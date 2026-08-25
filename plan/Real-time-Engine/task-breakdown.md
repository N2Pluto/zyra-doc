# Task Breakdown — Real-time Engine Module

> **Module:** [Real-time Engine](spec.md) · ClickUp [86d2weryr](https://app.clickup.com/t/86d2weryr)
> อ้างอิง [spec.md](spec.md) · [technical-design/](technical-design/) · [test-plan.md](test-plan.md)
> แต่ละ task ออกแบบให้จบได้ใน **1 PR** · commit ใช้ Conventional Commits

## Legend
- **Service:** `ws` = zyra-ws · `api` = zyra-api · `app` = zyra-app
- **Est:** S = ≤0.5d · M = 1–2d · L = 3–5d
- **สถานะฐาน:** ✅ ต่อยอดของเดิม · 🆕 สร้างใหม่ · ⛔ blocked (รอ decision)

---

## Phase 0 — Foundations & Decisions

| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-0.1 | ✅ **[Decision] SFU = LiveKit self-hosted** — provisioned แล้วที่ `zyra-sfu` (v1.8, :7880, dynacast on, Redis shared) ([AGENTS.md](../../../zyra-sfu/AGENTS.md)) | `zyra-sfu` | **DONE** | — |
| RTE-0.2 | Confirm scope: SC-RTE-03 lock (ตัดถาวร?), force-mute policy (05), backoff numbers (02) | — | — | S |
| RTE-0.3 | เพิ่ม media event constants + payload struct (`ws:room:*`, `ws:audio:*`, `ws:video:*`, `ws:share:*`) ใน `message.go` + TS types | ws, app | RTE-0.2 | M |
| RTE-0.4 | `MediaRoomState` / `MemberMedia` struct ใน `Room` + accessor (thread-safe) | ws | RTE-0.3 | M |
| RTE-0.5 | LiveKit token endpoint `POST /api/user/rooms/{id}/media-token` (mint ด้วย `LIVEKIT_API_KEY/SECRET`, identity=user_id, room={id}, UserGuard) + wire `LIVEKIT_URL` env | api | RTE-0.1 ✅ | M |
| RTE-0.6 | Frontend LiveKit client wrapper (`livekit-client`: connect/publish/subscribe/adaptiveStream) + `NEXT_PUBLIC_LIVEKIT_URL` | app | RTE-0.1 ✅ | M |

> ✅ **RTE-0.1 ปิดแล้ว** (SFU provisioned) → Group C, D, E **unblocked** — เหลือ RTE-0.5/0.6 (เชื่อม token + client) เป็น prerequisite
> Group A, B(SC-03) เริ่มได้ทันที (ไม่พึ่ง SFU)

---

## Group A — Presence & Sync (SC-RTE-01, 02) · ✅ ต่อยอด zyra-ws

### SC-RTE-01 · Avatar Position Sync — [design](technical-design/01-avatar-position-sync.md)
| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-1.1 | Multi-tab dedupe: 1 WS connection ต่อ user + `resolveStatus()` priority (DND>Busy>Away>Available) | ws | — | M |
| RTE-1.2 | `status_changed` fan-out ทุก channel (Map/DM/Sidebar/Member Panel) | ws, app | RTE-1.1 | M |
| RTE-1.3 | Server heartbeat miss-counter (ping 30s × miss 3 = offline, broadcast ภายใน 5s) | ws | — | S |
| RTE-1.4 | Client interpolation ใช้ server timestamp (verify smooth, ไม่กระตุก) | app | — | S |
| RTE-1.5 | Redis Pub/Sub fan-out ข้าม instance (idempotent, กัน double-broadcast) | ws | — | M |
| RTE-1.6 | Unit + integration + E2E tests (throttle, resolveStatus, heartbeat FSM, 2-node, latency) | ws, app | RTE-1.1..1.5 | M |
| RTE-1.7 | Load test 50 CCU/workspace (p95 < 500ms, ไม่ lag) | ws | RTE-1.6 | M |

### SC-RTE-02 · Reconnect / Desync Recovery — [design](technical-design/02-reconnect-desync-recovery.md)
| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-2.1 | ปรับ backoff ให้ตรง spec (1/2/4/8/16/30s, max 5) — reconcile กับ cap เดิม | app | RTE-0.2 | S |
| RTE-2.2 | Reconnecting indicator ใน HUD (non-blocking UI + game loop) | app | — | S |
| RTE-2.3 | Client message queue (memory, cap 10, drop oldest, flush FIFO หลัง reconnect) | app | — | M |
| RTE-2.4 | Server grace session (Redis TTL 120s: position/room_id/mute/camera) + rejoin | ws | RTE-0.4 | M |
| RTE-2.5 | Full snapshot request หลัง reconnect (server-authoritative merge) | ws, app | RTE-2.4 | M |
| RTE-2.6 | Retry-fail error banner (["ลองใหม่"]["ออกจาก Office"]) + `session_expired` modal+redirect | app | RTE-2.1 | S |
| RTE-2.7 | Tests (backoff seq, queue cap, grace boundary 2min, kill/restore network E2E) | ws, app | RTE-2.1..2.6 | M |

---

## Group B — Room State (SC-RTE-03, 04) · ✅ ต่อยอด + ⛔ SFU sync

### SC-RTE-03 · Room State Management — [design](technical-design/03-room-state-management.md)
| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-3.1 | `RoomState` payload (members, member_count, has_active_share, audio_active_count) + `ws:room:stateUpdate` broadcast | ws | RTE-0.4 | M |
| RTE-3.2 | Member count + share indicator บน room label + minimap (render) | app | RTE-3.1 | M |
| RTE-3.3 | Reset room state เมื่อคนสุดท้ายออก (idempotent) + concurrent-safe `members[]` | ws | RTE-3.1 | S |
| RTE-3.4 | Tests (add/remove/toggle/reset, no-REST assertion, minimap E2E) | ws, app | RTE-3.1..3.3 | M |

> lock/`is_locked` = reserve field เท่านั้น (ขีดฆ่าใน spec, รอ RTE-0.2)

### SC-RTE-04 · Room Member Join / Leave — [design](technical-design/04-room-member-join-leave.md)
| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-4.1 | Join validate (capacity, lock-reserve) + `ws:room:enterDenied {reason}` | ws | RTE-3.1 | M |
| RTE-4.2 | WS room ↔ SFU media room sync (join/leave ตามหลัง WS event) | ws, app | RTE-0.5, RTE-0.6, RTE-4.1 | L |
| RTE-4.3 | Audio auto-join ตาม user preference ตอน join | app | RTE-4.2 | S |
| RTE-4.4 | Presenter-left → force `ws:share:stopped` + cleanup on disconnect | ws | RTE-4.1 | M |
| RTE-4.5 | Lock/full indicator (UI) | app | RTE-4.1 | S |
| RTE-4.6 | Tests (validate, SFU sync, presenter-left, disconnect cleanup, 2-user E2E) | ws, app | RTE-4.1..4.5 | M |

---

## Group C — Audio & Video (SC-RTE-05, 06) · 🆕 LiveKit · prereq RTE-0.5/0.6

### SC-RTE-05 · Mute / Unmute Audio — [design](technical-design/05-mute-unmute-audio.md)
| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-5.1 | Client toggle mute (`track.enabled`, <200ms) + shortcut `M` (guard double-press) | app | RTE-0.6 | M |
| RTE-5.2 | `ws:audio:muteChanged` → server track state → `ws:audio:stateUpdate` broadcast + mic-slash icon | ws, app | RTE-0.4 | M |
| RTE-5.3 | `audio_active_count` recompute (≥0) ใน RoomState | ws | RTE-5.2, RTE-3.1 | S |
| RTE-5.4 | Force-mute: `ws:audio:forceMute` → `ws:audio:forceMuted {by_user_id}` + toast, target unmute เองเท่านั้น | ws, app | RTE-0.2, RTE-5.2 | M |
| RTE-5.5 | Speaking animation (active-speaker/analyser) รอบ avatar | app | RTE-5.1 | M |
| RTE-5.6 | Default mute ตาม preference ตอน join + tests | ws, app | RTE-5.1..5.5 | M |

### SC-RTE-06 · Camera On / Off — [design](technical-design/06-camera-on-off.md)
| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-6.1 | Client toggle camera (`videoTrack.enabled`, <500ms, no ghost track) + shortcut `V` | app | RTE-0.6 | M |
| RTE-6.2 | `ws:video:cameraChanged` → `ws:video:stateUpdate` broadcast (ไม่มี force — privacy) | ws, app | RTE-0.4 | S |
| RTE-6.3 | Camera-off fallback tile: avatar preview / initials + camera-slash icon | app | RTE-6.1 | M |
| RTE-6.4 | Permission handling: ขอครั้งแรกตอน join, denied → button disable + tooltip | app | RTE-6.1 | S |
| RTE-6.5 | Default camera-off ตาม preference + tests (fake-device E2E) | ws, app | RTE-6.1..6.4 | M |

---

## Group D — Screen Share Presenter (SC-RTE-07, 08) · 🆕 LiveKit · prereq RTE-0.5/0.6

### SC-RTE-07 · Screen Share Full Screen — [design](technical-design/07-screen-share-fullscreen.md)
| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-7.1 | Single-presenter guard (`startShare`, idempotent) + `ws:share:start/started/denied` | ws | RTE-0.4 | M |
| RTE-7.2 | Client getDisplayMedia (Entire Screen, 1920×1080@15fps) + publish screen track (แยกจาก camera) | app | RTE-0.6 | M |
| RTE-7.3 | HUD sharing indicator + stop 2 ทาง (HUD button + `track.onended`) | app | RTE-7.2 | M |
| RTE-7.4 | Cleanup: presenter leave/tab-close/disconnect → force `ws:share:stopped` + system message | ws | RTE-7.1, RTE-4.4 | M |
| RTE-7.5 | Permission-denied error toast + วิธีแก้ | app | RTE-7.2 | S |
| RTE-7.6 | Tests (guard, stop sources, disconnect cleanup, fake-device E2E) | ws, app | RTE-7.1..7.5 | M |

### SC-RTE-08 · Screen Share Window / Tab — [design](technical-design/08-screen-share-window-tab.md)
| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-8.1 | getDisplayMedia constraints ตาม source: Window 15fps / Tab 30fps, tab audio | app | RTE-7.2 | M |
| RTE-8.2 | Source-type detect (`displaySurface`) + verify window isolation | app | RTE-8.1 | S |
| RTE-8.3 | Tests (source→fps mapping, tab audio, fake-device E2E) — backend reuse 07 | app | RTE-8.1..8.2 | S |

---

## Group E — Screen Share Viewer (SC-RTE-09) · 🆕 LiveKit · prereq RTE-0.5/0.6

### SC-RTE-09 · Screen Share Viewer View — [design](technical-design/09-screen-share-viewer.md)
| ID | Task | Service | Dep | Est |
|----|------|---------|-----|-----|
| RTE-9.1 | ขยาย presenter guard 1→2 (max 2, คนที่ 3 denied) | ws | RTE-7.1 | S |
| RTE-9.2 | Auto layout switch (featured เมื่อ active share, กลับ grid เมื่อ stop) | app | RTE-7.1 | M |
| RTE-9.3 | Auto-subscribe screen stream + audio (no leak เมื่อเข้า/ออกรัว ๆ) | app | RTE-0.6, RTE-9.2 | M |
| RTE-9.4 | Presenter name overlay + zoom (clamp max 2x) + PiP video tiles | app | RTE-9.2 | M |
| RTE-9.5 | Simulcast/adaptive quality ตาม viewer bandwidth | app | RTE-0.6 | M |
| RTE-9.6 | Split-screen layout เมื่อ 2 presenters | app | RTE-9.1, RTE-9.2 | M |
| RTE-9.7 | Tests (layout select, 2-presenter split, zoom clamp, latency<500ms E2E) | ws, app | RTE-9.1..9.6 | M |

---

## Dependency Order (แนะนำลำดับทำ)

```
RTE-0.1 (SFU = LiveKit) ✅ DONE — zyra-sfu provisioned
RTE-0.2 (scope confirm)
   │
RTE-0.3 → RTE-0.4 (events + state struct)
   │
   ├─► Group A (SC-01, 02)  ← เริ่มได้ทันที ไม่พึ่ง SFU
   ├─► Group B (SC-03) → SC-04 ต้องรอ RTE-0.5/0.6 (LiveKit token+client) สำหรับ media sync
   │
RTE-0.5 (token endpoint) + RTE-0.6 (LiveKit client) ─►
   ├─► Group C (SC-05, 06)
   ├─► Group D (SC-07 → 08)
   └─► Group E (SC-09 ← ต่อจาก 07)
```

**Critical path:** `RTE-0.5/0.6 (LiveKit wiring) → RTE-7.1/7.2 → RTE-9.x`

**ทำ parallel ได้:** Group A ‖ Group B(SC-03) ‖ RTE-0.5/0.6 (LiveKit wiring) ตั้งแต่ต้น — SFU server พร้อมแล้ว

---

## Milestones

| M | ขอบเขต | Tasks |
|---|--------|-------|
| **M1 — Presence** | SC-RTE-01, 02 พร้อม load test 50 CCU | Group A |
| **M2 — Rooms** | SC-RTE-03, 04 (04 หลัง SFU) | Group B |
| **M3 — A/V** | SC-RTE-05, 06 | Group C |
| **M4 — Screen Share** | SC-RTE-07, 08, 09 | Group D, E |

## Definition of Done (module)
- [ ] ทุก SC-RTE-01..09 ผ่าน Acceptance Criteria ใน [spec.md](spec.md)
- [ ] Coverage: unit ≥80% · integration ≥70% · e2e ≥50% ([test-plan.md](test-plan.md))
- [ ] `go test ./...` (ws + api) และ `vitest run` (app) ผ่านทั้งหมด
- [ ] Load test 50 CCU/workspace ผ่าน
- [ ] ไม่มี secret hardcode, ไม่มี PII ใน log, member API ผ่าน `/api/user/*` เท่านั้น
