# VO Meeting + Map Editor — Issues batch 2 (รายงาน 21 ก.ค. 2026)

> **สถานะ:** ข้อ 1-4 (Meeting UI), 5 (gate tuning + เมนู RNNoise/VoiceFilter แยกกัน), 6-8 (Audio), C1, C2 แก้แล้ว — ยัง**ไม่ได้ live-test จริง** (verify ด้วย `tsc`/`eslint` เท่านั้น ในตอนนี้); ข้อ 5: VoiceFilter ในเมนูยังเป็น "coming soon" (ไม่มี engine จริง) ไม่แก้ปัญหา "พูดพร้อมกัน" หายขาด — ดูรายละเอียดในหัวข้อ 5
> รายงานโดย: ten_dev@hpktechnology.com
> ขอบเขต: ฟีเจอร์ Meeting ใน Virtual Office (`zyra-app/views/user/virtual-office/`) + Map Editor (`zyra-app/views/admin/workspace-editor/`)
> หมายเหตุ: ไฟล์นี้แยกจาก [`vo-meeting-issues-2026-07-21.md`](./vo-meeting-issues-2026-07-21.md) ที่มีอยู่ก่อนแล้วในวันเดียวกัน — คนละชุดบั๊ก ไม่ทับซ้อนกัน

---

## 1. (Bug) หน้าจอ Meeting ไม่ Responsive — ต้องการ 2 แถว × 5 จอ/หน้า, paging ซ้าย/ขวา

**คำอธิบายภาษาชาวบ้าน:** อยากให้หน้าจอ meeting แสดงได้ 2 แถว แถวละ 5 จอพอดีในหนึ่งหน้าจอ ไม่อยากให้ต้องเลื่อนลง ถ้ามีคนมากกว่านั้นให้เลื่อนไปทางขวาหรือซ้ายแทน

> ✅ **แก้แล้ว (2026-07-21)**

**Root Cause:** grid แบบ "ไม่มีคนแชร์จอ" ใน `zone-enter-panel.tsx` เดิมใช้ `chunkArray(orderedParticipants, 3)` (3 คอลัมน์ fixed) ห่อด้วย `overflow-y-auto` แนวตั้ง — ไม่ตอบสนองขนาดจอจริง, ไม่มี pagination, การ์ดสูง fix ที่ 422px ทำให้เกิน 2 แถวก็ scroll ลง

**Fix:**
- เพิ่ม pagination state (`gridPage`) แบ่งผู้เข้าร่วมเป็นหน้าละ 10 คน (`chunkArray(orderedParticipants, 10)`), แต่ละหน้า chunk ต่อเป็นแถวละ ≤5 (`chunkArray(page, 5)`) → สูงสุด 2 แถว × 5 คอลัมน์ต่อหน้า
- เอา `overflow-y-auto` ออก, การ์ด (`ExpandedDisplayCard`) เปลี่ยนจาก fixed `h-[422px]` เป็น `h-full` (แต่ละแถวใช้ `flex-1 min-h-0` แบ่งพื้นที่แนวตั้งที่เหลือจริงเท่าๆ กัน — จอน้อยแถวเดียวก็ขยายเต็ม, จอเต็ม 2 แถวก็บีบพอดี ไม่ล้น) พร้อม `max-h-[440px]` กันการ์ดใหญ่เกินไปบนจอที่มีคนน้อยมากๆ
- เพิ่มปุ่ม ◀ ▶ (lucide `ChevronLeft`/`ChevronRight`, ใช้ i18n key เดิม `scrollLeft`/`scrollRight` ที่มีอยู่แล้วสำหรับ compact bar) แสดงเฉพาะเมื่อมีมากกว่า 1 หน้า

**ไฟล์:** `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx`

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test** ต้องเปิด preview จริง join ด้วย ≥11 คน (หรือ mock) ตรวจว่าไม่มี scrollbar แนวตั้ง, 2×5 พอดี, ปุ่ม paging ทำงานถูกต้อง

---

## 2. (Bug) ชื่อห้อง "Meeting room" โผล่ทับหน้าจอที่แชร์ตอน Full-screen

**คำอธิบายภาษาชาวบ้าน:** ตอนแชร์หน้าจอแบบ full-screen ชื่อห้อง Meeting room โผล่เข้ามาทับหน้าจอที่กำลังแชร์อยู่

> ⚠️ **แก้บางส่วน (2026-07-21) — ยังไม่ยืนยัน root cause 100%**

**Root Cause (ยังไม่ยืนยันสมบูรณ์):** ไม่มี browser Fullscreen API ในระบบเลย — "full-screen" คือ in-app expanded overlay (`isExpanded`) ดังนั้นนี่ต้องเป็นการซ้อนทับ DOM/CSS ในเบราว์เซอร์ผู้ชม ไม่ใช่ถูก capture เข้าไปในสตรีมจริง ตรวจสอบแล้วว่า `PanelHeader`/`ScreenShareBox` ไม่น่าจะเป็นจุดรั่ว (ไม่ทับกันในโครงสร้าง flex ปกติ, ScreenShareBox โชว์แค่ชื่อผู้แชร์) จุดต้องสงสัยที่สุดคือ world-space floating labels ("hover zone name" และ "Active meeting room label") ใน `hero-virtual-office.tsx` ที่มี comment ยืนยันว่าเคยเกิดบั๊ก z-index/stacking-context แบบเดียวกันในไฟล์นี้มาก่อน

**Fix (defensive — ป้องกัน edge case ไม่ว่า root cause จริงจะเป็นอะไร):** เพิ่ม guard `!meetingExpanded` ให้ทั้งสอง world-space label ไม่ render เลยขณะ `ZoneEnterPanel` กำลัง expand (`meetingExpanded` เป็น hero-level state ที่ควบคุม panel นี้อยู่แล้วผ่าน `isExpanded`/`onExpandChange` prop ที่มีอยู่ก่อนแล้ว) — label โลกจริงไม่มีประโยชน์อะไรตอน panel คลุมเต็มจออยู่แล้ว

**ไฟล์:** `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (guard ที่ world-space label ทั้งสอง)

**Verify:** `tsc`/`eslint` ผ่าน — **ต้อง live-repro ยืนยันก่อนปิดงานจริง**: เปิด 2 แท็บ (คนแชร์ + คนดู), ขยาย panel เป็น fullscreen ระหว่างแชร์, สังเกตทุกจังหวะ (เข้าห้อง/เริ่มแชร์/expand) ว่าไม่มีข้อความชื่อห้องโผล่ทับอีก ถ้ายังพบ ต้องหา DOM element จริงที่ยังไม่ได้ตรวจ (อาจไม่ใช่ 2 label ที่แก้ไปนี้)

---

## 3. (Bug) Hover ห้องข้างๆ ทำ Video ในห้องปัจจุบันหายหมด

**คำอธิบายภาษาชาวบ้าน:** ตอนอยู่ใน Meeting room พอเอาเมาส์ไป hover ห้องข้างๆ Display หน้าจอ (video ทุกคน) หายหมดเลย พอเอาเมาส์ออกจึงกลับมาเหมือนเดิม

> ✅ **แก้แล้ว (2026-07-21)**

**Root Cause:** `handleCanvasMouseMove` set `zoneAccessState = { zone: <ห้องที่ hover>, ... }` ทุกครั้งที่ hover ห้อง meeting ที่ล็อกอยู่ห้องไหนก็ได้ (ไม่ใช่แค่ห้องที่กำลังพยายามเข้า) แต่ gate การ render `ZoneEnterPanel` (คุม video ทุก tile ของห้องปัจจุบัน) เป็น blanket `!zoneAccessState` — ไม่เช็คว่าห้องที่ hover ตรงกับห้องที่ user อยู่จริงหรือไม่ ผลคือ hover ห้อง B ขณะอยู่ห้อง A ทำ panel ของห้อง A unmount ทันที

**Fix:** เปลี่ยน gate จาก `!zoneAccessState` → `!(zoneAccessState && zoneAccessState.zone.id !== activeZone?.id)` — panel จะซ่อนเฉพาะตอน zoneAccessState เป็นห้องเดียวกับ activeZone จริงๆ เท่านั้น

**ไฟล์:** `zyra-app/views/user/virtual-office/hero-virtual-office.tsx`

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test**: อยู่ห้อง A ที่มี video เปิด, hover ห้อง B (locked) ข้างๆ, ยืนยันว่า video ห้อง A ไม่หายระหว่าง hover

---

## 4. (Bug) ชื่อตัวละครไม่ตรงกับชื่อใน Meeting Display

**คำอธิบายภาษาชาวบ้าน:** ตัวละครตั้งชื่อว่า ABC แต่ใน Meeting Display ยังโชว์ชื่อเดิม เช่น "Pai"

> ✅ **แก้แล้ว (2026-07-21)**

**Root Cause:** `charName` โหลดจาก localStorage ครั้งเดียวตอน mount; sync จาก DB มีแค่ครั้งเดียวแบบมี guard `if (!charName && ...)` — เมื่อ `charName` มีค่าแล้ว (แม้จะเก่า/ผิด จากการที่ lobby form auto-fill ด้วย account display_name ถ้าไม่เคยตั้งมาก่อน) จะไม่ถูก refresh จาก DB อีกเลยตลอด session priority การเลือกชื่อใน `getZoneParticipants()` ถูกต้องอยู่แล้ว (character_name ก่อน display_name) — ปัญหาคือ local state ค้าง ไม่ใช่ priority ผิด

**Fix:** เอา guard `!charName` ออกจาก effect ที่ sync จาก DB member entry — เทียบค่าล่าสุดจาก DB กับ `charName` ปัจจุบันทุกครั้งที่โหลด แล้วอัปเดตเฉพาะเมื่อต่างกัน (กัน re-render วนไม่จำเป็น) ทำให้ meeting tile เห็นชื่อที่ตรงกับที่ตั้งไว้ล่าสุดใน DB เมื่อเข้า VO ครั้งถัดไป โดยไม่ต้องเพิ่ม UI แก้ไขชื่อใหม่ใดๆ

**ไฟล์:** `zyra-app/views/user/virtual-office/hero-virtual-office.tsx`

**ข้อจำกัดที่เหลือ:** ถ้าเปลี่ยนชื่อตัวละครขณะอยู่ใน VO session เดียวกันสด (ไม่ reload/re-enter) จะยังไม่ sync ทันที ต้องออก-เข้าใหม่ครั้งถัดไปถึงจะเห็นชื่อล่าสุด (ไม่ implement live-refresh กลางเซสชัน เพราะเป็นการเพิ่ม scope ที่ user ไม่ได้ขอ)

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test**: ตั้งชื่อใน lobby, เข้าห้อง meeting, เทียบชื่อบน tile

---

## 5. (Limitation/Research) Noise Reduction "High" ไม่กันเสียงคนข้างๆ ที่พูดพร้อมกัน

**คำอธิบายภาษาชาวบ้าน:** กด Noise reduction เป็น High แล้ว ยังมีเสียงคนรอบข้างเข้ามาอยู่

> ✅ **แก้บางส่วน (2026-07-21) — tuning ภายใน RNNoise เดิม** (ตามที่ user เลือกรอบ 3: ใช้ RNNoise ต่อ แต่ปรับปรุงเพิ่ม แทนที่จะเปลี่ยนไป Krisp/อื่นๆ ที่ต้องเสียเงิน/รอ sales)

**Root Cause (ยืนยันจากโค้ดจริง, comment ในไฟล์อธิบายตรงๆ):** "High" = RNNoise (denoise เสียง noise ต่อเนื่อง เช่น พัดลม/แอร์) ต่อด้วย NoiseGate (เปิดเฉพาะตอนเงียบจริง -60dB) — เสียงคนข้างๆ พูด "คือเสียงพูด" ทั้งคู่ ไม่มีกลไกแยกเสียงพูดคนละคนออกจากกัน (ต้อง speaker-isolation/target-speaker-extraction ไม่ใช่ noise-suppression ธรรมดา) — ข้อจำกัดของสถาปัตยกรรม ไม่ใช่ config ผิด

**รอบ 1 (DTLN/ai-coustics/target-speaker research-grade)** — ดูรายละเอียดเต็มในประวัติ git/versioning ของไฟล์นี้ — สรุปสั้น: ทั้งหมดเป็น noise-suppression ธรรมดา (เหมือน RNNoise) ไม่ใช่ speaker-isolation ไม่แก้ปัญหานี้ตรงจุด

**รอบ 2 (2026-07-21 เพิ่มเติม) — พบตัวเลือกที่ตรงปัญหาจริง: Krisp VIVA SDK / "Voice Isolation" (`krisp-viva-pro` model)**

| ประเด็น | ผลตรวจสอบ |
|---|---|
| ทำสิ่งที่ user ต้องการจริงไหม | ✅ **ใช่ — เป็นสินค้าที่ shipped จริง** (ไม่ใช่ research-grade) การตลาดของ Krisp เองบอกตรงๆ ว่า "detects and removes all other nearby human voices and keeps only the main speaker's voice" — ตรงปัญหา 100% ต่างจากทุกตัวเลือกในรอบ 1 |
| Self-host ได้ไหม (ไม่ผูก LiveKit Cloud) | ✅ Krisp มี SDK ของตัวเอง (`sdk-docs.krisp.ai`) แยกจาก `livekit-plugins-noise-cancellation` — integrate เข้า audio pipeline ของตัวเองได้ตรง ๆ (รองรับ WebRTC transport ผ่าน `audio_in_filter`) ไม่ต้องพึ่ง LiveKit Cloud เลย — ข้อจำกัดเดิมที่เจอ ("ต้อง LiveKit Cloud") เป็นเรื่องเฉพาะ package wrapper ของ LiveKit เท่านั้น ไม่ใช่ข้อจำกัดของ Krisp เอง |
| Real-time พอไหม | ✅ VIVA SDK claim latency ~15ms (algorithmic), โมเดลเล็ก รันบน CPU ได้ |
| รองรับ Web/JS-WASM ไหม | ⚠️ **ยังไม่ยืนยัน 100%** — เอกสารบอกว่า SDK รองรับ "Web (JS/WASM)" เป็น platform ทั่วไป แต่ตัวอย่าง/เอกสารเชิงลึกของ Voice Isolation/VIVA เน้นไปทาง Conversational-AI-agent pipeline (เช่น Pipecat, ซึ่งเป็น Python framework ฝั่ง server) มากกว่า client-side ในเบราว์เซอร์แบบที่ noise-processors.ts ปัจจุบันใช้อยู่ — ต้องคุยกับทีม Krisp โดยตรงเพื่อยืนยันว่า "Voice Isolation" model รันใน browser ผ่าน JS/WASM ได้จริงสำหรับ use-case "meeting คนต่อคน" (ไม่ใช่แค่ human-to-AI-agent) |
| Pricing/licensing | ⚠️ **ไม่เปิดเผยสาธารณะ** — หน้า pricing ทั่วไปของ Krisp (consumer app, $8-15/เดือน) ไม่ใช่ราคาของ developer SDK; หน้า developer ให้แค่ "Request SDK Access"/ติดต่อ sales เท่านั้น |
| เงื่อนไขการใช้งาน | มีการระบุว่า Voice Isolation ทำงานดีที่สุดเมื่อพูดใกล้ไมค์ (มี "compatible devices" list สำหรับ headset บางรุ่นในแอปเดิม) — สอดคล้องกับหลักฟิสิกส์ทั่วไปของทุกโมเดล isolation ไม่ใช่ข้อจำกัดเฉพาะของ Krisp |

**คำแนะนำของผม:** **Krisp VIVA / Voice Isolation คือตัวเลือกที่ดีที่สุดที่หาเจอ** — เป็นสินค้าจริงตัวเดียวในตลาดตอนนี้ที่ทำสิ่งที่ user ต้องการ (แยกเสียงคนพูดคนละคน ไม่ใช่แค่กรอง noise) และไม่ผูกกับ LiveKit Cloud แต่ **ยังฟันธงไม่ได้ 100%** ว่าจะ integrate เข้ากับสถาปัตยกรรม client-side ปัจจุบันของ Zyra ได้ตรงๆ เพราะเอกสารสาธารณะเน้นไปทาง server-side voice-AI-agent มากกว่า — ขั้นต่อไปที่แนะนำคือ:

1. **ติดต่อ Krisp SDK sales/dev-relations โดยตรง** (ผ่าน "Request SDK Access" ที่ krisp.ai/developers) เพื่อถามยืนยัน 3 เรื่อง: (a) "Voice Isolation" model ใช้ผ่าน JS/WASM ใน browser client ได้จริงไหมสำหรับ use-case meeting คนต่อคน (ไม่ใช่แค่ agent pipeline), (b) โมเดลราคา/licensing เข้ากับ self-hosted SFU ของเราได้ไหม, (c) ขอ eval/trial account มาทดสอบ latency จริงกับ LiveKit ของเรา — ขั้นตอนนี้เป็นงาน business/procurement ไม่ใช่สิ่งที่ผมยืนยันต่อได้ด้วยการค้นหาเพิ่ม
2. ระหว่างรอคำตอบจาก Krisp — คงใช้ RNNoise ปัจจุบันไปก่อน (ไม่แนะนำเปลี่ยนไป DTLN ก่อน เพราะยืนยันแล้วว่า DTLN ไม่แก้ปัญหานี้เช่นกัน จะเสีย effort เปล่า)
3. **มาตรการเร็วสุดระหว่างนี้ (ไม่ใช่ซอฟต์แวร์):** แนะนำ user ใช้ headset ที่มีไมค์ boom ใกล้ปาก — ลดเสียงรอบข้างเข้าไมค์ได้จริงตามฟิสิกส์ และเป็นเงื่อนไขที่ Krisp เองก็แนะนำเช่นกัน

**รอบ 3 (2026-07-21 — implement จริง): tuning gate ของ "High" ให้เข้มขึ้น โดยไม่เปลี่ยนโมเดล**

`RnnoiseWorkletNode` เองไม่มี parameter ให้ปรับ "ความแรง" เลย (มีแค่ `maxChannels`/`wasmBinary`) — เป็น fixed pretrained model ตรวจสอบแล้วจาก type definitions ของ `@sapphi-red/web-noise-suppressor` ส่วนเดียวที่ tune ได้จริงคือ **NoiseGateWorkletNode ที่ต่อท้าย RNNoise** ก่อนแก้ Low และ High ใช้ `GATE_OPTS` ชุดเดียวกัน (`openThreshold: -50, closeThreshold: -60, holdMs: 500`) ทำให้ High ไม่ได้เข้มกว่า Low จริงๆ ในส่วน gate

**Fix:** แยก gate config เป็น 2 ชุด — `LOW_GATE_OPTS` (ค่าเดิม, gentle ตามเจตนาเดิมของ Low) และ `HIGH_GATE_OPTS` ใหม่ที่เข้มกว่า/ปิดเร็วกว่า (`openThreshold: -42, closeThreshold: -52, holdMs: 250`) ใช้เฉพาะกับ gate ที่ต่อท้าย RNNoise ใน "High" — ผลคือช่วงเวลาที่เสียงพื้นหลัง/คนข้างๆ จะรั่วผ่านได้ระหว่าง "ช่วงที่ผู้พูดหลักหยุดพูด" จะสั้นลง (ปิดเร็วขึ้น, threshold เปิดยากขึ้น)

**ไฟล์:** `zyra-app/lib/api/noise-processors.ts`

**ข้อจำกัดที่ยังอยู่ (สำคัญ ต้องบอก user ตรงๆ):** การ tune นี้ช่วยได้เฉพาะ**ช่วงที่ผู้พูดหลักเงียบ/หยุดพูด** เท่านั้น — **ไม่สามารถตัดเสียงคนอื่นที่พูดพร้อมกับผู้พูดหลักได้** เพราะ noise gate ไม่มีทางแยกได้ว่าเสียงที่ยังอยู่เหนือ threshold ตอนนั้นเป็นใครพูด (เป็นข้อจำกัดของสถาปัตยกรรม gate ทั่วไป ไม่ใช่แค่ config) ถ้าอยากแก้ปัญหา "พูดพร้อมกัน" ให้หายขาดจริง ต้องใช้ speaker-isolation (Krisp VIVA หรือ VoiceFilter-Lite ที่คุยกันไปก่อนหน้า) มีความเสี่ยงเล็กน้อยที่ threshold ใหม่จะเริ่มตัดหางคำพูดของผู้ใช้เองถ้าพูดเบา/พูดช้า — ถ้าเจอปัญหานี้ให้ปรับ `HIGH_GATE_OPTS.holdMs` ขึ้นก่อน (250 → 350-400) แล้วค่อยผ่อน threshold ถ้ายังไม่พอ (ค่าคงที่มี comment อธิบายไว้ในโค้ดแล้ว)

**สถานะ:** Fix นี้แก้แล้ว (`tsc`/`eslint` ผ่าน) — **ยังไม่ live-test เสียงจริง** ต้องฟังเปรียบเทียบก่อน/หลังในสภาพแวดล้อมที่มีคนพูดข้างๆ จริง เพื่อยืนยันว่าค่าที่เลือกไว้ (holdMs 250, threshold -42/-52) เหมาะสมหรือต้องปรับเพิ่ม — ถ้ายังไม่พอ ให้กลับไปพิจารณา Krisp VIVA (รายละเอียดด้านบน) เป็นทางเลือกถัดไป

**รอบ 4 (2026-07-21 — implement UI): แยกเมนูเป็น 2 engine (RNNoise / VoiceFilter), แต่ละตัวมี Medium/High**

ตามที่ user ขอ — restructure เมนู noise reduction จากแถวเดียว (Off/Low/High) เป็น: ปุ่ม **Off** แยกต่างหาก + กลุ่ม **"RNNoise"** (Medium/High, ใช้งานได้จริง — ภายในคือค่า `"low"`/`"high"` เดิม ไม่เปลี่ยน persistence key) + กลุ่ม **"VoiceFilter"** (Medium/High, ยังไม่มี engine จริงตามที่คุยกันในหัวข้อนี้ — ปุ่มกดได้แต่ไม่ทำอะไร นอกจากขึ้น toast "coming soon" ผ่าน `zyraToast.info` ตาม pattern เดียวกับ billing/calendar ที่มีอยู่แล้วในแอป)

ผลพลอยได้ทางโค้ด: เดิม "Low" ไม่ได้รัน RNNoise เลย (แค่ NoiseGate เฉยๆ) ส่วน "High" รัน RNNoise+gate — พอเปลี่ยนมาเป็นเมนู "RNNoise" ที่มี 2 ระดับ ทำให้ทั้ง Medium และ High ต้องรัน RNNoise เหมือนกันทั้งคู่ (ต่างกันแค่ความเข้มของ gate ที่ต่อท้าย) จึงรวม `NoiseGateProcessor`/`RnnoiseProcessor` เดิม (2 class) เป็น class เดียว (`RnnoiseProcessor` รับ gate config เป็น parameter)

**ไฟล์:** `zyra-app/lib/api/noise-processors.ts`, `zyra-app/views/user/virtual-office/components/vo-media-device-menu.tsx`, `zyra-app/messages/en.json`, `zyra-app/messages/th.json`

**สถานะ:** `tsc`/`eslint` ผ่าน, JSON locale ทั้งสองไฟล์ valid, dev server compile สะอาดไม่มี console error — **ยังไม่ได้คลิกทดสอบเมนูจริงในเบราว์เซอร์** เพราะต้อง auth + เข้าห้อง meeting ซึ่ง `zyra-api` ไม่ได้รันอยู่ในสภาพแวดล้อมนี้ ต้องเปิดเมนู mic (ปุ่มลูกศรข้าง mic ใน HUD) แล้วดูว่า 2 กลุ่มแสดงถูกต้อง, RNNoise เลือกได้จริง, VoiceFilter กดแล้วขึ้น toast ไม่ทำอะไรอย่างอื่น

---

## 6. (Bug) เสียงพูดเบา + เอียงไปทางซ้าย แม้เปิดลำโพง 80% แล้ว

**คำอธิบายภาษาชาวบ้าน:** เสียงพูดตอน Meeting ยังเบาอยู่ถึงแม้จะเปิดลำโพงของตัวเอง 80% แล้ว และเสียงออกด้านซ้าย

> ✅ **แก้แล้ว (2026-07-21)**

**Root Cause:** noise-reduction worklet chain (`GATE_OPTS.maxChannels: 1`, `RnnoiseWorkletNode({ maxChannels: 1 })`) เขียนผลลัพธ์ลง **channel 0 (ซ้าย) เท่านั้นเสมอ** ไม่ว่า input จะมีกี่ channel แต่ `createMediaStreamDestination()` default เป็น 2-channel output เมื่อไมค์เป็นอุปกรณ์ stereo-capable (USB mic/บาง headset) — WebAudio graph พา 2 channel ตลอดสาย แต่ worklet เติมแค่ channel ซ้าย → channel ขวาเงียบสนิท = "เบา" (ใช้แค่ 1 ใน 2 channel) + "เอียงซ้าย" (ขวาไม่มีเสียงเลย)

**Fix:** เพิ่ม `channelCount: { ideal: 1 }` ใน `audioCaptureDefaults` — บังคับ capture เป็น mono ตั้งแต่ต้นทาง (มาตรฐานปกติสำหรับ voice call, ไม่กระทบคุณภาพ) ทำให้ WebAudio graph ทั้งสายเป็น mono จริงตรงกับ assumption ของ worklet chain

**ไฟล์:** `zyra-app/lib/api/sfu-client.ts`

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test บนไมค์ stereo จริง**: ทดสอบด้วยไมค์ USB/headset ที่ report เป็น stereo (เช็คผ่าน `getUserMedia().getAudioTracks()[0].getSettings().channelCount` ก่อน/หลังแก้), ยืนยันเสียงออกทั้งสองหูเท่ากัน

---

## 7. (Bug) เปลี่ยน Device Mic แล้วเสียงหาย พูดไม่ได้ คนอื่นไม่ได้ยิน

**คำอธิบายภาษาชาวบ้าน:** เปลี่ยน device mic แล้วเสียงหาย พูดไม่ได้ คนอื่นไม่ได้ยิน

> ✅ **แก้แล้ว (2026-07-21)**

**Root Cause (ยืนยันจากโค้ด LiveKit จริงใน `node_modules`):** `switchDevice(..., exact: true)` → LiveKit's `LocalTrack.restart()` `stop()` device เดิมก่อนเสมอ **แล้วค่อย** `getUserMedia()` เปิดตัวใหม่ — ถ้าเปิดใหม่ล้มเหลว (busy/driver hiccup) mic จะไม่มีอะไรทำงานเลยเพราะตัวเก่าถูกปล่อยไปแล้ว rollback เดิมก็ใช้ `exact: true` เช่นกัน (เสี่ยง fail ซ้ำ) และถ้า rollback fail ก็ถูก swallow เงียบๆ ต่างจากกล้องที่มี `CameraTimeoutError` + reconnect safety net เต็มรูปแบบ — มิคไม่มีมาก่อน

**Fix:** เปลี่ยนชื่อ `recoverCameraSession` → `recoverMediaSession` (ใช้ร่วมกันได้จริง ไม่ได้ทำอะไรเฉพาะกล้อง) แล้วเรียกใช้จาก `selectDevice()`'s catch handler ด้วย — ถ้า rollback ไปอุปกรณ์เดิมก็ล้มเหลว (หรือไม่มีอุปกรณ์เดิมให้ rollback) สำหรับ `kind === "audioinput"` จะ trigger reconnect ทั้ง session (`sfu.disconnect()` + re-`establish()`) แทนการปล่อยเงียบ พร้อม toast แจ้งเตือนใหม่ (`micReconnectingTitle`/`micReconnectingBody`, เพิ่ม i18n en+th)

**ไฟล์:** `zyra-app/views/user/virtual-office/use-meeting-media.ts`, `zyra-app/messages/en.json`, `zyra-app/messages/th.json`

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test**: จำลอง switchDevice fail (device busy/unplug กลางทาง), ยืนยันว่าระบบ auto-recover แทนที่จะเงียบ

---

## 8. (Bug) Capture หน้าจอตอนคุยกันใน Meeting ยังได้ยินเสียงประชุม

**คำอธิบายภาษาชาวบ้าน:** ตอนคุยกันใน Meeting พอ capture หน้าจอ ยังได้ยินเสียง

> ✅ **แก้บางส่วนแล้ว (2026-07-21)** — เฉพาะกรณีที่แก้ได้จริง

**Root Cause:** แยกเป็น 2 กลไก
- **(a) แก้ได้จริง:** `setScreenShareEnabled()`/`switchScreenShareSource()` เรียก `getDisplayMedia({ audio: true, ... })` แบบ plain — ไม่เคยตั้ง `restrictOwnAudio`/`systemAudio: "exclude"` เมื่อแชร์ "Entire Screen" จะพ่วงเสียงระบบทั้งหมดซึ่งรวมเสียงประชุมที่กำลังเล่นอยู่บนเครื่องเดียวกัน (feedback loop เข้าไปในแทร็กที่แชร์เอง)
- **(b) แก้ไม่ได้ (ข้อจำกัดแพลตฟอร์ม):** เครื่องมือ record จอระดับ OS (QuickTime, Game Bar, OBS) capture เสียง system output ซึ่งรวมเสียงประชุมที่เล่นผ่าน `<audio>` element ปกติเสมอ — ไม่มี Web API ใดให้เว็บ opt-out เสียงตัวเองจาก OS-level capture ได้ **ไม่ใช่บั๊กของ Zyra**

**Fix ((a) เท่านั้น):** เพิ่ม `audio: { restrictOwnAudio: true }` และ `systemAudio: "exclude"` ใน `setScreenShareEnabled()` (ผ่าน LiveKit's `ScreenShareCaptureOptions`) และ `switchScreenShareSource()` (raw `getDisplayMedia()`, ต้อง cast type เพิ่มเพราะ property เหล่านี้ยังไม่อยู่ใน TS bundled DOM lib — Chromium-only, spec ใหม่)

**ไฟล์:** `zyra-app/lib/api/sfu-client.ts`

**ข้อจำกัด (b) ที่ user ควรทราบ:** ถ้าใช้โปรแกรม record จอระดับ OS ขณะเปิดลำโพงฟังเสียงประชุมอยู่ เสียงจะติดไปด้วยเสมอ ไม่มีทางแก้จากฝั่งเว็บแอป — ต้อง mute ลำโพง/ใช้หูฟังตอน record ถ้าไม่ต้องการให้ติดเสียง

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test**: แชร์จอพร้อมเปิดเสียงประชุมออกลำโพงเครื่องเดียวกัน, ฟังว่าเสียงประชุม/feedback ไม่เข้าไปในแทร็กที่แชร์

---

## 9. (Bug — หลังบ้าน) Object ล่องหน ต้องออกและเข้า Editor ใหม่

**คำอธิบายภาษาชาวบ้าน:** แต่งแผนที่บางครั้งมี object ล่องหน ไม่สามารถวางได้ ต้องออกและเข้าใหม่

> ✅ **แก้แล้ว (2026-07-21)**

**Root Cause:** `thumbCache` (`useRef<Map>`) preload แต่ละ URL พร้อม cache-busting retry **แค่ 1 ครั้ง** ถ้า 2 ครั้งนี้ fail ทั้งคู่ (เครือข่ายสะดุดชั่วคราว/S3-R2 hiccup) URL นั้นจะไม่ถูกเพิ่มเข้า cache เลย และ draw loop จะข้ามวาด object นั้นแบบเงียบๆ ตลอดไป จนกว่าจะมี state เปลี่ยนที่ trigger preload effect รันใหม่ — ถ้า user ไม่ได้ทำอะไรอื่นต่อ ก็ไม่มีอะไร retry ตรงกับอาการ "ยังเลือก/วางได้ (hit-test ใช้ tile-occupancy ไม่ใช่ thumbCache) แต่ไม่ render" และ "ออก-เข้าใหม่แก้ได้" (remount = thumbCache ว่างใหม่)

**Fix:** ปรับ `loadImage()` ให้ retry แบบ bounded (3 ครั้งรวม, backoff 0/1s/3s, cache-bust ทุก retry) ก่อนจะถือว่า fail จริง — ครอบคลุม transient network blip โดยไม่ต้องรอ state อื่นเปลี่ยนหรือ remount ทั้ง component (เพิ่ม cleanup flag กัน retry timer ทำงานหลัง unmount/effect re-run ด้วย)

**ไฟล์:** `zyra-app/views/admin/workspace-editor/components/map-editor-canvas.tsx`

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test**: จำลอง network throttling/offline ชั่วคราวตอน editor preload ภาพ, ยืนยันว่า object ปรากฏขึ้นเองหลัง retry

---

## 10. (Bug — หลังบ้าน) Object วางแล้วไปอยู่หลังกำแพงแทนที่จะอยู่หน้า

**คำอธิบายภาษาชาวบ้าน:** บางครั้งวาง object แล้วไม่อยู่หน้ากำแพง ไปอยู่หลังกำแพงแทน

> ✅ **แก้แล้ว (2026-07-21) — ตามที่ user เลือก: ขยาย toggle ให้ทุก object type (ไม่ทำ auto-detect)**

**Root Cause:** paint-order math (`WALL_MOUNT_LAYER`) ที่แก้ไปก่อนหน้านี้ถูกต้องและเทสครบแล้ว — ไม่ใช่ regression ปัญหาจริงคือ `wall_mounted` flag เป็น **manual-only เสมอ ไม่มี auto-detect** และ toggle ที่จะแก้มันถูกจำกัดเฉพาะ `objectType === "decoration" || objectType === "machine"` เท่านั้น — object type อื่น (furniture, structure, sofa, interactive_barrier) วางชิดกำแพงแล้วไม่มีทางแก้เลยแม้แต่ manual

**Fix:** ขยาย `canWallMount` ให้ครอบคลุมทุก object type ยกเว้น `wall` และ `walkable_group` (สอง type นี้เป็น reference layer ของผนัง/พื้นเอง ไม่ใช่ object ที่วางติดผนัง — ไม่สมเหตุสมผลที่จะมี toggle นี้) backend ไม่ต้องแก้ (column ไม่เคยจำกัด type อยู่แล้ว)

**ไฟล์:** `zyra-app/views/admin/workspace-editor/components/object-context-menu.tsx`

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test**: context-menu บน object type ที่ไม่ใช่ decoration/machine (เช่น furniture), ยืนยันว่ามีตัวเลือก "Wall Mounted" ให้กด

---

## 11. (Bug) ลำดับ tile ไม่ตรงกับเลขคิวยกมือ (ตำแหน่งการ์ดสลับมั่ว)

**คำอธิบายภาษาชาวบ้าน:** เลขบน badge ยกมือ (✋1, ✋2 ...) ถูกต้องอยู่แล้ว แต่ตำแหน่งการ์ดบนหน้าจอไม่เรียงตามเลขนั้น — เช่น คนไม่ได้ยกมือ (n5) ดันอยู่คั่นกลางระหว่างคนที่ยกมืออันดับ 1 กับ 2 อยากให้: ตัวเราอยู่การ์ดแรกเสมอ ตามด้วยคนที่ยกมือเรียงตามเลขคิว (ถ้าตัวเราเป็นอันดับ 3 ในคิว คนอื่นก็ยังโชว์ 1,2,4,5 ตามจริง แค่ตัวเราขึ้นการ์ดแรกไม่ขยับ) ถ้ามีแชร์จอด้วย ให้แชร์จอเรียงต่อจากเรา แล้วตามด้วยคนยกมือ

> ✅ **แก้แล้ว (2026-07-21)** — บั๊กนี้แยกจาก item #5 ("ลำดับคิวยกมือไม่เลื่อน") ใน [`vo-meeting-issues-2026-07-21.md`](./vo-meeting-issues-2026-07-21.md) — อันนั้นคือเลข badge เอง (renumbering เมื่อวางมือ), อันนี้คือ**ตำแหน่งการ์ด**ไม่ตรงกับเลข badge ที่ถูกต้องอยู่แล้ว

**Root Cause (ยืนยันจากโค้ดจริง):** `zone-enter-panel.tsx` — `handNumberOf()` คำนวณอันดับคิวถูกต้องอยู่แล้ว (badge เลขถูก) แต่ `otherParticipants` (รายชื่อที่ใช้กำหนด**ตำแหน่งการ์ด**ทั้งใน expanded grid และ compact bar) comment ในโค้ดเดิมบอกตรงๆ ว่า "everyone else keeps their incoming order" — คือเรียงตามลำดับที่ข้อมูลส่งมา (join order/อื่นๆ) ไม่เกี่ยวกับ hand-raise rank เลย ทำให้ badge เลขถูก แต่ตำแหน่งการ์ดสลับมั่ว

**Fix:** เพิ่ม sort ให้ `otherParticipants` — คนที่ยกมืออยู่ (มี `handNumberOf` ไม่ null) มาก่อนเสมอ เรียงจากน้อยไปมากตามเลขคิวจริง ส่วนคนไม่ได้ยกมือเรียงตามลำดับเดิม (stable sort) ต่อท้าย — ครอบคลุมทั้ง expanded grid (`orderedParticipants`) และ compact bar (ใช้ `otherParticipants` ตรงๆ) เพราะทั้งคู่ derive จากตัวแปรเดียวกัน ไม่ต้องแก้แยก 2 จุด

**ไฟล์:** `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx`

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test**: จำลอง 3+ คนยกมือไม่เรียงลำดับการกด, ยืนยันว่าการ์ดเรียงจากซ้าย-ขวาตรงกับเลข badge เสมอ (self ก่อน แล้ว 1,2,3... ตามจริง)

---

## 12. (Feature/Bug) ยกมือหายไปทันทีที่เปิดไมค์ — ควรหายเมื่อเริ่มพูดจริงเท่านั้น

**คำอธิบายภาษาชาวบ้าน:** ยกมือแล้วเปิดไมค์ (ยังไม่ทันพูดอะไรเลย) มือก็หายไปแล้ว — อยากให้ตรวจจับว่าเปิดไมค์ **แล้วเริ่มพูดจริง** ค่อยให้ยกมือหาย

> ✅ **แก้แล้ว (2026-07-21)**

**Root Cause:** `use-meeting-media.ts` — `toggleMic()`'s success handler เดิม auto-lower hand ทันทีที่ `sfu.microphoneEnabled` เป็น `true` (มิคเปิดสำเร็จ) โดยไม่เช็คว่าพูดจริงหรือยัง — comment เดิมในโค้ดถึงกับเขียนไว้ตรงๆ ว่า "speaking implicitly answers the raise-hand queue" ซึ่งไม่จริง (เปิดไมค์ ≠ พูด)

**Fix:** ย้าย logic auto-lower ออกจาก mic-enable success handler ไปเป็น `useEffect` ที่ฟัง `speakingUserIds` แทน (มาจาก LiveKit's `activeSpeakersChanged` — real audio-level-based active-speaker detection ที่มีอยู่แล้วในระบบ ใช้ทำ speaking-border สีเขียวบน tile) — เมื่อ `selfUserId` โผล่ใน `speakingUserIds` (แปลว่าพูดจริงและมิคเปิดอยู่ ณ ขณะนั้น — LiveKit จะไม่ใส่คนที่มิคปิด/เงียบเข้า set นี้อยู่แล้ว จึงไม่ต้องเช็ค mic-on แยก) **และ** ยกมืออยู่ ค่อย auto-lower + ส่ง `ws:hand:changed`

**ไฟล์:** `zyra-app/views/user/virtual-office/use-meeting-media.ts`

**Verify:** `tsc`/`eslint` ผ่าน — **ยังไม่ live-test**: ยกมือ → เปิดไมค์ไม่พูดอะไร (มือต้องยังอยู่) → พูดจริง (มือต้องหายทันที)

---

## 13. (Feature ใหม่) Knock ได้รับอนุญาตแล้ว → เดินไปนั่งเก้าอี้ที่ว่างอัตโนมัติ (ไม่มีเก้าอี้ → ไปยืนจุดว่าง)

**คำอธิบายภาษาชาวบ้าน:** ตอนกดขอเข้า meeting (Ask permission) ถ้ามีคนรับเข้า ให้ตัวละครเดินไปนั่งเก้าอี้ที่ว่างอัตโนมัติ ถ้าไม่มีเก้าอี้ว่าง ให้ไปยืนจุดที่ว่างแทน

> ✅ **แก้แล้ว (2026-07-21)** — ฟีเจอร์ใหม่ ไม่ใช่ bug fix

**Research ก่อน implement:** สำรวจโค้ดเดิมก่อนสร้างใหม่ (ตาม [[09-component-reuse]]) พบว่า:
- ระบบที่ใช้งานจริงคือ **PixiJS engine** (`zyra-engine/pixi-game/scene.ts`) ไม่ใช่ Phaser (`zyra-engine/systems/sit.system.ts` เป็นของ `play-test.tsx` ที่ **deprecated แล้ว** — "The Virtual Office now uses the Canvas 2D system")
- flow `knock_granted` (`hero-virtual-office.tsx`) **มีอยู่แล้ว** และเรียก `playTestRef.current.walkToTile(x, y)` ไปที่ "จุดกึ่งกลางห้อง" อยู่แล้ว (2 จุดโค้ด: normal case + follow-mode) — งานคือแทนที่พิกัด "กึ่งกลางห้อง" ด้วย "เก้าอี้ว่างที่ใกล้ที่สุด"
- **เดินไปเก้าอี้ด้วย `walkToTile` แล้ว auto-sit ทันทีที่ถึง** อยู่แล้วในเอนจิ้น (ไม่ต้องเขียน sit-trigger ใหม่) ถ้า tile ปลายทางเป็นเก้าอี้ที่ลงทะเบียนไว้และไม่มีคนนั่งอยู่
- มี tie-break กันชนกัน (`_tickSeatYield`) ถ้า 2 คนเดินไปเก้าอี้เดียวกันพร้อมกันอยู่แล้วในเอนจิ้น
- `isTileSittable(x,y)` (เช็คว่า tile เป็นเก้าอี้) มี expose ออกมาแล้ว แต่ **`isTileWalkable` (เช็คว่า tile เดินได้) ไม่มี** — ต้องเพิ่มใหม่
- **ไม่มี** ฟังก์ชัน "หาเก้าอี้ว่างที่ใกล้ที่สุดในโซน X" หรือ "หา tile ว่างที่ใกล้ที่สุดในโซน X" มาก่อน — ต้องสร้างใหม่ แต่ประกอบจากของที่มีอยู่แล้วทั้งหมด (ไม่ต้องแก้ engine เพิ่มนอกจาก isTileWalkable)
- `lib/zone-utils.ts` มี `zoneTileSet()`/`zoneCenterPoint()` อยู่แล้ว (รองรับโซนไม่เป็นสี่เหลี่ยมด้วย) — reuse ได้เลยแทนเขียน tile-enumeration เอง

**Fix (3 จุด):**
1. เพิ่ม `isTileWalkable(tileX, tileY): boolean` ใน `PlayTestHandle` (mirror `isTileSittable` เดิมทุกจุด — type, engine impl อ่านจาก `blockedTiles` ที่มีอยู่แล้ว, wire ใน `pixi-canvas.tsx`)
2. เพิ่ม `findSeatOrStandTile()` ใน `utils/tile-helpers.ts` — รับ zone + ตำแหน่งปัจจุบัน + set ของ tile ที่มีคนอยู่ (`otherPlayersRef`) + query callbacks (`isTileSittable`/`isTileWalkable`) แล้วคืน tile ที่ควรเดินไป: เก้าอี้ว่างใกล้สุดก่อน → ถ้าไม่มีเลยหา tile เดินได้ว่างใกล้สุด → ถ้าไม่มีจริงๆ fallback กลับไปจุดกึ่งกลางห้อง (พฤติกรรมเดิมก่อนมีฟีเจอร์นี้)
3. แก้ `knock_granted` handler ทั้ง 2 จุด (normal case + follow-mode) ให้เรียก `findSeatOrStandTile()` แทนการคำนวณจุดกึ่งกลางตรงๆ

**ไฟล์:** `zyra-app/zyra-engine/types.ts`, `zyra-app/zyra-engine/pixi-game/scene.ts`, `zyra-app/components/game-canvas/pixi-canvas.tsx`, `zyra-app/views/user/virtual-office/utils/tile-helpers.ts`, `zyra-app/views/user/virtual-office/hero-virtual-office.tsx`

**ขอบเขตที่ตั้งใจไม่แก้:** มี "เดินไปกึ่งกลางโซน" แบบเดียวกันอยู่อีกอย่างน้อย 2 จุดในไฟล์ (ไม่เกี่ยวกับ knock — น่าจะเป็น flow เข้าห้องที่ไม่ล็อก/private zone claim) **ไม่แตะ** เพราะ user ระบุเฉพาะ flow "ขอ permission" เท่านั้น ถ้าต้องการให้ครอบคลุม flow อื่นด้วย ต้องบอกเพิ่ม

**Verify:** `tsc`/`eslint` ผ่านทั้งโปรเจกต์ — **ยังไม่ live-test**: ต้องมี ≥2 คนในห้อง (คนนึงมีเก้าอี้ว่าง), คนที่ 3 knock ขอเข้า → รับเข้า → ยืนยันเดินไปนั่งเก้าอี้ว่างอัตโนมัติ; ทดสอบซ้ำตอนเก้าอี้เต็มหมด → ยืนยันไปยืนจุดว่างแทน

### ⚠️ Regression พบหลัง deploy item 13: เดินเข้าไปแล้วเดินออกมาเอง

**อาการ:** หลัง knock ได้รับอนุญาต ตัวละครเดินเข้าไปในห้อง meeting (ตาม item 13) แต่แล้วเดินออกมาเองอีกครั้ง โดย user ไม่ได้สั่ง ต้อง user เดินเข้าไปใหม่เอง

**Root Cause (ยืนยันด้วย research agent):** เป็น **race condition ที่มีอยู่ก่อนแล้ว** ระหว่าง `knock_granted` (WS, มาถึงเร็ว) กับ `grantZoneSectionAccess` (REST call + DB write, ช้ากว่า) — เดิม `handleKnockAllow` (ฝั่งเจ้าของห้อง) ส่ง `knockDecision(true)` (→ requester ได้ `knock_granted`) **ก่อน** แล้วค่อย `await grantZoneSectionAccess()` ตามหลัง ทำให้ requester ได้รับ "granted" ก่อนที่ local `zoneSections`/`lockedZones` ของตัวเองจะอัปเดตเป็น unlocked จริง (ผ่าน `sectionSync` ที่ยิงหลัง REST เสร็จเท่านั้น)

โค้ดเดิม (ก่อน item 13) เดินไปที่ "กึ่งกลางห้อง" ซึ่งอยู่ไกล — บังเอิญให้เวลา REST round-trip เพียงพอเสมอที่จะ unlock ทันก่อนถึง แต่ item 13 เปลี่ยนเป็นเดินไปเก้าอี้/tile ที่ใกล้ที่สุด (มักใกล้ทางเข้า) — เดินถึงเร็วกว่าเดิมมาก จนบ่อยครั้งถึงก่อนที่ unlock state จะมาทัน ระบบ 2 จุดที่มีอยู่ก่อนแล้ว (ออกแบบมาเพื่อเตะคนที่ไม่มีสิทธิ์ออกจากห้อง) เลย auto-eject คนที่**เพิ่งได้รับอนุญาตจริง**ออกไปโดยไม่ตั้งใจ:
- Engine-level (per-frame ระหว่างเดิน): เจอ zone ยังอยู่ใน `lockedZones` → ยกเลิก path + เรียก `onZoneBlocked`
- React-level: `enterZoneSection()` REST คืน 403 (`zone_locked:true`) เพราะ DB ยังไม่ commit

ทั้งสองจุดเรียก `walkOutOfZone()` ที่มีอยู่แล้ว (เดิมออกแบบไว้สำหรับปฏิเสธคนไม่มีสิทธิ์จริงๆ)

**Fix (2 จุด):**
1. **แก้ต้นตอ:** สลับลำดับใน `handleKnockAllow` — ทำ `grantZoneSectionAccess()` (REST) + `sectionSync()` (broadcast) **ก่อน** แล้วค่อยส่ง `knockDecision(true)` (→ `knock_granted`) ทีหลัง เพื่อให้ requester ได้ unlock state พร้อมอยู่แล้วตั้งแต่ก่อนได้รับ granted
2. **แก้จุดเสี่ยงรอง:** `stepAwayFromOccupiedTile()` (ใช้ตอนเดินไปเจอคนยืนทับ tile เดียวกัน) เดิมเลือก tile หลบไม่เช็คว่ายังอยู่ในโซนเดิมไหม — เพิ่มเงื่อนไข `zoneContainsTile()` กันไม่ให้หลบออกนอกโซนที่เพิ่งเข้ามา (ความเสี่ยงนี้สูงขึ้นเพราะ item 13 เล็งไปที่ tile ที่มีคนอยู่ใกล้ๆ มากกว่าจุดกึ่งกลางโล่งๆ แบบเดิม)

**ไฟล์:** `zyra-app/views/user/virtual-office/hero-virtual-office.tsx`

**Verify:** `tsc`/`eslint` ผ่านทั้งโปรเจกต์ — **ยังไม่ live-test**: knock ขอเข้า → รับเข้า → ยืนยันว่าเดินเข้าไปนั่ง/ยืนแล้ว**ไม่เดินออกมาเอง**อีก (ทดสอบซ้ำหลายรอบเพราะเป็น race condition ขึ้นอยู่กับ timing เครือข่าย ไม่ใช่ deterministic 100%)

---

## Summary

| # | ประเภท | หัวข้อ | สถานะ |
|---|--------|--------|-------|
| 1 | Bug | Video grid ไม่ responsive, ไม่มี paging | ✅ แก้แล้ว (code) — ยัง live-test ไม่ได้ |
| 2 | Bug | ชื่อห้องทับหน้าจอแชร์ตอน fullscreen | ⚠️ แก้บางส่วน — root cause ยังไม่ยืนยัน 100% |
| 3 | Bug | Hover ห้องข้างๆ ทำ video หายหมด | ✅ แก้แล้ว (code) — ยัง live-test ไม่ได้ |
| 4 | Bug | ชื่อตัวละครไม่ตรงกับ Meeting Display | ✅ แก้แล้ว (code) — ยัง live-test ไม่ได้ |
| 5 | Bug/Research | Noise reduction "High" ไม่กันเสียงคนข้างๆ | ✅ gate tuning + เมนู RNNoise/VoiceFilter(coming soon) แยกกัน — ยัง live-test ไม่ได้ / ไม่แก้ "พูดพร้อมกัน" หายขาด |
| 6 | Bug | เสียงเบา + เอียงซ้าย | ✅ แก้แล้ว (code) — ยัง live-test ไม่ได้ |
| 7 | Bug | สลับ device mic แล้วพูดไม่ได้ | ✅ แก้แล้ว (code) — ยัง live-test ไม่ได้ |
| 8 | Bug | Capture หน้าจอได้ยินเสียงประชุม | ✅ แก้บางส่วน (a) / ⛔ (b) ข้อจำกัดแพลตฟอร์ม |
| 9 | Bug | Object ล่องหนใน editor ต้อง reload | ✅ แก้แล้ว (code) — ยัง live-test ไม่ได้ |
| 10 | Bug | Object วางแล้วอยู่หลังกำแพง | ✅ แก้แล้ว (code, ขยาย toggle) — ยัง live-test ไม่ได้ |
| 11 | Bug | ตำแหน่ง tile ไม่ตรงกับเลขคิวยกมือ | ✅ แก้แล้ว (sort ตาม hand rank) — ยัง live-test ไม่ได้ |
| 12 | Feature/Bug | ยกมือหายทันทีที่เปิดไมค์ (ควรหายตอนพูดจริง) | ✅ แก้แล้ว (ผูกกับ activeSpeakersChanged) — ยัง live-test ไม่ได้ |
| 13 | Feature ใหม่ | Knock ได้รับอนุญาต → auto-walk ไปนั่งเก้าอี้ว่าง/ยืนจุดว่าง | ✅ แก้แล้ว (findSeatOrStandTile ใหม่) + แก้ regression เดินออกเอง (race condition) — ยัง live-test ไม่ได้ |
