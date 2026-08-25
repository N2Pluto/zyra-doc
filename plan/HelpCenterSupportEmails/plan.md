# Help Center — Support Emails: Field Fixes + Admin Reply

Status: **approved — open questions resolved below, ready for implementation**
Repos touched: `zyra-api`, `zyra-notifications`, `zyra-app`

---

## Part A — Fix missing fields in the 2 existing automatic support emails

### What

**User story:** As the recipient of either automatic support email (the admin
support-inbox alert, or the end-user acknowledgement), I want to see the
ticket's **Contact Type** always, and its **Impact** whenever the ticket is a
Bug Report, so I have full context without opening the app.

**Acceptance criteria**

- [ ] Support-inbox email ("New Ticket", `TemplateSupportNew`) shows a
      **Contact Type** row for all 4 contact types, with a human label (not
      the raw `bug_report` string).
- [ ] Support-inbox email shows an **Impact** row when — and only when —
      `contact_type = bug_report` (already partially working; verify label
      wording matches the new Contact Type row style).
- [ ] User-ack email ("We've received your message", `TemplateSupportAck`)
      shows the same **Contact Type** row for all 4 types.
- [ ] User-ack email shows the same **Impact** row when `contact_type =
      bug_report`, matching the inbox email's condition.
- [ ] Contact Type display labels match `zyra-app/messages/en.json` (lines
      ~2604-2607): "Report an Issue (Bug Report)", "Suggest a Feature
      (Feature Request)", "General Feedback", "Contact Support".
- [ ] No other visual/layout change to either email (reuse existing
      `emailCardOpen`/`emailCardClose`/`bodyRow`/summary-box chrome).
- [ ] Existing tests + any new template unit tests pass.

### Where

| File | Change |
|---|---|
| `zyra-api/internal/service/support_service.go` | Ack-email params builder (inside `sendEmails`, ~line 271-289) currently omits `contact_type` and `impact` — add both keys to the `params` map, same as `buildSupportInboxParams` already does. |
| `zyra-notifications/internal/mailer/mailer.go` (~lines 302-324) | `case TemplateSupportAck`: read new `contact_type` / `impact` via `get(...)`, pass to `buildSupportAckEmailHTML`. `case TemplateSupportNew`: already reads `impact`; add read of `contact_type`, pass to `buildSupportNewEmailHTML`. |
| `zyra-notifications/internal/mailer/templates.go` (~lines 877-950) | `buildSupportAckEmailHTML` and `buildSupportNewEmailHTML` signatures gain a `contactType string` param; add a "Contact Type" row (always) and keep/add an "Impact" row (bug_report only) in each. Add a small `contactTypeLabel(raw string) string` helper mapping the 4 raw values → display label (mirrors `en.json`), used by both builders. |
| `zyra-notifications/internal/mailer/templates_test.go` (or new test file, if one doesn't already exist for support templates) | Table-driven tests per `.claude/rules/04-test.md`: all 4 contact types render the Contact Type row; impact row present only for `bug_report`; empty/unknown contact_type falls back gracefully (no raw string leaked to the customer-facing email). |

No `zyra-app` changes are needed for Part A — these are backend-only template/param fixes; the raw `contact_type` values already exist in `tb_support_ticket` and are already threaded through `SupportService`/handlers, just not into the ack-email params.

### API Contract

No new/changed HTTP endpoints. Internal contract that changes:

- `zyra-api` → `zyra-notifications` `POST /v1/email` payload (`params` map)
  gains a `contact_type` key for `TemplateSupportAck` (already present for
  `TemplateSupportNew`, just not read on the notifications side).
- Function signatures inside `zyra-notifications` only (`buildSupportAckEmailHTML`,
  `buildSupportNewEmailHTML`) — not a network contract, but listed here since
  callers in `mailer.go` must be updated in the same PR.

### DB Impact

**None.** `contact_type` and `impact` already exist as columns on
`tb_support_ticket` (migration 61) and are already read into
`model.SupportTicket` / `buildSupportInboxParams`. This is a template +
params-plumbing fix only.

### Task Breakdown — Part A

1. `feat(api): pass contact_type + impact into support-ack email params`
   — edit `support_service.go` `sendEmails()` ack-email params map only.
2. `feat(notifications): add contact-type label + impact row to support emails`
   — `templates.go`: add `contactTypeLabel()` helper + Contact Type/Impact
   rows in both `buildSupportAckEmailHTML` and `buildSupportNewEmailHTML`;
   `mailer.go`: read `contact_type` in both switch cases, thread through.
3. `test(notifications): table-driven tests for support email contact-type/impact rows`
   — cover all 4 contact types × presence/absence of impact, for both templates.

---

## Part B — Admin "Reply to Ticket" feature (new)

### What

**User story:** As an admin, I want to see all support tickets submitted by
users, open one, and send a reply email back to the submitter using one of 4
contact-type-specific starting templates, so I can close the loop on support
requests without leaving the app or using a separate mail client.

**Acceptance criteria (v1 scope — see Open Questions for exact boundaries)**

- [ ] New admin nav entry ("Support" or "Tickets") in `AdminSidebar`.
- [ ] Admin list page: all tickets across all users, newest first, showing
      ticket code, contact type, topic, status, submitted-by, created_at.
- [ ] Admin ticket-detail view: full ticket fields (topic, description,
      impact, attachment, submitter, page/browser/os) + a "Reply" action.
- [ ] Reply modal: admin picks a template based on the ticket's contact type
      (or the modal auto-selects it since contact_type is already known),
      pre-fills subject + body from the matching Figma copy, admin can edit
      the body before sending (see Open Questions — confirm free-edit vs
      canned-only).
- [ ] On send: an email is dispatched to the ticket submitter using the
      selected template; the reply (or at least that a reply happened) is
      recorded against the ticket so the admin list/detail can show
      "Replied" state and avoid confusion about whether a ticket was already
      handled.
- [ ] Only permitted admins (new RBAC permission key, see below) can view
      the list/detail or send replies.

### Where

| File | Change |
|---|---|
| `zyra-api/internal/model/support.go` | Add reply-related fields to `SupportTicket` (e.g. `RepliedAt *time.Time`, `RepliedBy *string`) and a small `SupportReplyInput` struct. |
| `zyra-api/internal/service/support_service.go` | New methods: `ListAllTickets(ctx, filter)` (admin, no `user_id` filter), `GetTicket(ctx, ticketID)`, `ReplyToTicket(ctx, ticketID, adminID, templateKind, subject, body)`. Reuses `lookupUser`/email-send plumbing already in this file. |
| `zyra-api/internal/handler/support_handler.go` (or new `support_admin_handler.go`, matching the existing `user_admin_lifecycle_handler.go` split pattern) | New handlers: `AdminList`, `AdminGet`, `AdminReply` — modeled directly on `user_admin_lifecycle_handler.go`'s `suspend()` pattern (bind → service call → look up email → `h.notify.SendAsync(...)` → JSON response). |
| `zyra-api/internal/router/router.go` | New `admin.Group("/support")` alongside the other admin groups (~line 471 area), gated with `middleware.RequirePermission`. |
| `zyra-api/internal/rbac/catalog.go` | New permission key(s), e.g. `PermAdminSupportRead = "admin.support.read"` and `PermAdminSupportReply = "admin.support.reply"` (`DependsOn: [PermAdminSupportRead]`), new category `CatSupport` or grouped under existing `CatContentManagement` (confirm with user/PM which nav category this belongs under). |
| `zyra-api/internal/notify/client.go` | 4 new template constants, one per contact type (see API Contract below). |
| `zyra-notifications/internal/mailer/templates.go` | 4 new `buildSupportReply<Type>EmailHTML(...)` functions (or one shared `buildSupportReplyEmailHTML(kind, ...)`), reusing `emailCardOpen`/`emailCardClose`/`bodyRow`. Copy sourced from the 4 Figma designs already fetched. |
| `zyra-notifications/internal/mailer/mailer.go` | 4 new `case Template...:` branches (or 1 branch keyed by a `template_kind` param) that read `user_name`, `admin_name`, `ticket_code`, `subject`, `body` (or similar) and call the builder(s). |
| `zyra-app/components/admin/admin-sidebar.tsx` | Add nav item to `NAV_SECTIONS` (new "Support" section, or under an existing one — confirm placement). |
| `zyra-app/app/admin/support/page.tsx` (new) | List page, reuses `AdminSidebar`. |
| `zyra-app/app/admin/support/[id]/page.tsx` (new) | Detail page. |
| `zyra-app/views/admin/support/` (new) | `hero-support-list.tsx`, `hero-support-detail.tsx`, `support-reply-modal.tsx` — modeled on `zyra-app/views/admin/user-management/lifecycle/` (suspend-modal.tsx etc. pattern: confirm-then-call). All new UI raw Tailwind only (`.claude/rules/08-shadcn-ui.md`), icons from `lucide-react` only (`.claude/rules/12-icons.md`). |
| `zyra-app/lib/support-admin.ts` (new) | API call functions (`listTicketsAdmin`, `getTicketAdmin`, `replyToTicket`) — **must** hit `/api/admin/support/*`, which is correct here because this is genuinely an admin-only surface (`.claude/rules/15-member-api-separation.md` — no member-facing equivalent needed, ticket owners already have `/api/user/support/tickets` for their own list). |
| `zyra-app/messages/en.json` (+ other locale files if the project maintains them) | New i18n keys for the admin support pages, nav label, and modal copy. |

### API Contract

All responses use the `{status, message, data}` envelope already used by
`support_handler.go` (`gin.H{"status":.., "message":.., "data":..}` — matches
`model.APIResponse` shape in spirit; note the existing support handler builds
this by hand rather than the exact `model.APIResponse` struct since `Data` in
that struct is typed for auth responses only — keep the same `gin.H` pattern
for consistency with the sibling handler methods already in this file).

**1. `GET /api/admin/support/tickets`** — list all tickets (AdminGuard)

Query params (optional, v1 — confirm scope in Open Questions):
`status` (`open`/`resolved`), `contact_type`, `page`, `page_size`.

Response:
```json
{
  "status": 200,
  "message": "success",
  "data": {
    "tickets": [
      {
        "id": "uuid",
        "ticket_code": "ZYR-1000",
        "contact_type": "bug_report",
        "impact": "Cannot use at all (e.g., white screen)",
        "topic": "string",
        "status": "open",
        "user_id": "string",
        "user_name": "string",
        "user_email": "string",
        "created_at": "2026-08-04T10:00:00Z",
        "replied_at": null,
        "replied_by": null
      }
    ],
    "total": 42
  }
}
```

**2. `GET /api/admin/support/tickets/{id}`** — full ticket detail (AdminGuard)

Response: same shape as one item above, plus `description`, `attachment_url`,
`page_url`, `browser`, `os`.

**3. `POST /api/admin/support/tickets/{id}/reply`** — send reply email (AdminGuard)

Request (JSON):
```json
{
  "template_kind": "bug_report | feature_request | general_feedback | contact_support",
  "subject": "string",
  "body": "string",
  "mark_resolved": false
}
```
`template_kind` need not equal the ticket's original `contact_type` (admin
may override), but the UI should default to it. `mark_resolved` lets the
admin explicitly flip status (see Open Questions on whether this should be
automatic instead of a checkbox).

Response:
```json
{
  "status": 200,
  "message": "success",
  "data": {
    "id": "uuid",
    "status": "open | resolved",
    "replied_at": "2026-08-04T10:05:00Z",
    "replied_by": "admin-user-id"
  }
}
```

Error cases: `404` ticket not found, `400` invalid `template_kind`/empty
`subject`/`body`, `500` email dispatch/DB failure (email is sent
synchronously here, unlike the fire-and-forget `SendAsync` used for the
automatic emails — reply is a deliberate admin action, so the request should
probably wait for send confirmation or at least DB-persist the reply before
returning; recommend still using `notify.Client.SendAsync` for consistency
with the rest of the codebase, since `zyra-notifications` is the one that
owns actual delivery/retry — flag in Open Questions if synchronous
confirmation is required instead).

**New `notify.Template` constants** (`zyra-api/internal/notify/client.go`):
```go
TemplateSupportReplyBugReport       = "support_reply_bug_report"
TemplateSupportReplyFeatureRequest  = "support_reply_feature_request"
TemplateSupportReplyGeneralFeedback = "support_reply_general_feedback"
TemplateSupportReplyContactSupport  = "support_reply_contact_support"
```
(mirrored in `zyra-notifications/internal/mailer/mailer.go`'s own `Template`
constants, same convention as the existing `TemplateSupportAck`/`TemplateSupportNew` pair.)

**New RBAC permission keys** (`zyra-api/internal/rbac/catalog.go`):
```go
PermAdminSupportRead  = "admin.support.read"
PermAdminSupportReply = "admin.support.reply" // DependsOn: PermAdminSupportRead
```

### DB Impact

`tb_support_ticket.status` column already exists (migration 61,
`VARCHAR(16) DEFAULT 'open'`) — **no migration needed just to write
`'resolved'`**, it was always a valid value, simply unused until now.

However, v1 as scoped needs to **persist that a reply happened** (who/when,
so the admin UI can show "Replied" and the ticket detail can show reply
history) — this data doesn't exist anywhere today. Recommend one small
migration:

```sql
-- migration: 73_support_ticket_reply.sql
-- Adds admin-reply tracking to tb_support_ticket (v1: single latest reply,
-- not a full reply thread — see plan Open Questions).
ALTER TABLE tb_support_ticket
    ADD COLUMN IF NOT EXISTS replied_by  VARCHAR REFERENCES tb_user(id),
    ADD COLUMN IF NOT EXISTS replied_at  TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS reply_subject TEXT,
    ADD COLUMN IF NOT EXISTS reply_body    TEXT;

-- Admin "list all tickets" needs to sort/filter independent of user_id;
-- the existing idx_support_ticket_user (user_id, created_at DESC) doesn't
-- serve that. Add:
CREATE INDEX IF NOT EXISTS idx_support_ticket_status_created
    ON tb_support_ticket (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_ticket_created
    ON tb_support_ticket (created_at DESC);

-- Rollback:
--   DROP INDEX IF EXISTS idx_support_ticket_created;
--   DROP INDEX IF EXISTS idx_support_ticket_status_created;
--   ALTER TABLE tb_support_ticket
--       DROP COLUMN IF EXISTS reply_body,
--       DROP COLUMN IF EXISTS reply_subject,
--       DROP COLUMN IF EXISTS replied_at,
--       DROP COLUMN IF EXISTS replied_by;
```

Per team convention (`migrations-not-auto-run` / `feedback-run-migrations-myself`
memory notes), this SQL file will be applied by hand against dev/local DB by
whoever runs the dev-agent's implementation — flag this explicitly again at
PR time.

The new RBAC permission keys (`admin.support.read`/`admin.support.reply`) are
a **code-only** catalog change (per `internal/rbac/catalog.go` doc comment:
"the DB stores only the granted keys per role") — no migration required for
the catalog itself, but existing custom admin roles will **not**
automatically be granted the new keys (default-deny, same as every prior
catalog addition) — a super-admin will need to grant them manually via the
existing Role Management UI after deploy.

### Task Breakdown — Part B

Backend first, templates before wiring, frontend last:

1. `feat(api): add admin support-ticket reply RBAC permission keys`
   — `internal/rbac/catalog.go`: `PermAdminSupportRead`, `PermAdminSupportReply`.
2. `feat(api): migration 73 — support ticket reply tracking + admin list indexes`
   — the SQL above; apply to local/dev DB per team convention.
3. `feat(notifications): add 4 support-reply email templates`
   — `templates.go`: `buildSupportReply*EmailHTML` per contact type, from the
   4 Figma copy variants; reuses existing card chrome.
4. `feat(notifications): wire 4 new support-reply Template constants into mailer dispatch`
   — `mailer.go` switch cases + `Template` consts.
5. `feat(api): add notify.Template constants for support-reply emails`
   — `internal/notify/client.go` (mirrors step 4's names).
6. `feat(api): add SupportService.ListAllTickets/GetTicket/ReplyToTicket`
   — `support_service.go`, including status-flip + reply-persistence logic
   (behavior TBD per Open Questions).
7. `feat(api): add GET/POST /api/admin/support/tickets(:id)(/reply) handlers + routes`
   — new handler + `router.go` admin group, gated by the new permission keys.
8. `test(api): unit tests for SupportService admin list/get/reply`
   — table-driven per `.claude/rules/04-test.md`; mock DB via interface.
9. `feat(app): add "Support" nav entry to AdminSidebar`
10. `feat(app): add admin support ticket list page`
    — `app/admin/support/page.tsx` + `views/admin/support/hero-support-list.tsx` + `lib/support-admin.ts` list/get calls.
11. `feat(app): add admin support ticket detail page + reply modal`
    — `app/admin/support/[id]/page.tsx` + `hero-support-detail.tsx` + `support-reply-modal.tsx` (template picker + editable subject/body, confirm-and-send pattern mirroring `lifecycle-action-modals.tsx`).
12. `test(app): vitest for support-admin lib functions + reply modal happy/error paths`

---

## Definition of Done (both parts)

- [ ] Acceptance criteria above all satisfied.
- [ ] API contract (Part B) matches exactly what `zyra-app/lib/support-admin.ts`
      calls — no drift between handler JSON shape and frontend types.
- [ ] Migration 73 has a rollback block (included above) and is applied to
      local/dev DB before the frontend PRs that depend on the new columns.
- [ ] No secrets hardcoded (SMTP/API keys already come from env per
      `.claude/rules/06-release.md` — no changes needed there).
- [ ] `go test ./...` and `vitest run` green; `npx tsc --noEmit` clean for
      all new/edited `zyra-app` files.
- [ ] New admin UI reuses `AdminSidebar`, Tailwind-only, lucide-react icons
      only (rules 08/09/12).
- [ ] PR descriptions explain what + why per task.

---

## Open Questions (need user decision before Part B implementation starts)

1. **Reply body: free-edit or fully canned?** Recommend: admin picks a
   template (defaults to the ticket's own `contact_type`), which pre-fills
   subject + body textarea with the Figma copy (including bracketed
   placeholders like `[briefly mention the feature]` filled in with
   `[User Name]`/ticket topic where mechanical, left as brackets otherwise
   for the admin to fill by hand), and the admin can freely edit both before
   sending. Please confirm this is correct, or if it should be non-editable.
2. **Does sending a reply always flip `status` to `resolved`, only for the
   "bug fixed" template, or is it a separate admin toggle (`mark_resolved`
   in the request body, as drafted above)?** Recommend a checkbox default
   defaulting to checked only for the bug-report template, unchecked for
   the other 3 — please confirm.
3. **Reply history: single latest reply per ticket, or a full thread (multiple
   replies over time)?** The migration above assumes a single "latest reply"
   snapshot on the ticket row itself (simplest, matches "v1 has no
   status-change UI" tone of the original migration 61 comment). If multiple
   replies per ticket must be supported, a separate `tb_support_ticket_reply`
   child table is needed instead — please confirm which.
4. **Admin list page scope for v1** — is filtering/search (by status,
   contact_type, submitter) required in the first PR, or is a simple
   newest-first list acceptable for v1 with filters as a follow-up? (Query
   params are drafted above but implementing the UI controls could be
   deferred.)
5. **RBAC placement** — should the new `admin.support.*` permission keys live
   under a new "Support" category (new nav section) or under the existing
   `CatContentManagement` bucket? Affects both `catalog.go` category and
   where the nav item lives in `AdminSidebar`.
6. **Synchronous vs async email send on reply** — should `POST
   .../reply` wait for `zyra-notifications` to confirm delivery before
   responding 200 (so the admin knows for certain the email went out), or is
   the existing fire-and-forget `SendAsync` pattern (used for the automatic
   ack/inbox emails) acceptable here too? Recommend keeping `SendAsync` for
   consistency, but flagging since a reply is a deliberate one-off admin
   action where silent failure is worse UX than for automatic emails.
7. **Admin identity in the reply email's `[Admin Name]` placeholder** — pull
   from the logged-in admin's `display_name`/`name` (same fields
   `lookupUser` already reads for the ticket submitter), or should it be a
   generic "Zyra Support Team" signature with no named admin? Figma copy
   ends with "Warm regards, [Admin Name] / Zyra Support Team" implying a
   real name — confirm.

## Decisions (confirmed by user 2026-08-04)

1. **Reply body: free-edit.** Admin picks a template (defaults to the
   ticket's `contact_type`), subject+body pre-fill into an editable
   textarea, admin edits before sending.
2. **Resolve behavior:** sending a reply with `template_kind =
   bug_report` auto-flips `status` to `resolved`. For the other 3
   templates, `mark_resolved` is an explicit checkbox in the reply modal
   (default unchecked), passed through in the request body as drafted.
3. **Reply history: single latest reply only.** Use the
   `replied_by`/`replied_at`/`reply_subject`/`reply_body` columns on
   `tb_support_ticket` itself (migration 73 as drafted) — no child table.
4. **RBAC/nav placement: new "Support" section.** Add a new top-level nav
   section in `AdminSidebar` (not folded into `CatContentManagement`), and
   a new RBAC category for `admin.support.read` / `admin.support.reply` in
   `catalog.go`.
5. Remaining lower-risk items proceed with the plan's recommended
   defaults: async email send via `notify.Client.SendAsync` (question 6),
   real admin name in `[Admin Name]` from `display_name`/`name` (question
   7), and a simple newest-first admin list for v1 with the query params
   already drafted but their UI controls (filter/search) deferred to a
   follow-up (question 4).
