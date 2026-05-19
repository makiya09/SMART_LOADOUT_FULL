using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("Inventory", Schema = "slb")]
public class Inventory
{
    [Key] public Guid InventoryId { get; set; } = Guid.NewGuid();
    public Guid ProductId { get; set; }
    public Guid SiloId { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal CurrentStock { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal ReservedStock { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [NotMapped] public decimal AvailableStock => CurrentStock - ReservedStock;

    public Product Product { get; set; } = null!;
    public Silo Silo { get; set; } = null!;
}
