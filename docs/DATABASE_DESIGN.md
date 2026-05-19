# DATABASE DESIGN — Smart Load Bulk

**ออกแบบโดย:** Shuri  
**วันที่:** 2026-05-13  
**Version:** 1.0  
**Database:** SQL Server 2019+  
**Schema:** `slb`

---

## ภาพรวม

```
Database: SmartLoadBulkDB
Schema:   slb

กลุ่ม Table แบ่งตาม Domain:

[MASTER DATA]          [INVENTORY]         [ORDER & QUEUE]
Users                  Products            Orders
Customers              Silos               OrderItems
Trucks                 Inventory           LoadQueues
Drivers                InventoryLogs
TruckDriverMap

[LOADING]              [QR & VERIFY]       [HARDWARE]
Bays                   QrTokens            HardwareDevices
BayLogs                LoadChecklists      HardwareEvents
LoadJobs               ChecklistItems
LoadJobLogs

[SYSTEM]
NotificationLogs
AuditLogs
```

---

## 1. Table ทั้งหมด (23 Tables)

### กลุ่ม Master Data

#### `slb.Users` — ผู้ใช้งานระบบ
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| UserId | UNIQUEIDENTIFIER | PK, DEFAULT NEWSEQUENTIALID() | รหัสผู้ใช้ |
| Username | VARCHAR(50) | NOT NULL, UNIQUE | ชื่อเข้าใช้ |
| PasswordHash | VARCHAR(256) | NOT NULL | BCrypt Hash |
| FullName | NVARCHAR(100) | NOT NULL | ชื่อเต็ม |
| Email | VARCHAR(150) | UNIQUE | อีเมล |
| Role | VARCHAR(20) | NOT NULL, CHECK | ADMIN/SUPERVISOR/OPERATOR/VIEWER |
| IsActive | BIT | NOT NULL, DEFAULT 1 | สถานะ |
| LastLoginAt | DATETIME2 | NULL | เข้าใช้ล่าสุด |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |
| UpdatedAt | DATETIME2 | NULL | |

#### `slb.Customers` — ลูกค้า
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| CustomerId | UNIQUEIDENTIFIER | PK | รหัสลูกค้า |
| CustomerCode | VARCHAR(20) | NOT NULL, UNIQUE | รหัสสั้น |
| CustomerName | NVARCHAR(150) | NOT NULL | ชื่อบริษัท |
| ContactPerson | NVARCHAR(100) | NULL | ผู้ติดต่อ |
| Phone | VARCHAR(20) | NULL | เบอร์โทร |
| IsActive | BIT | NOT NULL, DEFAULT 1 | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

#### `slb.Trucks` — รถบรรทุก
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| TruckId | UNIQUEIDENTIFIER | PK | รหัสรถ |
| LicensePlate | VARCHAR(20) | NOT NULL, UNIQUE | ทะเบียนรถ |
| TruckType | VARCHAR(20) | NOT NULL, CHECK | TRAILER/TANKER/TIPPER/SILO |
| MaxCapacity | DECIMAL(10,3) | NOT NULL | น้ำหนักบรรทุกสูงสุด (ตัน) |
| CompanyName | NVARCHAR(150) | NULL | บริษัทรถ |
| IsActive | BIT | NOT NULL, DEFAULT 1 | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |
| UpdatedAt | DATETIME2 | NULL | |

#### `slb.Drivers` — คนขับรถ
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| DriverId | UNIQUEIDENTIFIER | PK | รหัสคนขับ |
| FullName | NVARCHAR(100) | NOT NULL | ชื่อ-นามสกุล |
| LicenseNo | VARCHAR(20) | NOT NULL, UNIQUE | เลขใบขับขี่ |
| LicenseExpiry | DATE | NOT NULL | วันหมดอายุใบขับขี่ |
| Phone | VARCHAR(20) | NULL | เบอร์โทร |
| IsActive | BIT | NOT NULL, DEFAULT 1 | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

#### `slb.TruckDriverMap` — จับคู่รถ-คนขับ
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| MapId | UNIQUEIDENTIFIER | PK | |
| TruckId | UNIQUEIDENTIFIER | FK → Trucks | |
| DriverId | UNIQUEIDENTIFIER | FK → Drivers | |
| IsActive | BIT | NOT NULL, DEFAULT 1 | คู่ปัจจุบัน |
| AssignedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

---

### กลุ่ม Inventory

#### `slb.Products` — สินค้า/วัตถุดิบ Bulk
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| ProductId | UNIQUEIDENTIFIER | PK | รหัสสินค้า |
| ProductCode | VARCHAR(20) | NOT NULL, UNIQUE | รหัสสินค้าสั้น |
| ProductName | NVARCHAR(150) | NOT NULL | ชื่อสินค้า |
| Unit | NVARCHAR(10) | NOT NULL | หน่วย (ตัน/KG/ลิตร) |
| MinStock | DECIMAL(12,3) | NOT NULL, DEFAULT 0 | Stock ขั้นต่ำ (Alert) |
| CriticalStock | DECIMAL(12,3) | NOT NULL, DEFAULT 0 | Stock วิกฤต (Block Order) |
| MaxStock | DECIMAL(12,3) | NOT NULL, DEFAULT 0 | Stock สูงสุด |
| IsActive | BIT | NOT NULL, DEFAULT 1 | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

#### `slb.Silos` — ไซโล/ถัง เก็บสินค้า
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| SiloId | UNIQUEIDENTIFIER | PK | รหัส Silo |
| SiloCode | VARCHAR(10) | NOT NULL, UNIQUE | รหัสสั้น (S01, S02) |
| SiloName | NVARCHAR(100) | NOT NULL | ชื่อไซโล |
| ProductId | UNIQUEIDENTIFIER | FK → Products | สินค้าที่เก็บ |
| Capacity | DECIMAL(12,3) | NOT NULL | ความจุสูงสุด (ตัน) |
| IsActive | BIT | NOT NULL, DEFAULT 1 | |

#### `slb.Inventory` — Stock ปัจจุบันต่อ Silo
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| InventoryId | UNIQUEIDENTIFIER | PK | |
| ProductId | UNIQUEIDENTIFIER | FK → Products | |
| SiloId | UNIQUEIDENTIFIER | FK → Silos, UNIQUE | 1 Silo = 1 Row |
| CurrentStock | DECIMAL(12,3) | NOT NULL, DEFAULT 0 | Stock ที่มีจริง |
| ReservedStock | DECIMAL(12,3) | NOT NULL, DEFAULT 0 | จอง (Order Confirmed แล้ว) |
| UpdatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

**Computed:** `AvailableStock = CurrentStock - ReservedStock`

#### `slb.InventoryLogs` — ประวัติการเคลื่อนไหว Stock
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| LogId | BIGINT | PK, IDENTITY | |
| ProductId | UNIQUEIDENTIFIER | FK → Products | |
| SiloId | UNIQUEIDENTIFIER | FK → Silos | |
| ChangeType | VARCHAR(15) | NOT NULL, CHECK | IN/OUT/ADJUST/RESERVE/UNRESERVE |
| Qty | DECIMAL(12,3) | NOT NULL | ปริมาณเปลี่ยนแปลง |
| BeforeStock | DECIMAL(12,3) | NOT NULL | Stock ก่อนเปลี่ยน |
| AfterStock | DECIMAL(12,3) | NOT NULL | Stock หลังเปลี่ยน |
| RefType | VARCHAR(20) | NULL | ORDER/LOADING/ADJUSTMENT |
| RefId | UNIQUEIDENTIFIER | NULL | FK ไปยัง Record อ้างอิง |
| Remark | NVARCHAR(500) | NULL | หมายเหตุ |
| CreatedBy | UNIQUEIDENTIFIER | FK → Users | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

---

### กลุ่ม Order & Queue

#### `slb.Orders` — ออเดอร์โหลดสินค้า
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| OrderId | UNIQUEIDENTIFIER | PK | |
| OrderCode | VARCHAR(20) | NOT NULL, UNIQUE | ORD-YYYY-NNNNNN |
| CustomerId | UNIQUEIDENTIFIER | FK → Customers | |
| OrderDate | DATE | NOT NULL, DEFAULT GETDATE() | |
| RequiredDate | DATE | NOT NULL | วันที่ต้องการ |
| Status | VARCHAR(15) | NOT NULL, CHECK | DRAFT/CONFIRMED/QUEUED/LOADING/COMPLETED/CANCELLED |
| TotalWeight | DECIMAL(12,3) | NULL | น้ำหนักรวม (คำนวณจาก Items) |
| Remark | NVARCHAR(500) | NULL | |
| CreatedBy | UNIQUEIDENTIFIER | FK → Users | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |
| UpdatedAt | DATETIME2 | NULL | |

#### `slb.OrderItems` — รายการสินค้าใน Order
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| ItemId | UNIQUEIDENTIFIER | PK | |
| OrderId | UNIQUEIDENTIFIER | FK → Orders | |
| ProductId | UNIQUEIDENTIFIER | FK → Products | |
| RequestedQty | DECIMAL(12,3) | NOT NULL | ปริมาณที่สั่ง |
| ActualQty | DECIMAL(12,3) | NULL | ปริมาณที่โหลดจริง |
| Unit | NVARCHAR(10) | NOT NULL | |

#### `slb.LoadQueues` — คิวรถ
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| QueueId | UNIQUEIDENTIFIER | PK | |
| OrderId | UNIQUEIDENTIFIER | FK → Orders | |
| TruckId | UNIQUEIDENTIFIER | FK → Trucks | |
| DriverId | UNIQUEIDENTIFIER | FK → Drivers | |
| Priority | TINYINT | NOT NULL, DEFAULT 5 | 1=ด่วนสุด, 9=ต่ำสุด |
| Status | VARCHAR(12) | NOT NULL, CHECK | WAITING/CALLED/DOCKED/LOADING/DONE/CANCELLED |
| EnqueuedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |
| CalledAt | DATETIME2 | NULL | เวลาที่ถูกเรียก |
| DockedAt | DATETIME2 | NULL | เวลาที่รถเข้า Bay |
| CompletedAt | DATETIME2 | NULL | เวลาที่เสร็จ |
| Remark | NVARCHAR(300) | NULL | |

---

### กลุ่ม Bay & Loading

#### `slb.Bays` — Bay โหลด
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| BayId | UNIQUEIDENTIFIER | PK | |
| BayCode | VARCHAR(10) | NOT NULL, UNIQUE | BAY-01, BAY-02 |
| BayName | NVARCHAR(100) | NOT NULL | ชื่อ Bay |
| BayType | VARCHAR(20) | NOT NULL, CHECK | BULK_DRY/BULK_LIQUID/GENERAL |
| MaxCapacity | DECIMAL(10,3) | NOT NULL | ตัน |
| IsActive | BIT | NOT NULL, DEFAULT 1 | |
| CurrentQueueId | UNIQUEIDENTIFIER | FK → LoadQueues, NULL | Queue ที่ใช้งานอยู่ |
| Status | VARCHAR(15) | NOT NULL, CHECK | AVAILABLE/CALLING/DOCKED/LOADING/CHECKING/ERROR/MAINTENANCE |
| LastUpdatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

#### `slb.BayLogs` — ประวัติ Event ของ Bay
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| LogId | BIGINT | PK, IDENTITY | |
| BayId | UNIQUEIDENTIFIER | FK → Bays | |
| QueueId | UNIQUEIDENTIFIER | FK → LoadQueues, NULL | |
| EventType | VARCHAR(25) | NOT NULL, CHECK | STATUS_CHANGE/TRUCK_CALLED/TRUCK_DOCKED/LOAD_STARTED/LOAD_COMPLETED/EMERGENCY/RESET |
| EventData | NVARCHAR(1000) | NULL | JSON Payload |
| CreatedBy | UNIQUEIDENTIFIER | FK → Users, NULL | NULL = System |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

#### `slb.LoadJobs` — งานโหลดสินค้า
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| JobId | UNIQUEIDENTIFIER | PK | |
| JobCode | VARCHAR(25) | NOT NULL, UNIQUE | JOB-YYYYMMDD-NNNNNN |
| OrderId | UNIQUEIDENTIFIER | FK → Orders | |
| OrderItemId | UNIQUEIDENTIFIER | FK → OrderItems | |
| TruckId | UNIQUEIDENTIFIER | FK → Trucks | |
| DriverId | UNIQUEIDENTIFIER | FK → Drivers | |
| BayId | UNIQUEIDENTIFIER | FK → Bays | |
| ProductId | UNIQUEIDENTIFIER | FK → Products | |
| SiloId | UNIQUEIDENTIFIER | FK → Silos, NULL | |
| TargetWeight | DECIMAL(10,3) | NOT NULL | น้ำหนักเป้าหมาย |
| ActualWeight | DECIMAL(10,3) | NULL | น้ำหนักจริง |
| TolerancePct | DECIMAL(5,2) | NOT NULL, DEFAULT 0.5 | % ยอมรับ |
| Status | VARCHAR(15) | NOT NULL, CHECK | CREATED/QR_ISSUED/QR_SCANNED/LOADING/PAUSED/COMPLETED/FAILED/CANCELLED |
| StartedAt | DATETIME2 | NULL | |
| CompletedAt | DATETIME2 | NULL | |
| FailReason | NVARCHAR(300) | NULL | |
| CreatedBy | UNIQUEIDENTIFIER | FK → Users | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |
| UpdatedAt | DATETIME2 | NULL | |

#### `slb.LoadJobLogs` — บันทึกน้ำหนักระหว่างโหลด
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| LogId | BIGINT | PK, IDENTITY | |
| JobId | UNIQUEIDENTIFIER | FK → LoadJobs | |
| EventType | VARCHAR(20) | NOT NULL, CHECK | WEIGHT_UPDATE/LOAD_START/LOAD_PAUSE/LOAD_RESUME/EMERGENCY_STOP/LOAD_COMPLETE |
| CurrentWeight | DECIMAL(10,3) | NULL | น้ำหนักขณะนั้น |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

---

### กลุ่ม QR & Verification

#### `slb.QrTokens` — QR Code Token
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| TokenId | UNIQUEIDENTIFIER | PK | |
| JobId | UNIQUEIDENTIFIER | FK → LoadJobs | |
| Token | VARCHAR(500) | NOT NULL, UNIQUE | JWT Signed String |
| TokenHash | VARCHAR(64) | NOT NULL | SHA256 สำหรับ Index |
| IsUsed | BIT | NOT NULL, DEFAULT 0 | ใช้แล้วหรือยัง |
| IsRevoked | BIT | NOT NULL, DEFAULT 0 | ถูกยกเลิก |
| RevokeReason | NVARCHAR(200) | NULL | |
| IssuedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |
| ExpiredAt | DATETIME2 | NOT NULL | |
| ScannedAt | DATETIME2 | NULL | |
| ScannedByDeviceId | UNIQUEIDENTIFIER | FK → HardwareDevices, NULL | |

#### `slb.LoadChecklists` — Checklist ก่อนปล่อยรถ
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| ChecklistId | UNIQUEIDENTIFIER | PK | |
| JobId | UNIQUEIDENTIFIER | FK → LoadJobs, UNIQUE | 1 Job = 1 Checklist |
| WeightVerified | BIT | NOT NULL, DEFAULT 0 | น้ำหนักผ่าน |
| ActualWeight | DECIMAL(10,3) | NULL | น้ำหนักจริงที่วัด |
| WeightDiff | DECIMAL(10,3) | NULL | ต่างจาก Target |
| QrVerified | BIT | NOT NULL, DEFAULT 0 | QR ผ่าน |
| DocumentsVerified | BIT | NOT NULL, DEFAULT 0 | เอกสารครบ |
| SealVerified | BIT | NOT NULL, DEFAULT 0 | Seal ปิดถัง |
| DriverVerified | BIT | NOT NULL, DEFAULT 0 | ตรวจสอบคนขับ |
| VerifiedBy | UNIQUEIDENTIFIER | FK → Users, NULL | Operator |
| VerifiedAt | DATETIME2 | NULL | |
| ReleasedBy | UNIQUEIDENTIFIER | FK → Users, NULL | Supervisor |
| ReleasedAt | DATETIME2 | NULL | |
| Remark | NVARCHAR(500) | NULL | |

#### `slb.ChecklistItems` — รายการ Checklist แบบ Dynamic
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| ItemId | UNIQUEIDENTIFIER | PK | |
| ChecklistId | UNIQUEIDENTIFIER | FK → LoadChecklists | |
| ItemCode | VARCHAR(20) | NOT NULL | WEIGHT, QR, SEAL, DOC, DRIVER |
| ItemName | NVARCHAR(100) | NOT NULL | คำอธิบาย |
| IsRequired | BIT | NOT NULL, DEFAULT 1 | |
| IsChecked | BIT | NOT NULL, DEFAULT 0 | |
| CheckedBy | UNIQUEIDENTIFIER | FK → Users, NULL | |
| CheckedAt | DATETIME2 | NULL | |
| Remark | NVARCHAR(200) | NULL | |

---

### กลุ่ม Hardware

#### `slb.HardwareDevices` — อุปกรณ์ Hardware
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| DeviceId | UNIQUEIDENTIFIER | PK | |
| DeviceCode | VARCHAR(20) | NOT NULL, UNIQUE | QRS-BAY01, RDR-BAY01 |
| DeviceName | NVARCHAR(100) | NOT NULL | ชื่ออุปกรณ์ |
| DeviceType | VARCHAR(20) | NOT NULL, CHECK | QR_SCANNER/RADAR/LOADING_PANEL/WEIGHT_SENSOR |
| Location | NVARCHAR(100) | NULL | ตำแหน่งติดตั้ง |
| BayId | UNIQUEIDENTIFIER | FK → Bays, NULL | ประจำ Bay ไหน |
| IpAddress | VARCHAR(15) | NULL | |
| Port | INT | NULL | |
| Protocol | VARCHAR(15) | NOT NULL, CHECK | SERIAL/TCP/MODBUS_TCP/HID |
| Status | VARCHAR(15) | NOT NULL, CHECK | ONLINE/OFFLINE/ERROR/MAINTENANCE |
| LastHeartbeat | DATETIME2 | NULL | |
| IsActive | BIT | NOT NULL, DEFAULT 1 | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |
| UpdatedAt | DATETIME2 | NULL | |

#### `slb.HardwareEvents` — Event จาก Hardware
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| EventId | BIGINT | PK, IDENTITY | |
| DeviceId | UNIQUEIDENTIFIER | FK → HardwareDevices | |
| EventType | VARCHAR(20) | NOT NULL, CHECK | QR_SCANNED/VEHICLE_DETECTED/WEIGHT_UPDATE/PANEL_STATE/HEARTBEAT/ERROR |
| Payload | NVARCHAR(2000) | NULL | JSON |
| IsProcessed | BIT | NOT NULL, DEFAULT 0 | |
| ProcessedAt | DATETIME2 | NULL | |
| ErrorMessage | NVARCHAR(500) | NULL | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

---

### กลุ่ม System

#### `slb.NotificationLogs` — Log การแจ้งเตือน
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| NotifId | BIGINT | PK, IDENTITY | |
| NotifType | VARCHAR(30) | NOT NULL | STOCK_ALERT/TRUCK_CALLED/EMERGENCY/DEVICE_OFFLINE/GATE_RELEASE |
| Severity | VARCHAR(10) | NOT NULL, CHECK | INFO/WARNING/ERROR/CRITICAL |
| Title | NVARCHAR(200) | NOT NULL | หัวเรื่อง |
| Message | NVARCHAR(1000) | NOT NULL | เนื้อหา |
| RefType | VARCHAR(20) | NULL | ORDER/JOB/BAY/DEVICE |
| RefId | UNIQUEIDENTIFIER | NULL | |
| Channel | VARCHAR(15) | NOT NULL | SIGNALR/EMAIL/LINE |
| RecipientRole | VARCHAR(20) | NULL | Role ที่ส่งถึง |
| IsSent | BIT | NOT NULL, DEFAULT 0 | |
| SentAt | DATETIME2 | NULL | |
| ErrorMessage | NVARCHAR(500) | NULL | |
| CreatedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |

#### `slb.AuditLogs` — Audit Trail ทุก Action
| Column | Type | Constraint | คำอธิบาย |
|--------|------|-----------|----------|
| AuditId | BIGINT | PK, IDENTITY | |
| TableName | VARCHAR(50) | NOT NULL | ชื่อ Table ที่แก้ไข |
| RecordId | NVARCHAR(50) | NOT NULL | PK ของ Record |
| Action | VARCHAR(10) | NOT NULL, CHECK | INSERT/UPDATE/DELETE |
| OldValues | NVARCHAR(MAX) | NULL | JSON ก่อนแก้ |
| NewValues | NVARCHAR(MAX) | NULL | JSON หลังแก้ |
| ChangedBy | UNIQUEIDENTIFIER | FK → Users, NULL | |
| ChangedAt | DATETIME2 | NOT NULL, DEFAULT SYSDATETIME() | |
| IpAddress | VARCHAR(45) | NULL | IPv4/IPv6 |

---

## 2. Relationship Diagram

```
Users ──────────────────────────────────────────────┐
  │                                                  │ CreatedBy
  │                                                  ▼
Customers ──▶ Orders ──▶ OrderItems ──▶ Products ──▶ Silos
                │                          │           │
                │                          └──▶ Inventory
                │                                  (Stock)
                ▼
            LoadQueues ◀──── Trucks
                │              │
                │            Drivers
                │         TruckDriverMap
                ▼
              Bays ──▶ BayLogs
                │
                ▼
            LoadJobs ──▶ LoadJobLogs
                │
                ├──▶ QrTokens ◀── HardwareDevices ──▶ HardwareEvents
                │
                └──▶ LoadChecklists ──▶ ChecklistItems
```

---

## 3. Index Strategy

| Table | Index | Columns | เหตุผล |
|-------|-------|---------|--------|
| Orders | IX_Orders_Status | Status, CreatedAt | Filter Order ตาม Status |
| Orders | IX_Orders_CustomerId | CustomerId | Join กับ Customer |
| LoadQueues | IX_Queue_Status | Status, Priority, EnqueuedAt | Queue Board Sort |
| LoadQueues | IX_Queue_TruckId | TruckId | ค้นหา Queue ของรถ |
| LoadJobs | IX_Jobs_Status | Status, CreatedAt | Active Jobs |
| LoadJobs | IX_Jobs_BayId | BayId | Bay ปัจจุบัน |
| LoadJobLogs | IX_JobLogs_JobId | JobId, CreatedAt | ดึง Log ของ Job |
| Inventory | IX_Inv_ProductId | ProductId | Dashboard |
| InventoryLogs | IX_InvLogs_ProductId | ProductId, CreatedAt | ประวัติ Stock |
| QrTokens | IX_QR_TokenHash | TokenHash | Lookup ตอน Validate |
| QrTokens | IX_QR_JobId | JobId | |
| HardwareEvents | IX_HwEv_DeviceId | DeviceId, CreatedAt | |
| HardwareEvents | IX_HwEv_Unprocessed | IsProcessed, CreatedAt | Poll Unprocessed |
| AuditLogs | IX_Audit_Table | TableName, ChangedAt | |
| NotificationLogs | IX_Notif_Unsent | IsSent, CreatedAt | Retry Unsent |

---

## 4. Stored Procedures

| SP Name | คำอธิบาย |
|---------|----------|
| `sp_GetInventoryDashboard` | Stock ทุก Product + Alert Status |
| `sp_GetQueueBoard` | Queue Board ปัจจุบัน (พร้อม Join รถ/คนขับ) |
| `sp_GetBayStatus` | สถานะ Bay ทั้งหมด + Job ที่ Active |
| `sp_EnqueueTruck` | เพิ่มรถเข้า Queue + Reserve Stock |
| `sp_CallTruckToBay` | เรียกรถเข้า Bay + เปลี่ยนสถานะ |
| `sp_CreateLoadJob` | สร้าง Job + ออก QR Token |
| `sp_ValidateQrToken` | ตรวจสอบ QR + Mark Used |
| `sp_UpdateLoadProgress` | อัปเดตน้ำหนัก + Log |
| `sp_CompleteLoading` | โหลดเสร็จ + สร้าง Checklist |
| `sp_ReleaseGate` | อนุมัติปล่อยรถ + ลด Stock จริง |

---

## 5. Views

| View | ใช้สำหรับ |
|------|-----------|
| `vw_InventoryDashboard` | หน้า Inventory รวม Stock ทุก Silo ต่อ Product |
| `vw_QueueBoard` | หน้า Queue Board พร้อมข้อมูลครบ |
| `vw_BayMonitor` | หน้า Bay Monitor พร้อม Job ปัจจุบัน |
| `vw_ActiveLoadJobs` | Jobs ที่กำลัง Loading อยู่ (SignalR Feed) |
| `vw_DailySummary` | สรุปยอดโหลดประจำวัน |

---

## 6. Status Enums

```
Users.Role:
  ADMIN | SUPERVISOR | OPERATOR | VIEWER

Trucks.TruckType:
  TRAILER | TANKER | TIPPER | SILO | GENERAL

Orders.Status:
  DRAFT → CONFIRMED → QUEUED → LOADING → COMPLETED
                                              ↑
  CANCELLED ←─────────────────────── (ทุก Status)

LoadQueues.Status:
  WAITING → CALLED → DOCKED → LOADING → DONE
  CANCELLED

Bays.Status:
  AVAILABLE → CALLING → DOCKED → LOADING → CHECKING → AVAILABLE
                                                ↓
                                              ERROR → (Manual RESET)

LoadJobs.Status:
  CREATED → QR_ISSUED → QR_SCANNED → LOADING → PAUSED → LOADING
                                                    ↓
                                               COMPLETED | FAILED | CANCELLED

HardwareDevices.Status:
  ONLINE | OFFLINE | ERROR | MAINTENANCE

InventoryLogs.ChangeType:
  IN | OUT | ADJUST | RESERVE | UNRESERVE
```

---

## 7. ไฟล์ SQL

- `db/001_create_smart_load_bulk_tables.sql` — Script หลัก (Create + SP + View + Test Data + Rollback)
