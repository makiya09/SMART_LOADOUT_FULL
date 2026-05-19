using SmartLoadBulk.Core.DTOs.Auth;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request);
    Task<bool> ChangePasswordAsync(Guid userId, ChangePasswordRequest request);
}
