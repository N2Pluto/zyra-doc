# Spotlight — Progress

> log ต่อรอบ (entry ใหม่ไว้บนสุด) · รูปแบบตาม [zyra-doc/README.md § อัปเดตความคืบหน้า](../../README.md)
> สถานะรวมอยู่ที่ blockquote หัว [spec.md](spec.md) · ความพร้อมของ dependency ดู [spec.md § ความพร้อม](spec.md)

---

## 2026-09-09 · Resolve Spotlight PR review findings

- Unified frontend Spotlight Meeting behavior around physical Meeting-zone context and server-confirmed room acceptance, including the solo-occupant prompt path, pending/retry handling, translated rejection feedback, status blocking, PiP companion behavior, and a distinct Stop listening action.
- Added `ws:spotlight:meetingLeave {room_id}`. Acceptance remains room-level, is explicitly revocable, clears when the final media-room member leaves, stays floor-scoped, and still clears when the final Spotlight speaker stops.
- Spotlight broadcaster state now follows the WebSocket speaker snapshot. Listener mic/camera/video attachment now follows the subscribe-only Spotlight SFU rather than Meeting media state.
- Removed dead stage controls and fabricated viewer count, restored non-Spotlight compact-tile styling, stabilized presenter video attachment, and changed countdown to a stable deadline.
- Confirmed `zyra-api` PR #104's behavior is already on `develop` via the existing room classifier, `MapInWorkspace`, UUID guards, and media-room tests; removed only the branch's dead helper/redundant helper-only test and cleaned duplicate comments.
- Verification so far: targeted frontend ESLint and Spotlight Vitest suites pass; `zyra-ws` and `zyra-api` build/vet/full tests pass. Full frontend lint/test validation and final diff review remain before handoff.

## 2026-09-09 · Fix Join action using the live Office WebSocket

- Resolved the `zyra-api` merge artifact in `internal/handler/media_handler.go`: retained the 3-argument `NewMediaHandler` constructor used by `main.go`, retained the Spotlight room helper required by its handler tests, and removed the duplicate prefix/legacy constructor that prevented the package from compiling.

- Adjusted the accepted-meeting companion layout against Figma node `5485:899345`: a non-interactive `#242B32` backdrop now covers the content area so the map cannot show through, while the Spotlight card and Meeting card remain separate, visibly bounded panels.
- Removed the idle tile outline at UI review; the companion card surface, spacing, and rounded corners provide the participant separation instead.
- Fixed the companion Meeting panel to always use the compact tile strip. A prior controlled expanded-state could render the full-screen grid, causing two participants to stretch into oversized cards instead of the fixed Figma tiles.
- Fixed the companion-mode source in the Hero: it now derives meeting presence from the active Meeting zone (`inMeeting`) rather than a delayed duplicate state (`selfInMeeting`). This ensures an accepted member reaches the compact-strip companion layout instead of the full-screen Meeting grid.
- Companion activation now uses the authoritative WebSocket speaker snapshot rather than the media hook's meeting-gated `remoteBroadcastActive`, which can remain false directly after a Meeting accepts Spotlight even though the broadcast is active.
- Set compact companion participant tiles to the Figma card surface `#242528`; participant separation comes from the card surface, spacing, and rounded corners rather than a visible stroke.
- Made companion tiles avatar-forward like the Spotlight stage: avatars are 72px and no longer dim merely because the participant's mic is muted; the muted status remains visible in the name label.
- Verified the presentation component after the layout adjustment with Prettier, targeted Vitest suites, and `git diff --check` in `zyra-app`.

- **ทำอะไร:** Live test สอง browser พบว่าเมื่อกด `Join spotlight` prompt หายเฉพาะ browser ที่กด แต่ไม่มี `accepted_meeting_ids` กลับมาจึงไม่มีใครเปลี่ยนเป็น combined Spotlight + Meeting layout. จุดส่งเดิมอ้าง `wsClient` จาก Zustand subscription ซึ่งอาจชี้ socket ที่กำลังปิดระหว่าง reconnect/HMR; `_send()` ของ socket ที่ไม่ `OPEN` เป็น no-op. เปลี่ยน action ให้ใช้ `wsClientRef.current` ซึ่ง Hero Virtual Office ผูกกับ socket ที่ใช้งานจริงตลอด session และ fallback ไป store เฉพาะเมื่อ ref ยังไม่พร้อม. เพิ่ม fallback ของ Meeting zone ID จาก meeting-chat/occupancy context ด้วย: media connection (`mediaZoneId`) อาจเป็น `null` ชั่วคราวระหว่าง reconnect/leave-grace ทั้งที่ Meeting UI ยัง active; ก่อนหน้านี้กรณีนี้ทำให้ click ไม่ส่ง event เลย. ใช้ zone ID เดียวกันทั้งส่ง acceptance และตัดสินใจแสดง combined layout.
- **ทำอะไร (ต่อ):** ปิดช่อง message lost ระหว่าง control WebSocket reconnect: `WorkspaceWSClient.spotlightMeetingJoin()` เก็บ request ไว้เมื่อ socket ยังไม่ `OPEN` และส่งครั้งเดียวหลังได้รับ `welcome` ของ session ใหม่ แทน `_send()` ที่ทิ้ง message เงียบ ๆ. Server handle ซ้ำได้ idempotent จึงไม่สร้าง acceptance ซ้ำ.
- **ทำอะไร (ต่อ):** Log local runtime ยืนยันว่า Redis ที่ `localhost:6379` ปฏิเสธการเชื่อมต่อ ทำให้ `zoneSet` ไม่มีข้อมูล. Handler เดิม reject `meeting geometry unavailable` ก่อนตรวจ `MediaRoomID` จึงไม่ broadcast acceptance ทั้งที่ทั้งสองคนอยู่ media call. ปรับให้ `MediaRoomID` ที่ตรง Meeting room เป็นหลักฐานเพียงพอเมื่อ geometry unavailable; geometry fallback ยังคงใช้เฉพาะก่อน media handshake. เพิ่ม Go regression test สำหรับ `zoneSet == nil`.
- **verify ถึงไหน:** Vitest Spotlight targeted suite ผ่าน 18 tests, Prettier check ของ `workspace-ws.ts` และ `hero-virtual-office.tsx` ผ่าน, `go test ./internal/hub` ผ่าน และ `git diff --check` ผ่าน.
- **เหลือ/ติดอะไร:** ต้อง refresh สอง browser เพื่อรับ frontend HMR/build ล่าสุด แล้ว live-test ใหม่: คนหนึ่งกด Join → browser สมาชิกทุกคนใน Meeting เดียวกันแสดง Spotlight ด้านบนและ Meeting panel ด้านล่างตาม Figma node `5485:899345`. ยังไม่ commit/push/deploy.

## 2026-09-09 · Fix Meeting-wide acceptance before media handshake

- **ทำอะไร:** พบจากการทดสอบสอง browser ว่า Meeting prompt แสดงได้จาก zone occupancy ก่อน LiveKit จะส่ง `ws:room:enter` เสร็จ แต่ server เดิมต้องการ `Client.MediaRoomID` จึง reject การกด Join ในช่วงนั้น ทำให้ทั้ง Meeting ไม่เปลี่ยนไป Spotlight. ปรับ `ws:spotlight:meetingJoin` ให้รับรองสมาชิก Meeting จาก `MediaRoomID` **หรือ** published geometry (`zoneClaimTileOK`): อย่างแรกครอบคลุม call ที่ active แม้ map snapshot server lag; อย่างหลังครอบคลุม prompt ที่มาก่อน SFU handshake. ยังตรวจว่า room เป็น Meeting จริงและมี Spotlight active บน floor เดียวกันเหมือนเดิม.
- **verify ถึงไหน:** เพิ่ม Go regression tests สำหรับ accept ก่อนตั้ง `MediaRoomID` และ active media room ที่ zone snapshot ยังไม่ทัน; `go test ./internal/hub` ผ่าน และ `git diff --check` ผ่าน.
- **เหลือ/ติดอะไร:** Local `zyra-ws` ที่พอร์ต 3003 ต้อง restart เพื่อโหลด source ล่าสุด แล้ว live-test สอง browser: คนหนึ่งกด Join → ทั้งสองเห็น Spotlight ด้านบนและ Meeting panel ด้านล่าง.

## 2026-09-08 · Meeting-wide acceptance

- Implemented `ws:spotlight:meetingJoin {room_id}` in `zyra-ws`. Requires sender membership in that media room, published meeting-zone geometry, and an active broadcast on sender's floor. Server stores accepted meeting IDs for the current broadcast and includes `accepted_meeting_ids` in full `ws:spotlight:stateUpdate` messages and reconnect snapshots. Last broadcaster stopping clears acceptance. Repeated Join is idempotent.
- `zyra-app` stores that server state and derives Meeting participation from its current media room ID. One member accepting opens Spotlight + the existing Meeting panel for peers in that meeting. Meeting media stays connected. Toast moved to upper right, 360px; companion meeting includes its shared toolbar.
- Verified: Go Spotlight hub tests passed, frontend Spotlight tests passed (18), and diff whitespace checks passed. Multi-browser/live visual verification still required. No deployment performed; app/ws on `feat/spotlight`, docs on `rif`.
- Full TypeScript check reports the existing unrelated errors in `pet-creation-wizard.test.tsx:239` and `pixi-game-scene.test.ts:5831,5872`; no new Spotlight errors reported.

---

## 2026-09-08 · Viewer Spotlight stage for members outside Meetings

- **ทำอะไร:** เพิ่ม viewer takeover ตาม Figma node `5469:891613`: เมื่อมีคนอื่น broadcast อยู่ ผู้ที่ไม่ได้อยู่ใน Meeting จะเห็น Spotlight stage เต็มพื้นที่ฝั่ง canvas พร้อมข้อมูล/สื่อของผู้ถ่ายทอด โดย sidebar ยังใช้งานได้. Viewer ไม่มี toolbar หรือปุ่ม Stop broadcast และซ่อน persistent live banner เพื่อไม่ให้สถานะซ้ำ. ปุ่ม Picture-in-Picture reuse `useDocumentPip`/browser-native PiP เดิมของ Virtual Office จึงเปิดหน้าต่างที่ลากย้ายได้จริง; Spotlight ใช้ PiP lifecycle แยกจาก Outside display และไม่ปิดเมื่อผู้ชมคลิก UI หรือสลับแท็บ. ปุ่ม X ซ่อน broadcast เฉพาะผู้ชมคนนั้นจนกว่า live รอบปัจจุบันจบ. คนที่อยู่ Meeting จะได้ prompt ขนาด 360px ที่มุมบนซ้ายแทน auto-join: Stay in meeting, Join spotlight (เริ่มรับ broadcast เพิ่มโดยไม่ออกจาก Meeting) หรือ X; ไม่มี auto-dismiss และยังคุยกับสมาชิก Meeting เดิมได้. หลัง Join แสดง Spotlight ด้านบนและ compact meeting panel ด้านล่าง. ผู้ที่อยู่ Spotlight tile หรือ opt out จะไม่ถูก takeover.
- **verify ถึงไหน:** เพิ่ม Vitest ยืนยัน prompt ของ Meeting และ Spotlight stage; targeted tests ผ่าน 6 tests. `git diff --check` ของ `zyra-app` ผ่าน.
- **ต้องตัดสินใจก่อนทำต่อ:** Requirement ล่าสุดให้สมาชิกคนหนึ่งกด Join แล้วสมาชิกทุกคนของ Meeting เดียวกันเข้า Spotlight พร้อมกัน เป็น cross-client state ใหม่. WebSocket ปัจจุบันมีเฉพาะ `ws:spotlight:stateUpdate` ระดับ floor (speaker set) และไม่มี event/ownership สำหรับ “meeting accepted Spotlight”; จึงยัง sync ทุก browser ไม่ได้อย่างถูกต้อง. ต้องกำหนด contract ใน `zyra-ws` ก่อน (sender authorization, `meeting_zone_id`/floor payload, broadcast audience, late join/reconnect และ reset เมื่อ Spotlight จบ) แล้วจึงต่อ `zyra-app` ให้ทุก client แสดง combined Spotlight + Meeting layout. Figma toast target node: `5485:899345`.
- **เหลือ/ความเสี่ยง:** ยังต้อง live-test สอง browser/client เพื่อยืนยัน listener ได้ SFU track และ stage ปิดทันทีเมื่อ broadcaster หยุด.

---

## 2026-09-08 · Play countdown, cancellable start, and Spotlight media token authorization

- **ทำอะไร:** ปรับ `zyra-app` ให้กด Play แล้วแสดง countdown 5 วินาทีเหนือ HUD; ระหว่างนับยังไม่ join/publish หรือส่ง `ws:spotlight:start` และกด `Cancel broadcast` เพื่อยกเลิกได้. เมื่อ broadcast live แล้ว presenter เข้า Spotlight stage แบบเต็มหน้าตาม Figma node `5469:892691` (frame 1440×1024): header/people counts, stage media surface, presenter identity, shared media toolbar และปุ่ม Stop broadcast ที่ยุติ session จริง. ซ่อน persistent broadcast banner ใน full-screen stage เพื่อไม่ให้มีสถานะซ้ำ. ก่อนหน้านั้น Panel และ banner ถูก gate ไว้จนกว่าจะกด Play/เริ่ม broadcast จริง. ป้องกัน `relatedTarget` ที่ไม่ใช่ DOM `Node` ก่อนเรียก `contains()` เพื่อแก้ runtime error ตอน mouse leave.
- **แก้ cross-repo:** พบ media token error `failed to verify room` เพราะ client ใช้ `spotlight:<floorId>` แต่ `zyra-api` อนุญาตเฉพาะ zone UUID. เพิ่มการ authorize ห้อง virtual Spotlight โดยตรวจว่า `<floorId>` เป็น map UUID ที่อยู่ใน workspace เดียวกัน; room ปกติยังตรวจ zone เดิม.
- **verify ถึงไหน:** `zyra-app` targeted Vitest ผ่าน 17 tests; `zyra-api` `go test ./internal/handler ./internal/service` ผ่าน. `git diff --check` ผ่านทั้งสอง repo.
- **เหลือ/ความเสี่ยง:** ยังไม่ได้ live-test จริงครบ cycle (Play → countdown จบ → LiveKit token/connect, และ Cancel ก่อนครบเวลา) หรือ multi-client broadcast.

---

## 2026-09-07 · Explicit Play ก่อนเริ่ม Spotlight broadcast

- **ทำอะไร:** ปรับ `zyra-app` ให้การเข้า Spotlight tile ยังไม่ join/publish Spotlight media และไม่ส่ง `ws:spotlight:start`; เพิ่มปุ่ม Play ทางขวาของ HUD เป็น action เริ่ม broadcast
- **ถึงไหน:** start request ผูกกับ Spotlight zone entry ปัจจุบัน; กด Play แล้วจึง join `spotlight:<floorId>` และส่ง start; เดินออกหรือ status opt-out reset request และส่ง stop
- **verify ถึงไหน:** targeted test ยืนยัน enter=no-op, Play=start, leave=stop ผ่าน; lint/typecheck/broader checks กำลังตรวจ
- **ต่อจากนี้:** verify visual บน local/dev และดำเนิน flow ส่วนอื่นตาม decision ที่เหลือใน spec
- **ติดอะไร:** ยังไม่ได้ live-test แบบหลาย client

---
