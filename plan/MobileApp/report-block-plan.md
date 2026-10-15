# Report & Block — แผนงาน (store compliance)

> **สถานะ:** PR เปิดแล้ว รอ review — [zyra-api#168](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/168) · [zyra-app#599](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/599) · unit test ผ่าน · ยังไม่ได้เทสบน dev (ดู progress.md) · มติ Ten ข้อ 8 · **วันที่:** 2026-10-15 · **repo:** zyra-api, zyra-app (zyra-ws ไม่แตะ)
> **ที่มา:** compliance audit 2026-10-15 ข้อ #2 — Apple Guideline 1.2 (User-Generated Content) + Google Play UGC policy บังคับให้แอปที่มี chat ระหว่างผู้ใช้ต้องมี (1) วิธี report เนื้อหา (2) block ผู้ใช้ (3) ทีมตอบสนอง report ได้ทันเวลา · ตอนนี้ zyra-app / zyra-api ไม่มีทั้งสองอย่าง
> **ไม่มี Figma:** UI ใช้ pattern จาก [prototype.html](../../web/mobile-ui-proposals/prototype.html) (`SH.memberAct`, `SH.memberProfile`, `msgMenuHTML`) — prototype ไม่มี mockup ของ report / block โดยตรง

## 1. Report ปรากฏที่ไหน

| จุด | Web | Mobile Lite | Mobile Spatial | ไฟล์ |
|---|---|---|---|---|
| เมนูข้อความ (ไม่ใช่ข้อความของตัวเอง) | More ใน hover bar | long-press | long-press | `views/chat/components/message-context-menu.tsx` (ใช้ร่วมทุก mode) — เพิ่ม **Report message** ใต้เส้นคั่นข้าง Delete |
| โปรไฟล์คนอื่นใน VO | popover คลิกตัวละคร | `LiteMemberProfileSheet` | `PlayerContextMenu` (bottom sheet) | `lite-home-sheets.tsx`, `player-context-menu.tsx` — เพิ่ม **Report** + **Block / Unblock** แถวสีแดงท้ายรายการ |
| สมาชิกใน chat | `conversation-info-panel.tsx` เมนู ⋯ ต่อคน | `mobile-chat-info.tsx` → `MemberActionsSheet` | เหมือน Lite | เพิ่ม **Report** + **Block / Unblock** |
| header ของ DM | `conversation-menu.tsx` (More) | `mobile-chat-info.tsx` (หน้า info ของ DM) | เหมือน Lite | เพิ่ม **Report** + **Block / Unblock** |

**Report sheet / dialog** (mobile = `BottomSheet`, web = modal Tailwind):
- เลือกเหตุผล 1 ข้อ: Spam (สแปม) · Harassment or bullying (คุกคาม/กลั่นแกล้ง) · Hate speech (ถ้อยคำสร้างความเกลียดชัง) · Sexual content (เนื้อหาทางเพศ) · Violence or threats (ความรุนแรง/ข่มขู่) · Other (อื่น ๆ)
- รายละเอียดเพิ่มเติม (ไม่บังคับ, ≤ 1000 ตัวอักษร)
- toggle **Also block this user** (บล็อกผู้ใช้นี้ด้วย) — ปิดเป็นค่าเริ่มต้น
- ส่งแล้ว toast "Thanks — our team will review this report." (ขอบคุณ ทีมงานจะตรวจสอบรายงานนี้)

## 2. Block ทำอะไร (A บล็อก B)

**ขอบเขต:** ระดับบัญชี — บล็อกครั้งเดียวมีผลทุก workspace ที่ทั้งคู่อยู่ (ดูคำถาม Q1)

| สิ่งที่ A เห็น / ได้รับ | ผล |
|---|---|
| ข้อความของ B ใน channel / group / thread / pinned / search | ซ่อน (server ไม่ส่งกลับ + client กรอง realtime) |
| DM กับ B | ซ่อนจากรายการ conversation · A เปิด DM ใหม่กับ B ไม่ได้ |
| unread count / bell notification / chat digest email / push จากข้อความของ B | ไม่นับ ไม่ส่ง |
| B ส่ง DM หา A | ถูกปฏิเสธ 403 "You can't message this user." (ไม่สามารถส่งข้อความถึงผู้ใช้นี้ได้) — B ส่งใน channel / group ได้ตามปกติ แต่ A ไม่เห็น |
| Unblock | Settings → **Blocked users** (ผู้ใช้ที่บล็อกไว้) + ปุ่มเดียวกันในโปรไฟล์ |

**ไม่อยู่ใน scope v1** (เสนอทำทีหลังถ้าต้องการ): ซ่อนตัวละคร / เสียง / วิดีโอของ B ใน VO, กัน Wave จาก B, block ใน meeting chat ชั่วคราว (ephemeral) — store ไม่ได้บังคับระดับนี้

**Realtime:** zyra-ws ส่ง `chat:message:new` ให้สมาชิกทุกคนเหมือนเดิม — client กรองที่ `lib/api/chat-ws.ts` ด้วยรายชื่อที่โหลดจาก `GET /api/user/blocks` (เก็บใน store) → ไม่ต้องแก้ zyra-ws

## 3. Report ไปไหน

1. **DB** `tb_content_report` — เก็บ snapshot ข้อความ ณ เวลาที่ report (ผู้ส่งลบ/แก้ทีหลังหลักฐานยังอยู่)
2. **Discord alert** + **email ไป `SUPPORT_EMAIL`** — reuse ช่องทางเดียวกับ support ticket (`discord.Client`, `notify.Client`) · email ใช้ template `support_ticket_new` เดิม (contact type "Content report") → ไม่ต้องแก้ zyra-notifications → ทีมรู้ทันที (Apple ต้องการ "timely response")
3. ~~**Admin page** `/admin/reports`~~ — **เลื่อนไปรอบหลัง (มติ Q2)** · v1 ทีมจัดการผ่าน Discord / email + ban ที่มีอยู่ — list (filter status) · ดูรายละเอียด + ข้อความ snapshot · ปุ่ม **Remove message** (soft delete + broadcast delete เหมือน user ลบเอง) · **Dismiss** / **Mark actioned** · ลิงก์ไปหน้า customer เพื่อ ban (มี `admin.customer.ban` อยู่แล้ว)
   - สิทธิ์: reuse `admin.support.read` (ดู) / `admin.support.reply` (จัดการ) — ไม่เพิ่ม permission ใหม่

## 4. API contract

ทุก route ใช้ `model.APIResponse` · user routes อยู่ใต้ `/api/user/*` (UserGuard) · admin อยู่ใต้ `/api/admin/*`

### User
| Method | Path | Request | Response `data` | Error |
|---|---|---|---|---|
| POST | `/api/user/reports` | `{ "target_type": "message"\|"user", "message_id"?: uuid, "reported_user_id": string, "workspace_id": uuid, "reason": "spam"\|"harassment"\|"hate"\|"sexual"\|"violence"\|"other", "details"?: string, "also_block"?: bool }` | `{ "id": uuid }` | 400 validation · 400 report ตัวเอง · 403 ไม่ใช่สมาชิก conversation / workspace · 404 ไม่พบข้อความ · 429 เกิน 20 report / ชม. · report ซ้ำ (reporter + message เดิม) = 200 คืน id เดิม |
| GET | `/api/user/blocks` | — | `[{ "user_id", "name", "image_upload", "blocked_at" }]` | — |
| POST | `/api/user/blocks` | `{ "user_id": string }` | `{ "user_id", "blocked_at" }` | 400 บล็อกตัวเอง · 404 ไม่พบ user · บล็อกซ้ำ = 200 |
| DELETE | `/api/user/blocks/:userId` | — | — | ไม่เคยบล็อก = 200 (idempotent) |

### Admin (เลื่อนไปรอบหลัง — มติ Q2)
| Method | Path | หมายเหตุ |
|---|---|---|
| GET | `/api/admin/reports?status=open&page=1&page_size=20` | list + total |
| GET | `/api/admin/reports/:id` | detail (reporter, reported user, snapshot, workspace, conversation) |
| PATCH | `/api/admin/reports/:id` | `{ "status": "open"\|"actioned"\|"dismissed", "admin_note"?: string }` |
| POST | `/api/admin/reports/:id/remove-message` | soft delete ข้อความ + broadcast `chat:message:deleted` · ตั้ง status = `actioned` |

### เปลี่ยนพฤติกรรม endpoint chat เดิม
`ListConversations`, `ListMessages`, `ListThreads`, `ListWorkspaceThreads`, `ListThreadReplies`, `ListPinned`, chat search, `GetUnreadCounts`, `CreateDM` (A → B = 403 `ErrUserBlocked`), `SendMessage` ใน DM (ฝั่งใดบล็อก = 403), `NotificationService.CreateForMessage` + chat digest (ข้ามผู้รับที่บล็อกผู้ส่ง)

## 5. Migration — `113_report_block.sql` (+ `.down.sql`)

> เลข 113 = ถัดจาก 112 บน develop ตอนนี้ — ถ้ามี branch อื่นใช้ 113 ก่อน merge ให้เลื่อนเลข

```sql
-- 113_report_block.sql
CREATE TABLE IF NOT EXISTS tb_user_block (
    blocker_id  VARCHAR        NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
    blocked_id  VARCHAR        NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id),
    CHECK (blocker_id <> blocked_id)
);
CREATE INDEX IF NOT EXISTS idx_user_block_blocked ON tb_user_block (blocked_id);

CREATE TABLE IF NOT EXISTS tb_content_report (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id       VARCHAR        NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
    reported_user_id  VARCHAR        NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
    workspace_id      UUID        REFERENCES tb_workspace(id) ON DELETE SET NULL,
    target_type       TEXT        NOT NULL CHECK (target_type IN ('message', 'user')),
    message_id        UUID        REFERENCES tb_message(id) ON DELETE SET NULL,
    conversation_id   UUID        REFERENCES tb_conversation(id) ON DELETE SET NULL,
    content_snapshot  TEXT,
    reason            TEXT        NOT NULL CHECK (reason IN ('spam','harassment','hate','sexual','violence','other')),
    details           TEXT,
    status            TEXT        NOT NULL DEFAULT 'open' CHECK (status IN ('open','actioned','dismissed')),
    admin_note        TEXT,
    handled_by        VARCHAR        REFERENCES tb_user(id) ON DELETE SET NULL,
    handled_at        TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_content_report_status_created ON tb_content_report (status, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_content_report_reporter_message
    ON tb_content_report (reporter_id, message_id) WHERE message_id IS NOT NULL;
```

```sql
-- 113_report_block.down.sql
DROP TABLE IF EXISTS tb_content_report;
DROP TABLE IF EXISTS tb_user_block;
```

(`tb_user.id` เป็น `VARCHAR` · `tb_workspace` / `tb_conversation` / `tb_message` เป็น `UUID` — เช็คกับ migration จริงแล้ว)

## 6. แบ่ง PR

| # | Repo | Branch (จาก `develop`) | เนื้อหา |
|---|---|---|---|
| 1 | zyra-api | `feat/report-block` | migration · `BlockService` + `ReportService` (handler → service) · กรอง block ใน chat / notification · table-driven tests (testify, mock DB ผ่าน interface ตามที่ service อื่นทำ) |
| 2 | zyra-app | `feat/report-block` | `lib/api/moderation.ts` · block list ใน store + กรอง realtime · Report sheet / dialog · เมนูทุกจุดในข้อ 1 · Settings → Blocked users · i18n en + th · vitest |
| 3 | zyra-doc | — | อัปเดต audit #2 + progress.md + review notes สำหรับ App Store / Play Console |

## 7. ทดสอบ / วัดผล
- unit: Go table-driven (validate reason / target, self-report, self-block, dedupe, rate limit, filter query) · vitest (API client, store filter, menu ซ่อน Report ในข้อความตัวเอง)
- manual บน dev: 2 บัญชี — report ข้อความ → เห็นใน DB + Discord + email · block → ข้อความเก่า / ใหม่ / DM หาย · unblock → กลับมา · ทั้ง web, Lite, Spatial
- **Before / After:** before = report 0 ช่องทาง / block 0 (นับจากโค้ด) · after = จำนวน row ใน `tb_content_report` / `tb_user_block` บน dev หลัง test — ไม่มี metric production ที่เกี่ยว (ฟีเจอร์ใหม่)

## 8. มติ Ten (2026-10-15)

- **Q1 →** ระดับบัญชี (ทุก workspace)
- **Q2 →** DB + Discord + email ก่อน · admin page / admin API ทำรอบหลัง
- **Q3 →** ใช้ style prototype ได้เลย
- **Q4 →** chat + DM พอ (ไม่ซ่อนใน VO)

### คำถามเดิม
- **Q1** Block ระดับบัญชี (ทุก workspace) — แนะนำ · หรือแยกต่อ workspace ตามที่ brief เขียน
- **Q2** Report ไป DB + Discord + email + admin page `/admin/reports` (แนะนำ, reviewer ถามได้ว่าทีมจัดการ report ยังไง) · หรือแค่ DB + Discord + email ก่อน (เร็วกว่า ~1 วัน, admin page ทำทีหลัง)
- **Q3** UI ไม่มี Figma — ใช้ style ของ prototype (sheet / แถวสีแดง) ได้เลย หรือรอ design
- **Q4** Scope v1 ไม่รวมการซ่อนตัวละคร / เสียงของคนที่บล็อกใน VO — โอเคไหม
