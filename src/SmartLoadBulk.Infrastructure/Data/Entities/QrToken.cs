using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("QrTokens", Schema = "slb")]
public class QrToken
{
    [Key] public Guid TokenId { get; set; } = Guid.NewGuid();
    public Guid JobId { get; set; }
    [MaxLength(500)] public required string Token { get; set; }
    [MaxLength(64)] public required string TokenHash { get; set; }
    public bool IsUsed { get; set; }
    public bool IsRevoked { get; set; }
    [MaxLength(200)] public string? RevokeReason { get; set; }
    public DateTime IssuedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiredAt { get; set; }
    public DateTime? ScannedAt { get; set; }
    public Guid? ScannedByDeviceId { get; set; }

    public LoadJob Job { get; set; } = null!;
}
