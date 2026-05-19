namespace SmartLoadBulk.Core.DTOs.Inventory;

public record ProductStockDto(
    Guid ProductId,
    string ProductCode,
    string ProductName,
    string Unit,
    decimal CurrentStock,
    decimal ReservedStock,
    decimal AvailableStock,
    decimal MinStock,
    decimal CriticalStock,
    string StockStatus,
    List<SiloStockDto> Silos
);

public record SiloStockDto(
    Guid SiloId,
    string SiloCode,
    string SiloName,
    decimal Capacity,
    decimal CurrentStock,
    decimal UtilizationPct
);

public record InventoryAdjustRequest(
    Guid ProductId,
    Guid SiloId,
    decimal Qty,
    string ChangeType,
    string? Remark
);

public record InventoryHistoryDto(
    long LogId,
    string ProductCode,
    string ProductName,
    string SiloCode,
    string ChangeType,
    decimal Qty,
    decimal BeforeStock,
    decimal AfterStock,
    string? Remark,
    string CreatedBy,
    DateTime CreatedAt
);
