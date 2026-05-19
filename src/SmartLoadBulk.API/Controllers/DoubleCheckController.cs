using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Check;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/check")]
[Authorize]
public class DoubleCheckController(IChecklistService checklistService) : ControllerBase
{
    [HttpGet("{jobId:guid}")]
    public async Task<ActionResult<ApiResponse<ChecklistDto>>> GetChecklist(Guid jobId)
    {
        var result = await checklistService.GetChecklistByJobIdAsync(jobId);
        return result is null ? NotFound(ApiResponse<ChecklistDto>.Fail("ไม่พบ Checklist")) : Ok(ApiResponse<ChecklistDto>.Ok(result));
    }

    [HttpPost("{jobId:guid}/weight")]
    public async Task<ActionResult<ApiResponse<bool>>> RecordWeight(Guid jobId, [FromBody] RecordActualWeightRequest request)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var ok = await checklistService.RecordActualWeightAsync(jobId, request, userId);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : BadRequest(ApiResponse<bool>.Fail("บันทึกน้ำหนักไม่สำเร็จ"));
    }

    [HttpPut("{jobId:guid}/item/{itemId:guid}")]
    public async Task<ActionResult<ApiResponse<bool>>> TickItem(Guid jobId, Guid itemId, [FromBody] TickChecklistItemRequest request)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var ok = await checklistService.TickItemAsync(jobId, itemId, request, userId);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : BadRequest(ApiResponse<bool>.Fail("บันทึก Checklist ไม่สำเร็จ"));
    }

    [HttpPost("{jobId:guid}/release")]
    [Authorize(Roles = "ADMIN,SUPERVISOR")]
    public async Task<ActionResult<ApiResponse<bool>>> Release(Guid jobId, [FromBody] ReleaseGateRequest request)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var ok = await checklistService.ReleaseGateAsync(jobId, request, userId);
        return ok ? Ok(ApiResponse<bool>.Ok(true, "อนุมัติปล่อยรถสำเร็จ")) : BadRequest(ApiResponse<bool>.Fail("ปล่อยรถไม่สำเร็จ"));
    }
}
