using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("Products", Schema = "slb")]
public class Product
{
    [Key] public Guid ProductId { get; set; } = Guid.NewGuid();
    [MaxLength(20)] public required string ProductCode { get; set; }
    [MaxLength(150)] public required string ProductName { get; set; }
    [MaxLength(10)] public required string Unit { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal MinStock { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal CriticalStock { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal MaxStock { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Silo> Silos { get; set; } = [];
    public ICollection<Inventory> Inventories { get; set; } = [];
    public ICollection<OrderItem> OrderItems { get; set; } = [];
}
