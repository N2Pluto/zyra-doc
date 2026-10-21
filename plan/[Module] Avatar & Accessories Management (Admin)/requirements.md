# [Module] Avatar & Accessories Management (Admin) — Requirements (แยกจาก spec)

> **สถานะ:** Draft — แยก req จาก ClickUp 2026-10-21 + เพิ่ม req จาก prototype Avatar Studio (AV-UP-11~17, Q13–14) · เทียบกับโค้ดเดิมแบบอ่านผิวเผิน (grep route/migration/ไฟล์ เท่านั้น ยังไม่ได้ไล่ logic) · ยังไม่ได้ดึง Figma
> **อ่านคู่กับ:** [spec.md](spec.md) (รายละเอียดทุก scenario) · [clickup-raw.md](clickup-raw.md)
> **รหัส req:** `AV-<กลุ่ม>-<เลข>` · คอลัมน์ "ที่มา" ชี้ไป scenario ใน ClickUp · คอลัมน์ "ของเดิม" = มีในโค้ดแล้วหรือยัง (จาก grep วันที่ 2026-10-21)

---

## 1. Data model — ต้องการอะไร

| Req | ความต้องการ | ที่มา | ของเดิม (zyra-api) |
|---|---|---|---|
| AV-DM-01 | Base character **1 ตัวต่อ platform** — ทุกคนใช้ตัวเดียวกัน | task หลัก | ❌ ของเดิมคือ `tb_avatar` = "ตัวละครสำเร็จรูปหลายตัว" (name, category general/special, walking/sitting sheet) — คนละ model |
| AV-DM-02 | Entity **Skin** = variant สี/สไตล์ของ base character · field: ชื่อ (≤50, unique), sort order, status, spritesheet URL, thumbnail URL, is_default, user_count | HP-02 | 🟡 ใกล้เคียง `tb_avatar` (migration 23/24/26/30) — ไม่มี `sort_order` · name เป็น VARCHAR(100) ไม่ใช่ 50 |
| AV-DM-03 | Entity **Accessory** = overlay แยก slot · field: ชื่อ (unique ใน category), category, status, รูปต่อ direction (4 ไฟล์หรือ 1 sheet), offset x/y **ต่อ direction**, thumbnail, user_count | HP-03 | ❌ ไม่มีตาราง accessory — ของเดิมมีแค่ `tb_avatar.accessory_slots TEXT[]` + route `POST /:id/accessory` (ผูกกับ avatar ตัวหนึ่ง ไม่ใช่ library กลาง) |
| AV-DM-04 | Category ของ accessory: **Hat / Glasses / Outfit / Bag / Wings** (5 ค่า) | task หลัก, HP-01, HP-03 | ❌ ของเดิมใน app: `AVATAR_ACCESSORY_SLOTS = ["hat","glasses","shirt"]` (3 ค่า, ชื่อไม่ตรง) |
| AV-DM-05 | Status 3 ค่า: `active` / `hidden` / `deleted` (soft delete) | HP-05, HP-06 | 🟡 ของเดิม status `active|hidden` + `is_deleted/deleted_at` แยก column (ไม่ได้ใช้ status=`deleted`) |
| AV-DM-06 | user ↔ item mapping: ต้องรู้ว่า user ใช้ skin ไหน + accessory ไหนในแต่ละ slot (เพื่อ user_count, reset ตอนลบ) | HP-01, HP-06, EC-02 | 🟡 มี `tb_user_avatar(user_id, avatar_id)` = เก็บได้แค่ 1 avatar ต่อ user · ไม่มี slot ของ accessory |
| AV-DM-07 | Audit log ทุกการแก้ไข/ลบ: admin_id, item_id, action, affected_user_count | HP-04, EC-02 | 🟡 มี `tb_avatar_audit_log` (migration 25, 57) — ต้องดูว่ารองรับ accessory + affected_user_count ไหม |
| AV-DM-08 | Hard delete: เก็บ `deleted_at` เพื่อ cron ลบ asset หลัง 30 วัน | HP-06 | ✅ มี `cmd/avatar-cleanup` ลบ S3 prefix `avatars/{id}/` + row (ต้องตรวจว่าใช้ 30 วันไหม และยังไม่ครอบ accessory) |

## 2. Asset / Upload — ต้องการอะไร

| Req | ความต้องการ | ที่มา | ของเดิม |
|---|---|---|---|
| AV-UP-01 | Skin spritesheet: PNG โปร่งใส · horizontal strip ต่อ state · frame 64×64 (หรือ 32×32 ตาม tile_size) · state บังคับ walk_s/n/e/w ×4, idle_s ×2 · sit ×2 optional | HP-02 | ❌ ของเดิมรับ sheet 1000px (`SUPPORTED_SHEET_SIZES = {1000}`) + metadata JSON ชื่อ frame `{character_id}_{state}_{n}` — layout คนละแบบ |
| AV-UP-02 | Skin: max **5MB** | HP-02, EP-01 | ❌ ของเดิม 20MB (`maxSpritesheetSize`) |
| AV-UP-03 | Accessory overlay: max **2MB**, PNG โปร่งใส, อัปโหลด 4 ไฟล์ต่อทิศ **หรือ** 1 sheet รวม 4 ทิศ | HP-03, EP-01 | 🟡 มี `MaxAccessoryDim = 256` + route upload accessory แต่เป็นรูปเดียวต่อ avatar |
| AV-UP-04 | Validate dimension: width หาร 64 ลงตัว · error บอกค่าจริง "(ของคุณ: {W}px)" | HP-02, EP-01 | 🟡 มี validate dimension ฝั่ง app (`validateSpritesheetDimensions`) แต่เช็คกับ 1000px |
| AV-UP-05 | Server ตรวจ PNG magic bytes `89 50 4E 47` | EP-01 | ✅ มี `avatarPNGMagic` ใน avatar_service.go |
| AV-UP-06 | Thumbnail auto-generate: skin จาก frame แรก `idle_s` **400×400** · accessory จาก South frame แรก | HP-02, HP-03 | 🟡 ของเดิม gen ฝั่ง client จาก walking sheet ขนาด 256 (`THUMBNAIL_SIZE = 256`) |
| AV-UP-07 | Transparency check: ไม่มีพื้นโปร่ง → **warning สีเหลือง ไม่บล็อก** | EP-01 | ❌ ไม่พบ |
| AV-UP-08 | Error ฝั่ง client ทันทีที่เลือกไฟล์ · inline ใต้ upload area · หายเมื่อเลือกไฟล์ใหม่ที่ถูก | EP-01 | 🟡 ของเดิมใช้ toast (`showValidationToast`) ไม่ใช่ inline |
| AV-UP-09 | Error code API: `INVALID_FILE_TYPE`, `FILE_TOO_LARGE`, `INVALID_DIMENSIONS`, `MISSING_DIRECTION`, `NAME_EXISTS` / `ACCESSORY_NAME_EXISTS` | HP-03, EP-01 | 🟡 ของเดิมใช้ `INVALID_TYPE`, `TOO_LARGE`, `MISSING_STATES`, `INVALID_FRAME_NAME`, `RESOLUTION_EXCEEDED` — ชื่อไม่ตรง |
| AV-UP-10 | เก็บไฟล์บน R2 เท่านั้น ตาม [11-s3-storage.md](../../../.claude/rules/11-s3-storage.md) | กฎโปรเจกต์ | ✅ ของเดิมใช้ S3Client prefix `avatars/{id}/` |
| AV-UP-11 | **(จาก prototype)** รับ 2 ไฟล์ต่อชิ้น: ชีทเดิน (บังคับ) + ชีทนั่ง (optional, fallback ใช้ชีทเดิน) · drop zone คลิก/ลากวาง · โชว์ชื่อไฟล์ + ขนาด + pixel ทึบ หลังอ่าน | spec §5.1, §5.3 | ❌ |
| AV-UP-12 | **(จาก prototype)** ตรวจ layout แบบ grid: 4 แถว (ลง/ซ้าย/ขวา/ขึ้น) × 4 หรือ 5 คอลัมน์ เฟรม 48×48 → error "ขนาดต้องเป็น 192×192 หรือ 240×192 แต่ไฟล์นี้ {W}×{H}" | spec §5.2, §5.4 | ❌ (ขัดกับ AV-UP-01 ที่ใช้ 64px — ดู Q13) |
| AV-UP-13 | **(จาก prototype)** warning ไม่บล็อก 3 แบบ: alpha ครึ่ง ๆ (ระบบจริงต้อง reject) · สีใกล้ key แต่ไม่ตรง (anti-alias) · channel ที่ slot นี้ไม่ควรใช้ · รายงาน inline สี ok/warn/bad | spec §5.4 | ❌ |
| AV-UP-14 | **(จาก prototype)** apply ชิ้นลง preview ทันทีก่อน save: เลือกท่า ยืน/เดิน/นั่ง, 4 ทิศ, หมุนอัตโนมัติ + diagnostic overlay (ผิวโผล่ = ชมพู, วาดเกิน base = ฟ้า, นับ px) | spec §5.5 | ❌ |
| AV-UP-15 | **(จาก prototype)** ระบบสี key 5 channel (skin/hair/eye/primary/secondary × 4 เฉด) · ตรวจว่าชิ้นใช้ channel ไหน · costume ไม่แปลงสี | spec §5.6 | ❌ |
| AV-UP-16 | **(จาก prototype)** เครื่องมือศิลปิน: export template (base จาง 30% + grid 48px, 1×/4×, overlay ชุดปัจจุบัน) · คัดลอกรูปไป Aseprite · ดาวน์โหลด template/guide/.gpl สำเร็จรูป | spec §5.7 | ❌ |
| AV-UP-17 | **(จาก prototype)** server bake หลัง save: `outfits/<hash>/walk.png` + `sit.png` (240×192, เติมคอลัมน์หลับตาเอง) + `thumb.png` | spec §5.2 | ❌ (ของเดิมเก็บ sheet ต่อ avatar ไม่มี bake) |

## 3. Admin UI — ต้องการอะไร

| Req | ความต้องการ | ที่มา | ของเดิม (zyra-app) |
|---|---|---|---|
| AV-UI-01 | หน้า Avatar Management แบ่ง **2 tab: Skins / Accessories** | HP-01 | ❌ ของเดิม `views/admin/avatar-management/` เป็น list avatar ชั้นเดียว ไม่มี tab |
| AV-UI-02 | Tab Accessories มี sub-tab 5 category | HP-01 | ❌ |
| AV-UI-03 | Grid card: thumbnail, ชื่อ, badge ✅ Active / 🚫 Hidden, user count, action buttons · **pagination 20/หน้า** | HP-01 | 🟡 มี `avatar-card.tsx`, `avatar-status-badge.tsx`, `avatar-pagination.tsx` — ต้องเช็ค page size |
| AV-UI-04 | Filter: All / Active / Hidden (+ "Deleted" ตาม HP-06) | HP-01, HP-06 | 🟡 มี `avatar-filter-menu.tsx` — ต้องเช็คว่ามี Deleted ไหม |
| AV-UI-05 | Search ตามชื่อ | HP-01 | ต้องเช็ค |
| AV-UI-06 | Sort: ใหม่สุด / เก่าสุด / ชื่อ A-Z / ใช้มากสุด | HP-01 | 🟡 มี `avatar-sort-menu.tsx` — ต้องเช็ค option |
| AV-UI-07 | ปุ่ม "+ Upload Skin ใหม่" → form: sheet PNG, ชื่อ, sort order, status · preview 4 ทิศ (idle_s animation) บน base character | HP-02 | 🟡 มี `avatar-form.tsx`, `avatar-preview-modal.tsx` — field/preview คนละ spec |
| AV-UI-08 | ปุ่ม "+ Upload Accessory ใหม่" ใน sub-tab → form: category pre-selected, overlay PNG, ชื่อ, status | HP-03 | ❌ |
| AV-UI-09 | **Slot position editor**: drag accessory บน preview เพื่อตั้ง offset x/y ต่อ direction + ปุ่ม "Copy to all directions" (South → N/E/W) | HP-03, HP-04 | ❌ |
| AV-UI-10 | Edit page: แก้ชื่อ/status · accessory แก้ offset ได้ · replace sprite → thumbnail regen · error ชื่อซ้ำ | HP-04 | 🟡 มี `avatar-detail-panel.tsx` — ต้องเพิ่ม offset editor + replace flow |
| AV-UI-11 | Default skin: ปุ่มลบ disabled + tooltip · ปุ่ม Hide ปิดถ้าเป็น skin Active ตัวเดียว | HP-05, HP-06 | ต้องเช็ค `avatar-delete-dialog.tsx` |
| AV-UI-12 | Delete confirmation แสดง user count: "Item นี้ถูกใช้โดย X users หากลบ avatars จะถูกรีเซ็ต item นี้" | HP-06 | 🟡 มี `avatar-delete-dialog.tsx` — ต้องเช็คข้อความ |
| AV-UI-13 | user count > 100 → ต้อง**พิมพ์ชื่อ item** ยืนยันก่อน Confirm | EC-02 | ❌ |
| AV-UI-14 | Progress ขณะ reset: "กำลัง reset 892 users... (450/892)" | EC-02 | ❌ |
| AV-UI-15 | ทำตาม Figma node ที่ระบุใน spec §2 (fidelity 95–100% ตาม [10-figma-fidelity.md](../../../.claude/rules/10-figma-fidelity.md)) · Tailwind-only · lucide-react only | กฎโปรเจกต์ | — |

## 4. API — ต้องการอะไร

> ของเดิมมี `/api/admin/avatars` อยู่แล้ว (List, Create, GetDetail, Update, Delete, UploadSpritesheet, UploadThumbnail, UploadMetadata, UploadAccessory) และ `/api/user/avatars`, `/api/user/avatars/default`, `PUT /api/user/me/avatar-selection` — ต้องตัดสินใจว่า **ต่อยอด** หรือ **ขึ้นชุดใหม่** (ดู §6 Q1)

| Req | ความต้องการ | ที่มา |
|---|---|---|
| AV-API-01 | List skins: filter status (all/active/hidden/deleted), search, sort (created desc/asc, name, user_count desc), page size 20 | HP-01, HP-06 |
| AV-API-02 | List accessories: เหมือน AV-API-01 + filter category | HP-01 |
| AV-API-03 | Create skin (multipart: sheet + metadata) → validate ตาม §2 → status default hidden | HP-02 |
| AV-API-04 | Create accessory (multipart: 4 ไฟล์ หรือ 1 sheet + category + offsets) → `MISSING_DIRECTION` ถ้าไม่ครบ · `ACCESSORY_NAME_EXISTS` ถ้าซ้ำใน category | HP-03 |
| AV-API-05 | Update metadata (ชื่อ/status/sort order/offsets) + replace sprite → regen thumbnail → audit log | HP-04 |
| AV-API-06 | Hide/Unhide: reject ถ้าเป็น default skin หรือเป็น skin Active ตัวสุดท้าย · มีผลกับ user picker ทันที | HP-05 |
| AV-API-07 | Delete: reject default skin · soft delete · trigger reset job · response ไม่บล็อก | HP-06, EC-02 |
| AV-API-08 | Reset job: batch 100 users · endpoint/stream ให้ admin ดู progress (เช่น `GET .../reset-jobs/:id`) | EC-02 |
| AV-API-09 | Member side: `/api/user/*` ต้องเห็นเฉพาะ active (ห้ามเรียก `/api/admin/*` ตาม [15-member-api-separation.md](../../../.claude/rules/15-member-api-separation.md)) · ต้องมี endpoint เลือก skin + accessory ต่อ slot | HP-05 |
| AV-API-10 | Response ใช้ `model.APIResponse` envelope ทุก endpoint | กฎโปรเจกต์ |

## 5. Realtime / Background — ต้องการอะไร

| Req | ความต้องการ | ที่มา | ของเดิม |
|---|---|---|---|
| AV-RT-01 | Hide/Unhide มีผลกับ user picker **ทันทีโดยไม่ต้อง reload** | HP-05 | ❌ ต้องออกแบบ (poll / WS event / query invalidate) |
| AV-RT-02 | Reset avatar ของ user online → **broadcast WebSocket** ให้เห็นเปลี่ยนทันที | EC-02 | ❌ ต้องแตะ zyra-ws (ดู memory: อ่านโค้ด ws จาก `origin/develop`) |
| AV-RT-03 | User offline → เห็นเปลี่ยนเมื่อเข้า VO ครั้งถัดไป | EC-02 | ✅ ได้เองถ้า VO โหลดจาก DB ตอน join |
| AV-RT-04 | Cron hard delete asset หลัง 30 วัน (ครอบทั้ง skin และ accessory) | HP-06 | 🟡 มี `cmd/avatar-cleanup` สำหรับ avatar เดิม |

## 6. ข้อขัดแย้ง / คำถามค้าง — ต้องตอบก่อน implement

| # | เรื่อง | รายละเอียด | รอใคร |
|---|---|---|---|
| Q1 | **ขัดกับมติ AvatarCustomization** | [AvatarCustomization/spec.md](../AvatarCustomization/spec.md) มติ 2026-10-05 (prototype เองก็เขียนว่า "ไม่มีหน้าให้ admin อัปโหลด"): "**ไม่มีหน้าให้ admin อัปโหลดรูป** — ชิ้นส่วน + palette เป็นไฟล์ใน repo" และ "ลบระบบ avatar เดิม (`tb_avatar` + Avatar Management) ออก" แต่ ClickUp โมดูลนี้ (สร้าง 2026-08-17, อัปเดต 2026-10-21) ให้ admin upload skin/accessory เอง → ต้องเลือกทางเดียว หรือตีความว่าโมดูลนี้ = หน้า "Part/Palette Management (admin)" ที่ AvatarCustomization ข้อค้าง 4 พูดถึง | PM (Moss) + Ten |
| Q2 | ต่อยอดหรือขึ้นใหม่ | ของเดิม `tb_avatar` / `/api/admin/avatars` / `views/admin/avatar-management` เป็น model "หลายตัวละครสำเร็จรูป" ไม่ใช่ "1 base + skin + accessory" → migrate schema เดิม หรือสร้างตาราง `tb_skin` / `tb_accessory` ใหม่แล้ว deprecate ของเดิม | Ten |
| Q3 | Slot list ไม่ตรงกัน | ClickUp: Hat / Glasses / Outfit / Bag / Wings (5) · โค้ดเดิม: hat / glasses / shirt (3) · AvatarCustomization มีตาราง slot อีกชุด (มี `costume`) | PM |
| Q4 | Frame size | ClickUp: 64×64 "หรือ 32×32 ตาม tile_size" · AvatarCustomization เสนอ 48×48 · โค้ดเดิม sheet 1000px | ศิลปิน + PM |
| Q5 | Thumbnail size | ClickUp 400×400 · โค้ดเดิม 256 · R2 key เดิม profile thumb 80×80 | PM |
| Q6 | HP-04 แก้ "Category" ได้ไหม | ชื่อ task มี Category แต่ AC ระบุแก้ได้แค่ชื่อ/status — ถ้าเปลี่ยน category ของ accessory ที่มีคนใส่อยู่ slot จะย้ายยังไง | PM |
| Q7 | Base character มาจากไหน | spec บอก 1 base character ต่อ platform แต่ไม่มี scenario upload/replace base character — เป็นไฟล์ใน repo? admin เปลี่ยนได้ไหม? | PM |
| Q8 | HP-02 และ EC-02 ถูกปิด (Closed) แล้ว | ปิดเพราะทำเสร็จ หรือปิดเพราะตัด scope? ไม่มี comment อธิบาย — ถ้าทำเสร็จ PR ไหน (git link ดึงไม่ได้) | Ten / PM |
| Q9 | user_count เชื่อถือได้ไหม | [AvatarManagement/SC-AV-01-user-count-fix.md](../AvatarManagement/SC-AV-01-user-count-fix.md) (2026-07-17) พบ `tb_user_avatar` ไม่เคยถูกเขียน → user_count = 0 ทั้งหมด · ตอนนี้มี `PUT /api/user/me/avatar-selection` แล้ว ต้องยืนยันว่าแก้แล้วบน prod เพราะ HP-01/HP-06/EC-02 พึ่งตัวเลขนี้ทั้งหมด | Ten |
| Q10 | Due date เลยแล้ว (2026-10-08) | task หลักยัง in progress — ต้องขอ due ใหม่หรือไม่ | PM |
| Q11 | Figma ยังไม่ได้ดึง | 6 node ใน spec §2 ต้อง authorize Figma MCP ก่อน (ตาม 10-figma-fidelity ห้ามเดา) · HP-02 และ EC-02 ไม่มี Figma link | Designer |
| Q12 | Accessory "ฟรีทั้งหมด" | task หลักบอก user เลือกใช้ได้ฟรีทั้งหมด → ไม่มี unlock/ราคา/เงื่อนไข ใช่ไหม (กันไว้ก่อน ไม่ต้องออกแบบ entitlement) | PM |
| Q13 | **Sheet format: ClickUp vs prototype** | ClickUp HP-02: เฟรม 64×64 strip ต่อ state (walk_s/n/e/w, idle_s, sit) · prototype: เฟรม 48×48 grid 4 แถว × 4–5 คอลัมน์ แยกไฟล์ walk + sit · accessory ใน ClickUp ใช้ offset x/y ต่อทิศ แต่ prototype วาดลงตำแหน่งจริงบน template ไม่มี offset → ต้องเลือกทางเดียว (ตาราง spec §5.8) | PM + ศิลปิน + Ten |
| Q14 | Prototype ทำไว้ฝั่ง member/designer ไม่ใช่ admin | ส่วน "ทดสอบชิ้นที่วาดเอง" เป็น sandbox ไม่ save ลง server · ถ้าจะเอาเป็นแบบหน้า admin ต้องเพิ่ม: ชื่อ/status/ชื่อซ้ำ, save ลง R2, audit log, user count, hide/delete ตาม HP-04~06 | Ten |

## 7. ขอบเขตที่ ClickUp **ไม่ได้พูดถึง** (ไม่ทำจนกว่าจะสั่ง ตาม [14-no-overreach.md](../../../.claude/rules/14-no-overreach.md))

- หน้า member เลือก skin/accessory (Avatar Customization ฝั่ง user) — ClickUp อ้างถึงแต่ไม่มี scenario ในโมดูลนี้
- Upload / เปลี่ยน base character
- Bulk upload, import/export, reorder ด้วย drag
- Role/permission ย่อยกว่า System Admin
- Mobile layout (custom field Desktop = ✅ เท่านั้น)
