# NEXT STEPS — Smart Load Bulk

**อัปเดตล่าสุด:** 2026-05-19 (หลัง Session 11)  
**Phase ปัจจุบัน:** Phase 0–4 ✅ 100% | Phase 6 ✅ 100% | Phase 5 ⬜ 0% | Phase 7 ⬜ 0%

---

## ✅ เสร็จแล้ว (Session 7)

- QrService + QRCoder PNG จริง ✅
- SignalR ILoadingEventPublisher + push events ✅
- Frontend useLoadingHub / useQueueHub hooks ✅
- ChecklistService (RecordWeight, TickItem, ReleaseGate) ✅

---

## ✅ Phase 6 Analytics SP Integration — เสร็จแล้ว (Session 8)

- AnalyticsDtos.cs — rewrite ตาม SP output columns จริง ✅
- AnalyticsService.cs — raw ADO.NET reader, 4 SPs, 6 methods ✅
- แก้ vite.config.ts proxy port 5000 → 5215 (bug สำคัญ) ✅
- อัปเดต Frontend types/index.ts + 4 Analytics pages ✅
- ทดสอบผ่านทุก endpoint: performance / loss-yield / bay / turnaround ✅

---

## ✅ Dark Theme Redesign — เสร็จสมบูรณ์ 100% (Session 9–11)

ทุกหน้าเป็น dark theme แล้ว รวมถึง Analytics 4 หน้า (chart grids + purple + borders)

---

## ✅ Phase 4 SignalR — เสร็จสมบูรณ์ 100% (Session 10)

LoadingHub / QueueHub / InventoryHub + reconnect backoff ครบแล้ว

---

## Priority 1 — Phase 7 UAT / Go-Live (ถัดไป!)

E2E test flow ครบทั้งระบบ:
1. Login → Dashboard
2. สร้าง Order → เพิ่มเข้า Queue
3. Call Truck → Dock → เริ่ม Load → Complete
4. QR Generate → Scan → Validate
5. Checklist: RecordWeight → TickItems ครบ → Release
6. Analytics: ตรวจสอบ Performance / Loss-Yield / Bay / Turnaround มีข้อมูลจริง

---

## Priority 2 — Phase 5 Hardware Integration

- `HardwareService` ยังเป็น stub ทั้งหมด
- ต้องรู้ Hardware protocol จริงก่อน (PLC? Modbus? Serial?)
- งาน PLC ต้องมี Simulation/Dry-run ก่อนเสมอ

---

## Priority 4 — UAT / Go-Live Prep

- ทดสอบ E2E flow ตั้งแต่ Login → Order → Queue → Bay → Load → Check → Release
- Performance test บน production data
- Deploy script + environment config

---

## ข้อควรระวัง (เรียนรู้จาก Session 5–7)

| ข้อ | รายละเอียด |
|-----|-----------|
| Launch Profile | ต้องรัน `--launch-profile http` เสมอ |
| SQL Server 2014 | ไม่รองรับ `CREATE OR ALTER` |
| sqlcmd encoding | ต้องใส่ `-f 65001` เสมอ เมื่อ script มีภาษาไทย |
| DB CHECK constraints | ตรวจ allowed Status values ก่อนเขียน code เสมอ |
| Entity vs DB | ตรวจ columns ใน DB จริงก่อน map entity ทุกครั้ง |
| QrToken | ไม่มี TokenType column ใน DB — เป็นแค่ DTO field |
| LoadChecklist | ไม่มี Status column และ ChecklistItems table ไม่มีใน DB |

---

## Progress

```
Phase 0 — Project Init        ✅ 100%
Phase 1 — DB / Architecture   ✅ 100%
Phase 2 — Bootstrap           ✅ 100%
Phase 3 — Core Modules        ✅ 100%  (Loading + QR + Checklist ✅)
Phase 4 — SignalR              ✅ 100%  (LoadingHub ✅ QueueHub ✅ InventoryHub ✅)
Phase 5 — Hardware              ⬜   0%
Phase 6 — Analytics Coding     ✅ 100%  (SP ✅ / Frontend ✅ / Dark UI ✅)
Phase 7 — UAT / Go-Live        ⬜   0%
```
