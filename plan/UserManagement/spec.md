# [Module] User Management — Spec

**ClickUp:** https://app.clickup.com/t/86d34t7a7
**Priority:** High (ยกเว้น SC-UM-06, SC-UM-16 = Normal)
**Assignee:** Ponlawat Lueakaew
**Status:** In Progress
**Version:** 1.0 · **Date:** 2026-07-15
**Refs:** `ux-ui-plan.md` · `task-breakdown.md` · `test-plan.md` · `capacity-scaling.md`

---

## Overview

Module สำหรับ **System Admin** จัดการ User 2 กลุ่มแยกกัน พร้อม Custom Role & Permission system (ตาม ClickUp):

- **Customer (Client side)** — ลูกค้าที่สมัครใช้ Zyra; role ผูกกับ **workspace**; System Admin ดู/จัดการ account ได้
- **Admin (System Admin side)** — internal users จัดการ platform; role ผูกกับ **module permission** บน Admin Dashboard

```
Role & Permission Architecture
  Admin side:     Role (custom name) → Permissions[] → assign to Admin User (global)
  Customer side:  Role (custom name) → Permissions[] → assign to Customer per Workspace
```

**หลักการ:** ทุกหน้าเป็น **Admin back-office** เท่านั้น (`/api/admin/*` + AdminGuard + permission-aware guard ตาม rule 15) — ไม่ใช่ member surface

## Codebase Alignment (v1.0 — สำรวจโค้ดจริงก่อนเขียน spec)

Module นี้ **greenfield แทบทั้งหมด**:

- **`tb_user` ไม่มี account-state column** — ไม่มี `is_suspended`/`is_banned`/`deleted_at`/`status`; ที่มีคือ transient login-lock (`locked_until`) + `is_verifyed` เท่านั้น → suspend/ban/soft-delete สร้างใหม่หมด
- **ไม่มี RBAC tables** — ไม่มี `tb_role`/`tb_permission`/`tb_admin`; authorization = `role_` string เดียวบน `tb_user` (`MEMBER`/`ADMIN`/`SYSADMIN`) → Custom Role+Permission เป็นของใหม่ทั้งหมด
- **ไม่มี `/api/admin/users*` endpoint** — reference CRUD ที่สะอาดสุด = `map_template_service.go` + `MapTemplateHandler`
- **Admin = `tb_user` row ที่ `role_ IN ('ADMIN','SYSADMIN')`**; Customer = `role_='MEMBER'` — table เดียวกัน ไม่แยก
- **Password = MD5 legacy** (`md5String()` / `tb_authen.password_`) — reset/temp ต้องใช้ MD5 เดิมเพื่อ compat login (ดู Open Q6)
- **Email ผ่าน zyra-notifications** (`notify.Client.SendAsync`); `forgot_password_service.go` = reference reset flow (rate limit 3/hr + single-use + `user_activities`)
- **`user_activities` table มีอยู่แล้ว** — reuse เป็น audit log + status history
- **FE:** ไม่มี `app/admin/layout.tsx` — hero render `<AdminSidebar/>` เอง + `useAdminGuard()`; `AdminSidebar` ยังไม่มี "User management" nav. Reuse ได้: `workspace-pagination`, `admin-filter-menu`, `admin-sort-menu`, `authFetch`, pattern `map-management` hero + `lib/api/map-templates.ts`
- **⚠️ DDL sync 2 ที่:** `postgres.go` (embedded) + numbered `migrations/*.sql`; migration ไม่ auto-run (apply เอง)
- **⚠️ Load-bearing:** `is_verifyed` (สะกดผิด) + `role_` (trailing `_`) ใช้ข้าม JWT/DB/FE — ห้ามแก้

---

## Scenario Index

| ID | Scenario | Group | Type | Priority | ClickUp |
|----|----------|-------|------|----------|---------|
| SC-UM-01 | List Customer ทั้งหมด | Customer | Happy | High | https://app.clickup.com/t/86d34t7fd |
| SC-UM-02 | ดูรายละเอียด Customer Profile | Customer | Happy | High | https://app.clickup.com/t/86d34t7jg |
| SC-UM-03 | Suspend / Unsuspend Customer | Customer | Happy | High | https://app.clickup.com/t/86d34t7q9 |
| SC-UM-04 | Ban Customer | Customer | Happy | High | https://app.clickup.com/t/86d34t7yf |
| SC-UM-05 | Delete Customer Account | Customer | Happy | High | https://app.clickup.com/t/86d34t82n |
| SC-UM-06 | Reset Customer Password | Customer | Happy | Normal | https://app.clickup.com/t/86d34t888 |
| SC-UM-07 | จัดการ Customer Role — สร้าง Custom Role | Customer RBAC | Happy | High | https://app.clickup.com/t/86d34t8f0 |
| SC-UM-08 | จัดการ Customer Role — กำหนด Permission | Customer RBAC | Happy | High | https://app.clickup.com/t/86d34t8nj |
| SC-UM-09 | Assign Customer Role ให้ User | Customer RBAC | Happy | High | https://app.clickup.com/t/86d34t8yc |
| SC-UM-10 | List Admin Users ทั้งหมด | Admin | Happy | High | https://app.clickup.com/t/86d34t92d |
| SC-UM-11 | เพิ่ม Admin User ใหม่ | Admin | Happy | High | https://app.clickup.com/t/86d34t95g |
| SC-UM-12 | จัดการ Admin Role — สร้าง Custom Role | Admin RBAC | Happy | High | https://app.clickup.com/t/86d34t9a7 |
| SC-UM-13 | จัดการ Admin Role — กำหนด Permission | Admin RBAC | Happy | High | https://app.clickup.com/t/86d34t9eh |
| SC-UM-14 | Assign Admin Role ให้ User | Admin RBAC | Happy | High | https://app.clickup.com/t/86d34t9je |
| SC-UM-15 | Suspend / Delete Admin User | Admin | Happy | High | https://app.clickup.com/t/86d34t9pb |
| SC-UM-16 | Reset Admin Password | Admin | Happy | Normal | https://app.clickup.com/t/86d34t9t6 |

---

## Data Model (สร้างใหม่ — ดู `task-breakdown.md §Architecture`)

```
tb_user (ALTER): account_status(active|suspended|banned|deleted), suspend_reason, suspend_until,
  ban_reason, ban_note, status_changed_by, status_changed_at, deleted_at, anonymized_at,
  must_change_password, admin_role_id (FK), token_version
tb_admin_role / tb_admin_role_permission        -- global admin roles
tb_workspace_role / tb_workspace_role_perm       -- per-workspace customer roles
tb_workspace_member (ALTER: role_id)             -- customer role assignment
tb_user_status_history                            -- SC-02 timeline
```

- **Permission catalog = static Go** (`internal/rbac/catalog.go`) 2 ชุด: `CustomerPermissions` (workspace/vo/chat) + `AdminPermissions` (admin.user.*/admin.role.*/system/content) พร้อม dependency graph
- **Guard ใหม่:** `RequirePermission(key)` (Super admin bypass; `admin.role.admin.manage` = Super-admin-only) + governance (แก้ตัวเองไม่ได้; แก้ Super admin ต้องเป็น Super admin)
- **Session revocation:** `token_version` claim (bump ตอน ban/delete/password-change) — cache Redis (ดู `capacity-scaling.md §2`)

---

## Scenario Details (Acceptance Criteria + Contract)

> UI spec แบบ pixel-perfect อยู่ใน `ux-ui-plan.md` (อ้าง § ต่อ scenario); ที่นี่เน้น behavior / AC / API / DB

### SC-UM-01 · List Customer — UI §3

- **AC:** ตาราง `role_='MEMBER'` (exclude deleted เว้นแต่ filter) 6 คอลัมน์ (Name/Status/Workspaces/Last active/Registered/Action); search username/email (debounce ~300ms); filter Status + Ath.via; sort Workspaces/Last active/Registered; pagination 20/page (cap 100); row-action menu สลับตาม status; Export CSV; empty state
- **API:** `GET /api/admin/customers?search&status&auth&sort&order&page&limit` → `{items,total,page,limit}`; perm `admin.user.customer.read`
- **DB:** index trgm (email/username) + status/registered/last_active (ดู `capacity-scaling.md §1`)

### SC-UM-02 · Customer Profile — UI §4

- **AC:** left profile card (avatar, name, email, phone, auth, status, registered, last active, **status history timeline**) + right tabs (Workspace/Activity log/Security); Workspace tab = table (Name/Role/Joined/Action) + Role filter + pagination; top actions Suspend/Ban/Delete
- **API:** `GET /customers/{id}`, `/customers/{id}/workspaces`, `/customers/{id}/activity`, `/customers/{id}/status-history`
- **DB:** `user_activities` (activity tab), `tb_user_status_history` (timeline)

### SC-UM-03 · Suspend / Unsuspend — UI §5

- **AC:** Suspend modal — Reason(req ≤500) + Suspended date → set `account_status='suspended'` + history + email; Suspend disabled จนกรอก reason. Unsuspend confirm → restore. ห้าม suspend ตัวเอง; validate transition
- **API:** `POST /customers/{id}/suspend {reason,until}` · `POST /customers/{id}/unsuspend`; perm `admin.user.customer.suspend`
- **Email:** `account_suspended` / `account_unsuspended`

### SC-UM-04 · Ban Customer — UI §6

- **AC:** Ban modal — Reason(req) + Note(opt) → **confirm step type-email gate** (ต้องพิมพ์ email ตรงจึง Ban ได้) → set `banned` + **bump token_version (ตัด session)** + email; banned user login → "Account access restricted" screen. Unban → restore
- **API:** `POST /customers/{id}/ban {reason,note}` · `/unban`; perm `admin.user.customer.ban`
- **Email:** `account_banned` / `account_unbanned`

### SC-UM-05 · Delete Customer — UI §7

- **AC:** Step1 warning (owner-of-N + impact box) → Step2 type-email confirm (invalid → error caption) → **soft delete** (`deleted_at`) + **anonymize PII** (name/email → hash) + **owner transfer** (Phase 1: admin longest-tenure ต่อ workspace) + bump token_version; purge ถาวรหลัง 30 วัน; end-user เห็น "Account deleted"
- **API:** `DELETE /customers/{id}` (body: confirm email); perm `admin.user.customer.delete`
- **DB:** partial index `WHERE deleted_at IS NULL`; purge job (`capacity-scaling.md §5`)

### SC-UM-06 · Reset Customer Password — UI §8

- **AC:** method chooser — **Send link** (reuse forgot-password token, exp 1h) หรือ **Force reset** (gen temp password MD5, `must_change_password='Y'`, bump token_version, แสดง temp + Copy); Google-auth user → ไม่ available; rate-limit
- **API:** `POST /customers/{id}/reset-password {method: link|force}`; perm `admin.user.customer.reset_password`
- **Email:** `password_reset_link` / `password_reset_temp` — ↔ SC-LOGIN-05

### SC-UM-07 · Customer Role — Create — UI §9

- **AC:** 2-card builder ใต้ tab Role & Permission (Customer); Role name(≤50 + counter) + template(opt) + description(opt); Save disabled จนกรอกชื่อ + เลือก permission; system role แก้/ลบไม่ได้
- **API:** `POST /workspace-roles`, `GET /workspace-roles?workspace_id`; validate key ใน `CustomerPermissions`

### SC-UM-08 · Customer Role — Permission — UI §9.2/9.3

- **AC:** permission matrix — left category (Workspace/VO/Chat) + master enable-all + count badge; right Access/Action (Switch per key); **dependency cascade** (on/off confirm); "All accesses" count; delete-role confirm (0 user ลบได้, >1 user ซ่อน Delete); revoke-mid-edit → error
- **API:** `PUT /workspace-roles/{id}/permissions {keys[]}`; `DELETE /workspace-roles/{id}` (409 ถ้า in-use)
- **Catalog (Workspace group, verbatim):** `workspace.read`, `workspace.settings.read`, `workspace.settings.edit`, `workspace.members.read`, `workspace.members.invite`, `workspace.members.remove`, `workspace.members.role_assign` *(VO/Chat = Open Q2)*

### SC-UM-09 · Assign Customer Role — UI §10

- **AC:** change-role modal (profile card + **locked Workspace field** + Role dropdown Default[Owner/Admin/Member/Guest]/Custom) → confirm modal (copy per case); workspace มี Owner แล้ว → ต้องย้าย owner ก่อน (409)
- **API:** `POST /customers/{id}/assign-role {workspace_id, role_id}` → update `tb_workspace_member.role_id`

### SC-UM-10 · List Admin Users — UI §11

- **AC:** ตาราง admin (role_ IN ADMIN/SYSADMIN) — เพิ่ม **Role column** (tag: Super admin/Admin/Support/Guest) เทียบกับ customer list; CTA "Add admin"; filter Status+Role; deleted row anonymized
- **API:** `GET /admins?search&status&role&sort&page&limit`; perm `admin.user.admin.read`

### SC-UM-11 · Add Admin — UI §12

- **AC:** modal 688px — first/last/email/role dropdown(Super admin/Admin/Support/Viewer) + **password option** (manual + strength panel 4 rule / auto-generate) + confirm; Add disabled จน valid; ทั้ง 2 flow บังคับ force-change ครั้งแรก; email unique
- **API:** `POST /admins {first,last,email,role_id,password_option,password?}` → tb_user(ADMIN)+tb_authen(MD5)+admin_role_id, `must_change_password='Y'`; perm `admin.user.admin.create`
- **Email:** `admin_invitation` (2 variant)

### SC-UM-12 · Admin Role — Create — UI §13.1

- **AC:** 2-card builder (Admin catalog) เหมือน SC-07; create mode = Save; **view/edit existing = Delete/Edit button**
- **API:** `POST /admin-roles`, `GET /admin-roles`; validate `AdminPermissions`

### SC-UM-13 · Admin Role — Permission — UI §13.2/13.3

- **AC:** matrix — category User management/Role management/Workspace management/Content Management/System; `admin.role.admin.manage` **ซ่อนถ้าไม่ใช่ Super admin**; dependency cascade; delete-role guard
- **API:** `PUT /admin-roles/{id}/permissions`; `GET /permissions` (catalog)
- **Catalog (User management group, verbatim):** `admin.user.customer.read/suspend/ban/delete/reset_password`, `admin.user.admin.read/create/suspend/delete` *(Role/Workspace/Content/System = Open Q2)*
- **ต่างจาก customer set:** admin มี `admin.user.admin.*` + Role/System/Content management; customer มีแค่ workspace/vo/chat scope

### SC-UM-14 · Assign Admin Role — UI §14

- **AC:** change-role modal (Previous/New role + submenu Default[Super admin/Admin/Support/Guest]/Custom) → Done; **governance:** ดู details ตัวเอง → ไม่มี Action button; เปลี่ยน role Super admin ต้องเป็น Super admin; downgrade → revoke session
- **API:** `POST /admins/{id}/assign-role {role_id}`

### SC-UM-15 · Suspend / Delete Admin — UI §15

- **AC:** Suspend (Reason ≤500 + date) / Reactivate confirm. **Delete** — impact box (Immediate Session Revocation / Anonymized History / 30-Day Retention / "cannot be undone") → soft delete + anonymize audit + **revoke session ทันที** + purge 30d; governance (self/super rule)
- **API:** `POST /admins/{id}/suspend`·`/reactivate` · `DELETE /admins/{id}`; perm `admin.user.admin.suspend`/`.delete`
- **Email:** `admin_suspended` / `admin_reactivated`

### SC-UM-16 · Reset Admin Password — UI §16

- **AC:** method chooser (link/force) เหมือน SC-06; + **self-service Change password page** (current/new/confirm + strength 4 rule; error weak/mismatch/wrong-current); **acting Super admin เปลี่ยน password ตัวเอง → ไม่ถูกดีดออก device ปัจจุบัน แต่ revoke device อื่นทันที**; force-change gate (`must_change_password='Y'` → redirect หลัง login)
- **API:** `POST /admins/{id}/reset-password {method}` · `PUT /api/user/me/password {current,new}`

---

## Open Questions

| # | คำถาม | Blocker | อ้างอิง |
|---|---|---|---|
| Q1 | Customer role scope = per-workspace จริง? (design ล็อค Workspace field) | data model, assign-role | ux-ui §20, task-breakdown §Deps |
| Q2 | Permission catalog ชุดเต็ม — VO/Chat (customer) + Workspace/Content/System (admin) | catalog | design แสดงเฉพาะ group แรก |
| Q3 | ชุด admin default role สุดท้าย — Viewer (SC-11) vs Guest (SC-14) | seed roles, add admin | — |
| Q4 | Status history timeline (SC-02) — `user_activities` เดิม หรือ table ใหม่ (`tb_user_status_history`) | data model | — |
| Q5 | CSV export scope — fields + filter-aware? | UM-017 | capacity §7 |
| Q6 | นโยบาย MD5 — คงไว้ (compat) หรือ migrate bcrypt/argon2 (แตะ login+register+forgot, out of scope) | reset/create/change password | plan สมมติ **คง MD5** |
| Q7 | Session-revocation strategy — instant Redis vs TTL-based (design บอก "revoke immediately") | UM-005 | capacity §2 |
| Q8 | Anonymization algorithm — hash email `d3b07384…@hashed-anonymized.net` (ตาม design) — ยืนยัน | delete flow | capacity §5 |
| Q9 | Email address จริง (from/support) + "[Admin Name]" ใน template | notif templates | — |
