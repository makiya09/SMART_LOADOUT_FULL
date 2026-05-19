namespace SmartLoadBulk.Core.DTOs.Loading;

public record BayStatusDto(
    Guid BayId,
    string BayCode,
    string BayName,
    string BayType,
    decimal MaxCapacity,
    string Status,
    Guid? CurrentQueueId,
    LoadingJobSummaryDto? CurrentJob
);

public record LoadingJobSummaryDto(
    Guid JobId,
    string JobCode,
    string LicensePlate,
    string DriverName,
    string ProductName,
    decimal TargetWeight,
    decimal ActualWeight,
    decimal ProgressPct,
    string Status,
    DateTime? StartedAt
);

public record LoadingJobDetailDto(
    Guid JobId,
    string JobCode,
    Guid BayId,
    string BayCode,
    Guid QueueId,
    Guid OrderId,
    string OrderCode,
    Guid TruckId,
    string LicensePlate,
    Guid DriverId,
    string DriverName,
    Guid ProductId,
    string ProductName,
    decimal TargetWeight,
    decimal ActualWeight,
    string Status,
    DateTime? StartedAt,
    DateTime? CompletedAt,
    string? FailReason
);

public record CallTruckRequest(Guid QueueId);

public record DockConfirmRequest(Guid QueueId);

public record LoadProgressRequest(decimal ActualWeight, string? Remark);

public record EmergencyStopRequest(string Reason);
