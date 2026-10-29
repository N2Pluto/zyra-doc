# SC-MTG-CAL-02 · Calendar Display — UX/UI Plan (from Figma)

> **สถานะ (2026-10-27):** ดึงจาก Figma ครบทั้ง 6 section ของ ClickUp · ยังไม่ implement · ยังไม่ได้ review กับ Design/PM
> **Figma file:** [Zyra design (More Organised ver.)](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-) (`Map8gX0L2hk7HnkaFRfhtj`) · ดึงผ่าน Figma MCP (`get_metadata` / `get_design_context` / `get_variable_defs` / `get_screenshot`) · ไม่ได้ download asset
> **กติกา:** ตัวเลขทุกตัวมาจาก Figma MCP เท่านั้น ([10-figma-fidelity](../../../.claude/rules/10-figma-fidelity.md)) · ช่องที่ดึงไม่ได้เขียนว่า **"ยังไม่ได้ดึง"** · ห้าม implement ค่าที่เดาเอง
> **flow / business rule อยู่ที่ [spec.md](spec.md)** — ไฟล์นี้พูดเฉพาะหน้าตา ตำแหน่ง และ state ของ UI
> **เกี่ยวข้อง:** [MeetingCalendarIntegration/ux-ui.md](../MeetingCalendarIntegration/ux-ui.md) (SC-MTG-CAL-01) ใช้ Calendar panel / full view ชุดเดียวกัน
> **ข้อสังเกตสำคัญ:** Figma ต่างจาก ClickUp หลายจุด (สี Zyra, ไม่มี Google/Outlook ใน design, popup ไม่มี source badge/description, error เป็น toast ไม่ใช่ banner, ไม่มี empty-state message) → ดู [§10](#10-figma-vs-clickup--ข้อขัดแย้งที่ต้องถาม)

---

## 0. Section / frame inventory

ทุก frame 1440×1024 · layer ชื่อ `Chat - Full view` คือ **Calendar full view** (ชื่อ layer ตกค้างจาก Chat)

| Scenario | Section | Frame (ซ้าย → ขวา) | Sticky (ข้อความ designer) |
|---|---|---|---|
| CLDD-HP-01 | `3898:761567` | `3898:779578` Idle UI (VO ก่อนเปิด) → `3898:778669` Half view + banner → `3898:778668` Half view → `3898:780220` Full view (Month) | `7762:170696` "ถ้ายังไม่มีการเซ็ตแล้วกากบาท Banner นี้จะโผล่มาเตือนวันละครั้ง" |
| CLDD-HP-02 | `4998:56260` | `4998:56263` Month (July 2026) → `4998:58541` + popup "+X more" `4998:58586` → `5106:41385` popup + Event detail `5106:41388` · แถวล่าง `5106:40788` Month (June 2026) | — |
| CLDD-HP-03 | `7747:74314` | `7747:74316` **Month** (สถานะก่อนกด Week) → `7753:37904` **Week** | — |
| CLDD-HP-04 | `7747:76800` | `7747:76802` **Month** (ภาพเหมือน `7747:74316` ทุก pixel) → `7753:39166` **Day** | — |
| CLDD-HP-05 | `7755:40085` | `7755:41732` Week (ก่อนกด) → Detail popup 6 แบบ: `7756:42824` base · `7759:86500` external link · `7756:46446` ยังไม่ตอบรับ · `7758:85071` Yes · `7758:85203` No · `7758:85836` Maybe | `7759:115928` "กรณีเซ็ตเป็น External link" · `7759:115933` "การตอบรับแต่ละรูปแบบ" (ทั้งคู่โดย Pai) |
| CLDD-EP-01 | `7759:120313` ⚠️ ชื่อ section ผิดเป็น "CLDI-HP-03 : สร้าง Zyra Meeting แล้ว Sync ไป Calendar ภายนอก" แต่เนื้อหาเป็น EP-01 | แถว "ไม่มี Events ในช่วงเวลาที่ดู": `7759:120360` → `7759:120365` → `7759:135034` · แถว "Calendar โหลดล้มเหลว (Network Error)": `7759:166254` skeleton → `7759:167460` skeleton + toast → `7761:168182` โหลดสำเร็จ | — |

### Layout ระดับหน้า (Full view `4998:56263`)

| ส่วน | Node | x / y | Size |
|---|---|---|---|
| Side bar | `I4998:56263;3290:703130` | 0 / 0 | 72×1024 |
| Calendar panel | `I4998:56263;3290:703503` | 72 / 16 | 320×992 |
| Calendar view | `I4998:56263;3298:4784` | 408 / 16 | 1014×991 (gap จาก panel 16 · ขวาเหลือ 18) |

Calendar view container: flex-col, **radius 16**, overflow clip (`I7753:37904;3298:4784`) · ส่วนบน (toolbar + day header + all-day) bg **#2B3540** gap 16 · ส่วน grid bg **#344354**
Frame root background: **ยังไม่ได้ดึง**

---

## 1. Design tokens (`get_variable_defs` บน `4998:56263` + ที่พบใน frame อื่น)

### สี

| Token | Hex | ใช้ที่ |
|---|---|---|
| Background/Primary · Theme colour/Primary | `#242B32` | sidebar, input, mini calendar, upcoming card, popup |
| Theme colour/Secondary | `#2B3540` | Calendar panel, toolbar/header, RSVP footer |
| Theme colour/Teritery (สะกดตาม Figma) | `#344354` | grid ของ Month / Week / Day |
| Primary/500 · Primary/Mint-500 | `#58D68D` | today, ปุ่ม +, ปุ่ม Join / Try again, bar ของ event My calendar |
| Primary/10% | `rgba(88,214,141,0.1)` | sidebar active, banner bg |
| Primary/20% | `rgba(88,214,141,0.2)` | event chip/block bg, view toggle selected, banner border |
| Grey/500 | `#8C99A6` | text รอง, วันเดือนอื่นใน Month grid, GMT+7, hour label |
| Grey/700 | `#636D76` | placeholder, วันเดือนอื่นใน mini calendar |
| Grey/900 | `#3B4046` | RSVP badge Maybe |
| Gray/6 | `#D1D1D6` | checkbox unchecked border |
| — (ไม่มีชื่อ token) | `#CAD0D6` | location ใน Day view event block |
| Blue/500 | `#2DB6FF` | Thai Holidays / all-day Holiday chip, link, icon info ของ toast |
| Blue/20% | `rgba(45,182,255,0.2)` | icon box ของ toast |
| Red/500 | `#F03A3A` | current-time line + label, RSVP No |
| Shade Black/500 | `#1A1B1E` | toast bg |
| Solid White/5% | `rgba(255,255,255,0.05)` | ปุ่ม secondary bg, cell border, skeleton |
| Solid White/20% | `rgba(255,255,255,0.2)` | border ปุ่ม / input / toggle / outline chip |
| — | `rgba(255,255,255,0.08)` | hour rule, day divider, all-day row border |
| — | `rgba(255,255,255,0.03)` | half-hour rule |
| — | `rgba(88,214,141,0.03)` | shade column วันนี้ (Week) |
| White shadow | `#FFFFFF14` = `rgba(255,255,255,0.08)` | popup / modal / toast shadow |
| Chat badge | `#D41818` | badge ใน sidebar (ไม่อยู่ใน scope) |

### Typography (Inter ทั้งหมด)

| Token | size / line-height / weight / letter-spacing |
|---|---|
| Title/Bold | 20 / 25 / 700 / 0 |
| Title/Medium | 20 / 25 / 500 / 0 |
| Sub/Regular | 16 / 22 / 400 / 0 |
| Body/Regular | 14 / 18 / 400 / 0 |
| Body/Medium | 14 / 18 / 500 / 0 |
| Caption 1/Regular | 12 / 15 / 400 / -0.43% (`tracking-[-0.0516px]`) |
| Caption 1/Semi | 12 / 15 / 600 / -0.43% |
| Caption 2/Regular | 10 / 13 / 400 / -0.43% (`tracking-[-0.043px]`) |
| Caption 2/Medium | 10 / 13–14 / 500 |

---

## 2. Entry point — Side bar (HP-01)

Node `I3898:778669;3260:680547` (ดึงจาก Half view)

| Property | Value |
|---|---|
| Container | bg `#242B32`, p 16, flex-col justify-between, w 72 |
| Logo | 40×40 |
| Menu | gap 16 · item w 40, p 8, radius 8, icon 24×24 |
| ลำดับไอคอน | Map → Member → Chat → **Calendar (ลำดับที่ 4)** → Notifications → Megaphone |
| Calendar active | bg `rgba(88,214,141,0.1)`, icon สี `#58D68D` (`…;1951:254129`) |
| ล่าง | Question, Setting (24px), divider, avatar 40 |
| Idle state (`3898:779578` → `I3898:779578;5:868`) | **ยังไม่ได้ดึง** spec (เห็นแค่ใน screenshot ว่ายังไม่มี panel) |

**Flow HP-01:** กดไอคอน Calendar → เปิด **Half view** (panel 320 ทับ VO map, VO ยังเห็นด้านขวา) → กดปุ่ม Expand → **Full view** (Calendar view 1014 แทน VO map) เปิดที่ **Month** (tab Month selected)

| | Half view | Full view |
|---|---|---|
| ด้านขวาของ panel | VO map (BG 1016×992 ที่ x 408) | Calendar view 1014×991 |
| ปุ่มแรกใน panel title | icon **Expand** (`I3898:778669;3290:702456;3898:775974`) | icon **Collapse** (`…;3260:680815`) |
| Panel content | เหมือนกัน (+ banner ถ้ายังไม่เชื่อม) | เหมือนกัน |

---

## 3. Calendar panel (ซ้าย 320px) — `I4998:56263;3290:703503`

Container: bg `#2B3540`, radius 16, p 16, gap 16, flex-col, overflow clip, 320×992

### 3.1 Title row `…;3260:680812` (flex justify-between, h 32)

| Element | Value |
|---|---|
| "Calendar" | Title/Bold 20/25 `#FFFFFF` |
| Menu group | gap 8 |
| ปุ่ม Expand/Collapse | 32×32, bg `rgba(255,255,255,0.05)`, border 1px `rgba(255,255,255,0.2)`, radius 6, p 8, icon 16 |
| ปุ่ม + (สร้าง meeting) | 32×32, bg `#58D68D`, radius 6, p 8, icon Plus 16 (`…;3260:680816`) |

### 3.2 Search input `…;3260:680818;35:3019`

| Property | Value |
|---|---|
| Size | 288×42 |
| Style | bg `#242B32`, border 1px `rgba(255,255,255,0.2)`, radius 8, px 12, py 8, gap 8 |
| Placeholder | "Search for meeting" (ค้นหาการประชุม) — Body/Regular 14/18 `#636D76` |

### 3.3 Connect-calendar banner (HP-01) — `I3898:778669;3290:702456;3898:776232`

แสดงเมื่อยังไม่ได้เชื่อม Google / Outlook · ตาม sticky: **กด X ปิดแล้วจะโผล่เตือนใหม่วันละครั้ง ถ้ายังไม่ได้ตั้งค่า**

| Property | Value |
|---|---|
| ตำแหน่ง | ใน panel ระหว่าง Search กับ Mini calendar (y 122) |
| Size | 288×144 |
| Container | bg `rgba(88,214,141,0.1)`, border 1px `rgba(88,214,141,0.2)`, radius 8, p 8, gap 16, flex-col justify-center, overflow clip |
| Text block `…;3898:776243` | flex-col gap 8, w 272 |
| Title | "Connect your calendar" (เชื่อมต่อปฏิทินของคุณ) — Body/Medium 14/18 white |
| Body | "Bring your Google or Outlook events into Zyra to manage your schedule in one place." (นำ events จาก Google หรือ Outlook เข้ามาใน Zyra เพื่อจัดการตารางเวลาในที่เดียว) — Body/Regular 14/18 `#8C99A6`, 3 บรรทัด |
| Button `…;3898:776247` | "Go to setting" (ไปที่การตั้งค่า) — 118×32, bg `#58D68D`, radius 6, px 16, py 8, text Body/Regular 14/18 white |
| Close X `…;3898:776265` | icon Cancel 16×16, top 8 / right 8 |
| Mascot `…;3898:776237` "C-hand2 1" | ~109×109 ที่ x 211 y 115 (ล้นขอบ ถูก clip เหลือแค่หัว) — เป็น image asset |
| Hidden "Alert banner" 288×70 `…;3898:775976` | เนื้อหา **ยังไม่ได้ดึง** |

> หมายเหตุ: text style ของ title/body map จาก token ของ frame + screenshot (per-node style ยังไม่ได้ดึง)

### 3.4 Section header ("TitleMenu")

| Property | Value |
|---|---|
| Layout | flex justify-between, w 288 · header → content gap 8 · ระหว่าง section gap 16 |
| Label | Body/Regular 14/18 `#8C99A6` |
| Chevron | 14×14 (Up = เปิด, Down = ปิด) |
| Sections | "Mini calendar" · "Upcoming meeting" · "Calendar list" |

### 3.5 Mini calendar `…;3290:702340`

| Property | Value |
|---|---|
| Container | bg `#242B32`, radius 16, p 8, w 288, gap 16 (inner gap 8) |
| Header | "July, 2026" Body/Regular 14/18 white · chevron ซ้าย/ขวา 14×14 gap 8 |
| Week start | Sunday |
| Weekday labels | "S M T W T F S" — Caption 1/Semi 12/15 `#8C99A6` |
| Day cell | h 32, w 1/7 (flex-1), p 8, center · text Body/Regular 14/18 white |
| Other-month day | text `#636D76` |
| Today | bg `#58D68D`, radius 90 (pill เต็ม cell ≈38.9×32), text white |
| Rows | 6 แถวเสมอ |
| Hover / selected (ที่ไม่ใช่ today) | ไม่มีใน design |

### 3.6 Upcoming meeting card (component `3284:701907` default / `3288:702126` disabled)

ตาม CAL-01 sticky: "Upcoming meeting จะโชว์แค่ของวันนั้นเท่านั้น"

| Property | Value |
|---|---|
| Card | bg `#242B32`, border 1px `rgba(255,255,255,0.05)`, radius 16, p 12, gap 8, 288×90 |
| Icon button | bg `rgba(255,255,255,0.05)`, border 1px `rgba(255,255,255,0.2)`, radius 6, p 8, icon VideoOn 16 |
| Title | Body/Medium 14/18 white, ellipsis 1 บรรทัด |
| Time / Location row | icon 16 gap 4 · text Caption 1/Regular 12/15 `#8C99A6` ellipsis |
| Disabled (ประชุมที่ผ่านไปแล้ว) | opacity 60% |
| List gap | 8 |
| Now-line ในลิสต์ | วงกลม 8×8 + เส้น 281×2 (288.3×8) — สีแดงในภาพ แต่สีจริงเป็น SVG **ยังไม่ได้ดึง** |

### 3.7 Calendar list (legend + filter) `…;3295:704087`

| Property | Value |
|---|---|
| Rows | gap 16 · row = checkbox 16 + label gap 8 |
| Checkbox checked | 16×16 radius 4, bg = สีของ calendar, check icon inset 15% |
| Checkbox unchecked | 16×16 radius 4, border 1px `#D1D1D6`, ไม่มี bg |
| Label | Body/Regular 14/18 white |
| Items ใน design | ☑ "My calendar" (`#58D68D`) · ☑ "Thai Holidays" (`#2DB6FF`) · ☐ "Christian Holidays" · ☐ "American League All-Star Team" |
| ตำแหน่ง | ล่างสุดของ panel (scroll ทั้ง container) |

> ⚠️ **ไม่มี Google Calendar / Outlook ใน list** — ดู §10

---

## 4. Calendar view toolbar (ใช้ร่วม Month / Week / Day) — `I4998:56263;3298:4784;3295:703744`

| Element | Node | Value |
|---|---|---|
| Header container | `…;3295:703744` | bg `#2B3540`, flex-col gap 16 |
| Title row | `…;3295:703812` | p 16, flex justify-between, h 74 |
| Left group | `…;3295:703906` | gap 8, items-center |
| "Today" (วันนี้) | `…;3295:703914` | 79×42, bg `rgba(255,255,255,0.05)`, border 1px `rgba(255,255,255,0.2)`, radius 8, px 16, py 8 · Sub/Regular 16/22 white |
| Period label | `…;3295:703813` | "July, 2026" — Title/Medium 20/25 white (Week: layer เขียน "20 July, 2026" แต่ภาพ render "July, 2026" — ดู §10) |
| Prev / Next | `…;3295:703928` / `…;3295:703907` | chevron 16×16, gap 8 |
| Right group | `…;3295:704019` | gap 8, justify-end |
| View toggle "Tab fill" | `…;3295:703847` | 259×42, border 1px `rgba(255,255,255,0.2)`, radius 8, p 4 · item h 32, p 8, flex-1, Body/Regular 14/18 white · **selected** bg `rgba(88,214,141,0.2)` radius 8 · labels "Day" / "Week" / "Month" |
| "Sync now" (ซิงก์ตอนนี้) | `…;3295:704048` | 130×42, bg `rgba(255,255,255,0.05)`, border 1px `rgba(255,255,255,0.2)`, radius 8, px 16, py 8, gap 8 · icon Reset 16 + Sub/Regular 16/22 white |

Hover / pressed / focus ของปุ่มทุกตัว: **ไม่มีใน design**

---

## 5. Month View (HP-02)

### 5.1 Weekday row `…;3295:704635`

| Property | Value |
|---|---|
| Row | 7 × 144.857 w, h 50 |
| Cell `…;3295:704739` | p 16, gap 8, flex-col items-center justify-end · label Body/Regular 14/18 white ("Sun" … "Sat") |
| Date circle | ซ่อนใน Month (ใช้ใน Week) |

### 5.2 Grid — `…;3295:704653` / Table `…;3295:704834`

| Property | Value |
|---|---|
| Container | bg `#344354`, border-top 1px `rgba(255,255,255,0.2)`, 1014×851 |
| Layout | 7 col × **6 แถวเสมอ** (ทั้ง July และ June 2026) |
| Cell | 144.857 × 141.833 (component main `4998:55577` = 144.857×133.333) · border 1px `rgba(255,255,255,0.05)`, p 8, เลขวันอยู่กลางบน · ไม่มี bg แยก |
| Day number wrapper | w 23, p 4, radius 90 |
| Day number text | Caption 1/Regular 12/15 |
| Default `4998:55579` | text white |
| วันของเดือนอื่น `4998:55753` | text `#8C99A6` (bg cell ไม่เปลี่ยน) |
| Today `4998:55577` | bg `#58D68D`, text white |
| Week start | Sunday |

### 5.3 Event chip ("Meeting event")

| Variant | Node ตัวอย่าง | Style |
|---|---|---|
| Timed — filled (My calendar) | `I4998:56263;3298:4784;4998:55919` | bg `rgba(88,214,141,0.2)`, radius 4, p 2 · inner gap 2 · **bar 2×8** `#58D68D` radius 90 · title Caption 2/Regular 10/13 white, ellipsis 1 บรรทัด |
| Timed — outline | `…;4998:55928` | ไม่มี bg, border 1px `rgba(255,255,255,0.2)`, radius 4, p 2 · bar 2×8 **white** · ความหมาย**ไม่ระบุ** (ใช้กับ "Product consult") |
| All-day — Holiday | `…;4998:55951` | bg **`#2DB6FF`** solid, radius 4, p 2 · bar opacity 0 · title "Holiday" 10/13 white |
| "+X more" | `…;4998:55966` | copy **"2 More"** (อีก 2 รายการ — ไม่มี "+") · bg `rgba(88,214,141,0.2)`, radius 4, p 2, hug ~37×16 · text Caption 2/Regular 10/13 **`#58D68D`** |

| Layout ใน cell (chip วาง absolute ไม่ใช่ auto-layout) | Value |
|---|---|
| Chip size | w 135, h 16 (บางอันสูง 17 — ไม่ consistent) |
| Inset ซ้าย | ~5px |
| ระยะระหว่าง chip | 3px |
| เลขวัน → chip แรก | ~8.5px |
| Max | 3 chips + "N More" |

### 5.4 "+X more" day popup — `4998:58586` (167×196)

| Property | Value |
|---|---|
| Container | bg `#242B32`, radius 16, p 16, gap 16, flex-col items-center justify-end · ไม่มี border/shadow |
| Header | flex-col gap 4: weekday "Mon" Body/Regular 14/18 white · date circle w 30 p 4 bg `#58D68D` radius 90, "20" Sub/Regular 16/22 white |
| List | flex-col gap 4 · chip 135×16 (style เหมือน 5.3) · แสดง**ทุก** event |
| Close | icon Cancel 16×16, top 8 / right 8 |

**Placement** (`5106:41385`): popup ที่ x 603 y 590 (ทับ cell Mon 20, ต่ำกว่าขอบบน cell ~8.5px) · กด event ใน popup → Event detail `5106:41388` 340×453 วาง**ขวาของ popup ห่าง 8px** (x 778 y 594 — ล้นขอบล่าง frame: 594+453 = 1047 > 1024) · **ไม่มี backdrop**

### 5.5 Month อื่น — `5106:40788` (June 2026)

แถวแรก 31 (May, สีเทา) + 1–6 · แถว 6 เป็นเดือนถัดไปทั้งแถว → 6 แถวคงที่ · ไม่มี event / ไม่มี today · mini calendar ใน frame นี้ยังเป็น "July, 2026" (design ไม่ sync กัน)

---

## 6. Week View (HP-03) — `7753:37904` → `I7753:37904;3298:4784`

Toolbar: tab **"Week"** selected (`…;3586:175530`) · ความกว้าง column วัน = (1014 − 64) / 7 = **135.714**

### 6.1 Time-zone column + Day header

| Item | Value | Node |
|---|---|---|
| Time-zone column | w **64**, flex-col items-center justify-end, pb 14 · text **"GMT+7"** Caption 2/Regular 10/13 `#8C99A6` | `…;7753:37662/37663` |
| Day header cell | flex-1, flex-col items-center justify-end, p 16, gap 8 | `…;3586:175533` … `175539` |
| Weekday label | "Sun" … "Sat" Body/Regular 14/18 white | `…;3295:704649` |
| Date circle | 30×30, p 4, radius 90 · text Sub/Regular 16/22 white | `…;3295:704650/704651` |
| Today | circle bg `#58D68D` | `…;3586:175534;3295:704647` |

### 6.2 All-day row ("Event band")

| Item | Value | Node |
|---|---|---|
| Row | h **32**, border-top 1px `rgba(255,255,255,0.08)`, overflow clip | `…;7753:37693` |
| Label cell | w 64, center · **"All-day"** (ทั้งวัน) Caption 2/Regular 10/13 `#8C99A6` | `…;7753:37694/37695` |
| Day cell | flex-1, border-left 1px `rgba(255,255,255,0.08)`, px 4, py 5 | `…;7753:37696` … `37703` |
| Holiday chip | bg `#2DB6FF`, h **22**, radius 4, p 2, เต็ม cell · "Holiday" 10/13 white ellipsis · bar opacity 0 | `…;7753:37701` (component `3586:175807` varient="Holiday") |

### 6.3 Hourly grid ("Hourly schedule" `…;7753:36129`)

| Item | Value |
|---|---|
| bg | `#344354` |
| **1 ชั่วโมง** | **72px** |
| **30 นาที** | **36px** (= 1 row ตาม ClickUp) |
| ช่วงที่วาด | 08:00 → 18:00 (visible 740px) ที่เหลือต้อง scroll — **00:00–07:30 และ 18:30–23:30 ไม่ได้วาด** |
| Hour label | "08:00" … "18:00" — w 56, text-center, Caption 2/Regular 10/13 `#8C99A6`, ชิดบนของ row · **ไม่มี label ของ :30** |
| Hour rule | 1px `rgba(255,255,255,0.08)` ต่อจาก label (x 56 → ขวาสุด) |
| Half-hour rule | 1px `rgba(255,255,255,0.03)`, left 64, w 950 |
| Day divider | 1×740 `rgba(255,255,255,0.08)` ที่ left 64 / 199.71 / 335.43 / 471.14 / 606.86 / 742.57 / 878.29 |
| Today column shade | bg `rgba(88,214,141,0.03)` เต็มความสูง (`…;7753:36130`) |
| Scrollbar track | x 1008, top 4, w 3, h 732, radius 3, `rgba(255,255,255,0.02)` |
| Scrollbar thumb | w 3, h 220, radius 3, `rgba(255,255,255,0.15)` |

### 6.4 Timed event block ("Timed meeting")

| Item | Value | Node |
|---|---|---|
| Position | absolute · left = column left + **4** · width = column − **8** = 127.714 | `…;7753:36181` |
| Top | (start − 08:00) × 72px/ชม. เช่น 09:00 → 72 · 10:15 → 162 | — |
| Height | 1 ชม. = **70** (72 − 2) · event สั้น (5 / 20 นาที) = **48** (= min-height) | `…;7753:36184/36187` |
| Container | flex-col, gap 2, p 4, radius 4 |  |
| bg (accepted) | `rgba(88,214,141,0.2)` | — |
| bg (variant ขาว "Product consult") | transparent + border 1px `rgba(255,255,255,0.2)` · bar white · ชื่อ/ความหมาย variant **ยังไม่ได้ดึง** | `…;7753:36187` (component `3298:4689`) |
| Title row | h 17, p 2 · bar **2×8** radius 90 `#58D68D` (หรือ white) + title Caption 2/Regular 10/13 white ellipsis | `…;3298:4673/4674` |
| Time text | 10/13 white, รูปแบบ **"09:00–10:00"** (en-dash ไม่มีเว้นวรรค) · block 48px ใช้ **9px**/13 | `…;7753:36183/36186` |

### 6.5 Overlap

ตัวอย่าง Mon: "Catch up Zyra project" + "Product consult" → กว้าง **61.857 เท่ากัน** ((127.714 − 4) / 2), **gap 4px**, top ตาม start ของแต่ละอัน (ไม่ align)
Overlap ≥ 3 อัน: **ยังไม่ได้ดึง** (ไม่มีใน design)

### 6.6 Current time indicator

| Item | Value | Node |
|---|---|---|
| Label | bg `#F03A3A`, **50×18**, radius 4, left 6 · "10:10" Caption 2/Medium 10/13 white center (ทับ hour label) | `…;7753:36202/36203` |
| Line | h **2px** `#F03A3A` · **เฉพาะ column วันนี้** (w 135.714) · top = ตำแหน่งเวลาจริง (10:10 → 156) | `…;7753:36204` |
| Dot | 8×8 SVG ที่ขอบซ้าย column วันนี้ — สีจริง **ยังไม่ได้ดึง** (ภาพเป็นแดง) | `…;7753:36205` |

---

## 7. Day View (HP-04) — `7753:39166` → `I7753:39166;3298:4784`

Toolbar: tab **"Day"** selected (`…;7753:38459`) · ค่า grid / label / rule / scrollbar **เหมือน Week ทุกตัว** ยกเว้น:

| Item | Day view value | Node |
|---|---|---|
| Day header | 1 column: "Mon" + วงกลม today `#58D68D` 30px "20" | `…;7753:38465` |
| All-day ว่าง | แสดง **"—"** Caption 1/Regular 12/15 `#8C99A6`, items-center, px 4, py 5 | `…;7753:39163/39164` |
| Day divider | เส้นเดียวที่ left 64 | `…;7753:39081` |
| Today shade | **ไม่มี** | — |
| Current-time line | h 2 `#F03A3A` **เต็มความกว้าง** (left 64, w 950) · dot ที่ left 60 · label เหมือน Week | `…;7753:39143/39144/39141` |
| Event block (≥ 1 ชม.) | left **68**, w **942** (950 − 8), h 70, p 4, gap 2, radius 4, bg `rgba(88,214,141,0.2)` | `…;7753:39125` |
| เนื้อหา block ยาว | [bar + title 10/13] · time "09:00–10:00" 10/13 white · **location** "Marketing room" Caption 1/Regular 12/15 **`#CAD0D6`** | `…;7753:39126–39128` |
| Block สั้น (แถวเดียว) | p 2, radius 4, flex-row **gap 8**: [bar + title] + time **"10:15 - 10:20"** (มีเว้นวรรค + hyphen) 10/13 white · ความสูง auto (accepted) / h **24** (variant ขาว) | `…;7753:39129` / `…;7753:39133` |
| Overlap | 2 อัน: left 68 w 469 + left 541 w 469 → เท่ากัน gap 4 | — |

> รูปแบบเวลาใน Week ("09:00–10:00") กับ Day block สั้น ("10:15 - 10:20") ไม่เหมือนกัน — ดู §10

---

## 8. Event Detail Popup (HP-05) — base `7756:42824`

### 8.1 ตำแหน่ง

| Item | Value |
|---|---|
| Week | popup x 744 y 314 (frame `7756:42823`) = **ชิดขวาของ column ที่คลิก** (column Mon ขอบขวา ≈ 743.4), top ≈ ระดับ block ที่คลิก |
| Month | ขวาของ "+X more" popup ห่าง 8px (§5.4) |
| Backdrop | **ไม่มี** |
| Selected state ของ event card | ไม่เห็นความต่าง |
| ปิดด้วย ESC / click outside | Figma ไม่ระบุ (มีแค่ icon Close) |
| ใกล้ขอบขวา / ขอบล่าง | **ยังไม่ได้ดึง** (ไม่มีใน design · Month ตัวอย่างล้นขอบล่าง) |

### 8.2 Container

w **340** · h 453 (ปกติ) / 425 (external link) / 509 (มี RSVP footer) · bg `#242B32` · radius 16 · p 16 · flex-col gap 16 · overflow clip · shadow `0 4px 16px 0 rgba(255,255,255,0.08)`

### 8.3 ส่วนประกอบ (เรียงบน → ล่าง)

| # | Item | Value | Node |
|---|---|---|---|
| 1 | Header (⚠️ ไอคอนแรกตอนนี้เป็น **calendar-x** = Cancel meeting และเปลี่ยนตาม role — ดู [CAL-01 ux-ui-plan §7.1–7.2](<../[Feature] Meeting — Calendar Integration/ux-ui-plan.md>)) | justify-between · **"Event detail"** (รายละเอียด event) Body/Medium 14/18 white · ขวา: icon **Trash**, **Edit**, **Cancel (ปิด)** 16×16 gap 16 | `I7756:42824;3592:298624` |
| 2 | Title row | h 22, gap 8 · swatch **12×12 radius 4** `#58D68D` · title "Daily standup meeting" Body/Medium 14/18 white | `…;7776:229118` |
| 3 | Divider | SVG เต็มความกว้าง — สี/ความหนา **ยังไม่ได้ดึง** | `…;3592:298629` |
| 4 | Date/time | icon Calendar 16 + gap 16 · text Body/Regular 14/18 `#8C99A6` gap 4: "20 July, 2026" · "•" · "10:00 - 10:30" | `…;3592:298737` |
| 5 | Location | icon Location 16 + gap 16 · "Product Zyra room" 14/18 `#8C99A6` ellipsis | `…;3594:752712` |
| 6 | Join button | ขวาของ #4–5 (flex items-end gap 16) · bg `#58D68D`, h 24, px 8, py 6, radius 4, gap 4 · icon VideoOn 16 + **"Join"** (เข้าร่วม) 14/18 white | `…;3594:752696` |
| 7 | Divider | เหมือน #3 | `…;3594:752642` |
| 8 | Participants | icon member 16 + gap 16 · "3 participants (1 yes and 3 awaiting)" (ผู้เข้าร่วม 3 คน — ตอบรับ 1, รอตอบ 3) 14/18 `#8C99A6` | `…;3593:299276` |
| 9 | Guest row | w 308, h 53, p 8, radius 8, gap 8 | `…;3593:299312…314` |
| 9a | Avatar | 32×32 radius 90 · ถ้าไม่มี status → border 1px `rgba(255,255,255,0.2)` | — |
| 9b | RSVP badge | มุมขวาล่าง (~8×8), radius 90, border 1px `#242B32` — ดู 8.5 | `…;6894:1062442` |
| 9c | Name | Body/Medium 14/18 white ellipsis | `…;3586:258090` |
| 9d | Role | Caption 1/Regular 12/15 `#8C99A6` — "Organiser" (ผู้จัด) / "Guest" (แขก) · gap 4 จาก name | `…;3586:258092` |
| 10 | Divider | เหมือน #3 | `…;3594:752643` |
| 11 | Link row | icon Link 16 + gap 16 · "Zyraworld.com" 14/18 **`#2DB6FF` underline** ellipsis · ขวา: Copy button p 4, radius 4, bg `rgba(255,255,255,0.05)`, border 1px `rgba(255,255,255,0.2)`, icon Copy 16 | `…;3594:752684/752652` |

Copy ตัวอย่าง attendees: "Dechawat Phondechaphiphat" (Organiser), "Conan Grey" (Guest), "Taylor Swift" (Guest)

### 8.4 Variants (6 แบบ)

| Node | h | ต่างจาก base |
|---|---|---|
| `7756:42824` | 453 | **Base** — มี location + Join · organiser มี badge ✓ · guest ไม่มี badge · link "Zyraworld.com" · ไม่มี RSVP footer |
| `7759:86500` | 425 | **External link** (sticky "กรณีเซ็ตเป็น External link") — **ไม่มีแถว location** · Join **opacity 0** (ซ่อนแต่กินพื้นที่) · link "Googlemeet.com" |
| `7756:46446` | 509 | **ยังไม่ได้ตอบรับ** — RSVP footer ชิดล่าง: bg `#2B3540`, p 16, gap 8 · **"Join?"** (เข้าร่วมไหม?) 14/18 white flex-1 · ปุ่ม **"Yes" "No" "Maybe"** (ไป / ไม่ไป / อาจจะ) h 24, px 8, py 6, radius 4, bg `rgba(255,255,255,0.05)`, border 1px `rgba(255,255,255,0.2)`, text 14/18 white · **มี X สีขาว 16px ขวาของ title row** (`I7756:46446;7776:234217`) ความหมายไม่ทราบ |
| `7758:85071` | 453 | **ตอบ Yes** — footer หาย · "Conan Grey" ได้ badge ✓ |
| `7758:85203` | 453 | **ตอบ No** — "Conan Grey" badge แดง X |
| `7758:85836` | 453 | **ตอบ Maybe** — "Conan Grey" badge "?" |

> ทุก variant ใช้ summary เดิม "3 participants (1 yes and 3 awaiting)" (placeholder ไม่ได้อัปเดตตาม state)

### 8.5 RSVP badge

| State | Badge |
|---|---|
| Yes | bg `#58D68D`, border 1px `#242B32`, icon Check 8×8 |
| No | bg `#F03A3A`, border 1px `#242B32`, p 1, icon Cancel 8×8 |
| Maybe | border 1px `#242B32` · inner 10×10 radius 90 bg `#3B4046` · "?" Inter 8px `#8C99A6` |
| Awaiting | ไม่มี badge · avatar border 1px `rgba(255,255,255,0.2)` |

Hover / disabled ของ Join, Yes/No/Maybe และ selected state หลังกด RSVP: **ยังไม่ได้ดึง** (ไม่มีใน design)

---

## 9. Empty / Loading / Error (EP-01) — section `7759:120313`

### 9.1 ไม่มี Events ในช่วงเวลาที่ดู (`7759:120360`)

- **ไม่มี** ข้อความ empty state และ**ไม่มี**ปุ่ม "สร้าง Meeting ใหม่" กลาง calendar — เป็น Week grid เปล่า (ยังมี chip "Holiday" ที่ Fri 24 จาก Thai Holidays)
- design แสดงการสร้าง meeting ผ่าน **Schedule event** popover แทน (ไม่มี backdrop):

| Frame | Modal | ตำแหน่ง | trigger (ตีความ — ไม่ยืนยัน) |
|---|---|---|---|
| `7759:120365` | `7759:120367` 340×711 | x 416 y 24 (ข้าง panel) | น่าจะจากปุ่ม + ใน panel title |
| `7759:135034` | `7759:135036` 340×711 | x 758 y 242 (ลอยบน grid) | น่าจะจากคลิกช่องว่างใน grid · ค่าใน modal เป็น Mon 20 แต่วางที่ column Tue/Wed |

Schedule event modal (main `3586:257415`) — สรุปเท่าที่ใช้อ้างอิง (spec เต็มอยู่ใน CAL-01 [ux-ui.md §4](../MeetingCalendarIntegration/ux-ui.md)):

| Prop | Value |
|---|---|
| Outer | 340×711, bg `#242B32`, radius 16, p 16, gap 16, shadow `0 4 16 0 rgba(255,255,255,0.08)` |
| Title / subtitle | "Schedule event" (นัดหมาย event) Title/Bold 20/25 white · "Create and schedule meetings." (สร้างและนัดหมายการประชุม) 14/18 `#8C99A6` · Close icon Cancel 24 |
| Fields | "Event" → "Please input event" · "Date & Time" → "20 July, 2026" + "10:00" / "10:30" · checkbox "All day" · "Location" → "Please select location" · "Guest" → "Please add guest" · "Description" → "Add description" (h 100) |
| Input | h 42, bg `#242B32`, border 1px `rgba(255,255,255,0.2)`, radius 8, px 12, py 8 · placeholder `#636D76` |
| Buttons | "Cancel" (ยกเลิก) bg white, text `#1A1B1E` 16/22, h 42, px 16, radius 8 · "Create" (สร้าง) disabled bg `#DBDFE3`, border `#B2BBC3`, text `#A3ADB8` · gap 16 justify-end |

### 9.2 Loading skeleton (`7759:166254`)

ทุก placeholder = **`rgba(255,255,255,0.05)`** ไม่มี border · **ไม่มี shimmer** ใน design (static fill) · sidebar แสดงปกติ

| ส่วน | Placeholder | Size | Radius |
|---|---|---|---|
| Panel title | "Calendar" เป็นข้อความจริง · ปุ่ม 32×32 (ใน screenshot icon ไม่แสดง — สาเหตุยังไม่ได้ดึง) | — | 6 |
| Search | `7759:166705` | 288×42 | 8 |
| Section label ×3 | `7759:167137` / `167139` / `167141` | 119×18 | 4 |
| Mini calendar | `7759:167004` | 288×266 | 8 |
| Upcoming card ×3 | `7759:167143` / `167153` / `167154` | 288×90 | 16 |
| Calendar list row ×3 | `7759:167151` / `167149` / `167147` | 119×18 | 4 |
| Toolbar ซ้าย / ขวา | `7759:167329` / `7759:167331` | 288×42 / 362×42 | 16 |
| Time-zone label | `7759:167333` | 40×16 | 4 |
| Day header (ต่อ column) | day name 40×16 (Sun–Tue) / 40×18 (Wed–Sat) + date 40×30 | — | 4 |
| All-day label | — | 40×16 | 4 |
| Hour label ×11 | ทุก 72px | 40×16 | 4 |

Grid rule / divider / scrollbar แสดงตามปกติ (ค่าเดียวกับ §6.3) · event block ซ่อนทั้งหมด

### 9.3 Error toast (`7761:168158` ใน `7759:167460`)

**Design ใช้ toast มุมขวาบน ไม่ใช่ error banner** และ skeleton ยังค้างอยู่ด้านหลัง

| Prop | Value |
|---|---|
| Size / position | 336×124 · top 16, right 16 (ทับ toolbar) |
| Container | bg `#1A1B1E`, radius 16, p 16, flex-col gap 16 · ไม่มี border · shadow `0 4px 8px rgba(255,255,255,0.08)` |
| Icon box | w 40, p 8, radius 8, bg `rgba(45,182,255,0.2)` · icon info (ⓘ) 24px `#2DB6FF` (layer ชื่อ "Check") |
| Title | "Couldn't load calendar events" (โหลด events ในปฏิทินไม่สำเร็จ) — Inter Bold 14/18 white |
| Body | "Please try again." (กรุณาลองใหม่อีกครั้ง) — Body/Regular 14/18 white |
| Close X | icon Cancel 16px white, ขวาบน |
| Action row | flex gap 8, justify-end |
| Retry | "Try again" (ลองใหม่) — bg `#58D68D`, h 32, px 16, py 8, radius 6, text 14/18 white |
| Hidden secondary | "Text" — bg white, text `#1A1B1E`, h 32, radius 6, **opacity 0** |
| Auto-dismiss / hover / pressed | **ยังไม่ได้ดึง** (ไม่มีใน design) |

หลังกด Try again (`7761:168182`): กลับเป็น Week view ปกติ toast หายไป

---

## 10. Figma vs ClickUp — ข้อขัดแย้งที่ต้องถาม

> **กติกากลาง 3 ฟีเจอร์ (ผู้ใช้ตัดสิน 2026-10-29):** Figma กับ ClickUp ขัดกัน → **ยึด Figma** ยกเว้นข้อที่ผู้ใช้ตัดสินเป็นอย่างอื่น (ดู [CAL-01 spec §6.1](<../[Feature] Meeting — Calendar Integration/spec.md>)) · ข้อที่มีแค่ฝั่งเดียว (Figma ไม่ได้วาด) ยังเป็นคำถามเปิด จนกว่าจะตัดสิน — ตารางข้างล่างจึงใช้เป็นรายการเทียบ ไม่ใช่คำถามรอตอบ (ยกเว้นข้อที่ Figma ไม่มี)

| # | หัวข้อ | ClickUp | Figma | ต้องถาม |
|---|---|---|---|---|
| U1 | สี Zyra | parent `#79DEA5` · HP-01 "Indigo" | **`#58D68D`** (My calendar / Primary/500) | ยึด Figma ใช่ไหม |
| U2 | Google / Outlook | สี `#4285F4` / `#0078D4` ใน legend + chip | **ไม่มีเลย** · legend มี My calendar, Thai Holidays (`#2DB6FF`), Christian Holidays, American League All-Star Team | สีและตำแหน่งใน Calendar list ของ Google/Outlook |
| U3 | Banner ยังไม่ connect | "เชื่อมต่อ Google / Outlook เพื่อดู events ทั้งหมด" | อังกฤษ "Connect your calendar" + body + ปุ่ม "Go to setting" + X · อยู่ใน panel · โผล่วันละครั้งหลังปิด | ใช้ copy ไหน / ภาษาไทยใน `messages/th.json` |
| U4 | Month rows | 4–6 แถว | **6 แถวคงที่** | ยึด 6 แถว? |
| U5 | Chip | dot สี + ชื่อ | **bar 2×8** + bg tint 20% · มี variant outline ที่ไม่บอกความหมาย | outline = สถานะอะไร (ยังไม่ตอบรับ?) |
| U6 | "+X more" | "+X more" | **"2 More"** | copy |
| U7 | All-day บนสุดของ cell | ต้องมี | ไม่มีตัวอย่างที่ all-day อยู่ร่วม cell กับ timed | ยืนยันลำดับ |
| U8 | ช่วงเวลา Week/Day | 00:00–23:30 ทุก 30 นาที | วาด 08:00–18:00 + scrollbar · ไม่มี label ของ :30 | scroll ได้ทั้งวัน? เปิดมาที่เวลาไหน? |
| U9 | Day event block | ชื่อ + เวลาเริ่ม | ชื่อ + **start–end** + **location** (block ยาว) | ยึด Figma? |
| U10 | รูปแบบเวลา | — | Week "09:00–10:00" vs Day สั้น "10:15 - 10:20" vs popup "10:00 - 10:30" | format เดียว |
| U11 | Popup source badge | "Zyra Meeting" / "Google Calendar" / "Outlook" | **ไม่มี** — มีแค่ swatch 12px | ต้องเพิ่มไหม |
| U12 | Popup description | ต้องมี | **ไม่มี** ในทุก variant | ต้องเพิ่มไหม |
| U13 | Join | "Join Now" เฉพาะ `meeting_status = active` | **"Join"** · ไม่มี state inactive · external link ซ่อนด้วย opacity 0 | copy + พฤติกรรมเมื่อไม่ active |
| U14 | Link ไป Google/Outlook | "เปิดใน Google Calendar / Outlook" | **ไม่มี** · มีแค่ link meeting (Zyraworld.com / Googlemeet.com) + Copy | ต้องเพิ่มไหม |
| U15 | ปิด popup | ESC / click outside | มีแค่ X | ยืนยันพฤติกรรม |
| U16 | ของเกิน ClickUp | — | Trash / Edit ใน popup · RSVP footer Yes/No/Maybe + badge · X สีขาวใน variant 509 | อยู่ใน scope การ์ดนี้หรือการ์ดอื่น |
| U17 | Empty state | "ไม่มี events ในช่วงนี้" + ปุ่ม "สร้าง Meeting ใหม่" กลาง calendar | **ไม่มี** — grid เปล่า + Schedule event popover | ใช้แบบไหน |
| U18 | Error | banner "ไม่สามารถโหลด events ได้ — [ลองใหม่]" | **Toast** ขวาบน "Couldn't load calendar events" + "Try again" · skeleton ค้างด้านหลัง | ยึด toast? |
| U19 | Skeleton | "skeleton loading ก่อน" | มี · static (ไม่มี shimmer) | ใส่ shimmer ไหม |
| U20 | Mobile swipe (HP-03/04) | swipe ซ้าย/ขวา | ไม่มี frame mobile | มี design mobile ไหม |
| U21 | ชื่อ section EP-01 | — | `7759:120313` ชื่อ "CLDI-HP-03 : …" (ผิด) | แจ้ง designer แก้ชื่อ |
| U22 | Sample data ไม่ตรงกัน | — | popup 10:00 - 10:30 แต่ event ที่คลิกคือ 09:00–10:00 · Week title layer "20 July, 2026" แต่ render "July, 2026" · mini calendar June frame ยังเป็น July | ยืนยันค่าที่ถูก |

---

## 11. ยังไม่ได้ดึง

- Frame root bg · Side bar Idle state · Half view ไม่มี banner (`3898:778668`) spec รายตัว
- Hidden "Alert banner" 288×70 ใน panel (`I3898:778669;3290:702456;3898:775976`)
- สีจริงของ SVG: divider ใน popup, now-line ในลิสต์ upcoming, current-time dot
- Hover / pressed / focus / disabled ของทุกปุ่ม, chip, cell, input — ไม่มีใน design
- Overlap ≥ 3 events · event ข้ามคืน (EC-03) · all-day หลายอันใน cell เดียว · timezone ต่างกันใน popup (EC-04) · "Event ถูกแก้ไข — [Reload]" (EC-06) — ไม่มี frame
- Rule ตำแหน่ง popup เมื่อใกล้ขอบขวา/ล่าง
- Prototype interaction (trigger ของ Schedule event, toast auto-dismiss, animation)
- Thai copy ของ toast / banner / empty state
- Mobile layout ทุก view

Screenshot ที่ใช้อ้างอิงตอนดึงอยู่ใน scratchpad ของ session นี้ (ไม่ได้เก็บเข้า repo) — ถ้าต้องการ ให้ดึงใหม่ด้วย `get_screenshot` ตาม node ใน §0

---

## 12. ขอบจอบัง + กดแล้วหาย — checklist ตอนทำจริง (2026-10-29)

> ผู้ใช้สั่ง: "ตอนทำจริงเช็คดีๆ ว่า UI ส่วนไหนเปิดมาแล้วโดนขอบจอบัง … กดแล้วมันเด้งหายไป" · ใช้กับทั้ง 3 ฟีเจอร์ (CAL-01/02/03 ใช้ popup ชุดเดียวกัน)
> **ที่มา:** (1) วัดใน POC ด้วย script — เปิดทุก popup จากทุก event / ทุก cell / slot ขอบจอ แล้ววัดว่าโดนตัดกี่ px · คลิกทุกจุดที่ไม่ใช่ปุ่มใน 9 popup (~190 จุด) ดูว่าปิดเองไหม (2) อ่านโค้ด `zyra-app` origin/develop (`22fc0d6d`) ใน `views/user/virtual-office/components/calendar/` — **อ่านโค้ด ยังไม่ได้เปิดแอปจริงทดสอบ**
> Figma วาดที่จอ **1440×1024** — จอจริงของ user ส่วนใหญ่เตี้ยกว่า ทุกค่าตำแหน่งแบบตายตัวใน Figma จึงต้องแปลงเป็นกติกา "วัดแล้ววาง" ตอนทำจริง

### 12.1 ขนาดจอที่ต้องทดสอบ

| จอ | หมายเหตุ |
|---|---|
| 1280×720 · 1366×768 | laptop ทั่วไป — เตี้ยกว่า Figma ~300px · **ชิ้นที่สูงเกิน 700 โดนตัดแน่** |
| 1440×900 · 1536×864 | MacBook / Windows 125% |
| 1920×1080 | desktop |
| browser zoom 125% / 150% | = จอเล็กลง ต้องผ่านเหมือนกัน |

ทุกขนาด × Day / Week / Month × panel half / full

### 12.2 Popup ทุกตัว — เสี่ยงโดนขอบตรงไหน + กติกาที่ต้องทำ

| ชิ้น | ขนาด | เสี่ยงโดนขอบเมื่อ | กติกา (ต้องทำ) | โค้ด develop ตอนนี้ | POC |
|---|---|---|---|---|---|
| **Event detail** (§8) | 340 × 387–657 (สูงตาม guest / description / RSVP footer) | event อยู่คอลัมน์ขวาสุด (เสาร์) · event ช่วงดึก / grid scroll ลงล่าง · จอ 720 กับ popup 657 | วางข้าง event: ขวาก่อน ไม่พอไปซ้าย · ล่างไม่พอ → ชิดล่างแล้วดันขึ้น · สูงเกินจอ → `max-height: 100vh − 32` + scroll ข้างใน · **วัดหลัง icon / font render เสร็จ** | ไม่ได้วางข้าง event — ตรึง `bottom-8 left-344` + max-h + scroll ([vo-calendar.tsx:395](../../../zyra-app/views/user/virtual-office/components/calendar/vo-calendar.tsx)) → ไม่โดนขอบ แต่**อาจบัง event ที่กด** และไม่ตรง Figma | ✔ เคยเกินล่าง 1px (event `maint` week view) เพราะวัดก่อน icon render → แก้แล้ว |
| **"+N more"** (Month) | 167 × ตามจำนวน | cell แถวล่าง / คอลัมน์ขวา | ล่างไม่พอ → เปิดขึ้นจากขอบล่างของ cell | **ยังไม่มี popover** — เป็น `<p>` กดไม่ได้ (calendar-main-view.tsx:390-394) | ✔ |
| **Schedule event form** (CAL-01 §6) | 340 × **711 ตอนว่าง → ~790–1000** เมื่อมี guest + เปิด Permission (+~53px/คน, +~90 permission) | **จอ ≤ 768 ทุกกรณี** · slot ช่วงล่าง | ห้ามใช้ความสูงคงที่ — วัดจริงหลัง render และทุกครั้งที่เนื้อหาเปลี่ยน · `max-height: 100vh − 32` · header (ชื่อ + X) กับปุ่ม Create **ติดอยู่ (sticky)** ส่วนกลาง scroll · ตามตำแหน่ง slot เมื่อ grid scroll / resize | **บั๊ก** `besideSlot()` คำนวณ top จาก `SCHEDULE_HEIGHT = 711` ตายตัว (vo-calendar.tsx:46, 86-90) → ฟอร์มที่สูงเกิน 711 ล้นล่าง **ปุ่ม Create หลุดจอ** (จอ 1000 + slot ล่าง: top 273 + ฟอร์ม 900 = 1173) · ตำแหน่งเก็บ DOMRect ตอนคลิก ไม่ตาม scroll (vo-calendar.tsx:131) | ✔ clamp ด้วยความสูงจริง |
| **Date picker** | 311 × ~290 | ฟอร์มอยู่ต่ำ | ไม่พอข้างล่าง → เปิดขึ้น · ไม่พอทั้งคู่ → จำกัดสูง + scroll · **ต้องไม่ถูก overflow ของฟอร์มตัด** → render ผ่าน portal (fixed) หรือให้ฟอร์ม overflow visible | `absolute top-[50px]` อยู่ใน dialog ที่ `overflow-y-auto` (calendar-schedule-event.tsx:239, 288-297) → **ถูกขอบฟอร์มตัด** ไม่มี max-height | ✔ flip / cap |
| **Start / End time** | 146 × 226 | เหมือน date | เหมือน date + scroll ไปเวลาที่เลือก | sched:36-37, 608-609 — เปิดลงอย่างเดียว ถูกฟอร์มตัด | ✔ |
| **Location / room** | เต็มช่อง × 284 (develop) / 226 (POC) | เหมือน date | เหมือน date | sched:346-347 — เหมือนกัน | ✔ |
| **Guest search** | เต็มช่อง × 321 | **เสี่ยงสุด** — อยู่ต่ำสุดในฟอร์ม | เหมือน date · flip ขึ้นแล้วสูงไม่เกิน 321 | sched:405 — เปิดลงอย่างเดียว · ฟอร์มว่าง (≈728) dropdown ไปถึง y≈825 → **ล่าง ~100px ถูกตัด** ต้อง scroll ฟอร์มหา | ✔ เดิมล้นล่าง **59px** (week 23:00 / day view) → flip ขึ้น เหลือ 0 |
| **Tooltip** (Figma: กล่อง `#1A1B1E` 12/15 p8 r8 ใต้ไอคอน) | กว้างตามข้อความ — ไทยยาวสุด "แก้ไขได้ที่ Google Calendar เท่านั้น — กดเพื่อเปิด" ≈ 270px | ไอคอนมุมขวาของ popup ที่ชิดขอบจอขวา · ไอคอนใน Settings modal (`overflow: hidden`) · ไอคอนแถวล่างสุด | เกินขวา → ชิดขวาของไอคอน · เกินซ้าย → ชิดซ้าย · ล่างไม่พอ → เปิดขึ้น · render ผ่าน portal เพื่อไม่ให้ `overflow: hidden` ตัด | ใช้ `title` ของ browser (calendar-parts.tsx:193) → ไม่โดนตัด แต่**ไม่ตรง Figma** — ตอนเปลี่ยนเป็นแบบ Figma ต้องทำกติกานี้ | ✔ เดิม tooltip ไปถึง x=1437 จาก 1440 → ชิดขวาแล้ว |
| **Setting modal** (CAL-01 §3.1) | **934 × 800** (Figma วางกลางจอ 1024 พอดี) | **จอสูง < 832** (1366×768, 1280×720) ขอบล่างหาย · จอกว้าง < 966 | จัดกลางจอ · `max-height: 100vh − 32` เนื้อหาฝั่งขวา scroll · กว้าง `min(934, 100vw − 32)` | ยังไม่ได้ตรวจในรอบนี้ | ตำแหน่งตายตัว (stage 1440×1024 เท่านั้น) |
| **Choose calendars to sync** (CAL-01 §3.5) | 458 × ~560 | จอ 720 ถ้าวางที่ top 200 แบบ POC | จัดกลางจอ · list `max-height` = ที่เหลือ | ยังไม่มี | ตำแหน่งตายตัว |
| **Cancel meeting modal** (CAL-01 §8.3) | 455 × 509 | Figma วาง top 258 → ก้นที่ 767 = เกินจอ 720 | จัดกลางจอ + max-height + scroll | ยังไม่มี | ตำแหน่งตายตัว |
| **Discard / Disconnect confirm** | 458 × 170 / 206 | ไม่เสี่ยงเรื่องขนาด แต่**อาจโดน UI อื่นทับ** | render ผ่าน portal ที่ `body` | **บั๊ก** discard modal `z-[10000]` แต่อยู่ใน HUD layer `absolute z-10` (sched:522 · hero-virtual-office.tsx:15146) → widget บนแผนที่ z-20–40 วาดทับ scrim / modal ได้ | — |
| **Toast** (Meeting Alert) | 336 × 142–166 ต่อใบ ซ้อนลง | หลาย meeting เตือนพร้อมกัน (5 นาทีก่อน + เริ่ม) บนจอ 720 | แสดงพร้อมกันไม่เกิน 3 ใบที่จอ < 800 (4 ใบที่จอสูงกว่า) ที่เหลือเข้าคิว · toast ที่ไม่หายเอง (sticky) ต้องปิดได้ | Sonner `top-right` (app/layout.tsx:233) — default แสดง 3 ใบ ✔ · push-failed toast `duration: Infinity` (vo-calendar.tsx:198-202) | ✔ สูงสุด 4 ใบ = 664px |
| Calendar panel lists / Notification panel | 320 × เต็มความสูง | ปฏิทินหลายอัน (หลังเลือก > 10 ใน §3.5) · upcoming ยาว | scroll ใน panel | — | ✔ scroll |

### 12.3 "กดแล้วหาย" — กติกาการปิด popup

| # | กติกา | develop ตอนนี้ | POC |
|---|---|---|---|
| C1 | ปิดเมื่อคลิก**นอก** popup เท่านั้น — เช็ค `pointerdown` + `ref.contains(target)` **ก่อน** state เปลี่ยน / re-render (ถ้าเช็คตอน `click` หลัง re-render, node ที่กดถูกถอดออกแล้ว → ถูกนับเป็น "นอก" → popup หาย) | ✔ ใช้ `mousedown` + `closest("[data-schedule-menu]")` (sched:149-160) | ✔ คลิก ~190 จุดที่ไม่ใช่ปุ่ม ไม่มีจุดไหนปิดเอง |
| C2 | ถ้า dropdown / tooltip ย้ายไป **portal** (ตามข้อ 12.2) ต้องนับ portal เป็น "ข้างใน" ด้วย — ไม่งั้นคลิกใน dropdown = ปิดทันที | ยังไม่มี portal | — |
| C3 | กด / ลาก **scrollbar** ของฟอร์มต้องไม่ปิด dropdown | **บั๊ก** mousedown บน scrollbar ของ dialog ไม่อยู่ใน `[data-schedule-menu]` → ปิดเมนู (sched:151-156) — พอดีกับบั๊ก guest dropdown ถูกตัด: user จะ scroll ไปหา แล้วมันหาย | ใช้ `click` ไม่โดน |
| C4 | Guest dropdown ต้องเปิดใหม่ได้ด้วยการคลิกช่อง (ไม่ใช่แค่ focus) | **บั๊ก** เปิดเฉพาะ `onFocus` / พิมพ์ (sched:399-403) → ถูกปิดขณะ input ยัง focus อยู่ คลิกซ้ำไม่เปิด ต้องพิมพ์ | ✔ คลิก `.gin` เปิด |
| C5 | มี draft อยู่แล้วคลิก slot อื่น / chip / ปุ่ม + / ปิด calendar → **ต้องถาม Discard ก่อน** (Figma `3613:202062`) ไม่ทิ้งเงียบ | **บั๊ก** remount ฟอร์มด้วย `key` (vo-calendar.tsx:367, 427) ข้าม discard confirm · draft chip `pointer-events-none` (calendar-parts.tsx:236) คลิกโดน slot ข้างใต้ · ปิด calendar จากข้างนอกทิ้ง draft (hero-virtual-office.tsx:6582-6585) | ปิดฟอร์มก่อน แล้วค่อยคลิกครั้งถัดไป |
| C6 | **Escape** ปิดชั้นบนสุดทีละชั้น: dropdown → ฟอร์ม / detail (ฟอร์มมีข้อมูล = ถาม Discard) → modal | **ไม่มีเลย** (ไม่มี keydown handler ใน calendar) | ✔ |
| C7 | grid scroll / resize window → popup ที่ผูกกับ event / slot ต้องย้ายตาม หรือปิด | เก็บ DOMRect ตอนคลิก ไม่ย้าย | ✔ วางใหม่ตอน resize |
| C8 | checkbox ใช้ `button role="checkbox"` ไม่ใช่ `label + input` (label ยิง click 2 ครั้ง → toggle แล้ว toggle กลับ / ถูกนับเป็นคลิกนอก) | ✔ (calendar-parts.tsx:60-66) | ✔ |
| — | ปิดโดยตั้งใจ (ไม่ใช่บั๊ก): Cancel meeting → เปิด modal · Edit → เปิดฟอร์ม · Join · X · Cancel / Save | — | ✔ |

### 12.4 วิธีเช็คตอนทำจริง (ก่อนส่ง QA)

1. ทุกจอใน §12.1 × Day / Week / Month × half / full
2. เปิด Event detail จาก: คอลัมน์ขวาสุด · 23:00 (scroll grid ล่างสุด) · แถวล่างของ Month · event ใน "+N more" · Upcoming list · Notification panel
3. เปิด Schedule event จาก slot มุมขวาล่าง แล้ว: เพิ่ม guest 5+ คน · เปิด Permission · เปิด Date / Time / Location / Guest ทีละตัว → ปุ่ม Create ต้องเห็นเสมอ, dropdown ต้องไม่ถูกตัด
4. Hover ทุก tooltip ตอน popup อยู่ชิดขอบขวา และใน Setting modal
5. คลิกในทุก popup: ช่องว่าง · ข้อความ · scrollbar (ลาก) · label · ปุ่ม X ของ guest pill · เดือนก่อน / ถัดไปใน date picker · scroll list เวลา → **ต้องไม่ปิด**
6. Escape ทีละครั้ง · คลิก slot อื่นตอนมี draft (ต้องถาม Discard) · scroll grid ตอน popup เปิด
7. Meeting Alert: ยิงหลาย alert พร้อมกันบนจอ 720 → toast ไม่ล้นล่าง ปิดได้ทุกใบ

### 12.5 ผลใน POC (ก่อน / หลังแก้ 2026-10-29 — วัดใน stage 1440×1024)

| จุด | ก่อน | หลัง |
|---|---|---|
| Guest dropdown ตอนฟอร์มอยู่ต่ำ (week 23:00, day view) | ล้นล่าง 59 px | 0 px (เปิดขึ้น สูง 321 เท่าเดิม) |
| Event detail `maint` (week, ล่างสุด) | ล้นล่าง 1 px (วัดก่อน icon render) | 0 px (ก้นที่ 1007 / ขอบ 1008) |
| Tooltip "แก้ไขได้ที่ Google Calendar …" ตอน popup ชิดขวา | ขอบขวา x=1437 จาก 1440 — popup ขยับขวาอีกนิด = ถูกตัด | ชิดขวาของไอคอน อยู่ในจอ |
| คลิกจุดที่ไม่ใช่ปุ่มใน 9 popup (~190 จุด) | — | ไม่มีจุดไหนปิดเอง |

POC เป็น stage 1440×1024 ตายตัว — **ทดสอบจอเล็ก (§12.1) ใน POC ไม่ได้** ต้องเช็คในแอปจริง
