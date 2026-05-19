using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Inventory;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class InventoryController(IInventoryService inventoryService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<ProductStockDto>>>> GetAll() =>
        Ok(ApiResponse<List<ProductStockDto>>.Ok(await inventoryService.GetAllStockAsync()));

    [HttpGet("{productId:guid}")]
    public async Task<ActionResult<ApiResponse<ProductStockDto>>> GetById(Guid productId)
    {
        var result = await inventoryService.GetProductStockAsync(productId);
        return result is null ? NotFound(ApiResponse<ProductStockDto>.Fail("ไม่พบสินค้า"))
            : Ok(ApiResponse<ProductStockDto>.Ok(result));
    }

    [HttpGet("history")]
    public async Task<ActionResult<ApiResponse<PagedResponse<InventoryHistoryDto>>>> GetHistory(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20) =>
        Ok(ApiResponse<PagedResponse<InventoryHistoryDto>>.Ok(await inventoryService.GetHistoryAsync(page, pageSize)));

    [HttpPost("adjust")]
    [Authorize(Roles = "ADMIN,SUPERVISOR")]
    public async Task<ActionResult<ApiResponse<bool>>> Adjust([FromBody] InventoryAdjustRequest request)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var ok = await inventoryService.AdjustStockAsync(request, userId);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : BadRequest(ApiResponse<bool>.Fail("ปรับ Stock ไม่สำเร็จ"));
    }
}
