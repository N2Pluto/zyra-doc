# Technical Design — 09 · Screen Share — Viewer View (SC-RTE-09)

> [Spec](../spec.md#sc-rte-09--screen-share--ผู้ชม-view) · ClickUp [86d2wev56](https://app.clickup.com/t/86d2wev56) · **ต่อยอด 07** + simulcast + max 2 presenters · Priority: Normal
> อ่าน [07-screen-share-fullscreen](07-screen-share-fullscreen.md) ก่อน

## Goal
ฝั่ง viewer: auto layout switch เมื่อเข้าห้องที่มี active share, subscribe screen stream อัตโนมัติ, presenter name overlay, zoom max 2x, simulcast ตาม bandwidth, **max 2 presenters พร้อมกัน (แบ่งครึ่งจอ)**

## Affected
- `zyra-app` (layout engine, subscribe, zoom, PiP) · `zyra-ws` (presenter count guard → ขยาย 07 จาก 1 เป็น 2) · **SFU** (auto-subscribe, simulcast)

## Architecture
```
Viewer เข้าห้อง active share → รับ ws:share:started (หรือ RoomState has_active_share)
   → auto layout switch: featured (share tile ใหญ่ + video tiles PiP ข้าง)
   → SFU auto-subscribe screen stream + audio (simulcast layer ตาม bandwidth)
Presenter stop → ws:share:stopped → layout กลับ default grid
2 presenters → split-screen (แบ่งครึ่งจอ, 2 featured tiles)
```

## ความต่าง/ขยายจาก 07
| ด้าน | 07 (presenter side) | 09 (viewer side) |
|------|---------------------|------------------|
| Presenter limit | 1 คน/ห้อง | **max 2 คน (แบ่งครึ่งจอ)** — ขยาย guard |
| Layout | featured 1 tile | featured 1 หรือ split 2 |
| Subscribe | publish | **auto-subscribe** |
| Quality | publish simulcast layers | **เลือก layer ตาม viewer bandwidth** |
| Zoom | — | **zoom in max 2x** |
| Overlay | — | presenter name มุมซ้ายบน |

## WS Events (ต่อยอด 07)
| Event | ทิศทาง | หมายเหตุ |
|-------|--------|---------|
| `ws:share:started` / `ws:share:stopped` | S→C | ✅ จาก 07 |
| `ws:share:start` guard | S | ขยาย: `len(presenters) < 2` (จาก 07 ที่ = 1) |

## Key Logic
- **Auto layout switch:** viewer ได้ `has_active_share` (จาก RoomState 03 หรือ `ws:share:started`) → สลับเป็น featured อัตโนมัติ; stop → กลับ grid
- **2-presenter guard:** ขยาย `startShare` ใน 07 ให้ยอมสูงสุด 2 → คนที่ 3 `ws:share:denied`
- **Split layout:** presenters == 2 → แบ่งครึ่งจอ (2 featured); == 1 → single featured
- **Simulcast:** LiveKit `enable_dynacast: true` (ตั้งไว้ใน `zyra-sfu/livekit.yaml`) + client `adaptiveStream` → เลือก layer ตาม downlink bandwidth อัตโนมัติ
- **Zoom:** viewer zoom share tile, clamp `scale ∈ [1, 2]`
- **PiP:** video tiles ของ member แสดงด้านข้าง
- **Latency target:** < 500ms presenter→viewer (วัดด้วย timestamp)
- **No leak:** viewer เข้า/ออกห้องรัว ๆ → subscribe/unsubscribe cleanup ไม่ leak stream

## Server-side (ขยาย guard จาก 07)
```go
const maxPresenters = 2
func (r *Room) startShare(userID string) error {
    r.mu.Lock(); defer r.mu.Unlock()
    if len(r.media.Presenters) >= maxPresenters {
        return ErrShareLimitReached // → ws:share:denied
    }
    r.media.Presenters = append(r.media.Presenters, userID)
    r.media.HasActiveShare = true
    r.broadcast(MsgShareStarted, ShareStartedPayload{PresenterID: userID})
    return nil
}
```

## DoD
- auto layout switch; presenter name overlay; zoom max 2x; PiP video tiles; latency < 500ms; simulcast ตาม bandwidth; 2 presenters → แบ่งครึ่งจอ; max 2 (คนที่ 3 reject)
- Unit ≥80% (layout select, 2-presenter guard, zoom clamp) · Integration ≥70% (auto-subscribe, stop→grid) · E2E ≥50% (viewer เห็น share, 2 presenters split)

## Risks / Open
- ✅ SFU = LiveKit — `enable_dynacast` เปิดแล้ว, viewer ใช้ `adaptiveStream: true`
- spec ขยาย presenter limit จาก 07 (1) เป็น 2 — ยืนยันว่า 2 เป็น hard limit (RTE-0.2)
