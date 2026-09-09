# Spotlight — Progress

> log ต่อรอบ (entry ใหม่ไว้บนสุด) · รูปแบบตาม [zyra-doc/README.md § อัปเดตความคืบหน้า](../../README.md)
> สถานะรวมอยู่ที่ blockquote หัว [spec.md](spec.md) · ความพร้อมของ dependency ดู [spec.md § ความพร้อม](spec.md)

---

## 2026-09-09 · แก้ companion layout (Spotlight + Meeting) ให้ตรง Figma 5495:910662

- **ทำอะไร:** ดึง spec จาก Figma MCP (node `5495:910662` — Spotlight display พร้อม Meeting panel) แล้วแก้ค่าที่เพี้ยนจาก design
  - **ระยะห่างสองการ์ด:** design วาง Spotlight panel `top=16 height=720` และ Meeting panel `top=744` → ห่างกัน **8px** พอดี. โค้ดเดิมกัน bottom ไว้ `300px` ตายตัว จึงเหลื่อม เปลี่ยนเป็น `bottom-[312px]`: ขอบบน Meeting panel = 16 (offset) + ความสูงคงที่ของ panel, ต้องการ gap 8 แล้วหัก `p-[16px]` ของ wrapper อีกชั้น. ค่าสุดท้าย: tile สูง 160 → panel สูง 304 → ขอบบนอยู่ 320 → ขอบการ์ด 328 → `bottom-[312px]` (รอบแรกใส่ 288 แล้วยังห่าง เพราะลืมหัก padding ของ wrapper)
  - **สี tile ผู้เข้าร่วม:** design ใช้ `rgba(255,255,255,0.05)` บนพื้น `#1A1B1E` ไม่ใช่สีทึบ — เดิมเป็น `#242528` (นี่คือ "สีไม่ตรง")
  - **ขนาด tile:** ยืนยันจาก `get_metadata` (`5468:673373` / `5468:673375`) — แถว tile กว้าง 1336, chevron 32×32, tile = 202.67 × 120, avatar = 42 × 42 กลาง tile. ค่าจริงที่ใช้หลังรีวิวกับผู้ใช้คือ **`h-[160px] max-w-[318px] flex-1` + `justify-center` + avatar 56px** = ขนาดเดียวกับกล่อง screen-share compact (`zone-enter-screen-share.tsx:127`) เป๊ะ ตามที่ผู้ใช้สั่ง "ให้ขนาดเท่าแชร์จอ" — geometry จึงไม่ต่างจาก tile ปกติของโปรเจกต์แล้ว เหลือต่างแค่สีพื้น (white 5% ตาม design). ลำดับที่รีวิวมา: ปล่อย flex เต็มแถว → "ยืด" → cap 203 ชิดซ้าย → "เล็ก/ควรอยู่กลาง" → 318×120 กลาง → "ต้องสูงกว่านี้ให้สมส่วน" → 318×188 → "กรอบรวมสูงเกิน" → 318×160 (เท่า screen-share)
  - **Meeting panel head:** design เป็น Display Head 56px (`px-8 py-16`) เหมือนหัว Spotlight — companion mode ครอบ `PanelHeader` ด้วย container 56px (เพิ่ม `w-full` ให้ PanelHeader ให้ยืดเต็มใน container)
  - **Spotlight panel:** padding 16 → **8**, เพิ่ม `gap-[24px]` ระหว่าง head กับ stage, head 36px → **56px** (`px-8`), ชื่อ stage 16px → **14px medium**, chip `h-24 p-4`, ปุ่มหัวการ์ด 28px → **24px** (`p-4` + icon 16), พื้น stage `#242528` → `rgba(255,255,255,0.05)` + `rounded-12` + `p-4`, ป้ายชื่อย้ายมาอยู่ใน flow มุมล่างซ้าย (`bg-black/80` + blur, `px-12 py-8`, `rounded-12`, 16/22), avatar เต็มจอ 220px → **35% ของความสูง stage** ตาม design
  - **ปุ่มกลางบนหัวการ์ด:** design เป็นปุ่มไอคอน 3 อันเท่ากัน (PiP / Chat / X) — ของเราปุ่มกลางเป็น `Stop listening` แบบมีข้อความ จึงเปลี่ยนเป็นปุ่มไอคอนขนาดเท่ากัน (24px) แต่ **ยังเป็น Stop listening ไม่ใช่ Chat** เพราะ Spotlight chat ยังไม่ได้ทำ → รอ PM เคาะว่าจะเพิ่มปุ่ม Chat ตาม design (งานใหม่) หรือคง Stop listening ไว้ในช่องนี้
- **verify ถึงไหน:** targeted Vitest 5 ไฟล์ 63 tests ผ่าน (อัปเดต 2 assertion ที่ผูกกับค่าเก่า: `bottom-[300px]` → `bottom-[312px]`, `bg-[#242528]` → `rgba(255,255,255,0.05)` + h-160/max-w-318), `tsc --noEmit` ไม่มี error ใหม่, ESLint + Prettier ผ่าน
- **เบี่ยงจาก design อย่างตั้งใจ (ผู้ใช้สั่งในรีวิว):** tile companion ใช้ 318×160 + avatar 56px แทน 202.67×120 + 42px ของ Figma เพราะ viewport จริงแคบกว่า frame 1440 (design ได้ 202px จากการมี 6 tiles พอดีในแถว) และต้องเท่ากล่อง screen-share ที่โปรเจกต์ใช้อยู่
- **ยังต่างจาก design:** ระยะซ้าย/ขวาของสองการ์ด (design ชิดขอบ sidebar 0 + ขวา 16 บน sidebar 72px; ของเรา sidebar 56px และเว้น 16 ทั้งสองข้าง) — ยังไม่แก้เพราะเป็น layout ระดับหน้า ไม่ใช่จุดที่รีวิว; MeetingTimer ในหัว Meeting panel ไม่มีใน design; ยังไม่ได้ live-test ผ่าน UI

---

## 2026-09-09 · แก้ Bell entry ไม่ขึ้นเลย (validation + CHECK constraint บน dev DB)

- **ทำอะไร:** ผู้ใช้รายงานว่าไม่เห็น notification เลย ตรวจแล้วเจอสองสาเหตุ
  1. **Bug จริงในโค้ด:** `validateSpotlightBroadcast` ตรวจ `actor_id`/`recipient_ids` ด้วย `uuid.Parse` แต่ `tb_user.id` เป็น `VARCHAR` (เก็บ identity-provider subject เช่น Google sub `111238104937251950343`) → request จริงถูกตีกลับ 400 ทั้งหมดและไม่มี row เกิดขึ้นเลย แก้เป็นตรวจ non-empty + `maxUserIDLen` (255) เฉพาะ `workspace_id`/`session_id` ที่เป็น UUID column จริงจึงยังตรวจ UUID; เพิ่ม test case ของ Google-sub id, blank และ id ยาวเกิน
  2. **dev DB:** CHECK constraint `tb_notification_type_check` บน dev DB (`gather-dev`) ไม่มี `spotlight_live` ทั้งที่ column ใหม่สองตัวมีแล้ว (embedded DDL ของ instance ที่รันตอน 16:34 ใส่ให้แล้ว) → ถูก revert ทีหลัง ตรงกับคำเตือนใน `internal/database/postgres.go` ว่า statement นี้ DROP/ADD constraint ทุก boot ดังนั้น **instance ที่ยังไม่มีโค้ดนี้ boot ทับได้** (dev DB นี้ถูกใช้ร่วมกับ environment ที่ deploy ไว้) จึงรัน statement ของ migration 98 ใส่ dev DB ให้แล้ว (column + CHECK + index, idempotent)
- **verify ถึงไหน:** ยิง internal endpoint ด้วย id จริง (workspace + user จริงในระบบ) `POST /api/internal/spotlight/broadcasts` → 200 และเกิด row `spotlight_live` จริงใน `tb_notification`; `POST .../:sessionId/end` → 200 และ `spotlight_ended_at` ถูก set; `go vet`/`go test ./...` ของ `zyra-api` ผ่านทั้งหมด
- **ข้อควรรู้/ยังต้องทำ:**
  - จนกว่า branch นี้จะขึ้น `develop`/dev **instance เก่าที่ boot ทับจะลบ `spotlight_live` ออกจาก CHECK อีก** แล้ว insert จะ fail เงียบ ๆ (best-effort call) — ถ้าเจออาการ noti ไม่ขึ้นซ้ำ ให้ตรวจ constraint ก่อน
  - พฤติกรรมที่ตั้งใจ: **ผู้ broadcast ไม่ได้รับ entry ของตัวเอง** และผู้รับคือสมาชิกที่อยู่ floor เดียวกัน "ตอนเริ่ม" เท่านั้น → ทดสอบด้วยบัญชีเดียว/workspace ที่มีสมาชิกคนเดียวจะไม่เห็นอะไรเลยตามดีไซน์ ต้องใช้ 2 บัญชีที่อยู่ workspace + floor เดียวกัน
  - ยังไม่ได้ live-test ผ่าน UI จริง

---

## 2026-09-09 · Durable Notification Bell entry for a Spotlight broadcast (EC-02)

- **ทำอะไร:** ทำ Bell entry ของ Spotlight ให้ **durable** ตามที่ผู้ใช้เคาะ (spec §7 ข้อ 14 → ดู Decision ใหม่ใน spec §1) เพื่อให้คนที่ปิด toast หรือกด X ออกจาก stage แล้วยังกลับเข้า broadcast ได้ และเมื่อ live จบ card เปลี่ยนเป็น "Broadcast ended" ที่ไม่มีปุ่ม Join
  - `zyra-api`: migration `98_notification_spotlight.sql` เพิ่ม type `spotlight_live` + column `spotlight_session_id` / `spotlight_ended_at` และ index ของ session (มิร์เรอร์ใน embedded DDL ของ `internal/database/postgres.go` ด้วย — ไม่งั้น CHECK constraint ถูก revert ทุก boot); `NotificationService.CreateSpotlightLive` / `EndSpotlightLive` insert-แล้ว-push และปิด session พร้อม push row ที่อัปเดต; internal endpoint `POST /api/internal/spotlight/broadcasts` และ `POST /api/internal/spotlight/broadcasts/:sessionId/end`; `ListNotifications` ส่งสองคอลัมน์ใหม่ออกไปด้วย
  - `zyra-ws`: `Room.spotlightSessions` ถือ session ปัจจุบันต่อ floor (สร้างเมื่อ speaker set ว่าง → ไม่ว่าง, ลบเมื่อว่าง), ส่ง `session_id` ไปกับ `ws:spotlight:stateUpdate` ทุกครั้งรวม snapshot, และเรียก zyra-api แบบ fire-and-forget ผ่าน `Hub.postInternalJSON` ใหม่ (pattern เดียวกับ `cleanupMeetingAttachments`). Recipients = คนที่อยู่ floor นั้นตอนเริ่ม ยกเว้นผู้ broadcast; สร้างเฉพาะ session ที่เพิ่งเปิดและ `notify=true` จึงไม่ซ้ำตอน reconnect re-assert
  - `zyra-app`: `spotlightSessionId` ใน `vo-session-store`; การ์ดใหม่ `SpotlightNotificationCard` ใน `vo-notification-panel` (badge broadcast แทน avatar, ปุ่ม Join ตอน live, ข้อความ ended เมื่อจบ); `canJoinBroadcastFromNotification` เป็น pure guard ให้ Join ได้เฉพาะ session ที่ live อยู่จริง ไม่งั้นเด้ง `spotlightEndedBeforeJoin`; hero เชื่อม Join เข้ากับการล้าง `spotlightViewerDismissed`/opt-out + ส่ง `spotlightMeetingJoin` ให้คนที่อยู่ใน Meeting; copy ใหม่ 6 คีย์ทั้ง en/th
  - `prependNotification` ใน chat-store เปลี่ยนให้ replace **ตรงตำแหน่งเดิม** (ตาม comment ที่เขียนไว้แต่เดิม) เพราะ row เดียวถูก push สองครั้ง (live → ended) และไม่ควรกระโดดขึ้นหัว list; แก้ test เดิมที่ยืนยันพฤติกรรมเก่าแล้ว
- **verify ถึงไหน:** `zyra-api` `go build/vet/test ./...` ผ่าน (เพิ่ม test ของ payload/validate + `dedupeIDs`); `zyra-ws` `go build/vet/test ./...` ผ่าน (เพิ่ม `spotlight_notification_test.go`: session id lifecycle, start/end call ผ่าน httptest stub ของ internal API, ข้าม re-assert, recipients ต่อ floor); `zyra-app` targeted Vitest 10 ไฟล์ 125 tests ผ่าน (มี `vo-notification-panel-spotlight.test.tsx` ใหม่), `tsc --noEmit` ไม่มี error ใหม่ (ยังเหลือ error เดิมที่ไม่เกี่ยวใน `pet-creation-wizard.test.tsx`, `pixi-game-scene.test.ts`), ESLint ของไฟล์ที่แก้ + Prettier + `git diff --check` ผ่านทั้งสาม repo
- **เหลือ/ติดอะไร:** ยังไม่ได้ live-test สอง browser (เริ่ม broadcast → คนอื่นเห็น entry ใน Bell → กด Join กลับเข้า stage → ผู้ broadcast หยุด → card เปลี่ยนเป็น ended). ต้องรัน migration 98 บน dev ก่อนทดสอบ และ `zyra-ws` ต้องมี `ZYRA_API_URL` + internal secret ตั้งไว้ ไม่งั้น entry จะไม่ถูกสร้าง (broadcast ยังทำงานปกติ). ยังไม่ commit/push/deploy. ข้อที่ยังไม่เคาะและตั้งใจไม่ทำ: recipients ระดับ workspace-wide/offline (§7 ข้อ 5), retention ของ row (§7 ข้อ 8/18), toast 15 วินาที + accept/later ตาม HP-04, และ setting เปิด-ปิดการแจ้งเตือนนี้

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
