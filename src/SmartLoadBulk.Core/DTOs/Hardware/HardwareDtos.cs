namespace SmartLoadBulk.Core.DTOs.Hardware;

public record HardwareDeviceDto(
    Guid DeviceId,
    string DeviceCode,
    string DeviceName,
    string DeviceType,
    string Protocol,
    string IpAddress,
    int Port,
    string Status,
    DateTime? LastPingAt,
    string? BayCode,
    object? Config
);

public record HardwareEventDto(
    long EventId,
    string DeviceCode,
    string DeviceType,
    string EventType,
    string? Payload,
    string? BayCode,
    DateTime EventTime
);

public record UpdateDeviceConfigRequest(string? IpAddress, int? Port, object? Config);

public record SimulateRequest(string SimType, string? Payload);

public record PanelCommandRequest(string Command, string? Payload);
