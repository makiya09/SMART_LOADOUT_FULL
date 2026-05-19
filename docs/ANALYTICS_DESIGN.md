# ANALYTICS DESIGN — Performance Analytics & Loss/Yield

**ออกแบบโดย:** Hawkeye  
**วันที่:** 2026-05-13  
**Version:** 1.0  
**อ้างอิง:** docs/PROJECT_CONTEXT.md § 7, docs/DATABASE_DESIGN.md

---

## ภาพรวม

```
ข้อมูลดิบ (slb Schema)
  └── slb.LoadJobs        ← Target/Actual Weight, Timing
  └── slb.LoadJobLogs     ← Weight timeline ระหว่างโหลด
  └── slb.LoadQueues      ← Wait/Call/Dock/Complete time
  └── slb.Bays            ← Bay assignment
  └── slb.Products        ← Product info
  └── slb.Trucks/Drivers  ← Truck/Driver info

          ↓ Transform via ana Views

Analytics Layer (ana Schema)
  └── ana.vw_JobPerformance       ← Per-job KPI ทุกตัว
  └── ana.vw_QueuePerformance     ← Timing per Queue
  └── ana.vw_DailyPerformance     ← Summary รายวัน
  └── ana.vw_BayPerformance       ← Bay utilization รายวัน
  └── ana.vw_ProductLossYield     ← Loss/Yield รายสินค้า
  └── ana.vw_TruckTurnaround      ← Turnaround รายรถ
  └── ana.AnalyticsConfig         ← Threshold ตั้งค่าได้

          ↓ Exposed via Stored Procedures

Dashboard API
  └── ana.sp_GetPerformanceDashboard
  └── ana.sp_GetLossYieldDashboard
  └── ana.sp_GetBayPerformanceDashboard
  └── ana.sp_GetTurnaroundDashboard
  └── ana.sp_GetProductLossAnalysis
```

---

## 1. KPI ทั้งหมด 17 ตัว — พร้อมสูตรและแหล่งข้อมูล

### กลุ่มที่ 1 — Volume KPIs (ปริมาณ)

| # | KPI | สูตร | แหล่งข้อมูล | หน่วย |
|---|-----|------|------------|-------|
| K01 | **Total Trucks** | `COUNT(QueueId)` | slb.LoadQueues | คัน |
| K02 | **Completed Trucks** | `COUNT WHERE Status='DONE'` | slb.LoadQueues | คัน |
| K03 | **Waiting Queue** | `COUNT WHERE Status='WAITING'` | slb.LoadQueues | คัน |
| K04 | **Loading Now** | `COUNT WHERE Status='LOADING'` | slb.LoadQueues | คัน |
| K05 | **Total Target Weight** | `SUM(TargetWeight)` | slb.LoadJobs | กก. |
| K06 | **Total Actual Weight** | `SUM(ActualWeight)` | slb.LoadJobs (COMPLETED) | กก. |

### กลุ่มที่ 2 — Loss / Yield KPIs (ความแม่นยำ)

| # | KPI | สูตร | แหล่งข้อมูล | หน่วย |
|---|-----|------|------------|-------|
| K07 | **Diff Kg** | `SUM(Actual) - SUM(Target)` | slb.LoadJobs | กก. |
| K08 | **Diff %** | `(SUM(Actual) - SUM(Target)) / SUM(Target) × 100` | slb.LoadJobs | % |
| K09 | **Loss Kg** | `SUM(Target - Actual) WHERE Actual < Target` | slb.LoadJobs | กก. |
| K10 | **Over Kg** | `SUM(Actual - Target) WHERE Actual > Target` | slb.LoadJobs | กก. |
| K11 | **Yield %** | `SUM(Actual) / SUM(Target) × 100` | slb.LoadJobs | % |
| K12 | **Loading Accuracy %** | `COUNT(IsAccurate=1) / COUNT(*) × 100` | slb.LoadJobs | % |

> **IsAccurate** = `ABS(DiffKg / Target × 100) <= TolerancePct`

### กลุ่มที่ 3 — Time / Efficiency KPIs (ประสิทธิภาพเวลา)

| # | KPI | สูตร | แหล่งข้อมูล | หน่วย |
|---|-----|------|------------|-------|
| K13 | **Avg Loading Time** | `AVG(DATEDIFF(MIN, StartedAt, CompletedAt))` | slb.LoadJobs | นาที |
| K14 | **Avg Waiting Time** | `AVG(DATEDIFF(MIN, EnqueuedAt, CalledAt))` | slb.LoadQueues | นาที |
| K15 | **Truck Turnaround Time** | `AVG(DATEDIFF(MIN, EnqueuedAt, CompletedAt))` | slb.LoadQueues | นาที |
| K16 | **Throughput (ton/hr)** | `SUM(Actual Ton) / SUM(LoadingMinutes / 60)` | slb.LoadJobs | ตัน/ชม. |
| K17 | **Bay Utilization %** | `SUM(LoadingMinutes) / (24×60) × 100` ต่อ Bay | slb.LoadJobs + Bays | % |

---

## 2. Threshold — เกณฑ์ตัดสิน (ตั้งค่าได้ใน `ana.AnalyticsConfig`)

### Yield % Threshold

```
✅ NORMAL (เขียว)   :  99.50% ≤ Yield ≤ 100.50%
⚠️ WARNING (เหลือง) :  99.00% ≤ Yield < 99.50%  หรือ  100.50% < Yield ≤ 101.00%
🔴 CRITICAL (แดง)   :  Yield < 99.00%  หรือ  Yield > 101.00%
```

### Loading Accuracy % Threshold

```
✅ GOOD    : Accuracy ≥ 95%
⚠️ WARNING : 85% ≤ Accuracy < 95%
🔴 POOR    : Accuracy < 85%
```

### Loading Time Threshold

```
✅ FAST    : ≤ 45 นาที
⚠️ NORMAL  : 45–60 นาที
🔴 SLOW    : > 60 นาที
```

### Waiting Time Threshold

```
✅ OK      : ≤ 20 นาที
⚠️ LONG    : 20–30 นาที
🔴 TOO LONG: > 30 นาที
```

### Turnaround Time Threshold

```
✅ FAST    : ≤ 90 นาที
⚠️ NORMAL  : 90–120 นาที
🔴 SLOW    : > 120 นาที
```

### Bay Utilization Threshold

```
✅ GOOD        : 70%–85%
⚠️ UNDERUSED   : < 70%
⚠️ OVERLOADED  : > 85%
```

### Throughput Threshold

```
✅ HIGH   : ≥ 25 ตัน/ชม.
⚠️ NORMAL : 15–25 ตัน/ชม.
🔴 LOW    : < 15 ตัน/ชม.
```

### Loss Alert Threshold

```
🔴 ALERT  : Loss% > 0.50% ต่องาน (เกิน Tolerance)
📧 NOTIFY : Loss รายวัน > 500 กก. → แจ้ง Supervisor
```

---

## 3. Dashboard ที่ต้องมี (5 หน้า)

### Dashboard 1 — Performance Overview (`/analytics`)

```
┌────────────────────────────────────────────────────────────────────────┐
│  📊 Performance Overview                    วันที่: 13/05/69           │
│  Filter: [วันนี้ ▾]  [ทุก Bay ▾]  [ทุกสินค้า ▾]                       │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐     │
│  │ Total Jobs  │ │ Total Actual│ │  Yield %    │ │ Accuracy %  │     │
│  │     12      │ │ 285.5 ตัน  │ │  99.82% ✅  │ │  91.7% ⚠️   │     │
│  │  วันนี้     │ │ / 286.0 ตัน│ │  NORMAL     │ │  WARNING    │     │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘     │
│                                                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐     │
│  │  Loss Kg    │ │   Over Kg   │ │ Avg Load    │ │ Throughput  │     │
│  │   −120 kg   │ │   +370 kg   │ │  Time       │ │  Ton/Hr     │     │
│  │  ⚠️ 2 งาน   │ │  ⚠️ 4 งาน   │ │   47 min    │ │   22.4      │     │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘     │
│                                                                        │
│  ┌────────────────────────────────┐ ┌───────────────────────────────┐  │
│  │  Yield % Trend (7 วัน)         │ │  Throughput by Bay (วันนี้)   │  │
│  │  101% ─────────────────────    │ │                               │  │
│  │  100%  ───╮  ╭──────────────   │ │  BAY-01  ████████████  24.1  │  │
│  │   99%  ╯  ╰──                  │ │  BAY-02  ██████████    19.8  │  │
│  │   98% ─────────────────────    │ │  BAY-03  █████████     18.2  │  │
│  │        07 08 09 10 11 12 13   │ │  BAY-04  ████████      15.9  │  │
│  └────────────────────────────────┘ └───────────────────────────────┘  │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  Job Summary วันนี้                                             │    │
│  │  Job Code    │ Bay  │ สินค้า   │ Target │ Actual │ Diff  │ สถานะ│   │
│  │  JOB-001     │ B01  │ ข้าว     │ 25,000 │ 25,050 │ +50 ✅│ DONE │   │
│  │  JOB-002     │ B02  │ น้ำตาล  │ 20,000 │ 19,880 │−120 ⚠│ DONE │   │
│  └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
```

**API:** `GET /api/analytics/performance?dateFrom=&dateTo=&bayId=&productId=`  
**SP:** `ana.sp_GetPerformanceDashboard`

---

### Dashboard 2 — Loss / Yield Dashboard (`/analytics/loss-yield`)

```
┌────────────────────────────────────────────────────────────────────────┐
│  📉 Loss / Yield Dashboard             Filter: [สัปดาห์นี้ ▾]          │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │  Total Loss  │ │  Total Over  │ │  Net Diff    │ │  Avg Yield%  │  │
│  │  −620 kg     │ │  +1,840 kg   │ │  +1,220 kg   │ │  99.96% ✅  │  │
│  │  6 งาน       │ │  14 งาน      │ │  ↑ ดีขึ้น     │ │              │  │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │
│                                                                        │
│  ┌─────────────────────────────────┐  ┌───────────────────────────┐   │
│  │  Loss vs Over รายวัน (Stacked)  │  │  Yield % Gauge             │   │
│  │  2000 ─────────────────────     │  │                            │   │
│  │  1000 ─ ████ ███ ██ ████ ███    │  │       99.96%               │   │
│  │     0 ─ ─────────────────────   │  │   ╭──────────────╮         │   │
│  │ -500  ─ ▓▓▓ ▓▓▓ ▓  ▓▓▓  ▓▓     │  │  ╯ ████████████ ╰        │   │
│  │        07 08 09 10 11 12       │  │   ▲ 99.5%  ▲ 100.5%        │   │
│  │  ██ Over  ▓▓ Loss              │  │   WARNING  WARNING          │   │
│  └─────────────────────────────────┘  └───────────────────────────┘   │
│                                                                        │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │  สินค้าที่มี Loss สูงสุด (Top 5)                               │     │
│  │                                                               │     │
│  │  เกลือสมุทร   ████████████████████  Loss: 280 kg  (1.82%) 🔴 │     │
│  │  น้ำตาลทราย  ████████████           Loss: 195 kg  (0.72%) ⚠️ │     │
│  │  ข้าวโพด      ████████               Loss: 145 kg  (0.51%) ⚠️ │     │
│  │  ข้าวเปลือก   ████                   Loss: 90 kg   (0.18%) ✅ │     │
│  └───────────────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────────────┘
```

**API:** `GET /api/analytics/loss-yield?dateFrom=&dateTo=`  
**SP:** `ana.sp_GetLossYieldDashboard`

---

### Dashboard 3 — Bay Performance Dashboard (`/analytics/bay`)

```
┌────────────────────────────────────────────────────────────────────────┐
│  🏭 Bay Performance Dashboard          Filter: [เดือนนี้ ▾]             │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌────────────────────┐ ┌────────────────────┐ ┌────────────────────┐  │
│  │  BAY-01            │ │  BAY-02            │ │  BAY-03            │  │
│  │  Utilization       │ │  Utilization       │ │  Utilization       │  │
│  │  ████████████ 78% ✅│ │  ████████████ 82% ✅│ │  ████████░░░ 61% ⚠│  │
│  │  Jobs: 48          │ │  Jobs: 52          │ │  Jobs: 38          │  │
│  │  Yield: 99.9% ✅   │ │  Yield: 99.7% ✅   │ │  Yield: 98.8% 🔴  │  │
│  │  Avg Time: 44 min  │ │  Avg Time: 48 min  │ │  Avg Time: 67 min 🔴│  │
│  └────────────────────┘ └────────────────────┘ └────────────────────┘  │
│                                                                        │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │  Bay Utilization Heatmap (ชั่วโมง)                            │     │
│  │       06 07 08 09 10 11 12 13 14 15 16 17 18 19 20           │     │
│  │ B01 │ ░░ ██ ██ ██ ██ ██ ░░ ██ ██ ██ ██ ░░ ██ ██ ░░ │        │     │
│  │ B02 │ ░░ ░░ ██ ██ ░░ ██ ██ ██ ░░ ██ ██ ██ ░░ ░░ ░░ │        │     │
│  │ B03 │ ░░ ██ ░░ ██ ██ ░░ ░░ ██ ██ ░░ ░░ ██ ░░ ░░ ░░ │        │     │
│  │ B04 │ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ │ MAINT  │     │
│  │      ██ = Loading  ░░ = Idle                          │        │     │
│  └───────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  ┌──────┬────────┬────────┬────────┬──────────┬──────────┬──────────┐  │
│  │ Bay  │ Jobs   │Weight  │Yield % │Accuracy% │ AvgTime  │ Util%   │  │
│  │ B01  │   48   │1,200t  │ 99.9%  │  97.9%   │  44 min  │  78%    │  │
│  │ B02  │   52   │1,040t  │ 99.7%  │  96.2%   │  48 min  │  82%    │  │
│  │ B03  │   38   │  760t  │ 98.8%  │  89.5%   │  67 min  │  61%    │  │
│  └──────┴────────┴────────┴────────┴──────────┴──────────┴──────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

**API:** `GET /api/analytics/bay?dateFrom=&dateTo=`  
**SP:** `ana.sp_GetBayPerformanceDashboard`

---

### Dashboard 4 — Truck Turnaround Dashboard (`/analytics/turnaround`)

```
┌────────────────────────────────────────────────────────────────────────┐
│  🚛 Truck Turnaround Dashboard         Filter: [สัปดาห์นี้ ▾]          │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │ Avg Turnaround│ │ Avg Waiting │ │ Avg Loading │ │ Fastest      │  │
│  │   108 min ⚠️ │ │   22 min ⚠️ │ │   47 min ✅ │ │   62 min ✅  │  │
│  │  NORMAL       │ │  LONG        │ │              │ │              │  │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │
│                                                                        │
│  ┌──────────────────────────────────┐ ┌─────────────────────────────┐  │
│  │  Turnaround Breakdown            │ │  Trend รายวัน               │  │
│  │  (Time Stacked Bar per job)      │ │  150 ─────────────────────  │  │
│  │                                  │ │  120 ─ ──╮    ╭────────     │  │
│  │  Waiting  ████░░░░░░░░░░░░ 22min │ │   90 ─    ╰────            │  │
│  │  Call→Dock░░░████░░░░░░░░░ 15min │ │   60 ─────────────────────  │  │
│  │  Loading  ░░░░░░░░████████ 47min │ │  Threshold: 90 min (----)   │  │
│  │  Check    ░░░░░░░░░░░░░██  10min │ │        07 08 09 10 11 12    │  │
│  │  ─────────────────────── 94min  │ └─────────────────────────────┘  │
│  └──────────────────────────────────┘                                  │
│                                                                        │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │  รถที่ Turnaround นานที่สุด (Top 5)                            │     │
│  │  80-5678 กก  ████████████████████████  145 min  🔴 SLOW       │     │
│  │  71-1111 กข  ███████████████████        128 min  🔴 SLOW       │     │
│  │  80-1234 กก  ██████████████             104 min  ⚠️ NORMAL     │     │
│  └───────────────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────────────┘
```

**API:** `GET /api/analytics/turnaround?dateFrom=&dateTo=`  
**SP:** `ana.sp_GetTurnaroundDashboard`

---

### Dashboard 5 — Product Loss Analysis (`/analytics/product`)

```
┌────────────────────────────────────────────────────────────────────────┐
│  📦 Product Loss Analysis              Filter: [เดือนนี้ ▾]            │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │ Products OK  │ │ Products ⚠️  │ │ Products 🔴  │ │ Total Loss   │  │
│  │      2       │ │      1       │ │      1       │ │   620 kg     │  │
│  │   ≤ 0.50%    │ │ 0.50-1.00%  │ │   > 1.00%   │ │ เดือนนี้     │  │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │
│                                                                        │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │  Loss % Ranking by Product (Horizontal Bar)                   │     │
│  │                                                               │     │
│  │  เกลือสมุทร   ████████████████████████  1.82% 🔴 CRITICAL    │     │
│  │  น้ำตาลทราย  ████████████               0.72% ⚠️ WARNING     │     │
│  │  ข้าวโพด      ████████                   0.51% ⚠️ WARNING     │     │
│  │  ข้าวเปลือก   ████                        0.18% ✅ NORMAL     │     │
│  │                                                               │     │
│  │  Threshold: ──── 0.50%   ──── 1.00%                          │     │
│  └───────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  ┌──────────────────────────────────┐ ┌───────────────────────────┐   │
│  │  Loss Trend by Product (7 วัน)   │ │  Product Detail           │   │
│  │  เกลือ  ╮─╭──╮ Loss สูงขึ้น      │ │  สินค้า: เกลือสมุทร       │   │
│  │  น้ำตาล ─╰──╯─ Stable           │ │  Jobs: 8  Target: 960t    │   │
│  │  ข้าว   ────── Normal            │ │  Actual: 942.5t           │   │
│  │  07 08 09 10 11 12 13           │ │  Loss:   17.5t (1.82%)    │   │
│  └──────────────────────────────────┘ │  Over:   0 kg             │   │
│                                       │  [ดูรายละเอียด Job ▶]    │   │
│                                       └───────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

**API:** `GET /api/analytics/product?dateFrom=&dateTo=&productId=`  
**SP:** `ana.sp_GetProductLossAnalysis`

---

## 4. Database Objects (ana Schema)

### Tables
| Table | คำอธิบาย |
|-------|----------|
| `ana.AnalyticsConfig` | Threshold ที่ตั้งค่าได้ |

### Views (อ่านจาก slb Schema)
| View | คำอธิบาย |
|------|----------|
| `ana.vw_JobPerformance` | KPI ทุกตัวต่อ Job |
| `ana.vw_QueuePerformance` | Timing ต่อ Queue |
| `ana.vw_DailyPerformance` | Summary รายวัน |
| `ana.vw_BayPerformance` | Bay utilization รายวัน |
| `ana.vw_ProductLossYield` | Loss/Yield รายสินค้า รายวัน |
| `ana.vw_TruckTurnaround` | Turnaround รายรถ รายวัน |

### Stored Procedures
| SP | Parameters | คำอธิบาย |
|----|-----------|----------|
| `ana.sp_GetPerformanceDashboard` | @DateFrom, @DateTo, @BayId, @ProductId | Overview |
| `ana.sp_GetLossYieldDashboard` | @DateFrom, @DateTo | Loss/Yield |
| `ana.sp_GetBayPerformanceDashboard` | @DateFrom, @DateTo | Bay Stats |
| `ana.sp_GetTurnaroundDashboard` | @DateFrom, @DateTo | Turnaround |
| `ana.sp_GetProductLossAnalysis` | @DateFrom, @DateTo, @ProductId | Product |

---

## 5. API Endpoints

```
GET  /api/analytics/performance      ?dateFrom&dateTo&bayId&productId
GET  /api/analytics/loss-yield       ?dateFrom&dateTo&productId
GET  /api/analytics/bay              ?dateFrom&dateTo&bayId
GET  /api/analytics/turnaround       ?dateFrom&dateTo&truckId
GET  /api/analytics/product          ?dateFrom&dateTo&productId
GET  /api/analytics/config           — ดึง Threshold ทั้งหมด
PUT  /api/analytics/config           — อัปเดต Threshold
GET  /api/analytics/export/excel     ?type&dateFrom&dateTo  — Export
```

---

## 6. React Component Structure (Analytics)

```
src/pages/
  AnalyticsLayout.tsx           — Shared layout + filter bar สำหรับ Analytics

  analytics/
    PerformanceOverviewPage.tsx
    LossYieldPage.tsx
    BayPerformancePage.tsx
    TurnaroundPage.tsx
    ProductLossPage.tsx

src/components/analytics/
  kpi/
    PerformanceKpiRow.tsx       — 4 KPI Card row
    YieldGauge.tsx              — SVG Gauge chart
    ThresholdBadge.tsx          — NORMAL/WARNING/CRITICAL badge

  charts/
    YieldTrendChart.tsx         — Recharts Line — Yield trend
    LossOverStackedBar.tsx      — Recharts Bar — Loss vs Over
    ThroughputBarChart.tsx      — Recharts Bar — ต่อ Bay
    BayHeatmap.tsx              — Custom SVG heatmap ชั่วโมง
    TurnaroundBreakdownBar.tsx  — Stacked Bar breakdown
    ProductLossRanking.tsx      — Horizontal Bar
    ProductLossTrendChart.tsx   — Multi-line trend

  tables/
    JobSummaryTable.tsx
    BayComparisonTable.tsx
    TruckRankingTable.tsx
    ProductLossTable.tsx

src/hooks/
  useAnalytics.ts               — Query analytics API
  useAnalyticsConfig.ts         — Threshold config
```

---

## 7. วิธี Test Analytics

1. รัน `db/002_create_analytics_schema.sql` หลังจาก Script 001
2. เรียก `EXEC ana.sp_GetPerformanceDashboard @DateFrom='2026-05-13', @DateTo='2026-05-13'`
3. ตรวจสอบ: ข้อมูล Test Data ที่ Shuri ใส่ไว้ควรปรากฏใน Views
4. ตรวจสอบ Yield % ควรได้ค่า (ถ้าไม่มี Job Completed ใน Test Data จะได้ 0)
5. ทดสอบ Threshold: ปรับ Config แล้วตรวจว่า Badge เปลี่ยนสี
