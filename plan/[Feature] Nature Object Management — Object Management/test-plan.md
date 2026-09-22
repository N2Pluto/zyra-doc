# SC-OBJ-NAT-01 · Test Plan — Nature Object Management (Admin)

> **สถานะ:** โค้ด feature อยู่บน `develop` แล้ว และมีไฟล์เทสจริงแล้วบางส่วน (2026-09-22) — `object_nature_test.go`, `object-nature-enum/api`, `nature-upload-validation`, `nature-preview-state` · ส่วนที่ยังเป็นแผนเปล่าคือ component test, E2E และ regression · **วันที่ร่าง:** 2026-09-17 · **อัปเดตล่าสุด:** 2026-09-22
> **Scope:** HP-01, HP-02, HP-03, HP-05, HP-06, HP-07, EP-01, EC-01 (8 scenario — **HP-04 descoped** ตาม [spec.md §รอบที่ 3](spec.md#รอบที่-3--2026-09-17-status-เปลี่ยนเป็น-in-progress))
> **Repo ที่กระทบ:** `zyra-api` (Go) · `zyra-app` (Vitest + Playwright + `zyra-engine`) · `zyra-ws` (Go, relay 1 บรรทัด)
> **อ่านคู่กัน:** [spec.md](spec.md) (AC ต้นทางจาก ClickUp) · [technical-design.md](technical-design.md) (schema/API/error ที่เทสอ้าง) · [ux-ui-plan.md](ux-ui-plan.md) (Figma — **ขัด spec 12 ข้อที่ยังไม่เคาะ**)
> **กติกาบังคับ:** [04-test.md](../../../.claude/rules/04-test.md) — Go = table-driven + `testify`, mock DB ผ่าน interface **ห้ามต่อ PostgreSQL จริง** · TS = Vitest + `vi.mock` **ห้ามยิง `/api/*` จริง** · เทสทุก sentinel error
> **⚠️ อ่าน [§0](#0-สิ่งที่ห้ามล็อกค่าใน-test-จนกว่า-pm-จะเคาะ) ก่อนเขียนเทสบรรทัดแรก** — ครึ่งหนึ่งของ AC ใน ClickUp ยังขัดกับ Figma อยู่ เทสที่ล็อกค่าผิดตอนนี้จะต้องรื้อทิ้งทั้งชุด

---

## Coverage Targets

| Layer | Package / Module | Target |
|---|---|---|
| Unit (Go) | `internal/model` (nature constants + validation), ส่วนที่แตกออกมาจาก `internal/service/object_service.go` (nature/animation) | ≥ 80% |
| Unit (TS) | `lib/api/objects.ts` (ส่วน nature/animation), helper คำนวณ required/optional completeness, preview state-resolver | ≥ 80% |
| Component (TS) | upload modal, preview modal, tree card, delete/replace dialog | critical paths only |
| API (Go handler) | ทุก route ที่เพิ่ม/แก้ — `POST/PUT /api/admin/objects`, `GET/PUT /api/admin/objects/:id/animations*` | 100% endpoint coverage |
| E2E (Playwright) | 8 scenario × happy + error path | ครบทุก scenario |

> **หมายเหตุเรื่องคำว่า "80%"** — ตารางนี้คือ **code coverage** ตาม [04-test.md](../../../.claude/rules/04-test.md) · ส่วนกฎทีม "ก่อนปรับ Comp ต้องเทส ≥ 80%" เป็นคนละเรื่อง = ก่อน mark task ใน ClickUp เป็น **Completed** ต้องเดิน checklist ใน [§7](#7-manual-qa-checklist--ใช้กับกฎ-80-ก่อน-mark-completed) ให้ผ่าน ≥ 80% ของเคส

---

## 0. สิ่งที่ห้ามล็อกค่าใน test จนกว่า PM จะเคาะ

> **อัปเดต 2026-09-20 — ข้อ 1, 2, 3, 7, 8, 14a เคาะแล้ว** (ดู [technical-design §4](technical-design.md#4-animation-states--required--optional--fallback-ตัดสินแล้ว-2026-09-20)) เทสที่อิงข้อพวกนี้ **ล็อกค่าได้แล้ว** · ที่เหลือในตารางยังห้ามล็อก

ข้อขัดแย้งใน [ux-ui-plan §14.1](ux-ui-plan.md#141-ต้องตัดสินก่อนเริ่มโค้ด-กระทบ-schema--api--flow) ที่ **ยังเปิด** — เทสในไฟล์นี้ที่แตะหัวข้อพวกนี้ต้องเขียนแบบ **อ่านค่าจาก constant กลาง (`NatureRequiredStates` / `NATURE_REQUIRED_STATES`) ไม่ใช่ hardcode รายชื่อ state ในไฟล์เทส** เพื่อให้เปลี่ยนคำตอบแล้วแก้ที่เดียว

| # (§14.1) | ห้ามล็อก | เขียนเทสยังไงแทน |
|---|---|---|
| ~~1~~ | ~~จำนวน required state~~ | **เคาะแล้ว: `idle` ตัวเดียว** → เทสตรง ๆ ได้: ไม่มี `idle` → `ErrRequiredAnimationStatesIncomplete` · มี `idle` อย่างเดียว → active ได้ · **เพิ่มเทส fallback**: ขอ state ที่ไม่มีไฟล์ → คืน `idle` |
| ~~2~~ | ~~key ของ state ที่ 3~~ | **เคาะแล้ว: key `sway_strong` label `Sway normal`** → เทสได้ว่า DB/S3 key เป็น `sway_strong` และ i18n `natureAnimStateSwayStrong` = `"Sway normal"` · เทสว่า **label ไม่เคยถูกเขียนลง DB** |
| ~~3~~ | ~~frame_count/frame_rate~~ | **เคาะแล้ว: ไม่มี UI** → เทสว่า client **ไม่ส่ง** 2 field นี้ · server ใช้ DEFAULT `1`/`12` · validator ยังเทสช่วง 1–64 / 4–24 ไว้เผื่ออนาคต |
| ~~7~~ | ~~มี `custom` ไหม~~ | **เคาะแล้ว: ไม่มี** → ลบเทส custom slug regex ทิ้ง · เพิ่มเทสว่า `nature_type='custom'` → `ErrInvalidNatureType` · `state` นอก 4 ค่า → reject |
| ~~8~~ | ~~status default / จุด gating~~ | **เคาะแล้ว: กันสองชั้น** → เทส server reject `status=active` เมื่อไม่มี `idle` (บังคับ) **และ** เทส component ว่าปุ่ม Save disabled จนกว่าจะมี `idle` |
| 10 | transparency = warning (spec) หรือ error บล็อก (Figma) | เทสว่า detect ได้ถูกต้อง (มี/ไม่มี alpha channel) แยกจากเทสว่า "บล็อกหรือไม่" — อันหลังใส่ `t.Skip`/`it.todo` ไว้ก่อน |
| 11 | preview controls (state buttons / Current State label / playback) | เทสเฉพาะ **state-resolver เป็น pure function** (wind → state, + fallback เป็น `idle` เมื่อ state นั้นยังไม่ upload ตาม AC ใหม่รอบที่ 2) ยังไม่เทส UI control ที่ Figma ไม่มี |
| 12 | mapping weather 5 ตัว → state | เทส resolver ด้วย **table ที่ประกาศในโค้ด** ไม่ใช่ตารางที่เขียนซ้ำในเทส · เคส `Strong rain`/`Thunderstorm` ใส่ `it.todo` รอ PM |
| 14 | name max length (100 vs code ปัจจุบัน 50) | เทส boundary โดยอ้าง `MAX_NAME_LENGTH` จากโค้ด ไม่ใช่เลข |
| ~~14a~~ | ~~Nature มี composition ได้ไหม~~ | **เคาะแล้ว 2026-09-17: ได้ เหมือน `decoration`** → ลบเทส `ErrCompositionNotAllowedForNature` · แทนด้วยเทส `deriveCollisionModeFromType("nature") === "walkable"` และ cells default เป็น `walkable` |

**เทสที่เขียนได้เลยตอนนี้โดยไม่ต้องรอ PM:** §1.1 (constants/validation parity), §1.3 (image/frame validator), §1.4 (sentinel errors), §2 (envelope + guard), §3.1–3.2 (API client), §5 (EC-01 broadcast contract), §6 (regression ของเดิมต้องไม่พัง)

---

## 1. Unit Tests — Go (`zyra-api`)

### 1.0 ข้อจำกัดโครงสร้างที่ต้องแก้ก่อนเทสได้

`ObjectService` ถือ `db *pgxpool.Pool` ตรง ๆ (`internal/service/object_service.go:63-66`) → **method บน struct นี้ mock DB ไม่ได้** ต้องทำตาม precedent ที่มีอยู่แล้วในไฟล์เดียวกัน/ของ Pet:

- แตก logic เป็น **free function รับ narrow interface** เช่น `queryRower` (`object_service.go:68`) หรือ exec-recorder แบบ `softDeletePetType` ใน `pet_service_test.go`
- validation ล้วน (ไม่แตะ DB) ให้เป็น **pure function ใน `internal/model`** → เทสได้ตรง ๆ ไม่ต้อง mock อะไรเลย

ถ้าเขียน service ใหม่แบบฝัง SQL ไว้ใน method ทั้งก้อน จะเทสตาม target 80% ไม่ได้ — ตัดสินใจเรื่องนี้ **ก่อน** เริ่ม PR แรกของ API

### 1.1 `internal/model/object.go` — nature constants + validation (table-driven)

| Test | Input | Expected |
|---|---|---|
| `TestIsValidObjectType_Nature` | `"nature"` | `true` (และ type เดิมทั้ง 9 ยัง `true`) |
| `TestNatureRequiredStates_KeysMatchNatureTypes` | — | ทุก key ใน `NatureRequiredStates` เป็น nature type ที่ประกาศไว้ และครบทุกตัว |
| `TestNatureOptionalStates_SubsetOfKnownStates` | — | optional state ทุกตัวอยู่ในชุด state ที่รู้จัก (`idle/sway_light/sway_strong/falling`) |
| `TestNatureRequiredStates_NoDuplicateWithinType` | — | ไม่มี state ซ้ำใน slice เดียวกัน และไม่ทับกับ optional ของ type เดียวกัน |
| `TestValidateNatureType` | `big_tree` … `flower_bush` / `custom` / `sakura_tree` / `""` | 6 ตัวแรก ok · **`custom` → `ErrInvalidNatureType`** (ตัดออกแล้ว มติ 2026-09-20) · `sakura_tree` → `ErrInvalidNatureType` (ชื่อเก่า) · `""` เมื่อ `type=nature` → `ErrNatureTypeRequired` |
| `TestValidateAnimationState_FixedType` | state ที่อยู่/ไม่อยู่ใน required∪optional ของ type นั้น | ไม่อยู่ → `ErrInvalidAnimationState` |
| `TestValidateAnimationState_ClosedSet` | `leaf_drop` / `sway_normal` / `petal_fall` / `""` | **ทุกตัว → `ErrInvalidAnimationState`** — state เป็นชุดปิด 4 ค่า (`idle`/`sway_light`/`sway_strong`/`falling`) ไม่มี slug อิสระแล้ว · `sway_normal` ต้องถูกปฏิเสธด้วย (เป็น **label** ไม่ใช่ key) |
| `TestResolveStateFallsBackToIdle` | ขอ `sway_light` แต่มีแต่ `idle` | คืน `idle` · ขอ state ที่ไม่มีและไม่มี `idle` ด้วย → คืน `nil`/ไม่ render (ไม่ panic) |
| `TestNatureDefaultGridSize` | ทุก nature_type | ตรงตารางใน [technical-design §4](technical-design.md#4-nature-type--requiredoptional-states-shared-constant) |

### 1.2 `object_service` — CRUD ที่ขยาย (mock DB ผ่าน interface)

| Test | Expected |
|---|---|
| `TestCreateObject_NatureRequiresNatureType` | `type=nature`, ไม่ส่ง `nature_type` → `ErrNatureTypeRequired`, ไม่มี INSERT ถูกยิง |
| `TestCreateObject_NatureTypeOnNonNatureRejected` | `type=decoration` + `nature_type=big_tree` → error, ไม่ INSERT |
| `TestCreateObject_NatureWritesWalkableComposition` | สร้าง Nature → composition ที่บันทึกมี cells `type="walkable"` ทั้งหมด (ไม่ใช่ไม่มีแถว — มติ 2026-09-17 ดู [§3](technical-design.md#3-nature-เดินได้เสมอ--ใช้กลไก-collision-เดิม-ตัดสินแล้ว-2026-09-17)) |
| `TestCreateObject_NatureDefaultStatus` | status ที่ถูกเขียนลง DB ตรงกับค่าที่ constant กำหนด (**ห้าม assert `"hidden"` ตรง ๆ** — §0 ข้อ 8) |
| `TestUpdateObject_NatureTypeLockedWhenAnimationExists` | count > 0 → `ErrNatureTypeLocked`, ไม่มี UPDATE |
| `TestUpdateObject_NatureTypeChangeAllowedWhenEmpty` | count = 0 → UPDATE ผ่าน (HP-06 AC ข้อยกเว้น) |
| `TestUpdateObject_ActivateBlockedWhenRequiredMissing` | `status=active` ขณะ required ขาด → `ErrRequiredAnimationStatesIncomplete` |
| `TestUpdateObject_ActivateAllowedWhenRequiredComplete` | required ครบ → ผ่าน |
| `TestListObjects_FilterByNatureType` | filter `types=nature` → WHERE มี `type = 'nature'`; ไม่มี filter → พฤติกรรมเดิมไม่เปลี่ยน |
| `TestDeleteObject_NatureSoftDeleteCascade` | soft delete → ลบ `tb_map_object` ที่ reference + ไม่ hard delete แถว `tb_object` (พฤติกรรมเดิม) |

### 1.3 Animation upsert + spritesheet validator (หัวใจของ HP-03 / EP-01)

Validator ต้องเป็น pure function (`ValidateSpritesheet(cfg image.Config, frameCount, frameRate int) error`) เทสด้วย PNG ที่ encode ในเทส เหมือน `pet_service_test.go` ทำอยู่ — **ห้ามอ่านไฟล์จากดิสก์**

| Test | Input | Expected |
|---|---|---|
| `TestValidateSpritesheet_FrameCountBoundary` | 0, 1, 64, 65 | 1 และ 64 ผ่าน · 0, 65 → error |
| `TestValidateSpritesheet_FrameRateBoundary` | 3, 4, 24, 25 | 4 และ 24 ผ่าน · 3, 25 → error |
| `TestValidateSpritesheet_WidthDivisible` | w=512,n=8 · w=960,n=7 | ลงตัวผ่าน · ไม่ลงตัว → `ErrFrameWidthNotDivisible` |
| `TestValidateSpritesheet_FrameSizeComputed` | w=512,h=96,n=8 | `frame_width=64`, `frame_height=96` (ไม่ split แนวตั้ง) |
| `TestValidateSpritesheet_DimensionCapInterim` | 1000×1000 · 1001×1000 | 1000 ผ่าน (interim [§5.2.1](technical-design.md#521--interim-2026-09-17--รับสไปรต์ขนาดใหญ่ถึง-1000px-ระหว่างที่-asset-ยังไม่เสร็จ)) · 1001 → `ErrImageTooLarge` |
| `TestValidateSpritesheet_StaticSingleFrame` | 1000×1000, `frame_count=1` | ผ่าน โดย**ไม่มี branch พิเศษ** — `frame_width=1000`, `frame_height=1000` |
| `TestUploadAnimation_DoesNotUseLegacy512Cap` | 800×800 | ผ่าน — ยืนยันว่า animation path ใช้ `maxNatureSpriteDimension` ไม่ใช่ `maxSpriteDimension=512` ของ piece/thumbnail |
| `TestUploadPiece_Still512` (regression) | 800×800 piece ของ object type เดิม | ยัง `ErrImageTooLarge` — cap เดิม **ต้องไม่ถูกขยายตามไปด้วย** |
| `TestUploadAnimation_RejectsNonPNG` | JPEG bytes | `ErrInvalidPNG` — เช็ค **magic bytes `89 50 4E 47`** ไม่ใช่ `Content-Type` ที่ client ส่งมา |
| `TestUploadAnimation_RejectsOversize` | > 2MB | `ErrFileTooLarge` — ยืนยันว่าใช้ `maxNatureSpritesheetSize` (2MB) **ไม่ใช่** `maxSpriteSize` เดิม (1MB) |
| `TestUploadAnimation_AcceptsExactly2MB` | 2MB พอดี | ผ่าน (boundary) |
| `TestUploadAnimation_TransparencyDetection` | PNG มี/ไม่มี alpha | detect ถูกต้อง — **การตัดสินว่าบล็อกหรือ warn ยัง `t.Skip`** (§0 ข้อ 10) |
| `TestUpsertAnimation_S3Key` | object `o1`, state `idle` | key = `static/object/o1/animations/idle.png` ตรง [§5.3](technical-design.md#53-s3-key-convention-ต่อยอด-pattern-เดิม) |
| `TestUpsertAnimation_ReplaceOverwritesSameKey` | upsert ซ้ำ state เดิม | S3 key เดิม (ไม่สร้าง key ใหม่) + `UNIQUE(object_id,state)` ทำให้เป็น UPDATE ไม่ใช่ INSERT ซ้ำ |
| `TestUpsertAnimation_ConfigOnlyWithoutFile` | ไม่ส่ง `file` แต่ส่ง config | ไม่เรียก S3 เลย, update เฉพาะ config |
| `TestUpsertAnimation_S3NilReturnsError` | `s3 == nil` | error ชัดเจน ไม่ panic (ตาม [11-s3-storage.md](../../../.claude/rules/11-s3-storage.md)) |
| `TestUpsertAnimation_RollbackOnDBFailure` | DB error หลัง upload | `tx.Rollback` ถูกเรียก, ไม่ commit |
| `TestGetAnimations_CompletenessFields` | upload ไป 2 จาก 3 required | `completed_required` 2 ตัว, `is_active_eligible=false` · ครบ → `true` |

### 1.4 Sentinel errors — ต้องมีเทสครบทุกตัว (กติกา 04-test)

`ErrInvalidNatureType` · `ErrNatureTypeRequired` · `ErrCompositionNotAllowedForNature` · `ErrNatureTypeLocked` · `ErrInvalidAnimationState` · `ErrFrameWidthNotDivisible` · `ErrRequiredAnimationStatesIncomplete`

| Test | Expected |
|---|---|
| `TestNatureSentinelErrors_Unique` | ข้อความไม่ซ้ำกัน และ `errors.Is` แยกออกจากกันได้ทุกคู่ |
| `TestNatureSentinelErrors_WrappedNotLost` | service wrap ด้วย `fmt.Errorf("...: %w", err)` แล้ว `errors.Is` ยังจับได้ |

### 1.5 EC-01 — broadcast หลัง replace sprite

| Test | Expected |
|---|---|
| `TestUpsertAnimation_PublishesAfterCommit` | publish ถูกเรียก **หลัง** commit สำเร็จเท่านั้น (ลำดับจาก recorder) |
| `TestUpsertAnimation_NoPublishOnRollback` | DB error → ไม่ publish เลย |
| `TestUpsertAnimation_FanOutPerWorkspace` | object ถูกวางใน 3 workspace → publish 3 ครั้ง, workspace id ไม่ซ้ำ · วาง 0 workspace → ไม่ publish |
| `TestUpsertAnimation_PayloadShape` | payload = `{object_id, state, version}` และ `version` = `updated_at.UnixMilli()` |
| `TestUpsertAnimation_PublishErrorDoesNotFailRequest` | publisher error → ยัง return 200 (broadcast เป็น best-effort ตาม pattern เดิม) |

### 1.6 `zyra-ws` — relay

| Test | Expected |
|---|---|
| `TestBroadcastZoneEvent_ObjectSpriteUpdatedRelayed` | `object_sprite_updated` ถูก forward ให้ client ใน workspace นั้น **verbatim** ไม่แก้ payload |
| `TestBroadcastZoneEvent_ObjectSpriteUpdatedNoStateMutation` | hub state (zone claims ฯลฯ) ไม่ถูกแตะ |
| `TestBroadcastZoneEvent_UnknownTypeStillDropped` | type นอก allowlist ยังถูก drop เหมือนเดิม (regression) |

---

## 2. API / Handler Tests (`zyra-api`)

| Test | Expected |
|---|---|
| `TestAnimationRoutes_RequireAdminGuard` | เรียกด้วย member token → 403 · ไม่มี token → 401 (**endpoint ทั้งหมดอยู่ใต้ `/api/admin/*` ตาม [15-member-api-separation](../../../.claude/rules/15-member-api-separation.md)**) |
| `TestMemberCannotReachAnimationEndpoints` | ยืนยันว่า **ไม่มี** route `/api/user/objects/:id/animations` ถูกเพิ่มโดยไม่ตั้งใจ |
| `TestGetAnimations_ResponseEnvelope` | `{status, message, data}` ตาม `model.ObjectAnimationResponse` (ไม่ใช่ `model.APIResponse`) |
| `TestPutAnimation_MultipartParsing` | อ่าน `file`, `frame_count`, `frame_rate`, `wind_threshold_kmh`, `base_intensity_multiplier` ครบ · ค่าที่ไม่ส่ง → default (0 / 1.0) |
| `TestPutAnimation_ParseFloatFormValue` | `"1.5"` ok · `"abc"` → 400 · `"0.05"` / `"5.5"` → นอกช่วง 0.1–5.0 |
| `TestPutAnimation_ErrorMessageFormatting` | width ไม่ลงตัว → message ประกอบค่าจริงตาม EP-01 (`W`, `N`, `W/N`) — assert ว่า **ค่าถูกแทนจริง** ไม่ใช่ literal `{W}` |
| `TestPutAnimation_ErrorCodeStable` | response มี `code` ที่ frontend ใช้ map i18n (ตาม pattern `petUploadValidation<CODE>`) — code ไม่เปลี่ยนตามภาษา |
| `TestPutAnimation_InvalidStateForType` | `bush` + state `falling` → 400 `ErrInvalidAnimationState` |
| `TestCreateObject_NatureEndToEndEnvelope` | `POST /api/admin/objects` type=nature → 200 + object มี `nature_type` ใน response |

---

## 3. Unit Tests — TypeScript (`zyra-app`, Vitest)

ไฟล์อยู่ใน `zyra-app/__tests__/` ตาม layout ที่ใช้อยู่ · `vi.mock` ทุก network call **ห้ามยิง `/api/*` จริง**

### 3.1 `lib/api/objects.ts` — nature/animation client

| Test | Expected |
|---|---|
| `listObjectAnimations` เรียก path ถูก | `/api/admin/objects/{id}/animations` ผ่าน `authFetch` |
| `upsertObjectAnimation` ส่ง FormData | field ครบ, ใช้ `authFetchForm` (ไม่ใช่ JSON body) |
| `upsertObjectAnimation` ไม่มีไฟล์ | ไม่ append `file` เข้า FormData |
| error path | response status ≠ 200 → throw/return error shape เดิมที่หน้าเรียกใช้ได้ |
| **ไม่มี `/api/admin/*` หลุดไป member path** | grep-style test: ทุก function ที่ export สำหรับ member ต้องขึ้นต้น `/api/user/` หรือ `/api/objects` |

### 3.2 Shared constants parity (Go ↔ TS)

| Test | Expected |
|---|---|
| `NATURE_REQUIRED_STATES` มี key ครบทุก nature type | ไม่ขาดไม่เกิน |
| optional ไม่ทับ required | ต่อ type |
| **parity กับฝั่ง Go** | เทสอ่าน JSON fixture ที่ Go test เขียนออกมา (หรือ Go test อ่าน TS constant) — ต้องมี **แหล่งเดียว** ที่ยืนยันว่าสอง map ตรงกัน มิฉะนั้นข้อ §0 #1/#2 จะ drift เงียบ ๆ |

### 3.3 Completeness / gating helper

| Test | Input | Expected |
|---|---|---|
| `requiredProgress(natureType, uploadedStates)` | 2 จาก 3 | `{done:2, total:3, eligible:false}` |
| ครบ | 3 จาก 3 | `eligible:true` |
| `custom` | state อะไรก็ได้ | `eligible:true` (ไม่มี required ตายตัว) |
| state แปลกปลอม | `["banana"]` | ไม่นับเข้า done, ไม่ throw |

### 3.4 Preview state-resolver (HP-05, pure function)

> **✅ เขียนแล้ว 2026-09-22** — `__tests__/nature-preview-state.test.ts` (10 case) ทดสอบ `resolveNaturePreviewState(weather, natureType, available)` ที่ export จาก `nature-preview-modal.tsx`
> **หมายเหตุ signature:** ของจริงรับ **weather** ไม่ใช่ **wind** — ค่า wind ไม่ได้คุม state ในรอบนี้ (Rain default 29 ขัดกับ `sway_strong ≥ 30` ในตัว spec เอง ดู [ux-ui-plan §14.1 ข้อ 12](ux-ui-plan.md#141-ต้องตัดสินก่อนเริ่มโค้ด-กระทบ-schema--api--flow)) → เคส `boundary ที่ threshold พอดี` **ยังไม่ applicable** จนกว่า PM จะเคาะตาราง band

| Test | Input | Expected | สถานะ |
|---|---|---|---|
| weather → state mapping | Clear / Cloudy / Rain | `idle` / `sway_light` / `sway_strong` ตาม PM HP-01 | ✅ |
| **fallback เป็น idle** (AC ใหม่ รอบที่ 2) | state ที่ resolver เลือก ยังไม่ upload | คืน `idle` | ✅ |
| type ที่ไม่มี state นั้นเลย | `bush` + Rain (bush ไม่มี `sway_strong`) | คืน `idle` | ✅ |
| ไม่มีสไปรต์เลย | `available` ว่าง | คืน `undefined` → canvas วาดแต่ tile ไม่ crash | ✅ |
| ไม่มี `idle` แต่มี state อื่น | `available = [sway_light]` | คืน `sway_light` (ดีกว่า canvas เปล่า) | ✅ |
| `falling` เฉพาะ shedding_tree | Thunderstorm + `big_tree` | คืน `sway_strong` ไม่ใช่ `falling` | ✅ |
| **sweep: ห้ามคืน state ที่ type ไม่มี** | ทุก weather × ทุก 6 type | ผลลัพธ์อยู่ใน `NATURE_ALLOWED_STATES[type]` เสมอ | ✅ |
| `Strong rain` / `Thunderstorm` mapping | — | ~~`it.todo`~~ → **ล็อกค่าตามสมมติฐาน "แรงอย่างน้อยเท่า Rain"** · ถ้า PM ตอบต่างต้องแก้ทั้ง `WEATHER_OPTIONS` และเทส | ⚠️ อิงสมมติฐาน |
| boundary ที่ wind threshold | — | ยังไม่ applicable (wind ไม่คุม state) | ⏸ รอ PM |

### 3.4.1 Geometry ของ modal (HP-05) — ยังไม่มีเทสอัตโนมัติ

วัดด้วยมือรอบที่ 10 ผ่าน dev harness ชั่วคราว (ดู [progress.md รอบที่ 10](progress.md)) ไม่ได้เขียนเป็น test: canvas 868×487 · wind block 260×50 · tile ↔ sprite bottom-centre ตรงกันที่ zoom 50–200% · dropdown 161 กว้าง เปิดขึ้นบน
ถ้าจะกันการ regress ต้องเป็น visual/DOM test ซึ่งยังไม่มี infra — **อย่าเคลมว่าเทสคลุมเรื่อง layout**

### 3.5 Cache-busting (EC-01)

| Test | Expected |
|---|---|
| `thumbSrc(url, updated_at)` ต่อ sprite | URL เปลี่ยนเมื่อ `updated_at` เปลี่ยน · เหมือนเดิมเมื่อไม่เปลี่ยน |
| ไม่มี `updated_at` | คืน URL เดิม ไม่ใส่ query เปล่า ๆ |

---

### 3.6 Render ของสไปรต์ interim (frame_count = 1 · contain scaling)

| Test | Input | Expected |
|---|---|---|
| `frame_count === 1` → ไม่ animate | sprite 1 เฟรม | ไม่สร้าง animation loop / ticker (แค่วาดภาพนิ่ง) |
| scaling = contain | ภาพ 1000×1000 บน grid 3×4 (96×128px) | ย่อพอดีกรอบ **รักษาสัดส่วน** (scale = min(96/1000, 128/1000)) ไม่บิดภาพ · มีช่องว่างได้ |
| scaling ของภาพที่สัดส่วนตรงอยู่แล้ว | 3:4 บน grid 3×4 | เต็มกรอบพอดี ไม่มีช่องว่าง |

> อ้าง [technical-design §5.2.1](technical-design.md#521--interim-2026-09-17--รับสไปรต์ขนาดใหญ่ถึง-1000px-ระหว่างที่-asset-ยังไม่เสร็จ) · `TILE_SIZE = 32` ต้องอ่านจาก `zyra-engine/constants.ts` ห้ามพิมพ์ 32 ในเทส

---

## 4. Component Tests (critical paths only)

| Component | เคสที่ต้องมี |
|---|---|
| Tree card (`object-card` variant ใหม่) | badge = Nature · แสดง state count · Active/Hidden tag ถูกต้อง · ไม่ crash เมื่อไม่มี thumbnail |
| Upload modal (HP-03) | เปิดจากปุ่ม `+ Upload` (modal ไม่ใช่ route) · tab ต่อ state · แสดง badge ของ state ที่ upload แล้ว · error toast เรียกด้วย `code` จาก backend · **ไม่ assert layout ตัวเลขที่ยัง `ต้องดึง` ใน [ux-ui-plan §15](ux-ui-plan.md#15-ต้องดึง-รวม-ยังไม่มีค่าจริง--ห้ามเดา)** |
| Preview modal (HP-05) | เปิดเป็น popup จากหน้า Upload · wind slider เปลี่ยนค่า → resolver ถูกเรียกด้วยค่าที่ถูก · **read-only: ไม่มี API call ใด ๆ ถูกยิงตอน simulate** (assert mock fetch = 0 ครั้ง) |
| Delete dialog (HP-07) | ต้องพิมพ์ชื่อ object จึงกดยืนยันได้ · แสดงจำนวน workspace/map ที่กระทบ · ปิด dialog = ไม่มี request |
| Replace spritesheet dialog (EC-01) | ยืนยัน **ก่อน** เปิด file picker · Cancel = ไม่แตะไฟล์เดิม |
| Filter / category dropdown (HP-01) | มี `Nature` เป็น category · filter ส่ง `types=nature` ไป API |

---

## 5. E2E (Playwright, `zyra-app/e2e/`)

| Scenario | Flow ที่ต้องเดินจบ |
|---|---|
| HP-01 | login admin → Object Management → filter Nature → เห็น card + badge + state count |
| HP-02 | สร้าง object type=nature → บันทึก → object โผล่ในลิสต์ พร้อม nature_type ที่เลือก |
| HP-03 | เปิด Upload modal → upload PNG ถูกต้อง → บันทึก → state แสดงว่า uploaded แล้ว |
| HP-05 | เปิด Preview popup → ลาก wind slider → animation/label เปลี่ยน → ปิด popup แล้วไม่มีอะไรถูกบันทึก |
| HP-06 | แก้ชื่อ/grid → บันทึก → ค่าเปลี่ยน · nature_type เป็น read-only เมื่อมี animation แล้ว |
| HP-07 | Hide → หายจาก library ของ member · Delete → พิมพ์ชื่อยืนยัน → หายจากลิสต์ |
| EP-01 | upload JPEG → toast "Only PNG…" · ไฟล์ > 2MB → toast ขนาด · frame_count ที่หารไม่ลงตัว → toast width |
| EC-01 | replace sprite ของ object ที่วางบน map → ยืนยัน modal → Virtual Office ที่เปิดค้างอยู่โหลด sprite ใหม่ (ผ่าน ws event) |

> EC-01 ต้องรัน `zyra-ws` จริงในสภาพ E2E (2 browser context: admin แก้ + member ที่อยู่ใน VO) — ถ้า infra E2E ยังไม่รองรับ ให้ลดเหลือ integration test ระดับ ws client แล้ว **เขียนไว้ตรง ๆ ว่ายังไม่ได้เทสจริงบน browser** ห้ามเคลมว่าผ่าน

---

## 6. Regression — ของเดิมต้องไม่พัง

Feature นี้แก้ enum และ query ที่ object type เดิมทั้ง 9 ตัวใช้ร่วมกัน:

| Test | Expected |
|---|---|
| object type เดิมทั้ง 9 ยังสร้าง/แก้/ลบได้ | ไม่มี validation ใหม่หลุดไปบังคับกับ type อื่น |
| `object_compositions` flow เดิมของ furniture/sofa | ไม่เปลี่ยน |
| `GET /api/objects/all` (member, UserGuard) | คืน nature object ที่ active ด้วย — และ **ไม่คืน** hidden/deleted |
| **Delete/Hide ไม่ทำให้ placement เดิมหาย** (contract ZYR-1088) | `__tests__/tile-builder-hidden-objects.test.ts` ต้องยังเขียว — **ตัดสินแล้ว 2026-09-17: ใช้ behaviour เดิม (ตัวเลือก a)** ดู [technical-design §10 ข้อ 5](technical-design.md#10-open-items-ที่ยังไม่ตัดสินใจ-ต้องถาม-pmยืนยันก่อน-implement-จริง) |
| **Delete แล้ว render กับ collision ต้องตรงกัน** (คำถามหลักของ HP-07) | soft delete object ที่ยังถูกวาง → `buildDbTiles` ยังวาด **และ** `obstacle_grid_builder` ยังคืน obstacle cell ชุดเดิม — **ห้ามมีฝั่งใดฝั่งหนึ่งหาย** (ล่องหนแต่ชน / เห็นแต่ทะลุ) |
| `ListAllActiveObjects` ยังคืน object ที่ soft-deleted แต่มี placement | `object_service.go:627-628` — ถ้าเผลอเพิ่ม filter `is_deleted` ทุก placement ของ object นั้นจะหายทันที |
| Nature ไม่เพิ่ม obstacle cell เลย | ไม่มีแถว `object_compositions` → obstacle grid ว่างสำหรับ nature ทุกตัว ทั้งก่อนและหลัง delete |
| **ห้ามลบ S3 asset ขณะยังมี placement** | ถ้ามีใครเพิ่ม cleanup job ในอนาคต ต้อง assert ว่าลบเฉพาะ `is_deleted = true` **และ** placement count = 0 (กัน "ภาพแตกแต่ยังชน") |
| `obstacle_grid_builder` + `tile-builder.ts` | object ที่ไม่มี composition ยัง walkable เหมือนเดิม (`__tests__/tile-builder-hidden-objects.test.ts` ต้องยังเขียว) |
| `npx tsc --noEmit` + `npm run lint` + `go test ./...` | เขียวทั้งหมดก่อนเปิด PR ([05-review.md](../../../.claude/rules/05-review.md)) |

---

## 7. Manual QA checklist — ใช้กับกฎ 80% ก่อน mark Completed

เช็กลิสต์นี้คือตัวที่กฎทีม "ก่อนปรับ Comp ต้องเทส ≥ 80%" หมายถึง (Comp = **Completed** ใน ClickUp ไม่ใช่ component) — เดินให้ครบก่อนขอเปลี่ยนสถานะ · **AI ไม่เปลี่ยน status ให้ ([13-clickup-status.md](../../../.claude/rules/13-clickup-status.md))**

| # | เคส | Scenario | ผ่าน? |
|---|---|---|---|
| 1 | Nature โผล่ใน category filter + dropdown | HP-01 | ☐ |
| 2 | Card แสดง badge + state count ถูกต้อง | HP-01 | ☐ |
| 3 | สร้าง object ครบทุก nature_type ที่ตกลงกันได้ | HP-02 | ☐ |
| 4 | ชื่อซ้ำ → error · ชื่อยาวเกิน limit → error | HP-02 | ☐ |
| 5 | Upload modal เปิดจากปุ่ม Upload (ไม่ใช่หน้าแยก) | HP-03 | ☐ |
| 6 | Upload ครบ required → ตั้ง Active ได้ · ไม่ครบ → ตั้งไม่ได้ | HP-03 | ☐ |
| 7 | Preview popup เปิดจากหน้า Upload | HP-05 | ☐ |
| 8 | Preview fallback เป็น idle เมื่อ state นั้นยังไม่ upload | HP-05 | ☐ |
| 9 | Preview ไม่บันทึกอะไรลง production | HP-05 | ☐ |
| 10 | แก้ชื่อ/grid/z-index/status ได้ | HP-06 | ☐ |
| 11 | nature_type ล็อกเมื่อมี animation แล้ว · ปลดล็อกเมื่อยังไม่มี | HP-06 | ☐ |
| 12 | Hide → member ไม่เห็นใน library · map เดิมยังแสดง | HP-07 | ☐ |
| 13 | Delete → พิมพ์ชื่อยืนยัน → หายจาก palette (**ของที่วางบน map แล้วยังอยู่ ตามตัวเลือก a**) | HP-07 | ☐ |
| 13b | หลัง delete: เดินเข้าหา object ที่วางไว้แล้ว — **เห็นภาพและชน/ไม่ชน ตรงกับก่อน delete เป๊ะ** (nature = เดินทะลุได้ทั้งก่อนและหลัง) | HP-07 | ☐ |
| 14 | EP-01 error ครบ 6 เคส ข้อความตรงที่ตกลง | EP-01 | ☐ |
| 15 | Replace sprite → modal ยืนยันแสดงจำนวน workspace/map จริง | EC-01 | ☐ |
| 16 | Member ที่อยู่ใน VO เห็น sprite ใหม่โดยไม่ต้อง refresh | EC-01 | ☐ |
| 17 | Nature เดินทะลุได้เสมอใน VO (ไม่บล็อกทาง) | ทุก scenario | ☐ |
| 18 | ไม่มี `console.log` / secret / PII ใน log ที่เพิ่มใหม่ | — | ☐ |

---

## 8. Definition of Done ของ test

- [ ] Go: `go test ./...` เขียว · coverage `internal/service` ส่วน nature/animation ≥ 80%
- [ ] TS: `vitest run` เขียว · coverage ของไฟล์ที่ระบุใน Coverage Targets ≥ 80% (ต้องเพิ่มไฟล์เหล่านี้เข้า `coverage.include` ใน `vitest.config.ts` — ปัจจุบัน scope อยู่แค่ chat)
- [ ] ทุก sentinel error ใหม่มีเทสอย่างน้อย 1 เคส
- [ ] ไม่มีเทสไหน hardcode รายชื่อ required state / ชื่อ key state ที่ยังไม่เคาะ (§0)
- [ ] E2E ครบ 8 scenario หรือระบุชัดว่าตัวไหนยังไม่ได้รันจริง **พร้อมเหตุผล** ([16-documentation.md](../../../.claude/rules/16-documentation.md) — ห้ามเขียนว่า verified ถ้าไม่ได้เทสจริง)
- [ ] บันทึกผลรอบนั้นลง [progress.md](progress.md) แยก "build เขียว" ออกจาก "live-test ผ่าน"

---

## 9. Traceability — Scenario → Test

| Scenario | Go unit | TS unit | Component | E2E |
|---|---|---|---|---|
| HP-01 | §1.2 list/filter | §3.1 | Tree card, filter | ✅ |
| HP-02 | §1.1, §1.2 create | §3.1 | — | ✅ |
| HP-03 | §1.3 ทั้งหมด | §3.3 | Upload modal | ✅ |
| HP-05 | — (client-only) | §3.4 | Preview modal | ✅ |
| HP-06 | §1.2 update/lock | §3.1 | — | ✅ |
| HP-07 | §1.2 delete | — | Delete dialog | ✅ |
| EP-01 | §1.3, §2 error format | §3.1 error | Upload modal toast | ✅ |
| EC-01 | §1.5, §1.6 | §3.5 | Replace dialog | ⚠️ ต้องมี ws จริง |
| ~~HP-04~~ | descoped — **ไม่เขียนเทส** | | | |
