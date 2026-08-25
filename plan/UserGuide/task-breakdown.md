# Task Breakdown — User Guide Module

**Version:** 1.0 · **Date:** 2026-07-14
**Scope:** SC-UG-01 ~ SC-UG-08
**Refs:** `spec.md` · `technical-design.md` · `ux-ui-plan.md` · `test-plan.md` · `figma-nodes.md`

---

## Status

- **Phase 1 — เสร็จ 2026-07-14** (verified E2E บน dev): UG-001~011 done. Onboarding hero images ใส่แล้ว (2026-07-14): Welcome = `static/background/user_guide_1.png`, อีก 3 tabs = `user_guide_2.png` (R2 public pub-b74ca…r2.dev, ใน `ONBOARDING_PAGES`). Empty-state illustration + feature-tour hero ยังใช้ icon/gradient fallback
- **Phase 2 — เสร็จ 2026-07-14** (verified E2E บน dev): UG-012~018, 020 done; help panel เปิดจากปุ่ม "?" ใน vo-sidebar (docked ขวา 336px), search+highlight, categories, detail+feedback (persist DB), empty state + popular. **ค้าง**: empty-state illustration ใช้ icon fallback รอ asset จริง
- **Phase 3 — เสร็จ 2026-07-14** (verified E2E บน dev): UG-021~031 done. Contact Support form ครบ 4 contact types (Bug + Impact, Feature, Feedback, Contact Support variant = Subject + send-to strip + no attachments), validation client+server, R2 attachment, ticket `ZYR-{n}`, rate-limit 5/hr, 2 email templates (zyra-notifications), My Tickets (TanStack Query), success toast, และ SC-UG-05→07 auto-fill (`Cannot find "{q}" in Articles`) เชื่อมครบ. ยืนยัน POST→201, DB persist ครบทุก field (impact/browser/os/page_url auto), success toast + My Tickets refresh.
- **Phase 4 — เสร็จ 2026-07-14** (verified E2E บน dev ด้วย temp-activated Virtual Pets tour แล้ว revert): UG-032~035 done. `lib/feature-tours.ts` (data-driven config, `ACTIVE_TOURS=[]` โดย default, seen-state localStorage per user+tour), `feature-tour-modal.tsx` (600w carousel + success modal), mount ใน hero-virtual-office (gate ด้วย `firstUnseenTour`). ยืนยัน Next/Back/dots, Let's Go!→success→Back to Office, seen persist + ไม่ขึ้นซ้ำ. **Gotcha ที่เจอ+แก้**: modal อยู่ใน VO HUD wrapper (`pointer-events-none`) → ต้องใส่ `pointer-events-auto` ที่ root modal ไม่งั้นคลิกทะลุไป canvas (Help Center panel รอดเพราะมี pointer-events-auto อยู่แล้ว). ACTIVE_TOURS ว่าง = ไม่มี tour แสดงใน prod จนกว่าจะ publish
- **Phase 5 — เสร็จ 2026-07-14**: UG-036~039. `e2e/user-guide.spec.ts` (9 scenarios × 3 browsers = 27 tests, E2E_LIVE-gated + assertNoAdminApi, enumerate ผ่าน `npm run e2e:list`), `usage-guide.md` เขียนครบ. Polish: vitest 260/260, tsc + eslint สะอาด, ทุก service (api/notifications/ws) build+test ผ่าน. UI เป็น dark-only ตาม design (ไม่มี light mode). **ClickUp ไม่แตะ** (project rule: read-only) — สรุปอยู่ใน docs แทน
- Migration 60, 61, 62 apply แล้วบน dev DB — **ต้อง apply บน preview/prod ตอน deploy**
- **Env ใหม่**: `SUPPORT_EMAIL` (inbox ของ ticket alert) — ยังไม่ set บน dev (email path skip inbox แต่ ticket ยังสร้างได้); ต้อง set ตอน deploy + PM ยืนยัน address จริง (design มี 3 ค่าขัดกัน — spec Q11)
- **Follow-up fixes — 2026-07-16** (จาก 2 issue reports บน SC-UG-01):
  1. SC-UG-03 **revised**: เดิมตัดสินใจ restart ที่ Welcome/0% เสมอเมื่อปิด browser กลาง onboarding (sticky note) — เปลี่ยนเป็น resume จาก step ที่ค้างไว้จริงตาม issue report ใหม่ (ดู `spec.md`/`technical-design.md` §0, §2, §3.1, §5.2). เพิ่ม migration `67_onboarding_progress.sql` (`onboarding_page_index` บน `tb_user`) + `PATCH /api/user/me/onboarding/progress` (ยิงทุก Next/Back) + reset กลับ 0 เมื่อ status เป็น skipped/completed — **ต้อง apply migration 67 บน preview/prod ตอน deploy**
  2. Bug: จบ onboarding ครบ (กด Let's Go!) แล้วกลับมาหน้า workspace list popup ขึ้นใหม่ — root cause คือ `["profile-onboarding"]` TanStack Query cache (`staleTime: Infinity`) ใน `hero-user-workspace.tsx` ไม่เคย invalidate หลัง resolve; แก้โดยให้ `handleOnboardingClose` เขียน cache ด้วย `queryClient.setQueryData` ควบคู่กับ Zustand store

## Summary

| Phase | Tasks | Layer | Scenarios |
|---|---|---|---|
| Phase 1 — Onboarding | UG-001 ~ UG-011 | API + FE | SC-UG-01, 02, 03 |
| Phase 2 — Help Center (Articles) | UG-012 ~ UG-020 | FE (+API feedback) | SC-UG-04, 05 |
| Phase 3 — Contact Support | UG-021 ~ UG-031 | API + Notifications + FE | SC-UG-07, 08 (+ปุ่ม Report ของ 05) |
| Phase 4 — Feature Walkthrough | UG-032 ~ UG-035 | FE | SC-UG-06 |
| Phase 5 — E2E & Polish | UG-036 ~ UG-039 | ทั้งหมด | all |

**Total: 39 tasks** · ลำดับแนะนำ: Phase 1 → 2 → 3 (Phase 4 ทำขนานได้; ปุ่ม "Report issue about" ใน Phase 2 ต้องรอ form จาก Phase 3 — ดู UG-019)

## Estimation Key

| Label | Effort |
|---|---|
| XS | < 2 h |
| S | 2–4 h |
| M | 4–8 h (1 วัน) |
| L | 8–16 h (2 วัน) |

---

## Phase 1 — Onboarding (SC-UG-01/02/03)

### UG-001 · Migration 60 — onboarding columns
**Layer:** zyra-api (PostgreSQL) · **Effort:** XS · **Depends:** —
- [ ] `60_user_onboarding.sql`: `onboarding_status` + `onboarding_updated_at` (default `'pending'`)
- [ ] Backfill user เดิมทั้งหมดเป็น `'completed'`
- [ ] Apply ผ่าน psql (dev + preview) — migration ไม่ auto-run

### UG-002 · Profile service — expose + update onboarding status
**Layer:** zyra-api · **Effort:** S · **Depends:** UG-001
- [ ] เพิ่ม `onboarding_status` ใน query/response ของ `GET /api/user/me` (`profile_service.go` + model)
- [ ] `UpdateOnboardingStatus(ctx, userID, status)` — validate เฉพาะ `skipped`/`completed`, idempotent, wrap error ด้วย `fmt.Errorf`
- [ ] Unit tests (mock DB): valid transitions, invalid value → error

### UG-003 · Route — `PATCH /api/user/me/onboarding`
**Layer:** zyra-api · **Effort:** XS · **Depends:** UG-002
- [ ] Handler + register ใน user group (`router.go`) ข้าง `PATCH /me/status`
- [ ] 400 เมื่อ status ไม่ถูกต้อง; envelope `{status, message, data}`

### UG-004 · FE lib — onboarding API + config
**Layer:** zyra-app · **Effort:** S · **Depends:** UG-003
- [ ] `lib/onboarding.ts`: `updateOnboardingStatus()` ผ่าน `authFetch`; `ONBOARDING_TABS` content config (copy ตาม `ux-ui-plan.md` §2.2); sessionStorage helpers spotlight
- [ ] เพิ่ม `onboarding_status` ใน `ProfileData` (`lib/api/profile.ts`) + `StoredUser` ถ้าจำเป็น

### UG-005 · Onboarding modal shell
**Layer:** zyra-app · **Effort:** L · **Depends:** UG-004
- [ ] `views/onboarding/onboarding-modal.tsx` — 900×600, sidebar (header/tabs/progress) + content pane ตาม pixel spec
- [ ] State machine `{tabIndex, pageIndex}` + Next/Back + tab states (default/active/success ✓)
- [ ] Progress bar gradient 0/33/67/100 + dots/counter chip
- [ ] Page transition animation (fade+slide 300ms)
- [ ] Lazy load ด้วย `next/dynamic`

### UG-006 · Step content + hero assets
**Layer:** zyra-app + design · **Effort:** M · **Depends:** UG-005
- [ ] Export hero images/screenshots 7 หน้า + logo จาก Figma → upload R2 (`static/onboarding/…`)
- [ ] ใส่ copy ทั้ง 7 หน้า verbatim; Welcome title ใส่ display name จาก user store

### UG-007 · Skip flow — confirmation modal
**Layer:** zyra-app · **Effort:** S · **Depends:** UG-005
- [ ] `onboarding-skip-modal.tsx` (458×332 warning เหลือง) บน overlay ชั้นสอง
- [ ] Cancel → กลับ step เดิม; Yes, Skip → PATCH `skipped` + ปิดทั้งหมด + `markSpotlightPending()`

### UG-008 · Post-skip spotlight + coach-mark
**Layer:** zyra-app · **Effort:** M · **Depends:** UG-007
- [ ] `create-workspace-spotlight.tsx` — เจาะรูรอบปุ่ม Create workspace จริงด้วย `getBoundingClientRect` + tooltip ขาว "Click to start creating a workspace."
- [ ] One-shot ผ่าน sessionStorage; dismiss เมื่อคลิกใดๆ; ทดสอบ resize/scroll

### UG-009 · Success modal + complete flow
**Layer:** zyra-app · **Effort:** S · **Depends:** UG-005
- [ ] `onboarding-success-modal.tsx` — "You're All Set!" / "Back to Workspace"
- [ ] Let's Go! → success; Back to Workspace → PATCH `completed` + ปิด

### UG-010 · Mount + resume gating
**Layer:** zyra-app · **Effort:** S · **Depends:** UG-005, UG-009
- [ ] Render ใน `hero-user-workspace.tsx` เมื่อ `onboarding_status === "pending"` (member เท่านั้น — admin redirect อยู่แล้ว)
- [ ] Login ใหม่ระหว่าง pending → ขึ้น Welcome/0% เสมอ (SC-UG-03); PATCH fail → ปิดได้แต่ยัง pending

### UG-011 · Unit tests — onboarding FE
**Layer:** zyra-app (Vitest) · **Effort:** M · **Depends:** UG-010
- [ ] `lib/onboarding.ts`: status update call, spotlight one-shot helpers (mock `authFetch` — ห้ามยิง API จริง)
- [ ] State machine: Next/Back/Skip/Cancel/complete ครบ happy + alternate paths

---

## Phase 2 — Help Center Articles (SC-UG-04/05)

### UG-012 · Help content data + seed articles
**Layer:** zyra-app · **Effort:** M · **Depends:** —
- [ ] `lib/help-content.ts`: types + `HELP_CATEGORIES` (5 หมวด) + `searchArticles()`
- [ ] เขียนบทความชุดแรก ≥ 8 เรื่อง **จาก flow จริงในโค้ด** (mic/camera, WASD movement, screen share, create workspace, invite member, internet issues, space config, look around) + mark `recommended`/`popular`
- [ ] Unit tests search: case-insensitive, category filter, empty query

### UG-013 · Panel shell + entry point
**Layer:** zyra-app · **Effort:** M · **Depends:** —
- [ ] `views/help-center/help-center-panel.tsx` — 336px docked ขวา + header/tabs/footer + internal route state + slide-in animation
- [ ] ปุ่ม `?` (CircleHelp) ใน `vo-sidebar.tsx` เหนือ Settings — toggle panel

### UG-014 · Main screen (Recommended + Categories)
**Layer:** zyra-app · **Effort:** M · **Depends:** UG-012, UG-013
- [ ] Recommended cards 275w เลื่อนนอน + scrollbar pill; Category grid 5 tiles ตาม tint

### UG-015 · Search results + highlight
**Layer:** zyra-app · **Effort:** M · **Depends:** UG-012, UG-013
- [ ] Live search + `HighlightedText` (match → `#FF8000` + bg 20%)
- [ ] Card 304w มี thumbnail + category label เขียว

### UG-016 · Category list + in-category search
**Layer:** zyra-app · **Effort:** S · **Depends:** UG-014
- [ ] Breadcrumb + "Search in this category..." + list cards (thumb + date) + slim scrollbar

### UG-017 · Article detail + Tips card
**Layer:** zyra-app · **Effort:** M · **Depends:** UG-016
- [ ] Hero 304×140, title/date, body card (เลขเขียว), tips card; back navigation ถูกต้อง (กลับ list/search/main ตามทางเข้า)

### UG-018 · Article feedback (FE + API)
**Layer:** zyra-api + zyra-app · **Effort:** M · **Depends:** UG-017
- [ ] Migration `62_help_article_feedback.sql` + apply
- [ ] `POST /api/user/help/articles/{slug}/feedback` (upsert) + unit tests
- [ ] FE: Helpful/Not helpful → thank-you state; กดได้ครั้งเดียว (local state + server persist)

### UG-019 · Empty state (SC-UG-05)
**Layer:** zyra-app · **Effort:** S · **Depends:** UG-015
- [ ] Illustration 100×100 (export → R2) + "No results found" + query echo
- [ ] Popular Articles card (ลิงก์เขียว → detail)
- [ ] ปุ่ม "Report issue about "{query}"" → เปิด contact form + auto-fill Topic (**รอ UG-026**; ระหว่างนั้น disable/ซ่อน)

### UG-020 · Unit tests — Help Center
**Layer:** zyra-app (Vitest) · **Effort:** M · **Depends:** UG-019
- [ ] Search/highlight/empty branch, feedback single-shot, panel route state

---

## Phase 3 — Contact Support (SC-UG-07/08)

### UG-021 · Migration 61 — support tickets
**Layer:** zyra-api · **Effort:** XS · **Depends:** —
- [ ] `61_support_tickets.sql` (sequence 1000 + table + index) + apply

### UG-022 · SupportService — create/list
**Layer:** zyra-api · **Effort:** L · **Depends:** UG-021
- [ ] `support_service.go`: validation ครบ (type/impact/lengths/file magic-bytes/5MB), R2 upload `support/{userID}/{uuid}.{ext}`, INSERT + ticket code `ZYR-{n}`, rate limit 5/hr/user
- [ ] Sentinel errors + unit tests ทุกกรณี (mock DB, mock S3)

### UG-023 · Support handler + routes
**Layer:** zyra-api · **Effort:** S · **Depends:** UG-022
- [ ] `POST/GET /api/user/support/tickets` ใน user group; multipart bind; list เฉพาะ user ตัวเอง
- [ ] Wiring `main.go` (inject db, s3Client, notifyClient)

### UG-024 · Email templates — zyra-notifications
**Layer:** zyra-notifications · **Effort:** M · **Depends:** —
- [ ] Template `support_ticket_ack` (user) + `support_ticket_new` (admin, มี/ไม่มี Impact + attachment link) ตาม copy ใน `spec.md` SC-UG-08
- [ ] รองรับ Reply-To = user email (ตรวจ/เพิ่มใน service)
- [ ] Env `SUPPORT_EMAIL` ใน zyra-api config + deploy env (แก้ env: block ใน GitHub Actions workflow — ดู memory deploy pipeline)

### UG-025 · Email trigger ใน SupportService
**Layer:** zyra-api · **Effort:** S · **Depends:** UG-022, UG-024
- [ ] `TemplateSupportAck`/`TemplateSupportNew` constants + `SendAsync` หลังสร้าง ticket (nil-safe, ไม่ block)
- [ ] Unit test: email params ถูกต้องตาม contact_type (Impact เฉพาะ bug)

### UG-026 · FE — Contact Support form
**Layer:** zyra-app · **Effort:** L · **Depends:** UG-013, UG-023
- [ ] `contact-support-form.tsx`: info banner (browser/OS จริงจาก userAgent), Contact Type dropdown 4 options, Impact (bug เท่านั้น), Topic/Subject + Description + counters, per-type placeholders
- [ ] Contact Support variant: send-to strip + Subject label + ไม่มี attachments
- [ ] Send disabled → enabled; submit ผ่าน `createSupportTicket` (FormData); double-submit guard

### UG-027 · FE — Attachment upload UX
**Layer:** zyra-app · **Effort:** M · **Depends:** UG-026
- [ ] Drop area → file picker; ตรวจ type/ขนาด client-side; uploaded card (ชื่อ+size+Completed+ลบ); error toast "Upload failed"

### UG-028 · FE — My Tickets
**Layer:** zyra-app · **Effort:** S · **Depends:** UG-023
- [ ] `my-tickets-list.tsx` — TanStack Query `["support-tickets"]`; History cards; empty state
- [ ] หลัง send: สลับ tab + success toast + invalidate

### UG-029 · เชื่อม SC-UG-05 → form
**Layer:** zyra-app · **Effort:** XS · **Depends:** UG-019, UG-026
- [ ] "Report issue about..." เปิด form + Topic auto-fill `Cannot find "{query}" in Articles` (truncate ≤100)

### UG-030 · Unit tests — support FE
**Layer:** zyra-app (Vitest) · **Effort:** M · **Depends:** UG-026~029
- [ ] Form validation ต่อ type, FormData payload, toast flows (mock lib — ห้ามยิง API จริง)

### UG-031 · API tests — support endpoints
**Layer:** zyra-api · **Effort:** S · **Depends:** UG-023
- [ ] Endpoint coverage: 201/400/413-เกินขนาด/403 ข้าม user/rate limit

---

## Phase 4 — Feature Walkthrough (SC-UG-06)

### UG-032 · Tour framework
**Layer:** zyra-app · **Effort:** S · **Depends:** —
- [ ] `lib/feature-tours.ts`: `FeatureTour` type + `ACTIVE_TOURS` + seen helpers (localStorage ต่อ user ต่อ tour — pattern `avatar-selection.ts`)

### UG-033 · Walkthrough modal
**Layer:** zyra-app · **Effort:** M · **Depends:** UG-032
- [ ] `feature-tour-modal.tsx` — 600w carousel: step badge, Skip tour, hero, tag/byline, dots, Back/Next/Let's Go! + transition
- [ ] Success modal (Back to Office) — reuse shell 458×332 จาก Phase 1

### UG-034 · Mount ใน VO + seen gating
**Layer:** zyra-app · **Effort:** S · **Depends:** UG-033
- [ ] Mount ใน `hero-virtual-office.tsx`; แสดง tour แรกที่ยังไม่ seen; skip/จบ → mark seen; ห้ามชนกับ onboarding (onboarding มาก่อน)

### UG-035 · Unit tests — tour
**Layer:** zyra-app (Vitest) · **Effort:** S · **Depends:** UG-034
- [ ] Seen persistence, step navigation, ACTIVE_TOURS ว่าง = ไม่ render

---

## Phase 5 — E2E & Polish

### UG-036 · E2E — onboarding journeys (Playwright)
**Effort:** M — complete ครบ step / skip+spotlight / resume หลัง re-login (reset flag ผ่าน SQL)

### UG-037 · E2E — help center + support
**Effort:** M — เปิด panel, search+highlight, detail+feedback, empty state → report → send → My Tickets + toast

### UG-038 · Visual/UX polish pass
**Effort:** S — เทียบ Figma ทุกหน้าจอ (spacing/สี/typography 95-100%), dark viewport เดียว, `npx tsc --noEmit` + `npm run lint` ผ่าน

### UG-039 · Docs + ClickUp
**Effort:** XS — อัปเดต usage notes ลง `zyra-doc/plan/UserGuide/`; คอมเมนต์สรุปใน ClickUp tasks (ห้ามเปลี่ยน status — PM/QA เท่านั้น)

---

## Dependencies นอกทีม dev

| # | รายการ | Blocker ของ |
|---|---|---|
| 1 | คำตอบ Open Questions Q1-Q16 (ดู `spec.md`) | UG-005 (Q1-Q3), UG-008 (Q4), UG-024 (Q11) |
| 2 | Figma assets export (hero images, illustrations) | UG-006, UG-019, UG-033 |
| 3 | Support inbox address จริง | UG-024 |
| 4 | เนื้อหาบทความ (ทีม product ตรวจภาษา) | UG-012 |
