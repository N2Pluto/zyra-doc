# สรุปการแก้บั๊ก/เพิ่มฟีเจอร์ — VO Meeting + Map Editor (2026-07-21)

> รายละเอียดเชิงเทคนิคเต็ม (root cause แบบ line-by-line) อยู่ที่
> `[zyra-doc/issus/vo-meeting-and-editor-issues-2026-07-21-batch2.md](../issus/vo-meeting-and-editor-issues-2026-07-21-batch2.md)`
> ไฟล์นี้เป็นสรุปภาพรวม + list โค้ดที่เปลี่ยนทั้งหมด ให้ดูเร็วๆ ว่าแก้อะไรไปบ้าง

**สถานะรวม:** ทุกข้อผ่าน `tsc --noEmit` + `npx eslint` (0 error) ในทุกรอบที่แก้ — **ยังไม่มีข้อไหน live-test จริงในเบราว์เซอร์** เพราะ `zyra-api` ไม่ได้รันอยู่ในสภาพแวดล้อมนี้ตลอดทั้ง session

---

## 1) Meeting Room — UI/Display


| #   | เรื่อง                                                                      | สิ่งที่แก้                                                                                                                                                              |
| --- | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A1  | Video grid ไม่ responsive ไม่มี paging                                      | เปลี่ยนจาก fixed 3-คอลัมน์ + scroll แนวตั้ง → paginated 2 แถว × 5 คอลัมน์ (10 คน/หน้า), tile ขนาดยืดหดตามพื้นที่จริง, ปุ่ม ◀/▶ เปลี่ยนหน้าเมื่อคนเกิน 10                |
| A2  | ชื่อห้อง "Meeting room" โผล่ทับหน้าจอที่แชร์ตอน fullscreen                  | เพิ่ม guard ไม่ให้ world-space zone label (hover name, active-meeting label) render ขณะ meeting panel กำลัง expand — *ยังไม่ยืนยัน root cause 100%, เป็น defensive fix* |
| A3  | Hover ห้องข้างๆ ทำ video ในห้องปัจจุบันหายหมด                               | แก้ gate การ render panel จาก `!zoneAccessState` (blanket) → เช็คว่า zoneAccessState เป็นห้องเดียวกับ activeZone จริงไหม                                                |
| A4  | ชื่อตัวละครไม่ตรงกับชื่อใน Meeting Display                                  | เอา guard `!charName` ออกจาก effect sync ชื่อจาก DB — sync ทุกครั้งที่โหลด ไม่ใช่แค่ครั้งแรก                                                                            |
| #11 | ตำแหน่ง tile ไม่เรียงตามเลขคิวยกมือ (เลข badge ถูก แต่ตำแหน่งการ์ดสลับมั่ว) | เพิ่ม sort ให้ `otherParticipants` — คนยกมือมาก่อนเสมอ เรียงตามเลขคิวจริง คนไม่ยกมือเรียงลำดับเดิมต่อท้าย                                                               |
| #12 | ยกมือหายทันทีที่เปิดไมค์ (ควรหายตอนพูดจริง)                                 | ย้าย auto-lower-hand จาก "mic เปิดสำเร็จ" ไปฟัง `speakingUserIds` (LiveKit active-speaker detection) แทน — หายเมื่อพูดจริงเท่านั้น                                      |




## 2) Meeting Room — Audio


| #    | เรื่อง                                        | สิ่งที่แก้                                                                                                                                                                                                                                                                                                                                                                                                 |
| ---- | --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| B2   | เสียงพูดเบา + เอียงซ้าย แม้เปิดลำโพง 80%      | บังคับ mic capture เป็น mono (`channelCount: {ideal:1}`) — แก้ bug ที่ noise-gate worklet เขียนแค่ channel ซ้าย ทำให้ channel ขวาเงียบสนิทเมื่อไมค์เป็นอุปกรณ์ stereo                                                                                                                                                                                                                                      |
| B3   | สลับ device mic แล้วพูดไม่ได้ คนอื่นไม่ได้ยิน | เพิ่ม auto-reconnect (`recoverMediaSession`, เดิมชื่อ `recoverCameraSession`) เมื่อสลับ mic ล้มเหลวและ rollback ก็ล้มเหลวด้วย — เดิมไม่มี safety net สำหรับ mic (มีแต่กล้อง)                                                                                                                                                                                                                               |
| B4   | Capture หน้าจอได้ยินเสียงประชุม               | เพิ่ม `restrictOwnAudio`/`systemAudio:"exclude"` ตอนแชร์จอ กันเสียงประชุมของตัวเอง/เสียงระบบเครื่องเดียวกันเข้าไปในแทร็กที่แชร์ (ส่วนโปรแกรม record จอระดับ OS ยังไงก็ได้ยินเสมอ — เป็นข้อจำกัดแพลตฟอร์ม แก้จากเว็บแอปไม่ได้)                                                                                                                                                                              |
| B1   | Noise Reduction "High" ไม่กันเสียงคนข้างๆพูด  | **Research spike** (ไม่ใช่โค้ด): DTLN/ai-coustics ไม่แก้ปัญหานี้ (เป็น noise-suppression เหมือน RNNoise ไม่ใช่ speaker-separation); เจอ **Krisp VIVA "Voice Isolation"** เป็นตัวเดียวที่ทำสิ่งนี้จริง แต่ยังไม่ยืนยัน JS/WASM + ราคา ต้องติดต่อ sales เอง — จากนั้น**tune gate ของ RNNoise "High" ให้เข้มขึ้น**แทน (threshold/holdMs เข้มกว่า Medium) ช่วยได้แค่ช่วงที่หยุดพูด ไม่แก้ "พูดพร้อมกัน" หายขาด |
| #13a | เมนู noise reduction ใหม่                     | แยกเป็น 2 engine: **RNNoise** (Medium/High, ใช้งานได้จริง) + **VoiceFilter** (Medium/High, "coming soon" — กดแล้วขึ้น toast เฉยๆ ยังไม่มี engine จริง)                                                                                                                                                                                                                                                     |




## 3) Map Editor — หลังบ้าน


| #   | เรื่อง                                 | สิ่งที่แก้                                                                                                                 |
| --- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| C1  | Object ล่องหน ต้องออก-เข้า editor ใหม่ | เพิ่ม bounded retry (3 ครั้ง, backoff 0/1s/3s) ตอน preload thumbnail — เดิม retry แค่ 1 ครั้งแล้วเลิกถาวรถ้า network สะดุด |
| C2  | Object วางแล้วไปอยู่หลังกำแพง          | ขยาย toggle "Wall Mounted" ให้ทุก object type (เดิมมีแค่ decoration/machine) — ยกเว้น wall/walkable_group ที่ไม่สมเหตุสมผล |




## 4) ฟีเจอร์ใหม่ — Knock granted → auto-walk ไปนั่ง/ยืน


| #                            | เรื่อง                                                                                   | สิ่งที่แก้                                                                                                                                                                                                                                                                 |
| ---------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| #13b                         | Ask permission ได้รับอนุญาต → เดินไปนั่งเก้าอี้ว่างอัตโนมัติ (ไม่มีเก้าอี้ → ยืนจุดว่าง) | เพิ่ม `isTileWalkable()` บน engine + `findSeatOrStandTile()` helper ใหม่ (หาเก้าอี้ว่างใกล้สุด → ถ้าไม่มีหา tile ว่างใกล้สุด → fallback กึ่งกลางห้อง) ต่อเข้ากับ `knock_granted` handler ทั้ง 2 branch                                                                     |
| **Regression** (พบหลัง #13b) | เดินเข้าไปแล้วเดินออกมาเอง                                                               | เป็น **race condition เดิม** ที่ #13b ทำให้โผล่ (เดินเร็วกว่าเดิมจนถึงก่อน unlock state จะมาทัน) — แก้โดยสลับลำดับใน `handleKnockAllow`: broadcast unlock **ก่อน** ส่ง granted (เดิมสลับกัน) + เพิ่ม zone-containment check ใน `stepAwayFromOccupiedTile` กันหลบออกนอกห้อง |


---



## Code ที่เปลี่ยนแปลงทั้งหมด (by file)



### `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx`

- A1: เพิ่ม `gridPage` state, เปลี่ยน `chunkArray(orderedParticipants, 3)` → paginated 2×5, เพิ่มปุ่ม `ChevronLeft`/`ChevronRight`, `ExpandedDisplayCard` เปลี่ยนจาก fixed `h-[422px]` → `h-full` responsive
- #11: เพิ่ม sort ให้ `otherParticipants` ตาม hand-raise rank



### `zyra-app/views/user/virtual-office/hero-virtual-office.tsx`

- A2: guard `!meetingExpanded` บน world-space zone label 2 จุด
- A3: แก้ gate `!zoneAccessState` → เช็ค zone id ตรงกัน
- A4: เอา guard `!charName` ออกจาก DB-sync effect
- #13b: import `findSeatOrStandTile`, เพิ่ม `pickEntryTile()` ใน `knock_granted` handler ทั้ง 2 branch
- Regression fix: สลับลำดับใน `handleKnockAllow` (grant+sectionSync ก่อน knockDecision), เพิ่ม zone-containment check ใน `stepAwayFromOccupiedTile` (import `zoneContainsTile`)



### `zyra-app/lib/api/sfu-client.ts`

- B2: เพิ่ม `channelCount: {ideal:1}` ใน `audioCaptureDefaults`
- B4: เพิ่ม `restrictOwnAudio`/`systemAudio` ใน `setScreenShareEnabled()` และ `switchScreenShareSource()`



### `zyra-app/views/user/virtual-office/use-meeting-media.ts`

- B3: rename `recoverCameraSession` → `recoverMediaSession`, เพิ่ม auto-reconnect path ใน `selectDevice()` catch handler
- #12: ย้าย auto-lower-hand logic จาก mic-enable handler → effect ใหม่ที่ฟัง `speakingUserIds`



### `zyra-app/lib/api/noise-processors.ts`

- B1 (round 3): แยก `GATE_OPTS` เป็น `MEDIUM_GATE_OPTS`/`HIGH_GATE_OPTS` (High เข้มกว่า)
- #13a: รวม `NoiseGateProcessor`+`RnnoiseProcessor` เป็น class เดียว (`RnnoiseProcessor` รับ gate config เป็น parameter) — ทั้ง Medium และ High รัน RNNoise เหมือนกันแล้ว



### `zyra-app/views/user/virtual-office/components/vo-media-device-menu.tsx`

- #13a: restructure เมนูเป็น Off + กลุ่ม RNNoise (Medium/High) + กลุ่ม VoiceFilter (Medium/High, disabled + toast "coming soon")



### `zyra-app/views/admin/workspace-editor/components/map-editor-canvas.tsx`

- C1: `loadImage()` เพิ่ม bounded retry (3 ครั้ง, backoff 0/1s/3s) พร้อม cleanup flag



### `zyra-app/views/admin/workspace-editor/components/object-context-menu.tsx`

- C2: ขยาย `canWallMount` ให้ทุก type ยกเว้น `wall`/`walkable_group`



### `zyra-app/zyra-engine/types.ts`

- #13b: เพิ่ม `isTileWalkable?` บน `PlayTestHandle`



### `zyra-app/zyra-engine/pixi-game/scene.ts`

- #13b: implement `isTileWalkable()` (อ่านจาก `blockedTiles` ที่มีอยู่แล้ว)



### `zyra-app/components/game-canvas/pixi-canvas.tsx`

- #13b: wire `isTileWalkable` เข้า `PlayTestHandle`



### `zyra-app/views/user/virtual-office/utils/tile-helpers.ts`

- #13b: เพิ่ม `findSeatOrStandTile()` (ใช้ `zoneTileSet`/`zoneCenterPoint` จาก `lib/zone-utils.ts`)



### `zyra-app/messages/en.json` + `zyra-app/messages/th.json`

- B3: เพิ่ม `micReconnectingTitle`/`micReconnectingBody`
- #13a: เปลี่ยน `noiseLow`→`noiseMedium`, เพิ่ม `noiseEngineRnnoise`/`noiseEngineVoicefilter`/`noiseVoicefilterComingSoon`

---

