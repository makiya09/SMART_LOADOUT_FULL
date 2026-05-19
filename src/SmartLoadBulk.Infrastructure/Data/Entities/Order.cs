using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("Orders", Schema = "slb")]
public class Order
{
    [Key] public Guid OrderId { get; set; } = Guid.NewGuid();
    [MaxLength(20)] public required string OrderCode { get; set; }
    public Guid CustomerId { get; set; }
    public DateTime OrderDate { get; set; } = DateTime.Today;
    public DateTime RequiredDate { get; set; }
    [MaxLength(15)] public string Status { get; set; } = "DRAFT";
    [Column(TypeName = "decimal(12,3)")] public decimal? TotalWeight { get; set; }
    [MaxLength(500)] public string? Remark { get; set; }
    public Guid CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public Customer Customer { get; set; } = null!;
    public ICollection<OrderItem> Items { get; set; } = [];
    public ICollection<LoadQueue> LoadQueues { get; set; } = [];
}

[Table("OrderItems", Schema = "slb")]
public class OrderItem
{
    [Key] public Guid ItemId { get; set; } = Guid.NewGuid();
    public Guid OrderId { get; set; }
    public Guid ProductId { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal RequestedQty { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal? ActualQty { get; set; }
    [MaxLength(10)] public required string Unit { get; set; }

    public Order Order { get; set; } = null!;
    public Product Product { get; set; } = null!;
}

[Table("Customers", Schema = "slb")]
public class Customer
{
    [Key] public Guid CustomerId { get; set; } = Guid.NewGuid();
    [MaxLength(20)] public required string CustomerCode { get; set; }
    [MaxLength(150)] public required string CustomerName { get; set; }
    [MaxLength(100)] public string? ContactPerson { get; set; }
    [MaxLength(20)] public string? Phone { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Order> Orders { get; set; } = [];
}
