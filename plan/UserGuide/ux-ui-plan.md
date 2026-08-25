# User Guide Module — UX/UI Plan (Pixel-Perfect)

> **Source:** Figma file `Map8gX0L2hk7HnkaFRfhtj` (Zyra design — More Organised ver.) — ดึง spec ผ่าน Figma MCP 2026-07-14
> **Canvas:** 1440 × 1024 px · Design tokens ร่วมกับ Chat/VirtualOffice module
> **Version:** 1.0 · **Date:** 2026-07-14
> Node IDs ทั้งหมดอยู่ใน `figma-nodes.md`

---

## 1. Design Tokens

| Token | ค่า | ใช้กับ |
|---|---|---|
| Background/Primary | `#242B32` | modal bg, panel bg, input bg |
| Background/Secondary | `#2B3540` | body card, counter chip, Popular Articles card |
| Shade Black/500 | `#1A1B1E` | toast bg |
| Shade Black/50% | `rgba(26,27,30,0.5)` | onboarding sidebar bg |
| Primary/500 | `#58D68D` | primary buttons, active icon box, progress fill, links, step numbers, category label |
| Primary/20% | `rgba(88,214,141,0.2)` | active tab bg, check icon box, success toast icon tile |
| Primary/900 | `#255A3B` | step badge bg (UG-06) |
| Gradient progress | `#58D68D → #8FE4B3` | onboarding progress fill |
| Yellow/500 + 20% | `#ECC819` / `rgba(236,200,25,0.2)` | skip-confirm warning icon |
| Red/500 + 20% | `#F03A3A` / `rgba(240,58,58,0.2)` | Yes, Skip danger button; required `*`; error toast icon tile |
| Blue/500 + 10%/20% | `#2DB6FF` | info banner; Getting Started tint |
| Orange/500 + 20% | `#FF8000` | search match highlight; Billing tint |
| Purple/500 | `#996ADF` | Account tint |
| Navy/500 | `#2C5AE4` | Chat tint |
| Grey/500 | `#8C99A6` | subtitle, caption, breadcrumb title |
| Grey/700 | `#636D76` | placeholder |
| Disabled btn | bg `#DBDFE3` / border `#B2BBC3` / text `#A3ADB8` | Send Message disabled |
| White 5% / 10% / 20% | `rgba(255,255,255,…)` | ghost bg / hover / border, divider, inactive dots |
| Overlay | `rgba(0,0,0,0.5)` | ทุก modal/spotlight |
| Menu shadow | `0 4px 16px rgba(255,255,255,0.08)` | modal, panel, dropdown, toast |

**Typography (Inter):** Title/Bold 20/25·700 · H/Bold 20·700 · Sub/Bold 16/22·700 · Sub/Medium 16/22·500 · Body/Bold-Medium-Regular 14/18 · Caption1 12/15 (tracking −0.43) · Step badge 12 SemiBold uppercase · Buttons 16/22 Regular
**Radius:** 24 (confirm/success modal) · 16 (modal ใหญ่, dropdown, toast) · 12 (coach-mark) · 8 (cards, inputs, buttons hลัก) · 6 (ปุ่มเล็ก h-32) · 4 (dots, tag) · 100/90 (icon chips, scrollbar)
**ปุ่มมาตรฐาน:** primary `h-[42px] px-4 rounded-[8px] bg-[#58D68D]` · ghost `h-[42px]` โปร่ง · secondary `bg-white/5 border border-white/20` · small `h-[32px] rounded-[6px]`

---

## 2. SC-UG-01/02/03 — Onboarding Modal

### 2.1 Shell (900×600, centered บน overlay ดำ 50%)

```
┌─ 900×600 · bg #242B32 · rounded-[16px] · overflow-clip · flex ────────────┐
│ Sidebar 212px                     │ Content 688px                          │
│ bg rgba(26,27,30,0.5)             │ ┌ Hero 260px (image + tint + [Skip]) ┐ │
│ ┌ Header p-24 border-b white/20 ┐ │ │ Skip: h-32 px-4 rounded-[6px]     │ │
│ │ 🚀 Getting Started (16 Bold)  │ │ │  bg white/5 border white/20       │ │
│ │ Zyra Virtual Office Guide     │ │ └───────────────────────────────────┘ │
│ │  (14 Reg #8C99A6)             │ │ Title row px-4 py-6: icon box 32     │ │
│ └───────────────────────────────┘ │  bg #58D68D + Title 20/25 Bold       │ │
│ Tabs p-16 gap-8:                  │ Body px-4 pb-6: 14/18 Regular white  │ │
│  Welcome / Office Setup /         │ ── divider white/20 ──                │ │
│  Invite Team / How to Play        │ Footer px-4 py-6 justify-between:    │ │
│  item p-8 rounded-[8px]           │  ● dots + chip "n / m"               │ │
│   default: icon box bg white/5    │  [Back ghost] [Next → primary]       │ │
│   active: bg #58D68D/20,          │                                       │ │
│           icon box bg #58D68D     │                                       │ │
│   done: + check 16 เขียวขวาสุด    │                                       │ │
│ Footer p-16/24 border-t:          │                                       │ │
│  "Overall Progress"  n%           │                                       │ │
│  track h-8 rounded-full white/20  │                                       │ │
│  fill gradient #58D68D→#8FE4B3    │                                       │ │
└───────────────────────────────────┴───────────────────────────────────────┘
```

- Page dots: current = pill 22×8 `#58D68D`; อื่น = 8×8 `white/20`; chip counter `bg-[#2B3540] px-2 py-1 rounded-[8px]` text 14 `#8C99A6`
- Progress: 0% (Welcome) → 33% (Office Setup ทั้ง 3 หน้า) → 67% (Invite Team) → 100% (How to Play)
- Hero: ภาพ illustration + tint `rgba(43,53,64,0.5)`; steps 2-7 มี product screenshot ทับ; Welcome แสดงโลโก้ Z 80×80

### 2.2 Copy ทั้ง 7 หน้า (verbatim)

| หน้า | Title | Body | Footer |
|---|---|---|---|
| Welcome | `Welcome to Zyra, {name}!` | `We're thrilled to have you here. Let's take a quick tour to see how you can set up your perfect virtual workspace. You can use the tabs on the left to explore at your own pace.` | Next เท่านั้น |
| Office Setup 1/3 | `1. Create & Choose Theme` | `Simply click 'Create Workspace', use filters for team capacity, and select your preferred Workspace theme.` | dots 1/3 + Back/Next |
| Office Setup 2/3 | `2. Review Details & Preview` | `Click 'Continue' to view the Workspace details summary. You can Preview the map to see the layout before deciding.` | dots 2/3 |
| Office Setup 3/3 | `3. Name & Create Workspace` | `If the preview looks great, simply enter your Workspace or map name, then click create to get started!` | dots 3/3 |
| Invite Team 1/2 | `1. Access Invite Menu` | `Inside your Workspace, locate the 'Member' or 'Setting member' menu. Click the 'Invite member' button to begin.` | dots 1/2 |
| Invite Team 2/2 | `2. Choose Invite Method` | `Choose what works best! You can type their Email address to send a direct invite, or Copy the Link and drop it in your team's chat.` | dots 2/2 |
| How to Play | `Walk & Talk Naturally` | `Use your keyboard arrows (or W,A,S,D) to walk. Move close to your colleagues and a video chat will automatically pop up!` | Back + **Let's Go!** (rocket icon) |

### 2.3 Success Modal (458×332)

`rounded-[24px] bg-[#242B32] p-10 gap-10 items-center` + Menu shadow
icon box 80×80 `rounded-[8px] bg-[#58D68D]/20` + check 56 เขียว → **"You're All Set!"** (20 Bold) → **"Enjoy your new virtual workspace."** (14/18 `#8C99A6`, w-392 center) → ปุ่ม secondary **"Back to Workspace"**

### 2.4 Skip Confirmation (SC-UG-02, 458×332 shell เดียวกัน)

- icon box 80×80 `bg-[rgba(236,200,25,0.2)]` + warning-circle 56 `#ECC819`
- **"Skip the onboarding tutorial?"** (20 Bold) / **"You can always configure settings from the Profile menu"** (14/18 `#8C99A6`)
- ปุ่ม gap-16: **Cancel** (secondary) + **"Yes, Skip"** (`bg-[rgba(240,58,58,0.2)] border-[rgba(240,58,58,0.2)] text-[#F03A3A]`)
- Layer: tutorial modal ยังอยู่ข้างใต้ + overlay ดำ 50% อีกชั้น

### 2.5 Post-skip Spotlight + Coach-mark (SC-UG-02)

- Overlay ดำ 50% เจาะรู rounded-rect **214×70** รอบปุ่ม "Create workspace" มุมขวาบน (ตำแหน่งจริงจาก `getBoundingClientRect` ไม่ hardcode 1196,98)
- Tooltip ขาว **300×46** ทางซ้ายของปุ่ม: `bg-white rounded-[12px] px-4 py-3` text **"Click to start creating a workspace."** 16/22 ดำ
- ไม่มี arrow / ปุ่มปิด — dismiss เมื่อคลิกที่ใดก็ได้ (open Q4), one-shot

### 2.6 Resume (SC-UG-03)

Welcome modal instance เดิมเป๊ะ ที่ 0% — ไม่มี UI ใหม่

---

## 3. SC-UG-04/05 — Help Center Panel

### 3.1 Shell (ทุกหน้า)

- Panel **336×full-height** docked `right-0 top-0`, `bg-[#242B32] p-4 gap-6 flex-col` + Menu shadow (content กว้าง 304)
- **Header:** CircleHelp icon 24 เขียว + **"Help Center"** (16/22 Medium) + X 24 ขวาสุด (ปิด)
- **Tabs:** container `border border-white/20 rounded-[8px] p-1`; 2 tabs flex-1 h-32 `rounded-[8px]` icon 16 + label 14/18 — active `bg-[rgba(88,214,141,0.2)]`: **Articles** / **My Tickets**
- **Search:** `h-[42px] rounded-[8px] border-white/20 bg-[#242B32] px-3` icon 16 + placeholder **"Search topic, issue, or keywords..."** `#636D76`
- **Footer:** divider → **"Need more help?"** (12/15 `#8C99A6`) → ปุ่ม **"Contact Support"** (h-32 rounded-[6px] bg-white/5 border-white/20, Mail icon 16)
- **Breadcrumb block** (category/detail/contact): divider / row h-32 gap-4: back button 32×32 (`rounded-[6px] bg-white/5 border-white/20` ArrowLeft 16) + title 14/18 Bold `#8C99A6` / divider

### 3.2 Main

- **"Recommended for you"** (Pin icon 16 + 14 Bold `#8C99A6`): การ์ด **275w** `bg-white/5 border-white/20 rounded-[8px] px-2 py-3` — title 14 Medium nowrap + sub 12/15 `#8C99A6`; เลื่อนนอน + scrollbar pill h-6 `white/20`
- **"All Categories"**: grid 2 คอลัมน์ gap-8; tile **148×82** `bg-white/5 border-white/20 rounded-[8px]` — icon chip 32 วงกลม tint 20% + label 12/15 Medium ขาว
  Getting Started (ฟ้า) / Virtual Office (เขียว) / Account (ม่วง) / Chat (navy) / Billing (ส้ม)

### 3.3 Search Results

- Heading **"Search Results"** 14 Bold `#8C99A6`; list gap-12
- Card 304w: thumbnail **80×80 rounded-[8px]** (+overlay ดำ 20%) + คอลัมน์: category label 12/15 Medium `#58D68D` + title 14/18 Medium ขาว
- **Match highlight:** ตัวที่ตรง query → text `#FF8000` + rect `rgba(255,128,0,0.2)` หลังตัวอักษร

### 3.4 Category List

- Breadcrumb (back + ชื่อหมวด) → **"Search in this category..."** input → **"Select an article to read:"**
- Card: thumb 80×80 + title 14 Medium (2 บรรทัด) + row Calendar icon 16 + date 12/15 `#8C99A6` (`Oct 24, 2026` format)
- Scrollbar แนวตั้ง 6px pill `white/20`; **หน้านี้ไม่มี footer** Need more help

### 3.5 Article Detail + Feedback

- Hero image **304×140 rounded-[8px]** → title **16/22 Bold** → date row
- **Body card** `bg-[#2B3540] rounded-[8px] p-2 gap-6`: intro ขาว 14/18 + numbered steps (เลข `#58D68D` + ข้อความขาว, gap-12)
- **Tips card** `bg-[#2B3540] rounded-[8px] px-2 py-3`: Lightbulb 16 + **"Tips:"** Bold + ต่อด้วยข้อความ Regular
- **Feedback footer:** divider → **"Was this article helpful?"** (12/15 ขาว) → ปุ่มคู่ flex-1 h-32 (ThumbsUp **"Helpful"** / ThumbsDown **"Not helpful"**)
- หลังกด → สลับเป็น: วงกลม 32 `bg-[#58D68D]/20` + check เขียว 24 + **"Thank you for your feedback!"** 14/18 `#58D68D`

### 3.6 Empty State (SC-UG-05)

- Illustration กล่อง+? **100×100** (asset export จาก Figma → R2)
- **"No results found"** 16/22 Medium ขาว / **"No content found for"** `#8C99A6` + **"{query}"** ขาว
- **Popular Articles card** `bg-[#2B3540] rounded-[8px] px-2 py-3`: head **"Popular Articles:"** 12/15 `#8C99A6` + ลิงก์ 14/18 Medium `#58D68D`: `Internet connection issues` / `How to enable Mic and Camera` / `Basic space configuration`
- ปุ่ม **"Report issue about "{query}""** (h-32 ghost, Send icon 16) → Contact form + Topic auto-fill `Cannot find "{query}" in Articles`

---

## 4. SC-UG-07/08 — Contact Support Form + My Tickets

### 4.1 Form (ใน panel shell เดิม, breadcrumb "Contact Support / Report Issue")

- **Info banner:** `bg-[rgba(45,182,255,0.1)] border-[rgba(45,182,255,0.2)] rounded-[8px] p-2` Info icon 16 + 14/18 `#2DB6FF`: **"The system will automatically attach your current URL, Browser (Chrome), and OS for faster investigation."** *(Browser/OS render ตามจริงจาก userAgent)*
- **Label:** 14/18 ขาว + ` *` `#F03A3A` · **Input:** h-42 / **Textarea:** h-100 — `bg-[#242B32] border-white/20 rounded-[8px] px-3 py-2` placeholder `#636D76` · **Counter:** 12/15 — ตัวเลขปัจจุบันขาว `/max` `#8C99A6`
- **Dropdown menu:** `bg-[#242B32] p-2 rounded-[16px]` + Menu shadow; item min-h-42 p-3 rounded-[8px] 14/18 ขาว (hover `bg-white/10`)

| Contact Type | Fields |
|---|---|
| `Report an Issue (Bug Report)` | + **Impact on Usage*** (`Cannot use at all (e.g., white screen)` / `Partially usable (e.g., no mic)` / `Annoyance / Visual Glitch`) · Topic placeholder `Summarize the issue` · Description placeholder `Describe the issue... (If possible, Please include step to reproduce so we can fix it faster)` · Attachments ✓ |
| `Suggest a Feature (Feature Request)` | Topic `summarize your idea` · Description `Describe the feature you want us to add or your idea...` · Attachments ✓ |
| `General Feedback` | Topic `summarize the issue` · Description `Describe the issue you encountered or what you need help with...` · Attachments ✓ |
| `Contact Support` (UG-08) | **Send-to strip** (`rounded-[8px] bg-white/5 p-2`: "Send to" 12 `#8C99A6` + `support@zyra.app` 14 `#58D68D`) · label แรกเป็น **Subject*** placeholder `summarize the issue` · Description `Tell us what happened or what you need help with...` · **ไม่มี Attachments** |

- **Attachments (Optional):** drop area `w-full h-[58px] bg-white/5 rounded-[8px]` center **"No file upload"** 14 Medium; helper **"Supports JPG, PNG up to 5MB"** 12/15 `#8C99A6`
  Uploaded state: card แถว — icon tile ไฟล์ + ชื่อ `Avatar.png` + `Size: 1 mb` + `• Completed` เขียว + Trash2 แดงขวา
- **Send Message:** w-full h-32 rounded-[6px] Send icon 16 + label 14/18 — disabled `bg-[#DBDFE3] border-[#B2BBC3] text-[#A3ADB8]` → enabled `bg-[#58D68D]` ขาว

### 4.2 Toasts (368w, `bg-[#1A1B1E] rounded-[16px] p-4`, มุมขวาบน — ใช้ `zyraToast`)

| Toast | Icon tile | Title / Body |
|---|---|---|
| Error | 40×40 `bg-[rgba(240,58,58,0.2)]` X แดง | **"Upload failed"** / "The selected file exceeds the 5 MB size limit." |
| Success | 40×40 `bg-[rgba(88,214,141,0.2)]` check เขียว | **"Message sent! Ticket ID #ZYR-6891"** / "We'll review and respond within 24 hours." |

### 4.3 My Tickets

- Tab **My Tickets** active; heading **"Your Contact History"** 16/22 Bold
- History Card 304w `bg-white/5 border-white/20 rounded-[8px] px-2 py-3` gap-12: `#ZYR-1094` 12/15 Medium `#8C99A6` → title 14/18 Medium ขาว → Calendar 16 + date 12/15 `#8C99A6`
- Empty state: ไม่มี design — ใช้ pattern §3.6 (illustration + "No tickets yet")

---

## 5. SC-UG-06 — New Feature Walkthrough Modal

### 5.1 Modal (600w, centered บน overlay ดำ 50%)

```
┌ 600w · bg #242B32 · rounded-[16px] · Menu shadow ──────────────┐
│ Header p-4 justify-between:                                     │
│  [STEP n OF 5]  badge bg #255A3B rounded-[20px] px-3 py-1.5     │
│                 12 SemiBold #58D68D uppercase                   │
│  Skip tour      14/18 Medium #8C99A6                            │
│ Hero 568×260 rounded-[16px] (px-4)                              │
│ Meta row px-4 py-6 gap-2: icon chip 28 bg #58D68D "✦"           │
│  + tag "Virtual Pets" (bg/border rgba(140,153,166,0.1)          │
│    rounded-[4px] px-2 py-1, 14 Bold ขาว)                        │
│  + "Zyra Product Team · Oct 24, 2026" 14/18 #8C99A6             │
│ ── divider white/20 ──                                          │
│ Title p-4: 16/22 Bold #58D68D                                   │
│ Body px-4 pb-6: 14/18 Regular ขาว                               │
│ Footer px-4 py-6 border-t justify-between:                      │
│  dots ×5 (active pill 22×8 #58D68D)                             │
│  [Back ghost (step 2-5)] [Next → / Let's Go! primary]           │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 ตัวอย่าง copy (Virtual Pets — example content เท่านั้น)

| Step | Title | Body |
|---|---|---|
| 1 | `Meet Your New Office Buddy! 🎉` | `Work is better with a companion. We're excited to introduce Virtual Pets to your Zyra workspace!` |
| 2 | `How to Adopt` | `Open your profile settings and click on the new 'Pets' tab. Choose from a dog, cat, bunny, or even a tiny dragon!` |
| 3 | `They Follow You Everywhere` | `Once equipped, your pet will happily trail behind your avatar as you walk around the virtual office.` |
| 4 | `Interactive Reactions` | `Press 'P' on your keyboard to pet them, or watch them react with cute animations when you enter a meeting zone.` |
| 5 | `Ready to Find Your Pet?` | `Your new virtual companion is waiting. Head over to your profile and pick your favorite one now!` — ปุ่ม **Let's Go!** |

Success modal: shell 458×332 เดียวกับ §2.3 — **"You're all set!"** / **"Go find your new furry friend in Zyra."** / ปุ่ม secondary **"Back to Office"**

---

## 6. Motion

- เปลี่ยนหน้า onboarding/walkthrough: fade + slide เล็กน้อย (reference sticky: https://gemini.google.com/share/6c3cd8e9d3e9) — เสนอ `transition duration-300 ease-out`, เนื้อหาเก่า fade-out/ใหม่ fade-in + translateX 16px
- Modal เปิด/ปิด: scale 0.96→1 + fade 200ms; panel Help Center: slide-in จากขวา 250ms
- Progress bar: `transition-[width] duration-500`
- Feedback state swap + Send success: fade 200ms

## 7. Icons (lucide-react ทั้งหมด — rule 12)

Rocket (Getting Started) · Hand (Welcome) · LayoutTemplate/Building (Office Setup) · UserPlus (Invite) · Move/Gamepad2 (How to Play) · Check / CheckCircle · AlertCircle (warning) · X · CircleHelp (?) · Search · Pin · FolderOpen ฯลฯ (category icons) · ArrowLeft · ArrowRight · Calendar · Lightbulb (Tips) · ThumbsUp / ThumbsDown · Mail · Send · Info · ChevronDown · Trash2 · Sparkles (✦)

## 8. Assets ที่ต้อง export จาก Figma → R2

| Asset | ขนาด | ใช้ที่ |
|---|---|---|
| Onboarding hero illustrations + product screenshots ×7 | 688×260 | UG-01 |
| Zyra "Z" logo 80×80 | — | Welcome |
| Empty-state box illustration | 100×100 | UG-05, My Tickets empty |
| Article thumbnails / hero ตัวอย่าง | 80×80, 304×140 | UG-04 |
| Feature tour hero (ต่อ announcement) | 568×260 | UG-06 |
| Email banner "Zyra — Work to Zyra" | — | zyra-notifications templates |
