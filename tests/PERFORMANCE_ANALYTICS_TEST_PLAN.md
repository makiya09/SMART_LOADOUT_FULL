# PERFORMANCE ANALYTICS — TEST PLAN (ฉบับละเอียด)

**เขียนโดย:** Captain America (QA/Testing Agent)  
**วันที่:** 2026-05-14  
**Version:** 1.0  
**อ้างอิง:** docs/PERFORMANCE_ANALYTICS_PLAN.md V2.0, docs/DATABASE_DESIGN.md, docs/FLOW_PROCESS.md V2.0

---

## ส่วนที่ 1: Analytics Test Scope

### 1.1 Dashboard ที่ต้อง Test (6 Dashboard)

| # | Dashboard | URL Route | SP หลักที่ใช้ | Priority |
|---|-----------|-----------|--------------|----------|
| D1 | Performance Overview | `/analytics` | SP01, SP08 | P1 |
| D2 | Loss / Yield Analysis | `/analytics/loss-yield` | SP02 | P1 |
| D3 | Bay Performance | `/analytics/bay` | SP03, SP07 | P1 |
| D4 | Truck Turnaround | `/analytics/turnaround` | SP04 | P2 |
| D5 | Product Loss Analysis | `/analytics/product` | SP05 | P2 |
| D6 | Truck Problem Report | `/analytics/truck-problem` | SP06 | P2 |

### 1.2 Stored Procedures ที่ต้อง Test (11 SPs)

| SP Code | ชื่อ SP | Parameters | Dashboard |
|---------|---------|-----------|-----------|
| SP01 | `ana.sp_GetPerformanceDashboard` | @DateFrom, @DateTo, @BayId(opt) | D1 |
| SP02 | `ana.sp_GetLossYieldDashboard` | @DateFrom, @DateTo, @ProductId(opt) | D2 |
| SP03 | `ana.sp_GetBayPerformanceDashboard` | @DateFrom, @DateTo | D3 |
| SP04 | `ana.sp_GetTurnaroundDashboard` | @DateFrom, @DateTo, @TruckId(opt) | D4 |
| SP05 | `ana.sp_GetProductLossAnalysis` | @DateFrom, @DateTo, @Top(default 10) | D5 |
| SP06 | `ana.sp_GetTruckProblemReport` | @DateFrom, @DateTo, @MinIncidents(default 2) | D6 |
| SP07 | `ana.sp_GetHourlyThroughput` | @Date, @BayId(opt) | D3 |
| SP08 | `ana.sp_GetShiftPerformance` | @DateFrom, @DateTo | D1 |
| SP09 | `ana.sp_GetKpiAlertHistory` | @DateFrom, @DateTo, @Severity(opt) | Alert Log |
| SP10 | `ana.sp_GetAnalyticsConfig` | (ไม่มี) | Settings |
| SP11 | `ana.sp_UpdateAnalyticsConfig` | @ConfigKey, @ConfigValue, @UpdatedBy | Settings |

### 1.3 Views ที่ต้อง Test (10 Views)

| V Code | ชื่อ View | คำอธิบาย | SP ที่ใช้ |
|--------|----------|---------|---------|
| V01 | `ana.vw_JobPerformance` | KPI ต่อ Job (Yield, Loss, Duration) | SP01, SP02 |
| V02 | `ana.vw_QueuePerformance` | Queue Waiting Time ต่อ Queue | SP04 |
| V03 | `ana.vw_DailyPerformance` | Aggregate รายวัน | SP01, SP08 |
| V04 | `ana.vw_BayPerformance` | KPI รายวัน ต่อ Bay | SP03 |
| V05 | `ana.vw_ProductLossYield` | Loss/Yield ต่อ Product ต่อวัน | SP02, SP05 |
| V06 | `ana.vw_TruckTurnaround` | Turnaround Time ต่อ Job | SP04 |
| V07 | `ana.vw_HourlyThroughput` | Throughput ต่อชั่วโมง ต่อ Bay | SP07 |
| V08 | `ana.vw_TruckProblemHistory` | ประวัติปัญหาต่อรถ | SP06 |
| V09 | `ana.vw_FormulaLossAnalysis` | Loss Analysis ต่อ Product × Bay | SP05 |
| V10 | `ana.vw_ShiftPerformance` | ประสิทธิภาพแยก Shift | SP08 |

---

## ส่วนที่ 2: SP Test Cases (PAT-001 ถึง PAT-011)

---

### PAT-001: `ana.sp_GetPerformanceDashboard`

**Parameters:** `@DateFrom DATE, @DateTo DATE, @BayId UNIQUEIDENTIFIER = NULL`  
**Returns:** 3 Result Sets (Summary KPIs, Daily Trend, Bay Summary)

#### Scenario 1: ข้อมูลปกติ (ช่วงที่มีข้อมูล)

```sql
-- Test Script
EXEC ana.sp_GetPerformanceDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'
```

| Result Set | Expected Columns | Expected Condition |
|-----------|-----------------|-------------------|
| #1 Summary | TotalJobs, CompletedJobs, CancelledJobs, EmergencyJobs, OverallYieldPct, TotalLossKg, AvgAccuracyPct, OverallAvgLoadingMin | TotalJobs ≥ 1, OverallYieldPct ระหว่าง 0-110 |
| #2 Daily Trend | WorkDate, TotalJobs, CompletedJobs, TotalActualTon, OverallYieldPct | วันละ 1 Row, เรียงตาม WorkDate |
| #3 Bay Summary | BayId, BayName, TotalJobs, TotalActualTon, AvgLoadingMin | Row ต่อ Bay |

#### Scenario 2: Edge Cases

```sql
-- Edge Case A: วันเดียว
EXEC ana.sp_GetPerformanceDashboard
  @DateFrom = '2026-05-14',
  @DateTo   = '2026-05-14'
-- Expected: Result Set #2 มีแค่ 1 Row (วันที่ 14)

-- Edge Case B: ช่วงที่ไม่มีข้อมูล
EXEC ana.sp_GetPerformanceDashboard
  @DateFrom = '2030-01-01',
  @DateTo   = '2030-01-31'
-- Expected: #1 TotalJobs = 0, OverallYieldPct = NULL, #2 ว่าง, #3 ว่าง

-- Edge Case C: ข้ามปี
EXEC ana.sp_GetPerformanceDashboard
  @DateFrom = '2025-12-15',
  @DateTo   = '2026-01-15'
-- Expected: ข้อมูลครอบคลุมทั้ง 2 ปี ไม่มี Error

-- Edge Case D: Filter เฉพาะ Bay
EXEC ana.sp_GetPerformanceDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14',
  @BayId    = '{valid-bay-id}'
-- Expected: #3 มีเฉพาะ Bay ที่ระบุ
```

**Verification SQL:**
```sql
-- ตรวจค่า TotalJobs ด้วยมือ
SELECT COUNT(*) AS TotalJobs_Manual
FROM slb.LoadJobs
WHERE StartedAt BETWEEN '2026-05-01' AND '2026-05-14 23:59:59'
-- ต้องตรงกับ SP Result #1 TotalJobs
```

---

### PAT-002: `ana.sp_GetLossYieldDashboard`

**Parameters:** `@DateFrom DATE, @DateTo DATE, @ProductId UNIQUEIDENTIFIER = NULL`  
**Returns:** 3 Result Sets (Summary, Daily Trend, Job Detail)

#### Scenario 1: ข้อมูลปกติ

```sql
EXEC ana.sp_GetLossYieldDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'
```

| Result Set | Expected Columns | Expected Values |
|-----------|-----------------|----------------|
| #1 Summary | OverallYieldPct, TotalLossKg, TotalOverKg, AvgDiffPct, AccuracyPct, LossJobCount, OverJobCount | YieldPct อยู่ระหว่าง 90–110% |
| #2 Daily Trend | WorkDate, AvgYieldPct, TotalLossKg, TotalOverKg | เรียงตาม WorkDate |
| #3 Job Detail | JobId, BayName, LicensePlate, ProductName, TargetWeight, ActualWeight, LossKg, YieldPct | Sort by LossKg DESC |

#### Scenario 2: Edge Cases

```sql
-- Edge Case A: Filter เฉพาะ Product ที่ไม่มีข้อมูล
EXEC ana.sp_GetLossYieldDashboard
  @DateFrom  = '2026-05-01',
  @DateTo    = '2026-05-14',
  @ProductId = '{product-with-no-jobs}'
-- Expected: ทุก KPI = 0 หรือ NULL ไม่ Error

-- Edge Case B: วันเดียวที่มีแค่ Job เดียว
-- Expected: YieldPct = Yield ของ Job นั้น, StdDev ไม่ Error (NULL หรือ 0)

-- Edge Case C: ทุก Job มี Yield = 100% พอดี
-- Expected: TotalLossKg = 0, TotalOverKg = 0, LossJobCount = 0
```

**Verification SQL:**
```sql
-- ตรวจ Loss ด้วยมือ
SELECT
  SUM(CASE WHEN ActualWeight < TargetWeight
       THEN TargetWeight - ActualWeight ELSE 0 END) AS ManualTotalLossKg,
  SUM(CASE WHEN ActualWeight > TargetWeight
       THEN ActualWeight - TargetWeight ELSE 0 END) AS ManualTotalOverKg,
  SUM(ActualWeight) / NULLIF(SUM(TargetWeight),0) * 100.0 AS ManualYieldPct
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt >= '2026-05-01' AND CompletedAt < '2026-05-15'
```

---

### PAT-003: `ana.sp_GetBayPerformanceDashboard`

**Parameters:** `@DateFrom DATE, @DateTo DATE`  
**Returns:** 2 Result Sets (Bay Summary, Bay Daily Trend)

#### Scenario 1: ข้อมูลปกติ

```sql
EXEC ana.sp_GetBayPerformanceDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'
```

| Result Set | Expected Columns | Expected Values |
|-----------|-----------------|----------------|
| #1 Bay Summary | BayId, BayName, TotalJobs, TotalActualTon, AvgLoadingMin, AvgYieldPct, BayUtilizationPct, ThroughputTonPerHour | Row ต่อ Bay |
| #2 Daily Trend | WorkDate, BayName, TotalJobs, TotalActualTon, BayYieldPct | Row ต่อวัน ต่อ Bay |

#### Scenario 2: Edge Cases

```sql
-- Edge Case A: Bay ที่ไม่มี Job เลย
-- Expected: Bay นั้นไม่ปรากฏใน Result (หรือปรากฏพร้อม TotalJobs = 0)

-- Edge Case B: วันเดียว
EXEC ana.sp_GetBayPerformanceDashboard
  @DateFrom = '2026-05-14',
  @DateTo   = '2026-05-14'
-- Expected: BayUtilizationPct = TotalLoadingMin / (HoursPerDay × 60) × 100

-- Edge Case C: WORKING_HOURS_PER_DAY = 0 (Config ผิดพลาด)
-- Expected: ไม่ Divide by Zero Error (ใช้ NULLIF)
```

**Verification SQL:**
```sql
-- ตรวจ BayUtilization ด้วยมือ
DECLARE @WorkingMinutes INT = (
  SELECT CAST(ConfigValue AS INT) * 60
  FROM ana.AnalyticsConfig
  WHERE ConfigKey = 'WORKING_HOURS_PER_DAY'
)

SELECT
  b.BayName,
  SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) AS TotalLoadingMin,
  @WorkingMinutes AS CapacityMin,
  SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) * 100.0
    / NULLIF(@WorkingMinutes, 0) AS ManualBayUtilPct
FROM slb.LoadJobs lj
JOIN slb.Bays b ON lj.BayId = b.BayId
WHERE lj.Status = 'COMPLETED'
  AND CAST(lj.StartedAt AS DATE) = '2026-05-14'
GROUP BY b.BayId, b.BayName
```

---

### PAT-004: `ana.sp_GetTurnaroundDashboard`

**Parameters:** `@DateFrom DATE, @DateTo DATE, @TruckId UNIQUEIDENTIFIER = NULL`  
**Returns:** 2 Result Sets (Summary, Job Detail)

#### Scenario 1: ข้อมูลปกติ

```sql
EXEC ana.sp_GetTurnaroundDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'
```

| Result Set | Expected Columns | Expected Values |
|-----------|-----------------|----------------|
| #1 Summary | AvgTurnaroundMin, MinTurnaroundMin, MaxTurnaroundMin, AvgQueueWaitMin, AvgLoadingMin, AvgChecklistMin, JobsOver120 | AvgTurnaroundMin > 0 |
| #2 Job Detail | LicensePlate, BayName, QueueWaitMin, DockingMin, LoadingMin, ChecklistMin, TurnaroundMin | Sort by TurnaroundMin DESC |

#### Scenario 2: Edge Cases

```sql
-- Edge Case A: Job ที่ไม่มี BayLog TRUCK_DEPARTED
-- Expected: ChecklistMin ใช้ค่า Default (CompletedAt + 10 นาที) ตาม View

-- Edge Case B: Filter เฉพาะรถ
EXEC ana.sp_GetTurnaroundDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14',
  @TruckId  = '{truck-id}'
-- Expected: เฉพาะ Job ของรถคันนั้น

-- Edge Case C: DateFrom = DateTo ที่ไม่มีข้อมูล
-- Expected: JobsOver120 = 0, AvgTurnaroundMin = NULL ไม่ Error
```

**Verification SQL:**
```sql
-- ตรวจ Turnaround ด้วยมือ
SELECT TOP 10
  t.LicensePlate,
  lq.CalledAt,
  lj.StartedAt,
  lj.CompletedAt,
  DATEDIFF(MINUTE, lq.CalledAt, lj.CompletedAt) AS ManualTurnaroundMin
FROM slb.LoadJobs lj
JOIN slb.LoadQueues lq ON lj.QueueId = lq.QueueId
JOIN slb.Trucks t ON lj.TruckId = t.TruckId
WHERE lj.Status = 'COMPLETED'
  AND lq.CalledAt IS NOT NULL
  AND CAST(lj.StartedAt AS DATE) >= '2026-05-01'
ORDER BY ManualTurnaroundMin DESC
```

---

### PAT-005: `ana.sp_GetProductLossAnalysis`

**Parameters:** `@DateFrom DATE, @DateTo DATE, @Top INT = 10`  
**Returns:** 2 Result Sets (Product Loss Rank, Product Daily Trend)

#### Scenario 1: ข้อมูลปกติ

```sql
EXEC ana.sp_GetProductLossAnalysis
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14',
  @Top      = 10
```

| Result Set | Expected Columns | Expected Values |
|-----------|-----------------|----------------|
| #1 Loss Rank | ProductName, ProductCode, TotalJobs, AvgYieldPct, YieldStdDev, TotalLossKg, AvgLossRatePct | Sort by TotalLossKg DESC, TOP 10 |
| #2 Daily Trend | WorkDate, ProductName, AvgYieldPct, TotalLossKg | เรียงตาม WorkDate, ProductName |

#### Scenario 2: Edge Cases

```sql
-- Edge Case A: @Top = 1 (แค่ Top 1 Product)
EXEC ana.sp_GetProductLossAnalysis
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14',
  @Top      = 1
-- Expected: #1 มีแค่ 1 Row (Product ที่ Loss สูงสุด)

-- Edge Case B: ทุก Product มี Yield = 100% พอดี
-- Expected: TotalLossKg = 0 สำหรับทุก Product

-- Edge Case C: มีแค่ 1 Job ต่อ Product
-- Expected: YieldStdDev = NULL (ไม่สามารถคำนวณ StdDev ด้วย 1 จุดได้)
```

---

### PAT-006: `ana.sp_GetTruckProblemReport`

**Parameters:** `@DateFrom DATE, @DateTo DATE, @MinIncidents INT = 2`  
**Returns:** 2 Result Sets (Problem Summary, Incident Timeline)

#### Scenario 1: ข้อมูลปกติ

```sql
EXEC ana.sp_GetTruckProblemReport
  @DateFrom    = '2026-05-01',
  @DateTo      = '2026-05-14',
  @MinIncidents= 2
```

| Result Set | Expected Columns | Expected Values |
|-----------|-----------------|----------------|
| #1 Problem Summary | LicensePlate, TransportCompany, TotalIncidents, EmergencyCount, HighLossCount, HighOverCount, SlowLoadCount | เฉพาะรถที่มี Incidents ≥ @MinIncidents |
| #2 Incident Timeline | LicensePlate, JobId, IncidentDate, IncidentType, YieldPct, BayName | ทุก Incident ไม่ filter |

#### Scenario 2: Edge Cases

```sql
-- Edge Case A: @MinIncidents = 1 (แสดงทุกรถที่มีปัญหา)
EXEC ana.sp_GetTruckProblemReport
  @DateFrom    = '2026-05-01',
  @DateTo      = '2026-05-14',
  @MinIncidents= 1

-- Edge Case B: ไม่มีรถที่มีปัญหา
-- Expected: #1 ว่าง, #2 มีข้อมูล Timeline

-- Edge Case C: รถที่มี Emergency ครั้งเดียวกับ High Loss
-- Expected: TotalIncidents = 2 (Emergency + HighLoss นับแยก)
```

---

### PAT-007: `ana.sp_GetHourlyThroughput`

**Parameters:** `@Date DATE, @BayId UNIQUEIDENTIFIER = NULL`  
**Returns:** 1 Result Set (Hourly Throughput per Bay)

#### Scenario 1: ข้อมูลปกติ

```sql
EXEC ana.sp_GetHourlyThroughput
  @Date  = '2026-05-14'
```

| Result Set | Expected Columns | Expected Values |
|-----------|-----------------|----------------|
| #1 | WorkHour, BayName, JobCount, TotalActualTon, AvgLoadingMin | Row ต่อ Hour × Bay |

#### Scenario 2: Edge Cases

```sql
-- Edge Case A: ชั่วโมงที่ไม่มี Job (เช่น ช่วงพักกลางคืน)
-- Expected: Hour นั้นไม่ปรากฏใน Result

-- Edge Case B: Filter เฉพาะ Bay
EXEC ana.sp_GetHourlyThroughput
  @Date  = '2026-05-14',
  @BayId = '{bay-id}'
-- Expected: เฉพาะ Bay ที่ระบุ

-- Edge Case C: วันหยุด/วันที่ไม่มีงาน
-- Expected: Result ว่าง ไม่ Error
```

---

### PAT-008: `ana.sp_GetShiftPerformance`

**Parameters:** `@DateFrom DATE, @DateTo DATE`  
**Returns:** 1 Result Set (Performance แยก Shift × Day)

```sql
EXEC ana.sp_GetShiftPerformance
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'
```

| Result Set | Expected Columns | Expected Values |
|-----------|-----------------|----------------|
| #1 | WorkDate, ShiftName, TotalJobs, TotalActualTon, AvgYieldPct, AvgLoadingMin, EmergencyCount | ShiftName IN ('SHIFT1','SHIFT2','SHIFT3') |

#### Edge Cases:

```sql
-- Job ที่เริ่ม 13:45 → SHIFT1 (Hour 13 ≤ 13) หรือ SHIFT2?
-- ตรวจ Logic: BETWEEN 6 AND 13 = SHIFT1, BETWEEN 14 AND 21 = SHIFT2
-- Hour 13 = SHIFT1 ✓, Hour 14 = SHIFT2 ✓

-- Boundary Test: Job StartedAt = '2026-05-14 13:59:59'
-- Expected: ShiftName = 'SHIFT1' (DATEPART(HOUR,...) = 13)
```

---

### PAT-009: `ana.sp_GetKpiAlertHistory`

**Parameters:** `@DateFrom DATE, @DateTo DATE, @Severity VARCHAR(10) = NULL`  
**Returns:** 1 Result Set (Alert History)

```sql
EXEC ana.sp_GetKpiAlertHistory
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'

-- Filter เฉพาะ CRITICAL
EXEC ana.sp_GetKpiAlertHistory
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14',
  @Severity = 'CRITICAL'
```

| Expected Columns | Expected Values |
|-----------------|----------------|
| AlertId, AlertType, KpiCode, KpiValue, Threshold, Severity, CreatedAt | Severity IN ('WARNING','CRITICAL') |

---

### PAT-010: `ana.sp_GetAnalyticsConfig`

**Parameters:** (ไม่มี)  
**Returns:** 1 Result Set (ทุก Config Row)

```sql
EXEC ana.sp_GetAnalyticsConfig
```

**Expected:**
- ได้ผลลัพธ์ ≥ 19 rows (จาก Seed Data ที่กำหนด)
- Columns: ConfigKey, ConfigValue, Description, Unit, UpdatedAt
- `YIELD_NORMAL_MIN` = '99.5'
- `WORKING_HOURS_PER_DAY` = '16'
- `PROBLEM_TRUCK_MIN_INCIDENTS` = '2'

**Verification SQL:**
```sql
-- ตรวจว่า Config ครบ
SELECT COUNT(*) AS TotalConfigs FROM ana.AnalyticsConfig
-- Expected: ≥ 19

SELECT ConfigKey, ConfigValue
FROM ana.AnalyticsConfig
WHERE ConfigKey IN (
  'YIELD_NORMAL_MIN','YIELD_NORMAL_MAX','YIELD_WARNING_MIN',
  'LOADING_TIME_NORMAL_MAX','WORKING_HOURS_PER_DAY'
)
ORDER BY ConfigKey
```

---

### PAT-011: `ana.sp_UpdateAnalyticsConfig`

**Parameters:** `@ConfigKey VARCHAR(50), @ConfigValue VARCHAR(50), @UpdatedBy UNIQUEIDENTIFIER`  
**Returns:** ไม่มี (UPDATE)

```sql
-- Test: อัปเดต YIELD_WARNING_MIN จาก 98.0 เป็น 97.5
EXEC ana.sp_UpdateAnalyticsConfig
  @ConfigKey   = 'YIELD_WARNING_MIN',
  @ConfigValue = '97.5',
  @UpdatedBy   = '{admin-user-id}'

-- ตรวจผลลัพธ์
SELECT ConfigKey, ConfigValue, UpdatedAt
FROM ana.AnalyticsConfig
WHERE ConfigKey = 'YIELD_WARNING_MIN'
-- Expected: ConfigValue = '97.5', UpdatedAt = now
```

**Edge Cases:**
```sql
-- อัปเดต ConfigKey ที่ไม่มีอยู่
EXEC ana.sp_UpdateAnalyticsConfig
  @ConfigKey   = 'KEY_DOES_NOT_EXIST',
  @ConfigValue = '999',
  @UpdatedBy   = '{admin-user-id}'
-- Expected: ไม่ Error, แต่ไม่มีการเปลี่ยนแปลงใน DB (0 rows affected)

-- อัปเดต ConfigValue เป็น String ที่ไม่ใช่ตัวเลข (ถ้า Validate)
EXEC ana.sp_UpdateAnalyticsConfig
  @ConfigKey   = 'YIELD_NORMAL_MIN',
  @ConfigValue = 'abc',
  @UpdatedBy   = '{admin-user-id}'
-- Expected: Error หรือ Validation ไม่ให้บันทึก (ขึ้นอยู่กับ Implementation)
```

---

## ส่วนที่ 3: KPI Calculation Validation

ตารางสูตรคำนวณ KPI ทั้งหมดพร้อมวิธี Verify:

| KPI | สูตรคำนวณ | วิธี Test | Threshold (NORMAL) |
|-----|----------|----------|-------------------|
| **YieldPct** | `(ActualWeight / TargetWeight) × 100` | Job Target=25000, Actual=24925 → Yield=99.7% | 99.5%–100.5% |
| **LossKg** | `TargetWeight - ActualWeight` (เมื่อ Actual < Target) | Actual=24000, Target=25000 → Loss=1000 kg | 0 คือดีที่สุด |
| **OverKg** | `ActualWeight - TargetWeight` (เมื่อ Actual > Target) | Actual=25500, Target=25000 → Over=500 kg | 0 คือดีที่สุด |
| **CompletionRate** | `(CompletedJobs / TotalJobs) × 100` | 8 Complete, 2 Cancel → 80.0% | ≥ 95% |
| **ThroughputTonPerHour** | `(ActualWeight kg / 1000) / (LoadingMin / 60)` | 25000 kg, 30 min → 50.0 t/hr | ≥ 20 t/hr |
| **AvgLoadingMinutes** | `AVG(DATEDIFF(minute, StartedAt, CompletedAt))` | [30, 45, 35] → avg = 36.7 min | ≤ 45 min |
| **AvgWaitingMinutes** | `AVG(DATEDIFF(minute, EnqueuedAt, CalledAt))` | [20, 30, 10] → avg = 20.0 min | ≤ 20 min |
| **BayUtilizationPct** | `(TotalLoadingMin / (HoursPerDay × 60)) × 100` | 480 min / 960 min → 50.0% | 70%–85% |
| **LoadingAccuracyPct** | `(Jobs ที่ \|Diff%\| ≤ 0.5 / TotalJobs) × 100` | 8/10 accurate → 80.0% | ≥ 90% |
| **AvgTurnaroundMin** | `AVG(DepartureTime - CalledAt)` in minutes | [60, 90, 75] → avg = 75 min | ≤ 90 min |
| **YieldStdDev** | `STDEV(YieldPct per Job)` | ยิ่งต่ำยิ่งดี (คงที่) | < 1.0 |
| **ProblemTruckRatePct** | `(รถที่มี Incident ≥ 2 / รถทั้งหมด) × 100` | 2 prob / 20 trucks → 10% | < 10% |

### 3.1 Manual Calculation Test Cases

#### KPI Calculation Test #1 — Yield%

**Setup Data:**
```sql
-- Job ทดสอบ
INSERT INTO slb.LoadJobs (JobCode, TargetWeight, ActualWeight, Status, StartedAt, CompletedAt)
VALUES ('CALC-TEST-001', 25000, 24925, 'COMPLETED', '2026-05-14 08:00:00', '2026-05-14 08:30:00')
```

**Expected Calculations:**
```
YieldPct = 24925 / 25000 × 100 = 99.70%
LossKg   = 25000 - 24925      = 75 kg
OverKg   = 0
DiffPct  = (24925-25000)/25000 × 100 = -0.30%
Throughput = 24.925 ton / (30/60 hr) = 49.85 t/hr
```

**Verify SQL:**
```sql
SELECT
  JobCode,
  TargetWeight,
  ActualWeight,
  YieldPct,
  LossKg,
  OverKg,
  DiffPct,
  ThroughputTonPerHour
FROM ana.vw_JobPerformance
WHERE JobCode = 'CALC-TEST-001'
```

#### KPI Calculation Test #2 — BayUtilization%

**Setup:**
- WORKING_HOURS_PER_DAY = 16 (CapacityMin = 960)
- Bay A มี Jobs วันนี้: [30 min, 45 min, 35 min, 40 min] = 150 min รวม

**Expected:**
```
BayUtilizationPct = 150 / 960 × 100 = 15.63%
Status = LOW (< 50%)
```

**Verify SQL:**
```sql
SELECT
  BayName,
  TotalLoadingMin,
  BayYieldPct,
  ThroughputTonPerHour
FROM ana.vw_BayPerformance
WHERE WorkDate = '2026-05-14'
  AND BayName = 'BAY-01'
```

---

## ส่วนที่ 4: View Verification Queries

SQL Script สำหรับตรวจสอบ 10 Views:

```sql
-- ============================================================
-- VIEW VERIFICATION SCRIPT
-- รัน Script นี้ใน SSMS เพื่อตรวจสอบ Views ทั้ง 10
-- ============================================================

-- V01: vw_JobPerformance — ตรวจ Column และ Calculation
SELECT TOP 5
  JobId, BayName, LicensePlate, ProductName,
  TargetWeight, ActualWeight, YieldPct, LossKg, OverKg,
  LoadingDurationMin, ThroughputTonPerHour, ShiftName
FROM ana.vw_JobPerformance
WHERE WorkDate >= '2026-05-01'
ORDER BY WorkDate DESC, YieldPct ASC
-- Expected: ไม่มี NULL ใน YieldPct (ถ้า TargetWeight > 0), ShiftName ต้องเป็น SHIFT1/SHIFT2/SHIFT3

-- V02: vw_QueuePerformance — ตรวจ Waiting Time
SELECT TOP 5
  QueueId, QueueNumber, Priority, Status,
  QueueWaitingMin, TotalSystemTimeMin, QueueDate
FROM ana.vw_QueuePerformance
WHERE QueueDate >= '2026-05-01'
ORDER BY QueueWaitingMin DESC
-- Expected: QueueWaitingMin ≥ 0 ทุก Row

-- V03: vw_DailyPerformance — ตรวจ Daily Aggregate
SELECT TOP 5 *
FROM ana.vw_DailyPerformance
ORDER BY WorkDate DESC
-- Expected: TotalJobs = CompletedJobs + CancelledJobs + EmergencyJobs + (อื่นๆ)
-- Expected: OverallYieldPct คำนวณจาก SUM(Actual)/SUM(Target)

-- V04: vw_BayPerformance — ตรวจ Bay KPIs
SELECT TOP 5 *
FROM ana.vw_BayPerformance
WHERE WorkDate >= '2026-05-01'
ORDER BY WorkDate DESC, BayName
-- Expected: ThroughputTonPerHour = TotalActualTon / (TotalLoadingMin/60)

-- V05: vw_ProductLossYield — ตรวจ Product-level Loss
SELECT TOP 5
  WorkDate, ProductName, TotalJobs,
  YieldPct, TotalLossKg, TotalOverKg, YieldStdDev
FROM ana.vw_ProductLossYield
ORDER BY WorkDate DESC, TotalLossKg DESC
-- Expected: TotalLossKg ≥ 0 ทุก Row

-- V06: vw_TruckTurnaround — ตรวจ Time Segments
SELECT TOP 5
  WorkDate, LicensePlate, BayName,
  QueueWaitMin, DockingMin, LoadingMin, ChecklistMin, TurnaroundMin
FROM ana.vw_TruckTurnaround
ORDER BY WorkDate DESC, TurnaroundMin DESC
-- Expected: TurnaroundMin = QueueWaitMin + DockingMin + LoadingMin + ChecklistMin (approx)

-- V07: vw_HourlyThroughput — ตรวจ Hourly Data
SELECT TOP 10
  WorkDate, WorkHour, BayName, JobCount,
  TotalActualTon, AvgLoadingMin
FROM ana.vw_HourlyThroughput
WHERE WorkDate >= '2026-05-01'
ORDER BY WorkDate DESC, WorkHour, BayName
-- Expected: WorkHour อยู่ระหว่าง 0-23

-- V08: vw_TruckProblemHistory — ตรวจ Incident Records
SELECT TOP 10
  LicensePlate, TransportCompany, IncidentDate,
  IncidentType, YieldPct, BayName
FROM ana.vw_TruckProblemHistory
ORDER BY IncidentDate DESC
-- Expected: IncidentType IN ('EMERGENCY','HIGH_LOSS','HIGH_OVER','SLOW_LOADING','OTHER')

-- V09: vw_FormulaLossAnalysis — ตรวจ Product × Bay Loss
SELECT TOP 10
  WorkDate, ProductName, BayName, JobCount,
  AvgYieldPct, YieldStdDev, TotalLossKg,
  MinYieldPct, MaxYieldPct
FROM ana.vw_FormulaLossAnalysis
ORDER BY WorkDate DESC, TotalLossKg DESC
-- Expected: MinYieldPct ≤ AvgYieldPct ≤ MaxYieldPct

-- V10: vw_ShiftPerformance — ตรวจ Shift Data
SELECT TOP 10
  WorkDate, ShiftName, TotalJobs, TotalActualTon,
  AvgYieldPct, AvgLoadingMin, EmergencyCount
FROM ana.vw_ShiftPerformance
ORDER BY WorkDate DESC, ShiftName
-- Expected: ShiftName IN ('SHIFT1','SHIFT2','SHIFT3')
-- Expected: TotalJobs ≥ EmergencyCount
```

---

## ส่วนที่ 5: Test Data Reference

### 5.1 Test Jobs จาก db/003 Section 6

| JobCode | กลุ่ม | TargetWeight | ActualWeight | Yield% | Expected Status |
|---------|-------|-------------|-------------|--------|----------------|
| ANA-TEST-001 | Normal | 25,000 kg | 24,925 kg | 99.70% | NORMAL (Green) |
| ANA-TEST-002 | Normal | 20,000 kg | 20,040 kg | 100.20% | NORMAL (Green) |
| ANA-TEST-003 | Normal | 30,000 kg | 29,955 kg | 99.85% | NORMAL (Green) |
| ANA-TEST-004 | Warning | 25,000 kg | 24,550 kg | 98.20% | WARNING (Amber) |
| ANA-TEST-005 | Warning | 20,000 kg | 19,760 kg | 98.80% | WARNING (Amber) |
| ANA-TEST-006 | Critical | 25,000 kg | 24,125 kg | 96.50% | CRITICAL (Red) |
| ANA-TEST-007 | Critical | 30,000 kg | 29,190 kg | 97.30% | CRITICAL (Red) |
| ANA-TEST-008 | Failed | 25,000 kg | NULL | — | EMERGENCY_STOPPED |
| ANA-TEST-009 | Failed | 20,000 kg | NULL | — | CANCELLED |
| ANA-TEST-010 | Over | 25,000 kg | 25,550 kg | 102.20% | WARNING Over |
| ANA-TEST-011 | Over Critical | 25,000 kg | 25,850 kg | 103.40% | CRITICAL Over |
| ANA-TEST-012 | Normal | 15,000 kg | 15,010 kg | 100.07% | NORMAL (Green) |

### 5.2 Expected Analytics Results จาก Seed Data

**หลังรัน SP01 (Performance Dashboard) สำหรับวันที่มี Seed Data:**
```
TotalJobs       = 12
CompletedJobs   = 10 (ANA-TEST-001 ถึง 007, 010 ถึง 012)
EmergencyJobs   = 1  (ANA-TEST-008)
CancelledJobs   = 1  (ANA-TEST-009)
TotalLossKg     = 75 + 450 + 240 + 875 + 810 = 2,450 kg (approx)
TotalOverKg     = 40 + 550 + 850 = 1,440 kg (approx)
OverallYieldPct = SUM(Actual) / SUM(Target) × 100
```

**Loss Alert ที่คาดหวัง:**
```
ANA-TEST-006: Yield 96.50% < 97% (YIELD_CRITICAL_MIN) → CRITICAL Alert
ANA-TEST-007: Yield 97.30% < 98% (YIELD_WARNING_MIN) → WARNING Alert
ANA-TEST-004: Yield 98.20% < 99.5% → WARNING Alert
ANA-TEST-011: Yield 103.40% > 103% (YIELD_CRITICAL_MAX) → CRITICAL Over Alert
```

### 5.3 SQL ตรวจ Seed Data ครบ

```sql
-- ตรวจ Seed Jobs ครบ 12 รายการ
SELECT JobCode, Status, TargetWeight, ActualWeight,
  CASE WHEN TargetWeight > 0
       THEN ActualWeight / TargetWeight * 100.0
       ELSE NULL END AS YieldPct
FROM slb.LoadJobs
WHERE JobCode LIKE 'ANA-TEST-%'
ORDER BY JobCode

-- Expected: 12 rows

-- ตรวจ NotificationLog ที่เกิดจาก Seed Data
SELECT nl.NotificationType, nl.Severity, nl.Message, nl.CreatedAt
FROM slb.NotificationLogs nl
WHERE nl.Message LIKE '%ANA-TEST-%'
ORDER BY nl.CreatedAt DESC
-- Expected: Alert สำหรับ 006, 007, 004, 011
```

---

## ส่วนที่ 6: AnalyticsConfig Threshold Test

ตรวจสอบว่า Threshold แต่ละตัวถูกต้องและ Alert Logic ทำงานตาม Config:

| ConfigKey | Default Value | Warning Trigger | Critical Trigger | ทดสอบโดย |
|-----------|-------------|----------------|-----------------|---------|
| YIELD_NORMAL_MIN | 99.5% | Yield < 99.5% → WARNING | Yield < YIELD_WARNING_MIN → escalate | Job ANA-TEST-004 |
| YIELD_NORMAL_MAX | 100.5% | Yield > 100.5% → WARNING | Yield > YIELD_WARNING_MAX → escalate | Job ANA-TEST-010 |
| YIELD_WARNING_MIN | 98.0% | — | Yield < 98.0% → CRITICAL | Job ANA-TEST-006 |
| YIELD_WARNING_MAX | 102.0% | — | Yield > 102.0% → CRITICAL | Job ANA-TEST-011 |
| YIELD_CRITICAL_MIN | 97.0% | — | Yield < 97.0% → Severe Alert | ต้องสร้าง Job Yield 96% |
| LOADING_TIME_NORMAL_MAX | 45 นาที | > 45 min = SLOW | > 60 min = WARNING, > 90 min = CRITICAL | Manual Test |
| LOADING_TIME_CRITICAL_MIN | 90 นาที | — | > 90 min = CRITICAL | Manual Test |
| QUEUE_WAIT_OK_MAX | 20 นาที | > 20 min = ACCEPTABLE | > 30 min = WARNING, > 60 min = CRITICAL | Manual Test |
| TURNAROUND_NORMAL_MAX | 90 นาที | > 90 min = SLOW | > 120 min = WARNING | Manual Test |
| BAY_UTIL_LOW_MAX | 50% | Util < 50% = LOW | — | PAT-003 |
| BAY_UTIL_GOOD_MIN | 70% | — | — | PAT-003 |
| WORKING_HOURS_PER_DAY | 16 ชม | — | — | PAT-003 Util Calc |
| PROBLEM_TRUCK_MIN_INCIDENTS | 2 ครั้ง | — | ≥ 2 → Problem Truck Flag | PAT-006 |

### 6.1 Config Update Test (PAT-011 ต่อ)

```sql
-- Test: เปลี่ยน Threshold แล้วตรวจว่า Alert Logic เปลี่ยนตาม

-- Step 1: อ่าน Config ปัจจุบัน
EXEC ana.sp_GetAnalyticsConfig
-- บันทึกค่า YIELD_WARNING_MIN = 98.0

-- Step 2: เปลี่ยน Threshold
EXEC ana.sp_UpdateAnalyticsConfig
  @ConfigKey   = 'YIELD_WARNING_MIN',
  @ConfigValue = '99.0',
  @UpdatedBy   = '{admin-guid}'

-- Step 3: ตรวจว่า Job ANA-TEST-004 (Yield 98.2%) กลายเป็น CRITICAL
-- (เพราะ 98.2% < 99.0% = new WARNING_MIN ซึ่งหมายถึง CRITICAL ใหม่)

-- Step 4: คืนค่าเดิม
EXEC ana.sp_UpdateAnalyticsConfig
  @ConfigKey   = 'YIELD_WARNING_MIN',
  @ConfigValue = '98.0',
  @UpdatedBy   = '{admin-guid}'
```

---

## ส่วนที่ 7: วิธีรัน Analytics Tests

### 7.1 Setup ลำดับการรัน SQL Scripts

```sql
-- รัน ตามลำดับ:
-- 1. สร้าง Database และ Tables (ถ้ายังไม่มี)
-- db/001_create_database.sql
-- db/002_create_tables.sql

-- 2. สร้าง Analytics Objects
-- db/003_create_analytics_objects.sql
--   Section 1: สร้าง Schema ana
--   Section 2: สร้าง Table AnalyticsConfig
--   Section 3: Seed Config Data (27 rows)
--   Section 4: สร้าง Views V01–V10
--   Section 5: สร้าง Stored Procedures SP01–SP11
--   Section 6: Seed Test Jobs (ANA-TEST-001 ถึง ANA-TEST-012)
--   Section 7: Quick Verify Script

-- 3. รัน Quick Verify
-- ตรวจว่า Setup ถูกต้อง
SELECT COUNT(*) FROM ana.AnalyticsConfig -- Expected: ≥ 19
SELECT COUNT(*) FROM slb.LoadJobs WHERE JobCode LIKE 'ANA-TEST-%' -- Expected: 12
SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'ana' -- Expected: 10
```

### 7.2 รัน Quick Verify จาก Section 7 ของ db/003

```sql
-- Quick Verify Script (ตามที่ระบุใน db/003 Section 7)

-- ตรวจ Views ทั้งหมดมีข้อมูล
SELECT 'vw_JobPerformance'     AS ViewName, COUNT(*) AS RowCount FROM ana.vw_JobPerformance
UNION ALL
SELECT 'vw_QueuePerformance',   COUNT(*) FROM ana.vw_QueuePerformance
UNION ALL
SELECT 'vw_DailyPerformance',   COUNT(*) FROM ana.vw_DailyPerformance
UNION ALL
SELECT 'vw_BayPerformance',     COUNT(*) FROM ana.vw_BayPerformance
UNION ALL
SELECT 'vw_ProductLossYield',   COUNT(*) FROM ana.vw_ProductLossYield
UNION ALL
SELECT 'vw_TruckTurnaround',    COUNT(*) FROM ana.vw_TruckTurnaround
UNION ALL
SELECT 'vw_HourlyThroughput',   COUNT(*) FROM ana.vw_HourlyThroughput
UNION ALL
SELECT 'vw_TruckProblemHistory',COUNT(*) FROM ana.vw_TruckProblemHistory
UNION ALL
SELECT 'vw_FormulaLossAnalysis',COUNT(*) FROM ana.vw_FormulaLossAnalysis
UNION ALL
SELECT 'vw_ShiftPerformance',   COUNT(*) FROM ana.vw_ShiftPerformance
ORDER BY ViewName

-- Expected: ทุก View มีข้อมูล > 0 row
```

### 7.3 ทดสอบ SPs ทีละตัวด้วย SSMS

**ขั้นตอน:**
1. เปิด SSMS → เชื่อมต่อ SmartLoadBulkDB
2. เปิด New Query
3. รัน SP Test Script ทีละ SP (PAT-001 ถึง PAT-011)
4. ตรวจ Result Set ตรงกับ Expected
5. บันทึกผล Pass/Fail

**Checklist สำหรับแต่ละ SP:**
- [ ] ไม่มี SQL Error
- [ ] Column ครบตาม Design
- [ ] ค่าที่คำนวณตรงกับ Manual Calculation
- [ ] Edge Case ไม่ Error (ช่วงไม่มีข้อมูล, NULL, Divide-by-Zero)
- [ ] Performance < 2 วินาที

### 7.4 ตรวจผ่าน Swagger API

```
URL: http://localhost:5000/swagger

Endpoints ที่ต้องทดสอบ:
GET  /api/analytics/performance?from=2026-05-01&to=2026-05-14
GET  /api/analytics/loss-yield?from=2026-05-01&to=2026-05-14
GET  /api/analytics/bay-performance?from=2026-05-01&to=2026-05-14
GET  /api/analytics/turnaround?from=2026-05-01&to=2026-05-14
GET  /api/analytics/product-loss?from=2026-05-01&to=2026-05-14&top=10
GET  /api/analytics/truck-problems?from=2026-05-01&to=2026-05-14
GET  /api/analytics/hourly-throughput?date=2026-05-14
GET  /api/analytics/shift-performance?from=2026-05-01&to=2026-05-14
GET  /api/analytics/alert-history?from=2026-05-01&to=2026-05-14
GET  /api/analytics/config
PUT  /api/analytics/config (Body: { "configKey": "X", "configValue": "Y" })
```

**สำหรับแต่ละ Endpoint ตรวจ:**
- HTTP Status = 200 OK
- Response Body มี JSON ถูก Format
- ตัวเลข KPI ตรงกับ SP Result ใน SSMS

### 7.5 ตรวจผ่าน Frontend Dashboard

**ขั้นตอนสำหรับแต่ละ Dashboard:**

1. เปิด `http://localhost:5173/analytics`
2. ตั้ง Date Range = 2026-05-01 ถึง 2026-05-14
3. รอข้อมูลโหลด
4. **เปรียบเทียบค่า KPI Card กับ SP Result ใน SSMS**

| ตรวจอะไร | วิธีตรวจ |
|---------|---------|
| ตัวเลข KPI Card ถูกต้อง | เทียบกับ SP Result ใน SSMS |
| Status Badge สีถูก | NORMAL=Green, WARNING=Amber, CRITICAL=Red |
| Chart แสดงข้อมูลถูก | เปรียบเทียบ Point บน Chart กับ vw_DailyPerformance |
| Filter Date Range ทำงาน | เปลี่ยน Date แล้วข้อมูลเปลี่ยน |
| Empty State แสดง | ใส่ Date ที่ไม่มีข้อมูล |
| SignalR Alert แสดง | รอ 15 นาที หรือ Trigger Alert ด้วยมือ |

---

## สรุป Analytics Test Coverage

| ส่วนที่ | รายการที่ Test | จำนวน Test |
|--------|--------------|-----------|
| Stored Procedures | SP01–SP11 (ทั้ง Normal + Edge Case) | 22+ Scenarios |
| Views | V01–V10 (ครบทุก View) | 10 Queries |
| KPI Calculation | 12 KPIs พร้อมสูตร + Manual Check | 12 KPIs |
| Config Threshold | 13 ConfigKeys | 13 Items |
| Test Data | 12 Seed Jobs (Normal/Warning/Critical/Failed) | 12 Jobs |
| API Endpoints | 11 Endpoints | 11 Tests |
| Frontend | 6 Dashboards | 6 Checks |
| **รวมทั้งหมด** | — | **76+ Test Points** |

---

## ข้อสังเกตและ Risk ที่ควรรู้

### Risk ที่พบจากการวิเคราะห์เอกสาร:

1. **FLOW_PROCESS vs DATABASE ไม่ตรงกัน (Bay Status):**
   - FLOW_PROCESS พูดถึง `AVAILABLE → CALLING → DOCKED → LOADING`
   - DATABASE_DESIGN มี Status = `AVAILABLE/CALLING/DOCKED/LOADING/CHECKING/ERROR/MAINTENANCE`
   - แต่ Views ใน PERFORMANCE_ANALYTICS ไม่กรอง CHECKING Status
   - **Action:** ตรวจว่า vw_BayPerformance นับ CHECKING เป็น Loading Time ด้วยหรือไม่

2. **BayLog TRUCK_DEPARTED อาจไม่มีในทุก Job:**
   - vw_TruckTurnaround ใช้ `ISNULL(bl_dep.EventTime, lj.CompletedAt + '00:10:00')` เป็น Fallback
   - ทำให้ ChecklistMin = 10 นาที เสมอถ้าไม่มี BayLog
   - **Action:** ต้องระบุใน Test Plan ว่าค่านี้อาจ Approximate

3. **AnalyticsConfig ไม่มี Validation ตัวเลข:**
   - sp_UpdateAnalyticsConfig รับ VARCHAR อาจ Update ค่าที่ไม่ใช่ตัวเลขได้
   - อาจทำให้ CAST ใน Query ล้มเหลว
   - **Action:** ควรเพิ่ม Input Validation หรือ TRY_CAST

4. **Seed Data (ANA-TEST-008 และ 009) ไม่มี ActualWeight:**
   - Views ที่ JOIN โดยไม่กรอง NULL ActualWeight อาจมีปัญหา
   - vw_JobPerformance กรอง `WHERE Status = 'COMPLETED'` จึงไม่รวม 2 Jobs นี้
   - **Action:** ตรวจว่า SP ทุกตัว Handle NULL ActualWeight ถูกต้อง

5. **ยังไม่มี Index สำหรับ LoadQueues.EnqueuedAt:**
   - PERFORMANCE_ANALYTICS_PLAN ระบุ Index เฉพาะ `CalledAt` และ `CreatedAt`
   - แต่ Average Waiting Time ใช้ `DATEDIFF(minute, CreatedAt, CalledAt)`
   - **Action:** ตรวจ Query Plan ว่า Index ใช้งานถูกต้อง

---

*Performance Analytics Test Plan V1.0 — Captain America (QA Agent) — 2026-05-14*  
*อ้างอิง: PERFORMANCE_ANALYTICS_PLAN.md V2.0, DATABASE_DESIGN.md*
