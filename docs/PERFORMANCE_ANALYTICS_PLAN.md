# PERFORMANCE ANALYTICS PLAN — Smart Load Bulk

**ออกแบบโดย:** Hawkeye  
**วันที่:** 2026-05-13  
**Version:** 2.0 (ฉบับละเอียด — ครอบคลุม 10 Area + Handoff สมบูรณ์)  
**อ้างอิง:** docs/PROJECT_CONTEXT.md, docs/SYSTEM_ARCHITECTURE.md V2.0, docs/FLOW_PROCESS.md V2.0

---

## ภาพรวมระบบ Analytics

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ANALYTICS SYSTEM OVERVIEW                            │
│                                                                         │
│   slb Schema (Raw OLTP)                ana Schema (Analytics OLAP)      │
│   ─────────────────────                ───────────────────────────      │
│   LoadJobs          ──────────────────→ vw_JobPerformance               │
│   LoadQueues        ──────────────────→ vw_QueuePerformance             │
│   LoadJobLogs       ──────────────────→ vw_DailyPerformance             │
│   BayLogs           ──────────────────→ vw_BayPerformance               │
│   InventoryLogs     ──────────────────→ vw_ProductLossYield             │
│   Trucks/Drivers    ──────────────────→ vw_TruckTurnaround              │
│   HardwareEvents    ──────────────────→ vw_HourlyThroughput             │
│   Orders/Items      ──────────────────→ vw_TruckProblemHistory          │
│                                        vw_FormulaLossAnalysis           │
│                                        vw_ShiftPerformance              │
│                                              │                          │
│                                              ▼                          │
│                                    Stored Procedures (11 SPs)           │
│                                              │                          │
│                                              ▼                          │
│                              AnalyticsController (ASP.NET Core 8)       │
│                                              │                          │
│                              ┌───────────────┴──────────────┐           │
│                              │          SignalR              │           │
│                              │        AnalyticsHub           │           │
│                              └───────────────┬──────────────┘           │
│                                              │                          │
│                              ┌───────────────┴──────────────┐           │
│                              │      React Dashboard UI       │           │
│                              │   (6 Dashboards, 25 KPIs)    │           │
│                              └──────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## ส่วนที่ 1 — KPI ทั้งหมดที่ควรมี (25 KPIs)

### กลุ่ม A: Volume & Production (K01–K07)

| Code | ชื่อ KPI | คำอธิบาย | Unit | Source Table |
|------|---------|---------|------|-------------|
| K01 | Total Jobs | จำนวน Job Loading ทั้งหมดในช่วงเวลา | Count | LoadJobs |
| K02 | Completed Jobs | Job ที่เสร็จสมบูรณ์ | Count | LoadJobs |
| K03 | Cancelled / Emergency Jobs | Job ที่ยกเลิกหรือ Emergency Stop | Count | LoadJobs |
| K04 | Completion Rate | สัดส่วน Job เสร็จ / Job ทั้งหมด | % | LoadJobs |
| K05 | Total Target Weight | น้ำหนักเป้าหมายรวม (จาก Order) | ตัน | OrderItems |
| K06 | Total Actual Weight | น้ำหนักที่โหลดจริงรวมทั้งหมด | ตัน | LoadJobs |
| K07 | Throughput Ton/Hour | ปริมาณโหลดจริงต่อชั่วโมง (ทั้งระบบ) | ตัน/ชม | LoadJobs |

### กลุ่ม B: Loss, Over & Yield (K08–K14)

| Code | ชื่อ KPI | คำอธิบาย | Unit | Source Table |
|------|---------|---------|------|-------------|
| K08 | Yield % | อัตรา Actual / Target ทั้งระบบ | % | LoadJobs |
| K09 | Total Loss Amount | น้ำหนักที่ขาดรวม (Actual < Target) | กก. | LoadJobs |
| K10 | Total Over Amount | น้ำหนักที่เกินรวม (Actual > Target) | กก. | LoadJobs |
| K11 | Diff % (Avg) | เปอร์เซ็นต์ความต่างเฉลี่ยต่อ Job | % | LoadJobs |
| K12 | Loading Accuracy % | Job ที่ Yield ± 0.5% / Total Jobs | % | LoadJobs |
| K13 | Loss Job Count | จำนวน Job ที่มี Yield < Threshold | Count | LoadJobs |
| K14 | Over Job Count | จำนวน Job ที่มี Yield > Threshold | Count | LoadJobs |

### กลุ่ม C: Time & Efficiency (K15–K20)

| Code | ชื่อ KPI | คำอธิบาย | Unit | Source Table |
|------|---------|---------|------|-------------|
| K15 | Avg Loading Time | เวลาโหลดเฉลี่ยต่อ Job (Start → Complete) | นาที | LoadJobs |
| K16 | Avg Queue Waiting Time | เวลารอในคิวเฉลี่ย (Confirmed → Called) | นาที | LoadQueues |
| K17 | Avg Truck Turnaround | เวลาตั้งแต่รถเข้า Bay ถึงออกจาก Bay | นาที | BayLogs |
| K18 | Bay Utilization % | เวลา Bay กำลัง Loading / เวลาทำงานรวม | % | BayLogs |
| K19 | Jobs per Bay per Day | จำนวน Job เฉลี่ยต่อ Bay ต่อวัน | Count | LoadJobs |
| K20 | Idle Bay Time | เวลาที่ Bay ว่าง (ไม่มีการโหลด) | นาที | BayLogs |

### กลุ่ม D: Product & Formula Analysis (K21–K23)

| Code | ชื่อ KPI | คำอธิบาย | Unit | Source Table |
|------|---------|---------|------|-------------|
| K21 | Loss Rate by Product | % Loss เฉลี่ยแยกตาม Product | % | LoadJobs + Products |
| K22 | Top Loss Product | Product ที่มี Loss สะสมสูงสุด (กก./ตัน) | กก. | LoadJobs + Products |
| K23 | Product Yield Variance | ความแปรปรวนของ Yield ต่อ Product | σ (SD) | LoadJobs + Products |

### กลุ่ม E: Truck & Transport (K24–K25)

| Code | ชื่อ KPI | คำอธิบาย | Unit | Source Table |
|------|---------|---------|------|-------------|
| K24 | Problem Truck Rate | รถที่มี Emergency / Loss สูงบ่อย / สัดส่วนทั้งหมด | % | Trucks + LoadJobs |
| K25 | Repeat Incident Count | จำนวน Emergency Stop / Loss Alert ต่อรถ ต่อช่วงเวลา | Count | HardwareEvents + Trucks |

---

## ส่วนที่ 2 — สูตรคำนวณแต่ละ KPI (พร้อม SQL)

### กลุ่ม A: Volume & Production

```sql
-- K01: Total Jobs
SELECT COUNT(*) AS TotalJobs
FROM slb.LoadJobs
WHERE StartedAt BETWEEN @DateFrom AND @DateTo

-- K02: Completed Jobs
SELECT COUNT(*) AS CompletedJobs
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt BETWEEN @DateFrom AND @DateTo

-- K03: Cancelled / Emergency Jobs
SELECT COUNT(*) AS CancelledJobs
FROM slb.LoadJobs
WHERE Status IN ('CANCELLED', 'EMERGENCY_STOPPED')
  AND StartedAt BETWEEN @DateFrom AND @DateTo

-- K04: Completion Rate
-- Completion Rate (%) = (CompletedJobs / TotalJobs) × 100
SELECT
  COUNT(CASE WHEN Status = 'COMPLETED' THEN 1 END) * 100.0
    / NULLIF(COUNT(*), 0)  AS CompletionRate
FROM slb.LoadJobs
WHERE StartedAt BETWEEN @DateFrom AND @DateTo

-- K05: Total Target Weight (ton)
-- ดึงจาก Order เพื่อให้ได้น้ำหนักเป้าหมายที่แท้จริง
SELECT SUM(oi.OrderedQty) AS TotalTargetWeight
FROM slb.LoadJobs lj
JOIN slb.LoadQueues lq ON lj.QueueId = lq.QueueId
JOIN slb.OrderItems oi ON lq.OrderItemId = oi.OrderItemId
WHERE lj.StartedAt BETWEEN @DateFrom AND @DateTo

-- K06: Total Actual Weight (ton)
SELECT SUM(ActualWeight) / 1000.0 AS TotalActualWeightTon
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt BETWEEN @DateFrom AND @DateTo

-- K07: Throughput (ton/hour)
-- Throughput = TotalActualWeight(ton) / SUM(LoadingDuration)(hour)
SELECT
  SUM(ActualWeight) / 1000.0 /
    NULLIF(SUM(DATEDIFF(MINUTE, StartedAt, CompletedAt)) / 60.0, 0)
  AS ThroughputTonPerHour
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt BETWEEN @DateFrom AND @DateTo
```

### กลุ่ม B: Loss, Over & Yield

```sql
-- K08: Yield % (ระดับ Job)
-- Yield% = (ActualWeight / TargetWeight) × 100
-- หมายเหตุ: TargetWeight มาจาก LoadJobs.TargetWeight

-- K08 ระดับ Job เดียว:
SELECT
  JobId,
  TargetWeight,
  ActualWeight,
  (ActualWeight / NULLIF(TargetWeight, 0)) * 100.0 AS YieldPct
FROM slb.LoadJobs

-- K08 ระดับรวม (Overall Yield):
SELECT
  SUM(ActualWeight) / NULLIF(SUM(TargetWeight), 0) * 100.0 AS OverallYieldPct
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt BETWEEN @DateFrom AND @DateTo

-- K09: Total Loss Amount (kg) — เฉพาะ Job ที่ขาด
-- Loss = TargetWeight - ActualWeight  เมื่อ Actual < Target
SELECT
  SUM(CASE WHEN ActualWeight < TargetWeight
           THEN TargetWeight - ActualWeight ELSE 0 END) AS TotalLossKg
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt BETWEEN @DateFrom AND @DateTo

-- K10: Total Over Amount (kg) — เฉพาะ Job ที่เกิน
-- Over = ActualWeight - TargetWeight  เมื่อ Actual > Target
SELECT
  SUM(CASE WHEN ActualWeight > TargetWeight
           THEN ActualWeight - TargetWeight ELSE 0 END) AS TotalOverKg
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt BETWEEN @DateFrom AND @DateTo

-- K11: Diff % Average
-- Diff% = ((Actual - Target) / Target) × 100  (ได้ติดลบถ้า Loss, บวกถ้า Over)
SELECT
  AVG((ActualWeight - TargetWeight) / NULLIF(TargetWeight, 0) * 100.0) AS AvgDiffPct
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt BETWEEN @DateFrom AND @DateTo

-- K12: Loading Accuracy % (Job ที่ Yield อยู่ใน ±0.5%)
-- Accurate Job = ABS(Diff%) ≤ 0.5
SELECT
  COUNT(CASE WHEN ABS((ActualWeight - TargetWeight)
             / NULLIF(TargetWeight, 0) * 100.0) <= 0.5 THEN 1 END) * 100.0
  / NULLIF(COUNT(*), 0) AS LoadingAccuracyPct
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt BETWEEN @DateFrom AND @DateTo

-- K13: Loss Job Count (Yield < 99.5%)
SELECT COUNT(*) AS LossJobCount
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND ActualWeight < TargetWeight * 0.995
  AND CompletedAt BETWEEN @DateFrom AND @DateTo

-- K14: Over Job Count (Yield > 100.5%)
SELECT COUNT(*) AS OverJobCount
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND ActualWeight > TargetWeight * 1.005
  AND CompletedAt BETWEEN @DateFrom AND @DateTo
```

### กลุ่ม C: Time & Efficiency

```sql
-- K15: Avg Loading Time (minutes) — StartedAt → CompletedAt
SELECT
  AVG(CAST(DATEDIFF(MINUTE, StartedAt, CompletedAt) AS FLOAT))
  AS AvgLoadingTimeMin
FROM slb.LoadJobs
WHERE Status = 'COMPLETED'
  AND CompletedAt BETWEEN @DateFrom AND @DateTo

-- K16: Avg Queue Waiting Time (minutes)
-- Queue Waiting = CalledAt - CreatedAt  (เวลารอตั้งแต่เข้าคิวจนถูกเรียก)
SELECT
  AVG(CAST(DATEDIFF(MINUTE, CreatedAt, CalledAt) AS FLOAT))
  AS AvgWaitingTimeMin
FROM slb.LoadQueues
WHERE Status = 'COMPLETED'
  AND CalledAt IS NOT NULL
  AND CalledAt BETWEEN @DateFrom AND @DateTo

-- K17: Avg Truck Turnaround Time (minutes)
-- Turnaround = รถออก Bay - รถเข้า Bay (จาก BayLogs)
SELECT
  AVG(CAST(DATEDIFF(MINUTE, ArrivalTime, DepartureTime) AS FLOAT))
  AS AvgTurnaroundMin
FROM (
  SELECT
    lj.JobId,
    MIN(CASE WHEN bl.EventType = 'TRUCK_ARRIVED'  THEN bl.EventTime END) AS ArrivalTime,
    MAX(CASE WHEN bl.EventType = 'TRUCK_DEPARTED' THEN bl.EventTime END) AS DepartureTime
  FROM slb.BayLogs bl
  JOIN slb.LoadJobs lj ON bl.BayId = lj.BayId
    AND bl.EventTime BETWEEN lj.StartedAt - '01:00:00' AND lj.CompletedAt + '01:00:00'
  WHERE lj.Status = 'COMPLETED'
    AND lj.CompletedAt BETWEEN @DateFrom AND @DateTo
  GROUP BY lj.JobId
) t
WHERE ArrivalTime IS NOT NULL AND DepartureTime IS NOT NULL

-- K18: Bay Utilization %
-- Utilization = SUM(LoadingMinutes per Bay) / (WorkingHours × 60) × 100
-- WorkingHours = 16 (ตั้งค่าได้ใน AnalyticsConfig)
SELECT
  b.BayName,
  SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) AS TotalLoadingMin,
  @WorkingMinutes AS CapacityMin,
  SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) * 100.0
    / NULLIF(@WorkingMinutes, 0) AS BayUtilizationPct
FROM slb.LoadJobs lj
JOIN slb.Bays b ON lj.BayId = b.BayId
WHERE lj.Status = 'COMPLETED'
  AND CAST(lj.StartedAt AS DATE) = @Date
GROUP BY b.BayId, b.BayName

-- K19: Jobs per Bay per Day
SELECT
  b.BayName,
  CAST(lj.CompletedAt AS DATE) AS WorkDate,
  COUNT(*) AS JobsCount
FROM slb.LoadJobs lj
JOIN slb.Bays b ON lj.BayId = b.BayId
WHERE lj.Status = 'COMPLETED'
  AND lj.CompletedAt BETWEEN @DateFrom AND @DateTo
GROUP BY b.BayId, b.BayName, CAST(lj.CompletedAt AS DATE)

-- K20: Idle Bay Time (minutes per day)
-- IdleTime = TotalDayMinutes - SUM(LoadingMinutes)
SELECT
  b.BayName,
  @WorkingMinutes - SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt))
  AS IdleTimeMin
FROM slb.LoadJobs lj
JOIN slb.Bays b ON lj.BayId = b.BayId
WHERE lj.Status = 'COMPLETED'
  AND CAST(lj.StartedAt AS DATE) = @Date
GROUP BY b.BayId, b.BayName
```

### กลุ่ม D: Product & Formula Analysis

```sql
-- K21: Loss Rate by Product (%)
SELECT
  p.ProductName,
  p.ProductCode,
  AVG((lj.TargetWeight - lj.ActualWeight) / NULLIF(lj.TargetWeight, 0) * 100.0)
    AS AvgLossRatePct,
  SUM(lj.TargetWeight - lj.ActualWeight) AS TotalLossKg,
  COUNT(*) AS JobCount
FROM slb.LoadJobs lj
JOIN slb.LoadQueues lq ON lj.QueueId = lq.QueueId
JOIN slb.Orders o       ON lq.OrderId = o.OrderId
JOIN slb.OrderItems oi  ON lq.OrderItemId = oi.OrderItemId
JOIN slb.Products p     ON oi.ProductId = p.ProductId
WHERE lj.Status = 'COMPLETED'
  AND lj.ActualWeight < lj.TargetWeight
  AND lj.CompletedAt BETWEEN @DateFrom AND @DateTo
GROUP BY p.ProductId, p.ProductName, p.ProductCode
ORDER BY TotalLossKg DESC

-- K22: Top Loss Product (สะสมสูงสุด)
-- → ใช้ Query K21 ORDER BY TotalLossKg DESC, LIMIT/TOP 10

-- K23: Product Yield Variance (Standard Deviation)
SELECT
  p.ProductName,
  AVG((lj.ActualWeight / NULLIF(lj.TargetWeight, 0)) * 100.0) AS AvgYieldPct,
  STDEV((lj.ActualWeight / NULLIF(lj.TargetWeight, 0)) * 100.0) AS YieldStdDev,
  MIN((lj.ActualWeight / NULLIF(lj.TargetWeight, 0)) * 100.0) AS MinYieldPct,
  MAX((lj.ActualWeight / NULLIF(lj.TargetWeight, 0)) * 100.0) AS MaxYieldPct
FROM slb.LoadJobs lj
JOIN slb.LoadQueues lq ON lj.QueueId = lq.QueueId
JOIN slb.OrderItems oi ON lq.OrderItemId = oi.OrderItemId
JOIN slb.Products p    ON oi.ProductId = p.ProductId
WHERE lj.Status = 'COMPLETED'
  AND lj.CompletedAt BETWEEN @DateFrom AND @DateTo
GROUP BY p.ProductId, p.ProductName
```

### กลุ่ม E: Truck & Transport

```sql
-- K24: Problem Truck Rate
-- "Problem" = รถที่มี EmergencyStop หรือ LossAlert ≥ 2 ครั้งใน Period
WITH ProblemTrucks AS (
  SELECT DISTINCT lj.TruckId
  FROM slb.LoadJobs lj
  WHERE lj.StartedAt BETWEEN @DateFrom AND @DateTo
    AND (
      lj.Status = 'EMERGENCY_STOPPED'
      OR (lj.Status = 'COMPLETED'
          AND lj.ActualWeight < lj.TargetWeight * 0.980) -- Loss > 2%
    )
  GROUP BY lj.TruckId
  HAVING COUNT(*) >= 2
)
SELECT
  COUNT(DISTINCT pt.TruckId) * 100.0
    / NULLIF(COUNT(DISTINCT lj.TruckId), 0) AS ProblemTruckRatePct
FROM slb.LoadJobs lj
LEFT JOIN ProblemTrucks pt ON lj.TruckId = pt.TruckId
WHERE lj.StartedAt BETWEEN @DateFrom AND @DateTo

-- K25: Repeat Incident Count per Truck
SELECT
  t.LicensePlate,
  t.TruckId,
  SUM(CASE WHEN lj.Status = 'EMERGENCY_STOPPED' THEN 1 ELSE 0 END)
    AS EmergencyCount,
  SUM(CASE WHEN lj.Status = 'COMPLETED'
                AND lj.ActualWeight < lj.TargetWeight * 0.980
           THEN 1 ELSE 0 END) AS LossAlertCount,
  COUNT(*) AS TotalJobs
FROM slb.Trucks t
JOIN slb.LoadJobs lj ON t.TruckId = lj.TruckId
WHERE lj.StartedAt BETWEEN @DateFrom AND @DateTo
GROUP BY t.TruckId, t.LicensePlate
ORDER BY (EmergencyCount + LossAlertCount) DESC
```

---

## ส่วนที่ 3 — Dashboard ที่ควรมี (6 Dashboards)

### Dashboard 1: Performance Overview (`/analytics`)

**วัตถุประสงค์:** ภาพรวมสถานะการโหลดทั้งระบบ — เห็นได้ใน 5 วินาที

```
┌─────────────────────────────────────────────────────────────────────────┐
│  [วันที่/ช่วงเวลา Filter] ▼    [Shift Filter] ▼    [🔄 Refresh]         │
├────────────┬────────────┬────────────┬────────────┬────────────────────┤
│  K01       │  K04       │  K08       │  K12       │  K07               │
│  Total     │ Completion │  Yield %   │ Accuracy % │ Throughput         │
│  Jobs      │  Rate %    │            │            │ ton/hr             │
│  ──────    │  ──────    │  ──────    │  ──────    │  ──────            │
│   124      │  96.8%     │  99.7%     │  87.2%     │  42.5 t/hr         │
│ ▲ +12 วันนี้│ 🟢 GOOD   │ 🟢 NORMAL  │ 🟡 OK      │ 🟢 HIGH            │
├────────────┴────────────┴────────────┴────────────┴────────────────────┤
│  LINE CHART — Daily Jobs + Tonnage Trend (30 วันย้อนหลัง)              │
│  ────────────────────────────────────────────────────────────────────  │
│  [กราฟเส้น 2 แกน: จำนวน Job (แกนซ้าย) + Tonnage (แกนขวา)]             │
├─────────────────────────────┬───────────────────────────────────────── │
│  BAR CHART — Jobs per Bay   │  DONUT — Job Status Distribution        │
│  Bay A █████████ 38         │       COMPLETED ████████ 96.8%          │
│  Bay B ██████    24         │       CANCELLED ██        2.4%          │
│  Bay C ████████  30         │       EMERGENCY █         0.8%          │
│  Bay D ███████   27         │                                         │
├─────────────────────────────┴───────────────────────────────────────── │
│  TABLE — Today's Job Summary (ล่าสุด 20 รายการ)                        │
│  JobId | Bay | Truck | Product | Target | Actual | Yield% | Status    │
└─────────────────────────────────────────────────────────────────────────┘
```

**KPIs หลัก:** K01, K02, K03, K04, K05, K06, K07, K08, K12  
**Charts:** Line (Trend), Bar (Per Bay), Donut (Status), Table (Detail)

---

### Dashboard 2: Loss / Yield Analysis (`/analytics/loss-yield`)

**วัตถุประสงค์:** วิเคราะห์ Loss, Over, Yield แต่ละ Job และ Trend

```
┌─────────────────────────────────────────────────────────────────────────┐
│  [Date Range] ▼   [Product Filter] ▼   [Bay Filter] ▼   [🔄]           │
├───────────┬───────────┬───────────┬───────────┬───────────┬───────────┤
│  K08      │  K09      │  K10      │  K11      │  K12      │  K13+K14  │
│ Yield%    │ Loss kg   │ Over kg   │ Avg Diff% │ Accuracy% │ Loss/Over │
│  99.7%    │ 142 kg    │  38 kg    │ -0.10%    │  87.2%    │ 🔴8 🟡3  │
├───────────┴───────────┴───────────┴───────────┴───────────┴───────────┤
│  GAUGE CHART — Yield % Gauge (คล้าย Speedometer)                       │
│  ────────────────────────────────────────────────────────────────────  │
│  [98%]══════════[99.5%]═══99.7%═══[100.5%]═══════════[102%]           │
│   CRITICAL       WARNING ↑ NORMAL           WARNING       CRITICAL     │
├──────────────────────────────────┬──────────────────────────────────── │
│  LINE CHART — Daily Yield Trend  │  AREA CHART — Daily Loss/Over       │
│  (30 days, with threshold lines) │  (แกนบน = Over, แกนล่าง = Loss)    │
│  [99.5% line ─ ─ ─ ─ ─ ─ ─]   │  [แสดงสัดส่วนว่าวันไหนมีปัญหา]     │
├──────────────────────────────────┴──────────────────────────────────── │
│  TABLE — Job Loss Detail (Sort by Loss Amount DESC)                     │
│  Date | JobId | Bay | Truck | Product | Target | Actual | Loss | Yield%│
│  (คลิก Row → Drill-down รายละเอียด Job)                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

**KPIs หลัก:** K08, K09, K10, K11, K12, K13, K14  
**Charts:** Gauge (Yield), Line (Trend), Area (Loss/Over), Table (Drill-down)

---

### Dashboard 3: Bay Performance (`/analytics/bay`)

**วัตถุประสงค์:** เปรียบเทียบประสิทธิภาพระหว่าง Bay และหาคอขวด

```
┌─────────────────────────────────────────────────────────────────────────┐
│  [Date] ▼   [Working Hours: 16hr] ▼   [🔄]                              │
├────────────────┬────────────────┬────────────────┬──────────────────── │
│ Bay A          │ Bay B          │ Bay C          │ Bay D               │
│ Util: 78% 🟢  │ Util: 45% 🟡  │ Util: 82% 🟢  │ Util: 62% 🟡       │
│ Jobs: 38       │ Jobs: 24       │ Jobs: 30       │ Jobs: 27           │
│ Avg Time: 22m  │ Avg Time: 31m  │ Avg Time: 19m  │ Avg Time: 26m     │
│ Yield: 99.8%   │ Yield: 99.2%🟡 │ Yield: 99.9%   │ Yield: 99.6%      │
├──────────────────────────────────────────────────────────────────────── │
│  HEATMAP — Bay Utilization by Hour (วันนี้)                             │
│  ────────────────────────────────────────────────────────────────────  │
│  Hour │ 06 │ 07 │ 08 │ 09 │ 10 │ 11 │ 12 │ 13 │ 14 │ 15 │ 16 │ 17  │
│  BayA │ ██ │ ██ │ ██ │ ░░ │ ██ │ ██ │ ─  │ ██ │ ██ │ ██ │ ██ │ ░░  │
│  BayB │ ░░ │ ██ │ ░░ │ ░░ │ ██ │ ░░ │ ─  │ ░░ │ ██ │ ░░ │ ██ │ ░░  │
│  BayC │ ██ │ ██ │ ██ │ ██ │ ██ │ ██ │ ─  │ ██ │ ██ │ ██ │ ██ │ ██  │
│  BayD │ ░░ │ ██ │ ██ │ ░░ │ ██ │ ██ │ ─  │ ██ │ ██ │ ░░ │ ██ │ ██  │
│  ██=LOADING  ░░=IDLE  ─=LUNCH BREAK                                    │
├──────────────────────────────────────────────────────────────────────── │
│  BAR CHART — Throughput per Bay (ton/hr)                                │
│  + LINE — Avg Loading Time per Bay Trend (7 วัน)                        │
└─────────────────────────────────────────────────────────────────────────┘
```

**KPIs หลัก:** K18, K19, K20, K07 (แยก Bay), K15 (แยก Bay), K08 (แยก Bay)  
**Charts:** Card Grid (Bay Summary), Heatmap (Utilization by Hour), Bar+Line (Throughput/Time)

---

### Dashboard 4: Truck Turnaround (`/analytics/turnaround`)

**วัตถุประสงค์:** วิเคราะห์เวลาที่รถใช้ตั้งแต่เข้าจนออก และหาคอขวด

```
┌─────────────────────────────────────────────────────────────────────────┐
│  [Date Range] ▼   [Truck Filter] ▼   [🔄]                               │
├──────────────────┬──────────────────┬──────────────────┬─────────────── │
│  K17             │  K16             │  K15             │  K07          │
│ Avg Turnaround   │ Avg Queue Wait   │ Avg Loading Time │ Throughput    │
│  78 min 🟢       │  24 min 🟢       │  22 min 🟢       │  42 t/hr 🟢  │
├──────────────────┴──────────────────┴──────────────────┴─────────────── │
│  STACKED BAR — Turnaround Time Breakdown (ต่อ Job)                      │
│  [Queue Wait] + [Loading Time] + [Checklist Time] = Total Turnaround    │
│  ────────────────────────────────────────────────────────────────────  │
│  08:00 ░░░░░████████░░  [Queue=15m, Load=22m, Check=5m] = 42m          │
│  09:30 ░░░░████████░░░  [Queue=10m, Load=20m, Check=8m] = 38m          │
│  11:00 ░░░░░░░████████  [Queue=30m, Load=25m, Check=5m] = 60m ⚠        │
├──────────────────────────────────────────────────────────────────────── │
│  LINE CHART — Daily Avg Turnaround (30 days)                            │
│  (พร้อม Threshold Line และ Trend Annotation)                            │
├──────────────────────────────────────────────────────────────────────── │
│  TABLE — Truck Turnaround Detail (Sort: Turnaround DESC)                │
│  Truck | Driver | Arrive | LoadStart | Complete | Depart | Total | Bay  │
└─────────────────────────────────────────────────────────────────────────┘
```

**KPIs หลัก:** K15, K16, K17, K07  
**Charts:** Stacked Bar (Time Breakdown), Line (Trend), Table (Detail)

---

### Dashboard 5: Product Loss Analysis (`/analytics/product`)

**วัตถุประสงค์:** หา Product / Formula ที่มีปัญหา Loss สูงเพื่อแก้ไขกระบวนการ

```
┌─────────────────────────────────────────────────────────────────────────┐
│  [Date Range] ▼   [Product Filter] ▼   [🔄]                             │
├────────────────────────────────────────┬────────────────────────────── │
│  BAR CHART — Loss by Product (TOP 10)  │  SCATTER — Yield Variance     │
│  ────────────────────────────────────  │  (X=AvgYield%, Y=StdDev)      │
│  ProductA ████████████ 450 kg          │  . = each product             │
│  ProductB ████████     320 kg          │  [stable zone: left-top]      │
│  ProductC ████         180 kg          │  [problem zone: right-bottom]  │
│  ProductD ██            90 kg          │                                │
├────────────────────────────────────────┴────────────────────────────── │
│  TABLE — Product Loss Summary                                           │
│  Product | Total Jobs | Avg Yield% | StdDev | Total Loss kg | Rank     │
│  (คลิก Product → Drill-down ดู Job แต่ละ Job)                           │
├──────────────────────────────────────────────────────────────────────── │
│  LINE CHART — Yield Trend per Product (เส้นต่อ Product เลือกได้)        │
│  (แสดง 30 วันย้อนหลัง เปรียบเทียบหลาย Product)                        │
└─────────────────────────────────────────────────────────────────────────┘
```

**KPIs หลัก:** K21, K22, K23  
**Charts:** Bar (Loss Rank), Scatter (Variance), Table (Summary), Line (Trend)

---

### Dashboard 6: Truck & Transport Problem (`/analytics/truck-problem`)

**วัตถุประสงค์:** หารถและคนขับที่มีปัญหาบ่อย — Emergency / Loss สูง / Turnaround นาน

```
┌─────────────────────────────────────────────────────────────────────────┐
│  [Date Range] ▼   [Transport Company Filter] ▼   [🔄]                   │
├──────────────────┬──────────────────┬────────────────────────────────── │
│  K24             │  K25             │  Problem Distribution            │
│ Problem Truck    │ Repeat Incident  │  Emergency ██████ 38%            │
│  Rate %          │  (Top Truck)     │  High Loss ████████ 51%          │
│  12.5% 🟡        │  TruckXX: 5 ครั้ง│  Long Wait  ███ 11%             │
├──────────────────┴──────────────────┴────────────────────────────────── │
│  BAR CHART — Problem Count per Truck (Top 15)                           │
│  [Emergency] + [Loss Alert] + [Long Turnaround] per Truck               │
│  ████░░░  TruckAA: Emergency=3, Loss=2, LongTA=1                       │
│  ████░    TruckBB: Emergency=1, Loss=3, LongTA=0                       │
├──────────────────────────────────────────────────────────────────────── │
│  TABLE — Truck Problem Detail                                           │
│  Truck | Company | Driver | TotalJobs | Emergency | LossAlert | TAAvg  │
│  (คลิก Truck → History ของรถคันนั้น)                                    │
├──────────────────────────────────────────────────────────────────────── │
│  TIMELINE — Incident History (แสดงเหตุการณ์แต่ละ Truck ตามเวลา)        │
│  TruckAA: ──🔴──────🟡───────🔴────────────────────────                │
│  TruckBB: ────────🟡─────────────🟡────────🔴───────                   │
│  (🔴=Emergency, 🟡=LossAlert)                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

**KPIs หลัก:** K24, K25, K17 (per truck)  
**Charts:** Bar (Problem per Truck), Table (Detail), Timeline (Incident History)

---

## ส่วนที่ 4 — Chart ที่ควรใช้ (Chart Specification)

| Chart Type | ใช้ใน Dashboard | Library | หมายเหตุ |
|-----------|----------------|---------|----------|
| Line Chart | D1, D2, D4, D5 | Recharts `<LineChart>` | รองรับ Multiple Lines, Reference Line |
| Bar Chart | D1, D3, D5, D6 | Recharts `<BarChart>` | Stacked/Grouped |
| Stacked Bar | D4 | Recharts `<BarChart stacked>` | แสดง Breakdown ของเวลา |
| Area Chart | D2 | Recharts `<AreaChart>` | Loss vs Over Area |
| Donut/Pie | D1, D6 | Recharts `<PieChart>` | Job Status, Incident Type |
| Gauge/Radial | D2 | Recharts `<RadialBarChart>` | Yield % Gauge |
| Heatmap | D3 | CSS Grid หรือ Custom Recharts | Utilization by Bay × Hour |
| Scatter Plot | D5 | Recharts `<ScatterChart>` | Yield vs Variance |
| KPI Card | ทุก Dashboard | Custom Component | ตัวเลขใหญ่ + Trend Arrow + Badge |
| Data Table | ทุก Dashboard | TanStack Table (react-table) | Sort, Filter, Pagination, Drill-down |

### KPI Card Component Specification

```
┌────────────────────────────────┐
│  [Icon]  Yield %               │  ← Label
│                                │
│  ████ 99.7%                    │  ← Main Value (text-4xl, font-bold)
│                                │
│  ▲ +0.2% vs Yesterday          │  ← Trend (green/red arrow)
│                                │
│  ████████░░░░  NORMAL          │  ← Status Badge (color from threshold)
└────────────────────────────────┘

Color Coding:
  GOOD / NORMAL  → bg-green-50,  border-green-200, text-green-700
  WARNING        → bg-amber-50,  border-amber-200, text-amber-700
  CRITICAL       → bg-red-50,    border-red-200,   text-red-700  + animate-pulse
```

---

## ส่วนที่ 5 — Table / View / Stored Procedure ที่ควรสร้าง

### 5.1 Views ใน Schema `ana` (10 Views)

#### V01: `ana.vw_JobPerformance` — Core KPI ต่อ Job

```sql
CREATE VIEW ana.vw_JobPerformance AS
SELECT
  lj.JobId,
  lj.BayId,
  b.BayName,
  lj.QueueId,
  lj.StartedAt,
  lj.CompletedAt,
  lj.Status,
  lj.TargetWeight,
  lj.ActualWeight,

  -- Truck & Driver
  lj.TruckId,
  t.LicensePlate,
  t.TruckType,
  d.FullName AS DriverName,

  -- Product
  p.ProductId,
  p.ProductName,
  p.ProductCode,

  -- Order & Customer
  o.OrderId,
  o.OrderNumber,
  c.CustomerName,

  -- Time KPIs
  DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) AS LoadingDurationMin,

  -- Weight KPIs
  lj.ActualWeight - lj.TargetWeight  AS DiffKg,
  CASE WHEN lj.TargetWeight > 0
       THEN (lj.ActualWeight - lj.TargetWeight) / lj.TargetWeight * 100.0
       ELSE NULL END                  AS DiffPct,
  CASE WHEN lj.TargetWeight > 0
       THEN lj.ActualWeight / lj.TargetWeight * 100.0
       ELSE NULL END                  AS YieldPct,
  CASE WHEN lj.ActualWeight < lj.TargetWeight
       THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END  AS LossKg,
  CASE WHEN lj.ActualWeight > lj.TargetWeight
       THEN lj.ActualWeight - lj.TargetWeight ELSE 0 END  AS OverKg,

  -- Accuracy Flag
  CASE WHEN ABS((lj.ActualWeight - lj.TargetWeight)
               / NULLIF(lj.TargetWeight, 0) * 100.0) <= 0.5
       THEN 1 ELSE 0 END              AS IsAccurate,

  -- Throughput (ton/hr per job)
  CASE WHEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) > 0
       THEN (lj.ActualWeight / 1000.0)
            / (DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) / 60.0)
       ELSE NULL END                  AS ThroughputTonPerHour,

  CAST(lj.StartedAt AS DATE)         AS WorkDate,
  DATEPART(HOUR, lj.StartedAt)       AS WorkHour,

  -- Shift (ตาม Config: Shift1=06-14, Shift2=14-22, Shift3=22-06)
  CASE WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 6  AND 13 THEN 'SHIFT1'
       WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 14 AND 21 THEN 'SHIFT2'
       ELSE 'SHIFT3' END              AS ShiftName

FROM slb.LoadJobs lj
JOIN slb.Bays        b  ON lj.BayId    = b.BayId
JOIN slb.Trucks      t  ON lj.TruckId  = t.TruckId
JOIN slb.LoadQueues  lq ON lj.QueueId  = lq.QueueId
JOIN slb.Orders      o  ON lq.OrderId  = o.OrderId
JOIN slb.Customers   c  ON o.CustomerId = c.CustomerId
JOIN slb.OrderItems  oi ON lq.OrderItemId = oi.OrderItemId
JOIN slb.Products    p  ON oi.ProductId = p.ProductId
LEFT JOIN slb.TruckDriverMap tdm ON t.TruckId = tdm.TruckId AND tdm.IsPrimary = 1
LEFT JOIN slb.Drivers d ON tdm.DriverId = d.DriverId
WHERE lj.Status = 'COMPLETED'
```

#### V02: `ana.vw_QueuePerformance` — Queue Waiting Time

```sql
CREATE VIEW ana.vw_QueuePerformance AS
SELECT
  lq.QueueId,
  lq.QueueNumber,
  lq.OrderId,
  lq.Status,
  lq.Priority,
  lq.CreatedAt,
  lq.CalledAt,
  lq.CompletedAt,

  -- Waiting Time = CalledAt - CreatedAt
  DATEDIFF(MINUTE, lq.CreatedAt, lq.CalledAt)    AS QueueWaitingMin,

  -- Total Time in System = CompletedAt - CreatedAt
  DATEDIFF(MINUTE, lq.CreatedAt, lq.CompletedAt) AS TotalSystemTimeMin,

  CAST(lq.CreatedAt AS DATE)     AS QueueDate,
  lq.Priority

FROM slb.LoadQueues lq
WHERE lq.CalledAt IS NOT NULL
```

#### V03: `ana.vw_DailyPerformance` — Daily Aggregate

```sql
CREATE VIEW ana.vw_DailyPerformance AS
SELECT
  CAST(lj.CompletedAt AS DATE) AS WorkDate,
  COUNT(*)                AS TotalJobs,
  COUNT(CASE WHEN lj.Status = 'COMPLETED' THEN 1 END) AS CompletedJobs,
  COUNT(CASE WHEN lj.Status = 'CANCELLED' THEN 1 END) AS CancelledJobs,
  COUNT(CASE WHEN lj.Status = 'EMERGENCY_STOPPED' THEN 1 END) AS EmergencyJobs,

  SUM(lj.TargetWeight)    AS TotalTargetKg,
  SUM(lj.ActualWeight)    AS TotalActualKg,
  SUM(CASE WHEN lj.ActualWeight < lj.TargetWeight
           THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END) AS TotalLossKg,
  SUM(CASE WHEN lj.ActualWeight > lj.TargetWeight
           THEN lj.ActualWeight - lj.TargetWeight ELSE 0 END) AS TotalOverKg,

  SUM(lj.ActualWeight) / NULLIF(SUM(lj.TargetWeight), 0) * 100.0 AS OverallYieldPct,
  AVG(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt))            AS AvgLoadingMin,

  COUNT(CASE WHEN ABS((lj.ActualWeight - lj.TargetWeight)
                      / NULLIF(lj.TargetWeight, 0) * 100.0) <= 0.5
             THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)          AS AccuracyPct,

  SUM(lj.ActualWeight / 1000.0)
    / NULLIF(SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) / 60.0, 0)
  AS ThroughputTonPerHour

FROM slb.LoadJobs lj
WHERE lj.Status IN ('COMPLETED', 'CANCELLED', 'EMERGENCY_STOPPED')
GROUP BY CAST(lj.CompletedAt AS DATE)
```

#### V04: `ana.vw_BayPerformance` — Bay-level KPIs

```sql
CREATE VIEW ana.vw_BayPerformance AS
SELECT
  CAST(lj.StartedAt AS DATE) AS WorkDate,
  lj.BayId,
  b.BayName,

  COUNT(*)            AS TotalJobs,
  SUM(lj.ActualWeight / 1000.0)  AS TotalActualTon,
  AVG(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) AS AvgLoadingMin,
  SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) AS TotalLoadingMin,

  SUM(lj.ActualWeight) / NULLIF(SUM(lj.TargetWeight), 0) * 100.0 AS BayYieldPct,

  SUM(lj.ActualWeight / 1000.0)
    / NULLIF(SUM(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) / 60.0, 0)
  AS ThroughputTonPerHour

FROM slb.LoadJobs lj
JOIN slb.Bays b ON lj.BayId = b.BayId
WHERE lj.Status = 'COMPLETED'
GROUP BY CAST(lj.StartedAt AS DATE), lj.BayId, b.BayName
```

#### V05: `ana.vw_ProductLossYield` — Product-level Loss

```sql
CREATE VIEW ana.vw_ProductLossYield AS
SELECT
  CAST(lj.CompletedAt AS DATE) AS WorkDate,
  p.ProductId,
  p.ProductName,
  p.ProductCode,

  COUNT(*)            AS TotalJobs,
  SUM(lj.TargetWeight)AS TotalTargetKg,
  SUM(lj.ActualWeight)AS TotalActualKg,

  SUM(lj.ActualWeight) / NULLIF(SUM(lj.TargetWeight), 0) * 100.0 AS YieldPct,
  SUM(CASE WHEN lj.ActualWeight < lj.TargetWeight
           THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END) AS TotalLossKg,
  SUM(CASE WHEN lj.ActualWeight > lj.TargetWeight
           THEN lj.ActualWeight - lj.TargetWeight ELSE 0 END) AS TotalOverKg,
  STDEV(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0) AS YieldStdDev

FROM slb.LoadJobs lj
JOIN slb.LoadQueues  lq ON lj.QueueId  = lq.QueueId
JOIN slb.OrderItems  oi ON lq.OrderItemId = oi.OrderItemId
JOIN slb.Products    p  ON oi.ProductId = p.ProductId
WHERE lj.Status = 'COMPLETED'
GROUP BY CAST(lj.CompletedAt AS DATE), p.ProductId, p.ProductName, p.ProductCode
```

#### V06: `ana.vw_TruckTurnaround` — Turnaround per Truck

```sql
CREATE VIEW ana.vw_TruckTurnaround AS
SELECT
  lj.JobId,
  CAST(lj.StartedAt AS DATE) AS WorkDate,
  lj.TruckId,
  t.LicensePlate,
  t.TruckType,
  lj.BayId,
  b.BayName,
  lj.QueueId,

  -- Timestamps
  lq.CreatedAt                              AS QueueCreatedAt,
  lq.CalledAt                               AS TruckCalledAt,
  lj.StartedAt                              AS LoadingStartedAt,
  lj.CompletedAt                            AS LoadingCompletedAt,

  -- Time Segments (minutes)
  DATEDIFF(MINUTE, lq.CreatedAt,   lq.CalledAt)   AS QueueWaitMin,
  DATEDIFF(MINUTE, lq.CalledAt,    lj.StartedAt)  AS DockingMin,
  DATEDIFF(MINUTE, lj.StartedAt,   lj.CompletedAt)AS LoadingMin,
  DATEDIFF(MINUTE, lj.CompletedAt,
    ISNULL(bl_dep.EventTime, lj.CompletedAt + '00:10:00')) AS ChecklistMin,

  -- Total Turnaround
  DATEDIFF(MINUTE, lq.CalledAt,
    ISNULL(bl_dep.EventTime, lj.CompletedAt + '00:10:00'))AS TurnaroundMin

FROM slb.LoadJobs lj
JOIN slb.Trucks     t   ON lj.TruckId = t.TruckId
JOIN slb.Bays       b   ON lj.BayId   = b.BayId
JOIN slb.LoadQueues lq  ON lj.QueueId = lq.QueueId
LEFT JOIN slb.BayLogs bl_dep ON bl_dep.BayId = lj.BayId
  AND bl_dep.EventType = 'TRUCK_DEPARTED'
  AND bl_dep.EventTime > lj.CompletedAt
  AND bl_dep.EventTime < DATEADD(HOUR, 2, lj.CompletedAt)
WHERE lj.Status = 'COMPLETED'
  AND lq.CalledAt IS NOT NULL
```

#### V07: `ana.vw_HourlyThroughput` — ชั่วโมง × Bay

```sql
CREATE VIEW ana.vw_HourlyThroughput AS
SELECT
  CAST(lj.StartedAt AS DATE)  AS WorkDate,
  DATEPART(HOUR, lj.StartedAt)AS WorkHour,
  lj.BayId,
  b.BayName,

  COUNT(*)                    AS JobCount,
  SUM(lj.ActualWeight / 1000.0) AS TotalActualTon,
  AVG(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt)) AS AvgLoadingMin

FROM slb.LoadJobs lj
JOIN slb.Bays b ON lj.BayId = b.BayId
WHERE lj.Status = 'COMPLETED'
GROUP BY
  CAST(lj.StartedAt AS DATE),
  DATEPART(HOUR, lj.StartedAt),
  lj.BayId, b.BayName
```

#### V08: `ana.vw_TruckProblemHistory` — ประวัติปัญหาของรถ (ใหม่)

```sql
CREATE VIEW ana.vw_TruckProblemHistory AS
SELECT
  lj.TruckId,
  t.LicensePlate,
  t.OwnerName                                  AS TransportCompany,
  lj.JobId,
  lj.StartedAt                                 AS IncidentDate,
  lj.Status,
  CASE
    WHEN lj.Status = 'EMERGENCY_STOPPED'       THEN 'EMERGENCY'
    WHEN lj.ActualWeight < lj.TargetWeight * 0.980 THEN 'HIGH_LOSS'
    WHEN lj.ActualWeight > lj.TargetWeight * 1.020 THEN 'HIGH_OVER'
    WHEN DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt) >
         (SELECT CAST(ConfigValue AS INT) FROM ana.AnalyticsConfig
          WHERE ConfigKey = 'LOADING_TIME_CRITICAL_MIN')
         THEN 'SLOW_LOADING'
    ELSE 'OTHER'
  END                                          AS IncidentType,
  lj.TargetWeight,
  lj.ActualWeight,
  CASE WHEN lj.TargetWeight > 0
       THEN lj.ActualWeight / lj.TargetWeight * 100.0
       ELSE NULL END                           AS YieldPct,
  lj.BayId,
  b.BayName

FROM slb.LoadJobs lj
JOIN slb.Trucks t ON lj.TruckId = t.TruckId
JOIN slb.Bays   b ON lj.BayId   = b.BayId
WHERE (
  lj.Status IN ('EMERGENCY_STOPPED', 'CANCELLED')
  OR (lj.Status = 'COMPLETED' AND (
    lj.ActualWeight < lj.TargetWeight * 0.980
    OR lj.ActualWeight > lj.TargetWeight * 1.020
  ))
)
```

#### V09: `ana.vw_FormulaLossAnalysis` — Loss วิเคราะห์ต่อ Formula/Product (ใหม่)

```sql
CREATE VIEW ana.vw_FormulaLossAnalysis AS
SELECT
  p.ProductId,
  p.ProductName,
  p.ProductCode,
  CAST(lj.CompletedAt AS DATE)                    AS WorkDate,
  lj.BayId,
  b.BayName,

  COUNT(*)                                         AS JobCount,
  AVG(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0) AS AvgYieldPct,
  STDEV(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0) AS YieldStdDev,
  SUM(CASE WHEN lj.ActualWeight < lj.TargetWeight
           THEN lj.TargetWeight - lj.ActualWeight ELSE 0 END) AS TotalLossKg,
  MIN(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0) AS MinYieldPct,
  MAX(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0) AS MaxYieldPct

FROM slb.LoadJobs lj
JOIN slb.LoadQueues  lq ON lj.QueueId  = lq.QueueId
JOIN slb.OrderItems  oi ON lq.OrderItemId = oi.OrderItemId
JOIN slb.Products    p  ON oi.ProductId   = p.ProductId
JOIN slb.Bays        b  ON lj.BayId       = b.BayId
WHERE lj.Status = 'COMPLETED'
GROUP BY
  p.ProductId, p.ProductName, p.ProductCode,
  CAST(lj.CompletedAt AS DATE),
  lj.BayId, b.BayName
```

#### V10: `ana.vw_ShiftPerformance` — ประสิทธิภาพแยก Shift (ใหม่)

```sql
CREATE VIEW ana.vw_ShiftPerformance AS
SELECT
  CAST(lj.StartedAt AS DATE) AS WorkDate,
  CASE
    WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 6  AND 13 THEN 'SHIFT1'
    WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 14 AND 21 THEN 'SHIFT2'
    ELSE 'SHIFT3'
  END                         AS ShiftName,

  COUNT(*)                    AS TotalJobs,
  SUM(lj.ActualWeight / 1000.0) AS TotalActualTon,
  AVG(lj.ActualWeight / NULLIF(lj.TargetWeight, 0) * 100.0) AS AvgYieldPct,
  AVG(DATEDIFF(MINUTE, lj.StartedAt, lj.CompletedAt))       AS AvgLoadingMin,
  COUNT(CASE WHEN lj.Status = 'EMERGENCY_STOPPED' THEN 1 END) AS EmergencyCount

FROM slb.LoadJobs lj
WHERE lj.Status IN ('COMPLETED', 'EMERGENCY_STOPPED')
GROUP BY
  CAST(lj.StartedAt AS DATE),
  CASE
    WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 6  AND 13 THEN 'SHIFT1'
    WHEN DATEPART(HOUR, lj.StartedAt) BETWEEN 14 AND 21 THEN 'SHIFT2'
    ELSE 'SHIFT3'
  END
```

---

### 5.2 Stored Procedures ใน Schema `ana` (11 SPs)

| SP Code | ชื่อ | Dashboard | Input Parameters |
|---------|-----|-----------|-----------------|
| SP01 | `sp_GetPerformanceDashboard` | D1 | @DateFrom, @DateTo, @BayId (opt) |
| SP02 | `sp_GetLossYieldDashboard` | D2 | @DateFrom, @DateTo, @ProductId (opt) |
| SP03 | `sp_GetBayPerformanceDashboard` | D3 | @DateFrom, @DateTo |
| SP04 | `sp_GetTurnaroundDashboard` | D4 | @DateFrom, @DateTo, @TruckId (opt) |
| SP05 | `sp_GetProductLossAnalysis` | D5 | @DateFrom, @DateTo, @Top (default 10) |
| SP06 | `sp_GetTruckProblemReport` | D6 | @DateFrom, @DateTo, @MinIncidents (default 2) |
| SP07 | `sp_GetHourlyThroughput` | D3 | @Date, @BayId (opt) |
| SP08 | `sp_GetShiftPerformance` | D1 | @DateFrom, @DateTo |
| SP09 | `sp_GetKpiAlertHistory` | Alert Log | @DateFrom, @DateTo, @Severity (opt) |
| SP10 | `sp_GetAnalyticsConfig` | Settings | — |
| SP11 | `sp_UpdateAnalyticsConfig` | Settings | @ConfigKey, @ConfigValue, @UpdatedBy |

#### ตัวอย่าง SP01: `sp_GetPerformanceDashboard`

```sql
CREATE PROCEDURE ana.sp_GetPerformanceDashboard
  @DateFrom  DATE,
  @DateTo    DATE,
  @BayId     UNIQUEIDENTIFIER = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- Result 1: Summary KPIs
  SELECT
    SUM(TotalJobs)        AS TotalJobs,
    SUM(CompletedJobs)    AS CompletedJobs,
    SUM(CancelledJobs)    AS CancelledJobs,
    SUM(EmergencyJobs)    AS EmergencyJobs,
    SUM(TotalActualKg) / NULLIF(SUM(TotalTargetKg), 0) * 100.0 AS OverallYieldPct,
    SUM(TotalLossKg)      AS TotalLossKg,
    AVG(AccuracyPct)      AS AvgAccuracyPct,
    AVG(AvgLoadingMin)    AS OverallAvgLoadingMin,
    SUM(TotalActualKg) / 1000.0 / NULLIF(SUM(TotalJobs), 0) AS AvgTonPerJob
  FROM ana.vw_DailyPerformance
  WHERE WorkDate BETWEEN @DateFrom AND @DateTo

  -- Result 2: Daily Trend (30 rows max)
  SELECT TOP 30
    WorkDate,
    TotalJobs,
    CompletedJobs,
    TotalActualKg / 1000.0 AS TotalActualTon,
    OverallYieldPct,
    AccuracyPct,
    ThroughputTonPerHour
  FROM ana.vw_DailyPerformance
  WHERE WorkDate BETWEEN @DateFrom AND @DateTo
  ORDER BY WorkDate

  -- Result 3: Bay Summary (ถ้าไม่ระบุ BayId)
  SELECT
    BayId,
    BayName,
    SUM(TotalJobs)      AS TotalJobs,
    SUM(TotalActualTon) AS TotalActualTon,
    AVG(AvgLoadingMin)  AS AvgLoadingMin,
    AVG(BayYieldPct)    AS AvgYieldPct,
    AVG(ThroughputTonPerHour) AS AvgThroughput
  FROM ana.vw_BayPerformance
  WHERE WorkDate BETWEEN @DateFrom AND @DateTo
    AND (@BayId IS NULL OR BayId = @BayId)
  GROUP BY BayId, BayName
  ORDER BY TotalActualTon DESC
END
```

#### ตัวอย่าง SP06: `sp_GetTruckProblemReport`

```sql
CREATE PROCEDURE ana.sp_GetTruckProblemReport
  @DateFrom      DATE,
  @DateTo        DATE,
  @MinIncidents  INT = 2
AS
BEGIN
  SET NOCOUNT ON;

  -- Result 1: Problem Summary
  SELECT
    TruckId,
    LicensePlate,
    TransportCompany,
    COUNT(*)                                          AS TotalIncidents,
    SUM(CASE WHEN IncidentType = 'EMERGENCY'   THEN 1 ELSE 0 END) AS EmergencyCount,
    SUM(CASE WHEN IncidentType = 'HIGH_LOSS'   THEN 1 ELSE 0 END) AS HighLossCount,
    SUM(CASE WHEN IncidentType = 'HIGH_OVER'   THEN 1 ELSE 0 END) AS HighOverCount,
    SUM(CASE WHEN IncidentType = 'SLOW_LOADING'THEN 1 ELSE 0 END) AS SlowLoadCount
  FROM ana.vw_TruckProblemHistory
  WHERE CAST(IncidentDate AS DATE) BETWEEN @DateFrom AND @DateTo
  GROUP BY TruckId, LicensePlate, TransportCompany
  HAVING COUNT(*) >= @MinIncidents
  ORDER BY TotalIncidents DESC

  -- Result 2: Incident Timeline
  SELECT
    TruckId,
    LicensePlate,
    JobId,
    IncidentDate,
    IncidentType,
    YieldPct,
    BayName
  FROM ana.vw_TruckProblemHistory
  WHERE CAST(IncidentDate AS DATE) BETWEEN @DateFrom AND @DateTo
  ORDER BY TruckId, IncidentDate
END
```

---

### 5.3 AnalyticsConfig Table — Threshold ที่ตั้งค่าได้

```sql
-- Table นี้สร้างใน Schema ana
-- Seed Data (19 rows) สำหรับ Threshold ทั้งหมด

INSERT INTO ana.AnalyticsConfig (ConfigKey, ConfigValue, Description, Unit) VALUES
-- Yield & Loss
('YIELD_NORMAL_MIN',           '99.5',  'Yield% ต่ำสุดที่ถือว่า NORMAL',   '%'),
('YIELD_NORMAL_MAX',           '100.5', 'Yield% สูงสุดที่ถือว่า NORMAL',   '%'),
('YIELD_WARNING_MIN',          '98.0',  'Yield% ต่ำกว่านี้ = WARNING',      '%'),
('YIELD_WARNING_MAX',          '102.0', 'Yield% สูงกว่านี้ = WARNING',      '%'),
('YIELD_CRITICAL_MIN',         '97.0',  'Yield% ต่ำกว่านี้ = CRITICAL',     '%'),
('YIELD_CRITICAL_MAX',         '103.0', 'Yield% สูงกว่านี้ = CRITICAL',     '%'),

-- Loading Time
('LOADING_TIME_FAST_MAX',      '30',    'โหลดได้ใน 30 นาที = FAST',         'นาที'),
('LOADING_TIME_NORMAL_MAX',    '45',    'โหลดได้ใน 45 นาที = NORMAL',        'นาที'),
('LOADING_TIME_SLOW_MIN',      '60',    'โหลดเกิน 60 นาที = SLOW',           'นาที'),
('LOADING_TIME_CRITICAL_MIN',  '90',    'โหลดเกิน 90 นาที = CRITICAL',       'นาที'),

-- Queue Waiting
('QUEUE_WAIT_OK_MAX',          '20',    'รอใน Queue ≤ 20 นาที = OK',         'นาที'),
('QUEUE_WAIT_WARNING_MIN',     '30',    'รอ Queue เกิน 30 นาที = WARNING',   'นาที'),
('QUEUE_WAIT_CRITICAL_MIN',    '60',    'รอ Queue เกิน 60 นาที = CRITICAL',  'นาที'),

-- Turnaround
('TURNAROUND_FAST_MAX',        '60',    'Turnaround ≤ 60 นาที = FAST',       'นาที'),
('TURNAROUND_NORMAL_MAX',      '90',    'Turnaround ≤ 90 นาที = NORMAL',     'นาที'),
('TURNAROUND_SLOW_MIN',        '120',   'Turnaround เกิน 120 นาที = SLOW',   'นาที'),

-- Bay Utilization
('BAY_UTIL_LOW_MAX',           '50',    'Bay Util < 50% = LOW',              '%'),
('BAY_UTIL_GOOD_MIN',          '70',    'Bay Util ≥ 70% = GOOD',             '%'),
('BAY_UTIL_HIGH_MIN',          '85',    'Bay Util ≥ 85% = HIGH (ระวัง Overload)', '%'),

-- Throughput
('THROUGHPUT_HIGH_MIN',        '30',    'Throughput ≥ 30 t/hr = HIGH',       't/hr'),
('THROUGHPUT_NORMAL_MIN',      '20',    'Throughput ≥ 20 t/hr = NORMAL',     't/hr'),
('THROUGHPUT_LOW_MAX',         '15',    'Throughput < 15 t/hr = LOW',        't/hr'),

-- Accuracy
('ACCURACY_GOOD_MIN',          '90',    'Accuracy ≥ 90% = GOOD',             '%'),
('ACCURACY_OK_MIN',            '80',    'Accuracy ≥ 80% = OK',               '%'),
('ACCURACY_POOR_MAX',          '70',    'Accuracy < 70% = POOR',             '%'),

-- Working Hours (สำหรับคำนวณ Bay Utilization)
('WORKING_HOURS_PER_DAY',      '16',    'ชั่วโมงทำงานต่อวัน',               'ชม'),

-- Problem Truck
('PROBLEM_TRUCK_MIN_INCIDENTS','2',     'จำนวนครั้งขั้นต่ำที่ถือว่า Problem Truck', 'ครั้ง')
```

---

## ส่วนที่ 6 — Alert Threshold และ Severity Logic

### 6.1 Yield Alert

| Condition | Severity | Action | Icon |
|-----------|---------|--------|------|
| 99.5% ≤ Yield ≤ 100.5% | NORMAL | ไม่มี | 🟢 |
| 98.0% ≤ Yield < 99.5% | WARNING | Notification Log | 🟡 |
| 100.5% < Yield ≤ 102.0% | WARNING | Notification Log | 🟡 |
| Yield < 98.0% | CRITICAL | Alert + SignalR Broadcast | 🔴 |
| Yield > 102.0% | CRITICAL | Alert + SignalR Broadcast | 🔴 |

### 6.2 Loading Time Alert

| Condition | Severity | Action |
|-----------|---------|--------|
| ≤ 30 นาที | FAST | ไม่มี |
| 31–45 นาที | NORMAL | ไม่มี |
| 46–60 นาที | SLOW | แสดงใน Dashboard (ไม่ Alert) |
| 61–90 นาที | WARNING | Notification Log |
| > 90 นาที | CRITICAL | Alert + SignalR |

### 6.3 Queue Waiting Time Alert

| Condition | Severity | Action |
|-----------|---------|--------|
| ≤ 20 นาที | OK | ไม่มี |
| 21–30 นาที | ACCEPTABLE | แสดงใน Dashboard |
| 31–60 นาที | WARNING | Notification Log |
| > 60 นาที | CRITICAL | Alert + SignalR |

### 6.4 Bay Utilization Alert

| Condition | Severity | คำอธิบาย |
|-----------|---------|---------|
| < 50% | LOW | Bay ว่างมาก — พิจารณาจัด Queue ใหม่ |
| 50–70% | NORMAL | ปกติ |
| 70–85% | GOOD | ประสิทธิภาพดี |
| > 85% | HIGH | ระวัง Overload — Bay อาจเป็นคอขวด |

### 6.5 Truck Turnaround Alert

| Condition | Severity | Action |
|-----------|---------|--------|
| ≤ 60 นาที | FAST | ไม่มี |
| 61–90 นาที | NORMAL | ไม่มี |
| 91–120 นาที | SLOW | แสดงใน Dashboard |
| > 120 นาที | WARNING | Notification Log |

### 6.6 Loss Alert (Per Job — ทันที)

```
ทุก Job ที่ Complete → คำนวณ YieldPct → เปรียบกับ Threshold
If YieldPct < YIELD_WARNING_MIN:
    → บันทึก NotificationLog (LOSS_ALERT, WARNING)
    → SignalR AnalyticsHub.OnLossAlert(jobId, lossKg, yieldPct)

If YieldPct < YIELD_CRITICAL_MIN:
    → บันทึก NotificationLog (LOSS_ALERT, CRITICAL)
    → SignalR AnalyticsHub.OnLossAlert(jobId, lossKg, yieldPct)
    → แสดง Alert Banner บนทุกหน้า
```

### 6.7 Throughput Alert

| Condition | Severity | Action |
|-----------|---------|--------|
| ≥ 30 t/hr | HIGH | ไม่มี |
| 20–30 t/hr | NORMAL | ไม่มี |
| 15–20 t/hr | LOW | แสดงใน Dashboard |
| < 15 t/hr | CRITICAL | Alert + Notification Log |

### 6.8 Problem Truck Alert (Batch — ทุก 1 ชั่วโมง)

```
Background Service KpiAlertService ทำงานทุก 15 นาที:

1. นับ Incident ต่อรถใน 7 วันล่าสุด
2. ถ้า Count ≥ PROBLEM_TRUCK_MIN_INCIDENTS (default = 2):
   → บันทึก NotificationLog (PROBLEM_TRUCK, WARNING)
   → SignalR AnalyticsHub.OnKpiAlert("PROBLEM_TRUCK", count, threshold)
```

---

## ส่วนที่ 7 — Phase การพัฒนา Analytics

### Phase A: Core Analytics Database (2 สัปดาห์)

**งาน Shuri:**
- [ ] สร้าง Schema `ana` ใน SmartLoadBulkDB
- [ ] สร้าง Table `ana.AnalyticsConfig` + Seed Data (27 rows)
- [ ] สร้าง Views V01–V10 ทั้งหมด
- [ ] สร้าง Stored Procedures SP01–SP11
- [ ] เพิ่ม Index บน slb Tables:
  ```sql
  CREATE INDEX IX_LoadJobs_CompletedAt   ON slb.LoadJobs (CompletedAt, Status)
  CREATE INDEX IX_LoadJobs_StartedAt     ON slb.LoadJobs (StartedAt, BayId)
  CREATE INDEX IX_LoadJobs_TruckId       ON slb.LoadJobs (TruckId, Status)
  CREATE INDEX IX_LoadJobs_QueueId       ON slb.LoadJobs (QueueId)
  CREATE INDEX IX_LoadQueues_CalledAt    ON slb.LoadQueues (CalledAt, Status)
  CREATE INDEX IX_LoadQueues_CreatedAt   ON slb.LoadQueues (CreatedAt)
  CREATE INDEX IX_BayLogs_EventTime      ON slb.BayLogs (BayId, EventType, EventTime)
  ```
- [ ] ทดสอบ Query Performance (ทุก SP ต้องเสร็จใน < 2 วินาที)
- [ ] เขียน Test Data สำหรับ Analytics (เพิ่ม LoadJobs 100+ rows พร้อม Variance)

**ผลลัพธ์:** SQL Script `db/003_create_analytics_objects.sql` พร้อมรัน

---

### Phase B: Analytics API Backend (1.5 สัปดาห์)

**งาน Iron Man (Backend):**

```csharp
// AnalyticsController endpoints:
GET  /api/analytics/performance          → SP01 (+ Query Params)
GET  /api/analytics/loss-yield           → SP02
GET  /api/analytics/bay-performance      → SP03
GET  /api/analytics/turnaround           → SP04
GET  /api/analytics/product-loss         → SP05
GET  /api/analytics/truck-problems       → SP06
GET  /api/analytics/hourly-throughput    → SP07
GET  /api/analytics/shift-performance    → SP08
GET  /api/analytics/alert-history        → SP09
GET  /api/analytics/config               → SP10
PUT  /api/analytics/config               → SP11
```

**Query Parameters Standard:**
```
?from=2026-05-01&to=2026-05-13   ← Date range (required)
&bayId=...                        ← Filter by Bay (optional)
&productId=...                    ← Filter by Product (optional)
&truckId=...                      ← Filter by Truck (optional)
&top=10                           ← Limit results (optional)
```

**AnalyticsHub (SignalR):**
- [ ] `KpiAlertService` Background Service — ทุก 15 นาที
- [ ] `OnKpiAlert(kpiCode, value, threshold, severity)` → Broadcast
- [ ] `OnLossAlert(jobId, lossKg, yieldPct, severity)` → Broadcast on Job Complete
- [ ] `OnDashboardRefresh(summary)` → Broadcast ทุก 1 ชั่วโมง

---

### Phase C: Analytics Dashboard UI (2 สัปดาห์)

**งาน Iron Man (Frontend) + Spider-Man (Design Review):**

```
สัปดาห์ 1: Dashboard 1-3
  - D1: Performance Overview (/analytics)
  - D2: Loss/Yield Analysis (/analytics/loss-yield)
  - D3: Bay Performance (/analytics/bay)

สัปดาห์ 2: Dashboard 4-6 + Alert System
  - D4: Truck Turnaround (/analytics/turnaround)
  - D5: Product Loss Analysis (/analytics/product)
  - D6: Truck Problem Report (/analytics/truck-problem)
  - Alert Banner Component
  - SignalR Subscribe สำหรับ AnalyticsHub
```

**React Component Structure:**

```
src/
├── pages/analytics/
│   ├── PerformanceOverviewPage.tsx
│   ├── LossYieldPage.tsx
│   ├── BayPerformancePage.tsx
│   ├── TurnaroundPage.tsx
│   ├── ProductLossPage.tsx
│   └── TruckProblemPage.tsx
│
├── components/analytics/
│   ├── KpiCard.tsx               ← ตัวเลข + Trend + Badge
│   ├── KpiCardGrid.tsx           ← Grid ของ KPI Cards
│   ├── YieldGauge.tsx            ← Gauge Chart (Recharts RadialBar)
│   ├── TrendLineChart.tsx        ← Line Chart + Threshold Lines
│   ├── LossAreaChart.tsx         ← Area Chart (Loss/Over)
│   ├── BayHeatmap.tsx            ← CSS Grid Heatmap (Hour × Bay)
│   ├── TurnaroundStackedBar.tsx  ← Stacked Bar (Time Breakdown)
│   ├── ProductLossBar.tsx        ← Horizontal Bar (Loss Rank)
│   ├── ProductScatter.tsx        ← Scatter (Yield vs Variance)
│   ├── TruckProblemBar.tsx       ← Grouped Bar (Emergency/Loss per Truck)
│   ├── IncidentTimeline.tsx      ← Timeline Chart (Custom)
│   ├── AlertBanner.tsx           ← Full-width alert strip
│   ├── DateRangeFilter.tsx       ← Preset + Custom DatePicker
│   └── AnalyticsTable.tsx        ← Reusable sortable table
│
├── hooks/
│   ├── useAnalyticsHub.ts        ← SignalR AnalyticsHub subscription
│   ├── usePerformanceData.ts     ← Fetch + cache analytics data
│   └── useKpiStatus.ts           ← Compare value vs threshold → status
│
└── store/
    └── useAnalyticsStore.ts      ← Zustand store for analytics state
```

---

### Phase D: Alert & Notification System (1 สัปดาห์)

**งาน Iron Man:**

```csharp
public class KpiAlertService : BackgroundService
{
    // ทำงานทุก 15 นาที
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(TimeSpan.FromMinutes(15), stoppingToken);

            // 1. ดึง Config Thresholds จาก DB
            var config = await _analyticsRepo.GetConfigAsync();

            // 2. ตรวจ Bay Utilization (วันนี้)
            var bayData = await _analyticsRepo.GetTodayBayPerformanceAsync();
            foreach (var bay in bayData)
            {
                if (bay.UtilizationPct < config.BayUtilLowMax)
                    await _hub.OnKpiAlert("BAY_UTIL_LOW", bay.UtilizationPct,
                                         config.BayUtilLowMax, "WARNING");
            }

            // 3. ตรวจ Queue Waiting (ชั่วโมงที่แล้ว)
            var avgWait = await _analyticsRepo.GetAvgQueueWaitAsync(1);
            if (avgWait > config.QueueWaitCriticalMin)
                await _hub.OnKpiAlert("QUEUE_WAIT", avgWait,
                                     config.QueueWaitCriticalMin, "CRITICAL");

            // 4. ตรวจ Problem Trucks (7 วัน)
            var problemTrucks = await _analyticsRepo.GetProblemTrucksAsync(7);
            if (problemTrucks.Any())
                await _hub.OnKpiAlert("PROBLEM_TRUCK",
                                      problemTrucks.Count, config.ProblemTruckMin, "WARNING");
        }
    }
}

// Loss Alert — ทำทันทีเมื่อ Job Complete (ใน LoadingService)
public async Task CompleteJobAsync(Guid jobId, decimal actualWeight)
{
    var job = await _repo.GetJobAsync(jobId);
    var yieldPct = actualWeight / job.TargetWeight * 100;

    if (yieldPct < config.YieldCriticalMin || yieldPct > config.YieldCriticalMax)
    {
        await _notifRepo.CreateAsync(new NotificationLog {
            Type = "LOSS_ALERT", Severity = "CRITICAL",
            Message = $"Job {jobId}: Yield {yieldPct:F1}% (Critical)"
        });
        await _analyticsHub.OnLossAlert(jobId, actualWeight - job.TargetWeight, yieldPct);
    }
}
```

---

### Phase E: Export & Report (1 สัปดาห์)

**งาน Iron Man:**
- [ ] `GET /api/analytics/export/excel` → ClosedXML หรือ EPPlus
  - Sheet 1: Summary KPIs
  - Sheet 2: Daily Trend
  - Sheet 3: Job Detail
  - Sheet 4: Loss Analysis
- [ ] `GET /api/analytics/export/pdf` → DinkToPdf หรือ Puppeteer (HTML → PDF)
- [ ] ปุ่ม Export ใน Dashboard (โหลด Progress → Download)

---

## ส่วนที่ 8 — ข้อมูลที่ต้องใช้จากระบบ

### Source Tables (slb Schema)

| Table | Field ที่ใช้ | ใช้สำหรับ |
|-------|------------|---------|
| `slb.LoadJobs` | JobId, BayId, QueueId, TruckId, StartedAt, CompletedAt, Status, TargetWeight, ActualWeight | ทุก KPI |
| `slb.LoadQueues` | QueueId, OrderId, OrderItemId, CreatedAt, CalledAt, CompletedAt, Status, Priority | K16, Waiting Time |
| `slb.Orders` | OrderId, CustomerId, OrderNumber, CreatedAt | Customer Analysis |
| `slb.OrderItems` | OrderItemId, OrderId, ProductId, OrderedQty | Target Weight, Product |
| `slb.Products` | ProductId, ProductName, ProductCode | Product Analysis |
| `slb.Bays` | BayId, BayName | Bay Performance |
| `slb.BayLogs` | BayId, EventType, EventTime | Turnaround (TRUCK_ARRIVED/DEPARTED) |
| `slb.Trucks` | TruckId, LicensePlate, TruckType, OwnerName, Capacity | Truck Analysis |
| `slb.Drivers` | DriverId, FullName | Driver Association |
| `slb.TruckDriverMap` | TruckId, DriverId, IsPrimary | Primary Driver |
| `slb.HardwareEvents` | EventType, EventTime, BayId | Emergency Stop events |
| `slb.NotificationLogs` | Type, Severity, CreatedAt | Alert History |
| `slb.AuditLogs` | Action, EntityId, CreatedAt | Audit Trail |

### Fields ที่ต้องมีใน `slb.LoadJobs` (สำคัญมาก)

```sql
-- Fields เหล่านี้ต้องมีใน LoadJobs table:
JobId         UNIQUEIDENTIFIER NOT NULL  -- PK
BayId         UNIQUEIDENTIFIER NOT NULL  -- FK → Bays
QueueId       UNIQUEIDENTIFIER NOT NULL  -- FK → LoadQueues
TruckId       UNIQUEIDENTIFIER NOT NULL  -- FK → Trucks
StartedAt     DATETIME2 NOT NULL         -- เวลาเริ่ม Loading
CompletedAt   DATETIME2 NULL             -- เวลา Complete (NULL ถ้ายังไม่เสร็จ)
Status        NVARCHAR(30) NOT NULL      -- IN_PROGRESS/COMPLETED/CANCELLED/EMERGENCY_STOPPED
TargetWeight  DECIMAL(10,3) NOT NULL     -- น้ำหนักเป้าหมาย (kg)
ActualWeight  DECIMAL(10,3) NULL         -- น้ำหนักจริง (NULL ถ้ายังไม่เสร็จ)
```

### Data Quality Requirements

| ปัญหา | ผลกระทบ | วิธีแก้ |
|-------|--------|--------|
| ActualWeight = NULL เมื่อ Job ยังไม่ Complete | Yield คำนวณไม่ได้ | WHERE Status = 'COMPLETED' ใน Views |
| CompletedAt = NULL | Duration คำนวณไม่ได้ | ISNULL + Fallback |
| ไม่มี BayLog TRUCK_ARRIVED | Turnaround คำนวณไม่ได้ | LEFT JOIN + แสดง N/A |
| TargetWeight = 0 | Division by Zero | NULLIF(TargetWeight, 0) ทุกที่ |
| LoadJob ไม่มี TruckId | ไม่สามารถ Map Truck | FK Constraint บังคับ |

---

## ส่วนที่ 9 — งานที่ต้องส่งต่อ (Handoff)

### Shuri — งาน Database

**งานทันที (Phase A):**
```
1. สร้าง db/003_create_analytics_objects.sql
   ├── CREATE SCHEMA ana (ถ้ายังไม่มี)
   ├── CREATE TABLE ana.AnalyticsConfig (+ 27 row seed data)
   ├── CREATE OR ALTER VIEW ana.vw_JobPerformance
   ├── CREATE OR ALTER VIEW ana.vw_QueuePerformance
   ├── CREATE OR ALTER VIEW ana.vw_DailyPerformance
   ├── CREATE OR ALTER VIEW ana.vw_BayPerformance
   ├── CREATE OR ALTER VIEW ana.vw_ProductLossYield
   ├── CREATE OR ALTER VIEW ana.vw_TruckTurnaround
   ├── CREATE OR ALTER VIEW ana.vw_HourlyThroughput
   ├── CREATE OR ALTER VIEW ana.vw_TruckProblemHistory  (ใหม่)
   ├── CREATE OR ALTER VIEW ana.vw_FormulaLossAnalysis  (ใหม่)
   ├── CREATE OR ALTER VIEW ana.vw_ShiftPerformance      (ใหม่)
   ├── CREATE PROCEDURE ana.sp_GetPerformanceDashboard
   ├── CREATE PROCEDURE ana.sp_GetLossYieldDashboard
   ├── CREATE PROCEDURE ana.sp_GetBayPerformanceDashboard
   ├── CREATE PROCEDURE ana.sp_GetTurnaroundDashboard
   ├── CREATE PROCEDURE ana.sp_GetProductLossAnalysis
   ├── CREATE PROCEDURE ana.sp_GetTruckProblemReport     (ใหม่)
   ├── CREATE PROCEDURE ana.sp_GetHourlyThroughput       (ใหม่)
   ├── CREATE PROCEDURE ana.sp_GetShiftPerformance       (ใหม่)
   ├── CREATE PROCEDURE ana.sp_GetKpiAlertHistory        (ใหม่)
   ├── CREATE PROCEDURE ana.sp_GetAnalyticsConfig
   ├── CREATE PROCEDURE ana.sp_UpdateAnalyticsConfig
   └── CREATE INDEX (7 indexes บน slb tables)

2. เพิ่ม Test Data ใน db/001:
   - LoadJobs 100+ rows (ครอบคลุมทุก Status, หลาย Bay, หลาย Product)
   - มี Variance ของ Yield (บาง Job Loss, บาง Job Normal, บาง Job Over)
   - มี Emergency Stop อย่างน้อย 5 rows
   - มี BayLogs (TRUCK_ARRIVED, TRUCK_DEPARTED) ครบ

3. ทดสอบ Performance:
   - ทุก SP เสร็จใน < 2 วินาที สำหรับข้อมูล 1 ปี (≈ 50,000 jobs)
   - EXPLAIN PLAN / Execution Plan ผ่าน
```

---

### Spider-Man — งาน UI/UX Design

**งานทันที:**
```
1. ออกแบบ Wireframe 6 หน้า Dashboard:
   - D1: Performance Overview (/analytics) — ดู Section 3 ด้านบน
   - D2: Loss/Yield Analysis (/analytics/loss-yield)
   - D3: Bay Performance (/analytics/bay)
   - D4: Truck Turnaround (/analytics/turnaround)
   - D5: Product Loss Analysis (/analytics/product)
   - D6: Truck Problem Report (/analytics/truck-problem)

2. ออกแบบ KPI Card Component:
   - Layout: Icon | Label | Value (ตัวเลขใหญ่) | Trend | Status Badge
   - States: Normal (green), Warning (amber), Critical (red + pulse)

3. ออกแบบ AlertBanner Component:
   - Full-width strip สีแดง/เหลือง (ขึ้นอยู่กับ Severity)
   - ข้อความ Alert + Dismiss Button
   - Stack ได้ถ้ามีหลาย Alert

4. ออกแบบ BayHeatmap:
   - Grid: Hour (X-axis 06-22) × Bay (Y-axis)
   - Color: Green=Loading, Gray=Idle, LightBlue=Checklist
   - Interactive: hover แสดง detail

5. Design Tokens เพิ่มเติม:
   - STATUS_NORMAL = green-600
   - STATUS_WARNING = amber-500
   - STATUS_CRITICAL = red-600 + animate-pulse
   - CHART_LOSS = red-400
   - CHART_OVER = orange-400
   - CHART_YIELD = blue-500

6. บันทึกไว้ที่ docs/UI_UX_DESIGN_ANALYTICS.md
```

---

### Iron Man — งาน Code

**Phase B — Backend (1.5 สัปดาห์):**
```
1. สร้าง IAnalyticsRepository + AnalyticsRepository
   - Map EF Core → SP result sets (DbCommand + FromSqlRaw หรือ Dapper)
   - DTOs: PerformanceDashboardDto, LossYieldDashboardDto, BayPerformanceDto...

2. สร้าง IAnalyticsService + AnalyticsService
   - Business logic: เรียก SP + ประมอบ Response

3. สร้าง AnalyticsController
   - 11 Endpoints ตาม spec
   - Query param validation + Date range max 1 ปี

4. สร้าง KpiAlertService (BackgroundService)
   - ตาม spec ใน Phase D
   - Inject AnalyticsHub

5. เพิ่ม OnLossAlert ใน LoadingService.CompleteJobAsync()
   - ทันทีเมื่อ Job Complete + Yield ผิดปกติ
```

**Phase C — Frontend (2 สัปดาห์):**
```
1. สร้าง analytics service layer:
   - src/services/analyticsService.ts (11 endpoints)

2. สร้าง Zustand store:
   - src/store/useAnalyticsStore.ts

3. สร้าง Custom Hooks:
   - useAnalyticsHub.ts (SignalR)
   - usePerformanceData.ts
   - useKpiStatus.ts (threshold comparison)

4. สร้าง Components ทั้งหมดตาม Component Structure ด้านบน

5. สร้าง 6 Analytics Pages

6. เพิ่ม AlertBanner ใน App Layout (subscribe AnalyticsHub)
```

**Phase E — Export:**
```
1. Backend: ClosedXML สำหรับ Excel, DinkToPdf สำหรับ PDF
2. Frontend: ปุ่ม Export พร้อม Loading state
```

---

## ข้อสังเกตสำคัญสำหรับ Developer

### 1. Yield vs Loss — นิยามให้ชัด

```
TargetWeight = น้ำหนักที่ Order สั่ง (from OrderItems.OrderedQty)
ActualWeight = น้ำหนักที่ชั่งได้จริง (from LoadJobs.ActualWeight)

Yield% = (Actual / Target) × 100
  - 100% = โหลดตรงเป๊ะ
  - < 100% = ขาดน้ำหนัก (Loss)
  - > 100% = เกินน้ำหนัก (Over)

Loss (kg) = Target - Actual  เมื่อ Actual < Target  (เป็นบวกเสมอ)
Over (kg) = Actual - Target  เมื่อ Actual > Target  (เป็นบวกเสมอ)
Diff (kg) = Actual - Target                          (ติดลบ=Loss, บวก=Over)
```

### 2. Turnaround Time — เส้นเวลา

```
[Queue Created] → [Truck Called] → [Truck Arrives] → [Loading Start] → [Loading Done] → [Truck Departs]
    ↑                   ↑                ↑                  ↑                 ↑               ↑
 QueueCreatedAt     CalledAt         ArrivalTime         StartedAt        CompletedAt    DepartureTime
                  ←────────────── Queue Wait ──────────────→
                                   ←────── Docking ─────→
                                                         ←── Loading ──→
                                                                          ←── Checklist──→
                  ←──────────────────── Turnaround Time ─────────────────────────────────→
```

### 3. Bay Utilization — WorkingHours

```
BayUtilization = TotalLoadingMinutes / (WorkingHoursPerDay × 60) × 100

WorkingHoursPerDay มาจาก ana.AnalyticsConfig → ConfigKey = 'WORKING_HOURS_PER_DAY'
Default = 16 ชั่วโมง (06:00–22:00)

ถ้า Bay ทำงาน 3 Shift = 24 ชั่วโมง → เปลี่ยน Config ได้จาก UI
```

### 4. Performance Test Targets

| Operation | Target Response | Acceptable |
|-----------|----------------|-----------|
| SP01 GetPerformanceDashboard (1 ปี) | < 1s | < 2s |
| SP02 GetLossYieldDashboard (1 ปี) | < 1s | < 2s |
| SP03 GetBayPerformanceDashboard (1 เดือน) | < 500ms | < 1s |
| SignalR OnLossAlert (per job) | < 50ms | < 100ms |
| Dashboard Page Load (API + Render) | < 2s | < 3s |

---

## Summary — สิ่งที่ออกแบบเสร็จแล้ว

| # | รายการ | สถานะ |
|---|--------|--------|
| 1 | KPI ทั้งหมด 25 ตัว (5 กลุ่ม) | ✅ |
| 2 | สูตรคำนวณพร้อม SQL ทุก KPI | ✅ |
| 3 | 6 Dashboard พร้อม Layout | ✅ |
| 4 | Chart Type ต่อ Dashboard | ✅ |
| 5 | 10 Views (SQL ครบ V01-V10) | ✅ |
| 6 | 11 Stored Procedures (Spec ครบ) | ✅ |
| 7 | 27 Alert Threshold Config Rows | ✅ |
| 8 | 7 Alert Severity Rules | ✅ |
| 9 | 5-Phase Development Plan | ✅ |
| 10 | Data Requirements + Field Mapping | ✅ |
| 11 | Handoff Tasks: Shuri / Spider-Man / Iron Man | ✅ |

---

*Performance Analytics Plan V2.0 — Hawkeye — 2026-05-13*  
*25 KPIs | 6 Dashboards | 10 Views | 11 SPs | 27 Thresholds | 3-Agent Handoff*
