# รูปโปรไฟล์หายทุกครั้งที่ล็อกอิน Google ใหม่ (ZYR-1137)

> **สถานะ:** แก้แล้ว 2026-09-01 — unit test เขียว 10/10 + ผ่าน mutation check (โค้ดเดิม fail 5 เคส) · **ยังไม่ live-test บน dev** · **repo:** zyra-api
> **ที่มา:** support ticket ZYR-1137 (impact: "Annoyance / Visual Glitch") · **branch:** zyra-api `fix/google-login-clobbers-profile`
> **สำคัญ:** สาเหตุ **ไม่ใช่** S3/R2 และ **ไม่ใช่** การกด Save โปรไฟล์ — เป็น Google login เขียนทับ DB

## อาการที่รายงาน

> รูปโปรไฟล์ที่ตั้งไว้ พอกดอัพเดตชอบหาย เมื่อ wab มีการ อัพเดต หรือ มีการปิดไปนานๆ — เลยต้องกลับมา upload ใหม่

กุญแจของเคสนี้คือ trigger สองอย่างที่ผู้ใช้บอก ("เว็บอัพเดต" = redeploy, "ปิดไปนานๆ" = session
หมดอายุ) มี**จุดร่วมเดียว**: ทั้งสองกรณีบังคับให้ผู้ใช้ **ล็อกอินใหม่** อาการจึงไม่ได้เกี่ยวกับ
storage หรือฟอร์มโปรไฟล์เลย

## Root cause — `LoginGoogle` เขียนทับ field ที่ user เป็นเจ้าของ

`zyra-api/internal/service/auth_service.go` branch ของบัญชีที่ **สร้างผ่าน Google**
(หาเจอด้วย Google `sub` → `findUserByID`) เขียนค่าจาก claims กลับลง DB แบบไม่มีเงื่อนไข:

```go
} else {
    user.Name        = givenName
    user.Lastname    = familyName
    user.Email       = email
    user.IsVerified  = "Y"
    user.Role        = "MEMBER"
    user.AuthenType  = "GOOGLE"
    user.ImageUpload = ptrOrNil(picture)   // ← ทับรูปที่ user อัปโหลดเอง
    if err := updateUser(ctx, tx, user); err != nil { ... }
```

`updateUser` เป็น full-row UPDATE — `set role_ = $1, name = $2, lastname = $3,
image_upload = $4, …` ไม่มี COALESCE ไม่มี guard → ทุก field ข้างบนลง DB จริงทุกครั้ง

ผลทุกครั้งที่กด "Sign in with Google":

| field | ผลที่เกิด |
|---|---|
| `image_upload` | ← Google `picture` claim → **รูป R2/GCS ที่ user อัปโหลดเองหายไป** (object เก่าค้างบน S3 ด้วย เพราะ path นี้ไม่เรียก `deleteOldAvatar`) |
| `image_upload` (บัญชี Google ที่ไม่มีรูป) | `picture == ""` → `ptrOrNil("")` = `nil` → **`image_upload = NULL`** → เหลือแต่ initials |
| `name` / `lastname` | ← Google claims → ชื่อที่ user แก้ในหน้า Profile ถูก revert |
| `role_` | ← `"MEMBER"` → **ADMIN/SYSADMIN ที่ล็อกอินด้วย Google ถูกลดสิทธิ์** |

`display_name` / `bio` ไม่อยู่ใน SET list ของ `updateUser` → ไม่ถูกแตะ ตรงกับที่ผู้ใช้รายงานว่า
หาย "แต่รูป"

`views/login/components/welcome-back-google.tsx` ใน zyra-app เป็น flow "Welcome back" ที่ทำไว้
สำหรับ returning Google user โดยเฉพาะ → เส้นทางนี้ถูกเดินบ่อยมาก จึง "หายทุกรอบ" จริง

**หลักฐานว่าเป็นบั๊ก ไม่ใช่ดีไซน์:** branch พี่น้องในฟังก์ชันเดียวกัน (บัญชีที่สมัครด้วย email
แล้วมาล็อกอิน Google) *มี* guard ถูกอยู่แล้ว:
```go
if existingByEmail.ImageUpload == nil && picture != "" {
    existingByEmail.ImageUpload = ptrOrNil(picture)
}
```

## สิ่งที่ตรวจแล้วว่า *ไม่ใช่* สาเหตุ

- **`PUT /api/user/me` ไม่ได้ blind-write ค่าว่าง** — `ProfileService.UpdateProfile` มี branch
  ที่สามที่ **ไม่แตะ** `image_upload` เลยเมื่อไม่ได้ส่ง avatar → กด Save โปรไฟล์เฉยๆ ไม่ทำรูปหาย
- `clear_avatar` ถูกส่งเฉพาะเมื่อ user กดยืนยันใน delete dialog (`hero-profile.tsx`)
- `updateUser` call site อื่นทุกจุด (register ×6, forgot-password ×2) โหลด row จาก DB ก่อนเสมอ
  → `image_upload` round-trip ครบ Google login เป็นจุดเดียวที่ผิด
- `SaveAvatarTemp` ไม่เขียน DB เลย → temp path ไม่เคยหลุดลง `image_upload`

## สิ่งที่แก้

`internal/service/auth_service.go` — แยก merge logic เป็น pure function `mergeGoogleClaims`
(+ type `googleClaims`) แล้วให้ branch นั้นเรียกใช้:

- `Email` / `IsVerified` / `AuthenType` → Google เป็นเจ้าของ เขียนตามเดิม
- `ImageUpload` → set เฉพาะเมื่อ `user.ImageUpload == nil && claims.Picture != ""`
- `Name` / `Lastname` → set เฉพาะเมื่อค่าเดิมว่าง (`strings.TrimSpace(...) == ""`)
- `Role` → ลบ `= "MEMBER"` ออก คง role เดิมจาก DB; default เป็น MEMBER เฉพาะเมื่อ row ไม่มี role

ไม่แตะ branch สมัครใหม่ (`insertUser`) และไม่แตะ branch email-matched ที่ถูกอยู่แล้ว
ฝั่ง zyra-app ไม่ต้องแก้ — `persistSession` อ่าน `image_upload` จาก login response อยู่แล้ว
เมื่อ backend ไม่ทับค่า response ก็พารูปเดิมกลับมาเอง

## Verify ถึงไหน

- `go test ./internal/service/... -run TestMergeGoogleClaims -v` → **PASS 10/10 subtests**
- **Mutation check:** ย้อน guard ออกให้เป็นพฤติกรรมเดิม → fail 5 เคสตรงตามอาการ
  (รูปถูกทับ, รูปถูก NULL, ชื่อถูก revert, ADMIN ถูกลด, SYSADMIN ถูกลด) แล้ว restore กลับ pass
- `go vet ./...` clean · `go build ./...` OK · `go test ./...` → 15 packages ok, 0 FAIL
- **ยังไม่ได้ทำ:** live E2E บน dev (Google login → อัปรูป → logout → Google login ซ้ำ) และ
  ยังไม่ได้ query prod ดู blast radius

## ต่อจากนี้

1. Live E2E บน dev ตามขั้นตอนใน `plan` — ต้องใช้บัญชีที่ **สมัครผ่าน Google** (`tb_user.id` = Google `sub`)
2. Query prod (read-only) ดูจำนวนผู้ที่โดนไปแล้ว:
   ```sql
   SELECT count(*) FROM tb_user WHERE authentype = 'GOOGLE' AND image_upload LIKE '%googleusercontent%';
   SELECT count(*) FROM tb_user WHERE authentype = 'GOOGLE' AND image_upload IS NULL;
   SELECT id, email, role_ FROM tb_user WHERE authentype = 'GOOGLE' AND role_ <> 'MEMBER';
   ```
   ผู้ใช้ที่รูปถูกทับไปแล้วต้องอัปโหลดใหม่เองอีกครั้ง (รูปเดิมถูกลบทิ้งจาก S3 ไปแล้วในรอบที่
   commit อันใหม่ — กู้คืนอัตโนมัติไม่ได้)

## ปัญหาที่เจอระหว่างสืบ แต่กันออกไปเป็น PR แยก (ยืนยันกับผู้ใช้แล้ว)

### P1 — legacy local path ค้างใน DB ไม่มี backfill
ก่อน commit `8e13cd7 feat(profile): integrate S3 client for avatar uploads` (2026-05-20) มี
local fallback ที่เก็บ `/uploads/profiles/<userID>_full.jpg` ลง `tb_user.image_upload` ตรงๆ
commit นั้นลบ fallback ทิ้งแต่ **ไม่มี migration ย้อนหลัง** (ตรวจครบ 107 ไฟล์ใน
`zyra-api/migrations/`) และ `router.go` เสิร์ฟ `/uploads` จาก `./static/uploads` ซึ่ง
**ไม่มีอยู่ใน image เลย** → row เหล่านั้นรูปพังถาวร
เสนอ: migration set เป็น NULL เพื่อให้ fallback เป็น initials แทนรูปแตก
นับจำนวน: `SELECT count(*) FROM tb_user WHERE image_upload IS NOT NULL AND image_upload NOT LIKE 'http%';`

### P2 — temp avatar staging อยู่บน ephemeral disk
`SaveAvatarTemp` เขียนไฟล์ลง `TEMP_AVATAR_DIR` (prod = `/tmp/zyra/avatar`) แล้ว
`commitAvatarToS3` อ่านกลับตอนกด Save — chart `zyra-infra/gitops/charts/zyra-service`
ไม่มี volume/PVC เลย ถ้ามี rollout คั่นระหว่าง crop กับ Save → `read temp avatar: no such file`
→ **การ save โปรไฟล์ทั้งก้อน fail 500** (ชื่อ/bio ไปด้วย)
นอกจากนี้ route `/profile-file` ชี้ `./static/profile/file` แต่ prod เขียนลง `/tmp/zyra/avatar`
→ **route นี้ 404 by construction** (frontend workaround ไปแล้วด้วย blob URL ใน
`upload-avatar-modal.tsx` — มี comment ยอมรับไว้ว่า "unreliable on prod")
เสนอ: stage ลง R2 แทน local disk แล้วลบ route `/profile-file` + `/uploads`

### บั๊ก bio ถูกล้าง (คนละเรื่องกับตั๋วนี้)
`zyra-app/views/user/workspace-enter/hero-workspace-enter.tsx` เรียก `updateProfile()` ตอน
join space เพื่อ mirror character name ลง `display_name` แต่ส่ง `bio: profileMetaRef.current.bio`
ซึ่ง **ไม่เคยถูก populate** (set แค่ `name`/`lastname`) → ทุกครั้งที่เข้า workspace แล้วเปลี่ยน
ชื่อตัวละคร **bio ของ user ถูกเขียนทับเป็น `""`** (`image_upload` ปลอดภัยเพราะไม่ได้ส่ง avatar field)

### S3 hygiene
- `deleteOldAvatar` หา thumb key ด้วย `strings.Replace(key, "_full.jpg", "_thumb.jpg", 1)` แต่
  temp-commit flow เก็บ full image เป็น `<uuid>.jpg` → `thumbKey == key` → **thumbnail เก่าไม่เคยถูกลบ**
- `_thumb.jpg` ถูก generate + upload ทุกครั้งแต่ **ไม่มี column ไหนเก็บและไม่มี query ไหนอ่าน** — dead weight
- `zyra-app/lib/api/profile.ts` `uploadAvatar()` (ยิง `POST /api/user/me/avatar`) เป็น **dead code** ไม่มี caller

---

## รอบที่ 2 — 2026-09-01 · รูปใน hover tag ของ private zone ไม่อัปเดต

> **สถานะ:** แก้แล้ว — vitest เขียว 30/30 + ผ่าน mutation check (no-op fail 5 เคส) · `next build` ผ่าน · **ยังไม่ live-test ใน VO** · **repo:** zyra-app
> **branch/PR:** zyra-app `fix/zone-claim-avatar-stale` → [zyra-app#233](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/233)
> **คนละ root cause กับรอบที่ 1** — รอบนี้เป็น client-side cache ไม่ใช่ DB ถูกเขียนทับ

### อาการที่รายงาน

> รูปตอนที่ไป hover ที่ zone นั้นไม่ได้เปลี่ยนไปด้วยเมื่อ upload profile ใหม่ไป

(แนบ screenshot: tag "Tester Ten's zone" ตอน hover โซนใน VO ยังโชว์รูปเดิม)

### Root cause — TanStack Query cache ไม่มีใคร invalidate เมื่อรูปเปลี่ยน

Backend **ถูกอยู่แล้ว**: `PrivateZoneClaimService.List` resolve `owner_name` / `owner_avatar_url`
ด้วย `JOIN tb_user` ตอนอ่าน (`COALESCE(u.image_upload, '')`) และ `tb_private_zone_claim`
(migration 58) เก็บแค่ `zone_name` — **ไม่มี snapshot ของรูปในตาราง** ตรวจแล้วทั้ง
`resolveOwnerIdentity` และ `List`

ปัญหาอยู่ที่ query `["zone-claims", workspaceId]` (`hooks/use-zone-claims.ts`) ที่ถูก
invalidate **เฉพาะ** เมื่อ claim เปลี่ยน — `zone_claim_changed`, `welcome`, และ
claim/unclaim actions **ไม่มีอะไร invalidate มันเมื่อรูปโปรไฟล์เปลี่ยน**

handler `profile_updated` ใน `hero-virtual-office.tsx` อัปเดต `otherPlayers` +
`allWorkspaceMembers` (รวม `avatar_url`) อยู่แล้ว แต่ไม่แตะ cache ก้อนนี้ →
nameplate กับ member panel สด แต่ tag โซนค้าง

**เสียทั้งสองทาง:**

| ใคร | ทำไมค้าง |
|---|---|
| peers | ได้ event `profile_updated` แต่ cache ไม่ถูก patch |
| คนที่อัปโหลดเอง | `Room.handleProfileUpdated` relay ด้วย `broadcastExcept(msg, c.UserID)` → **ผู้ส่งไม่ได้รับ event ของตัวเอง** เลยไม่มีสัญญาณอะไรมาอัปเดตเลย |

เคสที่ผู้ใช้เจอคือแบบที่สอง (hover โซนของตัวเอง) — เกิดเมื่ออัปโหลดจาก VO Settings → Profile
แล้วอยู่ใน VO ต่อโดยไม่ reload (ถ้าอัปโหลดจากหน้า `/profile` แล้วเดินกลับเข้า VO query จะ
refetch ตอน mount ทำให้ไม่เห็นอาการ)

### สิ่งที่แก้

เพิ่ม pure helper `applyOwnerProfileToClaims` ใน `lib/api/private-zone-claims.ts`
(อยู่กับ `displayZoneName` / `zoneClaimNameMap`) แล้วเรียกจาก 2 จุดใน `hero-virtual-office.tsx`:
handler `profile_updated` (สำหรับ peers) และ `onProfileSaved` (สำหรับตัวเอง เพราะไม่มี echo)

- `avatarUrl === ""` = ค่าจริง (ลบรูป → initials) · เฉพาะ `undefined` ที่คงค่าเดิม
- `owner_name` อัปเดตด้วย precedence ตาม server: `character_name || display_name || เดิม`
  (tag render `owner_name` จาก row เดียวกัน ถ้าแก้แต่รูปจะเป็นการแก้ครึ่งเดียว)
- แก้ cache ก้อนเดียว → ครอบทั้ง `pz-zone-hover.tsx` และ `pz-zone-card.tsx` (2 จุดเดียวที่อ่าน `owner_avatar_url`)
- ใช้ `setQueryData` ไม่ใช่ `invalidateQueries` — payload มีข้อมูลครบ ไม่ต้องยิง REST ซ้ำ และ
  ไม่ต้องเพิ่ม dep ใหม่ให้ effect ก้อนใหญ่ (`queryClient` อยู่ใน scope นั้นแล้ว — ถ้าประกาศ
  `useCallback` ทีหลังในไฟล์แล้วใส่ใน dep array ของ effect ที่อยู่ก่อนหน้าจะเจอ TDZ)

`avatar_url` ใน `ProfileUpdatedPayload` เป็นรูปโปรไฟล์ ไม่ใช่ spritesheet (comment ใน
`room.go` ระบุไว้: "Deliberately does NOT touch c.AvatarURL") — ตรงตามกฎ
photo-or-initials-never-sprite

### Verify ถึงไหน

- `npx vitest run __tests__/private-zone-claims.test.ts` → **30 passed** (เดิม 20 + ใหม่ 10)
- **Mutation check:** ทำ helper เป็น no-op → fail 5 เคส รวมเคสตรงอาการ
  ("pushes a new photo onto the owner's claim") แล้ว restore กลับ pass 30/30
- `npx tsc --noEmit` ไม่มี error ใหม่ — 2 error ใน `__tests__/pixi-game-scene.test.ts`
  (`RemotePlayerSnapshot.avatar_url`) **มีอยู่ก่อนแล้วบน develop** ยืนยันด้วยการ stash แล้วรันซ้ำ
- `npx eslint` ไฟล์ที่แก้ clean · `npx next build` สำเร็จ (route `/workspace/[id]/play` ผ่าน)
- **ยังไม่ได้ทำ:** live E2E ใน VO — ต้อง login ซึ่ง AI พิมพ์รหัสผ่านเองไม่ได้
  ขั้นตอนที่ต้องลอง: hover โซนที่ claim ไว้ → VO Settings → Profile → อัปโหลดรูป → Save →
  hover โซนเดิม รูปต้องเปลี่ยนทันทีโดยไม่ reload (เช็กทั้งฝั่งเจ้าของและฝั่ง peer)

### ต่อจากนี้ / ยังค้าง

- อัปโหลดจากหน้า `/profile` ตรงๆ **ไม่ broadcast `profile_updated`** เลย เพราะหน้านั้นไม่มี
  WS client → peer ที่อยู่ใน VO เห็นรูปเก่าทุก surface (nameplate, member panel, zone tag)
  จนกว่าจะ reload ตัวเจ้าของไม่มีปัญหาเพราะ query refetch ตอน mount เข้า VO
  แก้ได้โดยให้หน้า `/profile` แจ้ง VO (เช่นผ่าน storage event / BroadcastChannel) หรือให้
  server relay จาก REST — **ยังไม่ทำ คนละ scope**
- **develop มี tsc error ค้างอยู่ 2 ข้อ** ใน `__tests__/pixi-game-scene.test.ts`
  (`avatar_url` ไม่มีใน `RemotePlayerSnapshot`) — ไม่ได้เกิดจาก PR นี้ แต่ควรมีคนแก้

---

## รอบที่ 3 — 2026-09-01 · วัด blast radius บน prod + เตรียมสคริปต์กู้รูป

> **สถานะ:** fix ทั้งชุด merge เข้า develop แล้ว (dev) · **prod ยังมีบั๊ก** · สคริปต์กู้รูปเตรียมไว้แล้ว **ยังไม่รัน**
> **ต้องทำตามลำดับ:** release zyra-api ขึ้น prod **ก่อน** แล้วค่อยรันสคริปต์กู้

### ตัวเลขจริงบน prod (read-only, ผ่าน IAP tunnel)

| | จำนวน |
|---|---|
| ผู้ใช้ทั้งหมด | 142 |
| บัญชี Google | **127** (89% ของทั้งระบบ) |
| `image_upload` เป็น URL ของ Google ตอนนี้ | 121 |
| `image_upload` เป็นรูปที่อัปโหลดเอง | 8 |
| `image_upload` เป็น NULL (บัญชี Google) | 1 |
| **legacy `/uploads/profiles/*`** | **0** |

**P1 ที่บันทึกไว้ในรอบที่ 1 ตกไป** — ไม่มี legacy local path เหลือบน prod เลย ไม่ต้องทำ migration backfill

### รูปที่ถูกทับ "ยังอยู่" — กู้คืนได้ 20 คน

Google-login path ไม่เคยเรียก `deleteOldAvatar` → object ที่ผู้ใช้อัปโหลดยังค้างในบัคเก็ต
`gs://zyra-prod-gather-dev-458614/profiles/<userID>/`

- บัคเก็ตมีไฟล์รูปเต็ม **44 ไฟล์ จาก 28 คน** (หลายคนมีหลายเวอร์ชันเพราะ delete ไม่เคยทำงาน)
- cross-reference กับ DB: **20 คน** DB ชี้ Google URL แต่รูปตัวเองยังอยู่ → **กู้ได้ ไม่ต้องอัปโหลดใหม่**
- อีก 8 คนยังชี้รูปตัวเองอยู่ ปกติดี — ไม่อยู่ในรายการกู้

20 คนนั้น (เรียงตามวันที่อัปโหลดรูปที่จะกู้):

| อัปโหลดเมื่อ | อีเมล |
|---|---|
| 2026-08-31 | pup@hpktechnology.com · game.ponlawat.lk@gmail.com |
| 2026-08-27 | jane@hpktechnology.com · ja@hpktechnology.com |
| 2026-08-25 | pai@hpktechnology.com · got@hpktechnology.com |
| 2026-08-24 | tonkaow@hpktechnology.com |
| 2026-08-21 | team@hpktechnology.com · oat_cs@hpktechnology.com · jeen@hpktechnology.com |
| 2026-08-20 | trust_uxui@ · ruj_cs@ · pingpong@ · peach_cs@ · golf_cs@ · earth@ · bank_cs@ |
| 2026-08-19 | tum@hpktechnology.com |
| 2026-07-21 | poom@hpktechnology.com |
| 2026-07-20 | witsanu.sj@gmail.com |

### ยืนยันบั๊ก thumbnail กำพร้าจากข้อมูลจริง

บัคเก็ตมี 96 object แต่เป็นรูปเต็มแค่ 44 → **มี `_thumb.jpg` ที่ไม่มีตัวเต็มคู่กัน 8 ไฟล์**
ตรงกับที่รายงานไว้ว่า `deleteOldAvatar` หา thumb ด้วย `_full.jpg` → `_thumb.jpg` ซึ่งไม่ match
key ของ temp-commit (`<uuid>.jpg`) ตัวอย่าง: `profiles/104236071591997276879/64c5af03-..._thumb.jpg`

### สคริปต์ที่เตรียมไว้ (ยังไม่รัน)

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `ops/restore-clobbered-profile-photos-2026-09-01.sql` | UPDATE กู้รูป 20 คน (ต้อง `--write`) |
| `ops/restore-clobbered-profile-photos-2026-09-01-dryrun.sql` | read-only preview ว่าจะแก้แถวไหน |

คุณสมบัติของสคริปต์:
- **รันซ้ำได้ปลอดภัย** — `WHERE image_upload LIKE '%googleusercontent%'` จึงไม่ทับรูปของคนที่
  อัปโหลดใหม่เองไปแล้วหลังจากทำรายการนี้
- เลือก object ที่ **ใหม่สุด** ต่อคน = รูปที่เขาเลือกไว้ล่าสุด
- **verify กับ prod แล้วแบบ read-only**: dry-run คืนมา **20 แถวพอดี** ตรงกับรายการข้างบน
  (SQL parse ผ่าน, array จับคู่ถูก) หลังกู้สำเร็จ dry-run ต้องคืน 0 แถว
- คาดหมายผลรวม: `own_photos` 8 → 28, `google_pics` 121 → 101

### ⚠️ ลำดับสำคัญ — ห้ามรันก่อน release

fix ที่กันการทับ (`b1ab1a7`, PR #58) **อยู่แค่ develop** prod ยังทับอยู่ทุกครั้งที่มีคนล็อกอิน Google
ถ้ารันสคริปต์ตอนนี้ ทั้ง 20 คนจะถูกทับใหม่ในการล็อกอินครั้งถัดไป → เสียเปล่า

ลำดับที่ถูก:
1. release **zyra-api** ขึ้น prod (develop → main → tag `v*`) — develop นำ main อยู่ 6 commits
   และ **เป็นงานชุดนี้ทั้งหมด ไม่มีของคนอื่นปน** (Google clobber + security audit + delete ordering/temp key)
2. รัน dry-run ยืนยันว่ายังได้ 20 แถว
3. รันสคริปต์กู้ ด้วย `--write`
4. รัน dry-run ซ้ำ ต้องได้ 0 แถว

**zyra-app release แยกเรื่อง** — develop นำ main อยู่ 12 commits และมี `feat/pet-management-xp`
(#234) ของคนอื่นปนอยู่ ซึ่งยังไม่ผ่านการ verify ในรอบนี้ เป็นการตัดสินใจของ PM
(fix ที่กันการทับอยู่ใน zyra-api เท่านั้น จึงไม่ต้องรอ app release เพื่อกู้รูป)
