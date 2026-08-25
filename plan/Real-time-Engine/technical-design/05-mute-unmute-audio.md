# Technical Design — 05 · Mute / Unmute Audio (SC-RTE-05)

> [Spec](../spec.md#sc-rte-05--mute--unmute-audio) · ClickUp [86d2weuee](https://app.clickup.com/t/86d2weuee) · **ใหม่** (SFU + `ws:audio:*`)
> อ่าน [00-architecture-overview](00-architecture-overview.md) §4 — SFU = **LiveKit** (`zyra-sfu` :7880) ✅ พร้อมแล้ว

## Goal
Mute/unmute ทำงาน client-side (< 200ms), server track state เพื่อ broadcast indicator, รองรับ force-mute (target ต้อง unmute เอง), speaking animation, `audio_active_count`

## Affected
- `zyra-app` (toggle track, HUD, shortcut `M`, indicator) · `zyra-ws` (mute state broadcast, force-mute relay) · **SFU** (audio track)

## Architecture (media plane vs control plane)
```
Mute:  client หยุดส่ง audio MediaStreamTrack → SFU (media plane)
   → ส่ง ws:audio:muteChanged {muted:true} → zyra-ws (control plane)
   → zyra-ws broadcast indicator ให้ทุก member + update audio_active_count
```
- **Media** (เสียงจริง) = SFU · **State/indicator** = `zyra-ws` (ทุกคนเห็น mic-slash icon แม้ยังไม่ได้ยินเสียง)

## WS Events
| Event | ทิศทาง | Payload |
|-------|--------|---------|
| `ws:audio:muteChanged` | C→S | `{room_id, muted}` |
| `ws:audio:stateUpdate` | S→C | `{user_id, muted, audio_active_count}` |
| `ws:audio:forceMute` | C→S | `{room_id, target_user_id}` |
| `ws:audio:forceMuted` | S→C (target) | `{by_user_id}` → toast "…ได้ปิดไมค์ของคุณ" |

## Key Logic
- **Client-side mute:** `track.enabled = false` (ไม่ replace track, กลับมาเร็ว < 200ms) — ไม่หยุด publish ทั้งหมด
- **Shortcut `M`** → toggle (guard double-press < 200ms → state สุดท้าย)
- **Default mute** ตาม user preference ตอน join room
- **Force-mute:** ใครก็สั่ง force-mute คนอื่นได้ → server ส่ง `ws:audio:forceMuted` ให้ target → target mute ทันที. **Member อื่น unmute แทนไม่ได้** — เฉพาะ target เอง หรือคนที่สั่ง==คนเปิด (ตาม spec: "ให้คนที่ปิดกับคนเปิดเป็นคนเดียวกัน หรือแค่เจ้าตัว")
- **Speaking animation:** ใช้ LiveKit `ActiveSpeakersChanged` event (หรือ `RoomEvent.ActiveSpeakersChanged`) → ring รอบ avatar เมื่อ unmute+พูด
- **`audio_active_count`** = count(members where !muted) — update ใน RoomState (ดู 03)

## Server-side (Go)
```go
func (r *Room) setMute(userID string, muted bool) {
    r.media.Members[userID].Muted = muted
    r.recomputeAudioCount()
    r.broadcast(MsgAudioStateUpdate, AudioStatePayload{
        UserID: userID, Muted: muted, AudioActiveCount: r.media.AudioActiveCount,
    })
}
```

## DoD
- toggle < 200ms; `M` shortcut; mic-slash icon real-time; default ตาม preference; force-mute + toast; target unmute เองเท่านั้น; speaking animation; count ถูกต้อง (≥0)
- Unit ≥80% (toggle, force-mute rule, count) · Integration ≥70% (broadcast, forceMuted relay) · E2E ≥50% (2 users mute/speak)

## Risks / Open
- ✅ SFU = LiveKit — active-speaker ใช้ `ActiveSpeakersChanged` (มี built-in)
- **client-side mute (`track.enabled=false`) เสียงหยุดที่ client** — SFU ยัง track publish อยู่; ต้อง verify ว่า peer ไม่ได้ยิน (หรือใช้ `setMicrophoneEnabled(false)`)
- นิยาม "ใคร force-mute ได้บ้าง" (ทุกคน? host เท่านั้น?) ต้อง confirm — spec กำกวม (RTE-0.2)
