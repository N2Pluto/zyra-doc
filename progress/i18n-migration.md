# i18n Migration (next-intl) — Progress

**อัปเดตล่าสุด:** 2026-07-16 (workspace-preview เช็คแล้ว — ไม่ต้องทำอะไรเพิ่ม, ปิด batch สุดท้ายในลิสต์ "ยังไม่ได้เริ่มเลย" — i18n migration เสร็จสมบูรณ์ 100% ของ scope ที่รู้จักตอนนี้)
**Library:** next-intl (cookie-based, ไม่เปลี่ยน URL) — locale เก็บใน cookie `zyra_locale`
**ภาษา:** EN + TH (โครงสร้างเปิดให้เพิ่มภาษาอื่นได้ที่ `i18n/config.ts`)
**Total keys (ตรวจสด ณ 2026-07-16):** รัน `python3 -c "import json; print(sum(len(v) for v in json.load(open('messages/en.json')).values()))"` เพื่อเช็คตัวเลขจริงเสมอ — อย่าเชื่อเลขที่บันทึกไว้ในเอกสารนี้ เพราะมีงานคู่ขนาน (user + session นี้) แก้ไฟล์เดียวกันได้ตลอดเวลา
**Thai font:** เปลี่ยนเป็น Noto Sans Thai แล้ว (2026-07-16) — ดูหัวข้อ "Thai Font" ด้านล่าง

> ⚠️ **บทเรียนสำคัญ:** เอกสารเวอร์ชันก่อนหน้านี้ (ก่อน 2026-07-16) ระบุผิดว่า Navbar/Login/Signup/Verify/ForgotPassword/ResetPassword/Home/Profile/Onboarding/Chat "เสร็จแล้ว" — ความจริงคือมีแค่ keys ใน `messages/en.json`/`th.json` (scaffolded) แต่**ไม่มี `useTranslations()` เรียกใช้ในโค้ดเลยสักจุดเดียว** ตรวจสอบด้วย `grep -rl "useTranslations" <dir>` แล้วพบว่า 0/ไฟล์ทั้งหมดในทุก feature เหล่านี้ ต่อไปนี้เวลาจะ mark ว่า namespace ไหน "เสร็จ" ต้อง verify ด้วย grep จริงเสมอ อย่าเชื่อแค่ว่ามี key อยู่ใน JSON

---

## ✅ Infrastructure (เสร็จแล้ว, committed)

| งาน                                                  | ไฟล์                                                                                                                                                                           |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ติดตั้ง next-intl + verify Next 16 compat            | `zyra-app/package.json`                                                                                                                                                        |
| i18n config + locale server actions + request config | `i18n/config.ts`, `i18n/locale.ts`, `i18n/request.ts`                                                                                                                          |
| next.config.ts plugin + layout locale/provider       | `next.config.ts`, `app/layout.tsx`                                                                                                                                             |
| LanguageSwitcher component (navbar)                  | `components/language-switcher.tsx` ใช้ `useLocale()` เพื่อสลับภาษาได้ — แต่ `components/app-navbar.tsx` เองไม่มี `useTranslations()` (ดูหัวข้อ "🔴 Scaffolded แต่ไม่ได้ wire") |
| AGENTS.md convention doc                             | `AGENTS.md` — "UI copy" line updated 2026-07-15 to document the real next-intl convention (ก่อนหน้านี้เขียนขัดกันว่า "UI copy = English", แก้แล้ว)                             |

**หมายเหตุ:** ระหว่าง session ที่ทำ VO migration เกิด `git revert` ของ next-intl plugin/provider wiring ใน `next.config.ts` + `app/layout.tsx` ตามด้วย re-add (ดู commit `6ec8d15` → `764bea7`) — ตอนนี้ยืนยันแล้วว่า wiring อยู่ครบและใช้งานได้จริงบน HEAD ปัจจุบัน

---

## ✅ Features ที่ migrate ครบแล้วจริง (verified: มี `useTranslations`/`getTranslations` เรียกใช้จริงในโค้ด)

| Feature                                | Namespace                                                                                                                                                        | Keys  | หมายเหตุ                                                                                                                                                                                               |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Change password                        | `ChangePassword`                                                                                                                                                 | 26    | `hero-change-password.tsx` ใช้ `useTranslations("ChangePassword")` — verified                                                                                                                          |
| Navbar                                 | `Navbar`                                                                                                                                                         | 3     | `components/app-navbar.tsx` — wire แล้วระหว่างแก้ bug ปุ่มเปลี่ยนภาษา (ดูหัวข้อ bug ด้านล่าง); key `language` ยังไม่มีจุดใช้จริง (orphaned scaffold key, ไม่กระทบอะไร)                                 |
| **Virtual Office (ทั้งฟีเจอร์)**       | `VirtualOffice`                                                                                                                                                  | 555   | 45/53 ไฟล์ wire จริง (+1 key `earlier` เพิ่มระหว่างแก้ chat-utils.ts cross-file) — ดูรายละเอียดด้านล่าง                                                                                                |
| **Admin Dashboard (ทั้ง 7 namespace)** | `AdminShared`, `AdminWorkspaceManagement`, `AdminUserManagement`, `AdminAvatarManagement`, `AdminMapManagement`, `AdminObjectManagement`, `AdminWorkspaceEditor` | 1,215 | ดูหัวข้อ "Admin Dashboard" ด้านล่าง                                                                                                                                                                    |
| **Chat (ทั้งฟีเจอร์)**                 | `Chat`                                                                                                                                                           | 187   | 25/29 ไฟล์ wire จริง — ดูหัวข้อ "Chat" ด้านล่าง                                                                                                                                                        |
| **Home / workspace list**              | `Home`, `JoinWorkspace`, `CopyWorkspace`, `CreateWorkspace`, `WelcomeSpace` (ใหม่)                                                                               | 138   | ดูหัวข้อ "Home" ด้านล่าง                                                                                                                                                                               |
| **Login**                              | `Login`                                                                                                                                                          | 36    | 4/4 ไฟล์ wire จริง, **scaffold แม่น 100%, 0 key ใหม่** — verified ผ่าน browser จริง (screenshot ภาษาไทยเต็มหน้า); มี `LanguageSwitcher` มุมขวาบนแล้ว                                                   |
| **Signup**                             | `Signup`                                                                                                                                                         | 43    | 3/3 ไฟล์ (เว้น `signup-form-field.tsx` ที่เป็น prop-driven ล้วน) wire จริง, **scaffold แม่น 100%, 0 key ใหม่** — verified ผ่าน browser จริง; มี `LanguageSwitcher` มุมขวาบนแล้ว                        |
| **Verify (OTP)**                       | `Verify`                                                                                                                                                         | 25    | wire จริง, **scaffold แม่น 100%, 0 key ใหม่** — verified ผ่าน browser จริง; `SuccessCard` sub-component reuse key เดียวกับหน้าหลัก ไม่ได้ไปยืมจาก `Signup`                                             |
| **Forgot password**                    | `ForgotPassword`                                                                                                                                                 | 19    | wire จริง, **scaffold แม่น 100%, 0 key ใหม่** — verified ผ่าน browser จริง                                                                                                                             |
| **Reset password**                     | `ResetPassword`                                                                                                                                                  | 36    | wire จริง, **scaffold แม่น 100%, 0 key ใหม่** — verified ผ่าน browser จริง (ทดสอบ state "invalid link" เพราะไม่มี backend ออก token จริงได้)                                                           |
| **Profile**                            | `Profile`                                                                                                                                                        | 43    | 7/7 ไฟล์ wire จริง — scaffold แม่น 92% (36/40 exact match), 3 key ใหม่จาก `toastReason()` cross-file fix; verify ผ่าน browser ไม่ได้ (ต้อง auth) แต่ verify ระดับโค้ดครบ                               |
| **ImageCropper**                       | `ImageCropper`                                                                                                                                                   | 12    | อยู่ใน `upload-avatar-modal.tsx` (ไม่มีไฟล์ image-cropper แยก) — **scaffold แม่น 100%, 0 key ใหม่**                                                                                                    |
| **Onboarding**                         | `Onboarding`                                                                                                                                                     | 33    | 4/4 ไฟล์ + `lib/onboarding.ts` wire จริง — **scaffold แม่น 100%, 0 key ใหม่**                                                                                                                          |
| **Help Center**                        | `HelpCenter`                                                                                                                                                     | 137   | 4/4 ไฟล์ wire จริง — namespace ใหม่ทั้งหมด (ไม่เคย scaffold มาก่อน), verified ผ่าน `__tests__/help-center.test.ts` + `__tests__/support.test.ts` (25/25 ผ่าน) — ดูหัวข้อ "HelpCenter + Legal" ด้านล่าง |
| **Legal**                              | `Legal`                                                                                                                                                          | 70    | 2/2 ไฟล์ wire จริง — namespace ใหม่ทั้งหมด, verified ผ่าน browser จริงทั้ง EN/TH ที่ route `/legal` (public page)                                                                                      |
| **Workspace Enter**                    | `WorkspaceEnter`                                                                                                                                                 | 21    | 2/2 ไฟล์ wire จริง — namespace ใหม่ทั้งหมด (`hero-workspace-enter.tsx` + `change-character-modal.tsx`) — ดูหัวข้อ "WorkspaceEnter + WorkspaceLoading" ด้านล่าง                                         |
| **Workspace Loading**                  | `WorkspaceLoading`                                                                                                                                               | 19    | 1/1 ไฟล์ wire จริง — namespace ใหม่ทั้งหมด, รวม refactor error-throw เป็น fixed code (pattern เดียวกับ audit sweep) — ดูหัวข้อเดียวกัน                                                                 |
| **Feature Tour**                       | `FeatureTour`                                                                                                                                                    | 5     | 1/1 ไฟล์ wire จริง — namespace ใหม่ (เฉพาะ UI chrome; เนื้อหาทัวร์เองเป็น data-authored content, `ACTIVE_TOURS` ว่างอยู่ตอนนี้) — ดูหัวข้อ "FeatureTour + AcceptInvite" ด้านล่าง                       |
| **Accept Invite**                      | `AcceptInvite`                                                                                                                                                   | 28    | 1/1 ไฟล์ wire จริง — namespace ใหม่ทั้งหมด, verified ผ่าน browser จริงทั้ง EN/TH ที่ route `/join/[token]` — ดูหัวข้อเดียวกัน                                                                          |

**รวม keys ที่ wire จริงแล้ว: 2,668 / 2,668 (100% ของ key ที่มีอยู่ตอนนี้ — ทุก namespace ที่เคย scaffold ไว้ wire ครบหมดแล้ว; ดูหัวข้อ "ยังไม่ได้เริ่มเลย" สำหรับ feature ที่ยังไม่มี namespace)**

### ✅ Verified ผ่าน browser จริง (2026-07-16)

Login, Signup, Verify, Forgot password, Reset password — **ทุกหน้าเป็น public page ทดสอบผ่าน browser ได้เต็มรูปแบบใน sandbox นี้** (ไม่ต้องพึ่ง backend) — ตั้ง cookie `zyra_locale=th` แล้ว screenshot ยืนยันว่าทุกข้อความขึ้นภาษาไทยถูกต้องพร้อม font Noto Sans Thai ครบทุกหน้า (Reset password ทดสอบผ่าน state "ลิงก์ไม่ถูกต้อง" เพราะไม่มี backend ออก token จริงให้ทดสอบ flow ปกติได้ แต่ยืนยันว่า `invalidTitle`/`invalidBody`/`requestNewLink`/`backToLogin` ขึ้นถูกหมด)

**Home, Profile, Onboarding ยังตรวจสอบผ่าน browser ไม่ได้** เพราะ sandbox นี้ไม่มี `zyra-api` (backend) รัน จึง auth ไม่ผ่านและ redirect กลับ `/login` เสมอ (route `/setting`, onboarding modal ไม่อยู่ใน `PUBLIC_PATHS`) — ยืนยันได้แค่ระดับโค้ด: `grep -rl "useTranslations"` เจอครบ 7/7 ไฟล์ Profile, 4/4 ไฟล์ Onboarding

### ✅ Profile + ImageCropper + Onboarding — เสร็จและ wire แล้ว (2026-07-16, uncommitted)

- **Profile** (7 ไฟล์: `hero-profile.tsx`, `profile-form.tsx`, `upload-avatar-modal.tsx`, `profile-sidebar.tsx`, `profile-toast.tsx`, `delete-avatar-modal.tsx`, `confirm-modal.tsx`) — reuse 36/40 key เดิม + 3 key ใหม่
- **ImageCropper** — ฟีเจอร์ crop/rotate/zoom รูปภาพอยู่ **ใน** `upload-avatar-modal.tsx` เอง ไม่มีไฟล์ `image-cropper.tsx` แยกต่างหาก (ชื่อ namespace ทำให้เข้าใจผิดได้ว่าต้องมีไฟล์ชื่อนี้) — reuse ครบ 12/12
- **Onboarding** (`onboarding-modal.tsx` + 3 modal ย่อย + `lib/onboarding.ts`) — reuse ครบ 33/33, 0 key ใหม่

**Cross-file fix ที่เจอ (เจอ pattern เดิมซ้ำอีกรอบ — "plain `.ts` util คืนค่า hardcoded string ที่ component อื่น consume"):**

1. **`lib/api/profile.ts`'s `toastReason(msg)`** — เดิม return ประโยคภาษาอังกฤษตรงๆ ("a network error"/"a server error") ที่ interpolate เข้า `Profile.toastErrorBody` ("Due to {reason}...") — แก้ให้ return **key name** แทน (`reasonNetworkError`/`reasonServerError`/`reasonUnknownError` — เพิ่มใหม่ 3 key นี้ใน `Profile` namespace) แล้ว `profile-toast.tsx` (เจ้าของไฟล์นี้) resolve เองผ่าน `t(toastReason(msg))` — ยืนยันแล้วว่ามีแค่ 1 จุด import (`profile-toast.tsx`) ไม่กระทบไฟล์อื่น
2. **`lib/onboarding.ts`'s `ONBOARDING_TABS`/`ONBOARDING_PAGES`** — `label`/`title`/`body` field เปลี่ยนเป็น `labelKey`/`titleKey`/`bodyKey` ตาม pattern เดิม, `resolveTitle()` เปลี่ยน signature ให้รับ `t` เข้ามาแทนการ string-replace เอง — กระทบ `__tests__/onboarding.test.ts` ด้วย (ต้องอัปเดต test ให้ตรงกับ signature ใหม่, ยืนยันว่า 20 test ผ่านหมดหลังแก้)

**Orphaned key ที่พบ (ไม่กระทบอะไร):** `Profile.toastCharacterUpdated` ("Character updated") — ไม่มีจุดใช้งานจริงในโค้ดปัจจุบันเลย (ค้นทั้ง repo ไม่เจอ) น่าจะเป็น scaffold ที่เตรียมไว้สำหรับฟีเจอร์ "เปลี่ยนตัวละคร" ที่ยังไม่ได้ทำ toast แจ้งเตือนจริง — ปล่อยไว้ตามเดิม

### 🎨 LanguageSwitcher — bug fix เพิ่มเติม (2026-07-16)

- **เพิ่มปุ่มเปลี่ยนภาษาที่มุมขวาบนของหน้า Login/Signup** (`views/login/hero-login.tsx`, `views/signup/hero-signup.tsx`) — ก่อนหน้านี้ `LanguageSwitcher` มีแค่ใน `AppNavbar` (หน้าที่ login แล้วเท่านั้น) ผู้ใช้ที่ยังไม่ login เปลี่ยนภาษาไม่ได้เลย
- **แก้ dropdown background โปร่งใส** — user รายงานว่า dropdown ของ `LanguageSwitcher` มองไม่เห็นพื้นหลัง (เห็นเป็นกระจกฝ้า) — ตรวจสอบด้วย computed style ผ่าน browser จริงแล้วพบว่า `background-color` เป็น `rgb(36,43,50)` ทึบปกติ ไม่ transparent เลยในทุก viewport/ทุกครั้งที่ทดสอบ — **ทฤษฎีที่เป็นไปได้มากที่สุด: screenshot จับภาพระหว่าง fade-in/zoom-in entrance animation (100ms) พอดี** ทำให้เห็นเป็นภาพโปร่งแสงชั่วขณะ ไม่ใช่ bug ถาวร — แก้เชิงป้องกันไว้แล้วโดยเพิ่ม `!bg-[#242B32]` (important modifier) + `backdrop-blur-none` ใน `components/language-switcher.tsx` เพื่อตัดโอกาส CSS specificity/merge-order ใดๆ ที่อาจทำให้ `bg-popover` (ตัวแปร CSS ของ shadcn ที่ component นี้สืบทอดมา) แอบชนะได้ — **ควรขอให้ user ยืนยันอีกครั้งว่าเจอปัญหาซ้ำไหมหลัง fix นี้**

---

## ✅ Home / workspace list — เสร็จและ wire แล้ว (2026-07-16, uncommitted)

⚠️ **แก้ความเข้าใจผิดจากรอบก่อน:** เอกสารเดิมชี้ไปที่ `views/home/hero-home.tsx` (163 บรรทัด) ว่าเป็น "Home page" — **ผิด** ไฟล์นั้น**เป็น dead code ไม่มี route ไหน import เลย** หน้า Home จริง (route `/`, `app/page.tsx`) render `HeroUserWorkspace` จาก **`views/user/workspace/hero-user-workspace.tsx`** (1,350 บรรทัด) ต่างหาก — ก่อน mark ว่าไฟล์ไหน "คือหน้า X" ต้องเช็ค `app/**/page.tsx` ว่า import อะไรจริงๆ อย่าเดาจากชื่อไฟล์/โฟลเดอร์

- **`hero-user-workspace.tsx`** (Home namespace) + **`workspace-constants.ts`** (labelKey pattern สำหรับ `TAB_META`/`SORT_LABEL`) — wire แล้ว, 49/50 key เดิม reuse ตรงเป๊ะ + 1 key ใหม่ (`yearlyDiscount`: "-20%")
- **`create-workspace-modal.tsx`** (CreateWorkspace namespace, 763 บรรทัด) — reuse ครบ 31/31 key เดิม + 6 key ใหม่ (bare capacity numbers: `capacity10`...`capacity1000`)
- **`copy-workspace-modal.tsx`** (CopyWorkspace namespace) — reuse ครบ 22/22 key เดิม, ไม่มี key ใหม่
- **`join-workspace-modal.tsx`** (`views/user/workspace/components/`, JoinWorkspace namespace) — reuse 10/10 เดิม + 2 key ใหม่ (`codePlaceholder`/`codeFormat` สำหรับตัวอย่างรูปแบบโค้ด)
- **`hero-welcome-space.tsx`** — **namespace ใหม่ `WelcomeSpace`** (16 keys) แทนที่จะ reuse `CreateWorkspace` เพราะเนื้อหาต่างกันจริง (หน้านี้คือ pre-join camera/mic preview + ตั้งชื่อตัวละคร ไม่ใช่หน้า "workspace is ready" หลังสร้างเสร็จ) — เป็นตัวอย่างที่ดีว่า scaffold namespace เดิมไม่ใช่ทุกไฟล์จะ fit เสมอไป ต้อง verify เนื้อหาจริงก่อน reuse

**Dead code ที่เจอ (ไม่แตะ เพราะนอก scope, ไม่ควรเสียเวลาแปลโค้ดที่ไม่ถูก render):**

- `views/home/hero-home.tsx` (163 บรรทัด) — ไม่มี route ไหน import
- `views/user/space-builder/components/workspace-preview-modal.tsx` (33 บรรทัด) — ไม่มีไฟล์ไหน import เช่นกัน

**รวม Home batch: 138 keys จริง** (51+37+12+22+16 หัก key ซ้ำระหว่าง namespace ไม่มีเพราะแยก namespace ชัดเจน) ทุกไฟล์ verify ครบ: tsc/eslint/prettier/grep sweep/key-sync/dynamic-lookup cross-check

---

## ✅ Chat — เสร็จและ wire แล้ว (2026-07-16, uncommitted)

- **25/29 ไฟล์** ใน `views/chat/` เรียก `useTranslations("Chat")` จริง — อีก 4 ไฟล์ไม่ต้องการ: `use-chat-search.ts`/`use-typing-emitter.ts` (hook, ไม่มี text), `chat-avatar.tsx` (icon/initials ล้วน, ไม่มี text), `emoji-data.ts` (plain `.ts`, ใช้ labelKey pattern แต่ตัวเองไม่เรียก hook)
- Namespace `Chat` มี **187 keys** (185 keys เดิมที่ scaffold ไว้ + 2 keys ใหม่: `threadReplyCount`, `dateFormatPlaceholder`)
- **Scaffold เดิมแม่นมาก** — เกือบทุก string ที่เจอในโค้ดจริงตรงกับ key ที่ scaffold ไว้แบบ exact match (ยืนยันว่า scaffold รอบก่อนอ่านโค้ดจริงมาทำ ก็แค่ไม่เคย wire) มีแค่ 2 key ใหม่ที่ต้องเพิ่ม

### ปัญหา cross-feature ที่เจอ + แก้แล้ว

Chat มี shared util ไฟล์ที่ไม่ใช่ component (`chat-utils.ts`, `attachment-utils.tsx`) ซึ่งถูก reuse ข้าม feature — ต้องแก้ให้รับ `t` เป็น parameter แทนการ hardcode:

1. **`chat-utils.ts`** — `formatDayDivider`/`formatRelativeTime`/`groupFallbackName`/`conversationTitle`/`lastMessagePreview` เปลี่ยนให้รับ `t: ReturnType<typeof useTranslations>` เป็น parameter แทน hardcode string — ตาม caller 5 ไฟล์ใน `views/chat/` ให้ผ่าน `t` (namespace Chat) ของตัวเอง
2. **`chat-utils.ts` ถูก reuse ข้าม feature** — `views/user/virtual-office/components/vo-notification-panel.tsx` (namespace `VirtualOffice`) import `formatDayDivider`/`formatRelativeTime` มาใช้ด้วย! เพราะ `t` ต้อง resolve key จาก namespace `Chat` เท่านั้น (`today`/`yesterday`/`now` อยู่ใน Chat ไม่ใช่ VirtualOffice) จึงต้องเพิ่ม `const tChat = useTranslations("Chat")` แยกต่างหากในไฟล์นี้ ไว้ผ่านเข้า `chat-utils.ts` functions โดยเฉพาะ (คนละตัวกับ `t` ของ VirtualOffice เอง) — พบ bug เดิมด้วยว่า `"Earlier"` fallback hardcode ไว้ไม่เคยแปล เลยเพิ่ม key `earlier` ใหม่ให้ VirtualOffice namespace ไปด้วย
3. **`attachment-utils.tsx`** — `validateFile`/`fileErrorLabel` เปลี่ยนให้รับ `t` เป็น parameter เช่นกัน — ตรวจสอบแล้วว่าถูก consume จาก Chat namespace เท่านั้นจริงๆ (`zone-enter-panel.tsx` ที่ import จากไฟล์นี้ใช้แค่ `categorizeFileError`/`isImageMime` ซึ่งไม่มี text, ส่วน error label แสดงผ่าน `<FileErrorModal>` component ที่ import ทั้งก้อนมาเลย ซึ่งใช้ `useTranslations("Chat")` ของตัวเองอยู่แล้ว ไม่ต้อง thread `t` ข้าม namespace)

**บทเรียนใหม่:** เจอ pattern "shared plain `.ts`/`.tsx` util ที่ reuse ข้าม feature/namespace" เป็นครั้งแรกในรอบนี้ (ก่อนหน้าเจอแต่ util ที่ใช้ใน namespace เดียวกัน) — ต้อง `grep -rln "from.*<util-file>"` ทั้ง codebase ทุกครั้งก่อนแก้ util ที่ shared ไม่ใช่แค่เช็คใน dir ของ feature เดียว

### ปัญหาอื่นที่เจอ (ไม่ได้แก้ เพราะนอก scope)

- `use-typing-emitter.ts`'s fallback name `"Someone"` — broadcast ผ่าน WS ไปแสดงในเครื่องคนอื่น (ไม่ใช่ locale ของผู้ส่งเอง) แปล ณ จุดนี้จะไม่ตรง locale ของผู้ดู จึงปล่อยเป็น hardcode ตามเดิม (ต้องแก้ที่ตัวรับ ไม่ใช่ตัวส่ง ถ้าจะทำ)
- `create-group-modal.tsx` — description placeholder ใช้ข้อความของ "channel" เสมอแม้ตอนสร้าง "group" (pre-existing bug ไม่เกี่ยว i18n)

---

## ✅ HelpCenter + Legal — เสร็จและ wire แล้ว (2026-07-16, uncommitted)

**ต่างจากทุก batch ก่อนหน้า:** namespace ทั้งสองนี้ไม่เคยมี scaffold มาก่อนเลย — ต้อง**เขียนคำแปลอังกฤษ+ไทยเองใหม่ทั้งหมด** ไม่ใช่แค่ wire เข้า key ที่มีอยู่แล้วใน `messages/en.json`

### HelpCenter (137 keys, 4 ไฟล์ใน `views/help-center/`)

- **`help-center-panel.tsx`** (569 บรรทัด) — UI chrome ทั้งหมด (panel title, tabs, search, breadcrumb, feedback buttons ฯลฯ) 26 keys
- **`contact-support-form.tsx`** (363) + **`my-tickets-list.tsx`** (68) + **`highlighted-text.tsx`** (24, ไม่มี text ไม่ต้องแก้) — 41 keys เพิ่ม
- **Article/category content** (69 keys เพิ่มเอง ไม่ผ่าน agent) — `lib/help-content.ts` (5 categories, 10 articles) มี raw English `title`/`intro`/`steps[]`/`tips` ที่ `__tests__/help-center.test.ts` และ `searchArticles()` (case-insensitive substring match บน `title` ภาษาอังกฤษ) พึ่งพาอยู่ตรงๆ — **ไม่แตะไฟล์นี้เลย** เพื่อไม่ให้ search/test พัง แก้โดยเพิ่ม translation layer แยกต่างหากใน `help-center-panel.tsx`: `catLabel(t, id)` → `t(\`category_${id}_label\`)`, `articleTitle/Intro/Steps/Tips(t, article)` → `t(\`article_${slug}_title/intro/step${i}/tips\`)`— key ถูก derive จาก`slug`/`id` ที่เสถียรอยู่แล้ว ไม่ต้องแก้ data model แม้แต่บรรทัดเดียว (pattern ใหม่ที่ควรใช้ซ้ำถ้าเจอ content-data-file ที่มี search/test ผูกกับ raw string ในอนาคต)
- **`CONTACT_TYPES`/`IMPACT_OPTIONS`** ใน `contact-support-form.tsx` ใช้ pattern `labelKey` ปกติ — แต่ `IMPACT_OPTIONS[].value` (ค่าที่ส่งไป backend) **คงค่าอังกฤษเดิมไว้ตรงๆ** เพราะ `__tests__/support.test.ts` assert ค่านี้ตรงๆ — แปลแค่ label ที่แสดงผล ไม่แตะ value ที่เป็น API contract
- Verify: `npx tsc --noEmit` / `npx eslint` / `npx prettier --write` ผ่านหมด, grep sweep หา hardcoded string ไม่เจอ, key-sync check en/th 137/137 ตรงกัน, cross-check ยืนยันครบทั้ง 10 slugs × ทุก field (title/intro/step0-3/tips เฉพาะที่มี) ตรงกับ `lib/help-content.ts` จริง, รัน `__tests__/help-center.test.ts` + `__tests__/support.test.ts` ผ่านครบ 25/25 (0 regression จากการ restructure `labelKey`)
- **Verify ผ่าน browser ไม่ได้** — panel นี้ render เฉพาะตอน login เข้า Virtual Office แล้วเท่านั้น (sandbox ไม่มี backend) ยืนยันได้แค่ระดับโค้ด

### Legal (70 keys, 2 ไฟล์ใน `views/legal/`)

- **`hero-legal.tsx`** (469 บรรทัด) — หน้าเดียว route `/legal` (public, อยู่ใน `PUBLIC_PATHS` ทั้ง `proxy.ts`/`components/auth-guard.tsx` อยู่แล้ว) มี Terms of Service (7 sections) + Privacy Policy (7 sections) แบบ scroll เดียวกัน พร้อม sticky sidebar ToC sync กับ `?section=` query param ผ่าน `IntersectionObserver`, ต่อท้ายด้วย marketing footer (6 promo card + site footer) ที่ดูเหมือน copy มาจาก landing page template
- **`components/navbar.tsx`** (118 บรรทัด) — navbar แยกต่างหากจาก `app-navbar.tsx` หลัก (คนละ component, ไม่มี LanguageSwitcher เพราะไม่ได้ถูกขอให้เพิ่ม)
- Terms/Privacy section headings+bodies เก็บเป็น array `{headingKey, bodyKey}` วน render ผ่าน `.map()`, ToC labels/nav links/product-resource footer links เก็บเป็น array ของ key string เหมือนกัน (`TERMS_SECTIONS`, `PRIVACY_SECTIONS`, `TOC_ITEMS`, `PRODUCT_LINKS`, `RESOURCE_LINKS`, `NAV_ITEMS`) — ตรวจสอบแล้วว่าไม่ใช่ orphaned key แค่ grep แบบ literal เจอไม่ครบเพราะเป็น dynamic array reference
- `t.rich()` ใช้ 4 จุด (`noContentFoundFor` ใน HelpCenter, `card2Tagline`/`card6Tagline`/`card6Speech` ใน Legal) สำหรับ embedded `<bold>`/`<br>` tags — ยืนยันว่า render ถูกต้องผ่าน browser จริงแล้ว (ดู screenshot ด้านล่าง)
- Verify: `npx tsc --noEmit` / `npx eslint` / `npx prettier --write` ผ่านหมด, grep sweep ไม่เจอ hardcoded string, key-sync check en/th 70/70 ตรงกัน
- **Verified ผ่าน browser จริงทั้ง 2 ภาษา** (`/legal` เป็น public route) — screenshot ยืนยัน EN ("Legal", "Terms of Services", "1. Acceptance of Terms" ฯลฯ) และ TH ("ข้อกฎหมาย", "ข้อกำหนดการให้บริการ", "1. การยอมรับข้อกำหนด" ฯลฯ) ขึ้นถูกต้องครบ รวมถึง marketing footer cards + "© 2025 ABC, Inc." copyright + navbar links; ToC click-to-scroll ทำงานถูกต้อง (highlight เปลี่ยนสีตาม section)

### สิ่งที่พบแต่ไม่แก้ (นอก scope ตาม policy 14-no-overreach)

- **`copyright` key = "© 2025 ABC, Inc. All rights reserved."** — เป็น placeholder/dummy content ชัดเจน (ชื่อบริษัทไม่ตรงกับ "Zyra") ดูเหมือน copy มาจาก landing-page template ที่ยังไม่ได้แก้ให้ตรง — แปลตรงตัวไว้ตามเดิม ไม่ได้แก้เนื้อหาเพราะไม่ได้ถูกขอให้แก้
- **Marketing footer/promo section ต่อท้ายหน้า Legal** — โครงสร้างแปลกเพราะดูเหมือนเป็น landing-page section ที่หลงมาอยู่ท้ายหน้า ToS/Privacy (Card1-6 พูดถึง remote work/pricing/virtual office ไม่เกี่ยวกับข้อกฎหมายเลย) — คงโครงสร้างเดิมไว้ แปลให้ครบเท่านั้น ไม่ได้ปรับ layout
- **`SupportTicket.status` field** (ใน `lib/api/support.ts` type) — มีอยู่ใน type แต่ `my-tickets-list.tsx` ไม่เคย render field นี้เลย (ตั๋วทุกใบแสดงแค่ subject/date ไม่มี status badge) — อาจเป็นฟีเจอร์ที่ทำค้างไว้ ไม่ใช่ i18n bug จึงไม่แก้

---

## ✅ WorkspaceEnter + WorkspaceLoading — เสร็จและ wire แล้ว (2026-07-16, uncommitted)

**อีก batch ที่ไม่เคย scaffold มาก่อน** — เขียนคำแปลใหม่ทั้งหมด ไม่ใช่แค่ wire

### WorkspaceEnter (21 keys, 2 ไฟล์ใน `views/user/workspace-enter/`)

- **`hero-workspace-enter.tsx`** (449 บรรทัด, route `/workspace/[id]` — หน้า "ก่อนเข้าพื้นที่" preview กล้อง/ไมค์ + ตั้งชื่อตัวละคร) และ **`components/change-character-modal.tsx`** (204 บรรทัด) — ทั้งคู่ wire `useTranslations("WorkspaceEnter")`
- ไม่มี module-level constant array/object ที่ต้องทำ labelKey pattern — ทุก string เป็น JSX text ตรงไปตรงมา

### WorkspaceLoading (19 keys, 1 ไฟล์ใน `views/user/workspace-loading/`)

- **`hero-workspace-loading.tsx`** (432 บรรทัด, route `/workspace/[id]/loading` — หน้า progress bar โหลดข้อมูลก่อนเข้า Virtual Office จริง)
- **Phase label** (`phaseLabel` state เดิมเก็บ literal string "Connecting"/"Loading map"/ฯลฯ) เปลี่ยนเป็น `phaseKey` เก็บชื่อ key แทน (`phaseConnecting`/`phaseLoadingMap`/`phaseLoadingWorld`/`phaseLoadingMembers`/`phaseAlmostReady`) แล้ว resolve ผ่าน `t(phaseKey)` ตอน render — pattern เดียวกับ `labelKey` ที่ใช้ทั้งโปรเจกต์
- **TIPS array** (4 ข้อความ) เปลี่ยนจาก literal string array เป็น `TIP_KEYS` (ชื่อ key), เข้าถึงผ่าน `t(TIP_KEYS[tipIndex])`
- **Error-throw anti-pattern เจอซ้ำ (เจอครั้งแรกในหน้านี้เอง ไม่ใช่จาก audit sweep รอบก่อน):** โค้ดเดิม `throw new Error(wsRes.message ?? "Failed to load workspace")` แล้ว catch ด้วย `e instanceof Error ? e.message : "Unknown error"` แสดงตรงๆ — เปลี่ยนทุกจุด throw ให้เป็น **fixed code** แทน (`WORKSPACE_LOAD_FAILED`/`MAPS_LOAD_FAILED`/`NO_MAPS_FOUND`/`MAP_OBJECTS_LOAD_FAILED`/`OBJECTS_LOAD_FAILED`) แล้ว catch block map code → translated key ผ่าน `ERROR_KEY_BY_CODE` lookup object (unknown code fallback ไป `errorUnknown`) — **ตัด `wsRes.message`/`mapsRes.message` (raw backend text) ออกทั้งหมด ไม่ให้หลุดมาแสดงตรงๆ อีก** ตรงตาม policy `.claude/rules/05-review.md` (ห้ามโชว์ raw error message ตรงๆ)
- Verify: `npx tsc --noEmit` / `npx eslint` / `npx prettier --write` ผ่านหมด, grep sweep ไม่เจอ hardcoded string เหลือ (ยกเว้น `alt="Zyra"` ซึ่งเป็นชื่อแบรนด์ตามธรรมเนียมเดิม), key-sync check en/th ตรงกันทั้ง 2 namespace (21/21, 19/19), cross-check ครบทั้ง static + dynamic key (`t(phaseKey)`, `t(TIP_KEYS[i])`, `t(ERROR_KEY_BY_CODE[code] ?? "errorUnknown")`)
- **Verify ผ่าน browser ไม่ได้** — ทั้ง 2 หน้าต้องการ auth (`useUserGuard`) + workspace ID จริงที่มีอยู่ใน DB (sandbox ไม่มี backend) ยืนยันได้แค่ระดับโค้ด: route `app/workspace/[id]/page.tsx` และ `app/workspace/[id]/loading/page.tsx` เรียก component ที่ wire แล้วจริง

### สิ่งที่พบแต่ไม่แก้ (นอก scope)

- **`hero-workspace-enter.tsx`'s footer links ชี้ผิด route** — `<Link href="/legal/terms">`/`<Link href="/legal/privacy">` แต่ route จริงมีแค่ `/legal` เดี่ยว (ไม่มี `/legal/terms`, `/legal/privacy` แยก — ยืนยันด้วย `find app/legal -type f` เจอแค่ `page.tsx`) เป็น pre-existing bug ไม่เกี่ยวกับ i18n เลย (แปล label ให้ถูกแล้ว แต่ href ยังพังเหมือนเดิม)

---

## ✅ FeatureTour + AcceptInvite — เสร็จและ wire แล้ว (2026-07-16, uncommitted)

**อีก batch ที่ไม่เคย scaffold มาก่อน**

### FeatureTour (5 keys, 1 ไฟล์ใน `views/feature-tour/`)

- **`feature-tour-modal.tsx`** (158 บรรทัด, SC-UG-06 — modal carousel ประกาศฟีเจอร์ใหม่ เรนเดอร์ทับ VO ใน `hero-virtual-office.tsx`) — wire แค่ **UI chrome** (`Step {n} of {total}`, `Skip tour`, `Back`, `Let's Go!`, `Next`)
- **เนื้อหาทัวร์เอง (`tour.tag`/`tour.author`/`step.title`/`step.body`/`tour.success.*`) จงใจไม่แตะ** — มาจาก `lib/feature-tours.ts` ซึ่งเป็น data-authored content ทีละประกาศ (`ACTIVE_TOURS` **ว่างอยู่ตอนนี้** — ไม่มีทัวร์ active เลยในโปรดักชัน, `VIRTUAL_PETS_TOUR_EXAMPLE` ถูก comment ไว้ชัดเจนว่า "NOT active... kept as a template for authoring real announcements and for tests") ต่างจาก `lib/help-content.ts` ตรงที่ไม่มี slug คงที่ให้ผูก key ไว้ล่วงหน้า เพราะเนื้อหาจะถูกเขียนเพิ่มทีละประกาศในอนาคต ไม่ใช่ชุดบทความคงที่ — การบังคับให้ผ่าน `messages/*.json` ตอนนี้จะเกินขอบเขตงาน (เหมือนบังคับแปล blog post ล่วงหน้าที่ยังไม่มีเนื้อหา)
- `formatDate()` ใช้ `toLocaleDateString("en-US", ...)` hardcode locale — **จงใจไม่แก้** เพราะเป็น pattern เดียวกับที่เจอทั่วทั้งแอป (`chat-utils.ts`, `workspace-card.tsx`, `avatar-card.tsx`, `help-center-panel.tsx` ฯลฯ) และไม่เคยถูกแก้ในทุก batch ก่อนหน้านี้เลย — ถือเป็น scope แยกต่างหาก (locale-aware date formatting) ไม่ใช่ i18n string migration
- Verify: `npx tsc --noEmit` / `npx eslint` / `npx prettier --write` ผ่านหมด, grep sweep ไม่เจอ hardcoded string เหลือ, key-sync check en/th 5/5, `__tests__/feature-tours.test.ts` (9/9 ผ่าน — เทสแค่ `lib/feature-tours.ts` data functions ไม่แตะ modal)
- **Verify ผ่าน browser ไม่ได้** — modal นี้เรนเดอร์เฉพาะข้างใน Virtual Office ที่ auth แล้วเท่านั้น (sandbox ไม่มี backend) ยืนยันได้แค่ระดับโค้ด

### AcceptInvite (28 keys, 1 ไฟล์ใน `views/user/accept-invite/`)

- **`hero-accept-invite.tsx`** (342 บรรทัด, route `/join/[token]`) — 8 status state (idle/checking/loading/success/unauthenticated/expired/capacity_full/wrong_email/error) wire ครบทุก state
- **Error-throw anti-pattern เจอซ้ำอีกครั้ง** (เจอครั้งที่ 3 ในโปรเจกต์นี้ หลัง audit sweep + WorkspaceLoading): โค้ดเดิม `setErrorMsg(res.error)` เก็บ raw backend error text แล้วแสดงตรงๆ ใน generic error state (`{errorMsg || "This invite link is no longer valid..."}`) — ลบ `errorMsg` state ทิ้งทั้งหมด (กลายเป็น dead code ทันทีที่เลิกโชว์ raw text) เปลี่ยนเป็น `t("inviteLinkInvalidBody")` คงที่เสมอ ตรงตาม policy เดียวกับที่แก้ใน WorkspaceLoading — `res.error` ยังใช้ classify status ด้วย `.toLowerCase().includes(...)` ตามเดิม (ไม่แตะ logic ส่วนนี้ เพราะไม่ใช่ raw text ที่โชว์ผู้ใช้)
- ใช้ `t.rich()` 3 จุด สำหรับคำที่ถูกไฮไลต์เป็นสีขาวกลางประโยคสีเทา: `expiredBody` (คำว่า "expired"), `capacityFullBody` (คำว่า "reach limit"), `wrongEmailBody` (อีเมลที่ผู้ใช้กรอกไว้ — interpolate `{email}` เข้าไปใน `<strong>` tag พร้อมกัน)
- `backToLoginCta` ("Back to login") reuse ข้าม 3 state (expired/capacity_full/generic error) — ข้อความเดียวกันเป๊ะในต้นฉบับ ไม่ได้ทำ key ซ้ำ
- Verify: `npx tsc --noEmit` / `npx eslint` / `npx prettier --write` ผ่านหมด, grep sweep ไม่เจอ hardcoded string เหลือ (ยกเว้น `alt="ZYRA"` ซึ่งเป็นชื่อแบรนด์ตามธรรมเนียมเดิม), key-sync check en/th 28/28 ตรงกัน, cross-check literal + `t.rich()` ครบ 28/28 key ถูกใช้จริง ไม่มี orphaned key
- **Verified ผ่าน browser จริงทั้ง EN + TH** — เข้า `/join/test-token-123` (token ปลอมเพราะไม่มี backend) เจอ state "expired" แสดงถูกต้องครบทั้ง title/body (พร้อม `t.rich` ไฮไลต์คำว่า "expired"/"หมดอายุ")/ปุ่ม "Back to login"/"กลับไปหน้าเข้าสู่ระบบ" ทั้ง 2 ภาษา

### สิ่งที่พบแต่ไม่แก้ (นอก scope)

- **`proxy.ts` ไม่มี `/join` ใน `PUBLIC_PATHS`** (มีแค่ `components/auth-guard.tsx` ที่มี) — หมายความว่า user ที่ยังไม่ login แล้วคลิกลิงก์เชิญจะถูก `proxy.ts` redirect ไป `/login` **ก่อน**หน้า `/join/[token]` จะเรนเดอร์ด้วยซ้ำ ทำให้ state `"unauthenticated"` ที่มี UI ครบ (Continue with Google/Mail, Sign up, ToS) **ไม่มีทางถูกแสดงจริงในทางปฏิบัติ** — ตรงกับ gotcha ที่เคยบันทึกไว้ก่อนหน้านี้ว่า "เพิ่ม public route ใหม่ต้องแก้ทั้ง `proxy.ts` และ `auth-guard.tsx`" แต่หน้านี้ตกหล่นไปแค่ฝั่ง `proxy.ts` — เป็น pre-existing routing bug ไม่เกี่ยวกับ i18n เลย (แปล UI ของ state นี้ให้ถูกต้องแล้ว แต่ผู้ใช้จริงจะไม่มีทางเห็น จนกว่าจะแก้ `proxy.ts`)

---

## 🎉 Scaffolded-แต่ไม่ได้-wire — ว่างแล้ว (2026-07-16)

ทุก namespace ที่เคย scaffold ไว้ (Navbar, Home, JoinWorkspace, CopyWorkspace, CreateWorkspace, Login, Signup, Verify, ForgotPassword, ResetPassword, Profile, ImageCropper, Onboarding) **wire เข้าโค้ดครบหมดแล้ว** — ไม่มี feature ไหนเหลือในสถานะ "มี key แต่ไม่ใช้" อีกต่อไป ที่เหลือทั้งหมดคือ feature ที่ **ไม่เคยมี namespace เลยตั้งแต่แรก** (ดูหัวข้อ "ยังไม่ได้เริ่มเลย" ด้านล่าง)

---

## 🔍 Audit sweep — เจอ i18n bug หลงเหลือใน feature ที่เคย mark "เสร็จ" แล้ว (2026-07-16)

User ขอให้ช่วยหา "ส่วนอื่นที่ยังไม่รองรับภาษาไทย" นอกเหนือจาก namespace ที่ scaffold ไว้ — sweep กว้างครอบคลุม `components/` shared, `hooks/`, `stores/`, `lib/api/*.ts`, error boundaries เจอ 2 กลุ่มปัญหา:

### 1. Shared component ที่ไม่เคยถูกแตะเลย (มี hardcoded text ตรงๆ)

| ไฟล์                                      | ปัญหา                                                                                                                                   | แก้ยังไง                                                                                                                                                                                                                                                                         |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `components/workspace-loading-screen.tsx` | "Connecting to {workspaceName}" hardcode ตรงๆ, default prop `phaseLabel = "Starting"`/`workspaceName = "workspace"` เป็น literal string | เพิ่ม `useTranslations("VirtualOffice")` ในตัว component เอง (consumer เดียวคือ `hero-virtual-office.tsx` ยืนยันแล้วผ่าน grep ทั้ง repo) — key ใหม่ `connectingToWorkspace`, reuse `workspaceFallback`/`startingLabel` ที่มีอยู่แล้ว                                             |
| `lib/toast.tsx` (`ZyraToastContent`)      | `aria-label="Dismiss"` บนปุ่มปิด toast — component นี้ใช้ทุก namespace ทั่วทั้งแอป ไม่ผูกกับ feature ไหนเฉพาะ                           | สร้าง **namespace ใหม่ `Common`** (1 key: `dismiss`) แล้วเรียก `useTranslations("Common")` ตรงในตัว component เลย — ไม่ต้องแก้ caller แม้แต่จุดเดียว เพราะ `NextIntlClientProvider` โหลดทุก namespace พร้อมกันอยู่แล้ว (pattern นี้ใช้ซ้ำได้กับ shared component ตัวอื่นในอนาคต) |

### 2. `err instanceof Error ? err.message : t(fallback)` — anti-pattern ที่หลุดรอด migration ทุกรอบ (เจอ 8 จุด, แก้ครบ)

Pattern นี้แสดง **raw JS/backend error message ตรงๆ** เมื่อ catch exception จริง (ไม่ใช่ backend response ปกติ) — bypass การแปลทั้งหมด เพราะ `err.message` มาจาก `throw new Error("hardcoded English")` ในโค้ดเอง หรือจาก browser-native fetch error (ไม่มีทางแปลได้อยู่แล้ว) ขัดกับ policy ใน `AGENTS.md`/`.claude/rules/05-review.md` ที่บอกให้ map error code เป็น fixed client-side message เสมอ ห้ามโชว์ raw backend text ตรงๆ

**กลุ่ม A — โค้ดเอง throw hardcoded string ที่ควรเป็น code แทน (2 จุด, แก้โดยเปลี่ยน source):**

- `lib/api/chat.ts`'s `uploadAttachment` → เปลี่ยนจาก `"Network error during upload"`/`"Upload cancelled"`/raw backend message เป็น code คงที่ (`NETWORK_ERROR`/`UPLOAD_CANCELLED`/`UPLOAD_FAILED`) แล้ว `views/chat/components/message-input.tsx` resolve เป็นข้อความแปลแล้วเอง (key ใหม่: `Chat.uploadCancelledStatus`, `Chat.networkErrorUpload`)
- `lib/api/meeting-attachments.ts`'s `uploadMeetingAttachment` — bug เดียวกันเป๊ะ (copy-paste จาก chat.ts) → แก้แบบเดียวกัน, `views/user/virtual-office/components/zone-enter-panel.tsx` resolve เอง (key ใหม่: `VirtualOffice.uploadCancelledStatus`, `VirtualOffice.networkErrorUpload`)
- `lib/api/chat.ts`'s `getOrCreateDM` — throw `"Failed to open direct message"` เป็น hardcode เหมือนกัน แต่หลังแก้ caller (`start-new-chat-panel.tsx`) ให้เลิกอ่าน `err.message` ไปเลย ข้อความนี้เลยไม่ถูกแสดงที่ไหนแล้ว — ปล่อยไว้ตามเดิมได้ (ไม่ใช่ bug ที่ยังมีผลกระทบ)

**กลุ่ม B — catch generic exception (network/fetch failure) แล้วดันโชว์ `err.message` ตรงๆ (6 จุด, แก้โดยตัด `err.message` ทิ้งแล้วใช้ fallback ที่แปลแล้วเสมอ):**
`views/chat/components/start-new-chat-panel.tsx`, `views/signup/hero-signup.tsx`, `views/login/components/card-login.tsx`, `views/reset-password/hero-reset-password.tsx`, `views/forgot-password/hero-forgot-password.tsx`, `views/admin/workspace-editor/hero-workspace-editor.tsx` — ทุกจุดเปลี่ยนจาก `err instanceof Error ? err.message : t(fallback)` เป็น `t(fallback)` เฉยๆ (ไม่มี key ใหม่ ใช้ fallback key ที่มีอยู่แล้วทุกจุด)

**ยืนยันว่าไม่ใช่ bug (false positive ที่เจอระหว่าง sweep, ไม่ได้แก้):**

- `views/admin/map-management/components/map-template-detail-panel.tsx:286` — `err.message` ใช้เป็น **code** (จาก `loadImageFile` ที่ throw `"INVALID_FILE_TYPE"` เป็นต้น) แล้ว lookup ผ่าน `UPLOAD_ERROR_TOASTS[code]` ต่อ ไม่ใช่การโชว์ text ตรงๆ — ถูกต้องอยู่แล้ว (แก้ไปแล้วตอนทำ AdminMapManagement)

**Verify:** `python3 -c "..."` เช็ค key sync ผ่านทุก namespace, `npx tsc --noEmit` + `npx eslint` ผ่านทุกไฟล์, grep sweep ทั้ง repo หา pattern เดิมซ้ำ — เหลือแค่ 3 จุดที่เป็น code-extraction ที่ถูกต้อง (2 จุดที่เพิ่งแก้ + 1 จุดเดิมที่ถูกอยู่แล้ว)

---

## 🐛 Bug เจอระหว่าง user ทดสอบจริง — ปุ่มเปลี่ยนภาษาบน navbar ใช้งานไม่ได้ (2026-07-16, แก้แล้ว)

**อาการ:** user รายงานว่าปุ่มเปลี่ยนภาษา (🇬🇧 EN) บน navbar กดแล้วไม่มีอะไรเกิดขึ้น

**Root cause:** `components/app-navbar.tsx` มีปุ่มปลอมฝังอยู่ — `<Button>` เปล่าๆ hardcode "🇬🇧 EN" ไม่มี `onClick`/`DropdownMenu` ใดๆ เลย (เป็น placeholder ที่ค้างมาตั้งแต่ตอน build UI ตาม Figma) ส่วน component จริงที่ทำงานได้ถูกต้อง (`components/language-switcher.tsx` — ใช้ `useLocale()` + server action `setUserLocale()` + `router.refresh()`) **ถูกสร้างไว้แล้วแต่ไม่เคยถูก import ไปใช้ที่ไหนเลยในทั้ง codebase**

**แก้ไข:** สลับปุ่มปลอมเป็น `<LanguageSwitcher />` จริงใน `app-navbar.tsx`

**Verify:** ทดสอบผ่าน browser จริง (สร้าง debug page ชั่วคราวที่ public path แล้วลบทิ้งหลังทดสอบเสร็จ เพราะ AppNavbar ต้อง auth ซึ่ง sandbox นี้ไม่มี backend) — คลิกเปิด dropdown, เลือกภาษา, ยืนยันว่า `document.documentElement.lang`, cookie `zyra_locale`, และ font (Noto Sans Thai ↔ Inter) เปลี่ยนพร้อมกันถูกต้อง ไม่มี console error

**บทเรียน:** หลังจาก user ยืนยันว่า mechanism ทำงานถูกต้องแล้ว แต่ทดสอบบนหน้า **Home** แล้วยังไม่เห็นข้อความเปลี่ยน — นำไปสู่การพบว่า Home ยังไม่ได้ wire (แก้ในหัวข้อด้านบนแล้ว) เป็นตัวอย่างว่า "สลับภาษาไม่ทำงาน" อาจจริงๆ แล้วเป็นได้ทั้ง 2 แบบ: (1) bug ที่ mechanism เอง หรือ (2) mechanism ทำงานถูกแล้วแต่หน้านั้นยังไม่ได้แปล — ต้องแยกให้ออกก่อนไล่ debug

---

## ✅ Virtual Office — เสร็จและ commit แล้ว

ฟีเจอร์ที่ใหญ่ที่สุด migrate ครบ:

- 45/53 ไฟล์ใน `views/user/virtual-office/components/` wire `useTranslations("VirtualOffice")` (รวม `hero-virtual-office.tsx` และ `use-meeting-media.ts` hook) — อีก 8 ไฟล์ที่เหลือไม่มี hardcoded UI text (เช่น `vo-debug-panel.tsx` เป็น dev-only debug overlay ไม่ใช่ user-facing copy, ที่เหลือเป็น pure logic/wrapper component)
- Namespace `VirtualOffice` มี **554 keys** — sync กันครบระหว่าง `en.json`/`th.json`
- Module-level constants ที่เคย hardcode string ถูก refactor ให้ถือ key แทน (pattern เดียวกับ `emoji-data.ts` ใน Chat)
- ข้อความ rich-text ใช้ `t.rich()` พร้อม tag ที่ตรงกับ styling เดิม

### Commit history (verified)

งานนี้ commit เข้า `main` แล้วทั้งหมด — **ไม่มี uncommitted file เหลือ** (ก่อนหน้านี้เอกสารเวอร์ชันก่อนเข้าใจผิดว่ายังมี 63 ไฟล์ uncommitted รอ confirm, ตรวจสอบซ้ำแล้วพบว่า commit ไปแล้วจริง):

- `cd60033` — `feat(app): user management admin UI, i18n, change-password, VO polish` (commit หลักที่มี `messages/*.json`, `i18n/*`, VO + change-password wiring)
- `80e1492` — next-intl plugin/provider wiring (ครั้งแรก)
- `6ec8d15` — revert wiring ชั่วคราว (ตาม user request)
- `764bea7` — re-add wiring กลับ (ยืนยันว่า build พังถ้าไม่มี — `/admin/workspace` ต้องการ Suspense + ทุกหน้าที่ใช้ `useTranslations()` ต้องการ `NextIntlClientProvider`)
- `da21e17` — HEAD ปัจจุบัน (ไม่เกี่ยวกับ i18n — เพิ่ม nav item)

### Verification (re-run 2026-07-15 บน HEAD `da21e17`)

- `npx tsc --noEmit` — **ผ่าน, 0 errors** (error ที่เอกสารเก่าระบุเรื่อง `changePassword` import หายไปแล้ว — ไม่ reproduce)
- `npx eslint views/user/virtual-office/` — **ผ่าน, 0 errors** (4 error ที่เอกสารเก่าระบุเรื่อง ref-mirror `react-hooks/immutability` หายไปแล้ว — ไม่ reproduce)
- Key-checker: en/th `VirtualOffice` namespace sync กัน 554/554
- Grep sweep หา hardcoded English ที่หลงเหลือ — ไม่พบ (ยกเว้น debug-only panel ซึ่งไม่ใช่ user-facing)

### ⚠️ ปัญหาที่ยังเหลืออยู่ (ไม่เกี่ยวกับ i18n โดยตรง)

1. **`manage-members-modal.tsx`** บรรทัด 602 — dead code block (`{false && ...}`) ของ join-code panel ที่ไม่ได้ใช้งานจริง ยังไม่ได้ลบ (นอก scope ของงาน i18n)

---

## ✅ Admin Dashboard — เสร็จครบ 7/7 namespace (**uncommitted ทั้งหมด — 110 ไฟล์**)

Scope: `app/admin/` (thin route wrappers, ไม่ต้อง i18n) + `views/admin/` (130 ไฟล์) + `components/admin/*` (shared) — แบ่งเป็น 7 namespace ตาม sub-feature (ทำทีละ namespace, verify ผ่านค่อยไปต่อ ตามที่ user เลือก)

| #   | Namespace                  | ไฟล์                                                                                                    | Keys | สถานะ |
| --- | -------------------------- | ------------------------------------------------------------------------------------------------------- | ---- | ----- |
| 1   | `AdminShared`              | 3 (`components/admin/admin-sidebar.tsx`, `admin-filter-menu.tsx`, `admin-online-toast.tsx`)             | 24   | ✅    |
| 2   | `AdminWorkspaceManagement` | 9 (`views/admin/workspace-management/`)                                                                 | 48   | ✅    |
| 3   | `AdminUserManagement`      | 31 (`views/admin/user-management/**`, `views/admin/online/`)                                            | 280  | ✅    |
| 4   | `AdminAvatarManagement`    | 14 + `avatar-validation.ts` (`views/admin/avatar-management/`)                                          | 112  | ✅    |
| 5   | `AdminMapManagement`       | 12 (`views/admin/map-management/`)                                                                      | 101  | ✅    |
| 6   | `AdminObjectManagement`    | 26 (`views/admin/object-management/`, ~9k บรรทัด)                                                       | 275  | ✅    |
| 7   | `AdminWorkspaceEditor`     | 30 (`views/admin/workspace-editor/`, ~15.5k บรรทัด, มี `hero-workspace-editor.tsx` เดี่ยว 5,193 บรรทัด) | 375  | ✅    |

**รวม keys ที่ migrate แล้วในรอบ Admin Dashboard: 1,215 keys** ทุก namespace ผ่าน verify ครบ: `npx tsc --noEmit`, `npx eslint <dir>`, `npx prettier --write`, grep sweep หา hardcoded string ที่หลงเหลือ, key-sync check (en.json ↔ th.json), และ literal+dynamic `t("key")`/`labelKey` cross-check กับ messages files (รวมถึงเช็ค false-positive จาก dynamic lookup map เช่น `t(STATUS_LABEL_KEYS[s])` ที่ grep แบบ literal จับไม่ได้)

### วิธีทำงานที่ใช้ตลอดทั้ง 7 namespace

แต่ละ namespace แบ่งไฟล์เป็น 2-9 กลุ่มย่อยตามขนาด (namespace ใหญ่ขึ้น = กลุ่มเยอะขึ้น, ไฟล์เดี่ยวที่ใหญ่มาก เช่น `hero-workspace-editor.tsx` 5,193 บรรทัด หรือ `object-composer.tsx` 1,647 บรรทัด ได้ agent แยกเฉพาะตัวเอง) รัน sub-agent แบบ parallel ต่อกลุ่ม (แต่ละกลุ่ม wire component + คืนค่า key/value list กลับมา แต่**ห้ามแตะ `messages/en.json`/`th.json` เอง** — กันไฟล์ conflict) แล้วรวบรวม key ทั้งหมดมาเขียน JSON ทีเดียวเอง + แปลไทยเองเพื่อ consistency แล้ว verify รวมทั้ง namespace อีกที — pattern นี้ scale ได้ดีถึงระดับ 375 keys / 30 ไฟล์ / 15,565 บรรทัดในรอบสุดท้าย

### ปัญหาที่เจอระหว่างทำ + วิธีแก้ (เจอซ้ำหลายรอบ ควรรู้ไว้ถ้าทำ i18n batch ใหญ่ต่อไปในอนาคต)

1. **Plain `.ts` util ที่ fire toast เอง เรียก `useTranslations()` ไม่ได้** — เจอ 3 รอบ: `avatar-validation.ts` (`showValidationToast`), `map-template-constants.ts` (`UPLOAD_ERROR_TOASTS`) — แก้โดยเปลี่ยน map จาก `{title, message}` literal string เป็น `{titleKey, messageKey}` แล้วให้ component ฝั่งเรียกทำ `t(info.titleKey)` เอง (ต้อง brief ทั้ง 2 agent ที่เกี่ยวข้องให้ตรงกัน)
2. **ICU MessageFormat crash จาก literal curly brace** — string ต้นฉบับบางอันมี placeholder text แบบ `{character_id}_{state}_{frame_number}` ที่เป็นแค่คำอธิบาย pattern ไม่ใช่ตัวแปรจริง — ถ้าใส่ตรงๆ ผ่าน `t()` จะ crash เพราะ ICU ตีความ `{name}` เป็น interpolation variable เสมอ ต้อง reword ให้ไม่มี literal brace แทนการ escape (แก้แล้วใน `avatar-validation.ts`)
3. **`type-to-confirm-input.tsx`** — prop `action="ban"`/`action="delete"` เป็น raw English word ที่ interpolate เข้าไปในประโยคแปลแล้วโดยไม่ถูกแปล ต้องเพิ่ม `ACTION_LABEL_KEYS` map แปล action word เองก่อน interpolate
4. **Bare-value array ที่ต้อง match กับ backend data ตรงๆ** (`WORKSPACE_CATEGORIES = ["Country","Garage",...]` ใน `left-panel-constants.ts`) — ห้ามเปลี่ยนค่า value เอง เพราะใช้ compare กับ backend `category` field ตรงๆ วิธีแก้คือเพิ่ม **display-only label map แยกต่างหาก** (`WORKSPACE_CATEGORY_LABEL_KEYS`) ไว้ข้างๆ โดยไม่แตะ array เดิม — ใช้ได้กับกรณี identifier ↔ display label แยกกันทุกแบบ
5. **Dead code จาก refactor ระหว่างทาง** — เมื่อ agent ย้ายจาก "import label map จากไฟล์ constants แชร์" มาเป็น "local labelKey map ในไฟล์ตัวเอง" (เพราะไฟล์ constants เป็น plain `.ts` แก้ไม่ได้) จะทำให้ field เดิมในไฟล์ constants กลายเป็น dead code (เช่น `DIRECTION_LABELS` ใน `object-composer-constants.ts`, `LOAD_PHASES[].label` ใน `types.ts`) — ปล่อยไว้ตามเดิม (ไม่ลบ, นอก scope) แต่ flag ให้ user รู้
6. **Key collision risk** — ทุก sub-group ใช้ namespace เดียวกัน (flat) ต้อง brief ให้ agent ตั้งชื่อ key แบบ prefix เฉพาะ feature (เช่น `avatarFormNameLabel` ไม่ใช่ `nameLabel`) ยกเว้นคำ generic แท้ๆ (`cancel`/`close`/`save`/`delete`/`confirm`) ที่ reuse ข้าม sub-group ได้ — ไม่เจอ collision จริงเลยตลอดทั้ง 1,215 keys/7 namespace

### Dead code / bug ที่เจอระหว่างทำ (ไม่ได้แก้ เพราะนอก scope)

- `WorkspaceCreateModal`/`WorkspaceStatusBadge` (workspace-management) — ไม่มีที่ import ใช้งานจริง
- `ban-modal.tsx` — "Reason" กับ "Note (Optional)" ใช้ placeholder ข้อความเดียวกันผิดๆ (copy-paste bug เดิม)
- `admin-role-panel.tsx`/`customer-role-panel.tsx` — โค้ดซ้ำกันเกือบทั้งหมด
- role-permission บาง error toast เป็น dead code (ไม่มี UI ไหน render error state)
- `delete-map-dialog.tsx` — เรียก `setState` ระหว่าง render (code smell เดิม)
- Tooltip เดิม hardcode เป็นภาษาไทยตรงๆ ไม่สนใจ locale — แก้ให้ตาม locale แล้ว (map-management, zone-create-dialog.tsx)
- `object-composer-constants.ts`'s `DIRECTION_LABELS` — ไม่มีใคร import ใช้แล้วหลัง refactor (dead code)
- `types.ts`'s `LOAD_PHASES[].label` — field ไม่ได้ใช้แล้ว (แต่ `.progress` field ยังใช้อยู่) หลัง `hero-workspace-editor.tsx` เปลี่ยนไปใช้ local key map แทน
- `object-add-form.tsx` — มี `console.group`/`console.log` debug scaffolding เหลืออยู่ในโค้ด save flow

---

## 🎨 Thai Font (2026-07-16)

เปลี่ยน font ภาษาไทยเป็น **Noto Sans Thai** — แก้ที่ `app/layout.tsx`:

- โหลดผ่าน `next/font/google` (`Noto_Sans_Thai`, variable `--font-noto-sans-thai`, weight 400/500/600/700) — ตาม pattern เดียวกับ Inter/Poppins/Pixelify_Sans ที่มีอยู่แล้ว
- body font สลับอัตโนมัติ: `locale === "th"` → Noto Sans Thai, อื่นๆ → Inter (Inter ไม่มี Thai glyph coverage อยู่แล้ว)
- Verified ผ่าน browser: `document.documentElement.lang === "th"` → computed `font-family` เปลี่ยนเป็น `"Noto Sans Thai"` จริง

---

## 🎉 ยังไม่ได้เริ่มเลย — ว่างแล้ว (2026-07-16, ปิด batch สุดท้าย)

**`views/user/workspace-preview/hero-workspace-preview.tsx`** (23 บรรทัด, route จริง `/workspace/preview/[id]` ผ่าน `app/workspace/preview/[id]/page.tsx` — **ไม่ใช่ dead code**) — เช็คแล้วพบว่า **ไม่ต้องทำอะไรเพิ่ม**:

- ไฟล์นี้เป็น thin wrapper ล้วนๆ (23 บรรทัด) forward props ไปที่ `HeroWorkspaceEditor` (จาก `views/admin/workspace-editor/`) ด้วย `readOnly={true}` — ตัวไฟล์เองไม่มี hardcoded text แม้แต่ตัวเดียว ไม่ต้อง `useTranslations` เลย
- ทุก code path เฉพาะ `readOnly`/preview mode ใน `hero-workspace-editor.tsx` (ปุ่ม "Close preview" บรรทัด ~4963, `RoomListPanel`, `PreviewZoneClickLayer`, `PreviewZoneHighlight`) **ถูกแปลไปแล้วตั้งแต่รอบ `AdminWorkspaceEditor`** (`t("heroEditorClosePreviewTitle")` มีอยู่แล้ว) — ยืนยันด้วย grep sweep ทั้ง 2 component ย่อย ไม่พบ hardcoded string เหลือเลย

**สรุป: ทุก path ที่เคยอยู่ในลิสต์ "ยังไม่ได้เริ่มเลย" ตอนต้น (help-center, legal, workspace-enter, workspace-loading, feature-tour, accept-invite, workspace-preview) ตอนนี้เสร็จ/ยืนยันว่าไม่ต้องทำครบทั้งหมดแล้ว**

**หมายเหตุ:** `views/admin/status/` (ฟีเจอร์ใหม่ที่ user กำลังทำคู่ขนานอยู่ตอนนี้ — เห็นใน `git status`) **wire `useTranslations` มาแล้วตั้งแต่แรกโดย user เอง** ไม่ต้องทำอะไรเพิ่ม

---

## Next Steps

1. ~~Commit งาน i18n virtual-office~~ — **เสร็จแล้ว**
2. ~~เช็ค AGENTS.md ว่า "UI copy" convention~~ — **แก้แล้ว**
3. ~~แก้เอกสารให้ตรงความจริง (แก้ false "done" claims)~~ — **เสร็จแล้ว 2026-07-16**
4. ~~ทำต่อ `Chat` namespace~~ — **เสร็จแล้ว 2026-07-16** (187 keys, 25/29 ไฟล์ wire จริง)
5. ~~ทำต่อ `Home`/`JoinWorkspace`/`CopyWorkspace`/`CreateWorkspace` + แก้ bug ปุ่มเปลี่ยนภาษา~~ — **เสร็จแล้ว 2026-07-16** (138 keys ใหม่ + `WelcomeSpace` namespace ใหม่ + `Navbar` wire ครบ)
6. ~~ทำต่อ `Login`/`Signup`~~ — **เสร็จแล้ว 2026-07-16** (0 key ใหม่, scaffold แม่น 100%, verified ผ่าน browser จริง)
7. ~~ทำต่อ `Verify`/`ForgotPassword`/`ResetPassword` + ย้าย LanguageSwitcher ไปมุมขวาบน Login/Signup + แก้ dropdown background~~ — **เสร็จแล้ว 2026-07-16** (0 key ใหม่ทั้ง 3 namespace, verified ผ่าน browser จริงทุกหน้า)
8. ~~ทำต่อ `Profile`/`ImageCropper`/`Onboarding`~~ — **เสร็จแล้ว 2026-07-16** (3 key ใหม่จาก `toastReason()` cross-file fix, ที่เหลือ scaffold แม่น 100% — **ทุก namespace ที่เคย scaffold ไว้ wire ครบหมดแล้ว**)
9. ~~Audit sweep หา i18n bug ที่หลงเหลือนอกเหนือ namespace scaffold~~ — **เสร็จแล้ว 2026-07-16** (เจอ+แก้ 2 shared component ที่ไม่เคยแตะ + 8 จุด `err.message` anti-pattern ใน feature ที่เคย mark เสร็จแล้ว — ดูหัวข้อ "🔍 Audit sweep")
10. ~~ทำต่อ `HelpCenter`/`Legal`~~ — **เสร็จแล้ว 2026-07-16** (namespace ใหม่ทั้งคู่ — 137 + 70 keys เขียนคำแปลเองทั้งหมด, verified ผ่าน test suite 25/25 + browser จริง — ดูหัวข้อ "HelpCenter + Legal")
11. ~~ทำต่อ `WorkspaceEnter`/`WorkspaceLoading`~~ — **เสร็จแล้ว 2026-07-16** (namespace ใหม่ทั้งคู่ — 21 + 19 keys, รวม refactor error-throw anti-pattern เป็น fixed code — ดูหัวข้อ "WorkspaceEnter + WorkspaceLoading")
12. ~~ทำต่อ `FeatureTour`/`AcceptInvite`~~ — **เสร็จแล้ว 2026-07-16** (namespace ใหม่ทั้งคู่ — 5 + 28 keys, แก้ error-throw anti-pattern อีกครั้งใน AcceptInvite, verified ผ่าน browser จริงทั้ง EN/TH ที่ `/join/[token]` — ดูหัวข้อ "FeatureTour + AcceptInvite"; เจอ pre-existing bug `proxy.ts` ไม่มี `/join` ใน `PUBLIC_PATHS` ทำให้ state "unauthenticated" ไม่มีทางแสดงจริง — flag ไว้ ไม่แก้)
13. ~~เช็ค `views/user/workspace-preview/` ว่าเป็น dead code ไหม~~ — **เสร็จแล้ว 2026-07-16** (ไม่ใช่ dead code — route จริง `/workspace/preview/[id]` — แต่ไม่ต้องทำอะไรเพิ่ม: ไฟล์เป็น thin wrapper ไม่มี text เอง และทุก readOnly/preview code path ใน `hero-workspace-editor.tsx` ถูกแปลไปแล้วตั้งแต่รอบ `AdminWorkspaceEditor` — ดูหัวข้อ "ยังไม่ได้เริ่มเลย — ว่างแล้ว")
14. **🎉 i18n migration เสร็จสมบูรณ์ 100% ของทุก path ที่รู้จักในตอนนี้** — ไม่มี feature ไหนเหลือที่ยังไม่มี namespace หรือยังไม่ wire แล้ว
15. **Commit** — งานหลายส่วนถูก commit ไปแล้วโดย user เอง (เห็นใน `git log`, commit `eb074f9`, `507d484`, `8ebaa3d`) ระหว่างที่ session นี้ทำงานคู่ขนาน — เช็คสด (`git status --short`) ก่อน commit เสมอ เพราะมีไฟล์ของ user เองปนอยู่ด้วย (เช่น `.github/workflows/deploy-prod.yml`, `Dockerfile`, `lib/changelog.ts` ที่ไม่ใช่งาน i18n) — เนื่องจากตอนนี้งาน i18n เสร็จหมดแล้ว ควรถาม user ว่าต้องการ commit งานทั้งหมดเป็นก้อนเดียวหรือแยกเป็นหลาย commit ตาม batch
16. **หมายเหตุ workflow:** user commit งานเองเป็นระยะระหว่าง session นี้ทำงาน — ก่อนเชื่อ "จำนวนไฟล์ uncommitted" หรือ "total keys" ในเอกสารนี้ ให้รัน `git status --short` และนับ key สดเสมอ อย่าเชื่อเลขที่บันทึกไว้ก่อนหน้า
