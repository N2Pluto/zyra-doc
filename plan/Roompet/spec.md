# Room Pet — Virtual Office (Client Feature) — Spec

> ดึงข้อมูลจาก ClickUp — Space: Zyra World, List: `901614367195`
> Parent Task: [[Feature] Room Pet — Virtual Office](https://app.clickup.com/t/86d3dc92c) (`86d3dc92c`) · tag `client` · status **in progress** · priority normal · ไม่มี assignee · creator Moss Pm
> Subtask: SC-PET-01 ~ 08 ทุกใบ status **pending** · SC-PET-01~05 priority **high** · SC-PET-06~08 priority normal
> Card สร้าง 2026-06-19 · parent แก้ล่าสุด 2026-09-02 · subtask แก้ล่าสุด 2026-08-13 ~ 2026-08-18
> ใน ClickUp **ไม่มี** comment / attachment / checklist / dependency / linked task เลยแม้แต่ใบเดียว — เนื้อหาทั้งหมดอยู่ใน description
>
> **สถานะเอกสาร: implement ครบทั้ง 8 scenario แล้ว 2026-09-04** (ดู [progress.md รอบ 18](progress.md)) — build เขียวทุก repo · live-test ผ่านเฉพาะ XP engine · ยังไม่ได้ review กับ PM
> **ความพร้อม 2026-09-04: พอแล้ว — dependency ครบทั้ง 6 ข้อ** · `tb_room_pet` + placement (api #65) · member list (api #66) · ws relay `pet_*` 6 ตัว (ws #29) · Map Editor drag-drop (app #246) · VO render (app #248) · XP engine + ledger ([api #68](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/68) รอ merge) → ดู [§ความพร้อม](#ความพร้อม--ข้อมูลพอเริ่ม-room-pet-แล้วหรือยัง-ประเมิน-2026-09-02)
> **เหลืออะไร (2026-09-04):** live-test ครบทั้ง 8 scenario บน dev (ต้องตั้ง secret `NEXT_PUBLIC_ROOM_PET=true` ก่อน — ตอนนี้ปิดทุก env) · จ่าย XP ของอีก 9 activity (login/office/meeting/chat) ที่ยังไม่มีคนเรียก `Award()` · Share flow และ pet facing rows (รอ design) · `pet_sittable` บน object (คนละโมดูล)
> **repo ที่กระทบ:** zyra-app (VO client), zyra-api (member API + XP engine), zyra-ws (pet AI + broadcast), zyra-notifications (SC-PET-07)
>
> **เกี่ยวเนื่องกับ [PetManagement](../PetManagement/)** — โมดูลนั้นคือฝั่ง **Admin** (pet type library, sprite, XP config, วาง pet ลงห้อง) ส่วนเอกสารนี้คือฝั่ง **Member/Client** (pet มีชีวิตอยู่ในห้อง VO) ทุก scenario ในนี้ **ขึ้นกับ SC-PM-05 (วาง pet ลงห้อง) ซึ่งยังไม่เริ่ม** — ดูตารางเทียบ + จุดขัดกันใน [§ความเกี่ยวเนื่องกับ PetManagement](#ความเกี่ยวเนื่องกับ-petmanagement)
>
> **ข้อควรระวัง:** card ชุดนี้เขียนก่อน PM เคาะ decision ในฝั่ง PetManagement (2026-08-14 / 08-17 / 09-01) หลายจุดจึงใช้คำศัพท์และตัวเลขคนละชุด (ชื่อ stage, XP source, mood 4 state, XP reset ต่อ stage ฯลฯ) — ส่วน §1–§4 ด้านล่าง**คงเนื้อหาตาม card** ไม่แก้ ส่วนที่ต้อง reconcile รวมไว้ที่ [§จุดที่ขัดกับ PetManagement](#จุดที่ขัดกับ-petmanagement-ต้องเคาะก่อน-implement)

---

## 1. Overview (parent card)

Virtual Pet ประจำ Virtual Office Room ของ Workspace เป็น feature เสริมเพิ่มความสนุกและ engagement ให้ทีม

### Pet Concept

- **1 Room = 1 Pet** ประจำห้องนั้น (ไม่ผูกกับ user คนใดคนหนึ่ง)
- Pet เป็นของทั้ง workspace ทุกคนเลี้ยงด้วยกันได้
- Pet เติบโตจาก: การ active ของ users ในห้อง + การป้อนอาหาร/ดูแล
- Pet มี 4 growth stages: **Egg → Hatch → Grow → Evolve**
- Pet มี animation บน map: เดิน, Idle ในมุมห้อง, นั่งบน object

### Growth System (parent card)

```
Egg      (0–99 XP)     → ไข่อยู่นิ่ง ขยับเล็กน้อย
Hatch    (100–499 XP)  → ฟักออกมา เดินแบบ baby
Grow     (500–1999 XP) → โตขึ้น เดินเร็ว นั่งบน object ได้
Evolve   (2000+ XP)    → รูปแบบสมบูรณ์ มี special animation
```

### XP Sources (parent card)

| Source | XP |
|---|---|
| User login ใน workspace | +1 XP/วัน/user |
| User อยู่ใน Virtual Office 30 นาที | +2 XP |
| User pet/interact กับ pet | +1 XP (max 5 ครั้ง/วัน/user) |
| ทีม online พร้อมกัน 5+ คน | +10 XP bonus |

> ตารางนี้มี 4 แหล่ง — ฝั่ง Admin ([PetManagement SC-PM-04](../PetManagement/spec.md)) เคาะเป็น **10 activities ที่ admin ตั้งค่าได้** แล้ว ดู [§จุดที่ขัดกัน ข้อ 2](#จุดที่ขัดกับ-petmanagement-ต้องเคาะก่อน-implement)

---

## 2. Scenarios

| ID | Scenario | Type | Priority | Status (ClickUp) | Figma node |
|---|---|---|---|---|---|
| [SC-PET-01](https://app.clickup.com/t/86d3dc97w) | ดู Pet บน Virtual Office Map | Happy Path | high | pending | [4206-126170](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4206-126170&t=8eZdSQuhSXsJsB0C-0) |
| [SC-PET-02](https://app.clickup.com/t/86d3dc9h5) | Pet AI Movement — เดิน / Idle | Happy Path | high | pending | [4215-519205](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4215-519205&t=8eZdSQuhSXsJsB0C-0) |
| [SC-PET-03](https://app.clickup.com/t/86d3dc9y0) | Interact (ลูบหัว) | Happy Path | high | pending | [4256-567590](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4256-567590&t=8eZdSQuhSXsJsB0C-0) |
| [SC-PET-04](https://app.clickup.com/t/86d3dca4d) | Pet Growth — Egg → Hatch | Happy Path | high | pending | [4280-151858](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4280-151858&t=8eZdSQuhSXsJsB0C-0) |
| [SC-PET-05](https://app.clickup.com/t/86d3dcach) | Pet Growth — Hatch → Grow → Evolve | Happy Path | high | pending | [4284-171408](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4284-171408&t=m7iXghCnAnmO19mm-0) |
| [SC-PET-06](https://app.clickup.com/t/86d3dcatp) | ดู Pet Status และ XP Progress | Happy Path | normal | pending | [4308-277780](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4308-277780&t=8eZdSQuhSXsJsB0C-0) |
| [SC-PET-07](https://app.clickup.com/t/86d3dcb5j) | Pet Notification — Growth Event | Happy Path | normal | pending | [4354-854173](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4354-854173&t=8eZdSQuhSXsJsB0C-0) |
| [SC-PET-08](https://app.clickup.com/t/86d3dcbhz) | Pet Neglected State | Alternate Path | normal | pending | [4372-310825](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4372-310825&t=m7iXghCnAnmO19mm-0) |

> ชื่อ card จริงของ SC-PET-02 คือ "Pet AI Movement — เดิน / Idle " และ SC-PET-03 คือ "Interact " (ตัด "นั่งบน Object" กับ "(ป้อน / pet)" ที่อยู่ในตารางของ parent ออกแล้ว) — แต่เนื้อหาใน card ยังพูดถึง sittable object และ Feed อยู่ ดู [§จุดที่ขัดกัน ข้อ 3](#จุดที่ขัดกับ-petmanagement-ต้องเคาะก่อน-implement)
> Figma ทุก node อยู่ในไฟล์ [Zyra design — More Organised ver.](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-) — **spec UI ดึงจาก Figma MCP แล้วทั้ง 8 node → [ux-ui.md](ux-ui.md)** (px/hex ตรงจาก design + ผูกกับ component VO เดิมว่า reuse อะไร) · Figma **ใหม่กว่า card** หลายจุด: ไม่มี HUD banner (ใช้ modal เต็มจอ), Pet panel มี Daily quest + streak แทน Top 3/ปุ่มลูบหัว, mood มี 3 emoji, animation เต็มจอเล่นให้เฉพาะคนที่ทำให้ XP เต็ม, ต้องคลิกไข่ก่อน animation เริ่ม — ถ้าขัดกัน **ยึด Figma** แล้วแจ้ง PM แก้ card

---

## 3. รายละเอียดต่อ Scenario (ตาม ClickUp)

### SC-PET-01 · ดู Pet บน Virtual Office Map

**Type:** Happy Path
**Persona:** User ที่เข้า Virtual Office
**Pre-condition:** Room มี Pet อยู่แล้ว (Workspace Admin เลือก pet type แล้ว)

#### Scenario Steps
1. User เข้า Virtual Office — map โหลดเสร็จ
2. Pet sprite ปรากฏบน map ในห้องที่กำหนด
3. Pet แสดง growth stage ปัจจุบัน: Egg / Hatch / Grow / Evolve (sprite ต่างกัน)
4. Pet มีชื่อ label เล็กๆ ด้านบน sprite
5. Pet เคลื่อนไหว AI อัตโนมัติ (SC-PET-02)
6. Hover pet: แสดง tooltip ชื่อ, stage, XP bar

#### Acceptance Criteria
1. Pet sprite แสดงบน Virtual Office map layer เหนือ floor (z-index = `OBJECT_Z_INDEX`)
2. Stage sprite ต่างกัน: Egg = sprite ไข่, Hatch = baby, Grow = medium, Evolve = full form
3. ชื่อ pet label แสดงเหนือ sprite (เหมือน avatar nameplate)
4. Hover pet: tooltip แสดง ชื่อ, stage badge, XP bar (current/next stage XP), mood icon
5. Pet ไม่ block path ของ avatar (collision = walkable)
6. Pet แสดงบน minimap เป็น dot สีพิเศษ (เช่น สีชมพู)
7. ถ้าห้องนั้นไม่มี Pet: ไม่แสดงอะไร (Pet ต้อง assign โดย Workspace Admin, Owner, Admin System ก่อน)

#### Business Logic / Rules
1. Pet เป็น entity บน map คล้าย NPC — มี position (x, y) แต่ไม่ได้รับ input จาก user
2. Pet position sync ผ่าน WebSocket เหมือน avatar แต่ **server-driven** (AI movement)
3. Pet collision = walkable: avatar เดินทับ pet ได้ ไม่ block
4. **1 Room = 1 Pet เท่านั้น**

---

### SC-PET-02 · Pet AI Movement — เดิน / Idle

**Type:** Happy Path
**Persona:** User สังเกต Pet บน map
**Pre-condition:** Pet อยู่บน map, stage ≥ Hatch

#### AI Behavior States

**1. Wander (เดินเตร็ดรอบๆ)**
- Pet เดินไปยังจุดสุ่มภายใน room boundary
- รอ 3–8 วินาทีที่จุดหมาย แล้วเลือกจุดใหม่
- ใช้ pathfinding A\* หลีกเลี่ยง collision tiles
- ความถี่: 50% ของเวลาทั้งหมด
- Walk animation 4 direction (เหมือน avatar)

**2. Idle (อยู่นิ่งในมุมห้อง)**
- Pet หยุดอยู่ที่มุมห้องหรือจุด favorite
- เล่น idle animation loop: หาว/เงย/กระดิก
- ความถี่: 50% ของเวลาทั้งหมด
- Egg stage: อยู่นิ่งตลอด เฉพาะ wobble animation

**3. React to Nearby Avatar**
- เมื่อ avatar เข้ามาใกล้ pet (radius **3 tiles**): pet หันหน้าไปหา avatar
- เล่น "notice" animation (หูตั้ง, ตาเบิกกว้าง)
- ถ้า avatar อยู่นิ่ง > 3 วินาที: pet เดินเข้าหา avatar 1 tile — ถ้ามีหลายคนเข้าหาพร้อมกัน เลือก **random** ไม่ใช่คนที่มาก่อน

#### Acceptance Criteria
- Egg stage: wobble animation เท่านั้น ไม่เดิน
- Hatch stage: เดิน wander ช้า + idle animation + special animations
- Grow stage: เดิน wander + idle + special animations
- Evolve stage: ทุก behavior + special animations
- Pet ไม่เดินออกนอก room boundary
- Pet ไม่เดินทับ collision tiles
- React to avatar: หันหน้าหา + เดินเข้าหาถ้า avatar หยุดนิ่ง
- AI state transition smooth ไม่กระตุก

#### Business Logic / Rules
- AI movement ทำงาน **server-side** เพื่อ sync ทุก client พร้อมกัน
- Server broadcast `ws:pet:state` ทุก **200ms ขณะ moving**, ทุก **2s ขณะ idle**
- Pet position เก็บ Redis: `pet:position:{room_id}` TTL 5 นาที
- Sittable objects: ตรวจจาก Objects layer ที่มี property `pet_sittable: true`
- AI หยุดทำงานเมื่อไม่มี user อยู่ในห้อง > 5 นาที (ประหยัด server)

---

### SC-PET-03 · Interact

**Type:** Happy Path
**Persona:** User ที่อยู่ในห้องที่มี Pet
**Pre-condition:** User อยู่ใน Virtual Office, Pet อยู่ใน room เดียวกัน

#### Scenario Steps

**Pet / Stroke (ลูบหัว)**
1. User กด 🤚 Pet หรือ shortcut **P**
2. Pet เล่น happy animation: หยุดนิ่ง, ตาหรี่, หางกระดิก
3. XP +1
4. Heart particle แสดงเหนือ pet "♥"
5. Mood เปลี่ยนเป็น happy ถ้าเป็น neutral/hungry

**React บน Map**
- ถ้า pet นั่ง: user ต้องเดินเข้าไปใกล้ pet ก่อน interaction bubble แสดง
- ถ้า pet เดินผ่านมา: interaction bubble แสดงอัตโนมัติ 3 วินาที

#### Acceptance Criteria
- Interaction bubble แสดงเมื่อ avatar อยู่ใน radius **2 tiles**
- **Feed**: daily limit 3 ครั้ง/user/วัน — แสดง "X/3 ครั้งวันนี้"
- **Pet/Stroke**: daily limit 5 ครั้ง/user/วัน
- XP animation: "+X XP ✨" float ขึ้นและ fade out
- Happy animation: heart particles 🫶
- All interactions broadcast ให้ทุกคนใน room เห็นพร้อมกัน
- Rate limit: 1 action ทุก 3 วินาที (ป้องกัน spam click)
- Mood indicator บน pet tooltip อัปเดตทันที

#### Business Logic / Rules
- Daily limit นับต่อ `user_id` + `pet_id` + **UTC date**
- XP update: atomic increment ใน DB ป้องกัน race condition
- Interaction broadcast: `ws:pet:interact { pet_id, user_id, action, new_xp, mood }`

> card ตัดคำว่า "(ป้อน / pet)" ออกจากชื่อแล้ว และ Scenario Steps เหลือแค่ Pet/Stroke — แต่ Acceptance Criteria ยังมีบรรทัด **Feed 3 ครั้ง/วัน** และ SC-PET-06/08 ยังอ้าง Feed อยู่ → ต้องเคาะว่า Feed ยังอยู่ในสโคปไหม ([ข้อ 3](#จุดที่ขัดกับ-petmanagement-ต้องเคาะก่อน-implement))

---

### SC-PET-04 · Pet Growth — Egg → Hatch

**Type:** Happy Path
**Persona:** User ที่ดู Pet ฟัก
**Pre-condition:** Pet อยู่ใน stage Egg, XP ถึง 100

#### Scenario Steps
1. Pet accumulate XP จาก user interactions และ team activity
2. XP ถึง 100 → trigger hatch event
3. **Hatch animation** เล่นบน map:
   - ไข่เริ่มสั่น (wobble เร็วขึ้น)
   - รอยแตกปรากฏบน sprite
   - ไข่แตก — baby pet โผล่ออกมา (particle effect + stars ✨)
   - Baby pet เล่น "born" animation: ลืมตา, ขยับ, ส่งเสียง (sound effect optional)
4. Stage เปลี่ยนเป็น Hatch ทันที
5. Broadcast hatch event ให้ทุกคนใน room
6. Banner แสดงบน HUD ของทุกคน: "🥚 [ชื่อ pet] ฟักแล้ว! ยินดีด้วย! 🎉" — **เฉพาะ Active Status และต้องไม่อยู่ใน Bubble**

#### Acceptance Criteria
- Hatch animation: Egg wobble → crack sprite → explosion particle → baby pet appear
- Animation ใช้เวลา **3–5 วินาที** ก่อน stage switch
- Banner HUD: แสดงบน Virtual Office ทุกคนที่ online ใน workspace นั้น
- In-app notification: ส่งให้ทุก workspace member (ทั้ง online และ offline)
- Stage sprite เปลี่ยนทันทีหลัง animation จบ
- XP bar reset เป็น **0/400** (XP ที่ต้องการถึง Grow)
- Achievement badge: "🐣 First Hatch!" สำหรับ user ที่ป้อนอาหาร XP trigger ตัวสุดท้าย (**ยังไม่แสดง เก็บ logs ไว้**)

#### Business Logic / Rules
- Hatch trigger: server-side เมื่อ `pet.xp >= 100` และ `pet.stage = egg`
- Animation event: server broadcast `ws:pet:stageChange { stage: "hatch", animation: "hatch" }`
- Client play animation แล้วค่อย switch sprite (ไม่ switch ทันที)
- XP หลัง hatch: **reset เป็น 0** นับใหม่สำหรับ Grow stage
- Notification: เก็บใน Notifications table เหมือน SC-CHAT-10

---

### SC-PET-05 · Pet Growth — Hatch → Grow → Evolve

**Type:** Happy Path
**Persona:** Team ที่เลี้ยง Pet มาสักพัก

#### Growth Stages Summary

| Stage | XP Required | Sprite | Behavior |
|---|---|---|---|
| Egg | 0–99 | 🥚 ไข่ | wobble เท่านั้น |
| Hatch | 100–499 | 🐣 baby | เดินช้า, idle |
| Grow | 500–1999 | 🐱 medium | เดิน, นั่ง object, react |
| Evolve | 2000+ | 🐉 full | ทุก behavior + special |

#### Hatch → Grow (500 XP)
1. XP ถึง 500 → trigger grow animation
2. **Grow animation**: baby pet เปล่งแสง → โตขึ้น (scale animation) → form ใหม่
3. Banner: "🌱 [ชื่อ pet] เติบโตแล้ว! ตอนนี้ [ชื่อ] ใหญ่ขึ้นแล้ว 🎊"
4. Sprite เปลี่ยนเป็น medium size
5. Unlock behavior: นั่งบน sittable objects ได้
6. XP reset เป็น **0/1500** (XP ที่ต้องการถึง Evolve)

#### Grow → Evolve (2000 XP total / 1500 หลัง Grow)
1. XP ถึง threshold → trigger evolve animation
2. **Evolve animation**: light pillar → transformation → new form reveal พร้อม dramatic effect
3. Banner: "✨ [ชื่อ pet] Evolve แล้ว! ยินดีด้วยกับทีม! 🎆"
4. Sprite เปลี่ยนเป็น full evolved form
5. Unlock: special idle animations, special reactions
6. Achievement: "🏆 Fully Evolved!" ให้ทั้ง workspace

#### Post-Evolve
- Pet หยุดเติบโต (max stage)
- XP ยังสะสมได้ → แสดงเป็น **"Prestige XP"**
- Prestige XP: unlock cosmetic เช่น ribbon, hat, glow effect (**future feature**)

#### Acceptance Criteria
- Grow animation: scale up + particle burst เล่น **4–6 วินาที**
- Evolve animation: dramatic light pillar + transform เล่น **6–8 วินาที**
- ทุก growth event: banner HUD + in-app notification ทุก workspace member
- Sprite เปลี่ยนหลัง animation จบ (ไม่ก่อน)
- XP bar reset หลังทุก growth stage
- Post-Evolve: XP bar แสดง "Prestige" ด้วยสีพิเศษ
- Achievement unlock สำหรับ stage milestones

#### Business Logic / Rules
- Growth trigger: server-side check ทุกครั้งที่ XP อัปเดต
- Growth event broadcast: `ws:pet:stageChange` เหมือน SC-PET-04
- Animation เล่น client-side แต่ stage switch **รอ server confirm**
- Prestige XP: ไม่ trigger stage change แต่เก็บไว้สำหรับ future features

---

### SC-PET-06 · ดู Pet Status และ XP Progress

**Type:** Happy Path
**Persona:** User ที่อยากรู้ความคืบหน้าของ Pet
**Pre-condition:** ห้องมี Pet

#### Scenario Steps
1. User คลิกที่ Pet บน map หรือกด Pet icon บน HUD
2. เปิด Pet Status Panel (sidebar หรือ modal)
3. แสดงข้อมูลครบ: รูป, ชื่อ, stage, mood, XP progress

#### Pet Status Panel Layout (จาก card)

```
┌─────────────────────────────────┐
│  🐱  Mochi                      │
│  Stage: Grow  •  Mood: 😊 Happy │
├─────────────────────────────────┤
│  XP Progress                    │
│  ████████░░░░  480 / 1500       │
│  "เหลืออีก 1,020 XP ถึง Evolve"    │
├─────────────────────────────────┤
│  วันนี้                            │
│  🤚 ลูบหัวแล้ว 3/5 ครั้ง             │
├─────────────────────────────────┤
│  ผู้ดูแลวันนี้ (Top 3)                │
│  1. 👤 Alice   +12 XP           │
│  2. 👤 Bob     +8 XP            │
│  3. 👤 Carol   +6 XP            │
├─────────────────────────────────┤
│            [🤚 ลูบหัว]            │
└─────────────────────────────────┘
```

#### Acceptance Criteria
- Pet Status Panel เปิดได้จากคลิก Pet บน map หรือ HUD icon
- XP bar แสดง progress สู่ next stage พร้อม label "เหลืออีก X XP"
- Mood indicator: 😊 Happy, 😐 Neutral, 😮‍💨 Hungry, 😢 Sad (**4 state**)
- Daily interaction counter: Feed X/3, Stroke X/5 (ของ user คนนั้น)
- Top contributors วันนี้: top 3 users ที่ให้ XP มากสุด
- Feed/Stroke button ใน panel: disabled ถ้าครบ limit หรือ pet อยู่ไกลเกิน (ทำได้แต่ไม่ +XP)
- Stage badge สีตาม stage: Egg=เทา, Hatch=เหลือง, Grow=เขียว, Evolve=ม่วง

#### Business Logic / Rules
- Top contributors: นับ XP ที่ user contribute วันนี้ (**UTC date**)
- Mood แสดงตาม `last_fed_at`: < 12h = happy, 12–24h = neutral, 24–48h = hungry, > 48h = sad
- XP "เหลืออีก": `next_stage_xp - current_xp`

---

### SC-PET-07 · Pet Notification — Growth Event

**Type:** Happy Path
**Persona:** Workspace Member ทุกคน

#### Notification Types

**1. Stage Change (Hatch / Grow / Evolve)**
- Trigger: pet stage เปลี่ยน
- Channel: In-app notification + Banner บน Virtual Office
- Message: "🥚 [ชื่อ pet] ฟักแล้ว! มาดูกันที่ห้อง [ชื่อห้อง]"
- Action: กด notification → navigate ไปห้องนั้น

**2. XP Milestone**
- Trigger: XP ถึง 50%, 75%, 90% ของ next stage
- Channel: In-app notification (ไม่มี banner — ไม่รบกวน)
- Message: "🌟 [ชื่อ pet] ใกล้จะ Evolve แล้ว! เหลืออีก 150 XP เท่านั้น"

**3. Daily Reminder**
- Trigger: user login แต่ยังไม่ได้ interact กับ pet วันนี้ (ถ้า pet มีอยู่)
- Channel: In-app (ครั้งเดียวต่อวัน)
- Message: "🐾 [ชื่อ pet] รอให้คุณมาเยี่ยมอยู่นะ!"

#### Acceptance Criteria
- Stage change notification: ส่งทุก member ของ workspace (online + offline)
- Banner on Virtual Office: แสดง **5 วินาที** พร้อมปุ่ม "ไปดู"
- XP milestone: เฉพาะ user ที่อยู่ใน workspace นั้น
- **Hungry alert**: ส่งครั้งเดียวต่อ mood cycle (ไม่ spam ทุกชั่วโมง) — *card เขียน AC นี้ไว้แต่ไม่มีอยู่ในรายการ Notification Types ด้านบน*
- Daily reminder: ส่งได้ 1 ครั้ง/วัน/user เท่านั้น
- User ปิด notification ได้ใน notification settings

#### Business Logic / Rules
- Stage change: broadcast ผ่าน WS + เก็บ notification record
- XP milestone: check ทุกครั้งที่ XP update
- Daily reminder: **cron job 9:00 ICT** ทุกวัน

---

### SC-PET-08 · Pet Neglected State

**Type:** Alternate Path
**Persona:** Pet ที่ถูกทอดทิ้ง
**Pre-condition:** Pet ไม่ได้ลูบหัวนานเกินกำหนด

#### Mood Decay System (ตาม card — 3 state)

| Condition | Mood | Visual |
|---|---|---|
| ลูบหัวภายใน 12 ชั่วโมง | Happy 😊 | ปกติ |
| ไม่ได้ลูบหัว 12–48 ชั่วโมง | Neutral 😐 | animation ช้าลง |
| ไม่ได้ลูบหัว > 72 ชั่วโมง | Sad 😢 | sad sprite, นอนซม, ไม่ react user |

> ช่วง **48–72 ชม.** ไม่ตกอยู่ใน state ใดเลยใน card นี้ — ฝั่ง PetManagement ปิดช่องว่างนี้แล้ว (Neutral ยืดถึง 72 ชม.) ดู [ข้อ 4](#จุดที่ขัดกับ-petmanagement-ต้องเคาะก่อน-implement)

#### Scenario Steps — Sad State
1. Mood เปลี่ยนเป็น Sad
2. Pet sprite: ตาเศร้า, ใบหน้าบูดบึ้ง, นอนซม
3. Pet หยุดเดิน wander — นอนอยู่กับที่
4. XP gain จาก team activity ลดลง **50%** ขณะ mood = sad

#### Recovery
1. Recovery animation: pet ลุกขึ้น, ส่ายหัว, เล่น happy animation
2. Mood กลับ Happy ทันที
3. XP gain กลับปกติ

#### Acceptance Criteria
- Mood decay: อัปเดต mood โดย **cron job ทุก 1 ชั่วโมง**
- Sad: pet นอนซม, ไม่ react user
- XP penalty: mood=sad → XP gain จาก team activity ลด 50%
- Recovery: **feed 1 ครั้ง** → mood กลับ Happy ทันที
- Recovery animation: happy burst + ลุกขึ้น

#### Business Logic / Rules
- Mood decay ไม่ลด XP ที่สะสมไว้แล้ว — แค่ลด rate ของ XP gain ใหม่
- **ไม่มี "Pet ตาย"** — Sad เป็น worst state เสมอ
- Mood check: cron job ทุก 1 ชั่วโมง `UPDATE mood` ตาม `last_fed_at`

---

## 4. Realtime / Data ที่ card ระบุ (รวมจากทุกใบ)

| สิ่งที่ card ระบุ | ใบที่มา | รายละเอียด |
|---|---|---|
| `ws:pet:state` | SC-PET-02 | server → client ทุก 200ms (moving) / 2s (idle) |
| `ws:pet:interact` | SC-PET-03 | `{ pet_id, user_id, action, new_xp, mood }` broadcast ทั้งห้อง |
| `ws:pet:stageChange` | SC-PET-04/05 | `{ stage, animation }` — client เล่น animation ก่อนแล้วค่อย switch sprite |
| Redis `pet:position:{room_id}` | SC-PET-02 | TTL 5 นาที |
| Object property `pet_sittable: true` | SC-PET-02 | ใช้เลือก object ที่ pet นั่งได้ |
| Daily limit key | SC-PET-03 | `user_id + pet_id + UTC date` |
| `last_fed_at` | SC-PET-06/08 | ตัวกำหนด mood |
| Cron ทุก 1 ชม. | SC-PET-08 | UPDATE mood |
| Cron 9:00 ICT | SC-PET-07 | Daily reminder |
| Notifications table | SC-PET-04/07 | pattern เดียวกับ SC-CHAT-10 |
| Achievement log | SC-PET-04/05 | "First Hatch!", "Fully Evolved!" — เก็บ log ยังไม่แสดง |

---

## ความเกี่ยวเนื่องกับ PetManagement

[PetManagement](../PetManagement/) = ฝั่ง Admin (SC-PM-01 ~ 07) · เอกสารนี้ = ฝั่ง Member (SC-PET-01 ~ 08) — ทั้งสองใช้ข้อมูลชุดเดียวกัน:

| สิ่งที่ Member ใช้ | มาจาก Admin (PetManagement) | สถานะฝั่ง Admin (2026-08-31) |
|---|---|---|
| Sprite ต่อ stage / animation slot ที่ pet เล่น | SC-PM-03 — `tb_pet_animation` (slot `Wobbling` `Walking` `Sitting` `Happy` `Sad` `Evolution`) | เสร็จบางส่วน (FE ล็อก metadata) |
| Threshold ที่ทำให้ stage เปลี่ยน + XP ต่อ activity + mood rate | SC-PM-04 — `tb_pet_xp_config` (version history) | เสร็จ แต่**ยังไม่มี consumer** ที่จ่าย XP จริง |
| Pet instance ในห้อง (`tb_room_pet`: ตำแหน่ง, ชื่อ, xp) | SC-PM-05 — วางผ่าน Map Editor drag-drop | **api เสร็จ 2026-09-04** (migration 88 + `/api/admin/maps/:mapId/pets` + 4 event, branch `feat/room-pet-placement` ยังไม่ merge) · **Map Editor UI (PR 8) เสร็จ 2026-09-04** branch `feat/room-pet-map-editor` ยังไม่ merge · ws forward (PR 7) ยังไม่เริ่ม |
| Realtime bus ที่ pet event วิ่ง | `ZoneEventPublisher` → Redis `vo:zone` → zyra-ws | มีอยู่แล้ว แต่ zyra-ws ยังไม่รู้จัก `pet_*` |
| Member endpoint | `GET /api/user/workspaces/:id/pets` · `POST …/pets/:petId/play` (design แล้ว) | ยังไม่มีโค้ด |
| Feature flag | admin: `NEXT_PUBLIC_PET` (ปิดแค่เมนู) · **member: `NEXT_PUBLIC_ROOM_PET`** (`lib/room-pet-feature.ts`, เพิ่ม 2026-09-02) — **default false** เปิดเฉพาะ `"true"`; ทุก component Room Pet คืน null และห้ามเรียก API เมื่อปิด · Dockerfile + `deploy-gitops.yml` รับจาก `secrets.NEXT_PUBLIC_ROOM_PET` (ยังไม่ตั้ง = ปิดทุก env) | ปิดอยู่ทั้งคู่ |

**ลำดับที่ implement ได้จริง:** SC-PM-05 (placement + `tb_room_pet` + `pet_spawned/...`) → PR 7 ใน [db-schema-api-contract.md § แบ่งเป็น PR](../PetManagement/db-schema-api-contract.md) (zyra-ws forward) → PR 9 (XP engine + ledger) → จากนั้นค่อยเริ่ม SC-PET-01 ได้ — ก่อนหน้านั้นไม่มี pet ในห้องให้ render

### จุดที่ขัดกับ PetManagement (ต้องเคาะก่อน implement)

card ชุด Room Pet เขียนก่อนที่ PM จะเคาะ decision ฝั่ง Admin — จุดด้านล่างคือของที่ **ใช้คนละชุดกัน** ถ้าไม่เคาะ FE/BE จะทำคนละแบบ

| # | เรื่อง | Room Pet card (เอกสารนี้) | PetManagement (เคาะแล้ว) | ต้องทำ |
|---|---|---|---|---|
| 1 | **ชื่อ stage** | Egg / Hatch / Grow / Evolve | `egg` / `baby` / `adult` / `evolved` (ยึด Figma, ปิด 2026-08-14) — parent card ของ PetManagement ก็ยังเขียนชื่อเก่าอยู่ | ใช้ชื่อฝั่ง PetManagement ในโค้ด/API ทั้งหมด · ข้อความ UI ("ฟักแล้ว" ฯลฯ) ใช้ตาม card ได้ |
| 2 | **XP sources** | 4 แหล่ง fix (login +1, VO 30 นาที +2, interact +1 max 5, ทีม 5+ คน +10) | **10 activities** ที่ admin ตั้งค่าได้ (`xp_login_per_day`, `xp_office_10min/30min`, `xp_team_meeting*`, `xp_*_message_fo_day`, `xp_play_with_pet`) + `times`/วัน | ตารางใน parent card ตกไป — ใช้ config จริง · **"ทีม online พร้อมกัน 5+ คน +10" ไม่มีใน 10 activities** ต้องถาม PM ว่าตัดหรือเพิ่ม |
| 3 | **Interaction ชนิดไหน** | Stroke 🤚 / shortcut P (5 ครั้ง/วัน) + **Feed** (3 ครั้ง/วัน) ใน AC ของ 03/06 และ Recovery ของ 08 — แต่ชื่อ card ตัด "ป้อน" ออกแล้ว | มีแค่ `xp_play_with_pet` (default 1 XP) และคำถามค้าง #5 "เล่นกับ pet คือ interaction แบบไหน" | card นี้ตอบ #5 ได้ = Stroke · ต้องเคาะว่า **Feed ยังอยู่ไหม** ถ้าอยู่ต้องเป็น activity ที่ 11 หรือ share `xp_play_with_pet` |
| 4 | **Mood** | SC-PET-06: **4 state** (Happy/Neutral/Hungry/Sad ที่ 12/24/48 ชม.) · SC-PET-08: **3 state** (12 / 12–48 / >72 — มีช่องว่าง 48–72) · อิง `last_fed_at` · cron ทุก 1 ชม. UPDATE | **3 state**: Happy ≤12 ชม. (150%), Neutral 12–72 (100%), Sad >72 (50%) · derive จาก `last_activity_at` ตอนอ่าน **ไม่เก็บคอลัมน์ ไม่มี cron** · ปิด 2026-09-01 | ยึด 3 state + derived ของ PetManagement · **ตัด "Hungry" ออกจาก SC-PET-06** (หรือ PM ขอเพิ่มเป็น 4 state ทั้งสองฝั่ง) · "Hungry alert" ใน SC-PET-07 AC ก็จะหายตาม |
| 5 | **XP ต่อ stage: reset หรือสะสม** | reset เป็น 0 หลังทุก stage (0/400 → 0/1500) | **สะสม (cumulative)** threshold 100/500/2000 · stage derive จาก `xp` ตรง ๆ · ถ้า admin แก้ threshold pet เปลี่ยน stage ทันที | เก็บ xp สะสมตาม PetManagement · XP bar ใน UI **แสดงแบบ relative** (`xp - threshold_ปัจจุบัน` / `threshold_ถัดไป - threshold_ปัจจุบัน`) ให้ได้ตัวเลข 0/400, 0/1500 ตาม card โดยไม่ต้อง reset จริง |
| 6 | **stage เก็บหรือ derive** | `pet.stage = egg` เป็นคอลัมน์ · trigger เมื่อ `xp >= 100 AND stage = egg` | ไม่เก็บ `stage` · ใช้ `last_seen_stage` ตรวจ transition แล้ว broadcast `pet_stage_changed` (idempotent) | ยึด PetManagement — ได้ผลเดียวกับ card |
| 7 | **XP penalty ตอน Sad** | ลดเฉพาะ "XP จาก team activity" 50% | mood multiplier คูณ **ทุก** activity (Happy 150% / Neutral 100% / Sad 50%) รวม `xp_play_with_pet` | ถามว่า Stroke ตอน Sad ได้ 50% ด้วยไหม — card สื่อว่า interaction ยังได้เต็ม (เพื่อให้ recovery จูงใจ) |
| 8 | **Recovery ทันที** | Stroke/feed 1 ครั้ง → Happy ทันที | mood = `NOW() - last_activity_at` → interaction ที่ update `last_activity_at` ก็ทำให้ Happy ทันทีอยู่แล้ว | ตรงกัน — แต่ต้องกำหนดว่า **activity ไหนบ้าง** ที่ update `last_activity_at` (เฉพาะ interaction? หรือ login/office ด้วย — ถ้าด้วย pet จะแทบไม่มีวัน Sad ในทีมที่ active) |
| 9 | **1 Room = 1 Pet** | ระบุชัดทั้ง parent และ SC-PET-01 | **ยังไม่เคาะ** — default ปัจจุบันวางได้หลายตัว (`uq_room_pet_one_per_zone` ปิดไว้) | card นี้เป็นคำตอบของคำถามค้าง #1 ใน PetManagement → **เปิด unique index + implement modal "Replace this pet" ใน Map Editor** ก่อน merge PR 6/8 |
| 10 | ✅ **ปิดแล้ว 2026-09-04** — **ใครวาง pet / persona** | "Workspace Admin เลือก pet type" · AC7: Workspace Admin, Owner, Admin System | **System Admin** ผ่าน Map Editor (`/api/admin/maps/:mapId/pets`, AdminGuard) | ถ้า Workspace Owner/Admin ต้องวางเองได้ → ต้องมี endpoint ฝั่ง `/api/user/*` + สิทธิ์ตาม workspace role ซึ่ง**ยังไม่มีใน design** — ถาม PM |
| 11 | **ชื่อ event / ช่องทาง realtime** | `ws:pet:state` · `ws:pet:interact` · `ws:pet:stageChange` (ยิงจาก ws โดยตรง) | `pet_spawned` · `pet_moved` · `pet_renamed` · `pet_removed` · `pet_stage_changed` · `pet_xp_changed` (api → Redis `vo:zone` → ws) | รวมเป็นชุดเดียว: admin action ใช้ของ PetManagement · **AI position tick (`ws:pet:state`) เกิดใน zyra-ws เอง** ไม่ผ่าน api · `ws:pet:interact` ≈ `pet_xp_changed` + `action` |
| 12 | **AI movement server-side** | zyra-ws เดิน A\*, tick 200ms/2s, Redis `pet:position`, หยุดเมื่อไม่มีคน >5 นาที | **ไม่มีใน design เลย** — PetManagement ครอบแค่ตำแหน่งที่ admin วาง | งานใหม่ทั้งก้อนใน zyra-ws (pet ต้องรู้ zone tiles + blocked tiles + `pet_sittable` objects) — ต้องเขียน technical design แยก |
| 13 | **Animation ที่ client ต้องเล่น vs slot ที่มี** | wobble · walk 4 ทิศ · idle loop (หาว/เงย/กระดิก) · notice (หูตั้ง) · happy · sad/นอนซม · hatch (crack) · grow (glow+scale) · evolve (light pillar) · born · recovery · sit | slot ต่อ stage: egg = `Wobbling` `Evolution` · baby/adult/evolved = `Walking` `Sitting` `Happy` `Sad` `Evolution` (**17 slot, `Idle` ถูกถอด 2026-09-01**) | map ให้ชัด: idle → ใช้เฟรมแรกของ `Walking` หรือ `Sitting`? · notice/born/recovery → ไม่มี slot ต้องเป็น particle/effect ฝั่ง client หรือ reuse `Happy` · crack/glow/light pillar → `Evolution` ของ stage ต้นทาง + effect ฝั่ง client · **ถ้าต้องมี idle จริง ต้องกลับไปเปิด slot `Idle` (20 slot) ซึ่งเพิ่งตัดออก** |
| 14 | **Timezone ของ daily limit** | **UTC date** (SC-PET-03, SC-PET-06) | `day_key` = DATE ตาม **UTC+7** (ไม่งั้น "ข้อความแรกของวัน" รีเซ็ตตอน 7 โมงเช้า) · daily reminder ใน SC-PET-07 ก็ใช้ 9:00 **ICT** | ยึด UTC+7 ให้ตรงกับ ledger — card ต้องแก้ |
| 15 | **Sittable object** | property `pet_sittable: true` บน Objects layer | ไม่มี field นี้ใน Object Management | งานเพิ่มใน Object Management (admin ติ๊ก object ว่า pet นั่งได้) — คนละโมดูล |
| 16 | **Notification** | in-app ทุก member (offline ด้วย) + banner 5 วิ + XP milestone 50/75/90% + daily reminder cron + toggle ใน settings | ไม่มีใน PetManagement | กระทบ zyra-notifications + Setting → Notifications tab ของ member — SC-CHAT-10 เป็น precedent · **banner เฉพาะ Active status และไม่อยู่ใน Bubble** (SC-PET-04) ต้อง reuse logic presence ที่มี |
| 17 | **Achievement / Prestige XP** | เก็บ log "First Hatch!" / "Fully Evolved!" · Prestige XP หลัง evolved · cosmetic (future) | ไม่มี — `tb_room_pet.xp` เป็น INT สะสมได้ต่อหลัง `xp_evolve` อยู่แล้ว | Prestige = `xp - xp_evolve` derive ได้ ไม่ต้องเก็บ · achievement ต้องมี table ใหม่ถ้าจะ log จริง — ยังไม่มี design |
| 18 | **Top contributors วันนี้** | top 3 user ที่ให้ XP มากสุดวันนี้ | `tb_room_pet_xp_event` มี `user_id` + `day_key` + `xp_awarded` → query ได้ตรง ๆ | ตรงกัน — เพิ่ม endpoint `GET /api/user/workspaces/:id/pets/:petId/status` (ยังไม่มีใน contract) |
| 19 | **Animation ตอนเปลี่ยนช่วงวัย** | hatch/grow/evolve animation ต่อ pet (SC-PET-04/05) | slot `Evolution` เป็น PNG spritesheet ต่อ stage | **PM เคาะ 2026-09-02:** เมื่อถึง threshold pet เข้า "สถานะ evo" แล้วเล่น slot `Evolution` ซึ่งต้อง**อัปโหลดเป็น GIF** (ไม่ใช่ spritesheet) · **egg → baby ใช้ GIF กลางตัวเดียวทุก pet type** อัปขึ้น R2 แล้ว `static/pet/shared/egg-evolution.gif` (960×960, 24 เฟรม, 159 KB) client โหลดเป็น const ไม่ผูก `tb_pet_animation` · baby → adult / adult → evolved ใช้ GIF ของ stage ต้นทางต่อ pet type · ดู [ux-ui.md §5.2](ux-ui.md) + [PetManagement/spec.md § Evolution = GIF](../PetManagement/spec.md) · egg/evolved **คง slot `Evolution` ไว้** (PM ยืนยัน) → 17 slot เท่าเดิม · **egg `Evolution` prefill ไฟล์กลางอัตโนมัติทุก type** (API คืน `is_default: true` เมื่อไม่มี row) และ admin อัปทับได้ — client อ่าน URL จาก response ไม่ hardcode ([PetManagement/spec.md § Prefill](../PetManagement/spec.md)) · **ปิดครบแล้ว** |

### คำถามที่ต้องถาม PM ก่อนเริ่ม (สรุปจากตาราง)

1. **Feed** ยังอยู่ในสโคปไหม (ข้อ 3) — ถ้าอยู่ XP เท่าไร นับเป็น activity ไหน
2. **Mood 3 หรือ 4 state** (ข้อ 4) — Hungry มีจริงไหม
3. **"ทีม online 5+ คน +10 XP"** (ข้อ 2) — ตัดหรือเพิ่มเป็น activity ที่ 11
4. Stroke ตอน Sad ได้ XP 50% หรือ 100% (ข้อ 7) · activity ไหน reset mood (ข้อ 8)
5. **1 room = 1 pet** ยืนยันตาม card ใช่ไหม → เปิด `uq_room_pet_one_per_zone` (ข้อ 9)
6. Workspace Owner/Admin วาง pet เองได้ไหม หรือ System Admin เท่านั้น (ข้อ 10)
7. Idle animation ใช้ slot ไหน — กลับไปใช้ 20 slot หรือ reuse (ข้อ 13)
8. ยังค้างจาก PetManagement: วาง pet ใน Workspace **Template** แล้ว workspace ที่สร้างไปก่อนหน้าได้ pet ด้วยไหม
9. **card ↔ Figma ไม่ตรงกัน** (รายละเอียด + คำถาม design อีก 12 ข้อใน [ux-ui.md §0, §11](ux-ui.md)): banner HUD vs modal · Pet panel content (Top 3/ลูบหัว/Feed vs Daily quest/streak) · ใครเห็น animation เต็มจอ · streak "Together for N days" ต้องมี field ใหม่ · Hover tooltip ไม่มี (ข้อมูลอยู่บน nameplate ถาวร)

### ความพร้อม — ข้อมูลพอเริ่ม Room Pet แล้วหรือยัง (ประเมิน 2026-09-02)

> ตรวจกับ `origin/develop` ของ zyra-app / zyra-api / zyra-ws + PR ที่เปิดอยู่บน branch `feat/pet-management-xp`: [zyra-app #240](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/240) (CI เขียว, review **CHANGES_REQUESTED**) และ [zyra-api #63](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/63) (ยังไม่มี review) — **ยังไม่ merge ทั้งคู่**
> **ผล: ยังไม่พอ** — ฝั่ง content (pet type, sprite, XP config) พร้อม แต่ฝั่ง runtime ที่ทำให้มี pet อยู่ในห้องเป็นศูนย์

**PR #240 / #63 คืออะไร** — งานขัดเงา Admin เท่านั้น ไม่มีชิ้นไหนของ Room Pet:
- app: preview modal ตัดเฟรมตาม grid ที่ detect จาก alpha, layout ไข่แยก, `frame_rate_by_stage`, scrollbar ใน upload step, label "Evolution animation"
- api: `FrameRateByStage` ใน metadata + migration 88–91 normalize `frame_count`/`frame_rate` ของ sprite เดิม
- ⚠️ ทั้งสอง PR ยัง `accept="image/png,image/gif"` ที่ slot `Evolution` และล็อก frame input ทุก slot → **ขัด decision 2026-09-02** (GIF เท่านั้น · ซ่อน 3 ช่อง · prefill egg) — merge ได้แต่ต้องมี PR ตามแก้ตาม [PetManagement/spec.md § ผลต่อโค้ด](../PetManagement/spec.md)

**มีบน `develop` แล้ว ใช้ได้เลย**
- pet type CRUD + animation (S3 URL + frame meta) · XP config + history 10 version · field `pet_activity` ใน `NotificationSettings` (section ซ่อน `hidden: true`)
- โครง VO เดิมทุกชิ้นที่ [ux-ui.md §10](ux-ui.md) ให้ reuse (nameplate, minimap, panel shell, notification card, `AnnouncementGate`, `lib/zone-utils.ts`, relay `vo:zone`)
- GIF ไข่แตกกลางบน R2 (`static/pet/shared/egg-evolution.gif`)

**ยังไม่มีเลย — บล็อกทุก scenario SC-PET-01 ~ 08**

| ขาด | ผล | อยู่ในแผนไหน |
|---|---|---|
| `tb_room_pet` + placement API `/api/admin/maps/:mapId/pets` + palette ใน Map Editor (SC-PM-05) | **ไม่มี pet อยู่ในห้องใดเลย → ไม่มีอะไรให้ render** | PetManagement PR 6, 8 — ยังไม่เริ่ม |
| ~~member endpoint `GET /api/user/workspaces/:id/pets` · stroke · status~~ | ✅ **ครบทั้ง 3 ตัวแล้ว** (list = PR 10 merged · stroke + status = PR 9 [api #68](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/68)) — เหลือฝั่ง client ที่ยังต่อ mock อยู่ | PR 10 ✅ / PR 9 ✅ |
| ~~XP engine + ledger `tb_room_pet_xp_event`~~ | ✅ **มีแล้ว 2026-09-04** — migration 89 + `RoomPetXPService` + `POST …/pets/:petId/play` + `GET …/status` ([api #68](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/68), ยังไม่ merge) · จ่าย XP ได้แค่ `xp_play_with_pet` — อีก 9 activity (login/office/meeting/chat) ยังไม่มี caller | PR 9 ✅ |
| zyra-ws: pet AI + event `pet_*` (ตอนนี้รู้จักแค่ `zone_claim_changed` / `map_object_changed` / `map_updated`) | pet ไม่เคลื่อน ไม่ sync | PR 7 + technical-design.md ยังไม่เขียน |
| notification type `pet_*` ใน api / app / zyra-notifications + cron 9:00 ICT | SC-PET-07 ทั้งใบ | ยังไม่มี |
| Evolution GIF-only + prefill egg + ถอด `Idle` (17 slot) | โค้ดยังรับ PNG/GIF, ส่ง GIF เข้า grid validation, `RequiredPetSlots` ยัง 20 | รายการแก้ใน PetManagement/spec.md |
| `pet_sittable` บน object (มีแค่ derive `type === "sofa"`) | pet นั่ง object ไม่ได้ตาม spec | ยังไม่มี |
| คำตอบ design 12 ข้อ ([ux-ui.md §11](ux-ui.md)) + PM 9 ข้อ ([test-plan.md §6](test-plan.md)) | badge Adult/Evolved, minimap dot, compact zoom, toast ชน panel ฯลฯ | รอคำตอบ |

**ลำดับที่ต้องผ่านก่อนเริ่ม SC-PET-01** — ✅ **ผ่านครบทั้ง 6 ข้อแล้ว 2026-09-04**
1. ✅ merge #240 / #63 → PR ตามแก้ GIF-only + prefill + 17 slot
2. ✅ api PR 6 — `tb_room_pet` + placement + `pet_spawned/moved/renamed/removed` (api #65)
3. ✅ ws PR 7 — forward `pet_*` ทั้ง 6 ตัว (ws #29)
4. ✅ app PR 8 — drag-drop ใน Map Editor (app #246)
5. ✅ api PR 9 — XP engine + ledger ([api #68](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/68), รอ merge)
6. ✅ เริ่ม Room Pet ฝั่ง member ได้แล้ว — SC-PET-01 render บน VO เสร็จ (app #248) · **ถัดไป: ต่อ `VOPetPanel` + ปุ่ม stroke เข้า API จริง (SC-PET-03/06) แทน mock**

**เริ่มได้ทันทีโดยไม่รอข้อ 1–5** (component ล้วน ทดสอบกับ fixture ใน [test-plan.md §0](test-plan.md)): `PetStageBadge` · `PetTooltip` 3 variant · `VOPetPanel` (mock data) · derive helpers `lib/pet-stage.ts` (stage / mood / relative XP) · option `leadingIcon` / `trailingEmoji` / `progress` ของ `makeNameTag` · prop `petDots` ของ `VOMinimap` · unhide section PET ใน Setting — ตรง test-plan §1.1–1.7, 1.13, 1.14 · **ต้องเปิด `progress.md` ในโฟลเดอร์นี้ตั้งแต่ PR แรก**

### งานที่ยังไม่มี design เลย (ต้องเปิด technical-design.md ในโฟลเดอร์นี้)

- zyra-ws: pet AI (wander / idle / react) + tick + Redis position + หยุดเมื่อห้องว่าง (ข้อ 12)
- zyra-app: pet renderer บน PixiGameScene (z-order ตามกฎ `encodeZ` เดิม — **ไม่มี `OBJECT_Z_INDEX` ในโค้ด** ชื่อนั้นมาจาก card, walkable, nameplate, mood bubble, minimap dot), pet menu marker + tooltip คีย์ลัด, Pet menu panel, evolution modal + overlay, notification card, reminder banner — รายละเอียด reuse ต่อชิ้นอยู่ที่ [ux-ui.md §10](ux-ui.md)
- ⚠️ ข้อ 8 ด้านบน (ปุ่ม Pet บน HUD) — **Figma ไม่มีปุ่ม Pet บน HUD/bottom menu เลย** เปิด panel จากการคลิก pet เท่านั้น (ux-ui.md §2.4)
- zyra-api: member endpoints เพิ่มจาก contract (status panel, interaction พร้อม rate limit 3 วิ, daily counters) + XP engine ที่อ่าน `tb_pet_xp_config` จริง
- zyra-notifications: 3 ชนิด notification + cron 9:00 ICT + user toggle
- Object Management: `pet_sittable` (ข้อ 15)

---

## สถานะ implement ต่อ scenario (2026-09-04) — สำหรับ QA

> อ้างอิง PR ในตารางของ [progress.md รอบ 18](progress.md) · **build เขียวทุกตัว · live-test ผ่านเฉพาะ XP engine** ที่เหลือยังไม่ได้ทดสอบจริงบน dev เพราะ `NEXT_PUBLIC_ROOM_PET` ยังไม่ถูกตั้ง

| ID | ทำแล้ว | ไม่ได้ทำ (พร้อมเหตุผล) |
|---|---|---|
| SC-PET-01 ดู Pet บน map | sprite + nameplate + mood emoji + XP bar + minimap dot + คลิกเปิด panel · sheet 404 → ไม่แสดงอะไร (LOAD-03) | — |
| SC-PET-02 AI movement | wander (สุ่มจุดใกล้จุดวาง, พัก 3–8 วิ, ~50/50) · ไม่ออกนอกห้อง ไม่ทะลุ obstacle · หันหาคนใน 3 tiles · เดินเข้าหาเมื่อยืนนิ่ง 3 วิ · หลายคนเท่ากัน = สุ่ม · egg ไม่เดิน · sad ไม่เดิน · หยุดเมื่อไม่มีคน 5 นาที · client interpolate ให้ลื่น | **นั่งบน object** — ต้องมี `pet_sittable` ใน Object Management ก่อน (คนละโมดูล) · **facing (หันซ้าย/ขวา/บน/ล่าง)** — ws ส่ง direction มาแล้ว แต่ไม่มี spec ว่า sprite row ไหนคือทิศไหน เดาแล้วจะวาดผิด |
| SC-PET-03 Interact | marker มือ (คลิกถึงจะขึ้น) · tooltip `Press [P] pet` ตอน hover ในระยะ 2 tiles · คีย์ลัด P · ลำดับ `+N XP` → ♥ · Happy animation 2.5 วิ · rate limit 3 วิ (429) · ครบโควตา = ยังเล่นได้แต่ไม่ได้ XP | **Feed** — card ตัดชื่อออกแล้ว เหลือ Stroke อย่างเดียว |
| SC-PET-04 Egg → Baby | prompt คลิกไข่ → GIF → แสงวาบ → reveal → modal · เฉพาะคนที่ทำให้ XP เต็มเห็น animation คนอื่นได้ modal · GIF อ่านจาก API ไม่ hardcode · GIF 404 → ข้ามไป flash · Esc ข้ามไป modal · ไม่เด้งใส่คน away / ในห้องประชุม / ใน Bubble | **Share your friends** — modal ที่ ux-ui §5.4 บอกว่ามีอยู่แล้ว จริง ๆ ไม่มีในโค้ด · **achievement badge** — ยังไม่มี table |
| SC-PET-05 Baby → Adult → Evolved | flow เดียวกับ 04 ทุกประการ · bar ไหลลงจาก 100% พร้อมตัวเลขนับ · demote (admin ขยับ threshold) = ไม่เล่น animation | เหมือน 04 |
| SC-PET-06 Pet Status | panel เปิดจากคลิก pet · stage badge · mood · XP bar แบบ relative · Daily quest นับจริงจาก `GET …/status` · MAX XP variant | **Top 3 carers** — Figma แทนด้วย Daily quest (ยึด Figma) · ข้อมูลมีใน response แล้ว |
| SC-PET-07 Notification | 3 ชนิด (`pet_growth` / `pet_milestone` / `pet_reminder`) · เคารพ setting `pet_activity` · milestone 50/75/90 ไม่ยิงซ้ำ · reminder 09:00 ICT วันละครั้ง · card แปลภาษาฝั่ง client | **HUD banner 5 วิ** — Figma แทนด้วย modal เต็มจอ ซึ่งทุกคนได้อยู่แล้ว ทำทั้งคู่ = ประกาศซ้ำ |
| SC-PET-08 Neglected | mood derive จาก `last_activity_at` (3 state) · sad = แสดง sheet `Sad` + หยุดเดิน + ไม่ react · XP ลด 50% ผ่าน mood multiplier · stroke 1 ครั้ง = กลับ Happy ทันที | — |

### ต้องทำก่อนส่ง QA

1. ตั้ง secret **`NEXT_PUBLIC_ROOM_PET=true`** ใน GitHub Environment `dev` ของ zyra-app — ไม่ตั้ง = ไม่เห็นอะไรเลย
2. ตั้ง `xp_play_with_pet.times` = **5** ในหน้า XP Configuration (seed เป็น 1 แต่ SC-PET-03 เขียน 5)
3. อัป GIF slot `Evolution` ของ pet type ที่จะเทส (egg มี prefill กลางให้แล้ว แต่ baby/adult ต้องอัปเอง ไม่งั้น flow จะข้าม GIF ไป flash เลย)
4. deploy zyra-api + zyra-ws ใหม่ (pet AI กับ notification อยู่ในนั้น)

### ยังไม่มีคนเรียก — pet จะโตช้ามาก

`Award()` ถูกเรียกจาก **`POST …/play` ที่เดียว** ตอนนี้ อีก 9 activity (`xp_login_per_day`, `xp_office_*`, `xp_team_meeting*`, `xp_*_message_fo_day`) ยังไม่มีใครแทรกเข้า flow เดิม — เป็นงานถัดไป

## Reference

- ClickUp parent: [[Feature] Room Pet — Virtual Office](https://app.clickup.com/t/86d3dc92c)
- UI spec จาก Figma + reuse map กับ component VO เดิม: [ux-ui.md](ux-ui.md)
- Test plan (unit / component / API / E2E ต่อ scenario): [test-plan.md](test-plan.md)
- Admin side: [PetManagement/spec.md](../PetManagement/spec.md) · [db-schema-api-contract.md](../PetManagement/db-schema-api-contract.md) · [pm-discussion-notes.md](../PetManagement/pm-discussion-notes.md) (decision log) · [progress-2026-08-31.md](../PetManagement/progress-2026-08-31.md)
- Figma file: [Zyra design — More Organised ver.](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-) (node ต่อ scenario อยู่ในตาราง §2)
