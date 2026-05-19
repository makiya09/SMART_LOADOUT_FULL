using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SmartLoadBulk.API.Hubs;

[Authorize]
public class QueueHub : Hub
{
    // Server → Client events:
    // - TruckEnqueued(queueItem)
    // - TruckCalled(queueId, bayCode, licensePlate)
    // - TruckDocked(queueId, bayCode)
    // - QueueStatusChanged(queueId, status)
    // - QueuePriorityChanged(queueId, priority)
}
