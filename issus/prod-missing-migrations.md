# Prod ขาด migration → `relation "tb_map_zone" does not exist` (42P01)

## อาการ

หน้า `app.zyra-world.com/login` ขึ้น toast:

```
list published workspaces: ERROR: relation "tb_map_zone" does not exist (SQLSTATE 42P01)
```

## สาเหตุ

- Endpoint `GET /api/user/workspace-templates` → `WorkspaceService.ListPublishedWorkspaces()`
  query นับ room จากตาราง `tb_map_zone`
  (`zyra-api/internal/service/workspace_service.go` — subquery `room_count`)
- **zyra-api รัน DDL แค่ที่ hardcode ไว้ใน slice `migrations`** ใน
  `zyra-api/internal/database/postgres.go` ตอน boot เท่านั้น — สร้างแค่ 10 ตาราง baseline
- `tb_map_zone` และอีกหลายตารางถูกสร้างโดย **file migration** (`migrations/*.sql`)
  ซึ่ง **ไม่ถูกรันอัตโนมัติ** และไม่มีตาราง tracking (`schema_migrations`) + ไม่มี runner
- prod ต่อ DB ผ่าน env `DATABASE_URL` (default `DB_NAME=zyra-db`) — DB ตัวนั้นไม่เคยรัน file migration

## ตารางที่ boot ไม่สร้าง (มาจาก file migration เท่านั้น — prod เสี่ยงขาด)

Object: `tb_object`, `tb_object_image`, `tb_object_information`, `object_compositions`
Avatar: `tb_avatar`, `tb_avatar_audit_log`, `tb_user_avatar`
Map: `tb_map_template`, `tb_map_template_category`, `tb_map_version`
Zone: **`tb_map_zone`**, `tb_private_zone_access_log`, `tb_private_zone_claim`
Workspace history: `tb_workspace_version`, `tb_workspace_audit_log`
Chat: `tb_conversation`, `tb_conversation_member`, `tb_message`, `tb_message_attachment`, `tb_message_reaction`, `tb_user_last_read`
อื่น ๆ: `tb_notification`, `user_activities`

## ✅ ผลยืนยัน (2026-07-10)

prod ชี้ไป **database `postgres`** บน server เดียวกับ dev (`35.247.177.198:3500`, user `gather-dev`).
พบโดย list databases บน server แล้วดูตัวที่ขาด `tb_map_zone`:

| database | tables | tb_map_zone | คือ |
|---|---|---|---|
| `zyra-db` | 32 | ✅ | dev |
| `postgres` | 25 | ❌ | **prod** |
| `gather-dev_db` | 0 | — | ว่าง |

prod (`postgres`) **ขาด 29 ตาราง + 3 คอลัมน์**:
- 24 ตารางมาจาก file migration (10,13,14,15,17,18,23,25,27,34,35,36,49,50,52,58, create_user_activities)
- 5 ตารางมีเฉพาะใน embedded DDL (`postgres.go`): `tb_workspace_member/invite/join_request`,
  `tb_zone_section/_member` → prod รัน **image เก่า**; redeploy image ปัจจุบันแล้ว boot จะสร้างให้
- 3 คอลัมน์: `tb_map.status` (43), `tb_workspace.owner_id` (47), `tb_workspace.published_thumbnail_url` (46)

## วิธีเช็ก (script สำเร็จรูป)

```bash
../../service/check-db.sh list     # list ทุก db + tb_map_zone
../../service/check-db.sh prod     # เช็ก prod (postgres)
../../service/check-db.sh dev      # เช็ก dev  (zyra-db)
```

หรือรัน SQL ตรง ๆ:
```bash
PGPASSWORD=... psql "host=35.247.177.198 port=3500 user=gather-dev dbname=postgres sslmode=disable" \
  -f prod_schema_check.sql
```

## วิธีแก้

ไล่รัน file migration ที่ขาดตามลำดับเลข (10 → 58 + ไฟล์ `add_*.sql`) เข้ากับ DB prod ด้วยมือ
อย่างน้อยสำหรับ error นี้คือ `migrations/34_create_tb_map_zone.sql`

## แนวทางกันซ้ำ (backlog)

ควรมี migration runner จริง (เช่น golang-migrate) + ตาราง tracking แทนการรันด้วยมือ
เพื่อไม่ให้ prod/staging schema drift อีก
