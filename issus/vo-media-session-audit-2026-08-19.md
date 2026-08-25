# VO Media Session / Roster / Status — Proactive Bug Audit (2026-08-19)

ตรวจเชิงรุกต่อจากชุดบั๊ก "เสียงหลุดจาก meeting เก่า + ตัวละครค้าง in-meeting + Busy ไม่ตัด session" (zyra-app PR #119)
เพื่อหาว่ายังมีกรณีไหนอีกที่ทำให้เกิดอาการตระกูลเดียวกันได้ — ตรวจ 3 ด้าน: client media lifecycle (zyra-app),
server state (zyra-ws), status/roster surfaces (zyra-app)

**Baseline ของ line numbers:** zyra-app = branch `fix/vo-stale-meeting-media` (merge แล้วใน develop), zyra-ws = main ปัจจุบัน
ทุกข้อ CONFIRMED ถูก trace โค้ดครบเส้นทางแล้ว / SUSPECTED = เส้นทางจริงแต่ผลลัพธ์ปลายทางยังไม่ได้พิสูจน์

---

## กลุ่ม A — CRITICAL (ควรแก้ก่อน)

### A1. `scheduleReconnect` ไม่ดู DisconnectReason → สอง tab เตะกันวนไม่รู้จบ [CONFIRMED]
`use-meeting-media.ts:957` — `sfu.on("disconnected", scheduleReconnect)` ทิ้ง `reason` ที่ sfu-client ส่งมาให้ทุกครั้ง
ผู้ใช้เปิด VO 2 tab เข้า meeting เดียวกัน → LiveKit เตะ tab แรกด้วย `DUPLICATE_IDENTITY` → tab แรก auto-reconnect
→ เตะ tab สอง → วนตลอดไป (cap 3 ครั้งไม่เคย trip เพราะ `reconnectAttempt = 0` ทุกครั้งที่ connect สำเร็จ, :807)
อาการ: เสียงกระตุกทุก ~1 วิ ทั้งสอง tab, join/leave storm ใส่เพื่อนทุกคน, ไฟไมค์กระพริบ
**แก้:** ส่ง reason เข้า scheduleReconnect — ห้าม auto-rejoin เมื่อ `DUPLICATE_IDENTITY` / `PARTICIPANT_REMOVED` /
`ROOM_DELETED` / `CLIENT_INITIATED` และ reset attempt counter เฉพาะเมื่อ connection อยู่รอดเกิน ~15 วิ

### A2. `session_replaced` ไม่ตัด media session ของ tab เก่า [CONFIRMED]
`hero-virtual-office.tsx:2472-2475, 8605` — เปิด tab ใหม่ทับ → tab เก่าโชว์ modal "session replaced" แต่
`destroySession()` ไม่แตะ `activeZone`/route params ที่ `mediaZoneId` ใช้ → hook media ไม่เคย cleanup:
**ไมค์ tab เก่ายังส่งเสียงอยู่ (LED ติด, เพื่อนยังได้ยิน) และเสียง meeting ยังเล่นอยู่หลัง modal โดยไม่มี UI ให้ปิด**
รวมกับ A1 = ping-pong เตะกันไม่จบ
**แก้:** ให้ flag `sessionReplaced`/`capacityFull` บังคับ `mediaZoneId = null` (หรือเคลียร์ activeZone ใน handler)

### A3. zyra-ws: reconnect ด้วย socket ใหม่ ข้าม cleanup ของ socket เก่าทั้งหมด — root cause ฝั่ง server [CONFIRMED]
`room.go:385` — `if !r.clients.CompareAndDelete(c.UserID, c) { return }` (guard กัน phantom "left" ซึ่งถูกต้อง
สำหรับ presence) แต่มัน return ก่อนบรรทัด 395-465 ทั้งหมด: `removeFromAudioRoom`, `stopShare`, `releaseSeat`,
`removeFromMeetingChat`, `aoi.Remove`, chat subs, follow ฯลฯ — ทุก network blip/laptop wake ที่ reconnect
ทัน 200ms window จะทิ้ง ghost state ไว้ เป็นต้นตอของ B1-B5 ด้านล่าง
**แก้:** แยก resource-cleanup ออกจาก presence guard — ให้ `register` reclaim ของเก่าก่อน store client ใหม่
(ทั้งคู่ serialize ด้วย `lifecycleMu` อยู่แล้ว) ระวังอย่า broadcast "left" สำหรับคนที่กลับมาแล้ว

### A4. Busy ยังนับเป็น "Online" ใน zone-section → เพื่อนยังเห็นจุดแดง In meeting + ห้องล็อกค้าง [CONFIRMED]
`hero-virtual-office.tsx:5775` — `newPresence = myStatus === "away" ? "Away" : "Online"` (busy = Online)
และ `usersInMeeting` สาย section (`hero:7362-7368`) ไม่กรอง status เลย → คนกด Busy หลุดจาก media/roster
แล้ว (fix #119) แต่ nameplate จุดแดง, member panel row, DM dots, context menu ยังโชว์ In meeting หมด
ซ้ำร้าย: คน Busy คนเดียวในห้อง **keep section + lock ไว้ตลอด** และปลดล็อกไม่ได้เพราะ panel ถูกปิดไปแล้ว
**แก้:** map busy → "Away" ในการเขียน presence + กรอง status ใน `usersInMeeting` สาย section

---

## กลุ่ม B — HIGH

### B1. Ghost ใน audio snapshot ส่งให้คนเข้าใหม่ — zombie ที่ client แก้ไม่ได้ [CONFIRMED]
`zyra-ws/audio.go:565-613` — `sendAudioSnapshot` iterate `st.members` ดิบๆ ไม่กรอง live client
(ต่างจาก `audioActiveCountLocked` ที่กรอง) → คนเข้า zone ทีหลังได้ ghost เข้า `memberAudio` และไม่มีวันได้
`participantLeft` มา prune (ghost ตายไปก่อนเราเข้า) → **zombie ถาวรใน roster ของคนเข้าใหม่**
**แก้:** กรอง snapshot (และ `sendShareSnapshot`) ด้วย live client + `MediaRoomID == roomID` + ลบ entry เสียทิ้ง

### B2. Presenter slot รั่วถาวรเมื่อ presenter reconnect (เช่น reload ระหว่างแชร์จอ) [CONFIRMED]
ผลจาก A3 — slot ไม่ถูกปล่อย → `max_presenters_reached` ตลอดไป, snapshot ข้ามตัวเอง (`screenshare.go:169-171`)
เลยไม่มีใครรู้ว่าตัวเองค้าง, "ขอ slot" ก็ส่งถึง ghost ไม่ได้ = ทางตัน
**แก้:** validate presenters กับ live clients ทุกครั้งที่แตะ + reclaim ตอน reconnect

### B3. Ghost เป็น meeting owner ค้าง → force-mute/kick ใช้ไม่ได้ทั้งห้อง [CONFIRMED]
`audio.go:149-163, 631-656` — `joinOrder[0]` เป็น owner โดยไม่เช็ค liveness; ghost หัวแถว = ไม่มีใครในห้อง
(นอกจาก workspace owner/admin) mute/kick ใครได้ และ room state ถูก pin ตลอดชีวิต process
**แก้:** `meetingOwnerLocked` ข้าม id ที่ไม่มี live client ในห้อง + prune joinOrder ตอน enter/leave

### B4. Kick (#37) ไม่ตัด media ของคนถูกเตะ — แค่เดินออก [CONFIRMED delay / SUSPECTED indefinite]
`hero:4118-4161` + `zyra-ws/audio.go:398-436` — kick เป็นแค่ unicast แจ้งเตือน ระหว่างเดินออก (หลายวินาที)
คนถูกเตะ**ยังได้ยินและถูกได้ยิน**ทั้งที่หายจาก roster แล้ว; ถ้าเดินออกไม่ได้ (นั่งอยู่/ทางตัน) ค้างใน media ตลอด
และ server ไม่มี ban list — join กลับได้เสรี; `participantJoined` ฝั่ง peers ยังเคลียร์ `removedUserIds` ให้ด้วย
**แก้:** เมื่อได้ `ws:meeting:kicked` ให้บังคับ `mediaZoneId = null` ทันที (media ตายก่อน การเดินออกเป็นแค่ภาพ)

### B5. ไม่มี application-level liveness ฝั่ง server — tab ที่ JS ค้าง/freeze ถือที่นั่ง meeting ไว้ได้ไม่จำกัด [CONFIRMED]
`client.go:12-24` — eviction อิง WS ping/pong ล้วน ซึ่ง browser ตอบได้แม้ page freeze; `ClientMsgHeartbeat`
ไม่เคยถูกเก็บ timestamp มาใช้ (แค่ต่ออายุ Redis TTL)
**แก้:** เก็บ `lastAppMessageAt` + reaper ใน `runSessionTicker` เตะออกจาก media/share/chat state หลังเงียบ ~60 วิ
(ข้อเดียวนี้ครอบ B1-B3 เป็น backstop ทั้งหมด)

### B6. Camera-timeout ทิ้งกล้องค้าง (LED ติด) จนกว่าจะ reload [CONFIRMED]
`sfu-client.ts:524-530` — `CameraTimeoutError` rethrow ข้าม `_stopOrphanedTrack`; acquire ที่ช้า resolve
ทีหลัง recoverMediaSession → track ไม่มีใคร stop
**แก้:** เก็บ promise ของ camera acquire ไว้บน instance แล้ว stop ใน `_teardown`/`_disconnectNow`

### B7. dnd เลือกได้จาก picker แต่ไม่เข้ากฎ opt-out ใดๆ เลย + สีชนกับ "In meeting" [CONFIRMED]
`vo-status-picker.tsx:14-21` — dnd เลือกได้จริง แต่ไม่ถูก gate ใน mediaZoneId/roster/occupancy/force-clear/
circle clustering (zyra-ws กรองแค่ busy/away) = รูเดียวกับ busy ที่เพิ่งปิด และ `presence-status.ts:12-16`
ให้ dnd สีแดง `#F03A3A` เดียวกับ meeting (picker กลับโชว์ม่วง) — แยกไม่ออกจาก "In meeting"
**แก้:** ตัดสินใจ semantics — แนะนำรวม dnd เข้า predicate เดียว `optedOutOfSharedSpace(status)` + เปลี่ยนสี dot

### B8. Away กลางวง: media ถูกตัด (fix #119) แต่ panel ยังเปิด — ปุ่มทั้งหมดเป็น no-op เงียบๆ [CONFIRMED]
`hero:7813, 10485` กรองแค่ busy ไม่กรอง away ขณะที่ `mediaZoneId` กรองทั้งคู่ → กด Away กลาง meeting
ได้ panel ค้างที่ mic/cam/share กดแล้วเงียบ (zoneIdRef null)
**แก้:** ใช้ predicate เดียวกันทุก gate (ดูข้อเสนอท้ายเอกสาร)

### B9. Prefetch restore ไม่เรียก `setMyStatus` → server บอก available แต่ client ตัวเองไม่มี session [CONFIRMED]
`hero:3518-3538` — สาย prefetch rewrite savedStatus เป็น available ส่งให้ engine+WS แต่ไม่ set state ตัวเอง
(สาย getProfile ทำถูก :3551) → reload กลางห้อง meeting = เพื่อนเห็นเราปกติใน roster แต่เราไม่มี media
**แก้:** mirror `setMyStatus`/`setMyCustomMsg` ในสาย prefetch

### B10. `usersInMeeting` self-branch นับตัวเองด้วย → ยืนคนเดียวในห้อง meeting ก็ขึ้นจุดแดง [CONFIRMED]
`hero:7377-7383` — `ownRoom.participants.length >= 1` แต่ participants รวมตัวเองอยู่แล้ว → off-by-one
กระทบ HUD dot, self row, nameplate, chat-sound mute, announcement suppress
**แก้:** `>= 2` หรือตัด self ออกก่อนนับ

### B11. WS reconnect กลางแชร์จอ: server ลืม slot แต่ client ไม่ re-assert `shareStart` → เกิน cap 2 ได้ [CONFIRMED]
`use-meeting-media.ts:683-692` re-announce mic/cam/hand แต่ไม่ share
**แก้:** `if (sharePublishedRef.current) wsNow?.shareStart(zoneId)` ใน handler เดียวกัน

---

## กลุ่ม C — MEDIUM

- **C1.** Nameplate suppression ใช้ `usersInMeeting` แต่ facepile ใช้ geometry (กรอง busy แล้ว) → sprite ไร้ชื่อ
  /ไร้ hover ตอนซูมออก เมื่อสองชุดไม่ตรงกัน (`scene.ts:3752-3787, 5928` vs `hero:7506-7514`) — ใช้ set เดียวกัน
- **C2.** ไม่มี event "member left media room" จาก server: คนออกทั้งที่กล้องเปิด → ไม่มี `video:stateUpdate(false)`,
  คน muted ออก → ไม่มี event เลย; client พึ่ง LiveKit `participantLeft` ทางเดียว (`audio.go:660-695`)
  — เพิ่ม `ws:meeting:memberLeft` broadcast + client prune ตามนั้น (control-plane prune ไม่พึ่ง media plane)
- **C3.** Permission-grant re-warm publish ไมค์แบบ unmuted ชั่วครู่กลาง meeting ทั้งที่ UI บอก muted
  (`use-meeting-media.ts:753-762`) — acquire→mute→publish หรือข้าม re-warm เมื่อ micOn=false
- **C4.** Spotlight listener reconnect ไม่มี cap + ไม่ดู reason (`use-spotlight-broadcast.ts:232-247`) —
  2 tab ฟัง spotlight เดียวกัน = ping-pong ทุก 2 วิ
- **C5.** `establish()` ซ้อนกันได้ (recoverMediaSession stale ref / reconnectTimer / reconnected handler)
  → double getUserMedia, mute state พลิก, announce ซ้ำ (`use-meeting-media.ts:1317-1326, 933-935, 940-955`)
  — ใช้ in-flight promise + generation token
- **C6.** Screen share ไม่มี orphan-stop: เปิด picker → เดินออกจาก zone → ค่อยเลือกหน้าต่าง = แชร์ค้างทั้ง
  Chrome bar โดยไม่มี UI หยุด (`sfu-client.ts:635-690`) — server slot ไม่รั่ว (คนละประเด็นกับ B2)
- **C7.** bfcache/page freeze: ไม่มี pagehide handler; resume แล้ว WS ฟื้นเอง + re-announce แต่ LiveKit PC
  ตายเงียบ ไม่ trigger reconnect → HUD เขียว/เพื่อนเห็น unmuted แต่ไม่มีเสียงสองทาง — เช็ค `sfu.state.connected`
  ตอน visibility resume แล้ว `recoverMediaSession()`
- **C8.** Meeting text-chat + spotlight room ไม่ gate busy/away (`hero:5318, 5338`) — "participated" ค้างใน
  transcript, join broadcast room ทั้งที่ Busy
- **C9.** Circle: panel + `chatSpaceRoomId` ไม่ gate busy ฝั่ง client — พึ่ง server re-cluster (~1 วิ + ถ้า
  socket ล่มก็ค้าง) (`hero:10577-10580, 5325-5331`)
- **C10.** setStatus ตอน socket ไม่ open = drop เงียบ + ทุก reconnect รีเซ็ต status เป็น available ชั่วครู่
  (`workspace-ws.ts:974-978`) — queue แล้ว flush ตอน open / เก็บ status ใน Redis ข้าม Join
- **C11.** zyra-ws AOI: reconnect ใน cell เดิมไม่ replace `*Client` pointer เก่า (`aoi.go:44-46`) → คน
  reconnect เห็นเพื่อนแข็งค้างจน heartbeat 3 วิช่วย — แก้ 1 บรรทัด (re-Store pointer) **น่าจะเป็นสาเหตุ
  รายงาน "reconnect แล้วคนอื่นกระตุก/วาร์ป"**
- **C12.** เก้าอี้ล็อกค้างถาวรหลัง reconnect ขณะนั่ง (`seatOccupants` ไม่ถูก release, ผลจาก A3) — บล็อกทั้ง
  นั่งและเดินผ่าน tile
- **C13.** Meeting-chat session ไม่มีวันตาย (member เป็น `*Client` ตาย) → log ไม่ถูกล้าง, S3 attachments รั่ว
  (`meetingchat.go:263-322`)

## กลุ่ม D — LOW (จดไว้ เก็บตอนแตะไฟล์)

- D1. `memberAudio` ค้างจาก `audioMuteChanged(true)` หลัง connect fail (`use-meeting-media.ts:797`)
- D2. Reaction TTL timers ไม่ถูก clear ตอน cleanup (:1129)
- D3. `_pendingBgApply` ไม่ถูกล้างใน `_teardown`
- D4. WS listener ผูกกับ instance เดิม — ถ้า `initSession` รันซ้ำโดยไม่ remount hero, indicator ตายเงียบ
- D5. `knockPending`/`chatSubs` in-memory ไม่มี TTL/prune (zyra-ws)
- D6. Follow-chain half-link หลัง reconnect (leader ค้าง badge)
- D7. Minimap: `activeMeetingZoneIds` ใช้ `present_count > 0` (ไม่ใช่ ≥2, ไม่กรอง busy) + คน Busy มองไม่เห็น
  dot เพื่อนทุกคนบน minimap ตัวเอง (`hero:5226` — น่าจะไม่ตั้งใจ)
- D8. คน Busy ที่ยืนในห้องโผล่ในลิสต์ "invite เข้าห้องนี้" (`hero:9920-9934`)
- D9. Restore จาก auto-away คืนค่า busy เข้า meeting zone ได้โดยไม่ผ่าน force-clear
- D10. ไม่มี listener สำหรับ status_changed ของตัวเอง (จะกลายเป็นบั๊กทันทีที่มี status control นอก VO)

---

## ลำดับการแก้ที่แนะนำ

1. **A1 + A2** (zyra-app, ไฟล์เดียวกับ #119) — กัน ping-pong สอง tab + tab เก่าหลอน = อาการที่ผู้ใช้เจอบ่อยสุด
2. **A4 + B7 + B8 + B10** (zyra-app) — รวมเป็น PR เดียว: predicate กลาง `optedOutOfSharedSpace(status)`
   (busy/away/dnd) ใช้กับ mediaZoneId / meetingChatZoneId / spotlightRoomId / chatSpaceRoomId /
   hasMeetingPanel / panel gates / presence mapping + กรอง section ใน usersInMeeting + แก้ off-by-one
3. **A3** (zyra-ws) — reclaim-on-register ต้นตอฝั่ง server (ปิด B2, B3, C12, C13, D5, D6 พร้อมกัน)
4. **B5 + B1** (zyra-ws) — liveness reaper + snapshot filter เป็น defense-in-depth
5. **C11** (zyra-ws, 1 บรรทัด) — คุ้มสุดต่อบรรทัด
6. ที่เหลือตาม severity เมื่อแตะไฟล์นั้นๆ
