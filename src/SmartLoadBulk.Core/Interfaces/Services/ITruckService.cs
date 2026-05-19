using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Truck;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface ITruckService
{
    Task<PagedResponse<TruckDto>> GetTrucksAsync(int page, int pageSize, bool? isActive = null);
    Task<TruckDto?> GetTruckByIdAsync(Guid truckId);
    Task<TruckDto> CreateTruckAsync(CreateTruckRequest request);
    Task<bool> UpdateTruckAsync(Guid truckId, UpdateTruckRequest request);
    Task<PagedResponse<DriverDto>> GetDriversAsync(int page, int pageSize, bool? isActive = null);
    Task<DriverDto?> GetDriverByIdAsync(Guid driverId);
    Task<DriverDto> CreateDriverAsync(CreateDriverRequest request);
    Task<bool> UpdateDriverAsync(Guid driverId, UpdateDriverRequest request);
}
