using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Hardware;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/hardware")]
[Authorize]
public class HardwareDeviceController(IHardwareService hardwareService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<HardwareDeviceDto>>>> GetAll() =>
        Ok(ApiResponse<List<HardwareDeviceDto>>.Ok(await hardwareService.GetAllDevicesAsync()));

    [HttpGet("{deviceId:guid}")]
    public async Task<ActionResult<ApiResponse<HardwareDeviceDto>>> GetById(Guid deviceId)
    {
        var result = await hardwareService.GetDeviceByIdAsync(deviceId);
        return result is null ? NotFound(ApiResponse<HardwareDeviceDto>.Fail("ไม่พบ Device")) : Ok(ApiResponse<HardwareDeviceDto>.Ok(result));
    }

    [HttpPatch("{deviceId:guid}/config")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateConfig(Guid deviceId, [FromBody] UpdateDeviceConfigRequest request)
    {
        var ok = await hardwareService.UpdateDeviceConfigAsync(deviceId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบ Device"));
    }

    [HttpGet("events")]
    public async Task<ActionResult<ApiResponse<List<HardwareEventDto>>>> GetEvents([FromQuery] int limit = 100) =>
        Ok(ApiResponse<List<HardwareEventDto>>.Ok(await hardwareService.GetEventsAsync(limit)));

    [HttpPost("scanner/trigger")]
    [Authorize(Roles = "ADMIN,SUPERVISOR")]
    public async Task<ActionResult<ApiResponse<bool>>> TriggerScanner()
    {
        var ok = await hardwareService.TriggerScannerAsync();
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : BadRequest(ApiResponse<bool>.Fail("Trigger ไม่สำเร็จ"));
    }

    [HttpGet("radar/{bayId:guid}")]
    public async Task<ActionResult<ApiResponse<object>>> GetRadarData(Guid bayId) =>
        Ok(ApiResponse<object>.Ok(await hardwareService.GetRadarDataAsync(bayId) ?? new { }));

    [HttpPost("panel/{bayId:guid}/cmd")]
    [Authorize(Roles = "ADMIN,SUPERVISOR")]
    public async Task<ActionResult<ApiResponse<bool>>> SendPanelCommand(Guid bayId, [FromBody] PanelCommandRequest request)
    {
        // Safety Rule: Hardware Panel commands must always check simulation mode first
        var ok = await hardwareService.SendPanelCommandAsync(bayId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : BadRequest(ApiResponse<bool>.Fail("ส่งคำสั่งไม่สำเร็จ"));
    }

    [HttpPost("simulate/{type}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ApiResponse<bool>>> Simulate(string type, [FromBody] SimulateRequest request)
    {
        var ok = await hardwareService.SimulateAsync(request);
        return ok ? Ok(ApiResponse<bool>.Ok(true, $"Simulate {type} สำเร็จ")) : BadRequest(ApiResponse<bool>.Fail("Simulate ไม่สำเร็จ"));
    }
}
