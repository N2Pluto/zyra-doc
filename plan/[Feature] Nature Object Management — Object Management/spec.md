# SC-OBJ-NAT-01 · Nature Object Management — Object Management (Admin)

> **สถานะ:** ถอด spec จาก ClickUp ทั้งหมดแล้ว (2026-09-16) — **ยังไม่ implement** · ยังไม่ verify กับโค้ดจริง
> **🔄 รอบที่ 2 — ดึงใหม่ 2026-09-16 ~11:09 หลัง PM แก้ ClickUp:** main task ถอด **HP-04 ออกจากตาราง Subtasks** (ตัว subtask ยัง Closed อยู่) · **HP-03** เพิ่ม AC 2 ข้อ + แก้ 1 ข้อ (กด Upload → Modal · Object Status fallback idle · หลังบันทึกกำหนดสี/ประเภท box ได้) + ตาราง Required เปลี่ยน `sakura_tree` → `shedding_tree` แล้ว (แต่ `petal_fall` ยังไม่แก้) · **HP-05** step 1 เป็น "กด Preview บนหน้า Upload แล้วแสดง popup" + **ลบ ASCII mock ของ preview panel ออก** · **HP-06** `date_updated` เปลี่ยนแต่เนื้อหาเหมือนเดิม · HP-01/02/07, EP-01, EC-01 ไม่เปลี่ยน · รายละเอียดดู [§รอบที่ 2](#รอบที่-2--2026-09-16-pm-update-clickup)
> **🔄 รอบที่ 3 — ดึงใหม่ 2026-09-17 ~10:36:** **ไม่มีการแก้ description ใดๆ ทั้ง main และ 8 subtask** (เทียบกับรอบที่ 2 แล้วตรงทุกตัว) — เปลี่ยนแค่ **status: `pending` → `in progress` ทั้ง 9 task** (HP-04 ยัง `Closed` เหมือนเดิม) = PM เปิดงานให้เริ่มทำแล้ว · **ข้อขัดแย้ง Figma ↔ spec 12 ข้อใน [ux-ui-plan §14.1](ux-ui-plan.md#141-ต้องตัดสินก่อนเริ่มโค้ด-กระทบ-schema--api--flow) ยังไม่ถูกตอบเลย** (ไม่มี comment ใหม่ใน ClickUp) → ยังต้องเคลียร์กับ PM ก่อนแตะ schema · รายละเอียดดู [§รอบที่ 3](#รอบที่-3--2026-09-17-status-เปลี่ยนเป็น-in-progress)
> **วันที่สร้าง task:** 2026-08-24 · **อัปเดตล่าสุดใน ClickUp:** 2026-09-17 · **ClickUp (main):** [86d446fw1](https://app.clickup.com/t/86d446fw1) (`in progress`)
> **Module:** Object Management — Project Zyra · **Parent Module:** SC-OBJ (Object Management) · **Persona:** System Admin · **Priority:** Normal
> **Tag:** `admin` · **Assignees:** P A, Ponlawat Lueakaew · **Platform:** Desktop เท่านั้น (custom field `Desktop` ✅, `Mobile`/`Tablet` ไม่ติ๊ก)
> **List:** List · **Folder:** Zyra World · **Space id:** 90166731836
> **เป็นส่วนเสริมที่เพิ่มเข้ามาใหม่จาก Object Management (Admin) เดิม** — เพิ่ม Object Type ใหม่ชื่อ **Nature** แยกจาก Furniture/Decoration/Structure
> **✅ Naming ยืนยันแล้วกับผู้ใช้ (2026-09-16):** ใช้ `shedding_tree` (ไม่ใช้ `sakura_tree`) และ `falling` (ไม่ใช้ `petal_fall`) — ทั้งใน DB schema, API contract และ Figma node ต้อง sync ชื่อนี้ก่อน implement (ตาม comment ใน ClickUp HP-03 โดย P A, 2026-08-24 17:41) เนื้อหาดิบใน subtask HP-03/HP-04 ที่ดึงมาจาก ClickUp ยังเป็นชื่อเดิม (`sakura_tree` / `petal_fall`) — เก็บไว้ตามต้นฉบับในส่วน "Subtask Detail" ด้านล่างเพื่อไม่ให้ตกรายละเอียด แต่ถือว่าเป็นชื่อที่เลิกใช้แล้ว
> **เนื้อหาส่วนหลักคือ spec ตามที่ ClickUp เขียนไว้เท่านั้น** ยังไม่ผ่านการ verify กับโค้ดจริง

---

## Overview & Goal

เพิ่ม **Nature** เป็น Object Type ใหม่ใน Object Management module — Admin จัดการ Nature objects (ต้นไม้, พุ่มไม้, ดอกไม้) แยกจาก Furniture/Decoration/Structure ได้ชัดเจน เป็น Nature และ upload animated spritesheet สำหรับ Phaser.js animation

### Nature Object ต่างจาก Decoration อย่างไร

| Property | Decoration | Nature |
|---|---|---|
| Animation | ไม่มี (static sprite) | มี (animated spritesheet) |
| Collision | กำหนดได้ | Walkable เสมอ |
| Weather reaction | ไม่มี | intensity เปลี่ยนตาม wind |
| Interaction | ไม่มี | Hover/Click shake + particle |
| Frame config | ไม่มี | frame_count, frame_rate ต่อ anim state |

---

## Nature Types ที่รองรับ

| nature_type | ชื่อไทย | Size | Animation States |
|---|---|---|---|
| `big_tree` | ต้นใหญ่ | 3×4 tiles | idle, sway_light, sway_strong |
| `pine_tree` | ต้นสน | 2×3 tiles | idle, sway_light, sway_strong |
| `bush` | พุ่มไม้ | 1×1 tile | idle, sway_light |
| `shedding_tree` (ClickUp เดิมเขียน `sakura_tree` — เลิกใช้แล้ว) | ต้นซากุระ | 2×3 tiles | idle, sway_light, sway_strong, `falling` (ClickUp เดิมเขียน `petal_fall` — เลิกใช้แล้ว) |
| `bamboo` | ไผ่ | 1×3 tiles | idle, sway_light, sway_strong |
| `flower_bush` | ไม้ดอก | 1×1 tile | idle, sway_light |
| `custom` | กำหนดเอง | Admin ตั้ง | Admin กำหนด |

---

## Scenario Index (9 subtasks)

| # | Scenario | Type | Priority | ClickUp status | ClickUp |
|---|---|---|---|---|---|
| HP-01 | List Nature Objects ทั้งหมด | Happy Path | High | in progress | [86d446fyk](https://app.clickup.com/t/86d446fyk) |
| HP-02 | สร้าง Nature Object ใหม่ | Happy Path | High | in progress | [86d446g2z](https://app.clickup.com/t/86d446g2z) |
| HP-03 | Upload Animated Spritesheet ต่อ Animation State | Happy Path | High | in progress | [86d446g8p](https://app.clickup.com/t/86d446g8p) |
| ~~HP-04~~ | ~~ตั้งค่า Animation Config (Frame, Speed, Weather Intensity)~~ — **PM ถอดออกจากตาราง Subtasks ของ main task แล้ว (2026-09-16)** | Happy Path | High | **Closed** (2026-09-03) | [86d446gcn](https://app.clickup.com/t/86d446gcn) |
| HP-05 | Preview Nature Animation | Happy Path | Normal | in progress | [86d446ghj](https://app.clickup.com/t/86d446ghj) |
| HP-06 | แก้ไข Nature Object | Happy Path | Normal | in progress | [86d446gmh](https://app.clickup.com/t/86d446gmh) |
| HP-07 | Hide / Delete Nature Object | Happy Path | Normal | in progress | [86d446gtw](https://app.clickup.com/t/86d446gtw) |
| EP-01 | Upload Spritesheet ไม่ผ่าน Validation | Error Path | Normal | in progress | [86d446gxw](https://app.clickup.com/t/86d446gxw) |
| EC-01 | Nature Object ที่วางบน Map อยู่แล้วเมื่อ Admin แก้ไข Sprite | Edge Case | Normal | in progress | [86d446h2c](https://app.clickup.com/t/86d446h2c) |

> HP-04 ถูก mark **Closed** ใน ClickUp (2026-09-03) — ผู้ใช้ยืนยันแล้ว (2026-09-16) ว่าปิดถูกต้อง และ **PM ถอด HP-04 ออกจากตาราง Subtasks ของ main task ในรอบที่ 2 (2026-09-16)** = **descoped** ไม่ใช่ "ทำเสร็จแล้ว" (ตรวจโค้ดแล้วไม่มี table/field/UI รองรับ — ดู technical-design + ux-ui-plan §5) · เนื้อหายังเก็บไว้ครบด้านล่างเป็น reference เพราะ HP-05 preview ยังอ้าง wind threshold ชุดนี้

---

## รอบที่ 3 — 2026-09-17 (status เปลี่ยนเป็น in progress)

ดึงใหม่ 2026-09-17 ~10:36 (main task `date_updated` 1789616192905) เทียบกับรอบที่ 2 (2026-09-16 ~11:09):

| Task | เปลี่ยน | รายละเอียด |
|---|---|---|
| Main `86d446fw1` | **status** | `pending` → **`in progress`** · description **ไม่เปลี่ยนเลย** — ตาราง Nature Types ยังเขียน `petal_fall` ในคอลัมน์ Animation States ทั้งที่ HP-03 แก้เป็น `shedding_tree` แล้ว (ยังต้องขอ PM แก้ให้เป็น `falling`) · watchers ยัง 4 |
| HP-01, HP-02, HP-03, HP-05, HP-06, HP-07, EP-01, EC-01 | **status** | `pending` → **`in progress`** ทั้ง 8 ตัว (timestamp ไล่กันภายใน ~20 วินาที = PM กดเปลี่ยนรวดเดียว) · **description เหมือนรอบที่ 2 ทุกตัวอักษร** |
| HP-04 `86d446gcn` | — | ยัง **`Closed`** · `date_updated` เท่าเดิม (1788430517937) · ยังไม่อยู่ในตาราง Subtasks ของ main = **descoped เหมือนเดิม** |
| Comments | — | **ไม่มี comment ใหม่** — ยังมีแค่ comment เดิมบน HP-03 (`sakura_tree > shedding_tree / petal_fall > falling`) |

### ความหมายต่อการทำงาน

- **สถานะ = เปิดงานให้เริ่ม แต่ spec ยังไม่ครบ** — การเปลี่ยนเป็น `in progress` ไม่ได้ตอบคำถามที่ค้างไว้ · ข้อขัดแย้ง Figma ↔ spec **12 ข้อที่กระทบ schema/API/flow** ใน [ux-ui-plan §14.1](ux-ui-plan.md#141-ต้องตัดสินก่อนเริ่มโค้ด-กระทบ-schema--api--flow) **ยังเปิดอยู่ทุกข้อ** (required states = idle ตัวเดียวหรือ 3 ตัว · ชื่อ state ที่ 3 · frame_count/frame_rate เก็บระดับไหน · มี `custom` ไหม · status default · preview controls · ข้อ 14a "สี/ประเภท box") — ลงมือทำ migration ก่อนได้คำตอบ = เสี่ยงต้องรื้อ
- **งานที่เริ่มได้ทันทีโดยไม่ต้องรอ PM** (ไม่ขึ้นกับข้อขัดแย้งข้างบน): เพิ่ม `"nature"` เข้า object type enum + filter/badge ฝั่ง BE/FE · คอลัมน์ของ `tb_object_animation` เฉพาะที่ทุกฝ่ายตรงกัน (`object_id`, `state`, `sprite_url`, `frame_width/height`) · sentinel errors · และ **test plan** → [test-plan.md](test-plan.md)
- **ยังไม่มีโค้ด implement ใดๆ ในทุก repo** (ยืนยันจากการตรวจโค้ดรอบ 2026-09-16 — ยังไม่มี `tb_object_animation` และยังไม่มี `nature` ใน `validObjectTypes`) → ยังเป็น **planning only** แม้ ClickUp จะขึ้น in progress

---

## รอบที่ 2 — 2026-09-16 (PM update ClickUp)

ดึงใหม่ ~11:09 (main task `date_updated` 1789531761288) เทียบกับรอบแรก ~10:19:

| Task | เปลี่ยน | รายละเอียด |
|---|---|---|
| Main `86d446fw1` | ตาราง Subtasks | **ลบแถว HP-04** ออก (เหลือ 8 แถว: HP-01, 02, 03, 05, 06, 07, EP-01, EC-01) · ส่วนอื่นเหมือนเดิม (ตาราง Nature Types ยังเขียน `petal_fall`) · watchers 3 → 4 |
| HP-03 `86d446g8p` | Scenario Steps | ข้อ "Admin กด upload บน state ที่ต้องการ" ย้ายไปเป็น sub-bullet ใต้ "Optional states" และเปลี่ยนคำเป็น **"Admin กดปุ่ม upload เพื่อ upload บน state ที่ต้องการ"** → step ที่เหลือเลื่อนเลขเป็น 3–6 |
| HP-03 | ตาราง Required | `sakura_tree` → **`shedding_tree`** (ตาม comment ของ P A) — แต่คอลัมน์ Optional ยัง **`petal_fall`** ไม่ได้แก้เป็น `falling` |
| HP-03 | AC ใหม่ | **"กดปุ่ม Upload แล้วแสดง Modal เพื่อน upload ไฟล์รูปแต่ละ state"** → ยืนยันว่า Animation Manager เป็น **modal** ไม่ใช่หน้าแยก (ตรง Figma) |
| HP-03 | AC แก้ | "Object Status" บอก: **"X/Y required states idle " หาก state ไหนไม่ได้ upload ตอน preview ให้แสดง เป็น idle** (เดิม: "X/Y required states ครบ") → preview ต้อง fallback ไป idle สำหรับ state ที่ยังไม่มีไฟล์ |
| HP-03 | AC ใหม่ | **"หลังบันทึกสามารถกำหนดสีและประเภทของ box object ได้"** → ตรง Figma ที่มี hitbox toolbar/colour dot ใน Object Preview หลัง save — **แต่ขัดกับ HP-02 "Collision: fixed = walkable ไม่แสดงใน form"** ถ้า "ประเภท box" = blocked/walkable ต้องถาม PM |
| HP-05 `86d446ghj` | Scenario step 1 | "Admin กด Preview บนหน้า Animation Manager" → **"Admin กด Preview บนหน้า Upload แล้วแสดง popup"** (ตรง Figma: preview เป็น modal เปิดจาก Upload) |
| HP-05 | ลบ | **ASCII block "Ex. Preview Panel Layout" ถูกลบทั้งก้อน** (ที่มี Simulate Weather / Current State / Animation States buttons / Playback) — แต่ **Acceptance Criteria ยังคงข้อ State buttons, Current State label, Playback controls ไว้เหมือนเดิม** → ยังขัด Figma อยู่ |
| HP-06 `86d446gmh` | — | `date_updated` เปลี่ยนเป็น ~11:02 แต่ description **เหมือนรอบแรกทุกตัวอักษร** (อาจแก้แล้ว undo หรือแก้ field ที่ไม่ใช่ description) |
| HP-04, HP-01, HP-02, HP-07, EP-01, EC-01 | — | `date_updated` เท่าเดิม ไม่เปลี่ยน |
| Comments | — | ยังมีแค่ comment เดิมบน HP-03 (`sakura_tree > shedding_tree / petal_fall > falling`) |

**ผลต่อเอกสารอื่น:** ux-ui-plan §14.1 ข้อ 4 (HP-04) ปิดได้ · ข้อ 6 (redirect vs modal) ปิดได้สำหรับ HP-03/05 แต่ HP-02 ยังเขียน "redirect ไป Animation Manager" อยู่ (stale) · ข้อ 11 (preview controls) ยังเปิด · เพิ่มคำถามใหม่เรื่อง "สี/ประเภท box object" vs always-walkable (กระทบ technical-design §3 ที่ออกแบบว่า Nature **ไม่มี** `object_compositions` row)

---

# Subtask Detail (ถอดครบทุก task ตามต้นฉบับ ClickUp)

## HP-01 · List Nature Objects ทั้งหมด

**Type:** Happy Path · **Persona:** System Admin · **Priority:** High
**Pre-condition:** Admin เข้าหน้า Object Management

### Scenario Steps

1. Admin เข้า Object Management → กด Tab **"Nature"**
2. แสดง grid ของ Nature objects ทั้งหมด
3. แต่ละ card: animated thumbnail preview (ใบสั่นเล็กน้อย), ชื่อ, nature_type badge, animation state count, status
4. Filter, search, sort ตามปกติ

### Acceptance Criteria

- Menu "Nature" แสดงใน Object Management ถัดจาก menu อื่น
- Thumbnail: animated GIF หรือ loop animation preview (ไม่ใช่ static)
- Badge: nature_type (big_tree / pine_tree / ฯลฯ)
- "X states": จำนวน animation states ที่ upload ครบแล้ว / required ทั้งหมด
- Status badge: ✅ Active / 🚫 Hidden
- Filter: All / Active / Hidden / nature_type
- Search: ค้นหาชื่อ object
- Sort: ใหม่สุด / ชื่อ A-Z / ใช้มากสุด (workspace usage count)

### UX/UI

[Figma — node 5008-246597](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=5008-246597&t=okyGm4FNbcCs9sTo-0)

---

## HP-02 · สร้าง Nature Object ใหม่

**Type:** Happy Path · **Persona:** System Admin · **Priority:** High
**Pre-condition:** Admin กด "+ สร้าง Nature Object ใหม่"

### Scenario Steps

1. Admin กด **"+ สร้าง Nature Object ใหม่"**
2. กรอก metadata พื้นฐาน
3. กด "บันทึก" → สร้าง object record
4. redirect ไปหน้า Animation Manager เพื่อ upload sprites (HP-03)

### Acceptance Criteria

- ชื่อ: required, max 100 ตัวอักษร, unique ใน category nature
- Nature Type: dropdown 7 ตัวเลือก (รวม custom)
- Z-index: กำหนด layer
- Collision: **fixed = walkable** ไม่แสดงใน form (nature เสมอ walkable)
- Status default: Hidden (ต้อง upload sprites ก่อน active)
- "บันทึกและตั้งค่า Animation": redirect ไปหน้า Animation Manager

### UX/UI

[Figma — node 5167-320033](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=5167-320033&t=okyGm4FNbcCs9sTo-0)

---

## HP-03 · Upload Animated Spritesheet ต่อ Animation State

**Type:** Happy Path · **Persona:** System Admin · **Priority:** High
**Pre-condition:** Nature Object สร้างแล้ว เข้าหน้า Animation Manager

### Scenario Steps

1. Admin เข้าหน้า **Animation Manager** ของ Nature Object นั้น
2. เห็น animation state slots แบ่งตาม nature_type:
   - Required states (สีแดงถ้ายังไม่ upload)
   - Optional states (สีเทา)
     1. Admin กดปุ่ม upload เพื่อ upload บน state ที่ต้องการ *(รอบที่ 2: ย้ายมาเป็น sub-bullet + เปลี่ยนคำ — เดิมเป็น step 3 "Admin กด upload บน state ที่ต้องการ")*
3. Upload PNG spritesheet: horizontal strip (frame 1 | frame 2 | ...)
4. กรอก frame_count และ frame_rate
5. Preview animation loop บน canvas ก่อน save
6. กด "บันทึก" → spritesheet พร้อมใช้

### Required Animation States ต่อ Nature Type

> ชื่อ nature_type/state ยืนยันแล้ว: `shedding_tree` / `falling` · **รอบที่ 2 (2026-09-16): ClickUp แก้ `sakura_tree` → `shedding_tree` ในตารางนี้แล้ว แต่ Optional ยังเขียน `petal_fall`** — ยึด `falling` ตามที่ยืนยันกับผู้ใช้

| nature_type | Required | Optional |
|---|---|---|
| big_tree | idle, sway_light, sway_strong | — |
| pine_tree | idle, sway_light, sway_strong | — |
| bush | idle, sway_light | — |
| shedding_tree | idle, sway_light, sway_strong | falling |
| bamboo | idle, sway_light, sway_strong | — |
| flower_bush | idle, sway_light | — |

### Spritesheet Spec

```
Format: PNG, transparent background
Layout: horizontal strip (frame left → right)

frame_width = image_width / frame_count
frame_height = image_height (ไม่ split แนวตั้ง)

ตัวอย่าง big_tree idle (8 frames × 64px):
  image_width  = 512px (8 × 64)
  image_height = 96px  (สูงกว่า grid เพราะต้นใหญ่)
  frame_count  = 8
  frame_rate   = 12 fps
  → frame_width = 64px ✅
```

### Acceptance Criteria

- Animation state slots แสดงแบ่ง Required / Optional
- **(ใหม่ รอบที่ 2)** กดปุ่ม Upload แล้วแสดง Modal เพื่อน upload ไฟล์รูปแต่ละ state
- Required state ที่ยังไม่ upload: badge 🔴 + label "Required"
- Upload PNG: max 2MB, transparent background
- กรอก frame_count (1–64) และ frame_rate (4–24 fps) **Fix**
- Validate: image_width ÷ frame_count ต้องลงตัว
- Preview canvas: loop animation ทันทีหลัง upload
- **(แก้ รอบที่ 2)** "Object Status" บอก: "X/Y required states idle " หาก state ไหนไม่ได้ upload ตอน preview ให้แสดง เป็น idle *(เดิม: "X/Y required states ครบ")*
- ครบ required states ทั้งหมด: อนุญาต set status = Active
- ไม่ครบ: ปุ่ม Active disabled + tooltip "กรุณา upload required states ให้ครบก่อน"
- **(ใหม่ รอบที่ 2)** หลังบันทึกสามารถกำหนดสีและประเภทของ box object ได้ *(⚠️ ถ้า "ประเภท" = blocked/walkable จะขัด HP-02 "nature เสมอ walkable" — ต้องถาม PM)*

### UX/UI

[Figma — node 5184-334464](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=5184-334464&t=okyGm4FNbcCs9sTo-0)

### 💬 Comment (P A, 2026-08-24 17:41)

> sakura_tree > shedding_tree
> petal_fall > falling

---

## HP-04 · ตั้งค่า Animation Config (Frame, Speed, Weather Intensity)

**Type:** Happy Path · **Persona:** System Admin · **Priority:** High · **สถานะ ClickUp:** Closed (2026-09-03)
**Pre-condition:** Upload spritesheet ไว้แล้วอย่างน้อย 1 state

### Scenario Steps

1. Admin กด animation state ที่ต้องการตั้งค่า
2. Config panel เปิด ทางขวา
3. Admin ตั้งค่า:
   - frame_count, frame_rate (กรอกได้)
   - wind_threshold_kmh: state นี้เปิดใช้เมื่อลมถึงกี่ km/h
   - base_intensity_multiplier: ความแรง animation ที่ default
4. Preview อัปเดต real-time เมื่อเปลี่ยน config
5. กด "บันทึก"

### Wind Threshold Guidelines

| State | Recommended Threshold |
|---|---|
| idle | 0 km/h (เสมอ) |
| sway_light | ≥ 10 km/h |
| sway_strong | ≥ 30 km/h |
| falling | 0 km/h (เสมอ สำหรับ `shedding_tree`) |

### Acceptance Criteria

- frame_count: 1–64, validate หารด้วย spritesheet width ลงตัว
- frame_rate: 4–24 fps
- wind_threshold_kmh: 0–200 km/h (0 = เปิดเสมอ)
- base_intensity_multiplier: 0.1–5.0 (decimal)
- Preview canvas อัปเดต real-time ทันทีที่เปลี่ยน config
- Preview speed slider: 0.25x / 0.5x / 1.0x / 1.5x / 2.0x
- "Reset to defaults": คืน config เป็นค่า recommended ตาม state name

> **หมายเหตุ:** subtask นี้ถูกปิด (Closed) ใน ClickUp — **ผู้ใช้ยืนยันแล้วว่าปิดถูกต้อง** แต่ยังไม่ได้ verify กับโค้ดจริงว่า field/behavior ครบตาม Acceptance Criteria หรือยัง — ควรตรวจก่อนเริ่ม task อื่นที่ depend on this (HP-05 preview ใช้ config ชุดนี้)

---

## HP-05 · Preview Nature Animation

**Type:** Happy Path · **Persona:** System Admin · **Priority:** Normal
**Pre-condition:** Upload spritesheet ไว้แล้วอย่างน้อย 1 state

### Scenario Steps

1. Admin กด **"Preview"** บนหน้า Upload แล้วแสดง popup *(แก้ รอบที่ 2 — เดิม: "บนหน้า Animation Manager")*
2. Preview canvas แสดง nature object animated บน background เหมือน Virtual Office
3. Admin simulate weather เพื่อดู animation เปลี่ยน:
   - ลากปรับ wind speed slider → animation intensity เปลี่ยน
   - เลือก weather condition → เห็น state transition
4. Admin switch ดู states ต่างๆ

### Ex. Preview Panel Layout

> ⚠️ **PM ลบ block นี้ออกจาก ClickUp แล้วในรอบที่ 2 (2026-09-16)** — เก็บไว้ในเอกสารนี้เป็นประวัติเท่านั้น อย่าใช้เป็น spec · แต่ Acceptance Criteria ด้านล่าง (State buttons / Current State / Playback) **ยังอยู่ใน ClickUp** ไม่ได้ลบตาม

```
Preview — ต้นมะม่วงใหญ่

┌──────────────────────────────────────┐
│                                      │
│         🌳 (animated)                │
│                                      │
│    [Floor tile background]           │
└──────────────────────────────────────┘

Simulate Weather:
  Wind:  [━━━━━●━━━━━] 25 km/h
  Condition: [Rain ▼]  Clear/Cloudy/Rain/Storm

Current State: sway_light (auto-selected by wind 25 km/h)

Animation States:
  [idle] [sway_light ✓] [sway_strong]

Playback: [⏮] [⏸/▶] [⏭]  Speed: [1.0x ▼]
```

### Acceptance Criteria

- Preview canvas: แสดง animation บน floor tile background (เหมือน Virtual Office จริง)
- Wind slider: 0–100 km/h → เปลี่ยน animation state อัตโนมัติตาม threshold
- Weather condition dropdown: เปลี่ยน visual (rain overlay, tint) บน preview
- State buttons: คลิกบังคับดู state นั้นๆ ได้
- "Current State" label: บอก state ที่กำลังเล่น + เหตุผล (เช่น "auto: wind 25 km/h ≥ 10")
- Playback controls: pause/resume, step frame, speed multiplier
- Preview ไม่มีผลต่อ production — เป็น read-only simulation

### UX/UI

[Figma — node 5196-368373](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=5196-368373&t=okyGm4FNbcCs9sTo-0)

---

## HP-06 · แก้ไข Nature Object

**Type:** Happy Path · **Persona:** System Admin · **Priority:** Normal
**Pre-condition:** Nature object มีอยู่แล้ว

> รอบที่ 2: ClickUp `date_updated` เปลี่ยนเป็น 2026-09-16 ~11:02 แต่ description **ไม่ต่างจากรอบแรก** — ไม่มีอะไรต้องแก้ในส่วนนี้

### Scenario Steps

1. Admin กด "แก้ไข" บน Nature object card
2. แก้ไข metadata: ชื่อ, nature_type, grid_size, status
3. หรือเข้าหน้า Animation Manager เพื่อ replace/update spritesheet
4. กด "บันทึก"

### Acceptance Criteria

- แก้ไขได้: ชื่อ, grid_width, grid_height, status, z-index
- **Category, nature_type เปลี่ยนไม่ได้** หลังสร้าง (เพราะ required states ต่างกัน) — แสดง read-only + tooltip
- ยกเว้น: ถ้ายังไม่มี animation state ใดๆ → เปลี่ยน nature_type ได้ (ยังว่าง)
- Replace spritesheet: upload ใหม่แทนของเดิมในแต่ละ state
- Workspace ที่วาง object นี้แล้ว: sprite อัปเดตใน Virtual Office **ทันทีหลัง hot reload**
- Audit log: บันทึกทุกการแก้ไข

### UX/UI

[Figma — node 5219-753640](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=5219-753640&t=okyGm4FNbcCs9sTo-0)

---

## HP-07 · Hide / Delete Nature Object

**Type:** Happy Path · **Persona:** System Admin · **Priority:** Normal
**Pre-condition:** Nature object มีอยู่แล้ว

### Scenario Steps — Hide

1. Admin เปลี่ยน status → Hidden
2. Nature object หายออกจาก Object Library ของ user
3. Map ที่วาง object นี้ไว้แล้ว: **ยังแสดงต่อ** (ไม่ลบออกจาก placed_objects)
4. Admin และ Workspace Admin เห็น object ยังอยู่ใน Map Editor พร้อม badge "(Hidden)"

### Scenario Steps — Delete

1. Admin กด "ลบ"
2. Confirmation: "Object นี้ถูกวางใน X workspace — หากลบจะหายออกจาก map เหล่านั้น"
3. Admin Confirm → soft delete
4. Placed_objects ที่ reference object นี้: **ลบออกจาก map ทันที + hot reload**
5. Hard delete: storage assets ลบหลัง 30 วัน

### Acceptance Criteria — Hide

- Object หายจาก Object Library ทันที
- Map ที่วางไว้แล้ว: ยังแสดง nature object ต่อ (ไม่ลบ)
- Map Editor: แสดง "(Hidden)" badge บน placed nature object
- Workspace Admin วางใหม่ไม่ได้ (ไม่อยู่ใน Library)

### Acceptance Criteria — Delete

- Confirmation แสดง workspace count ที่ได้รับผลกระทบ
- ถ้า placed_objects_count > 0: ต้องพิมพ์ชื่อ object ยืนยัน
- Soft delete: ลบ placed_objects ที่ reference → hot reload ทุก workspace ที่มี object นั้น
- Hard delete: cron job หลัง 30 วัน

### UX/UI

[Figma — node 5219-761384](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=5219-761384&t=okyGm4FNbcCs9sTo-0)

---

## EP-01 · Upload Spritesheet ไม่ผ่าน Validation

**Type:** Error Path
**Trigger:** Admin upload spritesheet ที่ไม่ถูกต้องใน Animation Manager

### Error Cases

| Case | Message | Trigger |
|---|---|---|
| ไม่ใช่ PNG | "รองรับเฉพาะ PNG" | `file.type ≠ image/png` |
| เกิน 2MB | "ขนาดไฟล์เกิน 2 MB (ไฟล์ของคุณ: X.X MB)" | `size > 2MB` |
| frame_count ผิด | "Frame count ต้องอยู่ระหว่าง 1–64" | `< 1` หรือ `> 64` |
| frame_rate ผิด | "Frame rate ต้องอยู่ระหว่าง 4–24 fps" | `< 4` หรือ `> 24` |
| Width ไม่ลงตัว | "Width ({W}px) ต้องหารด้วย frame_count ({N}) ลงตัว — frame width = {W/N}px" | `W % N ≠ 0` |
| ไม่มี transparency | "แนะนำ PNG ที่มี transparent background" | warning ไม่ใช่ error |

### Acceptance Criteria

- Validate client-side ทันทีที่เลือกไฟล์
- Frame size preview: แสดง "frame size = {W/N} × {H} px" หลังกรอก frame_count
- Width ไม่ลงตัว: error แสดงทันทีเมื่อกรอก frame_count
- Warning transparency: สีเหลือง ไม่บล็อก upload
- Server magic bytes validate: PNG signature `89 50 4E 47`
- Error หายเมื่อ user แก้ค่าให้ถูกต้อง

### UX/UI

[Figma — node 5230-775889](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=5230-775889&t=okyGm4FNbcCs9sTo-0)

---

## EC-01 · Nature Object ที่วางบน Map อยู่แล้วเมื่อ Admin แก้ไข Sprite

**Type:** Edge Case
**Trigger:** Admin replace spritesheet ของ nature object ที่วางอยู่ใน workspaces แล้ว

### Scenario

```
"ต้นมะม่วงใหญ่" ถูกวางใน 15 workspaces
Admin replace sway_light.png ด้วยไฟล์ใหม่ที่ปรับ animation แล้ว
→ Workspaces ที่วางต้นไม้นี้ได้รับผลกระทบ
```

### Acceptance Criteria

- Replace sprite: Admin เห็น warning "Object นี้ถูกวางใน 15 workspaces — sprite ใหม่จะมีผลทันที"
- หลัง replace: CDN cache invalidate (URL เพิ่ม `?v={version}`)
- Virtual Office ที่วาง object นี้: **โหลด sprite ใหม่อัตโนมัติ** เมื่อ user enter map หรือ hot reload
- Animation config (frame_count, frame_rate) เปลี่ยนได้ — มีผลทันทีผ่าน hot reload
- Users ที่กำลัง online ใน Virtual Office: เห็น sprite อัปเดตภายใน **30 วินาที** (หลัง CDN invalidate)
- ไม่มี visual glitch: transition จาก sprite เก่าไปใหม่ smooth (fade out → fade in)
- Placed objects ที่ใช้ config เดิม: inherit config ใหม่จาก object definition อัตโนมัติ

### UX/UI

[Figma — node 5230-791935](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=5230-791935&t=okyGm4FNbcCs9sTo-0)

---

## Open Questions / ต้องเคลียร์ก่อน implement

1. ~~**Naming**: ยืนยันกับ PM ว่าจะใช้ `shedding_tree` / `falling` แทน `sakura_tree` / `petal_fall` หรือไม่~~ — **✅ ยืนยันแล้ว (2026-09-16): ใช้ `shedding_tree` / `falling`** ทั้งใน DB schema, API contract — **ยังต้อง sync ชื่อ node ใน Figma ให้ตรงก่อน implement** (ยังไม่ตรวจว่า Figma แก้ตามแล้วหรือยัง)
2. ~~**HP-04 status**: ทำไม subtask นี้ถูกปิด (Closed) ทั้งที่ยังไม่มี PR/commit ที่เกี่ยวข้องใน repo~~ — **✅ ยืนยันแล้ว (2026-09-16): ปิดถูกต้อง** ไม่ต้องขอ PM เปิดกลับ — แต่ **ยังไม่ verify กับโค้ดจริง** ว่า field/behavior ครบตาม Acceptance Criteria หรือยัง ควร grep/ตรวจโค้ดก่อนเริ่ม HP-05 ที่ depend on this
3. ~~**DB/Schema สำหรับ Nature object**: ต้องออกแบบ schema ใหม่~~ — **✅ ทำแล้ว (2026-09-16): ดู [technical-design.md](technical-design.md)** — `tb_object.nature_type` + ตารางใหม่ `tb_object_animation` (ต้นแบบจาก `tb_pet_animation`), API contract, realtime broadcast plan และ task breakdown ครบ · ยังเหลือ open items 4 ข้อท้ายไฟล์นั้นที่ต้องถาม PM ก่อน implement จริง (สี badge, per-placement override, broadcast fan-out, wind ผูกกับ environment feature จริงหรือ preview-only)
4. **Object Management เดิม**: nature tab นี้ต่อยอดจาก Object Management (Admin) module เดิมที่มีอยู่แล้ว — ต้องตรวจโครงสร้างโค้ดปัจจุบันของ object management ก่อนออกแบบ schema/route ใหม่ ว่า pattern เดิมเป็นอย่างไร (ตาม [[09-component-reuse]])
