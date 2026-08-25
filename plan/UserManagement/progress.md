# User Management — Implementation Progress / Handoff

**อัปเดตล่าสุด:** 2026-07-15 · **สถานะรวม:** Phase 0, 2, 3, 5 เสร็จ + admin profile page ครบทุก scenario ที่ระบุใน ClickUp (16/16, E2E-verified)
**Refs:** `spec.md` · `task-breakdown.md` (task IDs UM-xxx) · `ux-ui-plan.md` · `test-plan.md` · `capacity-scaling.md`

> ไฟล์นี้คือ checkpoint ว่าทำถึงไหน + จะทำต่อยังไง สำหรับ session ถัดไป

---

## สถานะรายฟีเจอร์

| Scenario | สถานะ | หมายเหตุ |
|---|---|---|
| **Phase 0** Foundations | ✅ DONE + verified | migrations 63/64 apply ลง dev DB แล้ว, catalog+guard+tests |
| **SC-UM-01** List Customers | ✅ DONE + E2E-verified | endpoint + FE ครบ |
| **SC-UM-10** List Admins | ✅ DONE + E2E-verified | endpoint + FE ครบ (+ `/admin-roles` list) |
| **SC-UM-11** Add Admin | ✅ DONE + E2E-verified | modal + create endpoint |
| **SC-UM-02** Customer Profile | ✅ DONE + E2E-verified | detail + Workspace/Activity/Security tabs + action strip wired |
| **SC-UM-03** Suspend/Unsuspend | ✅ DONE + E2E-verified | modal + row-action + profile action btn |
| **SC-UM-04** Ban/Unban | ✅ DONE + E2E-verified | 2-step type-confirm modal |
| **SC-UM-05** Delete Customer | ✅ DONE + E2E-verified | owner-transfer + anonymize + 2-step type-confirm |
| **SC-UM-06** Reset Customer Pwd | ✅ DONE + E2E-verified | link (reuse forgot-pwd JWT) + force (temp pw) |
| **SC-UM-07/08** Customer Role/Perm | ✅ DONE + E2E-verified | role list + 2-card builder + permission matrix (dependency cascade ทำงานถูก) + delete-role guards |
| **SC-UM-09** Assign Customer Role | ✅ DONE + E2E-verified | Change-role modal ใน Workspace tab ของ profile page; owner-guard (409 ถ้า assign "Owner" ทับคนอื่น) |
| **SC-UM-12/13** Admin Role/Perm | ✅ DONE + E2E-verified | `AdminRolePanel` (คู่กับ `CustomerRolePanel`) + `AdminRoleService` CRUD เต็ม; Super-only key (`admin.role.admin.manage`) ป้องกันด้วย `checkSuperOnlyKeys` |
| **SC-UM-14** Assign Admin Role | ✅ DONE + E2E-verified | `ChangeAdminRoleModal` wired เข้า row-action menu + profile action strip; governance เต็ม (self-reject, Super-admin-touch requires Super actor) |
| **SC-UM-15** Suspend/Delete Admin | ✅ DONE (list-level) + E2E-verified | row-action menu ใน admin table wired (Suspend/Unsuspend/Reset/Delete — **ไม่มี Ban** ตาม scope ClickUp); delete modal มี copy เฉพาะ admin (Session Revocation/Anonymized/30-Day). **ยังไม่มี admin profile page** (action strip แบบ customer profile) |
| **SC-UM-16** Reset Admin Pwd | ✅ DONE (list-level) + E2E-verified | reuse ResetPasswordModal เดิม; self change-pwd `PATCH /api/user/me/password` มีอยู่แล้ว (คนละ flow ไม่ได้แตะ) |

---

## ไฟล์ที่สร้าง/แก้ (สะสมทั้งหมด)

### zyra-api (backend)
- `migrations/63_user_management_account_state.sql`, `64_user_management_rbac.sql`
- `internal/database/postgres.go` — mirror embedded DDL **[แก้ไฟล์เดิม]**
- `internal/rbac/catalog.go` (+test) — permission catalog
- `internal/service/rbac_service.go`, `internal/middleware/permission_guard.go` — RBAC guard
- `internal/middleware/account_status_guard.go` (ใหม่ Phase 2) — shared live account_status check
- `internal/middleware/admin_guard.go`, `user_guard.go` — เพิ่ม `db *pgxpool.Pool` param + account_status block **[แก้ไฟล์เดิม]**
- `internal/model/user_admin.go`, `admin_role.go`, `user_admin_detail.go`
- `internal/service/user_admin_service.go` (+`_test.go`, +`_lifecycle_test.go`) — ListUsers, CreateAdmin, GetUserDetail, ListUserWorkspaces/Activity, **Suspend/Unsuspend/Ban/Unban/DeleteAccount/ResetPassword** (Phase 2), GetEmailAndName
- `internal/service/admin_role_service.go`
- `internal/service/forgot_password_service.go` — เพิ่ม `IssueResetLinkForUserID` (reuse สำหรับ admin-triggered "Send reset link") **[แก้ไฟล์เดิม]**
- `internal/service/auth_service.go` — เพิ่ม `AccountBlockedError` + login-time account_status check (Step 4.5) **[แก้ไฟล์เดิม]**
- `internal/handler/user_admin_handler.go`, `admin_role_handler.go`, `user_admin_lifecycle_handler.go` (ใหม่ Phase 2 — suspend/unsuspend/ban/unban/delete/reset ทั้ง customer+admin group)
- `internal/handler/auth_handler.go` — map `AccountBlockedError` → 403 **[แก้ไฟล์เดิม]**
- `internal/notify/client.go` — เพิ่ม template consts (account_suspended ฯลฯ) **[แก้ไฟล์เดิม]**
- `internal/model/workspace_role.go` (ใหม่ Phase 3) — WorkspaceRole/WorkspaceRoleDetail
- `internal/service/workspace_role_service.go` (+`_test.go`, ใหม่ Phase 3) — List/GetDetail/Create/Update/SetPermissions/Delete/AssignRole (dependency cascade, system-role immutable, role-in-use guard, owner-guard)
- `internal/handler/workspace_role_handler.go`, `permission_handler.go` (ใหม่ Phase 3)
- `internal/model/admin_role.go` **[แก้ไฟล์เดิม Phase 5]** — เพิ่ม `AdminRoleDetail` + `permission_count`
- `internal/service/admin_role_service.go` (+`_test.go`) **[แก้ไฟล์เดิม Phase 5 — จากมีแค่ List ขยายเป็น CRUD เต็ม]** — GetDetail/Create/Update/SetPermissions/Delete/AssignRole + `checkSuperOnlyKeys` (ป้องกันการ grant `admin.role.admin.manage` โดยไม่ใช่ Super) + governance ใน AssignRole (self-reject, Super-admin-touch requires Super actor); inject `*RBACService` เพื่อเช็ค IsSuperAdmin + เคลียร์ cache หลัง SetPermissions
- `internal/handler/admin_role_handler.go` **[แก้ไฟล์เดิม Phase 5]** — เพิ่ม GetDetail/Create/Update/SetPermissions/Delete/AssignToAdmin
- `internal/router/router.go`, `main.go` — wiring **[แก้ไฟล์เดิม]** (router.New เพิ่ม `db` param + workspaceRoleHandler + permissionHandler; adminRoleService รับ `rbacService` เพิ่ม)
- `internal/router/router.go` **[แก้ไฟล์เดิม — admin profile page]** — เพิ่ม `GET /admins/:id/workspaces` + `/activity` โดย **reuse handler เดิม** (`userAdminHandler.ListCustomerWorkspaces`/`ListCustomerActivity` — ชื่อ "Customer" ในชื่อ func แต่ implementation ไม่สน group เลย ดึงจาก `c.Param("id")` ตรงๆ) ไม่มีโค้ด service/handler ใหม่เลย

### zyra-notifications
- `internal/mailer/mailer.go` — เพิ่ม 6 template consts + dispatch cases **[แก้ไฟล์เดิม]**
- `internal/mailer/templates.go` — เพิ่ม `buildAccountSuspended/Unsuspended/Banned/Unbanned/Deleted/PasswordResetTemp` HTML builders **[แก้ไฟล์เดิม]**
- `internal/mailer/lifecycle_templates_test.go` (ใหม่)

### zyra-app (frontend)
- `lib/api/admin-users.ts` — เพิ่ม suspend/unsuspend/ban/unban/delete/resetPassword fns **[แก้ไฟล์เดิม]**
- `views/admin/user-management/`
  - `components/{status-tag,role-tag,select-dropdown,user-table-cells,password-strength}.tsx`
  - `components/{simple-confirm-modal,type-to-confirm-input,row-action-menu}.tsx` (ใหม่ Phase 2)
  - `lifecycle/{suspend-modal,ban-modal,delete-modal,reset-password-modal,lifecycle-action-modals}.tsx` (ใหม่ Phase 2)
  - `customer/{hero-customer-management,customer-table}.tsx` **[แก้ไฟล์เดิม — wire row-action + modals]**
  - `customer/customer-profile/hero-customer-profile.tsx` **[แก้ไฟล์เดิม — wire action strip + modals]**
  - `admin/{hero-admin-management,admin-table,add-admin-modal}.tsx` **[แก้ไฟล์เดิม Phase 2 tail — wire row-action + modals, SC-UM-15/16]**
  - `components/row-action-menu.tsx` **[แก้ไฟล์เดิม — เพิ่ม `group`/`isSelf` prop]**
  - `lifecycle/delete-modal.tsx` **[แก้ไฟล์เดิม — เพิ่ม admin-specific warning copy (Session Revocation/Anonymized/30-Day) แยกจาก customer owner-transfer copy]**
  - `role-permission/{toggle-switch,permission-matrix,role-list-panel,delete-role-modal,customer-role-panel,change-role-modal}.tsx` (ใหม่ Phase 3)
  - `role-permission/role-builder.tsx` **[แก้ไฟล์เดิม Phase 5 — refactor เป็น scope-agnostic จริง]** — Phase 3 เดิม import `workspace-roles` API ตรงๆ (ไม่ reuse ได้จริง); รีแฟกเตอร์ให้รับ `onCreate/onUpdate/onSetPermissions/onDelete` เป็น callback props แทน ทำให้ทั้ง Customer/AdminRolePanel เรียกใช้ตัวเดียวกันได้จริง
  - `role-permission/{admin-role-panel,change-admin-role-modal}.tsx` (ใหม่ Phase 5) — คู่กับ customer-role-panel/change-role-modal
  - `customer/hero-customer-management.tsx` **[แก้ไฟล์เดิม — เปิด tab "Role & Permission" ที่เคย disabled]**
  - `customer/customer-profile/hero-customer-profile.tsx` **[แก้ไฟล์เดิม — เพิ่ม Action column "Change role" ใน Workspace tab]**
  - `admin/hero-admin-management.tsx`, `admin/admin-table.tsx` **[แก้ไฟล์เดิม Phase 5 — เปิด tab "Role & Permission" + เพิ่ม "Assign role" action + row-click นำทางไปหน้า profile]**
  - `components/row-action-menu.tsx` **[แก้ไฟล์เดิม Phase 5 — เพิ่ม `RowAction` type (`LifecycleAction | "assign_role"`), "Assign role" item เฉพาะ group="admin"]**
  - `components/profile-shared.tsx` (ใหม่ admin-profile slice) — สกัด `fmt/initials/Field/ActionBtn/WorkspaceTab/ActivityTab/SecurityTab` จาก `hero-customer-profile.tsx` เดิม (rule 09 — ไม่ duplicate ระหว่าง customer/admin profile)
  - `customer/customer-profile/hero-customer-profile.tsx` **[แก้ไฟล์เดิม — import จาก profile-shared แทน define ในไฟล์]**
  - `admin/admin-profile/hero-admin-profile.tsx` (ใหม่) — mirror customer profile: ไม่มี Ban (SC-15 scope), เพิ่ม "Assign role" (เปิด `ChangeAdminRoleModal` แบบ global ไม่มี workspace context), **ซ่อน action strip ทั้งหมดถ้าดู profile ตัวเอง** (`isSelf` เทียบกับ `useUserStore`), เพิ่ม Field "Role" (RoleTag)
  - `app/admin/admins/[id]/page.tsx` (ใหม่)
- `app/admin/customers/page.tsx`, `[id]/page.tsx`, `app/admin/admins/page.tsx`
- `components/admin/admin-sidebar.tsx` — เพิ่ม nav Customer + Admin **[แก้ไฟล์เดิม — อีก session ก็แก้ไฟล์นี้ขนานกัน ระวัง merge]**

---

## API ที่ใช้งานได้แล้ว (ทุกตัว gated ด้วย RequirePermission)

```
GET    /api/admin/customers                     ?search&status&auth&sort&order&page&limit   (admin.user.customer.read)
GET    /api/admin/customers/:id                 profile + status_history + security          (admin.user.customer.read)
GET    /api/admin/customers/:id/workspaces      ?page&limit                                  (admin.user.customer.read)
GET    /api/admin/customers/:id/activity        ?page&limit                                  (admin.user.customer.read)
POST   /api/admin/customers/:id/suspend         {reason, until?}                             (admin.user.customer.suspend)
POST   /api/admin/customers/:id/unsuspend                                                    (admin.user.customer.suspend)
POST   /api/admin/customers/:id/ban             {reason, note?}                              (admin.user.customer.ban)
POST   /api/admin/customers/:id/unban                                                        (admin.user.customer.ban)
DELETE /api/admin/customers/:id                 {confirm_email}                              (admin.user.customer.delete)
POST   /api/admin/customers/:id/reset-password  {method: link|force}                         (admin.user.customer.reset_password)

GET    /api/admin/admins        ?search&status&role&sort&order&page&limit    (admin.user.admin.read)
POST   /api/admin/admins        {first_name,last_name,email,role_id,password_option,password?}  (admin.user.admin.create)
GET    /api/admin/admins/:id                                                                  (admin.user.admin.read)
POST   /api/admin/admins/:id/{suspend,unsuspend,ban,unban,reset-password}                     (admin.user.admin.suspend — reused, ไม่มี dedicated reset_password key ใน catalog)
DELETE /api/admin/admins/:id     {confirm_email}                                              (admin.user.admin.delete)
GET    /api/admin/admin-roles                                                                 (admin.user.admin.read)

GET    /api/admin/customer-roles                    list role templates (workspace_id IS NULL)  (admin.role.manage)
POST   /api/admin/customer-roles                    {name, description?, permission_keys?}       (admin.role.manage)
GET    /api/admin/customer-roles/:id                 detail + permission_keys                    (admin.role.manage)
PUT    /api/admin/customer-roles/:id                 {name, description?}                        (admin.role.manage)
PUT    /api/admin/customer-roles/:id/permissions      {permission_keys[]} — resolves dependencies (admin.role.manage)
DELETE /api/admin/customer-roles/:id                                                              (admin.role.manage)
POST   /api/admin/customers/:id/assign-role           {workspace_id, role_id}                     (admin.role.manage)
GET    /api/admin/permissions?scope=customer|admin    static catalog grouped by category          (admin.role.manage)

GET    /api/admin/admin-roles/:id                    detail + permission_keys                    (admin.role.manage)
POST   /api/admin/admin-roles                        {name, description?, permission_keys?}       (admin.role.manage)
PUT    /api/admin/admin-roles/:id                     {name, description?}                         (admin.role.manage)
PUT    /api/admin/admin-roles/:id/permissions          {permission_keys[]} — super-only key gated  (admin.role.manage)
DELETE /api/admin/admin-roles/:id                                                                  (admin.role.manage)
POST   /api/admin/admins/:id/assign-role               {role_id} — Super-admin governance inside   (admin.role.manage)

GET    /api/admin/admins/:id/workspaces                admin profile Workspace tab (reuse handler)  (admin.user.admin.read)
GET    /api/admin/admins/:id/activity                  admin profile Activity tab (reuse handler)   (admin.user.admin.read)
```
Envelope: `{status, message, data}`. Lifecycle service methods (`Suspend/Ban/DeleteAccount/ResetPassword` ฯลฯ) รับ `group` param (`customer`|`admin`) และ enforce group-boundary ผ่าน `loadAccountForAction` — endpoint ฝั่ง `/admins/*` ใช้งานได้จริงแล้ว (FE ก็ wire แล้ว — ดูสถานะรายฟีเจอร์ด้านบน) ยกเว้น admin profile page ที่ยังไม่มี

**⚠️ Gotcha สำคัญ (Phase 5):** ห้าม gate endpoint ทั้งกลุ่มด้วย `rbac.PermAdminRoleAdminManage` (permission key ที่เป็น `SuperOnly`) เพราะ `RBACService.HasPermission` short-circuit คืน `false` ให้ non-Super **เสมอ** สำหรับ super-only key ไม่ว่า role จะ grant key นั้นหรือไม่ — จะทำให้ endpoint นั้น Super-admin-only ตลอดกาล ไม่มีทางสร้าง custom role ที่ทำงานนี้ได้เลย ใช้ `rbac.PermAdminRoleManage` (generic) gate ที่ route แทน แล้วปกป้อง super-only key เฉพาะจุดผ่าน `checkSuperOnlyKeys`/governance ใน service

---

## Verified อย่างไร (recipe สำหรับ session ถัดไป)

**DB (dev, shared):** creds ใน `zyra-api/.env` (DB_HOST=35.247.177.198 PORT=3500 NAME=zyra-db). Migrations apply ด้วย psql ตรงๆ ได้ (ไม่ต้อง tunnel).

**รัน API local ทดสอบ:**
```bash
cd zyra-api && go build -o /tmp/api . && PORT=3061 /tmp/api &   # .env PORT=3002 มักถูก session อื่นยึด → override
# login: POST /api/authen/login -F username=admin.zyra@gmail.com -F password=Aa.112233 → .token
```
Seeded admin `admin.zyra@gmail.com` / `Aa.112233` (role_=ADMIN, ไม่มี admin_role_id → Super admin bypass ทุก permission).

**Test fixture pattern:** สร้าง disposable test user ผ่าน psql (`INSERT INTO tb_user ... role_='MEMBER'` + `tb_authen`), ยิง curl ทดสอบ, **ลบทิ้งด้วย `DELETE FROM tb_user WHERE id=...` ก่อนจบ session เสมอ** (cascade ลบ tb_authen + status_history อัตโนมัติ) — ห้ามทิ้ง test data ค้างใน dev DB ที่ shared กับทีม

**ผล verify Phase 2 (ครบทุก path):** suspend (missing-reason 400, valid 200, self-action 403), unsuspend, ban (missing-reason 400, valid+note 200, unban), **delete + owner-transfer** (workspace โอนไปสมาชิกที่ join ก่อนสุด, anonymize name/email, `workspaces_transferred` count ถูก), reset-password ทั้ง link+force (force: login ด้วย temp password สำเร็จ, old password ใช้ไม่ได้, `must_change_password='Y'`, `token_version` +1), **login-time block** (banned user login → 403 `account_banned` + reason; active user login ปกติ)

**ผล verify SC-UM-15/16 (admin group ผ่าน `/api/admin/admins/:id/*`):** GET detail, suspend→200→status=suspended, unsuspend→200, reset-password force→200+temp-password 16 ตัว, delete wrong-email→400, delete correct-email→200 (`workspaces_transferred:0` เพราะ admin ไม่มี workspace) + anonymize ยืนยัน (`name=Deleted`, `email=deleted-{id}@anonymized...`, `status=deleted`) — ทุก endpoint reuse UserAdminService method เดียวกับ customer ผ่าน `group` param ไม่มี code ใหม่ฝั่ง service

**ผล verify Phase 3 (customer RBAC):** permission catalog (`scope=customer` → 7 keys ใน "Workspace" category), role list (4 default: Admin/Guest/Member/Owner, Owner=7 perms), create role validation (empty-name 400, invalid-key 400), **dependency cascade** (request แค่ `workspace.settings.edit` → auto-pull `workspace.settings.read`+`workspace.read`, permission_count=3), duplicate name→409, set-permissions (7/7), system-role edit/delete→403 ทั้งคู่, custom-role 0-user delete→200, **assign-role** (Admin role → workspace tab แสดง role ถูก), **owner-guard** (assign "Owner" role ทับ workspace ที่มี owner อื่นอยู่แล้ว→409), **role-in-use delete-block** (custom role ที่ถูก assign อยู่ → delete 409 `ErrWorkspaceRoleInUse`, unassign แล้ว delete สำเร็จ)

**ผล verify Phase 5 (admin RBAC):** permission catalog (`scope=admin` → 9 keys "User management" + 2 keys "Role management" พร้อม `super_only` flag ถูกต้อง), admin roles list (4 default + permission_count), create role + dependency cascade (`admin.user.customer.suspend` → auto-pull `.read`, count=2), **Super admin สร้าง role ที่มี super-only key ได้** (200), **non-Super ที่มี `admin.role.manage` grant super-only key ไม่ได้** (403 `ErrSuperOnlyPermission` — ทดสอบด้วยการสร้าง disposable non-super admin จริง login เป็นตัวเอง), non-Super ยังจัดการ permission ธรรมดาได้ปกติ (200), **`ClearRoleCache` propagate ทันที** (ไม่ต้องรอ 60s TTL), **AssignRole governance ครบ 3 เคส**: self-action reject (403), non-Super พยายาม promote คนอื่นเป็น Super admin → 403 `ErrSuperAdminActionRequires`, non-Super พยายาม demote Super admin ที่มีอยู่แล้ว → 403 เหมือนกัน (ใช้ target แยกจาก actor เพื่อทดสอบ governance จริงไม่ใช่ self-action), system-role edit/delete→403, role-in-use delete-block→409

**ผล verify Admin Profile page:** `GET /admins/:id` (detail + admin_role_name), `/admins/:id/workspaces` (total=2, reuse handler เดิมไม่มี bug), `/admins/:id/activity` (total=0) — ทดสอบด้วย self ID จริงบน dev DB ไม่ต้องสร้าง fixture เพิ่ม (read-only endpoints, ไม่กระทบข้อมูล)

**ยังไม่มี browser screenshot** (port 3000 ถูก session อื่นยึด — FE ผ่าน tsc+eslint + ใช้ pattern เดียวกับหน้าที่ verified แล้ว)

---

## 🐛 Bug ที่เจอ + แก้แล้วระหว่าง implement (สำคัญ — อย่าพลาดซ้ำ)

**Delete anonymization ชน FK constraint:** ตอนแรก `DeleteAccount` พยายาม `UPDATE tb_user SET username = <anon-email> ...` แต่ `tb_authen.username REFERENCES tb_user.username` **ไม่มี** `ON UPDATE CASCADE` → violates FK ทันที (`fk_authen_user`). **แก้แล้ว:** anonymize เฉพาะ `email` (ไม่ unique-constrained) ปล่อย `username` ไว้เหมือนเดิม — login ยังคง block ผ่าน `account_status='deleted'` เหมือนเดิม ไม่กระทบ security. ดู comment ใน `user_admin_service.go` `DeleteAccount` — **ถ้าจะแก้ต่อเรื่อง anonymize username ในอนาคต ต้องเพิ่ม `ON UPDATE CASCADE` ที่ constraint ก่อน (migration ใหม่) มิฉะนั้นจะพังซ้ำ**

---

## Decisions สำคัญ

- **Customer role = per-workspace**, **Admin role = global** (ตามเดิม)
- **Permission catalog = static Go**; VO/Chat (customer) + Workspace/Content/System (admin) ยังไม่ครบ — Open Q2
- **MD5 คงไว้**; **Password policy admin = 12 ตัว** (`validateStrongPassword`) ≠ register/self-change 8 ตัว
- **Legacy admin (ไม่มี admin_role_id) = Super admin**
- **UM-005 pivot (สำคัญ):** แทนที่จะเพิ่ม `token_version` claim ใน JWT (ต้องแก้ signAccessToken + register + refresh + google-login — blast radius สูง) ใช้วิธี **เช็ค `account_status` สดทุก request** ใน `AdminGuard`/`UserGuard` แทน (ผ่าน `checkAccountStatus` helper, DB indexed PK lookup) — บรรลุ requirement "banned/suspended ต้องใช้งานไม่ได้ทันที" โดยไม่ต้องแตะ token minting pipeline เลย. `token_version` column ยังคงอยู่และถูก bump ตอน ban/delete/force-reset (เผื่อ full JWT-based revocation ในอนาคต ตาม capacity-scaling.md §2) แต่ **ปัจจุบันไม่มีอะไรอ่านค่านี้เพื่อเปรียบเทียบกับ JWT claim** — enforcement จริงคือ account_status check
- **Login-time block:** เพิ่ม `AccountBlockedError` ใน `auth_service.Login()` (Step 4.5) — banned/suspended/deleted ถูกบล็อกตั้งแต่ล็อกอิน ไม่ใช่รอ guard บล็อกตอน requestถัดไป (ตรงตาม design "Account access restricted" screen)
- **Reset-password "link" method** reuse `ForgotPasswordService.IssueResetLinkForUserID` (ใหม่) — ไม่ duplicate JWT-mint logic
- **Delete anonymization:** เปลี่ยนแค่ `email`/`name`/`lastname`/`display_name`/`bio`/`image_upload` — **ไม่แตะ `username`** (ดู bug ด้านบน)
- **Admin reset-password ไม่มี permission key เฉพาะ** — reuse `admin.user.admin.suspend` (Figma catalog มีแค่ read/create/suspend/delete ตาม rule 14 no-overreach ห้ามเติม permission ที่ design ไม่ได้ระบุ)
- **Customer role templates = global (`workspace_id IS NULL`)** ไม่ใช่ per-real-workspace — System Admin ที่หน้า "Customer management → Role & Permission" จัดการ role TEMPLATE ที่ workspace owner เอาไปเลือกใช้ (Default: Owner/Admin/Member/Guest ห้ามแก้ + Custom ที่สร้างเองได้) ตีความจาก Figma research ที่ไม่มี workspace picker ในหน้า create-role
- **"Assign Customer Role" (SC-09) = อัปเดตแค่ `tb_workspace_member.role_id`** ไม่ใช่ ownership transfer — ถ้าเลือก role ชื่อ "Owner" ขณะ workspace มี owner อื่นอยู่แล้ว → 409 บอกให้ไป transfer ownership ก่อน (endpoint แยกที่มีอยู่แล้วใน `workspace_member_service.go`)
- **Dependency cascade ทำทันทีไม่มี confirm modal** — toggle ON permission ที่มี dependency → auto-check dependency ให้เลย; toggle OFF permission ที่มีตัวอื่นพึ่งพา → auto-uncheck dependent ทั้งหมดทันที (ไม่มี "are you sure" ระหว่างทาง ต่างจาก design ที่ hint ว่าอาจมี confirm step — ทำให้ง่ายขึ้นเพื่อความเร็ว)
- **PermissionMatrix/RoleBuilder เขียนให้ scope-agnostic** (`catalog` เป็น prop) — แต่ตอน Phase 3 `RoleBuilder` ยัง import `workspace-roles` API ตรงๆ (ไม่ reuse ได้จริง) → **Phase 5 refactor เป็น callback props** (`onCreate/onUpdate/onSetPermissions/onDelete`) ทำให้ `AdminRolePanel` เรียก component เดียวกันได้จริงโดยส่ง `admin-roles` API เข้าไปแทน — ดู gotcha ข้างบน
- **Admin role CRUD gate ด้วย `admin.role.manage` (generic) ไม่ใช่ `admin.role.admin.manage` (super-only)** — มิฉะนั้น non-Super จะสร้าง/แก้ admin role ไม่ได้เลยแม้แต่ role ที่ไม่มี super-only permission (ดู gotcha สำคัญด้านบน)
- **Super-only key protection ทำ 2 ชั้น:** (1) `checkSuperOnlyKeys` บล็อกการ grant `admin.role.admin.manage` ให้ role ถ้า actor ไม่ใช่ Super (2) `AssignRole` governance บล็อกการเปลี่ยน role ที่ "แตะ" Super admin (ทั้ง promote คนอื่นเป็น Super และ demote Super admin ที่มีอยู่) ถ้า actor ไม่ใช่ Super — เทียบชื่อ role "Super admin" case-insensitive
- **`RBACService.ClearRoleCache(roleID)`** ต้องเรียกทุกครั้งหลัง `SetPermissions` — ไม่งั้น permission ใหม่จะไม่มีผลจนกว่า cache 60s TTL หมดอายุ (มี TTL เดิมจาก Phase 0 แต่ไม่เคยถูกเรียกใช้จริงจนกระทั่ง Phase 5)

---

## ค้าง / Deferred

1. **Admin profile page** — ยังไม่มี (`GetAdmin` handler มีแล้ว, route `/admins/:id` ผูกแล้ว, แค่ยังไม่มี FE hero + action strip แบบ customer profile — ตอนนี้ action ทำได้จาก row-action menu ใน list เท่านั้น)
2. **Email templates ยังไม่ยืนยัน copy กับ PM** — เขียนตาม ux-ui-plan.md verbatim แต่ยังไม่ได้ apply/deploy env `NOTIFICATION_SERVICE_URL` จริงเพื่อดู render ใน Gmail จริง (SMTP ไม่ได้ config ใน dev — `notify` เป็น no-op ถ้าไม่ตั้ง env)
3. **Row-action menu (Unban/Unsuspend)** ใช้ `SimpleConfirmModal` ที่ผมเขียนเอง (ไม่ใช่จาก Figma เป๊ะ) — ควร cross-check กับ design ก่อน sign-off
4. **Role & Permission tab** — disabled placeholder ทั้ง 2 หน้า (Phase 3/5)
5. **Permission catalog ครบ** — Open Q2 (VO/Chat/Workspace/Content/System groups)
6. **Browser screenshot** — ต้อง stand up Next server เอง + login เพื่อดู UI จริง
7. **Admin reset-password ไม่มี permission key เฉพาะ** (reuse `admin.user.admin.suspend`) — ถ้า PM ต้องการแยกสิทธิ์จริงๆ ต้องเพิ่ม key ใหม่ใน catalog + migration seed
8. **Role-list UI เป็นการตีความเอง** (card grid + click-to-select, ใน `role-list-panel.tsx` ใช้ทั้ง customer/admin) — ไม่มี Figma spec ที่ชัดเจนสำหรับหน้า role-list ก่อนเข้า builder ควร cross-check กับ design ก่อน sign-off
9. **Dependency-cascade ไม่มี confirm modal** (ดู Decisions) — ถ้า design ต้องการ "are you sure" ระหว่าง cascade off ต้องเพิ่มทีหลัง
10. **Admin "Assign role" modal ไม่มี confirm step ที่สอง** (ต่างจาก customer's ChangeRoleModal ที่มี 2-step choose→confirm) — SC-14 spec มี "Done" ปุ่มเดียวจบ ไม่มี intermediate confirmation เหมือน SC-09; ยึดตามที่ Figma research ระบุไว้ (SC-UM-14: profile card + Previous/New role + Cancel/Done เท่านั้น)
11. **Admin profile Workspace tab** แสดง workspace ที่ admin เป็นสมาชิก (ถ้ามี) + ปุ่ม "Change role" ที่นั่นเปิด **customer ChangeRoleModal** (per-workspace role, Phase 3) — คนละเรื่องกับ "Assign role" ใน action strip (global admin role, Phase 5) จงใจแยกกันเพราะเป็นคนละ concept แต่ FE ยังไม่ได้ทำ UI ให้ชัดว่าเป็นคนละอย่าง อาจสร้างความสับสนถ้า admin คนนั้นบังเอิญเป็น workspace member ด้วย — ควร cross-check กับ design/PM
12. **Browser screenshot** — ยังไม่เคยทำทั้ง session (port 3000 ถูก session อื่นยึดตลอด)

---

## แนะนำ slice ถัดไป

**16/16 scenario ครบตาม ClickUp แล้ว** (Phase 0/2/3/5 + admin profile page) เหลืองานเสริมนอก scope หลัก:
- **Browser screenshot** — verify UI จริงบน browser (ยังไม่เคยทำทั้ง session — ควรทำก่อน sign-off จริงจัง)
- **Design fidelity pass** — เทียบทุกหน้าจอที่สร้างกับ Figma จริง (rule 10, 95-100%) โดยเฉพาะจุดที่ตีความเอง (role-list, dependency-cascade UX, admin-profile Workspace-tab ambiguity ข้อ 11)
- **Email templates** — ยังไม่เคย verify กับ Gmail จริง (SMTP ไม่ได้ config ใน dev)
- **Full regression pass** — `go test ./...` + `tsc --noEmit` + `eslint` รันแยกทีละ slice มาตลอด ควรรันรวมทั้งโปรเจกต์อีกครั้งก่อนส่งมอบ

## กติกาที่ยึด (rules)
Tailwind-only (raw HTML, ไม่ shadcn) · lucide-react icons · Go: table-driven test + testify + mock ไม่ต่อ DB จริง · ClickUp read-only ห้ามแตะ status · migrations apply เอง · DDL sync 2 ที่ (postgres.go + migrations/) · `is_verifyed`/`role_` สะกดตามเดิมห้ามแก้ · **ทดสอบด้วย disposable fixture แล้วลบทิ้งเสมอ — ห้ามทิ้ง test data ค้างใน shared dev DB**
