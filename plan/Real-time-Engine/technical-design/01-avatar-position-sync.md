# Technical Design — 01 · Avatar Position Sync (SC-RTE-01)

> [Spec](../spec.md#sc-rte-01--avatar-position-sync--ทุก-module) · ClickUp [86d2wetb9](https://app.clickup.com/t/86d2wetb9)
> **สถานะ:** สร้างแล้ว ~90% ใน `zyra-ws` — ดู [gap-audit-sc-rte-01.md](../gap-audit-sc-rte-01.md)
> เอกสารนี้สะท้อน **โค้ดจริง** (แก้จากฉบับร่างเดิมที่อิง spec)

## Goal
Presence + position ของ avatar sync real-time (Map + Member Panel + DM), latency < 100ms, รองรับ CCU สูงต่อ workspace, **1 WS ต่อ user (evict model)**

## Affected
`zyra-ws` (hub) · `zyra-app` (client) · `zyra-api` (status persist — มีแล้ว)

## Architecture (โค้ดจริง)
| ส่วน | สถานะ | หลักฐาน |
|------|-------|---------|
| WS connect + `welcome` snapshot | ✅ ทำแล้ว | `hub.go`, `room.go:134` |
| 1 WS/user — **evict model** | ✅ ทำแล้ว | `room.go:161–183` — tab ใหม่เตะเก่า, `session_replaced`; same-tab (`ClientSessionID`) swap เงียบ |
| Position — **path-based** (`move_to`/`stop`) | ✅ ทำแล้ว | `room.go:576` + `MovingPayload.ServerTimeMs:693` |
| Move ticker 20ms + latest-wins coalescing | ✅ ทำแล้ว | `room.go:836` `runMoveTicker` |
| AOI fan-out 3×3 (16×16 cell) + binary frame | ✅ ทำแล้ว | `aoi.go`, `client.SendBin` |
| Snapshot resync (still-player) | ✅ ทำแล้ว | `sendNeighborSnapshot:519` + snapshot ticker 3s `:860` |
| Status broadcast + DB persist | ✅ ทำแล้ว | `handleStatus:935` + REST `PATCH /me/status` → `tb_user.availability_status` |
| Status → Map + Member Panel | ✅ ทำแล้ว | `hero:1243`, `vo-member-panel.tsx:415` |
| Heartbeat / silent disconnect | ✅ ทำแล้ว | WS ping 45s/pong 60s `client.go:16`; `handleHeartbeat:1701` (Redis TTL) |
| Offline cleanup ≤5s | ✅ ทำแล้ว | `unregister`→`MsgLeft` `room.go:332` |
| **Status → DM (presence dot)** | ❌ **gap — กำลังทำ** | DM อยู่คนละ context จาก workspace room |
| Latency < 100ms / CCU สูง ไม่ lag | ⚠️ **ยังไม่ verify** | ต้อง load test |

## Decisions (เคาะแล้ว)
- **Multi-tab = evict model** (คงของเดิม) — ไม่รองรับหลาย tab พร้อมกัน, ไม่มี status-priority merge. tab ใหม่แทน tab เก่าผ่าน `session_replaced`
- **Position ไม่ใช่ throttle 50ms** — ใช้ path-based (`move_to`/`stop`) + server ticker 20ms + AOI (ดีกว่า, มีอยู่แล้ว). spec เดิมที่เขียน "50ms throttle" ตกยุค → แก้ spec แล้ว

## WS Events (โค้ดจริง)
| Event | ทิศทาง | หมายเหตุ |
|-------|--------|---------|
| `move` / `move_to` / `stop` | C→S | path-based เป็นหลัก |
| `moved` (binary) / `moving` / `stopped` | S→C | 20ms ticker, latest-wins |
| `status` → `status_changed` | C→S / S→C | broadcast ในห้อง (workspace-scoped) |
| `heartbeat` / `ping` → `pong` | C→S / S→C | Redis TTL + clock sync |
| `welcome` / `joined` / `left` | S→C | presence lifecycle |

## งานที่เหลือ (ไม่ใช่ build position sync — มีแล้ว)
1. **DM presence** — ดู sub-design แยก (status ต้องข้าม workspace ไปถึง DM) → [ดูงาน implement]
2. **Load test** — verify latency < 100ms + CCU สูงไม่ lag (criterion ที่ยังไม่ยืนยัน)

## DoD
- ✅ position/status/presence/offline/heartbeat/interpolation — ครบ
- ⏳ DM presence dot
- ⏳ load test ผ่าน (latency < 100ms)

## Risks / Open
- AOI fan-out ที่ CCU สูง (โดยเฉพาะ map 1000 คน — ดู [capacity-scaling.md](../capacity-scaling.md)) — ต้อง load test
- DM presence = cross-workspace presence (งานเพิ่มจริง ไม่ใช่ wiring) — ดู design ด้านล่าง
