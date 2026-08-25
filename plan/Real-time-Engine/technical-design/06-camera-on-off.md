# Technical Design — 06 · Camera On / Off (SC-RTE-06)

> [Spec](../spec.md#sc-rte-06--camera-on--off) · ClickUp [86d2weuk9](https://app.clickup.com/t/86d2weuk9) · **ใหม่** (SFU + `ws:video:*`)
> อ่าน [00-architecture-overview](00-architecture-overview.md) §4 — SFU = **LiveKit** (`zyra-sfu`) ✅ พร้อมแล้ว

## Goal
Camera toggle client-side (< 500ms), shortcut `V`, camera-off → avatar preview/initials, default off ตาม preference, permission-denied handling. **Admin force camera-off ไม่รองรับ (privacy)**

## Affected
- `zyra-app` (toggle video track, HUD, shortcut, fallback tile) · `zyra-ws` (camera state broadcast) · **SFU** (video track)

## Architecture
```
Camera off: client หยุดส่ง video MediaStreamTrack → SFU
   → ws:video:cameraChanged {camera_on:false} → zyra-ws broadcast indicator
   → viewer render avatar preview / initials แทน video tile
```

## WS Events
| Event | ทิศทาง | Payload |
|-------|--------|---------|
| `ws:video:cameraChanged` | C→S | `{room_id, camera_on}` |
| `ws:video:stateUpdate` | S→C | `{user_id, camera_on}` |

> **ไม่มี** force-camera event — privacy โดย design (ต่างจาก audio ที่มี force-mute)

## Key Logic
- **Toggle:** `videoTrack.enabled = false` off, `true` on (< 500ms) — cleanup ให้ไม่ leak ghost track เมื่อ toggle ถี่
- **Shortcut `V`** → toggle
- **Fallback tile:** camera off → แสดง avatar preview (รูปเล็ก) หรือ initials (ตัวย่ออักษรแรกของชื่อ)
- **Default off** ตาม user preference ตอน join
- **Permission:** ขอครั้งแรกที่ join room. Denied → ปุ่ม Camera `disabled` + tooltip แนะนำเปิด permission
- **Camera + screen share พร้อมกันได้** (track แยก — ดู 07)

## Client-side (TS)
```ts
const toggleCamera = async () => {
  const on = !camState.on
  videoTrack.enabled = on            // fast path, no re-acquire
  setCamState({ on })
  ws.send("ws:video:cameraChanged", { room_id, camera_on: on })
}
```

## DoD
- toggle < 500ms; `V` shortcut; off → preview/initials + camera-slash icon; default ตาม preference; admin force-off ไม่มี; permission denied → disable+tooltip
- Unit ≥80% (toggle, fallback render, permission state) · Integration ≥70% (broadcast) · E2E ⚠️ fake-device ≥50% (2 users on/off)

## Risks / Open
- ✅ SFU = LiveKit — camera toggle ใช้ `setCameraEnabled()` / `videoTrack.enabled`
- E2E ต้องใช้ Chromium `--use-fake-device-for-media-stream` — permission-deny path test ยาก
