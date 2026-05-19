using SmartLoadBulk.Core.DTOs.Qr;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface IQrService
{
    Task<QrTokenDto> GenerateQrAsync(GenerateQrRequest request);
    Task<QrValidationResult> ValidateQrAsync(ValidateQrRequest request);
    Task<byte[]> GetQrImageAsync(Guid jobId);
    Task<bool> RevokeTokenAsync(Guid tokenId);
}
