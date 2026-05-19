namespace SmartLoadBulk.Core.DTOs.Queue;

public record QueueItemDto(
    Guid QueueId,
    Guid OrderId,
    string OrderCode,
    string CustomerName,
    Guid TruckId,
    string LicensePlate,
    string TruckType,
    Guid DriverId,
    string DriverName,
    int Priority,
    string Status,
    DateTime EnqueuedAt,
    DateTime? CalledAt,
    DateTime? DockedAt,
    DateTime? CompletedAt,
    string? Remark
);

public record EnqueueRequest(
    Guid OrderId,
    Guid TruckId,
    Guid DriverId,
    int Priority,
    string? Remark
);

public record UpdateQueuePriorityRequest(int Priority);
