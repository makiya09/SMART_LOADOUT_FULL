# HANDOFF — Smart Load Bulk

**อัปเดตล่าสุด:** 2026-05-18 (Session 9 — Dark Theme Redesign กำลังทำอยู่)  
**สถานะ:** Phase 3 ✅ 100% | Phase 4 SignalR 70% | Phase 6 Analytics 90% | Dark UI 🔵 60%

---

## สถานะเมื่อปิด Session 9 (ล่าสุด)

### 🔵 Dark Theme Redesign — กำลังทำอยู่
อ้างอิง design: `docs/feed_loading_system.html`

**เสร็จแล้ว:**
- `index.css` — IBM Plex Sans Thai/Mono fonts, CSS variables dark industrial
- `AppShell.tsx` — dark bg
- `Sidebar.tsx` — gradient logo, nav sections (Operations/Analytics/Settings), left-border active
- `TopBar.tsx` — dark + live dot + real-time clock
- `KpiCard.tsx` — stat-card style (2px top border, mono font, neon colors)

**ยังไม่เสร็จ:**
- `PageHeader.tsx`, `BayStatusCard.tsx`, `DashboardPage.tsx`, `OrdersPage.tsx`, `LoginPage.tsx`

**ไฟล์ Frontend ที่แก้:**
- `slb-frontend/src/index.css`
- `slb-frontend/src/components/layout/AppShell.tsx`
- `slb-frontend/src/components/layout/Sidebar.tsx`
- `slb-frontend/src/components/layout/TopBar.tsx`
- `slb-frontend/src/components/ui/KpiCard.tsx`

---

## สถานะเมื่อปิด Session 8

### ✅ Phase 6 Analytics SP Integration — เสร็จ
- AnalyticsService.cs จริง (raw ADO.NET, 4 SPs)
- 4 endpoints ทดสอบผ่าน: performance / loss-yield / bay / turnaround
- แก้ bug vite.config.ts proxy port 5000 → 5215 (login ไม่ได้ก่อนแก้)
- อัปเดต types/index.ts + 4 Analytics pages ให้ตรง SP output จริง

**ไฟล์ Backend ที่สร้าง/แก้:**
- `Core/DTOs/AnalyticsDtos.cs` (rewrite ครั้งใหญ่)
- `Infrastructure/Services/AnalyticsService.cs` (ใหม่ — ADO.NET จริง)
- `Infrastructure/Services/StubServices.cs` (ลบ AnalyticsService stub)

**ไฟล์ Frontend ที่แก้:**
- `slb-frontend/vite.config.ts` (proxy port 5000 → 5215)
- `slb-frontend/src/types/index.ts` (อัปเดต Analytics types)
- `slb-frontend/src/pages/PerformancePage.tsx`
- `slb-frontend/src/pages/LossYieldPage.tsx`
- `slb-frontend/src/pages/BayPerformancePage.tsx`
- `slb-frontend/src/pages/TurnaroundPage.tsx`

---

## สถานะเมื่อปิด Session 7

### ✅ API — http://localhost:5215
- รันด้วย: `cd src/SmartLoadBulk.API && dotnet run --launch-profile http`
- ⚠️ **ต้องใช้ `--launch-profile http` เสมอ** — https จะ strip Authorization header และได้ 401 ทุก endpoint

### ✅ Frontend — http://localhost:5173
- รันด้วย: `cd src/slb-frontend && npm run dev`

### ✅ DB — ASUS-MAKIYA / SmartLoadBulkDB
- Connection String อยู่ใน `src/SmartLoadBulk.API/appsettings.Development.json`
- Login: `POST /api/auth/login` body: `{"username":"admin","password":"Admin@1234"}`
- Token อยู่ที่ `response.data.token`

---

## สิ่งที่ทำใน Session 7 (2026-05-18)

### Phase 3.5 — QrService + QRCoder ✅
**ไฟล์ที่เปลี่ยน:**
- `Infrastructure/Services/QrService.cs` — ใช้ `PngByteQRCode` สร้าง PNG จริง (1,403 bytes)
- `Infrastructure/Data/Entities/QrToken.cs` — แก้ entity ตรง DB จริง

**DB columns จริง (ไม่ตรง entity เดิม):**
```
QrTokens: Token(varchar500), TokenHash(varchar64), IssuedAt, ExpiredAt, ScannedAt, IsUsed, IsRevoked
ไม่มี: TokenType, QrPayload, CreatedAt, UsedAt
```

### Phase 4 — SignalR Realtime Push ✅ (70%)
**Pattern ที่ใช้:** Dependency Inversion — ป้องกัน circular dependency

```
Core → ILoadingEventPublisher (interface)
Infrastructure/Services/LoadingService.cs → inject ILoadingEventPublisher
API/Services/SignalRLoadingEventPublisher.cs → implement ด้วย IHubContext<Hub>
API/Program.cs → register SignalRLoadingEventPublisher
```

**Events ที่ push หลัง state change:**
- `BayStatusChanged(bayCode, status)` — ทุก transition
- `LoadingStarted(bayCode, jobId, targetWeight)` — เมื่อเริ่มโหลด
- `LoadingProgress(bayCode, actualWeight, pct)` — UpdateProgress
- `LoadingCompleted(bayCode, jobId, actualWeight)` — Complete
- `EmergencyStop(bayCode, reason)` — Emergency
- `TruckCalled(queueId, bayCode, licensePlate)` — CallTruck
- `TruckDocked(queueId, bayCode)` — ConfirmDock
- `QueueStatusChanged(queueId, status)` — ทุก queue transition

**Frontend hooks:**
- `src/slb-frontend/src/hooks/useLoadingHub.ts` — subscribe LoadingHub
- `src/slb-frontend/src/hooks/useQueueHub.ts` — subscribe QueueHub
- `BayPage.tsx` — ใช้ SignalR แทน polling (fallback 30s)

### Phase 3 ChecklistService ✅ (สมบูรณ์)
**ไฟล์ที่เปลี่ยน:**
- `Infrastructure/Data/Entities/Checklist.cs` — แก้ entity ตรง DB จริง (ลบ ChecklistItem ออก)
- `Infrastructure/Data/SmartLoadBulkDbContext.cs` — ลบ ChecklistItems DbSet
- `Core/DTOs/Check/CheckDtos.cs` — เพิ่ม `ChecklistItemKey` (static Guid constants)
- `Infrastructure/Services/StubServices.cs` — ChecklistService implement จริงครบ

**DB columns จริง (ไม่มี ChecklistItems table!):**
```
LoadChecklists: ChecklistId, JobId, WeightVerified(bit), ActualWeight, WeightDiff,
                QrVerified(bit), DocumentsVerified(bit), SealVerified(bit), DriverVerified(bit),
                VerifiedBy, VerifiedAt, ReleasedBy, ReleasedAt, Remark
ไม่มี: Status, CreatedAt (และ table ChecklistItems ไม่มีใน DB เลย)
```

**ChecklistItemKey (Guid → DB flag mapping):**
```
c0000001-...-0001 → WeightVerified
c0000001-...-0002 → QrVerified
c0000001-...-0003 → DocumentsVerified
c0000001-...-0004 → SealVerified
c0000001-...-0005 → DriverVerified
```

**Status flow (derived จาก flags):**
```
PENDING → (บาง flag = true) → CHECKING → (ทุก flag = true) → VERIFIED → (release) → RELEASED
```

**Lazy init:** `GetChecklistByJobIdAsync` สร้าง record อัตโนมัติถ้ายังไม่มี

---

## State Machine Summary

```
Bay:   AVAILABLE → CALLING → DOCKED → LOADING ⇄ CHECKING → AVAILABLE
Queue: WAITING → CALLED → DOCKED → LOADING → DONE
Job:   CREATED → LOADING ⇄ PAUSED → COMPLETED
```

**DB CHECK constraints (สำคัญมาก — ห้ามใช้ค่าอื่น):**
- Bay: `AVAILABLE | CALLING | DOCKED | LOADING | CHECKING | ERROR | MAINTENANCE`
- Queue: `WAITING | CALLED | DOCKED | LOADING | DONE | CANCELLED`
- LoadJob: `CREATED | QR_ISSUED | QR_SCANNED | LOADING | PAUSED | COMPLETED | FAILED | CANCELLED`

---

## API Endpoints พร้อมใช้ทั้งหมด

| Controller | Endpoints |
|-----------|-----------|
| Auth | POST /api/auth/login |
| Bays | GET /api/bays, GET /api/bays/{id}, POST /api/bays/{id}/call, /dock, /load/start, /load/pause, /load/stop, /load/complete, /load/progress, /reset |
| Queue | GET /api/queue, POST /api/queue/enqueue, PUT /api/queue/{id}/priority, DELETE /api/queue/{id} |
| Orders | GET /api/orders, GET /api/orders/{id}, POST /api/orders, PUT /api/orders/{id}/status, DELETE /api/orders/{id} |
| QR | POST /api/qr/generate, POST /api/qr/validate, GET /api/qr/{jobId}/image, DELETE /api/qr/{tokenId}/revoke |
| Checklist | GET /api/check/{jobId}, POST /api/check/{jobId}/weight, PUT /api/check/{jobId}/item/{itemId}, POST /api/check/{jobId}/release |
| Trucks | GET /api/trucks, GET /api/drivers |
| Inventory | GET /api/inventory |
| Analytics | GET /api/performance, /api/lossyield, /api/bayperformance, /api/turnaround (Stub — Phase 6) |

---

## เมื่อกลับมาทำงาน

```
1. Nick Fury — อ่าน docs/CURRENT_STATUS.md + docs/NEXT_STEPS.md
2. ตรวจ API รัน: netstat -ano | findstr ":5215"
   ถ้าไม่รัน: cd src/SmartLoadBulk.API && dotnet run --launch-profile http
3. Login test: POST http://localhost:5215/api/auth/login
4. Frontend รัน: cd src/slb-frontend && npm run dev
5. ถัดไป: Dark Theme Redesign ต่อ — PageHeader, BayStatusCard, DashboardPage, OrdersPage, LoginPage
   อ้างอิง: docs/feed_loading_system.html
```

---

## ไฟล์ที่แก้ใน Session 7

| ไฟล์ | การเปลี่ยนแปลง |
|------|--------------|
| `Infrastructure/Data/Entities/QrToken.cs` | แก้ columns ตรง DB |
| `Infrastructure/Data/Entities/Checklist.cs` | แก้ entity ตรง DB (ลบ ChecklistItem) |
| `Infrastructure/Data/SmartLoadBulkDbContext.cs` | ลบ ChecklistItems DbSet |
| `Core/DTOs/Check/CheckDtos.cs` | เพิ่ม ChecklistItemKey constants |
| `Core/Interfaces/Services/ILoadingEventPublisher.cs` | สร้างใหม่ — publisher interface |
| `Infrastructure/Services/LoadingService.cs` | inject ILoadingEventPublisher, push events |
| `Infrastructure/Services/QrService.cs` | QRCoder PNG จริง + SHA256 hash |
| `Infrastructure/Services/StubServices.cs` | ChecklistService implement จริงครบ |
| `API/Services/SignalRLoadingEventPublisher.cs` | สร้างใหม่ — SignalR implementation |
| `API/Program.cs` | register SignalRLoadingEventPublisher |
| `slb-frontend/src/hooks/useLoadingHub.ts` | สร้างใหม่ |
| `slb-frontend/src/hooks/useQueueHub.ts` | สร้างใหม่ |
| `slb-frontend/src/pages/BayPage.tsx` | ใช้ SignalR + bayStore |
