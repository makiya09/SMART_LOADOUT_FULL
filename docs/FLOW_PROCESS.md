# FLOW PROCESS — Smart Load Bulk V2.0

**Version:** 2.0  
**อัปเดต:** 2026-05-13 (Doctor Strange V2.0 — ครอบคลุม 10 Module)  
**อ้างอิง:** docs/SYSTEM_ARCHITECTURE.md V2.0, docs/PROJECT_CONTEXT.md

---

## รายการ Flow ทั้งหมด

| # | Flow | Module | คำอธิบาย |
|---|------|--------|----------|
| F01 | Master Flow — ภาพรวมระบบ | ทั้งระบบ | Journey จาก Order → Dispatch |
| F02 | Order & Queue Flow | Order & Queue | สร้าง Order → เข้า Queue |
| F03 | Truck Register Flow | Truck Register | ลงทะเบียนรถและคนขับ |
| F04 | QR Code for Loading Flow | QR Code | สร้าง QR → Verify |
| F05 | Truck Calling & Loading Flow | Truck Calling | เรียกรถ → เทียบท่า → Loading |
| F06 | Double Check Loading Flow | Double Check | ตรวจสอบ Loading ก่อน Release |
| F07 | Hardware Integration Flow | Hardware | Gateway → Device → Event |
| F08 | Inventory Management Flow | Inventory | รับสินค้า → อัปเดต Inventory |
| F09 | Software Integration Flow | Software Integration | ERP/WMS Sync |
| F10 | Performance Analytics Flow | Performance Analytics | Collect → Compute → Display |
| F11 | Loss/Yield Monitoring Flow | Loss/Yield | Measure → Alert → Report |
| F12 | Emergency Stop Flow | Hardware/Safety | Emergency → Halt → Resume |

---

## F01 — Master Flow ภาพรวมระบบ

```
┌─────────────────────────────────────────────────────────────────┐
│                    SMART LOAD BULK — MASTER FLOW                │
└─────────────────────────────────────────────────────────────────┘

  PLANNING                   EXECUTION                  ANALYTICS
  ─────────                  ─────────                  ─────────

  [ERP/WMS] ──────────────→ [Order Created]
       ↓                          ↓
  [Inventory                [Queue Assigned]
   Available?] ─No→ [Hold]       ↓
       │                   [Truck Register]
       Yes                       ↓
       ↓                   [QR Code Issued]
  [Order                         ↓
   Confirmed]             [Truck Called] ←──── [Supervisor]
                                ↓
                         [Truck Arrive]
                                ↓
                         [QR Verified]
                                ↓
                         [Bay Assigned]
                                ↓
                         [Hardware Ready]         [Real-time
                          (Radar/Panel)            Dashboard]
                                ↓                     ↑
                         [Loading Start] ────────────→│
                                ↓                     │
                    ┌────── [Loading] ──────────────→ │
                    │           ↓                     │
                    │   [Target Weight?]               │
                    │       ↓  No → continue          │
                    │      Yes                        │
                    │           ↓                     │
                    └──→ [Double Check]               │
                                ↓                     │
                         [Seal & Sign]                │
                                ↓                     │
                         [Release Truck] ────────────→│
                                ↓                     │
                         [Invoice/DO]                 │
                                ↓                     ↓
                         [Job Complete] ──────→ [Analytics Update]
                                                      ↓
                                               [KPI Computed]
                                                      ↓
                                               [Alert if needed]
```

---

## F02 — Order & Queue Flow

```
Actor: SUPERVISOR / ERP System
─────────────────────────────────────────────────────────────────

START
  │
  ▼
[SUPERVISOR เปิดหน้า Order]
  │
  ▼
[กรอก Order Detail]
  ├── Customer (ลูกค้า)
  ├── Product (สินค้า)
  ├── Ordered Weight (ตัน)
  ├── Target Date/Time
  └── Priority (NORMAL/HIGH/URGENT)
  │
  ▼
[POST /api/orders]
  │
  ▼
[API ตรวจสอบ Inventory]
  ├── มี Stock เพียงพอ?
  │   ├── No → Response: INSUFFICIENT_STOCK
  │   │         → UI แสดง Warning + ยังสร้างได้ (PENDING)
  │   └── Yes → ต่อไป
  │
  ▼
[สร้าง Order (status = PENDING)]
  │
  ▼
[สร้าง OrderItems (แยก Product แต่ละตัว)]
  │
  ▼
[SUPERVISOR ยืนยัน Order → POST /api/orders/{id}/confirm]
  │
  ▼
[สร้าง LoadQueue Entry]
  ├── QueueNumber (AUTO: yyyyMMdd-NNN)
  ├── Priority ตาม Order
  ├── Status = WAITING
  └── EstimatedStart คำนวณจาก Queue ปัจจุบัน
  │
  ▼
[SignalR → QueueHub.OnQueueUpdated broadcast ไปทุก Client]
  │
  ▼
[หน้า Queue Board อัปเดต Real-time]
  │
  ▼
[Order Status = CONFIRMED]

END

─── State Machine ────────────────────────────────────────────────

Order:  PENDING → CONFIRMED → IN_PROGRESS → COMPLETED
                                          └→ CANCELLED

Queue:  WAITING → CALLED → LOADING → LOADED → COMPLETED
                └→ SKIPPED (รถไม่มา)
```

---

## F03 — Truck Register Flow

```
Actor: ADMIN / SUPERVISOR
─────────────────────────────────────────────────────────────────

START
  │
  ├─── [ลงทะเบียนรถใหม่] ──────────────────────────────┐
  │         │                                            │
  │         ▼                                            │
  │    [กรอก ข้อมูลรถ]                                   │
  │         ├── LicensePlate (ทะเบียน)                   │
  │         ├── TruckType (FRONT_LOAD/REAR_LOAD/SIDE)    │
  │         ├── Capacity (ตัน)                           │
  │         ├── OwnerName                                │
  │         └── ContactPhone                             │
  │         │                                            │
  │         ▼                                            │
  │    [POST /api/trucks]                                │
  │         │                                            │
  │         ▼                                            │
  │    [บันทึก + ได้ TruckId]                            │
  │                                                      │
  ├─── [ลงทะเบียน Driver] ──────────────────────────────┤
  │         │                                            │
  │         ▼                                            │
  │    [กรอก ข้อมูล Driver]                              │
  │         ├── FullName                                 │
  │         ├── LicenseNumber                            │
  │         ├── Phone                                    │
  │         └── IDCard                                   │
  │         │                                            │
  │         ▼                                            │
  │    [POST /api/drivers]                               │
  │         │                                            │
  │         ▼                                            │
  │    [บันทึก + ได้ DriverId]                           │
  │                                                      │
  └─── [ผูก Truck ↔ Driver] ───────────────────────────→┘
            │
            ▼
       [POST /api/trucks/{id}/drivers]
            │
            ▼
       [บันทึก TruckDriverMap]
            │   (IsPrimary = ว่านี่เป็นคนขับหลักหรือไม่)
            ▼
       [ข้อมูลพร้อมใช้ใน Order & QR Flow]

END

─── Validation Rules ─────────────────────────────────────────────

 • LicensePlate ต้องไม่ซ้ำ (UNIQUE constraint)
 • DriverLicenseNumber ต้องไม่ซ้ำ
 • 1 รถ ผูกได้หลาย Driver (แต่ Primary Driver 1 คน)
 • IsActive = false = ปิดการใช้งาน (Soft Delete)
```

---

## F04 — QR Code for Loading Flow

```
Actor: SUPERVISOR (ออก QR) / OPERATOR (Scan QR)
─────────────────────────────────────────────────────────────────

                    ┌─ ISSUE QR ─────────────────────────────┐
                    │                                        │
[Order CONFIRMED] ──→ [POST /api/qr/generate]               │
                    │        │                               │
                    │        ▼                               │
                    │  [Server สร้าง JWT Token]              │
                    │        ├── payload: {                  │
                    │        │     orderId,                  │
                    │        │     truckId,                  │
                    │        │     driverId,                 │
                    │        │     issuedAt,                 │
                    │        │     exp: +8hr                 │
                    │        │   }                           │
                    │        ├── signed: HMAC-SHA256         │
                    │        └── สร้าง QrToken record        │
                    │              (IsUsed = false)          │
                    │                                        │
                    │        ▼                               │
                    │  [Response: QR Image PNG + TokenId]    │
                    │                                        │
                    │        ▼                               │
                    │  [SUPERVISOR พิมพ์/แสดง QR]            │
                    └────────────────────────────────────────┘

                    ┌─ SCAN & VERIFY ─────────────────────────┐
                    │                                         │
[OPERATOR Scan QR] ──→ [POST /api/qr/verify]                 │
                    │        │                                │
                    │        ▼                                │
                    │  [Server ตรวจสอบ Token]                 │
                    │        ├── JWT Valid? (signature)       │
                    │        │   No → 401 INVALID_TOKEN       │
                    │        ├── Expired? (exp > now)         │
                    │        │   Yes → 401 TOKEN_EXPIRED      │
                    │        ├── IsUsed?                      │
                    │        │   Yes → 401 TOKEN_ALREADY_USED │
                    │        └── All Pass → ต่อไป             │
                    │                                         │
                    │        ▼                                │
                    │  [อัปเดต QrToken.IsUsed = true]         │
                    │  [อัปเดต QrToken.UsedAt = now]          │
                    │  [อัปเดต QrToken.UsedByUserId]          │
                    │                                         │
                    │        ▼                                │
                    │  [Response: Order + Truck + Driver Info] │
                    │                                         │
                    │        ▼                                │
                    │  [Bay Assignment → F05]                 │
                    └─────────────────────────────────────────┘

─── QR Token Lifecycle ───────────────────────────────────────────

  ISSUED → USED (Valid Scan)
         → EXPIRED (8hr timeout)
         → REVOKED (Admin ยกเลิก)

─── Security Notes ───────────────────────────────────────────────
 • Single-use token (IsUsed flag)
 • 8-hour expiry
 • Revoke ได้โดย ADMIN ผ่าน DELETE /api/qr/{tokenId}
 • Log ทุก Scan attempt (สำเร็จและล้มเหลว)
```

---

## F05 — Truck Calling & Loading Flow

```
Actor: SUPERVISOR (เรียกรถ) / OPERATOR (ควบคุม Loading) / Hardware (Radar/Panel)
─────────────────────────────────────────────────────────────────

[Queue Board แสดง WAITING Queue]
  │
  ▼
[SUPERVISOR เลือก Queue → กด "เรียกรถ"]
  │
  ▼
[POST /api/queues/{id}/call]
  │
  ▼
[อัปเดต LoadQueue.Status = CALLED]
[อัปเดต LoadQueue.CalledAt = now]
  │
  ▼
[SignalR → QueueHub.OnTruckCalled → แสดงบน TV Display]
  │
  ▼
[รถเข้า Bay ที่กำหนด]
  │
  ▼
[Radar Sensor ตรวจจับรถเข้า]
  │
  ▼
[Hardware Gateway → POST /api/hardware/events]
  │   └── EventType = TRUCK_DETECTED
  │
  ▼
[API → SignalR → HardwareHub.OnTruckDetected]
  │
  ▼
[OPERATOR กด "เริ่ม Loading" บนหน้า Bay Control]
  │
  ▼
[POST /api/loading/jobs]
  │
  ▼
[สร้าง LoadJob]
  ├── Status = IN_PROGRESS
  ├── BayId
  ├── QueueId → OrderId → ProductId → SiloId
  ├── StartedAt = now
  └── TargetWeight จาก Order
  │
  ▼
[อัปเดต Bay.Status = LOADING]
[อัปเดต Queue.Status = LOADING]
  │
  ▼
[SignalR → LoadingHub.OnLoadingStarted]
  │
  ▼
┌─────────────── LOADING IN PROGRESS ───────────────────────────┐
│                                                                │
│  [Loading Panel ส่ง Weight ทุก N วินาที]                       │
│        │                                                       │
│        ▼                                                       │
│  [Hardware Gateway → POST /api/hardware/events]                │
│        └── EventType = WEIGHT_UPDATE, value = xx.xx ton       │
│        │                                                       │
│        ▼                                                       │
│  [API อัปเดต LoadJob.CurrentWeight]                            │
│  [SignalR → LoadingHub.OnWeightUpdated(jobId, weight)]         │
│        │                                                       │
│        ▼                                                       │
│  [UI แสดง Progress Bar: CurrentWeight / TargetWeight]          │
│        │                                                       │
│        ▼                                                       │
│  [CurrentWeight ≥ TargetWeight?]                               │
│        │   No → วนซ้ำ                                          │
│        │   Yes → ต่อไป                                         │
│        ▼                                                       │
│  [Loading Panel ส่ง LOADING_COMPLETE event]                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
  │
  ▼
[SignalR → LoadingHub.OnLoadingComplete]
  │
  ▼
[→ F06 Double Check Loading]
  │
  ▼ (หลัง Double Check ผ่าน)
[POST /api/loading/jobs/{id}/complete]
  │
  ▼
[อัปเดต LoadJob.Status = COMPLETED]
[อัปเดต LoadJob.CompletedAt]
[อัปเดต LoadJob.ActualWeight]
[อัปเดต Bay.Status = IDLE]
[อัปเดต Queue.Status = COMPLETED]
[อัปเดต Inventory.CurrentStock -= ActualWeight]
  │
  ▼
[สร้าง InventoryLog, BayLog, AuditLog]
  │
  ▼
[SignalR → LoadingHub.OnJobCompleted]
[SignalR → InventoryHub.OnInventoryUpdated]
  │
  ▼
[→ F10 Analytics Update triggered]

END
```

---

## F06 — Double Check Loading Flow

```
Actor: SUPERVISOR (ตรวจสอบ) / OPERATOR (ยืนยัน)
─────────────────────────────────────────────────────────────────

[Loading Complete → หน้า Double Check เปิดอัตโนมัติ]
  │
  ▼
[แสดง Checklist ทั้งหมด]
  │
  Items ทั่วไป:
  ├── □ น้ำหนักตรงตาม Order?
  ├── □ สินค้าถูก Product?
  ├── □ ปิดฝา/Cover เรียบร้อย?
  ├── □ Seal ติดแล้ว?
  ├── □ เอกสาร DO/Invoice ครบ?
  └── □ คนขับลงชื่อรับแล้ว?
  │
  ▼
[OPERATOR Tick แต่ละรายการ]
  │
  ▼
[POST /api/loading/jobs/{id}/checklist]
  │   Body: { items: [{checklistItemId, isChecked, note}] }
  │
  ▼
[บันทึก LoadChecklist]
  │
  ▼
[มีรายการที่ FAIL?]
  ├── Yes → แสดง Warning
  │         [SUPERVISOR ตัดสินใจ: แก้ไข / Override]
  │         ถ้า Override → บันทึก Reason ใน Note
  │         ถ้าแก้ไข → กลับไป Loading
  │
  └── No (ทุกรายการ Pass) → ต่อไป
  │
  ▼
[SUPERVISOR กด "Confirm & Release"]
  │
  ▼
[POST /api/loading/jobs/{id}/complete] (ดู F05)
  │
  ▼
[ออก Delivery Order / พิมพ์เอกสาร]
  │
  ▼
[รถออกจาก Bay]
  │
  ▼
[Radar ตรวจจับรถออก → Hardware Event TRUCK_DEPARTED]
  │
  ▼
[Bay.Status = IDLE]
[Bay พร้อมรับรถคันถัดไป]

END

─── Checklist Rules ──────────────────────────────────────────────
 • Checklist Template กำหนดต่อ Product Type
 • SUPERVISOR สามารถเพิ่ม/ลด Item ใน Checklist ได้
 • ถ้า IsRequired = true และ IsChecked = false → Block Release
 • ทุก Override ต้องมี Note (ความยาว ≥ 10 ตัวอักษร)
```

---

## F07 — Hardware Integration Flow

```
Actor: Hardware Devices / Gateway Service / Background Service
─────────────────────────────────────────────────────────────────

HARDWARE LAYER
──────────────
  [QR Scanner]          [Radar Sensor]        [Loading Panel]
  Protocol: TCP/Serial  Protocol: Modbus TCP   Protocol: Modbus TCP
       │                      │                      │
       └──────────────────────┴──────────────────────┘
                               │
                               ▼
GATEWAY SERVICE (Background Service ใน ASP.NET Core)
─────────────────────────────────────────────────────
  ┌─────────────────────────────────────────────────────┐
  │                                                      │
  │  [Device Adapter Pool]                               │
  │       ├── QRScannerAdapter (TCP/COM Port)            │
  │       ├── RadarAdapter (Modbus TCP)                  │
  │       └── LoadingPanelAdapter (Modbus TCP)           │
  │                │                                     │
  │                ▼                                     │
  │  [Event Normalizer]                                  │
  │       ├── QR_SCANNED        ← QR Reader              │
  │       ├── TRUCK_DETECTED    ← Radar                  │
  │       ├── TRUCK_DEPARTED    ← Radar                  │
  │       ├── WEIGHT_UPDATE     ← Loading Panel          │
  │       ├── LOADING_COMPLETE  ← Loading Panel          │
  │       └── EMERGENCY_STOP    ← Any Device             │
  │                │                                     │
  │                ▼                                     │
  │  [POST /api/hardware/events] ← internal call         │
  │                                                      │
  └──────────────────────────────────────────────────────┘
                               │
                               ▼
API LAYER
─────────
  [HardwareController.PostEvent()]
       │
       ├── บันทึก HardwareEvent ใน DB
       ├── อัปเดต HardwareDevice.LastSeen
       │
       └── Route by EventType:
           ├── QR_SCANNED       → QrService.ProcessScan()
           ├── TRUCK_DETECTED   → BayService.TruckArrived()
           ├── TRUCK_DEPARTED   → BayService.TruckDeparted()
           ├── WEIGHT_UPDATE    → LoadingService.UpdateWeight()
           ├── LOADING_COMPLETE → LoadingService.SignalComplete()
           └── EMERGENCY_STOP  → SafetyService.EmergencyHalt()
       │
       ▼
  [SignalR Broadcast → HardwareHub]
       │
       ▼
  [UI Real-time Update]

─── Device Health Check ──────────────────────────────────────────

  Background Service ทำ Health Check ทุก 30 วินาที:
  ├── Ping Device
  ├── อัปเดต HardwareDevice.Status (ONLINE/OFFLINE/ERROR)
  └── SignalR → HardwareHub.OnDeviceStatusChanged
      └── UI แสดง Hardware Status Badge

─── Simulation Mode ──────────────────────────────────────────────
  • appsettings: "HardwareMode": "Simulation"
  • Simulation Adapter ส่ง Mock Events ทุก N วินาที
  • ไม่ต้องต่อ Hardware จริงในช่วง Development
```

---

## F08 — Inventory Management Flow

```
Actor: SUPERVISOR / System (Auto-deduct)
─────────────────────────────────────────────────────────────────

┌─── รับสินค้า (Inbound) ──────────────────────────────────────┐
│                                                               │
│  [SUPERVISOR กรอก Inbound Quantity]                           │
│        │                                                      │
│        ▼                                                      │
│  [POST /api/inventory/adjust]                                 │
│        │   Body: { siloId, productId, quantity, note }        │
│        │                                                      │
│        ▼                                                      │
│  [อัปเดต Inventory.CurrentStock += quantity]                  │
│  [สร้าง InventoryLog (type = INBOUND)]                        │
│  [SignalR → InventoryHub.OnInventoryUpdated]                  │
│                                                               │
└───────────────────────────────────────────────────────────────┘

┌─── ลดสต็อก (Auto-deduct after Loading) ──────────────────────┐
│                                                               │
│  [LoadJob Completed] ← F05                                    │
│        │                                                      │
│        ▼                                                      │
│  [InventoryService.Deduct(siloId, productId, actualWeight)]   │
│        │                                                      │
│        ▼                                                      │
│  [อัปเดต Inventory.CurrentStock -= actualWeight]              │
│  [สร้าง InventoryLog (type = OUTBOUND)]                       │
│  [SignalR → InventoryHub.OnInventoryUpdated]                  │
│                                                               │
│  [Stock < MinimumStock?]                                      │
│        │   Yes → สร้าง NotificationLog (LOW_STOCK)           │
│        │         SignalR → InventoryHub.OnLowStockAlert       │
│        └── No → ปกติ                                          │
│                                                               │
└───────────────────────────────────────────────────────────────┘

┌─── Inventory Dashboard Flow ─────────────────────────────────┐
│                                                               │
│  [GET /api/inventory]                                         │
│        │                                                      │
│        ▼                                                      │
│  [Query slb.vw_InventoryStatus]                               │
│        │   (Silo + Product + CurrentStock + MinimumStock +    │
│        │    Capacity + LastUpdated + Status)                  │
│        ▼                                                      │
│  [Response → UI Inventory Cards]                              │
│        │                                                      │
│        ▼                                                      │
│  [แสดง: Stock Level Gauge, Low Stock Alert, History Chart]    │
│                                                               │
└───────────────────────────────────────────────────────────────┘

─── Stock Status ─────────────────────────────────────────────────
  NORMAL   : Stock ≥ MinimumStock × 1.5
  LOW      : MinimumStock ≤ Stock < MinimumStock × 1.5
  CRITICAL : Stock < MinimumStock
  EMPTY    : Stock = 0
```

---

## F09 — Software Integration Flow

```
Actor: ERP System / WMS / External API
─────────────────────────────────────────────────────────────────

┌─── ERP → Smart Load Bulk (Inbound) ──────────────────────────┐
│                                                               │
│  [ERP ส่ง Order ผ่าน REST API]                                │
│        │                                                      │
│        ▼                                                      │
│  [POST /api/integration/orders]                               │
│        ├── Header: X-API-Key: {key}                           │
│        └── Body: { externalOrderId, customerId, items[] }     │
│        │                                                      │
│        ▼                                                      │
│  [API Key ถูกต้อง?]                                           │
│        │   No → 401 Unauthorized                              │
│        │   Yes → ต่อไป                                        │
│        │                                                      │
│        ▼                                                      │
│  [Map External → Internal Format]                             │
│  [สร้าง Order + OrderItems ใน DB]                             │
│  [เก็บ ExternalOrderId สำหรับ Sync back]                      │
│        │                                                      │
│        ▼                                                      │
│  [Response: { orderId, queueNumber, estimatedStart }]         │
│                                                               │
└───────────────────────────────────────────────────────────────┘

┌─── Smart Load Bulk → ERP (Outbound) ─────────────────────────┐
│                                                               │
│  [LoadJob Completed] ← F05                                    │
│        │                                                      │
│        ▼                                                      │
│  [IntegrationService.NotifyCompletion()]                      │
│        │                                                      │
│        ▼                                                      │
│  [POST {erpWebhookUrl}/api/deliveries]                        │
│        └── Body: { externalOrderId, actualWeight,             │
│                    completedAt, truckPlate, driverName }      │
│        │                                                      │
│        ▼                                                      │
│  [ERP อัปเดต Delivery Status]                                  │
│                                                               │
│  [Retry 3 ครั้ง ถ้า ERP ไม่ตอบ]                               │
│  [Log ทุก Webhook call ใน AuditLog]                            │
│                                                               │
└───────────────────────────────────────────────────────────────┘

┌─── Polling Mode (ถ้า ERP ไม่รองรับ Webhook) ─────────────────┐
│                                                               │
│  [Background Service ทุก 5 นาที]                              │
│        │                                                      │
│        ▼                                                      │
│  [GET {erpApiUrl}/api/orders?status=PENDING]                  │
│        │                                                      │
│        ▼                                                      │
│  [Import/Update Orders ใน DB]                                 │
│                                                               │
└───────────────────────────────────────────────────────────────┘

─── Integration Modes ────────────────────────────────────────────
  Mode A: Push  — ERP ส่งมาให้ (Webhook IN)
  Mode B: Pull  — เราดึงจาก ERP (Polling)
  Mode C: Manual — Operator กรอกเองใน UI
  (กำหนดได้ใน appsettings IntegrationMode)
```

---

## F10 — Performance Analytics Flow

```
Actor: System (Auto-compute) / SUPERVISOR (View)
─────────────────────────────────────────────────────────────────

DATA COLLECTION LAYER
──────────────────────
  [ทุก LoadJob]           [Queue Events]         [Inventory Events]
       │                       │                       │
       └───────────────────────┴───────────────────────┘
                               │
                               ▼
                    [slb Schema — Raw Data]
                    (LoadJobs, LoadQueues, BayLogs,
                     InventoryLogs, HardwareEvents)

COMPUTATION LAYER (ana Schema)
──────────────────────────────
  [Scheduled Job — ทุก 1 ชั่วโมง หรือ On-demand]
       │
       ▼
  [ana.vw_JobPerformance]
       ├── LoadingAccuracy = |ActualWeight - TargetWeight| / TargetWeight
       ├── LoadingDuration = CompletedAt - StartedAt (minutes)
       ├── YieldPct = (ActualWeight / OrderedWeight) × 100
       └── LossAmount = OrderedWeight - ActualWeight
       │
  [ana.vw_DailyPerformance]
       ├── TotalJobs, CompletedJobs, CancelledJobs
       ├── TotalTonnage, TotalLoss
       └── AvgLoadingTime, AvgWaitingTime
       │
  [ana.vw_BayPerformance]
       ├── JobCount, TotalTonnage per Bay
       └── BayUtilization = TotalLoadingMinutes / (WorkingHours × 60)
       │
  [ana.vw_TruckTurnaround]
       └── TurnaroundTime = DepartureTime - ArrivalTime
       │
  [ana.vw_HourlyThroughput]
       └── Tonnage per Hour per Bay

API LAYER
──────────
  [GET /api/analytics/performance?from=&to=]
       │   → calls ana.sp_GetPerformanceDashboard
       ▼
  [GET /api/analytics/loss-yield?from=&to=]
       │   → calls ana.sp_GetLossYieldDashboard
       ▼
  [GET /api/analytics/bay-performance]
       │   → calls ana.sp_GetBayPerformanceDashboard
       ▼
  [GET /api/analytics/turnaround]
       │   → calls ana.sp_GetTurnaroundDashboard
       ▼
  [GET /api/analytics/product-loss]
       │   → calls ana.sp_GetProductLossAnalysis

DISPLAY LAYER
─────────────
  [React Analytics Dashboard]
       ├── KPI Cards (17 Metrics)
       ├── Line Chart — Daily Tonnage Trend
       ├── Bar Chart — Bay Utilization
       ├── Pie Chart — Loss by Product
       └── Table — Job Detail with drill-down

ALERT LAYER
────────────
  [Background Service ตรวจ KPI ทุก 15 นาที]
       │
       ▼
  [เปรียบกับ ana.AnalyticsConfig Threshold]
       │
       ▼
  [Threshold Exceeded?]
       │   Yes → สร้าง NotificationLog
       │         SignalR → AnalyticsHub.OnKpiAlert
       │         UI แสดง Alert Banner
       └── No → ปกติ

─── KPI Refresh Schedule ─────────────────────────────────────────
  Real-time  : Weight, Bay Status (SignalR)
  Every 15m  : KPI Alert Check
  Every 1hr  : Dashboard Data Refresh
  On-demand  : User กด Refresh
```

---

## F11 — Loss/Yield Monitoring Flow

```
Actor: System (Auto-measure) / SUPERVISOR (View/Alert)
─────────────────────────────────────────────────────────────────

MEASURE PHASE
─────────────
  [LoadJob Completed]
       │
       ▼
  [คำนวณ Loss/Yield ทันที]
       ├── OrderedWeight  = LoadQueue.OrderedWeight
       ├── ActualWeight   = LoadJob.ActualWeight
       ├── YieldPct       = (Actual / Ordered) × 100
       ├── LossAmount     = Ordered - Actual (ถ้า > 0)
       └── OverloadAmount = Actual - Ordered (ถ้า < 0)
       │
       ▼
  [บันทึกใน LoadJob.ActualWeight, LoadJobLogs]

CLASSIFY PHASE
──────────────
  [YieldPct เปรียบกับ Threshold]
       ├── 99.5% – 100.5% → NORMAL (Green)
       ├── 98.0% – 99.5%  → WARNING (Yellow) — Loss เล็กน้อย
       ├── 100.5% – 102%  → WARNING (Yellow) — Over เล็กน้อย
       ├── < 98.0%        → CRITICAL (Red)   — Loss มาก
       └── > 102%         → CRITICAL (Red)   — Over มาก
       │
       ▼
  [บันทึก Status ใน HardwareEvents หรือ AuditLog]

ALERT PHASE
────────────
  [Status = WARNING หรือ CRITICAL]
       │
       ▼
  [สร้าง NotificationLog]
       ├── Type: LOSS_ALERT / OVERLOAD_ALERT
       ├── Severity: WARNING / CRITICAL
       └── Message: "Job #XXX: Yield 97.2% (ต่ำกว่า 98%)"
       │
       ▼
  [SignalR → AnalyticsHub.OnLossAlert]
       │
       ▼
  [UI แสดง Alert Banner บนทุกหน้า]
  [SUPERVISOR ได้รับ Notification]

REPORT PHASE
─────────────
  [SUPERVISOR เปิดหน้า Loss/Yield Dashboard]
       │
       ▼
  [GET /api/analytics/loss-yield?from=&to=&productId=]
       │   → ana.sp_GetLossYieldDashboard
       ▼
  [แสดง]
       ├── Daily Loss Trend Chart
       ├── Loss by Product Bar Chart
       ├── Loss by Bay Heatmap
       ├── Top 10 Jobs with Highest Loss Table
       └── Running Average Yield% (30 วันย้อนหลัง)

─── Root Cause Hints ─────────────────────────────────────────────
  Loss Pattern              | Probable Cause
  ─────────────────────────────────────────────────
  Loss เยอะทุก Bay          | Calibration ของ Sensor
  Loss เยอะเฉพาะ Bay หนึ่ง  | Hardware ของ Bay นั้น
  Loss เยอะเฉพาะ Product    | Density/Moisture ของสินค้า
  Loss เยอะช่วงเวลาหนึ่ง    | Operator Practice
```

---

## F12 — Emergency Stop Flow

```
Actor: OPERATOR / SUPERVISOR / Hardware Device
─────────────────────────────────────────────────────────────────

TRIGGER
────────
  ┌─── ผ่าน UI ────────────────────────────────────────────────┐
  │    [OPERATOR กดปุ่ม Emergency Stop บน Bay Control]         │
  │          │                                                  │
  │          ▼                                                  │
  │    [Dialog: "ยืนยัน Emergency Stop?" — Step 1]             │
  │    [กรอก Reason — Step 2]                                   │
  │    [กด Confirm]                                             │
  │          │                                                  │
  │    [POST /api/loading/jobs/{id}/emergency-stop]             │
  └────────────────────────────────────────────────────────────┘

  ┌─── ผ่าน Hardware ──────────────────────────────────────────┐
  │    [Emergency Button บน Loading Panel ถูกกด]               │
  │          │                                                  │
  │    [Hardware Gateway → POST /api/hardware/events]           │
  │          └── EventType = EMERGENCY_STOP                     │
  └────────────────────────────────────────────────────────────┘

HALT PHASE (ทันที ≤ 100ms)
───────────────────────────
  [SafetyService.EmergencyHalt(jobId, reason, triggeredBy)]
       │
       ├── อัปเดต LoadJob.Status = EMERGENCY_STOPPED
       ├── อัปเดต Bay.Status = ERROR
       ├── บันทึก AuditLog (Emergency Stop)
       │
       ├── [ส่งคำสั่ง HALT ไปยัง Loading Panel]
       │       └── Modbus Write: Register HALT = 1
       │
       └── [SignalR Broadcast ทุก Client]
               └── LoadingHub.OnEmergencyStop(jobId, bay, reason)

UI RESPONSE
────────────
  [ทุกหน้าที่ Subscribe LoadingHub]
       │
       ▼
  [แสดง Full-screen Emergency Banner (Red)]
       └── ข้อความ: "EMERGENCY STOP — Bay X — {reason}"
  [ล็อค ปุ่ม Loading ทุกปุ่ม]
  [Bay Status = ERROR (สีแดง)]

RESUME PHASE (ต้องการ SUPERVISOR)
──────────────────────────────────
  [SUPERVISOR ตรวจสอบเหตุการณ์]
       │
       ▼
  [POST /api/loading/jobs/{id}/resume หรือ /cancel]
       │
       ├── Resume → LoadJob.Status = IN_PROGRESS
       │           Bay.Status = LOADING
       │           ส่งคำสั่ง RESUME ไป Hardware
       │
       └── Cancel → LoadJob.Status = CANCELLED
                   Bay.Status = IDLE
                   ต้อง Manual Reset Hardware
       │
       ▼
  [SignalR → LoadingHub.OnEmergencyResolved]
  [Banner หาย / UI กลับสู่ปกติ]

─── Safety Rules ─────────────────────────────────────────────────
  • ทุก Emergency Stop ต้องมี Reason (บังคับ)
  • Resume ต้องการ Role SUPERVISOR ขึ้นไป
  • ทุก Emergency Event ถูก Log ใน HardwareEvents + AuditLog
  • งาน Hardware (Modbus Write) ต้องผ่าน Dry-run ก่อนใช้จริง
```

---

## State Machine Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                      ORDER STATE MACHINE                        │
│                                                                 │
│  PENDING → CONFIRMED → IN_PROGRESS → COMPLETED                  │
│    ↑            ↑           ↑            ↑                      │
│  กรอก         ยืนยัน    Loading       ส่งรถ                      │
│  Order        Order      เริ่ม         ออก                       │
│                   └→ CANCELLED (ยกเลิก ณ จุดใดก็ได้)            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      QUEUE STATE MACHINE                        │
│                                                                 │
│  WAITING → CALLED → LOADING → LOADED → COMPLETED               │
│                └→ SKIPPED (รถไม่มาภายใน timeout)               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      LOADJOB STATE MACHINE                      │
│                                                                 │
│  IN_PROGRESS → COMPLETED                                        │
│      └→ EMERGENCY_STOPPED → IN_PROGRESS (resume)               │
│                          └→ CANCELLED                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        BAY STATE MACHINE                        │
│                                                                 │
│  IDLE → OCCUPIED → LOADING → IDLE                               │
│             └→ ERROR (Emergency) → IDLE (after reset)          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      QR TOKEN STATE MACHINE                     │
│                                                                 │
│  ISSUED → USED (scan สำเร็จ, single-use)                       │
│        → EXPIRED (8hr timeout)                                  │
│        → REVOKED (Admin ยกเลิก)                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## SignalR Event Flow Summary

```
Event                              Hub             Trigger
──────────────────────────────────────────────────────────────────
OnQueueUpdated(queue)              QueueHub        Order confirm, Call
OnTruckCalled(queueId, bay)        QueueHub        SUPERVISOR call truck
OnInventoryUpdated(inv)            InventoryHub    Inbound / Job complete
OnLowStockAlert(siloId, stock)     InventoryHub    Stock < MinimumStock
OnLoadingStarted(job)              LoadingHub      Job created
OnWeightUpdated(jobId, weight)     LoadingHub      Hardware weight event
OnLoadingComplete(jobId)           LoadingHub      Target weight reached
OnJobCompleted(job)                LoadingHub      Release truck
OnEmergencyStop(jobId, bay, rsn)   LoadingHub      Emergency triggered
OnEmergencyResolved(jobId)         LoadingHub      Resume/Cancel after E-stop
OnDeviceStatusChanged(device)      HardwareHub     Health check
OnHardwareEvent(event)             HardwareHub     Any hardware event
OnKpiAlert(kpiCode, value, thr)    AnalyticsHub    Threshold exceeded
OnLossAlert(jobId, loss, yield)    AnalyticsHub    Loss/Yield out of range
OnDashboardRefresh(summary)        AnalyticsHub    Periodic refresh (1hr)
```

---

*Flow Process V2.0 — Doctor Strange — 2026-05-13*
*ครอบคลุม 10 Module + 12 Flows + State Machines + SignalR Event Summary*
