using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("Trucks", Schema = "slb")]
public class Truck
{
    [Key] public Guid TruckId { get; set; } = Guid.NewGuid();
    [MaxLength(20)] public required string LicensePlate { get; set; }
    [MaxLength(20)] public required string TruckType { get; set; }
    [Column(TypeName = "decimal(10,3)")] public decimal MaxCapacity { get; set; }
    [MaxLength(150)] public string? CompanyName { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public ICollection<TruckDriverMap> TruckDriverMaps { get; set; } = [];
    public ICollection<LoadQueue> LoadQueues { get; set; } = [];
}

[Table("Drivers", Schema = "slb")]
public class Driver
{
    [Key] public Guid DriverId { get; set; } = Guid.NewGuid();
    [MaxLength(100)] public required string FullName { get; set; }
    [MaxLength(20)] public required string LicenseNo { get; set; }
    public DateTime LicenseExpiry { get; set; }
    [MaxLength(20)] public string? Phone { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<TruckDriverMap> TruckDriverMaps { get; set; } = [];
    public ICollection<LoadQueue> LoadQueues { get; set; } = [];
}

[Table("TruckDriverMap", Schema = "slb")]
public class TruckDriverMap
{
    [Key] public Guid MapId { get; set; } = Guid.NewGuid();
    public Guid TruckId { get; set; }
    public Guid DriverId { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

    public Truck Truck { get; set; } = null!;
    public Driver Driver { get; set; } = null!;
}
