using SmartLoadBulk.Core.DTOs.Check;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface IChecklistService
{
    Task<ChecklistDto?> GetChecklistByJobIdAsync(Guid jobId);
    Task<bool> RecordActualWeightAsync(Guid jobId, RecordActualWeightRequest request, Guid userId);
    Task<bool> TickItemAsync(Guid jobId, Guid itemId, TickChecklistItemRequest request, Guid userId);
    Task<bool> ReleaseGateAsync(Guid jobId, ReleaseGateRequest request, Guid userId);
}
