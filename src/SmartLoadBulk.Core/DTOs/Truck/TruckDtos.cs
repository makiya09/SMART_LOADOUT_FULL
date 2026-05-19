namespace SmartLoadBulk.Core.DTOs.Truck;

public record TruckDto(
    Guid TruckId,
    string LicensePlate,
    string TruckType,
    decimal MaxCapacity,
    string? CompanyName,
    bool IsActive,
    DateTime CreatedAt
);

public record CreateTruckRequest(
    string LicensePlate,
    string TruckType,
    decimal MaxCapacity,
    string? CompanyName
);

public record UpdateTruckRequest(
    string LicensePlate,
    string TruckType,
    decimal MaxCapacity,
    string? CompanyName,
    bool IsActive
);

public record DriverDto(
    Guid DriverId,
    string FullName,
    string LicenseNo,
    DateTime LicenseExpiry,
    string? Phone,
    bool IsActive,
    DateTime CreatedAt
);

public record CreateDriverRequest(
    string FullName,
    string LicenseNo,
    DateTime LicenseExpiry,
    string? Phone
);

public record UpdateDriverRequest(
    string FullName,
    string LicenseNo,
    DateTime LicenseExpiry,
    string? Phone,
    bool IsActive
);
