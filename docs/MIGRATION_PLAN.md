# MIGRATION PLAN & DEVELOPMENT PHASES — Smart Load Bulk V2.0

**Version:** 2.0  
**อัปเดต:** 2026-05-13 (Doctor Strange V2.0 — ครอบคลุม 10 Module + Analytics)  
**อ้างอิง:** docs/SYSTEM_ARCHITECTURE.md V2.0, docs/PROJECT_CONTEXT.md

---

## Overview — 7 Development Phases

```
Phase 0  — Project Bootstrap & Infrastructure        (1 สัปดาห์)
Phase 1  — Database & Core Backend                   (2 สัปดาห์)
Phase 2  — Core UI Modules (MVP)                     (3 สัปดาห์)
Phase 3  — Realtime & SignalR                        (2 สัปดาห์)
Phase 4  — Hardware Integration                      (2 สัปดาห์)
Phase 5  — Analytics & Loss/Yield                    (2 สัปดาห์)
Phase 6  — Integration, QA & Go-Live                 (2 สัปดาห์)
─────────────────────────────────────────────────────────────────
ประมาณการรวม: ~14 สัปดาห์ (3.5 เดือน)
```

---

## Phase 0 — Project Bootstrap & Infrastructure

**ระยะเวลา:** 1 สัปดาห์  
**เป้าหมาย:** Setup Project Structure ให้พร้อม Develop  
**Agent:** Iron Man

### งานที่ต้องทำ

#### 0.1 Backend — ASP.NET Core 8 Web API
```
SmartLoadBulk/
├── SmartLoadBulk.API/          ← Web API Project
│   ├── Controllers/
│   ├── Hubs/                   ← SignalR Hubs
│   ├── Services/
│   ├── Models/
│   ├── DTOs/
│   ├── Middleware/
│   └── Program.cs
├── SmartLoadBulk.Core/         ← Business Logic
│   ├── Entities/               ← EF Core Entities
│   ├── Interfaces/
│   └── Services/
├── SmartLoadBulk.Infrastructure/
│   ├── Data/                   ← DbContext, Migrations
│   ├── Repositories/
│   └── Hardware/               ← Device Adapters
└── SmartLoadBulk.Tests/
```

**Packages:**
- Microsoft.EntityFrameworkCore.SqlServer 8.x
- Microsoft.AspNetCore.SignalR 8.x
- Microsoft.AspNetCore.Authentication.JwtBearer 8.x
- Serilog.AspNetCore
- NModbus (Modbus TCP)

#### 0.2 Frontend — React + TypeScript
```
smart-load-bulk-ui/
├── src/
│   ├── components/
│   │   ├── ui/                 ← shadcn/ui components
│   │   ├── layout/
│   │   ├── inventory/
│   │   ├── order/
│   │   ├── queue/
│   │   ├── bay/
│   │   ├── analytics/
│   │   └── shared/
│   ├── pages/
│   ├── hooks/
│   ├── store/                  ← Zustand stores
│   ├── services/               ← API calls
│   ├── types/
│   └── main.tsx
├── vite.config.ts
└── tailwind.config.ts
```

**Packages:**
- react 18, typescript
- vite, @vitejs/plugin-react
- tailwindcss, @shadcn/ui
- zustand
- @microsoft/signalr
- recharts
- react-router-dom v6
- axios
- react-qr-code, html5-qrcode

#### 0.3 Database Setup
- รัน `db/001_create_smart_load_bulk_tables.sql` บน SQL Server 2019+
- รัน `db/002_create_analytics_schema.sql`
- สร้าง connection string ใน `appsettings.json`
- ทดสอบ EF Core connection

#### 0.4 Dev Environment
- Docker Compose สำหรับ SQL Server (optional)
- `.env` / `appsettings.Development.json`
- Git repository + `.gitignore`
- README.md — วิธี run project

### Deliverables
- [ ] Backend project compile สำเร็จ
- [ ] Frontend dev server รันได้
- [ ] เชื่อมต่อ DB สำเร็จ (EF Core ping)
- [ ] Swagger UI แสดงได้

---

## Phase 1 — Database & Core Backend

**ระยะเวลา:** 2 สัปดาห์  
**เป้าหมาย:** Backend APIs ครบทุก Core Module พร้อมรับ Request  
**Agent:** Iron Man + Shuri (ตรวจ SQL)

### Priority: MoSCoW

| งาน | Priority | สัปดาห์ |
|-----|---------|---------|
| EF Core Entities (23 tables) | Must | 1 |
| JWT Auth + Role Middleware | Must | 1 |
| InventoryController | Must | 1 |
| OrderController | Must | 1 |
| QueueController | Must | 1 |
| TruckController | Must | 1 |
| DriverController | Must | 2 |
| BayController | Must | 2 |
| LoadingController | Must | 2 |
| QrController | Must | 2 |
| ChecklistController | Should | 2 |
| HardwareController (receive events) | Should | 2 |
| IntegrationController (ERP webhook) | Could | — |

### 1.1 EF Core Entities
- Map ทุก Table ใน slb schema
- กำหนด Fluent API: Index, FK, Constraint
- DbContext.OnModelCreating() config
- EF Migration (ถ้าใช้ Code First) หรือ Scaffold (ถ้าใช้ DB First)

### 1.2 Service Layer Pattern
```csharp
// Interface → Implementation → Controller
IInventoryService → InventoryService → InventoryController
IOrderService     → OrderService     → OrderController
IQueueService     → QueueService     → QueueController
ILoadingService   → LoadingService   → LoadingController
IQrService        → QrService        → QrController
IBayService       → BayService       → BayController
```

### 1.3 API Response Format (Standard)
```json
{
  "success": true,
  "data": { ... },
  "message": "OK",
  "errors": []
}
```

### 1.4 JWT Auth
- Login: POST /api/auth/login → JWT Bearer Token
- Token: { userId, role, name, exp }
- Middleware: [Authorize(Roles = "ADMIN,SUPERVISOR")]
- Role Hierarchy: ADMIN > SUPERVISOR > OPERATOR > VIEWER

### Deliverables
- [ ] Swagger แสดง Endpoints ครบ
- [ ] Postman Collection test ผ่าน
- [ ] Auth ทำงานถูกต้องตาม Role
- [ ] DB transaction ไม่มี race condition

---

## Phase 2 — Core UI Modules (MVP)

**ระยะเวลา:** 3 สัปดาห์  
**เป้าหมาย:** หน้าจอหลัก 9 หน้า ใช้งานได้ผ่าน API จริง  
**Agent:** Iron Man (Frontend) + Spider-Man (Design Review)

### หน้าที่ต้องทำ (ตาม Priority)

| หน้า | Route | สัปดาห์ | Priority |
|------|-------|---------|---------|
| Login | /login | 1 | Must |
| Inventory Dashboard | /inventory | 1 | Must |
| Order Management | /orders | 1 | Must |
| Queue Board | /queue | 1 | Must |
| Truck Register | /trucks | 2 | Must |
| Bay Control | /bay/:bayId | 2 | Must |
| QR Code | /qr | 2 | Must |
| Double Check | /checklist/:jobId | 2 | Must |
| Admin (Users/Settings) | /admin | 3 | Should |
| TV Display | /bay?display=tv | 3 | Should |

### 2.1 State Management (Zustand)

```typescript
// Store ต่อ Domain
useInventoryStore   → inventory list, low stock alerts
useOrderStore       → orders, current filter
useQueueStore       → queue list, called queue
useBayStore         → bay status map
useLoadingStore     → active jobs, current weight
useAuthStore        → user, token, role
useNotificationStore → alerts, unread count
```

### 2.2 API Service Layer

```typescript
// src/services/
inventoryService.ts   → GET /api/inventory, POST /api/inventory/adjust
orderService.ts       → CRUD /api/orders
queueService.ts       → GET /api/queues, POST call/skip
truckService.ts       → CRUD /api/trucks, /api/drivers
bayService.ts         → GET /api/bays, status
loadingService.ts     → POST /api/loading/jobs, complete, checklist
qrService.ts          → POST /api/qr/generate, verify
```

### 2.3 Key Components
- `<KpiCard>` — metric + trend indicator
- `<InventoryGauge>` — stock level circular gauge
- `<QueueTable>` — sortable queue with status badges
- `<BayStatusGrid>` — bay grid 2×N with color status
- `<WeightProgress>` — loading progress bar (real-time)
- `<QRDisplay>` — QR code image + expiry countdown
- `<ChecklistForm>` — dynamic checklist with validation
- `<AlertBanner>` — emergency + notification strip

### Deliverables
- [ ] ทุกหน้า render ได้ ไม่มี crash
- [ ] CRUD Operations ทำงานได้
- [ ] Form Validation ครบ
- [ ] Responsive บน 1920×1080 (Factory Display)

---

## Phase 3 — Realtime & SignalR

**ระยะเวลา:** 2 สัปดาห์  
**เป้าหมาย:** ทุกหน้าอัปเดต Real-time ผ่าน WebSocket  
**Agent:** Iron Man

### 3.1 SignalR Hubs (Backend)

```csharp
// 5 Hubs
LoadingHub   → /hubs/loading
QueueHub     → /hubs/queue
InventoryHub → /hubs/inventory
HardwareHub  → /hubs/hardware
AnalyticsHub → /hubs/analytics
```

### 3.2 Hub Methods & Events

**LoadingHub**
```csharp
// Server → Client
OnLoadingStarted(LoadJobDto job)
OnWeightUpdated(Guid jobId, decimal weight)
OnLoadingComplete(Guid jobId)
OnJobCompleted(LoadJobDto job)
OnEmergencyStop(Guid jobId, string bay, string reason)
OnEmergencyResolved(Guid jobId)
```

**QueueHub**
```csharp
OnQueueUpdated(QueueDto queue)
OnTruckCalled(Guid queueId, string bayName)
```

**InventoryHub**
```csharp
OnInventoryUpdated(InventoryDto inv)
OnLowStockAlert(Guid siloId, decimal currentStock)
```

**HardwareHub**
```csharp
OnDeviceStatusChanged(HardwareDeviceDto device)
OnHardwareEvent(HardwareEventDto evt)
OnTruckDetected(string bayName)
```

**AnalyticsHub**
```csharp
OnKpiAlert(string kpiCode, decimal value, decimal threshold)
OnLossAlert(Guid jobId, decimal lossAmount, decimal yieldPct)
OnDashboardRefresh(PerformanceSummaryDto summary)
```

### 3.3 Frontend SignalR Integration

```typescript
// src/hooks/useSignalR.ts
const { connection } = useSignalR('/hubs/loading')

useEffect(() => {
  connection.on('OnWeightUpdated', (jobId, weight) => {
    useLoadingStore.getState().updateWeight(jobId, weight)
  })
}, [connection])
```

### 3.4 Connection Resilience
- Auto-reconnect (withAutomaticReconnect)
- Reconnect delay: 0, 2000, 10000, 30000 ms
- Toast notification เมื่อ disconnect/reconnect
- Fallback: Polling ทุก 5 วินาที ถ้า WebSocket ไม่ทำงาน

### Deliverables
- [ ] Weight อัปเดต Real-time บน Bay Control
- [ ] Queue Board อัปเดตเมื่อ status เปลี่ยน
- [ ] Emergency Stop แสดง Banner ทุก Client
- [ ] Hardware Status Badge อัปเดตอัตโนมัติ

---

## Phase 4 — Hardware Integration

**ระยะเวลา:** 2 สัปดาห์  
**เป้าหมาย:** Gateway Service เชื่อมต่อ Hardware จริง  
**Agent:** Iron Man + Doctor Strange (Review)

### 4.1 Simulation Mode ก่อน (สัปดาห์ 1)
- HardwareMode = "Simulation" ใน appsettings
- SimulatedQRScannerAdapter: ส่ง QR_SCANNED ทุก 10s
- SimulatedRadarAdapter: ส่ง TRUCK_DETECTED → TRUCK_DEPARTED ทุก 2 นาที
- SimulatedLoadingPanelAdapter: ส่ง WEIGHT_UPDATE ทุก 2s (+5 ตัน)

### 4.2 Real Hardware Adapters (สัปดาห์ 2)

**QR Scanner (TCP/Serial)**
```csharp
public class QRScannerAdapter : IDeviceAdapter
{
    // Connect via TCP socket หรือ Serial COM port
    // Parse barcode string → QrScannedEvent
    // Send to /api/hardware/events
}
```

**Radar Sensor (Modbus TCP)**
```csharp
public class RadarAdapter : IDeviceAdapter
{
    // Connect via Modbus TCP (NModbus)
    // Poll Register 0x01 ทุก 500ms
    // Register = 1 → TRUCK_DETECTED
    // Register = 0 → TRUCK_DEPARTED
}
```

**Loading Panel (Modbus TCP)**
```csharp
public class LoadingPanelAdapter : IDeviceAdapter
{
    // Poll Register 0x10 (Weight, Float32) ทุก 1s
    // Register 0x20 (LoadingComplete, Bool)
    // Write Register 0x30 (HALT command)
}
```

### 4.3 Protocol Matrix

| Device | Protocol | Address | Port/COM |
|--------|----------|---------|----------|
| QR Scanner | TCP/Serial | config | config |
| Radar (Bay A) | Modbus TCP | config | 502 |
| Radar (Bay B) | Modbus TCP | config | 502 |
| Loading Panel | Modbus TCP | config | 502 |

### 4.4 Safety Rules สำหรับ Hardware
- ทุก Write Command ต้องผ่าน SUPERVISOR Approval
- Dry-run: log command แต่ไม่ส่งไป Hardware
- Production: ส่งจริง + log + verify response
- Emergency HALT ต้องใช้เวลา ≤ 100ms

### Deliverables
- [ ] Simulation Mode ทำงานได้สมบูรณ์
- [ ] Real QR Scanner อ่านได้
- [ ] Radar ตรวจรถเข้า/ออก Bay ได้
- [ ] Loading Panel ส่ง Weight ได้
- [ ] Emergency Stop หยุด Panel จริงได้

---

## Phase 5 — Analytics & Loss/Yield

**ระยะเวลา:** 2 สัปดาห์  
**เป้าหมาย:** Analytics Dashboard 5 หน้าทำงานได้ พร้อม KPI Alert  
**Agent:** Iron Man + Hawkeye (Design Review)

### 5.1 Backend Analytics (สัปดาห์ 1)

**AnalyticsController**
```csharp
GET /api/analytics/performance       → sp_GetPerformanceDashboard
GET /api/analytics/loss-yield        → sp_GetLossYieldDashboard
GET /api/analytics/bay-performance   → sp_GetBayPerformanceDashboard
GET /api/analytics/turnaround        → sp_GetTurnaroundDashboard
GET /api/analytics/product-loss      → sp_GetProductLossAnalysis
GET /api/analytics/config            → sp_GetAnalyticsConfig
PUT /api/analytics/config            → sp_UpdateAnalyticsConfig
GET /api/analytics/kpi-summary       → computed from Views
```

**KPI Alert Background Service**
```csharp
public class KpiAlertService : BackgroundService
{
    // ทำงานทุก 15 นาที
    // Query ana Views
    // เปรียบกับ AnalyticsConfig Threshold
    // ถ้า exceed → SignalR → AnalyticsHub
}
```

### 5.2 Frontend Analytics (สัปดาห์ 2)

**5 Analytics Pages:**

| หน้า | Route | Chart Types |
|------|-------|-------------|
| Performance Overview | /analytics/performance | KPI Cards, Line Chart, Bar |
| Loss/Yield | /analytics/loss-yield | Line, Bar, Pie, Table |
| Bay Performance | /analytics/bay | Heatmap, Bar, Utilization |
| Turnaround | /analytics/turnaround | Line, Histogram |
| Product Loss | /analytics/product-loss | Pie, Scatter, Table |

**Key Components:**
```typescript
<KpiAlertBanner>     → แสดงเมื่อ OnKpiAlert จาก SignalR
<TrendLineChart>     → Recharts LineChart + threshold line
<BayHeatmap>         → custom Recharts Treemap / CSS Grid
<LossTable>          → sortable table with drill-down
<ThresholdConfig>    → form สำหรับ SUPERVISOR ปรับ threshold
```

### 5.3 Date Range Filter
- Preset: Today, This Week, This Month, Last 30 Days
- Custom range: DatePicker
- ทุก Chart รองรับ Filter เดียวกัน (Context/Zustand)

### Deliverables
- [ ] 5 Analytics Pages render พร้อม Data จริง
- [ ] KPI Alert ขึ้นเมื่อ Threshold เกิน
- [ ] Threshold สามารถปรับได้ผ่าน UI
- [ ] Export CSV / Print Dashboard (Should)

---

## Phase 6 — Integration, QA & Go-Live

**ระยะเวลา:** 2 สัปดาห์  
**เป้าหมาย:** End-to-End Test ผ่าน + Deploy พร้อมใช้งาน  
**Agent:** Captain America (Testing) + Iron Man (Deploy)

### 6.1 Integration Testing (สัปดาห์ 1)

**Test Scenarios:**
```
TC-001 Full Loading Flow
  ─ สร้าง Order → Queue → QR → Bay → Loading → Check → Complete
  ─ Expected: Job COMPLETED, Inventory ลด, Analytics อัปเดต

TC-002 Emergency Stop During Loading
  ─ กำลัง Loading → กด Emergency Stop → Verify Halt
  ─ Expected: Job EMERGENCY_STOPPED, Panel หยุด, Banner ขึ้น

TC-003 QR Token Security
  ─ Scan QR ซ้ำ → Expected: 401 TOKEN_ALREADY_USED
  ─ Scan QR หลัง 8hr → Expected: 401 TOKEN_EXPIRED

TC-004 Low Stock Alert
  ─ Loading จนสต็อกต่ำกว่า MinimumStock
  ─ Expected: SignalR OnLowStockAlert ส่ง, Banner ขึ้น

TC-005 Loss Alert
  ─ Job ActualWeight < 98% ของ OrderedWeight
  ─ Expected: SignalR OnLossAlert ส่ง, Alert ขึ้น

TC-006 Concurrent Loading (Multi-Bay)
  ─ 2 Bay Loading พร้อมกัน
  ─ Expected: ไม่มี race condition ใน DB, Weight อัปเดตแยกกัน

TC-007 Hardware Offline
  ─ ปิด Simulator/Device
  ─ Expected: Health Check ตรวจพบ OFFLINE, Badge เปลี่ยนสี
```

### 6.2 Performance Testing

| Scenario | Target |
|---------|--------|
| API Response Time (P95) | < 200ms |
| SignalR Broadcast (1 event, 50 clients) | < 500ms |
| Dashboard Load (ana SP) | < 2s |
| Concurrent Users | 20+ |
| DB Query (hot path) | < 50ms |

### 6.3 ERP Integration Testing
- ทดสอบ Mode A (Webhook IN) กับ Mock ERP
- ทดสอบ Retry Logic (ERP ไม่ตอบ 3 ครั้ง)
- ทดสอบ Outbound Webhook

### 6.4 Pre-Go-Live Checklist
```
Infrastructure
├── [ ] SQL Server backup schedule ตั้งแล้ว
├── [ ] Firewall rules เปิดเฉพาะ port ที่จำเป็น
├── [ ] HTTPS certificate ติดตั้งแล้ว
├── [ ] Log rotation ตั้งแล้ว (Serilog)
└── [ ] Error monitoring (Application Insights หรือ Seq)

Application
├── [ ] appsettings.Production.json ครบ
├── [ ] Connection strings ไม่ใช่ Hardcoded
├── [ ] JWT Secret Key แข็งแกร่ง (256-bit+)
├── [ ] Hardware Mode = "Real" (ไม่ใช่ Simulation)
└── [ ] Seed Data ของ Production พร้อม

Testing
├── [ ] TC-001 ถึง TC-007 ผ่านทั้งหมด
├── [ ] Load Test ผ่าน 20 concurrent users
├── [ ] UAT กับ End-user ผ่าน
└── [ ] Training เสร็จสิ้น
```

### 6.5 Deployment
```
Option A: IIS + Windows Server
  - Publish API: dotnet publish -c Release
  - Deploy ที่ IIS Site
  - Frontend: npm run build → copy dist/ ไปที่ wwwroot

Option B: Docker
  - docker-compose up -d
  - Services: api, frontend (nginx), sqlserver

Option C: Local Server (Standalone)
  - Self-contained executable
  - appsettings ชี้ไปที่ Local SQL Server
```

### Deliverables
- [ ] TC-001 ถึง TC-007 ผ่านทั้งหมด
- [ ] Performance target ผ่าน
- [ ] Deploy สำเร็จบน Production Server
- [ ] User Training เสร็จ
- [ ] Monitoring Dashboard ทำงาน

---

## Risk Register

| # | Risk | Probability | Impact | Mitigation |
|---|------|------------|--------|-----------|
| R01 | Hardware Protocol ไม่ตรงกับ Spec | HIGH | HIGH | Simulation ก่อน, Dry-run, ขอ Spec จาก Vendor |
| R02 | ERP API ไม่มี Webhook | MEDIUM | MEDIUM | รองรับ Polling Mode เป็น Fallback |
| R03 | Weight Sensor Accuracy ต่ำ | MEDIUM | HIGH | Calibration + Threshold Tolerance ±0.5% |
| R04 | SQL Performance ช้าเมื่อ Data มาก | LOW | MEDIUM | Index ครบ, ana SP แยก Schema, Pagination |
| R05 | SignalR Scale (ผู้ใช้เยอะ) | LOW | MEDIUM | Redis Backplane (Phase 3+) |
| R06 | JWT Token ถูก Replay | LOW | HIGH | Single-use QR Token, Short Expiry |
| R07 | Emergency Stop ช้าเกิน | LOW | CRITICAL | Background Service Priority, Modbus Direct Write |
| R08 | Browser Compatibility (Factory PC) | MEDIUM | MEDIUM | Test บน Chrome ≥ 90, ไม่ใช้ Feature ใหม่เกินไป |
| R09 | Network Unstable ใน Factory | MEDIUM | HIGH | SignalR Reconnect, Offline-capable Queue |
| R10 | Data Loss ถ้า Server ล่ม | LOW | HIGH | SQL Server Transaction, UPS, Backup Schedule |

---

## MoSCoW Priority Summary

### Must Have (Phase 0–3)
- Inventory Dashboard + Stock Alerts
- Order & Queue Management
- Truck & Driver Register
- QR Code Issue & Verify
- Bay Control + Loading Flow
- Double Check Checklist
- JWT Auth + Role-based Access
- SignalR Real-time Updates
- Simulation Mode (Hardware)

### Should Have (Phase 4–5)
- Real Hardware Adapters
- Performance Analytics Dashboard
- Loss/Yield Monitoring
- KPI Alert & Threshold Config
- ERP Integration (Webhook)

### Could Have (Phase 6+)
- TV Display Mode
- PDF Report Export
- Predictive Analytics (ML)
- Mobile App
- Multi-language (EN/TH)

### Won't Have (V1.0)
- Native Mobile App
- Offline Mode (PWA)
- IoT Sensor Network (beyond current 3 devices)
- Advanced ML Predictions

---

## Dependency Map

```
Phase 0 ──→ Phase 1 ──→ Phase 2 ──→ Phase 3
                                         │
                              Phase 4 ───┤
                                         │
                              Phase 5 ───┤
                                         ↓
                                      Phase 6
```

- Phase 1 ต้องเสร็จก่อน Phase 2 (Backend APIs ก่อน UI)
- Phase 3 ต้องเสร็จก่อน Phase 4 (SignalR ก่อน Hardware Events)
- Phase 4 และ Phase 5 ทำ Parallel ได้ (ทีมต่างกัน)
- Phase 6 รอ Phase 4 และ 5 เสร็จ

---

## Effort Estimate

| Phase | งาน | ประมาณ |
|-------|-----|--------|
| 0 | Project Setup | 5 วัน |
| 1 | Backend APIs (23 Endpoints) | 10 วัน |
| 2 | Frontend UI (9 หน้า) | 15 วัน |
| 3 | SignalR 5 Hubs | 10 วัน |
| 4 | Hardware Adapters 3 ตัว | 10 วัน |
| 5 | Analytics 5 หน้า + KPI | 10 วัน |
| 6 | QA + Deploy + Training | 10 วัน |
| **รวม** | | **~70 วัน (14 สัปดาห์)** |

*หมายเหตุ: ประมาณการสำหรับ Developer 1 คน ทำงานเต็มเวลา*

---

*Migration Plan V2.0 — Doctor Strange — 2026-05-13*
*ครอบคลุม 10 Module + 7 Phases + Risk Register + MoSCoW*
