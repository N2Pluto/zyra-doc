# SC-AV-01 — Avatar List "จำนวนผู้ใช้งาน" ไม่ถูกต้อง (Fix Plan)

> สถานะ: **รอ review ก่อน implement**
> วันที่: 2026-07-17
> ผู้เขียน: dev (ผ่าน Claude Code)

---

## 1. อาการ (What's broken)

หน้า Admin → Avatar Management → Avatar List แสดง badge "จำนวนผู้ใช้งาน"
(`user_count`) ของแต่ละ avatar เป็นตัวเลขที่ไม่ถูกต้อง — จากการตรวจ dev DB
ทุก avatar (รวมทั้ง default) แสดง `user_count = 0` ทั้งที่มีผู้ใช้ 47 คนในระบบ

**หลักฐานจาก dev DB (`zyra-db` @ 35.247.177.198:3500):**

```
tb_user_avatar total rows = 0
tb_user        total rows = 47
→ ทุก avatar user_count = 0
```

---

## 2. Root cause

`user_count` มาจากตาราง `tb_user_avatar` (1 row = user 1 คน → avatar ที่ใช้)
แต่ **ไม่มีโค้ดที่ไหนเลยที่ INSERT/UPSERT ลง `tb_user_avatar`**

การเลือก avatar ของ member ถูกบันทึกลง **localStorage เท่านั้น**
(`saveSelectedAvatar` ใน `lib/avatar-selection.ts`) ไม่เคยส่งขึ้น backend

| จุด | ปัจจุบัน |
|---|---|
| `views/user/workspace-enter/components/change-character-modal.tsx:49` | `saveSelectedAvatar()` → localStorage |
| `views/user/workspace-enter/hero-workspace-enter.tsx:172` | `saveSelectedAvatar()` → localStorage |
| character **name** (บรรทัดถัดมา `hero-workspace-enter.tsx:185`) | ✅ ส่งขึ้น server แล้ว (`updateMyCharacterName`) |

การดำเนินการกับ `tb_user_avatar` ที่มีอยู่ทั้งหมดในโค้ด:
- **READ** — นับ count (`avatar_service.go` List/GetDetail/GetDefault)
- **UPDATE** — reassign เป็น default ตอนลบ avatar (`avatar_service.go:483`)
- **DELETE** — cleanup (`cmd/avatar-cleanup/main.go:140`)
- **INSERT** — ❌ ไม่มีเลย

→ ตาราง `tb_user_avatar` จึงว่างตลอด และ count = 0 เสมอ

> หมายเหตุ: `tb_user` ไม่มีคอลัมน์ avatar/character (มีแค่ `image_upload` = รูปโปรไฟล์)
> ดังนั้น DB ไม่มีข้อมูล avatar ที่ member เลือกอยู่เลย

### Secondary bug (latent)

Query นับ count ปัจจุบัน join แค่ `tb_user_avatar` ไม่ได้ join `tb_user`
→ เมื่อ populate ตารางแล้ว จะ **นับ user ที่ถูก ban / soft-delete ด้วย**
(`account_status IN ('banned','deleted')`) ทำให้ count เกินจริง

---

## 3. Decision (ยืนยันจากผู้ใช้ 2026-07-17)

**นิยาม "จำนวนผู้ใช้งาน" ของ avatar = "avatar ที่ผู้ใช้เห็นจริง" (effective avatar):**

- User ที่มี row ใน `tb_user_avatar` → นับให้ avatar ที่เลือก
- User ที่ **ยังไม่เคยเลือก** (ไม่มี row) → นับให้ **default avatar**
- นับเฉพาะ **countable member** = `role_ = 'MEMBER' AND account_status = 'active'
  AND deleted_at IS NULL` (ยืนยัน 2026-07-17: นับเฉพาะ role MEMBER, ตัด
  `suspended` + `banned` + `deleted` ทั้งหมด; `deleted_at IS NULL` ใส่ไว้ให้
  partial index `idx_user_group_status` ทำงาน)

**คุณสมบัติที่ต้องเป็นจริง:** ผลรวม `user_count` ทุก avatar = จำนวน countable user พอดี
(นับ user แต่ละคนครั้งเดียว)

**ผลทันทีหลัง fix:** ผู้ใช้ 47 คนที่ยังไม่มี row → default avatar = 47, ตัวอื่น = 0
ซึ่ง **ถูกต้อง** ตามนิยามนี้ (ทุกคนเห็น default จนกว่าจะเลือกเอง)
→ **ไม่ต้องมี backfill migration** เพราะ bucket "unselected → default" ครอบคลุมให้แล้ว

---

## 4. Where (กระทบส่วนไหน)

- `zyra-api` — เพิ่ม write endpoint + แก้ count query (service + handler + router)
- `zyra-app` — เพิ่ม API function + เรียกตอน save avatar 2 จุด
- DB — **ไม่มี migration ที่บังคับ** (ตาราง/‌index มีครบแล้ว); มี optional cleanup

---

## 5. API Contract (endpoint ใหม่)

### `PUT /api/user/me/avatar-selection` (UserGuard)

> ใช้ path `avatar-selection` เพราะ `POST /api/user/me/avatar` ถูกใช้โดย
> profile **photo** upload อยู่แล้ว — ห้ามชนกัน

**Request (JSON):**
```json
{ "avatar_id": "0306a25e-1d8d-475a-96bd-781eb0bc32bf" }
```

**Response — success:**
```json
{ "status": 200, "message": "success" }
```

**Response — error:**
| กรณี | status | message |
|---|---|---|
| avatar ไม่พบ / ถูกลบ | 404 | `avatar not found` |
| avatar status = hidden | 400 | `avatar not selectable` |
| avatar_id ว่าง/ไม่ใช่ uuid | 400 | `invalid avatar_id` |

> ใช้ `model.APIResponse` envelope ตาม rule 02
> member เลือกได้เฉพาะ avatar ที่ `status='active'` (ตรงกับ `/api/user/avatars` = active only)

---

## 6. Backend implementation

### 6.1 Service — `AvatarService.SetUserAvatar`

`internal/service/avatar_service.go`

```go
// SetUserAvatar upserts the caller's avatar selection into tb_user_avatar.
// Only an active (non-deleted) avatar may be selected.
func (s *AvatarService) SetUserAvatar(ctx context.Context, userID, avatarID string) error {
    // 1. ตรวจว่า avatar มีจริง + ไม่ถูกลบ + status='active'
    var status string
    err := s.db.QueryRow(ctx,
        `SELECT status FROM tb_avatar WHERE id = $1 AND is_deleted = FALSE`, avatarID,
    ).Scan(&status)
    if errors.Is(err, pgx.ErrNoRows) {
        return ErrAvatarNotFound
    }
    if err != nil {
        return fmt.Errorf("lookup avatar: %w", err)
    }
    if status != model.AvatarStatusActive {
        return ErrAvatarNotSelectable // sentinel ใหม่
    }

    // 2. upsert — trigger recount_tb_avatar_user_count ทำงานให้อัตโนมัติ
    _, err = s.db.Exec(ctx, `
        INSERT INTO tb_user_avatar (user_id, avatar_id, updated_at)
        VALUES ($1, $2, NOW())
        ON CONFLICT (user_id) DO UPDATE
          SET avatar_id = EXCLUDED.avatar_id, updated_at = NOW()`,
        userID, avatarID,
    )
    if err != nil {
        return fmt.Errorf("upsert user avatar: %w", err)
    }
    return nil
}
```

เพิ่ม sentinel: `var ErrAvatarNotSelectable = errors.New("avatar not selectable")`

### 6.2 แก้ count query (3 จุด — List / GetDetail / GetDefault)

นิยาม countable user (helper string ใช้ซ้ำ):
```sql
u.role_ = 'MEMBER' AND u.account_status = 'active' AND u.deleted_at IS NULL
```

**List** (`List`, ~บรรทัด 158) — แก้ subquery `uc` + เพิ่ม default bucket:
```sql
SELECT a.id, a.name, ...,
       COALESCE(uc.cnt, 0)
         + CASE WHEN a.is_default THEN (
             SELECT COUNT(*) FROM tb_user u
              WHERE u.role_ = 'MEMBER' AND u.account_status = 'active'
                AND u.deleted_at IS NULL
                AND NOT EXISTS (
                  SELECT 1 FROM tb_user_avatar ua WHERE ua.user_id = u.id)
           ) ELSE 0 END
       AS user_count,
       a.created_at, a.updated_at
  FROM tb_avatar a
  LEFT JOIN (
    SELECT ua.avatar_id, COUNT(DISTINCT ua.user_id) AS cnt
      FROM tb_user_avatar ua
      JOIN tb_user u ON u.id = ua.user_id
     WHERE u.role_ = 'MEMBER' AND u.account_status = 'active' AND u.deleted_at IS NULL
     GROUP BY ua.avatar_id
  ) uc ON uc.avatar_id = a.id
  WHERE ...
  ORDER BY user_count DESC   -- alias ครอบ CASE แล้ว → sort ถูกต้อง
```
> `ORDER BY user_count` (alias) ยังใช้ได้ เพราะ Postgres ยอมให้ order by output alias
> ซึ่งรวม CASE ครบ — ไม่ต้องแก้ logic sort เดิม

**GetDetail / GetDefault** — เปลี่ยน subquery เป็น:
```sql
(SELECT COUNT(*) FROM tb_user u
  WHERE u.role_ = 'MEMBER' AND u.account_status = 'active' AND u.deleted_at IS NULL
    AND (
      EXISTS (SELECT 1 FROM tb_user_avatar ua
               WHERE ua.user_id = u.id AND ua.avatar_id = a.id)
      OR (a.is_default AND NOT EXISTS (
            SELECT 1 FROM tb_user_avatar ua WHERE ua.user_id = u.id))
    )
) AS user_count
```

### 6.3 Handler — `AvatarHandler.SetMyAvatar`

`internal/handler/avatar_handler.go` — ดึง userID จาก `userIDFromContext(c)`
(pattern เดียวกับ profile handler), bind JSON `{avatar_id}`, map sentinel →
404/400, ตอบ `model.APIResponse{Status:200, Message:"success"}`

### 6.4 Route

`internal/router/router.go` — ใน user group (UserGuard):
```go
user.PUT("/me/avatar-selection", avatarHandler.SetMyAvatar)
```

---

## 7. Frontend implementation

### 7.1 API function — `lib/api/avatars.ts`

```ts
export interface SetAvatarSelectionResponse {
  status: number
  message: string
}

// Member persists their chosen in-game avatar to the server (feeds admin
// "user count"). Fire-and-forget at call sites — never blocks entering a space.
export async function setMyAvatarSelection(
  avatarId: string,
): Promise<SetAvatarSelectionResponse> {
  return authFetch<SetAvatarSelectionResponse>("/api/user/me/avatar-selection", {
    method: "PUT",
    body: JSON.stringify({ avatar_id: avatarId }),
  })
}
```

### 7.2 เรียกใช้ 2 จุด (fire-and-forget เหมือน character name)

**`change-character-modal.tsx` — `handleSave` (หลัง `saveSelectedAvatar`):**
```ts
setMyAvatarSelection(selectedAvatar.id).catch((err: unknown) => {
  console.warn("[change-character] avatar selection DB save failed:", err)
})
```

**`hero-workspace-enter.tsx` — `handleJoinSpace` (หลัง `saveSelectedAvatar`):**
```ts
if (avatarToSave) {
  saveSelectedAvatar({ ... })  // เดิม
  setMyAvatarSelection(avatarToSave.id).catch((err: unknown) => {
    console.warn("[workspace-enter] avatar selection DB save failed:", err)
  })
}
```

> เหตุผลที่ fire-and-forget: การเข้า space ต้องไม่ค้างเพราะ network — ตรงกับ
> pattern `updateMyCharacterName` ที่ทำอยู่แล้ว (`hero-workspace-enter.tsx:185`)

---

## 8. DB / Migration

- **ไม่มี migration บังคับ** — `tb_user_avatar` + index มีครบ (mig 27/28)
- Trigger `recount_tb_avatar_user_count` (mig 28) ทำงานกับ upsert อยู่แล้ว
  แต่ update เฉพาะคอลัมน์ denormalized `tb_avatar.user_count` (explicit-only,
  ไม่รวม default bucket) — คอลัมน์นี้ **ไม่ถูกใช้แสดงผลใน List/Detail/Default**
  (endpoint คำนวณ live) จึงปล่อยไว้ได้
- **Optional cleanup (ไม่บังคับ):** เพิ่ม filter countable user ในฟังก์ชัน trigger
  เพื่อให้คอลัมน์ denormalized ไม่รวม banned/deleted — ทำเป็น migration แยกภายหลัง

---

## 9. Testing / Verification

**Go unit (`avatar_service_test.go`):** test ปัจจุบันไม่ต่อ DB จริง (ทดสอบ
validation/audit helper) — เพิ่ม test สำหรับ `SetUserAvatar` เฉพาะส่วน
validation (avatar not found / hidden → sentinel) ได้เท่าที่ mock ไหว

**Manual DB verify (dev):** query ยืนยันสมบัติ "sum = countable users":
```sql
-- ต้องได้ = จำนวน countable user
SELECT SUM(uc) FROM (
  SELECT a.id,
    COALESCE((SELECT COUNT(DISTINCT ua.user_id) FROM tb_user_avatar ua
       JOIN tb_user u ON u.id=ua.user_id
      WHERE ua.avatar_id=a.id
        AND u.role_ = 'MEMBER' AND u.account_status = 'active' AND u.deleted_at IS NULL),0)
    + CASE WHEN a.is_default THEN
        (SELECT COUNT(*) FROM tb_user u
          WHERE u.role_ = 'MEMBER' AND u.account_status = 'active' AND u.deleted_at IS NULL
            AND NOT EXISTS (SELECT 1 FROM tb_user_avatar ua WHERE ua.user_id=u.id))
      ELSE 0 END AS uc
  FROM tb_avatar a WHERE a.is_deleted=FALSE
) x;
```

**E2E preview:** เลือก avatar → join space → เปิด Admin Avatar List →
ตัวเลข default ลดลง 1, avatar ที่เลือกเพิ่มขึ้น 1

---

## 10. Task breakdown (PR-sized)

1. `feat(api): add PUT /api/user/me/avatar-selection (upsert tb_user_avatar)`
   — service `SetUserAvatar` + sentinel + handler + route
2. `fix(api): count avatars by effective avatar, exclude banned/deleted users`
   — แก้ List/GetDetail/GetDefault query
3. `feat(app): persist member avatar selection to server`
   — `setMyAvatarSelection` + เรียก 2 จุด
4. `test(api): SetUserAvatar validation + manual DB count verify`

---

## 11. Out of scope (ไม่ทำในรอบนี้)

- ❌ ไม่ backfill localStorage เดิมของ 47 users (ทำไม่ได้ฝั่ง server; default
  bucket ครอบคลุมแล้ว)
- ❌ ไม่แก้ trigger denormalized column (optional, แยก PR)
- ❌ ไม่แตะ ClickUp status (ตาม rule 13)
