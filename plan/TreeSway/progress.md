# Tree Sway — Progress / Handoff

> **สถานะรวม:** prototype ต้นเดียว (`Bigtree 5`) เสร็จในโค้ด · ยังไม่ commit · ยังไม่ live-test · ขยายหลายต้น: พักไว้
> **อัปเดตล่าสุด:** 2026-09-23 · **คนล่าสุด:** rif (ร่วมกับ Claude Code)

## 2026-09-23 · rif (ร่วมกับ Claude Code)

- **ทำอะไร:** ต้นไม้แกว่งตามลมใน VO (PixiJS) — ใบแกว่ง ลำต้นเอนนิดหน่อย โคนนิ่ง · ขยับแบบ pixel (step ทีละ pixel, 8 fps) · ความแรงตาม `wind_kph`/`gust_kph` ของ office (ไม่มีข้อมูล → แกว่งเบา default) · รายละเอียดทั้งหมดใน [`plan.md`](plan.md)
- **ถึงไหน:** โค้ดครบบน `zyra-app@feat/tree-sway` (แตกจาก `develop` ล่าสุด) — **ยังไม่ commit/push** · ใช้กับ object ชื่อ `Bigtree 5` ต้นเดียว (hardcode `TREE_SWAY_NAME_RE` ใน `zyra-engine/pixi-game/scene.ts`)
- **PR:** — (ยังไม่เปิด)
- **verify ถึงไหน:** `vitest __tests__/tree-wind.test.ts` 9/9 ผ่าน · tsc + eslint ผ่านทุกไฟล์ที่แก้ · `git diff --check` ผ่าน · repro ใน headless Chromium (Metal) ด้วย pixi เวอร์ชันเดียวกัน: ลำต้นโคนนิ่ง, ใบเลื่อนเป็นขั้น pixel, ระยะแกว่งขึ้นตาม strength · **ยังไม่ได้ live-test ในแอปจริงหลังเปลี่ยนเป็น mesh** (รอบ filter ก่อนหน้า live-test แล้วเจอรูปกลับหัว — ดู plan.md §5)
- **ต่อจากนี้:** ทำตาม [plan.md §6.1](plan.md#61-ปิดงาน-prototype-นี้-ทำก่อน) — live-test → เช็คชื่อใน DB → จูน `cutoff` → commit + PR เข้า `develop`
- **ติดอะไร:** — (ส่วนขยายหลายต้น §6.2 รอตัดสินใจ/เขียน spec ก่อน ไม่ใช่ blocker ของ prototype)
