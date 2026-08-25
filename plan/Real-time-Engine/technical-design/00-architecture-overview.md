# Technical Design — 00 · Architecture Overview (shared foundation)

> **Module:** [Real-time Engine](../spec.md) · ClickUp [86d2weryr](https://app.clickup.com/t/86d2weryr)
> อ่านไฟล์นี้ก่อน แล้วค่อยดู technical design รายตาม task (01–09)

---

## 1. Service Topology (ของจริงในโปรเจกต์ตอนนี้)

```
┌─────────────┐   REST (auth, chat persist,     ┌─────────────┐
│  zyra-app   │   presence heartbeat, workspace) │  zyra-api   │  Go REST + SSE
│  (Next.js)  │ ───────────────────────────────► │             │  PostgreSQL
│             │                                   └─────────────┘
│ Phaser/Pixi │   WebSocket (move, presence,      ┌─────────────┐
│ WorkspaceWS │   room, chat-space relay)          │   zyra-ws   │  Go WS hub
│   Client    │ ◄───────────────────────────────► │  (gorilla)  │  Redis Pub/Sub
└─────┬───────┘                                     └─────────────┘
      │  WebRTC media (audio/video/screen)  ┌──────────────────────┐
      └────────────────────────────────────►│  zyra-sfu (LiveKit)  │  ◄── SC-RTE-05..09
                                             │  :7880  + Redis (HA) │
                                             └──────────────────────┘
```

| Service | Role | สถานะสำหรับ module นี้ |
|---------|------|------------------------|
| `zyra-api` | REST + presence SSE, DB persist, **mint LiveKit token** | มีอยู่แล้ว — เพิ่ม media-token endpoint |
| `zyra-ws` | WebSocket hub, movement, room state, chat-space, **media state (control plane)** | **มีอยู่แล้ว** — SC-RTE-01..04 ต่อยอด |
| `zyra-app` | UI + `WorkspaceWSClient` + game scene + **LiveKit client SDK** | มีอยู่แล้ว — ต่อยอด client |
| **`zyra-sfu`** | media forwarding (audio/video/screen) — **LiveKit v1.8** | **สร้างแล้ว** ([AGENTS.md](../../../../zyra-sfu/AGENTS.md)) — เหลือเชื่อม token + client (SC-RTE-05..09) |

---

## 2. สิ่งที่มีอยู่แล้ว (reuse — ห้ามสร้างซ้ำ)

### zyra-ws (Go)
| ของที่มี | ไฟล์ |
|---------|------|
| `Hub` / `Room` / `Client` + read/write pump | `zyra-ws/internal/hub/hub.go`, `client.go` |
| Message envelope `Envelope{Type, Payload}` | `zyra-ws/internal/hub/message.go:79` |
| AOI grid (proximity fan-out, 16×16 cell, 3×3 neighbourhood) | `zyra-ws/internal/hub/aoi.go` |
| Move ticker (buffer 50ms flush) | `zyra-ws/internal/hub/hub.go` (`runMoveTicker`) |
| Chat-space server-authoritative (`chat_space_state`) | `zyra-ws/internal/hub/chatspace.go` |
| Room enter/exit + knock | `zyra-ws/internal/hub/room.go`, `message.go` |
| Redis store (presence TTL, snapshot, `vo:notify`) | `zyra-ws/main.go`, hub store |

### zyra-app (TS)
| ของที่มี | ไฟล์ |
|---------|------|
| `WorkspaceWSClient` (connect/backoff/watchdog/clock-sync) | `zyra-app/lib/api/workspace-ws.ts` |
| Inbound/outbound message unions | `zyra-app/lib/api/workspace-ws-types.ts` |
| Binary `moved` decoder | `zyra-app/lib/api/workspace-ws.ts:90` |
| Game scene (Pixi) | see memory `[[vo-renderer-and-data-flow]]` |

### zyra-api (Go)
| ของที่มี | ไฟล์ |
|---------|------|
| Workspace presence REST heartbeat (`tile_x/y`, `last_visited_at`) | `zyra-api/internal/handler/workspace_presence_handler.go` |
| Admin presence SSE (`online`/`offline`/`ping`, TTL 65s) | `zyra-api/internal/handler/presence_handler.go` |

---

## 3. Message Envelope (มาตรฐานเดิม — ใช้ต่อ)

ทุก WS message ใช้ envelope เดียวกัน:

```go
// zyra-ws/internal/hub/message.go
type Envelope struct {
    Type    string          `json:"type"`
    Payload json.RawMessage `json:"payload"`
}
```

**Naming convention** (คงของเดิม):
- Outbound string value: `"moved"`, `"room_entered"`, `"chat_space_state"` หรือ colon style `"chat:message:new"`
- Go constants: `MsgMoved`, `MsgRoomEntered`, `MsgChatSpaceState`
- Client-side (outbound) constants: `ClientMsg*`
- Payload struct: PascalCase `MovedPayload`

> **กฎ:** media/room control events ใหม่ทั้งหมด (SC-RTE-05..09) ให้ใช้ colon namespace ตาม spec: `ws:room:*`, `ws:audio:*`, `ws:share:*` → map เป็น Go const `MsgRoom*`, `MsgAudio*`, `MsgShare*`

---

## 4. Media Layer — ✅ ตัดสินใจแล้ว: LiveKit (self-hosted) = `zyra-sfu`

RTE-0.1 ปิดแล้ว — media server = **LiveKit v1.8 self-hosted** อยู่ที่ service `zyra-sfu`
(รายละเอียด config: [zyra-sfu/AGENTS.md](../../../../zyra-sfu/AGENTS.md))

| ด้าน | ค่าจริง (จาก `zyra-sfu/livekit.yaml`) |
|------|--------------------------------------|
| Image | `livekit/livekit-server:v1.8` |
| HTTP API | `:7880` · TCP fallback `:7881` · media UDP `50000–60000` |
| Simulcast / adaptive | `enable_dynacast: true` → SC-RTE-09 |
| Max participants/room | `50` (ตรงกับ `DEFAULT_CAPACITY` ของ zyra-ws) |
| Empty room cleanup | `empty_timeout: 5m` |
| State backend | Redis **shared กับ zyra-ws** (HA) |
| Token | zyra-api mint ด้วย `LIVEKIT_API_KEY/SECRET` (prod ใช้ env `LIVEKIT_KEYS`) |

### Division of responsibility
- **`zyra-sfu` (LiveKit)** = media plane: forward audio/video/screen tracks, dynacast/simulcast, subscribe
- **`zyra-ws`** = control plane: room membership, mute/camera/share **state** (broadcast ให้ UI sync), presenter guard, force-mute
- **`zyra-api`** = mint LiveKit token (`POST /api/user/rooms/{id}/media-token`, UserGuard) + room service
- **`zyra-app`** = LiveKit client SDK (`livekit-client`) connect ตรงไป SFU ผ่าน `NEXT_PUBLIC_LIVEKIT_URL`
- **หลักการ:** media ไหลผ่าน SFU เท่านั้น, **state/indicator ไหลผ่าน `zyra-ws`** เพื่อให้ทุก client เห็นตรงกัน (แม้คนที่ยังไม่ join media)

### Room mapping
- **1 LiveKit Room = 1 VO room/zone** → map ตรงกับ SC-RTE-04
- 1 participant ส่งได้หลาย track (camera + screen แยกกัน) → SC-RTE-07
- identity = `user_id` · grants `canPublish`/`canSubscribe` ตาม role
- **Zone cap = 20 คน** · screen share ≤ 2/zone · กล้องเปิดได้ทุกคนใน zone
- **Map capacity = 100–1,000 คน** (ตาม tier) — media ยังบาวด์ที่ zone 20 เสมอ

> 📊 **Scale/capacity:** 2 แกน — map เยอะ (100→1000+) + map ใหญ่ (1 map ≤1000 คน). Media บาวด์/zone แต่รวมต้อง LiveKit **cluster**. Control-plane (1000 คน/map) พึ่ง **AOI + workspace sharding**. Reliability = audio-first (RED/FEC). Resource ผูกกับ **billing tier**. รายละเอียดทั้งหมด: [capacity-scaling.md](../capacity-scaling.md)

---

## 5. Cross-cutting concerns (ใช้ร่วมทุก task)

| Concern | แนวทาง | อ้างอิง task |
|---------|--------|-------------|
| **Auth** | JWT ใน WS query param (`token`) + LiveKit token แยก (mint จาก zyra-api) | ทุก task |
| **Horizontal scale** | Redis Pub/Sub fan-out ข้าม `zyra-ws` instance | 01, 03 |
| **Reconnect / grace** | `WorkspaceWSClient` backoff (มีอยู่) + server grace 2 นาที (ใหม่) | 02 |
| **Idempotency** | server ต้อง dedupe event ซ้ำ (enter/leave/share) | 03, 04, 07 |
| **Server-authoritative** | state ทั้งหมด server ชนะ local (มี pattern ใน chat-space แล้ว) | 02, 03 |
| **Cleanup on disconnect** | disconnect → remove member, stop share, clear presence | 02, 04, 07 |

---

## 6. Data Model กลาง (เพิ่มใน `Room` ของ zyra-ws)

```go
// เพิ่ม field เข้า Room struct เดิม (zyra-ws/internal/hub/room.go)
type MediaRoomState struct {
    Members         map[string]*MemberMedia // user_id -> media state
    HasActiveShare  bool
    Presenters      []string                // user_id ของคนที่ share อยู่ (max 2, SC-RTE-09)
    AudioActiveCount int                     // จำนวนคน unmute (SC-RTE-05)
    IsLocked        bool                     // SC-RTE-03 (⚠️ ถูกขีดฆ่าใน spec — reserve field ไว้)
}

type MemberMedia struct {
    UserID    string
    Muted     bool
    CameraOn  bool
    Sharing   bool
    ForcedMuteBy string // user_id คนที่สั่ง force mute (SC-RTE-05)
}
```

State นี้ **broadcast ผ่าน `zyra-ws`** ไม่ใช่ REST (ตาม SC-RTE-03 rule) — ดูรายละเอียดแต่ละ task

---

## 7. Index — technical design รายตาม task

| # | Task | ต่อยอด/ใหม่ | ไฟล์ |
|---|------|-----------|------|
| 01 | Avatar Position Sync | ต่อยอด zyra-ws AOI/presence | [01-avatar-position-sync.md](01-avatar-position-sync.md) |
| 02 | Reconnect / Desync Recovery | ต่อยอด client backoff + server grace | [02-reconnect-desync-recovery.md](02-reconnect-desync-recovery.md) |
| 03 | Room State Management | ต่อยอด room + media state | [03-room-state-management.md](03-room-state-management.md) |
| 04 | Room Member Join / Leave | ต่อยอด room + SFU join | [04-room-member-join-leave.md](04-room-member-join-leave.md) |
| 05 | Mute / Unmute Audio | ใหม่ (SFU + ws:audio) | [05-mute-unmute-audio.md](05-mute-unmute-audio.md) |
| 06 | Camera On / Off | ใหม่ (SFU + ws:video) | [06-camera-on-off.md](06-camera-on-off.md) |
| 07 | Screen Share — Full Screen | ใหม่ (SFU + ws:share) | [07-screen-share-fullscreen.md](07-screen-share-fullscreen.md) |
| 08 | Screen Share — Window / Tab | ต่อยอด 07 | [08-screen-share-window-tab.md](08-screen-share-window-tab.md) |
| 09 | Screen Share — Viewer View | ต่อยอด 07 + simulcast | [09-screen-share-viewer.md](09-screen-share-viewer.md) |
