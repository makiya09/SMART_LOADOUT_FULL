using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("HardwareDevices", Schema = "slb")]
public class HardwareDevice
{
    [Key] public Guid DeviceId { get; set; } = Guid.NewGuid();
    [MaxLength(20)] public required string DeviceCode { get; set; }
    [MaxLength(100)] public required string DeviceName { get; set; }
    [MaxLength(30)] public required string DeviceType { get; set; }
    [MaxLength(100)] public string? Location { get; set; }
    [MaxLength(20)] public required string Protocol { get; set; }
    [MaxLength(45)] public string? IpAddress { get; set; }
    public int? Port { get; set; }
    [MaxLength(15)] public string Status { get; set; } = "OFFLINE";
    public DateTime? LastHeartbeat { get; set; }
    public bool IsActive { get; set; } = true;
    public Guid? BayId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public Bay? Bay { get; set; }
    public ICollection<HardwareEvent> Events { get; set; } = [];
}

[Table("HardwareEvents", Schema = "slb")]
public class HardwareEvent
{
    [Key] public long EventId { get; set; }
    public Guid DeviceId { get; set; }
    [MaxLength(30)] public required string EventType { get; set; }
    [MaxLength(2000)] public string? Payload { get; set; }
    public Guid? BayId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public HardwareDevice Device { get; set; } = null!;
}
