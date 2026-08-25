# Technical Design — 08 · Screen Share — Window / Tab (SC-RTE-08)

> [Spec](../spec.md#sc-rte-08--screen-sharing--window--tab) · ClickUp [86d2weuzy](https://app.clickup.com/t/86d2weuzy) · **ต่อยอด 07** (ต่างที่ source type + fps)
> อ่าน [07-screen-share-fullscreen](07-screen-share-fullscreen.md) ก่อน — flow/events เหมือนกัน

## Goal
Share เฉพาะ Window หรือ Tab ผ่าน browser native picker (3 tab: Entire Screen / Window / Tab), รองรับ tab audio, frame rate ต่างกันตาม source

## Affected
- `zyra-app` (getDisplayMedia constraints, source detect) — backend เหมือน 07 ทั้งหมด

## ความต่างจาก 07 (Full Screen)
| ด้าน | Full Screen (07) | Window / Tab (08) |
|------|------------------|-------------------|
| Source | Entire Screen | Window / Tab |
| Frame rate | 15fps | **Window 15fps, Tab 30fps** |
| Audio | optional system audio | **Tab: รองรับ tab audio** |
| Data leak | ทั้งจอ | **Window: เฉพาะ window ที่เลือก ไม่รั่ว** |
| Picker UI | browser native | browser native (3 tab — **ไม่สร้าง UI เอง**) |

> WS events, presenter guard, stop flow, cleanup = **เหมือน 07 ทุกอย่าง** (`ws:share:*`) — task นี้ต่างแค่ constraints ฝั่ง client

## Key Logic
- **Native picker:** เรียก `getDisplayMedia` แล้ว browser แสดง 3 tab เอง — ระบบไม่ render picker เอง
- **Source-type detect:** อ่านจาก `track.getSettings().displaySurface` (`monitor` / `window` / `browser`) → set fps hint
- **Tab audio:** `getDisplayMedia({ video, audio: true })` — Tab share เก็บ tab audio track มาด้วย
- **Frame rate:** constraints `frameRate: { ideal: surface === "browser" ? 30 : 15 }`
- **Window isolation:** browser การันตี window share ไม่รั่ว source อื่น (OS-level) — verify ใน test

## Client-side (TS)
```ts
const stream = await navigator.mediaDevices.getDisplayMedia({
  video: { frameRate: { ideal: 30 } },   // browser จะ cap เองตาม surface
  audio: true,                            // tab audio (ถ้า user เลือก Tab)
})
const surface = stream.getVideoTracks()[0].getSettings().displaySurface
// surface: "monitor" | "window" | "browser" → ใช้ log/analytics
```

## DoD
- picker 3 ตัวเลือก (browser จัดการเอง); window share ไม่รั่ว; tab audio ทำงาน; fps Window 15 / Tab 30
- Unit ≥80% (source-type→fps mapping, audio flag) · Integration ≥70% (reuse 07) · E2E ⚠️ fake-device ≥50%

## Risks / Open
- fps ที่ได้จริงขึ้นกับ browser/OS — เป็น "ideal" ไม่การันตี
- tab audio รองรับเฉพาะบาง browser (Chrome/Edge) — Firefox/Safari จำกัด
