# SC-OBJ-NAT-01 · Technical Design — Nature Object Management (Admin)

> **สถานะ:** design เท่านั้น ยังไม่ implement · **วันที่:** 2026-09-16
> อ่าน [spec.md](spec.md) ก่อน — naming ยืนยันแล้ว: ใช้ `shedding_tree` / `falling` (ไม่ใช่ `sakura_tree` / `petal_fall`)
> ยึดตามของที่มีอยู่จริงในโค้ดที่ตรวจแล้ว (2026-09-16): `zyra-api/internal/model/object.go`, `internal/service/object_service.go`, `internal/handler/object_handler.go`, migration ล่าสุด = **102** (ถัดไปในไฟล์นี้ = **103**), `zyra-app/lib/api/objects.ts`, `zyra-app/views/admin/object-management/`, `zyra-engine/assets/tile-builder.ts`, `zyra-engine/pixi-game/scene.ts`, `zyra-api/internal/service/obstacle_grid_builder.go`, `zyra-api/internal/cache/zone_events.go`, `zyra-ws/internal/hub/message.go` + `zoneclaims.go`
> **⚠️ อัปเดต 2026-09-16 หลังถอด Figma ([ux-ui-plan.md](ux-ui-plan.md)):** design ขัดกับ spec ที่เอกสารนี้ยึดอยู่หลายจุด — **required state = `idle` ตัวเดียว** (ไม่ใช่ 3 state ตาม §4), state ที่ 3 ชื่อ **"Sway normal"** ไม่ใช่ `sway_strong`, **ไม่มีช่องกรอก frame_count/frame_rate** (§5.2 รับ required ไม่ได้), **Status default = Active** (gating §6.4 ต้องย้ายไปที่ Save), ไม่มี `custom` nature_type, Delete พิมพ์ชื่อทั้ง 2 เงื่อนไข · รายการที่ต้องแก้ในเอกสารนี้อยู่ที่ [ux-ui-plan §16](ux-ui-plan.md#16-สิ่งที่ต้องกลับไปแก้ใน-technical-designmd-หลังเห็น-figma) — **ยังไม่ได้แก้ตัว design ด้านล่างจนกว่า PM จะเคาะว่า Figma หรือ spec ชนะ**
> **🔄 ClickUp รอบที่ 2 (2026-09-16 ~11:09):** PM **ถอด HP-04 ออกจากตาราง Subtasks** = descoped → field `wind_threshold_kmh` / `base_intensity_multiplier` ใน §2.2 คงไว้เป็น server default ได้ แต่ **ไม่มี UI แก้** · HP-03 AC ใหม่ **"หลังบันทึกสามารถกำหนดสีและประเภทของ box object ได้"** — ถ้า "ประเภท" = hitbox blocked/walkable **จะล้ม §3** (ที่ออกแบบว่า Nature ไม่มี `object_compositions` row เพื่อให้ walkable อัตโนมัติ) → ต้องเคาะกับ PM ก่อนทำ migration · HP-03 ระบุแล้วว่า Upload เป็น **modal** (ไม่มี route แยก — ตรง §5.2 ที่เป็น sub-resource ของ object เดิม) · รายละเอียดใน [spec.md §รอบที่ 2](spec.md#รอบที่-2--2026-09-16-pm-update-clickup)
> **⚠️ เรื่องสถานะ HP-04:** ผู้ใช้ยืนยันแล้วว่า ClickUp ปิด HP-04 ถูกต้อง — แต่จากการตรวจโค้ดจริงรอบนี้ **ยังไม่มี table/field ใดๆ ที่รองรับ animation config ของ Object เลย** (ไม่มี `tb_object_animation` หรือเทียบเท่า มีแต่ precedent ที่คล้ายกันคือ `tb_pet_animation` ของ Pet) เข้าใจว่า "ปิดถูกต้อง" หมายถึง requirement/scope เคลียร์แล้วใน ClickUp ไม่ใช่ว่ามีโค้ดรองรับแล้ว — technical design นี้จึงออกแบบ+สร้างทุกอย่างใน HP-03/HP-04 ตั้งแต่ต้น ไม่ใช่แค่ verify ของเดิม
> **🔄 ClickUp รอบที่ 3 (2026-09-17 ~10:36):** ทุก task เปลี่ยน status `pending` → **`in progress`** (HP-04 ยัง Closed) แต่ **description ไม่เปลี่ยนแม้แต่ตัวเดียว และไม่มี comment ใหม่** → **open items §10 และข้อขัดแย้ง [ux-ui-plan §14.1](ux-ui-plan.md#141-ต้องตัดสินก่อนเริ่มโค้ด-กระทบ-schema--api--flow) ยังไม่ถูกตอบทั้งหมด** — เอกสารนี้จึง **ยังไม่แก้ design ด้านล่าง** · test coverage ที่ต้องมีคู่กับ design นี้อยู่ที่ [test-plan.md](test-plan.md) (เขียนแบบไม่ล็อกค่าที่ยังไม่เคาะ) · ดู [spec.md §รอบที่ 3](spec.md#รอบที่-3--2026-09-17-status-เปลี่ยนเป็น-in-progress)

---

## 1. ของเดิมที่มีอยู่แล้ว (ต้องต่อยอด ไม่ใช่สร้างใหม่)

| ส่วน | ที่อยู่ | สรุป |
|---|---|---|
| ตาราง object หลัก | `tb_object` (migration `10`, ต่อเติมถึง `70`) | `id, name, type VARCHAR(50), grid_width, grid_height, tint_colors[], thumbnail_url, sprite_url, z_index, status, is_deleted, deleted_at, created_at, updated_at` — `type` **ไม่มี DB CHECK** validate ที่ Go layer เท่านั้น (`model.IsValidObjectType`) |
| Object type enum ปัจจุบัน | `internal/model/object.go:6-14` | `furniture, decoration, structure, sofa, walkable_group, interactive_barrier, wall, machine, foods_and_drink` |
| Composition (piece/hitbox) | ตาราง `object_compositions` (1:1 กับ `tb_object`, migration `15`) | เก็บ `ObjectFileStore{Variants[].Directions[dir]{Pieces[], Hitbox, HitboxCells[], SitPoints[]}}` — ใช้กับ object ที่ประกอบจาก piece หลายชิ้นต่อทิศทาง |
| Soft delete | migration `16` + `70` | `is_deleted/deleted_at` + partial unique index บนชื่อ (`WHERE is_deleted IS NOT TRUE`) — **hard delete ไม่เคยเกิดจริง** แม้ FK จะเป็น `ON DELETE CASCADE` |
| Service layer | `internal/service/object_service.go` (1131 บรรทัด) | `NewObjectService(db, s3)`, tx pattern (`BeginTx`+`defer Rollback`), sentinel errors (`ErrObjectNotFound`, `ErrObjectNameTaken`, `ErrInvalidPNG`, `ErrFileTooLarge`, ...), `UploadPiece`/`UploadThumbnail` (S3 key `static/object/{id}/{name}.png`, magic-byte check `pngMagicBytes`, `maxSpriteSize=1MB`, `maxSpriteDimension=512`) |
| Response envelope | `model.ObjectListResponse` / `model.ObjectDetailResponse` (**ไม่ใช่** `model.APIResponse` — อันนั้นเป็นของ auth เท่านั้น) | `{Status, Message, Data}` — endpoint ใหม่ของ Nature ต้อง match รูปแบบนี้ |
| Routes | `internal/router/router.go` | `GET/POST /api/admin/objects`, `GET/PUT/DELETE /api/admin/objects/:id`, `GET /:id/usage`, `POST /pieces`, `POST /thumbnail` (AdminGuard) · `GET /api/objects`, `GET /api/objects/all` (UserGuard) |
| Placed objects | `tb_map_object` (migration `17`+) | `map_id, object_id, tile_x/y (float64), grid_width/height, facing, variant_index, wall_mounted` — ไม่มี refetch/broadcast ใดๆ เมื่อ catalog object (`tb_object`) ถูกแก้ที่ต้นทาง |
| Frontend views | `zyra-app/views/admin/object-management/components/` | `object-list-panel`, `object-card`, `object-detail-panel`, `object-add-form`, `object-composer` (Konva), `object-type-badge.tsx` (`TYPE_CONFIG` map สี/label ต่อ type), `object-status-badge.tsx`, `object-tint-swatches.tsx` |
| Frontend API layer | `zyra-app/lib/api/objects.ts` | `listObjects/getObject/createObject/updateObject/deleteObject/getObjectUsage/uploadPiece/uploadThumbnail` — ทุกตัวยิง `/api/admin/objects*` ผ่าน `authFetch`/`authFetchForm` |
| Precedent: animated spritesheet + frame config | `tb_pet_animation` (migration `83`, ต่อเติม `84/95`) + `internal/model/pet.go` | **ต้นแบบตรงที่สุด** สำหรับ Nature — `frame_count CHECK 1-64`, `frame_rate CHECK 4-24`, `frame_width/height`, ค่าคงที่ `PetFrameCountMin/Max`, `PetFrameRateMin/Max` |
| Realtime broadcast (มีอยู่แล้ว แต่ "catalog object" ไม่เคยใช้) | `internal/cache/zone_events.go` (`ZoneEventPublisher.PublishZoneEvent(ctx, workspaceID, msgType, payload)` → Redis `vo:zone`) + `zyra-ws/internal/hub/message.go` (allowlist `Msg*`) + `zoneclaims.go` (`BroadcastZoneEvent`, relay-only switch) | ใช้กับ zone claim / Zone Editor placement / pet / environment เท่านั้น — **`object_handler.go`/`object_service.go` ไม่เคยเรียก `PublishZoneEvent` เลย (grep ยืนยัน 0 matches)** ต้องสร้างใหม่ทั้งเส้นสำหรับ Nature |
| Walkable/collision pattern | `obstacle_grid_builder.go:57-64` (server) + `tile-builder.ts:102-114` (client) | **ไม่มี boolean `walkable` column** — เดินได้/ไม่ได้มาจาก `HitboxCell.Type` ใน composition เท่านั้น ดู [§3](#3-เหตุผลที่-nature-เดินได้เสมอโดยไม่ต้องเขียนโค้ดเพิ่ม) |

---

## 2. Schema ใหม่

### 2.1 `tb_object` — เพิ่ม `nature_type`

```sql
-- 103_object_nature.sql
ALTER TABLE tb_object ADD COLUMN IF NOT EXISTS nature_type VARCHAR(30) DEFAULT NULL;

COMMENT ON COLUMN tb_object.nature_type IS
  'sub-type เมื่อ tb_object.type = ''nature'' เท่านั้น: big_tree|pine_tree|bush|shedding_tree|bamboo|flower_bush|custom — ไม่มี DB CHECK ตั้งใจ (เหมือน type เอง) validate ที่ Go layer เพื่อรองรับ custom ในอนาคตโดยไม่ต้อง migration ใหม่';

CREATE INDEX IF NOT EXISTS idx_object_nature_type ON tb_object (nature_type) WHERE nature_type IS NOT NULL;
```

```sql
-- 103_object_nature.down.sql
DROP INDEX IF EXISTS idx_object_nature_type;
ALTER TABLE tb_object DROP COLUMN IF EXISTS nature_type;
```

`type = 'nature'` เป็นค่าที่ 10 ของ enum เดิม (`furniture, decoration, structure, sofa, walkable_group, interactive_barrier, wall, machine, foods_and_drink`) — เพิ่มใน Go/TS เท่านั้น ไม่ต้องแตะ DB เพราะคอลัมน์เป็น `VARCHAR(50)` ไม่มี CHECK อยู่แล้ว

### 2.2 `tb_object_animation` — ตารางใหม่ (ต้นแบบจาก `tb_pet_animation`)

```sql
-- ต่อจาก 103_object_nature.sql ไฟล์เดียวกัน (หรือแยกเป็น 104_object_animation.sql ก็ได้ — แนะนำแยก
-- เพื่อ rollback อิสระจากกัน)
CREATE TABLE IF NOT EXISTS tb_object_animation (
    id                       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    object_id                UUID         NOT NULL REFERENCES tb_object(id) ON DELETE CASCADE,
    state                    VARCHAR(30)  NOT NULL,  -- idle|sway_light|sway_strong|falling|<custom slug>
    sprite_url               TEXT         NOT NULL,
    frame_count              INTEGER      NOT NULL CHECK (frame_count BETWEEN 1 AND 64),
    frame_rate               INTEGER      NOT NULL CHECK (frame_rate BETWEEN 4 AND 24),
    frame_width              INTEGER      NOT NULL CHECK (frame_width > 0),
    frame_height             INTEGER      NOT NULL CHECK (frame_height > 0),
    wind_threshold_kmh       INTEGER      NOT NULL DEFAULT 0 CHECK (wind_threshold_kmh BETWEEN 0 AND 200),
    base_intensity_multiplier NUMERIC(3,2) NOT NULL DEFAULT 1.0 CHECK (base_intensity_multiplier BETWEEN 0.1 AND 5.0),
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (object_id, state)
);

CREATE INDEX IF NOT EXISTS idx_object_animation_object ON tb_object_animation (object_id);
```

```sql
-- .down.sql
DROP TABLE IF EXISTS tb_object_animation;
```

**หมายเหตุ:** `state` ไม่ใส่ `CHECK (... IN (...))` แบบ `tb_pet_animation.slot` เพราะ `nature_type = 'custom'` ต้องรับ state ที่ Admin ตั้งชื่อเองได้ (ClickUp: "Admin กำหนด") — validate รายชื่อที่อนุญาตที่ Go layer แทน โดยแยก 2 เคส: nature_type คงที่ (6 แบบ) → เช็คกับ whitelist ต่อ type, nature_type = 'custom' → รับ slug ใดก็ได้ที่ผ่าน regex `^[a-z][a-z0-9_]{1,29}$`

`base_intensity_multiplier` ใช้ `NUMERIC(3,2)` (0.10–5.00) ตรงกับ spec "decimal" ของ HP-04 ตรงตัว

### 2.3 ทำไมไม่ต้องมี object_compositions row สำหรับ Nature

ดู [§3](#3-เหตุผลที่-nature-เดินได้เสมอโดยไม่ต้องเขียนโค้ดเพิ่ม) — Nature object **ไม่ insert แถวใน `object_compositions` เลย** เพราะไม่มี piece/hitbox แบบ furniture ปกติ ระบบเดิมทั้งฝั่ง server และ client already default เป็น walkable เมื่อไม่มี composition data

---

## 3. Nature เดินได้เสมอ — ใช้กลไก collision เดิม (ตัดสินแล้ว 2026-09-17)

> **🔄 เขียนใหม่ 2026-09-17** — ฉบับก่อนสรุปว่า "Nature ไม่ insert แถว `object_compositions` เลย" ซึ่ง**ผิด** เพราะฟอร์มเดิมสร้าง composition ให้ทุก object ยกเว้น wall · ผู้ใช้ตัดสินว่า **ใช้ของเดิมที่มีอยู่แล้ว** ทั้ง toolbar สี และ blocked/walkable → Nature เดินเส้นทางเดียวกับ `decoration` เป๊ะ

### 3.1 กลไกที่มีอยู่แล้วและใช้ได้เลย

**collision default ต่อ object type** — `zyra-app/views/admin/object-management/constants.ts:90`

```ts
export const deriveCollisionModeFromType = (type: ObjectType | ""): CollisionMode => {
  if (type === "walkable_group" || type === "decoration" ||
      type === "machine" || type === "foods_and_drink") {
    return "walkable"
  }
  return "blocked"
}
```

**สิ่งที่ต้องทำสำหรับ Nature = เพิ่ม `type === "nature"` เข้าเงื่อนไขนี้ 1 บรรทัด** ไม่ต้องมี boolean `is_walkable` ใหม่ ไม่ต้องแก้ `obstacle_grid_builder.go` / `tile-builder.ts` และไม่ต้องมี branch พิเศษที่ service

**Toolbar บน Object Preview ใช้ของเดิมทั้งชุด** (`object-preview-canvas.tsx`, ถูกเรียกจาก `object-add-form.tsx:1366` = ฟอร์มเดียวกับที่ Nature reuse):

| ปุ่ม | โค้ด | ผลต่อ Nature |
|---|---|---|
| 🎨 สี | `:947` → `ColorPickerPopup` (`PRESET_COLORS` 13 สี + custom hex) | **piece tag colour** — สีป้ายกำกับในแถว `Object files` ไม่ลง DB ไม่กระทบ gameplay → ปล่อยไว้ได้ ตอบ AC "กำหนดสี…ของ box object" |
| 🖌 ประเภท box | `:995-1090` brush + dropdown `blocked`/`walkable` | ตอบ AC "…และประเภทของ box object" — default มาจาก `deriveCollisionModeFromType` |
| 🧽 ยางลบ | `:1093` | ของเดิม ไม่ต้องแตะ |

→ **[ux-ui-plan §14.1 ข้อ 14a ปิดแล้ว**: "walkable เสมอ" = **default ของ type** ไม่ใช่การล็อกไม่ให้แก้ (เหมือน `decoration` ที่ default walkable แต่ admin ปรับได้ถ้าจำเป็น) จึงไม่ขัดกับ AC ที่ให้กำหนดสี/ประเภท box ได้

### 3.2 ⚠️ บั๊กที่ต้องแก้ก่อน ไม่งั้น default walkable ไม่เกิดจริง

`deriveCollisionModeFromType` ตั้งแค่ **โหมดพู่กัน** — cells ที่บันทึกจริงมาจาก `buildCellsFromHitbox` ซึ่ง **hardcode `type: "blocked"`** ทั้ง 2 ที่ (`constants.ts:119` ตัวที่ใช้ตอน save · `object-preview-canvas.tsx:438` ตัวที่ใช้วาด) และ `applyFootprintToComposition` (`constants.ts:158-183`) จะใช้ fallback ชุดนี้เมื่อ direction ยังไม่มี cells ที่ระบายไว้

**ผล:** สร้าง Nature แล้วไม่ระบายเอง → save เป็น **blocked เต็มรอยเท้า = ต้นไม้กันทาง** ตรงข้ามกับ spec · กระทบ `decoration`/`machine`/`foods_and_drink` ด้วยเงื่อนไขเดียวกัน

**แก้ที่จุดเดียว** — ให้ fallback cells ใช้ collision mode แทน hardcode:
```ts
export const buildCellsFromHitbox = (
  hitbox: PieceHitbox,
  mode: CollisionMode = "blocked",   // default เดิม → call site เก่าไม่เปลี่ยนพฤติกรรม
): HitboxCell[] => { /* ... type: mode ... */ }
```
รายละเอียด + วิธีวัดผลกระทบกับข้อมูลจริง: [`issues/object-hitbox-default-collision-mode-2026-09-17.md`](../../issues/object-hitbox-default-collision-mode-2026-09-17.md) — **เป็น prerequisite ของ HP-02** ต้องแก้ก่อนหรือพร้อมกัน

### 3.3 Safety net ที่ยังคงอยู่ (ถ้า object ไม่มี composition จริง ๆ)

ถ้าด้วยเหตุใดก็ตาม Nature ถูกสร้างโดยไม่มีแถว `object_compositions` ระบบยัง treat เป็น walkable ให้เองทั้งสองฝั่ง — ไม่ crash ไม่กลายเป็นกำแพง:

- **Server** `obstacle_grid_builder.go:57-64` — `resolveHitboxCells` คืน `nil` เมื่อ `composition` เป็น NULL (มาจาก `LEFT JOIN` ที่ `:245-250`) → ไม่ block cell ไหนเลย
- **Client** `zyra-engine/assets/tile-builder.ts:102-114` — `hasBlockingFootprint(undefined)` → `false` → `passable = true`

ใช้เป็น **fallback ไม่ใช่ design หลัก** — design หลักคือ §3.1

---

## 4. Nature Type → Required/Optional States (shared constant)

ต้องประกาศ map เดียวกัน 2 ที่ (Go + TS) เหมือนที่ `TYPE_CONFIG`/`OBJECT_TYPES` ทำอยู่แล้วสำหรับ object type ปกติ:

```go
// internal/model/object.go (เพิ่มใหม่)
const (
    NatureTypeBigTree     = "big_tree"
    NatureTypePineTree    = "pine_tree"
    NatureTypeBush        = "bush"
    NatureTypeSheddingTree = "shedding_tree"
    NatureTypeBamboo      = "bamboo"
    NatureTypeFlowerBush  = "flower_bush"
    NatureTypeCustom      = "custom"

    AnimStateIdle       = "idle"
    AnimStateSwayLight  = "sway_light"
    AnimStateSwayStrong = "sway_strong"
    AnimStateFalling    = "falling"
)

// NatureRequiredStates / NatureOptionalStates: nil slice ของ nature_type == "custom"
// แปลว่า "ไม่มี required list ตายตัว — Admin เพิ่มเองได้ทุก state" (ดู §6.3)
var NatureRequiredStates = map[string][]string{
    NatureTypeBigTree:      {AnimStateIdle, AnimStateSwayLight, AnimStateSwayStrong},
    NatureTypePineTree:     {AnimStateIdle, AnimStateSwayLight, AnimStateSwayStrong},
    NatureTypeBush:         {AnimStateIdle, AnimStateSwayLight},
    NatureTypeSheddingTree: {AnimStateIdle, AnimStateSwayLight, AnimStateSwayStrong},
    NatureTypeBamboo:       {AnimStateIdle, AnimStateSwayLight, AnimStateSwayStrong},
    NatureTypeFlowerBush:   {AnimStateIdle, AnimStateSwayLight},
    NatureTypeCustom:       nil,
}

var NatureOptionalStates = map[string][]string{
    NatureTypeSheddingTree: {AnimStateFalling},
}
```

```ts
// zyra-app/lib/api/objects.ts (เพิ่มใหม่ — 1:1 กับ Go ด้านบน)
export type NatureType =
  | "big_tree" | "pine_tree" | "bush" | "shedding_tree" | "bamboo" | "flower_bush" | "custom"
export type AnimationState = "idle" | "sway_light" | "sway_strong" | "falling" | (string & {})

export const NATURE_REQUIRED_STATES: Record<NatureType, AnimationState[]> = {
  big_tree: ["idle", "sway_light", "sway_strong"],
  pine_tree: ["idle", "sway_light", "sway_strong"],
  bush: ["idle", "sway_light"],
  shedding_tree: ["idle", "sway_light", "sway_strong"],
  bamboo: ["idle", "sway_light", "sway_strong"],
  flower_bush: ["idle", "sway_light"],
  custom: [],
}
export const NATURE_OPTIONAL_STATES: Partial<Record<NatureType, AnimationState[]>> = {
  shedding_tree: ["falling"],
}
```

Grid size ต่อ nature_type (จาก spec.md) เป็น **default เริ่มต้นตอนสร้าง** ไม่ใช่ constraint ตายตัว (spec HP-02 ให้ Admin ปรับ grid_width/height เองได้อยู่แล้วเหมือน object ทั่วไป):

| nature_type | grid_width × grid_height default |
|---|---|
| big_tree | 3 × 4 |
| pine_tree | 2 × 3 |
| bush | 1 × 1 |
| shedding_tree | 2 × 3 |
| bamboo | 1 × 3 |
| flower_bush | 1 × 1 |
| custom | 1 × 1 (Admin ปรับเอง) |

---

## 5. API Contract

### 5.1 Object CRUD เดิม — ขยาย ไม่สร้างใหม่

`POST /api/admin/objects` และ `PUT /api/admin/objects/:id` (multipart, เหมือนเดิมทุกอย่าง) รับ field เพิ่ม 1 ตัว:

| Field | เดิม/ใหม่ | หมายเหตุ |
|---|---|---|
| `type=nature` | ใช้ enum เดิม เพิ่มค่า | ต้องเพิ่มใน `model.IsValidObjectType`/`validObjectTypes` |
| `nature_type` | **ใหม่** | required เมื่อ `type=nature`, ต้องอยู่ใน `NatureRequiredStates` key หรือ `"custom"` — ไม่ส่งมาเมื่อ type อื่น |
| `composition` / `sprites[]`/`tints[]` | เดิม | **ไม่ส่งสำหรับ Nature** (ดู §3) — validate ที่ handler: ถ้า `type=nature` และมี composition มาด้วย → reject `ErrCompositionNotAllowedForNature` |
| `status` | เดิม | มี gate เพิ่ม: `status=active` ถูก reject ด้วย `ErrRequiredAnimationStatesIncomplete` ถ้า nature_type ที่ไม่ใช่ custom ยังขาด required state (ดู §6.4) |

HP-06 AC "Category, nature_type เปลี่ยนไม่ได้หลังสร้าง ยกเว้นยังไม่มี animation state ใดๆ" → `UpdateObject` ต้อง reject การเปลี่ยน `type`/`nature_type` ถ้า `SELECT COUNT(*) FROM tb_object_animation WHERE object_id=$1` > 0 (`ErrNatureTypeLocked`)

### 5.2 Animation sub-resource — endpoint ใหม่

```
GET  /api/admin/objects/:id/animations           → list ทุก state ที่ upload แล้ว + required/optional completeness
PUT  /api/admin/objects/:id/animations/:state     → upsert 1 state (สร้างใหม่ หรือ replace ของเดิม — ใช้ endpoint เดียวกันทั้ง HP-03/HP-04/HP-06/EC-01)
```

ตั้งใจไม่มี `DELETE /:id/animations/:state` — ไม่มีอยู่ใน scenario ใดของ spec (ตาม [14-no-overreach.md](../../../.claude/rules/14-no-overreach.md)) ถ้าต้องการค่อยเพิ่มทีหลังเป็น task แยก

**`PUT /:id/animations/:state`** (multipart, เพราะมีไฟล์ — เหมือน pattern `uploadPiece`):

| Field | Required | Validate |
|---|---|---|
| `file` | เฉพาะตอนอัปโหลด/แทนที่สไปรต์ใหม่ (ไม่บังคับถ้าแก้แค่ config — HP-04 เคสไม่มีไฟล์ใหม่) | PNG magic bytes, ≤ 2MB (`maxNatureSpritesheetSize`, **แยกจาก `maxSpriteSize` เดิมที่ 1MB**) · dimension ≤ 1000px ตาม [§5.2.1](#521--interim-2026-09-17--รับสไปรต์ขนาดใหญ่ถึง-1000px-ระหว่างที่-asset-ยังไม่เสร็จ) |
| `frame_count` | ใช่ | 1–64, `image_width % frame_count == 0` (คำนวณจาก `image.DecodeConfig` เหมือน `UploadPiece` เดิม) |
| `frame_rate` | ใช่ | 4–24 |
| `wind_threshold_kmh` | ไม่ (default 0) | 0–200 |
| `base_intensity_multiplier` | ไม่ (default 1.0) | 0.1–5.0, ต้องเพิ่ม `parseFloatFormValue` helper (ของเดิมมีแต่ `parseIntFormValue`) |

Response: `model.ObjectAnimationResponse{Status, Message, Data *ObjectAnimation}` (envelope pattern เดิม)

ตัวอย่าง response ของ `GET /:id/animations`:
```json
{
  "status": 200,
  "message": "success",
  "data": {
    "nature_type": "shedding_tree",
    "required_states": ["idle", "sway_light", "sway_strong"],
    "optional_states": ["falling"],
    "completed_required": ["idle", "sway_light"],
    "is_active_eligible": false,
    "animations": [
      { "state": "idle", "sprite_url": "https://.../animations/idle.png?v=1789...",
        "frame_count": 8, "frame_rate": 12, "wind_threshold_kmh": 0, "base_intensity_multiplier": 1.0 },
      { "state": "sway_light", "sprite_url": "...", "frame_count": 6, "frame_rate": 10,
        "wind_threshold_kmh": 10, "base_intensity_multiplier": 1.0 }
    ]
  }
}
```

#### 5.2.1 ⏳ Interim (2026-09-17) — รับสไปรต์ขนาดใหญ่ถึง 1000px ระหว่างที่ asset ยังไม่เสร็จ

**สถานการณ์:** คนที่ทำ spritesheet ยังทำไม่เสร็จ → ต้องให้ Admin upload ภาพชั่วคราวได้ก่อน (เช่น ภาพนิ่ง 1000×1000) โดย**ไม่เปลี่ยน flow และไม่เปลี่ยน schema**

**สิ่งที่เปลี่ยน — 2 อย่างเท่านั้น:**

| เรื่อง | ค่าเดิม | Interim | เหตุผล |
|---|---|---|---|
| Dimension cap ของ animation upload | `maxSpriteDimension = 512` (`object_service.go:29`, บังคับที่ `:1011`) | **`maxNatureSpriteDimension = 1000`** (ค่าใหม่แยกตัว **ห้ามแก้ 512 ของเดิม** เพราะ piece/thumbnail ของ object type อื่นใช้อยู่) | 1000×1000 ติด cap เดิมแน่นอน |
| File size cap | 2MB (`maxNatureSpritesheetSize`) | คงไว้ 2MB ก่อน | PNG 1000×1000 โปร่งใสที่รายละเอียดเยอะ **มีสิทธิ์เกิน 2MB** → ถ้าเจอจริงค่อยขยับ แล้วบันทึกที่นี่ |

**สิ่งที่ไม่ต้องเปลี่ยนเลย:**

- **ยังเป็น horizontal strip เหมือนเดิม** — `frame_count` 1–64 ตามเดิม · ภาพนิ่ง 1 รูป = `frame_count = 1` ซึ่ง `image_width % 1 == 0` **ผ่าน validator ที่ออกแบบไว้อยู่แล้ว** ไม่ต้องมี branch พิเศษ ไม่ต้องมี flag "static mode"
- Schema, endpoint, S3 key, response envelope — เหมือนเดิมทุกอย่าง
- พอ asset จริงเสร็จ → upload strip ทับ state เดิมผ่าน `PUT /:id/animations/:state` ที่มีอยู่ **ไม่ต้อง migrate data**

**สิ่งที่ต้องระวังตอน implement:**

1. **`frame_rate` เป็น NOT NULL CHECK 4–24** → 1 เฟรมไม่มี frame rate ที่มีความหมาย ต้องเก็บ default (เช่น `12`) แล้ว **ฝั่ง render ข้าม animation loop เมื่อ `frame_count == 1`** ไม่ใช่เล่น loop 1 เฟรมที่ 12fps ทิ้งไว้ (เปลือง ticker เปล่า ๆ)
2. **Scaling บน map = `contain`** — `TILE_SIZE = 32` (`zyra-engine/constants.ts:7`) → `big_tree` 3×4 tiles = **96×128 px** แต่ภาพ interim เป็นจตุรัส 1000×1000 → **ย่อให้พอดีกรอบ `grid_width×32 × grid_height×32` โดยรักษาสัดส่วน มีช่องว่างได้ ห้ามบิดสัดส่วน** (ตัดสินแล้ว 2026-09-17) — placeholder ที่สัดส่วนยังไม่ final จะได้ไม่ดูเพี้ยน
3. ย่อ ~10 เท่าแปลว่า **เปลือง texture memory และ VRAM มาก** ถ้าวางหลายต้นในแมพเดียว — เป็นของชั่วคราวเท่านั้น **ห้ามปล่อยขึ้น prod ค้างไว้** ถ้าจะขึ้น prod ต้องมี asset จริงหรือ resize ก่อน

### 5.3 S3 key convention (ต่อยอด pattern เดิม)

```
static/object/{objectID}/animations/{state}.png
```
คู่กับของเดิม `static/object/{objectID}/thumbnail.png` และ `static/object/{objectID}/{pieceName}.png` — ใช้ `s.s3.UploadPNG(ctx, data, key)` เมธอดเดิม ไม่ต้องเพิ่มเมธอดใหม่ใน `S3Client`

### 5.4 CDN cache-busting (EC-01)

Spec บอก "URL เพิ่ม `?v={version}`" — ใช้ `updated_at` ของแถว `tb_object_animation` เป็น version (เหมือน `thumbSrc(url, updatedAt)` ที่มีอยู่แล้วใน `lib/utils.ts:16` สำหรับ thumbnail) ไม่ต้องคิด versioning scheme ใหม่:
```ts
// zyra-app — ใช้ helper เดิม ไม่สร้างใหม่
const animatedSpriteSrc = thumbSrc(animation.sprite_url, animation.updated_at)
```
S3 object เดิมถูก **overwrite ที่ key เดิม** (เหมือนพฤติกรรม thumbnail/piece เดิม) แล้วปล่อยให้ query string version เป็นตัว bust cache — ไม่ต้องสร้าง object ใหม่ทุกครั้งที่ replace

---

## 6. Sentinel errors ใหม่ (เพิ่มใน `object_service.go` ชุดเดิม)

```go
var (
    ErrInvalidNatureType                 = errors.New("invalid nature_type")
    ErrNatureTypeRequired                = errors.New("nature_type is required when type is nature")
    ErrCompositionNotAllowedForNature    = errors.New("nature objects cannot have a composition")
    ErrNatureTypeLocked                  = errors.New("nature_type cannot change after any animation state exists")
    ErrInvalidAnimationState             = errors.New("invalid animation state for this nature_type")
    ErrFrameWidthNotDivisible            = errors.New("image width is not evenly divisible by frame_count")
    ErrRequiredAnimationStatesIncomplete = errors.New("required animation states are not all uploaded yet")
)
```

Error message ที่ handler แปลงเป็น user-facing text ต้อง match ข้อความใน EP-01 เป๊ะ (ตาม spec.md §EP-01) เช่น `"Width ({W}px) ต้องหารด้วย frame_count ({N}) ลงตัว — frame width = {W/N}px"` — ต้อง format string ที่ handler ไม่ใช่ error message ดิบจาก Go (pattern เดียวกับที่ `object_handler.go` แปลง `err.Error()` เป็น message ที่ frontend แสดงอยู่แล้ว)

---

## 7. Realtime hot-reload broadcast (EC-01) — โครงสร้างใหม่ทั้งเส้น

**ยืนยันจากการตรวจโค้ด:** วันนี้ไม่มี broadcast ใดๆ เกิดขึ้นเลยเมื่อ admin แก้ catalog object (`tb_object`/`object_compositions`/animation) — ต่างจาก private-zone/pet/environment ที่มี `PublishZoneEvent` อยู่แล้ว นี่คือส่วนที่ "ใหม่ทั้งเส้น" ของ feature นี้ ไม่ใช่แค่ต่อยอด

### 7.1 zyra-api — publish หลัง commit animation

```go
// object_service.go — หลัง UpsertAnimation commit สำเร็จ
workspaceIDs, _ := s.getWorkspaceIDsUsingObject(ctx, objectID) // reuse query ของ GetObjectUsage (:551-562)
                                                                 // แค่ SELECT DISTINCT w.id แทนที่จะ join ครบ
for _, wsID := range workspaceIDs {
    _ = s.zonePublisher.PublishZoneEvent(ctx, wsID, "object_sprite_updated", map[string]any{
        "object_id": objectID,
        "state":     state,
        "version":   updatedAt.UnixMilli(),
    })
}
```
Fan-out ต่อ workspace เดียวกับที่ `GetObjectUsage` (:534-566) query อยู่แล้ว — ไม่ใช่ broadcast กระจายวงกว้าง (global) แต่ยิงเฉพาะ workspace ที่ placement จริงมี object นี้ ตรงกับ EC-01 ("ต้นมะม่วงใหญ่ถูกวางใน 15 workspaces")

### 7.2 zyra-ws — เพิ่ม allowlist entry เดียว (relay-only, ตาม pattern Environment/Pet)

```go
// internal/hub/message.go — เพิ่มใน const block เดียวกับ MsgEnvironmentChanged/MsgPetSpawned
MsgObjectSpriteUpdated = "object_sprite_updated" // broadcast: {object_id, state, version} — relay verbatim (SC-OBJ-NAT-01 EC-01)
```
```go
// internal/hub/zoneclaims.go — เพิ่ม case ใน BroadcastZoneEvent switch (:38-52)
case MsgObjectSpriteUpdated:
    // Nature sprite replaced by admin: forwarded verbatim, client refetches
    // the object catalog + busts its own texture cache. Nothing mirrored here.
```

### 7.3 zyra-app — listener ใหม่ใน `hero-virtual-office.tsx`

จุดต่อ (ใกล้ `map_object_changed`/`map_updated` listener ที่มีอยู่แล้วราวบรรทัด 3436/3538): เมื่อรับ `object_sprite_updated` →
1. Refetch `listAllActiveObjects()` (endpoint เดิม `/api/objects/all`)
2. Bust texture cache เฉพาะ object นั้นใน `texture-registry.ts` (`proxyUrl` + query string version ใหม่ทำให้ browser fetch ใหม่โดยอัตโนมัติอยู่แล้ว ไม่ต้องมี cache-invalidation API แยก)
3. Fade out → fade in (spec EC-01 "ไม่มี visual glitch") — ใช้ Pixi tween ธรรมดาตอน swap texture ใน `scene.ts` (จุดที่มีอยู่แล้วสำหรับ object replace ทั่วไป ถ้ามี, หรือเพิ่ม transition helper เล็ก ๆ)

**Risk ที่ต้องเผื่อเวลา implement:** ส่วนนี้เป็น infra ใหม่ 3 repo (api → ws → app) ไม่ใช่แค่เพิ่ม field ใน form ควรตีเป็น PR แยกจาก CRUD พื้นฐาน (ดู [§9](#9-task-breakdown-แนะนำ))

---

## 8. Frontend (`zyra-app`) — ส่วนที่ต้องเพิ่ม/แก้

| ไฟล์ | เปลี่ยนอะไร |
|---|---|
| `lib/api/objects.ts` | เพิ่ม `NatureType`, `AnimationState`, `ObjectAnimation`, `NATURE_REQUIRED_STATES`, `NATURE_OPTIONAL_STATES` + ฟังก์ชัน `listObjectAnimations(objectId)`, `upsertObjectAnimation(objectId, state, payload)` |
| `views/admin/object-management/components/constants.ts` | เพิ่ม `"nature"` เข้า `OBJECT_TYPES` |
| `views/admin/object-management/components/object-filter-menu.tsx` | เพิ่ม `"nature"` เข้า `TYPE_OPTIONS` |
| `views/admin/object-management/components/object-type-badge.tsx` | เพิ่ม `TYPE_CONFIG["nature"]` (สี badge ใหม่ — รอ Figma token ยืนยัน hex ตาม [10-figma-fidelity.md](../../../.claude/rules/10-figma-fidelity.md) ห้ามเดาสี) |
| **ใหม่** `views/admin/object-management/components/nature-animation-manager.tsx` | หน้า Animation Manager ของ HP-03/HP-04/HP-05 — state slots (required สีแดง/optional สีเทา ตาม AC), upload + frame config form, preview canvas |
| **ใหม่** `views/admin/object-management/components/nature-preview-canvas.tsx` | HP-05 — wind slider + weather condition dropdown + playback controls, "read-only simulation" ไม่ call API ใดๆ เพิ่ม (คำนวณ state transition ฝั่ง client ล้วนจาก threshold ที่ดึงมาแล้ว) |
| `messages/en.json` / `messages/th.json` | เพิ่ม namespace key ใหม่ต่อ component ข้างบน ตาม [`AGENTS.md`](../../../zyra-app/AGENTS.md) i18n convention (English ตาม Figma, ไทยแปลคู่กัน) |

**ไม่แตะ** `object-composer.tsx`/`konva-canvas.tsx` — Nature ไม่ใช้ piece composer เลย (ไม่มี directions/pieces) เป็นหน้าคนละแบบ ("Animation Manager" ไม่ใช่ "Composer")

---

## 9. Task breakdown แนะนำ (ตาม [01-plan.md](../../../.claude/rules/01-plan.md) — แบ่งให้จบใน 1 PR/task)

```
feat(api): add nature_type column + tb_object_animation table (migration 103/104)
feat(api): extend object CRUD to accept type=nature + nature_type, block composition on nature
feat(api): add animation sub-resource (PUT/GET /:id/animations) + validation + active-gating
feat(app): add "nature" to object type enum/badge/filter (constants.ts, object-type-badge.tsx)
feat(app): nature-animation-manager.tsx — upload spritesheet + frame config form (HP-02/HP-03/HP-04)
feat(app): nature-preview-canvas.tsx — wind/weather simulation preview (HP-05)
feat(api+ws+app): object_sprite_updated broadcast — hot-reload plumbing end-to-end (EC-01) — แยก PR ต่างหาก เพราะกระทบ 3 repo
test(api): table-driven tests สำหรับ validation (frame_count/frame_rate/width divisibility/PNG magic bytes/required-state gating)
test(app): vitest สำหรับ nature-animation-manager form validation + preview state-transition logic
```

---

## 10. Open items ที่ยังไม่ตัดสินใจ (ต้องถาม PM/ยืนยันก่อน implement จริง)

1. สี badge ของ `TYPE_CONFIG["nature"]` — ยังไม่มี hex จาก Figma token ที่ตรวจแล้ว ต้องดึงจาก `get_design_context`/`get_variable_defs` ตาม [10-figma-fidelity.md](../../../.claude/rules/10-figma-fidelity.md) ก่อนเขียนโค้ดจริง (spec.md ยังมีแค่ node id ของ layout ไม่ใช่สี)
2. `base_intensity_multiplier` เป็น global ต่อ state หรือ override ได้ต่อ placement (`tb_map_object`) ด้วย — spec HP-04/EC-01 พูดถึงระดับ object definition เท่านั้น ("Placed objects ที่ใช้ config เดิม: inherit config ใหม่จาก object definition อัตโนมัติ") → ยืนยันว่า**ไม่มี per-placement override** เก็บที่ `tb_object_animation` ระดับเดียวพอ (ออกแบบไว้แบบนี้แล้วในเอกสารนี้ — แจ้งไว้เป็น assumption ที่ยังไม่ถาม PM ตรงๆ)
3. Fan-out ของ `object_sprite_updated` — ยิงเฉพาะ workspace ที่มี placement ของ object นั้น (ตามที่ออกแบบไว้) หรือ broadcast แบบ global ทุก workspace ที่ online — เอกสารนี้เลือกแบบแรก (ตรงกับ EC-01 ตัวอย่าง "15 workspaces" และประหยัดกว่า) แต่ยังไม่ได้ confirm กับ PM
4. `wind_threshold_kmh`/weather condition ผูกกับ environment feature ที่มีอยู่แล้วหรือไม่ ([\[Feature\] Environment](<../[Feature]  · Environment (Time of Day + Weather) — Virtual Office Map/>)) — HP-05 preview เป็น "simulation แยก ไม่กระทบ production" แต่ยังไม่ชัดว่า production behavior จริง (ถ้ามี) ของ Nature จะอ่านค่าลมจาก environment service จริงหรือเป็นแค่ preview เท่านั้นที่ implement รอบนี้ (spec ไม่ได้พูดถึง production wind trigger เลย นอกจาก preview)
5. **✅ ตัดสินแล้ว 2026-09-17 — Delete ใช้ behaviour เดิม (ตัวเลือก a) ไม่ทำตาม spec HP-07 ข้อ "ลบ placed_objects"**

   spec HP-07 เขียนว่า soft delete แล้วต้อง "ลบ `placed_objects` ออกจาก map ทันที + hot reload" และ "hard delete storage assets หลัง 30 วัน" — **ตัดสินใจไม่ทำตาม** เพราะจะทำให้ map ของ workspace ที่วางของไว้แล้วหายเป็นรู และทุบ contract **ZYR-1088** ที่ทีมเคยตัดสินใจไว้แล้ว → **ต้องกลับไปแก้ spec ใน ClickUp ให้ตรงความจริง**

   **behaviour ที่ยึด (= โค้ดวันนี้ ตรวจแล้วทั้งเส้น 2026-09-17):**

   | ชั้น | ไฟล์ / query | soft-deleted object ที่ยังถูกวางอยู่ |
   |---|---|---|
   | ลบ | `DeleteObject` (`object_service.go:499-532`) | `UPDATE tb_object SET is_deleted, deleted_at, status='hidden'` — **ไม่แตะ `tb_map_object`** และ **ไม่ลบ S3 assets** |
   | catalog ที่ client ใช้ | `ListAllActiveObjects` (`object_service.go:627-628`) | `WHERE (status='active' AND NOT is_deleted) **OR EXISTS (SELECT 1 FROM tb_map_object WHERE object_id = o.id)`** → **ยังถูกส่งให้ client** ถ้ายังมี placement |
   | render | `buildDbTiles` + contract ZYR-1088 (`zyra-app/__tests__/tile-builder-hidden-objects.test.ts`) | **ยังวาดตามปกติ** — status ใช้ gate แค่ palette (ของที่วางใหม่ได้) |
   | collision (server, ตัวที่ zyra-ws ใช้ validate) | `obstacle_grid_builder.go:245-252` | query `FROM tb_map_object JOIN tb_object` **ไม่มี filter `is_deleted`/`status` เลย** → **ยังกันทางเหมือนเดิม** |

   **สรุปคำถาม "ผู้เล่นยังเดินผ่านได้ไหม": เห็นภาพและชนตรงกันทั้งสองฝั่ง — ไม่มีของล่องหนที่ยังชน และไม่มีภาพที่เดินทะลุได้** เพราะ render กับ obstacle grid อ่านจาก `tb_map_object` ชุดเดียวกันโดยไม่มีฝั่งไหนกรอง `is_deleted` · เฉพาะ Nature ยิ่งไม่มีประเด็นเลยเพราะไม่มีแถว `object_compositions` → ไม่ส่ง hitbox cell เข้า obstacle grid ตั้งแต่แรก ([§3](#3-เหตุผลที่-nature-เดินได้เสมอโดยไม่ต้องเขียนโค้ดเพิ่ม))

   **⚠️ กับดักที่ต้องกันไว้ — อย่าทำ hard delete assets ตาม spec ข้อ 30 วัน**
   ถ้าเอา "hard delete S3 หลัง 30 วัน" มาใช้**ทั้งที่ยังเก็บ placement ไว้** จะได้ผลลัพธ์แย่ที่สุดพอดี: **รูปหาย (ภาพแตก) แต่ hitbox ยังกันทางอยู่** = ของล่องหนที่เดินผ่านไม่ได้ ตรงกับที่ผู้ใช้ห่วงเป๊ะ · กติกาที่ต้องยึด: **ตราบใดที่ยังมีแถวใน `tb_map_object` ที่ reference object นั้น ห้ามลบ S3 asset** (คอมเมนต์ใน `DeleteObject:528-530` ระบุเจตนานี้ไว้แล้ว — อย่ารื้อ) · ถ้าอยากเก็บกวาดจริง ต้องเป็น cron ที่ลบเฉพาะ object ที่ `is_deleted = true` **และ placement count = 0** เท่านั้น ซึ่งยังไม่มีในระบบและไม่ใช่ scope รอบนี้

   **ผลต่อ Nature (HP-07) ที่ต้อง implement จริง:** delete = soft delete + หายจาก palette เท่านั้น · **ไม่ต้องมี hot-reload broadcast สำหรับ delete** (ของที่วางแล้วไม่เปลี่ยน) — broadcast ที่ต้องทำมีแค่ของ EC-01 (replace sprite) ตาม [§7](#7-realtime-hot-reload-broadcast-ec-01--โครงสร้างใหม่ทั้งเส้น)
