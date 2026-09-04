# Room Pet — Progress

> log ต่อรอบ (entry ใหม่ไว้บนสุด) · รูปแบบตาม [zyra-doc/README.md § อัปเดตความคืบหน้า](../../README.md)
> สถานะรวมอยู่ที่ blockquote หัว [spec.md](spec.md) · ความพร้อมของ dependency ดู [spec.md § ความพร้อม](spec.md)

---

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
