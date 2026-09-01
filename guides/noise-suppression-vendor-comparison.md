# เปรียบเทียบผู้ให้บริการตัดเสียงรบกวน (Noise Suppression / Voice Isolation)

> สถานะ: เอกสารประกอบการตัดสินใจ (สำหรับ PM นำเสนอ) · 2026-09-01
> กระทบ: `zyra-app` (client-side audio pipeline), `zyra-sfu` (self-hosted LiveKit)
> ต่อยอดจาก: `zyra-doc/issues/vo-meeting-and-editor-issues-2026-07-21-batch2.md` §5 (งานวิจัยรอบ 1–3)

---

## 1. สรุปสำหรับผู้บริหาร

**ปัญหาที่กำลังแก้มี 2 ระดับ และต้องแยกให้ขาด — เพราะราคาต่างกันคนละโลก**

| ระดับ | ตัวอย่างเสียง | เทคโนโลยีที่ต้องใช้ | สถานะของเรา |
|---|---|---|---|
| A. เสียงรบกวนทั่วไป | พัดลม แอร์ คีย์บอร์ด เสียงถนน | Noise Suppression (NS) | ✅ **มีแล้ว ใช้ของฟรี** (RNNoise + Speex + noise gate) |
| B. **เสียงคนอื่นพูดใกล้ ๆ** | เพื่อนร่วมโต๊ะคุยกัน เสียง TV คนพูด | **Voice Isolation / BVC** (คนละเทคโนโลยี) | ❌ **ยังแก้ไม่ได้ — ของฟรีไม่มีตัวไหนทำได้เลย** |

ข้อ B คือเรื่องที่ user ร้องเรียนซ้ำ ๆ ("กด High แล้วยังได้ยินเสียงคนข้าง ๆ") และเป็นเหตุผลเดียวที่ต้องพิจารณาจ่ายเงิน — **ไม่ใช่เพราะ RNNoise ไม่ดีพอ แต่เพราะ noise suppression ทุกตัวในโลกมองว่า "เสียงพูดของคนอื่น" ก็คือเสียงพูด จึงไม่ตัดให้**

**ข้อจำกัดสำคัญของเรา:** Zyra รัน SFU เอง (`zyra-sfu`) ไม่ได้ใช้ LiveKit Cloud → ตัวเลือกที่ผูกกับ LiveKit Cloud ใช้ไม่ได้ ยกเว้นจะยอมย้าย platform ทั้งก้อน

**ข้อสรุป 3 บรรทัด**
1. **Krisp (BVC ผ่าน JS SDK ตรง ๆ ไม่ผ่าน LiveKit)** = ตัวเลือกที่ตรงปัญหาที่สุด, proven ในตลาด (Discord/Zoom ใช้), ประมวลผลบนเครื่องผู้ใช้ทั้งหมด — **แต่ราคาไม่เปิดเผย ต้องคุย sales**
2. **ai-coustics (Quail Voice Focus)** = คู่เทียบที่จำเป็นต้องมี เพราะทำ speaker isolation ได้เหมือนกัน มี WebAssembly binding และ **ราคาเปิดเผยชัดเจน ($135–$540/เดือน)** ใช้ต่อรองกับ Krisp ได้
3. ที่เหลือ (Picovoice Koala, DeepFilterNet3, browser native) = ตัด noise ได้ดีขึ้นบ้าง แต่ **ไม่แก้ปัญหา B** — ถ้าจะจ่ายเงินเพื่อ B อย่าจ่ายให้กลุ่มนี้

---

## 2. ของที่ใช้อยู่ตอนนี้ (Baseline — ต้นทุน 0 บาท)

โค้ดจริง: [`zyra-app/lib/api/noise-processors.ts`](zyra-app/lib/api/noise-processors.ts)

```
ไมค์ → denoise (RNNoise | Speex) → makeup gain → noise gate → user volume → limiter
```

| ตัวเลือกใน UI | Engine จริง | ตัด noise ต่อเนื่อง | ตัดเสียงคนอื่นพูด |
|---|---|---|---|
| Off | ไม่มี (raw) | – | – |
| RNNoise · Medium / High | RNNoise (WASM) + noise gate | ✅ ดี | ❌ |
| VoiceFilter · Medium / High | Speex preprocessor + noise gate | ✅ พอใช้ | ❌ |

- ทุกอย่างรันในเบราว์เซอร์ผู้ใช้ (WASM) — ไม่มีค่าใช้จ่ายต่อนาที ไม่มีเสียงออกนอกเครื่อง
- License: MIT/BSD (ใช้เชิงพาณิชย์ได้ ไม่มีเงื่อนไข)
- Native `noiseSuppression` ของเบราว์เซอร์ถูก **ปิดไว้ตั้งใจ** เพื่อไม่ให้ซ้อนทับกับ RNNoise
- **ความต่างของ Medium/High คือความไวของ noise gate เท่านั้น** ไม่ใช่ความแรงของ AI (RNNoise ไม่มีปุ่มปรับความแรง)

---

## 3. เกณฑ์ตัดสิน

| # | เกณฑ์ | ทำไมสำคัญกับ Zyra |
|---|---|---|
| 1 | **ตัดเสียงคนอื่นพูดได้ไหม** | นี่คือปัญหาจริงข้อเดียวที่ยังแก้ไม่ได้ ข้ออื่นเป็นของแถม |
| 2 | ใช้กับ **self-hosted SFU** ได้ไหม | ถ้าไม่ได้ = ต้องย้าย platform (งานใหญ่ + ค่าใช้จ่ายอีกก้อน) |
| 3 | รันใน **เบราว์เซอร์ (WASM)** ได้ไหม | Zyra เป็นเว็บล้วน ไม่มี desktop app |
| 4 | CPU / latency | VO รัน Pixi renderer + WebRTC อยู่แล้ว เครื่องผู้ใช้มีงบ CPU จำกัด |
| 5 | ราคา + โมเดลคิดเงิน | ต่อนาที / ต่อ seat / ต่อปี — ผลต่อ margin ตอน scale |
| 6 | ความเป็นส่วนตัว | on-device (ไม่ส่งเสียงขึ้น cloud) ขายลูกค้าองค์กรง่ายกว่ามาก |
| 7 | แรงงาน integrate | เรามี `TrackProcessor` interface อยู่แล้ว ตัวที่เสียบเข้า pipeline เดิมได้ = ถูกที่สุด |

---

## 4. ตารางเปรียบเทียบหลัก

| เจ้า | ตัด noise | **ตัดเสียงคนอื่น** | รันที่ไหน | ใช้กับ SFU เราได้ | ราคา | License |
|---|---|---|---|---|---|---|
| **Krisp JS SDK** (NC + BVC) | ✅ ดีมาก | ✅ **ได้ (BVC)** | เบราว์เซอร์ (WASM) on-device | ✅ **ได้** (license ตรงกับ Krisp) | ❓ ไม่เปิดเผย — ต้องคุย sales | เชิงพาณิชย์ |
| **ai-coustics** Real-Time SDK (Rook / Quail Voice Focus) | ✅ ดีมาก | ✅ **ได้ (Voice Focus)** | WASM / native / server | ✅ ได้ | 💲 $135–$540/เดือน (รายปี) + overage | เชิงพาณิชย์ |
| LiveKit Cloud Enhanced NC (Krisp + ai-coustics) | ✅ ดีมาก | ✅ ได้ (voice isolation) | ฝั่ง LiveKit Cloud | ❌ **ต้องย้ายไป LiveKit Cloud** | Plan $50–$500/เดือน + voice isolation $0.0012/นาที | เชิงพาณิชย์ |
| Picovoice **Koala** | ✅ ดี (ดีกว่า RNNoise) | ❌ | เบราว์เซอร์ (WASM) on-device | ✅ ได้ | ฟรี 100 นาที/เดือน, เกินนั้นต้องคุย sales | เชิงพาณิชย์ + ต้อง AccessKey ต่อเน็ตเช็ค |
| **DeepFilterNet3** | ✅ ดี (ดีกว่า RNNoise ชัดเจน) | ❌ | เบราว์เซอร์ (WASM) | ✅ ได้ | **ฟรี** | MIT / Apache-2.0 |
| RNNoise *(ปัจจุบัน)* | ✅ พอใช้ | ❌ | เบราว์เซอร์ (WASM) | ✅ ใช้อยู่ | **ฟรี** | MIT/BSD |
| Speex *(ปัจจุบัน)* | 🟡 พื้นฐาน | ❌ | เบราว์เซอร์ (WASM) | ✅ ใช้อยู่ | **ฟรี** | BSD |
| Browser native (`noiseSuppression`) | 🟡 พื้นฐาน | ❌ | เบราว์เซอร์ | ✅ ได้ (ปิดไว้อยู่) | **ฟรี** | – |
| Browser `voiceIsolation` constraint | ✅ (ถ้ารองรับ) | 🟡 บางส่วน | OS/ฮาร์ดแวร์ | ✅ ได้ | **ฟรี** | – · ⚠️ ตอนนี้ใช้ได้จริงแค่ ChromeOS บางรุ่น |
| NVIDIA Maxine / RTX Voice | ✅ ดีมาก | 🟡 | ต้องมี **การ์ดจอ NVIDIA + แอปติดตั้ง** | ❌ ใช้ในเว็บไม่ได้ | ฟรี (ผูกฮาร์ดแวร์) | – |
| Adobe Podcast / Cleanvoice / ElevenLabs | ✅ ดีมาก | 🟡 | Cloud, **หลังอัดเสร็จ** | ❌ **ไม่ใช่ real-time** | รายเดือน | – |

> **หมายเหตุสำคัญ:** ห้ามเปิดหลายตัวซ้อนกันบนเสียงเดียว (LiveKit เตือนเรื่องนี้ตรง ๆ) — เลือกใช้ตัวเดียวเสมอ นี่คือเหตุผลที่เราปิด native `noiseSuppression` ไว้อยู่แล้ว

---

## 5. เจาะลึก Krisp

### 5.1 Krisp มี 3 โมเดล — อย่าสับสน

| โมเดล | ทำอะไร | มีบน Web (JS/WASM) ไหม |
|---|---|---|
| **NC** (Noise Cancellation) | ตัดเสียงรบกวนทั่วไป | ✅ มี |
| **BVC** (Background Voice Cancellation) | **ตัดเสียงคนอื่นที่พูดอยู่รอบ ๆ เหลือแต่เสียงคนหลัก** | ✅ **มี — และมีเฉพาะบน JS/Web SDK เท่านั้น** |
| **VIVA** (Voice Isolation for Voice Agents) | สำหรับ voice AI agent (turn/interruption prediction) | ❓ เอกสารเน้นฝั่ง server pipeline |

> 🔑 **จุดที่พลิกการตัดสินใจ:** ตอนแรกเราสรุปว่า "Krisp ใช้ไม่ได้เพราะต้องมี LiveKit Cloud" — **ข้อนั้นจริงเฉพาะกับ package `@livekit/krisp-noise-filter` ของ LiveKit เท่านั้น** ถ้า license กับ Krisp โดยตรง (`sdk-docs.krisp.ai`) จะได้ JS SDK ที่เสียบเข้า Web Audio / WebRTC ของเราเองได้ **ไม่ต้องพึ่ง LiveKit Cloud เลย** และ BVC ก็อยู่บน SDK ตัวนี้พอดี

### 5.2 สเปกจากเอกสาร Krisp

| หัวข้อ | ค่า |
|---|---|
| การประมวลผล | **บนเครื่องผู้ใช้ 100%** — ไม่มีการต่อ server ของ Krisp, เสียงไม่ถูกส่ง/เก็บบน cloud |
| Latency | ~1.5–2 ms ต่อเฟรม (เฟรมละ 10 ms) |
| ขนาดแพ็กเกจ | ~12 MB · ใช้ RAM ~100 MB ตอนทำงาน |
| Sample rate | 8 / 16 / 24 / 32 / 44.1 / 48 / 88.2 / 96 kHz |
| เบราว์เซอร์ | Chrome, Firefox, Edge (Safari มีข้อจำกัดเรื่อง 8 kHz stream) |
| CPU | สูงกว่า native SDK (รันใน worker thread เพื่อความเสถียร) |
| ความน่าเชื่อถือ | เทคโนโลยีเดียวกับที่อยู่ในอุปกรณ์ 200 ล้านเครื่อง, ประมวลผลเสียง >75 พันล้านนาที/เดือน |

### 5.3 ข้อควรระวังของ Krisp

- ⚠️ **BVC ต้องใช้หูฟัง** — ทำงานดีที่สุดกับ headset มีบูมไมค์ (มี "allowed device list" ในตัว SDK) ถ้า user ใช้ไมค์ลำโพงโน้ตบุ๊ก BVC จะไม่ทำงานเต็มที่ **ต้องสื่อสารกับ user ให้ชัด ไม่งั้นจะกลายเป็นเรื่องร้องเรียนรอบใหม่**
- ⚠️ **ราคาไม่เปิดเผย** — ราคาที่เห็นในเว็บ ($8–16/เดือน) คือแอปสำหรับผู้ใช้ทั่วไป **ไม่ใช่ราคา SDK** ต้องยื่น "Request SDK Access" แล้วรอ sales
- ⚠️ **+12 MB ต่อการโหลด** — ต้อง lazy-load เฉพาะตอนเข้า VO เท่านั้น (pattern เดียวกับที่ `sfu-client.ts` ทำกับ livekit-client อยู่แล้ว)
- ⚠️ CPU สูงกว่าของเดิม — ต้องวัดจริงบนเครื่อง spec ต่ำก่อนตัดสินใจ

---

## 6. Krisp vs ai-coustics (คู่ชิงตัวจริง)

| ประเด็น | **Krisp** | **ai-coustics** |
|---|---|---|
| โมเดลที่ตัดเสียงคนอื่นได้ | BVC | Quail Voice Focus 2.1 |
| Web / WASM | ✅ (BVC มีเฉพาะบน JS SDK) | ✅ มี binding WebAssembly อย่างเป็นทางการ |
| Latency | ~1.5–2 ms/เฟรม (เฟรม 10 ms) | ~30 ms end-to-end |
| ประสิทธิภาพ | รันบน CPU ได้ | 2.1 S เล็กลง 10 เท่าจาก 2.0 · 2.1 L ใช้ compute ลดลง 25% |
| **ราคา** | ❓ ไม่เปิดเผย ต้องคุย sales | ✅ **เปิดเผย: $135 / $360 / $540 ต่อเดือน** (จ่ายรายปี) ตามโควตานาที |
| ความสุกของสินค้า | สูงมาก — มาตรฐานอุตสาหกรรม ใช้กันแพร่หลาย | ใหม่กว่า แต่มี integration กับ LiveKit อย่างเป็นทางการ |
| จุดขายรอง | privacy on-device เต็มรูปแบบ | มี integration สำเร็จรูปกับ LiveKit / Pipecat, ทดลองผ่าน playground ได้ทันที |
| ทดลองก่อนซื้อ | ต้องขอ SDK access | ทดลอง SDK ฟรี 30 วัน + playground ออนไลน์ |
| ความเสี่ยง | ราคาอาจสูงเกินงบและรู้ช้า | latency สูงกว่า, ยังต้องยืนยันว่า WASM รัน Voice Focus ได้จริงในเบราว์เซอร์ |

> **ท่าที่แนะนำ:** เอา ai-coustics เป็น **ตัวตั้งราคา** (เพราะโปร่งใส) แล้วใช้ตัวเลขนั้นคุยกับ Krisp — ทั้งคู่มีทดลองใช้ฟรี ให้ **ทดสอบพร้อมกันในห้องประชุมจริง** แล้วค่อยตัดสินด้วยหูของทีม ไม่ใช่ด้วยโบรชัวร์

---

## 7. ประมาณการค่าใช้จ่าย

**สมมติฐาน:** คิดเฉพาะ "นาทีที่เปิดไมค์จริง" 22 วันทำการ/เดือน

| สถานการณ์ | ผู้ใช้พร้อมกัน | ชม./วัน | นาที/เดือน |
|---|---|---|---|
| S1 — ปัจจุบัน | 20 | 4 | 105,600 |
| S2 — โต | 50 | 5 | 330,000 |
| S3 — เป้าหมาย | 150 | 5 | 990,000 |

| ทางเลือก | S1 | S2 | S3 |
|---|---|---|---|
| **คงของเดิม (RNNoise/Speex)** | **$0** | **$0** | **$0** |
| **DeepFilterNet3** (อัปเกรดฟรี) | **$0** | **$0** | **$0** |
| **ai-coustics** | ~$143/เดือน (Startup + overage) | ~$401/เดือน (Pro + overage) | ~$1,128/เดือน (Business + overage) → ควรคุย Enterprise |
| **Krisp** | ❓ | ❓ | ❓ |
| **ย้ายไป LiveKit Cloud** | ~$176/เดือน (Ship + voice isolation) | ~$884/เดือน (Scale) | ~$1,676/เดือน (Scale) **+ ต้องทิ้ง SFU ที่ลงทุนไปแล้ว** |

- ai-coustics: ราคารายปี $135/$360/$540 (100k/300k/500k นาที) · จ่ายรายเดือนแพงกว่า ($149/$399/$599) · overage ~$0.0012–0.0015/นาที
- LiveKit Cloud: **background noise suppression รวมอยู่ในแพ็กแล้ว** แต่ **voice isolation (ตัวที่แก้ปัญหาเรา) คิดเพิ่ม $0.0012/นาที** และ Krisp BVC บน LiveKit เริ่มมีค่าใช้จ่ายเพิ่มตั้งแต่ 1 พ.ค. 2026
- ตัวเลขทั้งหมดเป็นค่า list price ยังไม่รวมส่วนลดจากการเจรจา

---

## 8. ความเสี่ยงที่ต้องบอก PM ล่วงหน้า

| ความเสี่ยง | ผลกระทบ | การรับมือ |
|---|---|---|
| BVC/Voice Focus ต้องใช้หูฟัง | user ที่ใช้ไมค์โน้ตบุ๊กจะยังบ่นเหมือนเดิม | สื่อสารในหน้า setting + แนะนำ headset ตั้งแต่ onboarding |
| CPU เพิ่มบนเครื่องสเปกต่ำ | VO เป็น Pixi + WebRTC อยู่แล้ว อาจกระตุก | ทดสอบบนเครื่องต่ำสุดที่ support ก่อนตัดสิน + ให้ปิดได้ |
| ขนาดไฟล์ +12 MB | โหลดหน้าแรกช้าลง | lazy-load เฉพาะตอนเข้า VO เท่านั้น |
| ราคาผูกกับ "นาที" | ค่าใช้จ่ายโตตามการใช้งาน ไม่ใช่ตามจำนวนลูกค้า | ต่อรองเป็น flat/seat-based, และเปิดฟีเจอร์เฉพาะ workspace ที่จ่ายเงิน |
| Vendor lock-in | เปลี่ยนเจ้ายาก | เขียนหลัง `MicProcessor` interface เดิม เพื่อสลับ engine ได้ |
| ราคา Krisp รู้ช้า | plan งบไม่ได้ | เริ่มติดต่อ sales **ตั้งแต่สัปดาห์นี้** — เป็น long-lead item |

---

## 9. ข้อเสนอ — ทำเป็น 3 เฟส

**เฟส 1 (ทำได้เลย, ฟรี, ~2–3 วันงาน)** — เปลี่ยน/เพิ่ม **DeepFilterNet3** แทน/คู่กับ RNNoise
คุณภาพการตัด noise ดีกว่า RNNoise ชัดเจน (PESQ ~3.5–4.0 เทียบ ~3.88 ของ RNNoise แต่ handle เสียงซับซ้อนได้ดีกว่ามาก), MIT/Apache ใช้เชิงพาณิชย์ได้, เสียบเข้า `MicProcessor` เดิมได้ตรง ๆ
→ **ไม่แก้ปัญหา B แต่ยกระดับ A ทันทีโดยไม่ต้องรออนุมัติงบ**

**เฟส 2 (ขนานกัน, งาน business)** — ติดต่อ **Krisp** และ **ai-coustics** พร้อมกัน ขอ trial ทั้งคู่
→ ทดสอบ A/B ในห้องประชุมจริงที่มีคนคุยกันข้าง ๆ วัด 3 อย่าง: คุณภาพเสียงที่ปลายทาง, CPU, latency

**เฟส 3 (หลังได้ราคา)** — ตัดสินใจซื้อ แล้วเปิดเป็นฟีเจอร์ระดับ premium ของ workspace ที่จ่ายเงิน เพื่อให้ค่าใช้จ่ายต่อนาทีมีรายได้รองรับ

**สิ่งที่ไม่แนะนำ:** ย้ายไป LiveKit Cloud เพื่อให้ได้ noise cancellation อย่างเดียว — แพงกว่า, ต้องทิ้งงาน SFU ที่ลงทุนไปแล้ว, และได้ผลลัพธ์เท่ากับ license Krisp ตรง ๆ

---

## 10. คำถามที่ต้องถาม sales (checklist สำหรับ PM)

**ถามทั้ง Krisp และ ai-coustics:**
1. ราคาโมเดลไหน — ต่อนาที / ต่อ seat / flat รายปี? มีขั้นต่ำไหม?
2. โมเดลที่ตัดเสียงคนอื่นได้ (BVC / Quail Voice Focus) **รันในเบราว์เซอร์ผ่าน JS/WASM ได้จริง** สำหรับ use case "ประชุมคนกับคน" ไม่ใช่แค่ AI agent ใช่ไหม?
3. ใช้กับ **self-hosted LiveKit SFU** ได้โดยไม่ต้องซื้อบริการอื่นเพิ่มใช่ไหม?
4. ขอ trial license เพื่อวัดผลจริงกับระบบเรา — ระยะเวลาและโควตาเท่าไร?
5. ต้องใช้อุปกรณ์แบบไหนถึงจะได้ผลเต็มที่ (headset เท่านั้นหรือเปล่า) และมี device list ไหม?
6. CPU ที่ใช้จริงบนเครื่องสเปกต่ำ (โน้ตบุ๊กออฟฟิศทั่วไป) ประมาณเท่าไร?
7. เสียงถูกส่งออกนอกเครื่องผู้ใช้หรือไม่ (ข้อนี้ต้องได้คำตอบเป็นลายลักษณ์อักษรเพื่อใช้ตอบลูกค้าองค์กร)

---

## แหล่งอ้างอิง

- Krisp Web/JS SDK — https://sdk-docs.krisp.ai/docs/introduction · BVC integration — https://sdk-docs.krisp.ai/docs/background-voice-cancellation-integration
- LiveKit noise cancellation docs — https://docs.livekit.io/transport/media/noise-cancellation/ · pricing — https://livekit.com/pricing
- ai-coustics — https://ai-coustics.com/pricing · https://docs.ai-coustics.com/ · Quail Voice Focus 2.1 — https://ai-coustics.com/blog/quail-voice-focus-2.1
- Picovoice Koala — https://picovoice.ai/platform/koala/ · pricing — https://picovoice.ai/pricing/
- DeepFilterNet — https://github.com/Rikorose/DeepFilterNet
- Chrome VoiceIsolation constraint — https://chromestatus.com/feature/5106413661847552
