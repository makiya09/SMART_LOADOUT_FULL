namespace SmartLoadBulk.Core.Interfaces.Services;

public interface INotificationService
{
    Task<List<object>> GetNotificationsAsync(int limit = 50);
    Task<bool> MarkReadAsync(long notificationId);
}
