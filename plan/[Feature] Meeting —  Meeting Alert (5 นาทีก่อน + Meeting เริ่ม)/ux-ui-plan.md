# SC-MTG-CAL-03 · Meeting Alert — UX/UI Plan (from Figma)

> **สถานะ (2026-10-27):** ดึงจาก Figma ครบ 6 section (MA-EP-03 ไม่มี Figma) · ยังไม่ implement · ยังไม่ได้ review กับ Design/PM
> **ขอบจอบัง / กดแล้วหาย:** toast ซ้อนหลายใบ + Notification panel อยู่ใน checklist [Calendar Display ux-ui-plan §12](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md#12-ขอบจอบัง--กดแล้วหาย--checklist-ตอนทำจริง-2026-10-29>)
> **Figma file:** [Zyra design (More Organised ver.)](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-) (`Map8gX0L2hk7HnkaFRfhtj`) · ดึงผ่าน Figma MCP · ไม่ได้ download asset
> **กติกา:** ตัวเลขทุกตัวมาจาก Figma MCP เท่านั้น ([10-figma-fidelity](../../../.claude/rules/10-figma-fidelity.md)) · ค่าที่อ่านจาก screenshot อย่างเดียวระบุ **[screenshot]** · ช่องที่ดึงไม่ได้เขียน **"ยังไม่ได้ดึง"**
> **flow / business rule อยู่ที่ [spec.md](spec.md)** · token สี/ตัวอักษร, Event detail popup และ Calendar view ใช้ชุดเดียวกับ [Calendar Display ux-ui-plan](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md>) (อ้าง § ในไฟล์นั้นแทนการคัดลอกซ้ำ)
> **ไม่มี sticky note ใน 6 section นี้เลย** — timing (ค้าง 3 นาที), การซ้อนของหลาย toast, animation ไม่มีใน Figma
> **ข้อสังเกตสำคัญ:** Figma ต่างจาก ClickUp หลายจุด (icon, copy อังกฤษคนละโครง, ไม่มีจำนวนคนในห้อง, มีปุ่ม Later เพิ่ม, past ไม่ greyed, bundle อยู่ใน toast) → ดู [§7](#7-figma-vs-clickup--ข้อขัดแย้งที่ต้องถาม)

---

## 0. Section / frame inventory

ทุก frame 1440×1024

### MA-HP-01 · Alert 5 นาทีก่อน Meeting — section `7764:170718`

| # | Node | แสดงอะไร |
|---|---|---|
| 1 | `7764:254070` Idle UI | VO ปกติ ไม่มี toast |
| 2 | `7764:255397` Calendar - Alert | VO + **Toast `7766:255425`** "Meeting starts in 5 minutes" |
| 3 | `7766:257062` Calendar - Alert | กด "Open Calendar" → Calendar Week view + **Event detail `7766:257063`** (x 744 y 314, 340×453) |
| 4 | `7766:257170` Idle UI | หลัง toast หาย — bell **ไม่มี badge**, chat badge "1" |
| 5 | `7766:462833` Calendar - Notification | Notification panel — การ์ดบนสุด "Meeting starts in 5 min…" |

### MA-HP-02 · Alert ตอน Meeting เริ่ม — section `7766:463132`

| # | Node | แสดงอะไร |
|---|---|---|
| 1 | `7766:463134` Idle UI | VO ปกติ |
| 2 | `7766:464667` Calendar - Alert | VO + **Toast `7766:464669`** "Meeting has started" + ปุ่ม Later / Join meeting |
| 3 | `7767:465812` Multiple Room - Go to meeting room | avatar ผู้ใช้อยู่ที่ประตู meeting hall ในห้องมีคนรอ 6 คน **[screenshot]** |
| 4 | `7767:465826` Multiple Room - Go to meeting room | อยู่ในห้องแล้ว: Display panel `7767:465829` (x 80 y 24, 1336×208) หัว "Meeting room 1" + 6 tiles · label บนแมพ "Meeting hall 01" **[screenshot]** |
| 5 | `7766:463135` Idle UI | VO ปกติ — bell ไม่มี badge |
| 6 | `7766:464886` Calendar - Notification | Notification panel — การ์ดบนสุด "Meeting has started" + Join |

### MA-HP-03 · Notification History — section `7767:466425`

| # | Node | แสดงอะไร |
|---|---|---|
| 1 | `7767:466450` Idle UI | VO ปกติ · bell ไม่มี badge |
| 2 | `7767:466451` Calendar - Notification | เปิด panel (bell active) · item แรกมีปุ่ม Join |
| 3 | `7767:469343` Multiple Room | กด Join → avatar ไปที่ meeting hall · panel ปิด |
| 4 | `7767:469357` Multiple Room | อยู่ในห้อง (Display panel "Meeting room 1" 6 คน) |
| 5 | `7767:468590` Calendar - Alert | **คลิก past item** → Calendar Week view วันนั้น + Event detail `7776:234258` ("Catch up Zyra project") |

### MA-HP-04 · User ปิด Alert (Dismiss) — section `7767:469956`

| # | Node | แสดงอะไร |
|---|---|---|
| 1 | `7767:469958` Idle UI | VO ปกติ |
| 2 | `7767:469959` Calendar - Alert | VO + **Toast `7767:469961`** (เหมือน HP-02 ทุกค่า) |
| 3 | `7767:469981` Idle UI | **หลัง dismiss:** toast หาย · **bell มี badge "1"** (frame เดียวใน HP-01/02/04 ที่ bell มี badge) |
| 4 | `7767:469982` Calendar - Notification | panel ยังมีการ์ด "Meeting has started" + Join → notification ยังอยู่ใน history |

### MA-EP-01 · User ไม่ Online เมื่อ Alert ถูกส่ง — section `7771:8157`

| # | Node | แสดงอะไร |
|---|---|---|
| 1 | `7771:8159` Idle UI | Idle (ดูแค่ thumbnail) |
| 2 | `7771:8160` Calendar - Alert | VO + **Toast `7771:197201`** "You missed 3 meetings" |
| 3 | `7771:197418` Calendar - Alert | กด "View Calendar" → Calendar Week + Event detail `7771:197420` |
| 4 | `7771:8163` Idle UI | **bell badge "3"**, chat badge "3" |
| 5 | `7771:23821` Calendar - Notification | panel → **3 การ์ด "Meeting has started" แยกกัน** (ไม่ bundle ใน panel) |

### MA-EP-02 · Meeting ถูกยกเลิก / เลื่อนเวลา — section `7771:198052`

| Sub-flow | # | Node | แสดงอะไร |
|---|---|---|---|
| Event ถูกยกเลิก (`7771:199607`) | 1 | `7771:198054` Idle UI | Idle |
| | 2 | `7771:198055` Calendar - Alert | VO + **Toast `7771:198057`** "…has been cancelled" |
| | 3 | `7771:198059` Calendar - Alert | Calendar + Event detail `7776:234357` · block "Daily standup meeting" เป็น**สีเทา** (สีจริง **ยังไม่ได้ดึง**) |
| | 4 | `7771:198058` Idle UI | bell badge "1", chat badge "1" |
| | 5 | `7771:199610` Calendar - Notification | panel · การ์ดแรก "Meeting cancelled" (icon เทา) |
| Event เลื่อนเวลา (`7771:199906`) | 1 | `7771:199908` Idle UI | Idle |
| | 2 | `7771:199909` Calendar - Alert | VO + **Toast `7771:199911`** "…has been rescheduled" |
| | 3 | `7771:201442` Calendar - Alert | Calendar + Event detail `7776:234456` (ภาพเหมือน EP-01 #3 — ไม่เห็น block ย้ายเวลา) |
| | 4 | `7771:199912` Idle UI | **ยังไม่ได้ดึง** |
| | 5 | `7771:199916` Calendar - Notification | panel · การ์ดแรก "Meeting rescheduled" (icon ส้ม) |

---

## 1. Tokens เพิ่มเติม (นอกเหนือจาก [Calendar Display §1](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md#1-design-tokens-get_variable_defs-บน-499856263--ที่พบใน-frame-อื่น>))

| Token | Hex | ใช้ที่ |
|---|---|---|
| Shade Black/500 | `#1A1B1E` | toast bg, text ปุ่มขาว |
| Blue/20% | `rgba(45,182,255,0.2)` | icon box toast 5 นาที / missed |
| Orange/500 | `#FF8000` | icon rescheduled |
| Orange/10% | `rgba(255,128,0,0.1)` | icon box toast rescheduled |
| — | `rgba(255,255,255,0.1)` | icon box toast cancelled |
| — | `#7EA2FC` | icon circle "New update" (system — ไม่ใช่ meeting) |
| Red/500 (badge) | `#D41818` | sidebar count badge (ต่างจาก Red/500 `#F03A3A` ของ current-time line — ชื่อ token ซ้ำ ต้องเช็ค) |

---

## 2. Meeting Alert Toast (HP-01 / HP-02 / HP-04 / EP-01 / EP-02)

ทุกอันเป็น **Toast component ตัวเดียวกับ error toast ของ Calendar** (`7761:168158` — [Calendar Display §9.3](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md#93-error-toast-7761168158-ใน-7759167460>)) · instance children `I<node>;5444:…` ชุดเดียวกัน · ต่างแค่ icon สี / copy / ปุ่ม / ตำแหน่ง

### 2.1 Container

| Prop | Value |
|---|---|
| Size | w **336** · h hug content: **142** (body 2 บรรทัด) / **160** (cancel, reschedule) · error toast เดิม = 124 |
| Position | **top 24 / right 24** (x 1080 y 24 ใน 1440) — ⚠️ error toast ของ Calendar อยู่ top 16 / right 16 |
| bg | `#1A1B1E` |
| Radius / padding / gap | 16 / 16 / 16 · flex-col, items-start, justify-center |
| Shadow | `0 4px 8px rgba(255,255,255,0.08)` |
| Border | ไม่มี |

### 2.2 Top row (`;5444:310194`) — flex-row gap 16 items-start

| Part | Value |
|---|---|
| Icon box `;5444:310195` | w 40, p 8, radius 8 (40×40) · bg ตามประเภท (2.4) |
| Icon `;5444:310196` | **Video on (กล้อง)** 24×24 — layer ชื่อ "Check" แต่ asset เป็นกล้อง → lucide `Video` · สีตามประเภท |
| Text column `;5444:310198` | flex-1, flex-col gap 8, 14/18 white, word-break |
| Title `;5444:310199` | Inter **Bold** 14/18 white |
| Body `;5444:310200` | Inter Regular 14/18 white, 2 บรรทัด |
| Close X `;5444:310201` | icon Cancel 16×16 สีขาว **[screenshot]**, align top |

### 2.3 Button row (`;5444:314695`) — flex-row gap 8, justify-end, w-full

| ปุ่ม | bg | text | h | px / py | radius |
|---|---|---|---|---|---|
| Primary `;5444:314691` | `#58D68D` | Inter Regular 14/18 white | 32 | 16 / 8 | 6 |
| Secondary `;5444:314686` (HP-02/04 เท่านั้น) | `#FFFFFF` | Inter Regular 14/18 `#1A1B1E` | 32 | 16 / 8 | 6 |

### 2.4 Variants (copy verbatim)

| ประเภท | Node | Icon box bg | Icon สี | Title | Body | ปุ่ม |
|---|---|---|---|---|---|---|
| 5 นาทีก่อน (HP-01) | `7766:255425` | `rgba(45,182,255,0.2)` | `#2DB6FF` | "Meeting starts in 5 minutes" (meeting จะเริ่มในอีก 5 นาที) | "Daily standup meeting" / "10:00 · Design Room" | "Open Calendar" (เปิด Calendar) |
| เริ่มแล้ว (HP-02, HP-04) | `7766:464669`, `7767:469961` | `rgba(88,214,141,0.2)` | `#58D68D` | "Meeting has started" (meeting เริ่มแล้ว) | "Daily standup meeting" / "10:00 · Design Room" | "Later" (ไว้ทีหลัง) · "Join meeting" (เข้าร่วม meeting) |
| พลาดหลายอัน (EP-01) | `7771:197201` | `rgba(45,182,255,0.2)` | `#2DB6FF` | "You missed 3 meetings" (คุณพลาด 3 meeting) | "You were offline when these meetings took place." (คุณ offline อยู่ตอนที่ meeting เหล่านี้เกิดขึ้น) | "View Calendar" (ดู Calendar) |
| ยกเลิก (EP-02) | `7771:198057` | `rgba(255,255,255,0.1)` | `#8C99A6` | "Daily standup meeting has been cancelled" (Daily standup meeting ถูกยกเลิกแล้ว) | "Previously scheduled for 20 July, 2026 at 10:00 - 10:30" (เดิมนัดไว้ 20 July, 2026 เวลา 10:00 - 10:30) | "View Calendar" |
| เลื่อนเวลา (EP-02) | `7771:199911` | `rgba(255,128,0,0.1)` | `#FF8000` | "Daily standup meeting has been rescheduled" (Daily standup meeting ถูกเลื่อนเวลาแล้ว) | "New time: 20 July, 2026 at 09:00 – 10:00" (เวลาใหม่: …) | "View Calendar" |

- ไม่มี countdown · ไม่มีจำนวนคนในห้อง · ไม่มี progress bar ในทุก variant
- toast แสดงเวลาเริ่มอย่างเดียว ("10:00") แต่การ์ดใน panel แสดงช่วง ("10:00-10:30")
- Stacking หลาย toast / enter-exit animation / ระยะเวลาค้าง: **ไม่มีใน Figma**
- Hover / pressed ของปุ่มและ X: **ไม่มีใน Figma**

### 2.5 ผลของการกดปุ่ม (ตาม frame)

| ปุ่ม | ผล |
|---|---|
| "Open Calendar" / "View Calendar" | Calendar **Week** view + เปิด Event detail popup ของ meeting นั้น (x 744 y 314) — popup เดียวกับ [Calendar Display §8](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md#8-event-detail-popup-hp-05--base-775642824>) |
| "Join meeting" | avatar ไปที่ meeting hall แล้วเข้าห้อง (Display panel "Meeting room 1") — ไม่ชัดว่า teleport หรือเดินไป |
| "Later" | **ไม่มี frame แสดง** |
| X | toast หาย · notification ยังอยู่ใน panel · bell ขึ้น badge "1" (HP-04 #3) |

---

## 3. Sidebar bell + badge

ข้อมูลจาก `I7767:469981;5:868` (Side bar - Dark)

| Prop | Value |
|---|---|
| Sidebar | w 72, bg `#242B32`, p 16, menu gap 16 · ลำดับ Map, Member, Chat, Calendar, **Bell (Notifications)** `;5:403`, Megaphone |
| Menu item | w 40, p 8, radius 8, icon 24 |
| Active (panel เปิด) | bg `rgba(88,214,141,0.1)`, icon `#58D68D` |
| Badge "Count number" `;5:403;5:510` | absolute **top −4 / right −4**, bg `#D41818`, radius 90, p 1 |
| Badge text | Inter Medium 10 / lh 14, white, center, w 16 (badge ≈ 18×16) |

พฤติกรรม badge ใน design:

| Frame | Bell badge |
|---|---|
| ตอน toast ของ HP-01 / HP-02 โผล่ + idle หลังจากนั้น | **ไม่มี** (มี badge "1" ที่ Chat แทน) |
| HP-04 หลัง dismiss | "1" |
| EP-01 idle | "3" |
| EP-02 cancel idle | "1" |
| ตอน panel เปิด | ไม่มี (สอดคล้องกับ "badge = 0 เมื่อเปิด panel") |

---

## 4. Notification panel (HP-03) — `I7767:466451;7766:462503`

### 4.1 Layout

| Prop | Value |
|---|---|
| ตำแหน่ง | x 72 y 16, **320×992** — **ดันแมพไปขวา** (map x 408, 1016×992) ไม่ได้ overlay · gap 16 |
| Container | bg `#2B3540`, radius 16, p 16, flex-col gap 16, overflow clip · ไม่มี shadow / border |
| Scroll | ไม่มีใน design (content สั้นกว่า panel) |

### 4.2 Header `…;130:65387`

| Element | Value |
|---|---|
| Row | flex, items-center, justify-between |
| Title | "Notification" (การแจ้งเตือน) — Title/Bold 20/25 white |
| Action | flex gap 8 · icon "read" (double check) 12×12 + **"Mark as read"** (ทำเครื่องหมายว่าอ่านแล้ว) Caption 1/Regular 12/15 `#8C99A6` — เป็น text link ไม่ใช่ปุ่มทึบ |

### 4.3 Tabs `…;48:3590`

| Element | Value |
|---|---|
| Container | border 1px `rgba(255,255,255,0.2)`, radius 8, p 4, w-full |
| Tab | flex-1, h 32, p 8, gap 8, center · Body/Regular 14/18 white |
| Active | bg `rgba(88,214,141,0.2)` radius 8 · **"View all"** (ทั้งหมด) |
| Inactive | ไม่มี bg · **"Unread"** (ยังไม่อ่าน) |
| สถานะ tab Unread ถูกเลือก | **ไม่มีใน design** |

### 4.4 Date group `…;48:3284` / `…;48:3291`

| Element | Value |
|---|---|
| Group | flex-col gap 16 (หัว ↔ list) |
| Heading | "Today" (วันนี้) / "Yesterday" (เมื่อวาน) — Caption 1/Regular 12/15 **white** |
| List | flex-col gap **8** · ไม่มี divider |
| กลุ่มเก่ากว่า Yesterday | **ไม่มีใน design** |

### 4.5 Notification card (meeting) `…;2081:39816`

| Element | Value |
|---|---|
| Card | p 8, radius 8, flex items-center, w-full |
| Card bg (highlight) | `rgba(255,255,255,0.05)` — บางการ์ดมี บางการ์ดไม่มี (ตีความว่า unread — **design ไม่ระบุ**) · ไม่มี unread dot |
| Inner `…;48:4467` | flex-row gap 8, items-start |
| Icon circle `…;2081:39693` | 32×32, radius 90, p 4 · icon กล้อง inset 20% สีขาว · bg ตามประเภท (4.6) |
| Text column `…;48:4470` | flex-1, flex-col gap 8, **items-end** (ปุ่ม Join ชิดขวา) |
| Title row | flex gap 8 · title Body/Medium 14/18 white flex-1 · time Regular 12/16 `#8C99A6` nowrap ellipsis |
| Body `…;48:4474` | Body/Regular 14/18 `#8C99A6` 2 บรรทัด: `<ชื่อ meeting>` / `<HH:MM-HH:MM> · <ห้อง>` |
| Join `…;5557:1042537` | bg `#58D68D`, h 24, px 8, py 6, radius 4, gap 4 · **"Join"** Body/Regular 14/18 white |

### 4.6 ประเภทการ์ด

| ประเภท | Title | Icon circle bg | Body บรรทัด 2 | ปุ่ม |
|---|---|---|---|---|
| 5 นาทีก่อน | "Meeting starts in 5 min…" (truncate) | ฟ้า (สีจริง **ยังไม่ได้ดึง** — [screenshot]) | "10:00-10:30 · Design Room" | ไม่มี |
| เริ่มแล้ว — ยังไม่จบ | "Meeting has started" | `#58D68D` | "10:00-10:30 · Design Room" | **Join** |
| เริ่มแล้ว — ผ่านไปแล้ว | "Meeting has started" | `#58D68D` | "09:00-09:30 · Design Room" | ไม่มี (สีอื่น**เหมือน active ทุกอย่าง** ไม่ greyed) |
| ยกเลิก | "Meeting cancelled" (meeting ถูกยกเลิก) | `#8C99A6` | "Previously scheduled for 20 July, 2026 at 10:00 - 10:30" | ไม่มี |
| เลื่อนเวลา | "Meeting rescheduled" (meeting ถูกเลื่อนเวลา) | `#FF8000` | "New time: 20 July, 2026 at 09:00 – 10:00" | ไม่มี |
| (ไม่ใช่ meeting) New update | "New update" | `#7EA2FC` + bell icon | — | — |
| (ไม่ใช่ meeting) Social | ชื่อคน | avatar 32 + status dot | — | — |

Relative time ใน design ไม่ consistent: "1 min ago", "30 min ago" vs "30 mins ago", "1 hours ago", "2 hours ago" (1 นาทีที่แล้ว / 30 นาทีที่แล้ว / 1 ชั่วโมงที่แล้ว …) — ต้องตกลง format

### 4.7 Click behaviour (ตาม frame)

| Action | ผล |
|---|---|
| คลิก bell | panel เปิด · bell active · badge หาย |
| กด "Join" บนการ์ด | panel ปิด · avatar ไป meeting hall → เข้าห้อง |
| คลิกการ์ดที่ผ่านไปแล้ว | Calendar **Week** view วันนั้น + Event detail ของ meeting |
| "Mark as read" / tab "Unread" | **ไม่มี frame แสดง** |

### 4.8 Empty / loading / hover

ไม่มีใน design ทั้งหมด

---

## 5. ผลต่อ Calendar (ปลายทาง)

- ใช้ Calendar Week view + Event detail popup ตาม [Calendar Display §6 / §8](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md>) — ไม่มี component ใหม่
- EP-02 cancel: **Figma ล่าสุด (ตรวจ 2026-10-29)** — meeting ที่ถูกยกเลิก**ยังแสดง**ใน calendar ของ attendee: block bg `rgba(255,255,255,0.1)` · แถบ `#8C99A6` · ขีดฆ่า 1px `#F03A3A` ทับชื่อและเวลา · Event detail `7841:319230` มีแค่ Close + "Reason for cancellation" (ค่าเต็มดู [CAL-01 ux-ui-plan §8.5](<../[Feature] Meeting — Calendar Integration/ux-ui-plan.md>)) · ⚠️ วันที่ 2026-10-27 เคยเห็นเป็น `opacity-0` (ซ่อน) — designer แก้กลับแล้ว · ฝั่งผู้ยกเลิก event หายจากจอ (CAL-01 HP-05 แถว 1)
- EP-02 reschedule: ภาพเหมือนกรณีปกติ — ไม่เห็น block ย้ายเวลา

---

## 6. Display panel ในห้อง (HP-02 / HP-03 หลัง Join)

`7767:465829` — x 80 y 24, 1336×208 · หัว "Meeting room 1" · ไอคอนคน "6" · video tiles 6 คน · control bar มีปุ่ม share screen / record / emoji / raise hand **[screenshot]** — เป็น UI เดิมของ VO meeting ไม่ใช่ของฟีเจอร์นี้ · spec รายละเอียด **ยังไม่ได้ดึง**

---

## 7. Figma vs ClickUp — ข้อขัดแย้งที่ต้องถาม

> **กติกากลาง 3 ฟีเจอร์ (ผู้ใช้ตัดสิน 2026-10-29):** Figma กับ ClickUp ขัดกัน → **ยึด Figma** ยกเว้นข้อที่ผู้ใช้ตัดสินเป็นอย่างอื่น (ดู [CAL-01 spec §6.1](<../[Feature] Meeting — Calendar Integration/spec.md>)) · ข้อที่มีแค่ฝั่งเดียว (Figma ไม่ได้วาด) ยังเป็นคำถามเปิด จนกว่าจะตัดสิน — ตารางข้างล่างจึงใช้เป็นรายการเทียบ ไม่ใช่คำถามรอตอบ (ยกเว้นข้อที่ Figma ไม่มี)

| # | หัวข้อ | ClickUp | Figma | ต้องถาม |
|---|---|---|---|---|
| A1 | Icon | HP-01 🔔 · HP-02 🎙 · EP-02 🔄 | **กล้อง (Video)** ทุกประเภท แยกด้วยสี (ฟ้า / เขียว / เทา / ส้ม) | ยึด Figma? |
| A2 | Title toast | "[ชื่อ meeting] เริ่มในอีก 5 นาที" / "[ชื่อ meeting] เริ่มแล้ว!" | title คงที่ภาษาอังกฤษ "Meeting starts in 5 minutes" / "Meeting has started" · ชื่อ meeting อยู่ใน body | โครงสร้าง + คำแปลไทยใน `messages/th.json` |
| A3 | จำนวนคนในห้อง (HP-02) | "มี 3 คนรออยู่" | **ไม่มี** | ต้องเพิ่มไหม / แสดงตรงไหน |
| A4 | ปุ่ม HP-01 | "เปิด Calendar" | "Open Calendar" | — (แค่ภาษา) |
| A5 | ปุ่ม HP-02 | "Join Now" สีเขียว | "Join meeting" + ปุ่ม **"Later"** สีขาวเพิ่ม | Later ทำอะไร (ปิด toast เหมือน X? snooze?) |
| A6 | Bell badge +1 ตอน alert มา | ต้องเพิ่ม | ตอน toast โผล่ **ไม่มี** badge ที่ bell (มีที่ Chat) · เห็นที่ bell แค่หลัง dismiss | ยืนยันว่า +1 ทันทีที่ alert มา |
| A7 | ระยะเวลาค้าง 3 นาที | HP-01 / HP-02 | ไม่มีระบุ | — (ยึด ClickUp + ถามข้อ 1 ใน spec §6) |
| A8 | ตำแหน่ง toast | มุมขวาบน | top 24 / right 24 (error toast ของ Calendar = 16 / 16) | ใช้ระยะเดียวกันไหม |
| A9 | ปุ่มบนการ์ด history | "Join Now" | **"Join"** (h 24) | copy |
| A10 | Past item | greyed out | **ไม่ greyed** — ต่างแค่ไม่มีปุ่ม Join | ยึดแบบไหน |
| A11 | Status label (past / active) | ต้องแสดง | ไม่มี label | ต้องเพิ่มไหม |
| A12 | "Mark all as read" | ปุ่ม | text link "Mark as read" 12px | copy + ความหมาย (อ่านทั้งหมด?) |
| A13 | ประวัติ 7 วัน | ต้องมี | มีแค่กลุ่ม Today / Yesterday | หัวกลุ่มของวันเก่ากว่า |
| A14 | Tabs View all / Unread | ไม่มีใน ClickUp | มี | อยู่ใน scope ไหม · unread logic (bg 5%?) |
| A15 | Bundle offline (EP-01) | "คุณมี 3 meeting alerts ที่พลาดไป" | **toast** "You missed 3 meetings" + "View Calendar" · ใน panel ยังเป็น 3 การ์ดแยก · การ์ดไม่มีปุ่ม Join | ยึด Figma? · "View Calendar" พาไปวันไหน |
| A16 | Cancel / reschedule (EP-02) | notification เดียว "🔄 [ชื่อ] ถูกเลื่อน/ยกเลิกแล้ว" | แยก 2 แบบ (cancelled เทา / rescheduled ส้ม) · body บอกเวลาเดิม / เวลาใหม่ | ยึด Figma? |
| A17 | Join บน notification เดิมหลังยกเลิก | redirect ไป Calendar | ไม่มี frame แสดง · Event detail ของ meeting ที่ยกเลิกยังมีปุ่ม Join | พฤติกรรมจริง + state ของ Join เมื่อยกเลิก |
| A18 | "bell บน navbar" | navbar | **sidebar ซ้าย** (ไอคอนที่ 5) · panel 320 ดันแมพ | — (ยึด Figma) |
| A19 | Sample data | — | ชื่อ / เวลา / ห้องไม่ตรงกันข้าม frame ("Design Room" vs "Product Zyra room" vs "Meeting hall 01") | — |
| A20 | Toast ซ้อนกันหลายใบ (EC-02 ไม่ bundle) | แยกต่อ meeting | ไม่มี frame | ซ้อนแนวตั้ง? จำกัดกี่ใบ? |

---

## 8. ยังไม่ได้ดึง

- สี SVG จริงของ icon กล้อง, X, read icon (ไม่ได้ download asset) — ใน zyra-app ใช้ lucide (`Video`, `X`, `CheckCheck`, `Bell`)
- สี icon circle ของการ์ด "Meeting starts in 5 min…" (เห็นเป็นฟ้าใน screenshot)
- `7771:199912` (EP-02 reschedule idle) · Idle ต้น flow `7771:8159`, `7771:198054`, `7771:199908`
- Display panel ในห้อง `7767:465829`
- Hover / pressed / focus · animation · stacking · empty state · scroll · tab Unread active · loading ของ panel — ไม่มีใน design
