# Gap analysis — SC-MTG-CAL-02 Calendar Display (Month / Week / Day)

> **ตรวจเมื่อ:** 2026-10-27 · read-only · โค้ด = `origin/develop` (zyra-app `22fc0d6d`, zyra-api `aaf5d7c`) — line number อ้างตาม commit นี้ · ยังไม่ได้รัน test
> **ใช้คู่กับ:** [spec.md](spec.md) · [ux-ui-plan.md](ux-ui-plan.md) · จุดที่ทับกับ Meeting Alert ดู [spec.md §7](spec.md#7-จุดที่ทับกับ-meeting-alert-sc-mtg-cal-03)
> **อ้างอิง requirement:** `zyra-doc/plan/[Feature] Meeting — Calendar Display/spec.md` (ClickUp) + `ux-ui-plan.md` (Figma CAL-02, §10 U1–U22)
> **ฐานที่มีอยู่:** CAL-01 (Google connect + Zyra scheduled meetings) — calendar panel / full view / Event details สร้างไว้แล้ว
> **หมายเหตุสำคัญ:** UI ปัจจุบันวาดตาม **Figma ของ CAL-01** (`3298:4784` — 12 ชม. ต่อ 800px, gutter 80, เลขวัน 45px) ไม่ใช่ Figma ของ CAL-02 (`7753:37904` — 72px/ชม., gutter 64, GMT+7, All-day band) → ค่าหลายตัวด้านล่างจึงเป็น ⚠️ "ทำแล้วแต่ต่างจาก Figma CAL-02"
> **Legend:** ✅ done · 🟡 partial · ❌ missing · ⚠️ done-but-differs (จาก ClickUp หรือ Figma CAL-02) · "ยังไม่ได้ตรวจ" = ไม่ได้ verify

ไฟล์หลักที่ใช้อ้างอิง (repo-relative):

| ไฟล์ | บทบาท |
|---|---|
| `zyra-app/views/user/virtual-office/components/calendar/vo-calendar.tsx` | panel ซ้าย + state (mode, date, banner, popup) |
| `zyra-app/views/user/virtual-office/components/calendar/calendar-main-view.tsx` | toolbar + Month grid + Week/Day time grid |
| `zyra-app/views/user/virtual-office/components/calendar/calendar-parts.tsx` | chip, now-line, checkbox, banner, upcoming card |
| `zyra-app/views/user/virtual-office/components/calendar/calendar-event-details.tsx` | Event details popup (Zyra meeting เท่านั้น) |
| `zyra-app/views/user/virtual-office/components/calendar/use-calendar-data.ts` | fetch + merge Zyra + Google (useEffect/useState) |
| `zyra-app/lib/calendar/calendar-dates.ts` | date maths + overlap lane layout (ไม่มี date library) |
| `zyra-app/lib/api/calendar-integration.ts` / `calendar-meetings.ts` | API client |
| `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` | entry point, flag gate, mount half/full |
| `zyra-api/internal/router/router.go` · `internal/service/calendar_*` · `internal/model/calendar_*` · `migrations/115–117` | API |

---

## (A) AC status

### CLDD-HP-01 · เปิด Calendar View ครั้งแรก

| AC / จุดตรวจ | สถานะ | หลักฐาน / หมายเหตุ |
|---|---|---|
| Entry: icon Calendar ใน sidebar (ลำดับ 4) | ✅ (มีเงื่อนไข) | `zyra-app/views/user/virtual-office/components/vo-sidebar.tsx:80` · กดแล้วเปิด **Half view** ก่อน (`hero-virtual-office.tsx:4922-4936`) → ปุ่ม Expand → Full view (`vo-calendar.tsx:249-257`) ตรง flow Figma HP-01 · **gated by `GOOGLE_CALENDAR_ENABLED`** ดู (C) |
| AC-HP01-1 โหลดเสร็จ ≤ 5 วิ | ยังไม่ได้วัด | ไม่มี perf work · ตอนเปิดยิง 2–5 request ขนาน (meetings main+today, Google calendars/events main+today — `use-calendar-data.ts:188-213`) · `GET /meetings` ทำ `reconcileWithGoogle` แบบ synchronous ทุกครั้ง (`zyra-api/internal/service/calendar_meeting_service.go:367`, throttle 20 วิ/meeting `calendar_meeting_inbound.go:34`) — อาจเพิ่ม latency |
| AC-HP01-2 Default = Month | ✅ | `vo-calendar.tsx:126-127` `useState<CalendarViewMode>("month")` (ผู้ใช้ขอ 2026-10-21; Figma CAL-02 HP-01 full view ก็เป็น Month) · test `__tests__/vo-calendar.test.tsx:212-224` · mode reset ทุกครั้งที่ปิด calendar (state อยู่ใน VOCalendar) |
| AC-HP01-3 วันปัจจุบัน highlight | ✅/⚠️ | Month: วงกลม `bg-[#58D68D]` (`calendar-main-view.tsx:371-377`) ✅ · Week/Day header: วงกลม **45px** (`calendar-main-view.tsx:175`) vs Figma CAL-02 **30px** ⚠️ · ไม่มี today-column shade `rgba(88,214,141,0.03)` ⚠️ · Mini calendar ไฮไลต์ **วันที่เลือก** ไม่ใช่วันนี้ (`calendar-mini-month.tsx:73-74,93-94`) — เลือกวันอื่นแล้ววันนี้ไม่ highlight ⚠️ |
| AC-HP01-4 Color legend Zyra/Google/Outlook | ⚠️/❌ | "Calendar list" ใน panel (`vo-calendar.tsx:331-358`) = My calendar (เขียว) + ปฏิทิน Google ทีละอัน + Thai Holidays (ฟ้า `#2DB6FF`) · สี: `calendarColor()` holiday `#2DB6FF` / primary `#58D68D` / อื่น ๆ = สีจาก Google (`calendar-parts.tsx:38-44`) → **Google primary ก็เขียวเหมือน Zyra** · ไม่มี Google `#4285F4` / Outlook `#0078D4` / Zyra `#79DEA5` หรือ Indigo · **ไม่มี Outlook เลย** · legend อยู่ใน panel ซ้าย (ตรง Figma) ไม่ใช่ "ใต้ calendar" ตาม ClickUp |
| AC-HP01-5 ยังไม่ connect → เฉพาะ Zyra + banner | ✅/⚠️ | Zyra meetings โหลดเสมอไม่ขึ้นกับ Google (`use-calendar-data.ts:205-213`, test `vo-calendar-meetings.test.tsx:220`) ✅ · banner แสดงเมื่อ `!connected && !bannerDismissed` (`vo-calendar.tsx:279-281`) ✅ · **copy ต่างจาก Figma CAL-02**: code "No calendar connected" / "Connect a calendar in Settings > Integrations…" (`zyra-app/messages/en.json:1796-1797`) vs Figma "Connect your calendar" / "Bring your Google or Outlook events into Zyra…" ⚠️ · ปิดแล้ว**ไม่กลับมาอีกเลย** (`localStorage zyra_gcal_banner_dismissed = "1"`, `vo-calendar.tsx:50,53-59,235-242`) vs Figma sticky "โผล่เตือนวันละครั้ง" ⚠️ · ปุ่ม Go to setting → Setting/Integrations ✅ (`hero-virtual-office.tsx:15519-15524`) |

### CLDD-HP-02 · Month View

| AC / จุดตรวจ | สถานะ | หลักฐาน / หมายเหตุ |
|---|---|---|
| Grid 7 × rows | ✅ (6 แถวคงที่) | `grid-cols-7 grid-rows-6` (`calendar-main-view.tsx:351`) · `monthGridDays` = 42 วัน (`lib/calendar/calendar-dates.ts:47-50`) → ตรง Figma U4 (6 แถวเสมอ), ClickUp บอก 4–6 |
| AC-HP02-1 วัน overflow greyed | ⚠️ | สี `#636D76` (`calendar-main-view.tsx:376`) vs Figma `#8C99A6` |
| Cell size / padding | ⚠️ | `min-h-[96px] p-[4px]` (`calendar-main-view.tsx:362`) vs Figma 144.857×141.833 p8 · เลขวัน `size-[24px]` vs Figma w23 p4 |
| AC-HP02-2 Chip = dot + ชื่อ (truncate) | ⚠️ (vs ClickUp) | Chip = **bar 2×8** + tint `rgba(88,214,141,0.2)` + ชื่อ 10/13 truncate (`calendar-parts.tsx:160-216`) → ตรง Figma, ไม่ใช่ "dot" ตาม ClickUp (U5) · variant outline = needsAction/tentative/**declined** (`calendar-parts.tsx:152-158`) — Figma ไม่บอกความหมาย · **สี chip ไม่ได้แยกตาม source**: Google event (ไม่ใช่ holiday) ก็เขียวเหมือน Zyra |
| Max 3 chips | ✅ | `MONTH_CHIPS = 3` (`calendar-main-view.tsx:46,381`) |
| "+X more" | ⚠️ | แสดง `<p>` "+{count} more" สีเทา `#8C99A6` ไม่มี bg (`calendar-main-view.tsx:390-394`, `messages/en.json:1817`) · copy ตรง ClickUp แต่ Figma = "2 More" bg Primary/20% text `#58D68D` (U6) |
| AC-HP02-3 กด "+X more" → popup ทุก event | ❌ | ไม่มี onClick / popup — เป็นแค่ข้อความ |
| AC-HP02-4 เรียงตาม start asc | ✅ | sort (`calendar-main-view.tsx:353-357`) |
| AC-HP02-5 All-day บนสุด | ✅ | `Number(b.all_day) - Number(a.all_day)` ก่อน start (`calendar-main-view.tsx:355`) |
| Prev / Next เดือน | ✅ | `shiftDate` (`calendar-dates.ts:67-71`), `vo-calendar.tsx:423-424` · test `calendar-dates.test.ts:72-81` |
| AC-HP02-6 เปลี่ยนเดือน ≤ 300ms | ยังไม่ได้วัด | render เป็น sync แต่ข้อมูล refetch ทุกครั้ง ไม่มี cache/prefetch (ไม่ใช้ react-query) · ไม่มี loading indicator ระหว่างรอ |
| กดวันใน Month → Day view | ✅ | `onDateChange(day); onModeChange("day")` (`calendar-main-view.tsx:364-370`) = AC-HP04-2 · ไม่มี test |

### CLDD-HP-03 · Week View

| AC / จุดตรวจ | สถานะ | หลักฐาน / หมายเหตุ |
|---|---|---|
| AC-HP03-1 7 คอลัมน์ ไม่ scroll แนวนอน | ✅ | `columnDays` + `flex-1` (`calendar-main-view.tsx:154-159,237-240`) |
| AC-HP03-2 ความสูง ∝ duration (30 นาที = 1 row) | ⚠️ | สูงตามนาทีจริง ✅ แต่ `HOUR_PX = 800/12 ≈ 66.67` (`calendar-main-view.tsx:39`) vs Figma CAL-02 **72px/ชม., 36px/30 นาที** · grid line มีแค่รายชั่วโมง (24 ช่อง `calendar-main-view.tsx:274-292`) ไม่มี half-hour rule `rgba(255,255,255,0.03)` · min-height chip 17 vs Figma 48 · ไม่มี inset 4px ซ้าย/ขวา |
| 00:00–23:30 scroll ได้ + initial scroll | ✅/⚠️ | grid สูง 24 ชม. scroll ได้ (`calendar-main-view.tsx:222-227`) ✅ · เปิดที่ (ชม.ปัจจุบัน − 1) ถ้า view มีวันนี้ ไม่งั้น 08:00 (`calendar-main-view.tsx:210-220`) ✅ (Figma ไม่ระบุ — U8) · label "01".."23" 14px white ชิดขวา (`calendar-main-view.tsx:228-236`) vs Figma "08:00" 10/13 `#8C99A6` w56 ⚠️ · ไม่มี scrollbar style ตาม Figma |
| คอลัมน์ "GMT+7" (time-zone) | ❌ | ไม่มี — gutter 80px ว่าง (`calendar-main-view.tsx:43,165`) vs Figma w64 + "GMT+7" |
| AC-HP03-3 Overlap side-by-side เท่ากัน | ✅/⚠️ | `layoutTimedEvents` จัด lane ต่อกลุ่มที่ทับกันแบบ transitive (`calendar-dates.ts:137-169`) → รองรับ ≥3 อันได้ ทุกอันในกลุ่มกว้าง `100/lanes`% (`calendar-main-view.tsx:303-308`) ✅ · ไม่มี gap 4px ระหว่าง lane / inset 4px (Figma) ⚠️ · test `calendar-dates.test.ts:116` (2 อัน) — ไม่มี test ≥3 |
| AC-HP03-4 All-day row เหนือ time grid | ❌/🟡 | **ไม่มี band แยก** — all-day chip วาง `absolute top-[7px]` ทับบนคอลัมน์ใน time grid ที่ scroll ได้ (`calendar-main-view.tsx:323-338`) → scroll หาย + ทับ event ช่วง 00:00–01:00 · Figma: row h32 + label "All-day" (Day: "—" ถ้าว่าง) |
| AC-HP03-5 เส้นเวลาปัจจุบันสีแดง | ✅/⚠️ | `CalendarNowLine` dot 8 + line 2px `#F03A3A` เฉพาะ column วันนี้ (`calendar-parts.tsx:82-98`, `calendar-main-view.tsx:339-341`), tick ทุก 60 วิ (`vo-calendar.tsx:51,141-144`) ✅ · ไม่มี label แดง "10:10" 50×18 (Figma) ⚠️ |
| Prev / Next สัปดาห์ | ✅ | `shiftDate` week ±7 |
| Header ช่วงวันที่ | ⚠️ | แสดง "July, 2026" ทุก mode (`calendar-main-view.tsx:95-97`) — Figma Week layer "20 July, 2026" แต่ render "July, 2026" (U22) |
| Event block content (Week) | ⚠️ | มีแค่ bar + title (`calendar-parts.tsx:209-214`) — Figma: title + "09:00–10:00" · เวลาโผล่แค่ใน `title=` tooltip (`calendar-parts.tsx:193`) |
| AC-HP03-6 Mobile swipe | ❌ | calendar ไม่ render บน mobile เลย: `!mobileSpatial && calendarView !== "closed"` (`hero-virtual-office.tsx:15501-15503`) · lite bottom nav ซ่อน Calendar (`lite/lite-bottom-nav.tsx:21`) · ไม่มี swipe handler/lib |

### CLDD-HP-04 · Day View

| AC / จุดตรวจ | สถานะ | หลักฐาน / หมายเหตุ |
|---|---|---|
| AC-HP04-1 1 วันเต็มหน้า + scroll แนวตั้ง | ✅ | Day = TimeGrid คอลัมน์เดียว (`viewRange` day `calendar-dates.ts:54-57`) |
| AC-HP04-2 กดวันใน Month → Day | ✅ | `calendar-main-view.tsx:364-370` |
| AC-HP04-3 Block แสดงชื่อ + เวลาเริ่ม | ❌ | ใช้ `CalendarEventChip` ตัวเดียวกับ Week → title อย่างเดียว · Figma Day: title + start–end + location `#CAD0D6` 12/15 (U9) |
| Prev / Next วัน | ✅ | `shiftDate` day ±1 |
| All-day section (EC-02) / "—" เมื่อว่าง | ❌ | เหมือน Week (ไม่มี band) |
| Current-time line เต็มความกว้าง | ✅ | Day มีคอลัมน์เดียว → `inset-x-0` เต็มกว้าง |
| AC-HP04-4 Mobile swipe | ❌ | เหมือน HP-03 |

### CLDD-HP-05 · Event Detail Popup

| AC / จุดตรวจ | สถานะ | หลักฐาน / หมายเหตุ |
|---|---|---|
| กด event ใด ๆ เปิด popup | 🟡 | **เฉพาะ Zyra meeting** — `openerFor` คืน undefined ถ้า `calendar_id !== MY_CALENDAR_ID` (`calendar-main-view.tsx:71-75`), `openEvent` guard (`vo-calendar.tsx:227-232`) · Google event กดไม่ได้เลย |
| AC-HP05-1 field ครบ | 🟡 | มี: title (`calendar-event-details.tsx:84-86`), วันที่ • เวลา (`:100-107`), location/ห้อง (`:108-111`), attendees avatar+ชื่อ+role (`:131-164`), join link + Copy (`:167-181`) · **ไม่มี description** (field `meeting.description` มีใน data แต่ไม่ render) · ไม่มี header "Event detail" |
| AC-HP05-2 Source badge | ❌ | มีแค่ swatch 12×12 `#58D68D` ตายตัว (`calendar-event-details.tsx:83`) — ตรง Figma (U11) แต่ไม่มีข้อความ "Zyra Meeting / Google Calendar / Outlook" |
| AC-HP05-3 "Join Now" เฉพาะ `meeting_status = active` | ⚠️/❌ | ปุ่ม **"Join"** (`messages/en.json:1855`) แสดง**ทุกครั้ง** (`calendar-event-details.tsx:113-121`) · **ไม่มี `meeting_status` ใน DB/model** (`zyra-api/migrations/117_calendar_meeting.sql`, `internal/model/calendar_meeting.go:45-69`) → "active" ยังไม่มีนิยาม · Join → เดินไปห้อง/zone ผ่าน `openMeetingLink` (`hero-virtual-office.tsx:12672-12692`) ✅ |
| AC-HP05-4 link "เปิดใน Google Calendar / Outlook" | ❌ | `html_link` / `google_html_link` มีใน model (`lib/api/calendar-meetings.ts:45,141`; Google `CalendarEvent.html_link` `lib/api/calendar-integration.ts:53`) แต่ไม่ใช้ใน UI · Figma ก็ไม่มี (U14) |
| AC-HP05-5 ESC / click-outside | ❌ | ปิดได้แค่ X (`calendar-event-details.tsx:88-96`) · ไม่มี keydown/mousedown listener |
| AC-HP05-6 Responsive | 🟡 | `w-[340px] overflow-y-auto max-h-[calc(100%-16px)]` วางคงที่ข้าง panel ล่างซ้าย (`vo-calendar.tsx:384-396`, `OVERLAY_LEFT` `:45`) — ไม่วางข้าง event ที่คลิกตาม Figma (§8.1) · ไม่มี mobile |
| Figma extras: Trash / Edit / RSVP Yes/No/Maybe | ❌ (ไม่อยู่ใน ClickUp) | ไม่มี · ไม่มี API แก้/ลบ meeting (router มีแค่ GET/POST/sync `router.go:292-296`) · ไม่มีตาราง RSVP · RSVP dot ปลอม: organiser เขียว, guest เทา (`calendar-event-details.tsx:146-151`) · สรุปผู้เข้าร่วม hardcode `yes: 1` (`:128`) |
| Style vs Figma CAL-02 | ⚠️ | title 16/22 (`:84`) vs Figma 14/18 · link สี `#8C99A6` (`:168-170`) vs Figma `#2DB6FF` underline |

### CLDD-EP-01 · Empty / Loading / Error

| AC / จุดตรวจ | สถานะ | หลักฐาน / หมายเหตุ |
|---|---|---|
| AC-EP01-1 empty state "ไม่มี events ในช่วงนี้" | ❌ | grid ว่างเฉย ๆ · มีแค่ "No meetings today" ใน Upcoming ของ panel (`vo-calendar.tsx:308-310`) · Figma ก็ไม่มี (U17) |
| AC-EP01-2 ปุ่ม "สร้าง Meeting ใหม่" | ❌ (ของเดิมใช้ได้) | ไม่มีใน empty state · แต่ Schedule event modal มีแล้ว (ปุ่ม + `vo-calendar.tsx:258-266`, คลิกช่องว่าง `calendar-main-view.tsx:277-290`) — ตรงกับที่ Figma แสดง |
| AC-EP01-3 ไม่แสดง error เมื่อว่าง | ✅ | ไม่มี error |
| AC-EP01-4 skeleton | ❌ | `CalendarData` ไม่มี `loading` state เลย (`use-calendar-data.ts:65-84`) · ไม่มี skeleton component สำหรับ calendar |
| AC-EP01-5 error banner/toast + ลองใหม่ | ❌ | โหลดครั้งแรก/เลื่อนช่วงล้มเหลว → `return false` แล้ว**เงียบ** (effects `use-calendar-data.ts:188-213` ไม่สนผล) · มี toast เฉพาะตอนกด Sync now ล้มเหลว `zyraToast.error(t("syncFailed"))` (`vo-calendar.tsx:181-185`) ไม่มีปุ่ม Try again |
| AC-EP01-6 Retry ทันที | 🟡 | มี Sync now ที่ re-read ทั้งหมด (`use-calendar-data.ts:267-303`) แต่ไม่ได้ผูกกับ error |
| AC-EP01-7 ไม่ crash / frame ยังอยู่ | ✅ (โดยพฤตินัย) | error ไม่ throw, frame render ต่อ · ไม่มี test |

### Edge cases

| EC | สถานะ | หลักฐาน / หมายเหตุ |
|---|---|---|
| EC-01 Overlap | ✅/⚠️ | Week/Day lane (ดู HP-03) · Month เรียงใน cell ✅ · กันซ้ำ Zyra vs Google copy (`use-calendar-data.ts:248-253`, test `vo-calendar-meetings.test.tsx:239`) |
| EC-02 All-day | 🟡 | Month top of cell ✅ · Week/Day ไม่มี All-day row ❌ · event หลายวันวาดทีละคอลัมน์ ไม่ span |
| EC-03 ข้ามคืน | 🟡 | `eventsOnDay` ใส่ทั้งสองวัน + `layoutTimedEvents` clip ต่อวัน (`calendar-dates.ts:93-101,142-143`, test `calendar-dates.test.ts:127`) → Day วันถัดไปแสดงช่วง 00:00–01:00 ✅ · ไม่มีตัวบอกว่า "ต่อจากเมื่อวาน" |
| EC-04 Timezone | 🟡 | ทุกอย่างแปลงเป็น **browser local tz** ผ่าน `new Date()` (`calendar-dates.ts:74-80`) ✅ auto convert · popup **ไม่แสดงสอง timezone** ❌ · Zyra meeting เก็บ `time_zone` (create ส่ง `Intl…resolvedOptions().timeZone` `calendar-schedule-event.tsx:214`) แต่ไม่แสดง · Google event: API ไม่ส่ง `timeZone` ออกมา (`zyra-api/internal/model/calendar_integration.go:50-62`, แม้ client อ่าน `googleEventTime.TimeZone` ได้ `calendar_google_client.go:94-98`) · ไม่มี label GMT+X |
| EC-05 ชื่อยาว | 🟡 | chip truncate ✅ (`calendar-parts.tsx:211`) · **popup ก็ truncate 1 บรรทัด** (`calendar-event-details.tsx:84`) → ไม่แสดงชื่อเต็มตาม EC-05 ❌ (มีแค่ `aria-label`) |
| EC-06 real-time / polling 5 นาที | ❌ | ไม่มี polling / webhook · refresh เฉพาะ: เปิด calendar, เปลี่ยนช่วง, Sync now · Zyra meeting ตาม Google แก้/ลบ เฉพาะตอน list (`calendar_meeting_inbound.go`) · ไม่มี "Event ถูกแก้ไข — [Reload]" |
| Search ใน panel | ✅ (extra) | กรองทั้ง grid + upcoming (`vo-calendar.tsx:61-67,160-171`) |

---

## (B) API

| Endpoint | Guard group | Flag | ใช้ทำอะไร | ไฟล์ |
|---|---|---|---|---|
| `GET /api/user/integrations/google/events?time_min&time_max&calendar_id=…` | UserGuard (`user` group) ✅ rule 15 | ลงทะเบียน**เฉพาะ** `GOOGLE_CALENDAR_ENABLED=true` + config ครบ | Google events ≤62 วัน ≤20 calendars, `singleEvents` | `zyra-api/internal/router/router.go:424-432`, `main.go:356-371`, `calendar_integration_service.go:44-47,544` |
| `GET /api/user/integrations/google/calendars` · `/status` · `POST /connect` · `DELETE ""` | UserGuard | flag เดียวกัน | calendar list (+ Thai Holidays) / status | `router.go:426-431` |
| `GET /api/integrations/google/callback` | public | flag | OAuth callback | `router.go:139-143` |
| `GET /api/user/workspaces/:id/meetings?time_min&time_max` | UserGuard (`userWS`) ✅ | **ลงทะเบียนเสมอ** (`main.go:373-374`) | Zyra meetings ที่ user เป็น organizer หรือ guest ใน workspace นั้น ≤62 วัน + reconcile กับ Google | `router.go:292-296`, `calendar_meeting_service.go:344-374`, `calendar_meeting_store.go:325-333` |
| `POST /api/user/workspaces/:id/meetings` · `POST …/meetings/sync` | UserGuard | เสมอ | create (push Google) / Sync now | `router.go:294-295` |

- **ไม่มี `/calendar/events`** ตาม ClickUp EP-01 — path จริงอยู่ใต้ `/api/user/*` ถูกตามกฎ 15 ✅ แต่ต้องแก้ spec/ClickUp ให้ตรง
- **ไม่มี endpoint รวม** — app เป็นคน merge: `use-calendar-data.ts:240-265` (`merge()` = Zyra meetings ก่อน + Google events ที่ id ไม่ซ้ำ `google_event_id`) · ยิงแยก "main range" กับ "today" อีกชุดสำหรับ Upcoming → 4 read + calendars
- Zyra meetings เป็น **ต่อ workspace** (`/workspaces/:id/meetings`) → calendar เห็นเฉพาะ meeting ของ workspace ที่อยู่ ไม่ใช่ "ทุก meeting ของ user" (ClickUp user story "all my meetings in one view" — ต้องยืนยัน)
- **Outlook:** ไม่มีที่ไหนเลยใน calendar (API comment `calendar_meeting_service.go:25` "Outlook (HP-02) is not connected yet") · Setting → Integrations Outlook = coming soon (ตาม progress CAL-01; ยังไม่ได้ตรวจไฟล์ `vo-setting-modal.tsx` บรรทัดจริง)
- Google `CalendarEvent` ที่ API ส่งออก (`internal/model/calendar_integration.go:50-62`) **ไม่มี** description / attendees / organizer / timeZone — ทั้งที่ Google client อ่าน `Description`, `Attendees`, `TimeZone` มาแล้ว (`calendar_google_client.go:94-123`) → HP-05 สำหรับ Google event ต้องขยาย model + `toCalendarEvent` (`calendar_integration_service.go:514-530`)
- Zyra meeting model ไม่มี `meeting_status`, RSVP, update/delete endpoint
- Migrations 115/116/117 อยู่ใน auto-migrate แล้ว (`zyra-api/internal/database/postgres.go:1125,1148`)

---

## (C) Overlaps / conflicts

### C1. ของที่มีแล้ว — ต้อง reuse/extend ห้ามสร้างใหม่ (rule 09)

| ของเดิม | ใช้กับ CAL-02 |
|---|---|
| `CalendarMainView` / `MonthGrid` / `TimeGrid` / `DayColumn` (`calendar-main-view.tsx`) | Month/Week/Day ของ CAL-02 = **แก้ไฟล์นี้** ไม่ใช่สร้าง view ใหม่ |
| `CalendarEventChip`, `eventChipVariant`, `CalendarNowLine`, `CalendarCheckbox`, `calendarColor`, `CalendarConnectBanner` (`calendar-parts.tsx`) | chip สีตาม source → เพิ่ม prop/variant ในของเดิม |
| `CalendarEventDetails` (`calendar-event-details.tsx`) | HP-05 popup → ขยายให้รับ Google event (+ source badge, description, open-in-Google, ESC/outside) **ห้ามทำ popup ตัวที่สอง** |
| `CalendarScheduleEvent` (`calendar-schedule-event.tsx`) | ปุ่ม "สร้าง Meeting ใหม่" ของ empty state เรียก `openSchedule` เดิม (`vo-calendar.tsx:205-208`) |
| `lib/calendar/calendar-dates.ts` | date lib เดียวของ calendar (ไม่มี date-fns/dayjs ใน `package.json`) · overlap layout อยู่ที่นี่แล้ว |
| `zyraToast.*WithTitle(..., { layout: "figma", actions })` (`zyra-app/lib/toast.tsx:56-75,224+`) | Error toast EP-01 (Figma: info icon + "Try again" primary) ใช้ `infoWithTitle` + action ได้เลย — toast system มีตัวเดียว (sonner wrapper) |
| `components/ui/skeleton.tsx` (ยกเว้นใน rule 08) | skeleton EP-01 |
| `openMeetingLink` / `joinCalendarMeeting` (`hero-virtual-office.tsx:12672-12692`) | "Join Now" → VO room |

### C2. ความขัดแย้งกับ ClickUp / Figma CAL-02

| # | จุด | โค้ดตอนนี้ | ClickUp | Figma CAL-02 |
|---|---|---|---|---|
| 1 | Grid metrics | 66.67px/ชม., gutter 80, label "01" 14px white, header circle 45 (Figma CAL-01 `3298:4784`) | 30 นาที = 1 row | 72px/ชม., 36/30 นาที, gutter 64 + "GMT+7", label "08:00" 10/13 `#8C99A6`, circle 30 |
| 2 | สี Zyra | `#58D68D` | `#79DEA5` / "Indigo" | `#58D68D` ✅ |
| 3 | สี source ใน chip | ทุก event (ยกเว้น holiday) เขียว | Google `#4285F4`, Outlook `#0078D4` | ไม่มี Google/Outlook (U2) |
| 4 | Join | "Join" แสดงเสมอ | "Join Now" เฉพาะ active | "Join", external link ซ่อน (opacity 0) |
| 5 | RSVP / Trash / Edit | ไม่มี (dot ปลอม) | ไม่อยู่ใน scope | มี (U16) |
| 6 | "+X more" | "+N more" เทา ไม่กดได้ | "+X more" กด → popup | "2 More" เขียว + popup 167×196 |
| 7 | All-day | overlay ใน grid | row เหนือ grid | band h32 "All-day" |
| 8 | Error | toast `syncFailed` เฉพาะ Sync now | banner + [ลองใหม่] | toast "Couldn't load calendar events" + "Try again" |
| 9 | Banner | "No calendar connected" · ปิดถาวร | "เชื่อมต่อ Google / Outlook…" | "Connect your calendar" · โผล่วันละครั้ง |
| 10 | Overflow day | `#636D76` | greyed | `#8C99A6` |
| 11 | Popup position | ข้าง panel ล่างซ้ายคงที่ | — | ข้าง column/event ที่คลิก |
| 12 | Mini calendar | ไฮไลต์วันที่เลือก | — | ไฮไลต์ today |

### C3. Feature flag / entry

- ไอคอน Calendar เปิดได้**เฉพาะ** `availability === "available"` = API มี route `/integrations/google/status` (`hero-virtual-office.tsx:4922-4930`, `stores/calendar-integration-store.ts:40-56`) → ถ้า `GOOGLE_CALENDAR_ENABLED` ปิด จะได้ toast "coming soon" **ทั้งที่ Zyra meetings API พร้อม** (route meetings ลงทะเบียนเสมอ) — ขัดกับ HP-01 persona "ยังไม่ connect ก็ดู Zyra events ได้"
- ถ้า `/status` ล้มด้วย error อื่น (network/5xx) `availability` ค้าง `"unknown"` → ก็ได้ toast coming soon เช่นกัน (`calendar-integration-store.ts:47-50`)
- ค่า `GOOGLE_CALENDAR_ENABLED` บน dev/uat/prod: **ยังไม่ได้ตรวจ** (อยู่ใน ESO secret)
- Mobile: ปิดทั้งหมด (`hero-virtual-office.tsx:15501-15503`, `vo-sidebar.tsx:110`, `lite/lite-bottom-nav.tsx:21`) — HP-03/04 swipe ไม่มีที่ให้ทำจนกว่าจะเปิด calendar บน mobile

### C4. Data-fetch pattern ขัด guide ทีม

- `use-calendar-data.ts` ใช้ `useEffect + useState + fetch` และ `eslint-disable react-hooks/set-state-in-effect` 5 จุด (`:189,195,201,206,211`) — ขัด `zyra-doc/guides/tanstack-query-migration.md` กติกา 1 ("ฟีเจอร์ใหม่ต้องใช้ `useQuery`") และกติกา 5 (polling ใช้ `refetchInterval`) · `@tanstack/react-query` มีใน `package.json:42` และใช้แล้วหลายที่ (`hooks/use-workspace-members.ts` ฯลฯ)
- ผลต่อ CAL-02: ไม่มี `isPending` (skeleton), ไม่มี `isError` (error toast), ไม่มี cache (month switch ≤300ms), ไม่มี `refetchInterval` (EC-06) — ทั้ง 4 AC ได้มาเกือบฟรีถ้าย้ายไป react-query

### C5. ของ CAL-02 ที่จริง ๆ ทำไปแล้วใน CAL-01

- Month/Week/Day toggle, Today, ‹ ›, Sync now, Month 6×7 + ≤3 chips, all-day-first sort, overlap lanes, now-line, click month day → Day, default Month, Zyra-only เมื่อไม่ connect, banner, Calendar list, Event details (Zyra), Join → ห้อง, Schedule event (= ปุ่มสร้าง meeting) — CAL-01 progress บันทึกว่า Month/Day "ไม่มี Figma frame ประกอบเอง" → ตอนนี้ CAL-02 มี frame แล้ว ต้อง re-align
- doc conflict: CAL-01 `progress.md` ยังเขียน "uncommitted / ยังไม่ live-test" แต่ snapshot develop มีโค้ดครบแล้ว (merged ตามที่ caller แจ้ง PR #634/#178 — ยังไม่ได้ตรวจเลข PR ในโค้ด)

### C6. อื่น ๆ

- date-grid logic ซ้ำในโปรเจกต์ (ไม่ใช่ของ calendar): `views/chat/components/date-range-picker.tsx:72-77` (เริ่มจันทร์), `components/admin/admin-date-picker.tsx:51-52`, `views/user/virtual-office/components/announcement/announcement-date-time.tsx:494-496`, admin user-management pickers — calendar เองใช้ `calendar-dates.ts` ตัวเดียว ไม่ต้องแตะ แต่อย่าเพิ่มตัวที่ 6
- localStorage keys ของ calendar: `zyra_gcal_banner_dismissed`, `zyra_gcal_selected:<email>` (keyed by Google email ไม่ใช่ user id — ถ้าไม่ connect key = `zyra_gcal_selected:`) (`vo-calendar.tsx:50`, `use-calendar-data.ts:26`)

---

## (D) Tests ที่มีอยู่

### zyra-app (vitest)

| ไฟล์ | ครอบอะไร | ไม่ครอบ (เกี่ยวกับ CAL-02) |
|---|---|---|
| `__tests__/calendar-dates.test.ts` | week เริ่มอาทิตย์, 6 สัปดาห์ (42 วัน), view ranges, paging + clamp, all-day local dates, format, `layoutTimedEvents` (2 อันทับ, back-to-back, clip ข้ามวัน) | overlap ≥3, DST/timezone |
| `__tests__/calendar-integration-api.test.ts` | status, 404 = feature off, error codes, connect, events query | — |
| `__tests__/google-calendar-connect.test.tsx` | popup OAuth flow | — |
| `__tests__/vo-calendar.test.tsx` | banner เมื่อไม่ connect, upcoming + past dim + calendar list, search, full view + Sync now + **default Month** (`:212-224`), Setting Integrations disconnect | Month chips/"+N", day click → Day, Week/Day layout, all-day, now-line, error/empty/skeleton |
| `__tests__/vo-calendar-meetings.test.tsx` | meetings API, organizer vs guest chip, My calendar ไม่ connect + Event details จาก Upcoming, กันซ้ำ Google copy (EC-01), create/toast/push failed/reconnect, ลบใน Google, all-day create, discard, คลิก slot → draft, Sync now retry | popup จาก grid chip, Google event popup, ESC/outside |

### zyra-api (go test, testify)

| ไฟล์ | ครอบอะไร |
|---|---|
| `internal/service/calendar_meeting_service_test.go` | validate create, push Google + outcomes, all-day, list + reject range, Sync failed, inbound reconcile (ลบ/แก้/ห้อง/throttle 20 วิ/description) |
| `internal/service/calendar_integration_service_test.go` | connect/state/callback/scope, token cache/refresh, calendars, events, disconnect |
| `internal/service/calendar_google_client_test.go` | httptest: token, error mapping, paging, insert/get event |
| `internal/handler/calendar_meeting_handler_test.go` · `calendar_integration_handler_test.go` | handler envelope/errors |
| `internal/router/calendar_routes_test.go` | routes ตาม flag + meeting routes |
| `internal/config/calendar_test.go` · `calendar_token_crypto_test.go` | config/crypto |

- e2e (Playwright `zyra-app/e2e/`): **ไม่มี** test calendar
- ไม่ได้รัน test ในรอบนี้ (read-only) — ผลผ่าน/ไม่ผ่าน **ยังไม่ได้ตรวจ**

---

## (E) Suggested remaining work (PR-sized)

ลำดับแนะนำ — ข้อที่มี ⚑ ต้องได้คำตอบ PM/Design ก่อน (ดู spec §5 + ux-ui-plan §10)

1. **refactor(app): ย้าย `use-calendar-data` ไป react-query** — `isPending`/`isError`/cache ต่อ range/`refetchInterval` 5 นาที (ฐานของ EP-01, AC-HP02-6, EC-06) · ไม่เปลี่ยน UI
2. **feat(app): EP-01 loading skeleton + error toast "Try again"** — skeleton ตาม Figma §9.2 (`components/ui/skeleton.tsx`), toast `zyraToast.infoWithTitle` + action retry · i18n en/th
3. **feat(app): re-align Week/Day grid กับ Figma CAL-02** — 72px/ชม. + half-hour rule, gutter 64 + "GMT±X", label "HH:00" 10/13, header circle 30, today column shade, now-label แดง, inset/gap 4px ของ block, block แสดงเวลา (Week) และ เวลา+location (Day = AC-HP04-3)
4. **feat(app): All-day band เหนือ time grid** (AC-HP03-4, EC-02, Day "—")
5. **feat(app): Month "+N More" day popup** (AC-HP02-3, Figma §5.4) + style "N More"/overflow `#8C99A6`/cell size ⚑ copy "+X more" vs "2 More"
6. **feat(api+app): Google event detail** — ขยาย `model.CalendarEvent` (description, attendees, timeZone, organizer) → `CalendarEventDetails` รับ Google event ได้, source badge, "Open in Google Calendar" (`html_link`), description, ชื่อเต็มไม่ truncate (EC-05), แสดง event tz ถ้าต่างจาก user (EC-04), ESC + click-outside, วางข้าง event ที่คลิก ⚑ U11/U12/U14/U15
7. **feat(app): สีตาม source** ใน chip + Calendar list ⚑ U1/U2 (Zyra `#58D68D` vs `#79DEA5`, Google `#4285F4`, Outlook)
8. **feat(api+app): "Join Now" เฉพาะ active** ⚑ นิยาม active (เวลาปัจจุบันอยู่ในช่วง start–end? มีคนอยู่ในห้อง? ต้องมี `meeting_status`?) — ถ้าต้องเก็บ status ต้องมี migration
9. **fix(app): เปิด Calendar โดยไม่ต้องมี `GOOGLE_CALENDAR_ENABLED`** — แยก availability ของ Zyra meetings ออกจาก Google (HP-01 persona ไม่ connect) + จัดการ `/status` error ไม่ให้ขึ้น coming soon
10. **feat(app): banner ตาม Figma CAL-02** — copy ใหม่ + โผล่ใหม่วันละครั้ง (เก็บวันที่แทน "1") ⚑ U3
11. **feat(app): empty state** ⚑ U17 (ClickUp ข้อความ+ปุ่ม vs Figma grid เปล่า) — ปุ่มใช้ `openSchedule` เดิม
12. **feat(app): EC-06 "Event ถูกแก้ไข — [Reload]"** ใน popup เมื่อ refetch พบว่า event เปลี่ยน (หลังข้อ 1)
13. **feat(app): mobile calendar + swipe** ⚑ U20 ไม่มี Figma mobile — ต้องเปิด calendar บน mobile ก่อน (ตอนนี้ปิดทั้งหมด)
14. **test(app)**: Month (+N popup, day → Day, sort), all-day band, overlap ≥3, popup Google/ESC/outside, skeleton/error/retry, polling · **perf**: วัด AC-HP01-1 (≤5 วิ) และ AC-HP02-6 (≤300ms) บน dev ด้วยตัวเลขจริง (rule 18)
15. **Outlook** (AC-HP01-4/HP-05 source "Outlook") — ขึ้นกับ CAL-01 HP-02 ที่ยังไม่ทำ · นอก scope การ์ดนี้จนกว่าจะมี Outlook integration
16. **docs**: แก้ ClickUp/spec `/calendar/events` → path จริง; อัปเดต CAL-01 `progress.md` (ยังเขียน uncommitted)
