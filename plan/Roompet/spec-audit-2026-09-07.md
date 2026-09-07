# Room Pet — ตรวจ spec ทีละข้อเทียบโค้ดจริง (2026-09-07)

> ตรวจทุก **Scenario Steps · Acceptance Criteria · Business Logic/Rules** ของ SC-PET-01…08 + ตาราง §4 Realtime/Data ใน [spec.md](spec.md) เทียบกับโค้ดบน `develop` ของ zyra-app / zyra-api / zyra-ws (app `fedc993` · ws `eb7c8d0` · api `b3e89de`) และข้อมูลจริงบน dev DB
> **แทนที่ตาราง "สถานะ implement ต่อ scenario (2026-09-05)" ท้าย spec.md ซึ่งหยุดอยู่ที่รอบ 25** — ตอนนี้งานอยู่รอบ 71
> กฎที่ใช้ตัดสิน: **card ขัดกับ Figma → ยึด Figma** (spec.md §2) · decision ของ user ระหว่างรอบ 26–71 → ยึด decision ล่าสุด (ดู [progress.md](progress.md), [clickup-audit-2026-09-05.md](clickup-audit-2026-09-05.md) D1–D16)

## สรุปตัวเลข

ตรวจ **185 ข้อ**

| ผล | จำนวน | ความหมาย |
|---|---|---|
| ✅ ทำแล้ว | 94 | ตรงตาม card |
| 🔄 ถูกแทนที่ | 31 | Figma หรือ decision ของ user แทนที่ข้อใน card ไปแล้ว — ไม่ใช่งานค้าง |
| 🟡 ทำบางส่วน | 38 | ทำแล้วแต่ไม่ครบตามตัวอักษรใน card |
| ❌ ยังไม่ได้ทำ | 22 | รวมของที่รอ design / รอ PM |

| Scenario | ✅ | 🔄 | 🟡 | ❌ |
|---|---|---|---|---|
| SC-PET-01 ดู Pet บน map | 13 | 3 | 1 | 0 |
| SC-PET-02 AI Movement | 12 | 2 | 10 | 3 |
| SC-PET-03 Interact | 8 | 4 | 4 | 3 |
| SC-PET-04 Egg → Hatch | 10 | 1 | 5 | 3 |
| SC-PET-05 Hatch → Grow → Evolve | 14 | 4 | 5 | 8 |
| SC-PET-06 Pet Status | 10 | 7 | 6 | 0 |
| SC-PET-07 Notification | 12 | 2 | 2 | 2 |
| SC-PET-08 Neglected | 11 | 4 | 3 | 2 |
| §4 Realtime / Data | 4 | 4 | 2 | 1 |

---

## ❌ งานค้างจริง — ต้องตัดสินใจก่อน (PM/design)

| # | เรื่อง | สถานะจริง | ต้องเคาะอะไร |
|---|---|---|---|
| 1 | **`pet_sittable` / นั่งบน object** (SC-PET-02 rules · SC-PET-05 unlock ของ Grow) | ไม่มีคำนี้ในโค้ดสักที่ทั้ง 3 repo · pet นั่งตามเวลา (นิ่ง 8 วิ) ทุกช่องแทน | ต้องเพิ่ม field ใน Object Management (คนละโมดูล กระทบ 4 repo) + เคาะ design 2 ข้อ (progress รอบ 25) |
| 2 | **Feed / ป้อนอาหาร** (SC-PET-03 AC · SC-PET-06 counter · SC-PET-08 recovery) | ไม่มีเลย — ไม่มี endpoint ไม่มีคอลัมน์ `last_fed_at` ไม่มีปุ่ม | ชื่อ card ตัด "ป้อน" ออกแล้วแต่ AC ยังเขียนอยู่ 3 จุด — ยืนยันว่าตัดจริงแล้วให้ PM แก้ card |
| 3 | **ลูบหัวได้ XP ไหม** (card: 5 ครั้ง/วัน) | `xp_play_with_pet` **ปิดอยู่** ใน config v13 และ `times` = 1 · ลูบได้แต่ไม่ได้ XP | เปิดกลับ + ตั้ง `times` เท่าไร (ค่านโยบาย ค้างมาตั้งแต่รอบ 25) |
| 4 | **animation ตอนโต 4–6 วิ / 6–8 วิ** | baby→adult และ adult→evolved ใช้เวลาแค่ **2.1 วิ** (แสงวาบ 0.9 + GIF ปลายทาง 1.2) เพราะไม่มี GIF "ออกจากร่างเดิม" ของ baby/adult · มีแค่ egg→baby ที่ได้ 3.6 วิ | ถ้าอยากได้ตามการ์ดต้องอัป GIF เพิ่มต่อ stage หรือยอมรับ 2.1 วิ |
| 5 | **ใครเห็นจอเต็มตอน pet โต** | ตอนนี้ **สมาชิกห้องเท่านั้น** (user เคาะ 2026-09-07) · คนอื่นได้แค่แถวในกระดิ่ง | card อยากให้ทุกคนใน workspace เห็น และเหตุผลที่ตัด banner ทิ้งคือ "ทุกคนได้ modal อยู่แล้ว" ซึ่งไม่จริงอีกต่อไป — ต้องเคาะว่าจะให้ non-resident เห็นอะไร |
| 6 | **notice animation** (หูตั้ง ตาเบิก ตอนคนเข้าใกล้) | ไม่มี slot รองรับใน 17 slot | เพิ่ม slot หรือตัดออกจาก card |
| 7 | **ความเร็วเดินต่าง stage** (baby ช้า / adult ปกติ) | ทุก stage ใช้ 900 ms/ช่องเท่ากัน | เคาะว่าจะทำไหม |
| 8 | **special animation เฉพาะ Evolve** | slot map ของ baby/adult/evolved เหมือนกันทุกประการ | เคาะว่าจะทำไหม |
| 9 | **streak "Together for N days"** (Figma) | component มีในพาเนลแล้วแต่ **ไม่มีใครส่งค่า `streakDays` เข้าไป** — โชว์เฉพาะหน้า dev preview | ไม่มี field ใน schema ต้องเคาะว่านับจากอะไร |
| 10 | **banner เตือนประจำวันของ Figma** (§8.2 node 4422:228432) | ไม่ได้ทำ — reminder มีแค่แถวในกระดิ่ง | ยึด Figma = ยังค้าง · หรือยืนยันว่าแถวกระดิ่งพอ |

## ❌ งานค้างจริง — แก้ได้เลยไม่ต้องรอใคร

| # | เรื่อง | รายละเอียด |
|---|---|---|
| 11 | **admin เปลี่ยน stage แล้วไม่มี notification / achievement** | `room_pet_service.go` ส่งแต่ event ผ่าน ws ไม่เรียก `notify()` → ไม่มีแถวใน `tb_notification` และไม่บันทึก achievement ขัดกับ rule ของ SC-PET-07 |
| 12 | **sprite บนแผนที่เปลี่ยนก่อน animation จบ** | รูปบน map derive จาก xp จึงสลับทันทีที่ `pet_xp_changed` มาถึง · คนที่เห็น overlay ไม่รู้สึกเพราะถูกบัง แต่คนอื่นเห็นสลับวูบ ขัดกับ AC "เปลี่ยนหลัง animation จบ" ทั้ง SC-PET-04 และ 05 |
| 13 | **tooltip `Press [P] pet` ไม่เคยขึ้นในเกมจริง** | `PetTooltip variant="key"` ถูก render เฉพาะหน้า `/dev/preview/room-pet` → คีย์ลัด P ไม่มีทางรู้ได้เอง |
| 14 | **"+X XP" ไม่มี float/fade** | AC เขียนว่า "float ขึ้นและ fade out" · ตอนนี้แสดงนิ่ง 1.2 วิแล้วสลับเป็นกรอบลูบหัว ไม่มี animation |
| 15 | **mood neutral ไม่ช้าลง** | card บอก neutral = animation ช้าลง · โค้ดลดความเร็ว 0.5× เฉพาะตอน sad |
| 16 | **rate limit 3 วิ มีรูรั่ว** | ตัวเช็คอ่านจาก ledger — ถ้า activity ปิดหรือโควตาห้องหมด ไม่มีแถวถูกเขียน guard จึงไม่ทำงาน (ตอนนี้กันด้วย cooldown 30 นาทีแทน) |
| 17 | **cooldown 30 นาที อ่านนอก transaction** | สองคำขอพร้อมกันเป๊ะ ๆ ผ่านได้ทั้งคู่ |
| 18 | **reminder ประจำวัน dedupe ข้าม workspace** | คนที่มี pet ใน 2 workspace ได้เตือนแค่ที่เดียวต่อวัน |
| 19 | **Top 3 ผู้ดูแล — API ส่งมาแต่ไม่มีใครใช้** | `contributors` อยู่ใน response และมี type ฝั่ง client แต่ไม่ถูก render (Figma แทนด้วย Daily quest) — ถ้าไม่ใช้แล้วควรตัดออกจาก response |
| 20 | **i18n `petGrowthBannerView` ไม่มีที่ใช้** | ตกค้างจาก banner ที่ยกเลิก |
| 21 | **idle "มุมห้อง / จุดโปรด"** | pet พักตรงที่เดินไปถึง ไม่มี logic เลือกมุมห้อง — ไม่เคยมีใครทักตลอด 71 รอบ |

---

## 🔄 ข้อที่ถูกแทนที่แล้ว (ไม่ใช่งานค้าง — card ต้องตามแก้)

| card เขียน | ของจริง | ที่มา |
|---|---|---|
| ชื่อ stage Egg/Hatch/Grow/Evolve | `egg` / `baby` / `adult` / `evolved` | PetManagement + Figma |
| XP reset เป็น 0 ทุก stage | xp สะสมตลอด แสดงผลแบบ relative | spec §จุดที่ขัดกัน ข้อ 5 |
| hover แล้วขึ้น tooltip ชื่อ/stage/XP/mood | ข้อมูลอยู่บน nameplate ถาวร · hover = ขอบเขียว | Figma (ux-ui.md:36) |
| `z-index = OBJECT_Z_INDEX` | y-sort เหมือนตัวละคร tie-break ต่ำกว่าคน 1 ระดับ | รอบ 26 (pet ทับ object ผิด) |
| minimap dot สีชมพู | `#996ADF` ม่วง | Figma node 4215-325070 |
| พัก 3–8 วิ | 4–20 วิ (sad 10–40) | user 2026-09-06 "เหมือนเป็นโรคลมบ้าหมู" |
| A* | BFS 4 ทิศ (ห้ามเดินเฉียง) | user 2026-09-07 |
| หันหน้าหาคนในระยะ 3 ช่อง | สังเกต 3 ช่อง · **หันหน้าเมื่อติดกัน + นิ่ง 1 วิ (เกิด pop)** | user 2026-09-07 |
| หลายคนพร้อมกัน = สุ่ม | คนที่มาถึงก่อนเสมอ | user 2026-09-05 |
| bubble ระยะ 2 ช่อง · เดินผ่านก็ขึ้นเอง 3 วิ | ติดกัน 1 ช่อง + นิ่ง 1 วิ เท่านั้น | user 2026-09-06 |
| ลูบ 5 ครั้ง/วัน/คน | 1 ครั้ง/คน/pet ทุก 30 นาที · โควตา XP เป็นของห้อง | user 2026-09-06 · D3 |
| ♥ particle | กรอบความคิดรูป pet + มือลูบ + หัวใจ | user 2026-09-06 |
| daily key = UTC | `day_key` = **UTC+7** | spec §จุดที่ขัดกัน ข้อ 14 |
| mood 4 state จาก `last_fed_at` + cron ทุกชั่วโมง | 3 state derive จาก `last_activity_at` ตอนอ่าน ไม่มี cron ไม่มีคอลัมน์ | ปิด 2026-09-01 |
| recovery = feed 1 ครั้ง | ลูบ 1 ครั้ง | Feed ไม่มีในสโคป |
| banner HUD 5 วิ + ปุ่ม "ไปดู" ทุก growth event | modal เต็มจอ | Figma |
| Prestige XP สีพิเศษ | บาร์ขาวเต็ม + `MAX XP` | Figma variant 4689:572008 |
| Top 3 ผู้ดูแล + ปุ่มลูบในพาเนล | Daily quest 5 รายการ · ปุ่มลูบอยู่บนตัว pet | Figma |
| เปิดพาเนลจาก HUD icon | คลิกที่ตัว pet เท่านั้น | Figma ไม่มีปุ่มบน HUD |
| `ws:pet:state` / `ws:pet:interact` / `ws:pet:stageChange` | `pet_state` / `pet_xp_changed` / `pet_stage_changed` (payload ต่างจาก card) | spec §จุดที่ขัดกัน ข้อ 11 |
| Redis `pet:position:{room_id}` TTL 5 นาที | `vo:pets:pos:{workspace_id}` TTL 10 นาที | ตั้งใจยืด TTL ให้ reload ช้ายังเจอ |
| Hungry alert | ไม่มี เพราะไม่มี mood hungry | ตามการตัด mood เหลือ 3 state |
| badge baby สีเหลือง | `#2DB6FF` ฟ้า | Figma 4287-179918 · adult/evolved ยังเป็นสีชั่วคราวจาก card (design ยังไม่ตอบ) |

---

## ✅ ยืนยันจากข้อมูลจริงบน dev (2026-09-07)

| สิ่งที่ตรวจ | ผล |
|---|---|
| 1 room = 1 pet | unique index `uq_room_pet_one_per_zone` เปิดอยู่ · pet ที่ยังไม่ลบ 13 ตัวใน 13 zone |
| XP config ที่ใช้อยู่ | v13 · threshold 100/500/2000 · mood 12h/48h/72h · เปิด 5 activity · `xp_play_with_pet` **ปิด** |
| Evolution GIF | pet type หลัก (Pie / POP / Popcorn / test / จอช …) มีครบทุก stage · เหลือ "Pop" ที่ baby ยังไม่มี |
| ledger XP | มี 6 activity ที่จ่ายจริงแล้ว รวม 44 เหตุการณ์ |
| ลูบหัว | `tb_room_pet_stroke` 39 แถว |
| notification | `pet_milestone` 5 · `pet_reminder` 5 แถว (ยังไม่มี `pet_growth` เพราะยังไม่มี pet ตัวไหนข้าม stage หลังติดตั้ง) |
| achievement | ตารางมีแล้วแต่ **0 แถว** — ยังไม่เคยมี pet ข้าม stage บน dev หลังรอบ 25 |
| frame rate | animation ที่ไม่ใช่ไข่ = 6 fps ครบ 185 แถว (mig 95) · ไข่ 16 fps |
| 09:00 ICT cron | ต่อกับ scheduler จริงใน `main.go` (`runPetReminderLoop` + `NextPetReminderAt` UTC+7) |

## หมายเหตุการตรวจ

- ตรวจด้วยการอ่านโค้ดและ query dev DB — **ยังไม่ได้ทดสอบด้วยตาในเบราว์เซอร์** (ติด login เหมือนเดิม) ทุกข้อที่ขึ้น ✅ หมายถึง "โค้ดทำตามนั้น" ไม่ใช่ "เห็นกับตาแล้วว่าถูก"
- แก้เอกสารระหว่างตรวจ: [evolution-flow.md](evolution-flow.md) เขียน adult → evolved = 1,000 XP (ที่ถูกคือ **2,000**) และ GIF scale 3.4×/816px (ที่ถูกคือ **3.2×/768px**) — แก้แล้วในรอบนี้
