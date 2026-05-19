using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Analytics;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/analytics")]
[Authorize]
public class LossYieldController(IAnalyticsService analyticsService) : ControllerBase
{
    [HttpGet("loss-yield")]
    public async Task<ActionResult<ApiResponse<LossYieldDashboardDto>>> GetLossYield(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] string? shift)
    {
        var query = new AnalyticsQueryParams(from ?? DateTime.Today, to ?? DateTime.Today, shift);
        return Ok(ApiResponse<LossYieldDashboardDto>.Ok(await analyticsService.GetLossYieldDashboardAsync(query)));
    }

    [HttpGet("bay")]
    public async Task<ActionResult<ApiResponse<BayPerformanceDashboardDto>>> GetBayPerformance(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] Guid? bayId)
    {
        var query = new AnalyticsQueryParams(from ?? DateTime.Today, to ?? DateTime.Today, BayId: bayId);
        return Ok(ApiResponse<BayPerformanceDashboardDto>.Ok(await analyticsService.GetBayPerformanceDashboardAsync(query)));
    }

    [HttpGet("turnaround")]
    public async Task<ActionResult<ApiResponse<TurnaroundDashboardDto>>> GetTurnaround(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        var query = new AnalyticsQueryParams(from ?? DateTime.Today, to ?? DateTime.Today);
        return Ok(ApiResponse<TurnaroundDashboardDto>.Ok(await analyticsService.GetTurnaroundDashboardAsync(query)));
    }
}
