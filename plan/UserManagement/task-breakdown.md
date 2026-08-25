# Task Breakdown — User Management Module

**Version:** 1.0 · **Date:** 2026-07-15
**Scope:** SC-UM-01 ~ SC-UM-16 (zyra-api + zyra-app + zyra-notifications)
**Refs:** `ux-ui-plan.md` · `test-plan.md` · `capacity-scaling.md`
ClickUp: https://app.clickup.com/t/86d34t7a7

---

## Status

- ยังไม่เริ่ม implement — เอกสารชุดนี้เป็น plan รอบแรก (2026-07-15) หลังสำรวจ codebase + ดึง Figma spec 16 nodes ครบ

## Codebase Alignment (สำรวจก่อนวางแผน)

ผลสำรวจโค้ดจริง — **module นี้ greenfield แทบทั้งหมด**:

- **`tb_user` ไม่มี account-state column เลย** — ไม่มี `is_suspended` / `is_banned` / `deleted_at` / `status`. ที่มีคือ transient login-lock (`locked_until`) + `is_verifyed` เท่านั้น → suspend/ban/soft-delete ต้องสร้างใหม่หมด
- **ไม่มี RBAC tables** — ไม่มี `tb_role`/`tb_permission`/`tb_admin`. Authorization = `role_` string เดียวบน `tb_user` (`MEMBER`/`ADMIN`/`SYSADMIN`) เทียบตรงๆ ใน `AdminGuard`. Custom Role+Permission ทั้งหมดเป็นของใหม่
- **ไม่มี `/api/admin/users*` endpoint ใดๆ** — ไม่มี ListUsers service. Reference CRUD ที่สะอาดสุด = `map_template_service.go` + `MapTemplateHandler` (list w/ pagination+search+sort+filter)
- **Admin = `tb_user` row ที่ `role_ IN ('ADMIN','SYSADMIN')`** — ไม่ใช่ table แยก. Customer = `role_='MEMBER'`. ทั้งคู่อยู่ table เดียวกัน
- **Password = MD5 legacy** (`md5String()` / `tb_authen.password_`) — reset/temp-password ต้องใช้ MD5 เดิมเพื่อ compat login (หรือวางแผน migrate — ดู Open Q)
- **Email ออกผ่าน zyra-notifications** (`notify.Client.SendAsync`) — zyra-api ไม่มี SMTP; template ใหม่เพิ่ม 2 ฝั่ง. `forgot_password_service.go` เป็น reference reset flow (rate limit + single-use + `user_activities`)
- **`user_activities` table มีอยู่แล้ว** (id, user_id, activity, ip, meta JSONB, created_at) — reuse เป็น audit log ของ admin action + status history
- **FE: ไม่มี `app/admin/layout.tsx`** — แต่ละ hero render `<AdminSidebar/>` เอง + `useAdminGuard()`. `AdminSidebar` (`components/admin/admin-sidebar.tsx`) `NAV_ITEMS` ยังไม่มี "User management" → เพิ่ม nav + route
- **FE reuse ได้:** `workspace-pagination.tsx` (generic pager), `admin-filter-menu.tsx`, `admin-sort-menu.tsx`, hero pattern ของ `map-management`, `authFetch`/`authFetchForm` (`lib/api/client.ts`), `lib/api/map-templates.ts` เป็น template ของ API module
- **⚠️ ต้องซิงก์ DDL 2 ที่:** `internal/database/postgres.go` (embedded `ADD COLUMN IF NOT EXISTS`) + numbered `migrations/*.sql`. Migration ไม่ auto-run — apply เอง (ดู memory [[migrations-not-auto-run]] / [[feedback-run-migrations-myself]])
- **⚠️ Load-bearing typo:** `is_verifyed` (สะกดผิด) และ `role_` (มี trailing underscore) ใช้ข้าม JWT/DB/FE — ห้ามแก้

---

## Architecture (ที่จะสร้างใหม่)

### Data model

```
tb_user  (ALTER — account state)
  account_status VARCHAR(20) DEFAULT 'active'   -- active|suspended|banned|deleted
  suspend_reason TEXT, suspend_until TIMESTAMPTZ
  ban_reason TEXT, ban_note TEXT
  status_changed_by VARCHAR, status_changed_at TIMESTAMPTZ
  deleted_at TIMESTAMPTZ                          -- soft delete (30-day purge)
  anonymized_at TIMESTAMPTZ                        -- PII hidden ใน audit
  must_change_password VARCHAR(1) DEFAULT 'N'      -- force reset flow
  admin_role_id VARCHAR                            -- FK → tb_admin_role (admin เท่านั้น)
  token_version INT DEFAULT 0                      -- session revocation

tb_admin_role            (id, name, description, is_system BOOL, created_by, created_at, updated_at)
tb_admin_role_permission (role_id, permission_key)          -- granted keys เท่านั้น
tb_workspace_role        (id, workspace_id NULLABLE, name, description, is_system, created_by, …)
tb_workspace_role_perm   (role_id, permission_key)
tb_workspace_member      (ALTER: role_id VARCHAR → tb_workspace_role)   -- customer role assign
tb_user_status_history   (id, user_id, action, reason, actor_id, meta JSONB, created_at)  -- SC-02 timeline
```

- **Permission catalog = static ใน Go** (`internal/rbac/catalog.go`) — ไม่เก็บเป็น table; DB เก็บเฉพาะ key ที่ role นั้น grant. Match กับ UI ที่ catalog fixed + versioned ใน code
- **2 catalog แยก:** `CustomerPermissions` (`workspace.*`, `vo.*`, `chat.*`) + `AdminPermissions` (`admin.user.customer.*`, `admin.user.admin.*`, `admin.role.*`, workspace/content/system)
- **Dependency graph** ใน catalog (permission A ต้องมี B) → cascade toggle (SC-08/13)

### Guard / session

- **`RequirePermission(key)` middleware** ใหม่ — โหลด acting admin's `admin_role_id` → permission set (cached) → 403 ถ้าไม่มี. Super admin bypass. `admin.role.admin.manage` gate Super-admin-only
- **Session revocation** = `token_version` claim ใน JWT เทียบกับ DB; bump เมื่อ delete/ban/password-change → ตัด session device อื่น (ดู `capacity-scaling.md §session` เรื่อง caching เพื่อไม่ให้ DB hit ทุก request)
- **Governance:** แก้ role/permission ตัวเองไม่ได้ (actor_id == target_id → 403); เปลี่ยน role Super admin ต้องเป็น Super admin

### API (ทั้งหมดใต้ `/api/admin`, AdminGuard + RequirePermission)

```
Customer:
  GET    /customers                       list (search, status, auth, sort, page)
  GET    /customers/{id}                  profile detail
  GET    /customers/{id}/workspaces       workspace tab
  GET    /customers/{id}/activity         activity log tab
  GET    /customers/{id}/status-history   timeline
  POST   /customers/{id}/suspend          {reason, until}
  POST   /customers/{id}/unsuspend
  POST   /customers/{id}/ban              {reason, note} + confirm gate FE
  POST   /customers/{id}/unban
  DELETE /customers/{id}                  type-confirm; owner transfer
  POST   /customers/{id}/reset-password   {method: link|force}
  GET    /customers/export                CSV
  POST   /customers/{id}/assign-role      {workspace_id, role_id}   (SC-09)

Customer roles (per workspace):
  GET/POST/PUT/DELETE /workspace-roles[...]
  PUT    /workspace-roles/{id}/permissions

Admin:
  GET    /admins                          list (+ role column)
  POST   /admins                          create (SC-11: name/email/role/password-option)
  GET    /admins/{id}
  POST   /admins/{id}/suspend | /reactivate
  DELETE /admins/{id}                     soft-delete + anonymize + revoke sessions
  POST   /admins/{id}/reset-password
  POST   /admins/{id}/assign-role         {role_id}   (SC-14)

Admin roles (global):
  GET/POST/PUT/DELETE /admin-roles[...]
  PUT    /admin-roles/{id}/permissions
  GET    /permissions                     catalog (customer + admin)

Self-service:
  PUT    /api/user/me/password            change password (SC-16 self page)
```

### FE structure

```
app/admin/customers/page.tsx           → HeroCustomerManagement (SC-01 + Role&Permission tab)
app/admin/customers/[id]/page.tsx      → HeroCustomerProfile (SC-02)
app/admin/admins/page.tsx              → HeroAdminManagement (SC-10 + Role&Permission tab)
views/admin/user-management/
  customer/  hero-customer-management.tsx · customer-table.tsx · customer-profile/*
             modals: suspend / unsuspend / ban / delete / reset-password
  admin/     hero-admin-management.tsx · add-admin-modal.tsx · (suspend/delete/reset modals)
  role-permission/  role-builder.tsx (shared 2-card) · permission-matrix.tsx (shared)
             change-role-modal.tsx (SC-09/14) · delete-role-modal.tsx
  components/ status-tag.tsx · role-tag.tsx · password-strength.tsx
lib/api/admin-customers.ts · admin-admins.ts · admin-roles.ts · permissions.ts
```

---

## Estimation Key

| Label | Effort |
|---|---|
| XS | < 2 h |
| S | 2–4 h |
| M | 4–8 h (1 วัน) |
| L | 8–16 h (2 วัน) |
| XL | > 16 h (แตกย่อยได้) |

## Summary

| Phase | Tasks | Layer | Scenarios |
|---|---|---|---|
| 0 — Foundations (schema + RBAC core + FE shell) | UM-001 ~ UM-010 | API + FE | ทุก SC |
| 1 — Customer list + profile | UM-011 ~ UM-018 | API + FE | SC-01, 02 |
| 2 — Customer lifecycle (suspend/ban/delete/reset) | UM-019 ~ UM-030 | API + Notif + FE | SC-03, 04, 05, 06 |
| 3 — Customer RBAC | UM-031 ~ UM-037 | API + FE | SC-07, 08, 09 |
| 4 — Admin list + create | UM-038 ~ UM-044 | API + Notif + FE | SC-10, 11 |
| 5 — Admin RBAC | UM-045 ~ UM-051 | API + FE | SC-12, 13, 14 |
| 6 — Admin lifecycle + self password | UM-052 ~ UM-060 | API + Notif + FE | SC-15, 16 |
| 7 — E2E, audit, CSV, polish | UM-061 ~ UM-066 | ทั้งหมด | all |

**Total: 66 tasks** · ลำดับ: Phase 0 → 1 → 2 (ขนานกับ 3) → 4 → 5 (ขนานกับ 6) → 7. Phase 0 block ทุกอย่าง

---

## Phase 0 — Foundations

### UM-001 · Migration — account-state columns บน `tb_user`
**Layer:** zyra-api (PostgreSQL) · **Effort:** S · **Depends:** —
- [ ] เพิ่ม column ตาม Architecture (account_status, suspend_*, ban_*, deleted_at, anonymized_at, must_change_password, admin_role_id, token_version) — ทั้ง numbered `migrations/*.sql` (เลขถัดไป — verify ก่อน) **และ** embedded DDL ใน `postgres.go` (`ADD COLUMN IF NOT EXISTS`)
- [ ] Backfill user เดิม `account_status='active'`, `token_version=0`
- [ ] rollback script คู่กัน (rule 06)

### UM-002 · Migration — RBAC tables
**Layer:** zyra-api · **Effort:** M · **Depends:** —
- [ ] `tb_admin_role`, `tb_admin_role_permission`, `tb_workspace_role`, `tb_workspace_role_perm`, `tb_user_status_history` + index (per-user timeline, role lookup)
- [ ] ALTER `tb_workspace_member` เพิ่ม `role_id`
- [ ] Seed default roles: admin (Super admin/Admin/Support/Guest — `is_system=true`) + customer (Owner/Admin/Member/Guest) พร้อม permission เริ่มต้น

### UM-003 · Permission catalog (Go)
**Layer:** zyra-api · **Effort:** M · **Depends:** —
- [ ] `internal/rbac/catalog.go`: `CustomerPermissions` + `AdminPermissions` (key, category, description, dependsOn[]) ตาม `ux-ui-plan.md §9.2/§13.2`
- [ ] `GET /api/admin/permissions` handler คืน catalog (grouped by category)
- [ ] Unit test: ทุก key unique, dependency ไม่มี cycle, category ครบ

### UM-004 · Permission-aware guard
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-002, UM-003
- [ ] `middleware.RequirePermission(key)` — โหลด role→perm set (cache in-process TTL สั้น + invalidate on role update), Super admin bypass, 403 envelope
- [ ] `admin.role.admin.manage` gate Super-admin-only
- [ ] Governance helper: `assertNotSelf(actor, target)`, `assertCanEditAdmin(actor, target)` (Super admin แก้ Super admin)
- [ ] Unit test ทุก branch

### UM-005 · Session revocation (`token_version`)
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-001
- [ ] ใส่ `tv` claim ใน `signAccessToken`; `AdminGuard`/`UserGuard` เทียบ `tv` กับ DB (cached — ดู `capacity-scaling.md`)
- [ ] `BumpTokenVersion(userID)` เรียกตอน delete/ban/password-change
- [ ] Unit test: token เก่า (tv ต่ำกว่า) → 401

### UM-006 · Base admin-user service + list query
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-001
- [ ] `user_admin_service.go`: `ListUsers(ctx, filter)` (group=customer|admin, search username/email, status, auth, sort, page/limit) — parameterized SQL, exclude `deleted_at` unless filter
- [ ] Sentinel errors (`ErrUserNotFound`, `ErrInvalidStatusTransition`, `ErrCannotActOnSelf`)
- [ ] Table-driven unit test (mock DB)

### UM-007 · FE — AdminSidebar "User management" section + routes
**Layer:** zyra-app · **Effort:** S · **Depends:** —
- [ ] เพิ่ม `NAV_ITEMS` Customer (`/admin/customers`) + Admin (`/admin/admins`) — icon ที่ไม่ชนกับ Avatar mgmt
- [ ] สร้าง route page.tsx (thin → hero) + `useAdminGuard()`

### UM-008 · FE — API client modules
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-006
- [ ] `lib/api/admin-customers.ts`, `admin-admins.ts`, `admin-roles.ts`, `permissions.ts` (copy pattern `map-templates.ts`: BASE, types, List params/data, fn ต่อ endpoint ผ่าน `authFetch`)
- [ ] Type: `AccountStatus`, `AdminRole`, `WorkspaceRole`, `Permission`, `PermissionCategory`

### UM-009 · FE — shared atoms (StatusTag, RoleTag, PasswordStrength)
**Layer:** zyra-app · **Effort:** M · **Depends:** —
- [ ] `status-tag.tsx` (Active/Ban/Suspend/Deleted color variant ตาม token) — extend pattern `ObjectStatusBadge` (rule 09)
- [ ] `role-tag.tsx` (Super admin pink / Admin blue / Support navy / Guest grey; + customer role neutral)
- [ ] `password-strength.tsx` (4 rule live check: ≥12, upper+lower, special, number)
- [ ] Vitest แต่ละตัว

### UM-010 · FE — shared modal shell + confirm modal
**Layer:** zyra-app · **Effort:** S · **Depends:** —
- [ ] `um-modal.tsx` (overlay + panel, 2 tier: form 455/688 h-42 button, confirm 458 h-32 rounded-6 backdrop-blur) — reuse ถ้ามี pattern เดิม
- [ ] `type-to-confirm-input.tsx` (SC-04/05 email gate + error state)

---

## Phase 1 — Customer List + Profile (SC-01, 02)

### UM-011 · API — customer list endpoint
**Layer:** zyra-api · **Effort:** S · **Depends:** UM-006, UM-004
- [ ] `GET /api/admin/customers` (RequirePermission `admin.user.customer.read`) — envelope `{items,total,page,limit}`

### UM-012 · API — customer detail + tabs
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-006
- [ ] `GET /customers/{id}` (profile + status fields + status history), `/workspaces`, `/activity` (จาก `user_activities`), `/status-history`
- [ ] Unit test

### UM-013 · FE — customer management hero + tabs
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-007, UM-008
- [ ] `hero-customer-management.tsx`: shell + tab bar (Customer management | Role & Permission) + card layout (`ux-ui-plan.md §3`)

### UM-014 · FE — customer table + search/filter/sort
**Layer:** zyra-app · **Effort:** L · **Depends:** UM-011, UM-013
- [ ] `customer-table.tsx` (6 column, status pill, avatar variant, date format `dd/mm/yyyy (hh:mm)`)
- [ ] debounced search (~300ms), Status/Auth dropdown filter, sortable columns, `workspace-pagination` reuse, empty state

### UM-015 · FE — row-action menu
**Layer:** zyra-app · **Effort:** S · **Depends:** UM-014
- [ ] `MoreVertical` → menu (contents สลับตาม status): Suspend/Unsuspend/Ban/Unban — divider — Reset password / Delete(แดง). Trigger modal ตาม action

### UM-016 · FE — customer profile page
**Layer:** zyra-app · **Effort:** L · **Depends:** UM-012, UM-008
- [ ] `customer-profile/`: left profile card (fields + status history timeline navy) + right content card (tabs Workspace/Activity/Security) + top action strip (Suspend/Ban/Delete)
- [ ] Workspace tab table (Name/Role/Joined/Action) + Role filter + pagination

### UM-017 · FE — CSV export (customer)
**Layer:** zyra-app + zyra-api · **Effort:** S · **Depends:** UM-011
- [ ] `GET /customers/export` (filter-aware — confirm Open Q5) → download; ปุ่ม `bg-[#005F2B]`

### UM-018 · Unit tests — customer list/profile FE
**Layer:** zyra-app (Vitest) · **Effort:** M · **Depends:** UM-016
- [ ] table filter/sort/pagination logic, status→pill mapping, date format, menu contents per status (mock lib)

---

## Phase 2 — Customer Lifecycle (SC-03, 04, 05, 06)

### UM-019 · API — suspend / unsuspend customer
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-006, UM-005
- [ ] `POST /customers/{id}/suspend` {reason(req, ≤500), until} → set status + history + `SendAsync` suspend email; `/unsuspend` restore
- [ ] validate transition (active→suspended, suspended→active), `assertNotSelf`
- [ ] Unit test ทุก transition + invalid

### UM-020 · API — ban / unban customer
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-019
- [ ] `POST /customers/{id}/ban` {reason(req), note}, `/unban` — bump token_version (ตัด session), history, email

### UM-021 · API — delete customer (owner transfer)
**Layer:** zyra-api · **Effort:** L · **Depends:** UM-020
- [ ] `DELETE /customers/{id}` — soft delete (`deleted_at`) + anonymize PII + **owner transfer** (Phase 1: admin longest-tenure ต่อ workspace) + bump token_version + history
- [ ] transaction + `defer tx.Rollback` (rule 03); Unit test owner-transfer logic

### UM-022 · API — reset customer password
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-005
- [ ] `POST /customers/{id}/reset-password` {method}: `link` → reuse forgot-password token flow (email link, exp 1h); `force` → gen temp password (MD5 → `tb_authen`), set `must_change_password='Y'`, bump token_version, email temp
- [ ] Google-auth user → 400 "reset not available"; Unit test ทั้ง 2 method

### UM-023 · Notif — email templates (customer lifecycle)
**Layer:** zyra-notifications · **Effort:** M · **Depends:** —
- [ ] Template: `account_suspended`, `account_unsuspended`, `account_banned`, `account_unbanned`, `account_deleted`, `password_reset_link`, `password_reset_temp` — copy verbatim จาก `ux-ui-plan.md §5.3/§6.3/§7/§8`
- [ ] constants ใน zyra-api notify + Reply-To/Admin name param

### UM-024 · FE — suspend + unsuspend modal
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-019, UM-010
- [ ] Suspend modal (Reason `0/500` + Suspended date picker + Clear all + disabled→enabled) · Unsuspend confirm

### UM-025 · FE — ban modal + type-confirm
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-020, UM-010
- [ ] Ban modal (Reason + Note + counter) → confirm step type-email gate (reuse UM-010 input + error)

### UM-026 · FE — delete modal (warning + type-confirm)
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-021, UM-010
- [ ] Step 1 warning (owner-count + impact box) → Step 2 type-email confirm + error "Invalid email. Please re-enter email."

### UM-027 · FE — reset password modal
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-022, UM-010
- [ ] Method chooser (2 radio) → send-link confirm / force-reset temp-password (Copy icon) + Back nav

### UM-028 · End-user blocked screens
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-020, UM-021
- [ ] Ban → "Account access restricted" screen; Delete → "Account deleted" (§7.3); Suspend → §15.4 pattern — gate ตอน login/guard เมื่อ `account_status != active`
- [ ] hook เข้า login flow: 403 + reason → render screen (ไม่ redirect loop)

### UM-029 · Unit tests — lifecycle FE
**Layer:** zyra-app (Vitest) · **Effort:** M · **Depends:** UM-024~027
- [ ] modal validation (reason required, counter, type-confirm gate/error, radio→enable), payload ถูก (mock lib)

### UM-030 · API tests — lifecycle endpoints
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-019~022
- [ ] 200/400 transition, 403 self, type-confirm, reset method, rate-limit reset

---

## Phase 3 — Customer RBAC (SC-07, 08, 09)

### UM-031 · API — workspace-role CRUD + permissions
**Layer:** zyra-api · **Effort:** L · **Depends:** UM-002, UM-003
- [ ] `GET/POST/PUT/DELETE /workspace-roles` + `PUT /{id}/permissions` — validate against `CustomerPermissions` catalog + dependency; block edit/delete `is_system`; delete guard (role มี >1 user → 409)
- [ ] Unit test dependency cascade + system-role protection

### UM-032 · FE — shared role builder (2-card)
**Layer:** zyra-app · **Effort:** L · **Depends:** UM-008
- [ ] `role-builder.tsx`: Card1 (Role name `0/50` + template + description) + Card2 wrapper; prop `catalog: "customer"|"admin"` + `mode: create|edit|view`

### UM-033 · FE — permission matrix (shared)
**Layer:** zyra-app · **Effort:** L · **Depends:** UM-003, UM-032
- [ ] `permission-matrix.tsx`: left category panel (master switch + count badge) + right Access/Action table (Switch per row); dependency cascade + "All accesses" count + enable-all logic

### UM-034 · FE — customer role page (SC-07/08)
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-031, UM-032, UM-033
- [ ] Role & Permission tab ใน customer hero → role list + builder (customer catalog: Workspace/VO/Chat); Edit/Delete menu + delete-role confirm

### UM-035 · API — assign customer role
**Layer:** zyra-api · **Effort:** S · **Depends:** UM-031
- [ ] `POST /customers/{id}/assign-role` {workspace_id, role_id} → update `tb_workspace_member.role_id`; rule owner-exists (ต้องย้าย owner ก่อน) → 409; history

### UM-036 · FE — change role modal (customer SC-09)
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-035, UM-010
- [ ] Change role modal (profile card + locked Workspace + Role dropdown submenu Default/Custom) → confirm modal (copy per case)

### UM-037 · Unit tests — customer RBAC
**Layer:** zyra-app + zyra-api · **Effort:** M · **Depends:** UM-031~036
- [ ] matrix dependency logic, enable-all, count; assign-role payload; system-role guard

---

## Phase 4 — Admin List + Create (SC-10, 11)

### UM-038 · API — admin list endpoint
**Layer:** zyra-api · **Effort:** S · **Depends:** UM-006, UM-004
- [ ] `GET /admins` (RequirePermission `admin.user.admin.read`) — join `admin_role_id`→role name/tag; filter status/role; deleted-anonymized row

### UM-039 · API — create admin
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-006, UM-004
- [ ] `POST /admins` {first, last, email, role_id, password_option, password?} — สร้าง `tb_user` (role_='ADMIN') + `tb_authen` (MD5) + `admin_role_id`; auto-generate ถ้าเลือก; set `must_change_password='Y'`; RequirePermission `admin.user.admin.create`
- [ ] validate email unique, password policy (≥12/upper+lower/special/number), role exists
- [ ] Unit test manual + auto password

### UM-040 · Notif — admin invitation email
**Layer:** zyra-notifications · **Effort:** S · **Depends:** —
- [ ] Template `admin_invitation` (2 variant: manual vs auto temp password) — "You've been added as an Admin"

### UM-041 · FE — admin management hero
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-007, UM-038
- [ ] `hero-admin-management.tsx`: shell + tab (Admin management | Role & Permission) + table (มี Role column + role tag) + "Add admin" CTA + Status/Role filter

### UM-042 · FE — add admin modal
**Layer:** zyra-app · **Effort:** L · **Depends:** UM-039, UM-009
- [ ] 688px modal: name/email/role dropdown + password option (radio) + password + strength panel + confirm password; disabled→enabled validation

### UM-043 · FE — admin row-action menu
**Layer:** zyra-app · **Effort:** S · **Depends:** UM-041
- [ ] menu: Assign role / Suspend / Reactivate / Reset password / Delete — governance: ตัวเอง → ไม่มี Action

### UM-044 · Tests — admin list/create
**Layer:** both · **Effort:** M · **Depends:** UM-038~042
- [ ] password policy validation, auto-gen, role join, create payload

---

## Phase 5 — Admin RBAC (SC-12, 13, 14)

### UM-045 · API — admin-role CRUD + permissions
**Layer:** zyra-api · **Effort:** L · **Depends:** UM-002, UM-003, UM-004
- [ ] `GET/POST/PUT/DELETE /admin-roles` + `PUT /{id}/permissions` — validate against `AdminPermissions`; `admin.role.admin.manage` hidden/blocked ถ้าไม่ใช่ Super admin; system-role + >1-user delete guard
- [ ] Unit test

### UM-046 · FE — admin role page (SC-12/13)
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-045, UM-032, UM-033
- [ ] Role & Permission tab (admin catalog: User/Role/Workspace/Content/System) — create (Save) + view/edit (Delete/Edit button) mode

### UM-047 · API — assign admin role + governance
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-045, UM-004
- [ ] `POST /admins/{id}/assign-role` {role_id} → set `admin_role_id`; `assertNotSelf`; เปลี่ยน Super admin ต้อง Super admin; history + (bump token_version ถ้า downgrade)
- [ ] Unit test governance branch

### UM-048 · FE — change admin role modal (SC-14)
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-047, UM-010
- [ ] Change role modal (Previous/New role + submenu Default/Custom) + Done; hide when self

### UM-049 · FE — permission dependency confirm UX
**Layer:** zyra-app · **Effort:** S · **Depends:** UM-033
- [ ] toggle-off ที่มี dependent → confirm modal (on/off case); mid-edit revoke → error state

### UM-050 · FE — role list + delete guard
**Layer:** zyra-app · **Effort:** S · **Depends:** UM-045, UM-046
- [ ] role list rows + Edit/Delete menu; delete-role confirm (`458×188`); hide delete เมื่อ role >1 user; system role non-editable

### UM-051 · Tests — admin RBAC
**Layer:** both · **Effort:** M · **Depends:** UM-045~050
- [ ] catalog scope, super-admin-only key, governance, dependency

---

## Phase 6 — Admin Lifecycle + Self Password (SC-15, 16)

### UM-052 · API — suspend / reactivate admin
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-006, UM-005
- [ ] `POST /admins/{id}/suspend` {reason, until} + `/reactivate` — `assertCanEditAdmin`, bump token_version, history, email

### UM-053 · API — delete admin (anonymize + revoke + 30d)
**Layer:** zyra-api · **Effort:** L · **Depends:** UM-005
- [ ] `DELETE /admins/{id}` — soft delete + anonymize name/email ใน audit + revoke session (bump token_version) + `deleted_at` (purge job 30d) + `assertNotSelf`/governance
- [ ] Unit test anonymization + session revoke

### UM-054 · API — reset admin password
**Layer:** zyra-api · **Effort:** S · **Depends:** UM-022
- [ ] `POST /admins/{id}/reset-password` {method} — เหมือน UM-022; force → temp + must_change + revoke

### UM-055 · API — self change password
**Layer:** zyra-api · **Effort:** M · **Depends:** UM-005
- [ ] `PUT /api/user/me/password` {current, new} — verify current (MD5), policy check, update `tb_authen`, clear `must_change_password`, **revoke session device อื่น (bump token_version) แต่ไม่ตัด current device** (ออก token ใหม่ให้ device ปัจจุบัน)
- [ ] Unit test wrong-current, weak, mismatch, session behavior

### UM-056 · Notif — admin lifecycle emails
**Layer:** zyra-notifications · **Effort:** S · **Depends:** —
- [ ] `admin_suspended`, `admin_reactivated`, admin `password_reset_*` (reuse customer template ถ้า copy ตรง)

### UM-057 · FE — admin suspend/reactivate/delete modals
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-052, UM-053, UM-010
- [ ] Suspend modal (§15.1) · Reactivate confirm · Delete modal (impact box 3 bullet + "cannot be undone")

### UM-058 · FE — admin reset password modal
**Layer:** zyra-app · **Effort:** S · **Depends:** UM-054, UM-027
- [ ] reuse reset-password modal (method + temp + Copy)

### UM-059 · FE — self-service Change password page
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-055, UM-009
- [ ] Account setting page (`/admin/account` หรือตาม route): left panel (Profile/Change password/Billing) + form (current/new/confirm + strength) + errors (weak/unmatch/wrong current)
- [ ] force-change gate: ถ้า `must_change_password='Y'` → redirect มาหน้านี้หลัง login

### UM-060 · Tests — admin lifecycle FE
**Layer:** zyra-app · **Effort:** M · **Depends:** UM-057~059
- [ ] modal validation, change-password form (policy/mismatch/wrong current), force-change gate

---

## Phase 7 — E2E, Audit, Polish

### UM-061 · Audit logging — admin actions
**Layer:** zyra-api · **Effort:** M · **Depends:** Phase 2–6
- [ ] ทุก admin mutation เขียน `user_activities`/`tb_user_status_history` (actor, action, target, reason, ip) — ห้าม log password/token (rule 07)

### UM-062 · Purge job — 30-day soft delete
**Layer:** zyra-api · **Effort:** S · **Depends:** UM-053
- [ ] scheduled job ลบ record `deleted_at < now-30d` ถาวร (หรือ document manual/cron)

### UM-063 · E2E — customer journeys (Playwright)
**Effort:** L · **Depends:** Phase 1–3
- [ ] list/search/filter → profile → suspend→unsuspend / ban(type-confirm) / delete(owner transfer) / reset (link+force); role create+assign

### UM-064 · E2E — admin journeys
**Effort:** L · **Depends:** Phase 4–6
- [ ] add admin (manual+auto) → assign role → suspend→reactivate → reset → delete(anonymize); self change-password + force-change gate; governance (self no-action, super-admin rule)

### UM-065 · Visual/UX polish
**Effort:** M · **Depends:** ทุก FE
- [ ] เทียบ Figma 95–100% ทุกหน้า (spacing/สี/typography), dark viewport, `npx tsc --noEmit` + `npm run lint` + `go test ./...` ผ่าน

### UM-066 · Docs + ClickUp
**Effort:** XS
- [ ] อัปเดต `zyra-doc/plan/UserManagement/`; comment สรุปใน ClickUp (ห้ามแตะ status — rule 13)

---

## Dependencies นอกทีม dev

| # | รายการ | Blocker ของ | Open Q |
|---|---|---|---|
| 1 | ยืนยัน customer role scope = per-workspace | UM-002, UM-031, UM-035 | Q1 |
| 2 | Permission catalog ชุดเต็ม (VO/Chat customer; Workspace/Content/System admin) | UM-003 | Q2 |
| 3 | ชุด default admin roles สุดท้าย (Viewer vs Guest) | UM-002, UM-039 | Q3 |
| 4 | นโยบาย MD5 → คงไว้ หรือ migrate bcrypt | UM-022, UM-039, UM-055 | Q6 |
| 5 | Owner-transfer rule Phase 2 (manual/auto select) | UM-021 | — |
| 6 | CSV export fields + filter-aware | UM-017 | Q5 |
| 7 | Session-revocation caching strategy (Redis?) | UM-005 | ดู capacity-scaling |
| 8 | Email address จริง (support/from) + Admin name ใน template | UM-023, UM-056 | — |

## Open Questions

- **Q1–Q5:** ดู `ux-ui-plan.md §20`
- **Q6 (MD5):** admin/temp password ควร migrate เป็น bcrypt/argon2 ไหม? ถ้า migrate ต้องแตะ login+register+forgot (out of scope นี้ — แนะนำ track แยก) ตอนนี้ plan สมมติ **คง MD5** เพื่อ compat
- **Q7:** `token_version` เช็คทุก request → DB hit; ใช้ Redis cache ไหม (ดู `capacity-scaling.md §2`)
- **Q8:** Deleted admin/customer — anonymize อย่างไร (hash email `d3b07384…@hashed-anonymized.net` ตาม design) — ยืนยัน algorithm
