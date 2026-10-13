# Meeting — Calendar Integration — UX/UI Spec (from Figma)

> **สถานะ (2026-10-12): ถอดได้บางส่วน — Figma MCP ชน tool-call limit (Starter plan) ระหว่างดึง** · ส่วนที่ถอดได้แล้วคือ (1) โครง frame/state ครบทั้ง 7 section จาก `get_metadata` (2) sticky note ของ designer ทุกตัว (3) **Schedule event modal ค่าเริ่มต้น** แบบละเอียด (`get_design_context`) (4) ขนาด/ตำแหน่งของ Calendar panel + empty state จาก metadata ของ HP-04
> **ส่วนที่ยังไม่มีค่า px/hex/copy:** Integration Settings ทุก state, Toast, General modal, Calendar half/full view, event chip, warning ของ EP-02/EP-03, submenu, Mini Calendar, Event details → ดู [§9 รายการ node ที่ต้องดึงต่อ](#9-node-ที่ยังต้องดึง-รอ-quota-figma)
> **กติกา:** ตัวเลขทุกตัวในไฟล์นี้มาจาก Figma MCP เท่านั้น ([`rules/10-figma-fidelity.md`](../../../rules/10-figma-fidelity.md)) · ช่องที่ยังดึงไม่ได้เขียนว่า **"ยังไม่ได้ดึง"** · ห้าม implement ค่าที่เดาเอง
> **Figma file:** [Zyra design (More Organised ver.) — Copy](https://www.figma.com/design/4SQDUkxARPaqDynY2IH6kt/Zyra-design--More-Organised-ver.---Copy-) (`4SQDUkxARPaqDynY2IH6kt`) · node id ตรงกับไฟล์ต้นฉบับ `Map8gX0L2hk7HnkaFRfhtj`
> **flow / business rule อยู่ที่ [spec.md](spec.md)** — ไฟล์นี้พูดเฉพาะหน้าตา ตำแหน่ง และ state ของ UI · path ของโค้ดอ้างจากการสำรวจ `zyra-app` เมื่อ 2026-10-12 (branch `feat/vo-meeting-pip`) ก่อนแก้ให้ grep ยืนยันอีกครั้ง
> **ยังไม่ implement · ยังไม่ได้ review กับ Design/PM**

---

## 0. ภาพรวม: Figma วาดอะไรบ้าง

Figma ของ feature นี้มี **2 ส่วนใหญ่** ซึ่งตอนนี้ยังไม่มีในโค้ดทั้งคู่:

1. **Integrations tab ใน Setting modal** (`Intergration Setting`): connect, disconnect, consent ถูกปฏิเสธ, token หมดอายุ
2. **หน้า Calendar ทั้งหน้า:** half view (panel 320px ข้าง VO map) + full view + **สร้าง meeting (Schedule event modal)** + Event details + event chip 4 แบบ

ส่วนที่ 2 ยืนยันว่า Figma รวม **scheduled meeting + Calendar view** ไว้ใน feature นี้ ซึ่งตรงกับ blocker [Q1 ใน spec.md](spec.md#q1-blocker--scheduled-meeting--calendar-view-อยู่ใน-scope-นี้หรือไม่) (ดู [§8 ข้อ U1](#8-ข้อสังเกต--ขัดกับ-clickup--คำถาม-design))

| ชิ้น UI | อยู่ตรงไหน | ของเดิมในโค้ด | Scenario |
|---|---|---|---|
| Integration row + status (connect / connected / disconnected / expired) | Setting modal → tab Integrations | `IntegrationRow` มีแค่ state Connect (`vo-setting-modal.tsx:916-959`) | HP-01, HP-02, HP-04, EP-01, EP-02 |
| OAuth popup (หน้าจอ Google/Microsoft) | popup window ทับ Setting | ไม่มี (Google login ใช้ popup แต่เป็น flow คนละแบบ) | HP-01, HP-02, EP-01 |
| Toast สำเร็จ / ยกเลิก / disconnect | มุมขวาบน `x=1080 y=24` · 336×94 | `zyraToast` (`lib/toast.tsx:224`) | HP-01, HP-02, HP-04, EP-01 |
| Confirm disconnect ("General modal") | กลางจอ `x=491 y=409` · 458×206 + Overlay | pattern ของ `vo-spotlight-share-confirm-modal.tsx:54-74` | HP-04 |
| Calendar half view (`Calendar panel` 320×992) | ข้าง sidebar `x=72 y=16` | ไม่มี · กดไอคอน Calendar แล้วได้แค่ toast "coming soon" | ทุก scenario |
| Calendar full view (layer ชื่อ `Chat - Full view`) | เต็มจอ ยกเว้น sidebar | ไม่มี | HP-01, HP-03, EP-02, EP-03 |
| Schedule event modal 340px | `x=416 y=24` ทับ half view | ไม่มี | HP-03 |
| Mini Calendar / Submenu ×4 | dropdown ใต้ field ใน modal | มี date/time picker ของ Announcement ที่ reuse ได้ | HP-03 |
| Event details 340×419 | `x=416 y=581` | ไม่มี | HP-03 |
| Event chip 4 แบบ | ใน grid ของ full view | ไม่มี | HP-03 |
| Empty state "No calendar connected" | กลาง panel / กลาง full view | ไม่มี | HP-04 |
| Warning ใน calendar (หมดอายุ / sync ไม่สำเร็จ) + Sync now | header ของ calendar | ไม่มี (`VOAlertBanner` ผูกกับ weather) | EP-02, EP-03 |

---

## 1. Frame inventory ต่อ scenario (จาก `get_metadata`)

ทุก frame มีขนาด 1440×1024 · "→" หมายถึง overlay หรือ instance ที่วางทับใน frame นั้น

### HP-01 · Connect Google Calendar สำเร็จ — section `3237:609135`

| ลำดับ | Node | Frame | ของที่วางทับ |
|---|---|---|---|
| 1 | `3249:619414` | Intergration Setting | — |
| 2 | `3254:620693` | Intergration Setting | (ภาพรวมคือ popup OAuth สีขาวกลางจอ) |
| 3 | `3254:620694` | Intergration Setting | (popup OAuth) |
| 4 | `3254:621159` | Intergration Setting | (popup OAuth + ปุ่มสีน้ำเงิน) |
| 5 | `3301:5047` | Intergration Setting | → **Toast** `3298:5019` 336×94 @ (1080, 24) |
| แถว 2 | `3290:702457` | Calendar - Half view | sticky: *"Upcoming meeting จะโชว์แค่ของวันนั้นเท่านั้น"* |
| แถว 2 | `3298:4785` | Chat - Full view (= calendar full view) | — |
| แถว 3 | `3898:776546` | Calendar - Half view | sticky: *"เข้ามาครั้งแรกและมี Banner ให้ Add integration สามารถกากบาทออกได้"* |
| แถว 3 | `3898:777348` | Chat - Full view | — |
| แถว 3 | `3898:778198` | Calendar - Half view | sticky: *"Calendar list ถ้ายังไม่เชื่อม Integration จะมีแต่ My Calendar = Meeting ที่เราสร้าง, Thai holidays"* |

### HP-02 · Connect Microsoft Outlook สำเร็จ — section `3301:5048`

| Node | Frame | ของที่วางทับ |
|---|---|---|
| `3301:5050` | Intergration Setting | — |
| `3301:7591` | Intergration Setting | — |
| `3301:5057` | Intergration Setting | → **Toast** `3301:5059` 336×94 @ (1080, 24) |
| `3301:5055` | Calendar - Half view | — |
| `3301:5056` | Chat - Full view | — |

> HP-02 มีแค่ 3 frame ในฝั่ง settings (HP-01 มี 5) และ **ไม่มี frame ที่เป็น calendar selector** แม้ ClickUp HP-02 ข้อ 6–7 จะให้เลือก calendar แล้วกด "บันทึก" → [U3](#8-ข้อสังเกต--ขัดกับ-clickup--คำถาม-design)

### HP-03 · สร้าง Zyra Meeting แล้ว Sync ไป Calendar ภายนอก — section `3583:77760`

**Half view (แถวบน)**

| Node | Frame | ของที่วางทับ | sticky / ความหมาย |
|---|---|---|---|
| `3583:77766` | Calendar - Half view | — | จุดเริ่ม |
| `3585:81101` | Create meeting | Schedule event modal `3586:258261` 340×711 @ (416, 24) | modal ว่าง ([§4](#4-schedule-event-modal--ค่าเริ่มต้น-ดึงแล้ว)) |
| `3613:132953` | Create meeting | modal + **Overlay** 1440×1024 + **General modal** `3613:202062` 458×170 @ (491, 427) | น่าจะเป็นการยืนยันปิด/ทิ้งร่าง (ยังไม่ได้ดึง copy) |
| `3586:258613` | Create meeting | modal 340×998 + **Mini Calendar** `3586:260046` 308×266 @ (432, 282) | เลือกวันที่ |
| `3586:259364` | Create meeting | modal 340×998 + **Submenu** `3586:260164` 146×226 @ (432, 332) | น่าจะเป็นรายการเวลา (กว้างเท่าช่องเวลา) |
| `3586:260385` | Create meeting | modal + Submenu `3586:260388` 308×284 @ (432, 442) | ยังไม่รู้ (Location?) |
| `3586:261320` | Create meeting | modal + Submenu `3586:261992` 308×321 @ (432, 526) | ยังไม่รู้ (Guest?) |
| `3586:280958` | Create meeting | modal + Submenu `3586:280961` 308×77 @ (432, 508) | ยังไม่รู้ (Permission?) |
| `3598:754493` | Create meeting | modal 340×948 | *"กรณีกด All day Field เวลาจะหายไป"* |
| `3586:281994` | Create meeting | modal 340×711 | *"กรณีเอา guest ออกหมดตัว Permission จะหายไป"* |
| `3586:282647` | Create meeting | modal 340×998 | ฟอร์มกรอกครบ |
| `3589:283395` | Create meeting | **Toast** `3590:283992` 336×76 + **Event details** `3594:752725` 340×419 @ (416, 581) | สร้างสำเร็จ |
| `3601:759928` | Create meeting | **Toast** `3601:759930` 336×112 | *"sync ล้มเหลว: Zyra meeting ยังสร้างสำเร็จ พร้อม toast warning การจะ Sync now ต้องเปิด Full view ถึงจะเห็นปุ่ม"* |
| `3601:761769` | Chat - Full view | — | *"กด Sync Now"* |

**Full view (แถวล่าง)**

| Node | Frame | ของที่วางทับ | sticky |
|---|---|---|---|
| `3583:77767` | Chat - Full view | — | — |
| `3594:753291` | Create meeting - Full view | modal 340×711 @ (416, 24) | *"แบบ Full view จะสามารถสร้างได้จาก ปุ่ม + กดจุดเวลาที่ตาราง"* |
| `3598:755976` | Create meeting - Full view | modal 340×998 | — |
| `3598:756788` | Create meeting - Full view | modal 340×998 | *"สามารถเลือกวันที่ได้ว่าจะเป็น วันเดียว หรือ หลายวัน เช่น 20 - 22 โดยการคลิกที่วัน"* |
| `3598:757508` | Create meeting - Full view | Toast `3598:758228` 336×76 + Event details `3598:758229` 340×419 | สร้างสำเร็จ |
| `3598:755129` | Create meeting - Full view | modal 340×711 @ **(762, 272)** | *"เมื่อกดที่ตารางจะขึ้น Event Schedule event"* (modal ไปเกาะช่องเวลาที่คลิก) |

**Event chip (`Meeting event`)**

| Node | ขนาด | sticky |
|---|---|---|
| `3613:132913` | 133×17 | *"Event ที่เราตอบรับแล้ว (น่าจะต้องกด YES ใน Google calendar)"* |
| `3613:132917` | 133×17 | *"Event ที่เรายังไม่ตอบรับ"* |
| `3613:132932` | 133×17 | *"Holiday วันสำคัญ"* |
| `3613:132943` | 133×**32** | *"กำลังสร้าง"* |

### HP-04 · Disconnect Calendar — section `3601:762611`

| ลำดับ | Node | Frame | ของที่วางทับ / sticky |
|---|---|---|---|
| 1 | `3601:762648` | Intergration Setting | (สถานะเชื่อมต่อแล้ว) |
| 2 | `4240:551007` | Intergration Setting = `Idle UI` + `Setting` 934×800 @ (253, 112) + **Overlay** | → **General modal** `4240:551936` 458×206 @ (491, 409) (ยืนยัน disconnect) |
| 3a | `3601:765503` | Intergration Setting | → Toast `3601:765504` 336×94 · sticky *"กรณี Google"* |
| 3b | `3601:765517` | Intergration Setting | → Toast `3601:765519` 336×94 · sticky *"กรณี Outlook"* |
| 4 | `3601:765821` | Calendar - Half view | empty state ([§5.3](#53-empty-state--no-calendar-connected)) · sticky *"หลังจาก Disconnect แล้วไปที่เมนู Calendar"* |
| 5 | `3601:765808` | Chat - Full view | empty state แบบ full view |

**ขนาด Setting modal ตามที่วางใน frame:** 934×800 @ (253, 112) ในจอ 1440×1024 (จาก `4240:551301`)

### EP-01 · User ปฏิเสธ OAuth Consent — section `3601:766158`

| Node | Frame | ของที่วางทับ |
|---|---|---|
| `3601:766160` | Intergration Setting | — |
| `3601:766161` | Intergration Setting | — |
| `3601:766162` | Intergration Setting | — |
| `3601:766195` | Intergration Setting | → **Toast** `3601:766197` 336×94 @ (1080, 24) |
| `3601:769050` | Intergration Setting | (แถว 2: น่าจะเป็นตอนกด "ลองใหม่") |

> Figma ใช้ **Toast** ขณะที่ ClickUp เขียนว่า "Error banner" → [U5](#8-ข้อสังเกต--ขัดกับ-clickup--คำถาม-design)

### EP-02 · Token หมดอายุ / Revoked — section `3601:769864`

| Node | Frame | ของที่วางทับ / sticky |
|---|---|---|
| `3602:774968` | Idle UI | — |
| `3602:775170` | Calendar - Expired token (half view) | sticky *"กดที่ข้อความ Warning หรือ ไปที่ Setting menu"* |
| `3602:775198` | Calendar - Expired token (full view) | — |
| `3613:131273` | Calendar - Expired token (Integration Setting) | → **Tooltips** `3613:131270` 285×46 @ (885, 200) |

### EP-03 · Sync ล้มเหลว — section `3602:834434`

| Node | Frame | sticky |
|---|---|---|
| `3602:834436` | Idle UI | — |
| `3602:834437` | half view | *"หลังจากระบบพยายาม Syn 3 ครั้ง แต่ไม่สามารถ Sync ข้อมูลได้"* |
| `3602:834439` | full view | *"เปิด Full view > กดปุ่ม Sync now"* |
| `3602:835652` | full view | *"กำลัง Sync ข้อมูล"* |
| `3602:836222` | full view | *"Sync สำเร็จ Warning หายไปทันที"* |

---

## 2. Design Tokens (เท่าที่ดึงได้จาก Schedule event modal `3586:258261`)

> ยังไม่ได้เรียก `get_variable_defs` · สีของ toast, badge, warning, event chip **ยังไม่ได้ดึง**

### Colors

| Token (Figma) | ค่า | ใช้กับ |
|---|---|---|
| Theme colour/Primary | `#242B32` | พื้นหลัง modal และ input |
| Solid White/100% | `#FFFFFF` | title, label, value, ปุ่ม Cancel |
| Solid White/20% | `rgba(255,255,255,0.2)` | border ของ input, scrollbar thumb |
| Grey/100 | `#DBDFE3` | พื้นหลังปุ่ม Create (disabled) |
| Grey/300 | `#B2BBC3` | border ของปุ่ม Create (disabled) |
| Grey/400 | `#A3ADB8` | ตัวอักษรปุ่ม Create (disabled) |
| Grey/500 | `#8C99A6` | subtitle |
| Grey/700 | `#636D76` | placeholder |
| Gray/6 | `#D1D1D6` | border ของ checkbox |
| Shade Black/500 | `#1A1B1E` | ตัวอักษรปุ่ม Cancel |
| White shadow | DROP_SHADOW `#FFFFFF14` offset (0, 4) radius 16 spread 0 | เงาของ modal |

### Typography (Inter: ใน code ใช้ `font-sans` เพื่อให้ข้อความไทยแสดงผลถูกต้อง เหมือน feature อื่น)

| Style | Size / Weight / Line-height |
|---|---|
| Title/Bold | 20 / 700 / 25 |
| Sub/Regular | 16 / 400 / 22 |
| Body/Regular | 14 / 400 / 18 |

---

## 3. Integrations tab (Setting modal): ⚠️ ยังไม่ได้ดึงค่า

### 3.1 สิ่งที่ยืนยันได้แล้ว

- Setting modal 934×800 วางที่ (253, 112) (`4240:551301`)
- Toast ทุกตัวในฝั่ง settings มีขนาด **336×94** วางที่ **(1080, 24)**
- Confirm disconnect = General modal **458×206** @ (491, 409) + Overlay เต็มจอ
- Tooltip ของ EP-02 = **285×46** @ (885, 200) ในหน้า Integration Setting (ClickUp บอกว่า tooltip อยู่บน calendar header แต่ Figma วาง tooltip ไว้ในหน้า Settings → [U7](#8-ข้อสังเกต--ขัดกับ-clickup--คำถาม-design))

### 3.2 State ที่ต้องมี (ตาม ClickUp × frame) และค่าที่ยังขาด

| State | Frame | Badge / ปุ่ม (ClickUp) | ค่าจาก Figma |
|---|---|---|---|
| ยังไม่เชื่อมต่อ | `3249:619414`, `3301:5050`, `3601:766160` | ปุ่ม "เชื่อมต่อ Google Calendar" / "เชื่อมต่อ Microsoft Outlook" | ยังไม่ได้ดึง |
| กำลัง OAuth (popup) | `3254:620693`, `3254:620694`, `3254:621159`, `3301:7591` | — | ยังไม่ได้ดึง (หน้า consent เป็นของ Google/Microsoft ไม่ต้อง implement) |
| เชื่อมต่อแล้ว | `3301:5047`, `3301:5057`, `3601:762648` | Connected badge + "ยกเลิกการเชื่อมต่อ" | ยังไม่ได้ดึง |
| ยืนยัน disconnect | `4240:551007` | "ยกเลิกการเชื่อมต่อ Google Calendar? Events จาก Google จะไม่แสดงใน Zyra" | ยังไม่ได้ดึง |
| หลัง disconnect | `3601:765503` (Google), `3601:765517` (Outlook) | "ไม่ได้เชื่อมต่อ" + "เชื่อมต่อ" | ยังไม่ได้ดึง |
| consent ถูกปฏิเสธ | `3601:766195`, `3601:769050` | "การเชื่อมต่อถูกยกเลิก — กรุณาอนุมัติสิทธิ์เพื่อ sync calendar" + "ลองใหม่" | ยังไม่ได้ดึง |
| token หมดอายุ | `3613:131273` | "หมดอายุ" สีเหลือง + "เชื่อมต่อใหม่" + tooltip | ยังไม่ได้ดึง |

### 3.3 ค่าที่โค้ดปัจจุบันใช้อยู่ (อ้างอิงเท่านั้น ไม่ใช่ค่าจาก Figma ของ feature นี้)

`IntegrationRow` (`vo-setting-modal.tsx:916-959`, comment อ้าง Figma `3233:607794`):
- กล่องโลโก้ `56px` `rounded-[8px] bg-white` · โลโก้ Google 44 / Outlook 40
- ชื่อ 14 medium / 18 white · คำอธิบาย 14 / 18 `#8C99A6`
- ปุ่ม `h-32 rounded-6 bg-#58D68D px-16 py-8` ข้อความ "เชื่อมต่อ"
- i18n `messages/th.json:1047-1054` ใช้ชื่อ "Google calendar" / "Outlook calendar" (c ตัวเล็ก) ต้องเทียบกับ Figma

---

## 4. Schedule event modal: ค่าเริ่มต้น ✅ ดึงแล้ว

**Node:** `3586:258261` (instance ของ component `3586:257415`, variant `varient="Default"`) · frame `3585:81101`

### 4.1 Container

| Property | ค่า |
|---|---|
| ขนาด | กว้าง **340px** · สูง 711 ในสถานะว่าง / 948 เมื่อติ๊ก All day / 998 เมื่อมี dropdown หรือกรอกครบ |
| ตำแหน่ง | (416, 24) ทับ half view · ใน full view อยู่ที่ (416, 24) หรือเกาะช่องเวลาที่คลิก เช่น (762, 272) |
| พื้นหลัง | `#242B32` |
| Radius / padding / gap | 16 / 16 / 16 (flex column) |
| Shadow | `#FFFFFF14` (0, 4) blur 16 |
| Overflow | `overflow-clip` + scrollbar thumb ภายใน: absolute right 0, top 56, 6×64, radius 90, `rgba(255,255,255,0.2)` |

### 4.2 Header (`3586:257329`)

| Element | ค่า |
|---|---|
| Title | "Schedule event" · Title/Bold 20/25 · `#FFFFFF` |
| Subtitle | "Create and schedule meetings." · Body/Regular 14/18 · `#8C99A6` |
| Gap title→subtitle | 8 |
| Close | component `Cancel` (`2:1087`) 24×24 มุมขวาบน |
| Divider | `3586:257334` เส้นเต็มความกว้าง (สีเส้นยังไม่ได้ดึง) |

### 4.3 Fields (ตามลำดับ)

ค่าที่ทุก field ใช้ร่วมกัน:
- label Body/Regular 14/18 `#FFFFFF`
- label→control gap 8
- control สูง **42**, พื้น `#242B32`, border 1px `rgba(255,255,255,0.2)`, radius **8**
- control padding x12 y8, gap 8, icon 16×16
- ตัวอักษร 14/18 · placeholder `#636D76` · value `#FFFFFF`

| # | Label | Node | Control | Placeholder / ค่าเริ่มต้น | Icon ซ้าย / ขวา |
|---|---|---|---|---|---|
| 1 | Title | `3586:257336` | text input | "Please input title" | — |
| 2 | Date & Time | `3586:257337` | dropdown → Mini Calendar | "20 July, 2026" | calendar / chevron-down |
| 3 | *(ไม่มี label)* เวลาเริ่ม | `3586:257339` | dropdown (time) | "10:00" | time / chevron-down |
| 4 | *(ไม่มี label)* เวลาจบ | `3586:257340` | dropdown (time) | "10:30" | time / chevron-down |
| — | ข้อ 3 กับ 4 อยู่แถวเดียวกัน gap 8 แต่ละช่อง flex-1 | `3586:257338` | | | |
| 5 | All day | `3593:298784` | **Checkbox** 16×16, border 1px `#D1D1D6`, radius 4, gap กับ label 8 | ไม่ติ๊ก | — |
| — | ข้อ 2–5 อยู่ในกลุ่มเดียวกัน gap 8 | `3593:298799` | | | |
| 6 | Location | `3586:257341` | dropdown | "Please select location" | location pin / chevron-down |
| 7 | Guest | `3586:257342` (สูง 68 รวม label) | input (member picker) | "Please add guest" | people / — |
| 8 | Description | `3586:257343` ("Rich input") | textarea สูง **100**, align top | "Add description" | — |

**ไม่มีใน modal ค่าเริ่มต้น:** Repeat · ตัวเลือก calendar ภายนอก (Google/Outlook) · ช่อง join link · Guest permission (sticky บอกว่าจะโผล่เมื่อมี guest ≥1 แต่ยังไม่ได้ดึง)

### 4.4 Buttons (`3586:257344`: justify-end, gap 16)

| ปุ่ม | Copy | พื้น | Border | ตัวอักษร | ขนาด |
|---|---|---|---|---|---|
| Cancel | "Cancel" | `#FFFFFF` | — | `#1A1B1E` Sub/Regular 16/22 | h42 · px16 py8 · radius 8 |
| Create (disabled ตอนฟอร์มว่าง) | "Create" | `#DBDFE3` | 1px `#B2BBC3` | `#A3ADB8` 16/22 | h42 · px16 py8 · radius 8 |

สถานะ enabled ของ Create อยู่ใน `3586:282647` ซึ่งยังไม่ได้ดึง

### 4.5 Behavior จาก sticky

- ติ๊ก **All day** → ช่องเวลา (ข้อ 3–4) หายไป (`3598:754493`, modal สูง 948)
- เอา guest ออกจนหมด → ส่วน **Permission** หายไป (`3586:281994`)
- Full view: เลือกได้ทั้งวันเดียวหรือหลายวัน (เช่น 20–22) โดยคลิกที่วัน (`3598:756788`)
- Full view: สร้างได้ 2 ทาง คือ ปุ่ม **+** หรือ **คลิกช่องเวลาในตาราง** แล้ว modal จะเกาะตำแหน่งที่คลิก (`3598:755129`)
- สร้างสำเร็จ → Toast 336×76 + Event details 340×419 (`3589:283395`)
- Sync ไป calendar ภายนอกไม่สำเร็จ → meeting ยังสร้างได้ + Toast warning 336×112 · ปุ่ม **Sync now** มีเฉพาะใน full view (`3601:759928`)

---

## 5. Calendar view: ⚠️ ยังไม่ได้ดึงค่า (มีแค่ขนาดและตำแหน่งจาก metadata)

### 5.1 Half view: `Calendar panel` (จาก `3601:765821`)

| Element | Node | ตำแหน่ง / ขนาด (ภายใน panel) |
|---|---|---|
| Sidebar | `3601:765823` | 72×1024 @ (0, 0) |
| Calendar panel | `3601:765824` | **320×992** @ (72, 16) |
| Title row | `3601:765825` | 288×32 @ (16, 16) → padding 16 |
| └ "Calendar" | `3601:765826` | ข้อความ 89×25 |
| └ Menu group | `3601:765827` | 72×32 ขวาสุด · ปุ่ม 32×32 สองปุ่ม (`3601:765828` @ 0, `3601:765829` @ 40) → gap 8 |
| Search input | `3601:765830` | 288×**42** @ (16, 64) → title→input gap 16 |
| Content | `3601:765831` | 288×854 @ (16, 122) → input→content gap 16 |
| พื้นที่ทางขวาของ panel (`BG`) | `3601:765822` | 1016×992 @ (408, 16) → panel→BG gap 16 |

ยังไม่ได้ดึง: สีพื้นของ panel, radius, ไอคอนของปุ่มใน Menu group (น่าจะเป็นขยาย full view กับสร้าง event แต่ยังไม่ยืนยัน), mini month calendar, calendar list (My Calendar / Thai holidays / Google / Outlook + สี + checkbox), Upcoming meeting list, banner "Add integration" ตอนเข้าครั้งแรก

### 5.2 Full view (`Chat - Full view`, จาก `3601:765808`)

| Element | Node | ตำแหน่ง / ขนาด |
|---|---|---|
| Sidebar | `3601:765811` / `3601:765820` | 72×1024 |
| Calendar panel (ด้านซ้าย) | `3601:765812` | 320×992 @ (72, 16) |
| พื้นที่หลัก (`Chat display + Menu`) | `3601:765813` | **1016×992** @ (408, 16) |

ยังไม่ได้ดึง: grid (day/week/month), view switcher, time column, today indicator, ปุ่ม +, ปุ่ม Sync now, warning

### 5.3 Empty state: "No calendar connected"

| Element | Half view (`3601:765831`) | Full view (`3601:765814`) |
|---|---|---|
| กลุ่ม | 288×854 | 438×976 @ (289, 8) ในพื้นที่หลัก (กึ่งกลาง) |
| รูป (Rectangle 92) | 100×100 @ (94, 307) | 100×100 @ (169, 377) |
| รูป→ข้อความ | 16 | 16 |
| Title | "No calendar connected" 182×22 | เหมือนกัน |
| Title→คำอธิบาย | 8 (y 0 → 30, title สูง 22) | 8 |
| คำอธิบาย | "Connect a calendar in Settings > Integrations to view your events." 288×36 (2 บรรทัด) | 438×18 (1 บรรทัด) |
| ข้อความ→ปุ่ม | 16 | 16 |
| Button | 130×42 (copy ยังไม่ได้ดึง) | 130×42 |

> Figma ใช้ copy ภาษาอังกฤษ ส่วน ClickUp ใช้ภาษาไทย ต้องทำ i18n ครบทั้ง `en` และ `th`

### 5.4 Event chip: ยังไม่ได้ดึง

มี 4 variant ตามตาราง §1 HP-03 (ตอบรับแล้ว / ยังไม่ตอบรับ / Holiday / กำลังสร้าง) · กว้าง 133 · สูง 17 ยกเว้น "กำลังสร้าง" สูง 32

### 5.5 Warning ของ EP-02 / EP-03: ยังไม่ได้ดึง

- EP-02: ข้อความ Warning ที่กดได้ (พาไป Settings) อยู่ใน half view และ full view
- EP-03: หลัง retry ครบ 3 ครั้ง → warning · full view มีปุ่ม Sync now → state "กำลัง Sync" → สำเร็จแล้ว warning หายทันที

---

## 6. Component reuse map (zyra-app)

| ชิ้นใน Figma | Reuse / ใหม่ | ที่อยู่ |
|---|---|---|
| Integration row | **reuse + เพิ่ม state** (badge, ปุ่มรอง, ยกเลิกการเชื่อมต่อ) | `views/user/virtual-office/components/vo-setting-modal.tsx:916-959` |
| Integrations tab / nav | reuse · เปลี่ยน handler จาก toast "coming soon" เป็นต่อ OAuth | `vo-setting-modal.tsx:961-989`, `:993-1014` |
| Toast ทุกตัว (+ ปุ่ม "ลองใหม่" / "Sync now") | reuse `zyraToast` + `layout:"figma"` + `actions` + `duration` | `lib/toast.tsx:56`, `:224` |
| General modal (ยืนยัน disconnect / ทิ้งร่าง) | reuse pattern (ยังไม่มี component กลาง) | `vo-spotlight-share-confirm-modal.tsx:54-74`, `vo-spotlight-exit-confirm-modal.tsx` · mobile `components/confirm-sheet.tsx:28` |
| Tooltip | reuse | `components/ui/tooltip.tsx:57` |
| Checkbox (All day, calendar list) | reuse | `components/ui/checkbox.tsx:33` |
| Input (Title, search) | reuse | `components/ui/input.tsx:19` · search pattern `views/chat/components/chat-sidebar.tsx:540-547` |
| Select / Submenu | reuse | `components/ui/select.tsx` (:181), `components/ui/dropdown-menu.tsx` |
| Button | reuse (ต้องเทียบ variant สี) | `components/ui/button.tsx:67` |
| Date field + Mini Calendar | reuse | `views/user/virtual-office/components/announcement/announcement-date-time.tsx:133` (`AnnouncementDateField`) |
| Time dropdown | reuse (ทีละ 15 นาที) ต้องเทียบกับ Submenu 146×226 | `announcement-date-time.tsx:317` (`AnnouncementTimeField`), `TIME_OPTIONS` :32 |
| เลือกหลายวัน (full view) | reuse | `views/chat/components/date-range-picker.tsx:57` |
| Calendar icon ใน sidebar | reuse (tab id `calendar` มีแล้ว) | `vo-sidebar.tsx:24`, `:85` · ตอนนี้กดแล้วขึ้น toast ที่ `hero-virtual-office.tsx:4666-4669` |
| Half / full view toggle + mount | reuse pattern ของ Chat (`chatView: closed/half/full`) | `hero-virtual-office.tsx:894`, `:14619-14630` (half), `:14632-14643` (full) |
| Panel shell 320px | reuse class หลังเทียบสีกับ Figma | `views/chat/chat-surface.tsx:350`, `announcement/announcement-list-panel.tsx:105` |
| ปุ่มขยาย/ย่อ | reuse pattern `Maximize2`/`Minimize2` | `views/chat/components/chat-sidebar.tsx:486` |
| Guest picker | **ใหม่** (ประกอบจากของเดิม) | อ้างอิง `views/chat/components/start-new-chat-panel.tsx:54`, `invite-member-modal.tsx:100` |
| Textarea (Description) | **ใหม่** (ไม่มี `components/ui/textarea.tsx`) | — |
| Status badge (Connected / ไม่ได้เชื่อมต่อ / หมดอายุ) | **ใหม่** | — |
| Grid ของ full view, event chip, Event details, warning ของ calendar, banner "Add integration" | **ใหม่** (`VOAlertBanner` ผูกกับ weather ใช้ตรง ๆ ไม่ได้ ยืมแค่หน้าตาได้) | `vo-alert-banner.tsx:48` (อ้างอิงหน้าตา) |

> ไม่มี shadcn `calendar` / `popover` และไม่มี `react-day-picker` / `date-fns` / `dayjs` ใน `package.json` · ถ้าจะเพิ่ม dependency ต้องขออนุมัติก่อน (`rules/08-shadcn-ui.md`, `rules/14-no-overreach.md`) · ทางที่แนะนำคือ reuse picker ของ Announcement/Chat ที่มีอยู่แล้ว
> Mobile: sidebar บน mobile **ไม่แสดง** Calendar (`vo-sidebar.tsx:119`) และ Figma ไม่มี frame mobile → [U10](#8-ข้อสังเกต--ขัดกับ-clickup--คำถาม-design)

---

## 7. ไม่อยู่ใน Figma ทั้งที่ ClickUp เขียนไว้ (ห้าม implement จนกว่าจะมี design)

| ClickUp | Figma |
|---|---|
| HP-01/HP-02 calendar selector (รายชื่อ calendar + "บันทึก") · EC-02 list + search เมื่อ > 10 อัน | ไม่พบ frame selector ใน settings (ยังต้องดู `3254:621159` / `3301:7591` ให้แน่ใจ) · calendar list ที่เห็นอยู่ใน half view แทน |
| EP-01 Error banner auto-hide 10 วิ | ใช้ Toast |
| EP-02 Warning icon + tooltip บน calendar header | ข้อความ Warning ที่กดได้ใน calendar + tooltip อยู่ในหน้า Settings |
| EP-03 "⚠ Events อาจไม่อัปเดต — [ลองใหม่]" | ปุ่ม **Sync now** ใน full view |
| HP-03 Zyra join link ใน event | modal ไม่มีช่อง join link (อาจอยู่ใน Event details ซึ่งยังไม่ได้ดึง) |

---

## 8. ข้อสังเกต / ขัดกับ ClickUp / คำถาม design

| # | เรื่อง | รายละเอียด |
|---|---|---|
| U1 | Figma ยืนยันว่ามี scheduled meeting + Calendar view | มี Schedule event modal, Event details, grid, event chip ครบ → ตอบ [Q1](spec.md#q1-blocker--scheduled-meeting--calendar-view-อยู่ใน-scope-นี้หรือไม่) ฝั่ง design ว่า **อยู่ใน feature นี้** แต่ ClickUp ไม่มี subtask/AC ของการสร้าง/แก้/ลบ meeting และหน้า Calendar เลย ต้องให้ PM เพิ่ม AC |
| U2 | "ห้อง" กับ "Location" | ClickUp ใช้คำว่า "ห้อง" · Figma ใช้ **Location** ("Please select location") ตัวเลือกคืออะไร (meeting zone บน VO map? ข้อความอิสระ?) ต้องรอดึง Submenu |
| U3 | Calendar selector | ClickUp HP-02 ให้เลือก calendar แล้วกด "บันทึก" · Figma HP-02 ไม่มี frame selector |
| U4 | attendees กับ Guest + Permission | Figma มี Guest permission (ไม่มีใน ClickUp) · permission มีอะไรบ้าง และส่งต่อไป Google/Outlook ได้หรือไม่ (Google มี `guestsCanModify` / `guestsCanInviteOthers` / `guestsCanSeeOtherGuests` ส่วน Outlook ไม่มี field ตรงกัน) |
| U5 | EP-01 Toast หรือ Banner | ClickUp เขียนว่า banner · Figma ใช้ Toast → เสนอให้ยึด Figma (reuse `zyraToast` + action "ลองใหม่" + `duration` 10s) |
| U6 | Sync now มีแค่ใน full view | sticky ระบุว่าต้องเปิด full view ถึงจะเห็นปุ่ม · EC-03 ใน ClickUp ใช้ toast "ลองใหม่" · ถ้าใช้ toast ที่มี action ก็กด retry ได้ทันทีโดยไม่ต้องเปิด full view ต้องถาม design |
| U7 | ตำแหน่ง tooltip ของ EP-02 | ClickUp: บน calendar header · Figma: ใน Integration Setting |
| U8 | "Thai holidays" | Figma มี calendar "Thai holidays" ตั้งแต่ยังไม่เชื่อม integration · ข้อมูลมาจากไหน (Google public holiday calendar ใช้ไม่ได้ถ้า user ไม่ได้ connect) |
| U9 | เลือกหลายวัน | full view เลือก 20–22 ได้ · ใน half view ทำได้ไหม · event หลายวันที่ไม่ใช่ all day จะแสดงอย่างไร |
| U10 | Mobile | ไม่มี frame mobile และ sidebar บน mobile ซ่อน Calendar · ช่วงแรกจะไม่รองรับ mobile ใช่ไหม |
| U11 | ภาษา | copy ใน Figma เป็นภาษาอังกฤษ ("Schedule event", "No calendar connected") แต่ ClickUp ใช้ภาษาไทย ต้องทำ `en` + `th` |
| U12 | ชื่อ layer | frame calendar full view ชื่อ `Chat - Full view` และ `Intergration` สะกดผิด · ไม่กระทบการ implement แค่บันทึกไว้ไม่ให้สับสน |

---

## 9. Node ที่ยังต้องดึง (รอ quota Figma)

Figma MCP ตอบกลับว่า *"You've reached the Figma MCP tool call limit on the Starter plan"* (ไฟล์ copy) และ *"…for your Collab seat on the Professional plan"* (ไฟล์ต้นฉบับ) · ต้องรอ quota reset หรืออัปเกรด seat

ลำดับที่ประหยัด call ที่สุด:

1. `get_variable_defs` 1 ครั้ง (เช่นบน `3290:702457`) → token ทั้งชุด
2. **Integrations:** `get_design_context` บน `Setting` ของ `3601:762648` (connected), `3601:765503` (disconnected), `3613:131273` (expired + tooltip), `3601:766195` (deny) · Toast `3298:5019`, `3601:765504`, `3601:766197` · General modal `4240:551936`
3. **Calendar half/full:** `3290:702457` (half), `3298:4785` (full), `3898:776546` (banner ครั้งแรก), `3898:778198` (calendar list ก่อน connect)
4. **Event chip:** `3613:132913`, `3613:132917`, `3613:132932`, `3613:132943`
5. **EP-02/EP-03:** `3602:775170`, `3602:775198`, `3602:834437`, `3602:834439`, `3602:835652`, `3602:836222`
6. **Schedule event:** Mini Calendar `3586:260046` · Submenu `3586:260164`, `3586:260388`, `3586:261992`, `3586:280961` · modal กรอกครบ `3586:282647` · All day `3598:754493` · General modal `3613:202062` · Event details `3594:752725` · Toast `3590:283992`, `3601:759930`
7. `get_screenshot` ทีละ top-level frame เพื่อเทียบภาพรวม

เมื่อดึงได้ให้เติม §3, §5 และส่วนที่เหลือของ §4 แล้วลบเครื่องหมาย ⚠️ ออก
