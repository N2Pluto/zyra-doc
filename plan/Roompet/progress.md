# Room Pet — Progress

> log ต่อรอบ (entry ใหม่ไว้บนสุด) · รูปแบบตาม [zyra-doc/README.md § อัปเดตความคืบหน้า](../../README.md)
> สถานะรวมอยู่ที่ blockquote หัว [spec.md](spec.md) · ความพร้อมของ dependency ดู [spec.md § ความพร้อม](spec.md)
>
> ## 🔖 มาทำต่อตรงนี้ (อัปเดต 2026-09-06 รอบ 33 — รายละเอียดล่าสุดอยู่รอบ 30–33)
>
> **จาก 7 งานที่เหลือ ปิดไป 5 · ค้าง 2** (office-time re-verify ผ่านแล้ว 20:01):
> 1. **เทส UI ในเบราว์เซอร์** — ยังติดเรื่องเดิม: AI พิมพ์รหัสผ่านลงฟอร์มไม่ได้ · session เป็น httpOnly `refresh_token` cookie ฉีด token ไม่ได้ · **Browser pane เป็นคนละ browser กับ Chrome ปกติ** ต้อง login ใน pane นั้น
> 2. **`pet_sittable`** — ไม่ได้เริ่ม กระทบ 4 repo + ต้องเคาะ design 2 ข้อก่อน (ดูรอบ 25 § ไม่ได้ทำ)
>
> **ของที่ตั้งค้างไว้ให้ (ตั้งใจ ไม่ใช่ขยะ):**
> - pet **Mochi Live** (ws `256893ae`, member-a) = baby ที่ tile (60,3) — XP ดูใน DB (ขยับตามการเทส office-time รอบ 25) · คืนค่าเดิม: `UPDATE tb_room_pet SET xp=0,last_seen_stage='egg',last_milestone=0`
> - pet **เจ้าปรื๊ด** (ws `34ffa741`, ของ user) = baby / 150 XP ที่ Floor 1 → ห้อง `test` → (60,39)
> - โฟลเดอร์ปลายทางของภาพ: `zyra-new/storage/preview/` · แผนเก็บภาพ 9 ไฟล์อยู่ในรอบ 21
>
> **migration ที่รันบน dev DB แล้ว (ล่าสุด):** 91 `tb_room_pet_achievement` · 92 `tb_message.content_type` + `'pet_card'` · 93 `tb_notification.room_pet_id`
>
> **ทุก repo อยู่บน develop สะอาด ไม่มี PR ค้าง** — api (#92) · ws (#54) · app (#311) — รอบ 26–70 · flow ตอนข้าม stage อ่านที่ [evolution-flow.md](evolution-flow.md)
> **⚠️ local ของ user (2026-09-06 กลางคืน):** checkout หลัก `zyra-app` ค้างที่ `eda36ae` (#257 — ก่อน Room Pet รอบ 26–42 ทั้งหมด) และ user รัน api/ws/app เองจาก checkout หลัก → อาการ "ฉากหลังไม่โหลด" ที่เห็นคืนนี้น่าจะเป็นบั๊กเก่าของ commit นั้น (regression 3dd45b6 ที่แก้ไปแล้วรอบ 27) — ต้อง `git pull` develop ทั้ง 3 repo แล้ว build ใหม่ก่อนเทส · migration ล่าสุดบน dev: **95** (`tb_pet_animation.frame_rate` 8 → 6)
> **local ของ user ตอนนี้:** `.env` ของ zyra-app ต้องมี `NEXT_PUBLIC_ROOM_PET=true` (build-time) ไม่งั้น pet ไม่วาดเลย — ผมเพิ่มไว้ใน worktree ที่ build เท่านั้น ฝาก user เพิ่มใน checkout หลัก
> **คำถามใหม่ให้ PM (รอบ 37):** obstacle grid เป็นต่อ workspace จาก main floor (`is_main DESC`) — pet (และคน) ที่อยู่ floor อื่นถูกเช็คกับเฟอร์นิเจอร์ของ main floor · ต้องทำ grid ต่อ floor ไหม

---

## 2026-09-07 (รอบ 70) — ลดความไวของ animation จาก 8 เป็น 6 เฟรม/วินาที

- **user บอก:** "ลด ความไวหน่อย ได้มั้ย เฟรม จาก 8 เฟรม เป็น 6 เฟรม"
- **ทำ api [#92](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/92):** `PetFrameRateDefault` 8 → 6 (ค่าตั้งต้นของฟอร์มอัปโหลดใน Pet Management) + **migration 95** ปรับแถวเดิม `UPDATE tb_pet_animation SET frame_rate = 6 WHERE frame_rate = 8 AND stage <> 'egg'` · **ไข่ไม่แตะ** (สั่นที่ 16 ผ่าน `PetFrameRateForStage`) · มี `.down.sql` คู่
- **ทำ app [#311](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/311):** ค่า fallback ใน `buildScenePets` ย้ายเป็น `PET_DEFAULT_FRAME_RATE = 6` ให้ตรงกับฝั่ง API (ค่าจริงมาจาก DB)
- **รันบน dev DB แล้ว: `UPDATE 185`** — adult 60 · baby 65 · evolved 60 แถว (egg 8 fps 4 แถว / 16 fps 23 แถว คงเดิม) · **ยังไม่ได้รันบน uat/prod**
- **verify:** api go build/vet/test ./... เขียว · app vitest 1751 เขียว · eslint/prettier/tsc สะอาด · **ยังไม่ได้ดูใน VO จริง** — ต้อง rebuild app (ค่าอยู่ใน DB แล้ว)
- **migration ล่าสุดบน dev: 95**

---

## 2026-09-07 (รอบ 69) — ยืนซ้อนตัวละครตอนนั่ง · หันหน้าตามจากไกล · สไลด์ไปกับพื้น · สวิตช์ notification

- **user บอก (3 เรื่อง + 1 คำถาม):** "ตอนที่นั่งอยู่บนเก้าอี้ แล้วมี pat ตามมา มันจะยืนซ้อนตัวกัน" · "อยู่ไกลมากแต่ pat หันหน้าตาม ต้องเกิด pop pat ก่อนถึงจะหันหน้าตาม" · "ยังเห็น pat แสดงท่าทางอื่นแล้วเคลื่อนที่ เหมือนสไลด์ไปกับพื้น" · "ปิด Notification ของสัตว์เลี้ยง … ทำงานได้ปกติมั้ย"

### 1. ยืนซ้อนตัวละคร (ws [#54](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/54))
คนไม่หลบ pet — มีแต่ pet หลบคน กฎ "มีคนยืนทับ → ขยับหลบ" มีตั้งแต่รอบ 55 แต่ใช้ `startWalk` ที่บังคับให้ปลายทาง**อยู่ในห้องของ pet** ตอนพาเดินเล่น pet อยู่นอกห้องเสมอ ทุกช่องรอบตัวจึงถูกปฏิเสธ → ติดใต้คนที่มานั่งทับถาวร · แก้: ตอน follow/returning ใช้ `walkTo` + `tileFree` (ไม่ผูกกับห้อง) maxSteps 2 เพื่อไม่ให้เดินเฉียง

### 2. หันหน้าตามจากไกล (ws [#54](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/54))
`petNoticeRadius` 3 ช่องถูกใช้ทั้ง "สังเกตเห็น" และ "หันหน้า" · แยกออกเป็น `petFaceRadius` 1 + `petFaceDwell` 1 วิ = กฎเดียวกับ pop ฝั่ง client (`PET_STROKE_RANGE_TILES` / `PET_LINK_DWELL_MS`) · dwell รีเซ็ตเมื่อใครเปลี่ยนช่อง เหมือน client · การ "สังเกตเห็น" (หยุดเดินเล่น / เดินเข้าหาคนที่ยืนนิ่ง) ยังเป็น 3 ช่อง

### 3. สไลด์ไปกับพื้น (app [#309](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/309))
ผลข้างเคียงของ interpolation buffer รอบ 67: engine เดินตามหลัง server 1 จังหวะ state "หยุด" (พร้อม sheet ท่านั่ง) จึงมาถึงตอน sprite ยังมีช่องเหลือให้เดิน · แก้ด้วย `petVisualHold` — ระหว่าง glide คงใช้ sheet ที่ออกเดินมา คงเฉพาะ "หน้าตา" ช่องปลายทาง/mood ยังใช้ค่าล่าสุด

### 4. สวิตช์ Notification ของสัตว์เลี้ยง (app [#309](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/309))
ตรวจทั้งเส้นทาง: แถวกระดิ่ง + push + เตือน 09:00 **เคารพสวิตช์อยู่แล้ว** (กรองใน SQL `COALESCE(notification_settings->>'pet_activity','true') <> 'false'` ที่ `notification_pet.go:104`, `:240`) · อีเมล digest ไม่เกี่ยว (แถว pet insert เป็น `email_suppressed = true`) · pet ไม่มี toast · **แต่หน้าจอ "Your Pet Evolved" เต็มจอไม่เคารพเลย** เพราะขี่มากับ broadcast `pet_stage_changed` ที่ยิงทั้ง workspace ไม่มี hook รายคน → กรองฝั่ง server ไม่ได้ · แก้ด้วย `petGrowthMayInterrupt({isResident, notificationsOn})` ที่ client + เรียก `hydrate()` ตอนเข้า VO (เดิม store โหลดค่าจริงเฉพาะตอนเปิดหน้า Settings จึงเสิร์ฟ default = เปิด ตลอด)

**เจอระหว่างตรวจ ยังไม่แก้ (นอกขอบเขต):** คีย์อื่นทั้งหมดในแท็บ Notifications (`thread_replies`, `joining_circle`, `hide_chat_in_meeting`, `event_*` 5 ตัว) บันทึกลง DB แต่**ไม่มีโค้ดไหนอ่านเลย** — `pet_activity` เป็นคีย์เดียวที่มีการบังคับใช้จริงในทั้งสองโค้ดเบส · และแถวกระดิ่ง pet ส่งให้สมาชิก workspace ทุกคน ขณะที่หน้าจอ growth เห็นเฉพาะสมาชิกห้อง (คนที่ไม่ใช่สมาชิกห้องได้แถวกระดิ่งเรื่อง pet ที่ตัวเองยุ่งด้วยไม่ได้)

- **verify:** ws go build/vet/test เขียว — เทสใหม่ `TestPetFollow_ShufflesAsideWhenSomeoneSitsOnIt` (ยืนยันว่า fail จริงบนโค้ดเก่า) และ `TestPetStep_TurnsToFaceOnlyOnceAPopHasFormed` + ปรับเทสเดิม 4 ตัวที่ยึดกฎหันหน้าแบบเก่า · app vitest 1751 เขียว (เทสใหม่ `petVisualHold` 4 กรณี + `petGrowthMayInterrupt` 3 กรณี) · eslint/prettier สะอาด · **ยังไม่ได้ดูใน VO จริง**

---

## 2026-09-07 (รอบ 68) — ยังสะดุดตอนกดวิ่ง: pet เดิน 1 ช่องต่อ 2 tick มาตลอด

- **user บอก:** "ลองใหม่แล้ว ยังสะดุดอยู่ตอนกดเพื่อวิ่งไว ให้มัน smooth กว่านี้ ไม่มีแบบสะดุดเลย"
- **ต้นตอจริง (เพิ่งเจอรอบนี้ — รอบ 64–67 แก้ถูกทางแต่ไม่ถึงราก):** `followStep` คิวทีละ 1 ช่อง เดินจบแล้ว `stepNow` ตั้ง `arriveAt` → **tick ถัดไปทั้ง tick ถูกใช้ไปกับการรายงาน "arrived"** ไม่เดินเลย → pet ขยับจริง **1 ช่อง / 2 tick = 400 ms ต่อช่อง** แต่บอก client ว่าช่องละ ~80 ms · client จึงเดิน 80 ms แล้ว**ยืน 320 ms** ทุกช่อง = อาการสะดุด และตอนวิ่งยิ่งหนักเพราะระยะห่างที่ไล่ไม่ทันโตขึ้นจนชน trail cap แล้วลัดทาง
- **ต้นตอรอง:** วัด pace ผู้นำต่อ **tick** ไม่ใช่ต่อ **ช่อง** — คนวิ่งข้าม 2–3 ช่องใน 1 tick จึงถูกอ่านว่าเดินช่องละ 200 ms (จริง ~89) · และ `petFollowMinStepMs` 90 > ความเร็ววิ่ง 89 → ต่อให้รู้ความเร็วก็ไล่ไม่มีวันทัน
- **ทำ ws [#53](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/53):** เติมเส้นทางจาก trail **ในลูป step** (การเดินตาม = การเดินต่อเนื่องครั้งเดียว) · ไม่รายงาน "หยุด" ระหว่างที่ผู้นำยังเดิน (grace 400 ms — เดิมทำให้ client สลับเป็นท่ายืนและเริ่ม glide ใหม่ทุกสองสามช่อง) · วัด pace ต่อช่อง · `petFollowMinStepMs` 90 → 70 · `petFollowMaxStepsPerTick` 3 → 4 · เก็บเศษเวลา 1 step แทนทิ้งทุก tick
- **ทำ app [#307](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/307):** `PET_GLIDE_MIN_STEP_MS` 90 → 70 (ให้ตรงกับ ws) · การเร่งไล่คิวเดิมเป็น "ขั้น" (เกิน 3 ช่องกระโดดไปเพดานทันที) เปลี่ยนเป็นทางลาด 8 % ต่อช่อง เพดาน 1.35×

### Before/After

| Metric | Before | After | Δ |
|---|---|---|---|
| เฟรมที่ sprite ยืนนิ่งระหว่างเดินตาม | 76.2 % | 3.9 % | −95 % |
| ความแปรปรวนความเร็วบนจอ (CV) | 1.87 | 0.21 | −89 % |
| ระยะที่เดินได้ใน 8 วินาที | 19 ช่อง | 97 ช่อง | ×5.1 |
| ระยะห่างสูงสุดจากคนที่วิ่ง (30 tick) | 86 ช่อง | 1 ช่อง | −98 % |
| pace ที่บอก client เทียบ pace จริง | 80 ms vs 400 ms | ต่างกัน < 25 % | — |

**วัดยังไง**: 3 แถวแรก = replay harness ใน vitest ป้อน state stream ของ ws (tick 200 ms) ผ่าน React beat 250 ms เข้า `PetLayer` จริง 8 วินาที แล้ว sample ตำแหน่ง sprite ทุก 16 ms · 2 แถวหลัง = go test จำลอง 30 tick ตามคนวิ่ง 89 ms/ช่อง
**ช่วงเวลาที่วัด**: จำลอง ไม่ใช่ prod — ยังไม่มี metric ของ pet บน Grafana

- **verify:** ws `go build` / `go vet` / `go test ./internal/hub` ✅ (เทสใหม่ 3 ตัว: ตามคนวิ่งทัน, วัด sprint ต่อช่อง, ไม่มี "หยุด" ระหว่างขาเดิน) · app vitest 1747 ✅ (เทสใหม่: สตรีมตามคนวิ่ง 6 วิ ยืนนิ่ง < 10 % ของเฟรม) · eslint/prettier สะอาด · `tsc --noEmit` มี error เดิม 3 ตัวในไฟล์เทสที่ไม่ได้แตะ (pet-creation-wizard, pixi-game-scene) · **ยังไม่ได้ดูใน VO จริง** — rebuild ws + app
- **ต่อจากนี้:** ถ้ายังรู้สึกสะดุด ให้ดูฝั่ง client ก่อน — `PET_GLIDE_BUFFER_MS` (260) กับ React beat `PET_SCENE_PUSH_MS` (250) เป็นตัวถัดไป (ทางเลือกที่ยังไม่ทำ: ส่งตำแหน่ง pet เข้า engine ตรงจาก ws handler ข้าม React beat)

---

## 2026-09-07 (รอบ 67) — เดินไม่ smooth "ช้า เร็ว ๆ เหมือนโดนดึงขา"

- **user บอก:** "ลองใหม่แล้ว ไม่เชิงว้าป แต่มันกดเดินไม่ smooth มันเป็นช้า เร็ว ๆ เหมือนโดนดึงขา อยากให้เดินเท่ากันทุกช่วง"
- **ต้นตอ 3 อย่าง (ทั้งหมดคือ "ความเร็วไม่คงที่" คนละชั้น):**
  1. **ws วัดจังหวะผู้นำแบบ aliasing** — tick ทุก 200 ms แต่คนเดินช่องละ ~267 ms ช่วงห่างที่วัดได้จึงสลับ 200/400 → pet เดินช่องช้าสลับช่องเร็ว
  2. **ws เร่งความเร็วแบบกระโดด** — `followPace` สลับระหว่าง pace ผู้นำ / 450 / 90 ตามระยะห่าง = กระตุก
  3. **client ได้ข้อมูลเป็นก้อน** — hero flush ตำแหน่งเข้า engine ทุก 250 ms (เป็น setState จึงลดไม่ได้) ทำให้บางจังหวะได้ 2 ช่อง บางจังหวะ 0 → pet เดิน 1 ช่องแล้ว**ยืนรอ** beat ถัดไป · และ `petGlideStepMs` หารด้วยความยาวคิว = เร่งกระชาก
- **ทำ ws [#52](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/52):** `leaderPaceMs` เป็นค่าเฉลี่ยเคลื่อนที่ (smoothing 4) · `followPace` เร่งทีละ 12 % ต่อระยะห่าง 1 ช่อง เพดาน 1.8× (ไม่กระโดด) · ผู้นำยืนนิ่ง (ยังไม่มี pace) ใช้ฐาน 280 ms = ความเร็วคนเดิน แทน 900 ms
- **ทำ app [#306](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/306):** เพิ่ม **interpolation buffer** — การเดินที่เริ่มจากหยุดนิ่งรอ 1 beat (260 ms) ก่อนออกตัว จึงมีช่องสะสมในคิวเสมอและเดินรวดเดียวไม่ต้องยืนรอ (ท่ามาตรฐานของ entity interpolation) · `petGlideStepMs` เร่งได้สูงสุด 1.4× แทนการหารด้วยความยาวคิว
- **verify:** ws go test ✅ (pace ไม่ช้าลงเมื่อห่างขึ้น, เปลี่ยนไม่เกิน 40 ms ต่อ 1 ช่องของระยะห่าง, ยังปิดช่องว่างได้ ≥ 1.5× · สตรีม 200/400 ที่ aliasing ลู่เข้าค่ากลาง) · app vitest 1746 ✅ (ก้อน 2 ช่องเดินด้วยความเร็วเท่ากันทั้งสองช่อง) · **ยังไม่ได้ดูใน VO จริง** — rebuild ws + app
- **แลกมาด้วย:** pet ตามหลังเพิ่มอีกประมาณ 1 ช่อง (จาก buffer 260 ms) เพื่อแลกกับความนิ่ง — ถ้าอยากให้ติดกว่านี้ลดค่า `PET_GLIDE_BUFFER_MS` ได้ แต่จะเริ่มเห็นสะดุดตอน beat ไม่ตรง

---

## 2026-09-07 (รอบ 66) — click เดินแล้ว pet ไม่ตาม / ว้าปเป็นช่วง ๆ ยิ่งวิ่งยิ่งหนัก

- **user บอก:** "ยังมีบัคเยอะมาก โดยเฉพาะตอน click เดิน pat ไม่ยอมเดินตาม เดินตามแล้วว้าปเป็นช่วง ๆ ยิ่งตอนวิ่งยิ่งว้าปหนัก"
- **ต้นตอ (ws, ตัวใหญ่ที่สุดของทั้งเรื่อง):** `handleMoveTo` ตั้ง `c.TileX/TileY` เป็น**ปลายทาง**ทันทีที่เริ่มเดิน แล้วเก็บ `MovePath` ไว้ให้ interpolate (ถูกสำหรับ AOI แต่เป็น teleport สำหรับอะไรก็ตามที่อ่านตำแหน่ง) · `playerTiles()` ที่ป้อนให้ pet AI จึงเห็นคน**วาร์ปไปปลายทาง**ทุกครั้งที่คลิกเดิน → trail ได้เส้นทางทั้งเส้นในทีเดียว, pet วางแผนทางยาวแล้ววิ่งไล่แบบ burst 3 ช่อง/tick, และระยะห่างที่วัดได้คือระยะถึง**ปลายทาง** ไม่ใช่ถึงตัวคน · วิ่ง = กระโดดไกลกว่า = ยิ่งหนัก · เรื่องนี้ยังทำให้ attention/pop วัดระยะจากปลายทางด้วย
- **ทำ ws [#51](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/51):** `playerTiles()` อ่านช่องจริงกลางทาง (`currentPathTile`) ตอนกำลังเดิน · `petFollowMinStepMs` 120 → **90** (คนเดิน 267 ms/ช่อง วิ่ง ~89 ms — pet ตามทันตอนวิ่งได้พอดี และเท่ากับเพดานความเร็วฝั่ง client) · `petFollowMaxTrail` = 24 รอย (~10 วิ) กัน pet ที่ติดสิ่งกีดขวางไล่ตามรอยเก่าเป็นนาที — ตัดทางลัดแต่ยัง**เดิน**ไม่ใช่วาร์ป
- **verify:** go test ✅ (playerTiles คืนช่องกลางทางตอนเดิน / ช่องจริงตอนยืน · click เดิน 8 ช่องใน 2 วิ pet ตามตลอด ห่างสุด ≤ 3 ช่องแล้วมาอยู่ข้าง ๆ · trail ไม่เกินเพดานตอน pet ถูกกำแพงขวางขณะผู้นำเดิน 60 ช่อง) · **ยังไม่ได้ดูใน VO จริง** — ต้อง rebuild ws (+ app จากรอบ 65)
- **สรุปเหตุวาร์ปทั้งหมดที่เจอ 3 รอบ:** (1) client หารเวลา 1 ก้าวให้ทุกช่อง + ทิ้งคิวเมื่อได้เป้าใหม่ (รอบ 64) · (2) client ถือ `step_ms = 0` ว่า teleport (รอบ 65) · (3) **server ป้อนตำแหน่งปลายทางแทนตำแหน่งจริง (รอบ 66)**

---

## 2026-09-07 (รอบ 65) — "ยังว้าปอยู่" — ต้นตอสุดท้าย: step_ms = 0

- **user บอก:** "ลองใหม่แล้ว ยังว้าปอยู่" (หลังรอบ 64)
- **สาเหตุที่เหลือ:** `pet_state` ส่ง `step_ms: 0` ทั้งตอน**หยุด**และทุก **idle heartbeat** โดยยังบอกช่องที่ AI ไปถึงแล้ว · ฝั่ง hero push เข้า engine ทุก 250 ms แต่ ws tick ทุก 200 ms (และเดินได้ทีละหลายช่องตอนไล่ตาม) ทั้ง buffer เก็บ state ล่าสุดของ pet แค่อันเดียว → สิ่งที่ layer ได้เห็นตอนจบ burst มัก**เป็น state หยุด** ที่อยู่ไกลออกไปหลายช่อง · โค้ดถือว่า "ไม่มี duration = teleport" จึง snap → **ว้าปมาหาตอนที่มันไล่ตามทัน** พอดี ตรงกับที่ user เห็น
- **ทำ app [#305](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/305):** จำ pace ล่าสุด (`lastStepMs`) แล้วเดินไปหา state ที่ไม่มี pace ด้วยความเร็วนั้น · snap เหลือแค่ 2 กรณีจริง: pet ที่ยังไม่เคยเดินเลย (เฟรมแรก) และกระโดดเกิน 12 ช่อง (admin ลาก / rejoin)
- **verify:** vitest 1745 ✅ (เทสใหม่: state หยุดที่ไกลออกไป 3 ช่องถูกเดินทีละช่อง วัดที่ 50 ms / 300 ms / จบ · pet ที่ยังไม่เคยเดินยัง snap) tsc/eslint สะอาด · **ยังไม่ได้ดูใน VO จริง** — rebuild app แล้วลองพาเดินอีกครั้ง
- **กฎที่จดไว้:** `step_ms/moveMs === 0` แปลว่า "ไม่ได้บอกจังหวะมา" ไม่ใช่ "ให้ teleport"

---

## 2026-09-07 (รอบ 64) — "ไม่ทันแล้วว้าปมาหา" · เสียงตอนเกิด pop

**user บอก:** "ทำไมตอน pet ไม่ค่อยทัน แล้วมันจะว้าปมาหา แบบนี้ไม่ได้ ต้องเดินต่อเนื่องเหมือนกับตัวละครผู้ใช้" · "ระบบเสียง อยากให้สุ่มมาด้วยตอนที่เชื่อม pop กับ pet"

- **ต้นตอ "ว้าป" (ฝั่ง client 2 จุด):**
  1. `petGlideRoute` เอาเวลา 1 step ไป**หารเฉลี่ย**ให้ทุกช่องที่ต้องข้าม → ไล่ตาม 3 ช่องในเวลา 1 step = ไถลเร็ว 3 เท่า
  2. `advanceMotion` ถือ state ใหม่เป็น "เป้าใหม่" วางเส้นทางจากตำแหน่งปัจจุบันแล้ว**ทิ้งคิวเดิม** และตอนค้างท่าลุก (`holdMotion`) มัน return ก่อนจะเข้าคิวด้วยซ้ำ → ช่องที่มาถึงระหว่างค้าง ถูกยัดรวมเป็น step เดียว
- **ต้นตอ "ไม่ทัน" (ฝั่ง ws):** เดินได้แค่ 1 ช่อง/tick (200 ms) = เร็วเท่าคนเดินพอดี จึงปิดช่องว่างไม่ได้เลย · และถ้าผู้นำ**ยืนนิ่ง** จะไม่มี pace ให้วัด ตกไปใช้ 900 ms/ช่อง = เดินเรื่อยเปื่อย
- **ทำ app [#304](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/304):** เปลี่ยน glide เป็น **คิวต่อท้าย** — ทุก state ต่อช่องเข้าคิว (bridge เป็นแนวตรง) แล้วเดินทีละช่องด้วย pace ต่อช่องของ server รวมช่วงค้างท่าลุก · คิวยาว → **เดินเร็วขึ้น** (`petGlideStepMs` สเกลจาก 3 ช่อง, ต่ำสุด 90 ms) ไม่ใช่วาร์ป · เหลือ snap เฉพาะกระโดดเกิน 12 ช่อง (= teleport จริง)
- **ทำ ws [#50](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/50):** tick เดียวเดินได้ทุกก้าวที่ถึงกำหนด (สูงสุด 3) · `followPace` ใหม่: ตามติด = pace ของผู้นำ, ห่าง 2 ช่อง = 450 ms, ห่าง ≥ 4 หรือรอยค้าง = **120 ms/ช่อง** — ผู้นำยืนนิ่งก็เร่งตามระยะได้แล้ว
- **เสียงตอน pop:** เกิด pop กับ pet → สุ่มเสียงจากแพ็กของ category ตัวนั้น เฉพาะคนที่ pop ด้วย (ต่อจากรอบ 63)
- **verify:** ws go test ✅ (ปิดช่องว่างกับผู้นำที่เดิน 1 ช่อง/tick จนเหลือ ≤ 2 ช่อง · ไม่มี tick ไหนขยับเกิน cap · ถึงผู้นำที่ยืนนิ่ง) · app vitest 1743 ✅ (state ระหว่าง glide เข้าคิวเดินครบทั้ง 2 ช่อง · ช่องที่มาตอนค้างท่าลุกถูกเดินทีหลังไม่ถูกข้าม · กระโดดเกินลิมิตยัง snap · `petGlideStepMs`) · **ยังไม่ได้ดูใน VO จริง** — ต้อง rebuild ws + app

---

## 2026-09-07 (รอบ 63) — เสียงสัตว์เลี้ยงขึ้น R2 + เอามาใช้จริง

- **user บอก:** "ใน storage/sound เพิ่มเสียงของสัตว์แต่ละตัว ช่วยเอาไปเก็บใน s3 แล้วนำมาใช้ ให้ตรงกับ Category ของ pet ตัวนั้น ๆ เปลี่ยนชื่อไฟล์ได้ จัดตำแหน่งให้ด้วย เพราะอนาคตจะมีเสียงของแต่ละ Category เพิ่ม ตอนนี้มีแค่ 3 ก่อน"
- **อัปขึ้น R2 แล้ว 20 ไฟล์** (2.7 MB) ที่ `static/pet/sound/` — โครงตั้งใจให้ขยายทีละโฟลเดอร์: `<category>/<baby|adult>/NN.mp3` + `shared/evolution.mp3` · ตั้งชื่อใหม่เป็นเลข 2 หลักเรียงจากคลิปสั้นไปยาว · `audio/mpeg`, `max-age=86400` · **ผูกกับ category ไม่ใช่ type** (แมวทุกตัวเสียงเดียวกัน type ใหม่ได้เสียงทันที) · ไก่ = category `bird` · ไข่ไม่มีเสียง · adult ใช้ร่วมกับวัยวิวัฒน์ · ตอนนี้ cat 6+3, dog 2+2, bird 2+4
- **ทำ api [#90](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/90):** `RoomPet.pet_type_category` (join `pt.category`) ทุก payload — VO ต้องรู้ category ถึงจะเลือกเสียงได้
- **ทำ app [#303](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/303):** `lib/pet-sound.ts` (registry + ตัวเลือกคลิป) · `lib/pet-sound-player.ts` (cache element, ระดับเสียงตาม Notification volume — 0 = ปิดจริง, ตัดที่ 2.5 วิแล้ว fade เพราะคลิปต้นทางบางไฟล์ยาว 8–15 วิ) · ลูบสำเร็จ → เสียงตาม category+ช่วงวัย (คนลูบได้ยินคนเดียว) · ลำดับการเติบโต → `evolution.mp3` ครั้งเดียวตอนเริ่ม (เฉพาะคนที่ XP ทำให้ข้าม) · `/dev/preview/room-pat` เพิ่มส่วนกดฟังทุกคลิป
- **verify:** URL ทั้ง 20 ตอบ 200 (`audio/mpeg`) · vitest 1740 ✅ (เทสใหม่ `pet-sound.test.ts`) · tsc/eslint สะอาด · headless: section แสดงผลและคลิกแล้ว resolve เป็น `…/cat/baby/03.mp3` — **เสียงจริงยังไม่ได้ฟัง** (headless ไม่มีเสียง) รบกวนฟังที่ `/dev/preview/room-pat`
- **เอกสาร:** [guides/pet-sounds.md](../../guides/pet-sounds.md) — โครง R2, วิธีเพิ่ม category ใหม่ (อัปไฟล์ + แก้ 1 บรรทัด), เล่นตอนไหน ใครได้ยิน
- **ยังไม่ได้ทำ (ตั้งใจ):** สวิตช์เปิด/ปิดเสียง pet แยกใน Settings (ตอนนี้ใช้ Notification volume ร่วม) · เสียงตอนเศร้า/เดินตาม · ให้ admin อัปเสียงเองผ่าน Pet Management (ตอนนี้เป็น asset กลางตาม category)

---

## 2026-09-07 (รอบ 62) — เดินตามต้องเป็นรอยเดียวกับผู้ใช้ 100% · ต้นตอเดินเฉียง

- **user บอก:** "มันไม่เป็นธรรมชาติเลย ตอนเดินติดตามออกมานอก zone pet เดินมั่วมาก อยากให้เดินตามรอยที่ผู้ใช้เดินเลย ทิศทางต้องตรงแบบ 100%"
- **ต้นตอที่หาเจอ:** `Room.findPath` (pathfinder ของผู้เล่น) อนุญาต **ก้าวทแยง** — pet ยืมใช้มาตลอด (เดินเล่น/เข้าหาคน/หลบ/ตาม/กลับบ้าน) นี่คือที่มาของ "เดินเฉียง" ทุกรอบที่ผ่านมา ไม่ใช่แค่ฝั่ง client
- **ทำ ws [#49](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/49):**
  - `petFindPath` = BFS 4 ทิศเฉพาะ pet ใช้แทนทุกจุด → ทุก path ของ pet ตรงแนว x/y เท่านั้น
  - **โหมดตาม = เดินตามรอย:** ทุก tick บันทึกช่องที่ผู้นำเหยียบลง trail (ถ้าผู้นำเร็วจนข้ามช่องจะเติมช่องระหว่างให้ต่อกัน) pet กินรอยทีละช่อง ตามหลัง 1 ช่อง ด้วยจังหวะเดียวกับผู้นำ (วัดจริง 200–900 ms) ถ้าตกท้ายรอย ≥ 3 ช่องเร่งเป็น 200 ms/ช่อง ต่อ leg ไม่มีหยุด · เริ่มตามจากที่ไกลจะเดินมาอยู่ข้างผู้นำก่อน · รอยที่เหยียบไม่ได้ (meeting zone / มีคนยืน) หรือถูกดันหลุดรอย → หาทางอ้อมบน `followGrid` (grid + meeting + คน = กำแพง) ไม่มีทาง → รอ
- **verify:** go test ✅ (ผู้นำเดินรูปตัว L → pet เหยียบช่องเดียวกันเรียงลำดับเดียวกัน ตามหลัง 1 ช่อง · ผู้นำ 2 ช่อง/tick → รอยต่อกันไม่มีช่องว่าง · `petFindPath` ตรงแนวเสมอ อ้อมสิ่งกีดขวางได้ ไม่มีทาง/ไม่มี grid → nil · เทสเดิมทั้งหมดผ่าน) · ฝั่ง app ไม่ต้องแก้ (glide facing รอบ 61 รองรับ) · **ยังไม่ได้ดูใน VO จริง** — rebuild ws แล้วลองพาเดินออกนอกห้อง

---

## 2026-09-07 (รอบ 61) — ท่าเดินตามแปลก เดินช้า หันหน้าผิดทาง

- **user บอก:** "ท่าตอน pet เดินตามแปลกมาก เดินช้าๆ ยังไงไม่รู้ แถมตอนเดินทิศทางไปทิศหนึ่งแต่หันหน้าไปอีกทาง"
- **สาเหตุ:** (1) `beginWalk` ใส่ดีเลย์ท่าลุก 750 ms ทุกครั้งที่ `stoppedAt` เก่าเกิน 8 วิ — pet ที่เดินตามไม่เคยหยุด `stoppedAt` จึงค้างค่าเก่า ทำให้ทุกการวางเส้นทางใหม่ (ทุก 3 ก้าว) รอ 750 ms = เดินช้าเป็นจังหวะ (2) ทุก 3 ก้าว leg จบแล้ว broadcast `moving:false` 1 tick ก่อนวางเส้นทางใหม่ → client สลับท่าพัก/เดินตลอด (3) client วาดแถวทิศจาก `facing` ของ server (= ทิศก้าวล่าสุด) แต่ตอน catch-up ไถลตามเส้นทาง x ก่อน y → ตัวไปทางหนึ่ง หน้าหันอีกทาง
- **ทำ ws [#48](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/48):** `followStep` ต่อ leg ใน tick เดียวกันเมื่อยังห่างผู้นำ (ไม่มี stop ระหว่าง leg, ถ้ามีคนก้าวมาขวางให้วางเส้นทางใหม่แทนหยุด) · จังหวะตามระยะ: 900 ข้างตัว / 450 เมื่อห่าง ≥ 2 / **300** เมื่อห่าง ≥ 4 (`petFollowSprintMs`, คนเดิน ~200 ms/ช่อง) · ท่าลุกใช้เมื่อไม่ได้ก้าวมา ≥ 8 วิจริง ๆ (`lastStepAt`) ไม่ใช่แค่ `stoppedAt` เก่า
- **ทำ app [#302](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/302):** `PetLayer.glideFacing` — ขณะสไปรต์ไถลบนจอ แถวทิศมาจากทิศของ segment ที่กำลังไถล (x-first แล้ว y) ไม่ใช่ facing ของ server; หยุดแล้วค่อยกลับไปใช้ facing/pop override
- **verify:** ws go test ✅ (ไล่ตาม 12 ช่อง: ไม่มี stop ระหว่างทาง + sprint ตอนห่าง; ก้าวเมื่อ 1 วิก่อน → ออกตัวทันทีแม้ stop clock เก่า) · app vitest 1733 ✅ (ก้าวเฉียงที่ server บอก "up" → วาดแถว right ตอนไถลแกน x แล้ว up ตอนแกน y) · ยังไม่ได้ดูใน VO จริง — rebuild ws + app แล้วลองพาเดิน

---

## 2026-09-07 (รอบ 60) — quest ให้เฉพาะสมาชิกที่มีโต๊ะในห้อง (owner/admin ไม่นับ)

- **user บอก:** "ไม่ว่า admin หรือ owner map ไม่สามารถทำ quest ให้ pet ของ zone อื่นได้ถ้าไม่ใช่สมาชิก และรายการ quest ต้องตามการเปิดปิดใน /admin/pet-management XP Configuration"
- **ทำ api [#89](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/89):** `AwardWorkspaceActivity` (login / อยู่ office / meeting / chat) นับให้ pet เฉพาะเมื่อคนทำมี private zone ในห้องนั้น (`loadRoomDeskResidents`) — owner/admin ยังเป็น resident ทุกห้องสำหรับลูบ/พาเดิน/วงกลม/modal โต แต่ไม่ได้ quest ของห้องที่ตัวเองไม่มีโต๊ะ · เพิ่ม `is_quest_resident` บน workspace pet list + status · การเปิด/ปิด quest ตาม XP Configuration มีอยู่แล้ว (server `activity.Enabled` → ACTIVITY_DISABLED, client `buildPetDailyQuests` กรอง enabled) ไม่ต้องแก้
- **ทำ app [#301](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/301):** panel แสดง Daily quest เมื่อ `is_quest_resident` (fallback `is_resident` กับ server เก่า)
- **verify:** api go test service/handler ✅ · app vitest 1732 ✅ · ยังไม่ได้ลองใน VO จริง — ทดสอบ: owner เปิด panel pet ในห้องที่ตัวเองไม่มี private zone → ไม่มีรายการ quest, ทำ login/chat แล้ว XP ของ pet นั้นไม่ขึ้น

---

## 2026-09-07 (รอบ 59) — พา pet ไปเดินเล่นนอก zone (follow) + กลับบ้านเมื่อปล่อย/คนออก

**user บอก:** "อยากพา pet ไปเดินเล่นนอก zone ได้ แต่ต้องกดเพื่อพาไปเท่านั้น เพิ่มปุ่มข้างปุ่มลูบหัว กดแล้ว pet เดินตามหลังตลอดจนกว่าจะยกเลิก ขึ้นสถานะติดตามแบบ zyra มีปุ่มยกเลิก ยกเลิกแล้วกลับจุดวาง เช็คติด box/meeting ดีๆ ถ้าคนนั้นออกจาก workspace ให้กลับทันที"

- **ws [#46](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/46) (+ gofmt #47):** ข้อความใหม่ `pet_follow {pet_id, follow}` — resident ที่ยืนห่าง ≤ 3 ช่องพาไปได้ ปล่อยได้เฉพาะคนที่พา · broadcast `pet_follow_changed {pet_id, user_id?}` และ `pet_state.following_user_id` สำหรับคนที่เข้ามาทีหลัง · ตอนตาม: อยู่ห่างผู้นำ ≤ 1 ช่อง วิ่งเมื่อห่าง ≥ 4 วางเส้นทางใหม่ทุก 3 ก้าว ไม่เหยียบ tile ที่ block / meeting zone / มีคนยืน ไม่ติดขอบห้อง (ออกนอก zone ได้) ไม่สนใจ attention/pop/เดินเล่นระหว่างนั้น · ปล่อย หรือคนพาหลุดจาก office / ย้ายชั้น → `pet_follow_changed` (ไม่มี user) แล้วเดินกลับจุดวาง (หรือช่องข้าง ๆ ถ้ามีคนยืน) ก่อน AI ห้องกลับมาทำงาน
- **app [#300](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/300):** ปุ่มที่ 2 (lucide Footprints, จานเขียวแบบเดียวกับมือ) ซ้ายปุ่มลูบ ทั้งบนป้ายชื่อและวงกลมตอนซูมออก — ขึ้นเฉพาะ pet ที่เรา pop อยู่ ไม่มีคนพาอยู่ และเราไม่ได้พาตัวอื่น · กด → `pet_follow true` · แถบสถานะแบบเดียวกับ follow bar ของ zyra ตรงกลางเหนือ HUD "กำลังพา {pet} เดินเล่น" + ปุ่ม "ส่งกลับบ้าน" → `pet_follow false` · PetLayer `petButtonKindAt`/`petWalkActionAt`, scene `setPetWalkable`/`setOnPetWalkClick`
- **verify:** ws go test ✅ (ตามออกนอกห้องแล้วหยุดข้างผู้นำ, อ้อม meeting zone, ผู้นำย้ายชั้น → ปล่อย+กลับบ้าน, บ้านมีคนยืน → หยุดข้าง ๆ, guard ของ handler) · app vitest 1732 ✅ (slot ปุ่มเดินบนป้าย, hit/hover ปุ่มเดินใน layer) · **ยังไม่ได้ทดสอบใน VO จริง** — ต้อง rebuild ws + app
- **หมายเหตุ:** "บน minimap" — ใช้ตำแหน่ง/หน้าตาเดียวกับ follow bar ของ zyra (กลางล่างเหนือ HUD) ถ้าต้องการวางไว้บน minimap จริง ๆ บอกได้ · ตำแหน่ง pet นอกห้องไม่ persist: ถ้า ws restart pet จะเกิดที่บ้าน

---

## 2026-09-07 (รอบ 58) — ขนาด pet บนแมพไม่เท่ากันตามท่า · เดินเฉียง/ว้าป/ท่านั่งขณะเดิน · pop ใน meeting zone

**user บอก:** "ใน VO ตอน pet เปลี่ยนท่าทาง ขนาดที่แสดงไม่เท่ากัน" · "การเดินต้องไม่เดินเฉียงและว้าป แสดงท่าไม่ถูก เดินอยู่แต่ท่าเป็นท่านั่ง/happy ต้องเล่น animation ให้เสร็จก่อนค่อยเปลี่ยน" · "อยู่ใน meeting zone ยังขึ้น pop"

- **สาเหตุ 1 (ขนาด):** `PetLayer` ยืดทุกเฟรมให้สูง 32 px (`sprite.height = PET_DISPLAY_H`) → เฟรมท่านั่ง (~102 px ต้นฉบับ) ถูกขยายเท่าท่ายืน (~130) ตัวจึงโตขึ้นตอนนั่ง — เรื่องเดียวกับ overlay รอบ 55
- **สาเหตุ 2 (เฉียง/ว้าป/ท่านั่งขณะเดิน):** client เล่นท่าลุก (Sitting ย้อนกลับ 750 ms) โดยค้างตัวไว้ ขณะที่ AI ก้าวต่อทันที (450–900 ms/ช่อง) → พอปล่อยค้าง ตัวไถลไปช่องที่ห่าง 1–2 ช่องในทีเดียว = เฉียง/ว้าป และเห็น "ท่านั่งอยู่แต่ตัวขยับ"
- **สาเหตุ 3 (pop ใน meeting):** เช็ค zone ใช้ตัวแรกที่ครอบ tile (`_areaZoneAtTile`) → meeting ที่วาดอยู่ในห้องได้ zone ห้องกลับมา ไม่ใช่ meeting
- **ทำ ws [#45](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/45):** `beginWalk` — ถ้ายืนนิ่ง ≥ 8 วิ (= นั่งอยู่บนทุก client) ประกาศเดินก่อน (moving, ช่องเดิม, หันไปทางที่จะไป) แล้วก้าวแรกหลัง `petStandUpMs` 750 ms ให้ตรงกับท่าลุกฝั่ง client · ใช้กับเดินเล่น/วิ่ง/เข้าหาคน/ไล่งับหาง
- **ทำ app [#299](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/299):** `PET_SOURCE_SCALE` = 32/130 px ต่อ px ต้นฉบับ ทุกเฟรมทุกชีท (adult/evolved สูงกว่านิดตามจริง) ป้ายชื่อแขวนจากเฟรมสูงสุดที่เคยเห็น ไม่ขยับลงตอนนั่ง hit-test ใช้ขนาดที่วาดจริง · `petGlideRoute` ถ้า state กระโดด > 1 ช่องหรือเฉียง ให้ไถลผ่าน waypoint ตรง ๆ (x ก่อน y) จากช่องที่ตัวอยู่ใกล้สุด แบ่งเวลาของ step กัน เกิน 12 ช่องถือเป็น teleport (snap) · pop เช็ค `_tileInZoneType("meeting")` ทุก zone
- **verify:** ws `go test ./internal/hub` ✅ (นั่ง 10 วิ → ประกาศก่อน ก้าวที่ 750 ms ไม่ก้าวที่ 500; ยืน 2 วิ → ก้าวทันที) · app vitest 1730 ✅ (pet-layer: ขนาดจากเฟรม 100×50 × scale, `petGlideRoute` รวมกรณี anchor ทศนิยม 58.25 ที่เคยทำ loop ไม่รู้จบ) · ยังไม่ได้ทดสอบใน VO จริง — ต้อง rebuild ws + app
- **ยังไม่ได้ทำ (ตั้งใจ):** "เล่น animation ให้เสร็จก่อนค่อยเปลี่ยนท่า" แบบทั่วไปทุกท่า — ตอนนี้ครอบแค่ท่าลุก (ค้าง 750 ms ทั้งสองฝั่ง) และท่านั่งลง→Happy (รอจบก่อนอยู่แล้ว) · ถ้ายังเห็นท่าสลับกลางคัน ให้บอกท่าคู่ไหนจะเพิ่มการรอให้

---

## 2026-09-07 (รอบ 57) — hover pet บน dev ไม่ขึ้นกรอบเขียว / ป้ายชื่อไม่ขึ้นหน้า

- **user บอก:** "บน dev เอาเมาส์ไป hover ตรง pet ทำไมไม่ขึ้นกรอบเขียวแบบตัวละคร และป้ายชื่อถ้า hover อยู่ต้องขึ้นมาด้านหน้า"
- **สาเหตุ:** รอบ 52 ถอด `setOnPetHover` ฝั่ง React ออก (เลิกใช้ hover เป็นเงื่อนไขลูบ) แต่บล็อก hover ใน `scene.ts` ถูกครอบด้วย `if (this.onPetHoverCallback)` → engine ไม่เรียก `petAt()`/`setHovered()` อีก → ไม่มี outline และป้ายไม่ยกขึ้น (ทั้งสองอย่างผูกกับ `hoveredId` ใน PetLayer)
- **ทำ (app [#298](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/298) → develop):** บล็อก hover รันเสมอเมื่อมี pet layer, callback ของ React เป็น optional
- **verify:** vitest ทั้งชุด ✅ tsc/eslint สะอาด · ยังไม่ได้ดูใน VO จริง (login) — dev deploy จาก develop แล้วลอง hover

---

## 2026-09-07 (รอบ 56) — หน้าโชว์เปลี่ยนเป็น type "Pie"

- **user บอก:** "/dev/preview/room-pat เปลี่ยน pet เป็นตัวที่ชื่อ Pie เพราะตัวนี้ไฟล์ถูกต้องทุกรูป"
- **ทำ (app [#296](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/296) + format #297 → develop):** `real-pet-fixture.ts` ชี้ไป Pie (`7117ac29`, active, 20 แถว animation) แทน ปรื๊ด (`1e77b16b` ถูก soft-delete แล้ว บางชีทเพี้ยน) ทุก section ของหน้าโชว์/harness ตามไป (evo flow, ทุกท่า, sprite strip, วงกลม, ป้ายชื่อ, การ์ดแชร์)
- **verify:** vitest 1726 ✅ tsc/eslint สะอาด · headless Chromium: section ทุกท่าเล่นได้ · ขนาด overlay ยังสเกลเดียว (ไข่ 210 vs GIF 200 px, Happy baby 163 px เท่ากันทั้ง prompt และ reveal, adult Happy 189)
- **หมายเหตุ:** type ที่ active บน dev ตอนนี้มีแค่ POP กับ Pie — pet ที่วางไว้ด้วย type ที่ถูกลบยังวาดได้ผ่าน `/api/user/pets/:id` (ไม่กรอง status)

---

## 2026-09-07 (รอบ 55) — พฤติกรรม pet v2 + overlay ขนาดเดียวกันจริง

**user บอก (พฤติกรรม):** ไม่เดินผ่าน meeting zone · ไม่ออกนอก room zone · ไม่ pop กับคนใน meeting zone · happy สุ่มวิ่งเล่น 10 % / วิ่งวงกลมไล่งับหาง 5 % · ไม่ยืนซ้อนตัวละคร · sad ไม่วิ่ง เดินน้อยลงมากๆ animation ช้าลง · เดินให้ทั่ว room zone ไปหาทุกคน
**user บอก (overlay):** "รูปยังมั่วๆ ความใหญ่ไม่เท่ากันบ้าง animation เล่นผิด step ต้องเป็น loop จนกด → evo → ท่านั่งของช่วงวัยใหม่ → happy วน · ขนาดรูปต้องเท่ากัน"

- **ws [#44](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/44) → develop:** `tileAllowed` ตัด tile ใน zone type `meeting` (เป้าเดินเล่น/ก้าวเข้าหา/ทุก step) · `updateAttention` ข้าม resident ที่ยืนใน meeting · sad: ไม่สนใจใคร เดินอย่างเดียว (`petSadStepMs` 1400) 10 % ของ decision พัก 10–40 วิ ไม่วิ่ง · happy: 5 % วิ่งวง 2×2 รอบตัว 2 รอบ (ไล่งับหาง) / 10 % วิ่งไปเป้าที่ห่าง ≥ 3 ช่อง ที่ `petRunStepMs` 450 (`pet_state.step_ms` บอกจังหวะ) · เดินเล่นสุ่มทั่วทั้งห้อง (ตัดรัศมี 4 ช่องรอบจุดวาง) และครึ่งหนึ่งเดินไปช่องข้าง resident ทีละคนวน · ถ้ามีคนเดินมายืนช่องถัดไประหว่างเดิน → หยุดตรงนั้น · ไม่ออกนอกห้อง: เดิมอยู่แล้ว (zone tiles)
- **app [#295](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/295) → develop:**
  - `_drawPetLinks` ไม่ pop กับคนที่ยืนใน meeting zone (area zones มี `zoneType` แล้ว) · `petPaceFrameRateScale` ชีท Walking เร็วขึ้นตาม step_ms ตอนวิ่ง (450 → 2×, cap 2.5)
  - **overlay สเกลเดียว:** ทุกชีท (loop ก่อนคลิก, นั่งลง, Happy วน, และ section ทุกท่า) วาดที่ `PET_EVOLUTION_SHEET_SCALE` 1.6 px/px เท้าอยู่ขอบล่างกรอบ 240 — เลิก fit-to-box ทีละชีท (ท่านั่ง Happy เคยถูกขยายจนเต็ม 240 ขณะที่ท่ายืนไม่เต็ม = "ใหญ่บ้างเล็กบ้าง") · GIF วาดในกรอบ 768 = 960 × 1.6 ÷ 2 (โลกใน GIF ใหญ่กว่าชีท 2 เท่า: ไข่ 250 vs 131, baby 260 vs 129, adult 310 vs 140 px) และวาง GIF ในคอลัมน์เดียวกับกรอบชีท เท้าจึงตรงกัน · `petSheetFrameCount` ชีทที่คอลัมน์น้อยกว่า frame_count (ไข่ Wobbling 4×3) เล่นตามจริง ไม่ replay เฟรม (เคยดู "มั่ว") · ลำดับยังเป็น loop → GIF ไข่แตก (egg เท่านั้น) → flash → GIF โผล่ → นั่งลง → Happy วน → modal
- **verify:** ws `go test ./internal/hub` ✅ (เทสใหม่ 6: ไม่เข้า meeting 600 ครั้ง, ข้ามคนใน meeting, sad เดินช้าและน้อย, happy วิ่งบ้าง, ไล่งับหางจบที่เดิม/ไม่วิ่งทับคน, เดินถึงปลายห้อง 20 ช่อง + ไปข้างคน) · app vitest 1726 ✅ tsc/eslint สะอาด · **วัดจาก pixel จริงใน headless Chromium** (อ่าน canvas / วาด GIF ลง canvas) บน `/dev/preview/room-pat`: ไข่ก่อนคลิก 210 px · ไข่ใน GIF 200 px · เท้าห่างกัน 8 px · baby ท่า Happy 155 px ทั้งใน prompt ของ baby→adult และ reveal ของ egg→baby · adult นั่งลง 210 → Happy 190 บน baseline เดียว — ยังไม่ได้ทดสอบพฤติกรรม ws ใน VO จริง (ต้อง rebuild ws + app บน local)
- **หมายเหตุ:** flash สีฟ้า 0.9 วิ ยังอยู่ระหว่าง GIF ออกกับ GIF เข้า (Figma §5.2) — ถ้าไม่ต้องการบอกได้ ตัดค่าคงที่เดียว · ค่า 1.6 / 3.2 อิงสัดส่วน asset ปัจจุบัน ถ้าศิลปินวาดโลก GIF ไม่ใช่ 2× ของชีท จะเพี้ยน ควรเขียนเป็นข้อกำหนดใน Pet Management

---

## 2026-09-07 (รอบ 54) — pet ยืนซ้อนตัวละคร

- **user บอก:** "pet จะชอบไปยืนตรงกับตัวละคร" (screenshot pet ถูกตัวละคร Tester Ten บังทั้งตัว)
- **ทำ (ws [#43](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/43) → develop):** pet AI ถือ tile ที่มีคนยืน (ทุกคน ไม่ใช่แค่ resident) เป็นที่ห้ามเหยียบ — เป้าเดินเล่น, ก้าวเข้าหาคน และทุก step ใน path · ถ้ามีคนเดินมายืนทับ pet จะขยับหลบ 1 ช่องทันที (4 ทิศตรงก่อน แล้วทแยง ภายในห้อง) ไม่รอ rest และแม้กำลังเศร้า
- **verify:** `go test ./internal/hub` ✅ (เทสใหม่ 4: หลบตอนถูกยืนทับแม้กำลังพัก, เลือกช่องว่างในห้อง 2×2, เดินเล่น 400 ครั้งไม่เหยียบคน 4 คน, ก้าวเข้าหาคนไม่เหยียบคนที่ยืนคั่น) · ยังไม่ได้ดูใน VO จริง — dev deploy อัตโนมัติจาก develop; local ต้อง rebuild ws
- **หมายเหตุ:** ถ้าคนเดินทับตอน pet กำลังเดินอยู่ มันเดินต่อตาม path เดิม (ไม่หลบกลางทาง) แล้วค่อยหลบเมื่อหยุด · pet ที่ล้อมรอบด้วยคน/ของทั้ง 8 ช่องจะยังยืนที่เดิม

---

## 2026-09-07 (รอบ 53) — วงกลม pet ตอนซูมออกพื้นดำ → เขียว Zyra (และ avatar ใน panel)

- **user บอก:** "ซูมออกมาแล้วเห็นเป็นวงกลมของ pet ตอนนี้พื้นหลังสีดำ อยากให้แก้เป็นสีเขียว zyra เมนูตอน click ด้วย"
- **ทำ (app [#294](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/294) → develop):** `PET_CIRCLE_BG` จากสีป้ายคน (`0x141420`) → `0x58D68D` · avatar วงกลมใน `VOPetPanel` จากชมพู `#FFA8A8` → `#58D68D`
- **verify:** vitest ทั้งชุด 1719 ✅ (เทส panel อัปเดตสี) tsc/eslint สะอาด · ภาพจาก harness ส่วนวงกลม PixiJS — ยังไม่ได้ดูใน VO จริง

---

## 2026-09-07 (รอบ 52) — ท่าเศร้าช้าลง + กรอบเศร้า · ลูบได้เฉพาะใน pop · ปุ่มลูบชนตัวละคร · หน้าโชว์เล่นได้ทุกท่า

**user บอก:** "ตอน mood sad อยากให้ animation ช้าลง เหมือน pet กำลังเศร้า แล้วขึ้นกรอบข้อความเหมือนตอนลูบหัวว่าเศร้า 3 นาทีครั้ง เฉพาะสมาชิก" · "/dev/preview/room-pat เพิ่ม animation ให้กดเล่นครบทุกท่า" · "ปุ่มลูบหัวตรงกับตัวละครคนอื่นจะกดโดนตัวละครแทน" · "คนที่จะลูบหัวได้ต้องอยู่ใน pop เท่านั้น"

- **ทำ (app [#293](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/293) → develop):**
  - **เศร้า:** `buildScenePets` คูณ frame rate ด้วย `PET_SAD_FRAME_RATE_SCALE` 0.5 ทุกชีทที่เล่นตอน mood sad (รวมเดิน) · ทุก 3 นาที (`PET_SAD_BUBBLE_INTERVAL_MS`, ครั้งแรกหลังเข้า 8 วิ) ขึ้นกรอบความคิดแบบเดียวกับตอนลูบ (`PetPatBubble variant="sad"`: หน้าจากชีท Sad + น้ำตา 2 หยด, keyframe `pet-sad-tear`) นาน 2.6 วิ **เฉพาะ resident ของห้อง** (`is_resident`) · หลายตัวเศร้าพร้อมกันขึ้นทีละตัว (`petSadBubbleSchedule`) · ถ้ากำลังเล่น feedback ของการลูบอยู่ข้ามรอบนั้น
  - **ลูบได้เฉพาะใน pop:** ปุ่มมือ/[P] ใช้ `proximityPetId` (pop link จาก engine) อย่างเดียว ถอด `strokeablePetId`/`hoveredPetId` (เดินมาใกล้/hover ไม่พอแล้ว)
  - **ลำดับคลิก** ใน `scene.ts`: ปุ่มมือของ pet → ตัวละครคนอื่น → ตัว pet → zone/เดิน (เดิมตัวละครมาก่อน คนใน pop ยืนทับปุ่มพอดีเลยกดโดนคน)
  - **หน้าโชว์** `/dev/preview/room-pat` เพิ่ม section "ทุกท่า": stage × slot (Happy/Idle/Sad/Sitting/Walking/Wobbling/Evolution) × แถวทิศ 0–3 × ความเร็วปกติ/เศร้า · fixture เพิ่ม Idle + Sad · `PetSheetPlayer` รับ `directionRow`/`speed`
- **verify:** vitest ทั้งชุด 1719 ✅ (เทสใหม่: สเกล fps ตอนเศร้า, ตารางเวลากรอบเศร้า, bubble variant sad) · tsc/eslint สะอาด · headless Chromium บนหน้าโชว์: section ทุกท่าเล่นได้ (Sad 2 ช็อตต่างกัน = ขยับจริง, แถวซ้าย, Evolution GIF, ไข่) · **ยังไม่ได้ทดสอบใน VO จริง** (login): กรอบเศร้าทุก 3 นาที, ปุ่มมือเฉพาะใน pop, คลิกปุ่มมือทับตัวละคร — ต้องลองบน local
- **ต่อจากนี้:** ถ้าอยากให้กรอบเศร้าขึ้นถี่/นานกว่านี้ แก้ค่าคงที่ใน `lib/pet-interaction.ts` · การลูบเดิมที่ทำได้จากการเดินมาใกล้ถูกตัดตามที่ขอ — ถ้า pop ไม่เกิด (pet เดินอยู่) จะลูบไม่ได้จนกว่าจะหยุดและเชื่อม pop

---

## 2026-09-07 (รอบ 51) — "รูปไม่ขึ้นเลย" ใน Workspace editor ของ owner

**user บอก:** screenshot editor ฝั่ง owner — ไอคอน stage ทุกที่ (marker menu, แถวช่วงวัย, hover card ใน palette) เป็นรอยเท้าหมด รวมทั้งไข่

- **สาเหตุ:** `usePetTypeAnimations` ดึงชีทของ pet type ผ่าน `GET /api/admin/pets/:id` — owner เรียกไม่ได้ (403) → hook cache `[]` → `pickStageIdleAnimation` คืน null ทุก stage → fallback รอยเท้า (ผิด rule 15 มาตั้งแต่รอบ 12 แต่ทดสอบกันมาในหน้า admin ตลอด)
- **ทำ:** api [#88](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/88) เพิ่ม `GET /api/user/pets/:id` (UserGuard, GetDetail เดิม, ไม่กรอง status เพื่อให้ pet ที่วางแล้วของ type ที่ถูก hide ทีหลังยังวาดได้) · app [#292](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/292) `getPetForUser` + hook ใช้ route นี้ทั้งโหมด admin และ owner
- **verify:** api `go test ./internal/handler` ✅ (เทส GetDetail 200/404) · app vitest ทั้งชุด 1715 ✅ tsc/eslint/prettier สะอาด · **ยังไม่ได้ลองใน editor จริง** — ต้อง pull + build ทั้ง api และ app แล้วเปิด Workspace editor ใหม่ (รูปควรขึ้นทั้ง marker menu / แถวช่วงวัย / hover card)

---

## 2026-09-07 (รอบ 50) — คนเห็น animation/modal · ปรับช่วงวัยจาก Workspace editor

**user บอก:** "คนที่ขึ้น animation คือคนที่ทำ quest จน xp เต็มเท่านั้น คนอื่นขึ้นแบบทั่วไป และขึ้นคนที่เป็นสมาชิกเท่านั้น" · "workspace editor ตอนวาง pet ให้ปรับช่วงวัยได้จากเมนูอันแรก (icon เท้า) เปลี่ยนเป็นช่วงวัยจริง กดแล้วเปิดให้เลือก · ถ้า xp เปลี่ยนไปแล้ว/มีคนทำ quest แล้วให้ถามยืนยัน · เปลี่ยนช่วงวัยแล้ว xp เริ่มนับใหม่ตามค่าเริ่มต้นของช่วงนั้น · hover ให้แสดงภาพตามช่วงวัย"

- **ทำ api ([#87](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/87) → develop):** `PATCH /api/{admin,user}/maps/:mapId/pets/:petId` รับ `stage` → set `last_seen_stage`, **xp = threshold ต้นช่วง** (egg 0 / baby xp_baby / adult xp_adult / evolved xp_evolve จาก tb_pet_xp_config ปัจจุบัน), `last_milestone = 0` · stage ไม่รู้จัก → 400 `INVALID_STAGE` · publish `pet_xp_changed` + `pet_stage_changed` **ไม่มี triggered_by** (ไม่มีใครได้ animation, ไม่ส่ง notification/achievement) · `RoomPet.xp_event_count` (นับ tb_room_pet_xp_event) บน editor list/get · `RoomPetService.SetXPConfig` wire ใน main.go · ไม่มี migration
- **ทำ app ([#291](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/291) → develop):**
  - marker menu: icon แรก = รูป **ช่วงวัยปัจจุบัน** กดแล้วเปิดแถว 4 stage ตาม Figma 4387:121093 (ปัจจุบัน opacity 100 อื่น 50 %) · hover แต่ละ stage ขึ้น preview 80px + ชื่อช่วงวัย · เลือกแล้วเรียก `setStage` → ถ้า `petHasEarnedXP` (xp ≠ ต้นช่วง หรือ `xp_event_count > 0`) ขึ้น modal ยืนยัน (shell เดียวกับ Replace this pet — เพิ่ม props title/body/confirmLabel ไม่ fork) · toast บอกช่วงวัยใหม่ · `PetStageIcon` แยกออกจาก palette hover card มาใช้ร่วม
  - VO: `pet_stage_changed` เปิด overlay/modal เฉพาะ **สมาชิกในห้องของ pet** (`is_resident`) — คนที่ XP ทำให้ข้ามได้ลำดับเต็ม คนอื่นในห้องได้ modal คนนอกห้องไม่เห็นอะไร (ตีความ "สมาชิก" = residents เหมือน quest/ลูบ/วงกลม)
- **verify:** api `go build/vet/test` ✅ (เทสใหม่ start-XP table + สอดคล้อง `derivePetStageFromXP`, handler stage-only/invalid) · app vitest ทั้งชุด 1715 ✅ (pet-marker-menu +7) · tsc/eslint สะอาด · **ยังไม่ได้ live-test ใน editor** (admin login ในเบราว์เซอร์ทดสอบติด) — ทดสอบจริง: เปิด Workspace editor → คลิก pet → กดรูปช่วงวัย → เลือก → ดู XP bar ใน VO เปลี่ยน
- **ติด/ต่อจากนี้:** ถ้า "สมาชิก" ที่ user หมายถึงคือสมาชิก workspace ทุกคน (ไม่ใช่แค่คนในห้อง) ให้ถอด gate `is_resident` บรรทัดเดียวใน hero · override ไป stage ที่สูงกว่าจะทำให้คนในห้องที่ออนไลน์เห็น modal "สัตว์เลี้ยงของคุณเติบโตแล้ว" (ตั้งใจ — pet โตจริง) · undo/redo ของ editor ยังไม่ครอบ pet

---

## 2026-09-07 (รอบ 49) — ก่อนคลิกต้องเคลื่อนไหววนไปก่อน

**user บอก:** "ก่อนจะกด click มันต้องเล่น animation วนไปเรื่อยๆ ก่อน" (screenshot prompt ที่เป็นรูปนิ่ง Happy)

- **ทำ (app #290 → develop):** phase prompt ใช้ `PetSheetPlayer` ตัวเดียวกับ reveal — ไข่เล่น Wobbling วน, baby/adult เล่น Happy วน ในกรอบ 240 จนกว่าจะคลิก · โหลดชีทไม่ได้ → รูปนิ่งเหมือนเดิม
- **verify:** vitest ทั้งชุด ✅ · headless Chromium บน `/dev/preview/room-pat`: มี canvas 1 ตัวใน prompt ทั้ง egg→baby และ baby→adult, ภาพ 3 ช็อตห่างกัน 90–260 ms ต่างกันทุกคู่ = เคลื่อนไหวจริง — ยังไม่ได้เทสใน VO จริง (login)
- **artifact** เดโมอัปเดต: prompt วน (ไข่โยก 4 เฟรม @16 fps / Happy @8 fps) แล้วต่อด้วยลำดับเดิม
- ตอนนี้ทั้งลำดับไม่มีเฟรมนิ่งเหลือแล้ว: วน → GIF ออก (egg) → flash → GIF เข้า → นั่งลง → Happy วน → modal (รูปใน modal ยังนิ่ง 160px ตาม Figma)

---

## 2026-09-07 (รอบ 48) — reveal ไม่ smooth (ค้างเป็นรูปนิ่ง) · รูปใหญ่เกิน

**user บอก:** "animation ตอนเล่นมันไม่ smooth เล่น evo ก่อน แล้วค่อยๆ นั่งก่อน แล้วเล่น happy วนไป · รูปมันขนาดใหญ่มาก ลดลงหน่อย"

- **ทำ (app #289 → develop):**
  - reveal เล่นจริง: ชีท **Sitting 1 รอบ** (ยืน → นั่ง 0.75 วิ) แล้ว **Happy วน** จนกว่าจะคลิก — component ใหม่ `PetSheetPlayer` (canvas, row 0) ตัดเฟรมด้วย grid detection ตัวเดียวกับ VO · `lib/pet-sheet-player.ts` = จังหวะเฟรม + layout สเกลเดียว/baseline เดียว (Sitting สูงกว่า Happy ถ้า fit แยกกันตัวจะกระตุกตอนสลับ) · โหลดชีทไม่ได้ → กลับเป็นรูปนิ่ง
  - `PET_EVOLUTION_STILL_PX` 320 → **240**, กรอบ GIF 1088 → **816** (ยัง 3.4×) · `PetEvolutionEvent.toRestAnimation` = Sitting ของ stage ใหม่ (hero + harness)
- **verify:** vitest ทั้งชุด 1708 ✅ · tsc/eslint/prettier สะอาด (ยกเว้น 3 error เดิม) · headless Chromium บน `/dev/preview/room-pat`: prompt → GIF ไข่ → โผล่ → ยืน → กำลังนั่ง → Happy วน ในกรอบ 240 ขนาดเท่ากันตลอด — ยังไม่ได้เทสใน VO จริง (login)
- **artifact** เดโมอัปเดตตาม (240/816 + นั่งลง → Happy วน) · ภาพในข้อ 2c ยังเป็นชุดรอบ 47 (ก่อนลดขนาด)
- **ต่อจากนี้:** ถ้าอยากให้ prompt เคลื่อนไหวด้วย (ไข่โยก / Happy วน ก่อนคลิก) ใช้ `PetSheetPlayer` ตัวเดียวกันได้เลย — ยังไม่ทำเพราะไม่ได้ขอ

---

## 2026-09-06 (รอบ 47) — ขนาดไม่เท่ากันตอนเล่น GIF · อยากเห็น animation ทุกช่วง · ใช้รูป Happy · หน้าโชว์ `/dev/preview/room-pat`

**user บอก:** "ตอนเล่น animation มันเล็ก แล้วกลับมาเป็นรูป pet ใหญ่อีก ไม่เท่ากัน" · "อยากเห็น animation ตอน evo ช่วงต่างๆ ด้วย" · "เอารูป happy มา เพราะมันนั่งหันหน้ามาตรงเลย" · "ไม่ได้ให้แก้ใน preview อย่างเดียว ต้องแก้ของจริงด้วย" · "สร้าง path /dev/preview/room-pat จะเอาไปโชว์"

- **พบ (แก้ความเข้าใจรอบ 46):** `tb_pet_animation` มี slot Evolution **ครบ 4 stage ของทุก type จริง** (Pie/POP/ปรื๊ด…) แต่ความหมายต่างกัน — egg = ท่าออก (24 เฟรม ไข่โยก→ร้าว→ระเบิดเต็มผืน) · baby/adult/evolved = ท่าเข้า (8 เฟรม เริ่มจากแสงเต็มผืน→เงา→ตัวจริง) → กฎเดิม "เล่น GIF ของ stage ที่ออก" ทำให้ baby→adult เล่นภาพ baby โผล่ (ผิด)
- **สาเหตุขนาดไม่เท่า:** GIF 960² วางตัวสัตว์แค่ ~26–32 % ของผืน (ที่เหลือเผื่อแสงระเบิด) แต่รูปนิ่งตัดชิดเต็มกรอบ 320 · overlay เดิมวาด GIF `max-h-[100vh]` → ตัวสัตว์เหลือ ~1/3 แล้วกลับมาใหญ่ตอน reveal และขึ้นกับความสูงจอ
- **ทำ (app #288 → develop):**
  - `lib/pet-evolution.ts`: phase ใหม่ `prompt → playing (GIF ไข่ เฉพาะ egg) → flash → arriving (GIF stage ใหม่ 1.2 วิ) → reveal → modal` · `pickPetEvolutionAnimation` คืนเฉพาะ egg · เพิ่ม `pickPetArrivalAnimation` · `PET_EVOLUTION_GIF_SCALE = 3.4` → GIF ทั้งสองวาดในกรอบ 1088px, overlay `overflow-hidden`
  - `lib/pet-scene.ts`: `PET_STAGE_IDLE_SLOT` baby/adult/evolved = **Happy** (fallback Sitting → Idle → Walking) → กระทบรูปนิ่ง overlay, modal, การ์ด `pet_card`, ไอคอนป้ายชื่อ/วงกลม และหน้า admin (pet-marker-menu, object-library)
  - `PetEvolutionEvent.arrivalGifUrl` + hero ส่งค่า · harness: fixture ปรื๊ด เพิ่ม Happy + GIF ทุก stage, ปุ่ม "แชร์ให้เพื่อน" เปิด `PetShareModal` จริงบน query cache ที่ seed ไว้ (`staleTime ∞` กัน refetch → 401 → เด้ง login), section ใหม่ `PetSharePreview` = การ์ดในแถวแชทแบบ message-item
  - **`/dev/preview/room-pat`** (public ใน `PUBLIC_PATHS` ของ proxy.ts + auth-guard.tsx, ไม่ผูก NODE_ENV) = overlay ทั้ง 3 ขั้น 2 มุมมอง + share picker + การ์ด + วงกลม/ป้ายชื่อ PixiJS · ถ้า build ไม่มี `NEXT_PUBLIC_ROOM_PET=true` หน้าจะขึ้นแถบเตือนและ overlay ไม่แสดง
- **verify:** vitest ทั้งชุด 1702 ✅ · tsc เหลือแค่ 3 error เดิมของ develop (`pet-creation-wizard.test.tsx`, `pixi-game-scene.test.ts` — ไม่เกี่ยว) · **ถ่ายภาพจริงด้วย headless Chromium** (`playwright` ใน node_modules + chromium-1228) บน :3200 `/dev/preview/room-pat`: egg→baby ไข่ prompt ≈ 260×320 · ไข่ใน GIF ≈ 226×250 · เงา baby ≈ 170×260 · reveal ≈ 160×250 → ขนาดเดียวกัน · baby→adult = flash → GIF adult → reveal · share DM/กลุ่ม/แชนเนล + เลือกแล้ว · การ์ด 3 แบบ (ปกติ / ไม่มีรูป → รอยเท้า / body เพี้ยน → ข้อความ) — ยังไม่ได้เทสใน VO จริง (login)
- **artifact** "Room Pet Evolution Flow" อัปเดต: เดโมเล่นได้ทั้ง 3 ช่วงด้วย geometry เดียวกับโค้ด + ข้อ 2c ภาพจริงจาก component · [evolution-flow.md](evolution-flow.md) แก้ §2/§4/§5
- **ติด/ต่อจากนี้:** ค่า 3.4× เป็นค่าคงที่จาก asset ปัจจุบัน → ควรเขียนข้อกำหนดผืน GIF ใน Pet Management · ถ้าดีไซน์ต้องการ "ท่าออก" ของ baby/adult ต้องเพิ่ม slot · dev/uat ต้องตั้ง `NEXT_PUBLIC_ROOM_PET=true` ถึงจะโชว์ overlay บน room-pat

---

## 2026-09-06 (รอบ 46) — "ยังไม่รู้ UI/flow ตอน XP เต็มแล้ว evo ช่วยทำ preview มาให้ดู"

- **ทำอะไร:** ไล่โค้ดจริง (api `Award`/`notify`, `notification_pet.go`, ws relay, `lib/pet-evolution.ts`, overlay/modal/share) แล้วสรุปเป็น [evolution-flow.md](evolution-flow.md) + artifact อ่านง่าย [Room Pet Evolution Flow](https://claude.ai/code/artifact/31179fdf-e705-49fb-aef5-5440bf0c18b8) (ใครเห็นอะไร · แจ้งเตือนจริงถึงใคร · sequence diagram · ช่องว่าง) · เพิ่ม section **Evolution flow** ใน `/dev/room-pet-preview` กดเล่น overlay จริงได้ทั้งมุมคนที่ทำให้ข้าม (prompt → GIF → flash → reveal → modal) และมุมคนอื่น (modal) ด้วยชีทจริงของปรื๊ด — [app #287](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/287)
- **สรุปสั้น:** ws ส่ง `pet_stage_changed` ให้ทุกคนที่เปิด VO ของ workspace · คนที่ XP ทำให้ข้ามได้ animation เต็มจอ (คลิกก่อนเล่น, Esc = ไป modal) · คนอื่นได้ modal ทันที · แจ้งเตือน **จริง** 3 แบบเข้ากระดิ่ง (ไม่มี toast ไม่มีอีเมล): `pet_growth` ทุกสมาชิก+owner · `pet_milestone` 50/75/90% ทุกสมาชิก+owner · `pet_reminder` 09:00 ICT เฉพาะ resident ที่ยังไม่เล่นวันนี้ · ปิดได้ที่ Setting → Notifications → กิจกรรมสัตว์เลี้ยง
- **ช่องว่างที่เห็น:** GIF Evolution มีแค่ egg ของ type จริง (stage อื่นข้ามไป flash) · คนไม่ออนไลน์ไม่มี replay · ไม่มีเสียง/effect บนแมพ · ยังไม่ได้เทส e2e ในเบราว์เซอร์
- verify: harness tsc/eslint ✅ · vitest pet-evolution 31 ✅ · artifact เผยแพร่แล้ว (private)

---

## 2026-09-06 (รอบ 45) — pop กับ pet เชื่อมได้หลายคนพร้อมกัน → ต้องทีละคน

**user บอก:** "ระบบ pop pet เชื่อมกันมากกว่าหนึ่งคนได้ ต้องเชื่อมได้ทีละคนเท่านั้น" (screenshot: 2 คนติด pet แล้วเกิด capsule ทั้งคู่)

- **สาเหตุ:** `_drawPetLinks` วาด capsule ให้**ทุกคู่** (pet, member) ที่ dwell ครบ · ฝั่ง hero มี poll 200ms ของตัวเองตัดสินปุ่มมือแยกจาก scene อีกชุด
- **ทำ:** `_drawPetLinks` 2 pass — เก็บนาฬิกา dwell/หลุดของทุกคู่ตามเดิม แล้วเลือก **คนเดียวต่อ pet** = `pickPetPopPartner` (คนที่มายืนติดก่อนสุด · เสมอตัดที่ id ให้ทุก client ตรงกัน · ตรงกับ attention list ของ AI) → capsule + หันหน้า + report เฉพาะคู่นั้น · คนอื่นยังนับเวลาต่อ พอคนแรกเดินออก คนถัดไปได้ pop · callback `(petId, memberId|null, isSelf)` → hero ตั้ง `proximityPetId` (ปุ่มมือ) จากนี้แทน poll เดิม (ลบทิ้ง) → ปุ่มกับ capsule ใช้ source เดียว คนที่สองไม่ได้ทั้งคู่
- PR: [app #286](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/286) merge develop แล้ว · tsc ✅ · vitest **1695** ✅ · eslint/prettier ✅ · **ไม่ได้เห็นในเบราว์เซอร์**
- ลอง (2 คน): คนแรกยืนติด 1 วิ → capsule+ปุ่ม · คนที่สองมายืนติด → ไม่มี capsule ไม่มีปุ่ม pet ยังหันหาคนแรก · คนแรกเดินออก → capsule ย้ายไปคนที่สองภายใน ~0.1 วิ

---

## 2026-09-06 (รอบ 44) — XP medal บน quest tile ไม่ตรง Figma

**user บอก:** "รูป xp icon มันแปลก ไม่ตรงตาม Figma" (Pet menu `4381:424480` → quest tile `4331:343228`)

- **สาเหตุ:** `xp-icon.png` บน R2 (รอบ 20 กว่า) เป็นภาพ 50×50 ที่ย่อจากศิลป์ต้นฉบับ → เบลอทุกขนาด และเรา render medal แค่ 24px กลาง tile ส่วน Figma ใช้ image fill 1024² ของเหรียญเต็ม tile + "+N" pixel font หนาขอบดำทับริบบิ้น
- **ทำ:** ดึง image fill จาก Figma (1024²) → trim ให้เหลือเหรียญ → ย่อเป็น 192² → อัป R2 **`static/pet/shared/xp-medal.png`** (key ใหม่ เพราะ key เก่า cache immutable 1 ปี) · `PET_XP_ICON_URL` ชี้ไฟล์ใหม่ (tooltip +XP 16px คมขึ้นด้วย) · tile 50×50 radius 8 white/10 · medal 34px ชิดบน · "+N" Pixelify 15px bold ขอบดำ 1px
- PR: [app #285](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/285) merge develop แล้ว · tsc ✅ · vitest **1694** ✅ · eslint/prettier ✅ · **ไม่ได้เห็นในเบราว์เซอร์** (เทียบจาก Figma export crop กับ geometry ที่วัด)
- asset เก่า `xp-icon.png` ยังอยู่บน R2 (ไม่มีใครใช้แล้ว) — ลบได้ถ้าต้องการ

---

## 2026-09-06 (รอบ 43) — pop แล้วนั่งเลย · ป้ายคนบังป้าย pet · กรอบความคิดตอนลูบหัว

**user บอก:** "ตอนเกิด pop กับ pet อยากให้มันนั่งลงเร็วขึ้น ตอนนี้ยืนเล่นพักแล้วค่อยนั่ง" · "ชื่อตัวละครไปบังป้ายชื่อ pet ถ้า hover แล้วต้องไม่บัง" · "กดลูบหัว อยากให้เป็นกรอบความคิดขึ้นบนป้ายชื่อ แสดงหน้า pet ตามช่วงวัย มี animation ลูบหัว ขึ้นหัวใจ แล้วหายไป เห็นแค่เราคนเดียว เอาหัวใจเดิมออก"

| เรื่อง | ทำ |
|---|---|
| pop → นั่งเลย | scene แจ้ง pop เกิด/หลุด (`setOnPetPopChange`) → hero ตั้ง `popSince` ใน live position → `petSettleAt()` = เร็วสุดระหว่าง "หยุด + 8 วิ" กับ "pop เกิด" → นั่ง (Sitting 1 รอบ) แล้วเล่น loop attention (Happy = ชีทนั่ง) **ทุก mood** · `petIsSeated()` ตามด้วย → ลุกก่อนเดินยังทำงาน · walk เคลียร์ popSince |
| ป้ายบัง | `PET_NAME_TAG_Z_HOVER` → MAX-5 เหนือทุกอย่างของตัวละครใน tag layer (ป้ายตัวเอง MAX-10 เคยเสมอกันแล้วชนะ · ป้าย hover คน MAX-7 · bubble MAX-6) |
| กรอบความคิดลูบหัว | `PetPatBubble`: กรอบเมฆขาว + หางจุด เหนือป้ายชื่อ · หน้า pet ตาม stage (frame ตัดจากชีท) · มือ lucide ลูบ (keyframes) · หัวใจ 3 ดวงลอยขึ้นจาง · หายใน 2.2 วิ · ตำแหน่งคำนวณเหนือป้ายทุกเฟรม (`--pet-plate-top`) · ลำดับ feedback: `xp` (ถ้าได้) → `pat` · แทน ♥ tooltip เดิม · อยู่บน state ของคนลูบ → **เห็นคนเดียว** (คนอื่นยังเห็น pet เล่น Happy) · harness มี sample |

- PR: [app #284](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/284) merge develop แล้ว · tsc ✅ · vitest **1694** ✅ · eslint/prettier ✅ · **ยังไม่ได้เห็นในเบราว์เซอร์** (user รัน stack เองจาก checkout หลัก — ต้อง pull develop + build)
- ลอง: เดินติด pet 1 วิ → capsule + pet หันมา + นั่งลงทันที · hover pet → ป้าย pet อยู่หน้าป้ายทุกคน · กดมือ → กรอบความคิดหน้า pet + มือลูบ + หัวใจลอย 2 วิ แล้วหาย · เปิดอีกแท็บด้วยอีกคน → คนนั้นไม่เห็นกรอบ

---

## 2026-09-06 (รอบ 42) — pop กับ pet ไม่หันหน้าทันที · ตัว pet ชนขอบล่าง tile

**user บอก:** "ตอนเชื่อม pop กับ pet มันไม่หันหน้ามาทันที ต้องรอ delay … ถ้าเกิด pop ให้หันหน้าหาคนที่เกิด pop ทันที" · "ขยับตำแหน่งตัว pet ขึ้นไปนิดหน่อย มันชนขอบล่างมากเกินไป"

| เรื่อง | สาเหตุ | แก้ | ที่ |
|---|---|---|---|
| หันช้า (ฝั่ง ws) | `updateAttention` อยู่**หลัง** rest gate → pet ที่พักอยู่ (4–20 วิ) หันหลังพักจบ | ย้ายบล็อก attention ไว้ก่อน gate: หัน (และก้าวเข้าหาเมื่อยืนนิ่งพอ) ใน tick ที่คนมาถึง · wander ยังรอพักจบ | [ws #42](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/42) |
| หันช้า (ฝั่ง client) | ต้องรอ `pet_state` จาก ws (tick 200ms + network) | scene ตั้ง **facing override** บน `PetLayer` ตอน pop เกิด (คู่ที่เกิดก่อนชนะ · `petFacingTowards` กฎเดียวกับ AI) → หันเฟรมเดียวกับ capsule · ws ยืนยันตามมา · ตอนเดินใช้ facing ของ AI | [app #283](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/283) |
| ชนขอบล่าง | frame ของ pet ถูก crop ชิดขอบด้วย grid detector ส่วน sheet ตัวละครมี margin → วางบน foot line เดียวกันแล้ว pet เตี้ยลงไปชนขอบ tile | `PET_DRAW_LIFT_Y = 5` ยกเฉพาะตอนวาด (sprite/outline/ป้าย/วง/hit rect) · foot line, depth sort, tile maths เหมือนเดิม | app #283 |

- verify: ws `go test ./...` ✅ · app tsc ✅ · vitest **1693** ✅ (ใหม่: facing override ยืน/เดิน/เคลียร์ · anchor/rect ตาม lift) · eslint/prettier ✅ · **ยังไม่ได้เห็นบน local** — user รัน stack เองจาก checkout หลักที่ยังเก่า (ดู blockquote บน)
- ลอง (หลัง pull + build ใหม่ทั้ง 3 repo): เดินไปติด pet 1 ช่อง หยุด 1 วิ → capsule + pet หันมาพร้อมกันทันที · ตัว pet ยกขึ้นจากขอบล่าง ~5px

---

## 2026-09-06 (รอบ 41) — "pet ขึ้นตั้งแต่เฟรมแรกแล้ว แต่ยังยืนค้างก่อนถึงขยับ ต้องเข้ามาแล้วเห็นขยับต่อได้เลย"

- **สาเหตุ:** มี 2 สถานะที่เป็นภาพนิ่ง**โดยดีไซน์**เดิม — ช่วง "ยืน" 8 วิแรกหลังหยุด = Walking frame 0 ค้าง · pet ที่นั่งแล้วและ mood neutral = ค้างที่ frame สุดท้ายของ Sitting ตลอด (Happy loop มีเฉพาะ mood happy)
- **ดูชีทจริงของ Pie/POP ทุก stage:** `Idle` = ยืนหายใจ/ขยับ · `Sitting` = ท่ากำลังนั่งลง (transition) · `Happy` = **นั่งอยู่**แล้วกระดิก · `Sad` = loop เศร้า
- **ท่าใหม่ (`petPose`):**

| สถานะ | เดิม | ใหม่ |
|---|---|---|
| หยุด < 8 วิ | Walking frame 0 นิ่ง | **Idle loop** |
| นั่งแล้ว + happy | Sitting 1 รอบ → Happy loop | เหมือนเดิม (Happy = loop ตอนนั่ง) |
| นั่งแล้ว + neutral | Sitting 1 รอบ → ค้าง frame สุดท้าย | **ยืน Idle loop ต่อ** (ไม่มีชีท "นั่งแบบ neutral") |
| sad | Sad loop | เหมือนเดิม |
| type ที่ไม่มี Idle | — | ใช้ chain เดิม |

- `petIsSeated()` เป็นที่เดียวที่ตัดสินว่า pet นั่งอยู่ → hero เล่นท่าลุก (Sitting ถอยหลัง) เฉพาะตัวที่นั่งจริง ตัวที่ยืน Idle เดินออกได้เลย (ผ่าน `petSeatedRef` ให้ handler ของ ws เห็น pets/config ปัจจุบัน)
- PR: [app #282](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/282) merge develop แล้ว · tsc ✅ · vitest **1692** ✅ · eslint/prettier ✅ · local prod build :3000
- **ข้อที่ตัดสินเอง (บอก user แล้ว):** neutral ไม่นั่ง เพราะไม่มีชีทนั่งแบบ neutral — ถ้าอยากให้นั่งแล้วใช้ Happy loop ทุก mood ที่ไม่ sad เปลี่ยนบรรทัดเดียว

---

## 2026-09-06 (รอบ 40) — โหลดเข้าแล้วไม่เห็น pet ทันที / เห็นแล้วยืนค้าง → พร้อมตั้งแต่หน้าโหลด

**user บอก:** "โหลดเข้าไปจะไม่เห็นสัตว์ทันที และเมื่อเห็น สัตว์เลี้ยงยืนท่าค้างอยู่ก่อน อยากให้โหลดให้เสร็จตั้งแต่หน้าโหลด"

| สาเหตุ | แก้ | ที่ |
|---|---|---|
| snapshot ตำแหน่ง pet (`pet_state` ×N หลัง welcome) มาถึงตอนอยู่หน้า `/loading` **ก่อน** hero ของ `/play` จะมี handler → pet รอ heartbeat ถัดไป (≤ 2 วิ) ถึงจะโผล่ | `vo-session-store` เก็บ `pet_state` ล่าสุดต่อ pet (`pets`, เคลียร์พร้อม session, `pet_removed` ลบ) · hero seed `petLiveBufferRef` จาก store ตอน mount (`moveMs: 0` = วางเลย ไม่ glide) | app #281 |
| sheet โหลด+ตัด frame **หลัง** office ขึ้นจอ ทีละ entity (ตัด grid บนรูป 1000×1000 = ช้า) | cutter ของ `PetLayer` memo ต่อ sheet (`makeCachedCutter` — ตัดครั้งเดียวต่อ session, ตัดพังไม่จำ) · `/loading` prefetch pet list + XP config เข้า React Query key เดียวกับ hook แล้ว warm sheet rest/walk/Happy/Sad ของ stage ปัจจุบันทุกตัว (`vo-preload.preloadPetSheets`) เป็น asset wave C · จำกัด 6 วิ ไม่ค้างหน้าโหลด | app #281 |
| state แรกของ pet ถูกนับเป็น "เพิ่งหยุด" → ยืนค้าง 8 วิ ก่อนนั่ง ทุกครั้งที่เข้า | ws ส่ง **`stopped_for_ms`** ใน `pet_state` (petAI จำ `stoppedAt`: seed / ก้าวสุดท้ายลง / ถูกตัดเดิน) · client ตั้ง `stoppedAt = now − stopped_for_ms` → pet ที่นั่งอยู่แล้วเปิดมาก็นั่ง/เล่นท่า mood เลย | ws #41 · app #281 |

- PR: [ws #41](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/41) · [app #281](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/281) — merge develop แล้ว
- verify: ws `go test ./...` ✅ (test ใหม่ `ReportsHowLongThePetHasBeenStanding`) · app tsc ✅ · vitest **1688** ✅ (ใหม่: memo cutter + retry เมื่อพัง · `collectPetSheets` ต่อ stage/dedupe/egg · `preloadPetSheets`) · eslint/prettier ✅ · local: prod build :3000 + ws build ใหม่บน 3003 พร้อมให้ user ลอง — **ยังไม่ได้เห็นเองว่า pet ขึ้นตั้งแต่เฟรมแรก** (ต้อง login)
- ลอง: reload หน้า VO → pet ควรอยู่ตำแหน่งจริง + ท่าจริง (นั่ง/mood) ตั้งแต่เฟรมแรก ไม่ยืนค้าง ไม่ pop ทีละตัว · หน้าโหลดอาจนานขึ้นเล็กน้อย (โหลด sheet ≤ 6 วิ)

---

## 2026-09-06 (รอบ 39) — ลองบน local จริง (build+start :3000) → 6 จุด + คูลดาวน์ลูบ 30 นาที

**user บอกเป็นชุด (ลองบน local ทีละรอบ):** "วงกลมไม่มีพื้นหลังของสัตว์เลี้ยง" · "จาก emoji เป็น icon และแสดงให้เป็นปุ่ม" · "การรันต้อง build ก่อนและ start run ที่ port 3000" · "วางสัตว์เลี้ยงใน ฟหกฟหก" / "ไม่เห็นเลย" · "ผิด เอาชื่อกลับมาตอนที่ซูมเข้าไป" · "ซูมออกกดรูปมือแล้วขึ้นเหมือนให้กดเดิน" · "hover ป้ายชื่อแล้วขึ้นชื่อ zone ของคนนั้น ต้องไม่ขึ้น" · "ลูบหัวได้ 30 นาทีต่อคน · เพิ่ม hover ให้ปุ่มลูบ"

| เรื่อง | สาเหตุ / ทำ | ที่ |
|---|---|---|
| pet ไม่ขึ้นบน local เลย | **flag ไม่เปิด**: โค้ดอ่าน `NEXT_PUBLIC_ROOM_PET` แต่ `.env` มีแค่ `NEXT_PUBLIC_PET` (เมนู admin คนละตัว) → build ใหม่ด้วย flag · **ws/api บน local เป็น build 4 ก.ย.** (ws ยังไม่มี pet AI → ไม่มี `pet_state` → client ไม่วาด) → rebuild จาก develop + restart 3003/3002 · วาง pet เพิ่ม 1 ตัว (Pie, กลุ่ม Room 1, tile 47,10) ใน dev DB — ห้อง test ทั้งสองมี pet อยู่แล้ว | local เท่านั้น |
| วงกลมโปร่ง | รูปในวงเป็น frame ตัดจาก spritesheet มีมุมโปร่ง → วางพื้นทึบสีป้าย (#141420) ไว้หลังเสมอ | app #280 |
| 🤚 → ปุ่มจริง | disc เขียว #58D68D ขอบขาว + icon มือ lucide (rule 12) วาดด้วย `Graphics.svg` · **hover**: #4dc47d + 1.15× + cursor pointer (`PetLayer.petButtonAt/setButtonHovered`, scene ตั้ง `canvas.style.cursor`) ทั้งปุ่มในป้ายและบนวง | app #280 |
| เอาป้ายกลับมา | รอบ 38 เอาป้ายออกทุก zoom → **ผิด** · ตอนนี้: zoom ≥ 3 ป้าย (ปุ่มอยู่ท้ายป้าย) · level 1–2 วงกลม (ปุ่มที่ขอบวง) | app #280 |
| ซูมออกกดมือแล้วขึ้น "Double click to move here" | ปุ่มคร่อมขอบวง hit-test เช็คแค่วง → กดครึ่งนอกหลุดถึงพื้น → hit นับวง+ปุ่ม (test pin ขอบนอกสุดของปุ่ม) | app #280 |
| hover ป้ายขึ้นชื่อ zone | `scene.nameplateAt(worldX, worldY)` (ป้าย/วงของคน + ป้าย/วง/ตัว pet) → hero ไม่ตั้ง hoveredZone / claim chip / lock overlay ตอน pointer อยู่บนป้าย | app #280 |
| ลูบได้ 30 นาทีต่อคน | ตาราง **`tb_room_pet_stroke`** (mig 94 + embedded DDL) บันทึกทุกครั้งที่ลูบแม้ไม่ได้ XP (ledger มีแถวเฉพาะตอนได้ XP ใช้คุมไม่ได้ตอน activity ปิด) · `/play` → **429 `STROKE_COOLDOWN` + `detail.next_at`** · response `next_stroke_at` · list/status `stroke_available_at` ของผู้เรียก · client ซ่อนปุ่มจนถึงเวลา กลับมาเอง · `[P]` เงียบตอนคูลดาวน์ · **ตีความ: ต่อคนต่อ pet** | api #86 · app #280 |

- PR: [app #280](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/280) · [api #86](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/86) — merge develop แล้วทั้งคู่ · mig 94 รันบน dev DB แล้ว
- verify: api `go test ./...` ✅ (test ใหม่ 3) · app tsc ✅ · vitest **1684** ✅ · eslint/prettier ✅ · **เห็นจริงบน local**: prod build :3000 + api/ws develop ล่าสุด user เดินทดสอบเอง (screenshot 3 รอบ) + raster จาก PixiJS harness (`/dev/room-pet-preview` มี section วงกลม/ป้าย ปุ่ม hover)
- **วิธี verify บน local ที่ใช้ได้จริง (จดไว้):** dev harness หน้า `/dev/room-pet-preview` expose `__harness = {app, tick}` บน host div → ตอน Browser pane ซ่อน rAF ไม่เดิน ให้เรียก `tick()` เองแล้ว `renderer.extract.base64()` → เขียน PNG ดูได้ · หน้า VO จริงยังต้อง login (พิมพ์รหัสไม่ได้)
- ค้าง: tooltip บอกเวลาที่เหลือตอนกด `[P]` ระหว่างคูลดาวน์ (ยังไม่ทำ ต้องเพิ่ม i18n) · ถ้าคูลดาวน์ต้องเป็น "ต่อคนรวมทุก pet" แก้ query เดียวใน `lastStrokeAt`

---

## 2026-09-06 (รอบ 38) — "ป้ายชื่อ pet เอาออกทุก zoom เลย เหลือแต่วงกลม"

- ตอบข้อสมมติของรอบ 37 (ป้ายอยู่ที่ zoom ≥ 3): **ไม่เอา — เอาออกทุก zoom**
- `PetLayer` ไม่สร้างป้ายชื่อแล้ว · **resident** เห็นวงกลมโปรไฟล์ (รูป stage · hover ขึ้นชื่อ · ขอบเขียว + z เหมือนวงตัวละคร) ลอยเหนือ sprite **ทุก zoom** · 🤚 เป็น badge มุมขวาล่างของวง ตอนลูบได้ (ติด 1 ช่อง + 1 วิ หรือ hover ในระยะ) กดที่วง = ลูบ ไม่งั้นกด = เปิด panel · `[P]` เหมือนเดิม · non-resident เห็นแค่ sprite (กดยังเปิด panel ได้) · วงคู่ตอน pop ที่ซูมออกเหมือนรอบ 37
- `makePetNameTag`/`layoutPetNameTag` ยังอยู่ใน utils เพราะหน้า dev preview (`views/dev/room-pet-preview`) ใช้ — ไม่ได้ลบ
- PR: [app #279](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/279) merge develop แล้ว · tsc ✅ · vitest pet-layer/scene/pet-scene 378 ✅ · eslint/prettier ✅ · **ยังไม่ได้เห็นในเบราว์เซอร์**
- ลอง: ห้องเรา → วงกลมเหนือ pet ทุก zoom hover ขึ้นชื่อ · ยืนติด 1 วิ → 🤚 โผล่บนวง กดวง = ลูบ · ห้องคนอื่น → ไม่มีวง

---

## 2026-09-06 (รอบ 37) — pet เดินทะลุกล่อง · ลุกก่อนเดิน · 🤚 ย้ายเข้าป้ายชื่อ · ซูมออกแล้วป้ายบังตา → วงกลมแบบตัวละคร

**user บอก (2 ข้อความ):** (1) "box ไหนที่ผ่านไม่ได้ สัตว์ต้องผ่านไม่ได้ด้วย · หยุดเดิน → นั่ง 1 รอบ → ท่า mood วน · ก่อนเดินเล่นท่านั่งกลับหลังเหมือนกำลังลุก · ui บังกันไปหมด ย้าย press p pat ออก เหลือแค่รูปมือแล้วย้ายไปอยู่ในชื่อของสัตว์ · hover สัตว์ต้องขึ้นของสัตว์มาด้านหน้ากดได้" (2) ส่ง screenshot ตอนซูมออก: "เอาชื่อทั้งหมดของสัตว์เลี้ยงออก (บังตา) · แสดงวงกลมเหมือนของตัวละคร เฉพาะสัตว์ที่เรามี private zone ใน room zone นั้น · hover แล้วบอกชื่อ · อยู่ใน pop กับสัตว์ตอนซูมให้ขึ้นวงคู่กันเหมือนคนอยู่ใน meeting"

| ข้อ | ทำ | ที่ไหน |
|---|---|---|
| pet ทะลุกล่อง | `tileBlocked` ถือว่า grid = nil คือ "ไม่มีอะไรบล็อก" → ห้องที่ snapshot `vo:obstacles` ยังไม่มา pet เดินทะลุโต๊ะ · ตอนนี้ `tileAllowed` **fail closed** เมื่อไม่มี grid (กฎเดียวกับ zone ใน #34) · test ใหม่ 2 ตัว (ไม่มี grid = ไม่เดิน · 300 decision ไม่เคยเหยียบ tile ที่บล็อก) | [ws #40](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/40) |
| ลุกก่อนเดิน | pet ที่**นั่งอยู่แล้ว** (ยืนนิ่ง ≥ 8 วิ) พอ `pet_state` มา `moving:true` → client ตั้ง `standUpFrom` → `petPose` เล่น Sitting **ถอยหลัง** (`playback:"once-reverse"`) sprite ค้างที่เดิม (`holdMotion`) จนจบชีท แล้วค่อย glide + Walking · `petPoseTransitionsAt` นัดเวลาสลับชีท · หยุด → Sitting 1 รอบ → mood loop มีอยู่แล้วจากรอบ 33 | app |
| 🤚 เข้าป้ายชื่อ | ลบปุ่มมือ DOM + tooltip `Press [P]` (ไฟล์ `pet-stroke-marker.tsx` ออก · overlay เหลือแค่ +XP/♥ หลังลูบ) · ป้ายชื่อ pet มี slot `action` = 🤚 ท้ายป้าย ขึ้นเฉพาะ pet ที่ resident เดินไปติด (1 ช่อง + 1 วิ) หรือ hover ตอนอยู่ในระยะ · ซ่อนตอนกำลังลูบ (ไม่มีปุ่มตาย) · ป้ายนับเป็นตัว pet ตอน hover/click · pet ที่ hover ป้ายเด้งมา `MAX-10` (เหนือป้ายคน `MAX-11`) · คลิก 🤚 = ลูบ (`setOnPetStrokeClick` เช็คก่อน click เปิด panel) · `[P]` ยังใช้ได้ | app |
| ซูมออก (level 1–2) | ป้าย pet **ซ่อนทั้งหมด** · **resident** เห็นวงกลมโปรไฟล์แบบตัวละคร (รูป stage ปัจจุบัน · ชื่อขึ้นตอน hover · hit-test ที่วง) — non-resident เห็นแค่ sprite ไม่มีอะไรให้ hover · `ScenePet.viewerIsResident` ← `is_resident` · pop ที่เกิดแล้ว (ติดกัน + dwell) → วงคน + วง pet วาดเป็น**คู่ซ้อนกัน** กึ่งกลางระหว่างสองตัว (คนซ้าย pet ขวา · ซ้อน 8px เท่า `-space-x-2` ของ facepile) hover ตามตำแหน่งคู่ · 1 คนต่อ pet (pop ที่เกิดก่อนได้ที่) | app |

- PR: [app #278](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/278) · [ws #40](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/40) — merge develop แล้วทั้งคู่
- verify: ws `go test ./...` ✅ · app tsc ✅ (3 error เดิมใน test file อื่นบน develop ไม่เกี่ยว) · vitest **1678** ✅ (130 ไฟล์) · eslint/prettier ✅ · **ยังไม่ได้เห็นในเบราว์เซอร์**
- **สมมติที่ตั้งไว้ (บอก user แล้ว):** ป้ายชื่อ pet ยังอยู่ที่ zoom level ≥ 3 (ข้อความก่อนหน้าให้ย้ายมือ**เข้า**ป้าย) — หายเฉพาะตอนซูมออก · ถ้าจะให้หายทุก zoom บอกได้
- **พบระหว่างทาง (ให้ PM):** obstacle grid เป็น**ต่อ workspace** สร้างจาก main floor (`obstacle_grid_builder.go` เรียง `is_main DESC`) — pet (และคน) บน floor อื่นถูกเช็คกับเฟอร์นิเจอร์ของ main floor · เป็นมาก่อน Room Pet · ยังไม่ได้แก้
- ลอง: (ก) ยืนติด pet 1 ช่อง 1 วิ → 🤚 โผล่ท้ายป้ายชื่อ กดแล้วลูบ · hover pet → ป้ายมาหน้าสุด (ข) ปล่อย pet นั่ง > 8 วิ แล้วรอมันเดิน → เห็นลุกก่อน (ค) ซูมออกสุด → ป้าย pet หาย · ห้องเรา: วงกลม+hover ชื่อ · ห้องคนอื่น: ไม่มี · ยืนติด pet ตอนซูมออก → วงคู่

---

## 2026-09-06 (รอบ 36) — "ไหนปุ่ม??" — 🤚 ถูกวาดอยู่**หลัง**แมพมาตลอด

- **สาเหตุจริง:** canvas container เป็น `absolute inset-0 z-1` · wrapper ของ `PetInteractionOverlay` เป็น sibling แบบ absolute **ไม่มี z-index** → อยู่ใต้แมพ · React render ทุกครั้งแต่ไม่มีใครเห็น ตั้งแต่ #251 (6 รอบ) · capsule เห็นเพราะวาด**ใน** canvas — จึงเป็น "ครึ่งเดียวของ pop" ที่โผล่มาให้เห็น (logic proximity ที่แก้ในรอบ 28/35 ไม่ใช่ตัวปิดกั้น)
- **แก้:** `z-30` (เหนือ HUD z-20 · ใต้ pet panel z-40) — [app #277](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/277) · test ใหม่ pin class + ปุ่มกดแล้วลูบ + hint ขึ้นคู่กัน
- บันทึกเป็น memory: overlay DOM ที่เป็น sibling ของ canvas ต้องมี z เสมอ
- vitest **1668** ✅ · **ยังไม่ได้เห็นในเบราว์เซอร์** — ครั้งนี้เป็น stacking ล้วน reload dev แล้วควรเห็น 🤚 + `Press [P]` ทันทีที่ยืนติด pet ~1 วิ

---

## 2026-09-06 (รอบ 35) — pet pop ใช้กฎเดียวกับ pop chat space · 🤚 ไม่ขึ้น

| user บอก | ทำ |
|---|---|
| pop กับสัตว์ให้เกิดแบบเดียวกับตัวละคร: เดินไปหยุด รอนิดหน่อย · **1 ช่องเท่านั้น** · หลุดแบบเดียวกัน | ระยะ `PET_STROKE_RANGE_TILES` 2→**1** (Chebyshev เท่า `chatProximityRadius`) · เกิดหลังยืนนิ่งข้าง pet **1 วิ** (`PET_LINK_DWELL_MS` = 500 stop grace + 500 form debounce ของ ws) โดยทั้งคู่ tile ไม่เปลี่ยน · หลุดหลังห่างเกิน **100 ms** (`chatEndDebounce`) · เดินผ่านไม่ pop |
| เข้าไปใกล้แล้วไม่เห็น UI ลูบ | สาเหตุที่น่าจะเป็น: 🤚/`Press [P]` อิง `settledTile` ที่ commit เฉพาะตอน path จบ/snap ส่วน capsule อ่านตำแหน่งจาก engine ตรง → อันหนึ่งขึ้นอันหนึ่งไม่ขึ้น · ตอนนี้ poll `getPlayerTile()` ทุก 200ms ด้วยนาฬิกา dwell เดียวกัน → 🤚 + hint + capsule ขึ้น/หายพร้อมกัน |

- PR: [app #276](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/276) · vitest **1665** ✅ · **ยังไม่ได้เห็นในเบราว์เซอร์** — ลอง: เดินไปติด pet 1 ช่อง หยุด ~1 วิ → capsule เขียว + 🤚 + `Press [P]` พร้อมกัน · ถอยออก 2 ช่อง → หายทันที

---

## 2026-09-06 (รอบ 34) — user เจอสาเหตุจริงของ "นั่งแล้วลุก": sheet Sitting คือท่ากำลังนั่งลง

- **user ชี้:** เฟรมของ slot `Sitting` = การเคลื่อนไหวจากยืน→นั่ง ดังนั้น loop = นั่งลง-ลุก-นั่งลง ตลอด → "เล่นรอบเดียว แล้วไปเล่นท่าของ mood แทน"
- **ทำ ([app #275](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/275)):**
  - `PetLayer` มี playback 3 แบบ: `loop` · `still` (ค้างเฟรม 0 = ยืน) · **`once`** (เล่นจากตอนที่รับ sheet มาจนจบแล้ว**ค้างเฟรมสุดท้าย** = นั่งอยู่)
  - `petPose`: เดิน→Walking loop · ลูบ→Happy · sad→Sad · egg→Wobbling · หยุด <8 วิ→ยืน (Walking เฟรม 0) · นิ่งครบ 8 วิ→**Sitting once** แล้วค้างนั่ง → mood happy เล่น **Happy loop** ต่อ · neutral นั่งนิ่ง
  - hero ตั้ง timer ที่ 2 จุด (เริ่มนั่ง / นั่งเสร็จ = +ความยาว sheet) เพราะไม่มี event
- ตารางท่าฉบับสุดท้าย (แทนของรอบ 33): เดิน=Walking · หยุด<8วิ=ยืนนิ่ง · นั่งลง=Sitting 1 รอบ · นั่งแล้ว: happy=Happy loop / neutral=ค้างท่านั่ง · egg=Wobbling · sad=Sad · ลูบ=Happy
- **verify:** vitest **1665** ✅ · merge develop · **ยังไม่ได้เห็นในเบราว์เซอร์**

---

## 2026-09-06 (รอบ 33) — ยังรีโหลดแล้ววาร์ป + "สัตว์เป็นโรคลมบ้าหมู"

> user เทสหลัง deploy รอบ 32 (ws fc9d9d3 / app e08c22b — ยืนยันจาก gitops ว่าเป็น develop ล่าสุด) แล้วยังเห็น 2 อาการ

| อาการ | root cause ที่เหลือ | แก้ | PR |
|---|---|---|---|
| รีโหลด → แมวเริ่มที่จุดวางแล้ว**วาร์ป**ไปจุดจริง | รอบ 32 แก้ฝั่ง ws (Redis + snapshot) แล้ว แต่ **client วาด pet จาก REST list ที่ anchor ก่อน** แล้วค่อยขยับตาม snapshot → เห็นวาร์ป | วาด pet (และ minimap dot / overlay) **เฉพาะตัวที่รู้ตำแหน่งจริงแล้ว** — กฎเดียวกับตัวละคร: ไม่วาดจนกว่า server จะบอกว่ายืนอยู่ไหน (snapshot มาหลัง welcome ไม่กี่เฟรม) | [app #274](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/274) |
| นั่งบ้างยืนบ้าง "โรคลมบ้าหมู" | rest pose = Sitting ทันทีที่หยุด + wander พัก 3–8 วิ → นั่ง-ลุก-เดิน 1 tile-นั่ง ทุกไม่กี่วิ | **หยุด = ยืน** (Walking frame 0 ค้าง หันทางที่หยุด) · **นิ่งครบ 8 วิค่อยนั่ง** (`PET_SIT_AFTER_MS`, hero ตั้ง timer สลับให้เพราะไม่มี event) · ws พักนานขึ้น **4–20 วิ** ไม่งั้นตัวที่อยู่คนเดียวจะไม่มีวันได้นั่ง | app #274 · [ws #39](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/39) |

ตารางท่าตอนนี้: เดิน = Walking เล่น · หยุด <8 วิ = Walking เฟรม 0 นิ่ง · นิ่ง ≥8 วิ = Sitting เล่น · egg = Wobbling · sad = Sad · ลูบ = Happy

- **verify:** vitest **1662** ✅ · ws go test ✅ · merge develop · **ยังไม่ได้เห็นในเบราว์เซอร์** — ลอง: รีโหลด → แมวโผล่ที่จุดจริงเลย ไม่มีวาร์ป · หยุดเดิน = ยืนนิ่ง ~8 วิแล้วค่อยนั่ง

---

## 2026-09-05 (รอบ 32) — "รีโหลดแล้ว pet กลับที่เดิม" + ทุกคนต้องเห็นเหมือนกัน

| อาการ | root cause | แก้ | PR |
|---|---|---|---|
| รีโหลดหน้าแล้ว pet กลับไปจุดที่วาง | (1) ws **ลบ room ทิ้งทันทีที่คนสุดท้ายออก** และ pet AI อยู่ใน room → คนเดียวรีโหลด = state หาย seed ใหม่ที่ anchor · (2) client ที่เพิ่ง join วาด pet ที่ anchor จนกว่า AI จะ broadcast ครั้งถัดไป (ช้าสุด 2 วิ ถ้า pet พัก) → เห็นกระโดดกลับบ้านแล้วกลับมา | (1) เก็บ tile+facing ลง Redis `vo:pets:pos:<ws>` (TTL 10 นาที — store ที่ card ขอไว้) ทุก tick ที่เปลี่ยน · seed ใหม่ overlay ตำแหน่งที่เก็บไว้ (ยอมรับเฉพาะ tile ที่ยังยืนได้ — admin อาจย้าย pet/แก้ zone) · (2) หลัง `welcome` ส่ง `pet_state` ของทุกตัวให้ client ที่ join ทันที (`step_ms:0` = snap) | [ws #37](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/37) |
| คนอื่นลูบแล้วเราไม่เห็นท่า Happy | มีแค่ client ของคนลูบที่สลับ sheet (จาก response `/play`) | `pet_xp_changed` มี `activity`+`user_id` อยู่แล้ว → activity = play และไม่ใช่เรา → เล่น Happy เท่ากัน (ผ่าน ref เพราะ ws handler ประกาศก่อน state) | [app #273](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/273) |
| test flaky บน ws | test "stranger ไม่ทำให้หัน" ปล่อยให้ wander วิ่ง (50%) → ก้าวเปลี่ยน facing | pin ห้อง = tile เดียว · แยก "ยังเดินเล่นเมื่อมีแต่ stranger" เป็นอีก test | [ws #38](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/38) |

- **สิ่งที่ทุกคนเห็นเหมือนกันตอนนี้:** ตำแหน่ง/ทิศ (ws authoritative + Redis + snapshot) · ท่าเดิน/นั่ง (จาก `moving` ของ ws) · Sad (derive จาก `last_activity_at` ที่ทุกคนได้เท่ากัน) · Happy ตอนถูกลูบ (broadcast) · egg/stage (จาก xp)
- **verify:** ws/app tests เขียว (ws test ที่ flaky แก้แล้ว รัน 3 รอบผ่าน) · merge develop · **ยังไม่ได้เห็นในเบราว์เซอร์** — ลอง: เดินให้ pet ขยับ → รีโหลด → ต้องอยู่ที่เดิม ไม่วาร์ป

---

## 2026-09-05 (รอบ 31) — user เคาะ A/B/C/E จาก audit + แก้ท่านั่ง/เดินสลับ + เดินช้าลง

| decision | ทำ | PR |
|---|---|---|
| **A** owner/admin = resident ทุกห้อง | `loadRoomResidents` = desk holders ∪ owner ∪ member role owner/admin → มีผลกับ quest / ลูบ / reminder / `is_resident` ทุกที่ | [api #85](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/85) |
| **B** เตือนใน editor | `RoomPet.desk_resident_count` (นับเฉพาะ desk ไม่นับ staff) → ตอนวาง toast เตือน + marker menu มีโน้ตส้ม "ห้องนี้ยังไม่มีใครมี private zone" | api #85 · [app #272](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/272) |
| **C** pet สนใจเฉพาะ resident | `resident_user_ids` ใน seed + `pet_spawned` → ws attention กรอง resident · คนนอกยืนข้าง ๆ = ไม่หัน ไม่หยุด · `zone_claim_changed` → refresh เฉพาะ resident list (ไม่ re-seed ทั้งก้อน ไม่งั้น pet วาร์ปกลับจุดวาง) | api #85 · [ws #36](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/36) |
| **E** icon บน nameplate ตาม stage | `ScenePet.iconSheet` = still sheet ของ stage → PetLayer ตัดเฟรมแรก · thumbnail เป็น fallback | app #272 |

### "ท่าทางนั่งวน เดินสลับไปๆ" — 3 สาเหตุซ้อน

| ที่ | สาเหตุ | แก้ |
|---|---|---|
| ws | client รู้ว่าเดินจบก็ต่อเมื่อ idle heartbeat มาถึง (ช้าสุด 2 วิ) → client ต้องเดา | tick หลังก้าวสุดท้าย "ถึง" broadcast `moving:false` ทันที 1 ครั้ง (`arriveAt`) — ws #36 |
| client | เดาว่าหยุดหลัง `step_ms + 150ms` แต่ step มาถึงห่างกัน ~step_ms ผ่าน flush 250ms → แพ้ race → หล่นเป็น Sitting ระหว่างก้าว | grace = 1 step เต็ม (900ms) เป็น backstop อย่างเดียว — app #272 |
| client | ทุกครั้งที่สลับ sheet (Walking↔Sitting) sprite **หาย 1–2 เฟรม** ระหว่างตัดเฟรมใหม่ | โชว์เฟรมเดิมค้างไว้จนเฟรมใหม่พร้อม — app #272 |

- **เดินช้าลง:** `petStepMs` 600 → **900 ms/tile** (ws #36) — client tween ตาม `step_ms` อัตโนมัติ
- **verify:** api/ws `go test` ✅ · app vitest **1658** ✅ · merge develop ครบ 3 repo · **ยังไม่ได้เห็นในเบราว์เซอร์**

---

## 2026-09-05 (รอบ 30) — audit ทั้งฟีเจอร์ตามที่ user สั่ง: "หาช่องโหว่ทั้งหมด ตรงไหนผิด ตรงไหนควรเพิ่ม ปุ่มตายตรงไหน"

### บั๊กที่เจอและแก้แล้ว (merge develop ครบ)

| # | ช่องโหว่ | ทำไมถึงเกิด | แก้ | PR |
|---|---|---|---|---|
| 1 | **ลูบแล้ว pet ที่ Sad ไม่ฟื้น** ถ้า `xp_play_with_pet` ปิด (v12 ปิดอยู่!) หรือโควตาวันหมด | `Award` return ก่อน UPDATE ทันทีที่ reason = disabled / daily-limit → `last_activity_at` ไม่ถูก reset → SC-PET-08 recovery ไม่เกิดเลยบน dev ตอนนี้ | touch-only path: UPDATE `last_activity_at` + commit + publish `pet_xp_changed` (xp_awarded 0) โดยไม่เขียน ledger | [api #84](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/84) |
| 2 | **reminder 09:00 ส่งหาทุก member** รวมคนที่ไม่มี private zone ในห้อง → ถูกเตือนทุกวันเรื่อง pet ที่ตัวเองแตะไม่ได้ | เขียนก่อนกฎ resident | กรอง recipient ด้วย `loadRoomResidents` | api #84 |
| 3 | **กด notification ของ pet แล้วไม่ไปไหน** (แค่ mark read) — card SC-PET-07 บอกต้อง navigate ไปห้อง | `tb_notification` ไม่มีข้อมูล pet | migration 93 `room_pet_id` (+ embedded DDL, รันบน dev แล้ว) · client: กด → เปิด panel + เดินไปหา ถ้าอยู่ชั้นอื่น → `/loading?zone_id=` ชั้นนั้น · pet ถูกลบแล้ว → toast | api #84 · [app #271](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/271) |
| 4 | **Go to "Join a meeting" ตาย** ถ้ากลาง meeting room เป็นโต๊ะ | เล็ง tile กลาง zone · `walkToTile` คืน false เงียบ ๆ เมื่อ tile ถูกบล็อก | `nearestWalkableZoneTile` เล็ง tile ที่เดินได้ใกล้กลางสุด · ไม่มีเลย → toast | app #271 |
| 5 | **residency ค้าง** หลัง claim/ปลด private zone (list pets stale 60 วิ) | ไม่ invalidate | invalidate `workspace-pets` ตอน `zone_claim_changed` | app #271 |

### ตรวจแล้วไม่พบปัญหา

ปุ่ม/ทางออกทุกจุดที่ไล่ดู: Pet panel (X · Go to ทุกแถว · Complete เป็น chip ไม่ใช่ปุ่ม) · 🤚 + `Press [P]` (resident เท่านั้น) · evolution modal (Confirm · Share) · Share modal (X · 3 tab · grid · Clear all · Send · empty state) · pet card ในแชท (realtime ส่ง `content_type` ครบ — `ChatMessageWire = Message`) · notification cards · Setting → Notifications `pet_activity` · Map Editor marker menu (rename / remove) · minimap dot (ไม่มี click ตาม Figma) · ws: attention/idle-out/zone fail-closed · quota room-wide + ledger actor · `xp_*` hooks 5 ตัวที่เปิด

### ที่ควรเพิ่ม / ต้องเคาะ (ยังไม่ทำ)

| # | เรื่อง | ทำไมสำคัญ | ทางเลือก |
|---|---|---|---|
| A | **owner ของ workspace ที่ไม่มี private zone** — วาง pet ได้แต่ทำอะไรกับมันไม่ได้ (ไม่ใช่ resident) | owner คือคนที่เทสก่อนใคร | (ก) owner/admin เป็น resident ทุกห้องโดยอัตโนมัติ (ข) ต้อง claim private zone เหมือนคนอื่น |
| B | **วาง pet ในห้องที่ไม่มีใครมี private zone** → ไม่มีใครลูบ/ทำ quest ได้เลย และ Sad แล้วไม่มีทางฟื้น | editor ไม่เตือน | เตือนใน marker menu / ตอนวาง ว่า "ห้องนี้ยังไม่มี resident" (editor ต้องรู้ claims) |
| C | **คนนอกห้องยืนข้าง pet ได้ไม่จำกัด** → pet หยุดนิ่งหันหาเขาตลอด (attention ไม่รู้ resident) | pet ของห้อง "ถูกกักตัว" โดยคนที่ทำอะไรมันไม่ได้ | ส่ง `resident_user_ids` เข้า `RoomPetAIView` ให้ ws สนใจเฉพาะ resident |
| D | **ลูบแล้วไม่ได้ XP** (`xp_play_with_pet` ปิด) — ตอนนี้ลูบ = แค่ฟื้น mood | card ให้ +1 XP max 5/วัน | เปิดกลับ (จะโชว์เป็น quest แถว 6) หรือ flag "จ่าย XP แต่ไม่โชว์ quest" |
| E | **icon บน nameplate ยังเป็น thumbnail ตัวโต** (spoiler เหมือน panel เดิม) | ขัดกับ "ลุ้น" (D11) | ให้ตาม stage เหมือน panel |
| F | **Hover ปุ่มลูบสำหรับ non-resident**: hover pet ของห้องอื่นได้ขอบเขียว (คลิกได้ดูข้อมูล) — ตั้งใจ แต่ควรยืนยัน | consistency กับ "ไม่มีปุ่มตาย" | ok หรือ เปลี่ยนเป็นขอบขาว |
| G | pet บนแมพยัง**ไม่มี "notice animation"** / ความเร็วเดินต่าง stage / นั่ง object (`pet_sittable`) | card เขียนไว้ ไม่มี slot/asset | ดู audit ข้อ 2–5 |

### verify

api `go test ./...` ✅ · app vitest **1656 ผ่าน** (ใหม่ 4) · migration 93 รันบน dev แล้ว · **ยังไม่ได้เห็นในเบราว์เซอร์** · live check ที่ควรทำหลัง deploy: ตั้ง `last_activity_at` ของ Mochi Live ถอย 4 วัน → ลูบ → mood กลับ happy ทั้งที่ `xp_awarded: 0`

---

## 2026-09-05 (รอบ 29) — user เทสรอบ 3: pet ต้องหยุดหันหาคนแรก · UI บอกว่าลูบได้ · เดิน = ท่าเดินเสมอ · capsule เชื่อมคน-สัตว์

| user บอก | root cause | แก้ | PR |
|---|---|---|---|
| "เดินเข้าไปใกล้ สัตว์เลี้ยงอยู่ไม่นิ่งเลย ต้องหยุดแล้วหันมา ถ้าหลายคนหันหาคนแรกเสมอ คนแรกไปค่อยไปคนถัดไป" | ws #32 ทำให้ "notice เป็นแค่ moment" แล้ว fall through ไป wander ต่อ → pet เดินหนีขณะยืนข้าง ๆ · เลือกคนใกล้สุด (random ถ้าเท่ากัน) ไม่ใช่คนแรก | `attention []userID` เรียงตามลำดับมาถึง · มีคนใน 3 tile = **หยุดนิ่ง** หันหา `attention[0]` · คนแรกออก → คนถัดไป · ก้าวเข้าหา 1 tile หลังยืนนิ่ง 3 วิ ยังอยู่ · ไม่มีใคร → wander ต่อ · ลบ `nearestPlayer` + test random tie | [ws #35](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/35) |
| "ตอนจะลูบหัว ไม่มี UI ขึ้นแจ้งเลยว่าลูบหัวได้" | ปุ่ม walk-up (#265) เป็นไอคอน 🤚 เปล่า ๆ + pet เดินหนีทำให้ปุ่มกระโดด | `Press [P] pet` โชว์คู่กับปุ่ม walk-up (ไม่ต้อง hover) + pet หยุดนิ่ง (ws #35) | [app #269](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/269) |
| "ถ้ามันเดินต้องเล่นท่าเดิน ต่อให้ลูบแล้ว happy ท่าอื่นเล่นตอนนิ่งเท่านั้น" | ลำดับเดิม: override(Happy) > sad > moving | **moving → Walking ชนะทุกท่า** · Happy/Sad/Sitting เฉพาะตอนนิ่ง (♥/+XP tooltip ยังเล่น) | app #269 |
| "ทำ UI คล้ายตอนเชื่อม pop chat space แต่เชื่อมกับสัตว์ เขียวของเรา ขาวคนอื่น เห็นแต่คนที่มี private zone ในห้อง" | ไม่มี | api [#83](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/83): `resident_user_ids` ต่อ pet · app: `scene.setPetLinks` + `_drawPetLinks` ใช้ `_drawChatCircleShape` เดิม (capsule เดียวกับ chat space) จาก tile ของ pet (`PetLayer.petGround`) ไปยัง resident ที่อยู่ในระยะ 2 tile · เขียว = ตัวเรา · ขาว = room-mate · hero ส่งเฉพาะ pet ที่เราเป็น resident → คนนอกห้องไม่เห็นเส้นเลย | [app #270](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/270) |

- **verify:** ws `go test` ✅ (ใหม่ 2: ยืนนิ่งขณะมีคนข้าง ๆ 200 รอบ · หันหาคนแรกแล้วสลับเมื่อคนแรกออก) · api ✅ · app vitest **1652** ✅ · merge develop ครบ 3 repo · **ยังไม่ได้เห็นในเบราว์เซอร์**
- **สิ่งที่ควรดูบน dev:** เดินเข้าหาเจ้าปรื๊ด → มันหยุด หันมา → ปุ่ม 🤚 + `Press [P] pet` + capsule เขียวจากเท้าเราถึงตัวมัน → กด P → ♥ (ไม่ได้ XP เพราะ v12) · ให้เพื่อนที่มี private zone ในห้อง `test` เดินเข้าไป → เห็น capsule ขาวของเขา

---

## 2026-09-05 (รอบ 28) — SC-PET-08: ปุ่มลูบหัวขึ้นเองเมื่อ room-mate เดินเข้าใกล้ (user สั่ง)

- **user ถาม:** SC-PET-08 ทำงานยังไง / ลูบหัวต้องไปลูบยังไง มีไหม → ของเดิม: ปุ่ม 🤚 ขึ้น**เฉพาะตอนคลิก pet** (และอยู่ในระยะ 2 tile) · hover ในระยะได้แค่ `Press [P] pet` · pet หันหน้าหาคนใน 3 tile อยู่แล้ว (ws AI)
- **user สั่ง:** คนที่มี private zone ในห้องเดินเข้าใกล้ → pet หันมา → มีปุ่มขึ้นบนหัวให้ลูบ
- **ทำ:**
  - api [#81](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/81): `GET /api/user/workspaces/:id/pets` ใส่ `is_resident` ต่อ pet (กฎเดียวกับ quest #80 — `loadRoomResidents` เป็น helper ใช้ร่วม 2 service)
  - app [#265](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/265): `nearestStrokeablePet` เลือก pet ที่ resident เดินเข้าใกล้ (≤2 tile ที่ **ตำแหน่งจริง**) → ปุ่ม 🤚 ขึ้นเอง ไม่ต้องคลิก/hover · เดินออก = หาย · non-resident ยังใช้ทางเดิม (คลิกถึงขึ้น)
  - **บั๊กที่เจอระหว่างทำ:** ระยะและตำแหน่ง overlay ใช้ `tile_x/tile_y` ที่วางไว้ ไม่ใช่ตำแหน่งจริงจาก `pet_state` → ตั้งแต่ #254 ที่ pet เดินได้ ปุ่มจึงลอยอยู่ที่จุดวางและวัดระยะผิดจุด — แก้ให้ตาม `petLivePositions` ทั้งคู่
- **SC-PET-08 ตอนนี้ (สรุปที่อธิบาย user):** mood derive จาก `last_activity_at` ตอนอ่าน (happy ≤12h · neutral ≤72h · sad >72h · ค่าปรับได้ใน XP config) ไม่มี cron/column · sad = เล่น sheet Sad + ws หยุด wander + ไม่ react คน + XP ×50% · **การลูบ 1 ครั้งคือ recovery** (reset `last_activity_at` → happy ทันที + เล่น Happy) — เฉพาะ stroke ที่ reset mood (login/office/chat ไม่ reset ไม่งั้นทีมที่ active จะไม่มีวัน sad) · ลูบไม่ได้ XP จนกว่าจะเปิด `xp_play_with_pet`
- **verify:** api `go test ./...` ✅ · app vitest **1651 ผ่าน** (ใหม่ 5) · merge develop ทั้งคู่ → dev · ยังไม่ได้เห็นในเบราว์เซอร์
- **เพิ่ม (user สั่งต่อ #3): รูปใน panel ต้องเป็น stage จริง "คนจะได้ลุ้น"** → เดิมใช้ `thumbnail_url` ของ pet type = เฟรมแรกของ Evolved → ไข่เปิด panel เห็นตัวโตเต็มวัย · แก้เป็น still ของ stage ปัจจุบัน (`pickIdleAnimation` → Wobbling/Walking frame 0) ตัดด้วย `usePetAnimationFrame` ตัวเดียวกับ modal/share card · ระหว่างโหลดโชว์ PawPrint ไม่ใช่ thumbnail (จะแวบ spoiler) · **ยังไม่แตะ** icon บน nameplate (ยังเป็น thumbnail) และ marker บนแมพ (กฎ user รอบ 16) — ถามต่อว่าจะให้ตาม stage ด้วยไหม (app PR ถัดจาก #267)
- **เพิ่ม (user สั่งต่อ #2): "ลูบหัวให้เฉพาะ resident ด้วย"** → api [#82](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/82): `POST …/play` เช็ค `roomResidents` → คนนอกห้องได้ **403 `NOT_ROOM_RESIDENT`** (แยกจาก FORBIDDEN/404) · app (PR ถัดจาก #266): pet ที่ `is_resident=false` ไม่มี 🤚 ตอนคลิก ไม่มี `Press [P]` ไม่ส่ง request · ผลพวง: recovery ของ SC-PET-08 (ลูบ = reset mood) ก็เป็นของ resident เท่านั้น · ตอนนี้ **ทุกอย่างที่ pet "ทำให้" (quest / ลูบ / ปุ่ม) เป็นของคนที่มี private zone ในห้องเดียวกันทั้งหมด** — คนอื่นดูข้อมูลได้อย่างเดียว
- **เพิ่ม (user สั่งต่อ):** "pet ของ zone ที่ไม่ใช่ของเรา กดแล้วต้องไม่มี quest ขึ้นมาบอกว่าให้ทำอะไร" → panel ของ pet ที่เราไม่ใช่ resident **ไม่มี section Daily quest เลย** (ไม่มี divider/หัวข้อ/แถว/ปุ่ม) เหลือ ชื่อ · XP · mood · stage — ใช้ `is_resident` จาก pet list ตั้งแต่เปิด panel จะได้ไม่แวบขึ้นมาก่อน status โหลด (app PR ถัดจาก #265) · แทนแบบเดิมใน #264 ที่โชว์ progress + โน้ต

---

## 2026-09-05 (รอบ 27) — user เทสต่อ: quest ต้องทำได้จริง / รีเซ็ตเที่ยงคืน / pet ห้ามออกนอกห้อง / hover ขอบเขียว + เคาะ quest เป็นของห้อง · อ่าน ClickUp ใหม่ทั้งชุด

### ที่เจอและแก้

| อาการ | root cause | แก้ | PR |
|---|---|---|---|
| quest โชว์ **0/1 ทุกแถว** ทั้งที่ ledger มี login ของ user แล้ว (20:01) | `Status` คืน quota **ตัวเดียว** (`xp_play_with_pet`) และนับต่อ user | คืน 1 แถวต่อ activity ที่ enabled ตาม `PetXPActivityOrder` นับทั้งห้อง | [api #80](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/80) |
| pet **เดินออกนอกห้อง** ไปหาคนในทางเดิน | ws `tileAllowed` **fail open** เมื่อไม่มี zone snapshot · ws `34ffa741` (ของ user) **ไม่มี key `vo:zones`** ใน Redis เพราะ zone ถูกเซฟก่อนมี cache (07-17) · path A* ไม่ถูกเช็คทุก tile | ws fail-**closed** + เช็คทุก tile ของ path · api backfill snapshot ตอน ws seed pets (`EnsureWorkspaceZonesPublished`) | [ws #34](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/34) · api #80 |
| hover pet ไม่มีขอบ | ไม่เคยทำ | `OutlineSlot` ต่อ pet ใน `PetLayer` สีเขียว 1px เหมือน avatar · scene เรียก `setHovered` | [app #264](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/264) |
| quest รีเซ็ตเที่ยงคืน | server `day_key` UTC+7 อยู่แล้ว · panel ที่เปิดค้างไม่ refetch | `usePetStatus` poll ทุก 1 นาทีขณะเปิด | app #264 |

### decision ที่ user เคาะ (บันทึกเต็มใน [clickup-audit-2026-09-05.md § decision](clickup-audit-2026-09-05.md))

- **D2 quest ทำได้เฉพาะคนที่มี private zone อยู่ในห้องของ pet** → `roomResidents` = claim ใน `tb_private_zone_claim` ที่ zone แชร์ tile กับห้อง (แชร์ 1 tile ก็นับ — สี่เหลี่ยมวาดมือเกยกำแพงได้) · `AwardWorkspaceActivity` ข้าม pet ที่ actor ไม่ใช่ resident · `Status.is_resident` → panel ซ่อน Go to + ขึ้นโน้ตให้ non-resident (ไม่มีปุ่มตาย)
- **D3 quest เป็นของห้อง ใครทำแล้วนับให้ทุกคน** → `usedToday` นับต่อ pet/วัน ไม่แยก user · ledger ยังบันทึก actor ทุก activity (office time เดิมเป็น NULL → contributors มองไม่เห็น)
- **ไม่แตะ stroke** — decision พูดถึง quest และ stroke ไม่ใช่ quest แล้ว (v12) → ลูบได้ทุก member แต่ไม่ได้ XP จนกว่าจะเปิด `xp_play_with_pet` กลับ (ถาม PM ข้อ 6 ใน audit)
- บน dev: user (Private 45 @55,36) และอีก 1 คน (Private 44) เป็น resident ของห้อง `test` ที่เจ้าปรื๊ดอยู่ → quest ของ user ควรขึ้น 1/1 หลัง deploy

### อ่าน ClickUp ใหม่ทั้งชุด

- description ทุกใบ **ไม่เปลี่ยน** จากที่ spec.md §1–§3 ลอกไว้ · เปลี่ยนแค่ status → in progress · ที่ "ไม่ตรง" คือ card vs ของจริง → ทำตารางเทียบทุก AC/BL 8 card + parent ที่ [clickup-audit-2026-09-05.md](clickup-audit-2026-09-05.md) พร้อม **8 ข้อที่ card สั่งแต่ยังไม่มีใครเคาะ** (bonus ทีม 5 คน · ความเร็วเดินต่าง stage · notice animation · bubble 3 วิ · pet_sittable · stroke XP · notification navigate · streak)

### verify

- api `go test ./...` ✅ (ใหม่: `TestResidentsOf` 5 เคส, `PetXPActivityOrder`, tracker บันทึก actor) · ws `go test ./...` ✅ (ใหม่ 3: ไม่มี geometry = ไม่เดิน · ห้อง 3×3 ไม่หลุด 400 รอบ · ไม่ตามคนออกนอกห้อง) · app vitest **1646 ผ่าน**
- merge เข้า develop ครบ 3 repo → dev deploy · **ยังไม่ได้เห็นหลังแก้ในเบราว์เซอร์** — ให้ user ดู: quest 1/1 · pet ไม่ออกนอกห้อง test · hover ขอบเขียว

---

## 2026-09-05 (รอบ 26) — user เทสบน dev เอง: background หาย · pet ไม่เล่นท่าเดิน · z-index · panel เลื่อนไม่ได้ / ปุ่ม Go to ตาย / รูป quest ผิด

> user เปิด VO บน dev เองแล้วส่ง screenshot 2 ใบ — นี่คือการเห็นด้วยตาครั้งแรกของฟีเจอร์นี้

### สิ่งที่เจอและแก้

| อาการ | root cause | แก้ | PR |
|---|---|---|---|
| **ฉากหลังแมพหายทั้งแมพ** (เห็นแต่สี canvas) | commit `3dd45b6` (2026-09-04, งาน preload textures — คนละ session กับ Room Pet) เปลี่ยน `mapBgUrl:` เป็น `...mapBackgroundUrls(mainMap)` แต่ helper return key `bgUrl/bgThumbUrl` ไม่ใช่ `mapBgUrl/mapBgThumbUrl` ที่ scene อ่าน · TypeScript ไม่จับเพราะ spread ไม่มี excess-property check | helper return key ตามชื่อ field ของ `MapConfig` (type เป็น `Pick<MapConfig,…>` ให้ rename ครั้งหน้าเป็น compile error) + test pin ชื่อ key | [app #261](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/261) |
| pet เดินแต่ใช้ท่า Idle | ws ส่ง `moving` มาแล้ว ทุก type มี slot Walking แต่ renderer ไม่เคยเลือก | `buildScenePets` เลือก Walking ตอน `moving` · client หยุดเองหลัง `step_ms + 150ms` (`PET_WALK_STOP_GRACE_MS`) เพราะ ws บอก "หยุด" ช้าสุด 2 วิ (idle heartbeat) | #261 |
| pet ทับ object ผิดจากตัวละคร | pet sort ที่ก้นสไปรต์ แต่ avatar sort ที่ `py + PLAYER_FOOT_OFFSET_Y` (−10) → pet อยู่ "ต่ำกว่า" ตัวละครบน tile เดียวกัน 10px | `petZIndex` ใช้ offset เดียวกัน · test ยืนยันว่าต่างจาก avatar บน tile เดียวกันแค่ tie-break | #261 |
| "เดินต้องเดิน 1 tile เหมือนตัวละคร" | **เป็นอยู่แล้ว** — ws ก้าวทีละ tile / 600ms และ client tween ทีละ `pet_state` | — | — |
| Pet panel ยาวเกินจอ เลื่อนไม่ได้ | ไม่มี max-height · Figma มี quest 5 แถว แต่ config เปิด 10 | panel `max-h-[calc(100vh-48px)]` + list `overflow-y-auto` | [app #262](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/262) |
| ปุ่ม **Go to ตายทุกปุ่ม** (แค่ปิด panel) | hero ผูก `onGoTo={() => setClickedPetId(null)}` | ตาราง `PET_QUEST_GO_TO_TARGET`: chat quest → เปิด chat · meeting quest → เดินไป meeting zone ที่ใกล้สุดบนชั้นนี้ (ไม่มี = toast) · play with pet → เดินไปหา pet · **login / office 10-30 นาที ไม่มีปุ่ม** (ทำอะไรไม่ได้นอกจากอยู่ที่นี่ — ปุ่มตายแย่กว่าไม่มี) | #262 |
| รูปบน quest tile ผิด | ใช้ lucide glyph ต่อ quest · Figma `4331:343228` ใช้ **XP medal เดียวกันทุกแถว** + เลข +N ข้างล่าง (asset เดียวกับที่ user ให้เปลี่ยนใน #258) | ใช้ `PET_XP_ICON_URL` ทุก tile | #262 |

### เพิ่ม: ท่าตามสถานการณ์จาก 17 slot ที่ Pet Management อัป ([app #263](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/263))

user ให้ย้อนอ่าน PetManagement/spec.md — slot vocabulary คือ `Wobbling / Walking / Sitting / Happy / Sad / Evolution` (17 slot, **ไม่มี Idle** — แถว Idle ใน DB มาจาก build 20 slot เดิม) แต่ renderer ใช้แค่ "idle" (Idle→Walking) ไม่เคยแสดง Sitting เลย · ตอนนี้:

| สถานการณ์ | sheet | fallback |
|---|---|---|
| egg | Wobbling | — |
| AI กำลังก้าว | Walking | rest |
| ยืนนิ่ง (AI พัก 3–8 วิ ระหว่าง wander) | **Sitting** | Idle → Walking |
| เหงา (sad) | Sad | rest |
| ถูกลูบ | Happy | rest |
| ภาพนิ่ง (modal / share card / editor marker) | Walking frame 0 (กฎ thumbnail ของ spec) | Idle → Sitting |

ลำดับ: stroke > sad > moving > resting · vitest **1642 ผ่าน** · ค้างฝั่ง PetManagement: ฟอร์ม upload ยังมี slot Idle (20 ≠ 17) — spec.md § ผลต่อโค้ด ระบุให้ถอดอยู่แล้ว

### เพิ่ม: config v11 → **v12** — ปิด activity ที่ไม่มีใน Figma ให้ Daily quest เหลือ 5 แถว (user สั่ง)

ทำผ่าน `PUT /api/admin/pet-xp-config` (admin-a) เหมือนรอบ 23 — ไม่แตะ SQL

| activity | v11 | v12 | เหตุผล |
|---|---|---|---|
| `xp_login_per_day` · `xp_office_10min` · `xp_team_meeting` · `xp_first_message_fo_day` · `xp_react_message_fo_day` | on | **on** | ตรงกับ 5 quest ใน Figma (Daily login / Stay 10 min / Join a meeting / Send message / React) |
| `xp_office_30min` · `xp_team_meeting_10min` · `xp_team_meeting_30min` · `xp_10_message_fo_day` | on | **off** | ไม่มีใน Figma |
| `xp_play_with_pet` | on | **off** | ไม่มีใน Figma — **ผลข้างเคียง: การลูบ (SC-PET-03) ไม่ได้ XP แล้ว** (animation + ♥ ยังเล่น, API ตอบ `awarded:false`) · ถ้าต้องการให้ลูบได้ XP ต้องเปิดกลับในหน้า XP Configuration |

- "Send message" ใน Figma (1/5) map เป็น `xp_first_message_fo_day` (ตีความว่า "ส่งข้อความ" ไม่ใช่ "ครบ 10 ข้อความ") — ถ้า PM ต้องการอีกตัวสลับได้ในหน้า config
- panel กรอง `enabled` อยู่แล้ว (`buildPetDailyQuests`) → เหลือ 5 แถวทันทีไม่ต้อง deploy · Max XP/Day ลดจาก 59 → 18

### หลักที่ user ย้ำ (บันทึกเป็น feedback)

> "ต้องไม่มีปุ่มที่มันตาย กดแล้วไปไหนต่อไม่ได้ แบบนี้ไม่เอา มันต้องทำงานได้จริงทุกอย่าง" — ปุ่มทุกปุ่มต้องพาไปทำสิ่งนั้นได้จริง ถ้าไม่มีทางไปให้ซ่อนปุ่ม

### verify

- `tsc` / `eslint` สะอาด · `vitest run` **1630 ผ่าน** ทั้งสอง PR (ใหม่ 12) · merge เข้า develop แล้ว → dev deploy อัตโนมัติ
- **ยังไม่ได้เห็นผลหลังแก้ในเบราว์เซอร์** — ต้องให้ user reload dev ดู: พื้นหลัง School 3 กลับมา · pet เล่น Walking ตอนเดิน · panel เลื่อนได้ · Go to พาไปจริง

### ต่อจากนี้

- เทส UI รอบถัดไปตามที่ user เห็นจริง · `pet_sittable` ยังค้าง (รอบ 25)

---

## 2026-09-05 (รอบ 25) — ไล่ปิด 7 งานที่เหลือ: ปิด 5 · เจอบั๊ก office clock 1 · ค้าง 2

> user สั่ง "ยังเหลืออีก 7 อย่าง ช่วยทำ แล้วส่งรายงานผล" — ลำดับตามตาราง [spec.md § งานที่เหลือ](spec.md) ของรอบก่อน

### ผลรวม

| # | งาน | ผล | PR |
|---|---|---|---|
| 1 | เทส UI ในเบราว์เซอร์ | ⛔ **ติดเหมือนเดิม** (login) | — |
| 2 | Share your friends | ✅ ทำครบ api + app | [api #79](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/79) · [app #260](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/260) |
| 3 | pet facing | ✅ ทำแล้ว — spec มีอยู่แล้วในโค้ดเรา | [app #259](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/259) |
| 4 | `pet_sittable` | ⬜ **ไม่ได้ทำ** — มีแผนด้านล่าง | — |
| 5 | achievement log | ✅ migration 91 + insert ตอนข้าม stage | [api #77](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/77) |
| 6 | cron 09:00 ICT | ✅ **ยิงจริงแล้วเช้านี้** | — (โค้ดเดิม #71) |
| 7 | `xp_office_10/30min` | ✅ live-test เจอบั๊ก → แก้ → **re-verify ผ่าน** (10min จ่ายที่ +10:06 · 30min ไม่จ่าย) | [api #78](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/78) |

### #3 pet facing — ไม่ต้องถาม design เพราะ spec อยู่ในโค้ดเราเอง

- รอบ 18 ตัดสินใจ "ไม่ทำ facing เพราะไม่มี spec ว่า sprite row ไหนคือทิศไหน" — **ผิด**: หน้า admin Pet Management preview (`pet-preview-modal.tsx`) ระบุ row ไว้แล้ว **Down / Left / Right / Up = 0 / 1 / 2 / 3** และทุก sheet ที่ artist เคยตรวจใน preview ก็ยืนยันลำดับนี้ไปแล้ว
- ย้ายตารางไป `lib/pet-sprite-direction.ts` แล้วให้ **ทั้ง preview และ `PetLayer` อ่านจากที่เดียว** → สิ่งที่ admin เห็นใน preview = สิ่งที่ member เห็นบนแมพ โดยโครงสร้าง drift กันไม่ได้
- `PetLayer` ตัด **ทุก row** (`frames[row][frame]`) แล้วเลือก row ตาม `facing` ที่ ws ส่งมากับ `pet_state` ตั้งแต่ #254 · sheet ที่ row น้อยกว่าที่ต้องใช้ (egg กลางมี 1 row) → fallback เป็น down ไม่ตัดเลย row ที่ไม่มี
- test 26 ตัว (`pet-sprite-direction.test.ts` + PetLayer suite) รวมเคส 1-row / 3-row / facing ไม่รู้จัก และเคส animate ภายใน row เดียวโดย row ไม่เปลี่ยนกลางคัน

### #5 achievement log — `tb_room_pet_achievement` (migration 91)

- card SC-PET-04/05 บอก "🐣 First Hatch!" ให้คนที่ทำ egg→baby · "🏆 Fully Evolved!" ให้ทั้งห้อง · **"เก็บ logs ไว้ ยังไม่แสดง"** → นี่คือ log ยังไม่มี endpoint อ่าน
- `petAchievementFor(prev, next)` pure function ตัดสินว่าได้ badge ไหนและเป็นของคน (`first_hatch`, user_id = คนที่ award) หรือของห้อง (`fully_evolved`, user_id NULL) · insert **หลัง commit แบบ best-effort** — pet ต้องโตได้แม้ log เขียนไม่ได้
- **unique `(room_pet_id, achievement)` + `ON CONFLICT DO NOTHING`** = admin ขยับ threshold จน demote แล้วกลับมา hatch ใหม่ ไม่ได้ First Hatch ซ้ำ · demote เองไม่ได้อะไร · table-driven test 8 เคส
- **mirror ใน embedded DDL แล้ว** (`postgres.go`) ตามบทเรียน #72 — migration ใน `migrations/*.sql` ไม่รันตอน deploy
- ยังไม่มีแถวจริงบน dev (เจ้าปรื๊ดเป็น baby อยู่ · แถวแรกจะเกิดตอนไข่ตัวใหม่ hatch หรือตัวไหนถึง evolved)

### #6 cron 09:00 ICT — ยิงจริงแล้ว ไม่ต้องเรียกตรง

- `tb_notification` type `pet_reminder` มี **8 แถว `created_at = 2026-09-05 09:00:00 ICT` เป๊ะ** — สร้างโดย job ที่ deploy อยู่ (`runPetReminderLoop` ใน main.go) ไม่ใช่ probe
- probe เรียก `SendPetDailyReminders` ซ้ำหลังจากนั้นได้ `sent: 0` → dedupe รายวันทำงาน · member-a ได้ reminder (ไม่มี XP event ก่อน 09:00) ตรงตามเงื่อนไข
- โฟลเดอร์ probe (`cmd/petremind-probe`) ลบแล้ว ไม่มีอะไรค้างใน repo

### #7 office time — live-test เจอบั๊ก "นาฬิกาค้าง"

- heartbeat member-a เข้า ws `256893ae` ทุก 30 วิ: 19:17:07 ได้ `xp_login_per_day` ถูกต้อง แต่ **19:17:08 ได้ `xp_office_10min` และ `_30min` พร้อมกัน** ทั้งที่ session เพิ่งเริ่ม 1 วินาที
- **root cause:** `PetActivityTracker` เริ่มนาฬิกาที่ heartbeat แรก และล้างเฉพาะตอนได้ leave · tab ที่หายไปเฉย ๆ (ปิด/crash/พับจอ) ไม่ส่ง leave → start time ค้างอยู่ในหน่วยความจำ → พอกลับมาอีกกี่ชั่วโมงก็ "อยู่ office มา 14 ชม." ทันที (member-a เคย heartbeat ตอนเทสช่วงบ่ายแล้วไม่เคย leave)
- **แก้ ([api #78](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/78)):** tracker จำ `lastBeat` ต่อ session · ถ้าห่างเกิน **`presenceTTL` (65 วิ)** ให้ลืมทั้งนาฬิกา office และ meeting ก่อนอ่าน — ใช้ threshold เดียวกับ presence ตั้งใจ: วินาทีที่ roster เห็นว่า offline นาฬิกาก็หยุดด้วย · heartbeat ปกติ 30 วิ อยู่ในกรอบสบาย มี test ยืนยันว่า 10 นาทีของ heartbeat ต่อเนื่องยังจ่าย
- **Before/After** (ตาม rule 18):

  | Metric | Before (#75) | After (#78) |
  |---|---|---|
  | เวลาจาก heartbeat แรก → `xp_office_10min` | **1 วินาที** (ledger 19:17:07 → 19:17:08) | **10 นาที 6 วินาที** (heartbeat แรก 19:51:02 → ledger 20:01:08) |
  | `xp_office_30min` ใน session 11 นาที | **จ่าย** (19:17:08) | **ไม่จ่าย** (session 11 นาที ไม่มีแถว `_30min`) ✅ |

  วัดจาก `tb_room_pet_xp_event` ของ pet `1922ecc1` (Mochi Live) · before = loop 19:17–19:28 · after = loop 19:51–20:02 บน api `dev-76a3561` · 2 แถวที่บั๊กจ่ายถูกลบและหัก XP คืนก่อน re-run (test data ของผมเอง)

### #2 Share your friends — ทำใหม่ทั้งชุด (api + app)

- **api ([#79](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/79)):** migration 92 ขยาย `tb_message.content_type` CHECK ให้มี `'pet_card'` (รันบน dev แล้ว · `tb_message` ไม่อยู่ใน embedded DDL จึงไม่มีอะไรมาทับตอน boot) · `SendMessageRequest.content_type` รับค่าเดียว = `"pet_card"` · `validatePetCard` ตรวจ JSON strict ก่อน insert (unknown field ไม่รับ, stage ต้องอยู่ใน `model.PetStages`, sprite url ต้อง https, frame geometry อยู่ในกรอบ) → 400 `ErrInvalidPetCard` · **ตั้งใจไม่เช็คว่า pet ยังอยู่** — การ์ดต้องอยู่ได้แม้ pet ถูกลบ · test 14 เคส
- **app ([#260](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/260)):**
  - `PetShareModal` ตาม Figma `4354:866488` (ดึง spec ผ่าน Figma MCP): search · tab DM/Group/Channel · grid 4 คอลัมน์ · Clear all/Send พร้อม disabled state สี Figma · DM = สมาชิก confirm จาก cache `useWorkspaceMembers` เดียวกับ picker อื่น ลบตัวเอง · Group/Channel = conversation ที่อยู่แล้ว · การเลือกคงอยู่ข้าม tab/search
  - Send = ส่ง `pet_card` เดิมเข้าทุกปลายทาง (DM สร้างระหว่างทางถ้ายังไม่มี) → toast "Share successfully." ตาม §5.5 แล้วปิด · fail หมด = error toast ค้างไว้ · fail บางส่วน = warning
  - การ์ด = JSON (`lib/pet-share-card.ts`): pet_id / pet_name / stage + **geometry ของ sheet เท่านั้น** → ฝั่งอ่านตัด frame ด้วย `petAnimationFrameDataUrl` ตัวเดียวกับ pet บนแมพ (ขยาย param type เป็น 3 field ที่มันอ่านจริง) · `PetCardMessage` ใน stream · sidebar preview จำการ์ดจาก shape ("Shared a pet card") เพราะ `MessagePreview` ไม่มี `content_type`
  - ปุ่ม "Share your friends" ใน evolution modal (ghost, flex-1 คู่กับ Confirm ตาม §5.3) โผล่เฉพาะเมื่อมี workspace ให้แชร์
- **ตัดสินใจเองที่ spec เว้นไว้:** §5.4 บอกว่าแชร์แล้ว "เปิด Direct message full view" — เลือกได้หลายคน จึงไม่มี chat เดียวให้กระโดดไป → จบที่ toast ไม่พาออกจาก VO · **ไม่มี Figma ของการ์ดในแชท** (ux-ui เอ่ยชื่ออย่างเดียว) ใช้ palette ของ modal
- **verify:** `tsc` สะอาด · `eslint` สะอาด · `vitest run` **1624 ผ่าน** (ใหม่ 25 ตัว) · `go test ./...` ผ่าน · **ยังไม่ได้เห็นในเบราว์เซอร์** (login) · ยังไม่ได้ยิง end-to-end จริงว่า card เด้งเข้าแชทของอีกฝั่ง

### #4 `pet_sittable` — ไม่ได้ทำ · แผนที่สำรวจไว้แล้ว

กระทบ 4 repo และมี design ที่ต้องเคาะก่อน จึงไม่เริ่มในรอบนี้:

| ชั้น | ต้องทำ | ที่สำรวจไว้ |
|---|---|---|
| DB / api | `tb_object.pet_sittable BOOLEAN NOT NULL DEFAULT false` (migration 93 + embedded DDL) · admin PUT/POST object รับ field · publish "sittable tiles ต่อ workspace" ลง Redis แบบเดียวกับ obstacle grid | obstacle publish อยู่ที่ `workspace_service.go:1253/1374` + `obstacle_grid_builder.go:222` ผ่าน `cache.ObstacleCache.SetWorkspaceObstacles` · `tb_map_object` มี `tile_x/tile_y/grid_width/grid_height/facing` ครบ |
| admin UI | toggle "Pet can sit here" ใน `object-add-form.tsx` / `object-detail-content.tsx` | icon map อยู่ใน `object-add-form-constants.ts` |
| ws | pet AI อ่าน sittable tiles ของห้อง · state ใหม่ `sitting` (เดินไปถึง → นั่ง N วิ → ลุก) · ส่ง `pet_state.sitting` | `internal/hub/pets.go` ตอนนี้ไม่รู้จัก map object เลย รู้แค่ obstacle grid |
| client | `PetLayer` เล่น slot `Sitting` เมื่อ `sitting=true` | slot `Sitting` มีใน 17 slot ของ PetManagement อยู่แล้ว |

**ต้องเคาะก่อน:** (1) object กว้างหลาย tile นั่ง tile ไหน / หันทางไหน (2) pet นั่งบน object ที่ avatar นั่งอยู่ได้ไหม (ที่นั่งเดียวกับคน?)

### ไม่ได้ทำ #1 — เทส UI

เหตุผลเดิมทั้ง 3 ข้อ (พิมพ์รหัสผ่านไม่ได้ / cookie httpOnly / Browser pane คนละ browser) · ทางออกที่เหลือคือ user login ใน Browser pane ให้ แล้วสั่ง "go" เหมือนรอบ 20

---

## 2026-09-05 (รอบ 24) — เปลี่ยน XP icon จาก emoji เป็น asset จริงของ Figma

- **ทำอะไร:** user ส่งไฟล์ `storage/xp-icon.png` (50×50 RGBA, 3233 B) มาให้ใช้แทน 🏅 ที่เป็น placeholder
  - อัปขึ้น R2 ที่ **`static/pet/shared/xp-icon.png`** — วางไว้ข้าง `egg-evolution.gif` เพราะเป็น asset ชุดเดียวกัน คือ **เหมือนกันทุก pet type** (ต่างจาก sprite ของ pet ที่ admin อัปแยกต่อ type) · ตั้ง `Cache-Control: public, max-age=31536000, immutable`
  - `lib/pet-interaction.ts`: `PET_XP_MEDAL_EMOJI` (🏅) → `PET_XP_ICON_URL` · เป็น const ไม่ใช่ config เพราะไม่มีอะไรให้ admin ปรับ
  - `pet-tooltip.tsx` variant `xp`: `<span>` ที่มี emoji → `<Image width={16} height={16} unoptimized>` ตาม ux-ui §4.3 ที่ระบุว่าเป็น PNG 16px
- **ไม่แตะ ♥** — Figma export เป็น PNG เหมือนกัน แต่ VO ใช้ธรรมเนียม emoji-as-text (`MEETING_EMOJIS`) และ user ขอมาแค่ XP icon · เขียน comment ในไฟล์ไว้ว่าอันไหนเป็นอะไร จะได้ไม่มีใครมา "แก้" ให้เหมือนกันทีหลัง
- **PR:** [app #258](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/258)
- **verify:**
  - upload ยืนยันแล้ว: `curl` ได้ `200 image/png` · sha256 ตรงกับไฟล์ต้นทางเป๊ะ (`ea3ff6c8…`)
  - `next.config` มี `remotePatterns: hostname "**"` อยู่แล้ว → `<Image>` โหลดจาก R2 ได้ ไม่ต้องแก้ config
  - `tsc` / `eslint` สะอาด · `vitest run` **1588 ผ่าน**
  - test เดิมที่ assert ว่า medal **ไม่ใช่** asset path ถูกแทน (มันตรงข้ามกับความจริงใหม่แล้ว) ด้วย 3 ข้อ: ♥ ยังเป็น unicode · XP icon ต้องเป็น absolute `https://…png` (ถ้าเป็น `/path` เปล่า ๆ จะ 404 เพราะ VO คนละ origin กับ asset) · element ที่ render เป็น `<img>` ชี้ไป `xp-icon.png` ขนาด 16px `alt=""`
  - **ยังไม่ได้เห็นในเบราว์เซอร์** — tooltip นี้โผล่ตอน stroke เท่านั้น และงานเทส UI ยังติด login อยู่

## 2026-09-04 (รอบ 23) — เปิด activity ครบ 10 ตัว + แก้ค่า office ที่กรอกสลับช่อง (config v9 → v11)

> งาน config ล้วน ไม่มีการแก้โค้ด · ทำผ่าน **admin API** (`PUT /api/admin/pet-xp-config`) ทั้งหมด ไม่ใช่ SQL ตรง เพื่อให้ version history ถูกต้องและ restore ได้

### สิ่งที่ทำ

| version | เปลี่ยนอะไร |
|---|---|
| v9 (ของเดิม) | `xp_login_per_day` และ `xp_office_10min` = `enabled:false` · `xp_office_10min` = **30 XP ทั้งที่ cap คือ 10** |
| **v10** | เปิด 2 ตัวนั้น + จำใจ clamp `xp_office_10min` 30 → 10 (ไม่งั้น API reject) |
| **v11 (ปัจจุบัน)** | ย้ายเลขกลับช่องที่ควรอยู่: `xp_office_10min` = **6** · `xp_office_30min` = **30** |

### สิ่งที่เจอ — config ใน DB ไม่ผ่าน validation ของตัวเอง

`xp_office_10min` เก็บ `xp: 30` แต่ `tb_pet_xp_activity_definition.max_xp` ของมันคือ **10** → ถ้าเอา config เดิมยิงกลับผ่าน API จะโดน reject ที่ `must_be_between_1_and_10`

แปลว่าแถวนั้น **ถูกเขียนเข้ามาโดยไม่ผ่าน API** (SQL ตรง หรือ constraint ใน migration 87 ถูกเพิ่มทีหลัง) — เป็นข้อสังเกตเรื่อง data integrity ที่ควรรู้: **หน้า XP Configuration จะ save ค่าที่ค้างอยู่ใน DB ไม่ได้** จนกว่าจะแก้ให้อยู่ในกรอบ

### ทำไมถึงตีความว่ากรอกสลับช่อง

เลข 30 **เกิน** cap ของช่อง 10 นาที (สูงสุด 10) แต่ **พอดีเป๊ะ** กับ cap ของช่อง 30 นาที (สูงสุด 30) · และค่า seed เดิมก็เรียงจากน้อยไปมาก (`10min`=2, `30min`=6) → ย้ายเลขเดิมกลับช่องที่ควรอยู่ ไม่ได้คิดเลขใหม่เอง · การสลับนี้ยังลบ clamp ที่จำใจใส่ตอน v10 ไปในตัว

### สถานะ config ตอนนี้ (v11) — ผ่าน validation ครบเป็นครั้งแรก

```
xp_login_per_day          1/5     xp_team_meeting_10min     2/10
xp_office_10min           6/10    xp_team_meeting_30min     6/30
xp_office_30min          30/30    xp_first_message_fo_day   1/5
xp_team_meeting           9/50    xp_10_message_fo_day      2/10
xp_play_with_pet          1/5     xp_react_message_fo_day   1/5
```

**enabled ครบทั้ง 10 ตัว · ไม่มีตัวไหนเกิน cap**

### verify

- heartbeat 3 ครั้ง → ledger 1 แถว `xp_login_per_day` · pet xp 0 → 1 ✅ (ทำตอน v10 ก่อนสลับ)
- `xp_office_10min` **ยังไม่ได้เทสจริง** — ต้องอยู่ใน VO จริง 10 นาที และนาฬิกา session อยู่ใน memory backdate จากข้างนอกไม่ได้ · logic มี unit test ครอบแล้ว (ปลดล็อก 10/30 นาที + ไม่จ่ายซ้ำ)
- ข้อมูลเทสคืนค่าเดิม: Mochi Live = egg / 0 XP · ledger ว่าง
- [api #76](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/76) (claim fix) deploy ขึ้น dev แล้ว — `dev-9ad7733` · การเปิด/ปิด activity กลางวันจึงมีผลทันที ไม่ต้องรอวันถัดไป

### ⚠️ ยังต้องให้ PM ดู

`xp_team_meeting` = 9 XP ดูเป็นเลขที่กรอกมั่ว ๆ (cap 50) และ `xp_team_meeting_30min` = 6 น้อยกว่า `xp_office_30min` = 30 — ไม่แตะให้ เพราะเป็นเรื่องนโยบายของ PM ไม่ใช่บั๊ก

## 2026-09-04 (รอบ 22) — จ่าย XP ครบทั้ง 10 activity (งานใหญ่สุดที่ค้างอยู่)

- **ปัญหา:** `Award()` มี caller เดียวมาตลอดคือ stroke → pet โตได้ทางเดียวคือให้คนลูบ · `tb_pet_xp_config` แทบไม่มีความหมาย
- **PR:** [api #75](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/75) ✅ merged — ต่ออีก 9 activity เข้า flow ที่มีอยู่แล้ว **ไม่เพิ่ม endpoint / ไม่เพิ่ม cron / ไม่เพิ่มตาราง**

| activity | trigger |
|---|---|
| `xp_login_per_day` | presence heartbeat |
| `xp_office_10min` / `_30min` | presence heartbeat (นาฬิกา session) |
| `xp_team_meeting` | `ZoneSectionService.EnterZone` |
| `xp_team_meeting_10min` / `_30min` | presence heartbeat (นาฬิกา meeting) |
| `xp_first_message_fo_day` | `ChatService.SendMessage` |
| `xp_10_message_fo_day` | `SendMessage` + count ข้อความวันนี้ |
| `xp_react_message_fo_day` | `ChatService.AddReaction` |

- **meeting duration ไม่ต้องมี timer ของตัวเอง** — heartbeat ที่ client ส่งอยู่แล้วคือ tick · `EnterZone`/`LeaveZone` เป็นตัวเปิด/ปิดนาฬิกา · รูปแบบเดียวกับ office time เลยใช้ code path ร่วมกัน

### decision ที่ตัดเอง (ต้องให้ PM ยืนยัน)

**pet ตัวไหนได้ XP → ทุกตัวใน workspace นั้น** · เพราะ activity ส่วนใหญ่ไม่ได้เกิดใน "ห้อง" ห้องใดห้องหนึ่ง (login ไม่ได้ login ในห้อง, chat เป็นระดับ workspace) · ทางเลือกอีกทาง คือให้เฉพาะ pet ในห้องที่ยืนอยู่ จะทำให้ **pet ในห้องที่คนไม่ค่อยเข้าอยู่ที่ 0 XP ตลอดกาล** · สิ่งที่ทำให้ pet แต่ละตัวต่างกันจึงเหลือแค่การถูกลูบในห้องตัวเอง

### เรื่อง performance ที่เป็นข้อจำกัดจริงของงานนี้

award 1 ครั้ง = 1 transaction ที่ถือ row lock บน pet · ถ้ายิงทุก heartbeat ของทุกคน = พัง

→ ใช้ **in-memory claim** จำว่าวันนี้จ่ายอะไรไปแล้ว แล้ว short-circuit **ก่อน**แตะ DB · ledger ยังเป็น authority อยู่ (restart แล้วลองใหม่ครั้งเดียว โควตาปฏิเสธเอง) · ถ้า award **fail** จะ release claim ให้ event ถัดไปลองใหม่ ไม่ใช่เงียบหายไปทั้งวัน · พอจ่ายครบวันแล้ว heartbeat เหลือแค่ lookup map ตัวเดียว

### รายละเอียดที่ต้องคงไว้

- **scope ตามตาราง contract**: login / message / reaction = per user · office / meeting = **per room** (ledger `user_id` = NULL โควตาเป็นของ pet ไม่ใช่ของคน) — มี test pin ไว้
- **ไม่มีตัวไหน `TouchActivity`** — มีแต่ interaction ตรงเท่านั้นที่ reset mood clock ไม่งั้นทีมที่ active จะไม่มีวัน Sad และ SC-PET-08 จะทดสอบไม่ได้
- session clock เป็น per-process (ตั้งใจ) — เป็นตัวจับเวลาเกม ไม่ใช่ billing · ledger การันตี exactly-once ต่อวันอยู่แล้วไม่ว่าจะกี่ replica

- **verify:** `go build` / `go vet` / `go test ./...` / `go test -race` ผ่านหมด · test ใหม่ 16 ตัว (heartbeat 25 ครั้งจ่าย login ครั้งเดียว, ปลดล็อก 10/30 นาทีและไม่ซ้ำ, scope room vs user, leave แล้วนาฬิกาเริ่มใหม่, meeting duration, "นั่งใน office ไม่ใช่ meeting", ขอบ 9/10/40 ข้อความ, count fail ไม่บล็อก first message, retry หลัง fail, claim แยกตาม user/workspace, nil receiver, 50 heartbeat พร้อมกันจ่ายครั้งเดียว, ชื่อ activity key ตรงกับ seed)
### live-test บน dev แล้ว — และเจอบั๊กเพิ่ม 1 ตัว

- **ผลเทส:** heartbeat 3 ครั้ง → ledger **1 แถวเดียว** (`xp_login_per_day`, user=admin-a, awarded=1) · pet xp 0 → 1 · **short-circuit ทำงานถูกต้อง**
- **บั๊กที่เจอ → [api #76](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/76) ✅ merged:** activity ที่ถูก **ปิดใน config** ไม่ควรยึด claim ไว้
  - เทสรอบแรก heartbeat แล้วไม่ได้ XP — **สาเหตุถูกต้อง**: config version 9 ตั้ง `xp_login_per_day` และ `xp_office_10min` เป็น `enabled: false` (มีคนแก้ผ่านหน้า XP Configuration)
  - แต่ tracker **claim ไปแล้ว** → admin เปิด activity ตอนเที่ยง จะไม่มีอะไรเกิดขึ้นจนถึงวันรุ่งขึ้น และ toggle จะดูเหมือนพัง
  - แก้: `AwardWorkspaceActivity` คืน `PetXPWorkspaceOutcome{Awarded, Disabled}` แทนที่จะคืนแค่ error → caller แยก "ปิดอยู่" ออกจาก "ได้ครบโควตาแล้ว" ได้ และ release claim เฉพาะกรณีแรก
- ⚠️ **`xp_login_per_day` กับ `xp_office_10min` ยัง `enabled:false` อยู่บน dev** (config v9) — ใครจะเทสต้องไปเปิดที่หน้า XP Configuration ก่อน ไม่ใช่บั๊กโค้ด
- ข้อมูลเทสคืนค่าเดิมครบ (config กลับเป็น `enabled:false`, Mochi Live กลับเป็น egg/0 XP, ล้าง ledger + notification)

## 2026-09-04 (รอบ 21) — สรุปสถานะส่งต่อ (handoff)

> **อ่านอันนี้ก่อนถ้าจะมาทำต่อ** — รวมสถานะทุกอย่าง ณ สิ้นวัน 2026-09-04

### สถานะรวม: implement ครบทั้ง 8 scenario · deploy dev แล้ว · ไม่มี PR ค้าง

| repo | image บน dev | คือ PR |
|---|---|---|
| zyra-app | `dev-62f840b` | #256 (owner editor) |
| zyra-api | `dev-4b64210` | #74 (`GET /api/user/pets`) |
| zyra-ws | `dev-44a9616` | #33 (pet diagnostics) |

**PR ที่ merge วันนี้ทั้งหมด 16 ตัว** — api #68–#74 · ws #30–#33 · app #250–#256

### ✅ ที่ verify แล้วว่าใช้งานได้จริงบน dev (ผ่าน REST + WebSocket)

| Scenario | หลักฐาน |
|---|---|
| SC-PET-01 | `GET …/pets` คืน pet + animations 20 ตัว · ไม่มีคอลัมน์ stage/mood (derive) |
| SC-PET-02 | เดินจริง 6 tile ใน 40 วิ · `step_ms=600` · ครบ 4 ทิศ · ไม่ออกนอก zone · `/healthz` โชว์ `wander_targets=72` |
| SC-PET-03 | stroke 200 · ซ้ำทันที 429 · เกินโควตา 200 `awarded:false` · ข้าม workspace 403 · pet มั่ว 404 · ไม่มี token 401 |
| SC-PET-04/05 | 99→100 XP = `egg→baby` + `pet_growth` ถึงสมาชิกครบ 2 คน + milestone ladder reset |
| SC-PET-06 | status คืน stage/mood/quota/contributors/xp_today ครบ |
| SC-PET-07 | 49→50 XP ยิง `pet_milestone` 2 แถว · stage change ชนะ milestone ไม่ยิงซ้อน |
| SC-PET-08 | mood multiplier 15/10/5 (150%/100%/50%) · ledger บันทึก `mood_at_award` ถูก |

### ❌ ที่ยังไม่ได้ทำ — ทดสอบ UI ในเบราว์เซอร์

**ติดที่ login เท่านั้น** ไม่ใช่ปัญหาโค้ด:
- AI พิมพ์รหัสผ่านลงฟอร์มไม่ได้ (กฎความปลอดภัย)
- ฉีด token แทนก็ไม่ได้ — session ของแอปเป็น **httpOnly `refresh_token` cookie** (`lib/auth/session.ts`) JS เขียนไม่ได้ · access token อยู่ใน memory ล้วน
- Browser pane เป็นคนละ browser กับ Chrome ปกติของ user → login ฝั่ง user ไม่ carry over

**วิธีทำต่อ:** ให้ user login ใน **Browser pane** (ไม่ใช่ Chrome ตัวเอง) แล้ว AI ขับต่อได้ทันที · แผน capture 9 ไฟล์ลง `storage/preview/` (marker/tooltip/panel/growth overlay/modal/notification)

### ข้อมูลเทสที่ค้างไว้บน dev (ตั้งใจทิ้งไว้)

| pet | workspace | ที่ | สถานะ |
|---|---|---|---|
| **เจ้าปรื๊ด** | `34ffa741` (ฟหกฟหก — ของ user) | Floor 1 → room `test` → (60,39) | **baby / 150 XP** ตั้งใจให้เดินได้เลย |
| Mochi Live | `256893ae` (member-a) | Zone 1 → Room Group 3 → (60,3) | reset เป็น egg / 0 XP แล้ว |

`tb_notification` pet_* = 0 แถว · `tb_room_pet_xp_event` = 0 แถว · `xp_play_with_pet` = `{times:1, xp:1}` (ค่า seed เดิม) — ล้างครบ ไม่มีขยะค้าง

### ⚠️ 3 เรื่องที่ต้องรู้ก่อนทำต่อ

1. **`กลุ่ม Room 1–7` ใน workspace `34ffa741` วาง pet ไม่ได้เลย** — private/meeting zone ทับเต็มทุกห้อง (Private 13/14/15/16 ทับ Room 2 ทั้งห้อง) · เหลือแค่ห้อง `test` 2 ห้องที่มี tile ว่าง (121 / 83) · ไม่ใช่บั๊ก ถ้าอยากวางในห้องกลุ่มต้องแก้ขนาด private zone ก่อน
2. **`ten_dev@hpktechnology.com` เป็นแค่ `member`** ของ workspace ตัวเอง (owner = `game.ponlawat.lk@gmail.com`) → ถึงจะมี endpoint owner แล้วก็ยังวาง pet เองไม่ได้ ต้องยก role เป็น `admin` ใน workspace นั้นก่อน
3. **`Award()` มี caller เดียว** คือ stroke — อีก 9 activity (login/office/meeting/chat) ยังไม่มีใครเรียก pet จึงโตช้ามาก **นี่คืองานชิ้นถัดไปที่ใหญ่สุด**

### งานที่เหลือ เรียงตามความสำคัญ

1. **จ่าย XP ของอีก 9 activity** — แทรก `Award()` เข้า flow เดิม (login / office time / meeting / chat) · ไม่มีอันนี้ pet โตได้ทางเดียวคือให้คนลูบ
2. ทดสอบ UI ในเบราว์เซอร์ (ติด login ตามด้านบน)
3. ตั้ง `xp_play_with_pet.times` = **5** ให้ตรง SC-PET-03 (seed เป็น 1)
4. **Share your friends** ใน evolution modal — ux-ui §5.4 บอกว่ามี component อยู่แล้ว แต่จริง ๆ ไม่มีในโค้ด ต้องทำ member picker + card message type ใน chat
5. **pet facing rows** — ws ส่ง direction มาแล้ว แต่ไม่มี spec ว่า sprite row ไหนคือทิศไหน (บาง sheet มีแถวเดียว) → ต้องถาม design
6. `pet_sittable` บน object (คนละโมดูล) — ไม่มีอันนี้ pet นั่งบนเฟอร์นิเจอร์ไม่ได้ตาม SC-PET-02
7. daily reminder cron 09:00 ICT — ยังไม่ได้เทสจริง (ต้องรอเวลา หรือเรียก `SendPetDailyReminders` ตรง)

## 2026-09-04 (รอบ 20) — owner/admin ของ workspace วาง pet เองได้ + วาง pet จริงให้ user

- **PM เคาะ (ตอบคำถามค้างข้อ 10 ของ [spec.md](spec.md)):** "user ที่เป็น owner/admin map วางได้ด้วย" — ไม่ใช่แค่ System Admin

| PR | ทำอะไร | สถานะ |
|---|---|---|
| [api #73](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/73) | `GET/POST/PATCH/DELETE /api/user/maps/:mapId/pets` — gate ด้วย `VerifyUserCanManageMapWorkspace` (owner หรือ admin member) ตัวเดิมที่ object/zone ใช้อยู่ | ✅ merged + deploy dev |
| [api #74](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/74) | `GET /api/user/pets` — pet type ที่วางได้ สำหรับ palette (rule 15: ห้าม member เรียก `/api/admin/pets`) | ✅ merged |
| [app #256](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/256) | เปิด palette ใน `/workspace/builder/[id]` — ตัด `!userMode` ออก · `useEditorApi(userMode)` bind endpoint family ให้ เหมือน object/zone | ✅ merged |

### สิ่งที่เกือบพลาด (เจอตอนทำ #256)

เปิด `petPlacementEnabled` ใน userMode เฉย ๆ จะ **403 ทันทีที่เปิด palette** เพราะ editor เรียก 2 endpoint ที่เป็น admin ล้วน:

| read | เดิม | ใหม่ |
|---|---|---|
| palette | `/api/admin/pets` | `/api/user/pets` |
| stage thresholds | `/api/admin/pet-xp-config` | `/api/user/pet-xp-config` |

นี่คือกับดักที่ rule 15 มีไว้ดักพอดี และจะโผล่ตอน runtime เฉพาะกับคนที่ไม่ใช่ admin เท่านั้น → เขียน test ที่ pin URL ครบทุกตัวของทั้ง 2 family + assert ว่า call ฝั่ง owner ไม่มีตัวไหนไป `/api/admin` เลย

### design decision

แยก handler (`RoomPetOwnerHandler`) ไม่ใช่ขยาย guard ของตัวเดิม เพราะเป็นคนละ surface จริง ๆ:

| | `/api/admin/maps/:mapId/pets` | `/api/user/maps/:mapId/pets` |
|---|---|---|
| guard | AdminGuard | UserGuard + map-manage role |
| ขอบเขต | map ของใครก็ได้ | เฉพาะ map ที่ตัวเองเป็นเจ้าของ |
| workspace lock | ต้องถือ | ไม่ต้อง |

lock คือความต่างที่มีสาระ — system admin แก้ template ที่ใช้ร่วมกันจึงต้องกันคนอื่น ส่วน owner ตกแต่งออฟฟิศตัวเองไม่ต้อง (ตรงกับที่ hero-workspace-editor เขียนไว้อยู่แล้วว่า "userMode skips the lock system") · ทั้งคู่ใช้ `RoomPetService` เดียวกัน กฎ placement จึงเหมือนกันเป๊ะ และมี test pin `detail.code` ของทั้ง 2 ฝั่งไว้กันหลุด

### วาง pet จริงให้ user แล้ว

- **"เจ้าปรื๊ด"** (type Pie) — workspace `ฟหกฟหก` → **Floor 1** → room **`test`** → tile **(60,39)** · ตั้งเป็น **baby / 150 XP / mood happy** เพื่อให้ AI เดินให้เห็น
- **ครั้งแรกวางไม่ผ่าน** ที่ `กลุ่ม Room 2` → `POSITION_BLOCKED_BY_ZONE` · **ไม่ใช่บั๊ก** — Private 13/14/15/16 ทับ Room 2 ทั้งห้อง · เช็คครบทั้ง 9 ห้องแล้ว: **`กลุ่ม Room 1–7` ถูก private/meeting zone ทับเต็มทุกห้อง** เหลือแค่ห้อง `test` 2 ห้องที่มี tile ว่าง (121 และ 83 tile)
- ต้องวางด้วย `admin-a` (System Admin) เพราะ **`ten_dev@hpktechnology.com` เป็นแค่ `member`** ของ workspace นั้น (owner คือ `game.ponlawat.lk@gmail.com`) → ถึงมี endpoint ใหม่แล้วก็ยังวางเองไม่ได้ ต้องยกเป็น `admin` ใน workspace ก่อน · acquire lock → place → release lock เรียบร้อย

- **ยังค้าง:** ทดสอบ UI ในเบราว์เซอร์ — ติดที่ผมพิมพ์รหัสผ่านลงฟอร์มไม่ได้ และ session ของแอปเป็น httpOnly `refresh_token` cookie จึงฉีด token แทนไม่ได้ · รอ user login แล้วผมค่อยขับต่อ

## 2026-09-04 (รอบ 19) — deploy dev + ตรวจ AC ทุกใบกับของจริง → เจอบั๊ก 3 ตัว

- **ทำอะไร:** user สั่ง "ตั้ง `NEXT_PUBLIC_ROOM_PET` แล้ว deploy dev" + "เช็ค AC / Business Logic ทุก scenario ว่าทำงานได้จริงมั้ย"
  - ตั้ง secret `NEXT_PUBLIC_ROOM_PET=true` ที่ GitHub Environment `dev` ของ zyra-app (ของเดิมมีอยู่แต่ค่าอ่านไม่ได้ — ทับเป็น `true`)
  - merge PR ที่ค้าง (app #254 #255) → dev deploy ครบทั้ง 3 repo · **app `dev-9eeeb2a` build หลังตั้ง secret** จึง bake flag ติดมาแล้ว

### บั๊กที่เจอตอนเทสของจริง (ทั้ง 3 ตัวแก้แล้ว)

| # | บั๊ก | เจอยังไง | แก้ที่ |
|---|---|---|---|
| 1 | **embedded DDL ทับ constraint ของ migration 90 ทุกครั้งที่ pod restart** → insert notification `pet_*` ตกทุกครั้ง (fail แบบเงียบ เพราะ notification เป็น best-effort) · แถม `tb_room_pet` / `tb_room_pet_xp_event` / `last_milestone` **ไม่มีใน embedded DDL เลย** → env ที่ deploy ใหม่จะไม่มีตารางเลย | stroke ที่ 49 XP แล้ว `last_milestone` ขยับเป็น 50 แต่ `tb_notification` ว่าง | [api #72](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/72) |
| 2 | **คนยืนใกล้ = pet แข็งค้างถาวร** — พอหันหน้าหาเสร็จแล้ว react branch `return` ทุก tick ไม่เคยไปถึงการตัดสินใจ wander อีกเลยตราบที่คนยังยืนอยู่ | probe client ยืนห่าง 1 tile ดู `pet_state` 60 วิ — หันหน้า 1 ครั้งแล้วนิ่งสนิท | [ws #32](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/32) |
| 3 | **idle-out ผูกกับ notice radius (3 tiles) แทนที่จะเป็น "ในห้อง"** — ทีมที่นั่งอยู่มุมไกลของห้องนับเป็น "ไม่มีใคร" pet เลยเงียบไปทั้งที่มีคนดูอยู่ | อ่านโค้ดตอนไล่บั๊ก #2 | [ws #32](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/32) |

บั๊ก #2 และ #3 มี regression test ที่ **fail กับโค้ดเก่า** และ pass กับโค้ดใหม่ (พิสูจน์ด้วยการ stash แล้วรัน)

- **เพิ่ม observability:** [ws #33](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/33) — `/healthz` คืน state ของ pet AI ทุกตัว (stage / mood / ตำแหน่ง / กำลังเดินมั้ย / เหลือกี่ ms ถึงตัดสินใจ / ห้องว่างมั้ย / **มีกี่ tile รอบบ้านที่เดินได้จริง**) เพราะ pet ที่ "นิ่ง" ถูกต้อง (ไข่ / เศร้า / ห้องว่าง / ถูกเฟอร์นิเจอร์ล้อม) หน้าตาเหมือน pet ที่พังทุกประการ — เสียเวลาเดาไปครึ่งวันเพราะไม่มีอันนี้

### ผลตรวจ AC — เทสกับ dev จริง (api `dev-330e77a`+, ws `dev-4ac09ac`+)

| Scenario | เทสอะไร | ผล |
|---|---|---|
| SC-PET-01 | `GET /api/user/workspaces/:id/pets` | ✅ คืน pet + animations 20 ตัว · ไม่มีคอลัมน์ `stage`/`mood` (derive ตามดีไซน์) |
| SC-PET-02 | probe client ต่อ `wss://ws.dev.zyra.center` | ✅ `pet_state` heartbeat ทุก 2 วิ · ✅ หันหน้าหาคน · ✅ **เดินจริง** หลังแก้บั๊ก #2: 40 วิ เดินผ่าน 6 tile `(60,3)→(59,2)→(60,2)→(61,1)→(62,1)→(62,2)` · 6 moving frame `step_ms=600` + 16 idle heartbeat · เห็นครบทั้ง 4 ทิศ · ไม่ออกนอก zone |
| SC-PET-03 | stroke / rate limit / โควตา / ข้าม workspace / pet มั่ว / ไม่มี token | ✅ 200 · 429 `RATE_LIMITED` · 200 `awarded:false DAILY_LIMIT_REACHED` · 403 · 404 · 401 |
| SC-PET-04/05 | stroke ที่ 99 XP | ✅ `egg → baby` · ยิง `pet_growth` ให้สมาชิกครบ 2 คน · `last_milestone` reset เป็น 0 ให้ stage ใหม่ |
| SC-PET-06 | `GET …/status` | ✅ stage / mood / quota / contributors / xp_today ครบ |
| SC-PET-07 | stroke ที่ 49 XP (ข้าม 50%) | ✅ `pet_milestone` 2 แถว (หลังแก้บั๊ก #1) · stage change ชนะ milestone ไม่ยิงซ้อน |
| SC-PET-08 | ตั้ง `last_activity_at` ย้อน 0 / 40 / 200 ชม. แล้ว stroke (base xp=10) | ✅ ได้ 15 / 10 / 5 ตรงกับ 150% / 100% / 50% · ledger บันทึก `mood_at_award=sad` ถูกต้อง |

ข้อมูลเทสคืนค่าเดิมหมดแล้ว (pet `Mochi Live` กลับไป xp=0 stage=egg, config `xp_play_with_pet` กลับเป็น times=1 xp=1)

- **ปิดครบ:** `/healthz` ตัวใหม่ยืนยันว่า pet ทำงานปกติ — `stage=baby mood=happy home=60,3 tile=(59,2) wander_targets=72 quiet=false` (ที่เดาว่าโดน obstacle ล้อมคือเดาผิด มี 72 tile ให้เดิน) · ที่เห็นนิ่งก่อนหน้าคือบั๊ก #2 ล้วน ๆ
- **ยังไม่ได้เทสด้วยตา:** ทุกอย่างฝั่ง UI (marker / tooltip / panel / growth overlay / notification card) — รอบนี้ตรวจผ่าน REST + WebSocket ล้วน ยังไม่ได้เปิดเบราว์เซอร์เข้า VO จริง
- **ยังไม่ได้เทส:** อีก 9 activity ที่ยังไม่มีคนเรียก `Award()` · daily reminder cron 09:00 ICT (ต้องรอเวลาจริง หรือเรียก `SendPetDailyReminders` ตรง ๆ)

## 2026-09-04 (รอบ 18) — implement SC-PET-01 ~ 08 ครบทุกใบ (8 PR)

- **ทำอะไร:** ผู้ใช้สั่ง "ทำต่อให้เสร็จเลยนะ ทั้งหมด" → ไล่ทำ scenario ที่เหลือทั้งหมดจนครบ 8 ใบ

| PR | repo | scenario | สถานะ |
|---|---|---|---|
| [api #69](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/69) | zyra-api | echo `last_activity_at` ใน `pet_xp_changed` | ✅ merged |
| [app #251](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/251) | zyra-app | **SC-PET-03** stroke + **SC-PET-06** panel ต่อ API จริง | ✅ merged |
| [app #252](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/252) | zyra-app | **SC-PET-04 / 05** growth sequence + modal | ✅ merged |
| [app #253](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/253) | zyra-app | **SC-PET-08** sad sprite | ✅ merged |
| [api #70](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/70) | zyra-api | internal pet list ให้ ws (`GET /api/internal/workspaces/:id/pets`) | ✅ merged |
| [ws #31](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/31) | zyra-ws | **SC-PET-02** pet AI (wander / idle / react) | ✅ merged |
| [app #254](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/254) | zyra-app | **SC-PET-02** client — interpolate `pet_state` | รอ CI |
| [api #71](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/71) | zyra-api | **SC-PET-07** notification 3 ชนิด + cron 09:00 ICT | ✅ merged |
| [app #255](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/255) | zyra-app | **SC-PET-07** client — notification card + interrupt rule | รอ CI |

- **decision ที่ตัดเองระหว่างทาง** (เขียนเหตุผลไว้ในโค้ด + PR body ทุกข้อ):
  1. **`Feed` ไม่ทำ** — card ตัดชื่อออกแล้ว เหลือ Stroke อย่างเดียว (ตอบคำถาม PM ข้อ 1)
  2. **Top 3 carers ไม่ทำ** — Figma แทนที่ด้วย Daily quest ตาม ux-ui §0 "ยึด Figma" · ข้อมูลมีใน `GET …/status` แล้ว ถ้า PM อยากได้คืนเพิ่ม section ได้เลย
  3. **Share your friends ไม่ทำ** — ux-ui §5.4 บอกว่าเป็น component เดิม แต่ `grep "Share to your friends"` ในโค้ดไม่เจอ (ต้องทำ member picker + card message type ใน chat ใหม่ทั้งชุด) · ปุ่มที่กดไม่ได้แย่กว่าไม่มีปุ่ม → แยกเป็นงานต่างหาก
  4. **HUD banner 5 วิ ไม่ทำ** — Figma แทนที่ด้วย modal เต็มจอ ซึ่งทุกคนใน workspace ได้อยู่แล้ว (คนที่ไม่ได้ trigger เปิดที่ modal เลย) · ทำทั้งคู่ = ประกาศเรื่องเดียวกันสองที่
  5. **facing ของ pet ไม่ทำ** — ws ส่ง direction มาแล้ว แต่ **ไม่มี spec ว่า sprite row ไหนคือทิศไหน** ของ pet sheet (บาง sheet มีแถวเดียว) เดาแล้วจะวาดหันผิดทาง → เปิดเป็นคำถาม design
  6. **ledger ไม่ใช้ unique index** ตามที่ contract ร่างไว้ — unique จะจ่ายได้ activity ละ 1 ครั้ง/วัน แต่ `times` ตั้ง > 1 ได้ (stroke 5 ครั้ง/วัน) → นับด้วย `COUNT(*)` ใต้ row lock แทน
  7. **เฉพาะ interaction ตรงกับ pet เท่านั้นที่ reset `last_activity_at`** — ถ้า login/office/chat reset ด้วย ทีมที่ active จะไม่มีวัน Sad และ SC-PET-08 เทสไม่ได้
  8. **stage change ชนะ milestone** — ข้าม threshold = เต็ม 100% แล้วรีเซ็ต ประกาศ "50% ของช่วงถัดไป" พร้อมกันเป็น noise · award ก้อนใหญ่ที่กระโดด 40% → 95% ประกาศแค่ 90 ไม่ประกาศทั้ง 3
- **verify ถึงไหน:**
  - **build เขียว ทุก repo**: zyra-api `go build`/`go vet`/`go test ./...` · zyra-ws เหมือนกัน · zyra-app `tsc` + `eslint` + **vitest 1558 ผ่าน** (3 pre-existing tsc error บน develop ไม่เกี่ยว)
  - **live-test ผ่านจริงเฉพาะ XP engine** (รอบ 17) — stroke / 429 / โควตา / 403 / 404 / `egg→baby` + เห็น 2 event บน `redis-cli SUBSCRIBE vo:zone`
  - **ยังไม่ได้ live-test:** pet AI เดินจริงในห้อง (ต้อง deploy ws + api ใหม่ก่อน) · growth sequence เต็มจอ · notification 3 ชนิด (ไม่มี pet ตัวไหนบน dev ใกล้ threshold พอจะยิงเองได้) · ทุกอย่างต้องเปิด `NEXT_PUBLIC_ROOM_PET=true` + prod build ([[vo-verify-needs-prod-build]])
- **migration ที่รันบน dev DB แล้ว:** 89 (`tb_room_pet_xp_event`), 90 (`tb_notification` 3 type ใหม่ + `tb_room_pet.last_milestone`)
- **ต่อจากนี้:**
  1. deploy dev แล้ว live-test ครบทั้ง 8 scenario (ต้องตั้ง `NEXT_PUBLIC_ROOM_PET` secret ก่อน — ตอนนี้ยังไม่ตั้ง = ปิดทุก env)
  2. ตั้ง `xp_play_with_pet.times` = 5 ในหน้า XP Configuration (seed เป็น 1 แต่ SC-PET-03 เขียน 5)
  3. จ่าย XP ของอีก 9 activity (login / office / meeting / chat) — ต้องแทรก `Award()` เข้า flow เดิม ยังไม่ทำ
  4. Share flow + pet facing rows — รอ design/PM
- **ติดอะไร:** 5 decision ด้านบนควรให้ PM/design ยืนยัน · `pet_sittable` บน object (ข้อ 15 ของ spec) ยังไม่มี — pet จึงยังนั่งบน object ไม่ได้

## 2026-09-04 (รอบ 17) — PR 9: XP engine + ledger · pet โตได้จริงเป็นครั้งแรก

- **ทำอะไร:** ปิดช่องว่างใหญ่สุดที่บล็อก SC-PET-03/04/05/06/08 — `tb_pet_xp_config` มี consumer แล้ว
  - `zyra-api/migrations/89_room_pet_xp_event.sql` — ledger `tb_room_pet_xp_event` (รันบน dev DB แล้ว ยืนยันด้วย `information_schema.columns`)
  - `internal/service/room_pet_xp_service.go` — `Award()` ทำใน transaction เดียวที่ถือ `SELECT ... FOR UPDATE` บนแถว `tb_room_pet`: นับ quota ของวัน → คูณ mood multiplier → insert ledger → บวก `xp` → เทียบ stage กับ `last_seen_stage` → publish · `Status()` ตอบ Pet panel (stage/mood/quota/top-3/xp วันนี้)
  - `internal/handler/room_pet_xp_user_handler.go` + route: `POST /api/user/workspaces/:id/pets/:petId/play` (SC-PET-03) · `GET …/status` (SC-PET-06) — `/api/user/*` ล้วนตาม rule 15
  - `pet_xp_changed` / `pet_stage_changed` = 2 event สุดท้ายของ 6 ตัวที่ zyra-ws relay อยู่แล้ว → **ไม่ต้องแก้ ws**
- **ตัดสินใจเองตรงที่ spec เว้นไว้** (ใส่เหตุผลไว้ใน `PetManagement/db-schema-api-contract.md` §5 + คำถามข้อ 4/5/10/11):
  1. **ไม่ใช้ unique index** `(pet, activity, day, user)` ตามที่ contract ร่างไว้ — unique จะยอมจ่ายได้ activity ละ 1 ครั้ง/วันเท่านั้น แต่ `times` ตั้งได้ > 1 (stroke = 5 ครั้ง/วันตาม SC-PET-03) → ใช้ index ธรรมดา + `COUNT(*)` ใต้ row lock แทน
  2. `day_key` เป็น DATE ตาม **UTC+7** ไม่ใช่ UTC
  3. **เฉพาะ interaction ตรงกับ pet เท่านั้นที่ reset `last_activity_at`** — ถ้า login/office/chat reset ด้วย ทีมที่ active จะไม่มีวัน Sad และ SC-PET-08 จะเทสไม่ได้
  4. ครบโควตาวันแล้ว = **200 `awarded: false`** ไม่ใช่ error (animation ยังเล่น แค่ไม่ได้ XP ตาม SC-PET-06) · มีแต่ spam guard 3 วิ ที่ตอบ 429
  5. `xp_play_with_pet` = stroke (ตอบคำถามค้างข้อ 5 ของ PetManagement จาก card Room Pet)
- **PR:** [api #68](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/68) (`feat/room-pet-xp-engine` → develop) — ยังไม่ merge
- **verify ถึงไหน:**
  - **build เขียว**: `go build` / `go vet` / `go test ./...` ผ่านหมด · test ใหม่ 7 ตัว (service, table-driven: stage derive, threshold validation, ขอบ mood รวมช่วง 48–72 ชม. ที่ card เว้นไว้, การปัดลงของ multiplier, day rollover UTC+7) + 11 เคส (handler)
  - **live-test ผ่านจริง** กับ dev DB + Redis + token ของ `member-a` บน pet "Mochi Live":

    | เคส | ผล |
    |---|---|
    | stroke | 200 `xp_awarded: 1` (base 1 × happy 150% ปัดลง) |
    | stroke ซ้ำทันที | 429 `RATE_LIMITED` |
    | stroke เกินโควตาวัน | 200 `awarded: false` `reason: DAILY_LIMIT_REACHED` |
    | pet ของ workspace ที่ไม่ได้เป็นสมาชิก | 403 `FORBIDDEN` (เช็ค membership ก่อน lookup) |
    | pet id มั่ว | 404 `ROOM_PET_NOT_FOUND` |
    | XP 99 → stroke | stage `egg` → `baby` · เห็นทั้ง `pet_xp_changed` และ `pet_stage_changed` บน `redis-cli SUBSCRIBE vo:zone` |
    | status | contributors + `xp_today` มาครบ |

    ข้อมูลเทสคืนค่าเดิม (xp=0, stage=egg, ล้าง ledger) หลังเทสเสร็จ
  - **ยังไม่ได้เทส:** ฝั่ง client (ยังไม่มีปุ่ม stroke ใน VO) · concurrent stroke 2 คนพร้อมกัน (row lock ยังพิสูจน์ด้วย test จริงไม่ได้ — เป็น argument จาก `FOR UPDATE`)
- **ต่อจากนี้:**
  1. app: ผูก `VOPetPanel` + marker 🤚 เข้ากับ `POST …/play` และ `GET …/status` จริง (ตอนนี้ panel ยังใช้ mock) → SC-PET-03 / SC-PET-06
  2. api: จ่าย XP ของอีก 9 activity (login / office / meeting / chat) — ต้องแทรก `Award()` เข้า flow ที่มีอยู่ ทำเป็น PR แยก
  3. app: evolution overlay + modal ตอนรับ `pet_stage_changed` → SC-PET-04 / SC-PET-05
  4. zyra-ws: pet AI movement (SC-PET-02) — **ยังไม่มี technical design เลย** ต้องเขียนก่อน
- **ติดอะไร:** ต้องให้ PM ยืนยัน 4 ข้อ (scope per-user/per-room, activity ไหน reset mood, `times` ของ stroke ควรเป็น 5 ไม่ใช่ 1, และ mood multiplier มีผลกับ stroke ตอน Sad ไหม) · comment ใน `zyra-ws/internal/hub/message.go` เขียน payload ของ `pet_stage_changed` เป็น `{from, to}` ซึ่งไม่ตรงของจริง (`{stage, prev_stage, …}`) — ws เป็น relay ล้วนจึงไม่พัง แต่ควรแก้ comment

## 2026-09-04 (รอบ 16) — เก็บ 3 บั๊ก UI จาก user เทสเอง + ปิดช่องว่างสุดท้ายของ SC-PM-05

- **user เทส Map Editor เอง (dev build local ที่ผมรันให้) แล้วส่ง feedback 3 จุด:**
  1. hover preview บน palette ต้องโชว์ครบ 4 growth stage ตาม [Figma 4141:760560](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4141-760560) — ของเดิมโชว์ pet type อื่นแทน (ตีความ Figma ผิดตอนทำ #246 — swatch row คือ stage ของตัวเดียวกัน ไม่ใช่ type อื่น)
  2. marker บนแมพ (ตอนแรกทำ derive stage ไปแสดงเป็นไข่) สลับกับที่ user ต้องการจริง: **บนแมพต้องเป็นรูปโตเต็มวัย (thumbnail) เมนู (ปุ่มลบ) ต้องเป็นรูปไข่** (stage จริง) — ผมเข้าใจสลับตอนแรก user แก้ให้ถูกอีกที
  3. `PetMarkerLayer` z-index (46) สูงกว่า popup ทุกเมนู (30) → marker แสดงทะลุทับเมนูตอนเปิด (screenshot user ส่งมาเห็นไอคอนโผล่ข้างเมนู)
- **ทำอะไร:** zyra-app worktree แยก (`run/zyra-app`) แก้ทั้ง 3 จุด:
  - `object-library-panel.tsx` — `PetHoverPreview` เปลี่ยนจาก siblings row เป็น stage row: ดึง `usePetTypeAnimations(pet.id)` (hook ใหม่ cache ตาม pet type, เรียก `GET /api/admin/pets/:id`) แล้ว `pickStageIdleAnimation` (แยกออกจาก `lib/pet-scene.ts`'s `pickIdleAnimation` ให้รับ animations ตรงๆ ไม่ต้องผ่าน `WorkspacePet`) ต่อด้วย `usePetAnimationFrame` (hook ใหม่ ครอปเฟรม 0 เป็น PNG data URL ผ่าน `lib/pet-sprite-preview.ts` แคชตาม sprite_url — logic เดียวกับที่ VO ใช้คือ `lib/sprite-grid.ts` เพราะ sheet มี gutter หารตรงๆ ไม่ได้)
  - `pet-marker-layer.tsx` — ทำ `PetMarkerButton` (derive stage แสดงไข่) ก่อน แล้ว**ย้อนกลับ**ตาม feedback ข้อ 2: marker บนแมพกลับไปใช้ `pet.thumbnail_url` เหมือนเดิม (ของเดิมถูกอยู่แล้ว) เหลือแค่แก้ `zIndex: 46 → 20` (ต่ำกว่าทุกเมนู 30 แต่ยังสูงกว่า ZoneCanvasLayer overlay สูงสุด 17)
  - `pet-marker-menu.tsx` — ไอคอนในเมนูเปลี่ยนจาก `pet.thumbnail_url` เป็น derived stage sprite จริง (`usePetTypeAnimations` + `derivePetStage(pet.xp, thresholds)` + `pickStageIdleAnimation` + `usePetAnimationFrame`) — จุดนี้คือจุดที่ user ต้องการจริง (เมนู = ไข่)
  - `hero-workspace-editor.tsx` — เพิ่ม fetch `getPetXPConfig()` (admin endpoint) เก็บ `petStageThresholds` ส่งเข้า `PetMarkerMenu` เท่านั้น (ไม่ส่งเข้า `PetMarkerLayer` เพราะ marker บนแมพไม่ต้อง derive แล้ว)
  - tests: แก้ `pet-marker-menu.test.tsx` (mock 2 hook ใหม่ยืนยันว่าไอคอนมาจาก derived stage ไม่ใช่ thumbnail_url ตรงๆ + เคส fallback PawPrint) · เพิ่ม `pet-scene.test.ts` คุม `pickStageIdleAnimation` เวอร์ชัน raw-array
- **verify ถึงไหน:** tsc สะอาด (error เดิม 1 ตัวใน `pet-creation-wizard.test.tsx` ยืนยันแล้วว่ามีอยู่ก่อนแก้ ไม่เกี่ยวกับรอบนี้) · eslint/prettier สะอาด · vitest ทั้ง repo 119 ไฟล์ **1491 เคสผ่าน** · build production สำเร็จ 2 รอบ (รอบแรกก่อนกลับด้าน marker, รอบสองหลังแก้ตาม feedback)
  - **live-test ใน Browser pane ต่อ local build**: hover การ์ด "Pie" → เห็น 4 ไอคอน egg/baby/adult/evolved จริง (ครอปจากสไปรต์จริง ไม่ใช่ placeholder) · marker "Mochi Live" บนแมพ = URL รูปจาก R2 (thumbnail) ยืนยันจาก DOM `<img src>` · เปิดเมนู "Mochi Live" → icon เป็น `data:image/png` (ครอปจากสไปรต์ไข่จริง) ไม่ใช่ thumbnail · เมนูไม่มี marker ทะลุทับอีก (`getComputedStyle` ยืนยัน layer z=20 < เมนู z=30, `elementFromPoint` ที่จุดซ้อนกันได้เมนูเสมอ)
  - **ปิดช่องว่างสุดท้ายของ SC-PM-05**: เปิด VO ค้างไว้ฝั่ง member (login คนละ tab ไม่ reload) แล้ว admin วาง pet ใหม่ผ่าน API → pet โผล่บน minimap ของ member ภายใน ~4 วิ **โดยไม่ reload หน้า** — พิสูจน์ acceptance "Broadcast hot reload ให้ users ที่ online" ครบวงจริงเป็นครั้งแรก (ก่อนหน้านี้มีแค่ unit test ของ ws relay + live test แค่ rename/move ไม่เคยทดสอบ spawn ระหว่างเปิด VO ค้างอยู่)
- **สรุป SC-PM-05 เทียบ Acceptance Criteria + Business Logic ของ card ClickUp `86d3dcet3`:** ครบทั้ง 8 AC + 4 Business Logic — 9 ข้อตรงเป๊ะ, 3 ข้อ (spawn position ไม่ใช่ center + event name ต่างจาก `ws:pet:spawned`) ต่างตรงตัวอักษรแต่เป็นการตัดสินใจของ PM ที่มาทีหลัง card (ยึด Figma) ไม่มีข้อไหนตกหล่น — ตารางเต็มอยู่ที่ [PetManagement/spec.md § SC-PM-05 AC ↔ implementation](../PetManagement/spec.md)
- **PR:** ยังไม่เปิด — แก้อยู่ใน worktree ท้องถิ่น (`run/zyra-app`, feature branch `feat/room-pet-editor-polish` แตกจาก develop `dd35bdf`) รอ user สั่ง commit + PR
- **ต่อจากนี้:** commit + PR (ผู้ใช้ยังไม่สั่ง) → **SC-PM-05 พร้อมส่ง QA เต็มรูปแบบ** (ครบทุก AC + live-verified ทุกจุดรวมช่องว่างสุดท้าย) → หลังจากนั้นขั้น 5 ตาม roadmap: PR 9 XP engine (รอ PM เคาะ scope activity + "เล่นกับ pet")
- **ติดอะไร:** ยังไม่ได้ commit/PR รอคำสั่ง user · เรื่องค้าง PM เดิม (template, stage row) ยังไม่มีคำตอบใหม่

## 2026-09-04 (รอบ 15) — PR 11 VO render + เก็บ SC-PM-05 ให้ครบ Acceptance ก่อนส่ง QA

- **PM/user เคาะ (2026-09-04):** ตัด **stage row ใน marker menu** ออกจาก v1 — ใช้ Replace แทน ("เปลี่ยนชนิดสัตว์แต่ XP/stage ติดห้องเดิม") · pet เป็นของ **workspace จริง** (ไม่ผูก template) ตามที่แนะนำ ยังรอ PM ยืนยันเรื่อง template อีกครั้ง · user ย้ำให้ **ปิด SC-PM-05 ให้ครบ AC ก่อนส่ง QA** ก่อนไปงานอื่น
- **ทำอะไร:**
  - **PR 11** zyra-app `feat/room-pet-vo-render` → **[#248](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/248)**: `hooks/use-workspace-pets.ts` (TanStack, gated flag) · `lib/pet-scene.ts` (stage→sheet, mood→emoji, ratio, WS delta reducer) · `zyra-engine/pixi-game/pet-layer.ts` (`PetLayer`: sprite 1 tile ใน mainContainer slot character, nameplate ใน name-tag layer, ตัดเฟรมด้วย `lib/sprite-grid` จาก `/api/img`, sheet หาย = ไม่วาด, `petAt`) · scene `setRoomPets/setOnPetClick` + click ก่อน zone/walk · ws types `pet_*` 4 ตัว · hero: pets ของชั้น → scene + minimap dots · คลิก pet → `VOPetPanel` มุมขวาบน · **แก้ `layoutPetNameTag` ใช้ solid fill แทน FillGradient** (gradient ใน sprite batch ทำ WebGL uniform พัง เกิด streak ทั้งฉาก)
  - **AC 2 ของ SC-PM-05 ("Room list มี badge มี Pet แล้ว")** → zyra-app `feat/room-pet-editor-has-pet-badge` **[#247](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/247)**: Layers tab ใน Map Editor แสดงห้องที่มี pet เสมอ + badge เขี้ยวม่วง + ชื่อ pet (i18n `leftPanelRoomHasPet` en/th)
- **verify ถึงไหน:** tsc/eslint/prettier ผ่าน · vitest ทั้ง repo 118 ไฟล์ 1483 เคส · **live production build** (`next build` + `start` :3300 ต่อ api local #66 :3012 + ws local #29 :3103 + dev DB) เป็น member-a: ไข่ "Mochi" วาดใน Room Group 3 พร้อม pill 🐾 ชื่อ 🥰 + XP bar · minimap dot ม่วง · admin PATCH rename+move ผ่าน API → pill/ตำแหน่งบน VO เปลี่ยนภายใน 1 วิ (relay `pet_renamed`/`pet_moved` ครบวง) · คลิกไข่ → VOPetPanel 0/100 XP · Happy · Egg · Daily quest 8 ข้อจาก config จริง · console ไม่มี error จากโค้ด pet
  - **บทเรียน:** dev server (`next dev`) วาด VO เพี้ยน (sprite ยืด/zoom มั่ว) ต้อง build+start เท่านั้น (user ยืนยัน) · Browser pane ที่ซ่อน → tab background → hero ตั้ง away แล้ว auto-leave หลัง `AWAY_AUTO_LEAVE_MS` (`/workspace?notice=idle_removed`) ทำให้ session หลุดกลาง test 2 ครั้ง ไม่ใช่บั๊กของ pet
  - badge #247 ยังไม่ได้ดูภาพจริง (worktree แยกกำลังเปิด)
- **สถานะ SC-PM-05 เทียบ Acceptance Criteria ของ card** (card ยังเป็น flow ฟอร์ม PM เปลี่ยนเป็น drag-drop 08-17): ดูตาราง [PetManagement/spec.md § SC-PM-05 AC ↔ implementation](../PetManagement/spec.md)
- ✅ **merged 2026-09-04:** #247 `0d29a18` (badge, ดูภาพจริงใน Layers tab แล้ว: "Room Group 3 🐾 Mochi Live") → #248 `357a61b` (VO render) → dev deploy อัตโนมัติ · ลบ worktree/branch/local server ชั่วคราวแล้ว
- **ต่อจากนี้:** QA เทส SC-PM-05 บน dev ตามตาราง AC ใน PetManagement/spec.md (pet ตัวอย่าง "Mochi Live" อยู่ในห้อง Room Group 3 ของ workspace `256893ae` ของ member-a) · เรื่องค้าง PM: template · แล้วค่อยขั้น 5 PR 9 XP engine
- **ติดอะไร:** AC "spawn ที่ center ของ room" ขัด PM decision (วางตรงที่ admin ลาก) ต้องบอก QA · `pet_spawned/pet_removed` refetch path ยังไม่ได้ live-test · multi-floor ยังไม่ได้ทดสอบ

## 2026-09-04 (รอบ 14) — ขั้น 1–3 ของ roadmap: merge #65 / #246 / #29 + PR 10 member API

- **roadmap ที่ user อนุมัติ** (2026-09-04): 1 merge api #65 + app PR 8 → 2 ws PR 7 → 3 api PR 10 member API → 4 app PR 11 VO render → 5 api PR 9 XP engine → 6 ws pet AI → 7 notifications · หลัก: Postgres เป็นความจริง / stage+mood derive / AI อยู่ที่ ws / XP จ่ายฝั่ง server · ข้อเสนอต่อ PM: ตัด stage row ออกจาก v1 (Replace ครอบ) และ pet เป็นของ workspace ไม่ใช่ template (ถ้าต้องการ default ทำตอน clone)
- **ทำอะไร:**
  - ✅ **merged** zyra-api #65 (`ce62893`) · zyra-app #246 (`20d6db6`, PR 8 Map Editor) · zyra-ws #29 (PR 7 relay `pet_*` 6 type) → ทั้ง 3 service deploy dev อัตโนมัติ (migration 88 อยู่บน dev แล้ว)
  - **PR 10** zyra-api branch `feat/room-pet-member-api`: `GET /api/user/workspaces/:id/pets` (UserGuard, owner/member ผ่าน `VerifyUserIsMember` ไม่ผ่าน = 403 `FORBIDDEN` แม้ workspace ไม่มีจริง — ไม่ leak) → `{items: WorkspacePet[] (RoomPet + animations[] ทุก stage/slot ของ pet type), total}` ทุกชั้นในครั้งเดียว client filter `map_id` เอง · animations ดึงครั้งเดียวด้วย `ANY($1)` · ไม่ส่ง `stage/mood` (derive ฝั่ง client) · handler ใช้ interface แคบ 2 ตัว · ไม่มี migration
  - tests: `room_pet_user_handler_test.go` 5 เคส + `attachPetAnimations` / `distinctPetTypeIDs`
- **verify ถึงไหน:** `go test ./...` เขียว · live กับ dev DB: 401 ไม่มี token · member-a ใน workspace ที่ไม่ได้เป็นสมาชิก → 403 · workspace ตัวเอง → 200 ว่าง · admin วาง "Mochi" → member GET ได้ 1 ตัว xp 0 ไม่มี field stage **animations 20** · member เรียก `/api/admin/maps/:id/pets` → 403 · workspace มั่ว → 403 · cleanup แล้ว
- **PR:** **[zyra-api #66](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/66)** เปิด 2026-09-04 รอ CI/merge
- **ต่อจากนี้:** ขั้น 4 PR 11 VO render (branch `feat/room-pet-vo-render` เตรียมแล้วจาก develop `20d6db6`): โหลด `GET /api/user/workspaces/:id/pets` + ฟัง `pet_*` จาก ws → วาด sprite ตาม stage (Idle นิ่งก่อน) + nameplate/minimap dot/panel ที่ทำไว้ใน #241 · แล้วขั้น 5 PR 9 XP engine (รอ PM เคาะ scope activity + "เล่นกับ pet")
- **ติดอะไร:** `POST …/pets/:petId/play` ยังไม่มี (ไปกับ PR 9) · ws relay ยังไม่ได้ live e2e (จะเห็นตอน PR 11)

## 2026-09-04 (รอบ 13) — PR 8 app: วาง Pet ลง Room ผ่าน Map Editor (SC-PM-05 ฝั่ง UI)

- **ทำอะไร:** zyra-app branch `feat/room-pet-map-editor` (worktree แยก แตกจาก `develop` @ `f6c0523`) — ปิด SC-PM-05 ฝั่ง Map Editor ตาม Figma section 4114:199428 ที่ดึงซ้ำทุก frame (ดู [PetManagement/ux-ui.md § สิ่งที่ Figma มีเพิ่ม](../PetManagement/ux-ui.md))
  - `lib/api/pets.ts` — `RoomPet` / `PlaceRoomPetBody` (มี `replace`) / `UpdateRoomPetBody` / `RoomPetErrorCode` + `listMapPets` / `placeMapPet` / `updateMapPet` / `removeMapPet` → `/api/admin/maps/:mapId/pets` (admin path — นี่คือโค้ด Map Editor ไม่ใช่ member) · `ROOM_PET_NAME_MAX_LENGTH = 30`
  - `lib/pet-placement.ts` — `resolvePetPlacement(zones, tx, ty, tileSize)` กระจก rule ฝั่ง Go: floor anchor → meeting/private ที่ครอบ tile ชนะ (`blocked_by_zone`) → room ที่ครอบ (`ok`) → ไม่มี (`outside_room`) · `canMovePetTo` (ย้ายได้ในห้องเดิมเท่านั้น) · `snapToQuarterTile`
  - `views/admin/workspace-editor/hooks/use-room-pets.ts` — โหลด pet ของชั้นเมื่อ map เปลี่ยน + `place/move/rename/remove` เขียน**ทันที** (ต่างจาก object/zone ที่ buffer ไว้หลัง Save draft — pet broadcast ให้ VO สดทุกครั้ง จึงไม่ต้อง buffer และ Discard ไม่แตะ pet) · replace ลบตัวเดิมออกจาก list local
  - palette `object-library-panel.tsx` — chip "Pet" (`PawPrint`) โผล่เฉพาะเมื่อ hero ส่ง `petTypes` · การ์ด pet type ที่ `active` + `stage_ready` ครบ 4 (`isPlaceablePetType`) · hover preview ตาม Figma object card (80×80 · ชื่อ · "1×1" · แถว 24px ของ pet type อื่น) · drag ส่ง `DragObjectData{objectType: "pet", objectId: petTypeId, 1×1}`
  - canvas `map-editor-canvas.tsx` — `usesFractionalAnchor()` รวม pet เข้ากับ decoration/machine (quarter-tile, ghost กลางเคอร์เซอร์) · prop ใหม่ `petDropValidity` → ghost สีน้ำเงิน `#2DB6FF` (Figma Blue/500) เมื่อวางได้ / แดงเมื่อไม่ได้ · drop ที่ blocked ขึ้น toast `Unable to place pet` แทนข้อความ object เดิม
  - `pet-marker-layer.tsx` — DOM overlay (z 46) วาด marker ทุกตัวจาก `{startX,startY,cellPx}` เดียวกับ zone layer · click = เลือก · pointer-drag = ย้าย (snap quarter-tile, เช็ก `canMovePetTo` ก่อนยิง PATCH, ผิดที่ → toast) · ห้องของ pet ที่เลือก/กำลังลาก highlight น้ำเงิน 10 % · `pointer-events-none` ระหว่างลากการ์ดจาก palette
  - `pet-marker-menu.tsx` (Figma 4114:281993: ชื่อ dbl-click rename ≤ 30 · divider · icon 24 + `Trash2`) · `pet-place-dialog.tsx` (ตั้งชื่อตอนวาง — Figma ไม่มี mockup ใช้ shell เดียวกับ zone dialog, ว่าง = ชื่อ pet type) · `pet-replace-modal.tsx` (Figma 4114:282877 ตรง spec 458px/p-4/gap-6/Cancel ขาว/Replace เขียว)
  - hero — gate `petPlacementEnabled = isPetManagementEnabled() && !userMode && !readOnly && !zoneScope` · โหลด `listPets({statuses:["active"]})` · `handleDrop` แยก branch pet → dialog → `place` → 409 `ZONE_ALREADY_HAS_PET` → Replace modal → `replace: true` · marker menu / dialogs mount ข้าง zone marker menu · เลือก zone/object แล้วเคลียร์ pet selection
  - i18n `AdminWorkspaceEditor` +19 key (en/th) — copy toast/modal ตรง Figma
  - tests: `__tests__/pet-placement.test.ts` 12 · `pets-api-map-pets.test.ts` 7 · `pet-marker-menu.test.tsx` 9 (menu / replace modal / place dialog)
- **verify ถึงไหน:** tsc สะอาด (เหลือ 2 error เดิมใน `pixi-game-scene.test.ts`) · eslint ผ่านทุกไฟล์ที่แตะ · prettier ผ่านไฟล์ใหม่ทั้งหมด (hero / canvas / palette เป็นไฟล์ที่ไม่ผ่าน prettier อยู่ก่อนแล้ว ไม่ format ทั้งไฟล์) · **vitest ทั้ง repo 115 ไฟล์ 1460 เคสผ่าน** · **live-test ใน Browser pane** dev server จาก worktree :3300 ต่อ api PR 6 local :3012 (dev DB) หน้า `/admin/workspace-management/4bac2b15…` (Zyra World, Zone 1 map 83×49): chip Pet โผล่ · การ์ด "Pie" · DnD ลงห้อง "Room Group 4" tile (58,42) → dialog ระบุห้องถูก → Place → POST 200 → marker "Golden" + toast "Golden placed" + ห้อง highlight น้ำเงิน · วางบน tile meeting ที่ซ้อนในห้อง → toast `Unable to place pet` ไม่มี dialog ไม่มี request · วางตัวที่ 2 ห้องเดิม → POST 409 → Replace modal (copy ตรง Figma) → Replace → POST 200 เหลือ marker เดียว "Beta" ตำแหน่งใหม่ · dbl-click rename → PATCH 200 "Buddy" · pointer-drag ไป (60,45) → PATCH 200 ตกถูก tile · ลากไปทับ meeting/private → ไม่ยิง request + toast · Trash → DELETE 200 marker หาย · DB หลังจบ: 4 row soft-deleted, `workspace_usage_count` 0 · console ไม่มี error นอกจาก log 409 ของ browser
  - บั๊กที่ live-test จับได้: pointerup อ่าน `drag` state ค้าง (pointermove เป็น continuous event React ยัง re-render ไม่ทัน) → ย้ายไม่ติดเมื่อ event มาถี่ → เพิ่ม `dragRef` mirror แล้วผ่าน
- **PR:** **[zyra-app #246](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/246)** `feat/room-pet-map-editor` → `develop` (ใหม่ 9 แก้ 7) เปิด 2026-09-04 · **zyra-api #65 merged** `ce62893` (dev deploy อัตโนมัติ) · **PR 7 [zyra-ws #29](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/29)** `feat/room-pet-events` relay `pet_*` 6 type (unit test 3 ไฟล์ `go test ./...` เขียว ยังไม่ live e2e — รอ VO render PR 11)
- **ต่อจากนี้:** merge #246 + #29 เมื่อ CI เขียว → PR 10 member `GET /api/user/workspaces/:id/pets` → PR 11 VO render (ตาม roadmap ที่ user อนุมัติ 2026-09-04: 1 merge → 2 ws → 3 member API → 4 VO render → 5 XP engine → 6 pet AI → 7 notifications)
- **ติดอะไร:** **stage row ใน marker menu (Figma 4387:121093 + modal "Stage change unavailable") ยังไม่ทำ** — ต้องนิยาม "admin เลือก stage" กับ "ทีมเคยถึง stage นั้น" (ต้องมี XP history จาก PR 9) รอ PM · undo/redo ของ editor ไม่ครอบ pet (เขียนทันที) · pet ใช้บน Space Builder (`userMode`) ไม่ได้เพราะ API เป็น admin — ถ้าต้องมีต้องเพิ่ม `/api/user/...` twin · ยังไม่ตอบ: วาง pet ใน Template แล้ว workspace เดิมได้ pet ไหม

## 2026-09-04 (รอบ 12) — PR 6 api: `tb_room_pet` + placement `/api/admin/maps/:mapId/pets` + 4 realtime event

- **ทำอะไร:** zyra-api branch `feat/room-pet-placement` (แตกจาก `develop` @ `3439242` หลัง #63 merge) — ตัวที่บล็อกทุก scenario SC-PET (ไม่มี pet ในห้อง = ไม่มีอะไร render)
  - `migrations/88_room_pet.sql` + `.down.sql` — ตาราง `tb_room_pet` ตาม [db-schema-api-contract.md §4](../PetManagement/db-schema-api-contract.md) + `created_by/updated_by` + index `idx_room_pet_map` / `idx_room_pet_pet_type` (partial `is_deleted = FALSE`) · `uq_room_pet_one_per_zone` ยัง comment (PM ยังไม่เคาะ 1 room = 1 pet) · **apply บน dev DB แล้ว** (16 คอลัมน์ 3 index)
  - `model/room_pet.go` — `RoomPet` (`name` = ชื่อแสดงจริง + `is_custom_name`, join `pet_type_name`/`thumbnail_url`, ไม่มี stage/mood) · request `PlaceRoomPetRequest` / `UpdateRoomPetRequest` (pointer ทุก field) · payload 4 event
  - `service/room_pet_service.go` — `List` / `Get` / `Place` / `Update` / `Remove` · gate: map มีจริง → zone อยู่บน map → anchor อยู่ใน zone (`roomPetPointInZone` = `zoneContainsTile` ฝั่ง FE: floor anchor, tiles JSONB ชนะ rect, `zoneTilePx` 32) → pet type `active` + `stageReadiness` ครบ 4 stage · ชื่อ trim/≤ 30 rune/ว่าง = NULL · place/remove อยู่ใน tx เดียวกับ `refreshPetTypeUsageCount` (`COUNT(DISTINCT workspace)`) · publish `pet_spawned/moved/renamed/removed` ผ่าน `zoneEventPublisher` เดิม best-effort หลัง commit
  - `handler/room_pet_handler.go` — interface แคบ `roomPetPlacementService` + `mapLockVerifier` (ทดสอบได้ไม่ต้องมี DB) · POST/PATCH/DELETE ต้องถือ **workspace lock** (423 `WORKSPACE_LOCKED`) เหมือน objects/zones · HTTP status = body status · 500 ไม่รั่ว error text
  - `pet_service.go` `Delete` → 409 `PET_TYPE_IN_USE` เมื่อยังมี placement สด (F7 ของ PR 1 ปิด) · `router.go` 4 route ใต้ `admin.Group("/maps")` · `main.go` wire + `SetPublisher`
  - tests: `room_pet_handler_test.go` (List / Place 12 เคส / Update 7 / Remove 3 / nil lock) · `room_pet_service_test.go` (point-in-zone rect 9 เคส + tiles list + nil, normalize name 6 เคส รวม Thai 30/31 rune, effective name)
- **verify ถึงไหน:** gofmt สะอาดทุกไฟล์ที่แตะ (main.go มี format เพี้ยนเดิมอยู่ก่อนแล้ว ไม่ได้แตะ) · `go vet` + `go build ./...` ผ่าน · `go test ./internal/handler/ ./internal/service/` ผ่าน · **live-test 20 เคสกับ api local :3012 ต่อ dev DB ผ่านทั้งหมด**: 401 ไม่มี token · 403 member · 423 ไม่มี lock · acquire lock → วางนอก zone 400 · pet type ไม่มี 404 · zone ของ map อื่น 404 · ชื่อ 31 ตัว 400 · วางสำเร็จ anchor 57.5/0.25 ชื่อ "  Golden  " → trim · ลบ pet type "Pie" ระหว่างวาง → **409 PET_TYPE_IN_USE ไม่ถูกลบ** · ย้าย 57,1 + ล้างชื่อ → `name` กลับเป็น "Pie" · ย้ายออก zone 400 · body ว่าง 400 · list 1 → remove → 404 ซ้ำ → list ว่าง · release lock · map ไม่มี 404 — DB หลังจบ: row soft-deleted (`name NULL`, `created_by/updated_by` = admin), `workspace_usage_count` กลับ 0, pet type ยัง active ไม่ถูกลบ, lock ปล่อยแล้ว · **Redis `vo:zone` ได้ครบ 4 event** (`redis-cli SUBSCRIBE`) payload ตรง contract (`pet_renamed.name` = "Pie" หลังล้าง custom)
- **PR:** **[zyra-api #65](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/65)** `feat/room-pet-placement` → `develop` (commit `acaf76d`, ใหม่ 7 แก้ 4) — เปิด 2026-09-04 รอ CI/merge
- **ต่อจากนี้:** commit + PR → develop (dev deploy อัตโนมัติ; migration 88 อยู่บน dev แล้ว **uat/prod ต้องรันเองก่อน deploy**) → PR 7 zyra-ws forward `pet_*` → PR 8 Map Editor palette/drag-drop → PR 10 member `GET /api/user/workspaces/:id/pets` → wire VO
- **PM เคาะเพิ่ม 2026-09-04 (ใส่ใน PR เดียวกัน commit 2):** (1) **1 room = 1 pet บังคับ** → เปิด `uq_room_pet_one_per_zone` ใน migration 88 (re-apply บน dev แล้ว) + pre-check ใน tx → 409 `ZONE_ALREADY_HAS_PET` (unique violation ก็ map เป็น code เดียวกัน รับ race) (2) **วางได้เฉพาะ `zone_type = 'room'`** → 400 `ZONE_NOT_ROOM` (3) **จุดวางห้ามตกใน meeting / private แม้ zone นั้นซ้อนอยู่ใน room** → service ดึง zone ประเภท meeting/private ทั้ง map แล้วเช็ก `roomPetPointInZone` ทุกตัว ทั้งตอน place และ move → 400 `POSITION_BLOCKED_BY_ZONE` · tests เพิ่ม: service `roomPetBlockingZone` 5 เคส + host/blocking types, handler +4 เคส · **live-test รอบ 2 ผ่าน 10/10** กับห้อง `35faaa2a` (room x57-68 y38-48 ที่มี private 8 ห้องซ้อน + meeting 1 ห้อง): วางใน meeting zone 400 ZONE_NOT_ROOM · tile ใน meeting (61,43) และใน private (58,39) 400 BLOCKED · tile ว่าง (58,42) 200 · ตัวที่ 2 ห้องเดิม 409 · ย้ายไป 61.5,43 400 BLOCKED · ย้าย 66,43 200 · remove แล้ววางใหม่ห้องเดิมได้ 200 (index นับเฉพาะ live rows) · cleanup remove
- **ติดอะไร:** PATCH ย้ายข้าม zone ไม่ได้ตาม contract (ต้อง remove + place) — ถ้า UX drag ข้ามห้องต้องเพิ่ม `zone_id` ใน PATCH · ยังไม่ตอบ: วาง pet ใน Workspace Template แล้ว workspace เดิมได้ pet ไหม

## 2026-09-02 (รอบ 11) — member endpoint `GET /api/user/pet-xp-config`

- **ทำอะไร:** branch `feat/room-pet-user-xp-config` ทั้ง 2 repo (แตกจาก `develop`) — endpoint แรกฝั่ง member ของ Room Pet
  - **zyra-api:** `model.PetXPConfigPublic { version, config }` + `PetXPConfigPublicResponse` · `handler/pet_xp_config_user_handler.go` — `PetXPConfigUserHandler` รับ interface แคบ `petXPConfigCurrentReader` (แค่ `GetCurrent`) แล้ว map ตัด `id/is_current/created_by*` และไม่ส่ง `constraints` · 404 `PET_XP_CONFIG_NOT_FOUND` เมื่อยังไม่มี version, 500 `INTERNAL_ERROR` ไม่รั่วข้อความ error · route `user.GET("/pet-xp-config")` ใต้ `UserGuard` · wire ใน `main.go` (reuse `PetXPConfigService` ตัวเดิม ไม่มี SQL ใหม่)
  - `handler/pet_xp_config_user_handler_test.go` — table-driven 3 เคส (200 / 404 / 500) + เคสยืนยันว่า response **ไม่มี** field admin และไม่มีชื่อ/uuid ของ admin ใน body
  - **zyra-app:** `lib/api/pets.ts` — type `PetXPConfigPublic` + `getPetXPConfigForUser()` → `/api/user/pet-xp-config` · `__tests__/pets-api-user-xp.test.ts` 3 เคส (path ไม่ใช่ `/api/admin`, payload เข้า `derivePetStage`/`derivePetProgress`/`buildPetDailyQuests` ได้ตรง ๆ, 404 ไม่ throw)
- **verify ถึงไหน:** Go: gofmt สะอาด · `go vet` + `go build ./...` ผ่าน · `go test ./internal/handler/ ./internal/service/` ผ่านทั้งหมด · **live-test กับ local api ที่ต่อ dev DB** (รันที่ port 3012 เพราะ 3002 มี instance เก่าของ user อยู่): ไม่มี token → 401 · `member-a@zyra.test` → 200 `version 8` (มีคน save version ใหม่ระหว่างวัน) data มีแค่ `config` + `version`, enabled 8 activity, mood 12/48/72 · member เรียก `/api/admin/pet-xp-config` → 403 (guard เดิมทำงาน) · FE: vitest 11/11 (ไฟล์ใหม่ + `pets-api-xp` เดิม), tsc, eslint ผ่าน
- **PR:** ✅ **[zyra-api #64](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/64)** + **[zyra-app #243](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/243)** `feat/room-pet-user-xp-config` → `develop` — **merged 2026-09-02** api `5bf317e` (09:36:22Z) → app `87dfc79` (09:36:35Z) ตามลำดับ · CI เขียวทั้งคู่ · branch ลบแล้ว · dev deploy อัตโนมัติทั้ง 2 service
- **ต่อจากนี้:** commit + PR (api ก่อน app เพราะ app เรียก path ใหม่) → harness/`VOPetPanel` ดึง config จริงจาก endpoint นี้แทน fixture เมื่ออยู่ในหน้าที่ login → เริ่ม component ที่เหลือ (hatch overlay + evolution modal, marker, mood bubble)
- **ติดอะไร:** config v8 บน dev ยังมี `neutral.within_hours = 48` (validation ฝั่ง Go ยังไม่บังคับ `== sad.after_hours`) — `derivePetMood` ไม่อ่านค่านี้จึงไม่กระทบ UI แต่ต้องแก้ตามรายการ PetManagement/spec.md

## 2026-09-02 (รอบ 10) — `lib/sprite-grid.ts` (port จาก #240) + harness ใช้ sprite จริงของ "ปรื๊ด"

- **ทำอะไร:** branch ใหม่ `feat/room-pet-sprite-utils` (จาก `develop` @ `bde39ce`) — user สั่ง cherry-pick sprite utils จาก #240 มาเริ่มก่อน merge
  - `lib/sprite-grid.ts` — port `detectSpriteGridFromPixels` / `getSpriteCrop` จาก `views/admin/pet-management/sprite-preview-utils.ts` ของ #240 (เนื้อเดิม 100 %) มาไว้ที่ `lib/` ตาม rule 09 + เพิ่ม DOM helper `detectSpriteGridFromImage` / `cropSpriteFrameToCanvas` / `loadSpriteImage` และ **`normalizeSpriteGrid()` ใหม่**
  - **บั๊กของแนวทาง #240 ที่ asset จริงเปิดเผย:** alpha-run detection นับ row/column เกินจริงเพราะ sprite มีช่องโปร่งใส**ภายในตัว** (ลำตัวกับขา) — baby Walking detect ได้ 8 rows, adult 5 rows ทั้งที่มี 4 ทิศ → crop "left/right" ได้ช่องว่าง · `normalizeSpriteGrid` รวม run ที่เกิน `direction_rows`/`frame_count` ข้ามช่องว่างเล็กสุด (gap ในตัว sprite แคบกว่า gutter ระหว่างเซลล์เสมอ) · run ที่**น้อยกว่า** metadata ให้เชื่อ detection
  - **ข้อมูลใน DB ไม่ตรง sheet จริง:** egg Wobbling detect ได้ **4 cols × 3 rows** แต่ `tb_pet_animation` เก็บ `frame_count 6 / direction_rows 4` (มาจากค่าที่ admin form ล็อกไว้แล้ว migration 88/89 normalize) → renderer ห้ามเชื่อ metadata อย่างเดียว ต้อง detect จากภาพ · ต้องแจ้ง PetManagement (`frame_count` ต่อ animation ต้องกรอกได้จริงตาม spec 2026-09-01)
  - `__tests__/sprite-grid.test.ts` — 12 เคส (4 เคสเดิมของ #240 + normalize 4 + edge 4)
  - harness: `views/dev/room-pet-preview/real-pet-fixture.ts` (URL R2 ของปรื๊ด — public ไม่ใช่ secret) · `real-pet-sprite-strip.tsx` แสดงเฟรม 0 ทั้ง 4 ทิศของ egg/baby/adult/evolved + GIF ไข่แตก · nameplate icon = เฟรมจริง baby Walking · panel avatar = thumbnail จริง · ทั้งหมดผ่าน `/api/img` (`proxyUrl`)
- **verify:** live บน 3110 — sheet ทั้ง 4 crop ถูกทุกทิศหลัง normalize (baby/adult/evolved 6×4, egg 4×3), GIF 960×960 + thumbnail 166×166 โหลดสำเร็จ, ไม่มี request 4xx/5xx · vitest 12/12 · tsc/eslint/prettier ผ่าน · ระหว่างทาง Turbopack cache `.next/room-pet` เพี้ยน (`[turbopack]_runtime.js` หาย) → ลบแล้วสตาร์ตใหม่หาย
- **PR:** ✅ **[zyra-app #242](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/242)** `feat/room-pet-sprite-utils` → `develop` (2 commit: `lib/sprite-grid.ts` + harness) — **merged 2026-09-02 09:08Z** (merge commit `6492e20`, CI 6/6, branch ลบแล้ว, dev deploy อัตโนมัติ) · หลัง #240 merge: ไฟล์ `sprite-preview-utils.ts` ของ admin ควรเปลี่ยนเป็น re-export จาก `lib/sprite-grid.ts` (เนื้อเดิมเท่ากัน add/add จะไม่ conflict) และให้ preview modal เรียก `normalizeSpriteGrid`
- **ต่อจากนี้:** commit + PR → member endpoint อ่าน XP config → เริ่ม component ที่เหลือ (hatch overlay + evolution modal ใช้ GIF จริง, marker, mood bubble) ตาม decision รอบ 9

## 2026-09-02 (รอบ 9) — PM ตอบ 9 ข้อที่ค้างใน test-plan §6 · ข้อมูล Pet Management จริงมาถึง

- **PM ตัดสิน 9 ข้อ** (บันทึกในแถว ✅ ของ [test-plan.md §6](test-plan.md)): CLASH-01 toast เลื่อนใต้ panel · CLASH-02 overlay รอออกจาก meeting · RT-04 pet ถูกลบระหว่าง GIF → เล่นจบ **และยังโชว์ modal** (soft delete) · LOAD-03 sprite 404 → **ไม่แสดงอะไร** · LOAD-06 stroke 500 → ไม่เล่น + toast error · ZOOM-02 zoom ไกล → จุด `#996ADF` · ZOOM-05 PiP ซ่อน panel/modal/overlay · A11Y-02 Esc ข้าม overlay ได้ · A11Y-04 GIF เล่นปกติ ลด effect
  - 3 ข้อต่างจากที่ผมเสนอ (RT-04, LOAD-03, ZOOM-02) — ไม่มีโค้ดที่ merge แล้วต้องแก้ เพราะยังไม่ได้ทำ overlay / map sprite / compact mode · จุดเดียวที่ควรถาม: `VOPetPanel` avatar เมื่อไม่มีรูปยังใช้ `PawPrint` (เคส null ไม่ใช่ 404) จะให้ว่างเหมือน LOAD-03 ไหม
- **ข้อมูลจริงบน dev DB** (ประเมินแล้ว ยังไม่แก้โค้ด): pet type "ปรื๊ด" (dog, active) 20 animation ครบ 4 stage — PNG 6×4 @8fps (egg @16fps), `Evolution` เป็น GIF ทุก stage, มี thumbnail · XP config v7 (threshold 100/500/2000, เปิด 8/10 activity, `neutral.within_hours` ยัง 48) · `tb_room_pet` ยังไม่มี
  - **ขัด spec:** ข้อมูลมี slot `Idle` ทั้ง 3 stage (20 slot) ทั้งที่ spec 2026-09-01 ถอด Idle → เสนอเก็บ Idle (ตอบคำถาม idle animation) รอ PM
  - PR #240 (ยัง CHANGES_REQUESTED) มี `views/admin/pet-management/sprite-preview-utils.ts` (`detectSpriteGridFromPixels`, `getSpriteCrop`) ที่ VO ต้องใช้ crop เฟรมจริง → หลัง merge ต้องย้ายไป `lib/` (rule 09)
- **ต่อจากนี้:** รอ #240 merge → PR ย้าย sprite utils + harness ใช้ sprite/thumbnail ของปรื๊ดผ่าน `/api/img` → member endpoint อ่าน XP config → อัปเดต spec เรื่อง Idle/neutral 48 → แล้วค่อยเริ่ม overlay/modal/marker/mood bubble ตาม decision ใหม่

## 2026-09-02 (รอบ 8) — dev preview harness + บั๊กที่ preview จับได้

- **ทำอะไร:** หน้า preview รวมทุก component กับ fixture เดียวกับเทส เปิดใน Browser pane แล้ว **render ครบทุกชิ้น** (badge 3 แถว · tooltip 3 variant · Pixi nameplate 3 ตัวอย่างรวมชื่อไทยที่ถูกตัด · VOPetPanel 4 state สลับได้ · minimap compact + expanded มี pet dot ม่วง · รายชื่อ section Setting มี PET · ตาราง derive)
  - `app/dev/room-pet-preview/page.tsx` (thin, `notFound()` นอก development) + `views/dev/room-pet-preview/hero-room-pet-preview.tsx` + `pet-name-tag-preview.tsx` (Pixi Application จริง วาด `makePetNameTag`/`layoutPetNameTag` ×2)
  - **auth bypass เฉพาะ dev:** `proxy.ts` + `components/auth-guard.tsx` ปล่อย `/dev/*` เมื่อ `NODE_ENV === "development"` (ทั้ง 2 ไฟล์ตาม rule 03) — production ไม่กระทบ (path 404 อยู่แล้ว)
  - launch config `zyra-app-room-pet` ใน `<repo-root>/.claude/launch.json` (env `NEXT_PUBLIC_ROOM_PET=true`, `NEXT_DIST_DIR=.next/room-pet`, port 3110) — ไม่ชน dev server ของ user ที่ 3000
- **บั๊กที่ preview จับได้ (unit test ไม่เห็น):** `VOPetPanel` เรียก `useTranslations("AdminShared")` → **`MISSING_MESSAGE` ตอน runtime** เพราะ `i18n/messages-scope.ts` ถอด namespace `Admin*` ออกจากทุก route ที่ไม่ใช่ `/admin` (และ `__tests__/i18n-namespace-split.test.ts` จะ fail ใน CI) → แก้: copy 10 key `xpSource*` เข้า namespace `VirtualOffice` (en+th) และให้ panel อ่านจาก `t("VirtualOffice")` อย่างเดียว · `PET_XP_ACTIVITY_LABEL_KEY` ยังเป็น map เดียว (ชื่อ key เท่ากันทั้ง 2 namespace) · เทส panel mock โยน error ถ้าเรียก namespace อื่น
- **PR:** ✅ **[zyra-app #241](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/241)** `feat/room-pet-ui` → `develop` (4 commit: flag+lib · components · pixi nameplate · harness — user เลือกเก็บ harness ไว้) — **merged 2026-09-02 08:05Z** (merge commit `bde39ce`, CI 6/6 เขียว, branch ลบแล้ว) → dev deploy อัตโนมัติ image `dev-bde39ce` พร้อม `NEXT_PUBLIC_ROOM_PET=true` · docs: **[zyra-doc #4](https://github.com/N2Pluto/zyra-doc/pull/4)** `docs/room-pet-plan` → `main` ยังเปิดอยู่
- **verify ถึงไหน:** live ใน dev server 3110 — console ไม่มี error หลัง reload สะอาด · `vitest` `vo-pet-panel` + `i18n-namespace-split` ผ่าน · tsc/eslint/prettier ผ่าน · ยังไม่ได้รัน `next build`
- **env บน dev (ทำแล้ว 2026-09-02):** ตั้ง GitHub **environment secret** `NEXT_PUBLIC_ROOM_PET=true` บน environment `dev` ของ repo zyra-app (workflow `deploy-gitops.yml` job `deploy` ใช้ `environment: dev|uat|production` → secret แยกต่อ env; `NEXT_PUBLIC_PET` ก็อยู่ระดับ env `dev` เหมือนกัน) · `uat` / `production` **ไม่มี** secret นี้ → build ได้ค่าว่าง = flag ปิด · มีผลกับ image `dev-<sha>` ตัวถัดไปหลัง merge เข้า `develop`
- **ต่อจากนี้:** merge #241 หลัง CI เขียว → รอ dev deploy แล้วเปิด `/workspace/<id>/play` บน dev ตรวจว่า section PET โผล่ใน Setting (ชิ้นเดียวที่ mount อยู่แล้ว) · เก็บ harness ไว้ใช้ตอน wire hero
- **ติดอะไร:** screenshot จาก Browser pane มีแถบดำด้านบนเมื่อ scroll (quirk ของ pane ไม่ใช่แอป — ยืนยันด้วย viewport 1500px เห็นครบ)

## 2026-09-02 (รอบ 7) — unhide section PET ใน Setting → Notifications · **ชุด component ล้วนครบ**

- **ทำอะไร:** `views/user/virtual-office/components/vo-setting-modal.tsx` — section `notifSectionPet` เปลี่ยนจาก `hidden: true` เป็น **`hidden: !isRoomPetEnabled()`** (flag `NEXT_PUBLIC_ROOM_PET` ตัวเดียวกับทุก surface) · export `NOTIFICATION_SECTIONS` / `VISIBLE_NOTIFICATION_SECTIONS` เพื่อเทส · **ไม่แตะ copy** เพราะ `notifPetActivityLabel` "Pet activity" / `notifPetActivityDesc` "Stay updated on your pet's progress, milestones, and evolution." ตรง Figma 4369-309920 อยู่แล้ว (th มีแล้ว) · field `pet_activity` + store + API เดิมใช้ต่อ default ON
  - `__tests__/vo-setting-notifications-pet.test.ts` — 5 เคส (ซ่อนเมื่อ flag off · โผล่ระหว่าง CALENDAR กับ ACTIVITIES เมื่อ on · row เดียว bind `pet_activity` · default true · section อื่นไม่กระทบ) ครอบ test-plan §1.13 ยกเว้น toast หลัง toggle (ยัง "เคาะ" ข้อความ)
- **ถึงไหน:** **component ล้วนที่ไม่ต้องรอ SC-PM-05 ครบทั้ง 6 รายการ** ตาม [spec.md § ความพร้อม](spec.md): `PetStageBadge` · `PetTooltip` · derive helpers · `VOPetPanel` · pet nameplate (Pixi) · `petDots` · Setting PET + flag `NEXT_PUBLIC_ROOM_PET` · ยังไม่มีชิ้นไหน mount ใน `hero-virtual-office.tsx` (ต้องรอ pet data)
- **PR:** ยังไม่เปิด · ยังไม่ commit — รอ user สั่ง (branch `feat/room-pet-ui`, 26 ไฟล์: แก้ 10 / ใหม่ 16)
- **verify ถึงไหน:** `vitest run` 13 ไฟล์ (pet 9 + regression `pixi-game-scene`, `vo-minimap-grouping`, `notification-settings-store`, admin 2) **452/452 ผ่าน** (3 skipped เดิม) · eslint สะอาดทุกไฟล์ที่แตะ · prettier ผ่านทุกไฟล์ที่แตะ · `tsc --noEmit` ไม่มี error ใหม่ (2 error เดิมใน `pixi-game-scene.test.ts` บน develop) · **ยังไม่ live-test** และยังไม่ได้รัน `next build`
- **ต่อจากนี้:** (1) commit + เปิด PR `feat(app): room pet ui components behind NEXT_PUBLIC_ROOM_PET` → develop (2) ตั้ง secret `NEXT_PUBLIC_ROOM_PET=true` เฉพาะ dev เมื่อจะ live-test (3) งานที่ต้องรอ backend: SC-PM-05 → api PR 6 → ws PR 7 → app PR 8 → api PR 9 แล้วค่อย wire hero (click pet → panel, nameplate บน scene, `petDots` จาก pet list, tooltip/marker, hatch overlay + evolution modal ที่ยังไม่ทำ)
- **ติดอะไร:** ไม่มี blocker ในชุดนี้ · ค้างจาก design: badge Adult/Evolved, peer pill vs `#242B32`, quest tile PNG, Pixelony, compact zoom, toast copy (ux-ui.md §11)

## 2026-09-02 (รอบ 6) — `petDots` บน `VOMinimap`

- **ทำอะไร:** เพิ่ม prop `petDots?: PetDot[]` ให้ `VOMinimap` (`views/user/virtual-office/components/vo-minimap.tsx`) — render marker วงกลมต่อ pet ใน `MinimapContent` **ก่อน** `PlayerPill` (อยู่ใต้ avatar) ที่ `tile × scale` · ขนาด `round(dotSize × 6/14)` → 6px ตอน collapsed/compact (dotSize 14), 9px ตอน expanded (22) · `pointer-events-none` · `role="img"` + `title` = ชื่อ pet · **ไม่ถูก group เข้า meeting pill** · gate ด้วย `isRoomPetEnabled()` — flag ปิด = ไม่ render แม้ hero ส่ง dots มา
  - `lib/pet-minimap.ts` (ใหม่) — `PET_MINIMAP_DOT_COLOR = "#996ADF"`, `PET_MINIMAP_DOT_RATIO = 6/14`, `interface PetDot { id, tileX, tileY, name? }`
  - **ปิดคำถาม design ข้อ 3 ได้เอง:** ดึง SVG `Ellipse 4` จาก Figma มาดู = `<circle r="3" fill="#996ADF"/>` (Purple/500) ไม่ใช่ "ชมพู" ตาม ClickUp — อัปเดต ux-ui.md §2.3 / §11 และ test-plan §1.14 แล้ว
  - `__tests__/vo-minimap-pet-dots.test.tsx` — 7 เคส ครอบ test-plan §1.14 ทั้ง 4 แถว + a11y + flag off + สเกลตอน expand
- **ถึงไหน:** prop พร้อมใช้ · hero ยังไม่ส่ง `petDots` (รอ pet data จาก API/ws)
- **PR:** ยังไม่เปิด
- **verify ถึงไหน:** `vitest run` `vo-minimap-pet-dots` + `vo-minimap-grouping` เดิม **11/11 ผ่าน** (grouping เดิมไม่กระทบ) · eslint สะอาด · prettier ผ่าน · tsc ไม่มี error ใหม่ · ยังไม่ commit · ยังไม่ live-test
- **ต่อจากนี้:** unhide section PET ใน Setting (gate ด้วย `isRoomPetEnabled()`) → เปิด PR รวม component ล้วนทั้งหมด
- **ติดอะไร:** ไม่มี

## 2026-09-02 (รอบ 5) — pet nameplate บน Pixi + feature flag `NEXT_PUBLIC_ROOM_PET`

- **ทำอะไร (nameplate):** แตะ engine ครั้งแรกบน `feat/room-pet-ui` — **ไม่แก้ `_updateNameTag` ของ avatar** เพื่อเลี่ยง regression; ทำเป็นคู่ factory/layout แยกที่ใช้ค่าคงที่และ text style เดียวกัน
  - `zyra-engine/pixi-game/constants.ts` — export `NAME_TAG_PEER_BG 0x141420` / `NAME_TAG_PEER_BG_ALPHA 0.88` / `NAME_TAG_GAP_ABOVE_SPRITE 5` (เดิมเป็น literal ใน scene) + `PET_NAME_TAG_*` (icon 16, emoji font 14, progress h 4 radius 90, track white 10 %, gradient `#58D68D → #8FE4B3`)
  - `zyra-engine/pixi-game/types.ts` — `PetNameTag` (bg / icon Sprite / label / emoji Text / progress Graphics + `_prev*`)
  - `zyra-engine/pixi-game/utils.ts` — แยก `nameTagLabelStyle()` ออกจาก `makeNameTag` (avatar ใช้ต่อเหมือนเดิม) · เพิ่ม `makePetNameTag()` + `layoutPetNameTag(tag, {name, emoji, ratio, iconTexture})` คืน `{tagW, tagH}` — geometry ตาม Figma 4215-519137: pad 4 · icon 16 + gap 4 + ชื่อ + gap 4 + emoji 16 · แถวสอง progress h 4 เต็มความกว้างใน · สูง **32** · radius 6 · bg = peer pill · redraw เฉพาะเมื่อ input เปลี่ยน · `truncateName` เหมือน avatar · gradient ผ่าน `FillGradient` (pixi 8.18)
  - `__tests__/pet-name-tag.test.ts` — 13 เคส ครอบ test-plan §1.2 ทั้ง 7 แถว + edge ratio + no-icon/no-emoji + rebuild guard · รัน `pixi-game-scene.test.ts` เดิมคู่กันเพื่อยืนยันว่า `makeNameTag` ไม่พัง
- **ทำอะไร (flag — ตามที่สั่งกลางทาง):** `lib/room-pet-feature.ts` → `isRoomPetEnabled()` อ่าน **`NEXT_PUBLIC_ROOM_PET`** เปิดเฉพาะ string `"true"` · **default = false** (ไม่ตั้ง = ปิด → main/uat/prod ไม่ render และไม่เรียก API pet) · แยกจาก `NEXT_PUBLIC_PET` (admin menu) · `PetStageBadge` / `PetTooltip` / `VOPetPanel` คืน `null` เมื่อปิด (เช็คหลัง hooks ทุกตัว) · `Dockerfile` ARG/ENV + `deploy-gitops.yml` build-arg จาก `secrets.NEXT_PUBLIC_ROOM_PET` (secret ยังไม่มี = ค่าว่าง = ปิด) · test 3 ไฟล์ component เพิ่มเคส "flag off → innerHTML ว่าง" (LOAD-07) และ `__tests__/room-pet-feature.test.ts` 4 เคส
  - ชื่อ flag: user บอก `NEXT_PUBLIC_ROOM` → ใช้ **`NEXT_PUBLIC_ROOM_PET`** ให้สื่อความ (แก้ที่เดียวใน `lib/room-pet-feature.ts` + Dockerfile + workflow ถ้าต้องการชื่อตรงตัว)
  - engine helper (`makePetNameTag` / `layoutPetNameTag`) ไม่ได้ gate ในตัว — scene ต้องเช็ค `isRoomPetEnabled()` ก่อนสร้าง pet entity (ยังไม่มีจุดเรียกในตอนนี้)
- **ถึงไหน:** component ล้วนครบ 4 ชิ้น + engine helper 1 คู่ + flag · ยังไม่มีอะไร mount ใน hero
- **PR:** ยังไม่เปิด
- **verify ถึงไหน:** `vitest run` 9 ไฟล์ (pet 6 + `pixi-game-scene` + admin 2) **432/432 ผ่าน** (3 skipped เดิม) · eslint สะอาด · prettier ผ่านทุกไฟล์ที่แตะ (repo-wide ยังมี 31 ไฟล์เดิมไม่ clean — ไม่เกี่ยว) · tsc ไม่มี error ใหม่ · ยังไม่ commit · ยังไม่ live-test
- **ต่อจากนี้:** `petDots` ของ `VOMinimap` → unhide section PET ใน Setting (gate ด้วย flag เดียวกัน) → เปิด PR รวม component ล้วน → ตั้ง secret `NEXT_PUBLIC_ROOM_PET=true` เฉพาะ dev เมื่อพร้อม live-test
- **ติดอะไร:** pill bg ของ pet ยึด peer `0x141420 @0.88` ไม่ใช่ `#242B32` ของ Figma (ux-ui.md §11 ข้อ 11) · ยังไม่ได้ทำ mood bubble บนแคนวาส (test-plan §1.3) — จะทำพร้อมตอน wire scene เพราะต้องผูกกับ timer ใน `_renderUpdate`

## 2026-09-02 (รอบ 4) — `VOPetPanel` + quest helper

- **ทำอะไร:** component ล้วนตัวที่ 3 บน `feat/room-pet-ui`
  - `lib/pet-xp-activities.ts` (ใหม่, shared admin ↔ member) — `PET_XP_ACTIVITY_ORDER` 10 key · `PET_XP_ACTIVITY_LABEL_KEY` (namespace `AdminShared` `xpSource*` — **ย้ายออกจาก `xp-configuration-panel.tsx`** ให้ admin import จากที่เดียวกัน ตาม rule 09) · `buildPetDailyQuests(activities, doneByActivity)` → เฉพาะ `enabled` ตามลำดับ catalogue, `done` clamp 0..times
  - `views/user/virtual-office/components/vo-pet-panel.tsx` — `VOPetPanel` presentational (Figma 4345-343306 / 4689-572008): shell เดียวกับ `VOProfilePanel` (`w-[320px] rounded-[16px] bg-[#242B32] p-[16px] gap-[16px]`) · header avatar 56 `#FFA8A8` + `next/image` (fallback `PawPrint`) · progress `h-[4px]` track `rgba(26,27,30,0.5)` fill gradient จาก `derivePetProgress` (relative) · ตัวเลข "350/500 XP" สะสม + "150 XP to evolve next stage" · variant MAX (track ขาวเต็ม, "MAX XP", ไม่มีบรรทัด remaining) · stats Mood/Stage (ใช้ `derivePetMood` + `PetStageBadge`) · streak banner `#FF8000` (ซ่อนถ้าไม่มี field) · Daily quest render จาก `quests` prop (tile 50 + `+xp` `font-pixelify-sans` · count `#58D68D` เมื่อครบ · ปุ่ม Complete disabled opacity-50 / Go to + ChevronRight → `onGoTo(activity)`) · config พัง → `—` (LOAD-10) · prop `now` ฉีดเวลาได้ · `useState(() => Date.now())` แทนเรียกในการ render (ผ่าน `react-hooks/purity`)
  - i18n `VirtualOffice.petPanel*` 11 key en+th · quest title reuse `AdminShared.xpSource*`
  - `__tests__/vo-pet-panel.test.tsx` — 27 เคส ครอบ test-plan §1.7 ทุกบล็อก (shell / header / MAX / LOAD-10 / stats / streak / quest) + `buildPetDailyQuests` 4 เคส
- **ถึงไหน:** ครบตาม Figma ที่มี · **ยังไม่ mount ใน hero** (รอ click-pet handler + `getPetStatus`) · quest tile ใช้ lucide แทนภาพประกอบ PNG ที่ยังไม่มี asset
- **PR:** ยังไม่เปิด
- **verify ถึงไหน:** `vitest run` 6 ไฟล์ (pet 4 + admin `pet-creation-wizard` + `xp-configuration`) **108/108 ผ่าน** — ยืนยันว่าการย้าย label map ไม่ทำ admin พัง · eslint สะอาด · prettier ผ่าน · tsc ไม่มี error ใหม่ · ยังไม่ commit · ยังไม่ live-test
- **ต่อจากนี้:** option ใหม่ของ `makeNameTag` (leadingIcon / trailingEmoji / progress) → `petDots` ของ `VOMinimap` → unhide section PET ใน Setting → แล้วค่อยเปิด PR รวม component ล้วน
- **ติดอะไร / ตัดสินไว้:**
  - quest tile ไม่มี PNG ตาม Figma → ใช้ lucide (`LogIn` `Timer` `Clock` `Video` `MessageSquare` `MessagesSquare` `SmilePlus` `Hand`) ไว้ก่อน สลับเป็น asset เมื่อ design ส่ง
  - ตัวเลข `+xp` ใช้ `font-pixelify-sans` (มีใน `app/layout.tsx` แล้ว) แทน Pixelony ของ Figma
  - ตัวเลข header แสดง **xp สะสม / threshold ถัดไป** ตาม Figma แต่ bar คิด relative — สองค่านี้มาจาก `derivePetProgress` ตัวเดียว ไม่ขัดกัน
  - ยังไม่มี prop `top contributors` / ปุ่มลูบหัวใน panel ตาม ClickUp — ยึด Figma (spec.md ข้อ 3)

## 2026-09-02 (รอบ 3) — derive helpers ใน `lib/pet-stage.ts`

- **ทำอะไร:** เพิ่มส่วน "derived values" ต่อท้าย `lib/pet-stage.ts` (branch เดิม) — รับ type จาก `PetXPConfig` ใน `lib/api/pets.ts` ตรง ๆ ไม่ประกาศซ้ำ
  - `isValidPetThresholds()` · `derivePetStage(xp, thresholds)` (สะสม, null เมื่อ config ใช้ไม่ได้) · `nextPetStage()` · `petStageStartXP()`
  - `derivePetProgress(xp, thresholds)` → `PetProgress` แบบ relative ต่อ stage (baby 350 → `250/400 remaining 150 ratio 0.625`) · evolved → `{ isMax: true, prestige }` · **ไม่ divide by zero** คืน null (LOAD-10)
  - `derivePetMood(lastActivityAt, now, moodConfig)` 3 state จาก `last_activity_at` — ขอบ 12h = happy, 72h = neutral, > 72 = sad · timestamp หาย = sad
  - const `PET_MOOD_ORDER` / `PET_MOOD_EMOJI` (🥰 🙂 😢 unicode) / `PET_MOOD_LABEL_KEY` · `DEFAULT_PET_STAGE_THRESHOLDS` / `DEFAULT_PET_MOOD_CONFIG` (fallback แสดงผลเท่านั้น)
  - i18n `VirtualOffice.petMoodHappy / petMoodNeutral / petMoodSad` en+th
  - `__tests__/pet-stage-derive.test.ts` — 28 เคส ครอบ test-plan §1.1 ทั้ง 9 แถว + ขอบ mood ทั้ง 4 จุด + config พัง
- **ถึงไหน:** helper ครบตามที่ `VOPetPanel` / nameplate / modal ต้องใช้
- **PR:** ยังไม่เปิด
- **verify ถึงไหน:** `vitest run` 3 ไฟล์ pet **57/57 ผ่าน** · eslint สะอาด · prettier ผ่าน · tsc ไม่มี error ใหม่ · ยังไม่ commit
- **ต่อจากนี้:** `VOPetPanel` กับ fixture (ใช้ `derivePetProgress` + `derivePetMood` + `PetStageBadge`) → option ใหม่ของ `makeNameTag` → `petDots` ของ `VOMinimap` → unhide section PET
- **ติดอะไร:** ไม่มี — แต่ `PetXPConfig.mood.neutral.within_hours` ไม่ถูกใช้ใน `derivePetMood` โดยตั้งใจ (contract บอกเป็น mirror ของ `sad.after_hours`) ถ้า BE ส่งค่าไม่เท่ากันมา UI จะยึด `sad.after_hours`

## 2026-09-02 (รอบ 2) — `PetTooltip` 3 variant

- **ทำอะไร:** component ล้วนตัวที่ 2 บน branch เดิม `feat/room-pet-ui`
  - `lib/pet-interaction.ts` — `PET_STROKE_SHORTCUT_KEY = "p"` / `PET_STROKE_SHORTCUT_LABEL = "P"` · `PET_HEART_EMOJI` · `PET_XP_MEDAL_EMOJI` (unicode)
  - `views/user/virtual-office/components/pet-tooltip.tsx` — `PetTooltip` (forwardRef) variant `key` ("Press [P] pet", badge `border/text #58D68D` radius 2 w 16) · `emoji` (glyph 16px เดียว default ♥, override ได้สำหรับ mood) · `xp` ("+N XP" `#ECC819` Caption 1/Medium + 🏅) · body `bg-[#1A1B1E] p-[8px] rounded-[8px] gap-[4px] drop-shadow` ตาม Figma nodes 4256-570876 / 4689-564658 / 4276-151515 · หางสามเหลี่ยม 16×8 ด้วย `clip-path` · วางตำแหน่ง screen-space แบบ `PZZoneHover` (`left/top = sx/sy`, translate ให้ปลายหางอยู่ที่ anchor) · `pointer-events-none` เสมอ · export `PET_TOOLTIP_POINTER_HEIGHT`
  - i18n `VirtualOffice.petTooltipPress / petTooltipStroke / petTooltipXp` en+th
  - `__tests__/pet-tooltip.test.tsx` — 13 เคส ครอบ test-plan §1.4 ทั้ง 7 แถว + const + locale format
- **ถึงไหน:** โค้ดครบ · **ยังไม่ mount** (รอ interaction hook / hero wiring)
- **PR:** ยังไม่เปิด (รวมกับ `PetStageBadge`)
- **verify ถึงไหน:** `vitest run` 2 ไฟล์ pet **29/29 ผ่าน** · eslint สะอาด · prettier ผ่าน · `tsc --noEmit` ไม่มี error ใหม่ · **ยังไม่ commit · ยังไม่ live-test**
- **ต่อจากนี้:** derive helpers (stage / mood / relative XP) ใน `lib/pet-stage.ts` → `VOPetPanel` กับ fixture → option ใหม่ของ `makeNameTag` → prop `petDots` ของ `VOMinimap` → unhide section PET ใน Setting
- **ติดอะไร / ตัดสินไว้ (ต้องให้ design รับรู้):**
  - emoji ใช้ **unicode text** ตาม convention เดิมของ VO (`MEETING_EMOJIS`) ไม่ใช่ PNG Apple-style ที่ Figma export — หน้าตาต่างตาม OS
  - หางสามเหลี่ยมเป็น CSS 16×8 ชี้ลงตรง ๆ แทน `Polygon 5` (15.86×14 หมุน 60°) ของ Figma — ใกล้เคียง ไม่เป๊ะ
  - Medal ใน xp variant ใช้ 🏅 unicode (ux-ui.md icon table บอก "ใช้ asset เดิมถ้ามี" — ไม่มีใน `public/`)

## 2026-09-02 — เริ่ม component ล้วน: `PetStageBadge`

- **ทำอะไร:** เริ่มชุด "component ที่ไม่ต้องรอ SC-PM-05" ตัวแรกตาม [spec.md § ความพร้อม](spec.md) — branch `feat/room-pet-ui` (zyra-app, แตกจาก `develop` @ `0393092`)
  - `lib/pet-stage.ts` — const กลาง: `PET_STAGE_ORDER`, `PET_STAGE_NUMBER`, `PET_STAGE_BADGE_COLOR` (hex), `PET_STAGE_BADGE_BG_CLASS` (Tailwind literal ให้ scanner เห็น), `PET_STAGE_LABEL_KEY`, `isPetStageId()`
  - `views/user/virtual-office/components/pet-stage-badge.tsx` — `PetStageBadge` 16×16 radius 4 p-2 + เลข Caption 2/Semi + highlight มุมซ้ายบน (ทำจาก Figma Ellipse 146 ด้วย CSS `blur-[6px]` แทน SVG asset) + label `sm` 14/18 (panel) / `md` 16/22 (modal) · `showLabel=false` → `sr-only`
  - i18n `VirtualOffice.petStage{Egg,Baby,Adult,Evolved}` ทั้ง en/th (th ใช้คำเดียวกับ admin `petUploadStage*`)
  - `__tests__/pet-stage-badge.test.tsx` — 15 เคส ครอบ test-plan §1.6 ทั้ง 4 แถว + sync ของ hex/class map + a11y
- **ถึงไหน:** โค้ดเขียนครบ 4 ไฟล์ · **ยังไม่ได้ mount ที่ไหน** (รอ `VOPetPanel` / `PetEvolutionModal`)
- **PR:** ยังไม่เปิด (ตั้งใจรวม component ล้วนหลายตัวใน PR เดียว)
- **verify ถึงไหน:** `vitest run __tests__/pet-stage-badge.test.tsx` **16/16 ผ่าน** · `eslint` 3 ไฟล์ใหม่สะอาด · `prettier --check` ผ่าน (auto-format 1 ไฟล์) · `tsc --noEmit` ไม่มี error จากไฟล์ใหม่ (มี 2 error เดิมใน `__tests__/pixi-game-scene.test.ts` บน `develop` อยู่ก่อนแล้ว ไม่เกี่ยว) · **ยังไม่ commit · ยังไม่ live-test** เพราะไม่มีที่ mount
- **ต่อจากนี้:** `PetTooltip` 3 variant → derive helpers `lib/pet-stage.ts` (stage/mood/relative XP) → `VOPetPanel` กับ fixture → option ใหม่ของ `makeNameTag` → prop `petDots` ของ `VOMinimap` → unhide section PET ใน Setting
- **ติดอะไร:** สี badge Adult/Evolved ไม่มีใน Figma — ใช้ค่าชั่วคราวจาก ClickUp (เขียว `#58D68D` / ม่วง `#996ADF`) พร้อม comment ใน const · test assert แค่ว่าเป็น hex ไม่ล็อกค่า (ux-ui.md §11 ข้อ 2)
