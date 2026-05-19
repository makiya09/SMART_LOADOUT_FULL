# UI PERFORMANCE DASHBOARD DESIGN — Smart Load Bulk

**ออกแบบโดย:** Spider-Man (UI/UX Designer)
**วันที่:** 2026-05-14
**Version:** 1.0
**อ้างอิง:** docs/PERFORMANCE_ANALYTICS_PLAN.md (Hawkeye), docs/SYSTEM_ARCHITECTURE.md V2.0

---

## ภาพรวม Performance Dashboard System

ระบบ Analytics ประกอบด้วย 4 Dashboard หลัก + Navigation Tab ร่วมกัน

```
/analytics               Performance Overview Dashboard
/analytics/loss-yield    Loss / Yield Dashboard
/analytics/bay           Bay Performance Dashboard
/analytics/turnaround    Truck Turnaround Dashboard
```

---

## 1. Performance Dashboard UI — Overview (`/analytics`)

**วัตถุประสงค์:** KPI ภาพรวมทั้งระบบ เห็นสรุปได้ใน 5 วินาที

### ASCII Wireframe

```
+---------------------------------------------------------------------+
|  Performance Analytics                 [Export Excel] [Export PDF]  |
+---------------------------------------------------------------------+
|  DATE RANGE FILTER                                                   |
|  [Today] [Yesterday] [7 Days] [30 Days] [Custom: from -- to]        |
|  Shift: [All] [Morning] [Afternoon] [Night]    [Refresh]            |
+---------------------------------------------------------------------+
|  ANALYTICS TAB NAV                                                   |
|  [Overview*] [Loss/Yield] [Bay Performance] [Truck Turnaround]      |
+---------------------------------------------------------------------+
|                                                                      |
|  KPI GROUP A: Volume & Production (grid-cols-4 gap-4)                |
|  +----------+ +----------+ +----------+ +----------+                |
|  | K01      | | K02      | | K03      | | K04      |                |
|  |Total Jobs| |Completed | |Cancelled | |Completion|                |
|  |   48     | |   44     | |    4     | |  91.7%   |                |
|  |[NORMAL]  | |[NORMAL]  | |[WARNING] | |[WARNING] |                |
|  +----------+ +----------+ +----------+ +----------+                |
|                                                                      |
|  +----------------------------+ +----------------------------+       |
|  | K05 Total Target Weight    | | K06 Total Actual Weight    |       |
|  |      960.0 ton             | |      952.3 ton             |       |
|  | [text-3xl slate-800 bold]  | | [text-3xl blue-700 bold]   |       |
|  +----------------------------+ +----------------------------+       |
|                                                                      |
|  +----------------------------+                                      |
|  | K07 Throughput                                                   |
|  | 48.5 ton/hour                                                    |
|  | [text-3xl green-700 bold]                                        |
|  +----------------------------+                                      |
|                                                                      |
|  KPI GROUP B: Loss, Over & Yield (grid-cols-4 gap-4)                |
|  +----------+ +----------+ +----------+ +----------+                |
|  | K08      | | K09      | | K10      | | K11      |                |
|  | Yield %  | |Total Loss| |Total Over| | Avg Diff |                |
|  |  99.2%   | | 7,700 kg | | 0 kg     | | -0.8%    |                |
|  |[WARNING] | |[WARNING] | |[NORMAL]  | |[WARNING] |                |
|  +----------+ +----------+ +----------+ +----------+                |
|                                                                      |
|  +----------+ +----------+ +----------+                              |
|  | K12      | | K13      | | K14      |                              |
|  | Accuracy | |Loss Jobs | |Over Jobs |                              |
|  |  89.6%   | |    5     | |    0     |                              |
|  |[WARNING] | |[WARNING] | |[NORMAL]  |                              |
|  +----------+ +----------+ +----------+                              |
|                                                                      |
|  KPI GROUP C: Time & Efficiency (grid-cols-3 gap-4)                  |
|  +----------+ +----------+ +----------+                              |
|  | K15      | | K16      | | K17      |                              |
|  | Avg Load | | Avg Wait | | Turnaround|                              |
|  |  22 min  | |  35 min  | |  65 min  |                              |
|  |[NORMAL]  | |[WARNING] | |[WARNING] |                              |
|  +----------+ +----------+ +----------+                              |
|                                                                      |
|  +----------+ +----------+ +----------+                              |
|  | K18      | | K19      | | K20      |                              |
|  | Bay Util | |Jobs/Bay  | | Idle Bay |                              |
|  |  72.4%   | |   11     | | 264 min  |                              |
|  |[NORMAL]  | |[NORMAL]  | |[NORMAL]  |                              |
|  +----------+ +----------+ +----------+                              |
|                                                                      |
|  CHARTS ROW (grid-cols-2 gap-6)                                      |
|  +-------------------------------+ +-------------------------------+ |
|  | Daily Tonnage Trend (7 days)  | | Completion Rate Trend         | |
|  | Recharts LineChart            | | Recharts LineChart + Area      | |
|  | X: Date  Y: ton               | | X: Date  Y: %                 | |
|  | Line: Actual, Target          | | Line: CompletionRate           | |
|  +-------------------------------+ +-------------------------------+ |
|                                                                      |
|  CHART: Hourly Throughput (Today)                                    |
|  [Recharts BarChart -- X: Hour, Y: ton/hr, Color by threshold]      |
|                                                                      |
+---------------------------------------------------------------------+
```

### KPI Card Variants

```
Normal State:          Warning State:        Critical State:
+------------+         +------------+        +------------+
| [icon]     |         | [icon]     |        | [icon]     |
| K08 Yield  |         | K08 Yield  |        | K08 Yield  |
|            |         |            |        |            |
|   99.8%    |         |   98.5%    |        |   96.2%    |
| text-green |         | text-amber |        | text-red   |
|            |         |            |        |            |
|[NORMAL]    |         |[WARNING]   |        |[CRITICAL]  |
|bg-green-50 |         |bg-amber-50 |        |bg-red-50   |
|trend +0.3% |         |trend -1.5% |        |trend -3.8% |
+------------+         +------------+        +------------+
                                             (border-red-400
                                              shadow-red-100)
```

### KPI Card Props
```typescript
interface KpiCardAnalyticsProps {
  code: string           // K01, K02...
  title: string
  value: number | string
  unit: string
  status: 'normal' | 'warning' | 'critical' | 'good'
  trend?: number         // % change vs previous period
  trendLabel?: string    // "vs yesterday"
  threshold?: {
    warning: number
    critical: number
  }
  icon?: React.ReactNode
  onClick?: () => void   // drill-down
}
```

---

## 2. Loss/Yield Dashboard UI (`/analytics/loss-yield`)

**วัตถุประสงค์:** วิเคราะห์ Loss / Over / Yield แยกตาม Product และ Bay

### ASCII Wireframe

```
+---------------------------------------------------------------------+
|  Loss / Yield Dashboard            [Export Excel] [Export PDF]      |
+---------------------------------------------------------------------+
|  DATE RANGE + TAB NAV (เหมือน Overview)                              |
+---------------------------------------------------------------------+
|                                                                      |
|  YIELD GAUGE + SUMMARY (grid-cols-3 gap-6)                           |
|  +---------------------+ +---------------------+ +---------------+  |
|  | YIELD % GAUGE       | | ACCURACY GAUGE       | | LOSS SUMMARY |  |
|  |                     | |                      | |              |  |
|  |  Recharts           | | Recharts             | | Loss: 7.7 t  |  |
|  |  RadialBarChart     | | RadialBarChart       | | Over:  0.0 t |  |
|  |                     | |                      | | Net:  -7.7 t |  |
|  |  99.2%              | | 89.6%                | |              |  |
|  | [big number center] | | [big number center]  | | Loss Jobs: 5 |  |
|  |                     | |                      | | Over Jobs: 0 |  |
|  | Threshold: 99.5%    | | Threshold: 95%       | |              |  |
|  | [WARNING amber]     | | [WARNING amber]      | |[WARNING]     |  |
|  +---------------------+ +---------------------+ +---------------+  |
|                                                                      |
|  DAILY LOSS/YIELD TREND (Recharts ComposedChart)                     |
|  +---------------------------------------------------------------+  |
|  | X: Date (7 days)                                              |  |
|  | Y Left: ton (Loss, Over as Bar)                               |  |
|  | Y Right: % (Yield as Line)                                    |  |
|  |                                                               |  |
|  | Bar: Loss = red, Over = orange                                |  |
|  | Line: Yield% = blue, threshold = dashed-red                   |  |
|  | Recharts: ComposedChart, Bar, Line, ReferenceLine             |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  PRODUCT LOSS TABLE (top 10 by Loss)                                 |
|  +--+-------------+-------+--------+--------+--------+---------+   |
|  |# | สินค้า      | Jobs  | Target | Actual | Loss   | Yield % |   |
|  +--+-------------+-------+--------+--------+--------+---------+   |
|  |1 | Feed A      | 18    | 360 t  | 352 t  | 8.0 t  | 97.8%   |   |
|  |  |             |       |        |        |[red]   |[WARNING]|   |
|  |2 | Feed B      | 12    | 240 t  | 239 t  | 1.0 t  | 99.6%   |   |
|  |  |             |       |        |        |[amber] |[NORMAL] |   |
|  |3 | Feed C      | 8     | 160 t  | 159.8t | 0.2 t  | 99.9%   |   |
|  |  |             |       |        |        |[green] |[NORMAL] |   |
|  +--+-------------+-------+--------+--------+--------+---------+   |
|                                                                      |
|  LOSS BY BAY HEATMAP (grid-cols-4)                                   |
|  +----------+ +----------+ +----------+ +----------+                |
|  | BAY 01   | | BAY 02   | | BAY 03   | | BAY 04   |                |
|  | Loss 4.5t| | Loss 1.2t| | Loss 2.0t| | Loss 0 t |                |
|  | Yield    | | Yield    | | Yield    | | Yield    |                |
|  | 97.5%    | | 99.2%    | | 98.7%    | | 100.0%   |                |
|  |[bg-red   | |[bg-amber | |[bg-amber | |[bg-green |                |
|  | -200]    | | -100]    | | -100]    | | -100]    |                |
|  +----------+ +----------+ +----------+ +----------+                |
|                                                                      |
|  TOP LOSS JOBS TABLE (10 Job ที่ Loss สูงสุด)                        |
|  +--------+--------+--------+--------+--------+--------+-------+    |
|  | Job ID | Truck  | Bay    | Product| Target | Actual |Yield% |    |
|  +--------+--------+--------+--------+--------+--------+-------+    |
|  |JOB-001 |80-1234 | Bay 01 | Feed A | 20.0 t | 18.5 t | 92.5% |   |
|  |        |        |        |        |        |[red]   |[CRIT] |   |
|  |JOB-005 |80-5678 | Bay 01 | Feed A | 20.0 t | 19.2 t | 96.0% |   |
|  |        |        |        |        |        |[amber] |[WARN] |   |
|  +--------+--------+--------+--------+--------+--------+-------+    |
|                                                                      |
|  PRODUCT YIELD VARIANCE (Recharts BarChart — Error Bar)              |
|  [X: Product, Y: Yield%, แสดง Avg, Min, Max per Product]            |
+---------------------------------------------------------------------+
```

### Gauge Component Spec
```typescript
// ใช้ Recharts RadialBarChart
// Props:
interface YieldGaugeProps {
  value: number           // 0-100
  threshold: {
    warning: number       // 99.5
    critical: number      // 98.0
  }
  size?: 'sm' | 'md' | 'lg'
  showLabel?: boolean
}

// Color Logic:
// value >= 99.5  -> green   (#16A34A)
// value >= 98.0  -> amber   (#D97706)
// value < 98.0   -> red     (#DC2626)
```

### recharts ที่ใช้ในหน้านี้
```
RadialBarChart        -- Yield Gauge, Accuracy Gauge
ComposedChart         -- Daily Loss/Yield Trend (Bar + Line)
BarChart              -- Loss by Product, Yield Variance
ReferenceLine         -- แสดง Threshold line ใน Chart
CartesianGrid         -- Grid เส้นประในกราฟ
Tooltip               -- Custom Tooltip แสดงรายละเอียด
Legend                -- คำอธิบาย Line/Bar
```

---

## 3. Bay Performance Dashboard UI (`/analytics/bay`)

**วัตถุประสงค์:** วิเคราะห์ Utilization และประสิทธิภาพแต่ละ Bay

### ASCII Wireframe

```
+---------------------------------------------------------------------+
|  Bay Performance Dashboard         [Export Excel] [Export PDF]      |
+---------------------------------------------------------------------+
|  DATE RANGE + TAB NAV                                                |
|  Bay Filter: [All Bays] [Bay 01] [Bay 02] [Bay 03] [Bay 04]          |
+---------------------------------------------------------------------+
|                                                                      |
|  BAY SUMMARY CARDS (grid-cols-4 gap-4)                               |
|  +-------------------+ +-------------------+                        |
|  | BAY 01            | | BAY 02            |                        |
|  | Jobs: 14          | | Jobs: 12          |                        |
|  | Tonnage: 266 t    | | Tonnage: 228 t    |                        |
|  | Utilization: 78%  | | Utilization: 65%  |                        |
|  | Avg Load: 19 min  | | Avg Load: 21 min  |                        |
|  | [GOOD bg-green-50]| | [NORMAL bg-green] |                        |
|  +-------------------+ +-------------------+                        |
|  +-------------------+ +-------------------+                        |
|  | BAY 03            | | BAY 04            |                        |
|  | Jobs: 10          | | Jobs: 8           |                        |
|  | Tonnage: 190 t    | | Tonnage: 152 t    |                        |
|  | Utilization: 55%  | | Utilization: 42%  |                        |
|  | Avg Load: 23 min  | | Avg Load: 24 min  |                        |
|  | [WARNING amber]   | | [WARNING amber]   |                        |
|  +-------------------+ +-------------------+                        |
|                                                                      |
|  BAY UTILIZATION BAR CHART (Recharts BarChart)                       |
|  +---------------------------------------------------------------+  |
|  | X: Bay Name    Y: Utilization %                               |  |
|  | Bar Color: green(>70%), amber(50-70%), red(<50%)              |  |
|  | ReferenceLine: 70% (Target Threshold -- dashed)               |  |
|  | Recharts: BarChart, Bar, XAxis, YAxis, ReferenceLine, Tooltip  |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  BAY UTILIZATION HEATMAP (กริดตาราง Days x Hours)                    |
|  +---------------------------------------------------------------+  |
|  |        | Bay 01 | Bay 02 | Bay 03 | Bay 04 |                  |  |
|  | Mon 13 | [dark] | [mid]  | [light]| [pale] |                  |  |
|  | Tue 14 | [dark] | [dark] | [mid]  | [light]|                  |  |
|  | Wed 15 | [mid]  | [mid]  | [light]| [pale] |                  |  |
|  |        |                                                       |  |
|  | Dark = High Utilization (>70%) = bg-blue-600                  |  |
|  | Mid  = Medium (50-70%)         = bg-blue-300                  |  |
|  | Light = Low (30-50%)           = bg-blue-100                  |  |
|  | Pale = Very Low (<30%)         = bg-slate-100                 |  |
|  | (Recharts: Custom Table Heatmap หรือ CSS Grid)                |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  THROUGHPUT BY BAY (Recharts GroupedBarChart)                        |
|  +---------------------------------------------------------------+  |
|  | X: Date  Y: ton/hour                                          |  |
|  | Grouped Bar: 1 Group per Date, 4 Bar per Bay                  |  |
|  | Colors: Bay1=blue, Bay2=green, Bay3=violet, Bay4=amber        |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  BAY PERFORMANCE TABLE (รายละเอียดแต่ละ Bay)                         |
|  +------+------+--------+--------+--------+---------+---------+     |
|  | Bay  | Jobs | Total  | Avg    | Util % | Idle    | Yield   |     |
|  |      |      | Ton    | Load   |        | Min     | Avg %   |     |
|  +------+------+--------+--------+--------+---------+---------+     |
|  | Bay1 | 14   | 266 t  | 19 min | 78%    | 211 min | 99.1%  |     |
|  | Bay2 | 12   | 228 t  | 21 min | 65%    | 336 min | 99.5%  |     |
|  | Bay3 | 10   | 190 t  | 23 min | 55%    | 432 min | 98.8%  |     |
|  | Bay4 | 8    | 152 t  | 24 min | 42%    | 557 min | 100.0% |     |
|  +------+------+--------+--------+--------+---------+---------+     |
|                                                                      |
|  IDLE TIME BY BAY (Recharts BarChart — Stacked)                      |
|  [X: Bay, Y: minutes, Stack: Loading vs Idle]                       |
+---------------------------------------------------------------------+
```

### Heatmap Implementation
```typescript
// Bay Heatmap — CSS Grid implementation
// ใช้ Custom Grid เนื่องจาก recharts ไม่มี Heatmap native

interface HeatmapCell {
  date: string
  bayId: number
  bayName: string
  utilizationPct: number
}

// Color mapping:
const getHeatmapColor = (pct: number): string => {
  if (pct >= 70) return 'bg-blue-600 text-white'
  if (pct >= 50) return 'bg-blue-300 text-blue-900'
  if (pct >= 30) return 'bg-blue-100 text-blue-800'
  return 'bg-slate-100 text-slate-500'
}
```

### recharts ที่ใช้ในหน้านี้
```
BarChart              -- Utilization by Bay
Bar                   -- แต่ละ Bay, Color by threshold
GroupedBarChart       -- Throughput ตามวัน
StackedBarChart       -- Idle vs Loading time
ReferenceLine         -- Target threshold line
XAxis, YAxis, CartesianGrid, Tooltip, Legend
```

---

## 4. Truck Turnaround Dashboard UI (`/analytics/turnaround`)

**วัตถุประสงค์:** วิเคราะห์เวลาตั้งแต่รถเข้า Bay ถึงออก และ Waiting Time

### ASCII Wireframe

```
+---------------------------------------------------------------------+
|  Truck Turnaround Dashboard        [Export Excel] [Export PDF]      |
+---------------------------------------------------------------------+
|  DATE RANGE + TAB NAV                                                |
+---------------------------------------------------------------------+
|                                                                      |
|  TURNAROUND KPI SUMMARY (grid-cols-4 gap-4)                          |
|  +----------+ +----------+ +----------+ +----------+                |
|  | K15      | | K16      | | K17      | | K24      |                |
|  | Avg Load | | Avg Wait | |Turnaround| | Problem  |                |
|  |  22 min  | |  35 min  | |  65 min  | | Truck 8% |                |
|  |[NORMAL]  | |[WARNING] | |[WARNING] | |[WARNING] |                |
|  +----------+ +----------+ +----------+ +----------+                |
|                                                                      |
|  TURNAROUND TIME HISTOGRAM (Recharts BarChart)                       |
|  +---------------------------------------------------------------+  |
|  | X: Time Range (0-30, 30-60, 60-90, 90-120, >120 min)         |  |
|  | Y: Job Count                                                  |  |
|  | Color: green(<60), amber(60-90), red(>90)                     |  |
|  | Recharts: BarChart, Bar (custom color per bucket)             |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  DAILY TURNAROUND TREND (Recharts LineChart)                         |
|  +---------------------------------------------------------------+  |
|  | X: Date (7 days)   Y: minutes                                 |  |
|  | Lines: AvgTurnaround, AvgWaiting, AvgLoading                  |  |
|  | Colors: Turnaround=blue, Waiting=amber, Loading=green         |  |
|  | ReferenceLine: Target threshold (dashed)                      |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  TURNAROUND BREAKDOWN (Stacked Bar per Day)                          |
|  +---------------------------------------------------------------+  |
|  | X: Date                                                       |  |
|  | Stacked Bar:                                                  |  |
|  |   Blue  = Loading Time                                        |  |
|  |   Amber = Waiting Time                                        |  |
|  |   Slate = Idle/Other Time                                     |  |
|  | Recharts: BarChart, Bar (stacked)                             |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  PROBLEM TRUCK ANALYSIS (K24, K25)                                   |
|  +-------------------+ +-----------------------------------+         |
|  | Problem Rate      | | Repeat Incident by Truck          |         |
|  | 8.3%              | |                                   |         |
|  | [RadialBarChart]  | | Truck  | Emrg | Loss | Total      |         |
|  |                   | | 80-1234|  2   |  1   |   3        |         |
|  |                   | | 80-5678|  0   |  2   |   2        |         |
|  |                   | | 80-9012|  1   |  0   |   1        |         |
|  +-------------------+ +-----------------------------------+         |
|                                                                      |
|  WAITING TIME BY HOUR (Recharts BarChart)                            |
|  +---------------------------------------------------------------+  |
|  | X: Hour (00-23)  Y: Avg Waiting minutes                       |  |
|  | แสดง Peak Hour ที่รอนาน                                       |  |
|  | Color: green(<20), amber(20-40), red(>40)                     |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  JOB DETAIL TABLE (ล่าสุด + Sort ได้)                                |
|  +--------+--------+------+--------+-------+-------+-------+        |
|  | Job ID | Truck  | Bay  | Product|Loading|Waiting|Turnard|        |
|  +--------+--------+------+--------+-------+-------+-------+        |
|  |JOB-001 |80-1234 | Bay1 | Feed A | 18min | 32min | 55min |        |
|  |JOB-002 |80-5678 | Bay2 | Feed B | 22min | 45min | 78min |        |
|  |        |        |      |        |       |[amber]|[amber]|        |
|  |JOB-003 |80-9012 | Bay1 | Feed A | 25min | 65min |110min |        |
|  |        |        |      |        |       |[red]  |[red]  |        |
|  +--------+--------+------+--------+-------+-------+-------+        |
|  Pagination | Sort by: Turnaround (desc)                             |
+---------------------------------------------------------------------+
```

### recharts ที่ใช้ในหน้านี้
```
BarChart              -- Turnaround Histogram, Waiting by Hour
Bar                   -- Custom Color per bucket
LineChart             -- Daily Turnaround Trend
Line                  -- Multiple lines (Turnaround, Waiting, Loading)
RadialBarChart        -- Problem Truck Rate Gauge
ReferenceLine         -- Threshold lines
ComposedChart         -- Breakdown Stacked Bar
```

---

## 5. Dashboard KPI Card Design — ทุก Variant

### KPI Card Sizes

```
SIZE: SM (สำหรับ Dashboard Secondary)
+---------------------------+
| [icon sm]  K01 Total Jobs |
|                           |
|   48                      |
|  text-3xl bold            |
|  [NORMAL badge-green]     |
|  vs yesterday: +3 (6.7%)  |
+---------------------------+
Width: col-span-1 (25% of row)

SIZE: MD (สำหรับ Dashboard Primary)
+-------------------------------+
| [icon]    K07 Throughput      |
|                               |
|  48.5 ton/hr                  |
|  text-3xl bold                |
|                               |
|  [NORMAL bg-green-50]         |
|  Target: 50 ton/hr            |
|  vs yesterday: +2.1 ton/hr    |
+-------------------------------+
Width: col-span-2 (50% of row)

SIZE: LG (สำหรับ Hero KPI บน TV/Overview)
+------------------------------------+
| [icon lg]  Overall Yield           |
|                                    |
|  99.2%                             |
|  text-5xl font-black               |
|                                    |
|  [WARNING bg-amber-50]             |
|  Threshold: 99.5%                  |
|  Trend: -0.6% from yesterday       |
+------------------------------------+
Width: col-span-3 (75% of row)
```

### KPI Card Status Variants

```
GOOD (เกิน Target):
+---------------------------+
| bg-white                  |
| border-l-4 border-green   |
| shadow-sm                 |
| [value: text-green-700]   |
| badge: bg-green-100       |
|        text-green-800     |
|        "GOOD"             |
+---------------------------+

NORMAL (ใน Target Range):
+---------------------------+
| bg-white                  |
| border-l-4 border-slate   |
| shadow-sm                 |
| [value: text-slate-800]   |
| badge: bg-slate-100       |
|        text-slate-700     |
|        "NORMAL"           |
+---------------------------+

WARNING (ใกล้ Threshold):
+---------------------------+
| bg-white                  |
| border-l-4 border-amber   |
| shadow-card               |
| [value: text-amber-700]   |
| badge: bg-amber-100       |
|        text-amber-800     |
|        "WARNING"          |
| [!] alert dot             |
+---------------------------+

CRITICAL (เกิน Threshold):
+---------------------------+
| bg-red-50                 |
| border-l-4 border-red-500 |
| shadow-card-lg            |
| ring-1 ring-red-200       |
| [value: text-red-700]     |
| badge: bg-red-100         |
|        text-red-800       |
|        "CRITICAL"         |
| [!!] alert dot pulse      |
+---------------------------+
```

---

## 6. Chart Types ที่ต้องใช้

| Chart | Recharts Component | ใช้กับ | หน้า |
|-------|-------------------|--------|------|
| Line Trend | `LineChart, Line` | Daily Tonnage Trend, Turnaround Trend | Overview, Turnaround |
| Area + Line | `AreaChart, Area, Line` | Completion Rate Trend | Overview |
| Bar Basic | `BarChart, Bar` | Bay Utilization, Throughput | Bay |
| Bar Grouped | `BarChart, Bar` (multiple) | Throughput by Bay/Day | Bay |
| Bar Stacked | `BarChart, Bar` (stacked) | Turnaround Breakdown | Turnaround |
| Composed | `ComposedChart, Bar, Line` | Loss/Yield Trend | Loss/Yield |
| Radial/Gauge | `RadialBarChart, RadialBar` | Yield Gauge, Accuracy Gauge | Loss/Yield |
| Histogram | `BarChart, Bar` | Turnaround Distribution | Turnaround |
| Heatmap | Custom CSS Grid | Bay Utilization Heatmap | Bay |

### Custom Chart Configurations

```typescript
// Yield Gauge — RadialBarChart
const YIELD_GAUGE_CONFIG = {
  innerRadius: '60%',
  outerRadius: '80%',
  startAngle: 200,
  endAngle: -20,
  data: [{ value: yieldPct, fill: getYieldColor(yieldPct) }]
}

// Common Tooltip Style
const CUSTOM_TOOLTIP_STYLE = {
  contentStyle: {
    background: '#1E293B',
    border: 'none',
    borderRadius: '8px',
    color: '#F8FAFC',
    fontSize: '13px',
    padding: '12px'
  }
}

// Threshold Reference Line
<ReferenceLine
  y={threshold}
  stroke="#DC2626"
  strokeDasharray="4 4"
  label={{ value: `Threshold: ${threshold}%`, fill: '#DC2626', fontSize: 12 }}
/>
```

---

## 7. Analytics Navigation

### Tab Navigation Component

```
+---------------------------------------------------------------+
|  [Overview] [Loss/Yield] [Bay Performance] [Truck Turnaround] |
+---------------------------------------------------------------+
```

### Navigation Implementation
```typescript
// AnalyticsTabNav.tsx
interface AnalyticsTabNavProps {
  activeTab: 'overview' | 'loss-yield' | 'bay' | 'turnaround'
  onTabChange: (tab: string) => void
}

// Tab routing:
const ANALYTICS_TABS = [
  { id: 'overview',    label: 'Overview',           path: '/analytics' },
  { id: 'loss-yield',  label: 'Loss / Yield',       path: '/analytics/loss-yield' },
  { id: 'bay',         label: 'Bay Performance',    path: '/analytics/bay' },
  { id: 'turnaround',  label: 'Truck Turnaround',  path: '/analytics/turnaround' },
]
```

### Active Tab Style
```
Active:   border-b-2 border-blue-600 text-blue-600 font-semibold
Inactive: text-slate-500 hover:text-slate-700
```

---

## 8. Alert / Threshold Display

### Threshold Alert Banner
```
+---------------------------------------------------------------+
|  [!!] KPI Alert: 3 ตัวเกิน Threshold                bg-red   |
|  Yield 98.5% (ต่ำกว่า 99.5%) | Accuracy 89.6% (ต่ำกว่า 95%) |
|  Waiting Time 35min (เกิน 30min)                              |
|                                  [View Details] [Dismiss]    |
+---------------------------------------------------------------+
```

### Inline Threshold Indicator (บน KPI Card)
```
+---------------------------+
| K08 Yield %               |
| 98.5%  [WARNING]          |
|                           |
| Progress toward threshold:|
| XXXXXXXXXX      99.5%     |
| |98.5%|                   |
| [amber bar, target line]  |
+---------------------------+
```

### Alert Rules
```typescript
interface AlertThreshold {
  kpiCode: string
  warningThreshold: number
  criticalThreshold: number
  direction: 'above' | 'below'   // 'below' = ต่ำกว่า threshold = bad
}

// ตัวอย่าง Config:
const KPI_THRESHOLDS: AlertThreshold[] = [
  { kpiCode: 'K08', warningThreshold: 99.5, criticalThreshold: 98.0, direction: 'below' },
  { kpiCode: 'K12', warningThreshold: 95.0, criticalThreshold: 90.0, direction: 'below' },
  { kpiCode: 'K16', warningThreshold: 30,   criticalThreshold: 60,   direction: 'above' },
  { kpiCode: 'K17', warningThreshold: 60,   criticalThreshold: 90,   direction: 'above' },
  { kpiCode: 'K18', warningThreshold: 60,   criticalThreshold: 40,   direction: 'below' },
]
```

---

## 9. Date Range Filter UI

### Component Design
```
+-------------------------------------------------------------+
|  Preset Buttons:                                             |
|  [Today] [Yesterday] [7 Days] [30 Days] [This Month]        |
|                                                             |
|  Custom Range:                                              |
|  From: [2026-05-01]    To: [2026-05-14]   [Apply]          |
|                                                             |
|  Shift Filter (Optional):                                   |
|  [All Shifts] [Morning 06-14] [Afternoon 14-22] [Night 22-06]|
|                                                             |
|  Selected: "7 Days: 2026-05-08 to 2026-05-14"              |
+-------------------------------------------------------------+
```

### DateRangeFilter Props
```typescript
interface DateRangeFilterProps {
  from: Date
  to: Date
  onChange: (from: Date, to: Date) => void
  presets?: Array<{
    label: string
    getRange: () => { from: Date; to: Date }
  }>
  showShift?: boolean
  onShiftChange?: (shift: 'all' | 'morning' | 'afternoon' | 'night') => void
}
```

### Preset Definitions
```typescript
const DATE_PRESETS = [
  {
    label: 'Today',
    getRange: () => ({
      from: startOfDay(new Date()),
      to: endOfDay(new Date())
    })
  },
  {
    label: '7 Days',
    getRange: () => ({
      from: subDays(new Date(), 6),
      to: new Date()
    })
  },
  {
    label: '30 Days',
    getRange: () => ({
      from: subDays(new Date(), 29),
      to: new Date()
    })
  },
  {
    label: 'This Month',
    getRange: () => ({
      from: startOfMonth(new Date()),
      to: new Date()
    })
  },
]
```

---

## 10. Export Button UI

### Export Button Design
```
Position: Top-right ของ Dashboard Page Header

+------------------------------------------+
|  Performance Analytics       [Export]     |
|                              dropdown:    |
|                              [Excel .xlsx]|
|                              [PDF .pdf]  |
+------------------------------------------+
```

### Export Button Component
```typescript
// ExportButton.tsx
interface ExportButtonProps {
  onExportExcel: () => void
  onExportPdf: () => void
  isLoading?: boolean
  disabled?: boolean
}

// Styling:
// Main button: bg-white border border-slate-300 text-slate-700
// Hover: bg-slate-50
// Loading: disabled + spinner inside
// Excel icon: green (#16A34A)
// PDF icon: red (#DC2626)
```

### Export Button UI States
```
Default:
+-------------------+
| [arrow] Export    |
| bg-white border   |
+-------------------+

Loading:
+-------------------+
| [spinner] ...     |
| Generating...     |
+-------------------+

Dropdown Open:
+-------------------+
| [arrow] Export  v |
+-------------------+
| [green] Excel     |
| [red]   PDF       |
+-------------------+
```

---

## 11. KPI Summary Table (25 KPIs ครบ)

| Code | ชื่อ | Unit | Dashboard | Chart |
|------|------|------|-----------|-------|
| K01 | Total Jobs | Count | Overview | KpiCard |
| K02 | Completed Jobs | Count | Overview | KpiCard |
| K03 | Cancelled/Emergency | Count | Overview | KpiCard |
| K04 | Completion Rate | % | Overview | KpiCard |
| K05 | Total Target Weight | ton | Overview | KpiCard Big |
| K06 | Total Actual Weight | ton | Overview | KpiCard Big |
| K07 | Throughput ton/hr | ton/hr | Overview | KpiCard + Line |
| K08 | Yield % | % | Loss/Yield | Gauge + Line |
| K09 | Total Loss | kg | Loss/Yield | KpiCard + Bar |
| K10 | Total Over | kg | Loss/Yield | KpiCard + Bar |
| K11 | Avg Diff % | % | Loss/Yield | KpiCard |
| K12 | Loading Accuracy | % | Loss/Yield | Gauge |
| K13 | Loss Job Count | Count | Loss/Yield | KpiCard |
| K14 | Over Job Count | Count | Loss/Yield | KpiCard |
| K15 | Avg Loading Time | min | Turnaround | KpiCard + Line |
| K16 | Avg Waiting Time | min | Turnaround | KpiCard + Line |
| K17 | Avg Turnaround | min | Turnaround | KpiCard + Hist |
| K18 | Bay Utilization | % | Bay | KpiCard + Bar |
| K19 | Jobs per Bay/Day | Count | Bay | KpiCard |
| K20 | Idle Bay Time | min | Bay | KpiCard + Bar |
| K21 | Loss Rate by Product | % | Loss/Yield | Table + Bar |
| K22 | Top Loss Product | kg | Loss/Yield | Table |
| K23 | Yield Variance | SD | Loss/Yield | Bar (ErrorBar) |
| K24 | Problem Truck Rate | % | Turnaround | Gauge |
| K25 | Repeat Incident | Count | Turnaround | Table |

---

## 12. หน้าจอ Analytics — Responsive Behavior

### PC (>=1280px)
- KPI Cards: `grid-cols-4` หรือ `grid-cols-5`
- Charts: `grid-cols-2` (2 Charts ต่อแถว)
- Table: Full Width พร้อม Pagination

### Tablet (768px–1279px)
- KPI Cards: `grid-cols-2`
- Charts: `grid-cols-1` (Stack)
- Table: Horizontal Scroll หรือ Simplified Columns

### TV Display (>=1536px)
- ไม่แสดง Analytics Dashboard บน TV Display Mode
- TV Mode ใช้เฉพาะ Bay Calling Page

---

## 13. Color Logic สำหรับ KPI Status

```typescript
// getKpiStatus.ts
export function getKpiStatus(
  code: string,
  value: number,
  thresholds: AlertThreshold[]
): 'good' | 'normal' | 'warning' | 'critical' {
  const config = thresholds.find(t => t.kpiCode === code)
  if (!config) return 'normal'

  if (config.direction === 'below') {
    // ต่ำกว่า = แย่
    if (value >= config.warningThreshold * 1.01) return 'good'
    if (value >= config.warningThreshold) return 'normal'
    if (value >= config.criticalThreshold) return 'warning'
    return 'critical'
  } else {
    // สูงกว่า = แย่
    if (value <= config.warningThreshold * 0.7) return 'good'
    if (value <= config.warningThreshold) return 'normal'
    if (value <= config.criticalThreshold) return 'warning'
    return 'critical'
  }
}

// Status -> Tailwind Class
export const KPI_STATUS_CLASSES = {
  good:     { text: 'text-green-700', bg: 'bg-green-50', badge: 'bg-green-100 text-green-800', border: 'border-green-400' },
  normal:   { text: 'text-slate-800', bg: 'bg-white',    badge: 'bg-slate-100 text-slate-700', border: 'border-slate-300' },
  warning:  { text: 'text-amber-700', bg: 'bg-amber-50', badge: 'bg-amber-100 text-amber-800', border: 'border-amber-400' },
  critical: { text: 'text-red-700',   bg: 'bg-red-50',   badge: 'bg-red-100 text-red-800',     border: 'border-red-500'   },
}
```

---

## 14. ไฟล์ที่ต้องสร้าง (Analytics UI)

**Base Path:** `D:\MAKIYA_PROJECT\Project_SmartLoadBulk\frontend\src\`

```
pages/analytics/
  PerformanceDashboardPage.tsx     -- /analytics
  LossYieldDashboardPage.tsx       -- /analytics/loss-yield
  BayPerformanceDashboardPage.tsx  -- /analytics/bay
  TruckTurnaroundDashboardPage.tsx -- /analytics/turnaround

components/analytics/
  AnalyticsTabNav.tsx              -- Tab Navigation
  KpiCardAnalytics.tsx             -- KPI Card + Status + Trend
  DateRangeFilter.tsx              -- Date Picker + Presets
  ExportButton.tsx                 -- Export Dropdown
  ThresholdBadge.tsx               -- KPI vs Threshold Badge
  YieldGauge.tsx                   -- RadialBarChart Gauge
  AccuracyGauge.tsx                -- RadialBarChart Gauge
  BayHeatmap.tsx                   -- Custom CSS Grid Heatmap
  LossProductTable.tsx             -- Product Loss Ranking Table
  TurnaroundHistogram.tsx          -- Bar Chart Histogram
  TruckIncidentTable.tsx           -- Repeat Incident Table

hooks/
  useAnalytics.ts                  -- Data fetching + refresh
  useKpiThreshold.ts               -- Threshold comparison logic

types/
  analytics.types.ts               -- KPI, Dashboard data types
```

---

## ส่งต่อให้ Iron Man

งานถัดไปที่ Iron Man ต้องทำสำหรับ Analytics:
1. ติดตั้ง recharts: `npm install recharts`
2. สร้าง `components/analytics/KpiCardAnalytics.tsx` ก่อน
3. สร้าง `components/analytics/DateRangeFilter.tsx`
4. สร้าง `components/analytics/YieldGauge.tsx` (RadialBarChart)
5. Implement `PerformanceDashboardPage.tsx` กับ Mock Data
6. ต่อด้วย `LossYieldDashboardPage.tsx`
7. เชื่อมต่อ API ที่ `/api/analytics/performance`
8. ตั้งค่า SignalR AnalyticsHub สำหรับ Live KPI Update

---

*Spider-Man -- UI/UX Designer -- MAKIYA Marvel AI Team -- 2026-05-14*
*Performance Dashboard Design V1.0 -- ครอบคลุม 4 Dashboard + 25 KPI*
