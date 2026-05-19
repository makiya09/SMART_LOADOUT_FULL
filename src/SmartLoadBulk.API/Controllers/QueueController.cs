using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Queue;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class QueueController(IQueueService queueService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<QueueItemDto>>>> GetBoard() =>
        Ok(ApiResponse<List<QueueItemDto>>.Ok(await queueService.GetQueueBoardAsync()));

    [HttpPost("enqueue")]
    public async Task<ActionResult<ApiResponse<QueueItemDto>>> Enqueue([FromBody] EnqueueRequest request)
    {
        var result = await queueService.EnqueueAsync(request);
        return Ok(ApiResponse<QueueItemDto>.Ok(result));
    }

    [HttpPut("{queueId:guid}/priority")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdatePriority(Guid queueId, [FromBody] UpdateQueuePriorityRequest request)
    {
        var ok = await queueService.UpdatePriorityAsync(queueId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบ Queue"));
    }

    [HttpDelete("{queueId:guid}")]
    [Authorize(Roles = "ADMIN,SUPERVISOR")]
    public async Task<ActionResult<ApiResponse<bool>>> Cancel(Guid queueId)
    {
        var ok = await queueService.CancelQueueAsync(queueId);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบ Queue"));
    }
}
