-- ============================================================
--  Smart Load Bulk — Analytics Objects (Schema: ana)
--  ออกแบบโดย: Shuri | อ้างอิง Hawkeye: PERFORMANCE_ANALYTICS_PLAN.md
--  วันที่: 2026-05-13 | Version: 1.0
--  Database  : SmartLoadBulkDB
--  Schema    : slb (source/OLTP), ana (analytics/OLAP)
--  SQL Server: 2019+
-- ============================================================
-- ⚠ รันหลัง 001_create_smart_load_bulk_tables.sql เสมอ
-- วิธีรัน:
--   1. ตรวจสอบว่า SmartLoadBulkDB มี schema slb และ tables ครบ
--   2. รัน Script นี้ใน SSMS (F5)
--   3. ดู Quick Verify ด้านล่างสุด
-- ============================================================
-- Rollback: ดู SECTION 8 ด้านล่างสุด
-- ============================================================

USE SmartLoadBulkDB;
GO

-- ============================================================
-- SECTION 1: Schema ana
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ana')
BEGIN
    EXEC('CREATE SCHEMA ana');
    PRINT 'Created schema: ana';
END
GO

-- ============================================================
-- SECTION 2: AnalyticsConfig Table
-- ============================================================

IF OBJECT_ID('ana.AnalyticsConfig', 'U') IS NULL
CREATE TABLE ana.AnalyticsConfig (
    ConfigId     INT           NOT NULL IDENTITY(1,1),
    ConfigKey    VARCHAR(60)   NOT NULL,
    ConfigValue  VARCHAR(50)   NOT NULL,
    Description  NVARCHAR(200) NOT NULL,
    Unit         NVARCHAR(20)  NOT NULL,
    UpdatedBy    NVARCHAR(100) NOT NULL DEFAULT 'SYSTEM',
    UpdatedAt    DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_AnalyticsConfig PRIMARY KEY (ConfigId),
    CONSTRAINT UQ_AnalyticsConfig_Key UNIQUE (ConfigKey)
);
GO

-- Seed / Upsert Config Values (27 rows)
MERGE ana.AnalyticsConfig AS tgt
USING (VALUES
    -- Yield & Loss Thresholds
    ('YIELD_NORMAL_MIN',            '99.5',  N'Yield% ต่ำสุดที่ถือว่า NORMAL',          N'%'),
    ('YIELD_NORMAL_MAX',            '100.5', N'Yield% สูงสุดที่ถือว่า NORMAL',          N'%'),
    ('YIELD_WARNING_MIN',           '98.0',  N'Yield% ต่ำกว่านี้ = WARNING',            N'%'),
    ('YIELD_WARNING_MAX',           '102.0', N'Yield% สูงกว่านี้ = WARNING',            N'%'),
    ('YIELD_CRITICAL_MIN',          '97.0',  N'Yield% ต่ำกว่านี้ = CRITICAL',           N'%'),
    ('YIELD_CRITICAL_MAX',          '103.0', N'Yield% สูงกว่านี้ = CRITICAL',           N'%'),
    -- Loading Time Thresholds
    ('LOADING_TIME_FAST_MAX',       '30',    N'โหลดได้ใน 30 นาที = FAST',               N'นาที'),
    ('LOADING_TIME_NORMAL_MAX',     '45',    N'โหลดได้ใน 45 นาที = NORMAL',              N'นาที'),
    ('LOADING_TIME_SLOW_MIN',       '60',    N'โหลดเกิน 60 นาที = SLOW',                N'นาที'),
    ('LOADING_TIME_CRITICAL_MIN',   '90',    N'โหลดเกิน 90 นาที = CRITICAL',            N'นาที'),
    -- Queue Waiting Thresholds
    ('QUEUE_WAIT_OK_MAX',           '20',    N'รอใน Queue ≤ 20 นาที = OK',              N'นาที'),
    ('QUEUE_WAIT_WARNING_MIN',      '30',    N'รอ Queue เกิน 30 นาที = WARNING',        N'นาที'),
    ('QUEUE_WAIT_CRITICAL_MIN',     '60',    N'รอ Queue เกิน 60 นาที = CRITICAL',       N'นาที'),
    -- Turnaround Thresholds
    ('TURNAROUND_FAST_MAX',         '60',    N'Turnaround ≤ 60 นาที = FAST',            N'นาที'),
    ('TURNAROUND_NORMAL_MAX',       '90',    N'Turnaround ≤ 90 นาที = NORMAL',          N'นาที'),
    ('TURNAROUND_SLOW_MIN',         '120',   N'Turnaround เกิน 120 นาที = SLOW',        N'นาที'),
    -- Bay Utilization
    ('BAY_UTIL_LOW_MAX',            '50',    N'Bay Util < 50% = LOW',                   N'%'),
    ('BAY_UTIL_GOOD_MIN',           '70',    N'Bay Util ≥ 70% = GOOD',                  N'%'),
    ('BAY_UTIL_HIGH_MIN',           '85',    N'Bay Util ≥ 85% = HIGH (ระวัง Overload)', N'%'),
    -- Throughput
    ('THROUGHPUT_HIGH_MIN',         '30',    N'Throughput ≥ 30 t/hr = HIGH',            N't/hr'),
    ('THROUGHPUT_NORMAL_MIN',       '20',    N'Throughput ≥ 20 t/hr = NORMAL',          N't/hr'),
    ('THROUGHPUT_LOW_MAX',          '15',    N'Throughput < 15 t/hr = LOW',             N't/hr'),
    -- Loading Accuracy
    ('ACCURACY_GOOD_MIN',           '90',    N'Accuracy ≥ 90% = GOOD',                  N'%'),
    ('ACCURACY_OK_MIN',             '80',    N'Accuracy ≥ 80% = OK',                    N'%'),
    ('ACCURACY_POOR_MAX',           '70',    N'Accuracy < 70% = POOR',                  N'%'),
    -- System Config
    ('WORKING_HOURS_PER_DAY',       '16',    N'ชั่วโมงทำงานต่อวัน (06:00–22:00)',        N'ชม'),
    ('PROBLEM_TRUCK_MIN_INCIDENTS', '2',     N'จำนวนครั้งขั้นต่ำที่ถือว่า Problem Truck',N'ครั้ง')
) AS src (ConfigKey, ConfigValue, Description, Unit)
ON tgt.ConfigKey = src.ConfigKey
WHEN MATCHED THEN
    UPDATE SET ConfigValue = src.ConfigValue,
               Description = src.Description,
               Unit        = src.Unit,
               UpdatedAt   = SYSDATETIME()
WHEN NOT MATCHED THEN
    INSERT (ConfigKey, ConfigValue, Description, Unit)
    VALUES (src.ConfigKey, src.ConfigValue, src.Description, src.Unit);
GO

PRINT 'AnalyticsConfig: seeded 27 rows';
GO

-- ============================================================
-- SECTION 3: Additional Indexes on slb Schema (for Analytics)
-- ============================================================
-- หมายเหตุ: ตรวจสอบว่า Index ยังไม่มีก่อนสร้าง

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadJobs_CompletedAt_Status'
               AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE INDEX IX_LoadJobs_CompletedAt_Status
        ON slb.LoadJobs (CompletedAt, Status)
        INCLUDE (BayId, TruckId, DriverId, ProductId, TargetWeight, ActualWeight);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadJobs_StartedAt_BayId'
               AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE INDEX IX_LoadJobs_StartedAt_BayId
        ON slb.LoadJobs (StartedAt, BayId)
        INCLUDE (Status, TargetWeight, ActualWeight);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadJobs_TruckId_Status'
               AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE INDEX IX_LoadJobs_TruckId_Status
        ON slb.LoadJobs (TruckId, Status)
        INCLUDE (StartedAt, CompletedAt, TargetWeight, ActualWeight);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadJobs_OrderItemId'
               AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE INDEX IX_LoadJobs_OrderItemId
        ON slb.LoadJobs (OrderItemId)
        INCLUDE (OrderId, ProductId, TargetWeight, ActualWeight, Status);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadQueues_CalledAt'
               AND object_id = OBJECT_ID('slb.LoadQueues'))
    CREATE INDEX IX_LoadQueues_CalledAt
        ON slb.LoadQueues (CalledAt, Status)
        INCLUDE (OrderId, TruckId, EnqueuedAt, CompletedAt);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadQueues_EnqueuedAt'
               AND object_id = OBJECT_ID('slb.LoadQueues'))
    CREATE INDEX IX_LoadQueues_EnqueuedAt
        ON slb.LoadQueues (EnqueuedAt, OrderId, TruckId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BayLogs_BayId_EventType'
               AND object_id = OBJECT_ID('slb.BayLogs'))
    CREATE INDEX IX_BayLogs_BayId_EventType
        ON slb.BayLogs (BayId, EventType, CreatedAt)
        INCLUDE (QueueId);
GO

PRINT 'Analytics indexes: created 7 indexes';
GO

-- ============================================================
-- SECTION 4: Views (10 Views ใน Schema ana)
-- ============================================================

-- --------------------------------------------------------
-- V01: ana.vw_JobPerformance — Core KPI ต่อ Job
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_JobPerformance', 'V') IS NOT NULL DROP VIEW ana.vw_JobPerformance;
GO
CREATE VIEW ana.vw_JobPerformance AS
SELECT
    lj.JobId,
    lj.JobCode,
    lj.BayId,
    b.BayCode,
    b.BayName,
    lj.TruckId,
    t.LicensePlate,
    t.TruckType,
    t.CompanyName                                       AS TransportCompany,
    lj.DriverId,
    d.FullName                                          AS DriverName,
    lj.ProductId,
    p.ProductCode,
    p.ProductName,
    lj.OrderId,
    o.OrderCode,
    c.CustomerName,
    lj.OrderItemId,

    -- Timestamps
    lj.StartedAt,
    lj.CompletedAt,
    lj.Status,
    CAST(lj.StartedAt AS DATE)                          AS WorkDate,
    DATEPART(HOUR, lj.StartedAt)                        AS WorkHour,

    -- Shift  (Shift1=06–13, Shift2=14–21, Shift3=22–05)
    CASE
        WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 6  AND 13 THEN 'SHIFT1'
        WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 14 AND 21 THEN 'SHIFT2'
        ELSE 'SHIFT3'
    END                                                  AS ShiftName,

    -- Weight
    lj.TargetWeight,
    lj.ActualWeight,
    lj.ActualWeight - lj.TargetWeight                   AS DiffKg,

    CASE WHEN lj.TargetWeight > 0
         THEN (lj.ActualWeight - lj.TargetWeight) / lj.TargetWeight * 100.0
         ELSE NULL END                                   AS DiffPct,

    CASE WHEN lj.TargetWeight > 0
         THEN lj.ActualWeight / lj.TargetWeight * 100.0
         ELSE NULL END                                   AS YieldPct,

    CASE WHEN lj.ActualWeight < lj.TargetWeight
         THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END  AS LossKg,

    CASE WHEN lj.ActualWeight > lj.TargetWeight
         THEN lj.ActualWeight - lj.TargetWeight ELSE 0 END  AS OverKg,

    -- Loading Duration (minutes)
    CASE WHEN lj.CompletedAt IS NOT NULL AND lj.StartedAt IS NOT NULL
         THEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)
         ELSE NULL END                                   AS LoadingDurationMin,

    -- Accuracy Flag (ABS Diff ≤ TolerancePct)
    CASE WHEN lj.TargetWeight > 0
              AND ABS(lj.ActualWeight - lj.TargetWeight) / lj.TargetWeight * 100.0
                  <= lj.TolerancePct
         THEN 1 ELSE 0 END                               AS IsAccurate,

    -- Throughput per Job (ton/hr)
    CASE WHEN lj.CompletedAt IS NOT NULL
              AND DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) > 0
         THEN (lj.ActualWeight / 1000.0)
              / (DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) / 60.0)
         ELSE NULL END                                   AS ThroughputTonPerHour

FROM slb.LoadJobs          lj
JOIN slb.Bays              b   ON lj.BayId       = b.BayId
JOIN slb.Trucks            t   ON lj.TruckId     = t.TruckId
JOIN slb.Drivers           d   ON lj.DriverId    = d.DriverId
JOIN slb.Orders            o   ON lj.OrderId     = o.OrderId
JOIN slb.Customers         c   ON o.CustomerId   = c.CustomerId
JOIN slb.OrderItems        oi  ON lj.OrderItemId = oi.ItemId
JOIN slb.Products          p   ON lj.ProductId   = p.ProductId
WHERE lj.Status = 'COMPLETED'
  AND lj.CompletedAt IS NOT NULL
  AND lj.ActualWeight IS NOT NULL;
GO

-- --------------------------------------------------------
-- V02: ana.vw_QueuePerformance — Queue Waiting Time
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_QueuePerformance', 'V') IS NOT NULL DROP VIEW ana.vw_QueuePerformance;
GO
CREATE VIEW ana.vw_QueuePerformance AS
SELECT
    lq.QueueId,
    lq.OrderId,
    lq.TruckId,
    t.LicensePlate,
    lq.DriverId,
    d.FullName                                          AS DriverName,
    lq.Priority,
    lq.Status,
    lq.EnqueuedAt,
    lq.CalledAt,
    lq.DockedAt,
    lq.CompletedAt,
    CAST(lq.EnqueuedAt AS DATE)                         AS QueueDate,

    -- Queue Wait = CalledAt - EnqueuedAt
    CASE WHEN lq.CalledAt IS NOT NULL
         THEN DATEDIFF(MINUTE, lq.EnqueuedAt, lq.CalledAt)
         ELSE NULL END                                   AS QueueWaitingMin,

    -- Dock Wait = DockedAt - CalledAt (เวลาตั้งแต่เรียกถึงรถมาถึง)
    CASE WHEN lq.DockedAt IS NOT NULL AND lq.CalledAt IS NOT NULL
         THEN DATEDIFF(MINUTE, lq.CalledAt, lq.DockedAt)
         ELSE NULL END                                   AS DockWaitMin,

    -- Total in System = CompletedAt - EnqueuedAt
    CASE WHEN lq.CompletedAt IS NOT NULL
         THEN DATEDIFF(MINUTE, lq.EnqueuedAt, lq.CompletedAt)
         ELSE NULL END                                   AS TotalSystemTimeMin

FROM slb.LoadQueues lq
JOIN slb.Trucks     t  ON lq.TruckId  = t.TruckId
JOIN slb.Drivers    d  ON lq.DriverId = d.DriverId
WHERE lq.CalledAt IS NOT NULL;
GO

-- --------------------------------------------------------
-- V03: ana.vw_DailyPerformance — Daily KPI Aggregate
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_DailyPerformance', 'V') IS NOT NULL DROP VIEW ana.vw_DailyPerformance;
GO
CREATE VIEW ana.vw_DailyPerformance AS
SELECT
    CAST(lj.StartedAt AS DATE)                           AS WorkDate,
    COUNT(*)                                             AS TotalJobs,
    COUNT(CASE WHEN lj.Status = 'COMPLETED' THEN 1 END)  AS CompletedJobs,
    COUNT(CASE WHEN lj.Status = 'CANCELLED' THEN 1 END)  AS CancelledJobs,
    COUNT(CASE WHEN lj.Status = 'FAILED'    THEN 1 END)  AS FailedJobs,

    -- [FIX Risk#4] เพิ่ม AND lj.ActualWeight IS NOT NULL ในทุก expression ที่คำนวณ Yield/Loss
    -- ป้องกัน NULL ActualWeight (เช่น FAILED Jobs) ทำให้ผลลัพธ์ SUM/AVG ผิดพลาด
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
             THEN lj.TargetWeight ELSE 0 END)                                AS TotalTargetKg,
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
             THEN lj.ActualWeight ELSE 0 END)                                AS TotalActualKg,

    -- Loss & Over (เฉพาะ COMPLETED + ActualWeight IS NOT NULL)
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
                  AND lj.ActualWeight < lj.TargetWeight
             THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END)             AS TotalLossKg,
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
                  AND lj.ActualWeight > lj.TargetWeight
             THEN lj.ActualWeight - lj.TargetWeight ELSE 0 END)             AS TotalOverKg,

    -- Overall Yield (COMPLETED + ActualWeight IS NOT NULL)
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
             THEN lj.ActualWeight ELSE 0 END)
        / NULLIF(SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
                          THEN lj.TargetWeight ELSE 0 END), 0)
        * 100.0                                          AS OverallYieldPct,

    -- Avg Loading Time (COMPLETED only)
    AVG(CASE WHEN lj.Status = 'COMPLETED' AND lj.CompletedAt IS NOT NULL
             THEN CAST(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) AS FLOAT)
             ELSE NULL END)                              AS AvgLoadingMin,

    -- Accuracy % (Yield ± TolerancePct) — เฉพาะ Job ที่มี ActualWeight
    COUNT(CASE WHEN lj.Status = 'COMPLETED'
                    AND lj.ActualWeight IS NOT NULL
                    AND lj.TargetWeight > 0
                    AND ABS(lj.ActualWeight - lj.TargetWeight)
                        / lj.TargetWeight * 100.0 <= lj.TolerancePct
               THEN 1 END) * 100.0
        / NULLIF(COUNT(CASE WHEN lj.Status = 'COMPLETED'
                             AND lj.ActualWeight IS NOT NULL THEN 1 END), 0)
                                                         AS AccuracyPct,

    -- Throughput (ton/hr) รวม — เฉพาะ Job ที่มี ActualWeight
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
             THEN lj.ActualWeight ELSE 0 END) / 1000.0
        / NULLIF(
            SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
                          AND lj.CompletedAt IS NOT NULL
                     THEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) ELSE 0 END)
            / 60.0, 0)                                  AS ThroughputTonPerHour

FROM slb.LoadJobs lj
WHERE lj.Status IN ('COMPLETED', 'CANCELLED', 'FAILED')
  AND lj.StartedAt IS NOT NULL
GROUP BY CAST(lj.StartedAt AS DATE);
GO

-- --------------------------------------------------------
-- V04: ana.vw_BayPerformance — Bay-level KPIs ต่อวัน
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_BayPerformance', 'V') IS NOT NULL DROP VIEW ana.vw_BayPerformance;
GO
CREATE VIEW ana.vw_BayPerformance AS
SELECT
    CAST(lj.StartedAt AS DATE)                                              AS WorkDate,
    lj.BayId,
    b.BayCode,
    b.BayName,

    COUNT(*)                                                                 AS TotalJobs,
    COUNT(CASE WHEN lj.Status = 'COMPLETED' THEN 1 END)                     AS CompletedJobs,

    -- [FIX Risk#4] กรอง ActualWeight IS NOT NULL ในทุก expression คำนวณ Ton/Yield/Throughput
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
             THEN lj.ActualWeight ELSE 0 END) / 1000.0
                                                                             AS TotalActualTon,

    AVG(CASE WHEN lj.Status = 'COMPLETED' AND lj.CompletedAt IS NOT NULL
             THEN CAST(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) AS FLOAT)
             ELSE NULL END)                                                  AS AvgLoadingMin,

    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.CompletedAt IS NOT NULL
             THEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) ELSE 0 END) AS TotalLoadingMin,

    -- Bay Yield (COMPLETED + ActualWeight IS NOT NULL)
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
             THEN lj.ActualWeight ELSE 0 END)
        / NULLIF(SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
                          THEN lj.TargetWeight ELSE 0 END), 0)
        * 100.0                                                              AS BayYieldPct,

    -- Throughput per Bay (เฉพาะ Job ที่มี ActualWeight)
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
             THEN lj.ActualWeight ELSE 0 END) / 1000.0
        / NULLIF(
            SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
                          AND lj.CompletedAt IS NOT NULL
                     THEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) ELSE 0 END)
            / 60.0, 0)                                                       AS ThroughputTonPerHour,

    -- [FIX Risk#1] Bay Utilization % นับ LOADING + CHECKING รวมกัน
    -- (CHECKING = truck ยังครอบครอง Bay อยู่ ต้องนับเป็น Utilized Time)
    -- ใช้ ISNULL(lj.CompletedAt, SYSDATETIME()) กรณี CHECKING ยังไม่มี CompletedAt
    SUM(CASE WHEN lj.Status IN ('COMPLETED', 'CHECKING') AND lj.StartedAt IS NOT NULL
             THEN DATEDIFF(MINUTE, lj.StartedAt,
                           ISNULL(lj.CompletedAt, SYSDATETIME()))
             ELSE 0 END) * 100.0
        / CAST(
            ISNULL(
                (SELECT CAST(ConfigValue AS INT) FROM ana.AnalyticsConfig
                 WHERE ConfigKey = 'WORKING_HOURS_PER_DAY'), 16)
            * 60 AS FLOAT)                                                   AS BayUtilizationPct

FROM slb.LoadJobs lj
JOIN slb.Bays     b  ON lj.BayId = b.BayId
WHERE lj.StartedAt IS NOT NULL
  AND lj.Status IN ('COMPLETED', 'CHECKING', 'CANCELLED', 'FAILED')
GROUP BY CAST(lj.StartedAt AS DATE), lj.BayId, b.BayCode, b.BayName;
GO

-- --------------------------------------------------------
-- V05: ana.vw_ProductLossYield — Loss/Yield ต่อ Product ต่อวัน
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_ProductLossYield', 'V') IS NOT NULL DROP VIEW ana.vw_ProductLossYield;
GO
CREATE VIEW ana.vw_ProductLossYield AS
SELECT
    CAST(lj.CompletedAt AS DATE)                         AS WorkDate,
    lj.ProductId,
    p.ProductCode,
    p.ProductName,

    COUNT(*)                                             AS TotalJobs,
    SUM(lj.TargetWeight)                                 AS TotalTargetKg,
    SUM(lj.ActualWeight)                                 AS TotalActualKg,

    SUM(lj.ActualWeight) / NULLIF(SUM(lj.TargetWeight), 0) * 100.0  AS YieldPct,

    SUM(CASE WHEN lj.ActualWeight < lj.TargetWeight
             THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END)      AS TotalLossKg,

    SUM(CASE WHEN lj.ActualWeight > lj.TargetWeight
             THEN lj.ActualWeight - lj.TargetWeight ELSE 0 END)      AS TotalOverKg,

    AVG(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0)       AS AvgYieldPct,
    STDEV(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0)     AS YieldStdDev,
    MIN(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0)       AS MinYieldPct,
    MAX(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0)       AS MaxYieldPct

FROM slb.LoadJobs  lj
JOIN slb.Products  p   ON lj.ProductId = p.ProductId
WHERE lj.Status = 'COMPLETED'
  AND lj.CompletedAt IS NOT NULL
  AND lj.ActualWeight IS NOT NULL
GROUP BY CAST(lj.CompletedAt AS DATE), lj.ProductId, p.ProductCode, p.ProductName;
GO

-- --------------------------------------------------------
-- V06: ana.vw_TruckTurnaround — Turnaround Time Breakdown
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_TruckTurnaround', 'V') IS NOT NULL DROP VIEW ana.vw_TruckTurnaround;
GO
CREATE VIEW ana.vw_TruckTurnaround AS
SELECT
    lj.JobId,
    lj.JobCode,
    CAST(lj.StartedAt AS DATE)                           AS WorkDate,
    lj.TruckId,
    t.LicensePlate,
    t.CompanyName                                        AS TransportCompany,
    lj.DriverId,
    d.FullName                                           AS DriverName,
    lj.BayId,
    b.BayCode,
    b.BayName,

    -- Key Timestamps
    lq.EnqueuedAt,
    lq.CalledAt,
    lq.DockedAt,
    lj.StartedAt                                         AS LoadingStartedAt,
    lj.CompletedAt                                       AS LoadingCompletedAt,
    lc.ReleasedAt,

    -- Time Segments (minutes)
    CASE WHEN lq.CalledAt IS NOT NULL
         THEN DATEDIFF(MINUTE, lq.EnqueuedAt, lq.CalledAt) ELSE NULL END   AS QueueWaitMin,

    CASE WHEN lq.DockedAt IS NOT NULL AND lq.CalledAt IS NOT NULL
         THEN DATEDIFF(MINUTE, lq.CalledAt,  lq.DockedAt)  ELSE NULL END   AS DockingMin,

    CASE WHEN lj.CompletedAt IS NOT NULL
         THEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) ELSE NULL END AS LoadingMin,

    -- [FIX Risk#2] ChecklistMin = เวลาตั้งแต่ LoadingCompleted → Released
    -- ถ้าไม่มี lc.ReleasedAt ใช้ lj.CompletedAt แทน (0 นาที) แทนการ +10 นาที hardcode
    CASE WHEN lj.CompletedAt IS NOT NULL
         THEN DATEDIFF(MINUTE, lj.CompletedAt,
                       COALESCE(lc.ReleasedAt, lj.CompletedAt))
         ELSE NULL END                                                        AS ChecklistMin,

    -- [FIX Risk#2] Total Turnaround = DockedAt → ReleasedAt (หรือ CompletedAt ถ้าไม่มี Release)
    -- ใช้ COALESCE(lc.ReleasedAt, lj.CompletedAt) แทนการ +10 นาที hardcode
    CASE
        WHEN lq.DockedAt IS NOT NULL
            THEN DATEDIFF(MINUTE, lq.DockedAt,
                          COALESCE(lc.ReleasedAt, lj.CompletedAt))
        ELSE NULL
    END                                                                      AS TurnaroundMin,

    -- Weights
    lj.TargetWeight,
    lj.ActualWeight,
    CASE WHEN lj.TargetWeight > 0
         THEN lj.ActualWeight / lj.TargetWeight * 100.0 ELSE NULL END       AS YieldPct

FROM slb.LoadJobs      lj
JOIN slb.Trucks        t   ON lj.TruckId  = t.TruckId
JOIN slb.Drivers       d   ON lj.DriverId = d.DriverId
JOIN slb.Bays          b   ON lj.BayId    = b.BayId
-- หา Queue ของ Job นี้ผ่าน OrderId + TruckId + DriverId
LEFT JOIN slb.LoadQueues lq ON lq.OrderId  = lj.OrderId
                             AND lq.TruckId  = lj.TruckId
                             AND lq.DriverId = lj.DriverId
LEFT JOIN slb.LoadChecklists lc ON lc.JobId = lj.JobId
WHERE lj.Status = 'COMPLETED'
  AND lj.CompletedAt IS NOT NULL;
GO

-- --------------------------------------------------------
-- V07: ana.vw_HourlyThroughput — Throughput รายชั่วโมง × Bay
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_HourlyThroughput', 'V') IS NOT NULL DROP VIEW ana.vw_HourlyThroughput;
GO
CREATE VIEW ana.vw_HourlyThroughput AS
SELECT
    CAST(lj.StartedAt AS DATE)                           AS WorkDate,
    DATEPART(HOUR, lj.StartedAt)                         AS WorkHour,
    lj.BayId,
    b.BayCode,
    b.BayName,

    COUNT(*)                                             AS JobCount,
    SUM(lj.ActualWeight / 1000.0)                        AS TotalActualTon,
    AVG(CAST(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) AS FLOAT)) AS AvgLoadingMin,
    SUM(lj.ActualWeight / 1000.0)
        / NULLIF(SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) / 60.0, 0)
                                                         AS ThroughputTonPerHour

FROM slb.LoadJobs lj
JOIN slb.Bays     b  ON lj.BayId = b.BayId
WHERE lj.Status = 'COMPLETED'
  AND lj.CompletedAt IS NOT NULL
  AND lj.ActualWeight IS NOT NULL
GROUP BY
    CAST(lj.StartedAt AS DATE),
    DATEPART(HOUR, lj.StartedAt),
    lj.BayId, b.BayCode, b.BayName;
GO

-- --------------------------------------------------------
-- V08: ana.vw_TruckProblemHistory — ประวัติ Incident ต่อรถ
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_TruckProblemHistory', 'V') IS NOT NULL DROP VIEW ana.vw_TruckProblemHistory;
GO
CREATE VIEW ana.vw_TruckProblemHistory AS
SELECT
    lj.JobId,
    lj.JobCode,
    lj.TruckId,
    t.LicensePlate,
    t.CompanyName                                        AS TransportCompany,
    lj.DriverId,
    d.FullName                                           AS DriverName,
    lj.BayId,
    b.BayCode,
    b.BayName,
    lj.StartedAt                                         AS IncidentDate,
    lj.Status,
    lj.TargetWeight,
    lj.ActualWeight,
    lj.FailReason,

    CASE WHEN lj.TargetWeight > 0
         THEN lj.ActualWeight / lj.TargetWeight * 100.0 ELSE NULL END   AS YieldPct,

    -- ประเภท Incident
    CASE
        WHEN lj.Status = 'FAILED'     THEN 'FAILED_JOB'
        WHEN lj.Status = 'CANCELLED'  THEN 'CANCELLED_JOB'
        WHEN lj.Status = 'COMPLETED'
             AND lj.ActualWeight < lj.TargetWeight * 0.980 THEN 'HIGH_LOSS'
        WHEN lj.Status = 'COMPLETED'
             AND lj.ActualWeight > lj.TargetWeight * 1.020 THEN 'HIGH_OVER'
        ELSE 'OTHER'
    END                                                                  AS IncidentType,

    CAST(lj.StartedAt AS DATE)                                           AS WorkDate

FROM slb.LoadJobs  lj
JOIN slb.Trucks    t  ON lj.TruckId  = t.TruckId
JOIN slb.Drivers   d  ON lj.DriverId = d.DriverId
JOIN slb.Bays      b  ON lj.BayId    = b.BayId
WHERE
    lj.Status IN ('FAILED', 'CANCELLED')
    OR (
        lj.Status = 'COMPLETED'
        AND lj.ActualWeight IS NOT NULL
        AND (
            lj.ActualWeight < lj.TargetWeight * 0.980
            OR lj.ActualWeight > lj.TargetWeight * 1.020
        )
    );
GO

-- --------------------------------------------------------
-- V09: ana.vw_FormulaLossAnalysis — Loss ต่อ Product × Bay × วัน
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_FormulaLossAnalysis', 'V') IS NOT NULL DROP VIEW ana.vw_FormulaLossAnalysis;
GO
CREATE VIEW ana.vw_FormulaLossAnalysis AS
SELECT
    CAST(lj.CompletedAt AS DATE)                          AS WorkDate,
    lj.ProductId,
    p.ProductCode,
    p.ProductName,
    lj.BayId,
    b.BayCode,
    b.BayName,

    COUNT(*)                                              AS JobCount,
    SUM(lj.TargetWeight)                                  AS TotalTargetKg,
    SUM(lj.ActualWeight)                                  AS TotalActualKg,

    AVG(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0)  AS AvgYieldPct,
    STDEV(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0) AS YieldStdDev,
    MIN(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0)  AS MinYieldPct,
    MAX(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0)  AS MaxYieldPct,

    SUM(CASE WHEN lj.ActualWeight < lj.TargetWeight
             THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END) AS TotalLossKg,
    SUM(CASE WHEN lj.ActualWeight > lj.TargetWeight
             THEN lj.ActualWeight - lj.TargetWeight ELSE 0 END) AS TotalOverKg

FROM slb.LoadJobs  lj
JOIN slb.Products  p  ON lj.ProductId = p.ProductId
JOIN slb.Bays      b  ON lj.BayId     = b.BayId
WHERE lj.Status = 'COMPLETED'
  AND lj.CompletedAt IS NOT NULL
  AND lj.ActualWeight IS NOT NULL
GROUP BY
    CAST(lj.CompletedAt AS DATE),
    lj.ProductId, p.ProductCode, p.ProductName,
    lj.BayId,    b.BayCode,     b.BayName;
GO

-- --------------------------------------------------------
-- V10: ana.vw_ShiftPerformance — KPI ต่อ Shift ต่อวัน
-- --------------------------------------------------------
IF OBJECT_ID('ana.vw_ShiftPerformance', 'V') IS NOT NULL DROP VIEW ana.vw_ShiftPerformance;
GO
CREATE VIEW ana.vw_ShiftPerformance AS
SELECT
    CAST(lj.StartedAt AS DATE)                            AS WorkDate,
    CASE
        WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 6  AND 13 THEN 'SHIFT1'
        WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 14 AND 21 THEN 'SHIFT2'
        ELSE 'SHIFT3'
    END                                                   AS ShiftName,

    COUNT(*)                                              AS TotalJobs,
    COUNT(CASE WHEN lj.Status = 'COMPLETED' THEN 1 END)   AS CompletedJobs,
    COUNT(CASE WHEN lj.Status = 'FAILED'    THEN 1 END)   AS FailedJobs,

    -- [FIX Risk#4] กรอง ActualWeight IS NOT NULL ป้องกัน NULL จาก FAILED Jobs เข้า SUM/AVG
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
             THEN lj.ActualWeight ELSE 0 END) / 1000.0
                                                          AS TotalActualTon,

    AVG(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight IS NOT NULL
             THEN lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0
             ELSE NULL END)                               AS AvgYieldPct,

    AVG(CASE WHEN lj.Status = 'COMPLETED' AND lj.CompletedAt IS NOT NULL
             THEN CAST(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) AS FLOAT)
             ELSE NULL END)                               AS AvgLoadingMin

FROM slb.LoadJobs lj
WHERE lj.Status IN ('COMPLETED', 'FAILED', 'CANCELLED')
  AND lj.StartedAt IS NOT NULL
GROUP BY
    CAST(lj.StartedAt AS DATE),
    CASE
        WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 6  AND 13 THEN 'SHIFT1'
        WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 14 AND 21 THEN 'SHIFT2'
        ELSE 'SHIFT3'
    END;
GO

PRINT 'Views: created 10 views in schema ana';
GO

-- ============================================================
-- SECTION 5: Stored Procedures (11 SPs ใน Schema ana)
-- ============================================================

-- --------------------------------------------------------
-- SP01: ana.sp_GetPerformanceDashboard
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetPerformanceDashboard', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetPerformanceDashboard;
GO
CREATE PROCEDURE ana.sp_GetPerformanceDashboard
    @DateFrom DATE,
    @DateTo   DATE,
    @BayId    UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Result 1: Summary KPIs (1 row)
    SELECT
        SUM(TotalJobs)       AS TotalJobs,
        SUM(CompletedJobs)   AS CompletedJobs,
        SUM(CancelledJobs)   AS CancelledJobs,
        SUM(FailedJobs)      AS FailedJobs,
        SUM(CompletedJobs) * 100.0 / NULLIF(SUM(TotalJobs), 0) AS CompletionRatePct,
        SUM(TotalActualKg) / NULLIF(SUM(TotalTargetKg), 0) * 100.0 AS OverallYieldPct,
        SUM(TotalLossKg)     AS TotalLossKg,
        SUM(TotalOverKg)     AS TotalOverKg,
        SUM(TotalActualKg) / 1000.0 AS TotalActualTon,
        AVG(AccuracyPct)     AS AvgAccuracyPct,
        AVG(AvgLoadingMin)   AS OverallAvgLoadingMin,
        AVG(ThroughputTonPerHour) AS AvgThroughput
    FROM ana.vw_DailyPerformance
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo;

    -- Result 2: Daily Trend
    SELECT
        WorkDate,
        TotalJobs,
        CompletedJobs,
        TotalActualKg / 1000.0 AS TotalActualTon,
        OverallYieldPct,
        AccuracyPct,
        ThroughputTonPerHour,
        AvgLoadingMin
    FROM ana.vw_DailyPerformance
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    ORDER BY WorkDate;

    -- Result 3: Bay Summary
    SELECT
        BayId,
        BayCode,
        BayName,
        SUM(TotalJobs)       AS TotalJobs,
        SUM(CompletedJobs)   AS CompletedJobs,
        SUM(TotalActualTon)  AS TotalActualTon,
        AVG(AvgLoadingMin)   AS AvgLoadingMin,
        AVG(BayYieldPct)     AS AvgYieldPct,
        AVG(ThroughputTonPerHour) AS AvgThroughput,
        AVG(BayUtilizationPct)    AS AvgUtilizationPct
    FROM ana.vw_BayPerformance
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId IS NULL OR BayId = @BayId)
    GROUP BY BayId, BayCode, BayName
    ORDER BY TotalActualTon DESC;

    -- Result 4: Shift Summary
    SELECT
        ShiftName,
        SUM(TotalJobs)       AS TotalJobs,
        SUM(CompletedJobs)   AS CompletedJobs,
        SUM(TotalActualTon)  AS TotalActualTon,
        AVG(AvgYieldPct)     AS AvgYieldPct,
        AVG(AvgLoadingMin)   AS AvgLoadingMin
    FROM ana.vw_ShiftPerformance
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    GROUP BY ShiftName
    ORDER BY ShiftName;
END;
GO

-- --------------------------------------------------------
-- SP02: ana.sp_GetLossYieldDashboard
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetLossYieldDashboard', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetLossYieldDashboard;
GO
CREATE PROCEDURE ana.sp_GetLossYieldDashboard
    @DateFrom  DATE,
    @DateTo    DATE,
    @ProductId UNIQUEIDENTIFIER = NULL,
    @BayId     UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Result 1: Summary KPIs
    SELECT
        SUM(TotalJobs)       AS TotalJobs,
        SUM(TotalTargetKg)   AS TotalTargetKg,
        SUM(TotalActualKg)   AS TotalActualKg,
        SUM(TotalActualKg) / NULLIF(SUM(TotalTargetKg), 0) * 100.0 AS OverallYieldPct,
        SUM(TotalLossKg)     AS TotalLossKg,
        SUM(TotalOverKg)     AS TotalOverKg,
        AVG(AvgYieldPct)     AS AvgYieldPct,
        MIN(MinYieldPct)     AS MinYieldPct,
        MAX(MaxYieldPct)     AS MaxYieldPct,
        AVG(YieldStdDev)     AS AvgYieldStdDev
    FROM ana.vw_ProductLossYield
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
      AND (@ProductId IS NULL OR ProductId = @ProductId);

    -- Result 2: Daily Yield Trend
    SELECT
        WorkDate,
        SUM(TotalActualKg) / NULLIF(SUM(TotalTargetKg), 0) * 100.0 AS DailyYieldPct,
        SUM(TotalLossKg)   AS TotalLossKg,
        SUM(TotalOverKg)   AS TotalOverKg,
        SUM(TotalJobs)     AS TotalJobs
    FROM ana.vw_ProductLossYield
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
      AND (@ProductId IS NULL OR ProductId = @ProductId)
    GROUP BY WorkDate
    ORDER BY WorkDate;

    -- Result 3: Loss by Product (Top 10)
    SELECT TOP 10
        ProductId,
        ProductCode,
        ProductName,
        SUM(TotalJobs)  AS TotalJobs,
        SUM(TotalLossKg) AS TotalLossKg,
        AVG(AvgYieldPct) AS AvgYieldPct,
        AVG(YieldStdDev) AS YieldStdDev
    FROM ana.vw_ProductLossYield
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    GROUP BY ProductId, ProductCode, ProductName
    ORDER BY SUM(TotalLossKg) DESC;

    -- Result 4: Job Detail (High Loss Jobs)
    SELECT TOP 50
        jp.JobId,
        jp.JobCode,
        jp.WorkDate,
        jp.BayName,
        jp.LicensePlate,
        jp.DriverName,
        jp.ProductName,
        jp.TargetWeight,
        jp.ActualWeight,
        jp.LossKg,
        jp.OverKg,
        jp.YieldPct,
        jp.LoadingDurationMin
    FROM ana.vw_JobPerformance jp
    WHERE jp.WorkDate BETWEEN @DateFrom AND @DateTo
      AND (@ProductId IS NULL OR jp.ProductId = @ProductId)
      AND (@BayId     IS NULL OR jp.BayId     = @BayId)
    ORDER BY jp.LossKg DESC;
END;
GO

-- --------------------------------------------------------
-- SP03: ana.sp_GetBayPerformanceDashboard
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetBayPerformanceDashboard', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetBayPerformanceDashboard;
GO
CREATE PROCEDURE ana.sp_GetBayPerformanceDashboard
    @DateFrom DATE,
    @DateTo   DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Result 1: Bay Summary
    SELECT
        BayId,
        BayCode,
        BayName,
        SUM(TotalJobs)              AS TotalJobs,
        SUM(CompletedJobs)          AS CompletedJobs,
        SUM(TotalActualTon)         AS TotalActualTon,
        SUM(TotalLoadingMin)        AS TotalLoadingMin,
        AVG(AvgLoadingMin)          AS AvgLoadingMin,
        AVG(BayYieldPct)            AS AvgYieldPct,
        AVG(ThroughputTonPerHour)   AS AvgThroughput,
        AVG(BayUtilizationPct)      AS AvgUtilizationPct
    FROM ana.vw_BayPerformance
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    GROUP BY BayId, BayCode, BayName
    ORDER BY BayCode;

    -- Result 2: Daily Trend per Bay
    SELECT
        WorkDate,
        BayId,
        BayCode,
        BayName,
        TotalJobs,
        CompletedJobs,
        TotalActualTon,
        AvgLoadingMin,
        BayYieldPct,
        ThroughputTonPerHour,
        BayUtilizationPct
    FROM ana.vw_BayPerformance
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    ORDER BY WorkDate, BayCode;

    -- Result 3: Hourly Heatmap (today or last date in range)
    SELECT
        WorkDate,
        WorkHour,
        BayId,
        BayCode,
        BayName,
        JobCount,
        TotalActualTon,
        ThroughputTonPerHour
    FROM ana.vw_HourlyThroughput
    WHERE WorkDate = @DateTo
    ORDER BY WorkHour, BayCode;
END;
GO

-- --------------------------------------------------------
-- SP04: ana.sp_GetTurnaroundDashboard
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetTurnaroundDashboard', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetTurnaroundDashboard;
GO
CREATE PROCEDURE ana.sp_GetTurnaroundDashboard
    @DateFrom DATE,
    @DateTo   DATE,
    @TruckId  UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Result 1: Summary
    SELECT
        COUNT(*)                      AS TotalJobs,
        AVG(CAST(TurnaroundMin AS FLOAT)) AS AvgTurnaroundMin,
        MIN(TurnaroundMin)            AS MinTurnaroundMin,
        MAX(TurnaroundMin)            AS MaxTurnaroundMin,
        AVG(CAST(QueueWaitMin AS FLOAT))  AS AvgQueueWaitMin,
        AVG(CAST(DockingMin   AS FLOAT))  AS AvgDockingMin,
        AVG(CAST(LoadingMin   AS FLOAT))  AS AvgLoadingMin,
        AVG(CAST(ChecklistMin AS FLOAT))  AS AvgChecklistMin
    FROM ana.vw_TruckTurnaround
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
      AND TurnaroundMin IS NOT NULL
      AND (@TruckId IS NULL OR TruckId = @TruckId);

    -- Result 2: Daily Avg Turnaround Trend
    SELECT
        WorkDate,
        AVG(CAST(TurnaroundMin AS FLOAT)) AS AvgTurnaroundMin,
        AVG(CAST(QueueWaitMin  AS FLOAT)) AS AvgQueueWaitMin,
        AVG(CAST(LoadingMin    AS FLOAT)) AS AvgLoadingMin,
        COUNT(*)                          AS JobCount
    FROM ana.vw_TruckTurnaround
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
      AND TurnaroundMin IS NOT NULL
    GROUP BY WorkDate
    ORDER BY WorkDate;

    -- Result 3: Job Detail (slowest first)
    SELECT TOP 50
        JobId,
        JobCode,
        WorkDate,
        LicensePlate,
        TransportCompany,
        DriverName,
        BayName,
        QueueWaitMin,
        DockingMin,
        LoadingMin,
        ChecklistMin,
        TurnaroundMin,
        YieldPct
    FROM ana.vw_TruckTurnaround
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
      AND (@TruckId IS NULL OR TruckId = @TruckId)
    ORDER BY TurnaroundMin DESC;
END;
GO

-- --------------------------------------------------------
-- SP05: ana.sp_GetProductLossAnalysis
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetProductLossAnalysis', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetProductLossAnalysis;
GO
CREATE PROCEDURE ana.sp_GetProductLossAnalysis
    @DateFrom DATE,
    @DateTo   DATE,
    @TopN     INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Result 1: Top N Loss Products
    SELECT TOP (@TopN)
        ProductId,
        ProductCode,
        ProductName,
        SUM(TotalJobs)    AS TotalJobs,
        SUM(TotalLossKg)  AS TotalLossKg,
        SUM(TotalOverKg)  AS TotalOverKg,
        AVG(AvgYieldPct)  AS AvgYieldPct,
        AVG(YieldStdDev)  AS YieldStdDev,
        MIN(MinYieldPct)  AS MinYieldPct,
        MAX(MaxYieldPct)  AS MaxYieldPct,
        SUM(TotalLossKg) / NULLIF(SUM(TotalTargetKg), 0) * 100.0 AS LossRatePct
    FROM ana.vw_ProductLossYield
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    GROUP BY ProductId, ProductCode, ProductName
    ORDER BY SUM(TotalLossKg) DESC;

    -- Result 2: Daily Yield per Product (all products)
    SELECT
        WorkDate,
        ProductId,
        ProductCode,
        ProductName,
        YieldPct,
        TotalLossKg,
        TotalJobs
    FROM ana.vw_ProductLossYield
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    ORDER BY WorkDate, ProductCode;

    -- Result 3: Loss per Product per Bay (Formula × Bay Analysis)
    SELECT
        ProductCode,
        ProductName,
        BayCode,
        BayName,
        SUM(JobCount)      AS TotalJobs,
        AVG(AvgYieldPct)   AS AvgYieldPct,
        AVG(YieldStdDev)   AS YieldStdDev,
        SUM(TotalLossKg)   AS TotalLossKg
    FROM ana.vw_FormulaLossAnalysis
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    GROUP BY ProductId, ProductCode, ProductName, BayId, BayCode, BayName
    ORDER BY SUM(TotalLossKg) DESC;
END;
GO

-- --------------------------------------------------------
-- SP06: ana.sp_GetTruckProblemReport
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetTruckProblemReport', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetTruckProblemReport;
GO
CREATE PROCEDURE ana.sp_GetTruckProblemReport
    @DateFrom     DATE,
    @DateTo       DATE,
    @MinIncidents INT = 2
AS
BEGIN
    SET NOCOUNT ON;

    -- Result 1: Problem Truck Summary
    SELECT
        TruckId,
        LicensePlate,
        TransportCompany,
        COUNT(*)                                              AS TotalIncidents,
        SUM(CASE WHEN IncidentType = 'FAILED_JOB'    THEN 1 ELSE 0 END) AS FailedJobCount,
        SUM(CASE WHEN IncidentType = 'CANCELLED_JOB' THEN 1 ELSE 0 END) AS CancelledJobCount,
        SUM(CASE WHEN IncidentType = 'HIGH_LOSS'     THEN 1 ELSE 0 END) AS HighLossCount,
        SUM(CASE WHEN IncidentType = 'HIGH_OVER'     THEN 1 ELSE 0 END) AS HighOverCount
    FROM ana.vw_TruckProblemHistory
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    GROUP BY TruckId, LicensePlate, TransportCompany
    HAVING COUNT(*) >= @MinIncidents
    ORDER BY COUNT(*) DESC;

    -- Result 2: Incident Timeline
    SELECT
        TruckId,
        LicensePlate,
        JobId,
        JobCode,
        IncidentDate,
        IncidentType,
        YieldPct,
        BayName,
        FailReason
    FROM ana.vw_TruckProblemHistory
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    ORDER BY TruckId, IncidentDate;

    -- Result 3: Problem Rate Summary
    SELECT
        COUNT(DISTINCT src.TruckId) AS TotalTrucks,
        COUNT(DISTINCT prob.TruckId) AS ProblemTrucks,
        COUNT(DISTINCT prob.TruckId) * 100.0
            / NULLIF(COUNT(DISTINCT src.TruckId), 0) AS ProblemTruckRatePct
    FROM slb.LoadJobs src
    LEFT JOIN (
        SELECT DISTINCT TruckId
        FROM ana.vw_TruckProblemHistory
        WHERE WorkDate BETWEEN @DateFrom AND @DateTo
        GROUP BY TruckId
        HAVING COUNT(*) >= @MinIncidents
    ) prob ON src.TruckId = prob.TruckId
    WHERE CAST(src.StartedAt AS DATE) BETWEEN @DateFrom AND @DateTo;
END;
GO

-- --------------------------------------------------------
-- SP07: ana.sp_GetHourlyThroughput
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetHourlyThroughput', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetHourlyThroughput;
GO
CREATE PROCEDURE ana.sp_GetHourlyThroughput
    @Date  DATE,
    @BayId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        WorkDate,
        WorkHour,
        BayId,
        BayCode,
        BayName,
        JobCount,
        TotalActualTon,
        AvgLoadingMin,
        ThroughputTonPerHour
    FROM ana.vw_HourlyThroughput
    WHERE WorkDate = @Date
      AND (@BayId IS NULL OR BayId = @BayId)
    ORDER BY WorkHour, BayCode;
END;
GO

-- --------------------------------------------------------
-- SP08: ana.sp_GetShiftPerformance
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetShiftPerformance', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetShiftPerformance;
GO
CREATE PROCEDURE ana.sp_GetShiftPerformance
    @DateFrom DATE,
    @DateTo   DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Result 1: Shift Summary (aggregate)
    SELECT
        ShiftName,
        SUM(TotalJobs)      AS TotalJobs,
        SUM(CompletedJobs)  AS CompletedJobs,
        SUM(FailedJobs)     AS FailedJobs,
        SUM(TotalActualTon) AS TotalActualTon,
        AVG(AvgYieldPct)    AS AvgYieldPct,
        AVG(AvgLoadingMin)  AS AvgLoadingMin,
        SUM(CompletedJobs) * 100.0 / NULLIF(SUM(TotalJobs), 0) AS CompletionRatePct
    FROM ana.vw_ShiftPerformance
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    GROUP BY ShiftName
    ORDER BY ShiftName;

    -- Result 2: Daily Shift Detail
    SELECT
        WorkDate,
        ShiftName,
        TotalJobs,
        CompletedJobs,
        FailedJobs,
        TotalActualTon,
        AvgYieldPct,
        AvgLoadingMin
    FROM ana.vw_ShiftPerformance
    WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    ORDER BY WorkDate, ShiftName;
END;
GO

-- --------------------------------------------------------
-- SP09: ana.sp_GetKpiAlertHistory
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetKpiAlertHistory', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetKpiAlertHistory;
GO
CREATE PROCEDURE ana.sp_GetKpiAlertHistory
    @DateFrom DATE,
    @DateTo   DATE,
    @Severity VARCHAR(10) = NULL   -- INFO / WARNING / ERROR / CRITICAL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        NotifId,
        NotifType,
        Severity,
        Title,
        Message,
        IsRead,
        CreatedAt
    FROM slb.NotificationLogs
    WHERE CAST(CreatedAt AS DATE) BETWEEN @DateFrom AND @DateTo
      AND (@Severity IS NULL OR Severity = @Severity)
      AND NotifType LIKE '%ALERT%'
    ORDER BY CreatedAt DESC;
END;
GO

-- --------------------------------------------------------
-- SP10: ana.sp_GetAnalyticsConfig
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_GetAnalyticsConfig', 'P') IS NOT NULL DROP PROCEDURE ana.sp_GetAnalyticsConfig;
GO
CREATE PROCEDURE ana.sp_GetAnalyticsConfig
    @ConfigKey VARCHAR(60) = NULL   -- NULL = ดึงทั้งหมด
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ConfigId,
        ConfigKey,
        ConfigValue,
        Description,
        Unit,
        UpdatedBy,
        UpdatedAt
    FROM ana.AnalyticsConfig
    WHERE @ConfigKey IS NULL OR ConfigKey = @ConfigKey
    ORDER BY ConfigKey;
END;
GO

-- --------------------------------------------------------
-- SP11: ana.sp_UpdateAnalyticsConfig
-- --------------------------------------------------------
IF OBJECT_ID('ana.sp_UpdateAnalyticsConfig', 'P') IS NOT NULL DROP PROCEDURE ana.sp_UpdateAnalyticsConfig;
GO
CREATE PROCEDURE ana.sp_UpdateAnalyticsConfig
    @ConfigKey   VARCHAR(60),
    @ConfigValue VARCHAR(50),
    @UpdatedBy   NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM ana.AnalyticsConfig WHERE ConfigKey = @ConfigKey)
    BEGIN
        RAISERROR('ConfigKey not found: %s', 16, 1, @ConfigKey);
        RETURN;
    END

    -- [FIX Risk#3] Type Validation: ตรวจสอบว่า ConfigKey ที่เป็น Numeric จะต้องได้รับค่าที่เป็นตัวเลขเท่านั้น
    -- ป้องกัน View/SP อื่นที่ CAST(ConfigValue AS FLOAT) ล้มเหลว
    IF TRY_CAST(@ConfigValue AS FLOAT) IS NULL
       AND @ConfigKey IN (
           'YIELD_NORMAL_MIN',
           'YIELD_NORMAL_MAX',
           'YIELD_WARNING_MIN',
           'YIELD_WARNING_MAX',
           'YIELD_CRITICAL_MIN',
           'YIELD_CRITICAL_MAX',
           'LOADING_TIME_FAST_MAX',
           'LOADING_TIME_NORMAL_MAX',
           'LOADING_TIME_SLOW_MIN',
           'LOADING_TIME_CRITICAL_MIN',
           'QUEUE_WAIT_OK_MAX',
           'QUEUE_WAIT_WARNING_MIN',
           'QUEUE_WAIT_CRITICAL_MIN',
           'TURNAROUND_FAST_MAX',
           'TURNAROUND_NORMAL_MAX',
           'TURNAROUND_SLOW_MIN',
           'BAY_UTIL_LOW_MAX',
           'BAY_UTIL_GOOD_MIN',
           'BAY_UTIL_HIGH_MIN',
           'THROUGHPUT_HIGH_MIN',
           'THROUGHPUT_NORMAL_MIN',
           'THROUGHPUT_LOW_MAX',
           'ACCURACY_GOOD_MIN',
           'ACCURACY_OK_MIN',
           'ACCURACY_POOR_MAX',
           'WORKING_HOURS_PER_DAY',
           'PROBLEM_TRUCK_MIN_INCIDENTS'
       )
    BEGIN
        RAISERROR('ConfigValue ต้องเป็นตัวเลขสำหรับ ConfigKey นี้: %s', 16, 1, @ConfigKey);
        RETURN;
    END

    UPDATE ana.AnalyticsConfig
    SET
        ConfigValue = @ConfigValue,
        UpdatedBy   = @UpdatedBy,
        UpdatedAt   = SYSDATETIME()
    WHERE ConfigKey = @ConfigKey;

    SELECT
        ConfigId, ConfigKey, ConfigValue, Description, Unit, UpdatedBy, UpdatedAt
    FROM ana.AnalyticsConfig
    WHERE ConfigKey = @ConfigKey;
END;
GO

PRINT 'Stored Procedures: created 11 SPs in schema ana';
GO

-- ============================================================
-- SECTION 6: Analytics Test Data
-- ============================================================
-- เพิ่ม LoadJobs test data สำหรับ verify views
-- ⚠ รันหลัง 001 ซึ่งมี Test Data (Users, Products, Bays, Trucks, Drivers, Orders, OrderItems) ครบแล้ว
-- ============================================================

PRINT '-- Inserting Analytics Test Data...';
GO

-- ดึง IDs จาก Test Data ที่มีอยู่ (001 script)
DECLARE
    @Bay1   UNIQUEIDENTIFIER,
    @Bay2   UNIQUEIDENTIFIER,
    @Truck1 UNIQUEIDENTIFIER,
    @Truck2 UNIQUEIDENTIFIER,
    @Truck3 UNIQUEIDENTIFIER,
    @Driver1 UNIQUEIDENTIFIER,
    @Driver2 UNIQUEIDENTIFIER,
    @Driver3 UNIQUEIDENTIFIER,
    @Prod1  UNIQUEIDENTIFIER,
    @Prod2  UNIQUEIDENTIFIER,
    @Order1 UNIQUEIDENTIFIER,
    @Order2 UNIQUEIDENTIFIER,
    @Item1  UNIQUEIDENTIFIER,
    @Item2  UNIQUEIDENTIFIER,
    @Item3  UNIQUEIDENTIFIER,
    @Silo1  UNIQUEIDENTIFIER,
    @Silo2  UNIQUEIDENTIFIER;

SELECT TOP 1 @Bay1   = BayId   FROM slb.Bays    WHERE IsActive = 1 ORDER BY BayCode;
SELECT TOP 1 @Bay2   = BayId   FROM slb.Bays    WHERE IsActive = 1 AND BayId <> @Bay1 ORDER BY BayCode;
SELECT TOP 1 @Truck1 = TruckId FROM slb.Trucks  WHERE IsActive = 1 ORDER BY LicensePlate;
SELECT TOP 1 @Truck2 = TruckId FROM slb.Trucks  WHERE IsActive = 1 AND TruckId <> @Truck1 ORDER BY LicensePlate;
SELECT TOP 1 @Truck3 = TruckId FROM slb.Trucks  WHERE IsActive = 1 AND TruckId NOT IN (@Truck1, @Truck2) ORDER BY LicensePlate;
SELECT TOP 1 @Driver1 = DriverId FROM slb.Drivers WHERE IsActive = 1 ORDER BY FullName;
SELECT TOP 1 @Driver2 = DriverId FROM slb.Drivers WHERE IsActive = 1 AND DriverId <> @Driver1 ORDER BY FullName;
SELECT TOP 1 @Driver3 = DriverId FROM slb.Drivers WHERE IsActive = 1 AND DriverId NOT IN (@Driver1, @Driver2) ORDER BY FullName;
SELECT TOP 1 @Prod1  = ProductId FROM slb.Products WHERE IsActive = 1 ORDER BY ProductCode;
SELECT TOP 1 @Prod2  = ProductId FROM slb.Products WHERE IsActive = 1 AND ProductId <> @Prod1 ORDER BY ProductCode;
SELECT TOP 1 @Order1 = OrderId   FROM slb.Orders   ORDER BY CreatedAt;
SELECT TOP 1 @Order2 = OrderId   FROM slb.Orders   WHERE OrderId <> @Order1 ORDER BY CreatedAt;
SELECT TOP 1 @Item1  = ItemId    FROM slb.OrderItems WHERE OrderId = @Order1;
SELECT TOP 1 @Item2  = ItemId    FROM slb.OrderItems WHERE OrderId = @Order1 AND ItemId <> @Item1;
SELECT TOP 1 @Item3  = ItemId    FROM slb.OrderItems WHERE OrderId = @Order2;
SELECT TOP 1 @Silo1  = SiloId    FROM slb.Silos WHERE IsActive = 1 ORDER BY SiloCode;
SELECT TOP 1 @Silo2  = SiloId    FROM slb.Silos WHERE IsActive = 1 AND SiloId <> @Silo1 ORDER BY SiloCode;

-- Guard: ถ้าหา IDs ไม่ได้ ให้ข้ามส่วนนี้
IF @Bay1 IS NULL OR @Truck1 IS NULL OR @Order1 IS NULL OR @Item1 IS NULL
BEGIN
    PRINT 'Analytics test data SKIPPED: required base data not found. Run 001 script first.';
    GOTO SkipTestData;
END

-- สร้าง LoadJobs หลากหลาย (COMPLETED, FAILED, CANCELLED + Loss/Over variance)
-- วันที่ 2026-05-10 ถึง 2026-05-13 (4 วัน)

-- Job 1: Bay1, Truck1, COMPLETED, Normal Yield (99.8%)
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-001')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-001', @Order1, @Item1, @Truck1, @Driver1, @Bay1, @Prod1, @Silo1,
        20000, 19960, 0.50, 'COMPLETED',
        '2026-05-10 07:00:00', '2026-05-10 07:28:00');

-- Job 2: Bay1, Truck2, COMPLETED, High Loss (96.5%) → CRITICAL
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-002')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-002', @Order1, @Item1, @Truck2, @Driver2, @Bay1, @Prod1, @Silo1,
        20000, 19300, 0.50, 'COMPLETED',
        '2026-05-10 08:30:00', '2026-05-10 09:05:00');

-- Job 3: Bay2, Truck3, COMPLETED, Over (101.2%)
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-003')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-003', @Order1, @Item1, @Truck3, @Driver3, @Bay2, @Prod1, @Silo1,
        20000, 20240, 0.50, 'COMPLETED',
        '2026-05-10 09:00:00', '2026-05-10 09:22:00');

-- Job 4: Bay1, Truck1, COMPLETED, Normal Prod2 (100.1%)
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-004')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-004', @Order2, ISNULL(@Item3, @Item1), @Truck1, @Driver1, @Bay1, ISNULL(@Prod2, @Prod1), ISNULL(@Silo2, @Silo1),
        15000, 15015, 0.50, 'COMPLETED',
        '2026-05-10 10:00:00', '2026-05-10 10:20:00');

-- Job 5: Bay2, Truck2, FAILED (Equipment failure)
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-005')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt, FailReason)
VALUES ('ANA-TEST-005', @Order2, ISNULL(@Item3, @Item1), @Truck2, @Driver2, @Bay2, ISNULL(@Prod2, @Prod1), ISNULL(@Silo2, @Silo1),
        20000, NULL, 0.50, 'FAILED',
        '2026-05-11 07:30:00', '2026-05-11 07:55:00',
        N'Loading panel communication error');

-- Job 6: Bay1, Truck3, COMPLETED, Warning Loss (98.2%)
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-006')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-006', @Order1, @Item1, @Truck3, @Driver3, @Bay1, @Prod1, @Silo1,
        25000, 24550, 0.50, 'COMPLETED',
        '2026-05-11 08:00:00', '2026-05-11 08:38:00');

-- Job 7: Bay2, Truck1, COMPLETED, Perfect (100.0%)
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-007')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-007', @Order2, ISNULL(@Item3, @Item1), @Truck1, @Driver1, @Bay2, ISNULL(@Prod2, @Prod1), ISNULL(@Silo2, @Silo1),
        18000, 18000, 0.50, 'COMPLETED',
        '2026-05-11 09:00:00', '2026-05-11 09:24:00');

-- Job 8: Bay1, Truck2, COMPLETED, Critical Loss Truck2 again (97.1%) → Problem Truck candidate
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-008')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-008', @Order1, @Item1, @Truck2, @Driver2, @Bay1, @Prod1, @Silo1,
        20000, 19420, 0.50, 'COMPLETED',
        '2026-05-12 07:00:00', '2026-05-12 07:45:00');

-- Job 9: Bay2, Truck3, COMPLETED, Slow but Normal Yield (99.6%)
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-009')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-009', @Order2, ISNULL(@Item3, @Item1), @Truck3, @Driver3, @Bay2, ISNULL(@Prod2, @Prod1), ISNULL(@Silo2, @Silo1),
        22000, 21912, 0.50, 'COMPLETED',
        '2026-05-12 08:00:00', '2026-05-12 09:25:00');  -- 85 นาที = SLOW

-- Job 10: Bay1, Truck1, COMPLETED, Normal (99.9%) — วันนี้
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-010')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-010', @Order1, @Item1, @Truck1, @Driver1, @Bay1, @Prod1, @Silo1,
        20000, 19980, 0.50, 'COMPLETED',
        '2026-05-13 07:00:00', '2026-05-13 07:25:00');

-- Job 11: Bay2, Truck2, FAILED — Truck2 มีปัญหา 3 ครั้ง → Problem Truck
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-011')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt, FailReason)
VALUES ('ANA-TEST-011', @Order2, ISNULL(@Item3, @Item1), @Truck2, @Driver2, @Bay2, ISNULL(@Prod2, @Prod1), ISNULL(@Silo2, @Silo1),
        18000, NULL, 0.50, 'FAILED',
        '2026-05-13 08:00:00', '2026-05-13 08:20:00',
        N'Radar sensor offline during docking');

-- Job 12: Bay1, Truck3, COMPLETED, Normal วันนี้ (99.7%)
IF NOT EXISTS (SELECT 1 FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-012')
INSERT INTO slb.LoadJobs (JobCode, OrderId, OrderItemId, TruckId, DriverId, BayId, ProductId, SiloId,
                           TargetWeight, ActualWeight, TolerancePct, Status, StartedAt, CompletedAt)
VALUES ('ANA-TEST-012', @Order1, @Item1, @Truck3, @Driver3, @Bay1, @Prod1, @Silo1,
        20000, 19940, 0.50, 'COMPLETED',
        '2026-05-13 09:00:00', '2026-05-13 09:22:00');

-- เพิ่ม LoadQueues สำหรับ Turnaround (match กับ Jobs ที่สร้างข้างบน)
IF NOT EXISTS (SELECT 1 FROM slb.LoadQueues WHERE OrderId = @Order1 AND TruckId = @Truck1
               AND EnqueuedAt = '2026-05-10 06:40:00')
INSERT INTO slb.LoadQueues (OrderId, TruckId, DriverId, Priority, Status,
                             EnqueuedAt, CalledAt, DockedAt, CompletedAt)
VALUES (@Order1, @Truck1, @Driver1, 5, 'DONE',
        '2026-05-10 06:40:00', '2026-05-10 06:50:00', '2026-05-10 06:58:00', '2026-05-10 07:28:00');

IF NOT EXISTS (SELECT 1 FROM slb.LoadQueues WHERE OrderId = @Order1 AND TruckId = @Truck2
               AND EnqueuedAt = '2026-05-10 08:00:00')
INSERT INTO slb.LoadQueues (OrderId, TruckId, DriverId, Priority, Status,
                             EnqueuedAt, CalledAt, DockedAt, CompletedAt)
VALUES (@Order1, @Truck2, @Driver2, 5, 'DONE',
        '2026-05-10 08:00:00', '2026-05-10 08:18:00', '2026-05-10 08:28:00', '2026-05-10 09:05:00');

-- เพิ่ม LoadChecklists สำหรับ Turnaround (ReleasedAt)
IF NOT EXISTS (SELECT 1 FROM slb.LoadChecklists lc
               JOIN slb.LoadJobs lj ON lc.JobId = lj.JobId WHERE lj.JobCode = 'ANA-TEST-001')
BEGIN
    DECLARE @JobId1 UNIQUEIDENTIFIER;
    SELECT @JobId1 = JobId FROM slb.LoadJobs WHERE JobCode = 'ANA-TEST-001';
    IF @JobId1 IS NOT NULL
    INSERT INTO slb.LoadChecklists (JobId, WeightVerified, ActualWeight, WeightDiff,
                                     QrVerified, DocumentsVerified, SealVerified, DriverVerified,
                                     VerifiedAt, ReleasedAt)
    VALUES (@JobId1, 1, 19960, -40, 1, 1, 1, 1, '2026-05-10 07:33:00', '2026-05-10 07:40:00');
END

-- เพิ่ม NotificationLogs สำหรับ KPI Alert History
IF NOT EXISTS (SELECT 1 FROM slb.NotificationLogs WHERE Title = N'HIGH LOSS ALERT: ANA-TEST-002')
INSERT INTO slb.NotificationLogs (NotifType, Severity, Title, Message)
VALUES ('LOSS_ALERT', 'CRITICAL',
        N'HIGH LOSS ALERT: ANA-TEST-002',
        N'Job ANA-TEST-002: Yield 96.5% (ต่ำกว่า threshold 97%)');

IF NOT EXISTS (SELECT 1 FROM slb.NotificationLogs WHERE Title = N'HIGH LOSS ALERT: ANA-TEST-008')
INSERT INTO slb.NotificationLogs (NotifType, Severity, Title, Message)
VALUES ('LOSS_ALERT', 'CRITICAL',
        N'HIGH LOSS ALERT: ANA-TEST-008',
        N'Job ANA-TEST-008: Yield 97.1% (ต่ำกว่า threshold 97%)');

PRINT 'Analytics test data: 12 LoadJobs + 2 LoadQueues + 1 Checklist + 2 NotifLogs inserted';
GOTO AfterTestData;

SkipTestData:
AfterTestData:
GO

-- ============================================================
-- SECTION 7: Quick Verify
-- ============================================================

PRINT '-- Quick Verify Analytics Objects...';
GO

-- Schema
SELECT 'ana schema' AS Object, COUNT(*) AS Found FROM sys.schemas WHERE name = 'ana';

-- Tables
SELECT 'ana.AnalyticsConfig' AS Object, COUNT(*) AS RowCount FROM ana.AnalyticsConfig;

-- Views
SELECT 'Views' AS Category, name AS ObjectName, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID('ana') AND type = 'V'
ORDER BY name;

-- Stored Procedures
SELECT 'Stored Procedures' AS Category, name AS ObjectName, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID('ana') AND type = 'P'
ORDER BY name;

-- Indexes (analytics)
SELECT 'Analytics Indexes' AS Category, i.name AS IndexName, t.name AS TableName
FROM sys.indexes i
JOIN sys.tables  t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'slb'
  AND i.name LIKE 'IX_Load%'
ORDER BY t.name, i.name;

-- View Sample Test
SELECT 'vw_JobPerformance rows' AS View_Name, COUNT(*) AS RowCount FROM ana.vw_JobPerformance;
SELECT 'vw_DailyPerformance rows' AS View_Name, COUNT(*) AS RowCount FROM ana.vw_DailyPerformance;
SELECT 'vw_BayPerformance rows' AS View_Name, COUNT(*) AS RowCount FROM ana.vw_BayPerformance;
SELECT 'vw_TruckProblemHistory rows' AS View_Name, COUNT(*) AS RowCount FROM ana.vw_TruckProblemHistory;
GO

-- SP Test
EXEC ana.sp_GetPerformanceDashboard
    @DateFrom = '2026-05-10',
    @DateTo   = '2026-05-13';
GO

EXEC ana.sp_GetLossYieldDashboard
    @DateFrom  = '2026-05-10',
    @DateTo    = '2026-05-13';
GO

EXEC ana.sp_GetTruckProblemReport
    @DateFrom     = '2026-05-10',
    @DateTo       = '2026-05-13',
    @MinIncidents = 1;
GO

EXEC ana.sp_GetAnalyticsConfig;
GO

PRINT '-- Analytics Objects Creation COMPLETE --';
GO

-- ============================================================
-- SECTION 8: Rollback Script
-- ============================================================
/*
=== ROLLBACK: ลบ Analytics Objects ทั้งหมด ===
คัดลอก Block นี้และรันแยกเมื่อต้องการ Rollback

-- Drop SPs
DROP PROCEDURE IF EXISTS ana.sp_GetPerformanceDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetLossYieldDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetBayPerformanceDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetTurnaroundDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetProductLossAnalysis;
DROP PROCEDURE IF EXISTS ana.sp_GetTruckProblemReport;
DROP PROCEDURE IF EXISTS ana.sp_GetHourlyThroughput;
DROP PROCEDURE IF EXISTS ana.sp_GetShiftPerformance;
DROP PROCEDURE IF EXISTS ana.sp_GetKpiAlertHistory;
DROP PROCEDURE IF EXISTS ana.sp_GetAnalyticsConfig;
DROP PROCEDURE IF EXISTS ana.sp_UpdateAnalyticsConfig;

-- Drop Views
DROP VIEW IF EXISTS ana.vw_JobPerformance;
DROP VIEW IF EXISTS ana.vw_QueuePerformance;
DROP VIEW IF EXISTS ana.vw_DailyPerformance;
DROP VIEW IF EXISTS ana.vw_BayPerformance;
DROP VIEW IF EXISTS ana.vw_ProductLossYield;
DROP VIEW IF EXISTS ana.vw_TruckTurnaround;
DROP VIEW IF EXISTS ana.vw_HourlyThroughput;
DROP VIEW IF EXISTS ana.vw_TruckProblemHistory;
DROP VIEW IF EXISTS ana.vw_FormulaLossAnalysis;
DROP VIEW IF EXISTS ana.vw_ShiftPerformance;

-- Drop Table
DROP TABLE IF EXISTS ana.AnalyticsConfig;

-- Drop Analytics Indexes on slb (optional)
DROP INDEX IF EXISTS IX_LoadJobs_CompletedAt_Status  ON slb.LoadJobs;
DROP INDEX IF EXISTS IX_LoadJobs_StartedAt_BayId     ON slb.LoadJobs;
DROP INDEX IF EXISTS IX_LoadJobs_TruckId_Status      ON slb.LoadJobs;
DROP INDEX IF EXISTS IX_LoadJobs_OrderItemId         ON slb.LoadJobs;
DROP INDEX IF EXISTS IX_LoadQueues_CalledAt          ON slb.LoadQueues;
DROP INDEX IF EXISTS IX_LoadQueues_EnqueuedAt        ON slb.LoadQueues;
DROP INDEX IF EXISTS IX_BayLogs_BayId_EventType      ON slb.BayLogs;

-- Drop Test Data (ถ้าต้องการ)
DELETE FROM slb.NotificationLogs WHERE Title LIKE 'HIGH LOSS ALERT: ANA-TEST-%';
DELETE FROM slb.LoadChecklists WHERE JobId IN
    (SELECT JobId FROM slb.LoadJobs WHERE JobCode LIKE 'ANA-TEST-%');
DELETE FROM slb.LoadJobs WHERE JobCode LIKE 'ANA-TEST-%';
DELETE FROM slb.LoadQueues WHERE EnqueuedAt BETWEEN '2026-05-10' AND '2026-05-13 23:59:59'
    AND OrderId IN (SELECT OrderId FROM slb.Orders WHERE OrderCode LIKE 'ORD-2026%');

-- Drop Schema (ทำได้เฉพาะเมื่อไม่มี Object ใน Schema แล้ว)
-- DROP SCHEMA ana;
*/
