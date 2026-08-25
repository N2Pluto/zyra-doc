# [Module] Virtual Office — Specification

**ClickUp:** https://app.clickup.com/t/86d2wefft  
**Status:** In Progress  
**Priority:** High

---

## Overview

Module สำหรับ Virtual Office แบบ 2D Map ที่ avatar-based ครอบคลุม feature ดังนี้:

- List Workspace / Loading Page
- Render Map
- Avatar Movement (WASD + Click-to-move)
- Collision Detection
- Multiple Room
- Private Area Zone (Knock / Deny)
- Availability Status บน Avatar
- Wave Notification (ทักทาย)
- Follow
- Space Member Panel
- Invite Member เข้า Space ด้วย Email
- Invite Member ที่ไม่มีบัญชีในระบบ
- Leave Workspace (Member / Owner)

---

## Scenarios Summary

| ID | Scenario | Type | Status |
|---|---|---|---|
| SC-VO-01 | List Workspace | Happy Path | In Progress |
| SC-VO-02 | Loading Page — เข้า Virtual Office | Happy Path | In Progress |
| SC-VO-03 | Render Map | Happy Path | In Progress |
| SC-VO-04 | Avatar Movement (WASD + Click-to-move) | Happy Path | In Progress |
| SC-VO-05 | Collision Detection | Alternate Path | In Progress |
| SC-VO-06 | Multiple Room — เดินเข้า/ออกห้อง | Happy Path | Pending |
| SC-VO-07 | Private Area Zone — Knock ขอเข้าห้อง | Happy Path | Pending |
| SC-VO-08 | Private Area Zone — ถูกปฏิเสธ | Error Path | Pending |
| SC-VO-09 | Availability Status บน Avatar | Happy Path | Pending |
| SC-VO-10 | Wave Notification — ทักทาย Member | Happy Path | Pending |
| SC-VO-11 | Follow — ติดตาม Avatar | Happy Path | Pending |
| SC-VO-14 | Space Member Panel | Happy Path | In Progress |
| SC-SB-10 | Invite Member เข้า Space ด้วย Email | Happy Path | Pending |
| SC-SB-11 | Invite Member ที่ไม่มีบัญชีในระบบ | Alternate Path | Pending |
| SC-PROFILE-06 | Leave Workspace — ยืนยันและออกสำเร็จ | Happy Path | Pending |
| SC-PROFILE-07 | Leave Workspace — Owner ออกไม่ได้ (Transfer Ownership) | Error Path | Pending |

---

## SC-VO-01 · List Workspace

**ClickUp:** https://app.clickup.com/t/86d37ufer  
**Type:** Happy Path  
**Persona:** Member และ Space Admin / Workspace Owner  
**Pre-condition:** Member และ Owner login แล้ว เข้าหน้า Workspace

### Scenario Steps

1. ระบบแสดง List Workspace ทั้งหมด โดยแยกเป็น Tab 3 Tab:
   - All workspace — รวมทุก workspace ที่มีสิทธิ์
   - My workspace — เฉพาะที่เป็น Owner
   - Shared with me — เฉพาะที่เป็น Member
2. ระบบแสดง Workspace ทั้งหมดในรูปแบบ card
3. แต่ละ Workspace card แสดง: thumbnail, ชื่อ Workspace, เวลาใช้งานล่าสุด, สิทธิ์การใช้งาน (Member/Owner), จำนวนผู้ใช้งาน active, จำนวน member (member/capacity)
4. ผู้ใช้งานกด Workspace เพื่อเข้า Map list (SC-VO-02)

### Acceptance Criteria

- Workspace list แสดง thumbnail preview ของ Workspace (map หลัก)
- แสดง metadata: ชื่อ Workspace, เวลาใช้งานล่าสุด, สิทธิ์การใช้งาน (Member/Owner)
- แสดง status badge: จำนวนผู้ใช้งาน active, จำนวน member (member/capacity)
- ปุ่ม "เข้าแก้ไข" — Owner
- ปุ่ม "เข้า Work Space" — Member และ Workspace Owner
- ปุ่ม "คัดลอก Work Space" — Member และ Workspace Owner
- ปุ่ม "Invite Member" — Space Admin / Workspace Owner

### Business Logic / Rules

- Map thumbnail generate อัตโนมัติจาก canvas screenshot เมื่อ save

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1805-259434

---

## SC-VO-02 · Loading Page — เข้า Virtual Office

**ClickUp:** https://app.clickup.com/t/86d2weg3x  
**Type:** Happy Path  
**Persona:** Logged-in Member  
**Pre-condition:** User กด "เข้า Virtual Office"

### Scenario Steps

1. แสดง List Workspace หรือ Virtual Office
2. User กด "เข้า Virtual Office"
3. ระบบแสดง Loading Screen พร้อม progress bar
4. โหลด: Map assets (tilesets, sprites), WebSocket connection, member list
5. Avatar ของ User ถูก spawn ที่ spawn point (ตามห้องที่ออกไปครั้งล่าสุด)
6. Loading เสร็จ — fade in เข้า Virtual Office map
7. แสดง HUD: member panel, chat, availability status, minimap

### Acceptance Criteria

- Loading screen แสดง office name และ progress bar (0–100%)
- Progress แบ่ง phase: Connecting (0–30%), Loading map (30–70%), Loading members (70–100%)
- ถ้าโหลดนานเกิน 10 วินาที: แสดง "กำลังเชื่อมต่อ..." พร้อมปุ่ม retry
- Fade-in animation เมื่อ map พร้อม
- ถ้า office เต็ม (capacity): แสดง "Office เต็มแล้ว กรุณาลองใหม่ภายหลัง"
- Asset preload ใช้ browser cache (cache-control headers)

### Business Logic / Rules

- WebSocket connect ก่อน map load เสมอ เพื่อ sync member positions
- Spawn point: ใช้ `last_position` ถ้ามี หรือ `default_spawn_point` ของ map
- ถ้า office เต็ม: ไม่ให้ join WebSocket room

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1805-271513

---

## SC-VO-03 · Render Map

**ClickUp:** https://app.clickup.com/t/86d2wegfe  
**Type:** Happy Path  
**Persona:** User เพิ่งเข้า Virtual Office  
**Pre-condition:** Loading สำเร็จ Map data โหลดแล้ว

### Scenario Steps

1. Engine รับ map.json (Tiled) render tile layers
2. แสดง Floor / Wall / Object / Decoration layer
3. Render avatar user และ member อื่น real-time
4. Camera follow avatar พร้อม smooth scroll
5. Minimap overview พร้อม dot ตำแหน่ง member
6. Room labels แสดงชื่อห้อง

### Acceptance Criteria

- Render ครบทุก layer: background, collision, decoration, avatars, UI overlay
- Screen follow avatar ของตัวเอง พร้อมช่องว่างภายในขอบ
- Avatar member อื่นแสดง real-time ตาม WebSocket position
- Minimap มุมล่างขวา dot สีตาม availability status
- Room label แสดงเมื่อ avatar เข้าใกล้ห้อง
- รองรับ map 100x100 tiles (32x32px) ไม่กระตุก
- Private zone: แสดงขอบเขตทางภาพ (เส้นขอบแบบเส้นประหรือแสงต่างกัน)

### Business Logic / Rules

- ทำให้การเคลื่อนที่ของ avatar ลื่นไหล ระหว่างการอัปเดตจาก WebSocket
- Render ใหม่เฉพาะ object ที่มีการเปลี่ยนแปลง
- **zIndex**: `floor < objects < avatars < UI overlay`
- โหลดข้อมูลแผนที่จาก CDN และใช้ cache เพื่อลดการโหลดซ้ำ

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1805-285771

---

## SC-VO-04 · Avatar Movement (WASD + Click-to-move)

**ClickUp:** https://app.clickup.com/t/86d2wegug  
**Type:** Happy Path  
**Persona:** User อยู่ใน Virtual Office  
**Pre-condition:** User spawn บน map แล้ว

### Scenario Steps

**WASD:**
1. กด WASD/Arrow
2. Avatar เคลื่อนที่พร้อม walk animation
3. ตรวจ collision
4. อัปเดต position broadcast WebSocket
5. Member อื่นเห็น smooth interpolation

**Click-to-move:**
1. คลิก map
2. คำนวณ pathfinding A*
3. Avatar เดินตาม path อัตโนมัติ
4. ถ้า path ถูกบล็อก: recalculate
5. Idle เมื่อถึงจุดหมาย

### Acceptance Criteria

- WASD + Arrow keys ควบคุมได้
- Click-to-move: คลิกพื้นที่ว่าง avatar เดินไป
- Walk animation 4-direction: up / down / left / right
- Idle animation เมื่อหยุดนิ่ง 3 วินาที
- ไม่ทะลุ wall/object (collision)
- Smooth interpolation ระหว่าง WS updates (50ms interval)
- Speed: 150 pixels/วินาที (configurable)

### Business Logic / Rules

- Position WebSocket อัปเดตทุก 50ms ขณะ moving (throttle)
- Pathfinding A* ทำงาน client-side
- Server validate position anti-cheat: ตรวจเคลื่อนที่เร็วเกินไปไหม
- Direction: `up / down / left / right / idle`

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1805-285771

---

## SC-VO-05 · Collision Detection

**ClickUp:** https://app.clickup.com/t/86d2wegye  
**Type:** Alternate Path  
**Persona:** User เดิน avatar เข้าหา wall/object  
**Pre-condition:** User กำลังเคลื่อนที่บน map

### Scenario Steps

1. Avatar เคลื่อนที่ไปทิศที่มี wall/object
2. ระบบตรวจ collision กับ tile layer
3. Avatar หยุดทันทีที่ขอบ collision
4. ไม่ทะลุผ่าน
5. กด direction อื่น: เคลื่อนที่ต่อได้
6. Click-to-move: A* หลีกเลี่ยง obstacle อัตโนมัติ

### Acceptance Criteria

- Avatar หยุดทันทีเมื่อชน wall (ไม่ sliding)
- Click-to-move pathfinding หลีกเลี่ยง obstacle อัตโนมัติ
- ถ้าไม่มี path ถึงจุดหมาย: avatar ไปจุดใกล้สุดที่ไปได้ แสดง visual indicator
- ไม่มี error ให้ user เห็น เป็น silent block

### Business Logic / Rules

- Collision map โหลดจาก Tiled Collision layer (boolean grid)
- Check collision ก่อนทุกครั้งที่ update position (client + server validate)
- Server validate: ถ้า position ใหม่ใน collision tile = reject position update
- Collision grid cache ใน client memory ตลอด session

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1810-518058

---

## SC-VO-06 · Multiple Room — เดินเข้า/ออกห้อง

**ClickUp:** https://app.clickup.com/t/86d2weh66  
**Type:** Happy Path  
**Persona:** User อยู่ใน Virtual Office  
**Pre-condition:** Map มีหลายห้อง กำหนดใน Tiled objectgroup

### Scenario Steps

1. Avatar เดินเข้า zone ที่กำหนดเป็น Room
2. ตรวจจับ overlap
3. แสดง room name popup เหนือ avatar
4. Proximity Chat scope เปลี่ยนเป็นเฉพาะคนในห้อง
5. Minimap highlight ห้องปัจจุบัน
6. Member Panel แสดง badge ชื่อห้อง
7. เดินออก: proximity scope กลับ open area

### Acceptance Criteria

- Room zone ตรวจจับโดย overlap กับ Tiled objectgroup
- Popup ชื่อห้องแสดงเมื่อเข้า fade out หลัง 3 วินาที
- Proximity Chat ใช้ `room_id` เป็น scope
- Room member count แสดงบน minimap หรือ room label
- Transition animation เมื่อเข้า/ออก (door/fade effect)
- รองรับสูงสุด 20 ห้องต่อ map

### Business Logic / Rules

- Room zone = Tiled polygon/rectangle ใน Rooms layer
- Overlap ตรวจ client-side แต่ `room_id` broadcast ไป server ด้วย
- Server track `room_id` ของแต่ละ user เพื่อ scope proximity chat
- ห้องไม่มี capacity limit (ต่างจาก Private Area)

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1842-209371

---

## SC-VO-07 · Private Area Zone — Knock ขอเข้าห้อง

**ClickUp:** https://app.clickup.com/t/86d2wehbh  
**Type:** Happy Path  
**Persona:** Member ต้องการเข้า Private Area  
**Pre-condition:** Map มี Private Zone กำหนดไว้ User อยู่นอก zone

### Scenario Steps

1. Avatar เดินเข้าใกล้ Private Zone boundary
2. แสดง visual indicator: lock icon และ zone name
3. Avatar ชน invisible wall ที่ขอบ Private Zone
4. แสดงปุ่ม Knock หรือ prompt
5. User กด Knock
6. ส่ง notification ไปหาคนในห้อง (owner/admin)
7. Owner เห็น knock notification พร้อมชื่อ + avatar ของผู้ขอ
8. Owner กด Allow: Private Zone barrier เปิดให้ user เดินเข้า
9. User เดินเข้า Private Zone สำเร็จ

### Acceptance Criteria

- Private Zone มี visual boundary ชัดเจน (dashed/glowing border)
- ปุ่ม Knock แสดงเมื่อ avatar เข้าใกล้ขอบ Private Zone
- Knock notification แสดงใน HUD ของคนในห้อง พร้อม avatar + ชื่อ
- Owner/Admin ในห้องเห็น notification และ Allow/Deny
- หลัง Allow: barrier เปิด user เดินเข้าได้ภายใน 30 วินาที
- ถ้าไม่มีใครอยู่ในห้อง: แสดง "ไม่มีใครอยู่ในห้องนี้"
- Knock cooldown 30 วินาที (ป้องกัน spam)

### Business Logic / Rules

- Private Zone = Tiled PrivateZones layer object ที่มี `knock_required: true`
- Barrier = invisible collision tile ที่ขอบ Private Zone
- หลัง Allow: server ส่ง `ws:privateZone:granted` ให้ user: เอา barrier ออกชั่วคราว 30 วินาที
- ถ้า user ไม่เดินเข้าภายใน 30 วินาที: barrier กลับมา
- บันทึก `private_zone_access_log` สำหรับ audit

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1858-324403

---

## SC-VO-08 · Private Area Zone — ถูกปฏิเสธ

**ClickUp:** https://app.clickup.com/t/86d2wehh0  
**Type:** Error Path  
**Persona:** Member ถูก Deny จาก Private Zone  
**Pre-condition:** User ส่ง Knock request ไปแล้ว Owner กด Deny

### Scenario Steps

1. Owner เห็น Knock notification
2. Owner กด Deny
3. ระบบส่ง `ws:privateZone:denied` ให้ user ที่ขอ
4. User เห็น notification "ขอเข้าห้องถูกปฏิเสธ"
5. Avatar ยังอยู่นอก Private Zone
6. ปุ่ม Knock กลับมาหลัง cooldown 30 วินาที

### Acceptance Criteria

- User เห็น toast/notification "ขอเข้าห้องถูกปฏิเสธ" พร้อมชื่อห้อง
- Avatar ไม่เคลื่อนที่เข้า zone
- ไม่ block user ถาวร เพียงแค่ cooldown 30 วินาที
- Owner ไม่ต้องอธิบายเหตุผล (Deny ได้เลย)
- ถ้า Deny 3 ครั้งติดต่อกัน: cooldown ขยายเป็น 5 นาที

### Business Logic / Rules

- Server broadcast `ws:privateZone:denied { zone_id, user_id }`
- บันทึก deny event ใน `access_log` เพื่อ audit
- Progressive cooldown: 30s (1st), 30s (2nd), 5min (3rd+)

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1860-338181

---

## SC-VO-09 · Availability Status บน Avatar

**ClickUp:** https://app.clickup.com/t/86d2wehp1  
**Type:** Happy Path  
**Persona:** User ต้องการตั้งค่า Availability Status  
**Pre-condition:** User อยู่ใน Virtual Office

### Scenario Steps

1. User คลิกที่ avatar ตัวเองหรือ status indicator
2. เห็น dropdown: Available, Busy, Away, Do Not Disturb, Custom
3. เลือก status
4. Avatar badge อัปเดตทันทีบน map
5. Member อื่นเห็น status badge เปลี่ยน real-time
6. Minimap dot สีเปลี่ยนตาม status

### Acceptance Criteria

- Status options: Available (เขียว), Busy (แดง), Away (เหลือง)
- Avatar แสดง status badge มุมล่างขวาของ avatar sprite
- Minimap dot สีตาม status
- Custom status พิมพ์ข้อความได้ max 30 ตัวอักษร พร้อม emoji
- Do Not Disturb: ซ่อน Wave notification จากคนอื่น
- Status sync ทั้ง Virtual Office และ app-wide (DM list, Member panel)

### Business Logic / Rules

- Status เปลี่ยนเมื่อ user leave office อัตโนมัติ = offline

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1860-341973

---

## SC-VO-10 · Wave Notification — ทักทาย Member

**ClickUp:** https://app.clickup.com/t/86d2wehv3  
**Type:** Happy Path  
**Persona:** User ต้องการทักทาย member  
**Pre-condition:** User อยู่ใน Virtual Office เห็น member คนอื่นบน map

> **Wave = ทักทาย (ไม่ต้องอยู่ใกล้กัน)**

### Scenario Steps

1. User คลิกที่ avatar ของ member คนอื่น
2. เห็น context menu: Wave, DM, Follow, View Profile
3. User เลือก Wave
4. Avatar ของ user เล่น wave animation
5. Member ที่ถูก wave เห็น notification ใน HUD: "[ชื่อ] โบกมือทักทายคุณ"
6. Member ที่ถูก wave กด Wave back: ส่ง wave กลับ
7. ทั้งคู่เห็น wave animation พร้อมกัน

### Acceptance Criteria

- Wave ได้จากทุกระยะ (ไม่จำกัด proximity)
- Wave notification แสดงใน HUD มุมบนขวา พร้อม avatar sender
- Notification หายอัตโนมัติหลัง 5 วินาที
- Wave animation บน avatar ของ sender ทุกคนบน map เห็น
- Do Not Disturb: ไม่รับ Wave notification
- Wave cooldown ต่อคน: 10 วินาที (ป้องกัน spam)

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1872-349124

---

## SC-VO-11 · Follow — ติดตาม Avatar

**ClickUp:** https://app.clickup.com/t/86d2wehzp  
**Type:** Happy Path  
**Persona:** User ต้องการติดตาม avatar ของ member  
**Pre-condition:** User อยู่ใน Virtual Office เห็น member ที่ต้องการ follow

### Scenario Steps

1. User คลิก avatar member เลือก Follow จาก context menu
2. ระบบ activate follow mode
3. Screen และ avatar ของ user ติดตาม avatar target อัตโนมัติ
4. Target เห็น notification "[ชื่อ] กำลัง follow คุณ"
5. User อยู่ใกล้ target เสมอ (ห่าง 1-2 tiles)
6. กด Unfollow หรือกด WASD: หยุด follow mode

### Acceptance Criteria

- Follow mode: user avatar เดินตาม target อัตโนมัติ
- Target avatar เห็น follow indicator (footprint icon เล็กๆ)
- Follow notification แสดงให้ target 1 ครั้ง
- กด WASD ขณะ follow: cancel follow mode ทันที
- Target สามารถ block follow ได้ (ไม่ให้ใครติดตาม)
- Follow ได้ครั้งละ 1 คนเท่านั้น
- ถ้า target ออก office: follow mode ยกเลิกอัตโนมัติ

### Business Logic / Rules

- Follow mode คำนวณ pathfinding A* ไปยัง target position อัตโนมัติ ทุก 200ms
- ระยะที่รักษา: 1-2 ช่อง ห่างจาก target (ไม่ทับกัน)
- Follow เก็บ Redis (ephemeral) ไม่บันทึก DB
- Block follow: user ตั้ง `allow_follow: false` ใน preferences

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1942-29366

---

## SC-VO-14 · Space Member Panel

**ClickUp:** https://app.clickup.com/t/86d2wejgu  
**Type:** Happy Path  
**Persona:** User ที่อยู่ใน Virtual Office  
**Pre-condition:** User อยู่ใน Virtual Office มี member คนอื่น online

### Scenario Steps

1. Member Panel แสดงด้านขวา HUD ตลอดเวลา (collapsible)
2. แสดงรายชื่อ member ทั้งหมดแบ่งกลุ่ม: Online, Away, Offline
3. แต่ละ member แสดง: avatar, ชื่อ, status badge, ห้องที่อยู่ปัจจุบัน
4. User คลิก member: เห็น quick action — DM, Wave, Follow, View Profile
5. Camera pan ไปยัง avatar ของ member ที่คลิก (locate on map)
6. ค้นหา member ด้วย search box ใน panel

### Acceptance Criteria

- Panel แสดง member แบ่งกลุ่ม: Online (เขียว), Away (เหลือง), Offline (เทา)
- Online members แสดงก่อน เรียงตามชื่อ
- แสดงห้องที่ member อยู่ปัจจุบัน (เช่น "Meeting Room A")
- คลิก member: camera pan + zoom ไปยัง avatar บน map
- Search: ค้นหาชื่อ member ได้ real-time
- Member count แสดงบน panel header เช่น "Members (12/50)"
- Panel collapse เหลือแค่ icon แถบข้าง
- อัปเดต real-time เมื่อ member join/leave/เปลี่ยน status

### Business Logic / Rules

- Member list ดึงจาก Redis office session (real-time) ไม่ใช่ DB
- Offline member แสดงได้แต่ไม่มี position บน map
- Camera pan ใช้ `engine.camera.pan(x, y)` พร้อม smooth tween
- Member count = online / capacity
- Member ที่ DND แสดง status ว่า DND ใน panel

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1951-217507

---

## SC-SB-10 · Invite Member เข้า Space ด้วย Email

**ClickUp:** https://app.clickup.com/t/86d2v1x63  
**Type:** Happy Path  
**Persona:** Space Admin / Workspace Owner  
**Pre-condition:** Space สร้างแล้ว, User มีสิทธิ์ invite member

### Scenario Steps

1. User เข้าหน้า Space Settings → แท็บ Members
2. กดปุ่ม "Invite Member"
3. กรอก email ของคนที่ต้องการ invite
4. เลือก role: Member / Admin
5. กด "ส่งคำเชิญ"
6. ระบบส่ง invitation email และสร้าง pending invite record
7. แสดง toast "ส่งคำเชิญไปยัง [email] แล้ว"
8. Pending member ปรากฏในรายการ Members พร้อม badge "รอยืนยัน"

### Acceptance Criteria

- Input รับ email ได้หลาย address (comma-separated หรือ Enter แยก)
- Dropdown เลือก role: Member, Admin พร้อมคำอธิบายแต่ละ role
- ปุ่ม "ส่งคำเชิญ" disable จนกว่าจะมี email ที่ valid อย่างน้อย 1 อัน
- Pending member แสดงใน list พร้อม badge สีเหลือง "รอยืนยัน"
- สามารถ resend หรือ cancel invite ของ pending member ได้
- Invitation link หมดอายุใน 7 วัน

### Business Logic / Rules

- ตรวจสอบ email ซ้ำ: ถ้า invite email ที่เป็น member อยู่แล้ว → แสดง error
- Invite ได้สูงสุดครั้งละ 10 email
- Role permission: Admin invite ได้ถึง Member, Owner invite ได้ทุก role
- Invitation token เป็น cryptographically secure random string
- หาก invitee ยังไม่มีบัญชี: redirect ไป Register หลัง accept invite (SC-SB-11)
- หาก invitee มีบัญชี: กด accept แล้ว join Space ทันที

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1951-268597

---

## SC-SB-11 · Invite Member ที่ไม่มีบัญชีในระบบ

**ClickUp:** https://app.clickup.com/t/86d2v1xck  
**Type:** Alternate Path  
**Persona:** Invitee — ได้รับ invitation email แต่ยังไม่มีบัญชี  
**Pre-condition:** Invitee ได้รับ invitation email, ยังไม่มีบัญชีใน Zyra

### Scenario Steps

1. Invitee คลิก "รับคำเชิญ" ใน email
2. Browser เปิดหน้า Accept Invitation
3. ระบบตรวจสอบ token — ถูกต้องและยังไม่หมดอายุ
4. หน้าแสดงข้อมูล: ชื่อ Space, ชื่อคนที่ invite, role ที่ได้รับ
5. เนื่องจากยังไม่มีบัญชี: แสดงปุ่ม "สมัครสมาชิกและรับคำเชิญ" และ "มีบัญชีแล้ว เข้าสู่ระบบ"
6. User กด "สมัครสมาชิก" → ไปหน้า Register พร้อม email pre-fill และ invite token ใน URL
7. หลัง Register + verify OTP สำเร็จ: ระบบ auto-accept invite และ join Space ทันที
8. Redirect ไปหน้า Space โดยตรง

### Acceptance Criteria

- Accept invitation page แสดงข้อมูล Space และ inviter ชัดเจน
- Email pre-fill ในหน้า Register จาก invitation
- Invite token ต้องถูก carry ตลอด Register flow จนสำเร็จ
- หลัง Register สำเร็จ: auto-join Space ไม่ต้องคลิก accept ซ้ำ
- ถ้า token หมดอายุระหว่าง Register: แจ้ง inviter ให้ส่ง invite ใหม่
- ถ้าสมัครด้วย Google: auto-accept invite หลัง OAuth สำเร็จ

### Business Logic / Rules

- Invite token เก็บใน session storage ตลอด Register flow
- หลัง Register สำเร็จ: ตรวจ invite token ก่อน redirect — ถ้ายัง valid ให้ auto-accept
- Auto-accept: สร้าง `space_member` record, mark invitation status = accepted
- ถ้า token หมดอายุ: register ปกติ แต่ไม่ join Space และแจ้งผู้ใช้

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1951-351958

---

## SC-PROFILE-06 · Leave Workspace — ยืนยันและออกสำเร็จ

**ClickUp:** https://app.clickup.com/t/86d2v0vhg  
**Type:** Happy Path  
**Persona:** Workspace Member (ไม่ใช่ Owner)  
**Pre-condition:** User เป็น member ของ Workspace, ไม่ใช่ Owner

### Scenario Steps

1. User เข้าหน้า Profile Settings → แท็บ Workspace
2. เห็นรายการ Workspace ที่ตัวเองเป็นสมาชิกอยู่
3. กดปุ่ม "ออกจาก Workspace" ที่ต้องการ
4. ระบบแสดง confirmation dialog พร้อมชื่อ Workspace และคำเตือน
5. User กรอกชื่อ Workspace เพื่อยืนยัน (prevent accidental leave)
6. กด "ยืนยันออกจาก Workspace"
7. ระบบ remove user ออกจาก Workspace
8. Redirect ไปหน้า Workspace selector
9. Toast "ออกจาก [ชื่อ Workspace] สำเร็จ"

### Acceptance Criteria

- แสดงรายการ Workspace ทั้งหมดที่ user เป็นสมาชิก พร้อม role badge
- Workspace ที่ user เป็น Owner แสดงปุ่ม "จัดการ" แทน "ออก"
- Confirmation dialog แสดง: ชื่อ Workspace, จำนวน member, คำเตือนว่าจะสูญเสียสิทธิ์ทั้งหมด
- ต้องพิมพ์ชื่อ Workspace ให้ตรงก่อนกด confirm (case-sensitive)
- หลังออก: revoke access ทันที และ redirect ออกจาก Workspace นั้น
- ถ้า Workspace มีแค่ user คนเดียว: แจ้งว่า Workspace จะถูกลบด้วย

### Business Logic / Rules

- Owner ไม่สามารถออกจาก Workspace ได้ ต้อง transfer ownership ก่อน (SC-PROFILE-07)
- หลัง leave: revoke refresh tokens ที่ผูกกับ Workspace นั้นทันที
- บันทึก audit log: `user_id`, `workspace_id`, `left_at`, `reason = voluntary`
- ลบ `workspace_member` record แต่เก็บ content ที่ user สร้างไว้ (ไม่ลบ data)

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1951-359635

---

## SC-PROFILE-07 · Leave Workspace — Owner ออกไม่ได้ (Transfer Ownership)

**ClickUp:** https://app.clickup.com/t/86d2v0vtn  
**Type:** Error Path  
**Persona:** Workspace Owner — พยายามออกจาก Workspace  
**Pre-condition:** User เป็น Owner ของ Workspace ที่ต้องการออก

### Scenario Steps

1. User กดปุ่ม "ออกจาก Workspace" บน Workspace ที่ตัวเองเป็น Owner
2. ระบบตรวจสอบ role — พบว่าเป็น Owner
3. แสดง modal อธิบายว่า Owner ออกไม่ได้โดยตรง
4. แสดง 2 ตัวเลือก:
   - "โอนความเป็นเจ้าของ" → ไปหน้า Transfer Ownership
   - "ยกเลิก" → ปิด modal
5. User เลือก Transfer Ownership → เลือก Admin คนใหม่
6. หลัง transfer สำเร็จ: role เปลี่ยนเป็น Admin → ออกได้ตามปกติ (SC-PROFILE-06)

### Acceptance Criteria

- ปุ่ม "ออกจาก Workspace" ของ Workspace ที่เป็น Owner แสดง disabled state หรือ tooltip เตือน
- Modal แจ้งชัดเจนว่า "คุณเป็น Owner ต้อง Transfer Ownership ก่อน"
- มีปุ่ม shortcut ไปหน้า Transfer Ownership โดยตรง
- Transfer Ownership: แสดง list member ที่ active พร้อม search
- Confirm transfer ด้วย modal ยืนยันอีกครั้ง
- หลัง transfer: badge role เปลี่ยนจาก Owner → Admin ทันที

### Business Logic / Rules

- Block leave ที่ server-side เสมอ ไม่ trust client
- Transfer ownership ต้อง target เป็น active Admin ของ Workspace เท่านั้น
- เมื่อ transfer: เปลี่ยน role ของ previous owner เป็น Admin (ไม่ใช่ member)
- บันทึก `ownership_transferred_at` และ `transferred_to_user_id` ใน Workspaces table
- Notify new owner ทาง email และ in-app notification

### UX/UI

Figma: https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1951-379814
