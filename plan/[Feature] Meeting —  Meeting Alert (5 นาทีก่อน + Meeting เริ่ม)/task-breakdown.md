# SC-MTG-CAL-03 · Meeting Alert — Task breakdown (ส่งให้ dev ทำก่อน)

> **สถานะ (2026-10-29):** Ten แยก Meeting Alert ให้ dev อีกคนทำ**ก่อน** Calendar Integration (CAL-01) / Calendar Display (CAL-02) · เอกสารนี้ = ขอบเขต + ใครเป็นเจ้าของส่วนที่ใช้ร่วมกัน + ลำดับ PR + คำถามที่ยังเปิด · **ยังไม่ implement**
> **Repo ที่กระทบ:** `zyra-api` · `zyra-app` · (`zyra-ws` / `zyra-notifications` ไม่ต้องแก้)
> **โค้ดที่อ้าง:** gap ละเอียดอยู่ที่ [code-gap.md](code-gap.md) (ตรวจ 2026-10-27 ที่ app `22fc0d6d` / api `aaf5d7c`) · ตรวจซ้ำ 2026-10-29: origin/develop = app `59a86574` (+21 commit) / api `e083e65` (+2 commit) — **ไม่มี commit แตะไฟล์ของฟีเจอร์นี้** (toast, notification panel, calendar, chat store, notification/calendar service, `postgres.go`) · migration ล่าสุด = `121` → ของใหม่ = **`122`**
> **2026-10-29 รอบ 1 implement แล้ว (ยังไม่ commit)** → [progress.md](progress.md) · §4 ด้านล่างอัปเดตตามโค้ดจริง (ต่างจากร่าง 3 จุด: `meeting_superseded_at`, `meeting_zone_id` แทน `meeting_join_url`, `alert_type` 4 ค่า)
> **อ่านคู่กัน:** [spec.md](spec.md) (requirement) · [ux-ui-plan.md](ux-ui-plan.md) (ค่า Figma ทุกจอ) · [POC](<../[Feature] Meeting — Calendar Display/poc/index.html>) ปุ่ม "ส่ง Meeting Alert" · checklist ขอบจอ / กดแล้วหาย → [Calendar Display ux-ui-plan §12](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md#12-ขอบจอบัง--กดแล้วหาย--checklist-ตอนทำจริง-2026-10-29>)

---

## 0. สรุปสำหรับ dev (อ่านอันนี้ก่อน)

- **ท่อ notification มีครบแล้ว** — `tb_notification` → Redis `vo:notify` → zyra-ws `chat:notification:new` → bell panel + badge · งานหลักคือ **ตัวตั้งเวลา (loop ใน zyra-api) + type ใหม่ของ meeting + กันส่งซ้ำ + toast / การ์ดใน panel**
- **แม่แบบที่ใกล้ที่สุด:** Spotlight live / ended (`notification_service.go:268-410`) — row ต่อผู้รับ, push, แล้ว UPDATE + push ซ้ำเมื่อสถานะเปลี่ยน
- **Figma ชนะเมื่อขัดกับ ClickUp** (Ten ตัดสิน 2026-10-29 — [CAL-01 spec §6.1 D0](<../[Feature] Meeting — Calendar Integration/spec.md>)) · ข้อที่ Figma ไม่ได้วาด ดู §3.2 (มีค่าแนะนำให้ใช้ไปก่อน)
- **กับดัก 4 ข้อที่เคยพัง / ทำผิดง่าย**
  1. type ใหม่ต้องเพิ่มใน superset CHECK ของ `zyra-api/internal/database/postgres.go` (~บรรทัด 376-380) **ในรอบเดียวกับ migration** — เคยทำ dev boot ไม่ขึ้นมาแล้ว 3 ครั้ง
  2. insert ทุก row ของ meeting ต้อง `email_suppressed = true` — digest email ไม่กรอง type (`notification_service.go:1080-1085`) จะส่งอีเมลไปหา user ทั้งที่ spec บอก in-app เท่านั้น
  3. กันส่งซ้ำด้วย **DB UNIQUE + `ON CONFLICT DO NOTHING RETURNING`** (push เฉพาะแถวที่ insert สำเร็จ) — ห้ามพึ่ง Redis lock อย่างเดียว (`AcquirePollerLock` เป็น fail-open) · ช่วง rolling deploy มี 2 pod
  4. tick 1 นาทีแบบ ClickUp ทำ "≤ 30 วิ" ไม่ได้ → tick **15–30 วิ**
- **ห้ามแตะ** (เป็นของ CAL-01 / CAL-02 — §2): API แก้ / ยกเลิก / เลื่อน meeting, Event detail popup, การเปลี่ยน hard delete → soft cancel ของ Google inbound

---

## 1. ขอบเขตรอบนี้

| Scenario | ทำรอบนี้ | หมายเหตุ |
|---|---|---|
| MA-HP-01 Alert 5 นาทีก่อน | ✅ ครบ | toast ฟ้า + "Open Calendar" (เปิด Calendar) |
| MA-HP-02 Alert ตอนเริ่ม | ✅ ครบ | toast เขียว + "Later" (ไว้ทีหลัง) / "Join meeting" (เข้าร่วม meeting) |
| MA-HP-03 Notification history | ✅ ครบ | การ์ด meeting ใน panel เดิม (ไม่ทำ panel ใหม่) |
| MA-HP-04 Dismiss | ✅ ครบ (มีของเดิมแล้วเกือบหมด) | X ของ `zyraToast` |
| MA-EP-01 Offline | ✅ ครบ | toast รวม "You missed N meetings" (คุณพลาด N meeting) |
| MA-EP-03 Duplicate / race | ✅ ครบ | DB UNIQUE |
| MA-EP-02 ยกเลิก / เลื่อนหลังส่ง alert | 🟡 **ฝั่ง notification ครบ** · ต้นทางมีแค่ Google inbound | Zyra ยังไม่มี API ยกเลิก / เลื่อน (เป็นงาน CAL-01 HP-05/06) → dev คนนี้ทำ function `NotifyMeetingChanged` ไว้ให้ CAL-01 เรียกทีหลัง + ต่อกับ Google inbound ที่มีอยู่ |
| EC-01…EC-05 | ✅ | EC-01 window ต้องรับ meeting ที่สร้างหลัง window เริ่มแล้ว · EC-03 คำนวณจาก `start_at` (absolute) อยู่แล้ว |
| Event จาก Google / Outlook | ❌ ไม่ทำ | Google events ไม่ได้เก็บใน DB (ดึงสด) → alert ได้เฉพาะ Zyra meeting (§3.2 Q5) |
| Mobile / Lite | ❌ ไม่มีหน้า Calendar | toast ขึ้นได้ แต่ซ่อนปุ่ม "Open / View Calendar" (§3.2 Q10) |

---

## 2. ส่วนที่ใช้ร่วมกับ CAL-01 / CAL-02 — ใครเป็นเจ้าของ (เพราะ Alert ทำก่อน)

ที่มา: [Calendar Display spec §7 X1–X8](<../[Feature] Meeting — Calendar Display/spec.md#7-จุดที่ทับกับ-meeting-alert-sc-mtg-cal-03>) + [CAL-01 ux-ui-plan §1](<../[Feature] Meeting — Calendar Integration/ux-ui-plan.md>)

| # | ส่วน | เจ้าของ | Alert ทำแค่ไหน | ต้องเผื่อให้คนถัดไป |
|---|---|---|---|---|
| X1 | เปิด Calendar ได้แม้ `GOOGLE_CALENDAR_ENABLED` ปิด (`hero-virtual-office.tsx:4922-4935`) | **Alert** | ตัดเงื่อนไข flag ออกจาก**การเปิด** Calendar (meeting API ไม่ขึ้นกับ flag อยู่แล้ว) | CAL-02 HP-01 ใช้ต่อ |
| X2 | เปิด Calendar ไปที่วัน / โหมด / event (`vo-calendar.tsx` state `mode`, `detailsId`) | **Alert** | prop `focus?: { date: Date; meetingId?: string; mode?: "day" \| "week" \| "month" }` → Week + เปิด Event detail | ตั้งชื่อ / รูป prop ให้ CAL-02 ใช้ได้ (คลิกวันใน Month, deep link) |
| X3 | Event detail popup (`calendar-event-details.tsx`) | **CAL-02** | **ใช้ของเดิม ไม่แก้** — เปิดด้วย `meetingId` | CAL-02 ขยายรองรับ Google / RSVP / cancelled ทีหลัง |
| X4 | สถานะ meeting / `cancelled_at` | คอลัมน์ = **Alert** · การ set = **CAL-01** (HP-05/06 + D1 ยกเลิกแล้วเป็นขีดฆ่า) | **ตกลงแล้ว (Ten 2026-10-29):** Alert เพิ่ม `tb_calendar_meeting.cancelled_at TIMESTAMPTZ NULL` ใน migration 122 (ยังไม่มีใคร set) · scheduler `WHERE cancelled_at IS NULL` ตั้งแต่แรก · ไม่เปลี่ยน inbound จาก hard delete | CAL-01 แค่ set `cancelled_at` + เรียก `NotifyMeetingChanged` — ไม่ต้องเพิ่มคอลัมน์เอง |
| X5 | ย้าย `use-calendar-data` ไป react-query | CAL-02 | ไม่ต้องทำ | — |
| X6 | Toast variant (`lib/toast.tsx`) | **Alert** | เพิ่ม variant เทา (`rgba(255,255,255,0.1)` / `#8C99A6`) + ส้ม (`rgba(255,128,0,0.1)` / `#FF8000`) + body หลายบรรทัด — **เพิ่ม prop ในของเดิม ห้าม fork** (rule 09) | CAL-02 EP-01 error toast ใช้ตัวเดียวกัน |
| X7 | Copy ปุ่ม Join | — | ตาม Figma (D0): toast **"Join meeting"** · การ์ดใน panel **"Join"** | — |
| X8 | Mobile | ยังไม่ตัดสิน | ซ่อนปุ่มเปิด Calendar บน mobile / Lite | — |
| — | การ์ดใน notification panel (`vo-notification-panel.tsx`) | **Alert** | เพิ่ม**การ์ด meeting ใหม่**เท่านั้น — ไม่ restyle ทั้ง panel (badge, "Mark all read", เวลาแบบ "5m") เพราะกระทบทุก type (rule 14) | ถ้า PM อยากให้ทั้ง panel ตรง Figma → แยกเป็นงานใหม่ |

### 2.1 งานที่กำลังวิ่งอยู่ — ระวังชนไฟล์

| งาน | ไฟล์ที่แตะ | ชนกับ Alert ตรงไหน | ทำยังไง |
|---|---|---|---|
| Session "Fix calendar popup edge-clipping + dismiss bugs" (branch `fix/calendar-popup-edges`, เริ่ม 2026-10-29) | `vo-calendar.tsx`, `calendar-schedule-event.tsx`, `calendar-parts.tsx`, `hero-virtual-office.tsx` (discard modal / ปิด calendar) | X1 / X2 แตะ `vo-calendar.tsx` + `hero-virtual-office.tsx` | ทำ PR ฝั่ง API ก่อน · PR ที่แตะสองไฟล์นี้ (APP-2) ให้แตกจาก develop **หลัง** PR นั้น merge หรือ rebase ก่อนเปิด PR |

---

## 3. ข้อที่ตัดสินแล้ว / ยังเปิด

### 3.1 ตัดสินแล้วด้วยกติกา "ขัดกันให้ยึด Figma" (เทียบ [ux-ui-plan §7](ux-ui-plan.md#7-figma-vs-clickup--ข้อขัดแย้งที่ต้องถาม))

| ข้อ | ใช้แบบนี้ |
|---|---|
| A1 icon | กล้อง lucide `Video` ทุกแบบ แยกสี: ฟ้า `#2DB6FF` (5 นาที, missed) · เขียว `#58D68D` (เริ่ม) · เทา `#8C99A6` (ยกเลิก) · ส้ม `#FF8000` (เลื่อน) |
| A2 title | title คงที่ตาม Figma "Meeting starts in 5 minutes" / "Meeting has started" … ชื่อ meeting อยู่ใน body · ข้อความไทยใน `messages/th.json` |
| A3 จำนวนคนในห้อง | **ไม่แสดง** (Figma วาด toast ครบแต่ไม่มี) |
| A4 / A5 / A9 ปุ่ม | "Open Calendar" · "Later" + "Join meeting" · การ์ด "Join" (h 24) |
| A8 ตำแหน่ง | top 24 / right 24 (Toaster เดิมตรงแล้ว) |
| A10 / A11 past item | ไม่ greyed · ไม่มี label · แค่ไม่มีปุ่ม Join |
| A15 offline | toast เดียว "You missed N meetings" + "View Calendar" · ใน panel ยังเป็นการ์ดแยกทีละอัน ไม่มีปุ่ม Join |
| A16 ยกเลิก / เลื่อน | 2 แบบแยกกัน (เทา / ส้ม) · body บอกเวลาเดิม / เวลาใหม่ |
| A18 bell | ไอคอนที่ 5 ใน sidebar ซ้าย (มีแล้ว) |
| setting "Event reminders" | ClickUp + Figma = **5 นาที** → แก้ copy setting เดิมที่บอก "10 minutes" (`messages/en.json:65,1029`, `th.json:65,1029`) · และให้ toggle `event_reminders` / `event_start` / `event_changes` / `event_cancellations` มีผลจริง (gate ใน SQL แบบ pet reminder `notification_pet.go:215-253`) |

### 3.2 ยังเปิด — มีค่าแนะนำให้ใช้ไปก่อน (ต้องให้ Ten / PM ยืนยัน)

Figma ไม่ได้วาด หรือเป็นเรื่อง logic ล้วน · ถ้าคำตอบต่างจากค่าแนะนำ แก้ทีหลังได้โดยไม่ต้องเปลี่ยน schema (ยกเว้น Q3)

| # | คำถาม | ค่าแนะนำ (ใช้ไปก่อน) | ที่มา |
|---|---|---|---|
| Q1 | toast ค้างกี่นาที (HP-02 เขียนว่านานกว่าแต่ตัวเลขเท่ากัน) | 3 นาทีทั้งคู่ (`duration: 180000`) | spec §6 #1 |
| Q2 | "Later" ทำอะไร | ปิด toast เหมือน X (notification ยังอยู่ใน panel) | ux A5 |
| Q3 | เลื่อนเวลาแล้วส่ง 5 นาที / เริ่ม ใหม่ตามเวลาใหม่ไหม | ✅ **ตัดสินแล้ว (ผู้ใช้ 2026-10-29): ส่งใหม่** → ใส่ `meeting_start_at` ใน UNIQUE key (**ต้องตอบก่อน API-1** เพราะเปลี่ยน schema) | spec §6 #3 |
| Q4 | สร้าง meeting กระชั้น (เหลือ 2 นาที) copy ว่าอะไร | "Meeting starts in 2 minutes" (คำนวณนาทีจริง) · เหลือ < 1 นาที → ส่งแบบ "เริ่มแล้ว" | spec §6 #5, EC-01 |
| Q5 | Google / Outlook event ได้ alert ไหม | ไม่ — Zyra meeting เท่านั้น | spec §6 #7, code-gap C.12 |
| Q6 | ใครได้รับ | organiser + guest ทุกคน (Zyra ไม่มี RSVP) | spec §6 #8, C.11 |
| Q7 | เปิด panel แล้ว badge = 0 ไหม (ClickUp) — โค้ดตอนนี้แค่ซ่อน | ✅ **ทำแล้ว (ผู้ใช้สั่ง 2026-10-29):** badge นับเฉพาะ unread ที่มาหลังเปิด panel ครั้งล่าสุด (seen time ต่อ workspace ในเบราว์เซอร์) · tab Unread ยังใช้ `is_read` | spec §6 #10, ux A6, C.7 |
| Q8 | ประวัติ 7 วัน | ✅ **ทำแล้ว 2026-10-29:** ไม่ลบข้อมูล · panel โหลดหน้าถัดไปเมื่อเลื่อนถึงท้าย (`before`) | spec §6 #15, ux A13 |
| Q9 | meeting ทั้งวัน (all-day) ได้ alert ไหม | ไม่ส่ง | code-gap A.9 EC-03 |
| Q10 | mobile / Lite ไม่มีหน้า Calendar | ส่ง toast ได้ แต่ซ่อนปุ่ม "Open / View Calendar" | X8 |
| Q11 | meeting ไม่ได้ผูกห้อง ("Any available meeting room") กด Join แล้วไปไหน | ปิด toast + เปิด Calendar ที่ meeting นั้น (ไม่เดินไปไหน) | code-gap A.3 HP02-3 |
| Q12 | แจ้งยกเลิก / เลื่อน ส่งให้ใคร | ทุกคนที่ได้รับเชิญ (ไม่ใช่เฉพาะคนที่ได้ alert ไปแล้ว) · ยกเลิกก่อนถึงเวลา alert = ไม่ส่ง 5 นาที / เริ่ม | spec §6 #13 |
| Q13 | กด Join บนการ์ดที่ meeting ถูกยกเลิกแล้ว | ไม่มีปุ่ม Join · กดการ์ด = เปิด Calendar ที่ meeting นั้น (เป็นขีดฆ่าตาม D1) | ux A17 |

---

## 4. API contract (ร่าง — ให้ dev ปรับได้ แต่ต้องอัปเดตเอกสารนี้)

### 4.1 DB — migration `122_meeting_alert` (+ `.down.sql`) + mirror ใน `postgres.go`

```sql
-- notification types (ต้องเพิ่มใน superset CHECK ของ postgres.go รอบเดียวกัน)
--   meeting_reminder | meeting_started | meeting_cancelled | meeting_rescheduled

ALTER TABLE tb_notification
  ADD COLUMN calendar_meeting_id   UUID NULL REFERENCES tb_calendar_meeting(id) ON DELETE SET NULL,
  ADD COLUMN meeting_start_at      TIMESTAMPTZ NULL,  -- snapshot ตอนส่ง (meeting อาจถูกลบ / เลื่อนทีหลัง)
  ADD COLUMN meeting_end_at        TIMESTAMPTZ NULL,
  ADD COLUMN meeting_prev_start_at TIMESTAMPTZ NULL,  -- เฉพาะ rescheduled / cancelled: เวลาเดิม
  ADD COLUMN meeting_prev_end_at   TIMESTAMPTZ NULL,
  ADD COLUMN meeting_superseded_at TIMESTAMPTZ NULL;  -- (ของจริง) set บน reminder / started เดิมเมื่อยกเลิก / เลื่อน → การ์ดเลิกแสดง Join

CREATE TABLE IF NOT EXISTS tb_meeting_alert_log (
  meeting_id       UUID        NOT NULL REFERENCES tb_calendar_meeting(id) ON DELETE CASCADE,
  user_id          VARCHAR     NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,  -- tb_user.id เป็น VARCHAR
  alert_type       TEXT        NOT NULL,  -- (ของจริง) reminder | started | cancelled | rescheduled
  meeting_start_at TIMESTAMPTZ NOT NULL,  -- Q3: อยู่ใน key → เลื่อนเวลาแล้วส่งใหม่ได้
  notification_id  UUID        NULL REFERENCES tb_notification(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (meeting_id, user_id, alert_type, meeting_start_at)
);

-- X4 (ตกลงแล้ว 2026-10-29): Alert เพิ่มคอลัมน์ · CAL-01 HP-05/06 เป็นคน set ทีหลัง
ALTER TABLE tb_calendar_meeting ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ NULL;
CREATE INDEX IF NOT EXISTS idx_calendar_meeting_start ON tb_calendar_meeting (start_at) WHERE cancelled_at IS NULL;
```

- เทส migration up → down → up กับ Postgres จริง (dev DB) ก่อนเปิด PR
- ชื่อ type / คอลัมน์ **ยังไม่ตกลง** — เปลี่ยนได้ แต่ต้องตรงกันทั้ง migration, `postgres.go`, `model.Notification`, `NotificationType` ฝั่ง app

### 4.2 Payload (`model.Notification` เพิ่ม field — ใช้ endpoint เดิมทั้งหมด)

```json
{
  "id": "…", "type": "meeting_reminder", "is_read": false, "created_at": "2026-10-30T02:55:04Z",
  "title": "Daily standup meeting",
  "body": "Design Room",
  "calendar_meeting_id": "…",
  "meeting_start_at": "2026-10-30T03:00:00Z", "meeting_end_at": "2026-10-30T03:30:00Z",
  "meeting_prev_start_at": null, "meeting_prev_end_at": null,
  "meeting_zone_id": "…",               // (ของจริง) ห้องปัจจุบันของ meeting — app ประกอบ /workspace/{ws}/play?zone_id= เอง
  "meeting_superseded_at": null
}
```

- `title` / `body` = **ข้อมูลดิบ** (ชื่อ meeting / ชื่อห้อง) — ข้อความ toast ("Meeting starts in 5 minutes", "10:00 · Design Room") ให้ฝั่ง app ประกอบจาก i18n + เวลา local ของ user (EC-03)
- **ไม่มี endpoint ใหม่** — list / read / read-all ใช้ `/api/user/notifications*` เดิม (UserGuard ✅ rule 15) · **ไม่มี WS event ใหม่** — ใช้ `vo:notify` → `chat:notification:new`
- (ถ้าจำเป็น) `GET /api/user/workspaces/:id/meetings/:meetingId` ให้ "Open Calendar" เปิด meeting ที่อยู่นอกช่วงที่โหลด

### 4.3 Service ที่ CAL-01 จะเรียกทีหลัง

```go
// NotifyMeetingChanged sends meeting_cancelled / meeting_rescheduled to every invited
// member and updates their earlier meeting rows so the card stops offering Join.
func (s *MeetingAlertService) NotifyMeetingChanged(ctx context.Context, in MeetingChange) error
```

- รอบนี้เรียกจาก Google inbound `reconcileOne` (`calendar_meeting_inbound.go`) — **ก่อน** hard delete (snapshot ชื่อ / เวลาเก็บใน row แล้ว · FK `ON DELETE SET NULL`)
- CAL-01 HP-05 / HP-06 เรียกตัวเดียวกันตอนยกเลิก / เลื่อนใน Zyra

---

## 5. PR (ลำดับแนะนำ — แตกจาก `develop` ทุกอัน ตาม rule 17)

| # | Repo | PR (conventional commit) | ขึ้นกับ | ไฟล์หลัก |
|---|---|---|---|---|
| API-1 | zyra-api | `feat(api): add meeting alert notification types and alert log` — migration 122 (+down) · `postgres.go` (CHECK superset + DDL) · `model.Notification` + `ListNotifications` SELECT | Q3 | `migrations/122_*.sql`, `internal/database/postgres.go`, `internal/model/chat.go`, `internal/service/notification_service.go` |
| API-2 | zyra-api | `feat(api): send 5-minute and start meeting alerts from a background loop` — `MeetingAlertService` + loop ใน `main.go` (tick 15–30 วิ, `context.WithTimeout`) · window EC-01 · settings gate · skip cancelled / all-day · `email_suppressed = true` · `ON CONFLICT DO NOTHING RETURNING` → publish `vo:notify` | API-1 | `internal/service/meeting_alert_service.go` (ใหม่), `main.go` |
| API-3 | zyra-api | `feat(api): notify members when a meeting is cancelled or rescheduled` — `NotifyMeetingChanged` + hook ใน Google inbound + UPDATE row เดิม + push ซ้ำ (แบบ `EndSpotlightLive`) | API-1 | `meeting_alert_service.go`, `calendar_meeting_inbound.go` |
| APP-1 | zyra-app | `feat(app): show meeting alert toasts` — variant เทา / ส้ม + body หลายบรรทัดใน `lib/toast.tsx` · `NotificationType` + fields · handler `chat:notification:new` (ใกล้ `hero-virtual-office.tsx:3883-3897`) · Later / Join meeting · i18n en + th | API-1 (ทำคู่ API-2 ได้โดย mock payload) | `lib/toast.tsx`, `lib/api/chat.ts`, `hero-virtual-office.tsx`, `messages/*.json` |
| APP-2 | zyra-app | `feat(app): open the calendar on a given meeting` — X1 (ตัด Google flag ออกจากการเปิด) + X2 (`focus` prop → Week + Event detail) · ต่อปุ่ม Open / View Calendar | APP-1 · **หลัง** PR `fix/calendar-popup-edges` (§2.1) | `vo-calendar.tsx`, `hero-virtual-office.tsx` |
| APP-3 | zyra-app | `feat(app): meeting cards in the notification panel` — การ์ด (icon กล้องตามสี, Join h24 เฉพาะยังไม่จบ, past, cancelled, rescheduled) · คลิก → Calendar วันนั้น · load-more | APP-2 | `vo-notification-panel.tsx` |
| APP-4 | zyra-app | `feat(app): bundle missed meeting alerts on return` — EP-01 toast "You missed N meetings" (row meeting ที่ยังไม่อ่าน + สร้างก่อนเข้า VO รอบนี้ — ให้ client ตัดสิน ไม่เชื่อ online flag ฝั่ง server, code-gap C.14) | APP-1 | `hero-virtual-office.tsx` หรือ hook ใหม่ |
| APP-5 | zyra-app | `fix(app): align event reminder setting copy with the 5-minute alert` | — | `messages/en.json`, `th.json` |
| DOC | zyra-doc | `plan/[Feature] Meeting —  Meeting Alert …/progress.md` ทุกรอบ + before / after (§7) | ทุก PR | — |

---

## 6. Test (rule 04 + กติกาทีม 80% ก่อนปรับ Completed)

**Go (table-driven, testify, mock DB ด้วย interface)** — `MeetingAlertService`:
- meeting เริ่มใน 5 นาที → ส่งให้ organiser + guest ครบ, `email_suppressed = true`
- tick ซ้ำ / 2 instance พร้อมกัน → ส่งครั้งเดียว (UNIQUE)
- สร้าง meeting เหลือ 3 นาที → ส่ง reminder ทันที · เหลือ 30 วิ → ส่ง started
- `event_reminders = false` → ไม่ส่ง reminder (แต่ยังส่ง started ถ้า `event_start` เปิด)
- meeting ยกเลิกก่อนถึงเวลา (`cancelled_at` / ถูกลบ) → ไม่ส่ง
- เลื่อนเวลาหลังส่งแล้ว → ส่ง rescheduled + ส่ง reminder ใหม่ตามเวลาใหม่ (ถ้า Q3 = ใช่)
- all-day → ไม่ส่ง

**Vitest (`vi.mock` ทุก API)** — handler `chat:notification:new` → `zyraToast` args ตาม type (สี, title, ปุ่ม, duration) · การ์ด panel ตามสถานะ · bundle EP-01 นับถูก

**ทดสอบมือบน dev (`app.dev.zyra.center`)** — 2 บัญชีในห้อง VO เดียวกัน:
1. สร้าง meeting เริ่มในอีก 6 นาที → รอ toast ฟ้า (จดเวลาจริง)
2. ถึงเวลาเริ่ม → toast เขียว → Join meeting พาไปห้อง
3. บัญชี B ออกจาก VO ก่อนเวลา แล้วกลับเข้า → toast "You missed …"
4. X / Later → toast หาย การ์ดยังอยู่ใน panel
5. ยิง alert หลายอันพร้อมกันบนจอ 1280×720 → toast ไม่ล้นจอ ([Display ux §12](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md#12-ขอบจอบัง--กดแล้วหาย--checklist-ตอนทำจริง-2026-10-29>))

---

## 7. Before / After (rule 18 — feature ใหญ่ multi-PR)

| Metric | Before | After |
|---|---|---|
| meeting alert ที่ส่งได้ | 0 (ไม่มีระบบ) | ยังไม่ได้วัด — วัดหลัง deploy dev |
| ความช้าของ reminder: `tb_notification.created_at − (meeting_start_at − 5 นาที)` p95 | — | ยังไม่ได้วัด · เป้า ≤ 30 วิ (HP-01) |
| ความช้าของ started: `created_at − meeting_start_at` p95 | — | ยังไม่ได้วัด · เป้า ≤ 60 วิ (HP-02) |
| ส่งซ้ำ: `SELECT calendar_meeting_id, user_id, type, meeting_start_at, count(*) … HAVING count(*) > 1` | — | ต้องเป็น 0 |
| อีเมลหลุด: row meeting ที่ `email_suppressed = false` | — | ต้องเป็น 0 |

---

## 8. ยังไม่ได้ตรวจ

- พฤติกรรม sonner เมื่อ toast 336px ซ้อนหลายใบ + การซ้อนกับ toast เฉพาะของ VO (wave / knock / spotlight ที่มุมขวาบนเหมือนกัน) — code-gap C.6
- นับคนในห้องฝั่ง server (ไม่ใช้แล้วตาม A3 — ข้ามได้)
- replicas ของ api บน origin `zyra-infra` ปัจจุบัน (ที่อ่านไว้เป็น checkout 2026-09-24)
