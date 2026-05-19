using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Loading;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/bays")]
[Authorize]
public class LoadingJobController(ILoadingService loadingService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<BayStatusDto>>>> GetAllBays() =>
        Ok(ApiResponse<List<BayStatusDto>>.Ok(await loadingService.GetAllBaysAsync()));

    [HttpGet("{bayId:guid}")]
    public async Task<ActionResult<ApiResponse<BayStatusDto>>> GetBay(Guid bayId)
    {
        var result = await loadingService.GetBayByIdAsync(bayId);
        return result is null ? NotFound(ApiResponse<BayStatusDto>.Fail("ไม่พบ Bay")) : Ok(ApiResponse<BayStatusDto>.Ok(result));
    }

    [HttpPost("{bayId:guid}/call")]
    public async Task<ActionResult<ApiResponse<bool>>> CallTruck(Guid bayId, [FromBody] CallTruckRequest request)
    {
        var ok = await loadingService.CallTruckAsync(bayId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true, "เรียกรถสำเร็จ")) : BadRequest(ApiResponse<bool>.Fail("ไม่สามารถเรียกรถได้"));
    }

    [HttpPost("{bayId:guid}/dock")]
    public async Task<ActionResult<ApiResponse<bool>>> ConfirmDock(Guid bayId, [FromBody] DockConfirmRequest request)
    {
        var ok = await loadingService.ConfirmDockAsync(bayId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true, "ยืนยันรถเข้า Bay สำเร็จ")) : BadRequest(ApiResponse<bool>.Fail("ยืนยันไม่สำเร็จ"));
    }

    [HttpPost("{bayId:guid}/load/start")]
    public async Task<ActionResult<ApiResponse<bool>>> StartLoading(Guid bayId)
    {
        var ok = await loadingService.StartLoadingAsync(bayId);
        return ok ? Ok(ApiResponse<bool>.Ok(true, "เริ่มโหลดสำเร็จ")) : BadRequest(ApiResponse<bool>.Fail("ไม่สามารถเริ่มโหลดได้"));
    }

    [HttpPost("{bayId:guid}/load/pause")]
    public async Task<ActionResult<ApiResponse<bool>>> PauseLoading(Guid bayId)
    {
        var ok = await loadingService.PauseLoadingAsync(bayId);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : BadRequest(ApiResponse<bool>.Fail("ไม่สามารถ Pause ได้"));
    }

    [HttpPost("{bayId:guid}/load/stop")]
    [Authorize(Roles = "ADMIN,SUPERVISOR,OPERATOR")]
    public async Task<ActionResult<ApiResponse<bool>>> EmergencyStop(Guid bayId, [FromBody] EmergencyStopRequest request)
    {
        var ok = await loadingService.EmergencyStopAsync(bayId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true, "Emergency Stop สำเร็จ")) : BadRequest(ApiResponse<bool>.Fail("ไม่สามารถ Stop ได้"));
    }

    [HttpPost("{bayId:guid}/load/complete")]
    public async Task<ActionResult<ApiResponse<bool>>> CompleteLoading(Guid bayId)
    {
        var ok = await loadingService.CompleteLoadingAsync(bayId);
        return ok ? Ok(ApiResponse<bool>.Ok(true, "โหลดเสร็จสิ้น")) : BadRequest(ApiResponse<bool>.Fail("ไม่สามารถจบงานได้"));
    }

    [HttpPost("{bayId:guid}/load/progress")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateProgress(Guid bayId, [FromBody] LoadProgressRequest request)
    {
        var ok = await loadingService.UpdateProgressAsync(bayId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : BadRequest(ApiResponse<bool>.Fail("อัปเดต Progress ไม่สำเร็จ"));
    }

    [HttpPost("{bayId:guid}/reset")]
    [Authorize(Roles = "ADMIN,SUPERVISOR")]
    public async Task<ActionResult<ApiResponse<bool>>> ResetBay(Guid bayId)
    {
        var ok = await loadingService.ResetBayAsync(bayId);
        return ok ? Ok(ApiResponse<bool>.Ok(true, "Reset Bay สำเร็จ")) : BadRequest(ApiResponse<bool>.Fail("Reset ไม่สำเร็จ"));
    }
}
