# Task Breakdown — Chat Module

**Version:** 1.1  
**Date:** 2026-06-29  
**Scope:** SC-CHAT-01 ~ SC-CHAT-12  
**Refs:** `spec.md` · `technical-design.md` · `ux-ui-plan.md` · `test-plan.md`  
**Changelog:** v1.1 (2026-06-29) — Codebase Alignment

---

## Codebase Alignment (v1.1)

> ปรับ task ให้ตรงกับโค้ดจริง (ดู `technical-design.md` §16/changelog ประกอบ) — task ทั้งหมดด้านล่างยังเป็นงานที่ต้องสร้างใหม่ ("to be built") เว้นแต่ระบุไว้เป็นอย่างอื่น:

- **Email** ทั้งหมดไม่ได้อยู่ใน zyra-api แต่ส่งผ่าน **zyra-notifications microservice** (POST `/v1/email` ด้วย `notify.Client`, header `X-Notification-Key`). zyra-api ไม่มี SMTP ในตัว — ถ้า `NOTIFICATION_SERVICE_URL` ว่าง การส่งจะเป็น no-op (ไม่มี SMTP fallback). chat digest ต้องเพิ่ม template ใหม่ใน zyra-notifications + scheduler ใน zyra-api.
- **Notification (in-app)**: ยังไม่มี `tb_notification` หรือ `NotificationService` อยู่จริง — DB + business logic เป็นของ zyra-api (NEW), real-time push เป็นของ zyra-ws, email เป็นของ zyra-notifications.
- **Migration** เริ่มที่หมายเลข **52** เป็นต้นไป (highest existing migration = `51_workspace_transfer_columns.sql`).
- **Frontend paths**: ไม่มี `lib/api/chat.ts`, `lib/ws/chat-ws.ts`, `stores/chat-store.ts`, route `chat/page.tsx` อยู่จริง — ทุกไฟล์เป็น NEW. REST ใช้ `authFetch` จาก `lib/api/client.ts`; chat WS ต้อง extend `WorkspaceWSClient` ใน `lib/api/workspace-ws.ts` (มี `chat(content)` อยู่แล้ว); renderer คือ `PixiGameScene` (PixiJS v8) ไม่ใช่ Phaser.
- **zyra-ws** มี Room เดียวต่อ workspace และ `MsgChat` broadcast ทั้งห้องอยู่แล้ว — per-conversation fan-out / typing / proximity ต้องสร้างเพิ่มบน primitive ที่มี (`Hub.getOrCreateRoom`, `broadcastToRoom`).

---

## Summary

| Phase | Tasks | Layer | Scenarios |
|---|---|---|---|
| Phase 1 — Core DM + Channel | CHAT-001 ~ CHAT-016 | API + WS + FE | SC-CHAT-01, SC-CHAT-04 |
| Phase 2 — Group + Thread + Reactions | CHAT-017 ~ CHAT-028 | API + WS + FE | SC-CHAT-05, SC-CHAT-06, SC-CHAT-07 |
| Phase 3 — Attachments | CHAT-029 ~ CHAT-037 | API + FE | SC-CHAT-08, SC-CHAT-09 |
| Phase 4 — Notifications + Search | CHAT-038 ~ CHAT-048 | API + WS + FE | SC-CHAT-10, SC-CHAT-11 |
| Phase 5 — Proximity + Typing | CHAT-049 ~ CHAT-058 | WS + FE | SC-CHAT-02, SC-CHAT-03, SC-CHAT-12 |
| Phase 6 — Test Reporting & Visual Regression | CHAT-059 ~ CHAT-062 | CI + FE | all |

**Total: 62 tasks**

---

## Estimation Key

| Label | Effort |
|---|---|
| XS | < 2 h |
| S | 2–4 h |
| M | 4–8 h (1 day) |
| L | 8–16 h (2 days) |
| XL | 16–24 h (3 days) |

---

## Phase 1 — Core DM + Channel

> Delivers: SC-CHAT-01 (Direct Message), SC-CHAT-04 (Channel Chat), SC-CHAT-10 (Unread basic)

---

### CHAT-001 · DB Migration — All Chat Tables

**Layer:** zyra-api (PostgreSQL)  
**Effort:** M  
**Depends on:** —  
**Scenarios:** all

> **หมายเหตุ:** highest existing migration = `51_workspace_transfer_columns.sql` — chat migrations ต้องเริ่มที่หมายเลข **52** เป็นต้นไป ตามลำดับ FK ด้านล่าง

**Tasks:**
- [ ] `52_create_chat_tables.sql` (หรือแยกไฟล์ 52..58 ตามลำดับ FK) — write migration SQL for `tb_conversation` (52)
- [ ] Write migration SQL for `tb_conversation_member` (53)
- [ ] Write migration SQL for `tb_message` (54)
- [ ] Write migration SQL for `tb_message_reaction` (55)
- [ ] Write migration SQL for `tb_message_attachment` (56)
- [ ] Write migration SQL for `tb_user_last_read` (57)
- [ ] Write migration SQL for `tb_notification` (58) — NEW table; ยังไม่มีอยู่จริงใน zyra-api
- [ ] Create all indexes (see `technical-design.md §2`)
- [ ] Write rollback SQL for each table

**Definition of Done:**
- All 7 tables exist in test DB
- Indexes verified with `\d tablename`
- Rollback script tested (drop and re-run migrates cleanly)

---

### CHAT-002 · Go Model — `internal/model/chat.go`

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-001  
**Scenarios:** all

**Tasks:**
- [ ] Define `ConversationItem`, `MessagePreview`, `MemberPreview` structs
- [ ] Define `Message`, `ReactionGroup`, `Attachment` structs
- [ ] Define `SendMessageRequest`, `CreateGroupRequest` request structs
- [ ] Define `SearchResult`, `UnreadCount`, `Notification` structs
- [ ] Define all sentinel errors (`ErrConversationNotFound`, `ErrNotConversationMember`, `ErrCannotDMSelf`, `ErrMessageTooLong`, `ErrRateLimited`, etc.)
- [ ] Ensure all JSON tags follow `omitempty` convention consistent with existing models

**Definition of Done:**
- `go build ./internal/model/...` passes with zero errors

---

### CHAT-003 · Go Service — `chat_service.go` Conversation CRUD

**Layer:** zyra-api  
**Effort:** L  
**Depends on:** CHAT-001, CHAT-002  
**Scenarios:** SC-CHAT-01, SC-CHAT-04, SC-CHAT-05

**Tasks:**
- [ ] `GetOrCreateDM(ctx, workspaceID, userID, targetUserID)` — upsert DM pair, assert `userID != targetUserID`
- [ ] `CreateChannel(ctx, workspaceID, creatorID, name, isPrivate)` — workspace admin only; auto-add creator as admin member
- [ ] `CreateGroup(ctx, workspaceID, creatorID, req)` — validate member count ≤ 50; creator = group admin; notify added members
- [ ] `ListConversations(ctx, workspaceID, userID)` — joins unread count per conversation from `tb_user_last_read`
- [ ] `GetConversation(ctx, convID, userID)` — assert membership
- [ ] `UpdateConversation(ctx, convID, userID, req)` — name/icon; assert group admin role
- [ ] `AddConversationMembers(ctx, convID, adminID, userIDs)` — check limit; assert admin role
- [ ] `RemoveMember(ctx, convID, adminID, targetUserID)` — assert admin; promote next member if removing admin
- [ ] `LeaveConversation(ctx, convID, userID)` — set `left_at`; if last member in group → set `archived_at`; if owner leaves group → promote next longest-joined member
- [ ] `ToggleMute(ctx, convID, userID)` — flip `tb_conversation_member.muted`

**Definition of Done:**
- All methods unit-tested with mock DB (table-driven, see `test-plan.md §1.1`)
- `go test ./internal/service/... -run TestChat` passes

---

### CHAT-004 · Go Service — `chat_service.go` Messages

**Layer:** zyra-api  
**Effort:** L  
**Depends on:** CHAT-003  
**Scenarios:** SC-CHAT-01, SC-CHAT-04, SC-CHAT-06

**Tasks:**
- [ ] `ListMessages(ctx, convID, viewerID, before *string, limit int)` — cursor-based pagination; soft-deleted messages return placeholder; populate `thread_count` and `thread_previews`
- [ ] `SendMessage(ctx, convID, senderID, req)` — validate length ≤ 4000; check rate limit; link attachment IDs; trigger notification goroutine
- [ ] `EditMessage(ctx, msgID, editorID, content)` — assert ownership; set `is_edited = true`, `edited_at`
- [ ] `DeleteMessage(ctx, msgID, deleterID)` — soft delete (`deleted_at`); assert ownership or conversation admin
- [ ] `ListThreadReplies(ctx, parentID, viewerID)` — assert `reply_to_id IS NULL` on parent (1-level only); assert viewer is conversation member
- [ ] `GetMessage(ctx, msgID, viewerID)` — used after send for confirmed payload
- [ ] Redis rate-limit helper: `checkRateLimit(ctx, userID)` — INCR/EXPIRE 60s key, return `ErrRateLimited` at 31+

**Definition of Done:**
- Unit tests cover all sentinel errors
- Cursor pagination returns correct order on large fixture dataset (100+ messages)
- Rate limit test: 30 calls pass, 31st returns `ErrRateLimited`

---

### CHAT-005 · Go Handler — `chat_handler.go`

**Layer:** zyra-api  
**Effort:** M  
**Depends on:** CHAT-003, CHAT-004  
**Scenarios:** SC-CHAT-01, SC-CHAT-04

**Tasks:**
- [ ] `GET /api/user/chat/conversations` → `ListConversations`
- [ ] `POST /api/user/chat/conversations/dm` → `GetOrCreateDM`
- [ ] `GET /api/user/chat/channels` → filter conversations by type=channel
- [ ] `POST /api/user/chat/channels` → `CreateChannel` (workspace admin guard)
- [ ] `GET /api/user/chat/conversations/:id` → `GetConversation`
- [ ] `PATCH /api/user/chat/conversations/:id` → `UpdateConversation`
- [ ] `POST /api/user/chat/conversations/:id/members` → `AddConversationMembers`
- [ ] `DELETE /api/user/chat/conversations/:id/members/:userId` → `RemoveMember`
- [ ] `DELETE /api/user/chat/conversations/:id/membership` → `LeaveConversation`
- [ ] `PATCH /api/user/chat/conversations/:id/mute` → `ToggleMute`
- [ ] `GET /api/user/chat/conversations/:id/messages` → `ListMessages`
- [ ] `POST /api/user/chat/conversations/:id/messages` → `SendMessage`
- [ ] `PATCH /api/user/chat/messages/:id` → `EditMessage`
- [ ] `DELETE /api/user/chat/messages/:id` → `DeleteMessage`
- [ ] `GET /api/user/chat/messages/:id/thread` → `ListThreadReplies`
- [ ] Register all routes in `router.go` under `UserGuard`
- [ ] All handlers return `model.APIResponse` envelope

**Definition of Done:**
- `go vet ./...` clean
- All routes listed in router, verified with `curl` smoke test
- 401 returned when no token; 403 when not conversation member

---

### CHAT-006 · zyra-ws — Chat Room: join/leave/fan-out

**Layer:** zyra-ws  
**Effort:** L  
**Depends on:** CHAT-001  
**Scenarios:** SC-CHAT-01, SC-CHAT-04

> **หมายเหตุ (codebase):** zyra-ws ปัจจุบัน scope ทุก Room ที่ระดับ workspace (1 Room/workspaceID ผ่าน `Hub.getOrCreateRoom`) และ `handleChat()` broadcast `MsgChat` ทั้งห้องอยู่แล้ว — ยังไม่มี per-conversation fan-out. งานนี้คือเพิ่ม `ConversationRoom` registry (`map[conversationID]set ของ client`) ภายใน Room ที่มีอยู่ เพื่อ fan-out ต่อ conversation (ไม่ใช่สร้าง Room ใหม่ระดับบนสุด). ทุก inbound/outbound map ลงบน `Envelope{type,payload}` + binary `moved_bin` ตาม constant `ClientMsg*/Msg*` ใน `internal/hub/message.go`.

**Tasks:**
- [ ] Add `chat:join` / `chat:leave` inbound payload types (map ลงบน `Envelope.type`) handled ใน `hub/room.go`
- [ ] เพิ่ม `ConversationRoom` registry ภายใน Room ที่มีอยู่: `map[conversationID]set ของ client` (ไม่สร้าง Room ระดับบนสุดใหม่)
- [ ] Conversation fan-out helper — fan-out ไปยัง client ที่ join conversation นั้น (mirror `broadcastToRoom`), รับ `exclude *Client`
- [ ] Handle `chat:message` inbound: validate payload → persist ผ่าน zyra-api (REST) — zyra-ws ไม่เขียน `tb_message` โดยตรง เว้นแต่ตั้งใจแชร์ DB pool → broadcast `chat:message:new` to conversation → send `chat:message:new:ack` to sender
- [ ] Handle `chat:read` inbound: debounce → upsert `tb_user_last_read` → broadcast `chat:unread:update` to sender only
- [ ] Handle `chat:message:edit` broadcast: fan-out `{ message_id, content, edited_at }`
- [ ] Handle `chat:message:delete` broadcast: fan-out `{ message_id }`
- [ ] Client cleanup on disconnect: remove from all `ChatRoom` sets

**Definition of Done:**
- Two test clients join same conversation, message sent by A appears at B within 200ms
- Disconnect removes client from room (no phantom broadcasts)
- `go test ./internal/hub/...` passes

---

### CHAT-007 · Zustand Store — `stores/chat-store.ts` (NEW)

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** —  
**Scenarios:** SC-CHAT-01, SC-CHAT-04

> **หมายเหตุ:** ยังไม่มี `stores/chat-store.ts` — สร้างใหม่ตาม Zustand 5 pattern ของ stores ที่มีอยู่ (`user-store.ts`, `vo-session-store.ts` ฯลฯ — `create<State>((set, get) => ...)`).

**Tasks:**
- [ ] Define store interface (see `technical-design.md §7.2`)
- [ ] `conversations`: list + CRUD actions
- [ ] `messages`: Record keyed by `convId`; `appendMessages`, `prependOlderMessages`, `upsertMessage`, `replaceOptimistic`, `removeMessage`
- [ ] `typingUsers`: Record by `convId`
- [ ] `unreadCounts`: per convId; `setUnread`, `clearUnread`, `totalUnread()` selector
- [ ] `activeConversationId` + `setActiveConversation`
- [ ] `activeThreadMessageId` + `setActiveThread`
- [ ] `notifications` list + `notificationUnread` count

**Definition of Done:**
- Vitest unit tests cover `replaceOptimistic`, `upsertMessage` (dedup by ID), `totalUnread`

---

### CHAT-008 · `lib/api/chat.ts` — REST API Helpers (NEW)

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** —  
**Scenarios:** SC-CHAT-01, SC-CHAT-04

> **หมายเหตุ:** `lib/api/chat.ts` ยังไม่มี — สร้างไฟล์ใหม่ ใช้ `authFetch`/`authFetchForm` จาก `lib/api/client.ts` (มี 401 refresh+retry อยู่แล้ว).

**Tasks:**
- [ ] `listConversations(workspaceId)` → GET `/api/user/chat/conversations`
- [ ] `getOrCreateDM(workspaceId, targetUserId)` → POST `/api/user/chat/conversations/dm`
- [ ] `listChannels(workspaceId)` → GET `/api/user/chat/channels`
- [ ] `getConversation(convId)` → GET `/api/user/chat/conversations/:id`
- [ ] `listMessages(convId, before?, limit?)` → GET with cursor params
- [ ] `sendMessageREST(convId, req)` → POST (fallback when WS fails)
- [ ] `editMessage(msgId, content)` → PATCH
- [ ] `deleteMessage(msgId)` → DELETE
- [ ] `listThreadReplies(msgId)` → GET `/api/user/chat/messages/:id/thread`
- [ ] `markRead(convId)` → POST `/api/user/chat/conversations/:id/read`
- [ ] `getUnreadCounts(workspaceId)` → GET `/api/user/chat/unread`
- [ ] All functions use `authFetch` from existing `lib/api/client.ts`
- [ ] Vitest mocks for all functions

**Definition of Done:**
- `npx tsc --noEmit` passes
- Vitest: happy path + 401 + network error covered per function

---

### CHAT-009 · Chat WS — extend `WorkspaceWSClient` (`lib/api/workspace-ws.ts`)

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-007  
**Scenarios:** SC-CHAT-01, SC-CHAT-04

> **หมายเหตุ:** ไม่มีโฟลเดอร์ `lib/ws/` หรือไฟล์ `lib/ws/chat-ws.ts` — WS client จริงคือ class `WorkspaceWSClient` ใน `lib/api/workspace-ws.ts` (single connection ต่อ workspace, มี method `chat(content)` อยู่แล้วเป็นจุดเริ่ม; types อยู่ใน `lib/api/workspace-ws-types.ts`). ให้เพิ่ม chat method/handler ใน `WorkspaceWSClient` หรือ helper module ใน `lib/api/` แทนการสร้าง `lib/ws/chat-ws.ts`.

**Tasks:**
- [ ] เพิ่ม chat methods/handlers ใน `WorkspaceWSClient` (ต่อยอดจาก `chat(content)` ที่มีอยู่)
- [ ] `joinConversation(convId)` / `leaveConversation(convId)`
- [ ] `sendMessage(payload)` with `temp_id` generation (`crypto.randomUUID()`)
- [ ] `onChatMessageNew` → `store.upsertMessage`
- [ ] `onChatMessageAck` → `store.replaceOptimistic(tempId, msg)`
- [ ] `onTypingUpdate` → `store.typingUsers[convId] = users`
- [ ] `onReactionUpdate` → update reactions on message in store
- [ ] `onNotificationNew` → append to `store.notifications`
- [ ] `onUnreadUpdate` → `store.setUnread(convId, count)`
- [ ] Optimistic fail path: 5s timeout → mark message `status: "failed"`

**Definition of Done:**
- Vitest: mock WS, assert `replaceOptimistic` called on ack; assert `upsertMessage` dedupes

---

### CHAT-010 · FE Component — `views/chat/hero-chat.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-007, CHAT-008, CHAT-009  
**Scenarios:** SC-CHAT-01, SC-CHAT-04

**Tasks:**
- [ ] Layout: `flex h-screen` — sidebar left + active panel right
- [ ] Mount: `listConversations` → populate store on load
- [ ] Connect `WorkspaceWSClient` (chat methods) on mount, disconnect on unmount
- [ ] Route: `app/workspace/[id]/chat/page.tsx` (NEW route — ต้องสร้าง) mounts `HeroChat`; พิจารณา `PUBLIC_PATHS` ใน `components/auth-guard.tsx` ถ้าจำเป็น
- [ ] Deep-link: `?conv=<id>` sets `activeConversationId` on mount
- [ ] Pixel spec from `ux-ui-plan.md` — canvas 1440×1024, bg `#242B32`

**Definition of Done:**
- Chat page loads with sidebar + empty panel state
- Switching conversation updates right panel

---

### CHAT-011 · FE Component — `views/chat/components/chat-sidebar.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-010  
**Scenarios:** SC-CHAT-01, SC-CHAT-04, SC-CHAT-10

**Tasks:**
- [ ] DM section: list of DM conversations, avatar + name + last-message preview
- [ ] Channels section: list of channels with `#` prefix
- [ ] Unread badge per item: `store.unreadCounts[convId]` → show red badge (max 99+)
- [ ] Online status dot on DM avatar: green/yellow/gray
- [ ] Active conversation highlight: `bg-[rgba(88,214,141,0.1)] rounded-[8px]`
- [ ] "New DM" button → open DM target picker modal
- [ ] Pixel spec from `ux-ui-plan.md` — sidebar `w-[320px] bg-[#1E252B]`

**Definition of Done:**
- Unread badge shows correct count, clears when conversation opened
- Active state visually correct per Figma

---

### CHAT-012 · FE Component — `views/chat/components/message-item.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** —  
**Scenarios:** SC-CHAT-01, SC-CHAT-04, SC-CHAT-06, SC-CHAT-07

**Tasks:**
- [ ] Avatar + name + timestamp header
- [ ] Consecutive messages from same user: compact (no header repeat within 5 min)
- [ ] Soft-deleted: "ข้อความนี้ถูกลบ" placeholder
- [ ] Edited: "(แก้ไขแล้ว)" label
- [ ] Quoted reply preview (if `reply_to_id`)
- [ ] Reaction bar below message
- [ ] Thread reply count + avatar row: "X replies →"
- [ ] Pinned indicator
- [ ] Hover → action bar: reply, react, edit (own), delete (own/admin), pin (admin)
- [ ] Status indicator on own messages: sending / sent / failed + retry button
- [ ] Optimistic message: render with `opacity-50` while `status = "sending"`

**Definition of Done:**
- All render states visible in Storybook or isolated dev page
- No `console.log` remaining

---

### CHAT-013 · FE Component — `views/chat/components/message-input.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-009  
**Scenarios:** SC-CHAT-01, SC-CHAT-04, SC-CHAT-12

**Tasks:**
- [ ] `<textarea>` auto-resize (1–8 rows)
- [ ] `Enter` = send; `Shift+Enter` = newline
- [ ] Emoji picker button (trigger `EmojiPicker` component)
- [ ] Attach file button (trigger hidden `<input type="file">`)
- [ ] Send button (disabled when empty and no pending attachments)
- [ ] Typing emitter: `useTypingEmitter` hook (see `technical-design.md §7.7`)
- [ ] Show pending attachment previews above input bar with cancel button
- [ ] Max character counter: show warning at 3800/4000, block at 4000
- [ ] On send: call `chatWS.sendMessage()` + clear input + call `onSend` from typing hook

**Definition of Done:**
- `Enter` sends; `Shift+Enter` adds newline
- Typing indicator fires correctly (verified via WS mock in Vitest)

---

### CHAT-014 · FE Component — `views/chat/components/dm-panel.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-011, CHAT-012, CHAT-013  
**Scenarios:** SC-CHAT-01

**Tasks:**
- [ ] Header: other user's avatar + name + online status
- [ ] Message list with infinite scroll (`IntersectionObserver` at top → load older)
- [ ] Scroll-to-bottom on new incoming message (if already near bottom)
- [ ] "Jump to unread" banner when unread messages exist on open
- [ ] `markRead` called on mount and on scroll past unread messages
- [ ] Empty state: "ยังไม่มีข้อความ เริ่มบทสนทนาได้เลย"
- [ ] Pixel spec from `ux-ui-plan.md` — full view `w-[1016px] bg-[#1E252B]`

**Definition of Done:**
- Infinite scroll loads older messages; new messages append at bottom
- `markRead` called → unread badge clears in sidebar

---

### CHAT-015 · FE Component — `views/chat/components/channel-panel.tsx`

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-014  
**Scenarios:** SC-CHAT-04

**Tasks:**
- [ ] Header: `#channel-name` + member count + settings icon (admin)
- [ ] Reuse message list + `MessageInput` from DM panel
- [ ] Pinned messages banner (if any pinned) → expandable
- [ ] @mention autocomplete: `@` triggers member picker dropdown

**Definition of Done:**
- Channel renders correctly with pinned banner
- @mention dropdown appears on `@` key

---

### CHAT-016 · Unread Count — `tb_user_last_read` Integration

**Layer:** zyra-api + zyra-ws + zyra-app  
**Effort:** M  
**Depends on:** CHAT-004, CHAT-006, CHAT-008  
**Scenarios:** SC-CHAT-10 (basic)

**Tasks:**
- [ ] API: `POST /api/user/chat/conversations/:id/read` → upsert `tb_user_last_read`
- [ ] API: `GET /api/user/chat/unread` → COUNT messages where `created_at > last_read_at` per conversation
- [ ] WS: on `chat:read` event → debounce 2s → call REST read endpoint
- [ ] WS: after new message saved → push `chat:unread:update` to all members not in that conversation room
- [ ] FE: on conversation open → dispatch `markRead`; listen to `onUnreadUpdate` to update store
- [ ] FE: `chat-sidebar` reads `store.unreadCounts`; badge shows `99+` when > 99

**Definition of Done:**
- User opens conversation → badge clears immediately
- User receives message while in another conversation → badge increments

---

## Phase 2 — Group + Thread + Reactions

> Delivers: SC-CHAT-05 (Group), SC-CHAT-06 (Thread), SC-CHAT-07 (Emoji Reaction)

---

### CHAT-017 · Go Service — Group: AddMembers, AutoAdmin Promote

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-003  
**Scenarios:** SC-CHAT-05

**Tasks:**
- [ ] `CreateGroup` already in CHAT-003 — add: notification to all added members (`group_add`)
- [ ] `AddConversationMembers` — enforce 50-member limit with `ErrGroupMemberLimit`
- [ ] `LeaveConversation` — if leaving user is only admin, promote oldest-joined member to admin
- [ ] `LeaveConversation` — if last member leaves, set `archived_at` (no deletion)
- [ ] Unit tests for all 3 scenarios

**Definition of Done:**
- Leave-last-admin test: promotes next member
- Leave-last-member test: `archived_at` set

---

### CHAT-018 · FE Component — `create-group-modal.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-008  
**Scenarios:** SC-CHAT-05

**Tasks:**
- [ ] Step 1: Search + multi-select members (2–50); show avatar + name chips
- [ ] Step 2: Optional group name (max 100 chars); auto-generate from member names if blank
- [ ] Step 3: "สร้าง Group" → `createGroup()` → navigate to new group conversation
- [ ] Group icon: collage of first 4 member avatars (CSS grid 2×2)
- [ ] Pixel spec from Figma node `2081-35462`

**Definition of Done:**
- Can create group with 2 members, no name → auto-name displayed
- Name input enforces max 100 chars

---

### CHAT-019 · FE Component — `group-panel.tsx`

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-014, CHAT-018  
**Scenarios:** SC-CHAT-05

**Tasks:**
- [ ] Header: group icon (collage) + name + member count
- [ ] Group info panel: member list + role badges + add/remove (admin only)
- [ ] Leave group button (for non-admin members)
- [ ] Reuse message list + `MessageInput`

**Definition of Done:**
- Admin sees add/remove controls; member sees only "Leave Group"

---

### CHAT-020 · Go Service — Thread: `ListThreadReplies`, depth guard

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-004  
**Scenarios:** SC-CHAT-06

**Tasks:**
- [ ] `SendMessage` — when `reply_to_id` is set, assert parent message `reply_to_id IS NULL` (no nested threads)
- [ ] `ListThreadReplies` — returns flat list ordered by `created_at ASC`
- [ ] Include `thread_count` and first 3 reactor avatars in `ListMessages` response for messages with replies

**Definition of Done:**
- Attempting to reply to a reply returns 400 with "cannot nest threads" error

---

### CHAT-021 · FE Component — `thread-panel.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-012, CHAT-013  
**Scenarios:** SC-CHAT-06

**Tasks:**
- [ ] Slides in from right as overlay; does not replace main panel
- [ ] Header: parent message quoted at top
- [ ] Reply list below (flat, `created_at ASC`)
- [ ] `MessageInput` at bottom (send with `reply_to_id = parentId`)
- [ ] Thread reply count badge on parent message updates in real-time
- [ ] Close button → `setActiveThread(null)`
- [ ] Pixel spec from Figma node `2096-1032317`

**Definition of Done:**
- Thread panel opens without hiding main chat
- Reply appears in both thread panel and as count badge on parent

---

### CHAT-022 · zyra-ws — Thread Reply Broadcast

**Layer:** zyra-ws  
**Effort:** S  
**Depends on:** CHAT-006, CHAT-020  
**Scenarios:** SC-CHAT-06

**Tasks:**
- [ ] `chat:message:new` broadcast includes `reply_to_id` field
- [ ] FE store: on receiving `chat:message:new` with `reply_to_id` → increment `thread_count` on parent message in store
- [ ] Notification: trigger `reply` notification for thread participants + parent message author

**Definition of Done:**
- Reply sent → parent message `thread_count` increments for all clients in room

---

### CHAT-023 · Go Service — Reaction: Add / Remove / Aggregate

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-002  
**Scenarios:** SC-CHAT-07

**Tasks:**
- [ ] `AddReaction(ctx, msgID, userID, emoji)` — upsert into `tb_message_reaction`; check 20-type limit; return full `ReactionGroup[]`
- [ ] `RemoveReaction(ctx, msgID, userID, emoji)` — DELETE from `tb_message_reaction`
- [ ] `ListReactions(ctx, msgID, viewerID)` — aggregate by emoji; set `my_react` flag per viewer

**Definition of Done:**
- 20 distinct emoji types → 21st returns `ErrReactionLimit`
- Same user clicking same emoji: returns 200 (idempotent via UPSERT)

---

### CHAT-024 · Go Handler — Reaction Endpoints

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-023  
**Scenarios:** SC-CHAT-07

**Tasks:**
- [ ] `POST /api/user/chat/messages/:id/reactions` → `AddReaction`
- [ ] `DELETE /api/user/chat/messages/:id/reactions/:emoji` → `RemoveReaction`
- [ ] `GET /api/user/chat/messages/:id/reactions` → `ListReactions`
- [ ] Register in `router.go`

**Definition of Done:**
- `curl` smoke test: add/remove/list reactions return correct shapes

---

### CHAT-025 · zyra-ws — Reaction Broadcast

**Layer:** zyra-ws  
**Effort:** S  
**Depends on:** CHAT-006, CHAT-024  
**Scenarios:** SC-CHAT-07

**Tasks:**
- [ ] Handle `chat:reaction` inbound event: call REST to persist → broadcast `chat:reaction:update` with full `ReactionGroup[]` to conversation room
- [ ] FE: `onReactionUpdate` handler in `ChatWSClient` → update reactions on message in store

**Definition of Done:**
- User A reacts → User B sees reaction within 300ms without page reload

---

### CHAT-026 · FE Component — `emoji-picker.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** —  
**Scenarios:** SC-CHAT-07

**Tasks:**
- [ ] Quick bar: 6 most-used emojis on message hover (👍 ❤️ 😂 😮 😢 🎉)
- [ ] Full picker: emoji grid grouped by category + search input
- [ ] Frequently used section at top (stored in localStorage `zyra_emoji_frequent`)
- [ ] Click emoji → trigger `chatWS.sendReaction()` or insert into message input (context-dependent)
- [ ] Pixel spec from Figma node `2096-1559539`

**Definition of Done:**
- Picker opens on hover action bar; quick bar reacts within 100ms
- Clicking same emoji twice removes reaction (toggle behavior)

---

### CHAT-027 · FE — Reaction Display on `message-item.tsx`

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-012, CHAT-025, CHAT-026  
**Scenarios:** SC-CHAT-07

**Tasks:**
- [ ] Reaction bar below message: emoji + count chips
- [ ] `my_react = true` → chip has active bg `bg-[rgba(88,214,141,0.15)] border-[#58D68D]`
- [ ] Hover on chip → tooltip with user names who reacted
- [ ] Clicking chip → toggle reaction via `chatWS.sendReaction()`
- [ ] Optimistic: immediately add/remove reaction chip before WS confirms

**Definition of Done:**
- Toggle works: add → chip appears; click again → chip disappears
- Count accurate after broadcast

---

### CHAT-028 · `lib/api/chat.ts` — Group + Thread + Reaction helpers

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-008  
**Scenarios:** SC-CHAT-05, SC-CHAT-06, SC-CHAT-07

**Tasks:**
- [ ] `createGroup(workspaceId, req)` → POST `/api/user/chat/conversations/group`
- [ ] `listThreadReplies(msgId)` → GET `/api/user/chat/messages/:id/thread`
- [ ] `addReaction(msgId, emoji)` → POST
- [ ] `removeReaction(msgId, emoji)` → DELETE
- [ ] `listReactions(msgId)` → GET

**Definition of Done:**
- Vitest mocks cover all new functions

---

## Phase 3 — Attachments

> Delivers: SC-CHAT-08 (File Upload), SC-CHAT-09 (File Error)

---

### CHAT-029 · Go Service — `attachment_service.go`

**Layer:** zyra-api  
**Effort:** L  
**Depends on:** CHAT-001, CHAT-002  
**Scenarios:** SC-CHAT-08, SC-CHAT-09

**Tasks:**
- [ ] `UploadAttachment(ctx, convID, userID, file, header)`:
  - Read first 512 bytes → validate magic bytes vs `allowedMIME` map
  - Assert `file.Size ≤ 25 MB`
  - Upload to R2: key `chat/{convId}/{uuid}.ext`
  - If image: generate 300px thumbnail (`imaging.Fit`) → upload as `{uuid}_thumb.jpg`
  - INSERT `tb_message_attachment` with `scan_status = 'pending'`
  - Return `Attachment` struct
- [ ] `LinkAttachments(ctx, msgID, attachmentIDs []string)` — UPDATE `message_id` on attachment rows
- [ ] `ScanComplete(ctx, attachmentID, status)` — UPDATE `scan_status`; broadcast `chat:attachment:scanned` to conversation if infected
- [ ] Unit tests: valid image, valid PDF, oversized file, disallowed MIME

**Definition of Done:**
- Valid JPEG → R2 URL returned; thumbnail also on R2
- Oversized file → error before any upload begins
- `.exe` file → magic bytes check fails even with spoofed MIME

---

### CHAT-030 · Go Handler — `attachment_handler.go`

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-029  
**Scenarios:** SC-CHAT-08, SC-CHAT-09

**Tasks:**
- [ ] `POST /api/user/chat/attachments` — parse multipart; call `UploadAttachment`; return `Attachment`
- [ ] Register in `router.go` under `UserGuard`
- [ ] Max 5 files check at handler level (loop over multipart parts)

**Definition of Done:**
- Upload 6 files → only first 5 processed; 6th returns partial error
- File > 25 MB → 413 response

---

### CHAT-031 · FE — File Upload in `message-input.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-013  
**Scenarios:** SC-CHAT-08, SC-CHAT-09

**Tasks:**
- [ ] `<input type="file" multiple accept="...">` (hidden, triggered by button)
- [ ] Drag-and-drop zone on message panel (highlight on dragover)
- [ ] Client-side validation: `file.size`, `file.type`, count ≤ 5
- [ ] Per-file error message inline (not blocking other valid files)
- [ ] For valid files: call `uploadAttachment()` → show progress bar with cancel button
- [ ] On success: add `attachment_id` to pending list; show thumbnail or file card preview
- [ ] Cancel: `DELETE /api/user/chat/attachments/:id` (remove from R2 + DB if not yet linked to message)

**Definition of Done:**
- Drag-drop works; cancel mid-upload aborts XHR
- Error shown per-file without blocking valid files

---

### CHAT-032 · `lib/api/chat.ts` — `uploadAttachment`

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-008  
**Scenarios:** SC-CHAT-08

**Tasks:**
- [ ] `uploadAttachment(convId, file, onProgress)` — POST multipart with `XMLHttpRequest` for progress events
- [ ] Returns `Attachment` on success
- [ ] `cancelAttachmentUpload(attachmentId)` — DELETE

**Definition of Done:**
- Vitest: mock XHR; assert `onProgress` called with % values

---

### CHAT-033 · FE Component — Attachment Rendering in `message-item.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-012  
**Scenarios:** SC-CHAT-08, SC-CHAT-09

**Tasks:**
- [ ] Image attachment: show `thumb_url` inline (max `w-[300px] rounded-[8px]`); click → fullscreen lightbox
- [ ] Non-image: file card with mime-type icon (lucide), file name, size formatted (KB/MB), download link
- [ ] `scan_status = 'infected'`: red card "ไฟล์นี้ไม่ปลอดภัย" — no download link
- [ ] `scan_status = 'pending'`: show spinner overlay on file card
- [ ] Multiple attachments in one message: grid layout (max 4 visible, "+N more" overflow)

**Definition of Done:**
- Image click opens lightbox (no `<a>` for lightbox trigger — use `<button>`)
- Infected file: no href present in DOM

---

### CHAT-034 · FE Component — `file-preview.tsx` (Lightbox)

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** —  
**Scenarios:** SC-CHAT-08

**Tasks:**
- [ ] Fixed overlay `z-50` with black bg `bg-black/80`
- [ ] Center image with `max-w-[90vw] max-h-[90vh]`
- [ ] Close on overlay click or `Escape` key
- [ ] Download button (top-right)
- [ ] Previous / Next arrows if message has multiple images

**Definition of Done:**
- `Escape` closes lightbox; overlay click closes; download attr triggers save

---

### CHAT-035 · Virus Scan Stub — `ScanWorker`

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-029  
**Scenarios:** SC-CHAT-08, SC-CHAT-09

**Tasks:**
- [ ] Background goroutine: poll `tb_message_attachment WHERE scan_status = 'pending'` every 30s
- [ ] Stub: mark all pending → `clean` (real provider TBD — see Open Question #2 in `technical-design.md`)
- [ ] On `infected`: UPDATE `scan_status = 'infected'`; push `chat:attachment:scanned` via WS to conversation members
- [ ] FE: `onAttachmentScanned` event → update attachment in store → re-render file card

**Definition of Done:**
- Stub worker runs without goroutine leak
- Test: inject `infected` row → WS event fired within 35s

---

### CHAT-036 · Go Unit Tests — Attachment Service

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-029  
**Scenarios:** SC-CHAT-08, SC-CHAT-09

**Tasks:**
- [ ] `TestUploadAttachment_ValidJPEG`
- [ ] `TestUploadAttachment_ValidPDF`
- [ ] `TestUploadAttachment_OversizedFile`
- [ ] `TestUploadAttachment_DisallowedMIME_SpoofedExtension`
- [ ] `TestLinkAttachments_Valid`
- [ ] `TestLinkAttachments_WrongOwner` (attachment from different conversation)

**Definition of Done:**
- `go test ./internal/service/... -run TestAttachment` all pass

---

### CHAT-037 · API Tests — Attachment Endpoints

**Layer:** Integration test  
**Effort:** S  
**Depends on:** CHAT-030  
**Scenarios:** SC-CHAT-08, SC-CHAT-09

**Tasks:**
- [ ] POST valid image → 200 with `file_url` (S3 URL)
- [ ] POST non-image → 200 with `file_url` (no `thumb_url`)
- [ ] POST > 25 MB → 413
- [ ] POST unsupported type `.exe` (spoofed as `image/jpeg`) → 400 (magic bytes check)
- [ ] POST 6 files in one request → partial success: 5 uploaded, 6th error

**Definition of Done:**
- All 5 cases pass against running zyra-api + R2

---

## Phase 4 — Notifications + Search

> Delivers: SC-CHAT-10 (Full Notifications), SC-CHAT-11 (Search)

---

### CHAT-038 · Go Service — `notification_service.go` (NEW)

**Layer:** zyra-api  
**Effort:** L  
**Depends on:** CHAT-001, CHAT-004  
**Scenarios:** SC-CHAT-10

> **หมายเหตุ:** ยังไม่มี `NotificationService` หรือ `tb_notification` อยู่จริง — เป็น component ใหม่ใน zyra-api. การส่ง email digest ไม่ใช้ SMTP ในตัว zyra-api แต่เรียก **zyra-notifications** (POST `/v1/email` ผ่าน `notify.Client`).

**Tasks:**
- [ ] `CreateForMessage(ctx, msg, convID)` — parse @mentions from content; determine recipients (DM → other user, channel → all active members, group → all members); exclude muted users
- [ ] `CreateGroupAdd(ctx, convID, actorID, userIDs)` — `group_add` notification for each added user
- [ ] `CreateReactionNotif(ctx, msgID, reactorID, emoji)` — `reaction` notification for message owner
- [ ] `ListNotifications(ctx, userID, limit, before)` — paginated; join `actor` + `conversation` info
- [ ] `MarkRead(ctx, notifID, userID)` — single notification read
- [ ] `MarkAllRead(ctx, userID)` — bulk UPDATE
- [ ] `GetUnreadCount(ctx, userID)` — COUNT WHERE `is_read = false`
- [ ] Email digest: `SendDigest(ctx, userID)` — collect unread notifications; check last WS heartbeat > 5 min; ส่งผ่าน zyra-notifications (POST `/v1/email` ด้วย `notify.Client`; ต้องเพิ่ม chat digest template ใหม่ใน zyra-notifications — ยังไม่มี). หมายเหตุ: ถ้า `NOTIFICATION_SERVICE_URL` ว่าง การส่งเป็น no-op (ไม่มี SMTP fallback)

**Definition of Done:**
- Unit tests: DM notification created; @mention parsed; muted user excluded
- Email: `notify.Client` mock called with correct recipient (template + params) + digest content

---

### CHAT-039 · Go Handler — Notification Endpoints

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-038  
**Scenarios:** SC-CHAT-10

**Tasks:**
- [ ] `GET /api/user/notifications` → `ListNotifications`
- [ ] `POST /api/user/notifications/read-all` → `MarkAllRead`
- [ ] `PATCH /api/user/notifications/:id/read` → `MarkRead`
- [ ] Register in `router.go` under `UserGuard`

**Definition of Done:**
- `GET` returns paginated list; `PATCH` marks single read; `POST` marks all

---

### CHAT-040 · zyra-ws — Notification Push

**Layer:** zyra-ws  
**Effort:** S  
**Depends on:** CHAT-006, CHAT-038  
**Scenarios:** SC-CHAT-10

**Tasks:**
- [ ] After `NotificationService.CreateForMessage` saves to DB, push `chat:notification:new` to each recipient's WS connection (by userID)
- [ ] Hub: `SendToUser(userID, msg)` helper — iterate active clients, match by userID

**Definition of Done:**
- User A sends to User B → User B receives `chat:notification:new` within 200ms

---

### CHAT-041 · FE Component — `notification-bell.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-007, CHAT-040  
**Scenarios:** SC-CHAT-10

**Tasks:**
- [ ] Bell icon (`lucide-react Bell`) with red badge showing `store.notificationUnread`
- [ ] Badge shows `99+` when > 99
- [ ] Click → dropdown panel: list of `store.notifications` with preview
- [ ] Notification item: sender avatar + preview text + timestamp + unread dot
- [ ] @mention notifications highlighted in distinct color
- [ ] Click notification item → navigate to conversation + `markRead(notifId)` + `markRead(convId)` (unread badge clears)
- [ ] "Mark all as read" button
- [ ] `onNotificationNew` WS handler → prepend to store + increment `notificationUnread`

**Definition of Done:**
- Badge increments on new notification; clears on mark-all-read
- Click navigates to correct conversation

---

### CHAT-042 · FE — Mute Toggle UI in `conversation-info-panel.tsx`

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-008  
**Scenarios:** SC-CHAT-10

**Tasks:**
- [ ] Conversation info panel (right side slide-in from conversation header)
- [ ] Mute toggle: custom `<button>` switch (no shadcn) showing current mute state
- [ ] On toggle → `toggleMute(convId)` → store updates `conversations[convId].isMuted`
- [ ] Muted conversation: bell icon crossed out in sidebar

**Definition of Done:**
- Mute persists across page reload (store re-fetches from API on mount)

---

### CHAT-043 · Go Service — `chat_search_service.go`

**Layer:** zyra-api  
**Effort:** M  
**Depends on:** CHAT-001  
**Scenarios:** SC-CHAT-11

**Tasks:**
- [ ] `SearchMessages(ctx, workspaceID, userID string, params SearchParams)` — PostgreSQL FTS query with `ts_headline` (see `technical-design.md §9.1`)
- [ ] `SearchParams`: `Query`, `In *string`, `From *string`, `After *time.Time`, `Before *time.Time`, `Limit int`
- [ ] Validate: user is member of workspace; query non-empty
- [ ] Never returns proximity chat messages (type != 'proximity')
- [ ] Never returns soft-deleted messages

**Definition of Done:**
- Thai keyword search returns results
- Filter by `in`, `from`, `after`, `before` all work independently
- Deleted message never appears in results

---

### CHAT-044 · Go Handler — Search Endpoint

**Layer:** zyra-api  
**Effort:** S  
**Depends on:** CHAT-043  
**Scenarios:** SC-CHAT-11

**Tasks:**
- [ ] `GET /api/user/chat/search?q=&in=&from=&after=&before=&limit=` → `SearchMessages`
- [ ] Register in `router.go`
- [ ] Return max 50 results + `total` count

**Definition of Done:**
- Smoke test: query returns `content_snippet` with `<mark>` tags

---

### CHAT-045 · `lib/api/chat.ts` — `searchMessages` (debounced)

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-008  
**Scenarios:** SC-CHAT-11

**Tasks:**
- [ ] `searchMessages(params)` — debounced 300ms; GET `/api/user/chat/search`
- [ ] Vitest: assert debounce; mock returns results

**Definition of Done:**
- Rapid keystroke sends only 1 request after 300ms idle

---

### CHAT-046 · FE Component — `search-panel.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-045  
**Scenarios:** SC-CHAT-11

**Tasks:**
- [ ] Trigger: search icon in sidebar or `Cmd+K`
- [ ] Overlay panel (full-width or side panel per Figma node `2162-83837`)
- [ ] Input with debounced search call
- [ ] Filter bar: "From" user picker, "In" channel/DM picker, Date range
- [ ] Result list: sender avatar + snippet with `<mark>` highlighted + channel + timestamp
- [ ] Click result: close search panel → navigate to conversation → scroll to message → highlight 3s animation
- [ ] Empty state: "ไม่พบผลลัพธ์สำหรับ '{query}'"
- [ ] Loading skeleton while fetching

**Definition of Done:**
- Click result scrolls to correct message and highlights it for 3 seconds
- Filters narrow results correctly

---

### CHAT-047 · FE — Scroll-to-Message + Highlight

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-014, CHAT-046  
**Scenarios:** SC-CHAT-11

**Tasks:**
- [ ] After navigating to conversation from search, receive `targetMessageId` prop
- [ ] If message is in current page: `element.scrollIntoView({ behavior: 'smooth' })`
- [ ] If message not yet loaded: fetch messages around `targetMessageId` → insert into store → scroll
- [ ] Add `ring-2 ring-[#58D68D]` highlight class for 3s then remove

**Definition of Done:**
- Message scrolled to and highlighted within 500ms of search result click

---

### CHAT-048 · Email Digest — Inactivity Gate

**Layer:** zyra-api  
**Effort:** M  
**Depends on:** CHAT-038  
**Scenarios:** SC-CHAT-10

**Tasks:**
- [ ] Cron-like goroutine ใน zyra-api: every 5 min, find users with `last_ws_heartbeat < now() - 5min` and unread notifications
- [ ] Batch notifications by user → ส่งผ่าน zyra-notifications (POST `/v1/email` ด้วย `notify.Client`; chat digest template ต้องเพิ่มใหม่ใน zyra-notifications — ยังไม่มี). zyra-api ไม่มี SMTP/HTML email infra ในตัว; ถ้า `NOTIFICATION_SERVICE_URL` ว่าง → skip แบบ no-op
- [ ] Mark digest sent: set `email_digest_sent_at` on notifications
- [ ] Respect mute settings: skip muted conversations in digest
- [ ] Unit test: mock `notify.Client`; assert digest sent only after 5-min inactivity

**Definition of Done:**
- User offline 5+ min with unread messages → `notify.Client` called with digest template
- User online → no email sent

---

## Phase 5 — Proximity + Typing

> Delivers: SC-CHAT-02 (Proximity auto-open), SC-CHAT-03 (Leave proximity), SC-CHAT-12 (Typing indicator)

---

### CHAT-049 · zyra-ws — Proximity Session (Redis Set)

**Layer:** zyra-ws  
**Effort:** L  
**Depends on:** —  
**Scenarios:** SC-CHAT-02, SC-CHAT-03

**Tasks:**
- [ ] On `avatar:move` event: compute `session_id = floor(x/200)+":"+floor(y/200)`
- [ ] Compare with user's current `proximity_session_id` stored in `client.go`
- [ ] If changed: `SREM` old key, `SADD` new key; both with TTL 30s
- [ ] Grace period: set `proximity_leaving_timer` 1s; if user re-enters same session within 1s → cancel timer (prevent flicker)
- [ ] Rejoin window: if same `session_id` rejoined within 5s → skip `proximity:join` broadcast noise
- [ ] On SADD result == 1 (first member): create new session; broadcast nothing
- [ ] On SADD result > 1: broadcast `proximity:join { user_id, user_name }` to all session members
- [ ] On SREM + SCARD == 0: session destroyed (Redis key expires naturally)
- [ ] Max 10 members per session: if SCARD == 10, reject new member with `proximity:full`
- [ ] On client disconnect: SREM from current session

**Definition of Done:**
- 2 clients: A moves into B's tile → both receive `proximity:join`
- A moves away → B receives `proximity:leave`; A receives 2s grace toast
- SCARD > 10 → reject with `proximity:full`

---

### CHAT-050 · zyra-ws — Proximity Message Relay

**Layer:** zyra-ws  
**Effort:** S  
**Depends on:** CHAT-049  
**Scenarios:** SC-CHAT-02, SC-CHAT-03

**Tasks:**
- [ ] Handle `proximity:text` inbound: assert sender is in a proximity session
- [ ] Broadcast `proximity:message { sender_id, sender_name, text, session_id }` to all members in same Redis set
- [ ] **Do NOT persist to DB** — proximity messages are ephemeral
- [ ] Validate: `text` max 4000 chars (same as regular message)

**Definition of Done:**
- Message from A relayed to B and C in same session
- Not stored: PostgreSQL `tb_message` count unchanged after proximity message

---

### CHAT-051 · FE Component — `proximity-panel.tsx`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** —  
**Scenarios:** SC-CHAT-02, SC-CHAT-03

**Tasks:**
- [ ] Rendered as overlay on Virtual Office map (`hero-virtual-office.tsx`)
- [ ] Auto-opens on `proximity:join` WS event; auto-closes on all members leave or self leaves
- [ ] Shows member list with avatars (everyone in current session)
- [ ] Ephemeral message list (in-memory only, cleared on panel close)
- [ ] `MessageInput` — sends `proximity:text` event (not REST)
- [ ] Visual indicator: pulsing ring around own avatar tile when in proximity session
- [ ] On panel open: fade-in animation; on close: fade-out + 2s warning toast first
- [ ] Pixel spec from Figma node `2012-260260`

**Definition of Done:**
- Panel opens without user action when another avatar is near
- No proximity messages persist in DB (verified by API count check)

---

### CHAT-052 · FE — Virtual Office Map Proximity Integration

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-051  
**Scenarios:** SC-CHAT-02, SC-CHAT-03

**Tasks:**
- [ ] In `hero-virtual-office.tsx`: wire `chatWS.onProximityJoin` → show `ProximityPanel`
- [ ] Wire `chatWS.onProximityLeave` → update session member list; close panel if empty
- [ ] On own avatar move: send `avatar:move` which triggers server proximity recalculation
- [ ] Toast: "กำลังออกจากพื้นที่สนทนา..." (2s before panel close) — use `lib/toast.tsx`
- [ ] If message typed in input when panel closes: discard text (spec: SC-CHAT-03)

**Definition of Done:**
- Move away triggers 2s toast then panel fades out
- Input discarded on auto-close

---

### CHAT-053 · zyra-ws — Typing: Redis TTL + Aggregate Broadcast

**Layer:** zyra-ws  
**Effort:** M  
**Depends on:** CHAT-006  
**Scenarios:** SC-CHAT-12

**Tasks:**
- [ ] Handle `chat:typing:start`: `SET typing:{convId}:{userId} {name} EX 3`
- [ ] Handle `chat:typing:stop`: `DEL typing:{convId}:{userId}`
- [ ] Background goroutine per conversation room (lazy-started on first `typing:start`): every 500ms, SCAN `typing:{convId}:*` → collect names → broadcast `chat:typing { conversation_id, users: [{id, name}] }` to room
- [ ] Do NOT send `chat:typing` back to sender
- [ ] Stop goroutine when no typing keys remain (idle 5s)
- [ ] Keyspace notification fallback: subscribe to `__keyevent@*__:expired` for auto-stop on TTL

**Definition of Done:**
- User A types → User B sees `chat:typing` within 1s
- A stops 3s → B sees `chat:typing { users: [] }` within 4s (TTL + 500ms poll)

---

### CHAT-054 · FE Component — `typing-indicator.tsx`

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-009  
**Scenarios:** SC-CHAT-12

**Tasks:**
- [ ] `store.typingUsers[convId]` → render below message list, above input
- [ ] 0 users: hidden
- [ ] 1 user: "[name] กำลังพิมพ์..."
- [ ] 2–3 users: "[name1] และ [name2] กำลังพิมพ์..."
- [ ] 4+ users: "หลายคนกำลังพิมพ์..."
- [ ] Animated dots: 3 dots bouncing (`animate-bounce` staggered by 100ms each)
- [ ] Never shows own name
- [ ] Pixel spec from Figma node `2151-1217508`

**Definition of Done:**
- All 4 user-count cases render correctly
- Own typing never shown

---

### CHAT-055 · FE — `useTypingEmitter` Hook

**Layer:** zyra-app  
**Effort:** S  
**Depends on:** CHAT-009, CHAT-013  
**Scenarios:** SC-CHAT-12

**Tasks:**
- [ ] `onKeyDown`: if not already sending → `chatWS.sendTypingStart(convId)`; set 3s debounce timer
- [ ] Timer fires → `chatWS.sendTypingStop(convId)`; reset flag
- [ ] `onSend`: clear timer → `chatWS.sendTypingStop(convId)` immediately
- [ ] `onBlur`: clear timer → `chatWS.sendTypingStop(convId)` immediately
- [ ] Vitest: simulate 3 keydowns + wait 3s → assert `sendTypingStop` called once

**Definition of Done:**
- Hook correctly calls start once per burst; stop once per idle/send

---

### CHAT-056 · Go Unit Tests — ChatService + NotificationService

**Layer:** zyra-api  
**Effort:** M  
**Depends on:** CHAT-003, CHAT-004, CHAT-038  
**Scenarios:** all

**Tasks:**
- [ ] All table-driven tests from `test-plan.md §1.1` — ChatService section
- [ ] All table-driven tests from `test-plan.md §1.1` — NotificationService section
- [ ] Coverage report ≥ 80% on `internal/service/chat_service.go`
- [ ] Coverage report ≥ 80% on `internal/service/notification_service.go`

**Definition of Done:**
- `go test ./internal/service/... -cover` shows ≥ 80%

---

### CHAT-057 · TypeScript Unit Tests — `lib/api/chat.ts`, `stores/chat-store.ts`

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-008, CHAT-007  
**Scenarios:** all

**Tasks:**
- [ ] All Vitest cases from `test-plan.md §1.2` — chat.ts functions
- [ ] `chat-store`: replaceOptimistic, upsertMessage dedup, totalUnread
- [ ] `WorkspaceWSClient` chat methods: mock WS, assert ack flow, optimistic fail path
- [ ] Coverage ≥ 80% on `lib/api/chat.ts` and `stores/chat-store.ts`

**Definition of Done:**
- `npx vitest run --coverage` ≥ 80% for chat files

---

### CHAT-058 · Playwright E2E — Core Chat Flows

**Layer:** zyra-app (e2e/)  
**Effort:** L  
**Depends on:** All Phase 1–5 tasks  
**Scenarios:** all

**Tasks:**
- [ ] `E2E-CHAT-01`: DM send + receive (2 browser contexts)
- [ ] `E2E-CHAT-04`: Channel message → all members receive
- [ ] `E2E-CHAT-05`: Create group + send first message
- [ ] `E2E-CHAT-06`: Thread reply → count badge updates on parent
- [ ] `E2E-CHAT-07`: Emoji reaction toggle (add + remove)
- [ ] `E2E-CHAT-08`: File upload (image + PDF)
- [ ] `E2E-CHAT-09`: Oversized file + wrong type → inline error
- [ ] `E2E-CHAT-10`: Unread badge → open conversation → badge clears
- [ ] `E2E-CHAT-11`: Search keyword → click result → scroll to highlighted message
- [ ] `E2E-CHAT-12`: Typing indicator → 3s timeout → indicator disappears
- [ ] `E2E-CHAT-02`: Proximity panel auto-opens on avatar proximity
- [ ] `E2E-CHAT-03`: Move away → 2s toast → panel closes
- [ ] Member API separation assertion wired for all tests (no `/api/admin/*` calls)
- [ ] Run on Chromium + Firefox + WebKit

**Definition of Done:**
- All 13 E2E tests pass on Chromium
- Firefox + WebKit: core 5 (DM, channel, group, unread, reactions) pass

---

## Dependency Graph (Phase Summary)

```
CHAT-001 (DB)
    └── CHAT-002 (Models)
            ├── CHAT-003 (Service: Conversations)
            │       ├── CHAT-004 (Service: Messages) ──── CHAT-007 (Store)
            │       │       ├── CHAT-005 (Handler)   ──── CHAT-008 (lib/api)
            │       │       └── CHAT-016 (Unread)    ──── CHAT-009 (ChatWSClient)
            │       └── CHAT-006 (WS: chat rooms)         │
            │                                             CHAT-010 (hero-chat)
            ├── CHAT-017 (Group logic)                     ├── CHAT-011 (sidebar)
            │       └── CHAT-018 (create-group-modal)      ├── CHAT-012 (message-item)
            ├── CHAT-020 (Threads)                         ├── CHAT-013 (message-input)
            │       ├── CHAT-021 (thread-panel)            ├── CHAT-014 (dm-panel)
            │       └── CHAT-022 (WS thread broadcast)     └── CHAT-015 (channel-panel)
            ├── CHAT-023 (Reactions)
            │       ├── CHAT-024 (Handler)
            │       ├── CHAT-025 (WS broadcast)
            │       └── CHAT-026/027 (emoji-picker + FE)
            ├── CHAT-029 (Attachment Service)
            │       ├── CHAT-030 (Handler)
            │       ├── CHAT-031/032 (FE upload)
            │       └── CHAT-033/034 (FE rendering)
            ├── CHAT-038 (Notification Service)
            │       ├── CHAT-039/040 (Handler + WS push)
            │       ├── CHAT-041 (notification-bell)
            │       └── CHAT-048 (email digest)
            ├── CHAT-043 (Search Service)
            │       ├── CHAT-044 (Handler)
            │       └── CHAT-046/047 (search-panel + scroll)
            ├── CHAT-049 (WS Proximity Sessions)
            │       └── CHAT-050/051/052 (proximity relay + FE)
            └── CHAT-053 (WS Typing TTL)
                    └── CHAT-054/055 (typing-indicator + hook)

Tests (parallel to implementation):
    CHAT-056 (Go unit tests) — runs alongside CHAT-003 ~ CHAT-038
    CHAT-057 (TS unit tests) — runs alongside CHAT-007 ~ CHAT-028
    CHAT-058 (E2E) — runs after all phases complete
    CHAT-059 (Test Reporting setup) — runs alongside CHAT-056 ~ CHAT-058
    CHAT-060 (Visual Regression baseline) — runs after Phase 1 FE complete
    CHAT-061 (Visual Regression CI gate) — runs alongside CHAT-060
```

---

## Phase 6 — Test Reporting & Visual Regression

> Cross-cutting quality layer — set up alongside Phase 1 and mature through each phase.

---

### CHAT-059 · Test Reporting Setup

**Layer:** zyra-api + zyra-app + CI  
**Effort:** M  
**Depends on:** CHAT-056, CHAT-057, CHAT-058  
**Scenarios:** all

#### 6.1 Go Coverage Report

**Tasks:**
- [ ] Add `go test ./... -coverprofile=coverage.out -covermode=atomic` to CI step
- [ ] Generate HTML report: `go tool cover -html=coverage.out -o coverage.html`
- [ ] Upload `coverage.html` as CI artifact (retain 30 days)
- [ ] Add `go-badge` step: generate coverage badge → write to `zyra.doc/badges/api-coverage.svg`
- [ ] CI gate: fail build if `internal/service/chat_service.go` coverage < 80%
  ```yaml
  - run: |
      COVERAGE=$(go tool cover -func=coverage.out | grep "chat_service.go" | awk '{print $3}')
      echo "Coverage: $COVERAGE"
      python3 -c "import sys; v=float('$COVERAGE'.replace('%','')); sys.exit(1) if v < 80 else None"
  ```

**Definition of Done:**
- CI artifact contains `coverage.html` with line-by-line highlights
- Build fails if chat service coverage drops below 80%

---

#### 6.2 TypeScript Coverage Report (Vitest)

**Tasks:**
- [ ] Add `@vitest/coverage-v8` provider to `vitest.config.ts`
  ```ts
  coverage: {
    provider: "v8",
    reporter: ["text", "html", "lcov"],
    include: ["lib/**/*.ts", "stores/**/*.ts"],
    thresholds: { lines: 80, functions: 80, branches: 75 }
  }
  ```
- [ ] Output to `coverage/` dir; upload as CI artifact
- [ ] LCOV report → feed into Codecov or similar for PR diff coverage comments
- [ ] CI gate: `--coverage.thresholds` fails build automatically on drop

**Definition of Done:**
- `npx vitest run --coverage` generates `coverage/index.html`
- PR comment shows coverage delta for changed files

---

#### 6.3 Playwright HTML Report

**Tasks:**
- [ ] Configure `playwright.config.ts`:
  ```ts
  reporter: [
    ["html", { outputFolder: "playwright-report", open: "never" }],
    ["junit", { outputFile: "playwright-results.xml" }],
    ["list"],
  ]
  ```
- [ ] Upload `playwright-report/` as CI artifact (retain 14 days)
- [ ] Upload `playwright-results.xml` to CI test results panel (GitHub Actions: `dorny/test-reporter`)
- [ ] Retry flaky tests: `retries: 2` in CI, `retries: 0` locally
- [ ] Failed test: capture screenshot + video (already Playwright default with `trace: "on-first-retry"`)
- [ ] Slack/notification: post test summary (pass/fail count) to dev channel after E2E run

**Tasks (Playwright config additions):**
- [ ] `use.trace: "on-first-retry"` — trace on first retry
- [ ] `use.screenshot: "only-on-failure"` — auto screenshot on failure
- [ ] `use.video: "retain-on-failure"` — keep video only for failed tests
- [ ] Attach test IDs to each test (`test.info().annotations.push(...)`) for ClickUp linkage

**Definition of Done:**
- CI shows per-test pass/fail with screenshot link on failure
- `playwright-report/index.html` renders trace viewer for failed tests

---

#### 6.4 Unified Dashboard (Optional — Phase 6 stretch)

**Tasks:**
- [ ] Consolidate Go coverage + TS coverage + Playwright results into single CI summary step
- [ ] Write summary to `$GITHUB_STEP_SUMMARY`:
  ```
  | Layer          | Coverage | Status |
  |----------------|----------|--------|
  | Go services    | 84%      | ✅ pass |
  | TS lib/stores  | 81%      | ✅ pass |
  | E2E (Chromium) | 13/13    | ✅ pass |
  | E2E (Firefox)  | 5/5      | ✅ pass |
  ```

**Definition of Done:**
- GitHub Actions job summary shows unified table on every test run

---

### CHAT-060 · Visual Regression — Baseline Capture

**Layer:** zyra-app  
**Effort:** M  
**Depends on:** CHAT-014, CHAT-015, CHAT-021, CHAT-026, CHAT-033, CHAT-041, CHAT-046, CHAT-051  
**Scenarios:** all (UI components)

> Tool: **Playwright** built-in `toHaveScreenshot()` — no extra dependency needed.  
> Baseline screenshots stored in `e2e/snapshots/` and committed to repo.

**Components to Snapshot (baseline set):**

| Component | States to Capture |
|---|---|
| `chat-sidebar` | default, unread badge, active conversation |
| `message-item` | text only, with image, with file card, deleted, edited, with reactions, thread count |
| `message-input` | empty, text typed, with 1 attachment, with error |
| `dm-panel` | empty state, messages loaded, unread banner |
| `channel-panel` | with pinned banner, without |
| `thread-panel` | open state with 3 replies |
| `emoji-picker` | closed (hover bar), open full picker |
| `typing-indicator` | 1 user, 2 users, 4+ users |
| `notification-bell` | 0 unread, 5 unread, 99+ unread, panel open |
| `search-panel` | empty, results list, no results |
| `proximity-panel` | auto-opened, 3 members |
| `file-preview` | lightbox open (image) |

**Tasks:**
- [ ] Create `e2e/visual/chat-components.spec.ts`
- [ ] For each component state: render in isolation (mock store data) → `expect(page).toHaveScreenshot('name.png', { maxDiffPixels: 10 })`
- [ ] Run on Chromium only for baseline (cross-browser visual run is optional stretch)
- [ ] Commit all generated `.png` baseline files to `e2e/snapshots/`
- [ ] Add `e2e/snapshots/` to `.gitattributes` as binary (no line-ending transforms)

**Definition of Done:**
- All 30+ baseline screenshots exist in `e2e/snapshots/`
- First run with `--update-snapshots` passes with zero diff
- PR description updated: "VR baselines committed for Chat module"

---

### CHAT-061 · Visual Regression — CI Gate + Diff Report

**Layer:** zyra-app + CI  
**Effort:** M  
**Depends on:** CHAT-060  
**Scenarios:** all (UI regressions)

**Tasks:**

#### Playwright VR in CI
- [ ] Add VR test job to CI (separate from functional E2E to keep clear separation):
  ```yaml
  visual-regression:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npx playwright install chromium
      - run: npx playwright test e2e/visual/ --project=chromium
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: vr-diff-report
          path: |
            playwright-report/
            test-results/**/*-diff.png
            test-results/**/*-actual.png
          retention-days: 7
  ```
- [ ] On VR failure: CI uploads 3-way diff images (expected / actual / diff)
- [ ] Diff threshold: `maxDiffPixels: 10` (tight — pixel-perfect per Figma rule)
- [ ] Per-component `maxDiffPixels` override for animated components (typing dots): `maxDiffPixels: 50`

#### Snapshot Update Workflow
- [ ] Add manual trigger job `update-snapshots`:
  ```yaml
  on:
    workflow_dispatch:
      inputs:
        component:
          description: "Component to update (e.g. 'typing-indicator' or 'all')"
  ```
  Runs `npx playwright test e2e/visual/ --update-snapshots` → commits updated PNGs
- [ ] Protect: only runs on non-main branches (prevents accidental baseline overwrite on main)

#### PR Check Integration
- [ ] Annotate PR with VR diff images when failures occur (use `github-script` to post comment with artifact links)
- [ ] VR job is **non-blocking** (warning only) during Phase 1–4; becomes **blocking gate** from Phase 5 onward when all baselines are stable

**Definition of Done:**
- VR job runs on every PR targeting `main`
- Failed VR: artifact with 3-way diff images uploaded, PR comment posted
- `update-snapshots` workflow dispatched manually, commits PNG updates cleanly

---

### CHAT-062 · Storybook Stories (Optional — Visual Dev Aid)

**Layer:** zyra-app  
**Effort:** L  
**Depends on:** CHAT-012, CHAT-013, CHAT-026, CHAT-033, CHAT-041, CHAT-054  
**Scenarios:** all (component development)

> Not strictly required for VR but dramatically speeds up visual development and diff reviews.

**Tasks:**
- [ ] Set up Storybook (if not already present): `npx storybook@latest init`
- [ ] Story: `message-item.stories.tsx` — 8 variants (text, attachment, deleted, edited, reactions, thread, pinned, optimistic-sending)
- [ ] Story: `message-input.stories.tsx` — empty, with attachment, with error, typing
- [ ] Story: `emoji-picker.stories.tsx` — quick bar, full picker
- [ ] Story: `typing-indicator.stories.tsx` — 0/1/2/4 users
- [ ] Story: `notification-bell.stories.tsx` — 0/5/99+ unread, panel open
- [ ] Story: `file-preview.stories.tsx` — image lightbox, infected file card
- [ ] Connect Storybook VR: `@storybook/addon-storyshots-playwright` → auto-snapshot all stories

**Definition of Done:**
- `npx storybook build` passes
- All 8 message-item variants render without console errors

---

## Open Questions (Block Before Implementation)

| # | Question | Blocks | Owner |
|---|---|---|---|
| OQ-1 | File size limit: 25 MB recommended — confirm? | CHAT-029, CHAT-031 | PM |
| OQ-2 | Virus scan provider: ClamAV self-hosted vs VirusTotal API | CHAT-035 | DevOps |
| OQ-3 | Email digest HTML template — provide design | CHAT-048 | Designer |
| OQ-4 | Proximity radius: 200 map units — confirm with VO map scale | CHAT-049 | PM |
| OQ-5 | @mention autocomplete scope: workspace members or channel members only? | CHAT-038 | PM |
| OQ-6 | Message edit history: store revisions or just `is_edited` flag? | CHAT-001 (schema) | Tech lead |
