# [Module] Real-time Engine

> **ClickUp Task:** [86d2weryr](https://app.clickup.com/t/86d2weryr)
> **Status:** in progress · **Priority:** High · **Assignee:** Ponlawat Lueakaew
> **Location:** Space `90166731836` › Folder `Zyra World` › List `List`

---

## Overview

Module สำหรับ **Real-time Engine** ที่เป็น backbone ของทั้ง system ครอบคลุม 4 Feature:

- **Avatar Position Sync** (ทุก module — Virtual Office + Chat + ทั้งหมด)
- **Room State Management**
- **Mute/Unmute, Camera On/Off**
- **Screen Sharing** (Full screen + Window/Tab)

---

## Scenarios

| ID | Scenario | Type | Status |
|----|----------|------|--------|
| SC-RTE-01 | Avatar Position Sync — ทุก module (Global Presence) | Happy Path | in progress |
| SC-RTE-02 | Avatar Sync — Reconnect / Desync Recovery | Alternate Path | in progress |
| SC-RTE-03 | Room State Management | Happy Path | pending |
| SC-RTE-04 | Room State — Member Join / Leave | Happy Path | pending |
| SC-RTE-05 | Mute / Unmute Audio | Happy Path | pending |
| SC-RTE-06 | Camera On / Off | Happy Path | pending |
| SC-RTE-07 | Screen Sharing — Full Screen | Happy Path | pending |
| SC-RTE-08 | Screen Sharing — Window / Tab | Happy Path | pending |
| SC-RTE-09 | Screen Share — ผู้ชม View | Happy Path | pending |

---

## SC-RTE-01 · Avatar Position Sync — ทุก Module

> [ClickUp](https://app.clickup.com/t/86d2wetb9) · **Type:** Happy Path · **Status:** in progress
> ✅ **Implementation:** สร้างแล้ว ~90% ใน `zyra-ws` — ดู [gap-audit-sc-rte-01.md](gap-audit-sc-rte-01.md). ~~ขีดฆ่า~~ = spec เดิมที่ไม่ตรงโค้ดจริง (reconciled)

**Persona:** User ทุกคนที่ online ใน Workspace
**Pre-condition:** User online อยู่ใน Virtual Office หรือ app ใดก็ได้ใน Workspace

### Scenario Steps
1. User เปิด app หรือเข้า Virtual Office ระบบ connect WebSocket และ register presence
2. Server broadcast presence ของ user ไปยัง Workspace members ทุกคน
3. User เคลื่อนที่ avatar บน map position sync ทุก 50ms (throttle)
4. User เปลี่ยน status broadcast ทันทีทุก module (DM, Sidebar, Member Panel)
5. User ปิด app server broadcast offline ให้ทุกคนภายใน 5 วินาที

### Acceptance Criteria
- Position sync latency < 100ms ในเครือข่ายปกติ
- Status sync ทุก module พร้อมกัน DM, Sidebar, Map, Member Panel
- Avatar position interpolation smooth ฝั่ง client (ไม่กระตุก) ✅
- User offline: avatar หายจาก map ภายใน 5 วินาที ✅
- รองรับ 50 concurrent users ต่อ Workspace ไม่ lag ⚠️ ยังไม่ load test
- Heartbeat ทุก 30 วินาที detect silent disconnect ✅
- ~~Presence sync ระหว่าง browser tabs (same user, multiple tabs)~~ → **evict model:** tab ใหม่แทน tab เก่า (`session_replaced`), 1 connection/user เท่านั้น

### Business Logic / Rules
- WebSocket connection: 1 ต่อ user (**evict model** — tab ใหม่เตะ tab เก่าออก, ไม่รองรับหลาย tab พร้อมกัน)
- ~~Position throttle: 50ms ขณะ moving~~ → **path-based** (`move_to`/`stop`) + server move ticker 20ms + AOI + binary frame (ดีกว่า throttle)
- ~~Status priority multi-tab: DND > Busy > Away > Available~~ → ไม่ใช้ (1 connection/user, last-wins) — ผลจาก evict model
- Heartbeat: WS ping 45s/pongWait 60s + client `heartbeat` 30s (Redis TTL refresh) — detect silent disconnect
- Presence เก็บ Redis; broadcast ในห้องผ่าน AOI (workspace-scoped)

### UX/UI
- [Figma — node 2196-466457](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2196-466457&t=MXeRHTHV9XYUCObQ-0)

---

## SC-RTE-02 · Avatar Sync — Reconnect / Desync Recovery

> [ClickUp](https://app.clickup.com/t/86d2weth9) · **Type:** Alternate Path · **Status:** in progress

WebSocket หลุดชั่วคราว → auto reconnect → full state sync

**Persona:** User ที่ connection หลุดกะทันหัน (Virtual Office / Chat)
**Pre-condition:** User กำลัง online และ active อยู่ใน Workspace แล้ว WebSocket disconnect โดยไม่ตั้งใจ

### Scenario Steps
1. WebSocket connection หลุดกะทันหัน (network drop / server restart / timeout)
2. Client ตรวจจับ `onclose` / `onerror` event ทันที
3. แสดง reconnecting indicator ใน Head-Up Display — non-blocking ทั้ง UI และ game loop
4. Client เริ่ม retry ด้วย exponential backoff: 1s → 2s → 4s → 8s → 16s → 30s (cap)
5. ระหว่าง retry: ข้อความที่ user พิมพ์ถูก queue ไว้ใน memory (max 10)
6. Reconnect สำเร็จ: client ส่ง `ws:presence:connect` พร้อม `ws_token` เดิม
7. Server ตรวจสอบ grace period (2 นาที) — ถ้าผ่าน: rejoin room และ session เดิม
8. Server ส่ง full state: member positions, room states, presence ทั้งหมด
9. ส่ง queued messages, indicator หายไป ทุกอย่างกลับปกติ

### Acceptance Criteria
- Reconnecting indicator แสดงใน Head-Up Display ทันทีที่ disconnect — ไม่บล็อก UI หรือ game loop
- Auto retry exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s — สูงสุด 5 ครั้ง
- Reconnect สำเร็จ: client request full snapshot ทันที ก่อน resume ทุก operation
- Avatar ของ user ยังปรากฏบน map ของ member อื่นตลอด grace period (2 นาที)
- Rejoin ภายใน grace period: กลับ room และ session เดิม ไม่ผ่าน loading screen ใหม่
- Queued messages ถูกส่งทันทีหลัง reconnect สำเร็จ ตามลำดับที่ queue ไว้
- Mute / Camera state คงเดิมหลัง reconnect — ไม่ reset เป็น default
- Proximity chat: rejoin session เดิมถ้ายังอยู่ใน radius และ session ยังไม่ expire
- Retry ครบ 5 ครั้งไม่สำเร็จ: แสดง error banner + ปุ่ม "ลองใหม่" และ "ออกจาก Office"
- เกิน grace period 2 นาที: server clear session — client แสดง modal และ redirect ออก

### Business Logic / Rules
- Grace period: server เก็บ position, `room_id`, mute/camera state ไว้ 2 นาทีหลัง disconnect
- WS token (`ws_token`) อายุ 24 ชั่วโมง — ใช้ reconnect ได้ตลอด session ไม่ต้องขอ token ใหม่
- Message queue: client-side memory สูงสุด 10 messages — เกินนั้น drop oldest
- Snapshot merge: server state ชนะ local state เสมอ (server is source of truth)
- SFU reconnect: ทำงาน parallel กับ WS reconnect ไม่รอกัน
- Heartbeat resume: หลัง reconnect สำเร็จ client เริ่ม heartbeat ping ทุก 30s ทันที
- Multiple tabs: ถ้า tab อื่นของ user เดียวกัน reconnect ก่อน ให้ใช้ session นั้นแทน

### UX/UI
- [Figma — node 2196-491665](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2196-491665&t=MXeRHTHV9XYUCObQ-0)

---

## SC-RTE-03 · Room State Management

> [ClickUp](https://app.clickup.com/t/86d2wetw6) · **Type:** Happy Path · **Status:** pending

**Pre-condition:** Virtual Office มี Rooms กำหนดไว้ใน map

> **หมายเหตุ:** step และ criteria ที่ขีดฆ่า (~~strikethrough~~) ถูกตัดออกจาก scope ตามต้นฉบับใน ClickUp

### Scenario Steps
1. User เดินเข้าห้อง `members[]` อัปเดต broadcast
2. User เริ่ม screen share `has_active_share = true`
3. ~~Admin lock ห้อง `is_locked = true` member ใหม่เข้าไม่ได้~~
4. User ออกจากห้อง `members[]` อัปเดต broadcast
5. ห้องว่าง state reset เป็น default

### Acceptance Criteria
- Room state อัปเดต real-time ทุก member ในห้องและบน minimap
- ~~Lock room: เฉพาะ Admin/Owner ทำได้~~
- Lock visual: lock icon บน map และ member panel
- Screen share indicator แสดงบน room label
- Member count บน room label อัปเดต real-time

### Business Logic / Rules
- State อัปเดตผ่าน WebSocket events เสมอ ไม่ใช่ REST API

### UX/UI
- [Figma — node 2230-141187](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2230-141187&t=MXeRHTHV9XYUCObQ-0)

---

## SC-RTE-04 · Room State — Member Join / Leave

> [ClickUp](https://app.clickup.com/t/86d2weu7t) · **Type:** Happy Path · **Status:** pending

**Pre-condition:** Room มี state อยู่แล้ว

### Scenario Steps

**JOIN STEPS:**
1. Avatar เดินเข้า room zone (overlap detection)
2. Client ส่ง `ws:room:enter { room_id }`
3. Server validate: ห้องไม่ lock, capacity ไม่เต็ม
4. Server เพิ่ม `user_id` เข้า `members[]` broadcast `ws:room:stateUpdate`
5. User join media room (audio auto-connect ตาม preference)

**LEAVE STEPS:**
1. Avatar เดินออก room zone
2. Client ส่ง `ws:room:leave { room_id }`
3. Server ลบ `user_id` ออกจาก `members[]` broadcast
4. ถ้า user กำลัง share: stop share อัตโนมัติ
5. User leave media room
6. คนสุดท้ายออก: reset room state เป็น default

### Acceptance Criteria
- Join: user ได้รับ room state ทันที
- Leave: room state อัปเดตทันที ทุกคนในห้องเห็น
- ห้อง lock: join ไม่ได้ แสดง lock indicator
- Presenter ออก: screen share หยุดทันที แจ้งทุกคน
- Audio auto-join ตาม user preference
- คนสุดท้ายออก: reset room state ทั้งหมด

### Business Logic / Rules
- Server validate room lock ก่อน allow join
- SFU media room join/leave ต้อง sync กับ WS room events
- Presenter ออก = force stop share = `ws:share:stopped { reason: presenter_left }`

### UX/UI
- [Figma — node 2240-400675](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2240-400675&t=MXeRHTHV9XYUCObQ-0)

---

## SC-RTE-05 · Mute / Unmute Audio

> [ClickUp](https://app.clickup.com/t/86d2weuee) · **Type:** Happy Path · **Status:** pending

**Pre-condition:** User อยู่ในห้อง SFU media room joined

### Scenario Steps
1. User กดปุ่ม Mute บน HUD หรือ shortcut `M`
2. Client หยุดส่ง audio MediaStreamTrack ไปยัง SFU
3. Mute icon (ไมค์ขีดทับสีแดง) แสดงบน avatar และ member tile
4. ทุก member ในห้องเห็น mute indicator real-time
5. กด Unmute: audio track กลับมา, indicator หายไป
6. `audio_active_count` ใน room state อัปเดต

### Acceptance Criteria
- Mute/Unmute ใช้เวลา < 200ms
- Shortcut: `M` = toggle mute/unmute
- Mute icon บน avatar (ไมค์ขีดทับสีแดง)
- Join ห้องใหม่: default mute/unmute ตาม user preference
- Member force mute ได้ user รู้ผ่าน toast "User name ได้ปิดไมค์ของคุณ"
- User ถูก force mute ต้องกด unmute เองเท่านั้น (Member ไม่ unmute แทน)
- คนที่ถูกปิดไมค์ ให้คนที่ปิดกับคนเปิดเป็นคนเดียวกัน หรือแค่เจ้าตัวเปิดได้
- Audio level indicator (speaking animation) รอบ avatar เมื่อ unmute และพูด

### Business Logic / Rules
- Mute ทำงาน client-side
- Server track mute state เพื่อ broadcast ให้ member อื่น
- Force mute: server ส่ง `ws:audio:forceMuted { by_user_id }` ให้ target
- `audio_active_count` = จำนวน user ที่ unmute ในห้อง

### UX/UI
- [Figma — node 2231-387790](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2231-387790&t=MXeRHTHV9XYUCObQ-0)

---

## SC-RTE-06 · Camera On / Off

> [ClickUp](https://app.clickup.com/t/86d2weuk9) · **Type:** Happy Path · **Status:** pending

**Pre-condition:** User อยู่ในห้อง SFU media room joined

### Scenario Steps
1. User กดปุ่ม Camera บน Head-Up Display หรือ shortcut `V`
2. Camera off: แสดง avatar thumbnail หรือ initials แทน video tile
3. Camera off icon (กล้องขีดทับ) บน tile ของ user
4. ทุก member ในห้องเห็น camera off indicator real-time
5. กด Camera on: video track กลับมา แสดง video feed

### Acceptance Criteria
- Camera toggle ใช้เวลา < 500ms
- Shortcut: `V` = toggle camera on/off
- Camera off: แสดง avatar **รูปภาพขนาดเล็กที่ใช้เป็นตัวอย่าง (preview)** หรือ initials (ตัวย่อที่มาจากตัวอักษรตัวแรกของชื่อหรือคำหลายคำ) แทน video tile
- Join ห้องใหม่: default camera off ตาม user preference
- Admin ไม่สามารถ force camera off ได้ (privacy: user ควบคุมเองเท่านั้น)
- Browser permission ถูกปฏิเสธ: ปุ่ม Camera disable พร้อม tooltip แนะนำ

### Business Logic / Rules
- Camera off ทำงาน client-side: หยุดส่ง video MediaStreamTrack
- Browser permission ขอครั้งแรกที่ join ห้อง
- Admin force camera off ไม่รองรับโดย design (privacy)

### UX/UI
- [Figma — node 2256-36147](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2256-36147&t=MXeRHTHV9XYUCObQ-0)

---

## SC-RTE-07 · Screen Sharing — Full Screen

> [ClickUp](https://app.clickup.com/t/86d2weuup) · **Type:** Happy Path · **Status:** pending

**Pre-condition:** User อยู่ในห้อง joined

### Scenario Steps
1. User กดปุ่ม Screen Share บน HUD หรือ shortcut (`S`)
2. Browser แสดง native screen picker — user เลือก "Entire Screen" tab
3. User กด Share — browser ส่ง MediaStream (video + optional audio) กลับมา
4. Server validate: ห้องไม่มี active share → อนุมัติ, อัปเดต room state `has_active_share = true`
5. Client เพิ่ม screen track เข้า SFU room session (แยกจาก camera track)
6. SFU forward screen stream ให้ member ทุกคนในห้อง
7. Layout ของทุกคนเปลี่ยนเป็น featured: share tile ใหญ่ตรงกลาง + video tiles เล็กด้านข้าง
8. Presenter เห็น sharing indicator "กำลัง Share หน้าจอ" บน HUD พร้อม stop button
9. User กด Stop Sharing (HUD หรือ browser native stop button) → stream หยุด
10. Room state อัปเดต `has_active_share = false`, layout ทุกคนกลับ default grid

### Acceptance Criteria
- Share ได้เฉพาะ 1 คนต่อห้อง — ถ้ามีคน share อยู่แล้ว แสดง "[ชื่อ] กำลัง share อยู่ กรุณารอ"
- Screen share tile แสดงแบบ featured layout (tile ใหญ่ตรงกลาง) ทุก member เห็นพร้อมกัน
- Resolution target: 1920×1080, frame rate 15fps
- Presenter เห็น sharing indicator ชัดเจนบน HUD ตลอดเวลาที่ share อยู่
- Stop sharing ได้ 2 ทาง: ปุ่ม Stop บน HUD และ browser native stop button
- หลัง stop: layout ทุกคนกลับ default grid อัตโนมัติภายใน 1 วินาที
- Presenter ออกจากห้อง: share หยุดอัตโนมัติ แจ้งทุกคนด้วย system message
- Presenter ปิด tab/browser: browser cleanup stream อัตโนมัติ server ตรวจจับผ่าน disconnect
- Screen share track แยกจาก camera track — presenter ยังเปิด camera ได้พร้อมกัน
- Browser permission denied: แสดง error toast พร้อมวิธีแก้ (เปิด permission ใน browser settings)

### UX/UI
- [Figma — node 2273-158960](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2273-158960&t=KhEK47ULDJ1kMis5-0)

---

## SC-RTE-08 · Screen Sharing — Window / Tab

> [ClickUp](https://app.clickup.com/t/86d2weuzy) · **Type:** Happy Path · **Status:** pending

**Pre-condition:** User อยู่ในห้อง ต้องการ share เฉพาะ window/tab

### Scenario Steps
1. User กดปุ่ม Screen Share บน Head-Up Display
2. Browser แสดง native picker พร้อม 3 tab: Entire Screen / Window / Tab
3. User เลือก Window หรือ Tab แล้วกด Share
4. ทุกคนในห้องเห็น window/tab share tile (featured layout)
5. Tab share: browser แสดง sharing banner ด้านล่าง tab นั้น
6. Stop: กดปุ่ม HUD หรือ browser banner

### Acceptance Criteria
- Browser picker แสดง 3 ตัวเลือก: Entire Screen, Window, Tab
- Window share: แสดงเฉพาะ application window ที่เลือก ไม่รั่วข้อมูลอื่น
- Tab share: รองรับ tab audio (share tab with audio)
- Frame rate: Window 15fps, Tab 30fps
- Browser จัดการ picker UI เอง ไม่ต้องสร้าง UI เอง

### UX/UI
- [Figma — node 2301-529050](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2301-529050&t=KhEK47ULDJ1kMis5-0)

---

## SC-RTE-09 · Screen Share — ผู้ชม View

> [ClickUp](https://app.clickup.com/t/86d2wev56) · **Type:** Happy Path · **Status:** pending · **Priority:** Normal

**Pre-condition:** มี presenter กำลัง share อยู่ในห้อง User เป็น viewer

### Scenario Steps
1. User เดินเข้าห้องที่มี active screen share
2. Layout เปลี่ยนเป็น featured: share tile ใหญ่ + video tiles เล็กด้านข้าง
3. SFU ส่ง screen stream ให้ viewer subscribe อัตโนมัติ
4. Viewer เห็น screen share real-time พร้อม audio
5. Presenter หยุด share: layout กลับ default grid อัตโนมัติ
6. ถ้ามี User share screen 2 คน ให้แบ่งครึ่งจอ

### Acceptance Criteria
- Layout switch อัตโนมัติเมื่อเข้าห้องที่มี active share
- Share tile แสดงชื่อ presenter มุมซ้ายบน
- Viewer zoom in share tile ได้ (max 2x)
- Video tiles ของ member แสดงด้านข้าง (PiP layout)
- Latency target: < 500ms จาก presenter ถึง viewer
- Simulcast: SFU ส่ง quality ต่างกันตาม viewer bandwidth
- ถ้ามี User share screen 2 คน ให้แบ่งครึ่งจอ
- Share ได้สูงสุดพร้อมกัน 2 user

### UX/UI
- [Figma — node 2301-553258](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2301-553258&t=KhEK47ULDJ1kMis5-0)
