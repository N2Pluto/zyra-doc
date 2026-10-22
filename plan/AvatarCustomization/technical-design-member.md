# SC-AV-02 — Avatar Customization (Client) — Technical Design (ฝั่ง member)

> **สถานะ:** Draft v0.1 · 2026-10-22 · ยังไม่ implement · **repo:** zyra-api (หลัก), zyra-app (หลัก), zyra-ws (เล็กน้อย)
> **อ้างอิงโค้ดจริง:** `origin/develop` ของ zyra-api / zyra-ws / zyra-app ณ 2026-10-22 (หลัง merge งาน Admin api#179–#185) · migration ล่าสุดที่เกี่ยวข้อง `119_user_outfit_per_workspace`
> **ต่อยอดจาก:** [technical-design.md](technical-design.md) (ร่างต้นฉบับ 2026-10-05 ของระบบ paper-doll — Ten นำขึ้น git 2026-10-22) · ส่วนที่ต้นฉบับยังใช้ได้และเอกสารนี้ไม่ได้เขียนซ้ำ: §3.1–3.3 สี key / กฎศิลปิน, §9 ลบระบบเดิม · ส่วนที่เอกสารนี้**แทน**: API path (§7 ต้นฉบับ → §5 ที่นี่), `tb_user_outfit` (ต่อ workspace), สีเป็น hex + shade แทน palette id, ชีท output (§2 ต้นฉบับ → D-M7)
> **เอกสารคู่กัน:** [spec.md](spec.md) (requirement + มติ §8.3) · [ux-ui.md](ux-ui.md) (ค่า Figma) · ฝั่ง Admin: [technical-design.md](<../[Module] Avatar & Accessories Management (Admin)/technical-design.md>) · [data contract](<../[Module] Avatar & Accessories Management (Admin)/data/>)
> **หลักการ:** เอกสารนี้คือ **ฝั่ง member ของระบบ paper-doll เดียวกับ Admin** — ไม่สร้างระบบที่สอง · ใช้ schema / renderer / reset job ที่ merge แล้ว · ส่วนที่ต่างจากเอกสาร Admin มาจากมติใน spec §8.3 เท่านั้น

---

## 0. สรุป

| เรื่อง | ออกแบบ |
|---|---|
| เก็บชุด | `tb_user_outfit` (มีแล้ว) **ต่อ (user, workspace)** — 1 แถว = outfit JSON + URL ที่ bake แล้ว |
| API member | `GET /api/user/avatar/catalog` · `GET /api/user/avatar/outfit/default` · `GET`/`PUT /api/user/workspaces/:id/avatar/outfit` |
| แต่งตัว / preview | client render เองด้วย `lib/avatar-part/render.ts` (มีแล้ว — ใช้กับหน้า Admin) |
| บันทึก | server validate → normalize → **bake** เป็นชีท `walk` + `sit` 192×192 (4×4 เฟรม 48 px — layout เดียวกับ VO) + `thumb` → R2 → upsert |
| VO | ยังเป็น "URL เดียวต่อคน" — ใช้ `walk_url` / `sit_url` ที่ bake แล้วแทน `walking_spritesheet_url` ของ `tb_avatar` · คนอื่นเห็นผ่าน `moved.avatar_url` เดิม |
| Realtime | `outfit_updated` (ใหม่) + `outfit_reset` (มีแล้ว) ผ่าน Redis `vo:notify` → zyra-ws → socket ของ user ใน room ของ workspace นั้น |
| Skin | 5 เฉดของระบบ (ไม่อัปโหลด) บนชีท body ตัวเดียว · ramp เฉด Default ดูดจากชีท body |

**ต้องตัดสินก่อน implement:** D-M1 (บันทึกอัตโนมัติตาม Figma vs ปุ่มบันทึกตาม ClickUp), D-M2 (ค่า 5 เฉด — spec Q-4c), D-M3 (Slot preset ตาม Figma อยู่ใน scope ไหม) — ดู §13

---

## 1. Scope

**ทำ (member):** catalog · ชุดปัจจุบันต่อ workspace · บันทึก + bake · ใช้ชุดใน VO · realtime หลังบันทึก · รับ `outfit_reset` · หน้าแต่งตัว + entry point

**ไม่ทำ:** หน้า Admin / upload / validate ชีท / reset job / hard delete (merge แล้วฝั่ง Admin) · ลบระบบ `tb_avatar` เดิม (งานแยกหลังขึ้น prod — Admin TD §11) · mobile layout (ClickUp ติ๊ก Desktop — แต่ Figma มีเฟรม iPhone: spec Q-12)

---

## 2. Baseline บน `develop` (2026-10-22) — สิ่งที่ reuse

### 2.1 zyra-api

| ของ | ที่ | ใช้ยังไง |
|---|---|---|
| `tb_avatar_part` (+ `_variant`, `_audit`, `tb_avatar_reset_job`) | `migrations/118_avatar_parts_admin.sql` + embedded DDL `internal/database/postgres.go` | catalog อ่านจากตารางนี้ (`status='active' AND NOT is_deleted` + ช่วง `available_from..until`) |
| `tb_user_outfit` (`user_id`, **`workspace_id`**, `outfit` JSONB, `bake_hash`, `walk_url`, `sit_url`, `thumbnail_url`, `updated_at`) · PK `(user_id, workspace_id)` · GIN บน `outfit` | `migrations/119_user_outfit_per_workspace.sql` (Ten, commit `3f2bc64`, merge แล้ว — ตามมติ C-14) | ตารางหลักของงานนี้ — **ไม่ต้อง migrate เพิ่มเพื่อเก็บชุด** |
| `model.AvatarPartCategories` (18 หมวด: `ID`, `Group`, `Layer`, `RequiresSit`, `FixedColour`, `Occupies`) | `internal/model/avatar_part.go` | ลำดับวาด / occupies / channel ตอน bake และ validate |
| `AvatarPartFrameSize = 48`, `AvatarPartSheetSize = 192` | เดียวกัน | ขนาดชีท bake |
| Reset job: ลบ `slots.<slot>` ออกจาก outfit + `bake_hash = ''` แล้ว `PublishOutfitReset(ctx, userID, workspaceID)` | `internal/service/avatar_part_delete.go:~260-290`, `internal/cache/notification.go:119` | outfit JSON ต้องมี `slots.<slot>.part_id` (query `@>` ใช้ key นี้) · `bake_hash = ''` = ต้อง re-bake (§6.4) |
| Membership | `WorkspaceMemberService.IsMemberOrOwner` (`internal/service/workspace_member_service.go:1303`) | guard ของ endpoint ต่อ workspace |
| Route group member | `user := api.Group("/user", middleware.UserGuard(...))` (`router.go:143`) · `userWS` group `/user/workspaces/:id/...` (`router.go:~257` มี `members/me/character-name`) | วาง route ใหม่ |
| R2 | `storage.S3Client.UploadPNG` (rule 11) | อัปโหลดไฟล์ bake |

ยังไม่มี: member route ใด ๆ ของ avatar-part / outfit · โค้ด bake (Admin TD อ้าง "AvatarCustomization §6" แต่ยังไม่มีใน repo)

### 2.2 zyra-app

| ของ | ที่ | ใช้ยังไง |
|---|---|---|
| Renderer | `lib/avatar-part/render.ts` — `KEY_COLOURS`, `classifyKey`, `rampT`, `rampOf(hex)`, `paletteFor`, `decodeSheet`, `pickFrame`, `resolveSheet`, `blitFrame`, `loadSheet`, `drawLayer` | preview ในหน้าแต่งตัว (ห้ามเขียนซ้ำ) |
| สี | `lib/avatar-part/shade.ts` — `shadeHex`, `shadeTrack`, `PREVIEW_MAIN_COLOURS` (12 สีหลัก + แถบ Shade) | ตัวเลือกสีของ member (Figma: "เลื่อนเฉดสีได้ Items เปลี่ยนเฉดตาม") |
| ค่าคงที่ | `lib/avatar-part/constants.ts` — `ACCESSORY_CATEGORIES` (18), `FRAME_SIZE`, `BASE_SHEET_URLS` | parity กับ Go |
| ชีท base | `public/avatar/base/{walk,sit}.png` (192×192) | ชีท body Default (spec §9.3) |
| Frame layout ของ VO | `zyra-engine/avatar-frames.ts` — `AVATAR_SHEET_COLS = 4`, `ROWS = 4`, idle col 1, walk 4 เฟรม, sit 3 เฟรม | **ไฟล์ bake ต้องเป็น 4×4 เท่านี้** → VO ไม่ต้องแก้ frame cache |
| ใส่ avatar ให้ player | `scene.ts` `setPlayerAvatar(walkUrl, sitUrl)` (hot-swap) · hero ตั้ง `mapConfig.playerSpriteUrl` จาก `storedAvatar.walking_spritesheet_url` | เปลี่ยนเป็น URL จาก outfit |
| ส่ง avatar ให้คนอื่น | state poll 100ms ส่ง `avatar_url` · onSave ล้าง `lastTileRef` เพื่อบังคับส่ง | ใช้ต่อ |
| Toast | `lib/toast.tsx` `zyraToast.*` | EP-01 |

### 2.3 zyra-ws

| ของ | ที่ |
|---|---|
| `MsgOutfitReset = "outfit_reset"` | `internal/hub/message.go:74` |
| `Hub.PushOutfitReset(workspaceID, userID)` → ส่งเฉพาะ connection ของ user ใน room ของ workspace นั้น (ข้าม client ที่อยู่ใน grace) | `internal/hub/outfit_reset.go` (commit `aff1f27`) |
| relay จาก Redis `vo:notify` (`OutfitResetUserID` + `WorkspaceID`) | `internal/store/redis.go:~927` |
| `moved.avatar_url` → broadcast เมื่อ URL เปลี่ยน (`room.go` `avatarChanged`) | เดิม |
| 1 connection ต่อ user ต่อ room (`r.getClient(userID)`) | `outfit_reset.go` |

---

## 3. Flow

```
หน้าแต่งตัว (zyra-app)
  ├─ GET /api/user/avatar/catalog ─────────────── ชิ้น active ทั้ง 18 หมวด + skin tones + palette/shade spec
  ├─ GET /api/user/workspaces/:id/avatar/outfit ─ ชุดของ workspace นี้ (+ unavailable, + baked URLs)
  │      (bake_hash = '' → server re-bake ก่อนตอบ §6.4)
  ├─ แต่ง → preview ด้วย lib/avatar-part/render.ts (ไม่ยิง server)
  └─ บันทึก (ปุ่ม หรือ auto-save — D-M1)
         PUT /api/user/workspaces/:id/avatar/outfit
           validate → normalize → hash → (มีไฟล์ hash นี้แล้ว? ใช้เลย : bake → R2)
           → UPSERT tb_user_outfit → commit
           → Redis vo:notify {workspace_id, outfit_updated_user_id, walk_url, sit_url, updated_at}
           → 200 {outfit, baked, updated_at}
VO (tab เดียวกันหรือ tab อื่นที่อยู่ room นั้น)
  ├─ ได้ 200 / ได้ ws "outfit_updated" → setPlayerAvatar(walk_url, sit_url) + ส่ง avatar_url ใน poll ถัดไป
  └─ zyra-ws room.go เห็น avatar_url เปลี่ยน → broadcast moved → คนอื่นโหลดชีทใหม่ (≤ 2 s, AC-HP05-3)
Admin ลบชิ้น → reset job (มีแล้ว) → outfit_reset → client GET outfit (re-bake) → เหมือนข้างบน
```

---

## 4. Data model

### 4.1 ตาราง — ไม่ต้องสร้างใหม่

`tb_user_outfit` หลัง migration 119 ใช้ได้ตามนี้ · **เพิ่ม 1 คอลัมน์ (เสนอ):**

```sql
-- migration 12x_user_outfit_bake_version.sql (+ .down.sql) และ embedded DDL ใน postgres.go
ALTER TABLE tb_user_outfit ADD COLUMN IF NOT EXISTS outfit_version INT NOT NULL DEFAULT 1;
-- down: ALTER TABLE tb_user_outfit DROP COLUMN IF EXISTS outfit_version;
```

- `outfit_version` = เลข schema ของ JSON (§4.2) เผื่อเปลี่ยนรูปแบบภายหลัง — ถ้าทีมเห็นว่าใส่ใน JSON (`"v": 1`) พอ ก็ไม่ต้อง migrate (เลือกอย่างใดอย่างหนึ่ง)
- ไม่มีแถว = ยังไม่เคยแต่งใน workspace นี้ → ได้ชุด default (AC-HP06-4) · **ไม่ insert ตอนอ่าน**
- ลบแถวเฉพาะ cascade ตอน user / workspace ถูกลบ · ออกจาก VO / ถูก remove member แล้วกลับมา → แถวยังอยู่ (AC-HP06-5, มติ Q-6b) — **ตรวจว่า `RemoveMember` / `LeaveWorkspace` ไม่ลบ `tb_user_outfit`** (ตอนนี้ไม่มีโค้ดแตะ — ห้ามเพิ่ม)

### 4.2 Outfit JSON (v1)

```jsonc
{
  "v": 1,
  "skin_tone": "fair",                   // id ใน SKIN_TONES (§4.3) — บังคับ ถอดไม่ได้
  "colors": {                            // channel ที่ใช้ทั้งตัว
    "hair": "#2E2E38",                   // hex หลังผสม shade แล้ว (ใช้กับ hair + facial_hair)
    "eye":  "#2F8F94"
  },
  "slots": {                             // key = category id 18 ตัว · ไม่มี key = ไม่ใส่
    "hair":    { "part_id": "uuid" },
    "top":     { "part_id": "uuid", "colors": { "primary": "#3A5AA8", "secondary": "#EDEDF3" } },
    "special_costume": { "part_id": "uuid", "variant_id": "uuid" }   // special ใช้ variant แทนสี
  }
}
```

กติกา:

- `slots.<slot>.part_id` **ชื่อนี้ห้ามเปลี่ยน** — reset job ของ Admin query ด้วย `outfit @> {slots:{<slot>:{part_id}}}`
- ไม่ใส่ = ไม่มี key (reset job ใช้ `#- ARRAY['slots', slot]` อยู่แล้ว) — ไม่เก็บ `null`
- สีเก็บเป็น **hex ที่ผสม shade แล้ว** (Figma: 12 สีหลัก + แถบ Shade; renderer มี `rampOf(hex)`) — **ต่างจากต้นฉบับ §3.4/§5** ที่ใช้ palette id + ตาราง `tb_avatar_palette` (Admin migration 118 ไม่สร้างตารางนี้ และ Admin TD §7 ให้สีเป็น 12 สี + Shade) · ถ้าทีมยังต้องการ palette ที่ admin จัดการ (เช่น สีฮาโลวีนมีช่วงเวลา) = D-M8
- `colors` ในชิ้นมีได้เฉพาะ channel ที่ชิ้นนั้นมีใน `tb_avatar_part.color_channels` · หมวด `FixedColour` (`face`, `special_costume`) ห้ามมี `colors`
- `special_costume` / `dress` มี `Occupies = [top, bottoms]` → normalize ลบ `top`, `bottoms` ออก
- ไม่มีหมวดบังคับนอกจาก skin (ClickUp ไม่ระบุ · Admin model ไม่มี `Required`) → ถ้าทีมต้องการบังคับ `eyes` / `top` ฯลฯ ต้องเพิ่ม flag ในโมเดล (D-M4)

### 4.3 Skin tones (มติ spec §9.3)

```go
// internal/model/avatar_outfit.go — parity กับ zyra-app lib/avatar-part/skin-tones.ts
type SkinTone struct {
    ID       string    // "default", "t1".."t4"
    NameKey  string    // i18n
    Ramp     [4]string // hex highlight→deep · "default" = ดูดจากชีท body (§6.2)
}
// ค่าจาก Figma "Customise avatar - Skin tone" 7615:207397 (ux-ui.md §5.7) — สีจุดบน card 1 สีต่อเฉด
// ramp 4 ขั้นสร้างด้วย rampOf(hex) แบบเดียวกับ render.ts (หรือ designer ให้ ramp เต็ม — D-M2)
var SkinTones = []SkinTone{
    {ID: "fair",        NameKey: "fair"},        // #F6D5B3
    {ID: "light_beige", NameKey: "lightBeige"},  // #E0B491
    {ID: "tan",         NameKey: "tan"},         // #C58F69
    {ID: "brown",       NameKey: "brown"},       // #9C694E
    {ID: "dark_brown",  NameKey: "darkBrown"},   // #684B3D
}
const DefaultSkinTone = "fair" // สมมติ — Figma แสดง tag "Used" ที่ Fair · sticky "สีผิว Default" ไม่บอกชื่อ (D-M2)
```

- ค่าคงที่ในโค้ด (ไม่ใช่ตาราง · admin ไม่จัดการ) → EC-02 ส่วน skin ไม่เกิด
- **ขัดกับมติ Q-4 เล็กน้อย:** มติให้ "ดูดสีผิว 4 เฉดจากชีท body" — ใช้กับเฉด Default ได้ (เทียบว่าตรง `#F6D5B3` ไหม) ส่วนอีก 4 เฉดมาจาก Figma เป็นสีเดียวต่อเฉด → ต้องสร้าง ramp ด้วย `rampOf` · ตรวจกับ designer (D-M2)
- ramp ของเฉด Default คำนวณครั้งเดียวตอน start จาก `public/avatar/base/walk.png` เวอร์ชันที่ api ถือ (§6.2) หรือ hard-code ผลลัพธ์ + test ว่าตรงกับไฟล์ — **เสนอ hard-code + test** (ไม่ต้องให้ api โหลดไฟล์จาก zyra-app)

### 4.4 ไฟล์ bake บน R2

```
outfits/{bake_hash}/walk.png   192×192 (หรือ 240×192 ถ้า D-M7 = มีเฟรมกะพริบ)
outfits/{bake_hash}/sit.png    192×192 (เหมือนกัน)
outfits/{bake_hash}/thumb.png  (ต้นฉบับ §6: เฟรมยืนหันหน้า ขยาย 4× nearest · ขนาดจริงตาม ux-ui.md)
```

- prefix `outfits/` ตามต้นฉบับ §6 และ data contract
- `bake_hash = sha256( BAKE_VERSION + canonical_json(outfit) + id:art_version ของทุกชิ้น + ramp ของ skin tone ที่ใช้ )` (ต้นฉบับ §6 · hex 64 = `VARCHAR(64)` ที่มีแล้ว)
- ชุดเหมือนกัน (ข้าม user / workspace) = ไฟล์เดียวกัน · immutable → cache ยาวได้
- ไม่ลบไฟล์ hash เก่าทันที (คนอื่นอาจใช้ hash เดียวกัน) → cleanup เป็นงานแยก (orphan sweep ตาม `tb_user_outfit` — ไม่อยู่ใน scope แรก)
- `BAKE_VERSION` ขึ้นเมื่อเปลี่ยน algorithm bake → ทุกชุด re-bake แบบ lazy

---

## 5. API (member)

ทุก route ใต้ `UserGuard` (rule 15 — ห้าม `/api/admin/*`) · response = `model.APIResponse` · layer `handler/avatar_outfit_handler.go` → `service/avatar_outfit_service.go` → SQL inline (rule 02)

### 5.1 `GET /api/user/avatar/catalog`

ไม่มี query · ส่ง `ETag` = max(`updated_at`) ของชิ้น active (+ `BAKE_VERSION`) · `Cache-Control: private, max-age=60`

```jsonc
{ "status": 200, "message": "success", "data": {
  "version": "2026-10-22T03:00:00Z",
  "sheet": { "frame": 48, "cols": 4, "rows": ["down","left","right","up"] },
  "base": { "walk_url": "…/base/walk.png", "sit_url": "…/base/sit.png" },
  "skin_tones": [ { "id": "default", "ramp": ["#…","#…","#…","#…"] }, … ],      // 5
  "colours": { "main": ["#…" ×12], "shade": { "light": 0.85, "dark": 0.75 } },    // จาก shade.ts
  "categories": [ { "id": "hair", "group": "head", "layer": 9, "fixed_colour": false, "occupies": [] }, … ], // 18 ตามลำดับ Figma
  "parts": { "hair": [ { "id": "uuid", "name": "…", "thumbnail_url": "…", "walk_url": "…", "sit_url": "…|null",
                         "color_channels": ["hair"], "is_default": false, "sort_order": 0,
                         "available_until": null, "variants": [] } ] }
}}
```

- เฉพาะ `status = 'active' AND NOT is_deleted AND (available_from IS NULL OR available_from <= now()) AND (available_until IS NULL OR available_until > now())`
- เรียง `is_default DESC, sort_order, lower(name)`
- `name`: ชิ้นมีชื่อเดียว (Admin ไม่มี i18n) — แสดงตามที่ admin ตั้ง

### 5.2 `GET /api/user/avatar/outfit/default`

`data = { outfit, baked }` ของชุด default: `skin_tone = DefaultSkinTone` + ชิ้น `is_default = true` ของแต่ละหมวด (ถ้ามี) — Figma sticky: "ตัวละคร Default ใส่ชุดขาว สีผิว Default" → ต้องมีชิ้น default ของ top/bottoms สีขาวใน catalog (asset) · bake ครั้งเดียวแล้วใช้ร่วม

### 5.3 `GET /api/user/workspaces/:id/avatar/outfit`

| ผล | เมื่อ |
|---|---|
| 200 `{ is_default, outfit, baked:{hash,walk_url,sit_url,thumbnail_url}, unavailable:[…], parts_in_use:{…}, updated_at }` | ปกติ · ไม่มีแถว → ชุด default + `is_default: true`, `updated_at: null` |
| 403 `NOT_WORKSPACE_MEMBER` | ไม่ใช่ member / owner (`IsMemberOrOwner`) |
| 404 `WORKSPACE_NOT_FOUND` | ไม่มี workspace |

- `unavailable` = slot ที่ชิ้นที่ใส่อยู่ถูก **hidden** หรือหมดช่วง `available_until` (spec AC-EC02-5 — ยังใส่ต่อได้ แสดง note)
- `parts_in_use` = ข้อมูลชิ้น (url ชีท / thumbnail) ของชิ้นที่ใส่อยู่แต่ **ไม่อยู่ใน catalog** (hidden / หมดช่วง) — ให้ preview วาดชุดปัจจุบันได้
- แถวที่ `bake_hash = ''` (โดน reset) หรือ art_version เปลี่ยน → re-bake ก่อนตอบ (§6.4)

### 5.4 `PUT /api/user/workspaces/:id/avatar/outfit`

Request = outfit JSON (§4.2) · `Content-Type: application/json` · body ≤ 16 KB

ขั้นตอน (service):

1. ตรวจ member (403)
2. Validate (400) — `v` รองรับ · `skin_tone` อยู่ใน `SkinTones` · slot อยู่ใน 18 หมวด · `part_id` มีจริง ไม่ถูกลบ ตรงหมวด · hex รูปแบบ `#RRGGBB` · channel ตรงกับ `color_channels` · `variant_id` เป็นของชิ้นนั้น
3. **Hidden / หมดช่วง:** ผ่านได้ถ้า `(slot, part_id[, variant_id])` เหมือนแถวเดิมของ user ใน workspace นี้ (ใส่อยู่แล้ว) · เลือกใหม่ → `400 PART_NOT_SELECTABLE` (Admin TD §8.1)
4. Normalize — ลบ slot ที่โดน `occupies` · ตัด `colors` ที่ไม่ใช้ · เรียง key (canonical)
5. hash → ถ้า hash เท่ากับแถวเดิม → ตอบ 200 เลย (no-op, ไม่ publish) · ถ้ามีไฟล์ hash นี้แล้ว (มีแถวอื่นใช้ hash เดียวกัน — query `tb_user_outfit WHERE bake_hash=$1 LIMIT 1`) → reuse URL · ไม่งั้น bake (§6) + upload
6. `INSERT … ON CONFLICT (user_id, workspace_id) DO UPDATE` (last-write-wins, AC-EC03-1) — upload ก่อน tx (ไฟล์ immutable, ถ้า tx ล้มไฟล์ค้างเป็น orphan ได้ไม่เสียหาย)
7. หลัง commit: `PublishOutfitUpdated(ctx, userID, workspaceID, walk, sit, updatedAt)` — publish ล้มไม่ทำให้ PUT ล้ม (log warn แบบ reset job)
8. ตอบ 200 เหมือน GET

| HTTP | `message` | `detail` | client ทำ |
|---|---|---|---|
| 400 | `INVALID_OUTFIT` | `{field}` | toast · ไม่ retry |
| 400 | `INVALID_SKIN_TONE` · `INVALID_SLOT` · `INVALID_COLOUR` · `CHANNEL_NOT_ALLOWED` | `{slot, channel?}` | toast · ไม่ retry |
| 400 | `PART_NOT_FOUND` · `PART_NOT_SELECTABLE` | `{slot, part_id}` | reload catalog + toast · ไม่ retry |
| 403 | `NOT_WORKSPACE_MEMBER` | — | ปิดหน้า |
| 413 | `OUTFIT_TOO_LARGE` | — | — |
| 429 | `TOO_MANY_REQUESTS` | — | (auto-save) รอแล้วส่งชุดล่าสุด |
| 500 | `BAKE_FAILED` | — | retry 1 ครั้ง (AC-EP01-5) |
| 503 | `STORAGE_NOT_CONFIGURED` | — | retry 1 ครั้ง |

- `PART_NOT_SELECTABLE` ตรงกับ Admin TD §8.1 — data contract เดิมใช้ `PART_NOT_FOUND` สำหรับกรณีนี้ (spec C-17): **ใช้ 2 code แยก** (ไม่มี vs มีแต่เลือกไม่ได้)
- Rate limit ต่อ (user, workspace): 1 req/วินาที, burst 5 — จำเป็นถ้า D-M1 = auto-save

### 5.5 Route

```go
// router.go — group user (UserGuard)
user.GET("/avatar/catalog", avatarOutfitHandler.Catalog)
user.GET("/avatar/outfit/default", avatarOutfitHandler.DefaultOutfit)
// group userWS (/user/workspaces)
userWS.GET("/:id/avatar/outfit", avatarOutfitHandler.GetMyOutfit)
userWS.PUT("/:id/avatar/outfit", avatarOutfitHandler.PutMyOutfit)
```

ตั้งชื่อ path ตาม spec §9.2 (ตอบ C-17: ใช้ `/api/user/avatar/*` สำหรับของที่ไม่ผูก workspace และ `/api/user/workspaces/:id/avatar/outfit` สำหรับชุด — แทน `/api/user/me/outfit` ใน Admin TD §9)

---

## 6. Bake (zyra-api)

### 6.1 Algorithm — ต้องให้ผลเหมือน `lib/avatar-part/render.ts` ทุก pixel

```
input: outfit (normalized), parts (+ variants), skin ramp
for sheet in [walk, sit]:
  canvas 192×192 RGBA โปร่ง
  layers = [base body (layer 0)] + ชิ้นที่ใส่ เรียงตาม Category.Layer (เท่ากัน → ลำดับใน AvatarPartCategories)
  for layer in layers:
     src = sheet ของชิ้น (sit ไม่มี → fallback: ใช้เฟรม idle ของ walk ตาม resolveSheet)
     for each pixel (alpha 255):
        ch = classifyKey(rgb)        // skin/hair/eye/primary/secondary หรือ null
        if FixedColour or ch == null → ใช้สีเดิม
        else ramp = ramp ของ channel (skin → SkinTone.Ramp · hair/eye → outfit.colors · primary/secondary → slots.<slot>.colors หรือ default ramp)
             out = rampColour(ramp, rampT(ch, rgb))
        วางทับ (alpha 0/255 เท่านั้น — Admin validate ไว้แล้ว)
  encode PNG
thumb: ตัดเฟรม down/idle (row 0, col 1) ขยาย nearest-neighbor ตามขนาดใน ux-ui.md
```

- **Parity test (บังคับ):** fixture outfit 3–5 ชุด → bake ใน Go → เทียบ byte-for-byte (หรือ pixel) กับผล `render.ts` ที่ commit ไว้เป็น golden PNG ใน zyra-api `testdata/` — แบบเดียวกับ parity ของ `CATEGORY_LAYER` ที่ Admin ทำ (`avatar_part_test.go` ↔ `__tests__/avatar-part-renderer.test.ts`)
- Port ฟังก์ชัน `classifyKey` / `rampT` / `rampOf` / `rampColour` / `shadeHex` เป็น Go 1:1 ใน `internal/service/avatar_bake.go` (ไม่ใช้ headless browser)

### 6.2 สีผิว Default ดูดจากชีท body (มติ Q-4)

- อ่าน pixel ที่ `classifyKey == skin` ของ `public/avatar/base/walk.png` → จัดกลุ่มตาม `rampT` 4 ขั้น → ค่าเฉลี่ยต่อขั้น = ramp 4 สี
- ทำเป็นสคริปต์ครั้งเดียว (`cmd/skin-ramp` หรือ test helper) แล้ว hard-code ลง `SkinTones[0].Ramp` + test ว่าตรงกับไฟล์ base ปัจจุบัน → เปลี่ยนไฟล์ base แล้ว test แดง = ต้องอัปเดต
- ถ้าชีท body เป็นสีจริง (ไม่ใช่สี key) → "ดูด" = เก็บ 4 สีจริงของผิวตาม luminance ไว้เป็น ramp Default และ map เป็นสี key ตอน bake — **ต้องตรวจไฟล์ base จริงก่อน** (`public/avatar/base/walk.png` ยังไม่ได้เปิดดูค่า pixel)

### 6.3 ประสิทธิภาพ

- Cache ชีทที่ decode แล้วใน memory (LRU ~200 ชีท, key = `url + art_version`) — ชีท 192×192 ≈ 147 KB RGBA
- เป้า: bake 1 ชุด (≤ 19 layer × 2 ชีท) < 150 ms p95 บน api pod ปัจจุบัน — วัดใน test benchmark
- Dedupe ด้วย hash ทำให้ชุดยอดนิยมไม่ bake ซ้ำ
- PUT ทำ bake แบบ synchronous (ClickUp ต้องการให้คนอื่นเห็นใน 2 s)

### 6.4 Lazy re-bake

- GET outfit (และ PUT) ตรวจ: `bake_hash = ''` (reset job ล้าง) **หรือ** hash ที่คำนวณใหม่ (art_version / BAKE_VERSION เปลี่ยน) ≠ ที่เก็บ → bake ใหม่ + UPDATE แถว (ไม่ publish — client ที่เรียก GET จะเอาไปใช้เอง)
- VO ที่โหลดชุดคนอื่นใช้ URL จาก `moved.avatar_url` → ไม่กระทบ
- ⚠ Reset job ของ Admin ล้าง slot แต่ **ไม่เติมชิ้น default** และ Admin TD §8.3 เขียนว่า "slot บังคับ → ใส่ชิ้น default" — ตอนนี้ไม่มี slot บังคับใน model (D-M4) จึงสอดคล้องกัน

---

## 7. Realtime

### 7.1 `outfit_updated` (ใหม่) — ตาม `outfit_reset` ทุกอย่าง

| repo | งาน |
|---|---|
| zyra-api `internal/cache/notification.go` | เพิ่ม field ใน `notificationEnvelope`: `OutfitUpdatedUserID string \`json:"outfit_updated_user_id,omitempty"\`` + `Outfit *OutfitUpdatedPayload \`json:"outfit,omitempty"\`` (`walk_url`, `sit_url`, `updated_at`) · `PublishOutfitUpdated(ctx, userID, workspaceID, payload)` |
| zyra-ws `internal/store/redis.go` | parse field → `hub.PushOutfitUpdated(workspaceID, userID, payload)` |
| zyra-ws `internal/hub/message.go` | `MsgOutfitUpdated = "outfit_updated"` + payload struct |
| zyra-ws `internal/hub/outfit_reset.go` (หรือไฟล์ใหม่) | `PushOutfitUpdated` = ส่งให้ connection ของ user ใน room นั้น (ข้าม grace) — เหมือน `PushOutfitReset` |

- ชื่อ `outfit_updated` (snake_case คู่กับ `outfit_reset`) แทน `ws:avatar:updated` ของ ClickUp — spec Q-13 (เสนอ)
- **ไม่ broadcast ให้คนอื่น** — คนอื่นเห็นผ่าน `moved.avatar_url` เดิมเมื่อ client ของเจ้าของส่ง URL ใหม่
- `updated_at` กันลำดับสลับ: client ไม่ apply ถ้าเก่ากว่าที่ถืออยู่

### 7.2 ข้อจำกัด multi-tab (EC-03)

- zyra-ws มี **1 connection ต่อ user ต่อ room** → tab ที่สองใน workspace เดียวกันไม่ได้อยู่ใน room พร้อมกัน (หรือเตะอันแรก — ต้องตรวจ `hub.Join` อีกครั้งตอน implement)
- หน้าแต่งตัวที่เปิดจาก lobby (`Before enter space`) **ไม่มี ws** → ws ไม่ช่วย
- จึงใช้ 2 ชั้น: (1) ws `outfit_updated` สำหรับ tab ที่อยู่ใน VO · (2) TanStack Query `refetchOnWindowFocus` + `BroadcastChannel("zyra-avatar-outfit")` ใน browser เดียวกัน (post หลัง PUT สำเร็จ) → tab อื่นอัปเดต "ชุดที่บันทึก" ตาม Figma sticky "Tab 2 เซฟทีหลัง ระบบจะแสดงข้อมูลล่าสุด"
- draft ค้างใน tab อื่น: อัปเดตชุดที่บันทึก แต่ไม่ทับ draft (spec Q-11 — ถ้าเป็น auto-save ไม่มี draft ค้าง ปัญหานี้หายไป)

### 7.3 `outfit_reset` (มีแล้ว)

client ใน VO ได้ `outfit_reset` → `GET …/avatar/outfit` (server re-bake) → `setPlayerAvatar` + ส่ง `avatar_url` · ถ้าหน้าแต่งตัวเปิดอยู่ → reload catalog + outfit

---

## 8. zyra-app

### 8.1 โครงไฟล์ (ตาม rule 02)

```
lib/api/avatar-outfit.ts              getAvatarCatalog · getDefaultOutfit · getWorkspaceOutfit · putWorkspaceOutfit (authFetch → /api/user/*)
lib/avatar-part/skin-tones.ts         SKIN_TONES (parity กับ Go)
lib/avatar-part/outfit.ts             type Outfit · normalizeOutfit · applyPart · removePart · clearAll · hashKey — reducer ล้วน (test ได้)
hooks/use-avatar-outfit.ts            TanStack Query: ["avatar","catalog"] · ["avatar","outfit",workspaceId] · mutation + retry + BroadcastChannel
views/user/avatar-customize/
  hero-avatar-customize.tsx           หน้า "Customise avatar" (Dressing room) — layout ตาม ux-ui.md
  components/…                        category column · item grid · costume panel · colour picker + shade · stage preview · slot presets (ถ้า D-M3)
app/(user)/…/page.tsx หรือ overlay    ตาม entry point (ux-ui.md / spec Q-7)
messages/{en,th}.json                 namespace AvatarCustomize
```

- ใช้ `lib/avatar-part/render.ts` วาด stage + thumbnail ใน card (ห้ามเขียน renderer ใหม่ — rule 09)
- UI ตาม rule 08 / 12 (Tailwind + icon ตามที่ ux-ui.md ระบุ · icon 20 หมวดมีใน Figma `7648:213497` — Admin มี `AccessoryCategoryIcon` แล้วใน `components/ui/icon.tsx` reuse ได้ถ้า glyph ตรง)

### 8.2 การบันทึก — 2 แบบ (D-M1)

| | (ก) ปุ่มบันทึก / ยกเลิก (ClickUp HP-05) | (ข) บันทึกอัตโนมัติ (Figma sticky `7698:143821`) |
|---|---|---|
| ยิง PUT | ตอนกดบันทึก | ทุกครั้งที่เปลี่ยน — debounce 800 ms, ส่งเฉพาะชุดล่าสุด, ยกเลิก request เก่า (`AbortController`) |
| ยกเลิก | กลับชุดที่บันทึก + confirm ถ้า dirty (AC-HP05-5/6) | ไม่มี — "ย้อนกลับ" ออกจากหน้าได้เลย |
| network error | คง selection + toast + retry 1 ครั้ง/3 s (AC-EP01-*) | Figma `7698:187581`: icon reload บนตัวละคร → นานเกินไป → **กลับเป็นชุดเดิม** + toast |
| ภาระ server | 1 bake ต่อการบันทึก | หลาย bake ต่อ session → ต้องมี rate limit + dedupe hash · พิจารณา "preview ไม่ bake, bake ตอนออกจากหน้า" |
| ws/VO | publish ทุกครั้ง | publish ทุกครั้งที่ PUT สำเร็จ (คนอื่นเห็นชุดเปลี่ยนรัว ๆ) |

API ด้านบนรองรับทั้งสองแบบ (PUT idempotent + no-op ถ้า hash เดิม + rate limit) — **ต้องตัดสินก่อนทำ UI**

### 8.3 VO

- ตอนเข้า workspace: `GET /api/user/workspaces/:id/avatar/outfit` **ก่อน** ต่อ ws → ส่ง `baked.walk_url` เป็น `avatar_url` query (handler.go:130) และตั้ง `mapConfig.playerSpriteUrl` (แทน `storedAvatar.walking_spritesheet_url` ที่ hero ~:6123)
- ระหว่างนั่ง: ส่ง `sit_url` ตามกลไกเดิม (hero :3541-3610)
- **คง key `zyra_selected_avatar` และ shape `StoredAvatar` เดิม** ตามต้นฉบับ §8 (`id = bake_hash`, `walking_spritesheet_url = walk_url`, `sitting_spritesheet_url = sit_url`) → ~24 ไฟล์ที่อ่าน `StoredAvatar` ไม่ต้องแก้ · แต่เพราะชุดเป็น **ต่อ workspace** ค่านี้ต้อง **เขียนทับทุกครั้งที่เข้า workspace** จาก GET outfit — หน้า loading (`hero-workspace-loading.tsx:~384`) ดึงก่อนต่อ ws และ VO mount (`hero-virtual-office.tsx:~2194-2272`) เปลี่ยนจาก `listAvatarsForUser` เป็น GET outfit (ต้นฉบับ §8) · เปิด 2 workspace คนละ tab: key เดียวกันถูกทับสลับกัน → แต่ละ tab ต้องถือค่าใน memory หลังโหลด ไม่อ่าน localStorage ซ้ำระหว่าง session (ตรวจตอน implement)
- เปลี่ยนชุดสำเร็จ / ได้ `outfit_updated` / `outfit_reset` → `scene.setPlayerAvatar(walk, sit)` + ล้าง `lastTileRef` (บังคับส่ง avatar_url)
- รอง VO เปิดในหลาย workspace พร้อมกัน — แต่ละ tab ถือชุดของ workspace ตัวเอง

### 8.4 Entry point

ตาม Figma (sticky `7648:255732`): เมนู "Change Avatar" → เปลี่ยนเป็น **"Customise avatar"** + ชื่อ workspace ใต้ปุ่มย้อนกลับ · จุดเปิด: `Before enter space` (lobby — แทนปุ่มเปลี่ยนตัวละครเดิมใน `hero-workspace-enter.tsx`) และ `Availability Status - Set status` (VO profile panel — แทน `vo-profile-panel.tsx:515` "Change avatar") — รายละเอียดใน ux-ui.md · Profile page (`profile-form.tsx`) อยู่นอก workspace → ไม่เปิดหน้านี้ (spec Q-7)

---

## 9. Feature flag / Rollout

| flag | ที่ | ปิด | เปิด |
|---|---|---|---|
| `AVATAR_OUTFIT_ENABLED` | zyra-api env | route member ตอบ 404 | เปิด route |
| `NEXT_PUBLIC_AVATAR_CUSTOMIZE` | zyra-app | ระบบเดิม (`tb_avatar` + change-character-modal) | หน้าแต่งตัว + VO ใช้ outfit |

- ลำดับ deploy: api (route + bake) → ws (`outfit_updated`) → app (flag ปิด) → เปิด flag dev → UAT → prod
- Backward compat: VO รับ `avatar_url` ได้ทั้งชีท `tb_avatar` เดิม (1000×1000? — **ตรวจ: baseline บอก `tb_avatar` sheet 1000×1000 แต่ engine เป็น 4×4 grid** ทำงานได้เพราะ frame size คำนวณจากขนาดรูป) และชีท bake 192×192 → client เก่า/ใหม่อยู่ใน room เดียวกันได้
- ผู้ใช้เดิมที่เลือก character `tb_avatar` ไว้ → เปิด flag แล้วได้ชุด default ทุก workspace (spec Q-15 — รอยืนยัน)

---

## 10. Security / ข้อจำกัด

- member อ่าน/เขียนได้เฉพาะชุดตัวเอง (user จาก token เท่านั้น ไม่รับ `user_id` ใน body) และเฉพาะ workspace ที่เป็น member
- validate ทุก id กับ DB — ไม่เชื่อ URL ชีทจาก client (server ใช้ URL จาก `tb_avatar_part` เท่านั้น)
- body ≤ 16 KB · hex regex · ไม่ log outfit JSON เต็ม (log แค่ hash)
- R2 key มาจาก hash เท่านั้น (ไม่มี input ผู้ใช้ใน path)

---

## 11. Test (สรุป — รายละเอียดใน test-plan.md รอบถัดไป)

| ชั้น | อะไร |
|---|---|
| Go unit | validate (ทุก error code) · normalize (occupies, channel) · hash canonical · hidden-ที่ใส่อยู่ผ่าน / เลือกใหม่ไม่ผ่าน · no-op hash เดิม |
| Go parity | bake golden PNG ↔ `render.ts` · skin ramp ↔ ไฟล์ base |
| Go integration | PUT → แถว + R2 mock + publish · GET ไม่มีแถว → default · `bake_hash=''` → re-bake · non-member 403 · 2 workspace แยกกัน (AC-HP06-*) |
| ws | `outfit_updated` ส่งเฉพาะ room ของ workspace · ข้าม grace (แบบ `outfit_reset_test.go`) |
| app vitest | reducer `outfit.ts` · hook retry 1 ครั้ง/3 s · BroadcastChannel sync |
| e2e (Playwright) | แต่ง → บันทึก → อีก browser context เห็นชุดใหม่ ≤ 2 s (AC-HP05-3) · network error (EP-01) |

---

## 12. Task breakdown (ร่าง — ย้ายไป task-breakdown.md เมื่ออนุมัติ)

| # | repo | งาน | ขึ้นกับ | ประมาณ |
|---|---|---|---|---|
| M-1 | api | model `SkinTones` + outfit JSON types + validate/normalize/hash + unit test | D-M2 (ค่าสี — ใส่ placeholder ได้) | 1 d |
| M-2 | api | bake (`avatar_bake.go`) + golden parity กับ `render.ts` + benchmark | M-1 | 2 d |
| M-3 | api | routes catalog / default / GET / PUT + flag + rate limit + integration test | M-1, M-2 | 1.5 d |
| M-4 | api + ws | `outfit_updated` (notification.go + redis.go + hub) + test | M-3 | 0.5 d |
| M-5 | app | `lib/api/avatar-outfit.ts` + `skin-tones.ts` + `outfit.ts` reducer + hook + test | M-3 (mock ได้ก่อน) | 1 d |
| M-6 | app | หน้า Customise avatar ตาม ux-ui.md (stage, category, grid, costume panel, colour + shade, clear all) | M-5, D-M1, D-M3 | 3 d |
| M-7 | app | VO ใช้ outfit ต่อ workspace + รับ `outfit_updated` / `outfit_reset` + entry point + flag | M-4, M-6 | 1.5 d |
| M-8 | app | e2e + เปิด flag dev | M-7 | 0.5 d |

รวม ≈ 11 วันคน (ไม่รวม Slot preset ถ้า D-M3 = ทำ)

---

## 13. ต้องตัดสิน / ความเสี่ยง

| # | เรื่อง | ผลถ้าไม่ตอบ | ใคร |
|---|---|---|---|
| **D-M1** | บันทึกอัตโนมัติ (Figma) vs ปุ่มบันทึก/ยกเลิก + confirm (ClickUp HP-05) — รวมพฤติกรรม EP-01 (กลับชุดเดิม vs คง selection) | UI + ภาระ bake | PM + Designer |
| **D-M2** | ✅ บางส่วน: 5 เฉดจาก Figma = Fair `#F6D5B3` · Light Beige `#E0B491` · Tan `#C58F69` · Brown `#9C694E` · Dark Brown `#684B3D` · เหลือ: เฉดไหน Default (สมมติ Fair) + ramp 4 ขั้นต่อเฉด (ใช้ `rampOf` หรือ designer ให้) | `SkinTones` | Designer |
| **D-M3** | Slot = preset หลายชุด (Figma sticky `7726:222732`) อยู่ใน scope ไหม — ถ้าทำต้องเพิ่ม `preset_index` ใน PK หรือเก็บ `presets[]` + `active` ใน JSON | schema + UI | PM |
| D-M4 | มีหมวดบังคับไหม (นอกจาก skin) เช่น eyes / top | validate + reset job ของ Admin | PM + Ten |
| D-M5 | ขนาด thumbnail ของชุด (`thumb.png`) | bake | Designer (ux-ui.md) |
| D-M6 | ชื่อ event `outfit_updated` (spec Q-13) | ws contract | Ten |
| R-1 | ชีท base เป็นสี key หรือสีจริง (§6.2) | วิธีดูด ramp | ตรวจไฟล์ก่อน M-1 |
| R-2 | 1 ws connection ต่อ user ต่อ room → multi-tab sync พึ่ง BroadcastChannel/refetch (§7.2) | EC-03 ไม่ครบถ้าคนละ browser | ยอมรับได้? |
| R-3 | auto-save + bake ทุกครั้ง → โหลด CPU | latency | rate limit + dedupe + วัด M-2 |
| R-4 | ไฟล์ bake orphan สะสม | ค่า R2 | งาน sweep แยก |
| R-5 | asset ชุด Default (เสื้อ/กางเกงขาว) ยังไม่มีชิ้น `is_default` ใน catalog | ชุด default ว่าง | ศิลปิน + admin อัปโหลด |
| D-M7 | เฟรมกะพริบตา (ต้นฉบับ §2): output 5 คอลัมน์ 240×192 + ชิ้น `eyes` วาด 5 คอลัมน์ + แก้ `buildFrameCache` อ่าน cols — **ตอนนี้ Admin validator รับแค่ 192×192** และ engine เป็น 4 คอลัมน์ → v1 ของเอกสารนี้ bake 192×192 (ไม่กะพริบ) · ถ้าจะเอากะพริบ ต้องแก้ Admin validator + engine (ต้นฉบับ F1) ก่อน | ขนาด output + renderer | Ten + PM |
| D-M9 | Figma มีของที่ ClickUp ไม่มี: **Undo / Redo**, **Clear all** (ลบ item ใน slot ปัจจุบัน + skin กลับ Default), **ถอดด้วย double-click** (ไม่มีการ์ด "None"), preview **ภาพนิ่ง** (ClickUp ต้องการ animated) — ดู [ux-ui.md](ux-ui.md) §8 ทั้งตาราง | UI + reducer `outfit.ts` (undo stack ฝั่ง client เท่านั้น ไม่กระทบ API) | PM + Designer |
| D-M8 | palette ที่ admin จัดการ (ต้นฉบับ `tb_avatar_palette`, สีพิเศษตามช่วงเวลา) vs สี 12 + Shade อิสระ (Figma / Admin TD §7) | validate สี + catalog | PM + Designer |

---

## Changelog

| วันที่ | อะไร |
|---|---|
| 2026-10-22 | v0.1 — ร่างแรก ต่อจาก develop หลัง merge Admin (api#179–#185, ws `outfit_reset` per workspace, app `lib/avatar-part/*`) + มติ spec §8.3 · ต่อยอดจาก [technical-design.md](technical-design.md) ต้นฉบับ (คง StoredAvatar shape, จุดดึง outfit ก่อนต่อ ws, prefix `outfits/`, สูตร hash) · แยกเป็นไฟล์ใหม่เพื่อไม่ทับต้นฉบับ |
