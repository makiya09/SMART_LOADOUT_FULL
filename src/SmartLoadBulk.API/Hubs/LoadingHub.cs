using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SmartLoadBulk.API.Hubs;

[Authorize]
public class LoadingHub : Hub
{
    public async Task JoinBayGroup(string bayCode) =>
        await Groups.AddToGroupAsync(Context.ConnectionId, $"bay-{bayCode}");

    public async Task LeaveBayGroup(string bayCode) =>
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"bay-{bayCode}");

    // Server → Client events pushed via IHubContext<LoadingHub>:
    // - LoadingStarted(bayCode, jobId, targetWeight)
    // - LoadingProgress(bayCode, actualWeight, progressPct)
    // - LoadingCompleted(bayCode, jobId, actualWeight)
    // - EmergencyStop(bayCode, reason)
    // - BayStatusChanged(bayCode, status)
}
