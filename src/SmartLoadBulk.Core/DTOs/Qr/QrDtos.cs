namespace SmartLoadBulk.Core.DTOs.Qr;

public record GenerateQrRequest(Guid JobId, string TokenType, int ExpiryMinutes = 60);

public record QrTokenDto(
    Guid TokenId,
    Guid JobId,
    string JobCode,
    string TokenType,
    string QrPayload,
    DateTime ExpiresAt,
    bool IsUsed
);

public record ValidateQrRequest(string QrPayload, Guid BayId);

public record QrValidationResult(
    bool IsValid,
    string? Message,
    Guid? JobId,
    string? JobCode,
    string? LicensePlate,
    string? DriverName,
    string? ProductName,
    decimal? TargetWeight,
    string? BayCode
);
