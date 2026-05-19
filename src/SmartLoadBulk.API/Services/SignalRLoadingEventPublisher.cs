using Microsoft.AspNetCore.SignalR;
using SmartLoadBulk.API.Hubs;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Services;

public class SignalRLoadingEventPublisher(
    IHubContext<LoadingHub> loadingHub,
    IHubContext<QueueHub> queueHub) : ILoadingEventPublisher
{
    public Task BayStatusChangedAsync(string bayCode, string status) =>
        loadingHub.Clients.All.SendAsync("BayStatusChanged", bayCode, status);

    public Task LoadingStartedAsync(string bayCode, Guid jobId, decimal targetWeight) =>
        loadingHub.Clients.Group($"bay-{bayCode}")
            .SendAsync("LoadingStarted", bayCode, jobId, targetWeight);

    public Task LoadingProgressAsync(string bayCode, decimal actualWeight, decimal progressPct) =>
        loadingHub.Clients.Group($"bay-{bayCode}")
            .SendAsync("LoadingProgress", bayCode, actualWeight, progressPct);

    public Task LoadingCompletedAsync(string bayCode, Guid jobId, decimal actualWeight) =>
        loadingHub.Clients.Group($"bay-{bayCode}")
            .SendAsync("LoadingCompleted", bayCode, jobId, actualWeight);

    public Task EmergencyStopAsync(string bayCode, string reason) =>
        loadingHub.Clients.Group($"bay-{bayCode}")
            .SendAsync("EmergencyStop", bayCode, reason);

    public Task TruckCalledAsync(Guid queueId, string bayCode, string licensePlate) =>
        queueHub.Clients.All.SendAsync("TruckCalled", queueId, bayCode, licensePlate);

    public Task TruckDockedAsync(Guid queueId, string bayCode) =>
        queueHub.Clients.All.SendAsync("TruckDocked", queueId, bayCode);

    public Task QueueStatusChangedAsync(Guid queueId, string status) =>
        queueHub.Clients.All.SendAsync("QueueStatusChanged", queueId, status);
}
