# PROJECT CONTEXT — Smart Load Bulk

**วันที่เริ่มต้น:** 2026-05-13  
**สถานะ:** Planning Phase  
**ทีม:** MAKIYA Marvel AI Team  
**ประเภทโปรเจค:** New Project / Smart Loadout / Bulk Loading / Industrial Dashboard

---

## 1. ภาพรวมระบบ

**Smart Load Bulk** คือระบบจัดการการโหลดสินค้าแบบ Bulk สำหรับโรงงานอาหารสัตว์หรือโรงงานอุตสาหกรรม  
ระบบครอบคลุมตั้งแต่การบริหาร Inventory, การรับ Order, การจัดคิวรถบรรทุก, การเรียกรถเข้าโหลด, การยืนยันด้วย QR Code, การตรวจสอบซ้ำก่อนปล่อยรถออก และการเชื่อมต่อกับ Hardware ภายในโรงงาน

เป้าหมายหลักคือทำให้กระบวนการโหลดสินค้า **เร็วขึ้น, ตรวจสอบได้, ลดความผิดพลาด, ลด Loss/Yield ผิดปกติ และดูสถานะได้แบบ Real-time**

---

## 2. เป้าหมายหลักของระบบ

1. จัดการ Order และ Queue รถบรรทุกอย่างเป็นระบบ
2. แสดง Inventory / Demand / Supply / Balance ผ่าน Dashboard
3. ลดความผิดพลาดในการโหลดสินค้า เช่น รถผิดคิว, สินค้าผิด, Bay ผิด, น้ำหนักคลาดเคลื่อน
4. ใช้ QR Code เพื่อยืนยัน Job, รถ, Bay และขั้นตอนการโหลด
5. เพิ่ม Double Check ก่อนปล่อยรถออก
6. เชื่อมต่อ Hardware เช่น QR Scanner, Radar/Sensor, Loading Panel
7. มี Dashboard วัดประสิทธิภาพการโหลดและวิเคราะห์ Loss / Yield
8. รองรับ Report, Audit Log และการสรุปผลการทำงาน

---

## 3. Scope ระบบ

### In Scope

- Inventory Dashboard
- Order & Queue Management
- Truck Register
- Truck Calling
- Loading Job
- QR Code Verification
- Double Check Loading
- Hardware Integration
- Software Integration
- Performance Analytics
- Loss / Yield Dashboard
- Report / Export
- Audit Log
- Notification Log

### Out of Scope ระยะแรก

- การควบคุม PLC โดยตรงแบบ Live Write
- การเชื่อมต่อ ERP/SAP จริงแบบ Production
- AI Optimization ขั้นสูง
- Mobile App เต็มรูปแบบ

> ถ้าต้องเชื่อมต่อ PLC หรือระบบ Production จริง ต้องทำ Dry-run / Simulation ก่อนเสมอ

---

## 4. Module หลัก

| # | Module | คำอธิบาย | Priority | Agent หลัก |
|---|---|---|---|---|
| 1 | **Inventory Dashboard** | แสดงสถานะสินค้าคงคลัง Bulk, Demand, Supply, Balance | High | Hawkeye, Spider-Man, Shuri |
| 2 | **Order & Queue** | รับออเดอร์และจัดคิวรถบรรทุก | High | Doctor Strange, Iron Man |
| 3 | **Truck Calling & Loading** | เรียกรถ, กำหนด Bay, ควบคุมสถานะการโหลด | High | Doctor Strange, Iron Man |
| 4 | **Truck Register** | ลงทะเบียนรถบรรทุก, คนขับ, บริษัทขนส่ง | Medium | Iron Man |
| 5 | **QR Code for Loading** | สร้าง/สแกน QR เพื่อยืนยัน Job และขั้นตอนโหลด | High | Iron Man, Captain America |
| 6 | **Double Check Loading** | ตรวจสอบรถ, Order, Product, Bay, Weight ก่อนจบงาน | High | Captain America, Iron Man |
| 7 | **Software Integration** | เชื่อมต่อ ERP, WMS, Database, API ภายนอก | Medium | Doctor Strange, Shuri |
| 8 | **Hardware Integration** | QR Scanner, Radar/Sensor, Loading Panel, Device Status | Medium | Doctor Strange, Iron Man |
| 9 | **Performance Analytics** | วิเคราะห์ประสิทธิภาพการโหลด, Turnaround Time, Bay Utilization | High | Hawkeye |
| 10 | **Loss / Yield Monitoring** | วิเคราะห์ Target vs Actual, Loss, Over, Yield, Loading Accuracy | High | Hawkeye, Shuri, Spider-Man |

---

## 5. Flow การทำงานหลัก

```text
Order / Load Plan
      ↓
Truck Register
      ↓
Queue Generate
      ↓
Truck Calling
      ↓
Assign Loading Bay
      ↓
QR Scan / Verify Job
      ↓
Start Loading
      ↓
Actual Weight / Loading Result
      ↓
Double Check Loading
      ↓
Inventory Transaction
      ↓
Performance / Loss-Yield Analysis
      ↓
Report / Dashboard / Notification
```

---

## 6. UI/UX Requirements

### Style

- Modern Industrial Dashboard
- ดูสบายตา
- ใช้งานง่ายสำหรับ Operator และ Supervisor
- เหมาะกับสภาพแวดล้อมโรงงาน
- ข้อมูลสำคัญต้องเห็นชัดใน 3–5 วินาที

### Device Support

- Desktop
- Tablet
- Industrial Monitor
- TV Display สำหรับ Truck Calling Board
- Touch Screen
- Barcode / QR Scanner Input

### Visual Guideline

| Item | แนวทาง |
|---|---|
| Background | สีอ่อน สบายตา หรือ Dark Mode สำหรับจอโรงงาน |
| Primary Color | Green / Blue |
| Warning | Amber / Orange |
| Danger | Red |
| Success | Green |
| Table | อ่านง่าย ไม่แน่นเกินไป |
| Font | ขนาดใหญ่พอสำหรับอ่านระยะไกล |
| Status | ใช้ Badge / Pill / Icon ชัดเจน |

### หน้าจอหลักที่ต้องมี

1. Main Dashboard
2. Inventory Dashboard
3. Queue Management
4. Truck Register
5. Truck Calling Display
6. Loading Verification
7. Double Check Loading
8. Hardware Monitor
9. Performance Dashboard
10. Loss / Yield Dashboard
11. Report Page
12. Setting Page

---

## 7. Performance Analytics Requirement

ระบบต้องมี Module สำหรับวิเคราะห์ประสิทธิภาพการโหลดอาหาร โดยใช้ชื่อ:

```text
Loading Performance Analytics / Loss-Yield Monitoring
```

### เป้าหมาย

- วัดประสิทธิภาพการโหลดอาหาร
- เปรียบเทียบ Target Weight กับ Actual Weight
- วิเคราะห์ Loss / Over / Yield
- วิเคราะห์ Truck Turnaround Time
- วิเคราะห์ Queue Waiting Time
- วิเคราะห์ Loading Bay Performance
- วิเคราะห์ Product / Formula ที่มี Loss สูง
- แสดงผลผ่าน Dashboard ที่ดูง่ายและทันสมัย

### KPI หลักที่ต้องรองรับ

| KPI | คำอธิบาย |
|---|---|
| Total Trucks | จำนวนรถทั้งหมด |
| Completed Trucks | จำนวนรถที่โหลดเสร็จ |
| Waiting Queue | จำนวนรถที่รอโหลด |
| Loading Now | จำนวนรถที่กำลังโหลด |
| Total Target Weight | น้ำหนักเป้าหมายรวม |
| Total Actual Weight | น้ำหนักโหลดจริงรวม |
| Diff Kg | Actual - Target |
| Diff % | เปอร์เซ็นต์ความต่าง |
| Loss Kg | น้ำหนักที่ขาดจาก Target |
| Over Kg | น้ำหนักที่เกินจาก Target |
| Yield % | Actual / Target × 100 |
| Loading Accuracy % | ความแม่นยำการโหลด |
| Average Loading Time | เวลาโหลดเฉลี่ย |
| Average Waiting Time | เวลารอเฉลี่ย |
| Truck Turnaround Time | เวลาตั้งแต่รถเข้า-ออก |
| Throughput Ton/Hour | ปริมาณโหลดต่อชั่วโมง |
| Bay Utilization % | อัตราการใช้งาน Bay |

### สูตรคำนวณเบื้องต้น

```text
Diff Kg = Actual Weight - Target Weight
Diff % = ((Actual Weight - Target Weight) / Target Weight) × 100
Yield % = (Actual Weight / Target Weight) × 100
Loss Kg = Target Weight - Actual Weight เมื่อ Actual < Target
Over Kg = Actual Weight - Target Weight เมื่อ Actual > Target
Loading Duration = Loading End Time - Loading Start Time
Truck Turnaround Time = Exit Time - Register Time
Throughput Ton/Hour = Actual Weight Ton / Loading Duration Hour
```

### Dashboard ที่ต้องมี

1. Performance Overview Dashboard
2. Loss / Yield Dashboard
3. Bay Performance Dashboard
4. Truck Turnaround Dashboard
5. Product Loss Analysis Dashboard

### Agent ที่เกี่ยวข้อง

| Agent | หน้าที่ |
|---|---|
| Hawkeye | ออกแบบ KPI, สูตรคำนวณ, Dashboard Metric |
| Shuri | ออกแบบ View / Stored Procedure / Database สำหรับ Analytics |
| Spider-Man | ออกแบบ UI/UX Dashboard |
| Iron Man | เขียน Backend API และ Frontend |
| Captain America | ทดสอบ KPI และ Dashboard |
| Vision | ทำคู่มือและสรุปการใช้งาน Dashboard |

---

## 8. Hardware Integration

| Hardware | การใช้งาน | Priority | หมายเหตุ |
|---|---|---|---|
| **QR Scanner** | สแกน QR ยืนยัน Job โหลด, รถ, Bay | High | ควรรองรับ Keyboard Wedge / Serial / USB |
| **Radar / Sensor** | ตรวจจับตำแหน่งรถที่จอดเข้า Bay | Medium | ใช้ตรวจว่าเข้า Bay ถูกต้องหรือไม่ |
| **Loading Panel** | แผงควบคุมการโหลด Start/Stop/Emergency | Medium | ระยะแรกควรทำแบบ Dry-run |
| **Industrial Monitor / TV** | แสดง Truck Calling Display | High | ต้องใช้ Font ใหญ่และ Layout ชัดเจน |
| **Scale / Weight System** | อ่านน้ำหนัก Target / Actual | High | ใช้สำหรับ Loss/Yield |

---

## 9. Software Integration

### เป้าหมายการเชื่อมต่อ

- ERP / SAP สำหรับ Order
- WMS สำหรับ Inventory
- SQL Server Database
- Notification Service เช่น LINE / Internal Notification
- Report / Export Service
- Hardware Middleware

### รูปแบบ Integration ที่ควรรองรับ

| Integration | แนวทาง |
|---|---|
| ERP / SAP | API / DB View / Import File |
| WMS | API / DB View / Stored Procedure |
| Hardware | TCP/IP / Serial / REST API / Middleware |
| Notification | LINE Messaging API / Internal API |
| Report | PDF / Excel / Dashboard |

---

## 10. Technology Stack ที่แนะนำ

| Layer | Recommended |
|---|---|
| Frontend | React + TypeScript |
| UI Framework | Tailwind CSS หรือ Material UI |
| Backend | ASP.NET Core 8 Web API |
| Realtime | SignalR |
| Database | SQL Server |
| Report / Export | Excel / PDF Export |
| Hardware Middleware | Windows Service หรือ Worker Service |
| Authentication | JWT / Role-based Permission |
| Logging | Serilog หรือ Application Log Table |

> Technology Stack นี้เป็นข้อเสนอเริ่มต้น สามารถปรับตามข้อจำกัดของโรงงานและระบบเดิมได้

---

## 11. Database Concept เบื้องต้น

กลุ่ม Table ที่ควรมี:

```text
loadout_order_h
loadout_order_d
truck_register
truck_queue
loading_job
loading_verify_log
inventory_balance
inventory_transaction
hardware_device
notification_log
audit_log
```

สำหรับ Performance Analytics แนะนำแยก schema:

```text
ana
```

ตัวอย่าง View / Stored Procedure:

```text
ana.v_LoadingPerformanceJob
ana.v_LoadingPerformanceDaily
ana.v_LoadingLossYield
ana.v_LoadingBayPerformance
ana.v_TruckTurnaround
ana.SP_Performance_Dashboard_Get
ana.SP_LossYield_Dashboard_Get
```

---

## 12. Marvel AI Team Workflow

1. **Nick Fury** อ่านสถานะโปรเจคและ Next Steps
2. **Black Widow** วิเคราะห์ระบบเดิม / หาไฟล์ / อ่านโค้ด
3. **Doctor Strange** ออกแบบ Architecture และ Flow Process
4. **Hawkeye** ออกแบบ KPI, Loss/Yield, Performance Analytics
5. **Shuri** ออกแบบ Database, View, Stored Procedure
6. **Spider-Man** ออกแบบ UI/UX Dashboard
7. **Iron Man** เขียน Backend API / Frontend
8. **Captain America** ทำ Test Plan และ Regression Test
9. **Vision** ทำคู่มือ / เอกสาร / Presentation
10. **Nick Fury** สรุป Handoff ก่อนปิดเครื่อง

---

## 13. ทีมงาน Marvel AI

| Agent | หน้าที่ในโปรเจคนี้ |
|---|---|
| **Nick Fury** | Project Memory, Handoff, Next Steps, จำสถานะงาน |
| **Black Widow** | วิเคราะห์ระบบที่มีอยู่, หาไฟล์ที่เกี่ยวข้อง |
| **Doctor Strange** | ออกแบบ Architecture, Flow Process, Module Design |
| **Hawkeye** | ออกแบบ KPI, Performance Analytics, Loss/Yield, Dashboard Metric |
| **Shuri** | SQL, Stored Procedure, Database Design, Analytics View |
| **Spider-Man** | UI/UX Designer, Frontend Layout, Dashboard, Modern Web UI |
| **Iron Man** | เขียน Code Frontend/Backend, API, Integration |
| **Captain America** | Test Case, QA, Regression Test, Production Risk |
| **Vision** | Documentation, คู่มือ, Changelog, Presentation |

---

## 14. Phase การพัฒนา

### Phase 1: Planning & Design

- สรุป Requirement
- ออกแบบ Flow Process
- ออกแบบ Architecture
- ออกแบบ UI/UX Concept
- ออกแบบ Database Concept

### Phase 2: MVP Dashboard + Queue

- Main Dashboard
- Truck Register
- Queue Management
- Truck Calling Display
- Mock Inventory

### Phase 3: Loading Verification

- QR Code Verification
- Confirm Loading
- Double Check Loading
- Loading Job Status

### Phase 4: Inventory + Performance Analytics

- Inventory Transaction
- Demand / Supply / Balance
- Performance Dashboard
- Loss / Yield Dashboard

### Phase 5: Hardware Integration

- QR Scanner
- Radar / Sensor
- Loading Panel
- Device Status Monitor

### Phase 6: Report + Notification

- Loading Report
- Inventory Report
- Loss/Yield Report
- LINE / Internal Notification
- Export Excel / PDF

### Phase 7: Testing + Documentation

- Functional Test
- Integration Test
- Performance Test
- User Manual
- Admin Manual
- Presentation / Demo Script

---

## 15. Safety Rules

- ห้ามเชื่อมต่อ Production Hardware แบบสั่งงานจริงใน Phase แรก
- ห้ามเขียน PLC / Loading Panel Command จริงโดยไม่มี Dry-run
- ห้าม UPDATE / DELETE Production Database โดยไม่มี SELECT Preview
- Hardware Integration ต้องมี Simulation Mode
- QR Verification ต้องมี Audit Log
- Loading Completion ต้องมี Double Check
- Loss/Yield ต้องระบุสูตรและ Threshold ชัดเจน
- ทุก Module ต้องมี Test Plan
- ถ้าไม่มั่นใจ ให้ Agent ระบุว่า “ต้องตรวจสอบเพิ่มเติม” ห้ามเดา

---

## 16. Current Status

```text
Status: Planning Phase
Next Recommended Agent: Doctor Strange
Next Recommended Task: ออกแบบ System Architecture และ Flow Process
```

---

## 17. Prompt ถัดไปที่แนะนำ

```text
ให้ Doctor Strange อ่าน docs/PROJECT_CONTEXT.md

ช่วยออกแบบระบบ Smart Load Bulk โดยละเอียด

ขอผลลัพธ์:
1. Architecture ภาพรวม
2. Flow Process Diagram
3. Module หลัก
4. หน้าจอที่ต้องมี
5. API ที่ต้องมี
6. Database หลักที่ควรมี
7. Realtime Event ที่ควรมี
8. Hardware Integration Flow
9. Phase การพัฒนา
10. Risk

ให้บันทึกไว้ที่:
docs/SYSTEM_ARCHITECTURE.md
docs/FLOW_PROCESS.md
docs/MIGRATION_PLAN.md
```
