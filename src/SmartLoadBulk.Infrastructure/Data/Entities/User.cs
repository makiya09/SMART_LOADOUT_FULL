using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartLoadBulk.Infrastructure.Data.Entities;

[Table("Users", Schema = "slb")]
public class User
{
    [Key] public Guid UserId { get; set; } = Guid.NewGuid();
    [MaxLength(50)] public required string Username { get; set; }
    [MaxLength(256)] public required string PasswordHash { get; set; }
    [MaxLength(100)] public required string FullName { get; set; }
    [MaxLength(150)] public string? Email { get; set; }
    [MaxLength(20)] public required string Role { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? LastLoginAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}
