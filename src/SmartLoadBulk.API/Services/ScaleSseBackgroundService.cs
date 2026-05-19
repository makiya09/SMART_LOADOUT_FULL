using System.Text.Json;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using SmartLoadBulk.API.Hubs;
using SmartLoadBulk.Infrastructure.Data;

namespace SmartLoadBulk.API.Services;

/// <summary>
/// Background service ที่ subscribe SSE stream จาก Scale Service แต่ละ Bay
/// รองรับ SimulationMode สำหรับ UAT โดยไม่ต้องต่อ Scale จริง
/// </summary>
public class ScaleSseBackgroundService(
    IConfiguration config,
    IServiceScopeFactory scopeFactory,
    IHubContext<HardwareHub> hardwareHub,
    IHubContext<LoadingHub> loadingHub,
    ILogger<ScaleSseBackgroundService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        var section = config.GetSection("ScaleService");
        if (!section.GetValue<bool>("Enabled"))
        {
            logger.LogInformation("[Scale] ScaleService disabled — skipping");
            return;
        }

        var scales = section.GetSection("Scales").Get<List<ScaleConfig>>() ?? [];
        if (scales.Count == 0)
        {
            logger.LogWarning("[Scale] No scales configured");
            return;
        }

        var tasks = scales.Select(s => RunScaleAsync(s, ct)).ToArray();
        await Task.WhenAll(tasks);
    }

    private async Task RunScaleAsync(ScaleConfig scale, CancellationToken ct)
    {
        if (scale.SimulationMode)
        {
            logger.LogInformation("[Scale:{Bay}] Simulation mode ON", scale.BayCode);
            await RunSimulationAsync(scale, ct);
            return;
        }

        var reconnectDelay = config.GetSection("ScaleService").GetValue<int>("ReconnectDelaySeconds", 5);

        while (!ct.IsCancellationRequested)
        {
            try
            {
                logger.LogInformation("[Scale:{Bay}] Connecting SSE → {Url}", scale.BayCode, scale.SseUrl);
                await ConnectAndReadAsync(scale, ct);
            }
            catch (OperationCanceledException) { break; }
            catch (Exception ex)
            {
                logger.LogWarning("[Scale:{Bay}] Connection lost: {Msg} — retry in {Sec}s",
                    scale.BayCode, ex.Message, reconnectDelay);
            }

            if (!ct.IsCancellationRequested)
                await Task.Delay(TimeSpan.FromSeconds(reconnectDelay), ct);
        }
    }

    private async Task ConnectAndReadAsync(ScaleConfig scale, CancellationToken ct)
    {
        using var http = new HttpClient();
        http.Timeout = Timeout.InfiniteTimeSpan;

        if (!string.IsNullOrEmpty(scale.ApiKey))
            http.DefaultRequestHeaders.Add("X-API-Key", scale.ApiKey);

        using var response = await http.GetAsync(scale.SseUrl,
            HttpCompletionOption.ResponseHeadersRead, ct);
        response.EnsureSuccessStatusCode();

        using var stream = await response.Content.ReadAsStreamAsync(ct);
        using var reader = new StreamReader(stream);

        logger.LogInformation("[Scale:{Bay}] SSE connected ✅", scale.BayCode);

        while (!ct.IsCancellationRequested && !reader.EndOfStream)
        {
            var line = await reader.ReadLineAsync(ct);
            if (string.IsNullOrWhiteSpace(line) || !line.StartsWith("data:")) continue;

            var raw = line["data:".Length..].Trim();
            if (TryParseWeight(raw, scale.WeightUnit, out var weightKg))
                await ProcessWeightAsync(scale.BayCode, weightKg, ct);
        }
    }

    private async Task ProcessWeightAsync(string bayCode, decimal weightKg, CancellationToken ct)
    {
        // Push real-time ไปที่ HardwareHub ทันที (ไม่รอ DB)
        await hardwareHub.Clients.All.SendAsync("WeightUpdated", bayCode, weightKg, ct);

        // อัปเดต LoadJob ที่กำลัง LOADING อยู่ใน DB
        using var scope = scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SmartLoadBulkDbContext>();

        var bay = await db.Bays.FirstOrDefaultAsync(b => b.BayCode == bayCode, ct);
        if (bay is null || bay.Status != "LOADING") return;

        var job = await db.LoadJobs
            .FirstOrDefaultAsync(j => j.BayId == bay.BayId && j.Status == "LOADING", ct);
        if (job is null) return;

        job.ActualWeight = weightKg;
        job.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        var pct = job.TargetWeight > 0
            ? Math.Min(weightKg / job.TargetWeight * 100, 100)
            : 0;

        // Push progress ไปที่ LoadingHub
        await loadingHub.Clients.Group($"bay-{bayCode}")
            .SendAsync("LoadingProgress", bayCode, weightKg, Math.Round(pct, 1), ct);

        logger.LogDebug("[Scale:{Bay}] {Weight} kg ({Pct}%)", bayCode, weightKg, pct);
    }

    // Simulation — จำลอง weight เพิ่มขึ้นเรื่อยๆ จนถึง target แล้ว reset
    private async Task RunSimulationAsync(ScaleConfig scale, CancellationToken ct)
    {
        var intervalMs = config.GetSection("ScaleService").GetValue<int>("SimulationIntervalMs", 2000);
        decimal current = 0;
        decimal step = scale.SimulationStepKg > 0 ? scale.SimulationStepKg : 500;
        decimal target = scale.SimulationTargetKg > 0 ? scale.SimulationTargetKg : 20000;

        while (!ct.IsCancellationRequested)
        {
            current = current >= target ? 0 : Math.Min(current + step, target);
            await ProcessWeightAsync(scale.BayCode, current, ct);
            await Task.Delay(intervalMs, ct);
        }
    }

    private static bool TryParseWeight(string raw, string unit, out decimal weightKg)
    {
        weightKg = 0;

        // รูปแบบ JSON: {"weight":1250.50} หรือ {"weightKg":1250.50} หรือ {"weightTon":1.25}
        if (raw.StartsWith('{'))
        {
            try
            {
                using var doc = JsonDocument.Parse(raw);
                var root = doc.RootElement;

                if (root.TryGetProperty("weightKg", out var wKg))
                    weightKg = wKg.GetDecimal();
                else if (root.TryGetProperty("weightTon", out var wTon))
                    weightKg = wTon.GetDecimal() * 1000;
                else if (root.TryGetProperty("weight", out var w))
                {
                    var val = w.GetDecimal();
                    weightKg = unit.Equals("ton", StringComparison.OrdinalIgnoreCase) ? val * 1000 : val;
                }
                else return false;

                return weightKg >= 0;
            }
            catch { return false; }
        }

        // รูปแบบ plain number: 1250.50
        if (decimal.TryParse(raw, System.Globalization.NumberStyles.Any,
            System.Globalization.CultureInfo.InvariantCulture, out var plain))
        {
            weightKg = unit.Equals("ton", StringComparison.OrdinalIgnoreCase) ? plain * 1000 : plain;
            return weightKg >= 0;
        }

        return false;
    }
}

public class ScaleConfig
{
    public string BayCode { get; set; } = "";
    public string SseUrl { get; set; } = "";
    public string WeightUnit { get; set; } = "kg";  // "kg" หรือ "ton"
    public string ApiKey { get; set; } = "";
    public bool SimulationMode { get; set; } = false;
    public decimal SimulationStepKg { get; set; } = 500;
    public decimal SimulationTargetKg { get; set; } = 20000;
}
