using System.Data;
using System.Data.Common;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using SmartLoadBulk.Core.DTOs.Analytics;
using SmartLoadBulk.Core.Interfaces.Services;
using SmartLoadBulk.Infrastructure.Data;

namespace SmartLoadBulk.Infrastructure.Services;

public class AnalyticsService(SmartLoadBulkDbContext db) : IAnalyticsService
{
    // ─── Performance Dashboard ─────────────────────────────────────────────────

    public async Task<PerformanceDashboardDto> GetPerformanceDashboardAsync(AnalyticsQueryParams q)
    {
        using var reader = await ExecSpAsync("ana.sp_GetPerformanceDashboard",
            DateParam("@DateFrom", q.DateFrom),
            DateParam("@DateTo", q.DateTo),
            NullableGuidParam("@BayId", q.BayId));

        // RS1: KPI
        var kpi = EmptyPerformanceKpi;
        if (await reader.ReadAsync())
            kpi = new PerformanceKpiDto(
                reader.Int("TotalJobs"), reader.Int("CompletedJobs"),
                reader.Int("CancelledJobs"), reader.Int("FailedJobs"),
                reader.Dbl("CompletionRatePct"), reader.Dbl("OverallYieldPct"),
                reader.Dec("TotalLossKg"), reader.Dec("TotalOverKg"), reader.Dec("TotalActualTon"),
                reader.Dbl("AvgAccuracyPct"), reader.Dbl("OverallAvgLoadingMin"),
                reader.DblN("AvgThroughput"));

        // RS2: Daily trend
        await reader.NextResultAsync();
        var daily = new List<DailyTrendDto>();
        while (await reader.ReadAsync())
            daily.Add(new DailyTrendDto(
                reader.Date("WorkDate"), reader.Int("TotalJobs"), reader.Int("CompletedJobs"),
                reader.Dec("TotalActualTon"), reader.Dbl("OverallYieldPct"),
                reader.Dbl("AccuracyPct"), reader.DblN("ThroughputTonPerHour"), reader.Dbl("AvgLoadingMin")));

        // RS3: Bay summary
        await reader.NextResultAsync();
        var bays = new List<BaySummaryDto>();
        while (await reader.ReadAsync())
            bays.Add(new BaySummaryDto(
                reader.Str("BayCode"), reader.Str("BayName"),
                reader.Int("TotalJobs"), reader.Int("CompletedJobs"),
                reader.Dec("TotalActualTon"), reader.Dbl("AvgLoadingMin"),
                reader.Dbl("AvgYieldPct"), reader.DblN("AvgThroughput"), reader.Dbl("AvgUtilizationPct")));

        // RS4: Shift summary
        await reader.NextResultAsync();
        var shifts = new List<ShiftSummaryDto>();
        while (await reader.ReadAsync())
            shifts.Add(new ShiftSummaryDto(
                reader.Str("ShiftName"), reader.Int("TotalJobs"), reader.Int("CompletedJobs"),
                reader.Dec("TotalActualTon"), reader.Dbl("AvgYieldPct"), reader.Dbl("AvgLoadingMin")));

        return new PerformanceDashboardDto(kpi, daily, bays, shifts);
    }

    // ─── Loss/Yield Dashboard ──────────────────────────────────────────────────

    public async Task<LossYieldDashboardDto> GetLossYieldDashboardAsync(AnalyticsQueryParams q)
    {
        using var reader = await ExecSpAsync("ana.sp_GetLossYieldDashboard",
            DateParam("@DateFrom", q.DateFrom),
            DateParam("@DateTo", q.DateTo),
            NullableGuidParam("@ProductId", q.ProductId),
            NullableGuidParam("@BayId", q.BayId));

        // RS1: KPI
        var kpi = EmptyLossYieldKpi;
        if (await reader.ReadAsync())
            kpi = new LossYieldKpiDto(
                reader.Int("TotalJobs"), reader.Dec("TotalTargetKg"), reader.Dec("TotalActualKg"),
                reader.Dbl("OverallYieldPct"), reader.Dec("TotalLossKg"), reader.Dec("TotalOverKg"),
                reader.Dbl("AvgYieldPct"), reader.Dbl("MinYieldPct"), reader.Dbl("MaxYieldPct"),
                reader.Dbl("AvgYieldStdDev"));

        // RS2: Daily trend
        await reader.NextResultAsync();
        var daily = new List<DailyLossTrendDto>();
        while (await reader.ReadAsync())
            daily.Add(new DailyLossTrendDto(
                reader.Date("WorkDate"), reader.Dbl("DailyYieldPct"),
                reader.Dec("TotalLossKg"), reader.Dec("TotalOverKg"), reader.Int("TotalJobs")));

        // RS3: Product loss
        await reader.NextResultAsync();
        var products = new List<ProductLossDto>();
        while (await reader.ReadAsync())
            products.Add(new ProductLossDto(
                reader.Str("ProductCode"), reader.Str("ProductName"),
                reader.Int("TotalJobs"), reader.Dec("TotalLossKg"),
                reader.Dbl("AvgYieldPct"), reader.Dbl("YieldStdDev")));

        // RS4: Job detail
        await reader.NextResultAsync();
        var jobs = new List<LossJobDetailDto>();
        while (await reader.ReadAsync())
            jobs.Add(new LossJobDetailDto(
                reader.Guid("JobId"), reader.Str("JobCode"), reader.Date("WorkDate"),
                reader.Str("BayName"), reader.Str("LicensePlate"), reader.Str("DriverName"),
                reader.Str("ProductName"), reader.Dec("TargetWeight"), reader.Dec("ActualWeight"),
                reader.Dec("LossKg"), reader.Dec("OverKg"),
                reader.Dbl("YieldPct"), reader.Dbl("LoadingDurationMin")));

        return new LossYieldDashboardDto(kpi, daily, products, jobs);
    }

    // ─── Bay Performance Dashboard ─────────────────────────────────────────────

    public async Task<BayPerformanceDashboardDto> GetBayPerformanceDashboardAsync(AnalyticsQueryParams q)
    {
        using var reader = await ExecSpAsync("ana.sp_GetBayPerformanceDashboard",
            DateParam("@DateFrom", q.DateFrom),
            DateParam("@DateTo", q.DateTo));

        // RS1: Bay summary
        var bays = new List<BaySummaryExtDto>();
        while (await reader.ReadAsync())
            bays.Add(new BaySummaryExtDto(
                reader.Str("BayCode"), reader.Str("BayName"),
                reader.Int("TotalJobs"), reader.Int("CompletedJobs"),
                reader.Dec("TotalActualTon"), reader.Int("TotalLoadingMin"),
                reader.Dbl("AvgLoadingMin"), reader.Dbl("AvgYieldPct"),
                reader.DblN("AvgThroughput"), reader.Dbl("AvgUtilizationPct")));

        // RS2: Daily bay data
        await reader.NextResultAsync();
        var daily = new List<BayDayPerformanceDto>();
        while (await reader.ReadAsync())
            daily.Add(new BayDayPerformanceDto(
                reader.Date("WorkDate"), reader.Str("BayCode"), reader.Str("BayName"),
                reader.Int("TotalJobs"), reader.Int("CompletedJobs"), reader.Dec("TotalActualTon"),
                reader.Dbl("AvgLoadingMin"), reader.Dbl("BayYieldPct"),
                reader.DblN("ThroughputTonPerHour"), reader.Dbl("BayUtilizationPct")));

        // RS3: Hourly heatmap
        await reader.NextResultAsync();
        var hourly = new List<HourlyHeatmapDto>();
        while (await reader.ReadAsync())
            hourly.Add(new HourlyHeatmapDto(
                reader.Date("WorkDate"), reader.Int("WorkHour"),
                reader.Str("BayCode"), reader.Str("BayName"),
                reader.Int("JobCount"), reader.Dec("TotalActualTon"),
                reader.DblN("ThroughputTonPerHour")));

        return new BayPerformanceDashboardDto(bays, daily, hourly);
    }

    // ─── Turnaround Dashboard ──────────────────────────────────────────────────

    public async Task<TurnaroundDashboardDto> GetTurnaroundDashboardAsync(AnalyticsQueryParams q)
    {
        using var reader = await ExecSpAsync("ana.sp_GetTurnaroundDashboard",
            DateParam("@DateFrom", q.DateFrom),
            DateParam("@DateTo", q.DateTo),
            NullableGuidParam("@TruckId", q.TruckId));

        // RS1: KPI
        var kpi = EmptyTurnaroundKpi;
        if (await reader.ReadAsync())
            kpi = new TurnaroundKpiDto(
                reader.Int("TotalJobs"), reader.Dbl("AvgTurnaroundMin"),
                reader.Int("MinTurnaroundMin"), reader.Int("MaxTurnaroundMin"),
                reader.Dbl("AvgQueueWaitMin"), reader.Dbl("AvgDockingMin"),
                reader.Dbl("AvgLoadingMin"), reader.Dbl("AvgChecklistMin"));

        // RS2: Daily trend
        await reader.NextResultAsync();
        var daily = new List<TurnaroundDailyDto>();
        while (await reader.ReadAsync())
            daily.Add(new TurnaroundDailyDto(
                reader.Date("WorkDate"), reader.Dbl("AvgTurnaroundMin"),
                reader.Dbl("AvgQueueWaitMin"), reader.Dbl("AvgLoadingMin"), reader.Int("JobCount")));

        // RS3: Job details
        await reader.NextResultAsync();
        var jobs = new List<TurnaroundJobDto>();
        while (await reader.ReadAsync())
            jobs.Add(new TurnaroundJobDto(
                reader.Guid("JobId"), reader.Str("JobCode"), reader.Date("WorkDate"),
                reader.Str("LicensePlate"), reader.StrN("TransportCompany"),
                reader.Str("DriverName"), reader.Str("BayName"),
                reader.Dbl("QueueWaitMin"), reader.Dbl("DockingMin"),
                reader.Dbl("LoadingMin"), reader.Dbl("ChecklistMin"),
                reader.Dbl("TurnaroundMin"), reader.Dbl("YieldPct")));

        return new TurnaroundDashboardDto(kpi, daily, jobs);
    }

    // ─── Analytics Config ──────────────────────────────────────────────────────

    public async Task<List<AnalyticsConfigDto>> GetConfigAsync()
    {
        using var reader = await ExecSpAsync("ana.sp_GetAnalyticsConfig",
            new SqlParameter("@ConfigKey", SqlDbType.VarChar) { Value = DBNull.Value });

        var result = new List<AnalyticsConfigDto>();
        while (await reader.ReadAsync())
            result.Add(new AnalyticsConfigDto(
                reader.Str("ConfigKey"),
                reader.StrN("ConfigGroup"),
                reader.Dec("ConfigValue"),
                reader.StrN("Unit"),
                reader.StrN("Description")));
        return result;
    }

    public async Task<bool> UpdateConfigAsync(string configKey, UpdateAnalyticsConfigRequest request)
    {
        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "EXEC ana.sp_UpdateAnalyticsConfig @ConfigKey, @ConfigValue, @UpdatedBy",
                new SqlParameter("@ConfigKey", configKey),
                new SqlParameter("@ConfigValue", request.ConfigValue),
                new SqlParameter("@UpdatedBy", "SYSTEM"));
            return true;
        }
        catch { return false; }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private async Task<DbDataReader> ExecSpAsync(string spName, params SqlParameter[] parameters)
    {
        var conn = db.Database.GetDbConnection();
        if (conn.State != ConnectionState.Open) await conn.OpenAsync();

        var cmd = conn.CreateCommand();
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.CommandText = spName;
        foreach (var p in parameters) cmd.Parameters.Add(p);

        return await cmd.ExecuteReaderAsync();
    }

    private static SqlParameter DateParam(string name, DateTime value) =>
        new(name, SqlDbType.Date) { Value = value.Date };

    private static SqlParameter NullableGuidParam(string name, Guid? value) =>
        new(name, SqlDbType.UniqueIdentifier) { Value = (object?)value ?? DBNull.Value };

    // ─── Empty defaults ────────────────────────────────────────────────────────

    private static readonly PerformanceKpiDto EmptyPerformanceKpi =
        new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, null);

    private static readonly LossYieldKpiDto EmptyLossYieldKpi =
        new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    private static readonly TurnaroundKpiDto EmptyTurnaroundKpi =
        new(0, 0, 0, 0, 0, 0, 0, 0);
}

// ─── DbDataReader extension helpers ───────────────────────────────────────────

internal static class ReaderExtensions
{
    public static int Int(this DbDataReader r, string col) => r.IsDBNull(r.GetOrdinal(col)) ? 0 : r.GetInt32(r.GetOrdinal(col));
    public static decimal Dec(this DbDataReader r, string col) => r.IsDBNull(r.GetOrdinal(col)) ? 0m : r.GetDecimal(r.GetOrdinal(col));
    public static double Dbl(this DbDataReader r, string col) => r.IsDBNull(r.GetOrdinal(col)) ? 0d : Convert.ToDouble(r.GetValue(r.GetOrdinal(col)));
    public static double? DblN(this DbDataReader r, string col) => r.IsDBNull(r.GetOrdinal(col)) ? null : Convert.ToDouble(r.GetValue(r.GetOrdinal(col)));
    public static string Str(this DbDataReader r, string col) => r.IsDBNull(r.GetOrdinal(col)) ? "" : r.GetString(r.GetOrdinal(col));
    public static string? StrN(this DbDataReader r, string col) => r.IsDBNull(r.GetOrdinal(col)) ? null : r.GetString(r.GetOrdinal(col));
    public static DateTime Date(this DbDataReader r, string col) => r.GetDateTime(r.GetOrdinal(col));
    public static Guid Guid(this DbDataReader r, string col) => r.GetGuid(r.GetOrdinal(col));
}
