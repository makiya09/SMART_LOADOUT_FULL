# UI/UX DESIGN — Smart Load Bulk

**ออกแบบโดย:** Spider-Man (UI/UX Designer)
**วันที่:** 2026-05-14
**Version:** 2.0 (ฉบับสมบูรณ์ — 14 หน้า + Full Design System)
**อ้างอิง:** docs/PROJECT_CONTEXT.md, docs/SYSTEM_ARCHITECTURE.md V2.0, docs/FLOW_PROCESS.md V2.0

---

## 1. Design Concept

### Theme Name
**"Clean Factory Command Center"**

### Philosophy
- ข้อมูลสำคัญต้องเห็นได้ภายใน 3–5 วินาที
- Operator และ Supervisor ใช้งานได้สะดวกในสภาพแวดล้อมโรงงาน
- Status ของทุกอย่างต้องชัดเจนด้วยสี + ข้อความ ไม่ต้องเดา
- Layout สะอาด ไม่แน่น เหมาะกับจอขนาดใหญ่และ Touch Screen
- Industrial แต่ทันสมัย ไม่ดูเก่า ไม่ดูซับซ้อน

### Visual Direction
- Light Mode เป็นหลัก (Dark Mode เฉพาะ TV Display)
- Card-based Layout
- Sidebar แบบ Collapsible (240px / 64px)
- Status Badge ทุกที่ที่มีสถานะ
- Big Number KPI ที่มองเห็นชัดจากระยะไกล
- Progress Bar แสดงน้ำหนัก Loading แบบ Real-time
- Color-coded ทุก Status: Green=OK, Amber=Warning, Red=Critical/Error

---

## 2. Color Palette

### Primary Colors
| ชื่อ | HEX | Tailwind Class | ใช้กับ |
|------|-----|----------------|--------|
| Primary Blue | #2563EB | `bg-blue-600` | ปุ่มหลัก, Active State, Header |
| Primary Green | #16A34A | `bg-green-600` | Success, Active Bay, Completed |
| Light Blue | #DBEAFE | `bg-blue-100` | Background Highlight, Card Border |
| Light Green | #DCFCE7 | `bg-green-100` | Success Background, Low Alert |

### Neutral Colors
| ชื่อ | HEX | Tailwind Class | ใช้กับ |
|------|-----|----------------|--------|
| Page Background | #F8FAFC | `bg-slate-50` | พื้นหลังทั้งหน้า |
| Card Background | #FFFFFF | `bg-white` | การ์ดทุกใบ |
| Sidebar BG | #1E293B | `bg-slate-800` | Sidebar |
| Sidebar Text | #CBD5E1 | `text-slate-300` | เมนู Sidebar |
| Active Menu | #3B82F6 | `bg-blue-500` | เมนูที่กำลังใช้งาน |
| Heading Text | #0F172A | `text-slate-900` | หัวข้อหลัก |
| Body Text | #334155 | `text-slate-700` | ข้อความทั่วไป |
| Muted Text | #94A3B8 | `text-slate-400` | Label, Sub-text |
| Border | #E2E8F0 | `border-slate-200` | เส้นขอบการ์ด |
| Stripe Row | #F1F5F9 | `bg-slate-100` | Table Stripe |

### Status Colors
| สถานะ | HEX | Tailwind Class | ใช้กับ |
|--------|-----|----------------|--------|
| AVAILABLE / IDLE | #16A34A | `bg-green-600 text-white` | Bay พร้อมใช้ |
| CALLING | #D97706 | `bg-amber-600 text-white` | กำลังเรียกรถ |
| LOADING | #2563EB | `bg-blue-600 text-white` | กำลังโหลด |
| WAITING | #7C3AED | `bg-violet-600 text-white` | รอในคิว |
| COMPLETED | #059669 | `bg-emerald-600 text-white` | เสร็จสิ้น |
| ERROR | #DC2626 | `bg-red-600 text-white` | ผิดพลาด |
| EMERGENCY | #DC2626 | `bg-red-600 text-white animate-pulse` | Emergency Stop |
| OFFLINE | #64748B | `bg-slate-500 text-white` | อุปกรณ์ Offline |
| WARNING KPI | #F59E0B | `bg-amber-500 text-white` | KPI เตือน |
| NORMAL KPI | #16A34A | `text-green-600` | KPI ปกติ |
| CRITICAL KPI | #DC2626 | `text-red-600` | KPI วิกฤต |

### Inventory Status Colors
| ระดับ Stock | สี | Tailwind |
|-------------|-----|---------|
| NORMAL (>=150% Min) | Green | `text-green-600 bg-green-50` |
| LOW (100–150% Min) | Amber | `text-amber-600 bg-amber-50` |
| CRITICAL (<100% Min) | Red | `text-red-600 bg-red-50` |
| EMPTY (0) | Slate | `text-slate-500 bg-slate-100` |

---

## 3. Typography Scale

### Font Family
```
Primary Font: Inter (Google Fonts)
Fallback: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif
Monospace: JetBrains Mono (สำหรับ Code, Serial Number, QR Token)
```

### Size Scale
| ชื่อ | Size | Tailwind | ใช้กับ |
|------|------|---------|--------|
| xs | 11px | `text-xs` | Label เล็ก, Timestamp |
| sm | 13px | `text-sm` | Table Row, Badge |
| base | 14px | `text-sm` | Body Text ทั่วไป |
| md | 16px | `text-base` | Form Label, Description |
| lg | 18px | `text-lg` | Card Title, Section Header |
| xl | 20px | `text-xl` | Page Sub-title |
| 2xl | 24px | `text-2xl` | Page Title, Bay Name |
| 3xl | 30px | `text-3xl` | KPI Number ใน Dashboard Card |
| 4xl | 36px | `text-4xl` | Bay Number (TV Display) |
| 5xl | 48px | `text-5xl` | KPI ใหญ่ (TV Display Mode) |
| 6xl | 60px | `text-6xl` | Queue Number บน TV Display |
| 7xl | 72px | `text-7xl` | Truck Calling Number (TV) |

### Font Weight
| ชื่อ | Weight | Tailwind |
|------|--------|---------|
| Regular | 400 | `font-normal` |
| Medium | 500 | `font-medium` |
| SemiBold | 600 | `font-semibold` |
| Bold | 700 | `font-bold` |
| ExtraBold | 800 | `font-extrabold` |
| Black | 900 | `font-black` |

---

## 4. Spacing & Grid System

### Grid
```
Max Width:    1440px  (max-w-screen-2xl)
Columns:      12 columns
Gutter:       24px    (gap-6)
Padding X:    24px    (px-6)
Sidebar:      240px   (w-60) — Expanded
Sidebar:      64px    (w-16) — Collapsed
Top Bar:      64px    (h-16)
```

### Spacing Scale
| ชื่อ | px | Tailwind |
|------|-----|---------|
| xs | 4px | `p-1` |
| sm | 8px | `p-2` |
| md | 12px | `p-3` |
| base | 16px | `p-4` |
| lg | 20px | `p-5` |
| xl | 24px | `p-6` |
| 2xl | 32px | `p-8` |

### Border Radius
| ชื่อ | px | Tailwind | ใช้กับ |
|------|-----|---------|--------|
| sm | 6px | `rounded` | Badge, Input |
| md | 8px | `rounded-lg` | Card ทั่วไป |
| lg | 12px | `rounded-xl` | Modal, Panel |
| 2xl | 16px | `rounded-2xl` | TV Display Card |
| full | — | `rounded-full` | Avatar, Status Dot |

### Card Style Standard
```
bg-white rounded-lg shadow-sm border border-slate-200 p-6
```

### Table Style Standard
```
thead: bg-slate-50 text-slate-600 text-sm font-medium uppercase tracking-wide
tbody row: even:bg-slate-50 hover:bg-blue-50/50 transition-colors
td: py-3 px-4 text-sm text-slate-700
border: border-b border-slate-100
```

---

## 5. Component Library

### A. Layout Components
| Component | Path | คำอธิบาย |
|-----------|------|----------|
| `AppShell` | `components/layout/AppShell.tsx` | Shell หลัก (Sidebar + TopBar + Content) |
| `Sidebar` | `components/layout/Sidebar.tsx` | เมนูด้านซ้าย Collapsible |
| `TopBar` | `components/layout/TopBar.tsx` | Header บน (Breadcrumb, Notification, User) |
| `PageContainer` | `components/layout/PageContainer.tsx` | Wrapper ของ Content Area |
| `SectionHeader` | `components/layout/SectionHeader.tsx` | หัวข้อ Section + Action Button |

### B. Dashboard Cards
| Component | Props หลัก | คำอธิบาย |
|-----------|-----------|----------|
| `KpiCard` | `title, value, unit, trend, status, icon` | KPI Card ขนาดมาตรฐาน |
| `KpiCardBig` | `title, value, unit, status` | KPI Card ใหญ่ (TV Mode) |
| `BayStatusCard` | `bayId, bayName, status, queueInfo, progress` | สถานะ Bay หนึ่งใบ |
| `InventoryCard` | `productName, currentStock, minStock, capacity, status` | Stock Level Card |
| `QueueCard` | `queueNumber, truckPlate, product, weight, priority, status` | รายการคิวแต่ละใบ |
| `AlertCard` | `type, message, timestamp, severity` | Alert / Notification Card |

### C. Status & Badge
| Component | Props หลัก | คำอธิบาย |
|-----------|-----------|----------|
| `StatusBadge` | `status, size` | Badge สี + ข้อความ |
| `PriorityBadge` | `priority: NORMAL or HIGH or URGENT` | Badge Priority |
| `StockLevelBadge` | `level: NORMAL or LOW or CRITICAL or EMPTY` | Badge Stock |
| `StatusDot` | `status, animate` | จุดสีเล็ก (Online/Offline) |
| `KpiBadge` | `value, threshold, unit` | Badge KPI เปรียบ Threshold |

### D. Progress & Indicator
| Component | Props หลัก | คำอธิบาย |
|-----------|-----------|----------|
| `LoadingProgressBar` | `current, target, unit` | Progress Bar น้ำหนักโหลด |
| `StockGauge` | `current, min, capacity` | Gauge Stock Level |
| `WeightDisplay` | `current, target, diff` | แสดงน้ำหนัก Current vs Target |
| `TimerDisplay` | `startTime, status` | นับเวลา Loading / Waiting |
| `ThroughputMeter` | `value, unit, threshold` | Meter ค่า Throughput |

### E. Table Components
| Component | Props หลัก | คำอธิบาย |
|-----------|-----------|----------|
| `DataTable` | `columns, data, pagination, sortable` | Table ทั่วไปพร้อม Sort/Page |
| `QueueTable` | `queues, onCall, onCancel` | ตาราง Queue พร้อม Action |
| `OrderTable` | `orders, onSelect, filters` | ตาราง Order |
| `TruckTable` | `trucks, onEdit, onView` | ตาราง Truck/Driver |
| `LoadJobTable` | `jobs, onView, filters` | ตาราง Loading Job |
| `HardwareTable` | `devices, onConfig` | ตาราง Hardware Device |

### F. Form Components
| Component | Props หลัก | คำอธิบาย |
|-----------|-----------|----------|
| `OrderForm` | `onSubmit, initialData` | ฟอร์มสร้าง Order |
| `TruckForm` | `onSubmit, initialData` | ฟอร์มลงทะเบียนรถ |
| `DriverForm` | `onSubmit, initialData` | ฟอร์มลงทะเบียนคนขับ |
| `ChecklistForm` | `items, onSubmit, jobId` | ฟอร์ม Double Check |
| `WeightInputForm` | `targetWeight, onSubmit` | กรอกน้ำหนักจริง |
| `DateRangeFilter` | `from, to, onChange, presets` | เลือกช่วงวันที่ |

### G. QR Components
| Component | Props หลัก | คำอธิบาย |
|-----------|-----------|----------|
| `QrDisplay` | `token, jobId, truckPlate, product` | แสดง QR Code |
| `QrScanner` | `onScan, onError, mode` | สแกน QR (Camera/Input) |
| `QrResult` | `status, orderInfo, truckInfo, message` | ผลการ Verify QR |
| `QrPrintLayout` | `jobId, token, details` | Layout พิมพ์ QR |

### H. Modal / Dialog
| Component | Props หลัก | คำอธิบาย |
|-----------|-----------|----------|
| `ConfirmDialog` | `title, message, onConfirm, onCancel, variant` | Dialog ยืนยัน |
| `EmergencyDialog` | `bayId, onConfirm, onCancel` | Dialog Emergency Stop (2-step) |
| `TruckCallModal` | `queue, bays, onCall` | Modal เรียกรถ + เลือก Bay |
| `WeightVerifyModal` | `job, onVerify` | Modal ยืนยันน้ำหนัก |
| `ReleaseGateModal` | `job, checklist, onRelease` | Modal อนุมัติปล่อยรถ |

### I. Hardware Components
| Component | Props หลัก | คำอธิบาย |
|-----------|-----------|----------|
| `DeviceStatusCard` | `device: HardwareDevice` | Card สถานะ Device |
| `DeviceStatusGrid` | `devices` | Grid แสดงทุก Device |
| `HardwareEventLog` | `events, filter` | Log Event จาก Hardware |
| `SimulationPanel` | `onTrigger, deviceType` | Panel ทดสอบ Dry-run |

### J. Navigation
| Component | Props หลัก | คำอธิบาย |
|-----------|-----------|----------|
| `NavItem` | `icon, label, path, isActive, badge` | รายการเมนู |
| `NavSection` | `label, children` | กลุ่มเมนู |
| `BreadcrumbNav` | `items` | Breadcrumb |
| `AnalyticsTabNav` | `activeTab, onTabChange` | Tab Navigation ใน Analytics |

---

## 6. App Shell Layout

### ASCII Wireframe — App Shell (PC 1920x1080)

```
+--------------------------------------------------------------------------+
|  TOP BAR (h-16, bg-white, border-b border-slate-200, shadow-sm)          |
|  [Logo]  Smart Load Bulk        Breadcrumb       [Bell 3]  [Gear] [User] |
+--------+-----------------------------------------------------------------+
|SIDEBAR  | CONTENT AREA (flex-1, bg-slate-50, overflow-y-auto)            |
|(w-60)   |                                                                 |
|         |  +--------------------------------------------------------------+|
|[Logo]   |  |  PAGE HEADER                                                ||
|         |  |  Page Title / Description          [Action Buttons]         ||
|---------|  +--------------------------------------------------------------+|
|         |                                                                 |
|Overview |  +----------------------------------------------------------+   |
| Main    |  |                                                          |   |
| Inv.    |  |     PAGE CONTENT                                         |   |
| Queue   |  |     (Cards / Tables / Charts / Forms)                    |   |
|         |  |                                                          |   |
|Loading  |  +----------------------------------------------------------+   |
| Bay     |                                                                 |
| QR      |                                                                 |
| Check   |                                                                 |
|         |                                                                 |
|Register |                                                                 |
| Trucks  |                                                                 |
| Orders  |                                                                 |
|         |                                                                 |
|Monitor  |                                                                 |
| HW      |                                                                 |
|         |                                                                 |
|Analytic |                                                                 |
| Perf.   |                                                                 |
| Loss    |                                                                 |
| Bay     |                                                                 |
| Truck   |                                                                 |
|         |                                                                 |
|Reports  |                                                                 |
|Setting  |                                                                 |
|         |                                                                 |
|[Logout] |                                                                 |
+---------+-----------------------------------------------------------------+
```

### Sidebar Menu Structure
```
Overview
  Main Dashboard        /dashboard
  Inventory Dashboard   /inventory

Loading
  Order & Queue         /queue
  Bay Monitor           /bay
  QR Verification       /qr/scan
  Double Check          /check

Register
  Trucks & Drivers      /trucks
  Orders                /orders

Monitor
  Hardware Status       /hardware

Analytics
  Performance           /analytics
  Loss / Yield          /analytics/loss-yield
  Bay Performance       /analytics/bay
  Truck Turnaround      /analytics/turnaround

Reports               /reports
Settings              /settings
```

---

## 7. Layout แต่ละหน้า (14 หน้า)

---

### หน้า 1: Main Dashboard (`/dashboard`)

**วัตถุประสงค์:** ภาพรวมระบบทั้งหมดในหน้าเดียว Supervisor เปิดดูได้ทุกเช้า

```
+---------------------------------------------------------------------+
|  Main Dashboard   วันที่ เวลา Real-time        [Refresh] [TV Mode]  |
+---------------------------------------------------------------------+
|  KPI ROW — 5 Cards (grid-cols-5 gap-4)                               |
|  +----------+ +----------+ +----------+ +----------+ +----------+   |
|  | Trucks   | | Loading  | | Waiting  | | Complete | |Throughput|   |
|  |   12     | |    4     | |    5     | |    3     | | 48.5 t/h |   |
|  | Today    | |  Now     | |  Queue   | |  Today   | |          |   |
|  +----------+ +----------+ +----------+ +----------+ +----------+   |
|                                                                      |
|  BAY STATUS GRID (grid-cols-4 gap-4)                                 |
|  +--------------------+  +--------------------+                      |
|  | BAY 01             |  | BAY 02             |                      |
|  | [LOADING]          |  | [AVAILABLE]        |                      |
|  | ทะเบียน: 80-1234   |  |                    |                      |
|  | Feed A             |  | ว่าง / พร้อมรับรถ  |                      |
|  | XXXXXXXXXX 78%     |  |                    |                      |
|  | 15.6 / 20 ตัน      |  |                    |                      |
|  +--------------------+  +--------------------+                      |
|  +--------------------+  +--------------------+                      |
|  | BAY 03             |  | BAY 04             |                      |
|  | [CALLING]          |  | [ERROR]            |                      |
|  | ทะเบียน: 80-5678   |  | Emergency Stop     |                      |
|  |                    |  | [Resume] [Cancel]  |                      |
|  +--------------------+  +--------------------+                      |
|                                                                      |
|  +--------------------------+ +--------------------------+           |
|  | QUEUE WAITING (5)        | | LOW STOCK ALERTS (2)     |           |
|  | Q001 | 80-1111 | 20t     | | Feed B -- 12 ton LOW     |           |
|  | Q002 | 80-2222 | 15t     | | Feed C -- 3 ton CRITICAL |           |
|  | Q003 | 80-3333 | 25t     | |                          |           |
|  | [View Queue Board]       | | [View Inventory]         |           |
|  +--------------------------+ +--------------------------+           |
|                                                                      |
|  NOTIFICATION LOG (5 ล่าสุด)                                         |
|  +---------------------------------------------------------------------+  |
|  | 10:32  EMERGENCY STOP -- Bay 04 -- กด Stop Panel               |  |
|  | 10:15  Bay 02 -- Job เสร็จ -- 80-9988 -- 20.1 ตัน              |  |
|  | 09:45  Stock Alert -- Feed C ต่ำกว่า Minimum                  |  |
|  +---------------------------------------------------------------------+  |
+---------------------------------------------------------------------+
```

**shadcn/ui:** `Card, Badge, Progress, ScrollArea`
**Responsive:** PC: 5 KPI / 4 Bay Cards | Tablet: 3 KPI / 2 Bay Cards

---

### หน้า 2: Inventory Dashboard (`/inventory`)

**วัตถุประสงค์:** ดูสต็อกสินค้าทุกตัว พร้อมสถานะและ Alert

```
+---------------------------------------------------------------------+
|  Inventory Dashboard           [+ Adjust Stock] [Export]            |
+---------------------------------------------------------------------+
|  SUMMARY KPI ROW (grid-cols-4 gap-4)                                 |
|  +----------+ +----------+ +----------+ +----------+                |
|  | Products | | Low Stock| | Critical | | Total    |                |
|  |    8     | |    2     | |    1     | | 480 ตัน  |                |
|  +----------+ +----------+ +----------+ +----------+                |
|                                                                      |
|  FILTER: [ค้นหาสินค้า] [สถานะ: All] [Silo: All]                      |
|                                                                      |
|  INVENTORY CARDS (grid-cols-3 gap-4)                                 |
|  +------------------------+ +------------------------+               |
|  | Feed A (Silo 1)        | | Feed B (Silo 2)        |               |
|  | [NORMAL]               | | [LOW]                  |               |
|  | XXXXXXXXXXXX 85%       | | XXXX         28%       |               |
|  | 85 ton / Cap 100 ton   | | 12 ton / Min 43 ton    |               |
|  | Min: 20 ton            | | Min: 20 ton            |               |
|  | Updated: 10:32         | | Updated: 09:15         |               |
|  +------------------------+ +------------------------+               |
|  +------------------------+ +------------------------+               |
|  | Feed C (Silo 3)        | | Feed D (Silo 4)        |               |
|  | [CRITICAL]             | | [NORMAL]               |               |
|  | X             8%       | | XXXXXXXXXX   72%       |               |
|  | 3 ton / Min 40 ton     | | 72 ton / Cap 100 ton   |               |
|  +------------------------+ +------------------------+               |
|                                                                      |
|  STOCK MOVEMENT CHART (7 วันย้อนหลัง)                                |
|  [Recharts BarChart — Inbound vs Outbound — X: Date, Y: ton]        |
|                                                                      |
|  INVENTORY HISTORY TABLE                                             |
|  +--+----------+------+------+-------+-----------------------+      |
|  |# | สินค้า   | Type | Qty  | Stock | เวลา                  |      |
|  +--+----------+------+------+-------+-----------------------+      |
|  |1 | Feed A   | OUT  | -20t | 85t   | 2026-05-14 10:15      |      |
|  |2 | Feed C   | OUT  | -5t  | 3t    | 2026-05-14 09:45      |      |
|  +--+----------+------+------+-------+-----------------------+      |
+---------------------------------------------------------------------+
```

**recharts:** `BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend`
**shadcn/ui:** `Card, Badge, Progress, Table`
**Responsive:** PC: 4 KPI / 3-col Cards | Tablet: 2 KPI / 2-col Cards

---

### หน้า 3: Order & Queue (`/queue`)

**วัตถุประสงค์:** จัดการคิวรถบรรทุก ดูสถานะ และเรียกรถเข้า Bay

```
+---------------------------------------------------------------------+
|  Order & Queue Board           [+ New Order] [Refresh]              |
+---------------------------------------------------------------------+
|  FILTER: [ค้นหา] [วันที่: Today] [สถานะ: All] [Priority: All]        |
|                                                                      |
|  QUEUE SUMMARY (4 Cards)                                             |
|  +----------+ +----------+ +----------+ +----------+                |
|  | Waiting  | | Called   | | Loading  | |Completed |                |
|  |    5     | |    2     | |    4     | |    8     |                |
|  +----------+ +----------+ +----------+ +----------+                |
|                                                                      |
|  QUEUE TABLE                                                         |
|  +--+--------+----------+----------+------+----------+----------+   |
|  |# | Queue  | Truck    | Product  |Weight| Status   | Action   |   |
|  +--+--------+----------+----------+------+----------+----------+   |
|  |1 |Q001    | 80-1234  | Feed A   | 20t  |[WAITING] |[Call][X] |   |
|  |2 |Q002    | 80-5678  | Feed B   | 15t  |[CALLED]  |[View]    |   |
|  |3 |Q003    | 80-9012  | Feed A   | 25t  |[LOADING] |[View]    |   |
|  |4 |Q004    | 80-3456  | Feed C   | 10t  |[URGENT]  |[Call][X] |   |
|  +--+--------+----------+----------+------+----------+----------+   |
|  Pagination: [1] [2] [3] Next                                       |
+---------------------------------------------------------------------+
```

**shadcn/ui:** `Table, Badge, Button, Select, Input, Dialog`
**Responsive:** PC: Full Table | Tablet: Card View

---

### หน้า 4: Truck Register (`/trucks`)

**วัตถุประสงค์:** ลงทะเบียนและจัดการรถบรรทุกและคนขับ

```
+---------------------------------------------------------------------+
|  Truck Register         [+ Register Truck] [+ Register Driver]       |
+---------------------------------------------------------------------+
|  TAB: [Trucks | Drivers | Truck-Driver Map]                          |
|                                                                      |
|  (Tab: Trucks)                                                       |
|  FILTER: [ค้นหาทะเบียน] [ประเภท: All] [สถานะ: All]                    |
|                                                                      |
|  TRUCK TABLE                                                         |
|  +--+-----------+----------+----------+------+----------+--------+  |
|  |# | ทะเบียน   | ประเภท   | Capacity | คนขับ| สถานะ   | Action |  |
|  +--+-----------+----------+----------+------+----------+--------+  |
|  |1 | 80-1234   | FRONT    | 25 ตัน  | สมชาย|[ACTIVE]  |[Edit]  |  |
|  |2 | 80-5678   | REAR     | 20 ตัน  | สุดา |[ACTIVE]  |[Edit]  |  |
|  |3 | 80-9012   | FRONT    | 25 ตัน  | -    |[INACTIVE]|[Edit]  |  |
|  +--+-----------+----------+----------+------+----------+--------+  |
|                                                                      |
|  (Tab: Drivers)                                                      |
|  DRIVER TABLE                                                        |
|  +--+------------+----------+------------+------+----------+------+ |
|  |# | ชื่อ       | เบอร์โทร | License No | รถ   | สถานะ   | Act  | |
|  +--+------------+----------+------------+------+----------+------+ |
|  |1 | สมชาย ดี   | 081-xxxx | DL-12345   |80-1234|[ACTIVE] |[Edit]| |
|  +--+------------+----------+------------+------+----------+------+ |
+---------------------------------------------------------------------+
```

**shadcn/ui:** `Tabs, Table, Badge, Button, Dialog`
**Responsive:** PC: Full Table | Tablet: Row Expand

---

### หน้า 5: Truck Calling Display — TV Mode (`/bay?display=tv`)

**วัตถุประสงค์:** จอใหญ่ในโรงงานแสดงคิวรถ อ่านได้จากระยะไกล

```
+-------------------------------------------------------------------------+
|  bg-slate-900 FULL SCREEN — NO SIDEBAR — NO TOPBAR                      |
|                                                                          |
|  +-------------------------------------------------------------------+  |
|  | SMART LOAD BULK - TRUCK CALLING BOARD        10:32:45             |  |
|  | [text-white text-3xl font-bold]     [text-slate-300 text-xl]      |  |
|  +-------------------------------------------------------------------+  |
|                                                                          |
|  +--------------------------------+ +--------------------------------+   |
|  | BAY 01          [LOADING]      | | BAY 02          [IDLE]         |   |
|  | bg-blue-900/40 border-blue-500 | | bg-slate-800 border-slate-600  |   |
|  |                                | |                                |   |
|  |   80-1234 กข                  | |   ว่าง / พร้อมรับรถ            |   |
|  |  [text-7xl font-black white]  | |   [text-2xl text-slate-300]    |   |
|  |                                | |                                |   |
|  |  XXXXXXXXXXXXXXXX   78%        | |                                |   |
|  |  15,600 / 20,000 kg            | |                                |   |
|  |  [text-4xl font-bold blue-200] | |                                |   |
|  +--------------------------------+ +--------------------------------+   |
|                                                                          |
|  +--------------------------------+ +--------------------------------+   |
|  | BAY 03          [CALLING]      | | BAY 04   [!! EMERGENCY !!]     |   |
|  | bg-amber-900/40 border-amber   | | bg-red-900 border-red pulse    |   |
|  |                                | |                                |   |
|  | โปรดเข้า Bay 03                | |   !! หยุดฉุกเฉิน !!            |   |
|  |                                | |   [text-5xl red-200]           |   |
|  |   80-5678 กข                  | |                                |   |
|  |  [text-7xl font-black amber]  | |   รอ Supervisor ตรวจสอบ        |   |
|  |  Feed B  25 ตัน               | |   [text-2xl red-300]           |   |
|  +--------------------------------+ +--------------------------------+   |
|                                                                          |
|  +-------------------------------------------------------------------+  |
|  | WAITING QUEUE                                                     |  |
|  | Q001  80-1111  |  Feed A  |  20 ton  |  [URGENT]                 |  |
|  | Q002  80-2222  |  Feed B  |  15 ton  |  [NORMAL]                 |  |
|  | [text-3xl white]                                                  |  |
|  +-------------------------------------------------------------------+  |
+-------------------------------------------------------------------------+
```

**หมายเหตุ TV Display:**
- Dark Background (`bg-slate-900`) ลดแสงสะท้อน
- Font Size ขั้นต่ำ 36px สำหรับ Label ทั่วไป
- Truck Plate: `text-7xl font-black` (72px)
- Auto-refresh ผ่าน SignalR ไม่ต้อง F5
- URL param: `?display=tv` Toggle Layout

---

### หน้า 6: Loading Verification — QR Scan (`/qr/scan`)

**วัตถุประสงค์:** สแกน QR Code เพื่อยืนยัน Job และเริ่มโหลด

```
+---------------------------------------------------------------------+
|  QR Verification          [Switch: Camera / Manual Input]           |
+---------------------------------------------------------------------+
|                                                                      |
|  +----------------------------+  +------------------------------+    |
|  |  QR SCANNER AREA           |  |  SCAN RESULT                 |    |
|  |                            |  |                              |    |
|  |  +----------------------+  |  |  (รอ Scan)                   |    |
|  |  |                      |  |  |  รอการสแกน QR               |    |
|  |  |   [Camera View]      |  |  |  หรือกรอก Token             |    |
|  |  |   or                 |  |  |                              |    |
|  |  |   [QR Code Image]    |  |  |  (Scan สำเร็จ)              |    |
|  |  |                      |  |  |  +------------------------+  |    |
|  |  +----------------------+  |  |  | [VERIFIED] bg-green-50 |  |    |
|  |                            |  |  | Order: ORD-001         |  |    |
|  |  Manual Input:             |  |  | Truck: 80-1234         |  |    |
|  |  [Token: ___________]      |  |  | Driver: สมชาย          |  |    |
|  |  [Verify]                  |  |  | Product: Feed A        |  |    |
|  |                            |  |  | Weight: 20 ton         |  |    |
|  +----------------------------+  |  | [Select Bay]           |  |    |
|                                  |  | [Start Loading]        |  |    |
|                                  |  +------------------------+  |    |
|                                  |                              |    |
|                                  |  (Scan ผิดพลาด)             |    |
|                                  |  +------------------------+  |    |
|                                  |  | [ERROR] bg-red-50      |  |    |
|                                  |  | Token Expired/Used     |  |    |
|                                  |  | [Try Again]            |  |    |
|                                  |  +------------------------+  |    |
|                                  +------------------------------+    |
|                                                                      |
|  RECENT SCANS (5 ล่าสุด)                                            |
|  +------+--------+----------+----------+-----------------+          |
|  | #    | Truck  | Result   | Bay      | เวลา            |          |
|  +------+--------+----------+----------+-----------------+          |
|  | QR01 |80-1234 |[SUCCESS] | Bay 01   | 10:32           |          |
|  | QR02 |80-5678 |[EXPIRED] | -        | 10:15           |          |
|  +------+--------+----------+----------+-----------------+          |
+---------------------------------------------------------------------+
```

**shadcn/ui:** `Card, Badge, Button, Select, Alert`
**Responsive:** PC: 2-col (Scanner + Result) | Tablet: Stack vertical

---

### หน้า 7: Double Check Loading (`/check/:jobId`)

**วัตถุประสงค์:** ตรวจสอบรายการก่อนปล่อยรถ Supervisor Approve

```
+---------------------------------------------------------------------+
|  Double Check Loading                    Job #JOB-2026-001          |
+---------------------------------------------------------------------+
|  JOB SUMMARY (Card)                                                  |
|  Order: ORD-001 | Bay: Bay 01 | Truck: 80-1234                      |
|  Product: Feed A | Target: 20.00 ton | Actual: 20.05 ton            |
|  Yield: 100.25% [NORMAL bg-green-50]                                |
|                                                                      |
|  WEIGHT VERIFICATION                                                 |
|  Target: 20,000 kg                                                  |
|  Actual: 20,050 kg  [text-2xl blue-700 bold]                        |
|  Diff:   +50 kg (0.25%)  [text-green-600]                           |
|                                                                      |
|  CHECKLIST (grid-cols-2 gap-3)                                       |
|  [X] น้ำหนักตรงตาม Order           Required                         |
|  [X] สินค้าถูก Product             Required                         |
|  [X] ปิดฝา/Cover เรียบร้อย         Required                         |
|  [X] Seal ติดแล้ว                  Required                         |
|  [ ] เอกสาร DO/Invoice ครบ         Required  <- ยังไม่ Tick         |
|  [ ] คนขับลงชื่อรับแล้ว            Required  <- ยังไม่ Tick         |
|                                                                      |
|  (Warning: ยังมีรายการค้าง)                                          |
|  [!] รายการ 5,6 ยังไม่ผ่าน กรุณาตรวจสอบก่อน Release               |
|                                                                      |
|  ACTIONS                                                             |
|  [Override + Reason]    [Back]    [Confirm & Release] <- Disabled   |
+---------------------------------------------------------------------+
```

**shadcn/ui:** `Card, Checkbox, Alert, Button, Dialog`
**Responsive:** PC: 2-col Checklist | Tablet: 1-col Checklist

---

### หน้า 8: Hardware Monitor (`/hardware`)

**วัตถุประสงค์:** ดูสถานะ Hardware ทุกตัวในโรงงาน

```
+---------------------------------------------------------------------+
|  Hardware Monitor       [Simulation Mode: OFF] [Refresh All]         |
+---------------------------------------------------------------------+
|  DEVICE SUMMARY (3 Cards)                                            |
|  +----------+ +----------+ +----------+                              |
|  | Online   | | Offline  | | Error    |                              |
|  |    6     | |    1     | |    0     |                              |
|  +----------+ +----------+ +----------+                              |
|                                                                      |
|  DEVICE STATUS GRID (grid-cols-3 gap-4)                              |
|  +-------------------------+ +-------------------------+              |
|  | [dot] ONLINE            | | [dot] ONLINE            |              |
|  | QR Scanner -- Bay 01    | | QR Scanner -- Bay 02    |              |
|  | IP: 192.168.1.101       | | IP: 192.168.1.102       |              |
|  | Protocol: TCP 9001      | | Protocol: TCP 9001      |              |
|  | Last Seen: 2 sec ago    | | Last Seen: 2 sec ago    |              |
|  | [Config] [Test Ping]    | | [Config] [Test Ping]    |              |
|  +-------------------------+ +-------------------------+              |
|  +-------------------------+ +-------------------------+              |
|  | [dot] ONLINE            | | [dot] OFFLINE pulse     |              |
|  | Radar -- Bay 01         | | Loading Panel -- Bay 04 |              |
|  | Protocol: Modbus 502    | | Last Seen: 1 hr ago     |              |
|  | Distance: 0.8m          | | !! Connection Timeout   |              |
|  | [Config]                | | [Config] [Reconnect]    |              |
|  +-------------------------+ +-------------------------+              |
|                                                                      |
|  TAB: [Event Log | Simulation]                                       |
|  +------------+----------------+-----------------+--------------+    |
|  | เวลา       | Device         | Event           | Value        |    |
|  +------------+----------------+-----------------+--------------+    |
|  | 10:32:01   | Radar-Bay01    | TRUCK_DETECTED  | dist=0.8m    |    |
|  | 10:31:45   | QR-Bay01       | QR_SCANNED      | token=abc123 |    |
|  | 10:30:00   | Panel-Bay02    | WEIGHT_UPDATE   | 15600 kg     |    |
|  +------------+----------------+-----------------+--------------+    |
+---------------------------------------------------------------------+
```

**shadcn/ui:** `Card, Badge, Tabs, Table, Button, Switch`
**Responsive:** PC: 3-col Grid | Tablet: 2-col Grid

---

### หน้า 9: Performance Dashboard — Overview (`/analytics`)

ดูรายละเอียดใน `docs/UI_PERFORMANCE_DASHBOARD_DESIGN.md`

---

### หน้า 10: Loss/Yield Dashboard (`/analytics/loss-yield`)

ดูรายละเอียดใน `docs/UI_PERFORMANCE_DASHBOARD_DESIGN.md`

---

### หน้า 11: Bay Performance Dashboard (`/analytics/bay`)

ดูรายละเอียดใน `docs/UI_PERFORMANCE_DASHBOARD_DESIGN.md`

---

### หน้า 12: Truck Turnaround Dashboard (`/analytics/turnaround`)

ดูรายละเอียดใน `docs/UI_PERFORMANCE_DASHBOARD_DESIGN.md`

---

### หน้า 13: Report Page (`/reports`)

**วัตถุประสงค์:** สร้าง Report และ Export ข้อมูล

```
+---------------------------------------------------------------------+
|  Reports                                                             |
+---------------------------------------------------------------------+
|  REPORT TYPES (grid-cols-3 gap-4)                                    |
|  +------------------------+ +------------------------+               |
|  | Loading Report          | | Inventory Report        |               |
|  | รายการโหลดตาม Period   | | Stock Movement          |               |
|  | [Excel] [PDF]          | | [Excel] [PDF]          |               |
|  +------------------------+ +------------------------+               |
|  +------------------------+ +------------------------+               |
|  | Loss/Yield Report      | | Truck Performance       |               |
|  | รายงาน Loss/Yield      | | ประสิทธิภาพรถ          |               |
|  | [Excel] [PDF]          | | [Excel] [PDF]          |               |
|  +------------------------+ +------------------------+               |
|                                                                      |
|  REPORT BUILDER                                                      |
|  +---------------------------------------------------------------+  |
|  | ประเภทรายงาน: [Loading Report]                                |  |
|  | ช่วงวันที่: [2026-05-01] ถึง [2026-05-14]                     |  |
|  | สินค้า: [All]  Bay: [All]  Status: [All]                      |  |
|  | Format: [Excel] [PDF]                    [Generate Report]    |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  RECENT REPORTS                                                      |
|  +----------------------+------------+--------+--------------+       |
|  | ชื่อรายงาน           | วันที่      | Format | Action       |       |
|  +----------------------+------------+--------+--------------+       |
|  | Loading_2026-05-14   | 14/05 10:30| Excel  | [Download]   |       |
|  | LossYield_May2026    | 13/05 08:00| PDF    | [Download]   |       |
|  +----------------------+------------+--------+--------------+       |
+---------------------------------------------------------------------+
```

**shadcn/ui:** `Card, Button, Select, Input, Table, DatePicker`
**Responsive:** PC: 3-col Report Types | Tablet: 2-col

---

### หน้า 14: Setting Page (`/settings`)

**วัตถุประสงค์:** ตั้งค่าระบบ Threshold, Integration, User Management

```
+---------------------------------------------------------------------+
|  Settings                                                            |
+---------------------------------------------------------------------+
|  TAB: [General | Analytics Threshold | Hardware | Integration | Users]|
|                                                                      |
|  (Tab: Analytics Threshold)                                          |
|  +---------------------------------------------------------------+  |
|  | Yield Threshold                                               |  |
|  |   Normal Range:   [99.5]% to [100.5]%                        |  |
|  |   Warning Range:  [98.0]% to [99.5]%  or [100.5]% to [102]%  |  |
|  |   Critical:       < [98.0]%  or > [102]%                     |  |
|  |                                                               |  |
|  | Loading Accuracy Minimum: [95]%                               |  |
|  | Working Hours per Day: [16] hours                             |  |
|  |                                           [Save Settings]    |  |
|  +---------------------------------------------------------------+  |
|                                                                      |
|  (Tab: Users) -- ADMIN Only                                          |
|  +--+--------------+---------+------------+--------+----------+      |
|  |# | Username     | Role    | Last Login | Status | Action   |      |
|  +--+--------------+---------+------------+--------+----------+      |
|  |1 | admin        | ADMIN   | Today      |[ACTIVE]|[Edit]    |      |
|  |2 | supervisor1  | SUPERV  | Today      |[ACTIVE]|[Edit]    |      |
|  |3 | operator1    | OPER    | Yesterday  |[ACTIVE]|[Edit]    |      |
|  +--+--------------+---------+------------+--------+----------+      |
|  [+ Add User]                                                        |
+---------------------------------------------------------------------+
```

**shadcn/ui:** `Tabs, Card, Input, Select, Switch, Table, Button`
**Responsive:** PC/Tablet: Same Layout

---

## 8. Queue Board UI — Truck Queue Status

### Queue Card Design
```
+----------------------------------------------------------+
|  Q001                                      [URGENT]      |
|  border-l-4 border-red-500 bg-red-50                     |
+----------------------------------------------------------+
|  Truck:    80-1234 กข                                    |
|  Driver:   สมชาย ดีใจ                                    |
|  Product:  Feed A                                        |
|  Weight:   20.00 ton                                     |
|  Bay:      รอกำหนด                                       |
|  Wait:     00:23:15  [TimerDisplay animate]              |
+----------------------------------------------------------+
|  [Call Truck]    [Change Priority]    [Cancel]           |
+----------------------------------------------------------+
```

### Queue Status Color Rules
| Status | Card Left Border | Background | Badge |
|--------|-----------------|------------|-------|
| WAITING | `border-slate-300` | `bg-white` | `bg-slate-100 text-slate-600` |
| WAITING URGENT | `border-red-500` | `bg-red-50` | `bg-red-600 text-white` |
| CALLED | `border-amber-500` | `bg-amber-50` | `bg-amber-500 text-white` |
| LOADING | `border-blue-500` | `bg-blue-50` | `bg-blue-600 text-white` |
| COMPLETED | `border-green-500` | `bg-green-50` | `bg-green-600 text-white` |

---

## 9. Loading Status UI — Real-time Loading Progress

### Bay Loading Card (Real-time)
```
+--------------------------------------------------------------+
|  BAY 01                                       [LOADING]      |
|  bg-blue-600 text-white badge                                |
+--------------------------------------------------------------+
|  Truck:   80-1234 กข                                         |
|  Product: Feed A                                             |
|  Order:   ORD-2026-001                                       |
+--------------------------------------------------------------+
|  Current Weight:                                             |
|                                                              |
|  XXXXXXXXXXXXXXXXXXXXXXXXXXXX         78%                    |
|  [bg-blue-600 h-4 rounded-full w-78%]                        |
|                                                              |
|  15,600 kg           /          20,000 kg                    |
|  [text-3xl blue-700 bold]        [text-xl slate-500]         |
|                                                              |
|  Diff: -4,400 kg remaining                                   |
+--------------------------------------------------------------+
|  Start: 10:15:00 | Elapsed: 00:17:32 [TimerDisplay]          |
|  Throughput: 53.2 ton/hour                                   |
+--------------------------------------------------------------+
|  [Emergency Stop - red]         [Complete Loading - green]   |
+--------------------------------------------------------------+
```

---

## 10. QR Verification UI

### QR Success State
```
+----------------------------------------------+
|  bg-green-50 border-green-200 rounded-xl      |
|                                               |
|  [checkmark]  VERIFIED                        |
|  text-green-600 text-2xl font-bold            |
|                                               |
|  Order:   ORD-2026-001                        |
|  Truck:   80-1234 กข                          |
|  Driver:  สมชาย ดีใจ                          |
|  Product: Feed A                              |
|  Weight:  20.00 ton                           |
|  Valid:   Until 18:32:00                      |
|                                               |
|  Bay:  [Bay 01]  [Bay 02]  [Bay 03]           |
|                                               |
|  [Start Loading at Bay 01]                    |
|  bg-blue-600 text-white                       |
+----------------------------------------------+
```

### QR Error State
```
+----------------------------------------------+
|  bg-red-50 border-red-200 rounded-xl          |
|                                               |
|  [x]  INVALID QR                              |
|  text-red-600 text-2xl font-bold              |
|                                               |
|  Token หมดอายุ / ถูกใช้ไปแล้ว                 |
|  กรุณาขอ QR ใหม่จาก Supervisor               |
|                                               |
|  [Scan Again]                                 |
|  bg-slate-600 text-white                      |
+----------------------------------------------+
```

---

## 11. Hardware Status UI

### Device ONLINE Card
```
+---------------------------------------+
|  [dot-green] ONLINE   bg-green-50     |
|  QR Scanner -- Bay 01                 |
+---------------------------------------+
|  Type:      QR_SCANNER                |
|  Protocol:  TCP                       |
|  Address:   192.168.1.101:9001        |
|  Last Seen: 2 sec ago                 |
|  Uptime:    8h 23m                    |
+---------------------------------------+
|  [Config]          [Test Ping]        |
+---------------------------------------+
```

### Device OFFLINE Card
```
+---------------------------------------+
|  [dot-red] OFFLINE  bg-red-50 pulse   |
|  Loading Panel -- Bay 04              |
+---------------------------------------+
|  Type:      LOADING_PANEL             |
|  Protocol:  Modbus TCP                |
|  Address:   192.168.1.204:502         |
|  Last Seen: 1 hour ago                |
|  Error:     Connection Timeout        |
+---------------------------------------+
|  [Config]  [Reconnect]  [View Log]    |
+---------------------------------------+
```

---

## 12. Tailwind Design Tokens

### ไฟล์ `tailwind.config.js` — Extended Theme

```javascript
// tailwind.config.js
module.exports = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50:  '#EFF6FF',
          100: '#DBEAFE',
          500: '#3B82F6',
          600: '#2563EB',
          700: '#1D4ED8',
        },
        success: {
          50:  '#F0FDF4',
          100: '#DCFCE7',
          500: '#22C55E',
          600: '#16A34A',
          700: '#15803D',
        },
        warning: {
          50:  '#FFFBEB',
          100: '#FEF3C7',
          500: '#F59E0B',
          600: '#D97706',
          700: '#B45309',
        },
        danger: {
          50:  '#FEF2F2',
          100: '#FEE2E2',
          500: '#EF4444',
          600: '#DC2626',
          700: '#B91C1C',
        },
        bay: {
          idle:     '#16A34A',
          calling:  '#D97706',
          loading:  '#2563EB',
          error:    '#DC2626',
          occupied: '#7C3AED',
        },
      },
      fontFamily: {
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'sans-serif'],
        mono: ['JetBrains Mono', 'Consolas', 'monospace'],
      },
      fontSize: {
        'kpi-sm':  ['30px', { lineHeight: '36px', fontWeight: '700' }],
        'kpi-md':  ['36px', { lineHeight: '44px', fontWeight: '700' }],
        'kpi-lg':  ['48px', { lineHeight: '56px', fontWeight: '800' }],
        'kpi-xl':  ['60px', { lineHeight: '68px', fontWeight: '800' }],
        'kpi-2xl': ['72px', { lineHeight: '80px', fontWeight: '900' }],
      },
      boxShadow: {
        'card':    '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
        'card-lg': '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
      },
      animation: {
        'pulse-fast': 'pulse 0.8s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
    },
  },
  plugins: [],
}
```

---

## 13. React Component Structure

### Folder Structure
```
src/
  app/
    App.tsx
    router.tsx
    providers.tsx

  components/
    layout/
      AppShell.tsx
      Sidebar.tsx
      TopBar.tsx
      PageContainer.tsx
      SectionHeader.tsx

    common/
      StatusBadge.tsx
      PriorityBadge.tsx
      StockLevelBadge.tsx
      KpiBadge.tsx
      StatusDot.tsx
      LoadingSpinner.tsx
      EmptyState.tsx
      ErrorBoundary.tsx

    dashboard/
      KpiCard.tsx
      KpiCardBig.tsx
      BayStatusCard.tsx
      AlertCard.tsx
      NotificationFeed.tsx

    inventory/
      InventoryCard.tsx
      StockGauge.tsx

    queue/
      QueueCard.tsx
      QueueTable.tsx
      TruckCallModal.tsx

    loading/
      LoadingProgressBar.tsx
      WeightDisplay.tsx
      TimerDisplay.tsx
      BayLoadingCard.tsx
      EmergencyDialog.tsx

    qr/
      QrDisplay.tsx
      QrScanner.tsx
      QrResult.tsx

    checklist/
      ChecklistForm.tsx
      WeightVerifyCard.tsx
      ReleaseGateModal.tsx

    hardware/
      DeviceStatusCard.tsx
      DeviceStatusGrid.tsx
      HardwareEventLog.tsx
      SimulationPanel.tsx

    analytics/
      KpiCardAnalytics.tsx
      DateRangeFilter.tsx
      ExportButton.tsx
      ThresholdBadge.tsx

    tables/
      DataTable.tsx
      OrderTable.tsx
      TruckTable.tsx
      LoadJobTable.tsx

  pages/
    dashboard/
      MainDashboardPage.tsx
    inventory/
      InventoryPage.tsx
      InventoryDetailPage.tsx
    queue/
      QueuePage.tsx
    orders/
      OrderListPage.tsx
      OrderFormPage.tsx
    trucks/
      TruckRegisterPage.tsx
    bay/
      BayOverviewPage.tsx
      BayDetailPage.tsx
      BayTvDisplayPage.tsx
    qr/
      QrScanPage.tsx
      QrGeneratePage.tsx
    check/
      DoubleCheckPage.tsx
    hardware/
      HardwareMonitorPage.tsx
    analytics/
      PerformanceDashboardPage.tsx
      LossYieldDashboardPage.tsx
      BayPerformanceDashboardPage.tsx
      TruckTurnaroundDashboardPage.tsx
    reports/
      ReportPage.tsx
    settings/
      SettingsPage.tsx

  hooks/
    useSignalR.ts
    useBayStatus.ts
    useQueueBoard.ts
    useInventory.ts
    useAnalytics.ts

  stores/
    bayStore.ts
    queueStore.ts
    inventoryStore.ts
    notificationStore.ts

  types/
    bay.types.ts
    queue.types.ts
    inventory.types.ts
    hardware.types.ts
    analytics.types.ts

  lib/
    api.ts
    signalr.ts
    utils.ts
```

---

## 14. TV Display Mode

### หน้า `/bay?display=tv` — Full Screen TV Layout

**คุณสมบัติ:**
- ไม่มี Sidebar / TopBar
- Full Screen 100vw 100vh
- Background: `bg-slate-900` (Dark เพื่อลดแสงสะท้อน)
- Font Size ขั้นต่ำ 36px สำหรับ Label ทั่วไป
- Truck Plate: `text-7xl font-black` (72px)
- Auto-refresh ผ่าน SignalR — ไม่ต้อง F5
- ใช้ได้กับ TV 55" ขึ้นไป ที่ความละเอียด 1920x1080

### Bay Card — TV Display Mode

```
IDLE State:
+------------------------------------------------------------------+
|  bg-slate-800 border-2 border-slate-600 rounded-2xl              |
|                                                                  |
|  BAY 01                                           [IDLE]         |
|  text-white text-4xl font-bold            bg-green-600 text-xl   |
|                                                                  |
|  ว่าง / พร้อมรับรถ                                               |
|  text-slate-300 text-2xl                                         |
+------------------------------------------------------------------+

CALLING State:
+------------------------------------------------------------------+
|  bg-amber-900/30 border-2 border-amber-500 rounded-2xl           |
|                                                                  |
|  BAY 02                                        [CALLING]         |
|  text-white text-4xl font-bold          bg-amber-600 text-xl     |
|                                                                  |
|  โปรดเข้าที่จอด Bay 02                                           |
|  text-amber-200 text-xl                                          |
|                                                                  |
|         80-5678 กข                                               |
|  text-white text-7xl font-black                                  |
|                                                                  |
|  Feed B  --  25 ton                                              |
|  text-slate-200 text-2xl                                         |
+------------------------------------------------------------------+

LOADING State:
+------------------------------------------------------------------+
|  bg-blue-900/30 border-2 border-blue-500 rounded-2xl             |
|                                                                  |
|  BAY 01                                        [LOADING]         |
|  text-white text-4xl font-bold           bg-blue-600 text-xl     |
|                                                                  |
|         80-1234 กข                                               |
|  text-white text-7xl font-black                                  |
|                                                                  |
|  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  78%                             |
|  bg-blue-500 h-6 rounded-full                                    |
|                                                                  |
|  15,600 kg  /  20,000 kg                                         |
|  text-blue-200 text-4xl font-bold                                |
+------------------------------------------------------------------+

EMERGENCY State:
+------------------------------------------------------------------+
|  bg-red-900 border-4 border-red-500 rounded-2xl animate-pulse    |
|                                                                  |
|  BAY 04                              [!! EMERGENCY !!]           |
|  text-white text-4xl          bg-red-600 text-xl animate-bounce  |
|                                                                  |
|  หยุดฉุกเฉิน!                                                    |
|  text-red-200 text-5xl font-black                                |
|                                                                  |
|  รอ Supervisor ตรวจสอบ                                           |
|  text-red-300 text-2xl                                           |
+------------------------------------------------------------------+
```

### Queue Waiting Section (TV Display Bottom)
```
+--------------------------------------------------------------------------+
|  คิวรอ (Waiting Queue)                                                    |
|  bg-slate-800/80 border-t border-slate-600                               |
|                                                                          |
|  [Q001]  80-1111  |  Feed A  |  20 ton  |  [URGENT bg-red-600]          |
|  [Q002]  80-2222  |  Feed B  |  15 ton  |  [NORMAL bg-slate-600]        |
|  text-white text-3xl -- อัปเดต Real-time ผ่าน SignalR                   |
+--------------------------------------------------------------------------+
```

### Implementation Note
```typescript
// BayTvDisplayPage.tsx — Toggle TV Mode
const [searchParams] = useSearchParams()
const isTvMode = searchParams.get('display') === 'tv'

if (isTvMode) {
  return <TvDisplayLayout />  // Full screen, no AppShell
}
return <AppShell><BayOverviewContent /></AppShell>
```

---

## Responsive Breakpoints

| Breakpoint | Width | Target Device |
|-----------|-------|---------------|
| sm | 640px | Phone (ไม่ใช่ Target หลัก) |
| md | 768px | Tablet |
| lg | 1024px | Laptop |
| xl | 1280px | Desktop |
| 2xl | 1536px+ | Large Monitor / TV |

---

## shadcn/ui Components ทั้งหมดที่ใช้

```
Card, CardHeader, CardContent, CardFooter
Badge
Button
Table, TableHeader, TableBody, TableRow, TableCell
Dialog, DialogContent, DialogTitle, DialogFooter
Select, SelectItem, SelectTrigger, SelectContent
Input
Tabs, TabsList, TabsTrigger, TabsContent
Progress
Separator
Alert, AlertDescription, AlertTitle
ScrollArea
Tooltip, TooltipContent, TooltipTrigger
Checkbox
Switch
DatePicker (จาก shadcn calendar)
```

---

## ไฟล์ UI ที่ควรสร้าง

**Base Path:** `D:\MAKIYA_PROJECT\Project_SmartLoadBulk\frontend\src\`

- `components/layout/` — AppShell, Sidebar, TopBar
- `components/common/` — Badge, StatusDot, KpiCard
- `components/dashboard/` — BayStatusCard, AlertCard
- `components/queue/` — QueueCard, QueueTable
- `components/loading/` — LoadingProgressBar, WeightDisplay, EmergencyDialog
- `components/qr/` — QrDisplay, QrScanner, QrResult
- `components/hardware/` — DeviceStatusCard, HardwareEventLog
- `pages/` — ทุก Page Component

---

## ส่งต่อให้ Iron Man

งานถัดไปที่ Iron Man ต้องทำ:
1. ตั้งค่า React Project + Vite + TypeScript + Tailwind
2. ติดตั้ง shadcn/ui + recharts + Zustand + Axios + @microsoft/signalr
3. สร้าง `tailwind.config.js` ตาม Design Tokens
4. สร้าง AppShell + Sidebar + TopBar ก่อน
5. Implement MainDashboardPage ก่อน (MVP)
6. ต่อด้วย QueuePage และ BayTvDisplayPage
7. Implement Analytics Dashboard ตาม `docs/UI_PERFORMANCE_DASHBOARD_DESIGN.md`

---

*Spider-Man -- UI/UX Designer -- MAKIYA Marvel AI Team -- 2026-05-14*
*Version 2.0 -- ฉบับสมบูรณ์ 14 หน้า*
