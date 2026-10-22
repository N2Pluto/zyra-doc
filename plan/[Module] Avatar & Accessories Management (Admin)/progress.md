# [Module] Avatar & Accessories Management (Admin) — Progress / Handoff

> **สถานะรวม:** เริ่ม implement แล้ว (รอบ 6) — เปิด PR 4 ตัว รอ review: zyra-app#638 (APP-1 renderer lib) · zyra-app#639 (APP-2 shell + category panel) · zyra-api#179 (API-1 schema) · zyra-api#180 (API-2 validator) · ยังไม่ merge · D1–D6 ยังไม่มีคำตอบ ใช้ค่าตามเอกสารไปก่อน (ระบุใน PR)
> **อัปเดตล่าสุด:** 2026-10-22 · **คนล่าสุด:** Ten (ผ่าน Claude Code)

## 2026-10-22 (รอบ 6 · เริ่ม implement) · Ten (ผ่าน Claude Code)

- **ทำอะไร:**
  - APP-1 `lib/avatar-part/{constants,shade,render,chair,validate}.ts` ยกจาก POC · ใช้ layout ชีทจาก `zyra-engine/avatar-frames` (ไม่ประกาศซ้ำ) · `chairOffsets` คำนวณจาก composition จริงด้วยสูตร VO (piece − 176, เท้า = sitPoint + 5) · base sheet `public/avatar/base/{walk,sit}.png`
  - APP-2 หยิบ branch `feat/accessory-category-panel` กลับมา rebase บน develop · icon 18 หมวดจาก Figma เข้า `components/ui/icon.tsx` (`AccessoryCategoryIcon`, currentColor) · panel อ่านรายชื่อหมวดจาก `lib/avatar-part/constants.ts`
  - API-1 migration **118** (115–117 ถูกใช้แล้ว) + embedded DDL: `tb_avatar_part`, `tb_avatar_part_variant`, `tb_avatar_part_audit`, `tb_avatar_reset_job`, `tb_user_outfit` + GIN · model + ค่าคงที่ 18 หมวด
  - API-2 `ValidateAccessorySheet` / `ValidateAccessoryInput` / `CheckRequiredSheets` · code ใหม่ `VARIANT_NAME_REQUIRED`, `VARIANT_NAME_TOO_LONG`, `INVALID_COLOR_TAG` (เพิ่มใน technical-design §5)
- **ถึงไหน:** 4 PR เปิดเข้า develop · ลำดับ merge: #638 → #639 · #179 → #180 (ตัวหลังมี commit ของตัวหน้า)
- **PR:** zyra-app#638 · zyra-app#639 · zyra-api#179 · zyra-api#180
- **verify ถึงไหน:**
  - build เขียว: vitest renderer 64 ผ่าน (coverage `lib/avatar-part` 98%) · Go `go test ./...` เขียว · validator 44 sub-test (AC-U-01~28) · model parity AC-T-04 ทั้งสองฝั่ง
  - migration: รันบน dev DB ใน transaction แล้ว ROLLBACK (ไม่มีอะไรค้าง) — up 5 ตาราง · up ซ้ำไม่ error · ชื่อซ้ำในหมวดเดียวกันโดนบล็อก / ข้ามหมวด + หลังลบใช้ซ้ำได้ · query นับผู้ใช้ใช้ GIN index · down → up ได้
  - UI: category panel เปิดใน browser ผ่าน harness ชั่วคราวที่ 1440×1024 — icon ครบ 18 · active เป็นสีเขียว · ไม่มี console error
  - **ยังไม่ได้** เทสหลัง login admin บน dev · ยังไม่ได้บูต pod จริงกับ migration 118 (เกิดหลัง merge)
- **ต่อจากนี้:** review + merge 4 PR → API-3 (service CRUD + R2 + thumbnail) → API-4 (routes + permission) → APP-3 (list)
- **ติดอะไร:** D1–D6 ยังไม่ตอบ (ใช้ 48px · ไม่โปร่งใส = error · sit ตาม sticky · `tb_avatar_part` สร้างใน API-1) · เอกสาร `plan/AvatarCustomization/` ที่อ้างถึงยังไม่ขึ้น main (มีแค่ในเครื่อง)

## 2026-10-21 (รอบ 5 · POC) · Ten (ผ่าน Claude Code)

- **ทำอะไร:** แก้ POC [poc/accessory-admin-poc.html](poc/accessory-admin-poc.html) ตาม feedback Ten (publish: https://claude.ai/artifact/EHWxezQ31xnvz5vWBCeUNv version 10)
  - category panel (Figma 7508:36620): icon 18 หมวดใช้ SVG จาก Figma ตรง ๆ + chevron/search จาก Figma · ค้นหาได้ · พับกลุ่มได้
  - sidebar icon เทียบ path กับ lucide: Object = armchair, Workspace = pencil-ruler, Customer = user-round, Admin = user-round-cog (Map ยังไม่เจอตัวตรง ใช้ files ไปก่อน)
  - หน้า list: card แสดงตัวละครใส่ชิ้นนั้น (base + ตา Eye 1 default + ชิ้น)
  - tab Sitting: เก้าอี้จาก object จริง "Office Chair" (Blue, dev `tb_object` 498aac2c…) วางตามสูตร VO engine (piece − 176, เท้าที่ sitPoint + 5px, `above_character` วาดทับ)
  - สี: swatch ลงสีของหมวดนั้นเอง (Eyes → ตา, Hair/Facial Hair → ผม, เสื้อผ้า → primary/secondary) · เปลี่ยนเป็นเลือกสีหลัก 12 สีจาก Figma แล้วเลื่อนแถบ Shade ปรับความเข้ม (ซ้ายจางถึงพาสเทล ขวาเข้มถึงเกือบดำ)
- **ถึงไหน:** POC ใช้รีวิวได้ครบ 6 scenario · zyra-app#636 ปิดแล้ว (Ten ให้ทำใน POC ก่อน)
- **verify ถึงไหน:** เปิดผ่าน local server ในแอปที่ 1440px ทุกรอบ ไม่มี console error · ยังไม่ได้ให้ทีม design รีวิว
- **ต่อจากนี้:** ทีม design รีวิว POC · แถบ Shade ไม่มีใน Figma (ออกแบบเอง) รอ design ยืนยัน · ~~เขียน ux-ui-plan.md~~ เขียนแล้ว → [ux-ui-plan.md](ux-ui-plan.md) (ค่า Figma ทุก node + สิ่งที่ POC ต่างจาก Figma + คำถาม U1–U8) · [test-plan.md](test-plan.md) (EP/BVA/decision table/state transition + traceability ครบ 8 scenario) · [technical-design.md](technical-design.md) (ต่อยอด schema AvatarCustomization, migration 115, reset job, ws `outfit_reset`) · [task-breakdown.md](task-breakdown.md) (13 PR ≈ 17.5 วัน, blocker D1–D6) · ถัดไป: ตอบ D1–D6 แล้วเริ่ม API-1 / APP-1 / APP-2
- **ติดอะไร:** Map management icon ใน Figma ไม่ตรง lucide ตัวไหน

## 2026-10-21 · Ten (ผ่าน Claude Code)

- **ทำอะไร:** ดึง ClickUp task หลัก `86d43pbbj` + subtask 8 ใบ (description, status, priority, custom field, comment, attachment, checklist, dependency) มาเก็บเป็น [clickup-raw.md](clickup-raw.md) → เรียบเรียงเป็น [spec.md](spec.md) → แยกเป็น req 40 ข้อใน [requirements.md](requirements.md) พร้อมเทียบกับโค้ดเดิม (grep route / migration / ไฟล์ view) แบบผิวเผิน
- **ถึงไหน:** (รอบ 4) ดึง Figma ครบ 6 node (5 master screen + sidebar category + submenu + colour picker + modal 3 แบบ + toast 4 แบบ + screenshot state 32 ภาพ) → ทำ POC [poc/accessory-admin-poc.html](poc/accessory-admin-poc.html) (publish ที่ https://claude.ai/artifact/EHWxezQ31xnvz5vWBCeUNv) ใช้ sprite จริง 72 ไฟล์จาก `demo file/custom avatar` + palette swap + animation เดิน/นั่ง/หมุน 4 ทิศ · ยังไม่ได้เขียน ux-ui-plan.md (รอ Ten ดู POC ก่อน) · (รอบ 3) สร้าง [data/](data/) ส่งทีมหน้าบ้าน: `avatar-outfit-data.json` (data contract 11 slot / 31 parts / palette / state shape / animation / ui text) + `api-example.md` (5 endpoint `/api/user/avatar/*` + TS client + mock) + `frontend-guide.md` (คู่มือ dev หน้าบ้าน: mock, palette swap, renderer, reducer, checklist, DoD) · (รอบ 2 วันเดียวกัน) อ่าน prototype [Zyra Avatar Studio](https://claude.ai/artifact/5CWTCN9yMtbQ4czt29FVty) แล้วสรุป flow upload / layout ชีท 48px / validation / สี key / template tool ลง spec §5 + req AV-UP-11~17 + Q13–14
- **PR:** zyra-doc#90 (เอกสาร) · zyra-app#636 (category panel) ปิดแล้ว 2026-10-21 ตามคำสั่ง Ten — โค้ดยังอยู่ที่ branch `feat/accessory-category-panel` (worktree `.wt/zyra-app-accessory`)
- **verify ถึงไหน:** #636: tsc/eslint/prettier เขียว + i18n-namespace-split test ผ่าน + render ผ่าน dev harness ชั่วคราวที่ 1440×1024 (panel 368×920, row 42, filter ทำงาน) · **ยังไม่ได้** เทสหลัง login admin จริง · เอกสาร: ตรวจว่าเนื้อหาตรงกับ ClickUp ทุกใบ · **ยังไม่ได้** ไล่ logic โค้ดเดิม, ยังไม่ได้ดึง Figma (MCP ยังไม่ authorize)
- **ต่อจากนี้:** review/merge #636 → หน้า list (node 7000:443507) + add Special/Other (7031:170181, 7031:171040) + edit (7024:48803) ทีละ PR โดยใช้ค่าจาก POC · icon ใน Figma เป็น lucide: Characters = person-standing, Wand = wand-sparkles, Filter = list-filter, Pet = paw-print, PanelLeftClose = panel-left-close, Rotate = rotate-cw/ccw (เทียบ path แล้ว) · เขียน ux-ui-plan.md จากค่า Figma ที่ดึงแล้ว → technical-design + task-breakdown · ตอบ Q1–Q14 ใน requirements §6 (สำคัญสุด Q1 ขัดกับมติ AvatarCustomization, Q2 ต่อยอดหรือขึ้นใหม่) → ดึง Figma 6 node → เขียน technical-design + task-breakdown
- **ติดอะไร:** API ใน data/api-example.md เป็นข้อเสนอ ยังไม่มีใน zyra-api · Ten ยังไม่ตอบคำถาม 7 ข้อที่ถามในแชท (ความสัมพันธ์กับ AvatarCustomization, sheet format, slot list, สี key, สถานะ HP-02/EC-02, Figma, ผลลัพธ์ที่ต้องการ) · HP-02 และ EC-02 ถูก Closed ใน ClickUp โดยไม่มี comment/PR อธิบาย — ไม่รู้ว่าทำเสร็จหรือตัด scope · due date task หลัก (2026-10-08) เลยแล้ว
