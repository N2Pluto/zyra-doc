# Pet Management — DB Schema & API Contract

> **สถานะ: design doc — ยังไม่แตะไฟล์จริง** (ไม่มี migration/Go/TS ถูกเขียน) ใช้ review ก่อน implement
> อ้างอิง: [spec.md](spec.md) (แก้ตามคำตอบ PM แล้ว) · [pm-discussion-notes.md](pm-discussion-notes.md) (decision log) · [work-split.md](work-split.md) (แผนแบ่งงาน)
> Migration ถัดไปที่ว่าง: **77** (ล่าสุดในโปรเจกต์คือ `76_user_security_sessions.sql`)
>
> **อัปเดต 2026-08-17 — ✅ ข้อ 2 กับ ข้อ 5 ปิดแล้ว** schema ข้างล่างแก้ตามคำตอบจริงแล้ว ไม่มีจุด 🔴 เหลือ

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
                             CHECK (direction_rows >= 1),  -- ⏸ ค่าที่ยอมรับจริงรอดู sprite จาก artist
    frame_width  INT         NOT NULL,          -- = sprite_width  / frame_count    (คำนวณตอน upload)
    frame_height INT         NOT NULL,          -- = sprite_height / direction_rows (คำนวณตอน upload)
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (pet_type_id, stage, slot)
);

CREATE INDEX IF NOT EXISTS idx_pet_animation_type ON tb_pet_animation (pet_type_id);
```

- **spritesheet เป็น grid** (ข้อ 2 — ยึด Figma): คอลัมน์ = frame, แถว = direction → ต้องหารลงตัวทั้ง 2 แกน
  - `frame_width  = sprite_width  / frame_count`
  - `frame_height = sprite_height / direction_rows`

### ⏸ ค่า `direction_rows` + ลำดับแถว — รอดู sprite จริงจาก artist ก่อน

**ยังไม่ล็อก** — ตั้งใจจะให้เป็น `1` หรือ `4` (VO orthogonal-only) และเรียงแถวตาม avatar เดิม แต่ต้องเห็นไฟล์จริงก่อนว่า artist ทำมาแบบไหน

สมมติฐานที่ตั้งไว้ (ยังไม่ยืนยัน):

| row | ทิศ | ที่มา |
|---|---|---|
| 0 | `down` (ใต้) | `AVATAR_DIR_ROW` ใน `zyra-app/zyra-engine/avatar-frames.ts:26` |
| 1 | `left` (ตก) | |
| 2 | `right` (ออก) | |
| 3 | `up` (เหนือ) | |

| slot | คาดว่า direction_rows |
|---|---|
| `Walking`, `Sitting` | 4 |
| `Wobbling`, `Evolution` | 1 |
| `Happy`, `Sad` | 1 |

**สิ่งที่ยังทำได้เลยโดยไม่ต้องรอ** — คอลัมน์ `direction_rows INT` เข้า migration 77 ได้เลยไม่ว่าคำตอบจะเป็นอะไร เพราะสิ่งที่เปลี่ยนคือ **CHECK constraint กับ const ลำดับแถวใน Go เท่านั้น**:

- ใส่ CHECK แบบหลวม (`>= 1`) ไปก่อน → รัดให้แคบทีหลังด้วย `ALTER TABLE … DROP CONSTRAINT … ADD CONSTRAINT …` หนึ่งบรรทัด
- **อย่าใส่ `CHECK (direction_rows IN (1, 4))` ตั้งแต่แรก** — ถ้า artist ส่ง 8 ทิศมาจะ insert ไม่เข้าและต้อง migration แก้ ขณะที่การรัดทีหลังไม่มีความเสี่ยง (ข้อมูลที่มีอยู่ผ่าน constraint ใหม่แน่นอนถ้าค่าจริงแคบกว่า)
- ลำดับแถว: เขียนเป็น const ที่ **import จาก `AVATAR_DIR_ROW`** ตั้งแต่แรก ถ้า artist ทำมาไม่ตรง ค่อยตัดสินว่าจะขอให้แก้ไฟล์ หรือเพิ่ม mapping แยก
- `frame_width`/`frame_height` **เก็บ** ไม่ derive — client ต้องใช้ทุกเฟรมเพื่อ slice spritesheet ถ้าไม่เก็บต้อง decode PNG ใหม่ทุก request (ค่าถูก validate ให้หารลงตัวตอน upload อยู่แล้ว จึงไม่ขัดกัน)
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
    "neutral": { "within_hours": 48, "xp_rate_percent": 100 },
    "sad":     { "after_hours":  72, "xp_rate_percent": 50  }
  }
}
```

- `enabled` ใส่ไว้ตั้งแต่แรกเพราะ Figma มี toggle ต่อ activity (ข้อ 4 ที่ยังค้าง) — ถ้าไม่ต้องใช้ ก็ปล่อย `true` ทิ้งไว้ ไม่มี cost แต่ถ้าต้องใช้แล้วไม่มี ต้องเขียน migration แก้ JSONB ทุก row
- `Max` จาก card ไม่ได้เก็บใน DB — เป็น **validation constant ใน Go** (เพดานที่ admin กรอกได้) ไม่ใช่ข้อมูลที่ config เก็บ
- prune history: หลัง insert version ใหม่ ลบ version ที่เก่ากว่า 10 ล่าสุดใน tx เดียวกัน

### 4. `tb_room_pet` — pet instance ในห้อง (SC-PM-05)

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
≤ 48 ชม.       → neutral (×100%)
> 48 ชม.       → ???  ⚠️ ช่วง 48–72 ชม. ไม่มี state ใน card
> 72 ชม.       → sad     (×50%)
```

**ตอนนี้ implement เป็น `> 48 ชม. = sad`** (Sad เริ่มที่ 48 ไม่ใช่ 72) เพราะเป็นการตีความเดียวที่ไม่มีช่องว่าง — แต่ถ้า PM ตอบว่า Neutral ยืดถึง 72 ชม. ก็แก้เลขเดียวใน Go const **ต้องถามก่อน merge**

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

### Member — `/api/user/*` (UserGuard)

ตาม `.claude/rules/15-member-api-separation.md` — member **ห้าม**เรียก `/api/admin/*`

| Method | Path | คำอธิบาย |
|---|---|---|
| GET | `/api/user/workspaces/:workspaceId/pets` | pet ในชั้นที่กำลังเข้า + derived `stage`/`mood` + animation URL ครบ (VO client) |
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
| `file` | PNG spritesheet (≤ 1 MB, ≤ 1000×1000, `width % frame_count = 0`, `height % direction_rows = 0`) |
| `frame_count` | `1`–`64` (จำนวนคอลัมน์) |
| `frame_rate` | `4`–`24` |
| `direction_rows` | `1` หรือ `4` เท่านั้น (`4` = down/left/right/up ตามลำดับ `AVATAR_DIR_ROW`) |

```json
{
  "status": 200,
  "message": "success",
  "data": {
    "sprite_url": "https://pub-b74ca….r2.dev/static/pet/9f3c…/adult/Sitting_7c1e….png",
    "frame_width": 96, "frame_height": 128, "direction_rows": 4,
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
| 400 | `INVALID_DIMENSIONS` ⚠️ | width หรือ height > 1000 (ชื่อ code รอ PM ยืนยัน) |
| 400 | `INVALID_FRAME_COUNT` | นอกช่วง 1–64 |
| 400 | `INVALID_FRAME_RATE` | นอกช่วง 4–24 |
| 400 | `INVALID_DIRECTION_ROWS` ⚠️ | ไม่ใช่ `1` หรือ `4` |
| 400 | `FRAME_SIZE_MISMATCH` | `width % frame_count ≠ 0` — แนบ `{width, frame_count}` ให้ FE ขึ้นข้อความพร้อมเลข |
| 400 | `FRAME_ROW_MISMATCH` ⚠️ | `height % direction_rows ≠ 0` — แนบ `{height, direction_rows}` |
| 400 | `INVALID_SLOT` | `slot` ไม่อยู่ใน 6 ตัว (`Wobbling`/`Walking`/`Sitting`/`Happy`/`Sad`/`Evolution`) หรือไม่ valid สำหรับ stage นั้น |
| 400 | `PET_NOT_READY` | วาง pet type ที่ sprite ยังไม่ครบทุก stage |
| 400 | `POSITION_OUTSIDE_ZONE` | จุดที่วางอยู่นอก `zone_id` ที่ส่งมา |
| 409 | `PET_TYPE_IN_USE` | DELETE pet type ที่ยังถูกวางในห้อง |
| 409 | `ZONE_ALREADY_HAS_PET` | วาง pet ตัวที่ 2 ในห้องเดิม — **ยังไม่เปิดใช้** รอ PM ยืนยันกฎ 1 room = 1 pet |
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

**สิ่งที่ต้องทำใน zyra-ws**: เพิ่ม 6 type นี้ใน handler ที่ subscribe `vo:zone` — ปัจจุบันรู้จักแค่ `zone_claim_changed`, `map_object_changed`, `map_updated` type ที่ไม่รู้จักจะถูกทิ้งเงียบ ๆ

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
3. mood ช่วง 48–72 ชม. เป็น state อะไร (ตอนนี้ตีความว่า sad เริ่มที่ 48)
4. activity ตัวไหนนับ per-user ตัวไหนนับ per-room (ตารางที่เสนอไว้ข้างบน)
5. `xp_play_with_pet` — "เล่นกับ pet" คือ interaction แบบไหนใน VO (คลิก? emoji? เดินเข้าใกล้?) ยังไม่มี spec member-side

**ไม่บล็อก แต่ควรรู้**
6. ยืนยันชื่อ error code ที่เราตั้งเอง: `INVALID_DIMENSIONS`, `INVALID_DIRECTION_ROWS`, `FRAME_ROW_MISMATCH`
7. `Max` ใน card = เพดานที่ admin ตั้งได้ (ตีความแบบนี้) หรือเพดาน XP ต่อวัน?
8. activity toggle เปิด/ปิด ที่เห็นใน Figma ต้องมีจริงไหม (เผื่อ `enabled` ไว้แล้ว)
9. Adult / Evolved required slots — อนุมานว่าเหมือน Baby (Figma ไม่มี frame ที่โชว์ตรง ๆ)

---

## Reference

- [spec.md](spec.md) · [pm-discussion-notes.md](pm-discussion-notes.md) · [ux-ui.md](ux-ui.md)
- Precedent ในโค้ด: `tb_avatar` (`internal/database/postgres.go:37`), `avatar_service.go` (PNG validate + S3), `cache/zone_events.go` (realtime), `internal/router/router.go:485` (admin route group)
