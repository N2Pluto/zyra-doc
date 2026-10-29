# SC-MTG-CAL-01 · Calendar Integration — UX/UI Plan (from Figma)

> **สถานะ (2026-10-29):** ดึงจาก Figma ครบทุก section ของการ์ด (HP-01…HP-05, EP-01…EP-03) + section ใหม่ที่ designer เพิ่ม · **HP-06 Reschedule ยังไม่มีใน Figma** · ยังไม่ได้ review กับ Design/PM
> **Figma:** `Map8gX0L2hk7HnkaFRfhtj` page "✅ Calendar Integration" `3225:480433` · ดึงผ่าน Figma MCP (≈78 calls · ไม่โดน limit) · ไม่ได้ download asset
> **กติกา:** ตัวเลขทุกตัวมาจาก Figma MCP ([10-figma-fidelity](../../../.claude/rules/10-figma-fidelity.md)) · ค่าจากภาพอย่างเดียวระบุ **[screenshot]** · ดึงไม่ได้เขียน **"ยังไม่ได้ดึง"**
> **flow / AC อยู่ที่ [spec.md](spec.md)** · ค่า Calendar panel / toolbar / Month-Week-Day / Event detail พื้นฐานอยู่ที่ [Calendar Display ux-ui-plan](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md>) · toast / bell / notification panel อยู่ที่ [Meeting Alert ux-ui-plan](<../[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/ux-ui-plan.md>) — ไฟล์นี้ไม่คัดลอกซ้ำ ดู [§1](#1-ส่วนที่-3-ฟีเจอร์ใช้ร่วมกัน)
> **แทนที่:** [MeetingCalendarIntegration/ux-ui.md](../MeetingCalendarIntegration/ux-ui.md) (2026-10-12/21) สำหรับค่า Figma — Figma เปลี่ยนไปหลายจุด ดู [§11](#11-เปลี่ยนจากเอกสารเดิม-meetingcalendarintegrationux-uimd)
> **กติกากลาง 3 ฟีเจอร์ (ผู้ใช้ตัดสิน 2026-10-29):** Figma กับ ClickUp ขัดกัน → **ยึด Figma** ยกเว้นข้อที่ผู้ใช้ตัดสินเป็นอย่างอื่น (ดู [CAL-01 spec §6.1](<../[Feature] Meeting — Calendar Integration/spec.md>)) · ข้อที่มีแค่ฝั่งเดียว (Figma ไม่ได้วาด) ยังเป็นคำถามเปิด จนกว่าจะตัดสิน
> **POC ที่ทำตามเอกสารนี้:** [poc/index.html](<../[Feature] Meeting — Calendar Display/poc/index.html>) (launch config `meeting-calendar-poc-3143`) — รวม 3 ฟีเจอร์ สลับ Figma / ClickUp ได้

---

## 0. Section / frame inventory (page `3225:480433`)

| Scenario | Section | สิ่งที่วาด | Sticky (designer) |
|---|---|---|---|
| HP-01 Connect Google | `3237:609135` | `3249:619414` Integrations ยังไม่เชื่อม → `3254:620693` เลือกบัญชี → `3254:620694` signing back in → `3254:621159` ขอสิทธิ์ (popup 340×625 @ 550,200) → `3301:5047` เชื่อมแล้ว + toast `3298:5019` · แถว 2–3 = Calendar half/full (Calendar Display) | `3621:259108` "Upcoming meeting จะโชว์แค่ของวันนั้นเท่านั้น" · `3898:777344` "เข้ามาครั้งแรกและมี Banner ให้ Add integration สามารถกากบาทออกได้" · `3898:778664` "Calendar list ถ้ายังไม่เชื่อม Integration จะมีแต่ My Calendar = Meeting ที่เราสร้าง Thai holidays" |
| HP-02 Connect Outlook | `3301:5048` | `3301:5050` ยังไม่เชื่อม → `3301:7591` Microsoft "Permissions requested" (340×744 @ 550,140.5) → `3301:5057` Outlook เชื่อมแล้ว + toast `3301:5059` · ไม่มีขั้นเลือกบัญชี · ไม่มี calendar selector | — |
| HP-03 สร้าง meeting | `3583:77760` | Schedule event (Default / Mini Calendar / Time / Location / Guest list / Guest search / All day / ไม่มี guest / Filled) · Discard modal · toast สำเร็จ + Event detail · sync failed toast · Full view สร้างจากปุ่ม + และคลิกช่องเวลา · chip "กำลังสร้าง" | ดู §6.6 |
| HP-04 Disconnect | `3601:762611` | `3601:762648` Google เชื่อมแล้ว → `4240:551007` General modal → `3601:765503` (Google) / `3601:765517` (Outlook) กลับเป็น Connect + toast · **frame ปฏิทินหลัง disconnect ถูกเอาออกแล้ว** | `3613:133960` "กรณี Google" · `3613:133964` "กรณี Outlook" |
| HP-05 Cancel **ใหม่** | `7802:237620` (+ สำเนา `7881:512959`) | 6 แถว flow + แถว 7 Recurring (ว่าง) — ดู §8 | 12 sticky ดู §8.1 |
| HP-06 Reschedule | — | **ไม่มีใน Figma** (`7881:512959` เป็นสำเนา HP-05 ไม่ใช่ reschedule) | — |
| EP-01 Deny consent | `3601:766158` | `3601:766160` → `3601:766161` → `3601:766162` (กด Cancel) → `3601:766195` toast แดง `3601:766197` · แถว 2 `3601:769050` = popup Microsoft (ฝั่ง Outlook) | — |
| EP-02 Token หมดอายุ | `3601:769864` | `3602:774968` Idle → `3602:775170` half + banner → `3602:775198` full + banner → `3613:131273` Settings + tooltip `3613:131270` | `3613:133981` "กดที่ข้อความ Warning หรือ ไปที่ Setting menu" |
| EP-03 Sync ล้มเหลว | `3602:834434` | `3602:834437` half + banner → `3602:834439` full → `3602:835652` กำลัง sync → `3602:836222` สำเร็จ banner หาย | `3602:836792` "หลังจากระบบพยายาม Syn 3 ครั้ง แต่ไม่สามารถ Sync ข้อมูลได้" · `3613:131527` "เปิด Full view > กดปุ่ม Sync now" · `3613:131531` "กำลัง Sync ข้อมูล" · `3613:131535` "Sync สำเร็จ Warning หายไปทันที" |
| Module overview **ใหม่** | `7789:1282008` + การ์ด scenario A/B/C `7789:1282946/7/8` | กติกากลางของ Event management (R1–R6) + 16 scenario — ดู §9 | — |
| Components | `3613:131696` | `7756:45643` Event detail (variant ตาม role) · `7841:314755` Timed meeting (รวม cancelled) | — |

---

## 1. ส่วนที่ 3 ฟีเจอร์ใช้ร่วมกัน

**ขอบจอบัง / กดแล้วหาย — checklist ตอนทำจริงของ popup ทุกตัว (รวม Setting modal, Cancel modal, Choose calendars, tooltip) อยู่ที่ [Calendar Display ux-ui-plan §12](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md#12-ขอบจอบัง--กดแล้วหาย--checklist-ตอนทำจริง-2026-10-29>)**

CAL-01 (Integration) · CAL-02 (Calendar Display) · CAL-03 (Meeting Alert) ใช้หน้าจอเดียวกัน — **component เดียว ห้ามทำซ้ำ** ([rule 09](../../../.claude/rules/09-component-reuse.md)) · ตารางนี้บอกว่าค่าของแต่ละชิ้นอยู่ไฟล์ไหน และฟีเจอร์ไหนแตะส่วนไหน

| Component | Figma | ค่าอยู่ที่ | CAL-01 | CAL-02 | CAL-03 | โค้ดปัจจุบัน (develop) |
|---|---|---|---|---|---|---|
| Sidebar + ไอคอน Calendar / Bell / Setting + badge | Display `3898:761567` · Alert badge | [Display §2](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md>) · [Alert §3](<../[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/ux-ui-plan.md>) | ⚙ → Setting | 📅 → panel | 🔔 → panel + badge | `vo-sidebar.tsx` |
| Calendar panel 320 (title, search, banner, mini cal, upcoming, calendar list) | Display `4998:56263` | Display §3 · ที่นี่ §5 (banner EP-02/03) | connect banner, alert banner, calendar list ต่อ provider | ทั้งหมด | — | `vo-calendar.tsx` |
| Toolbar (Today / ‹ › / Day-Week-Month / Sync now) | Display | Display §4 · ที่นี่ §5.3 (Syncing) | Sync now + Syncing | ทั้งหมด | — | `calendar-main-view.tsx` |
| Month / Week / Day grid + chip / block | Display | Display §5–7 | — | ทั้งหมด | cancelled / rescheduled | `calendar-main-view.tsx`, `calendar-parts.tsx` |
| **Event detail popup** | `7756:45643` (variants) | Display §8 + ที่นี่ §7–8 | header ตาม role, Cancel, Description | เปิดจาก chip | เปิดจาก toast / การ์ด | `calendar-event-details.tsx` |
| **Schedule event modal** (สร้าง/แก้) | `3586:257415` | ที่นี่ §6 | เจ้าของ | ปุ่ม +, คลิกช่องเวลา, empty state | — | `calendar-schedule-event.tsx` |
| Date / Time / Location / Guest dropdown | `3586:260046` ฯลฯ | ที่นี่ §6.3 | เจ้าของ | — | — | ใช้ `announcement-date-time.tsx` (`TIME_OPTIONS`) + `CalendarMiniMonth` |
| **Toast** (336, `#1A1B1E`) | หลายจุด | ที่นี่ §4 · Alert §2 · Display §9.3 | connect / disconnect / cancel / sync fail | load error | 5-min / started / missed / cancelled / rescheduled | `lib/toast.tsx` `zyraToast` layout figma |
| **General modal** (458) | `4240:551936`, `3613:202062` | ที่นี่ §3.4, §6.4 | disconnect, discard | — | — | pattern ของ `vo-spotlight-share-confirm-modal.tsx` |
| **Cancel meeting modal** (455) | `7841:498103` | ที่นี่ §8.3 | เจ้าของ (HP-05) | — | — | ไม่มี |
| Setting modal → Integrations | `3237:609169` | ที่นี่ §3 | เจ้าของ | — | — | `vo-setting-modal.tsx` |
| Notification panel + การ์ด meeting | Alert `7767:466425` | Alert §4 | การ์ด "Event deleted" (HP-05 แถว 2/5) | — | เจ้าของ | `vo-notification-panel.tsx` |
| Cancelled meeting state | `7841:314755`, `7841:319230` | ที่นี่ §8.5 | ผู้ยกเลิก | การแสดงใน grid | alert + การ์ด | ไม่มี (`tb_calendar_meeting` ไม่มี status) |

**จุดที่ต้องตกลงร่วมกันทั้ง 3 การ์ด** (ต่อจาก [Calendar Display spec §7 X1–X8](<../[Feature] Meeting — Calendar Display/spec.md>)):

| # | เรื่อง | CAL-01 | CAL-02 | CAL-03 |
|---|---|---|---|---|
| S1 | Event ที่ถูกยกเลิกแสดงยังไง | **ตัดสินแล้ว (ผู้ใช้ 2026-10-29):** meeting / การจองที่สร้างใน Zyra ลบหรือยกเลิกแล้ว **ทิ้งไว้เป็นขีดฆ่าในปฏิทินของทุกคน** (รวมผู้ยกเลิก) · event จาก Google/Outlook **ลบใน Zyra ไม่ได้** — ไอคอนถังขยะเป็นลิงก์ + tooltip เปิด provider ไปลบที่นั่น แล้ว sync กลับมาหายจาก Zyra · (เดิม: ClickUp HP-05 ให้หายจาก calendar ทุกคน · Figma HP-05 แถว 1 หายจากจอผู้ยกเลิก — ต้องแจ้ง PM/Design ให้แก้ตาม) | ใช้กติกาเดียวกัน | Figma MA-EP-02 (เทา 10% + ขีดฆ่าแดง + "Reason for cancellation") ตรงกับกติกานี้ |
| S2 | ปุ่มใน Event detail ตาม role | calendar-x / Edit / Close (Organizer) · Edit / Close (Attendee ตาม Figma) · Close (cancelled) | Display §8 เขียน Trash/Edit/Close (frame เก่า) | — |
| S3 | นิยาม "live / active" | HP-05/06 ห้ามยกเลิก/เลื่อนตอน live | "Join Now" เฉพาะ active | Join บนการ์ดเฉพาะยังไม่จบ |
| S4 | ข้อความแจ้ง cancel / reschedule | ❌ "[ชื่อ] ถูกยกเลิกโดย [Organizer]" · 🔄 "ถูกเลื่อนเป็น [เวลาใหม่]" | — | "… has been cancelled / rescheduled" |
| S5 | Join บน alert เก่าหลังยกเลิก | HP-05: "ยกเลิกแล้ว" (disabled) · HP-06: แสดงเวลาใหม่ / ไป Calendar | — | MA-EP-02: redirect ไป Calendar |
| S6 | สีของ provider | Figma ใหม่มีโลโก้ Google/Outlook 12×12 บน chip (`7893:532052`/`532079` — ยังไม่ได้ดึง) | ClickUp: สีตาม source | — |
| S7 | ภาษา | Figma ทั้ง 3 = อังกฤษ · ClickUp = ไทย → ต้องมี en + th ใน `messages/*.json` ([rule 19](../../../.claude/rules/19-thai-translation.md)) | เหมือนกัน | เหมือนกัน |

---

## 2. Tokens ที่ใช้ในฟีเจอร์นี้ (นอกเหนือ [Display §1](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md>) / [Alert §1](<../[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/ux-ui-plan.md>))

| Token | ค่า | ใช้ที่ |
|---|---|---|
| Shade Black/50% | `rgba(26,27,30,0.5)` | การ์ดบัญชีใน Integrations |
| Overlay | `rgba(0,0,0,0.5)` | หลัง Setting / General modal / Cancel modal |
| Yellow/500 | `#ECC819` | ข้อความ + ไอคอน warning (EP-02/03, toast "Something went wrong") |
| Yellow/10% · Yellow/20% | `rgba(236,200,25,0.1)` · `rgba(236,200,25,0.2)` | พื้น + ขอบ alert banner / icon box toast warning |
| — | `rgba(255,212,0,0.1)` | icon box toast "Calendar sync failed" (ต่างจาก Yellow/10% เล็กน้อย — ค่าจริงใน Figma) |
| Red/500 (ปุ่ม) | `#F03A3A` | Disconnect / Confirm cancel |
| Red/500 (badge) | `#D41818` | pill "Booked" |
| Red/20% | `rgba(240,58,58,0.2)` | icon box toast EP-01 / "Event deleted" |
| Red 5% / 20% | `rgba(240,58,58,0.05)` · `rgba(240,58,58,0.2)` | ปุ่ม Disconnect (outline) |
| Cancelled bg | `rgba(255,255,255,0.1)` | block / chip ที่ถูกยกเลิก |

---

## 3. Setting → Integrations (HP-01 / HP-02 / HP-04 / EP-02)

### 3.1 Setting modal shell (`3237:609169`, เหมือนกันทุก frame)

| ส่วน | Node | ค่า |
|---|---|---|
| Modal | `3237:609169` | **934×800 @ (253,112)** · flex row · radius 16 · overflow clip |
| Overlay | `3237:609168` | เต็มจอ `rgba(0,0,0,0.5)` |
| เมนูซ้าย | `…;3233:607795` | w 238 · `#242B32` · backdrop-blur 4 · p16 · gap 16 · title "Setting" Title/Bold 20/25 · รายการ gap 8 |
| รายการเมนู | `…;43:5402` | min-h 42 · p12 · r8 · icon 16 + gap 8 + Body/Regular 14/18 white · Profile / General / Audio / Manage member / **Integrations** / Environment |
| เมนู active | `…;43:5455` | bg `rgba(88,214,141,0.1)` · ตัวอักษร `#58D68D` |
| แผงขวา | `…;3233:607796` | flex-1 · `#2B3540` · backdrop-blur 4 · p16 · gap 16 |
| หัว | `…;3233:607799/800` | "Integrations" Title/Bold 20/25 · "Manage integrations with third-party services to keep your workspace and tools in sync." (จัดการการเชื่อมต่อกับบริการภายนอก เพื่อให้ workspace และเครื่องมือ sync กัน) 14/18 `#8C99A6` · X 24 |
| แถว | `…;3233:607803` | flex col **gap 24** · divider ระหว่างแถว (สี SVG ยังไม่ได้ดึง) |

### 3.2 Integration row (Google `…;3233:607804` / Outlook `…;3237:616359`)

| ส่วน | ค่า |
|---|---|
| Row | flex row gap 24 items-center · ซ้าย flex-1 col gap 8 |
| โลโก้ | 56×56 · bg white · r8 · รูปโลโก้ (asset) |
| ชื่อ | "Google calendar" / "Outlook calendar" (c ตัวเล็ก) Body/Medium 14/18 white |
| คำอธิบาย | "Connect your Google Calendar to view and manage your schedule without leaving Zyra." (เชื่อม Google Calendar เพื่อดูและจัดการตารางเวลาโดยไม่ต้องออกจาก Zyra) 14/18 `#8C99A6` |

| State | ฝั่งขวา | ฝั่งซ้าย (หลังโลโก้) |
|---|---|---|
| **ยังไม่เชื่อม** | ปุ่ม **"Connect"** h32 px16 py8 r6 `#58D68D` 14/18 white | — |
| **เชื่อมแล้ว** | ปุ่ม **"Disconnect"** h32 px16 py8 r6 bg `rgba(240,58,58,0.05)` border 1 `rgba(240,58,58,0.2)` 14/18 `#F03A3A` | ไอคอน `insert-link` 24 + การ์ดบัญชี: bg `rgba(26,27,30,0.5)` border 1 white20% r8 p8 gap 8 · avatar 40 r90 border white20% · ชื่อ Body/Bold 14/18 · อีเมล 12/15 `#8C99A6` tracking −0.0516 |
| **หมดอายุ** (EP-02 `3613:131273`) | ไอคอน info + tooltip + ปุ่ม **"Reconnect"** ไอคอน refresh (ปุ่มรอง พื้นเข้ม + ขอบเทา — ค่า px **ยังไม่ได้ดึง**) | ไอคอนเปลี่ยนเป็น **"×"** [screenshot] + การ์ดบัญชีเดิม |
| กำลังเชื่อม / กำลังตัด | **ไม่มี frame** | — |
| เชื่อมทั้ง Google + Outlook | **ไม่มี frame** (layout คือแถวเดียวกันซ้ำ) | — |

⚠️ แถว Outlook ตอนเชื่อมแล้ว (`I3301:7924;…;3237:616364`) ปุ่มสีแดงแต่เขียนว่า **"Connect"** — น่าจะ designer ลืมแก้ ใช้ "Disconnect" แล้วแจ้ง designer

Tooltip EP-02 (`3613:131270` 285×46 @ 885,200): bg `#1A1B1E` · r8 · p8 · shadow `0 4 8 rgba(255,255,255,0.08)` · Caption 1/Regular 12/15 white · "Calendar connection expired. Please reconnect your calendar to continue syncing" (การเชื่อมต่อปฏิทินหมดอายุ กรุณาเชื่อมต่อใหม่เพื่อ sync ต่อ) · ลูกศรชี้ลง

### 3.3 OAuth popup (ของ Google / Microsoft — ไม่ใช่ UI ของเรา)

Figma วาดเป็นการ์ด 340 กว้าง ลอยกลางจอ ทับ Setting ที่ถูก dim (`Overlay` อยู่เหนือ Setting) → ความหมายคือ **เปิด popup window แยก** ไม่ redirect · Setting ค้างเปิดอยู่ข้างหลัง

| Provider | ขั้น |
|---|---|
| Google | Choose an account → You're signing back in to Zyra (Cancel / Continue) → Zyra wants access to your Google Account (340×625) |
| Microsoft | Permissions requested (340×744) — 4 scopes · Cancel / Accept · ไม่มีขั้นเลือกบัญชี |

ขนาด popup ขั้น 1–2 ของ Google: **ยังไม่ได้ดึง** · POC ใช้กล่องจำลองธรรมดา (ไม่ลอกหน้าตา Google/Microsoft)

### 3.4 Disconnect confirm — General modal (`4240:551936` 458×206 @ 491,409)

| ส่วน | ค่า |
|---|---|
| Container | `#242B32` · backdrop-blur 4 · r16 · p16 · gap **24** · ไม่มี shadow |
| Title | **"Disconnect calendar integration"** (ยกเลิกการเชื่อมต่อปฏิทิน) Sub/Medium 16/22 · X 24 · divider ใต้ title (gap 16) |
| Body | "Zyra will stop syncing events from your connected calendar. Existing Zyra meetings will remain available and won't be affected." (Zyra จะหยุด sync events จากปฏิทินที่เชื่อมไว้ · meeting ใน Zyra ที่มีอยู่จะยังอยู่ ไม่ได้รับผลกระทบ) 14/18 `#8C99A6` |
| ปุ่ม | ซ้าย = ปุ่มซ่อน (opacity 0) · ขวา gap 8: **"Cancel"** h32 r6 bg white text `#1A1B1E` · **"Disconnect"** h32 r6 bg `#F03A3A` text white · 14/18 |

ไม่ระบุชื่อ provider · วาดเฉพาะฝั่ง Google

### 3.5 Choose calendars to sync — ไม่มีใน Figma (POC ทำแบบ Zyra)

ตัดสินที่ [spec §6.1 D5](spec.md#61-ตัดสินแล้ว-ผู้ใช้สั่งในแชท-2026-10-29) · ค่าด้านล่างเป็นของ POC (ยืมจาก General modal §3.4 + Schedule event) **ไม่ใช่ค่า Figma** — รอ designer

| ส่วน | ค่าใน POC |
|---|---|
| เปิดเมื่อ | OAuth สำเร็จครั้งแรก (ไม่เปิดตอน Reconnect) · หรือกดลิงก์ "Syncing N calendars · Change" (sync อยู่ N ปฏิทิน · เปลี่ยน) ใต้คำอธิบายในแถว Integration ที่เชื่อมแล้ว (`#58D68D` 12/15 + ไอคอน `calendar-check` 14) |
| Container | เหมือน General modal: `#242B32` r16 p16 กว้าง 458 · title "Choose calendars to sync" 16/22 Medium + X 24 + divider |
| คำอธิบาย | "Select the Google Calendar calendars you want to see in Zyra." (เลือกปฏิทินของ Google Calendar ที่จะแสดงใน Zyra) 14/18 `#8C99A6` |
| ช่องค้นหา | แสดงเมื่อมีปฏิทิน **> 10** · แบบช่อง Search ของ Calendar panel (h42 r8 border `rgba(255,255,255,0.2)`) · placeholder "Search calendars" · ไม่เจอ = `No calendars match "…"` (ไม่พบปฏิทินที่ตรงกับคำค้น) |
| รายการ | สูงสุด 320 แล้ว scroll · แถว h42 p12 r8 · hover `rgba(255,255,255,0.05)` · checkbox 16 ติ๊กแล้วเป็นสีของปฏิทินนั้น · Primary มี chip "Primary" (ปฏิทินหลัก) 11/15 border `rgba(255,255,255,0.2)` |
| ค่าเริ่มต้น | ติ๊กเฉพาะ Primary (EC-02) |
| ปุ่ม | ซ้าย = "N selected" (เลือกแล้ว N) 12 `#8C99A6` · ขวา "Cancel" (ขาว) + **"Save"** (mint) h42 · ไม่ได้เลือกเลย = Save disabled |
| หลัง Save | toast เขียว "Calendars saved" (บันทึกปฏิทินแล้ว) + รายชื่อ · Calendar list ใน panel แสดง My calendar + ปฏิทินที่เลือก · ปฏิทินที่ไม่ได้เลือกไม่ sync / ไม่แสดง |

---

## 4. Toasts ของ CAL-01

ทั้งหมด = Toast component เดียวกับ [Alert §2](<../[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/ux-ui-plan.md>): 336 กว้าง · top 24 / right 24 · bg `#1A1B1E` · r16 · p16 · shadow `0 4 8 rgba(255,255,255,0.08)` · icon box 40 p8 r8 · glyph 24 · title Body/Bold 14/18 · body Body/Regular 14/18 · X 16 · ปุ่ม h32 px16 r6 `#58D68D` · ตรงกับ `zyraToast` layout figma (`lib/toast.tsx`) แล้ว · **Figma ไม่ระบุเวลาค้าง**

| Scenario | Node | Icon box / glyph | Title | Body | Action |
|---|---|---|---|---|---|
| HP-01 | `3298:5019` 336×94 | `rgba(88,214,141,0.2)` · Check | Google Calendar connected (เชื่อม Google Calendar แล้ว) | Your account is now synced with Zyra. (บัญชีของคุณ sync กับ Zyra แล้ว) | — |
| HP-02 | `3301:5059` | เขียว · Check | Outlook Calendar connected | Your account is now synced with Zyra. | — |
| HP-04 | `3601:765504` / `3601:765519` | เขียว · Check | Disconnected successfully (ยกเลิกการเชื่อมต่อแล้ว) | Google Calendar has been disconnected. / Outlook Calendar has been disconnected. | — |
| EP-01 | `3601:766197` | `rgba(240,58,58,0.2)` · X `#F03A3A` | Connection canceled (การเชื่อมต่อถูกยกเลิก) | Your calendar wasn't connected. (ยังไม่ได้เชื่อมปฏิทิน) | **ไม่มี** |
| HP-03 สำเร็จ | `3590:283992` 336×76 | เขียว · Check | **Event scheduled** (สร้าง event แล้ว) | Your event has been created. | — |
| HP-03 sync ล้มเหลว | `3601:759930` 336×112 | `rgba(255,212,0,0.1)` · Warning-triangle `#ECC819` | Calendar sync failed (sync ปฏิทินไม่สำเร็จ) | Your meeting wasn't synced to your calendar. Please sync again. | **ไม่มี** (ต้องเปิด full view กด Sync now — sticky `3601:760501`) |
| HP-05 สำเร็จ | `7816:263026` 336×72 | เขียว · Check | — (บรรทัดเดียว) | Event cancelled successfully (ยกเลิก event แล้ว) | — |
| HP-05 sync ลบไม่สำเร็จ | `7861:503358` 336×142 | `rgba(236,200,25,0.1)` · Warning-triangle `#ECC819` | Something went wrong (มีบางอย่างผิดพลาด) | Event cancelled in Zyra, but not removed from Google Calendar. (ยกเลิกใน Zyra แล้ว แต่ยังไม่ถูกลบจาก Google Calendar) | **Try again** |
| HP-05 ลบไม่สำเร็จซ้ำ | `7861:502697` 336×160 | เหลือง | Something went wrong | Couldn't remove from Google Calendar. Please delete it manually. (ลบจาก Google Calendar ไม่ได้ กรุณาลบเอง) | **Open Google Calendar** |
| HP-05 token หมดอายุ | `7861:503384` 336×142 | เหลือง | Expired token (token หมดอายุ) | Google Calendar disconnected. Reconnect to continue. (Google Calendar ถูกตัดการเชื่อมต่อ เชื่อมต่อใหม่เพื่อทำต่อ) | **Go to setting** |
| HP-05 ถูกลบ (external / organiser ถูกลบ) | `7865:507186` / `7865:506402` 336×94 | `rgba(240,58,58,0.2)` · video-off `#F03A3A` | Event deleted (event ถูกลบ) | [Event name] has been deleted from your calendar. | — |

---

## 5. Warning ใน Calendar (EP-02 / EP-03)

### 5.1 Alert banner (ใน Calendar panel ใต้ title ก่อนช่อง Search — half `3602:775170` / full `3602:775198`)

| Prop | ค่า |
|---|---|
| Node | `I3602:773964;3290:702456;3602:775941` "Alert banner" |
| พื้น / ขอบ | `rgba(236,200,25,0.1)` · 1px `rgba(236,200,25,0.2)` |
| Layout | flex row items-center gap 8 · p8 · r8 · w-full (288) |
| Icon | Warning-triangle 16 |
| Text | `#ECC819` Body/Regular 14/18 |
| EP-02 copy | "Calendar connection expired. Please reconnect your calendar to continue syncing. Go to **Setting**" (การเชื่อมต่อปฏิทินหมดอายุ กรุณาเชื่อมต่อใหม่เพื่อ sync ต่อ · ไปที่ Setting) — "Setting" Inter Medium + underline = ลิงก์ |
| EP-03 copy | "We couldn't sync your calendar after multiple attempts. Please sync again." (sync ปฏิทินไม่สำเร็จหลังลองหลายครั้ง กรุณา sync ใหม่) — **ไม่มีลิงก์ลองใหม่** · design_context ของ banner EP-03 **ยังไม่ได้ดึง** (ภาพเหมือนกัน) |

- ไม่มี warning icon บน calendar header · events เดิมยังแสดง (stale) ไม่จาง
- ตำแหน่งเดียวกับ connect banner (Display §3.3) — มีได้ทีละอัน

### 5.2 EP-02 — ไม่มี notification / toast ใน Figma

### 5.3 EP-03 — Sync now → Syncing

ปุ่ม Sync now (130×42 — Display §4) เปลี่ยนเป็น **"Syncing"** + spinner ระหว่าง sync (ปุ่มแคบลง → tab เลื่อน) · สำเร็จ = banner หายทันที **ไม่มี toast** · ค่า px ของ state Syncing **ยังไม่ได้ดึง**

---

## 6. Schedule event modal (HP-03 — ใช้ร่วมกับ CAL-02)

### 6.1 Container + fields (`3586:258261`, component `3586:257415`)

340 กว้าง (711 ค่าเริ่ม / 948–998 เมื่อเปิด dropdown หรือมี guest) · `#242B32` · r16 · p16 · gap 16 · shadow `0 4 16 #FFFFFF14` · scrollbar 6×64 r90 white20% · control h42 r8 border 1 white20% px12 py8 gap 8 icon 16 · label 14/18 white gap 8 · placeholder `#636D76`

| # | Label | Placeholder / ค่า | หมายเหตุ |
|---|---|---|---|
| — | หัว | "Schedule event" Title/Bold 20/25 · "Create and schedule meetings." 14/18 `#8C99A6` · X 24 · divider | — |
| 1 | **Event** | "Please input event" | **เปลี่ยน** จาก "Title" |
| 2 | Date & Time | "20 July, 2026" + calendar / chevron | — |
| 3–4 | — | "10:00" / "10:30" (row gap 8 · Filled gap 16 — Figma ไม่ตรงกันเอง) | ทีละ 15 นาที |
| 5 | All day | checkbox 16 r4 border `#D1D1D6` | sticky `3598:755786` "กรณีกด All day Field เวลาจะหายไป" |
| 6 | Location | "Please select location" | ดู 6.3 |
| 7 | Guest | "Please add guest" + member icon (h68) | — |
| 8 | Description | "Add description" h100 | — |
| ปุ่ม | Cancel / Create | Cancel bg white `#1A1B1E` 16/22 h42 r8 · Create disabled bg `#DBDFE3` border `#B2BBC3` text `#A3ADB8` · enabled `#58D68D` white | justify-end gap 16 |

### 6.2 Guest list + Permission (Filled `3586:282649`)

| ส่วน | ค่า |
|---|---|
| Guest list | flex col ไม่มี gap · แถว h53 w308 p8 r8 |
| Organiser | avatar 32 · ชื่อ Body/Medium 14/18 · "Organiser" 12/15 `#8C99A6` · **ไม่มี X** |
| Guest (hover) | bg `rgba(255,255,255,0.05)` · "Guest" · X 16 |
| Permission | หัว "Permission" 14/18 + chevron 14 · กล่อง `#2B3540` r8 p8 gap 8 |
| ตัวเลือก (default ตาม sticky `7802:246812`) | **Modify event** ✗ · **Invite others** ✓ · **See guest list** ✓ · checkbox ติ๊ก `#58D68D` r4 |
| ไม่มี guest | Permission หายไป (sticky `3589:283367`) |

POC เปลี่ยนรายชื่อ guest เป็นวง (pill) + X ตอน hover ตามที่ผู้ใช้ขอ (2026-10-27) — **ต่างจาก Figma** ต้องให้ design ยืนยัน

### 6.3 Dropdowns

| Dropdown | Node | ค่า |
|---|---|---|
| Mini Calendar | `3586:260046` 308×266 | [screenshot] หัว "July, 2026" + ‹ › · S M T W T F S · วันเลือกวงกลม `#58D68D` · ⚠️ มีเลข "32" ต่อจาก 31 (typo designer) · ค่า px ยังไม่ได้ดึง · **POC/โค้ดควรใช้ `AnnouncementDateField`** (ผู้ใช้สั่ง 2026-10-27) |
| Time | `3586:260164` 146×226 | [screenshot] 10:00 (เลือก = พื้นขาว 10%) · 10:15 · 10:30 … ทีละ 15 นาที |
| **Location** | `3586:260388` 308×284 | `#242B32` r16 p8 **gap 8** shadow `0 4 16 white8%` · แถวแรก "Any available meeting room" bg white10% r8 p12 + check 16 · divider · ห้อง p12 r8 min-h42 gap 8 + **pill สถานะ** |
| ↳ Available | `…;43:5907;2427:626249` | "Available" bg `#58D68D` r90 p1 · Caption 2/Medium 10/14 white |
| ↳ Booked | `…;43:5909;2427:626249` | "Booked" bg `#D41818` r90 p1 · 10/14 white |
| ↳ sticky | `7780:236310` | "พอเลือก Any available meeting room ระบบต้องเลือกห้องที่ว่าง ณ เวลาที่เราเลือกมาให้" |
| Guest list | `3586:261992` 308×321 | `#242B32` r16 p8 · แถว p12 r8 gap 8 · avatar 32 border white20% · ชื่อ 14/18 Medium · อีเมล 12/15 `#8C99A6` |
| Guest search | `3586:280961` 308×77 | แถวผล bg white10% r8 p12 · **ส่วนที่ตรงคำค้นเป็นตัวหนา** ทั้งชื่อและอีเมล |

### 6.4 Discard confirm (`3613:202062` 458×170 @ 491,427)

`#242B32` r16 p16 gap 24 · "Discard this event" Sub/Medium 16/22 · X 24 · "Your changes won't be saved." (การเปลี่ยนแปลงจะไม่ถูกบันทึก) 14/18 `#8C99A6` · **Discard** (bg white text `#1A1B1E`) · **Keep Editing** (`#58D68D` white) · h32 r6 14/18 gap 8

### 6.5 Draft chip "กำลังสร้าง" (`3613:132943` 133×32)

bg `rgba(88,214,141,0.2)` · border 1 `#58D68D` · r4 · p2 · "No title" / "10:00 - 10:30" 10/13 · แถบซ้าย opacity 0 · shadow 5 ชั้น: `0 78 11 rgba(0,0,0,0)` · `0 50 10 rgba(0,0,0,0.01)` · `0 28 8.5 rgba(0,0,0,0.05)` · `0 13 6.5 rgba(0,0,0,0.09)` · `0 3 3.5 rgba(0,0,0,0.1)`

### 6.6 Sticky ของ HP-03

| Node | ข้อความ |
|---|---|
| `3601:760501` | "sync ล้มเหลว: Zyra meeting ยังสร้างสำเร็จ พร้อม toast warning การจะ Sync now ต้องเปิด Full view ถึงจะเห็นปุ่ม" |
| `3598:755790` | "แบบ Full view จะสามารถสร้างไก้จาก ปุ่ม + กดจุดเวลาที่ตาราง" |
| `3754:429541` | "สามารถเลือกวันที่ได้ว่าจะเป็น วันเดียว หรือ หลายวัน เช่น 20 - 22 โดยการคลิกที่วัน" |
| `3598:755808` | "เมื่อกดที่ตารางจะขึ้น Event Schedule event" |
| `7816:268829` | "กรณีเขียน Description" |
| `3613:132909` / `132921` / `132928` / `132939` | chip: ตอบรับแล้ว · ยังไม่ตอบรับ · Holiday · กำลังสร้าง |

---

## 7. Event detail popup — ส่วนที่ CAL-01 เพิ่ม (`7756:45643` variants · ค่าพื้นฐาน = [Display §8](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md>))

Shell: 340 · `#242B32` · p16 gap16 r16 · shadow `0 4 16 white8%` · หัว "Event detail" Medium 14/18 · dot 12×12 r4 · divider 1px white20%

### 7.1 ไอคอนหัวตาม role

| Variant | Node | ไอคอน (16, gap 16, stroke white) | อื่น ๆ |
|---|---|---|---|
| Internal · Organizer | `7802:239608` 340×453 | **calendar-x** (= Cancel meeting) · **Edit** · Close | Location + Join |
| Internal · Attendee | `7859:499490` 340×453 | **Edit** · Close (ไม่มี calendar-x) | ⚠️ Module overview R2 บอก guest ไม่มี Modify = ดูอย่างเดียว — Figma ยังโชว์ Edit |
| Internal · Guest มี footer RSVP | variant 2 | — | footer "Join?" Yes / No / Maybe (Display §8.4) |
| External · Organizer | `7816:266948` 340×483 | **Trash** · **Edit** · Close → กดแล้ว **redirect ไป provider** (sticky `7841:498762`) | แถว video: `meet.google.com/…` `#2DB6FF` underline + Join |
| Cancelled | `7841:319230` 340×535 | **Close เท่านั้น** | ดู §8.5 |

Tooltip บน calendar-x (`7841:498759`): "Cancel meeting" (ยกเลิก meeting) · bg `#1A1B1E` · p8 r8 · 12/15 white · shadow `0 4 8 white8%` · ลูกศรล่าง

lucide ที่ใช้แทน: `CalendarX`, `Pencil`, `Trash2`, `X` ([rule 12](../../../.claude/rules/12-icons.md))

### 7.2 ตารางสิทธิ์ตามบทบาท (ใช้ใน POC — รวม Figma B1 + Module overview R2 + ClickUp HP-05/06)

| บทบาทของฉันใน event | ไอคอนหัว popup | แก้ฟอร์มได้ | ยกเลิก / เลื่อน | อื่น ๆ | ที่มา |
|---|---|---|---|---|---|
| Organiser (Zyra) | calendar-x · Edit · Close | ทุก field + Permission | ได้ | — | Figma B1 · R2 |
| Organiser · กำลังประชุม | calendar-x · Edit **disabled** + tooltip | — | ไม่ได้ (`409 MEETING_IN_PROGRESS`) | — | HP-06 EC-A · HP-05 QA |
| Workspace Admin (ไม่ใช่ผู้จัด) | เหมือน Organiser | ทุก field | ได้ | — | ClickUp HP-05/06 (Figma ไม่มี frame) |
| Guest · ไม่มีสิทธิ์ | Close | — | ไม่ได้ | RSVP footer ถ้ายังไม่ตอบ | R2 (Figma attendee ยังโชว์ Edit — I21) |
| Guest · Modify event | Edit · Close | รายละเอียด (ชื่อ/เวลา/ห้อง/description) · **Guest ล็อก** | ไม่ได้ | — | R2 · sticky `7858:498828` |
| Guest · Invite others (ค่าเริ่ม) | Edit · Close | **เพิ่ม guest อย่างเดียว** (เอาคนเดิมออกไม่ได้) · field อื่นล็อก | ไม่ได้ | — | Figma HP-05 แถว 6 `7868:509814` |
| Guest · Modify + Invite | Edit · Close | รายละเอียด + เพิ่ม/เอา guest ออก · Permission ไม่เห็น | ไม่ได้ | — | `7868:510588` |
| Guest · See guest list ปิด | ตามสิทธิ์อื่น | — | — | popup แสดงแค่จำนวน "N participants" ไม่โชว์รายชื่อ | ClickUp Permission (Figma ไม่มี frame) |
| Organiser · event จาก Google/Outlook | Trash · Edit · Close — **เป็นลิงก์ไป provider (เปิดแท็บใหม่) + tooltip "ลบ/แก้ไขได้ที่ Google Calendar เท่านั้น"** | — | ลบใน Zyra ไม่ได้ — ลบที่ต้นทางแล้ว sync กลับ (toast "Event deleted") | — | sticky `7841:498762` + กติกาผู้ใช้ 2026-10-29 |
| Guest · event จาก Google/Outlook | Trash (ลิงก์ + tooltip) · Close | — | ลบใน Zyra ไม่ได้ | — | กติกาผู้ใช้ 2026-10-29 (Figma `7865:508350` ไม่มีไอคอน — ต้องให้ design อัปเดต) |
| Event ที่ถูกยกเลิก (สร้างใน Zyra) | Close | — | — | **ค้างในปฏิทินทุกคนเป็นขีดฆ่า** + "Reason for cancellation" | `7841:319230` + กติกาผู้ใช้ 2026-10-29 |

หมายเหตุ POC: แยก Modify (แก้รายละเอียด) กับ Invite (เพิ่มคน) ให้ชัด — Google Calendar จริงถือว่า Modify รวมสิทธิ์เชิญด้วย ต้องให้ PM ยืนยันว่า Zyra จะทำแบบไหน · ป้าย "POC · คุณเป็น …" ใน popup/ฟอร์มมีไว้สาธิตเท่านั้น ไม่อยู่ใน design

### 7.3 แถวใหม่ (`7816:268127` 340×503)

- **Description** (ใหม่): icon `text-align-start` 16 · gap 16 · ข้อความ 14/18 `#8C99A6`
- Link: **`#2DB6FF` underline** (เดิม `#8C99A6`) + ปุ่ม copy p4 r4 white5% border white20%
- Organiser มี status badge เขียว (check) มุมขวาล่าง avatar
- ⚠️ "3 participants (1 yes and 3 awaiting)" ตัวเลขยังไม่ตรงกันเหมือนเดิม

---

## 8. HP-05 · ยกเลิก Meeting (section `7802:237620`)

### 8.1 Flow ที่วาด

| แถว | Frames | Sticky |
|---|---|---|
| 1 · Organiser สร้าง Event จาก Zyra | `7802:239605` Event detail + tooltip → `7816:263017` Cancel modal → `7816:263021` ปฏิทิน (event หายจากจอผู้ยกเลิก) + toast สำเร็จ → ภาพ Google Calendar | `7816:263030` "คนอื่นได้รับแจ้งเตือน MA-EP-02 · Meeting ถูกยกเลิก / เลื่อนเวลาหลัง Alert ส่งไปแล้ว" |
| 2 · Organizer สร้าง Event จาก Google/Outlook | `7816:266946` Event detail (External) → ภาพ Google → `7858:498834` → `7865:507184` toast "Event deleted" → `7865:507187` Notification | `7858:498768` "External : Meeting ถูกลบ" · `7841:498762` "External จะไม่มีการยกเลิก จะเป็นการ Delete หรือ ลบแทน Edit และ Delete จะเป็นการกดแล้ว Redirect ไปยังเจ้านั้นๆ" · `7858:499484` "ถ้า Delete จากข้างนอก = Calendar view ใน Zyra จะไม่โชว์ Meeting นั้น" |
| 3 · Attendee พยายามยกเลิก | `7859:499488` Event detail ไม่มี calendar-x | `7859:500163` "Yes/No/Maybe CLDD-HP-05 · กด Event Card ดู Detail Popup" · `7868:512931` "Guestไม่เห็นยกเลิก และ ลบ" |
| 4 · Sync ยกเลิกล้มเหลว | `7859:500169` → `7859:500173` modal → `7859:500177` toast สำเร็จ → `7859:502074` "Event cancelled in Zyra, but not removed…" [Try again] → `7861:502692` "Couldn't remove…" [Open Google Calendar] / `7861:503379` "Expired token" [Go to setting] | `7859:502068` "External ลบไม่สำเร็จ" |
| 5 · Organizer ถูกลบบัญชี | `7863:503986` → `7863:504661` → `7865:506400` toast "Event deleted" → `7865:505909` Notification | `7863:505904` "Organiser ถูกลบ Appointment หายไป" |
| 6 · Event ที่ sync เข้ามา | `7865:507695` Organiser · `7865:508350` Guest (ไม่เห็นยกเลิก/ลบ) · `7868:509003` Guest+Modify → Schedule event · `7868:509814` Guest+Invite → modal · `7868:510588` Guest ได้ทั้ง 2 | `7858:498828` "Meeting ที่ Organiser ให้ Permission Guest Modify ไม่สามารถยกเลิก หรือ ลบ ได้" · `7865:508345` "Organiser" · `7868:511279` "Guest ไม่เห็นยกเลิก กับ ลบ" · `7865:508349` "Guest ได้สิทธิ์ Modify" · `7868:510494` "Guest ได้สิทธิ์ Invite other guest" · `7868:511266` "Guest ได้สิทธิ์ทั้ง 2" |
| 7 · Recurring meeting | **ว่าง** | — |

### 8.2 Overlay

เต็มจอ `rgba(0,0,0,0.5)` (`7816:263019`)

### 8.3 Cancel meeting modal (`7841:498103` 455×509 @ 493,258)

| ส่วน | ค่า |
|---|---|
| Container | `#242B32` · p16 · gap 16 · r16 · w 455 · flex col |
| หัว | "Cancel meeting" (ยกเลิก meeting) Inter Medium 16/22 · X 24 · divider white20% |
| คำถาม | "Are you sure you want to cancel this meeting?" (ต้องการยกเลิก meeting นี้ใช่ไหม) 14/18 white |
| แถวข้อมูล | col gap 16 · แถว = icon 16 + gap 16 + (label 14/18 white / ค่า 14/18 `#8C99A6` gap 8 truncate) |
| ↳ | `Name` (T) · "Event" / "New project consult" |
| ↳ | `Calendar` · "Date & time" / "20 July, 2026 • 10:00 - 10:30" |
| ↳ | `member` · "Attendees to be notified" / "3 attendees will be notified of this cancellation." (attendee 3 คนจะได้รับแจ้งการยกเลิกนี้) |
| เหตุผล | "Reason " white + "(Optional)" `#8C99A6` · textarea h100 px12 py8 r8 border white20% · placeholder "Reason to cancel the event." `#636D76` · ตัวนับขวา "0" Medium 12/15 white + "/200" 12/15 `#8C99A6` |
| ปุ่ม | ซ้าย "Clear all" **opacity 0** · ขวา gap 8: **Cancel** bg white `#1A1B1E` · **Confirm** bg `#F03A3A` white · Regular 16/22 · h42 px16 py8 r8 |
| ไม่มีใน Figma | checkbox "แจ้ง attendees ทาง notification" (ClickUp) · state disabled / loading / error · validation เกิน 200 |

### 8.4 Toasts — ดู §4 (แถว HP-05)

### 8.5 Cancelled state (Figma Meeting Alert MA-EP-02 `7841:319229` — ฝั่ง attendee)

| ชิ้น | ค่า |
|---|---|
| Timed block (`I7771:198060;3298:4784;7841:318780` 127.7×70) | bg **`rgba(255,255,255,0.1)`** · bar 2×8 r90 **`#8C99A6`** · title / time 10/13 white · **เส้นขีดฆ่า 1px `#F03A3A`** 2 เส้น (ทับ title และทับเวลา) |
| Event detail cancelled (`7841:319230` 340×535) | Close อย่างเดียว · dot `#8C99A6` · ไม่มี Join / link · ท้าย: divider → "Reason for cancellation" (เหตุผลที่ยกเลิก) 14/18 white → เหตุผล 14/18 `#8C99A6` |
| Upcoming card | จางลง [screenshot] · opacity ยังไม่ได้ดึง |
| ผู้ยกเลิก (HP-05 แถว 1) | Figma: event **หายจาก grid** ของผู้ยกเลิก — **ผู้ใช้กำหนดใหม่ 2026-10-29: ให้ค้างเป็นขีดฆ่าเหมือน attendee** (ต้องแจ้ง designer แก้ frame `7816:263021`) |

⚠️ 2026-10-27 เคยเห็น block นี้เป็น `opacity-0` — ตรวจ 2026-10-29 ไม่มีแล้ว (designer แก้กลับ) · ต้องแก้ใน [Meeting Alert ux-ui-plan §5](<../[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/ux-ui-plan.md>)

---

## 9. Module overview (`7789:1282008`) — กติกากลางที่ designer ใส่ไว้

- **Scope:** Internal = สร้างใน Zyra · External = มาจาก Google/Outlook · ตอนนี้: Internal 01–06 + External แบบ 2 (เปิด event จริงที่ต้นทาง แล้ว sync กลับ — 07–10) · อนาคต: External แบบ 1 (แก้/ยกเลิกใน Zyra แล้ว write กลับ provider — 11–16)
- **R1** field ที่แก้ได้: ชื่อ, รายละเอียด, วัน-เวลาเริ่ม/จบ, ทั้งวัน, time zone, สถานที่/ลิงก์ประชุม, ผู้เข้าร่วม, สิทธิ์ Guest Modify
- **R2** สิทธิ์: ผู้สร้าง Internal → ดู/แก้/ลบ (backend ตรวจซ้ำ) · Guest + Modify → ดู/แก้ ไม่แสดงลบ backend ต้องปฏิเสธ · Guest ไม่มี Modify → ดูอย่างเดียว
- **R3** recurring ต้องเลือก instance/series (ข้อเสนอ: ครั้งนี้ / ครั้งนี้และถัดไป / ทั้งชุด — ยังไม่สรุป)
- **R5** organizer ยกเลิกนัด ≠ ผู้เข้าร่วมเอารายการออกจากปฏิทินตัวเอง · ห้ามสรุปว่ายกเลิกจากการที่รายการหายไปอย่างเดียว
- **R6** เก็บ/ส่งวันที่ ISO ค.ศ. · แสดง พ.ศ. ได้แต่ต้องแปลงชัด + time zone
- **รอตัดสิน:** recurring scope, นโยบายแจ้งผู้เข้าร่วมเมื่อแก้/ลบ, sync/retry/freshness, conflict/version/draft, ความสามารถ API ของ provider, การแสดง cancel vs remove
- การ์ด scenario 16 ใบ (A `7789:1282946` 01–06 · B `…947` 07–10 · C `…948` 11–16): **มีแค่หัวข้อ — เนื้อหายังไม่ได้ดึง**

---

## 10. Figma vs ClickUp — ข้อขัดแย้งที่ต้องถาม

### 10.0 ผลตัดสิน (ผู้ใช้ 2026-10-29 — ขัดกันให้ยึด Figma, [spec §6.1](spec.md#61-ตัดสินแล้ว-ผู้ใช้สั่งในแชท-2026-10-29))

| ผล | ข้อ |
|---|---|
| **ยึด Figma** | I1 (UI อังกฤษ + คำแปลใน `th.json`) · I2 · I3 · I4 (D4) · I6 · I7 (D7) · I8 (D8) · I10 · I11 (ไม่มีลิงก์ลองใหม่ใน banner) · I12 · I13 (ไม่มี checkbox — ข้อความคงที่) · I14 · I16 (RSVP) · I18 · I21 (R2) |
| **ทำตาม ClickUp เพราะผู้ใช้สั่ง** | I5 → ทำหน้าเลือกปฏิทิน + Save (D5, §3.5) · push meeting เดิมตอนเชื่อม (D6) |
| **ผู้ใช้ตัดสินต่างจากทั้งคู่** | I17 → ยกเลิกแล้วยังอยู่เป็นขีดฆ่าให้ทุกคนเห็น (D1) |
| **ยังเปิด** (Figma ไม่ได้วาด ไม่ใช่ขัดกัน) | I9 แจ้งเตือน EP-02 · I15 Workspace Admin ยกเลิกได้ไหม · I19 auto-retry · I20 HP-06 Reschedule · I22 designer แก้ label ปุ่ม Outlook |

| # | หัวข้อ | ClickUp | Figma | ต้องถาม |
|---|---|---|---|---|
| I1 | ภาษา | ไทยทุกข้อความ | อังกฤษทุกจอ | copy ไทยใน `th.json` |
| I2 | ทางเข้า | Workspace Settings → Integrations → Calendar | Setting modal → Integrations (ไม่มีหมวด Calendar ย่อย) | — (ยึด Figma) |
| I3 | ปุ่ม | "เชื่อมต่อ Google Calendar" / "เชื่อมต่อ Microsoft Outlook" / "ยกเลิกการเชื่อมต่อ" | "Connect" / "Disconnect" | copy |
| I4 | Badge สถานะ | Connected / "ไม่ได้เชื่อมต่อ" / "หมดอายุ" สีเหลือง | **ไม่มี badge** — การ์ดบัญชี + ปุ่ม · หมดอายุ = ไอคอน × + info + Reconnect | ต้องมี badge ไหม |
| I5 | Calendar selector + "บันทึก" (HP-01 optional / HP-02) | มี | **ไม่มี** | ทำไหม (โค้ดใช้ Calendar list ใน panel แทน) |
| I6 | Toast HP-01 | "เชื่อมต่อ Google Calendar สำเร็จ — กำลัง sync events..." | "Google Calendar connected" / "Your account is now synced with Zyra." | copy |
| I7 | Confirm disconnect | ระบุ provider + "Events จาก Google จะไม่แสดงใน Zyra" | "Disconnect calendar integration" ไม่ระบุ provider + "meeting เดิมยังอยู่" | copy |
| I8 | EP-01 | **banner** + ปุ่ม "ลองใหม่" + หายใน 10 วิ | **toast แดง** ไม่มีปุ่มลองใหม่ | ยึดแบบไหน |
| I9 | EP-02 แจ้งเตือน | notification 1 ครั้ง | ไม่มี frame notification / toast | ต้องมีไหม · ช่องทางไหน |
| I10 | EP-02/03 ตำแหน่ง warning | icon บน calendar header + tooltip | **banner ใน panel** (tooltip อยู่ใน Settings) | — (ยึด Figma) |
| I11 | EP-03 copy + retry | "⚠ Events อาจไม่อัปเดต — [ลองใหม่]" | "We couldn't sync your calendar after multiple attempts. Please sync again." · retry = Sync now ใน full view | copy · ต้องมีลิงก์ลองใหม่ใน banner ไหม |
| I12 | HP-03 sync ล้มเหลว | toast warning | toast ไม่มีปุ่ม retry · sticky ให้ไปกด Sync now ใน full view | — |
| I13 | HP-05 checkbox แจ้ง attendees | มี (default ✅) | **ไม่มี** — ข้อความคงที่ "N attendees will be notified" | ต้องมี checkbox ไหม |
| I14 | HP-05 ปุ่ม | "ยกเลิก Meeting" สีแดงใน popup | ไอคอน calendar-x + tooltip "Cancel meeting" | — (ยึด Figma) |
| I15 | HP-05 ใครยกเลิกได้ | Organizer + Workspace Admin | Organizer (ไม่มี frame admin) | admin ด้วยไหม |
| I16 | HP-05 attendee | ปุ่ม "ปฏิเสธเข้าร่วม" | RSVP Yes/No/Maybe ใน footer | ใช้ RSVP เดียวกัน |
| I17 | HP-05 event หลังยกเลิก | หายจาก calendar ทุกคน + Meeting History | ผู้ยกเลิก: หาย · attendee: เทา + ขีดฆ่า + เหตุผล | ยึดแบบไหน · Meeting History อยู่ไหน |
| I18 | HP-05 toast | "ยกเลิก [ชื่อ] แล้ว" | "Event cancelled successfully" | copy |
| I19 | HP-05 EP-B retry | auto-retry 30s → 2m → 5m แล้วแจ้ง organizer | toast Try again → Open Google Calendar | ทั้ง 2 ร่วมกันได้ |
| I20 | **HP-06 Reschedule** | dialog เฉพาะเวลา + เหตุผล + checkbox + conflict | **ไม่มีใน Figma** — มีแต่ Edit (ดินสอ) เปิด Schedule event ทั้งชุด | ต้องให้ designer วาด หรือใช้ Edit แทน |
| I21 | Edit ของ attendee | HP-05/06: เฉพาะ Organizer/Admin | Figma attendee ยังมี Edit · R2 = เฉพาะ guest ที่มี Modify | ยืนยัน R2 |
| I22 | ปุ่ม Outlook เชื่อมแล้ว | — | เขียน "Connect" ในปุ่มแดง | designer แก้ |

---

## 11. เปลี่ยนจากเอกสารเดิม ([MeetingCalendarIntegration/ux-ui.md](../MeetingCalendarIntegration/ux-ui.md))

| # | เดิม | ตอนนี้ |
|---|---|---|
| C1 | HP-04 มี frame ปฏิทินหลัง disconnect (`3601:765821`, `3601:765808`) | **ถูกเอาออก** |
| C2 | EP-01 แถว 2 `3601:769050` = "กดลองใหม่" (เดา) | คือ popup Microsoft (ฝั่ง Outlook) |
| C3–C4 | Connected / ไม่ได้เชื่อมต่อ เป็น badge | ไม่มี badge — การ์ดบัญชี / ปุ่ม Connect |
| C5 | Confirm copy = ClickUp | "Disconnect calendar integration" + body ใหม่ |
| C6 | Field แรก "Title" / "Please input title" | **"Event" / "Please input event"** |
| C7 | Toast "Meeting scheduled" / "Your meeting has been created." | **"Event scheduled" / "Your event has been created."** |
| C8 | Location: badge จำนวนคน | **pill Available / Booked** + ต้องเลือกห้องว่างให้เมื่อเลือก "Any available" |
| C9 | Submenu `3586:280961` = Permission (เดา) | ผลค้น guest (ตัวหนาส่วนที่ตรง) |
| C10 | Event details `3594:752725` 340×419 | **Event detail** `7756:45548` 453 / `7816:268127` 503 — หัว + calendar-x/Edit/Close · Description · link ฟ้า |
| C11 | EP-02/03 warning "ยังไม่ได้ดึง" | banner เหลืองใน panel (§5) |
| C12 | ไม่มี HP-05 | section ใหม่ `7802:237620` (§8) |

---

## 12. ยังไม่ได้ดึง

- สี divider (SVG) ใน Setting / modal · overlay ใน frame OAuth · ขนาด popup Google ขั้น 1–2
- ปุ่ม Reconnect + info icon (px) · banner EP-03 (design_context) · state "Syncing" (px)
- Mini Calendar / Time submenu (px — มีแค่ภาพ)
- Event detail ของ External synced-in (`7865:507697`, `7865:508352`) · Schedule event โหมด guest แก้ (`7868:509648/509816/510590`) · Notification "Event deleted" (`7865:507187`, `7865:505909`)
- เนื้อหาการ์ด scenario 01–16 · โลโก้ provider บน chip (`7893:532052`/`532079`)
- hover / pressed / disabled / loading ของทุกปุ่ม · ระยะเวลาค้างของ toast — ไม่มีใน Figma
- **HP-06 Reschedule ทั้งหมด** — ไม่มีใน Figma
