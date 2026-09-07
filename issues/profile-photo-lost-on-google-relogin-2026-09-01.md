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
