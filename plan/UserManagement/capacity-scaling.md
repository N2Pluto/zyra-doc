# Capacity & Scaling Plan — User Management Module

**Version:** 1.0 · **Date:** 2026-07-15
**Scope:** SC-UM-01 ~ SC-UM-16 · **Refs:** `task-breakdown.md` (§Architecture) · `test-plan.md`

> เอกสารนี้ระบุ scaling concerns ของ module — จุดที่จะกลายเป็น bottleneck เมื่อ user/admin/audit โตขึ้น และ mitigation ที่ต้องออกแบบตั้งแต่ต้น (ไม่ใช่แก้ทีหลัง)

---

## 0. สมมติฐานปริมาณ (Load Assumptions)

| Metric | Baseline | Target (12 mo) | หมายเหตุ |
|---|---|---|---|
| Customer accounts (`tb_user role_=MEMBER`) | ~10k | **500k–1M** | list SC-01 ต้อง paginate จริง |
| Admin accounts | ~10 | ~200 | list SC-10 เล็ก |
| Workspaces / customer | 1–5 | เท่าเดิม | owner-transfer, workspace tab |
| `user_activities` (audit) rows | ~100k | **> 50M** | โตเร็วสุด — index + retention |
| `tb_user_status_history` | — | ~5M | status timeline |
| Admin list request rate | ต่ำ | ต่ำ | back-office เท่านั้น |
| Guarded request rate (ทุก `/api/*`) | สูง | สูงมาก | token_version check อยู่ใน hot path |

**เส้นเลือดใหญ่:** (1) customer list query บนตารางล้านแถว, (2) `token_version` check ในทุก request, (3) permission resolution ต่อ admin action, (4) audit log growth. 3 อย่างแรกอยู่ใน hot path — ออกแบบผิดคือ regression ทั้งระบบ

---

## 1. Customer List Query (SC-01/10) — ตารางล้านแถว

**ปัญหา:** `GET /api/admin/customers` search + filter + sort + count บน `tb_user` ที่มี 1M rows. `SELECT count(*)` เต็มตาราง + `OFFSET` ลึก = ช้าเป็นวินาที

**Mitigation:**

- **Index ที่ต้องมี (UM-001/006):**
  ```sql
  CREATE INDEX idx_user_group_status   ON tb_user (role_, account_status) WHERE deleted_at IS NULL;
  CREATE INDEX idx_user_registered     ON tb_user (created_at DESC);
  CREATE INDEX idx_user_last_active    ON tb_user (last_login_at DESC);
  CREATE INDEX idx_user_email_trgm     ON tb_user USING gin (email gin_trgm_ops);      -- search ILIKE
  CREATE INDEX idx_user_username_trgm  ON tb_user USING gin (username gin_trgm_ops);
  ```
  (ต้องเปิด extension `pg_trgm` — เพิ่มใน migration; ถ้าไม่ได้ → prefix search `email LIKE 'q%'` + btree)
- **Sort ต้อง match index** — ทุก sortable column (registered/last_active/workspaces) มี index; ไม่งั้น sort ทั้งตาราง
- **Count แยกจาก page fetch** — query count มี cache สั้น (30–60s) ต่อ filter combo; หรือใช้ approximate count (`reltuples`) เมื่อ filter ว่าง เพราะ "(100)" เป็นตัวเลขคร่าวๆ
- **Deep pagination:** design ใช้ page number (1/2/3 + "20/page") → OFFSET ok ที่หน้าต้นๆ. เตรียม **keyset/cursor pagination** เป็น fallback ถ้าคน jump ไปหน้าลึก (WHERE created_at < cursor)
- **"Workspaces" column count** — อย่า N+1 count ต่อ row; ใช้ `LEFT JOIN LATERAL` หรือ subquery aggregate + index บน `tb_workspace_member(user_id)` / `tb_workspace.owner_id`
- **default limit 20**, cap `limit ≤ 100` (ตาม `LIMIT_OPTIONS` เดิม); reject limit ใหญ่

---

## 2. `token_version` Session Check — Hot Path ⚠️

**ปัญหา:** session-revocation (UM-005) เทียบ `tv` claim กับ DB **ทุก guarded request**. ถ้า query `tb_user` ต่อ request = +1 DB round-trip ต่อทุก API call ทั้งระบบ → DB saturation

**Mitigation (สำคัญที่สุดในเอกสารนี้):**

- **Cache `token_version` ใน Redis** (มี infra แล้ว — memory [[redis-migrated-prod-redis]]): key `uv:{userID}` → int, TTL ~5 min
  - Guard: อ่าน Redis ก่อน; miss → DB → set. เทียบ `tv` claim
  - Bump (ban/delete/password-change): `INCR` DB column **และ** `SET uv:{userID}` (หรือ `DEL` ให้ re-read) — invalidate ทันที
- **หรือทางที่ถูกกว่า** — ไม่เช็คทุก request: access token อายุสั้น (มี `tokenExpire` อยู่แล้ว) + เช็ค `tv` เฉพาะตอน **refresh** เท่านั้น. Revocation propagate ภายใน access-token TTL (เช่น 15 นาที) แทน instant
  - **Trade-off:** design SC-15/16 บอก "instantly disconnected" / "revoke immediately" → ต้อง instant สำหรับ ban/delete/password-change เฉพาะทาง. แนะนำ **hybrid:** cache Redis (instant + ถูก) สำหรับ 3 action นี้; request ปกติอ่าน cache
- **JWT เก่าไม่มี `tv`** — treat เป็น 0 หรือบังคับ re-login ครั้งเดียวตอน deploy (regression check ใน test-plan §5)
- **Decision:** ต้องเลือกกลยุทธ์ก่อน implement UM-005 → Open Q7 ใน `task-breakdown.md`

---

## 3. Permission Resolution (RBAC) — ต่อ admin action

**ปัญหา:** `RequirePermission(key)` (UM-004) โหลด `admin_role_id` → permission set ต่อ request. Admin request rate ต่ำ แต่ยังไม่ควร query 2 ตาราง (`tb_admin_role_permission`) ทุกครั้ง

**Mitigation:**

- **In-process cache** permission set ต่อ `role_id` (map + `sync.RWMutex`, TTL สั้น หรือ invalidate-on-write) — admin roles น้อย (~200) เก็บใน memory ได้สบาย
- **Invalidate on role update** (UM-045 `PUT /permissions`) — bump version หรือ clear entry นั้น; ถ้า multi-instance → ใช้ Redis pub/sub invalidate (pattern เดียวกับ [[vo-realtime-redis-bus]]) หรือ TTL สั้นพอ (30–60s) รับ eventual consistency ได้
- **Catalog เป็น static Go** — ไม่ query; dependency graph resolve in-memory (O(keys))
- Permission set เก็บเป็น `map[string]struct{}` → lookup O(1)

---

## 4. Audit Log Growth (`user_activities` + status history)

**ปัญหา:** โตเร็วสุด (>50M rows). ทุก admin action + login/reset เขียน 1 row. Timeline query (SC-02) + rate-limit count query ช้าลงเรื่อยๆ

**Mitigation:**

- **Index:** `(user_id, created_at DESC)` (timeline), `(activity, created_at)` (rate-limit count) — มีอยู่แล้วบางส่วน; verify + เพิ่ม
- **Timeline paginate** — SC-02 status history โหลด N ล่าสุด + "load more" (keyset by created_at) ไม่ดึงทั้งหมด
- **Retention / partitioning:** partition `user_activities` by month (`created_at`) → drop partition เก่า; หรือ archive > 6–12 mo ไป cold storage. Status-change history เก็บนานกว่า activity ทั่วไป (compliance)
- **เขียน async** — audit write ไม่ block admin action response (fire-and-forget + retry) เหมือน pattern email `SendAsync`
- **ห้าม log PII/password/token** (rule 07) — ลด row size + ความเสี่ยง

---

## 5. Soft-Delete Purge (30-day) — SC-05/15

**ปัญหา:** deleted account เก็บ 30 วัน (design SC-15) แล้วลบถาวร. ถ้าไม่มี job → row สะสม + list query ต้อง `WHERE deleted_at IS NULL` ตลอด

**Mitigation:**

- **Scheduled purge (UM-062):** ลบ `deleted_at < now() - 30d` ถาวร (batch, LIMIT ต่อ run กัน long lock); cron/scheduled — migrations ไม่ auto-run ฉะนั้น job ต้อง explicit
- **Partial index** `WHERE deleted_at IS NULL` ให้ list query ไม่แตะ deleted rows (อยู่ใน §1 index แล้ว)
- **Anonymize ทันทีตอน delete** (ไม่รอ purge) — PII (name/email) hash เป็น `d3b07384…@hashed-anonymized.net` ทันที; purge แค่ hard-delete row ที่เหลือ
- **Cascade:** `tb_authen` FK `ON DELETE CASCADE` แล้ว; ตรวจ workspace_member / role assignment ให้ cleanup ด้วย

---

## 6. Email Fan-out (zyra-notifications)

**ปัญหา:** admin action → email 1 ฉบับ (ต่ำ). แต่ **bulk action** (ถ้าเพิ่มภายหลัง: suspend หลายคน) → email burst

**Mitigation:**

- ปัจจุบัน 1 action = 1 email ผ่าน `SendAsync` (non-blocking) — พอสำหรับ single-target
- **ถ้าเพิ่ม bulk:** queue + rate-limit ที่ zyra-notifications ฝั่งเดียว; อย่า loop `SendAsync` sync ใน handler
- Email failure ต้อง **ไม่ rollback** action (account status เปลี่ยนแล้ว) — log + retry; ticket path pattern เดียวกับ UserGuide

---

## 7. CSV Export (SC-01/10) — ตารางใหญ่

**ปัญหา:** `GET /customers/export` ทั้ง 1M rows ลง CSV ใน request เดียว → memory + timeout

**Mitigation:**

- **Stream response** (`Transfer-Encoding: chunked`) — เขียน row-by-row จาก cursor, ไม่ load ทั้งชุดเข้า memory
- **Filter-aware** (Open Q5) — export ตาม filter ปัจจุบัน ลดขนาด default
- **Cap / async:** ถ้า > N rows (เช่น 100k) → generate async + email link แทน sync download
- อย่า include PII เกินจำเป็น; audit การ export เอง

---

## 8. Rate Limiting & Abuse

- **Reset password** — reuse rate-limit เดิม (`forgot_password_service` 3/hr) ต่อ target user; admin-triggered ก็ควรมี cap กัน loop
- **Login (banned/suspended/deleted)** — reject เร็วที่ guard/login (account_status + token_version) ก่อนถึง business logic
- **List/search** — debounce ฝั่ง FE (~300ms) + cap limit ฝั่ง API; search แพง (trigram) → กัน query ถี่

---

## 9. Concurrency & Consistency

- **Role permission edit พร้อมกัน** (SC-08/13 "revoke mid-edit") — optimistic version บน role (updated_at/version); เขียนทับ → 409 + error state ตาม design
- **Owner transfer (delete)** — ทำใน transaction (`defer tx.Rollback`), lock workspace row กัน race กับ concurrent membership change
- **Status transition** — validate transition ใน service + (ถ้าจำเป็น) `SELECT … FOR UPDATE` กัน double-suspend
- **Token version bump** — atomic `INCR`/`UPDATE … SET tv = tv + 1`

---

## 10. สรุป — สิ่งที่ต้องออกแบบตั้งแต่ Phase 0

| # | ต้องมีก่อน scale | Task | ความเสี่ยงถ้าไม่ทำ |
|---|---|---|---|
| 1 | Index ครบ (trgm + sort + partial deleted) | UM-001/006 | list query timeout ที่ 100k+ |
| 2 | `token_version` **cached** (Redis) — ไม่ query ทุก request | UM-005 | DB saturation ทั้งระบบ |
| 3 | Permission set cache + invalidate | UM-004/045 | admin action ช้า + stale perms |
| 4 | Audit index + async write + retention | UM-061/062 | audit table โต → ทุก query ช้า |
| 5 | Soft-delete purge job + anonymize-on-delete | UM-053/062 | row สะสม + PII ค้าง |
| 6 | CSV stream + cap | UM-017 | memory/timeout |

**Decision ที่ต้อง lock ก่อน implement:** §2 (session-revocation strategy — instant Redis vs TTL-based) และ §3 (permission cache invalidation — pub/sub vs TTL) → tie เข้ากับ Open Q7 ใน `task-breakdown.md`. Redis มีพร้อมใช้แล้ว (prod-redis 10.107.20.91, AUTH) ตาม memory [[redis-migrated-prod-redis]]
