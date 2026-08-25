# Meeting / VO Bug Batch — 2026-08-07

Status: **Planning only — no code changed.** 9 user-reported issues, root-caused by reading
`zyra-app` (+ `zyra-ws` where relevant). Each item lists What / Where / Sizing / Open Questions.
No fix is to start until the "Open Questions" for that item are answered (no-overreach).

---

## 1. Meeting Display shows people who aren't really in the meeting; kick has no visible effect

**What (verified):** Meeting membership is derived two different ways depending on *whose*
client is computing it:

- For the zone the CURRENT client is itself joined to (`zone.id === mediaZoneId`),
  `getAuthoritativeZoneParticipants()` unions tile-geometry with the LiveKit media-plane
  (`memberVideo`/`memberAudio` keys) and subtracts `meetingAudio.removedUserIds`.
- For **every other zone** (i.e. what every bystander/other-client sees for a meeting room
  they are not in), it silently falls back to pure tile-geometry
  (`getZoneParticipants()` — "is your avatar's tile inside the zone rectangle", nothing about
  actually having joined LiveKit audio/video).

This means: (a) someone merely standing/walking through a meeting zone's rectangle shows up
as "in meeting" for everyone else even if they never joined the media room, and (b) the
server's own kick handler comment admits the gap:

> `internal/hub/audio.go:442-444` (zyra-ws) — *"Everyone else learns about the removal too —
> their participants menu is derived from tile geometry, which only catches up once the
> target's walk-out actually lands (and never, if that walk is blocked)."*

So kicking removes the target from the LiveKit room (they get `ws:meeting:kicked` and tear
down their own media session), but every *other* viewer's participant list still shows them
until their avatar's tile physically leaves the zone rectangle — which can lag or never
happen (blocked walk-out). This is a documented, intentional gap in the current design, not
an accidental crash.

**Where:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx:6925-7032` (`getZoneParticipants`,
  `getAuthoritativeZoneParticipants`, `zoneMeetings`)
- `zyra-app/views/user/virtual-office/components/vo-member-panel.tsx:504-524` ("In meeting"
  section split — feeds off the same `zoneMeetings`)
- `zyra-app/views/user/virtual-office/components/zone-participants-submenu.tsx` (kick button UI)
- `zyra-ws/internal/hub/audio.go:398-452` (`handleMeetingKick`)

**Sizing:** Needs a design decision before sizing (see open question) — could be a small
client-only patch (force-remove kicked user from ALL clients' geometry-derived lists, not
just the joiner's own) or a bigger change (make meeting membership authoritative from the
server's room roster everywhere, not just for the client's own zone). Likely **2 PRs**:
1. `fix(ws)`: on `ws:meeting:kicked`/`MsgMeetingMemberRemoved`, broadcast should let ALL
   clients (not just the joined one) mark the target as force-removed until their tile
   actually leaves.
2. `fix(app)`: apply that removed-set in `getZoneParticipants` itself (not just the
   media-plane-union branch), so it works for every viewer, not just the zone's own occupant.

**Open questions:**
- Is "Meeting Display" the top-of-panel **participants dropdown** (`ZoneParticipantsSubmenu`,
  opened via the header's member-icon button) or the **"In meeting" section of the right-side
  member panel** (`vo-member-panel.tsx`)? Both are affected by the same root cause but are
  different UI surfaces — confirm which one(s) the user means before scoping the PR.
- Desired semantics: should "in meeting" require an actual LiveKit media-room join (audio or
  video published), or should walking into the zone rectangle continue to count (current
  VO model, "physically standing there = in the meeting", similar to Gather)? This changes
  whether the fix is "sync geometry faster" vs "redefine membership to be media-plane only".

---

## 2. Meeting Display tile size should stay fixed across pages, not re-grow on later pages

**What (verified):** Tile size in the expanded grid is NOT a fixed constant — it's whatever
flexbox computes for the CURRENT page's tile count. The grid pages 10 at a time (2 rows × 5
cols); each row is `flex-1 justify-center`, each tile is `flex-1` (capped at
`max-w-[440px] max-h-[440px]`). So a page with 5 tiles crammed into one row shrinks them down
(as reported, "200×200"); paging to page 2 with e.g. 2 tiles left recomputes flex distribution
for just those 2 tiles, so they grow back up (toward the 440px cap) instead of staying at the
page-1 size.

**Where:** `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx:208-338`
(`gridPages`/`gridRows` computation + the `flex-1`/`justify-center` row+card layout), and
`ExpandedDisplayCard` in `zyra-app/views/user/virtual-office/components/zone-enter-tiles.tsx:396-533`
(fixed `max-w-[440px] max-h-[440px] flex-1` sizing, no global/shared size input).

**Sizing:** Small, self-contained — **1 PR**. Needs the exact intended rule from the user
(see open question) before implementing, since "keep page 1's size" vs "always size for the
total roster count" are different formulas.

**Open questions:**
- Exact sizing rule wanted: (a) tile size is fixed by the **largest page** (i.e. always sized
  as if 10 tiles were present, so it never changes across pages), or (b) tile size is fixed
  by **whatever page 1 computed** and every later page reuses that number even if it has
  fewer people, or (c) something else (e.g. a hardcoded 200×200 regardless of page/count)?
  This determines whether the fix computes size from `orderedParticipants.length` globally,
  from a memoized "size at first render", or a fixed design-token pixel size.

---

## 3. Big Map / HUD status doesn't turn red ("In Meeting") for the local user

**What (verified — confirmed bug):** `usersInMeeting` (the Set that drives the red "meeting"
status everywhere) is built by two loops that both **explicitly exclude the local user**:

- Loop 1 (same-floor, tile-geometry via `zoneMeetings`): self is only ever included in the
  underlying geometry check if `debugMyTile` is set — a **debug-panel-only** override, never
  populated in normal use. The media-plane union in `getAuthoritativeZoneParticipants` also
  explicitly skips self (`if (... || lc === selfLc || ...) continue`).
- Loop 2 (cross-floor, `zoneSections`): `if (uid === user?.id) continue` — self is skipped by
  design (comment says self is meant to be "driven by the instant tile path above instead").

Since loop 1 never actually captures self either (outside debug mode), **self can never be in
`usersInMeeting` under normal operation**. This directly breaks:
- `selfInMeeting` (line ~7091, itself just `usersInMeeting.has(user.id)`) — always `false`.
- `isInMeeting={!!(user && usersInMeeting.has(user.id))}` passed to `VOHud` (line ~9831) and
  `VOProfilePanel` (line ~10000) — the local status dot/HUD color never flips to
  `STATUS_DOT_COLOR.meeting` (red) via this path.

**Where:** `zyra-app/views/user/virtual-office/hero-virtual-office.tsx:6925-7098`
(`getZoneParticipants`, `getAuthoritativeZoneParticipants`, `zoneMeetings`, `usersInMeeting`,
`selfInMeeting` effect), consumed by `vo-hud.tsx:172-174` and the `VOProfilePanel` call site.

**Sizing:** Small, well-isolated — **1 PR**. Fix direction: derive `selfInMeeting` from
whether the local user is *actually* standing in a `zone_type === "meeting"` zone with ≥2
occupants (the local client already knows `activeZone`/`mediaZoneId` — this doesn't need to
go through the "other users" `usersInMeeting` set at all), then feed that same boolean into
`isInMeeting` at the HUD/profile-panel call sites instead of `usersInMeeting.has(user.id)`.

**Open questions:** None — this is a clear, self-contained bug fix. (Only worth flagging:
this interacts with #1's semantics question — if "in meeting" gets redefined to require an
actual media-room join, the self-status fix should use that same new definition.)

---

## 4. Screen share causes lag/freeze persisting after closing the app; mic misses quiet speech

**4a. Lag persisting after close — likely NOT an app code bug, needs resource-level check.**
No code path was found that could keep consuming CPU/GPU after the tab/app is fully closed —
LiveKit tracks/AudioContext are torn down on `disconnect()`/unmount, and there's no persistent
background worker outside the page lifecycle. This smells like an OS/browser/GPU-driver level
symptom (e.g. Chrome's screen-capture pipeline or a WASM background-effects model not being
released before the tab is force-killed) rather than an app bug that can be "fixed" here.
**Do not implement anything for 4a without a live repro** (does closing the *tab* fully stop
it, or only closing the OS window/app frame? does `chrome://process-internals` still show a
process after close? what OS/GPU?).

**4b. Mic doesn't pick up quiet speech (verified, concrete hypothesis):** The default noise
reduction level is **"high"** (`loadNoiseReductionLevel()` defaults to `"high"` — see
`lib/media-preference.ts:75` and its own test). High's post-RNNoise noise gate
(`HIGH_GATE_OPTS` in `lib/api/noise-processors.ts:123-128`) uses `openThreshold: -42dB`,
`closeThreshold: -52dB`, `holdMs: 250`. The gate can't distinguish "quiet speech" from
"residual background noise" — anything below the open threshold after RNNoise processing gets
silenced. A user speaking softly or sitting far from the mic is a very plausible match for
"eats quiet speech", and this is called out as a known tuning risk in the file's own header
comment ("if High starts clipping the tail of your own words in practice, ease HIGH_GATE_OPTS
back toward MEDIUM_GATE_OPTS's values").

**Where:** `zyra-app/lib/media-preference.ts:75` (default level), `zyra-app/lib/api/noise-processors.ts:104-128`
(gate thresholds), wired in `zyra-app/lib/api/sfu-client.ts` (`audioCaptureDefaults`, no
explicit `autoGainControl` set — relies on browser default).

**Sizing:** 4a — not sizeable as a code task without a live repro; possibly not fixable in-app
at all. 4b — small, **1 PR** (loosen `HIGH_GATE_OPTS`, and/or change the default level, and/or
explicitly request `autoGainControl: true` in `audioCaptureDefaults`), but needs a product
decision on which default to ship.

**Open questions:**
- 4a: what exactly is "closing gather"? Closing the browser tab, the whole browser, or an
  installed/PWA-style app window? Does the lag show up as high CPU in Activity
  Monitor/Task Manager, or is it perceived system-wide sluggishness? This changes whether
  it's even an app-fixable bug.
- 4b: should the DEFAULT noise-reduction level change (e.g. default to "low"/Medium instead
  of "high"), or should only the High gate's thresholds be loosened, or should we add
  explicit `autoGainControl: true`? These are different, independent changes.

---

## 5. Viewers see "Stop sharing" but no shared screen content

**What:** Code review did not find an obvious single-line bug — the relevant event wiring
looks internally consistent on paper:
- `screenSharerIds()` (`lib/api/sfu-client.ts:693-710`) only counts a sharer once
  `pub.isSubscribed && pub.track && !pub.isMuted` — i.e. it *should* wait for a real
  subscribed track before showing the tile.
- `_onRemoteTrackChanged` (fires on `TrackPublished`/`Unpublished`/`Muted`/`Unmuted`) and
  `_onTrackSubscribed`/`_onTrackUnsubscribed` (fires on actual subscription) both emit
  `"screenTracksChanged"`, which `use-meeting-media.ts:459-473` uses to recompute
  `screenSharerIds` + bump `screenEpoch`, and `ScreenVideo`'s effect
  (`zone-enter-tiles.tsx:60-89`) re-attaches whenever `screenEpoch` bumps.

Because the eventual-consistency chain looks correct in isolation, this needs a **live
repro** rather than a further static-code guess: check the presenter guard's 2-slot cap → server
`ws:share:*` rejection path (does a rejected/blocked 3rd presenter still leave a stale
LiveKit-level track published that a 4th client subscribes to but nothing renders?), and
check the VP9→VP8 `backupCodec` renegotiation path (`SCREEN_SHARE_CODEC` in
`sfu-client.ts:1106`) for a race where `attachScreen()` grabs a track reference just before a
codec-fallback republish swaps it out from under the `<video>` element.

**Where:** `zyra-app/lib/api/sfu-client.ts:678-710,916-989` (attach/subscribe wiring),
`zyra-app/views/user/virtual-office/use-meeting-media.ts:456-473`, `zyra-app/views/user/virtual-office/components/zone-enter-screen-share.tsx`
(`ScreenShareBox`/`ScreenVideo` render+attach).

**Sizing:** Needs live/browser-devtools investigation before it can be sized as a fix — flag
as **"investigate first"**, not a ready-to-implement PR.

**Open questions:**
- Reproduce with: 1 presenter + ≥2 viewers, note whether ALL viewers see nothing or only
  some; note if it recovers after presenter stops/restarts sharing (transient) or is
  permanently stuck for the session; check whether the presenter count is at/near the "max 2
  concurrent presenters" cap when it happens.

---

## 6. Screen share quality is blocky/degraded vs Gather Town

**What (verified):** The current settings are already fairly generous on paper — this
contradicts the "under-configured" assumption in the original report:
- Default quality `"720p30"` → `maxBitrate: 6_000_000` (6 Mbps), `contentHint: "detail"`,
  `degradationPreference: "maintain-resolution"` (`lib/api/sfu-client.ts:1122-1165`,
  `screenQualityProfile()`).
- `videoCodec: "vp9"` with `backupCodec: true` VP8 fallback, `dynacast`/`adaptiveStream`
  enabled on the Room.
- Higher presets exist up to `1080p60` at 12 Mbps, user-selectable via the share menu.

Since the encode-side config already looks reasonable, "blocky" is more likely one of: (a)
the viewer is on a constrained connection and `adaptiveStream`/simulcast/dynacast is stepping
them down to a lower layer (expected, not a bug), (b) the *default* quality (720p30) is what
most users leave selected and simply isn't "1080p" the way Gather might default to, or (c) a
genuine encoder/SFU-side issue that needs live bandwidth/stats inspection
(`getStats()`/LiveKit debug panel) to confirm actual negotiated resolution/bitrate rather than
just the requested ceiling.

**Where:** `zyra-app/lib/api/sfu-client.ts:1106-1166` (`SCREEN_SHARE_CODEC`,
`screenQualityProfile`), share-quality picker in `zyra-app/views/user/virtual-office/components/vo-screen-share-menu.tsx`.

**Sizing:** Not sizeable yet — needs a live side-by-side comparison (actual negotiated
resolution/bitrate via LiveKit stats) before deciding whether this is a default-quality
product decision or a real degradation bug.

**Open questions:**
- Is the complaint about the DEFAULT (720p30) experience, or does it still look blocky even
  after manually selecting 1080p30/1080p60 from the share-quality menu? These point to very
  different fixes (change the default vs. investigate an actual encode/network problem).

---

## 7. Green "speaking" border causes ALL tiles to resize/reflow when someone talks

**What (verified, plausible layout mechanism):** Every tile in the expanded/compact grid is
sized by flexbox (`flex-1`, rows `justify-center`, no fixed pixel width) with
`transition-all duration-300` applied to the SAME element whose border toggles on/off:

```
const borderClass = speakingNow ? "border-2 border-[#58D68D]" : handNumber != null ? "border-2 border-[#ECC819]" : ""
...
className={["group relative flex ... transition-all duration-300", ... borderClass, ...]}
```

(`CompactDisplayCard` — `zone-enter-tiles.tsx:219-235`; `ExpandedDisplayCard` —
`zone-enter-tiles.tsx:439-458`, identical pattern). Because there is no border reserved when
idle (`borderClass = ""`, i.e. 0-width border) and a 2px border appears only while speaking,
the flex item's border-box changes size, and flexbox must redistribute space among ALL
siblings in that row when one item's box changes — `transition-all` then animates that
redistribution across every tile simultaneously, which reads as the whole row "jumping" every
time someone starts/stops speaking.

**Where:** `zyra-app/views/user/virtual-office/components/zone-enter-tiles.tsx:219-235` (Compact)
and `:439-458` (Expanded).

**Sizing:** Small, self-contained — **1 PR**. Fix direction: reserve the border space
permanently (e.g. always render `border-2 border-transparent` and only swap the *color*, never
add/remove the border itself), or switch to a non-layout-affecting treatment (`outline`/
`box-shadow`/inset ring instead of `border`), and/or scope `transition-all` down to
`transition-colors` so unrelated geometry never animates.

**Open questions:** None — this is implementable directly once confirmed live (recommend a
quick live check that the fix actually removes the jump, since flexbox reflow behavior can be
subtle — not blocking scoping, just verification before merge).

---

## 8. Green speaking indicator sometimes doesn't appear despite actually speaking (own side)

**What (verified, plausible race):** The border/ring shows only when
`speaking && muted === false && !disconnected` (`zone-enter-tiles.tsx:221`, `:441`).
`speaking` comes from LiveKit's native `activeSpeakersChanged` (audio-level based, fast) while
`muted` comes from a **separate**, custom WS broadcast (`ws:audio:stateUpdate` /
`memberAudio` map in `use-meeting-media.ts`). Right after joining a room or unmuting, `muted`
can transiently be `undefined` ("no audio session announced yet") — and the check is
`muted === false` (strict), so `undefined` fails it even though the person IS actually
speaking per LiveKit. This is a state race between two independently-updated sources, not a
audio-detection sensitivity problem — matches "intermittent", not "never".

**Where:** `zyra-app/views/user/virtual-office/components/zone-enter-tiles.tsx:219-226,439-446`
(the `speakingNow` guard), fed by `speakingUserIds` (LiveKit) and `memberAudio` (custom WS) in
`zyra-app/views/user/virtual-office/use-meeting-media.ts`.

**Sizing:** Small — **1 PR** — e.g. treat `muted === undefined` as "assume live" for the
purpose of the speaking ring (or key the ring off `speaking` alone, since LiveKit's own
`activeSpeakersChanged` only ever includes participants whose mic is actually live per the
comment at `use-meeting-media.ts:385-388`).

**Open questions:**
- Confirm the "camera on" correlation is real and not coincidental (i.e. does it still
  intermittently fail with camera OFF)? If camera-on specifically makes it worse, that points
  to a CPU-contention angle (background-effects WASM model competing for the main thread /
  audio-worklet scheduling) rather than the mute-state race above — worth a live A/B check
  before merging the race fix, in case a second contributing cause also needs addressing.

---

## 9. Emoji/reaction floats up then warps left-right instead of a smooth path

**What (verified — confirmed bug):** `FloatingReaction`'s horizontal position is NOT part of
its Web-Animations-API keyframes (which only animate a fixed `translate(-50%, ...)` vertical
rise) — it's a **plain inline style** recomputed on every render:

```tsx
function FloatingReaction({ emoji, offset }: { emoji: string; offset: number }) {
  useEffect(() => { ref.current?.animate([...], {...}) }, [])   // vertical rise only, runs ONCE
  return <div ... style={{ left: `calc(50% + ${offset}px)` }}>{emoji}</div>   // re-set every render
}

function TileReactions({ reactions }) {
  return reactions.map((r, i) => (
    <FloatingReaction key={r.id} emoji={r.emoji} offset={(i % 3) - 1 === 0 ? 0 : ((i % 3) - 1) * 22} />
  ))
}
```

`offset` is derived from **`i`, the reaction's current index in the filtered array** — not a
stable per-reaction value. As sibling reactions for the same user expire and get pruned
(each has its own TTL, independently, from the `reactions` state in `use-meeting-media.ts`),
a still-live reaction's index shifts on the next render, so its `offset` (and therefore its
`left` position) changes value. Since `left` is a plain style (not part of the one-shot WAAPI
animation captured at mount), the emoji instantly snaps to the new horizontal position —
exactly matching "floats up smoothly, then warps/teleports left-right".

**Where:** `zyra-app/views/user/virtual-office/components/zone-enter-tiles.tsx:118-155`
(`FloatingReaction`, `TileReactions`) — used by both `CompactDisplayCard` and
`ExpandedDisplayCard`, i.e. both the compact bottom-bar meeting view and the full-screen
expanded grid. **No separate Pixi/map-level reaction renderer was found** — `zyra-engine/pixi-game/scene.ts`
has a wave-emoji ("👋") system (`triggerWaveAnimation`, unrelated feature) but no code for the
`reactions`/`sendReaction` feature at all.

**Sizing:** Small, self-contained — **1 PR**. Fix direction: give each reaction a stable
per-id offset assigned once (e.g. a small hash of `r.id`, or store the offset at creation time
in the `reactions` state itself) instead of deriving it from array index every render.

**Open questions:**
- Since no map-level (Pixi) reaction renderer exists, "happens on the big VO map too" likely
  refers to the **compact (non-expanded) meeting bar**, which renders as an overlay while the
  Pixi map is still visible behind/around it, not a second, separate implementation — please
  confirm this is what's meant before we close this as a single-location fix. If there really
  is a second, distinct emoji effect rendered directly over player sprites on the map, point
  us to it (not found in this pass).

---

## Prioritized / PR-sized Task Breakdown

Small, ready-to-implement (code-verified, no open blocking question beyond a definition check):

1. `fix(app): stop self's HUD/profile status from always missing meeting-red` — issue 3
2. `fix(app): give speaking-border tiles reserved space to stop grid reflow` — issue 7
3. `fix(app): don't gate the speaking ring on a not-yet-announced mute state` — issue 8 (pending camera-correlation check)
4. `fix(app): stabilize floating-reaction horizontal offset per reaction id` — issue 9
5. `fix(app): keep meeting-display tile size fixed across pagination` — issue 2 (pending exact sizing rule)

Needs a scope/semantics decision from the user before starting:

6. `fix(app+ws): meeting-display membership + kick effectiveness` — issue 1 (2 PRs: ws
   broadcast fix + app geometry-list fix), blocked on "what counts as in-meeting" definition
7. `fix(app): loosen default mic noise-gate for quiet speech` — issue 4b, blocked on which
   default/threshold change is wanted

Needs live investigation before any code is written (not sizeable yet):

8. Issue 4a — screen-share-induced lag persisting after close (may be OS/GPU-level, not app)
9. Issue 5 — screen share subscribed-but-blank for viewers (presenter-cap / codec-fallback race)
10. Issue 6 — screen share quality vs Gather (encode settings already look reasonable; likely
    default-quality perception or a live bandwidth/stats question, not an obvious code bug)

## Definition-of-Done checklist for this planning pass
- [x] Every issue investigated against actual code (file+line cited), not guessed
- [x] Ambiguous scope items flagged as open questions instead of assumed
- [x] No production code changed
- [x] DB impact: none of these 9 issues require a migration
- [x] No secrets referenced
