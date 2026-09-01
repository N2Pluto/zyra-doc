# เมนู meeting ค้างหลังคลิกออกจากห้องประชุมกลับ private zone ตัวเอง

> **สถานะ:** แก้แล้ว + **live-verified 2026-09-01** — repro บั๊กได้จริงบน local stack แล้วพิสูจน์ว่าหายทั้ง 2 ชั้น (ตาราง §Live verify) · unit test เขียว (15 เคสใหม่, suite รวม 1287 ผ่าน) + `tsc`/eslint/prettier/`next build` สะอาด · **repo:** zyra-app (client-only fix, ไม่แตะ zyra-ws)
> **branch:** zyra-app `fix/vo-meeting-panel-stuck-on-walkout` · **doc:** zyra-doc `docs/vo-meeting-panel-stuck-on-walkout`
> **สำคัญ:** ต้นเหตุ **ไม่ใช่** LiveKit/SFU และ **ไม่ใช่** media-plane union (BUG #50) — เป็น client ยิง zone-claim ที่ server verify ไม่ได้ แล้วโดน `force_sync` ฆ่า walk ทิ้ง

## อาการที่รายงาน

> เข้าห้อง meeting ที่ไม่มีคนอยู่ แล้วออกมาด้วยการ click กลับไปที่ private zone ตัวเอง →
> เมนู meeting ค้าง แล้ว meeting ก็เหมือนว่าเรายังอยู่ในนั้น
>
> เพิ่มเติม: **click ตรงพื้นที่ว่างใน private zone เท่านั้นที่เป็น — ถ้า click ไปนั่งที่เก้าอี้ ไม่เป็น**

หน้าจอที่เห็น: `ZoneEnterPanel` (compact) ค้างอยู่บนสุด หัวข้อเป็นชื่อ **meeting zone** พร้อมปุ่ม
chat (= `isMeeting`) แต่จำนวนสมาชิกเป็น **0** และเนื้อ panel ขึ้น "No one here yet" ขณะที่ timer
เดินอยู่ — ทั้งที่ตัวละครยืนอยู่ใน private zone ของตัวเองแล้ว

เบาะแส "เก้าอี้ไม่เป็น" คือกุญแจของเคสนี้ — มันชี้ตรงไปที่ recovery path ที่มีเฉพาะฝั่ง seat

## ทำไม panel โชว์ 0 คน — สอง source of truth ที่หลุดจากกัน

| ข้อมูลใน panel | มาจาก |
|---|---|
| panel โชว์/ไม่โชว์ + ชื่อโซน + `isMeeting` | `activeZone` ← **`settledTile`** |
| participant tiles / จำนวนคน / `activePrivateOccupancy` | geometry ของ **tile จริง** (`debugMyTile`) |

`activeZone` ไม่ได้ derive จากตำแหน่งจริงของตัวละคร แต่ derive จาก `settledTile`
(`hero-virtual-office.tsx` — `zoneAtWorldPoint(visibleZones, …)` บน settledTile) เพราะฉะนั้น
"panel ของ meeting โชว์อยู่ แต่บอก 0 คน" = **`settledTile` ค้างอยู่ในโซน meeting ขณะที่ตัวจริง
อยู่ที่อื่น** ไม่ใช่ปัญหาของ roster

`settledTile` ถูกเขียนแค่ 4 ที่:

1. `setOnPathStarted` — **meeting-exit detection (#56)**: ดันไป tile ปลายทางทันทีตอนคลิก
2. `setOnPathEnded` — commit tile ที่ไปถึงจริง (เส้นทางปกติของ zone entry)
3. `moved` self-sync ที่ **hard snap**
4. `force_sync`

## Root cause — claim โซนที่ยังไปไม่ถึง → server ตอบ force_sync → walk ตายเงียบ

```
1. click พื้นว่างใน private zone (ยืนอยู่ใน meeting)
   engine: _firePathStarted → hero onPathStarted → ส่ง `goto`
   + #56 ดัน settledTile = tile ปลายทาง  ← ตัวละครยังอยู่ใน meeting

2. activeZone = private zone → effect chat-space ยิง
   ws `chat_space:zone { suppressed:true, zone_id:<private zone> }`
   ซึ่ง zyra-ws อ่านว่า "ฉันยืนอยู่ในโซนนี้"

3. zyra-ws handleChatSpaceZone → zoneClaimTileOK() = false
   (server ยังเห็นเราที่ meeting tile, in-flight leg ก็ไม่ถึง private zone)
   → forceSync(c, "zone_claim_rejected")            [internal/hub/room.go]

4. client: forceSyncLocalPlayer()
   - ล้าง pathQueue + _retirePathWalk()  →  **ไม่ยิง onPathEnded**
   - hero: setSettledTile(server tile)   →  **กลับไปอยู่ใน meeting**

5. server ยังเดิน goto ต่อ (forceSync ล้างแค่ lastWalkPath) → self-sync ลากตัวละคร
   ไปถึง private zone จริง แต่ไม่มีอะไรอัปเดต settledTile อีกเลย
```

ผลลัพธ์: `activeZone` ค้างที่ meeting → `ZoneEnterPanel` เด้งกลับมา + `mediaZoneId` ค้าง
(SFU re-connect เข้าห้อง meeting, ไมค์/กล้อง publish อยู่จริง) + `meetingChatZoneId` ค้าง →
ยิง event `participated` ใหม่ ซึ่งอธิบาย **timer ที่นับใหม่จาก 00:00** ในภาพได้ — panel มัน
*ปิดแล้วเด้งกลับ* ไม่ใช่ค้างมาตั้งแต่แรก

จุดที่ทำให้ reproduce ได้ทุกครั้ง (ไม่ใช่ race): `forceSync` สร้าง `Seq` สดตอนส่ง
(`c.nextOutSeq()`) เพราะฉะนั้น gate `supersedable && seq < maxSelfSeqRef` ฝั่ง client กันมันไม่ได้
— force_sync นี้ "ใหม่กว่า" ทุก self-sync ที่ผ่านมาเสมอ

### ทำไม click เก้าอี้ไม่เป็น

เส้นทาง seat arm `_pendingSeat` + `_seatResumeLeft = 2` ไว้ → `forceSyncLocalPlayer`
**เก็บ sit intent ข้าม snap แล้วเรียก `_resumeSeatIntent()` เดินใหม่** → walk รอบใหม่จบปกติ →
`onPathEnded` ยิง → `settledTile` commit ที่ tile จริง → panel ปิดถูกต้อง

เส้นทาง click พื้นว่าง `set _pendingSeat = null` ชัดๆ → **ไม่มี recovery เลย** walk ตายเงียบ
ไม่มีใครรายงานจุดจบ

> meeting ว่างไม่ใช่เงื่อนไขของบั๊ก — แค่ทำให้เห็นชัด ถ้ามีคนอยู่ในห้อง media-plane union
> (BUG #50) จะยังโชว์ tile ของคนนั้น panel เลยดูเหมือน meeting ปกติ จับไม่ได้

## สิ่งที่แก้

### 1. claim โซนจาก tile จริง ไม่ใช่ `settledTile` — ตัดต้นเหตุ

`views/user/virtual-office/utils/zone-helpers.ts` — เพิ่ม pure helper `chatSpaceZoneReport()`

```ts
chatSpaceZoneReport(activeZone, liveZoneId) => { suppressed, zoneId }
```

- `suppressed` ยังคง derive จาก `activeZone` — server ไม่ validate flag นี้ และการฆ่า
  proximity pop ให้เร็วคือพฤติกรรมที่ต้องการ (#56 ยังทำงานเดิมครบ)
- `zoneId` (= ตัวที่เป็น **claim**) ยิงเฉพาะเมื่อ `liveZoneId === activeZone.id` เท่านั้น →
  ระหว่างเดินรายงาน `""` (ค่าเดียวกับตอน leave) แล้ว claim จริงจะออกตอนไปถึง ซึ่งเป็นจังหวะที่
  server verify ได้

`hero-virtual-office.tsx` — เพิ่ม `liveZoneId` memo (จาก `debugMyTile`) และให้ effect
`chat_space:zone` เรียก helper ตัวนี้ (deps: `[activeZone, liveZoneId]`)

### 2. click-walk รอดจาก force_sync — ชั้นกันพลาด

`zyra-engine/pixi-game/scene.ts` — เติมฝาแฝดของ seat-resume ให้ click-walk ที่ไม่มี seat intent:

| ของใหม่ | หน้าที่ |
|---|---|
| `_clickWalkGoal` / `_clickWalkResumeLeft` | จำ world point ที่คลิก + budget (arm = 1 ต่อคลิก) |
| arm ใน branch click พื้นว่าง | เฉพาะ click-walk ที่ไม่มี seat intent |
| clear ใน `_retirePathWalk()` | ทุกทางที่ walk จบปกติ (arrival / cancel / WASD interrupt / locked-zone abort / stuck detector) ทิ้ง budget ทันที |
| `_resumeClickWalk()` ใน `forceSyncLocalPlayer` | re-pathfind จากตำแหน่ง**ที่ถูกแก้แล้ว** ไปยัง tile ที่คลิก + `_firePathStarted` (hero ส่ง `goto` ใหม่ → server ทิ้ง route เดิม) |

เงื่อนไขความปลอดภัย:

- **one shot ต่อคลิก** — `_retirePathWalk()` zero budget ไปแล้วก่อน resume → correction loop
  ถอยไปเป็นพฤติกรรมเดิม (ยืนนิ่ง) ไม่ใช่เดินวนไม่จบ
- **re-pathfind จากตำแหน่งใหม่** → การ reject เชิงตำแหน่งจริง (`blocked_dest` / `invalid_path` /
  `wall_crossing`) ได้ route ที่สั้นลงและถูก validate ใหม่ ไม่ใช่ retry route ที่ถูกปฏิเสธ
- **seat branch มาก่อน** (`else if`) → เก้าอี้ยังใช้ `_resumeSeatIntent` เดิม ไม่มี walk ซ้อน
- `blockWalk` (follow mode) ยังห้าม self-walk เหมือนเดิม
- scope แค่ click-walk (`pathFromMouse` + ไม่มี `_pendingSeat`) — `walkToTile` (follow / zone join /
  "go to" คน) ไม่ถูกแตะ

## Test

| ไฟล์ | ครอบอะไร |
|---|---|
| `__tests__/vo-chat-space-zone-claim.test.ts` (ใหม่, 10 เคส) | `chatSpaceZoneReport` — suppression ตาม activeZone (4 zone type), claim ต้องรอ tile จริง, ไม่ claim ตอน walk in-flight (เคส regression ตรงตัว), ไม่ claim meeting/spotlight, ไม่ claim โซนที่เดินออกมาแล้ว |
| `__tests__/pixi-game-scene.test.ts` → `describe("click-walk survives force_sync")` (5 เคส) | re-issue walk หลัง force_sync, resume ครั้งเดียวต่อคลิก, ไม่ resume walk ที่จบปกติแล้ว, seat branch ยังชนะเมื่อมี sit intent, ปลายทางยังเป็น tile ที่คลิก |

รวม: `npx vitest run` → 101 files / 1287 passed · `npx tsc --noEmit` สะอาด (เหลือ error เดิม 2 ตัว
ใน `pixi-game-scene.test.ts` เรื่อง `avatar_url` ที่มีอยู่บน develop ก่อนแล้ว) · eslint + prettier ผ่าน

## Live verify (2026-09-01)

Stack: `next build` + `next start -p 3200` (prod build ของ branch นี้) → zyra-api local :3002 → dev DB ·
zyra-ws ของตัวเองที่ :3103 (`ALLOWED_ORIGINS='*'`) · workspace `office`
(`256893ae-…`) · user `member-a@zyra.test` · **Meeting Group 6** (tiles 15,26→25,33) →
**Private Group 9** (tiles 15,19→19,22), click พื้นว่าง tile `17,21`

> **ต้องทำก่อน repro:** local Redis ไม่มี key `vo:zones:<workspaceId>` (zyra-api publish เฉพาะตอน
> zone CRUD) → `getZoneSet()` = nil → `zoneClaimTileOK` **fail open** → server ไม่เคยส่ง force_sync
> และบั๊กไม่ขึ้นเลย ต้อง publish zone set ก่อน (มิรเรอร์ `publishZoneCache` จาก DB) ไม่งั้นการทดสอบ
> จะ "ผ่าน" แบบหลอกๆ

ทั้ง 3 เคสรันบน build เดียวกัน ต่างกันแค่ปิด/เปิดฟิกซ์ทีละชั้น:

| # | premature claim (fix 1) | click-walk resume (fix 2) | ผล |
|---|---|---|---|
| 1 | ไม่ถูกส่ง (ตามที่ ship) | armed | panel ปิด**ตั้งแต่กลางทาง** (sample แรกที่ tile 18,23), `force_sync` = **0 เฟรม**, ปิดค้าง 6 วิ ✅ |
| 2 | ส่ง claim แบบโค้ดเก่า | armed | ได้ `force_sync{zone_claim_rejected}` ที่ tile `20,27` (ในห้อง meeting) → walk ตาย → resume เดินใหม่ → **panel ปิดเองใน ~1.6 วิ** ✅ |
| 3 | ส่ง claim แบบโค้ดเก่า | ถอด `_clickWalkGoal` ออก | **panel ค้าง 7 วิ+ ไม่หาย** — header `Meeting Group 6`, สมาชิก `0`, "No one here yet", timer เดิน ขณะตัวละครยืนที่ `17,21` ใน private zone ❌ **= อาการที่รายงานเป๊ะ** |

เคส 3 คือหลักฐานว่า mechanism ถูกต้องทั้งเส้น: `pathQueue` เหลือ 0 ทันทีที่ force_sync มา (walk ตาย
ไม่มี `onPathEnded`) แต่ตัวละคร**ยังไปถึง `17,21`** เพราะ server เดิน goto ที่ถูกทิ้งต่อแล้วลากด้วย
self-sync — ตรงกับที่วิเคราะห์ไว้ทุกข้อ

เคส 2 ยังยืนยันว่า fix 2 เป็น safety net จริง ไม่ใช่โค้ดตาย: ถึงจะมี hard correction กลางทาง
(เหตุผลอื่นก็ได้ — `blocked_dest`, `visibility_resume`, …) click-walk ก็ไม่ตายเงียบอีก

## ยัง verify ไม่ถึงระดับไหน

- verify บน **local stack (prod build) + dev DB** เท่านั้น — ยังไม่ได้ทดสอบบน dev cluster / uat
- ยังไม่ทดสอบ**หลายคน**พร้อมกันในห้อง (เคสนี้เล่นคนเดียว 1 online) — media-plane union (BUG #50)
  จะเปลี่ยนภาพที่เห็น แต่ไม่เปลี่ยน mechanism
- mic/cam ถูกบล็อกใน Browser pane → ไม่ได้ยืนยันว่า LiveKit session ถูกตัดจริงตอน panel ปิด
  (ตามโค้ดคือ `mediaZoneId` เป็น null ทันทีที่ `activeZone` ออกจาก meeting)
- ยังไม่ได้วัดว่า claim ที่เลื่อนไปออกตอน "ถึงจริง" (ช้าลงเท่าอายุ poll ของ `debugMyTile` ~100ms)
  กระทบจังหวะเกิด proximity pop ในห้อง room/private หรือไม่ — ตามโค้ดคือ pop ผูกกับ claim นี้
  เท่านั้น และเดิม claim ก็ออกตอน `onPathEnded` อยู่แล้ว จึงคาดว่าไม่ต่าง
- ไม่ได้แก้ฝั่ง zyra-ws — `handleChatSpaceZone` ยังตอบ `force_sync` เมื่อ verify claim ไม่ได้
  (ถูกต้องแล้วสำหรับ client ที่ claim จริงๆ ผิด) ถ้าอนาคตอยากผ่อน ให้พิจารณา "ถือ claim ไว้เฉยๆ
  ถ้า client มี goto in-flight ที่ปลายทางอยู่ในโซนที่ claim"

## จุดที่ควรระวังต่อ (สำหรับรอบหน้า)

- **`activeZone` ≠ ตำแหน่งจริง** โดยดีไซน์ (#56 ให้มันวิ่งนำ) → อะไรที่ต้อง "ยืนยันตำแหน่ง" กับ
  server ต้องใช้ tile จริงเสมอ ไม่ใช่ `activeZone` / `settledTile`
- **`force_sync` ฆ่า walk โดยไม่ยิง `onPathEnded`** — ทุกอย่างที่ผูก state ไว้กับ `onPathEnded`
  (`settledTile` = zone entry/exit ทั้งระบบ) จะค้างเงียบทุกครั้งที่มี hard correction กลางทาง
- อย่าแก้อาการนี้ด้วยการทำให้ `activeZone` derive จาก tile จริง — จะย้อน #56 (media session
  ไม่ยอมตัดตอนเดินออก) กลับมาทั้งดุ้น
