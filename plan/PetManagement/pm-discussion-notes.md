# Pet Management — Decision Log (PM ตอบแล้ว)

> เดิมเป็นรายการคำถามที่เทียบ [spec.md](spec.md) กับ Figma ([ux-ui.md](ux-ui.md)) — PM ตอบครบแล้ว (2026-08-14) และแก้ ClickUp card หลายใบตามคำตอบ
> ไฟล์นี้ถูกเขียนใหม่เป็น **decision log**: แต่ละข้อมีคำตอบ + ผลการเทียบกับ card จริงใน ClickUp
>
> **อัปเดต 2026-08-17 — ข้อ 2 กับ ข้อ 5 ปิดแล้ว ไม่มี blocker เหลือ** PM ยืนยันให้ **ยึด Figma** สำหรับ stage/animation model และใช้ Map Editor drag-drop สำหรับ placement → เริ่ม implement ได้ทุก PR (แผนงานที่ [work-split.md](work-split.md))
>
> **Source of truth**: ClickUp card เป็นหลัก **ยกเว้น stage/animation model ที่ยึด Figma** — ข้อยกเว้นซ้อน: `Happy XP = 150%` ยึด card ไม่ใช่ sticky note ใน Figma (ดูข้อ 3)

**Card อ้างอิง**: [[Module] Pet Management](https://app.clickup.com/t/86d3dcbra) · [SC-PM-01](https://app.clickup.com/t/86d3dcbx9) · [SC-PM-02](https://app.clickup.com/t/86d3dcc16) · [SC-PM-03](https://app.clickup.com/t/86d3dcc8r) · [SC-PM-04](https://app.clickup.com/t/86d3dccmn) · [SC-PM-05](https://app.clickup.com/t/86d3dcet3) · [SC-PM-07](https://app.clickup.com/t/86d3dcfpz)

---

## สรุปสถานะ


| #   | ประเด็น                           | คำตอบ PM                                          | เทียบ card                                       | สถานะ         |
| --- | --------------------------------- | ------------------------------------------------- | ------------------------------------------------ | ------------- |
| 1   | Growth stage 4 vs 6               | **4 stages**                                      | ตรงกันทุกใบ                                      | ✅ ปิด         |
| 2   | Animation ต่อ direction vs ต่อท่า | **รวมทุก direction ในไฟล์เดียว — ยึด Figma**      | ❌ SC-PM-03 ยังเป็น per-direction (card ต้องแก้)  | ✅ ปิด (08-17) |
| 3   | Mood 3-state                      | ใช้ 3-state (แก้ card แล้ว)                       | ตรง + มีตัวเลขครบ                                | ✅ ปิด         |
| 4   | XP sources 10 activities          | **10 activities**                                 | ตรง (มี default/max ครบ)                         | ✅ ปิด         |
| 5   | Assign pet: form vs Map Editor    | **Map Editor drag-drop**, ตัด tab, ตั้งชื่อตอนวาง | ❌ SC-PM-05 ยังเป็น form flow เดิม (card ต้องแก้) | ✅ ปิด (08-17) |
| 6   | Transparency block ไหม            | **warning ไม่ block**                             | ตรง                                              | ✅ ปิด         |
| 7   | Validation ที่ Figma ไม่มี UI     | (ไม่ได้ตอบ)                                       | card ตอบให้แล้ว                                  | ✅ ปิดโดย card |
| 8   | Max dimension                     | **1,000 × 1,000 px**                              | ตรง (แต่ยังไม่มี error code)                     | 🟡 เกือบปิด   |
| 9   | Count badge บน pet card           | **workspace_usage_count**                         | ตรง                                              | ✅ ปิด         |
| 10  | Pagination                        | **10 / page**                                     | ❌ card ยังเขียน 20/หน้า                          | 🟡 ต้อง sync  |


---

## ✅ ปิดล่าสุด 2026-08-17 (เดิมเป็น blocker)

### ข้อ 2 — Animation: **ยึด Figma** รวมทุก direction ในไฟล์เดียว

**เคาะแล้ว**: animation 1 slot = 1 ไฟล์ที่รวมทุก direction (ตาม Figma) — ตาราง per-direction ใน [SC-PM-03](https://app.clickup.com/t/86d3dcc8r) (`walk_n/walk_s/walk_e/walk_w`) **ตกไป** card ต้องแก้ตาม

**Slot vocabulary ที่ใช้จริง** (6 ตัว):


| Stage     | Required slots                                    | Count |
| --------- | ------------------------------------------------- | ----- |
| `egg`     | `Wobbling`, `Evolution`                           | 2     |
| `baby`    | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5     |
| `adult`   | เหมือน `baby`                                     | 5     |
| `evolved` | เหมือน `baby` (รวม `Evolution`)                   | 5     |


- **Egg = 2 ไม่ใช่ 3** — counter ใน Figma node #4/#9 โชว์ `3/3` แต่ animation dropdown ของ Egg โชว์แค่ 2 รายการ ([ux-ui.md:350](ux-ui.md)) → dropdown คือรายการ animation จริง counter เป็น mockup ที่ไม่ sync
- **Adult / Evolved** ไม่มี frame ใน Figma ที่โชว์ dropdown ตรง ๆ — อนุมานว่าเหมือน Baby
- Egg → Baby เล่น `Evolution` (ตอบคำถามเดิมเรื่อง animation ตอนฟักไข่)

**ผลต่อ schema — spritesheet เป็น grid ไม่ใช่ horizontal strip แล้ว**:


| ต้องมี                            | ค่า                                                                                                |
| --------------------------------- | -------------------------------------------------------------------------------------------------- |
| `tb_pet_animation.direction_rows` | `INT NOT NULL DEFAULT 1`                                                                           |
| สูตร frame                        | `frame_width = sprite_width / frame_count` **และ** `frame_height = sprite_height / direction_rows` |
| Validation แกนที่ 2               | `height % direction_rows = 0` → error code ใหม่ (เสนอ `FRAME_ROW_MISMATCH`)                        |


### ข้อ 5 — Assign pet: **Map Editor drag-drop**

**เคาะแล้ว**: ✅ ใช้ Map Editor drag-drop · ✅ ตัด tab "Assign to Room" ออกจาก Pet Management · ✅ ตั้งชื่อ pet ตอนวาง เหมือนตั้งชื่อห้อง — flow ฟอร์มใน [SC-PM-05](https://app.clickup.com/t/86d3dcet3) **ตกไปทั้งใบ** card ต้องแก้ตาม

**ผลที่ตามมา**:


| หัวข้อ         | สรุป                                                                                                    |
| -------------- | ------------------------------------------------------------------------------------------------------- |
| Endpoint       | ใช้ชุด map-scoped `/api/admin/maps/:mapId/pets` อย่างเดียว — ตัด `POST /api/admin/pets/:id/assign` ทิ้ง |
| Spawn position | **ตำแหน่งที่ admin วาง** (`tile_x`/`tile_y` เป็น `DOUBLE PRECISION`) — center ของ zone ตกไป             |
| ชื่อ pet       | ยัง optional + max 30 chars, UI = ตั้ง/แก้ตอนวางบน Map Editor                                           |
| FE scope       | Pet Management ไม่มี tab placement อีกต่อไป                                                             |


**ยังค้าง 1 ข้อ (ไม่บล็อก)** — **กฎ 1 room = 1 pet ยังบังคับไหม** Figma ไม่ได้ตอบ และ PM ตอบแค่ flow
→ default ที่ใช้ไปก่อน: **ยังไม่เปิด** `uq_room_pet_one_per_zone` (วางได้หลายตัว) เพราะเพิ่ม unique index ทีหลังทำได้ถ้ายังไม่มีข้อมูลซ้ำ แต่ถ้าเปิดไปแล้วปลดยากกว่า

**ยังค้างอีกข้อ (ไม่บล็อก)** — **Workspace Template vs Workspace จริง**: ชื่อ card คือ "Room ของ Workspace **Template**" แต่ criteria พูดถึง broadcast ให้ user ที่ online (= workspace จริง) → วาง pet ใน template แล้ว workspace ที่สร้างไปก่อนหน้าได้ pet ด้วยไหม

---

## ✅ ปิดแล้ว — ใช้เป็น spec ได้เลย

### ข้อ 1 — 4-stage model

`Egg → Baby → Adult → Evolved` ยืนยันแล้ว สอดคล้องกันทั้ง 3 card (SC-PM-01 "4 stages", SC-PM-03 stage tabs, SC-PM-04 `xp_baby`/`xp_adult`/`xp_evolve`)

Evolution XP threshold จาก [SC-PM-04](https://app.clickup.com/t/86d3dccmn):


| Field       | Default | Transition      |
| ----------- | ------- | --------------- |
| `xp_baby`   | 100     | Egg → Baby      |
| `xp_adult`  | 500     | Baby → Adult    |
| `xp_evolve` | 2000    | Adult → Evolved |


### ข้อ 3 — Mood 3-state (มีตัวเลขครบแล้ว)


| State                   | Duration | XP rate  | ความหมาย              |
| ----------------------- | -------- | -------- | --------------------- |
| Happy (`xp_happy`)      | 12 Hr.   | **150%** | ร่าเริง               |
| Neutral                 | 48 Hr.   | 100%     | ปกติ                  |
| Sad (`sad_after_hours`) | 72 Hr.   | **50%**  | ไม่มีใครเข้ามา + เหงา |


> **หมายเหตุ**: sticky note ใน Figma เขียน "Happy XP (50%)" ซึ่งกลับหัวกับ card — card เป็นของใหม่กว่าและมีเหตุผลกว่า (Happy = bonus, Sad = penalty) จึงยึด card
>
> **จุดที่ต้องตีความตอน implement** (ไม่บล็อก แต่ควรเคาะก่อนเขียน scheduler): `Duration` = "ไม่มี activity นานเท่าไหร่ถึงเข้า state นี้" → active ภายใน 12 ชม. = Happy, 12–48 ชม. = Neutral, เกิน 72 ชม. = Sad แล้ว **ช่วง 48–72 ชม. คือ state อะไร**? ถ้าตีความว่า Neutral ยืดถึง 72 ชม. ก็จบ — แต่ต้องให้ PM confirm

### ข้อ 4 — XP Sources 10 activities

จาก [SC-PM-04](https://app.clickup.com/t/86d3dccmn) — ทุกตัวมี default + max:


| Field                     | Default | Max |
| ------------------------- | ------- | --- |
| `xp_login_per_day`        | 1       | 5   |
| `xp_office_10min`         | 2       | 10  |
| `xp_office_30min`         | 6       | 30  |
| `xp_team_meeting`         | 10      | 50  |
| `xp_team_meeting_10min`   | 2       | 10  |
| `xp_team_meeting_30min`   | 6       | 30  |
| `xp_first_message_fo_day` | 1       | 5   |
| `xp_10_message_fo_day`    | 2       | 10  |
| `xp_react_message_fo_day` | 1       | 5   |
| `xp_play_with_pet`        | 1       | 5   |


คำถามเดิมเรื่อง "field `time` หมายถึงอะไร" ตอบเรียบร้อย — เวลาถูก **ฝังเข้าไปในชื่อ activity แล้ว** (`_10min` / `_30min`) ไม่ใช่ field แยก

**ยังค้างเล็กน้อย** (ไม่บล็อก schema):

- `Max` = เพดานของค่าที่ admin ตั้งได้ (validation) หรือ เพดาน XP ที่ pet รับได้ต่อวันจาก activity นั้น? — ตีความจากตำแหน่งในตารางว่าเป็น **validation ของ config form** (card เขียน "number inputs พร้อม min/max validation")
- Figma มี **toggle เปิด/ปิดต่อ activity** แต่ card ไม่มี field นี้ → ถ้าต้องมี ต้องเพิ่ม `enabled` boolean ต่อ activity ใน schema
- ชื่อ field มี typo ที่ควรคงไว้ให้ตรงกันทั้ง FE/BE: `xp_first_message_fo_day`, `xp_10_message_fo_day`, `xp_react_message_fo_day` (`fo` = `of`)

### ข้อ 6 — Transparency = warning ไม่ block

[SC-PM-07](https://app.clickup.com/t/86d3dcfpz) ยืนยันตรงกัน: message "แนะนำให้ใช้ PNG ที่มี transparent background", trigger ระบุ "warning ไม่ใช่ error", acceptance criteria เขียนชัด "yellow banner ไม่บล็อก upload" → ไม่ต้องแก้อะไร ใช้ตาม spec.md เดิมได้เลย

### ข้อ 7 — Validation ที่ Figma ไม่มี UI (PM ไม่ได้ตอบ แต่ card เคลียร์ให้แล้ว)

- `FRAME_SIZE_MISMATCH` **มีแล้ว** ใน card ครบทั้ง message (`"Width ของรูป ({W}px) ต้องหารด้วย frame_count ({N}) ลงตัว"`), code, และ HTTP 400 → ทำ ไม่ใช่ feature อนาคต
- `frame_count` / `frame_rate` เป็น **per-animation** ไม่ใช่ global ต่อ stage — [SC-PM-03](https://app.clickup.com/t/86d3dcc8r) เขียนว่า "กำหนด frame_count และ frame_rate (fps) **ต่อ animation**"
- Range: `frame_count` 1–64, `frame_rate` 4–24 fps
- Server ต้อง validate magic bytes: PNG signature `89 50 4E 47`

### ข้อ 9 — Count badge = `workspace_usage_count`

เลขวงกลมข้างชื่อ pet คือ `workspace_usage_count` (ไม่ใช่ field ใหม่) — [SC-PM-01](https://app.clickup.com/t/86d3dcbx9) ระบุใน card content: Evolve sprite preview, ชื่อ, category badge, "4 stages", status, `workspace_usage_count`

---

## 🟡 ต้อง sync ตัวเลขให้ตรง (ไม่บล็อก)

### ข้อ 8 — Max dimension 1,000 × 1,000 px

เพิ่มใน [SC-PM-07](https://app.clickup.com/t/86d3dcfpz) แล้วเป็น error case ที่ **block** (ไม่ใช่ warning)

แต่ยังไม่มี **error code** ให้เคสนี้ — ตาราง "Validation Rules Summary" กับ "Error Codes & HTTP Status" ยังมีแค่ 5 code เดิม (`INVALID_FILE_TYPE`, `FILE_TOO_LARGE`, `INVALID_FRAME_COUNT`, `INVALID_FRAME_RATE`, `FRAME_SIZE_MISMATCH`) → ต้องตั้งเพิ่ม เช่น `IMAGE_TOO_LARGE` / `INVALID_DIMENSIONS` (400)

### ข้อ 10 — Pagination = 10 / page

PM เคาะ **10 / page** ตาม Figma แต่ [SC-PM-01](https://app.clickup.com/t/86d3dcbx9) ยังเขียน "pagination 20/หน้า" → ใช้ **10** เป็น default, card ต้องแก้ตัวเลข

---

## งานที่ต้องทำต่อ

**ฝั่ง PM / card** (AI ไม่แก้ ClickUp ตาม policy):

- [ ] SC-PM-03 — animation slots ต่อ stage (ข้อ 2) ยังเป็นโมเดลเดิม
- [ ] SC-PM-05 — flow assign pet (ข้อ 5) ยังเป็นฟอร์มเดิม
- [ ] SC-PM-01 — pagination 20 → 10
- [ ] SC-PM-07 — เพิ่ม error code ของเคส dimension เกิน
- [ ] [[Module] Pet Management](https://app.clickup.com/t/86d3dcbra) — ช่อง Scope ยังเขียน stage เก่า "(Egg/Hatch/Grow/Evolve)" ควรเป็น "(Egg/Baby/Adult/Evolved)"

**ฝั่งเรา**:

- [x] แก้ [spec.md](spec.md) ตามข้อ 1, 3, 4, 7, 8, 9, 10 ที่ปิดแล้ว (2026-08-14) — ส่วน SC-PM-03 animation matrix กับ SC-PM-05 flow คงเนื้อหาเดิมไว้ mark 🔴 รอเคลียร์
- [ ] ออกแบบ DB schema + API contract — **รอข้อ 2 กับ 5 ก่อน** เพราะทั้งคู่กระทบ table โดยตรง (animation slot key, room-pet placement/position)

---

## Reference

- Full spec เดิม (ล้าสมัยบางส่วน): [spec.md](spec.md)
- Figma breakdown ละเอียดทุก node: [ux-ui.md](ux-ui.md)
- Figma file: [Zyra design — More Organised ver.](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-)

