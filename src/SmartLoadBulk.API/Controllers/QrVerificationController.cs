using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Qr;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api/qr")]
[Authorize]
public class QrVerificationController(IQrService qrService) : ControllerBase
{
    [HttpPost("generate")]
    public async Task<ActionResult<ApiResponse<QrTokenDto>>> Generate([FromBody] GenerateQrRequest request)
    {
        var result = await qrService.GenerateQrAsync(request);
        return Ok(ApiResponse<QrTokenDto>.Ok(result));
    }

    [HttpPost("validate")]
    public async Task<ActionResult<ApiResponse<QrValidationResult>>> Validate([FromBody] ValidateQrRequest request)
    {
        var result = await qrService.ValidateQrAsync(request);
        return Ok(ApiResponse<QrValidationResult>.Ok(result));
    }

    [HttpGet("{jobId:guid}/image")]
    public async Task<IActionResult> GetImage(Guid jobId)
    {
        var image = await qrService.GetQrImageAsync(jobId);
        return File(image, "image/png");
    }

    [HttpDelete("{tokenId:guid}/revoke")]
    [Authorize(Roles = "ADMIN,SUPERVISOR")]
    public async Task<ActionResult<ApiResponse<bool>>> Revoke(Guid tokenId)
    {
        var ok = await qrService.RevokeTokenAsync(tokenId);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบ Token"));
    }
}
