using SmartLoadBulk.Core.DTOs.Loading;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface ILoadingService
{
    Task<List<BayStatusDto>> GetAllBaysAsync();
    Task<BayStatusDto?> GetBayByIdAsync(Guid bayId);
    Task<bool> CallTruckAsync(Guid bayId, CallTruckRequest request);
    Task<bool> ConfirmDockAsync(Guid bayId, DockConfirmRequest request);
    Task<LoadingJobDetailDto?> GetJobByIdAsync(Guid jobId);
    Task<bool> StartLoadingAsync(Guid bayId);
    Task<bool> PauseLoadingAsync(Guid bayId);
    Task<bool> EmergencyStopAsync(Guid bayId, EmergencyStopRequest request);
    Task<bool> CompleteLoadingAsync(Guid bayId);
    Task<bool> UpdateProgressAsync(Guid bayId, LoadProgressRequest request);
    Task<bool> ResetBayAsync(Guid bayId);
}
