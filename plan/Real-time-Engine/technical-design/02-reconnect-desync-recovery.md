# Technical Design — 02 · Reconnect / Desync Recovery (SC-RTE-02)

> [Spec](../spec.md#sc-rte-02--avatar-sync--reconnect--desync-recovery) · ClickUp [86d2weth9](https://app.clickup.com/t/86d2weth9) · **ต่อยอด** client backoff (มีแล้ว) + server grace period (ใหม่)
> อ่าน [00-architecture-overview](00-architecture-overview.md) ก่อน

## Goal
WS หลุด → auto reconnect (backoff, non-blocking HUD) → full state resync. Grace period 2 นาที: rejoin room/session เดิม, mute/camera คงเดิม, queued messages flush ตามลำดับ

## Affected
- `zyra-app` (client — มี backoff แล้ว, เพิ่ม queue + indicator + snapshot request) · `zyra-ws` (grace period session store — ใหม่)

## Architecture
| ส่วน | สถานะ |
|------|-------|
| Exponential backoff + jitter | ✅ มีแล้ว (`workspace-ws.ts:136`) แต่ spec ขอ 1→2→4→8→16→30 max 5 → **ปรับ cap/จำนวนให้ตรง** |
| Liveness watchdog 30s | ✅ มีแล้ว |
| Reconnect on wake/focus/online | ✅ มีแล้ว |
| Tab session ID (`client_session_id`) | ✅ มีแล้ว (sessionStorage) |
| `force_sync` / `session_replaced` / `server_drain` | ✅ มีแล้ว |
| **Grace period 2 นาที server-side** | ⚠️ ใหม่ — เก็บ position/room_id/mute/camera |
| **Reconnecting indicator (HUD, non-blocking)** | ⚠️ ใหม่ (UI) |
| **Client message queue (max 10, drop oldest)** | ⚠️ ใหม่ |
| **Full snapshot request หลัง reconnect** | ⚠️ ใช้ `welcome`/`force_sync` |

## Flow
```
WS onclose/onerror → HUD indicator (ไม่บล็อก game loop)
  → backoff retry 1/2/4/8/16/30s (max 5)
  → พิมพ์ข้อความ = enqueue (memory, cap 10, drop oldest)
reconnect open → ส่ง ws:presence:connect { ws_token, client_session_id }
  server เช็ค grace (≤2 นาที) & ws_token (≤24h):
     ผ่าน → rejoin room+session เดิม → ส่ง full snapshot (positions/rooms/presence)
     เกิน grace → clear session → client แสดง modal + redirect
  → flush queued messages (FIFO) → indicator หาย
retry 5 ครั้ง fail → error banner + ["ลองใหม่"] ["ออกจาก Office"]
```

## WS Events
| Event | ทิศทาง | Payload |
|-------|--------|---------|
| `ws:presence:connect` | C→S | `{ws_token, client_session_id}` |
| `welcome` / `force_sync` | S→C | full snapshot (มีแล้ว) |
| `session_replaced` | S→C | ✅ มีแล้ว (multi-tab) |
| `session_expired` | S→C | ⚠️ ใหม่ — เกิน grace, redirect |

## Server-side (grace session)
```go
type GraceSession struct {
    UserID   string
    RoomID   string
    TileX, TileY int
    Muted, CameraOn bool
    ExpiresAt int64 // now + 2min
}
// เก็บใน Redis (TTL 120s) เพื่อ survive ข้าม instance
```
- **Snapshot merge:** server state ชนะเสมอ (source of truth) — pattern เดียวกับ chat-space
- **SFU reconnect:** ทำ parallel กับ WS (ไม่รอกัน) — LiveKit client auto-reconnect แยก
- **Multi-tab:** ถ้า tab อื่น reconnect ก่อน → ใช้ session นั้น (มี `session_replaced` แล้ว)
- **Heartbeat resume:** หลัง reconnect เริ่ม ping 30s ทันที

## Client-side (queue)
```ts
private queue: OutboundMessage[] = []
private enqueue(m: OutboundMessage) {
  if (this.queue.length >= 10) this.queue.shift() // drop oldest
  this.queue.push(m)
}
private flushQueue() {
  for (const m of this.queue) this._send(m.type, m.payload)
  this.queue = []
}
```

## DoD
- indicator แสดงทันที non-blocking; rejoin ภายใน 2 นาทีไม่ผ่าน loading; mute/camera คงเดิม; queue flush ตามลำดับ; retry 5 fail → banner; เกิน grace → modal+redirect
- Unit ≥80% (backoff seq, queue cap, snapshot merge) · Integration ≥70% (rejoin, grace boundary) · E2E ≥50% (kill/restore network)

## Risks / Open
- ต้อง reconcile backoff เดิม (cap 20s) กับ spec (30s, max 5) — ยืนยัน number กับ PM
- Grace session ต้องอยู่ Redis เพื่อ survive server restart
