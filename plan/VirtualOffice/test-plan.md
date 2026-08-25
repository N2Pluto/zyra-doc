# Zyra — Master Test Plan

**อัปเดต:** 2026-06-17  
**ClickUp (Virtual Office):** https://app.clickup.com/t/86d2wefft  
**Spec:** [zyra.doc/plan/[Module] Virtual Office/spec.md](./zyra.doc/plan/%5BModule%5D%20Virtual%20Office/spec.md)

---

## Overview

| Layer | Framework | Target Coverage |
|-------|-----------|----------------|
| Unit — Backend (Go) | `testing` + `testify` | ≥ 80% (service + util packages) |
| Unit — Frontend (TS) | `vitest` + React Testing Library | ≥ 80% (components + stores + lib) |
| API | `httptest` (Go) | All public endpoints + edge cases |
| E2E / UI | **Playwright** (TypeScript) | Critical user journeys + Virtual Office module |

---

## Test Environment

| ข้อกำหนด | รายละเอียด |
|---|---|
| Browser | Chrome latest, Firefox latest, WebKit |
| Users ที่ต้องมี | User A (Owner), User B (Admin), User C (Member), User D (ไม่มีบัญชี) |
| Workspace | Workspace ที่มี Virtual Office พร้อมใช้งาน |
| Map | Map ที่มี Private Zone, Multiple Room, Collision tiles ครบ |
| Network | WebSocket ต้องพร้อมใช้งาน |

---

## 1. Unit Tests — Backend (`zyra-api`)

### 1.1 Auth Service (`internal/service/auth_service.go`)

| Test Case | Input | Expected | Edge Case? |
|-----------|-------|----------|------------|
| Login — happy path | valid email + password | access token + refresh cookie | |
| Login — wrong password (1st–4th attempt) | bad password | `AttemptsRemaining` decrements | ✓ |
| Login — account locked (5th attempt) | bad password × 5 | `AccountLockedError` with `LockedUntil` | ✓ |
| Login — locked but time expired | bad password after lock expired | resets counter, returns `AttemptsRemaining` | ✓ |
| Login — user not found | nonexistent email | `ErrUserNotFound` | ✓ |
| Login — rememberMe=true | valid creds + rememberMe | refresh token TTL = 30d | ✓ |
| Login — rememberMe=false | valid creds | refresh token TTL = 1d | |
| Refresh — valid token | valid refresh cookie | new access token | |
| Refresh — expired token | expired refresh cookie | 401 error | ✓ |
| Refresh — tampered token | modified JWT | 401 error | ✓ |
| Refresh — revoked token | token not in DB | 401 error | ✓ |
| Logout | valid session | refresh cookie cleared, DB record deleted | |

### 1.2 Register Service (`internal/service/register_service.go`)

| Test Case | Input | Expected | Edge Case? |
|-----------|-------|----------|------------|
| Initial — new email | unique email | OTP sent, pending record created | |
| Initial — duplicate email (verified) | existing verified email | conflict error | ✓ |
| Initial — duplicate email (unverified) | existing unverified email | new OTP resent | ✓ |
| Verify — correct OTP | valid code within TTL | account activated | |
| Verify — wrong OTP | invalid code | error, attempts tracked | ✓ |
| Verify — expired OTP | code after TTL | `ErrOTPExpired` | ✓ |
| Resend — within cooldown | resend < 60s after last send | `ErrResendTooSoon` | ✓ |
| Resend — after cooldown | resend > 60s | new OTP generated | |
| Save — username taken | duplicate username | conflict error | ✓ |
| Save — weak password | password < 8 chars | validation error | ✓ |

### 1.3 Forgot Password Service (`internal/service/forgot_password_service.go`)

| Test Case | Expected | Edge Case? |
|-----------|----------|------------|
| Request reset — valid email | reset token created, email sent | |
| Request reset — unknown email | success response (no enumeration) | ✓ |
| GetResetInfo — valid token | token metadata returned | |
| GetResetInfo — expired token | `ErrTokenExpired` | ✓ |
| GetResetInfo — used token | `ErrTokenUsed` | ✓ |
| ResetPassword — valid token + strong password | password updated, token invalidated | |
| ResetPassword — token reuse | `ErrTokenUsed` | ✓ |
| ResetPassword — password same as current | `ErrSamePassword` | ✓ |

### 1.4 Workspace Service (`internal/service/workspace_service.go`)

| Test Case | Expected | Edge Case? |
|-----------|----------|------------|
| CreateWorkspace — from template | workspace cloned with maps + objects | |
| CreateWorkspace — template not found | 404 error | ✓ |
| UpdateWorkspace — owner | success | |
| UpdateWorkspace — non-owner | 403 forbidden | ✓ |
| DeleteWorkspace — with active locks | `ErrWorkspaceLocked` | ✓ |
| AcquireLock — no existing lock | lock granted | |
| AcquireLock — lock held by same user | lock refreshed | ✓ |
| AcquireLock — lock held by other user (active) | `ErrLockHeld` | ✓ |
| AcquireLock — lock held by other user (expired) | lock taken over | ✓ |
| HeartbeatLock — valid lock | TTL extended | |
| HeartbeatLock — invalid lock | `ErrLockNotOwned` | ✓ |

### 1.5 Workspace Member / Invite Service

| Test Case | Expected | Edge Case? |
|-----------|----------|------------|
| Invite — new email | pending record + email sent | |
| Invite — existing member | conflict error | ✓ |
| Invite — > 10 emails at once | validation error | ✓ |
| Resend invite — within cooldown | `ErrResendTooSoon` | ✓ |
| Accept invite — valid token | member joined | |
| Accept invite — expired token (> 7 days) | `ErrInviteExpired` | ✓ |
| Accept invite — token reuse | `ErrInviteUsed` | ✓ |
| Leave workspace — member | success, access revoked | |
| Leave workspace — owner with transfer pending | `ErrOwnerCannotLeave` | ✓ |
| Transfer ownership — to non-admin | validation error | ✓ |
| Transfer ownership — to active admin | role swapped, notification sent | |

### 1.6 Map / Zone / Object Services

| Test Case | Expected | Edge Case? |
|-----------|----------|------------|
| CreateMap — duplicate name in workspace | conflict error | ✓ |
| AddMapObject — out-of-bounds position | validation error | ✓ |
| CreateZone — empty name | validation error | ✓ |
| SaveVersion — max versions reached | oldest version pruned | ✓ |
| RestoreVersion — version not in workspace | 404 | ✓ |

### 1.7 Presence / Wave Service

| Test Case | Expected | Edge Case? |
|-----------|----------|------------|
| Heartbeat — updates last_seen | success | |
| Heartbeat TTL expired — status → offline | presence removed from online list | ✓ |
| Wave — sender DND | wave blocked | ✓ |
| Wave — receiver DND | notification not delivered | ✓ |
| Wave cooldown — same target within 10s | `ErrWaveCooldown` | ✓ |
| Private Zone knock — no occupant | `ErrZoneEmpty` | ✓ |
| Knock cooldown within 30s | `ErrKnockCooldown` | ✓ |
| Progressive cooldown after 3 denies | cooldown extends to 5 min | ✓ |
| Knock allow — barrier open 30s then auto-close | timer fires, barrier closed | ✓ |

---

## 2. Unit Tests — Frontend (`zyra-app`)

### 2.1 Auth Store / Hooks (`stores/`, `hooks/`)

| Test | Expected | Edge Case? |
|------|----------|------------|
| `useAuth` — sets token on login | access token stored in memory | |
| `useAuth` — clears state on logout | token nulled, redirect to /login | |
| Token refresh — on 401 response | auto-retry original request with new token | ✓ |
| Token refresh — refresh fails | logout triggered | ✓ |

### 2.2 Components (`components/`)

| Component | Test Case | Edge Case? |
|-----------|-----------|------------|
| `AuthGuard` | unauthenticated → redirects to /login | |
| `AuthGuard` | authenticated → renders children | |
| `AppNavbar` | renders active workspace name | |
| `AppNavbar` | logout button triggers auth clear | |
| `Avatar` | renders fallback when src missing | ✓ |
| Game Canvas | mounts without crash | |
| Game Canvas | disposes on unmount (no memory leak) | ✓ |
| Member Panel | search filters list in real-time | |
| Member Panel | collapse/expand toggle | |
| Availability Badge | renders correct color per status | |
| Wave notification | auto-dismisses after 5s | ✓ |

### 2.3 Utility / Lib (`lib/`)

| Function | Test Case | Edge Case? |
|----------|-----------|------------|
| `cn()` (className merger) | merges conflicting Tailwind classes | ✓ |
| API client `fetch` wrapper | attaches Authorization header | |
| API client `fetch` wrapper | retries once on 401 | ✓ |
| API client `fetch` wrapper | throws after second 401 | ✓ |
| Date/format helpers | locale-aware formatting | ✓ |

---

## 3. API Tests (`zyra-api`)

> Strategy: `net/http/httptest` + in-memory test DB (`testcontainers-go` หรือ `pgxmock`). Seed ข้อมูลก่อนแต่ละกลุ่ม และ teardown หลังจบ

### 3.1 Auth Endpoints

```
POST /api/authen/login
POST /api/authen/login_google
POST /api/authen/refresh
POST /api/authen/logout
POST /api/authen/forgot-password
GET  /api/authen/reset-password/info
POST /api/authen/reset-password
```

| Test | Status | Body Check |
|------|--------|------------|
| Login — valid creds | 200 | `status:200`, token present |
| Login — invalid creds (attempt 1) | 200 | `status:400`, `attemptsRemaining:4` |
| Login — locked | 200 | `status:423`, `lockedUntil` RFC3339 |
| Login — missing body fields | 400 | error message |
| Refresh — no cookie | 401 | error |
| Refresh — valid cookie | 200 | new access token |
| Logout — no session | 401 | |
| ForgotPassword — unknown email | 200 | same success (no enumeration) |
| ResetPassword — expired token | 400 | `ErrTokenExpired` |

### 3.2 Register Endpoints

```
POST /api/register/initial
POST /api/register/save
POST /api/register/verify
POST /api/register/resend
```

| Test | Status |
|------|--------|
| Initial — new email | 200 |
| Initial — taken email (verified) | 409 |
| Verify — correct OTP | 200 |
| Verify — expired OTP | 400 |
| Resend — within cooldown | 429 |
| Save — username taken | 409 |

### 3.3 User Endpoints (`/api/user/*`)

```
GET    /api/user/me
PUT    /api/user/me
POST   /api/user/me/avatar
GET    /api/user/avatars
GET    /api/user/avatars/default
GET    /api/user/templates
GET    /api/user/workspaces
```

| Test | Notes |
|------|-------|
| GET /me — no token | 401 |
| PUT /me — empty display name | 400 |
| POST /me/avatar — > 5 MB | 413 |
| POST /me/avatar — non-image MIME | 400 |
| GET /workspaces | 200, only caller's workspaces |

### 3.4 Workspace Endpoints

```
POST   /api/user/workspaces
PATCH  /api/admin/workspaces/:id
DELETE /api/admin/workspaces/:id
POST   /api/admin/workspaces/:id/lock
DELETE /api/admin/workspaces/:id/lock
POST   /api/admin/workspaces/:id/lock/heartbeat
GET    /api/admin/workspaces/:id/lock
GET    /api/admin/workspaces/:id/history
```

| Test | Notes |
|------|-------|
| POST workspaces — invalid template | 404 |
| PATCH workspace — non-owner | 403 |
| DELETE workspace — with lock | 423 |
| Acquire lock — locked by other (active) | 423 |
| Acquire lock — locked by other (expired) | 200, taken over |
| Heartbeat — not owner | 403 |

### 3.5 Workspace Member / Invite Endpoints

| Test | Notes |
|------|-------|
| Invite — existing member | 409 |
| Invite — > 10 emails | 400 |
| Accept invite — expired | 400 |
| Leave — owner without transfer | 403 |
| Transfer — to non-admin | 400 |

### 3.6 Map / Object / Zone Endpoints

| Test | Notes |
|------|-------|
| Create map — duplicate name | 409 |
| Add object — out-of-bounds x/y | 400 |
| Create zone — empty name | 400 |
| Restore version — wrong workspace | 403 |

---

## 4. E2E / UI Tests — Playwright (`zyra-app`)

> Config: `playwright.config.ts` — Chromium + Firefox + WebKit, base URL from `.env.test`

```bash
# Install
npm install -D @playwright/test
npx playwright install

# Run
npx playwright test
npx playwright test --ui
npx playwright test --reporter=html
```

### 4.1 Auth Flows

**File:** `tests/e2e/auth/login.spec.ts`

| Scenario | Assert |
|----------|--------|
| Happy path login | Redirect to home/workspace, navbar visible |
| Wrong password | Error toast: "Invalid email or password" |
| Account locked | Error + lock countdown timer visible |
| Remember me | Refresh page → still logged in |
| Logout | Redirect to /login, token cleared |

**File:** `tests/e2e/auth/register.spec.ts`

| Scenario | Assert |
|----------|--------|
| Full registration → OTP verify | Redirect to onboarding/home |
| Duplicate email | Error message shown |
| Resend OTP within cooldown | "Please wait" + countdown |
| Invalid OTP | Error: "Invalid code" |
| Expired OTP | Error: "Code expired" |

**File:** `tests/e2e/auth/forgot-password.spec.ts`

| Scenario | Assert |
|----------|--------|
| Request reset — valid email | "Check your email" screen |
| Reset with valid link | New password accepted, redirect to login |
| Reset with expired link | Error: "Link expired" |
| Reset — same as old password | Error: "Cannot reuse previous password" |

### 4.2 Profile Management

**File:** `tests/e2e/profile/profile.spec.ts`

| Scenario | Assert |
|----------|--------|
| Update display name | New name appears in navbar |
| Upload avatar — valid image | Preview shown, saved on submit |
| Upload avatar — oversized | Error toast before upload |
| Select preset avatar | Avatar updates immediately |

### 4.3 Workspace Management

**File:** `tests/e2e/workspace/workspace.spec.ts`

| Scenario | Assert |
|----------|--------|
| Create workspace from template | Workspace card appears on dashboard |
| Rename workspace | Updated name shown |
| Delete workspace | Card removed from list |
| Open builder | Builder canvas renders without error |

---

## 5. Module Tests — [Module] Virtual Office

> Playwright files ใน `tests/e2e/virtual-office/`

### TC-VO-01 · List Workspace

**File:** `tests/e2e/virtual-office/list-workspace.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 1.1 | แสดง Tab ครบ 3 tab | เข้าหน้า Workspace | เห็น All workspace / My workspace / Shared with me | High |
| 1.2 | Tab "My workspace" กรอง Owner เท่านั้น | คลิก My workspace | แสดงเฉพาะ Workspace ที่ตัวเองเป็น Owner | High |
| 1.3 | Tab "Shared with me" กรอง Member เท่านั้น | คลิก Shared with me | แสดงเฉพาะ Workspace ที่ตัวเองเป็น Member | High |
| 1.4 | Workspace card แสดง metadata ครบ | ดู card แต่ละอัน | เห็น thumbnail, ชื่อ, เวลาใช้งานล่าสุด, role badge, active count, member/capacity | High |
| 1.5 | ปุ่มตาม role ถูกต้อง (Owner) | login เป็น Owner ดู card | เห็นปุ่ม "เข้าแก้ไข", "เข้า Work Space", "คัดลอก Work Space", "Invite Member" | High |
| 1.6 | ปุ่มตาม role ถูกต้อง (Member) | login เป็น Member ดู card | เห็นปุ่ม "เข้า Work Space", "คัดลอก Work Space" เท่านั้น — ไม่เห็น "เข้าแก้ไข", "Invite Member" | High |
| 1.7 | Thumbnail generate จาก canvas | save map แล้วกลับมาดู card | thumbnail อัปเดตเป็น screenshot ล่าสุด | Medium |
| 1.8 | กด Workspace card เข้า Virtual Office ได้ | คลิก card | ไปหน้า Loading Page (TC-VO-02) | High |

### TC-VO-02 · Loading Page

**File:** `tests/e2e/virtual-office/loading.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 2.1 | Progress bar แสดงและเดินหน้า | กด "เข้า Virtual Office" | เห็น progress bar เริ่มที่ 0% เดินหน้าไป 100% | High |
| 2.2 | Phase ของ progress ถูกต้อง | สังเกต progress label | Connecting (0–30%) → Loading map (30–70%) → Loading members (70–100%) | Medium |
| 2.3 | แสดงชื่อ office บน loading screen | กด เข้า | เห็นชื่อ Workspace บน loading screen | Medium |
| 2.4 | Fade-in animation หลังโหลดเสร็จ | รอโหลดเสร็จ | map fade-in เข้ามาแทน loading screen | Medium |
| 2.5 | HUD แสดงครบหลัง load | เข้า map สำเร็จ | เห็น member panel, availability status, minimap | High |
| 2.6 | Spawn ที่ last position | ออกจาก map แล้วเข้าใหม่ | avatar spawn ที่ตำแหน่งเดิมก่อนออก | Medium |
| 2.7 | Timeout 10 วินาที แสดง retry | จำลอง slow network | หลัง 10s เห็นข้อความ "กำลังเชื่อมต่อ..." พร้อมปุ่ม retry | High |
| 2.8 | Office เต็ม — ไม่ให้เข้า | เข้า office ที่ capacity เต็ม | เห็น "Office เต็มแล้ว กรุณาลองใหม่ภายหลัง" — ไม่ join WebSocket | High |

### TC-VO-03 · Render Map

**File:** `tests/e2e/virtual-office/render-map.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 3.1 | Render ครบทุก layer | เข้า Virtual Office | เห็น background, walls, objects, decoration, avatar, UI overlay ครบ | High |
| 3.2 | Camera follow avatar | เดิน avatar | กล้องติดตาม avatar พร้อม margin จากขอบ | High |
| 3.3 | Avatar member อื่น real-time | เปิด 2 browser เข้า office เดียวกัน | avatar ของอีก user เคลื่อนที่สอดคล้องกัน real-time | High |
| 3.4 | Minimap แสดง dot ตาม status | ดู minimap | dot สีตรงกับ availability status ของแต่ละ member | Medium |
| 3.5 | Room label ปรากฏเมื่อเข้าใกล้ | เดิน avatar ใกล้ห้อง | label ชื่อห้องปรากฏเหนือประตู/ขอบห้อง | Medium |
| 3.6 | Private zone boundary มองเห็น | เดินไปใกล้ Private Zone | เห็นเส้นขอบชัดเจน (dashed/glowing) | Medium |
| 3.7 | zIndex ถูกต้อง — avatar อยู่บน object | เดิน avatar ผ่าน object | avatar แสดงทับ object ไม่หายลงใต้ | High |
| 3.8 | ไม่กระตุกบน map 100x100 | เดินทั่ว map | animation ลื่น ไม่มี lag/jitter | High |

### TC-VO-04 · Avatar Movement

**File:** `tests/e2e/virtual-office/movement.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 4.1 | กด W เดินขึ้น | กด W | avatar เดินขึ้น พร้อม walk animation ทิศ up | High |
| 4.2 | กด A/S/D ครบ 4 ทิศ | กดแต่ละ key | avatar เดินตรงทิศนั้น walk animation ถูกต้อง | High |
| 4.3 | Arrow keys ใช้งานได้ | กด Arrow keys | ทำงานเหมือน WASD | High |
| 4.4 | Idle animation หลัง 3 วินาที | หยุดกด key 3 วินาที | avatar เล่น idle animation | Medium |
| 4.5 | Click-to-move ไปยังพื้นที่ว่าง | คลิกพื้นที่ว่างบน map | avatar เดินไปถึงจุดที่คลิก | High |
| 4.6 | Click-to-move หลีก obstacle | คลิกจุดที่มี object กั้น | avatar หาเส้นทางอ้อม ไปถึงจุดหมาย | High |
| 4.7 | Member อื่นเห็น movement smooth | เปิด 2 browser เดิน | อีก user เห็น avatar เดิน smooth ไม่กระตุก | High |
| 4.8 | Speed ประมาณ 150px/s | วัด speed การเดิน | ความเร็วอยู่ในช่วงที่กำหนด | Low |

### TC-VO-05 · Collision Detection

**File:** `tests/e2e/virtual-office/collision.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 5.1 | Avatar หยุดเมื่อชน wall | เดินตรงไปหา wall | avatar หยุดที่ขอบ wall ทันที ไม่ sliding | High |
| 5.2 | Avatar ไม่ทะลุ object | เดินเข้าหา object | avatar หยุด ไม่ทะลุ | High |
| 5.3 | กด direction อื่นหลังชน wall | ชน wall แล้วกด direction อื่น | avatar เคลื่อนที่ต่อได้ทิศที่ว่าง | High |
| 5.4 | Click-to-move หลีก obstacle อัตโนมัติ | คลิกจุดหมายฝั่งตรงข้าม wall | avatar หา path อ้อม ไม่ทะลุ | High |
| 5.5 | ถ้า path ไม่มี — ไปจุดใกล้สุด | คลิกพื้นที่ที่ล้อมรอบ | avatar ไปจุดใกล้ที่สุดที่ไปได้ พร้อม visual indicator | Medium |
| 5.6 | Server reject position ที่ผิดปกติ | simulate position hacking | server ไม่ยอมรับ position ที่อยู่ใน collision tile | High |

### TC-VO-06 · Multiple Room

**File:** `tests/e2e/virtual-office/rooms.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 6.1 | Popup ชื่อห้องขึ้นเมื่อเข้า | เดิน avatar เข้าห้อง | เห็น popup ชื่อห้องเหนือ avatar | High |
| 6.2 | Popup หายหลัง 3 วินาที | เข้าห้องแล้วรอ | popup fade out หลัง 3s | Medium |
| 6.3 | Minimap highlight ห้องปัจจุบัน | อยู่ในห้อง ดู minimap | ห้องปัจจุบัน highlight บน minimap | Medium |
| 6.4 | Member Panel แสดง badge ห้อง | อยู่ในห้อง ดู Member Panel | badge ชื่อห้องแสดงข้าง member ที่อยู่ในห้อง | Medium |
| 6.5 | Proximity Chat scope เปลี่ยนเมื่อเข้าห้อง | เข้าห้อง พิมพ์ chat | message ส่งหาเฉพาะคนในห้องเดียวกัน | High |
| 6.6 | Scope กลับ open area เมื่อออกห้อง | เดินออกจากห้อง | Proximity Chat scope กลับเป็น open area | High |
| 6.7 | Transition animation เมื่อเข้า/ออก | เดินเข้าและออกห้อง | เห็น door/fade effect | Low |

### TC-VO-07 · Private Area Zone — Knock ขอเข้าห้อง

**File:** `tests/e2e/virtual-office/private-zone.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 7.1 | Visual boundary ของ Private Zone มองเห็น | เดินไปใกล้ | เห็น dashed/glowing border ชัดเจน | High |
| 7.2 | Lock icon และ zone name ปรากฏ | เดินใกล้ขอบ | เห็น lock icon + ชื่อ zone | High |
| 7.3 | Avatar หยุดที่ขอบ Private Zone | เดินตรงเข้า Private Zone | avatar ชน invisible wall ที่ขอบ | High |
| 7.4 | ปุ่ม Knock ปรากฏ | เดินชนขอบ | ปุ่ม Knock หรือ prompt แสดงขึ้น | High |
| 7.5 | กด Knock — notification ไปถึง owner ในห้อง | User C กด Knock, User A อยู่ในห้อง | User A เห็น notification พร้อม avatar + ชื่อ User C | High |
| 7.6 | Owner กด Allow — user เดินเข้าได้ | User A กด Allow | barrier เปิด User C เดินเข้า Private Zone ได้ภายใน 30s | High |
| 7.7 | Barrier กลับมาถ้าไม่เดินเข้าใน 30s | User A กด Allow แต่ User C ไม่เดิน | หลัง 30s barrier กลับมาปิด | Medium |
| 7.8 | ไม่มีใครในห้อง — แสดงข้อความ | Knock ในห้องที่ว่าง | เห็น "ไม่มีใครอยู่ในห้องนี้" | High |
| 7.9 | Knock cooldown 30 วินาที | Knock แล้ว Knock อีกทันที | ปุ่ม Knock disabled หรือแสดง countdown 30s | Medium |

### TC-VO-08 · Private Area Zone — ถูกปฏิเสธ

**File:** `tests/e2e/virtual-office/private-zone.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 8.1 | Owner กด Deny — user เห็น notification | User A กด Deny | User C เห็น toast "ขอเข้าห้องถูกปฏิเสธ" พร้อมชื่อห้อง | High |
| 8.2 | Avatar ไม่เคลื่อนที่เข้า zone | หลัง Deny | avatar User C ยังอยู่นอก Private Zone | High |
| 8.3 | ปุ่ม Knock กลับมาหลัง 30s | หลัง Deny รอ 30s | ปุ่ม Knock กลับมา enabled | Medium |
| 8.4 | Progressive cooldown 3 ครั้ง | Deny 3 ครั้งติดต่อกัน | cooldown ครั้งที่ 3 ขยายเป็น 5 นาที | Medium |

### TC-VO-09 · Availability Status บน Avatar

**File:** `tests/e2e/virtual-office/availability.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 9.1 | เปลี่ยน status เป็น Available | คลิก avatar ตัวเอง → เลือก Available | badge เปลี่ยนเป็นสีเขียว | High |
| 9.2 | เปลี่ยน status เป็น Busy | เลือก Busy | badge เปลี่ยนเป็นสีแดง | High |
| 9.3 | เปลี่ยน status เป็น Away | เลือก Away | badge เปลี่ยนเป็นสีเหลือง | High |
| 9.4 | Member อื่นเห็น badge เปลี่ยน real-time | เปลี่ยน status, ดูจาก browser อื่น | badge อัปเดต real-time | High |
| 9.5 | Minimap dot สีตาม status | เปลี่ยน status ดู minimap | dot สีตรงกับ status | Medium |
| 9.6 | Custom status พิมพ์ได้ max 30 ตัวอักษร | พิมพ์ custom status | รับได้ถึง 30 ตัว, ตัวที่ 31 ไม่รับ | Medium |
| 9.7 | Custom status รองรับ emoji | พิมพ์ emoji ใน custom status | emoji แสดงบน badge ได้ | Low |
| 9.8 | DND ไม่รับ Wave notification | ตั้ง DND, User อื่น Wave | ไม่มี wave notification ปรากฏ | High |
| 9.9 | Status เปลี่ยนเป็น offline เมื่อออก | ออกจาก office, ดูจาก browser อื่น | status เปลี่ยนเป็น offline | High |
| 9.10 | Status sync ใน Member Panel | เปลี่ยน status ดู Member Panel | status อัปเดตใน panel ด้วย | Medium |

### TC-VO-10 · Wave Notification

**File:** `tests/e2e/virtual-office/wave.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 10.1 | Context menu ปรากฏเมื่อคลิก avatar | คลิก avatar member | เห็น context menu: Wave, DM, Follow, View Profile | High |
| 10.2 | กด Wave — animation บน sender | User A คลิก Wave ไปหา User B | avatar User A เล่น wave animation | High |
| 10.3 | Receiver เห็น notification | User B ดู HUD | เห็น "[ชื่อ User A] โบกมือทักทายคุณ" มุมบนขวา | High |
| 10.4 | Notification มี avatar ของ sender | ดู notification | เห็น avatar ของ User A ใน notification | Medium |
| 10.5 | Notification หายหลัง 5 วินาที | รอ | notification auto-dismiss หลัง 5s | Medium |
| 10.6 | Wave ได้จากทุกระยะ | Wave จาก map คนละมุม | notification ส่งถึงได้ | High |
| 10.7 | Wave back — ทั้งคู่เห็น animation | User B กด Wave back | ทั้ง User A และ B เล่น wave animation | Medium |
| 10.8 | DND ไม่รับ Wave | User B ตั้ง DND, User A Wave | User B ไม่เห็น notification | High |
| 10.9 | Cooldown 10 วินาทีต่อคน | Wave หา User B ซ้ำทันที | Wave ครั้งที่ 2 ไม่ผ่าน หรือปุ่ม disabled 10s | Medium |

### TC-VO-11 · Follow

**File:** `tests/e2e/virtual-office/follow.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 11.1 | เลือก Follow จาก context menu | คลิก avatar → Follow | activate follow mode | High |
| 11.2 | Avatar ติดตาม target อัตโนมัติ | target เดินไปทิศต่างๆ | user avatar ตามทุกทิศ ห่าง 1-2 tiles | High |
| 11.3 | Target เห็น notification | ดู HUD ของ target | "[ชื่อ] กำลัง follow คุณ" แสดง 1 ครั้ง | High |
| 11.4 | Target เห็น follow indicator | ดู avatar ของ target | เห็น footprint icon เล็กๆ | Medium |
| 11.5 | กด WASD ยกเลิก follow mode | ขณะ follow กด W | follow mode ยกเลิกทันที avatar หยุดตาม | High |
| 11.6 | กด Unfollow ยกเลิก follow mode | คลิก Unfollow | follow mode ยกเลิก | High |
| 11.7 | Follow ได้ครั้งละ 1 คน | follow User B แล้วคลิก follow User C | follow User B ยกเลิก เริ่ม follow User C | High |
| 11.8 | Target ออก office — follow ยกเลิกอัตโนมัติ | target ออก office | follow mode ยกเลิกทันที | High |
| 11.9 | Block follow — ไม่ให้ใครติดตาม | ตั้ง allow_follow: false, user อื่น Follow | follow ไม่ได้ หรือ notification ถูกบล็อก | Medium |

### TC-VO-14 · Space Member Panel

**File:** `tests/e2e/virtual-office/member-panel.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| 14.1 | Panel แสดงด้านขวา HUD | เข้า Virtual Office | เห็น Member Panel ด้านขวา | High |
| 14.2 | Member แบ่งกลุ่ม Online/Away/Offline | ดู panel | เห็น 3 กลุ่มชัดเจน สีถูกต้อง | High |
| 14.3 | Online members เรียงก่อน ตามชื่อ | ดู panel | Online แสดงก่อน Away และ Offline เรียง A-Z | Medium |
| 14.4 | แสดงห้องที่ member อยู่ | member อยู่ในห้อง ดู panel | เห็นชื่อห้องใต้ชื่อ member | Medium |
| 14.5 | คลิก member — camera pan | คลิกชื่อ member ใน panel | camera pan smooth ไปยัง avatar ของ member | High |
| 14.6 | Quick action จากการคลิก member | คลิก member | เห็น DM, Wave, Follow, View Profile | High |
| 14.7 | Search member real-time | พิมพ์ชื่อใน search box | list กรองทันที ขณะพิมพ์ | High |
| 14.8 | Member count บน header | ดู panel header | เห็น "Members (online/capacity)" | Medium |
| 14.9 | Panel collapse | คลิก collapse | panel ย่อเหลือ icon แถบข้าง | Medium |
| 14.10 | Panel expand กลับมา | คลิก icon | panel กลับมาแสดงเต็ม | Medium |
| 14.11 | อัปเดต real-time เมื่อ member join | user ใหม่เข้า office | member ปรากฏในรายการทันที | High |
| 14.12 | อัปเดต real-time เมื่อ member leave | user ออก office | member หายออกจากรายการหรือเปลี่ยนเป็น Offline | High |

---

## 6. Module Tests — Invite & Workspace Membership

### TC-SB-10 · Invite Member เข้า Space ด้วย Email

**File:** `tests/e2e/workspace/invite-member.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| SB10.1 | เปิดหน้า Invite Member | Space Settings → Members → Invite Member | เห็น input email และ dropdown role | High |
| SB10.2 | ปุ่ม "ส่งคำเชิญ" disable ขณะ email ว่าง | เปิด dialog ยังไม่พิมพ์ | ปุ่มยัง disabled | High |
| SB10.3 | Invite email เดียว | กรอก email 1 อัน กด ส่ง | toast "ส่งคำเชิญไปยัง... แล้ว" | High |
| SB10.4 | Invite หลาย email พร้อมกัน | กรอก email 3 อัน comma-separated | invite ส่งครบทุก email | Medium |
| SB10.5 | Pending member ปรากฏใน list | หลังส่ง invite | เห็น badge "รอยืนยัน" สีเหลืองหน้าชื่อ | High |
| SB10.6 | Invite email ซ้ำ (member เดิม) | invite email ที่เป็น member อยู่แล้ว | แสดง error ไม่ส่ง | High |
| SB10.7 | Invite เกิน 10 email ต่อครั้ง | กรอก 11 email | error หรือ block ไม่ให้เกิน 10 | Medium |
| SB10.8 | Resend invite | คลิก resend ของ pending member | ส่ง email ใหม่ | Medium |
| SB10.9 | Cancel invite | คลิก cancel ของ pending member | pending member หายออกจาก list | Medium |
| SB10.10 | Invitation link หมดอายุ 7 วัน | ใช้ link เก่าหลัง 7 วัน | หน้า error "คำเชิญหมดอายุแล้ว" | High |
| SB10.11 | Admin invite ได้ถึง Member เท่านั้น | login เป็น Admin เปิด role dropdown | เห็น Member เท่านั้น ไม่เห็น Admin/Owner | High |

### TC-SB-11 · Invite Member ที่ไม่มีบัญชีในระบบ

**File:** `tests/e2e/workspace/invite-new-user.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| SB11.1 | คลิก link ใน email — Accept page เปิด | User D คลิก "รับคำเชิญ" | เห็นหน้า Accept Invitation พร้อมชื่อ Space + inviter | High |
| SB11.2 | Token หมดอายุ — error page | คลิก link เก่าหลัง 7 วัน | เห็น error "คำเชิญหมดอายุ" | High |
| SB11.3 | กด "สมัครสมาชิก" — email pre-fill | คลิกปุ่มสมัคร | หน้า Register เปิด email กรอกมาให้แล้ว | High |
| SB11.4 | Register + OTP สำเร็จ — auto-join Space | ทำ register จนจบ | ระบบ auto-accept invite redirect ไปหน้า Space ทันที | High |
| SB11.5 | Token หมดอายุระหว่าง Register | ใช้เวลา register นานเกิน 7 วัน | register สำเร็จ แต่ไม่ join Space แจ้ง invite หมดอายุ | Medium |
| SB11.6 | สมัครด้วย Google — auto-accept | คลิก Google OAuth บน accept page | หลัง OAuth สำเร็จ auto-join Space | Medium |
| SB11.7 | เลือก "มีบัญชีแล้ว เข้าสู่ระบบ" | คลิกปุ่ม Login | redirect ไปหน้า Login พร้อม invite token | High |

---

## 7. Module Tests — Profile / Leave Workspace

### TC-PROFILE-06 · Leave Workspace — ยืนยันและออกสำเร็จ

**File:** `tests/e2e/profile/leave-workspace.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| P06.1 | แสดงรายการ Workspace พร้อม role badge | Profile Settings → Workspace | เห็น list Workspace ทุกอัน พร้อม badge Member/Admin/Owner | High |
| P06.2 | Workspace ที่เป็น Owner แสดง "จัดการ" แทน "ออก" | ดู list | ปุ่ม "จัดการ" แทน "ออกจาก Workspace" บน Workspace ที่เป็น Owner | High |
| P06.3 | Confirmation dialog มีข้อมูลครบ | กดปุ่ม "ออกจาก Workspace" | เห็น dialog แสดงชื่อ Workspace, จำนวน member, คำเตือน | High |
| P06.4 | ต้องพิมพ์ชื่อ Workspace ถูกต้อง | พิมพ์ชื่อผิด case | ปุ่ม confirm ยัง disabled | High |
| P06.5 | พิมพ์ชื่อถูก — confirm ได้ | พิมพ์ชื่อถูกต้อง case-sensitive | ปุ่ม confirm เปิด | High |
| P06.6 | Leave สำเร็จ — redirect และ toast | กด confirm | redirect ไป Workspace selector, toast "ออกจาก... สำเร็จ" | High |
| P06.7 | Access revoke ทันที | หลัง leave ลอง navigate กลับ | ถูก redirect ออก ไม่มีสิทธิ์เข้า | High |
| P06.8 | Workspace ที่มีแค่ 1 คน — แจ้งว่าจะถูกลบ | leave Workspace ที่เป็น member คนเดียว | dialog แจ้งว่า Workspace จะถูกลบด้วย | High |

### TC-PROFILE-07 · Leave Workspace — Owner ออกไม่ได้

**File:** `tests/e2e/profile/leave-workspace.spec.ts`

| # | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| P07.1 | Owner กดปุ่ม "ออก" — modal ปรากฏ | login เป็น Owner กด "ออก" | modal แจ้ง "คุณเป็น Owner ต้อง Transfer Ownership ก่อน" | High |
| P07.2 | Modal มีปุ่ม Transfer Ownership | ดู modal | เห็นปุ่ม "โอนความเป็นเจ้าของ" และ "ยกเลิก" | High |
| P07.3 | กด "ยกเลิก" — modal ปิด ไม่มีอะไรเปลี่ยน | คลิก ยกเลิก | modal ปิด user ยังเป็น Owner | High |
| P07.4 | กด Transfer Ownership — เห็น list Admin | คลิกปุ่ม Transfer | เห็น list member ที่เป็น Admin พร้อม search | High |
| P07.5 | เลือก Admin ใหม่ — confirm dialog | เลือก Admin คนใหม่ | เห็น modal ยืนยันอีกครั้ง | High |
| P07.6 | Transfer สำเร็จ — role เปลี่ยน | กด confirm transfer | badge role เปลี่ยนจาก Owner → Admin ทันที | High |
| P07.7 | New owner ได้รับ notification | ดู email + in-app ของ new owner | ได้รับ notification ทั้ง email และ in-app | High |
| P07.8 | หลัง transfer — ออก Workspace ได้แล้ว | หลัง transfer กด "ออกจาก Workspace" | flow ปกติ ทำได้เหมือน TC-PROFILE-06 | High |
| P07.9 | Server block leave ถ้า Owner ยังไม่ transfer | simulate API call leave โดยตรง | server return error 403 | High |
| P07.10 | Transfer ได้เฉพาะ active Admin | ดู list ใน transfer page | เห็นเฉพาะ Admin ที่ active (ไม่เห็น Member หรือ Inactive) | High |

---

## 8. Coverage Targets & CI Gates

```
Unit (Backend)  : go test ./... -coverprofile=coverage.out  → ≥ 80%
Unit (Frontend) : npx vitest run --coverage                 → ≥ 80%
API             : all test cases pass                       → 100%
E2E             : no failures on Chromium (smoke)           → 100%
```

### Recommended CI Pipeline (GitHub Actions)

```yaml
jobs:
  unit-backend:
    runs-on: ubuntu-latest
    steps:
      - run: go test ./... -race -coverprofile=coverage.out
      - run: go tool cover -func=coverage.out | grep total | awk '{if ($3+0 < 80) exit 1}'

  unit-frontend:
    runs-on: ubuntu-latest
    steps:
      - run: npm ci && npx vitest run --coverage

  api-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
    steps:
      - run: go test ./internal/handler/... -tags=integration

  e2e:
    runs-on: ubuntu-latest
    steps:
      - run: npm ci && npx playwright install --with-deps
      - run: npx playwright test --reporter=html
```

---

## 9. Test Data & Fixtures

| Resource | Strategy |
|----------|----------|
| DB (unit/API) | `testcontainers-go` หรือ pgxmock; seed via `migrations/` |
| Users | Factory helpers: `testutil.NewUser()`, `testutil.NewAdminUser()` |
| Workspaces | `testutil.NewWorkspace(ownerID)` with 1 default map + private zone |
| E2E users | `.env.test` — `TEST_USER_EMAIL`, `TEST_ADMIN_EMAIL`, `TEST_MEMBER_EMAIL` (pre-seeded) |
| File uploads | `testdata/` — `valid-avatar.png` (< 2 MB), `oversized.png` (> 5 MB), `bad.pdf` |

---

## 10. Edge Cases Checklist

- [ ] SQL injection in all string inputs (username, workspace name, zone name, custom status)
- [ ] XSS in display name / workspace description / custom status fields
- [ ] JWT with `alg: none` header rejected
- [ ] Concurrent lock acquire race (two requests at exactly the same time)
- [ ] File upload — zero-byte file
- [ ] File upload — valid MIME but corrupt content
- [ ] Pagination — `page=0`, `page=-1`, `limit=9999`
- [ ] Long strings (> DB column length) — display name, workspace name, custom status
- [ ] Workspace with 0 maps (edge display state)
- [ ] Version history — restoring the currently active version
- [ ] SSE / Presence — reconnect after network drop
- [ ] WebSocket — reconnect after disconnect mid-session
- [ ] Timezone — `lockedUntil` rendered in user's local timezone
- [ ] Google OAuth — token exchange failure (provider error)
- [ ] Avatar upload — animated GIF handling
- [ ] Private Zone — knock when zone has no name
- [ ] Wave to self (same user, different session)
- [ ] Follow target who has DND enabled
- [ ] Transfer ownership to member who has already left workspace
- [ ] Invite link used after inviter was removed from workspace
