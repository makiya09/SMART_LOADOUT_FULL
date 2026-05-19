# DECISION LOG — Smart Load Bulk

**สร้างโดย:** Nick Fury  
**วันที่เริ่มต้น:** 2026-05-13

บันทึกการตัดสินใจสำคัญเรื่อง Architecture, Database, Technology และ Design

---

## 2026-05-13

### [DEC-001] Technology Stack
**ตัดสินใจโดย:** Developer  
**วันที่:** 2026-05-13  
**สถานะ:** ✅ ตัดสินใจแล้ว

| Layer | การตัดสินใจ | เหตุผล |
|-------|------------|--------|
| Frontend | React + TypeScript (Vite) | Modern, Component-based, TypeScript ช่วยลด Bug |
| UI Library | Tailwind CSS + shadcn/ui | Utility-first, ปรับแต่งง่าย, มี Component พร้อม |
| State | Zustand | เบากว่า Redux, ง่ายกว่าสำหรับทีม |
| Backend | ASP.NET Core 8 Web API | .NET 8 LTS, Performance ดี, รองรับ SignalR |
| Realtime | SignalR (Built-in) | เชื่อมต่อ WebSocket ง่าย, รองรับ Fallback |
| ORM | Entity Framework Core 8 | Code First, Migration ง่าย |
| Database | SQL Server 2019+ | ทีมคุ้นเคย, เหมาะกับ Enterprise |
| Auth | JWT Bearer Token | Stateless, รองรับ Role-based |
| Hardware | Gateway Background Service | แยก Service เพื่อ Isolation |

---

### [DEC-002] Database Schema Design
**ตัดสินใจโดย:** Shuri  
**วันที่:** 2026-05-13  
**สถานะ:** ✅ ตัดสินใจแล้ว

| หัวข้อ | การตัดสินใจ | เหตุผล |
|--------|------------|--------|
| Schema Name | `slb` (SmartLoadBulk) | แยก Namespace ชัดเจน |
| Primary Key | UNIQUEIDENTIFIER + NEWSEQUENTIALID() | ลด Index Fragmentation vs NEWID() |
| Log Tables PK | BIGINT IDENTITY | Performance ดีกว่า GUID สำหรับ Time-series |
| Table จำนวน | 23 Tables | ครอบคลุมทุก Domain |
| Soft Delete | ใช้ IsActive แทน DELETE | กัน Data Loss, รองรับ Audit |
| Analytics Schema | `ana` | แยก OLTP กับ OLAP ชัดเจน (ยังไม่ได้สร้าง) |

---

### [DEC-003] UI/UX Theme
**ตัดสินใจโดย:** Spider-Man  
**วันที่:** 2026-05-13  
**สถานะ:** ✅ ตัดสินใจแล้ว

| หัวข้อ | การตัดสินใจ | เหตุผล |
|--------|------------|--------|
| Mode | Light Mode | ใช้กลางวัน ไม่ล้าตา |
| Primary Color | Blue #2563EB + Green #16A34A | อ่านง่าย สบายตา เป็นมืออาชีพ |
| Font | Inter | Readability ดี โดยเฉพาะตัวเลข |
| Layout | Sidebar + Content Area | Standard Dashboard Pattern |
| KPI Number Size | 48px Bold | อ่านได้จาก TV 1-2 เมตร |
| TV Mode | `/bay?display=tv` | หน้าจอโรงงาน ไม่มี Sidebar |
| Bay Card | 7 States, 7 สี | สถานะเปลี่ยนชัดเจนทันที |

---

### [DEC-004] Hardware Integration Pattern
**ตัดสินใจโดย:** Doctor Strange  
**วันที่:** 2026-05-13  
**สถานะ:** ✅ ตัดสินใจแล้ว

| หัวข้อ | การตัดสินใจ |
|--------|------------|
| Pattern | Gateway Background Service แยกจาก Main API |
| Protocol รองรับ | Serial, TCP, Modbus TCP, HID |
| Safety | ต้องมี Simulation Mode ก่อน Connect จริงเสมอ |
| Emergency Stop | 2-step Confirm (กันกด accident) |
| QR Token | Single-use JWT, Expire 8 ชั่วโมง, HMAC Signed |

---

### [DEC-005] Performance Analytics Scope
**ตัดสินใจโดย:** Developer (ผ่าน PROJECT_CONTEXT.md ที่อัปเดต)  
**วันที่:** 2026-05-13  
**สถานะ:** 🟡 ตัดสินใจแล้ว — รอ Hawkeye ออกแบบ

| หัวข้อ | การตัดสินใจ |
|--------|------------|
| รวมอยู่ใน Scope | ใช่ — เป็น Module 9 และ 10 |
| Schema | `ana` (แยกจาก `slb`) |
| KPI หลัก | 17 ตัว (Loss, Yield, Turnaround, Bay Utilization ฯลฯ) |
| Dashboard | 5 หน้า (Performance, Loss/Yield, Bay, Turnaround, Product Analysis) |
| Agent รับผิดชอบ | Hawkeye (ออกแบบ) + Shuri (DB) + Spider-Man (UI) |
| สถานะ | **ยังไม่ได้เริ่มออกแบบ** — เป็น Gap ที่ต้องทำ |

---

## Pending Decisions (ยังรอ)

| # | หัวข้อ | รอจาก | ผลกระทบ |
|---|--------|--------|---------|
| P01 | SQL Server Connection String จริง | Developer/IT | รัน Script ไม่ได้ |
| P02 | Bay ในโรงงานมีกี่ Bay ชื่ออะไร | Developer | Seed Data ไม่ครบ |
| P03 | ERP/WMS Integration (มีหรือไม่) | Developer | Scope Phase 5 |
| P04 | Hardware Spec (QR Scanner รุ่น/Protocol) | Developer/Vendor | Hardware Phase |
| P05 | Deploy Server: IP/OS/IIS Version | IT | Go-Live Phase |
| P06 | Timeline ต้องการเสร็จเมื่อไร | Developer | Priority ทุก Phase |
