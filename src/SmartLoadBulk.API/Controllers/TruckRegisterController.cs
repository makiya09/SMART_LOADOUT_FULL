using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Truck;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Controllers;

[ApiController]
[Route("api")]
[Authorize]
public class TruckRegisterController(ITruckService truckService) : ControllerBase
{
    // --- Trucks ---
    [HttpGet("trucks")]
    public async Task<ActionResult<ApiResponse<PagedResponse<TruckDto>>>> GetTrucks(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] bool? isActive = null) =>
        Ok(ApiResponse<PagedResponse<TruckDto>>.Ok(await truckService.GetTrucksAsync(page, pageSize, isActive)));

    [HttpGet("trucks/{truckId:guid}")]
    public async Task<ActionResult<ApiResponse<TruckDto>>> GetTruck(Guid truckId)
    {
        var result = await truckService.GetTruckByIdAsync(truckId);
        return result is null ? NotFound(ApiResponse<TruckDto>.Fail("ไม่พบรถ")) : Ok(ApiResponse<TruckDto>.Ok(result));
    }

    [HttpPost("trucks")]
    public async Task<ActionResult<ApiResponse<TruckDto>>> CreateTruck([FromBody] CreateTruckRequest request)
    {
        var result = await truckService.CreateTruckAsync(request);
        return Ok(ApiResponse<TruckDto>.Ok(result));
    }

    [HttpPut("trucks/{truckId:guid}")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateTruck(Guid truckId, [FromBody] UpdateTruckRequest request)
    {
        var ok = await truckService.UpdateTruckAsync(truckId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบรถ"));
    }

    // --- Drivers ---
    [HttpGet("drivers")]
    public async Task<ActionResult<ApiResponse<PagedResponse<DriverDto>>>> GetDrivers(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] bool? isActive = null) =>
        Ok(ApiResponse<PagedResponse<DriverDto>>.Ok(await truckService.GetDriversAsync(page, pageSize, isActive)));

    [HttpGet("drivers/{driverId:guid}")]
    public async Task<ActionResult<ApiResponse<DriverDto>>> GetDriver(Guid driverId)
    {
        var result = await truckService.GetDriverByIdAsync(driverId);
        return result is null ? NotFound(ApiResponse<DriverDto>.Fail("ไม่พบคนขับ")) : Ok(ApiResponse<DriverDto>.Ok(result));
    }

    [HttpPost("drivers")]
    public async Task<ActionResult<ApiResponse<DriverDto>>> CreateDriver([FromBody] CreateDriverRequest request)
    {
        var result = await truckService.CreateDriverAsync(request);
        return Ok(ApiResponse<DriverDto>.Ok(result));
    }

    [HttpPut("drivers/{driverId:guid}")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateDriver(Guid driverId, [FromBody] UpdateDriverRequest request)
    {
        var ok = await truckService.UpdateDriverAsync(driverId, request);
        return ok ? Ok(ApiResponse<bool>.Ok(true)) : NotFound(ApiResponse<bool>.Fail("ไม่พบคนขับ"));
    }
}
