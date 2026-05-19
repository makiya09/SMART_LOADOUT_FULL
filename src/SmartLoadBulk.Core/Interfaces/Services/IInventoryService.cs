using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Inventory;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface IInventoryService
{
    Task<List<ProductStockDto>> GetAllStockAsync();
    Task<ProductStockDto?> GetProductStockAsync(Guid productId);
    Task<PagedResponse<InventoryHistoryDto>> GetHistoryAsync(int page, int pageSize);
    Task<bool> AdjustStockAsync(InventoryAdjustRequest request, Guid userId);
}
