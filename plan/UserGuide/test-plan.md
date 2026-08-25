# Test Plan — User Guide Module

**Version:** 1.0 · **Date:** 2026-07-14
**Scope:** SC-UG-01 ~ SC-UG-08 (zyra-api + zyra-app + zyra-notifications)
**Refs:** `spec.md` · `technical-design.md` · `task-breakdown.md`

---

## Coverage Targets

| Layer | Package / Module | Target |
|---|---|---|
| Unit (Go) | `internal/service/support_service.go`, `profile_service.go` (ส่วน onboarding), `help_service.go` | ≥ 80% |
| Unit (TS) | `lib/onboarding.ts`, `lib/help-content.ts`, `lib/feature-tours.ts`, `lib/api/support.ts` | ≥ 80% |
| Component | onboarding modal, help panel, contact form | critical paths |
| API | ทุก route ใหม่ | 100% endpoint coverage |
| E2E (Playwright) | 3 journeys | happy + alternate + error |

กติกา (ตาม rules เดิม): Go ใช้ table-driven + `testify`; mock DB ผ่าน interface — **ห้ามต่อ PostgreSQL จริง**; TS ใช้ Vitest + `vi.mock` — **ห้ามยิง `/api/*` จริง**; test ทุก sentinel error

---

## 1. Unit Tests — Go (zyra-api)

### 1.1 `profile_service.go` — onboarding

| Test | Input | Expected |
|---|---|---|
| `TestUpdateOnboarding_Skipped` | userID, "skipped" | UPDATE ถูกยิง, no error |
| `TestUpdateOnboarding_Completed` | userID, "completed" | no error |
| `TestUpdateOnboarding_InvalidValue` | "pending" / "done" / "" | error (400) — ห้าม set กลับ pending |
| `TestUpdateOnboarding_Idempotent` | ยิง "skipped" ซ้ำ | no error |
| `TestGetProfile_IncludesOnboardingStatus` | user มี status 'pending' | response มี `onboarding_status: "pending"` |

### 1.2 `support_service.go` — CreateTicket (table-driven)

| Test | Input | Expected |
|---|---|---|
| `TestCreateTicket_BugReport` | type=bug_report + impact + topic + desc | INSERT, code `ZYR-{seq}`, email params มี Impact |
| `TestCreateTicket_FeatureRequest` | type=feature_request, no impact | สำเร็จ, email ไม่มี Impact |
| `TestCreateTicket_GeneralFeedback` | valid | สำเร็จ |
| `TestCreateTicket_ContactSupport` | type=contact_support | สำเร็จ; ห้ามมี attachment (ส่งมา → error) |
| `TestCreateTicket_InvalidType` | type="other" | `ErrInvalidContactType` |
| `TestCreateTicket_BugMissingImpact` | bug_report ไม่มี impact | validation error |
| `TestCreateTicket_ImpactOnNonBug` | feedback + impact | validation error |
| `TestCreateTicket_TopicTooLong` | topic 101 chars | `ErrTopicTooLong` |
| `TestCreateTicket_TopicBoundary` | topic 100 chars พอดี | สำเร็จ |
| `TestCreateTicket_DescTooLong` | desc 1001 chars | `ErrDescriptionTooLong` |
| `TestCreateTicket_EmptyRequired` | topic/desc ว่าง | validation error |
| `TestCreateTicket_AttachmentTooLarge` | file 5MB+1 | `ErrAttachmentTooLarge` |
| `TestCreateTicket_AttachmentBoundary` | file 5MB พอดี PNG | สำเร็จ, upload key `support/{uid}/…` |
| `TestCreateTicket_AttachmentWrongType` | .gif / .pdf / PNG นามสกุลปลอม (magic bytes ผิด) | `ErrAttachmentType` |
| `TestCreateTicket_S3NotConfigured` | s3=nil + มีไฟล์ | error "storage not configured"; ไม่มีไฟล์ → สำเร็จ |
| `TestCreateTicket_NotifyNil` | notify=nil | ticket สำเร็จ (email no-op) |
| `TestCreateTicket_EmailFail` | notify error | ticket สำเร็จ (SendAsync ไม่ block) |
| `TestCreateTicket_RateLimit` | ticket ที่ 6 ใน 1 ชม. | rate-limit error |
| `TestListTickets_OwnOnly` | user A | เฉพาะ ticket ของ A, ล่าสุดก่อน |
| `TestTicketCode_Format` | seq 1094 | `ZYR-1094` |

**Boundary values:** topic 0/1/100/101 · desc 0/1/1000/1001 · file 0B/5MB/5MB+1 · rate limit 5/6

### 1.3 `help_service.go` — article feedback

| Test | Input | Expected |
|---|---|---|
| `TestFeedback_FirstVote` | user+slug ใหม่, helpful=true | INSERT |
| `TestFeedback_Upsert` | vote ซ้ำ helpful=false | UPDATE (unique user+slug) |
| `TestFeedback_EmptySlug` | slug "" | validation error |

## 2. Unit Tests — TypeScript (zyra-app, Vitest)

### 2.1 `lib/onboarding.ts`

- `updateOnboardingStatus("skipped"/"completed")` → PATCH ถูก path/payload (mock `authFetch`); error propagate
- Spotlight helpers: `markSpotlightPending()` → `consumeSpotlight()` คืน true ครั้งเดียว, ครั้งสองคืน false; SSR-safe (ไม่มี window ไม่ crash)
- `ONBOARDING_TABS`: 4 tabs, 7 pages รวม, copy ตรง spec (snapshot)

### 2.2 Onboarding modal state (component/logic)

- Next จาก Welcome → Office Setup 1/3; Back ไม่มีบน Welcome
- เดินครบ → Let's Go! → success → Back to Workspace → `updateOnboardingStatus("completed")` ถูกเรียกครั้งเดียว
- Skip ทุก step → confirm; Cancel → step เดิม (state ไม่ reset); Yes, Skip → `"skipped"` + spotlight pending
- Progress: 0/33/67/100 ตาม tab ที่จบ; PATCH fail → modal ปิดได้ + ไม่ throw

### 2.3 `lib/help-content.ts`

- `searchArticles("h")` → เรียงถูก, case-insensitive; `searchArticles("hh")` → `[]`; query ว่าง → ทั้งหมด/ไม่ filter
- category filter เฉพาะหมวด; `recommended`/`popular` filter helpers
- ทุก slug unique; ทุกบทความมี category ที่อยู่ใน `HELP_CATEGORIES`

### 2.4 `HighlightedText`

- match เดี่ยว/หลายตำแหน่ง/ต้น-ท้าย string/ไม่ match/query อักขระพิเศษ (regex escape)

### 2.5 `lib/api/support.ts`

- `createSupportTicket`: FormData มี field ครบตาม type (impact เฉพาะ bug, ไม่มี attachment เมื่อ contact_support), auto metadata (page_url/browser/os)
- `listSupportTickets` map response; `sendArticleFeedback(slug, helpful)` payload ถูก

### 2.6 Contact form logic

- Send disabled: default / topic ว่าง / desc ว่าง / bug ไม่เลือก impact → disabled; ครบ → enabled
- Counter 27/100 กับ auto-fill `Cannot find "hh" in Articles`; auto-fill truncate เมื่อ query ยาว
- ไฟล์เกิน 5MB / ผิด type → `zyraToast.errorWithTitle` ถูกเรียก + ไม่ set file
- Submit สำเร็จ → success toast + สลับ tab My Tickets + invalidate `["support-tickets"]`
- Double-submit: ปุ่ม disabled ระหว่าง pending

### 2.7 `lib/feature-tours.ts`

- Seen key ต่อ user ต่อ tour (`zyra_feature_tour_{id}_{uid}`); mark → ไม่แสดงซ้ำ; user อื่นไม่กระทบ; `ACTIVE_TOURS` ว่าง → ไม่มี tour ค้าง

## 3. API Tests (zyra-api route level)

| Route | Cases |
|---|---|
| `PATCH /api/user/me/onboarding` | 200 skipped/completed · 400 ค่าอื่น · 401 ไม่มี token |
| `POST /api/user/support/tickets` | 201 ทุก contact_type · 400 validation แต่ละข้อ · 400 ไฟล์ผิด/เกิน · 401 · 429 rate limit |
| `GET /api/user/support/tickets` | 200 เฉพาะของตัวเอง · ว่าง = `[]` · 401 |
| `POST /api/user/help/articles/{slug}/feedback` | 200 first + upsert · 400 body ผิด · 401 |

## 4. E2E (Playwright — dev server port 3000)

> Pre-condition: seed user ใหม่ (`onboarding_status='pending'`) + reset ผ่าน SQL ระหว่าง case; ใช้บัญชี seed `member-a@zyra.test` สำหรับ non-onboarding cases

### J1 — Onboarding (SC-UG-01/02/03)
1. Login user ใหม่ → modal ขึ้นบน `/` ทันที; assert copy Welcome + ชื่อ user
2. Next ×7 → assert progress 33/67/100 + ✓ tabs → Let's Go! → "You're All Set!" → Back to Workspace → modal หาย
3. Reload + re-login → **ไม่ขึ้นอีก** (completed)
4. Reset เป็น pending → login → Skip → confirm modal → Cancel → step เดิม → Skip → Yes, Skip → spotlight + tooltip "Click to start creating a workspace." → คลิก → หาย; re-login → ไม่ขึ้น (skipped)
5. Reset pending → login → Next ×2 → ปิด tab → login ใหม่ → modal ขึ้นที่ Welcome 0% (resume rule)

### J2 — Help Center (SC-UG-04/05)
1. เข้า VO → คลิก `?` → panel เปิด 336px; assert header/tabs/categories 5 หมวด
2. Search "mic" → ผลลัพธ์ + highlight; คลิก → detail (hero/steps/tips) → Helpful → thank-you state
3. Category "Virtual Office" → list → in-category search → back navigation ครบ
4. Search "zzzz" → empty state + Popular Articles ลิงก์ทำงาน
5. X ปิด panel; เปิดใหม่ → กลับหน้า main

### J3 — Contact Support (SC-UG-07/08)
1. จาก empty state ("zzzz") → "Report issue about" → form + Topic auto-fill `Cannot find "zzzz" in Articles`
2. Bug Report: เลือก Impact, กรอกครบ, แนบ PNG เล็ก → Send enabled → ส่ง → My Tickets + toast `Message sent! Ticket ID #ZYR-…` + card ขึ้นใน list
3. แนบไฟล์ >5MB → error toast, form ไม่ถูกส่ง
4. Contact Support type → send-to strip + Subject label + ไม่มี attachment area → ส่งสำเร็จ
5. (ถ้ามี mailhog/log) assert email 2 ฉบับถูก request ไป zyra-notifications

### J4 — Feature Tour (SC-UG-06, เมื่อมี ACTIVE_TOURS ใน test build)
1. เข้า VO → tour modal STEP 1 OF 5 → Next/Back → Let's Go! → success → Back to Office → reload → ไม่ขึ้นซ้ำ
2. Reset seen → Skip tour ที่ step 2 → ไม่ขึ้นซ้ำ

## 5. Regression Checks

- [ ] Lobby (`hero-user-workspace.tsx`) ของ user เก่า (completed) — ไม่มี modal/แฟลชขึ้นมา
- [ ] `GET /api/user/me` ผู้บริโภคเดิม (navbar, profile) ไม่พังจาก field ใหม่
- [ ] VO sidebar เดิม (member/notification panels) toggle ร่วมกับ Help panel ได้ไม่ชนกัน
- [ ] `npx tsc --noEmit` + `npm run lint` + `go test ./...` ผ่านทั้งหมด
- [ ] Migration 60-62 มี rollback script คู่กัน (ตาม release rule)

## 6. Manual QA Checklist

- [ ] Pixel-compare ทุกหน้าจอกับ Figma (95-100% ตาม rule 10)
- [ ] Animation เปลี่ยนหน้า onboarding/tour ลื่น ไม่กระตุก
- [ ] Spotlight ตรงปุ่มจริงเมื่อ resize window
- [ ] Email 2 ฉบับ render ถูกใน Gmail จริง (ack + admin, มี/ไม่มี Impact)
- [ ] คีย์บอร์ด: Esc ปิด panel/modal ได้ตาม convention; focus trap ใน modal
