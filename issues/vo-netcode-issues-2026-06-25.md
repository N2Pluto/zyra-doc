> **สถานะ:** ทั้ง 4 ปัญหาได้รับการแก้ไขแล้ว — ดูหัวข้อ "✅ Root Cause & Fix" ใต้แต่ละปัญหา
> Verify: `zyra-ws` ผ่าน `go build` / `go vet` / `go test ./internal/hub/`, `zyra-app` ผ่าน `tsc --noEmit` / `eslint`
> แนะนำให้ทดสอบจริงแบบ multiplayer (2+ เครื่อง/แท็บ) เพื่อยืนยันพฤติกรรม netcode

---

1. ปัญหาการซิงค์ตัวละครไม่ตรงกันเมื่อมีผู้ใช้จำนวนมาก (Desynchronization under High Load)

    คำอธิบายภาษาชาวบ้าน: พอคนเยอะปุ๊บ ตำแหน่งหรือสถานะตัวละครของแต่ละคนเริ่มไม่ตรงกัน (เช่น เครื่องเราเห็นคนนี้เดินไปซ้าย แต่เครื่องเพื่อนเห็นอยู่ทางขวา) จนต้องกด Refresh หน้าจอเพื่อดึงข้อมูลใหม่

    ขยายความเชิงเทคนิค (สำหรับ AI): > Issue: High-concurrency state desynchronization. เมื่อมีผู้ใช้งานพร้อมกันจำนวนมาก Server ไม่สามารถ Broadcast ข้อมูลตำแหน่ง (Position) และสถานะ (State) ของผู้เล่นทุกคนได้ทันเวลา หรือเกิดจากกลไก Client-side Prediction ที่ไม่มีการทำ Reconciliation (การสอดประสานข้อมูล) ที่ดีพอ ทำให้ข้อมูลในเครื่องของแต่ละ Client หลุดออกจากกัน (Desynced) จนต้องทำ Hard Reload เพื่อล้างแคชและดึง State ล่าสุดจาก Database/Server ใหม่

    ✅ **Root Cause & Fix:**

        Root cause (ของจริง): ไม่ใช่ broadcast ไม่ทัน (server มี latest-wins coalescing + flush ทุก 20ms + AOI grid อยู่แล้ว) แต่อยู่ที่ `Client.SendBin()` ใน `zyra-ws/internal/hub/client.go` — เมื่อ binary send buffer (cap 256) เต็มชั่วคราว (peer ที่ช้า/พับจอ ขณะมีคนขยับพร้อมกันเยอะ = 20Hz × N players) โค้ดเดิม **ตัด client ทั้งคนทิ้ง** (`unregister` + `close`) ผู้ใช้จึงหลุดจาก realtime stream → ต้องกด Refresh เพื่อ reconnect (ตรงกับอาการที่รายงาน)

        Fix: binary move frame เป็น idempotent latest-wins snapshot (tick ถัดไปทับเสมอภายใน 20ms) จึงเปลี่ยน `SendBin` ให้ **drop เฟรมเก่าทิ้ง 1 อันแล้ว enqueue เฟรมใหม่** แทนการตัด client — ผู้ใช้รอดผ่านช่วง congestion ชั่วคราวโดยไม่ต้อง refresh ส่วน client ที่ตายจริงยังถูกเก็บกวาดด้วย WritePump write-deadline / ping-pong (SendBin ถูกเรียกจาก move-ticker goroutine เดียวต่อ room → drain-and-replace ปลอดภัยจาก race) แถมกำจัด double-close bug ที่ซ่อนอยู่
        การแก้ Issue 4 (ด้านล่าง) ก็ช่วยลดแหล่ง desync ตอน resume จาก background ด้วย
        ไฟล์: `zyra-ws/internal/hub/client.go` (`SendBin`)


2. ปัญหานั่งค้างเมื่อลงจากโซฟา (Animation State Stuck / Glitch)

    คำอธิบายภาษาชาวบ้าน: เวลาตัวละครไปนั่งโซฟา แล้วพอลุกเดินออกมา ท่าทางของตัวละครยังค้างอยู่ในท่านั่ง แต่ตัวเคลื่อนที่ไปแล้ว

    ขยายความเชิงเทคนิค (สำหรับ AI):

        Issue: Animation State Machine failure on object detaching. เกิดจากเงื่อนไขการเปลี่ยนสถานะ (Animation Transition) ไม่ทำงานเมื่อผู้เล่นหลุดพ้นจาก Interaction Zone ของโซฟา ตัวแปรที่เป็นเงื่อนไข (เช่น isSitting = false) อาจจะไม่ถูกเปลี่ยน หรือ Event ตอนลุก (Exit Trigger) ไม่ได้ถูกส่งไปแจ้ง Animation Controller หรือ Server ทำให้ Client อื่นๆ ยังคงเล่นแอนิเมชันท่านั่งค้างไว้

    แนวทางแก้ไขที่แนะนำ:

        เช็ก Trigger เกรดการหลุดออกจากโซฟา (OnTriggerExit หรือ Un-sit Event) ว่าทำงานถูกต้อง 100% ไหม

        บังคับ Reset Animation State ทันทีที่ผู้เล่นกดปุ่มเคลื่อนที่ (Movement Input) ให้หลุดจากท่านั่งทันที

    ✅ **Root Cause & Fix:**

        Root cause (ของจริง): ฝั่ง local มีการ trigger ลุก (`_triggerSitRise`) บนปุ่มเคลื่อนที่อยู่แล้ว แต่ตอนผู้เล่นลุกแล้วเดินทันที สถานะ `sitting:false` ถูก **suppress** ใน moveTimer (`hero-virtual-office.tsx`, เงื่อนไข `&& !isPathWalking`) จึงมีช่วงที่ client อื่นยังได้ snapshot ค้างว่า `sitting:true` ทั้งที่ตัวกำลังเลื่อนที่ → เห็นเป็นท่านั่งไถลไปบนพื้น (moving แต่ pose ค้างนั่ง)

        Fix (2 invariant ที่ engine ฝั่งผู้รับ ใน `_updateRemotePlayerAnimations()` — ครอบคลุมทุกกรณีไม่ว่า propagate ทางไหนหลุด):
        1. **ตัวที่กำลังเคลื่อนที่จริงต้องไม่นั่ง** — ถ้าตรวจพบการเคลื่อนที่ (`movementDetected`) แต่ flag ค้าง `sitting=true` ให้ล้างทันที (กันท่านั่งไถลไปบนพื้น)
        2. **ตัวที่นั่งต้องอยู่บน seat tile จริง** — เคสนั่งค้าง **ลอยกลางอากาศ** ขณะหยุดนิ่ง (invariant ข้อ 1 ไม่ครอบคลุมเพราะไม่ขยับ) ถ้า `sitting=true` แต่ tile ปัจจุบันไม่อยู่ใน `sittableSeats` / `sittableObjectHitboxKeys` (และ seat data โหลดแล้ว) ให้บังคับยืน — re-check ทุกเฟรม จึง override กรณี buffer ยัด stale `sitting:true` ซ้ำได้
        ไฟล์: `zyra-app/zyra-engine/pixi-game/scene.ts` (`_updateRemotePlayerAnimations`)

        ✅ **Root cause ฝั่ง sender/server (ต้นตอจริงของ "นั่งค้างลอยกลางอากาศ"):**
        `move_to` (ตอนยืนแล้วเดิน) **ไม่ส่ง `avatar_url`** ไปด้วย → server `handleMoveTo` คง `c.AvatarURL` ไว้เป็น **sitting spritesheet** (ที่ตั้งไว้ตอนนั่งล่าสุด) แล้ว broadcast sheet เก่านั้นใน `moving` → peer เดินตัวละครด้วย spritesheet ท่านั่ง จึงเห็นเป็นนั่งค้าง/ตัวงอแม้จะลุกเดินแล้ว (`moveTimer` ที่ปกติส่ง avatar_url ตอนลุก ถูก suppress ระหว่าง path walk ด้วย `!isPathWalking`)
        Fix (sync avatar_url ผ่าน path protocol):
        • **sender** `setOnPathStarted` ส่ง `client.moveTo({ path, speed, avatar_url: walkAvatarUrl })` (walking spritesheet) → server อัปเดต `c.AvatarURL` = walk sheet, snapshot ของ new joiner ก็ถูกต้อง และ `moving` พา walk sheet ไป
        • **receiver** `offMoving` อัปเดต `otherPlayers[user]` เป็น `sitting:false` + `avatar_url = payload.avatar_url` → effect `setRemotePlayers` reload `walkTex` เป็น sheet ยืน (เลิกใช้ sheet นั่ง) และ un-stick sitting
        • ไม่ต้องแก้ Go เพิ่ม — `handleMoveTo` มี `if p.AvatarURL != "" { c.AvatarURL = p.AvatarURL }` และ `MovingPayload.AvatarURL` อยู่แล้ว แค่ client ไม่เคยส่งมา
        ไฟล์: `hero-virtual-office.tsx` (`setOnPathStarted`, `offMoving`)

        ✅ **Repro ที่แท้จริง + root cause สุดท้าย (background → resume):**
        ผู้ใช้ระบุ: เกิดเมื่อ **มีคนนั่งเก้าอี้ → เราพับจอ/สลับแท็บ → ระหว่างนั้นเขาลุกเดินออก → เรากลับมา → เห็นเขานั่งค้างกลางอากาศ**
        สาเหตุ: ขณะ tab ถูกพับ `requestAnimationFrame` หยุด + React effect ถูก throttle → engine ค้าง state เดิม (peer นั่งอยู่) และ event sit→stand/เดินที่เข้ามาระหว่างนั้น **ไม่ถูก reconcile เข้า engine**; ถ้า peer หยุดเดินแล้วไม่ขยับอีก engine ก็ค้างท่านั่งตลอด (ไม่มี event ใหม่มา trigger) — invariant per-frame อาจไม่จับเพราะ pathMovement/texture ค้าง
        Fix: hero เพิ่ม listener `visibilitychange` → ตอนกลับมา `visible` เรียก `setRemotePlayers(snapshot ล่าสุด, { resync: true })` → rebuild remote ทุกตัวจาก snapshot ที่ authoritative (ตำแหน่ง + sitting + reload texture) ล้าง state ที่ค้างจาก background (กลไก `resync` มีอยู่แล้ว แค่ไม่เคยถูก trigger ตอน resume) — ทำงานคู่กับ `_handleResumeFromBackground` ของ engine (reset local timer + re-baseline)
        ไฟล์: `hero-virtual-office.tsx` (visibilitychange resync effect)


3. ปัญหาความเร็วตัวละครไม่เท่ากันเมื่อกด Follow (Follow Speed Discrepancy)

    คำอธิบายภาษาชาวบ้าน: พอใช้ฟังก์ชันเดินตาม (Follow) ตัวละครที่เดินตามบางทีก็วิ่งไวเกินไป บางทีก็ช้าเกินไป หรือความเร็วของแต่ละเครื่องประมวลผลออกมาไม่เท่ากัน ทำให้ดูตุกติก

    ขยายความเชิงเทคนิค (สำหรับ AI):

        Issue: Frame-rate dependent movement or network lag latency in follow logic. ระบบคำนวณระยะห่างและความเร็วในการเดินตาม (Follow Logic) อาจจะอิงกับ Frame Rate ของหน้าจอ (เช่น ไม่ได้คูณด้วย deltaTime) ทำให้เครื่องที่ลื่นกว่าวิ่งไวกว่า หรือเกิดจาก Network Latency ที่ส่งพิกัดของผู้ถูกตามมาล่าช้า ทำให้ตัวเดินตามเกิดอาการกระตุกและพยายาม "เร่งความเร็ว" (Rubber-banding) เพื่อไล่ตามพิกัดล่าสุดให้ทัน

    ✅ **Root Cause & Fix:**

        ปัญหาเดิม (ชัดเจนจากผู้ใช้): **ตัวที่เดินตาม (follower) เดินตามไม่ทันคนด้านหน้า — ค่อยๆ ห่างออกเรื่อยๆ**

        Root cause (ของจริง — ต่างจากสมมติฐาน): การเคลื่อนที่คูณ `deltaTime` อยู่แล้วทุกจุด จึง **ไม่ใช่** frame-rate dependent ปัญหาจริงคือ follower เดินแบบ reactive (breadcrumb): รอ event "moving" ของคนนำ → re-path → เดินทีละ leg ด้วยความเร็ว **เท่ากับคนนำ (120 px/s)** แต่เสียเวลาไปกับ reaction-latency + การหยุด/ออกตัวระหว่าง leg (`setTimeout` defer + settle ตอนถึง) → ความเร็วเฉลี่ยต่ำกว่าคนนำ → ปิดช่องว่างไม่ได้ ยิ่งเดินยิ่งห่าง ("เดินตามไม่ทัน")

        Fix: **catch-up speed** — ให้ follower เดินเร็วขึ้นตามระยะที่ห่าง เพื่อไล่ปิดช่องว่าง พร้อมส่งความเร็วจริงผ่าน protocol ให้ peer render ตรงกัน:
        • `scene.ts`: เพิ่ม `_moveSpeedMult` + `setMoveSpeedMultiplier()` (clamp `1..SPRINT_MULTIPLIER`) และ `_currentMoveSpeed()` (= base × max(sprint, mult)) ใช้ใน `_updateMovement`; ส่ง speed ผ่าน `onPathStartedCallback` (keyboard + mouse/walkToTile)
        • hero `processFollowStep` / `handleStartFollow`: คำนวณระยะห่าง → `setMoveSpeedMultiplier(catchupMult)` ก่อนเดินแต่ละ leg — `dist 2→1.0×, 3→1.25×, 4→1.5×, ≥5→1.75×`; reset เป็น `1` ตอน adjacent (`dist<=1`) และตอน `handleStopFollow`
        • hero ส่ง `client.moveTo({ path, speed })`; server `handleMoveTo` ใช้ `clampSpeed(p.Speed)` (clamp `[120, 210]` กัน cheat) แทน 120 hardcode → ใช้คำนวณ `durationMs`, `MoveSpeed`, `MovingPayload.Speed` → peer render ความเร็วเดียวกับที่ follower เดินจริง (จึงไม่ snap/rubber-band และไม่ถูก clamp ตัดให้ช้าลง); backward compatible (client เก่าไม่ส่ง speed → fallback 120)
        ผลข้างเคียงที่ดี: แก้ bug sprint cross-machine (เดิมคน sprint จะดูช้ากว่าบนจอคนอื่น) ไปในตัว
        หมายเหตุ: cap ที่ 1.75× → ถ้าคนนำ sprint เต็ม follower จะตามแบบรักษาระยะ (ไม่ปิดช่องว่างเพิ่ม) ซึ่งเป็น edge case ที่ยอมรับได้
        ไฟล์: `scene.ts`, `zyra-engine/types.ts`, `components/game-canvas/pixi-canvas.tsx`, `hero-virtual-office.tsx`, `lib/api/workspace-ws-types.ts`, `zyra-ws/internal/hub/message.go`, `room.go`

ปัญหานี้เป็นอีกหนึ่งเคสคลาสสิกของเว็บแอปพลิเคชันหรือเกมบนเบราว์เซอร์เลยครับ!

สาเหตุเกิดจาก Browser Optimization (การประหยัดทรัพยากรของเบราว์เซอร์) เมื่อเราพับจอ ย้ายแท็บ หรือเปิดหน้าต่างอื่นบัง เบราว์เซอร์จะสั่ง Pause หรือลดความเร็วในการรัน JavaScript (requestAnimationFrame หรือ setTimeout/setInterval จะถูกจำกัดให้ทำงานช้าลงอย่างมากเพื่อเซฟแบตเตอรี่และ CPU)

พอเราเปิดจอกลับเข้ามา ระบบมันเลยรวบยอดคำนวณตำแหน่งที่ค้างอยู่ทั้งหมดในทีเดียว ทำให้เห็นตัวละคร "วาร์ป" หรือ "กระโดด" ไปโผล่อีกที่หนึ่งครับ

เพื่อเอาไปบรีฟต่อให้ AI หรือทีมพัฒนาเข้าใจ ให้ใช้คำอธิบายเชิงเทคนิคนี้ได้เลยครับ:
4. ปัญหาตัวละครวาร์ปเมื่อพับจอ/สลับแท็บ (Background Throttling & De-synchronization)

    คำอธิบายภาษาชาวบ้าน: เวลาคนเล่นพับจอลง หรือสลับไปเล่นเว็บอื่น พอเปิดกลับมาดูหน้าจอเกมอีกที ตัวละครของตัวเองหรือคนอื่นจะกระโดด/วาร์ปข้ามทิศทางไปเลย ไม่เดินต่อเนื่อง เพราะระบบหยุดทำงานตอนพับจอ

    ขยายความเชิงเทคนิค (สำหรับ AI):

        Issue: Browser Background Throttling causes state accumulation and sudden position snapping. เมื่อ Client ทำการ Minimise หน้าจอหรือสลับ Tab เบราว์เซอร์จะจำกัดการทำงานของ JavaScript Loop (requestAnimationFrame / Timers) ทำให้ Client ไม่ได้รับหรือประมวลผลข้อมูลตำแหน่งจาก Server แบบ Real-time พอผู้เล่นสลับหน้าจอกลับมา (Focus) ตัว Client จะประมวลผลข้อมูลพิกัดล่าสุดที่ตกค้างทันที ส่งผลให้เกิดการกระโดดของตำแหน่งตัวละครอย่างรุนแรง (Position Snapping/Warping) แทนที่จะเป็นการเคลื่อนที่แบบต่อเนื่อง

    แนวทางแก้ไขที่แนะนำ (Technical Solutions):

        ใช้ Web Workers สำหรับ Network Loop: แยกโค้ดส่วนที่รับ-ส่งข้อมูลกับ Server (เช่น WebSocket) ไปรันบน Web Workers เพราะ Web Workers จะไม่ถูกเตะปลั๊กหรือจำกัดความเร็ว (Throttled) แม้ว่าผู้เล่นจะพับจอหรือสลับแท็บ ทำให้รับข้อมูลพิกัดได้ต่อเนื่องตลอดเวลา

        ใช้ Page Visibility API: ตรวจจับสถานะเมื่อผู้เล่นกลับมาเปิดจอ (document.visibilityState === 'visible') แล้วให้ทำ Soft Reset หรือค่อยๆ ทำ Lerp (Linear Interpolation) เพื่อสไลด์ตัวละครไปยังตำแหน่งล่าสุดแทนการสั่งวาร์ปทันที

        Server-side Timestamp Validation: คำนวณการเคลื่อนที่โดยอิงจาก Time Delta ที่เกิดขึ้นจริงระหว่างเซิร์ฟเวอร์กับไคลเอนต์ ไม่ใช่อิงจากเฟรมเรตของเครื่องผู้เล่น

    ✅ **Root Cause & Fix:**

        Root cause (ของจริง): ไม่มี Page Visibility API เลย — พอ tab ถูกซ่อน browser หยุด `requestAnimationFrame` (game loop แช่แข็ง) แต่ WebSocket snapshot ยังเข้ามา/คิวค้างเรื่อยๆ พอกลับมา interpolator ไล่ replay backlog ที่ค้างทีเดียว + dead-reckoning ใช้ค่า elapsed มหาศาล → remote วาร์ป/snap ข้ามแมป

        Fix (ตามแนวทางที่แนะนำ — Page Visibility API + soft-reset): เพิ่ม listener `visibilitychange` (พร้อม cleanup) + เมธอด `_handleResumeFromBackground()` ใน scene เมื่อกลับมา visible:
        • reset `lastTimestamp` → เฟรมแรกที่กลับมาได้ dt เล็ก (local ไม่ประมวลผล backlog รวบยอด)
        • re-baseline remote ทุกตัว: ยุบ posBuffer เหลือ entry ล่าสุด re-stamp เป็น `now` (dead-reckoning elapsed reset ≈ 0 กันเหวี่ยง), gap ปานกลางให้ **glide เข้าด้วย `settle`** ที่มีอยู่แล้ว (สไลด์ ไม่วาร์ป), gap ไกลมาก snap (กันอาการไถลข้ามห้อง), ส่วน server-anchored path ปล่อยให้ settle เองเฟรมถัดไป (interpolatePath clamp progress → 1)
        หมายเหตุ: แนวทาง Web Workers สำหรับ network loop เป็นงาน architectural ใหญ่กว่า — ยังไม่ทำในรอบนี้
        ไฟล์: `zyra-app/zyra-engine/pixi-game/scene.ts` (`_handleResumeFromBackground`, visibility listener)

