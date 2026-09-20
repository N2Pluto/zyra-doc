# SC-OBJ-NAT-01 · Progress — Nature Object Management (Admin)

> entry ใหม่อยู่**บนสุด** · ClickUp main: [86d446fw1](https://app.clickup.com/t/86d446fw1) · **implement เริ่มแล้ว 2026-09-20** — 3 PR แรกเปิดแล้ว (schema + collision bugfix + enum/badge/filter), ยังไม่ merge/deploy

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
