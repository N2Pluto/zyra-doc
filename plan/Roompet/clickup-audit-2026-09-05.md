# Room Pet — อ่าน ClickUp ใหม่ทั้งชุด เทียบกับของที่ทำจริง (2026-09-05)

> **สถานะ:** audit ครบ 8 card + parent · repo: zyra-api / zyra-app / zyra-ws · ทำตามคำสั่ง user "อ่าน 86d3dc92c ใหม่ทั้งหมดแบบละเอียด แล้วเอามาใส่ใน plan/Roompet เพราะดูเหมือนจะไม่ตรง"
> **แหล่ง:** ClickUp MCP (read-only) ดึงสด 2026-09-05 20:45 ICT — parent [86d3dc92c](https://app.clickup.com/t/86d3dc92c) + subtask 8 ใบ · ไม่มี comment / attachment / checklist ในทุกใบ
> **สิ่งที่เปลี่ยนใน ClickUp ตั้งแต่ spec.md เขียน (08-13~18):** เนื้อหา description **ไม่เปลี่ยนแม้แต่ตัวอักษร** (เทียบกับ [spec.md §1–§3](spec.md) แล้วตรงทุกบรรทัด) · ที่เปลี่ยนคือ **status ทุกใบ `pending` → `in progress`** (parent 09-02, SC-01/02/03 09-03, SC-04~08 09-04) และ parent มี assignee = user แล้ว
>
> **สรุปว่า "ไม่ตรง" ตรงไหน:** card ไม่ได้เปลี่ยน — ที่ไม่ตรงคือ **card กับของที่ทำ** เพราะระหว่างทางมี 3 แหล่งที่ทับ card: (1) **Figma** ใหม่กว่า card ([ux-ui.md](ux-ui.md) — ยึด Figma ตามที่ตกลงในรอบ 18) (2) **PM decision ฝั่ง PetManagement** (4 stage ชื่อใหม่, 10 activities, slot 17 ตัว, XP ไม่ reset ต่อ stage) (3) **user เคาะเองบน dev วันนี้** (quest 5 ตัว, quest เป็นของห้อง, เฉพาะคนมี private zone ในห้อง) — ตารางด้านล่างบอกทุกข้อว่าตรง / เบี่ยงเพราะอะไร / ยังไม่ทำ

สัญลักษณ์: ✅ ทำตาม card · 🔀 ทำต่างจาก card **โดยตั้งใจ** (มีแหล่งอ้าง) · ❌ ยังไม่ทำ · ❓ ต้องเคาะ

---

## Parent — Room Pet Feature

| card | ของจริง | สถานะ |
|---|---|---|
| 1 Room = 1 Pet ไม่ผูก user | `tb_room_pet` 1 แถว/zone (unique) · api #65 | ✅ |
| Pet ของทั้ง workspace ทุกคนเลี้ยงได้ | stroke เปิดให้ทุก member · **quest เฉพาะ resident ของห้อง** (user เคาะ 09-05) | 🔀 user decision |
| โตจาก active ของ users ในห้อง + ป้อนอาหาร/ดูแล | โตจาก 10 activity (config) + stroke · **ไม่มี Feed** (card SC-03 ตัดชื่อทิ้งแล้ว) | 🔀 PM |
| 4 stage **Egg → Hatch → Grow → Evolve** | `egg / baby / adult / evolved` ตาม Figma + PetManagement | 🔀 PM 08-14 (ชื่อ) |
| animation: เดิน / Idle ในมุมห้อง / นั่งบน object | เดิน (Walking) · นิ่ง = Sitting · **นั่งบน object ❌** (`pet_sittable` ยังไม่มี) | ⚠️ ครึ่งเดียว |
| Egg 0–99 / Hatch 100–499 / Grow 500–1999 / Evolve 2000+ | threshold เป็น **config** (`tb_pet_xp_config.thresholds`, default 100/500/2000) | ✅ (ปรับได้) |
| Hatch "เดินแบบ baby", Grow "เดินเร็ว", Evolve "special animation" | ความเร็วเดิน **เท่ากันทุก stage** (600 ms/tile) · special animation ❌ | ❌ |
| XP Sources 4 แถว (login +1/วัน · office 30 นาที +2 · pet/interact +1 max 5 · **ทีม online 5+ คน +10**) | 10 activities ตาม PetManagement SC-PM-04 · **"ทีม online พร้อมกัน 5+ คน" ไม่มีใน 10 ตัว** | 🔀 PM · ❓ bonus 5 คนหายไปจาก config ตั้งใจไหม |

## SC-PET-01 · ดู Pet บน map

| card | ของจริง | สถานะ |
|---|---|---|
| sprite เหนือ floor, z-index = `OBJECT_Z_INDEX` | ใช้กฎ z-order เดียวกับตัวละคร (`encodeZ(sortRowDrawOrder(row,1),1,tie)`) — ไม่มี `OBJECT_Z_INDEX` ในโค้ด (app #261) | ✅ (ชื่อ const ต่าง) |
| sprite ต่างกันทุก stage | sheet ต่อ stage จาก Pet Management | ✅ |
| ชื่อ label เหนือ sprite เหมือน nameplate | nameplate + mood emoji + XP bar (Figma) | ✅ |
| **Hover: tooltip ชื่อ / stage badge / XP bar / mood** | Figma **ไม่มี tooltip** — ข้อมูลอยู่บน nameplate ถาวร · hover = **ขอบเขียว** (user 09-05, app #264) + `Press [P] pet` เมื่ออยู่ในระยะ | 🔀 Figma + user |
| ไม่ block path | pet ไม่อยู่ใน obstacle grid | ✅ |
| minimap dot "สีพิเศษ (เช่นชมพู)" | `#996ADF` ม่วง ตาม Figma Ellipse | 🔀 Figma |
| ห้องไม่มี pet = ไม่แสดง · assign โดย WS Admin / Owner / Admin System | admin editor (#246) + owner/admin editor (#256, user เคาะ) | ✅ |
| position sync ผ่าน WS server-driven | zyra-ws `pet_state` (#31) | ✅ |

## SC-PET-02 · AI Movement

| card | ของจริง | สถานะ |
|---|---|---|
| Wander จุดสุ่มใน room boundary · รอ 3–8 วิ · A* หลีก collision · 50% | ครบ · **วันนี้เจอเดินออกนอกห้องบน dev** เพราะ workspace เก่าไม่มี zone snapshot ใน Redis → แก้ fail-closed ([ws #34](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/34)) + backfill snapshot ([api #80](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/80)) | ✅ (แก้แล้ววันนี้) |
| Walk animation 4 direction เหมือน avatar | Walking sheet + facing row 0–3 (app #259, #263) | ✅ |
| Idle "อยู่มุมห้อง/จุด favorite" เล่น idle loop หาว/เงย/กระดิก | นิ่ง = **Sitting** (spec PetManagement ไม่มี slot Idle) · ไม่มี "จุด favorite" — พักตรงที่เดินถึง | 🔀 slot spec |
| Egg: wobble เท่านั้น ไม่เดิน | ✅ | ✅ |
| React: หันหา (radius 3) · "notice animation หูตั้งตาเบิก" · เข้าหา 1 tile หลังยืนนิ่ง 3 วิ · random เมื่อหลายคน | หันหา / เข้าหา ✅ · **หยุดนิ่ง + หันหาคนแรก ไม่ random** (D12, user เคาะ) · **notice animation ❌** (ไม่มี slot ให้) | 🔀 user · ⚠️ |
| Hatch เดิน**ช้า** / Grow เดิน / Evolve ทุก behavior + special | ความเร็วเดียว ไม่มี special | ❌ |
| ไม่เดินทับ collision / ไม่ออกนอก room | ✅ (หลัง ws #34 เช็คทุก tile ของ path) | ✅ |
| broadcast 200 ms ขณะเดิน / 2 วิ ขณะ idle | tick 200 ms · step 600 ms · idle heartbeat 2 วิ | ✅ |
| position เก็บ Redis `pet:position:{room}` TTL 5 นาที | อยู่ใน memory ของ ws (แหล่งจริงคือ ws) — ไม่มี Redis key | 🔀 design ws #31 |
| Sittable objects `pet_sittable: true` | ❌ ยังไม่มี (แผนใน progress รอบ 25) | ❌ |
| AI หยุดเมื่อไม่มีคนในห้อง > 5 นาที | ✅ (ws #32) | ✅ |

## SC-PET-03 · Interact

| card | ของจริง | สถานะ |
|---|---|---|
| กด 🤚 หรือ P → happy animation → +1 XP → ♥ → mood happy | ✅ (app #251) · **ปุ่ม 🤚 ขึ้นเองเมื่อ resident เดินเข้าใกล้ ≤2 tile** (app #265, user 09-05) · XP = config `xp_play_with_pet` · **ตอนนี้ปิดอยู่ (config v12) → ลูบได้แต่ไม่ได้ XP** | ⚠️ config |
| bubble เมื่ออยู่ใน radius 2 | ✅ | ✅ |
| "pet เดินผ่านมา: bubble โชว์เอง 3 วิ" | ❌ ไม่ทำ — bubble โชว์ตอน hover/ใกล้เท่านั้น | ❌ |
| **Feed** 3/วัน | card ตัดชื่อ "(ป้อน / pet)" ทิ้งแล้ว แต่ AC ยังมี Feed | 🔀 PM (ไม่มี Feed) |
| Stroke 5/วัน/user | config `times` = 1 (ค่า seed) · **ตอนนี้ quota เป็นของห้อง ไม่ใช่ต่อ user** (user เคาะ 09-05) | 🔀 user decision · ❓ ตั้ง times=5 |
| "+X XP ✨" float · heart particles · broadcast ทุกคน · rate limit 3 วิ · mood อัปเดตทันที | ✅ ทั้งหมด (429 ที่ 3 วิ) | ✅ |
| Daily limit นับ **UTC date** | นับ **UTC+7** (เที่ยงคืนไทย) — user ยืนยันวันนี้ "รีเซ็ตทุกเที่ยงคืน" | 🔀 user |
| atomic increment | `SELECT … FOR UPDATE` ต่อ pet | ✅ |
| broadcast `ws:pet:interact {pet_id,user_id,action,new_xp,mood}` | ใช้ `pet_xp_changed {pet_id, xp, last_activity_at}` (ชื่อ/field ต่าง) | 🔀 ชื่อ event |

## SC-PET-04 · Egg → Hatch

| card | ของจริง | สถานะ |
|---|---|---|
| hatch animation: wobble เร็วขึ้น → crack → explosion → baby "born" | คลิกไข่ → **GIF `Evolution` กลาง** → แสงวาบ → reveal (Figma + PM 09-02 "Evolution = GIF") | 🔀 PM/Figma |
| animation 3–5 วิ ก่อน switch sprite | GIF จบแล้วค่อยเปลี่ยน (ความยาวตาม GIF) | ✅ |
| **Banner HUD 5 วิ** ทุกคน active ไม่อยู่ใน Bubble | Figma แทนด้วย **modal เต็มจอ** ทุกคน (คนที่ทำ XP เต็มเห็น animation ก่อน) | 🔀 Figma |
| In-app notification ทุก member online+offline | `pet_growth` ทุก member (api #71) | ✅ |
| **XP bar reset 0/400** | XP **สะสมไม่ reset** — bar เป็น relative ต่อ stage (PM, spec.md ข้อ 5) | 🔀 PM |
| Achievement "First Hatch!" เก็บ log ยังไม่แสดง | `tb_room_pet_achievement` (api #77) | ✅ |
| broadcast `ws:pet:stageChange {stage:"hatch", animation:"hatch"}` | `pet_stage_changed {stage, prev_stage, triggered_by, …}` | 🔀 ชื่อ event |
| notification เก็บใน Notifications table เหมือน SC-CHAT-10 | ✅ `tb_notification` type ใหม่ 3 ตัว (mig 90) | ✅ |

## SC-PET-05 · Hatch → Grow → Evolve

| card | ของจริง | สถานะ |
|---|---|---|
| Grow animation scale-up 4–6 วิ / Evolve light pillar 6–8 วิ | flow เดียวกับ 04 ด้วย GIF ของ stage ต้นทาง (baby/adult ต้องอัป GIF เอง — ยังไม่มีบน dev → ข้ามไป flash) | 🔀 PM · ⚠️ content |
| Banner ทุก growth event | modal เต็มจอ (Figma) | 🔀 Figma |
| Unlock นั่ง sittable ที่ Grow | ❌ (`pet_sittable`) | ❌ |
| XP reset ทุก stage · Post-Evolve "Prestige XP" สีพิเศษ | ไม่ reset · evolved = variant **MAX** ของ Figma (ไม่มีคำว่า Prestige) | 🔀 PM/Figma |
| Achievement "Fully Evolved!" ทั้ง workspace | log (api #77, user NULL = ของห้อง) | ✅ |
| stage switch รอ server confirm | client เปลี่ยน sheet จาก `pet_stage_changed` ของ server | ✅ |

## SC-PET-06 · Pet Status

| card | ของจริง | สถานะ |
|---|---|---|
| เปิดจากคลิก pet **หรือ Pet icon บน HUD** | คลิก pet เท่านั้น (Figma ไม่มี icon บน rail) | 🔀 Figma |
| Layout: XP progress + "เหลืออีก X XP" + **ลูบหัวแล้ว 3/5** + **Top 3** + **ปุ่มลูบหัว** | Figma: Mood / Stage / streak / **Daily quest** — ไม่มี Top 3, ปุ่มลูบ, Feed · "เหลืออีก X XP" ✅ | 🔀 Figma |
| Mood 4 state (Happy / Neutral / **Hungry** / Sad) ตาม `last_fed_at` 12/24/48h | 3 state (Happy 12h / Neutral / Sad 72h) ตาม PM 08-14 · ไม่มี Hungry | 🔀 PM |
| Daily counter "ของ user คนนั้น" | **quest เป็นของห้อง** (user เคาะ 09-05, api #80) | 🔀 user |
| Feed/Stroke ปุ่มใน panel disabled เมื่อครบ/ไกล | ไม่มีปุ่มใน panel (Figma) · Go to ต่อ quest ทำงานจริง (app #262) | 🔀 Figma |
| Stage badge สี Egg เทา / Hatch เหลือง / Grow เขียว / Evolve ม่วง | Egg `#8C99A6` / Baby `#2DB6FF` (Figma) / Adult `#58D68D` / Evolved `#996ADF` (interim) | 🔀 Figma (Baby ฟ้าไม่ใช่เหลือง) |
| Top contributors UTC date | data มีใน response (`contributors`) แต่ Figma ไม่แสดง · วันเป็น UTC+7 | 🔀 |
| streak "Together for N days" (Figma) | ❌ ไม่มี field · panel ซ่อน banner | ❌ (Figma-only) |

## SC-PET-07 · Notification

| card | ของจริง | สถานะ |
|---|---|---|
| Stage change: in-app + **banner** · กด → navigate ไปห้อง | in-app ✅ · banner → modal (Figma) · **กด notification navigate ไปห้อง ❓ ยังไม่ได้ตรวจ** | ⚠️ ต้องเช็ค |
| Milestone 50/75/90% in-app ไม่มี banner · "เหลืออีก 150 XP" | ✅ `pet_milestone` ไม่ยิงซ้ำ (`last_milestone`) | ✅ |
| Daily reminder 09:00 ICT · 1 ครั้ง/วัน/user · เฉพาะ user login แต่ยังไม่ interact | ✅ ยิงจริง 09-05 09:00 (8 แถว) | ✅ |
| **Hungry alert** ครั้งเดียวต่อ mood cycle | ❌ ไม่มี Hungry state → ไม่มี alert | 🔀 PM (ไม่มี Hungry) |
| user ปิดได้ใน settings | ✅ `pet_activity` toggle | ✅ |

## SC-PET-08 · Neglected

| card | ของจริง | สถานะ |
|---|---|---|
| Happy ≤12h / Neutral 12–48h / Sad >72h (48–72 ไม่ระบุ) | Neutral ยืดถึง 72h (config `mood`) | ✅ (ตีความ) |
| Sad: sprite เศร้า นอนซม หยุด wander ไม่ react | Sad sheet + หยุดเดิน + ไม่ react | ✅ |
| XP จาก team activity −50% | mood multiplier (config `sad.xp_rate_percent`) | ✅ |
| Recovery: **feed** 1 ครั้ง → Happy ทันที + recovery animation | **stroke** 1 ครั้ง → Happy + เล่น Happy sheet | 🔀 PM (ไม่มี Feed) |
| mood อัปเดตโดย **cron ทุก 1 ชม.** | derive ตอนอ่านจาก `last_activity_at` ไม่มี cron ไม่มี column mood | 🔀 design (ผลเท่ากัน) |
| ไม่มี pet ตาย | ✅ | ✅ |

---

## สิ่งที่ card สั่งแต่ **ยังไม่มีใครเคาะ** — ต้องถาม PM

> ข้อ 6 (stroke) เปลี่ยนไปแล้ว: ลูบเป็นของ resident เท่านั้น (D10) — เหลือแค่คำถามว่าจะให้ลูบได้ XP ไหม (เปิด `xp_play_with_pet` กลับ)

1. **"ทีม online พร้อมกัน 5+ คน +10 XP"** หายไปจาก 10 activities ของ PetManagement — ตั้งใจตัดไหม
2. **ความเร็วเดินต่าง stage** (Hatch ช้า / Grow ปกติ) และ **special animation ของ Evolve** — ไม่มี slot รองรับ ต้อง design เพิ่มหรือตัด
3. **notice animation** (หูตั้ง ตาเบิก) เมื่อคนเข้าใกล้ — ไม่มี slot
4. **"pet เดินผ่านมา bubble โชว์เอง 3 วิ"** — ยังไม่ทำ จะเอาไหม
5. **`pet_sittable`** — ต้องเคาะ 2 ข้อ (ดู progress รอบ 25) และเป็นงาน 4 repo
6. **`xp_play_with_pet`**: card บอก 5 ครั้ง/วัน · seed = 1 · ตอนนี้ **ปิด** (v12) และ quota เป็นของห้อง → ลูบไม่ได้ XP เลย — ตกลงจะให้ลูบได้ XP ไหม ถ้าใช่ต้องเปิด + ตั้ง times
7. **กด notification แล้ว navigate ไปห้อง** — ยังไม่ได้ตรวจว่า card notification ทำ
8. **streak "Together for N days"** ของ Figma — ไม่มี field ใน schema

## PM/user decision ที่เคาะวันนี้ (2026-09-05) — บันทึกให้ card ตามแก้

| # | เคาะว่า | ผล |
|---|---|---|
| D1 | Daily quest โชว์แค่ 5 ตัวที่ Figma มี | config v12 ปิดอีก 5 activity (รวม `xp_play_with_pet`) |
| D2 | quest ทำได้เฉพาะ **คนที่มี private zone อยู่ในห้องของ pet** | `roomResidents` (api #80) · non-resident **ไม่เห็น section quest เลย** (app หลัง #265 — เดิม #264 โชว์ progress+โน้ต) |
| D3 | quest **เป็นของห้อง** ใครทำแล้วนับให้ทุกคน | quota ต่อ pet/วัน ไม่แยก user (api #80) |
| D4 | Daily quest รีเซ็ตทุกเที่ยงคืน (ไทย) | `day_key` UTC+7 อยู่แล้ว · panel poll ทุก 1 นาที (app #264) |
| D5 | pet เดินได้เฉพาะใน zone ที่วาง ห้ามออก | ws fail-closed (#34) + api backfill snapshot (#80) |
| D6 | hover pet = ขอบเขียวเหมือนตัวละคร | app #264 |
| D7 | ใช้ท่าที่อัปโหลดตามสถานการณ์ (Walking/Sitting/Sad/Happy/Wobbling) | app #263 |
| D8 | ไม่มีปุ่มตาย ทุกปุ่มต้องพาไปทำได้จริง | app #262 |
| D9 | resident เดินเข้าใกล้ pet → หันหน้ามา + ปุ่มลูบขึ้นเอง | ws AI (มีอยู่แล้ว) + api #81 + app #265 |
| D10 | pet ของห้องอื่น: กดแล้วไม่มี quest เลย · **ลูบได้เฉพาะ resident** | app #266 · api #82 + app #267 |
| D11 | รูปใน Pet panel = stage ปัจจุบันจริง (ไข่เห็นไข่) ไม่ใช่ thumbnail ตัวโต | app #268 |
| D12 | มีคนใกล้ = pet **หยุดนิ่ง** หันหาคนที่มาถึงก่อน คนแรกออกค่อยไปคนถัดไป (แทน nearest/random ของ card) | ws #35 |
| D13 | เดิน = ท่า Walking เสมอ ท่าอื่นเล่นตอนนิ่งเท่านั้น | app #269 |
| D14 | capsule แบบ chat space เชื่อม pet ↔ resident ที่อยู่ในระยะ (เขียวเรา/ขาวคนอื่น เห็นเฉพาะ resident) | api #83 · app #270 |
