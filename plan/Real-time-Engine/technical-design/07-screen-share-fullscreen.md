# Technical Design — 07 · Screen Share — Full Screen (SC-RTE-07)

> [Spec](../spec.md#sc-rte-07--screen-sharing--full-screen) · ClickUp [86d2weuup](https://app.clickup.com/t/86d2weuup) · **ใหม่** (SFU + `ws:share:*`) — เป็น base ของ 08, 09
> อ่าน [00-architecture-overview](00-architecture-overview.md) §4 — SFU = **LiveKit** (`zyra-sfu`) ✅ พร้อมแล้ว

## Goal
Full-screen share ผ่าน browser native picker, single-presenter guard, featured layout, screen track แยกจาก camera, stop 2 ทาง (HUD + browser), cleanup เมื่อ presenter leave/disconnect

## Affected
- `zyra-app` (getDisplayMedia, publish screen track, HUD indicator, featured layout) · `zyra-ws` (share state + presenter guard) · **SFU** (screen track forward)

## Architecture (control plane guard, media plane forward)
```
Share: HUD/shortcut S → navigator.mediaDevices.getDisplayMedia({video,audio})
   → ws:share:start {room_id} → zyra-ws validate: !has_active_share
       ok → has_active_share=true, presenter=user → ws:share:started (broadcast)
       fail → ws:share:denied {reason: active_share_exists, presenter_name}
   → client publish screen track เข้า LiveKit (`setScreenShareEnabled(true)`, source=ScreenShare แยกจาก camera)
   → LiveKit forward ให้ทุก member → featured layout switch (ดู 09)
Stop: HUD button หรือ browser native "Stop sharing" (track.onended)
   → ws:share:stop → has_active_share=false → ws:share:stopped → layout กลับ grid < 1s
```

## WS Events
| Event | ทิศทาง | Payload |
|-------|--------|---------|
| `ws:share:start` | C→S | `{room_id}` |
| `ws:share:started` | S→C | `{room_id, presenter_id, presenter_name}` |
| `ws:share:denied` | S→C | `{room_id, reason, presenter_name}` |
| `ws:share:stop` | C→S | `{room_id}` |
| `ws:share:stopped` | S→C | `{room_id, presenter_id, reason}` reason: `user_stopped\|presenter_left\|disconnect` |

## Key Logic
- **Single-presenter guard** (task นี้): 1 คน/ห้อง — คนที่สอง → `ws:share:denied` แสดง "[ชื่อ] กำลัง share อยู่ กรุณารอ". (SC-RTE-09 ขยายเป็น max 2)
- **Track แยก:** screen track publish เป็น source แยก → presenter เปิด camera ได้พร้อมกัน
- **Stop 2 ทาง:** HUD button + `screenTrack.onended` (browser native stop) → เรียก path เดียวกัน
- **Cleanup:** presenter leave room / tab close / WS disconnect → server force `ws:share:stopped` + `has_active_share=false` + system message
- **Resolution/fps target:** 1920×1080 @ 15fps → ใส่ constraints ตอน getDisplayMedia + track settings
- **Permission denied:** getDisplayMedia reject → error toast + วิธีเปิด permission

## Server-side (guard, idempotent)
```go
func (r *Room) startShare(userID string) error {
    r.mu.Lock(); defer r.mu.Unlock()
    if r.media.HasActiveShare {
        return ErrActiveShareExists // → ws:share:denied
    }
    r.media.HasActiveShare = true
    r.media.Presenters = []string{userID}
    r.broadcast(MsgShareStarted, ShareStartedPayload{PresenterID: userID})
    return nil
}
```

## DoD
- 1 คน/ห้อง (คนสองได้ข้อความรอ); featured layout ทุกคน; 1920×1080@15fps; HUD indicator; stop 2 ทาง; layout กลับ < 1s; presenter leave/close → auto stop+system msg; track แยกจาก camera; permission denied → toast
- Unit ≥80% (guard, stop sources, track-separate) · Integration ≥70% (start/stop, disconnect cleanup) · E2E ⚠️ fake-device ≥50%

## Risks / Open
- ✅ SFU = LiveKit — screen track = `Track.Source.ScreenShare` (แยกจาก camera โดย native)
- getDisplayMedia audio (system/tab audio) รองรับต่าง browser — test cross-browser
- browser native stop button detect ผ่าน `track.onended` — LiveKit ยิง `LocalTrackUnpublished` ต้อง map เข้า `ws:share:stop`
