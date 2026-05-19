using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationController(INotificationService notificationService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<object>>>> GetNotifications([FromQuery] int limit = 50) =>
        Ok(ApiResponse<List<object>>.Ok(await notificationService.GetNotificationsAsync(limit)));

    [HttpPut("{id:long}/read")]
    public async Task<ActionResult<ApiResponse<bool>>> MarkRead(long id)
    {
        var ok = await notificationService.MarkReadAsync(id);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบ Notification"));
    }
}
