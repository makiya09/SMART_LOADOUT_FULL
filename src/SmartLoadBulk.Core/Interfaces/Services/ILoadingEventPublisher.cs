namespace SmartLoadBulk.Core.Interfaces.Services;

public interface ILoadingEventPublisher
{
    Task BayStatusChangedAsync(string bayCode, string status);
    Task LoadingStartedAsync(string bayCode, Guid jobId, decimal targetWeight);
    Task LoadingProgressAsync(string bayCode, decimal actualWeight, decimal progressPct);
    Task LoadingCompletedAsync(string bayCode, Guid jobId, decimal actualWeight);
    Task EmergencyStopAsync(string bayCode, string reason);

    Task TruckCalledAsync(Guid queueId, string bayCode, string licensePlate);
    Task TruckDockedAsync(Guid queueId, string bayCode);
    Task QueueStatusChangedAsync(Guid queueId, string status);
}
