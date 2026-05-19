using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("LoadChecklists", Schema = "slb")]
public class LoadChecklist
{
    [Key] public Guid ChecklistId { get; set; } = Guid.NewGuid();
    public Guid JobId { get; set; }

    public bool WeightVerified { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal? ActualWeight { get; set; }
    [Column(TypeName = "decimal(12,3)")] public decimal? WeightDiff { get; set; }

    public bool QrVerified { get; set; }
    public bool DocumentsVerified { get; set; }
    public bool SealVerified { get; set; }
    public bool DriverVerified { get; set; }

    public Guid? VerifiedBy { get; set; }
    public DateTime? VerifiedAt { get; set; }
    public Guid? ReleasedBy { get; set; }
    public DateTime? ReleasedAt { get; set; }

    [MaxLength(500)] public string? Remark { get; set; }

    public LoadJob Job { get; set; } = null!;
}
