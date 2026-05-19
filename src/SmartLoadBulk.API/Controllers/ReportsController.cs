using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Analytics;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReportsController : ControllerBase
{
    [HttpGet("analytics/export/excel")]
    public IActionResult ExportExcel([FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        // TODO: Implement Excel export using EPPlus or ClosedXML
        return Ok(new { message = "Excel export — coming soon" });
    }

    [HttpGet("analytics/export/pdf")]
    public IActionResult ExportPdf([FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        // TODO: Implement PDF export
        return Ok(new { message = "PDF export — coming soon" });
    }

    [HttpGet("loading-summary")]
    public IActionResult GetLoadingSummary([FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        // TODO: Implement loading summary report
        return Ok(new { message = "Loading summary — coming soon" });
    }
}
