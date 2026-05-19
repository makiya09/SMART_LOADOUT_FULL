using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SmartLoadBulk.API.Hubs;

[Authorize]
public class AnalyticsHub : Hub
{
    // Server → Client events:
    // - KpiUpdated(kpiData)
    // - AlertTriggered(alertType, kpiKey, currentValue, threshold)
}
