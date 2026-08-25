# Technical Design — 03 · Room State Management (SC-RTE-03)

> [Spec](../spec.md#sc-rte-03--room-state-management) · ClickUp [86d2wetw6](https://app.clickup.com/t/86d2wetw6) · **ต่อยอด** room + เพิ่ม media state
> อ่าน [00-architecture-overview](00-architecture-overview.md) ก่อน

## Goal
Room state (members, active-share, member count, lock) sync real-time ทุก member + minimap. **State ผ่าน WS events เท่านั้น ไม่ใช่ REST**

> ⚠️ **Scope note:** Admin lock ห้อง / `is_locked` **ถูกขีดฆ่าใน spec** → reserve field แต่ **ไม่ implement flow lock** ใน task นี้

## Affected
- `zyra-ws` (หลัก — เพิ่ม `MediaRoomState`) · `zyra-app` (render room label + minimap)

## Architecture
| ส่วน | สถานะ |
|------|-------|
| Room enter/exit + `members[]` broadcast | ✅ มีแล้ว (`room.go`) |
| **`has_active_share` toggle + indicator** | ⚠️ เพิ่ม (ผูกกับ SC-RTE-07) |
| **Member count บน room label real-time** | ⚠️ เพิ่ม (derive จาก members) |
| **Reset room state เมื่อว่าง** | ⚠️ เพิ่ม |
| Lock icon / `is_locked` | ⛔ reserve field เท่านั้น (ขีดฆ่า) |

## Room State (single source of truth = zyra-ws)
```go
// ต่อยอด Room เดิม ด้วย MediaRoomState (ดู 00-overview §6)
type RoomState struct {
    RoomID          string   `json:"room_id"`
    Members         []string `json:"members"`      // user_id
    MemberCount     int      `json:"member_count"`
    HasActiveShare  bool     `json:"has_active_share"`
    AudioActiveCount int     `json:"audio_active_count"`
    IsLocked        bool     `json:"is_locked"`    // reserve — ขีดฆ่า, default false
}
```

## WS Events
| Event | ทิศทาง | Payload |
|-------|--------|---------|
| `ws:room:enter` / `room_enter` | C→S | `{room_id}` ✅ มี |
| `ws:room:leave` / `room_exit` | C→S | `{room_id}` ✅ มี |
| `ws:room:stateUpdate` | S→C | `RoomState` (ใหม่ — รวม share/count) |

## Key Logic
- ทุกการเปลี่ยน state → build `RoomState` → `room.broadcast(ws:room:stateUpdate)` ให้ทุก member + push minimap channel
- `has_active_share` = true เมื่อ SC-RTE-07 เริ่ม share, false เมื่อ stop/presenter-left
- คนสุดท้ายออก → reset ทุก field เป็น default (idempotent)
- **ไม่มี REST mutation** สำหรับ state — assert ใน integration test

## DoD
- room state real-time ทุก member + minimap; share indicator + member count update; reset เมื่อว่าง; state ผ่าน WS เท่านั้น
- Unit ≥80% (add/remove member, toggle share, reset) · Integration ≥70% (broadcast, no-REST) · E2E ≥50% (member count/indicator ฝั่งที่สอง)

## Risks / Open
- concurrent enter/leave (race on `members[]`) → ต้อง lock/actor ต่อ room (มี pattern ใน chat-space)
- ยืนยันว่า lock feature ตัดถาวรหรือแค่เลื่อน (field ยัง reserve ไว้)
