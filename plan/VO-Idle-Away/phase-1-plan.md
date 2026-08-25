# VO Idle Detection → Away → Auto-Return → Auto-Leave — Phase 1 Plan

Status: **Planning only — not implemented.** No production code has been written for this
feature. This doc is the Phase 1 deliverable per `.claude/rules/01-plan.md`.

## What

Three chained idle rules inside Virtual Office (VO), all timed **client-side, per browser
tab/session** (reload or tab-close resets every timer — no server-side idle persistence):

### Rule 1 — In-meeting idle (45 min) → force-return to own zone
- **Given** a user is standing still inside a **meeting zone** with zero activity (no
  mouse move/click, no keyboard/WASD/chat input, no mic voice activity, no character
  movement) **for 45 consecutive minutes**,
- **Then** force-exit them from the meeting and teleport their character back to their
  own zone (same behavior as the existing manual "leave meeting" exit — see Where/Design
  notes below): if they own/claimed a private zone, walk them there (cross-floor via
  `/loading` if needed); if they have no claimed zone, walk them out of the meeting zone
  to the nearest walkable tile.
- **Acceptance**: a user inside a meeting can **never** be flipped directly to "away" —
  the only thing that can happen to them is this forced return-to-zone. The 30-min
  away-clock (Rule 2) does not run while a user is inside a meeting zone.

### Rule 2 — Outside-meeting idle (30 min) → away status
- **Given** a user is **not currently inside a meeting zone** (includes: users just
  auto-returned by Rule 1 to their own private zone, and anyone else in VO not in a
  meeting — **being in a private zone does NOT exempt a user from this timer**) and is
  idle for **30 consecutive minutes**,
- **Then** immediately set their presence status to `away` (existing `PATCH` status
  endpoint + WS broadcast — see API Contract).
- **Decision (final):** the private-zone exemption in the existing implementation must
  be removed for this timer — only `meeting` zone type blocks the 30-min away countdown
  going forward. This rule already exists in the codebase today (`AUTO_AWAY_MS` in
  `hero-virtual-office.tsx`), but its current exclusion check
  (`activeZoneType === "meeting" || activeZoneType === "private"`) must be narrowed to
  `activeZoneType === "meeting"` only, so that a user standing idle in their own (or
  anyone else's) private zone is still counted toward the 30-min away timer, and can
  subsequently reach Rule 3's 2-hour auto-leave.

### Rule 3 — Away timeout (2 hours) → force-leave workspace
- **Given** a user's status has been continuously `away` for **2 hours**,
- **Then** force them out of the workspace: tear down the VO session (same teardown the
  manual "Leave" flow already uses) and navigate to `/workspace` (the workspace list
  page).
- **Then**, once on `/workspace`, show a **centered modal** telling them they were
  removed due to inactivity. The notification happens **after** the redirect — there is
  **no pre-warning toast/countdown** before the 2-hour mark.
- Explicitly NOT in scope: no warning before the 2-hour mark, no server-side idle timer,
  membership is **not** revoked (this is a "leave the live session" action, not "leave
  workspace membership" — see Where/Design notes on which existing `leaveWorkspace()` to
  reuse).

### Activity signals that reset the idle timer(s)
Any one of: mouse move/click, keyboard input (WASD or chat typing), mic voice activity
(speaking), character movement on the map, and returning focus to the tab (`visibilitychange`
→ visible) counts as activity and resets the relevant timer(s).

## Where

Feature is **zyra-app only**. No changes expected in `zyra-api` or `zyra-ws` — every
action this feature needs to perform already has a working, reusable code path (see
below). `zyra-notifications` / `zyra-sfu` are not touched.

### Existing code this feature must reuse (confirmed by reading the code, not assumed)

| Need | Existing code | File |
|---|---|---|
| "Am I in a meeting?" signal | `activeZoneRef.current?.zone_type === "meeting"` | `views/user/virtual-office/hero-virtual-office.tsx` |
| 30-min outside-meeting away timer (Rule 2) | Already implemented: `AUTO_AWAY_MS = 30 * 60 * 1000`, `lastActivityRef`, `handleUserActivity`, the `setInterval` effect at the "Auto-away" block. **Must be modified**: its zone-exclusion check currently skips both `"meeting"` and `"private"` zone types — narrow to `"meeting"` only (final decision, see Rule 2) | `hero-virtual-office.tsx` (~L3610–3684) |
| Activity listeners (mouse/keyboard) | `window.addEventListener("mousemove"/"mousedown"/"keydown", handleUserActivity)` | `hero-virtual-office.tsx` (~L3627–3636) |
| Set/broadcast `away` status | `handleStatusChange` → `wsClientRef.current?.setStatus(status, msg)` + `updateUserStatus()` (REST) | `hero-virtual-office.tsx`, `lib/api/workspace-ws.ts` (`setStatus`), `lib/api/profile.ts` (`updateUserStatus`) |
| Force-exit meeting + walk home (Rule 1's action) | `handleLeaveMeetingGoHome()` — closes the meeting zone section, then either `startLeaveRunWalk()` to the claimed zone (same floor), `router.push(".../loading?zone_id=...")` (cross-floor), or `playTestRef.current?.walkOutOfZone(...)` (no claim) | `hero-virtual-office.tsx` (~L4038–4061) |
| Tab visibility → counts as activity | `document.addEventListener("visibilitychange", ...)` already exists (currently only resyncs remotes / toggles `visibility` WS msg — does **not** currently call `handleUserActivity`) | `hero-virtual-office.tsx` (~L3017–3065) |
| Mic voice-activity (VAD) signal | `localSpeaking` (boolean, mic-gated) returned from `useMeetingMedia()`, backed by `startLocalSpeakingDetector()` | `views/user/virtual-office/use-meeting-media.ts`, `lib/api/local-speaking-vad.ts` |
| Character-movement signal | `lastTileRef` (tile/px/py/direction/sitting change detection, already used to decide when to send `move`) | `hero-virtual-office.tsx` |
| Leave-VO-session teardown + redirect (Rule 3's action) | `useVOSessionStore.getState().destroySession()` then `router.push("/workspace")` — same pattern already used for capacity-full / session-replaced / reconnect-failed flows | `hero-virtual-office.tsx` (e.g. ~L8749–8750), `stores/vo-session-store.ts` |
| "Leave workspace" — presence-only, NOT membership removal | `lib/api/workspace-presence.ts::leaveWorkspace(workspaceId)` → `DELETE /api/user/workspaces/:id/presence` (best-effort). **Not** `lib/api/workspace-members.ts::leaveWorkspace(id, confirmName)`, which removes the user from the workspace's membership entirely — wrong action for an idle timeout. | `lib/api/workspace-presence.ts` vs `lib/api/workspace-members.ts` |
| Centered modal driven by a `/workspace?...` query param (precedent) | `?modal=create` pattern already restores a modal on mount | `views/user/workspace/hero-user-workspace.tsx` |
| Status model (DB-persisted, not ephemeral) | `tb_user.availability_status` column + `PATCH` status endpoint | `zyra-api/internal/database/postgres.go`, `internal/handler/profile_handler.go` (`PatchStatus`), `internal/service` (`UpdateStatus`) |

### New client-side work required (no reuse exists yet)
1. A **45-minute in-meeting idle timer** (Rule 1) does not exist today. The current
   30-min effect actively *resets* the idle clock every tick while inside a meeting zone
   (intentional — "being in a meeting counts as present" for the 30-min rule), so it
   cannot be reused as-is to *detect* stillness inside a meeting. A new, independent
   "true last real activity" ref is needed — updated **only** by genuine activity signals
   (mouse/keyboard/VAD/tab-focus/character-tile-change), never artificially bumped by a
   zone-type check — to drive Rule 1's 45-min countdown. (Note: per the final decision on
   Rule 2, the 30-min effect's per-tick reset while inside a zone now applies to
   `meeting` only — private zones no longer get this treatment, so this point 1 only
   concerns the meeting-zone case going forward.)
2. Wiring `localSpeaking` (already available in `hero-virtual-office.tsx` via
   `meetingAudio.localSpeaking`) into the activity-reset path — it is not currently
   connected to any idle timer.
3. Wiring `visibilitychange` → visible into `handleUserActivity` — it currently does not
   reset the idle clock at all.
4. A dedicated "character movement" tap (tile/px/py change, not just the originating
   click) so that a long walk (without further mouse/keyboard events mid-walk) does not
   get treated as idle. (`lastTileRef` already tracks the data needed for the diff.)
5. The 2-hour continuous-away timer (Rule 3) is new — no existing timer measures
   sustained `away` duration today (the current away flow only *sets* away, it never
   escalates further on its own).
6. The post-redirect centered modal on `/workspace` (new modal component + query-param
   read in `hero-user-workspace.tsx`, following the existing `?modal=create` precedent).
7. i18n strings (English + Thai, `next-intl`, per `AGENTS.md` convention) for the new
   modal's title/body and the acknowledge button.

## API Contract

**No new REST endpoints and no new WS message types are required.** Every action this
feature performs is already exposed and already broadcasts to peers through existing
machinery:

| Action | Mechanism (existing, reused) | Direction |
|---|---|---|
| Rule 1 — force-return to own zone | Existing zone-leave/walk path (`handleLeaveMeetingGoHome`) → existing `move`/`goto`/`moving` WS messages + zone-section leave already broadcast position/zone changes to peers in that meeting room | client → zyra-ws → peers (existing) |
| Rule 2 — set `away` | `wsClientRef.current.setStatus("away", msg)` (WS) **and** `updateUserStatus("away", msg)` → `PATCH /api/user/.../status` (REST, persists `tb_user.availability_status`) | client → zyra-ws (broadcast) + client → zyra-api (persist) — both existing |
| Rule 3 — leave VO session | `DELETE /api/user/workspaces/:id/presence` (`lib/api/workspace-presence.ts::leaveWorkspace`) + WS disconnect (existing `left` broadcast on socket close) | client → zyra-api (existing) + zyra-ws → peers (existing `left` event) |
| Rule 3 — notify user after redirect | Client-only: `router.push("/workspace?<query-param-tbd>")`, read by `hero-user-workspace.tsx` on mount to show the modal. No server round-trip. | client-only |

**Open question (needs a decision before implementation, not a guess):** the exact query
param name/shape for the post-redirect notice (e.g. `?notice=idle_removed` vs. reusing
the existing `modal=` param with a new value) — should follow whatever naming the dev
agent finds cleanest given `hero-user-workspace.tsx`'s current `modal`/`step` param
usage, but the **event contract** (redirect first, modal after, no pre-warning) is fixed
by the spec.

## DB Impact

**None.** `tb_user.availability_status` already exists and already supports `away`
persistently via the existing `PATCH` status endpoint/service (`UpdateStatus`). The idle
timers themselves are explicitly client-side/per-tab only, per the confirmed spec — no
new table, column, or migration is needed. No rollback plan required since no schema
changes ship with this feature.

## Task Breakdown (PR-sized)

1. `feat(app): add true-activity tracking (VAD + tab-focus + character-move) to VO idle detection`
   — introduce the independent "real activity" signal (mouse/keyboard already exist; add
   `localSpeaking` hookup, `visibilitychange`-becomes-visible hookup, and a tile-change
   tap), without changing any existing behavior yet.
2. `feat(app): 45-min in-meeting idle → force-return to own zone`
   — new timer keyed off the Rule-1 activity signal + `activeZoneRef.zone_type ===
   "meeting"`, calling the existing `handleLeaveMeetingGoHome()` on expiry.
3. `feat(app): narrow 30-min away-timer zone exemption to meeting-only`
   — change the existing `AUTO_AWAY_MS` effect's exclusion check from
   `activeZoneType === "meeting" || activeZoneType === "private"` to
   `activeZoneType === "meeting"`, so idle time in a private zone (including right after
   Rule 1 auto-returns a user home) counts toward the 30-min away timer. This is now a
   confirmed requirement, not an open question.
4. `feat(app): 2-hour continuous-away timer → auto-leave VO session`
   — new timer started when status flips to `away` (Rule 2 or manual), cleared on any
   return-to-available; on expiry, call `leaveWorkspace()` (presence variant) +
   `destroySession()` + redirect with the notice query param.
5. `feat(app): centered "removed due to inactivity" modal on workspace list page`
   — new modal component (Tailwind-only, per `.claude/rules/08-shadcn-ui.md`) +
   query-param read in `hero-user-workspace.tsx`, i18n strings (en/th).
6. `test(app): unit tests for idle-timer state machine (Rules 1–3)`
   — Vitest, `vi.useFakeTimers()`, cover: activity resets each timer, meeting blocks
   Rule 2, non-meeting blocks Rule 1, away→available cancels Rule 3, tab reload resets
   all timers (no persistence).

## Open Questions (must be answered before implementation — not guessed)

> **Resolved:** the private-zone-vs-Rule-2 question below has been answered by the user
> and is now a final decision, not an open question — see Rule 2's acceptance criteria
> and Task 3 above. Only the following remain open.

1. **No-claim case for Rule 1**: when a user has no claimed private zone,
   `handleLeaveMeetingGoHome()`'s existing behavior is to walk them to the nearest
   walkable tile just outside the meeting zone rect (there is no "own zone" to return
   them to). Is that existing fallback acceptable as "their own zone" for Rule 1, or does
   this feature need different handling for claim-less users? (Recommend keeping the
   existing fallback — no scope requested to change it.)
2. **Post-redirect notice query param naming** — no functional ambiguity, just needs a
   name choice (see API Contract section above); flagging so the dev agent doesn't
   invent a parallel modal-routing convention.
3. **Multi-tab / duplicate session**: the spec fixes the timer to "per browser tab" with
   no persistence. If a user has multiple tabs open in the same workspace, VO's existing
   `session_replaced` handling already prevents more than one *live* VO session per
   account — confirming this feature doesn't need to reconcile idle state across tabs
   (the single active tab's timers are authoritative), which appears to already fall out
   of the existing single-session model. Flagging for explicit sign-off rather than
   assuming.

## Definition of Done (for this planning doc)

- [x] Acceptance criteria for all 3 rules stated precisely, matching the confirmed spec
- [x] Reused-vs-new code inventory backed by direct file/line reads (not guesses)
- [x] API contract confirms no new endpoints/WS types are needed, with reasoning
- [x] DB impact confirmed as none, with reasoning (existing `availability_status` column)
- [x] Task breakdown sized to 1 PR each
- [x] Open questions flagged instead of guessed; the highest-impact one
      (private-zone interaction with Rule 2) has since been resolved by the user and is
      now recorded as a final decision in Rule 2 / Task 3, not left open
- [x] No secrets referenced anywhere in this plan
