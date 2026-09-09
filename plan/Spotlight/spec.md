# Spotlight — Virtual Office — Spec

> ดึงข้อมูลจาก ClickUp — Space: Zyra World, List: `901614367195`
> Parent Task: [[Feature] Spotlight — Virtual Office](https://app.clickup.com/t/36898257/86d46qtnj) (`86d46qtnj`) · tag `client` · status **in progress** · priority **high** · sprint points **6** · assignees `rif fullstack`, `P A` · creator Moss Pm
> Subtask 14 ใบ: HP-01 และ EC-01 **closed** · อีก 12 ใบยังเปิด (`pending` 11, `open` 1) · HP-01~09 priority high · EP-01~02 และ EC-01~02 normal · EC-03 low
>
> **สถานะเอกสาร: ถอด parent และ description ของ subtask ครบทั้ง 14 ใบ ณ 2026-09-07 — ล่าสุดผู้ใช้ยืนยัน Start UX: เข้า Spotlight ยังไม่ broadcast; ต้องกดปุ่ม Play บน HUD ก่อน**
> **ความพร้อม: ยังไม่ควรเริ่ม implement ตาม spec ใหม่นี้ทั้งก้อน** — Spotlight รุ่นปัจจุบันเป็น floor-wide audio broadcast และขัดกับ card หลายจุด ดู [§6](#6-ความต่างจากระบบปัจจุบัน-ตรวจโค้ด-2026-09-07) และ [§7](#7-เรื่องที่ต้องเคาะก่อน-implement)
> **repo ที่คาดว่ากระทบ:** `zyra-app`, `zyra-ws`, `zyra-api` และอาจมี `zyra-notifications` หาก Notification Bell ต้อง durable/offline
>
> §1–§5 คง requirement ตาม ClickUp แม้บางใบขัดกันเอง ส่วนข้อวิเคราะห์และคำถามแยกไว้ §6–§10 เพื่อไม่ให้ปะปนกับต้นฉบับ

---

## 1. Overview (parent card)

### Decision — 2026-09-08, Meeting-wide Join (user approved)

สมาชิกคนใดใน Meeting กด Join Spotlight จะเป็นการยอมรับสำหรับ Meeting เดียวกันทั้งหมด สมาชิกยังอยู่ใน Meeting และคุยต่อได้ หน้าจอใช้ Spotlight ด้านบนและ meeting tiles/toolbar ด้านล่าง ตาม Figma node `5485:899345`; toast ขนาดกระชับอยู่มุมบนขวา

### Decision — 2026-09-09, Notification Bell = durable (user approved, §7 ข้อ 14)

Bell ของ Spotlight เป็น **durable** ไม่ใช่ client session: เก็บใน `tb_notification` เพื่อให้ค้างข้าม refresh/เครื่อง และมี read state จริง ตาม EC-02

Contract:

- Type ใหม่ `spotlight_live` ใน `tb_notification` (migration 98) + column `spotlight_session_id UUID` และ `spotlight_ended_at TIMESTAMPTZ`
- `zyra-ws` เป็นเจ้าของ session state: สร้าง `session_id` (UUIDv4) เมื่อ speaker set ของ floor ว่าง → ไม่ว่าง และลบเมื่อว่างอีกครั้ง; ส่ง `session_id` ไปกับ `ws:spotlight:stateUpdate` ทุกครั้ง (รวม snapshot ตอน reconnect) และเป็น `""` เมื่อไม่มี broadcast
- `zyra-ws` → `zyra-api` ผ่าน internal endpoint (`X-Internal-Secret`, fire-and-forget):
  - `POST /api/internal/spotlight/broadcasts` `{workspace_id, session_id, actor_id, recipient_ids[]}` ตอนเริ่ม
  - `POST /api/internal/spotlight/broadcasts/:sessionId/end` `{workspace_id}` ตอนจบ → set `spotlight_ended_at` ของ session นั้นและ push row ที่อัปเดตแล้ว
- **Recipients = สมาชิกที่อยู่บน floor ที่ broadcast ตอนเริ่ม ยกเว้นผู้ broadcast** — คงพฤติกรรม floor-scoped ของ Spotlight ปัจจุบัน (§7 ข้อ 5 workspace-wide ยังไม่เคาะ) และทำให้ปุ่ม Join มีความหมายกับคนที่ได้รับจริง
- สร้าง row เฉพาะเมื่อ session เพิ่งเปิดและ `notify=true` — reconnect re-assert (`notify=false`) ไม่สร้างซ้ำ
- Row เป็น `email_suppressed` เสมอ (ไม่เข้า chat digest) และ push ผ่าน `vo:notify` → `chat:notification:new` เดิม
- Client จะ Join ได้เฉพาะเมื่อ `spotlight_session_id` ของ row ตรงกับ `session_id` ที่ live อยู่ตอนนั้น ไม่เช่นนั้นแสดง `spotlightEndedBeforeJoin` — กันการเปิด session ใหม่ของ marker เดิมผิดตัวตาม EC-02
- ยังไม่ตัดสิน: retention/ลบประวัติ (§7 ข้อ 8/18), offline/cross-floor delivery และ setting เปิด-ปิดการแจ้งเตือนนี้

Contract: client sends `ws:spotlight:meetingJoin` with `{room_id: string}`. Matching `MediaRoomID` is authoritative membership evidence; before the media handshake, published Meeting geometry plus the caller's claimed tile is the fallback. An active Spotlight on the caller's floor is required. Invalid requests use the existing error envelope. Any member may accept; no owner restriction. Server includes `accepted_meeting_ids: string[]` in existing floor `ws:spotlight:stateUpdate` messages (including reconnect snapshots). Clients apply acceptance only when their current meeting ID matches and do not treat Join as successful before that snapshot confirms it. Duplicate requests are idempotent.

Acceptance remains room-level and can be reversed with `ws:spotlight:meetingLeave {room_id: string}`. Leave is idempotent and broadcasts an updated snapshot. The server also revokes acceptance when the room's final media member leaves, preventing a later unrelated group in the same Meeting zone from inheriting it. The floor's final broadcaster stopping/disconnecting still clears all accepted rooms. State is ephemeral and floor-scoped, with no DB migration. Missing `accepted_meeting_ids` from older servers means an empty list. Meeting media is never left by accepting; Stop listening revokes the room acceptance and is distinct from hiding the Spotlight stage.

Spotlight คือ Stage สำหรับการนำเสนอใน Virtual Office ผู้ดูแลวาง Spotlight marker ผ่าน Map Editor และสมาชิก Workspace เดินเข้า marker เพื่อเริ่ม Spotlight session

### แนวคิดหลัก

- Admin วาง marker บน map ได้มากกว่า 1 จุด
- สมาชิก Workspace ทุกคนมีสิทธิ์ขึ้น Stage ตาม card ปัจจุบัน
- เมื่อเข้า marker ต้องยืนยันก่อนเริ่ม session
- marker คนละจุดมี presenter พร้อมกันได้
- Spotlight สื่อสารระดับ Workspace ไม่ใช่เฉพาะผู้ที่อยู่ใกล้ marker
- ผู้ที่ไม่ได้ Meeting/Conversation เห็น Spotlight แบบเต็มจอทันที
- ผู้ที่อยู่ใน Meeting/Conversation เห็น toast ก่อน และเลือกเปิดเป็น second session ได้
- Presenter ใช้กล้อง, screen share และ Workspace Chat ได้
- เมื่อ Spotlight เริ่ม share ระบบหยุด meeting screen share ตาม HP-06/EP-01

### Persona และสิทธิ์

| Persona | ความสามารถตาม card |
|---|---|
| Workspace Admin / System Admin | วางและตั้งค่า marker ใน Map Editor |
| Workspace Member | เดินเข้า marker และยืนยันขึ้น Stage |
| Spotlight Presenter | ควบคุม mic, camera, screen share, chat, viewer count และออก Stage |
| Viewer ที่ไม่ได้ Meeting | เปิด Spotlight เต็มจอทันที และกลับ Virtual Office ได้ |
| Viewer ที่กำลัง Meeting/Conversation | รับ toast และเลือกดูเป็น second session หรือดูภายหลังจาก Bell |

> Card ไม่กำหนด role restriction, approval, moderation หรือจำนวน presenter สูงสุด จึงห้ามเพิ่มเองจนกว่า PM จะยืนยัน

### ในขอบเขต

- marker placement, save และ hot reload
- prompt/confirmation ก่อนขึ้น Stage
- lifecycle: start, active, leave, disconnect, reconnect, auto-end
- normal viewer, meeting viewer และ state restoration
- camera, screen share, audio, chat และ viewer count
- หลาย marker/หลาย presenter
- Toast, Notification Bell, minimap และ marker Idle/Active
- `spotlight_markers` ใน `map.json` และ `spotlight_sessions`

### ไม่พบใน card

- recording/replay, schedule, moderator/host approval, kick presenter, stage capacity
- cross-workspace broadcast และ mobile/tablet interaction
- API/WS payload/error contract ที่สมบูรณ์
- Figma node หรือ design link สำหรับ surface ใหม่

## 2. กฎการแสดงผลและ Media (parent card)

### Display matrix

| สถานะ Viewer | พฤติกรรม |
|---|---|
| ไม่ได้ Meeting/Conversation | เปิด Spotlight full screen ทันที |
| อยู่ Private Zone หรือ non-meeting zone | เปิด Spotlight full screen ทันที |
| อยู่ Meeting Zone / Conversation | แสดง toast; กดดูแล้วเปิด second session |
| กด `เดี๋ยวก่อน`/X | Meeting ไม่เปลี่ยน และเปิดภายหลังจาก Bell ได้ |
| เข้า radius แต่ยังไม่ยืนยัน | แสดง prompt เท่านั้น ไม่สร้าง session |
| marker ว่าง | ไม่สร้าง media session และไม่ส่ง notification |

### Audio / Video matrix

| ผู้ใช้/สถานะ | Audio | Video/Share |
|---|---|---|
| Spotlight Presenter | ได้ยิน ambient Workspace; meeting audio เป็นอีก session | กล้องเป็นจอแรกของ Spotlight |
| Presenter ที่อยู่ทั้ง Meeting และ Spotlight | parent ระบุว่า “ไม่ได้ยิน spotlight audio” | Viewer เห็นกล้อง presenter เป็นจอแรก |
| Meeting viewer ที่กดดู | HP-05 ระบุว่าได้ยินทั้ง meeting และ Spotlight | Spotlight panel หลัก; meeting tiles ยังทำงาน |
| มี meeting share แล้ว Spotlight เริ่ม share | meeting share ถูกปิดทันที | Spotlight share เป็น main content |

### Camera / Screen Share

- Spotlight มี 1 presenter ต่อ marker
- Camera only → camera เป็น main content
- Share only → share เป็น main content
- Camera + share → share ใหญ่, camera เป็น PiP ขวาล่าง
- ไม่มีทั้งคู่ → placeholder ชื่อ presenter + `กำลัง Present...`
- Presenter ไม่ถูกเพิ่มเข้า Meeting video grid
- หลาย session share พร้อมกันได้เพียง Stage เดียว; Stage ที่เริ่มก่อนมี priority

## 3. Data model ตาม ClickUp

### `spotlight_markers` ใน `map.json`

```json
{
  "id": "spl-001",
  "type": "marker",
  "marker_type": "spotlight",
  "x": 320,
  "y": 256,
  "properties": {
    "label": "Stage A",
    "color": "#F59E0B",
    "icon": "spotlight",
    "interaction_radius": 2
  }
}
```

`id` ต้องคงที่และถูกใช้ร่วมกันใน session, notification, chat badge และ minimap ส่วน radius ใน JSON เท่ากับ 2 แต่ HP-01/HP-02 พูดถึง 1 tile

### `spotlight_sessions`

| Field | Type | ความหมาย |
|---|---|---|
| `id` | UUID PK | session identifier |
| `workspace_id` | UUID FK | Workspace ของ session |
| `marker_id` | VARCHAR(50) | marker ที่ใช้งาน |
| `presenter_id` | UUID FK → users.id | Presenter |
| `status` | ENUM | `active` / `ended` |
| `screen_sharing` | BOOLEAN | สถานะ share |
| `camera_on` | BOOLEAN | สถานะกล้อง |
| `started_at` | TIMESTAMP | เวลาเริ่ม |
| `ended_at` | TIMESTAMP NULL | เวลาจบ |

Card ยังไม่กำหนด FK target ของ Workspace, unique/index, expiry, retention/history, timezone และวิธีอ้าง `marker_id` ไป `map.json`

## 4. Scenarios

| ID | Scenario | Type | Priority | Status |
|---|---|---|---|---|
| [HP-01](https://app.clickup.com/t/36898257/86d46qtt9) | Admin วาง Spotlight Marker บน Map | Happy | high | closed |
| [HP-02](https://app.clickup.com/t/36898257/86d46qtwr) | User เข้า Spotlight Zone | Happy | high | pending |
| [HP-03](https://app.clickup.com/t/36898257/86d46qu3a) | User ที่ไม่ได้ Meeting เห็น Spotlight | Happy | high | pending |
| [HP-04](https://app.clickup.com/t/36898257/86d46qu7q) | คนใน Meeting ได้รับ Notification | Happy | high | pending |
| [HP-05](https://app.clickup.com/t/36898257/86d46que8) | คนใน Meeting กดดู — Second Session | Happy | high | pending |
| [HP-06](https://app.clickup.com/t/36898257/86d46quhj) | Spotlight เริ่ม Share — ปิด Meeting Share | Happy | high | pending |
| [HP-07](https://app.clickup.com/t/36898257/86d46qupt) | Spotlight Camera — จอแรกใน View | Happy | high | pending |
| [HP-08](https://app.clickup.com/t/36898257/86d46quut) | Spotlight Chat — Workspace-wide | Happy | high | pending |
| [HP-09](https://app.clickup.com/t/36898257/86d46quy1) | User ออกจาก Spotlight Zone | Happy | high | pending |
| [EP-01](https://app.clickup.com/t/36898257/86d46qv22) | หลาย User/หลาย Marker พร้อมกัน | Error | normal | pending |
| [EP-02](https://app.clickup.com/t/36898257/86d46qv5n) | Presenter Disconnect กลางคัน | Error | normal | pending |
| [EC-01](https://app.clickup.com/t/36898257/86d46qvbv) | เข้า Spotlight ขณะ Share ใน Meeting | Edge | normal | closed |
| [EC-02](https://app.clickup.com/t/36898257/86d46qvff) | ปฏิเสธ Toast แล้วดูจาก Bell | Edge | normal | pending |
| [EC-03](https://app.clickup.com/t/36898257/86d46qvn2) | Marker Idle vs Active | Edge | low | open |

> HP-07 ชื่อ task ใช้ “Spotlight View” แต่ heading ใน description ใช้ “Meeting” เอกสารยึด behavior ในรายละเอียด: กล้องอยู่ Spotlight view และ Bob ไม่อยู่ Meeting grid

## 5. รายละเอียดต่อ Scenario (ตาม ClickUp)

### HP-01 · Admin วาง Spotlight Marker บน Map

**Persona:** Workspace Admin / System Admin  
**Pre-condition:** อยู่ใน Map Editor (SC-AWM)

#### Scenario Steps

1. เลือก `Spotlight Marker` จาก toolbar
2. คลิกจุดบน map เพื่อวาง marker
3. marker แสดง icon สีเขียว
4. ตั้ง label และ interaction radius (default = 2)
5. วางได้หลายจุด เช่น Stage A/B
6. Save แล้ว Virtual Office hot reload ทันที

#### Acceptance Criteria / Rules

- เป็นเครื่องมือแยกจาก Meeting/Private Zone
- icon มี pulse สีเขียว, วางได้ไม่จำกัด, walkable และไม่ block avatar
- Card ภาพประกอบพูดถึง radius 1 tile ซึ่งขัดกับ default 2
- สีเขียวขัดกับ JSON/EC-03 ที่ใช้เหลือง `#F59E0B`

### HP-02 · User เข้า Spotlight Zone

**Persona:** Workspace Member  
**Pre-condition:** map มี marker และ user อยู่ใน radius

#### Scenario Steps

1. เมื่อเดินเข้า Spotlight ให้แสดงปุ่ม Play ที่ด้านขวาของ HUD โดยยังไม่เริ่ม broadcast
2. User กด Play เพื่อยืนยันเริ่ม broadcast
3. หลังจากกดแล้ว Server สร้าง session
4. Broadcast `⭐ [ชื่อ user] กำลัง Present บน Stage`
5. Viewer ไป HP-03 หรือ HP-04 ตามสถานะ

#### Acceptance Criteria / Rules

- ปุ่ม Play บน HUD เป็น Start action ที่ยืนยันล่าสุด; flow prompt ใกล้ avatar/ปุ่ม E จาก card เดิมตกไปสำหรับจุดนี้
- เดินเข้าอย่างเดียวยังไม่สร้าง sessionและห้ามส่ง `ws:spotlight:start`; กด Play แล้ว start ต้อง idempotent
- HUD แสดง `⭐ LIVE — [Stage name]`, viewer count, mic/camera/share/chat/leave
- Avatar presenter มี glow ring; marker คนละจุด active พร้อมกันได้
- Card ไม่บอกว่าคนเดียวขึ้นหลาย Stage หรือ marker เดียวรับหลายคนได้หรือไม่

### HP-03 · User ที่ไม่ได้ Meeting เห็น Spotlight

**Persona:** Member ที่ไม่ได้ Meeting/Conversation  
**Pre-condition:** มี session active

#### Scenario Steps / Acceptance Criteria

1. รับ broadcast แล้วเปิด full-screen Spotlight ทันทีโดยไม่ถาม
2. Private Zone/non-meeting zone ก็ถูก view นี้แทน
3. แสดง camera/share, Stage, presenter, viewer count และ Workspace Chat ด้านขวา
4. กด `กลับ Virtual Office` ได้โดยไม่หยุด Spotlight ของคนอื่น
5. ถ้ามีหลาย session มี switcher `Stage A | Stage B | ...`

Card ไม่กำหนด default/order ของ Stage หรือช่องทางกลับเข้าดูหลังออก full-screen

### HP-04 · คนใน Meeting ได้รับ Spotlight Notification

**Persona:** Member ที่กำลัง Meeting/Conversation

#### Scenario Steps / Acceptance Criteria

1. ไม่เปิด full-screen ทับ meeting
2. Toast มุมขวาบนใต้ meeting header: `⭐ Bob กำลัง Present บน Stage A`
3. มี `ดู Spotlight`, `เดี๋ยวก่อน`, X และ headline/topic ถ้ามี
4. Toast ไม่บัง tiles/ไม่หยุด media และค้าง 15 วินาที
5. Dismiss แล้วเก็บใน Notification Bell
6. หลาย Spotlight ให้ queue ทีละรายการ ไม่ overlap และไม่ซ้ำจาก reconnect

### HP-05 · คนใน Meeting กดดู — Second Session

**Persona:** Meeting participant ที่กด `ดู Spotlight`

#### Scenario Steps / Acceptance Criteria

1. เปิด Spotlight เป็น second session โดยไม่ออก meeting
2. Spotlight เป็น panel หลัก; meeting tiles ย่อเป็นพื้นที่รอง
3. ได้ยิน meeting และ Spotlight พร้อมกัน; presenterไม่ได้ยิน meeting ผ่าน Spotlight
4. Workspace Chat และ viewer count ยังใช้งานได้
5. `กลับ Meeting เต็มจอ` แล้วย่อ Spotlight เป็น PiP ขวาล่าง
6. ปิด Spotlight แล้ว meeting เดิมต้องไม่เสีย state
7. Second-session connect failure ห้ามทำ meeting หลุด

Card ไม่กำหนดสัดส่วน layout, volume, ducking หรือ echo prevention

### HP-06 · Spotlight เริ่ม Screen Share — ปิด Meeting Screen Share

**Pre-condition:** มี meeting share ทำงาน และ Spotlight presenter เริ่ม share

#### Scenario Steps / Acceptance Criteria

1. Carol กำลัง share ใน Meeting A; Bob เริ่ม Spotlight share
2. ระบบหยุด share ของ Carol ทันที และ Carol เห็น toast เหตุผล 10 วินาที/ปิด X ได้
3. Card ระบุให้หยุด **ทุก meeting screen share ใน Workspace**
4. Bob's share เป็น main content; meeting audio/video ยังทำงาน
5. เมื่อ Spotlight หยุด share ผู้ใช้ meeting เริ่ม share ใหม่ได้ แต่ไม่กลับเอง

> Cross-meeting stop เป็นผลกระทบสูง ต้องยืนยัน scope/authority ก่อน implement

### HP-07 · Spotlight Camera — จอแรกใน Spotlight View

**Persona:** Meeting participant ที่รับ second session  
**Pre-condition:** Presenter เปิดกล้องและ viewer ยอมรับ Spotlight

#### Acceptance Criteria

- camera on → กล้องเป็น main content ทันที
- camera off → placeholder `กล้องปิด` + ชื่อ presenter
- share + camera → share ใหญ่, camera PiP ขวาล่าง
- Bob ไม่อยู่ Meeting video grid; meeting tiles เดิมไม่เปลี่ยน
- viewer count เปลี่ยนเมื่อ join/leave

| State | Main | Secondary |
|---|---|---|
| Camera only | Camera | — |
| Share only | Screen share | — |
| Camera + share | Screen share | Camera PiP |
| ไม่มีทั้งคู่ | ชื่อ + `กำลัง Present...` | — |

### HP-08 · Spotlight Chat — Workspace-wide

**Persona:** Presenter และสมาชิก Workspace  
**Pre-condition:** session active และมี Workspace Chat เดิม

#### Scenario Steps / Acceptance Criteria

1. Presenter เปิด chat จาก HUD/view และส่งเข้าช่อง Workspace เดิม
2. ข้อความระหว่าง live มี badge `⭐ [Stage A]`
3. ทุกคนเห็นข้อความเดียวกันจาก VO, Meeting หรือ Spotlight
4. คนที่ยังไม่กดดู Spotlight ก็เห็นผ่าน Workspace Chat ปกติ
5. หลังออก Stage ข้อความใหม่ไม่ติด badge แต่ข้อความเก่าคง badge
6. ประวัติเก็บด้วยระบบ Workspace Chat ปกติ

ดังนั้น stage/session context ต้องถูก snapshot ตอนสร้าง message มิฉะนั้น badge ย้อนหลังจะเปลี่ยนหรือหาย

### HP-09 · User ออกจาก Spotlight Zone

**Persona:** Presenter  
**Pre-condition:** session active

#### Scenario Steps

1. กด `ออก Stage` หรือเดินออก radius
2. ถาม `ออกจาก Stage A? Spotlight จะสิ้นสุด`
3. Confirm แล้วจบ session
4. Broadcast `⭐ Spotlight จบแล้ว — Stage A`
5. Viewer กลับ VO/Meeting เดิม

#### Acceptance Criteria / Transition

- Full-screen viewer กลับ VO แบบ smooth ไม่ blank
- Second-session viewer ปิด Spotlight panel, meetingกลับเต็ม และเห็น toast
- Toast `⭐ Stage A สิ้นสุดแล้ว` ค้าง 3 วินาที
- เดินออกต้อง confirm ถ้า `auto-exit on leave = enabled`
- Card กล่าวถึง setting นี้แต่ไม่บอก owner/default หรือ state ระหว่างรอ confirm

### EP-01 · หลาย User เข้า Spotlight หลาย Marker พร้อมกัน

**Type ใน card:** Error Path  
**Trigger:** Bob เข้า Stage A (`spl-001`) และ Alice เข้า Stage B (`spl-002`) พร้อมกัน

#### Acceptance Criteria

- แต่ละ session independent; viewer เห็น `⭐ Stage A (Bob) | ⭐ Stage B (Alice)`
- Toast ทั้งสอง Stage ขึ้นครั้งเดียวและไม่ overlap
- Presenter ทั้งสองใช้ Workspace Chat เดียวกันพร้อม badge Stage แยก
- Stage ที่เริ่ม share ก่อนได้ priority
- Stage ถัดไปถูกปฏิเสธด้วย:

```text
⚠ ไม่สามารถ screen share ได้
Stage A (Bob) กำลัง screen share อยู่
```

Global share lock ต้อง release เมื่อ stop/end/disconnect/timeout และกัน race ตอนเริ่มพร้อมกัน

### EP-02 · Presenter Disconnect กลางคัน

**Trigger:** network หลุด/browser crash ขณะ active

#### Case A — Reconnect ภายใน 2 นาที

1. Server รักษา session เดิม
2. Viewer เห็น `⏸ Spotlight หยุดชั่วคราว — รอ presenter กลับมา`
3. Reconnect แล้ว resume โดยไม่สร้าง session ใหม่
4. Toast `▶ Bob กลับมาแล้ว — Spotlight ดำเนินต่อ`

#### Case B — เกิน 2 นาที

1. Server auto-end
2. Broadcast `⭐ Stage A สิ้นสุดแล้ว (presenter disconnect)`
3. Viewer กลับ VO/Meeting

Chat history ต้องอยู่ครบ และ meeting share ที่เคยถูกปิดห้ามกลับอัตโนมัติ

### EC-01 · เข้า Spotlight ขณะ Share ใน Meeting

**Trigger:** Bob กำลัง share ใน Meeting แล้วเข้า Spotlight

#### Scenario / Acceptance Criteria

1. ก่อน confirm เตือนว่าการขึ้น Stage จะปิด meeting share
2. ปุ่มคือ `ยกเลิก` และ `ขึ้น Stage และปิด Share`
3. Confirm แล้วปิด share ของ Bob และ Bob เปิด Spotlight share ได้ทันที
4. Bob เห็น `⚠ การแชร์หน้าจอใน Meeting ของคุณถูกปิด เนื่องจากคุณเข้า Spotlight`
5. Meeting participants เห็น `Bob หยุด screen share`
6. เมื่อออก Stage share เดิมไม่กลับเอง

### EC-02 · ปฏิเสธ Toast แล้วดูจาก Bell

**Trigger:** User กด `เดี๋ยวก่อน` หรือ X

#### Acceptance Criteria

- Meeting ดำเนินต่อ; user ไม่ join และไม่ถูกนับ viewer
- Bell แสดง `⭐ Stage A — Bob (🔴 LIVE)` พร้อม `ดู Spotlight`
- ถ้ายัง live คลิกแล้วเปิด second session ตาม HP-05
- ถ้าจบแล้วแสดง `สิ้นสุดแล้ว` และปุ่ม disabled
- Card ไม่กำหนด retention, read/unread, offline delivery หรือ sync ข้าม device
- Notification ต้องอ้าง session ID เพื่อไม่เปิด session รอบใหม่ของ marker เดิมผิดตัว

### EC-03 · Marker Idle vs Active

| State | Visual | Hover | Server/WS |
|---|---|---|---|
| Idle | `⭐ Stage A`, pulse ช้า สีเหลืองอ่อน | `เดินเข้าเพื่อ Present` | client-side; ไม่มี idle event |
| Active | `⭐ Stage A 🔴 LIVE`, pulse เร็ว สีเหลืองสว่าง, ชื่อ presenter | `Bob กำลัง Present อยู่` | manage session + broadcast |
| หลาย marker ว่าง | แสดงทุก markerปกติ | ราย marker | ไม่ notification |

Minimap ใช้ ⭐ dot: idle เหลืองอ่อน/active เหลืองสว่าง; marker ต้องไม่ block avatarหรือรบกวน workflow

## 6. ความต่างจากระบบปัจจุบัน (ตรวจโค้ด 2026-09-07)

Spotlight ปัจจุบันคือ “ประกาศเสียงทั้ง floor จาก spotlight tile” ไม่ใช่ presentation stage ตาม card ชุดนี้

| เรื่อง | ปัจจุบัน | ClickUp | Gap |
|---|---|---|---|
| Map | `tb_map_zone`, rectangle/tile | marker ใน `map.json` + radius | ต้องเลือก source of truth/migration |
| Start | ยืน tile แล้ว unmute | เข้า tile → แสดง Play บน HUD → กดแล้วเริ่ม session | เปลี่ยนเป็น explicit-start gate |
| Identity | `spotlight:<floorId>`, state floor+user | workspace+marker+session | contract ใหม่ |
| Scope | floor-only | Workspace-wide | อาจต้องข้าม floor/map |
| Media | audio-only; cameraถูก block | mic+camera+share | client/SFU งานใหญ่ |
| Normal viewer | auto-listen + banner mute | full-screenทันที | view/state restore ใหม่ |
| Meeting viewer | block notification/listener | toast + second session | behaviorตรงข้าม |
| End | mute/เดินออก = stop | leave/ออก radius + confirm | mute semanticsขัดกัน |
| State | in-memory speaker set | `spotlight_sessions` + grace | persistenceต้องเคาะ |
| Multi-stage | ไม่มี marker identity | switcher/sessionแยก | ของเดิมแยก Stageไม่ได้ |
| Viewer count | ไม่มี | realtime/session | protocolใหม่ |
| Notification | 8 วินาที; mute/dismiss; Bell durable ตาม EC-02 (2026-09-09) | 15 วินาที; accept/later/Bell | เหลือ 15 วินาที + accept/later |
| Share | ไม่มี global precedence | Spotlightหยุด meeting; first Stage wins | distributed authority |
| Disconnect | removeทันที | pause/resume 2 นาที | cleanupใหม่ |

### จุดเดิมที่ควร reuse

- Server occupancy validation ก่อนรับ `start`
- full-state snapshot และ dedupeตอน join/reconnect
- LiveKit subscribe-only listener pattern
- cleanup lifecycle (ปรับเพิ่ม grace period)
- Workspace Chat channel และ UI/media primitives เดิม

### ไฟล์สำคัญ

- `zyra-app/views/user/virtual-office/use-spotlight-broadcast.ts`
- `zyra-app/views/user/virtual-office/components/vo-spotlight-banner.tsx`
- `zyra-app/views/user/virtual-office/components/vo-spotlight-notification.tsx`
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx`
- `zyra-app/lib/api/workspace-ws.ts`, `workspace-ws-types.ts`
- `zyra-ws/internal/hub/spotlight.go`, `message.go`
- `zyra-api/internal/model/map_zone.go`, `service/map_zone_service.go`
- `zyra-api/migrations/34_create_tb_map_zone.sql`

## 7. เรื่องที่ต้องเคาะก่อน Implement

| # | เรื่อง | ต้องเคาะ |
|---|---|---|
| 1 | Marker vs Zone | model ใหม่, แปลงของเดิม หรือคง zone+metadata |
| 2 | Radius | 1 หรือ 2 tiles; หน่วย/boundary |
| 3 | สี | HP-01 เขียว vs JSON/EC-03 เหลือง |
| 4 | Entry | `กด E`, click หรือทั้งคู่; mobile/tablet |
| 5 | Scope | Workspace-wide ข้ามทุก floor/mapจริงหรือไม่ |
| 6 | Capacity | คนเดียวหลาย Stage/markerเดียวหลายคน/occupied error |
| 7 | Full-screen | หลังกลับ VO จะดู sessionเดิมอีกอย่างไร |
| 8 | Audio | mix/mute/duck/volume/echo ต่อ actor |
| 9 | Presenter+Meeting | คงหรือออกจาก meeting session |
| 10 | Stop share | ยืนยันให้หยุดทุก meetingทั้ง Workspaceจริงหรือไม่ |
| 11 | Multi-Stage | default/order/auto-switch เมื่อ Stageจบ |
| 12 | Share lock | owner, race, TTL, reconnect, stale recovery |
| 13 | Viewer count | pending/hidden/PiP/muted/reconnect นับอย่างไร |
| 14 | Bell | **เคาะแล้ว 2026-09-09: durable ใน `tb_notification`** (ดู §1 Decision); เหลือ retention/offline/cross-floor |
| 15 | Walk leave | `auto-exit` default/owner/debounce |
| 16 | Mute | mute คง sessionหรือจบแบบระบบเดิม |
| 17 | Reconnect | identity หลาย tab/device และ resume authorization |
| 18 | Persistence | DB audit/history หรือ live stateใน Redis/WS |
| 19 | Chat badge | snapshot labelหรือ join sessionย้อนหลัง |
| 20 | Design | ต้องมี Figma ของ full-screen, split/PiP, HUD, toast, switcher |

### คำถามสั้นสำหรับ PM

1. Spotlight ข้ามทุก floor จริงไหม และคนที่ไม่ได้เปิด VO ต้องรับด้วยหรือไม่?
2. ใช้ marker ใหม่หรือ Spotlight zone เดิม?
3. radius = 1/2 และสีเขียว/เหลืองอะไรเป็นหลัก?
4. Normal viewerถูกเปิดเต็มจอทันทีจริงไหม; หลังกลับ VO ดูใหม่ตรงไหน?
5. Meeting viewerได้ยินสอง sessionพร้อมกันจริงไหม?
6. Spotlight share ต้องหยุดทุก meeting share ทั้ง Workspaceจริงไหม?
7. ~~Bell ต้อง durable/offline หรืออยู่แค่ client session?~~ → durable (2026-09-09); ยังเหลือ offline/cross-floor delivery และ retention
8. `spotlight_sessions` เก็บประวัตินานเท่าไร?
9. ขอ Figma/approved design ของทุก surface ใหม่

## 8. Realtime / API Contract ที่ต้องออกแบบ

ชื่อ endpoint/event/payload/error ยังไม่มีใน ClickUp ส่วนนี้จึงระบุ capability ไม่ตั้งชื่อ contract แทนทีม

```text
idle → confirming → starting → active
                         ↓
              paused_reconnecting (≤2 นาที)
                    ↙           ↘
                 active       ending → ended
```

### Capability ขั้นต่ำ

- start ด้วย marker ID + request ID; acknowledgement/typed rejection
- validate membership, map/floor และ authoritative geometry
- idempotent end และ full active-session snapshot
- started/updated/paused/resumed/ended + camera/share state
- viewer join/leave หรือ authoritative count
- notification identity สำหรับ dedupe/Bell
- Workspace share lock หากยืนยัน HP-06/EP-01
- grace timer และ stale cleanup

### Security / Correctness

- Client ห้ามประกาศ presenter ID ของคนอื่น
- Server ตัดสิน occupancy, active session, share priority และ end reason
- retry/reconnect ห้าม duplicate session/count/toast
- viewer count ห้ามเชื่อค่าจาก clientโดยตรง
- ห้าม log token, SDP, PII หรือ chat content
- member REST ต้องอยู่ `/api/user/*` ไม่เรียก `/api/admin/*`

### Database ที่ต้องเติมก่อน migration

- FK/cascade, partial unique index, end reason, timezone
- indexesตาม query, retention/cleanup และ restart recovery
- transaction/locking สำหรับ simultaneous start/share priority

## 9. ผลกระทบและลำดับงาน

| Repository | ความรับผิดชอบที่คาดไว้ |
|---|---|
| `zyra-api` | map/session persistence, member auth/query, chat metadataถ้าต้องเพิ่ม |
| `zyra-ws` | authority, Workspace broadcast, occupancy, snapshot, count, share lock, reconnect |
| `zyra-app` | Map Editor, confirm, HUD, full-screen, second session, layout, Bell, chat badge, minimap |
| `zyra-notifications` | เฉพาะ durable/offline Bell |

### ลำดับ PR หลัง requirement นิ่ง

1. Contract/schema: marker/zone, session, WS/API, DB intent
2. API map/session migration/service
3. WS session core, concurrency, reconnect
4. App marker/entry/HUD/normal full-screen
5. Meeting toast/second session/audio policy
6. Camera/share/priority/failure recovery
7. Chat badge/Bell เฉพาะ scopeที่อนุมัติ
8. Multi-Stage hardening, observability และ E2E

แต่ละ PR ต้องเริ่มจาก `develop` และ mergeกลับ `develop` ตาม `rules/17-git-branch-workflow.md`; งานที่พึ่ง contract ห้ามเริ่มก่อนต้นทางนิ่ง

## 10. Test Scope / Definition of Done

### `zyra-app`

- radius prompt, cancel/confirm/duplicate click
- Idle/Active/minimap/hot reload
- full-screen + กลับ VO + multi-Stage switcher
- toast queue/15s/accept/dismiss/Bell
- second-session failure ไม่ทำ meetingหลุด
- camera 4 states, share+PiP, meeting share warning
- leave/smooth restore, reconnect/timeout
- i18n, keyboard, focus trap, reduced motion

### `zyra-ws`

- membership/map/marker/radius/spoof validation
- idempotent start/end และ duplicate connection
- simultaneous presenters/markers และ full snapshot
- viewer count ไม่ double-count
- first-share-wins race + stale lock
- disconnect → pause 2 นาที → resumeเดิม/auto-end
- stopหนึ่ง sessionไม่กระทบอีก session; race detector

### `zyra-api`

- migration constraints/indexes/rollback
- Handler → Service, authorization, typed/sentinel errors
- mock DB; ห้ามใช้ PostgreSQLจริงใน unit test
- service coverage ≥80% สำหรับ logicใหม่

### E2E สำคัญ

1. Presenter + normal viewer
2. Presenter + meeting viewer accept
3. Dismiss แล้วเปิดจาก Bell
4. สอง presenter/สอง Stage
5. Meeting share ถูกแทนและเริ่มใหม่ได้
6. Disconnect/reconnectก่อนและหลัง 2 นาที
7. Sessionจบแล้วทุก viewerกลับ contextเดิมโดย mediaไม่หลุด

### Definition of Done

- [ ] คำถาม §7 ถูกตอบและบันทึก
- [ ] มี approved design/Figma ทุก surface
- [ ] Marker/Zone และ persistence ถูกเคาะ
- [ ] REST/WS contract มี payload, validation, error, idempotency, reconnect
- [ ] owner/PR dependency ของทุก repo ชัด
- [ ] happy/error/edge, multi-session, reconnect และ race tests ผ่าน
- [ ] ไม่ regression Meeting, Private Zone, proximity chat, Map Editor, Workspace Chat
- [ ] member UI ไม่เรียก `/api/admin/*`
- [ ] ไม่มี secret/PII ใน log และมี lifecycle observability

## Reference

- [ClickUp parent — Spotlight](https://app.clickup.com/t/36898257/86d46qtnj)
- `rules/01-plan.md`, `02-design.md`, `03-develop.md`, `04-test.md`, `05-review.md`
- `rules/09-component-reuse.md`, `12-icons.md`, `14-no-overreach.md`
- `rules/15-member-api-separation.md`, `16-documentation.md`, `17-git-branch-workflow.md`
