# Pet Management — Work Split (Dev 2 คน + AI)

> อ้างอิง: [spec.md](spec.md) · [db-schema-api-contract.md](db-schema-api-contract.md) (9-PR breakdown) · [ux-ui.md](ux-ui.md) · [pm-discussion-notes.md](pm-discussion-notes.md)
>
> สมมติฐาน: **Dev A = senior**, **Dev B = junior**, ทั้งคู่ใช้ AI ช่วยเขียนโค้ด — ถ้าทั้งคู่เป็น fullstack ระดับใกล้กัน การแบ่งนี้ใช้ไม่ได้ ต้องแบ่งเป็น vertical slice แทน
>
> **แผนเดิมด้านล่าง (08-17) ยังใช้ได้ แต่ PR 1–5 merge เข้า `develop` แล้ว** — งานที่เหลือจริงดูที่ [§งานที่เหลือ](#งานที่เหลือ--อัปเดต-2026-08-31) (ตรวจกับโค้ดเมื่อ 2026-08-31)

## งานที่เหลือ — อัปเดต 2026-08-31

> ที่มาของสถานะ: [progress-2026-08-31.md](progress-2026-08-31.md) (ผลตรวจโค้ดบน `origin/develop` — zyra-app `d748a39`, zyra-api `2419213`)
> รายละเอียดจุดที่ต้องเก็บย้อนหลัง (F1–F15): [code-findings-2026-08-31.md](code-findings-2026-08-31.md)

### สถานะ 9 PR

| # | PR | สถานะ | หมายเหตุ |
|---|---|---|---|
| 1 | `feat(api): pet type CRUD + migration` | ✅ merged | migration ใช้เลข **83** ไม่ใช่ 77 · ยังขาด 409 `PET_TYPE_IN_USE` + `workspace_usage_count` (ไปกับ PR 6) |
| 2 | `feat(api): pet animation upload + grid validation` | ✅ merged | เก็บ F3, F4, F5, F10, F11 |
| 3 | `feat(api): pet xp config + version history` | ✅ merged | ตรง contract ครบ |
| 4 | `feat(app): pet library + stage manager UI` | ✅ merged | 4a/4b/4d ครบ · **4c ยังไม่ครบ** (F8) · เก็บ F1, F2, F9 |
| 5 | `feat(app): xp config form` | ✅ merged | เก็บ F13 |
| 6 | `feat(api): room pet placement + realtime` | ✅ **merged 2026-09-04** [zyra-api #65](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/65) (`ce62893`, 3 commit: placement · PM rules · replace) | AI (ดู [Roompet/progress.md รอบ 12](../Roompet/progress.md)) — migration ใช้เลข **88** · เก็บ 409 `PET_TYPE_IN_USE` + `workspace_usage_count` (F7) ครบในรอบนี้ |
| 7 | `feat(ws): forward pet_* events` | 🟡 PR [zyra-ws #29](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/29) เปิด 2026-09-04 (6 type, pure relay) รอ merge | AI |
| 8a | `feat(app): pet palette + popup ตั้งชื่อ` | 🟡 โค้ดเสร็จ 2026-09-04 บน branch `feat/room-pet-map-editor` (zyra-app) live-test ผ่าน · PR [zyra-app #246](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/246) เปิดแล้ว | AI — รวม 8a+8b ใน PR เดียว ดู [Roompet/progress.md รอบ 13](../Roompet/progress.md) |
| 8b | `feat(app): pet drag-drop ใน Map Editor` | 🟡 เสร็จพร้อม 8a — marker เป็น DOM overlay ไม่ใช่ Pixi (Map Editor เป็น 2D canvas) · **stage row ยังไม่ทำ** รอ PM | AI |
| 9 | `feat(api): xp earning engine + ledger` | ⬜ ยังไม่เริ่ม | Dev A |

### ยังไม่เริ่มเลย — 4 PR

| PR | เจ้าของ | งานย่อย |
|---|---|---|
| **6** | Dev A | migration `tb_room_pet` (ยังไม่มีในรีโป — 83 สร้างแค่ 3 ตาราง) · 4 endpoint `/api/admin/maps/:mapId/pets` (GET/POST/PATCH/DELETE) · validate จุดวางอยู่ใน `zone_id` จริง (tiles JSONB ไม่ใช่ AABB — ใช้ `lib/zone-utils` ฝั่ง FE + ตรวจซ้ำใน service) · gate `status=active` + `stage_ready` ครบ → `PET_NOT_READY` · `POSITION_OUTSIDE_ZONE` · publish 4 event ผ่าน `ZoneEventPublisher` · **เก็บของค้างจาก PR 1**: `DELETE /pets/:id` คืน 409 `PET_TYPE_IN_USE` + เขียน `workspace_usage_count` (F7) |
| **7** | Dev A | เพิ่ม 6 type (`pet_spawned` / `pet_moved` / `pet_renamed` / `pet_removed` / `pet_stage_changed` / `pet_xp_changed`) ใน subscriber `vo:zone` — ปัจจุบัน ws รู้จักแค่ `zone_claim_changed`, `map_object_changed`, `map_updated` type อื่นถูกทิ้งเงียบ |
| **8a** | Dev B | pet palette panel ใน Map Editor + popup ตั้งชื่อตอนวาง — **ไม่แตะ Pixi scene** |
| **8b** | Dev A | drag-drop + render pet บน scene · อ่าน skill `vo-desync-debug` ก่อนแตะ |
| **9** | Dev A | migration `tb_room_pet_xp_event` + `uq_room_pet_xp_daily` ที่ต้อง `COALESCE(user_id,'')` · hook 10 activity เข้า flow จริง · `day_key` UTC+7 · derive `stage`/`mood` ห้ามเก็บคอลัมน์ · `last_seen_stage` detect transition → ยิง `pet_stage_changed` · throttle `pet_xp_changed` |

> ⚠️ **เลข migration** — แผนเดิมเขียน `77_pet_management.sql` แต่ของจริงลงเป็น 83 / 84 / 85 และตอนนี้เลขสูงสุดในรีโปคือ **86** (แถม 85 ถูกใช้ซ้ำ 3 ไฟล์แล้ว) → migration ของ PR 6 / PR 9 ต้องเช็กเลขว่างก่อนตั้งชื่อ อย่าถือว่า 87 ว่างโดยไม่ดู

### ไม่มีใครเป็นเจ้าของใน 9 PR — ต้องเพิ่มใบใหม่

| PR ใหม่ | เจ้าของ | งาน | หลักฐานว่าตกหล่น |
|---|---|---|---|
| **10** `feat(api): member pet endpoints` | Dev A | `GET /api/user/workspaces/:workspaceId/pets` (+ derived `stage`/`mood` + animation URL ครบ) · `POST /api/user/workspaces/:workspaceId/pets/:petId/play` (idempotent วันละครั้ง/คน) | อยู่ใน [db-schema-api-contract.md §Member](db-schema-api-contract.md) แต่ไม่ปรากฏใน PR 1–9 เลย |
| **11** `feat(app): render pet ใน VO` | Dev A | render pet บน VO scene ฝั่ง member · เล่น animation ตาม stage/mood · ลำดับแถว direction ต้อง import จาก `AVATAR_DIR_ROW` | "เกณฑ์ก่อนเปิด Feature Flag" ระบุ "render ตาม stage/mood" แต่ PR 8 คือ Map Editor เท่านั้น · ข้อสมมติลำดับแถว (`0=down 1=left 2=right 3=up`) **ยังไม่มีใครใช้ = ยังไม่เคยพิสูจน์กับ sprite จริง** |

### ของที่ต้องเก็บใน PR ที่ merge แล้ว

รายละเอียดเต็ม (ไฟล์:บรรทัด + วิธี verify) อยู่ใน [code-findings-2026-08-31.md](code-findings-2026-08-31.md)

| ระดับ | ID | เรื่อง | repo |
|---|---|---|---|
| บล็อก UAT | F3 | เพดาน 1000px / 1MB ขัดกับ frame_count ที่ล็อกไว้ 50 → อัปชีทจริงไม่ผ่าน | api + app |
| ต้องแก้ | F1 · F2 | progress bar ยังเป็นสเกล 17 slots · preview modal hardcode 6×4@8fps + ทิ้ง metadata | app |
| ต้องแก้ | F4 · F5 | `FRAME_SIZE_MISMATCH` ไม่ได้เช็ค modulo · error detail ไม่แนบ `{width, frame_count}` / `{height, direction_rows}` | api |
| ต้องแก้ | F8 | SC-PM-07 ฝั่ง FE — toast ยัง generic ตัวเดียว + ไม่มี client-side pre-check | app |
| ตกหล่น | F6 · F7 | ไม่มี `POST /pets/:id/thumbnail` · `workspace_usage_count` ไม่มีใครเขียน | api |
| ปรับให้ตรง | F9 · F10 · F11 | Pet Library ไม่ใช้ TanStack key ตาม contract · S3 key slot ตัวเล็ก · GIF ที่ slot Evolution ไม่มีในเอกสาร | app / api |
| คุณภาพ | F12 · F13 · F14 | Go test ครอบแค่ pure function (ไม่มี `pet_handler_test.go` / ไม่มี mock DB) · XP panel import `@/components/ui/*` ผิด rule 08 · search ไม่มี debounce | api / app |
| ตัดสินใจ | F15 | flag ปิดแค่เมนู — route + `/api/admin/pets*` ยังเข้าได้ | app + api |

### blocker — ต้องได้คำตอบก่อนลงมือ

| ต้องได้ก่อน | คำถาม |
|---|---|
| แก้ F1 / F2 | **17 หรือ 20 slots** — โค้ดใช้ 20 (Egg 2 + Baby/Adult/Evolved ละ 6 โดยเพิ่ม `Idle`) แต่ [§RequiredSlots(stage)](#requiredslotsstage--ค่าที่ใช้-ยึด-figma) ในเอกสารนี้เขียน 17 (ละ 5) — ตอบก่อนไม่งั้นแก้ progress bar เสร็จต้องแก้อีกรอบ |
| แก้ F3 | **metadata ต่อ animation** — เปิดให้ตั้งเองตาม spec หรือรับค่า fixed 50/24/4 อย่างเป็นทางการ (คำตอบกำหนดว่าจะยกเพดาน หรือปลดล็อกฟอร์ม) |
| merge PR 6 / 8 | ~~1 room = 1 pet บังคับไหม~~ ✅ **PM 2026-09-04: บังคับ** (`uq_room_pet_one_per_zone` เปิดแล้ว) + วางได้เฉพาะ `room` zone, จุดวางห้ามตกใน meeting/private แม้ซ้อนใน room · **ยังค้าง:** วาง pet ใน Workspace Template แล้ว workspace ที่สร้างไปก่อนหน้าได้ pet ด้วยไหม |
| merge PR 9 | mood ช่วง 48–72 ชม. เป็น state อะไร · activity ตัวไหน per-user ตัวไหน per-room · `xp_play_with_pet` คือ interaction แบบไหนใน VO (ยังไม่มี spec member-side) |
| F15 | เจตนาของ `NEXT_PUBLIC_PET` — ปิดแค่เมนู หรือต้องปิด route + API ด้วย |

### เวลาที่เหลือ

| ช่วง | PR | กินเวลา |
|---|---|---|
| Placement + realtime + Map Editor | 6, 7, 8a, 8b | D1–D5 |
| XP earning engine | 9 | D6–D7 |
| Member API + VO render (ใบใหม่) | 10, 11 | D7–D9 |
| เก็บ F1–F15 | — | +1–2 วัน (ขนานกับ 8a ได้บางส่วน) |
| **รวม** | | **~8–10 วันทำการ** |

คอขวดยังเป็น **คิวของ Dev A** เหมือนเดิมและหนักกว่าแผนเดิม — 6 → 7 → 8b → 9 → 10 → 11 ต่อกัน 6 ใบ ขณะที่งานที่โยนให้ Dev B ขนานได้จริงมีแค่ 8a + ข้อ F1/F2/F8/F9/F13/F14 ฝั่ง FE ถ้าจะคลายต้องแยก PR 10 (member API เป็น read endpoint ตรงไปตรงมา + มี precedent ใน `/api/user/*`) ออกมาให้ Dev B ทำใต้ review ของ Dev A

## ✅ PM ปิด 2 blocker แล้ว (2026-08-17)

| ข้อ | คำตอบ | ผลต่อแผน |
|---|---|---|
| **ข้อ 2** — animation | **รวมทุก direction ในไฟล์เดียว** = ตรงกับ model ใน Figma ([ux-ui.md](ux-ui.md#-stage--animation-model-จริงจาก-figma-ต่างจาก-specmd-ทั้งหมด)) | ปลด PR 2, 4d — **แต่ schema ต้องแก้ก่อนเขียน migration 77** ดูหัวข้อถัดไป |
| **ข้อ 5** — assign pet | **Map Editor drag-drop / ตัด tab "Assign to Room" / ตั้งชื่อตอนวาง** | ปลด PR 6, 8 — endpoint ใช้ชุด map-scoped, ตัด scope FE ออก 1 tab |
| **ทั่วไป** | **stage/animation model ยึดตาม Figma** เมื่อขัดกับ ClickUp card | ปิดคำถามย่อย Egg count + Evolved slot (ดูล่าง) |

**ไม่มี PR ไหน block แล้ว — ทั้ง 9 ใบเริ่มได้ตามลำดับ dependency ปกติ**

> ⚠️ **ข้อยกเว้นของกฎ "ยึด Figma"** — sticky note ใน Figma เขียน `Happy XP (50%)` ซึ่งกลับหัวกับ card ที่ระบุ Happy = **150%** (bonus) จุดนี้ยัง**ยึด card** ตามที่ตัดสินไว้ใน [spec.md:197](spec.md) เพราะ Happy = penalty ไม่สมเหตุสมผล — กฎยึด Figma ใช้กับ **stage/animation model** เท่านั้น ไม่ใช่ค่าตัวเลข XP

## สรุปเวลา

| ช่วง | PR | กินเวลา |
|---|---|---|
| Contract setup | — | D0 (ครึ่งวัน) |
| BE core + FE ที่ไม่พึ่ง upload | 1, 3, 5, 4a, 4b, 4c | D1–D3 |
| Animation + Stage Manager | 2, 4d | D3–D5 |
| Placement + realtime + Map Editor | 6, 7, 8 | D5–D7 |
| XP earning engine | 9 | D8–D9 |
| **รวม** | | **~9 วันทำการ** |

คอขวดใหม่ไม่ใช่ PM แล้ว แต่เป็น **คิวของ Dev A** — PR 8 (Pixi) กับ PR 9 (XP engine) เป็นงาน senior-only ที่ต่อท้ายกัน ดูวิธีคลายที่หัวข้อ [Dev B](#dev-b-junior--nextjs-zyra-app-ทั้งหมด)

---

## Schema delta จากคำตอบข้อ 2 / ข้อ 5

✅ **[db-schema-api-contract.md](db-schema-api-contract.md) แก้ตามนี้เรียบร้อยแล้ว (2026-08-17)** — ตารางนี้เก็บไว้เป็นสรุปว่าเปลี่ยนอะไรบ้าง ให้ senior เช็กตอนเขียน migration 77 ว่าครบทุกข้อ

| เปลี่ยน | draft เดิม (08-14) | ที่ใช้จริง |
|---|---|---|
| `tb_pet_animation` | ไม่มี | เพิ่ม `direction_rows INT NOT NULL DEFAULT 1` + CHECK แบบหลวม (`>= 1`) ไปก่อน |
| สูตร frame | `frame_width = sprite_width / frame_count` เท่านั้น | + `frame_height = sprite_height / direction_rows` (spritesheet เป็น **grid** ไม่ใช่ strip) |
| ลำดับแถว | ไม่มี | ⏸ **รอดู sprite จริงจาก artist** — สมมติฐาน: reuse `AVATAR_DIR_ROW` (`0=down 1=left 2=right 3=up`) เขียนโค้ดให้ import จาก const นั้นตั้งแต่แรก |
| Validation | มีแค่ `width % frame_count = 0` | + `height % direction_rows = 0` → error code ใหม่ (เสนอ `FRAME_ROW_MISMATCH`) |
| slot vocabulary (Go const) | `walk_n/walk_s/walk_e/walk_w/idle/sit` | `Wobbling` `Walking` `Sitting` `Happy` `Sad` `Evolution` |
| `RequiredSlots(stage)` | ยังไม่กำหนด | Egg = 2 slot · Baby/Adult/Evolved = 5 slot (ตารางเต็มด้านล่าง) |
| Placement endpoint | มี 2 ทางเลือก (form vs map-scoped) | ใช้ **map-scoped ชุดเดียว** `/api/admin/maps/:mapId/pets` — ตัด `POST /api/admin/pets/:id/assign` ทิ้ง |
| FE scope | มี tab "Assign to Room" | **ตัดทิ้ง** — placement อยู่ใน Map Editor เท่านั้น |
| `tb_room_pet.name` | optional | ยังเป็น optional max 30 — แต่ UI ตั้งชื่อย้ายไปอยู่ตอนวางบน Map Editor |

### `RequiredSlots(stage)` — ค่าที่ใช้ (ยึด Figma)

| Stage | Required slots | Count | ที่มา |
|---|---|---|---|
| `egg` | `Wobbling`, `Evolution` | 2 | animation dropdown ของ Egg ใน preview modal (node #5) |
| `baby` | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5 | animation dropdown ของ Baby (node #6) |
| `adult` | เหมือน `baby` | 5 | ⚠️ ไม่มี frame ที่โชว์ตรง ๆ — อนุมานตาม Figma |
| `evolved` | เหมือน `baby` (รวม `Evolution`) | 5 | ⚠️ ไม่มี frame ที่โชว์ตรง ๆ — อนุมานตาม Figma |

- **Egg = 2 ไม่ใช่ 3** — counter ใน node #4/#9 โชว์ `3/3` แต่ **animation dropdown โชว์แค่ 2 รายการ** ([ux-ui.md:350](ux-ui.md)) dropdown เป็นรายการ animation จริง ส่วน counter น่าจะเป็น mockup ที่ไม่ sync → ยึด dropdown
- **Evolved มี `Evolution` ด้วย** — แม้ไม่มีอะไรให้ evolve ต่อ แต่ Figma ไม่ได้แยก Evolved ออกจาก stage อื่น ให้ upload ครบไว้ก่อน ถ้าไม่ได้ใช้จริงก็แค่ไม่มีใครเรียก

### คำถามที่ยังค้าง (ไม่บล็อก)

**กฎ 1 room = 1 pet ยังบังคับไหม** — Figma ไม่ได้ตอบเรื่องนี้ และ PM ตอบแค่ flow

ค่า default ที่ใช้ไปก่อน: **ยังไม่เปิด** `uq_room_pet_one_per_zone` (วางได้หลายตัวต่อห้อง) เพราะเพิ่ม unique index ทีหลังทำได้ถ้ายังไม่มีข้อมูลซ้ำ แต่ถ้าเปิดไปแล้วจะปลดยากกว่า — ถ้า PM ยืนยันว่าบังคับ ให้เปิด index + คืน `409 ZONE_ALREADY_HAS_PET` ตามที่ design doc เขียนไว้

---

## ตารางเวลา

| วัน | Dev A (senior) | Dev B (junior) |
|---|---|---|
| **D0** (ครึ่งวัน) | setup contract + แก้ schema ตามข้อ 2 (ดูหัวข้อบน) | อ่าน precedent + rules |
| **D1** | PR 1 — pet type CRUD | PR 5 — XP config form |
| **D2** | PR 3 — XP config API | PR 4a — Pet Library |
| **D3** | PR 2 — animation upload + grid validation | PR 4b + 4c |
| **D4** | review เลน B + verify upload บน dev | PR 4d — Stage Manager |
| **D5** | PR 6 — placement + realtime publish | PR 4d ต่อ + preview modal |
| **D6** | PR 7 — ws forward + PR 8b (Pixi drag-drop) | PR 8a — pet palette + rename UI |
| **D7** | PR 8b ต่อ + verify 2-client | QA fix |
| **D8–D9** | PR 9 — XP engine + verify ไม่จ่ายซ้ำ | QA fix / Vitest ให้ครบ |

---

## D0 — senior ต้องลงของนี้ก่อน ไม่งั้น junior ตัน

ครึ่งวัน แล้วสองคนแยกเลนได้จริง

| ลง | ทำไม |
|---|---|
| `zyra-api/migrations/77_pet_management.sql` (5 table, **รวม `direction_rows` แล้ว**) | เจ้าของไฟล์คนเดียว — junior ห้ามแตะ ไม่งั้น conflict/เลขชน |
| `zyra-api/internal/model/pet.go` — struct + slot const 6 ตัว + `RequiredSlots(stage)` | เป็นสัญญาที่ FE ยึด |
| `zyra-app/lib/api/pets.ts` — **เขียนแค่ type + function signature** (ตัด `assign` ออก เหลือ map-scoped) | junior เขียน UI ทับได้เลย implement body ทีหลัง |
| stub handler ตอบ fixture ตาม example response ในเอกสาร API contract | junior เห็นข้อมูลจริงตั้งแต่วันแรก ไม่ต้องรอ BE เสร็จ |
| route ทั้ง 3 group ใน `router.go` (ตอบ 501 ไปก่อนก็ได้) | กันไม่ให้ต้องแก้ไฟล์นี้ซ้ำหลายรอบ |

---

## Dev A (senior) — Go + zyra-ws + Pixi

| วัน | PR | งาน |
|---|---|---|
| D1 | 1 | `feat(api): pet type CRUD + migration 77` (SC-PM-01/02) |
| D2 | 3 | `feat(api): pet xp config + version history` (SC-PM-04) |
| D3 | 2 | `feat(api): pet animation upload + grid validation` (SC-PM-03/07) |
| D5 | 6 | `feat(api): room pet placement + realtime` (SC-PM-05) |
| D6 | 7 | `feat(ws): forward pet_* events` (6 type) |
| D6–D7 | 8b | `feat(app): pet drag-drop ใน Map Editor` — เฉพาะส่วน Pixi scene |
| D8–D9 | 9 | `feat(api): xp earning engine + ledger` |

### จุดที่ต้องระวังเป็นพิเศษ (senior เท่านั้น)

- **PR 2 grid validation** — spritesheet เป็น grid แล้ว ต้อง validate **2 แกน** (`width % frame_count` และ `height % direction_rows`) ไม่ใช่แกนเดียวเหมือนที่ design doc เขียนไว้
- **ลำดับแถว direction ต้อง import จาก `AVATAR_DIR_ROW`** ไม่ใช่พิมพ์เลข 0-3 ใหม่ — engine มี single source of truth อยู่แล้ว ถ้าแยกกันแล้วเปลี่ยนภายหลัง pet จะหันผิดทิศเงียบ ๆ (⏸ ยังไม่ยืนยันว่า sprite จริงเรียงแบบนี้ — แต่ import จาก const ไว้ก่อนถูกกว่าพิมพ์เลขเอง ไม่ว่าคำตอบจะเป็นอะไร)
- **PR 9 idempotency** — `uq_room_pet_xp_daily` ใช้ `COALESCE(user_id, '')` ถ้าลืมจะกันจ่ายซ้ำไม่ได้เลย (NULL ไม่ชนกันเองใน unique index)
- **`day_key` เป็น UTC+7 ไม่ใช่ UTC** — ไม่งั้น "ข้อความแรกของวัน" รีเซ็ตตอน 7 โมงเช้า
- **derived `stage`/`mood`** — ห้ามเก็บลงคอลัมน์ (เหตุผลใน design doc หลักการข้อ 1)
- **PR 8b Map Editor** — VO movement/render เป็น bug family ที่ลึกมาก อ่าน skill `vo-desync-debug` ก่อนแตะ scene

---

## Dev B (junior) — Next.js (zyra-app) ทั้งหมด

ลำดับตามนี้ อย่าสลับ — ไล่จากง่าย/ปิดสนิท ไปหายากขึ้น

| วัน | PR | งาน | ทำไมเหมาะ junior |
|---|---|---|---|
| D1 | 5 | XP Config form (SC-PM-04) | spec ปิด 100% ตัวเลขครบทุกช่อง (10 activity + 3 mood + 3 threshold) เป็น number input ล้วน ไม่มี upload ไม่มี realtime พังก็ไม่กระทบใคร |
| D2 | 4a | Pet Library grid + filter/search/sort/pagination (SC-PM-01) | copy pattern จาก `views/admin/avatar-management/` ได้เกือบทั้งดุ้น |
| D3 | 4b | ฟอร์มสร้าง Pet Type step 1 (SC-PM-02) | CRUD ฟอร์มธรรมดา redirect ต่อ Stage Manager |
| D3 | 4c | Error toast + client-side validation (SC-PM-07) | ตาราง rule 6 บรรทัดตายตัว เขียน Vitest ง่าย เห็นผลไว |
| D4–D5 | 4d | Stage Manager UI (SC-PM-03) + Pet preview modal | ✅ ปลดแล้ว — 4 stage tab, slot list ตายตัว 6 ตัว, upload card + preview canvas |
| D6 | 8a | Pet palette ใน Map Editor + popup ตั้งชื่อตอนวาง | เป็น panel/ฟอร์มธรรมดา **ไม่แตะ Pixi scene** — ส่วน drag-drop จริงเป็นของ Dev A (8b) |

> **การแยก PR 8 → 8a/8b คือตัวคลายคอขวด** — ถ้าไม่แยก Dev A จะมี PR 8 + PR 9 ต่อกันคนเดียว 4 วันรวด ขณะที่ Dev B ว่าง

### Precedent ที่ให้ junior ไปอ่านก่อนเริ่ม (D0)

| ต้องการ | ดูของเดิมที่ |
|---|---|
| Admin list page + filter/sort/pagination | `zyra-app/views/admin/avatar-management/` |
| Admin page shell + sidebar | `components/admin/admin-sidebar.tsx` (rule 09 — ห้ามสร้าง sidebar ใหม่) |
| API call + TanStack Query key | `lib/api/avatars.ts`, `lib/api/objects.ts` |
| Upload form (FormData) | `authFetchForm` ใน `lib/api/client.ts` |
| Map Editor panel / palette | `zyra-app/views/admin/workspace-editor/` |

### กฎที่ junior ต้องอ่านก่อนเขียนบรรทัดแรก

- [08-shadcn-ui.md](../../../.claude/rules/08-shadcn-ui.md) — **Tailwind-only** ห้าม import `@/components/ui/*` (ยกเว้น skeleton/icon)
- [12-icons.md](../../../.claude/rules/12-icons.md) — icon จาก `lucide-react` เท่านั้น
- [10-figma-fidelity.md](../../../.claude/rules/10-figma-fidelity.md) — ห้ามเดา spacing/สี ใช้ค่า exact จาก [ux-ui.md](ux-ui.md)
- [09-component-reuse.md](../../../.claude/rules/09-component-reuse.md) — ค้นของเดิมก่อนสร้างใหม่เสมอ
- [17-git-branch-workflow.md](../../../.claude/rules/17-git-branch-workflow.md) — แตก `feat/*` จาก `develop` เท่านั้น

---

## งานที่ห้ามให้ junior เด็ดขาด

| งาน | เหตุผล |
|---|---|
| migration ทุกไฟล์ | เลข migration ชน + rollback ยาก |
| PR 9 — XP earning engine | idempotency + timezone + unique index พลาดแล้วจ่าย XP ซ้ำแบบเงียบ ๆ |
| PR 8b — Pixi drag-drop scene | แตะ Pixi scene = bug family ที่แก้มา 8 รอบ (8a panel UI ทำได้) |
| PR 7 — zyra-ws event forward | พังแล้วกระทบ VO ทั้งระบบ ไม่ใช่แค่ pet |
| แก้ type ใน `lib/api/pets.ts` | เป็นสัญญาข้ามคน ถ้าไม่ตรงให้ทัก senior ไม่ใช่แก้เอง |

---

## ที่ต้องระวังเมื่อทีมใช้ AI

### AI ยุบให้ / ไม่ยุบให้

| ยุบเกือบหมด | ไม่ยุบเลย |
|---|---|
| เขียน CRUD handler/service ตาม precedent | review ว่าโค้ดที่ได้ถูกจริง (ไม่ใช่ดูเหมือนถูก) |
| เขียนฟอร์ม + Tailwind ตาม Figma spec | verify บน dev จริง (upload, realtime, XP ไม่จ่ายซ้ำ) |
| เขียน table-driven test / Vitest | QA / UAT round |
| แปลง type contract FE↔BE | decision ที่ต้องถามคน (ดูคำถามที่ยังค้าง) |

### กติกา

- **Review คือคอขวด** ไม่ใช่การเขียน — senior คนเดียวรีวิว output ของสองเลนที่ผลิตเร็วขึ้นหลายเท่า ให้จำกัด WIP ที่ **1 PR ต่อคน** อย่าปล่อยให้ค้างรีวิวพร้อมกัน 4 ใบ (นี่คือเหตุผลที่ D4 ของ Dev A เป็นวัน review ล้วน ไม่ใช่วันเขียนโค้ด)
- **รายการ "ห้ามให้ junior" ยิ่งสำคัญขึ้น** — AI เขียน idempotency/timezone ที่ดูสมเหตุสมผลแต่ผิดได้อย่างแนบเนียน คนที่รีวิวต้องรู้ว่าผิดตรงไหน ไม่ใช่แค่เห็นว่า test เขียว
- **ห้ามให้ AI เดา Figma** — rule 10 บังคับดึง spec จริง ค่าที่ AI เดาจะ "ดูใกล้เคียง" แต่ไม่ตรง
- **verify บน dev ต้องทำจริงทุก PR** — โค้ดที่ compile ผ่านและ test เขียว ยังไม่ได้แปลว่า upload/realtime ทำงาน

---

## จุดที่จะชนกัน — กันไว้ก่อน

1. **`zyra-api/internal/router/router.go`** — senior คนเดียวแตะ ลง route ทั้งหมดรวดเดียวตั้งแต่ D0
2. **`zyra-app/lib/api/pets.ts`** — senior เขียน type, junior เขียน function body เท่านั้น
3. **`77_pet_management.sql`** — ไฟล์เดียวจบ ห้ามแตกเป็น 77/78 คู่ขนาน
4. **Map Editor (D6)** — 8a กับ 8b แตะ feature เดียวกัน ให้ 8a เป็นไฟล์ panel/palette แยก ส่วน 8b แตะ scene เท่านั้น คุยกันก่อนเริ่มว่าไฟล์ไหนของใคร
5. **Prettier** — repo ยังไม่ clean ทั้งหมด อย่ารัน `prettier --write` ทั้งไฟล์ (จะกลบ diff ตัวเอง) ให้ format เฉพาะบรรทัดที่แก้

---

## ลำดับ merge

```
D1  A: feat/pet-api-crud      ──┐
D1  B: feat/pet-xp-form       ──┼─→ develop → verify บน dev
D2  A: feat/pet-xp-config-api ──┘
```

- PR 5 (junior, D1) merge ก่อน PR 3 (senior, D2) ได้เลย เพราะกิน stub อยู่ — **อย่าให้ junior รอ BE**
- ทุก PR ผ่าน review ตาม [05-review.md](../../../.claude/rules/05-review.md) ก่อน merge เข้า `develop`
- `develop → main` และ tag `v*` ต้อง confirm กับผู้ใช้ทุกครั้ง (deploy uat/prod อัตโนมัติ)
