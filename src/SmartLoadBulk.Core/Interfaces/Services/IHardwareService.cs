using SmartLoadBulk.Core.DTOs.Hardware;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface IHardwareService
{
    Task<List<HardwareDeviceDto>> GetAllDevicesAsync();
    Task<HardwareDeviceDto?> GetDeviceByIdAsync(Guid deviceId);
    Task<bool> UpdateDeviceConfigAsync(Guid deviceId, UpdateDeviceConfigRequest request);
    Task<List<HardwareEventDto>> GetEventsAsync(int limit = 100);
    Task<bool> TriggerScannerAsync();
    Task<object?> GetRadarDataAsync(Guid bayId);
    Task<bool> SendPanelCommandAsync(Guid bayId, PanelCommandRequest request);
    Task<bool> SimulateAsync(SimulateRequest request);
}
