# Test Plan — User Management Module

**Version:** 1.0 · **Date:** 2026-07-15
**Scope:** SC-UM-01 ~ SC-UM-16 (zyra-api + zyra-app + zyra-notifications)
**Refs:** `ux-ui-plan.md` · `task-breakdown.md` · `capacity-scaling.md`

---

## Coverage Targets

| Layer | Package / Module | Target |
|---|---|---|
| Unit (Go) | `internal/service/user_admin_service.go`, `admin_role_service.go`, `workspace_role_service.go`, `internal/rbac/*`, `middleware.RequirePermission` | ≥ 80% |
| Unit (TS) | `lib/api/admin-customers.ts`, `admin-admins.ts`, `admin-roles.ts`, `permissions.ts`; `password-strength`, permission-matrix logic | ≥ 80% |
| Component | table, modals (suspend/ban/delete/reset), role builder, permission matrix, add-admin | critical paths |
| API | ทุก route ใหม่ | 100% endpoint coverage |
| E2E (Playwright) | customer + admin journeys + governance | happy + alternate + error |

กติกา (rules 04/05): Go = table-driven + `testify`, mock DB ผ่าน interface — **ห้ามต่อ PostgreSQL จริง**; TS = Vitest + `vi.mock` — **ห้ามยิง `/api/*` จริง**; test ทุก sentinel error; ห้าม log PII/password/token ใน test output

---

## 1. Unit Tests — Go (zyra-api)

### 1.1 `internal/rbac/catalog.go`

| Test | Expected |
|---|---|
| `TestCatalog_CustomerKeysUnique` | ไม่มี key ซ้ำใน CustomerPermissions |
| `TestCatalog_AdminKeysUnique` | ไม่มี key ซ้ำใน AdminPermissions |
| `TestCatalog_NoDependencyCycle` | dependsOn ไม่มี cycle (topological ผ่าน) |
| `TestCatalog_EveryKeyHasCategory` | ทุก key อยู่ใน category ที่ประกาศ |
| `TestCatalog_DependencyKeysExist` | dependsOn ชี้ไป key ที่มีจริง |

### 1.2 `middleware.RequirePermission`

| Test | Input | Expected |
|---|---|---|
| `TestRequirePermission_Granted` | admin role มี key | next() |
| `TestRequirePermission_Denied` | role ไม่มี key | 403 envelope |
| `TestRequirePermission_SuperAdminBypass` | Super admin, key ใดก็ได้ | next() |
| `TestRequirePermission_ManageKeyHiddenNonSuper` | key `admin.role.admin.manage`, ไม่ใช่ Super | 403 |
| `TestRequirePermission_NoRole` | admin ไม่มี role_id | 403 |
| `TestGuard_TokenVersionStale` | JWT tv < DB tv | 401 (session revoked) |
| `TestGuard_TokenVersionMatch` | tv ตรง | ผ่าน |
| `TestGovernance_ActOnSelf` | actor_id == target_id | `ErrCannotActOnSelf` |
| `TestGovernance_EditSuperAdmin_NonSuper` | non-super แก้ super | 403 |

### 1.3 `user_admin_service.go` — list + lifecycle (table-driven)

| Test | Expected |
|---|---|
| `TestListUsers_CustomerGroup` | เฉพาะ `role_='MEMBER'`, exclude deleted |
| `TestListUsers_AdminGroup` | เฉพาะ ADMIN/SYSADMIN + join role |
| `TestListUsers_SearchUsernameEmail` | filter ตรง, case-insensitive |
| `TestListUsers_FilterStatus` | active/suspended/banned/deleted |
| `TestListUsers_FilterAuth` | Email / Google |
| `TestListUsers_SortColumns` | workspaces/last_active/registered — asc/desc |
| `TestListUsers_Pagination` | page/limit, total ถูก |
| `TestSuspend_Active→Suspended` | set status+reason+until, history row, email param, no error |
| `TestSuspend_InvalidTransition` | suspended→suspend ซ้ำ / deleted→suspend | `ErrInvalidStatusTransition` |
| `TestSuspend_ReasonRequired` | reason ว่าง | validation error |
| `TestSuspend_ReasonBoundary` | 500 พอดี ok / 501 error | boundary |
| `TestUnsuspend_Restore` | suspended→active |
| `TestBan_BumpsTokenVersion` | token_version +1 (ตัด session) |
| `TestUnban_Restore` | banned→active |
| `TestDelete_OwnerTransfer` | user เป็น owner N workspace → transfer ไป admin longest-tenure ต่อ ws |
| `TestDelete_SoftAndAnonymize` | set deleted_at + anonymized_at + hash email, bump token_version |
| `TestDelete_ActOnSelf` | `ErrCannotActOnSelf` |
| `TestResetPassword_Link` | ออก reset token (exp 1h), email link param, ไม่แตะ password |
| `TestResetPassword_Force` | gen temp (MD5 → tb_authen), must_change='Y', bump tv, email temp |
| `TestResetPassword_GoogleAuth` | authentype=Google | 400 not available |

**Boundary:** reason 0/1/500/501 · note 0/500 · page/limit · password policy (11/12 char)

### 1.4 `workspace_role_service.go` + `admin_role_service.go`

| Test | Expected |
|---|---|
| `TestCreateRole_Valid` | INSERT role + granted keys |
| `TestCreateRole_InvalidPermissionKey` | key นอก catalog | error |
| `TestSetPermissions_DependencyCascade` | เปิด key ที่ depend → เปิด dependency ด้วย |
| `TestSetPermissions_DisableCascade` | ปิด key ที่มี dependent → ปิด dependent (confirm case) |
| `TestEditSystemRole_Blocked` | is_system=true | `ErrSystemRoleImmutable` |
| `TestDeleteRole_NoUsers` | 0 user | ลบได้ |
| `TestDeleteRole_HasUsers` | >1 user | `ErrRoleInUse` (409) |
| `TestAdminRole_ManageKeyGate` | non-super สร้าง role ที่มี `admin.role.admin.manage` | blocked |
| `TestCreateAdmin_ManualPassword` | policy ผ่าน → tb_user(ADMIN)+tb_authen(MD5)+role_id, must_change='Y' |
| `TestCreateAdmin_AutoPassword` | gen password ตาม policy |
| `TestCreateAdmin_WeakPassword` | <12 / ไม่มี upper / special / number | validation error แต่ละข้อ |
| `TestCreateAdmin_DuplicateEmail` | email ซ้ำ | `ErrDuplicate` |
| `TestAssignRole_Customer_OwnerExists` | workspace มี owner แล้ว | 409 ต้องย้ายก่อน |
| `TestAssignRole_Admin_SuperByNonSuper` | non-super เปลี่ยน super | 403 |

### 1.5 self change password (`profile_service` หรือ service ใหม่)

| Test | Expected |
|---|---|
| `TestChangePassword_WrongCurrent` | current ผิด (MD5) | error |
| `TestChangePassword_WeakNew` | policy fail | error |
| `TestChangePassword_Success` | update tb_authen, clear must_change, bump tv (revoke อื่น), **current device ได้ token ใหม่** |

---

## 2. Unit Tests — TypeScript (zyra-app, Vitest)

### 2.1 API lib (`lib/api/*`) — mock `authFetch`

- `listCustomers`/`listAdmins`: query string ถูก (search/status/auth/role/sort/page/limit); map `{items,total,page,limit}`
- lifecycle fn (suspend/unsuspend/ban/unban/delete/reset): path + payload ถูก per action
- `createAdmin`: payload (name/email/role_id/password_option/password); assign-role; role CRUD + `setPermissions`
- `getPermissions`: group by category
- error propagate (401/403/409)

### 2.2 `password-strength`

- 4 rule live: ≥12 / upper+lower / special / number — แต่ละ combination; empty; ครบทุกข้อ → all pass

### 2.3 permission-matrix logic

- toggle single → count badge +1, "All accesses" +1
- enable-all master → เปิดทุก key ทุก category
- master ไม่ active เมื่อยังมี key ปิดในหมวด
- dependency: เปิด key A (depend B) → B เปิดตาม; ปิด B ที่มี dependent A → confirm → ปิด A ด้วย
- select category → render access ของหมวดนั้น

### 2.4 table logic (customer/admin)

- filter status/auth/role, debounced search, sort toggle, pagination reset on filter change
- status → pill color mapping (active/suspend/ban/deleted)
- role → tag color (super/admin/support/guest)
- date format `dd/mm/yyyy (hh:mm)`; deleted user → hashed email + generic avatar
- row-action menu contents สลับตาม status (active→Suspend/Ban; suspended→Unsuspend; banned→Unban)

### 2.5 modal logic

- Suspend/Ban: Reason required → Suspend/Ban disabled จนกรอก; counter `n/500`
- Ban/Delete: type-email gate — ปุ่ม disabled จน email ตรง; ไม่ตรง → error caption/border
- Reset: radio เลือก → Confirm enabled; force → แสดง temp + Copy
- Change role: dropdown submenu (Default/Custom) → confirm modal; hide when self
- Add admin: disabled จนทุก field valid + password policy + confirm match; auto-gen ซ่อน manual entry
- Change password (self): wrong current / weak / mismatch error; success flow

### 2.6 governance (FE)

- ดู profile ตัวเอง → ไม่มี Action button (self)
- role builder: system role → field disabled + ไม่มี Delete; delete hidden เมื่อ role >1 user

---

## 3. API Tests (route level)

| Route | Cases |
|---|---|
| `GET /admin/customers` | 200 list · filter/sort/page · 401 · 403 no-perm |
| `GET /admin/customers/{id}` (+tabs) | 200 · 404 · 403 |
| `POST /customers/{id}/suspend`·`/unsuspend` | 200 · 400 reason/transition · 403 self · 401 |
| `POST /customers/{id}/ban`·`/unban` | 200 · 400 · 403 · token revoked หลัง ban |
| `DELETE /customers/{id}` | 200 owner-transfer · 400 · 403 self · anonymized |
| `POST /customers/{id}/reset-password` | 200 link/force · 400 google · 429 rate-limit |
| `GET /customers/export` | 200 CSV · filter-aware · 403 |
| workspace-role CRUD + `/permissions` | 200 · 400 bad key · 409 in-use · 403 system |
| `POST /customers/{id}/assign-role` | 200 · 409 owner-exists · 403 |
| `GET /admins` | 200 (+role) · 403 |
| `POST /admins` | 201 manual/auto · 400 policy/dup · 403 |
| `POST /admins/{id}/suspend`·`/reactivate`·`/reset-password` | 200 · 403 governance · 401 |
| `DELETE /admins/{id}` | 200 anonymize+revoke · 403 self/super rule |
| admin-role CRUD + `/permissions` | 200 · 400 · 409 · 403 super-only key |
| `POST /admins/{id}/assign-role` | 200 · 403 self/super · 200 downgrade→revoke |
| `PUT /api/user/me/password` | 200 (current device keeps session) · 400 wrong/weak/mismatch · 401 |
| `GET /admin/permissions` | 200 catalog grouped |

---

## 4. E2E (Playwright — dev server port 3000)

> Pre-condition: seed admin (`role_='ADMIN'` + admin_role Super admin) + seed customers หลาย status; reset ผ่าน SQL ระหว่าง case. ห้ามยิง production DB

### J1 — Customer list + profile (SC-01/02)
1. Login admin → `/admin/customers` → table 100 rows, tabs, filters
2. Search email → filter; Status filter Suspend → เฉพาะ suspended; sort Registered date
3. คลิก row → profile: fields + status history timeline + Workspace tab table + Role filter
4. Pagination + empty state (search zzzz)

### J2 — Customer lifecycle (SC-03/04/05/06)
1. Suspend: reason + date → Suspend → toast; row = Suspend pill; (mailhog) suspend email
2. Unsuspend confirm → active
3. Ban: reason+note → type-email confirm (ผิด→disabled) → Ban → token revoked (customer login = "Account access restricted")
4. Delete: owner-of-N warning → type-email (invalid→error caption) → Delete → owner transferred; deleted row anonymized
5. Reset: Send link → email link (exp 1h); Force → temp password + Copy + must_change gate

### J3 — Customer RBAC (SC-07/08/09)
1. Role & Permission tab → Create role: name + toggle permissions (Workspace/VO/Chat) → count badge → Save → toast
2. Enable-all master; dependency toggle confirm
3. System role → ไม่มี Delete/แก้ไม่ได้; custom role >1 user → Delete ซ่อน
4. Assign role: change-role modal (locked workspace + Role dropdown) → confirm → toast; owner-exists → ต้องย้ายก่อน

### J4 — Admin list + create (SC-10/11)
1. `/admin/admins` → table มี Role column (tag colors); "Add admin"
2. Add admin manual: name/email/role + password + strength (4 rule) + confirm → Add → toast + invitation email
3. Add admin auto-generate: ซ่อน manual entry → temp password ส่ง email
4. Duplicate email → error; weak password → strength ไม่ผ่าน

### J5 — Admin RBAC + governance (SC-12/13/14)
1. Admin Role & Permission: create (admin catalog: User/Role/Workspace/Content/System) → Save
2. `admin.role.admin.manage` ไม่โผล่เมื่อ login เป็น non-Super
3. Assign admin role: change-role (Previous/New) → Done → toast
4. Governance: ดู profile ตัวเอง → ไม่มี Action; non-Super แก้ Super → blocked

### J6 — Admin lifecycle + self password (SC-15/16)
1. Suspend admin (reason+date) → reactivate confirm
2. Delete admin → impact box (3 bullet) → Delete → session revoked + audit anonymized (name/email ซ่อน)
3. Reset admin password (link/force)
4. Self Change password: wrong current → error; weak/mismatch → error; success → current device ยังใช้ได้, device อื่นถูก revoke
5. Force-change gate: admin ที่ must_change='Y' → redirect Change password หลัง login

---

## 5. Regression Checks

- [ ] Login/register/forgot-password เดิม (MD5) ไม่พังจาก column + token_version ใหม่
- [ ] JWT เดิม (ไม่มี `tv` claim) — guard handle graceful (treat as 0 หรือ force re-login ตามที่ตัดสินใจ)
- [ ] Existing admin pages (avatar/object/map/workspace) ไม่กระทบจาก AdminSidebar nav ใหม่
- [ ] `AdminGuard` เดิม (`ADMIN`/`SYSADMIN`) ยังทำงานร่วม `RequirePermission` ใหม่
- [ ] Workspace member เดิมที่ไม่มี `role_id` — default resolve ถูก (owner ผ่าน `owner_id` ตาม memory [[workspace-owner-no-member-row]])
- [ ] `npx tsc --noEmit` + `npm run lint` + `go test ./...` ผ่านทั้งหมด
- [ ] Migration ทุกไฟล์มี rollback คู่ (rule 06); DDL sync postgres.go ↔ migrations

## 6. Manual QA Checklist

- [ ] Pixel-compare ทุกหน้าจอกับ Figma 95–100% (rule 10) — status/role tag colors, modal 2-tier button, permission matrix
- [ ] Toast copy ตรง (Ticket-less: "Message sent" ไม่ใช้ที่นี่ — ใช้ action-specific)
- [ ] Email 7+ templates render ถูกใน Gmail จริง (suspend/unsuspend/ban/unban/delete/reset-link/reset-temp/admin-invite)
- [ ] Type-to-confirm ตรง email เป๊ะ (case-sensitive?) — ยืนยันกับ design
- [ ] Password strength meter live + policy ≥12 ถูก
- [ ] Session revocation จริง: ban/delete/change-password → device อื่นเด้งออก, current (self change) ไม่เด้ง
- [ ] Governance: self ไม่มี action; super-admin-edits-super-admin; hidden manage key
- [ ] Keyboard: Esc ปิด modal; focus trap; type-confirm ไม่ submit ด้วย Enter โดยไม่ตั้งใจ

## 7. Security Test Focus (rule 05)

- [ ] IDOR: admin A permission จำกัด → เรียก endpoint นอกสิทธิ์ → 403 (ไม่ใช่แค่ซ่อน UI)
- [ ] Privilege escalation: assign role ตัวเองสูงขึ้น → blocked; non-super ตั้ง manage key → blocked
- [ ] SQL injection: search/filter param parameterized (`$1,$2`)
- [ ] Password/temp/token ไม่ปรากฏใน log หรือ response ที่ไม่ควร
- [ ] Reset token single-use + exp 1h; rate-limit reset
- [ ] Deleted/banned user ไม่สามารถ auth ได้ (token_version + account_status ทั้งคู่ block)
