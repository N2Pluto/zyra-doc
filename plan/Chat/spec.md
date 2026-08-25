# [Module] Chat — Spec

**ClickUp:** https://app.clickup.com/t/86d2we8gj  
**Priority:** High  
**Assignee:** Ponlawat Lueakaew  
**Status:** In Progress

---

## Codebase Alignment (v1.1 — 2026-06-29)

ปรับ spec ให้ตรงกับโค้ดจริงของ zyra-api / zyra-ws / zyra-app:

- **Notification:** ไม่มี `tb_notification` table หรือ `NotificationService` อยู่จริง — เป็น forward-looking design ที่ต้องสร้างใหม่ (DB + business logic อยู่ zyra-api, WS push อยู่ zyra-ws, ส่วน email ออกผ่าน zyra-notifications เท่านั้น)
- **WebSocket:** zyra-ws ใช้ native WebSocket envelope `{type, payload}` (ไม่ใช่ Socket.IO) + binary frame `moved_bin`; ชื่อ type จริงเป็น constant `ClientMsg*/Msg*`. ปัจจุบันมีเฉพาะ `MsgChat` ที่ broadcast ทั้งห้อง workspace — event `chat:*` / `proximity:*` / `ws:*` ในเอกสารยังไม่มีจริง ต้องสร้างใหม่และ map ลงบน `Envelope.type`
- คงเนื้อหา design / Thai / Figma node IDs / scenario เดิมไว้ทั้งหมด; แก้เฉพาะข้อความที่อ้าง infra ซึ่งไม่มีจริง

## Overview

Module สำหรับระบบ Chat ครอบคลุม 10 Features:

- Direct Message (DM)
- Proximity Chat (Virtual Office Map — avatar-based)
- Global / Channel Chat
- Group Chat
- Thread Replies
- Emoji Reactions
- File / Image Attachment (limit TBD)
- Unread Badge / Notification (In-app + Email)
- Message Search
- Typing Indicator

---

## Scenario Index

| ID | Scenario | Type | Priority |
|----|----------|------|----------|
| SC-CHAT-01 | ส่ง Direct Message (DM) | Happy Path | High |
| SC-CHAT-02 | Proximity Chat — คุยกับคนใกล้บน Virtual Office Map | Happy Path | High |
| SC-CHAT-03 | Proximity Chat — ออกนอก Proximity Radius | Alternate Path | Normal |
| SC-CHAT-04 | ส่งข้อความใน Global / Channel Chat | Happy Path | High |
| SC-CHAT-05 | สร้างและส่งข้อความใน Group Chat | Happy Path | High |
| SC-CHAT-06 | Thread Replies — ตอบกลับใน Thread | Happy Path | Normal |
| SC-CHAT-07 | Emoji Reaction บนข้อความ | Happy Path | Normal |
| SC-CHAT-08 | File / Image Attachment | Happy Path | High |
| SC-CHAT-09 | File Attachment เกิน Limit หรือประเภทผิด | Error Path | Normal |
| SC-CHAT-10 | Unread Badge และ Notification (In-app) | Happy Path | High |
| SC-CHAT-11 | Message Search | Happy Path | Normal |
| SC-CHAT-12 | Typing Indicator | Happy Path | Normal |

---

## SC-CHAT-01 · ส่ง Direct Message (DM)

**ClickUp:** https://app.clickup.com/t/86d2we8qe  
**Type:** Happy Path  
**Persona:** Logged-in User  
**Pre-condition:** User login แล้ว อยู่ใน Workspace เดียวกันกับผู้รับ  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1977-1359172

### Scenario Steps

1. User กดที่ชื่อ member หรือ icon DM ใน Sidebar
2. เปิดหน้า DM Chat กับ member นั้น
3. User พิมพ์ข้อความในช่อง input
4. กด Enter หรือปุ่ม Send
5. ข้อความแสดงทันทีฝั่ง sender (optimistic update)
6. ระบบส่งผ่าน WebSocket — ผู้รับเห็นข้อความ real-time
7. Message แสดง timestamp และ read receipt (seen status)

### Acceptance Criteria

- DM เปิดได้จาก Sidebar member list และ avatar ใน Virtual Office Map
- ข้อความ max 4,000 ตัวอักษรต่อข้อความ
- รองรับ message box พื้นฐาน message รูปภาพ, เอกสาร, emoji
- Enter = ส่ง, Shift+Enter = ขึ้นบรรทัดใหม่
- แสดง read receipt: Sent / Delivered / Seen พร้อม timestamp
- ถ้าผู้รับ offline: ข้อความเก็บไว้และแสดงเมื่อ online
- DM history โหลดแบบ infinite scroll (pagination 50 messages/page)
- แสดง online status ของผู้รับ (online / away / offline)

### Business Logic / Rules

- ส่งข้อความผ่าน WebSocket (native WebSocket — envelope `{type, payload}`; zyra-ws ไม่ใช้ Socket.IO)
- Message เก็บใน DB เสมอ ไม่หายเมื่อ disconnect
- Optimistic update: แสดงข้อความทันทีฝั่ง sender ก่อน server ยืนยัน
- ถ้า send fail: แสดง retry button บนข้อความนั้น
- Read receipt อัปเดตเมื่อผู้รับเปิดหน้า DM และ scroll ผ่านข้อความ
- ไม่สามารถ DM ตัวเองได้
- Rate limit: ส่งได้สูงสุด 30 ข้อความ/นาที/user

---

## SC-CHAT-02 · Proximity Chat — คุยกับคนใกล้บน Virtual Office Map

**ClickUp:** https://app.clickup.com/t/86d2we8zv  
**Type:** Happy Path  
**Persona:** User อยู่ใน Virtual Office Map  
**Pre-condition:** User online อยู่ใน Virtual Office Map, มี member อื่นอยู่ใกล้เคียง  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2012-260260

### Scenario Steps

1. User อยู่ใน Virtual Office Map avatar แสดงบน map
2. User เดิน avatar เข้าใกล้ avatar ของ member คนอื่น
3. เมื่อ avatar 2 คนอยู่ในรัศมี proximity
4. ระบบเปิด Proximity Chat panel อัตโนมัติ
5. แสดงชื่อ member ที่อยู่ในรัศมีพร้อม avatar
6. ถ้ามีหลายคนในรัศมี: ทุกคนเข้าร่วม proximity session เดียวกัน

### Acceptance Criteria

- Proximity panel เปิดอัตโนมัติเมื่อ avatar เข้า radius ไม่ต้องกด
- แสดงรายชื่อ member ทั้งหมดในรัศมีปัจจุบัน
- ข้อความ proximity ไม่บันทึกใน history (ephemeral) หายเมื่อออกจาก radius
- Proximity panel ปิดอัตโนมัติเมื่อออกนอก radius (SC-CHAT-03)
- แสดง visual indicator บน map รอบ avatar เมื่ออยู่ใน proximity zone
- รองรับ proximity chat สูงสุด 10 คน ต่อ session

### Business Logic / Rules

- Proximity คำนวณจาก avatar position (x, y) บน Virtual Office Map
- Radius configurable default 200 map units
- Position อัปเดตผ่าน WebSocket ทุกครั้งที่ avatar เคลื่อนที่
- ถ้า user disconnect: ออกจาก proximity session ทันที

---

## SC-CHAT-03 · Proximity Chat — ออกนอก Proximity Radius

**ClickUp:** https://app.clickup.com/t/86d2we93m  
**Type:** Alternate Path  
**Persona:** User ที่กำลังอยู่ใน Proximity Chat  
**Pre-condition:** User กำลัง proximity chat อยู่กับ member คนอื่น  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2012-406483

### Scenario Steps

1. User เดิน avatar ออกนอก radius ของ member คนอื่น
2. ระบบตรวจจับว่าออกนอก proximity zone
3. แสดง toast เตือน "กำลังออกจากพื้นที่สนทนา..."
4. Proximity Chat panel ค่อยๆ fade out และปิดอัตโนมัติ

### Acceptance Criteria

- แสดง toast เตือนก่อน panel ปิด 2 วินาที
- ถ้ายังมี member อื่นใน radius: พวกเขาคุยต่อกันได้ปกติ
- ถ้าออกจนไม่มีใครเหลือ: session ถูก destroy ทันที
- ข้อความที่พิมพ์ค้างใน input ไม่ถูกส่ง ถ้า panel ปิดก่อน
- กด avatar ของ member อีกครั้งเพื่อเปิด DM แทนได้

### Business Logic / Rules

- ตรวจ proximity ทุกครั้งที่ avatar เคลื่อนที่ (logical event `proximity:*` — map ลงบน `Envelope.type`; ปัจจุบันการเคลื่อนที่ใช้ binary `moved_bin`, proximity chat เป็นงานใหม่ที่ต้องสร้าง)
- Grace period 1 วินาทีก่อน disconnect session (ป้องกัน flicker)
- Server broadcast event `proximity:leave` (payload-level naming บน `Envelope.type`) ให้ member ที่เหลือในทันที
- ถ้า user ออกแล้วกลับเข้า radius ภายใน 5 วินาที: rejoin session เดิม

---

## SC-CHAT-04 · ส่งข้อความใน Global / Channel Chat

**ClickUp:** https://app.clickup.com/t/86d2we98u  
**Type:** Happy Path  
**Persona:** Workspace Member  
**Pre-condition:** User เป็น member ของ Workspace, Channel มีอยู่แล้ว  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2017-446920

### Scenario Steps

1. User เลือก Chat Channel จาก Sidebar (เช่น #general, #announcements)
2. เห็น message history ของ Channel
3. พิมพ์ข้อความในช่อง input กด Enter
4. ข้อความแสดงทันที (optimistic update)
5. ทุก member ใน Channel เห็นข้อความ real-time
6. Unread badge อัปเดตสำหรับ member ที่ไม่ได้อยู่ในหน้า Channel

### Acceptance Criteria

- Channel list แสดงใน Sidebar แบ่งตาม Space
- แสดง unread count badge บน Channel ที่มีข้อความใหม่
- ข้อความ max 4,000 ตัวอักษร รองรับ markdown พื้นฐาน
- @mention member ใน Channel ได้ (trigger notification)
- @Everyone mention ทุกคนที่ online ใน Channel
- Pin ข้อความสำคัญได้ (เฉพาะ Admin)
- Message history infinite scroll pagination 50 messages
- Jump to unread button เมื่อเปิด Channel ที่มี unread messages

### Business Logic / Rules

- Channel มี 2 ประเภท: Public (ทุกคนใน Workspace เข้าได้) และ Private (invite only)
- #general เป็น default channel ทุก member ถูก join อัตโนมัติ ลบออกไม่ได้
- @mention สร้าง notification ให้คนที่ถูก mention (SC-CHAT-10)
- Admin เท่านั้น pin / unpin ข้อความได้
- Rate limit: 30 ข้อความ/นาที/user

---

## SC-CHAT-05 · สร้างและส่งข้อความใน Group Chat

**ClickUp:** https://app.clickup.com/t/86d2we9cz  
**Type:** Happy Path  
**Persona:** Logged-in User  
**Pre-condition:** User login แล้ว ต้องการสร้าง Group Chat กับ member หลายคน  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2081-35462

### Scenario Steps

1. User กด "สร้าง Group Chat" ใน Sidebar หรือ Chat panel
2. เปิด modal ค้นหาและเลือก member (2 คนขึ้นไป)
3. ตั้งชื่อ Group (optional — ถ้าไม่ตั้ง ใช้ชื่อ member ต่อกันแทน)
4. กด "สร้าง Group"
5. เปิดหน้า Group Chat ทันที
6. Member ทุกคนได้รับ notification "คุณถูกเพิ่มเข้า Group: [ชื่อ]"
7. User ส่งข้อความแรก — ทุกคนเห็น real-time

### Acceptance Criteria

- เลือก member ได้สูงสุด 50 คน ต่อ Group
- ชื่อ Group optional max 100 ตัวอักษร
- ถ้าไม่ตั้งชื่อ: แสดงชื่อ member รวมกัน เช่น "John, Jane, Bob"
- Group icon แสดง collage avatar ของ member
- Admin Group สามารถ: เพิ่ม/ลบ member, เปลี่ยนชื่อ, เปลี่ยน icon
- Member ธรรมดาสามารถ leave group ได้ตลอดเวลา
- แสดงรายชื่อ member ใน Group info panel
- Message history บันทึกและ searchable

### Business Logic / Rules

- ผู้สร้าง Group เป็น Group Admin อัตโนมัติ
- Group Admin สามารถเพิ่ม member ได้ถึง limit (50 คน)
- ถ้า Group Admin ออก: ย้าย admin ให้ member ที่อยู่นานสุด
- Group ไม่ถูกลบถ้ามี member เหลืออยู่
- ถ้า member ทุกคนออก: Group archived อัตโนมัติ

---

## SC-CHAT-06 · Thread Replies

**ClickUp:** https://app.clickup.com/t/86d2we9ha  
**Type:** Happy Path  
**Persona:** Logged-in User  
**Pre-condition:** มีข้อความอยู่ใน DM / Channel / Group Chat แล้ว  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2096-1032317

### Scenario Steps

1. User hover บนข้อความ — เห็น action bar ปรากฏ
2. กดปุ่ม "ตอบกลับใน Thread"
3. Thread panel เปิดทางขวามือ แสดงข้อความต้นทางและ replies
4. User พิมพ์และส่งข้อความใน thread
5. ใน main chat: ข้อความต้นทางแสดง "X replies" พร้อม avatar ของคนที่ reply
6. Member คนอื่นที่ join thread ได้รับ notification เมื่อมี reply ใหม่

### Acceptance Criteria

- Thread panel เปิด overlay ทางขวา ไม่แทน main chat
- แสดงข้อความต้นทางด้านบนสุดของ Thread panel
- Thread reply count และ avatar preview แสดงใน main chat
- Notification เมื่อมีคน reply ใน thread ที่ user มีส่วนร่วม
- Thread สามารถมี nested reply ได้ 1 ระดับเท่านั้น (ไม่ infinite nesting)
- Thread ใน DM, Channel, Group ทำงานเหมือนกัน

### Business Logic / Rules

- Thread เป็น flat list ของ replies ใต้ parent message (1 level)
- ไม่รองรับ thread ซ้อน thread (ป้องกัน complexity)
- Notification: ส่งให้คนที่ reply ใน thread เดียวกันและ sender ของ parent message
- Thread reply ใช้ Messages Table เดิม โดย `reply_to_id = parent message id`

---

## SC-CHAT-07 · Emoji Reaction

**ClickUp:** https://app.clickup.com/t/86d2we9qh  
**Type:** Happy Path  
**Persona:** Logged-in User  
**Pre-condition:** มีข้อความอยู่ใน Chat  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2096-1559539

### Scenario Steps

1. User hover บนข้อความ — เห็น action bar
2. กด emoji icon — เปิด emoji picker
3. เลือก emoji ที่ต้องการ
4. Reaction แสดงใต้ข้อความทันที (optimistic update)
5. ทุกคนในห้องเห็น reaction อัปเดต real-time
6. กด reaction เดิมอีกครั้ง = ยกเลิก reaction

### Acceptance Criteria

- Emoji picker แสดง frequently used ก่อน พร้อม search emoji
- แสดง reaction count และ user list เมื่อ hover บน reaction
- กด reaction เดิมซ้ำ = toggle off (ยกเลิก)
- 1 message รองรับ reaction ได้สูงสุด 20 emoji ประเภท
- 1 user react emoji เดียวกันได้ครั้งเดียว (ไม่นับซ้ำ)
- Reaction อัปเดต real-time ทุก user ใน room ผ่าน WebSocket
- Quick reaction bar แสดง emoji ยอดนิยม 6 อัน เมื่อ hover

### Business Logic / Rules

- Aggregate count คำนวณ real-time
- WebSocket broadcast event `reaction:update` (logical name บน `Envelope.type` — event นี้ยังไม่มีใน zyra-ws ต้องสร้างใหม่) ทุกครั้งที่มีการเปลี่ยนแปลง
- Emoji ใช้ Unicode standard

---

## SC-CHAT-08 · File / Image Attachment

**ClickUp:** https://app.clickup.com/t/86d2wea2p  
**Type:** Happy Path  
**Persona:** User ใน Chat  
**Pre-condition:** อยู่ใน DM/Channel/Group | File size limit TBD  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2100-1943316

### Scenario Steps

1. กด paperclip หรือ drag & drop ไฟล์
2. Validate client-side
3. แสดง preview + progress bar
4. Upload ไป cloud storage
5. แสดง file/image ใน chat
6. ผู้รับเห็น real-time พร้อม download/preview

### Acceptance Criteria

- รองรับ drag+drop และ file picker
- Image แสดง inline thumbnail ใน chat
- ไฟล์อื่นแสดง file card พร้อม icon ชื่อ ขนาด
- Progress bar ระหว่าง upload พร้อมปุ่ม cancel
- Image click เปิด fullscreen lightbox
- ส่งได้สูงสุด 5 ไฟล์ต่อข้อความ

### Business Logic / Rules

- File size limit: TBD
- Allowed types: image (jpg, png, gif), PDF, DOCX, XLSX, PPTX, ZIP, TXT, CSV
- เก็บใน cloud storage ชื่อไฟล์ UUID (Cloudflare R2)
- Image generate thumbnail 300px server-side
- Virus scan async ก่อน deliver ผู้รับ

---

## SC-CHAT-09 · File Attachment เกิน Limit หรือประเภทผิด

**ClickUp:** https://app.clickup.com/t/86d2wea5b  
**Type:** Error Path  
**Persona:** User — แนบไฟล์เกิน limit หรือประเภทไม่รองรับ  
**Pre-condition:** User พยายาม upload ไฟล์ที่ไม่ผ่าน validation  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2122-70963

### Scenario Steps

1. User เลือกไฟล์ที่ประเภทผิดหรือใหญ่เกิน
2. Validate client-side ทันที
3. แสดง error inline
4. ไฟล์ไม่ถูก upload — User เลือกไฟล์ใหม่หรือยกเลิก

### Acceptance Criteria

- Validate client-side ทันทีที่เลือกไฟล์ก่อน upload
- ไฟล์ผิดประเภท: แสดงชื่อไฟล์และ error "ประเภทไฟล์ไม่รองรับ"
- ไฟล์ใหญ่เกิน: แสดงขนาดจริง เช่น "ไฟล์ของคุณ 25 MB เกิน limit (TBD)"
- เกิน 5 ไฟล์: แสดง "แนบได้สูงสุด 5 ไฟล์ต่อข้อความ ไฟล์ที่เกินถูกตัดออก"
- แสดง error ต่อไฟล์ ไม่ block ไฟล์อื่นที่ valid
- Server-side validate ซ้ำด้วย magic bytes

### Business Logic / Rules

- Client check: `file.type` และ `file.size` ก่อน upload
- Server check: magic bytes ไม่เชื่อ MIME จาก client
- ถ้า 5 ไฟล์บางอันผ่าน บางอันไม่ผ่าน: upload เฉพาะอันที่ผ่าน แจ้ง error อันที่ไม่ผ่าน
- Virus scan fail: แสดง file card สีแดง "ไฟล์นี้ไม่ปลอดภัย ไม่สามารถดาวน์โหลดได้"

---

## SC-CHAT-10 · Unread Badge และ Notification (In-app)

**ClickUp:** https://app.clickup.com/t/86d2weaan  
**Type:** Happy Path  
**Persona:** Logged-in User  
**Pre-condition:** User ไม่ได้อยู่ในหน้า Chat ขณะมีข้อความใหม่เข้ามา  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2138-799995

### Scenario Steps

1. User A ส่งข้อความหา User B ใน DM / Channel / Group
2. User B ไม่ได้อยู่ในหน้า Chat นั้น
3. ระบบสร้าง notification และอัปเดต unread count
4. Unread badge แสดงใน Sidebar บน DM / Channel / Group ที่มีข้อความใหม่
5. In-app notification bell แสดง dot และ count รวม
6. User B กดเข้า Chat: unread badge หายไป, mark as read

### Acceptance Criteria

- Unread badge แสดงจำนวนข้อความที่ยังไม่อ่านบน DM/Channel/Group
- Notification bell icon แสดง total unread count (max แสดง 99+)
- Notification panel แสดง preview ข้อความล่าสุดพร้อม sender avatar
- กดที่ notification: นำไปยัง chat นั้นและ mark as read
- @mention สร้าง notification แยก (highlight สีพิเศษ)
- User ตั้งค่า mute ต่อ DM/Channel/Group ได้ (ไม่แจ้งเตือน)
- Email notification ส่งเมื่อ inactive 5 นาที (batch รวมหลาย message)
- Mark all as read ในคลิกเดียว

### Business Logic / Rules

- Unread count คำนวณจาก messages ที่ `created_at > last_read_at` ของ user
- In-app notification เก็บใน Notifications table (NEW — ยังไม่มี `tb_notification` หรือ `NotificationService` ใน zyra-api; ต้องสร้างใหม่ โดย DB + logic อยู่ zyra-api, real-time push อยู่ zyra-ws, email อยู่ zyra-notifications) และ push ผ่าน WebSocket
- Mute setting เก็บต่อ user ต่อ conversation
- event `notification:new` (logical name บน `Envelope.type` — ยังไม่มีจริง ต้องสร้างใหม่) push ทันทีเมื่อมี message ใหม่

---

## SC-CHAT-11 · Message Search

**ClickUp:** https://app.clickup.com/t/86d2weamj  
**Type:** Happy Path  
**Persona:** User ต้องการค้นหาข้อความ  
**Pre-condition:** User login แล้ว มี message history  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2162-83837

### Scenario Steps

1. กด search icon หรือ Cmd+K
2. เปิด Search panel
3. พิมพ์ keyword
4. Results แบบ real-time debounce 300ms
5. แสดง: ข้อความตรงกัน, sender, channel/DM, timestamp
6. กด result นำไปที่ข้อความพร้อม highlight

### Acceptance Criteria

- ค้นหาครอบคลุม DM/Channel/Group ที่ user มีสิทธิ์
- Full-text search ไทยและอังกฤษ
- Keyword highlight ในผลลัพธ์
- Filter: From (sender), In (channel/DM), Date range
- Max 50 results พร้อม "ดูทั้งหมด"
- Click result: scroll ไปข้อความนั้น highlight 3 วินาที
- ไม่ค้นหาข้อความ proximity chat (ephemeral)

### Business Logic / Rules

- เฉพาะ message ที่ user มีสิทธิ์เห็น
- Debounce 300ms ก่อนส่ง request
- ไม่ค้นหา deleted message

---

## SC-CHAT-12 · Typing Indicator

**ClickUp:** https://app.clickup.com/t/86d2wear8  
**Type:** Happy Path  
**Persona:** Logged-in User  
**Pre-condition:** User กำลังพิมพ์ข้อความใน Chat ที่มีคนอื่นออนไลน์อยู่  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2151-1217508

### Scenario Steps

1. User A เริ่มพิมพ์ข้อความในช่อง input
2. ระบบส่ง typing event ผ่าน WebSocket ทันที
3. User B เห็น "John กำลังพิมพ์..." พร้อม animated dots (...)
4. ถ้ามีหลายคนพิมพ์พร้อมกัน: "John และ Jane กำลังพิมพ์..."
5. ถ้ามีมากกว่า 3 คน: "หลายคนกำลังพิมพ์..."
6. User A หยุดพิมพ์ 3 วินาที หรือส่งข้อความ: typing indicator หายไป

### Acceptance Criteria

- Typing indicator แสดงในทุก chat type: DM, Channel, Group
- Animated dots animation (3 จุดวิ่ง)
- 1 คน: "[ชื่อ] กำลังพิมพ์..."
- 2–3 คน: "[ชื่อ1] และ [ชื่อ2] กำลังพิมพ์..."
- 4+ คน: "หลายคนกำลังพิมพ์..."
- หายไปทันทีเมื่อส่งข้อความหรือ clear input
- หายไปอัตโนมัติหลังหยุดพิมพ์ 3 วินาที (timeout server-side)
- ไม่แสดง typing indicator ของตัวเอง

### Business Logic / Rules

- WebSocket event `typing:start` / `typing:stop` (logical name บน `Envelope.type` — typing indicator ยังไม่มีใน zyra-ws ต้องสร้างใหม่)
- Server timeout 3 วินาทีหลังได้รับ event ล่าสุด ถ้าไม่มี `typing:stop`
- ไม่ broadcast typing event กลับไปหา sender
