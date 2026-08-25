# Chat Module — คู่มือการใช้งาน & วิธีทำงาน

**Version:** 1.0 · **Date:** 2026-06-29 · **Status:** Implemented (SC-CHAT-01 ~ SC-CHAT-12)
**Refs:** `spec.md` · `technical-design.md` · `task-breakdown.md` · `test-plan.md` · `ux-ui-plan.md`

> เอกสารนี้สรุปว่า **Chat ทำงานยังไง** และ **ผู้ใช้กดตรงไหนเพื่อทำอะไร** ครอบคลุมทั้ง 12 ฟีเจอร์
> โค้ดอยู่ใน 4 services: `zyra-app` (Next.js FE), `zyra-api` (Go REST), `zyra-ws` (Go WebSocket), `zyra-notifications` (Go email)

---

## 1. ภาพรวม (TL;DR)

Chat คือระบบแชทในตัว Zyra ที่เปิดจากหน้า Workspace มี 12 ฟีเจอร์:

| # | ฟีเจอร์ | ผู้ใช้กดตรงไหน (สั้น ๆ) |
|---|---------|--------------------------|
| 1 | **Direct Message (DM)** | Sidebar → "Start a new chat" → เลือกคน / คลิก DM ในรายการ |
| 2 | **Proximity Chat** | เดิน avatar เข้าใกล้คนอื่นใน Virtual Office → panel เด้งเอง |
| 3 | **ออกจาก Proximity** | เดิน avatar ออกห่าง → toast เตือน 2 วิ → panel ปิด |
| 4 | **Channel Chat** | Sidebar → section "Channels" → เลือก #channel |
| 5 | **Group Chat** | Sidebar → "Start a new chat" → New Group → เลือกสมาชิก 2+ |
| 6 | **Thread Reply** | Hover ข้อความ → ไอคอน thread → พิมพ์ใน panel ขวา |
| 7 | **Emoji Reaction** | Hover ข้อความ → ไอคอน emoji → เลือก emoji |
| 8 | **File / Image** | ไอคอน 📎 ในกล่องพิมพ์ หรือ ลากไฟล์มาวาง |
| 9 | **File error** | เลือกไฟล์ผิด type/ใหญ่เกิน → error แสดงใต้ไฟล์นั้น |
| 10 | **Unread + Notification** | Badge แดงบนรายการแชท + กระดิ่ง 🔔 บนหัว sidebar |
| 11 | **Search** | ไอคอนค้นหาใน sidebar หรือกด **Cmd/Ctrl + K** |
| 12 | **Typing Indicator** | พิมพ์ในแชท → อีกฝั่งเห็น "… กำลังพิมพ์" อัตโนมัติ |

**เข้าหน้า Chat:** route `/workspace/[id]/chat` (มาจากปุ่ม Chat ใน sidebar ของ workspace)

---

## 2. สถาปัตยกรรม (ใครรับผิดชอบอะไร)

```
                          ┌───────────────────────────────┐
                          │  zyra-app (Next.js, :3000)    │
                          │  views/chat/* + stores/*      │
                          └───────┬───────────────┬───────┘
              REST (HTTPS)        │               │   WebSocket (เชื่อมเส้นเดียวกับ Virtual Office)
                                  ▼               ▼
              ┌───────────────────────────┐  ┌──────────────────────────────┐
              │  zyra-api :3001 (Gin)     │  │  zyra-ws :3004 (Hub)         │
              │  /api/user/chat/*         │  │  relay: message/edit/delete, │
              │  /api/user/notifications  │  │  reaction, typing, proximity │
              │  เก็บข้อความ + business    │  │  (ไม่แตะ DB — แค่ fan-out)    │
              └───────┬───────────────────┘  └───────────────┬──────────────┘
                      │                                       │
        ┌─────────────┼─────────────┐                         │ (proximity = ephemeral
        ▼             ▼             ▼                          │  ไม่บันทึก DB)
  ┌──────────┐ ┌────────────┐ ┌─────────────────┐
  │PostgreSQL│ │Cloudflare R2│ │zyra-notifications│  ← email digest (template "chat_digest")
  │ :5432    │ │ (ไฟล์แนบ)   │ │ :3003 (อีเมล)    │
  └──────────┘ └────────────┘ └─────────────────┘
```

**หลักการแบ่งงาน**
- **เก็บถาวร (REST → zyra-api → PostgreSQL):** ข้อความ, conversation, reaction, attachment metadata, notification, unread cursor → REST คือ **source of truth**
- **เรียลไทม์ (WebSocket → zyra-ws):** กระจายข้อความ/typing/reaction/proximity ให้สมาชิกที่ online — **ไม่แตะ DB** แค่ relay
- **อีเมล (zyra-notifications):** email digest เมื่อ user inactive (ไม่มี SMTP ใน zyra-api; ถ้า `NOTIFICATION_SERVICE_URL` ว่าง = ข้าม ไม่ error)
- **ไฟล์ (Cloudflare R2):** เก็บไฟล์แนบ + thumbnail; DB เก็บแค่ URL

> **สำคัญ:** WS ไม่ echo ข้อความกลับให้คนส่ง → ฝั่งคนส่งต้อง **optimistic render** เอง (REST ยืนยันแล้วค่อย relay ให้คนอื่น)

---

## 3. วิธีใช้งานแต่ละฟีเจอร์ (กดตรงไหน + เบื้องหลังทำอะไร)

### 3.1 เปิดหน้า Chat
- ไปที่ `/workspace/{id}/chat` → เห็น **Sidebar ซ้าย (320px)** + **panel ขวา**
- รองรับ deep-link `?conv={id}` เพื่อเปิดแชทนั้นทันที
- ตอน mount: โหลด `listConversations` + `getUnreadCounts` และต่อ WS handlers (ถ้า user เข้า Virtual Office อยู่)

### 3.2 Direct Message (SC-CHAT-01)
**กด:** Sidebar → ปุ่มเขียว **"Start a new chat"** → เลือกสมาชิก → เปิด DM panel (หรือคลิกชื่อใน section "Direct messages")
**ทำงาน:**
- พิมพ์ → **Enter ส่ง**, **Shift+Enter ขึ้นบรรทัด**
- ข้อความเด้งทันทีฝั่งคนส่ง (optimistic, จาง ๆ ตอน "sending") → REST ยืนยัน → relay ให้ผู้รับเห็นเรียลไทม์
- ส่งไม่สำเร็จ → ข้อความขึ้นสถานะ "failed" + ปุ่ม retry
- เลื่อนขึ้นบนสุด = โหลดข้อความเก่า (infinite scroll, 50/หน้า)
- จำกัด: ข้อความ ≤ 4,000 ตัวอักษร, 30 ข้อความ/นาที/คน

### 3.3 Proximity Chat (SC-CHAT-02 / 03)
**กด:** ไม่ต้องกด — เดิน avatar ใน **Virtual Office** (`/workspace/{id}/play`) เข้าใกล้ avatar คนอื่น → **panel เด้งอัตโนมัติ**
**ทำงาน:**
- FE คำนวณ "ใครอยู่ใกล้" จากตำแหน่ง avatar แล้วจับเป็น session ตาม grid-bucket (รัศมี ~5 tiles)
- พิมพ์คุยได้แบบ **ephemeral — ไม่บันทึกประวัติ** (ผ่าน WS `proximity:text` เท่านั้น)
- เดินออกห่าง → toast "กำลังออกจากพื้นที่สนทนา..." 2 วิ (มี grace 1 วิ กันกระพริบ, กลับเข้าภายใน 5 วิ ไม่ rejoin ซ้ำ) → panel fade ปิด, ข้อความที่พิมพ์ค้างถูกทิ้ง

### 3.4 Channel Chat (SC-CHAT-04)
**กด:** Sidebar → section **"Channels"** → เลือก `#channel`
**ทำงาน:**
- Header แสดง `#ชื่อ` + จำนวนสมาชิก
- สร้าง channel ได้เฉพาะ **workspace owner/admin**; ลบ `#general` (default) ไม่ได้
- Admin ของ channel: pin/unpin ข้อความ, เพิ่ม/ลบสมาชิก, เปลี่ยนชื่อ
- รองรับ @mention (สร้าง notification ให้คนที่ถูก mention)

### 3.5 Group Chat (SC-CHAT-05)
**กด:** Sidebar → "Start a new chat" → **New Group** → ค้นหา+เลือกสมาชิก (2–50 คน) → ตั้งชื่อ (ไม่บังคับ) → **Create**
**ทำงาน:**
- ไม่ตั้งชื่อ → ใช้ชื่อสมาชิกต่อกัน (auto-name)
- ผู้สร้าง = group admin อัตโนมัติ
- admin ออก → เลื่อน admin ให้คนที่อยู่นานสุด; สมาชิกออกหมด → group ถูก archive

### 3.6 Thread Reply (SC-CHAT-06)
**กด:** hover ข้อความ → ไอคอน **reply/thread** ใน action bar → panel เปิดด้านขวา
**ทำงาน:**
- บนสุดของ panel = ข้อความต้นทาง (quote), ด้านล่าง = รายการ reply เรียงเวลา
- ข้อความหลักโชว์ "{n} replies"
- **Thread ลึกได้ 1 ระดับ** (reply ของ reply ไม่ได้ — backend reject)

### 3.7 Emoji Reaction (SC-CHAT-07)
**กด:** hover ข้อความ → ไอคอน **emoji** → quick bar (7 อัน) หรือกด **[+]** เปิด picker เต็ม (มี search + frequently-used)
**ทำงาน:**
- กด emoji → chip ขึ้นใต้ข้อความ (optimistic) → broadcast ให้ทุกคนเห็น
- กด emoji เดิมซ้ำ = toggle ออก
- กดที่ตัวเลข reaction → เปิด modal ดูว่าใครกดบ้าง
- จำกัด 20 ชนิด emoji/ข้อความ, 1 คน 1 emoji ต่อข้อความ

### 3.8 File / Image Attachment (SC-CHAT-08)
**กด:** ไอคอน **📎** ในกล่องพิมพ์ หรือ **ลากไฟล์มาวาง** บน panel
**ทำงาน:**
- รูป → แสดง thumbnail inline, คลิกเปิด **lightbox** (เลื่อนซ้าย/ขวาได้ถ้าหลายรูป, Esc ปิด)
- ไฟล์อื่น → file card (ไอคอนตาม type + ชื่อ + ขนาด + ปุ่มดาวน์โหลด)
- ระหว่าง upload มี progress bar + ปุ่ม cancel
- จำกัด: ≤ 5 ไฟล์/ข้อความ, ≤ 25 MB/ไฟล์
- type ที่รองรับ: jpg, png, gif, webp, pdf, docx, xlsx, pptx, zip, txt, csv
- ไฟล์ติดไวรัส (scan = infected) → card สีแดง, ไม่มีปุ่มดาวน์โหลด

### 3.9 File Error (SC-CHAT-09)
**เกิดเมื่อ:** เลือกไฟล์ผิด type / ใหญ่เกิน / เกิน 5 ไฟล์
**ทำงาน:**
- Validate ฝั่ง client ทันที → error แสดงใต้ไฟล์ที่ผิด (ไม่บล็อกไฟล์อื่นที่ผ่าน)
- Server ตรวจซ้ำด้วย **magic bytes** (ไม่เชื่อ MIME จาก client) — สแปม `.exe` ปลอมเป็น `.jpg` จะถูกปฏิเสธ

### 3.10 Unread Badge & Notification (SC-CHAT-10)
**ดูตรงไหน:**
- **Badge แดง** บนรายการแชทที่มีข้อความใหม่ (cap "99+")
- **กระดิ่ง 🔔** บนหัว sidebar → dropdown รายการ notification (มี avatar + preview + เวลา + จุดยังไม่อ่าน, @mention ไฮไลต์เขียว)
**ทำงาน:**
- กดเข้าแชท → badge หาย (markRead)
- กด notification → พาไปแชทนั้น + mark read
- "Mark all as read" เคลียร์ทั้งหมด
- **Mute** ต่อแชทได้ (ปุ่ม More → Conversation info → toggle Mute) → ไม่แจ้งเตือน, ไอคอนกระดิ่งขีดฆ่าใน sidebar
- **Email digest:** ถ้า inactive ส่งสรุปทางอีเมล (ผ่าน zyra-notifications, template `chat_digest`)
- *หมายเหตุ:* notification ดึงผ่าน REST (mount + เมื่อ window focus + เมื่อมีข้อความเข้าแชทที่ไม่ได้เปิด) — ไม่มี WS push เฉพาะ notification

### 3.11 Message Search (SC-CHAT-11)
**กด:** ไอคอนค้นหาใน sidebar หรือ **Cmd/Ctrl + K**
**ทำงาน:**
- พิมพ์ → debounce 300ms → ค้นด้วย PostgreSQL full-text (ไทย+อังกฤษ)
- กรองได้: **From** (ผู้ส่ง), **In** (แชท), **Date range**
- ผลลัพธ์ไฮไลต์คำที่ตรง (`<mark>` render แบบ safe ไม่ใช้ dangerouslySetInnerHTML)
- กดผลลัพธ์ → ปิด panel → เปิดแชท → scroll ไปข้อความนั้น + ไฮไลต์เขียว 3 วิ
- ไม่ค้น proximity (ephemeral) และข้อความที่ลบ

### 3.12 Typing Indicator (SC-CHAT-12)
**เห็นเมื่อ:** อีกฝั่งกำลังพิมพ์
**ทำงาน:**
- พิมพ์ → ส่ง `chat:typing:start` (กันรัวด้วย flag) → หยุด 3 วิ / ส่ง / blur = `chat:typing:stop`
- ข้อความ: 1 คน → "{ชื่อ} กำลังพิมพ์...", 2–3 คน → "{a} และ {b}...", 4+ → "หลายคนกำลังพิมพ์..."
- มี dot เด้ง 3 จุด, ไม่โชว์ของตัวเอง, auto-หายถ้าไม่มี refresh ภายใน 3 วิ

---

## 4. API Endpoints (zyra-api, ภายใต้ UserGuard)

> Member เรียกเฉพาะ `/api/user/*` เท่านั้น (Member API Separation)

### Conversations
| Method | Path | ใช้ทำ |
|--------|------|-------|
| GET | `/api/user/chat/conversations?workspace_id=` | รายการแชททั้งหมด |
| POST | `/api/user/chat/conversations/dm` | สร้าง/เปิด DM |
| POST | `/api/user/chat/conversations/group` | สร้าง group |
| GET | `/api/user/chat/conversations/:id` | รายละเอียดแชท |
| PATCH | `/api/user/chat/conversations/:id` | เปลี่ยนชื่อ (admin) |
| POST | `/api/user/chat/conversations/:id/members` | เพิ่มสมาชิก (admin) |
| DELETE | `/api/user/chat/conversations/:id/members/:userId` | ลบสมาชิก (admin) |
| DELETE | `/api/user/chat/conversations/:id/membership` | ออกจากแชท |
| PATCH | `/api/user/chat/conversations/:id/mute` | toggle mute |
| POST | `/api/user/chat/conversations/:id/read` | mark read |

### Channels
| Method | Path | ใช้ทำ |
|--------|------|-------|
| GET | `/api/user/chat/channels?workspace_id=` | รายการ channel |
| POST | `/api/user/chat/channels` | สร้าง channel (ws owner/admin) |
| DELETE | `/api/user/chat/channels/:id` | ลบ channel (ไม่ใช่ #general) |

### Messages
| Method | Path | ใช้ทำ |
|--------|------|-------|
| GET | `/api/user/chat/conversations/:id/messages?before=&limit=` | ประวัติ (cursor) |
| POST | `/api/user/chat/conversations/:id/messages` | ส่งข้อความ |
| PATCH | `/api/user/chat/messages/:id` | แก้ไข (เจ้าของ) |
| DELETE | `/api/user/chat/messages/:id` | ลบ (soft, เจ้าของ/admin) |
| GET | `/api/user/chat/messages/:id/thread` | reply ใน thread |
| POST / DELETE | `/api/user/chat/messages/:id/pin` | pin / unpin (admin) |

### Reactions / Attachments / Unread / Search
| Method | Path | ใช้ทำ |
|--------|------|-------|
| POST | `/api/user/chat/messages/:id/reactions` | เพิ่ม reaction |
| DELETE | `/api/user/chat/messages/:id/reactions/:emoji` | ลบ reaction |
| GET | `/api/user/chat/messages/:id/reactions` | รายการ reaction |
| POST | `/api/user/chat/attachments` | upload ไฟล์ (multipart) |
| DELETE | `/api/user/chat/attachments/:id` | ยกเลิกไฟล์ (ก่อน link) |
| GET | `/api/user/chat/unread?workspace_id=` | จำนวน unread ต่อแชท |
| GET | `/api/user/chat/search?q=&in=&from=&after=&before=&limit=` | ค้นหา |

### Notifications (ไม่อยู่ใต้ /chat)
| Method | Path | ใช้ทำ |
|--------|------|-------|
| GET | `/api/user/notifications?limit=&before=` | รายการ notification |
| POST | `/api/user/notifications/read-all` | อ่านทั้งหมด |
| PATCH | `/api/user/notifications/:id/read` | อ่านอันเดียว |

---

## 5. WebSocket Events (zyra-ws — ใช้ connection เดียวกับ Virtual Office)

Envelope: `{ "type": "...", "payload": { ... } }`

| Inbound (client→server) | Outbound (server→สมาชิกคนอื่น) | หมายเหตุ |
|---|---|---|
| `chat:join` / `chat:leave` `{conversation_id}` | — | subscribe/unsubscribe ห้องแชท |
| `chat:message` `{conversation_id, message}` | `chat:message:new` | ส่ง **หลัง** REST persist สำเร็จ |
| `chat:message:edit` | `chat:message:edit` | |
| `chat:message:delete` `{…, message_id}` | `chat:message:delete` | |
| `chat:reaction` `{…, message_id, reactions}` | `chat:reaction:update` | |
| `chat:typing:start` / `chat:typing:stop` `{…, user}` | `chat:typing` `{…, user, typing}` | |
| `proximity:join` / `proximity:leave` `{session_id}` | `proximity:join` / `proximity:leave` | |
| `proximity:text` `{session_id, text}` | `proximity:message` | **ไม่บันทึก DB** |

> ทุก relay ส่งให้ "คนอื่น" ในห้อง ไม่ส่งกลับคนส่ง · disconnect = ถอด subscription ทั้งหมดอัตโนมัติ

---

## 6. Database (zyra-api / PostgreSQL) — migration `52_create_chat_tables.sql`

| ตาราง | เก็บอะไร |
|-------|----------|
| `tb_conversation` | DM / channel / group (FK → tb_workspace UUID) |
| `tb_conversation_member` | สมาชิก + role(admin/member) + muted + left_at |
| `tb_message` | ข้อความ (reply_to_id = thread 1 ระดับ, soft delete, FTS GIN index) |
| `tb_message_reaction` | 1 user / 1 emoji / message (unique) |
| `tb_message_attachment` | ไฟล์แนบ (R2 url + thumb + scan_status) |
| `tb_user_last_read` | cursor อ่านล่าสุด → คำนวณ unread |
| `tb_notification` | in-app notification + email_digest_sent_at |

> ID เป็น hybrid: คอลัมน์อ้าง `tb_user` เป็น VARCHAR, อ้าง `tb_workspace` เป็น UUID (ตาม schema เดิม)

---

## 7. โครงสร้างไฟล์

### zyra-app (Frontend)
```
app/workspace/[id]/chat/page.tsx          ← route → HeroChat
views/chat/
  hero-chat.tsx                            ← orchestrator (sidebar + panel + overlays)
  components/
    chat-sidebar.tsx  chat-avatar.tsx  chat-utils.ts
    dm-panel.tsx  channel-panel.tsx  message-list.tsx
    message-item.tsx  message-input.tsx
    emoji-picker.tsx  emoji-data.ts  reaction-modal.tsx
    thread-panel.tsx  create-group-modal.tsx
    attachment-utils.tsx  file-preview.tsx
    notification-bell.tsx  search-panel.tsx
    conversation-info-panel.tsx
    typing-indicator.tsx  use-typing-emitter.ts
views/user/virtual-office/components/vo-proximity-panel.tsx  ← proximity overlay
stores/chat-store.ts          ← useChatStore (Zustand)
stores/proximity-store.ts     ← proximity (ephemeral)
lib/api/chat.ts               ← REST helpers (ผ่าน authFetch)
lib/api/chat-ws.ts            ← attachChatHandlers (inbound → store)
lib/api/proximity-ws.ts       ← attachProximityHandlers
lib/api/workspace-ws.ts       ← WorkspaceWSClient (+chat/proximity send methods)
```

### zyra-api (Backend)
```
migrations/52_create_chat_tables.sql
internal/model/chat.go
internal/service/{chat_service,attachment_service,notification_service,chat_search_service}.go
internal/handler/{chat_handler,attachment_handler,notification_handler,chat_search_handler}.go
internal/router/router.go     ← routes ใต้ user.Group("/chat")
main.go                       ← wiring + scan loop + digest loop
```

### zyra-ws & zyra-notifications
```
zyra-ws/internal/hub/{chat.go, proximity.go}  (+ message.go/room.go/client.go)
zyra-notifications/internal/mailer/{mailer.go, templates.go}  ← template "chat_digest"
```

---

## 8. การรันในเครื่อง (local)

ต้องเปิดครบ stack:

| Service | Port | คำสั่ง |
|---------|------|--------|
| PostgreSQL | 5432 | (apply migration `52_*` ก่อน) |
| Redis | 6379 | (เผื่อ VO/proximity) |
| zyra-api | 3001 | `cd zyra-api && go run .` |
| zyra-ws | 3004 | `cd zyra-ws && go run .` |
| zyra-notifications | 3003 | `cd zyra-notifications && go run .` *(ไม่เปิดก็ได้ — อีเมลจะถูกข้าม)* |
| zyra-app | 3000 | `cd zyra-app && npm run dev` |

**ENV ที่เกี่ยว (zyra-api):**
```
DATABASE_URL=...                 # ต้อง migrate ตาราง chat แล้ว
REDIS_URL=redis://localhost:6379/0
AWS_BUCKET_* / AWS_PUBLIC_URL    # สำหรับไฟล์แนบ (R2) — ไม่ตั้ง = upload ปิด
NOTIFICATION_SERVICE_URL=http://localhost:3003   # ว่าง = ข้าม email digest
NOTIFICATION_API_KEY=...
```

---

## 9. Testing

| ชั้น | คำสั่ง | สถานะ |
|------|--------|-------|
| Go unit (zyra-api) | `cd zyra-api && go test ./internal/service/...` | ✅ pure-fn validation tests |
| Go (zyra-ws) | `cd zyra-ws && go test ./...` | ✅ relay/reaction/typing/proximity (+`-race`) |
| FE unit (vitest) | `cd zyra-app && npm run test` | ✅ 97 chat tests (store/api/ws) |
| FE coverage | `npx vitest run --coverage` | ✅ chat files ≥ threshold |
| E2E (Playwright) | `npm run e2e:list` (offline) / `E2E_LIVE=1 npm run e2e` | specs พร้อม, รันจริงต้องมี stack + seeded users |

ดูรายละเอียด E2E ที่ `zyra-app/e2e/README.md`

---

## 10. ข้อจำกัด / งานที่ค้าง

- **Virus scan = stub** — ปัจจุบัน mark pending → clean ทุก 30 วิ (ยังไม่ต่อ AV engine จริง — ดู Open Question #2 ใน `technical-design.md`)
- **Visual regression baselines (CHAT-060)** — มี CI job + placeholder spec แต่ต้อง capture baseline บน live app ก่อน (gate ด้วย `VR_LIVE`)
- **Storybook (CHAT-062)** — ยังไม่ทำ (optional)
- **Go coverage gate** — ตั้ง warn-only เพราะ service ใช้ `*pgxpool.Pool` concrete (unit test ครอบเฉพาะ pure functions; DB paths ต้องพึ่ง integration/E2E)
- **Proximity** — ใช้ grid-bucket detection ฝั่ง client; กรณี avatar คาบเส้น bucket อาจไม่จับคู่จนกว่าจะข้ามเส้น (มี grace 1 วิ + rejoin 5 วิ ลด flicker)
- **Notification** — delivery แบบ REST-fetch (ไม่มี WS push เฉพาะ notification); unread badge มาจาก WS message + fetch
```
