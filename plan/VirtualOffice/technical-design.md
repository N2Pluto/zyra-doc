# [Module] Virtual Office — Technical Design

**Spec:** [spec.md](./spec.md) | **Test Plan:** [test-plan.md](./test-plan.md) | **UX/UI:** [ux-ui-plan.md](./ux-ui-plan.md)  
**วันที่:** 2026-06-17

---

## 1. System Architecture

### 1.1 High-Level Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Browser (zyra-app)                            │
│                                                                         │
│  ┌──────────────┐   ┌──────────────┐   ┌───────────────────────────┐   │
│  │  Next.js     │   │  Phaser      │   │  Zustand Store            │   │
│  │  Pages/API   │   │  Game Scene  │   │  virtual-office.store.ts  │   │
│  │  Routes      │   │  (Canvas)    │   │                           │   │
│  └──────┬───────┘   └──────┬───────┘   └────────────┬──────────────┘  │
│         │                  │                         │                  │
│         │    REST fetch()  │  WS send/recv           │ dispatch         │
└─────────┼──────────────────┼─────────────────────────┼──────────────────┘
          │                  │                         │
          ▼ HTTPS            ▼ WSS                     │
┌──────────────────┐  ┌──────────────────────────────┐ │
│   zyra-api       │  │         zyra-ws               │ │
│   (Go + Gin)     │  │   (Go + gorilla/websocket)    │ │
│                  │  │                               │ │
│  ┌────────────┐  │  │  ┌──────┐  ┌──────────────┐  │ │
│  │  Handler   │  │  │  │ Hub  │  │    Room      │  │ │
│  │  Service   │  │  │  │      ├─►│  (per wsId)  │  │ │
│  │  Model     │  │  │  └──────┘  └──────┬───────┘  │ │
│  └────────────┘  │  │                   │           │ │
└────────┬─────────┘  └───────────────────┼───────────┘ │
         │                                │             │
         ▼                                ▼             │
┌─────────────────┐            ┌──────────────────────┐ │
│   PostgreSQL    │            │        Redis          │◄┘
│                 │            │                       │
│  tb_workspace   │            │  vo:presence:{ws}:*   │
│  tb_workspace   │            │  vo:room:{ws}:*       │
│    _member      │            │  vo:knock_cd:{ws}:*   │
│  tb_workspace   │            │  vo:follow:{ws}:*     │
│    _invitation  │            │  vo:wave_cd:{ws}:*    │
│  tb_private     │            │  vo:zone_granted:*    │
│    _zone_access │            └──────────────────────┘
│    _log         │
│  tb_workspace   │
│    _audit_log   │
└─────────────────┘
```

### 1.2 Request Flow Diagram

```
                        ── REST (HTTPS) ──────────────────────────────────────

  Browser                    Next.js API Route          zyra-api
    │                              │                        │
    │── fetch("/api/user/ws/:id")─►│                        │
    │                              │── GET /api/user/ws/:id►│
    │                              │                        │── query PostgreSQL
    │                              │◄── 200 {workspace} ────│
    │◄── workspace data ───────────│                        │

                        ── WebSocket (WSS) ───────────────────────────────────

  Browser                    zyra-ws (Hub)           Redis
    │                              │                    │
    │── WS connect /:wsId ────────►│                    │
    │                              │── HSET presence ──►│
    │◄── welcome {players} ────────│                    │
    │                              │                    │
    │── move {tile_x, tile_y} ────►│                    │
    │                              │── validateMove()   │
    │                              │── HSET tile_x/y ──►│
    │◄── moved (broadcast) ────────│                    │
    │                              │                    │
    │── knock {zone_id} ──────────►│                    │
    │                              │── GET knock_cd ───►│
    │                              │◄── (nil = ok) ─────│
    │                              │── send knock_request ──► owner
    │◄── knock_request ACK ────────│                    │

                        ── Auth Token Flow ───────────────────────────────────

  Browser ──── Cookie (zyra_token) ─────────────────────────────────────────►
               All requests carry JWT in cookie (set by zyra-api on login)
               zyra-ws reads token from query param: ?token=<jwt>
```

### 1.3 WebSocket Hub Architecture

```
zyra-ws process
│
└── Hub (singleton)
      │  sync.Map: workspaceID → *Room
      │
      ├── Room: "workspace-abc"
      │     │  sync.Map: userID → *Client
      │     │
      │     ├── Client: user-1  ──── goroutine readPump  ──► parse Envelope
      │     │                   └─── goroutine writePump ◄── chan Envelope
      │     ├── Client: user-2
      │     └── Client: user-3
      │
      └── Room: "workspace-xyz"
            ├── Client: user-4
            └── Client: user-5

Message broadcast path:
  Client.readPump → Room.handleClientMessage() → Room.broadcast(msg, excludeUserID)
  Each broadcast writes to Client.send chan → writePump flushes to WS conn
```

### 1.4 Frontend Layer Diagram

```
/workspace/[id]/play                         z-index stack
│
├── [z:0]  <GameCanvas>                      Phaser iframe-like canvas
│           │
│           └── VirtualOfficeScene
│                 ├── TileLayer: floor
│                 ├── TileLayer: walls / objects
│                 ├── ZoneLayer: rooms + private zones
│                 ├── SpriteGroup: RemotePlayers (interpolated)
│                 ├── Sprite: LocalPlayer (WASD/click input)
│                 └── TileLayer: decoration (top)
│
└── [z:10] <HUDLayer>  pointer-events: none (pass-through to canvas)
              │         interactive children use pointer-events: auto
              ├── <Sidebar>              left  72px
              ├── <RoomDisplayPanel>     top   center
              ├── <MemberPanel>          right collapsible
              ├── <Minimap>              bottom-right 180×135px
              ├── <StatusPicker>         bottom-left popover
              ├── <BottomToolbar>        bottom center
              ├── <WaveNotification>     top-right toast stack
              ├── <KnockNotification>    top-right toast (owner)
              ├── <KnockOverlay>         zone overlay (requester)
              └── <FollowBar>            bottom center bar
```

### 1.5 Services ที่เกี่ยวข้อง

| Service | ภาษา | Role |
|---|---|---|
| `zyra-api` | Go + Gin | REST API: workspace, member, invite, leave, transfer |
| `zyra-ws` | Go + gorilla/websocket | Real-time: movement, status, wave, knock, follow |
| `zyra-app` | Next.js 16 / React 19 | Frontend: game canvas, HUD, panels |
| PostgreSQL | — | Persistent data: workspace, member, invite, audit log |
| Redis | — | Ephemeral: online presence, knock cooldown, follow state, wave cooldown |

---

## 2. Database Schema Changes

### 2.1 ตารางที่มีอยู่แล้ว (ใช้ได้เลย)

| Table | ใช้กับ |
|---|---|
| `tb_workspace` | SC-VO-01, SC-PROFILE-06/07 |
| `tb_workspace_member` | SC-SB-10/11, SC-PROFILE-06/07 |
| `tb_workspace_invitation` | SC-SB-10/11 (model `WorkspaceInviteRow` มีแล้ว) |
| `tb_map_zone` | SC-VO-06/07 (room + private zone data) |

### 2.2 Column เพิ่มใน `tb_workspace`

```sql
ALTER TABLE tb_workspace
  ADD COLUMN capacity          INT          DEFAULT 50,
  ADD COLUMN transferred_to    VARCHAR(36),        -- SC-PROFILE-07
  ADD COLUMN transferred_at    TIMESTAMPTZ;
```

### 2.3 Column เพิ่มใน `tb_workspace_member`

```sql
ALTER TABLE tb_workspace_member
  ADD COLUMN last_position_x   INT,
  ADD COLUMN last_position_y   INT,
  ADD COLUMN last_map_id       VARCHAR(36);        -- spawn at last position
```

### 2.4 ตารางใหม่: `tb_private_zone_access_log`

```sql
CREATE TABLE tb_private_zone_access_log (
  id           VARCHAR(36)  PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id VARCHAR(36)  NOT NULL,
  map_id       VARCHAR(36)  NOT NULL,
  zone_id      VARCHAR(36)  NOT NULL,
  user_id      VARCHAR(36)  NOT NULL,
  action       VARCHAR(10)  NOT NULL CHECK (action IN ('knock','allow','deny')),
  created_at   TIMESTAMPTZ  DEFAULT now()
);
CREATE INDEX ON tb_private_zone_access_log (workspace_id, zone_id, user_id);
```

### 2.5 ตารางใหม่: `tb_workspace_audit_log`

```sql
CREATE TABLE tb_workspace_audit_log (
  id           VARCHAR(36)  PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id VARCHAR(36)  NOT NULL,
  user_id      VARCHAR(36)  NOT NULL,
  action       VARCHAR(30)  NOT NULL,   -- 'left', 'ownership_transferred', etc.
  meta         JSONB,
  created_at   TIMESTAMPTZ  DEFAULT now()
);
```

---

## 3. Redis Key Design

> ทุก key มี TTL เพื่อ auto-cleanup

| Key Pattern | Type | TTL | ใช้กับ |
|---|---|---|---|
| `vo:presence:{wsId}:{userId}` | Hash | 30s (heartbeat renew) | online status, tile position |
| `vo:room:{wsId}:{userId}` | String | 30s | current room_id ของ user |
| `vo:knock_cd:{wsId}:{zoneId}:{userId}` | String | 30s / 5min | knock cooldown |
| `vo:knock_deny_count:{wsId}:{zoneId}:{userId}` | String | 10min | deny counter |
| `vo:follow:{wsId}:{followerId}` | String | session | follow target_id |
| `vo:wave_cd:{wsId}:{senderId}:{targetId}` | String | 10s | wave cooldown |
| `vo:zone_granted:{wsId}:{zoneId}:{userId}` | String | 30s | barrier open window |

### Presence Hash Fields

```
vo:presence:{wsId}:{userId} → {
  status:       "available" | "busy" | "away" | "dnd"
  custom_msg:   string (max 30 chars)
  tile_x:       int
  tile_y:       int
  display_name: string
  avatar_url:   string
}
```

---

## 4. WebSocket Protocol Extensions

> ไฟล์: `zyra-ws/internal/hub/message.go`

### 4.1 Message Types เพิ่มเติม (Server → Client)

```go
// ── New outbound types ─────────────────────────────────────────
const (
    MsgStatusChanged   = "status_changed"    // user เปลี่ยน availability status
    MsgRoomEntered     = "room_entered"      // user เดินเข้าห้อง
    MsgRoomExited      = "room_exited"       // user เดินออกห้อง
    MsgWaveReceived    = "wave_received"     // notification ถึงผู้ถูก wave
    MsgFollowStarted   = "follow_started"    // notification ถึง target ว่ามีคน follow
    MsgFollowEnded     = "follow_ended"      // follow mode ยกเลิก
    MsgKnockRequest    = "knock_request"     // owner ในห้องรับ knock notification
    MsgKnockGranted    = "knock_granted"     // barrier เปิด — ส่งให้ผู้ขอ
    MsgKnockDenied     = "knock_denied"      // ถูก deny — ส่งให้ผู้ขอ
    MsgCapacityReached = "capacity_reached"  // office เต็ม — ปิด connection
)
```

### 4.2 Message Types เพิ่มเติม (Client → Server)

```go
const (
    ClientMsgStatus    = "status"        // เปลี่ยน availability status
    ClientMsgRoomEnter = "room_enter"    // แจ้ง server เมื่อเดินเข้าห้อง
    ClientMsgRoomExit  = "room_exit"     // แจ้ง server เมื่อเดินออก
    ClientMsgWave      = "wave"          // wave ไปหา target
    ClientMsgFollow    = "follow"        // start/stop follow
    ClientMsgKnock     = "knock"         // knock private zone
    ClientMsgKnockDecision = "knock_decision" // allow / deny (owner)
    ClientMsgHeartbeat = "heartbeat"     // renew Redis TTL
)
```

### 4.3 Payload Types

```go
// Inbound
type ClientStatusPayload struct {
    Status    string `json:"status"`     // available | busy | away | dnd
    CustomMsg string `json:"custom_msg"` // max 30 chars
}

type ClientRoomPayload struct {
    RoomID string `json:"room_id"`
}

type ClientWavePayload struct {
    TargetUserID string `json:"target_user_id"`
}

type ClientFollowPayload struct {
    TargetUserID string `json:"target_user_id"` // empty = unfollow
}

type ClientKnockPayload struct {
    ZoneID string `json:"zone_id"`
}

type ClientKnockDecisionPayload struct {
    ZoneID    string `json:"zone_id"`
    RequestID string `json:"request_id"`
    Allow     bool   `json:"allow"`
}

// Outbound
type StatusChangedPayload struct {
    UserID    string `json:"user_id"`
    Status    string `json:"status"`
    CustomMsg string `json:"custom_msg,omitempty"`
}

type RoomPayload struct {
    UserID string `json:"user_id"`
    RoomID string `json:"room_id"`
}

type WaveReceivedPayload struct {
    SenderUserID   string `json:"sender_user_id"`
    SenderName     string `json:"sender_name"`
    SenderAvatarURL string `json:"sender_avatar_url"`
}

type KnockRequestPayload struct {
    RequestID      string `json:"request_id"`
    ZoneID         string `json:"zone_id"`
    ZoneName       string `json:"zone_name"`
    RequesterID    string `json:"requester_id"`
    RequesterName  string `json:"requester_name"`
    RequesterAvatar string `json:"requester_avatar"`
}

type KnockResultPayload struct {
    ZoneID    string `json:"zone_id"`
    ZoneName  string `json:"zone_name"`
    Granted   bool   `json:"granted"`
    WindowSec int    `json:"window_sec,omitempty"` // 30 ถ้า granted
}

type FollowNotificationPayload struct {
    FollowerID    string `json:"follower_id"`
    FollowerName  string `json:"follower_name"`
    Following     bool   `json:"following"` // true=started, false=ended
}
```

### 4.4 Player Struct เพิ่ม Fields

```go
type Player struct {
    UserID      string `json:"user_id"`
    DisplayName string `json:"display_name"`
    AvatarURL   string `json:"avatar_url"`
    TileX       int    `json:"tile_x"`
    TileY       int    `json:"tile_y"`
    // New fields
    Status      string `json:"status"`      // availability status
    CustomMsg   string `json:"custom_msg,omitempty"`
    RoomID      string `json:"room_id,omitempty"`
    Direction   string `json:"direction"`   // up|down|left|right|idle
}
```

---

## 5. REST API Endpoints (zyra-api)

### 5.1 Endpoints ใหม่ที่ต้องเพิ่ม

#### Workspace Invite (SC-SB-10/11)

```
POST   /api/admin/workspaces/:id/invites          invite member(s)
GET    /api/admin/workspaces/:id/invites          list pending invites
DELETE /api/admin/workspaces/:id/invites/:invId   cancel invite
POST   /api/admin/workspaces/:id/invites/:invId/resend   resend invite

GET    /api/invite/:token                         get invite info (public)
POST   /api/invite/:token/accept                  accept invite (authed user)
```

#### Leave / Transfer Ownership (SC-PROFILE-06/07)

```
DELETE /api/user/workspaces/:id/membership        leave workspace (member/admin)
POST   /api/admin/workspaces/:id/transfer         transfer ownership to admin
```

#### Presence (last position save)

```
POST   /api/user/workspaces/:id/presence          save last_position on leave
```

### 5.2 Request / Response Shape

**POST `/api/admin/workspaces/:id/invites`**
```json
Request:  { "emails": ["a@x.com", "b@x.com"], "role": "member" }
Response: { "invited": 2, "skipped": 0, "errors": [] }
```

**GET `/api/invite/:token`**
```json
Response: {
  "workspace_name": "Starlight",
  "inviter_name": "Conan Grey",
  "role": "member",
  "expires_at": "2026-06-24T00:00:00Z"
}
```

**DELETE `/api/user/workspaces/:id/membership`**
```json
Request:  { "confirm_name": "Starlight" }  // case-sensitive
Response: { "status": "left" }
```

**POST `/api/admin/workspaces/:id/transfer`**
```json
Request:  { "new_owner_user_id": "uuid-of-admin" }
Response: { "status": "transferred", "new_owner_id": "...", "your_new_role": "admin" }
```

### 5.3 Standard Error Response Envelope

ทุก endpoint ใช้ `model.APIResponse` เสมอ — ห้าม return raw error string

```json
{
  "status":  400,
  "message": "validation failed: emails must not be empty"
}
```

| HTTP Status | ใช้เมื่อ |
|---|---|
| `400 Bad Request` | validation fail, missing field, bad format |
| `401 Unauthorized` | token ขาด / expired |
| `403 Forbidden` | มี token แต่ไม่มีสิทธิ์ (wrong role / not member) |
| `404 Not Found` | resource ไม่มีใน DB |
| `409 Conflict` | duplicate entry (member already invited) |
| `422 Unprocessable` | business rule fail (name mismatch, owner cannot leave) |
| `500 Internal` | unexpected DB/service error — ห้าม leak details |

---

### 5.4 API Validation Rules (per endpoint)

#### POST `/api/admin/workspaces/:id/invites`

| Field | Rule | Error |
|---|---|---|
| `emails` | required, array, len 1–10 | 400 `emails must have 1–10 items` |
| `emails[]` | valid email format (RFC 5322) | 400 `invalid email: <email>` |
| `emails[]` | not already active member | 409 `<email> is already a member` |
| `emails[]` | not already pending invite | 409 `<email> already has a pending invite` |
| `role` | required, enum: `member` \| `admin` | 400 `role must be member or admin` |
| `:id` | workspace exists | 404 `workspace not found` |
| caller | must be owner or admin of workspace | 403 `insufficient permissions` |

#### GET `/api/admin/workspaces/:id/invites`

| Check | Rule | Error |
|---|---|---|
| `:id` | workspace exists | 404 |
| caller | must be admin/owner | 403 |

#### DELETE `/api/admin/workspaces/:id/invites/:invId`

| Check | Rule | Error |
|---|---|---|
| `:invId` | invite exists + belongs to workspace | 404 `invite not found` |
| invite status | must be `pending` (not accepted/expired) | 422 `invite already accepted or expired` |
| caller | must be admin/owner | 403 |

#### POST `/api/admin/workspaces/:id/invites/:invId/resend`

| Check | Rule | Error |
|---|---|---|
| `:invId` | invite exists + pending | 404 / 422 |
| rate limit | max 3 resends per invite | 429 `too many resend attempts` |
| caller | must be admin/owner | 403 |

#### GET `/api/invite/:token`

| Check | Rule | Error |
|---|---|---|
| `token` | exists in DB | 404 `invitation not found` |
| invite | not expired (`expires_at > now()`) | 422 `invitation expired` |
| invite | not already accepted | 422 `invitation already used` |

_Note: public endpoint — no auth required_

#### POST `/api/invite/:token/accept`

| Check | Rule | Error |
|---|---|---|
| `token` | valid, not expired, not accepted | 404 / 422 |
| caller | authenticated user (JWT required) | 401 |
| caller | email matches invite email | 403 `this invitation was sent to a different email` |
| membership | user not already a member | 409 `already a member of this workspace` |
| capacity | workspace not full | 422 `workspace is at capacity` |

#### DELETE `/api/user/workspaces/:id/membership`

| Field | Rule | Error |
|---|---|---|
| `confirm_name` | required, non-empty string | 400 `confirm_name is required` |
| `confirm_name` | must exactly match workspace name (case-sensitive) | 422 `workspace name does not match` |
| caller | must be active member of workspace | 403 |
| caller role | owner → cannot leave without transferring ownership first | 422 `transfer ownership before leaving` |

#### POST `/api/admin/workspaces/:id/transfer`

| Field | Rule | Error |
|---|---|---|
| `new_owner_user_id` | required, valid UUID format | 400 |
| `new_owner_user_id` | must be active member of workspace | 422 `target user is not a member` |
| `new_owner_user_id` | role must be `admin` | 422 `target user must be an admin` |
| `new_owner_user_id` | cannot be same as caller | 422 `cannot transfer to yourself` |
| caller | must be current owner | 403 `only the owner can transfer ownership` |

#### POST `/api/user/workspaces/:id/presence`

| Field | Rule | Error |
|---|---|---|
| `tile_x` | required, integer ≥ 0 | 400 |
| `tile_y` | required, integer ≥ 0 | 400 |
| `map_id` | required, valid UUID | 400 |
| caller | must be active member | 403 |

---

### 5.5 WebSocket Message Validation

zyra-ws validate ทุก inbound message ก่อน process:

```go
// pattern ที่ใช้กับทุก handler
func (r *Room) handleClientMessage(c *Client, env Envelope) {
    switch env.Type {
    case ClientMsgStatus:
        var p ClientStatusPayload
        if err := json.Unmarshal(env.Payload, &p); err != nil {
            r.sendError(c, "invalid payload")
            return
        }
        if !isValidStatus(p.Status) {
            r.sendError(c, "status must be available|busy|away|dnd")
            return
        }
        if len(p.CustomMsg) > 30 {
            r.sendError(c, "custom_msg exceeds 30 characters")
            return
        }
        // ...

    case ClientMsgWave:
        var p ClientWavePayload
        if err := json.Unmarshal(env.Payload, &p); err != nil {
            r.sendError(c, "invalid payload")
            return
        }
        if p.TargetUserID == "" || p.TargetUserID == c.UserID {
            r.sendError(c, "invalid target_user_id")
            return
        }
        if _, ok := r.getClient(p.TargetUserID); !ok {
            r.sendError(c, "target not in office")
            return
        }
        // ...
    }
}
```

| Message | Validation | Error sent back |
|---|---|---|
| `move` | tile_x/y: int, dx/dy ≤ 3, not collision tile | `error: invalid move` |
| `status` | status ∈ {available,busy,away,dnd}; custom_msg ≤ 30 chars | `error: invalid status` |
| `wave` | target_user_id: non-empty, not self, target in room | `error: invalid target` |
| `knock` | zone_id: non-empty, zone exists in map, not in cooldown | `error: knock cooldown` |
| `knock_decision` | request_id: exists, zone_id matches, caller is zone owner | `error: unauthorized decision` |
| `follow` | target_user_id: non-empty OR empty (unfollow), not self | `error: invalid target` |
| `room_enter` | room_id: non-empty, zone type = room | `error: invalid room` |

---

## 6. Frontend Architecture (zyra-app)

### 6.1 Route Structure

```
/workspace                    → SC-VO-01  List Workspace
/workspace/[id]               → SC-VO-02  Loading Page → Game
/workspace/[id]/play          → SC-VO-03–14  Virtual Office (game canvas)
/invite/[token]               → SC-SB-11  Accept Invitation page
/profile                      → SC-PROFILE-06/07  (existing, add workspace tab)
```

### 6.2 Zustand Store

**`stores/virtual-office.store.ts`**
```ts
interface VirtualOfficeState {
  // Connection
  wsStatus: "disconnected" | "connecting" | "connected"

  // Players
  players: Record<string, Player>   // userId → Player
  myUserId: string

  // My state
  myTile: { x: number; y: number }
  myDirection: Direction
  myRoomId: string | null
  myStatus: AvailabilityStatus
  myCustomMsg: string

  // Follow mode
  followTargetId: string | null

  // Knock state
  knockedZoneId: string | null
  knockCooldownUntil: number | null  // timestamp ms

  // UI
  memberPanelOpen: boolean
  loadingPhase: "connecting" | "map" | "members" | "done"
  loadingProgress: number   // 0–100

  // Actions
  setStatus(status: AvailabilityStatus, msg?: string): void
  wave(targetUserId: string): void
  startFollow(targetUserId: string): void
  stopFollow(): void
  knock(zoneId: string): void
  decideKnock(requestId: string, zoneId: string, allow: boolean): void
}
```

### 6.3 WebSocket Client Hook

**`hooks/use-virtual-office-ws.ts`**
```ts
function useVirtualOfficeWS(workspaceId: string) {
  // connect on mount, reconnect on drop
  // dispatch to store on every message type
  // expose: send(type, payload) helper
}
```

Message → Store mapping:

| WS Message | Store Action |
|---|---|
| `welcome` | set players, myTile, loadingPhase = done |
| `joined` | add player |
| `left` | remove player |
| `moved` | update player tile + direction |
| `status_changed` | update player status |
| `room_entered/exited` | update player roomId |
| `wave_received` | show toast notification |
| `knock_request` | show knock notification toast |
| `knock_granted` | open barrier, show prompt |
| `knock_denied` | show denied toast, set cooldown |
| `follow_started` | show "X is following you" toast |
| `capacity_reached` | redirect to list + error modal |

### 6.4 Game Engine (Phaser Scene)

**`components/game-canvas/scenes/VirtualOfficeScene.ts`**

```
VirtualOfficeScene
├── Layers (Tiled)
│   ├── floor       (walkable tiles)
│   ├── walls       (static collision)
│   ├── objects     (furniture, non-walkable)
│   ├── zones       (room + private zone detection)
│   └── decoration  (top layer, non-collision)
│
├── Systems
│   ├── CollisionSystem     — loads boolean grid from Tiled, check before move
│   ├── PathfindingSystem   — A* on collision grid (click-to-move, follow mode)
│   ├── ZoneDetectionSystem — overlap test on zones layer each move
│   ├── CameraSystem        — smooth follow + pan-to-player
│   └── InterpolationSystem — lerp remote player positions (50ms ticks → smooth)
│
├── Objects
│   ├── LocalPlayer         — WASD + click input, throttle WS send 50ms
│   └── RemotePlayer        — interpolated by InterpolationSystem
│
└── HUD (React overlay, NOT Phaser)
    ├── MemberPanel
    ├── StatusPicker
    ├── WaveToast
    ├── KnockToast
    ├── FollowBar
    └── Minimap
```

### 6.5 Component Tree (HUD)

```
<VirtualOfficePage>
  ├── <LoadingOverlay>            phase + progress bar
  ├── <GameCanvas>                Phaser scene
  └── <HUDLayer>                  React overlay (pointer-events: none except interactive)
        ├── <Sidebar>             72px left icons
        ├── <MemberPanel>         collapsible right panel
        ├── <StatusPicker>        bottom-left popover
        ├── <Minimap>             bottom-right
        ├── <BottomToolbar>       cam/mic/wave buttons
        ├── <RoomDisplayPanel>    top bar when inside room
        ├── <WaveNotification>    top-right toast (wave received)
        ├── <KnockNotification>   top-right toast (knock request for owner)
        ├── <KnockOverlay>        overlay on private zone (requester side)
        └── <FollowBar>           bottom center bar
```

---

## 7. Loading Sequence (SC-VO-02)

```
1. GET /api/user/workspaces/:id          → check capacity
   ├─ if full → show "Office เต็มแล้ว" modal → stop
   └─ ok → continue

2. WS connect wss://ws.zyra.app/:wsId    phase: "connecting" (0–30%)

3. Receive `welcome` message              phase: "map" (30–70%)
   └─ start loading Tiled map JSON + assets from CDN

4. Map + sprites loaded                   phase: "members" (70–100%)
   └─ interpolate remote players into scene

5. loadingPhase = "done"
   └─ fade-in animation, show HUD
```

Timeout: ถ้าไม่ได้ `welcome` ใน 10s → show retry button

---

## 8. Collision & Zone Detection

### Collision Grid

```ts
// โหลดจาก Tiled JSON collision layer
const collisionGrid: boolean[][] = loadCollisionLayer(tiledMap)

// ก่อน move ทุกครั้ง
function canMoveTo(tileX: number, tileY: number): boolean {
  return !collisionGrid[tileY]?.[tileX]
}
```

### Zone Detection (per move tick)

```ts
interface Zone {
  id: string
  name: string
  type: "room" | "private"
  bounds: Phaser.Geom.Rectangle | Phaser.Geom.Polygon
}

function detectZone(tileX: number, tileY: number, zones: Zone[]): Zone | null {
  return zones.find(z => z.bounds.contains(tileX * TILE_SIZE, tileY * TILE_SIZE)) ?? null
}
```

Private Zone = invisible collision wall + overlay card เมื่อเข้าใกล้ (<3 tiles)

---

## 9. Anti-Cheat: Server Position Validation

> `zyra-ws/internal/hub/room.go` — `handleMove()`

```go
// ตรวจก่อน broadcast
func validateMove(from, to TilePosition, collisionGrid [][]bool) bool {
    if collisionGrid[to.Y][to.X] {
        return false // collision tile
    }
    dx := abs(to.X - from.X)
    dy := abs(to.Y - from.Y)
    if dx > 3 || dy > 3 {
        return false // teleport detection
    }
    return true
}
```

---

## 10. Capacity Check

```go
// zyra-ws/internal/hub/room.go — Join()
func (r *Room) checkCapacity(workspaceCapacity int) error {
    if r.count() >= workspaceCapacity {
        return ErrCapacityReached
    }
    return nil
}
// ถ้าเต็ม → ส่ง capacity_reached message แล้ว close connection
```

---

## 11. Private Zone Knock Flow

```
Client (requester)                    Server (zyra-ws)              Client (owner in zone)
     │                                      │                              │
     │── knock { zone_id } ───────────────► │                              │
     │                                      │ validate cooldown (Redis)    │
     │                                      │ generate request_id          │
     │                                      │── knock_request ────────────►│
     │◄── knock_request ACK ────────────────│                              │
     │                                      │                              │
     │  (waiting...)                        │◄── knock_decision {allow} ───│
     │                                      │                              │
     │◄── knock_granted { window: 30s } ────│                              │
     │    set Redis: zone_granted TTL 30s   │                              │
     │                                      │                              │
     │── move into zone ──────────────────► │                              │
     │   server validates zone_granted key  │                              │
```

---

## 12. Follow Mode Flow

```
Every 200ms while following:
  client calculates path to (targetTile.x ± 1, targetTile.y ± 1)
  if pathExists → send move commands along path
  if target left office → dispatch follow_ended → clear followTargetId
```

Follow state: ephemeral in client store + Redis `vo:follow:{wsId}:{followerId}`  
Server ไม่ต้อง validate follow path (ใช้ collision validation เหมือนปกติ)

---

## 13. Invite Token Flow (SC-SB-11)

```
Register page
  ├── queryParam: ?invite_token=xxx
  ├── store token in sessionStorage
  └── after OTP verify success:
        POST /api/invite/:token/accept
          ├── create workspace_member record
          ├── mark invitation accepted
          └── redirect to /workspace/:id
```
