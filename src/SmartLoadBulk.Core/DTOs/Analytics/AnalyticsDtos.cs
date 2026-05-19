namespace SmartLoadBulk.Core.DTOs.Analytics;

public record AnalyticsQueryParams(
    DateTime DateFrom,
    DateTime DateTo,
    string? Shift = null,
    Guid? BayId = null,
    Guid? ProductId = null,
    Guid? TruckId = null
);

// ─── Performance Dashboard ─────────────────────────────────────────────────────

public record PerformanceDashboardDto(
    PerformanceKpiDto Kpi,
    List<DailyTrendDto> DailyTrend,
    List<BaySummaryDto> BaySummary,
    List<ShiftSummaryDto> ShiftSummary
);

public record PerformanceKpiDto(
    int TotalJobs, int CompletedJobs, int CancelledJobs, int FailedJobs,
    double CompletionRatePct, double OverallYieldPct,
    decimal TotalLossKg, decimal TotalOverKg, decimal TotalActualTon,
    double AvgAccuracyPct, double AvgLoadingMin, double? AvgThroughput
);

public record DailyTrendDto(
    DateTime Date, int TotalJobs, int CompletedJobs,
    decimal TotalActualTon, double YieldPct,
    double AccuracyPct, double? ThroughputTonPerHour, double AvgLoadingMin
);

public record BaySummaryDto(
    string BayCode, string BayName, int TotalJobs, int CompletedJobs,
    decimal TotalActualTon, double AvgLoadingMin, double AvgYieldPct,
    double? AvgThroughput, double AvgUtilizationPct
);

public record ShiftSummaryDto(
    string ShiftName, int TotalJobs, int CompletedJobs,
    decimal TotalActualTon, double AvgYieldPct, double AvgLoadingMin
);

// ─── Loss/Yield Dashboard ──────────────────────────────────────────────────────

public record LossYieldDashboardDto(
    LossYieldKpiDto Kpi,
    List<DailyLossTrendDto> DailyTrend,
    List<ProductLossDto> ProductLoss,
    List<LossJobDetailDto> JobDetails
);

public record LossYieldKpiDto(
    int TotalJobs, decimal TotalTargetKg, decimal TotalActualKg,
    double OverallYieldPct, decimal TotalLossKg, decimal TotalOverKg,
    double AvgYieldPct, double MinYieldPct, double MaxYieldPct, double AvgYieldStdDev
);

public record DailyLossTrendDto(
    DateTime Date, double DailyYieldPct,
    decimal TotalLossKg, decimal TotalOverKg, int TotalJobs
);

public record ProductLossDto(
    string ProductCode, string ProductName,
    int TotalJobs, decimal TotalLossKg, double AvgYieldPct, double YieldStdDev
);

public record LossJobDetailDto(
    Guid JobId, string JobCode, DateTime WorkDate, string BayName,
    string LicensePlate, string DriverName, string ProductName,
    decimal TargetWeight, decimal ActualWeight,
    decimal LossKg, decimal OverKg, double YieldPct, double LoadingDurationMin
);

// ─── Bay Performance Dashboard ─────────────────────────────────────────────────

public record BayPerformanceDashboardDto(
    List<BaySummaryExtDto> BaySummary,
    List<BayDayPerformanceDto> DailyData,
    List<HourlyHeatmapDto> HourlyData
);

public record BaySummaryExtDto(
    string BayCode, string BayName, int TotalJobs, int CompletedJobs,
    decimal TotalActualTon, int TotalLoadingMin, double AvgLoadingMin,
    double AvgYieldPct, double? AvgThroughput, double AvgUtilizationPct
);

public record BayDayPerformanceDto(
    DateTime Date, string BayCode, string BayName,
    int TotalJobs, int CompletedJobs, decimal TotalActualTon,
    double AvgLoadingMin, double BayYieldPct,
    double? ThroughputTonPerHour, double BayUtilizationPct
);

public record HourlyHeatmapDto(
    DateTime Date, int WorkHour, string BayCode, string BayName,
    int JobCount, decimal TotalActualTon, double? ThroughputTonPerHour
);

// ─── Turnaround Dashboard ──────────────────────────────────────────────────────

public record TurnaroundDashboardDto(
    TurnaroundKpiDto Kpi,
    List<TurnaroundDailyDto> DailyTrend,
    List<TurnaroundJobDto> JobDetails
);

public record TurnaroundKpiDto(
    int TotalJobs, double AvgTurnaroundMin, int MinTurnaroundMin, int MaxTurnaroundMin,
    double AvgQueueWaitMin, double AvgDockingMin, double AvgLoadingMin, double AvgChecklistMin
);

public record TurnaroundDailyDto(
    DateTime Date, double AvgTurnaroundMin,
    double AvgQueueWaitMin, double AvgLoadingMin, int JobCount
);

public record TurnaroundJobDto(
    Guid JobId, string JobCode, DateTime WorkDate,
    string LicensePlate, string? TransportCompany, string DriverName, string BayName,
    double QueueWaitMin, double DockingMin, double LoadingMin,
    double ChecklistMin, double TurnaroundMin, double YieldPct
);

// ─── Analytics Config ──────────────────────────────────────────────────────────

public record AnalyticsConfigDto(
    string ConfigKey, string? ConfigGroup,
    decimal ConfigValue, string? Unit, string? Description
);

public record UpdateAnalyticsConfigRequest(decimal ConfigValue);
