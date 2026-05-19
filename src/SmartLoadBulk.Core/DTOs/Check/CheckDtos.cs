namespace SmartLoadBulk.Core.DTOs.Check;

// Item keys ที่ใช้ใน TickItemAsync — ตรงกับ flag columns ใน DB
public static class ChecklistItemKey
{
    public static readonly Guid Weight    = Guid.Parse("c0000001-0000-0000-0000-000000000001");
    public static readonly Guid Qr        = Guid.Parse("c0000001-0000-0000-0000-000000000002");
    public static readonly Guid Documents = Guid.Parse("c0000001-0000-0000-0000-000000000003");
    public static readonly Guid Seal      = Guid.Parse("c0000001-0000-0000-0000-000000000004");
    public static readonly Guid Driver    = Guid.Parse("c0000001-0000-0000-0000-000000000005");
}

public record ChecklistDto(
    Guid ChecklistId,
    Guid JobId,
    string JobCode,
    string LicensePlate,
    string DriverName,
    string ProductName,
    decimal TargetWeight,
    decimal? ActualWeight,
    string Status,          // derived: PENDING | CHECKING | VERIFIED | RELEASED
    List<ChecklistItemDto> Items
);

public record ChecklistItemDto(
    Guid ItemId,            // uses ChecklistItemKey constants
    string ItemName,
    string ItemType,
    bool IsRequired,
    bool IsChecked,
    DateTime? CheckedAt,
    string? CheckedBy,
    string? Remark
);

public record TickChecklistItemRequest(bool IsChecked, string? Remark);

public record RecordActualWeightRequest(decimal ActualWeight, string? Remark);

public record ReleaseGateRequest(string ApprovedBy, string? Remark);
