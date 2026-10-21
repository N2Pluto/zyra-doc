# SC-MTG-CAL-01 · Meeting — Calendar Integration (Google Calendar + Microsoft Outlook)

> **สถานะ (2026-10-21):** **HP-01 + HP-03 implemented (Google only) — ยังไม่ commit · ยังไม่ live-test กับ Google จริง** · scenario อื่นยังไม่ทำ · ดู [progress.md](progress.md) และ [§9 Decision log](#9-decision-log)
> **วันที่ถอด:** 2026-10-12 · **ClickUp:** [[Feature] Meeting — Calendar Integration](https://app.clickup.com/t/86d3nbcrq) (`pending` · priority High · tag `client` · assignee Ponlawat Lueakaew · creator Moss Pm)
> **Repo ที่กระทบ (คาด):** `zyra-app` (Integrations tab, calendar view, OAuth popup) · `zyra-api` (OAuth code exchange, token storage, sync worker, event push, notification type) · `zyra-ws` (อาจใช้ relay `vo:notify` ที่มีอยู่ — ยังไม่ยืนยัน) · `zyra-notifications` (เฉพาะถ้า EP-02 ต้องส่ง email — ยังไม่ยืนยัน)
> **โครงเอกสาร:** §1–§4 = requirement ต้นทางจาก ClickUp/Figma (ถอดตามที่เขียน ไม่แต่งเติม) · §5 = current implementation (ตรวจโค้ดจริง 2026-10-12) · §6 = gap · §7 = ข้อขัดแย้ง/คำถาม · §8 = ข้อเสนอของ Agent (ยังไม่ใช่ decision)
> **ข้อสังเกตสำคัญ:** ใน Zyra **ยังไม่มี "scheduled meeting" (meeting ที่มีชื่อ/เวลา/attendees) และยังไม่มีหน้า Calendar** — มีแค่ meeting zone แบบ realtime ใน VO · แต่ HP-01/HP-03/EC-04 อ้างถึง "Zyra meeting ที่สร้าง" และ Figma วาดหน้า Calendar ไว้ → ดู [Q1](#q1-blocker--scheduled-meeting--calendar-view-อยู่ใน-scope-นี้หรือไม่)

---

## 1. Overview (จาก ClickUp parent)

**Module:** Meeting Module — Project Zyra
**Persona:** Workspace Member (user แต่ละคน connect เอง)

User เชื่อมต่อ Google Calendar หรือ Microsoft Outlook ของตัวเองกับ Zyra เพื่อให้ events จากทั้งสองแหล่ง sync เข้า Zyra ได้อัตโนมัติ และเมื่อสร้าง Zyra meeting ก็ sync กลับไปยัง calendar ภายนอก

### User Stories

```
As a Workspace Member
I want to connect my Google Calendar / Outlook to Zyra
So that I can see all my meetings in one place without switching apps

As a Workspace Member
I want Zyra meetings I create to sync to my external calendar
So that colleagues who use Google/Outlook can also see them
```

### Source links

| แหล่ง | ลิงก์ |
|---|---|
| ClickUp parent | [[Feature] Meeting — Calendar Integration](https://app.clickup.com/t/86d3nbcrq) |
| Figma file | `Map8gX0L2hk7HnkaFRfhtj` — Zyra design (More Organised ver.) · node ต่อ scenario ดู §2 |
| ClickUp comments | ไม่มี (ตรวจ 2026-10-12) |

---

## 2. Scope & Scenario Index (7 subtasks + 4 edge cases)

| # | Scenario | Type | ClickUp status | ClickUp | Figma node |
|---|---|---|---|---|---|
| HP-01 | Connect Google Calendar สำเร็จ | Happy Path | **in progress** | [CLDI-HP-01](https://app.clickup.com/t/86d3nf00n) | `3237-609135` |
| HP-02 | Connect Microsoft Outlook สำเร็จ | Happy Path | **in progress** | [CLDI-HP-02](https://app.clickup.com/t/86d3nf08e) | `3301-5048` |
| HP-03 | สร้าง Zyra Meeting แล้ว Sync ไป Calendar ภายนอก | Happy Path | pending | [CLDI-HP-03](https://app.clickup.com/t/86d3nf0c9) | `3583-77760` |
| HP-04 | Disconnect Calendar | Happy Path | pending | [CLDI-HP-04](https://app.clickup.com/t/86d3nf0gc) | `3601-762611` |
| EP-01 | User ปฏิเสธ OAuth Consent | Error Path | pending | [CLDI-EP-01](https://app.clickup.com/t/86d3nf0n6) | `3601-766158` |
| EP-02 | Token หมดอายุ / Revoked | Error Path | pending | [CLDI-EP-02](https://app.clickup.com/t/86d3nf0qe) | `3601-769864` |
| EP-03 | Sync ล้มเหลว (Rate Limit / Server Error) | Error Path | pending | [CLDI-EP-03](https://app.clickup.com/t/86d3nf0vv) | `3602-834434` |
| EC-01 ~ EC-04 | Edge cases (อยู่ใน parent task) | Edge Case | — | parent | — |

> HP-01/HP-02 ถูกเปลี่ยนเป็น `in progress` ใน ClickUp วันที่ 2026-10-12 แต่ **ยังไม่มีโค้ดหรือ branch ที่เกี่ยวกับ calendar ใน repo ใดเลย** (ตรวจ 2026-10-12 — ดู §5)

**In scope (ตาม ClickUp):** connect/disconnect Google + Outlook ต่อ user · sync event ภายนอกเข้า Zyra · push Zyra meeting ออกไป calendar ภายนอก · จัดการ consent ถูกปฏิเสธ / token หมดอายุ / sync ล้มเหลว

**Out of scope (ClickUp ไม่ได้พูดถึง — ห้ามเติมเอง):** calendar อื่น (Apple/iCloud, CalDAV), การแก้ไข event ภายนอกจากใน Zyra, recurring event rules, การจองห้อง (room resource), admin-level/workspace-level integration

**Scope ที่ยังไม่ชัด:** การสร้าง scheduled meeting และหน้า Calendar view เอง — ดู [Q1](#q1-blocker--scheduled-meeting--calendar-view-อยู่ใน-scope-นี้หรือไม่)

---

## 3. Subtask Detail (ถอดจาก ClickUp ครบทุก task)

### HP-01 · Connect Google Calendar สำเร็จ

**Pre-condition:** User login Zyra แล้ว ยังไม่ได้เชื่อมต่อ calendar ใดๆ

**Scenario Steps**
1. User เข้า Workspace Settings → Integrations → Calendar
2. กด **"เชื่อมต่อ Google Calendar"**
3. Popup Google OAuth consent screen เปิด — ไม่ redirect ออกจาก Zyra
4. User เลือก Google account และ approve scopes: `calendar.readonly` + `calendar.events`
5. Popup ปิด กลับ Zyra อัตโนมัติ
6. calendars sync อัตโนมัติ
7. Toast: "เชื่อมต่อ Google Calendar สำเร็จ — กำลัง sync events..."
8. Zyra แสดง calendar selector: รายชื่อ Google Calendars (Primary, Work, Personal ฯลฯ) — *Optional*

**Acceptance Criteria**
- [ ] AC-HP01-1 OAuth popup เปิดเป็น popup window — ไม่ redirect tab หลัก
- [ ] AC-HP01-2 Connected badge แสดงบน Google Calendar section ใน Settings
- [ ] AC-HP01-3 Events จาก Google sync เข้า Zyra ภายใน **30 วินาที**
- [ ] AC-HP01-4 Token เก็บ server-side encrypted — ไม่ปรากฏใน localStorage / URL
- [ ] AC-HP01-5 Zyra meetings ที่มีอยู่ถูก push ไปสร้างใน Google Calendar อัตโนมัติ

**Figma (sticky note ใน section `3237-609135`, ถอด 2026-10-12)**
- frame: `Intergration Setting` ×5 (ขั้น connect + Toast สำเร็จ), `Calendar - Half view` ×3, `Chat - Full view` ×2
- "Upcoming meeting จะโชว์แค่ของวันนั้นเท่านั้น"
- "เข้ามาครั้งแรกและมี Banner ให้ Add integration สามารถกากบาทออกได้"
- "Calendar list ถ้ายังไม่เชื่อม Integration จะมีแต่ My Calendar = Meeting ที่เราสร้าง, Thai holidays"

### HP-02 · Connect Microsoft Outlook สำเร็จ

**Pre-condition:** User login Zyra แล้ว ยังไม่ได้เชื่อมต่อ Outlook

**Scenario Steps**
1. User เข้า Settings → Integrations → Calendar
2. กด **"เชื่อมต่อ Microsoft Outlook"**
3. Popup Microsoft OAuth เปิด (scope: `Calendars.ReadWrite`)
4. User login Microsoft account และ approve
5. Popup ปิด กลับ Zyra
6. Zyra แสดง calendar selector ของ Outlook
7. User เลือก calendars และกด "บันทึก"

**Acceptance Criteria**
- [ ] AC-HP02-1 Connected badge แสดงบน Outlook section
- [ ] AC-HP02-2 User สามารถ connect ทั้ง Google + Outlook พร้อมกันได้ — ไม่ conflict
- [ ] AC-HP02-3 Events จาก Outlook sync เข้า Zyra ภายใน **30 วินาที**

**Figma:** `3301-5048` — ยังไม่ได้ถอดรายละเอียด (Figma MCP ติด rate limit 2026-10-12)

### HP-03 · สร้าง Zyra Meeting แล้ว Sync ไป Calendar ภายนอก

**Pre-condition:** User connect Google + Outlook แล้ว

**Scenario Steps**
1. User สร้าง meeting ใน Zyra (ชื่อ, เวลา, ห้อง, attendees)
2. ระบบ auto-create event ใน Google Calendar และ Outlook
3. Event มี: ชื่อ, เวลา, description, Zyra meeting join link
4. Attendees ได้รับ calendar invite จาก Google / Outlook (ถ้า email ตรงกัน)

**Acceptance Criteria**
- [ ] AC-HP03-1 Event ปรากฏใน Google Calendar ภายใน **10 วินาที**
- [ ] AC-HP03-2 Event ปรากฏใน Outlook ภายใน **10 วินาที**
- [ ] AC-HP03-3 Zyra join link แนบใน description ของ calendar event ภายนอก
- [ ] AC-HP03-4 ถ้า sync ล้มเหลว: Zyra meeting ยังสร้างสำเร็จ พร้อม toast warning

**Figma:** `3583-77760` — ถอดและ implement แล้ว 2026-10-21 → [ux-ui.md §11](ux-ui.md#11-hp-03-ค่าที่ดึง-2026-10-21-และที่-implement)

**สถานะ AC (2026-10-21, unit test เท่านั้น — ยังไม่ live-test):** AC-HP03-1 push ทันทีตอนสร้าง (timeout 8 วิ) · **AC-HP03-2 ค้าง (Outlook ยังไม่มี — HP-02)** · AC-HP03-3 join link อยู่ท้าย description · AC-HP03-4 meeting บันทึกก่อน push เสมอ + toast "Calendar sync failed" + Sync now

### HP-04 · Disconnect Calendar

**Pre-condition:** User connect Google Calendar แล้ว

**Scenario Steps**
1. User เข้า Settings → Integrations → กด **"ยกเลิกการเชื่อมต่อ"** ถัดจาก Google
2. Confirmation: "ยกเลิกการเชื่อมต่อ Google Calendar? Events จาก Google จะไม่แสดงใน Zyra"
3. User กด "ยกเลิกการเชื่อมต่อ"
4. Token revoke + synced Google events ลบออกจาก Zyra

**Acceptance Criteria**
- [ ] AC-HP04-1 Google events หายออกจาก Zyra ทันทีหลัง disconnect
- [ ] AC-HP04-2 Token revoke ยืนยันได้ผ่าน Google Account → Security
- [ ] AC-HP04-3 Zyra meetings ที่เคย push ไป Google: **ยังอยู่ใน Google** (ไม่ลบ)
- [ ] AC-HP04-4 Settings badge เปลี่ยนเป็น "ไม่ได้เชื่อมต่อ" + ปุ่ม "เชื่อมต่อ"

**Figma:** `3601-762611` — ยังไม่ได้ถอด (rate limit)

### EP-01 · User ปฏิเสธ OAuth Consent

**Trigger:** User กด "ยกเลิก" หรือ "Deny" ใน OAuth popup

**Steps**
1. Popup ปิด
2. Error banner: "การเชื่อมต่อถูกยกเลิก — กรุณาอนุมัติสิทธิ์เพื่อ sync calendar"
3. ปุ่ม "ลองใหม่"

**Acceptance Criteria**
- [ ] AC-EP01-1 ไม่มี token เก็บในระบบ
- [ ] AC-EP01-2 ไม่มี crash หน้า Settings
- [ ] AC-EP01-3 "ลองใหม่" เปิด OAuth popup ใหม่ทันที
- [ ] AC-EP01-4 Banner หายเองหลัง 10 วินาที หรือเมื่อกด X

**Figma (`3601-766158`):** frame `Intergration Setting` ×4 + frame สุดท้ายมี instance **`Toast`** (336×94) — ดู [Q11](#q11--ep-01-banner-หรือ-toast)

### EP-02 · Token หมดอายุ / Revoked

**Trigger:** User revoke Zyra access ใน Google Account settings โดยตรง

**Steps**
1. Zyra refresh token → `401 Unauthorized`
2. Mark status = `expired`
3. Notification: "การเชื่อมต่อ Google Calendar หมดอายุ กรุณาเชื่อมต่อใหม่"
4. Settings badge "หมดอายุ" สีเหลือง + ปุ่ม "เชื่อมต่อใหม่"

**Acceptance Criteria**
- [ ] AC-EP02-1 Calendar ยังแสดง events เดิม (stale) — ไม่ blank ทันที
- [ ] AC-EP02-2 Warning icon บน calendar header + tooltip
- [ ] AC-EP02-3 Notification ส่ง **1 ครั้ง** ไม่ spam
- [ ] AC-EP02-4 "เชื่อมต่อใหม่" ไม่ต้อง re-enter email

**Figma (`3601-769864`):** frame `Idle UI`, `Calendar - Expired token` ×3 (Calendar half view, Chat full view, Integration Setting + `Tooltips` 285×46) · sticky: "กดที่ข้อความ Warning หรือ ไปที่ Setting menu"

### EP-03 · Sync ล้มเหลว (Rate Limit / Server Error)

**Trigger:** API ตอบ `429` หรือ `500`

**Steps**
1. Retry exponential backoff: **30s → 2m → 5m**
2. หลัง 3 ครั้ง: warning badge บน header
3. Warning: "⚠ Events อาจไม่อัปเดต — [ลองใหม่]"

**Acceptance Criteria**
- [ ] AC-EP03-1 Calendar ยังใช้งานได้ด้วย stale data
- [ ] AC-EP03-2 Zyra meetings ไม่ได้รับผลกระทบ
- [ ] AC-EP03-3 Warning badge หายหลัง sync สำเร็จ

**Figma:** `3602-834434` — ยังไม่ได้ถอด (rate limit)

---

## 4. Edge Cases (จาก parent task)

| # | Case | Expected Behavior |
|---|---|---|
| EC-01 | Disconnect แล้ว Reconnect | Sync 30 วันย้อนหลัง + อนาคต, ไม่ duplicate event |
| EC-02 | Google Calendars > 10 อัน | Scrollable list + search, default = Primary เท่านั้น |
| EC-03 | Push Zyra Meeting ล้มเหลว | Meeting ยังสร้างสำเร็จ, toast "ลองใหม่" |
| EC-04 | ลบ Zyra Meeting ที่ Sync แล้ว | Auto-delete Google event ใน 10 วิ, Zyra state ชนะถ้า fail |

---

## 5. Current Implementation (ตรวจโค้ดจริง 2026-10-12)

### 5.1 Git state

| Repo | Branch ปัจจุบัน | Branch/commit เกี่ยวกับ calendar |
|---|---|---|
| zyra-api | `develop` | ไม่มี |
| zyra-app | `feat/vo-meeting-pip` | ไม่มี |
| zyra-ws | `feat/spotlight` | ไม่มี |
| zyra-notifications | `feat/spotlight` | ไม่มี |

### 5.2 สิ่งที่มีอยู่แล้ว

| เรื่อง | สถานะ | ที่อยู่ |
|---|---|---|
| Integrations tab (UI stub) | มี row Google Calendar + Outlook พร้อมปุ่ม Connect → แค่ toast "coming soon" · ยังไม่มีสถานะ connected/expired/disconnect | `zyra-app/views/user/virtual-office/components/vo-setting-modal.tsx:916-989` (comment: *"No calendar-OAuth backend yet"*) · logo `public/image/integrations/{google-calendar,outlook}.png` · i18n `VirtualOffice.integration*` ใน `messages/{en,th}.json` |
| ที่อยู่ของ Integrations tab | อยู่ใน **VO Setting modal (ราย workspace)** tab `integrations` ไม่ได้ gate ตาม role · **ไม่มีหน้า "Workspace Settings" แยก** | `vo-setting-modal.tsx:993-1014` (tabs), `:1336` (desktop), `:1506` (phone) |
| Calendar ใน sidebar | ไอคอนมีแล้ว กดแล้วขึ้น toast "coming soon" | `zyra-app/views/user/virtual-office/components/vo-sidebar.tsx:85` · `hero-virtual-office.tsx:4665-4668` |
| Google login | identity อย่างเดียว (implicit flow `id_token`, scope `openid email profile`) · popup → opener ส่งผลผ่าน localStorage · **ไม่เก็บ Google access/refresh token** | `zyra-app/app/login/google/page.tsx`, `app/login/google/callback/page.tsx` · `zyra-api/internal/service/auth_service.go:246-377` |
| Encryption-at-rest helper | **ไม่มี** (ไม่มี AES/GCM ใน `internal/`) | — |
| Config pattern | flat struct + `getenv` ใน `zyra-api/internal/config/config.go` (เช่น `GoogleClientID`) · `google.golang.org/api` เป็น dependency อยู่แล้ว | — |
| Background job | goroutine ticker loop ใน `zyra-api/main.go` (ไม่มี queue/cron lib) · ใช้ Redis lock กันหลาย instance ได้ (ตัวอย่าง `runEnvironmentAlertLoop`) | `zyra-api/main.go:409-454` |
| Retry ladder 30s → 2m → 5m | **มี precedent ตรงตัว** (`WeatherRetryBackoff`, 3 ครั้ง, tick 10s) | `zyra-api/internal/service/environment_weather_retry.go` |
| In-app notification | `tb_notification` + CHECK constraint ของ type (ล่าสุดเพิ่ม `weather_alert`) · push ผ่าน Redis `vo:notify` → zyra-ws | `zyra-api/migrations/100_notification_weather_alert.sql` · `internal/service/notification_service.go` · app type union `zyra-app/lib/api/chat.ts:125-140` |
| Toast | `zyraToast.*` รองรับ action button (เหมาะกับ "ลองใหม่"/"เชื่อมต่อใหม่") | `zyra-app/lib/toast.tsx` |
| Banner | `vo-alert-banner.tsx` (3 ระดับ) | `zyra-app/views/user/virtual-office/components/` |
| Migration | SQL เลขเรียง รันมือ · ล่าสุด `109_roadmap_object_mystery.sql` → เลขถัดไป **110** | `zyra-api/migrations/` |
| Member API | `/api/user/*` (UserGuard) · ห้ามใช้ `/api/admin/*` | `zyra-api/internal/router/router.go` |

### 5.3 สิ่งที่ "meeting" หมายถึงในโค้ดปัจจุบัน

- **มีแค่ VO realtime meeting** = zone type `meeting` บน map + `tb_zone_section`/`tb_zone_section_member` + LiveKit media token (`/api/user/workspaces/:id/zone-sections/*`, `/rooms/:roomId/media-token`)
- **ไม่มี scheduled meeting:** ไม่มี table/model/route/form ที่มีชื่อ, เวลาเริ่ม-จบ, attendees · ไม่มี meeting join link (link เดียวที่มีคือ workspace invite `app/join/[token]`)
- **ไม่มีหน้า Calendar view**

---

### 5.4 อัปเดต 2026-10-20 (หลังเอกสารชุดแรก)

- N2Pluto push `origin/feat/calendar-google-integration` (`05f8e1d`, 2026-10-19): migration **115** `tb_user_calendar_integration` (1 แถวต่อ user ต่อ provider — ผูกกับ **user** ไม่ใช่ workspace), เข้ารหัส token AES-256-GCM, config `GOOGLE_CALENDAR_*` (ปิดเป็นค่าเริ่มต้น), model ของ `/api/user/integrations/google/*` · commit อ้างเอกสาร `zyra-doc/plan/CalendarIntegration` + scenario `SC-CAL-01..08` ซึ่ง**ไม่มีใน zyra-doc**
- HP-01 ถูก implement บน `feat/calendar` ของ zyra-api + zyra-app (uncommitted) — รายละเอียดไฟล์และผล test อยู่ใน [progress.md](progress.md)

## 6. Gap (requirement เทียบกับ baseline)

| Requirement | สิ่งที่ต้องมีเพิ่ม | ขึ้นกับ |
|---|---|---|
| HP-01/HP-02 connect | OAuth **authorization code flow** ฝั่ง server (ไม่ใช่ implicit แบบ login), เก็บ refresh token แบบ encrypted, table connection ต่อ user ต่อ provider, UI สถานะ connected/expired/disconnected + calendar selector | Q2, Q3, Q8 |
| Sync event เข้า Zyra ภายใน 30 วิ | sync worker + ที่เก็บ external events + **หน้าที่แสดง events** | Q1, Q6 |
| HP-03 / EC-03 / EC-04 / AC-HP01-5 push meeting | **scheduled meeting entity + form สร้าง/ลบ + join link** (ยังไม่มีทั้งหมด) + mapping Zyra meeting ↔ external event id | **Q1 (blocker)** |
| HP-04 disconnect | revoke token กับ provider + ลบ synced events | Q7 |
| EP-02 แจ้งเตือน | notification type ใหม่ (migration แก้ CHECK constraint) + dedupe ให้ส่ง 1 ครั้ง | Q10 |
| EP-03 retry | reuse pattern `WeatherRetryBackoff` + สถานะ sync ให้ UI อ่าน | Q1 (header ไหน) |
| Credentials | Google Cloud OAuth client (calendar scopes) + Microsoft Entra app registration + secret/key สำหรับเข้ารหัส | Q8, Q9 |

---

## 7. ข้อขัดแย้ง & คำถามที่ต้องเคลียร์ (ก่อน implement)

### Q1 (BLOCKER) — Scheduled meeting + Calendar view อยู่ใน scope นี้หรือไม่

- **ต้นทาง:** HP-03 "User สร้าง meeting ใน Zyra (ชื่อ, เวลา, ห้อง, attendees)" · AC-HP01-5 "Zyra meetings ที่มีอยู่ถูก push" · EC-04 "ลบ Zyra Meeting" · AC-EP02-1/EP-03 "Calendar ยังแสดง events เดิม", "warning บน calendar header" · Figma: `Calendar - Half view`, "My Calendar = Meeting ที่เราสร้าง", "Upcoming meeting"
- **โค้ดจริง:** ไม่มี scheduled meeting และไม่มีหน้า Calendar (§5.3)
- **Figma (ถอด 2026-10-12):** วาด Schedule event modal, Event details, calendar half/full view, event chip ไว้ใน section ของ HP-03 → ฝั่ง design ถือว่า **อยู่ใน feature นี้** (ดู [ux-ui.md U1](ux-ui.md#8-ข้อสังเกต--ขัดกับ-clickup--คำถาม-design)) แต่ ClickUp ยังไม่มี AC ของส่วนนี้
- **คำถาม:** การสร้าง/แก้/ลบ scheduled meeting + หน้า Calendar view มี ClickUp task แยกอยู่แล้วหรือไม่ · ถ้าไม่มี ต้องรวมใน feature นี้ไหม · "ห้อง" ใน HP-03 คือ meeting zone บน VO map ใช่ไหม · join link พาไปที่ไหน (เข้า workspace แล้ว warp ไปที่ zone?)

### Q2 (BLOCKER) — Connection ผูกกับอะไร: user ทั้งบัญชี หรือ user ต่อ workspace

- **ต้นทาง:** Persona "user แต่ละคน connect เอง" · HP-01 "Workspace Settings → Integrations" · HP-02/HP-04 "Settings → Integrations"
- **โค้ดจริง:** Integrations tab อยู่ใน VO Setting modal ซึ่งเปิดภายใน workspace · ไม่มีหน้า Workspace Settings แยก
- **คำถาม:** user ที่อยู่หลาย workspace connect ครั้งเดียวแล้วเห็น events ทุก workspace หรือแยก connect ต่อ workspace · meeting ที่ push ออกไปเป็นของ workspace ไหน

### Q3 — Calendar selector ของ Google กับ Outlook ไม่เหมือนกัน

- HP-01: sync อัตโนมัติ + selector "Optional" · HP-02: ต้องเลือก calendar แล้วกด "บันทึก" · EC-02: default = Primary เท่านั้น (พูดถึงแค่ Google)
- **คำถาม:** ทั้งสอง provider ใช้ flow เดียวกันได้ไหม (เช่น default primary แล้วแก้ทีหลังได้) · push meeting ไปที่ calendar ไหน (primary เสมอ?)

### Q4 — "Sync ภายใน 30 วินาที" หมายถึง initial sync หรือทุกการเปลี่ยนแปลง

- ถ้าหมายถึงการเปลี่ยนแปลงใน Google/Outlook ต้องโผล่ใน Zyra ≤30 วิ ตลอดเวลา → ต้องใช้ push notification ของ provider (Google `events.watch`, Microsoft Graph subscriptions) ซึ่งต้องมี public HTTPS webhook + ต่ออายุ channel/subscription · ถ้า poll ทุก ≤30 วิ ต่อ user จะชน quota
- **คำถาม:** ยอมรับ initial sync ≤30 วิ + periodic sync (กี่นาที) ได้ไหม หรือต้อง near-realtime

### Q5 — Attendees, invite และ event ซ้ำ

- HP-03 ข้อ 4: attendees ได้ invite จาก Google/Outlook ถ้า email ตรง
- ถ้า attendee ก็ connect calendar ไว้ด้วย จะเห็น (ก) Zyra meeting ของตัวเอง + (ข) invite ที่ sync เข้ามาจาก calendar ตัวเอง → ซ้ำ · EC-01 ห้าม duplicate
- ถ้า organizer connect ทั้ง Google + Outlook → attendee ได้ invite 2 ฉบับ
- **คำถาม:** ต้อง dedupe ข้าม user/ข้าม provider ไหม · ถ้า connect ทั้งสองแล้ว invite ควรส่งจาก provider ไหน

### Q6 — ช่วงเวลาที่ sync

- EC-01: "30 วันย้อนหลัง + อนาคต" — อนาคตไม่ได้กำหนดขอบเขต · ใช้กับ connect ครั้งแรกด้วยไหม (ClickUp เขียนไว้เฉพาะ reconnect)
- Figma: "Upcoming meeting จะโชว์แค่ของวันนั้นเท่านั้น"
- **คำถาม:** ช่วงอนาคตกี่วัน · recurring event ต้องรองรับไหม

### Q7 — Lifecycle ของ meeting ที่ push ออกไป

- HP-04: disconnect แล้ว event ที่เคย push **ยังอยู่ใน Google** · EC-04: ลบ Zyra meeting → ลบ Google event ใน 10 วิ (พูดถึงแค่ Google)
- ขัดกันเมื่อ: disconnect แล้วค่อยลบ meeting → ไม่มี token ไปลบ event ที่ค้างอยู่ · reconnect แล้ว event ที่ Zyra เคย push จะถูก sync กลับเข้ามาซ้ำกับ Zyra meeting (ชน EC-01)
- ClickUp ไม่พูดถึงการ **แก้ไข** meeting (เปลี่ยนเวลา/ชื่อ) ว่าต้อง update event ภายนอกไหม
- **คำถาม:** EC-04 ใช้กับ Outlook ด้วยไหม · "Zyra state ชนะถ้า fail" หมายถึงอะไร (ลบใน Zyra สำเร็จเสมอ + retry ลบภายนอก?) · แก้ไข meeting ต้อง sync ไหม

### Q8 — Scopes และ OAuth app

- Google: ClickUp ระบุ `calendar.readonly` + `calendar.events` · Calendar scopes จัดเป็น sensitive → production ต้องผ่าน **Google OAuth app verification** (ใช้เวลา) · ปัจจุบัน OAuth client ใช้แค่ login
- Microsoft: ClickUp ระบุ `Calendars.ReadWrite` อย่างเดียว · ต้องมี `offline_access` เพื่อได้ refresh token (ไม่งั้นทำ background sync ไม่ได้)
- **คำถาม:** ใช้ Google Cloud project เดิมหรือแยก · ใครเป็นเจ้าของ Microsoft Entra app registration · รองรับบัญชี Microsoft แบบไหน (work/school, personal, ทั้งสอง)

### Q9 — Token encryption key

- AC-HP01-4 ต้อง encrypt token server-side แต่ยังไม่มี helper/key ใน `zyra-api`
- **คำถาม:** key เก็บที่ไหน (env ธรรมดา หรือ secret manager) · rotation policy

### Q10 — EP-02 notification ช่องทางไหน

- "Notification ส่ง 1 ครั้ง" — in-app bell (`tb_notification`) หรือ email หรือทั้งสอง · ตรวจเจอ token ตายได้เฉพาะตอน worker refresh → ต้องมี periodic sync
- EP-02 เขียนเฉพาะ Google — Outlook ใช้กติกาเดียวกันไหม

### Q11 — EP-01 Banner หรือ Toast

- ClickUp: "Error banner" + ปุ่ม "ลองใหม่" + หายเองใน 10 วิ · Figma `3601-766158` frame สุดท้ายเป็น instance `Toast`
- **คำถาม:** ใช้ toast (มี action ได้อยู่แล้ว) หรือ banner ใน Integrations tab

### Q12 — สิ่งที่ Figma มีแต่ ClickUp ไม่มี

- Banner "Add integration" ครั้งแรก (ปิดได้) · calendar "Thai holidays" (มาจาก source ไหน) · "My Calendar" · Upcoming meeting
- ตาม `rules/14-no-overreach.md` จะไม่ใส่เป็น requirement จนกว่าจะยืนยันว่าอยู่ใน scope ของ feature นี้

### Q13 — สถานะ ClickUp ไม่ตรงกับโค้ด

- HP-01/HP-02 เป็น `in progress` แต่ไม่มีโค้ด/branch เลย — มีคนเริ่มงานนอก repo (เช่น design/ขอ credential) อยู่หรือไม่

---

## 8. ข้อเสนอของ Agent (ยังไม่ใช่ decision — รอ review)

> ส่วนนี้เป็นแนวทางเบื้องต้นเพื่อช่วยตอบ Q ข้างบน รายละเอียด contract/schema จะอยู่ใน `technical-design.md` หลังเคลียร์ Q1–Q4

1. **แยกเฟส** เพื่อให้ส่วนที่ไม่ติด Q1 เริ่มได้ก่อน
   - **Phase 1 — Connect/Disconnect + สถานะ** (HP-01, HP-02, HP-04, EP-01, EP-02 ฝั่ง settings): OAuth code flow ใน popup → callback ที่ `zyra-api` แลก code เป็น token เก็บแบบ encrypted · browser ได้แค่ผลสำเร็จ/ล้มเหลว (reuse pattern popup → opener ของ Google login แต่ไม่ส่ง token ผ่าน browser)
   - **Phase 2 — Inbound sync** (events ภายนอก → Zyra) + EP-03 retry: ทำเมื่อมีหน้าแสดง events (Q1)
   - **Phase 3 — Outbound push** (HP-03, EC-03, EC-04, AC-HP01-5): ทำหลังมี scheduled meeting entity
2. **Reuse:** `WeatherRetryBackoff` pattern สำหรับ EP-03 · ticker loop + Redis lock ใน `main.go` สำหรับ sync worker · `zyraToast` + action สำหรับ "ลองใหม่"/"เชื่อมต่อใหม่" · `IntegrationRow` เดิมใน `vo-setting-modal.tsx` · notification pipeline เดิม (เพิ่ม type ใหม่ผ่าน migration 110+)
3. **API:** อยู่ใต้ `/api/user/integrations/calendar/*` (member route, UserGuard) — รายละเอียด method/path/request/response/error ทำใน technical-design
4. **Dedupe:** เก็บ mapping `zyra_meeting_id ↔ (provider, external_event_id)` และใส่ marker ใน event ที่ Zyra push (Google `extendedProperties.private` / Graph `singleValueExtendedProperties`) เพื่อไม่ sync กลับเข้ามาซ้ำ (ตอบ EC-01/Q7)

---

## 9. Decision log

| วันที่ | เรื่อง | ตัดสินใจ | ใครตัดสิน | ปิดคำถาม |
|---|---|---|---|---|
| 2026-10-20 | Connection scope | ผูกกับ **user ทั้งบัญชี** (connect ครั้งเดียวใช้ได้ทุก workspace) — ตาม schema 115 ของ N2Pluto | ตามโค้ดที่มีอยู่ + ผู้ใช้ให้ merge งานนั้นมาใช้ | Q2 (ฝั่ง Google) |
| 2026-10-20 | Sync model | ดึง event สดจาก Google ผ่าน zyra-api ทุกครั้งที่เปิด/เปลี่ยนช่วง/กด Sync now · ไม่มีตาราง event · ไม่มี worker | ผู้ใช้ | Q4 บางส่วน (initial ≤30 วิ ผ่านเพราะอ่านสด · ยังไม่มี periodic/push จาก Google) |
| 2026-10-20 | Google scopes | `calendar.readonly` + `calendar.events` ตาม ClickUp (+ `openid email profile`) | ผู้ใช้ | Q8 เฉพาะ scope (OAuth app/credential ยังเปิด) |
| 2026-10-20 | Calendar UI ใน HP-01 | ทำ half/full view ครบ แต่แสดงเฉพาะ Google · ไม่มี My calendar · ซ่อนปุ่ม + · Thai Holidays = Google holiday calendar (`en.th#holiday@group.v.calendar.google.com`) หลัง connect | ผู้ใช้ | Q1 **ยังเปิด** (scheduled meeting) · U8 บางส่วน |
| 2026-10-20 | Callback | `GET /api/integrations/google/callback` (public) แลก code ฝั่ง server · state = HS256 JWT 10 นาที + nonce ใน cookie httpOnly (กัน callback จาก browser อื่น) · redirect กลับ `/integrations/google/callback?status=` แล้ว popup ส่งผลให้ tab หลักผ่าน localStorage | Agent (ตาม pattern Google login เดิม) | — |
| 2026-10-20 | Error code ของ API | `calendar_reauth_required` ตอบ **409** ไม่ใช่ 401 (401 จะทำให้ `authFetch` ของ app ตัด session Zyra) | Agent | — |
| 2026-10-21 | Scheduled meeting (HP-03) | ทำ scheduled meeting + Schedule event ครบตาม Figma `3583:77760` · meeting ผูกกับ **workspace** (organizer + guest ต้องเป็นสมาชิก) · ไม่มีแก้/ลบ/RSVP ในรอบนี้ | ผู้ใช้ (UI ครบตาม Figma) | **Q1 ปิด** (ฝั่ง create + calendar view) |
| 2026-10-21 | Provider ของ HP-03 | push ไป **Google ก่อน** · Outlook ทำตอน HP-02 | ผู้ใช้ | Q5 บางส่วน (ยังไม่มีกรณี connect 2 provider) |
| 2026-10-21 | "ห้อง" / join link | Location = meeting zone ทุกชั้นของ workspace หรือ "Any available meeting room" · join link = `${APP_URL}/workspace/{ws}/play?zone_id=` (เลือกห้อง) หรือ `/workspace/{ws}/play` (any) | ผู้ใช้ | U2 |
| 2026-10-21 | Retry push ที่ล้มเหลว | `google_sync_status=failed` + **Sync now** (full view) re-push meeting ที่ยังไม่จบ · ไม่มี worker | ผู้ใช้ | U6 |
| 2026-10-21 | Google → Zyra | "ทุกอย่างต้องเหมือนกันทั้งสองฝั่ง": meeting ที่ push แล้ว ถ้า organizer ลบใน Google → ลบใน Zyra · แก้ใน Google (ชื่อ/เวลา/รายละเอียด/สถานที่/guest/สิทธิ์) → อัปเดต Zyra · ตรวจตอน list meetings (เปิด/เลื่อน Calendar + Sync now) ไม่มี webhook · Zyra → Google (แก้/ลบ) ยังไม่ทำจนกว่าจะมี design EC-04 | ผู้ใช้ | Q7 บางส่วน |
| 2026-10-21 | กันแสดงซ้ำ | app ซ่อน Google event ที่ id = `google_event_id` ของ Zyra meeting (organizer และ invitee ใช้ id เดียวกัน) · event ที่ push มี `extendedProperties.private.zyra_meeting_id` | Agent | EC-01 บางส่วน |

### API ที่ implement (member, UserGuard — rule 15)

| Method | Path | Request | Response `data` | Error |
|---|---|---|---|---|
| POST | `/api/user/integrations/google/connect` | `{ "return_to"?: "/integrations/google/callback" }` | `{ auth_url }` + Set-Cookie `zyra_gcal_state` | 401 |
| GET | `/api/integrations/google/callback` (public) | `code`, `state`, `error` จาก Google | 302 → `${APP_URL}{return_to}?provider=google&status=connected\|denied\|scope_missing\|expired\|error` | — |
| GET | `/api/user/integrations/google/status` | — | `{ provider, connected, state?, email?, name?, scopes?, connected_at? }` | 401 |
| GET | `/api/user/integrations/google/calendars` | — | `{ items: [{ id, summary, primary, holiday, background_color }] }` | 404 `calendar_not_connected` · 409 `calendar_reauth_required` · 502 `calendar_provider_unavailable` |
| GET | `/api/user/integrations/google/events` | `time_min`, `time_max` (RFC3339, ≤62 วัน), `calendar_id` ซ้ำได้ ≤20 | `{ time_min, time_max, items: [{ id, calendar_id, summary, start, end, all_day, location, meet_link, html_link, status, response_status }] }` | 400 · 404 · 409 · 502 ตามด้านบน |
| DELETE | `/api/user/integrations/google` | — | `{ connected: false, revoked }` | 401 |

**HP-03 (2026-10-21)** — member, UserGuard, ลงทะเบียนเสมอ (ไม่ขึ้นกับ `GOOGLE_CALENDAR_ENABLED`; ถ้าปิด meeting อยู่ใน Zyra อย่างเดียว `google_sync=none`)

| Method | Path | Request | Response `data` | Error |
|---|---|---|---|---|
| GET | `/api/user/workspaces/:id/meetings` | `time_min`, `time_max` (RFC3339, ≤62 วัน) | `{ items: CalendarMeeting[] }` — meeting ที่เราเป็น organizer หรือ guest | 400 · 401 · 403 (ไม่ใช่สมาชิก) |
| POST | `/api/user/workspaces/:id/meetings` | `{ title, description, start, end, all_day, time_zone, zone_id, guest_ids[], permissions{modify_event, invite_others, see_guest_list} }` — all_day ใช้ `YYYY-MM-DD` (end exclusive) | **201** `CalendarMeeting` (`google_sync`: none \| synced \| failed — failed ก็ยัง 201) | 400 · 401 · 403 |
| POST | `/api/user/workspaces/:id/meetings/sync` | — | `{ synced, failed }` | 401 · 403 |

`CalendarMeeting` = `{ id, workspace_id, title, description, start, end, all_day, time_zone, zone_id, location, join_url, organizer{user_id,name,email}, guests[], permissions, google_sync, google_event_id?, google_html_link? }` · DB: migration 117

Error body ใช้รูปเดียวกับ environment/pet handler: `{ status, message: <code>, detail: { code } }` · `GOOGLE_CALENDAR_ENABLED` ปิด = ไม่ลงทะเบียน route (404) และ app แสดง coming soon แบบเดิม

## Readiness

| เงื่อนไข | สถานะ |
|---|---|
| Requirement ต้นทางถอดครบ | ✅ ClickUp parent + 7 subtasks (2026-10-12) |
| Figma | ⚠️ [ux-ui.md](ux-ui.md) (2026-10-12): โครง frame + sticky ครบ 7/7 section · ดึงค่าละเอียดได้แค่ Schedule event modal + ขนาดของ Calendar panel/empty state · ที่เหลือติด Figma MCP rate limit (รายการ node ที่ต้องดึงต่ออยู่ใน ux-ui.md §9) |
| Baseline โค้ด | ✅ ตรวจแล้ว 2026-10-12 (§5) |
| Blocker | ~~Q1~~ ปิดแล้ว 2026-10-21 (create + view) · **Q8** (OAuth app + credential สำหรับ dev/prod + Google verification) · ~~Q2~~ ปิดแล้ว (§9) · แก้/ลบ meeting (EC-04) ยังไม่มี spec |
| Technical design | contract ของ HP-01 อยู่ใน §9 · ยังไม่มี `technical-design.md` แยก |

**สรุป (2026-10-21):** HP-01 + HP-03 ฝั่ง Google implement แล้ว (ยกเว้น AC-HP01-5, AC-HP03-2 Outlook) แต่ยังไม่ live-test เพราะยังไม่มี OAuth credential · HP-02/HP-04/EP/EC ยังไม่ทำ

**Next step:** ตั้ง OAuth client + env บน dev แล้ว live-test HP-01 (checklist ใน [progress.md](progress.md)) → หาเอกสาร `plan/CalendarIntegration` ของ N2Pluto มารวม → PM ตอบ Q1 (scheduled meeting) ก่อนเริ่ม HP-03 · Q ที่เหลือยังต้องตอบก่อน scenario ที่เกี่ยวข้อง
