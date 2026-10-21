# SC-MTG-CAL-01 · Meeting — Calendar Integration · Progress

> entry ใหม่อยู่**บนสุด** · แยก "test ผ่าน" ออกจาก "live-test กับ Google จริงผ่าน" ให้ชัดทุกครั้ง

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
