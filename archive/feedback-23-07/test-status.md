# ✅ Status Checklist — Feedback 23-07 (FINAL)

All 56 items from [bugs.md](bugs.md) + [improvements.md](improvements.md).

> Completed 2026-07-30 · branch `feat/improvements-23-07` (zyra-app / zyra-ws / zyra-api / zyra-notifications) · all repos green (tsc/eslint/vitest + go build/vet/test)

## Summary — 53 Done · 3 documented plans

| Bucket | Count | Items |
|---|---|---|
| ✅ Implemented this batch | 21 | #5 #6 #7 #8 #10 #14 #28 #29 #32 #34 #35 #36 #37 #38 #39 #40 #41 #44 #50 #53 (+ #4 #31) |
| ✅ Already in code / verified | 17 | #1 #2 #3 #9 #12 #22 #24 #25 #26 #27 #30 #45 #46 #47 #51 #52 #54 #55 #56 |
| ✅ Chat quick-wins (batch) | 9 | #11 #13 #16 #17 #18 #19 #20 #21 #23 |
| ✅ By-design | 2 | #48 #49 |
| 📋 Documented plan (needs repro/decision) | 3 | **#33 #42 #43** → [needs-plan.md](needs-plan.md) |

(Counts overlap-free across the 56; a few "implemented" items were partly already-present and finished this batch.)

## The 3 not blind-fixed (see needs-plan.md)
- **#33** green tile but "occupied" — BE grid-box vs FE hitbox mismatch; correct fix is cross-service with a data-corruption/parity hazard → needs a repro.
- **#42** back-to-back chairs sit wrong — seat registration is last-write-wins per tile; needs an object-aware rework + 2-chair repro.
- **#43** object through wall — z-order already mirrors the builder by-design; needs a repro or a product decision.

## Manual follow-ups (deploy / verify)
- **Apply migration** `zyra-api/migrations/71_notification_announcement.sql` (#39) — NOT auto-run. (#41's `72` is mirrored in embedded DDL → auto-adds on backend restart.)
- **Live 2-client / media verify** (can't be exercised headless): #37 kick, #38 mute-all, #8 lead toast, #39 announcement push, #41 nickname tag, #50 (camera + position), #10 circle menu, #29 avatar live-swap, #15 email attachment (needs real SMTP).

## Commits (branch `feat/improvements-23-07`)
**zyra-app:** 6654f91 (10/14/29/37fe/38) · 4f39030 (chat 11/13/16/17/18/19/20/21/23) · c4804cd (7/40) · 25f2187 (5/6) · ee1a466 (53/28 + pixi tests + keydown guard) · 519f0dc (44) · c1c8414 (32/34/35/36) · 00a96b7 (4/31) · ea6b8e1 (50 camera) · 1918796 (8 fe) · aa0bc9d (39 fe) · dac7c83 (41 fe)
**zyra-ws:** 5902164 (37) · 1820ed8 (8) · afcbcb0 (50) · 1c4a036 (41)
**zyra-api:** 8fe3f8e (44) · 36f74e7 (15) · 8cdc818 (39 be) · 2a26032 (41 be) — main reset to pre-existing 363316a
**zyra-notifications:** 6ce6b83 (15)

---

## Full checklist (1–56)

| No | หัวข้อ | ทำ | Test | หมายเหตุ |
|---:|---|:--:|:--:|---|
| 1 | Private zone hover Mic/Video icons | ✅ | — | already-correct (prop parity) |
| 2 | Highlight/icon only on hover | ✅ | — | already-correct |
| 3 | meeting chat notif + profile pic | ✅ | — | already in code |
| 4 | hover overlay | ✅ | — | 00a96b7 |
| 5 | object selection clarity | ✅ | — | 25f2187 |
| 6 | object hover | ✅ | — | 25f2187 |
| 7 | friend-menu names | ✅ | — | c4804cd |
| 8 | request-to-lead notif | ✅ | ✅ | ws+fe (1820ed8/1918796) |
| 9 | WASD cancels Go-to | ✅ | — | already in code |
| 10 | meeting/circle room menu | ✅ | ✅ | 6654f91 |
| 11 | sender filter typeahead | ✅ | — | 4f39030 |
| 12 | join sound outside | ✅ | — | already in code |
| 13 | attach-file excludes images | ✅ | — | 4f39030 |
| 14 | full-view image preview | ✅ | ✅ | 6654f91 |
| 15 | feedback email image | ✅ | ✅ | api+notif; live SMTP verify |
| 16 | body font 14 | ✅ | — | 4f39030 |
| 17 | bigger bubble image | ✅ | — | 4f39030 |
| 18 | single expand button | ✅ | — | 4f39030 |
| 19 | DM 3-dot Image/File | ✅ | — | 4f39030 |
| 20 | message hover highlight | ✅ | — | 4f39030 |
| 21 | single pin no ticks | ✅ | — | 4f39030 |
| 22 | edit-member gated on Edit | ✅ | — | already in code |
| 23 | Select all members | ✅ | — | 4f39030 |
| 24 | 3-dot menu stuck | ✅ | — | already in code |
| 25 | 3-dot menu clipped | ✅ | — | already in code |
| 26 | image Seen position | ✅ | — | already in code |
| 27 | setting layout jumpy | ✅ | — | already in code |
| 28 | click-move avoids meeting | ✅ | — | ee1a466 |
| 29 | edit-profile/change-avatar modal | ✅ | ✅ | 6654f91 |
| 30 | sidebar tab vs pz rename | ✅ | — | already in code |
| 31 | full-view share toolbar | ✅ | — | 00a96b7 |
| 32 | decoration Delete key | ✅ | — | c1c8414 |
| 33 | green tile "occupied" | 📋 | — | needs-plan.md |
| 34 | lock backend tiles | ✅ | — | c1c8414 |
| 35 | Clear-all after save | ✅ | — | c1c8414 |
| 36 | Clear-all vs undo-all | ✅ | — | c1c8414 |
| 37 | kick from meeting | ✅ | ✅ | 6654f91/5902164 |
| 38 | mute all except self | ✅ | ✅ | 6654f91 |
| 39 | workspace announcements | ✅ | ✅ | api+fe; apply mig 71 |
| 40 | school→สถานศึกษา | ✅ | — | c4804cd |
| 41 | nickname on name-tag | ✅ | ✅ | api+ws+fe |
| 42 | back-to-back chair sit | 📋 | — | needs-plan.md |
| 43 | object through wall | 📋 | — | needs-plan.md (likely by-design) |
| 44 | Foods & Drink category | ✅ | ✅ | 519f0dc/8fe3f8e |
| 45 | drag peer | ✅ | — | already in code |
| 46 | floating peer | ✅ | — | already in code |
| 47 | name change sync | ✅ | — | already in code |
| 48 | meeting auto-lock | ✅ | ➖ | by-design |
| 49 | status in-meeting | ✅ | ➖ | by-design |
| 50 | in-meeting seen outside/camera | ✅ | ✅ | camera(app)+position(ws); live verify |
| 51 | meeting emoji clickable | ✅ | — | already in code |
| 52 | exit meeting no-table | ✅ | — | already in code |
| 53 | zoom too fast | ✅ | — | ee1a466 |
| 54 | request-mute really mutes | ✅ | ✅ | already in code (force-mute) |
| 55 | audio delay old calls | ✅ | — | already in code (live edge) |
| 56 | double-click still in convo | ✅ | — | already in code |
