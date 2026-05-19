using SmartLoadBulk.Core.DTOs.Analytics;

namespace SmartLoadBulk.Core.Interfaces.Services;

public interface IAnalyticsService
{
    Task<PerformanceDashboardDto> GetPerformanceDashboardAsync(AnalyticsQueryParams query);
    Task<LossYieldDashboardDto> GetLossYieldDashboardAsync(AnalyticsQueryParams query);
    Task<BayPerformanceDashboardDto> GetBayPerformanceDashboardAsync(AnalyticsQueryParams query);
    Task<TurnaroundDashboardDto> GetTurnaroundDashboardAsync(AnalyticsQueryParams query);
    Task<List<AnalyticsConfigDto>> GetConfigAsync();
    Task<bool> UpdateConfigAsync(string configKey, UpdateAnalyticsConfigRequest request);
}
