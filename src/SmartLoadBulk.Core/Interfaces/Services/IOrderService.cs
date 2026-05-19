using SmartLoadBulk.Core.DTOs.Common;
using SmartLoadBulk.Core.DTOs.Order;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface IOrderService
{
    Task<PagedResponse<OrderListDto>> GetOrdersAsync(int page, int pageSize, string? status = null);
    Task<OrderDetailDto?> GetOrderByIdAsync(Guid orderId);
    Task<OrderDetailDto> CreateOrderAsync(CreateOrderRequest request, Guid userId);
    Task<bool> UpdateStatusAsync(Guid orderId, UpdateOrderStatusRequest request);
    Task<bool> CancelOrderAsync(Guid orderId, Guid userId);
}
