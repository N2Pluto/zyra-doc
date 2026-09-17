# SC-OBJ-NAT-01 · Progress — Nature Object Management (Admin)

> entry ใหม่อยู่**บนสุด** · ClickUp main: [86d446fw1](https://app.clickup.com/t/86d446fw1) · **ยังเป็น planning only — ไม่มีโค้ด implement ในทุก repo**

---

## รอบที่ 3 — 2026-09-17

**ทำอะไร:** ดึง ClickUp ใหม่ทั้ง main + 9 subtask เทียบกับเอกสารรอบที่ 2 แล้ว sync เข้าเอกสาร + เขียน test plan

**ถึงไหน:**
- ClickUp เปลี่ยนแค่ **status `pending` → `in progress` ทั้ง 9 task** (HP-04 ยัง Closed/descoped) — **description ไม่เปลี่ยนแม้แต่ตัวเดียว และไม่มี comment ใหม่**
- อัปเดต [spec.md](spec.md): header blockquote, ตาราง Scenario Index (status ทุกแถว), เพิ่มหัวข้อ **§รอบที่ 3**
- อัปเดต header ของ [technical-design.md](technical-design.md) และ [ux-ui-plan.md](ux-ui-plan.md) ให้ระบุว่า open items ยังไม่ถูกตอบ
- เขียนใหม่: [test-plan.md](test-plan.md) — coverage target ตาม [04-test.md](../../../.claude/rules/04-test.md), unit Go/TS, handler, component, E2E, regression, manual QA checklist 18 ข้อ, traceability ต่อ scenario
- อัปเดตแถวของฟีเจอร์นี้ใน [plan/README.md](../README.md)

**PR:** ไม่มี (เอกสารอย่างเดียว ยังไม่แตะโค้ด)

**verify ถึงไหน:** เอกสารล้วน — **ไม่มีอะไรให้ build/test** · ข้อมูล ClickUp ยืนยันจาก API ตรง (main `date_updated` 1789616192905) · สถานะโค้ด ("ยังไม่มี `tb_object_animation` / ไม่มี `nature` ใน `validObjectTypes`") ยึดตามผลตรวจโค้ดรอบ 2026-09-16 **ยังไม่ได้ re-grep ซ้ำในรอบนี้**

**ต่อจากนี้:**
1. เอา [ux-ui-plan §14.1](ux-ui-plan.md#141-ต้องตัดสินก่อนเริ่มโค้ด-กระทบ-schema--api--flow) 12 ข้อไปถาม PM — โดยเฉพาะข้อ 1 (required states), 2 (ชื่อ state ที่ 3), 3 (frame config), 8 (status default), **14a (สี/ประเภท box ขัด always-walkable)** เพราะบล็อก migration
2. เริ่มงานที่ไม่ขึ้นกับคำตอบได้เลย: เพิ่ม `"nature"` เข้า object type enum + filter/badge, แตก validation เป็น pure function ใน `internal/model` (ไม่งั้นเทสตาม target 80% ไม่ได้ — ดู [test-plan §1.0](test-plan.md#10-ข้อจำกัดโครงสร้างที่ต้องแก้ก่อนเทสได้))
3. ขอ PM แก้ `petal_fall` → `falling` ในตาราง Nature Types ของ main task (ยังค้างจากรอบที่ 2)

**ติดอะไร:** ClickUp เปิดงานเป็น in progress แล้ว แต่ **spec ยังขัดกับ Figma 12 จุดที่กระทบ schema** — ถ้าเริ่ม migration ก่อนได้คำตอบ เสี่ยงต้องรื้อ `tb_object_animation` ทิ้ง

---

## รอบที่ 1–2 — 2026-09-16

**ทำอะไร:** ถอด spec จาก ClickUp ครบทุก subtask ([spec.md](spec.md)) · ออกแบบ schema/API/realtime จากโค้ดจริง ([technical-design.md](technical-design.md)) · ถอด Figma ครบ 8 section ([ux-ui-plan.md](ux-ui-plan.md)) · ดึง ClickUp ซ้ำหลัง PM แก้ แล้วบันทึกเป็น §รอบที่ 2

**ถึงไหน:** เอกสาร 3 ไฟล์ครบ · naming ยืนยัน `shedding_tree`/`falling` · HP-04 descoped · พบข้อขัดแย้ง Figma ↔ spec 35 จุด (12 จุดกระทบ schema/API/flow)

**PR:** ไม่มี · **verify:** เอกสารล้วน ยังไม่ implement · **ติดอะไร:** open questions ยังไม่ถูกตอบ
