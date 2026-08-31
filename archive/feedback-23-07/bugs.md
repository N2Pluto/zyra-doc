# 🐞 Bugs (Issue) — Feedback 23-07

รวม **23 รายการ** ที่จัดเป็นบัค (ทำงานผิด/ไม่ตรงตามที่ควรจะเป็น) จาก [README.md](README.md) — รวมชุด UX/UI (#1–#43) และ AI100 (#45–#56)

**เรียงตาม priority:**
- 🔴 **High:** [#15](#15) · [#50](#50) · [#55](#55) · [#56](#56)
- 🟠 **Medium:** [#1](#1) · [#9](#9) · [#22](#22) · [#33](#33) · [#42](#42) · [#43](#43) · [#46](#46) · [#47](#47) · [#51](#51) · [#54](#54)
- 🟡 **Low:** [#3](#3) · [#12](#12) · [#24](#24) · [#25](#25) · [#26](#26) · [#27](#27) · [#30](#30) · [#45](#45) · [#52](#52)

> คำอธิบายฟิลด์: **Effort** `S`<ครึ่งวัน / `M` 1–2 วัน / `L` >2 วัน หรือข้าม service · **Conf.** ความมั่นใจของการวิเคราะห์

---

## Feedback

<a name="15"></a>
### #15 — อีเมล feedback ไม่แนบรูป (ส่งแค่ลิงก์) `Feedback · 🔴 High · Effort M · Conf. high`

**Feedback เดิม:** "Email ที่ส่ง ไม่ส่งรูป"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-notifications/internal/mailer/mailer.go` (ตัวประกอบ/ส่งเมล)
- `zyra-notifications/internal/mailer/templates.go` (~L904–906 `buildSupportNewEmailHTML`)
- `zyra-notifications/internal/handler/handler.go` (`emailRequest`)
- `zyra-api/internal/notify/client.go` (`sendRequest`)
- `zyra-api/internal/service/support_service.go` (`CreateTicket` / `sendEmails`)
- `zyra-app/views/help-center/components/contact-support-form.tsx` (ฝั่งแนบรูป)

**สาเหตุ / บริบทปัจจุบัน:**
ไล่เส้นทางแล้วพบว่า **ระบบไม่เคย "แนบรูป" จริง มีแต่ลิงก์**:
1. FE แนบรูปเป็น multipart field `attachment` → `POST /api/user/support/tickets`
2. BE `CreateTicket` อัปโหลด byte ขึ้น R2/S3 (`s3.UploadJPEG/UploadPNG`) แล้วเก็บแค่ **public URL string** ลง DB
3. `sendEmails` ส่งต่อเป็นพารามิเตอร์ `attachment_url` (แค่ URL)
4. `notify/client.go` + `handler.go` รับ params เป็น `map[string]string` เท่านั้น → **ไม่มีช่องส่ง binary**
5. `mailer.go > Send` ประกอบอีเมลเป็น single-part `text/html` ไม่มี multipart/mixed
6. template แสดงรูปเป็นแค่ `<a href=attachment_url>View attachment</a>` ไม่ใช่ `<img>` inline และไม่ใช่ไฟล์แนบ

→ ถ้า bucket/publicURL ไม่ได้เปิด public หรือ mail client บล็อกรูป remote ผู้รับจะไม่เห็นรูปเลย

**แนวทางแก้ (end-to-end):**
1. `mailer.go > Send`: เปลี่ยนจาก single-part เป็น **multipart/mixed** เมื่อมี attachment (เพิ่ม `Content-Type` ตามชนิดรูป + `Content-Transfer-Encoding: base64` + `Content-Disposition: attachment`; หรือ `inline` + `Content-ID` เพื่อฝัง `<img src=cid:...>`)
2. ขยาย pipeline ให้ส่ง byte ได้: เพิ่ม field `attachments {filename, content_type, data_base64}` ใน `emailRequest` + `sendRequest` + signature ของ `Send/SendAsync`
3. `support_service.go`: ส่ง `in.AttachmentData` (byte ที่มีในหน่วยความจำอยู่แล้ว) เป็น base64 ไปกับ `TemplateSupportNew`

**ทางเลือกเบา (ชั่วคราว):** เปลี่ยน template เป็น `<img src=attachmentURL>` inline + ยืนยัน bucket `support/*` เปิด public — แต่ยังเสี่ยงถูก mail client บล็อก จึงแนะนำวิธีแนบไฟล์จริง

---

## Display

<a name="1"></a>
### #1 — Private zone ไม่ขึ้นไอคอน Mic/Video ตอน hover `Display · 🟠 Medium · Effort S · Conf. high`

**Feedback เดิม:** "Hover ตรง Display ของคนอื่นใน Private zone ไม่ขึ้น Icon Mic & Video — ที่จริงควรจะขึ้นไม่ว่าจะอยู่ใน Meeting room, Private zone หรือตอน Circle"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (~L8888–8890)
- `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx` (`RequestMediaControls` ~L971)

**สาเหตุ / บริบทปัจจุบัน:**
ไอคอน Mic/Video บน hover คือปุ่มใน `RequestMediaControls` ที่จะแสดงเมื่อ `canRequestMedia === true` (Compact L836–837 / Expanded L1053–1054) ซึ่งต้องมี prop `onRequestMediaOff` ถูกส่งเข้ามา
ที่ hero ~L8888 ส่งแบบมีเงื่อนไข: `activeZone.zone_type === "meeting" ? handleRequestMediaOff : undefined` → **ใน Private zone จึงเป็น `undefined`** → hover แล้วไม่ขึ้นไอคอน
(Circle L8993 ส่ง handler ตรง ๆ และ Meeting ผ่านเงื่อนไข → ทั้งสองปกติ ตรงกับ feedback ที่บอกว่าพลาดเฉพาะ Private zone)

**แนวทางแก้:**
ที่ hero ~L8888 แก้เงื่อนไขให้ Private zone ได้ handler ด้วย เช่น
`(activeZone.zone_type === "meeting" || activeZone.zone_type === "private") ? handleRequestMediaOff : undefined`
หรือส่ง `handleRequestMediaOff` ตรง ๆ เหมือนบล็อก Circle — ไม่ต้องเพิ่ม UI ใหม่ (overlay `group-hover` รองรับอยู่แล้ว)
ควรเช็ก `handleRequestMediaOff` (~L6388) ว่าใช้ได้กับ private-zone media session ด้วย

---

<a name="3"></a>
### #3 — ไม่มี notif เมื่อมี meeting chat + รูปโปรไฟล์ไม่ตรงตัวละคร `Display · 🟡 Low · Effort M · Conf. med`

**Feedback เดิม:** "(3.1) ไม่มี Notification เมื่อข้อความมาใน meeting chat · (3.2) รูปโปรไฟล์ไม่ตรงกับตัว Display"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (`meeting_chat:append` ~L2383–2390, mute เสียง ~L1492)
- `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx` (`hasUnreadChat` ~L2449–2453)
- `zyra-app/zyra-engine/pixi-game/scene.ts` (sprite ~L4888/5272)
- `zyra-app/lib/api/workspace-members.ts` (`avatar_url`)

**สาเหตุ / บริบทปัจจุบัน:**
- **3.1:** handler `meeting_chat:append` แค่ append เข้า state เฉย ๆ ไม่ยิงเสียง/toast — affordance เดียวคือจุดแดง `hasUnreadChat` (เห็นเฉพาะตอน compact + แชทปิด) ยิ่งกว่านั้น เสียงแจ้งเตือนแชทปกติถูก **ปิดเสียงเมื่ออยู่ในมีทติ้ง** (`if (inMeetingRef.current) return` ~L1492) → ข้อความ meeting chat จึงเงียบสนิท
- **3.2:** การ์ด Display แสดง headshot (self = `user.image_upload`, remote = `member.avatar_url`) ส่วนตัวสไปรต์ในแมพใช้ `walk_sprite_url` (สไปรต์ชีตตัวละคร) ซึ่งเป็นภาพคนละชุดกันโดยดีไซน์ → รูปการ์ดกับตัวละครไม่ตรงกัน และ self/remote มาจากคนละแหล่ง อาจไม่ตรงกัน

**แนวทางแก้:**
- **3.1:** ใน `meeting_chat:append` เพิ่มการแจ้งเตือนเมื่อข้อความมาจากคนอื่น (`entry.user_id !== self`) และแชทปิด: reuse `chatNotificationSoundRef` และ/หรือขึ้น toast/badge เลียนแบบ path ของ DM (~L1462–1498) + เพิ่ม i18n `en.json`/`th.json`
- **3.2:** กำหนด single source of truth ของรูป participant — resolve headshot ให้สม่ำเสมอทั้ง self/remote หรือถ้าอยากให้ตรงตัวละครจริง ให้ใส่ character thumbnail บนการ์ด; ตรวจว่า `member.avatar_url` เป็นรูปโปรไฟล์จริง ไม่ใช่ spritesheet (ผ่าน `/api/user/*`)

---

<a name="43"></a>
### #43 — วาง object ชิดกำแพงแล้วทะลุ `Display · 🟠 Medium · Effort M · Conf. med`

**Feedback เดิม (UX/UI #43):** "วาง object ชิดกำแพงแล้วทะลุ"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/zyra-engine/pixi-game/utils.ts` (`objectSortRow` L24–32, `effectiveObjectSortRow` L75–80, `WALL_MOUNT_LAYER` L54, `wallMountOccluders`/`playerZOverWallMounts` L102–116)
- `zyra-app/zyra-engine/pixi-game/scene.ts` (`piece.sprite.zIndex = encodeZ(...)` ~L900, wall occluder ~L269)
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (`pzIsOccupied` L5285–5321, `pzInBounds` L5220–5233)
- `zyra-api/internal/service/workspace_service.go` (`footprintBlocked` L602–616)

**สาเหตุ / บริบทปัจจุบัน:**
การวาง object ทับ/ชิด wall tile **อนุญาตโดยดีไซน์** — ผนังเป็น visual boundary ไม่ใช่ collision: FE `pzIsOccupied` ข้าม tile ที่เป็น wall (`if (!placingWall && pzWallObjectIds…) continue` L5309) และ `pzInBounds` เช็คแค่ขอบแมพ; BE `footprintBlocked` ก็ระบุ "non-wall placements may freely overlap wall tiles" (L606–607)
→ อาการ "ทะลุ" จริง ๆ เป็นปัญหา **z-order** ไม่ใช่ collision: wall **ไม่มี depth priority** — `objectSortRow` จัด wall ผ่าน default branch (`anchorTileY + rows − 1`) เท่าเฟอร์นิเจอร์ทั่วไป มีแค่ `walkable_group` (back-most) กับ `wall_mounted` (front-most, `WALL_MOUNT_LAYER`) ที่ออกนอกแถว → object ที่แถวล่าง ≥ แถวล่างของ wall (หรือ object ที่เป็น `wall_mounted`) จึงวาด **ทับหน้า** ผนัง = เห็นเหมือนทะลุ

**แนวทางแก้:**
ให้ wall มีลำดับ occlusion ใน render z-order — เพิ่ม wall band ใน `effectiveObjectSortRow`/`objectSortRow` (`utils.ts`) หรือทำ wall-occluder carve-out เลียนแบบ `wallMountOccluders`/`playerZOverWallMounts` ให้ผนังบัง object ที่อยู่ข้างหลัง · ถ้าต้องการบล็อกการวางจริง ให้เพิ่ม bounds ห้ามทับ wall tile ที่ `pzIsOccupied` (L5303/L5309) + `footprintBlocked` (L606–607)

---

## Avatar

<a name="9"></a>
### #9 — กด WASD/ลูกศรไม่ยกเลิกการเดินแบบ "Go to" `Avatar · 🟠 Medium · Effort S · Conf. high`

**Feedback เดิม:** "ตอน Go to ไม่สามารถกด wasd หรือ ลูกศร เพื่อยกเลิกการเดินได้"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/zyra-engine/pixi-game/scene.ts` (`walkToTile` ~L4463–4479, `onKeyDown` ~L1047–1062, `_updateMovement` ~L1997)
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (`onGoTo` ~L7742–7754)

**สาเหตุ / บริบทปัจจุบัน:**
"Go to" เรียก `walkToTile()` ซึ่งตั้ง `pathFromMouse = false` แล้วเก็บเส้นทางใน `pathQueue`
การยกเลิกด้วยปุ่มเดินมี 2 จุด แต่ไม่ครอบกรณีนี้:
- `onKeyDown` set `targetX/Y = null` แต่เคลียร์ `pathQueue` เฉพาะเมื่อ `this.blockWalk` (โหมด follow)
- `_updateMovement` เคลียร์ `pathQueue` เฉพาะเมื่อ `anyKey && this.pathFromMouse === true`

→ เพราะ Go to ตั้ง `pathFromMouse = false` เส้นทางจึงไม่ถูกตัด avatar เดินต่อจนถึงปลายทาง (คลิกเดินด้วยเมาส์ยกเลิกได้เพราะ `pathFromMouse = true`)

**แนวทางแก้:**
ใน `_updateMovement` (~L1997) ยกเลิกเงื่อนไข `this.pathFromMouse` ออก หรือเพิ่มสาขาให้เคลียร์ `pathQueue` เมื่อ `anyKey` ไม่ว่าเส้นทางจะมาจากคลิกหรือ `walkToTile` โดยคง logic เดิม: fire `onPathEndedCallback` (ส่ง stop ให้ server), snap ไป tile center, reset `_blockAutoSitUntilPathEnd`/`_pendingSeat` — ต้องไม่กระทบโหมด follow (`blockWalk`) แก้จุดเดียวไฟล์เดียว

---

<a name="42"></a>
### #42 — เก้าอี้หันหลังชนกัน นั่งผิดตัว (ว๊าปไปตัวหลัง) `Avatar · 🟠 Medium · Effort M · Conf. med`

**Feedback เดิม (UX/UI #42):** "วางเก้าอี้หันหลังชนกัน ตัวละครจะว๊าปไปนั่งด้านหลังแสดง ต้องนั่งตามตำแหน่งที่เดินไป"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/zyra-engine/pixi-game/scene.ts` (`_triggerSit` L3611–3645 — warp ที่ L3636–3637 `this.px/py = seat.worldX/Y`; seat pick แรก L1307–1310, confirm L1215–1284, auto-sit L1129–1147; seat registration L925–978, `registerBodyTile` skip-if-claimed L959)

**สาเหตุ / บริบทปัจจุบัน:**
`_triggerSit` teleport ไป seat anchor (`seat.worldX/worldY`) **โดยไม่ reconcile กับ tile ที่ avatar เดินไปจริง** · สำหรับเก้าอี้ 2 ตัวที่ tile ติดกัน (หันหลังชนกัน): `registerBodyTile` ข้าม tile ที่ถูกจองแล้ว (`if (this.sittableSeats.has(k)) return` L959) → เก้าอี้ที่ import ก่อนยึด body/hitbox tile ที่ทับกัน คลิกเก้าอี้อีกตัวบน tile นั้นเลย resolve ได้ `worldX/Y` ของเก้าอี้ตัวแรก; หรือ `sitPoints` offset (`anchorWorldX + sp.x` L932–933) ทำให้ sit anchor ไปตกบน tile ของเก้าอี้ตัวหลัง → avatar "ว๊าป" ไปนั่งตัวหลัง

**แนวทางแก้:**
ที่ `_triggerSit` L3636–3637 (และ seat pick L1130/L1308) resolve seat จาก **ด้าน/tile ที่ avatar ยืน** + `selSeatObj`/`seatToObject` (คลิกตรง object ไหน) แทนการเชื่อ `sittableSeats` per-tile ที่เก้าอี้ติดกันเขียนทับกันได้ — เลือก sit anchor ที่ tile ตรงกับตำแหน่งปัจจุบันของ avatar

---

<a name="45"></a>
### #45 — เดินชนตัวละครอื่นแล้วลากตัวนั้นไปด้วย `Avatar · 🟡 Low · Effort M · Conf. med`

**Feedback เดิม (AI100 #1):** "ตัวละครเดินชนกันจะโดนอีกตัวละครลากไปด้วย"

> **หมายเหตุ:** ทีมระบุสถานะ In-Progress

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/zyra-engine/pixi-game/scene.ts` (`_tickOverlapTimer` L3977–4029, `_pushIfOccupied` L4031–4069 — dodge direction L4043–4050, `_isDodgeForbiddenZone` L4101–4108)
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (`stepAwayFromOccupiedTile` = no-op L1564)

**สาเหตุ / บริบทปัจจุบัน:**
peer ไม่เคยถูกดันจากการชนจริง (remote avatar เป็น server-interpolated ล้วน — `PathMovement`/`posBuffer`) — อาการ "ลาก" คือ **local push-out ของตัวเราเอง**: เมื่อ avatar ค้างบน tile ที่ `occupiedByRemote` ≥ `OVERLAP_DELAY_S` (0.15s) `_pushIfOccupied` ย้ายตัวเราไป tile ข้างเคียงแล้ว broadcast เป็น move · heuristic เลือกทิศ "away from occupant facing" (L4043–4050) ใช้ `remoteDir` = ทิศ peer ล่าสุด ซึ่งสำหรับ peer ที่เพิ่งเดินตามมาข้างหลังจะชี้ **ย้อนกลับตาม corridor** → ดันตัวเรา **ไปข้างหน้าตามทางเดิน** เกิดการไถลต่อเนื่อง (chaining) = ความรู้สึก "ถูกลากไป"

**แนวทางแก้:**
`_pushIfOccupied` L4037–4050 — เลือก dodge tile จาก geometry ของตัวเราเอง (away-from-shared-tile / ทิศ approach จริง) แทน facing ของ peer · และ/หรือ `_tickOverlapTimer` L4001/L4016 ยืด settle หรือบังคับให้ peer ต้อง "หยุด" (ไม่ใช่แค่เดินผ่าน) ก่อนจึง nudge

---

<a name="46"></a>
### #46 — เห็นเพื่อนลอย `Avatar · 🟠 Medium · Effort M · Conf. med`

**Feedback เดิม (AI100 #2):** "เห็น เพื่อนลอยได้"

> **หมายเหตุ:** ทีมระบุสถานะ In-Progress · ทับกับ item #2 ในเอกสารเก่า `zyra-doc/issues/ai100-feedback-2026-07-21.md` (เคย fix แล้ว 2026-07-21) → อาจเป็น regression หรืออีก vector ของอาการเดิม

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/zyra-engine/pixi-game/utils.ts` (`tileToWaypoint` L138–151, `trimRemainingPath` L237–276 — hardcode py L249–252)
- `zyra-app/zyra-engine/pixi-game/scene.ts` (`updateRemotePlayerPos` L5795–5874, `setRemotePlayers` L5210–5231 — trust raw px/py L5212–5213, sit path L5826–5832, sit-invariant "B" L2027–2038)

**สาเหตุ / บริบทปัจจุบัน:**
เป็น y-anchor mismatch หลาย vector: (1) **sitter ที่ seat ยังไม่ลงทะเบียนบน client** (chair ที่ claimant วางใน private zone / seats ยังโหลดไม่เสร็จ) → `updateRemotePlayerPos` คง walk foot-anchor ไว้ + guard L2027 gate ด้วย `sittableSeats.size > 0` → sitter ค้างที่ fallback anchor = "ลอย" เฉพาะที่คนอื่นเห็น; (2) **welcome/resync เชื่อ `snap.px/py` ดิบ** (L5212–5213) ที่ server เก็บเป็น tile-centre (`ty*32+16`) สูงกว่า foot anchor ~19px จนกว่า `moved_bin` ตัวถัดไปจะ re-anchor; (3) `trimRemainingPath` (L249–252) hardcode `py = tile_y*TILE_SIZE + TILE_SIZE + 3` ทุก tile ไม่เผื่อ wall-tile offset ที่ `tileToWaypoint` ให้ (`ty*32+26`)

**แนวทางแก้:**
re-anchor peer ที่ยืนผ่าน `tileToWaypoint` แทนการเชื่อ raw px/py ใน `setRemotePlayers` (L5212–5213) · ให้ `trimRemainingPath` (L249–252) ใช้ `tileToWaypoint`/รับ `wallTiles` · จัดการช่วง seat-ยังไม่โหลดใน sit path (L5826–5832 / invariant L2027) แทนการปล่อย sitter ที่ fallback anchor

---

## Profile

<a name="47"></a>
### #47 — เปลี่ยนชื่อแล้วเพื่อนเห็นไม่เปลี่ยน (จอตัวเองเปลี่ยน) `Profile · 🟠 Medium · Effort S · Conf. high`

**Feedback เดิม (AI100 #3):** "เปลี่ยนชื่อแล้วชื่อไม่เปลี่ยน แต่ที่จอตัวเองเปลี่ยน แต่เพื่อนเห็นไม่เปลี่ยน"

> **หมายเหตุ:** ทีมระบุสถานะ In-Progress

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (charName effect → `setPlayerName` L3059–3063, `notifyProfileUpdated` caller เดียว L7644, peer patch L1968–1982 — id compare L1972)
- `zyra-app/lib/api/workspace-ws.ts` (`notifyProfileUpdated` L782–788)
- `zyra-app/lib/api/workspace-members.ts` (`updateMyCharacterName` L255–260)
- `zyra-ws/internal/hub/room.go` (`handleProfileUpdated` L1548) + `message.go` (`ProfileUpdatedPayload` L255–259)

**สาเหตุ / บริบทปัจจุบัน:**
pipeline broadcast ครบและถูกต้องทุกช่วง (local tag → `setPlayerName`, WS `profile_updated` → `broadcastExcept` → peer patch `otherPlayers`) — จุดที่ขาดคือ **trigger**: `notifyProfileUpdated` ถูก wire ไว้ที่ path เดียวคือปุ่ม Save ในแท็บ Profile ของ `VOSettingModal` · การเปลี่ยน character name ผ่าน path อื่นอัปเดต local tag (charName effect) + persist DB (`updateMyCharacterName`) **โดยไม่ยิงเฟรม `profile_updated`** → peer ที่ต่ออยู่แล้วค้างชื่อเก่า (อ่านชื่อใหม่ได้จาก join/`welcome` snapshot เท่านั้น) · รอง: peer handler เทียบ id แบบ case-sensitive (`p.user_id === user_id` L1972) ต่างจากที่อื่นที่ lower-case — `tb_user.id` เป็น VARCHAR ถ้า casing ต่างจะ drop patch เงียบ ๆ

**แนวทางแก้:**
เรียก `notifyProfileUpdated` จากทุก entry point ของ rename (หรือ centralize ให้ DB-write + WS-notify + local-tag เกิดพร้อมกันเสมอ) · lower-case การเทียบ id ที่ L1972

---

## Decoration

<a name="33"></a>
### #33 — พื้นที่ว่าง (เขียว) แต่ขึ้น error "occupied" `Decoration · 🟠 Medium · Effort L · Conf. med`

**Feedback เดิม:** "มีพื้นที่ว่าง(สีเขียว)แต่ไม่สามารถวาง Object ได้ error occupied (เหตุเกิดคล้ายตอนหลังบ้าน)"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-api/internal/service/workspace_service.go` (`checkFootprintCollision` L623–671, `ErrCellOccupied` L664)
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (`pzResolveFootprint` L5183–5197, `pzIsOccupied` L5230, `handlePzPlace` L5416–5433)
- `zyra-app/lib/api/user-workspace-editor.ts`

**สาเหตุ / บริบทปัจจุบัน:**
FE คำนวณ occupancy ด้วย footprint **แบบ direction-aware** (`hitboxCols/hitboxRows`) → ghost เขียว (valid) บน tile ที่ว่างจริง
แต่ backend `checkFootprintCollision` ใช้ **AABB จาก `grid_width × grid_height` เต็มกล่อง** ของ object เดิมใน DB
เมื่อ object เดิมมี hitbox เล็กกว่า bounding grid → tile ที่ FE เห็นว่าว่างยังทับ bounding box ของ object เดิม → server คืน `ErrCellOccupied` (409) → `handlePzPlace` โชว์ toast "occupied" ทั้งที่ FE pre-check ผ่าน (ตรงกับบั๊กหลังบ้านที่เคยเจอ)

**แนวทางแก้:**
แก้ที่ backend ให้ collision ตรงกับ FE/builder: `checkFootprintCollision` ต้อง resolve footprint จริง (hitbox cols/rows ต่อ direction/variant) แทนกล่อง `grid_width × grid_height` เต็ม ทั้ง object ที่วางใหม่และ object เดิมที่ scan จาก DB (คงกฎ stacking `footprintBlocked` L602–616 ไว้)
เป็นงาน **cross-service** ต้องให้ข้อมูล hitbox เข้าถึงได้ฝั่ง Go + เพิ่ม test เคส "FE valid แต่ BE reject"

---

## Sound

<a name="12"></a>
### #12 — ได้ยินเสียง join meeting ทั้งที่อยู่นอกห้อง `Sound · Priority ไม่ระบุ · Effort S · Conf. high`

**Feedback เดิม:** "อยู่นอก Meeting ได้ยินเสียงคน Join Meeting"

> **หมายเหตุ:** ตารางต้นฉบับไม่ระบุ Type — จัดเป็นบัคเพราะเป็นเสียง sound-effect รั่วข้ามสถานะ (ไม่ใช่ voice รั่ว)

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (โหลดเสียง ~L1052–1059, guard เล่นเสียง ~L2181–2197, leave path ~L6825–6833 / ~L3830–3836)
- `zyra-app/lib/api/zone-sections.ts` (`is_member` L55–56, L71–72)

**สาเหตุ / บริบทปัจจุบัน:**
เสียง `enter-room-01.mp3` (`enterRoomSoundRef`) เล่นใน handler WS `section_sync` เมื่อ `zoneType === "meeting" && playerInZone && memberCountIncreased`
โดย `playerInZone = existingSync?.is_member === true || inPayload`
**root cause:** flag `is_member` เป็นแบบ sticky — `is_member = true` เมื่อ `status != NotAccess` เมื่อผู้ใช้เดินออก `leaveZoneSection` ลดจาก Member(2) → Access(3) (ไม่ใช่ NotAccess) ดังนั้น `is_member` ยัง `true` → คนที่ออกไปแล้ว (แต่ยังมีสิทธิ์กลับเข้า) ยังผ่านเงื่อนไข → ได้ยินเสียงทุกครั้งที่มีคน join

**แนวทางแก้:**
แก้ guard ~L2187 ให้เช็ค physical presence จริงแทน `is_member` เช่น:
- `activeZoneRef.current?.id === payload.zone_id` (โซนที่ผู้เล่นยืนอยู่จริง), หรือ
- `(payload.online_member_ids ?? []).includes(myId)`

คงเงื่อนไข `zoneType === "meeting"` + `memberCountIncreased` ไว้ · self-join (~L6962) ปล่อยได้ · แนะนำเพิ่ม unit test เคส "ออกจากห้องแล้ว `is_member` ยัง true → ต้องไม่เล่นเสียง"

---

## Chat

<a name="22"></a>
### #22 — แก้ไขสมาชิกได้ก่อนกดปุ่ม Edit `Chat · 🟠 Medium · Effort M · Conf. med`

**Feedback เดิม:** "เลือก member ยังไม่ได้กดปุ่ม Edit แต่สามารถแก้ไขได้แล้ว ต้องกด Edit ก่อนถึงจะแก้ไขได้"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/chat/components/create-group-modal.tsx` (ปุ่ม "Edit" L526–542, `handleSave` L268)
- `zyra-app/views/chat/components/conversation-info-panel.tsx` (เปลี่ยน role)

**สาเหตุ / บริบทปัจจุบัน:**
ในโหมด edit (Settings) ของ `CreateGroupModal` ฟอร์ม name/description และ toggle รายชื่อสมาชิก **แก้ได้ทันทีตั้งแต่เปิด** — ปุ่มล่างชื่อ "Edit" (ไอคอน Pencil) จริง ๆ ทำหน้าที่ Save → ผู้ใช้งง (การเปลี่ยน role ใน `ConversationInfoPanel` ก็ไม่มี gating เช่นกัน)

**แนวทางแก้:**
เพิ่ม state `editing` (default `false`) เฉพาะโหมด edit:
- ยังไม่กด → input/textarea เป็น `readOnly/disabled` + member rows กดไม่ได้ (view mode), ปุ่มล่าง = "Edit" → `setEditing(true)`
- `editing === true` → ปุ่มเปลี่ยนเป็น "Save" เรียก `handleSave` แล้ว reset (ใช้ `canSubmit` เดิมต่อได้)

---

<a name="24"></a>
### #24 — เมนู 3 จุดของข้อความค้าง ต้องกดซ้ำ `Chat · 🟡 Low · Effort M · Conf. med`

**Feedback เดิม:** "กด 3 จุดตรงข้อความ เมนูที่ปรากฏออกมาค้าง ต้องกด 3 จุดอีกครั้งจึงยุบกลับ" ([วิดีโอ](https://drive.google.com/file/d/1mssiBZdfqt8JmCRh6QWutls6IG_juOjh/view))

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/chat/components/message-item.tsx` (`MessageContextMenu` L282, L332–359, click-outside L143–157)

**สาเหตุ / บริบทปัจจุบัน:**
`MessageContextMenu` render แบบ `absolute` อยู่ใน hover action bar ที่เป็น `hidden group-hover:flex` เมื่อเปิดเมนู (`menuOpen`) แล้วเลื่อนเมาส์ออก action bar ถูกซ่อนแต่ `menuOpen` ยัง `true` → พอ hover กลับมาเมนูยังค้าง (click-outside/Esc มี แต่ไม่ครอบเคสนี้)

**แนวทางแก้:**
sync การมองเห็น action bar กับ state เมนู — เพิ่ม `onMouseLeave` ที่ root → `setMenuOpen(false)` **หรือดีกว่า** portal เมนูไป `document.body` พร้อมคำนวณตำแหน่งเหมือน reaction picker (`computePickerPos` L164–172) → **แก้คู่กับ #25 ในคราวเดียว**

---

<a name="25"></a>
### #25 — เมนู 3 จุดใกล้กล่องพิมพ์ถูกตัด `Chat · 🟡 Low · Effort M · Conf. high`

**Feedback เดิม:** "กด 3 จุดตรงข้อความที่ใกล้กล่องเขียนข้อความ เมนูจะถูกตัด" ([วิดีโอ](https://drive.google.com/file/d/1mssiBZdfqt8JmCRh6QWutls6IG_juOjh/view))

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/chat/components/message-item.tsx` (`MessageContextMenu` `absolute right-0 top-[28px]` L585–587, reaction picker pattern L164–172)

**สาเหตุ / บริบทปัจจุบัน:**
`MessageContextMenu` ใช้ `absolute right-0 top-[28px]` เปิดลงล่างเสมอ และไม่ได้ portal → ถูกตัดด้วย `overflow` ของ message list/panel เมื่อข้อความอยู่ใกล้กล่องพิมพ์ (ต่างจาก reaction picker ที่ portal ไป body + flip ขึ้นได้)

**แนวทางแก้:**
ทำแบบเดียวกับ reaction picker — portal เมนูไป `document.body` (`fixed z-[10000]`), คำนวณตำแหน่งจาก `getBoundingClientRect` ของปุ่ม 3 จุด, clamp ให้อยู่ในจอ, flip ขึ้น (bottom-anchored) เมื่อจะล้นขอบล่าง → **reuse pattern เดิม ทำพร้อม #24**

---

<a name="26"></a>
### #26 — ข้อความรูป: ป้าย "Seen" อยู่ผิดตำแหน่ง `Chat · 🟡 Low · Effort S · Conf. med`

**Feedback เดิม:** "กรณีส่งข้อความเป็นรูป Seen อยู่ผิดตำแหน่ง น่าจะต้องอยู่ด้านขวาเหมือนตอนส่งข้อความเป็น Text"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/chat/components/message-item.tsx` (receipt L437–473, AttachmentBlock L478–487)

**สาเหตุ / บริบทปัจจุบัน:**
delivery receipt (Check/CheckCheck + Seen) อยู่ใน body row `flex items-end gap-[8px]` ต่อท้าย content
ข้อความ text ถูกดันไปขวาเพราะ content span มี `flex-1` — แต่รูปล้วน (`content = null`) body row มีแค่ receipt ไม่มี `flex-1` spacer จึงชิดซ้ายและอยู่เหนือรูป (รูปถูก render ใน `AttachmentBlock` แยกด้านล่าง)

**แนวทางแก้:**
กรณีรูปล้วนของ own message จัด receipt ชิดขวา (เพิ่ม `justify-end`/`ml-auto` เมื่อไม่มี content) หรือย้าย receipt ไปท้าย attachment block ให้อยู่มุมขวาเหมือน text — ตรวจไม่ให้กระทบ compact และข้อความของคนอื่น

---

## Setting

<a name="27"></a>
### #27 — หน้า Setting layout เลื่อน/กระเด้ง `Setting · 🟡 Low · Effort S · Conf. med`

**Feedback เดิม:** "ตอน Setting เหมือนว่าตอนลองเซ็ตตัวหน้าจอมันเลื่อน ๆ กระเด้งแปลก ๆ" ([วิดีโอ](https://drive.google.com/file/d/1djw69qEobZJXQPhjapqXg8t0OI5yM9lo/view))

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/profile/hero-profile.tsx` (header `flex flex-wrap ... justify-between`)
- `zyra-app/views/profile/components/profile-form.tsx` (error `<p>` L295–299, L319–323)
- `zyra-app/views/profile/components/profile-sidebar.tsx` (`lg:h-[920px]`)
- `zyra-app/app/globals.css` (~L181–186)

**สาเหตุ / บริบทปัจจุบัน:**
หน้า `/setting` เรนเดอร์ `HeroProfile` (Account Setting) — สาเหตุ jitter:
1. `globals.css` ไม่มี `scrollbar-gutter: stable` → scrollbar โผล่/หายทำให้เนื้อหาขยับแนวนอน
2. header ใช้ `flex flex-wrap` → ปุ่ม Cancel/Save wrap ลงบรรทัดใหม่ตอนจอแคบ → ความสูง header เปลี่ยน; การสลับ view↔edit เปลี่ยนปุ่ม + field ทำให้ความสูงกระโดด
3. `profile-form.tsx` render `<p>` error + ตัวนับอักษรแบบมีเงื่อนไข **โดยไม่จองพื้นที่** → เด้งตอน blur/พิมพ์
4. sidebar `lg:h-[920px]` แต่ main panel `lg:min-h-[920px]` ไม่ match กัน

**แนวทางแก้:**
1. เพิ่ม `scrollbar-gutter: stable both-edges` ที่ `html` ใน `globals.css` (`@layer base`)
2. จองพื้นที่คงที่ให้บรรทัด error + ตัวนับอักษร (container `min-h` เสมอ แล้ว show/hide แค่ข้อความ)
3. header สูงคงที่ (`min-h`) หรือเลี่ยง `flex-wrap` ให้ปุ่มไม่ wrap
4. ปรับ sidebar/main panel ให้ความสูงสอดคล้อง (ใช้ `min-h` ทั้งคู่ + `items-stretch`)

---

## Workspace

<a name="30"></a>
### #30 — เปิด tab sidebar ค้าง ทำให้เปิด popup แก้ชื่อ private zone ไม่ได้ `Workspace · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "ถ้ามีการเปิด tab ตรง Sidebar → popup Edit Workspace Private Zone ไม่เกิดขึ้น"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (`handleCanvasClick` L6614–6641, `anyMapBlockingPanelOpen` L4653–4657, `setPzCardZoneId` L6637, modal render L7854)
- `zyra-app/views/user/virtual-office/components/pz-zone-card.tsx`
- `zyra-app/views/user/virtual-office/components/pz-edit-zone-name-modal.tsx`

**สาเหตุ / บริบทปัจจุบัน:**
popup `PZEditZoneNameModal` เปิดผ่านเมนู `PZZoneCard` เท่านั้น (คลิก private zone บน canvas → `setPzCardZoneId`)
แต่ `handleCanvasClick` มี early-return L6619: `if (anyMapBlockingPanelOpen) return`
โดย `anyMapBlockingPanelOpen = activeTab==="members" || activeTab==="notifications" || chatView==="half" || showHelpCenter`
→ เมื่อเปิด tab/panel ใด ๆ ที่ sidebar คลิกบน zone ถูกกลืน → การ์ดไม่เปิด → เข้าเมนู Edit zone name ไม่ได้

**แนวทางแก้:**
- ย้าย branch private zone (L6632–6641) ให้ทำงาน**ก่อน** early-return หรือผ่อนเงื่อนไขให้คลิก private zone ที่ผู้ใช้เป็นเจ้าของ (`claimsByZone.get(zone.id)`) ยังเปิดการ์ดได้
- ก่อน `setPzCardZoneId` ควรปิด panel พร้อมกัน (`setActiveTab("map")` / `setChatView("closed")` / `setShowHelpCenter(false)`)
- **ทางเลือก UX นิ่งกว่า:** เพิ่มเมนู "Edit zone name" ในส่วน "Private zones" ของ `vo-member-panel.tsx` wire ขึ้นไป `setPzModal("rename")` (ไม่แตะ API — `renameZoneClaim` ผ่าน `/api/user` มีอยู่แล้ว)

---

## Meeting

> ชุด AI100 (renumber #45–#56) — ดู [README.md](README.md) หมายเหตุการจัดหมวด

<a name="50"></a>
### #50 — อยู่ meeting แต่คนอื่นเห็นตัวละครอยู่ข้างนอก / เปิดกล้องคนอื่นไม่เห็น `Meeting · 🔴 High · Effort L · Conf. med`

**Feedback เดิม (AI100 #6):** "อยู่ใน meeting แต่คนอื่นเห็นตัวละครอยู่ข้างนอก เปิดกล้องแต่คนอื่นไม่เห็น คนนั้นเห็นแต่กล้องตัวเอง"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (`getZoneParticipants` L6200–6252, panel wiring L8907)
- `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx` (`TileVideo` L444–480, `selfParticipant` L2406–2419)
- `zyra-app/views/user/virtual-office/components/use-meeting-media.ts` (`attachVideo` L1187–1190)
- `zyra-ws/internal/hub/audio.go` (L73–105) · `room.go` (AOI move/snapshot L795–893)

**สาเหตุ / บริบทปัจจุบัน:**
สถานะการอยู่ในมีทติ้งถูกอนุมานจาก **3 plane คนละแหล่ง**: geometry (tile ของ avatar), media (LiveKit room ตาม `MediaRoomID`), section (DB `member_ids`) · panel + การ attach กล้องขับด้วย **geometry plane ล้วน** — `getZoneParticipants` สร้าง list จาก tile + rect hit-test เท่านั้น ไม่แตะ `MediaRoomID`/`member_ids` · ถ้า peer มี tile ค้าง "นอกห้อง" (เข้าห้องผ่าน deep-link/teleport/spawn หรือข้าม AOI cell) → ไม่ถูกนับใน list → ไม่ mount `TileVideo` → **ไม่ attach กล้องที่ LiveKit subscribe มาแล้ว**; ตัวผู้ publish เห็นแค่ self-tile → "เห็นแต่กล้องตัวเอง" (เสียงมีปัญหาเดียวกันแต่ SFU auto-attach audio ทั้ง room เลยเห็นน้อยกว่า)

**แนวทางแก้:**
ทำ participant list ให้ authoritative จาก **media/section plane** — union `getZoneParticipants(activeZone)` กับ key ของ `memberAudio`/`memberVideo` (มาจาก `broadcastToMediaRoom` ใน `audio.go`) หรือ section `member_ids` · หรือบังคับ position reconcile ให้ peer ตอน `handleMediaRoomEnter` (`audio.go` L87–105) เช่นยิง `force_sync`/neighbour snapshot

> root สาเหตุเดียวกับ [#52](#52) และ [#56](#56) — membership เดาจาก geometry แทน `MediaRoomID`/section

---

<a name="51"></a>
### #51 — Emoji ในแชท meeting กดไม่ได้ `Meeting · 🟠 Medium · Effort S · Conf. high`

**Feedback เดิม (AI100 #7):** "Emoji แชทกดไม่ได้"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx` (composer emoji btn L2274–2292, `toggleEmoji` L2087–2098, portal picker L2293–2307; toolbar variant ที่ถูกต้อง L1360–1378 / L1479–1508)
- `zyra-app/views/user/virtual-office/components/emoji-picker.tsx` (outside-click L36–49)

**สาเหตุ / บริบทปัจจุบัน:**
ปุ่ม emoji ของ composer อยู่ **นอก** `rootRef` ของ picker ที่ `createPortal` ไป `document.body` · picker มี `document` `mousedown` listener (L36–49) ที่เรียก `onClose()` เมื่อคลิกนอก `rootRef` → การกดปุ่ม trigger ถูกนับเป็น outside-click สั่งปิด ขณะที่ `onClick` ของปุ่มก็ run `toggleEmoji` บน interaction เดียวกัน = race เปิด↔ปิดชนกัน ปุ่มเลยเหมือน "กดไม่ติด" (toolbar variant ไม่เป็นเพราะ wrap ปุ่ม+popover ใน ref เดียว)

**แนวทางแก้:**
`emoji-picker.tsx` L36–49 — ยกเว้นปุ่ม trigger จาก outside-click test (รับ `triggerRef`/`ignoreRef` หรือใช้ `event.composedPath()`) หรือทำแบบ toolbar variant คือ wrap trigger+picker ใน ref เดียวแทนการ portal

> คลาสเดียวกับ portal-menu ของแชท [#24](#24)/[#25](#25)

---

<a name="52"></a>
### #52 — ไม่มีโต๊ะ กดออกจาก meeting ไม่มี action `Meeting · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม (AI100 #8):** "เมื่อไม่มีโต๊ะถ้ากดออกจาก meeting ไม่มี action เกิดขึ้น"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (`VOHud onLeaveClick` L8734–8740, `handleLeaveMeetingGoHome` L3908–3918, `closeActiveMeetingZone` L3863–3901, `[activeZone]` teardown effect L6854–7100, section heartbeat L5110–5167)

**สาเหตุ / บริบทปัจจุบัน:**
"โต๊ะ" ในที่นี้คือ private zone ที่ผู้ใช้ claim ไว้ (`myZoneClaim`) · `handleLeaveMeetingGoHome` ทำ `closeActiveMeetingZone()` (section leave + `section_sync` เท่านั้น ไม่ย้าย avatar) แล้วชน `if (!myZoneClaim) return` → **ไม่เดินออก** · เพราะ avatar ยังอยู่ใน meeting rect `activeZone`/`mediaZoneId` จึงไม่ transition → media session ไม่ teardown, panel ค้าง, และ section heartbeat (L5110–5167) re-establish section ที่เพิ่ง leave = คลิกแล้วเหมือนไม่มีอะไรเกิด (กรณีมีโต๊ะจะเดินออก → `onPathEnded` → `settledTile` เปลี่ยน → teardown รัน จึงไม่เจอ)

**แนวทางแก้:**
ที่ `handleLeaveMeetingGoHome` — หลัง `closeActiveMeetingZone()` ให้เดิน avatar ออกไป tile ว่างนอก meeting rect **เสมอ** แม้ไม่มี `myZoneClaim` เพื่อให้ `activeZone`/`mediaZoneId` transition และ teardown เดิมทำงาน · ดีกว่า: decouple การ teardown "ออกจาก meeting" ออกจากการเดิน — null media/section membership ตรง ๆ ตอนกด leave

> root สาเหตุเดียวกับ [#50](#50)/[#56](#56)

---

<a name="54"></a>
### #54 — Request ปิดไมค์ ควรปิดไมค์คนนั้นจริง (ตอนนี้แค่ advisory) `Meeting · 🟠 Medium · Effort L · Conf. high`

**Feedback เดิม (AI100 #10):** "Req ปิดไมค์คือไมค์คนนั้นปิดเลย"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx` (`RequestMediaControls` L971–1009) · `hero-virtual-office.tsx` (`handleRequestMediaOff` L6443–6455)
- `zyra-app/views/user/virtual-office/components/use-meeting-media.ts` (`requestMediaOff` L1142–1149, `acceptMediaRequest` L1154–1161, indicator `forcedMuteBy` L46–49/L663) · `workspace-ws.ts` (L915–916)
- `zyra-ws/internal/hub/audio.go` (`handleMediaRequest` L162–192, `memberAudioState.forcedMuteBy` L29) · `message.go` (`ForcedMuteBy` L1027/L1050, payload L1057/L1164) · `workspace-ws-types.ts` (`forced_mute_by` L352)

**สาเหตุ / บริบทปัจจุบัน:**
flow ปัจจุบันเป็น **advisory ล้วน**: `handleMediaRequest` unicast `MsgMediaRequested` ให้เป้าหมายเท่านั้น ไม่เปลี่ยน state ใด ๆ (header `audio.go` L14–16 ระบุ "advisory only, no force path") → ผู้ถูกขอต้องกด Accept เอง (`acceptMediaRequest` → `toggleMic` ปิดไมค์ตัวเอง) · มี scaffold `forced_mute_by`/`ForcedMuteBy` ครบทั้ง Go และ FE แต่ **ไม่เคยถูก set** (ฝั่ง Go เคลียร์ตอน self-unmute แต่ไม่มีที่ assign)

**แนวทางแก้ (mic เท่านั้น — camera ไม่มี force โดยดีไซน์):**
1. protocol: เพิ่ม `Force bool` ใน `ClientMediaRequestPayload` (`message.go` L1164) + `Forced bool` ใน `MediaRequestedPayload` (L1057)
2. server `handleMediaRequest`: เมื่อ force + `kind=="mic"` set `m.muted=true`/`m.forcedMuteBy=c.UserID` แล้ว **broadcast** `MsgAudioStateUpdate` (`ForcedMuteBy`) + unicast สั่ง target หยุด LiveKit mic (control plane แตะ media plane ไม่ได้)
3. client target: ใน `ws:media:requested`/handler ใหม่ เมื่อ forced → auto `sfu.setMicrophoneEnabled(false)` + `audioMuteChanged(...)` แทนการเด้ง advisory card (indicator UI ต่อ `forcedMuteBy` ไว้แล้ว)

> ต้องตัดสิน policy สิทธิ์ก่อน · ทำคู่/ต่อยอดกับ improvement [#38](improvements.md#38) (mute all)

---

<a name="55"></a>
### #55 — เสียงดีเล: กลับมาแล้วได้ยินเสียงที่เรียกไว้นานแล้ว `Meeting · 🔴 High · Effort M · Conf. med`

**Feedback เดิม (AI100 #11):** "เสียงดีเล มีคนเรียกแก้วนานแล้ว แก้วไม่อยู่ พอกลับมามันได้ยินเสียงเขาเรียกเฉยเลย แต่เขาเรียกไว้นานแล้ว"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/components/sfu-client.ts` (`_onTrackSubscribed` L877–893, `_ensureAudioHost` L1007–1015, `_teardown` L1017–1033, `startAudio` L697–699)
- `zyra-app/views/user/virtual-office/components/use-meeting-media.ts` (`resumeAudio` L456–458, lifecycle effect L373–650, reconnect L581–614)

**สาเหตุ / บริบทปัจจุบัน:**
กรณีเดินออก-กลับเข้าห้องไม่มีปัญหา (`mediaZoneId`→null teardown SFU แล้วสร้างใหม่) · เคสที่เจอคือ **tab-away/กลับมาโดยยังอยู่ห้องเดิม**: `mediaZoneId` ไม่เปลี่ยน SFU ยัง "connected" → ไม่มีอะไร re-establish/flush · ระหว่าง tab hidden/frozen playout + jitter buffer ของ `<audio>` ถูก suspend/queue ไว้ พอกลับมา buffered packets เล่นออกก่อนไล่ทัน live = "ได้ยินเสียงที่เขาเรียกไว้นานแล้ว" · ไม่มี `visibilitychange` handler ที่ไหน (grep = 0); `startAudio()` แค่ปลด autoplay block ไม่ได้ flush · (มีแค่ UI overlay `vo-tab-away-global.tsx`)

**แนวทางแก้:**
เพิ่ม `visibilitychange` handler (ใน `SFUClient` หรือ lifecycle effect ของ `use-meeting-media`) ที่ตอน return-to-visible **flush remote audio ไป live** — detach+reattach remote audio track ที่ subscribe อยู่ (หรือ reset `currentTime` ของ `<audio>` host / re-subscribe) แล้วเรียก `startAudio()` · optional: treat ช่วง hidden นาน ๆ เหมือน reconnect (reuse path `establish()`)

---

<a name="56"></a>
### #56 — อยู่ meeting ดับเบิลคลิกเดินไปหาคนอื่น แต่ยังอยู่ในสนทนาเดิม `Meeting · 🔴 High · Effort M · Conf. med`

**Feedback เดิม (AI100 #12):** "อยู่ใน meeting แล้วดับเบิ้ลคลิกไปหาเท็นนะ คือเอาตัวไปหาเท็น แต่มันยังอยู่ในสนทนา กับมอสกับวาวา"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (`activeZone` จาก `settledTile` L4653–4663, `settledTile` commit ที่ `onPathEnded` L4319–4328, `mediaZoneId` derive L4825–4832)
- `zyra-app/views/user/virtual-office/components/use-meeting-media.ts` (media teardown L618–649)

**สาเหตุ / บริบทปัจจุบัน:**
`activeZone` (→ `mediaZoneId` + section) ผูกกับ `settledTile` ซึ่งสำหรับการเดินแบบ click/double-click "ไปหาคน" จะ commit **แค่ที่ `onPathEnded` ปลายทาง** (จงใจ เพื่อไม่ให้เดินผ่านโซนแล้วเปิด modal) → ระหว่างเดิน media session + section ยัง active ทั้งเส้น · ยิ่งถ้าปลายทาง resolve กลับเข้า meeting rect (เช่นดับเบิลคลิกคนที่ยืนขอบห้อง) หรือ walk ถูก interrupt → `activeZone` ไม่เปลี่ยนเลย teardown ไม่รัน = avatar ออกไปแล้วแต่ media plane ยัง `MediaRoomID`-joined = "ยังอยู่ในสนทนากับคนเดิม" (WASD ไม่เจอเพราะ `onPathEnded` fire ต่อ tile)

**แนวทางแก้:**
ให้การ **"ออก"** จาก media/meeting zone ขับด้วย **live tile** (polled ปัจจุบัน) ไม่ใช่ settled-arrival — คงตรรกะ gate ด้วย `onPathEnded` ไว้สำหรับ **"เข้า"** เท่านั้น · หรือเมื่อ click/goto เริ่มจากในห้องและปลายทางอยู่นอก rect ให้ null membership ทันที (แก้ที่ `settledTile`/`activeZone` derivation L4319–4328/L4653–4663 + `mediaZoneId` L4825–4832)

> root สาเหตุเดียวกับ [#50](#50)/[#52](#52)
