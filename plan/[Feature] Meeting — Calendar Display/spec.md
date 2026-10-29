# SC-MTG-CAL-02 · Meeting — Calendar Display (Month / Week / Day View)

> **สถานะ (2026-10-27):** **Spec ถอดจาก ClickUp + ดึง Figma ครบ 6 section แล้ว ([ux-ui-plan.md](ux-ui-plan.md)) — ยังไม่ implement · ยังไม่ได้ตรวจโค้ด** · Figma ขัดกับ ClickUp 22 จุด → [ux-ui-plan §10](ux-ui-plan.md#10-figma-vs-clickup--ข้อขัดแย้งที่ต้องถาม)
> **กติกากลาง 3 ฟีเจอร์ (ผู้ใช้ตัดสิน 2026-10-29):** Figma กับ ClickUp ขัดกัน → **ยึด Figma** ยกเว้นข้อที่ผู้ใช้ตัดสินเป็นอย่างอื่น (ดู [CAL-01 spec §6.1](<../[Feature] Meeting — Calendar Integration/spec.md>)) · ข้อที่มีแค่ฝั่งเดียว (Figma ไม่ได้วาด) ยังเป็นคำถามเปิด จนกว่าจะตัดสิน
> **วันที่ถอด:** 2026-10-27 · **ClickUp:** [[Feature] Meeting — Calendar Display (Month / Week / Day View)](https://app.clickup.com/t/86d3nbd9b) (`pending` · priority High · tag `client` · assignee P A · creator Moss Pm · สร้าง 2026-07-10 · แก้ล่าสุด 2026-10-27)
> **Depends on:** SC-MTG-CAL-01 — [MeetingCalendarIntegration](../MeetingCalendarIntegration/spec.md) (ClickUp [[Feature] Meeting — Calendar Integration](https://app.clickup.com/t/86d3nbcrq))
> **ฟีเจอร์คู่กัน:** [SC-MTG-CAL-03 Meeting Alert](<../[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/spec.md>) — กด alert แล้วมาเปิด Calendar View + event detail popup (HP-05) ของการ์ดนี้
> **CAL-01 (ใช้หน้าจอร่วมกัน):** [Calendar Integration spec](<../[Feature] Meeting — Calendar Integration/spec.md>) · ตารางส่วนที่ 3 ฟีเจอร์ใช้ร่วมกัน + ตารางสิทธิ์ตามบทบาท → [CAL-01 ux-ui-plan §1, §7.2](<../[Feature] Meeting — Calendar Integration/ux-ui-plan.md>)
> **โครงเอกสาร:** §1–§4 = requirement ต้นทางจาก ClickUp (ถอดตามที่เขียน ไม่แต่งเติม) · §5 = ข้อสังเกต / จุดขัดกันในต้นทาง (ยังไม่ใช่ decision)

---

## 1. Overview (จาก ClickUp parent)

**Module:** Meeting Module — Project Zyra
**Persona:** Workspace Member ที่ connect calendar แล้ว (หรือยังไม่ connect)
**Depends on:** SC-MTG-CAL-01

แสดง events จากทุก source รวมกันใน Calendar View เดียว โดย toggle ระหว่าง Month / Week / Day ได้ พร้อม color coding แยก source และ event detail popup

### Color System

| Source | Color (ตามที่เขียนใน ClickUp) | Hex |
|---|---|---|
| Zyra Meeting | Geen (= Green) | `#79DEA5` |
| Google Calendar | Blue | `#4285F4` |
| Outlook | Teal | `#0078D4` |

> ดู [§5 ข้อ 1](#5-ข้อสังเกต--จุดขัดกันในต้นทาง) — HP-01 เขียนว่า Zyra = Indigo ไม่ตรงกับตารางนี้

### User Stories

```
As a Workspace Member
I want to see all my meetings in one calendar view (Zyra + Google + Outlook)
So that I don't have to switch between apps to check my schedule

As a Workspace Member
I want to switch between Month, Week, and Day views
So that I can see my schedule at different levels of detail
```

(ฉันอยากเห็น meeting ทั้งหมดใน calendar เดียว (Zyra + Google + Outlook) จะได้ไม่ต้องสลับแอปเพื่อดูตาราง · ฉันอยากสลับ Month / Week / Day เพื่อดูตารางในระดับรายละเอียดต่างกัน)

### Source links

| แหล่ง | ลิงก์ |
|---|---|
| ClickUp parent | [[Feature] Meeting — Calendar Display (Month / Week / Day View)](https://app.clickup.com/t/86d3nbd9b) |
| Figma file | `Map8gX0L2hk7HnkaFRfhtj` — Zyra design (More Organised ver.) · node ต่อ scenario ดู §2 |
| ClickUp comments | ไม่มี — ทั้ง parent และ 6 subtask (ตรวจ 2026-10-27) |
| Attachments / checklists / custom fields | ไม่มี (ตรวจ 2026-10-27) |

---

## 2. Scope & Scenario Index (6 subtasks + 6 edge cases)

| ID | ชื่อ | ClickUp | Figma node | สถานะ ClickUp |
|---|---|---|---|---|
| CLDD-HP-01 | เปิด Calendar View ครั้งแรก | [CLDD-HP-01 · เปิด Calendar View ครั้งแรก](https://app.clickup.com/t/86d3nf2tn) | [`3898-761567`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3898-761567) | pending |
| CLDD-HP-02 | Month View | [CLDD-HP-02 · Month View](https://app.clickup.com/t/86d3nf2x7) | [`4998-56260`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4998-56260) | pending |
| CLDD-HP-03 | Week View | [CLDD-HP-03 · Week View](https://app.clickup.com/t/86d3nf2z6) | [`7747-74314`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7747-74314) | pending |
| CLDD-HP-04 | Day View | [CLDD-HP-04 · Day View](https://app.clickup.com/t/86d3nf31v) | [`7747-76800`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7747-76800) | pending |
| CLDD-HP-05 | กด Event Card ดู Detail Popup | [CLDD-HP-05 · กด Event Card ดู Detail Popup](https://app.clickup.com/t/86d3nf358) | [`7755-40085`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7755-40085) | pending |
| CLDD-EP-01 | ไม่มี Events ในช่วงเวลาที่ดู และ Calendar โหลดล้มเหลว | [CLDD-EP-01 · ไม่มี Events ในช่วงเวลาที่ดู และ Calendar โหลดล้มเหลว](https://app.clickup.com/t/86d3nf3ae) | [`7759-120313`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7759-120313) | pending |
| EC-01 ~ EC-06 | Edge cases (อยู่ใน parent) | — | — | — |

ทุก subtask: ไม่มี assignee · ไม่มี priority · ไม่มี due date · สร้าง 2026-07-10 โดย Moss Pm

---

## 3. Scenarios (ถอดจาก subtask)

### CLDD-HP-01 · เปิด Calendar View ครั้งแรก

**Pre-condition:** User เข้า Workspace

**Scenario Steps:**
1. User กด "Calendar" จาก sidebar หรือ top nav
2. Calendar เปิด default เป็น **Month View** ของเดือนปัจจุบัน
3. Events แสดงด้วย color badge ตาม source บนทุกวันที่มี event
4. Color legend แสดงด้านล่าง calendar

**Acceptance Criteria:**

| # | AC |
|---|---|
| AC-HP01-1 | Calendar โหลดเสร็จภายใน **5 วินาที** |
| AC-HP01-2 | Default view = Month View |
| AC-HP01-3 | วันปัจจุบัน highlight ชัดเจน |
| AC-HP01-4 | Color legend แสดง: Zyra (Indigo) · Google (Blue) · Outlook (Teal) — ⚠️ ขัดกับ Color System ใน parent ดู §5 ข้อ 1 |
| AC-HP01-5 | ถ้ายังไม่ connect calendar ภายนอก: แสดงเฉพาะ Zyra events พร้อม banner "เชื่อมต่อ Google / Outlook เพื่อดู events ทั้งหมด" |

**Figma:** node `3898-761567`

---

### CLDD-HP-02 · Month View

**Pre-condition:** User อยู่หน้า Calendar

**Scenario Steps:**
1. Calendar แสดง grid ของเดือน (7 คอลัมน์ × 4–6 แถว)
2. แต่ละวัน: แสดง event chips สูงสุด 3 รายการ
3. วันที่มี event มากกว่า 3 รายการ: แสดง **"+X more"** (อีก X รายการ)
4. กด "+X more": expand popup แสดง events ทั้งหมดของวันนั้น
5. ปุ่ม `<` `>` เพื่อเลื่อนเดือน prev / next

**Acceptance Criteria:**

| # | AC |
|---|---|
| AC-HP02-1 | Grid แสดงครบทุกวันของเดือน พร้อมวัน overflow จากเดือน prev/next (greyed out) |
| AC-HP02-2 | Event chips แสดง: dot สี + ชื่อ event (truncate ถ้ายาว) |
| AC-HP02-3 | "+X more" คลิกได้ expand popup แสดงทุก event ของวันนั้น |
| AC-HP02-4 | Events เรียงตามเวลาเริ่มต้น ascending ใน cell |
| AC-HP02-5 | All-day events แสดง **บนสุด** ของ cell ก่อน time-based events |
| AC-HP02-6 | เลื่อนเดือน: render ใหม่ภายใน **300ms** |

**Figma:** node `4998-56260`

---

### CLDD-HP-03 · Week View

**Pre-condition:** User กด toggle "Week"

**Scenario Steps:**
1. Week View แสดง 7 คอลัมน์ (วัน) × แถวเวลา (00:00–23:30 ทุก 30 นาที)
2. Event blocks แสดงในช่องเวลาที่ตรงกัน ความสูง proportional กับ duration
3. Overlapping events แสดง side-by-side ในคอลัมน์เดียวกัน
4. All-day events แสดงใน row บนสุดแยกจากเวลา
5. ปุ่ม `<` `>` เลื่อนสัปดาห์ prev / next

**Acceptance Criteria:**

| # | AC |
|---|---|
| AC-HP03-1 | แสดง 7 วันในหนึ่งหน้า (desktop) — ไม่ต้อง scroll แนวนอน |
| AC-HP03-2 | Event block ความสูง proportional กับ duration จริง (30 นาที = 1 row) |
| AC-HP03-3 | Overlap: แสดง side-by-side ไม่ทับกัน — width แบ่งเท่า ๆ กัน |
| AC-HP03-4 | All-day row: แสดงเหนือ time grid |
| AC-HP03-5 | Current time indicator: เส้นสีแดงแสดงเวลาปัจจุบันใน time grid |
| AC-HP03-6 | Mobile: swipe left/right เพื่อเปลี่ยนสัปดาห์ |

**Figma:** node `7747-74314`

---

### CLDD-HP-04 · Day View

**Pre-condition:** User กด toggle "Day" หรือ กดวันใดวันหนึ่งใน Month View

**Scenario Steps:**
1. Day View แสดงวันเดียว แถวเวลา 00:00–23:30 ทุก 30 นาที
2. Event blocks แสดงตาม duration จริง
3. Overlapping events: side-by-side
4. ปุ่ม `<` `>` เลื่อนวัน prev / next

**Acceptance Criteria:**

| # | AC |
|---|---|
| AC-HP04-1 | แสดง 1 วันเต็มหน้า พร้อม scroll แนวตั้งถ้า events เยอะ |
| AC-HP04-2 | กดวันใน Month View → switch ไป Day View ของวันนั้น |
| AC-HP04-3 | Event block แสดงชื่อ + เวลาเริ่มต้น |
| AC-HP04-4 | Mobile: swipe left/right เพื่อเปลี่ยนวัน |

**Figma:** node `7747-76800`

---

### CLDD-HP-05 · กด Event Card ดู Detail Popup

**Pre-condition:** มี events บน calendar

**Scenario Steps:**
1. User กด event ใด ๆ บน calendar
2. Event detail popup เปิด แสดง:
   - ชื่อ event
   - วันที่ และเวลา (start — end)
   - Source badge สีตาม source
   - Location หรือ Video link (ถ้ามี)
   - Attendees (avatar + ชื่อ)
   - Description
3. Zyra meeting ที่ **active**: ปุ่ม **"Join Now"** (เข้าร่วมเลย) แสดง
4. กด "Join Now" → navigate ไป Virtual Office room

**Acceptance Criteria:**

| # | AC |
|---|---|
| AC-HP05-1 | Popup แสดงข้อมูลครบทุก field |
| AC-HP05-2 | Source badge: "Zyra Meeting" / "Google Calendar" / "Outlook" พร้อมสีตาม source |
| AC-HP05-3 | "Join Now" แสดงเฉพาะ Zyra meeting ที่ `meeting_status = active` |
| AC-HP05-4 | Google / Outlook event: แสดง link "เปิดใน Google Calendar / Outlook" |
| AC-HP05-5 | ปิดด้วย ESC หรือ click นอก popup |
| AC-HP05-6 | Popup responsive |

**Figma:** node `7755-40085`

---

### CLDD-EP-01 · ไม่มี Events ในช่วงเวลาที่ดู และ Calendar โหลดล้มเหลว

#### (a) ไม่มี Events ในช่วงเวลาที่ดู

**Trigger:** Month/Week/Day ที่เลือกไม่มี events

**Expected Behavior:**

| # | AC |
|---|---|
| AC-EP01-1 | แสดง empty state กลาง calendar: "ไม่มี events ในช่วงนี้" |
| AC-EP01-2 | ปุ่ม "สร้าง Meeting ใหม่" ใน empty state |
| AC-EP01-3 | ไม่แสดง error — เป็น valid state |

#### (b) Calendar โหลดล้มเหลว (Network Error)

**Trigger:** API `/calendar/events` ตอบกลับ error

**Expected Behavior:**

| # | AC |
|---|---|
| AC-EP01-4 | แสดง skeleton loading ก่อน |
| AC-EP01-5 | ถ้า fail: error banner "ไม่สามารถโหลด events ได้ — [ลองใหม่]" |
| AC-EP01-6 | กด "ลองใหม่": retry fetch ทันที |
| AC-EP01-7 | ไม่ crash หน้า — calendar frame ยังแสดงอยู่ |

**Figma:** node `7759-120313`

---

## 4. Edge Cases (จาก ClickUp parent)

| # | Case | Expected Behavior |
|---|---|---|
| EC-01 | Events ทับเวลากัน | Week/Day: side-by-side, Month: เรียงใน cell |
| EC-02 | All-Day Event | Month: top of cell, Week: All Day row, Day: All Day section |
| EC-03 | Event ข้ามคืน (เช่น 23:00–01:00) | แสดงใน Day View แบบ wrap ต่อเนื่องไปวันถัดไป |
| EC-04 | Timezone ต่างกัน | Auto convert เป็น user timezone, popup แสดงทั้งสอง timezone |
| EC-05 | Event ชื่อยาวมาก | Truncate พร้อม ellipsis "..." บน chip, แสดงชื่อเต็มใน popup |
| EC-06 | Google event แก้ไขขณะดู Zyra | อัปเดต real-time (webhook) หรือ 5 นาที (polling), popup เปิดอยู่แสดง "Event ถูกแก้ไข — [Reload]" |

---

## 5. ข้อสังเกต / จุดขัดกันในต้นทาง

ข้อสังเกตจากการอ่าน ClickUp เท่านั้น — **ยังไม่ใช่ decision** ต้องถาม PM (Moss Pm) / designer

| # | จุด | รายละเอียด | ต้องถาม |
|---|---|---|---|
| 1 | สีของ Zyra ไม่ตรงกัน | parent: Zyra = Green `#79DEA5` · HP-01 AC: Zyra = **Indigo** | ยึดอันไหน — เช็คกับ Figma ด้วย |
| 2 | Outlook "Teal" แต่ hex เป็นน้ำเงิน | `#0078D4` คือ Microsoft blue ไม่ใช่ teal และใกล้กับ Google `#4285F4` มาก | ใช้ hex นี้จริงไหม / แยกสีออกจาก Google พอไหม |
| 3 | Endpoint `/calendar/events` | EP-01 อ้าง API `/calendar/events` แต่ยังไม่มี API contract ระบุ (method, query range, response) · ตามกฎ [15-member-api-separation](../../../.claude/rules/15-member-api-separation.md) member API ต้องอยู่ใต้ `/api/user/*` | path จริง + contract |
| 4 | "Zyra meeting" / `meeting_status = active` | HP-05 อ้าง scheduled Zyra meeting ที่มีชื่อ/เวลา/attendees/status — SC-MTG-CAL-01 spec บันทึกไว้ว่า Zyra ยังไม่มี scheduled meeting (ดู [Q1 ของ CAL-01](../MeetingCalendarIntegration/spec.md#q1-blocker--scheduled-meeting--calendar-view-อยู่ใน-scope-นี้หรือไม่)) | data model ของ Zyra meeting มาจาก scenario ไหน |
| 5 | ปุ่ม "สร้าง Meeting ใหม่" (EP-01) | ไม่มี scenario ไหนในการ์ดนี้บอกว่ากดแล้วไปไหน | ไป flow สร้าง meeting ของการ์ดไหน |
| 6 | "Join Now" → Virtual Office room | ไม่ระบุว่า meeting ผูกกับ workspace/room/zone ไหน | mapping meeting → VO room |
| 7 | EC-03 ข้ามคืน | ระบุเฉพาะ Day View — Week/Month ไม่ระบุ | Week/Month แสดงยังไง |
| 8 | EC-04 timezone | "user timezone" มาจากไหน (browser / profile) · "ทั้งสอง timezone" = timezone ของ event ต้นทาง + ของ user ใช่ไหม | แหล่ง timezone |
| 9 | EC-06 real-time | webhook (Google push) หรือ polling 5 นาที — ขึ้นกับ CAL-01 sync ที่ยังไม่เสร็จ (Outlook ยังไม่ทำ) | เลือกแบบไหนใน phase แรก |
| 10 | จุดเข้า "Calendar" | HP-01 บอก "sidebar หรือ top nav" — ไม่ระบุว่าอยู่ใน workspace (VO) หรือ lobby | ตำแหน่งจริงตาม Figma |
| 11 | Mobile swipe | HP-03/HP-04 มี mobile swipe แต่ไม่มี Figma mobile node | มี design mobile ไหม |
| 12 | Persona "ยังไม่ connect" | HP-01 แสดง banner — ไม่ระบุว่ากด banner แล้วไปหน้า Integrations ของ CAL-01 หรือไม่ | action ของ banner |

---

## 6. ตรวจกับโค้ด (2026-10-27) — สรุป

รายละเอียดทุก AC + file:line อยู่ใน **[code-gap.md](code-gap.md)** (ตรวจ `origin/develop` zyra-app `22fc0d6d` / zyra-api `aaf5d7c` · read-only · ยังไม่ได้รัน test)

**ภาพรวม:** หน้า Calendar (panel + full view Month/Week/Day + Event details + Schedule event) **มีอยู่แล้วจาก CAL-01** (merge develop แล้ว — app#634, api#178) → งาน CAL-02 คือ **แก้/ขยายของเดิม** ไม่ใช่สร้างใหม่ (rule 09) · แต่ของเดิมวาดตาม Figma ของ CAL-01 (`3298:4784`) ไม่ใช่ของ CAL-02

| สถานะ | เรื่อง |
|---|---|
| ✅ มีแล้ว | default Month · Month 6 แถว + ≤3 chip เรียง all-day ก่อนแล้วตามเวลา · overlap lane (รองรับ ≥3) · เส้นเวลาแดง · กดวันใน Month → Day · Zyra meeting แสดงแม้ไม่ connect Google · Join → เดินไปห้อง · ปุ่มสร้าง meeting |
| ⚠️ มีแต่ต่างจาก Figma CAL-02 | Week/Day grid 66.7px/ชม. (Figma 72) ไม่มี half-hour rule · gutter 80 ไม่มี "GMT+7" · วงกลมวันที่ 45px (Figma 30) · "+N more" สีเทา (Figma "2 More" เขียว) · overflow day `#636D76` (Figma `#8C99A6`) · banner copy "No calendar connected" + ปิดแล้วไม่กลับมา (Figma โผล่วันละครั้ง) · popup วางคงที่ข้าง panel |
| ❌ ยังไม่มี | **All-day row** (all-day วางทับใน time grid) · กด "+N more" → popup · Day block แสดงเวลา/location · **popup ของ Google event** (กดไม่ได้) · source badge / description / ลิงก์เปิดใน Google / ESC + click-outside · ชื่อเต็มใน popup (EC-05) · **skeleton / error + retry / empty state** (โหลดล้มเงียบ) · polling 5 นาที (EC-06) · สีแยกตาม source (Google ก็เขียว) · Outlook · mobile (calendar ปิดบน mobile ทั้งหมด) |
| ⚠️ ขัดกับโค้ด/กติกา | ไม่มี `/calendar/events` — ของจริง `/api/user/integrations/google/events` + `/api/user/workspaces/:id/meetings` (app เป็นคน merge) · **ไอคอน Calendar เปิดได้เฉพาะเมื่อ `GOOGLE_CALENDAR_ENABLED`** (ปิด = toast coming soon) ทั้งที่ meeting API พร้อมเสมอ → ขัด HP-01 persona "ยังไม่ connect" · ไม่มี `meeting_status` → "Join Now เฉพาะ active" ยังไม่มีนิยาม · `use-calendar-data.ts` ใช้ useEffect/useState + eslint-disable 5 จุด ขัด guide TanStack Query (ย้ายแล้วได้ skeleton/error/cache/polling) · Google `CalendarEvent` ที่ API ส่งไม่มี description/attendees/timeZone (client อ่านมาแล้วแต่ทิ้ง) · Zyra meeting เป็น**ต่อ workspace** — "ทุก meeting ของฉัน" ข้าม workspace ไม่ได้ |
| ยังไม่ได้วัด | โหลด ≤5 วิ (AC-HP01-1) · เปลี่ยนเดือน ≤300ms (AC-HP02-6) |

งานที่เหลือแบ่งเป็น PR ได้ 16 ข้อ → [code-gap.md §E](code-gap.md#e-suggested-remaining-work-pr-sized)

---

## 7. จุดที่ทับกับ Meeting Alert (SC-MTG-CAL-03)

สองการ์ดแตะโค้ดชุดเดียวกัน — ควรวางลำดับ / แบ่งคนให้ไม่แก้ไฟล์เดียวกันพร้อมกัน

| # | จุด | CAL-02 ต้องการ | MA ต้องการ | ไฟล์ที่ชนกัน | ข้อเสนอ |
|---|---|---|---|---|---|
| X1 | เปิด Calendar โดยไม่ผูก Google flag | HP-01 persona ยังไม่ connect | "Open Calendar" / "View Calendar" จาก toast + คลิกการ์ด history | `hero-virtual-office.tsx:4922-4935`, `stores/calendar-integration-store.ts` | ทำครั้งเดียว ก่อนทั้งคู่ |
| X2 | เปิด Calendar ไปที่วัน/โหมด/event ที่กำหนด | กดวัน Month → Day (มีแล้ว) | toast → **Week** + Event detail · การ์ดที่ผ่านไป → วันนั้น | `vo-calendar.tsx` (state `mode`, `detailsId` อยู่ข้างใน) | เพิ่ม prop `focus` ใน `VOCalendar` ครั้งเดียว ใช้ทั้งสองฟีเจอร์ |
| X3 | Event detail popup | ขยายให้รับ Google event + badge/description/ESC | เปิดจาก alert (Zyra meeting) | `calendar-event-details.tsx` | ทำ popup ตัวเดียว (ห้ามมีตัวที่สอง) — CAL-02 ขยายก่อน MA ใช้ |
| X4 | นิยาม "active" / meeting status | "Join Now" เฉพาะ active | Join บนการ์ดเฉพาะยังไม่จบ · ยกเลิก/เลื่อน | `tb_calendar_meeting` (ไม่มี status/cancelled_at), `calendar_meeting_inbound.go` (ลบ = hard delete) | ตกลงนิยามเดียว (เช่น now ∈ [start, end] และไม่ถูก cancel) · soft cancel แทน hard delete — migration เดียว |
| X5 | Data fetch ของ calendar | skeleton/error/cache/polling | หลัง reschedule/cancel ต้องให้ calendar อัปเดต | `use-calendar-data.ts` | ย้ายไป react-query ก่อน (CAL-02 PR แรก) แล้ว MA invalidate query ได้ |
| X6 | Toast | error toast EP-01 (`infoWithTitle` + Try again) | toast 5 แบบ (ฟ้า/เขียว/เทา/ส้ม, body 2 บรรทัด) | `lib/toast.tsx` | เพิ่ม variant/prop ในของเดิมครั้งเดียว (rule 09) |
| X7 | Copy "Join" | "Join Now" (ClickUp) vs "Join" (Figma + โค้ด) | "Join Now" vs "Join meeting" / "Join" | `messages/en.json`, `th.json` | ตัดสิน copy ชุดเดียวกับ PM |
| X8 | Mobile | swipe Week/Day | ปุ่ม "Open Calendar" บน mobile ไม่มีปลายทาง | `hero-virtual-office.tsx:15501-15503`, lite nav | ตัดสินพร้อมกันว่า calendar บน mobile อยู่ใน scope ไหม |

---

## 8. ขั้นถัดไป

- ~~ดึงค่า Figma 6 node (§2) ลง `ux-ui-plan.md`~~ — เสร็จ 2026-10-27 ([ux-ui-plan.md](ux-ui-plan.md)) · พบว่า section ของ EP-01 (`7759:120313`) ชื่อผิดเป็น "CLDI-HP-03" แต่เนื้อหาถูก
- ~~ตรวจโค้ดจริง แล้วเขียน baseline + gap~~ — เสร็จ 2026-10-27 ([code-gap.md](code-gap.md), สรุป §6)
- **POC (HTML, ภาพจำลอง ไม่ใช่โค้ดจริง)** — [poc/index.html](poc/index.html) รวม Calendar Display + Meeting Alert · สลับ Figma / ClickUp ได้ · เปิดด้วย launch config `meeting-calendar-poc-3143` (http://localhost:3143) · 2026-10-27
- แก้ `/calendar/events` ใน ClickUp/spec ให้เป็น path จริง (ต้องให้ผู้ใช้สั่งก่อนแก้ ClickUp) · อัปเดต CAL-01 `progress.md` ที่ยังเขียนว่า uncommitted (จริง merge develop แล้ว)
- ส่งคำถาม §5 ให้ PM
