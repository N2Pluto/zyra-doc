# dev zyra-api รีสตาร์ทไม่ขึ้น — CHECK constraint ของ tb_notification

> **สถานะ:** ✅ **แก้แล้ว · ยืนยันบน dev แล้ว** (PR #110 → `develop` → Argo sync 2026-09-10 08:41 UTC)
> **วันที่พบ:** 2026-09-10 · **repo ที่กระทบ:** `zyra-api` (โค้ด) · `zyra-app` branch `feat/spotlight` (ต้นเหตุของข้อมูล)
> **เจอตอน:** restart dev zyra-api เพื่อให้รับ `ENVIRONMENT_ENABLED` + `GOOGLE_MAPS_API_KEY` ใหม่ (SC-ENV-01)

## อาการ

`kubectl -n dev rollout restart deploy/zyra-api` → pod ใหม่ **CrashLoopBackOff** ทันที pod เก่ายังรันอยู่ rollout เลยค้าง dev ไม่ล่ม

```
init db failed: run migrations: migration failed
"ALTER TABLE tb_notification ADD CONSTRAINT tb_notification_type_check
 CHECK (type IN ('dm','mention','reply','group_add','reaction','zone_force_unclaimed',
                 'announcement','pet_growth','pet_milestone','pet_reminder'))":
ERROR: check constraint "tb_notification_type_check" of relation "tb_notification"
       is violated by some row (SQLSTATE 23514)
```

## Root cause

`internal/database/postgres.go` รัน migration ตอนบูตทุกครั้ง โดย **DROP แล้ว ADD** constraint นี้ใหม่ ⇒ ถ้ามีแถวไหนที่ `type` ไม่อยู่ในลิสต์ **บูตไม่ผ่าน**

ใน dev DB มี `type = 'spotlight_live'` อยู่ **25 แถว** ซึ่งไม่มีในลิสต์:

| type | count |
|---|---|
| dm | 130 |
| group_add | 37 |
| pet_reminder | 35 |
| **spotlight_live** | **25** ← ไม่อยู่ในลิสต์ |
| mention | 20 |
| announcement | 14 |
| reaction | 14 |
| reply | 10 |
| pet_milestone | 5 |
| zone_force_unclaimed | 4 |

- แถวแรก `2026-09-09 10:10:43 UTC` · แถวล่าสุด `2026-09-10 07:54:14 UTC`
- pod ที่รันอยู่ตอนพบ อายุ 22 ชม. (บูตราว 2026-09-09 10:20 UTC) ⇒ **dev zyra-api รีสตาร์ทไม่ขึ้นมาตั้งแต่ 2026-09-09 ~10:10 UTC** ใครก็ตามที่ restart / node evict / OOM หลังจากนั้นจะทำ dev API ล่ม
- `grep -r spotlight_live` ใน `zyra-api` / `zyra-ws` / `zyra-notifications` บน `develop` **ไม่เจอเลย** — เจอเฉพาะ `zyra-app` commit `9bf86d4` บน branch **`origin/feat/spotlight`** (Apiwat, 2026-09-09) ⇒ ฟีเจอร์ Spotlight เขียน notification type ใหม่ลง dev DB แต่**ยังไม่ได้เพิ่ม type นั้นเข้าลิสต์ฝั่ง api**
- โค้ดตรงนั้นมีคอมเมนต์เตือนกับดักนี้ไว้เองอยู่แล้ว: *"...its inserts then fail — which is exactly what happened to the pet_* types added in migration 90"* — เคสเดิมซ้ำรอบสอง

## ผลข้างเคียงที่เกิดขึ้นแล้ว

statement แต่ละอันคอมมิตแยกกัน ⇒ **DROP สำเร็จ แต่ ADD ล้ม** ⇒ ตอนนี้ **dev DB ไม่มี `tb_notification_type_check` เหลืออยู่เลย** (ยืนยันด้วย `SELECT conname FROM pg_constraint` = 0 rows) constraint จะกลับมาเองเมื่อมี pod บูตผ่านสักตัว ซึ่งต้องแก้ตามข้างล่างก่อน

rollout ถูก `rollout undo` กลับไปแล้ว — RS เก่า (`zyra-api-75df6c5f79`) กลับมา 1/1 · RS ที่ crash (`zyra-api-7fb54f4874`) scale เหลือ 0 · dev กลับมาสถานะเดิมก่อน restart

## วิธีแก้ — ทำแล้ว ([zyra-api#110](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/110), squash-merge เข้า `develop` 2026-09-10)

เพิ่ม `'spotlight_live'` เข้าลิสต์ใน `internal/database/postgres.go` + เทสต์ `TestNotificationTypeCheckListsEveryKnownType` ที่ pin ลิสต์ไว้ (รวม type ที่ repo นี้ไม่ได้เขียนเอง ซึ่งเป็นเคสที่ compiler และเทสต์เดิมจับไม่ได้) — pod ใหม่จะบูตผ่านและสร้าง constraint กลับมาเอง

```go
CHECK (type IN ('dm', 'mention', 'reply', 'group_add', 'reaction', 'zone_force_unclaimed', 'announcement',
                'pet_growth', 'pet_milestone', 'pet_reminder', 'spotlight_live'))
```

**ทางที่ห้ามทำ:** ลบ 25 แถวนั้นทิ้ง — ฟีเจอร์ Spotlight ยังเขียนเข้ามาเรื่อย ๆ เดี๋ยวก็กลับมาใหม่ และตอนนั้น insert จะเริ่ม fail แทน (เพราะ constraint จะมีแล้ว)

## กันไม่ให้เกิดซ้ำ

migration แบบ DROP-แล้ว-ADD constraint ที่รันตอนบูตทุกครั้ง = **ทุกแถวที่ service อื่นเขียนเข้ามาสามารถทำให้ api บูตไม่ขึ้นได้** และจะไม่มีใครรู้จนกว่าจะ restart ครั้งถัดไป (ที่นี่คือ 22 ชม.ให้หลัง) — ควรพิจารณา:

- เพิ่ม type ใหม่เข้าลิสต์ **ใน PR เดียวกับที่เริ่มเขียน type นั้น** ไม่ว่าจะเขียนจาก repo ไหน
- หรือ `NOT VALID` constraint (ตรวจเฉพาะแถวใหม่ ไม่ล้มตอนบูตเพราะแถวเก่า)

---

## ยืนยันผลแล้ว (2026-09-10 08:41 UTC)

| | ก่อนแก้ | หลังแก้ |
|---|---|---|
| pod ใหม่บูต | ❌ CrashLoopBackOff (restart 4 ครั้งใน 2m37s) | ✅ `zyra-api-c8858fddc-lrfmn` **1/1 Running** · `zyra-api listening on :8080` |
| error ตอน boot | `init db failed: run migrations: ... (SQLSTATE 23514)` | grep `init db failed|migration failed|panic` = **ไม่มี** |
| `tb_notification_type_check` ใน dev DB | **ไม่มี** (0 rows ใน `pg_constraint`) | ✅ มีแล้ว และลิสต์รวม `'spotlight_live'` |
| image | `backend-preview:dev-abed8e4` | `backend-preview:dev-0bff223` |

**วัดยังไง:** `kubectl -n dev get pods` + `kubectl logs` + `SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint WHERE conname='tb_notification_type_check'` (รันผ่าน pod ชั่วคราวใน namespace `dev`)
**แหล่งข้อมูล:** cluster `zyra-k3s` namespace `dev` · GitHub run `34455955183` · zyra-infra commit `5183aeb`
