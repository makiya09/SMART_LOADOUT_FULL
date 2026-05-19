using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SmartLoadBulk.API.Hubs;

[Authorize]
public class InventoryHub : Hub
{
    // Server → Client events:
    // - StockUpdated(productId, productCode, currentStock, availableStock, status)
    // - LowStockAlert(productId, productCode, currentStock, minStock)
}
