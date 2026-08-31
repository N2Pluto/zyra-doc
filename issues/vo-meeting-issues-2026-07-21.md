# VO Meeting — Issues & Requests (รายงาน 21 ก.ค. 2026)

> **สถานะ:** ข้อ 1, 2, 3, 4, 6, 7, 8, 9 แก้แล้ว (ดูรายละเอียดแต่ละข้อด้านล่าง) — ยังไม่ได้ live-test บน production/network จริงในทุกข้อ, ข้อ 5 ตรวจสอบ static code แล้วไม่พบ defect ยังต้องการ live repro ก่อนแก้เพิ่ม
> รายงานโดย: ten_dev@hpktechnology.com
> ขอบเขต: ฟีเจอร์ Meeting ใน Virtual Office (`zyra-app/views/user/virtual-office/`)

---

## 1. (Bug) เปิดกล้องไม่ติด ต้องออกห้อง Meeting แล้วเข้าใหม่

**คำอธิบายภาษาชาวบ้าน:** มีคนเปิดกล้องในห้อง Meeting แล้วภาพไม่ขึ้น ต้องออกจากห้องแล้วเข้าใหม่ถึงจะใช้งานได้

> ✅ **แก้แล้ว (2026-07-21)** — ดู Root Cause & Fix ด้านล่าง

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- จุดที่เกี่ยวข้อง: `toggleCamera()` และ camera pre-warm ใน [`use-meeting-media.ts`](../../zyra-app/views/user/virtual-office/use-meeting-media.ts) (`sfu.setCameraEnabled`, `CameraPermissionDeniedError` handling ~L519, ~L832-882)
- ต้อง repro ก่อนว่าเป็น (a) `getUserMedia`/permission race ตอน publish track ครั้งแรก, (b) LiveKit track publish สำเร็จฝั่ง client แต่ subscribe ฝั่ง peer อื่นไม่ทำงาน (SFU/room state), หรือ (c) toggle guard (debounce < 200ms ที่ comment บอกไว้ที่บรรทัด 13) กันการ retry หลัง fail แรก
- สิ่งที่ยังไม่รู้: error ที่ throw ตอนนั้นคืออะไร (ดู `describeMediaToggleError`, ~L197) — ต้องขอ console log จริงจาก user ครั้งถัดไปที่เกิด
- ทำไมออก-เข้าใหม่ถึงแก้ได้: บ่งชี้ว่าเป็น stale local state/track ไม่ใช่ permission จริง (permission denied จะไม่หายด้วยการ rejoin)

**✅ Root Cause & Fix:**

Root cause (จาก source-level analysis ของ `livekit-client@2.20.1`, ยังไม่ได้ live-repro เพราะเป็น device/driver-level race ที่ trigger ตามใจไม่ได้): `LocalParticipant.setTrackEnabled()` เก็บสถานะ "กำลัง publish อยู่" ต่อ `Track.Source` ไว้ใน `pendingPublishing` (Set ภายใน, private) — ถูกลบออกก็ต่อเมื่อ promise ของการ acquire (`createTracks()` → `getUserMedia`) settle (resolve/reject) เท่านั้น ถ้า OS/driver ของกล้องทำให้ `getUserMedia` **ค้างไม่ resolve ไม่ reject เลย** (พบได้บนกล้องบางรุ่นหลัง re-acquire ถี่ๆ) — ทุกครั้งที่เรียก `setCameraEnabled(true)` ซ้ำในเซสชันเดิมหลังจากนั้น จะเข้า branch "already pending" ที่แค่ poll `pendingPublishPromises` นาน 10 วินาทีแล้ว **resolve เงียบๆ โดยไม่มี error** (ไม่มี track ใหม่, ไม่มี publish, ไม่มี exception) — กล้องเลย "ไม่ติด" แบบไม่มี error ใดๆ ให้เห็นเลย ทางแก้เดียวคือออกจากห้องแล้วเข้าใหม่ (สร้าง `Room`/`LocalParticipant` ใหม่ = `pendingPublishing` ว่างใหม่)

Fix (2 ไฟล์):
1. `zyra-app/lib/api/sfu-client.ts` — เพิ่ม `CameraTimeoutError` + wrap การเรียก `room.localParticipant.setCameraEnabled(true)` ด้วย timeout 8 วินาที (`withTimeout()`) ทั้งใน attempt แรกและ retry-branch (device-open-error). ถ้าค้างเกิน 8 วินาที จะ throw `CameraTimeoutError` แทนที่จะเงียบ — ทำให้ caller เห็น error จริงเป็นครั้งแรก
2. `zyra-app/views/user/virtual-office/use-meeting-media.ts` — `toggleCamera()` เพิ่ม branch จับ `CameraTimeoutError` โดยเฉพาะ: แสดง toast "Reconnecting camera" แล้วเรียก `recoverCameraSession()` ซึ่งทำ `sfu.disconnect()` + re-run `establish()` (เก็บ `establish` ไว้ใน `establishRef` จาก lifecycle effect) — เป็นการ **automate สิ่งที่ user ทำเองตอนนี้ (ออกห้อง+เข้าใหม่)** โดยไม่ต้อง manual — เพราะ `sfu.disconnect()` เรียก `_teardown()` ที่ `removeAllListeners()` ก่อนเสมอ การ disconnect แบบตั้งใจนี้จึงไม่ trigger `scheduleReconnect` ซ้อน (ตรวจสอบแล้วว่าไม่มี race)
- `camOnRef`/`camOn` **ไม่ถูกรีเซ็ตเป็น false** ในกรณี timeout — คงค่า "ต้องการเปิด" ไว้ ให้ `establish()` (ที่อ่าน `camOnRef.current`) ลองเปิดกล้องอีกครั้งบน room connection ใหม่โดยอัตโนมัติ
- เพิ่ม i18n keys `camReconnectingTitle` / `camReconnectingBody` (en + th)

**Verify:** `npx tsc --noEmit` ผ่าน, `npx eslint` ผ่าน (0 errors), dev server compile สะอาด ไม่มี console error — **ยังไม่ได้ live-test เส้นทาง timeout/recovery จริง** เพราะต้อง reproduce getUserMedia ค้างจริง (device/driver-level) ซึ่งไม่สามารถ trigger ได้ตามใจในสภาพแวดล้อม dev ปกติ — ถ้าเกิดซ้ำอีกควรเช็ค console หา log `[sfu] camera enable timed out after 8000 ms` เพื่อยืนยัน root cause นี้ตรงหรือไม่

---

## 2. (Bug) กดใส่เบลอกล้อง แล้วหน้าจอค้าง (Chrome ขึ้น "หน้าเว็บไม่ตอบสนอง")

**คำอธิบายภาษาชาวบ้าน:** ลองกดเลือกเบลอพื้นหลังกล้อง แล้วหน้าจอค้างทำอะไรไม่ได้ Chrome ให้เลือกรอ หรือปิดแท็บ

> ✅ **แก้แล้ว (2026-07-21)** — ดู Root Cause & Fix ด้านล่าง

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- ฟีเจอร์นี้คือ [[vo-camera-background-effects]] — `applyBackgroundEffect()` ใน [`lib/api/video-background.ts`](../../zyra-app/lib/api/video-background.ts) เรียกใช้ `@livekit/track-processors` (MediaPipe selfie segmentation, self-host ที่ `public/mediapipe`)
- Hypothesis ที่น่าจะเป็นไปได้ที่สุด: `isBackgroundEffectSupported()` (video-background.ts:75) เช็ค `MediaStreamTrackGenerator`/`MediaStreamTrackProcessor` ก่อน แต่ Chrome เวอร์ชันใหม่ๆ ไม่ expose API นี้บน main thread แล้ว จึง fallback ไปที่ `canvas.captureStream()` — เส้นทาง fallback นี้ทำ WebGL2 segmentation compositing **บน main thread** (ไม่ใช่ Worker) ซึ่งอาจ block UI thread หนักตอนโหลด/รัน MediaPipe model ครั้งแรก (`BackgroundProcessor(...)` + `track.setProcessor()`, ~L139-141) → ตรงกับอาการ "ค้าง" ที่ user เจอ
- ยังไม่ยืนยัน — ต้อง repro บน Chrome เวอร์ชัน/เครื่องเดียวกับ user จริง แล้วเปิด Performance tab เช็คว่า main thread block นานแค่ไหนตอนกด blur
- จุดที่ควรดูเพิ่ม: `vo-background-effects-modal.tsx` เรียก `applyBackgroundEffect` แบบ awaited ใน effect (~L178, ~L207) — ถ้า promise ค้างนาน UI ทั้ง modal จะดูเหมือนแข็ง แม้จริงๆ ไม่ได้ infinite-loop

**✅ Root Cause & Fix:**

Root cause (จาก source-level analysis ของ `@livekit/track-processors@0.7.2`'s compiled `dist/index.mjs`, ยังไม่ได้ live-repro บนเครื่อง/Chrome ของ user จริง): ยืนยันแล้วว่าเส้นทาง fallback (`ProcessorWrapper.initFallbackPath()`) ขับ MediaPipe segmentation ผ่าน `requestAnimationFrame` loop (`startRenderLoop()`) ที่เรียก `this.transformer.transform(frame, controller)` **โดยไม่ await** ก่อน schedule เฟรมถัดไป — ต่างจาก modern stream path (`MediaStreamTrackProcessor`/`MediaStreamTrackGenerator`) ที่ serialize ด้วย Streams API backpressure โดยธรรมชาติ ผลคือถ้าเฟรมใดเฟรมหนึ่งประมวลผลช้ากว่า frame budget (default 30fps = 33ms/เฟรม) — เช่น ตอน cold-start ของ GPU delegate ครั้งแรกที่กด blur, การ์ดจอ/driver ที่ช้า, หรือเครื่องที่ไม่แรง — จะเกิดการเรียก `imageSegmenter.segmentForVideo()` **ซ้อนกัน (concurrent)** บน instance เดียวกัน ซึ่ง MediaPipe's `ImageSegmenter` ไม่ได้ออกแบบให้ reentrant → มีโอกาสสูงที่จะทำให้ WASM/GPU pipeline ค้าง (main thread ถูก pin จนเกิด "หน้าเว็บไม่ตอบสนอง" ของ Chrome) ตรงกับอาการที่ user รายงาน

Fix (`zyra-app/lib/api/video-background.ts`) — ปรับ parameter ที่เราควบคุมได้จากฝั่งเรา (แก้ vendored package ใน node_modules ไม่ได้):
1. เพิ่ม `maxFps: 15` (ค่า default ของ package คือ 30) ให้กับ `BackgroundProcessor({...})` ตอนสร้าง processor ครั้งแรก — ขยาย frame budget จาก 33ms เป็น ~67ms ต่อเฟรม ลดโอกาสที่เฟรมถัดไปจะ fire ก่อนเฟรมก่อนหน้าประมวลผลเสร็จ (ยังไม่ใช่การป้องกัน 100% เพราะ reentrancy guard อยู่ใน vendored code ที่แก้ไม่ได้ — เป็นการลด "โอกาสชน" ไม่ใช่ปิดช่องโหว่ทั้งหมด) — 15fps ไม่กระทบการรับรู้ของ background effect (Zoom/Meet ก็รันที่ framerate ต่ำระดับนี้)
2. เพิ่ม `onFrameProcessed` callback ที่ warn (throttled ทุก 5 วิ) เมื่อเฟรมใดใช้เวลาประมวลผล > 250ms — เพื่อให้ครั้งถัดไปที่เกิดปัญหา มี log ที่เป็นตัวเลขจริง (`[video-background] slow segmentation frame: Xms`) แทนที่จะต้องพึ่ง DevTools Performance capture สด

**Verify:** `npx tsc --noEmit` ไม่มี error ใหม่จากไฟล์นี้ (พบ 4 error ที่**ไม่เกี่ยวข้อง**ใน `zone-enter-panel.tsx`/`hero-virtual-office.tsx` — เป็นงาน WIP ค้างอยู่ก่อนหน้านี้ในเครื่อง เกี่ยวกับ meeting-chat-reaction feature ที่ยังไม่เสร็จ ไม่ใช่จากการแก้ครั้งนี้), `npx eslint lib/api/video-background.ts` ผ่าน 0 error, dev server compile สะอาด ไม่มี console error — **ยังไม่ได้ live-test การกด blur จริงบนเครื่อง/Chrome ที่ freeze** เพราะต้องใช้ webcam จริง + Chrome build ที่ตกอยู่ใน fallback path เดียวกับ user ถ้าเกิดซ้ำอีกควรเช็ค console หา log `[video-background] slow segmentation frame:` เพื่อยืนยันว่า root cause นี้ตรงหรือไม่ ถ้ายังค้างอยู่แม้ลด fps แล้ว ควรพิจารณาทางเลือกที่กว้างกว่านี้ (เช่น ปิด background-effect บน browser ที่ใช้ fallback path เท่านั้น — เป็น scope ที่ใหญ่กว่าเพราะตัดฟีเจอร์ออกจาก user บางกลุ่ม ต้องคุยกับ user ก่อน)

---

## 3. (Feature Request) เมื่อมีคนแชร์จอ อยากให้ทุกคนเข้า Full-screen อัตโนมัติ

**คำอธิบายภาษาชาวบ้าน:** ตอนนี้เมื่อมีคนแชร์หน้าจอ คนอื่นในห้องยังไม่ auto เข้าสู่โหมด full-screen ที่แสดงจอที่แชร์ — อยากให้ทุกคนถูกพาเข้า full-screen ทันทีที่คนแรกเริ่มแชร์

> ✅ **แก้แล้ว (2026-07-21)** — ดู Root Cause & Fix ด้านล่าง

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- เกี่ยวข้องกับ [[screen-share-livekit-only]] — media ผ่าน LiveKit track, presenter guard สูงสุด 2 คนผ่าน `ws:share:*` ใน zyra-ws
- ต้อง clarify ก่อน implement (ตาม [[no-overreach]] policy):
  1. "full-screen" หมายถึง browser Fullscreen API จริง (`requestFullscreen()`) หรือ full-screen แบบ in-app overlay (เต็ม viewport แต่ไม่ใช่ browser fullscreen)?
  2. ทุกคนแปลว่า auto โดยไม่ต้อง confirm เลยใช่ไหม หรือควรมี toast/prompt ให้กดเข้า full-screen เอง (เบราว์เซอร์บาง engine บล็อก auto-fullscreen ที่ไม่ได้มาจาก user gesture)?
  3. คนที่กำลังโฟกัสหน้าต่างอื่นอยู่ (เช่นเปิด profile modal) ควร force ปิดแล้วเข้า full-screen ด้วยไหม?
- ไฟล์ที่เกี่ยวข้องน่าจะเป็น `vo-screen-share-menu.tsx`, `zone-enter-panel.tsx`, และ media state ใน `use-meeting-media.ts`

**คำตอบจาก user (2026-07-21):**
1. "Full-screen" = เหมือนกับตอนกดปุ่มขยาย (expand) ที่มุมขวาบนของ panel อยู่แล้ว — คือ in-app overlay เต็ม viewport (`ZoneEnterPanel`'s `isExpanded`/`meetingExpanded`) ไม่ใช่ browser Fullscreen API
2. Auto ทันทีไม่ต้อง confirm

**✅ Fix (`zyra-app/views/user/virtual-office/hero-virtual-office.tsx`):**
- มี effect ที่มีอยู่แล้วชื่อ "Screen-share start chime" (~L4617) ที่ track `meetingAudio.screenSharerIds` แบบ baseline เพื่อเล่นเสียงแจ้งเตือนตอนมีคนแชร์จอใหม่ — ใช้ pattern เดียวกันสร้าง effect ใหม่ต่อท้าย: track ว่า `screenSharerIds.size` เปลี่ยนจาก **0 → มากกว่า 0** (baseline-tracked เหมือนกัน กันไม่ให้ join ห้องที่แชร์อยู่แล้วโดน force-expand, และกันไม่ให้ presenter คนที่ 2 join ซ้ำ trigger ซ้ำ)
- เมื่อ trigger: เรียก `setMeetingExpanded(true)` + `setActiveTab("map")` + `setChatView("closed")` + `setShowProfilePanel(false)` — mirror พฤติกรรมเดียวกับตอนกด expand ปุ่มเอง (`onExpandChange(true)`)
- ครอบคลุมทั้ง**ตัว presenter เองด้วย** (ต่างจาก chime ที่ตั้งใจ exclude ตัวเอง) เพราะ user ระบุว่าอยากให้ "ทุกคน" เข้า full-screen

**Verify:** `npx tsc --noEmit` และ `npx eslint` ผ่าน 0 error, dev server compile สะอาด — **ยังไม่ได้ live-test จริงกับ 2+ ผู้ใช้** (ต้องมี full stack + คนแชร์จอจริงเพื่อยืนยันว่า effect trigger ถูกจังหวะ)

---

## 4. (Feature Request) ปรับ Quality Selection ตอนแชร์จอ — auto ตามเครื่อง หรือ fix สูงสุดตาม internet

**คำอธิบายภาษาชาวบ้าน:** ตอนแชร์จอ อยากให้ระบบเลือกคุณภาพให้เองตามความเหมาะสมของเครื่อง (ไม่อยากมีตัวเลือกให้กดเยอะ) หรือถ้าจะให้เลือก ก็ fix ไว้ที่คุณภาพสูงสุดแล้วปรับตาม internet แทน

> ✅ **แก้แล้ว (2026-07-21)** — ดู Root Cause & Fix ด้านล่าง

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- ของเดิมมีอยู่แล้ว: `screen-share-quality-modal.tsx` (ลบไปแล้ว — ดู fix ด้านล่าง) ให้เลือก 5 ตัวเลือก (`720p30` default, `720p60`, `1080p15`, `1080p30`, `1080p60`) — ตรงกับ [[screen-share-livekit-only]] ที่บอกไว้ว่า preset ปัจจุบันคือ 720p30 fix
- User อยากได้ 2 ทางเลือก (ต้องถามว่าเอาทางไหน ไม่ใช่ทำทั้งคู่):
  - **(a) Auto-detect ตามเครื่อง**: เลือก quality ให้เองจาก device capability (เช่น CPU core count, `navigator.hardwareConcurrency`, หรือ encoder capability ผ่าน `RTCRtpSender.getCapabilities`) — ไม่โชว์ modal เลือกเยอะๆ ให้ user
  - **(b) Fix ที่สูงสุด + ปรับตาม network**: เริ่มที่ 1080p60 แล้วใช้ LiveKit adaptive stream / simulcast หรือ bandwidth estimation ปรับ resolution/fps ลงเองตาม connection (LiveKit รองรับ `VideoPreset` + adaptive stream อยู่แล้วในระดับ SDK)
- ทั้งสองทางเปลี่ยน UX จากปัจจุบัน (modal เลือก quality ก่อนแชร์) เป็น auto ล้วน — กระทบ `vo-screen-share-menu.tsx` และ flow เรียก `sfu-client.ts` (`ScreenShareQuality` type)

**คำตอบจาก user (2026-07-21):** เลือก (b) Fix สูงสุด + adaptive ตาม network, เก็บ manual quality picker ไว้เป็น advanced option (ไม่ยกเลิกไปเลย)

**✅ Fix:**
- ค้นพบว่า `VOScreenShareMenu` (`components/vo-screen-share-menu.tsx`) มี "Change quality" submenu (5 ตัวเลือกเดิมครบ) อยู่แล้วสำหรับตอน **กำลังแชร์อยู่** — นี่คือ "advanced option" ที่ user อยากเก็บไว้พอดี ไม่ต้องสร้างใหม่
- ยืนยันจาก `screenQualityProfile()` ใน `sfu-client.ts` ว่า preset `1080p60` ใช้ `degradationPreference: "maintain-framerate"` อยู่แล้ว (WebRTC congestion control จะลด **resolution** ลงอัตโนมัติเมื่อ bandwidth ไม่พอ แทนที่จะลด framerate) — ตรงกับ "fix สูงสุด + ปรับตาม network" ที่ user ขอเป๊ะ ไม่ต้องแก้ `sfu-client.ts` เพิ่ม
- `use-meeting-media.ts`: เพิ่ม `DEFAULT_SCREEN_SHARE_QUALITY = "1080p60"`, เปลี่ยน `startScreenShare(quality?: ScreenShareQuality)` ให้ default เป็นค่านี้เมื่อไม่ได้ระบุ
- `hero-virtual-office.tsx`: `handleScreenToggle` เปลี่ยนจากเปิด modal ก่อนแชร์ → เรียก `meetingAudio.startScreenShare()` ตรงๆ (skip การถามคุณภาพก่อนแชร์)
- **ลบไฟล์ `screen-share-quality-modal.tsx`** ทิ้งทั้งหมด (ไม่มีจุดเรียกใช้เหลือแล้ว) + ลบ i18n keys ที่ใช้เฉพาะ modal นี้ (`shareScreenTitle`, `shareScreenModalSubtitle`, `qualityDefaultBadge`, `qualityModalHint*` × 5) ออกจาก `messages/en.json`/`th.json` — keys ที่ share กับ `VOScreenShareMenu` (`qualityTitle*`, `qualityMenuHint*`) เก็บไว้ตามเดิม

**Verify:** `npx tsc --noEmit` และ `npx eslint` ผ่าน 0 error, ยืนยันไม่มีจุดอ้างอิงถึง modal ที่ลบเหลืออยู่ (`grep` ทั้ง repo), dev server compile สะอาด — **ยังไม่ได้ live-test การแชร์จอจริงบน network ที่แย่** เพื่อยืนยันว่า resolution ลดลงจริงตามที่ `degradationPreference` ตั้งไว้

---

## 5. (Bug) ลำดับคิวยกมือไม่เลื่อนเมื่อคนข้างหน้าพูด/วางมือ

**คำอธิบายภาษาชาวบ้าน:**
- ตอนยกมือ ยังไม่มีการเรียงลำดับคนยกมือ 1, 2, 3, 4, 5 ต่อเนื่องกันไปเรื่อยๆ ให้ถูกต้องเสมอ
- เวลากดยกมือ ลำดับไม่เลื่อนตามเมื่อคนข้างหน้าออกจากคิว เช่น A กด = คนที่ 1, B กด = คนที่ 2, V กด = คนที่ 3 — เมื่อ A เปิดไมค์พูด ตัวเลขคิวของ A ไม่หายไป (ทั้งที่ควรจะลดคิวลง แล้ว B เลื่อนขึ้นมาเป็นคนที่ 1)
- แนบภาพหน้าจอ: เห็น tile "n5" กับ badge "✋2" และ "Ponlawat Lueakaew" กับ badge "✋1" (คนละ tile, มี mic ปิดอยู่ทั้งคู่) — ยืนยันว่า badge ตัวเลขแสดงอยู่จริงในสถานการณ์นี้

**ขยายความเชิงเทคนิค (สำหรับ AI):**

Server (`zyra-ws/internal/hub/audio.go`):
- `handleHandChanged()` (~L227-266): ทุกครั้งที่ raise, เพิ่ม `st.nextHandSeq` (ตัวนับ monotonic ต่อห้อง, ไม่รีเซ็ต) แล้ว assign เป็น `m.handSeq` ของคนนั้น — เป็น **"เลขบัตรคิว" ที่ออกครั้งเดียวตอน raise** ไม่ใช่ "อันดับปัจจุบันในคิว" เมื่อ lower, `m.handSeq = 0` และ broadcast `Raised:false` — แต่ไม่มีการ re-broadcast/recompute handSeq ของคนอื่นที่เหลือในคิว (ออกแบบมาให้ client คำนวณ rank เองจากชุด raw seq ที่เหลือ)
- `HandStateUpdatePayload` broadcast ผ่าน `broadcastToMediaRoom(msg, "", roomID)` — `excludeUserID=""` หมายถึงส่งถึงทุกคนรวมทั้งผู้ส่งเอง ดังนั้น propagation ของ WS message เองไม่น่าจะเป็นปัญหาถ้า message ถูกส่งจริง

Client (`zyra-app/views/user/virtual-office/`):
- `use-meeting-media.ts`: `memberHands: Map<string, number>` เก็บ raw `hand_seq` เฉพาะคนที่ **ยังยกมืออยู่** (บรรทัด `ws:hand:stateUpdate` handler — `if (p.raised) next.set(...) else next.delete(...)`) — คนที่วางมือแล้วจะถูกลบออกจาก map ไปเลย ไม่ใช่แค่ set เป็น 0
- `components/zone-enter-panel.tsx` (`handQueue`/`handNumberOf`, ~L2143-2149): recompute rank เอง — sort `memberHands` ascending ตาม raw seq แล้วใช้ index+1 เป็นเลขที่โชว์บน badge ✅ **ตรรกะนี้ตรวจสอบแล้วว่าถูกต้อง** — ถ้า A ถูกลบออกจาก map จริง B/V ควรขยับเป็น 1/2 ทันที (dense rank ไม่ใช่ raw ticket)
- **จุดที่น่าสงสัยที่สุด**: auto-lower-hand-on-speak — `use-meeting-media.ts` `toggleMic()` success handler (`if (live && handRaisedRef.current) { setHandRaised(false); getWsClient()?.handChanged(zoneId, false) }`) มีอยู่แล้ว แต่ต่อกับ **เฉพาะ manual mic toggle path (`toggleMic()`) เท่านั้น** — ยังไม่ตรวจสอบว่า path อื่นที่ทำให้ mic live (เช่น reconnect, pre-warm) มีการ auto-lower ด้วยหรือเปล่า (ไม่น่าเกี่ยวกับ repro ที่ user อธิบายซึ่งเป็นการกด mic ตรงๆ)
- ยังไม่ยืนยัน (ต้อง repro จริงพร้อมเปิด Network tab ดู WS frame `ws:hand:changed`/`ws:hand:stateUpdate`): (a) `handChanged(zoneId, false)` ถูกส่งจริงไหมตอน A unmute, (b) ถ้าส่งแล้ว broadcast ไปถึง client อื่นไหม (ควรถึงเพราะ exclude ว่าง), (c) หรือปัญหาจริงๆ อยู่ที่ระยะเวลาหน่วง (WS round-trip) ที่ user เข้าใจผิดว่าเป็นบั๊กถาวร

**🔍 การตรวจสอบเพิ่มเติม (2026-07-21, ยังไม่ได้แก้):**

Trace ทั้ง chain ด้วยตัวเลขจริง (A raise=1, B raise=2, V raise=3 → A unmute):
1. `toggleMic()` (`use-meeting-media.ts`): `next=true` → `sfu.setMicrophoneEnabled(true).then(() => { live=true; if (live && handRaisedRef.current) { setHandRaised(false); handChanged(zoneId, false) } })` — เงื่อนไขนี้ควร true ถ้า A เคยยกมือไว้จริงและ handRaisedRef sync ทัน (เป็น user action ปกติ ไม่ใช่ double-click เร็วๆ ที่จะทำให้ ref stale)
2. Server `handleHandChanged()`: set `m.handSeq=0`, broadcast `{user_id:A, raised:false, hand_seq:0}` ผ่าน `broadcastToMediaRoom(msg, "", roomID)` — ส่งถึงทุกคนรวม sender เอง
3. ทุก client's `ws:hand:stateUpdate` handler: `raised=false` → `memberHands.delete(A)` → map เหลือ `{B:2, V:3}`
4. `zone-enter-panel.tsx`'s `handQueue = sort([...memberHands])` = `[B, V]` → `handNumberOf(B)=1, handNumberOf(V)=2` ✅ ตรงกับที่ user ต้องการ

ตรวจสอบเพิ่ม: mic toggle มี **จุดเข้าเดียว** (`meetingAudio.toggleMic`) ทั้ง keyboard shortcut "M", HUD button, และ toolbar อื่นๆ — ไม่มี bypass path ที่ข้าม auto-lower logic นี้ไปได้ ยืนยันด้วยว่า badge rendering (`CompactDisplayCard`) โชว์ตามเงื่อนไข `handNumber != null` ที่คำนวณสดทุก render ไม่มี cache/stale state

**สรุป:** ตรวจสอบทุกจุดในเชิง static code reading แล้ว **ไม่พบ defect** ที่อธิบายอาการที่ user รายงานได้ — mechanism ที่ออกแบบไว้ (auto-lower on unmute → WS broadcast → client recompute) ถูกต้องตามที่ trace ด้วยตัวเลขข้างบน ความเป็นไปได้ที่เหลือคือ (1) เกิด race condition จริงภายใต้ network latency จริงที่ static analysis มองไม่เห็น, (2) user ทำ action ที่ต่างจาก "กดปุ่ม mic" ตรงๆ (เช่น mute ผ่าน OS-level หรือ browser tab mute แทน), หรือ (3) เป็นไปได้ว่า bug นี้เกิดจาก scenario อื่นที่ไม่ตรงกับที่ trace ไว้

**ต้องการก่อนแก้:** repro จริงกับผู้ใช้ 3+ คน พร้อมเปิด DevTools Network (WS frames) ตอน A กดปุ่มไมค์เปิดพูด — เช็คว่า `ws:hand:changed` ส่งออกไปไหม และ client อื่นได้รับ `ws:hand:stateUpdate` (`raised:false`) สำหรับ A หรือไม่ — **ไม่แนะนำให้แก้โค้ดแบบเดาสุ่มโดยไม่มี repro** เพราะ mechanism ที่มีอยู่ตรวจสอบแล้วว่าถูกต้อง การแก้แบบไม่มีหลักฐานมีความเสี่ยงทำให้เกิด regression มากกว่าประโยชน์

---

## 6. (Feature Request) Busy status ใน Private Zone ต้องไม่เข้าร่วม Meeting (media)

**คำอธิบายภาษาชาวบ้าน:** ถ้าตัวละครอยู่ใน private zone และสถานะเป็น Busy ไม่ควรถูกดึงเข้าร่วม shared media (มิเช่นนั้นแม้ตั้ง Busy ไว้ก็ยังโดนรวมกล้อง/ไมค์กับคนอื่นในโซนอยู่ดี)

> ✅ **แก้แล้ว (2026-07-21)** — ดู Root Cause & Fix ด้านล่าง

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- Status ระบบจริง: `AvailabilityStatus = "available" | "busy" | "away" | "dnd"` (`vo-profile-panel.tsx`) — ตั้งเองผ่าน `VOStatusPicker` เท่านั้น ไม่มี auto-derive เป็น busy
- จุดที่ตัดสินว่า private zone จะกลายเป็น shared media room หรือไม่ อยู่ที่ `mediaZoneId` ใน `hero-virtual-office.tsx` (~L4506-4511 เดิม): `activeZone.zone_type === "private" && activePrivateOccupancy >= 2` — ค่านี้ป้อนตรงเข้า `useMeetingMedia({ meetingZoneId: mediaZoneId, ... })`
- `activePrivateOccupancy` (useMemo, ~L4487-4504) มี precedent อยู่แล้ว: exclude คนสถานะ `"away"` ออกจากการนับ (ทั้งคนอื่นและตัวเอง) — เป็น pattern เดียวกับที่จะใช้ทำ busy-gate
- สำคัญ: meeting zone (ไม่ใช่ private) มี logic เดิมอยู่แล้วที่ force-clear Busy/Away กลับเป็น "available" ตอนเข้า meeting zone (~L6638-6643 เดิม) — เพราะงั้น Busy จะไม่มีทางเกิดขึ้นใน meeting zone ได้เลยอยู่แล้ว ช่องโหว่มีแค่ private zone เท่านั้น (ตรงกับที่ user ระบุ)

**✅ Fix (`hero-virtual-office.tsx`):**
- เพิ่มเงื่อนไข `myStatus !== "busy"` เข้าไปใน private-zone clause ของ `mediaZoneId` ตรงๆ (บรรทัดเดียว): `activeZone.zone_type === "private" && activePrivateOccupancy >= 2 && myStatus !== "busy"`
- **ไม่แตะ** `activePrivateOccupancy` — คนที่ตั้ง Busy ยังคงถูกนับรวมในการคำนวณ occupancy ของคนอื่น (เพราะ exclusion filter เดิมกัน "away" เท่านั้น ไม่กัน "busy") ดังนั้นถ้ามี Busy 1 คน + non-Busy 1 คนในโซน คนที่ไม่ Busy ยังเข้า media ได้ปกติ (occupancy=2) — คนที่ Busy แค่ตัวเองไม่ join media plane เท่านั้น ยังเดินในโซนได้ตามปกติ ไม่ถูกกันออกจากโซน
- เพราะ `mediaZoneId` เป็น plain expression (ไม่ memoized) ที่ re-evaluate ทุก render และป้อนตรงเข้า `useMeetingMedia`'s lifecycle effect (deps มี `roomId`) — ผลข้างเคียงที่ได้มาฟรี: ถ้า user ที่กำลังอยู่ใน media session อยู่แล้วเปลี่ยนสถานะเป็น Busy ระหว่างทาง จะถูก disconnect ออกจาก media โดยอัตโนมัติทันที (ไม่ใช่แค่กันตอน join ใหม่เท่านั้น)
- ไม่เพิ่ม toast/notification ใดๆ — ตั้งใจให้ silent ตาม pattern เดิมของ force-clear-busy-on-meeting-entry ที่ก็ไม่มี toast เหมือนกัน (ถ้าต้องการ toast ทีหลังค่อยเพิ่ม)
- ขอบเขต: เจาะจงเฉพาะ status `"busy"` เท่านั้น ไม่แตะ `"dnd"`/`"away"` ตามคำขอเป๊ะๆ

**Verify:** `npx tsc --noEmit` และ `npx eslint views/user/virtual-office/hero-virtual-office.tsx` ผ่าน 0 error, dev server compile สะอาด ไม่มี console error — **ยังไม่ได้ live-test จริง** (ต้องมี 2+ ผู้ใช้จริงในเครื่องเดียวกัน private zone, ตั้งคนหนึ่งเป็น Busy แล้วดูว่า mic/cam ไม่ publish เข้า media session จริง)

---

## 7. (UI Polish) Hover controls บน video tile — เพิ่ม dark overlay + icon สีขาวให้เหมือนกัน

**คำอธิบายภาษาชาวบ้าน (พร้อมภาพหน้าจอ):**
- เวลา hover เจอปุ่มกล้อง/ไมค์บน tile อยากให้มี overlay สีดำอยู่ข้างหลังปุ่ม จะได้ดูเด่นขึ้น
- สี icon อยากให้เป็นสีขาวเหมือนกันหมด — ตอนนี้ tile ของตัวเอง (self) ใช้สีเขียว/แดงต่างจาก tile คนอื่น (remote) ที่เป็นสีขาวอยู่แล้ว

> ✅ **แก้แล้ว (2026-07-21)** — ดู Fix ด้านล่าง

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- 2 component ที่เกี่ยวข้องใน `views/user/virtual-office/components/zone-enter-panel.tsx`, ใช้ร่วมกันทั้ง `CompactDisplayCard` (top bar) และ `ExpandedDisplayCard` (full-screen grid):
  - `SelfTileControls` (~L931-961 เดิม) — hover บน tile ของตัวเอง แสดงปุ่ม cam/mic toggle จริง สี icon เดิม: **เขียว `#58D68D` (on) / แดง `#F03A3A` (off)**
  - `RequestMediaControls` (~L970-1008 เดิม) — hover บน tile คนอื่น แสดงปุ่ม "ขอให้ปิดกล้อง/ไมค์" สี icon เดิม: **ขาวอยู่แล้ว**
- ทั้งสอง component เดิมใช้ wrapper `<div className="absolute left-1/2 top-1/2 z-20 hidden -translate-x-1/2 -translate-y-1/2 items-center gap-[16px] group-hover:flex">` — ครอบแค่พื้นที่ปุ่ม ไม่มี dark overlay คลุมทั้ง tile
- มี pattern "dark overlay + button" ที่ใช้อยู่แล้วใน component อื่นในไฟล์เดียวกัน (ปุ่ม expand ของ screen-share, ~L632 เดิม): `<div className="absolute inset-0 z-20 hidden items-center justify-center bg-black/40 group-hover:flex">` — ใช้เป็น pattern อ้างอิงตรงๆ

**✅ Fix:**
- `SelfTileControls`: เปลี่ยน wrapper เป็น `absolute inset-0 ... rounded-[12px] bg-black/40 group-hover:flex` (จาก centered-only เป็น cover-ทั้ง-tile) + เปลี่ยน icon สี Video/VideoOff/Mic/MicOff ทั้ง 4 ตัวจาก `text-[#58D68D]`/`text-[#F03A3A]` → `text-white` ทั้งหมด
- `RequestMediaControls`: เปลี่ยน wrapper แบบเดียวกัน (icon สีขาวอยู่แล้ว ไม่ต้องแก้สี)
- ไม่แตะ toolbar หลักด้านล่าง (`vo-hud.tsx`, ปุ่ม cam/mic ตัวใหญ่ 24px) — นั่นเป็น pattern สีเขียว/แดงที่ตั้งใจแยกต่างหาก ไม่ใช่ tile hover ที่ user พูดถึงในภาพหน้าจอ

**Verify:** `npx tsc --noEmit` และ `npx eslint` ผ่าน 0 error, dev server compile สะอาด ไม่มี console error — **ยังไม่ได้เห็นผลจริงใน browser** เพราะ hover state นี้ต้อง login + เข้า meeting จริงพร้อมกล้องเปิด ถึงจะ trigger ให้เห็น (ไม่สามารถ reach ได้ในสภาพแวดล้อม dev ตอนนี้โดยไม่มี session จริง)

---

## 8. (Feature Request) เมนู Chat ในห้อง Meeting — เพิ่ม red dot แจ้งเตือนข้อความที่ยังไม่ได้อ่าน

**คำอธิบายภาษาชาวบ้าน:** อยากให้ปุ่ม chat ใน meeting panel มี red dot แสดงเมื่อมีข้อความที่ยังไม่ได้อ่าน

> ✅ **แก้แล้ว (2026-07-21)** — ดู Fix ด้านล่าง

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- ปุ่ม chat ที่เห็นในภาพ (ไอคอน chat bubble ใน toolbar ของ meeting panel พร้อม lock/link/expand) คือปุ่มใน `PanelHeader` component (`views/user/virtual-office/components/zone-enter-panel.tsx`) ที่ toggle `chatOpen` (state ใน `ZoneEnterPanel` หลัก)
- `meetingChatEntries` (prop, มาจาก `hero-virtual-office.tsx`'s `resolvedMeetingChatEntries`) คือ ephemeral chat log ของ meeting zone — แต่ละ entry มี `kind: "message" | "event"` (event = join/leave, ไม่ใช่ข้อความจริง)
- ไม่มีระบบ unread tracking สำหรับ meeting chat มาก่อนเลย (ต่างจาก main chat ที่มี `useChatStore`'s `unread_count` อยู่แล้ว แต่นั่นคนละระบบ ไม่เกี่ยวกับ meeting chat)

**✅ Fix (`zone-enter-panel.tsx`):**
- เพิ่ม `hasUnreadChat` derived state ใน `ZoneEnterPanel`: เก็บ `lastReadEntryCount` (จำนวน entries ณ ครั้งล่าสุดที่ chat "ปิด") ผ่าน pattern "adjust state during render" ของ React (เทียบ `chatOpen` กับ `prevChatOpen` ที่เก็บไว้ แล้ว setState แบบมีเงื่อนไขตรงๆ ใน render body — **ไม่ใช้ useEffect** เพราะจะโดน lint error `react-hooks/set-state-in-effect`, และ**ไม่ใช้ ref mutate ระหว่าง render** เพราะโปรเจกต์นี้ enable `react-hooks/refs` lint rule ที่ห้าม access ref ระหว่าง render ด้วย — ลองทั้ง 2 แบบแล้วโดน error ทั้งคู่ ก่อนเจอ pattern นี้ที่ผ่าน)
- `hasUnreadChat = !chatOpen && entries.slice(lastReadEntryCount).some(kind==="message" && user_id !== selfUserId)` — ตอน chat เปิดอยู่บังคับเป็น false เสมอ (ไม่มีอะไร unread ตอนกำลังดูอยู่), lastReadEntryCount อัปเดตเฉพาะตอน chat **ปิด** (transition true→false) เท่านั้น พอ chat ปิดแล้วมีข้อความใหม่เข้ามาจะโผล่ unread ทันที
- ไม่นับ entry kind="event" (join/leave) และไม่นับข้อความของตัวเอง
- ส่ง prop `hasUnreadChat` เข้า `PanelHeader` (ทั้ง 2 จุดที่เรียก — compact และ expanded), เพิ่ม red dot (`bg-[#F03A3A]`, 7px, absolute top-right) บนปุ่ม chat แสดงเมื่อ `hasUnreadChat && !chatOpen`
- ครอบคลุมทั้ง chat history เดิมที่มีอยู่ก่อน mount ด้วย (ถ้าเพิ่งเข้า zone มาแล้วมีข้อความเก่าที่ยังไม่เคยเห็น จะโชว์ unread ทันทีตั้งแต่แรก — ไม่ใช่แค่ข้อความใหม่หลัง mount เท่านั้น)

**Verify:** `npx tsc --noEmit` และ `npx eslint` ผ่าน 0 error (หลังแก้ lint error 2 รอบจาก useEffect/ref approach), dev server compile สะอาด ไม่มี console error — **ยังไม่ได้เห็นผลจริงใน browser** ต้อง login + เข้า meeting จริง + ให้อีกคนส่งข้อความตอน chat ปิดอยู่ ถึงจะเห็น dot ปรากฏจริง

---

## 9. (Feature Request) ป้ายจำนวนคนใน Meeting Zone — ให้ hover ก่อนถึงขึ้น เมื่อมีคนมากกว่า 2 คน

**คำอธิบายภาษาชาวบ้าน (พร้อมภาพหน้าจอ):** ป้าย "กลุ่ม Meeting 11 · 2" ที่ลอยอยู่เหนือ meeting zone บนแผนที่ — อยากให้ต้อง hover zone นั้นก่อนถึงจะขึ้นตัวเลขจำนวนคน ในกรณีที่ห้องนั้นมีคนมากกว่า 2 คนแล้ว (ห้องที่คนน้อย ≤2 คน ให้คงพฤติกรรมเดิม)

> ✅ **แก้แล้ว (2026-07-21)** — ดู Fix ด้านล่าง

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- ป้ายนี้**ไม่ได้อยู่ใน Pixi (`scene.ts`)** แต่เป็น React/HTML overlay ล้วนๆ ใน `hero-virtual-office.tsx` (~L7966-8004 เดิม) — "Active meeting room label" แสดง `{zone.name} · {section.present_count}` เหนือทุก meeting zone ที่มีคนอยู่ (`present_count > 0`)
- พฤติกรรมเดิม**สลับข้างกับที่ user ขอ**: ป้ายตัวเลขแสดง**เสมอ** (ยกเว้นตอน hover ถึงจะซ่อน — สลับไปโชว์ label ชื่ออย่างเดียวไม่มีตัวเลขแทน จาก block "Hover zone name label" ~L7931-7965 เดิม) — ไม่มีเงื่อนไข threshold คนเยอะ/น้อยเลยในโค้ดเดิม
- Hover state มีอยู่แล้วใน React (`hoveredZone`, จาก `handleCanvasMouseMove` → `zoneAtWorldPoint`) ไม่ต้องแก้ Pixi/scene.ts เลย
- Threshold "ห้องคนเยอะ" มี precedent ใกล้เคียงคือ `facepileZones` (`participants.length >= 2` สำหรับสลับไปโชว์ facepile) แต่ user ระบุ "มากกว่า 2" (`> 2`) ชัดเจน จึงใช้ threshold ของตัวเองแยก ไม่ reuse ค่า `>= 2` เดิม

**✅ Fix (`hero-virtual-office.tsx`):**
- Block "Active meeting room label" (ตัวเลข count): เอาเงื่อนไข `zone.id !== hoveredZone?.id` ออกจาก `.filter()` แล้วย้าย logic hover เข้าไปคำนวณใน `.map()` แทน: `isHovered = zone.id === hoveredZone?.id`, `isCrowded = section.present_count > 2`, แล้ว `if (isCrowded ? !isHovered : isHovered) return null` — สรุป: ห้องคนเยอะ (>2) โชว์**เฉพาะตอน hover**, ห้องคนน้อย (≤2) โชว์**เสมอยกเว้นตอน hover** (พฤติกรรมเดิม)
- Block "Hover zone name label" (ชื่ออย่างเดียว ไม่มีตัวเลข): เพิ่มเงื่อนไขไม่ให้ขึ้นซ้อนกับ badge ตัวเลขตอน hover ห้องคนเยอะ — `!(hoveredZone.zone_type === "meeting" && (zoneSections.get(hoveredZone.id)?.present_count ?? 0) > 2)` — กันไม่ให้ทั้ง 2 label โชว์ทับกันตอน hover ห้องที่มีคนมากกว่า 2

**Verify:** `npx tsc --noEmit` และ `npx eslint` ผ่าน 0 error, dev server compile สะอาด ไม่มี console error — **ยังไม่ได้เห็นผลจริงใน browser** ต้อง login เข้า workspace ที่มี meeting zone จริงพร้อมคนมากกว่า 2 คน แล้วลอง hover/ไม่ hover ดูว่า badge ตัวเลขสลับแสดง/ซ่อนถูกต้องตามที่ตั้งใจไว้

---

## Summary

| # | ประเภท | หัวข้อ | สถานะ |
|---|--------|--------|-------|
| 1 | Bug | กล้องไม่ติด ต้อง rejoin ห้อง | ✅ Fixed (2026-07-21) — ยังไม่ live-tested เส้นทาง timeout จริง |
| 2 | Bug | เบลอกล้องทำหน้าจอค้าง (Chrome unresponsive) | ✅ Fixed (2026-07-21) — ยังไม่ live-tested บนเครื่อง/Chrome ที่ freeze จริง |
| 3 | Feature | Auto full-screen เมื่อมีคนแชร์จอ | ✅ Fixed (2026-07-21) — ยังไม่ live-tested กับผู้ใช้ 2+ คนจริง |
| 4 | Feature | Auto/adaptive quality ตอนแชร์จอ | ✅ Fixed (2026-07-21) — ยังไม่ live-tested บน network ที่แย่จริง |
| 5 | Bug | ลำดับคิวยกมือไม่เลื่อนเมื่อคนข้างหน้าพูด/วางมือ | 🔍 ตรวจสอบ static code แล้วไม่พบ defect — ต้องการ live repro + WS network log ก่อนแก้เพิ่ม |
| 6 | Feature | Busy status ใน Private Zone ไม่เข้าร่วม meeting | ✅ Fixed (2026-07-21) — ยังไม่ live-tested กับผู้ใช้ 2+ คนจริง |
| 7 | UI Polish | Video tile hover: dark overlay + icon สีขาวให้เหมือนกัน | ✅ Fixed (2026-07-21) — ยังไม่เห็นผลจริงใน browser (ต้อง login + meeting จริง) |
| 8 | Feature | Chat menu red-dot unread indicator | ✅ Fixed (2026-07-21) — ยังไม่เห็นผลจริงใน browser (ต้อง login + meeting จริง) |
| 9 | Feature | Meeting zone count badge — hover-gate เมื่อคน >2 | ✅ Fixed (2026-07-21) — ยังไม่เห็นผลจริงใน browser (ต้อง login + meeting จริง) |
