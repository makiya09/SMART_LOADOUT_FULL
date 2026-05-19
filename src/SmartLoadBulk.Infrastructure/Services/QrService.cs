using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using QRCoder;
using SmartLoadBulk.Core.DTOs.Qr;
using SmartLoadBulk.Core.Interfaces.Services;
using SmartLoadBulk.Infrastructure.Data;
using SmartLoadBulk.Infrastructure.Data.Entities;

namespace SmartLoadBulk.Infrastructure.Services;

public class QrService(SmartLoadBulkDbContext db) : IQrService
{
    public async Task<QrTokenDto> GenerateQrAsync(GenerateQrRequest request)
    {
        var job = await db.LoadJobs.FindAsync(request.JobId)
            ?? throw new InvalidOperationException("ไม่พบ LoadJob");

        // Revoke previous active tokens for this job
        var oldTokens = await db.QrTokens
            .Where(t => t.JobId == request.JobId && !t.IsRevoked)
            .ToListAsync();
        foreach (var t in oldTokens) t.IsRevoked = true;

        var expiresAt = DateTime.UtcNow.AddMinutes(request.ExpiryMinutes);

        // Token = base64(JSON payload)
        var payloadObj = new { tokenId = Guid.NewGuid(), jobId = request.JobId, issuedAt = DateTime.UtcNow };
        var payloadJson = JsonSerializer.Serialize(payloadObj);
        var tokenPayload = Convert.ToBase64String(Encoding.UTF8.GetBytes(payloadJson));
        var tokenHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(tokenPayload)))[..64];

        var token = new QrToken
        {
            JobId = request.JobId,
            Token = tokenPayload,
            TokenHash = tokenHash,
            ExpiredAt = expiresAt
        };
        db.QrTokens.Add(token);
        await db.SaveChangesAsync();

        return new QrTokenDto(token.TokenId, token.JobId, job.JobCode,
            request.TokenType, token.Token, token.ExpiredAt, token.IsUsed);
    }

    public async Task<QrValidationResult> ValidateQrAsync(ValidateQrRequest request)
    {
        var token = await db.QrTokens
            .Include(t => t.Job).ThenInclude(j => j.Truck)
            .Include(t => t.Job).ThenInclude(j => j.Driver)
            .Include(t => t.Job).ThenInclude(j => j.Product)
            .FirstOrDefaultAsync(t => t.Token == request.QrPayload && !t.IsRevoked);

        if (token is null)
            return new QrValidationResult(false, "QR Code ไม่ถูกต้องหรือถูกยกเลิกแล้ว", null, null, null, null, null, null, null);

        if (token.IsUsed)
            return new QrValidationResult(false, "QR Code นี้ถูกใช้ไปแล้ว", null, null, null, null, null, null, null);

        if (token.ExpiredAt < DateTime.UtcNow)
            return new QrValidationResult(false, "QR Code หมดอายุแล้ว", null, null, null, null, null, null, null);

        if (token.Job.BayId != request.BayId)
            return new QrValidationResult(false, "QR Code ไม่ตรงกับ Bay นี้", null, null, null, null, null, null, null);

        var bay = await db.Bays.FindAsync(token.Job.BayId);

        token.IsUsed = true;
        token.ScannedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();

        var j = token.Job;
        return new QrValidationResult(true, "ตรวจสอบสำเร็จ",
            j.JobId, j.JobCode, j.Truck.LicensePlate, j.Driver.FullName,
            j.Product.ProductName, j.TargetWeight, bay?.BayCode);
    }

    public async Task<byte[]> GetQrImageAsync(Guid jobId)
    {
        var token = await db.QrTokens
            .Where(t => t.JobId == jobId && !t.IsRevoked && !t.IsUsed)
            .OrderByDescending(t => t.IssuedAt)
            .FirstOrDefaultAsync();

        if (token is null) throw new InvalidOperationException("ไม่พบ QR Token สำหรับ Job นี้");

        using var qrGenerator = new QRCodeGenerator();
        using var qrData = qrGenerator.CreateQrCode(token.Token, QRCodeGenerator.ECCLevel.M);
        using var qrCode = new PngByteQRCode(qrData);
        return qrCode.GetGraphic(10);
    }

    public async Task<bool> RevokeTokenAsync(Guid tokenId)
    {
        var token = await db.QrTokens.FindAsync(tokenId);
        if (token is null) return false;
        token.IsRevoked = true;
        await db.SaveChangesAsync();
        return true;
    }
}
