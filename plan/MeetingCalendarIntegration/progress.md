# SC-MTG-CAL-01 · Meeting — Calendar Integration · Progress

> entry ใหม่อยู่**บนสุด** · แยก "test ผ่าน" ออกจาก "live-test กับ Google จริงผ่าน" ให้ชัดทุกครั้ง

## รอบที่ 2 — 2026-10-21 · CLDI-HP-03 สร้าง Zyra Meeting แล้ว Sync ไป Google (implement แล้ว · ยังไม่ commit · ยังไม่ live-test)

**ขอบเขต (ตกลงกับผู้ใช้ 2026-10-21 ก่อนลงมือ)** — ดู [spec §9](spec.md#9-decision-log)

| เรื่อง | ตัดสินใจ |
|---|---|
| Provider | **Google ก่อน** — Outlook (HP-02) ยังไม่ทำ → AC-HP03-2 ค้าง · โครง (`google_sync_status`, pusher interface) ต่อ Outlook ได้ |
| UI | **ครบตาม Figma** section `3583:77760`: Schedule event ทุก field + Event details + toast สำเร็จ/sync ล้มเหลว + My calendar + สร้างจากปุ่ม + และคลิกช่องเวลาใน full view + เลือกหลายวัน |
| Location / join link | เลือกห้อง → `${APP_URL}/workspace/{ws}/play?zone_id={zone}` (deep link เดิมที่เดินไปห้องให้) · "Any available meeting room" → `/workspace/{ws}/play` (เข้า workspace เฉยๆ) |
| Retry | **Sync now ใน full view** re-push meeting ที่ `failed` และยังไม่จบ · ไม่มี background worker |

ภาพอ้างอิงที่ผู้ใช้ export: `zyra/CLDI-HP-03 · สร้าง Zyra Meeting แล้ว Sync ไป Calendar ภายนอก/` (21 ภาพ) · ค่าทุกตัวดึงจาก Figma MCP ([ux-ui.md §11](ux-ui.md#11-hp-03-ค่าที่ดึง-2026-10-21-และที่-implement))

### ทำอะไรแล้ว

**zyra-api** (branch `feat/calendar` · uncommitted)
- `migrations/117_calendar_meeting.sql` (+down) — `tb_calendar_meeting` (workspace, organizer, title, description, start/end, all_day, time_zone, zone_id `ON DELETE SET NULL`, location_name, guest permissions 3 ตัว, `google_event_id`/`google_html_link`/`google_sync_status` none|synced|failed) + `tb_calendar_meeting_guest`
- `internal/model/calendar_meeting.go` · `internal/service/calendar_meeting_store.go` (SQL) · `internal/service/calendar_meeting_service.go` — validate (title ≤200, description ≤5000, IANA tz, end>start, ≤62 วัน, guest ≤100 และต้องเป็นสมาชิก workspace, zone ต้องเป็น meeting zone ของ workspace) → บันทึกก่อน → push Google (timeout 8 วิ) → บันทึกผล · push ล้มเหลวไม่ทำให้ create ล้ม (AC-HP03-4)
- `calendar_google_client.go` — `InsertEvent` (`POST /calendars/primary/events?sendUpdates=all` → Google ส่ง invite ให้ guest) · body มี join link ใน description (AC-HP03-3), attendees = email guest, `guestsCan*` ตาม Permission, `extendedProperties.private.zyra_meeting_id`
- `calendar_integration_service.go` — `InsertEvent(userID, ev)` ใช้ token เดิม (refresh/needs_reauth แบบ HP-01)
- `internal/handler/calendar_meeting_handler.go` + route ใน `router.go` (ลงทะเบียนเสมอ ไม่ขึ้นกับ `GOOGLE_CALENDAR_ENABLED`) + wiring `main.go`

**zyra-app** (branch `feat/calendar` · uncommitted)
- `lib/api/calendar-meetings.ts` — create/list/sync + `meetingToEvent` (My calendar = `zyra:my-calendar`)
- `components/calendar/use-calendar-data.ts` — โหลด meeting ของ workspace ทุกครั้ง (ไม่ต้อง connect Google) รวมกับ Google · ซ่อน Google event ที่ id ตรงกับ `google_event_id` ของ meeting (กันซ้ำ) · Sync now = `POST meetings/sync` แล้วอ่านใหม่
- `calendar-schedule-event.tsx` (ใหม่) — Schedule event modal + dropdown วัน/เวลา/ห้อง/guest + Permission + Discard modal
- `calendar-event-details.tsx` (ใหม่) — Event details + Join + copy link
- `use-meeting-rooms.ts` (ใหม่) — meeting zone ทุกชั้นของ workspace (`listMaps` + `listZones`)
- `vo-calendar.tsx` — ปุ่ม + (เปิด), My calendar ใน Calendar list, การ์ด/chip ของ Zyra meeting กดเปิด Event details, toast สำเร็จ / caution "Calendar sync failed"
- `calendar-main-view.tsx` — คลิกช่องว่างใน Day/Week grid → modal ข้างช่อง + draft chip "No title" · `calendar-parts.tsx` — `CalendarDraftChip`, chip/การ์ดกดได้ · `calendar-mini-month.tsx` — `rangeEnd`
- `hero-virtual-office.tsx` — ส่ง workspaceId, user id, สมาชิก, จำนวนคนในห้อง (`zoneSections.present_count`), `joinCalendarMeeting` (reuse `openMeetingLink`)
- i18n `Calendar.*` เพิ่ม 39 key (en/th)

### Verify แล้ว

| Check | ผล |
|---|---|
| zyra-api `go build ./...` · `go vet ./...` · `gofmt -l` (ไฟล์ที่แก้) | ผ่าน |
| zyra-api `go test ./... -count=1` | ผ่านทั้ง repo |
| zyra-api test ใหม่: service (validate 14 กรณี, push สำเร็จ+payload, all-day, ผล Google 5 แบบ, list, sync now, InsertEvent+needs_reauth) · client `InsertEvent` (httptest + error mapping) · handler · route | ผ่าน |
| migration 117 up → down → up + SQL ทุก method ของ store กับ **Postgres 16 จริง** (container ชั่วคราว, test ชั่วคราวลบแล้ว) | ผ่าน |
| zyra-app eslint + prettier (ไฟล์ calendar ทั้งหมด + test) | ผ่าน |
| zyra-app vitest: `vo-calendar-meetings` (ใหม่ 12 case) + `vo-calendar`, `calendar-dates`, `calendar-integration-api`, `google-calendar-connect` | 40/40 ผ่าน |

### อัปเดต 2026-10-21 (บ่าย) — ทดสอบกับ Google จริงบน dev

- Push ล้มเหลวรอบแรก: `.env` ตั้ง `GOOGLE_CALENDAR_SCOPES` เป็น readonly → Google ปฏิเสธ insert · ผู้ใช้เอาบรรทัดออก + reconnect + Sync now → meeting 3 รายการ `synced` (ตรวจใน DB)
- แก้โค้ด: connect ต้องได้ calendar scope ครบตามที่ขอ (ไม่งั้น `scope_missing`) · `InsertEvent` เช็ก `calendar.events` ก่อนเรียก Google → `ErrCalendarScopeMissing` · Google 403 แยก scope ไม่พอ / rate limit · API ส่ง `google_reconnect_required` / `reconnect_required` · app แสดง toast ให้ไป reconnect (ข้อความ `pushReconnectBody` **ไม่มีใน Figma**) · test ผ่าน (api service/handler/router, app vitest 41/41)
- Full view เปิดที่ **Month** เป็นค่าเริ่มต้น (ผู้ใช้ขอ — Figma วาด Week)
- ลบ event ใน Google แล้ว Zyra meeting ยังอยู่ → ผู้ใช้ตัดสิน "ทุกอย่างต้องเหมือนกันทั้งสองฝั่ง" (ดู spec §9) · ทำ **Google → Zyra**: `calendar_meeting_inbound.go` — ทุกครั้งที่ list meetings (เปิด/เลื่อน Calendar, Sync now) อ่าน Google event ของ meeting ที่ `synced` ด้วย token ของ organizer (ไม่เกินทุก 20 วิ/meeting, พร้อมกัน ≤5) · ถูกลบ (cancelled/404/410) → ลบ meeting ใน Zyra (หายจาก guest ด้วย) · ถูกแก้ → title, description (ตัด HTML + บรรทัด "Join in Zyra"), เวลา/all-day, location (จับคู่ชื่อห้อง ไม่ตรง = any + ข้อความ), guest (สมาชิก workspace ตาม email), permission · อ่าน Google ไม่ได้ → ไม่แตะ · app ทิ้ง meeting ที่สร้างในหน้าแล้วถูกลบไปเมื่อ read ถัดไป · **Zyra → Google (แก้/ลบ, EC-04) ยังไม่ทำ** (ไม่มี UI/Figma)
- Verify: service test ใหม่ 6 (ลบ, แก้, ห้อง+all-day, error ไม่แตะ, throttle 20 วิ, description) · client `GetEvent` + 410 · store method ใหม่ 4 ตัวกับ Postgres 16 จริง · `go test ./...` ผ่าน · app vitest 19/19 (calendar meeting + panel)

### ยังไม่ได้ verify / เหลือ

- AC-HP03-1 (≤10 วิ) / invite ถึง guest ยังไม่ได้วัด/ยืนยันกับ Google จริงอย่างเป็นทางการ — AC-HP03-1 (≤10 วิ) / AC-HP03-3 / invite ถึง guest ผ่านแค่ unit test
- ยังไม่ได้เปิดดูใน browser จริง
- **AC-HP03-2 (Outlook)** ค้างจนกว่าจะทำ HP-02
- migration 117 ใส่ใน auto-migrate (`internal/database/postgres.go` slice `migrations`) แล้ว 2026-10-21 — รอบแรกลืมใส่ ทำให้ `/meetings` ตอบ 500 (ตารางไม่มี) · เพิ่ม 115/116 (HP-01) เข้า slice ด้วย — ตรวจแล้วรันซ้ำได้ทั้งบน DB ที่เคยรันมือไว้และ DB ใหม่ (Postgres 16 ชั่วคราว)
- ไอคอน Calendar ใน sidebar ยังเปิด panel เฉพาะเมื่อ API เปิด Google Calendar (`GOOGLE_CALENDAR_ENABLED`) ตาม HP-01 — ถ้าปิด จะสร้าง meeting ไม่ได้จาก UI แม้ API ของ meeting พร้อม
- ไม่ได้ทำ: แก้/ลบ meeting (EC-04), RSVP ใน Zyra, push meeting เก่าตอน connect (AC-HP01-5), mobile
- สิ่งที่ต่างจาก/ไม่มีใน Figma ดู [ux-ui.md §11.3](ux-ui.md#113-สิ่งที่ต่างจาก-figma--ตัดสินใจเอง-รอ-designpm-ยืนยัน)

## รอบที่ 1 — 2026-10-20 · CLDI-HP-01 Connect Google Calendar (implement แล้ว · ยังไม่ commit · ยังไม่ live-test)

**ขอบเขต (ตกลงกับผู้ใช้ 2026-10-20 ก่อนลงมือ)** — ดู [spec §9](spec.md#9-decision-log)

| เรื่อง | ตัดสินใจ |
|---|---|
| API base | merge งาน N2Pluto (`origin/feat/calendar-google-integration` · `05f8e1d` migration 115 + เข้ารหัส token + config) เข้า `feat/calendar` แล้วทำต่อ |
| Calendar UI | ทำ half view + full view ครบ แต่**แสดงเฉพาะ Google** — ไม่มี "My calendar" / ปุ่ม + สร้าง (ยังไม่มี scheduled meeting · Q1) · Thai Holidays ดึงจาก Google holiday calendar หลัง connect |
| Sync model | ดึงสดจาก Google ผ่าน zyra-api ทุกครั้งที่เปิด/เลื่อนช่วง/กด Sync now — ไม่มีตาราง event, ไม่มี worker |
| Scope | `calendar.readonly` + `calendar.events` ตาม ClickUp (+ `openid email profile` สำหรับชื่อบนการ์ด) |

### ทำอะไรแล้ว

**zyra-api** (branch `feat/calendar` · uncommitted — ผู้ใช้ commit เอง)
- รับงาน N2Pluto เป็น uncommitted (เดิม merge แล้วได้ merge commit ในเครื่อง → ถอยออกตามที่ผู้ใช้ขอ "ไม่ต้อง commit")
- `migrations/116_user_calendar_integration_name.sql` (+down) — `provider_name` สำหรับชื่อบัญชี Google บนการ์ด
- `internal/config/calendar.go` — scope ค่าเริ่มต้นเป็นชุด ClickUp
- `internal/service/calendar_google_client.go` — token/refresh/userinfo/calendarList/events (แบ่งหน้า, `singleEvents`)/revoke ด้วย `net/http` · map 401/`invalid_grant` → `ErrCalendarReauthRequired`, 429/5xx → `ErrCalendarProviderUnavailable`, 404 → ข้าม calendar นั้น
- `internal/service/calendar_integration_store.go` — SQL ของ `tb_user_calendar_integration`
- `internal/service/calendar_integration_service.go` — state JWT (HS256, 10 นาที, ผูก nonce ใน cookie httpOnly) · callback · cache access token + refresh · `needs_reauth` · calendars (primary ก่อน + เติม Thai Holidays) · events (≤62 วัน, ≤20 calendars, ตัด cancelled) · disconnect (revoke แบบ best effort)
- `internal/handler/calendar_integration_handler.go` + route ใน `router.go` + wiring ใน `main.go` (ลงทะเบียนเฉพาะ `GOOGLE_CALENDAR_ENABLED=true` และ config ครบ)

**zyra-app** (branch `feat/calendar` · uncommitted)
- `lib/api/calendar-integration.ts`, `stores/calendar-integration-store.ts`, `hooks/use-google-calendar-connect.ts` (popup + storage event)
- `app/integrations/google/callback/page.tsx` → `views/integrations/google-calendar-callback.tsx` (หน้า popup ปลายทาง)
- `lib/calendar/calendar-dates.ts` (date maths ไม่มี library)
- `views/user/virtual-office/components/calendar/*` — panel, mini calendar, upcoming, calendar list, banner, full view (Day/Week/Month, Sync now)
- `vo-setting-modal.tsx` — Integrations: การ์ด connected (avatar Zyra + ชื่อ/อีเมล Google) + Disconnect · Outlook ยัง coming soon · บน phone drawer ยัง coming soon
- `hero-virtual-office.tsx` — `calendarView` (closed/half/full) ช่องเดียวกับ Chat · ไอคอน Calendar เปิด panel เมื่อ API เปิดฟีเจอร์ (ไม่งั้นยังเป็น toast coming soon)
- i18n `VirtualOffice.integration*` เพิ่ม 6 key + namespace ใหม่ `Calendar` (en/th)

### Verify แล้ว

| Check | ผล |
|---|---|
| zyra-api `go build ./...` · `go vet ./...` · `gofmt -l` | ผ่าน / ไม่มีไฟล์ค้าง |
| zyra-api `go test ./... -count=1` | ผ่านทั้ง repo (exit 0) |
| zyra-api test ใหม่: service (connect URL, state ผิด/หมดอายุ/คนละ browser, denied, scope ไม่ครบ, ไม่มี refresh token, connect สำเร็จ+token ถูกเข้ารหัส, cache/refresh/needs_reauth, calendars, events, disconnect) · client (httptest) · handler · route flag | ผ่าน |
| migration 115+116 up/down + SQL ของ store กับ **Postgres 16 จริง** (container ชั่วคราว, ลบแล้ว) | ผ่าน |
| zyra-app `tsc --noEmit` | ไม่มี error ในไฟล์ที่แก้ (มี error เดิม 3 ไฟล์ test ที่ไม่เกี่ยว: `environment-weather-fx`, `pet-creation-wizard`, `pixi-game-scene`) |
| zyra-app eslint (ไฟล์ที่แก้ทั้งหมด) · prettier | ผ่าน |
| zyra-app vitest ใหม่: `calendar-dates`, `calendar-integration-api`, `google-calendar-connect`, `vo-calendar` | ผ่าน |

### ยังไม่ได้ verify / เหลือ

- **ยังไม่ได้ live-test กับ Google จริง** — ต้องมี OAuth client + env ก่อน (ดูด้านล่าง) · AC-HP01-1/2/3/4 ผ่านในระดับ unit test เท่านั้น
- ยังไม่ได้เปิดดูใน browser จริง (ต้องมี API + DB + login) — layout เทียบจาก Figma `get_design_context` เท่านั้น
- **AC-HP01-5 (push Zyra meeting ที่มีอยู่ไป Google) ทำไม่ได้** — ยังไม่มี scheduled meeting (Q1)
- ขั้น 8 "calendar selector" — ทำเป็น Calendar list ใน panel (Figma ไม่มี selector ใน Settings · U3)
- Disconnect กดแล้วตัดเลย ยังไม่มี confirm modal/toast (เป็นของ HP-04)
- Month view และ Day view **ไม่มี Figma frame** — ประกอบจาก token เดียวกับ Week (ux-ui.md §5.6)
- migration 115/116 เป็นไฟล์ให้รันมือ ยังไม่ได้ใส่ใน list auto-migrate ของ `internal/database/postgres.go` (ตาม 111–115 ที่ก็ไม่ได้ใส่)
- เอกสาร `zyra-doc/plan/CalendarIntegration` ที่ commit `05f8e1d` อ้างถึง **ไม่มีใน zyra-doc** — ต้องถาม N2Pluto ว่ามีอยู่ที่ไหน แล้วรวมกับโฟลเดอร์นี้

### ต้องตั้งค่าก่อน live-test (zyra-api)

| env | ค่า |
|---|---|
| `GOOGLE_CALENDAR_ENABLED` | `true` |
| `GOOGLE_CALENDAR_CLIENT_ID` / `_SECRET` | OAuth client (Web) ที่เปิด Google Calendar API แล้ว — แยกจาก client ของ login |
| `GOOGLE_CALENDAR_REDIRECT_URL` | `${APP_URL}/api/integrations/google/callback` (**ต้องเป็นโดเมนของ app** เพราะ cookie nonce ถูกตั้งผ่าน rewrite `/api` ของ Next) และต้องลงทะเบียนใน GCP ตรงตัว |
| `GOOGLE_CALENDAR_STATE_KEY` | สุ่ม ≥ 32 ตัวอักษร |
| `CALENDAR_TOKEN_ENC_KEY` | base64 ของ 32 bytes (`openssl rand -base64 32`) |
| `APP_URL` | URL ของ zyra-app (ใช้สร้าง redirect กลับเข้า app) |

แล้วรัน `migrations/115_…sql` + `116_…sql` · Calendar scopes เป็น sensitive → production ต้องผ่าน Google OAuth verification (Q8)
