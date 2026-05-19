using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("Bays", Schema = "slb")]
public class Bay
{
    [Key] public Guid BayId { get; set; } = Guid.NewGuid();
    [MaxLength(10)] public required string BayCode { get; set; }
    [MaxLength(100)] public required string BayName { get; set; }
    [MaxLength(20)] public required string BayType { get; set; }
    [Column(TypeName = "decimal(10,3)")] public decimal MaxCapacity { get; set; }
    public bool IsActive { get; set; } = true;
    public Guid? CurrentQueueId { get; set; }
    [MaxLength(15)] public string Status { get; set; } = "AVAILABLE";
    public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

    public LoadQueue? CurrentQueue { get; set; }
    public ICollection<LoadJob> LoadJobs { get; set; } = [];
}

[Table("LoadQueues", Schema = "slb")]
public class LoadQueue
{
    [Key] public Guid QueueId { get; set; } = Guid.NewGuid();
    public Guid OrderId { get; set; }
    public Guid TruckId { get; set; }
    public Guid DriverId { get; set; }
    public byte Priority { get; set; } = 5;
    [MaxLength(12)] public string Status { get; set; } = "WAITING";
    public DateTime EnqueuedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CalledAt { get; set; }
    public DateTime? DockedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    [MaxLength(300)] public string? Remark { get; set; }

    public Order Order { get; set; } = null!;
    public Truck Truck { get; set; } = null!;
    public Driver Driver { get; set; } = null!;
}

[Table("LoadJobs", Schema = "slb")]
public class LoadJob
{
    [Key] public Guid JobId { get; set; } = Guid.NewGuid();
    [MaxLength(20)] public required string JobCode { get; set; }
    public Guid OrderId { get; set; }
    public Guid OrderItemId { get; set; }
    public Guid TruckId { get; set; }
    public Guid DriverId { get; set; }
    public Guid BayId { get; set; }
    public Guid ProductId { get; set; }
    public Guid? SiloId { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal TargetWeight { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal ActualWeight { get; set; }
    [Column(TypeName = "decimal(5,2)")] public decimal TolerancePct { get; set; } = 0;
    [MaxLength(15)] public string Status { get; set; } = "CREATED";
    public DateTime? StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    [MaxLength(500)] public string? FailReason { get; set; }
    public Guid? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public Bay Bay { get; set; } = null!;
    public Order Order { get; set; } = null!;
    public OrderItem OrderItem { get; set; } = null!;
    public Truck Truck { get; set; } = null!;
    public Driver Driver { get; set; } = null!;
    public Product Product { get; set; } = null!;
    public ICollection<LoadChecklist> Checklists { get; set; } = [];
    public ICollection<QrToken> QrTokens { get; set; } = [];
}
