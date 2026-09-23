# SC-OBJ-NAT-01 · Progress — Nature Object Management (Admin)

> entry ใหม่อยู่**บนสุด** · ClickUp main: [86d446fw1](https://app.clickup.com/t/86d446fw1) · **asset จริงมาแล้วและรองรับแล้ว 2026-09-23** (รอบที่ 11 — spritesheet 6 เฟรม) · UI ครบทุก Figma node ตั้งแต่รอบที่ 10 · §14.1 เหลือเปิดข้อเดียว (ข้อ 12 weather mapping รอ PM) · **ยังไม่ได้เปิดดูในหน้า admin จริง** เพราะ AI login ไม่ได้ · **VO/in-game ยังวาดสไปรต์เป็นภาพเดียว ยังไม่รองรับเฟรม**

---

## รอบที่ 11 — 2026-09-23 (asset จริงมาแล้ว — spritesheet 6 เฟรม ไม่ใช่ภาพนิ่ง)

**ทำอะไร:** ผู้ใช้ส่งไฟล์จริงจากคนทำ asset มาให้ (`demo file/Tree Animation/`) บอกว่า "1000×1000 แบ่งเป็นรูป 160×220 แก้ให้เป็นไปตามสัดส่วนนี้" → วัดของจริงก่อน แล้วค่อยแก้

### สิ่งที่วัดได้ (ต่างจากที่บอกไว้ 2 จุด)

| | ที่บอกไว้ | **วัดจริง** |
|---|---|---|
| ชีต | 1000×1000 | 1000×1000 ✓ |
| ขนาดเฟรม | 160×220 | **160×222** (`Tree idle.png` เป็นขนาดนี้เป๊ะ) |
| ระยะห่างต่อเซลล์ | 160 | **1000/6 = 166.67** |
| จำนวนเฟรม | — | **6** |
| แถวที่มีภาพ | — | **16–237** เท่านั้น (ล่างว่าง 778 แถว) |

**สำคัญ:** ภาพวาดกว้าง 160 จริง แต่ **export วางห่างกัน 166.67** — คนละเรื่องกัน · ถ้าหั่นที่ 160 เป๊ะตามที่สั่ง จะกินเข้าไปในเฟรมเรื่อย ๆ (เฟรมที่ 6 อยู่ x 837–996 แต่ 5×160 = 800) → ยึด **pitch = ความกว้างชีต ÷ จำนวนเฟรม** ซึ่งถูกทั้งกรณี export ชิด (960) และกรณีนี้

**บั๊กที่เจอจากการวัด:** โค้ด interim เก็บชีตด้วย `frame_count = 1`, `frame_width/height = 1000×1000` ซึ่งไม่จริง → ทุกที่ที่วาดสไปรต์วาดทั้งชีต = admin ที่อัปไฟล์นี้จะเห็น**ต้นไม้ 6 ต้นเบียดกันอยู่มุมกล่อง**

### ที่ทำ

| PR | Repo | ทำอะไร |
|---|---|---|
| [zyra-api#138](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/138) | zyra-api | `nature_sprite_strip.go` — normalise ตอน upload: หา strip จาก alpha, crop แถวที่ว่าง, เขียนใหม่เป็น strip ชิด N เซลล์เท่ากัน, เก็บ `frame_count`/`frame_width`/`frame_height` ของ strip ที่เขียนใหม่ |
| [zyra-app#446](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/446) | zyra-app | `NatureSpriteFrame` วาดทีละเซลล์ผ่าน `background-position` + `image-rendering: pixelated` · ใช้ใน HP-05 (เล่น animation), HP-03 canvas และ Object Preview (ค้างเฟรม 0) · ฟอร์มโชว์ Frame count จริงแทนเลข 1 ที่ hardcode |

**ทำไม normalise ที่ server ไม่ใช่ให้ client รู้เรื่อง padding เอง:** เพราะ consumer มีหลายตัว (preview modal, Object Preview, upload canvas, และต่อไปคือ VO renderer) — ให้ทุกตัวรู้เรื่อง padding กับ pitch เศษส่วนเองคือเปิดช่องให้หลุดกันคนละแบบ · normalise ครั้งเดียวแล้วทุกตัวเห็น strip ชิด ๆ เหมือนกันหมด

### กติกาที่ตั้งใจทำและห้ามพัง

1. **เฟรมต้องคงระยะเยื้องภายในเซลล์ตัวเอง** — ระยะเยื้องนั่นคือ animation (ต้นไม้เอนซ้ายขวาในรอยเท้าเดิม) ถ้า "จัดกลางให้" = ลบ animation ทิ้ง · มีเทสกันไว้
2. **copy เซลล์ ห้าม resample** — pixel art เบลอ และลำต้นจะกระตุกทีละพิกเซลระหว่างเฟรม
3. **ชีตเฟรมเดียวที่ชิดขอบอยู่แล้ว → คืนไบต์เดิม** ไม่ decode/encode ใหม่
4. **algorithm ฝั่ง Go กับ TS ต้องตรงกัน** (tolerance 2px, เงื่อนไข fallback) — ถ้าไม่ตรง client จะ preview ที่ pitch ที่ server ไม่ได้เก็บ ซึ่งแย่กว่าไม่มี preview

### ข้อจำกัดที่รู้ตัว (มีเทสตั้งชื่อกำกับ ห้ามมา "แก้" ด้วยการเดา)

ถ้า export แบบ**ไม่มีช่องว่างใสคั่นระหว่างเฟรม** คอลัมน์ทึบจะต่อกันเป็นก้อนเดียว แยกจากภาพเดี่ยวกว้าง ๆ ไม่ออกจาก alpha → fallback เป็น 1 เฟรม (= พฤติกรรมเดิม ไม่ regress) · asset จริงทั้ง 2 ไฟล์มีช่องว่าง 3–6px · ถ้าจะให้ชัวร์ ควรขอให้คน export ใส่ช่องว่างไว้เสมอ หรือไม่ก็เพิ่มช่องกรอก frame count (ซึ่งขัดมติ 2026-09-20 ต้องถาม PM)

### verify ถึงไหน

| วัดอะไร | ผล |
|---|---|
| รันกับไฟล์จริง | `Tree Animation.png` → 6 เฟรม 167×222 (ชีต 1002×222, 164 KB → 157 KB) · `Tree idle.png` → 1 เฟรม 160×222 ไบต์เดิม |
| ภาพ output | เปิดดูแล้ว — ต้นไม้ 6 ต้นเรียงชิด ไม่มี padding |
| render ใน modal (dev harness) | ต้นไม้ **ต้นเดียว** ยืนบน tile · กล่อง 167×222 (strip ที่ normalise แล้ว) และ 166.66×222 (export ดิบ) · `background-position` เดินจากเฟรม 5 → 0 ใน 350ms · bottom-centre ตรงกับ tile ทั้งคู่ (482=482, 601=601) |
| test | Go `go test ./...` เขียว (+4 ชุด table-driven) · TS `vitest` 186 files / 2541 tests (+17 case) · `tsc` · `eslint` · `next build` เขียว |

**ยังไม่ได้ทำ/ยังไม่ได้ verify:** หน้า admin จริง (ต้อง login) · **ฝั่ง VO/Phaser/Pixi ยังวาดสไปรต์เป็นภาพเดียวอยู่** — ถ้าเอา nature ขึ้น map จริงต้นไม้จะโชว์ทั้งชีต ต้องทำต่อ

**ต่อจากนี้:**
1. merge 2 PR → develop แล้วเช็ค dev
2. ทำ frame-aware rendering ฝั่ง VO (`zyra-engine`) — งานก้อนถัดไปที่จำเป็นจริง ๆ ก่อนเอา nature ขึ้น map
3. ยืนยันกับคนทำ asset ว่า export จะเป็น pitch 166.67 แบบนี้ตลอด หรือจะเปลี่ยนไป export ชิด (960×222) — ทั้งคู่รองรับแล้ว แต่ควรรู้ว่าจะยึดอันไหน

**ติดอะไร:** login หน้า admin · §14.1 ข้อ 12 ยังรอ PM

---

## รอบที่ 10 — 2026-09-22 (HP-05 preview modal — node สุดท้าย + ปิด §14.1 ที่เหลือ)

**ทำอะไร:** ผู้ใช้สั่ง "ทำทั้งหมด ต่อให้เสร็จ" → เก็บงานที่ค้างจากรอบ 9 ทั้งหมดที่ทำได้เอง: implement HP-05 ซึ่งเป็น node เดียวที่ยังไม่ได้ทำ, ปิดข้อที่เหลือใน §14.1, และ **verify ด้วยตาให้ได้โดยไม่ต้อง login**

**ถึงไหน:** [zyra-app#432](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/432)

| ไฟล์ | ทำอะไร |
|---|---|
| `nature-preview-modal.tsx` (ใหม่) | HP-05 node `5199:369528` + dropdown `5219:751880` — shell 900×600 · canvas 868×488 grid 40px · tile 1×1 ที่พิกัด Figma · sprite **bottom-centre anchored** บน tile (zoom แล้วเท้ายังติดพื้น) · wind thresholds block · weather picker เปิดขึ้นบน · zoom pill |
| `nature-canvas.tsx` (ใหม่) | ดึง zoom pill + grid 40px ที่ซ้ำกันระหว่าง HP-03 กับ HP-05 ออกมาเป็นของกลาง ([rule 09](../../../.claude/rules/09-component-reuse.md)) — HP-03 พฤติกรรมไม่เปลี่ยน |
| `nature-upload-modal.tsx` | footer `Preview` ส่ง **draft ของ modal เอง** ขึ้นไป (ไฟล์ที่เพิ่งเลือกยังไม่เข้า state ของฟอร์ม — ถ้าส่งของฟอร์มจะ preview ผิดตัว) |
| `object-add-form.tsx` · `object-detail-content.tsx` | ปุ่ม `Preview` บน header ทั้งโหมด create/edit และ view (เฉพาะ nature) · disabled เมื่อยังไม่มี sprite สักตัว |
| `constants.ts` | `MAX_NAME_LENGTH` 50 → **100** (§14.1 ข้อ 14) |
| `__tests__/nature-preview-state.test.ts` (ใหม่) | 10 case ของ `resolveNaturePreviewState` รวม sweep ว่า **ไม่มีทางคืน state ที่ `nature_type` นั้นไม่มี** |

### §14.1 ปิดเพิ่ม 6 ข้อ — เหลือเปิดข้อเดียว

| ข้อ | สรุป |
|---|---|
| 5 · entry point | ปิด — ทำตาม Figma: ไม่มี route/tab/sidebar ใหม่ Nature เป็น category ที่ 10 |
| 9 · delete confirm | ปิด — code เดิมตรง Figma อยู่แล้ว ไม่ต้องแก้ · **spec ClickUp ยังผิด** |
| 10 · transparency | ปิด — บล็อกทั้ง client และ server ตาม Figma |
| 11 · preview controls | ปิด — ทำตาม Figma (ไม่มี state buttons / playback) + idle fallback · **AC 3 ข้อใน ClickUp ยังค้าง** |
| 13 · "(Hidden)" badge | ปิด — **ตัดทิ้ง** ไม่มีทั้งใน Figma และ code เดิม และกระทบ object ทุกชนิด ไม่ใช่ scope นี้ |
| 14 · name 100 | ปิด — spec + Figma ตรงกัน และ DB เป็น `VARCHAR(100)` อยู่แล้ว |
| **12 · weather mapping** | **ยังเปิด** — ทำไปด้วยสมมติฐาน (ดูด้านล่าง) รอ PM ยืนยัน |

### จุดที่ตัดสินเองเพราะไม่มีค่าจริง (บันทึกไว้ให้แก้ทีเดียวถ้า PM/designer ตอบมา)

1. **Strong rain / Thunderstorm → state ไหน** — ไม่เคยมี mapping ที่ไหนเลย · ตีความว่า "แรงอย่างน้อยเท่า Rain" แล้ว resolve ไป state แรงสุดเท่าที่ `nature_type` มี ⇒ มีแต่ `shedding_tree` ที่ถึง `falling` ที่เหลือกลับมา `sway_strong`
2. **wind slider 0–90** — best-fit จาก 6 เฟรม (9→23px, 80→215px, ไม่ linear) · เลือก weather แล้ว slider เด้งไปค่าของเฟรมนั้น แต่ **ค่า wind ไม่ได้เปลี่ยน state** เพราะ Rain default 29 ขัดกับ `sway_strong ≥ 30` ในตัว spec เอง — ถ้าให้ wind คุม state จะได้ผลไม่ตรง mapping ของ PM
3. **weather icon = lucide monochrome** — Figma เป็นภาพประกอบมีสี (sun gradient, cloud raster, bolt `#FFED8D`) แต่ [rule 12](../../../.claude/rules/12-icons.md) บังคับ lucide-only · ยอมรับว่า fidelity ตกตรงนี้ ถ้าจะเอาของ Figma ต้อง export 5 SVG ลง `components/ui/icon.tsx`
4. **ปุ่ม Preview ใช้ h-40 ไม่ใช่ 42** — ให้เท่ากับ Cancel/Save ที่อยู่ข้างกัน (§7.2 เองก็เป็น h-40) ไม่งั้นแถวปุ่มจะสูงไม่เท่ากัน

### verify ถึงไหน — คราวนี้**เห็นของจริงแล้ว** (ต่างจากรอบ 9)

รอบ 9 ติดว่า AI login หน้า admin ไม่ได้ (ใส่รหัสผ่านแทนผู้ใช้ไม่ได้) เลย verify ได้แค่ build เขียว · รอบนี้แก้ด้วยการ mount modal ใน harness ชั่วคราวใต้ `app/dev/` (public เฉพาะ dev) แล้ว**อ่านค่า geometry จริงจาก DOM มาเทียบ Figma** แล้วลบ harness ทิ้งก่อน commit

| วัดอะไร | Figma | ที่ render จริง |
|---|---|---|
| canvas | 868×488 | 868×**487** — ต่าง 1px เพราะ Figma วาด divider เป็นเส้น 1px ที่สูง 0, CSS สูง 1px จริง |
| wind block | 260×50 @ y 530 | 260×50 @ y **529** (ตอนแรกได้ 56 — wrapper ของค่า km/h ไม่ได้ `text-[0px]` ตาม Figma ทำให้แถวสูงเกิน 6px → แก้แล้ว) |
| tile ↔ sprite | bottom-centre ตรงกัน | ตรงกันที่ zoom 50–200% (เช็ค 150%: tile bottom 482 = sprite bottom 482, centre 601 = 601) |
| dropdown | 161 กว้าง, เปิดขึ้นบน, x เดียวกับ trigger | ตรง |

- `vitest` **185 files / 2518 tests** ผ่าน (เดิม 183/2501) · `tsc --noEmit` ไม่มี error ใหม่ · `eslint` clean · `next build` ผ่าน
- **ยังไม่ได้เปิดดูใน `/admin/object-management` จริง** — harness พิสูจน์ตัว modal เอง ไม่ได้พิสูจน์ว่าปุ่ม Preview ในหน้าจริงเปิดมันขึ้นมาถูกตัว/ถูกสถานะ

**ต่อจากนี้:**
1. merge #432 → `develop` แล้วเช็ค dev
2. เปิด `/admin/object-management` ด้วยตาคน (ต้องมี login) — จุดเดียวที่เหลือของ Figma fidelity
3. ขอ PM แก้ ClickUp 4 จุด: HP-02 ที่ยังเขียน redirect ไป Animation Manager · HP-05 AC 3 ข้อ (state buttons / Current State / playback) ที่ design ไม่มี · HP-07 delete condition · mapping ของ Strong rain / Thunderstorm
4. ตัดสินเรื่อง backfill 24 object / 2,453 placement ที่โดนบั๊ก `buildCellsFromHitbox` (prod write — ต้องขอ sign-off)

**ติดอะไร:** login หน้า admin (ต้องเป็นผู้ใช้ทำเอง) · §14.1 ข้อ 12 และ §15 ที่เหลือรอ PM/designer

---

## รอบที่ 9 — 2026-09-22 (UI จริงตาม Figma + merge/deploy ครบทั้ง backend และ frontend)

**ทำอะไร:** ผู้ใช้ทักว่า UI ที่ทำรอบที่ 8 เป็นของเก่า/เวอร์ชันย่อ ไม่ใช่ design จริง → ดึง Figma ใหม่ผ่าน MCP ทั้ง 7 node แล้ว implement ใหม่ให้ตรง พร้อมปิดงาน backend ที่ทำให้ "สร้าง object ได้จริง"

**ถึงไหน — merge เข้า `develop` + deploy ขึ้น dev ครบแล้ว 3 PR:**

| PR | Repo | merge commit | ทำอะไร |
|---|---|---|---|
| [zyra-api#131](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/131) | zyra-api | `800e8ef` | `CreateObject`/`UpdateObject` รับ `nature_type` + batch upload sprite ในคำขอเดียว · endpoint ใหม่ `GET /:id/animations` + `PUT /:id/animations/:state` · active-gating บังคับที่ server · ล็อก `nature_type` เมื่อมี animation แล้ว |
| [zyra-app#427](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/427) | zyra-app | `a24f31d` | เปิด `"nature"` ใน Category dropdown + save path แยกสำหรับ nature (ไม่มี composer) |
| [zyra-app#429](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/429) | zyra-app | `44f9079` | **UI จริงตาม Figma ทั้ง 7 node** (รายละเอียดด้านล่าง) |

### UI ที่ทำตาม Figma (PR #429)

| Node | Screen | สิ่งที่ทำ |
|---|---|---|
| `5167:320033` → `5167:331415` | HP-02 create | Nature type คู่กับ Z-index แถวเดียว · Status ลงแถวเอง · section `Upload stage & animation` (title+Info, subtitle, ปุ่ม `+ Upload` เขียว, Frame count/rate read-only, Object files 256px + preview grid 425px) · ดึง Status toggle เป็นตัวแปรเดียวใช้ 2 ที่ ไม่ให้มี switch ซ้ำใน DOM |
| `5184:334464` → `6034:345420` | HP-03 upload modal | `nature-upload-modal.tsx` ใหม่ 900×600 — tab ต่อ state + badge นับไฟล์ · canvas + zoom pill · pills X/Y/W/H · banner PNG · dropzone/file row · footer Preview ǀ Cancel · Save · ไฟล์ staged แล้วส่งไปพร้อม Save ของฟอร์ม (ตอนสร้าง object ยังไม่มีใน DB) |
| `5008:246597` → `5045:273291` | HP-01 tree card | `State : N` (= จำนวน state ที่ type นั้น**มี** ตาม §14.2 ข้อ 17 — derive จาก `NATURE_ALLOWED_STATES` ไม่ต้องแก้ backend) + tag `nature_type` สี Blue/500 แทน grid size + tint + category tag |
| `5230:775889` | EP-01 error toasts | `nature-upload-validation.ts` ใหม่ + toast ต่อ error code copy ตรงจาก design · transparency เป็น **error บล็อก** ตาม design (ไม่ใช่ warning ตาม spec เก่า — §14.1 ข้อ 10 ปิด) |
| `5230:791935` → `6037:509126` | EC-01 replace | `replace-spritesheet-dialog.tsx` ใหม่ — เด้ง**ก่อน**เปิด file picker เมื่อ sprite นั้น live อยู่ใน workspace แล้ว |
| `5219:753640` → `5219:760257` | HP-06 saved/edit | view mode ดึง sprite ที่ save แล้วมาโชว์ (ผ่าน `listObjectAnimations`) ควบกับไฟล์ที่ staged · preview fallback เป็น idle ที่บันทึกไว้ |
| `5219:761384` | HP-07 hide/delete | **มีครบอยู่แล้ว ไม่ต้องแก้** — panel 384px "Affected Workspaces & Maps" + confirm-name modal ใน `delete-object-dialog.tsx` ตรง Figma |

### จุดที่ตั้งใจไม่ทำตาม Figma (บันทึกไว้เพื่อไม่ให้รอบหน้ามาแก้กลับ)

1. **Frame count / rate โชว์ `1` / `12` ไม่ใช่ `50` / `24` ตาม mock** — 1/12 คือค่าที่ API เก็บจริง (`tb_object_animation` default; ไม่มีช่องกรอกตามมติ 2026-09-20) โชว์ 50/24 = UI บอกข้อมูลเท็จกับ admin · ถ้าจะเอา 50/24 จริงต้องเปลี่ยน DB default ด้วย
2. **HP-06 ยังมีปุ่ม Delete** ทั้งที่เฟรม view mode ไม่มี — Figma ขัดกันเองเรื่องจุดกด Delete (§14.3 ข้อ 28 `ต้องดึง`) และถ้าเอาออกจะไม่เหลือทางลบ object เลย
3. **ปุ่ม Preview ยังไม่ทำงาน** — HP-05 (`5196:368373`) ไม่อยู่ใน 7 node ที่สั่ง · ใน modal ทำเป็น disabled ไว้, บน header ยังไม่ใส่ (ปุ่มตายแย่กว่าไม่มี)

### เจอระหว่างทาง

- **เลข migration ชนกัน** — `103` ที่ technical-design จองไว้ถูก `feat/admin-roadmap-api` ใช้ไปแล้วบน develop → renumber เป็น **`105_object_nature.sql` / `106_object_animation.sql`** (แก้ทั้งชื่อไฟล์ เลขใน comment และ reference ในโค้ด Go)
- **`CreateObject` ไม่มี unit test มาก่อนเลย** และ `ObjectService` ถือ `*pgxpool.Pool` ตรง ๆ → แยก logic ที่ไม่แตะ DB ออกเป็น `internal/service/object_nature.go` เพื่อให้ table-driven test ได้ตาม test-plan §1.0

**verify ถึงไหน:**
- zyra-api: `go build` · `go vet` · `go test ./...` เขียว
- zyra-app: `tsc --noEmit` ไม่มี error ใหม่ · `vitest` 183 files / 2501 tests ผ่าน · `eslint` clean · `next build` ผ่าน · CI ครบทุก check รวม CodeRabbit
- **deploy ขึ้น dev จริงแล้ว ตรวจ health ยืนยัน version ตรง sha:** `api.dev.zyra.center/api/health` → `dev-800e8ef` · `app.dev.zyra.center/api/health` → `dev-44f9079` (ไล่ครบ GitHub Actions → `zyra-infra` values.yaml → Argo CD sync → pod rollout)
- ⚠️ **ยังไม่ได้ verify ด้วยตาบนเบราว์เซอร์** — CI เช็คแค่ build/test ไม่ได้เทียบภาพกับ Figma · หน้า admin ต้อง login ซึ่ง AI ทำเองไม่ได้ (นโยบายห้ามกรอกรหัสผ่าน) → **ยังไม่ถือว่า Figma fidelity ผ่าน จนกว่าจะมีคนเปิดดูจริง**

**ต่อจากนี้:**
1. เปิด `app.dev.zyra.center` → Object management → Category = Nature ดูของจริง แล้วแจ้งจุดที่เพี้ยน
2. HP-05 preview modal (`5196:368373`) ถ้าจะทำ — ปุ่ม Preview 2 จุดรออยู่
3. blocker UI ที่เหลือใน §14.1 (5, 9–14) + ค่า `ต้องดึง` ใน §15 ยังไม่ได้เคลียร์กับ PM
4. ยังไม่ได้แก้ spec ใน ClickUp ให้ตรงมติ (HP-07 delete, `petal_fall`, required states, frame config)
5. ยังไม่ได้ตัดสินเรื่อง backfill 24 object ที่โดนบั๊ก collision (2,453 placement)

**ติดอะไร:** ไม่มีที่บล็อกงาน — เหลือแค่รอคนเปิดดู UI จริงกับรอ PM ตอบข้อที่ค้าง

---

## รอบที่ 8 — 2026-09-20 (implement เริ่มแล้ว — 3 PR แรก)

**ทำอะไร:** ลงมือเขียนโค้ด 3 งานที่ไม่ขึ้นกับ blocker ที่เหลือ (§14.1 ที่ยังไม่ตัดสินเป็นเรื่อง UI ล้วน — ดูรอบที่ 7)

**ถึงไหน — เปิด PR แล้ว 3 ใบ:**

| PR | Repo | ทำอะไร |
|---|---|---|
| [zyra-api#130](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/130) | zyra-api | migration `105_object_nature.sql` (`tb_object.nature_type`) + `106_object_animation.sql` (`tb_object_animation`, DB `CHECK` บน `state` เพราะไม่มี custom แล้ว) · `model.ObjectTypeNature` เข้า `validObjectTypes` · 6 `NatureType*` + 4 `AnimState*` constants · `NatureAllowedStates`/`NatureDefaultGridSize`/`IsValidNatureType`/`IsValidAnimationState` · table-driven test ครบ (`object_nature_test.go`) |
| [zyra-app#425](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/425) | zyra-app | แก้บั๊ก collision default ที่วัด prod แล้ว 2,453 placement (รอบที่ 5–6) — `buildCellsFromHitbox(hitbox, mode)` ไม่ hardcode `"blocked"` อีกต่อไป · เป็น prerequisite ของ HP-02 |
| [zyra-app#426](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/426) | zyra-app | เพิ่ม `"nature"` เข้า `ObjectType` + `TYPE_CONFIG` badge (สี `#2C5AE4` Navy/500 จาก Figma จริง ไม่ใช่เดา) + filter checkbox + icon `TreePine` + `deriveCollisionModeFromType` + `DEFAULT_Z_INDEX.nature=3` — **ตั้งใจไม่เพิ่มเข้า `OBJECT_TYPES`** (Category dropdown ในฟอร์มสร้าง) เพราะยังไม่มี special-case `category==="nature"` (ux-ui-plan §3.4) ถ้าเปิดตอนนี้จะสร้าง object ที่ไม่มี nature_type และ upload ไม่ได้ |

**เจอระหว่างทำ:** migration เลข `103` ที่ technical-design ออกแบบไว้ถูก branch อื่น (`feat/admin-roadmap-api`) ใช้ไปแล้วบน `develop` → ต้อง renumber เป็น **105/106** (แก้ทั้งไฟล์ migration และ comment ในโค้ดที่อ้างเลขเดิม)

**verify ถึงไหน:**
- zyra-api: `go build ./...` · `go vet ./...` · `go test ./...` (ทุก package) · `gofmt -l` เขียวหมด
- zyra-app: `npx tsc --noEmit` ไม่มี error ใหม่ (error เดิม 6 ตัวใน `environment-weather-fx`/`pet-creation-wizard`/`pixi-game-scene` ไม่เกี่ยวกับที่แก้) · `npx vitest run` 180 files ผ่านหมดทั้ง 2 branch · `npx eslint` clean
- **build เขียวเท่านั้น — ยังไม่ได้ deploy/live-test บน dev environment**

**ต่อจากนี้:**
1. รอ PR ทั้ง 3 ใบ review + merge เข้า `develop`
2. งานถัดไปตาม task breakdown ([technical-design §9](technical-design.md#9-task-breakdown-แนะนำ-ตาม-01-planmd--แบ่งให้จบใน-1-prtask)): animation sub-resource endpoints (`GET/PUT /:id/animations`) + `nature-animation-manager.tsx` (ต้องรอ category=nature special-case ก่อน)
3. blocker ที่เหลือใน §14.1 (5, 9–14 + ค่า `ต้องดึง` §15) ยังเป็นเรื่อง UI ล้วน ไม่บล็อกงาน backend ที่เหลือ

**ติดอะไร:** ไม่มี — งานเดินต่อได้ปกติ

---

## รอบที่ 7 — 2026-09-20 (เคาะครบ 5 blocker · schema ปลดล็อก)

**ทำอะไร:** รับคำตอบ 5 ข้อสุดท้ายที่บล็อก schema แล้วเขียนลงเอกสารทุกไฟล์

**ถึงไหน — ทั้ง 5 ข้อปิดหมด:**

| # | มติ | ผลต่อโค้ด |
|---|---|---|
| 1 | **required = `idle` ตัวเดียว** ทุก type · state ที่ไม่มีไฟล์ **fallback ไป `idle`** ตอน render (ทั้ง preview และ VO จริง) | `NatureRequiredStates` map ยุบเหลือ `const NatureRequiredState = AnimStateIdle` · ต้องทำ fallback resolver ฝั่ง client |
| 2 | key `sway_strong` · label **`Sway normal`** — **แยก key กับ label มี 4 state ไม่ใช่ 5** | i18n `natureAnimStateSwayStrong` = "Sway normal" · ห้ามเอา label ลง DB/S3 |
| 3 | **ไม่ต้องมี frame_count/frame_rate เลย** ทั้ง field และ dropdown (ตัด dropdown read-only ออกจากฟอร์มด้วย) | คอลัมน์มี `DEFAULT 1` / `DEFAULT 12` · client ไม่ส่ง · API ยังรับไว้เผื่ออนาคต |
| 4 | **ไม่มี `custom`** เหลือ 6 nature_type | `state` เป็นชุดปิด 4 ค่า → ใส่ DB `CHECK` ได้ · ตัด regex slug ทิ้ง |
| 5 | active gating **กันทั้ง server และ client** | server reject `status=active` เมื่อไม่มี `idle` + client disable Save ([§6.1](technical-design.md#61-active-gating--กันสองชั้น)) |

**ไฟล์ที่แก้:** [technical-design.md](technical-design.md) — เขียน §4 ใหม่ทั้งหัวข้อ (states/fallback/label map/grid default) · §2.2 schema (DEFAULT + CHECK + ตัด custom) · §5.1–5.2 (nature_type 6 ตัว · frame fields optional · Nature ส่ง composition ได้) · §6.1 ใหม่ (gating 2 ชั้น) · ตัด sentinel `ErrCompositionNotAllowedForNature` · [ux-ui-plan §14.1](ux-ui-plan.md) ปิดข้อ 1/2/3/7/8 · [test-plan §0 + §1.1 + §1.2](test-plan.md) ปลดล็อกเทสที่เคยห้ามล็อกค่า + เพิ่มเทส fallback

**PR:** ต่อจาก [#27](https://github.com/N2Pluto/zyra-doc/pull/27)

**verify ถึงไหน:** เอกสารล้วน ยังไม่แตะโค้ด — **แต่ตอนนี้ §14.1 ไม่เหลือข้อที่กระทบ schema/API แล้ว = เขียน migration 103/104 ได้จริง**

**ต่อจากนี้:**
1. `feat(api)`: migration 103 (`tb_object.nature_type`) + 104 (`tb_object_animation` พร้อม DEFAULT/CHECK) + `"nature"` เข้า `validObjectTypes`
2. `fix(app)`: บั๊ก collision default (`buildCellsFromHitbox` รับ `mode`) — prerequisite ของ HP-02 มีผลวัด prod แล้ว 2,453 placement
3. `feat(app)`: `"nature"` เข้า enum/badge/filter + `deriveCollisionModeFromType`
4. ที่ยังเปิดคือเรื่อง UI ล้วน (§14.1 ข้อ 5, 9–14 + ค่า `ต้องดึง` ใน §15) ไม่บล็อก backend

**ติดอะไร:** ยังไม่ได้แก้ spec ใน ClickUp ให้ตรงกับมติทั้งหมด (HP-07 delete, `petal_fall`, required states, frame config) — ต้องให้ PM แก้ · ทีมยังไม่เคาะเรื่อง backfill 24 object

---

## รอบที่ 6 — 2026-09-17 (วัดบั๊ก collision กับ prod จริง)

**ทำอะไร:** รัน query บน prod AlloyDB (read-only ผ่าน IAP tunnel) เพื่อวัดผลกระทบของบั๊ก `buildCellsFromHitbox` ที่เจอในรอบที่ 5

**ถึงไหน:** **ยืนยันว่าบั๊กเกิดขึ้นจริงบน production**

| ตัวชี้วัด | ค่า |
|---|---|
| object ที่ type ควร walkable แต่มี blocked cell | **32** (`decoration` 18/68 · `machine` 14/18 = 78% · `foods_and_drink` 0/32 · `walkable_group` 0/46) |
| แยกเฉพาะที่**ไม่มี cell walkable เลย** = ลายเซ็นของ fallback | **24** (`decoration` 15 · `machine` 9) — อีก 8 ตัวเป็น cell ผสม = admin ตั้งใจระบาย |
| placement ที่กันทางทั้งที่ควรเดินทะลุได้ | **2,453** |
| map / workspace ที่กระทบ | **50 / 47** |

**PR:** ต่อจาก [#26](https://github.com/N2Pluto/zyra-doc/pull/26)

**verify ถึงไหน:** วัดจริงด้วย SQL 4 ชุดบน prod (snapshot 2026-09-17 ~15:10) — **Before เท่านั้น ยังไม่มี After เพราะยังไม่ได้แก้โค้ด** · ตัวเลข 24 เป็น "น่าจะเป็นบั๊ก" ไม่ใช่ยืนยัน 100% (ข้อมูลแยกไม่ออกระหว่าง fallback กับ admin ที่ตั้งใจระบาย blocked ทั้งแผง — ใช้เกณฑ์ `walkable_cells = 0`)

**ต่อจากนี้:** ตัวเลขใหญ่พอที่ควรพิจารณา **backfill** 24 object แทนที่จะแก้ไปข้างหน้าอย่างเดียวตามที่เสนอไว้ตอนแรก — ต้องให้ทีมเคาะ · ส่วน blocker 5 ข้อของ Nature ยังค้างเหมือนเดิม

**ติดอะไร:** รอทีมตัดสินเรื่อง backfill · รอ PM ตอบ §14.1 5 ข้อ

---

## รอบที่ 5 — 2026-09-17 (ปิด blocker 14a + เจอบั๊ก collision default)

**ทำอะไร:** ตรวจโค้ด UI จริงตามที่ผู้ใช้สั่งว่า "สี/blocked-walkable ของเดิมก็มีอยู่แล้ว" แล้วเขียน design ใหม่ให้ตรงของจริง

**ถึงไหน:**
- **✅ ปิด blocker ข้อ 14a** (ตัวที่หนักสุดใน §14.1) — 🎨 = piece tag colour `PRESET_COLORS` 13 สี (`color-picker-popup.tsx:7`) ไม่ลง DB · 🖌 = collision brush ที่ default มาจาก `deriveCollisionModeFromType` (`constants.ts:90`) → Nature แค่เพิ่มเข้าลิสต์ walkable 1 บรรทัด · "walkable เสมอ" = default ของ type ไม่ใช่ล็อก จึงไม่ขัดกับ AC → เหลือ blocker 5 ข้อ
- **แก้ [technical-design §3](technical-design.md) ใหม่ทั้งหัวข้อ** — ฉบับก่อนเขียนว่า "Nature ไม่ insert แถว `object_compositions`" **ผิด** เพราะ `object-add-form.tsx:687` สร้าง composition ให้ทุก object ยกเว้น wall · ของจริงคือ Nature เดินเส้นเดียวกับ `decoration` เป๊ะ · กลไก no-composition เดิมยังอยู่แต่ลดบทเป็น **safety net** (§3.3)
- **เจอบั๊กใหม่** — `deriveCollisionModeFromType` ตั้งแค่โหมดพู่กัน แต่ `buildCellsFromHitbox` **hardcode `type: "blocked"`** ทั้ง `constants.ts:119` และ `object-preview-canvas.tsx:438` → object ที่ควร walkable ถูก save เป็นกำแพงถ้า admin ไม่ระบายเอง · กระทบ `decoration`/`machine`/`foods_and_drink` ด้วย ไม่ใช่แค่ Nature · บันทึกที่ [`issues/object-hitbox-default-collision-mode-2026-09-17.md`](../../issues/object-hitbox-default-collision-mode-2026-09-17.md) พร้อมวิธีแก้ (เพิ่ม param `mode` default `"blocked"`) + SQL วัดผลกระทบ — **เป็น prerequisite ของ HP-02**

**PR:** ต่อจาก [#24](https://github.com/N2Pluto/zyra-doc/pull/24)

**verify ถึงไหน:** เอกสารล้วน · ข้อเท็จจริงทั้งหมดอ่านจากโค้ดจริงรอบนี้ (`constants.ts:90,115,158` · `object-add-form.tsx:144,687,1366` · `object-preview-canvas.tsx:431,947,995,1093` · `color-picker-popup.tsx:7` · `object-sprite-canvas.tsx:91`) — **ยังไม่ได้ query DB จริง** ว่ามี object กี่ตัวโดนบั๊ก collision (SQL อยู่ในไฟล์ issue แล้ว)

**ต่อจากนี้:** เหลือ blocker 5 ข้อ (§14.1 ข้อ 1, 2, 3, 7, 8) ที่ยังต้องถาม PM · แก้บั๊ก collision ก่อนหรือพร้อมกับ HP-02

**ติดอะไร:** ยังไม่มีคำตอบ PM 5 ข้อ · ยังไม่ได้แก้ spec HP-07/`petal_fall` ใน ClickUp

---

## รอบที่ 4 — 2026-09-17 (interim: รับภาพ 1000px + เจอ spec ขัด code เรื่อง Delete)

**ทำอะไร:** รับ 2 การตัดสินใจจากผู้ใช้เข้าเอกสาร + ตรวจโค้ด delete flow จริงแล้วเจอข้อขัดแย้งใหม่

**ถึงไหน:**
- **Interim decision (คนทำ spritesheet ยังไม่เสร็จ):** ให้ upload ภาพขนาดถึง **1000×1000** ไปก่อน — ยังเป็น horizontal strip format เดิม, ภาพนิ่ง = `frame_count = 1` (ผ่าน validator เดิมโดยไม่ต้องมี branch พิเศษ) · เปลี่ยนแค่ **dimension cap ตัวใหม่ `maxNatureSpriteDimension = 1000`** (ห้ามแตะ `maxSpriteDimension = 512` ของ piece/thumbnail) · **scaling = contain** รักษาสัดส่วน · บันทึกที่ [technical-design §5.2.1](technical-design.md#521--interim-2026-09-17--รับสไปรต์ขนาดใหญ่ถึง-1000px-ระหว่างที่-asset-ยังไม่เสร็จ) + เพิ่มเทสที่ [test-plan §1.3 / §3.6](test-plan.md)
- **✅ ตัดสินแล้ว — Delete ใช้ behaviour เดิม (ตัวเลือก a):** spec HP-07 บอกให้ลบ `placed_objects` ออกจาก map แต่โค้ดจงใจเก็บไว้ (contract ZYR-1088) → **ยึดของเดิม ต้องกลับไปแก้ spec ใน ClickUp** · ตรวจครบทั้งเส้นแล้วว่า **render กับ collision ตรงกัน**: `ListAllActiveObjects` (`object_service.go:627-628`) ยังคืน object ที่ soft-deleted ถ้ายังมี placement · `buildDbTiles` ยังวาด · `obstacle_grid_builder.go:245-252` query ไม่มี filter `is_deleted` เลย → ยังกันทางเหมือนเดิม **ไม่มีของล่องหนที่ยังชน** · Nature ไม่มี `object_compositions` → ไม่ส่ง hitbox เข้า obstacle grid ตั้งแต่แรก · **กับดัก: ห้ามทำ hard delete S3 ตาม spec ข้อ 30 วัน** ขณะยังมี placement ไม่งั้นจะได้ "ภาพแตกแต่ยังชน" · รายละเอียดที่ [technical-design §10 ข้อ 5](technical-design.md#10-open-items-ที่ยังไม่ตัดสินใจ-ต้องถาม-pmยืนยันก่อน-implement-จริง)
- **(เดิม) เจอ spec HP-07 ขัดกับโค้ดที่มี regression test คุมอยู่:** spec บอก delete แล้วให้ลบ `placed_objects` ออกจาก map ทันที แต่ `DeleteObject` (`object_service.go:499-532`) จงใจ**ไม่แตะ `tb_map_object`** และ contract **ZYR-1088** (`tile-builder-hidden-objects.test.ts`) บังคับว่า hidden/soft-deleted ที่วางแล้ว**ต้องยัง render** · S3 assets ก็ไม่เคยถูกลบ (ไม่มี cron 30 วัน) → เพิ่มเป็น [technical-design §10 ข้อ 5](technical-design.md#10-open-items-ที่ยังไม่ตัดสินใจ-ต้องถาม-pmยืนยันก่อน-implement-จริง) **ต้องให้ PM เลือกก่อน implement HP-07**

**PR:** ต่อจาก [#22](https://github.com/N2Pluto/zyra-doc/pull/22)

**verify ถึงไหน:** เอกสารล้วน · ข้อเท็จจริงเรื่อง cap 512 / TILE_SIZE 32 / DeleteObject / ZYR-1088 อ่านจากโค้ดจริงในรอบนี้ (`object_service.go:29,499-532,1011` · `zyra-engine/constants.ts:7` · `__tests__/tile-builder-hidden-objects.test.ts`) — **ยังไม่ได้รันอะไร ไม่มีโค้ดให้รัน**

**ต่อจากนี้:** ขอ PM แก้ spec HP-07 ให้ตรงกับ behaviour (a) ที่ตัดสินแล้ว ควบไปกับ §14.1 12 ข้อเดิม · เรื่อง 2MB cap ให้เช็คกับไฟล์ 1000×1000 จริงจากคนทำ asset ว่าเกินไหม

**ติดอะไร:** เหมือนรอบที่ 3 — §14.1 ยังเปิดครบ · เพิ่มข้อ delete มาอีก 1

---

## รอบที่ 3 — 2026-09-17

**ทำอะไร:** ดึง ClickUp ใหม่ทั้ง main + 9 subtask เทียบกับเอกสารรอบที่ 2 แล้ว sync เข้าเอกสาร + เขียน test plan

**ถึงไหน:**
- ClickUp เปลี่ยนแค่ **status `pending` → `in progress` ทั้ง 9 task** (HP-04 ยัง Closed/descoped) — **description ไม่เปลี่ยนแม้แต่ตัวเดียว และไม่มี comment ใหม่**
- อัปเดต [spec.md](spec.md): header blockquote, ตาราง Scenario Index (status ทุกแถว), เพิ่มหัวข้อ **§รอบที่ 3**
- อัปเดต header ของ [technical-design.md](technical-design.md) และ [ux-ui-plan.md](ux-ui-plan.md) ให้ระบุว่า open items ยังไม่ถูกตอบ
- เขียนใหม่: [test-plan.md](test-plan.md) — coverage target ตาม [04-test.md](../../../.claude/rules/04-test.md), unit Go/TS, handler, component, E2E, regression, manual QA checklist 18 ข้อ, traceability ต่อ scenario
- อัปเดตแถวของฟีเจอร์นี้ใน [plan/README.md](../README.md)

**PR:** ไม่มี (เอกสารอย่างเดียว ยังไม่แตะโค้ด)

**verify ถึงไหน:** เอกสารล้วน — **ไม่มีอะไรให้ build/test** · ข้อมูล ClickUp ยืนยันจาก API ตรง (main `date_updated` 1789616192905) · สถานะโค้ด ("ยังไม่มี `tb_object_animation` / ไม่มี `nature` ใน `validObjectTypes`") ยึดตามผลตรวจโค้ดรอบ 2026-09-16 **ยังไม่ได้ re-grep ซ้ำในรอบนี้**

**ต่อจากนี้:**
1. เอา [ux-ui-plan §14.1](ux-ui-plan.md#141-ต้องตัดสินก่อนเริ่มโค้ด-กระทบ-schema--api--flow) 12 ข้อไปถาม PM — โดยเฉพาะข้อ 1 (required states), 2 (ชื่อ state ที่ 3), 3 (frame config), 8 (status default), **14a (สี/ประเภท box ขัด always-walkable)** เพราะบล็อก migration
2. เริ่มงานที่ไม่ขึ้นกับคำตอบได้เลย: เพิ่ม `"nature"` เข้า object type enum + filter/badge, แตก validation เป็น pure function ใน `internal/model` (ไม่งั้นเทสตาม target 80% ไม่ได้ — ดู [test-plan §1.0](test-plan.md#10-ข้อจำกัดโครงสร้างที่ต้องแก้ก่อนเทสได้))
3. ขอ PM แก้ `petal_fall` → `falling` ในตาราง Nature Types ของ main task (ยังค้างจากรอบที่ 2)

**ติดอะไร:** ClickUp เปิดงานเป็น in progress แล้ว แต่ **spec ยังขัดกับ Figma 12 จุดที่กระทบ schema** — ถ้าเริ่ม migration ก่อนได้คำตอบ เสี่ยงต้องรื้อ `tb_object_animation` ทิ้ง

---

## รอบที่ 1–2 — 2026-09-16

**ทำอะไร:** ถอด spec จาก ClickUp ครบทุก subtask ([spec.md](spec.md)) · ออกแบบ schema/API/realtime จากโค้ดจริง ([technical-design.md](technical-design.md)) · ถอด Figma ครบ 8 section ([ux-ui-plan.md](ux-ui-plan.md)) · ดึง ClickUp ซ้ำหลัง PM แก้ แล้วบันทึกเป็น §รอบที่ 2

**ถึงไหน:** เอกสาร 3 ไฟล์ครบ · naming ยืนยัน `shedding_tree`/`falling` · HP-04 descoped · พบข้อขัดแย้ง Figma ↔ spec 35 จุด (12 จุดกระทบ schema/API/flow)

**PR:** ไม่มี · **verify:** เอกสารล้วน ยังไม่ implement · **ติดอะไร:** open questions ยังไม่ถูกตอบ
