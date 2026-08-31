# Pet Management — จุดที่โค้ดต่างจากเอกสาร (ส่งให้ dev)

> **สถานะ:** ผลตรวจโค้ด 2026-08-31 — **ยังไม่มีใครแก้** ทุกข้อในไฟล์นี้เป็นของที่พบจากการอ่านโค้ด ไม่ได้แตะโค้ดเลย
> **base ที่ตรวจ:** zyra-app `d748a39` · zyra-api `2419213` (ทั้งคู่คือ `origin/develop` — โค้ด Pet merge เข้า develop แล้ว)
> **verify แล้ว:** `go build ./...` เขียว · `go test ./internal/service/... ./internal/handler/... -run 'Pet|XP'` ผ่าน · Vitest pet 5 ไฟล์ / 39 tests ผ่าน · **ยังไม่ได้ live-test บน dev / ยังไม่ได้ UAT ไฟล์ sprite จริง**
> **repo ที่กระทบ:** zyra-app, zyra-api · **เอกสารอ้างอิง:** [progress-2026-08-31.md](progress-2026-08-31.md) · [db-schema-api-contract.md](db-schema-api-contract.md) · [work-split.md](work-split.md)

สถานะรายหัวข้อใน [progress-2026-08-31.md](progress-2026-08-31.md) **ตรงกับโค้ดทั้งหมด** ไฟล์นี้คือส่วนที่เอกสารยังไม่ได้บันทึก — เรียงตามความเร่งด่วน

## ตารางสรุปเพื่อ assign

| ID | เรื่อง | repo | ระดับ | ต้องรอคำตอบก่อนไหม |
|---|---|---|---|---|
| F1 | progress bar ยังเป็นสเกล 17 slots | zyra-app | ต้องแก้ | ✅ รอ 17 vs 20 |
| F2 | preview modal hardcode 6×4@8fps + ทิ้ง metadata | zyra-app | ต้องแก้ | ✅ รอ 17 vs 20 + metadata policy |
| F3 | เพดาน 1000px ขัดกับ frame 50 → อัปไฟล์จริงไม่ผ่าน | zyra-api + zyra-app | **บล็อก UAT** | ✅ รอ metadata policy |
| F4 | `FRAME_SIZE_MISMATCH` ไม่ได้เช็ค modulo | zyra-api | ต้องแก้ | — |
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

### F1 — progress bar ยังเป็นสเกล 17 slots ทั้งที่ระบบต้องการ 20

- **ไฟล์:** `zyra-app/views/admin/pet-management/components/pet-detail-panel.tsx:33-52` (ตาราง `PET_UPLOAD_PROGRESS_WIDTHS`) และการใช้งานที่ `:97`
- **อาการ:** อัปโหลดครบ 17/20 บาร์ขึ้นเต็ม 100% แล้ว จากนั้น 18, 19, 20 บาร์ไม่ขยับ (`?? "w-full"` กลืนไป)
- **สาเหตุ:** array มี 18 ค่า step ละ 5.88% = 100/17 → ถูกทำไว้ตอน spec ยัง 17 slots แต่ตอนนี้ `PET_UPLOAD_TOTAL = 20` (`pet-upload-config.ts:72`) และ `model.RequiredPetSlots` ฝั่ง Go ก็ 20 (`zyra-api/internal/model/pet.go:35-40`)
- **ต้องแก้:** เลิก hardcode ตาราง width → คำนวณจาก `uploaded / total` ตรง ๆ (ถ้าต้องคง Tailwind class ล้วน ให้ gen ตามจำนวน slot จริง ไม่ใช่ค่าคงที่ 17 ขั้น)
- **กระทบ 2 ที่:** หน้า create/edit และ `PetSelectedView` (`:454-459`) ที่ส่ง `animations.length` เข้าตัวเดียวกัน
- **verify:** อัปโหลด 18/20 แล้วดูว่าบาร์ยังขยับ

### F2 — preview modal ใช้ค่า animation ชุดที่ 3 ที่ไม่ตรงกับใครเลย

- **ไฟล์:** `zyra-app/views/admin/pet-management/components/pet-preview-modal.tsx:166` (`void animationMeta`) และ `:177-180`
- **อาการ:** preview เล่นเป็น 6 เฟรม × 4 rows @ 8fps ตายตัว ไม่ว่าไฟล์จริงจะเป็นเท่าไร → preview ไม่ตรงกับของที่จะเห็นในเกม
- **สาเหตุ:** modal รับ `animationMeta` (ค่าจริงจาก DB: `frame_count/frame_rate/direction_rows/frame_width/frame_height`) แล้ว `void` ทิ้ง และ prop `frameCount`/`frameRate` (50/24) ที่ `pet-upload-step.tsx:456-465` ส่งมาก็ไม่ได้ถูก destructure ออกมาใช้
- **ตอนนี้มี 3 สัญญาที่ไม่ตรงกัน:** DB (ค่าจริงต่อ animation) · upload form (50 / 24 / 4) · preview (6 / 4 / 8)
- **ต้องแก้:** ให้ preview อ่านจาก `animationMeta[key]` เป็นหลัก แล้ว fallback เป็นค่าที่ upload ส่งมา
- **verify:** อัปชีทที่ frame_count ≠ 6 แล้วเทียบว่า preview เดินตามจำนวนเฟรมจริง

### F3 — เพดาน 1000px ขัดกับ frame_count ที่ล็อกไว้ 50 → อัปโหลดไฟล์จริงจะไม่ผ่าน (บล็อก UAT)

- **ไฟล์:** `zyra-api/internal/service/pet_service.go:24` (`maxPetSpriteSize = 1MB`) และ `:512-523` (`validatePetSpriteDimensions`) · ฝั่ง FE `pet-upload-step.tsx:241-303` ล็อก `frameCount=50` / `frameRate=24` / `directionRows=4` และ `<select disabled>`
- **อาการที่จะเจอใน UAT:** ชีท 50 เฟรมที่เฟรมขนาดปกติ (เช่น 64px → กว้าง 3200px) จะได้ `INVALID_DIMENSIONS` ทันที เพราะ API รับไม่เกิน 1000×1000 → เฟรมกว้างได้ไม่เกิน **20px** (เคส "valid" ใน unit test เองคือ 1000×400 → 20×100 ที่ `pet_service_test.go:71`) และไฟล์ต้องไม่เกิน 1 MB ด้วย
- **ต้องเลือกทางใดทางหนึ่งก่อนนัด UAT:**
  1. ปลดล็อก metadata ให้ตั้งค่าต่อ animation ตาม spec (เลิกล็อก 50/24/4) แล้วให้ artist ส่งชีทตามที่ระบบรับ หรือ
  2. ยกเพดาน dimension/ขนาดไฟล์ให้รองรับชีท 50 เฟรมของจริง (ต้องคุยขนาดจริงกับ artist ก่อนตั้งเลข)
- **หมายเหตุ:** ข้อนี้เป็นเรื่องเดียวกับ "Animation metadata" ใน [progress §จุดที่ต้องตัดสินใจ](progress-2026-08-31.md) แต่เอกสารยังไม่ได้บันทึกว่ามัน **ขัดกับเพดานฝั่ง API จนอัปไฟล์จริงไม่ได้**

---

## กลุ่ม 2 — ไม่ตรง [db-schema-api-contract.md](db-schema-api-contract.md)

### F4 — `FRAME_SIZE_MISMATCH` เช็คผิดเงื่อนไข

- **ไฟล์:** `zyra-api/internal/service/pet_service.go:516`
- contract เขียน `width % frame_count = 0` แต่โค้ดเช็คแค่ `width < frame_count` → ชีทที่หารไม่ลงตัว (เช่น width 100, frame_count 3) **ผ่าน** แล้ว `width / frame_count` ปัดทิ้งเศษเงียบ ๆ → เฟรมเพี้ยนทีละพิกเซลสะสม
- **ต้องแก้:** เพิ่ม `width % frame_count != 0 → ErrPetFrameSizeMismatch` (แกน height มี modulo อยู่แล้วที่ `:519`)

### F5 — error detail ไม่แนบตัวเลขให้ FE

- **ไฟล์:** `zyra-api/internal/handler/pet_handler.go:162-166`, `:197-201`
- contract ระบุให้แนบ `{width, frame_count}` กับ `FRAME_SIZE_MISMATCH` และ `{height, direction_rows}` กับ `FRAME_ROW_MISMATCH` เพื่อให้ FE ขึ้นข้อความพร้อมเลข — ปัจจุบันส่งแค่ `detail: {code}`
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

## คำถามที่ต้องได้คำตอบก่อนแก้ F1–F3 / F15

| # | คำถาม | ค้างมาจาก |
|---|---|---|
| 1 | **17 หรือ 20 slots** — โค้ดใช้ 20 (Egg 2 + Baby/Adult/Evolved ละ 6 โดยเพิ่ม `Idle`), [work-split.md:50-57](work-split.md) เขียน 17 (ละ 5) → ต้องได้คำตอบก่อนแก้ F1/F2 ไม่งั้นแก้แล้วต้องแก้อีกรอบ | progress §Required animation slots |
| 2 | **metadata ต่อ animation** — เปิดให้ตั้งค่าเองตาม spec หรือรับค่า fixed อย่างเป็นทางการ (คำตอบกำหนดว่าจะแก้ F3 ทางไหน) | progress §Animation metadata |
| 3 | **เจตนาของ feature flag** — ปิดแค่เมนู หรือต้องปิดทั้ง route + API (F15) | ใหม่จากรอบตรวจนี้ |
