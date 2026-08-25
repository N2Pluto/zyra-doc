# Technical Design — User Guide Module

**Version:** 1.0 · **Date:** 2026-07-14
**Scope:** SC-UG-01 ~ SC-UG-08
**Depends on:** zyra-api (Go/Gin), zyra-app (Next.js 16), zyra-notifications (Go, email), Cloudflare R2
**Refs:** `spec.md` · `ux-ui-plan.md` · `figma-nodes.md`

---

## 0. Design Decisions (สรุปก่อน)

| เรื่อง | ตัดสินใจ | เหตุผล |
|---|---|---|
| Onboarding state | คอลัมน์ใหม่ใน `tb_user`: `onboarding_status` (`pending`/`skipped`/`completed`) — expose ผ่าน `GET /api/user/me`, เขียนผ่าน `PATCH /api/user/me/onboarding` | ต้อง survive ข้าม device/login (SC-UG-03) — localStorage อย่างเดียวไม่พอ; pattern เดียวกับ `PATCH /me/status` ที่มีอยู่ |
| Onboarding resume position (revised 2026-07-16) | คอลัมน์เพิ่ม `onboarding_page_index` (migration 67) — เขียนผ่าน `PATCH /api/user/me/onboarding/progress` ทุกครั้งที่ Next/Back; reset กลับ 0 เมื่อ status เปลี่ยนเป็น skipped/completed | เดิมตัดสินใจ restart ที่ Welcome/0% เสมอ (sticky note) — issue report ใหม่ขอให้ resume จาก step ที่ค้างไว้จริง; เลือก server-side (ไม่ใช่ localStorage) ให้ survive ข้าม device เหมือน onboarding_status |
| Post-skip spotlight (one-shot) | `sessionStorage` flag ฝั่ง client | เป็น UI ครั้งเดียวหลัง Yes, Skip ใน session นั้น ไม่ต้อง persist ถาวร |
| Help articles | **v1 = static content ใน frontend** (`lib/help-content.ts`) ค้นหา client-side | ไม่มี CMS/admin requirement ใน design; บทความคือคู่มือของ flow ที่เปลี่ยนพร้อมโค้ด — เก็บใน repo review ง่าย; type ออกแบบให้สลับไป API ได้ (ดู §5.1) |
| Article feedback | persist ฝั่ง server: `tb_help_article_feedback` (unique ต่อ user+slug) | ทีมอยากรู้ว่าบทความไหนไม่ช่วย; payload เล็ก |
| Support ticket | `tb_support_ticket` + `POST/GET /api/user/support/tickets`; attachment ขึ้น R2; email 2 ฉบับผ่าน zyra-notifications (async) | ตาม design (My Tickets = persistence) + rule 11 (S3 only) + email boundary จริง |
| Ticket code | `ZYR-{running number}` จาก sequence เริ่ม 1000 | ตรงรูปแบบ `#ZYR-1094` ใน design |
| Feature walkthrough (UG-06) | data-driven config ใน frontend (`lib/feature-tours.ts`) + seen-state ใน localStorage ต่อ user ต่อ tour id | ยังไม่มี announcement backend; ย้ายเป็น server-driven ได้ภายหลังโดย interface เดิม |
| UI stack | Tailwind-only (rule 08), lucide-react (rule 12), `zyraToast`, hand-rolled modal/panel ตาม pattern chat side-panels | ตาม rules + โค้ดจริง |

---

## 1. System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                       zyra-app (Next.js)                            │
│                                                                     │
│  views/onboarding/ (NEW)        views/help-center/ (NEW)            │
│  ├── onboarding-modal.tsx       ├── help-center-panel.tsx           │
│  ├── onboarding-skip-modal.tsx  ├── article-search / category /     │
│  ├── onboarding-success-modal   │   article-detail / empty-state    │
│  └── create-workspace-spotlight ├── contact-support-form.tsx        │
│                                 └── my-tickets-panel.tsx            │
│  views/feature-tour/ (NEW)                                          │
│  └── feature-tour-modal.tsx                                         │
│                                                                     │
│  lib/onboarding.ts (NEW)   lib/help-content.ts (NEW, static data)   │
│  lib/feature-tours.ts (NEW)                                         │
│  lib/api/support.ts (NEW)  lib/api/profile.ts (+onboarding_status)  │
└──────────────────────────┬─────────────────────────────────────────┘
                           │ REST (authFetch — lib/api/client.ts)
                           ▼
┌───────────────────────────────────────────┐
│  zyra-api :3001 (Gin + PostgreSQL)         │
│  /api/user/me                (+ field)     │
│  /api/user/me/onboarding     PATCH (NEW)   │
│  /api/user/support/tickets   POST/GET (NEW)│
│  /api/user/help/articles/:slug/feedback    │
│                              POST (NEW)    │
│                                            │
│  internal/service/support_service.go (NEW) │
│  internal/service/profile_service.go (+)   │
└───────┬──────────────────┬─────────────────┘
        │                  │ notify.Client (POST /v1/email)
        ▼                  ▼
┌───────────────┐  ┌──────────────────────────┐   ┌────────────────┐
│ PostgreSQL    │  │ zyra-notifications :3003  │   │ Cloudflare R2  │
│ tb_user (+col)│  │ templates (NEW):          │   │ support/{uid}/ │
│ tb_support_   │  │  support_ticket_ack       │   │  {uuid}.png    │
│   ticket      │  │  support_ticket_new       │   └────────────────┘
│ tb_help_      │  └──────────────────────────┘
│   article_    │
│   feedback    │
└───────────────┘
```

zyra-ws / zyra-sfu **ไม่เกี่ยว** กับ module นี้ (ไม่มี realtime requirement)

---

## 2. Database (zyra-api/migrations — apply เอง ไม่ auto-run)

> Migration ล่าสุด = `59_map_object_fractional_tiles.sql` → เริ่มที่ **60**
> หมายเหตุ: `tb_user.id` เป็น **VARCHAR** (ไม่ใช่ UUID) — FK ต้องเป็น VARCHAR

### `60_user_onboarding.sql`

```sql
-- onboarding status: pending | skipped | completed
ALTER TABLE tb_user
    ADD COLUMN IF NOT EXISTS onboarding_status VARCHAR(16) NOT NULL DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS onboarding_updated_at TIMESTAMPTZ;

-- ผู้ใช้เดิมทั้งหมดถือว่าผ่านแล้ว — ไม่เด้ง tutorial ใส่คนเก่า
UPDATE tb_user SET onboarding_status = 'completed', onboarding_updated_at = NOW();
```

### `61_support_tickets.sql`

```sql
CREATE SEQUENCE IF NOT EXISTS support_ticket_no_seq START 1000;

CREATE TABLE IF NOT EXISTS tb_support_ticket (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_no     BIGINT NOT NULL DEFAULT nextval('support_ticket_no_seq'),
    user_id       VARCHAR NOT NULL REFERENCES tb_user(id),
    contact_type  VARCHAR(32)  NOT NULL,  -- bug_report | feature_request | general_feedback | contact_support
    impact        VARCHAR(64),            -- bug_report เท่านั้น
    topic         VARCHAR(100) NOT NULL,  -- = Subject เมื่อ contact_support
    description   VARCHAR(1000) NOT NULL,
    attachment_url TEXT,                  -- R2 public URL
    page_url      TEXT,
    browser       VARCHAR(128),
    os            VARCHAR(128),
    status        VARCHAR(16) NOT NULL DEFAULT 'open',  -- open | resolved (v1 ยังไม่มี UI เปลี่ยน)
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_support_ticket_user ON tb_support_ticket (user_id, created_at DESC);
```

Ticket code แสดงผล = `'ZYR-' || ticket_no` (สร้างใน service ไม่เก็บซ้ำใน DB)

### `62_help_article_feedback.sql`

```sql
CREATE TABLE IF NOT EXISTS tb_help_article_feedback (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      VARCHAR NOT NULL REFERENCES tb_user(id),
    article_slug VARCHAR(128) NOT NULL,
    helpful      BOOLEAN NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, article_slug)
);
```

### `67_onboarding_progress.sql` (added 2026-07-16 — SC-UG-03 resume revision)

> Migration ล่าสุดตอนนี้ = `66_join_token_group_config.sql` → ตัวนี้คือ **67**

```sql
-- 0-based index into zyra-app ONBOARDING_PAGES (0..6) — resume position
ALTER TABLE tb_user ADD COLUMN IF NOT EXISTS onboarding_page_index SMALLINT NOT NULL DEFAULT 0;
```

---

## 3. API Contracts (ทั้งหมดใต้ `/api/user/*` — UserGuard, rule 15)

ทุก endpoint ตอบ envelope `{status, message, data}` ตาม convention ที่ `authFetch` ฝั่ง frontend คาดหวัง

### 3.1 Onboarding

**`GET /api/user/me`** (มีอยู่แล้ว — เพิ่ม field)
```json
{ "data": { ..., "onboarding_status": "pending", "onboarding_page_index": 2 } }
```

**`PATCH /api/user/me/onboarding`** (NEW — pattern เดียวกับ `PATCH /me/status`)
```json
// request
{ "status": "skipped" }        // "skipped" | "completed" เท่านั้น
// 400 ถ้าค่าอื่น; idempotent (ยิงซ้ำได้)
// response
{ "status": 200, "message": "success", "data": { "onboarding_status": "skipped" } }
```
> ไม่มีทางกลับเป็น `pending` ผ่าน API (one-way) — reset ได้เฉพาะ DB โดยตรง (dev/test); การเรียกนี้ reset `onboarding_page_index` กลับ 0 ด้วยเสมอ

**`PATCH /api/user/me/onboarding/progress`** (NEW 2026-07-16 — SC-UG-03 resume revision)
```json
// request
{ "page_index": 2 }   // 0..6, validated server-side against ONBOARDING_PAGES length
// response
{ "status": 200, "message": "success", "data": { "onboarding_page_index": 2 } }
```
> ยิงทุกครั้งที่กด Next/Back ระหว่าง `pending` — ไม่แตะ `onboarding_status`; fail-safe เดียวกับ endpoint ด้านบน (ถ้า PATCH fail ผู้ใช้ยัง Next/Back ต่อได้ตามปกติ แค่ resume position อาจตกไปที่ step ก่อนหน้า)

### 3.2 Support tickets

**`POST /api/user/support/tickets`** (NEW) — `multipart/form-data` (FormData pattern ตาม rule 02)

| field | type | rule |
|---|---|---|
| `contact_type` | string | required — `bug_report`/`feature_request`/`general_feedback`/`contact_support` |
| `impact` | string | required เมื่อ `bug_report`; ห้ามส่งเมื่อ type อื่น |
| `topic` | string | required, ≤100 |
| `description` | string | required, ≤1,000 |
| `page_url`, `browser`, `os` | string | client เก็บอัตโนมัติ (banner "auto-attach") |
| `attachment` | file | optional; JPG/PNG; ≤ 5MB; ห้ามเมื่อ `contact_support` |

Server-side validation ซ้ำทุกข้อ (service layer) — ไม่เชื่อ client
```json
// response 201
{ "status": 201, "message": "success",
  "data": { "id": "…uuid…", "ticket_code": "ZYR-1094", "created_at": "…" } }
```

**`GET /api/user/support/tickets`** (NEW) — list ของ user ตัวเอง, ล่าสุดก่อน
```json
{ "data": { "tickets": [
  { "id": "…", "ticket_code": "ZYR-1094", "topic": "Bug can't walk",
    "contact_type": "bug_report", "status": "open", "created_at": "…" }
] } }
```

### 3.3 Article feedback

**`POST /api/user/help/articles/{slug}/feedback`** (NEW)
```json
// request
{ "helpful": true }
// upsert (unique user+slug); response 200 {data:{article_slug, helpful}}
```

---

## 4. zyra-api Implementation

### 4.1 Files

| File | งาน |
|---|---|
| `internal/model/support.go` (NEW) | `SupportTicket`, request/response structs |
| `internal/service/support_service.go` (NEW) | create/list ticket, validation, R2 upload, email trigger, sentinel errors |
| `internal/handler/support_handler.go` (NEW) | bind multipart, call service |
| `internal/service/profile_service.go` (แก้) | `UpdateOnboardingStatus(ctx, userID, status)`; `UpdateOnboardingProgress(ctx, userID, pageIndex)` (NEW 2026-07-16); เพิ่ม `onboarding_status`/`onboarding_page_index` ใน query `GET /me` (auth_service.go findUserByID/Email* + register/forgot-password services ที่ใช้ scanUser ร่วมกัน) |
| `internal/handler/profile_handler.go` (แก้) | `PATCH /me/onboarding`, `PATCH /me/onboarding/progress` (NEW) |
| `internal/service/help_service.go` (NEW) | article feedback upsert |
| `internal/router/router.go` (แก้) | routes ใหม่ใน user group + wiring ใน `main.go` |
| `internal/notify/client.go` (แก้) | เพิ่ม `TemplateSupportAck`, `TemplateSupportNew` |

### 4.2 SupportService — โครง

```go
var (
    ErrInvalidContactType = errors.New("invalid contact type")
    ErrTopicTooLong       = errors.New("topic exceeds 100 characters")
    ErrDescriptionTooLong = errors.New("description exceeds 1000 characters")
    ErrAttachmentTooLarge = errors.New("attachment exceeds 5MB")
    ErrAttachmentType     = errors.New("attachment must be JPG or PNG")
)

type SupportService struct {
    cfg    *config.Config
    db     *pgxpool.Pool
    s3     *storage.S3Client // nil → attachment ไม่ได้ (return error เฉพาะเมื่อมีไฟล์)
    notify *notify.Client    // nil → no-op (ไม่ block การสร้าง ticket)
}

func (s *SupportService) CreateTicket(ctx context.Context, in CreateTicketInput) (*SupportTicket, error) {
    // 1. validate (type/impact/lengths/file)
    // 2. ถ้ามีไฟล์: s3.UploadPNG/UploadJPEG key = fmt.Sprintf("support/%s/%s%s", in.UserID, uuid.New(), ext)
    // 3. INSERT ... RETURNING id, ticket_no, created_at (tx + defer tx.Rollback(ctx))
    // 4. code := fmt.Sprintf("ZYR-%d", ticketNo)
    // 5. s.sendEmails(ticket)  // SendAsync — ห้าม block
    return t, nil
}
```

### 4.3 Email (zyra-notifications)

Template ใหม่ 2 ตัว (เพิ่มทั้ง constant ใน `notify/client.go` และ template จริงใน zyra-notifications):

| Template | To | Params |
|---|---|---|
| `support_ticket_ack` | user email | `user_name, ticket_code, topic, description, app_url, contact_email` — subject `We've received your message! (Ticket #{ticket_code})`, CTA "Visit Help Center" → `{app_url}` |
| `support_ticket_new` | `cfg.SupportEmail` (env ใหม่ `SUPPORT_EMAIL`) | `user_name, user_email, ticket_code, topic, impact (optional), description, submitted_at, os_browser, attachment_url (optional)` — subject `[New Ticket] {topic} - {user_name} (Ticket #{ticket_code})`, CTA "Reply to User" → `mailto:{user_email}` |

หมายเหตุจาก design: "From" ใน mockup admin email เป็น gmail ของ user — ของจริงส่งจากระบบ + ตั้ง **Reply-To = user email** (zyra-notifications ต้องรองรับ reply-to ถ้ายังไม่มี — ตรวจตอน implement)
Reply templates 4 แบบใน Figma = playbook ของทีม support, **ไม่ build**

### 4.4 Env ใหม่

```env
SUPPORT_EMAIL=support@zyra.app   # inbox ทีม support — PM ยืนยัน address จริง (spec Q11)
```

---

## 5. zyra-app Implementation

### 5.1 Help content (static v1, API-ready)

```ts
// lib/help-content.ts
export interface HelpArticle {
  slug: string            // stable id — ใช้กับ feedback API
  category: HelpCategoryId
  title: string
  thumbnail?: string      // R2 URL
  heroImage?: string
  updatedAt: string       // ISO — render เป็น "Oct 24, 2026"
  intro: string
  steps: string[]         // เลขเขียวใน body card
  tips?: string
  recommended?: boolean   // "Recommended for you"
  popular?: boolean       // "Popular Articles" ใน empty state
}
export const HELP_CATEGORIES = [
  { id: "getting-started", label: "Getting Started", tint: "#2DB6FF" },
  { id: "virtual-office",  label: "Virtual Office",  tint: "#58D68D" },
  { id: "account",         label: "Account",         tint: "#996ADF" },
  { id: "chat",            label: "Chat",            tint: "#2C5AE4" },
  { id: "billing",         label: "Billing",         tint: "#FF8000" },
] as const
export function searchArticles(q: string, category?: HelpCategoryId): HelpArticle[] { … }
```
- ค้นหา: case-insensitive substring บน title (+ category filter); highlight ทำใน component โดย split ตำแหน่ง match
- ถ้าย้ายเป็น backend ในอนาคต: แทน `searchArticles` ด้วย TanStack Query fetch — interface component ไม่เปลี่ยน
- **เนื้อหาบทความชุดแรกต้องเขียนจาก flow จริง** (ดูตาราง "Existing Flows" ใน `spec.md`) — อย่างน้อย: enable mic/camera, movement (WASD), screen share, create workspace, invite member, internet troubleshooting, basic space configuration

### 5.2 Onboarding

| File | งาน |
|---|---|
| `lib/onboarding.ts` (NEW) | `ONBOARDING_TABS` config (tab id, icon, pages[title, body, image]); `updateOnboardingStatus(status)` → `PATCH /api/user/me/onboarding`; `updateOnboardingProgress(pageIndex)` (NEW 2026-07-16) → `PATCH /api/user/me/onboarding/progress`; `clampPageIndex()` guards a stale/out-of-range resume value; sessionStorage helper `markSpotlightPending()/consumeSpotlight()` |
| `views/onboarding/onboarding-modal.tsx` (NEW) | shell 900×600: sidebar (tabs + progress) + content pane; state `{pageIndex}` seeded from `initialPageIndex` prop (`clampPageIndex(profile.onboarding_page_index)`); Next/Back → `goToPage()` updates state + fires `updateOnboardingProgress` (fire-and-forget); Skip → skip modal |
| `views/onboarding/components/onboarding-skip-modal.tsx` | confirmation (warning เหลือง) — Cancel / Yes, Skip |
| `views/onboarding/components/onboarding-success-modal.tsx` | "You're All Set!" — Back to Workspace |
| `views/onboarding/components/create-workspace-spotlight.tsx` | overlay เจาะรู (CSS `box-shadow: 0 0 0 9999px rgba(0,0,0,0.5)` บน absolute rect ทับตำแหน่งปุ่มจริงจาก `getBoundingClientRect`) + tooltip ขาว |

**Mount point:** ใน `views/user/workspace/hero-user-workspace.tsx` — render `<OnboardingModal initialPageIndex={profile.onboarding_page_index} />` เมื่อ `profile.onboarding_status === "pending"` (โหลดจาก `getProfile()` React Query cache `["profile-onboarding"]` / user store; admin ถูก redirect ออกไปก่อนแล้ว). **Gotcha ที่แก้ 2026-07-16**: คิวรี่นี้ตั้ง `staleTime: Infinity` และไม่เคย invalidate — `handleOnboardingClose` ต้อง `queryClient.setQueryData(["profile-onboarding"], …)` เขียนสถานะใหม่ด้วย ไม่งั้น remount (เช่นกลับมาหน้า workspace list หลังจบ tutorial) จะยังอ่านค่า `onboarding_status: "pending"` เก่าจาก cache แล้วเด้ง modal ซ้ำ

**State transitions:**
```
pending ──(Yes, Skip)──▶ skipped     + markSpotlightPending() → spotlight one-shot; onboarding_page_index reset → 0
pending ──(Let's Go!)──▶ completed   (patch ยิงทันทีที่กด Let's Go!, ไม่ใช่ตอน Back to Workspace); onboarding_page_index reset → 0
pending ──(ปิด browser / หลุด)──▶ ยัง pending → login ใหม่ resume ที่ onboarding_page_index ล่าสุด (revised SC-UG-03, เดิม restart ที่ Welcome/0%)
```
- Status PATCH ยิงตอนกด **Yes, Skip** / **Let's Go!**; Progress PATCH ยิงทุกครั้งที่กด **Next/Back** (ไม่แตะ status). ถ้า PATCH ใดล้มเหลว → ปิด/นำทางต่อได้ตามปกติ เป็น fire-and-forget fail-safe (status ค้าง pending หรือ resume position ตกไปที่ step ก่อนหน้า — ไม่ block UX)
- แสดงชื่อใน Welcome จาก user store (`StoredUser.name`)

### 5.3 Help Center + Support

| File | งาน |
|---|---|
| `views/help-center/help-center-panel.tsx` (NEW) | panel shell 336px docked ขวา; internal route state: `main / search / category / detail / notFound / contactForm / myTickets`; header + tabs + footer |
| `views/help-center/components/…` | `recommended-cards.tsx`, `category-grid.tsx`, `article-list.tsx`, `article-detail.tsx` (+feedback state), `search-results.tsx` (+`HighlightedText`), `search-empty-state.tsx`, `contact-support-form.tsx`, `my-tickets-list.tsx` |
| `lib/api/support.ts` (NEW) | `createSupportTicket(FormData)`, `listSupportTickets()`, `sendArticleFeedback(slug, helpful)` — ผ่าน `authFetch` |

**Entry point:** เพิ่มปุ่ม `?` (lucide `CircleHelp`) ใน `views/user/virtual-office/components/vo-sidebar.tsx` เหนือปุ่ม Settings — toggle panel (pattern เดียวกับ member/notification panels ที่มีอยู่)

**Contact form details:**
- Metadata: `page_url = window.location.href`, `browser`/`os` parse จาก `navigator.userAgent` (แสดงใน banner ตามจริง ไม่ hardcode "Chrome")
- Validation client: disable Send จนครบ required; นับ counter; ตรวจไฟล์ก่อน upload (type + size → `zyraToast.errorWithTitle("Upload failed", "The selected file exceeds the 5 MB size limit.")`)
- Success: `zyraToast.successWithTitle("Message sent! Ticket ID #"+code, "We'll review and respond within 24 hours.")` + สลับไป tab My Tickets + invalidate query `["support-tickets"]`
- TanStack Query: `["support-tickets"]` สำหรับ My Tickets list

### 5.4 Feature Tour (UG-06)

```ts
// lib/feature-tours.ts
export interface FeatureTour {
  id: string              // e.g. "virtual-pets-2026-07" — seen key
  tag: string             // "Virtual Pets"
  author: string          // "Zyra Product Team"
  date: string
  steps: { title: string; body: string; image: string }[]
}
export const ACTIVE_TOURS: FeatureTour[] = []   // ว่าง = ไม่แสดงอะไร; Virtual Pets เป็น example ใน test เท่านั้น
// seen: localStorage `zyra_feature_tour_${tourId}_${userId}` (pattern เดียวกับ lib/avatar-selection.ts)
```
- `views/feature-tour/feature-tour-modal.tsx` — carousel modal 600px ตาม spec; mount ใน `hero-virtual-office.tsx` เมื่อมี tour ที่ยังไม่ seen
- Server-driven announcements = future phase (ถ้า PM ต้องการสร้าง announcement โดยไม่ deploy)

### 5.5 สิ่งที่ **ไม่ต้อง**แก้

- `PUBLIC_PATHS` (proxy.ts + auth-guard.tsx) — ไม่มี route/page ใหม่ ทุกอย่างเป็น component ใน page เดิมที่ protected อยู่แล้ว
- zyra-ws / PixiGameScene — ไม่แตะ engine

---

## 6. Error Handling & Edge Cases

| Case | พฤติกรรม |
|---|---|
| PATCH onboarding fail (network) | ปิด modal ได้ปกติ; status ยัง pending → เด้งใหม่ครั้งหน้า (ยอมรับได้ตาม SC-UG-03) |
| Upload fail / เกิน 5MB / ผิด type | ตรวจ client ก่อน (toast error, ไม่ส่ง request); server ตรวจซ้ำ → 400 + message |
| S3 ไม่ config (`s3 == nil`) + มีไฟล์แนบ | 503 "image storage not configured" (pattern เดิมของ profile upload) |
| notify.Client nil / email fail | ticket สร้างสำเร็จเสมอ (email เป็น SendAsync + no-op เมื่อ nil) — log warning |
| ค้นหา query ว่าง | กลับสู่หน้า main (ไม่ใช่ empty state) |
| Topic auto-fill ยาวเกิน 100 | truncate query ให้ template `Cannot find "…" in Articles` รวมแล้ว ≤ 100 |
| Double-submit Send | disable ปุ่มระหว่าง pending (mutation isPending) |
| หลาย tab เปิดพร้อมกัน | last-write-wins ที่ `onboarding_status` — ไม่มีปัญหา (one-way transition) |

## 7. Security

- ทุก endpoint ใหม่อยู่ใต้ UserGuard; `GET /support/tickets` filter `user_id = ctx user` เสมอ (ห้าม parameter ระบุ user อื่น)
- SQL parameterized (`$1, $2`) ทุก query
- ห้าม log description/email เต็ม ๆ (PII) — log แค่ ticket id + user id
- Attachment: ตรวจ magic bytes/`Content-Type` ฝั่ง server ไม่ใช่แค่นามสกุล; จำกัด 5MB ที่ multipart reader
- Rate limit การสร้าง ticket: ≤ 5/ชั่วโมง/user (กัน spam ไป support inbox) — เช็คใน service ด้วย query count

## 8. Performance

- Help content เป็น static import — ไม่มี network cost; search เป็น O(n) บน array เล็ก (<100 บทความ)
- Onboarding modal โหลด lazy (`next/dynamic`) — ไม่เพิ่ม bundle ให้ user ที่จบ onboarding แล้ว
- รูปทั้งหมดผ่าน `next/image` + R2 public URL
