using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SmartLoadBulk.API.Hubs;

[Authorize]
public class HardwareHub : Hub
{
    // Server → Client events:
    // - DeviceStatusChanged(deviceId, deviceCode, status, lastPingAt)
    // - QrScanned(payload, bayCode)
    // - RadarDetected(bayCode, detected)
    // - WeightUpdated(bayCode, weight)
}
