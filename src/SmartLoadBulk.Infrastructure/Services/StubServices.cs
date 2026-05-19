using SmartLoadBulk.Core.DTOs.Analytics;
using SmartLoadBulk.Core.DTOs.Check;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Hardware;
using SmartLoadBulk.Core.DTOs.Order;
using SmartLoadBulk.Core.DTOs.Queue;
using SmartLoadBulk.Core.DTOs.Truck;
using SmartLoadBulk.Core.Interfaces.Services;
using SmartLoadBulk.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace SmartLoadBulk.Infrastructure.Services;

// TODO: Replace stub implementations with real business logic

public class OrderService(SmartLoadBulkDbContext db) : IOrderService
{
    public async Task<PagedResponse<OrderListDto>> GetOrdersAsync(int page, int pageSize, string? status = null)
    {
        var query = db.Orders.Include(o => o.Customer).Include(o => o.Items).AsQueryable();
        if (status is not null) query = query.Where(o => o.Status == status);

        var total = await query.CountAsync();
        var items = await query.OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .Select(o => new OrderListDto(o.OrderId, o.OrderCode, o.Customer.CustomerName,
                o.OrderDate, o.RequiredDate, o.Status, o.TotalWeight ?? 0, o.Items.Count, o.CreatedAt))
            .ToListAsync();

        return new PagedResponse<OrderListDto> { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
    }

    public async Task<OrderDetailDto?> GetOrderByIdAsync(Guid orderId)
    {
        var o = await db.Orders.Include(o => o.Customer)
            .Include(o => o.Items).ThenInclude(i => i.Product)
            .FirstOrDefaultAsync(o => o.OrderId == orderId);
        if (o is null) return null;

        var items = o.Items.Select(i => new OrderItemDto(i.ItemId, i.ProductId,
            i.Product.ProductCode, i.Product.ProductName, i.RequestedQty, i.ActualQty, i.Unit)).ToList();

        return new OrderDetailDto(o.OrderId, o.OrderCode, o.CustomerId, o.Customer.CustomerName,
            o.OrderDate, o.RequiredDate, o.Status, o.TotalWeight ?? 0, o.Remark, items, o.CreatedAt);
    }

    public async Task<OrderDetailDto> CreateOrderAsync(CreateOrderRequest request, Guid userId)
    {
        var order = new Data.Entities.Order
        {
            OrderCode = $"ORD-{DateTime.Today:yyyyMMdd}-{Guid.NewGuid().ToString()[..6].ToUpper()}",
            CustomerId = request.CustomerId,
            RequiredDate = request.RequiredDate,
            Remark = request.Remark,
            CreatedBy = userId,
            Status = "DRAFT",
            TotalWeight = request.Items.Sum(i => i.RequestedQty)
        };
        db.Orders.Add(order);

        foreach (var item in request.Items)
        {
            db.OrderItems.Add(new Data.Entities.OrderItem
            {
                OrderId = order.OrderId,
                ProductId = item.ProductId,
                RequestedQty = item.RequestedQty,
                Unit = item.Unit
            });
        }

        await db.SaveChangesAsync();
        return (await GetOrderByIdAsync(order.OrderId))!;
    }

    public async Task<bool> UpdateStatusAsync(Guid orderId, UpdateOrderStatusRequest request)
    {
        var order = await db.Orders.FindAsync(orderId);
        if (order is null) return false;
        order.Status = request.Status;
        order.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> CancelOrderAsync(Guid orderId, Guid userId)
    {
        var order = await db.Orders.FindAsync(orderId);
        if (order is null) return false;
        order.Status = "CANCELLED";
        order.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return true;
    }
}

public class QueueService(SmartLoadBulkDbContext db) : IQueueService
{
    public async Task<List<QueueItemDto>> GetQueueBoardAsync()
    {
        return await db.LoadQueues
            .Where(q => q.Status != "DONE" && q.Status != "CANCELLED")
            .Include(q => q.Order).ThenInclude(o => o.Customer)
            .Include(q => q.Truck).Include(q => q.Driver)
            .OrderBy(q => q.Priority).ThenBy(q => q.EnqueuedAt)
            .Select(q => new QueueItemDto(q.QueueId, q.OrderId, q.Order.OrderCode,
                q.Order.Customer.CustomerName, q.TruckId, q.Truck.LicensePlate, q.Truck.TruckType,
                q.DriverId, q.Driver.FullName, q.Priority, q.Status, q.EnqueuedAt,
                q.CalledAt, q.DockedAt, q.CompletedAt, q.Remark))
            .ToListAsync();
    }

    public async Task<QueueItemDto> EnqueueAsync(EnqueueRequest request)
    {
        var q = new Data.Entities.LoadQueue
        {
            OrderId = request.OrderId,
            TruckId = request.TruckId,
            DriverId = request.DriverId,
            Priority = (byte)request.Priority,
            Remark = request.Remark
        };
        db.LoadQueues.Add(q);
        await db.SaveChangesAsync();
        return (await GetQueueBoardAsync()).First(x => x.QueueId == q.QueueId);
    }

    public async Task<bool> UpdatePriorityAsync(Guid queueId, UpdateQueuePriorityRequest request)
    {
        var q = await db.LoadQueues.FindAsync(queueId);
        if (q is null) return false;
        q.Priority = (byte)request.Priority;
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> CancelQueueAsync(Guid queueId)
    {
        var q = await db.LoadQueues.FindAsync(queueId);
        if (q is null) return false;
        q.Status = "CANCELLED";
        await db.SaveChangesAsync();
        return true;
    }
}

public class TruckService(SmartLoadBulkDbContext db) : ITruckService
{
    public async Task<PagedResponse<TruckDto>> GetTrucksAsync(int page, int pageSize, bool? isActive = null)
    {
        var query = db.Trucks.AsQueryable();
        if (isActive.HasValue) query = query.Where(t => t.IsActive == isActive);
        var total = await query.CountAsync();
        var items = await query.OrderBy(t => t.LicensePlate).Skip((page - 1) * pageSize).Take(pageSize)
            .Select(t => new TruckDto(t.TruckId, t.LicensePlate, t.TruckType, t.MaxCapacity, t.CompanyName, t.IsActive, t.CreatedAt))
            .ToListAsync();
        return new PagedResponse<TruckDto> { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
    }

    public async Task<TruckDto?> GetTruckByIdAsync(Guid id) =>
        await db.Trucks.Where(t => t.TruckId == id)
            .Select(t => new TruckDto(t.TruckId, t.LicensePlate, t.TruckType, t.MaxCapacity, t.CompanyName, t.IsActive, t.CreatedAt))
            .FirstOrDefaultAsync();

    public async Task<TruckDto> CreateTruckAsync(CreateTruckRequest request)
    {
        var truck = new Data.Entities.Truck
        {
            LicensePlate = request.LicensePlate, TruckType = request.TruckType,
            MaxCapacity = request.MaxCapacity, CompanyName = request.CompanyName
        };
        db.Trucks.Add(truck);
        await db.SaveChangesAsync();
        return (await GetTruckByIdAsync(truck.TruckId))!;
    }

    public async Task<bool> UpdateTruckAsync(Guid id, UpdateTruckRequest request)
    {
        var truck = await db.Trucks.FindAsync(id);
        if (truck is null) return false;
        truck.LicensePlate = request.LicensePlate; truck.TruckType = request.TruckType;
        truck.MaxCapacity = request.MaxCapacity; truck.CompanyName = request.CompanyName;
        truck.IsActive = request.IsActive; truck.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<PagedResponse<DriverDto>> GetDriversAsync(int page, int pageSize, bool? isActive = null)
    {
        var query = db.Drivers.AsQueryable();
        if (isActive.HasValue) query = query.Where(d => d.IsActive == isActive);
        var total = await query.CountAsync();
        var items = await query.OrderBy(d => d.FullName).Skip((page - 1) * pageSize).Take(pageSize)
            .Select(d => new DriverDto(d.DriverId, d.FullName, d.LicenseNo, d.LicenseExpiry, d.Phone, d.IsActive, d.CreatedAt))
            .ToListAsync();
        return new PagedResponse<DriverDto> { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
    }

    public async Task<DriverDto?> GetDriverByIdAsync(Guid id) =>
        await db.Drivers.Where(d => d.DriverId == id)
            .Select(d => new DriverDto(d.DriverId, d.FullName, d.LicenseNo, d.LicenseExpiry, d.Phone, d.IsActive, d.CreatedAt))
            .FirstOrDefaultAsync();

    public async Task<DriverDto> CreateDriverAsync(CreateDriverRequest request)
    {
        var driver = new Data.Entities.Driver
        {
            FullName = request.FullName, LicenseNo = request.LicenseNo,
            LicenseExpiry = request.LicenseExpiry, Phone = request.Phone
        };
        db.Drivers.Add(driver);
        await db.SaveChangesAsync();
        return (await GetDriverByIdAsync(driver.DriverId))!;
    }

    public async Task<bool> UpdateDriverAsync(Guid id, UpdateDriverRequest request)
    {
        var driver = await db.Drivers.FindAsync(id);
        if (driver is null) return false;
        driver.FullName = request.FullName; driver.LicenseNo = request.LicenseNo;
        driver.LicenseExpiry = request.LicenseExpiry; driver.Phone = request.Phone;
        driver.IsActive = request.IsActive;
        await db.SaveChangesAsync();
        return true;
    }
}

public class ChecklistService(SmartLoadBulkDbContext db) : IChecklistService
{
    public async Task<ChecklistDto?> GetChecklistByJobIdAsync(Guid jobId)
    {
        var job = await db.LoadJobs
            .Include(j => j.Truck).Include(j => j.Driver).Include(j => j.Product)
            .FirstOrDefaultAsync(j => j.JobId == jobId);
        if (job is null) return null;

        // สร้าง checklist record ถ้ายังไม่มี (lazy init)
        var cl = await db.LoadChecklists.FirstOrDefaultAsync(c => c.JobId == jobId);
        if (cl is null)
        {
            cl = new Data.Entities.LoadChecklist { JobId = jobId };
            db.LoadChecklists.Add(cl);
            await db.SaveChangesAsync();
        }

        var status = DeriveStatus(cl);
        var items = BuildVirtualItems(cl);

        return new ChecklistDto(cl.ChecklistId, cl.JobId, job.JobCode,
            job.Truck.LicensePlate, job.Driver.FullName, job.Product.ProductName,
            job.TargetWeight, cl.ActualWeight, status, items);
    }

    public async Task<bool> RecordActualWeightAsync(Guid jobId, RecordActualWeightRequest request, Guid userId)
    {
        var job = await db.LoadJobs.FindAsync(jobId);
        if (job is null) return false;

        var cl = await EnsureChecklistAsync(jobId);
        cl.ActualWeight = request.ActualWeight;
        cl.WeightDiff = request.ActualWeight - job.TargetWeight;
        cl.WeightVerified = true;
        if (request.Remark is not null) cl.Remark = request.Remark;

        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> TickItemAsync(Guid jobId, Guid itemId, TickChecklistItemRequest request, Guid userId)
    {
        var cl = await EnsureChecklistAsync(jobId);
        var now = DateTime.UtcNow;

        if (itemId == ChecklistItemKey.Weight)       { cl.WeightVerified    = request.IsChecked; }
        else if (itemId == ChecklistItemKey.Qr)      { cl.QrVerified        = request.IsChecked; }
        else if (itemId == ChecklistItemKey.Documents){ cl.DocumentsVerified = request.IsChecked; }
        else if (itemId == ChecklistItemKey.Seal)    { cl.SealVerified      = request.IsChecked; }
        else if (itemId == ChecklistItemKey.Driver)  { cl.DriverVerified    = request.IsChecked; }
        else return false;

        // ถ้าทุก flag ผ่านหมดแล้ว บันทึก VerifiedAt
        if (cl.WeightVerified && cl.QrVerified && cl.DocumentsVerified && cl.SealVerified && cl.DriverVerified)
        {
            cl.VerifiedBy = userId;
            cl.VerifiedAt = now;
        }
        else
        {
            cl.VerifiedAt = null;
            cl.VerifiedBy = null;
        }

        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ReleaseGateAsync(Guid jobId, ReleaseGateRequest request, Guid userId)
    {
        var cl = await db.LoadChecklists.FirstOrDefaultAsync(c => c.JobId == jobId);
        if (cl is null) return false;

        // ต้องผ่าน verify ทุก flag ก่อนถึงจะ release ได้
        if (!cl.WeightVerified || !cl.QrVerified || !cl.DocumentsVerified || !cl.SealVerified || !cl.DriverVerified)
            return false;

        cl.ReleasedBy = userId;
        cl.ReleasedAt = DateTime.UtcNow;
        if (request.Remark is not null) cl.Remark = request.Remark;

        await db.SaveChangesAsync();
        return true;
    }

    private async Task<Data.Entities.LoadChecklist> EnsureChecklistAsync(Guid jobId)
    {
        var cl = await db.LoadChecklists.FirstOrDefaultAsync(c => c.JobId == jobId);
        if (cl is not null) return cl;
        cl = new Data.Entities.LoadChecklist { JobId = jobId };
        db.LoadChecklists.Add(cl);
        return cl;
    }

    private static string DeriveStatus(Data.Entities.LoadChecklist cl)
    {
        if (cl.ReleasedAt.HasValue) return "RELEASED";
        if (cl.WeightVerified && cl.QrVerified && cl.DocumentsVerified && cl.SealVerified && cl.DriverVerified) return "VERIFIED";
        if (cl.WeightVerified || cl.QrVerified || cl.DocumentsVerified || cl.SealVerified || cl.DriverVerified) return "CHECKING";
        return "PENDING";
    }

    private static List<ChecklistItemDto> BuildVirtualItems(Data.Entities.LoadChecklist cl) =>
    [
        new(ChecklistItemKey.Weight,    "ตรวจสอบน้ำหนัก",       "WEIGHT",    true, cl.WeightVerified,    cl.VerifiedAt, null, null),
        new(ChecklistItemKey.Qr,        "สแกน QR Code",          "QR",        true, cl.QrVerified,        cl.VerifiedAt, null, null),
        new(ChecklistItemKey.Documents, "ตรวจเอกสาร",            "DOCUMENT",  true, cl.DocumentsVerified, cl.VerifiedAt, null, null),
        new(ChecklistItemKey.Seal,      "ตรวจซีลรถ",             "SEAL",      true, cl.SealVerified,      cl.VerifiedAt, null, null),
        new(ChecklistItemKey.Driver,    "ยืนยันตัวตนคนขับ",      "DRIVER",    true, cl.DriverVerified,    cl.VerifiedAt, null, null),
    ];
}

public class HardwareService(SmartLoadBulkDbContext db) : IHardwareService
{
    public async Task<List<HardwareDeviceDto>> GetAllDevicesAsync() =>
        await db.HardwareDevices
            .Select(d => new HardwareDeviceDto(d.DeviceId, d.DeviceCode, d.DeviceName, d.DeviceType,
                d.Protocol, d.IpAddress ?? "", d.Port ?? 0, d.Status, d.LastHeartbeat, null, null))
            .ToListAsync();

    public async Task<HardwareDeviceDto?> GetDeviceByIdAsync(Guid id) =>
        await db.HardwareDevices.Where(d => d.DeviceId == id)
            .Select(d => new HardwareDeviceDto(d.DeviceId, d.DeviceCode, d.DeviceName, d.DeviceType,
                d.Protocol, d.IpAddress ?? "", d.Port ?? 0, d.Status, d.LastHeartbeat, null, null))
            .FirstOrDefaultAsync();

    public Task<bool> UpdateDeviceConfigAsync(Guid id, UpdateDeviceConfigRequest request) => Task.FromResult(true); // TODO
    public Task<List<HardwareEventDto>> GetEventsAsync(int limit = 100) => Task.FromResult(new List<HardwareEventDto>()); // TODO
    public Task<bool> TriggerScannerAsync() => Task.FromResult(true); // TODO (Safety: Dry-run only)
    public Task<object?> GetRadarDataAsync(Guid bayId) => Task.FromResult<object?>(null); // TODO
    public Task<bool> SendPanelCommandAsync(Guid bayId, PanelCommandRequest request) => Task.FromResult(true); // TODO (Safety: simulation mode)
    public Task<bool> SimulateAsync(SimulateRequest request) => Task.FromResult(true); // TODO
}

public class NotificationService : INotificationService
{
    public Task<List<object>> GetNotificationsAsync(int limit = 50) => Task.FromResult(new List<object>());
    public Task<bool> MarkReadAsync(long id) => Task.FromResult(true);
}
