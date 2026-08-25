# Pet Management Module (Admin) — Spec

> ดึงข้อมูลจาก ClickUp — Space: Zyra World, List: `901614367195`
> Parent Task: [\[Module\] Pet Management](https://app.clickup.com/t/86d3dcbra) (`86d3dcbra`)

> **อัปเดต 2026-08-14** — แก้ตามคำตอบ PM ที่ปิดแล้ว (ดู [pm-discussion-notes.md](pm-discussion-notes.md)): 4-stage model, mood 3-state, XP sources 10 activities, max dimension, pagination
>
> **อัปเดต 2026-08-17 — ✅ ปิดครบทุกจุด ไม่มี blocker เหลือ** 2 จุดที่เคย mark 🔴 ถูกเคาะแล้ว:
> - **SC-PM-03 — animation slot**: **ยึด Figma** — 1 slot = 1 ไฟล์ที่รวมทุก direction (spritesheet เป็น **grid**) slot vocabulary = `Wobbling`/`Walking`/`Sitting`/`Happy`/`Sad`/`Evolution`
> - **SC-PM-05 — flow assign pet**: **Map Editor drag-drop** ตัด tab "Assign to Room" ตั้งชื่อตอนวาง
>
> เนื้อหาในเอกสารนี้แก้ตามที่เคาะแล้ว — **ClickUp card 2 ใบยังเป็นของเก่า** (PM ต้องแก้เอง) ถ้าขัดกันให้ยึดเอกสารนี้
> DB schema + API contract: [db-schema-api-contract.md](db-schema-api-contract.md) · แผนแบ่งงาน: [work-split.md](work-split.md)

## Overview

Module สำหรับ **System Admin** จัดการ Pet Types, Sprites, Growth Stages และ XP Config ที่ใช้ใน Room Pet Feature (สัตว์เลี้ยงประจำห้องใน Virtual Office)

## Scope

- จัดการ Pet Type Library (ประเภทสัตว์เลี้ยง)
- จัดการ Sprite ต่อ Stage (Egg/Baby/Adult/Evolved) + Animation States
- กำหนด XP Config (threshold, decay rules)
- Assign Pet ให้ Room ของ Workspace
- Monitor Pet Stats ทุก Workspace

## Scenarios

| ID | Scenario | Type | Status (ClickUp) |
|----|----------|------|-------------------|
| [SC-PM-01](https://app.clickup.com/t/86d3dcbx9) | List Pet Types ทั้งหมด | Happy Path | pending |
| [SC-PM-02](https://app.clickup.com/t/86d3dcc16) | สร้าง Pet Type ใหม่ | Happy Path | pending |
| [SC-PM-03](https://app.clickup.com/t/86d3dcc8r) | Upload Sprite ต่อ Stage และ Animation | Happy Path | pending |
| [SC-PM-04](https://app.clickup.com/t/86d3dccmn) | กำหนด XP Config | Happy Path | pending |
| [SC-PM-05](https://app.clickup.com/t/86d3dcet3) | วาง Pet ลง Room ผ่าน Map Editor | Happy Path | pending |
| SC-PM-06 | Monitor Pet Stats ทุก Workspace | Happy Path | **Closed** (ไม่อยู่ในสโคป spec นี้) |
| [SC-PM-07](https://app.clickup.com/t/86d3dcfpz) | Sprite Upload ไม่ผ่าน Validation | Error Path | pending |

> หมายเหตุ: SC-PM-06 ถูกปิด (Closed) ใน ClickUp แล้ว และไม่ได้อยู่ในลิสต์ที่ร้องขอ — ไม่รวมรายละเอียดในเอกสารนี้

---

## SC-PM-01 · List Pet Types ทั้งหมด

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Admin เข้าหน้า Pet Management

### Scenario Steps
1. Admin เข้าหน้า Pet Management
2. แสดง Pet Type Library: card grid แสดงทุก pet type
3. แต่ละ card แสดง: sprite preview (Evolved stage), ชื่อ, category, stage count, status, workspace usage count
4. Filter / search / sort
5. กด Pet card → ดูรายละเอียด stages และ sprites

### Acceptance Criteria
- Grid layout, pagination **10/หน้า** (default; dropdown ให้ user เปลี่ยนได้)
- Card: Evolved sprite animated preview, ชื่อ, category badge, "4 stages", status, `workspace_usage_count`
  - เลขวงกลมข้างชื่อ pet ใน Figma = `workspace_usage_count` (ไม่ใช่ field ใหม่)
- Filter: status (active/hidden), category (cat/dog/dragon/bunny/custom...)
- Search: ชื่อ pet type
- Sort: name, created_at, usage_count
- Detail page: แสดง sprites ทุก stage + animation states ต่อ stage

### UX/UI Reference
[Figma — node 3997-197036](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3997-197036&t=KrMB68Z63QeG3ccx-0)

---

## SC-PM-02 · สร้าง Pet Type ใหม่

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Admin กด "สร้าง Pet Type ใหม่"

### Scenario Steps
1. กรอก: ชื่อ, category, description, status
2. กด Save → สร้าง Pet Type record
3. เข้าหน้า Stage Manager เพื่อ upload sprites (ต่อที่ SC-PM-03)

### Acceptance Criteria
- ชื่อ: required, max 100 ตัวอักษร, unique
- Category: dropdown (Cat, Dog, ...)
- Status default: `hidden` (ต้อง review ก่อน active)
- หลัง save: redirect ไปหน้า Stage Manager ทันที

### UX/UI Reference
[Figma — node 4017-33277](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4017-33277&t=KrMB68Z63QeG3ccx-0)

---

## SC-PM-03 · Upload Sprite ต่อ Stage และ Animation

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Pet Type สร้างแล้ว เข้าหน้า Stage Manager

### Stage Manager Layout
แต่ละ Stage (**Egg / Baby / Adult / Evolved**) มี Tab แยกกัน — 4 stages เท่านั้น

> Mood (Happy / Sad) **ไม่ใช่ stage** — เป็น state ที่คำนวณจาก activity (ดู SC-PM-04) โมเดล 6-stage เดิมที่มี `Lonely` / `Happy` เป็น tab ถูกยกเลิกแล้ว

### Animation Slots ต่อ Stage — ✅ ปิดแล้ว (ข้อ 2, ยึด Figma)

**1 slot = 1 ไฟล์ที่รวมทุก direction** — ตาราง per-direction ใน [SC-PM-03 card](https://app.clickup.com/t/86d3dcc8r) (`walk_n/walk_s/walk_e/walk_w`) ตกไปแล้ว card ยังไม่ถูกแก้

| Stage | Required Slots | Count |
|-------|----------------|-------|
| Egg | `Wobbling`, `Evolution` | 2 |
| Baby | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5 |
| Adult | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5 |
| Evolved | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5 |

- **Egg = 2 ไม่ใช่ 3** — counter ใน Figma node #4/#9 โชว์ `3/3` แต่ animation dropdown ของ Egg โชว์แค่ 2 รายการ ([ux-ui.md:350](ux-ui.md)) → ยึด dropdown, counter เป็น mockup ที่ไม่ sync
- **Adult / Evolved** ไม่มี frame ใน Figma ที่โชว์ dropdown ตรง ๆ — อนุมานว่าเหมือน Baby
- **Egg → Baby เล่น `Evolution`** (ตอบคำถามเดิมเรื่อง animation ตอนฟักไข่)
- **Happy / Sad เป็น slot ภายใน stage ไม่ใช่ stage แยก** — สอดคล้องกับ mood 3-state ใน SC-PM-04

### Scenario Steps
1. Admin เลือก Stage tab (Egg, Baby, Adult, Evolved)
2. แต่ละ Stage แสดง animation slots
3. Upload PNG spritesheet ต่อ animation state (เหมือน Object Composer แต่ simpler)
4. Admin กำหนด frame count และ frame rate ต่อ animation
5. Preview animation บน canvas
6. บันทึก

### Acceptance Criteria
- Stage tabs: Egg, Baby, Adult, Evolved
- Animation slots: แสดง required (สีแดง ถ้าขาด) และ optional (สีเทา)
- Upload PNG spritesheet ต่อ animation: max 1MB, max 1,000 × 1,000 px, แนะนำให้มี transparency (ไม่มี = warning ไม่ block)
- กำหนด `frame_count`, `frame_rate` (fps) และ `direction_rows` **ต่อ animation** (ไม่ใช่ global ต่อ stage)
- Preview: แสดง animation loop บน canvas ก่อน save
- Required animations ต้อง upload ครบก่อน stage นั้นพร้อมใช้งาน
- "Stage Ready" badge แสดงบน tab ที่ครบ required animations

### Business Logic / Rules
- Spritesheet: **grid** — คอลัมน์ = frame, แถว = direction (ไม่ใช่ horizontal strip แล้ว ตามข้อ 2)
- `frame_width  = sprite_width  / frame_count`
- `frame_height = sprite_height / direction_rows`
- ⏸ **ค่า `direction_rows` ที่ยอมรับ + ลำดับแถว ยังไม่ล็อก — รอดู sprite จริงจาก artist**
  - สมมติฐาน: `1` (ไม่มีทิศ) หรือ `4` (VO เป็น orthogonal-only) เรียงตาม `AVATAR_DIR_ROW` ใน `zyra-engine/avatar-frames.ts` — `0 = down` · `1 = left` · `2 = right` · `3 = up`
  - คาดว่า `Walking` / `Sitting` = 4, `Wobbling` / `Evolution` / `Happy` / `Sad` = 1
  - เป็นค่าที่ admin กรอกตอน upload ไม่ได้ hardcode → เปลี่ยนได้โดยไม่ต้อง migrate ข้อมูล
- Engine render: Phaser.js `anims.create()` จาก frame config
- Stage incomplete: pet จะใช้ fallback animation (`Walking` loop; Egg ใช้ `Wobbling`)

### UX/UI Reference
[Figma — node 4043-249225](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4043-249225&t=F9kfchFmCSys23FH-0)

---

## SC-PM-04 · กำหนด XP Config

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Admin เข้าหน้า Pet Management → Tab XP Config

### XP Config Parameters

**Evolution XP (Stage Thresholds)**

| Field | Default | Transition |
|-------|---------|--------------|
| `xp_baby` | 100 | Egg → Baby |
| `xp_adult` | 500 | Baby → Adult |
| `xp_evolve` | 2000 | Adult → Evolved |

**XP Sources — 10 activities**

`Max` = เพดานของค่าที่ admin ตั้งได้ในฟอร์ม (validation) ไม่ใช่เพดาน XP ต่อวัน

| Field | Default | Max | Description |
|-------|---------|-----|--------------|
| `xp_login_per_day` | 1 | 5 | XP ต่อ user login/วัน |
| `xp_office_10min` | 2 | 10 | มีคนอยู่ใน office 10 นาที |
| `xp_office_30min` | 6 | 30 | มีคนอยู่ใน office 30 นาที |
| `xp_team_meeting` | 10 | 50 | Team join a meeting |
| `xp_team_meeting_10min` | 2 | 10 | Team join a meeting 10 นาที |
| `xp_team_meeting_30min` | 6 | 30 | Team join a meeting 30 นาที |
| `xp_first_message_fo_day` | 1 | 5 | ส่ง message แรกของวัน |
| `xp_10_message_fo_day` | 2 | 10 | ส่ง chat 10 ข้อความ |
| `xp_react_message_fo_day` | 1 | 5 | React message ด้วย emoji |
| `xp_play_with_pet` | 1 | 5 | เล่นกับ pet |

> **ชื่อ field ต้องใช้ตามนี้เป๊ะทั้ง FE/BE** — `_fo_day` เป็น typo ที่ตั้งไว้ใน card แล้ว (`fo` = `of`) เปลี่ยนได้ก็ต้องเปลี่ยนพร้อมกันทั้ง card และโค้ด
>
> คำถามเดิมว่า field `time` ต่อ activity หมายถึงอะไร — ตกไปแล้ว เพราะเวลาถูกฝังในชื่อ activity (`_10min` / `_30min`) ไม่ใช่ input แยก
>
> **ยังค้าง (ไม่บล็อก schema)**: Figma มี toggle เปิด/ปิดต่อ activity แต่ card ไม่มี field นี้ → ถ้าต้องมี ต้องเพิ่ม `enabled: boolean` ต่อ activity

**Mood & Penalty Config — 3 states**

Mood กระทบ **อัตราการได้ XP** (ไม่ใช่หัก XP ตรง ๆ) — Happy ได้ bonus, Sad ถูก penalty

| State | Field | Duration | XP rate | ความหมาย |
|-------|-------|----------|---------|-----------|
| Happy | `xp_happy` | 12 Hr. | **150%** | ร่าเริง |
| Neutral | — | 48 Hr. | 100% | ปกติ |
| Sad | `sad_after_hours` | 72 Hr. | **50%** | ไม่มีใครเข้ามา + เหงา |

- `Duration` = ระยะเวลาที่ไม่มี activity แล้วตกเข้า state นั้น → active ภายใน 12 ชม. = Happy, 12–48 ชม. = Neutral, เกิน 72 ชม. = Sad
- Validation: ต้องบังคับ `Happy% ≥ Neutral% ≥ Sad%` เสมอ (ตาม note ของ designer)
- ⚠️ ช่วง **48–72 ชม.** ยังไม่มี state กำกับใน card — ตีความชั่วคราวว่า Neutral ยืดถึง 72 ชม. ต้องให้ PM confirm ก่อนเขียน mood scheduler
- sticky note ใน Figma เขียน "Happy XP (50%)" ซึ่งกลับหัวกับตารางนี้ — ยึด card (ใหม่กว่า และ Happy=bonus สมเหตุสมผลกว่า)

### Scenario Steps
1. Admin เข้า XP Config section
2. เห็น config ปัจจุบัน (default values)
3. Admin ปรับค่าตามต้องการ
4. กด Save → config มีผลทันทีกับทุก pet ใน platform

### Acceptance Criteria
- Config form: number inputs พร้อม min/max validation
- Save confirmation: "การเปลี่ยน XP Config จะมีผลกับ Pet ทุกตัวในทันที"
- Config history: บันทึก 10 versions ล่าสุด ย้อนกลับได้
- Preview impact: "ด้วย config นี้ Pet จะถึง Evolved ใน ~X วัน (ถ้า team 5 คน active ทุกวัน)"

### UX/UI Reference
[Figma — node 4066-205195](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4066-205195&t=KrMB68Z63QeG3ccx-0)

---

## SC-PM-05 · วาง Pet ลง Room ผ่าน Map Editor

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Pet Type มี sprites ครบ (status = active), Admin เปิด Map Editor ของ workspace/template ที่ต้องการ

### ✅ ปิดแล้ว (ข้อ 5) — flow เปลี่ยนจากฟอร์มเป็น drag-drop

- ✅ ใช้ **Map Editor drag-drop** — ลาก Pet จาก palette ไปวางบน room zone
- ✅ **ตัด tab "Assign to Room"** ในหน้า Pet Management ออกทั้งหมด
- ✅ **ตั้งชื่อ pet ตอนวาง** เหมือนตั้งชื่อห้อง (แก้ทีหลังได้)

> [SC-PM-05 card](https://app.clickup.com/t/86d3dcet3) ยังเป็น flow ฟอร์มเดิมทั้งใบ — **ตกไปแล้ว** ยึดเอกสารนี้ PM ต้องแก้ card ตาม

### Scenario Steps
1. Admin เปิด Map Editor ของ workspace/template
2. เลือก Pet จาก palette (แสดงเฉพาะ pet type ที่ status = active และ sprite ครบ)
3. ลากไปวางบนตำแหน่งที่ต้องการภายใน room zone
4. ตั้งชื่อ Pet ตอนวาง (optional — ไม่กรอก = ใช้ชื่อ Pet Type)
5. Pet ถูกสร้างที่ตำแหน่งที่วาง ด้วย `xp = 0` (stage/mood เป็นค่า derived)
6. Workspace members ที่ online เห็น Pet ปรากฏบน map ทันที
7. ลากย้าย / เปลี่ยนชื่อ / ลบ ได้จาก Map Editor เดียวกัน

### Acceptance Criteria
- Pet palette: แสดงเฉพาะ pet type `status = active`
- ตำแหน่ง: **ใช้ตำแหน่งที่ admin วาง** (`tile_x`/`tile_y` เป็น `DOUBLE PRECISION` รองรับ quarter-tile) — ไม่ใช่ center ของ zone
- ต้องวางภายใน room zone — วางนอก zone = ไม่ให้วาง
- ชื่อ Pet: optional, max 30 chars, default = Pet Type name
- ย้าย/เปลี่ยนชื่อ/ลบ Pet จาก Map Editor ได้
- Broadcast ให้ users ที่ online เห็นทันที (`pet_spawned` / `pet_moved` / `pet_renamed` / `pet_removed`)
- ⚠️ **กฎ 1 room = 1 pet ยังไม่เคาะ** — default ปัจจุบันคือ **วางได้หลายตัวต่อห้อง** (ไม่เปิด unique index) ถ้า PM ยืนยันว่าบังคับ ให้เปิด index + คืน `409 ZONE_ALREADY_HAS_PET`

### Business Logic / Rules
- วาง pet = สร้าง `tb_room_pet` record: `xp = 0`, `last_activity_at = NOW()`, `last_seen_stage = 'egg'`
- **ไม่เก็บ `stage` / `mood` เป็นคอลัมน์** — derive จาก `xp` + threshold และ `last_activity_at` ตอนอ่าน
- Pet ปรากฏบน map ทันทีผ่าน `ZoneEventPublisher` → Redis `vo:zone` → zyra-ws
- ⚠️ **ยังค้าง**: วาง pet ใน Workspace Template แล้ว workspace ที่สร้างไปก่อนหน้าได้ pet ด้วยไหม

### UX/UI Reference
[Figma — node 4114-199428](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4114-199428&t=F9kfchFmCSys23FH-0)

---

## SC-PM-07 · Sprite Upload ไม่ผ่าน Validation

**Type:** Error Path
**Persona:** System Admin — upload sprite ที่ไม่ถูกต้อง
**Pre-condition:** Admin พยายาม upload spritesheet ใน Stage Manager

### Error Cases

| Case | Message | Trigger |
|------|---------|---------|
| ไม่ใช่ PNG | "รองรับเฉพาะ PNG" | `file.type ≠ image/png` |
| ขนาดเกิน 1MB | "ขนาดไฟล์ต้องไม่เกิน 1 MB" | `size > 1MB` |
| frame_count ผิด | "จำนวน frame ต้องไม่เป็น 0 หรือเกิน 64" | `frame_count < 1` หรือ `> 64` |
| frame_rate ผิด | "Frame rate ต้องอยู่ระหว่าง 4-24 fps" | `fps < 4` หรือ `> 24` |
| Width ไม่หารลงตัว | "Width ของรูป ({W}px) ต้องหารด้วย frame_count ({N}) ลงตัว" | `width % frame_count ≠ 0` |
| **Height ไม่หารลงตัว** | "Height ของรูป ({H}px) ต้องหารด้วย direction_rows ({R}) ลงตัว" | `height % direction_rows ≠ 0` — เคสใหม่จากข้อ 2 (grid) |
| **direction_rows ผิด** ⏸ | "จำนวนแถวไม่ถูกต้อง" | ค่าที่ยอมรับรอดู sprite จริง (สมมติฐาน: `1` หรือ `4`) |
| **ขนาดภาพเกิน 1,000 × 1,000 px** | "ขนาดภาพต้องไม่เกิน 1,000 × 1,000 px" | `width > 1000` หรือ `height > 1000` — **block** |
| ไม่มี transparency | "แนะนำให้ใช้ PNG ที่มี transparent background" | warning ไม่ใช่ error (ยืนยันแล้ว — ไม่ block upload) |

### Acceptance Criteria
- Validate client-side ทันทีที่เลือกไฟล์
- Frame size preview: แสดง "frame size = {W/N} × {H/R} px" หลังกรอก frame_count และ direction_rows
- Width/Height หารไม่ลงตัว: error แสดงทันทีเมื่อกรอกค่า
- Server magic bytes validate: PNG signature `89 50 4E 47`
- Warning transparency: yellow banner ไม่บล็อก upload
- Dimension เกิน 1,000 × 1,000 px: error toast แดง block การ upload

### Validation Rules Summary

| Field | Rule | Code |
|-------|------|------|
| file | PNG only | `INVALID_FILE_TYPE` |
| file | max 1MB | `FILE_TOO_LARGE` |
| width / height | max 1,000 px | `INVALID_DIMENSIONS` ⚠️ |
| frame_count | 1–64 | `INVALID_FRAME_COUNT` |
| frame_rate | 4–24 fps | `INVALID_FRAME_RATE` |
| direction_rows | ⏸ รอ artist (สมมติฐาน: 1 หรือ 4) | `INVALID_DIRECTION_ROWS` ⚠️ |
| width % frame_count | = 0 | `FRAME_SIZE_MISMATCH` |
| height % direction_rows | = 0 | `FRAME_ROW_MISMATCH` ⚠️ |

> ⚠️ `INVALID_DIMENSIONS` เป็นชื่อที่ **เราเสนอ** — card เพิ่มเคส dimension เข้ามาแต่ยังไม่ได้ตั้ง error code ให้ (ตาราง code ใน card ยังมีแค่ 5 ตัวเดิม) ให้ PM ยืนยันชื่อก่อน implement

### Error Codes & HTTP Status

| HTTP | Code | Message | Trigger |
|------|------|---------|---------|
| 400 | `INVALID_FILE_TYPE` | รองรับเฉพาะ PNG | ไม่ใช่ PNG |
| 400 | `FILE_TOO_LARGE` | ขนาดไฟล์เกิน 1 MB | เกิน limit |
| 400 | `INVALID_DIMENSIONS` ⚠️ | ขนาดภาพต้องไม่เกิน 1,000 × 1,000 px | width หรือ height เกิน 1,000 |
| 400 | `INVALID_FRAME_COUNT` | frame_count ต้องอยู่ระหว่าง 1-64 | ค่าผิด |
| 400 | `INVALID_FRAME_RATE` | frame_rate ต้องอยู่ระหว่าง 4-24 fps | ค่าผิด |
| 400 | `INVALID_DIRECTION_ROWS` ⚠️ | direction_rows ไม่ถูกต้อง | ค่าผิด (ช่วงที่ยอมรับ ⏸ รอ artist) |
| 400 | `FRAME_SIZE_MISMATCH` | width ของรูปต้องหารด้วย frame_count ลงตัว | หารไม่ลงตัว |
| 400 | `FRAME_ROW_MISMATCH` ⚠️ | height ของรูปต้องหารด้วย direction_rows ลงตัว | หารไม่ลงตัว |

> ⚠️ `INVALID_DIMENSIONS`, `INVALID_DIRECTION_ROWS`, `FRAME_ROW_MISMATCH` เป็นชื่อที่ **เราเสนอ** — card ยังมีแค่ 5 code เดิม ให้ PM ยืนยันก่อน implement

### UX/UI Reference
[Figma — node 4043-252350](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4043-252350&t=KrMB68Z63QeG3ccx-0)
