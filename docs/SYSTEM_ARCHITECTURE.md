# SYSTEM ARCHITECTURE — Smart Load Bulk

**ออกแบบโดย:** Doctor Strange  
**วันที่:** 2026-05-13  
**Version:** 2.0 (อัปเดตครอบคลุม 10 Module — รวม Analytics & Loss/Yield)  
**อ้างอิง:** docs/PROJECT_CONTEXT.md, docs/DATABASE_DESIGN.md, docs/ANALYTICS_DESIGN.md

---

## 1. Architecture ภาพรวม (High-Level)

```
╔══════════════════════════════════════════════════════════════════════════╗
║                           CLIENT LAYER                                  ║
║                                                                         ║
║  ┌────────────────┐  ┌──────────────────┐  ┌────────────────────────┐  ║
║  │  Operator App  │  │  Factory Display │  │  Supervisor / Admin    │  ║
║  │  React + TS    │  │  TV/LCD Monitor  │  │  React + TS            │  ║
║  │  (Office/Gate) │  │  /bay?display=tv │  │  Analytics + Settings  │  ║
║  └───────┬────────┘  └────────┬─────────┘  └───────────┬────────────┘  ║
╚══════════╪═════════════════════╪════════════════════════╪══════════════╝
           │                    │                         │
           └────────────────────┴────────────────┬────────┘
                                                 │  HTTPS + WSS (SignalR)
╔════════════════════════════════════════════════╪════════════════════════╗
║                        API LAYER               │                        ║
║  ┌─────────────────────────────────────────────▼──────────────────┐    ║
║  │                  ASP.NET Core 8 Web API                         │    ║
║  │                                                                 │    ║
║  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐      │    ║
║  │  │ Inventory │ │  Order &  │ │   Truck   │ │    Bay    │      │    ║
║  │  │Controller │ │   Queue   │ │Controller │ │Controller │      │    ║
║  │  └───────────┘ └───────────┘ └───────────┘ └───────────┘      │    ║
║  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐      │    ║
║  │  │  QR Code  │ │  Loading  │ │ Hardware  │ │Analytics  │      │    ║
║  │  │Controller │ │Controller │ │Controller │ │Controller │      │    ║
║  │  └───────────┘ └───────────┘ └───────────┘ └───────────┘      │    ║
║  │                                                                 │    ║
║  │  ┌─────────────────────────────────────────────────────────┐   │    ║
║  │  │                SignalR Hubs (Realtime)                   │   │    ║
║  │  │  LoadingHub │ QueueHub │ InventoryHub │ HardwareHub      │   │    ║
║  │  │  AnalyticsHub (Live KPI streaming)                       │   │    ║
║  │  └─────────────────────────────────────────────────────────┘   │    ║
║  │                                                                 │    ║
║  │  ┌──────────────────────┐  ┌────────────────────────────────┐  │    ║
║  │  │  Background Services │  │   Middleware                   │  │    ║
║  │  │  HardwareGateway     │  │   JWT Auth │ Rate Limit        │  │    ║
║  │  │  NotificationService │  │   Request Logging │ CORS       │  │    ║
║  │  │  AnalyticsScheduler  │  │                                │  │    ║
║  │  └──────────────────────┘  └────────────────────────────────┘  │    ║
║  └─────────────────────────────────────────────────────────────────┘    ║
╚═══════════════════════════════╤═════════════════════════╤══════════════╝
                                │                         │
          ╔═════════════════════▼═════╗    ╔══════════════▼═══════════════╗
          ║       DATA LAYER          ║    ║       HARDWARE LAYER         ║
          ║                           ║    ║                              ║
          ║  ┌─────────────────────┐  ║    ║  ┌──────────────────────┐   ║
          ║  │   SQL Server 2019+  │  ║    ║  │  Hardware Gateway    │   ║
          ║  │   SmartLoadBulkDB   │  ║    ║  │  (Background Svc)    │   ║
          ║  │                     │  ║    ║  └──────────┬───────────┘   ║
          ║  │  Schema: slb  (OLTP)│  ║    ║             │               ║
          ║  │  Schema: ana  (OLAP)│  ║    ║  ┌──────────▼───────────┐   ║
          ║  └─────────────────────┘  ║    ║  │  Device Adapters     │   ║
          ║                           ║    ║  │  QR Scanner (TCP)    │   ║
          ║  ┌─────────────────────┐  ║    ║  │  Radar  (Modbus TCP) │   ║
          ║  │  Redis (Optional)   │  ║    ║  │  Loading Panel (I/O) │   ║
          ║  │  Queue / Session    │  ║    ║  │  Weight Sensor       │   ║
          ║  └─────────────────────┘  ║    ║  └──────────────────────┘   ║
          ╚═══════════════════════════╝    ╚══════════════════════════════╝
```

---

## 2. Technology Stack (ตัดสินใจแล้ว — ล็อค)

| Layer | Technology | Version | หมายเหตุ |
|-------|-----------|---------|----------|
| **Frontend** | React + TypeScript | 18+ | Vite build |
| **UI Library** | Tailwind CSS + shadcn/ui | Latest | Light Mode |
| **Charts** | Recharts | Latest | Analytics Dashboard |
| **Realtime Client** | @microsoft/signalr | Latest | WebSocket + fallback |
| **State** | Zustand | Latest | ตัดสินใจแล้ว |
| **HTTP Client** | Axios | Latest | Interceptors + retry |
| **Backend** | ASP.NET Core 8 Web API | .NET 8 LTS | |
| **Realtime Server** | SignalR | Built-in | 5 Hubs |
| **Database** | SQL Server 2019+ | — | EF Core 8 |
| **ORM** | Entity Framework Core 8 | 8.x | Code First |
| **Auth** | JWT Bearer Token | — | Role-based |
| **Hardware** | Background Worker Service | .NET 8 | Gateway pattern |
| **Logging** | Serilog | Latest | File + DB |
| **Cache** | Redis | Optional | Queue/Session |

---

## 3. Module หลัก — ครบ 10 Module

| # | Module | Priority | Controller | Pages | Agent |
|---|--------|----------|-----------|-------|-------|
| 1 | **Inventory Dashboard** | High | InventoryController | 3 หน้า | Shuri, Spider-Man |
| 2 | **Order & Queue** | High | OrderController, QueueController | 4 หน้า | Iron Man |
| 3 | **Truck Calling & Loading** | High | BayController | 4 หน้า | Iron Man |
| 4 | **Truck Register** | Medium | TruckController, DriverController | 4 หน้า | Iron Man |
| 5 | **QR Code for Loading** | High | QrController | 3 หน้า | Iron Man |
| 6 | **Double Check Loading** | High | ChecklistController | 3 หน้า | Iron Man |
| 7 | **Software Integration** | Medium | IntegrationController | — | Shuri |
| 8 | **Hardware Integration** | Medium | HardwareController | 4 หน้า | Iron Man |
| 9 | **Performance Analytics** | High | AnalyticsController | 5 หน้า | Hawkeye |
| 10 | **Loss / Yield Monitoring** | High | AnalyticsController | (รวมใน 9) | Hawkeye |

---

## 4. หน้าจอทั้งหมด (21 หน้า)

### Module 1 — Inventory
| หน้า | URL | คำอธิบาย |
|------|-----|----------|
| Inventory Overview | `/inventory` | Stock ทุก Product + Alert |
| Inventory Detail | `/inventory/:productId` | Stock รายสินค้า + Silo |
| Inventory History | `/inventory/history` | ประวัติการเคลื่อนไหว |

### Module 2 — Order & Queue
| หน้า | URL | คำอธิบาย |
|------|-----|----------|
| Order List | `/orders` | รายการ Order ทั้งหมด |
| Order Create | `/orders/new` | สร้าง Order ใหม่ |
| Order Detail | `/orders/:orderId` | รายละเอียด + เพิ่มรถเข้าคิว |
| Queue Board | `/queue` | Kanban Queue ทั้งหมด |

### Module 3 — Bay Monitor
| หน้า | URL | คำอธิบาย |
|------|-----|----------|
| Bay Overview | `/bay` | สถานะ Bay ทุก Bay |
| Bay Detail | `/bay/:bayId` | Bay เดียว + Loading Control |
| Bay TV Display | `/bay?display=tv` | หน้าจอโรงงาน — Full Screen |
| Loading Control | `/bay/:bayId/load` | ควบคุม Start/Stop/Emergency |

### Module 4 — Truck Register
| หน้า | URL | คำอธิบาย |
|------|-----|----------|
| Truck List | `/trucks` | รายการรถทั้งหมด |
| Truck Form | `/trucks/new` หรือ `/:id/edit` | ลงทะเบียน/แก้ไขรถ |
| Driver List | `/drivers` | รายการคนขับ |
| Driver Form | `/drivers/new` หรือ `/:id/edit` | ลงทะเบียน/แก้ไขคนขับ |

### Module 5 — QR Code
| หน้า | URL | คำอธิบาย |
|------|-----|----------|
| QR Generate | `/qr/generate/:jobId` | สร้างและแสดง QR |
| QR Scan | `/qr/scan` | สแกน (Web Camera / Input) |
| QR Print | `/qr/print/:jobId` | Layout สำหรับพิมพ์ |

### Module 6 — Double Check
| หน้า | URL | คำอธิบาย |
|------|-----|----------|
| Checklist | `/check/:jobId` | Tick รายการตรวจสอบ |
| Weight Verify | `/check/:jobId/weight` | ยืนยันน้ำหนักจริง |
| Release Gate | `/check/:jobId/release` | อนุมัติปล่อยรถ |

### Module 8 — Hardware
| หน้า | URL | คำอธิบาย |
|------|-----|----------|
| Device List | `/hardware` | สถานะ Device ทั้งหมด |
| Device Config | `/hardware/:deviceId` | ตั้งค่า Device |
| Event Log | `/hardware/events` | ประวัติ Event จาก Hardware |
| Simulation | `/hardware/simulate` | ทดสอบ Dry-run |

### Module 9 & 10 — Analytics
| หน้า | URL | คำอธิบาย |
|------|-----|----------|
| Performance Overview | `/analytics` | KPI รวม + Trend |
| Loss / Yield | `/analytics/loss-yield` | Loss vs Over + Gauge |
| Bay Performance | `/analytics/bay` | Utilization + Heatmap |
| Turnaround | `/analytics/turnaround` | Truck Turnaround Analysis |
| Product Loss | `/analytics/product` | Loss Ranking by Product |

---

## 5. API Endpoints ทั้งหมด

### Inventory API
```
GET  /api/inventory                    — Stock ทุก Product
GET  /api/inventory/:productId         — Stock รายสินค้า + Silos
GET  /api/inventory/history            — ประวัติ Stock
POST /api/inventory/adjust             — ปรับ Stock (Admin)
```

### Order API
```
GET    /api/orders                     — รายการ Order (filter/page)
GET    /api/orders/:orderId            — Order รายการ
POST   /api/orders                     — สร้าง Order
PUT    /api/orders/:orderId/status     — เปลี่ยนสถานะ
DELETE /api/orders/:orderId            — ยกเลิก Order
```

### Queue API
```
GET    /api/queue                      — Queue Board ปัจจุบัน
POST   /api/queue/enqueue              — เพิ่มรถเข้าคิว
PUT    /api/queue/:queueId/priority    — เปลี่ยนลำดับ
DELETE /api/queue/:queueId             — ยกเลิก Queue
```

### Truck & Driver API
```
GET    /api/trucks                     — รายการรถ
POST   /api/trucks                     — ลงทะเบียนรถ
PUT    /api/trucks/:truckId            — แก้ไขรถ
GET    /api/drivers                    — รายการคนขับ
POST   /api/drivers                    — ลงทะเบียนคนขับ
PUT    /api/drivers/:driverId          — แก้ไขคนขับ
```

### Bay & Loading API
```
GET    /api/bays                       — สถานะ Bay ทั้งหมด
GET    /api/bays/:bayId                — สถานะ Bay เดียว
POST   /api/bays/:bayId/call           — เรียกรถเข้า Bay
POST   /api/bays/:bayId/dock           — ยืนยันรถเข้า Bay
POST   /api/bays/:bayId/load/start     — เริ่มโหลด
POST   /api/bays/:bayId/load/pause     — หยุดชั่วคราว
POST   /api/bays/:bayId/load/stop      — Emergency Stop
POST   /api/bays/:bayId/load/complete  — โหลดเสร็จ
POST   /api/bays/:bayId/load/progress  — อัปเดตน้ำหนัก (จาก Hardware)
POST   /api/bays/:bayId/reset          — Reset Bay (หลัง Error)
```

### QR API
```
POST   /api/qr/generate                — สร้าง QR Token สำหรับ Job
POST   /api/qr/validate                — ตรวจสอบ QR ที่สแกน
GET    /api/qr/:jobId/image            — QR Image (PNG/SVG)
DELETE /api/qr/:tokenId/revoke         — ยกเลิก Token
```

### Checklist & Release API
```
GET    /api/check/:jobId               — Checklist ของ Job
POST   /api/check/:jobId/weight        — บันทึกน้ำหนักจริง
PUT    /api/check/:jobId/item/:itemId  — Tick รายการ
POST   /api/check/:jobId/release       — อนุมัติปล่อยรถ
```

### Hardware API
```
GET    /api/hardware                   — Device ทั้งหมด
GET    /api/hardware/:deviceId         — Device รายตัว
PATCH  /api/hardware/:deviceId/config  — ตั้งค่า Device
GET    /api/hardware/events            — Event Log ล่าสุด
POST   /api/hardware/scanner/trigger   — Manual trigger Scanner
GET    /api/hardware/radar/:bayId      — ข้อมูล Radar ล่าสุด
POST   /api/hardware/panel/:bayId/cmd  — ส่งคำสั่ง Panel
POST   /api/hardware/simulate/:type    — Dry-run Simulation
```

### Analytics API
```
GET    /api/analytics/performance      — Performance Overview Dashboard
GET    /api/analytics/loss-yield       — Loss/Yield Dashboard
GET    /api/analytics/bay              — Bay Performance Dashboard
GET    /api/analytics/turnaround       — Turnaround Dashboard
GET    /api/analytics/product          — Product Loss Analysis
GET    /api/analytics/config           — ดึง Threshold Config
PUT    /api/analytics/config           — อัปเดต Threshold
GET    /api/analytics/export/excel     — Export Excel
GET    /api/analytics/export/pdf       — Export PDF
```

### Auth & User API
```
POST   /api/auth/login                 — Login → JWT
POST   /api/auth/logout                — Logout
GET    /api/users                      — รายการ User (Admin)
POST   /api/users                      — สร้าง User
PUT    /api/users/:userId              — แก้ไข User
PATCH  /api/users/:userId/role         — เปลี่ยน Role
```

**รวม API Endpoints:** ~45 endpoints

---

## 6. Database — สองสกีมา

### Schema: `slb` (OLTP — 23 Tables)
```
[MASTER]          [INVENTORY]        [ORDER & QUEUE]
Users             Products           Orders
Customers         Silos              OrderItems
Trucks            Inventory          LoadQueues
Drivers           InventoryLogs
TruckDriverMap

[LOADING]         [QR & VERIFY]      [HARDWARE]
Bays              QrTokens           HardwareDevices
BayLogs           LoadChecklists     HardwareEvents
LoadJobs          ChecklistItems
LoadJobLogs

[SYSTEM]
NotificationLogs
AuditLogs
```

### Schema: `ana` (OLAP Analytics — Hawkeye Design)
```
[CONFIG]          [VIEWS — อ่านจาก slb]
AnalyticsConfig   vw_JobPerformance
                  vw_QueuePerformance
                  vw_DailyPerformance
                  vw_BayPerformance
                  vw_ProductLossYield
                  vw_TruckTurnaround
                  vw_HourlyThroughput

[STORED PROCEDURES]
sp_GetPerformanceDashboard
sp_GetLossYieldDashboard
sp_GetBayPerformanceDashboard
sp_GetTurnaroundDashboard
sp_GetProductLossAnalysis
sp_GetAnalyticsConfig
sp_UpdateAnalyticsConfig
```

> **ดูรายละเอียดครบ:** `docs/DATABASE_DESIGN.md` (slb) และ `docs/ANALYTICS_DESIGN.md` (ana)

---

## 7. SignalR Realtime Events — 5 Hubs

### Hub 1: `LoadingHub` (`/hubs/loading`)
| Event | Direction | Payload | ผู้รับ |
|-------|-----------|---------|-------|
| `BayStatusChanged` | Server→Client | `{bayId, status, queueId}` | All |
| `LoadProgressUpdated` | Server→Client | `{jobId, bayId, currentWeight, targetWeight, percent}` | Bay Group |
| `TruckCalled` | Server→Client | `{queueId, truckId, bayId, licensePlate}` | Display Monitor |
| `TruckDocked` | Server→Client | `{bayId, queueId}` | Operator |
| `EmergencyStop` | Server→Client | `{bayId, reason, timestamp}` | All (Critical) |
| `LoadCompleted` | Server→Client | `{jobId, bayId, actualWeight}` | Bay Group |
| `GateReleased` | Server→Client | `{jobId, bayId}` | All |

### Hub 2: `QueueHub` (`/hubs/queue`)
| Event | Direction | Payload | ผู้รับ |
|-------|-----------|---------|-------|
| `QueueUpdated` | Server→Client | `{queueList}` | Queue Board |
| `TruckArrived` | Server→Client | `{truckId, licensePlate}` | Operator |
| `QueuePositionChanged` | Server→Client | `{queueId, newPosition}` | Queue Board |
| `QueueCancelled` | Server→Client | `{queueId}` | Queue Board |

### Hub 3: `InventoryHub` (`/hubs/inventory`)
| Event | Direction | Payload | ผู้รับ |
|-------|-----------|---------|-------|
| `StockUpdated` | Server→Client | `{productId, currentStock, reservedStock}` | Dashboard |
| `StockAlert` | Server→Client | `{productId, productName, currentStock, minStock, alertLevel}` | Supervisor |
| `InventoryAdjusted` | Server→Client | `{productId, changeType, qty}` | Admin |

### Hub 4: `HardwareHub` (`/hubs/hardware`)
| Event | Direction | Payload | ผู้รับ |
|-------|-----------|---------|-------|
| `QrScanned` | Server→Client | `{deviceId, token, bayId, timestamp}` | Loading Controller |
| `RadarDetected` | Server→Client | `{bayId, detected, distance}` | Bay Monitor |
| `WeightUpdated` | Server→Client | `{bayId, weight}` | Bay Monitor |
| `PanelStateChanged` | Server→Client | `{bayId, panelState}` | Bay Monitor |
| `DeviceOnline` | Server→Client | `{deviceId, deviceName}` | Supervisor |
| `DeviceOffline` | Server→Client | `{deviceId, deviceName, lastSeen}` | Supervisor |

### Hub 5: `AnalyticsHub` (`/hubs/analytics`)
| Event | Direction | Payload | ผู้รับ |
|-------|-----------|---------|-------|
| `KpiUpdated` | Server→Client | `{yieldPct, accuracyPct, totalJobs}` | Analytics Dashboard |
| `LossAlert` | Server→Client | `{productId, productName, lossPct, lossKg}` | Supervisor |
| `DailyKpiSnapshot` | Server→Client | `{date, kpiSummary}` | Analytics |
| `ThroughputUpdated` | Server→Client | `{bayId, throughputTonPerHour}` | Analytics |

---

## 8. Hardware Integration Architecture

```
╔══════════════════════════════════════════════════════════════════╗
║               Hardware Gateway Service                           ║
║          (ASP.NET Core 8 — IHostedService)                       ║
║                                                                  ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  DeviceManager                                           │   ║
║  │  ┌────────────────┐  ┌────────────────┐  ┌───────────┐  │   ║
║  │  │ QrScannerAdptr │  │  RadarAdapter  │  │PanelAdptr │  │   ║
║  │  │  Serial/TCP    │  │  Modbus TCP    │  │Modbus TCP │  │   ║
║  │  │  HID USB       │  │               │  │           │  │   ║
║  │  └───────┬────────┘  └───────┬────────┘  └─────┬─────┘  │   ║
║  └──────────┼───────────────────┼─────────────────┼─────────┘   ║
║             │                   │                 │             ║
║  ┌──────────▼───────────────────▼─────────────────▼─────────┐   ║
║  │  EventDispatcher                                          │   ║
║  │  ┌──────────────────────────┐                            │   ║
║  │  │ → POST /api/bays/load    │ → Main API (HTTP Internal) │   ║
║  │  │ → POST /api/qr/validate  │                            │   ║
║  │  │ → SignalR HardwareHub    │ → Realtime Notification     │   ║
║  │  └──────────────────────────┘                            │   ║
║  └──────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════╝

Flow ต่อ Device:

QR Scanner:
  Scan → Raw String → Parse → POST /api/qr/validate
         → Valid: SignalR QrScanned → Open Panel
         → Invalid: SignalR Alert → Log Security Event

Radar/Sensor:
  Detect → Distance Data → POST /api/bays/{bayId}/radar
         → Vehicle In Range: Update Bay DOCKED
         → No Vehicle: Update Bay AVAILABLE

Loading Panel:
  Weight Pulse → POST /api/bays/{bayId}/load/progress (ทุก 500ms)
  Emergency Button → POST /api/bays/{bayId}/load/stop (immediate)
  Panel State → SignalR PanelStateChanged

Safety Rules (Hardware):
  ✦ Simulation Mode ต้องทำงานได้ก่อน Connect จริง
  ✦ Emergency Stop ต้อง 2-step confirm บน Web UI
  ✦ Hardware Command ต้องผ่าน Dry-run ก่อนเสมอ
  ✦ ถ้า Device Offline → Alert + Log + ไม่ Block การโหลด (Fallback Manual)
```

### Protocol Matrix
| Hardware | Protocol | Library | Port |
|----------|----------|---------|------|
| QR Scanner (TCP) | TCP Socket | System.Net.Sockets | 9001 |
| QR Scanner (Serial) | RS-232 / USB | System.IO.Ports | COM# |
| Radar Sensor | Modbus TCP | NModbus4 | 502 |
| Loading Panel | Modbus TCP | NModbus4 | 502 |
| Weight Sensor | Modbus TCP / Serial | NModbus4 | 502 |

---

## 9. Security Design

| ด้าน | วิธีการ |
|------|---------|
| Authentication | JWT Bearer Token (HS256, Expire 8h) |
| Authorization | Role-based: ADMIN / SUPERVISOR / OPERATOR / VIEWER |
| QR Token | Single-use JWT, HMAC-SHA256, Expire 8h per Job |
| Hardware API | Internal network only + API Key header |
| CORS | Whitelist Origin เท่านั้น |
| Rate Limit | 100 req/min ต่อ IP, Emergency Stop ไม่ Rate Limit |
| HTTPS | Required ทุก Environment |
| Audit Log | ทุก Action บันทึกใน slb.AuditLogs |

### Role Permissions
| Feature | ADMIN | SUPERVISOR | OPERATOR | VIEWER |
|---------|-------|-----------|---------|--------|
| สร้าง Order | ✅ | ✅ | ✅ | ❌ |
| เรียกรถ / เปิด Bay | ✅ | ✅ | ✅ | ❌ |
| Emergency Stop | ✅ | ✅ | ✅ | ❌ |
| Release Gate | ✅ | ✅ | ❌ | ❌ |
| ดู Analytics | ✅ | ✅ | ❌ | ✅ |
| ปรับ Threshold | ✅ | ✅ | ❌ | ❌ |
| จัดการ User | ✅ | ❌ | ❌ | ❌ |
| Hardware Config | ✅ | ✅ | ❌ | ❌ |

---

## 10. UI Design System (สรุป)

```
Theme:     Light Mode — "Clean Factory Command Center"
Primary:   Blue #2563EB + Green #16A34A
Font:      Inter, 14px Body, 48px KPI Number, 24px Heading
Grid:      12 Column, max-width 1440px
Sidebar:   240px (collapsed: 64px)
```

**Status Colors:**
```
AVAILABLE   → Green-600  / bg-green-50
CALLING     → Amber-500  / bg-amber-50
LOADING     → Blue-600   / bg-blue-50
ERROR       → Red-600    / bg-red-50    + animate-pulse
NORMAL KPI  → Green text
WARNING KPI → Amber text
CRITICAL    → Red text   + badge pulse
```

> **ดูรายละเอียดครบ:** `docs/UI_UX_DESIGN.md` (9 หน้า Wireframe + Component)  
> **ดู Analytics UI:** `docs/ANALYTICS_DESIGN.md` (5 หน้า Dashboard Layout)
