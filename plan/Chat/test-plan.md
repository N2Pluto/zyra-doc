# Test Plan — Zyra Chat & Core Platform

**Version:** 1.1  
**Date:** 2026-06-29  
**Scope:** zyra-api (Go) + zyra-app (Next.js) + Chat module (SC-CHAT-01 ~ SC-CHAT-12)

**Changelog:** v1.1 (2026-06-29) — Codebase Alignment: ปรับ service boundary (email ผ่าน zyra-notifications), แก้ frontend paths (WorkspaceWSClient/authFetch/PixiGameScene), migration เริ่มที่ 52, hybrid ID scheme, ทำเครื่องหมาย infra ที่ยังต้องสร้างใหม่

### Codebase Alignment (v1.1)

- **Renderer**: virtual office ใช้ PixiJS v8 (`PixiGameScene` ใน `zyra-engine/pixi-game/scene.ts`) ไม่ใช่ Phaser — E2E ต้อง assert Pixi canvas
- **Chat route ยังไม่มี**: route VO จริงคือ `app/workspace/[id]/play/page.tsx` → `HeroVirtualOffice`; หน้า chat ใหม่ต้องสร้าง route ใหม่และพิจารณา `PUBLIC_PATHS` ใน `components/auth-guard.tsx`
- **Proximity chat overlay** ฝังใน `views/user/virtual-office/hero-virtual-office.tsx`
- **File-size limit ยังไม่ถูกกำหนดในโค้ด** (open question) — test ต้องอ้าง `CHAT_FILE_MAX_MB` (TBD, ค่าแนะนำ 25MB) ไม่ hardcode ตัวเลขที่ขัดกับ technical-design

---

## Coverage Targets

| Layer | Package / Module | Target |
|---|---|---|
| Unit (Go) | `internal/service/*` | ≥ 80% |
| Unit (TS) | `lib/auth/*.ts`, `lib/api/*.ts` | ≥ 80% |
| Unit (TS) | `lib/avatar-selection.ts`, `lib/canvas-utils.ts` | ≥ 80% |
| Component | Critical paths only | N/A |
| API | All routes in `router.go` | 100% endpoint coverage |
| E2E | Core user journeys (Playwright) | Happy path + error path |

---

## 1. Unit Tests

### 1.1 Go — zyra-api (`internal/service/*`)

Framework: `testify/assert`, `testify/require`  
DB: mock via interface — **no real PostgreSQL connection**

---

#### 1.1.1 `auth_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestLogin_ValidCredentials` | valid username + password | returns `LoginResult` with access + refresh tokens |
| `TestLogin_UserNotFound` | unknown username | returns `ErrUserNotFound` |
| `TestLogin_WrongPassword_AttemptsRemaining` | wrong password (1st attempt) | returns `InvalidCredentialsError{AttemptsRemaining: 2}` |
| `TestLogin_WrongPassword_LastAttempt` | wrong password (final attempt) | returns `InvalidCredentialsError{AttemptsRemaining: 0}`, account locked |
| `TestLogin_AccountLocked` | correct creds but account locked | returns `AccountLockedError{Until: future_time}` |
| `TestLogin_UnverifiedUser` | user with `is_verifyed = 'N'` | returns `LoginResult` with `VerifyID` set, no tokens |
| `TestLogin_GoogleAccount` | password login on Google-only account | returns appropriate error |
| `TestLogin_Refresh_ValidToken` | valid refresh token | returns new access token |
| `TestLogin_Refresh_PasswordChanged` | refresh token issued before password reset | returns `ErrPasswordChanged` |
| `TestLogin_Refresh_ExpiredToken` | expired refresh token | returns `401` error |
| `TestLoginGoogle_NoClientID` | GOOGLE_CLIENT_ID not set | returns `ErrGoogleClientNotSet` |
| `TestLoginGoogle_ValidToken` | valid Google ID token | returns `LoginResult` |
| `TestLoginGoogle_NewUser_IsNewFlag` | first-time Google login | `LoginResult` includes `is_new = true` |
| `TestNotifyLocked_EmailExists` | valid locked email | sends notification, returns nil |
| `TestNotifyLocked_EmailNotFound` | unknown email | returns nil (silent) |
| `TestLogout_ClearsRefreshToken` | valid session | refresh token revoked in DB |

**Boundary Values:**
- Password MD5 hash: input `""` → `ErrUserNotFound` or credential error (not panic)
- `AttemptsRemaining` never goes below 0
- `AccountLockedError.Until` is always in the future when returned

---

#### 1.1.2 `register_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestRegisterInitial_ValidEmail` | new valid email | returns verification record |
| `TestRegisterInitial_DuplicateEmail` | already registered email | returns `ErrDuplicate` |
| `TestRegisterInitial_GoogleAccountConflict` | email already via Google Sign-In | returns `ErrGoogleAccountConflict` |
| `TestRegisterSave_ValidData` | all fields valid | user saved with `is_verifyed = 'N'`, OTP sent |
| `TestRegisterSave_WeakPassword` | password without uppercase | returns validation error |
| `TestRegisterSave_WeakPassword_NoSpecialChar` | password without special char | returns validation error |
| `TestRegisterSave_WeakPassword_NoDigit` | password without digit | returns validation error |
| `TestRegisterSave_WeakPassword_TooShort` | password < 8 chars | returns validation error |
| `TestRegisterVerify_CorrectOTP` | correct OTP within 30min | sets `is_verifyed = 'Y'`, returns tokens |
| `TestRegisterVerify_WrongOTP_AttemptsRemaining` | wrong OTP (1st attempt) | returns `ErrOTPInvalid{AttemptsRemaining: 2}` |
| `TestRegisterVerify_WrongOTP_Locked` | wrong OTP (exhausted all attempts) | returns `ErrOTPLocked` |
| `TestRegisterVerify_ExpiredOTP` | OTP > 30 min old | returns `ErrOTPExpired` |
| `TestRegisterResend_Success` | under rate limit | generates new OTP, sends email |
| `TestRegisterResend_RateLimited` | too many resend requests | returns `ErrResendLocked{SecondsRemaining: N}` |
| `TestRegisterResend_SecondsRemaining_NonNegative` | just-expired limit | `SecondsRemaining ≥ 0` |

**Boundary Values:**
- OTP exactly at 30-min boundary → `ErrOTPExpired`
- OTP 1 second before 30 min → accepted
- `AttemptsRemaining` after lock → always 0

---

#### 1.1.3 `forgot_password_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestForgotPassword_ValidEmail` | registered email | sends reset email, returns nil |
| `TestForgotPassword_UnknownEmail` | unregistered email | returns `ErrEmailNotRegistered` |
| `TestForgotPassword_GoogleAccount` | Google-only account email | returns `ErrGoogleAccount` |
| `TestForgotPassword_RateLimited` | > `maxEmailRequestsPerHour` (3) requests/hr | returns `ErrResetRateLimited` |
| `TestGetResetInfo_ValidToken` | valid unused JWT token | returns user info |
| `TestGetResetInfo_InvalidToken` | tampered/expired token | returns `ErrResetTokenInvalid` |
| `TestGetResetInfo_UsedToken` | already-used token | returns `ErrResetTokenUsed` |
| `TestResetPassword_Success` | valid token + new password | password updated, token marked used |
| `TestResetPassword_SamePassword` | new password == current | returns `ErrSamePassword` |
| `TestResetPassword_InvalidToken` | bad token | returns `ErrResetTokenInvalid` |
| `TestResetPassword_UsedToken` | already-used token | returns `ErrResetTokenUsed` |
| `TestResetPassword_UsageRateLimited` | > `maxResetUsagePerHour` (3) uses/hr | returns `ErrResetUsageRateLimited` |

**Boundary Values:**
- Exactly 3 reset emails/hr → allowed; 4th → `ErrResetRateLimited`
- Exactly 3 reset usages/hr → allowed; 4th → `ErrResetUsageRateLimited`
- JWT `purpose` field != `"pwd_rst"` → `ErrResetTokenInvalid`

---

#### 1.1.4 `profile_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestGetProfile_Found` | valid user ID | returns profile data |
| `TestGetProfile_NotFound` | unknown user ID | returns `ErrNotFound` |
| `TestUpdateProfile_ValidFields` | name, lastname | updates record, returns updated profile |
| `TestUploadAvatar_S3Success` | valid JPEG bytes | uploads to S3, saves public URL to DB |
| `TestUploadAvatar_S3NotConfigured` | s3 == nil | returns `ErrStorageNotConfigured` |
| `TestUploadAvatar_DeletesOldAvatar` | existing S3 avatar URL | calls `s3.DeleteObject` with old key |
| `TestUploadAvatarTemp_CreatesFile` | valid image bytes | saves to `TempAvatarDir`, returns temp key |
| `TestDeleteAvatarTemp_DeletesFile` | valid temp key | removes temp file, returns nil |
| `TestDeleteAvatarTemp_InvalidKey` | path traversal `../etc/passwd` | returns error, no file operation |

---

#### 1.1.5 `workspace_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestCreateWorkspace_Valid` | valid name + template ID | creates workspace record, returns ID |
| `TestCreateWorkspace_DuplicateName` | duplicate name for same owner | returns `ErrDuplicate` |
| `TestListUserWorkspaces_Empty` | user with no workspaces | returns empty slice, nil error |
| `TestGetWorkspace_NotOwner` | different user ID | returns `ErrForbidden` or `ErrNotFound` |
| `TestDeleteWorkspace_CascadesMaps` | workspace with maps | deletes workspace + all child maps |
| `TestGetWorkspaceCapacity_UnderLimit` | 3 of 10 members | returns `{current: 3, max: 10}` |

---

#### 1.1.6 `workspace_member_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestInviteByEmails_ValidEmails` | 3 valid email addresses | creates 3 invite records, sends emails |
| `TestInviteByEmails_DuplicateEmail` | email already member | returns `ErrDuplicate` for that email |
| `TestAcceptInvite_ValidToken` | valid JWT invite token | adds user to workspace members |
| `TestAcceptInvite_ExpiredToken` | expired token | returns error |
| `TestRemoveMember_CannotRemoveOwner` | owner member ID | returns `ErrForbidden` |
| `TestLeaveWorkspace_Owner` | workspace owner tries to leave | returns error (must transfer first) |
| `TestTransferOwnership_ValidTarget` | new owner is current member | updates owner, old owner becomes member |
| `TestTransferOwnership_NonMember` | target not in workspace | returns `ErrNotFound` |
| `TestRegenerateJoinLink_Success` | valid workspace ID | generates new UUID token, returns link |
| `TestPatchMyCharacterName_Valid` | name ≤ 50 chars | updates `character_name` in members table |
| `TestPatchMyCharacterName_TooLong` | name > 50 chars | returns validation error |

---

#### 1.1.7 `workspace_presence_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestHeartbeat_NewUser` | user not in presence table | inserts record with TTL |
| `TestHeartbeat_ExistingUser` | user already present | updates `last_seen_at` |
| `TestGetOnline_ReturnsActiveUsers` | 3 online, 1 expired | returns slice of 3 |
| `TestLeave_RemovesUser` | valid user + workspace | deletes presence record |

---

#### 1.1.8 `avatar_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestListActive_ReturnsOnlyActive` | 3 active + 2 inactive avatars | returns 3 avatars |
| `TestGetDefault_Exists` | default avatar configured | returns avatar data |
| `TestGetDefault_NoneConfigured` | no default set | returns `ErrNotFound` |
| `TestCreateAvatar_Valid` | valid avatar data | creates record, returns ID |
| `TestUploadSpritesheet_S3Success` | valid PNG bytes | uploads to S3 key `static/avatar/{id}/walk.png` |
| `TestUploadThumbnail_S3Success` | valid PNG bytes | uploads to S3 key `static/avatar/{id}/thumb.png` |
| `TestDeleteAvatar_CleansS3` | avatar with S3 URLs | calls `s3.DeleteObject` for each asset |

---

#### 1.1.9 `object_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestListActive_FiltersInactive` | 5 objects, 2 inactive | returns 3 active |
| `TestListAllActive_IncludesAll` | 5 active objects | returns all 5 |
| `TestCreate_ValidObject` | valid object data | creates DB record, returns ID |
| `TestUploadPiece_S3Success` | valid PNG, objectID, pieceID | uploads to `static/object/{id}/{name}.png` |
| `TestUploadThumbnail_S3Success` | valid PNG | uploads to `static/object/{id}/thumbnail.png` |
| `TestDelete_CleansS3AndPieces` | object with pieces | deletes all pieces + thumbnail from S3 |
| `TestSaveObjectInfo_Valid` | valid JSON payload | upserts to `tb_object_information` |
| `TestGetObjectInfo_NotFound` | unknown object ID | returns `ErrNotFound` |
| `TestGetObjectUsage_CountsMaps` | object used in 3 maps | returns `{count: 3, maps: [...]}` |

---

#### 1.1.10 `map_template_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestListPublic_ReturnsActiveOnly` | 4 templates, 1 draft | returns 3 published |
| `TestListCategories_AllReturned` | 5 categories | returns all 5 |
| `TestCreate_ValidTemplate` | valid name + thumbnail | creates record |
| `TestUpdate_ToggleStatus` | template ID + status change | updates `status` field |
| `TestDelete_NotInUse` | template not referenced by workspace | deletes record |
| `TestDelete_InUse` | template used by active workspace | returns `ErrConflict` |

---

#### 1.1.11 `map_zone_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestCreateZone_ValidBounds` | valid x/y/width/height | creates zone record |
| `TestCreateZone_ZeroSize` | width=0 or height=0 | returns validation error |
| `TestUpdateZone_MovesPosition` | new x/y | updates record |
| `TestDeleteZone_Success` | valid zone ID | removes record |
| `TestListZones_ByMap` | mapID with 3 zones | returns 3 zones |

---

#### 1.1.12 `map_version_service.go`

| Test Name | Input | Expected |
|---|---|---|
| `TestSaveVersion_CreatesSnapshot` | current map state | serializes objects/zones into version record |
| `TestListVersions_Ordered` | 5 saved versions | returns newest-first |
| `TestRestoreVersion_RestoresObjects` | version ID | replaces current map objects with snapshot |
| `TestRestoreVersion_NotFound` | unknown version ID | returns `ErrNotFound` |

---

#### 1.1.13 `presence_service.go` (admin SSE)

| Test Name | Input | Expected |
|---|---|---|
| `TestHeartbeat_UpdatesOnlineStatus` | valid user context | upserts presence with TTL |
| `TestGetOnline_ReturnsCurrentUsers` | 5 online users | returns slice of 5 |
| `TestGetAll_IncludesOffline` | 5 online + 3 offline | returns all 8 with status |

---

### 1.2 TypeScript — zyra-app (Vitest)

Framework: `vitest` + `vi.mock`  
Rule: **no real `/api/*` calls** — all HTTP mocked via `vi.mock`

---

#### 1.2.1 `lib/auth/session.ts`

```ts
vi.mock("global.fetch")
```

| Test Name | Scenario | Expected |
|---|---|---|
| `persistSession — stores token and user` | `data = { status: 200, token: "tok", data: { id: "1", username: "u" } }` | `getAccessToken()` returns `"tok"`, `zyra_token` cookie set |
| `persistSession — no-op without token` | `data = { status: 200 }` (no token) | `getAccessToken()` returns null |
| `persistSession — no-op without data` | `data = { status: 200, token: "tok" }` (no data) | cookie NOT set |
| `clearSession — clears token and cookie` | after `persistSession` | `getAccessToken()` returns null, `zyra_token` cookie cleared |
| `clearSession — calls logout endpoint` | — | `fetch("/api/authen/logout", { method: "POST" })` called |
| `loginWithEmail — sends FormData` | valid payload | `fetch("/api/authen/login", { method: "POST", body: FormData })` |
| `loginWithEmail — returns status 400 on wrong creds` | mock returns `{ status: 400, message: "fail" }` | returns `{ status: 400 }` |
| `loginWithEmail — returns status 423 on locked` | mock returns `{ status: 423, locked_until: "..." }` | returns `{ status: 423, locked_until }` |
| `loginWithEmail — returns status 403 on unverified` | mock returns `{ status: 403, id: "verify_id" }` | returns `{ status: 403, id }` |
| `refreshAccessToken — updates in-memory token` | mock returns `{ status: 200, token: "new_tok" }` | `getAccessToken()` returns `"new_tok"` |
| `refreshAccessToken — returns null on failure` | mock returns `{ status: 401 }` | returns `{ token: null }` |
| `refreshAccessToken — password_changed reason` | mock returns `{ status: 401, message: "password change" }` | returns `{ token: null, reason: "password_changed" }` |
| `notifyLockedAccount — swallows errors silently` | fetch throws | no error thrown |
| `getAccessToken — restores from cookie on page refresh` | `_accessToken = null`, cookie `zyra_token=tok` | returns `"tok"` |

---

#### 1.2.2 `lib/avatar-selection.ts`

| Test Name | Scenario | Expected |
|---|---|---|
| `saveSelectedAvatar — writes to localStorage` | valid `StoredAvatar` | `localStorage.getItem("zyra_selected_avatar")` parses to same object |
| `loadSelectedAvatar — returns null when empty` | localStorage empty | returns `null` |
| `loadSelectedAvatar — returns null on corrupt JSON` | `localStorage` contains `"{"` | returns `null` (no throw) |
| `loadSelectedAvatar — returns stored avatar` | valid JSON in localStorage | returns parsed `StoredAvatar` |
| `clearSelectedAvatar — removes key` | after `saveSelectedAvatar` | `localStorage.getItem("zyra_selected_avatar")` is null |
| `saveCharacterName — trims whitespace` | `"  Alice  "` | stored as `"Alice"` |
| `loadCharacterName — returns null for blank string` | `"   "` stored | returns `null` |
| `saveSelectedAvatar — no-op on server-side (window undefined)` | SSR context | no error thrown |

---

#### 1.2.3 `lib/api/avatars.ts`

```ts
vi.mock("@/lib/api/client")
```

| Test Name | Scenario | Expected |
|---|---|---|
| `listAvatarsForUser — calls /api/user/avatars` | mock returns avatar list | returns list |
| `listAvatarsForUser — throws on 401` | mock returns 401 | throws or returns error response |
| `getDefaultAvatar — calls /api/user/avatars/default` | mock returns default | returns avatar |

---

#### 1.2.4 `lib/api/workspaces.ts`

| Test Name | Scenario | Expected |
|---|---|---|
| `listUserWorkspaces — returns workspace array` | mock 200 | returns array |
| `createUserWorkspace — posts FormData` | valid payload | `fetch` called with `POST` + `FormData` |
| `createUserWorkspace — returns ID on success` | mock `{ status: 200, data: { id: "ws1" } }` | returns `"ws1"` |
| `deleteUserWorkspace — calls DELETE endpoint` | valid ID | `fetch` called with `DELETE` |
| `getWorkspaceCapacity — returns capacity object` | mock `{ current: 3, max: 10 }` | returns `{ current: 3, max: 10 }` |

---

#### 1.2.5 `lib/api/workspace-members.ts`

| Test Name | Scenario | Expected |
|---|---|---|
| `listWorkspaceMembers — returns members` | mock 200 | returns array |
| `inviteByEmails — posts email list` | `["a@b.com", "c@d.com"]` | `fetch` called with email array |
| `leaveWorkspace — calls DELETE membership` | valid workspace ID | `DELETE /api/user/workspaces/:id/membership` |
| `transferOwnership — posts new owner ID` | valid member ID | `POST /api/user/workspaces/:id/transfer` |
| `patchCharacterName — patches name` | `"Alice"` | `PATCH /api/user/workspaces/:id/members/me/character-name` |

---

#### 1.2.6 `lib/api/profile.ts`

| Test Name | Scenario | Expected |
|---|---|---|
| `getMyProfile — calls /api/user/me` | mock 200 | returns user profile |
| `updateProfile — sends updated fields` | `{ name: "John" }` | `PUT /api/user/me` called |
| `uploadAvatar — sends FormData with file` | File object | `POST /api/user/me/avatar` called |

---

#### 1.2.7 `lib/api/virtual-office.ts`

| Test Name | Scenario | Expected |
|---|---|---|
| `getPublishedMapData — returns workspace + map + zones` | mock 200 | returns combined data object |
| `getPublishedMapData — 404 workspace` | mock 404 | throws or returns null |
| `getPublishedMapData — uses /api/user/* endpoints` | — | called URL never contains `/api/admin/` |

---

## 2. API Tests

All tests target the running `zyra-api` server (integration environment).  
Auth: pass `Authorization: Bearer <token>` except on public endpoints.

### 2.1 Health

| Endpoint | Method | Test | Status | Response |
|---|---|---|---|---|
| `/api/health` | GET | Normal check | 200 | `{ "status": "ok" }` |

---

### 2.2 Auth (`/api/authen/*`)

| Endpoint | Method | Scenario | Status | Key Response Fields |
|---|---|---|---|---|
| `/api/authen/login` | POST | Valid credentials | 200 | `token`, `data.id`, `data.username` |
| `/api/authen/login` | POST | Wrong password (remaining attempts) | 400 | `message` contains attempt count |
| `/api/authen/login` | POST | Wrong password (account locked) | 423 | `locked_until` ISO timestamp |
| `/api/authen/login` | POST | Unknown username | 400 | error message |
| `/api/authen/login` | POST | Unverified account | 403 | `id` (verifyID for OTP step) |
| `/api/authen/login` | POST | Missing username field | 400 | validation error |
| `/api/authen/login` | POST | Missing password field | 400 | validation error |
| `/api/authen/login_google` | POST | Valid Google token | 200 | `token`, `is_new` flag |
| `/api/authen/login_google` | POST | Invalid Google token | 401 | error message |
| `/api/authen/refresh` | POST | Valid refresh cookie | 200 | new `token` |
| `/api/authen/refresh` | POST | No cookie | 401 | error |
| `/api/authen/refresh` | POST | After password reset | 401 | `message` includes "password change" |
| `/api/authen/logout` | POST | Authenticated | 200 | clears refresh cookie |
| `/api/authen/logout` | POST | No session | 200 | no error (idempotent) |
| `/api/authen/notify-locked` | POST | Locked account email | 200 | `{ status: 200 }` |
| `/api/authen/notify-locked` | POST | Unknown email | 200 | no error (silent) |
| `/api/authen/forgot-password` | POST | Valid registered email | 200 | success message |
| `/api/authen/forgot-password` | POST | Google account email | 400 | `ErrGoogleAccount` message |
| `/api/authen/forgot-password` | POST | Unregistered email | 400 | `ErrEmailNotRegistered` message |
| `/api/authen/forgot-password` | POST | Rate limited (4th request/hr) | 429 | rate limit error |
| `/api/authen/reset-password/info` | GET | Valid `?token=` | 200 | user info |
| `/api/authen/reset-password/info` | GET | Invalid token | 400 | `ErrResetTokenInvalid` |
| `/api/authen/reset-password/info` | GET | Used token | 400 | `ErrResetTokenUsed` |
| `/api/authen/reset-password` | POST | Valid token + new password | 200 | success + new session token |
| `/api/authen/reset-password` | POST | Same password | 400 | `ErrSamePassword` |
| `/api/authen/reset-password` | POST | Invalid token | 400 | `ErrResetTokenInvalid` |

---

### 2.3 Register (`/api/register/*`)

| Endpoint | Method | Scenario | Status | Key Response Fields |
|---|---|---|---|---|
| `/api/register/initial` | POST | New valid email | 200 | verify session token |
| `/api/register/initial` | POST | Duplicate email | 409 | `ErrDuplicate` message |
| `/api/register/initial` | POST | Google account email | 409 | `ErrGoogleAccountConflict` |
| `/api/register/initial` | POST | Invalid email format | 400 | validation error |
| `/api/register/save` | POST | All valid fields | 200 | user created |
| `/api/register/save` | POST | Weak password (< 8 chars) | 400 | password rule error |
| `/api/register/save` | POST | Weak password (no uppercase) | 400 | password rule error |
| `/api/register/save` | POST | Weak password (no special char) | 400 | password rule error |
| `/api/register/save` | POST | Weak password (no digit) | 400 | password rule error |
| `/api/register/verify` | POST | Correct OTP | 200 | `token`, `data` (logged in) |
| `/api/register/verify` | POST | Wrong OTP | 400 | `ErrOTPInvalid`, `attempts_remaining` |
| `/api/register/verify` | POST | OTP locked (all attempts used) | 423 | `ErrOTPLocked` |
| `/api/register/verify` | POST | Expired OTP | 400 | `ErrOTPExpired` |
| `/api/register/resend` | POST | Under rate limit | 200 | new OTP sent |
| `/api/register/resend` | POST | Rate limited | 429 | `ErrResendLocked`, `seconds_remaining` |

---

### 2.4 User Profile (`/api/user/me`, UserGuard)

| Endpoint | Method | Scenario | Status | Key Response Fields |
|---|---|---|---|---|
| `/api/user/me` | GET | Authenticated | 200 | user profile object |
| `/api/user/me` | GET | No token | 401 | unauthorized |
| `/api/user/me` | GET | Expired token | 401 | unauthorized |
| `/api/user/me` | PUT | Valid update (name, lastname) | 200 | updated profile |
| `/api/user/me` | PUT | No auth | 401 | unauthorized |
| `/api/user/me/avatar` | POST | Valid JPEG, authenticated | 200 | `image_upload` URL (S3 URL) |
| `/api/user/me/avatar` | POST | File too large | 413 | error |
| `/api/user/me/avatar` | POST | Non-image file | 400 | error |
| `/api/user/me/avatar/temp` | POST | Valid image | 200 | temp key |
| `/api/user/me/avatar/temp/:key` | DELETE | Valid temp key | 200 | success |
| `/api/user/me/avatar/temp/:key` | DELETE | Path traversal key | 400 | error |

---

### 2.5 Avatars (`/api/user/avatars`, UserGuard)

| Endpoint | Method | Scenario | Status | Notes |
|---|---|---|---|---|
| `/api/user/avatars` | GET | Authenticated | 200 | only `is_active = true` avatars |
| `/api/user/avatars` | GET | Unauthenticated | 401 | — |
| `/api/user/avatars/default` | GET | Default set | 200 | single avatar |
| `/api/user/avatars/default` | GET | No default configured | 404 | — |

---

### 2.6 User Workspaces (`/api/user/workspaces/*`, UserGuard)

| Endpoint | Method | Scenario | Status | Notes |
|---|---|---|---|---|
| `/api/user/workspaces` | GET | Has workspaces | 200 | array |
| `/api/user/workspaces` | GET | No workspaces | 200 | empty array |
| `/api/user/workspaces` | POST | Valid template ID | 201 | new workspace ID |
| `/api/user/workspaces` | POST | Invalid template ID | 404 | error |
| `/api/user/workspaces/:id` | GET | Owner | 200 | workspace detail |
| `/api/user/workspaces/:id` | GET | Non-owner | 403 | forbidden |
| `/api/user/workspaces/:id` | PATCH | Valid fields | 200 | updated workspace |
| `/api/user/workspaces/:id` | DELETE | Owner | 200 | success |
| `/api/user/workspaces/:id` | DELETE | Non-owner | 403 | forbidden |
| `/api/user/workspaces/:id/thumbnail` | POST | Valid image | 200 | S3 URL |
| `/api/user/workspaces/:id/maps` | GET | Has maps | 200 | array |
| `/api/user/workspaces/:id/maps` | POST | Valid map data | 201 | new map ID |
| `/api/user/workspaces/:id/maps/:mapId` | PATCH | Valid update | 200 | updated map |
| `/api/user/workspaces/:id/maps/:mapId` | DELETE | Valid | 200 | success |
| `/api/user/workspaces/:id/history` | GET | — | 200 | version list |
| `/api/user/workspaces/:id/capacity` | GET | — | 200 | `{ current, max }` |
| `/api/user/workspaces/:id/presence` | POST | Heartbeat | 200 | success |
| `/api/user/workspaces/:id/presence` | GET | — | 200 | online members |
| `/api/user/workspaces/:id/presence` | DELETE | Leave | 200 | success |

---

### 2.7 Workspace Members (`/api/user/workspaces/:id/members`, UserGuard)

| Endpoint | Method | Scenario | Status | Notes |
|---|---|---|---|---|
| `/:id/members` | GET | Owner | 200 | member list |
| `/:id/invites` | POST | Valid emails | 200 | invite records |
| `/:id/invites` | POST | Already-member email | 409 | `ErrDuplicate` |
| `/:id/invites` | POST | Empty email list | 400 | validation error |
| `/:id/invites/:inviteId` | DELETE | Owner | 200 | cancelled |
| `/:id/invites/:inviteId/resend` | POST | Valid invite | 200 | resent |
| `/:id/members/:memberId` | DELETE | Owner removing member | 200 | success |
| `/:id/members/:memberId` | DELETE | Trying to remove owner | 403 | error |
| `/:id/members/me/character-name` | PATCH | Valid name ≤ 50 chars | 200 | updated |
| `/:id/members/me/character-name` | PATCH | Name > 50 chars | 400 | validation error |
| `/:id/join-link` | GET | — | 200 | join URL |
| `/:id/join-link` | PUT | Regenerate | 200 | new join URL |
| `/:id/membership` | DELETE | Non-owner member | 200 | left workspace |
| `/:id/membership` | DELETE | Owner (not transferred) | 400 | must transfer first |
| `/:id/transfer` | POST | Valid member target | 200 | ownership transferred |
| `/:id/transfer` | POST | Non-member target | 404 | error |
| `/join/:token` | POST | Valid token | 200 | user added to workspace |
| `/join/:token` | POST | Expired / invalid token | 400 | error |

---

### 2.8 Map Objects & Zones (`/api/user/maps/:mapId/*`, UserGuard)

| Endpoint | Method | Scenario | Status | Notes |
|---|---|---|---|---|
| `/:mapId/objects` | GET | Valid map | 200 | object array |
| `/:mapId/objects` | POST | Valid object placement | 201 | new object record |
| `/:mapId/objects/:id` | PATCH | Move position | 200 | updated x/y |
| `/:mapId/objects/:id/meta` | PATCH | Update z-index | 200 | updated meta |
| `/:mapId/objects/:id` | DELETE | Valid | 200 | removed |
| `/:mapId/zones` | GET | — | 200 | zone array |
| `/:mapId/zones` | POST | Valid zone | 201 | zone record |
| `/:mapId/zones/:zoneId` | PATCH | Update bounds | 200 | updated |
| `/:mapId/zones/:zoneId` | DELETE | — | 200 | removed |
| `/:mapId/versions` | GET | — | 200 | version list |
| `/:mapId/versions` | POST | — | 201 | snapshot saved |
| `/:mapId/versions/:versionId/restore` | POST | Valid version | 200 | map restored |
| `/:mapId/versions/:versionId/restore` | POST | Unknown version | 404 | error |

---

### 2.9 Objects (`/api/objects`, UserGuard)

| Endpoint | Method | Scenario | Status | Notes |
|---|---|---|---|---|
| `/api/objects` | GET | Authenticated | 200 | active objects only |
| `/api/objects/all` | GET | Authenticated | 200 | all active objects |
| `/api/objects` | GET | Unauthenticated | 401 | — |

---

### 2.10 Admin Endpoints (`/api/admin/*`, AdminGuard)

**Important:** All admin endpoints must return `403` when called with a non-admin token.

| Group | Key Tests |
|---|---|
| `/api/admin/objects` | CRUD + piece/thumbnail upload + object info; 403 with member token |
| `/api/admin/avatars` | CRUD + spritesheet/thumbnail/metadata/accessory upload; 403 with member token |
| `/api/admin/workspaces` | CRUD + thumbnail + lock lifecycle + version history |
| `/api/admin/maps/:mapId/*` | Object placement + zone CRUD + version snapshot/restore |
| `/api/admin/map-templates` | CRUD + thumbnail + category list/create |
| `/api/admin/presence` | heartbeat + online list + all users + SSE events stream |
| `/api/admin/workspace-templates/:id/*` | Read-only preview of maps/objects/zones |

**Cross-cutting Admin Tests:**
- Every admin endpoint returns `401` with no token
- Every admin endpoint returns `403` with a valid member (non-admin) token
- S3 upload endpoints return the public S3 URL (not a local path)
- Delete endpoints clean up related S3 objects

---

## 3. UI / End-to-End Tests (Playwright)

Tool: **Playwright**  
Browsers: Chromium (primary), Firefox, WebKit  
Viewport: 1440×1024  
Base URL: `http://localhost:3000`

### Setup

```ts
// playwright.config.ts
export default defineConfig({
  testDir: "./e2e",
  use: {
    baseURL: "http://localhost:3000",
    viewport: { width: 1440, height: 1024 },
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox",  use: { ...devices["Desktop Firefox"] } },
    { name: "webkit",   use: { ...devices["Desktop Safari"] } },
  ],
})
```

---

### 3.1 Auth Flow

#### E2E-AUTH-01: Email Login — Happy Path

```
1. Navigate to /login
2. Fill username (valid)
3. Fill password (valid)
4. Click "Sign In"
5. Assert redirect to /workspace (or dashboard)
6. Assert zyra_token cookie is set
7. Assert user name visible in UI
```

#### E2E-AUTH-02: Email Login — Wrong Password

```
1. Navigate to /login
2. Fill valid username + wrong password
3. Click "Sign In"
4. Assert error toast / message with remaining attempts count
5. Assert still on /login
6. Assert zyra_token NOT set
```

#### E2E-AUTH-03: Email Login — Account Locked

```
1. Navigate to /login with locked account credentials
2. Click "Sign In"
3. Assert 423 error message / "account locked until" displayed
4. Assert zyra_token NOT set
```

#### E2E-AUTH-04: Email Login — Unverified Account (OTP Gate)

```
1. Login with unverified account
2. Assert redirect to /verify (or OTP modal)
3. Enter correct OTP
4. Assert redirect to /workspace
5. Assert zyra_token set
```

#### E2E-AUTH-05: Register Flow

```
1. Navigate to /register
2. Fill email → Submit
3. Fill full name, username, password (valid) → Submit
4. Enter OTP from email
5. Assert redirect to /workspace
6. Assert zyra_token set
```

#### E2E-AUTH-06: Register — Duplicate Email

```
1. Navigate to /register
2. Enter already-registered email
3. Assert error displayed (duplicate email message)
4. Assert stays on register step 1
```

#### E2E-AUTH-07: Register — Weak Password Validation

```
1. Navigate to /register → fill email → save step
2. Fill password without uppercase → Assert inline error
3. Fill password without special char → Assert inline error
4. Fill password without digit → Assert inline error
5. Fill password < 8 chars → Assert inline error
6. Fill valid password → No error
```

#### E2E-AUTH-08: Forgot Password Flow

```
1. Navigate to /login → click "Forgot password"
2. Enter registered email → Submit
3. Assert success message (email sent)
4. Simulate opening reset link (with valid token)
5. Fill new password + confirm
6. Assert redirect to /login with success toast
7. Login with new password → Assert success
```

#### E2E-AUTH-09: Session Refresh on Page Reload

```
1. Login → get zyra_token cookie
2. Reload page
3. Assert still authenticated (no redirect to /login)
4. Assert user profile visible
```

#### E2E-AUTH-10: Logout

```
1. Login successfully
2. Click logout button
3. Assert redirect to /login
4. Assert zyra_token cookie cleared
5. Assert /workspace redirects back to /login
```

---

### 3.2 Workspace Flow

#### E2E-WS-01: Create Workspace — Happy Path

```
1. Login as member
2. Navigate to /workspace → click "New Workspace"
3. Select template
4. Fill workspace name → Submit
5. Assert new workspace card appears in list
6. Assert workspace name matches input
```

#### E2E-WS-02: Delete Workspace

```
1. Login as workspace owner
2. Navigate to workspace settings
3. Click "Delete Workspace" → Confirm
4. Assert workspace removed from list
```

#### E2E-WS-03: Invite Member by Email

```
1. Login as workspace owner
2. Open workspace members modal
3. Enter valid email → Send invite
4. Assert invite record shows in pending list
5. Assert invited user can see workspace after accepting
```

#### E2E-WS-04: Join by Link

```
1. Copy join link from workspace settings
2. Open in incognito (logged-in as different user)
3. Assert user added to workspace members
```

#### E2E-WS-05: Transfer Ownership

```
1. Login as workspace owner
2. Open members panel → select member → "Transfer Ownership"
3. Confirm
4. Assert new owner label updated in UI
5. Assert old owner now shows as "Member"
```

---

### 3.3 Chat Module (SC-CHAT-01 ~ SC-CHAT-12)

#### E2E-CHAT-01: Direct Message (DM) — Send and Receive

```
1. Login as User A → Enter workspace
2. User B online in same workspace
3. Open DM panel → select User B
4. Type message → Send
5. Assert message appears in DM thread (User A view)
6. Login as User B → Assert message received in DM
7. Assert unread badge cleared on open
```

#### E2E-CHAT-02: Proximity Chat — Auto-open

```
1. Login as User A → Enter virtual office map
2. User B moves near User A (proximity radius)
3. Assert proximity chat panel auto-opens
4. User A types message → Send
5. Assert message visible to User B (within range)
6. User B moves away → Assert chat panel closes/grays out
```

#### E2E-CHAT-03: Channel Message

```
1. Login → Enter workspace → Open Channels panel
2. Select existing channel (e.g. #general)
3. Type message → Send
4. Assert message appears in channel
5. All workspace members can see message
```

#### E2E-CHAT-04: Create Group Chat

```
1. Open chat panel → "New Group" button
2. Add User B and User C
3. Set group name → Create
4. Assert group appears in chat list
5. Send message in group → Assert all members receive
```

#### E2E-CHAT-05: Thread Reply

```
1. Hover over a message → Click "Reply in Thread"
2. Assert thread panel opens on right
3. Type reply → Send
4. Assert reply appears in thread, not in main channel
5. Assert thread reply count badge increments on parent message
```

#### E2E-CHAT-06: Emoji Reaction

```
1. Hover over a message → Click emoji icon
2. Assert emoji picker opens
3. Select emoji (e.g. 👍)
4. Assert reaction appears below message
5. Click same emoji again → Assert reaction removed (toggle)
6. Assert reaction count updates in real-time for other users
```

#### E2E-CHAT-07: File Upload — Success

```
1. Open chat panel → Click attachment icon
2. Select image file (≤ CHAT_FILE_MAX_MB [TBD — ดู open question; ค่าแนะนำ 25MB], valid format)
3. Assert file preview shown before send
4. Click Send
5. Assert file message appears in chat with thumbnail/link
6. Click thumbnail → Assert file opens/downloads
```

#### E2E-CHAT-08: File Upload — Error (size/type)

```
1. Open chat panel → Click attachment icon
2. Select file > CHAT_FILE_MAX_MB (TBD — ดู open question; ค่าแนะนำ 25MB) → Assert inline error "File too large"
3. Select unsupported format (e.g. .exe) → Assert inline error "File type not supported"
4. Assert no message sent
```

#### E2E-CHAT-09: Unread Message Badge

```
1. User A is away from DM panel
2. User B sends 3 messages to User A
3. Assert unread badge shows "3" on DM/channel item
4. User A opens DM → Assert badge disappears
5. Assert messages marked as read
```

#### E2E-CHAT-10: Search Messages

```
1. Open chat search (magnifier icon)
2. Type keyword that exists in past messages
3. Assert search results list appears
4. Assert result highlights keyword
5. Click result → Assert scrolls to that message in chat
6. Type non-existent keyword → Assert "No results" state
```

#### E2E-CHAT-11: Typing Indicator

```
1. User A and User B both in same DM/channel
2. User A starts typing (without sending)
3. Assert "User A is typing..." indicator visible to User B within 2 seconds
4. User A stops typing (30s idle or sends message)
5. Assert typing indicator disappears
```

#### E2E-CHAT-12: Channel Management

```
1. Login as workspace owner → Open channel settings
2. Create new channel "announcements" → Assert appears in channel list
3. Rename channel → Assert name updates
4. Add User B to channel → Assert User B sees channel
5. Remove User B from channel → Assert channel hidden for User B
6. Delete channel → Assert removed from list for all members
```

---

### 3.4 Virtual Office Flow

#### E2E-VO-01: Enter Virtual Office

```
1. Login → Navigate to /workspace/:id/play
2. Assert avatar selection screen
3. Select avatar → Enter name → Click Enter
4. Assert Pixi canvas (PixiGameScene) renders
5. Assert user avatar visible on map
6. Assert other online members appear
```

#### E2E-VO-02: Movement

```
1. Enter virtual office
2. Click on tile 5 tiles away
3. Assert avatar animates toward destination
4. Assert other users see avatar move (real-time)
```

#### E2E-VO-03: Wave Interaction

```
1. User A enters VO
2. User A right-clicks on User B's avatar → "Wave"
3. Assert wave notification toast appears for User B
4. Assert wave animation plays on User A
```

#### E2E-VO-04: Knock Feature

```
1. User B is in a private room (restricted zone)
2. User A requests knock → Assert User B sees knock notification
3. User B grants → Assert User A can enter zone
4. User B denies → Assert User A sees denial toast
```

#### E2E-VO-05: Capacity Reached

```
1. Workspace at max capacity
2. New user tries to join
3. Assert "workspace full" modal displayed
4. Assert redirect back to /workspace
```

#### E2E-VO-06: Leave Workspace

```
1. Enter virtual office
2. Click Leave Workspace (for non-owner)
3. Assert confirmation modal
4. Confirm → Assert presence removed, redirect to /workspace
```

---

### 3.5 Profile Flow

#### E2E-PROFILE-01: Update Name

```
1. Navigate to /profile
2. Edit display name → Save
3. Assert toast "Saved successfully"
4. Reload → Assert name persists
```

#### E2E-PROFILE-02: Upload Avatar

```
1. Navigate to /profile → click avatar
2. Select image → Crop → Save
3. Assert new avatar shown in profile header
4. Assert S3 URL stored (not localhost path)
```

---

### 3.6 Cross-Browser Compatibility Checks

For each critical flow, run on Chromium + Firefox + WebKit:

| Feature | Chromium | Firefox | WebKit |
|---|:---:|:---:|:---:|
| Login / Logout | ✓ | ✓ | ✓ |
| Register + OTP verify | ✓ | ✓ | ✓ |
| Create Workspace | ✓ | ✓ | ✓ |
| Chat: send DM | ✓ | ✓ | ✓ |
| Chat: file upload | ✓ | ✓ | ✓ |
| Virtual Office render | ✓ | ✓ | ✓ |
| Emoji picker | ✓ | ✓ | ✓ |
| Typing indicator | ✓ | ✓ | ✓ |

---

## 4. Test Environment

### Go Unit Tests

```bash
cd zyra-api
go test ./internal/service/... -v -cover -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html
```

### TypeScript Unit Tests

```bash
cd zyra-app
npx vitest run --coverage
# Target: coverage/index.html
```

### API Tests

```bash
# Start zyra-api with test DB
DATABASE_URL=<test_db_url> go run ./cmd/server

# Run API test suite (e.g. Hoppscotch collection or Bruno)
```

### E2E Tests

```bash
cd zyra-app
# Start both zyra-api + zyra-app
npx playwright test
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit
npx playwright show-report
```

---

## 5. Test Data Requirements

| Data | Required For |
|---|---|
| Admin user (role = admin) | Admin endpoint tests, admin E2E tests |
| Member user (role = member) | Member endpoint tests, member API separation tests |
| Locked account | E2E-AUTH-03, API lock tests |
| Unverified account (OTP pending) | E2E-AUTH-04, `/register/verify` tests |
| Workspace with 2+ members | Invite, transfer, remove member tests |
| Avatar with S3 URLs | S3 upload/delete tests |
| Object with pieces | Object CRUD + S3 cleanup tests |

---

## 6. Member API Separation Assertions

Every test that touches a member-facing page **must assert** the following:

```ts
// In Playwright E2E tests — intercept all fetch calls
page.on("request", (req) => {
  if (req.url().includes("/api/admin/")) {
    throw new Error(`Member page called admin endpoint: ${req.url()}`)
  }
})
```

In API tests: member token → `/api/admin/*` must return `403`.

---

## 7. CI Integration

```yaml
# .github/workflows/test.yml (reference)
jobs:
  unit-go:
    run: cd zyra-api && go test ./... -cover

  unit-ts:
    run: cd zyra-app && npx vitest run --coverage

  e2e:
    run: cd zyra-app && npx playwright test --project=chromium
```

**Gate before merge:** unit-go + unit-ts must pass with ≥ 80% coverage on `service/*` and `lib/*.ts`.
