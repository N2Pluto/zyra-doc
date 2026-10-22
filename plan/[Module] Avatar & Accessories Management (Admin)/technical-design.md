# Accessory Management (Admin) — Technical Design

> **สถานะ:** Draft v1.0 · 2026-10-21 · ยังไม่ implement · **repo:** zyra-api, zyra-app, zyra-ws (เล็กน้อย)
> **อ้างอิงโค้ดจริง:** `origin/develop` ของ zyra-api / zyra-ws ณ 2026-10-21 · migration ล่าสุด `114_user_apple_token`
> **ต่อยอดจาก:** [AvatarCustomization/technical-design.md](../AvatarCustomization/technical-design.md) (schema `tb_avatar_part` / `tb_avatar_palette` / `tb_user_outfit` + bake ฝั่ง server) — เอกสารนี้คือ **ฝั่ง admin** ของระบบเดียวกัน ไม่ใช่ระบบที่สอง
> **เอกสารคู่กัน:** [ux-ui-plan.md](ux-ui-plan.md) · [test-plan.md](test-plan.md) · [task-breakdown.md](task-breakdown.md) · [data/api-example.md](data/api-example.md) (ฝั่ง member)

---

## 1. ภาพรวม

```
Admin (zyra-app /admin/accessory-management)
   │  multipart upload / JSON
   ▼
zyra-api  /api/admin/avatar-parts*  ── RequirePermission(admin.avatar.manage)
   │   validate PNG → upload R2 → tb_avatar_part (+ variant) → audit
   │   delete → reset job (batch 100) → re-bake ชุดผู้ใช้ → Redis publish
   ▼
Redis  channel เดิมของ notification  ──►  zyra-ws  ──►  "outfit_reset" ไปที่ socket ของผู้ใช้
                                                       client โหลดชุดใหม่ แล้วส่ง avatar_url ใหม่ใน move
Member (data/api-example.md)  /api/user/avatar/catalog  อ่านเฉพาะชิ้น active ในช่วงเวลา
```

หลักการที่ยึด (จากมติ AvatarCustomization):
- ชิ้นส่วนวาดด้วย **สี key** แล้วเปลี่ยนสีด้วย palette swap · ยกเว้น Special Costume ใช้สีตามไฟล์
- ชุดของผู้ใช้ **bake ฝั่ง server** เป็นชีทเดิน + ชีทนั่ง 1 คู่ · VO และ zyra-ws ยังรับ "URL เดียวต่อคน" เหมือนเดิม
- Hide **ไม่แตะ** ชุดที่ผู้ใช้ใส่อยู่ · Delete **ถอดออก** จากทุกคนที่ใส่

> มติ AvatarCustomization 2026-10-05 เขียนว่า "ไม่มีหน้าให้ admin อัปโหลดรูป" — ClickUp + Figma ของโมดูลนี้ให้ admin อัปโหลด เอกสารนี้ยึด ClickUp/Figma และถือว่ามติข้อนั้นถูกแทนแล้ว (requirements Q1) → ต้องแก้หัว AvatarCustomization/spec.md ตามด้วย

---

## 2. หมวด (category) ↔ slot

Figma มี 18 หมวด · data contract ฝั่ง member มี 11 slot → ใช้ **หมวด = slot** (18 ค่า) และขยาย data contract ตาม (ux-ui-plan U4)

| กลุ่ม | category (ค่าใน DB) | ชีท | สีเปลี่ยนได้ | วาดทับลำดับ (ต่ำ→สูง) |
|---|---|---|---|---|
| Head | `hair` | walk (+sit ตาม U5) | hair | 9 |
| | `eyes` | walk | eye | 2 |
| | `face` | walk | — (สีตายตัว) | 3 |
| | `facial_hair` | walk (+sit ตาม U5) | hair | 7 |
| Body | `top` | walk + sit | primary, secondary | 5 |
| | `outer` | walk + sit | primary, secondary | 6 |
| | `dress` | walk + sit | primary, secondary | 5 (ทับ top+bottoms) |
| | `bottoms` | walk + sit | primary, secondary | 4 |
| | `shoes` | walk | primary, secondary | 4 |
| | `special_costume` | walk + sit **ต่อ variant** | — (สีตามไฟล์) | 5 (ทับ top+bottoms) |
| Accessory | `hat` | walk | primary, secondary | 11 |
| | `glasses` | walk | primary | 10 |
| | `mask` | walk | primary, secondary | 8 |
| | `neck` | walk | primary, secondary | 8 |
| | `belt` | walk | primary | 6 |
| | `bag` | walk | primary, secondary | 6 |
| | `back` | walk | primary, secondary | 1 (หลังตัว) |
| | `companion` | walk | primary, secondary | 12 |

- base (`body`) ไม่อยู่ในหน้า admin — เป็นไฟล์ใน repo ตามมติเดิม (ลำดับ 0)
- ลำดับวาดเก็บเป็น constant `CATEGORY_LAYER` ตัวเดียว ใช้ทั้ง Go (bake) และ TS (preview) · เทส parity ตาม test-plan §3.2
- "ต้องมีชีทนั่ง" เก็บเป็น `CATEGORY_REQUIRES_SIT` — ค่าเริ่มต้นตาม sticky Figma (`top`, `outer`, `dress`, `bottoms`, `special_costume`)
- `dress` / `special_costume` มี `occupies = [top, bottoms]` (ใส่แล้วสองช่องนั้นว่าง)

---

## 3. Spec ไฟล์ชีท

| รายการ | ค่า | ที่มา |
|---|---|---|
| รูปแบบ | PNG RGBA | EP-01 |
| ขนาด | 192 × 192 = 4 แถว (ลง/ซ้าย/ขวา/ขึ้น) × 4 คอลัมน์ เฟรม 48 px | ไฟล์จริง 72 ไฟล์ใน `demo file/custom avatar` · ClickUp บอก 64 px (test-plan §0) |
| ขนาดไฟล์สูงสุด | 2 MB (`ACCESSORY_MAX_BYTES`) | Figma alert |
| alpha | 0 หรือ 255 เท่านั้น — ค่ากลาง = warning | prototype |
| พื้นโปร่งใส | ต้องมี alpha channel และมี pixel โปร่งอย่างน้อย 1 จุด → ไม่ผ่าน = `NOT_TRANSPARENT` (error ตาม Figma · ux-ui-plan U3) | Figma toast |
| สี key | scan ตอนอัปโหลด เก็บ `color_channels` | AvatarCustomization §3.3 |

Validator (Go) `internal/service/avatar_part_validate.go` — ต่อยอดของเดิม `readAndValidatePNG` / `avatarPNGMagic` ใน `avatar_service.go` ใช้ `image/png` + `golang.org/x/image` (มีใน go.mod แล้ว)

---

## 4. DB schema

> ⚠️ GitOps deploy ไม่รัน `migrations/*.sql` (`internal/database/postgres.go` comment บรรทัด ~356 "It has now bitten three times") → ทุกตาราง/คอลัมน์ใหม่ต้องใส่ **ทั้ง** migration file **และ** embedded DDL ใน `postgres.go`

### 4.1 Migration `118_avatar_parts_admin.sql` (+ `.down.sql`)

> เลข 115–117 ถูกใช้ไปแล้ว (calendar) → ใช้ **118** · ทำแล้วใน zyra-api#179 · สร้าง `tb_avatar_part` + `tb_user_outfit` เองด้วย `IF NOT EXISTS` (D6) · ไม่สร้าง `tb_avatar_palette` (admin ไม่ใช้)

ถ้า AvatarCustomization A1 ยังไม่ได้สร้าง `tb_avatar_part` → migration นี้สร้างเอง ตามร่าง §5 ของเอกสารนั้น บวกส่วนขยายด้านล่าง ถ้าสร้างไปแล้ว → ใช้แค่ `ALTER` ส่วนขยาย

```sql
-- migration 118: admin accessory management
-- ส่วนขยายบน tb_avatar_part (AvatarCustomization §5)
ALTER TABLE tb_avatar_part
  ADD COLUMN IF NOT EXISTS deleted_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS created_by  VARCHAR,
  ADD COLUMN IF NOT EXISTS updated_by  VARCHAR;
-- slot ขยายเป็น 18 หมวด (§2) — เก็บเป็น VARCHAR(20) เดิม ตรวจค่าที่ service (ไม่ใช้ enum เพื่อเพิ่มหมวดได้โดยไม่ต้อง migrate)

-- ชื่อซ้ำไม่ได้ในหมวดเดียวกัน (ไม่สนตัวพิมพ์ · ไม่นับที่ลบแล้ว)
CREATE UNIQUE INDEX IF NOT EXISTS ux_tb_avatar_part_slot_name
  ON tb_avatar_part (slot, lower(name)) WHERE NOT is_deleted;

-- Special Costume: 1 ชิ้นมีหลาย variant สี แต่ละ variant มีชีทของตัวเอง
CREATE TABLE IF NOT EXISTS tb_avatar_part_variant (
  id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id        UUID         NOT NULL REFERENCES tb_avatar_part(id) ON DELETE CASCADE,
  name           VARCHAR(50)  NOT NULL,          -- ชื่อสี เช่น "Orange"
  color_tag      CHAR(7)      NOT NULL,          -- "#FF8000" (แบบเดียวกับ ObjectVariant.ColorTag)
  walk_sheet_url TEXT         NOT NULL,
  sit_sheet_url  TEXT         NOT NULL,
  thumbnail_url  TEXT,
  sort_order     INT          NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tb_avatar_part_variant_part ON tb_avatar_part_variant (part_id);
-- UNIQUE constraint ใส่ expression ไม่ได้ → ใช้ unique index
CREATE UNIQUE INDEX IF NOT EXISTS ux_tb_avatar_part_variant_name ON tb_avatar_part_variant (part_id, lower(name));

-- audit ทุกการแก้ไข (HP-04) และการลบ (EC-02)
CREATE TABLE IF NOT EXISTS tb_avatar_part_audit (
  id           BIGSERIAL    PRIMARY KEY,
  part_id      UUID         NOT NULL,
  action       VARCHAR(20)  NOT NULL,            -- created|updated|hidden|unhidden|deleted|hard_deleted
  performed_by VARCHAR      NOT NULL,            -- admin user id (ไม่เก็บ email — rule 07)
  detail       JSONB        NOT NULL DEFAULT '{}', -- changed_fields, affected_user_count, job_id
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tb_avatar_part_audit_part ON tb_avatar_part_audit (part_id, created_at DESC);

-- job ถอดชิ้นที่ถูกลบออกจากชุดผู้ใช้ (EC-02)
CREATE TABLE IF NOT EXISTS tb_avatar_reset_job (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id     UUID         NOT NULL,
  total       INT          NOT NULL,
  done        INT          NOT NULL DEFAULT 0,
  status      VARCHAR(20)  NOT NULL DEFAULT 'running', -- running|completed|failed
  last_error  TEXT,
  created_by  VARCHAR      NOT NULL,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- หา "ใครใส่ชิ้นนี้อยู่" เร็ว ๆ (user count + reset job)
CREATE INDEX IF NOT EXISTS idx_tb_user_outfit_outfit_gin
  ON tb_user_outfit USING GIN (outfit jsonb_path_ops);
```

### 4.2 จำนวนผู้ใช้ต่อชิ้น (card count, modal ลบ)

**ไม่เก็บเป็นคอลัมน์** (บักเดิม `user_count = 0` ตลอด — [AvatarManagement/SC-AV-01-user-count-fix.md](../AvatarManagement/SC-AV-01-user-count-fix.md)) → นับสดจาก `tb_user_outfit`:

```sql
-- รู้ slot ของชิ้นอยู่แล้ว → ใช้ containment (@>) ซึ่ง GIN jsonb_path_ops ใช้ index ได้
SELECT count(*) FROM tb_user_outfit
WHERE outfit @> jsonb_build_object('slots', jsonb_build_object($1::text, jsonb_build_object('part_id', $2::text)))
-- $1 = slot (category), $2 = part_id
```

list หน้า 20 ชิ้น = 1 query รวม (`jsonb_path_query` + `GROUP BY`) ไม่ query ทีละ card

### 4.3 สถานะ

`status` = `active` | `hidden` · ลบ = `is_deleted = TRUE` + `deleted_at` (คงรูปแบบเดิมของ `tb_avatar`) · transition ตาม test-plan §1.5 · สถานะเริ่มต้นตอนสร้าง = ค่าจาก toggle ในฟอร์ม (Figma default Active) — **รอ PM** เพราะ ClickUp บอก Hidden

---

## 5. API (admin)

ทุก route ใต้ group admin เดิม + `middleware.RequirePermission(permChecker, rbac.PermAdminAvatarManage)` (มีอยู่แล้วที่ `internal/rbac/catalog.go:90` แต่ route avatar เดิมไม่ได้ตรวจ — route ใหม่ตรวจ) · response = `model.APIResponse` · ชื่อ route ตาม AvatarCustomization §7

| Method | Path | Body / Query | ผล |
|---|---|---|---|
| GET | `/api/admin/avatar-parts` | `category, status=all\|active\|hidden\|deleted, search, sort=latest, page, limit (≤100, default 20)` | `{ items[], total }` · item มี `user_count`, `variants[]` (special) |
| GET | `/api/admin/avatar-parts/category-counts` | — | `{ hair: 5, eyes: 6, … }` ครบ 18 key (ไม่นับที่ลบ) |
| GET | `/api/admin/avatar-parts/:id` | — | รายละเอียด + variants + `user_count` |
| POST | `/api/admin/avatar-parts` | multipart: `name, category, status, available_from?, available_until?, walk, sit?` · special: `variants` (JSON: `[{name, color_tag}]`) + ไฟล์ `variant_{i}_walk`, `variant_{i}_sit` | 201 + item |
| PATCH | `/api/admin/avatar-parts/:id` | multipart เหมือน POST (ทุก field optional) · `remove_variant_ids[]` | 200 + item · audit `changed_fields` |
| PATCH | `/api/admin/avatar-parts/:id/status` | `{ status }` | 200 · audit hidden/unhidden |
| GET | `/api/admin/avatar-parts/:id/usage` | — | `{ user_count }` (เปิด modal ลบ) |
| DELETE | `/api/admin/avatar-parts/:id` | `{ confirm_name? }` (บังคับเมื่อ user_count > 100) | 0 คน → 200 ทันที · มีคน → 202 `{ job_id, total }` |
| GET | `/api/admin/avatar-parts/reset-jobs/:job_id` | — | `{ status, done, total }` (poll ทุก 1 s ระหว่าง modal เปิด) |

Error code (map 1:1 กับ toast/inline ใน ux-ui-plan §7–8 และ test-plan §2):

| HTTP | code | sentinel |
|---|---|---|
| 400 | `INVALID_FILE_TYPE` | `ErrInvalidFileType` |
| 400 | `FILE_TOO_LARGE` | `ErrFileTooLarge` |
| 400 | `INVALID_DIMENSIONS` | `ErrInvalidDimensions` |
| 400 | `NOT_TRANSPARENT` | `ErrNotTransparent` |
| 400 | `MISSING_SHEET` (+ `detail.sheet`, `detail.variant`) | `ErrMissingSheet` |
| 400 | `INVALID_CATEGORY` · `NAME_REQUIRED` · `NAME_TOO_LONG` · `INVALID_DATE_RANGE` · `VARIANT_REQUIRED` · `VARIANT_NAME_REQUIRED` · `VARIANT_NAME_TOO_LONG` · `INVALID_COLOR_TAG` | `ErrPart…` ตามชื่อ (prefix `ErrPart` เพราะ `ErrFileTooLarge` มีใน object_service แล้ว) |
| 400 | `CONFIRM_NAME_REQUIRED` · `CONFIRM_NAME_MISMATCH` | — |
| 404 | `PART_NOT_FOUND` | `ErrAccessoryNotFound` |
| 409 | `ACCESSORY_NAME_EXISTS` · `VARIANT_NAME_EXISTS` | `ErrNameExists` · `ErrVariantDuplicate` |
| 409 | `PART_DELETED` | `ErrAccessoryDeleted` |
| 503 | `STORAGE_NOT_CONFIGURED` | `ErrStorageNotConfigured` |

Layer: `handler/avatar_part_handler.go` (รับ input, validate ผิว) → `service/avatar_part_service.go` (logic, tx, `defer tx.Rollback`) → SQL inline ([02-design.md](../../../.claude/rules/02-design.md))

---

## 6. Upload + storage

- R2 ผ่าน `storage.S3Client.UploadPNG` เท่านั้น ([11-s3-storage.md](../../../.claude/rules/11-s3-storage.md))
- key: `static/avatar-part/{part_id}/{variant_id|base}/{walk|sit}-{uuid}.png` · thumbnail `…/thumb-{uuid}.png`
- **thumbnail ทำฝั่ง server:** ตัดเฟรม (ลง, col 1) ของชีทเดิน → วาดทับ base แบบเดียวกับ card ใน POC (ตัวละครใส่ชิ้น) → ขยาย nearest-neighbor → PNG · ไม่ต้องให้ client อัปโหลด thumbnail แยก (ต่างจาก avatar เดิม)
- ลำดับใน `Create`: validate ทุกไฟล์ก่อน → เปิด tx → insert → upload → commit · upload พัง → rollback แล้ว `DeleteObject` ไฟล์ที่ขึ้นไปแล้ว (test AC-U-33)
- replace ชีท: upload ใหม่ → update URL + `art_version = art_version + 1` → ลบไฟล์เก่า **หลัง** commit · `art_version` เปลี่ยน → `bake_hash` ของทุกชุดที่ใช้ชิ้นนี้เปลี่ยน → lazy re-bake ตาม AvatarCustomization §6 (ผู้ใช้เห็นภาพใหม่ครั้งถัดไปที่โหลดชุด)

---

## 7. สี

| หมวด | สีมาจาก | เก็บที่ |
|---|---|---|
| ทุกหมวดยกเว้น special | สี key ในไฟล์ → member เลือก palette ตอนแต่งตัว | `color_channels` (scan ตอนอัปโหลด) |
| `special_costume` | สีตามไฟล์ทั้งชิ้น · 1 variant = 1 สี | `tb_avatar_part_variant.color_tag` + `name` |

- **แถว 12 สี + แถบ Shade ในหน้า admin = preview อย่างเดียว ไม่บันทึก** (Figma: "Type อื่น เป็น Auto-generate") · ใช้ดูว่าชิ้นเปลี่ยนสีได้สวยไหมก่อนเปิดให้ผู้ใช้
- ชื่อ variant: admin พิมพ์เอง หรือกด generate จาก hex (sticky `7488:32649`) — ตาราง hex → ชื่อ อยู่ฝั่ง client (`lib/avatar-part/color-name.ts`)

---

## 8. Hide / Delete / Reset

### 8.1 Hide
`PATCH …/status {hidden}` → member catalog ไม่ส่งชิ้นนี้อีก (AV-API-09) · **ไม่แตะ `tb_user_outfit`** · `PUT /me/outfit` ที่มีชิ้น hidden: ถ้าเป็นชิ้นที่ผู้ใช้ใส่อยู่แล้ว (ตรงกับแถวเดิม) → ผ่าน · ถ้าเพิ่งเลือกใหม่ → 400 `PART_NOT_SELECTABLE`

### 8.2 Delete
```
DELETE /:id
  tx: SELECT … FOR UPDATE · ตรวจ confirm_name ถ้า user_count > 100
      UPDATE is_deleted, deleted_at · audit(deleted, affected_user_count)
      ถ้า user_count > 0 → INSERT tb_avatar_reset_job(total) 
  commit → 202 {job_id}
  go resetWorker(job_id)            (goroutine ใน process เดียว — replicas = 1 ตอนนี้)
```

### 8.3 Reset worker (EC-02)
```
loop:
  SELECT user_id, outfit FROM tb_user_outfit
   WHERE outfit @> {slots:{<slot>:{part_id:<id>}}}      -- query เดียวกับ §4.2
   ORDER BY user_id LIMIT 100 FOR UPDATE SKIP LOCKED
  ถ้าไม่มีแถว → job completed
  ต่อคน: ถอด slot ที่ใช้ชิ้นนี้ (slot บังคับ → ใส่ชิ้น default ของ slot) → bake (dedupe ด้วย bake_hash) → UPDATE แถว
  UPDATE job.done += n · commit
  ต่อคน: publish Redis {outfit_reset_user_id} (หลัง commit เท่านั้น)
```
- **resume ได้:** query หา "คนที่ยังใส่ชิ้นนี้" ทุกรอบ → job ตายกลางทางแล้วรันใหม่ ไม่ reset ซ้ำคนที่เสร็จแล้ว (AC-U-55) · ตอน api start ให้หยิบ job `running` ที่ค้างมารันต่อ
- **เมื่อ replicas > 1** (มีแผน [Autoscaling](../Autoscaling/)): หุ้ม worker ด้วย `pg_try_advisory_lock(hashtext(job_id))` — มี precedent `pg_advisory_xact_lock` ใน `pet_xp_config_service.go`

### 8.4 Hard delete หลัง 30 วัน
`cmd/avatar-cleanup` มีอยู่แต่ **ไม่เคยถูกรัน**: Dockerfile build แค่ `/app/server` และใน `zyra-infra` ไม่มี CronJob ของมัน → ทำเป็น **ticker ใน process** (ทุก 24 ชม. + `pg_try_advisory_lock` คงที่) ลบ R2 prefix `static/avatar-part/{id}/` ด้วย `DeleteByPrefix` แล้วลบแถว · S3 พังให้ log แล้วข้ามไปชิ้นถัดไป (AC-U-49) · ใช้ ticker เดียวกันลบชิ้นของ `tb_avatar` เดิมได้ด้วย (แก้บักนี้ในทีเดียว)

---

## 9. zyra-ws — แจ้งผู้ใช้ที่ online

ใช้ช่องทางเดิม: zyra-api publish Redis channel ของ notification (`internal/cache/notification.go` — `notificationEnvelope`) → zyra-ws subscribe อยู่แล้ว (`store/redis.go`, `notifyChannel`)

| ฝั่ง | งาน |
|---|---|
| zyra-api | เพิ่ม field `OutfitResetUserID string \`json:"outfit_reset_user_id,omitempty"\`` + `PublishOutfitReset(ctx, userID)` (แบบเดียวกับ `PublishUserDeleted`) |
| zyra-ws | เจอ field นี้ → ส่ง `{"type":"outfit_reset"}` ไปทุก socket ของ user นั้น · เพิ่ม `MsgOutfitReset` ใน `message.go` |
| zyra-app (VO) | ได้ `outfit_reset` → `GET /api/user/me/outfit` → อัปเดต avatar_url ของตัวเอง → ส่งใน `move` ถัดไป → room.go (`avatarChanged`) broadcast ให้คนอื่นเห็นเองตามกลไกเดิม |

ผู้ใช้ offline: ไม่ต้องทำอะไร — เข้า VO ครั้งหน้าได้ชุดใหม่จาก DB (AC-U-59)

---

## 10. zyra-app

```
app/admin/accessory-management/page.tsx          → HeroAccessoryManagement
views/admin/accessory-management/
  hero-accessory-management.tsx                    state: category, mode (list|add|view|edit)
  components/
    accessory-category-panel.tsx                   node 7508:36620 (ทำเสร็จใน branch feat/accessory-category-panel — PR #636 ปิดไว้ หยิบกลับได้)
    accessory-list-panel.tsx · accessory-card.tsx · accessory-pagination.tsx · accessory-filter-menu.tsx
    accessory-form.tsx                             add/view/edit · Save gating (test-plan §3.4)
    accessory-upload-table.tsx                     special costume variants
    accessory-dropzone.tsx                         หมวดอื่น
    accessory-preview.tsx                          canvas · tab Idle/Walking/Sitting · หมุน · เก้าอี้
    accessory-colour-picker.tsx · accessory-shade-slider.tsx
    accessory-delete-dialog.tsx                    3 แบบ + progress reset job
lib/api/avatar-parts.ts                            authFetch / authFetchForm → /api/admin/avatar-parts*
lib/avatar-part/
  render.ts        classifyKey · rampT · rampColor · paletteFor · drawLayer  (ยกจาก POC)
  shade.ts         shadeHex · shadeTrack  (POC: ขาว 85% / ดำ 75%)
  chair.ts         chairOffsets(composition, dir) — สูตร VO: piece − 176, เท้า = sitPoint + SIT_HIP_TO_FOOT_OFFSET_Y
  constants.ts     CATEGORIES (18), CATEGORY_LAYER, CATEGORY_REQUIRES_SIT, ACCESSORY_MAX_BYTES — parity กับ Go
  validate.ts      validateAccessoryFile (client-side ทันทีที่เลือกไฟล์)
components/ui/icon.tsx                             + icon 18 หมวด (custom SVG จาก Figma · currentColor)
components/admin/admin-sidebar.tsx                 + navAccessoryManagement (WandSparkles)
messages/{en,th}.json                              namespace AdminAccessoryManagement
i18n/messages-scope.ts                             + AdminAccessoryManagement ใน ADMIN_ONLY_NAMESPACES
```

- **เก้าอี้ใน preview:** อ่าน object จริงผ่าน `GET /api/objects` (UserGuard — admin ผ่าน) ด้วย id คงที่ `PREVIEW_CHAIR_OBJECT_ID` (Office Chair `498aac2c-…` บน dev · prod ต้องเลือก id ของ prod) · รูปผ่าน proxy `/api/img?url=` (CORS ของ canvas)
- **base + ตา default:** ไฟล์ base ใน repo (`public/avatar/base/walk.png`, `sit.png` 192×192) + ตาชิ้น default ของ slot `eyes` จาก catalog
- Tailwind อย่างเดียว ไม่ใช้ `components/ui/*` ที่เป็น interactive ([08-shadcn-ui.md](../../../.claude/rules/08-shadcn-ui.md)) · toast ใช้ `zyraToast`
- ใช้ TanStack Query: key `["admin","avatar-parts",category,filters,page]` · `["admin","avatar-parts","counts"]` · invalidate ทั้งสองหลัง create/update/delete

---

## 11. ระบบเดิม (Avatar management / `tb_avatar`)

คงไว้จนกว่า member ฝั่ง v2 (แต่งตัว) จะขึ้น prod — ตาม AvatarCustomization §9 · เมนู "Avatar management" อยู่ต่อ · หน้าใหม่เป็นเมนูแยก "Accessory management" (ตาม Figma) · ลบของเดิมเป็นงานแยกหลังจากนั้น

---

## 12. ความเสี่ยง / ต้องตัดสินใจก่อนเริ่ม

| # | เรื่อง | ผลถ้าไม่ตอบ | ตัดสินใจโดย |
|---|---|---|---|
| D1 | ขนาดชีท 48 vs 64 px | validator / renderer ผิดทั้งระบบ | PM + ศิลปิน (Q13) |
| D2 | พื้นไม่โปร่งใส = error หรือ warning | ข้อความ + test AC-U-10 | PM (U3) |
| D3 | สถานะเริ่มต้น Active หรือ Hidden | default ของฟอร์ม + API | PM |
| D4 | 18 หมวด → ขยาย data contract ฝั่ง member | member เลือกชิ้นหมวดใหม่ไม่ได้ | PM + Ten (U4) |
| D5 | Hair / Facial Hair ต้องมีชีทนั่งไหม | `CATEGORY_REQUIRES_SIT` | PM + ศิลปิน (U5) |
| D6 | AvatarCustomization A1 (สร้าง tb_avatar_part) ทำก่อนหรือรวมกับ migration 118 | ลำดับ PR | Ten |
| R1 | bake ต่อคนใน reset job — 892 คนอาจช้า | admin รอ progress นาน | วัดตอน API-5 · dedupe ด้วย bake_hash ช่วยได้มาก |
| R2 | `PREVIEW_CHAIR_OBJECT_ID` ต่างกันแต่ละ env | preview ไม่มีเก้าอี้ | ใส่ใน env build (`NEXT_PUBLIC_PREVIEW_CHAIR_ID`) หรือ fallback ไม่วาดเก้าอี้ |
