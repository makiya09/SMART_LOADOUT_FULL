# NEXT STEPS — Smart Load Bulk

**อัปเดตล่าสุด:** 2026-05-18 (หลัง Session 9)  
**Phase ปัจจุบัน:** Phase 3 ✅ 100% | Phase 4 SignalR 70% | Phase 6 Analytics 90% | Dark UI 🔵 60%

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

## Priority 1 — Dark Theme Redesign (Session 9 กำลังทำ) 🔵

**อ้างอิง:** `docs/feed_loading_system.html`

**เสร็จแล้ว:**
- `index.css` — IBM Plex Sans Thai/Mono, CSS variables dark industrial ✅
- `AppShell.tsx` — dark bg ✅
- `Sidebar.tsx` — gradient logo, nav sections, left-border active ✅
- `TopBar.tsx` — dark + live dot + real-time clock ✅
- `KpiCard.tsx` — stat-card style (2px top border, mono font, neon colors) ✅

**ต้องทำต่อ (เรียงลำดับ):**
1. `PageHeader.tsx` — dark industrial style
2. `BayStatusCard.tsx` — dark bay card
3. `DashboardPage.tsx` — ปรับ layout + dark components ครบ
4. `OrdersPage.tsx` — ปรับ table dark
5. `LoginPage.tsx` — ปรับ login form dark industrial

---

## Priority 2 — Phase 4 SignalR (30% ที่เหลือ)

ส่วนที่ยังไม่ได้ทำ:
- `useQueueHub` ใน `OrdersPage` / `DashboardPage` — auto-refresh queue board
- InventoryHub push เมื่อ stock เปลี่ยน
- ทดสอบ SignalR reconnect เมื่อ connection หลุด

---

## Priority 3 — Phase 5 Hardware Integration

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
Phase 4 — SignalR              🔵  70%  (Push events ✅ / QueueHub frontend ⬜)
Phase 5 — Hardware              ⬜   0%
Phase 6 — Analytics Coding     🟢  90%  (SP ✅ / Frontend ✅ / Dark UI 🔵 60%)
Phase 7 — UAT / Go-Live        ⬜   0%
```
