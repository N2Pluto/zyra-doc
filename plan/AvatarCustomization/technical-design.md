# Avatar Customization — Technical Design

> **⚠ ร่างต้นฉบับ 2026-10-05 — บางส่วนถูกแทนแล้ว (หัวเอกสารนี้เพิ่ม 2026-10-22 ตอนนำขึ้น git ไฟล์นี้เคยอยู่ในเครื่องเดียว):**
> - **ชุดเดียวทุก workspace → ชุดแยกต่อ workspace** (มติ C-14 · [spec.md](spec.md) §8.3, §9.2) · `tb_user_outfit` ใน §5 ด้านล่างไม่มี `workspace_id` — ของจริงเป็น PK `(user_id, workspace_id)` (zyra-api migration 118 + 119)
> - **slot ชุดเดิม (11 slot) → 18 หมวดตาม Figma** (มติ Q-5) · ค่าคงที่จริงอยู่ที่ `zyra-api/internal/model/avatar_part.go` + `zyra-app/lib/avatar-part/constants.ts`
> - **"ไม่มีหน้าให้ admin อัปโหลด" → admin อัปโหลดได้** ตาม ClickUp/Figma ของ [Admin](<../[Module] Avatar & Accessories Management (Admin)/technical-design.md>) (ทำแล้ว)
> - **Skin = Default ไม่อัปโหลด + 5 เฉด** (มติ C-13, Q-4b — [spec.md](spec.md) §9.3)
> - ลิงก์ `spec.md#…` ในไฟล์นี้หมายถึง spec ต้นฉบับ (ร่าง 2026-10-08) ที่ยังไม่ขึ้น git — [spec.md](spec.md) ปัจจุบันเป็นฉบับของ rif (SC-AV-02)
> - ส่วนที่ยังใช้ได้: palette swap / สี key (§3), algorithm (§3.5), bake + cache (§6)

> **สถานะ:** Draft 2026-10-05 · ยังไม่ implement · **repo:** zyra-api, zyra-app
> **คู่กับ:** [spec.md](spec.md) (มติ + ข้อค้าง + acceptance criteria)

## 1. ภาพรวม

```
admin อัปโหลดชิ้นส่วน (PNG วาดด้วย key color) ─┐
admin จัดการ palette (ชุดสี) ──────────────────┤
                                               ▼
member: หน้าแต่งตัว — preview ประกอบสดใน browser (recolor + ซ้อน layer)
        └─ Save → PUT /api/user/me/outfit
                    └─ zyra-api: validate → recolor → ซ้อน layer → เติมเฟรมกะพริบ → อัปขึ้น R2
                         → tb_user_outfit.walk_url / sit_url
VO:  GET /api/user/me/outfit → walk_url / sit_url
     → ใช้ทางเดิมทั้งหมด (avatar_url ใน ws, StoredAvatar, scene.ts)
```

**ทำไม bake ฝั่ง server:** ระบบปัจจุบันผูกกับสัญญา "1 URL ชีทต่อคน" อยู่ราว 36 ไฟล์ (zyra-app 24, zyra-ws 8, zyra-api 4) — ws ส่ง `AvatarURL` ตัวเดียว (`zyra-ws/internal/hub/message.go:205` `Player.AvatarURL`), VO ตัดเฟรมจาก texture เดียว (`zyra-engine/pixi-game/utils.ts` `buildFrameCache`) · bake แล้วได้ output รูปแบบเดิม → ws ไม่ต้องแก้ · โค้ดเดิน/นั่งใน `scene.ts` ไม่ต้องแตะ · peer โหลด 2 ไฟล์ต่อคนเหมือนเดิม

## 2. Sheet layout v2

| | ค่า | เหตุผล |
|---|---|---|
| ขนาดเฟรม | **48×48** วาด 1:1 | = `PLAYER_DISPLAY_W/H` (`zyra-engine/constants.ts:190`) · ถ้าวาดใหญ่แล้วย่อแบบ nearest เส้นหลับตา 1px จะหายบางเฟรม · ซูมสูงสุด 3× (`CAMERA_ZOOM_MAX`) ขยายแบบ nearest ยังคม |
| แถว | 4: down, left, right, up | เหมือนเดิม (`AVATAR_DIR_ROW`) |
| ชีทเดิน (output) | **5 col = 240×192** | col 0–3 เดิน (col 1 = ยืน) · **col 4 = ยืนหลับตา** |
| ชีทนั่ง (output) | **5 col = 240×192** | col 0–2 นั่ง · col 3 ลุก · **col 4 = นั่งหลับตา** |

**ชิ้นส่วน (input) วาดแค่ 4 col (192×192)** — server เติม col 4 ให้เองโดย copy เฟรมยืน (เดิน col 1 / นั่ง col 2)
**ยกเว้น `eyes`** ต้องวาด 5 col (240×192) — col 4 = ตาปิด (ใช้ skin channel วาดเปลือกตา) · แถว up ไม่เห็นตา วาด col 4 เหมือน col 1 ได้เลย
→ ศิลปินวาดเฟรมหลับตาแค่ชิ้น `eyes` ชิ้นเดียวต่อแบบ ไม่ต้องวาดซ้ำทุกชิ้น

### Renderer (zyra-app) — รองรับทั้งชีทเก่าและใหม่

- `buildFrameCache` (`zyra-engine/pixi-game/utils.ts:732`): `fs = floor(height / 4)`, `cols = floor(width / fs)` แทน `fs = width / 4` → ชีทเก่า 4×4 (192² หรือ 1000²) ได้ 4 col, ชีทใหม่ได้ 5 col · `FrameCache` เพิ่ม `cols` · `getFrame` clamp col ด้วย `cols - 1`
- `avatar-frames.ts` เพิ่ม `AVATAR_BLINK_COL = 4`
- **กะพริบตา:** timer ต่อ player (ตัวเอง + peer) สุ่มรอบ 2–6 วินาที ปิดตา ~120 ms · กะพริบเฉพาะเมื่อ
  - ยืนนิ่ง (ตอนนี้ใช้ `IDLE_COL`) หรือนั่งเสร็จแล้ว (ค้างที่ col 2)
  - ทิศไม่ใช่ up
  - `cache.cols > AVATAR_BLINK_COL` (ชีทเก่าไม่กะพริบ — ไม่พัง)
- แก้แค่จุดเลือก column ใน `_renderUpdate` (`scene.ts:4386-4400`) และ render ของ peer (`scene.ts:4646-4675`) · **ไม่แตะ state เดิน/นั่ง/ตำแหน่ง** · ไม่ส่งอะไรผ่าน ws (แต่ละเครื่องสุ่มเอง เป็นแค่ความสวยงาม)

## 3. ระบบสี — palette swap

### 3.1 หลักการ

- ศิลปินวาดส่วนที่เปลี่ยนสีได้ด้วย **key color** — สีที่จองไว้ตายตัว **4 เฉดต่อ channel** (1 highlight · 2 base · 3 shadow · 4 deep)
- ตอนประกอบ: pixel ที่ตรง key ของ channel X เฉด n **เป๊ะ** → แทนด้วยเฉด n ของ palette ที่ผู้ใช้เลือกให้ channel X
- pixel อื่น = **สีตายตัว** ไม่เปลี่ยน (เส้นขอบ, ตาขาว, กระดุม, โลโก้) · ชุด special วาดสีจริงทั้งชิ้นได้ (ไม่มี key เลย = ไม่มีตัวเลือกสี)

```
ชิ้น top (วาดด้วย key)        palette "Navy" ที่ผู้ใช้เลือกให้ primary        ผลลัพธ์
#FFA0A0  primary-1   ──►   [ #5A7BC4, #2E4A8F, #1C2F5E, #0E1830 ][0]   ──►  #5A7BC4
#FF0000  primary-2   ──►                                       [1]   ──►  #2E4A8F
#A00000  primary-3   ──►                                       [2]   ──►  #1C2F5E
#1A1A1A  (สีตายตัว)  ──►   ไม่เปลี่ยน                                  ──►  #1A1A1A
```

**ทำไมไม่ทำมือทีละสี:** ทรงผม 20 แบบ × 12 สี = 240 แบบ × 2 ชีท = **480 ไฟล์** · palette swap = **40 ไฟล์ + 12 แถวใน DB** · เพิ่มสีใหม่ = เพิ่ม 1 แถว ไม่ต้องวาด · เสื้อ 1 ตัวมี 2 channel × 16 สี = 256 แบบโดยไม่ต้องวาดเพิ่ม · ผม/คิ้ว/หนวดสีตรงกันเสมอเพราะใช้ palette เดียวกัน

### 3.2 Channel + key color (ร่าง)

เลือกสีจัดที่ไม่น่าถูกใช้เป็นสีจริงในงาน pixel art · ส่งให้ศิลปินเป็นไฟล์ palette `zyra-avatar-keys.gpl` (เปิดใน Aseprite ได้)

| channel | ใครเลือก | ramp ของ palette | key 1 | key 2 | key 3 | key 4 |
|---|---|---|---|---|---|---|
| `skin` | 1 ครั้งต่อชุด (ทั้งตัว) | skin | `#FFA0FF` | `#FF00FF` | `#A000A0` | `#500050` |
| `hair` | 1 ครั้งต่อชุด (ผม คิ้ว หนวด) | hair | `#A0FFFF` | `#00FFFF` | `#00A0A0` | `#005050` |
| `eye` | 1 ครั้งต่อชุด | eye | `#FFFFA0` | `#FFFF00` | `#A0A000` | `#505000` |
| `primary` | ต่อ slot | cloth | `#FFA0A0` | `#FF0000` | `#A00000` | `#500000` |
| `secondary` | ต่อ slot | cloth | `#A0FFA0` | `#00FF00` | `#00A000` | `#005000` |

กฎสำหรับศิลปิน:
- 1 channel ใช้ได้ไม่เกิน 4 เฉดนี้เท่านั้น · ห้าม anti-alias ระหว่าง key กับสีอื่น
- alpha ต้องเป็น 0 หรือ 255 เท่านั้น (ไม่มีโปร่งครึ่ง ๆ)
- สีตายตัวห้ามใกล้ key (ต่างกันทุก channel RGB ไม่เกิน 8 = ถือว่าเพี้ยน → reject)

### 3.3 การตรวจตอน admin อัปโหลด (zyra-api)

1. PNG · ≤ 1 MB · ขนาด 192×192 หรือ 240×192 (`eyes` ต้อง 240×192)
2. ทุก pixel alpha ∈ {0, 255}
3. pixel ทึบที่ตรง key → จดว่าใช้ channel ไหน · pixel ที่ "ใกล้ key แต่ไม่ตรง" → reject พร้อมบอก (x, y) และ key ที่ใกล้
4. channel ที่เจอต้องอยู่ในรายการที่ slot นั้นอนุญาต ([spec §Slots](spec.md#slots-เสนอ))
5. เก็บผลลง `color_channels` อัตโนมัติ — admin ไม่ต้องติ๊กเอง · อัปโหลดชีทใหม่ → `art_version + 1`

### 3.4 การเลือกสีในหน้าแต่งตัว

- `skin` / `hair` / `eye` เลือกครั้งเดียว ใช้กับทุกชิ้นที่มี channel นั้น
- `primary` / `secondary` เลือกแยกต่อ slot · แสดงเฉพาะ channel ที่ชิ้นนั้นมีจริง (`color_channels`)
- ไม่ได้เลือก → ใช้ palette default ของ ramp นั้น
- palette ก็มี general/special + ช่วงเวลาได้ (เช่น สีฮาโลวีน)

### 3.5 Algorithm (เหมือนกันทั้ง Go และ TS)

```
for row in 0..3:                                   # ทิศ
  for slot in layer_order[dir(row)]:               # ล่าง → บน
    part = outfit[slot]; if none: continue
    for col in 0..4:
      src = col < part.cols ? part.frame(row, col) : part.frame(row, IDLE_COL_OF_SHEET)
      for each pixel p in src where p.a == 255:
        if key = KEY_INDEX[p.rgb]:  p.rgb = palette_of(slot, key.channel).shades[key.shade]
        dst[row, col] = p                          # ทับตรง ๆ (alpha 0/255 ไม่ต้อง blend)
```

- ค่าคงที่ (key, slot, channel ที่ slot อนุญาต, layer order, ขนาดเฟรม, `BAKE_VERSION`) ประกาศ **ที่เดียว** ใน Go (`internal/avatar/config.go`) แล้วส่งให้ frontend ผ่าน `GET /api/user/avatar/config` → preview ในหน้าแต่งตัวใช้ค่าชุดเดียวกับ bake
- **Golden test:** fixture PNG + outfit + ภาพคำตอบชุดเดียวกัน commit ไว้ทั้ง `zyra-api/internal/avatar/testdata/golden/` และ `zyra-app` → Go bake กับ TS compose ต้องได้ pixel ตรงกับภาพคำตอบ (AC6)

## 4. Layer order

```
default: body, eyes, bottom, shoes, top, facial_hair, hair, glasses, hat, accessory
```

- config รองรับ override ต่อทิศ (`layer_order.up = [...]`) — v1 ใช้ order เดียวก่อน ถ้าศิลปินเจอเคสที่ต้องสลับ (เช่น ผมยาวจากด้านหลังทับคอเสื้อ) ค่อยเพิ่ม override
- `costume` วางที่ตำแหน่งของ `top` · `occupies_slots` บอกว่าทับ slot ไหน (slot เหล่านั้นต้องว่าง)

## 5. DB schema (ร่าง migration)

> ⚠️ GitOps deploy รันแค่ embedded DDL ใน `zyra-api/internal/database/postgres.go` (`migrations/*.sql` ไม่ auto-run — ดู comment ที่ `postgres.go:355`) → ตารางใหม่ต้องใส่**ทั้ง** migration file และ embedded DDL · ระบบเดิมเคยพลาดจุดนี้ (`tb_user_avatar` ไม่อยู่ใน embedded DDL)

```sql
-- migration: avatar customization (v2)
CREATE TABLE IF NOT EXISTS tb_avatar_part (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  slot            VARCHAR(20)  NOT NULL,                    -- body|eyes|bottom|shoes|top|facial_hair|hair|glasses|hat|accessory|costume
  name            VARCHAR(100) NOT NULL,
  walk_sheet_url  TEXT,
  sit_sheet_url   TEXT,
  thumbnail_url   TEXT,
  color_channels  TEXT[]       NOT NULL DEFAULT '{}',       -- จากการ scan ตอนอัปโหลด
  occupies_slots  TEXT[]       NOT NULL DEFAULT '{}',       -- costume เท่านั้น
  category        VARCHAR(20)  NOT NULL DEFAULT 'general',  -- general|special
  available_from  TIMESTAMPTZ,
  available_until TIMESTAMPTZ,
  status          VARCHAR(20)  NOT NULL DEFAULT 'hidden',   -- active|hidden
  is_default      BOOLEAN      NOT NULL DEFAULT FALSE,
  sort_order      INT          NOT NULL DEFAULT 0,
  art_version     INT          NOT NULL DEFAULT 1,
  is_deleted      BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tb_avatar_part_slot ON tb_avatar_part (slot) WHERE NOT is_deleted;
CREATE UNIQUE INDEX IF NOT EXISTS ux_tb_avatar_part_default
  ON tb_avatar_part (slot) WHERE is_default AND NOT is_deleted;

CREATE TABLE IF NOT EXISTS tb_avatar_palette (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  ramp            VARCHAR(20)  NOT NULL,                    -- skin|hair|eye|cloth
  name            VARCHAR(100) NOT NULL,
  shades          TEXT[]       NOT NULL CHECK (array_length(shades, 1) = 4),  -- hex 4 เฉด ตามลำดับ key 1–4
  category        VARCHAR(20)  NOT NULL DEFAULT 'general',
  available_from  TIMESTAMPTZ,
  available_until TIMESTAMPTZ,
  status          VARCHAR(20)  NOT NULL DEFAULT 'active',
  is_default      BOOLEAN      NOT NULL DEFAULT FALSE,
  sort_order      INT          NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_tb_avatar_palette_default
  ON tb_avatar_palette (ramp) WHERE is_default;

CREATE TABLE IF NOT EXISTS tb_user_outfit (
  user_id        VARCHAR      PRIMARY KEY REFERENCES tb_user(id) ON DELETE CASCADE,
  outfit         JSONB        NOT NULL,
  bake_hash      VARCHAR(64)  NOT NULL,
  walk_url       TEXT         NOT NULL,
  sit_url        TEXT         NOT NULL,
  thumbnail_url  TEXT         NOT NULL,
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
```

`outfit` JSON:

```json
{
  "colors": { "skin": "<palette_id>", "hair": "<palette_id>", "eye": "<palette_id>" },
  "slots": {
    "body":   { "part_id": "<uuid>" },
    "eyes":   { "part_id": "<uuid>" },
    "top":    { "part_id": "<uuid>", "colors": { "primary": "<palette_id>", "secondary": "<palette_id>" } },
    "bottom": { "part_id": "<uuid>", "colors": { "primary": "<palette_id>" } },
    "hair":   { "part_id": "<uuid>" }
  }
}
```

## 6. Bake + cache

- **`bake_hash`** = sha256(`BAKE_VERSION` + outfit แบบ canonical + `id:art_version` ของทุกชิ้น + `shades` ของทุก palette ที่ใช้)
- R2 key แบบ content-addressed: `outfits/{bake_hash}/walk.png`, `sit.png`, `thumb.png` (thumb = เฟรมยืนหันหน้า ขยาย 4× nearest) → ชุดเหมือนกันใช้ไฟล์ร่วมกัน · มีไฟล์อยู่แล้วข้ามการ bake · cache แบบ immutable ได้
- **ผู้ใช้เดิม / ไม่เคยแต่งตัว (มติข้อ 5):** ไม่มีแถวใน `tb_user_outfit` → API ประกอบชุดจาก part + palette ที่เป็น default → ได้ hash เดียวกันทุกคน → bake ครั้งเดียวใช้ทั้งระบบ · **ไม่ต้อง backfill**
- **admin แก้ภาพ/สี/ซ่อนชิ้น:** ไม่ต้อง batch job — `GET /me/outfit` คำนวณ hash ใหม่จาก DB ปัจจุบัน ถ้าไม่ตรงกับที่เก็บไว้ → แทนชิ้นที่ถูกซ่อนตาม AC7 → bake ใหม่ → อัปเดตแถว (lazy re-bake) · เวลาที่ใช้ bake ภาพ 240×192 ต้องวัดจริงตอนทำ A2
- ไฟล์ใน `outfits/` ที่ไม่มีใครอ้างถึงเกิน 30 วัน → cron ลบ (ทำทีหลังได้ เหมือน `cmd/avatar-cleanup`)

## 7. API contract

ทุก response ใช้ `model.APIResponse` · member อยู่ใต้ `/api/user/*` เท่านั้น (rule 15)

### Member (UserGuard)

| Method | Path | ใช้ทำอะไร |
|---|---|---|
| GET | `/api/user/avatar/config` | slot, channel, key color, layer order, ขนาดเฟรม, `bake_version` |
| GET | `/api/user/avatar/parts` | ชิ้นที่ active (general + special ที่อยู่ในช่วงเวลา) |
| GET | `/api/user/avatar/palettes` | palette ที่ active |
| GET | `/api/user/me/outfit` | `{ outfit, walk_url, sit_url, thumbnail_url, bake_hash, is_default }` |
| PUT | `/api/user/me/outfit` | body = `outfit` (JSON เพราะเป็น nested) → validate → bake → คืน shape เดียวกับ GET |

ตรวจตอน PUT: slot บังคับครบ (เว้นที่ costume ทับ) · ชิ้นมีจริง ไม่ถูกลบ slot ตรง active · special อยู่ในช่วงเวลา (เว้นตามข้อค้าง 5) · costume → slot ที่ทับต้องว่าง · palette ตรง ramp ของ channel · key แปลก ๆ → 400

### Admin (AdminGuard + ตรวจ `admin.avatar.manage`)

| Method | Path |
|---|---|
| GET / POST | `/api/admin/avatar-parts` |
| GET / PATCH / DELETE | `/api/admin/avatar-parts/:id` |
| POST | `/api/admin/avatar-parts/:id/sheet` (form: `type` = walk\|sit, `file`) — ตรวจตาม §3.3 |
| POST | `/api/admin/avatar-parts/:id/thumbnail` |
| GET / POST | `/api/admin/avatar-palettes` |
| PATCH / DELETE | `/api/admin/avatar-palettes/:id` |

> ระบบเดิมมี RBAC `admin.avatar.manage` (`internal/rbac/catalog.go:90`) แต่ route ไม่ได้ตรวจ — route ใหม่ให้ตรวจ

## 8. zyra-app — จุดที่ต้องแก้

| เรื่อง | ไฟล์ |
|---|---|
| API (member) | `lib/api/avatar-outfit.ts` ใหม่ — config / parts / palettes / getMyOutfit / saveMyOutfit |
| API (admin) | `lib/api/admin-avatar-parts.ts` ใหม่ (แยกจาก member ตาม rule 15) |
| preview | `lib/avatar-compose.ts` ใหม่ — pure function recolor + ซ้อน layer บน canvas |
| localStorage | `lib/avatar-selection.ts` — **คง key `zyra_selected_avatar` และ shape `StoredAvatar` เดิม** (rule 15): `id = bake_hash`, `walking_spritesheet_url = walk_url`, `sitting_spritesheet_url = sit_url` → ไฟล์ที่อ่าน `StoredAvatar` อยู่ (~24 ไฟล์) ไม่ต้องแก้ |
| refresh จาก DB | หน้า loading (`hero-workspace-loading.tsx:384`) ต้องดึง `GET /me/outfit` **ก่อน** ต่อ ws ไม่งั้นรอบแรกหลัง release จะส่ง URL ชีทเก่าที่ค้างใน localStorage · VO mount (`hero-virtual-office.tsx:2194-2272`) เปลี่ยนจาก `listAvatarsForUser` เป็น `getMyOutfit` |
| renderer | `zyra-engine/avatar-frames.ts`, `zyra-engine/pixi-game/utils.ts`, `scene.ts` (§2) |
| หน้าแต่งตัว | `views/user/avatar-editor/` ใหม่ — แทน `change-character-modal.tsx`, ตัวเลือกใน `hero-workspace-enter.tsx`, `profile-form.tsx`, `vo-profile-panel.tsx` · **รอ Figma** |
| admin | `views/admin/avatar-parts/`, `views/admin/avatar-palettes/` ใช้ `AdminSidebar` · **รอ Figma** |
| default fallback | `/sprites/characters/Character_001*.png` → ชีท default ชุดใหม่ (export จากผล bake ชุด default) |
| flag | `NEXT_PUBLIC_AVATAR_V2` (build-time → ต้องใส่ GitHub Environment ทั้ง dev / uat / production) |

เครื่องมือ admin ที่ใช้ชีท bundled 4×4 (`object-composer.tsx`, `sit-test-dialog.tsx`, spawn icon ใน `hero-workspace-editor.tsx`) — v1 ให้ใช้ `Character_001` เดิมต่อไป ย้ายตอน cleanup

## 9. ลบระบบเดิม (release ถัดจากที่ v2 ขึ้น prod)

- **api:** `tb_avatar`, `tb_avatar_audit_log`, `tb_user_avatar` + trigger · route `/api/admin/avatars*`, `/api/user/avatars*`, `PUT /api/user/me/avatar-selection` · `avatar_service.go` / `avatar_handler.go` / `model/avatar.go` · `cmd/avatar-cleanup` · embedded DDL ใน `postgres.go` · **ย้าย `ErrAvatarTooLarge` / `ErrAvatarInvalidType` ออกก่อน เพราะ `pet_service.go` ใช้อยู่**
- **app:** `views/admin/avatar-management/`, `lib/api/avatars.ts`, `hooks/use-user-avatars.ts`, `avatar-preview-modal.tsx` (Phaser) + `zyra-engine/scenes/gather.scene.ts` ถ้าไม่มีที่อื่นใช้ · โค้ดที่ไม่มีใคร import (`zyra-engine/canvas-game/*`, `components/play-test/gather-scene.ts`)
- **อื่น ๆ:** `zyra-loadtest/k6/lib/api/user.js`, seed 41 avatar ใน `zyra-service/seed/`
- R2 prefix `avatars/` ลบหลังยืนยันว่าไม่มีอะไรอ้างถึง

## 10. zyra-ws

**ไม่แก้ protocol** — `avatar_url` ยังเป็น URL ชีทที่ใช้อยู่ (เดินหรือนั่ง) เหมือนเดิม · กะพริบตาไม่ผ่าน ws

## 11. ลำดับงาน (1 PR ต่อแถว)

| # | งาน | repo | เริ่มได้เมื่อ |
|---|---|---|---|
| P0 | art kit: `zyra-avatar-keys.gpl` + body template 48px + ชิ้นตัวอย่าง 1 ชิ้นต่อ slot | ศิลปิน | ได้คนวาด + ยืนยันขนาด/สี key |
| A1 | migration + embedded DDL + palette CRUD + part CRUD + scan/validate ตอนอัปโหลด + tests | api | ตอนนี้ |
| A2 | `internal/avatar`: config + bake + outfit GET/PUT + ชุด default + lazy re-bake + golden test | api | A1 |
| F1 | renderer: `buildFrameCache` อ่าน cols + กะพริบตา (ชีทเก่าไม่กะพริบ ไม่พัง) | app | ตอนนี้ (ใช้ชีททดสอบ) |
| F2 | admin Part + Palette Management | app | A1 + Figma |
| F3 | `lib/avatar-compose.ts` + golden test ให้ตรงกับ A2 | app | A2 |
| F4 | หน้าแต่งตัว member | app | F3 + Figma |
| F5 | ต่อ loading / lobby / profile / VO เข้ากับ outfit API หลัง flag | app | A2 + F4 |
| C1 | ลบระบบเดิม (§9) | api + app + loadtest + seed | v2 ขึ้น prod แล้ว |

**ติดอยู่:** คนวาด asset (P0) และ Figma (F2, F4) — ที่เหลือเริ่มคู่ขนานได้
