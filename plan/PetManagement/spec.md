# Pet Management Module (Admin) — Spec

> ดึงข้อมูลจาก ClickUp — Space: Zyra World, List: `901614367195`
> Parent Task: [\[Module\] Pet Management](https://app.clickup.com/t/86d3dcbra) (`86d3dcbra`)

> **อัปเดต 2026-08-14** — แก้ตามคำตอบ PM ที่ปิดแล้ว (ดู [pm-discussion-notes.md](pm-discussion-notes.md)): 4-stage model, mood 3-state, XP sources 10 activities, max dimension, pagination
>
> **อัปเดต 2026-08-17 — ✅ ปิดครบทุกจุด ไม่มี blocker เหลือ** 2 จุดที่เคย mark 🔴 ถูกเคาะแล้ว:
> - **SC-PM-03 — animation slot**: **ยึด Figma** — 1 slot = 1 ไฟล์ที่รวมทุก direction (spritesheet เป็น **grid**) slot vocabulary = `Wobbling`/`Walking`/`Sitting`/`Happy`/`Sad`/`Evolution`
> - **SC-PM-05 — flow assign pet**: **Map Editor drag-drop** ตัด tab "Assign to Room" ตั้งชื่อตอนวาง
>
> **อัปเดต 2026-09-01 — แก้ 26 จุดที่ UI ทำงานไม่ได้จริง/ขัดกันเอง + ล็อกกฎ sprite grid จาก asset จริง**
> - ทุกคอนโทรลระบุครบ 3 อย่าง: **enable เมื่อไร · กดแล้วเกิดอะไร · ค่าที่ยอมรับเท่าไร**
> - กฎ sprite เขียนใหม่จากไฟล์จริง `zyra-app/public/image/petdemo/Cat_Adult_Happy.png` — กฎเดิม (`width % frame_count = 0`, `frame_height = height / direction_rows`) **reject/ตัดสไปรต์ของ artist เอง**
> - ปิดข้อ ⏸ `direction_rows` + ลำดับแถว (มี sprite จริงแล้ว)
> - ที่มา: [progress-2026-08-31.md](progress-2026-08-31.md) · [code-findings-2026-08-31.md](code-findings-2026-08-31.md) · UI audit ของ [ux-ui.md](ux-ui.md)
>
> **อัปเดต 2026-09-02 — PM เคาะ: slot `Evolution` ต้องอัปโหลดเป็น GIF เท่านั้น** (ไม่ใช่ PNG spritesheet) — เมื่อ pet ถึง threshold จะเข้า "สถานะ evo" ของช่วงวัยนั้นแล้วเล่น GIF นี้ · ส่วน **ไข่แตก (egg → baby) ใช้ GIF กลางตัวเดียวทุก pet type** ที่อัปขึ้น R2 แล้ว (`static/pet/shared/egg-evolution.gif`) → ดู [SC-PM-03 § Evolution = GIF](#evolution-slot--gif-เท่านั้น-2026-09-02) · **ยืนยันแล้ว: egg และ evolved ยังต้องมี slot `Evolution`** → required slot คง **17** ไม่เปลี่ยน
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

## Pet Category — 9 ค่า (single source)

**ทุกที่ที่แสดง category ต้องอ่านจากลิสต์เดียวกันนี้** — filter submenu ใน Pet Library, dropdown ตอนสร้าง/แก้ pet, badge บน card ห้าม hardcode แยกกัน

| value (DB / API) | Label (EN) |
|---|---|
| `buffalo` | Buffalo |
| `bird` | Bird |
| `cat` | Cat |
| `dog` | Dog |
| `elephant` | Elephant |
| `exotic` | Exotic Pets |
| `fish` | Fish & Aquatic |
| `reptile` | Reptile |
| `small` | Small Pets |

> **เดิม filter submenu ใน Figma มี 8 ตัว (ไม่มี `Buffalo`) แต่ dropdown มี 9** → pet ที่ category = `buffalo` สร้างได้แต่กรองไม่เจอ ต้องใช้ 9 ค่านี้ทั้งสองที่
> ลิสต์เก่าใน spec นี้ (`dragon`, `bunny`, `custom`) **ไม่มีอยู่จริงในระบบ** — ตกไปแล้ว

---

## SC-PM-01 · List Pet Types ทั้งหมด

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Admin เข้าหน้า Pet Management

### Scenario Steps
1. Admin เข้าหน้า Pet Management
2. แสดง Pet Type Library: การ์ดเรียงเป็นลิสต์แนวตั้งในพาเนลซ้าย
3. แต่ละ card แสดง: thumbnail (ภาพนิ่ง), ชื่อ, category badge, จำนวน stage ที่พร้อมใช้, status badge, workspace usage count
4. Filter / search / sort
5. กด Pet card → พาเนลขวาแสดงรายละเอียดแบบอ่านอย่างเดียว

### Acceptance Criteria

**ลิสต์ + pagination**
- Pagination default **10/หน้า** · dropdown ให้เลือก `10 / 20 / 50` (cap ฝั่ง API = 100)
- **FE ต้องส่ง `limit` ทุก request เสมอ** — API default = 20 ถ้าไม่ส่งจะได้ 20 เงียบ ๆ ไม่ตรงกับที่ UI แสดง

**Pet card**
- Thumbnail **ภาพนิ่ง** 80×80 (ไม่ใช่ animated preview) — source ตามลำดับ: เฟรมแรกของ `Evolved > Walking` → ถ้าไม่มี ใช้ไฟล์แรกที่อัปโหลด
- ชื่อ pet · category badge (ตามตาราง 9 ค่า) · status badge (Active/Hidden)
- **`stage_ready X/4`** — จำนวน stage ที่ animation ครบ **ห้ามแสดง "4 stages" ตายตัว** เพราะทุก pet มี 4 stage เท่ากันอยู่แล้ว ตัวเลขจะไม่มีความหมาย
- Badge วงกลมมุมขวาบน = `workspace_usage_count` (จำนวนห้องที่ pet type นี้ถูกวาง)

**Filter / Search / Sort**
- Filter: status (`active` / `hidden`) + category (**9 ค่าตามตารางด้านบน**)
- Search: ชื่อ pet type — **debounce 300ms** ห้ามยิง request ทุกตัวอักษรที่พิมพ์
- Sort: `name` · `created_at` · `usage_count`
  - ⚠️ **`usage_count` ต้องซ่อน (ไม่แสดงเป็นตัวเลือก) จนกว่า SC-PM-05 จะ live** — ตอนนี้ยังไม่มีจุดไหนในระบบเขียนค่า `workspace_usage_count` ทุกตัวเป็น 0 กดแล้วลำดับไม่เปลี่ยน = ตัวเลือกที่กดได้แต่ไม่มีผล
  - ด้วยเหตุผลเดียวกัน badge ตัวเลขบน card จะเป็น 0 ทั้งหมดจนกว่า placement จะ live (ยังแสดงได้ ไม่ต้องซ่อน)

**Detail view (เลือก pet แล้ว)**
- เป็น **สรุปแบบอ่านอย่างเดียว** — แสดงชื่อ / category / status / description / `stage_ready X/4` / animation ที่มีต่อ stage
- **ห้ามมี stepper ของ wizard และห้ามมี toggle Status ในโหมดนี้** (ใช้ badge แทน) — คอนโทรลที่ดูกดได้แต่ไม่ควรกดในหน้าอ่านข้อมูล
- ปุ่มที่มีได้: `Delete` (แดง) และ `Edit` (เขียว — เข้าสู่ wizard โหมดแก้ไข)

**ปุ่ม Add**
- ปุ่ม `+` ที่ header และปุ่ม `+ Add pet` ใน empty state ทำงานอย่างเดียวกัน
- **ขณะฟอร์ม Add/Edit เปิดอยู่ ปุ่ม Add ต้อง disabled** (กดซ้ำแล้วข้อมูลที่กรอกค้างอยู่ต้องไม่หาย)

### UX/UI Reference
[Figma — node 3997-197036](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3997-197036&t=KrMB68Z63QeG3ccx-0)

---

## SC-PM-02 · สร้าง Pet Type ใหม่

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Admin กด "สร้าง Pet Type ใหม่"

### Scenario Steps
1. **Step 1 — General information**: กรอกชื่อ, category, description (status ยังตั้งไม่ได้ ดูด้านล่าง)
2. กด `Next ›` → ระบบสร้าง Pet Type record (status = `hidden`) แล้วเข้าสู่ **Step 2 — Upload stage & animation** ในฟอร์มเดียวกัน
3. Upload sprite ต่อ slot (ต่อที่ SC-PM-03)
4. เมื่ออัปครบทุก slot → กด `✓ Save` ที่ header → **Step 3 — Complete**

### Acceptance Criteria

**ฟิลด์**
- ชื่อ: required, max 100 ตัวอักษร, unique (case-insensitive), แสดง counter `n/100`
- Category: dropdown จาก **9 ค่า canonical**
- Description: optional
- Status default: **`hidden`**

**Status toggle — ต้องปิดไว้และกดไม่ได้ตอนสร้าง**
- ค่าเริ่มต้นของ toggle คือ **OFF (Hidden)** ไม่ใช่ ON
- toggle **disabled พร้อมข้อความเหตุผล** จนกว่า `stage_ready` จะครบทั้ง 4 stage — ตอนสร้างใหม่ยังไม่มี sprite เลย จึงเปิดไม่ได้แน่นอน
- ถ้าพยายามเปิดตอน stage ยังไม่ครบ: แสดง inline error ที่ toggle ("ต้องอัป animation ครบทุก stage ก่อน") **ห้ามปล่อยให้กด Save แล้วค่อยเด้ง error `PET_NOT_READY` จาก API**
- เดิม Figma วาด toggle เป็น ON/Active เป็นค่า default → ถ้าทำตามนั้น ฟอร์มจะ Save ไม่ผ่านตลอดกาล

**ปุ่มในฟอร์ม — แต่ละปุ่มมีหน้าที่เดียว ห้ามซ้อนกัน**

| ปุ่ม | อยู่ที่ | enable เมื่อ | กดแล้ว |
|---|---|---|---|
| `Next ›` | footer | step 1 และกรอกชื่อ + category ครบ | create (ครั้งแรก) / update draft แล้วไป step 2 |
| `‹ Back` | footer | อยู่ step 2 | กลับ step 1 (ข้อมูลที่กรอกยังอยู่) |
| `✓ Save` | header | **step 2 เท่านั้น** และอัป animation ครบทุก slot | บันทึก + ไป step 3 |
| `✕ Cancel` | header | ตลอด | ปิดฟอร์ม — **ถ้ามีข้อมูลที่ยังไม่บันทึกต้องถามยืนยันก่อน** |

- ที่ step 1 **ต้องไม่มีปุ่ม Save ที่กดได้** (เดิม Save กับ Next enable ด้วยเงื่อนไขเดียวกันแต่ปลายทางต่างกัน จนไม่รู้ว่าอันไหนคือการ commit จริง)

**Step indicator (3 ขั้น)**
1. `General information` — ผ่านเมื่อไป step 2 แล้ว
2. `Upload stage & animation` — ผ่านเมื่ออัปครบทุก slot
3. `Complete` — **state หลังกด Save สำเร็จ**: แสดงสรุป pet ที่สร้าง + ปุ่มกลับ Pet Library (ก่อนหน้านี้ไม่มีการนิยาม ทำให้ขั้นที่ 3 ไปถึงไม่ได้เลย)
- Progress bar ระหว่าง step 2 → 3 ต้องคำนวณจาก `จำนวน slot ที่อัปแล้ว ÷ RequiredSlots.total` **ห้าม hardcode จำนวนขั้นของ bar** (ของเดิมทำตาราง width ไว้ 17 ขั้นแล้วสเกลไม่ตรงกับจำนวน slot จริง)

**Edit mode**
- ใช้ wizard ตัวเดียวกับ create ทุกอย่าง (ไม่มีหน้า Edit แยก)
- โหลดค่าเดิมมาใส่ + แสดง animation ที่อัปไว้แล้วเป็นไฟล์ที่มีอยู่

**หลัง Next สำเร็จ**
- ไป **step 2 (Upload stage & animation) ในฟอร์มเดียวกัน** — ไม่มีหน้า "Stage Manager" แยกให้ redirect ไป

### UX/UI Reference
[Figma — node 4017-33277](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4017-33277&t=KrMB68Z63QeG3ccx-0)

---

## SC-PM-03 · Upload Sprite ต่อ Stage และ Animation

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Pet Type สร้างแล้ว อยู่ step 2 ของ wizard

### Stage Layout
4 stage: **Egg / Baby / Adult / Evolved** — แสดงเป็น **รายการ (list) ในพาเนลซ้าย** ไม่ใช่ tab แนวนอน แต่ละแถวมี count tag `n/N`

> Mood (Happy / Sad) **ไม่ใช่ stage** — เป็น state ที่คำนวณจาก activity (ดู SC-PM-04) โมเดล 6-stage เดิมที่มี `Lonely` / `Happy` เป็น tab ถูกยกเลิกแล้ว

### Animation Slots ต่อ Stage — ✅ ปิดแล้ว (ข้อ 2, ยึด Figma)

**1 slot = 1 ไฟล์ที่รวมทุก direction** — ตาราง per-direction ใน [SC-PM-03 card](https://app.clickup.com/t/86d3dcc8r) (`walk_n/walk_s/walk_e/walk_w`) ตกไปแล้ว card ยังไม่ถูกแก้

| Stage | Required Slots | Count |
|-------|----------------|-------|
| Egg | `Wobbling`, `Evolution` | 2 |
| Baby | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5 |
| Adult | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5 |
| Evolved | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5 |

**รวมทั้งหมด 17 slot** — ตัวเลขนี้คือของจริง

- **Egg = 2 ไม่ใช่ 3** — counter ใน Figma node #4/#9 โชว์ `3/3` แต่ animation dropdown ของ Egg โชว์แค่ 2 รายการ ([ux-ui.md](ux-ui.md)) → ยึด dropdown, counter เป็น mockup ที่ไม่ sync
- **sidebar tag ที่โชว์ `0/1` และ `0/4` ใน Figma ก็เป็น mockup เก่า** — ค่าที่ถูกคือ `0/2` และ `0/5`
- **Adult / Evolved** ไม่มี frame ใน Figma ที่โชว์ dropdown ตรง ๆ — อนุมานว่าเหมือน Baby
- **Egg → Baby เล่น `Evolution`** (ตอบคำถามเดิมเรื่อง animation ตอนฟักไข่) — **2026-09-02:** slot `Evolution` ของ egg **ยังต้องมี** (PM ยืนยัน) และเป็น GIF · **ระบบ prefill ไฟล์กลาง** `static/pet/shared/egg-evolution.gif` ให้ทุก pet type อัตโนมัติ (slot นี้ถือว่า "พร้อม" ตั้งแต่สร้าง pet type) และ admin **ยังอัป GIF ของตัวเองทับได้** — กลไกดู [§ Prefill egg Evolution](#prefill-egg-evolution-จากไฟล์กลาง-2026-09-02)
- **Happy / Sad เป็น slot ภายใน stage ไม่ใช่ stage แยก** — สอดคล้องกับ mood 3-state ใน SC-PM-04

### Evolution slot = GIF เท่านั้น (2026-09-02)

PM เคาะแล้ว: เมื่อ pet ถึง threshold ของช่วงวัยจะเข้า **สถานะ evo** แล้วเล่น animation ของ slot `Evolution` ของ stage ต้นทาง — ไฟล์นี้ต้อง **อัปโหลดเป็น GIF** (ภาพเคลื่อนไหวจบในตัว) ไม่ใช่ PNG spritesheet เหมือน slot อื่น

| | slot อื่น (`Wobbling` `Walking` `Sitting` `Happy` `Sad`) | slot `Evolution` |
|---|---|---|
| ชนิดไฟล์ | PNG 1000×1000 เท่านั้น | **GIF เท่านั้น** (`GIF87a`/`GIF89a`) — PNG ที่ slot นี้ = `INVALID_FILE_TYPE` |
| `frame_count` / `frame_rate` / `direction_rows` | ต้องกรอก, validate grid | **ไม่มี** — GIF กำหนดเฟรมและความเร็วในไฟล์เอง ฟอร์มต้องซ่อน 3 ช่องนี้ที่ slot `Evolution` |
| `frame_width` / `frame_height` ใน DB | = `floor(1000 ÷ frame_count)` | เก็บ **ขนาดภาพ GIF** (width × height) · `frame_count`/`frame_rate`/`direction_rows` เก็บ `NULL` (ต้องปลด `NOT NULL` + CHECK สำหรับ row ที่เป็น GIF) |
| ขนาดภาพ | = 1000×1000 | **สี่เหลี่ยมจัตุรัส ไม่เกิน 1000×1000** (ไฟล์กลาง egg เป็น 960×960) — ไม่บังคับเท่ากับ 1000 |
| ขนาดไฟล์ | ≤ 1 MB | ≤ 1 MB เท่ากัน (GIF 24 เฟรม 960px ของจริง = 159 KB) — ถ้า artist ส่งเกินให้ขยับเป็น 2 MB **เฉพาะ GIF** ไม่ขยับของ PNG |
| transparency | warning ถ้าไม่มี | ไม่ตรวจ (GIF โปร่งใสแบบ 1-bit) |
| ตอนเล่น | slice grid ตาม frame_* | `<img>` / GifSprite ทับ overlay ตอนเปลี่ยน stage (Roompet SC-PET-04/05) เล่น 1 รอบแล้ว switch sprite |
| การเลื่อนไหวปกติในห้อง | ใช้ | **ไม่ใช้** — GIF ไม่ได้อยู่บน map ปกติ |

- **ทั้ง 4 stage มี slot `Evolution` (PM ยืนยัน 2026-09-02) — required slot คง 17:** **egg → baby** เล่น `Evolution` ของ egg (prefill จากไฟล์กลางบน R2 — หัวข้อถัดไป) · **baby → adult** ใช้ `Evolution` ของ baby · **adult → evolved** ใช้ `Evolution` ของ adult · **evolved** ยังต้องอัป `Evolution` แม้ไม่มีช่วงถัดไป (สำรองไว้ตาม PM — ยังไม่มี consumer ในระบบ; ไม่ต้องเขียนโค้ดเรียก)

### Prefill egg `Evolution` จากไฟล์กลาง (2026-09-02)

**เคาะแล้ว:** slot `Evolution` ของ stage `egg` ได้ไฟล์กลางอัตโนมัติทุก pet type และ admin เลือกอัป GIF ของตัวเองทับได้

**กลไก = fallback ตอนอ่าน ไม่ copy row ลง DB** (ตามหลัก "ค่าที่ derive ได้ ห้ามเก็บ" ใน [db-schema-api-contract.md](db-schema-api-contract.md))

| กรณี | `tb_pet_animation` (egg, Evolution) | API คืน | `stage_ready.egg` |
|---|---|---|---|
| ยังไม่อัปเอง (ค่าเริ่มต้นทุก type) | **ไม่มี row** | `sprite_url` = URL ไฟล์กลาง · `frame_width/height` = 960 · `is_default: true` | นับว่า slot นี้พร้อม → egg พร้อมเมื่ออัป `Wobbling` ครบ |
| admin อัปเอง | มี row (GIF ของ type นั้น) | ของ type นั้น · `is_default: false` | เหมือนเดิม |
| admin ลบไฟล์ที่อัปเอง | ลบ row | **กลับไปไฟล์กลาง** (`is_default: true`) — ไม่มี state "ว่าง" สำหรับ slot นี้ | ยังพร้อม |

- URL ไฟล์กลางเป็น **config ฝั่ง zyra-api** (`PET_EGG_EVOLUTION_DEFAULT_URL`, default = `${AWS_PUBLIC_URL}/static/pet/shared/egg-evolution.gif`) ไม่ hardcode ในโค้ดและไม่ hardcode ใน client — client อ่านจาก response เท่านั้น
- เหตุผลที่ไม่ insert row ตอนสร้าง pet type: เปลี่ยนไฟล์กลางครั้งเดียวมีผลทุก type ทันที · pet type เก่าที่สร้างก่อน feature นี้ได้ default ด้วยโดยไม่ต้อง backfill · ลบไฟล์เองแล้วกลับ default ได้โดยไม่มี edge case row ว่าง
- ใช้กับ **egg เท่านั้น** — baby/adult/evolved ไม่มีไฟล์กลาง ต้องอัปเอง

**UI ใน wizard step 2 (egg → animation `Evolution`)**
- การ์ด upload แสดงสถานะ **`Default`** (badge เทา `#8C99A6`) + preview GIF กลาง แทน empty state · ปุ่มเปลี่ยนจาก `Upload` เป็น `Replace`
- หลังอัปเอง → badge หาย แสดงไฟล์ของ type นั้น · ปุ่ม `Delete` = กลับไป Default (ข้อความยืนยันต้องบอกว่า "จะกลับไปใช้ไฟล์กลาง" ไม่ใช่ "จะลบ animation")
- count tag ของ egg เริ่มที่ `1/2` (Evolution พร้อมแล้ว) · progress bar ของ wizard นับ slot นี้เป็นอัปแล้วตั้งแต่ต้น (17 slot, เริ่มที่ 1)
- Preview modal: dropdown ของ egg มี `Evolution` เล่นได้ทันที (จากไฟล์กลาง)
- ข้อความบนการ์ด: `Default egg hatch animation is shared by all pets. Upload a GIF to use your own.` (i18n en/th)

**สถานะโค้ด:** ยังไม่มี — `stageReadiness` นับจาก row จริงล้วน, response ไม่มี `is_default`, FE ไม่มี state Default บนการ์ด
- ตารางใน [db-schema-api-contract.md § GIF ที่ slot Evolution](db-schema-api-contract.md) มีผลต่อ schema/validation

**สถานะโค้ด ณ 2026-09-02 (ยังไม่ตรง):** `pet_service.go` รับ **ทั้ง PNG และ GIF** ที่ slot `Evolution` (`allowedMimeTypesBySlot`) · GIF ยังถูกส่งเข้า `validatePetSpriteDimensions` (บังคับ ≤1000, `width ≥ frame_count`, `height % direction_rows = 0`) และเก็บ `frame_width = width/frame_count` ซึ่งไม่มีความหมายกับ GIF · FE ยังบังคับกรอก/ล็อก `frame_count 50 / frame_rate 24 / direction_rows 4` ทุก slot รวม `Evolution` · preview modal render GIF ด้วย `<img>` ได้แล้ว (`pet-preview-modal.tsx` `isGif`)
- ⚠️ **ไม่มี slot `Idle`** — โค้ดที่ merge เข้า `develop` แล้วเพิ่ม `Idle` เข้ามาเป็น 20 slot ต้องถอดออก (ดู [§ผลต่อโค้ด](#ผลต่อโค้ด--schema-จากการแก้-spec-รอบนี้-2026-09-01))

**กฎเลข `n/N`**: ตัวเลข required/uploaded ทุกที่ (tag ข้าง stage, dropdown ใน preview modal, progress bar ของ wizard) **ต้อง derive จากตารางนี้แหล่งเดียว** ห้าม hardcode ตัวเลขซ้ำในแต่ละคอมโพเนนต์ — ที่ผ่านมา 3 ที่ใช้เลขคนละชุด (`0/1`+`0/4`, `2`+`5`, `3/3`)

### Sprite Grid — ล็อกจาก asset จริงแล้ว (2026-09-01)

ไฟล์อ้างอิง: `zyra-app/public/image/petdemo/Cat_Adult_Happy.png` (artist ส่งทุกไฟล์มาแบบเดียวกัน)

**ผลวัดจากไฟล์จริง** (bounding box ของทั้ง 24 sprite จาก alpha channel):

```
ขนาดชีท           : 1000 × 1000 px
คอลัมน์ (6 คอลัมน์) : 13-156 · 176-318 · 344-489 · 516-658 · 686-829 · 844-987
แถว    (4 แถว)    : 43-160 · 190-303 · 365-478 · 542-654
พื้นที่ y 655-999   : ว่างทั้งหมด (≈ 2 แถวล่างของ grid)
```

ทดสอบว่า grid ไหนถูก — **ขอบเซลล์ต้องตกในช่องว่างระหว่างสไปรต์เสมอ**:

| Grid ที่ทดสอบ | คอลัมน์ | แถว | ผล |
|---|---|---|---|
| **จัตุรัส `1000 ÷ 6 ≈ 166`** | ขอบ 166 / 332 / 498 / 664 / 830 ตกในช่องว่างครบทุกเส้น ✅ | ขอบ 166 / 332 / 498 ตกในช่องว่างครบทุกเส้น ✅ | **ใช้ได้** |
| `176` | ขอบ 880 ตัดสไปรต์คอลัมน์ที่ 6 ❌ | ตกในช่องว่าง ✅ | ใช้ไม่ได้ |
| `height ÷ 4 = 250` (สูตรเดิมใน spec) | — | ขอบ 250 **ตัดสไปรต์แถวที่ 2 (y 190-303)** ❌ | **ใช้ไม่ได้** |

**กฎที่ใช้จริง**

| กฎ | ค่า |
|---|---|
| ขนาดชีท | **1,000 × 1,000 px เท่านั้น** (ไม่ใช่ "ไม่เกิน") — เหมือน avatar spritesheet |
| ขนาดเซลล์ | **จัตุรัส**: `frame_width = frame_height = floor(1000 ÷ frame_count)` |
| จำนวนแถวที่อ่าน | `direction_rows` แถวจากด้านบน — **พื้นที่ที่เหลือด้านล่างปล่อยว่างได้** (asset จริงว่างประมาณ 1/3 ล่าง) |
| `direction_rows` | `1` (ไม่มีทิศ) หรือ `4` เท่านั้น — ลำดับแถว **`0 = down` · `1 = left` · `2 = right` · `3 = up`** ตาม `AVATAR_DIR_ROW` (`zyra-engine/avatar-frames.ts`) ✅ ยืนยันจากไฟล์จริงแล้ว (row 0 หน้าตรง, row 1 หันซ้าย, row 2 หันขวา, row 3 หลัง) |
| ตัวอย่างจากไฟล์จริง | `frame_count = 6`, `direction_rows = 4` → เซลล์ 166 × 166 px, ใช้พื้นที่ 996 × 664 px |

**❌ ยกเลิกกฎเดิม 2 ข้อ** (ทั้งคู่ทำให้ asset ของ artist ใช้ไม่ได้):
- `width % frame_count = 0` — 1000 % 6 = 4 → ไฟล์จริงถูก reject ทั้งชุด
- `frame_height = sprite_height ÷ direction_rows` — 1000/4 = 250 แต่แถวจริงสูง ~166 → renderer ตัดแมวครึ่งตัว

**✅ กฎตรวจใหม่แทน**:
- `frame_size ≥ 16px` → `FRAME_SIZE_MISMATCH` ถ้าย่อยเกินไป (ที่ชีท 1000px แปลว่า `frame_count ≤ 62` มีผลจริง แม้ช่วงที่รับคือ 1–64)
- `direction_rows × frame_size ≤ 1000` → `FRAME_ROW_MISMATCH` ถ้า grid ล้นภาพ (เช่น `frame_count = 3` + `direction_rows = 4` → 333×4 = 1332 > 1000 = ไม่ผ่าน)

### Scenario Steps
1. Admin เลือก stage จากรายการซ้าย (Egg, Baby, Adult, Evolved)
2. แต่ละ stage แสดง animation slot ตามตารางด้านบน
3. Upload PNG spritesheet ต่อ slot
4. กรอก `frame_count`, `frame_rate`, `direction_rows` **ต่อ animation**
5. กด `Preview` เพื่อดู animation loop
6. บันทึก

### Acceptance Criteria

**Stage list**
- 4 stage เรียงเป็นรายการซ้าย มี count tag `n/N` ต่อ stage
- tag **แดงเมื่อยังไม่ครบ · เขียวเมื่อครบ** (ของเดิมระบุแค่สีแดง)
- ไม่มี "tab" และไม่มี "Stage Ready badge บน tab" — badge คือ count tag ในรายการนี้

**Upload**
- PNG **1,000 × 1,000 px เท่านั้น**, ไม่เกิน 1 MB, แนะนำให้มี transparency (ไม่มี = warning ไม่ block)
- slot `Evolution` **รับ GIF เท่านั้น** (PM เคาะ 2026-09-02 — เดิมรับได้ทั้ง PNG/GIF) ไม่มี 3 ช่อง frame และไม่ตรวจ transparency — รายละเอียดใน [§ Evolution slot = GIF](#evolution-slot--gif-เท่านั้น-2026-09-02)

**3 input ต่อ animation — ต้องกรอกได้จริง**

| Field | Default | ช่วงที่รับ | หมายเหตุ |
|---|---|---|---|
| `frame_count` | **6** | 1–64 (มีผลจริง 1–62 จากกฎ `frame_size ≥ 16px`) | จำนวนคอลัมน์ |
| `frame_rate` | **8** | 4–24 fps | 8 = `AVATAR_WALK_FPS` ค่าที่ engine ใช้อยู่ |
| `direction_rows` | **4** | `1` หรือ `4` | จำนวนแถวที่อ่านจากด้านบน |

- ทั้ง 3 ช่องเป็น **number input ที่ enabled** กรอกแยกได้ต่อ animation — **ห้ามเป็น select ที่ disabled และห้ามล็อกค่าคงที่** (ของเดิมล็อก 50 เฟรม / 24 fps ซึ่งไม่ตรงกับ asset จริงเลย และผู้ใช้เห็น dropdown ที่กดไม่ได้)
- แสดง frame size ที่คำนวณได้ใต้ฟิลด์: `frame size = {frame_size} × {frame_size} px` เพื่อให้เห็นผลทันทีที่กรอก

**Preview**
- ปุ่ม `Preview` **enable เมื่อมี asset อัปแล้วอย่างน้อย 1 ชิ้น** (ไม่ต้องรอครบทุก slot)
- Modal มี stage tab + animation dropdown — **รายการใน dropdown derive จาก RequiredSlots ของ stage นั้น**
- ต้องมี **empty state** ต่อ (stage, animation) ที่ยังไม่มีไฟล์ ("ยังไม่ได้อัปโหลด animation นี้") — ห้ามโชว์ canvas ว่างเปล่าโดยไม่บอกอะไร
- Preview ต้องเล่นด้วย **metadata จริงของไฟล์นั้น** (`frame_count` / `frame_rate` / `direction_rows` ที่บันทึกไว้) ห้าม hardcode
- ตัวสัตว์ที่อยู่กลาง canvas เป็น **ภาพ preview ไม่ใช่คอนโทรลที่ลากได้** — ระบบไม่มี field เก็บ anchor/offset ถ้าต้องการให้ลากตั้ง anchor ต้องเพิ่ม field ใน schema ก่อน

**อื่น ๆ**
- Required animation ต้องอัปครบก่อน stage นั้นถึงจะ "พร้อมใช้งาน"
- ลบไฟล์ออกจาก slot ได้ (ปุ่มถังขยะบนการ์ดไฟล์)

### Business Logic / Rules
- Spritesheet เป็น **grid ของเซลล์จัตุรัส** — คอลัมน์ = frame, แถว = direction
- `frame_width = frame_height = floor(sprite_width ÷ frame_count)`
- แถวที่เกิน `direction_rows` และพื้นที่ที่เหลือด้านล่าง = พื้นที่ว่าง ไม่ต้อง validate ว่ามีภาพ
- Engine render: สร้าง animation จาก frame config (คอลัมน์ 0..`frame_count-1` ของแถวตาม facing)
- Stage incomplete: pet ใช้ fallback animation (`Walking` loop; Egg ใช้ `Wobbling`)

### UX/UI Reference
[Figma — node 4043-249225](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4043-249225&t=F9kfchFmCSys23FH-0)

---

## SC-PM-04 · กำหนด XP Config

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Admin เข้าหน้า Pet Management → Tab XP Configuration

### XP Config Parameters

**Evolution XP (Stage Thresholds)** — เป็นค่า **สะสม (cumulative)** ไม่ใช่ค่าที่ต้องบวกกัน

| Field | Default | Min–Max | Transition |
|-------|---------|---------|--------------|
| `xp_baby` | 100 | 1–1,000,000 | Egg → Baby |
| `xp_adult` | 500 | 1–1,000,000 | Baby → Adult |
| `xp_evolve` | 2000 | 1–1,000,000 | Adult → Evolved |

- derive stage: `xp < xp_baby` → egg · `< xp_adult` → baby · `< xp_evolve` → adult · `≥ xp_evolve` → evolved
- ต้อง `xp_baby < xp_adult < xp_evolve` เสมอ
- **เพดาน 1,000,000** จำเป็น: `tb_room_pet.xp` เป็น `INT` (สูงสุด 2,147,483,647) ถ้าปล่อยให้กรอกค่ามหาศาลจะเทียบพลาดแบบเงียบ ๆ — เดิมฟอร์มไม่มี max เลย พิมพ์กี่หลักก็ได้

**XP Sources — 10 activities**

`Max` = เพดานของค่าที่ admin ตั้งได้ในฟอร์ม (validation) ไม่ใช่เพดาน XP ต่อวัน

| Field | Default XP | Max XP | `times` (ครั้ง/วัน) | Description |
|-------|-----------|--------|--------------------|--------------|
| `xp_login_per_day` | 1 | 5 | 1 (1–50) | XP ต่อ user login/วัน |
| `xp_office_10min` | 2 | 10 | 1 (1–50) | มีคนอยู่ใน office 10 นาที |
| `xp_office_30min` | 6 | 30 | 1 (1–50) | มีคนอยู่ใน office 30 นาที |
| `xp_team_meeting` | 10 | 50 | 1 (1–50) | Team join a meeting |
| `xp_team_meeting_10min` | 2 | 10 | 1 (1–50) | Team join a meeting 10 นาที |
| `xp_team_meeting_30min` | 6 | 30 | 1 (1–50) | Team join a meeting 30 นาที |
| `xp_first_message_fo_day` | 1 | 5 | 1 (1–50) | ส่ง message แรกของวัน |
| `xp_10_message_fo_day` | 2 | 10 | 1 (1–50) | ส่ง chat 10 ข้อความ |
| `xp_react_message_fo_day` | 1 | 5 | 1 (1–50) | React message ด้วย emoji |
| `xp_play_with_pet` | 1 | 5 | 1 (1–50) | เล่นกับ pet |

- **`times` = จำนวนครั้งสูงสุดที่ activity นั้นจ่าย XP ได้ต่อวัน** (ต่อ user หรือต่อ room ตาม scope ใน [db-schema-api-contract.md](db-schema-api-contract.md)) — ผูกกับ quota ใน XP ledger (PR 9) ช่วง 1–50
  - เดิมช่องนี้ปรากฏในฟอร์มโดยไม่มีนิยาม และ ux-ui.md เขียนว่า field `time` "ไม่มีจริง" → ถ้าทีมสรุปว่าไม่ใช้ ต้อง **เอาช่องออกจากฟอร์ม** ไม่ใช่ปล่อยให้กรอกค่าที่ไม่มีใครอ่าน
- Switch เปิด/ปิดต่อ activity → `enabled: boolean` ใน JSONB

> **ชื่อ field ต้องใช้ตามนี้เป๊ะทั้ง FE/BE** — `_fo_day` เป็น typo ที่ตั้งไว้ใน card แล้ว (`fo` = `of`) เปลี่ยนได้ก็ต้องเปลี่ยนพร้อมกันทั้ง card และโค้ด

**Mood & Penalty Config — 3 states**

Mood กระทบ **อัตราการได้ XP** (ไม่ใช่หัก XP ตรง ๆ) — Happy ได้ bonus, Sad ถูก penalty

| State | ช่วงเวลาไม่มี activity | XP rate (default) | Min–Max ของ rate |
|-------|------------------------|-------------------|------------------|
| Happy | ≤ **12** ชม. | **150%** | 0–300% |
| Neutral | 12 – **72** ชม. | 100% | 0–300% |
| Sad | > **72** ชม. | **50%** | 0–300% |

- **ปิดช่องว่าง 48–72 ชม. แล้ว**: Neutral ยืดถึง 72 ชม. — เดิมตั้ง Neutral = 48 และ Sad = 72 ทำให้ช่วง 48–72 ชม. ไม่ตกอยู่ใน state ใดเลย
- ค่าที่กรอกได้จริงมี 2 ค่า: `happy.within_hours` (ขอบบนของ Happy) และ `sad.after_hours` (ขอบที่เข้า Sad)
  - **ช่อง Neutral ในฟอร์มเป็น read-only** แสดงช่วงที่คำนวณได้ (`12 – 72 ชม.`) — เพราะ Neutral คือ "ช่วงระหว่าง Happy กับ Sad" ไม่ใช่ค่าที่ตั้งอิสระ
  - ค่าที่ส่งขึ้น API: `mood.neutral.within_hours` ต้อง **เท่ากับ** `mood.sad.after_hours` เสมอ
- ชั่วโมงทุกช่อง: **1–720 ชม.** (สูงสุด 30 วัน) — ต้อง > 0 ไม่งั้น mood เปลี่ยนทันทีจนวนลูป และเดิมไม่มี max เลย
- XP rate: **0–300%** จำนวนเต็ม ห้ามติดลบ (ติดลบ = ทำกิจกรรมแล้ว XP ลด ซึ่งกลับด้าน) · `0%` ตั้งได้ = mood นั้นไม่ได้ XP เลย ให้ขึ้นข้อความเตือน inline
- ต้อง `Happy% ≥ Neutral% ≥ Sad%` เสมอ
- sticky note ใน Figma เขียน "Happy XP (50%)" ซึ่งกลับหัวกับตารางนี้ — ยึด card (Happy = bonus)

### Stat Summary (คำนวณฝั่ง client แบบ real-time จากค่าที่กรอก)

```
Total XP needed      = xp_evolve                                  (ค่าสะสม ไม่ใช่ผลรวมของ 3 threshold)
Max XP / Day         = Σ xp ของทุก activity ที่ enabled
Max evolution within = ceil(Total XP needed ÷ Max XP / Day)  วัน
```

- footnote: `* Calculation assumes users maximise all available daily XP sources.`
- ⚠️ เลข `2,000 XP` / `65 XP` / `40 Days` ในดีไซน์เป็น **mockup ที่ไม่สอดคล้องกันเอง** (default จริงได้ 32 XP/วัน → 63 วัน) ห้าม hardcode ตัวเลขเหล่านี้ลง UI
- ⚠️ สูตร "Total XP needed = Growth to Baby + Growth to Adult + Growth to Evolved" ที่เขียนไว้ใน ux-ui.md **ผิด** — จะได้ 2,600 แทนที่จะเป็น 2,000 เพราะ threshold เป็นค่าสะสมอยู่แล้ว

### Version History & Restore
- บันทึก **10 versions ล่าสุด** (insert version ใหม่แล้ว prune ส่วนเกินใน transaction เดียว)
- Timeline แสดงต่อ version: badge `V n` + ชื่อผู้บันทึก + avatar + เวลา + เมนู `⋯` → `Restore`
- Restore = **สร้าง version ใหม่จากค่าเดิม** (append-only) ไม่ใช่ย้อนทับของเก่า
- Restore modal: title `Restore selected version?` · description ต้องพูดถึง **XP configuration** ไม่ใช่ "workspace" (XP config เป็น global ไม่ผูกกับ workspace ใด) · ปุ่ม `Cancel` / `Restore`

### Scenario Steps
1. Admin เข้า XP Configuration tab
2. เห็น config ที่ใช้อยู่ (version ปัจจุบัน)
3. Admin ปรับค่าตามต้องการ
4. กด Save → สร้าง version ใหม่ + มีผลทันทีกับทุก pet ใน platform

### Acceptance Criteria
- Config form: number input ทุกช่องมี min/max ตามตารางด้านบน + inline error ทันทีที่กรอกเกินช่วง
- **Save flow**: กด Save → validate → สำเร็จ → **toast** `XP configuration saved successfully.`
  - **ไม่มี dialog ยืนยันก่อน save** — dialog มีที่เดียวคือ Restore (ของเดิมใน spec สั่งให้มี confirmation dialog ซึ่งขัดกับดีไซน์)
- Validation rules ที่ต้อง block การ save (ทั้ง client + server):

| กฎ | ข้อความ / เหตุผล |
|---|---|
| ปิด switch ทุก activity | บล็อก — config ที่ไม่มี XP source เลย = pet ไม่มีวันโต ให้ข้อความว่า "ต้องเปิดอย่างน้อย 1 แหล่ง XP" |
| activity ที่ enabled มี `xp = 0` หรือค่าว่าง | บล็อก — `xp` ต้อง 1 ถึง Max ของ activity นั้น |
| `times` นอกช่วง 1–50 | บล็อก |
| threshold ไม่เรียงจากน้อยไปมาก | บล็อก — Baby < Adult < Evolved |
| threshold เป็น 0 / ว่าง / ติดลบ / ทศนิยม / ตัวอักษร | บล็อก — จำนวนเต็มบวกเท่านั้น |
| ชั่วโมงเป็น 0 หรือเกิน 720 | บล็อก |
| XP rate ติดลบ หรือเกิน 300 | บล็อก |
| `Happy% < Neutral%` หรือ `Neutral% < Sad%` | บล็อก — mood ที่ดีกว่าต้องไม่ได้ XP น้อยกว่า |
| `happy.within_hours ≥ sad.after_hours` | บล็อก — ช่วง Neutral ต้องมีจริง |

- ทุก validation error ฝั่ง server คืน `422 INVALID_XP_CONFIG` พร้อม `detail: {field, reason}` เพื่อให้ FE ชี้ช่องที่ผิดได้
- Config history: 10 versions ล่าสุด ย้อนกลับได้
- Preview impact: แสดงจำนวนวันจากสูตร `Max evolution within` ด้านบน (**สมมติฐานเดียว** = ใช้ XP source ที่เปิดไว้ครบทุกวัน — ตัดสมมติฐาน "team 5 คน active ทุกวัน" ที่เคยเขียนไว้ออก เพราะไม่ตรงกับสูตรที่ UI ใช้จริง)

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
- ต้องวางภายใน room zone — วางนอก zone = toast แดง `Unable to place pet` + ไม่สร้าง record
- ชื่อ Pet: optional, max 30 chars, default = Pet Type name
- ย้าย/เปลี่ยนชื่อ/ลบ Pet จาก Map Editor ได้ (marker menu → Trash)
- Broadcast ให้ users ที่ online เห็นทันที (`pet_spawned` / `pet_moved` / `pet_renamed` / `pet_removed`)
- **การวาง pet ต้องอัปเดต `workspace_usage_count` ของ pet type นั้น** — badge และ sort `usage_count` ใน SC-PM-01 พึ่งค่านี้
- ✅ **PM เคาะ 2026-09-04: 1 room = 1 pet บังคับ** (`uq_room_pet_one_per_zone` เปิดแล้ว) · วางได้เฉพาะ `zone_type = 'room'` · จุดวางห้ามตกใน meeting/private แม้ซ้อนอยู่ใน room
  - modal "Replace this pet" ใช้จริง: วางซ้ำห้อง → 409 → confirm → `replace: true` → pet ใหม่รับ XP/stage ต่อจากตัวเดิม (sticky Figma)
  - ⚠️ **stage row ใน marker menu (Figma 4387:121093) ยังไม่ทำ** — ต้องนิยาม "admin เลือก stage" กับ "ทีมเคยถึง stage นั้น" ก่อน ดู [ux-ui.md § สิ่งที่ Figma มีเพิ่ม](ux-ui.md)

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
**Pre-condition:** Admin พยายาม upload spritesheet ใน step 2 ของ wizard

### Validation Rules Summary

| Field | Rule | Code |
|-------|------|------|
| file | PNG เท่านั้น (นามสกุล + magic bytes `89 50 4E 47`) · **slot `Evolution` = GIF เท่านั้น** (magic `GIF87a`/`GIF89a`; PNG ที่ slot นี้ก็ผิด) | `INVALID_FILE_TYPE` |
| file | ไม่เกิน 1 MB | `FILE_TOO_LARGE` |
| width / height | **ต้องเท่ากับ 1,000 × 1,000 px พอดี** · GIF (`Evolution`): จัตุรัส **ไม่เกิน** 1,000×1,000 | `INVALID_DIMENSIONS` |
| frame_count | 1–64 | `INVALID_FRAME_COUNT` |
| frame_rate | 4–24 fps | `INVALID_FRAME_RATE` |
| direction_rows | `1` หรือ `4` | `INVALID_DIRECTION_ROWS` |
| frame_size | `floor(width ÷ frame_count) ≥ 16px` | `FRAME_SIZE_MISMATCH` |
| grid | `direction_rows × frame_size ≤ height` | `FRAME_ROW_MISMATCH` |
| transparency | แนะนำให้มี — ไม่มี = **warning ไม่ block** | `NO_TRANSPARENCY` (ใน `data.warnings`) |

> **เปลี่ยนจากของเดิม**: `INVALID_DIMENSIONS` เดิมคือ "ไม่เกิน 1,000×1,000" ตอนนี้คือ "ต้องเท่ากับ 1,000×1,000" · `FRAME_SIZE_MISMATCH` / `FRAME_ROW_MISMATCH` เดิมเป็นกฎหารลงตัว (modulo) ซึ่ง reject asset จริง — ดูเหตุผลใน [SC-PM-03 § Sprite Grid](#sprite-grid--ล็อกจาก-asset-จริงแล้ว-2026-09-01)

### Error Cases + Copy

| Code | Title (EN) | Message (EN) | ข้อความไทย |
|------|-----------|--------------|-----------|
| `INVALID_FILE_TYPE` | `Upload failed` | `Only PNG files are supported.` | รองรับเฉพาะไฟล์ PNG |
| `FILE_TOO_LARGE` | `Upload failed` | `The file must be 1 MB or smaller.` | ขนาดไฟล์ต้องไม่เกิน 1 MB |
| `INVALID_DIMENSIONS` | `Invalid image size` | `The spritesheet must be exactly 1,000 × 1,000 px.` | สไปรต์ชีทต้องมีขนาด 1,000 × 1,000 px เท่านั้น |
| `INVALID_FRAME_COUNT` | `Invalid frame count` | `Frame count must be between 1 and 64.` | จำนวน frame ต้องอยู่ระหว่าง 1–64 |
| `INVALID_FRAME_RATE` | `Invalid frame rate` | `Frame rate must be between 4 and 24 FPS.` | Frame rate ต้องอยู่ระหว่าง 4–24 fps |
| `INVALID_DIRECTION_ROWS` | `Invalid direction rows` | `Direction rows must be 1 or 4.` | จำนวนแถวทิศทางต้องเป็น 1 หรือ 4 |
| `FRAME_SIZE_MISMATCH` | `Frame too small` | `{frame_count} frames make each frame {frame_size} px — the minimum is 16 px.` | frame_count {frame_count} ทำให้แต่ละเฟรมเหลือ {frame_size} px (ขั้นต่ำ 16 px) |
| `FRAME_ROW_MISMATCH` | `Grid does not fit` | `{direction_rows} rows × {frame_size} px exceeds the {height} px sheet.` | {direction_rows} แถว × {frame_size} px เกินความสูงของชีท ({height} px) |
| `NO_TRANSPARENCY` | `Missing transparency` (**warning เหลือง**) | `This PNG has no transparent background. The pet may show a solid box in the room.` | PNG นี้ไม่มีพื้นหลังโปร่งใส pet อาจขึ้นเป็นกล่องทึบในห้อง |

- **transparency เป็น warning ไม่ใช่ error** — API คืน `200` พร้อม `data.warnings: ["NO_TRANSPARENCY"]` (Figma วาดเป็น error toast แดง `Invalid PNG image` ซึ่งตกไปแล้วตามคำตอบ PM ข้อ 6)
- error ทุกตัวคืน HTTP `400` + `detail.code` **พร้อมตัวเลขที่เกี่ยวข้อง** (`{width, height, frame_count, frame_size, direction_rows}`) เพื่อให้ FE เติมลงข้อความได้ตามตาราง — ไม่ใช่ส่งแค่ code

### Acceptance Criteria
- **Client-side validate ทันทีที่เลือกไฟล์** (ชนิดไฟล์, ขนาดไฟล์, dimension) ก่อนยิง request — ผู้ใช้ต้องไม่ต้องรอ round-trip เพื่อรู้ว่าไฟล์ผิด
- FE ต้อง **map `detail.code` → ข้อความตายตัวตามตารางด้านบน** (single source) ห้ามใช้ข้อความรวมแบบ `Upload failed ({code})`
- Frame size preview: แสดง `frame size = {frame_size} × {frame_size} px` ทันทีที่กรอก `frame_count`
- inline error ใต้ field สำหรับ `frame_count` / `frame_rate` / `direction_rows`; toast แดงสำหรับ error ที่เกิดตอนเลือกไฟล์
- Server validate magic bytes ซ้ำอีกชั้นเสมอ

### UX/UI Reference
[Figma — node 4043-252350](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4043-252350&t=KrMB68Z63QeG3ccx-0)

---

## ผลต่อโค้ด / schema จากการแก้ spec รอบนี้ (2026-09-01)

โค้ดที่ merge เข้า `develop` แล้วยังทำตาม spec เวอร์ชันก่อนหน้า — รายการนี้คือสิ่งที่ต้องแก้ให้ตรงกับเอกสารนี้ (รายละเอียดต่อข้อ + ไฟล์:บรรทัด ดู [code-findings-2026-08-31.md](code-findings-2026-08-31.md))

### zyra-api

| ต้องแก้ | จาก | เป็น |
|---|---|---|
| `model.RequiredPetSlots` (`internal/model/pet.go`) | 20 slot (มี `Idle`) | **17 slot** ถอด `PetSlotIdle` ออก |
| DB CHECK `tb_pet_animation.slot` + bootstrap DDL (`internal/database/postgres.go`) | มี `'Idle'` | ถอด `'Idle'` + **ล้าง row ที่ slot = `Idle`** ก่อนใส่ constraint |
| ตรวจขนาดชีท (`internal/service/pet_service.go`) | `width/height ≤ 1000` | **ต้อง = 1000 × 1000** — reuse แนวเดียวกับ `requiredSpritesheetDim` ใน `avatar_service.go` |
| `validatePetSpriteDimensions` | `width < frame_count` → mismatch · `height % direction_rows` | **เซลล์จัตุรัส**: `frame_size = width / frame_count` · เช็ค `frame_size ≥ 16` และ `direction_rows × frame_size ≤ height` |
| error detail (`internal/handler/pet_handler.go`) | ส่งแค่ `{code}` | แนบตัวเลขตามตาราง copy ใน SC-PM-07 |
| `ValidatePetXPConfig` (`internal/service/pet_xp_config_service.go`) | `happy.within < neutral.within < sad.after` | `happy.within < sad.after` และ **`neutral.within == sad.after`** + เพดาน hours ≤ 720, rate ≤ 300, threshold ≤ 1,000,000, `times` ≤ 50 |
| seed config v1 (migration 85 + bootstrap DDL) | `neutral.within_hours = 48` | **72** (ปิดช่องว่าง 48–72 ชม.) |
| `DELETE /api/admin/pets/:id` | ลบได้เสมอ | คืน `409 PET_TYPE_IN_USE` ถ้ายังถูกวางในห้อง (ทำพร้อม SC-PM-05) |
| `workspace_usage_count` | ไม่มีใครเขียน | อัปเดตตอนวาง/ลบ pet ใน SC-PM-05 |
| `allowedMimeTypesBySlot[Evolution]` (`pet_service.go`) — **2026-09-02** | `{PNG, GIF}` | **`{GIF}` เท่านั้น** |
| GIF path ใน `UploadAnimation` — **2026-09-02** | ผ่าน `validatePetSpriteDimensions` + เก็บ `frame_width = width/frame_count` | ข้าม grid validation · เช็คแค่จัตุรัส ≤ 1000 · เก็บ width/height จริง · `frame_count/frame_rate/direction_rows = NULL` |
| `tb_pet_animation` CHECK/NOT NULL ของ `frame_count`/`frame_rate`/`direction_rows` — **2026-09-02** | `NOT NULL` + CHECK ทุก row | ปลดเป็น nullable สำหรับ row GIF (migration ใหม่ + bootstrap DDL) |
| Prefill egg `Evolution` (`pet_service.go` `stageReadiness` + detail/list response, `config.go`) — **2026-09-02** | ไม่มี | ถ้าไม่มี row (egg, Evolution) → คืน URL กลางจาก `PET_EGG_EVOLUTION_DEFAULT_URL` + `is_default: true` และนับว่าพร้อม · `DeleteAnimation` ของ slot นี้ = กลับ default |

### zyra-app

| ต้องแก้ | จาก | เป็น |
|---|---|---|
| `pet-upload-config.ts` | 20 slot (`idle` ในทุก stage) | **17 slot** |
| `pet-upload-step.tsx` | `frameCount = 50`, `frameRate = 24`, `directionRows = 4` hardcode + `<select disabled>` | number input **enabled** ต่อ animation · default **6 / 8 / 4** · **ซ่อน 3 ช่องนี้ที่ slot `Evolution`** และ `accept="image/gif"` อย่างเดียว (2026-09-02) |
| notice "PNG only" ใน upload step (`petUploadPngNotice`) | บอกว่ารับ PNG อย่างเดียว | เพิ่มข้อความว่า `Evolution` ต้องเป็น GIF (i18n en/th) — 2026-09-02 |
| การ์ด upload egg/`Evolution` (`pet-upload-step.tsx` `AnimationUploadCard`) + count tag + progress + preview — **2026-09-02** | empty state เหมือน slot อื่น | state `Default` (badge + preview ไฟล์กลาง + ปุ่ม `Replace`) อ่านจาก `is_default` · ลบ = กลับ default · นับพร้อมตั้งแต่ต้น |
| `pet-preview-modal.tsx` | hardcode 6×4@8 และ `void animationMeta` | อ่าน `frame_count` / `frame_rate` / `direction_rows` จริงจาก DB (ค่า 6×4@8 บังเอิญตรงกับ asset demo แต่จะผิดทันทีที่ไฟล์อื่นใช้ค่าอื่น) + เพิ่ม empty state ต่อ slot ที่ยังไม่มีไฟล์ |
| ปุ่ม Preview | `disabled` จนอัปครบทุก slot | enable เมื่อมี asset ≥ 1 |
| `pet-detail-panel.tsx` progress bar | ตาราง width 18 ค่า (สเกล 17 ขั้น) | คำนวณจาก `uploaded / RequiredSlots.total` |
| Status toggle ในฟอร์ม | default ON, กดได้ตลอด | default OFF + disabled จนกว่า `stage_ready` ครบ 4 stage |
| ปุ่ม Save / Next | enable ด้วยเงื่อนไขเดียวกันที่ step 1 | Save เฉพาะ step 2 · Next เฉพาะ step 1 |
| Sort menu ใน Pet Library | มี `usage_count` | ซ่อนจนกว่า SC-PM-05 จะ live |
| Category filter | 8 ค่า (ไม่มี buffalo) | **9 ค่า** จาก source เดียวกับ dropdown |
| Search input | ยิงทุกตัวอักษร | debounce 300ms |
| toast ตอน upload ล้มเหลว | ข้อความรวม `Upload failed ({code})` | map ต่อ code ตามตาราง SC-PM-07 + client-side pre-check |
| `xp-configuration-panel.tsx` | input ไม่มี max, ช่อง Neutral กรอกอิสระ | ใส่ min/max ทุกช่อง + Neutral เป็น read-only mirror ของ Sad boundary |
| `xp-configuration-panel.tsx` imports | `@/components/ui/dialog`, `dropdown-menu` | Tailwind-only ตาม `.claude/rules/08-shadcn-ui.md` |

### เอกสารอื่นที่ต้องตามแก้

- [db-schema-api-contract.md](db-schema-api-contract.md) — สูตร frame (§`tb_pet_animation`), กฎ modulo ใน example request, mood ordering, slot vocabulary (ไม่มี `Idle`), `frame_count` default
- [code-findings-2026-08-31.md](code-findings-2026-08-31.md) — **F2/F3 ต้องแก้คำอธิบาย**: preview 6×4@8 คือค่าที่ตรงกับ asset จริง ส่วนฟอร์ม 50/24 คือค่าที่ผิด (ตอนที่เขียน findings ยังไม่ได้ดู sprite จริง)
