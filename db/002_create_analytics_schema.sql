-- ============================================================
--  Smart Load Bulk — Analytics Schema (ana)
--  ออกแบบโดย: Hawkeye | วันที่: 2026-05-13 | Version: 1.0
--  Prerequisites: 001_create_smart_load_bulk_tables.sql ต้องรันก่อน
-- ============================================================
-- วิธีรัน:
--   1. รัน 001_create_smart_load_bulk_tables.sql ก่อน
--   2. รัน Script นี้ใน SSMS (F5)
--   3. ตรวจสอบ Quick Verify ท้าย Script
-- ============================================================

USE SmartLoadBulkDB;
GO

-- ============================================================
-- SECTION 1: Create Schema ana
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ana')
BEGIN
    EXEC('CREATE SCHEMA ana');
    PRINT 'Created schema: ana';
END
GO

-- ============================================================
-- SECTION 2: AnalyticsConfig Table — Threshold ตั้งค่าได้
-- ============================================================

IF OBJECT_ID('ana.AnalyticsConfig', 'U') IS NULL
CREATE TABLE ana.AnalyticsConfig (
    ConfigKey   VARCHAR(60)      NOT NULL,
    ConfigValue NVARCHAR(100)    NOT NULL,
    DataType    VARCHAR(10)      NOT NULL DEFAULT 'DECIMAL'
                                 CONSTRAINT CK_Config_DataType CHECK (DataType IN ('DECIMAL','INT','VARCHAR')),
    Description NVARCHAR(200)    NULL,
    UpdatedAt   DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    UpdatedBy   UNIQUEIDENTIFIER NULL,
    CONSTRAINT PK_AnalyticsConfig PRIMARY KEY (ConfigKey)
);
GO

-- Seed Default Thresholds
MERGE ana.AnalyticsConfig AS tgt
USING (VALUES
    -- Yield %
    ('YIELD_NORMAL_MIN',        '99.50',  'DECIMAL', N'Yield% ขั้นต่ำที่ถือว่า NORMAL'),
    ('YIELD_NORMAL_MAX',        '100.50', 'DECIMAL', N'Yield% สูงสุดที่ถือว่า NORMAL'),
    ('YIELD_WARNING_MIN',       '99.00',  'DECIMAL', N'Yield% ขั้นต่ำก่อนเป็น CRITICAL'),
    ('YIELD_WARNING_MAX',       '101.00', 'DECIMAL', N'Yield% สูงสุดก่อนเป็น CRITICAL'),
    -- Loading Accuracy
    ('ACCURACY_GOOD_MIN',       '95.00',  'DECIMAL', N'Accuracy% ขั้นต่ำ GOOD'),
    ('ACCURACY_WARNING_MIN',    '85.00',  'DECIMAL', N'Accuracy% ขั้นต่ำ WARNING'),
    -- Loading Time (minutes)
    ('LOAD_TIME_FAST_MAX',      '45',     'INT',     N'Loading ≤ นาทีนี้ถือว่า FAST'),
    ('LOAD_TIME_NORMAL_MAX',    '60',     'INT',     N'Loading ≤ นาทีนี้ถือว่า NORMAL'),
    -- Waiting Time (minutes)
    ('WAIT_TIME_OK_MAX',        '20',     'INT',     N'Waiting ≤ นาทีนี้ถือว่า OK'),
    ('WAIT_TIME_LONG_MAX',      '30',     'INT',     N'Waiting ≤ นาทีนี้ถือว่า LONG'),
    -- Turnaround Time (minutes)
    ('TURN_FAST_MAX',           '90',     'INT',     N'Turnaround ≤ นาทีนี้ถือว่า FAST'),
    ('TURN_NORMAL_MAX',         '120',    'INT',     N'Turnaround ≤ นาทีนี้ถือว่า NORMAL'),
    -- Bay Utilization %
    ('BAY_UTIL_GOOD_MIN',       '70.00',  'DECIMAL', N'Utilization% ขั้นต่ำ GOOD'),
    ('BAY_UTIL_GOOD_MAX',       '85.00',  'DECIMAL', N'Utilization% สูงสุด GOOD (เกินนี้ = OVERLOADED)'),
    -- Throughput (ton/hour)
    ('THROUGHPUT_HIGH_MIN',     '25.00',  'DECIMAL', N'Throughput ≥ นี้ถือว่า HIGH'),
    ('THROUGHPUT_NORMAL_MIN',   '15.00',  'DECIMAL', N'Throughput ≥ นี้ถือว่า NORMAL'),
    -- Loss Alert
    ('LOSS_ALERT_PCT',          '0.50',   'DECIMAL', N'Loss% ต่องานที่จะ Alert'),
    ('LOSS_DAILY_ALERT_KG',     '500',    'INT',     N'Loss Kg ต่อวันที่จะ Notify Supervisor')
) AS src (ConfigKey, ConfigValue, DataType, Description)
ON tgt.ConfigKey = src.ConfigKey
WHEN NOT MATCHED THEN
    INSERT (ConfigKey, ConfigValue, DataType, Description)
    VALUES (src.ConfigKey, src.ConfigValue, src.DataType, src.Description);
GO

PRINT '  AnalyticsConfig created and seeded.';
GO

-- ============================================================
-- SECTION 3: Views
-- ============================================================

PRINT '-- Creating Analytics Views...';
GO

-- --------------------------------------------------------
-- ana.vw_JobPerformance — KPI ทุกตัวต่อ 1 Job
-- --------------------------------------------------------
CREATE OR ALTER VIEW ana.vw_JobPerformance AS
SELECT
    j.JobId,
    j.JobCode,
    j.OrderId,
    j.BayId,
    b.BayCode,
    b.BayName,
    j.TruckId,
    t.LicensePlate,
    t.TruckType,
    j.DriverId,
    d.FullName                                           AS DriverName,
    j.ProductId,
    p.ProductCode,
    p.ProductName,
    p.Unit,
    j.TargetWeight,
    ISNULL(j.ActualWeight, 0)                            AS ActualWeight,
    j.TolerancePct,

    -- Diff
    ISNULL(j.ActualWeight, 0) - j.TargetWeight           AS DiffKg,
    CASE WHEN j.TargetWeight > 0
         THEN (ISNULL(j.ActualWeight, 0) - j.TargetWeight) / j.TargetWeight * 100.0
         ELSE 0 END                                      AS DiffPct,

    -- Yield
    CASE WHEN j.TargetWeight > 0
         THEN ISNULL(j.ActualWeight, 0) / j.TargetWeight * 100.0
         ELSE 0 END                                      AS YieldPct,

    -- Loss / Over
    CASE WHEN ISNULL(j.ActualWeight, 0) < j.TargetWeight
         THEN j.TargetWeight - j.ActualWeight ELSE 0 END AS LossKg,
    CASE WHEN ISNULL(j.ActualWeight, 0) > j.TargetWeight
         THEN j.ActualWeight - j.TargetWeight ELSE 0 END AS OverKg,

    -- Accuracy flag
    CASE WHEN j.TargetWeight > 0
              AND ABS((ISNULL(j.ActualWeight,0) - j.TargetWeight) / j.TargetWeight * 100.0) <= j.TolerancePct
         THEN 1 ELSE 0 END                               AS IsAccurate,

    -- Timing
    j.StartedAt,
    j.CompletedAt,
    DATEDIFF(MINUTE, j.StartedAt, j.CompletedAt)        AS LoadingMinutes,

    -- Throughput (ton/hr)
    CASE WHEN DATEDIFF(MINUTE, j.StartedAt, j.CompletedAt) > 0
         THEN (ISNULL(j.ActualWeight, 0) / 1000.0)
              / (DATEDIFF(MINUTE, j.StartedAt, j.CompletedAt) / 60.0)
         ELSE 0 END                                      AS ThroughputTonPerHour,

    j.Status,
    CAST(j.CompletedAt AS DATE)                          AS LoadDate,
    DATEPART(HOUR, j.StartedAt)                          AS LoadHour
FROM slb.LoadJobs  j
JOIN slb.Bays      b ON b.BayId     = j.BayId
JOIN slb.Trucks    t ON t.TruckId   = j.TruckId
JOIN slb.Drivers   d ON d.DriverId  = j.DriverId
JOIN slb.Products  p ON p.ProductId = j.ProductId
WHERE j.Status = 'COMPLETED'
  AND j.ActualWeight IS NOT NULL;
GO

-- --------------------------------------------------------
-- ana.vw_QueuePerformance — Timing ต่อ Queue (DONE เท่านั้น)
-- --------------------------------------------------------
CREATE OR ALTER VIEW ana.vw_QueuePerformance AS
SELECT
    q.QueueId,
    q.OrderId,
    q.TruckId,
    t.LicensePlate,
    t.TruckType,
    q.DriverId,
    d.FullName                                              AS DriverName,
    q.Priority,
    q.EnqueuedAt,
    q.CalledAt,
    q.DockedAt,
    q.CompletedAt,

    -- Waiting: เข้าคิว → ถูกเรียก
    DATEDIFF(MINUTE, q.EnqueuedAt, q.CalledAt)             AS WaitingMinutes,
    -- Call to Dock: ถูกเรียก → รถจอด
    DATEDIFF(MINUTE, q.CalledAt,   q.DockedAt)             AS CallToDockedMinutes,
    -- Turnaround: เข้าคิว → งานเสร็จ
    DATEDIFF(MINUTE, q.EnqueuedAt, q.CompletedAt)          AS TurnaroundMinutes,

    CAST(q.EnqueuedAt AS DATE)                             AS QueueDate,
    DATEPART(HOUR, q.EnqueuedAt)                           AS QueueHour
FROM slb.LoadQueues q
JOIN slb.Trucks     t ON t.TruckId  = q.TruckId
JOIN slb.Drivers    d ON d.DriverId = q.DriverId
WHERE q.Status     = 'DONE'
  AND q.CompletedAt IS NOT NULL
  AND q.CalledAt    IS NOT NULL;
GO

-- --------------------------------------------------------
-- ana.vw_DailyPerformance — Summary KPI รายวัน
-- --------------------------------------------------------
CREATE OR ALTER VIEW ana.vw_DailyPerformance AS
SELECT
    jp.LoadDate,
    COUNT(jp.JobId)                                              AS TotalJobs,
    SUM(jp.TargetWeight)                                         AS TotalTargetKg,
    SUM(jp.ActualWeight)                                         AS TotalActualKg,
    SUM(jp.DiffKg)                                               AS TotalDiffKg,
    SUM(jp.LossKg)                                               AS TotalLossKg,
    SUM(jp.OverKg)                                               AS TotalOverKg,
    CASE WHEN SUM(jp.TargetWeight) > 0
         THEN SUM(jp.ActualWeight) / SUM(jp.TargetWeight) * 100.0
         ELSE 0 END                                              AS YieldPct,
    CASE WHEN SUM(jp.TargetWeight) > 0
         THEN SUM(jp.LossKg) / SUM(jp.TargetWeight) * 100.0
         ELSE 0 END                                              AS LossPct,
    AVG(CAST(jp.LoadingMinutes  AS FLOAT))                       AS AvgLoadingMinutes,
    AVG(jp.ThroughputTonPerHour)                                 AS AvgThroughputTonPerHour,
    SUM(CASE WHEN jp.IsAccurate = 1 THEN 1.0 ELSE 0 END)
        / NULLIF(COUNT(jp.JobId), 0) * 100.0                    AS AccuracyPct,
    COUNT(DISTINCT jp.BayId)                                     AS ActiveBays,
    COUNT(DISTINCT jp.TruckId)                                   AS UniqueTrucks
FROM ana.vw_JobPerformance jp
GROUP BY jp.LoadDate;
GO

-- --------------------------------------------------------
-- ana.vw_BayPerformance — Bay KPI รายวัน
-- --------------------------------------------------------
CREATE OR ALTER VIEW ana.vw_BayPerformance AS
SELECT
    jp.LoadDate,
    jp.BayId,
    jp.BayCode,
    jp.BayName,
    COUNT(jp.JobId)                                              AS TotalJobs,
    SUM(jp.TargetWeight)                                         AS TotalTargetKg,
    SUM(jp.ActualWeight)                                         AS TotalActualKg,
    SUM(jp.LossKg)                                               AS TotalLossKg,
    SUM(jp.OverKg)                                               AS TotalOverKg,
    CASE WHEN SUM(jp.TargetWeight) > 0
         THEN SUM(jp.ActualWeight) / SUM(jp.TargetWeight) * 100.0
         ELSE 0 END                                              AS YieldPct,
    SUM(CASE WHEN jp.IsAccurate = 1 THEN 1.0 ELSE 0 END)
        / NULLIF(COUNT(jp.JobId), 0) * 100.0                    AS AccuracyPct,
    SUM(jp.LoadingMinutes)                                       AS TotalLoadingMinutes,
    AVG(CAST(jp.LoadingMinutes AS FLOAT))                        AS AvgLoadingMinutes,
    -- Utilization = นาทีที่โหลดจริง / 24 ชั่วโมง (1,440 นาที)
    SUM(jp.LoadingMinutes) * 100.0 / 1440.0                     AS UtilizationPct,
    AVG(jp.ThroughputTonPerHour)                                 AS AvgThroughputTonPerHour
FROM ana.vw_JobPerformance jp
GROUP BY jp.LoadDate, jp.BayId, jp.BayCode, jp.BayName;
GO

-- --------------------------------------------------------
-- ana.vw_ProductLossYield — Loss/Yield รายสินค้า รายวัน
-- --------------------------------------------------------
CREATE OR ALTER VIEW ana.vw_ProductLossYield AS
SELECT
    jp.LoadDate,
    jp.ProductId,
    jp.ProductCode,
    jp.ProductName,
    jp.Unit,
    COUNT(jp.JobId)                                              AS TotalJobs,
    SUM(jp.TargetWeight)                                         AS TotalTargetKg,
    SUM(jp.ActualWeight)                                         AS TotalActualKg,
    SUM(jp.DiffKg)                                               AS TotalDiffKg,
    SUM(jp.LossKg)                                               AS TotalLossKg,
    SUM(jp.OverKg)                                               AS TotalOverKg,
    CASE WHEN SUM(jp.TargetWeight) > 0
         THEN SUM(jp.ActualWeight) / SUM(jp.TargetWeight) * 100.0
         ELSE 0 END                                              AS YieldPct,
    CASE WHEN SUM(jp.TargetWeight) > 0
         THEN SUM(jp.LossKg) / SUM(jp.TargetWeight) * 100.0
         ELSE 0 END                                              AS LossPct,
    CASE WHEN SUM(jp.TargetWeight) > 0
         THEN SUM(jp.OverKg) / SUM(jp.TargetWeight) * 100.0
         ELSE 0 END                                              AS OverPct,
    SUM(CASE WHEN jp.IsAccurate = 1 THEN 1.0 ELSE 0 END)
        / NULLIF(COUNT(jp.JobId), 0) * 100.0                    AS AccuracyPct,
    AVG(CAST(jp.LoadingMinutes AS FLOAT))                        AS AvgLoadingMinutes
FROM ana.vw_JobPerformance jp
GROUP BY jp.LoadDate, jp.ProductId, jp.ProductCode, jp.ProductName, jp.Unit;
GO

-- --------------------------------------------------------
-- ana.vw_TruckTurnaround — Turnaround รายรถ รายวัน
-- --------------------------------------------------------
CREATE OR ALTER VIEW ana.vw_TruckTurnaround AS
SELECT
    qp.QueueDate,
    qp.TruckId,
    qp.LicensePlate,
    qp.TruckType,
    qp.DriverId,
    qp.DriverName,
    COUNT(qp.QueueId)                          AS TotalRounds,
    AVG(CAST(qp.WaitingMinutes    AS FLOAT))   AS AvgWaitingMinutes,
    AVG(CAST(qp.CallToDockedMinutes AS FLOAT)) AS AvgCallToDockedMinutes,
    AVG(CAST(qp.TurnaroundMinutes AS FLOAT))   AS AvgTurnaroundMinutes,
    MIN(qp.TurnaroundMinutes)                  AS MinTurnaroundMinutes,
    MAX(qp.TurnaroundMinutes)                  AS MaxTurnaroundMinutes,
    SUM(qp.TurnaroundMinutes)                  AS TotalTurnaroundMinutes
FROM ana.vw_QueuePerformance qp
GROUP BY qp.QueueDate, qp.TruckId, qp.LicensePlate, qp.TruckType, qp.DriverId, qp.DriverName;
GO

-- --------------------------------------------------------
-- ana.vw_HourlyThroughput — Throughput รายชั่วโมง (สำหรับ Heatmap)
-- --------------------------------------------------------
CREATE OR ALTER VIEW ana.vw_HourlyThroughput AS
SELECT
    jp.LoadDate,
    jp.BayId,
    jp.BayCode,
    jp.LoadHour,
    COUNT(jp.JobId)                AS JobCount,
    SUM(jp.ActualWeight) / 1000.0  AS TotalActualTon,
    SUM(jp.LoadingMinutes)         AS TotalLoadingMinutes,
    CASE WHEN SUM(jp.LoadingMinutes) > 0
         THEN (SUM(jp.ActualWeight) / 1000.0) / (SUM(jp.LoadingMinutes) / 60.0)
         ELSE 0 END                AS ThroughputTonPerHour
FROM ana.vw_JobPerformance jp
GROUP BY jp.LoadDate, jp.BayId, jp.BayCode, jp.LoadHour;
GO

PRINT '  Analytics Views created.';
GO

-- ============================================================
-- SECTION 4: Stored Procedures
-- ============================================================

PRINT '-- Creating Analytics Stored Procedures...';
GO

-- --------------------------------------------------------
-- ana.sp_GetPerformanceDashboard
-- --------------------------------------------------------
CREATE OR ALTER PROCEDURE ana.sp_GetPerformanceDashboard
    @DateFrom  DATE             = NULL,
    @DateTo    DATE             = NULL,
    @BayId     UNIQUEIDENTIFIER = NULL,
    @ProductId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Default: วันนี้
    SET @DateFrom  = ISNULL(@DateFrom,  CAST(GETDATE() AS DATE));
    SET @DateTo    = ISNULL(@DateTo,    CAST(GETDATE() AS DATE));

    -- 1. KPI Summary (Period)
    SELECT
        COUNT(jp.JobId)                                          AS TotalJobs,
        SUM(jp.TargetWeight)                                     AS TotalTargetKg,
        SUM(jp.ActualWeight)                                     AS TotalActualKg,
        SUM(jp.DiffKg)                                           AS TotalDiffKg,
        SUM(jp.LossKg)                                           AS TotalLossKg,
        SUM(jp.OverKg)                                           AS TotalOverKg,
        CASE WHEN SUM(jp.TargetWeight) > 0
             THEN SUM(jp.ActualWeight) / SUM(jp.TargetWeight) * 100.0
             ELSE 0 END                                          AS YieldPct,
        SUM(CASE WHEN jp.IsAccurate=1 THEN 1.0 ELSE 0 END)
            / NULLIF(COUNT(jp.JobId),0) * 100.0                 AS AccuracyPct,
        AVG(CAST(jp.LoadingMinutes AS FLOAT))                    AS AvgLoadingMinutes,
        AVG(jp.ThroughputTonPerHour)                             AS AvgThroughputTonPerHour,
        COUNT(DISTINCT jp.TruckId)                               AS UniqueTrucks
    FROM ana.vw_JobPerformance jp
    WHERE jp.LoadDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId     IS NULL OR jp.BayId     = @BayId)
      AND (@ProductId IS NULL OR jp.ProductId = @ProductId);

    -- 2. Live Status (ตอนนี้)
    SELECT
        COUNT(CASE WHEN q.Status = 'WAITING'  THEN 1 END) AS WaitingCount,
        COUNT(CASE WHEN q.Status = 'CALLED'   THEN 1 END) AS CalledCount,
        COUNT(CASE WHEN q.Status = 'DOCKED'   THEN 1 END) AS DockedCount,
        COUNT(CASE WHEN q.Status = 'LOADING'  THEN 1 END) AS LoadingCount
    FROM slb.LoadQueues q
    WHERE q.Status NOT IN ('DONE','CANCELLED');

    -- 3. Daily Trend
    SELECT
        dp.LoadDate,
        dp.TotalJobs,
        dp.TotalActualKg,
        dp.YieldPct,
        dp.AccuracyPct,
        dp.AvgLoadingMinutes,
        dp.AvgThroughputTonPerHour
    FROM ana.vw_DailyPerformance dp
    WHERE dp.LoadDate BETWEEN @DateFrom AND @DateTo
    ORDER BY dp.LoadDate;

    -- 4. Throughput by Bay (Period)
    SELECT
        bp.BayCode,
        bp.BayName,
        SUM(bp.TotalJobs)              AS TotalJobs,
        SUM(bp.TotalActualKg) / 1000.0 AS TotalActualTon,
        AVG(bp.AvgThroughputTonPerHour)AS AvgThroughput,
        AVG(bp.UtilizationPct)         AS AvgUtilizationPct
    FROM ana.vw_BayPerformance bp
    WHERE bp.LoadDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId IS NULL OR bp.BayId = @BayId)
    GROUP BY bp.BayId, bp.BayCode, bp.BayName
    ORDER BY AvgThroughput DESC;
END
GO

-- --------------------------------------------------------
-- ana.sp_GetLossYieldDashboard
-- --------------------------------------------------------
CREATE OR ALTER PROCEDURE ana.sp_GetLossYieldDashboard
    @DateFrom  DATE             = NULL,
    @DateTo    DATE             = NULL,
    @ProductId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @DateFrom = ISNULL(@DateFrom, CAST(GETDATE() AS DATE));
    SET @DateTo   = ISNULL(@DateTo,   CAST(GETDATE() AS DATE));

    -- 1. Period Summary
    SELECT
        SUM(jp.LossKg)                                           AS TotalLossKg,
        SUM(jp.OverKg)                                           AS TotalOverKg,
        SUM(jp.DiffKg)                                           AS NetDiffKg,
        CASE WHEN SUM(jp.TargetWeight) > 0
             THEN SUM(jp.ActualWeight) / SUM(jp.TargetWeight) * 100.0
             ELSE 0 END                                          AS AvgYieldPct,
        CASE WHEN SUM(jp.TargetWeight) > 0
             THEN SUM(jp.LossKg) / SUM(jp.TargetWeight) * 100.0
             ELSE 0 END                                          AS LossPct,
        COUNT(CASE WHEN jp.LossKg > 0 THEN 1 END)               AS JobsWithLoss,
        COUNT(CASE WHEN jp.OverKg  > 0 THEN 1 END)              AS JobsWithOver,
        COUNT(jp.JobId)                                          AS TotalJobs
    FROM ana.vw_JobPerformance jp
    WHERE jp.LoadDate BETWEEN @DateFrom AND @DateTo
      AND (@ProductId IS NULL OR jp.ProductId = @ProductId);

    -- 2. Daily Loss vs Over
    SELECT
        dp.LoadDate,
        dp.TotalLossKg,
        dp.TotalOverKg,
        dp.NetDiffKg,  -- ลบออก: dp.TotalDiffKg
        dp.YieldPct,
        dp.LossPct
    FROM ana.vw_DailyPerformance dp
    WHERE dp.LoadDate BETWEEN @DateFrom AND @DateTo
    ORDER BY dp.LoadDate;

    -- 3. Product Loss Ranking
    SELECT TOP 10
        py.ProductCode,
        py.ProductName,
        py.Unit,
        SUM(py.TotalLossKg)    AS TotalLossKg,
        SUM(py.TotalOverKg)    AS TotalOverKg,
        SUM(py.TotalTargetKg)  AS TotalTargetKg,
        CASE WHEN SUM(py.TotalTargetKg) > 0
             THEN SUM(py.TotalLossKg) / SUM(py.TotalTargetKg) * 100.0
             ELSE 0 END        AS LossPct,
        CASE WHEN SUM(py.TotalTargetKg) > 0
             THEN SUM(py.TotalActualKg) / SUM(py.TotalTargetKg) * 100.0
             ELSE 0 END        AS YieldPct,
        SUM(py.TotalJobs)      AS TotalJobs
    FROM ana.vw_ProductLossYield py
    WHERE py.LoadDate BETWEEN @DateFrom AND @DateTo
      AND (@ProductId IS NULL OR py.ProductId = @ProductId)
    GROUP BY py.ProductId, py.ProductCode, py.ProductName, py.Unit
    ORDER BY TotalLossKg DESC;
END
GO

-- --------------------------------------------------------
-- ana.sp_GetBayPerformanceDashboard
-- --------------------------------------------------------
CREATE OR ALTER PROCEDURE ana.sp_GetBayPerformanceDashboard
    @DateFrom DATE             = NULL,
    @DateTo   DATE             = NULL,
    @BayId    UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @DateFrom = ISNULL(@DateFrom, CAST(GETDATE() AS DATE));
    SET @DateTo   = ISNULL(@DateTo,   CAST(GETDATE() AS DATE));

    -- 1. Bay Comparison Summary
    SELECT
        bp.BayId,
        bp.BayCode,
        bp.BayName,
        SUM(bp.TotalJobs)               AS TotalJobs,
        SUM(bp.TotalActualKg) / 1000.0  AS TotalActualTon,
        SUM(bp.TotalLossKg)             AS TotalLossKg,
        AVG(bp.YieldPct)                AS AvgYieldPct,
        AVG(bp.AccuracyPct)             AS AvgAccuracyPct,
        AVG(bp.AvgLoadingMinutes)       AS AvgLoadingMinutes,
        AVG(bp.AvgThroughputTonPerHour) AS AvgThroughputTonPerHour,
        AVG(bp.UtilizationPct)          AS AvgUtilizationPct
    FROM ana.vw_BayPerformance bp
    WHERE bp.LoadDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId IS NULL OR bp.BayId = @BayId)
    GROUP BY bp.BayId, bp.BayCode, bp.BayName
    ORDER BY AvgUtilizationPct DESC;

    -- 2. Bay Daily Trend
    SELECT
        bp.LoadDate,
        bp.BayCode,
        bp.TotalJobs,
        bp.YieldPct,
        bp.UtilizationPct,
        bp.AvgLoadingMinutes
    FROM ana.vw_BayPerformance bp
    WHERE bp.LoadDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId IS NULL OR bp.BayId = @BayId)
    ORDER BY bp.LoadDate, bp.BayCode;

    -- 3. Hourly Heatmap Data
    SELECT
        ht.LoadDate,
        ht.BayCode,
        ht.LoadHour,
        ht.JobCount,
        ht.TotalActualTon,
        ht.ThroughputTonPerHour
    FROM ana.vw_HourlyThroughput ht
    WHERE ht.LoadDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId IS NULL OR ht.BayId = @BayId)
    ORDER BY ht.LoadDate, ht.BayCode, ht.LoadHour;
END
GO

-- --------------------------------------------------------
-- ana.sp_GetTurnaroundDashboard
-- --------------------------------------------------------
CREATE OR ALTER PROCEDURE ana.sp_GetTurnaroundDashboard
    @DateFrom DATE             = NULL,
    @DateTo   DATE             = NULL,
    @TruckId  UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @DateFrom = ISNULL(@DateFrom, CAST(GETDATE() AS DATE));
    SET @DateTo   = ISNULL(@DateTo,   CAST(GETDATE() AS DATE));

    -- 1. Period Summary
    SELECT
        AVG(CAST(qp.TurnaroundMinutes   AS FLOAT)) AS AvgTurnaroundMinutes,
        AVG(CAST(qp.WaitingMinutes      AS FLOAT)) AS AvgWaitingMinutes,
        AVG(CAST(qp.CallToDockedMinutes AS FLOAT)) AS AvgCallToDockedMinutes,
        MIN(qp.TurnaroundMinutes)                  AS MinTurnaroundMinutes,
        MAX(qp.TurnaroundMinutes)                  AS MaxTurnaroundMinutes,
        COUNT(qp.QueueId)                          AS TotalRounds,
        COUNT(DISTINCT qp.TruckId)                 AS UniqueTrucks
    FROM ana.vw_QueuePerformance qp
    WHERE qp.QueueDate BETWEEN @DateFrom AND @DateTo
      AND (@TruckId IS NULL OR qp.TruckId = @TruckId);

    -- 2. Daily Turnaround Trend
    SELECT
        qp.QueueDate,
        AVG(CAST(qp.TurnaroundMinutes AS FLOAT)) AS AvgTurnaroundMinutes,
        AVG(CAST(qp.WaitingMinutes    AS FLOAT)) AS AvgWaitingMinutes,
        COUNT(qp.QueueId)                        AS TotalRounds
    FROM ana.vw_QueuePerformance qp
    WHERE qp.QueueDate BETWEEN @DateFrom AND @DateTo
      AND (@TruckId IS NULL OR qp.TruckId = @TruckId)
    GROUP BY qp.QueueDate
    ORDER BY qp.QueueDate;

    -- 3. Slowest Trucks (Top 10)
    SELECT TOP 10
        tt.LicensePlate,
        tt.TruckType,
        tt.DriverName,
        SUM(tt.TotalRounds)              AS TotalRounds,
        AVG(tt.AvgTurnaroundMinutes)     AS AvgTurnaroundMinutes,
        AVG(tt.AvgWaitingMinutes)        AS AvgWaitingMinutes,
        MAX(tt.MaxTurnaroundMinutes)     AS MaxTurnaroundMinutes
    FROM ana.vw_TruckTurnaround tt
    WHERE tt.QueueDate BETWEEN @DateFrom AND @DateTo
      AND (@TruckId IS NULL OR tt.TruckId = @TruckId)
    GROUP BY tt.TruckId, tt.LicensePlate, tt.TruckType, tt.DriverId, tt.DriverName
    ORDER BY AvgTurnaroundMinutes DESC;

    -- 4. Turnaround Distribution Buckets
    SELECT
        CASE
            WHEN qp.TurnaroundMinutes <= 60  THEN '0-60 min'
            WHEN qp.TurnaroundMinutes <= 90  THEN '60-90 min'
            WHEN qp.TurnaroundMinutes <= 120 THEN '90-120 min'
            ELSE '120+ min'
        END AS Bucket,
        COUNT(*) AS JobCount
    FROM ana.vw_QueuePerformance qp
    WHERE qp.QueueDate BETWEEN @DateFrom AND @DateTo
      AND (@TruckId IS NULL OR qp.TruckId = @TruckId)
    GROUP BY
        CASE
            WHEN qp.TurnaroundMinutes <= 60  THEN '0-60 min'
            WHEN qp.TurnaroundMinutes <= 90  THEN '60-90 min'
            WHEN qp.TurnaroundMinutes <= 120 THEN '90-120 min'
            ELSE '120+ min'
        END
    ORDER BY MIN(qp.TurnaroundMinutes);
END
GO

-- --------------------------------------------------------
-- ana.sp_GetProductLossAnalysis
-- --------------------------------------------------------
CREATE OR ALTER PROCEDURE ana.sp_GetProductLossAnalysis
    @DateFrom  DATE             = NULL,
    @DateTo    DATE             = NULL,
    @ProductId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @DateFrom = ISNULL(@DateFrom, CAST(GETDATE() AS DATE));
    SET @DateTo   = ISNULL(@DateTo,   CAST(GETDATE() AS DATE));

    -- Threshold จาก Config
    DECLARE @LossAlertPct DECIMAL(5,2) =
        CAST((SELECT ConfigValue FROM ana.AnalyticsConfig WHERE ConfigKey = 'LOSS_ALERT_PCT') AS DECIMAL(5,2));

    -- 1. Product Summary with Alert Status
    SELECT
        py.ProductId,
        py.ProductCode,
        py.ProductName,
        py.Unit,
        SUM(py.TotalJobs)      AS TotalJobs,
        SUM(py.TotalTargetKg)  AS TotalTargetKg,
        SUM(py.TotalActualKg)  AS TotalActualKg,
        SUM(py.TotalLossKg)    AS TotalLossKg,
        SUM(py.TotalOverKg)    AS TotalOverKg,
        CASE WHEN SUM(py.TotalTargetKg) > 0
             THEN SUM(py.TotalLossKg) / SUM(py.TotalTargetKg) * 100.0
             ELSE 0 END                 AS LossPct,
        CASE WHEN SUM(py.TotalTargetKg) > 0
             THEN SUM(py.TotalActualKg) / SUM(py.TotalTargetKg) * 100.0
             ELSE 0 END                 AS YieldPct,
        AVG(py.AccuracyPct)             AS AvgAccuracyPct,
        CASE
            WHEN SUM(py.TotalTargetKg) > 0
                 AND SUM(py.TotalLossKg) / SUM(py.TotalTargetKg) * 100.0 > @LossAlertPct * 2
                 THEN 'CRITICAL'
            WHEN SUM(py.TotalTargetKg) > 0
                 AND SUM(py.TotalLossKg) / SUM(py.TotalTargetKg) * 100.0 > @LossAlertPct
                 THEN 'WARNING'
            ELSE 'NORMAL'
        END                             AS AlertStatus
    FROM ana.vw_ProductLossYield py
    WHERE py.LoadDate BETWEEN @DateFrom AND @DateTo
      AND (@ProductId IS NULL OR py.ProductId = @ProductId)
    GROUP BY py.ProductId, py.ProductCode, py.ProductName, py.Unit
    ORDER BY TotalLossKg DESC;

    -- 2. Daily Loss Trend by Product
    SELECT
        py.LoadDate,
        py.ProductCode,
        py.TotalLossKg,
        py.LossPct,
        py.YieldPct
    FROM ana.vw_ProductLossYield py
    WHERE py.LoadDate BETWEEN @DateFrom AND @DateTo
      AND (@ProductId IS NULL OR py.ProductId = @ProductId)
    ORDER BY py.LoadDate, py.ProductCode;

    -- 3. Job Detail (ถ้าระบุ ProductId)
    IF @ProductId IS NOT NULL
    BEGIN
        SELECT
            jp.JobCode,
            jp.BayCode,
            jp.LicensePlate,
            jp.TargetWeight,
            jp.ActualWeight,
            jp.DiffKg,
            jp.DiffPct,
            jp.LossKg,
            jp.OverKg,
            jp.YieldPct,
            jp.IsAccurate,
            jp.LoadingMinutes,
            jp.LoadDate
        FROM ana.vw_JobPerformance jp
        WHERE jp.LoadDate  BETWEEN @DateFrom AND @DateTo
          AND jp.ProductId = @ProductId
        ORDER BY jp.LossKg DESC;
    END
END
GO

-- --------------------------------------------------------
-- ana.sp_GetAnalyticsConfig — ดึง Threshold ทั้งหมด
-- --------------------------------------------------------
CREATE OR ALTER PROCEDURE ana.sp_GetAnalyticsConfig
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ConfigKey, ConfigValue, DataType, Description, UpdatedAt
    FROM ana.AnalyticsConfig
    ORDER BY ConfigKey;
END
GO

-- --------------------------------------------------------
-- ana.sp_UpdateAnalyticsConfig — อัปเดต Threshold
-- --------------------------------------------------------
CREATE OR ALTER PROCEDURE ana.sp_UpdateAnalyticsConfig
    @ConfigKey   VARCHAR(60),
    @ConfigValue NVARCHAR(100),
    @UpdatedBy   UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM ana.AnalyticsConfig WHERE ConfigKey = @ConfigKey)
    BEGIN
        SELECT 'ERROR' AS Result, N'ไม่พบ Config Key: ' + @ConfigKey AS Message;
        RETURN;
    END
    UPDATE ana.AnalyticsConfig
    SET ConfigValue = @ConfigValue,
        UpdatedAt   = SYSDATETIME(),
        UpdatedBy   = @UpdatedBy
    WHERE ConfigKey = @ConfigKey;
    SELECT 'SUCCESS' AS Result, @ConfigKey AS ConfigKey, @ConfigValue AS NewValue;
END
GO

PRINT '  Analytics Stored Procedures created.';
GO

-- ============================================================
-- SECTION 5: Indexes บน Views (ปรับ Performance Query)
-- ============================================================

-- Index ช่วย Query ที่ filter ด้วยวันที่บน LoadJobs (ถ้ายังไม่มี)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Jobs_CompletedAt' AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE INDEX IX_Jobs_CompletedAt ON slb.LoadJobs(CompletedAt, Status) WHERE Status = 'COMPLETED';

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Jobs_StartedAt' AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE INDEX IX_Jobs_StartedAt ON slb.LoadJobs(StartedAt) WHERE StartedAt IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Queue_CompletedAt' AND object_id = OBJECT_ID('slb.LoadQueues'))
    CREATE INDEX IX_Queue_CompletedAt ON slb.LoadQueues(CompletedAt, Status) WHERE Status = 'DONE';

GO

-- ============================================================
-- SECTION 6: Quick Verify
-- ============================================================

SELECT 'Schema ana Tables'      AS ObjectType, COUNT(*) AS Count
FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'ana' AND TABLE_TYPE = 'BASE TABLE'
UNION ALL
SELECT 'Schema ana Views',       COUNT(*)
FROM INFORMATION_SCHEMA.VIEWS   WHERE TABLE_SCHEMA = 'ana'
UNION ALL
SELECT 'Schema ana Procedures',  COUNT(*)
FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = 'ana' AND ROUTINE_TYPE = 'PROCEDURE'
UNION ALL
SELECT 'AnalyticsConfig Rows',   COUNT(*) FROM ana.AnalyticsConfig;
GO

-- ตรวจสอบ Config
SELECT ConfigKey, ConfigValue, Description FROM ana.AnalyticsConfig ORDER BY ConfigKey;
GO

PRINT '';
PRINT '=== Analytics Schema (ana) Setup Complete ===';
PRINT 'Tables: 1 (AnalyticsConfig)';
PRINT 'Views: 6 (JobPerformance, QueuePerformance, DailyPerformance, BayPerformance, ProductLossYield, TruckTurnaround, HourlyThroughput)';
PRINT 'SPs: 7 (GetPerformanceDashboard, GetLossYieldDashboard, GetBayPerformanceDashboard, GetTurnaroundDashboard, GetProductLossAnalysis, GetAnalyticsConfig, UpdateAnalyticsConfig)';
GO

-- ============================================================
-- ROLLBACK SCRIPT (ลบ ana Schema ทั้งหมด)
-- คัดลอก Section นี้แยกแล้วรัน
-- ============================================================
/*
USE SmartLoadBulkDB;
GO
DROP PROCEDURE IF EXISTS ana.sp_UpdateAnalyticsConfig;
DROP PROCEDURE IF EXISTS ana.sp_GetAnalyticsConfig;
DROP PROCEDURE IF EXISTS ana.sp_GetProductLossAnalysis;
DROP PROCEDURE IF EXISTS ana.sp_GetTurnaroundDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetBayPerformanceDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetLossYieldDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetPerformanceDashboard;
DROP VIEW IF EXISTS ana.vw_HourlyThroughput;
DROP VIEW IF EXISTS ana.vw_TruckTurnaround;
DROP VIEW IF EXISTS ana.vw_ProductLossYield;
DROP VIEW IF EXISTS ana.vw_BayPerformance;
DROP VIEW IF EXISTS ana.vw_DailyPerformance;
DROP VIEW IF EXISTS ana.vw_QueuePerformance;
DROP VIEW IF EXISTS ana.vw_JobPerformance;
DROP TABLE IF EXISTS ana.AnalyticsConfig;
DROP SCHEMA IF EXISTS ana;
GO
*/
