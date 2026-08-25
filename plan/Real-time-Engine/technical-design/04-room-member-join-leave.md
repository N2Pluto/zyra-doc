# Technical Design — 04 · Room Member Join / Leave (SC-RTE-04)

> [Spec](../spec.md#sc-rte-04--room-state--member-join--leave) · ClickUp [86d2weu7t](https://app.clickup.com/t/86d2weu7t) · **ต่อยอด** room + sync กับ SFU media room
> อ่าน [00-architecture-overview](00-architecture-overview.md) ก่อน

## Goal
Avatar เดินเข้า/ออก room zone → join/leave ทั้ง **WS room state** และ **SFU media room** ให้ sync กัน. Validate lock/capacity, presenter ออก = force stop share

## Affected
- `zyra-ws` (room membership + validate) · `zyra-api` (mint SFU token ตอน join) · `zyra-app` (overlap detection, SFU connect)

## Architecture
| ส่วน | สถานะ |
|------|-------|
| Overlap detection (avatar ↔ zone) | ✅ มีบางส่วน (room_enter client-side) |
| Room enter/exit broadcast | ✅ มีแล้ว |
| **Capacity / lock validate ก่อน join** | ⚠️ เพิ่ม (lock = reserve, capacity = ใช้) |
| **SFU media room join/leave sync WS** | ⚠️ ใหม่ (ต้องมี SFU — ดู 00 §4) |
| **Audio auto-join ตาม preference** | ⚠️ ใหม่ |
| **Presenter ออก → force stop share** | ⚠️ ใหม่ (ผูก SC-RTE-07) |

## Flow
```
JOIN:  avatar overlap zone → ws:room:enter {room_id}
   server validate: !locked && count < capacity
   ok → members[] += user → ws:room:stateUpdate
      → zyra-api mint SFU token → client connect SFU media room
      → audio auto-connect ตาม user preference
   fail → ws:room:enterDenied {reason: locked|full} → lock/full indicator

LEAVE: avatar ออก zone → ws:room:leave {room_id}
   server: members[] -= user → ws:room:stateUpdate
   ถ้า user sharing → ws:share:stopped {reason: presenter_left} (force)
   client leave SFU media room
   คนสุดท้ายออก → reset room state (ดู 03)
```

## WS Events
| Event | ทิศทาง | Payload |
|-------|--------|---------|
| `ws:room:enter` | C→S | `{room_id}` |
| `ws:room:enterDenied` | S→C | `{room_id, reason}` (ใหม่) |
| `ws:room:leave` | C→S | `{room_id}` |
| `ws:room:stateUpdate` | S→C | `RoomState` (ดู 03) |
| `ws:share:stopped` | S→C | `{room_id, reason: presenter_left}` |

## API (zyra-api — LiveKit token)
```
POST /api/user/rooms/{room_id}/media-token
→ { token, url }   # LiveKit access token (identity=user_id, room={room_id}), url = NEXT_PUBLIC_LIVEKIT_URL
```
- Guard: UserGuard (member เรียกผ่าน `/api/user/*` เท่านั้น — ตาม rule 15)
- mint ด้วย `LIVEKIT_API_KEY/SECRET` (ตรงกับ `zyra-sfu`), grants `canPublish`/`canSubscribe`
- **SFU พร้อมแล้ว:** LiveKit v1.8 ที่ `zyra-sfu` :7880 (ดู [zyra-sfu/AGENTS.md](../../../../zyra-sfu/AGENTS.md))

## Key Logic
- **Sync WS ↔ SFU:** WS room เป็น source of truth ของ membership; SFU join/leave ตามหลัง WS event (ไม่ให้ media เข้าก่อน state)
- **Presenter-left:** server ตรวจตอน leave/disconnect ว่า user เป็น presenter → broadcast `ws:share:stopped` + อัปเดต `has_active_share`
- **Idempotent:** duplicate enter/leave ไม่เพิ่ม/ลบ member ซ้ำ
- **Cleanup on disconnect:** WS close (ไม่ส่ง leave) → server cleanup member + SFU participant

## DoD
- join ได้ room state ทันที; leave update ทุกคน; lock → deny+indicator; capacity เต็ม → deny; presenter ออก → share หยุด+แจ้ง; audio auto-join; คนสุดท้าย reset
- Unit ≥80% (validate, presenter-left, overlap) · Integration ≥70% (enter/leave + SFU sync) · E2E ≥50% (2 users join/leave)

## Risks / Open
- ✅ SFU = LiveKit (`zyra-sfu`) — resolved. เหลือ implement token endpoint + LiveKit room lifecycle
- LiveKit room auto-create ตอน participant แรก join / auto-clean `empty_timeout: 5m` — ต้องระวัง sync กับ WS room reset
- capacity มาจากไหน (map config / room definition) ต้องยืนยัน source (LiveKit `max_participants: 50`)
