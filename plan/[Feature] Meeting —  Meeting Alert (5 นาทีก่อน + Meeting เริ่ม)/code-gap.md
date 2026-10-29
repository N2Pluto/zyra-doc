# Gap analysis — SC-MTG-CAL-03 Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)

> **สถานะ:** read-only code gap analysis · 2026-10-27 · ไม่ได้แก้ repo/doc ใด ๆ
> **Code ที่ตรวจ:** `origin/develop` 2026-10-27 — zyra-app `22fc0d6d`, zyra-api `aaf5d7c`, zyra-ws `1ec265f`, zyra-notifications `20eab8f` (path repo-relative + line number ตาม commit นี้) · ยังไม่ได้รัน test
> **ใช้คู่กับ:** [spec.md](spec.md) · [ux-ui-plan.md](ux-ui-plan.md) · จุดที่ทับกับ Calendar Display ดู [spec.md §8](spec.md#8-จุดที่ทับกับ-calendar-display-sc-mtg-cal-02)
> **Requirement:** `zyra-doc/plan/[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/spec.md` + `ux-ui-plan.md` · context CAL-01 = `zyra-doc/plan/MeetingCalendarIntegration/progress.md`
> **zyra-infra:** อ่านจาก live checkout ซึ่งเก่า (commit `32b45f8`, 2026-09-24) — replicas อาจไม่ตรงกับ origin ปัจจุบัน (**ยังไม่ได้ตรวจกับ origin**)

Legend: ✅ exists · 🟡 partial / reusable but needs work · ❌ missing · ⚠️ conflicts with existing code/rule

---

## 0. TL;DR (สรุปสั้น)

- **ระบบ notification มีครบเกือบทั้ง pipeline แล้ว** — ตาราง `tb_notification` + `/api/user/notifications` (UserGuard ✅ rule 15) + Redis `vo:notify` → zyra-ws `chat:notification:new` → bell panel (View all / Unread, Today / Yesterday, Mark all read) + badge ใน sidebar · มี pattern "bell row ที่มี Join + สถานะ ended" อยู่แล้วจาก Spotlight (`spotlight_live`) ที่เกือบเหมือน meeting alert
- **สิ่งที่ไม่มีเลย:** scheduler ของ meeting, notification type สำหรับ meeting, ตาราง dedupe, meeting status (cancel/reschedule ใน Zyra), RSVP, toast meeting (มี component แต่ยังไม่มี variant เทา/ส้ม + body 2 บรรทัด), "missed meetings" bundle on reconnect, การเปิด Calendar ไปที่ event/วันที่กำหนด
- **ชนกันที่สำคัญ:** ชื่อตาราง/สถานะใน ClickUp (`notifications`, `status = pending`) ≠ ของจริง (`tb_notification`, `is_read`, ไม่มี status) · type CHECK constraint ต้องแก้ใน `postgres.go` (เคยทำ dev boot ไม่ขึ้นมาแล้ว) · setting "Event reminders" บอก **10 นาที** แต่ ClickUp = 5 นาที และ setting ยังไม่ถูก enforce ที่ไหนเลย · digest email จะส่ง meeting row ทางอีเมลถ้าไม่ตั้ง `email_suppressed = true` (ขัด "in-app เท่านั้น") · cancel/reschedule ใน Zyra เกิดได้ทางเดียวคือ Google inbound sync แบบ lazy (ตอนมีคนเปิด Calendar) และ cancel = **hard delete**

---

## A. AC status table

### A.1 Business rules (spec §5)

| Rule | สถานะ | Evidence / หมายเหตุ |
|---|---|---|
| Cron ทุก 1 นาที ตรวจ `start_at BETWEEN now AND now+5m` | ❌ | ไม่มี loop ของ meeting ใน `zyra-api/main.go:486-536` (12 loops: purge, presence cleanup ×2, section cleanup, environment ×2, attachment scan, digest, announcement lifecycle, pet reminder, avatar part ×2) · zyra-ws / zyra-notifications ไม่มี scheduler ที่เกี่ยว (zyra-notifications = stateless email/FCM relay, `zyra-notifications/README.md` "ไม่มี DB") · โครง loop ใช้ต่อได้ (ดู B) |
| Start alert `start_at BETWEEN now-1m AND now` | ❌ | เหมือนข้างบน · index ที่มีใช้ได้: `idx_calendar_meeting_workspace_start (workspace_id, start_at)` `zyra-api/internal/database/postgres.go:1176-1177` — แต่ scan ข้ามทุก workspace ด้วย `start_at` อย่างเดียว ควรมี index `(start_at)` เพิ่ม (suggestion) |
| Dedupe `meeting_alert_log (meeting_id, user_id, alert_type)` UNIQUE | ❌ | ไม่มีตาราง · pattern ที่ใช้ต่อได้: partial UNIQUE + `ON CONFLICT … DO NOTHING` ของ weather `zyra-api/migrations/100_notification_weather_alert.sql:25-27` + `zyra-api/internal/service/notification_weather.go:53-55,75-77`; atomic claim `UPDATE … WHERE notified_at IS NULL RETURNING` ของ announcement `zyra-api/internal/service/announcement_service.go:884-913` |
| Offline → `notifications` table `status = pending` | ⚠️ 🟡 | ตารางจริงชื่อ **`tb_notification`** (`zyra-api/migrations/52_create_chat_tables.sql:122-134`) ไม่มีคอลัมน์ `status` — มีแค่ `is_read` (+ `email_suppressed`, `email_digest_sent_at`) · การ "deliver on reconnect" เกิดเองอยู่แล้ว: row อยู่ใน DB, client `listNotifications` ตอน mount (`zyra-app/hooks/use-chat-wiring.ts:68-91,95-112`) · แต่ไม่มี marker "toast แสดงแล้ว/ยัง" สำหรับ EP-01 bundle toast |

### A.2 MA-HP-01 · Alert 5 นาทีก่อน

| AC | สถานะ | Evidence |
|---|---|---|
| HP01-1 ส่งทุก invited participant ≤30 วิ ก่อนครบ 5 นาที | ❌ | ไม่มี scheduler · ผู้รับหาได้จาก `tb_calendar_meeting.organizer_id` + `tb_calendar_meeting_guest` (`postgres.go:1150-1182`) · ⚠️ tick 1 นาทีให้ granularity 60 วิ — ตอบ "≤30 วิ" ไม่ได้ถ้า tick = 60s (ต้อง tick ถี่กว่า เช่น 15–30s แบบ announcement 5s `zyra-api/main.go:579`) |
| HP01-2 toast มุมขวาบน ค้าง 3 นาทีแล้วหายเอง | 🟡 | `zyraToast.*WithTitle(…, { layout: "figma", duration })` `zyra-app/lib/toast.tsx:12-15,64-72,103-156,193-221` = card 336 / icon box 40 / title bold / X / action row — ตรงโครง Figma §2 · Toaster global `position="top-right"` offset 24 (`zyra-app/app/layout.tsx:233-237`, `zyra-app/lib/safe-area.ts:16-21`) = ตรง Figma top 24/right 24 · `duration: 180000` ทำได้ · ขาด: body 2 บรรทัด (message เป็น `<p>` เดียว ไม่มี `whitespace-pre-line`) |
| HP01-3 กด → Calendar View + event detail popup | ❌ | `VOCalendar` ไม่มี prop เปิดไปวันที่/โหมด/event ที่กำหนด (`zyra-app/views/user/virtual-office/components/calendar/vo-calendar.tsx:93-117`; state ภายใน `mode="month"`, `detailsId` `:127-133`) · Figma ต้องการ **Week** view · Calendar เปิดได้เฉพาะเมื่อ `GOOGLE_CALENDAR_ENABLED` (`hero-virtual-office.tsx:4922-4935`) — ปิดอยู่ = toast "coming soon" |
| HP01-4 bell badge +1 | 🟡 | badge มี (`vo-sidebar.tsx:248,273-276`) source = `useChatStore.notificationUnread` = นับ `!is_read` จาก **30 row ที่โหลด** (`stores/chat-store.ts:168-170,516-531`) — ไม่ใช้ `unread_count` ที่ API ส่งมา (`notification_handler.go:75-80`) · realtime +1 ผ่าน `prependNotification` เมื่อ `chat:notification:new` มาถึง (`lib/api/chat-ws.ts:190-196`) ✅ ใช้ต่อได้ |
| HP01-5 ส่ง 1 ครั้ง/meeting/user | ❌ | ต้องมี dedupe (A.1) |
| HP01-6 offline → เก็บไว้แสดงเมื่อกลับมา | 🟡 | row ค้างใน DB + fetch ตอน mount ✅ · toast ตอนกลับมา ❌ (ไม่มี logic "แสดง toast ของ row ที่สร้างตอน offline") |

### A.3 MA-HP-02 · Alert ตอน Meeting เริ่ม

| AC | สถานะ | Evidence |
|---|---|---|
| HP02-1 ภายใน 1 นาทีหลัง start | ❌ | ไม่มี scheduler |
| HP02-2 ปุ่ม Join Now สีเขียว | 🟡 | toast action `primary` = `bg-[#58D68D]` + `secondary` = ขาว (`lib/toast.tsx:74-82`) ตรง Figma "Join meeting" + "Later" · ไม่มี meeting toast จริง |
| HP02-3 Join → VO room โดยตรง | 🟡 ✅ | `joinCalendarMeeting(url)` → `openMeetingLink` เดิน avatar ไป zone (+ข้ามชั้นผ่าน `/loading?zone_id=`) + `setInviteZoneId` ข้าม knock (`hero-virtual-office.tsx:12636-12691`) · join URL = `/workspace/{ws}/play?zone_id={zone}` (`zyra-api/internal/service/calendar_meeting_service.go:263-270`) · ⚠️ `zone_id` ว่าง ("Any available meeting room") = แค่ปิด calendar ไม่ไปห้องไหน · ⚠️ เป็นการ**เดิน** ไม่ใช่ teleport (Figma ไม่ชัด) · ใช้ได้เฉพาะเมื่อ user อยู่ใน VO ของ workspace นั้น |
| HP02-4 "มี 3 คนรออยู่" | 🟡 | client: `zoneSections` → `meetingRoomOccupancy` (`hero-virtual-office.tsx:12694-12697`) ส่งเข้า Calendar แล้ว · server: `tb_zone_section_member` (presence) `zyra-api/internal/service/zone_section_service.go:86,100,166-185` — query นับต่อ zone **ยังไม่ได้ตรวจ** predicate ที่ถูกต้อง · ⚠️ Figma ไม่มีจำนวนคน (ux §7 A3) |
| HP02-5 ค้าง 3 นาที | 🟡 | duration ตั้งได้ (ดู HP01-2) · ตัวเลขยังขัดกันใน spec §6 #1 |
| HP02-6 1 ครั้ง/meeting/user | ❌ | dedupe |

### A.4 MA-HP-03 · Notification History

| AC | สถานะ | Evidence |
|---|---|---|
| (base) bell → panel ใหม่→เก่า | ✅ | `VONotificationPanel` (`zyra-app/views/user/virtual-office/components/vo-notification-panel.tsx:124-449`) · API `GET /api/user/notifications?workspace_id=` `ORDER BY created_at DESC` (`zyra-api/internal/router/router.go:417-422`, `notification_service.go:886-951`) · sidebar order Map/Members/Chat/Calendar/**Bell**/Megaphone ตรง Figma (`vo-sidebar.tsx:77-82`) |
| Tabs View all / Unread · Today / Yesterday | ✅ | tabs `vo-notification-panel.tsx:400-420` (`viewAllTab`, `unreadTab`) · group `formatDayDivider` Today/Yesterday/วันที่ (`views/chat/components/chat-utils.ts:86-96`, panel `:235-250`) |
| HP03-1 ย้อนหลัง 7 วัน | 🟡 | ไม่มี filter วัน, ไม่มี retention purge (ไม่มี `DELETE FROM tb_notification` ใน service) · panel โหลดแค่ `NOTIF_PAGE = 30` ไม่มี load-more (`vo-notification-panel.tsx:73,155`) แม้ API รองรับ `before` |
| HP03-2 past greyed out | ❌ / ⚠️ | ไม่มี · analog: Spotlight card เปลี่ยน title/body เป็น "ended" และซ่อน Join (`vo-notification-panel.tsx:582-639`) · Figma ไม่ greyed (ux §7 A10) |
| HP03-3 Join ยังแสดงถ้า meeting ยังไม่จบ | ❌ (pattern 🟡) | ต้องรู้ `end_at` ของ meeting ใน row · analog `isSpotlightRowLive` (`:86-89`) |
| HP03-4 Mark all as read | ✅ ⚠️ | `POST /api/user/notifications/read-all` (`notification_handler.go:83-96`) + ปุ่ม (`vo-notification-panel.tsx:378-396`) · ⚠️ copy/style: code "Mark all read" สีเขียว `#58D68D` icon 14 vs Figma "Mark as read" `#8C99A6` 12 |
| HP03-5 badge = 0 เมื่อเปิด panel | 🟡 ⚠️ | badge แค่**ซ่อน**ตอน panel active (`vo-sidebar.tsx:248` `&& !isActive`) — เปิด panel ไม่ mark read · ปิด panel แล้ว badge กลับมา · ไม่มีแนวคิด "seen" แยกจาก "read" (spec §6 #10) |
| คลิก past item → Calendar วันนั้น | ❌ | ไม่มี branch meeting ใน `onItemClick` (`:187-233`) + ไม่มี entry point เปิด Calendar ที่วันที่กำหนด |

### A.5 MA-HP-04 · Dismiss

| AC | สถานะ | Evidence |
|---|---|---|
| HP04-1 X → toast หายทันที | ✅ | X ใน figma layout `toast.dismiss(id)` (`lib/toast.tsx:126-133`) |
| HP04-2 ยังอยู่ใน history | ✅ (โดยโครงสร้าง) | toast เป็น client-only, row ใน `tb_notification` ไม่ถูกแตะ |
| HP04-3 ไม่กระทบอันอื่น | ✅ | dismiss ตาม id ของ sonner |
| "Later" button (Figma) | ❌ | ไม่มีความหมายกำหนด (ux §7 A5) — ถ้า = ปิด toast ใช้ action `secondary` ได้เลย |

### A.6 MA-EP-01 · Offline

| AC | สถานะ | Evidence |
|---|---|---|
| EP01-1 เก็บใน DB status=pending | ⚠️ 🟡 | ไม่มี `status`; row ใน `tb_notification` ทำหน้าที่แทน · ⚠️ ต้อง insert `email_suppressed = true` ไม่งั้น digest email ส่ง (digest ไม่กรอง type: `notification_service.go:1010-1013,1080-1085`) |
| EP01-2 กลับมา online แสดงทันที | 🟡 | panel/badge ✅ ตอน mount · toast ❌ |
| EP01-3 bundle "You missed 3 meetings" | ❌ | ไม่มี logic · ต้องตัดสินว่า "missed" = row ไหน (unread + created ขณะ offline? หรือ meeting จบแล้ว?) · panel ยังเป็นการ์ดแยก (ตรง Figma ux §0 EP-01 #5) |
| นิยาม "online" | ⚠️ | API `IsOnline` = app-wide heartbeat (`workspace_presence_service.go:299-350`) แต่ realtime delivery = WS room ของ workspace นั้นเท่านั้น (`zyra-ws/internal/hub/hub.go:334-356` — ไม่อยู่ใน room = no-op) → คนที่ online ใน lobby / workspace อื่น จะไม่เห็น toast จนกว่าจะเข้า VO นั้น |

### A.7 MA-EP-02 · Cancel / reschedule หลังส่ง alert

| AC | สถานะ | Evidence |
|---|---|---|
| ต้นทาง: มี edit/cancel meeting ไหม | ❌ ⚠️ | Zyra **ไม่มี** API แก้/ยกเลิก meeting — route มีแค่ `GET/POST /:id/meetings`, `POST /:id/meetings/sync` (`router.go:290-295`); app มีแค่ create/list/sync (`zyra-app/lib/api/calendar-meetings.ts:86-125`) · การเปลี่ยนเกิดทางเดียว = **Google inbound reconcile** ตอน list (`zyra-api/internal/service/calendar_meeting_inbound.go:67-138`): แก้เวลา → `ApplyGoogleChange` UPDATE `start_at` (`calendar_meeting_store.go:206-249`), ลบ/cancel ใน Google → **hard DELETE** (`:251-256`) · reconcile ทำงานเฉพาะเมื่อมีคนเปิด Calendar (throttle 20 วิ/meeting, in-memory) → scheduler อาจยิง alert ให้ meeting ที่ถูกลบใน Google ไปแล้วแต่ยังไม่มีใครเปิด Calendar |
| ไม่มี meeting status column | ❌ | `tb_calendar_meeting` ไม่มี `status` / `cancelled_at` (`postgres.go:1150-1174`) · model ไม่มี (`zyra-api/internal/model/calendar_meeting.go:45-69`) |
| EP02-2 notification "ถูกเลื่อน/ยกเลิก" | ❌ | ไม่มี type · setting `event_changes` / `event_cancellations` มีแล้วแต่ไม่ถูกใช้ (ดู C) |
| EP02-3 Join บน noti เดิม → Calendar แทน | ❌ (pattern 🟡) | analog Spotlight: `EndSpotlightLive` UPDATE row + re-push ผ่าน `vo:notify` ให้การ์ดที่เปิดอยู่เปลี่ยนสถานะทันที (`notification_service.go:348-410`) · ⚠️ ถ้า meeting ถูก hard-delete row noti ต้องเก็บ snapshot title/เวลาเอง (FK ต้อง `ON DELETE SET NULL`) |

### A.8 MA-EP-03 · Duplicate / race

| AC | สถานะ | Evidence |
|---|---|---|
| EP03-1..3 idempotency server-side | ❌ (pattern ✅) | ไม่มีตาราง (spec ใช้ชื่อ 2 แบบ `meeting_alert_log` / `alert_sent_log`) · pattern พร้อมใช้: UNIQUE + `ON CONFLICT DO NOTHING RETURNING` (insert สำเร็จเท่านั้นถึง push) — กันได้ทั้ง tick ซ้ำ, 2 replica ระหว่าง rolling deploy, restart กลางทาง · Redis lock `AcquirePollerLock` (SetNX, fail-open) `zyra-api/internal/cache/environment.go:309-319` ใช้เป็น optimization ได้ แต่ห้ามพึ่งเป็นตัว dedupe เพราะ fail-open |
| replicas | 🟡 | api/ws `replicas: 1` ทุก env ใน `zyra-infra/gitops/envs/*/services/{api,ws}/values.yaml` (checkout เก่า 2026-09-24 — **ยังไม่ได้ตรวจกับ origin**) · rolling update อาจมี 2 pod ชั่วคราว → ต้องพึ่ง DB dedupe |

### A.9 Edge cases

| EC | สถานะ | Evidence / หมายเหตุ |
|---|---|---|
| EC-01 short notice (<5 นาที) | ❌ | ไม่มี validation ห้าม start ในอดีต/ใกล้ (`calendar_meeting_service.go:84-107`) → window query ต้องรับ meeting ที่สร้างหลัง window แล้ว (เช่น `start_at <= now+5m AND start_at > now` และยังไม่มี log) · copy "starts in 5 minutes" ผิดถ้าเหลือ 2 นาที (spec §6 #5) |
| EC-02 หลาย meeting ใกล้กัน ไม่ bundle | 🟡 | sonner stack ได้ (Toaster ไม่ได้ตั้ง `visibleToasts`/`expand` → default ของ sonner, **ยังไม่ได้ตรวจ** behavior จริงกับ toast 336px) · ⚠️ VO มี toast stack ของตัวเองอีกชุดที่มุมขวาบนเหมือนกัน (ดู C.6) |
| EC-03 timezone | ✅ (โดยโครงสร้าง) | `start_at TIMESTAMPTZ` absolute · display ฝั่ง client ใช้ local time (`lib/calendar/calendar-dates.ts:82-114`) · all-day meeting = `start_at` เที่ยงคืนของ `time_zone` (`calendar_meeting_service.go:87-88`) → ต้องตัดสินว่าจะ alert all-day ไหม (**ไม่มีใน spec**) |
| EC-04 อยู่ใน meeting อื่น | ✅ | ไม่มี suppression ใด ๆ สำหรับ notification type ใหม่ (`hide_chat_in_meeting` ใช้กับ chat เท่านั้น — `zyra-api/internal/model/auth.go:233-236`) |
| EC-05 ช้าได้ ≤2 นาที | 🟡 | ขึ้นกับ tick + `context.WithTimeout` per tick (pattern ใน `main.go:635-657`) |

### A.10 Notification settings gating (ไม่ได้อยู่ใน ClickUp แต่มีในโค้ด)

| สิ่งที่มี | สถานะ | Evidence |
|---|---|---|
| `event_reminders`, `event_start`, `event_changes`, `event_cancellations`, `event_invitations` (default ON) | 🟡 ⚠️ | struct `zyra-api/internal/model/auth.go:238-243`, default `:313-326`, API `GET/PATCH /api/user/me/notification-settings` (`router.go:183-184`) · UI desktop toggles (`vo-setting-modal.tsx:393-427`) · lite: section Calendar `hidden: true` (`lite/lite-notification-settings-page.tsx:55-66`) · **ไม่มี code ไหน enforce** (grep ทั้ง 4 repo เจอแค่ model/UI/test) · copy บอก **10 นาที** (`messages/en.json:65,1029`, `th.json:65,1029`) ⚠️ |

---

## B. Existing building blocks to reuse

| Building block | Path | ใช้ทำอะไร |
|---|---|---|
| `tb_notification` + workspace_id, title, body, actor_id, is_read, email_suppressed | `zyra-api/migrations/52_create_chat_tables.sql:122-134`, `56_…:6`, `58_…:43-55`, `71_…:9-18` | เก็บ meeting alert rows (workspace-scoped, title/body snapshot) |
| Superset type CHECK (บูตทุกครั้ง) | `zyra-api/internal/database/postgres.go:356-381` | **ต้อง**เพิ่ม type ใหม่ที่นี่ในรอบเดียวกัน |
| Auto-migrate slice (GitOps รันเฉพาะอันนี้) | `postgres.go:17` (`var migrations`), meeting tables `:1148-1183` | ใส่ DDL ใหม่ (migration ถัดไป = **122**; ล่าสุดในโฟลเดอร์ = 121) |
| `NotificationService` + `notificationPusher` + `presenceChecker` | `zyra-api/internal/service/notification_service.go:42-91` | สร้าง row + push realtime + เช็ค online |
| Spotlight live/ended pattern (insert-if-not-exists per recipient, push, UPDATE ended + re-push) | `notification_service.go:268-410`, model `zyra-api/internal/model/chat.go:247-277`, migration `98_notification_spotlight.sql` | แม่แบบที่ใกล้ที่สุดของ meeting started → ended/cancelled |
| Weather alert unique-per-user insert | `migrations/100_notification_weather_alert.sql:25-27`, `service/notification_weather.go:53-77` | แม่แบบ UNIQUE + `ON CONFLICT DO NOTHING` |
| Announcement deferred notify sweep (atomic claim) | `announcement_service.go:884-913`, loop `main.go:670-697`, interval 5s `main.go:579` | แม่แบบ "เวลาถึงแล้วค่อยยิง" + tick ถี่ |
| Pet reminder + settings gate ใน SQL | `notification_pet.go:215-253` (`COALESCE(u.notification_settings->>'pet_activity','true') <> 'false'`) | gate `event_reminders` / `event_start` ฝั่ง SQL |
| Redis poller lock | `zyra-api/internal/cache/environment.go:309-319`, ใช้ที่ `main.go:744-760` | (optional) เลือก 1 replica ต่อ tick |
| Redis `vo:notify` publisher | `zyra-api/internal/cache/notification.go:14,67-84` | push row ไป zyra-ws |
| zyra-ws relay → `chat:notification:new` (unicast ใน room ของ workspace) | `zyra-ws/main.go:87-113`, `zyra-ws/internal/hub/hub.go:334-356`, `message.go:185-193,1159-1163` | ไม่ต้องเพิ่ม WS event ใหม่ |
| Client WS handler → store | `zyra-app/lib/api/chat-ws.ts:190-200`, `stores/chat-store.ts:516-552` | badge/panel realtime |
| Per-type toast hook จาก `chat:notification:new` | `hero-virtual-office.tsx:3883-3897` (zone_force_unclaimed, announcement) | จุดใส่ handler meeting toast |
| `NotificationType` union + `Notification` interface | `zyra-app/lib/api/chat.ts:128-187` | เพิ่ม type/field |
| Notification panel + Spotlight card (Join pill + ended state) | `vo-notification-panel.tsx:124-449, 582-639`, `TYPE_META :455-467` | การ์ด meeting (ควรเป็น card แยกแบบ Spotlight) |
| `zyraToast` figma layout (title, body, icon override, actions, duration, iconBoxAlpha) | `zyra-app/lib/toast.tsx:56-221` | meeting toast — `info` (ฟ้า) / `success` (เขียว) ตรง Figma, `icon={Video}` |
| Toaster top-right 24/24 | `app/layout.tsx:233-237`, `lib/safe-area.ts:16-21` | ตำแหน่งตรง Figma แล้ว |
| Sidebar bell + badge | `vo-sidebar.tsx:77-82,248,273-276` | badge count |
| Join flow | `hero-virtual-office.tsx:12636-12691` (`openMeetingLink`, `joinCalendarMeeting`), deep link `:4568-4597` | "Join meeting" / "Join" |
| Room occupancy | `hero-virtual-office.tsx:12694-12697`; server `zone_section_service.go` | "มี N คนรออยู่" |
| Meeting data + recipients | `postgres.go:1150-1182`, store `calendar_meeting_store.go:325-334` (`ListForUser` organizer OR guest) | query ผู้รับ |
| Join URL builder | `calendar_meeting_service.go:263-270` | ใส่ใน row/payload |
| Presence (API) | `workspace_presence_service.go:299-350` (`IsOnline`, `IsOnlineIn`) | ตัดสิน online/offline ตอนสร้าง row |
| Notification settings (calendar keys) | `model/auth.go:238-243,313-326`; app `lib/api/profile.ts:392-410` | gating |

---

## C. Overlaps / conflicts

| # | เรื่อง | ClickUp / Figma | โค้ดจริง | ผลกระทบ |
|---|---|---|---|---|
| C.1 | ชื่อตาราง + สถานะ | `notifications` table, `status = pending` | `tb_notification`, ไม่มี `status` — มี `is_read` + `email_suppressed` | ไม่ควรเพิ่ม `status` ทั่วตาราง; "pending" = row ที่ยังไม่ถูกแสดงเป็น toast (ถ้าจำเป็นค่อยเพิ่ม `toast_shown_at`/`delivered_at` เฉพาะ meeting) |
| C.2 | Type CHECK constraint | type ใหม่ (5min / started / cancelled / rescheduled) | superset CHECK ถูก DROP/ADD ทุก boot (`postgres.go:356-381`) — เคยพังมาแล้ว 3 ครั้ง (`spotlight_live`, `weather_alert`, pet_*) | ต้องเพิ่ม type ใน `postgres.go` + migration ในรอบเดียวกัน ไม่งั้น insert ล้มเงียบ (best-effort) หรือ API boot ไม่ขึ้น |
| C.3 | Channel "in-app เท่านั้น" | in-app only | digest email ไม่กรอง type (`notification_service.go:1080-1085`) · mobile push ปฏิเสธ type ที่ไม่รู้จัก (`push_settings.go:10-13,37-38`) | meeting rows ต้อง `email_suppressed = true` เสมอ · push ไม่ส่งเอง ✅ แต่ถ้า PM อยากได้ push ต้องเพิ่ม `PushType` + setting |
| C.4 | Setting copy 10 นาที | 5 นาที | "Get notified 10 minutes before your event starts." (`messages/en.json:65,1029`, th `:65,1029`) | ต้องตัดสิน 5 vs 10 แล้วแก้ copy · และ gate alert ด้วย `event_reminders` / `event_start` / `event_changes` / `event_cancellations` (ตอนนี้ toggle ไม่มีผล) |
| C.5 | Toast variants | 5 สี: ฟ้า, เขียว, ฟ้า (missed), เทา `rgba(255,255,255,0.1)`/`#8C99A6`, ส้ม `rgba(255,128,0,0.1)`/`#FF8000` | `VARIANT` มี success/error/warning (`#f6913a`)/info/caution (`lib/toast.tsx:19-54`) — ไม่มีเทา ส้ม `#FF8000` | ต้องเพิ่ม variant (หรือ prop สี) — ตาม rule 09 "เพิ่ม prop ในของเดิม ห้าม fork" · body 2 บรรทัดต้องรองรับ line break |
| C.6 | Toast system ซ้ำซ้อน | toast เดียวมุมขวาบน | sonner (`zyraToast`) top-right 24 + VO bespoke stacks ที่ right 24 เหมือนกัน (wave/knock/spotlight/media request: `vo-spotlight-notification.tsx:75,131`, `vo-knock-notification.tsx:90`) | toast meeting อาจซ้อนทับการ์ด VO อื่น (**ยังไม่ได้ตรวจ** visually) — ควรใช้ `zyraToast` (มี X + actions ตรง Figma แล้ว) ไม่สร้างชุดที่ 3 |
| C.7 | Bell badge semantics | +1 ตอน alert, = 0 เมื่อเปิด panel, "Mark all as read" | badge = unread ใน 30 row ล่าสุด, ซ่อนตอน panel active เท่านั้น, ไม่มี seen vs read | AC-HP03-5 ไม่ตรง · ถ้าจะ reset จริงต้องเพิ่ม `last_seen_at` ต่อ user/workspace หรือ mark-all-read ตอนเปิด (ซึ่งทำให้ปุ่ม Mark all ไร้ความหมาย) |
| C.8 | Badge/การ์ด/header style | badge 16×~18, top −4/right −4, Medium 10 · Join h24 px8 r4 · header "Mark as read" #8C99A6 12 · icon circle สีตามประเภท + กล้อง | badge 14, top 4/right 4, bold 9 (`vo-sidebar.tsx:273-276`) · Spotlight Join h28 px16 r6 (`:629-633`) · "Mark all read" สีเขียว (`:378-396`) · NotificationCard ใช้ avatar/โลโก้ + type badge (`:469-575`) | ต้องตัดสินว่าแก้ของเดิมให้ตรง Figma ทั้ง panel (กระทบทุก type) หรือแค่การ์ด meeting |
| C.9 | Relative time | "1 min ago", "2 hours ago" | compact "5m", "3h", "2d" (`chat-utils.ts:104-118`) | ใช้ของเดิม (ทุก type) หรือเปลี่ยนทั้ง panel |
| C.10 | Cancel/reschedule source | Organizer แก้/ยกเลิกใน Zyra | ไม่มี UI/API — เปลี่ยนได้จาก Google inbound เท่านั้น, lazy, cancel = hard delete (`calendar_meeting_inbound.go:102-138`, `calendar_meeting_store.go:251-256`) | EP-02 ทำได้แค่กรณี Google แก้/ลบ และต้อง hook ใน `reconcileOne` · ถ้าต้องการ EP-02 จาก Zyra ต้องทำ EC-04 ของ CAL-01 (edit/delete) ก่อน · ควรเปลี่ยนเป็น soft cancel เพื่อให้ history ยังอ้างได้ |
| C.11 | Recipients / RSVP | "invited participants" (+ RSVP No?) | organizer + guests, **ไม่มี RSVP** (`calendar-meetings.ts:126-130` "Zyra has no RSVP of its own"); guest ต้องเป็นสมาชิก workspace | filter RSVP ทำไม่ได้ · external Google attendees ไม่ได้ alert |
| C.12 | Google/Outlook events | (spec §6 #7) | Google events ดึงสด ไม่เก็บ DB (CAL-01 progress รอบที่ 1 "Sync model") | server-side alert สำหรับ Google event ทำไม่ได้โดยไม่มีตาราง/worker ใหม่ → scope = Zyra meetings เท่านั้น |
| C.13 | Calendar entry point | "Open Calendar" → Week + event detail | Calendar เปิดได้เมื่อ `GOOGLE_CALENDAR_ENABLED` เท่านั้น (`hero-virtual-office.tsx:4922-4935`), default Month, ไม่มี prop focus event · desktop only (`:15502-15503` `!mobileSpatial`) | ต้องเพิ่ม entry point + ตัด gate Google ออกจากการเปิด meeting (meeting API ไม่ขึ้นกับ flag อยู่แล้ว `router.go:290-292`) · lite/mobile ไม่มี Calendar → ปุ่ม "Open Calendar" บน mobile ไม่มีปลายทาง |
| C.14 | "online" definition | user online in Workspace | API presence in-memory per pod (`workspace_presence_service.go:34-57`) — pod ใหม่หลัง deploy ว่างจนกว่าจะมี heartbeat (~30 วิ) · WS delivery ต้องอยู่ใน room workspace นั้น | ตัดสิน offline/online ที่ server ไม่แม่น 100% — แนะนำให้ client ตัดสิน "toast หรือ bundle" จากเวลา row vs เวลาที่ตัวเองเข้า VO แทนการเชื่อ flag ฝั่ง server |
| C.15 | Comment เก่าในโค้ด | — | `lib/api/chat.ts:644-646` และ docstring panel `vo-notification-panel.tsx:116-118` บอก "REST-only, no WS push" แต่จริงมี `chat:notification:new` แล้ว | ไม่กระทบ logic แต่ทำให้คนอ่านเข้าใจผิด |
| C.16 | Side note (ไม่เกี่ยวตรง) | — | คอลัมน์ `weather_alert_id` + unique index (migration 100) **ไม่อยู่ใน** `postgres.go` auto-migrate (grep ไม่เจอ) — insert weather bell อาจล้มบน env ที่ไม่ได้รัน SQL มือ (**ยังไม่ได้ตรวจกับ DB จริง**) | บอกไว้เพราะ pattern dedupe ที่จะ copy มาจากตัวนี้ — ของใหม่ต้องลง `postgres.go` ด้วย |
| C.17 | Display panel ในห้อง | Figma HP-02 #4 "Meeting room 1" | UI VO meeting เดิม | ไม่ใช่ scope ของฟีเจอร์นี้ (ux §6) |

---

## D. DB / API impact sketch (suggestion — ยังไม่ใช่ decision, ไม่มีโค้ด)

### D.1 DB (migration 122 + mirror ใน `postgres.go`)

- **`tb_meeting_alert_log`** (suggestion) — `meeting_id` FK `ON DELETE CASCADE`, `user_id`, `alert_type` (`reminder_5m` | `started` | `changed` | `cancelled`), `start_at` (เวลาของ meeting ตอนส่ง), `notification_id`, `created_at` · UNIQUE `(meeting_id, user_id, alert_type, start_at)` — ใส่ `start_at` ใน key เพื่อให้เลื่อนเวลาแล้วส่งใหม่ได้ (spec §6 #3) · ทางเลือก: ไม่มีตารางแยก ใช้ partial UNIQUE บน `tb_notification (calendar_meeting_id, user_id, type, meeting_start_at)` แบบ weather
- **`tb_notification` columns** (suggestion) — `calendar_meeting_id UUID NULL REFERENCES tb_calendar_meeting(id) ON DELETE SET NULL`, `meeting_start_at TIMESTAMPTZ NULL`, `meeting_end_at TIMESTAMPTZ NULL` (สำหรับ Join/ended/greyed โดยไม่ต้อง JOIN meeting ที่อาจถูกลบ), `meeting_zone_id` / ชื่อห้องเก็บใน `body` หรือคอลัมน์แยก · title = ชื่อ meeting (snapshot)
- **type CHECK** เพิ่ม เช่น `meeting_reminder`, `meeting_started`, `meeting_rescheduled`, `meeting_cancelled` (ชื่อ **ยังไม่ตกลง**) — ใน `postgres.go:377-380` + migration
- **`tb_calendar_meeting`** (suggestion) — `cancelled_at TIMESTAMPTZ NULL` (soft cancel) แทน hard delete ใน inbound · index `(start_at)` หรือ partial index สำหรับ window scan
- (ถ้าต้องการ EP-01 bundle ฝั่ง server) `tb_notification.toast_shown_at` หรือเก็บฝั่ง client — **ยังไม่ตัดสิน**
- (ถ้าต้องการ "seen" แยก read) `tb_user_notification_seen (user_id, workspace_id, seen_at)` — ขึ้นกับคำตอบ spec §6 #10

### D.2 Backend logic (zyra-api)

- `MeetingAlertService` + loop ใน `main.go` (tick 15–30s, `context.WithTimeout`, optional `AcquirePollerLock`) : 
  1. claim ผู้รับ: meetings ที่ `start_at` ใน window, ไม่ cancelled, ไม่ all-day (**ยังไม่ตกลง**) × (organizer ∪ guests) × settings gate (`event_reminders` / `event_start`) → `INSERT … ON CONFLICT DO NOTHING RETURNING`
  2. insert `tb_notification` (`email_suppressed = true`, workspace_id, title/body snapshot)
  3. publish `vo:notify` (payload = `model.Notification` + meeting fields)
- Hook ใน `calendar_meeting_inbound.go` `reconcileOne`: เวลาเปลี่ยน → `meeting_rescheduled` (gate `event_changes`) + อัปเดต row เดิม/ re-push; ถูกลบ → `meeting_cancelled` (gate `event_cancellations`) — เฉพาะผู้ที่ได้ alert ไปแล้วหรือทุก guest (**ต้องถาม**)
- `ListNotifications` SELECT + `model.Notification` เพิ่ม field meeting · (optional) filter 7 วัน
- จำนวนคนในห้อง: query `tb_zone_section_member` ต่อ `(workspace_id, zone_id)` ตอนส่ง (snapshot) — หรือให้ client คำนวณจาก `zoneSections` (live) **ต้องถาม** (spec §6 #12)

### D.3 API endpoints

- **ไม่ต้องมี endpoint ใหม่** สำหรับ list / mark read / mark all — ใช้ `/api/user/notifications*` (UserGuard ✅ rule 15)
- (optional) `GET /api/user/workspaces/:id/meetings/:meetingId` — ให้ "Open Calendar" เปิด event ที่อยู่นอกช่วงที่โหลดได้ (ตอนนี้มีแค่ list ตามช่วงเวลา)
- (ถ้าทำ seen) `POST /api/user/notifications/seen?workspace_id=`
- ไม่มี admin endpoint

### D.4 WS events

- **ไม่ต้องมี event ใหม่** — ใช้ `vo:notify` → `chat:notification:new` (insert และ update แบบเดียวกับ Spotlight end) · zyra-ws ไม่ต้องแก้ (relay opaque JSON)

### D.5 Frontend (zyra-app)

- `NotificationType` + interface fields (`lib/api/chat.ts`)
- handler `chat:notification:new` → `zyraToast` meeting (duration 180s, `icon={Video}`, actions Open Calendar / Later + Join meeting) ใน `hero-virtual-office.tsx` ใกล้ `:3883-3897`
- toast variants เทา/ส้ม + body หลายบรรทัด ใน `lib/toast.tsx` (เพิ่ม prop ไม่ fork)
- `MeetingNotificationCard` ใน panel (icon circle + กล้อง, Join h24, ended/greyed state, click → Calendar วันนั้น)
- Calendar entry point: `VOCalendar` prop `focus={{ date, meetingId, mode: "week" }}` + เปิดได้แม้ Google flag ปิด
- EP-01: บน mount เทียบ row meeting ที่ `!is_read` และสร้างก่อน session นี้ → toast bundle "You missed N meetings"
- i18n en/th ทุก copy (rule 19) + แก้ copy setting 10 → 5 นาที (ถ้าตกลง)

---

## E. Suggested PR-sized task list (suggestion)

| # | Repo | PR | ขึ้นกับ | หมายเหตุ |
|---|---|---|---|---|
| 0 | — | **ถาม PM** ก่อน: spec §6 (#1,#3,#5,#7,#8,#10,#12,#13,#14) + ux §7 (A3,A5,A6,A10,A12–A17,A20) + C.4 (5 vs 10 นาที) + all-day meeting alert ไหม + EP-02 จาก Zyra ต้องมี edit/cancel ก่อน | — | หลายข้อเปลี่ยน schema |
| 1 | zyra-api | `feat(api): add meeting alert notification types and alert log` — migration 122 (+down) + mirror `postgres.go` (type CHECK superset, `tb_meeting_alert_log`, คอลัมน์ meeting บน `tb_notification`, index) + model/`ListNotifications` field | 0 | test migration up/down/up กับ Postgres จริง (แบบ CAL-01) |
| 2 | zyra-api | `feat(api): send 5-min and start meeting alerts from a background loop` — service + loop + settings gate + `email_suppressed=true` + `vo:notify` publish + EC-01 window + table-driven tests (dedupe, short notice, settings off, cancelled skip, 2 replicas concurrent) | 1 | ไม่ต้องแก้ zyra-ws |
| 3 | zyra-api | `feat(api): notify guests when a synced meeting is rescheduled or cancelled` — hook ใน inbound reconcile + soft cancel + update/re-push row เดิม (Join → Calendar) | 1, (0: scope EP-02) | ถ้าต้องการ edit/cancel จาก Zyra → แยกเป็นงาน CAL-01 EC-04 ก่อน |
| 4 | zyra-app | `feat(app): show meeting alert toasts` — toast variants (เทา/ส้ม, multi-line body) ใน `lib/toast.tsx` + handler ใน hero + Join/Open Calendar/Later + i18n | 2 | vitest: handler → toast args |
| 5 | zyra-app | `feat(app): open calendar on a given meeting` — `VOCalendar` focus prop (Week + Event details) + ไม่ผูกกับ Google flag + fetch meeting เดี่ยวถ้าอยู่นอกช่วง | — (ทำคู่กับ 4) | อาจต้อง endpoint get-one (D.3) |
| 6 | zyra-app | `feat(app): meeting cards in the notification panel` — card + Join (ยังไม่จบ) / past / cancelled / rescheduled + click → Calendar วันนั้น + (ถ้าตกลง) 7-day / load-more | 1, 5 | ตัดสิน C.8 (แก้ style panel ทั้งหมดหรือแค่การ์ด meeting) |
| 7 | zyra-app | `feat(app): bundle missed meeting alerts on return` — EP-01 toast "You missed N meetings" + badge semantics (C.7) | 4, 6 | ขึ้นกับคำตอบ seen vs read |
| 8 | zyra-app | `fix(app): align event reminder setting copy with meeting alert timing` — copy 10 → 5 นาที (en/th) ถ้า PM ยืนยัน | 0 | เล็ก |
| 9 | zyra-doc | progress + before/after (rule 18: feature ใหญ่ multi-PR) — metric เช่น alert latency (created_at − start_at) p95, duplicate count = 0 จาก `tb_meeting_alert_log` | 2–7 | ยังไม่ได้วัด (ยังไม่ implement) |

---

## F. ยังไม่ได้ตรวจ

- พฤติกรรม sonner เมื่อมี toast 336px หลายใบ (stack/expand) และการซ้อนกับ VO bespoke toast stack — ยังไม่ได้เปิดดูใน browser
- predicate ที่ถูกต้องของ "คนที่อยู่ในห้อง" ฝั่ง server (`tb_zone_section_member.presence`/`is_present`) และ `zoneSections` ฝั่ง client ครอบคลุมทุกชั้นหรือแค่ชั้นปัจจุบัน
- replicas ของ api/ws บน origin `zyra-infra` ปัจจุบัน (อ่านจาก checkout 2026-09-24)
- `weather_alert_id` บน DB จริงของแต่ละ env (C.16)
- Calendar Display (CAL-02) — event detail popup แบบ Figma (RSVP) ยังไม่ได้ตรวจว่า implement แล้วหรือยัง; ที่มีคือ `calendar-event-details.tsx` ของ CAL-01 (เฉพาะ Zyra meeting)
- Figma ไม่ได้ดึงซ้ำในการตรวจรอบนี้ — ค่า UI อ้างจาก `ux-ui-plan.md`
