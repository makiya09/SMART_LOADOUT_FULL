# SMART LOAD BULK — TEST PLAN (ฉบับสมบูรณ์)

**เขียนโดย:** Captain America (QA/Testing Agent)  
**วันที่:** 2026-05-14  
**Version:** 1.0  
**อ้างอิง:** docs/PROJECT_CONTEXT.md, docs/FLOW_PROCESS.md V2.0, docs/DATABASE_DESIGN.md, docs/PERFORMANCE_ANALYTICS_PLAN.md, docs/UI_UX_DESIGN.md

---

## ส่วนที่ 1: Test Strategy Overview

### 1.1 Test Scope

ระบบ Smart Load Bulk ครอบคลุม 10 Module หลัก ดังนี้:

| # | Module | In Scope | Priority |
|---|--------|----------|----------|
| 1 | Truck Register | ใช่ | P2 |
| 2 | Order & Queue Management | ใช่ | P1 |
| 3 | Truck Calling & Loading | ใช่ | P1 |
| 4 | QR Code Verification | ใช่ | P1 |
| 5 | Double Check Loading | ใช่ | P1 |
| 6 | Inventory Management | ใช่ | P2 |
| 7 | Realtime (SignalR) | ใช่ | P1 |
| 8 | Hardware Status Monitor | ใช่ | P2 |
| 9 | Performance Analytics | ใช่ | P2 |
| 10 | Loss / Yield Dashboard | ใช่ | P2 |
| 11 | Report / Export | ใช่ | P3 |
| 12 | Notification | ใช่ | P2 |

**Out of Scope (Phase แรก):**
- PLC Write Command จริง (ทำได้แค่ Simulation Mode)
- ERP/SAP Integration แบบ Production Live
- Mobile App

---

### 1.2 Test Levels

| Level | คำอธิบาย | เครื่องมือ |
|-------|----------|-----------|
| **Unit Test** | ทดสอบ Function / Method ย่อย | xUnit (.NET) |
| **Integration Test** | ทดสอบ API + Database | Swagger UI / Postman |
| **System Test** | ทดสอบ End-to-End Flow ทั้งระบบ | Manual + Browser |
| **Regression Test** | ทดสอบหลัง Patch/Update ว่าไม่พัง | ชุด TC-016 |
| **Performance Test** | ทดสอบ SignalR ภายใต้ Load | Artillery / manual |

---

### 1.3 Test Types

| Type | ย่อ | คำอธิบาย |
|------|-----|----------|
| **Manual** | M | ทดสอบด้วยมือผ่าน Browser |
| **API** | A | ทดสอบผ่าน Swagger UI หรือ Postman |
| **E2E** | E | ทดสอบ Flow ต้นถึงปลายจากหน้าจอ |
| **DB** | D | ทดสอบด้วย SQL Query ตรง SSMS |

---

### 1.4 Test Environment

| Layer | Spec |
|-------|------|
| **Database** | SQL Server 2019+ / SmartLoadBulkDB / Schema: slb, ana |
| **Backend** | ASP.NET Core 9 Web API / Port 5000 (HTTP) หรือ 5001 (HTTPS) |
| **Frontend** | React + Vite / TypeScript / Tailwind CSS / Port 5173 |
| **SignalR** | Hub: `/hubs/queue`, `/hubs/loading`, `/hubs/hardware`, `/hubs/analytics` |
| **Auth** | JWT Bearer Token / Role: ADMIN, SUPERVISOR, OPERATOR, VIEWER |
| **Browser** | Chrome 120+ (Primary), Edge (Secondary) |

**User Account สำหรับ Test:**

| Username | Password | Role | ใช้ Test |
|----------|----------|------|---------|
| admin01 | Test@1234 | ADMIN | TC ที่ต้องการ Admin |
| supervisor01 | Test@1234 | SUPERVISOR | TC การควบคุม Loading |
| operator01 | Test@1234 | OPERATOR | TC การ Scan QR |
| viewer01 | Test@1234 | VIEWER | TC ตรวจ Unauthorized |

---

### 1.5 Test Data Strategy

**ใช้ Seed Data จาก:** `db/003_create_analytics_objects.sql` Section 6

ข้อมูล Seed ที่ใช้:
- **12 LoadJobs** (ANA-TEST-001 ถึง ANA-TEST-012)
  - Normal Jobs: ANA-TEST-001, 002, 003 — Yield 99.7–100.2%
  - Warning Jobs: ANA-TEST-004, 005 — Yield 98.2–98.8%
  - Critical Jobs: ANA-TEST-006, 007 — Yield 96.5–97.3%
  - Failed/Emergency: ANA-TEST-008, 009
- **Master Data:** Trucks, Drivers, Bays, Products, Silos, Customers ที่มีในระบบ

---

### 1.6 Pass / Fail Criteria

| เกณฑ์ | Pass | Fail |
|-------|------|------|
| **Functional** | ระบบทำงานตาม Expected Result | ผลลัพธ์ต่างจาก Expected |
| **Validation** | ระบบแสดง Error Message ที่ชัดเจน | ไม่แสดง Error หรือ Crash |
| **Performance** | API Response < 2 วินาที | API Response > 5 วินาที |
| **SignalR** | Update ถึง Browser อื่นใน < 3 วินาที | ไม่ Update หรือ Delay > 10 วินาที |
| **Security** | 403 เมื่อ Role ไม่เพียงพอ | อนุญาตการเข้าถึงที่ไม่ควร |

---

## ส่วนที่ 2: Test Cases หลัก (TC-001 ถึง TC-014)

### TC-001: Truck Register

**วัตถุประสงค์:** ทดสอบการลงทะเบียนรถ, คนขับ, และการจัดการข้อมูล

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-001-01 | สร้างรถใหม่สำเร็จ | Login เป็น ADMIN, ไปหน้า Truck Register | 1) คลิก "Add Truck" 2) กรอก LicensePlate = "80-6789", TruckType = "TRAILER", MaxCapacity = 30 3) คลิก Save | รถถูกสร้าง, แสดงในตาราง, TruckId ได้รับ | P2 | E |
| TC-001-02 | ป้องกันทะเบียนรถซ้ำ | มีรถ "80-6789" ในระบบแล้ว | 1) คลิก "Add Truck" 2) กรอก LicensePlate = "80-6789" 3) คลิก Save | แสดง Error "ทะเบียนรถนี้มีในระบบแล้ว" (400 Bad Request) | P1 | E |
| TC-001-03 | สร้างคนขับใหม่สำเร็จ | Login เป็น ADMIN | 1) คลิก "Add Driver" 2) กรอก FullName = "สมชาย ใจดี", LicenseNo = "DRV-12345", LicenseExpiry = 2027-12-31, Phone = "0812345678" 3) คลิก Save | คนขับถูกสร้าง, แสดงในตาราง | P2 | E |
| TC-001-04 | ตรวจใบขับขี่หมดอายุ | มีคนขับที่ LicenseExpiry = 2025-01-01 (หมดแล้ว) | 1) เปิดหน้า Driver List 2) ค้นหาคนขับที่หมดอายุ | แสดง Badge "ใบขับขี่หมดอายุ" (สีแดง) บนรายการคนขับ | P1 | M |
| TC-001-05 | ค้นหารถด้วยทะเบียน | มีรถหลายคันในระบบ | 1) ไปหน้า Truck Register 2) พิมพ์ "80-67" ใน Search Box | ตารางกรองแสดงเฉพาะรถที่มีทะเบียนตรงกัน | P2 | M |
| TC-001-06 | Filter รถตาม TruckType | มีรถ TRAILER และ TANKER ในระบบ | 1) เลือก Filter "TruckType = TANKER" 2) กด Apply | แสดงเฉพาะรถประเภท TANKER | P3 | M |
| TC-001-07 | Deactivate รถ (IsActive = false) | มีรถที่ Active ในระบบ | 1) คลิกที่รถ 2) คลิก Toggle "Active" → Off 3) Confirm | รถถูก Deactivate, แสดง Badge "Inactive", ไม่แสดงใน Queue Dropdown | P2 | E |
| TC-001-08 | Reactivate รถ | มีรถที่ Inactive | 1) Filter รถที่ Inactive 2) คลิก Toggle "Active" → On | รถกลับมา Active, แสดงปกติ | P3 | E |
| TC-001-09 | ผูก Truck กับ Driver | มีรถและคนขับที่ยังไม่ผูกกัน | 1) เปิดรถ 2) คลิก "Assign Driver" 3) เลือกคนขับ 4) เลือก IsPrimary = true 5) Save | ความสัมพันธ์ TruckDriverMap ถูกสร้าง | P2 | E |

**API Tests สำหรับ TC-001:**

```http
POST /api/trucks
Authorization: Bearer {admin_token}
Content-Type: application/json
{
  "licensePlate": "80-6789",
  "truckType": "TRAILER",
  "maxCapacity": 30,
  "companyName": "บริษัทขนส่งทดสอบ"
}
Expected: 201 Created

GET /api/trucks?search=80-67
Expected: 200 OK, array ของรถที่ตรงกัน

PUT /api/trucks/{truckId}/deactivate
Expected: 200 OK, isActive = false
```

---

### TC-002: Queue Generate

**วัตถุประสงค์:** ทดสอบการสร้างคิวจาก Order ที่ Confirmed

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-002-01 | สร้าง Queue จาก Order Confirmed | มี Order ที่ Status = CONFIRMED, มีรถในระบบ | 1) ไปหน้า Queue Management 2) เลือก Order ที่ Confirmed 3) เลือกรถและคนขับ 4) คลิก "Add to Queue" | สร้าง LoadQueue (Status = WAITING), QueueNumber = yyyyMMdd-NNN, แสดงใน Queue Board | P1 | E |
| TC-002-02 | ตรวจ Priority Queue (URGENT ก่อน NORMAL) | มี Queue NORMAL ที่รออยู่ก่อน, เพิ่ม Queue URGENT | 1) สร้าง Queue Priority = 1 (URGENT) 2) ดู Queue Board | Queue ที่ Priority 1 แสดงอยู่บนสุดของรายการ | P1 | M |
| TC-002-03 | ป้องกัน Enqueue ซ้ำ (Order เดิม) | มี Order ที่อยู่ใน Queue แล้ว | 1) พยายาม Add Order เดิมเข้า Queue อีกครั้ง | แสดง Error "Order นี้มีในคิวแล้ว" (400 Bad Request) | P1 | E |
| TC-002-04 | Cancel Queue + คืน Status | มี Queue WAITING | 1) คลิก Queue 2) คลิก "Cancel Queue" 3) กรอก Reason 4) Confirm | Queue.Status = CANCELLED, Order.Status กลับเป็น CONFIRMED, สามารถ Enqueue ใหม่ได้ | P1 | E |
| TC-002-05 | Order ที่มีสินค้าไม่เพียงพอ | Inventory ต่ำกว่า OrderedQty | 1) สร้าง Order สินค้า X จำนวน 50 ตัน 2) Inventory X มี 10 ตัน | แสดง Warning "สินค้าไม่เพียงพอ" (ยังสร้าง Order ได้แต่เตือน) | P1 | E |
| TC-002-06 | Queue Board อัปเดต Real-time | เปิด 2 Browser Tab | 1) สร้าง Queue ใน Browser 1 2) สังเกต Browser 2 | Browser 2 อัปเดต Queue Board อัตโนมัติภายใน 3 วินาที (SignalR) | P1 | E |

**API Tests สำหรับ TC-002:**

```http
POST /api/orders/{orderId}/confirm
Authorization: Bearer {supervisor_token}
Expected: 200 OK, status = CONFIRMED

POST /api/queues
Authorization: Bearer {supervisor_token}
{
  "orderId": "{orderId}",
  "truckId": "{truckId}",
  "driverId": "{driverId}",
  "priority": 5
}
Expected: 201 Created, queueNumber: "20260514-001"

DELETE /api/queues/{queueId}
Body: { "reason": "ลูกค้ายกเลิก" }
Expected: 200 OK, status = CANCELLED
```

---

### TC-003: Truck Calling

**วัตถุประสงค์:** ทดสอบการเรียกรถเข้า Bay และการเปลี่ยน Bay Status

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-003-01 | เรียกรถเข้า Bay ที่ว่าง | มี Queue WAITING, มี Bay AVAILABLE | 1) ไปหน้า Truck Calling 2) เลือก Queue 3) เลือก Bay 4) คลิก "เรียกรถ" | Queue.Status = CALLED, Bay.Status = CALLING, TV Display แสดงชื่อรถ/Bay | P1 | E |
| TC-003-02 | Bay Status เปลี่ยน AVAILABLE → CALLING → DOCKED | Bay เป็น AVAILABLE | 1) เรียกรถ 2) รถเข้า Bay (Radar Event) | Bay.Status เปลี่ยนตามลำดับ, SignalR อัปเดตทุก Client | P1 | E |
| TC-003-03 | กรณี Bay ทุกอันเต็ม | Bay ทุก Bay มีสถานะไม่ใช่ AVAILABLE | 1) พยายามเรียกรถ 2) ดู Bay Dropdown | Dropdown แสดงว่าทุก Bay ไม่ว่าง, หรือปุ่ม "เรียกรถ" ถูก Disable | P2 | M |
| TC-003-04 | Emergency Stop ระหว่าง Calling | รถกำลัง Loading ใน Bay | 1) คลิกปุ่ม Emergency Stop 2) กรอก Reason 3) Confirm | LoadJob.Status = EMERGENCY_STOPPED, Bay.Status = ERROR, แสดง Banner แดง Full-screen | P1 | E |
| TC-003-05 | TV Display Mode แสดงถูกต้อง | มีการเรียกรถ | 1) เปิดหน้า TV Display 2) เรียกรถจาก Supervisor Page | TV Display แสดงชื่อรถ, Bay, QueueNumber ด้วยตัวอักษรขนาดใหญ่ (text-6xl+) | P2 | M |
| TC-003-06 | Resume หลัง Emergency Stop | มี Job ที่ EMERGENCY_STOPPED | 1) Login เป็น SUPERVISOR 2) คลิก Resume บน Job ที่หยุด | LoadJob.Status = IN_PROGRESS, Bay.Status = LOADING, Banner หาย | P1 | E |

**API Tests สำหรับ TC-003:**

```http
POST /api/queues/{queueId}/call
Authorization: Bearer {supervisor_token}
Body: { "bayId": "{bayId}" }
Expected: 200 OK, queue.status = CALLED, bay.status = CALLING

POST /api/loading/jobs/{jobId}/emergency-stop
Authorization: Bearer {operator_token}
Body: { "reason": "สายส่งหลุด" }
Expected: 200 OK, job.status = EMERGENCY_STOPPED

POST /api/loading/jobs/{jobId}/resume
Authorization: Bearer {supervisor_token}
Expected: 200 OK, job.status = IN_PROGRESS
```

---

### TC-004: QR Code Verification

**วัตถุประสงค์:** ทดสอบการสร้าง QR Token, การ Scan Verify และ Security ของ QR

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-004-01 | Generate QR Token สำหรับ Job ใหม่ | มี LoadJob ที่ Status = QR_ISSUED | 1) เปิดหน้า QR สำหรับ Job 2) คลิก "Generate QR" | ได้รับ QR Image PNG, TokenId, IsUsed = false, ExpiredAt = now + 8hr | P1 | E |
| TC-004-02 | Scan QR → Validate → ผ่าน | มี QR Token ที่ valid (ยังไม่หมดอายุ, ยังไม่ใช้) | 1) Scan QR ด้วย Device หรือ Manual Input 2) POST /api/qr/verify | ได้รับ 200 OK, ข้อมูล Order + Truck + Driver, Token.IsUsed = true | P1 | E |
| TC-004-03 | QR หมดอายุ (>8 ชั่วโมง) → ปฏิเสธ | มี QR Token ที่ ExpiredAt < now | 1) ส่ง Token ที่หมดอายุไปที่ /api/qr/verify | 401 Unauthorized, Error Code = TOKEN_EXPIRED | P1 | A |
| TC-004-04 | QR ถูกใช้แล้ว → ปฏิเสธ | มี QR Token ที่ IsUsed = true | 1) Scan QR ที่ใช้แล้ว 2) POST /api/qr/verify | 401 Unauthorized, Error Code = TOKEN_ALREADY_USED | P1 | A |
| TC-004-05 | QR ปลอม (Signature ไม่ถูกต้อง) → ปฏิเสธ | ไม่มี Precondition พิเศษ | 1) POST /api/qr/verify ด้วย Token ที่แก้ไขเอง | 401 Unauthorized, Error Code = INVALID_TOKEN | P1 | A |
| TC-004-06 | QR ถูก Revoke โดย Admin | ADMIN Revoke Token | 1) Admin DELETE /api/qr/{tokenId} 2) ลอง Scan Token เดิม | 401 Unauthorized, Error Code = TOKEN_REVOKED | P1 | A |
| TC-004-07 | ตรวจ Audit Log ทุก Scan Attempt | มีการ Scan ทั้งสำเร็จและล้มเหลว | 1) ตรวจ AuditLogs ใน DB | มีบันทึกทุก Scan Attempt ทั้งสำเร็จและล้มเหลว พร้อม Timestamp และ UserId | P2 | D |

**SQL สำหรับ TC-004-07:**
```sql
-- ตรวจ Audit Log การ Scan QR
SELECT TOP 20 * 
FROM slb.AuditLogs
WHERE Action LIKE '%QR%'
ORDER BY CreatedAt DESC

-- ตรวจ Token ที่ใช้แล้ว
SELECT TokenId, IsUsed, IsRevoked, ScannedAt 
FROM slb.QrTokens
WHERE JobId = '{jobId}'
```

---

### TC-005: Loading Double Check

**วัตถุประสงค์:** ทดสอบ Checklist, Weight Verification และ Release Gate

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-005-01 | Checklist ครบทุกรายการ → ผ่าน | มี Job ที่ Loading เสร็จ | 1) หน้า Double Check เปิดอัตโนมัติ 2) Tick ทุก Checkbox (น้ำหนัก, QR, Seal, เอกสาร, คนขับ) 3) Save | Checklist.WeightVerified = QrVerified = DocumentsVerified = SealVerified = DriverVerified = true | P1 | E |
| TC-005-02 | บันทึกน้ำหนักจริง vs เป้าหมาย | มีหน้า Double Check | 1) กรอก ActualWeight = 25.450 ตัน (TargetWeight = 25.000) | บันทึก ActualWeight, คำนวณ WeightDiff = 0.450 ตัน | P1 | E |
| TC-005-03 | Over Weight Alert (>Target+Tolerance) | TargetWeight = 25.000, Tolerance = 0.5% | 1) กรอก ActualWeight = 25.200 ตัน (เกิน 0.8%) | แสดง Warning Banner "น้ำหนักเกิน 0.8% จากเป้าหมาย" (สีเหลือง/แดง) | P1 | E |
| TC-005-04 | Short Weight Alert (<Target-Tolerance) | TargetWeight = 25.000, Tolerance = 0.5% | 1) กรอก ActualWeight = 24.000 ตัน (ขาด 4%) | แสดง Alert "น้ำหนักขาด 4% จากเป้าหมาย" (สีแดง/CRITICAL) | P1 | E |
| TC-005-05 | IsRequired = true และไม่ได้ Tick → Block Release | มีรายการ IsRequired = true ที่ยังไม่ได้ Tick | 1) คลิก "Confirm & Release" โดยไม่ Tick รายการ IsRequired | ระบบ Block การ Release, แสดง Error "กรุณากรอกรายการที่จำเป็นทุกข้อ" | P1 | E |
| TC-005-06 | Override ที่มี Note (≥10 ตัวอักษร) | มีรายการที่ Fail แต่ SUPERVISOR Override | 1) SUPERVISOR คลิก Override 2) กรอก Note < 10 ตัวอักษร 3) ลอง Save | แสดง Error "กรุณาระบุเหตุผล (อย่างน้อย 10 ตัวอักษร)" | P1 | E |
| TC-005-07 | Release Gate (Role ADMIN/SUPERVISOR เท่านั้น) | Login เป็น OPERATOR | 1) ลองคลิก "Confirm & Release" | ปุ่ม Release ถูก Disable หรือ 403 Forbidden | P1 | E |
| TC-005-08 | Release Gate สำเร็จ (SUPERVISOR) | Checklist ครบ, Login เป็น SUPERVISOR | 1) คลิก "Confirm & Release" 2) Confirm Dialog | Job.Status = COMPLETED, Bay.Status = IDLE, Inventory ถูก Deduct | P1 | E |

---

### TC-006: Inventory Balance

**วัตถุประสงค์:** ทดสอบ Stock Display, Adjustment และ Alert

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-006-01 | ดู Stock ปัจจุบันต่อสินค้า/Silo | มีข้อมูล Inventory | 1) ไปหน้า Inventory Dashboard 2) ดูการ์ดแต่ละ Silo | แสดง CurrentStock, ReservedStock, AvailableStock, Status Badge | P2 | M |
| TC-006-02 | Inventory Adjustment (เพิ่ม Stock) | Login เป็น ADMIN/SUPERVISOR | 1) คลิก "Adjust Inventory" 2) เลือก Silo 3) กรอก Quantity = +10 4) กรอก Note 5) Save | CurrentStock เพิ่มขึ้น 10, สร้าง InventoryLog (type=ADJUST) | P2 | E |
| TC-006-03 | Inventory Adjustment (ลด Stock) | CurrentStock ≥ 5 | 1) Adjust Quantity = -5 | CurrentStock ลดลง 5, สร้าง InventoryLog (type=ADJUST) | P2 | E |
| TC-006-04 | Low Stock Warning (MinStock ≤ Stock < 1.5×MinStock) | Stock อยู่ใน Zone LOW | 1) ดูหน้า Inventory Dashboard | แสดง Badge "LOW" สีเหลือง (Amber) | P2 | M |
| TC-006-05 | Critical Stock Alert (Stock < MinStock) | Stock < MinStock | 1) ดูหน้า Inventory Dashboard 2) ตรวจ Notification | แสดง Badge "CRITICAL" สีแดง, มี NotificationLog (type=LOW_STOCK) | P1 | E |
| TC-006-06 | Stock ไม่พอสำหรับ Order | Stock = 5 ตัน, Order = 20 ตัน | 1) สร้าง Order สินค้าที่ Stock ไม่พอ 2) Confirm Order | แสดง Warning "สินค้าไม่เพียงพอ", Order ยังสร้างได้แต่ Status = PENDING | P1 | E |
| TC-006-07 | Auto-deduct หลัง Job Complete | Job Complete แล้ว | 1) ดู Inventory ก่อน Job Complete 2) Release Job 3) ดู Inventory อีกครั้ง | CurrentStock ลดลงเท่ากับ ActualWeight ของ Job | P1 | D |

**SQL สำหรับ TC-006-07:**
```sql
-- ตรวจ Inventory ก่อน-หลัง Job
SELECT il.ChangeType, il.Qty, il.BeforeStock, il.AfterStock, il.CreatedAt
FROM slb.InventoryLogs il
WHERE il.RefType = 'LOADING'
  AND il.RefId = '{jobId}'
ORDER BY il.CreatedAt DESC
```

---

### TC-007: Realtime Queue Update (SignalR)

**วัตถุประสงค์:** ทดสอบ Realtime Update ผ่าน SignalR Hub

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-007-01 | Queue Update ถึง 2 Browser | เปิด 2 Browser (Chrome + Edge) ล็อกอินแล้ว | 1) Browser 1: สร้าง Queue ใหม่ 2) สังเกต Browser 2 | Browser 2 แสดง Queue ใหม่ใน Queue Board ภายใน 3 วินาที (ไม่ต้อง Refresh) | P1 | E |
| TC-007-02 | Bay Status เปลี่ยนบน TV Display | TV Display Mode เปิดอยู่ | 1) เรียกรถจาก Supervisor Page 2) สังเกต TV Display | TV Display อัปเดตชื่อรถและ Bay ทันที | P1 | E |
| TC-007-03 | SignalR Reconnect อัตโนมัติ | Browser เชื่อมต่อ SignalR อยู่ | 1) ตัด Network ชั่วคราว (F12 → Throttle: Offline) 2) รอ 5 วินาที 3) เปิด Network กลับ | Browser Reconnect อัตโนมัติ, แสดง "Reconnecting..." ระหว่างขาด, กลับมาทำงานปกติ | P1 | E |
| TC-007-04 | Weight Update Real-time ระหว่าง Loading | Job กำลัง LOADING | 1) ดูหน้า Bay Control 2) Hardware ส่ง WEIGHT_UPDATE Event | Progress Bar อัปเดตแสดง CurrentWeight / TargetWeight แบบ Real-time | P1 | E |

---

### TC-008: Hardware Status

**วัตถุประสงค์:** ทดสอบการแสดงสถานะ Device และ Alert

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-008-01 | แสดง Device ทั้งหมดพร้อมสถานะ | มี HardwareDevices ใน DB | 1) ไปหน้า Hardware Monitor | แสดงการ์ดทุก Device: DeviceCode, DeviceName, Status Badge, LastHeartbeat | P2 | M |
| TC-008-02 | Auto-refresh ทุก 15 วินาที | เปิดหน้า Hardware Monitor | 1) สังเกต LastHeartbeat ของ Device 2) รอ 15+ วินาที | ข้อมูล LastHeartbeat อัปเดต (หรือ Badge Status เปลี่ยน) โดยไม่ Refresh | P2 | M |
| TC-008-03 | Device OFFLINE → สีแดง + Alert | Device ไม่ส่ง Heartbeat > Timeout | 1) หยุด Simulation Device 2) รอ Health Check Cycle (30 วินาที) | Device Status = OFFLINE, Badge สีแดง, มี NotificationLog (Device Offline) | P2 | E |
| TC-008-04 | Device กลับมา ONLINE → สถานะอัปเดต | Device ที่เคย OFFLINE | 1) เริ่ม Device อีกครั้ง 2) รอ Health Check | Device Status เปลี่ยนเป็น ONLINE, Badge สีเขียว | P2 | E |
| TC-008-05 | ตรวจ API Hardware Event | Simulation Mode ทำงาน | 1) POST /api/hardware/events (EventType = HEARTBEAT) | 200 OK, HardwareDevice.LastHeartbeat อัปเดต | P2 | A |

**API Tests สำหรับ TC-008:**
```http
POST /api/hardware/events
Authorization: Bearer {system_token}
{
  "deviceId": "{deviceId}",
  "eventType": "HEARTBEAT",
  "payload": "{}"
}
Expected: 200 OK

GET /api/hardware/devices
Expected: 200 OK, array ของ devices พร้อม status
```

---

### TC-009: Performance Analytics

**วัตถุประสงค์:** ทดสอบ Dashboard KPI และ Stored Procedure ต่างๆ

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-009-01 | เรียก SP sp_GetPerformanceDashboard | มี LoadJobs ใน DB (Seed Data) | 1) GET /api/analytics/performance?from=2026-05-01&to=2026-05-14 | 200 OK, ได้ KPI: totalJobs, completionRate, yieldPct, throughput | P1 | A |
| TC-009-02 | KPI CompletionRate คำนวณถูกต้อง | Seed Data: 10 Jobs, 8 COMPLETED, 2 CANCELLED | 1) เรียก API 2) ดูค่า completionRate | completionRate = 80.0% (8/10 × 100) | P1 | A |
| TC-009-03 | กรองข้อมูลตาม Date Range (วันเดียว) | มีข้อมูลหลายวัน | 1) GET /api/analytics/performance?from=2026-05-14&to=2026-05-14 | ได้ข้อมูลเฉพาะวันที่ 2026-05-14 เท่านั้น | P2 | A |
| TC-009-04 | กรองตาม Date Range ข้ามปี | มีข้อมูลปี 2025 และ 2026 | 1) GET /api/analytics/performance?from=2025-12-01&to=2026-01-31 | ได้ข้อมูล 2 เดือนข้ามปีถูกต้อง | P2 | A |
| TC-009-05 | กรณีไม่มีข้อมูล → Empty State | ส่ง DateRange ที่ไม่มีข้อมูล | 1) GET /api/analytics/performance?from=2030-01-01&to=2030-01-31 | 200 OK, ค่า KPI = 0 หรือ null, หน้า Dashboard แสดง "ไม่มีข้อมูล" | P2 | E |
| TC-009-06 | Throughput Ton/Hour คำนวณถูกต้อง | มี Job ที่ ActualWeight = 25000 kg, LoadingDuration = 30 min | 1) เรียก SP / API | throughput = 25/0.5 = 50 ton/hr | P1 | D |
| TC-009-07 | Dashboard แสดง KPI Cards | เปิดหน้า /analytics | 1) ไปหน้า Performance Dashboard 2) เลือก Date Range | แสดง KPI Card ทั้งหมด (Total Jobs, Completion Rate, Yield%, Accuracy%, Throughput) พร้อม Status Badge | P1 | M |

**SQL สำหรับ TC-009-06:**
```sql
EXEC ana.sp_GetPerformanceDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'
-- ตรวจ Column: TotalJobs, CompletedJobs, YieldPct, ThroughputTonPerHour
```

---

### TC-010: Loss / Yield Calculation

**วัตถุประสงค์:** ตรวจสอบความถูกต้องของสูตรคำนวณ Loss/Yield

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-010-01 | Yield% = (Actual/Target) × 100 | Job: Target = 25000 kg, Actual = 24925 kg | 1) ดูข้อมูล Job จาก ana.vw_JobPerformance | YieldPct = 24925/25000 × 100 = 99.70% | P1 | D |
| TC-010-02 | Loss = Target - Actual (ถ้า Actual < Target) | Job: Target = 25000, Actual = 24000 | 1) Query vw_JobPerformance | LossKg = 1000 kg, OverKg = 0 | P1 | D |
| TC-010-03 | Over = Actual - Target (ถ้า Actual > Target) | Job: Target = 25000, Actual = 25500 | 1) Query vw_JobPerformance | LossKg = 0, OverKg = 500 kg | P1 | D |
| TC-010-04 | Yield < 98% → Critical Status | Job ANA-TEST-006 (Yield 96.5%) | 1) ตรวจ NotificationLogs หลัง Job Complete | มี NotificationLog Type = LOSS_ALERT, Severity = CRITICAL | P1 | D |
| TC-010-05 | Yield 98–99.5% → Warning Status | Job ANA-TEST-004 (Yield 98.2%) | 1) ตรวจ NotificationLogs | มี NotificationLog Type = LOSS_ALERT, Severity = WARNING | P1 | D |
| TC-010-06 | Yield 99.5–100.5% → Normal Status | Job ANA-TEST-001 (Yield 99.7%) | 1) ตรวจ vw_JobPerformance | ไม่มี Alert, Status = NORMAL (Green) | P1 | D |
| TC-010-07 | SP sp_GetLossYieldDashboard ผลลัพธ์ถูกต้อง | Seed Data ครบ | 1) EXEC ana.sp_GetLossYieldDashboard | ได้ TotalLossKg, TotalOverKg, OverallYieldPct ตรงกับการคำนวณ Manual | P1 | D |

**SQL สำหรับ TC-010:**
```sql
-- ตรวจ Yield Calculation
SELECT JobId, TargetWeight, ActualWeight, YieldPct, LossKg, OverKg
FROM ana.vw_JobPerformance
WHERE JobId IN (
  SELECT JobId FROM slb.LoadJobs WHERE JobCode LIKE 'ANA-TEST-%'
)
ORDER BY YieldPct

-- SP Test
EXEC ana.sp_GetLossYieldDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'
```

---

### TC-011: Bay Performance

**วัตถุประสงค์:** ทดสอบ KPI รายละเอียดของแต่ละ Bay

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-011-01 | เปรียบเทียบ KPI ต่าง Bay | มี Jobs หลาย Bay | 1) ไปหน้า Bay Performance Dashboard 2) เลือก Date Range | แสดง Card แต่ละ Bay: Completion Rate, Yield%, BayUtilizationPct | P2 | M |
| TC-011-02 | BayUtilizationPct คำนวณถูกต้อง | Bay A มี TotalLoadingMin = 480, HoursPerDay = 16 (=960 min) | 1) ดู BayUtilizationPct ของ Bay A | BayUtilizationPct = 480/960 × 100 = 50.0% | P1 | D |
| TC-011-03 | Radar Chart แสดงค่าถูกต้อง | เปิดหน้า Bay Performance | 1) ดู Radar Chart บนหน้า Bay Dashboard | Radar Chart แสดงค่า 5 Axis (Utilization, Yield, Jobs, Throughput, LoadingTime) ตรงกับ KPI Card | P2 | M |
| TC-011-04 | SP sp_GetBayPerformanceDashboard | Seed Data | 1) EXEC SP | ได้ Result Set แต่ละ Bay พร้อม KPI ครบ | P1 | D |

**SQL สำหรับ TC-011:**
```sql
-- ตรวจ Bay KPI
SELECT WorkDate, BayName, TotalJobs, TotalActualTon,
       AvgLoadingMin, BayYieldPct, ThroughputTonPerHour
FROM ana.vw_BayPerformance
WHERE WorkDate >= '2026-05-01'
ORDER BY WorkDate, BayName

-- คำนวณ Utilization
-- HoursPerDay ดึงจาก AnalyticsConfig Key = 'HoursPerDay'
EXEC ana.sp_GetBayPerformanceDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'
```

---

### TC-012: Truck Turnaround

**วัตถุประสงค์:** ทดสอบการคำนวณเวลา Turnaround ของรถ

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-012-01 | คำนวณ TotalTurnaroundMinutes | Job ที่มี BayLog ครบ (TRUCK_ARRIVED และ TRUCK_DEPARTED) | 1) Query vw_TruckTurnaround | TurnaroundTime = DepartureTime - ArrivalTime (minutes) | P1 | D |
| TC-012-02 | Turnaround > 120 นาที → Flag | มี Job ที่ใช้เวลา > 120 นาที | 1) ดู Dashboard Turnaround 2) ตรวจ Table | Job ที่ Turnaround > 120 นาที แสดง Flag สีแดง/Warning | P2 | M |
| TC-012-03 | Breakdown ครบทุก Phase | มี Job ที่มีข้อมูล Queue + Loading + Checklist | 1) ดู Stacked Bar Chart | แสดง Queue Wait + Loading Time + Checklist Time = Total | P2 | M |
| TC-012-04 | SP sp_GetTurnaroundDashboard | Seed Data | 1) EXEC SP 2) ตรวจผลลัพธ์ | ได้ AvgTurnaroundMin, MinTurnaroundMin, MaxTurnaroundMin, JobsOver120 | P1 | D |

**SQL สำหรับ TC-012:**
```sql
SELECT * FROM ana.vw_TruckTurnaround
WHERE WorkDate >= '2026-05-01'
ORDER BY TurnaroundTimeMin DESC

EXEC ana.sp_GetTurnaroundDashboard
  @DateFrom = '2026-05-01',
  @DateTo   = '2026-05-14'
```

---

### TC-013: Notification

**วัตถุประสงค์:** ทดสอบระบบแจ้งเตือนและ Real-time Badge

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-013-01 | แจ้งเตือนเมื่อ Stock ต่ำกว่า MinStock | Stock ลดต่ำกว่า MinStock | 1) Adjust Inventory ให้ต่ำกว่า MinStock | มี NotificationLog สร้าง, Notification Bell Badge เพิ่มจำนวน, แสดงใน Notification Panel | P2 | E |
| TC-013-02 | แจ้งเตือนเมื่อ Device Offline | Device ไม่ส่ง Heartbeat | 1) หยุด Simulation Device 2) รอ Health Check | มี NotificationLog (type=DEVICE_OFFLINE), Bell Badge อัปเดต Real-time | P2 | E |
| TC-013-03 | แจ้งเตือนเมื่อ Yield ต่ำกว่า Threshold | Job Yield < 98% | 1) Job Complete ที่มี Yield ต่ำ | มี NotificationLog (type=LOSS_ALERT), ปรากฏใน Notification Panel | P2 | E |
| TC-013-04 | Mark as Read → Unread count ลด | มี Notification ที่ Unread | 1) คลิก Notification Bell 2) คลิก Mark as Read บนรายการ | Unread count ลดลง 1, รายการนั้นเปลี่ยนสถานะเป็น Read | P2 | E |
| TC-013-05 | Notification Bell Badge อัปเดต Real-time | มี Browser เปิดอยู่ 2 หน้าต่าง | 1) สร้าง Notification จาก Browser 1 2) สังเกต Browser 2 | Bell Badge บน Browser 2 อัปเดตเพิ่มจำนวนทันที | P2 | E |

---

### TC-014: Report Export

**วัตถุประสงค์:** ทดสอบการดาวน์โหลด Report ในรูปแบบต่างๆ

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-014-01 | ดาวน์โหลด Daily Summary Excel | มีข้อมูลวันที่เลือก | 1) ไปหน้า Report 2) เลือก Date Range 3) คลิก "Export Excel" | ไฟล์ .xlsx ถูก Download, เปิดได้, มีข้อมูลครบ Header + Rows | P3 | E |
| TC-014-02 | ดาวน์โหลด Loss/Yield PDF | มีข้อมูล Loss/Yield | 1) ไปหน้า Loss/Yield Dashboard 2) คลิก "Export PDF" | ไฟล์ .pdf ถูก Download, แสดงรายงาน Loss/Yield พร้อม Chart | P3 | E |
| TC-014-03 | กรองด้วย Date Range ก่อน Export | มีข้อมูลหลายวัน | 1) เลือก DateFrom = 2026-05-01, DateTo = 2026-05-07 2) Export Excel | ไฟล์ Excel มีเฉพาะข้อมูล 1-7 พฤษภาคม เท่านั้น | P3 | E |
| TC-014-04 | ข้อมูล Report ตรงกับ Dashboard | ดู Dashboard แล้ว Export | 1) บันทึกค่า KPI จาก Dashboard 2) Export Excel 3) เปรียบเทียบ | ตัวเลขใน Excel ตรงกับค่าที่แสดงบน Dashboard | P2 | M |

---

## ส่วนที่ 3: Error Handling Test Cases (TC-015)

### TC-015: Error Handling

**วัตถุประสงค์:** ทดสอบการจัดการ Error ที่ชัดเจนและปลอดภัย

| TC-ID | Test Case Name | Precondition | Steps | Expected Result | Priority | Type |
|-------|----------------|-------------|-------|-----------------|----------|------|
| TC-015-01 | JWT Token หมดอายุ → Redirect /login | มี Token ที่หมดอายุ | 1) ใช้ Expired Token 2) เรียก API ใดก็ได้ | API Response: 401 Unauthorized, Frontend Redirect ไปหน้า /login | P1 | E |
| TC-015-02 | API ล่ม → แสดง Error State ไม่ Crash | Backend ไม่ตอบสนอง | 1) ปิด Backend 2) เปิดหน้า Dashboard | หน้าแสดง Error State (ข้อความ "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์") ไม่ Crash หรือ White Screen | P1 | M |
| TC-015-03 | Input ผิด Format (เช่น LicensePlate ว่าง) | ฟอร์มสร้างรถ | 1) ส่งฟอร์มโดยไม่กรอก LicensePlate | แสดง Validation Error ข้างใต้ Field ที่ผิด, ไม่ส่ง API | P1 | M |
| TC-015-04 | Network Timeout → Retry / Error Message | Network ช้ามาก | 1) Throttle Network เป็น Slow 3G 2) เรียก API ที่ใช้เวลานาน | แสดง Loading Spinner, ถ้า Timeout แสดง "การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่" | P2 | M |
| TC-015-05 | Unauthorized Access (VIEWER DELETE) | Login เป็น VIEWER | 1) POST/DELETE API ที่ต้องการ ADMIN | 403 Forbidden, ข้อความ "คุณไม่มีสิทธิ์ดำเนินการนี้" | P1 | A |
| TC-015-06 | OPERATOR พยายาม Release Gate | Login เป็น OPERATOR | 1) POST /api/loading/jobs/{id}/complete | 403 Forbidden | P1 | A |
| TC-015-07 | ข้อมูล DB Null → ไม่ Crash | บาง Column เป็น NULL | 1) เรียก API ที่มีข้อมูล NULL | API Response 200, Frontend แสดง N/A หรือ "-" แทน NULL ไม่ Crash | P2 | A |

---

## ส่วนที่ 4: Regression Test Checklist (TC-016)

### TC-016: Regression Test ทุก Sprint

**วัตถุประสงค์:** ตรวจสอบ Core Flow ยังทำงานได้หลังทุก Patch/Update

#### Core Flow Regression Checklist:

| # | Test Item | Pass ✓ | Fail ✗ | หมายเหตุ |
|---|-----------|--------|--------|---------|
| 1 | Login ด้วย Username/Password → ได้ JWT Token | | | |
| 2 | Login ผิด Password → 401 Unauthorized | | | |
| 3 | สร้าง Order → Status = PENDING | | | |
| 4 | Confirm Order → สร้าง Queue → Status = WAITING | | | |
| 5 | เรียกรถ (Call) → Queue.Status = CALLED, Bay.Status = CALLING | | | |
| 6 | QR Generate → ได้ QR Image | | | |
| 7 | QR Scan → Valid → ผ่าน | | | |
| 8 | Start Loading → Job.Status = LOADING | | | |
| 9 | Loading Complete → หน้า Double Check เปิด | | | |
| 10 | Double Check ครบ → Release → Job.Status = COMPLETED | | | |
| 11 | Inventory ถูก Deduct หลัง Job Complete | | | |
| 12 | Dashboard แสดงข้อมูลถูกต้องหลัง Patch | | | |
| 13 | TV Display ยังทำงานหลัง Update | | | |
| 14 | SignalR ยัง Broadcast ได้หลัง Restart Backend | | | |
| 15 | Auth ยังทำงานหลังเปลี่ยน JWT Config | | | |
| 16 | KPI Card Yield% แสดงถูกต้อง | | | |
| 17 | Export Excel ยังดาวน์โหลดได้ | | | |

**วิธีใช้:** ทำ Checklist นี้หลังทุก Sprint/Release ก่อน Deploy Production

---

## ส่วนที่ 5: วิธีรัน Test

### 5.1 Setup Test Environment

```bash
# Step 1: ติดตั้ง SQL Server และสร้าง Database
# รัน Script ตามลำดับ:
# db/001_create_database.sql
# db/002_create_tables.sql
# db/003_create_analytics_objects.sql  ← รวม Seed Data Section 6

# Step 2: ตั้งค่า Backend
cd src/slb-backend
# แก้ appsettings.Development.json:
# ConnectionStrings.DefaultConnection = "Server=.;Database=SmartLoadBulkDB;..."
# JwtSettings.Secret = "your-secret-key"
# HardwareMode = "Simulation"   ← สำคัญ! ใช้ Simulation ใน Test

dotnet run

# Step 3: ตั้งค่า Frontend
cd src/slb-frontend
npm install
npm run dev
# เปิด http://localhost:5173
```

---

### 5.2 Load Test Data

```sql
-- รัน Seed Data จาก db/003 Section 6
-- หรือรัน Script ด้านล่างเพื่อตรวจว่า Seed Data ครบ

SELECT COUNT(*) AS SeedJobs
FROM slb.LoadJobs
WHERE JobCode LIKE 'ANA-TEST-%'
-- Expected: 12 rows

SELECT * FROM slb.LoadJobs
WHERE JobCode LIKE 'ANA-TEST-%'
ORDER BY JobCode
```

---

### 5.3 Manual Testing Steps

**สำหรับ E2E Test:**

1. เปิด Browser ไปที่ `http://localhost:5173`
2. Login ด้วย Account ที่เหมาะกับ TC นั้นๆ (ดูตาราง User ในข้อ 1.4)
3. ทำตาม Steps ที่ระบุใน Test Case แต่ละ TC
4. บันทึกผลใน Pass/Fail Column
5. ถ้า Fail ให้ Screenshot และบันทึก Error Message

---

### 5.4 API Testing ด้วย Swagger UI

```
URL: http://localhost:5000/swagger
หรือ: http://localhost:5001/swagger (HTTPS)
```

**ขั้นตอน:**
1. เปิด Swagger UI
2. คลิก "Authorize" → กรอก Bearer Token ที่ได้จาก Login
3. ค้นหา Endpoint ที่ต้องการ Test
4. กรอก Parameters / Body ตาม TC
5. คลิก "Execute" และดู Response

**ตัวอย่าง Login ด้วย Swagger:**
```json
POST /api/auth/login
{
  "username": "supervisor01",
  "password": "Test@1234"
}
Response: { "token": "eyJ..." }
```

---

### 5.5 Database Verification (SSMS)

สำหรับ TC ที่ Type = DB ให้รัน SQL Query ใน SSMS:

1. เชื่อมต่อ SQL Server → SmartLoadBulkDB
2. รัน Query ที่ระบุใน Test Case
3. เปรียบเทียบผลกับ Expected Result

---

## สรุป Test Coverage

| Module | จำนวน TC | Priority หลัก | Type หลัก |
|--------|----------|--------------|-----------|
| Truck Register | 9 TC | P2 | E |
| Queue Generate | 6 TC | P1 | E |
| Truck Calling | 6 TC | P1 | E |
| QR Verification | 7 TC | P1 | A |
| Double Check | 8 TC | P1 | E |
| Inventory | 7 TC | P2 | E |
| SignalR Realtime | 4 TC | P1 | E |
| Hardware Status | 5 TC | P2 | E |
| Performance Analytics | 7 TC | P1 | A/D |
| Loss/Yield | 7 TC | P1 | D |
| Bay Performance | 4 TC | P2 | D |
| Truck Turnaround | 4 TC | P1 | D |
| Notification | 5 TC | P2 | E |
| Report Export | 4 TC | P3 | E |
| Error Handling | 7 TC | P1 | A/M |
| Regression | 17 Items | P1 | E |
| **รวม** | **107 TC** | | |

---

*Test Plan V1.0 — Captain America (QA Agent) — 2026-05-14*  
*อ้างอิง: PROJECT_CONTEXT.md, FLOW_PROCESS.md V2.0, DATABASE_DESIGN.md*
