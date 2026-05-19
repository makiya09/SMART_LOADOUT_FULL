/* =============================================================================
   db/analytics/001_create_loading_performance_analytics.sql

   Smart Load Bulk — Loading Performance Analytics
   Author  : Shuri (Database Agent)
   Date    : 2026-05-13
   Version : 1.0

   Prerequisites:
     - db/001_create_smart_load_bulk_tables.sql ต้องรันก่อน
     - SQL Server 2019+
     - Database: SmartLoadBulkDB

   Contents:
     Section 1 : Schema Setup + AnalyticsConfig
     Section 2 : Performance Indexes (6 indexes on slb tables)
     Section 3 : Views (5 views in ana schema)
                   3.1 vw_JobPerformance
                   3.2 vw_DailyPerformance
                   3.3 vw_LossYield
                   3.4 vw_BayPerformance
                   3.5 vw_TruckTurnaround
     Section 4 : Stored Procedures (4 SPs in ana schema)
                   SP01 sp_GetPerformanceDashboard
                   SP02 sp_GetLossYieldDashboard
                   SP03 sp_GetBayPerformanceDashboard
                   SP04 sp_GetTurnaroundDashboard
     Section 5 : Test Queries
     Section 6 : Rollback Script (commented)

   Filter Support (ทุก SP รองรับ):
     @DateFrom / @DateTo   — ช่วงวันที่
     @ProductId            — กรอง Product เฉพาะ
     @BayId                — กรอง Loading Bay เฉพาะ
     @CustomerId           — กรอง Customer เฉพาะ
     @LicensePlate         — กรอง Truck ตามทะเบียน
============================================================================= */

USE SmartLoadBulkDB;
GO

-- ============================================================================
-- SECTION 1: SCHEMA SETUP + AnalyticsConfig
-- ============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ana')
    EXEC('CREATE SCHEMA ana');
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'ana' AND t.name = 'AnalyticsConfig'
)
BEGIN
    CREATE TABLE ana.AnalyticsConfig (
        ConfigKey     VARCHAR(50)      NOT NULL CONSTRAINT PK_AnalyticsConfig PRIMARY KEY,
        ConfigValue   NVARCHAR(200)    NOT NULL,
        Description   NVARCHAR(300)   NULL,
        UpdatedBy     NVARCHAR(100)   NULL,
        UpdatedAt     DATETIME2       NOT NULL DEFAULT SYSDATETIME()
    );
END;
GO

-- Seed ค่าตั้งต้น (MERGE = idempotent)
MERGE ana.AnalyticsConfig AS tgt
USING (VALUES
    ('WORKING_HOURS_PER_DAY',   '16',   'จำนวนชั่วโมงทำงานต่อวัน (ใช้คำนวณ BayUtilization)'),
    ('YIELD_WARNING_PCT',       '99.5', 'Yield ต่ำกว่านี้ = WARNING'),
    ('YIELD_CRITICAL_PCT',      '99.0', 'Yield ต่ำกว่านี้ = CRITICAL'),
    ('OVER_WARNING_PCT',        '100.5','Yield เกินนี้ = WARNING (Over)'),
    ('OVER_CRITICAL_PCT',       '101.0','Yield เกินนี้ = CRITICAL (Over)'),
    ('LOADING_TIME_WARNING_MIN','60',   'เวลาโหลดเกินนี้ = WARNING (นาที)'),
    ('LOADING_TIME_CRITICAL_MIN','90',  'เวลาโหลดเกินนี้ = CRITICAL (นาที)'),
    ('QUEUE_WAIT_WARNING_MIN',  '30',   'รอคิวเกินนี้ = WARNING (นาที)'),
    ('TURNAROUND_WARNING_MIN',  '120',  'Turnaround เกินนี้ = WARNING (นาที)'),
    ('BAY_UTIL_LOW_PCT',        '50',   'Bay Utilization ต่ำกว่านี้ = LOW'),
    ('THROUGHPUT_MIN_TON_HOUR', '10',   'Throughput ต่ำกว่านี้ = LOW (ตัน/ชม)')
) AS src(ConfigKey, ConfigValue, Description)
ON tgt.ConfigKey = src.ConfigKey
WHEN NOT MATCHED THEN
    INSERT (ConfigKey, ConfigValue, Description) VALUES (src.ConfigKey, src.ConfigValue, src.Description);
GO


-- ============================================================================
-- SECTION 2: PERFORMANCE INDEXES ON slb TABLES
-- ============================================================================

-- IX-A: LoadJobs กรองด้วย CompletedAt + Status (query หลักของ Analytics)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadJobs_CompletedAt_Analytics' AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE NONCLUSTERED INDEX IX_LoadJobs_CompletedAt_Analytics
        ON slb.LoadJobs (CompletedAt, Status)
        INCLUDE (BayId, TruckId, DriverId, ProductId, OrderId, OrderItemId,
                 TargetWeight, ActualWeight, StartedAt, TolerancePct);
GO

-- IX-B: LoadJobs กรองด้วย StartedAt (สำหรับ Shift / Hourly Report)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadJobs_StartedAt_Analytics' AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE NONCLUSTERED INDEX IX_LoadJobs_StartedAt_Analytics
        ON slb.LoadJobs (StartedAt, Status)
        INCLUDE (BayId, TruckId, ProductId, OrderId, ActualWeight, TargetWeight);
GO

-- IX-C: LoadJobs กรอง BayId (สำหรับ Bay Dashboard)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadJobs_BayId_Completed' AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE NONCLUSTERED INDEX IX_LoadJobs_BayId_Completed
        ON slb.LoadJobs (BayId, CompletedAt)
        INCLUDE (Status, ActualWeight, TargetWeight, StartedAt, TruckId, ProductId);
GO

-- IX-D: LoadJobs กรอง TruckId (สำหรับ Truck / Turnaround Dashboard)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadJobs_TruckId_Analytics' AND object_id = OBJECT_ID('slb.LoadJobs'))
    CREATE NONCLUSTERED INDEX IX_LoadJobs_TruckId_Analytics
        ON slb.LoadJobs (TruckId, CompletedAt, Status)
        INCLUDE (BayId, ProductId, ActualWeight, TargetWeight, StartedAt, DriverId, OrderId);
GO

-- IX-E: LoadQueues join กับ LoadJobs (OrderId + TruckId + DriverId)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadQueues_Join_Analytics' AND object_id = OBJECT_ID('slb.LoadQueues'))
    CREATE NONCLUSTERED INDEX IX_LoadQueues_Join_Analytics
        ON slb.LoadQueues (OrderId, TruckId, DriverId)
        INCLUDE (QueueId, Status, EnqueuedAt, CalledAt, DockedAt, CompletedAt);
GO

-- IX-F: LoadChecklists join กับ LoadJobs (JobId) — ReleasedAt สำหรับ Turnaround
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoadChecklists_JobId_Released' AND object_id = OBJECT_ID('slb.LoadChecklists'))
    CREATE NONCLUSTERED INDEX IX_LoadChecklists_JobId_Released
        ON slb.LoadChecklists (JobId)
        INCLUDE (ReleasedAt, VerifiedAt, ActualWeight, WeightDiff);
GO


-- ============================================================================
-- SECTION 3: VIEWS
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 3.1  vw_JobPerformance
--      KPI รายละเอียดต่อ Job — ใช้เป็น Base ของ Dashboard ทั้งหมด
--      Filter ได้: Date, ProductId, BayId, CustomerId, LicensePlate
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER VIEW ana.vw_JobPerformance
AS
SELECT
    -- Keys
    lj.JobId,
    lj.JobCode,
    CAST(COALESCE(lj.CompletedAt, lj.StartedAt) AS DATE)               AS JobDate,

    -- Order / Customer
    o.OrderId,
    o.OrderCode,
    c.CustomerId,
    c.CustomerCode,
    c.CustomerName,

    -- Product
    p.ProductId,
    p.ProductCode,
    p.ProductName,
    p.Unit,

    -- Bay
    b.BayId,
    b.BayCode,
    b.BayName,

    -- Truck / Driver
    t.TruckId,
    t.LicensePlate,
    t.TruckType,
    d.DriverId,
    d.FullName                                                           AS DriverName,

    -- Weight (kg)
    lj.TargetWeight,
    lj.ActualWeight,
    lj.TolerancePct,

    -- Yield KPIs
    ROUND(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0, 4)     AS YieldPct,
    ROUND(lj.ActualWeight - lj.TargetWeight, 3)                         AS DiffKg,
    ROUND((lj.ActualWeight - lj.TargetWeight)
          / NULLIF(lj.TargetWeight, 0) * 100.0, 4)                      AS DiffPct,

    CASE WHEN lj.ActualWeight < lj.TargetWeight
         THEN ROUND(lj.TargetWeight - lj.ActualWeight, 3)
         ELSE 0 END                                                      AS LossKg,
    CASE WHEN lj.ActualWeight > lj.TargetWeight
         THEN ROUND(lj.ActualWeight - lj.TargetWeight, 3)
         ELSE 0 END                                                      AS OverKg,

    CAST(
        CASE WHEN ABS((lj.ActualWeight - lj.TargetWeight)
                      / NULLIF(lj.TargetWeight, 0) * 100.0)
                  <= lj.TolerancePct
             THEN 1 ELSE 0
        END AS BIT)                                                      AS IsAccurate,

    -- Loss Category
    CASE
        WHEN lj.ActualWeight < lj.TargetWeight * 0.990 THEN 'CRITICAL_LOSS'
        WHEN lj.ActualWeight < lj.TargetWeight * 0.995 THEN 'WARNING_LOSS'
        WHEN lj.ActualWeight > lj.TargetWeight * 1.010 THEN 'CRITICAL_OVER'
        WHEN lj.ActualWeight > lj.TargetWeight * 1.005 THEN 'WARNING_OVER'
        ELSE 'NORMAL'
    END                                                                  AS LossCategory,

    -- Time KPIs
    lj.StartedAt,
    lj.CompletedAt,
    DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)                      AS LoadingDurationMin,

    CASE WHEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) > 0
         THEN ROUND(lj.ActualWeight / 1000.0
                    / (DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) / 60.0), 4)
         ELSE NULL
    END                                                                  AS ThroughputTonPerHour,

    -- Shift
    CASE
        WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 6  AND 13 THEN 'SHIFT1'
        WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 14 AND 21 THEN 'SHIFT2'
        ELSE 'SHIFT3'
    END                                                                  AS ShiftName,

    -- Status
    lj.Status,
    lj.FailReason,
    lj.CreatedAt
FROM slb.LoadJobs       lj
INNER JOIN slb.Orders     o  ON lj.OrderId   = o.OrderId
INNER JOIN slb.Customers  c  ON o.CustomerId = c.CustomerId
INNER JOIN slb.Products   p  ON lj.ProductId = p.ProductId
INNER JOIN slb.Bays       b  ON lj.BayId     = b.BayId
INNER JOIN slb.Trucks     t  ON lj.TruckId   = t.TruckId
INNER JOIN slb.Drivers    d  ON lj.DriverId  = d.DriverId
WHERE lj.ActualWeight IS NOT NULL
  AND lj.Status IN ('COMPLETED', 'FAILED', 'CANCELLED');
GO


-- ─────────────────────────────────────────────────────────────────────────────
-- 3.2  vw_DailyPerformance
--      KPI รวมรายวัน — ใช้แสดง Trend Chart + Daily Summary Table
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER VIEW ana.vw_DailyPerformance
AS
SELECT
    CAST(COALESCE(lj.CompletedAt, lj.StartedAt) AS DATE)               AS WorkDate,

    -- Volume
    COUNT(*)                                                             AS TotalJobs,
    SUM(CASE WHEN lj.Status = 'COMPLETED' THEN 1 ELSE 0 END)           AS CompletedJobs,
    SUM(CASE WHEN lj.Status = 'CANCELLED' THEN 1 ELSE 0 END)           AS CancelledJobs,
    SUM(CASE WHEN lj.Status = 'FAILED'    THEN 1 ELSE 0 END)           AS FailedJobs,

    ROUND(
        SUM(CASE WHEN lj.Status = 'COMPLETED' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(*), 0), 2)                               AS CompletionRatePct,

    -- Weight (ตัน)
    ROUND(SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.TargetWeight ELSE 0 END)
          / 1000.0, 3)                                                   AS TotalTargetWeightTon,
    ROUND(SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.ActualWeight ELSE 0 END)
          / 1000.0, 3)                                                   AS TotalActualWeightTon,

    -- Yield / Loss / Over
    ROUND(
        SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.ActualWeight  ELSE 0 END)
        / NULLIF(SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.TargetWeight ELSE NULL END), 0)
        * 100.0, 4)                                                      AS OverallYieldPct,

    ROUND(SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight < lj.TargetWeight
                   THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END), 3)
                                                                         AS TotalLossKg,
    ROUND(SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight > lj.TargetWeight
                   THEN lj.ActualWeight - lj.TargetWeight ELSE 0 END), 3)
                                                                         AS TotalOverKg,

    ROUND(AVG(CASE WHEN lj.Status = 'COMPLETED'
                   THEN (lj.ActualWeight - lj.TargetWeight)
                        / NULLIF(lj.TargetWeight, 0) * 100.0
                   ELSE NULL END), 4)                                    AS AvgDiffPct,

    -- Accuracy
    ROUND(
        SUM(CASE WHEN lj.Status = 'COMPLETED'
                  AND ABS((lj.ActualWeight - lj.TargetWeight)
                          / NULLIF(lj.TargetWeight, 0) * 100.0)
                      <= lj.TolerancePct
                 THEN 1 ELSE 0 END)
        * 100.0
        / NULLIF(SUM(CASE WHEN lj.Status = 'COMPLETED' THEN 1 ELSE 0 END), 0), 2)
                                                                         AS LoadingAccuracyPct,

    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight < lj.TargetWeight * 0.995
             THEN 1 ELSE 0 END)                                          AS LossJobCount,
    SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight > lj.TargetWeight * 1.005
             THEN 1 ELSE 0 END)                                          AS OverJobCount,

    -- Time KPIs
    ROUND(AVG(CASE WHEN lj.Status = 'COMPLETED'
                   THEN CAST(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) AS FLOAT)
                   ELSE NULL END), 1)                                    AS AvgLoadingTimeMin,

    -- Throughput (ตัน/ชม)
    ROUND(
        SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.ActualWeight ELSE 0 END) / 1000.0
        / NULLIF(
            SUM(CASE WHEN lj.Status = 'COMPLETED'
                     THEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)
                     ELSE 0 END) / 60.0,
          0), 4)                                                          AS ThroughputTonPerHour

FROM slb.LoadJobs lj
WHERE lj.StartedAt IS NOT NULL
  AND lj.Status IN ('COMPLETED', 'FAILED', 'CANCELLED')
GROUP BY CAST(COALESCE(lj.CompletedAt, lj.StartedAt) AS DATE);
GO


-- ─────────────────────────────────────────────────────────────────────────────
-- 3.3  vw_LossYield
--      Loss / Yield รายละเอียดต่อ Job + Product + Customer
--      ใช้สำหรับ Loss/Yield Dashboard และ Alert
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER VIEW ana.vw_LossYield
AS
SELECT
    lj.JobId,
    lj.JobCode,
    CAST(lj.CompletedAt AS DATE)                                         AS JobDate,

    -- Order / Customer
    o.OrderCode,
    c.CustomerId,
    c.CustomerCode,
    c.CustomerName,

    -- Product
    p.ProductId,
    p.ProductCode,
    p.ProductName,
    p.Unit,

    -- Ordered vs Actual
    oi.RequestedQty                                                      AS OrderedQty,
    lj.TargetWeight,
    lj.ActualWeight,

    -- Yield KPIs
    ROUND(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0, 4)     AS YieldPct,
    ROUND(lj.ActualWeight - lj.TargetWeight, 3)                         AS DiffKg,
    ROUND((lj.ActualWeight - lj.TargetWeight)
          / NULLIF(lj.TargetWeight, 0) * 100.0, 4)                      AS DiffPct,

    CASE WHEN lj.ActualWeight < lj.TargetWeight
         THEN ROUND(lj.TargetWeight - lj.ActualWeight, 3)
         ELSE 0 END                                                      AS LossKg,
    CASE WHEN lj.ActualWeight > lj.TargetWeight
         THEN ROUND(lj.ActualWeight - lj.TargetWeight, 3)
         ELSE 0 END                                                      AS OverKg,

    -- Loss Category (ตาม Threshold ค่าตายตัว; SP จะเทียบกับ AnalyticsConfig อีกที)
    CASE
        WHEN lj.ActualWeight < lj.TargetWeight * 0.990 THEN 'CRITICAL_LOSS'
        WHEN lj.ActualWeight < lj.TargetWeight * 0.995 THEN 'WARNING_LOSS'
        WHEN lj.ActualWeight > lj.TargetWeight * 1.010 THEN 'CRITICAL_OVER'
        WHEN lj.ActualWeight > lj.TargetWeight * 1.005 THEN 'WARNING_OVER'
        ELSE 'NORMAL'
    END                                                                  AS LossCategory,

    -- Bay / Truck
    b.BayId,
    b.BayCode,
    b.BayName,
    t.LicensePlate,
    t.TruckType,
    d.FullName                                                           AS DriverName,

    -- Checklist Weight (จาก Double-Check)
    lc.ActualWeight                                                      AS ChecklistActualWeight,
    lc.WeightDiff                                                        AS ChecklistWeightDiff,

    lj.CompletedAt,
    lj.FailReason
FROM slb.LoadJobs         lj
INNER JOIN slb.Orders     o  ON lj.OrderId      = o.OrderId
INNER JOIN slb.Customers  c  ON o.CustomerId    = c.CustomerId
INNER JOIN slb.OrderItems oi ON lj.OrderItemId  = oi.ItemId
INNER JOIN slb.Products   p  ON lj.ProductId    = p.ProductId
INNER JOIN slb.Bays       b  ON lj.BayId        = b.BayId
INNER JOIN slb.Trucks     t  ON lj.TruckId      = t.TruckId
INNER JOIN slb.Drivers    d  ON lj.DriverId     = d.DriverId
LEFT  JOIN slb.LoadChecklists lc ON lj.JobId    = lc.JobId
WHERE lj.Status = 'COMPLETED'
  AND lj.ActualWeight IS NOT NULL;
GO


-- ─────────────────────────────────────────────────────────────────────────────
-- 3.4  vw_BayPerformance
--      KPI รวมต่อ Bay ต่อวัน — ใช้สำหรับ Bay Dashboard
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER VIEW ana.vw_BayPerformance
AS
SELECT
    CAST(COALESCE(lj.CompletedAt, lj.StartedAt) AS DATE)               AS WorkDate,
    b.BayId,
    b.BayCode,
    b.BayName,
    b.BayType,

    -- Volume
    COUNT(*)                                                             AS TotalJobs,
    SUM(CASE WHEN lj.Status = 'COMPLETED' THEN 1 ELSE 0 END)           AS CompletedJobs,
    SUM(CASE WHEN lj.Status IN ('FAILED','CANCELLED') THEN 1 ELSE 0 END) AS FailedJobs,

    -- Weight
    ROUND(SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.TargetWeight ELSE 0 END) / 1000.0, 3)
                                                                         AS TotalTargetWeightTon,
    ROUND(SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.ActualWeight ELSE 0 END) / 1000.0, 3)
                                                                         AS TotalActualWeightTon,

    -- Yield / Loss
    ROUND(
        SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.ActualWeight  ELSE 0 END)
        / NULLIF(SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.TargetWeight ELSE NULL END), 0)
        * 100.0, 4)                                                      AS AvgYieldPct,

    ROUND(SUM(CASE WHEN lj.Status = 'COMPLETED' AND lj.ActualWeight < lj.TargetWeight
                   THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END), 3)
                                                                         AS TotalLossKg,

    -- Time
    SUM(CASE WHEN lj.Status = 'COMPLETED'
             THEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)
             ELSE 0 END)                                                 AS TotalLoadingMin,

    ROUND(AVG(CASE WHEN lj.Status = 'COMPLETED'
                   THEN CAST(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) AS FLOAT)
                   ELSE NULL END), 1)                                    AS AvgLoadingTimeMin,

    -- BayUtilizationPct (คำนวณด้วย 16 ชม. default; SP จะ override จาก AnalyticsConfig)
    ROUND(
        SUM(CASE WHEN lj.Status = 'COMPLETED'
                 THEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) ELSE 0 END)
        * 100.0 / NULLIF(16.0 * 60, 0), 2)                              AS BayUtilizationPct_16h,

    -- Throughput
    ROUND(
        SUM(CASE WHEN lj.Status = 'COMPLETED' THEN lj.ActualWeight ELSE 0 END) / 1000.0
        / NULLIF(
            SUM(CASE WHEN lj.Status = 'COMPLETED'
                     THEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)
                     ELSE 0 END) / 60.0,
          0), 4)                                                          AS ThroughputTonPerHour

FROM slb.LoadJobs lj
INNER JOIN slb.Bays b ON lj.BayId = b.BayId
WHERE lj.StartedAt IS NOT NULL
  AND lj.Status IN ('COMPLETED', 'FAILED', 'CANCELLED')
GROUP BY
    CAST(COALESCE(lj.CompletedAt, lj.StartedAt) AS DATE),
    b.BayId, b.BayCode, b.BayName, b.BayType;
GO


-- ─────────────────────────────────────────────────────────────────────────────
-- 3.5  vw_TruckTurnaround
--      เวลา Turnaround รายละเอียดต่อ Job
--      DockedAt (LoadQueues) → ReleasedAt (LoadChecklists)
--      Join LoadQueues ผ่าน OrderId + TruckId + DriverId
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER VIEW ana.vw_TruckTurnaround
AS
SELECT
    lj.JobId,
    lj.JobCode,
    CAST(lj.CompletedAt AS DATE)                                         AS JobDate,

    -- Order / Customer
    o.OrderCode,
    c.CustomerId,
    c.CustomerCode,
    c.CustomerName,

    -- Bay / Truck / Driver
    b.BayId,
    b.BayCode,
    b.BayName,
    t.TruckId,
    t.LicensePlate,
    t.TruckType,
    d.DriverId,
    d.FullName                                                           AS DriverName,

    -- Weight
    lj.TargetWeight,
    lj.ActualWeight,
    ROUND(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0, 4)     AS YieldPct,

    -- Timestamps
    lq.EnqueuedAt,
    lq.CalledAt,
    lq.DockedAt,
    lj.StartedAt                                                         AS LoadStartedAt,
    lj.CompletedAt                                                       AS LoadCompletedAt,
    lc.VerifiedAt                                                        AS ChecklistVerifiedAt,
    lc.ReleasedAt                                                        AS GateReleasedAt,

    -- Time Breakdown (นาที)
    DATEDIFF(MINUTE, lq.EnqueuedAt, lq.CalledAt)                        AS QueueWaitMin,
    DATEDIFF(MINUTE, lq.CalledAt,   lq.DockedAt)                        AS CallToDockMin,
    DATEDIFF(MINUTE, lq.DockedAt,   lj.StartedAt)                       AS DockToLoadStartMin,
    DATEDIFF(MINUTE, lj.StartedAt,  lj.CompletedAt)                     AS LoadingMin,
    DATEDIFF(MINUTE, lj.CompletedAt, lc.ReleasedAt)                     AS ChecklistMin,

    -- Turnaround = DockedAt → GateReleasedAt
    DATEDIFF(MINUTE, lq.DockedAt,    lc.ReleasedAt)                     AS TurnaroundMin,

    -- Total System Time = EnqueuedAt → GateReleasedAt
    DATEDIFF(MINUTE, lq.EnqueuedAt,  lc.ReleasedAt)                     AS TotalSystemTimeMin

FROM slb.LoadJobs          lj
INNER JOIN slb.Orders       o  ON lj.OrderId   = o.OrderId
INNER JOIN slb.Customers    c  ON o.CustomerId = c.CustomerId
INNER JOIN slb.Bays         b  ON lj.BayId     = b.BayId
INNER JOIN slb.Trucks       t  ON lj.TruckId   = t.TruckId
INNER JOIN slb.Drivers      d  ON lj.DriverId  = d.DriverId
LEFT  JOIN slb.LoadQueues   lq ON  lj.OrderId  = lq.OrderId
                               AND lj.TruckId  = lq.TruckId
                               AND lj.DriverId = lq.DriverId
LEFT  JOIN slb.LoadChecklists lc ON lj.JobId   = lc.JobId
WHERE lj.Status = 'COMPLETED';
GO


-- ============================================================================
-- SECTION 4: STORED PROCEDURES
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- SP01: sp_GetPerformanceDashboard
--
-- Dashboard หลัก — Overview KPI + Daily Trend + Bay Comparison + Top Loss Jobs
--
-- Parameters:
--   @DateFrom    DATE               (required)
--   @DateTo      DATE               (required)
--   @BayId       UNIQUEIDENTIFIER   (optional — NULL = ทุก Bay)
--   @CustomerId  UNIQUEIDENTIFIER   (optional — NULL = ทุก Customer)
--
-- Result Sets:
--   #1  Summary KPIs (1 row)
--   #2  Daily Trend (N rows ตามช่วงวันที่)
--   #3  Bay Comparison (ต่อ Bay)
--   #4  Top 10 High Loss Jobs
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE ana.sp_GetPerformanceDashboard
    @DateFrom    DATE,
    @DateTo      DATE,
    @BayId       UNIQUEIDENTIFIER = NULL,
    @CustomerId  UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ดึงค่า Threshold จาก Config
    DECLARE @WorkingHours     FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'WORKING_HOURS_PER_DAY'), 16);
    DECLARE @YieldWarning     FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'YIELD_WARNING_PCT'),      99.5);
    DECLARE @YieldCritical    FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'YIELD_CRITICAL_PCT'),     99.0);
    DECLARE @LoadTimeWarning  FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'LOADING_TIME_WARNING_MIN'), 60);

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #1: Summary KPIs
    -- ──────────────────────────────────────────────────────────────
    SELECT
        COUNT(*)                                                         AS TotalJobs,
        SUM(CASE WHEN jp.Status = 'COMPLETED' THEN 1 ELSE 0 END)       AS CompletedJobs,
        SUM(CASE WHEN jp.Status = 'CANCELLED' THEN 1 ELSE 0 END)       AS CancelledJobs,
        SUM(CASE WHEN jp.Status = 'FAILED'    THEN 1 ELSE 0 END)       AS FailedJobs,

        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN 1 ELSE 0 END)
              * 100.0 / NULLIF(COUNT(*), 0), 2)                         AS CompletionRatePct,

        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.TargetWeight ELSE 0 END) / 1000.0, 3)
                                                                         AS TotalTargetWeightTon,
        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.ActualWeight ELSE 0 END) / 1000.0, 3)
                                                                         AS TotalActualWeightTon,

        ROUND(
            SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.ActualWeight  ELSE 0 END)
            / NULLIF(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.TargetWeight ELSE NULL END), 0)
            * 100.0, 4)                                                  AS OverallYieldPct,

        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' AND jp.ActualWeight < jp.TargetWeight
                       THEN jp.TargetWeight - jp.ActualWeight ELSE 0 END), 3)
                                                                         AS TotalLossKg,

        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' AND jp.ActualWeight > jp.TargetWeight
                       THEN jp.ActualWeight - jp.TargetWeight ELSE 0 END), 3)
                                                                         AS TotalOverKg,

        ROUND(
            SUM(CASE WHEN jp.Status = 'COMPLETED'
                      AND ABS(jp.DiffPct) <= jp.TolerancePct
                     THEN 1 ELSE 0 END)
            * 100.0
            / NULLIF(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN 1 ELSE 0 END), 0), 2)
                                                                         AS LoadingAccuracyPct,

        ROUND(AVG(CASE WHEN jp.Status = 'COMPLETED'
                       THEN CAST(jp.LoadingDurationMin AS FLOAT) ELSE NULL END), 1)
                                                                         AS AvgLoadingTimeMin,

        ROUND(
            SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.ActualWeight ELSE 0 END) / 1000.0
            / NULLIF(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.LoadingDurationMin ELSE 0 END) / 60.0, 0)
            , 4)                                                          AS ThroughputTonPerHour,

        @YieldWarning    AS Threshold_YieldWarning,
        @YieldCritical   AS Threshold_YieldCritical,
        @LoadTimeWarning AS Threshold_LoadingTimeWarning

    FROM ana.vw_JobPerformance jp
    WHERE jp.JobDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId      IS NULL OR jp.BayId      = @BayId)
      AND (@CustomerId IS NULL OR jp.CustomerId = @CustomerId);

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #2: Daily Trend
    -- ──────────────────────────────────────────────────────────────
    SELECT
        dp.WorkDate,
        dp.TotalJobs,
        dp.CompletedJobs,
        dp.FailedJobs,
        dp.CompletionRatePct,
        dp.TotalActualWeightTon,
        dp.OverallYieldPct,
        dp.TotalLossKg,
        dp.LoadingAccuracyPct,
        dp.AvgLoadingTimeMin,
        dp.ThroughputTonPerHour,
        CASE WHEN dp.OverallYieldPct < @YieldCritical THEN 'CRITICAL'
             WHEN dp.OverallYieldPct < @YieldWarning  THEN 'WARNING'
             ELSE 'NORMAL'
        END AS YieldStatus
    FROM ana.vw_DailyPerformance dp
    WHERE dp.WorkDate BETWEEN @DateFrom AND @DateTo
    ORDER BY dp.WorkDate;

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #3: Bay Comparison
    -- ──────────────────────────────────────────────────────────────
    DECLARE @WorkingMinPerDay FLOAT = @WorkingHours * 60 * DATEDIFF(DAY, @DateFrom, @DateTo) + @WorkingHours * 60;

    SELECT
        jp.BayId,
        jp.BayCode,
        jp.BayName,
        COUNT(*)                                                         AS TotalJobs,
        SUM(CASE WHEN jp.Status = 'COMPLETED' THEN 1 ELSE 0 END)       AS CompletedJobs,
        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.ActualWeight ELSE 0 END) / 1000.0, 3)
                                                                         AS TotalWeightTon,
        ROUND(
            SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.ActualWeight  ELSE 0 END)
            / NULLIF(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.TargetWeight ELSE NULL END), 0)
            * 100.0, 4)                                                  AS AvgYieldPct,
        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.LoadingDurationMin ELSE 0 END)
              * 100.0 / NULLIF(@WorkingMinPerDay, 0), 2)                 AS BayUtilizationPct,
        ROUND(AVG(CASE WHEN jp.Status = 'COMPLETED'
                       THEN CAST(jp.LoadingDurationMin AS FLOAT) ELSE NULL END), 1)
                                                                         AS AvgLoadingTimeMin
    FROM ana.vw_JobPerformance jp
    WHERE jp.JobDate BETWEEN @DateFrom AND @DateTo
      AND (@CustomerId IS NULL OR jp.CustomerId = @CustomerId)
    GROUP BY jp.BayId, jp.BayCode, jp.BayName
    ORDER BY TotalWeightTon DESC;

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #4: Top 10 High Loss Jobs
    -- ──────────────────────────────────────────────────────────────
    SELECT TOP 10
        jp.JobCode,
        jp.JobDate,
        jp.CustomerName,
        jp.ProductName,
        jp.BayCode,
        jp.LicensePlate,
        jp.TargetWeight,
        jp.ActualWeight,
        jp.YieldPct,
        jp.LossKg,
        jp.OverKg,
        jp.LossCategory,
        jp.LoadingDurationMin,
        jp.FailReason
    FROM ana.vw_JobPerformance jp
    WHERE jp.JobDate BETWEEN @DateFrom AND @DateTo
      AND jp.Status = 'COMPLETED'
      AND jp.LossKg > 0
      AND (@BayId      IS NULL OR jp.BayId      = @BayId)
      AND (@CustomerId IS NULL OR jp.CustomerId = @CustomerId)
    ORDER BY jp.LossKg DESC;
END;
GO


-- ─────────────────────────────────────────────────────────────────────────────
-- SP02: sp_GetLossYieldDashboard
--
-- Loss / Yield Dashboard — Summary + Product Breakdown + Daily Trend + Critical Jobs
--
-- Parameters:
--   @DateFrom     DATE
--   @DateTo       DATE
--   @ProductId    UNIQUEIDENTIFIER  (optional)
--   @BayId        UNIQUEIDENTIFIER  (optional)
--   @CustomerId   UNIQUEIDENTIFIER  (optional)
--   @LicensePlate VARCHAR(20)       (optional — กรอง Truck ตามทะเบียน)
--
-- Result Sets:
--   #1  Loss/Yield Summary KPIs
--   #2  Product Breakdown (Loss per Product)
--   #3  Daily Loss/Yield Trend
--   #4  Critical Loss Jobs (Yield < Threshold)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE ana.sp_GetLossYieldDashboard
    @DateFrom     DATE,
    @DateTo       DATE,
    @ProductId    UNIQUEIDENTIFIER = NULL,
    @BayId        UNIQUEIDENTIFIER = NULL,
    @CustomerId   UNIQUEIDENTIFIER = NULL,
    @LicensePlate VARCHAR(20)      = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @YieldWarning  FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'YIELD_WARNING_PCT'),  99.5);
    DECLARE @YieldCritical FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'YIELD_CRITICAL_PCT'), 99.0);
    DECLARE @OverWarning   FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'OVER_WARNING_PCT'),   100.5);
    DECLARE @OverCritical  FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'OVER_CRITICAL_PCT'),  101.0);

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #1: Loss/Yield Summary
    -- ──────────────────────────────────────────────────────────────
    SELECT
        COUNT(*)                                                         AS TotalCompletedJobs,
        ROUND(SUM(ly.TargetWeight) / 1000.0, 3)                         AS TotalTargetWeightTon,
        ROUND(SUM(ly.ActualWeight) / 1000.0, 3)                         AS TotalActualWeightTon,
        ROUND(SUM(ly.ActualWeight) / NULLIF(SUM(ly.TargetWeight), 0) * 100.0, 4)
                                                                         AS OverallYieldPct,
        ROUND(SUM(ly.LossKg), 3)                                         AS TotalLossKg,
        ROUND(SUM(ly.OverKg), 3)                                         AS TotalOverKg,
        SUM(CASE WHEN ly.LossKg > 0 THEN 1 ELSE 0 END)                 AS LossJobCount,
        SUM(CASE WHEN ly.OverKg > 0 THEN 1 ELSE 0 END)                 AS OverJobCount,
        SUM(CASE WHEN ly.LossCategory = 'CRITICAL_LOSS' THEN 1 ELSE 0 END) AS CriticalLossJobs,
        ROUND(AVG(ly.DiffPct), 4)                                        AS AvgDiffPct,
        -- Threshold reference
        @YieldWarning  AS Threshold_YieldWarning,
        @YieldCritical AS Threshold_YieldCritical,
        @OverWarning   AS Threshold_OverWarning,
        @OverCritical  AS Threshold_OverCritical
    FROM ana.vw_LossYield ly
    WHERE ly.JobDate BETWEEN @DateFrom AND @DateTo
      AND (@ProductId    IS NULL OR ly.ProductId    = @ProductId)
      AND (@BayId        IS NULL OR ly.BayId        = @BayId)
      AND (@CustomerId   IS NULL OR ly.CustomerId   = @CustomerId)
      AND (@LicensePlate IS NULL OR ly.LicensePlate = @LicensePlate);

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #2: Product Breakdown
    -- ──────────────────────────────────────────────────────────────
    SELECT
        ly.ProductId,
        ly.ProductCode,
        ly.ProductName,
        ly.Unit,
        COUNT(*)                                                         AS TotalJobs,
        ROUND(SUM(ly.TargetWeight) / 1000.0, 3)                         AS TotalTargetWeightTon,
        ROUND(SUM(ly.ActualWeight) / 1000.0, 3)                         AS TotalActualWeightTon,
        ROUND(SUM(ly.ActualWeight) / NULLIF(SUM(ly.TargetWeight), 0) * 100.0, 4)
                                                                         AS YieldPct,
        ROUND(SUM(ly.LossKg), 3)                                         AS TotalLossKg,
        ROUND(SUM(ly.OverKg), 3)                                         AS TotalOverKg,
        ROUND(AVG(ly.DiffPct), 4)                                        AS AvgDiffPct,
        ROUND(STDEV(ly.YieldPct), 4)                                     AS YieldStdDev,
        SUM(CASE WHEN ly.LossCategory IN ('CRITICAL_LOSS','WARNING_LOSS') THEN 1 ELSE 0 END) AS LossJobCount
    FROM ana.vw_LossYield ly
    WHERE ly.JobDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId        IS NULL OR ly.BayId        = @BayId)
      AND (@CustomerId   IS NULL OR ly.CustomerId   = @CustomerId)
      AND (@LicensePlate IS NULL OR ly.LicensePlate = @LicensePlate)
    GROUP BY ly.ProductId, ly.ProductCode, ly.ProductName, ly.Unit
    ORDER BY TotalLossKg DESC;

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #3: Daily Loss/Yield Trend
    -- ──────────────────────────────────────────────────────────────
    SELECT
        ly.JobDate,
        COUNT(*)                                                         AS TotalJobs,
        ROUND(SUM(ly.ActualWeight) / NULLIF(SUM(ly.TargetWeight), 0) * 100.0, 4)
                                                                         AS YieldPct,
        ROUND(SUM(ly.LossKg), 3)                                         AS TotalLossKg,
        ROUND(SUM(ly.OverKg), 3)                                         AS TotalOverKg,
        SUM(CASE WHEN ly.LossCategory = 'CRITICAL_LOSS' THEN 1 ELSE 0 END) AS CriticalLossCount,
        CASE WHEN SUM(ly.ActualWeight) / NULLIF(SUM(ly.TargetWeight), 0) * 100.0 < @YieldCritical
             THEN 'CRITICAL'
             WHEN SUM(ly.ActualWeight) / NULLIF(SUM(ly.TargetWeight), 0) * 100.0 < @YieldWarning
             THEN 'WARNING'
             ELSE 'NORMAL'
        END AS YieldStatus
    FROM ana.vw_LossYield ly
    WHERE ly.JobDate BETWEEN @DateFrom AND @DateTo
      AND (@ProductId    IS NULL OR ly.ProductId    = @ProductId)
      AND (@BayId        IS NULL OR ly.BayId        = @BayId)
      AND (@CustomerId   IS NULL OR ly.CustomerId   = @CustomerId)
      AND (@LicensePlate IS NULL OR ly.LicensePlate = @LicensePlate)
    GROUP BY ly.JobDate
    ORDER BY ly.JobDate;

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #4: Critical Loss Jobs (Yield < @YieldWarning)
    -- ──────────────────────────────────────────────────────────────
    SELECT TOP 20
        ly.JobCode,
        ly.JobDate,
        ly.CustomerName,
        ly.ProductCode,
        ly.ProductName,
        ly.BayCode,
        ly.LicensePlate,
        ly.OrderedQty,
        ly.TargetWeight,
        ly.ActualWeight,
        ly.YieldPct,
        ly.LossKg,
        ly.DiffPct,
        ly.LossCategory,
        ly.ChecklistActualWeight,
        ly.ChecklistWeightDiff
    FROM ana.vw_LossYield ly
    WHERE ly.JobDate BETWEEN @DateFrom AND @DateTo
      AND ly.YieldPct < @YieldWarning
      AND (@ProductId    IS NULL OR ly.ProductId    = @ProductId)
      AND (@BayId        IS NULL OR ly.BayId        = @BayId)
      AND (@CustomerId   IS NULL OR ly.CustomerId   = @CustomerId)
      AND (@LicensePlate IS NULL OR ly.LicensePlate = @LicensePlate)
    ORDER BY ly.YieldPct ASC;
END;
GO


-- ─────────────────────────────────────────────────────────────────────────────
-- SP03: sp_GetBayPerformanceDashboard
--
-- Bay Performance Dashboard — Bay Summary + Hourly Heatmap + Bay Daily Trend
--
-- Parameters:
--   @DateFrom  DATE
--   @DateTo    DATE
--   @BayId     UNIQUEIDENTIFIER  (optional)
--
-- Result Sets:
--   #1  Bay Summary (per Bay, ช่วงวันที่ทั้งหมด)
--   #2  Hourly Throughput Heatmap (Bay × Hour ของวันสุดท้ายใน range)
--   #3  Bay Daily Trend
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE ana.sp_GetBayPerformanceDashboard
    @DateFrom  DATE,
    @DateTo    DATE,
    @BayId     UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @WorkingHours     FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'WORKING_HOURS_PER_DAY'), 16);
    DECLARE @TotalDays        INT   = DATEDIFF(DAY, @DateFrom, @DateTo) + 1;
    DECLARE @WorkingMinTotal  FLOAT = @WorkingHours * 60 * @TotalDays;

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #1: Bay Summary
    -- ──────────────────────────────────────────────────────────────
    SELECT
        jp.BayId,
        jp.BayCode,
        jp.BayName,
        COUNT(*)                                                         AS TotalJobs,
        SUM(CASE WHEN jp.Status = 'COMPLETED' THEN 1 ELSE 0 END)       AS CompletedJobs,
        SUM(CASE WHEN jp.Status IN ('FAILED','CANCELLED') THEN 1 ELSE 0 END) AS FailedCancelledJobs,
        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.ActualWeight ELSE 0 END) / 1000.0, 3)
                                                                         AS TotalWeightTon,
        ROUND(
            SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.ActualWeight  ELSE 0 END)
            / NULLIF(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.TargetWeight ELSE NULL END), 0)
            * 100.0, 4)                                                  AS AvgYieldPct,
        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.LoadingDurationMin ELSE 0 END)
              * 100.0 / NULLIF(@WorkingMinTotal, 0), 2)                  AS BayUtilizationPct,
        ROUND(AVG(CASE WHEN jp.Status = 'COMPLETED'
                       THEN CAST(jp.LoadingDurationMin AS FLOAT) ELSE NULL END), 1)
                                                                         AS AvgLoadingTimeMin,
        ROUND(
            SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.ActualWeight ELSE 0 END) / 1000.0
            / NULLIF(SUM(CASE WHEN jp.Status = 'COMPLETED' THEN jp.LoadingDurationMin ELSE 0 END) / 60.0, 0)
            , 4)                                                          AS ThroughputTonPerHour,
        ROUND(SUM(CASE WHEN jp.Status = 'COMPLETED' AND jp.LossKg > 0
                       THEN jp.LossKg ELSE 0 END), 3)                   AS TotalLossKg
    FROM ana.vw_JobPerformance jp
    WHERE jp.JobDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId IS NULL OR jp.BayId = @BayId)
    GROUP BY jp.BayId, jp.BayCode, jp.BayName
    ORDER BY TotalWeightTon DESC;

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #2: Hourly Throughput Heatmap (วันล่าสุดใน range)
    -- Bay × Hour — ตัน/ชั่วโมง
    -- ──────────────────────────────────────────────────────────────
    SELECT
        b.BayCode,
        b.BayName,
        DATEPART(HOUR, lj.StartedAt)                                     AS HourOfDay,
        COUNT(*)                                                         AS JobCount,
        ROUND(SUM(lj.ActualWeight) / 1000.0, 3)                         AS TotalWeightTon,
        ROUND(SUM(lj.ActualWeight) / 1000.0
              / NULLIF(SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) / 60.0, 0), 4)
                                                                         AS ThroughputTonPerHour
    FROM slb.LoadJobs lj
    INNER JOIN slb.Bays b ON lj.BayId = b.BayId
    WHERE lj.Status = 'COMPLETED'
      AND CAST(lj.StartedAt AS DATE) = @DateTo
      AND (@BayId IS NULL OR lj.BayId = @BayId)
    GROUP BY b.BayId, b.BayCode, b.BayName, DATEPART(HOUR, lj.StartedAt)
    ORDER BY b.BayCode, HourOfDay;

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #3: Bay Daily Trend
    -- ──────────────────────────────────────────────────────────────
    SELECT
        bp.WorkDate,
        bp.BayCode,
        bp.BayName,
        bp.TotalJobs,
        bp.CompletedJobs,
        bp.TotalActualWeightTon,
        bp.AvgYieldPct,
        bp.TotalLoadingMin,
        bp.AvgLoadingTimeMin,
        ROUND(bp.TotalLoadingMin * 100.0 / NULLIF(@WorkingHours * 60, 0), 2)
                                                                         AS BayUtilizationPct,
        bp.ThroughputTonPerHour
    FROM ana.vw_BayPerformance bp
    WHERE bp.WorkDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId IS NULL OR bp.BayId = @BayId)
    ORDER BY bp.WorkDate, bp.BayCode;
END;
GO


-- ─────────────────────────────────────────────────────────────────────────────
-- SP04: sp_GetTurnaroundDashboard
--
-- Truck Turnaround Dashboard — Summary + Truck Breakdown + Daily Trend
--
-- Parameters:
--   @DateFrom     DATE
--   @DateTo       DATE
--   @LicensePlate VARCHAR(20)      (optional — กรอง Truck)
--   @BayId        UNIQUEIDENTIFIER (optional)
--   @CustomerId   UNIQUEIDENTIFIER (optional)
--
-- Result Sets:
--   #1  Turnaround Summary KPIs
--   #2  Truck Breakdown (Turnaround per Truck)
--   #3  Daily Turnaround Trend
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE ana.sp_GetTurnaroundDashboard
    @DateFrom     DATE,
    @DateTo       DATE,
    @LicensePlate VARCHAR(20)      = NULL,
    @BayId        UNIQUEIDENTIFIER = NULL,
    @CustomerId   UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TurnaroundWarning FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'TURNAROUND_WARNING_MIN'), 120);
    DECLARE @QueueWaitWarning  FLOAT = ISNULL((SELECT CAST(ConfigValue AS FLOAT) FROM ana.AnalyticsConfig WHERE ConfigKey = 'QUEUE_WAIT_WARNING_MIN'), 30);

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #1: Turnaround Summary KPIs
    -- ──────────────────────────────────────────────────────────────
    SELECT
        COUNT(*)                                                         AS TotalJobs,
        SUM(CASE WHEN tt.TurnaroundMin IS NOT NULL THEN 1 ELSE 0 END)  AS JobsWithFullTurnaround,
        ROUND(AVG(CAST(tt.TurnaroundMin    AS FLOAT)), 1)               AS AvgTurnaroundMin,
        ROUND(MIN(tt.TurnaroundMin), 1)                                 AS MinTurnaroundMin,
        ROUND(MAX(tt.TurnaroundMin), 1)                                 AS MaxTurnaroundMin,
        ROUND(AVG(CAST(tt.QueueWaitMin     AS FLOAT)), 1)               AS AvgQueueWaitMin,
        ROUND(AVG(CAST(tt.LoadingMin       AS FLOAT)), 1)               AS AvgLoadingMin,
        ROUND(AVG(CAST(tt.ChecklistMin     AS FLOAT)), 1)               AS AvgChecklistMin,
        ROUND(AVG(CAST(tt.TotalSystemTimeMin AS FLOAT)), 1)             AS AvgTotalSystemTimeMin,
        SUM(CASE WHEN tt.TurnaroundMin > @TurnaroundWarning THEN 1 ELSE 0 END)
                                                                         AS SlowTurnaroundCount,
        SUM(CASE WHEN tt.QueueWaitMin  > @QueueWaitWarning  THEN 1 ELSE 0 END)
                                                                         AS LongQueueWaitCount,
        @TurnaroundWarning AS Threshold_TurnaroundWarning,
        @QueueWaitWarning  AS Threshold_QueueWaitWarning
    FROM ana.vw_TruckTurnaround tt
    WHERE tt.JobDate BETWEEN @DateFrom AND @DateTo
      AND (@LicensePlate IS NULL OR tt.LicensePlate = @LicensePlate)
      AND (@BayId        IS NULL OR tt.BayId        = @BayId)
      AND (@CustomerId   IS NULL OR tt.CustomerId   = @CustomerId);

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #2: Truck Breakdown
    -- ──────────────────────────────────────────────────────────────
    SELECT
        tt.TruckId,
        tt.LicensePlate,
        tt.TruckType,
        COUNT(*)                                                         AS TotalJobs,
        ROUND(AVG(CAST(tt.TurnaroundMin    AS FLOAT)), 1)               AS AvgTurnaroundMin,
        ROUND(AVG(CAST(tt.QueueWaitMin     AS FLOAT)), 1)               AS AvgQueueWaitMin,
        ROUND(AVG(CAST(tt.LoadingMin       AS FLOAT)), 1)               AS AvgLoadingMin,
        ROUND(AVG(CAST(tt.TotalSystemTimeMin AS FLOAT)), 1)             AS AvgTotalSystemTimeMin,
        SUM(CASE WHEN tt.TurnaroundMin > @TurnaroundWarning THEN 1 ELSE 0 END)
                                                                         AS SlowTurnaroundCount,
        CASE WHEN AVG(CAST(tt.TurnaroundMin AS FLOAT)) > @TurnaroundWarning
             THEN 'SLOW' ELSE 'NORMAL'
        END AS TurnaroundStatus
    FROM ana.vw_TruckTurnaround tt
    WHERE tt.JobDate BETWEEN @DateFrom AND @DateTo
      AND (@BayId        IS NULL OR tt.BayId        = @BayId)
      AND (@CustomerId   IS NULL OR tt.CustomerId   = @CustomerId)
    GROUP BY tt.TruckId, tt.LicensePlate, tt.TruckType
    ORDER BY AvgTurnaroundMin DESC;

    -- ──────────────────────────────────────────────────────────────
    -- Result Set #3: Daily Turnaround Trend
    -- ──────────────────────────────────────────────────────────────
    SELECT
        tt.JobDate,
        COUNT(*)                                                         AS TotalJobs,
        ROUND(AVG(CAST(tt.TurnaroundMin    AS FLOAT)), 1)               AS AvgTurnaroundMin,
        ROUND(AVG(CAST(tt.QueueWaitMin     AS FLOAT)), 1)               AS AvgQueueWaitMin,
        ROUND(AVG(CAST(tt.LoadingMin       AS FLOAT)), 1)               AS AvgLoadingMin,
        ROUND(AVG(CAST(tt.TotalSystemTimeMin AS FLOAT)), 1)             AS AvgTotalSystemTimeMin,
        ROUND(MAX(CAST(tt.TurnaroundMin    AS FLOAT)), 1)               AS MaxTurnaroundMin,
        CASE WHEN AVG(CAST(tt.TurnaroundMin AS FLOAT)) > @TurnaroundWarning
             THEN 'WARNING' ELSE 'NORMAL'
        END AS TurnaroundStatus
    FROM ana.vw_TruckTurnaround tt
    WHERE tt.JobDate BETWEEN @DateFrom AND @DateTo
      AND (@LicensePlate IS NULL OR tt.LicensePlate = @LicensePlate)
      AND (@BayId        IS NULL OR tt.BayId        = @BayId)
      AND (@CustomerId   IS NULL OR tt.CustomerId   = @CustomerId)
    GROUP BY tt.JobDate
    ORDER BY tt.JobDate;
END;
GO


-- ============================================================================
-- SECTION 5: TEST QUERIES
-- ============================================================================

-- ── Quick Verify: Object Count ───────────────────────────────────────────────
SELECT 'SCHEMA'     AS ObjectType, name         AS ObjectName FROM sys.schemas       WHERE name = 'ana'
UNION ALL
SELECT 'TABLE',  t.name FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'ana'
UNION ALL
SELECT 'VIEW',   v.name FROM sys.views  v JOIN sys.schemas s ON v.schema_id = s.schema_id WHERE s.name = 'ana'
UNION ALL
SELECT 'SP',     p.name FROM sys.procedures p JOIN sys.schemas s ON p.schema_id = s.schema_id WHERE s.name = 'ana'
ORDER BY ObjectType, ObjectName;

-- ── Quick Verify: Indexes ─────────────────────────────────────────────────────
SELECT
    OBJECT_NAME(i.object_id) AS TableName,
    i.name                   AS IndexName,
    i.type_desc
FROM sys.indexes i
WHERE i.name LIKE 'IX_LoadJobs_%'
   OR i.name LIKE 'IX_LoadQueues_%'
   OR i.name LIKE 'IX_LoadChecklists_%'
ORDER BY TableName, IndexName;

-- ── Test vw_JobPerformance ────────────────────────────────────────────────────
SELECT TOP 5 * FROM ana.vw_JobPerformance ORDER BY JobDate DESC;

-- ── Test vw_DailyPerformance ──────────────────────────────────────────────────
SELECT * FROM ana.vw_DailyPerformance ORDER BY WorkDate DESC;

-- ── Test vw_LossYield ─────────────────────────────────────────────────────────
SELECT TOP 10 * FROM ana.vw_LossYield ORDER BY LossKg DESC;

-- ── Test vw_BayPerformance ────────────────────────────────────────────────────
SELECT * FROM ana.vw_BayPerformance ORDER BY WorkDate DESC, BayCode;

-- ── Test vw_TruckTurnaround ───────────────────────────────────────────────────
SELECT * FROM ana.vw_TruckTurnaround ORDER BY JobDate DESC;

-- ── Test SP01: GetPerformanceDashboard ────────────────────────────────────────
EXEC ana.sp_GetPerformanceDashboard
    @DateFrom   = '2026-05-01',
    @DateTo     = '2026-05-31',
    @BayId      = NULL,
    @CustomerId = NULL;

-- ── Test SP02: GetLossYieldDashboard ─────────────────────────────────────────
EXEC ana.sp_GetLossYieldDashboard
    @DateFrom     = '2026-05-01',
    @DateTo       = '2026-05-31',
    @ProductId    = NULL,
    @BayId        = NULL,
    @CustomerId   = NULL,
    @LicensePlate = NULL;

-- ── Test SP03: GetBayPerformanceDashboard ─────────────────────────────────────
EXEC ana.sp_GetBayPerformanceDashboard
    @DateFrom = '2026-05-01',
    @DateTo   = '2026-05-31',
    @BayId    = NULL;

-- ── Test SP04: GetTurnaroundDashboard ────────────────────────────────────────
EXEC ana.sp_GetTurnaroundDashboard
    @DateFrom     = '2026-05-01',
    @DateTo       = '2026-05-31',
    @LicensePlate = NULL,
    @BayId        = NULL,
    @CustomerId   = NULL;

-- ── Test with Filters ─────────────────────────────────────────────────────────
-- กรอง Truck เฉพาะทะเบียน
EXEC ana.sp_GetLossYieldDashboard
    @DateFrom     = '2026-05-01',
    @DateTo       = '2026-05-31',
    @LicensePlate = '70-1234';

-- ── Test AnalyticsConfig ──────────────────────────────────────────────────────
SELECT ConfigKey, ConfigValue, Description FROM ana.AnalyticsConfig ORDER BY ConfigKey;

-- ── Test AnalyticsConfig Update ───────────────────────────────────────────────
UPDATE ana.AnalyticsConfig
SET ConfigValue = '97', UpdatedBy = 'admin', UpdatedAt = SYSDATETIME()
WHERE ConfigKey = 'YIELD_CRITICAL_PCT';

SELECT ConfigKey, ConfigValue FROM ana.AnalyticsConfig WHERE ConfigKey = 'YIELD_CRITICAL_PCT';

-- ย้อนกลับ
UPDATE ana.AnalyticsConfig
SET ConfigValue = '99.0', UpdatedAt = SYSDATETIME()
WHERE ConfigKey = 'YIELD_CRITICAL_PCT';


-- ============================================================================
-- SECTION 6: ROLLBACK SCRIPT (commented — uncomment เมื่อต้องการ Drop)
-- ============================================================================

/*
-- WARNING: จะลบ Objects ทั้งหมดใน ana schema

-- Drop Stored Procedures
DROP PROCEDURE IF EXISTS ana.sp_GetTurnaroundDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetBayPerformanceDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetLossYieldDashboard;
DROP PROCEDURE IF EXISTS ana.sp_GetPerformanceDashboard;

-- Drop Views
DROP VIEW IF EXISTS ana.vw_TruckTurnaround;
DROP VIEW IF EXISTS ana.vw_BayPerformance;
DROP VIEW IF EXISTS ana.vw_LossYield;
DROP VIEW IF EXISTS ana.vw_DailyPerformance;
DROP VIEW IF EXISTS ana.vw_JobPerformance;

-- Drop Tables
DROP TABLE IF EXISTS ana.AnalyticsConfig;

-- Drop Schema (ต้อง Drop Objects ทั้งหมดก่อน)
-- DROP SCHEMA ana;

-- Drop Indexes on slb tables
DROP INDEX IF EXISTS IX_LoadChecklists_JobId_Released   ON slb.LoadChecklists;
DROP INDEX IF EXISTS IX_LoadQueues_Join_Analytics        ON slb.LoadQueues;
DROP INDEX IF EXISTS IX_LoadJobs_TruckId_Analytics       ON slb.LoadJobs;
DROP INDEX IF EXISTS IX_LoadJobs_BayId_Completed         ON slb.LoadJobs;
DROP INDEX IF EXISTS IX_LoadJobs_StartedAt_Analytics     ON slb.LoadJobs;
DROP INDEX IF EXISTS IX_LoadJobs_CompletedAt_Analytics   ON slb.LoadJobs;
*/
