using Microsoft.EntityFrameworkCore;
using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Inventory;
using SmartLoadBulk.Core.Interfaces.Services;
using SmartLoadBulk.Infrastructure.Data;

namespace SmartLoadBulk.Infrastructure.Services;

public class InventoryService(SmartLoadBulkDbContext db, IInventoryEventPublisher events) : IInventoryService
{
    public async Task<List<ProductStockDto>> GetAllStockAsync()
    {
        var products = await db.Products
            .Where(p => p.IsActive)
            .Include(p => p.Silos.Where(s => s.IsActive))
            .Include(p => p.Inventories)
            .ToListAsync();

        return products.Select(p =>
        {
            var totalCurrent = p.Inventories.Sum(i => i.CurrentStock);
            var totalReserved = p.Inventories.Sum(i => i.ReservedStock);
            var available = totalCurrent - totalReserved;
            var status = totalCurrent <= p.CriticalStock ? "CRITICAL"
                       : totalCurrent <= p.MinStock ? "LOW" : "NORMAL";

            var silos = p.Silos.Select(s =>
            {
                var inv = p.Inventories.FirstOrDefault(i => i.SiloId == s.SiloId);
                var stock = inv?.CurrentStock ?? 0;
                return new SiloStockDto(s.SiloId, s.SiloCode, s.SiloName, s.Capacity, stock,
                    s.Capacity > 0 ? Math.Round(stock / s.Capacity * 100, 2) : 0);
            }).ToList();

            return new ProductStockDto(p.ProductId, p.ProductCode, p.ProductName, p.Unit,
                totalCurrent, totalReserved, available, p.MinStock, p.CriticalStock, status, silos);
        }).ToList();
    }

    public async Task<ProductStockDto?> GetProductStockAsync(Guid productId)
    {
        var all = await GetAllStockAsync();
        return all.FirstOrDefault(p => p.ProductId == productId);
    }

    public async Task<PagedResponse<InventoryHistoryDto>> GetHistoryAsync(int page, int pageSize)
    {
        await Task.CompletedTask;
        return new PagedResponse<InventoryHistoryDto> { Page = page, PageSize = pageSize };
    }

    public async Task<bool> AdjustStockAsync(InventoryAdjustRequest request, Guid userId)
    {
        var inv = await db.Inventories
            .FirstOrDefaultAsync(i => i.ProductId == request.ProductId && i.SiloId == request.SiloId);
        if (inv is null) return false;

        if (request.ChangeType == "IN")
            inv.CurrentStock += request.Qty;
        else if (request.ChangeType == "OUT")
            inv.CurrentStock -= request.Qty;
        else if (request.ChangeType == "ADJUST")
            inv.CurrentStock = request.Qty;

        inv.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();

        // Push real-time event to connected clients
        var stock = await GetProductStockAsync(request.ProductId);
        if (stock is not null)
        {
            await events.StockUpdatedAsync(stock.ProductId, stock.ProductCode,
                stock.CurrentStock, stock.AvailableStock, stock.StockStatus);

            if (stock.StockStatus is "LOW" or "CRITICAL")
                await events.LowStockAlertAsync(stock.ProductId, stock.ProductCode,
                    stock.CurrentStock, stock.MinStock);
        }

        return true;
    }
}
