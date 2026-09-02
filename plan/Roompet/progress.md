# Room Pet — Progress

> log ต่อรอบ (entry ใหม่ไว้บนสุด) · รูปแบบตาม [zyra-doc/README.md § อัปเดตความคืบหน้า](../../README.md)
> สถานะรวมอยู่ที่ blockquote หัว [spec.md](spec.md) · ความพร้อมของ dependency ดู [spec.md § ความพร้อม](spec.md)

---

## 2026-09-02 (รอบ 11) — member endpoint `GET /api/user/pet-xp-config`

- **ทำอะไร:** branch `feat/room-pet-user-xp-config` ทั้ง 2 repo (แตกจาก `develop`) — endpoint แรกฝั่ง member ของ Room Pet
  - **zyra-api:** `model.PetXPConfigPublic { version, config }` + `PetXPConfigPublicResponse` · `handler/pet_xp_config_user_handler.go` — `PetXPConfigUserHandler` รับ interface แคบ `petXPConfigCurrentReader` (แค่ `GetCurrent`) แล้ว map ตัด `id/is_current/created_by*` และไม่ส่ง `constraints` · 404 `PET_XP_CONFIG_NOT_FOUND` เมื่อยังไม่มี version, 500 `INTERNAL_ERROR` ไม่รั่วข้อความ error · route `user.GET("/pet-xp-config")` ใต้ `UserGuard` · wire ใน `main.go` (reuse `PetXPConfigService` ตัวเดิม ไม่มี SQL ใหม่)
  - `handler/pet_xp_config_user_handler_test.go` — table-driven 3 เคส (200 / 404 / 500) + เคสยืนยันว่า response **ไม่มี** field admin และไม่มีชื่อ/uuid ของ admin ใน body
  - **zyra-app:** `lib/api/pets.ts` — type `PetXPConfigPublic` + `getPetXPConfigForUser()` → `/api/user/pet-xp-config` · `__tests__/pets-api-user-xp.test.ts` 3 เคส (path ไม่ใช่ `/api/admin`, payload เข้า `derivePetStage`/`derivePetProgress`/`buildPetDailyQuests` ได้ตรง ๆ, 404 ไม่ throw)
- **verify ถึงไหน:** Go: gofmt สะอาด · `go vet` + `go build ./...` ผ่าน · `go test ./internal/handler/ ./internal/service/` ผ่านทั้งหมด · **live-test กับ local api ที่ต่อ dev DB** (รันที่ port 3012 เพราะ 3002 มี instance เก่าของ user อยู่): ไม่มี token → 401 · `member-a@zyra.test` → 200 `version 8` (มีคน save version ใหม่ระหว่างวัน) data มีแค่ `config` + `version`, enabled 8 activity, mood 12/48/72 · member เรียก `/api/admin/pet-xp-config` → 403 (guard เดิมทำงาน) · FE: vitest 11/11 (ไฟล์ใหม่ + `pets-api-xp` เดิม), tsc, eslint ผ่าน
- **PR:** ยังไม่ commit ทั้ง 2 repo — รอ user สั่ง
- **ต่อจากนี้:** commit + PR (api ก่อน app เพราะ app เรียก path ใหม่) → harness/`VOPetPanel` ดึง config จริงจาก endpoint นี้แทน fixture เมื่ออยู่ในหน้าที่ login → เริ่ม component ที่เหลือ (hatch overlay + evolution modal, marker, mood bubble)
- **ติดอะไร:** config v8 บน dev ยังมี `neutral.within_hours = 48` (validation ฝั่ง Go ยังไม่บังคับ `== sad.after_hours`) — `derivePetMood` ไม่อ่านค่านี้จึงไม่กระทบ UI แต่ต้องแก้ตามรายการ PetManagement/spec.md

## 2026-09-02 (รอบ 10) — `lib/sprite-grid.ts` (port จาก #240) + harness ใช้ sprite จริงของ "ปรื๊ด"

- **ทำอะไร:** branch ใหม่ `feat/room-pet-sprite-utils` (จาก `develop` @ `bde39ce`) — user สั่ง cherry-pick sprite utils จาก #240 มาเริ่มก่อน merge
  - `lib/sprite-grid.ts` — port `detectSpriteGridFromPixels` / `getSpriteCrop` จาก `views/admin/pet-management/sprite-preview-utils.ts` ของ #240 (เนื้อเดิม 100 %) มาไว้ที่ `lib/` ตาม rule 09 + เพิ่ม DOM helper `detectSpriteGridFromImage` / `cropSpriteFrameToCanvas` / `loadSpriteImage` และ **`normalizeSpriteGrid()` ใหม่**
  - **บั๊กของแนวทาง #240 ที่ asset จริงเปิดเผย:** alpha-run detection นับ row/column เกินจริงเพราะ sprite มีช่องโปร่งใส**ภายในตัว** (ลำตัวกับขา) — baby Walking detect ได้ 8 rows, adult 5 rows ทั้งที่มี 4 ทิศ → crop "left/right" ได้ช่องว่าง · `normalizeSpriteGrid` รวม run ที่เกิน `direction_rows`/`frame_count` ข้ามช่องว่างเล็กสุด (gap ในตัว sprite แคบกว่า gutter ระหว่างเซลล์เสมอ) · run ที่**น้อยกว่า** metadata ให้เชื่อ detection
  - **ข้อมูลใน DB ไม่ตรง sheet จริง:** egg Wobbling detect ได้ **4 cols × 3 rows** แต่ `tb_pet_animation` เก็บ `frame_count 6 / direction_rows 4` (มาจากค่าที่ admin form ล็อกไว้แล้ว migration 88/89 normalize) → renderer ห้ามเชื่อ metadata อย่างเดียว ต้อง detect จากภาพ · ต้องแจ้ง PetManagement (`frame_count` ต่อ animation ต้องกรอกได้จริงตาม spec 2026-09-01)
  - `__tests__/sprite-grid.test.ts` — 12 เคส (4 เคสเดิมของ #240 + normalize 4 + edge 4)
  - harness: `views/dev/room-pet-preview/real-pet-fixture.ts` (URL R2 ของปรื๊ด — public ไม่ใช่ secret) · `real-pet-sprite-strip.tsx` แสดงเฟรม 0 ทั้ง 4 ทิศของ egg/baby/adult/evolved + GIF ไข่แตก · nameplate icon = เฟรมจริง baby Walking · panel avatar = thumbnail จริง · ทั้งหมดผ่าน `/api/img` (`proxyUrl`)
- **verify:** live บน 3110 — sheet ทั้ง 4 crop ถูกทุกทิศหลัง normalize (baby/adult/evolved 6×4, egg 4×3), GIF 960×960 + thumbnail 166×166 โหลดสำเร็จ, ไม่มี request 4xx/5xx · vitest 12/12 · tsc/eslint/prettier ผ่าน · ระหว่างทาง Turbopack cache `.next/room-pet` เพี้ยน (`[turbopack]_runtime.js` หาย) → ลบแล้วสตาร์ตใหม่หาย
- **PR:** ✅ **[zyra-app #242](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/242)** `feat/room-pet-sprite-utils` → `develop` (2 commit: `lib/sprite-grid.ts` + harness) — **merged 2026-09-02 09:08Z** (merge commit `6492e20`, CI 6/6, branch ลบแล้ว, dev deploy อัตโนมัติ) · หลัง #240 merge: ไฟล์ `sprite-preview-utils.ts` ของ admin ควรเปลี่ยนเป็น re-export จาก `lib/sprite-grid.ts` (เนื้อเดิมเท่ากัน add/add จะไม่ conflict) และให้ preview modal เรียก `normalizeSpriteGrid`
- **ต่อจากนี้:** commit + PR → member endpoint อ่าน XP config → เริ่ม component ที่เหลือ (hatch overlay + evolution modal ใช้ GIF จริง, marker, mood bubble) ตาม decision รอบ 9

## 2026-09-02 (รอบ 9) — PM ตอบ 9 ข้อที่ค้างใน test-plan §6 · ข้อมูล Pet Management จริงมาถึง

- **PM ตัดสิน 9 ข้อ** (บันทึกในแถว ✅ ของ [test-plan.md §6](test-plan.md)): CLASH-01 toast เลื่อนใต้ panel · CLASH-02 overlay รอออกจาก meeting · RT-04 pet ถูกลบระหว่าง GIF → เล่นจบ **และยังโชว์ modal** (soft delete) · LOAD-03 sprite 404 → **ไม่แสดงอะไร** · LOAD-06 stroke 500 → ไม่เล่น + toast error · ZOOM-02 zoom ไกล → จุด `#996ADF` · ZOOM-05 PiP ซ่อน panel/modal/overlay · A11Y-02 Esc ข้าม overlay ได้ · A11Y-04 GIF เล่นปกติ ลด effect
  - 3 ข้อต่างจากที่ผมเสนอ (RT-04, LOAD-03, ZOOM-02) — ไม่มีโค้ดที่ merge แล้วต้องแก้ เพราะยังไม่ได้ทำ overlay / map sprite / compact mode · จุดเดียวที่ควรถาม: `VOPetPanel` avatar เมื่อไม่มีรูปยังใช้ `PawPrint` (เคส null ไม่ใช่ 404) จะให้ว่างเหมือน LOAD-03 ไหม
- **ข้อมูลจริงบน dev DB** (ประเมินแล้ว ยังไม่แก้โค้ด): pet type "ปรื๊ด" (dog, active) 20 animation ครบ 4 stage — PNG 6×4 @8fps (egg @16fps), `Evolution` เป็น GIF ทุก stage, มี thumbnail · XP config v7 (threshold 100/500/2000, เปิด 8/10 activity, `neutral.within_hours` ยัง 48) · `tb_room_pet` ยังไม่มี
  - **ขัด spec:** ข้อมูลมี slot `Idle` ทั้ง 3 stage (20 slot) ทั้งที่ spec 2026-09-01 ถอด Idle → เสนอเก็บ Idle (ตอบคำถาม idle animation) รอ PM
  - PR #240 (ยัง CHANGES_REQUESTED) มี `views/admin/pet-management/sprite-preview-utils.ts` (`detectSpriteGridFromPixels`, `getSpriteCrop`) ที่ VO ต้องใช้ crop เฟรมจริง → หลัง merge ต้องย้ายไป `lib/` (rule 09)
- **ต่อจากนี้:** รอ #240 merge → PR ย้าย sprite utils + harness ใช้ sprite/thumbnail ของปรื๊ดผ่าน `/api/img` → member endpoint อ่าน XP config → อัปเดต spec เรื่อง Idle/neutral 48 → แล้วค่อยเริ่ม overlay/modal/marker/mood bubble ตาม decision ใหม่

## 2026-09-02 (รอบ 8) — dev preview harness + บั๊กที่ preview จับได้

- **ทำอะไร:** หน้า preview รวมทุก component กับ fixture เดียวกับเทส เปิดใน Browser pane แล้ว **render ครบทุกชิ้น** (badge 3 แถว · tooltip 3 variant · Pixi nameplate 3 ตัวอย่างรวมชื่อไทยที่ถูกตัด · VOPetPanel 4 state สลับได้ · minimap compact + expanded มี pet dot ม่วง · รายชื่อ section Setting มี PET · ตาราง derive)
  - `app/dev/room-pet-preview/page.tsx` (thin, `notFound()` นอก development) + `views/dev/room-pet-preview/hero-room-pet-preview.tsx` + `pet-name-tag-preview.tsx` (Pixi Application จริง วาด `makePetNameTag`/`layoutPetNameTag` ×2)
  - **auth bypass เฉพาะ dev:** `proxy.ts` + `components/auth-guard.tsx` ปล่อย `/dev/*` เมื่อ `NODE_ENV === "development"` (ทั้ง 2 ไฟล์ตาม rule 03) — production ไม่กระทบ (path 404 อยู่แล้ว)
  - launch config `zyra-app-room-pet` ใน `<repo-root>/.claude/launch.json` (env `NEXT_PUBLIC_ROOM_PET=true`, `NEXT_DIST_DIR=.next/room-pet`, port 3110) — ไม่ชน dev server ของ user ที่ 3000
- **บั๊กที่ preview จับได้ (unit test ไม่เห็น):** `VOPetPanel` เรียก `useTranslations("AdminShared")` → **`MISSING_MESSAGE` ตอน runtime** เพราะ `i18n/messages-scope.ts` ถอด namespace `Admin*` ออกจากทุก route ที่ไม่ใช่ `/admin` (และ `__tests__/i18n-namespace-split.test.ts` จะ fail ใน CI) → แก้: copy 10 key `xpSource*` เข้า namespace `VirtualOffice` (en+th) และให้ panel อ่านจาก `t("VirtualOffice")` อย่างเดียว · `PET_XP_ACTIVITY_LABEL_KEY` ยังเป็น map เดียว (ชื่อ key เท่ากันทั้ง 2 namespace) · เทส panel mock โยน error ถ้าเรียก namespace อื่น
- **PR:** ✅ **[zyra-app #241](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/241)** `feat/room-pet-ui` → `develop` (4 commit: flag+lib · components · pixi nameplate · harness — user เลือกเก็บ harness ไว้) — **merged 2026-09-02 08:05Z** (merge commit `bde39ce`, CI 6/6 เขียว, branch ลบแล้ว) → dev deploy อัตโนมัติ image `dev-bde39ce` พร้อม `NEXT_PUBLIC_ROOM_PET=true` · docs: **[zyra-doc #4](https://github.com/N2Pluto/zyra-doc/pull/4)** `docs/room-pet-plan` → `main` ยังเปิดอยู่
- **verify ถึงไหน:** live ใน dev server 3110 — console ไม่มี error หลัง reload สะอาด · `vitest` `vo-pet-panel` + `i18n-namespace-split` ผ่าน · tsc/eslint/prettier ผ่าน · ยังไม่ได้รัน `next build`
- **env บน dev (ทำแล้ว 2026-09-02):** ตั้ง GitHub **environment secret** `NEXT_PUBLIC_ROOM_PET=true` บน environment `dev` ของ repo zyra-app (workflow `deploy-gitops.yml` job `deploy` ใช้ `environment: dev|uat|production` → secret แยกต่อ env; `NEXT_PUBLIC_PET` ก็อยู่ระดับ env `dev` เหมือนกัน) · `uat` / `production` **ไม่มี** secret นี้ → build ได้ค่าว่าง = flag ปิด · มีผลกับ image `dev-<sha>` ตัวถัดไปหลัง merge เข้า `develop`
- **ต่อจากนี้:** merge #241 หลัง CI เขียว → รอ dev deploy แล้วเปิด `/workspace/<id>/play` บน dev ตรวจว่า section PET โผล่ใน Setting (ชิ้นเดียวที่ mount อยู่แล้ว) · เก็บ harness ไว้ใช้ตอน wire hero
- **ติดอะไร:** screenshot จาก Browser pane มีแถบดำด้านบนเมื่อ scroll (quirk ของ pane ไม่ใช่แอป — ยืนยันด้วย viewport 1500px เห็นครบ)

## 2026-09-02 (รอบ 7) — unhide section PET ใน Setting → Notifications · **ชุด component ล้วนครบ**

- **ทำอะไร:** `views/user/virtual-office/components/vo-setting-modal.tsx` — section `notifSectionPet` เปลี่ยนจาก `hidden: true` เป็น **`hidden: !isRoomPetEnabled()`** (flag `NEXT_PUBLIC_ROOM_PET` ตัวเดียวกับทุก surface) · export `NOTIFICATION_SECTIONS` / `VISIBLE_NOTIFICATION_SECTIONS` เพื่อเทส · **ไม่แตะ copy** เพราะ `notifPetActivityLabel` "Pet activity" / `notifPetActivityDesc` "Stay updated on your pet's progress, milestones, and evolution." ตรง Figma 4369-309920 อยู่แล้ว (th มีแล้ว) · field `pet_activity` + store + API เดิมใช้ต่อ default ON
  - `__tests__/vo-setting-notifications-pet.test.ts` — 5 เคส (ซ่อนเมื่อ flag off · โผล่ระหว่าง CALENDAR กับ ACTIVITIES เมื่อ on · row เดียว bind `pet_activity` · default true · section อื่นไม่กระทบ) ครอบ test-plan §1.13 ยกเว้น toast หลัง toggle (ยัง "เคาะ" ข้อความ)
- **ถึงไหน:** **component ล้วนที่ไม่ต้องรอ SC-PM-05 ครบทั้ง 6 รายการ** ตาม [spec.md § ความพร้อม](spec.md): `PetStageBadge` · `PetTooltip` · derive helpers · `VOPetPanel` · pet nameplate (Pixi) · `petDots` · Setting PET + flag `NEXT_PUBLIC_ROOM_PET` · ยังไม่มีชิ้นไหน mount ใน `hero-virtual-office.tsx` (ต้องรอ pet data)
- **PR:** ยังไม่เปิด · ยังไม่ commit — รอ user สั่ง (branch `feat/room-pet-ui`, 26 ไฟล์: แก้ 10 / ใหม่ 16)
- **verify ถึงไหน:** `vitest run` 13 ไฟล์ (pet 9 + regression `pixi-game-scene`, `vo-minimap-grouping`, `notification-settings-store`, admin 2) **452/452 ผ่าน** (3 skipped เดิม) · eslint สะอาดทุกไฟล์ที่แตะ · prettier ผ่านทุกไฟล์ที่แตะ · `tsc --noEmit` ไม่มี error ใหม่ (2 error เดิมใน `pixi-game-scene.test.ts` บน develop) · **ยังไม่ live-test** และยังไม่ได้รัน `next build`
- **ต่อจากนี้:** (1) commit + เปิด PR `feat(app): room pet ui components behind NEXT_PUBLIC_ROOM_PET` → develop (2) ตั้ง secret `NEXT_PUBLIC_ROOM_PET=true` เฉพาะ dev เมื่อจะ live-test (3) งานที่ต้องรอ backend: SC-PM-05 → api PR 6 → ws PR 7 → app PR 8 → api PR 9 แล้วค่อย wire hero (click pet → panel, nameplate บน scene, `petDots` จาก pet list, tooltip/marker, hatch overlay + evolution modal ที่ยังไม่ทำ)
- **ติดอะไร:** ไม่มี blocker ในชุดนี้ · ค้างจาก design: badge Adult/Evolved, peer pill vs `#242B32`, quest tile PNG, Pixelony, compact zoom, toast copy (ux-ui.md §11)

## 2026-09-02 (รอบ 6) — `petDots` บน `VOMinimap`

- **ทำอะไร:** เพิ่ม prop `petDots?: PetDot[]` ให้ `VOMinimap` (`views/user/virtual-office/components/vo-minimap.tsx`) — render marker วงกลมต่อ pet ใน `MinimapContent` **ก่อน** `PlayerPill` (อยู่ใต้ avatar) ที่ `tile × scale` · ขนาด `round(dotSize × 6/14)` → 6px ตอน collapsed/compact (dotSize 14), 9px ตอน expanded (22) · `pointer-events-none` · `role="img"` + `title` = ชื่อ pet · **ไม่ถูก group เข้า meeting pill** · gate ด้วย `isRoomPetEnabled()` — flag ปิด = ไม่ render แม้ hero ส่ง dots มา
  - `lib/pet-minimap.ts` (ใหม่) — `PET_MINIMAP_DOT_COLOR = "#996ADF"`, `PET_MINIMAP_DOT_RATIO = 6/14`, `interface PetDot { id, tileX, tileY, name? }`
  - **ปิดคำถาม design ข้อ 3 ได้เอง:** ดึง SVG `Ellipse 4` จาก Figma มาดู = `<circle r="3" fill="#996ADF"/>` (Purple/500) ไม่ใช่ "ชมพู" ตาม ClickUp — อัปเดต ux-ui.md §2.3 / §11 และ test-plan §1.14 แล้ว
  - `__tests__/vo-minimap-pet-dots.test.tsx` — 7 เคส ครอบ test-plan §1.14 ทั้ง 4 แถว + a11y + flag off + สเกลตอน expand
- **ถึงไหน:** prop พร้อมใช้ · hero ยังไม่ส่ง `petDots` (รอ pet data จาก API/ws)
- **PR:** ยังไม่เปิด
- **verify ถึงไหน:** `vitest run` `vo-minimap-pet-dots` + `vo-minimap-grouping` เดิม **11/11 ผ่าน** (grouping เดิมไม่กระทบ) · eslint สะอาด · prettier ผ่าน · tsc ไม่มี error ใหม่ · ยังไม่ commit · ยังไม่ live-test
- **ต่อจากนี้:** unhide section PET ใน Setting (gate ด้วย `isRoomPetEnabled()`) → เปิด PR รวม component ล้วนทั้งหมด
- **ติดอะไร:** ไม่มี

## 2026-09-02 (รอบ 5) — pet nameplate บน Pixi + feature flag `NEXT_PUBLIC_ROOM_PET`

- **ทำอะไร (nameplate):** แตะ engine ครั้งแรกบน `feat/room-pet-ui` — **ไม่แก้ `_updateNameTag` ของ avatar** เพื่อเลี่ยง regression; ทำเป็นคู่ factory/layout แยกที่ใช้ค่าคงที่และ text style เดียวกัน
  - `zyra-engine/pixi-game/constants.ts` — export `NAME_TAG_PEER_BG 0x141420` / `NAME_TAG_PEER_BG_ALPHA 0.88` / `NAME_TAG_GAP_ABOVE_SPRITE 5` (เดิมเป็น literal ใน scene) + `PET_NAME_TAG_*` (icon 16, emoji font 14, progress h 4 radius 90, track white 10 %, gradient `#58D68D → #8FE4B3`)
  - `zyra-engine/pixi-game/types.ts` — `PetNameTag` (bg / icon Sprite / label / emoji Text / progress Graphics + `_prev*`)
  - `zyra-engine/pixi-game/utils.ts` — แยก `nameTagLabelStyle()` ออกจาก `makeNameTag` (avatar ใช้ต่อเหมือนเดิม) · เพิ่ม `makePetNameTag()` + `layoutPetNameTag(tag, {name, emoji, ratio, iconTexture})` คืน `{tagW, tagH}` — geometry ตาม Figma 4215-519137: pad 4 · icon 16 + gap 4 + ชื่อ + gap 4 + emoji 16 · แถวสอง progress h 4 เต็มความกว้างใน · สูง **32** · radius 6 · bg = peer pill · redraw เฉพาะเมื่อ input เปลี่ยน · `truncateName` เหมือน avatar · gradient ผ่าน `FillGradient` (pixi 8.18)
  - `__tests__/pet-name-tag.test.ts` — 13 เคส ครอบ test-plan §1.2 ทั้ง 7 แถว + edge ratio + no-icon/no-emoji + rebuild guard · รัน `pixi-game-scene.test.ts` เดิมคู่กันเพื่อยืนยันว่า `makeNameTag` ไม่พัง
- **ทำอะไร (flag — ตามที่สั่งกลางทาง):** `lib/room-pet-feature.ts` → `isRoomPetEnabled()` อ่าน **`NEXT_PUBLIC_ROOM_PET`** เปิดเฉพาะ string `"true"` · **default = false** (ไม่ตั้ง = ปิด → main/uat/prod ไม่ render และไม่เรียก API pet) · แยกจาก `NEXT_PUBLIC_PET` (admin menu) · `PetStageBadge` / `PetTooltip` / `VOPetPanel` คืน `null` เมื่อปิด (เช็คหลัง hooks ทุกตัว) · `Dockerfile` ARG/ENV + `deploy-gitops.yml` build-arg จาก `secrets.NEXT_PUBLIC_ROOM_PET` (secret ยังไม่มี = ค่าว่าง = ปิด) · test 3 ไฟล์ component เพิ่มเคส "flag off → innerHTML ว่าง" (LOAD-07) และ `__tests__/room-pet-feature.test.ts` 4 เคส
  - ชื่อ flag: user บอก `NEXT_PUBLIC_ROOM` → ใช้ **`NEXT_PUBLIC_ROOM_PET`** ให้สื่อความ (แก้ที่เดียวใน `lib/room-pet-feature.ts` + Dockerfile + workflow ถ้าต้องการชื่อตรงตัว)
  - engine helper (`makePetNameTag` / `layoutPetNameTag`) ไม่ได้ gate ในตัว — scene ต้องเช็ค `isRoomPetEnabled()` ก่อนสร้าง pet entity (ยังไม่มีจุดเรียกในตอนนี้)
- **ถึงไหน:** component ล้วนครบ 4 ชิ้น + engine helper 1 คู่ + flag · ยังไม่มีอะไร mount ใน hero
- **PR:** ยังไม่เปิด
- **verify ถึงไหน:** `vitest run` 9 ไฟล์ (pet 6 + `pixi-game-scene` + admin 2) **432/432 ผ่าน** (3 skipped เดิม) · eslint สะอาด · prettier ผ่านทุกไฟล์ที่แตะ (repo-wide ยังมี 31 ไฟล์เดิมไม่ clean — ไม่เกี่ยว) · tsc ไม่มี error ใหม่ · ยังไม่ commit · ยังไม่ live-test
- **ต่อจากนี้:** `petDots` ของ `VOMinimap` → unhide section PET ใน Setting (gate ด้วย flag เดียวกัน) → เปิด PR รวม component ล้วน → ตั้ง secret `NEXT_PUBLIC_ROOM_PET=true` เฉพาะ dev เมื่อพร้อม live-test
- **ติดอะไร:** pill bg ของ pet ยึด peer `0x141420 @0.88` ไม่ใช่ `#242B32` ของ Figma (ux-ui.md §11 ข้อ 11) · ยังไม่ได้ทำ mood bubble บนแคนวาส (test-plan §1.3) — จะทำพร้อมตอน wire scene เพราะต้องผูกกับ timer ใน `_renderUpdate`

## 2026-09-02 (รอบ 4) — `VOPetPanel` + quest helper

- **ทำอะไร:** component ล้วนตัวที่ 3 บน `feat/room-pet-ui`
  - `lib/pet-xp-activities.ts` (ใหม่, shared admin ↔ member) — `PET_XP_ACTIVITY_ORDER` 10 key · `PET_XP_ACTIVITY_LABEL_KEY` (namespace `AdminShared` `xpSource*` — **ย้ายออกจาก `xp-configuration-panel.tsx`** ให้ admin import จากที่เดียวกัน ตาม rule 09) · `buildPetDailyQuests(activities, doneByActivity)` → เฉพาะ `enabled` ตามลำดับ catalogue, `done` clamp 0..times
  - `views/user/virtual-office/components/vo-pet-panel.tsx` — `VOPetPanel` presentational (Figma 4345-343306 / 4689-572008): shell เดียวกับ `VOProfilePanel` (`w-[320px] rounded-[16px] bg-[#242B32] p-[16px] gap-[16px]`) · header avatar 56 `#FFA8A8` + `next/image` (fallback `PawPrint`) · progress `h-[4px]` track `rgba(26,27,30,0.5)` fill gradient จาก `derivePetProgress` (relative) · ตัวเลข "350/500 XP" สะสม + "150 XP to evolve next stage" · variant MAX (track ขาวเต็ม, "MAX XP", ไม่มีบรรทัด remaining) · stats Mood/Stage (ใช้ `derivePetMood` + `PetStageBadge`) · streak banner `#FF8000` (ซ่อนถ้าไม่มี field) · Daily quest render จาก `quests` prop (tile 50 + `+xp` `font-pixelify-sans` · count `#58D68D` เมื่อครบ · ปุ่ม Complete disabled opacity-50 / Go to + ChevronRight → `onGoTo(activity)`) · config พัง → `—` (LOAD-10) · prop `now` ฉีดเวลาได้ · `useState(() => Date.now())` แทนเรียกในการ render (ผ่าน `react-hooks/purity`)
  - i18n `VirtualOffice.petPanel*` 11 key en+th · quest title reuse `AdminShared.xpSource*`
  - `__tests__/vo-pet-panel.test.tsx` — 27 เคส ครอบ test-plan §1.7 ทุกบล็อก (shell / header / MAX / LOAD-10 / stats / streak / quest) + `buildPetDailyQuests` 4 เคส
- **ถึงไหน:** ครบตาม Figma ที่มี · **ยังไม่ mount ใน hero** (รอ click-pet handler + `getPetStatus`) · quest tile ใช้ lucide แทนภาพประกอบ PNG ที่ยังไม่มี asset
- **PR:** ยังไม่เปิด
- **verify ถึงไหน:** `vitest run` 6 ไฟล์ (pet 4 + admin `pet-creation-wizard` + `xp-configuration`) **108/108 ผ่าน** — ยืนยันว่าการย้าย label map ไม่ทำ admin พัง · eslint สะอาด · prettier ผ่าน · tsc ไม่มี error ใหม่ · ยังไม่ commit · ยังไม่ live-test
- **ต่อจากนี้:** option ใหม่ของ `makeNameTag` (leadingIcon / trailingEmoji / progress) → `petDots` ของ `VOMinimap` → unhide section PET ใน Setting → แล้วค่อยเปิด PR รวม component ล้วน
- **ติดอะไร / ตัดสินไว้:**
  - quest tile ไม่มี PNG ตาม Figma → ใช้ lucide (`LogIn` `Timer` `Clock` `Video` `MessageSquare` `MessagesSquare` `SmilePlus` `Hand`) ไว้ก่อน สลับเป็น asset เมื่อ design ส่ง
  - ตัวเลข `+xp` ใช้ `font-pixelify-sans` (มีใน `app/layout.tsx` แล้ว) แทน Pixelony ของ Figma
  - ตัวเลข header แสดง **xp สะสม / threshold ถัดไป** ตาม Figma แต่ bar คิด relative — สองค่านี้มาจาก `derivePetProgress` ตัวเดียว ไม่ขัดกัน
  - ยังไม่มี prop `top contributors` / ปุ่มลูบหัวใน panel ตาม ClickUp — ยึด Figma (spec.md ข้อ 3)

## 2026-09-02 (รอบ 3) — derive helpers ใน `lib/pet-stage.ts`

- **ทำอะไร:** เพิ่มส่วน "derived values" ต่อท้าย `lib/pet-stage.ts` (branch เดิม) — รับ type จาก `PetXPConfig` ใน `lib/api/pets.ts` ตรง ๆ ไม่ประกาศซ้ำ
  - `isValidPetThresholds()` · `derivePetStage(xp, thresholds)` (สะสม, null เมื่อ config ใช้ไม่ได้) · `nextPetStage()` · `petStageStartXP()`
  - `derivePetProgress(xp, thresholds)` → `PetProgress` แบบ relative ต่อ stage (baby 350 → `250/400 remaining 150 ratio 0.625`) · evolved → `{ isMax: true, prestige }` · **ไม่ divide by zero** คืน null (LOAD-10)
  - `derivePetMood(lastActivityAt, now, moodConfig)` 3 state จาก `last_activity_at` — ขอบ 12h = happy, 72h = neutral, > 72 = sad · timestamp หาย = sad
  - const `PET_MOOD_ORDER` / `PET_MOOD_EMOJI` (🥰 🙂 😢 unicode) / `PET_MOOD_LABEL_KEY` · `DEFAULT_PET_STAGE_THRESHOLDS` / `DEFAULT_PET_MOOD_CONFIG` (fallback แสดงผลเท่านั้น)
  - i18n `VirtualOffice.petMoodHappy / petMoodNeutral / petMoodSad` en+th
  - `__tests__/pet-stage-derive.test.ts` — 28 เคส ครอบ test-plan §1.1 ทั้ง 9 แถว + ขอบ mood ทั้ง 4 จุด + config พัง
- **ถึงไหน:** helper ครบตามที่ `VOPetPanel` / nameplate / modal ต้องใช้
- **PR:** ยังไม่เปิด
- **verify ถึงไหน:** `vitest run` 3 ไฟล์ pet **57/57 ผ่าน** · eslint สะอาด · prettier ผ่าน · tsc ไม่มี error ใหม่ · ยังไม่ commit
- **ต่อจากนี้:** `VOPetPanel` กับ fixture (ใช้ `derivePetProgress` + `derivePetMood` + `PetStageBadge`) → option ใหม่ของ `makeNameTag` → `petDots` ของ `VOMinimap` → unhide section PET
- **ติดอะไร:** ไม่มี — แต่ `PetXPConfig.mood.neutral.within_hours` ไม่ถูกใช้ใน `derivePetMood` โดยตั้งใจ (contract บอกเป็น mirror ของ `sad.after_hours`) ถ้า BE ส่งค่าไม่เท่ากันมา UI จะยึด `sad.after_hours`

## 2026-09-02 (รอบ 2) — `PetTooltip` 3 variant

- **ทำอะไร:** component ล้วนตัวที่ 2 บน branch เดิม `feat/room-pet-ui`
  - `lib/pet-interaction.ts` — `PET_STROKE_SHORTCUT_KEY = "p"` / `PET_STROKE_SHORTCUT_LABEL = "P"` · `PET_HEART_EMOJI` · `PET_XP_MEDAL_EMOJI` (unicode)
  - `views/user/virtual-office/components/pet-tooltip.tsx` — `PetTooltip` (forwardRef) variant `key` ("Press [P] pet", badge `border/text #58D68D` radius 2 w 16) · `emoji` (glyph 16px เดียว default ♥, override ได้สำหรับ mood) · `xp` ("+N XP" `#ECC819` Caption 1/Medium + 🏅) · body `bg-[#1A1B1E] p-[8px] rounded-[8px] gap-[4px] drop-shadow` ตาม Figma nodes 4256-570876 / 4689-564658 / 4276-151515 · หางสามเหลี่ยม 16×8 ด้วย `clip-path` · วางตำแหน่ง screen-space แบบ `PZZoneHover` (`left/top = sx/sy`, translate ให้ปลายหางอยู่ที่ anchor) · `pointer-events-none` เสมอ · export `PET_TOOLTIP_POINTER_HEIGHT`
  - i18n `VirtualOffice.petTooltipPress / petTooltipStroke / petTooltipXp` en+th
  - `__tests__/pet-tooltip.test.tsx` — 13 เคส ครอบ test-plan §1.4 ทั้ง 7 แถว + const + locale format
- **ถึงไหน:** โค้ดครบ · **ยังไม่ mount** (รอ interaction hook / hero wiring)
- **PR:** ยังไม่เปิด (รวมกับ `PetStageBadge`)
- **verify ถึงไหน:** `vitest run` 2 ไฟล์ pet **29/29 ผ่าน** · eslint สะอาด · prettier ผ่าน · `tsc --noEmit` ไม่มี error ใหม่ · **ยังไม่ commit · ยังไม่ live-test**
- **ต่อจากนี้:** derive helpers (stage / mood / relative XP) ใน `lib/pet-stage.ts` → `VOPetPanel` กับ fixture → option ใหม่ของ `makeNameTag` → prop `petDots` ของ `VOMinimap` → unhide section PET ใน Setting
- **ติดอะไร / ตัดสินไว้ (ต้องให้ design รับรู้):**
  - emoji ใช้ **unicode text** ตาม convention เดิมของ VO (`MEETING_EMOJIS`) ไม่ใช่ PNG Apple-style ที่ Figma export — หน้าตาต่างตาม OS
  - หางสามเหลี่ยมเป็น CSS 16×8 ชี้ลงตรง ๆ แทน `Polygon 5` (15.86×14 หมุน 60°) ของ Figma — ใกล้เคียง ไม่เป๊ะ
  - Medal ใน xp variant ใช้ 🏅 unicode (ux-ui.md icon table บอก "ใช้ asset เดิมถ้ามี" — ไม่มีใน `public/`)

## 2026-09-02 — เริ่ม component ล้วน: `PetStageBadge`

- **ทำอะไร:** เริ่มชุด "component ที่ไม่ต้องรอ SC-PM-05" ตัวแรกตาม [spec.md § ความพร้อม](spec.md) — branch `feat/room-pet-ui` (zyra-app, แตกจาก `develop` @ `0393092`)
  - `lib/pet-stage.ts` — const กลาง: `PET_STAGE_ORDER`, `PET_STAGE_NUMBER`, `PET_STAGE_BADGE_COLOR` (hex), `PET_STAGE_BADGE_BG_CLASS` (Tailwind literal ให้ scanner เห็น), `PET_STAGE_LABEL_KEY`, `isPetStageId()`
  - `views/user/virtual-office/components/pet-stage-badge.tsx` — `PetStageBadge` 16×16 radius 4 p-2 + เลข Caption 2/Semi + highlight มุมซ้ายบน (ทำจาก Figma Ellipse 146 ด้วย CSS `blur-[6px]` แทน SVG asset) + label `sm` 14/18 (panel) / `md` 16/22 (modal) · `showLabel=false` → `sr-only`
  - i18n `VirtualOffice.petStage{Egg,Baby,Adult,Evolved}` ทั้ง en/th (th ใช้คำเดียวกับ admin `petUploadStage*`)
  - `__tests__/pet-stage-badge.test.tsx` — 15 เคส ครอบ test-plan §1.6 ทั้ง 4 แถว + sync ของ hex/class map + a11y
- **ถึงไหน:** โค้ดเขียนครบ 4 ไฟล์ · **ยังไม่ได้ mount ที่ไหน** (รอ `VOPetPanel` / `PetEvolutionModal`)
- **PR:** ยังไม่เปิด (ตั้งใจรวม component ล้วนหลายตัวใน PR เดียว)
- **verify ถึงไหน:** `vitest run __tests__/pet-stage-badge.test.tsx` **16/16 ผ่าน** · `eslint` 3 ไฟล์ใหม่สะอาด · `prettier --check` ผ่าน (auto-format 1 ไฟล์) · `tsc --noEmit` ไม่มี error จากไฟล์ใหม่ (มี 2 error เดิมใน `__tests__/pixi-game-scene.test.ts` บน `develop` อยู่ก่อนแล้ว ไม่เกี่ยว) · **ยังไม่ commit · ยังไม่ live-test** เพราะไม่มีที่ mount
- **ต่อจากนี้:** `PetTooltip` 3 variant → derive helpers `lib/pet-stage.ts` (stage/mood/relative XP) → `VOPetPanel` กับ fixture → option ใหม่ของ `makeNameTag` → prop `petDots` ของ `VOMinimap` → unhide section PET ใน Setting
- **ติดอะไร:** สี badge Adult/Evolved ไม่มีใน Figma — ใช้ค่าชั่วคราวจาก ClickUp (เขียว `#58D68D` / ม่วง `#996ADF`) พร้อม comment ใน const · test assert แค่ว่าเป็น hex ไม่ล็อกค่า (ux-ui.md §11 ข้อ 2)
