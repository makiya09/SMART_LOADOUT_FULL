using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Order;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OrdersController(IOrderService orderService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResponse<OrderListDto>>>> GetOrders(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? status = null) =>
        Ok(ApiResponse<PagedResponse<OrderListDto>>.Ok(await orderService.GetOrdersAsync(page, pageSize, status)));

    [HttpGet("{orderId:guid}")]
    public async Task<ActionResult<ApiResponse<OrderDetailDto>>> GetById(Guid orderId)
    {
        var result = await orderService.GetOrderByIdAsync(orderId);
        return result is null ? NotFound(ApiResponse<OrderDetailDto>.Fail("ไม่พบ Order"))
            : Ok(ApiResponse<OrderDetailDto>.Ok(result));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<OrderDetailDto>>> Create([FromBody] CreateOrderRequest request)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await orderService.CreateOrderAsync(request, userId);
        return CreatedAtAction(nameof(GetById), new { orderId = result.OrderId }, ApiResponse<OrderDetailDto>.Ok(result));
    }

    [HttpPut("{orderId:guid}/status")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateStatus(Guid orderId, [FromBody] UpdateOrderStatusRequest request)
    {
        var ok = await orderService.UpdateStatusAsync(orderId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบ Order"));
    }

    [HttpDelete("{orderId:guid}")]
    [Authorize(Roles = "ADMIN,SUPERVISOR")]
    public async Task<ActionResult<ApiResponse<bool>>> Cancel(Guid orderId)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var ok = await orderService.CancelOrderAsync(orderId, userId);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบ Order"));
    }
}
