# Meeting Alert (SC-MTG-CAL-03) — Progress

> entry ใหม่อยู่บนสุด · รูปแบบ: ทำอะไรแล้ว / verify อะไรแล้ว / เหลืออะไร-ติดอะไร

---

## 2026-10-29 · รอบ 3 — UI ให้ตรงภาพใน `ux-ui/` + X1 เต็ม (ผู้ใช้สั่ง) · **ยังไม่ commit · ยังไม่ live-test**

เทียบภาพครบ 12 ภาพ (toast 5 แบบ, panel 5 ภาพ, Calendar หลังกด Open Calendar, idle หลัง dismiss) แล้วแก้ส่วนที่ยังไม่ตรง — **แก้ของที่ใช้ร่วมกันทุก type ตามที่ผู้ใช้สั่ง** (task-breakdown §2 เคยบอกว่าไม่แตะ)

| เรื่อง | ไฟล์ | ก่อน → หลัง |
|---|---|---|
| ปุ่มหัว panel (desktop) | `vo-notification-panel.tsx` | "Mark all read" สีเขียว icon 14 → **"Mark as read"** `#8C99A6` 12/15 icon 12 gap 8 (ไม่มีอะไรให้อ่าน = จาง 50%) · mobile / drawer ไม่แตะ |
| เวลาบนการ์ด (desktop) | `vo-notification-panel.tsx` · `messages/*.json` (`VirtualOffice.notifMinutesAgo / notifHoursAgo / notifDaysAgo`) | "5m" → **"5 mins ago" / "1 hour ago" / "1 day ago"** (ไทย "5 นาทีที่แล้ว") — ทุก type ใน panel desktop · mobile / drawer ยังเป็น "5m" (มี Figma ของตัวเอง) · ภาพเขียน "1 hours ago" ใช้รูปที่ถูกไวยากรณ์ |
| การ์ด reminder | `messages/en.json` | "Event starts in 5 minutes" → **"Event starts in 5 mins"** (toast ยังเป็น "minutes" ตามภาพ) |
| badge ใน sidebar (bell + chat) | `vo-sidebar.tsx` | 14px อยู่ในมุม bold 9 → **top/right −4, `#D41818`, p 1, Medium 10/14, กว้าง 16** (Figma "Count number" — ใช้ชุดเดียวกันทั้ง bell และ chat) · badge สมาชิก (เขียว) ไม่แตะ |
| X1 — Calendar ใน sidebar | `hero-virtual-office.tsx` | เดิม `GOOGLE_CALENDAR_ENABLED` ปิด → toast "coming soon" → **เปิด Calendar ได้ทุก env** (Zyra meeting ไม่ต้องใช้ Google; ไม่ได้เชื่อม → Calendar โชว์ banner ให้เชื่อมเอง) · ⚠️ env ที่ flag ปิดจะเห็น Calendar แล้ว (รวม prod ถ้า flag ปิดอยู่) |

**ไม่ได้แก้:** ตำแหน่ง Event detail ใน Calendar (ภาพอยู่ข้าง event ที่กด / โค้ดชิดซ้าย) — เป็นของ CAL-02 + PR #672

**Verify:** tsc (source) + eslint (panel, sidebar) + prettier ผ่าน · test ใหม่ `vo-sidebar-count-badge.test.tsx` (2) + header / เวลา desktop 1 ตัว · แก้ `vo-notification-panel-mobile.test.tsx` 2 จุด (`markAllRead` → `markAsRead` ของ panel desktop) · full suite 4996 ผ่าน / 3 fail (`accessory-form`, `admin-avatar-management-flag`, `pet-creation-wizard`) — รันแยกผ่านครบ 21/21 · **ยังไม่ได้เปิดดูในเบราว์เซอร์**

---

## 2026-10-29 · รอบ 2 — HP-03 load-more + badge reset · มติ Q3 (rif + Claude) · **ยังไม่ commit · ยังไม่ live-test**

**มติ (ผู้ใช้ 2026-10-29):** **Q3 = เลื่อนเวลาแล้วส่ง alert 5 นาที / เริ่ม ใหม่ตามเวลาใหม่** — ตรงกับที่ทำไว้ในรอบ 1 (`meeting_start_at` อยู่ใน PK ของ `tb_meeting_alert_log`) ไม่ต้องแก้ schema · สั่งให้ทำ HP-03 ส่วนที่ขาด: load-more + badge

**ทำแล้ว (zyra-app เท่านั้น)**

| เรื่อง | ไฟล์ | สรุป |
|---|---|---|
| AC-HP03-5 badge = 0 เมื่อเปิด panel | `stores/chat-store.ts` · `lib/notification-seen.ts` (ใหม่) · `hero-virtual-office.tsx` | เพิ่ม `notificationSeenAt` + `notificationBadge` ใน store — badge นับเฉพาะ row ที่**ยังไม่อ่านและมาหลัง**เปิด panel ครั้งล่าสุด · เปิด panel → บันทึกเวลา (และบันทึกอีกครั้งตอนปิด เพราะ row ที่เข้ามาระหว่างเปิดถือว่าเห็นแล้ว) · เก็บต่อ workspace ใน `localStorage` (`zyra_notification_seen:<ws>`) · **tab Unread / "Mark as read" ยังใช้ `is_read` เหมือนเดิม** (Q7) · ใช้กับ sidebar ของ VO (desktop + Spatial phone rail) · **Lite ยังใช้ `notificationUnread` เดิม** (ไม่ได้แตะ) |
| AC-HP03-1 ประวัติย้อนหลัง | `vo-notification-panel.tsx` · `chat-store.ts` (`appendNotifications`) | เลื่อนถึงท้ายรายการ → โหลดหน้าถัดไป 30 รายการด้วย `before=<id ของรายการเก่าสุด>` (API เดิม) · ไม่มีปุ่ม (Figma ไม่มี) — `IntersectionObserver` + ข้อความ loading เดิมระหว่างโหลด · หน้าแรกได้ไม่ครบ 30 = หมดแล้ว · ไม่ตัดที่ 7 วัน (ย้อนได้เรื่อย ๆ ตาม Q8 — ไม่ลบข้อมูล) · ใช้กับทุก variant (panel / mobile / drawer) |

**Verify:** `tsc` (source) + eslint (store, panel, lib) + prettier ผ่าน · test ใหม่ `notification-badge-seen.test.ts` (5) + load-more 2 ตัวใน `vo-notification-panel-meeting.test.tsx` · test panel เดิม (spotlight, mobile) ผ่าน · full suite 4994 ผ่าน / 2 fail = `accessory-form`, `pet-creation-wizard` ตัวเดิมที่รันแยกผ่าน (timeout ตอนรันพร้อมกัน)

eslint ของ hero รอบนี้: 0 error · 11 warning เดิมทั้งหมด (เลื่อนบรรทัดตามโค้ดที่เพิ่ม)

**ยังไม่ได้ verify:** เปิดดูจริงในเบราว์เซอร์ · seen time เก็บแค่ในเบราว์เซอร์นี้ — เปิดอีกเครื่อง badge ยังนับ unread ทั้งหมดจนกว่าจะเปิด panel ที่เครื่องนั้น (ถ้าต้องการให้ตรงกันทุกเครื่องต้องเพิ่ม API เก็บ seen time ฝั่ง server)

---

## 2026-10-29 · รอบ 1 — implement API-1/2/3 + APP-1/2/3/4/5 (rif + Claude) · **ยังไม่ commit · ยังไม่ live-test**

### Branch (ยังไม่ commit ทั้งหมด — ผู้ใช้ review + commit เอง)

| Repo | Branch | ฐาน |
|---|---|---|
| zyra-api | `feat/meeting-alert` | `origin/develop` `e083e65` |
| zyra-app | `feat/meeting-alert` | **`origin/fix/calendar-popup-edges` `5e92786`** — PR [#672](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/672) ของ N2Pluto ยังไม่ merge · ตั้งฐานบนนั้นเพราะงานนี้แตะ `vo-calendar.tsx` / `hero-virtual-office.tsx` ชุดเดียวกัน (task-breakdown §2.1) · #672 merge แล้วให้ rebase กลับ develop · PR [#673](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/673) `fix/calendar-now-line` แตะแค่ `calendar-parts.tsx` ไม่ชนกัน |
| zyra-ws / zyra-notifications | ไม่แก้ | ใช้ `vo:notify` → `chat:notification:new` เดิม |

ทำใน branch เดียวต่อ repo (ไม่ได้แยก 1 PR ต่อ task ตาม §5 เพราะไม่ได้ commit) — ตอน commit แยกได้ตามตารางไฟล์ด้านล่าง

### ทำแล้ว

**zyra-api**

| Task | ไฟล์ | สรุป |
|---|---|---|
| API-1 | `migrations/122_meeting_alert.sql` (+`.down.sql`) · `internal/database/postgres.go` · `internal/model/chat.go` · `internal/service/notification_service.go` | type CHECK +4 (`meeting_reminder/started/cancelled/rescheduled`) ทั้ง migration และ superset ใน `postgres.go` · คอลัมน์ `tb_notification.calendar_meeting_id / meeting_start_at / meeting_end_at / meeting_prev_start_at / meeting_prev_end_at / meeting_superseded_at` · `tb_meeting_alert_log` PK `(meeting_id, user_id, alert_type, meeting_start_at)` · `tb_calendar_meeting.cancelled_at` + index `(start_at) WHERE cancelled_at IS NULL` · `ListNotifications` คืน field meeting + `meeting_zone_id` (LEFT JOIN meeting ปัจจุบัน) |
| API-2 | `internal/service/meeting_alert_service.go` + `meeting_alert_store.go` (ใหม่) · `main.go` | loop ทุก **15 วิ** (`MeetingAlertInterval`) · reminder เมื่อเหลือ ≤ 5 นาที (และ ≥ 1 นาที) · started เมื่อถึงเวลา (ช้าได้ ≤ 2 นาที — EC-05) · EC-01: meeting ที่สร้างหลังจุด 5 นาที → reminder ทันที หรือ started ทันทีถ้าเหลือ < 1 นาที · gate `event_reminders` / `event_start` · ข้าม all-day + `cancelled_at` · ผู้รับ = organizer + guest ที่ยังเป็นสมาชิก workspace · claim log `ON CONFLICT DO NOTHING` → insert `tb_notification` (`email_suppressed = true`) ใน transaction เดียว → push `vo:notify` |
| API-3 | `meeting_alert_service.go` `NotifyMeetingChanged` · `calendar_meeting_service.go` (`SetChangeNotifier`) · `calendar_meeting_inbound.go` | ยกเลิก / เลื่อน → set `meeting_superseded_at` บน row reminder / started เดิม + push ซ้ำ (การ์ดเลิกแสดง Join) → ส่ง `meeting_cancelled` / `meeting_rescheduled` ให้ทุกคนยกเว้นผู้เปลี่ยน (gate `event_cancellations` / `event_changes`, dedupe ด้วย log เดียวกัน) · ข้าม meeting ที่จบไปแล้ว · แก้ชื่ออย่างเดียว (เวลาไม่เปลี่ยน) ไม่แจ้ง · ต่อกับ Google inbound: ลบใน Google → แจ้ง**ก่อน** hard delete · เลื่อนใน Google → แจ้งหลัง `ApplyGoogleChange` |

**zyra-app** (ฐาน #672)

| Task | ไฟล์ | สรุป |
|---|---|---|
| APP-1 | `lib/toast.tsx` · `lib/api/chat.ts` · `lib/meeting-alert.ts` (ใหม่) · `views/user/virtual-office/use-meeting-alerts.ts` (ใหม่) · `hero-virtual-office.tsx` · `messages/en.json` + `th.json` (namespace `MeetingAlert`) | variant `neutral` (เทา `rgba(255,255,255,0.1)` / `#8C99A6`) + `notice` (ส้ม `rgba(255,128,0,0.1)` / `#FF8000`) + body หลายบรรทัด (`whitespace-pre-line`) — เพิ่มในของเดิม · toast 4 แบบค้าง 3 นาที icon `Video` · reminder = Open Calendar · started = Later + Join event · cancelled / rescheduled = View Calendar · toast ใหม่ของ meeting เดียวกันแทนอันเก่า · ไม่ toast row ที่ push ซ้ำเพื่อปิด Join · เรียกจาก `onNotification` ของ chat wiring (ยังเด้งแม้อยู่ใน meeting อื่น — EC-04) |
| APP-2 | `components/calendar/vo-calendar.tsx` · `hero-virtual-office.tsx` | prop `initialFocus { date, mode, meetingId }` (อ่านตอน mount, hero remount ด้วย `key`) · Open / View Calendar → Calendar **full + Week** ของวัน meeting + Event details · ผ่าน `guardCalendarLeave` (มี draft → ถาม Discard ก่อน) · เปิดจาก sidebar → กลับไปวันนี้ · Join: มีห้อง → `joinCalendarMeeting` (เดินไปห้อง) · ไม่มีห้อง → เปิด Calendar ที่ meeting (Q11) |
| APP-3 | `components/vo-notification-panel.tsx` | `MeetingNotificationCard`: วงกลม 32 สีตามประเภท + กล้อง · title / เวลาแบบ relative เดิม · body 2 บรรทัด · Join (h24 px8 r4 `#58D68D`) เฉพาะ started ที่ยังไม่จบและไม่ถูก supersede · past ไม่ greyed · คลิกการ์ด → Calendar · ไม่ restyle การ์ด type อื่น |
| APP-4 | `use-meeting-alerts.ts` | ตอนเข้า VO: row `meeting_started` ที่ยังไม่อ่านและสร้างก่อนเข้ารอบนี้ → toast เดียว "You missed N events" + View Calendar (เปิดที่ meeting ล่าสุด) · จำเวลาสรุปล่าสุดใน `localStorage` (`zyra_meeting_missed_seen:<ws>`) ไม่ให้เด้งซ้ำทุกครั้งที่เข้า |
| APP-5 | `messages/en.json`, `th.json` | copy setting "Event reminders" 10 → 5 นาที |

### Copy — ยึดภาพใหม่ใน `ux-ui/` (ผู้ใช้วางไว้ 2026-10-29) ไม่ใช่ ux-ui-plan §2.4

ภาพใหม่เปลี่ยน **"Meeting" → "Event"** ทุกจุด และ toast แสดง**ช่วงเวลา**: "Event starts in 5 minutes" · "Event has started" / "Join event" · "You missed 3 events" · "Event has been cancelled" + "Scheduled : 20 July, 2026 at 10:00 - 10:30" · "Event has been rescheduled" + "New time: …" · การ์ด: "Event cancelled" + "Previously scheduled for …", "Event rescheduled" · body toast `10:00 - 10:30 · Design Room` / การ์ด `10:00-10:30 · Design Room` · ต้องแก้ ux-ui-plan §2.4 / §4.6 ตาม (ยังไม่แก้)

### Verify แล้ว

- zyra-api: `go build ./...` · `go vet` · `go test ./...` ผ่านทั้ง repo · test ใหม่ `meeting_alert_service_test.go` (table-driven: reminder / started / EC-01 / EC-05 / settings off / ส่งซ้ำ / เลื่อนเวลาแล้วส่งใหม่ / cancel / reschedule / actor ไม่ได้แจ้ง / supersede push) + `TestListTellsGuestsOfGoogleDeletesAndMoves` · coverage: `SendDue` 95%, `dueMeetingAlert` 100%, `NotifyMeetingChanged` 86% (store SQL = 0% ใน unit test)
- **Postgres 16 จริง (docker ชั่วคราว ลบแล้ว)**: บูต DDL ใน `postgres.go` ผ่าน · migration 122 down → up → up ผ่าน · `SendDue` 4 ตัวพร้อมกัน → ได้ 2 row (organizer + g1; g2 ปิด reminder, คนนอก workspace ไม่ได้) · all-day / cancelled ไม่ได้ · ทุก row `email_suppressed = true` + log ผูก `notification_id` · started 3 คน · `ListNotifications` คืน field ครบ · เลื่อนเวลา → supersede 5 row + rescheduled 2 คน · ยกเลิกแล้ว hard delete → row ยังอยู่ (`calendar_meeting_id` = NULL) · down ทั้งที่มี row meeting แล้วบูตซ้ำได้ (test file ชั่วคราว ลบแล้ว ไม่อยู่ใน diff)
- zyra-app: `tsc --noEmit` ไม่มี error ในไฟล์ source (error ที่มีอยู่ใน `__tests__/` เดิม 9 จุด ไม่เกี่ยว) · eslint ไฟล์ที่แก้ (ยกเว้น hero — ดูข้างล่าง) ผ่าน · prettier ผ่าน · test ใหม่ 40 ตัวผ่าน (`meeting-alert`, `use-meeting-alerts`, `vo-notification-panel-meeting`, `zyra-toast` +1) · full suite 4983 ผ่าน / 6 fail ใน 5 ไฟล์ที่ไม่เกี่ยว (accessory-form, customer-permission-matrix, mobile-b-cw-create-workspace, native-apple-signin, pet-creation-wizard) — รันแยกผ่านครบ 48/48 = timeout ตอนรันพร้อมกัน

### ยังไม่ได้ verify / เหลือ

- **ยังไม่ได้เปิดดูในเบราว์เซอร์ / ยังไม่ได้ทดสอบบน dev** (task-breakdown §6 ข้อ 1–5) · toast หลายใบซ้อนบนจอ 1280×720 · ตำแหน่งชนกับ toast ของ VO อื่น
- ~~eslint ของ `hero-virtual-office.tsx`~~ — รันจบแล้ว: 0 error · 11 warning ทั้งหมดอยู่นอกบรรทัดที่แก้ (unused eslint-disable + exhaustive-deps ที่บรรทัด 8507 ของเดิม)
- ตาราง before / after (§7) ยังไม่มีตัวเลข — วัดหลังขึ้น dev
- **ไม่ได้ทำ**: load-more ใน panel (Q8 — Figma ไม่มีแบบ) · เหตุผลการยกเลิก (CAL-01 AC-HP05-3) · รวม reschedule หลายครั้งใน 1 นาที (CAL-01 HP-06 EC-E)
- ~~X1 ทำแค่บางส่วน~~ — ทำเต็มแล้วในรอบ 3
- missed bundle (APP-4) อ่านจาก `useChatStore.notifications` ก้อนแรกหลังเข้า VO — ถ้า store ยังค้างรายการของ workspace ก่อนหน้า อาจนับผิด (ยังไม่ได้เทสกรณีสลับ workspace)

### ใช้ค่าแนะนำของ task-breakdown §3.2 (ยังไม่ได้ให้ Ten ยืนยัน)

Q1 3 นาที · Q2 Later = ปิด · Q3 เลื่อนแล้วส่งใหม่ (**ผู้ใช้ยืนยันแล้วในรอบ 2**) · Q4 นาทีจริง · Q5 Zyra เท่านั้น · Q6 organizer + guest · Q7 badge = unread เดิม · Q9 all-day ไม่ส่ง · Q10 มือถือไม่มีปุ่ม Calendar · Q11 ไม่มีห้อง → Calendar · Q12 ทุก guest ยกเว้นผู้เปลี่ยน · Q13 ไม่มี Join

### ต่างจาก task-breakdown §4 (แก้ในเอกสารนั้นแล้ว)

- เพิ่ม `tb_notification.meeting_superseded_at`
- payload ใช้ `meeting_zone_id` แทน `meeting_join_url`
- `alert_type` = `reminder | started | cancelled | rescheduled` (cancel / reschedule ใช้ log เดียวกันกันส่งซ้ำ)

### ฝากให้ CAL-01 (HP-05 / HP-06)

- set `cancelled_at` / แก้เวลาแล้วเรียก `MeetingAlertService.NotifyMeetingChanged(ctx, MeetingChange{…, ActorID: ผู้ยกเลิก/เลื่อน})` — กรณี hard delete ต้องเรียก**ก่อน**ลบ · service ถูก inject ให้ `CalendarMeetingService` แล้วผ่าน `SetChangeNotifier` (`main.go`)
