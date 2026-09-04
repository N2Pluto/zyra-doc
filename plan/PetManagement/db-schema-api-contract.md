# Pet Management — DB Schema & API Contract

> **สถานะ: design doc — ยังไม่แตะไฟล์จริง** (ไม่มี migration/Go/TS ถูกเขียน) ใช้ review ก่อน implement
> อ้างอิง: [spec.md](spec.md) (แก้ตามคำตอบ PM แล้ว) · [pm-discussion-notes.md](pm-discussion-notes.md) (decision log) · [work-split.md](work-split.md) (แผนแบ่งงาน)
> Migration ถัดไปที่ว่าง: **77** (ล่าสุดในโปรเจกต์คือ `76_user_security_sessions.sql`)
>
> **อัปเดต 2026-08-17 — ✅ ข้อ 2 กับ ข้อ 5 ปิดแล้ว** schema ข้างล่างแก้ตามคำตอบจริงแล้ว ไม่มีจุด 🔴 เหลือ
>
> **อัปเดต 2026-09-01 — แก้ตาม [spec.md](spec.md) ที่ล็อกกฎ sprite จาก asset จริง** 5 จุด: สูตร frame (เซลล์จัตุรัส), ยกเลิกกฎหารลงตัว 2 แกน, ขนาดชีทต้อง = 1000×1000, `direction_rows` ปิดแล้ว (`1`/`4` เรียงตาม `AVATAR_DIR_ROW`), mood Neutral ยืดถึง 72 ชม.
>
> **อัปเดต 2026-09-02 — slot `Evolution` เป็น GIF เท่านั้น (PM เคาะ)** → `frame_count/frame_rate/direction_rows` ต้อง nullable สำหรับ row GIF · egg → baby ใช้ GIF กลางบน R2 ไม่ใช่ slot ต่อ pet type · ดู [§ GIF ที่ slot Evolution](#gif-ที่-slot-evolution--pm-เคาะ-2026-09-02)

## ข้อควรรู้ก่อนอ่าน

สิ่งที่เปลี่ยนจาก draft แรก (2026-08-14) หลัง PM เคาะข้อ 2 / ข้อ 5:

| เปลี่ยน | จาก | เป็น |
|---|---|---|
| slot vocabulary | `walk_n/walk_s/walk_e/walk_w/idle/sit` | `Wobbling` `Walking` `Sitting` `Happy` `Sad` `Evolution` (ยึด Figma) |
| รูปแบบ spritesheet | horizontal strip | **grid** — เพิ่ม `direction_rows` |
| Placement endpoint | มี 2 ทางเลือก (form vs map-scoped) | **map-scoped ชุดเดียว** ตัด `POST /api/admin/pets/:id/assign` ทิ้ง |
| Spawn position | center ของ zone | ตำแหน่งที่ admin วางบน Map Editor |

> `slot` ยังเป็น **VARCHAR + validate ใน Go** ไม่ใช่ PG enum — vocabulary ปิดแล้วก็จริง แต่ enum ต้อง `ALTER TYPE` ทุกครั้งที่เพิ่ม slot ใหม่ (เช่นถ้าเพิ่มท่าใหม่ในอนาคต) VARCHAR + const ถูกกว่าและไม่มีข้อเสียในทางปฏิบัติ

---

## หลักการออกแบบ 3 ข้อ

### 1. ค่าที่ derive ได้ ห้ามเก็บ

card เขียนว่า `room_pets` เก็บ `stage=egg, xp=0, mood=happy` — **ผมเสนอให้เก็บแค่ `xp` กับ `last_activity_at`** ส่วน `stage` และ `mood` คำนวณตอนอ่าน เหตุผล:

- **`stage` derive จาก `xp` + threshold ใน config** — card สั่งว่า "Save → config มีผลทันทีกับทุก pet ใน platform" ถ้า admin ลด `xp_adult` จาก 500 → 300 pet ที่มี 400 XP ต้องเป็น Adult **ทันที** ถ้าเก็บ `stage` เป็นคอลัมน์ต้องมี job ไล่ UPDATE ทุก row (แถมจะ drift ถ้า job พลาด)
- **`mood` derive จาก `last_activity_at`** — mood เปลี่ยนตามเวลาที่ผ่านไปเอง ไม่มี event มาเปลี่ยน ถ้าเก็บเป็นคอลัมน์ต้องมี scheduler เดินทุกชั่วโมงเพื่อเปลี่ยน happy→neutral→sad ซึ่งพังเงียบได้
- ตรงกับ precedent ใน repo: Announcement module ใช้ derived status ไม่เก็บลง DB ([[announcement-module]])

**ยกเว้น `last_seen_stage`** — ต้องเก็บ เพราะเป็นตัวเดียวที่บอกได้ว่า "เพิ่ง" ข้าม stage เพื่อ trigger animation `Evolution` + broadcast (pattern เดียวกับ `announcement.notified_at` migration 75)

### 2. reuse infra ที่มีแล้ว

| ต้องการ | ใช้ของเดิม |
|---|---|
| PNG validate (magic bytes + size) | `readAndValidatePNG()` ใน `avatar_service.go:805` |
| Upload S3 | `storage.S3Client.UploadPNG()` |
| Realtime broadcast | `cache.ZoneEventPublisher.PublishZoneEvent()` → Redis `vo:zone` |
| Pagination/filter/sort shape | `ListAvatarsParams` + `AvatarListData` |
| Soft delete + partial unique name | pattern ของ `tb_object` (migration 70) |

**ไม่สร้าง RBAC permission key ใหม่** — Avatar/Object management ปัจจุบันใช้แค่ `AdminGuard` ไม่มี `RequirePermission` (ต่างจาก User Management) Pet Management จึงทำแบบเดียวกัน ถ้าจะ gate ทีหลังค่อยเพิ่ม key เป็นงานแยก

### 3. ตำแหน่ง = double precision ไม่ใช่ INT

`tb_room_pet.tile_x/tile_y` เป็น `DOUBLE PRECISION` ตั้งแต่แรก — ไม่ใช่ INT แล้วแก้ทีหลัง เพราะเคยพลาดมาแล้วกับ `tb_map_object` (INT ทำให้ตำแหน่ง quarter-tile ถูกปัดเงียบ ๆ คนละที่กับที่วาง ต้องมา migration 59 แก้ทีหลัง)

---

## DB Schema — migration `77_pet_management.sql`

### 1. `tb_pet_type` — Pet Library (SC-PM-01/02)

```sql
CREATE TABLE IF NOT EXISTS tb_pet_type (
    id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(100) NOT NULL,
    category              VARCHAR(20)  NOT NULL DEFAULT 'cat',
    description           TEXT,
    status                VARCHAR(10)  NOT NULL DEFAULT 'hidden'
                                       CHECK (status IN ('active', 'hidden')),
    thumbnail_url         TEXT,
    workspace_usage_count INT          NOT NULL DEFAULT 0,
    is_deleted            BOOLEAN      NOT NULL DEFAULT FALSE,
    deleted_at            TIMESTAMPTZ,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- unique เฉพาะ row ที่ยังไม่ถูกลบ — soft-deleted pet ไม่ควรกินชื่อไว้ตลอดกาล
-- (ปัญหาเดียวกับ tb_object ที่ต้องแก้ด้วย migration 70)
CREATE UNIQUE INDEX IF NOT EXISTS uq_pet_type_name_active
    ON tb_pet_type (lower(name)) WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_pet_type_status ON tb_pet_type (status)
    WHERE is_deleted = FALSE;
```

- index ใช้ `lower(name)` **ต่างจาก precedent** เล็กน้อย — `tb_object` (migration 70) unique ที่ `(name)` ตรง ๆ ทำให้ "Mochi" กับ "mochi" อยู่ร่วมกันได้ ซึ่งน่าจะไม่ใช่สิ่งที่ต้องการสำหรับ catalog ที่ admin พิมพ์ชื่อเอง ถ้าต้องการให้เหมือนของเดิมเป๊ะ ตัด `lower()` ออก
- `category` validate ใน Go (`IsValidPetCategory`) ไม่ใช่ CHECK — card เขียน "dropdown (Cat, Dog, ....)" คือ list ยังไม่ปิด การใส่ CHECK จะทำให้เพิ่ม category = migration
- `workspace_usage_count` = จำนวน room ที่ pet type นี้ถูกวาง (denormalized counter, sync แบบเดียวกับ `tb_avatar.user_count` / `tb_map_template.workspace_usage_count`) — เป็น field ที่ Figma แสดงเป็น badge วงกลม (ข้อ 9)
- `thumbnail_url` แยกจาก sprite — card บอก card grid โชว์ "Evolved sprite animated preview" ซึ่ง**อ่านจาก animation ของ stage evolved ได้เลย** thumbnail จึงเป็น optional fallback ตอน stage ยังไม่ครบ

### 2. `tb_pet_animation` — sprite ต่อ (stage, slot) (SC-PM-03)

**ไม่มีตาราง `tb_pet_stage`** — stage เป็นค่าคงที่ 4 ค่า ไม่มี attribute ของตัวเอง (ready/incomplete เป็น derived) การมีตารางกลางจะบังคับให้ต้อง seed 4 row ทุกครั้งที่สร้าง pet type โดยไม่ได้อะไรกลับมา

```sql
CREATE TABLE IF NOT EXISTS tb_pet_animation (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_type_id  UUID        NOT NULL REFERENCES tb_pet_type(id) ON DELETE CASCADE,
    stage        VARCHAR(10) NOT NULL CHECK (stage IN ('egg', 'baby', 'adult', 'evolved')),
    slot         VARCHAR(20) NOT NULL,          -- Wobbling|Walking|Sitting|Happy|Sad|Evolution — validate ใน Go
    sprite_url   TEXT        NOT NULL,
    frame_count    INT       NOT NULL CHECK (frame_count    BETWEEN 1 AND 64),
    frame_rate     INT       NOT NULL CHECK (frame_rate     BETWEEN 4 AND 24),
    direction_rows INT       NOT NULL DEFAULT 1
                             CHECK (direction_rows IN (1, 4)),  -- ✅ ปิดแล้ว 2026-09-01 (เห็น sprite จริงแล้ว)
    frame_width  INT         NOT NULL,          -- = floor(sprite_width / frame_count)  เซลล์จัตุรัส
    frame_height INT         NOT NULL,          -- = frame_width (จัตุรัส) ไม่ใช่ sprite_height / direction_rows
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (pet_type_id, stage, slot)
);

CREATE INDEX IF NOT EXISTS idx_pet_animation_type ON tb_pet_animation (pet_type_id);
```

- **spritesheet เป็น grid ของเซลล์จัตุรัส** (ข้อ 2 — ยึด Figma; ล็อกค่าจาก asset จริง 2026-09-01): คอลัมน์ = frame, แถว = direction
  - ชีทต้องเป็น **1000 × 1000 px เท่านั้น** (เหมือน avatar — `requiredSpritesheetDim` ใน `avatar_service.go`)
  - `frame_width = frame_height = floor(sprite_width / frame_count)`
  - อ่าน `direction_rows` แถวจากด้านบน **พื้นที่ที่เหลือด้านล่าง/ขวาปล่อยว่างได้**
  - ❌ **ไม่มีกฎหารลงตัวแล้ว** — asset จริง (`Cat_Adult_Happy.png`, 6 คอลัมน์ × 4 แถว) มี `1000 % 6 = 4` และแถวจริงสูง ~166 ไม่ใช่ 250 กฎเดิมจึง reject ไฟล์และตัดสไปรต์กลางตัว ดูผลวัดใน [spec.md § Sprite Grid](spec.md)
  - ตรวจแทนด้วย: `frame_size ≥ 16px` และ `direction_rows × frame_size ≤ sprite_height`

### ✅ ค่า `direction_rows` + ลำดับแถว — ปิดแล้ว 2026-09-01

ยืนยันจาก asset จริงของ artist (`zyra-app/public/image/petdemo/Cat_Adult_Happy.png` — 1000×1000, 6 ท่า × 4 ทิศ, ล่างว่าง ~1/3):

| row | ทิศ | ที่มา |
|---|---|---|
| 0 | `down` (ใต้) | `AVATAR_DIR_ROW` ใน `zyra-app/zyra-engine/avatar-frames.ts:26` — ตรงกับไฟล์จริงเป๊ะ |
| 1 | `left` (ตก) | |
| 2 | `right` (ออก) | |
| 3 | `up` (เหนือ) | |

| slot | direction_rows ที่ใช้ |
|---|---|
| `Walking`, `Sitting` | 4 |
| `Wobbling`, `Happy`, `Sad` | 1 หรือ 4 (แล้วแต่ไฟล์ที่ artist ส่ง — `Cat_Adult_Happy.png` เป็น 4) |
| `Evolution` | **ไม่มี** — เป็น GIF (2026-09-02) ดูหัวข้อถัดไป |

### GIF ที่ slot `Evolution` — PM เคาะ 2026-09-02

`Evolution` ไม่ใช่ spritesheet อีกต่อไป: อัปโหลดเป็น **GIF จบในตัว** เล่นตอน pet ข้าม threshold (สถานะ evo ของช่วงวัยนั้น) — ดูกฎเต็มใน [spec.md § Evolution slot = GIF](spec.md)

ผลต่อ schema `tb_pet_animation`:

| คอลัมน์ | row PNG (slot อื่น) | row GIF (`Evolution`) |
|---|---|---|
| `sprite_url` | `.../{stage}/{slot}_{uuid}.png` | `.../{stage}/evolution_{uuid}.gif` (โค้ดตั้ง ext/content-type ตาม GIF อยู่แล้ว) |
| `frame_count` / `frame_rate` / `direction_rows` | NOT NULL + CHECK | **NULL** → ต้องปลด `NOT NULL` เป็น `CHECK ((slot = 'Evolution' AND frame_count IS NULL AND frame_rate IS NULL AND direction_rows IS NULL) OR (slot <> 'Evolution' AND frame_count BETWEEN 1 AND 64 AND ...))` — migration ใหม่ + แก้ bootstrap DDL ใน `internal/database/postgres.go` |
| `frame_width` / `frame_height` | `floor(1000 ÷ frame_count)` | **width × height ของ GIF** (เช่น 960 × 960) — ใช้เป็นขนาดตอน render |

Validation ฝั่ง Go สำหรับ GIF: magic `GIF87a`/`GIF89a` (มีแล้ว) · `gif.DecodeConfig` แล้วเช็ค **`width == height && width ≤ 1000`** เท่านั้น · **ห้าม**เรียก `validatePetSpriteDimensions` (โค้ดปัจจุบันยังเรียก — ต้องแก้) · ไม่ตรวจ transparency · ขนาดไฟล์ ≤ 1 MB เท่าเดิม

API response ของ animation GIF: `{ sprite_url, frame_width, frame_height, frame_count: null, frame_rate: null, direction_rows: null, mime_type: "image/gif" }` — เพิ่ม `mime_type` (หรือ FE ดูจากนามสกุล) เพื่อให้ client เลือก renderer ถูก

**`RequiredSlots` ไม่เปลี่ยน — PM ยืนยัน 2026-09-02 ว่า egg และ evolved ยังต้องมี `Evolution`** (17 slot): egg = `{Wobbling, Evolution}` · baby/adult/evolved = `{Walking, Sitting, Happy, Sad, Evolution}`

**Prefill egg `Evolution` (เคาะ 2026-09-02) — fallback ตอนอ่าน ไม่มี row:**

```
GET /api/admin/pets/:id  →  animations.egg.Evolution
  มี row       → { sprite_url: <ของ type>, frame_width, frame_height, ..., is_default: false }
  ไม่มี row    → { sprite_url: cfg.PetEggEvolutionDefaultURL, frame_width: 960, frame_height: 960,
                   frame_count: null, frame_rate: null, direction_rows: null,
                   mime_type: "image/gif", is_default: true }
stage_ready.egg = has(Wobbling)            // Evolution ถือว่าพร้อมเสมอ (default หรือของเอง)
DELETE .../stages/egg/animations/Evolution → ลบ row แล้วคืน 200 พร้อม object default (ไม่ใช่ 404 / ไม่ใช่ว่าง)
```

- config ใหม่ใน `zyra-api/internal/config`: `PET_EGG_EVOLUTION_DEFAULT_URL` (default `${AWS_PUBLIC_URL}/static/pet/shared/egg-evolution.gif`) — ไฟล์จริงอยู่บน R2 แล้ว 960×960 · 24 เฟรม · 159 KB
- ไม่ insert row ตอน `POST /api/admin/pets` และไม่ backfill type เก่า — default มีผลกับทุก type รวมที่สร้างไปแล้ว
- `is_default` ปรากฏใน animation object **ทุกตัว** (false สำหรับ slot อื่น) เพื่อให้ FE ไม่ต้อง special-case ชื่อ slot
- member endpoint `GET /api/user/workspaces/:id/pets` ใช้ fallback เดียวกัน — client VO ไม่รู้จัก URL กลางเอง
- **ไม่ต้องแก้ schema** — เป็น logic ใน service + config อย่างเดียว

- `CHECK (direction_rows IN (1, 4))` ใส่ได้เลยแล้ว ไม่ต้องรออีก
- ลำดับแถว: ต้อง **import จาก `AVATAR_DIR_ROW`** ไม่ใช่พิมพ์เลข 0-3 ใหม่ (engine มี single source อยู่แล้ว)
- `frame_width`/`frame_height` **เก็บ** ไม่ derive ตอน read — client ต้องใช้ทุกเฟรมเพื่อ slice spritesheet ถ้าไม่เก็บต้อง decode PNG ใหม่ทุก request
- `CHECK` ของ `frame_count`/`frame_rate`/`direction_rows` = ค่าเดียวกับ SC-PM-07 — validate 2 ชั้น (Go ให้ error code สวย, DB กัน bug)

**Slot vocabulary — const ใน Go ไม่ใช่ CHECK** (เพิ่มท่าใหม่ไม่ต้อง migration):

```go
var petSlots = []string{"Wobbling", "Walking", "Sitting", "Happy", "Sad", "Evolution"}

func RequiredSlots(stage string) []string {
    if stage == "egg" {
        return []string{"Wobbling", "Evolution"}
    }
    return []string{"Walking", "Sitting", "Happy", "Sad", "Evolution"} // baby / adult / evolved
}
```

### 3. `tb_pet_xp_config` — global config + version history (SC-PM-04)

card ต้องการ "บันทึก 10 versions ล่าสุด ย้อนกลับได้" → เก็บเป็น **immutable snapshot row ละ version** ไม่ใช่ table เดียวที่ UPDATE ทับ

```sql
CREATE TABLE IF NOT EXISTS tb_pet_xp_config (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    version    INT         NOT NULL UNIQUE,
    is_current BOOLEAN     NOT NULL DEFAULT FALSE,
    config     JSONB       NOT NULL,
    created_by VARCHAR(36) REFERENCES tb_user(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- มี current ได้แค่ version เดียว (pattern เดียวกับ enforce_single_default_avatar, migration 30)
CREATE UNIQUE INDEX IF NOT EXISTS uq_pet_xp_config_current
    ON tb_pet_xp_config (is_current) WHERE is_current = TRUE;
```

**ทำไม JSONB ไม่ใช่ 20 คอลัมน์**: config มี ~19 scalar (3 threshold + 10 activity + 3 mood duration + 3 mood rate) และต้องเก็บ history — ถ้าเป็นคอลัมน์ การเพิ่ม activity ตัวที่ 11 = migration ที่ต้องเติมค่าให้ทุก history row ย้อนหลัง ซึ่งทำให้ snapshot เก่า "ถูกแก้" ไม่ใช่ snapshot อีกต่อไป JSONB ทำให้ version เก่าแช่แข็งจริง

**ราคาที่จ่าย**: DB ไม่ validate ค่าให้ → **validation ทั้งหมดอยู่ใน Go struct** (`model.PetXPConfig` + `Validate()`) ต้องมี unit test คุมให้ครบ (min/max ต่อ field, `happy_rate ≥ neutral_rate ≥ sad_rate`)

**รูปร่าง `config` JSONB** (default = ค่าจาก card):

```json
{
  "thresholds": { "xp_baby": 100, "xp_adult": 500, "xp_evolve": 2000 },
  "activities": {
    "xp_login_per_day":         { "xp": 1,  "enabled": true },
    "xp_office_10min":          { "xp": 2,  "enabled": true },
    "xp_office_30min":          { "xp": 6,  "enabled": true },
    "xp_team_meeting":          { "xp": 10, "enabled": true },
    "xp_team_meeting_10min":    { "xp": 2,  "enabled": true },
    "xp_team_meeting_30min":    { "xp": 6,  "enabled": true },
    "xp_first_message_fo_day":  { "xp": 1,  "enabled": true },
    "xp_10_message_fo_day":     { "xp": 2,  "enabled": true },
    "xp_react_message_fo_day":  { "xp": 1,  "enabled": true },
    "xp_play_with_pet":         { "xp": 1,  "enabled": true }
  },
  "mood": {
    "happy":   { "within_hours": 12, "xp_rate_percent": 150 },
    "neutral": { "within_hours": 72, "xp_rate_percent": 100 },
    "sad":     { "after_hours":  72, "xp_rate_percent": 50  }
  }
}
```

- `enabled` ใส่ไว้ตั้งแต่แรกเพราะ Figma มี toggle ต่อ activity (ข้อ 4 ที่ยังค้าง) — ถ้าไม่ต้องใช้ ก็ปล่อย `true` ทิ้งไว้ ไม่มี cost แต่ถ้าต้องใช้แล้วไม่มี ต้องเขียน migration แก้ JSONB ทุก row
- `Max` จาก card ไม่ได้เก็บใน DB — เป็น **validation constant ใน Go** (เพดานที่ admin กรอกได้) ไม่ใช่ข้อมูลที่ config เก็บ
- prune history: หลัง insert version ใหม่ ลบ version ที่เก่ากว่า 10 ล่าสุดใน tx เดียวกัน

### 4. `tb_room_pet` — pet instance ในห้อง (SC-PM-05)

> ✅ **ลงจริงแล้ว 2026-09-04** — `zyra-api/migrations/88_room_pet.sql` (+ `.down.sql`) apply บน dev DB แล้ว · ต่างจากร่างด้านล่าง 3 จุด: เพิ่ม `created_by` / `updated_by` (VARCHAR → `tb_user`, pattern เดียวกับ `tb_pet_type`) · เพิ่ม `idx_room_pet_pet_type` (partial, ใช้เช็ก `PET_TYPE_IN_USE`) · `last_seen_stage` มี CHECK 4 ค่า · `uq_room_pet_one_per_zone` **เปิดใช้แล้ว** (PM เคาะ 1 room = 1 pet 2026-09-04 — apply บน dev แล้ว)

```sql
CREATE TABLE IF NOT EXISTS tb_room_pet (
    id               UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    map_id           UUID             NOT NULL REFERENCES tb_map(id)      ON DELETE CASCADE,
    zone_id          UUID             NOT NULL REFERENCES tb_map_zone(id) ON DELETE CASCADE,
    pet_type_id      UUID             NOT NULL REFERENCES tb_pet_type(id) ON DELETE RESTRICT,
    name             VARCHAR(30),                        -- NULL = ใช้ชื่อ pet type (ตั้งตอนวางบน Map Editor)
    tile_x           DOUBLE PRECISION NOT NULL,          -- ตำแหน่งที่ admin วาง, ไม่ใช่ INT (บทเรียน migration 59)
    tile_y           DOUBLE PRECISION NOT NULL,
    xp               INT              NOT NULL DEFAULT 0 CHECK (xp >= 0),
    last_activity_at TIMESTAMPTZ      NOT NULL DEFAULT NOW(),  -- mood derive จากค่านี้
    last_seen_stage  VARCHAR(10)      NOT NULL DEFAULT 'egg',  -- detect stage transition
    is_deleted       BOOLEAN          NOT NULL DEFAULT FALSE,
    deleted_at       TIMESTAMPTZ,
    created_at       TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_room_pet_map ON tb_room_pet (map_id) WHERE is_deleted = FALSE;

-- กฎ "1 room = 1 pet" — PM ยังไม่เคาะ (ข้อ 5 ตอบแค่ flow) ยังไม่เปิด index นี้
-- default ปัจจุบัน = วางได้หลายตัวต่อห้อง; เพิ่ม unique index ทีหลังทำได้ถ้ายังไม่มีข้อมูลซ้ำ
-- แต่ถ้าเปิดไปแล้วปลดยากกว่า จึงเลือกไม่เปิดไว้ก่อน
-- CREATE UNIQUE INDEX IF NOT EXISTS uq_room_pet_one_per_zone
--     ON tb_room_pet (zone_id) WHERE is_deleted = FALSE;
```

- **1 room = 1 pet บังคับแล้ว** (PM 2026-09-04) — `uq_room_pet_one_per_zone` เปิดใช้ใน migration 88 · ห้องที่วางได้ = `zone_type = 'room'` เท่านั้น และจุดวางห้ามตกใน meeting/private (กฎอยู่ใน service ดู §Placement)
- `map_id` **เก็บซ้ำ**กับที่ derive ได้จาก `zone_id` โดยตั้งใจ — VO client โหลด pet ทั้งชั้นด้วย `WHERE map_id = ?` ครั้งเดียว ถ้าไม่เก็บต้อง JOIN `tb_map_zone` ทุกครั้งที่เข้าห้อง
- `ON DELETE RESTRICT` ที่ `pet_type_id` — pet type ที่ถูกวางใช้งานอยู่ต้องลบไม่ได้ (soft delete เท่านั้น) ป้องกัน pet หายจาก map ของ user โดยที่ admin ไม่รู้ตัว
- **ไม่มีคอลัมน์ `stage` และ `mood`** — derive (ดูหัวข้อถัดไป)

### 5. `tb_room_pet_xp_event` — XP ledger + กัน XP ซ้ำ

**ตารางนี้ไม่มีใน card เลย แต่ขาดไม่ได้** — ถ้าไม่มี `xp_first_message_fo_day` จะจ่าย XP ทุกข้อความที่ส่ง ไม่ใช่ข้อความแรกของวัน และ `xp_login_per_day` จะจ่ายทุกครั้งที่ login ไม่ใช่วันละครั้ง

```sql
CREATE TABLE IF NOT EXISTS tb_room_pet_xp_event (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    room_pet_id UUID        NOT NULL REFERENCES tb_room_pet(id) ON DELETE CASCADE,
    activity    VARCHAR(40) NOT NULL,              -- key ใน config.activities
    user_id     VARCHAR(36) REFERENCES tb_user(id) ON DELETE SET NULL,  -- NULL = room-level
    day_key     DATE        NOT NULL,              -- วันที่ (UTC+7) ที่นับ quota
    xp_base     INT         NOT NULL,              -- ค่าจาก config ตอนนั้น
    xp_awarded  INT         NOT NULL,              -- xp_base × mood multiplier (ปัดลง)
    mood        VARCHAR(10) NOT NULL,              -- mood ตอนจ่าย (audit)
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- กันจ่ายซ้ำ: activity ที่นับ per-user ใช้ user_id, ที่นับ per-room ใส่ '' แทน NULL
-- (NULL ใน unique index ไม่ชนกันเอง — ต้อง COALESCE ไม่งั้นกันไม่ได้เลย)
CREATE UNIQUE INDEX IF NOT EXISTS uq_room_pet_xp_daily
    ON tb_room_pet_xp_event (room_pet_id, activity, day_key, COALESCE(user_id, ''));
```

**scope ต่อ activity** (⚠️ ตีความจากคำอธิบายใน card — ต้องให้ PM ยืนยัน):

| Activity | scope | เหตุผล |
|---|---|---|
| `xp_login_per_day` | per user / วัน | card เขียน "XP ต่อ **user** login/วัน" |
| `xp_office_10min` / `_30min` | per room / วัน | "มีคนอยู่ใน office" — ไม่ผูกกับคนใดคนหนึ่ง |
| `xp_team_meeting*` | per room / วัน | "**Team** join a meeting" |
| `xp_first_message_fo_day` | per user / วัน | "**your** first message of the day" |
| `xp_10_message_fo_day` | per user / วัน | นับข้อความของ user คนนั้น |
| `xp_react_message_fo_day` | per user / วัน | action ของ user |
| `xp_play_with_pet` | per user / วัน | action ของ user |

`day_key` เป็น DATE ตาม timezone ไทย (UTC+7) ไม่ใช่ UTC — ไม่งั้น "ข้อความแรกของวัน" จะรีเซ็ตตอน 7 โมงเช้า

---

## ค่าที่ derive ไม่เก็บ

### `stage` — จาก `xp` + threshold ปัจจุบัน

```
xp <  xp_baby    → egg
xp <  xp_adult   → baby
xp <  xp_evolve  → adult
xp >= xp_evolve  → evolved
```

`last_seen_stage` ใช้ตรวจ transition: ถ้า `derived != last_seen_stage` → เล่น animation `Evolution` + broadcast `pet_stage_changed` + UPDATE `last_seen_stage` (idempotent — ยิงซ้ำไม่ได้)

### `mood` — จาก `NOW() - last_activity_at`

```
≤ 12 ชม.       → happy   (×150%)
12–72 ชม.      → neutral (×100%)
> 72 ชม.       → sad     (×50%)
```

**✅ ปิดแล้ว 2026-09-01 — Neutral ยืดถึง 72 ชม.** (ช่องว่าง 48–72 ที่เคยไม่มี state หายไป)

- ค่าที่ admin ตั้งได้จริงมี 2 ค่า: `mood.happy.within_hours` (ขอบบนของ Happy) และ `mood.sad.after_hours` (ขอบที่เข้า Sad)
- `mood.neutral.within_hours` **ต้องเท่ากับ** `mood.sad.after_hours` เสมอ (เป็นค่า mirror ไม่ใช่ค่าอิสระ) — ฟอร์มแสดงช่อง Neutral เป็น read-only
- ⚠️ **validation ฝั่ง Go ต้องแก้**: จาก `happy.within < neutral.within < sad.after` เป็น `happy.within < sad.after` **และ** `neutral.within == sad.after`
- seed ของ migration 85 + bootstrap DDL ต้องเปลี่ยน `neutral.within_hours` จาก 48 → 72

### `stage_ready` — จากจำนวน animation ที่ upload ครบ

required slot list เป็น const ใน Go (`RequiredSlots(stage) []string` — ดูโค้ดในหัวข้อ `tb_pet_animation`) → `stage_ready = ทุก slot ใน list มี row ใน tb_pet_animation`

`egg` ต้องครบ 2 slot, `baby`/`adult`/`evolved` ต้องครบ 5 slot

---

## API Contract

ทุก endpoint ตอบด้วย envelope `model.APIResponse` (`{status, message, data?}`) ตาม `.claude/rules/02-design.md`

### Admin — `/api/admin/pets` (AdminGuard)

| Method | Path | คำอธิบาย |
|---|---|---|
| GET | `/api/admin/pets` | list + filter/search/sort/pagination (SC-PM-01) |
| POST | `/api/admin/pets` | สร้าง pet type → `status=hidden` (SC-PM-02) |
| GET | `/api/admin/pets/:id` | detail + animation ทุก stage + `stage_ready` |
| PUT | `/api/admin/pets/:id` | แก้ name/category/description/status |
| DELETE | `/api/admin/pets/:id` | soft delete — 409 ถ้ายังถูกวางในห้องอยู่ |
| POST | `/api/admin/pets/:id/stages/:stage/animations/:slot` | upload spritesheet (multipart) (SC-PM-03) |
| DELETE | `/api/admin/pets/:id/stages/:stage/animations/:slot` | ลบ animation ออกจาก slot |
| POST | `/api/admin/pets/:id/thumbnail` | upload thumbnail (optional) |

### Admin — XP Config `/api/admin/pet-xp-config` (AdminGuard)

| Method | Path | คำอธิบาย |
|---|---|---|
| GET | `/api/admin/pet-xp-config` | config ที่ใช้อยู่ (`is_current`) |
| PUT | `/api/admin/pet-xp-config` | สร้าง version ใหม่ + ตั้งเป็น current (SC-PM-04) |
| GET | `/api/admin/pet-xp-config/history` | 10 versions ล่าสุด |
| POST | `/api/admin/pet-xp-config/history/:version/restore` | clone version เก่าเป็น version ใหม่ |

> **ทำไมแยก path ไม่เอาไว้ใต้ `/api/admin/pets/xp-config`**: Gin 1.10 รองรับ static segment คู่กับ `:id` ได้ (มี precedent `customers.GET("/export")` คู่กับ `/:id` ที่ `router.go:409`) แต่ต้องระวังลำดับ register ตลอดไป — แยก path ทำให้ไม่มีโอกาสพลาดเลย และ XP config เป็น global ไม่ได้เป็น sub-resource ของ pet ตัวใดตัวหนึ่งอยู่แล้ว
>
> restore ใช้ **POST สร้าง version ใหม่** ไม่ใช่ PUT ย้อนของเก่า — history จึงเป็น append-only อ่านย้อนหลังได้ว่าใครกดย้อนเมื่อไหร่

### Admin — Placement (SC-PM-05, Map Editor drag-drop)

ผูกกับ **map** ไม่ใช่กับ pet type — ไม่มี `POST /api/admin/pets/:id/assign` แล้ว (flow ฟอร์มตกไปตามข้อ 5)

| Method | Path | คำอธิบาย |
|---|---|---|
| GET | `/api/admin/maps/:mapId/pets` | pet ทั้งหมดบนชั้นนี้ (editor load) |
| POST | `/api/admin/maps/:mapId/pets` | วาง pet: `{zone_id, pet_type_id, name?, tile_x, tile_y}` |
| PATCH | `/api/admin/maps/:mapId/pets/:petId` | ย้าย/เปลี่ยนชื่อ: `{name?, tile_x?, tile_y?}` |
| DELETE | `/api/admin/maps/:mapId/pets/:petId` | ลบออกจากห้อง (soft delete) |

- `tile_x`/`tile_y` = ตำแหน่งที่ admin วางจริง — service **ไม่คำนวณ center ของ zone** ให้
- service ต้อง validate ว่าจุดที่วางอยู่ภายใน `zone_id` ที่ส่งมาจริง (ใช้ `lib/zone-utils` ฝั่ง FE + ตรวจซ้ำฝั่ง service เพราะ zone เป็น tiles JSONB ไม่ใช่ AABB)
- pet type ที่วางได้ต้อง `status = active` **และ** `stage_ready` ครบทุก stage

> ✅ **implement แล้ว 2026-09-04** (`feat/room-pet-placement`, `handler/room_pet_handler.go` + `service/room_pet_service.go`) — รายละเอียดที่ contract ไม่ได้เขียนไว้แล้วตัดสินตอนทำ:
> - **ต้องถือ workspace lock** สำหรับ POST/PATCH/DELETE เหมือน objects/zones ใน group เดียวกัน → ไม่มี lock = **423 `WORKSPACE_LOCKED`** (GET ไม่ต้อง)
> - response `RoomPet`: `name` = ชื่อที่แสดงจริงเสมอ (custom หรือชื่อ pet type) + `is_custom_name` · มี `pet_type_name` / `thumbnail_url` join มาให้ palette · **ไม่มี** `stage` / `mood` (derive ฝั่ง client จาก `xp` + `/api/user/pet-xp-config`)
> - PATCH `name: ""` = ล้างชื่อ custom กลับไปใช้ชื่อ pet type · PATCH ส่ง `tile_x` หรือ `tile_y` ตัวเดียวได้ (อีกตัวใช้ค่าเดิม) · ย้ายได้**ภายใน zone เดิมเท่านั้น** (ไม่มี `zone_id` ใน PATCH ตาม contract) · body ว่าง → 400 `INVALID_REQUEST` · tile ติดลบ → 400 `INVALID_POSITION`
> - กฎ inside-zone = `zoneContainsTile` ฝั่ง FE: floor anchor เป็น tile (57.5 → 57) · tiles JSONB ชนะ rect · rect ใช้ `zoneTilePx = 32`
> - HTTP status = ค่าใน body (404/400/423/500) ต่างจาก `/api/admin/pets*` เดิมที่ตอบ HTTP 200 เสมอ — `authFetch` อ่าน body ทั้ง 2 แบบ
> - เพิ่ม code: 404 `MAP_NOT_FOUND` · 404 `ZONE_NOT_FOUND` (zone ไม่ได้อยู่บน map นี้) · 404 `ROOM_PET_NOT_FOUND` · 400 `INVALID_NAME` (> 30 rune) · 400 `INVALID_POSITION` · 423 `WORKSPACE_LOCKED`
> - `DELETE /api/admin/pets/:id` ตอบ 409 `PET_TYPE_IN_USE` แล้วเมื่อยังมี placement ที่ `is_deleted = FALSE` · `workspace_usage_count` = `COUNT(DISTINCT workspace)` ของ placement สด recompute ใน tx เดียวกับ place/remove (F7 ปิด)
> - **PM เคาะ 2026-09-04:** วางได้เฉพาะ `zone_type = 'room'` (400 `ZONE_NOT_ROOM`) · จุดวางห้ามตกใน `meeting` / `private` แม้ซ้อนใน room (400 `POSITION_BLOCKED_BY_ZONE` — เช็กทุก zone ประเภทนั้นบน map ทั้งตอน place และ move) · 1 room = 1 pet (409 `ZONE_ALREADY_HAS_PET` — pre-check ใน tx + unique index รับ race; ลบแล้ววางใหม่ได้เพราะ index นับเฉพาะ `is_deleted = FALSE`)

### Member — `/api/user/*` (UserGuard)

ตาม `.claude/rules/15-member-api-separation.md` — member **ห้าม**เรียก `/api/admin/*`

| Method | Path | คำอธิบาย |
|---|---|---|
| GET | `/api/user/pet-xp-config` | ✅ **ทำแล้ว 2026-09-02** (branch `feat/room-pet-user-xp-config`) — config ปัจจุบันแบบ member: `{ version, config: { thresholds, activities (ทุกตัวพร้อม `enabled`), mood } }` **ไม่มี** `id` / `is_current` / `created_by*` / `constraints` · 404 `PET_XP_CONFIG_NOT_FOUND` ถ้ายังไม่มี version · VO ใช้ derive stage / progress / mood + Daily quest (`buildPetDailyQuests`) |
| GET | `/api/user/workspaces/:workspaceId/pets` | ✅ **ทำแล้ว 2026-09-04** ([zyra-api #66](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/66)) — pet **ทุกชั้น** ของ workspace ในครั้งเดียว (client filter `map_id`) แต่ละตัว = `RoomPet` + `animations[]` ครบทุก stage/slot · **ไม่ส่ง `stage`/`mood`** ให้ client derive จาก `xp` + `/api/user/pet-xp-config` · owner/member เท่านั้น ไม่ใช่ = 403 (workspace ไม่มีจริงก็ 403 ไม่ leak) |
| POST | `/api/user/workspaces/:workspaceId/pets/:petId/play` | activity "Play with your pet" → บวก XP (idempotent วันละครั้ง/คน) |

---

## ตัวอย่าง Request / Response

### `GET /api/admin/pets?search=&category=cat&status=active&sort=name&page=1&limit=10`

```json
{
  "status": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "9f3c…",
        "name": "Mochi",
        "category": "cat",
        "status": "active",
        "thumbnail_url": "https://pub-b74ca….r2.dev/static/pet/9f3c…/thumbnail.png",
        "workspace_usage_count": 7,
        "stage_ready": { "egg": true, "baby": true, "adult": true, "evolved": false },
        "created_at": "2026-08-14T03:12:00Z",
        "updated_at": "2026-08-14T03:12:00Z"
      }
    ],
    "total": 23, "page": 1, "limit": 10
  }
}
```

`limit` default = **10** (ข้อ 10) และ cap ที่ 100

### `POST /api/admin/pets/:id/stages/adult/animations/sit` — multipart

> path เป็น `…/animations/Sitting` (slot ตาม vocabulary ใหม่) ไม่ใช่ `sit`

| field | ค่า |
|---|---|
| `file` | PNG spritesheet — **1000 × 1000 px เท่านั้น**, ≤ 1 MB (ไม่มีกฎหารลงตัวแล้ว) |
| `frame_count` | `1`–`64` (จำนวนคอลัมน์) — default **6** · ต้องได้ `frame_size = floor(1000 / frame_count) ≥ 16px` |
| `frame_rate` | `4`–`24` — default **8** (= `AVATAR_WALK_FPS`) |
| `direction_rows` | `1` หรือ `4` เท่านั้น (`4` = down/left/right/up ตามลำดับ `AVATAR_DIR_ROW`) |

```json
{
  "status": 200,
  "message": "success",
  "data": {
    "sprite_url": "https://pub-b74ca….r2.dev/static/pet/9f3c…/adult/Sitting_7c1e….png",
    "frame_width": 166, "frame_height": 166, "direction_rows": 4,
    "stage_ready": true
  }
}
```

### Error codes (SC-PM-07)

ใช้ `detail.code` แนบไปกับ envelope (pattern เดียวกับ `UploadUrlResponse.detail` ใน `lib/api/avatars.ts`)

| HTTP | code | เมื่อ |
|---|---|---|
| 400 | `INVALID_FILE_TYPE` | ไม่ใช่ PNG (นามสกุล + magic bytes `89 50 4E 47`) |
| 400 | `FILE_TOO_LARGE` | > 1 MB |
| 400 | `INVALID_DIMENSIONS` | ขนาดชีทไม่ใช่ 1000 × 1000 px พอดี |
| 400 | `INVALID_FRAME_COUNT` | นอกช่วง 1–64 |
| 400 | `INVALID_FRAME_RATE` | นอกช่วง 4–24 |
| 400 | `INVALID_DIRECTION_ROWS` ⚠️ | ไม่ใช่ `1` หรือ `4` |
| 400 | `FRAME_SIZE_MISMATCH` | `floor(width / frame_count) < 16px` (frame_count มากเกินไป) — แนบ `{width, frame_count, frame_size}` ให้ FE ขึ้นข้อความพร้อมเลข |
| 400 | `FRAME_ROW_MISMATCH` | `direction_rows × frame_size > height` (grid ล้นภาพ) — แนบ `{height, direction_rows, frame_size}` |
| 400 | `INVALID_SLOT` | `slot` ไม่อยู่ใน 6 ตัว (`Wobbling`/`Walking`/`Sitting`/`Happy`/`Sad`/`Evolution`) หรือไม่ valid สำหรับ stage นั้น |
| 400 | `PET_NOT_READY` | วาง pet type ที่ sprite ยังไม่ครบทุก stage |
| 400 | `POSITION_OUTSIDE_ZONE` | จุดที่วางอยู่นอก `zone_id` ที่ส่งมา |
| 409 | `PET_TYPE_IN_USE` | DELETE pet type ที่ยังถูกวางในห้อง |
| 409 | `ZONE_ALREADY_HAS_PET` | วาง pet ตัวที่ 2 ในห้องเดิม — ✅ **เปิดใช้แล้ว 2026-09-04** (PM เคาะ 1 room = 1 pet) pre-check + partial unique index `uq_room_pet_one_per_zone` |
| 400 | `ZONE_NOT_ROOM` | วางใน zone ที่ `zone_type != 'room'` (meeting / private / block / spawn / teleport / spotlight) — PM 2026-09-04 |
| 400 | `POSITION_BLOCKED_BY_ZONE` | จุดวางตกใน zone `meeting` / `private` ของ map เดียวกัน **แม้ zone นั้นจะซ้อนอยู่ใน room** — PM 2026-09-04 (เช็กทั้งตอน place และ move) |
| 404 | `MAP_NOT_FOUND` · `ZONE_NOT_FOUND` · `ROOM_PET_NOT_FOUND` | map ไม่มี · zone ไม่ได้อยู่บน map นี้ · pet ไม่มี/ถูกลบแล้ว |
| 423 | `WORKSPACE_LOCKED` | เขียน placement โดยไม่ถือ workspace edit lock |
| 422 | `INVALID_XP_CONFIG` | validate config ไม่ผ่าน — แนบ `{field, reason}` |

> **transparency ไม่มี error code** — ตาม PM (ข้อ 6) ส่งกลับเป็น `data.warnings: ["NO_TRANSPARENCY"]` พร้อม HTTP 200 upload สำเร็จปกติ

---

## Realtime Events

publish ผ่าน `ZoneEventPublisher` ที่มีอยู่ (Redis channel `vo:zone`) → zyra-ws forward เข้า workspace room

| Type | Payload | ยิงเมื่อ |
|---|---|---|
| `pet_spawned` | `{map_id, pet: {...}}` | admin วาง pet |
| `pet_moved` | `{map_id, pet_id, tile_x, tile_y}` | admin ลากย้าย |
| `pet_renamed` | `{map_id, pet_id, name}` | admin เปลี่ยนชื่อ |
| `pet_removed` | `{map_id, pet_id}` | admin ลบ |
| `pet_stage_changed` | `{map_id, pet_id, from, to}` | XP ข้าม threshold (เล่น `Evolution`) |
| `pet_xp_changed` | `{map_id, pet_id, xp, mood}` | ได้ XP (throttle ฝั่ง service) |

> ✅ **4 event ฝั่ง admin (`pet_spawned` / `pet_moved` / `pet_renamed` / `pet_removed`) publish จริงแล้ว 2026-09-04** — ยืนยันด้วย `redis-cli SUBSCRIBE vo:zone` ระหว่าง live-test (envelope `{workspace_id, type, payload}` เหมือน event เดิม) · `pet_spawned.pet` คือ `RoomPet` เต็มตัว · `pet_renamed.name` = ชื่อที่แสดงจริงหลังเปลี่ยน (ล้าง custom แล้วได้ชื่อ pet type) · publish เป็น best-effort หลัง commit — Redis ล่ม placement ยังสำเร็จ (log warn) · อีก 2 event (`pet_stage_changed` / `pet_xp_changed`) รอ PR 9

> ✅ **zyra-ws relay ทำแล้ว** [zyra-ws #29](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/29) (2026-09-04) — 6 type ผ่าน `BroadcastZoneEvent` แบบ pure relay ไม่มี mirror

**สิ่งที่ต้องทำใน zyra-ws** (ทำแล้ว ดูด้านบน): เพิ่ม 6 type นี้ใน handler ที่ subscribe `vo:zone` — ปัจจุบันรู้จักแค่ `zone_claim_changed`, `map_object_changed`, `map_updated` type ที่ไม่รู้จักจะถูกทิ้งเงียบ ๆ

⚠️ gotcha ที่เคยเจอ: ถ้า zyra-api start ผิด CWD จะไม่ได้ `INTERNAL_API_SECRET` แล้ว ws join 401 ทั้งหมด — event จะดูเหมือน "ไม่ถูก publish" ทั้งที่ publish ปกติ ([[vo-realtime-redis-bus]])

---

## S3 Keys (rule 11 — S3 only)

```
static/pet/{petTypeID}/thumbnail.png
static/pet/{petTypeID}/{stage}/{slot}_{uuid}.png
```

`{uuid}` ต่อท้ายทุกครั้งที่ upload ใหม่ **จำเป็น** ไม่ใช่ของฟุ่มเฟือย — key ซ้ำทำให้ CDN ยัง serve รูปเก่าหลัง replace (ปัญหาเดิมของ avatar spritesheet) หลัง upload สำเร็จให้ `DeleteObject(KeyFromURL(oldURL))` ในไฟล์เดิม

---

## FE — `lib/api/pets.ts`

```ts
// admin
listPetTypes(params: ListPetTypesParams): Promise<PetTypeListResponse>
createPetType(body: CreatePetTypeBody): Promise<PetTypeResponse>
getPetType(id: string): Promise<PetTypeDetailResponse>
updatePetType(id: string, body: UpdatePetTypeBody): Promise<PetTypeResponse>
deletePetType(id: string): Promise<DeletePetTypeResponse>
uploadPetAnimation(id: string, stage: PetStage, slot: string, form: FormData): Promise<UploadAnimationResponse>
deletePetAnimation(id: string, stage: PetStage, slot: string): Promise<BaseResponse>

// xp config
getPetXPConfig(): Promise<PetXPConfigResponse>
updatePetXPConfig(body: PetXPConfig): Promise<PetXPConfigResponse>
listPetXPConfigHistory(): Promise<PetXPConfigHistoryResponse>
restorePetXPConfig(version: number): Promise<PetXPConfigResponse>

// placement — Map Editor drag-drop (SC-PM-05)
listMapPets(mapId: string): Promise<MapPetListResponse>
placeMapPet(mapId: string, body: PlaceMapPetBody): Promise<MapPetResponse>
updateMapPet(mapId: string, petId: string, body: UpdateMapPetBody): Promise<MapPetResponse>
removeMapPet(mapId: string, petId: string): Promise<BaseResponse>

// member — ห้ามชี้ /api/admin/*
getPetXPConfigForUser(): Promise<PetResponse<PetXPConfigPublic>>   // ✅ มีแล้ว (lib/api/pets.ts)
listWorkspacePets(workspaceId: string): Promise<WorkspacePetListResponse>
playWithPet(workspaceId: string, petId: string): Promise<PlayWithPetResponse>
```

- upload ใช้ `authFetchForm` (FormData), ที่เหลือ `authFetch` — ตาม `lib/api/client.ts`
- TanStack Query key: `["pet-types", params]`, `["pet-type", id]`, `["pet-xp-config"]`, `["map-pets", mapId]`

---

## แบ่งเป็น PR (task sizing ตาม rule 01)

| # | PR | ขึ้นกับ |
|---|---|---|
| 1 | `feat(api): pet type CRUD + migration 77` (SC-PM-01/02) | — |
| 2 | `feat(api): pet animation upload + grid validation` (SC-PM-03/07) | 1 |
| 3 | `feat(api): pet xp config + version history` (SC-PM-04) | 1 |
| 4 | `feat(app): pet library + stage manager UI` | 1, 2 |
| 5 | `feat(app): xp config form` | 3 |
| 6 | `feat(api): room pet placement + realtime` (SC-PM-05) | 1 |
| 7 | `feat(ws): forward pet_* events` | 6 |
| 8 | `feat(app): pet drag-drop ใน Map Editor` | 6 |
| 9 | `feat(api): xp earning engine + ledger` | 3, 6 |

**ไม่มี PR ไหนถูก block แล้ว** — แบ่งงานให้ dev 2 คนพร้อมตารางเวลา: [work-split.md](work-split.md)

---

## คำถามที่ยังค้าง (ไม่บล็อกการเริ่ม)

**ต้องได้ก่อน merge PR 6 / 8**
1. กฎ **1 room = 1 pet** ยังบังคับไหม — default ปัจจุบัน: ไม่เปิด `uq_room_pet_one_per_zone`
2. วาง pet ใน Workspace **Template** แล้ว workspace ที่สร้างไปก่อนหน้าได้ pet ด้วยไหม

**ต้องได้ก่อน merge PR 9**
3. ~~mood ช่วง 48–72 ชม. เป็น state อะไร~~ — ✅ **ปิดแล้ว 2026-09-01: Neutral ยืดถึง 72 ชม.** (Sad เริ่ม > 72)
4. activity ตัวไหนนับ per-user ตัวไหนนับ per-room (ตารางที่เสนอไว้ข้างบน)
5. `xp_play_with_pet` — "เล่นกับ pet" คือ interaction แบบไหนใน VO (คลิก? emoji? เดินเข้าใกล้?) ยังไม่มี spec member-side

**ไม่บล็อก แต่ควรรู้**
6. ยืนยันชื่อ error code ที่เราตั้งเอง: `INVALID_DIMENSIONS`, `INVALID_DIRECTION_ROWS`, `FRAME_ROW_MISMATCH` (ความหมายของ 2 ตัวหลังเปลี่ยนแล้วตาม spec 2026-09-01)
7. `Max` ใน card = เพดานที่ admin ตั้งได้ (ตีความแบบนี้) หรือเพดาน XP ต่อวัน?
8. activity toggle เปิด/ปิด ที่เห็นใน Figma ต้องมีจริงไหม (เผื่อ `enabled` ไว้แล้ว)
9. Adult / Evolved required slots — อนุมานว่าเหมือน Baby (Figma ไม่มี frame ที่โชว์ตรง ๆ)

---

## Reference

- [spec.md](spec.md) · [pm-discussion-notes.md](pm-discussion-notes.md) · [ux-ui.md](ux-ui.md)
- Precedent ในโค้ด: `tb_avatar` (`internal/database/postgres.go:37`), `avatar_service.go` (PNG validate + S3), `cache/zone_events.go` (realtime), `internal/router/router.go:485` (admin route group)
