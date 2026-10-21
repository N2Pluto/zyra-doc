# [Module] Avatar & Accessories Management (Admin) — Progress / Handoff

> **สถานะรวม:** Planning — ดึง ClickUp ครบ + แยก req + ยกตัวอย่าง upload flow จาก prototype แล้ว · ยังไม่ได้ตอบคำถามค้าง 14 ข้อ · ยังไม่ implement
> **อัปเดตล่าสุด:** 2026-10-21 · **คนล่าสุด:** Ten (ผ่าน Claude Code)

## 2026-10-21 · Ten (ผ่าน Claude Code)

- **ทำอะไร:** ดึง ClickUp task หลัก `86d43pbbj` + subtask 8 ใบ (description, status, priority, custom field, comment, attachment, checklist, dependency) มาเก็บเป็น [clickup-raw.md](clickup-raw.md) → เรียบเรียงเป็น [spec.md](spec.md) → แยกเป็น req 40 ข้อใน [requirements.md](requirements.md) พร้อมเทียบกับโค้ดเดิม (grep route / migration / ไฟล์ view) แบบผิวเผิน
- **ถึงไหน:** เอกสาร 3 ไฟล์ครบ · เพิ่มแถวใน `plan/README.md` · (รอบ 3) สร้าง [data/](data/) ส่งทีมหน้าบ้าน: `avatar-outfit-data.json` (data contract 11 slot / 31 parts / palette / state shape / animation / ui text) + `api-example.md` (5 endpoint `/api/user/avatar/*` + TS client + mock) + `frontend-guide.md` (คู่มือ dev หน้าบ้าน: mock, palette swap, renderer, reducer, checklist, DoD) · (รอบ 2 วันเดียวกัน) อ่าน prototype [Zyra Avatar Studio](https://claude.ai/artifact/5CWTCN9yMtbQ4czt29FVty) แล้วสรุป flow upload / layout ชีท 48px / validation / สี key / template tool ลง spec §5 + req AV-UP-11~17 + Q13–14
- **PR:** zyra-doc#90 (เอกสารอย่างเดียว)
- **verify ถึงไหน:** ตรวจว่าเนื้อหาตรงกับ ClickUp ทุกใบ · **ยังไม่ได้** ไล่ logic โค้ดเดิม, ยังไม่ได้ดึง Figma (MCP ยังไม่ authorize)
- **ต่อจากนี้:** ตอบ Q1–Q12 ใน requirements §6 ก่อน (สำคัญสุด Q1 ขัดกับมติ AvatarCustomization, Q2 ต่อยอดหรือขึ้นใหม่) → ดึง Figma 6 node → เขียน technical-design + task-breakdown
- **ติดอะไร:** API ใน data/api-example.md เป็นข้อเสนอ ยังไม่มีใน zyra-api · Ten ยังไม่ตอบคำถาม 7 ข้อที่ถามในแชท (ความสัมพันธ์กับ AvatarCustomization, sheet format, slot list, สี key, สถานะ HP-02/EC-02, Figma, ผลลัพธ์ที่ต้องการ) · HP-02 และ EC-02 ถูก Closed ใน ClickUp โดยไม่มี comment/PR อธิบาย — ไม่รู้ว่าทำเสร็จหรือตัด scope · due date task หลัก (2026-10-08) เลยแล้ว
