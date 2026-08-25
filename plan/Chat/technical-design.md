# Technical Design — Chat Module

**Version:** 1.1  
**Date:** 2026-06-29  
**Scope:** SC-CHAT-01 ~ SC-CHAT-12  
**Depends on:** zyra-api (Go/Gin), zyra-ws (Go/WS), zyra-app (Next.js 16), zyra-notifications (Go, email only)

**Changelog:** v1.1 (2026-06-29) — Codebase Alignment: ปรับเอกสารให้ตรงกับโค้ดจริง

### Codebase Alignment (v1.1)

- **Email boundary** — zyra-api ไม่มี SMTP/email code ในตัว; transactional email ทุกชนิดถูก delegate ไป zyra-notifications microservice (POST `/v1/email`, header `X-Notification-Key`) ผ่าน `notify.Client`. ถ้า `NOTIFICATION_SERVICE_URL` ว่าง → no-op (ไม่มี SMTP fallback). chat digest template ยังไม่มี — เป็นงานใหม่ใน zyra-notifications.
- **`tb_notification` + NotificationService = NEW** — ปัจจุบันยังไม่มี table หรือ service นี้อยู่จริงในทั้ง 3 service. In-app notification (DB + logic) เป็นของ zyra-api, WS push เป็นของ zyra-ws, email เป็นของ zyra-notifications.
- **WS protocol** — zyra-ws ใช้ native WebSocket envelope `Envelope{type, payload}` + binary `moved_bin`; ชื่อ type จริงเป็น constant `ClientMsg*`/`Msg*`. ปัจจุบันมีแค่ `MsgChat` (broadcast ทั้งห้อง workspace) — per-conversation room, typing, proximity, rate-limit ยังไม่มี ต้อง build บน primitive ที่มีอยู่ (Room ต่อ workspace, AOI grid, Redis `vo:*` keys).
- **Frontend paths** — ไม่มี `lib/api/chat.ts`, `lib/ws/chat-ws.ts`, `stores/chat-store.ts`, route `chat/page.tsx`. Client จริง: REST = `authFetch` (`lib/api/client.ts`), WS = `WorkspaceWSClient` (`lib/api/workspace-ws.ts`, มี `chat(content)` อยู่แล้ว), renderer = `PixiGameScene`. ไฟล์ chat ใหม่ทั้งหมดต้องสร้างตาม convention เดิม.
- **DB ids = hybrid** — `tb_user.id` เป็น VARCHAR; `tb_workspace`/`tb_map` ใช้ native UUID. FK ที่ชี้ workspace ต้องเป็น UUID + cast `::text` เมื่อ return.
- **Migration เริ่มที่ 52** — migration สูงสุดจริงปัจจุบันคือ `51_workspace_transfer_columns.sql`.

---

## 1. System Architecture

> **Alignment note (v1.1):** เป้าหมาย path/component ในไดอะแกรมส่วนใหญ่เป็น **NEW (ต้องสร้างใหม่)**. ของจริงปัจจุบัน: REST client = `authFetch` (`lib/api/client.ts`), WS client = `WorkspaceWSClient` (`lib/api/workspace-ws.ts`, มี `chat(content)` อยู่แล้ว) — ไม่มี `lib/api/chat.ts` / `lib/ws/chat-ws.ts`. zyra-ws ใช้ native WS envelope (ไม่ใช่ Socket.IO) และยังไม่มี per-conversation room. email ทั้งหมดออกผ่าน zyra-notifications (port 3003), ไม่ใช่ใน zyra-api.

```
┌─────────────────────────────────────────────────────────────┐
│                        zyra-app (Next.js)                    │
│  views/chat/ (NEW)    lib/api/chat.ts(NEW) WorkspaceWSClient │
│  ├── hero-chat.tsx    ├── listChannels()  (lib/api/         │
│  ├── dm-panel.tsx     ├── listMessages()    workspace-ws.ts)│
│  ├── channel-panel    ├── sendMessage()   ├── chat(content) │
│  └── search-panel     └── searchMessages()└── + chat:* (NEW)│
└──────────────┬──────────────────────┬────────────────────────┘
               │ REST (HTTPS)         │ WebSocket (WSS, native envelope)
               ▼                      ▼
┌──────────────────────┐  ┌───────────────────────────────────┐
│  zyra-api :3001      │  │  zyra-ws :3004                    │
│  (Gin + PostgreSQL)  │  │  (Go + Redis, native WS)          │
│                      │  │  now: MsgChat (broadcast ทั้งห้อง) │
│  /api/user/chat/*    │  │  NEW: ConversationRoom registry   │
│  /api/user/notify/*  │  │  events: message, typing,         │
│  /api/user/search    │  │  reaction, presence, proximity    │
└──────────┬───────────┘  └─────────────┬─────────────────────┘
           │ notify.Client (POST /v1/email)        │
           ▼                            ▼
┌──────────────────┐        ┌───────────────────┐
│  PostgreSQL :5432│        │  Redis :6379       │
│  tb_conversation │        │  typing TTL (NEW)  │
│  tb_message      │        │  proximity (NEW)   │
│  tb_reaction     │        │  chat rate limit   │
│  tb_attachment   │        │  vo:* keys (now)   │
│  tb_notification │        └───────────────────┘
│  tb_user_lastread│
└──────────────────┘                   │ email only
           │                           ▼
           ▼              ┌──────────────────────────┐
┌──────────────────┐      │ zyra-notifications :3003 │
│ Cloudflare R2    │      │ POST /v1/email           │
│ chat/{convId}/   │      │ templates: otp, welcome, │
│  {uuid}.jpg      │      │ reset_password, …        │
│  {uuid}.pdf …    │      │ chat digest = NEW        │
└──────────────────┘      └──────────────────────────┘
```

### Service Responsibilities

| Service | Role in Chat |
|---|---|
| **zyra-api** (:3001) | REST: history, channel/group CRUD, reactions, attachments, search; owns `tb_notification` (DB + logic, **NEW**); triggers email via `notify.Client` |
| **zyra-ws** (:3004) | WebSocket: real-time message fan-out, typing, reactions broadcast, proximity session (per-conversation routing + typing/proximity = **NEW** on existing Room primitives) |
| **zyra-notifications** (:3003) | **Email only** — POST `/v1/email` (`notify.Client`). Owns SMTP/Gmail. chat digest template = **NEW** |
| **PostgreSQL** | Persistent storage for all messages (except proximity), reactions, attachments, notifications |
| **Redis** | Ephemeral: typing TTL, proximity rooms, WS rate-limit counters, read-receipt dedup (these chat keys are **NEW**; zyra-ws currently has only `vo:*` keys) |
| **Cloudflare R2** | File/image storage under `chat/{conversationId}/{uuid}.ext` |

---

## 2. Database Schema

> **ID scheme เป็นแบบ hybrid** — `tb_user.id` เป็น `VARCHAR` (string ไม่ใช่ UUID type) ส่วน `tb_workspace`/`tb_map` ใช้ native PostgreSQL `UUID` (`gen_random_uuid()`) แล้ว cast `::text` ตอน return ให้ application. ดังนั้น: คอลัมน์ chat ที่อ้างอิง **user** (`created_by`, `sender_id`, `user_id`, `actor_id`) ใช้ `VARCHAR REFERENCES tb_user(id)`; คอลัมน์ที่อ้างอิง **workspace** ต้องเป็น `UUID REFERENCES tb_workspace(id)` (cast `::text` เมื่อ return). chat tables เองใช้ `gen_random_uuid()::text` (VARCHAR) เป็น PK ได้.

### 2.1 `tb_conversation`

```sql
CREATE TABLE tb_conversation (
    id            VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    workspace_id  UUID NOT NULL REFERENCES tb_workspace(id) ON DELETE CASCADE,  -- tb_workspace.id is native UUID; cast ::text on return
    type          VARCHAR NOT NULL CHECK (type IN ('dm', 'channel', 'group')),
    name          VARCHAR(100),           -- NULL for DM, required for group/channel
    is_default    BOOLEAN NOT NULL DEFAULT false,  -- true = #general (cannot be deleted)
    is_private    BOOLEAN NOT NULL DEFAULT false,  -- channel: private invite-only
    created_by    VARCHAR NOT NULL REFERENCES tb_user(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at   TIMESTAMPTZ              -- set when all members leave (group only)
);

CREATE INDEX idx_conv_workspace ON tb_conversation(workspace_id);
CREATE INDEX idx_conv_type      ON tb_conversation(type);
```

### 2.2 `tb_conversation_member`

```sql
CREATE TABLE tb_conversation_member (
    id              VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    conversation_id VARCHAR NOT NULL REFERENCES tb_conversation(id) ON DELETE CASCADE,
    user_id         VARCHAR NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
    role            VARCHAR NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    muted           BOOLEAN NOT NULL DEFAULT false,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    left_at         TIMESTAMPTZ,          -- NULL = active member
    UNIQUE (conversation_id, user_id)
);

CREATE INDEX idx_conv_member_user ON tb_conversation_member(user_id);
CREATE INDEX idx_conv_member_conv ON tb_conversation_member(conversation_id);
```

### 2.3 `tb_message`

```sql
CREATE TABLE tb_message (
    id              VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    conversation_id VARCHAR NOT NULL REFERENCES tb_conversation(id) ON DELETE CASCADE,
    sender_id       VARCHAR NOT NULL REFERENCES tb_user(id),
    reply_to_id     VARCHAR REFERENCES tb_message(id),  -- NULL = top-level; non-NULL = thread reply (1 level)
    content         TEXT,               -- max 4000 chars; NULL if attachment-only message
    content_type    VARCHAR NOT NULL DEFAULT 'text' CHECK (content_type IN ('text', 'attachment', 'system')),
    is_edited       BOOLEAN NOT NULL DEFAULT false,
    edited_at       TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ,        -- soft delete — keep row for thread count integrity
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Composite index: fetch last N messages per conversation
CREATE INDEX idx_msg_conv_created  ON tb_message(conversation_id, created_at DESC);
-- Thread replies
CREATE INDEX idx_msg_reply_to      ON tb_message(reply_to_id) WHERE reply_to_id IS NOT NULL;
-- Full-text search (Thai + English)
CREATE INDEX idx_msg_fts           ON tb_message USING GIN (to_tsvector('simple', coalesce(content, '')));
```

### 2.4 `tb_message_reaction`

```sql
CREATE TABLE tb_message_reaction (
    id          VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    message_id  VARCHAR NOT NULL REFERENCES tb_message(id) ON DELETE CASCADE,
    user_id     VARCHAR NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
    emoji       VARCHAR NOT NULL,       -- Unicode emoji character e.g. "👍"
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (message_id, user_id, emoji) -- 1 user 1 emoji per message
);

CREATE INDEX idx_reaction_message ON tb_message_reaction(message_id);
```

### 2.5 `tb_message_attachment`

```sql
CREATE TABLE tb_message_attachment (
    id          VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    message_id  VARCHAR NOT NULL REFERENCES tb_message(id) ON DELETE CASCADE,
    file_url    VARCHAR NOT NULL,       -- R2 public URL
    thumb_url   VARCHAR,                -- R2 thumbnail URL (images only, 300px)
    file_name   VARCHAR NOT NULL,       -- original filename for display
    file_size   BIGINT NOT NULL,        -- bytes
    mime_type   VARCHAR NOT NULL,
    scan_status VARCHAR NOT NULL DEFAULT 'pending'
                    CHECK (scan_status IN ('pending', 'clean', 'infected')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_attachment_message ON tb_message_attachment(message_id);
```

### 2.6 `tb_user_last_read`

```sql
CREATE TABLE tb_user_last_read (
    user_id         VARCHAR NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
    conversation_id VARCHAR NOT NULL REFERENCES tb_conversation(id) ON DELETE CASCADE,
    last_read_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, conversation_id)
);
```

### 2.7 `tb_notification`

> **(NEW — ต้องสร้างใหม่)** ปัจจุบันยังไม่มี table `tb_notification` หรือ `NotificationService` อยู่จริงใน zyra-api/zyra-ws/zyra-notifications. สคีมาด้านล่างเป็น forward-looking design. DB + business logic เป็นของ zyra-api; WS push เป็นของ zyra-ws; email เป็นของ zyra-notifications.

```sql
CREATE TABLE tb_notification (
    id              VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id         VARCHAR NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
    type            VARCHAR NOT NULL CHECK (type IN ('dm', 'mention', 'reply', 'group_add', 'reaction')),
    conversation_id VARCHAR REFERENCES tb_conversation(id) ON DELETE CASCADE,
    message_id      VARCHAR REFERENCES tb_message(id) ON DELETE SET NULL,
    actor_id        VARCHAR REFERENCES tb_user(id) ON DELETE SET NULL,
    is_read         BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notif_user       ON tb_notification(user_id, is_read, created_at DESC);
CREATE INDEX idx_notif_conv       ON tb_notification(conversation_id);
```

### 2.8 Migration Order

> Highest existing migration in `zyra-api/migrations` = `51_workspace_transfer_columns.sql`. Chat migrations เริ่มที่หมายเลข **52** เป็นต้นไป (เรียงตาม FK dependency).

```sql
-- Run in order (FK dependencies) — start at 52
-- 52_create_chat_tables.sql อาจรวมเป็นไฟล์เดียว หรือแยกตามลำดับนี้:
-- 52_tb_conversation.sql
-- 53_tb_conversation_member.sql
-- 54_tb_message.sql
-- 55_tb_message_reaction.sql
-- 56_tb_message_attachment.sql
-- 57_tb_user_last_read.sql
-- 58_tb_notification.sql
```

---

## 3. API Endpoints (New — Chat Module)

All under `UserGuard` → `/api/user/chat/*`

### 3.1 Conversations

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/user/chat/conversations` | List conversations (DM + channels + groups) for current user in workspace |
| `POST` | `/api/user/chat/conversations/dm` | Create or get existing DM with another user |
| `POST` | `/api/user/chat/conversations/group` | Create new group chat |
| `GET` | `/api/user/chat/conversations/:id` | Get conversation detail + members |
| `PATCH` | `/api/user/chat/conversations/:id` | Update group name/icon (admin only) |
| `POST` | `/api/user/chat/conversations/:id/members` | Add members to group/private channel |
| `DELETE` | `/api/user/chat/conversations/:id/members/:userId` | Remove member (admin) |
| `DELETE` | `/api/user/chat/conversations/:id/membership` | Leave group/channel |
| `PATCH` | `/api/user/chat/conversations/:id/mute` | Toggle mute for current user |

### 3.2 Channels (subset of conversations, workspace-scoped)

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/user/chat/channels` | List all channels user is member of in workspace |
| `POST` | `/api/user/chat/channels` | Create new channel (workspace admin only) |
| `DELETE` | `/api/user/chat/channels/:id` | Delete channel (not #general) |

### 3.3 Messages

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/user/chat/conversations/:id/messages` | List messages (pagination: `?before=<msgId>&limit=50`) |
| `POST` | `/api/user/chat/conversations/:id/messages` | Send message (text / thread reply) |
| `PATCH` | `/api/user/chat/messages/:id` | Edit own message |
| `DELETE` | `/api/user/chat/messages/:id` | Soft-delete own message |
| `GET` | `/api/user/chat/messages/:id/thread` | List thread replies under a message |
| `POST` | `/api/user/chat/messages/:id/pin` | Pin message (channel admin only) |
| `DELETE` | `/api/user/chat/messages/:id/pin` | Unpin message |

### 3.4 Reactions

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/user/chat/messages/:id/reactions` | Add reaction `{ emoji: "👍" }` |
| `DELETE` | `/api/user/chat/messages/:id/reactions/:emoji` | Remove reaction |
| `GET` | `/api/user/chat/messages/:id/reactions` | List reactions with user lists per emoji |

### 3.5 Attachments

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/user/chat/attachments` | Upload file → returns `{ url, thumb_url, file_name, file_size, mime_type }` |

### 3.6 Unread / Notifications

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/user/chat/unread` | Unread count per conversation `{ conversation_id, count }[]` |
| `POST` | `/api/user/chat/conversations/:id/read` | Mark conversation as read (updates `tb_user_last_read`) |
| `GET` | `/api/user/notifications` | List notifications (paginated) |
| `POST` | `/api/user/notifications/read-all` | Mark all notifications as read |
| `PATCH` | `/api/user/notifications/:id/read` | Mark single notification as read |

### 3.7 Search

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/user/chat/search` | Search messages `?q=keyword&in=<convId>&from=<userId>&after=<date>&before=<date>&limit=50` |

---

## 4. Request / Response Shapes

### 4.1 `ConversationItem`

```go
type ConversationItem struct {
    ID           string    `json:"id"`
    WorkspaceID  string    `json:"workspace_id"`
    Type         string    `json:"type"`          // "dm" | "channel" | "group"
    Name         *string   `json:"name"`
    IsDefault    bool      `json:"is_default"`
    IsPrivate    bool      `json:"is_private"`
    IsMuted      bool      `json:"is_muted"`
    UnreadCount  int       `json:"unread_count"`
    LastMessage  *MessagePreview `json:"last_message"`
    Members      []MemberPreview `json:"members,omitempty"` // DM: the other user; group: first 3
    UpdatedAt    time.Time `json:"updated_at"`
}

type MessagePreview struct {
    ID        string    `json:"id"`
    Content   *string   `json:"content"`
    SenderID  string    `json:"sender_id"`
    SenderName string   `json:"sender_name"`
    CreatedAt time.Time `json:"created_at"`
}

type MemberPreview struct {
    ID          string  `json:"id"`
    Name        string  `json:"name"`
    ImageUpload *string `json:"image_upload"`
    OnlineStatus string `json:"online_status"`  // "online" | "away" | "offline"
}
```

### 4.2 `Message`

```go
type Message struct {
    ID             string       `json:"id"`
    ConversationID string       `json:"conversation_id"`
    Sender         MemberPreview `json:"sender"`
    ReplyToID      *string      `json:"reply_to_id"`
    ReplyToPreview *MessagePreview `json:"reply_to_preview,omitempty"`
    Content        *string      `json:"content"`
    ContentType    string       `json:"content_type"`
    IsEdited       bool         `json:"is_edited"`
    IsDeleted      bool         `json:"is_deleted"`  // true = show "ข้อความนี้ถูกลบ"
    ThreadCount    int          `json:"thread_count"`
    ThreadPreviews []MemberPreview `json:"thread_previews,omitempty"` // first 3 avatars
    Reactions      []ReactionGroup `json:"reactions"`
    Attachments    []Attachment `json:"attachments"`
    IsPinned       bool         `json:"is_pinned"`
    CreatedAt      time.Time    `json:"created_at"`
}

type ReactionGroup struct {
    Emoji   string   `json:"emoji"`
    Count   int      `json:"count"`
    MyReact bool     `json:"my_react"`  // true = current user reacted
    Users   []string `json:"users"`     // user display names (for tooltip)
}

type Attachment struct {
    ID         string  `json:"id"`
    FileURL    string  `json:"file_url"`
    ThumbURL   *string `json:"thumb_url"`
    FileName   string  `json:"file_name"`
    FileSize   int64   `json:"file_size"`
    MimeType   string  `json:"mime_type"`
    ScanStatus string  `json:"scan_status"`
}
```

### 4.3 `SendMessageRequest`

```go
type SendMessageRequest struct {
    Content       *string  `json:"content"`           // required if no attachments
    ReplyToID     *string  `json:"reply_to_id"`       // thread reply
    AttachmentIDs []string `json:"attachment_ids"`    // pre-uploaded via /attachments
}
```

### 4.4 `SearchResult`

```go
type SearchResult struct {
    MessageID      string    `json:"message_id"`
    ConversationID string    `json:"conversation_id"`
    ConvName       string    `json:"conv_name"`
    ConvType       string    `json:"conv_type"`
    SenderName     string    `json:"sender_name"`
    ContentSnippet string    `json:"content_snippet"` // highlighted snippet
    CreatedAt      time.Time `json:"created_at"`
}
```

---

## 5. Go Service Layer (`internal/service/`)

### 5.1 New Files

```
internal/service/
  chat_service.go          -- conversation + message + reaction CRUD
  chat_search_service.go   -- full-text search via PostgreSQL tsvector
  attachment_service.go    -- S3 upload + thumbnail generation
  notification_service.go  -- create/push/mark-read notifications

internal/handler/
  chat_handler.go
  attachment_handler.go
  notification_handler.go

internal/model/
  chat.go                  -- ConversationItem, Message, Attachment, etc.
```

### 5.2 `ChatService` Sentinel Errors

```go
var (
    ErrConversationNotFound  = errors.New("conversation not found")
    ErrNotConversationMember = errors.New("user is not a member of this conversation")
    ErrCannotDMSelf          = errors.New("cannot send DM to yourself")
    ErrMessageNotFound       = errors.New("message not found")
    ErrNotMessageOwner       = errors.New("only message owner can edit or delete")
    ErrDefaultChannelDelete  = errors.New("cannot delete the default channel")
    ErrGroupMemberLimit      = errors.New("group has reached the maximum of 50 members")
    ErrMessageTooLong        = errors.New("message exceeds 4000 character limit")
    ErrReactionLimit         = errors.New("message has reached the 20 emoji type limit")
    ErrRateLimited           = errors.New("rate limit: max 30 messages per minute")
)
```

### 5.3 Key Service Methods

> **ขอบเขต persistence:** message persistence เป็นหน้าที่ของ **zyra-api** (`ChatService` ถือ dependency ผ่าน constructor injection แบบ pattern จริง: `*pgxpool.Pool`, `*storage.S3Client`, `*notify.Client`). **zyra-ws** ทำ real-time fan-out อย่างเดียว และเรียก zyra-api (REST) เพื่อ persist — **ไม่เขียน `tb_message` โดยตรง** เว้นแต่จะตั้งใจแชร์ DB pool. ปัจจุบัน zyra-ws อ่าน Redis ที่ zyra-api publish เท่านั้น (ไม่มี chat persistence path). `NotificationService` เป็น component ใหม่ใน zyra-api (ยังไม่มี).

```go
type ChatService struct {
    db     *pgxpool.Pool
    s3     *storage.S3Client
    redis  *redis.Client
    notify *NotificationService // NEW component in zyra-api; uses notify.Client for email via zyra-notifications
}

// Conversations
func (s *ChatService) GetOrCreateDM(ctx, workspaceID, userID, targetUserID string) (*ConversationItem, error)
func (s *ChatService) CreateGroup(ctx, workspaceID, creatorID string, req CreateGroupRequest) (*ConversationItem, error)
func (s *ChatService) ListConversations(ctx, workspaceID, userID string) ([]ConversationItem, error)
func (s *ChatService) LeaveConversation(ctx, convID, userID string) error  // promotes next member if admin leaves

// Messages
func (s *ChatService) ListMessages(ctx, convID, viewerID string, before *string, limit int) ([]Message, error)
func (s *ChatService) SendMessage(ctx, convID, senderID string, req SendMessageRequest) (*Message, error)
func (s *ChatService) EditMessage(ctx, msgID, editorID string, content string) (*Message, error)
func (s *ChatService) DeleteMessage(ctx, msgID, deleterID string) error     // soft delete
func (s *ChatService) ListThreadReplies(ctx, parentID, viewerID string) ([]Message, error)

// Reactions
func (s *ChatService) AddReaction(ctx, msgID, userID, emoji string) error
func (s *ChatService) RemoveReaction(ctx, msgID, userID, emoji string) error

// Unread
func (s *ChatService) MarkRead(ctx, convID, userID string) error
func (s *ChatService) GetUnreadCounts(ctx, workspaceID, userID string) ([]UnreadCount, error)

// Rate limit (Redis counter — 30 msg/min/user)
func (s *ChatService) checkRateLimit(ctx, userID string) error
```

### 5.4 Message Pagination Pattern

```go
// Cursor-based pagination — no OFFSET (avoids N+1 on large history)
// Request: GET /conversations/:id/messages?before=<msgId>&limit=50
// SQL:
SELECT m.*, ... FROM tb_message m
WHERE m.conversation_id = $1
  AND ($2::text IS NULL OR m.created_at < (SELECT created_at FROM tb_message WHERE id = $2))
  AND m.deleted_at IS NULL
ORDER BY m.created_at DESC
LIMIT $3
```

### 5.5 Attachment Service (S3 Key Structure)

```
chat/{conversationId}/{uuid}.ext           ← original file
chat/{conversationId}/{uuid}_thumb.jpg     ← 300px thumbnail (images only)
```

```go
type AttachmentService struct {
    db *pgxpool.Pool
    s3 *storage.S3Client
}

// UploadAttachment: validate MIME (magic bytes) → upload to R2 → generate thumb → persist tb_message_attachment
func (s *AttachmentService) UploadAttachment(ctx, convID string, file io.Reader, header *multipart.FileHeader) (*Attachment, error)

// Allowed MIME types (server-side allowlist)
var allowedMIME = map[string]bool{
    "image/jpeg": true, "image/png": true, "image/gif": true, "image/webp": true,
    "application/pdf": true,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": true,  // docx
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": true,        // xlsx
    "application/vnd.openxmlformats-officedocument.presentationml.presentation": true, // pptx
    "application/zip": true,
    "text/plain": true, "text/csv": true,
}
```

---

## 6. WebSocket Protocol Extension (zyra-ws)

zyra-ws already handles Virtual Office messages. Chat events are added to the same connection, scoped to `conversation_id`.

> **Alignment note (v1.1):** zyra-ws ใช้ **native WebSocket** envelope เดียวคือ `Envelope{ Type string, Payload json.RawMessage }` (ไม่ใช่ Socket.IO) + binary frame `moved_bin` สำหรับ position. ชื่อ type จริงเป็น constant แบบ `ClientMsg*`/`Msg*` ใน `internal/hub/message.go`. ปัจจุบันมีเพียง `handleChat()` ที่ broadcast `MsgChat{user_id, display_name, content}` ไปทั้งห้อง workspace — **ไม่มี** conversation routing / typing / reaction / proximity. ชื่อ logical event `chat:*` / `proximity:*` ด้านล่างเป็น naming ระดับ payload ที่ต้อง **map ลงบน `Envelope.type`** และทั้งหมด (ยกเว้น chat = `MsgChat` ที่มีอยู่แล้วแต่ยัง broadcast ทั้งห้อง) เป็น **NEW ที่ต้องเพิ่ม**.

### 6.1 New Inbound Events (client → server)

> **Room model (alignment):** zyra-ws ปัจจุบัน scope ทุก `Room` ที่ระดับ **workspace** (1 Room ต่อ `workspaceID` ผ่าน `Hub.getOrCreateRoom`, destroy เมื่อ client = 0, `runMoveTicker` flush ทุก 20ms) และ `MsgChat` broadcast ทั้งห้อง. มีแนวคิด private `RoomID` (zone) ผ่าน `room_enter`/`room_exit` (`broadcastToRoom`) แต่ **ไม่มี** per-conversation fan-out. ต้องเพิ่ม **`ConversationRoom` registry** (`map[conversationID]` → set ของ client) ภายใน `Room` ที่มีอยู่ เพื่อ fan-out ต่อ conversation — ไม่ใช่สร้าง Room ใหม่ระดับบนสุด. primitive ที่ใช้: `Hub.getOrCreateRoom`, `broadcastToRoom`, `runMoveTicker`.

```go
// Join a conversation room to receive real-time events
type JoinConversationPayload struct {
    ConversationID string `json:"conversation_id"`
}

// Leave a conversation room
type LeaveConversationPayload struct {
    ConversationID string `json:"conversation_id"`
}

// Real-time message (WS fast path — server persists via goroutine)
type ChatMessagePayload struct {
    ConversationID string   `json:"conversation_id"`
    Content        *string  `json:"content"`
    ReplyToID      *string  `json:"reply_to_id"`
    AttachmentIDs  []string `json:"attachment_ids"`
    TempID         string   `json:"temp_id"`   // client-generated UUID for optimistic update
}

// Typing events
type TypingPayload struct {
    ConversationID string `json:"conversation_id"`
}

// Reaction (WS broadcast, REST for persistence)
type ReactionPayload struct {
    ConversationID string `json:"conversation_id"`
    MessageID      string `json:"message_id"`
    Emoji          string `json:"emoji"`
    Action         string `json:"action"`  // "add" | "remove"
}

// Proximity events (existing + extended)
type ProximityPayload struct {
    X    float64 `json:"x"`
    Y    float64 `json:"y"`
    Text *string `json:"text"`  // message content (ephemeral, not stored in DB)
}
```

**Inbound message types:**

| Type | Payload | Notes |
|---|---|---|
| `chat:join` | `JoinConversationPayload` | Subscribe to conversation room |
| `chat:leave` | `LeaveConversationPayload` | Unsubscribe |
| `chat:message` | `ChatMessagePayload` | Send new message |
| `chat:typing:start` | `TypingPayload` | Start typing |
| `chat:typing:stop` | `TypingPayload` | Stop typing |
| `chat:reaction` | `ReactionPayload` | React / unreact |
| `chat:read` | `{ conversation_id }` | Mark read (updates Redis, debounced to REST) |
| `proximity:text` | `ProximityPayload` | Proximity chat (ephemeral) |

### 6.2 New Outbound Events (server → client)

| Type | Payload | Notes |
|---|---|---|
| `chat:message:new` | `Message` | Broadcast to conversation room members |
| `chat:message:new:ack` | `{ temp_id, message_id }` | Confirm to sender only |
| `chat:message:edit` | `{ message_id, content, edited_at }` | Broadcast |
| `chat:message:delete` | `{ message_id }` | Broadcast |
| `chat:typing` | `{ conversation_id, users: [{id, name}] }` | Current typists (server aggregates) |
| `chat:reaction:update` | `{ message_id, reactions: ReactionGroup[] }` | Full reaction state |
| `chat:notification:new` | `Notification` | Push to specific user's connection |
| `chat:unread:update` | `{ conversation_id, count }` | Push to specific user |
| `proximity:message` | `{ sender_id, sender_name, text, session_id }` | Proximity only |
| `proximity:join` | `{ user_id, user_name }` | User entered proximity |
| `proximity:leave` | `{ user_id }` | User left proximity |

### 6.3 Typing Indicator — Redis TTL Pattern

> **(NEW pattern)** zyra-ws ปัจจุบันใช้ Redis แบบ optional (graceful degrade) สำหรับ `vo:*` keys เท่านั้น (เช่น `vo:presence:{ws}:{user}` 35s, `vo:members:{ws}`, `vo:wave_cd:{ws}:{sender}:{target}` 10s, `vo:knock_cd`, `vo:follow:{ws}:{user}`, `vo:last_pos`, `vo:pos_snapshot`). typing สำหรับ chat ยังไม่มี — แนะนำตั้ง namespace ให้สอดคล้องเช่น `vo:typing:{ws}:{conv}:{user}`.

```
Key:   vo:typing:{ws}:{conversation_id}:{user_id}
Value: user_display_name
TTL:   3 seconds (auto-expire)

On chat:typing:start  → SET key value EX 3
On chat:typing:stop   → DEL key
On TTL expire         → Redis keyspace notification → server pushes chat:typing to room
Server aggregates all typing:{conv_id}:* keys and broadcasts to room every 500ms
```

### 6.4 Proximity Chat — Redis Session

> **(NEW subsystem)** proximity chat ยังไม่ implement ใน zyra-ws — ต้องสร้างใหม่. **หมายเหตุสำคัญ:** AOI ที่มีอยู่ (grid cell ขนาด 16-tile, neighbourhood 3×3) ใช้ **กรอง broadcast การเคลื่อนที่เท่านั้น** ไม่ใช่ proximity chat — proximity chat ต้องเป็น subsystem ใหม่แยกต่างหาก. ตั้ง namespace ให้สอดคล้องกับ `vo:*` keys ที่มีอยู่.

```
Key:   vo:proximity:{workspace_id}:{session_id}
Type:  Redis Set
Value: {user_id}
TTL:   30 seconds (heartbeat must renew)

session_id = computed from anchor tile position (tile-based, สอดคล้องกับ AOI grid)
             e.g., floor(x/tile) + ":" + floor(y/tile)

On avatar:move  → recalculate session_id; if changed, SREM old, SADD new
                  if SCARD > 0: broadcast proximity:join to room
                  if old SCARD == 0: session destroyed
Grace period:   EXPIRE key 1s before actually removing user (handles brief moves)
Rejoin window:  5s — if user rejoins same session_id within 5s, skip proximity:join noise
```

### 6.5 Rate Limiting (WS layer)

> **(NEW pattern)** chat rate-limit ยังไม่มีใน zyra-ws — แต่สามารถ mirror cooldown pattern ของ wave/knock ที่มีอยู่ (`vo:wave_cd`, `vo:knock_cd`). ตั้ง namespace ให้สอดคล้องเช่น `vo:chat_rl:{user_id}`.

```
Key:   vo:chat_rl:{user_id}
Type:  Redis counter (INCR + EXPIRE)
Limit: 30 increments per 60 seconds
On exceed: server sends { type: "error", code: "RATE_LIMITED", retry_after: N }
           drops the message silently (not persisted)
```

---

## 7. Frontend Architecture (zyra-app)

### 7.1 File Structure

> **Alignment note (v1.1):** ไฟล์ทั้งหมดด้านล่างเป็น **NEW (ต้องสร้างใหม่)**. ของจริงปัจจุบัน: REST client = `authFetch`/`authFetchForm` ใน `lib/api/client.ts` (มี 401 refresh+retry); WS client = class `WorkspaceWSClient` ใน `lib/api/workspace-ws.ts` (single connection ต่อ workspace, มี method `chat(content)` อยู่แล้ว, types ใน `lib/api/workspace-ws-types.ts`); renderer = `PixiGameScene` (`zyra-engine/pixi-game/scene.ts`, PixiJS v8 — ไม่ใช่ Phaser). **ไม่มีโฟลเดอร์ `lib/ws/`** — chat WS ให้ **extend `WorkspaceWSClient`** (เพิ่ม method/handler `chat:*` ในนั้น หรือ helper module ใน `lib/api/`) แทนการสร้าง `lib/ws/chat-ws.ts`. stores ที่มีจริง: `user-store.ts`, `space-builder-store.ts`, `object-draft-store.ts`, `vo-session-store.ts`, `vo-prefetch-store.ts` (Zustand 5). route VO จริงคือ `app/workspace/[id]/play/page.tsx` → `HeroVirtualOffice`; route chat ต้องเพิ่มใหม่และพิจารณา `PUBLIC_PATHS` ใน `components/auth-guard.tsx`.

```
views/chat/  (NEW)
  hero-chat.tsx                    ← top-level layout: sidebar + active panel
  components/
    chat-sidebar.tsx               ← DM list, channel list, group list + unread badges
    dm-panel.tsx                   ← DM thread view
    channel-panel.tsx              ← channel thread view
    group-panel.tsx                ← group thread view
    thread-panel.tsx               ← thread reply overlay (right side)
    message-item.tsx               ← renders a single message
    message-input.tsx              ← input bar (text, emoji, attach, send)
    emoji-picker.tsx               ← emoji picker modal
    file-preview.tsx               ← image lightbox / file card
    search-panel.tsx               ← search overlay
    notification-bell.tsx          ← notification icon + panel
    typing-indicator.tsx           ← animated dots + names
    proximity-panel.tsx            ← ephemeral proximity chat overlay (on VO map)
    create-group-modal.tsx         ← step: pick members → set name
    conversation-info-panel.tsx    ← members, settings, mute toggle

lib/api/chat.ts (NEW)              ← REST calls (ใช้ authFetch จาก lib/api/client.ts): listConversations, sendMessage, searchMessages, etc.
lib/api/workspace-ws.ts (EXTEND)   ← เพิ่ม chat:* methods/handlers ใน WorkspaceWSClient ที่มีอยู่ (มี chat(content) เป็นจุดเริ่ม); ไม่สร้าง lib/ws/chat-ws.ts
stores/chat-store.ts (NEW)         ← Zustand 5 (pattern create<State>((set,get)=>...) ตาม stores เดิม): conversations, messages (by convId), typing, unread counts
```

### 7.2 Zustand Store Shape

```ts
interface ChatStore {
  // Conversations
  conversations: ConversationItem[]
  activeConversationId: string | null
  setActiveConversation: (id: string) => void

  // Messages — keyed by conversation ID
  messages: Record<string, Message[]>
  hasMoreMessages: Record<string, boolean>
  appendMessages: (convId: string, msgs: Message[]) => void
  prependOlderMessages: (convId: string, msgs: Message[]) => void
  upsertMessage: (msg: Message) => void          // optimistic + confirmed
  replaceOptimistic: (tempId: string, msg: Message) => void
  removeMessage: (msgId: string) => void

  // Typing
  typingUsers: Record<string, { id: string; name: string }[]>

  // Unread
  unreadCounts: Record<string, number>
  setUnread: (convId: string, count: number) => void
  clearUnread: (convId: string) => void
  totalUnread: () => number

  // Thread
  activeThreadMessageId: string | null
  setActiveThread: (msgId: string | null) => void

  // Notifications
  notifications: Notification[]
  notificationUnread: number
}
```

### 7.3 Optimistic Message Flow

```
User types → clicks Send
│
├─ 1. Generate temp_id (UUID on client)
├─ 2. Append optimistic message to store (status: "sending")
├─ 3. Send via WS: chat:message { temp_id, content, ... }
│
Server receives
├─ 4. Validates rate limit → rejects or persists to DB
├─ 5. Sends chat:message:new:ack { temp_id, message_id } back to sender
└─ 6. Broadcasts chat:message:new to all members in conversation room
│
Client receives ack
├─ 7. store.replaceOptimistic(temp_id, confirmedMessage) → status: "sent"
│
Client receives broadcast (including sender, deduped by message_id)
└─ 8. store.upsertMessage(msg) — no-op if already inserted via ack

On WS error / timeout (5s no ack)
└─ 9. Update optimistic message → status: "failed", show retry button
       retry: re-send same payload with same temp_id
```

### 7.4 Chat WS surface (extend `WorkspaceWSClient` in `lib/api/workspace-ws.ts`)

> **Alignment:** ไม่มี `lib/ws/chat-ws.ts`. ให้เพิ่ม method/handler chat ลงใน class `WorkspaceWSClient` ที่มีอยู่ (single connection ต่อ workspace, มี `chat(content)` เป็นจุดเริ่ม) หรือทำ helper module ใน `lib/api/`. ด้านล่างคือ surface ที่ต้องเพิ่ม (เขียนเป็น `ChatWSClient` เพื่อสื่อ shape เท่านั้น):

```ts
// surface ที่เพิ่มเข้า WorkspaceWSClient (ไม่ใช่ class แยกใน lib/ws/)
class ChatWSClient {
  private ws: WorkspaceWSClient  // reuse existing zyra-ws connection
  private store: ChatStore

  joinConversation(convId: string): void
  leaveConversation(convId: string): void
  sendMessage(payload: ChatMessagePayload): void
  sendTypingStart(convId: string): void
  sendTypingStop(convId: string): void
  sendReaction(payload: ReactionPayload): void
  markRead(convId: string): void

  // Event handlers (registered on existing WS connection)
  private onChatMessageNew(msg: Message): void
  private onChatMessageAck(ack: { temp_id: string; message_id: string }): void
  private onTypingUpdate(payload: { conversation_id: string; users: ... }): void
  private onReactionUpdate(payload: ...): void
  private onNotificationNew(notif: Notification): void
  private onUnreadUpdate(payload: { conversation_id: string; count: number }): void
}
```

### 7.5 Message Rendering Rules

| Condition | Render |
|---|---|
| `is_deleted = true` | "ข้อความนี้ถูกลบ" (italic, gray) — no content |
| `content_type = "attachment"` and image MIME | Inline thumbnail + lightbox on click |
| `content_type = "attachment"` and non-image | File card: icon + name + size + download |
| `reply_to_id` is set | Quoted preview above message body |
| `thread_count > 0` | "X replies" link + avatar row below message |
| `is_edited = true` | "(แก้ไขแล้ว)" label after content |
| `scan_status = "infected"` | File card red: "ไฟล์นี้ไม่ปลอดภัย" — no download link |
| `is_pinned = true` | Pin icon on message + shows in pinned panel |

### 7.6 Infinite Scroll Pattern

```ts
// On channel/DM panel mount
useEffect(() => {
  dispatch({ type: "LOAD_INITIAL", convId })
  // GET /conversations/:id/messages?limit=50 → newest 50
  // Set hasMore[convId] = total > 50
}, [convId])

// On scroll to top
const handleScrollTop = useCallback(() => {
  if (!hasMore[convId] || isLoading) return
  const oldest = messages[convId][0]
  // GET /conversations/:id/messages?before=<oldest.id>&limit=50
  // prependOlderMessages(convId, result)
}, [messages, hasMore, convId])
```

### 7.7 Typing Indicator Component

```tsx
// Input uses debounce: send typing:start on first keystroke, reset 3s timer
// Stop is sent when: (a) message sent, (b) input cleared, (c) 3s timer fires

function useTypingEmitter(convId: string) {
  const timerRef = useRef<ReturnType<typeof setTimeout>>()
  const isSending = useRef(false)

  const onKeyDown = useCallback(() => {
    if (!isSending.current) {
      chatWS.sendTypingStart(convId)
      isSending.current = true
    }
    clearTimeout(timerRef.current)
    timerRef.current = setTimeout(() => {
      chatWS.sendTypingStop(convId)
      isSending.current = false
    }, 3000)
  }, [convId])

  const onSend = useCallback(() => {
    clearTimeout(timerRef.current)
    chatWS.sendTypingStop(convId)
    isSending.current = false
  }, [convId])

  return { onKeyDown, onSend }
}
```

---

## 8. Notification System

> **Alignment note (v1.1):** `NotificationService` + `tb_notification` เป็น **NEW (ยังไม่มีในโค้ด)**. ความเป็นเจ้าของ: **DB + business logic = zyra-api**, **WS push = zyra-ws**, **email = zyra-notifications**. zyra-api ส่งอีเมลผ่าน `notify.Client` → POST `{NOTIFICATION_SERVICE_URL}/v1/email` (header `X-Notification-Key`, body `{template, to, params}`). ถ้า `NOTIFICATION_SERVICE_URL` ว่าง → client เป็น `nil` และ `Send()` เป็น **no-op (ไม่มี SMTP fallback ใน zyra-api)**. zyra-notifications รองรับ template: `otp`, `welcome`, `reset_password`, `locked_account`, `workspace_invite` — **ยังไม่มี digest/batch/cron** ดังนั้น chat digest template + scheduler เป็นงานใหม่.

### 8.1 Trigger Points

| Event | Notification Type | Recipients |
|---|---|---|
| New DM received | `dm` | recipient (if not in DM view) |
| @mention in channel/group | `mention` | mentioned user |
| @Everyone in channel | `mention` | all channel members (online only) |
| New thread reply | `reply` | thread participants + parent message author |
| Added to group | `group_add` | added user |
| New reaction on own message | `reaction` | message owner |

### 8.2 Delivery Flow

```
Message saved to DB
│
├─ NotificationService.CreateForMessage(ctx, msg)
│   ├─ Determine recipients (exclude sender, check mute settings)
│   ├─ Batch INSERT into tb_notification
│   └─ For each online recipient:
│       └─ Push via WS (zyra-ws): chat:notification:new + chat:unread:update
│
├─ Unread count: UPDATE/INSERT tb_user_last_read kept current for active views
│   If user is in conversation view → skip notification (already reading)
│
└─ Email dispatch (async, 5-min inactivity gate) — via zyra-notifications, NOT in-process SMTP:
    ├─ Check: user last WS heartbeat > 5 min ago?
    ├─ Batch collect all unread notifications for that user
    └─ Send single digest via notify.Client → POST /v1/email (zyra-notifications)
       ต้องเพิ่ม chat digest template ใน zyra-notifications (NEW — ยังไม่มี)
       + digest scheduler ใน zyra-api. ถ้า NOTIFICATION_SERVICE_URL ว่าง → skip (no-op)
```

### 8.3 Mute Logic

```
tb_conversation_member.muted = true
→ no notifications pushed for that conversation
→ unread count still increments (badge stays visible, just no popup)
→ email digest skipped for that conversation
```

---

## 9. Message Search

### 9.1 PostgreSQL Full-Text Search

```sql
-- Query: user searches "hello world" in workspace W
SELECT
    m.id           AS message_id,
    m.conversation_id,
    c.name         AS conv_name,
    c.type         AS conv_type,
    u.name         AS sender_name,
    ts_headline('simple', m.content, plainto_tsquery('simple', $3),
        'StartSel=<mark>, StopSel=</mark>, MaxWords=20, MinWords=10'
    )              AS content_snippet,
    m.created_at
FROM tb_message m
JOIN tb_conversation c        ON c.id = m.conversation_id
JOIN tb_conversation_member cm ON cm.conversation_id = c.id AND cm.user_id = $2 AND cm.left_at IS NULL
JOIN tb_user u                ON u.id = m.sender_id
WHERE c.workspace_id = $1
  AND m.deleted_at IS NULL
  AND c.type != 'proximity'           -- exclude ephemeral
  AND to_tsvector('simple', coalesce(m.content, '')) @@ plainto_tsquery('simple', $3)
  AND ($4::timestamptz IS NULL OR m.created_at >= $4)   -- after filter
  AND ($5::timestamptz IS NULL OR m.created_at <= $5)   -- before filter
  AND ($6::text IS NULL OR m.sender_id = $6)             -- from filter
  AND ($7::text IS NULL OR m.conversation_id = $7)       -- in filter
ORDER BY m.created_at DESC
LIMIT 50;
```

### 9.2 Debounce (Frontend)

```ts
// lib/api/chat.ts
export const searchMessages = debounce(async (params: SearchParams) => {
  const res = await authFetch(`/api/user/chat/search?${toQS(params)}`)
  return (await res.json()) as SearchResult[]
}, 300)
```

---

## 10. File Upload Flow

```
Client picks file(s)
│
├─ Client-side validation:
│   ├─ file.size > FILE_SIZE_LIMIT → show inline error, skip
│   ├─ file.type not in allowedMIME → show inline error, skip
│   └─ count > 5 → trim excess, show warning
│
├─ For each valid file:
│   ├─ POST /api/user/chat/attachments
│   │   Body: multipart/form-data { file, conversation_id }
│   │
│   └─ Server:
│       ├─ Read magic bytes (first 512 bytes) → verify real MIME
│       ├─ Upload to R2: chat/{convId}/{uuid}.ext
│       ├─ If image: generate 300px thumb → upload to R2: chat/{convId}/{uuid}_thumb.jpg
│       ├─ INSERT tb_message_attachment (scan_status = 'pending')
│       ├─ Enqueue async virus scan job
│       └─ Return Attachment { id, file_url, thumb_url, file_name, file_size, mime_type }
│
├─ Client receives attachment IDs → appends to SendMessageRequest.attachment_ids
│
└─ POST /conversations/:id/messages { content, attachment_ids }
    Server links attachments to message record
```

### File Size Limit

```go
const (
    MaxFileSizeBytes  = 25 * 1024 * 1024  // 25 MB (TBD — align with spec)
    MaxFilesPerMessage = 5
    ThumbSize         = 300               // px
)
```

---

## 11. Rate Limiting

| Scope | Limit | Backend |
|---|---|---|
| Send message (WS) | 30 msg/min per user per workspace | Redis INCR + EXPIRE 60s |
| Send message (REST fallback) | 30 msg/min per user | Redis same key |
| File upload | 20 files/min per user | Redis INCR + EXPIRE 60s |
| Message search | 30 req/min per user | Redis INCR + EXPIRE 60s |
| Typing events | throttled client-side (1 event / 3s) | Client-side only |

---

## 12. Security

### 12.1 Authorisation Checks (every endpoint)

```
GET /conversations/:id/messages
  → assert user is active member of conversation (left_at IS NULL)

POST /conversations/:id/messages
  → assert member + not muted (mute doesn't block sending, only notifications)

PATCH /messages/:id
  → assert sender_id = current user

DELETE /messages/:id (soft)
  → assert sender_id = current user OR user is conversation admin

POST /messages/:id/pin
  → assert user is workspace admin OR channel admin

POST /channels (create)
  → assert user is workspace admin
```

### 12.2 File Security

- Server validates MIME via magic bytes — never trust `Content-Type` from client
- All R2 URLs are public CDN; no signed URL required (files are non-sensitive attachments)
- `scan_status = 'infected'` → file card shows warning, download link removed from response
- Filename stored as-is for display; S3 key uses UUID (no path traversal possible)

### 12.3 Proximity Chat (No Persistence)

- Proximity messages are never written to DB
- Payload passes through Redis pub/sub only
- No search, no history, no attachment allowed in proximity chat

### 12.4 Input Validation

```go
// On SendMessage
if len(req.Content) > 4000 {
    return nil, ErrMessageTooLong
}
if len(req.AttachmentIDs) > 5 {
    return nil, fmt.Errorf("max 5 attachments per message")
}
if req.Content == nil && len(req.AttachmentIDs) == 0 {
    return nil, fmt.Errorf("message must have content or attachments")
}
// ReplyToID depth check: reply_to must not itself have a reply_to (1-level threads only)
```

---

## 13. Performance Notes

| Concern | Solution |
|---|---|
| Message load latency | Cursor-based pagination (no OFFSET); index on `(conversation_id, created_at DESC)` |
| Fan-out to large channels | WS hub broadcasts to in-memory room set — O(n) with Redis pub/sub for multi-node |
| Unread count accuracy | `tb_user_last_read` upserted per user on `chat:read` WS event, debounced 2s before REST persist |
| Search latency | GIN index on `tsvector`; limit 50 results; debounce 300ms on client |
| Reaction aggregate | Computed on read from `tb_message_reaction GROUP BY emoji`; cached 5s in Redis for hot messages |
| Attachment thumbnail | Generated server-side at upload time (not on-the-fly); stored in R2 |
| Proximity calculation | Server checks position delta on every `avatar:move` WS event; O(1) Redis set ops |

---

## 14. Environment Variables

### 14.1 Existing envs (relevant to Chat)

```env
# Ports
# zyra-api           :3001
# zyra-notifications :3003
# zyra-ws            :3004

# zyra-api → zyra-notifications (email)
NOTIFICATION_SERVICE_URL=http://zyra-notifications:3003   # ถ้าว่าง → email no-op (no SMTP fallback)
NOTIFICATION_API_KEY=<X-Notification-Key>

# zyra-api & zyra-ws (Redis optional, graceful degrade)
REDIS_URL=redis://...

# zyra-notifications (owns SMTP — Gmail only)
EMAIL_SERVICE=gmail
EMAIL_AUTHEN_USER=<smtp-user>
EMAIL_AUTHEN_PASS=<smtp-app-password>
EMAIL_SEND_FROM=<from-address>
```

### 14.2 New envs (Chat)

```env
# zyra-api additions (NEW)
CHAT_FILE_MAX_MB=25                    # attachment size limit (TBD — see open question #1)
CHAT_RATE_LIMIT_MSG_PER_MIN=30
CHAT_RATE_LIMIT_UPLOAD_PER_MIN=20

# zyra-ws additions (NEW; Redis optional)
CHAT_TYPING_TTL_SEC=3
CHAT_PROXIMITY_RADIUS=200
CHAT_PROXIMITY_GRACE_MS=1000
CHAT_PROXIMITY_REJOIN_WINDOW_SEC=5
CHAT_PROXIMITY_MAX_MEMBERS=10
```

---

## 15. Implementation Phases

### Phase 1 — Core DM + Channel (SC-CHAT-01, SC-CHAT-04)
1. DB migrations (all 7 tables)
2. zyra-api: `ChatService`, REST endpoints (conversations + messages + channels)
3. zyra-ws: `chat:join/leave`, `chat:message`, optimistic ack, fan-out
4. zyra-app: `chat-store`, `ChatWSClient`, `hero-chat`, `dm-panel`, `channel-panel`, `message-input`
5. Unread badge + `tb_user_last_read` (SC-CHAT-10 basic)

### Phase 2 — Group + Thread + Reactions (SC-CHAT-05, SC-CHAT-06, SC-CHAT-07)
1. `CreateGroup` endpoint + `create-group-modal`
2. Thread endpoint + `thread-panel`
3. Reaction endpoints + WS broadcast + `emoji-picker`

### Phase 3 — Attachments (SC-CHAT-08, SC-CHAT-09)
1. `AttachmentService` + R2 upload + thumbnail
2. MIME validation (magic bytes) + file card UI
3. Drag-and-drop + progress bar + cancel
4. Async virus scan stub (mark pending → clean)

### Phase 4 — Notifications + Search (SC-CHAT-10 full, SC-CHAT-11)
1. `NotificationService` (NEW) + `tb_notification` (NEW) + WS push (zyra-ws)
2. Email digest (5-min inactivity gate) — via zyra-notifications (`notify.Client` → POST `/v1/email`); ต้องเพิ่ม chat digest template + scheduler (NEW); no SMTP in zyra-api
3. `ChatSearchService` + PostgreSQL FTS + `search-panel`

### Phase 5 — Proximity + Typing + Polish (SC-CHAT-02, SC-CHAT-03, SC-CHAT-12)
1. zyra-ws proximity session (Redis set + grace period)
2. `proximity-panel` overlay on Virtual Office map
3. Typing indicator: Redis TTL + WS aggregate + animated dots

---

## 16. Open Questions

| # | Question | Impact |
|---|---|---|
| 1 | File size limit — spec says "TBD". Recommend 25 MB. | Attachment service config |
| 2 | Virus scanning provider — use ClamAV on-prem or SaaS (e.g. VirusTotal API)? | `attachment_service.go` async job |
| 3 | Email digest format for unread notifications — HTML template needed (เพิ่มเป็น template ใหม่ใน **zyra-notifications**, trigger จาก `notification_service.go` ผ่าน `notify.Client`) | zyra-notifications template + zyra-api scheduler |
| 4 | Multi-node zyra-ws (for scale) — Redis pub/sub fan-out already planned? | WS hub architecture |
| 5 | @Everyone rate limit — should there be a cooldown per channel? | `chat_service.go` |
| 6 | Message edit history — store previous versions or just flag `is_edited`? | DB schema (optional `tb_message_edit_history`) |
