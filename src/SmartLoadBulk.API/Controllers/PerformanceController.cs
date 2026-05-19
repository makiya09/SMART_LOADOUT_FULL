using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Analytics;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/analytics")]
[Authorize]
public class PerformanceController(IAnalyticsService analyticsService) : ControllerBase
{
    private AnalyticsQueryParams BuildQuery(DateTime? from, DateTime? to, string? shift) =>
        new(from ?? DateTime.Today, to ?? DateTime.Today, shift);

    [HttpGet("performance")]
    public async Task<ActionResult<ApiResponse<PerformanceDashboardDto>>> GetPerformance(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] string? shift) =>
        Ok(ApiResponse<PerformanceDashboardDto>.Ok(await analyticsService.GetPerformanceDashboardAsync(BuildQuery(from, to, shift))));

    [HttpGet("config")]
    public async Task<ActionResult<ApiResponse<List<AnalyticsConfigDto>>>> GetConfig() =>
        Ok(ApiResponse<List<AnalyticsConfigDto>>.Ok(await analyticsService.GetConfigAsync()));

    [HttpPut("config/{configKey}")]
    [Authorize(Roles = "ADMIN,SUPERVISOR")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateConfig(string configKey, [FromBody] UpdateAnalyticsConfigRequest request)
    {
        var ok = await analyticsService.UpdateConfigAsync(configKey, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบ Config Key"));
    }
}
