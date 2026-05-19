using Microsoft.AspNetCore.SignalR;
using SmartLoadBulk.API.Hubs;
using SmartLoadBulk.Core.Interfaces.Services;

namespace SmartLoadBulk.API.Services;

public class SignalRInventoryEventPublisher(IHubContext<InventoryHub> hub) : IInventoryEventPublisher
{
    public Task StockUpdatedAsync(Guid productId, string productCode, decimal currentStock, decimal availableStock, string status) =>
        hub.Clients.All.SendAsync("StockUpdated", productId, productCode, currentStock, availableStock, status);

    public Task LowStockAlertAsync(Guid productId, string productCode, decimal currentStock, decimal minStock) =>
        hub.Clients.All.SendAsync("LowStockAlert", productId, productCode, currentStock, minStock);
}
