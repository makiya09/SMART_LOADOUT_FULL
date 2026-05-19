using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("Silos", Schema = "slb")]
public class Silo
{
    [Key] public Guid SiloId { get; set; } = Guid.NewGuid();
    [MaxLength(10)] public required string SiloCode { get; set; }
    [MaxLength(100)] public required string SiloName { get; set; }
    public Guid ProductId { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal Capacity { get; set; }
    public bool IsActive { get; set; } = true;

    public Product Product { get; set; } = null!;
    public Inventory? Inventory { get; set; }
}
