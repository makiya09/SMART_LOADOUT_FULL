using Microsoft.EntityFrameworkCore;
using SmartLoadBulk.Core.DTOs.Loading;
using SmartLoadBulk.Core.Interfaces.Services;
using SmartLoadBulk.Infrastructure.Data;
using SmartLoadBulk.Infrastructure.Data.Entities;

namespace SmartLoadBulk.Infrastructure.Services;

// Bay Status:  AVAILABLE | CALLING | DOCKED | LOADING | CHECKING (pause) | ERROR (emergency) | MAINTENANCE
// Queue Status: WAITING | CALLED | DOCKED | LOADING | DONE | CANCELLED
// Job Status:  CREATED | QR_ISSUED | QR_SCANNED | LOADING | PAUSED | COMPLETED | FAILED | CANCELLED

public class LoadingService(SmartLoadBulkDbContext db, ILoadingEventPublisher events) : ILoadingService
{
    public async Task<List<BayStatusDto>> GetAllBaysAsync()
    {
        var bays = await db.Bays.Where(b => b.IsActive).ToListAsync();
        var result = new List<BayStatusDto>();
        foreach (var b in bays)
            result.Add(new BayStatusDto(b.BayId, b.BayCode, b.BayName, b.BayType, b.MaxCapacity,
                b.Status, b.CurrentQueueId, await GetActiveJobSummaryAsync(b.CurrentQueueId)));
        return result;
    }

    public async Task<BayStatusDto?> GetBayByIdAsync(Guid bayId)
    {
        var b = await db.Bays.FindAsync(bayId);
        if (b is null) return null;
        return new BayStatusDto(b.BayId, b.BayCode, b.BayName, b.BayType, b.MaxCapacity,
            b.Status, b.CurrentQueueId, await GetActiveJobSummaryAsync(b.CurrentQueueId));
    }

    public async Task<LoadingJobDetailDto?> GetJobByIdAsync(Guid jobId)
    {
        var j = await db.LoadJobs
            .Include(x => x.Bay).Include(x => x.Order)
            .Include(x => x.Truck).Include(x => x.Driver).Include(x => x.Product)
            .FirstOrDefaultAsync(x => x.JobId == jobId);
        if (j is null) return null;
        var queue = await db.LoadQueues.FirstOrDefaultAsync(q => q.OrderId == j.OrderId);
        return new LoadingJobDetailDto(j.JobId, j.JobCode, j.BayId, j.Bay.BayCode,
            queue?.QueueId ?? Guid.Empty, j.OrderId, j.Order.OrderCode,
            j.TruckId, j.Truck.LicensePlate, j.DriverId, j.Driver.FullName,
            j.ProductId, j.Product.ProductName, j.TargetWeight, j.ActualWeight,
            j.Status, j.StartedAt, j.CompletedAt, j.FailReason);
    }

    // AVAILABLE → CALLING
    public async Task<bool> CallTruckAsync(Guid bayId, CallTruckRequest request)
    {
        var bay = await db.Bays.FindAsync(bayId);
        if (bay is null || bay.Status != "AVAILABLE") return false;

        var queue = await db.LoadQueues.Include(q => q.Truck)
            .FirstOrDefaultAsync(q => q.QueueId == request.QueueId);
        if (queue is null || queue.Status != "WAITING") return false;

        bay.Status = "CALLING";
        bay.CurrentQueueId = request.QueueId;
        bay.LastUpdatedAt = DateTime.UtcNow;

        queue.Status = "CALLED";
        queue.CalledAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        await events.BayStatusChangedAsync(bay.BayCode, "CALLING");
        await events.TruckCalledAsync(request.QueueId, bay.BayCode, queue.Truck.LicensePlate);
        await events.QueueStatusChangedAsync(request.QueueId, "CALLED");

        return true;
    }

    // CALLING → DOCKED
    public async Task<bool> ConfirmDockAsync(Guid bayId, DockConfirmRequest request)
    {
        var bay = await db.Bays.FindAsync(bayId);
        if (bay is null || bay.Status != "CALLING") return false;
        if (bay.CurrentQueueId != request.QueueId) return false;

        var queue = await db.LoadQueues.FindAsync(request.QueueId);
        if (queue is null) return false;

        bay.Status = "DOCKED";
        bay.LastUpdatedAt = DateTime.UtcNow;

        queue.Status = "DOCKED";
        queue.DockedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        await events.BayStatusChangedAsync(bay.BayCode, "DOCKED");
        await events.TruckDockedAsync(request.QueueId, bay.BayCode);
        await events.QueueStatusChangedAsync(request.QueueId, "DOCKED");

        return true;
    }

    // DOCKED → LOADING (create job) | CHECKING → LOADING (resume job)
    public async Task<bool> StartLoadingAsync(Guid bayId)
    {
        var bay = await db.Bays.FindAsync(bayId);
        if (bay is null || !bay.CurrentQueueId.HasValue) return false;
        if (bay.Status != "DOCKED" && bay.Status != "CHECKING") return false;

        Guid newJobId = Guid.Empty;
        decimal targetWeight = 0;

        var pausedJob = await db.LoadJobs
            .FirstOrDefaultAsync(j => j.BayId == bayId && j.Status == "PAUSED");
        if (pausedJob != null)
        {
            pausedJob.Status = "LOADING";
            pausedJob.UpdatedAt = DateTime.UtcNow;
            newJobId = pausedJob.JobId;
            targetWeight = pausedJob.TargetWeight;
        }
        else if (bay.Status == "DOCKED")
        {
            var queue = await db.LoadQueues
                .Include(q => q.Order).ThenInclude(o => o.Items)
                .FirstOrDefaultAsync(q => q.QueueId == bay.CurrentQueueId);
            if (queue is null) return false;

            var item = queue.Order.Items.FirstOrDefault();
            if (item is null) return false;

            var job = new LoadJob
            {
                JobCode = $"LJ-{DateTime.Today:yyyyMMdd}-{Guid.NewGuid().ToString()[..6].ToUpper()}",
                BayId = bayId,
                OrderId = queue.OrderId,
                OrderItemId = item.ItemId,
                TruckId = queue.TruckId,
                DriverId = queue.DriverId,
                ProductId = item.ProductId,
                TargetWeight = item.RequestedQty,
                Status = "LOADING",
                StartedAt = DateTime.UtcNow
            };
            db.LoadJobs.Add(job);
            queue.Status = "LOADING";

            newJobId = job.JobId;
            targetWeight = item.RequestedQty;
        }
        else return false;

        bay.Status = "LOADING";
        bay.LastUpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        await events.BayStatusChangedAsync(bay.BayCode, "LOADING");
        await events.LoadingStartedAsync(bay.BayCode, newJobId, targetWeight);
        await events.QueueStatusChangedAsync(bay.CurrentQueueId!.Value, "LOADING");

        return true;
    }

    // LOADING → CHECKING (pause)
    public async Task<bool> PauseLoadingAsync(Guid bayId)
    {
        var bay = await db.Bays.FindAsync(bayId);
        if (bay is null || bay.Status != "LOADING") return false;

        var job = await db.LoadJobs
            .FirstOrDefaultAsync(j => j.BayId == bayId && j.Status == "LOADING");
        if (job is null) return false;

        job.Status = "PAUSED";
        job.UpdatedAt = DateTime.UtcNow;
        bay.Status = "CHECKING";
        bay.LastUpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        await events.BayStatusChangedAsync(bay.BayCode, "CHECKING");

        return true;
    }

    // any active → ERROR (emergency stop)
    public async Task<bool> EmergencyStopAsync(Guid bayId, EmergencyStopRequest request)
    {
        var bay = await db.Bays.FindAsync(bayId);
        if (bay is null) return false;

        var job = await db.LoadJobs.FirstOrDefaultAsync(j =>
            j.BayId == bayId && (j.Status == "LOADING" || j.Status == "PAUSED"));
        if (job != null)
        {
            job.Status = "FAILED";
            job.FailReason = request.Reason;
            job.CompletedAt = DateTime.UtcNow;
            job.UpdatedAt = DateTime.UtcNow;
        }

        if (bay.CurrentQueueId.HasValue)
        {
            var queue = await db.LoadQueues.FindAsync(bay.CurrentQueueId);
            if (queue is { Status: not "DONE" })
            {
                queue.Status = "CANCELLED";
                queue.CompletedAt = DateTime.UtcNow;
                await events.QueueStatusChangedAsync(bay.CurrentQueueId.Value, "CANCELLED");
            }
        }

        var bayCode = bay.BayCode;
        bay.Status = "ERROR";
        bay.LastUpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        await events.BayStatusChangedAsync(bayCode, "ERROR");
        await events.EmergencyStopAsync(bayCode, request.Reason);

        return true;
    }

    // LOADING → AVAILABLE (complete)
    public async Task<bool> CompleteLoadingAsync(Guid bayId)
    {
        var bay = await db.Bays.FindAsync(bayId);
        if (bay is null || bay.Status != "LOADING") return false;

        var job = await db.LoadJobs
            .FirstOrDefaultAsync(j => j.BayId == bayId && j.Status == "LOADING");
        if (job is null) return false;

        job.Status = "COMPLETED";
        job.CompletedAt = DateTime.UtcNow;
        job.UpdatedAt = DateTime.UtcNow;

        Guid? queueId = bay.CurrentQueueId;
        if (queueId.HasValue)
        {
            var queue = await db.LoadQueues.FindAsync(queueId);
            if (queue != null)
            {
                queue.Status = "DONE";
                queue.CompletedAt = DateTime.UtcNow;
            }
        }

        var bayCode = bay.BayCode;
        var completedJobId = job.JobId;
        var actualWeight = job.ActualWeight;

        bay.Status = "AVAILABLE";
        bay.CurrentQueueId = null;
        bay.LastUpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        await events.BayStatusChangedAsync(bayCode, "AVAILABLE");
        await events.LoadingCompletedAsync(bayCode, completedJobId, actualWeight);
        if (queueId.HasValue)
            await events.QueueStatusChangedAsync(queueId.Value, "DONE");

        return true;
    }

    // update actual weight while loading/checking
    public async Task<bool> UpdateProgressAsync(Guid bayId, LoadProgressRequest request)
    {
        var job = await db.LoadJobs.FirstOrDefaultAsync(j =>
            j.BayId == bayId && (j.Status == "LOADING" || j.Status == "PAUSED"));
        if (job is null) return false;

        job.ActualWeight = request.ActualWeight;
        job.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();

        var bay = await db.Bays.FindAsync(bayId);
        if (bay != null)
        {
            var pct = job.TargetWeight > 0
                ? Math.Min(100, Math.Round(request.ActualWeight / job.TargetWeight * 100, 1))
                : 0m;
            await events.LoadingProgressAsync(bay.BayCode, request.ActualWeight, pct);
        }

        return true;
    }

    // force-reset bay back to AVAILABLE (ADMIN/SUPERVISOR only)
    public async Task<bool> ResetBayAsync(Guid bayId)
    {
        var bay = await db.Bays.FindAsync(bayId);
        if (bay is null) return false;

        var activeJobs = await db.LoadJobs
            .Where(j => j.BayId == bayId && j.Status != "COMPLETED" && j.Status != "FAILED" && j.Status != "CANCELLED")
            .ToListAsync();
        foreach (var job in activeJobs)
        {
            job.Status = "FAILED";
            job.FailReason = "Bay Reset";
            job.CompletedAt = DateTime.UtcNow;
            job.UpdatedAt = DateTime.UtcNow;
        }

        if (bay.CurrentQueueId.HasValue)
        {
            var queue = await db.LoadQueues.FindAsync(bay.CurrentQueueId);
            if (queue is { Status: not "DONE" })
            {
                queue.Status = "CANCELLED";
                queue.CompletedAt = DateTime.UtcNow;
                await events.QueueStatusChangedAsync(bay.CurrentQueueId.Value, "CANCELLED");
            }
        }

        var bayCode = bay.BayCode;
        bay.Status = "AVAILABLE";
        bay.CurrentQueueId = null;
        bay.LastUpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        await events.BayStatusChangedAsync(bayCode, "AVAILABLE");

        return true;
    }

    private async Task<LoadingJobSummaryDto?> GetActiveJobSummaryAsync(Guid? currentQueueId)
    {
        if (!currentQueueId.HasValue) return null;
        var j = await db.LoadJobs
            .Include(x => x.Truck).Include(x => x.Driver).Include(x => x.Product)
            .FirstOrDefaultAsync(x => x.Status != "COMPLETED" && x.Status != "FAILED" && x.Status != "CANCELLED"
                && db.LoadQueues.Any(q => q.QueueId == currentQueueId && q.OrderId == x.OrderId));
        if (j is null) return null;
        var pct = j.TargetWeight > 0 ? Math.Min(100, Math.Round(j.ActualWeight / j.TargetWeight * 100, 1)) : 0m;
        return new LoadingJobSummaryDto(j.JobId, j.JobCode, j.Truck.LicensePlate, j.Driver.FullName,
            j.Product.ProductName, j.TargetWeight, j.ActualWeight, pct, j.Status, j.StartedAt);
    }
}
