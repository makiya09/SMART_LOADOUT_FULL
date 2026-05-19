using SmartLoadBulk.Core.DTOs.Queue;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface IQueueService
{
    Task<List<QueueItemDto>> GetQueueBoardAsync();
    Task<QueueItemDto> EnqueueAsync(EnqueueRequest request);
    Task<bool> UpdatePriorityAsync(Guid queueId, UpdateQueuePriorityRequest request);
    Task<bool> CancelQueueAsync(Guid queueId);
}
