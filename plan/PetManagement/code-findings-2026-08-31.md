# Pet Management — จุดที่โค้ดต่างจากเอกสาร (ส่งให้ dev)

> **สถานะ:** ผลตรวจโค้ด 2026-08-31 — **ยังไม่มีใครแก้** ทุกข้อในไฟล์นี้เป็นของที่พบจากการอ่านโค้ด ไม่ได้แตะโค้ดเลย
> **base ที่ตรวจ:** zyra-app `d748a39` · zyra-api `2419213` (ทั้งคู่คือ `origin/develop` — โค้ด Pet merge เข้า develop แล้ว)
> **verify แล้ว:** `go build ./...` เขียว · `go test ./internal/service/... ./internal/handler/... -run 'Pet|XP'` ผ่าน · Vitest pet 5 ไฟล์ / 39 tests ผ่าน · **ยังไม่ได้ live-test บน dev / ยังไม่ได้ UAT ไฟล์ sprite จริง**
> **repo ที่กระทบ:** zyra-app, zyra-api · **เอกสารอ้างอิง:** [progress-2026-08-31.md](progress-2026-08-31.md) · [db-schema-api-contract.md](db-schema-api-contract.md) · [work-split.md](work-split.md)
> **อัปเดต 2026-09-01** — หลังดู sprite จริง (`zyra-app/public/image/petdemo/Cat_Adult_Happy.png`) และ user เคาะ decision แล้ว: **F1 / F2 / F3 เขียนใหม่** (ตอนตรวจรอบแรกยังไม่เห็น asset จริง) และคำถามข้อ 1-2 ท้ายไฟล์ปิดแล้ว — กฎที่เป็นทางการอยู่ใน [spec.md](spec.md)

สถานะรายหัวข้อใน [progress-2026-08-31.md](progress-2026-08-31.md) **ตรงกับโค้ดทั้งหมด** ไฟล์นี้คือส่วนที่เอกสารยังไม่ได้บันทึก — เรียงตามความเร่งด่วน

## ตารางสรุปเพื่อ assign

| ID | เรื่อง | repo | ระดับ | ต้องรอคำตอบก่อนไหม |
|---|---|---|---|---|
| F1 | `PET_UPLOAD_TOTAL` เป็น 20 (มี `Idle`) แต่ของจริงคือ 17 | zyra-app + zyra-api | ต้องแก้ | ✔️ เคาะแล้ว = **17** |
| F2 | preview modal ทิ้ง metadata จริง (hardcode 6×4@8) | zyra-app | ต้องแก้ | ✔️ เคาะแล้ว |
| F3 | กฎ sprite ปัจจุบัน reject/ตัด asset จริงของ artist | zyra-api + zyra-app | **บล็อก UAT** | ✔️ เคาะแล้ว |
| F4 | `validatePetSpriteDimensions` ยังใช้สูตรเก่า (ไม่ใช่เซลล์จัตุรัส) | zyra-api | ต้องแก้ | ✔️ เคาะแล้ว |
| F5 | error detail ไม่แนบตัวเลขตาม contract | zyra-api | ต้องแก้ | — |
| F6 | ไม่มี `POST /pets/:id/thumbnail` | zyra-api | ตกหล่น | — |
| F7 | `workspace_usage_count` ไม่มีใครเขียน | zyra-api | ตกหล่น | ต่อ PR 6 |
| F8 | toast ไม่ map ต่อ error code + ไม่มี client-side pre-check | zyra-app | ต้องแก้ (SC-PM-07) | — |
| F9 | Pet Library ไม่ได้ใช้ TanStack Query key ตาม contract | zyra-app | ปรับให้ตรง | — |
| F10 | S3 key ใช้ slot ตัวเล็ก ต่างจาก contract | zyra-api | ตัดสินใจ | — |
| F11 | รับ GIF ที่ slot Evolution — contract ไม่มีเขียน | zyra-api | อัปเดตเอกสาร | — |
| F12 | ขอบเขต Go test แคบกว่าที่รายงานไว้ | zyra-api | ต้องเพิ่ม test | — |
| F13 | XP panel import `@/components/ui/*` ผิด rule 08 | zyra-app | ต้องแก้ | — |
| F14 | search ไม่มี debounce | zyra-app | เล็กน้อย | — |
| F15 | `NEXT_PUBLIC_PET` gate แค่เมนู route/API ยังเปิด | zyra-app + zyra-api | ตัดสินใจ | ✅ ถามว่าเจตนาคืออะไร |

---

## กลุ่ม 1 — ต้องแก้ก่อน (มองเห็นได้ / บล็อก UAT)

### F1 — โค้ดใช้ 20 slots (มี `Idle`) แต่ของจริงคือ 17

- **เคาะแล้ว 2026-09-01: ใช้ 17 slots** — Egg 2 (`Wobbling`, `Evolution`) + Baby/Adult/Evolved ละ 5 (`Walking`, `Sitting`, `Happy`, `Sad`, `Evolution`) ตาม [spec.md SC-PM-03](spec.md)
- **ต้องแก้ 4 ที่ให้ `Idle` หายไป:**
  - `zyra-api/internal/model/pet.go:35-40` — ถอด `PetSlotIdle` ออกจาก `RequiredPetSlots` (และ const ถ้าไม่ได้ใช้ที่อื่น)
  - `zyra-api/internal/database/postgres.go` + `migrations/84_pet_animation_idle_slot.sql` — ถอด `'Idle'` ออกจาก CHECK และ **ล้าง row ที่ `slot = 'Idle'` ก่อนใส่ constraint ใหม่** (ไม่งั้น ALTER ไม่ผ่าน)
  - `zyra-app/views/admin/pet-management/pet-upload-config.ts` — `GROWN_STAGE_ANIMATIONS` ตัด `idle` ออก → `PET_UPLOAD_TOTAL` = 17
- **ผลพลอยได้:** `PET_UPLOAD_PROGRESS_WIDTHS` (`pet-detail-panel.tsx:33-52`) มี 18 ค่า = สเกล 17 ขั้นพอดี **ถ้า total กลับเป็น 17 บาร์จะตรงเอง** — ไม่ต้องรื้อตาราง แต่แนะนำให้เปลี่ยนไปคำนวณจาก `uploaded / PET_UPLOAD_TOTAL` อยู่ดี เพื่อไม่ให้พังอีกถ้าจำนวน slot เปลี่ยน
- **verify:** อัปครบ 17/17 แล้วบาร์เต็มพอดี · `stage_ready` ของทั้ง 4 stage เป็น true · pet ที่เคยอัป `Idle` ไว้ต้องไม่ค้างใน DB

### F2 — preview modal ทิ้ง metadata จริงแล้ว hardcode ค่าไว้

- **ไฟล์:** `zyra-app/views/admin/pet-management/components/pet-preview-modal.tsx:166` (`void animationMeta`) และ `:177-180`
- **สถานะจริง (แก้จากรอบตรวจแรก):** ค่าที่ hardcode ไว้ (6 เฟรม × 4 แถว @ 8fps) **ตรงกับ asset จริงของ artist** — `Cat_Adult_Happy.png` เป็น 6 ท่า × 4 ทิศ และ 8fps คือ `AVATAR_WALK_FPS` ที่ engine ใช้ ค่าที่ผิดคือ **ฟอร์ม upload ที่ล็อก 50 เฟรม / 24 fps** (ดู F3)
- **แต่ยังต้องแก้อยู่ดี:** modal รับ `animationMeta` (ค่าจริงจาก DB) แล้ว `void` ทิ้ง → พอ artist ส่งไฟล์ที่ใช้ค่าอื่น (เช่น `Wobbling` ที่มีทิศเดียว) preview จะเล่นผิดทันทีโดยไม่มีอะไรเตือน
- **ต้องแก้:** อ่าน `frame_count` / `frame_rate` / `direction_rows` จาก `animationMeta[key]` เป็นหลัก → fallback เป็นค่าที่ฟอร์มส่งมา → fallback สุดท้าย 6/4/8 · เพิ่ม empty state ต่อ (stage, animation) ที่ยังไม่มีไฟล์
- **verify:** อัปไฟล์ที่ `frame_count ≠ 6` หรือ `direction_rows = 1` แล้วดูว่า preview เดินตามค่าจริง

### F3 — กฎ sprite ปัจจุบัน reject / ตัด asset จริงของ artist (บล็อก UAT)

- **ไฟล์:** `zyra-api/internal/service/pet_service.go:512-523` (`validatePetSpriteDimensions`) · `zyra-app/.../pet-upload-step.tsx:241-303` (ล็อก `frameCount=50` / `frameRate=24` + `<select disabled>`)
- **ทดสอบกับ asset จริง** `zyra-app/public/image/petdemo/Cat_Adult_Happy.png` (1000×1000, 6 ท่า × 4 ทิศ):

| กฎปัจจุบัน | ผลกับไฟล์จริง |
|---|---|
| `width % frame_count = 0` (contract) | `1000 % 6 = 4` → **reject ไฟล์ทั้งชุด** |
| `frame_height = height / direction_rows` | `1000/4 = 250` แต่แถวจริงสูง ~166 → เส้นแบ่งที่ y=250 มีพิกเซลทึบ **624 พิกเซล** = ตัดแมวครึ่งตัว |
| ฟอร์มล็อก 50 เฟรม / 24 fps | ของจริงคือ **6 เฟรม / 8 fps** — และ 50 เฟรมบนชีท 1000px จะเหลือเฟรมกว้าง 20px |

- **กฎใหม่ที่เคาะแล้ว** (รายละเอียด + ผลวัดอยู่ใน [spec.md § Sprite Grid](spec.md)):
  - ชีทต้องเป็น **1000 × 1000 px เท่านั้น** (reuse `requiredSpritesheetDim` จาก `avatar_service.go`)
  - เซลล์ **จัตุรัส**: `frame_width = frame_height = floor(width / frame_count)` · อ่าน `direction_rows` แถวจากด้านบน · ที่เหลือปล่อยว่างได้
  - ทิ้งกฎหารลงตัวทั้ง 2 แกน → ตรวจแทนด้วย `frame_size ≥ 16px` (`FRAME_SIZE_MISMATCH`) และ `direction_rows × frame_size ≤ height` (`FRAME_ROW_MISMATCH`)
  - ฟอร์มปลดล็อกทั้ง 3 ช่อง default **6 / 8 / 4**
- **verify:** อัป `Cat_Adult_Happy.png` ด้วย `frame_count=6, frame_rate=8, direction_rows=4` ต้องผ่าน และ preview ต้องเห็นแมวเต็มตัวทั้ง 24 เฟรม

## กลุ่ม 2 — ไม่ตรง [db-schema-api-contract.md](db-schema-api-contract.md)

### F4 — `validatePetSpriteDimensions` ยังใช้สูตรเก่าทั้งฟังก์ชัน

- **ไฟล์:** `zyra-api/internal/service/pet_service.go:512-523`
- ตอนนี้: `width/height ≤ 1000` · `width < frame_count → FRAME_SIZE_MISMATCH` · `height % direction_rows ≠ 0 → FRAME_ROW_MISMATCH` · คืน `(width/frame_count, height/direction_rows)`
- **ต้องเปลี่ยนเป็น** (ตาม [spec.md § Sprite Grid](spec.md)):
  1. `width == 1000 && height == 1000` ไม่งั้น `INVALID_DIMENSIONS` (ตอนนี้เป็น "ไม่เกิน" ต้องเป็น "เท่ากับ")
  2. `frameSize := width / frameCount` → ถ้า `< 16` คืน `FRAME_SIZE_MISMATCH`
  3. `directionRows * frameSize > height` → คืน `FRAME_ROW_MISMATCH`
  4. คืน `(frameSize, frameSize)` — **เซลล์จัตุรัส** ไม่ใช่ `height / directionRows`
- ข้อ 4 สำคัญที่สุด: สูตรเดิมทำให้ `frame_height` ของ asset จริงเป็น 250 แทนที่จะเป็น 166 → renderer ตัดสไปรต์ (ดู F3)
- unit test เดิม (`pet_service_test.go:61-75`) ต้องเขียนใหม่ทั้งชุดเพราะอิงสูตรเก่า

### F5 — error detail ไม่แนบตัวเลขให้ FE

- **ไฟล์:** `zyra-api/internal/handler/pet_handler.go:162-166`, `:197-201`
- spec ระบุให้แนบ `{width, frame_count, frame_size}` กับ `FRAME_SIZE_MISMATCH` และ `{height, direction_rows, frame_size}` กับ `FRAME_ROW_MISMATCH` เพื่อให้ FE ขึ้นข้อความพร้อมเลขตามตาราง copy ใน [spec.md SC-PM-07](spec.md) — ปัจจุบันส่งแค่ `detail: {code}`
- เกี่ยวกับ F8 โดยตรง (FE ขึ้นข้อความละเอียดไม่ได้เพราะไม่มีข้อมูล)

### F6 — ไม่มี endpoint upload thumbnail

- contract §Admin มี `POST /api/admin/pets/:id/thumbnail` (optional) — ยังไม่มีใน `router.go` ปัจจุบัน thumbnail ถูก auto-set จาก animation ที่อัปตัวแรก (`pet_service.go:347-357`) และเปลี่ยนเองไม่ได้
- **ต้องเคาะ:** จะทำ endpoint หรือรับว่า auto-thumbnail พอ แล้วแก้ contract

### F7 — `workspace_usage_count` ไม่มีใครเขียน → sort ไม่มีความหมาย

- คอลัมน์มีจริง (`migrations/83_pet_management.sql:12`) และ list รองรับ `sort=usage_count` (`pet_service.go:92`) แต่ทั้งรีโปไม่มีจุดไหน UPDATE ค่านี้ → ทุกตัวเป็น 0 ตลอด
- ต้องไปเขียนพร้อม **PR 6 (placement)** เพราะจำนวนการใช้งานคือจำนวน pet ที่ถูกวางอยู่

### F8 — SC-PM-07 ฝั่ง FE ยังไม่ครบ

- **ไฟล์:** `zyra-app/views/admin/pet-management/components/pet-upload-step.tsx:306-315` · ข้อความที่ `messages/en.json:1565`
- ตอนนี้มี toast เดียวแบบ generic `"Upload failed ({code})."` — ยังไม่ได้ map error code → ข้อความตายตัวตามตาราง 6 บรรทัดใน contract (`INVALID_FILE_TYPE` / `FILE_TOO_LARGE` / `INVALID_DIMENSIONS` / `FRAME_SIZE_MISMATCH` / `FRAME_ROW_MISMATCH` / `INVALID_SLOT`) และไม่มี **client-side pre-check** ขนาด/ชนิด/dimension ก่อนยิง (ผู้ใช้ต้องรอ round-trip ก่อนรู้ว่าไฟล์ผิด)
- warning `NO_TRANSPARENCY` ทำถูกแล้ว (`:313-315`)

### F9 — Pet Library ไม่ได้ใช้ TanStack Query key ตาม contract

- **ไฟล์:** `zyra-app/views/admin/pet-management/components/pet-library-panel.tsx:56-67` ใช้ `useEffect` + `useState` ตรง ๆ
- contract §FE ระบุ key `["pet-types", params]`, `["pet-type", id]`, `["map-pets", mapId]` — ที่ทำตามมีแค่ XP panel (`["pet-xp-config"]`, `["pet-xp-config-history"]`)
- ผลตามมา: refetch ใช้ `refreshKey` counter ส่งจาก hero แทน `invalidateQueries` และไม่มี cache ข้ามหน้า

### F10 — S3 key ใช้ slot ตัวเล็ก

- `pet_service.go:307` สร้าง key เป็น `static/pet/{id}/{stage}/{slot ตัวเล็ก}_{uuid}.png` (เช่น `sitting_….png`) แต่ contract §S3 Keys เขียน `{slot}` ตาม vocabulary (`Sitting_….png`)
- ไม่กระทบการทำงาน (URL เก็บใน DB) แต่ให้เลือกว่าจะแก้โค้ดหรือแก้เอกสาร ก่อนมีข้อมูลจริงเยอะ

### F11 — รับ GIF ที่ slot `Evolution` โดยที่เอกสารไม่มีเขียน

- `pet_service.go:258-283`, `:387-415` — ถ้า slot เป็น `Evolution` และไฟล์นามสกุล `.gif` จะ validate ด้วย magic `GIF87a/GIF89a` แล้วอัปเป็น `image/gif` ข้าม logic frame/transparency ไปเลย
- contract §Error codes เขียนว่า PNG เท่านั้น (magic `89 50 4E 47`) → **เป็นของแถมที่ยังไม่มีในเอกสาร** ต้องยืนยันว่าตั้งใจ แล้วเขียนลง contract (หรือถอดออก)

---

## กลุ่ม 3 — คุณภาพ / กฎโปรเจกต์

### F12 — ขอบเขต Go test แคบกว่าที่รายงานไว้

- ที่มีจริง: `pet_service_test.go` 4 func (`validatePetAnimationInput`, `isGIFName`, `validatePetSpriteDimensions`, `stageReadiness`) + `pet_xp_config_service_test.go` (validation) + `pet_xp_config_handler_test.go` (error mapping) — **ทั้งหมดเป็น pure function**
- ยังไม่มี: service test ที่ mock DB, และไม่มี `pet_handler_test.go` เลย
- `.claude/rules/04-test.md` ตั้ง target `internal/service/*` ≥ 80% — ยังไม่ถึง
- Vitest ฝั่ง app ผ่าน 5 ไฟล์ / 39 tests (`pets-api`, `pets-api-xp`, `pet-creation-wizard`, `pet-category-select`, `xp-configuration-validation`)

### F13 — XP panel ผิด rule 08 (Tailwind-only)

- **ไฟล์:** `zyra-app/views/admin/pet-management/components/xp-configuration-panel.tsx:8-14` import `@/components/ui/dialog` และ `@/components/ui/dropdown-menu`
- [08-shadcn-ui.md](../../../.claude/rules/08-shadcn-ui.md) ห้าม import `@/components/ui/*` (ยกเว้น `skeleton`/`icon`) → modal restore + เมนู `Ellipsis` ต้องเขียนเป็น Tailwind ล้วน
- **บริบท:** ทั้งรีโปมี 24 ไฟล์ใน `views/` ที่ทำแบบเดียวกัน ไม่ใช่ปัญหาเฉพาะ Pet — ถ้าจะบังคับควรตัดสินใจระดับทีมพร้อมกัน ไม่ใช่จับเฉพาะ PR นี้

### F14 — search ใน Pet Library ไม่มี debounce

- `pet-library-panel.tsx:56-67` — `search` อยู่ใน deps ของ `useEffect` ตรง ๆ → ยิง `GET /api/admin/pets` ทุกตัวอักษรที่พิมพ์

---

## กลุ่ม 4 — เรื่อง feature flag ที่ต้องเคาะ

### F15 — `NEXT_PUBLIC_PET` ปิดแค่เมนู

- `isPetManagementEnabled()` (`zyra-app/lib/pet-feature.ts`) ถูกเรียกที่เดียวคือ `components/admin/admin-sidebar.tsx:55`
- route `/admin/pet-management` และ `/admin/pet-management/xp-configuration` **ยังเข้าได้ตรงผ่าน URL** (มีแค่ `useAdminGuard`) และ `/api/admin/pets*` + `/api/admin/pet-xp-config*` ไม่มี flag เลย (มีแค่ `AdminGuard`, `router.go:542-560`)
- ถ้อยคำในเอกสาร ("เมนูถูกควบคุมด้วย flag") ถูกตามตัวอักษร — แต่ถ้าเจตนาคือ "ยังไม่เปิดฟีเจอร์" ตอนนี้ยังปิดไม่จริง
- **ต้องถาม:** ยอมรับได้ไหมว่า admin ที่รู้ URL เข้าไปสร้าง pet ได้ตอนนี้ ถ้าไม่ ต้องเพิ่ม gate ที่ route (redirect) และฝั่ง API

---

## เรื่องดีที่เอกสารยังไม่ได้บันทึก (ไม่ใช่ปัญหา)

- **ตาราง Pet ไม่ต้องรัน migration มือ** — `tb_pet_type` / `tb_pet_animation` / `tb_pet_xp_config` + seed config version 1 อยู่ใน bootstrap DDL ของ `zyra-api/internal/database/postgres.go:782-868` แล้ว → ถูกสร้างตอน service start เอง (ต่างจากฟีเจอร์อื่นที่ต้อง apply `migrations/*.sql` เอง)
- **`migrations/84_pet_animation_idle_slot.sql` เป็น no-op** เทียบกับ 83 ในรีโปปัจจุบัน (`83_pet_management.sql:31` มี `'Idle'` ในชุด CHECK อยู่แล้ว) — 84 มีผลเฉพาะ DB ที่รัน 83 เวอร์ชันเก่าไปแล้ว ถ้าเจอ env ที่ CHECK ยังไม่มี `Idle` ให้รัน 84
- XP config API ตรง contract ครบ รวม `422 INVALID_XP_CONFIG` + `detail.{field,reason}` (`pet_xp_config_handler.go:78-88`) และ prune history 10 version ใน tx เดียวพร้อม `pg_advisory_xact_lock` กัน version ชนกัน

---

## คำถามที่ต้องได้คำตอบ (เหลือข้อ 3)

| # | คำถาม | ค้างมาจาก |
|---|---|---|
| 1 | ~~17 หรือ 20 slots~~ — ✅ **ปิดแล้ว 2026-09-01: ใช้ 17** (ถอด `Idle` ออกจากโค้ด) | progress §Required animation slots |
| 2 | ~~metadata ต่อ animation~~ — ✅ **ปิดแล้ว 2026-09-01: ปลดล็อกให้กรอกต่อ animation** default 6 / 8 fps / 4 rows และล็อกชีทที่ 1000×1000 | progress §Animation metadata |
| 3 | **เจตนาของ feature flag** — ปิดแค่เมนู หรือต้องปิดทั้ง route + API (F15) | ใหม่จากรอบตรวจนี้ |
