# VO Movement V2 — Staging Soak Checklist (PR8)

Covers the plan at `.claude/plans/effervescent-forging-octopus.md` (also mirrored
in the session that produced PRs 1–7). Goal: prove `VO_MOVEMENT_V2` is safe to
default-on in prod (PR9) before touching real users.

## 0. Prerequisites

- [ ] PRs 1–7 deployed to staging (zyra-api, zyra-ws, zyra-app all on the branch/tag that includes them)
- [ ] `go test ./...` green on zyra-api and zyra-ws; `vitest run` green on zyra-app (all confirmed locally already — re-confirm on the staging build)
- [ ] Redis reachable from both zyra-api and zyra-ws (obstacle grid + zone cache both depend on it — see §3)
- [ ] At least 2 test accounts + 1 workspace with: a meeting zone, a private zone (unclaimed), a spotlight tile, at least one wall/furniture obstacle, one teleport pad

## 1. Enable the flag

- [ ] Set `VO_MOVEMENT_V2=true` on the staging **zyra-ws** deployment
- [ ] Set `NEXT_PUBLIC_VO_MOVEMENT_V2=true` on the staging **zyra-app** build (this is a `NEXT_PUBLIC_*` var — it's baked in at build time, not runtime; a rebuild/redeploy is required, not just an env change)
- [ ] Confirm both flags are actually in effect: zyra-ws should log `"VO_MOVEMENT_V2 enabled — server-authoritative movement protocol active"` on boot (`main.go`); on the client, open devtools → Network → WS frames and confirm outbound frames are `input`/`goto`, not `move`/`move_to`

**Mixed-version sanity check** (server supports both protocols simultaneously by design): open one browser with the v2 build and one against a cached/old v1 build if available, in the same workspace. Confirm both render each other correctly — this proves the flag-off default stays fully functional for anyone not yet on the new build.

## 2. Functional pass — one person, one tab

- [ ] WASD movement in all 8 directions — moves smoothly, no rubber-banding under normal (unthrottled) network
- [ ] Sprint (Shift + WASD) — visibly faster, no rejection
- [ ] Click-to-walk (single tile, and a long multi-tile path across the map)
- [ ] Walk into a wall / blocked tile — stops correctly, no warp-through
- [ ] Walk onto a chair/seat tile — sits correctly (WASD auto-sit and click-to-seat both)
- [ ] Sit → stand → walk away — no stuck state
- [ ] Walk through a doorway / wall-mounted object — collision matches what's rendered
- [ ] Teleport pad — arriving opens the floor picker; walking *through* one (not stopping on it) must NOT open the picker
- [ ] Backgrounding the tab mid-walk (switch tabs, wait, come back) — character doesn't "run forever" or freeze permanently (checks `inputStaleAfter`/`releaseAllKeys` handling)

## 3. Zone/meeting/spotlight pass (PR6 validation — watch for false rejects)

This is the part most likely to regress if zone geometry and the obstacle grid ever drift apart, since PR6 added real server-side rejection where there was none before.

- [ ] Walk into the meeting zone with a second account already inside — both flip to "meeting" (red dot) in the sidebar, minimap, and chat
- [ ] Leave the meeting zone — status reverts, `online_member_ids` updates for the other occupant
- [ ] Stand on the spotlight tile, unmute — broadcast starts; confirm `ws:spotlight:start` is **not** rejected (check zyra-ws logs / a `MsgError` in devtools WS frames — an `"not on a spotlight tile"` error here means the zone cache and the actual tile the player predicts don't agree — a real bug, not a flake)
- [ ] Step off the spotlight tile, mute — broadcast stops
- [ ] Chat-space proximity pop forms/dissolves correctly walking in/out of a private zone
- [ ] **After an admin edits a zone's shape/position mid-session** (resize/move the meeting or spotlight zone in the editor while a soak session is running): confirm the zone-geometry cache picks up the change within `zoneSetTTL` (30s, `room.go`) — walk into the *new* zone boundary and confirm meeting/spotlight still work; walk into the *old* boundary (now outside the zone) and confirm it's correctly rejected/inactive
- [ ] Claim an unclaimed private zone — confirm it still works from anywhere on the map (intentional, per PR7 — this must NOT have started rejecting)

If any of the above produces an unexpected `MsgError`/rejection: check whether the workspace's zone cache was ever populated (`vo:zones:<workspaceID>` in Redis) — a zone edited *before* PR6 shipped won't have a cache entry until it's touched once (create/update/delete) after the deploy; this is expected fail-open behavior, not a bug, but worth confirming it resolves itself after one edit.

## 4. Smoothness — the actual pass/fail gate for this migration

Per the plan: **occasional visible rubber-banding is an acceptable rare edge case; a "stutter" or "stop-start" on ordinary movement is not.**

- [ ] Record ~30s of normal WASD movement (screen capture) under unthrottled network — confirm it looks indistinguishable from the v1/legacy build
- [ ] Repeat with Chrome DevTools → Network → Throttling set to a mid-tier profile (~100–150ms added latency) — confirm:
  - [ ] Movement still renders smoothly frame-to-frame (local prediction is doing its job)
  - [ ] Corrections, when they happen, are a **soft glide** (a barely-visible landing adjustment), not a visible stop/teleport — this is the 1-tile reconciliation path (`reconcileLocalPlayer` in `scene.ts`)
  - [ ] Hard snaps (≥2-tile divergence) are rare — if you can trigger one on demand under normal play (not deliberately spamming a wall edge), that's a signal the client/server obstacle grids have drifted
- [ ] With 3+ concurrent test accounts moving simultaneously in the same room, confirm no visible desync in how peers render each other (this exercises `flushMoves`/AOI broadcast under real concurrency, not just the reconciliation path)

## 5. Regression / persistence pass

- [ ] Reload the page mid-session — spawn position matches where you actually were (exercises the Postgres `last_position_x/y` write path from PR1, now server-tick-driven under v2)
- [ ] Disconnect/reconnect (kill WiFi briefly) — `force_sync` on reconnect lands you at the correct authoritative tile, and (post-PR5) an active zone/meeting status recomputes correctly if the reconnect happened to snap you into/out of a zone boundary
- [ ] Follow mode (if in scope for this soak) — leader/follower chain still walks correctly, no "walk-stop-walk" jitter

## 6. What to watch server-side (logs/metrics, not just eyeballing the client)

- [ ] zyra-ws error rate on `input`/`goto`/`section_sync`/`chat_space:zone`/`ws:spotlight:start` — should be ~0 outside of deliberate edge-case testing above
- [ ] `force_sync` frequency per active session — a healthy baseline is "rare"; a session generating many force_syncs per minute of normal play indicates client/server obstacle-grid or zone-grid disagreement worth investigating before PR9
- [ ] CPU on the zyra-ws process under the concurrent-movement test in §4 — the tick loop (`runMoveTicker`, 20ms) now does real simulation work per active mover under v2; confirm it doesn't visibly regress compared to a v1-only baseline at similar CCU

## 7. Sign-off before PR9 (flip default-on in prod)

- [ ] §2–§5 all pass with no unresolved findings
- [ ] Any `force_sync`/zone-rejection spike from §6 has a known, explained cause (not "unknown, but rare enough to ignore")
- [ ] At least one soak session included a live zone edit (§3) to confirm the cache-refresh path works, not just a freshly-seeded workspace
- [ ] Rollback confirmed trivial: flip both flags back off, reload — behavior reverts to today's production behavior exactly (no DB migration exists in this migration, so this should be instant)
