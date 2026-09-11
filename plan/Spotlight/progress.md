# Spotlight — Progress

> log ต่อรอบ (entry ใหม่ไว้บนสุด) · รูปแบบตาม [zyra-doc/README.md § อัปเดตความคืบหน้า](../../README.md)
> สถานะรวมอยู่ที่ blockquote หัว [spec.md](spec.md) · ความพร้อมของ dependency ดู [spec.md § ความพร้อม](spec.md)

---

## 2026-09-11 · แท่นยืน/ลำแสงลงมาที่เท้า · tooltip + shortcut [B] · หลายคนขึ้น stage พร้อมกัน · cap แชร์จอของ Spotlight

รอบนี้ผู้ใช้แจ้ง 4 เรื่องต่อเนื่องกันจากการเล่นจริง (2 เรื่องแรกเป็นงาน art/UI, 2 เรื่องหลังเป็นบั๊กพฤติกรรม)

### 1. แท่นยืน (pad) และลำแสงของ spotlight ไม่ตรงเท้าตัวละคร — `zyra-engine/pixi-game/scene.ts`

- **อาการ:** ผู้ใช้บอก "แท่นยืนมันอยู่ตรงกลางเกินไป ตอนยืนมันเลยดูเลย ช่วยทำให้มันลงมาอีกนิดแต่อยู่ภายในช่อง แบบตรงเท้าพอดี" แล้วตามด้วย "ไฟที่ฉายลงมา ไม่ทำให้พอดีด้วยหรอ"
- **สาเหตุร่วมของทั้งสองอัน:** art ถูกวางอิงแถวที่อยู่ **สูงกว่าพื้นที่ sprite ยืนจริง 10px** — `playerSprite` anchor `(0.5, 1)` วางที่ `py` และ `py` ของคนที่ยืนอยู่ = จุดกลาง tile + `|PLAYER_FOOT_OFFSET_Y|` (ดู `_snapToSeat`: `this.py = spot.worldY - PLAYER_FOOT_OFFSET_Y`)
  - **pad + sparkle:** เดิม `position.set(cx, cy)` โดย `cy` = จุดกลาง zone แบบเรขาคณิต → เรืองแสงลอยอยู่ระดับสะโพก *ด้านหลัง* ตัวละคร
  - **ลำแสง:** เดิม `beam.position.set(occupant.x, occupant.footY)` แต่ `footY` คือ **แถว hitbox/สำหรับ depth sort** ไม่ใช่พื้นที่ยืน → ลำแสงตัดจบแค่ระดับหน้าแข้ง เท้าหลุดออกนอกแสง
- **แก้:** ย้ายทั้งสองมาอยู่บน "เส้นพื้น" (ground line) เส้นเดียวกัน
  - pad: `cy = Math.min(zone.y + zone.height/2 - PLAYER_FOOT_OFFSET_Y, zone.y + zone.height - padBelowCenter)` — ตัว `Math.min` คือ clamp ตามที่ผู้ใช้สั่งว่า "แต่อยู่ภายในช่องนะ" (ขอบล่างของ art ไม่ล้นออกนอก zone) → stage 2×2 tile ลงมาเต็ม 10px, stage 1×1 clamp ที่ 7.4px แล้วขอบล่าง pad พอดีเส้นล่างของ zone
  - beam: `position.set(occupant.x, occupant.footY - PLAYER_FOOT_OFFSET_Y)` — **เฉพาะตำแหน่ง** ส่วน `zIndex` ยังคิดจาก `footY` เดิม เพื่อไม่ให้ลำดับการวาด (แสงทับ avatar / pad อยู่ใต้ avatar) เปลี่ยน
- **วัดจาก art จริงก่อนแก้ (ไม่ได้เดา):** `Spotlight_yellow_base.gif` 320×320 มี pixel ทึบแถว 200–319 centroid `0.811` → ตรงกับ `SPOTLIGHT_MARKER_PAD_CENTER_Y = 0.8` ที่ใช้เป็น anchor อยู่แล้ว จึงไม่ต้องแตะค่า anchor เลย แก้ที่ตำแหน่งที่วางพอ

### 2. ปุ่ม Stop broadcast: tooltip แบบมี key badge + shortcut [B] — `components/zone-enter-header.tsx`

- **ทำอะไร:** เดิมปุ่มใช้ `title=` ของ browser ซึ่งใส่ badge ไม่ได้ → เปลี่ยนเป็น tooltip ตอน hover/focus ใช้ภาษาภาพเดียวกับ tooltip ของ Room Pet (`PetTooltip`) เพื่อให้ key badge สองที่ในโปรดักต์อ่านเป็นอันเดียวกัน: bubble `#1A1B1E` radius 8 p-8 gap-4 + หัวลูกศรล่างเป็น CSS triangle + `<kbd>` กรอบเขียว `#58D68D`; คง `aria-label` และเพิ่ม `aria-keyshortcuts`
- **[B] กดได้จริง (ผู้ใช้ยืนยันว่าต้องการ):** เดิมทั้งโปรเจกต์ **ไม่มี** shortcut B อยู่เลย (เช็คแล้วไม่ชนกับอะไร) → เพิ่ม `STOP_BROADCAST_SHORTCUT_KEY = "b"` + listener ใน `MeetingToolbar` โดย guard ด้วย `onStopBroadcast` ซึ่งเป็น **จุด mount เดียว** (มีแต่ `vo-spotlight-stage.tsx:382` ที่ส่ง prop นี้ และอยู่หลัง `showControls`) → คนที่ดูอยู่บน listener-only stage กด B ไปปิด broadcast ของคนอื่นไม่ได้; ข้ามการทำงานเมื่อกำลังพิมพ์ (INPUT/TEXTAREA/contentEditable) และเมื่อมี modifier — แบบเดียวกับ handler ของ shortcut `[P]` ที่มีอยู่
- **ขอบเขตตามที่ผู้ใช้เคาะ:** ใส่ให้ **เฉพาะปุ่ม Stop broadcast** ปุ่มอื่นใน toolbar (mic/cam/emoji/ยกมือ) ยังใช้ `title` เดิม

### 3. คนที่ 2 ขึ้น stage แล้วไม่ขึ้น / ขึ้นแค่คนเดียว (บั๊ก — ตรงกับดีไซน์ 2-up "Spotlight 2 │ Viewers 50")

- **ของเดิมที่พร้อมอยู่แล้ว ไม่ต้องทำใหม่:** `zyra-ws` รองรับหลาย speaker ต่อ floor เต็มรูปแบบ (`spotlightFloors[floorID]` เป็น map ของ userID และมี comment ตรง ๆ ว่า "a second speaker joining an ongoing one keeps the id it already has") และ `SpotlightSpeakerGrid` ก็ layout grid หลายคนได้อยู่แล้ว (`columns = ceil(sqrt(n))` → 2 คน = 2 ช่องข้างกัน) — ปัญหาทั้งหมดอยู่ฝั่ง client 3 จุด
- **(ก) stage อ่านแหล่งข้อมูลผิด:** stage ของ presenter list คนจาก **เรขาคณิต tile** (`getAuthoritativeZoneParticipants`) ส่วน stage ของคนดู list จาก **speaker set ของ server** → สองฝั่งไม่มีทางตรงกัน; เรขาคณิตตอบคำถามนี้ไม่ได้ด้วย เพราะ (1) ยืนบน marker ยังไม่ใช่การขึ้นไลฟ์ (ต้องกด Play) และ (2) presenter ตอนอยู่ใน exit-confirm เดินออกจาก marker แล้วแต่ยัง broadcast อยู่
  - **แก้:** ทำ memo เดียว `spotlightStageParticipants` จาก `spotlight.speakers` (`hero-virtual-office.tsx:6949`) แล้วให้ทั้งสองฝั่งอ่านอันเดียวกัน (`spotlightViewerParticipants` กลายเป็น filter ตัวเองออกจากลิสต์นี้) — เลิกใช้ hack ที่ต้องเอา presenter ใส่กลับเข้า list ด้วยมือตอน exit-confirm ไปเลย เพราะ server คงชื่อเขาไว้ใน speaker set อยู่แล้ว
  - **ระวังไว้แล้ว:** ใน memo แยกเคส self ออกมา (ชื่อ = `charName`, รูป = `user.image_upload`) ให้เหมือน branch self ของ `resolveParticipant` — ที่ inline เพราะ helper ตัวนั้นประกาศอยู่ล่างกว่า hook ที่ใช้ลิสต์นี้; คนอื่นยังใช้ `speaker.name` + `member.avatar_url` เหมือนเดิม ไม่เปลี่ยนพฤติกรรมฝั่งคนดู
- **(ข) เดินขึ้น marker ที่มีคนไลฟ์อยู่แล้ว → จอว่างเปล่า:** ทั้ง `deriveShouldListen` และ `spotlightViewerActive` ตัดสิทธิ์คนที่ยืนบน marker ออกจากการเป็นคนดู → B เดินขึ้นไปแล้ว broadcast หายจากจอ ต้องกด Play แบบมองไม่เห็นอะไรเลย
  - **แก้:** เงื่อนไขจริงแคบกว่านั้น — สิ่งที่ต้องห้ามคือ **การ publish เข้าห้องเอง** (สอง LiveKit connection ของ identity เดียวในห้องเดียวกันจะแย่งห้องกัน) ซึ่งผูกกับการกด Play ไม่ใช่การยืนบน tile (ดู `spotlightRoomId` = `onSpotlightStage && spotlightBroadcastRequested`) → เปลี่ยน gate ทั้งสองไปอิง `broadcastRequested` แทน (`deriveShouldListen` รับ arg ใหม่, `hardBlock` แก้คู่กัน)
  - **ผลข้างเคียงที่ดีขึ้น:** ระหว่าง countdown 5 วิ (ยังไม่ set `requestedSpotlightZoneId`) คนกด Play ยังเห็น stage อยู่ แล้วค่อยสลับเป็น stage ของตัวเองตอนไลฟ์จริง; และ B ที่ฟังอยู่จะถูกนับเป็น viewer ในห้อง broadcast ด้วย (เลข Viewers เลยไม่ค้าง 0)
- **(ค) HUD ถูก stage ทับ:** `VOHud` ไม่มี z-index ส่วน stage เป็น `z-50` → ถ้าโชว์ stage ให้ B เฉย ๆ ปุ่ม Play ที่จะพาเขาขึ้นเวทีจะถูกฝังอยู่ข้างใต้ กลายเป็นแย่กว่าเดิม
  - **แก้:** ยกแถว HUD ล่างเป็น `z-[60]` **เฉพาะตอน** `onSpotlightTile && anySpotlightViewerActive && !spotlightViewerPip` — คนดูที่ไม่ได้ยืนบน marker ยังได้ takeover เต็มจอเหมือนเดิม
- **ข้อที่ผู้ใช้เคาะ:** ยืนบน tile **ไม่** ขึ้นไลฟ์อัตโนมัติ — ยังต้องกด Play เหมือนเดิม (ตรงกับ Start UX ที่ยืนยันไว้ใน spec.md) แต่ต้องเห็น stage ระหว่างรอ

### 4. แชร์จอบน stage ได้ทีละ 1 คน + toast ขออนุญาตคนที่แชร์อยู่

- **ของเดิมที่พร้อมอยู่แล้ว:** flow นี้มีครบทั้งเส้นอยู่แล้วจาก SC-RTE-09 ของ meeting — `ws:share:request` / `ws:share:requested` / `ws:share:declined` / `ws:share:request:decline` และ `VOShareRequestNotification` ก็คือ toast ในดีไซน์ที่ผู้ใช้ส่งมาเป๊ะ (avatar + "Request to share screen · right now" + `Keep Sharing` / `Stop Sharing`); `zyra-ws` ก็ cap ห้อง spotlight ไว้ที่ 1 คนอยู่แล้ว (`maxPresentersIn`, `internal/hub/screenshare.go`)
- **บั๊กคือตัวเลขไม่ตรงกันตัวเดียว:** client pre-check ใช้ `MAX_SCREEN_PRESENTERS = 2` แบบ flat → บน stage ที่มีคนแชร์อยู่ 1 คน `others.length (1) >= 2` เป็น false จึงปล่อยให้เปิด picker แล้ว publish ไปเลย แล้วโดน server ปฏิเสธด้วย `ws:share:denied` ขึ้น toast "screen share is full" — **flow ขอสิทธิ์จึงไม่เคยทำงานบน stage เลย**
- **แก้:** เพิ่ม `maxScreenPresentersIn(roomId)` ใน `use-meeting-media.ts` ให้ mirror ฝั่ง server (spotlight = 1, ที่อื่น = 2) และใช้ทั้งที่ pre-check และที่ `ws:share:stopped` (เดิม `presenter_count >= 2` ก็ผิดเกณฑ์ของ stage ด้วย); เพิ่ม `SPOTLIGHT_ROOM_PREFIX` + `isSpotlightRoomId()` ใน `lib/spotlight-feature.ts` เพราะ client ต้องแยกชนิดห้องจาก media-room id อย่างเดียว (`spotlight:<floorId>` vs zone UUID)
- **เช็ค z-order แล้ว:** toast เป็นลูก `z-50` ของ root ส่วน stage อยู่ใน overlay `z-10` → toast วาดทับ stage ได้จริง ไม่ต้องแก้อะไรเพิ่ม
- **ไม่ได้แตะ `vo-spotlight-share-confirm-modal.tsx`:** อันนั้นคือ EC-01 (ขึ้น stage แล้วเสีย share ของตัวเอง) เป็นเรื่องละกันกับ flow ขอสิทธิ์นี้

### verify ถึงไหน

- **test ที่เพิ่ม/แก้:** pad อยู่บนเส้นพื้นและไม่ล้น zone + sparkle ขยับตาม pad, ลำแสงลงบนเส้นพื้น (แก้ assertion เดิมที่ pin ไว้ที่ `footY`), tooltip มี badge `B` และไม่มี `title` ซ้อน, `[B]` ปิด broadcast ได้แต่ไม่ทำงานตอนพิมพ์/มี modifier/บน listener-only stage, stage วาง speaker หลายคนข้างกันและหัวการ์ดนับ 2, `deriveShouldListen` 3 เคสใหม่ (ยืนบน tile ยังไม่กด Play = ฟัง / บน tile + ไลฟ์ = ไม่ฟัง / กด Play แล้วแต่ออกจาก tile = ฟัง), `isSpotlightRoomId`
- **ผล:** targeted Vitest **18 ไฟล์ 541 tests ผ่าน** (ทุกไฟล์ที่ import module ที่แก้), `tsc --noEmit` ไม่มี error ใหม่ (เหลือ 5 ตัวเดิมบน HEAD: `pet-creation-wizard`, `pixi-game-scene`), ESLint 0 error
- **ข้อจำกัดที่ต้องบอกตรง ๆ:** (1) **ยังไม่ได้ live-test 2 client พร้อมกัน** — ข้อ 3 ทั้งหมดอนุมานจากโค้ด + พฤติกรรมของ `zyra-ws` ไม่ใช่จากการเห็นของจริง ควรเปิด 2 browser เช็คก่อนปิดงาน (2) full suite 145 ไฟล์ **รันไม่จบบนเครื่องนี้** — ล้มด้วย `[vitest-pool]: Failed to start forks worker` / `Timeout waiting for worker to respond` ซึ่งเป็น resource exhaustion ของเครื่อง ไม่ใช่ assertion fail จึง verify ด้วยวิธีไล่ไฟล์ที่กระทบแทน

### ยังไม่ได้ทำ / ต้องเคาะ

- **ตัวเลข countdown ใหญ่ถูก stage ทับ:** overlay countdown เป็น `z-30` อยู่ใต้ stage `z-50` → ตอน B กด Play ขณะดู stage อยู่จะไม่เห็นเลข 5 วิตัวใหญ่ (chip "Going live in N" + Cancel ใน HUD ยังเห็นเพราะยกเป็น `z-[60]` แล้ว) — ตั้งใจไม่ยกเพราะเลข 360px ทับ feed สดน่าจะแย่กว่า ถ้าอยากให้เห็นต้องเคาะว่าจะย่อ/ย้ายตำแหน่งอย่างไร
- **ชื่อ speaker บน stage ของคนดู** ยังใช้ `speaker.name` จาก server (ไม่ใช่ `character_name` จาก roster แบบลิสต์อื่นในแอป) — คงไว้เพื่อไม่ขยาย scope รอบนี้ ถ้าต้องการให้ตรงกันทั้งแอปค่อยเคาะแยก
- **ขนาด zone ของ stage จริง:** ข้อ 1 clamp ไว้ให้ทำงานถูกทั้ง 1×1 และ 2×2 แต่ยังไม่ได้ยืนยันว่า zone ที่ผู้ใช้ใช้จริงกว้างพอให้ 2 คนยืนพร้อมกันทางเรขาคณิต — ถ้าเป็น 1×1 คนที่ 2 จะยืนไม่ได้ตั้งแต่ระดับ collision (ไม่เกี่ยวกับที่แก้ไปรอบนี้) ควรเช็คตอน live-test

---

## 2026-09-09 · PiP เห็นจอที่แชร์ + ปุ่ม chat ในหัวการ์ด/mini window

- **PiP ตอนแชร์จอมองไม่เห็น (แก้แล้ว):** รอบก่อนตั้งใจให้ mini window เป็น avatar-only (`sharing = !compact`) ซึ่งผิดความต้องการ — ถ้ามีคนแชร์อยู่ mini window จะแสดง **จอที่แชร์** แทน avatar (`MiniWindowScreen` ใหม่: `<video>` attach จาก `attachScreen`, `object-contain` บนพื้นดำเพื่อไม่ crop จอในการ์ด 340px, ป้ายชื่อพร้อมไอคอน Monitor มุมล่างซ้าย) และ hero ส่ง `screenSharers/screenEpoch/attachScreen/detachScreen` เข้า instance ของ mini window ด้วย (เดิมส่งแค่ instance ของ stage)
- **ปุ่ม chat ตามดีไซน์ (ทำแล้ว):** เพิ่มปุ่ม chat ทั้งหัวการ์ด stage และ title bar ของ mini window ตามที่ดีไซน์วางไว้ (ลำดับ: PiP/expand → chat → stop listening → X)
  - **ไม่ได้สร้าง chat ใหม่:** ตาม spec HP-08 ("Spotlight Chat รวมกับทุกคนใน Workspace") ปุ่มนี้เปิด **workspace chat เดิม** — เลือก conversation ที่ `is_default` จาก chat store แล้วเปิด `ChatSurface` แบบ `half` (reuse ทางเดียวกับที่ Bell เปิดห้องแชท)
  - **เหตุผลที่กด chat แล้วย่อเป็น mini window:** panel แชทแบบ half ถูก dock ซ้ายที่ z-50 และ stage เต็มจอเป็น sibling ที่วาดทับ จึงเปิดพร้อมกันไม่ได้ — กด chat จาก stage เต็มจอจะย่อ broadcast ลง mini window (มุมขวาล่าง) ให้เห็นทั้งแชทและ broadcast พร้อมกัน
- **verify ถึงไหน:** เพิ่ม/แก้ 2 Vitest cases (mini window เรียก `attachScreen` และยังเป็นการ์ด 340px ไม่ใช่ layout side-column; ปุ่ม chat ยิง callback ได้ทั้งจาก stage และ mini window); targeted Vitest 9 ไฟล์ 137 tests ผ่าน, `tsc --noEmit` ไม่มี error ใหม่, ESLint 0 error (เหลือ warning เดิมบน HEAD 1 ตัว), Prettier + `git diff --check` ผ่าน
- **ยังไม่ได้ทำ:** Spotlight chat แบบ thread แยกของตัวเอง (spec HP-08 ระบุว่าใช้ Workspace Chat ร่วมกัน จึงถือว่าเข้าเกณฑ์แล้ว) และการวางแชทไว้ "ด้านขวา" ของ stage ตามข้อความใน spec §HP-03 (ของเรา dock ซ้ายตาม ChatSurface เดิม)

---

## 2026-09-09 · chip หัวการ์ดกดดูรายชื่อได้ + เก็บ eslint error ที่ตกค้าง

- **chevron ใน chip ทำงานจริงแล้ว:** กด chip `Spotlight <n>` หรือ `Viewers <n>` แล้วเปิด dropdown รายชื่อ — reuse `ZoneParticipantsSubmenu` (panel `#242B32` 289px ของ meeting header) ไม่ได้สร้าง component ใหม่; chevron หมุน 180° ตอนเปิด, มี click-away layer แบบเดียวกับ submenu เดิม, เปิดได้ทีละอัน และแต่ละแถวมีปุ่มแชท 1:1 (ต่อกับ `handleOpenDm` เดิม)
- **รายชื่อผู้ชมมาจากไหน:** เพิ่ม `participantIds()` ใน `SFUClient` (local + remote identities ของห้อง) แล้วเปลี่ยน `roomParticipantCount` → **`roomParticipantIds`** ทั้งใน `use-meeting-media.ts` และ `use-spotlight-broadcast.ts`; hero กรอง speaker ออกแล้ว resolve ชื่อ/รูปจาก `allWorkspaceMembers` (`display_name` → `character_name` → `someoneFallback`) เป็น `ZoneParticipant[]` ส่งเข้า stage — prop `viewerCount` เลยถูกแทนด้วย `viewers` (จำนวน = `viewers.length` แหล่งเดียว ไม่มี state ซ้อน)
- **เก็บ eslint error ตกค้าง (จากรอบ confirm dialog):** เดิมใส่ `eslint-disable react-hooks/set-state-in-effect` ไว้ — รอบนี้แก้ที่ต้นเหตุ: ย้าย state `spotlightShareConfirm` ขึ้นไปอยู่กับ state ของการเข้า Spotlight tile แล้วยุบ reset เข้า effect "ออกจาก tile" ที่มีอยู่เดิม จึง **ลบทั้ง effect และ suppression ที่เพิ่มไว้ออก** (สุทธิ: effect น้อยลง 1 อัน, suppression น้อยลง 1 อัน)
- **verify ถึงไหน:** ขยาย test ของหัวการ์ดให้ครอบ dropdown (กดแล้วเห็นรายชื่อ, เปิดอันหนึ่งปิดอีกอัน, ยังไม่กดต้องไม่มีรายชื่อโผล่); targeted Vitest 10 ไฟล์ 105 tests ผ่าน, `tsc --noEmit` ไม่มี error ใหม่, ESLint ของไฟล์ที่แก้ **0 error** (เหลือ warning เดิม 1 ตัวของ `handleSpotlightStopListening` ที่มีอยู่ก่อนแล้วบน HEAD — ไม่แตะเพราะไม่ใช่ของงานนี้), Prettier + `git diff --check` ผ่าน

---

## 2026-09-09 · PiP ของ Spotlight = mini window ลากได้ในหน้า (Figma 5493:904351 / 5491:904215)

- **เปลี่ยนแนวทางจากรอบก่อน:** เดิม PiP ของ Spotlight เปิด **native Document PiP** (`useDocumentPip`) เพราะลากออกนอก browser ได้ แต่ดีไซน์ที่ผู้ใช้ส่ง (`5493:904351`) เป็น **การ์ดลอยในหน้า** วางบนแผนที่และลากไปวางที่ไหนก็ได้ จึงเปลี่ยนมาทำตามดีไซน์และถอด native PiP ของ Spotlight ออก (Outside display ยังใช้ native PiP ของตัวเองอยู่ เพราะจุดประสงค์ของอันนั้นคือให้เห็นตอนสลับแท็บ)
- **สเปกที่ทำตาม (node `5491:904215`):** การ์ด `340×280`, `bg #1A1B1E`, `rounded-16`, `pb-8`, `gap-8`; title bar `bg #242B32` `p-8` มีชื่อ 14/18 medium + ไอคอน 16px สามอัน (full screen / chat / cancel) แบบไม่มีกรอบ; body `px-8` + surface `rgba(255,255,255,0.05)` `rounded-12` `p-4` avatar กลาง 35% ของความสูง + ป้ายชื่อเล็กมุมล่างซ้าย; ตำแหน่งเริ่มต้น `bottom-24 right-64`
- **ลากได้:** drag ที่ title bar ด้วย pointer events + `setPointerCapture`, clamp ไม่ให้หลุดขอบ viewport (เหลือขอบ 8px) และปุ่มบน title bar `stopPropagation` จึงกดได้ไม่ลากการ์ดตาม
- **โครงสร้างที่ปรับ:** `compact` ของ `VOSpotlightStage` เดิมเป็น "การ์ดเล็กในกรอบ stage เดิม" → เปลี่ยนเป็น return `VOSpotlightMiniWindow` ตรง ๆ และล้างเงื่อนไข `compact`/`inPipWindow` ออกจาก markup ของ stage เต็มจอ (prop `inPipWindow` ถูกลบ); avatar ใช้กฎ 35% ของความสูงเหมือนกันทุกขนาดตาม design
- **พฤติกรรมที่ผูกกัน:** กด PiP → ซ่อน stage เต็มจอ เหลือ mini window (เสียงยังทำงาน), กด full screen บน mini window → กลับเป็น stage เต็มจอ, กด X → ซ่อน broadcast รอบนี้เหมือนเดิม; และตอน mini window แสดงอยู่ Meeting panel กลับไปเป็นแถบ compact ปกติด้านบน (ไม่ใช่ companion layout) ตรงตามที่ดีไซน์วาดไว้
- **verify ถึงไหน:** แทน test เดิมของ `inPipWindow` ด้วย case ใหม่ (การ์ด 340×280, ไม่มี viewer counts, title bar เป็น drag handle `cursor-grab`, ปุ่ม expand/close ยิง callback ถูกตัว); targeted Vitest 8 ไฟล์ 93 tests ผ่าน, `tsc --noEmit` ไม่มี error ใหม่, ESLint ของไฟล์ที่แก้ผ่าน (เหลือ warning เดิมของ `handleSpotlightStopListening` ที่มีอยู่ก่อนแล้วบน HEAD), Prettier + `git diff --check` ผ่าน
- **หมายเหตุ trade-off:** mini window แบบในหน้าไม่แสดงเมื่อสลับไปแท็บ/แอปอื่น (ต่างจาก native PiP เดิม) — ถ้าต้องการทั้งสองแบบ ต้องเคาะว่าจะให้ปุ่มไหนทำอะไร; ปุ่มกลางของ title bar ในดีไซน์คือ **chat** แต่ของเรายังเป็น Stop listening เพราะ Spotlight chat ยังไม่ได้ทำ (ค้างเรื่องเดียวกับหัวการ์ด stage)

---

## 2026-09-09 · หัวการ์ด Spotlight: จำนวนคนไลฟ์ + จำนวนผู้ชม (Figma DisplayHead 5469:894550)

- **ทำอะไร:** หัวการ์ดเดิมมี chip เดียว (นับ speaker) เปลี่ยนเป็นสองชุดตาม design: `Spotlight <n>` │ `Viewers <n>` โดย chip ใช้สเปกของ design (`bg rgba(255,255,255,0.05)`, `border rgba(255,255,255,0.2)`, `h-24`, `p-4`, `rounded-6`, icon 16, ตัวเลข 14/18) และเส้นคั่นแนวตั้ง 16px `white/20`; แยกเป็น `StageCountChip` ใน `vo-spotlight-stage.tsx` — คนไลฟ์นับจาก speaker set (floor เดียวไลฟ์พร้อมกันได้หลายคน) ส่วนผู้ชมมาจาก prop ใหม่ `viewerCount`
- **ที่มาของจำนวนผู้ชม (ของจริง ไม่ใช่ค่าปลอม):** เดิมรอบก่อนถอด viewer count ออกเพราะไม่มีแหล่งข้อมูล — รอบนี้ใช้ LiveKit เป็นแหล่ง: ทุกคนที่ต่ออยู่ในห้อง `spotlight:<floorId>` ที่ไม่ใช่ speaker = ผู้ชม
  - เพิ่ม `roomParticipantCount` ใน `use-meeting-media.ts` (sync จาก `sfu.state.participantCount` ตอน connect + event `participantJoined/Left`, reset เป็น 0 ตอน teardown) → ใช้ฝั่ง presenter เพราะ session ของเขาคือห้อง broadcast เอง
  - เพิ่ม `roomParticipantCount` แบบเดียวกันใน `use-spotlight-broadcast.ts` (listener session) → ใช้ฝั่งคนดู/companion
  - hero คำนวณ `max(0, roomParticipantCount - speakers.length)` ทั้งสองเส้นทาง (ผู้ชมนับตัวเองด้วย ซึ่งถูกต้องตามความหมาย "คนที่กำลังดู")
- **ยังไม่ทำ (ไม่ได้สั่ง):** chip ใน design มีลูกศร chevron ซึ่งสื่อว่ากดเพื่อดูรายชื่อคนไลฟ์/คนดู — ยังไม่ทำ dropdown เพราะเป็น flow ใหม่ (จะได้ chevron ที่กดไม่ได้) รอเคาะ; ส่วน §7 ข้อ 13 (นับ pending/hidden/PiP/muted/reconnect อย่างไร) ถือว่าใช้เกณฑ์ "ต่ออยู่ในห้อง broadcast" ไปก่อน
- **verify ถึงไหน:** เพิ่ม 2 Vitest cases (แสดงทั้งสองจำนวน / ยังไม่มีคนดูต้องขึ้น 0 ไม่ใช่ช่องว่าง) และแก้ assertion เดิมที่เคยยืนยันว่าไม่มีคำ `Viewers` ในหัวการ์ด; targeted Vitest 9 ไฟล์ 92 tests ผ่าน, `tsc --noEmit` ไม่มี error ใหม่, ESLint/Prettier/`git diff --check` ผ่าน

---

## 2026-09-09 · Confirm ก่อนขึ้น Stage ตอนกำลังแชร์จอ (EC-01) + toast ตาม Figma

- **ทำอะไร:**
  - `vo-spotlight-share-confirm-modal.tsx` ใหม่: กด Play บน Spotlight tile ขณะที่ตัวเองมี screen share อยู่ → ถามก่อน ตาม EC-01 ข้อ 1-2 (`ยกเลิก` / `ขึ้น Stage และปิด Share`) กด confirm แล้วปิด share ของตัวเองทันที (EC-01 ข้อ 3) แล้วจึงเริ่ม countdown 5 วิเหมือนปกติ; เดินออกจาก tile หรือถูก block ด้วยสถานะ = ยกเลิกคำถามไปด้วย
  - `hero-virtual-office.tsx`: แยก `beginSpotlightCountdown` ออกจาก `handleSpotlightStart` (ตัวหลังเป็นด่านถาม) และย้าย 2 handler ไปไว้หลัง `meetingAudio` เพราะต้องอ่าน `screenOn`
  - Toast ตาม design: ดึง node `5495:911326` มาแล้วพบว่าเป็น toast ของโปรเจกต์อยู่แล้ว (bg `#1A1B1E`, radius 16, p-16, icon box 40px, title bold 14/18, body 14/18, X 16) → ใช้ `zyraToast.warningWithTitle` ทั้งสองกรณี: **title `Screen sharing stopped`** + body ตาม design `Your screen share ended when you joined Spotlight.` สำหรับคนที่ขึ้น Stage เอง และ body ที่ชัดกว่าสำหรับคนที่ถูก Spotlight ของคนอื่นปิด (`shareStoppedBySpotlight`)
- **สิ่งที่พบใน Figma (สำคัญ):** section HP-06 (`5495:907584`) **ไม่มี confirm dialog** ในดีไซน์เลย — ดีไซน์ใช้แค่ toast; confirm มาจาก spec EC-01 (ClickUp) ที่ผู้ใช้สั่งให้ทำเพิ่ม จึงทำตาม shell ของ confirm dialog ที่โปรเจกต์มีอยู่ (`PZUnclaimModal`, Figma 2615:103366) — ถ้าภายหลังมี node ของ dialog นี้ให้เปลี่ยนตามได้
- **จุดที่ยังไม่ตรง design 100%:** สี icon ของ toast — design ใช้ Yellow/500 `#ECC819` บน `rgba(255,212,0,0.1)` ส่วน variant `warning` ของ `lib/toast.tsx` เป็นส้ม `#F6913A` บน `rgba(246,145,58,0.2)`; ไม่เพิ่ม variant ใหม่เพราะเป็น primitive ที่ทุกหน้าใช้ร่วมกัน — รอผู้ใช้/ดีไซน์เคาะว่าจะเพิ่มสีเหลืองเป็น variant ของ design system หรือคงส้ม
- **verify ถึงไหน:** เพิ่ม `__tests__/vo-spotlight-share-confirm.test.tsx` (5 cases: copy ครบ, cancel/confirm/X แยกกันชัด, key ครบทั้ง en/th, และ pin คำในดีไซน์ของ toast); targeted Vitest 10 ไฟล์ 137 tests ผ่าน, `tsc --noEmit` ไม่มี error ใหม่, ESLint/Prettier ผ่าน, `git diff --check` ผ่าน
- **เหลือ:** ยังไม่ได้ live-test (ต้องมี share อยู่จริงแล้วเดินขึ้น Spotlight tile — ในสถาปัตยกรรมปัจจุบันการเดินออกจาก Meeting zone จะสลับ media room และหยุด share ให้ก่อนอยู่แล้ว ดังนั้น dialog จะเจอในกรณีที่ยังอยู่ในห้อง/ยังแชร์อยู่ตอนกด Play เท่านั้น)

---

## 2026-09-09 · Spotlight share screen (presenter + viewer + companion) + precedence เหนือ meeting share

- **ทำไมเดิมแชร์ไม่ได้:** ไม่ใช่บั๊ก — ฟีเจอร์ยังไม่มี. ฝั่ง publish ผ่านอยู่แล้ว (`roomId` ตอนอยู่ Spotlight = `spotlight:<floorId>` และ `ws:room:enter` ตั้ง `MediaRoomID` ให้ ทำให้ `handleShareStart` ผ่านเพราะ `spotlight:*` ไม่ใช่ zone จึง fail open) แต่ (1) `vo-spotlight-stage.tsx` ไม่มีพื้นที่แสดงจอเลย และ (2) listener session ของคนดูต่อเฉพาะ mic/กล้อง ไม่มี `attachScreen` ทั้งคนดูก็ไม่ได้อยู่ใน media room จึงไม่ได้รับ `ws:share:started`
- **Decision ใหม่ (ผู้ใช้เคาะ 2026-09-09, spec §7 ข้อ 10):** Spotlight share **หยุด screen share ของทุก meeting ทั้งเวิร์กสเปซ** (ตาม HP-06 ตรงตัว)
- **ทำอะไร:**
  - `zyra-ws` `screenshare.go`: `handleShareStart` ที่ room เป็น `spotlight:*` เรียก `stopMeetingSharesForSpotlight` ใหม่ → force-stop presenter ของทุก room อื่นในเวิร์กสเปซ (ข้าม room ที่เป็น `spotlight:*` ด้วยกัน) พร้อม reason `spotlight_started`; เก็บรายชื่อเหยื่อใต้ lock แล้วค่อยเรียก `stopShare` (มัน lock เอง)
  - `zyra-app` `use-meeting-media.ts`: handler `ws:share:stopped` ถ้าเป็นตัวเราเองและ reason = `spotlight_started` → unpublish track ของตัวเอง + toast `shareStoppedBySpotlight` (en/th)
  - `zyra-app` `use-spotlight-broadcast.ts`: expose `screenSharerIds` / `screenEpoch` / `attachScreen` / `detachScreen` จาก listener SFU (event `screenTracksChanged`) — คนดูจึงเห็นจอได้โดย **ไม่ต้องแก้ contract ของ zyra-ws เลย**
  - `zyra-app` `vo-spotlight-stage.tsx`: ตาม Figma node `5495:912468` → `get_metadata`/`get_design_context` ได้ layout ตอนแชร์: `Share screen` frame 1320×624 = **Side display 250×576** + gap **8px** + **Share display 1062×624**; แยก presenter surface ออกเป็น component `SpotlightPresenterSurface` (ถือ attach/detach กล้องของตัวเอง) เพื่อ render ได้ทั้งเต็มจอ/คอลัมน์ข้าง/PiP; ตัวเล่นจอ reuse `ScreenShareView variant="expanded"` ที่มีกรอบ `#1A1B1E` + border white/20 + ป้ายชื่อ + ปุ่มซูม `100% − ⎯ +` ตรงตาม design node `I5499:915624;85:28008` อยู่แล้ว; PiP (compact) ตั้งใจไม่สลับไป layout แชร์
  - `hero-virtual-office.tsx`: ส่ง screen props — presenter ใช้จาก `meetingAudio` (session ของตัวเองคือ room spotlight), viewer/companion ใช้จาก `spotlight.*` พร้อม resolve ชื่อจาก roster
- **verify ถึงไหน:** `zyra-ws` เพิ่ม 2 Go tests (`TestSpotlightShareStopsMeetingShares` ครอบ 2 meeting ต่าง floor + ยืนยันว่า Spotlight ของ floor อื่นไม่ถูกแตะ, `TestMeetingShareDoesNotStopOtherShares` เป็น inverse guard) — `go build/vet/test ./...` ผ่าน; `zyra-app` เพิ่ม 3 Vitest cases ของ share layout (side column + attachScreen ถูกเรียก, ไม่มีคนแชร์ = layout เดิม, PiP ไม่ takeover) — targeted 8 ไฟล์ 80 tests ผ่าน, `tsc --noEmit` ไม่มี error ใหม่, ESLint/Prettier/i18n parity ผ่าน, `git diff --check` ผ่านทั้งสอง repo
- **ข้อจำกัด/ยังไม่ทำ:** precedence ทำงานภายใน Room ของ zyra-ws instance เดียว (ถ้า scale หลาย instance ต้อง relay ผ่าน Redis เพิ่ม); ยังไม่มีปุ่ม/ป้ายเตือนก่อนขึ้น Stage ว่า meeting share จะถูกปิด (HP-06 ข้อ 1-2 confirm dialog) และยังไม่ได้ทำ Spotlight chat ที่ design มีปุ่มไว้; ยังไม่ได้ live-test สอง browser

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
