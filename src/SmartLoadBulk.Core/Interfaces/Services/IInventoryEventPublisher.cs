namespace SmartLoadBulk.Core.Interfaces.Services;

public interface IInventoryEventPublisher
{
    Task StockUpdatedAsync(Guid productId, string productCode, decimal currentStock, decimal availableStock, string status);
    Task LowStockAlertAsync(Guid productId, string productCode, decimal currentStock, decimal minStock);
}
