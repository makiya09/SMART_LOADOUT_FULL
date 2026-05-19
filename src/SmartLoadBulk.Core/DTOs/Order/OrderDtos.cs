namespace SmartLoadBulk.Core.DTOs.Order;

public record OrderListDto(
    Guid OrderId,
    string OrderCode,
    string CustomerName,
    DateTime OrderDate,
    DateTime RequiredDate,
    string Status,
    decimal TotalWeight,
    int ItemCount,
    DateTime CreatedAt
);

public record OrderDetailDto(
    Guid OrderId,
    string OrderCode,
    Guid CustomerId,
    string CustomerName,
    DateTime OrderDate,
    DateTime RequiredDate,
    string Status,
    decimal TotalWeight,
    string? Remark,
    List<OrderItemDto> Items,
    DateTime CreatedAt
);

public record OrderItemDto(
    Guid ItemId,
    Guid ProductId,
    string ProductCode,
    string ProductName,
    decimal RequestedQty,
    decimal? ActualQty,
    string Unit
);

public record CreateOrderRequest(
    Guid CustomerId,
    DateTime RequiredDate,
    string? Remark,
    List<CreateOrderItemRequest> Items
);

public record CreateOrderItemRequest(
    Guid ProductId,
    decimal RequestedQty,
    string Unit
);

public record UpdateOrderStatusRequest(string Status, string? Remark);
