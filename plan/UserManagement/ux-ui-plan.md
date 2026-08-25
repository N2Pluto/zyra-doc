# User Management Module — UX/UI Plan (Pixel-Perfect)

> **Source:** Figma file `Map8gX0L2hk7HnkaFRfhtj` (Zyra design — More Organised ver.) — ดึง spec ผ่าน Figma MCP 2026-07-15
> **Canvas:** 1440 × 1024 px · Design tokens ร่วมกับ Chat / VirtualOffice / UserGuide modules
> **Scope:** SC-UM-01 ~ SC-UM-16 (Admin back-office เท่านั้น — ไม่ใช่ member surface)
> **Version:** 1.0 · **Date:** 2026-07-15
> **Refs:** `task-breakdown.md` · `test-plan.md` · `capacity-scaling.md`
> ClickUp: https://app.clickup.com/t/86d34t7a7

---

## 0. หลักการ

- ทุกหน้าเป็น **Admin back-office** — เข้าผ่าน `AdminGuard` + permission-aware guard (`/api/admin/*`) ตาม rule 15
- **Tailwind-only** (rule 08) + icon จาก `lucide-react` เท่านั้น (rule 12); ห้าม shadcn, ห้าม inline SVG (ยกเว้น `components/ui/icon.tsx`)
- Modal/dropdown = hand-rolled overlay + panel (`fixed inset-0 z-50` + click-outside) ตาม pattern เดิม
- Toast ใช้ `zyraToast` (`lib/toast.tsx`) — 336w มุมขวาบน
- **Reuse ก่อนสร้างใหม่** (rule 09): `AdminSidebar`, `workspace-pagination`, `admin-filter-menu`, `admin-sort-menu` มีอยู่แล้ว — ต่อยอด ไม่ fork
- Dark theme เดียว (ไม่มี light mode)

---

## 1. Design Tokens (ร่วมทั้ง 16 หน้า)

### 1.1 Colors

| Token | ค่า | ใช้กับ |
|---|---|---|
| Background/Secondary | `#2B3540` | page canvas (หลัง card) |
| Background/Primary | `#242B32` | sidebar, headbar, card, table, input, modal |
| Shade Black/50% | `rgba(26,27,30,0.5)` | profile card ใน change-role modal |
| Shade Black/500 | `#1A1B1E` | text บนปุ่มขาว |
| Primary/500 | `#58D68D` | primary button, active tab underline, active sidebar, status "Active", count, Unsuspend/Confirm |
| Primary/20% | `rgba(88,214,141,0.2)` | active sidebar item bg, active category bg |
| Primary/10% | `rgba(88,214,141,0.1)` | "Active" status pill bg+border |
| Primary/700 | `#3E9864` | (hover ref) |
| CSV green | `#005F2B` | ปุ่ม Export CSV |
| Yellow/500 | `#ECC819` | status "Suspend" text; pill bg `rgba(236,200,25,0.1)` |
| Orange/500 | `#FF8000` | status "Ban" text; pill bg `rgba(255,128,0,0.1)` |
| Red/500 | `#F03A3A` | status "Deleted", danger button, "cannot be undone", delete menu |
| Red/5% · 20% · 50% | `rgba(240,58,58,…)` | danger ghost button bg/border (Delete/Edit-role, Clear all) |
| Red count badge | `#D41818` | permission category count badge |
| Grey/500 | `#8C99A6` | secondary text, column header, label, count, description |
| Grey/600 | `#7F8B97` | locked/filled input value (Workspace read-only) |
| Grey/700 | `#636D76` | input placeholder |
| Grey/900 | `#3B4046` | table row bottom border |
| Navy/500 | `#2C5AE4` | status-history timeline icon; admin role "Support" tag |
| Role tag: Super admin | `#D457F0` (pink) | admin role pill (text+border, bg 10%) |
| Role tag: Admin | `#2DB6FF` (blue) | admin role pill |
| Role tag: Support | `#2C5AE4` (navy) | admin role pill |
| Role tag: Guest | `#8C99A6` (grey) | admin role pill |
| Disabled button | bg `#DBDFE3` / border `#B2BBC3` / text `#A3ADB8` | ปุ่ม primary ตอน disabled (Save/Add/Suspend/Send) |
| Avatar fallback | text-initials bg `#7EA2FC` · image-avatar bg `#FFA8A8` | avatar |
| White 5% / 10% / 20% | `rgba(255,255,255,…)` | subtle fill / language pill / border |
| Overlay | `rgba(0,0,0,0.5)` + `backdrop-blur-[4px]` (confirm modal) | ทุก modal |
| Menu shadow | `0 4px 16px rgba(255,255,255,0.08)` | modal, dropdown, submenu, toast (light glow) |

### 1.2 Typography (Inter)

| Style | Spec | ใช้ |
|---|---|---|
| H/Bold (Title) | 20 · 700 · lh normal | page title ("Customer management") |
| Sub/Medium | 16 · 500 · 22 | modal title, section title ("Customer lists") |
| Sub/Regular | 16 · 400 · 22 | ปุ่มใหญ่ 42px (Export CSV, modal buttons) |
| Body/Bold | 14 · 700 · 18 | profile name |
| Body/Medium | 14 · 500 · 18 | tab label, small button |
| Body/Regular | 14 · 400 · 18 | table cell, input, menu item, body |
| Caption 1/Regular | 12 · 400 · 15 · tracking −0.43 | status pill, char counter, description, email sub-line |
| Caption 2/Medium | 10 · 500 · 14 | count badge |

### 1.3 Shape / มาตรฐานปุ่ม

- **Radius:** 24 (success modal) · 16 (card, modal, dropdown, toast, panel) · 8 (input, page/form button, card row) · 6 (confirm-modal button, pagination cell) · 4 (status pill, tag) · 90/100 (count badge, avatar)
- **ปุ่ม 2 tier:** page/form modal = `h-[42px] rounded-[8px]` label 16 · confirm modal = `h-[32px] rounded-[6px]` label 14
- **ปุ่มมาตรฐาน:** primary `bg-[#58D68D] text-white` · cancel/neutral **ปุ่มขาว** `bg-white text-[#1A1B1E]` (ไม่ใช่ ghost) · danger solid `bg-[#F03A3A] text-white` · danger ghost `bg-[rgba(240,58,58,0.05)] border-[rgba(240,58,58,0.2)] text-[#F03A3A]` · back/secondary `bg-white/5 border-white/20 text-white` · disabled = token ด้านบน
- **Input:** `h-[42px] rounded-[8px] bg-[#242B32] border-white/20 px-3 py-2` placeholder `#636D76` · **Textarea:** `h-[100px] items-start` + counter `n/max` (n ขาว, /max grey) มุมขวา
- **Switch (toggle):** 48×24 · **Radio:** 16px · **Status/Role Tag:** `px-4 py-2 rounded-[4px]` bg+border 10% ของสี, text 12

---

## 2. Shared Chrome — Back-office Shell

> Component `Sidebar_backoffice` + `Headbar` ใช้ทุกหน้า full-page (SC-UM-01,02,07,08,10,12,13,16). **Reuse `components/admin/admin-sidebar.tsx`** — เพิ่ม section "User management" (Customer, Admin) ถ้ายังไม่มี

### 2.1 Sidebar (275px, `bg-[#242B32] p-4 gap-6`)
- Logo 56×56 บนสุด + ปุ่ม collapse (`PanelLeftClose` 16)
- **Section "Workspace"** (header 14 `#8C99A6` + chevron): Avatar / Object / Map / Workspace management
- **Section "User management"**: **Customer** · **Admin** — active item `bg-[rgba(88,214,141,0.2)] text-[#58D68D]`, icon 16 + label 14, `min-h-[42px] p-3 rounded-[8px]`
- ⚠️ `Users` icon ถูกใช้กับ Avatar management แล้ว — Customer/Admin ใช้ icon อื่น (`UserRound` / `ShieldCheck` / `UserCog`)

### 2.2 Headbar (`left-275 w-1165 h-72 bg-[#242B32] px-4 py-2` space-between)
- ขวา (gap-4): Language pill (`bg-white/10 rounded-[8px] px-2 py-2.5` flag24 + "EN" + chevron) + Profile (avatar 40 + name Body/Bold + chevron)

### 2.3 Tab bar (`left-291 top-88 w-1133 bg-[#242B32] rounded-[16px] p-4 gap-4`)
- Tab `pl-2 pr-4 py-3` icon16 + label14; active = `border-b border-[#58D68D]`
- Customer side: **Customer management** | **Role & Permission**
- Admin side: **Admin management** | **Role & Permission**

### 2.4 Main card (`left-291 top-170 w-1133 bg-[#242B32] rounded-[16px] p-4 gap-6`)

---

## 3. SC-UM-01 — List Customers

**Purpose:** ตาราง customer ทั้งหมด + search / filter / sort / row-action / export / pagination

- **Header row** (space-between): title block → **"Customer management"** (H/Bold 20) + **"Manage customer accounts and track customer activity."** (14 `#8C99A6`) · ขวา = Search `w-[448px] h-[42px]` placeholder **"Search for customer by username or email"** (icon `Search` 16)
- **List sub-header:** **"Customer lists"** (Sub/Medium) + **"(100)"** (16 `#8C99A6`) · ขวา 2 dropdown: **"Status : All"** และ **"Ath. via : All"** (label grey, value ขาว, chevron) — dropdown panel `bg-[#242B32] p-2 rounded-[16px]` menu shadow
- **Table** (`rounded-[16px]`, columns = flex stacks): header cell `h-[56px] p-3 border-b border-white/20` label 14 `#8C99A6` + sort icon; row `h-[64px] p-3 border-b border-[#3B4046]`
  | Column | Content | Sort |
  |---|---|---|
  | Name (flex-grow) | avatar40 + name14 ขาว / email12 `#8C99A6` | — |
  | Status (w-100) | Status pill | — |
  | Workspaces | number | ✓ |
  | Last active | `13/11/2026 ` ขาว + `(11:00)` grey | ✓ |
  | Registered date | เหมือนบน | ✓ |
  | Action | `MoreVertical` 16 (centered) | — |
- **Status pill:** Active `#58D68D` · Ban `#FF8000` · Suspend `#ECC819` · Deleted `#F03A3A` (bg+border 10%)
- **Row-action menu** (`bg-[#242B32] p-2 rounded-[16px]` menu shadow, item `p-3` icon16+14, contents สลับตาม status): Suspend (`Ban`) / Unsuspend / Ban / Unban (`X`) — divider — Reset password (`Key`) / Delete (`Trash2`, `#F03A3A`)
- **Footer** (space-between): **Export CSV** (`bg-[#005F2B] h-[42px] rounded-[8px]` `Upload` icon) + Pagination (reuse `workspace-pagination.tsx`: prev / cell 32×32 rounded-6, active `#58D68D` / "20 / page")
- **Empty state:** variant `Customer list - Empty`
- **Auth filter values:** Email / Google · **Deleted user** row = email hash `d3b07384…@hashed-anonymized.net` + generic avatar

---

## 4. SC-UM-02 — Customer Profile Detail

**Purpose:** โปรไฟล์ customer 1 คน — identity/status + tab (Workspace / Activity log / Security) + admin actions

- **Top action strip:** Back control + **Suspend** · **Ban** · **Delete** (Delete danger)
- **Left profile card** (`w-[341px] bg-[#242B32] rounded-[16px] gap-6`): avatar + name (Body/Bold) + email + fields — **Phone no.**, **Auth. via** (Email), **Status** (pill), **Registered date**, **Last active** + **Status history** timeline (icon 32 วงกลม Navy `#2C5AE4` ต่อ entry, `w-[333px]`)
- **Right content card** (`left-291 top-178 w-1133 h-830 rounded-[16px] p-4 gap-4`):
  - **Tabs:** Workspace · Activity log · Security (underline-style)
  - **Workspace tab (default):** sub-header **"Workspace"** + **"(20)"** + **"Role : All"** filter (`w-160`) + table: Name / Role (Owner·Admin·Member·Guest) / Joined date / Action; pagination "10 / page"
  - **Activity log tab:** timeline ของ `user_activities` (login, password reset, status change)
  - **Security tab:** login/lock/verify info
- **Workspace detail modal** (900×600 overlay) เปิดจาก row — reuse workspace detail ที่มีอยู่ถ้าเป็นไปได้

---

## 5. SC-UM-03 — Suspend / Unsuspend Customer

### 5.1 Suspend modal (`w-[455px] bg-[#242B32] rounded-[16px] p-4 gap-4` menu shadow)
- Title **"Suspend account?"** (Sub/Medium) + X (`Cancel` icon 24) + divider
- **Reason*** — textarea `h-[100px]` placeholder **"Please provide a reason for suspending this user."** + counter **`0/500`**
- **Suspended date** — input `h-[42px]` placeholder **"Select suspended date"** + chevron → date picker
- Footer (space-between): **"Clear all"** danger ghost (`opacity-0` default) ซ้าย · ขวา (gap-2) **"Cancel"** (ขาว) + **"Suspend"** (disabled จนกรอก reason → `#58D68D`)
- Success → Toast (336×90) + suspend email

### 5.2 Unsuspend confirm (`rounded-[16px] p-4 gap-6 backdrop-blur-[4px]`)
- Title **"Unsuspended this account?"** + X + divider
- Body: **"This user is currently suspended. Unsuspended the account will restore access to the workspace immediately."** (14 `#8C99A6`)
- ปุ่ม (h-32 rounded-6): **"Cancel"** (ขาว) + **"Unsuspended"** (`#58D68D`)

### 5.3 Email copy (ผ่าน zyra-notifications)
- Suspend: "Hi {name}," / "Your account has been temporarily suspended, and you are currently unable to access Zyra." / "Reason for suspension: {reason}" / "Suspension period: You will be able to access your account again on {date} at {time}." / closing + "Best regards, [Admin Name] Zyra Support Team"
- Unsuspend: "Your account suspension has been lifted, and you can now access Zyra again."

---

## 6. SC-UM-04 — Ban Customer

### 6.1 Ban modal (`w-[455px]` shell เดียวกับ suspend)
- Title **"Ban account?"** + X + divider
- **Reason*** — textarea `h-[100px]` placeholder **"Please provide a reason for suspending this user."** *(sic — ตาม design)* + `0/500`
- **Note (Optional)** — textarea `h-[100px]` + `0/500`
- Footer: **"Clear all"** danger ghost (opacity-0) + **"Cancel"** (ขาว) + **"Ban"** (disabled → เขียว? **ตาม design ban ใช้ปุ่มปกติ; แต่ confirm step gate ด้วย type-email**)

### 6.2 Ban confirm — type-to-confirm (`rounded-[16px] p-4 gap-6 backdrop-blur-[4px]`)
- Title **"Ban account?"** + X + divider
- Label **"Confirm ban "{email}""** → input placeholder **"Enter "{email}" to ban this user"**
- ปุ่ม (h-32 rounded-6): **"Cancel"** (ขาว) + **"Ban"** (disabled จน email ตรง)
- Success → Toast + ban email

### 6.3 Email copy
- Ban: "Your account has been banned, and you can no longer access Zyra." / "Reason for ban: {reason}" / closing
- Unban: "Your account ban has been removed, and you can now access Zyra again."
- Login-blocked screen: title **"Account access restricted"**, body **"This account is no longer able to access the workspace. Please contact support for further assistance."** + Reason row + **"Back to login"**

---

## 7. SC-UM-05 — Delete Customer Account

> Shell modal 458px · flow 3 step (warning → type-confirm → [end-user success])

### 7.1 Step 1 — Warning (`458×378`, `rounded-[16px] p-4 gap-6 backdrop-blur-[4px]`)
- Title **"Delete account?"** + X + divider
- Body (14 `#8C99A6`): **"This user is the Owner of {n} workspaces. Deleting the account will permanently remove the user and revoke access to all workspaces."**
- **Info box** (`bg-white/5 rounded-[16px] p-4 gap-2`): "For those workspaces:" + bullet (grey base + white emphasis):
  - "Owner will be **transferred to admin with the longest tenure** in the workspace."
  - "Existing members and admins will **keep their access**"
  - "The deleted user will **lose access** to all workspace data"
  - แดง Medium `#F03A3A`: **"This action cannot be undone."**
- Footer (h-32 rounded-6): **"Cancel"** (ขาว) + **"Delete"** (`#F03A3A`)

### 7.2 Step 2 — Type-to-confirm (`458×220`, error → `243`)
- Title **"Delete account?"** + divider
- Label **"Confirm delete "{email}""** → input placeholder **"Enter "{email}" to delete this user"**
- Disabled Delete จน email ตรง; **error:** border `#F03A3A` + caption **"Invalid email. Please re-enter email."**

### 7.3 End-user success (`458×480`, `rounded-[24px] p-10 gap-10` center)
- icon badge 80×80 `rounded-[8px] bg-[rgba(240,58,58,0.2)]` + `X` 56 แดง → **"Account deleted"** (20 Bold) → body (14 `#8C99A6` w-392): **"Your account has been deleted. You no longer have access to this workspace or the platform."** → reason card → ปุ่ม full-width `h-[44px] bg-[#58D68D]` **"Contact support"** + text link **"Back to login"**

---

## 8. SC-UM-06 — Reset Customer Password

### 8.1 Step 1 — Method chooser (`458×344`, `rounded-[16px] p-4 gap-6`)
- Title **"Reset password"** + divider · body **"Select how you want to reset this user's password."**
- 2 radio (gap-4, radio16 + title ขาว + desc grey):
  1. **"Send reset link"** — "A password reset email will be sent to the user, and they can set a new password themselves."
  2. **"Force reset"** — "A temporary password will be generated for the user. They'll need to use it to sign in and will be required to change their password immediately after signing in."
- Footer: **"Cancel"** (ขาว) + **"Confirm"** (disabled จนเลือก radio → `#58D68D`)

### 8.2 Step 2a — Send-link confirm (`458×206`)
- Body: **"A password reset link will be sent to {email}. The user can use the link to create a new password."**
- Footer: **"Back"** (secondary ซ้าย) + **"Cancel"** (ขาว) + **"Send"** (`#58D68D`)

### 8.3 Step 2b — Force-reset temp password (`458×306`)
- Body: **"A temporary password will be generated and sent to {email}. The user will need to use it to sign in and will be required to change their password at the next sign-in."**
- **Temp password block** (`bg-white/5 rounded-[8px] p-4`): label **"Temporary password:"** + value (14 Bold ขาว) + `Copy` icon 16
- Footer: **"Back"** + **"Cancel"** + **"Send"**
- Email: "Hi {name} ({email})." / "Your password for Zyra has been reset." / "Your temporary password is: {temp}" / "The link will be expired within 1 hours." — ↔ SC-LOGIN-05 Forgot Password
- Google-auth user → note: reset ไม่ available (login ผ่าน Google)

---

## 9. SC-UM-07 / 08 — Customer Role & Permission

> Full-page 2-card builder ใต้ tab **"Role & Permission"** (Customer side). SC-08 = state matrix ของหน้าเดียวกัน

### 9.1 Card 1 — Create role (`w-1133 rounded-[16px] p-4 gap-6`)
- Header: **"Create role & permission"** (20 Bold) + **"Create a role and set the permissions that define user access in the workspace."** · ขวา (h-42): **"Cancel"** (ขาว + `X`) + **"Save"** (disabled + `Check`)
- Row: **Role name** (placeholder "Please input role name" + counter **`0/50`**) · **Role template (Optional)** (dropdown "Select role template")
- **Description (Optional)** — textarea `h-[100px]` placeholder "Briefly describe the responsibilities of this role"

### 9.2 Card 2 — Set permission (`gap-6`, body `h-[397px] gap-4`)
- Header: **"Set permission"** + **"Define user access in the workspace."** · ขวา chip `bg-white/5 rounded-[8px] p-2`: **"All accesses :"** + count (Bold `#58D68D`)
- **Left category panel** (`w-[349px] border-white/20 rounded-[16px]`): header row (`bg-white/5 min-h-[42px]`) **"Permission"** / **"Enable all permissions and accesses"** + master **Switch** 48×24 · list (`p-2 gap-2`) category row `min-h-[42px] p-3 rounded-[8px]` icon16 + label + count badge (`bg-[#D41818] rounded-[90px]` 10 ขาว) + chevron-right; active `bg-[rgba(88,214,141,0.2)] text-[#58D68D]`
  - **Customer categories:** Workspace · Virtual office · Chat
- **Right permission table** (flex-1 `border-white/20 rounded-[16px]`): **Access** column (header 56 `bg-white/5`, row `h-[64px]`: key 14 ขาว + description 12 `#8C99A6`) + **Action** column (Switch 48×24 centered)

**Customer permission catalog (Workspace category — verbatim key → desc):**
| key | description |
|---|---|
| `workspace.read` | View workspace detail |
| `workspace.settings.read` | View workspace settings |
| `workspace.settings.edit` | Edit workspace Settings |
| `workspace.members.read` | View member in workspace |
| `workspace.members.invite` | Invite member to workspace |
| `workspace.members.remove` | Remove member in workspace |
| `workspace.members.role_assign` | Change role member in workspace |

*(Virtual office / Chat categories: keys โหลดเมื่อเลือก category — ต้อง confirm ชุดเต็มกับ Figma ตอน implement; ดู Open Questions Q2)*

### 9.3 SC-UM-08 states (behavior)
- **Enable-all:** master switch เปิดทุก permission; ถ้าไม่ครบทุก access ในหมวด master ไม่ active
- **Template select:** เลือก template → pre-fill permissions
- **Dependency check:** เปิด/ปิด permission → cascade ไป dependent (มีทั้ง "dependency on" / "off" — ต้อง confirm)
- **Default roles:** แก้/ลบไม่ได้ · **Custom role delete:** 0 user → ลบได้; >1 user → ซ่อนปุ่ม Delete
- **Row action menu** (role list): Edit (`Pencil`) / Delete (`Trash2` แดง)
- **Delete role confirm** (`458×188`): title **"Delete role?"** / body **"This role will be permanently deleted and can no longer be assigned to users."** / **"Cancel"** + **"Delete"** (`#F03A3A`)
- **Error:** สิทธิ์แก้ไขถูก revoke ระหว่างแก้ → error state; connection fail → toast (336×108)

---

## 10. SC-UM-09 — Assign Customer Role to User

### 10.1 Change role modal (`458px`, `rounded-[16px] p-4 gap-4` menu shadow)
- Title **"Change role"** + X + divider
- **Profile card** (`bg-[rgba(26,27,30,0.5)] border-white/20 rounded-[8px] p-4`): avatar40 + name (Body/Bold) + email (12 `#8C99A6`) + `X` remove
- **Workspace field (locked):** label "Workspace" → input `h-[42px]` fill white/5%, value `#7F8B97` (read-only)
- **Role field (dropdown):** label "Role" → value ขาว + chevron
- Footer (ขวา, h-42): **"Cancel"** (ขาว) + **"Confirm"** (`#58D68D`)

### 10.2 Role picker submenu (`bg-[#242B32] p-2 rounded-[16px]` menu shadow)
- Group **"Default":** Owner · Admin · Member · Guest — divider — **"Custom":** (role ที่สร้างเอง) — group header 12 `#8C99A6`, item `min-h-[42px] p-3`

### 10.3 Confirm modal (`gap-6 backdrop-blur-[4px]`)
- Title **"Change role?"** + X + divider · body (14 `#8C99A6`, copy ต่าง per case): เช่น **"This will update the user's access and permissions immediately. They'll gain access to workspace management features available to admins."**
- Footer (h-32 rounded-6, space-between): **"Back"** (secondary) ซ้าย · ขวา **"Cancel"** (ขาว) + **"Change role"** (`#58D68D`)
- **Business rules (sticky):** promote→Admin; workspace มี Owner แล้ว → ต้องย้าย owner เดิมก่อน; demote Admin

---

## 11. SC-UM-10 — List Admin Users

**Purpose:** ตาราง admin account (ต่างจาก customer: มี **Role column**)

- ใต้ sidebar **"Admin"** + tab **"Admin management"** (active) | **"Role & Permission"**
- Header: **"Admin management"** (20 Bold) + **"Manage admin accounts and track admin activity."** · ขวา (w-544 gap-2): Search placeholder **"Search for admin by username or email"** + **"Add admin"** (`h-[42px] bg-[#58D68D]` + `Plus` 16)
- Sub-header: **"Admin lists"** + **"(100)"** · ขวา 2 filter: **"Status : All"** · **"Role : All"**
- **Table columns:** Name (avatar+email) · **Role** (role tag: Super admin pink / Admin blue / Support navy / Guest grey) · Status (w-100) · Last active ✓ · Created at ✓ · Action (`MoreVertical`)
  - Deleted admin row = hashed email + generic avatar
- Footer: Export CSV (opacity-0 variant) + pagination "20 / page"
- **ต่างจาก customer list:** (1) มี Role column (admin roles) (2) CTA = "Add admin" (3) placeholder admin-specific (4) title/subtitle อ้าง admin

---

## 12. SC-UM-11 — Add New Admin User

### Modal (`w-[688px] rounded-[16px] p-4 gap-4` menu shadow)
- Title **"Add admin"** + X + divider
- Row 1 (2 col gap-4): **First name** ("Please input first name") · **Last name** ("Please input last name")
- Row 2: **Email** ("Please input email") · **Role** dropdown ("Please select role") → submenu **Super admin · Admin · Support · Viewer**
- **"Password option:"** + 2 radio: **"Set password manually"** (default) · **"Auto-generate password"**
- **Password** field (eye-off toggle) + **Password strength panel** (`bg-white/5 p-2 rounded-[8px]`): "Password strength:" + 4 rule row (dot 10 + 12 `#8C99A6`): **"At least 12 characters"** · **"Uppercase and lowercase character"** · **"One special character"** · **"One number"**
- **Confirm password** field (eye-off)
- Footer (h-42): **"Cancel"** (ขาว) + **"Add admin"** (disabled จน valid)
- Auto-generate → ซ่อน manual entry; ทั้ง 2 flow บังคับ force-change-password ครั้งแรก login
- Success → toast + invitation email ("You've been added as an Admin")

---

## 13. SC-UM-12 / 13 — Admin Role & Permission

> Full-page 2-card builder เหมือน §9 แต่ **permission catalog เป็น admin scope** และ layout header ต่าง (SC-13 = view/edit existing role มีปุ่ม Delete/Edit)

### 13.1 Card 1 (create: SC-12 / edit: SC-13)
- SC-12 header ปุ่ม: **"Cancel"** + **"Save"** (disabled) — subtitle **"Create a role and set the permissions that define admin access."**
- SC-13 header ปุ่ม (view existing): **"Delete"** (danger ghost + `Trash2`) + **"Edit"** (`#58D68D` + `Pencil`); field pre-filled (เช่น "Workspace Coordinator", counter `10/50`, description)
- Fields: **Role name** (`0/50`) · **Role template (Optional)** · **Description (Optional)** `h-[100px]`

### 13.2 Card 2 — Set permission (chip **"All accesses :"** + count)
- **Admin categories (left panel):** User management · Role management · Workspace management · Content Management · System (แต่ละ row มี count badge)

**Admin permission catalog — User management group (verbatim):**
| key | description |
|---|---|
| `admin.user.customer.read` | View customer list |
| `admin.user.customer.suspend` | Suspend customer |
| `admin.user.customer.ban` | Ban customer |
| `admin.user.customer.delete` | Delete customer |
| `admin.user.customer.reset_password` | Reset customer password |
| `admin.user.admin.read` | View admin list |
| `admin.user.admin.create` | Create new admin |
| `admin.user.admin.suspend` | Suspend admin |
| `admin.user.admin.delete` | Delete admin |

- **Role management group:** `admin.role.*` (2 access) รวม `admin.role.admin.manage` — **ซ่อนถ้าไม่ใช่ Super admin** (sticky)
- Workspace / Content / System groups: keys โหลดเมื่อเลือก — confirm ชุดเต็มกับ Figma (Open Q2)
- **ต่างจาก customer set (§9):** admin set มี `admin.user.admin.*` + Role/System/Content management; customer set มีแค่ `workspace.*` / vo / chat scope

### 13.3 SC-UM-13 behavior
- Master enable-all; per-access switch เพิ่ม count badge; select group → filter table; dependency-check confirm; delete role confirm (`458×188`); toast on save

---

## 14. SC-UM-14 — Assign Admin Role to User

### Change role modal (`458px` shell §10)
- Title **"Change role?"** + X + divider
- **Profile card** (avatar + name + email + X remove)
- **Previous role** (read-only, เช่น "Admin") · **New role** (dropdown → submenu)
- **Submenu:** **"Default":** Super admin · Admin · Support · Guest — divider — **"Custom":** Audit · Monitor customer · Workspace creator
- Footer: **"Cancel"** + **"Done"** (`#58D68D`)
- Success → toast
- **Governance (sticky):** เปลี่ยน role ของ Super admin ต้องให้ Super admin ที่มีสิทธิ์ทำ; **ดู details ตัวเอง → ไม่มีปุ่ม Action** (แก้ permission/role ตัวเองไม่ได้ทุกตำแหน่ง)

---

## 15. SC-UM-15 — Suspend / Delete Admin User

### 15.1 Suspend modal (`w-[455px]` §5.1): **"Suspend account?"** / Reason `0/500` / Suspended date / Clear all + Cancel + Suspend(disabled)
### 15.2 Reactivate: Confirmation modal (`458×188`)
### 15.3 Delete modal (`458px`, `gap-6 backdrop-blur-[4px]`)
- Title **"Delete account?"** + X + divider
- Body: **"This user will lose access immediately. Deleting this admin account will result in the following impacts:"**
- **Impact box** (`bg-white/5 rounded-[16px] p-4 gap-2`, bold lead-in + grey):
  - **Immediate Session Revocation:** "The user will be instantly disconnected from all active sessions."
  - **Anonymized History:** "The admin's name and email in the audit trail will be permanently hidden."
  - **30-Day Retention:** "The account will be soft-deleted and permanently erased after 30 days."
  - แดง Medium: **"This action cannot be undone."**
- Footer (h-32 rounded-6): **"Cancel"** (ขาว) + **"Delete"** (`#F03A3A`)
### 15.4 End-user suspend screen (`458×508`): **"Suspend account"** / "Your account has been temporarily suspended." / **"Reason for suspension"** + **"Suspension period"** ("You will be able to access your account again on {date} at {time}.")

---

## 16. SC-UM-16 — Reset Admin Password

### 16.1 Method chooser modal (`458px §8.1`): **"Reset password"** / "Select how you want to reset this user's password." / radio **"Send reset link"** · **"Force reset"** / **"Cancel"** + **"Confirm"** (disabled)
### 16.2 Force-reset temp password (`458×306`): body + **"Temporary password:"** + value + `Copy` icon
### 16.3 Reset email (Gmail): "Hi {name} ({email})." / "Your password for Zyra has been reset." / "Your temporary password is: {temp}" / "you'll be required to create a new password immediately after signing in." / "Note : The link will be expired within 1 hours."
### 16.4 Self-service Change password page (`2489:98289`, full 1440×1024)
- Left **"Account setting"** panel (`w-[340px] p-6`): back "‹ Workspace" + menu Profile / **Change password** (active) / Billing
- Right card (`w-[1052px] p-6 gap-10 rounded-[16px]`): **"Change password"** (20 Bold) + **"For your security, please verify your current password before setting a new one."**
- Form (gap-6, input block `w-[482px]`): **Current password** · **New password** + **Password strength** box (4 rule) · **Confirm new password** → ปุ่ม full-width **"Change password"** (disabled จน valid)
- Policy: ≥12 char + upper/lower + special + number; error: weak / "Unmatch password" / wrong current
- **Session rule (sticky):** Super admin ที่กำลังใช้อยู่ **ไม่ถูกดีดออก** device ปัจจุบัน แต่ revoke session device อื่นทันที

---

## 17. Motion

- Modal เปิด/ปิด: scale 0.96→1 + fade 200ms · overlay fade
- Tab switch: content fade 150ms · underline slide
- Toast: slide-in ขวา 250ms + auto-dismiss
- Permission switch toggle: instant + count badge count-up
- Progress/counter: `transition` 200ms

## 18. Icons (lucide-react — rule 12)

`UserRound`/`ShieldCheck` (sidebar) · `Search` · `Plus` · `MoreVertical` · `ArrowUpDown` (sort) · `ChevronDown`/`ChevronRight`/`ChevronLeft` · `Ban`/`CircleSlash` (suspend) · `X` (unban/close) · `Key` (reset password) · `Trash2` (delete) · `Pencil` (edit) · `Upload` (export) · `Check`/`CheckCircle` · `Copy` · `Calendar` · `Eye`/`EyeOff` · `Info` · `Circle` (radio) · `PanelLeftClose`

## 19. Assets → R2

| Asset | ใช้ที่ |
|---|---|
| Empty-state illustration (customer/admin list ว่าง) | SC-UM-01, 10 |
| Email banner "Zyra — Work to Gather" | zyra-notifications templates (suspend/ban/delete/reset/invite) |
| Anonymized/deleted-user generic avatar glyph | SC-UM-01, 10 |

## 20. Open Questions (UI) → `task-breakdown.md §Dependencies`

- **Q1:** Customer role scope — per-workspace จริงไหม? (design ล็อค Workspace field ใน assign) → กระทบ data model
- **Q2:** Permission catalog ชุดเต็มของ Virtual office / Chat (customer) และ Workspace/Content/System (admin) — design แสดงเฉพาะ group แรก
- **Q3:** Admin default roles = Super admin/Admin/Support/Guest หรือ + Viewer (SC-11 dropdown มี Viewer, SC-14 มี Guest) — ยืนยันชุดสุดท้าย
- **Q4:** Status history timeline (SC-02) — เก็บใน `user_activities` เดิม หรือ table ใหม่
- **Q5:** CSV export scope (fields, filter-aware?) — SC-01/10 footer
