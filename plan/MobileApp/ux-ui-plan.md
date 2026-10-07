# Mobile App — UX/UI Plan (ถอดจาก Figma)

> **สถานะ:** กำลังทยอยรับ UI จาก design ทีละ subtask — HP-03 · Virtual Office ครบ (§0–7, Ten ตอบแล้ว 10/12) · **HP-04 · Meeting (Video/Audio) ครบ (§8, Ten ตอบแล้ว 8/10 — ค้างข้อ 9–10)** · **HP-05 · Chat ครบ (§9, Ten ตอบแล้ว 11/12 — ค้างข้อ 1)** · **HP-06 · Sidebar & Navigation ครบ (§10, แนวนอนไม่มี bottom bar · Ten ตอบแล้ว 5/8 — ค้างข้อ 5, 7, 8)** · **HP-07 · Install & Onboarding ครบ (§11 — แนวตั้งอย่างเดียว · Ten ตอบครบ 10/10)** · **HP-08 · Push Notifications ครบ (§12 — Ten ตอบครบ 10/10 · เพิ่มหน้าขอ Allow §12.6)** · **HP-09 · Camera & Mic Permissions ครบ (§13 — Ten ตอบครบ 7/7 · เพิ่ม pre-permission §13.6)** · **HP-10 · Offline / Poor Connection ครบ (§14 — Ten ตอบครบ · เสนอ icon §14.7 + หน้า skeleton §14.8)** · **EP-01 · Performance Fallback ครบ (§15 — แนวนอนเท่านั้น · Ten ตอบ 9/9 · เสนอเมนู Performance §15.7)** · **EP-02 · Bandwidth / Audio-Only Fallback ครบ (§16 — Ten ตอบครบ 8/8)** · **EC-03 · Screen Size ครบ (§17 — phone 390/430 + iPad 744/1024 · tablet ใช้ UI มือถือ · Ten ตอบครบ 11/11)** · **HP-11 · Spotlight ครบ (§18 — แนวตั้ง presenter อย่างเดียว · แนวนอนตามข้อเสนอ §18.6 · Ten ตอบครบ 14/14)** · ลิงก์ Figma ที่ Ten ส่ง 2026-10-01 ตรงกับ node ที่ดึงไว้ · **มติ: เลือกโหมดเองใน Settings, Lite ไม่โหลด engine, Lite user = ghost ใน meeting** · ยังไม่แตะโค้ด · **repo:** zyra-app (Phase 0–1)
> **ไฟล์ Figma:** `Map8gX0L2hk7HnkaFRfhtj` — Zyra design (More Organised ver.) · ลิงก์ node = `https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=<id>` (แทน `:` ด้วย `-`)
> **กติกา:** ทุกค่าในไฟล์นี้ดึงจาก Figma MCP (`get_design_context` / `get_metadata` / `get_variable_defs`) ไม่ได้เดา · ค่าที่ยังไม่ได้ดึงระดับ px จะติด 🔍 · จุดที่ขัดกับมติ/โค้ด/ClickUp ติด ⚠️ และรวมไว้ในหัวข้อคำถามของแต่ละ subtask (§7 / §8.6 / §9.6)
> **เอกสารคู่กัน:** [open-items.md](open-items.md) (checklist UI ที่ขาด / คำถามค้าง) · mockup UI ที่ยังไม่มีใน Figma: https://zyra-mobile-ui-proposals.vercel.app · [spec.md](spec.md) · [screens.md](screens.md) · [technical-design.md §16](technical-design.md) · [clickup-spec.md §3 HP-03](clickup-spec.md)

## Assets ที่เตรียมไว้ (R2 dev bucket `zgather-dev` · อัปโหลด 2026-10-02)

| ไฟล์ | ใช้ที่ | URL |
|---|---|---|
| `zyra-logo.svg` (160×160 · โลโก้ Zyra World ตัว Z สีเขียว `#58D68D` พื้นใส) | ไอคอนแอป · โลโก้ header · splash / login | https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/mobile-app/zyra-logo.svg |
| `spotlight-celebrate.png` (1304×640 · ตัวละคร 3 ตัว + spotlight) | sheet ติดตั้ง PWA · หน้าที่เกี่ยวกับ Spotlight / ฉลอง | https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/mobile-app/spotlight-celebrate.png |
| `mascot-sparkle.png` (424×528 · ตัวละครกอดหมอน Z) | empty state (~~หน้า Coming soon~~ ตัดแล้ว §19.7) | https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/mobile-app/mascot-sparkle.png |

- key `static/mobile-app/<ชื่อไฟล์>` ตาม rule 11 · `Cache-Control: public, max-age=31536000` · ต้นฉบับอยู่ที่ `demo file/img 2/` และสำเนาใน `zyra-doc/web/mobile-ui-proposals/img/`
- **ยังไม่ได้อัปขึ้น bucket ของ prod** — ทำตอน implement / release ตามขั้นตอน deploy (rule 06) · ถ้าเปลี่ยนไฟล์ ให้ใช้ชื่อใหม่ (cache 1 ปี)

## 0. สรุปสั้น — HP-03 บอกอะไร

Figma HP-03 ไม่ได้มีแค่หน้าแมพ แต่เป็น **flow ทั้งเส้นตั้งแต่เปิดแอปจนเข้าออฟฟิศ** แบ่ง 2 แถวชัดเจน:

| แถวใน Figma | หมายถึง | เริ่มที่ | จบที่ |
|---|---|---|---|
| **Browser** | เว็บบนมือถือ (Phase 0 ของเรา) | Landing page → Login (Google / Mail) | Lite Home หรือ Spatial map |
| **App – Log in with email** | แอป Capacitor (Phase 1) | Splash → Onboarding 3 slide → Get started (Google / Apple / Email) | Lite Home หรือ Spatial map |

ทั้งสองแถวใช้หน้ากลางร่วมกัน: **Space builder (รายการ workspace) → Select workspace mode → (Keep This Setting?) → (Rotate your phone…) → Lobby → Connecting (tips) → Home**

**สิ่งสำคัญที่ต่างจากที่เราเคยเขียนไว้ใน spec/TD §16 (✅ Ten ยืนยันแล้ว ดู §7):**
1. **โหมดไม่ได้สลับอัตโนมัติตาม orientation** — ผู้ใช้ **เลือกโหมดเอง** ที่หน้า "Select workspace mode" หลังเลือก workspace · ระบบจำค่าไว้ (1 วัน หรือ ตลอด) · เปลี่ยนได้ใน Settings
2. ถ้า orientation ของเครื่องไม่ตรงกับโหมดที่เลือก → **หน้าเต็มจอ "Rotate your phone to use Lite/Spatial Mode."** บล็อกไว้ ไม่ใช่สลับโหมดให้
3. **Lite Mode = หน้า Home แบบ list** (workspace header, Start spotlight / Instant meeting, ค้นหา, ห้องประชุมที่กำลังมีคน, Circle, รายชื่อ Online/Offline) + bottom nav 4 ปุ่ม **ไม่มีแมพเลย**
4. **Spatial Mode = แมพเต็มจอแนวนอน** + joystick ซ้ายล่าง + แถบ mic/cam/leave กลางล่าง + minimap ขวาล่าง + ปุ่มกลม 5 ปุ่มขวาบน (weather, spotlight, calendar, members, notifications) + ปุ่ม chat ซ้ายล่าง · **ไม่มี bottom nav**

## 1. Design tokens ที่ใช้ทั้ง flow (จาก `get_variable_defs`)

| Token | ค่า | ใช้ที่ |
|---|---|---|
| Shade Black/500 | `#1A1B1E` | พื้นหลังหน้าแอป, ปุ่มกลมบนแมพ |
| Shade Black/400 | `#232427` | bottom sheet, card ห้องประชุม, แถบ meeting บนแมพ |
| Theme colour/Primary | `#242B32` | พื้นหลังหน้า Rotate, name tag คนอื่นบนแมพ |
| Primary/500 | `#58D68D` | ปุ่มหลัก, border card ที่เลือก, progress bar (gradient → `#8FE4B3`) |
| Primary/700 | `#3E9864` | — |
| Purple/500 | `#996ADF` | name tag ตัวเอง, สถานะ "In meeting" |
| Blue/500 | `#2DB6FF` | alert banner (bg 10%, border 20%) |
| Red/500 | `#D41818` | badge count, Leave (bg `rgba(212,24,24,0.2)`) |
| Red/500 (อีกชุด) | `#F03A3A` | badge "Locked" |
| Grey/500 | `#8C99A6` | ข้อความรอง |
| Grey/700 | `#636D76` | placeholder |
| Grey/400 / 300 / 100 | `#A3ADB8` / `#B2BBC3` / `#DBDFE3` | ปุ่ม disabled (bg `#DBDFE3`, border `#B2BBC3`, text `#A3ADB8`) |
| Solid White 5% / 20% | `rgba(255,255,255,0.05/0.2)` | card bg / border, bottom nav active pill |
| Sub/Medium · Sub/Regular · Sub/Bold | Inter 16/22 (500 / 400 / 700) | หัวข้อ, ปุ่ม |
| Body/Regular · Body/Medium · Body/Bold | Inter 14/18 (400 / 500 / 700) | ข้อความทั่วไป |
| Caption 1/Regular · Medium | Inter 12/15, letter-spacing −0.43 | ข้อความรอง, name tag |
| Caption 2/Medium | Inter 10/14 | ข้อความใน toast |

ตรงกับ comment P A ใน ClickUp (font 14 ปกติ / เล็กสุด 10 / ใหญ่สุด 24, ปุ่ม 42, field 42) · ยังไม่เห็น 24px ใน section นี้

## 2. Flow ทั้งเส้น (ลำดับตามลูกศรใน Figma)

### 2.1 แถว App (Phase 1 — Capacitor)

```
Splash (6411:1142334)
 → Onboarding slide 1/2/3 (6280:611495 · 6295:612028 · 6295:612036)
 → Get started = Login (6075:21550 · 6075:21604)
 → Space builder – Empty (6075:21508) / Fill (5889:415855)
 → Select workspace mode (6392:1128974 → เลือกแล้ว 6392:1128982 / 6396:1129252)
 → Keep This Setting? bottom sheet + spinner (6407:1129791)
 → [orientation ไม่ตรง] Rotate your phone to use Spatial Mode (6387:1128830 / 6396:1129324)
 → Lobby แนวนอน "Welcome to <workspace>" (6387:1127419)
 → Connecting to workspace ×5 tips (5889:424245 … 5889:424338 · แนวนอน 6387:1128442 / 6396:1129328)
 → Lite: Homepage (5800:425090) → เลื่อนแล้ว Homepage – Slide (5873:360244)
 → Spatial: Worksapce – Horizon (6707:63977 / 6707:64139)
```

### 2.2 แถว Browser (Phase 0 — mobile web)

```
Mobile landing page (6382:35915 · 6382:37357)   ← เว็บการตลาด
 → Login – Vertical (6382:44512)  [Google / Mail เท่านั้น ไม่มี Apple]
 → Space builder Empty/Fill (6382:1126070 / 6382:1126301)
 → Worksapce mode – Vertical = Select mode (6382:1126494 · 6382:1126744 · 6382:1126786 · 6511:135083)
 → Rotate (6387:1128830) → Lobby (6387:1127419) → Connecting → Homepage (6387:1126917)
```

แนวนอน (section 6511:44108) มีชุดเดียวกันในเวอร์ชัน 844×390: Website – Horizon (6511:44022, เมนู hamburger เปิด 6511:44070), Login – Horizon (6511:50525), Space builder – Horizon (6511:50701 / 6511:133636), Worksapce mode – Horizone (6511:134636 / 6511:134638 / 6511:134681), Keep This Setting แนวนอน (6511:135032), Rotate to Lite (6511:137151), Worksapce – Horizon (6696:60848 / 6696:61010)

## 3. หน้าต่อหน้า — spec

### 3.1 Splash + Onboarding (App เท่านั้น)

| หน้า | Node | เนื้อหา |
|---|---|---|
| Splash | 6411:1142334 | โลโก้ Z กลางจอ พื้น `#1A1B1E` (ClickUp บอก 2 วินาที) |
| Slide 1 | 6280:611495 | วงกลม placeholder 200×200 ที่ (95,222) · หัวข้อ "Real-Time Collaboration Starts with One Workspace." (358×117) · คำอธิบาย "See your teammates avatars, move between spaces, and communicate in context. Everything happens where you are, not where you've been" · progress dots 40×4 · ปุ่ม 358×40 ที่ y=780 |
| Slide 2 | 6295:612028 | "Everything You Need to Collaborate, All in One Space" · "Chat, meet, and share instantly—everything you need to collaborate happens in one seamless space." |
| Slide 3 | 6295:612036 | "Transform Your Workspace Into a Place People Love" · "Raise your pet, collect achievements, and watch your workspace come alive with personality and joy." |

- ภาพประกอบยังเป็นวงกลมเทา (placeholder) ทั้ง 3 slide 🔍
- ⚠️ ClickUp HP-07 ระบุ slide เป็น "Virtual Office / Meeting (AI Summary) / Team Features (Quiz, Poll, Tarot)" — Figma ใช้ copy คนละชุด (ไม่มี AI Summary / Quiz / Poll / Tarot) → ยึด Figma

### 3.2 Get started / Login

| | App (6075:21550) | Browser แนวตั้ง (6382:44512) | Browser แนวนอน (6511:50525) |
|---|---|---|---|
| ปุ่ม social | **Continue with Google** + **Continue with Apple** | Continue with Google + Continue with Apple + Continue with Mail | Continue with Google + Continue with Mail (ไม่มี Apple → **เพิ่ม Continue with Apple** ตาม §7 ข้อ 11) |
| ฟอร์ม | Email / Password (มี eye toggle) + Forget password + **Sign in** เขียว | ไม่มีฟอร์มบนหน้าแรก (Mail → หน้าถัดไป) | เหมือนแนวตั้ง |
| อื่น ๆ | มาสคอตอวตารเหนือหัวข้อ "Welcome to Zyra World" | โลโก้ Z, ตัวเลือกภาษา EN มุมขวาบน, card ซ้อนพื้นหลังเมืองกลางคืน | card 844 กว้าง ต้อง scroll (frame 844×664) |
| ลิงก์ | Sign up · Terms of Services · Privacy Policy (สีเขียว) | เหมือนกัน | เหมือนกัน |

- ตรงกับ SC-MOB-01 (Google native + Apple) และ inventory B1/B2
- ⚠️ Apple บน Browser แนวตั้งมี แต่แนวนอนไม่มี — น่าจะเป็น Figma ยังไม่อัปเดต ต้องถาม

### 3.3 Space builder (รายการ workspace)

| State | Node | รายละเอียด |
|---|---|---|
| Empty แนวตั้ง | 6382:1126070 / 6075:21508 | header โลโก้ 40 + avatar 40 · หัวข้อ "Space builder" + ปุ่ม `+` เขียว 40×40 · ช่องค้นหา "Search for your workspace" + ปุ่ม filter · illustration กล่องว่าง + "No workspaces created" + "Let's create workspace to work or gather with your team." + ปุ่ม "+ Create workspace" |
| Fill แนวตั้ง | 6382:1126301 / 5889:415855 | list card 1 คอลัมน์: thumbnail แมพ 64×64 · ชื่อ · "Last visited : Sep 18, 2025 (13:00 PM)" · badge role (Owner ส้ม / Admin ฟ้า / Member เขียว) · `15/50` (สมาชิก) · `● 10` (ออนไลน์) · เมนู ⋮ |
| แนวนอน | 6511:50701 / 6511:133636 | เหมือนกันแต่ card **2 คอลัมน์** |

- ตรงกับ `views/user/workspace/hero-user-workspace.tsx` (screens.md B) — grid 2 คอลัมน์ในแนวนอนตรงกับโค้ดเดิม (`:439,472`)
- ⚠️ ชื่อหน้าใน Figma คือ "Space builder" แต่ในโค้ด/ClickUp EC-01 "Space Builder" หมายถึง editor วางของ (desktop only) — ต้องเคลียร์ชื่อ

### 3.4 Select workspace mode ★ (หน้าใหม่ ไม่มีในโค้ด)

**Node:** symbol 6392:1128974 · เลือก Lite 6392:1128982 · เลือก Spatial 6396:1129252 · แนวนอน 6511:134636 (844×840 → scroll)

| ส่วน | Spec |
|---|---|
| พื้นหลัง | `#1A1B1E` (App) / รูปเมืองกลางคืน (Browser 6382:1126494) |
| Header | โลโก้ 40×40 ซ้าย + avatar 40×40 (`#7EA2FC`, ตัวย่อ) ขวา · `left:16 top:16 w:358` |
| เนื้อหา | container `left:16 top:80 w:358` flex-col gap 24 |
| **ปุ่ม back (UI อัปเดต 2026-10-05)** | Figma `6392-1128982` เพิ่มปุ่มแรกในคอลัมน์เนื้อหา **เหนือหัวข้อ**: 32×32 bg white 5% p 8 radius 8 icon chevron-left 16 · แตะ = กลับหน้าก่อน (Space builder / หน้าที่เปิดมา) · ที่เหลือของหน้าเหมือนเดิมทุกค่า (ตรวจด้วย `get_design_context` แล้ว) |
| หัวข้อ | "Select workspace mode" Sub/Medium ขาว · "Choose the view that fits your workspace experience." Body/Regular `#8C99A6` gap 8 |
| Alert banner | "You can change this anytime in Settings" · bg `rgba(45,182,255,0.1)` border `rgba(45,182,255,0.2)` radius 8 p 8 gap 8 · icon info 16 · text `#2DB6FF` 14/18 |
| Card ("Mode madal") ×2 | bg `rgba(255,255,255,0.05)` border `rgba(255,255,255,0.2)` **radius 16 p 16 gap 16** · เลือกแล้ว border → `#58D68D` |
| ใน card | แถวบน: วงกลม placeholder 56×56 + radio 16×16 (ขวา) · ชื่อโหมด Sub/Medium ขาว · คำอธิบาย Body/Regular `#8C99A6` · กล่องดำ bg `#1A1B1E` radius 8 p 16 gap 8 w 324: วงกลม 24 + ข้อความ 14/18 ขาว |
| Lite Mode card | "A simple vertical view for quick conversations." · "Use for checking messages, quick meetings, focus work" |
| Spatial Mode card | "A wider horizontal view for immersive interaction." · "Use for exploring spaces, avatar movement, team sync." |
| ปุ่ม Confirm | `left:16 top:786 w:358 h:42` radius 8 px 16 py 8 · **ยังไม่เลือก = disabled** bg `#DBDFE3` border `#B2BBC3` text `#A3ADB8` · เลือกแล้ว bg `#58D68D` text ขาว 16/22 |

**พฤติกรรม (จากลูกศร + sticky note 6407:1130011):**
- กด Confirm → เปิด **bottom sheet "Keep This Setting?"** (6407:1129791) พร้อม overlay `rgba(0,0,0,0.5)` blur 6 + spinner 40 กลางจอ
- Bottom sheet: bg `#232427` radius บน 24 p 16 gap 16 · หัวข้อ Sub/Bold · ปุ่ม Cancel 16 มุมขวาบน (358,16) · กล่อง radio bg white 5% radius 16 p 16 · 2 ตัวเลือก (แต่ละแถว min-h 42 p 12 gap 8 radio 16 + text 14/18):
  - **Remind me again** (default) — sticky: *"จะจำค่านี้ไปตลอด 1 วัน และจะเป็นไปทุก Workspace เพียงแค่ 1 วัน พรุ่งนี้ก็จะถามอีก"*
  - **Always** — sticky: *"จำค่านี้ไปตลอด สามารถแก้ไขได้ภายหลัง"*
  - ปุ่ม Confirm เขียว h 42 เต็มกว้าง
- หลัง Confirm → ถ้า orientation ไม่ตรง → §3.5 · ถ้าตรง → Lobby §3.6

### 3.5 Rotate your phone (หน้าบล็อกเมื่อ orientation ไม่ตรงโหมด)

| Node | ข้อความ | เมื่อไหร่ |
|---|---|---|
| 6387:1128830 / 6396:1129324 (แนวตั้ง 390×844) | "Rotate your phone to use Spatial Mode." | เลือก Spatial แต่ถือเครื่องแนวตั้ง |
| 6511:137151 (แนวนอน 844×390) | "Rotate your phone to use Lite Mode." | เลือก Lite แต่ถือเครื่องแนวนอน |

Spec: พื้น `#242B32` · container 326 กว้าง กลางจอ p 16 radius 16 gap 8 · วงกลม placeholder 56 (ไอคอนยังไม่มี 🔍) · ข้อความ Body/Regular ขาว center

⚠️ นี่คือจุดที่ต่างจาก technical-design §16 ที่เราวางว่า "หมุนแล้วสลับโหมดทันที" → ดู §7 ข้อ 1

### 3.6 Lobby (pre-join) — มีแต่แนวนอน

**Node:** 6387:1127419 (iPhone 13 & 14 – 9, 844×390)
- โลโก้ซ้ายบน, avatar ขวาบน · หัวข้อกลาง "Welcome to Starlight world"
- ซ้าย: กล่อง preview กล้อง "Your camera is off" + ปุ่ม cam/mic สีแดง (ปิดอยู่) 2 ปุ่ม
- ขวา: "Character name" + input "Input character name" · ตัวละคร + ปุ่ม "Change character" · ปุ่ม **Join space** เขียวเต็มกว้าง
- ล่าง: "By joining space, you agree with Terms of Services and Privacy Policy"
- ตรงกับ `views/user/workspace-enter/hero-workspace-enter.tsx` (screens.md B) จัด 2 คอลัมน์
- ⚠️ ไม่มี Lobby แนวตั้งใน HP-03 → ดู §7 ข้อ 5

### 3.7 Connecting to workspace (loading + tips)

**Node:** symbol 5889:424245 (+ 4 variant) · แนวนอน 6387:1128442 / 6396:1129328 / 6511:44842 / 6511:137489
- พื้นหลัง: ภาพออฟฟิศ + overlay `rgba(43,53,64,0.5)` ทับบน `#1A1B1E`
- กล่อง LoadingTips กลางจอ **w 360** flex-col gap 16: รูป 194 สูง radius 16 · กล่อง tips bg `rgba(0,0,0,0.2)` radius 8 p 8 ("**Tips:** " Body/Bold + ข้อความ Body/Regular) · progress bar h 4 radius 90 bg white 20% fill gradient `#58D68D → #8FE4B3` · "Connecting... 30%" Body/Regular center
- Tips 5 ข้อ (สลับตามลำดับ):
  1. Walk up to teammates to start a conversation instantly by circle.
  2. Use Threads in Chat to keep discussions organised and easy to revisit.
  3. Follow teammates around the map to stay in sync.
  4. Check status to know who's Available before reaching out.
  5. Wave at teammates or send a quick message to spark spontaneous collaboration.
- ตรงกับ `views/user/workspace-enter/hero-workspace-loading.tsx` + `workspace-loading-screen.tsx` (screens.md B) — ขนาดกล่องเดิม 696/580/456 → 360

### 3.8 Lite Mode — Homepage ★ (หน้าใหม่)

**Node:** symbol 5800:425090 · เลื่อนแล้ว 5873:360244 · Browser 6387:1126917 / 6511:44793 · พื้น `#1A1B1E` · content `left:16 w:358`

| ส่วน | Spec |
|---|---|
| Header | โลโก้ workspace 40 + **"Starlight Workspace ⌄"** Sub/Medium (chevron 16 = workspace switcher) · ใต้ชื่อ: icon member 14 + "100 Members" · จุดเขียว + "50 Online" (Caption 1 `#8C99A6`) · ขวา: ปุ่ม **user-plus 24** (invite) + **กระดิ่ง** พร้อม badge แดง "10" (`#D41818` radius 90, offset −4) |
| ปุ่มคู่ | **Start spotlight** (icon megaphone) + **Instant meeting** (icon video, bg `#58D68D`) · แต่ละปุ่ม flex-1 h 42 radius 8 px 16 py 8 gap 8 · ปุ่มซ้าย bg white 5% border white 20% · text Sub/Regular · **UI อัปเดต 2026-10-05 (Figma `6275-611019`): Start spotlight เป็นปุ่ม icon อย่างเดียว 42×42** (bg white 5% border white 20% p 8 radius 8 icon megaphone 16 ไม่มีข้อความ) ซ้าย · gap 8 · **Instant meeting ยาวที่เหลือ (308 ที่ 358)** bg `#58D68D` px 16 py 8 gap 8 icon video 16 + Sub/Regular 16/22 ขาว |
| Search | input w 305 h 42 "Search for members or meeting rooms" placeholder `#636D76` + ปุ่ม filter 42 |
| Section "In meeting" | หัวข้อ Body + chevron-up (พับได้) · **Meeting room card**: bg `#232427` border white 5% radius 8 p 12 gap 16 · ชื่อ "Meeting hall 01" Body/Medium · "Meeting room • 70 participants" Caption 1 `#8C99A6` · avatar stack 24 ×4 + "+10" · badge **Locked** (bg `#F03A3A` radius 90 p 4 icon lock 14) สำหรับห้องล็อก |
| Section "Circle" | หัวข้อ + chevron · แถว avatar cluster (วงกลมสีน้ำตาล ~48) แสดงกลุ่มคนที่กำลังคุยกันเป็น circle บนแมพ · มี "+10" |
| Section "Online (50)" | **Member list – Mobile** แถวสูง 56 px 16 py 8 radius 8 gap 8 · avatar 40 (มี status dot) · ชื่อ Body/Medium · บรรทัดรอง Caption 1: "Active" / "Busy" / custom status "🚨 If have any urgent CALL ME" / "Active • 📅 In meeting" (`#996ADF`) |
| Section "Offline (5)" | เหมือน Online แต่ avatar จาง ข้อความ "Offline" |
| **Bottom nav** | pill กลางล่าง: **Home · Chat · Calendar · Profile (avatar รูปตัวเอง)** (รอบแรกซ่อน Calendar — §10.6 ข้อ 7) · แต่ละปุ่ม "Menu side bar" w 40 p 8 icon 24 · active = "Sup bottom bar" bg white 20% radius 90 p 8 · badge count แดงบน Chat · **icon-only ไม่มี label** (ตรง comment P A) |
| Bottom nav ตอนเลื่อน (Homepage – Slide) | sticky 5800:423437: *"กรณีมีการเลื่อน Bottom bar จะมีขนาดเล็กลง"* → bar h **48** bg `rgba(26,27,30,0.5)` radius 1000 p 4 `left/right: 10.26%` · active pill 75.5×40 |

Sticky 6714:163081: *"เปลี่ยนปุ่มจาก Create schedule & Instant meeting เป็น Start spotlight & Instant meeting — Create schedule ไปสร้างในเมนู Calendar ได้ แต่ Spotlight ไม่มีที่ให้อยู่แล้ว"* → ยืนยันปุ่มคู่บนสุดคือ Start spotlight + Instant meeting

สิ่งที่ Lite Home **ไม่มี**: แมพ, joystick, minimap, status picker (ยังไม่เห็น), ปุ่ม settings (น่าจะอยู่ใน Profile tab 🔍)

### 3.9 Spatial Mode — Worksapce – Horizon ★ (แมพแนวนอน)

**Node:** 6707:63977 (base 6511:146255) · 6707:64139 · 6696:60848 / 6696:61010 · 844×390

| ส่วน | ตำแหน่ง / Spec |
|---|---|
| Map | รูปแมพ 844×619 กลางจอ (offset −67.5 แนวตั้ง) — ใน Figma เป็นรูปนิ่ง ของจริงคือ PixiJS canvas |
| Avatar + name tag | name tag radius 6 p 4 gap 4 · status dot 10 · ชื่อ Caption 1/Medium ขาว · **ตัวเอง** bg `#996ADF` w 140 · **คนอื่น** bg `#242B32` · avatar 27×40 |
| **Joystick** | `left:88 top:234` ขนาด **128×140** (SVG วงกลมโปร่ง + ปุ่มกลาง) — ตรง task 0.3 · ClickUp HP-03 บอก 100×100 ⚠️ |
| ปุ่ม Chat | วงกลม 32 bg `#1A1B1E` `left:32 top:342` icon 16 |
| **Meeting Menu** (กลางล่าง) | bg `#232427` radius 16 p 8 gap 8 `bottom:16` center · avatar ตัวเอง 32 + status · ปุ่ม cam-off 24 (p 8 radius 8) · mic-off 24 · divider · **Leave** icon แดง bg `rgba(212,24,24,0.2)` |
| **Minimap** | `right:32 bottom:16` **169×100** bg `#1A1B1E` radius 16 · กรอบห้อง border white 20%/10% radius 4 · จุดสถานะตัวเอง 6 · avatar cluster 6px |
| ปุ่มขวาบน | `right:32 top:16` gap 8 วงกลม 32: **Weather** (gradient `#03AFFF → #BAF1FF` blur 4, icon เมฆ) · **megaphone** (spotlight) · **Calendar** · **member** · **Notifications** — ทุกปุ่ม bg `#1A1B1E` p 8 icon 16 |
| Notification toast (variant `showNotificationToast`) | `top:16` ขวา w 300 bg `#1A1B1E` radius 12 p 8 gap 8 · avatar 32 + ชื่อ Caption 1/Medium + "Wave to you" Caption 2 `#8C99A6` · ปุ่ม 3: wave (white 5%/border 20%), chat (bg ขาว), locate (bg `#58D68D`) radius 6 p 8 icon 16 · progress bar 4px ล่าง (นับถอยหลัง) |
| Display (variant `showDisplay`) | กล่อง **168×158** bg `#232427` border 2 `#58D68D` radius 12 p 4 `top:216` ขวา · avatar 56 กลาง + ป้ายชื่อ "Matthew" (bg black blur radius 8) — น่าจะเป็น tile คนที่กำลังพูด/วิดีโอ 🔍 ถาม §7 ข้อ 7 |

สิ่งที่ Spatial **ไม่มี**: bottom nav, ปุ่ม Home/Profile, status picker, settings, ปุ่ม locate ตัวเอง (มีใน toast เท่านั้น) 🔍

### 3.10 Website landing (แถว Browser — เว็บการตลาด)

**Node:** 6382:35915 / 6382:37357 (แนวตั้ง) · 6511:44022 (แนวนอน) · เมนู hamburger เปิด 6511:44070
- Hero "Real-Time Collaboration Starts with **One Workspace**" (highlight ม่วง) · ปุ่ม "Contact for Demo" + "Create workspace" · section Feature (Virtual office, Real-time chat, Avatar, Screen share, Space builder, Decoration, Team management), 3 steps, testimonial, pricing (Monthly / Yearly Save 20%), FAQ "Ask Me about Zyra", footer (Product / Learn more / Legal), toggle TH/EN
- เมนู hamburger: Feature · About us · Resource · Pricing · Contact us · TH/EN · ปุ่ม Login เขียวเต็มกว้าง
- ⚠️ หน้านี้เป็นเว็บการตลาด (`zyra.center`?) ไม่ใช่ zyra-app → ถาม §7 ข้อ 9

## 4. ตารางเทียบ Lite vs Spatial (จาก Figma จริง)

| | Lite Mode (แนวตั้ง) | Spatial Mode (แนวนอน) |
|---|---|---|
| เข้าถึงยังไง | เลือกที่ Select workspace mode → ถือแนวตั้ง | เลือกที่ Select workspace mode → ถือแนวนอน |
| ถือผิด orientation | "Rotate your phone to use Lite Mode." | "Rotate your phone to use Spatial Mode." |
| หน้าหลัก | Home list (ห้องประชุม / Circle / Online / Offline) | แมพ PixiJS เต็มจอ |
| Navigation | bottom nav 4: Home · Chat · Calendar · Profile → **รอบแรกซ่อน Calendar เหลือ 3** (§10.6 ข้อ 7) | ปุ่มกลม 5 ขวาบน + chat ซ้ายล่าง |
| ประชุม | ปุ่ม Instant meeting / แตะห้องใน "In meeting" | เดินเข้า zone · แถบ mic/cam/leave กลางล่าง |
| Spotlight | ปุ่ม Start spotlight | ปุ่ม megaphone ขวาบน |
| แจ้งเตือน | กระดิ่ง + badge ใน header | ปุ่มกระดิ่งขวาบน + toast 300px |
| ตำแหน่งตัวเองบนแมพ | ไม่แสดง | avatar + name tag ม่วง + minimap |

## 5. ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-09-30 เย็น ตามคำตอบ §7)

| เอกสาร | สิ่งที่ต้องแก้ |
|---|---|
| spec.md "โหมดการแสดงผลบนมือถือ" | เพิ่ม "ผู้ใช้เลือกโหมดเอง + จำค่า 1 วัน/ตลอด" · orientation ไม่ตรง → หน้า Rotate (ไม่ใช่สลับ) · SC-MOB-02 ต้องเขียนใหม่ |
| technical-design.md §16 | §16.1 กลไก `setRenderSuspended` ยังใช้ได้กับหน้า Rotate (บังแมพ) แต่ **trigger เปลี่ยนจาก orientation เป็น mode setting + orientation** · เพิ่ม: เก็บ mode ต่อ user (localStorage `zyra_*` + TTL 1 วัน / permanent) · Lite Mode เป็นหน้าใหม่ไม่ใช่ overlay บน VO (§7 ข้อ 2 จะชี้ขาด) |
| screens.md | เพิ่มหน้าใหม่: Select workspace mode, Keep This Setting sheet, Rotate, Lite Home (+ Slide), Connecting tips ใหม่ · Lobby แนวนอน |
| task-breakdown.md | 0.12 `useMobileMode()` → รวม mode setting · 0.14 Lite shell → ขยายเป็น Lite Home ทั้งหน้า · เพิ่ม task "Select mode + Keep setting" · joystick 128×140 |
| clickup-spec.md §18 | ข้อ 25 ปรับ: ไม่ใช่ banner และไม่ใช่ auto-switch แต่เป็น mode setting + หน้า Rotate · joystick 100 vs 128 · onboarding copy ต่างจาก HP-07 |

## 6. Node ที่ยังไม่ได้ดึงระดับ px (🔍 รอบหน้า)

Splash/Onboarding (ดึงแค่ metadata) · Get started ฟอร์ม · Space builder card · Lobby แนวนอน · Homepage – Slide เต็ม · Website landing · Circle cluster component · Profile tab ใน Lite (ยังไม่มีใน HP-03)

## 7. คำถาม / ข้อสงสัย — คำตอบจาก Ten (2026-09-30 เย็น)

| # | คำถาม | คำตอบ | สถานะ |
|---|---|---|---|
| 1 | โหมดกับ orientation | **เอาแบบ Figma** — เปลี่ยนโหมดได้จาก Settings ในแอปเท่านั้น · เหตุผล: Lite Mode **ไม่ต้องโหลด map / object / ของที่ไม่จำเป็น** ประหยัดเวลาและทรัพยากร (ข้อความต้นฉบับพิมพ์ว่า "โหมดแนวนอน" — ตีความว่าหมายถึง Lite Mode แนวตั้ง เพราะแนวนอน = Spatial ต้องมีแมพ) | ✅ ปิด → spec / TD §16 แก้แล้ว |
| 2 | Lite Mode ยังอยู่ในออฟฟิศไหม | คน desktop / Spatial จะเห็นคน Lite Mode เป็น **ghost อยู่ใน meeting** — เดินไปไหนไม่ได้, ไม่รับรู้ว่าคนอื่นอยู่ตรงไหน, คนอื่นเห็นแค่เป็น **ช่อง meeting (tile)** | ✅ ปิด → TD §16.2 |
| 3 | แตะ Circle / ห้อง "In meeting" ใน **Lite Home (แนวตั้ง)** แล้วเกิดอะไร | คำถามเดิมไม่ชัด — ถามใหม่: ใน Lite Mode แนวตั้ง กดการ์ดห้องประชุมหรือ Circle แล้ว (ก) เข้าห้องทันทีเป็น tile แบบ ghost + เปิดหน้าประชุมแนวตั้ง (HP-04 portrait) หรือ (ข) แค่ดูรายชื่อคนในห้องก่อน แล้วค่อยกด Join | ⏸ **ข้ามไปก่อน** — Ten: จะมีในข้อถัด ๆ ไป (subtask อื่น) |
| 4 | "Lobby" คืออะไร | คำศัพท์ในโค้ด = หน้า **pre-join** ก่อนเข้าออฟฟิศ (`/workspace/[id]` → `hero-workspace-enter.tsx`) ที่มี preview กล้อง, ตั้งชื่อตัวละคร, ปุ่ม **Join space** — ใน Figma คือหน้า "Welcome to Starlight world" (6387:1127419) ที่มีแต่แนวนอน · คำถามคือ **ถ้าเลือก Lite Mode ต้องผ่านหน้านี้ไหม และแนวตั้งหน้าตาอย่างไร** (หรือ Lite ข้ามไปหน้า Home เลยเพราะไม่มีตัวละครบนแมพ) | ✅ **ไม่ต้องผ่าน** — Lite เข้า Home เลย (ยังต้องมี Connecting ไหม 🔍 ยึดตามลูกศร Figma = มี) |
| 5 | Settings / status / Profile ใน Spatial | อยู่ที่ **แถบเมนูด้านล่าง ปุ่ม avatar ข้างปุ่มเปิด/ปิดไมค์** (Meeting Menu) | ✅ ปิด |
| 6 | กล่อง "Display" 168×158 | **tile คนที่กำลังพูด** (active speaker) | ✅ ปิด |
| 7 | Joystick 128×140 vs ClickUp 100×100 | **ยึด Figma 128×140** | ✅ ปิด → clickup-spec §18 |
| 8 | Website landing page | **เว็บแยก มีอยู่แล้ว** ไม่อยู่ใน scope zyra-app | ✅ ปิด |
| 9 | Remind me again นับ 1 วันยังไง · Always เก็บต่อ user หรือต่อเครื่อง | **localStorage ต่อเครื่อง · จำ 1 วัน** (ตีความ = 24 ชม. นับจากตอนกด Confirm · Always = ไม่หมดอายุ) | ✅ ปิด |
| 10 | Onboarding copy Figma ≠ ClickUp HP-07 | **ยึด Figma** (Ten 2026-10-01) | ✅ ปิด |
| 11 | Login แนวนอน (Browser) ไม่มี Continue with Apple | **ยึด Figma แล้วเพิ่มปุ่ม Continue with Apple** ให้ครบเหมือนแนวตั้ง (Ten 2026-10-01 "เพิ่มไป") · เว็บต้องใช้ Sign in with Apple JS (task 1.5) | ✅ ปิด |
| 12 | ชื่อ "Space builder" = รายการ workspace | **ใช่** (Ten 2026-10-01) — ในแอปใช้ชื่อ "Space builder" = หน้ารายการ workspace · ⚠️ ClickUp EC-01 ใช้ "Space Builder" หมายถึง editor (desktop only) — คนละอย่าง | ✅ ปิด |

### 7.1 คำถามเดิม (เก็บไว้อ้างอิง)

1. **โหมดกับ orientation** — Figma ให้ผู้ใช้เลือกโหมดแล้วบล็อกด้วยหน้า "Rotate your phone…" ถ้าถือผิดด้าน · มติเดิม (2026-09-30 เช้า) คือ "หมุนเครื่องแล้วสลับโหมดทันที" → เอาแบบไหน? (ถ้าเอาแบบ Figma: อยู่ Spatial แล้วหมุนเป็นแนวตั้ง = เห็นหน้า Rotate ไม่ใช่ Lite Home)
2. **Lite Mode ยังอยู่ในออฟฟิศไหม** — ใน Lite Home ไม่มีแมพเลย แต่มี section "Circle" และ "In meeting" ที่เป็นข้อมูลจากแมพ · ตอนอยู่ Lite avatar ของเรายังยืนอยู่ในแมพให้คนอื่นเห็นไหม หรือถือว่า "online แต่ไม่อยู่ในแมพ"? (กระทบ zyra-ws + TD §16.1)
3. **แตะ Circle / ห้องใน "In meeting" แล้วเกิดอะไร** — join เสียงทันที (แบบ companion) หรือเปิดหน้า meeting แนวตั้ง (HP-04)?
4. **Remind me again = 1 วัน ทุก workspace** — นับจากเวลาที่ตอบ หรือเที่ยงคืน? · "Always" เก็บต่อ user (ทุกเครื่อง) หรือต่อเครื่อง?
5. **Lobby แนวตั้ง** — HP-03 มี Lobby แค่ 844×390 · ถ้าเลือก Lite Mode ต้องผ่าน Lobby ไหม และเป็นแนวตั้งหน้าตาอย่างไร?
6. **Spatial Mode ไม่มี Settings / status picker / Profile** — เข้าจากไหน? (แตะ avatar ตัวเองในแถบ Meeting Menu? หรือปุ่ม member?)
7. **กล่อง "Display" 168×158 บนแมพ** (variant showDisplay, ชื่อ "Matthew" border เขียว) — คือ tile วิดีโอคนที่พูด / spotlight / หรือ self-view?
8. **Joystick 128×140** ใน Figma vs ClickUp HP-03 AC "100×100" — ยึด Figma?
9. **Website landing page** (แถว Browser) อยู่ใน scope ของทีมเรา (zyra-app) หรือเป็นเว็บการตลาดแยก?
10. **Onboarding copy** — Figma 3 slide (Collaboration / Collaborate in One Space / Pet & achievements) ต่างจาก ClickUp HP-07 (VO / Meeting AI Summary / Quiz Poll Tarot) — ยึด Figma?
11. **Login แนวนอน (Browser) ไม่มี Continue with Apple** แต่แนวตั้งมี — Figma ตกหล่นหรือตั้งใจ?
12. **ชื่อ "Space builder"** ใน Figma = หน้ารายการ workspace · ในโค้ด/ClickUp EC-01 = editor (desktop only) — ใช้ชื่ออะไรในแอป?

---

## 8. HP-04 · Mobile Responsive — Meeting (Video/Audio) (รับ 2026-09-30 เย็น)

**Node:** แนวตั้ง section `6111-125216` (390×844) · แนวนอน section `6511-139220` (844×390) · ดึงผ่าน `get_metadata` ทั้ง 2 section + `get_design_context` 15 frame + screenshot 30 frame

### 8.1 โครง section (8 แถวเหมือนกันทั้งแนวตั้ง/แนวนอน)

| แถว | แนวตั้ง (Lite Mode) | แนวนอน (Spatial Mode) |
|---|---|---|
| 1. Instant meeting – Display layer | Lite Home → กด Instant meeting → ห้อง 1 คน → 2 → 3 → 4 → 5 → 6 → 6+ (ลูกศร) | แมพ (Meeting/Private zone/Pet menu ขวาล่าง) → ห้อง 1 → 2 → 3 → 4 → 5 → 6 → 6+ |
| 2. Open Mic / Cam | เปิดกล้อง → ปุ่มสลับกล้องโผล่ที่ header → Tap 1 ครั้งเมนูหาย Display ไป center | เหมือนกัน |
| 3. Emoji / Raise Hand | กด emoji → panel 6 ตัว → emoji ลอยบน tile · ยกมือ → กรอบ tile เหลือง + badge ✋ + เลขลำดับ | เหมือนกัน (panel ลอยเหนือ Meeting Menu) |
| 4. Share Screen | ฝั่งแชร์ "You're sharing your screen" · ฝั่งดู shared tile ใหญ่บน + tiles ล่าง · 2+ display มีลูกศร · แชร์ไม่ได้ → tooltip | เหมือนกัน + sticky "ยังไม่แน่ใจ action ขยายจอ" |
| 5. PIP | กดลูกศรลง → กลับ Lite Home + tile 168×158 ลอย · ใครพูดสลับขึ้น | กดลูกศรลง → กลับแมพ + tile 168×158 **ขวาล่างเหนือ minimap** (`right 32` · ขอบล่างของ tile ห่างขอบบน minimap 8 → ที่ 844×390 = `top 108`) · **minimap ไม่หาย** (Ten 2026-10-01) · Figma แถว PIP แนวนอนไม่มี frame มีแค่ sticky "โหมดแนวนอนไม่น่าจะมีเพราะสามารถดู Map ได้" → ตำแหน่งนี้เป็นข้อเสนอ 🎨 design ยืนยัน · Meeting Menu บนแมพเหลือ avatar/cam/mic/leave |
| 6. Join meeting | แตะการ์ดห้องใน Lite Home → bottom sheet "Join meeting" · ห้องล็อก → "Request to join" | modal กลางจอ 390 ทับแมพ (overlay blur) · ห้องล็อก → "Request to join" |
| 7. EC – Unavailable rooms | กด Instant meeting แต่ห้องเต็ม → sheet "All rooms are busy" | **ไม่มี** — sticky: "โหมดแนวนอนไม่น่าจะมี เพราะสามารถดู Map ได้" (เดินเข้าห้องเอง) |
| 8. EC – Low battery | toast "Low battery. Charge to stay connected." เหนือ Meeting Menu ทั้งใน tiles / share viewer / sharer | เหมือนกัน |

### 8.2 Component หลัก (spec จาก get_design_context)

**Meeting Title (header)** — แนวตั้ง `w 358 top 24` · แนวนอน `w 780 top 16`
- ซ้าย: ปุ่ม **chevron-down** (bg white 5% p 8 radius 8 icon 16) = ย่อเป็น PIP · ชื่อห้อง "Meeting Hall" Body/Medium ขาว ellipsis · **แนวนอนเพิ่ม chip ผู้เข้าร่วม** (Icon Button h 32 px 8 py 4 bg white 5% radius 8: avatar 16 ซ้อน −6 + "+6" Body/Regular)
- ขวา gap 8 ปุ่มเดียวกัน 4–5 ปุ่ม: **[สลับกล้อง — โผล่เฉพาะตอนเปิดกล้อง]** · **lock** · **users** (Participants — เดิม user-plus เปลี่ยนตาม Pai 2026-10-02 · ดู §8.8) · **chat** · **speaker/unmute**
- ⚠️ ไม่มี "ชื่อ Meeting" (เช่น Daily stand up) ในทุก frame — มีแค่ชื่อห้อง (ดู §8.6 ข้อ 1)

**Meeting Display (tiles)** — แนวตั้ง `left 16 top 96 w 358 h 636` · แนวนอน `left 32 top 64 w 780 h 238`
- tile: bg white 5% radius 12 p 4 · avatar 56 วงกลมกลาง (สีพื้นตามคน) · **Name for display** มุมซ้ายล่าง bg black blur 4 radius 8 px 6 py 4: icon mic-off 14 (แดง `#F03A3A`) + ชื่อ Caption 1/Regular ขาว
- เปิดกล้อง: tile เป็นวิดีโอเต็ม (People image cover) name tag ทับ · ตัวเองมีกรอบเขียว `#58D68D` (ตอนซ่อนเมนู 6349:570280)
- ยกมือ: กรอบ tile เหลือง `#ECC819` + badge ✋ + เลขคิว มุมขวาล่าง · ปุ่มยกมือใน Menu เป็นสีเหลือง
- emoji ลอยกลาง tile (👋)

| จำนวนคน | แนวตั้ง | แนวนอน |
|---|---|---|
| 1 | tile เดียว h 338 กลางจอ | tile 358×238 กลาง |
| 2 | 2 tile ซ้อนแนวตั้ง flex-1 | 2 tile 358 gap 16 |
| 3 | 2 คอลัมน์ h 200 (แถว 2 มี 1) | 3 tile 249.33 กว้าง |
| 4–5 | 2 คอลัมน์ h 200 | 2 แถว × 3 (h 111) แถว 2 จัดกลาง |
| 6 | 2 คอลัมน์ × 3 แถว h 200 | 2 × 3 h 111 |
| > 6 | **ลูกศร ‹ › 26×24** ที่ `left 4 / right 360, y 410` (bg white 5% border white 20% radius 4) เลื่อนหน้า | ลูกศรที่ `left 4 / right 810` กึ่งกลางแนวตั้ง |

**Meeting Menu (bottom bar)** — bg `#232427` radius 16 p 8 **w 358** `bottom 16` กึ่งกลาง (ทั้งสอง orientation)
- ปุ่ม 7: **cam** · **mic** · **share screen** ┃ **emoji** · **raise hand** ┃ **leave** (bg `rgba(212,24,24,0.2)` icon แดง) · แต่ละปุ่ม icon 24 p 8 radius 8 · divider แนวตั้ง
- state: emoji เปิด → bg white 10% · share กำลังแชร์ → bg navy `#2C5AE4` · share ใช้ไม่ได้ → opacity 50% + tooltip · ยกมือ → bg เหลือง
- **Meeting Menu บนแมพ (Spatial PIP)**: avatar 32 + status · cam · mic ┃ leave (ไม่มี share/emoji/hand) — ตรงกับ HP-03 §3.9

**1 Tap ซ่อนเมนู** (6349:570195 / 6547:580015): header เลื่อนขึ้นบน, Menu เลื่อนลงล่าง, Display ย้ายไป center (`top 1/2`) · sticky ถาม **"Tap 2 ครั้งจะมี Action?"** (ยังไม่กำหนด)

**Emoji panel** (6361:640929): bg `#232427` radius 8 p 8 gap 8 ลอยเหนือ Menu (แนวตั้ง `left 146 top 736`, แนวนอน `373,282`) · 👋 ❤️ 🎉 👍 🤣 + ปุ่ม emoji เพิ่ม (16 px ทุกตัว)

**Share screen**
- ฝั่งแชร์ (6547:583840 / portrait 6350:570750): tile เต็ม bg white 5% radius 12: วงกลม 80 placeholder + "You're sharing your screen" Body/Medium + "You can switch to another screen while others continue to see your shared screen." Body/Regular `#8C99A6` + ปุ่ม **Stop sharing** (bg ขาว text `#1A1B1E` h 42 px 16 radius 8) · ปุ่ม share ใน Menu เป็น navy
- ฝั่งดู (6350:571157): tile แชร์ flex-1 บน (name tag icon = screen แทน mic) + 2 tile h 200 ล่าง + ลูกศรที่ y 629 เมื่อ 2+ display · แนวนอน: shared tile กลาง 244 กว้าง (6547:584233) หรือเต็ม 780 (6547:584367)
- แชร์ไม่ได้ (6633:55018): ปุ่ม share opacity 50% · **Tooltips** "Screen sharing is only available in your browser." bg `#1A1B1E` p 8 radius 8 drop-shadow white 8% + หางสามเหลี่ยม ⚠️ ข้อความขัดกับ ClickUp EC-02/HP-11 (ดู §8.6 ข้อ 5)
- sticky ฝั่งแชร์: *"ให้มีการแชร์ไปเลย หรือมีการถามก่อนว่าจะแชร์แค่หน้าจอเสียงไม่ต้อง? หรือแชร์หน้าจอแล้วโทรศัพท์เปิดโหมดห้ามรบกวนอัตโนมัติ"* — ยังไม่ตัดสินใจ
- sticky แนวนอน: *"ยังไม่แน่ใจ action ที่จะทำให้หน้าจอใหญ่: Tap ที่หน้าจอที่แชร์ / Double tap / Tap แล้วปรากฏเมนูให้ขยาย"* — ยังไม่ตัดสินใจ

**PIP** (symbol 6350:571263): Display tile **168×158** bg `#232427` radius 12 p 4 ที่ `left 203 top 606` ลอยเหนือ Lite Home (ทับ list, เหนือ bottom nav) · name tag + avatar 56 · sticky *"ตอน PIP ใครพูดให้สลับขึ้นหน้าคนนั้น"* (active speaker) · แนวนอน: tile 168×158 **ขวาล่างเหนือ minimap** (`right 32` · ขอบล่างของ tile ห่างขอบบน minimap 8 → ที่ 844×390 = `top 108`) · **minimap ไม่หาย** (Ten 2026-10-01) · Figma แถว PIP แนวนอนไม่มี frame มีแค่ sticky "โหมดแนวนอนไม่น่าจะมีเพราะสามารถดู Map ได้" → ตำแหน่งนี้เป็นข้อเสนอ 🎨 design ยืนยัน

**Join meeting sheet** (6265:610075 / modal แนวนอน 6547:590402): bg `#232427` radius บน 24 (แนวนอน radius 16 กลางจอ w 390) p 16 gap 40 · "Join meeting" Sub/Bold + Cancel 16 · ชื่อห้อง Body/Medium + avatar stack 24 +10 · ปุ่ม **settings 42×42** (bg white 5%) + **Join** เขียว h 42 flex-1 · ห้องล็อก: icon lock หน้าชื่อ + ปุ่ม **Request to join** (bg ขาว) · sticky: *"จะตั้งค่าไรได้บ้างนะ?"* (ปุ่ม settings) และ *"ถ้าเป็น Circle ก็เปลี่ยน Join meeting > Join Circle"*

**All rooms are busy sheet** (6257:608850): "Start meeting" Sub/Bold + Cancel · วงกลม 80 placeholder · "All rooms are busy" Body/Medium · "There's no available room right now. Try again soon." `#8C99A6` · ปุ่ม **Done** เขียว

**Low battery toast** (Text notification bottom): bg `rgba(0,0,0,0.7)` blur 4 h 32 radius 8 px 8 py 4 gap 8: icon warning 16 เหลือง `#ECC819` + "Low battery. Charge to stay connected." Body/Regular + Cancel 16 · ตำแหน่ง `bottom 76` (เหนือ Meeting Menu) · ClickUp HP-04: แสดงเมื่อแบต < 20%

### 8.3 โน้ตจาก Ten (2026-09-30) เทียบกับ Figma

| โน้ต | ใน Figma | สถานะ |
|---|---|---|
| Priority: ชื่อ Meeting (Daily stand up) กับ ชื่อห้อง (Meeting Hall) | header มีแค่ชื่อห้อง "Meeting Hall" | ⏳ ถาม §8.6 ข้อ 1 |
| กดชื่อห้อง → ไปหน้า Setting | ไม่มี frame หน้า Setting ใน HP-04 · sticky ก็ถาม "จะตั้งค่าไรได้บ้าง" | ⏳ ข้อ 2 |
| กดลูกศรลง → PIP | ✅ chevron-down ที่ header → PIP row | ✅ |
| ชวนคน: Internal ผ่าน Chat · External ผ่าน Copy / ส่งคำเชิญเมล | ปุ่ม user-plus มี แต่ไม่มี sheet ชวนคนใน HP-04 | ⏳ ข้อ 3 |
| คนอื่นใน Map เห็นเราเป็น Ghost | สอดคล้อง TD §16.2 | ✅ |
| Private zone > คนอื่นเข้ามา > เรากลายเป็นหน้าจอ Meeting | ไม่มี frame | ⏳ ข้อ 4 |
| > 6 คน ลูกศรซ้าย-ขวา | ✅ 6+ Display มีลูกศร | ✅ |
| Open Mic/Cam: เมนูสลับกล้องโผล่ · Tap 1 ครั้งเมนูหาย บนเลื่อนขึ้น ล่างเลื่อนลง Display center | ✅ ตรง frame | ✅ |
| ฝั่งคนแชร์ Note: แชร์เลย / ถามก่อน / auto DND | sticky เดียวกัน ยังไม่ตัดสินใจ | ⏳ ข้อ 6 |
| ตอน PIP ใครพูดให้สลับ | ✅ PIP row 3 frame (Matthew → Conan Grey) | ✅ |

### 8.4 เทียบกับโค้ดปัจจุบัน (ตรวจ 2026-09-30)

| Figma | โค้ด zyra-app | งาน |
|---|---|---|
| Meeting tiles + name tag + active speaker | `zone-enter-tiles.tsx` grid · `use-meeting-media.ts:820` มี `activeSpeakersChanged` แล้ว | layout ใหม่ทั้ง 2 orientation + PIP ใช้ active speaker เดิม |
| header lock / invite / chat / speaker | `zone-enter-header.tsx` มี lock zone แล้ว (`zone-enter-types.ts`) · chat = `zone-enter-chat.tsx` · invite = `invite-member-modal.tsx` (696px) | ย่อเป็นปุ่ม icon 5 ปุ่ม · ปุ่ม invite เปลี่ยนเป็น Participants sheet → Invite sheet แท็บ Chat/Link/Email (§8.8) |
| Emoji reaction / Raise hand | **มีแล้ว** — `zone-enter-types.ts:28-33` `handRaised` / `onToggleHand` / `onSendReaction(emoji)` และ `:142` raise-queue sequence (เลขลำดับบน tile) | แค่ย้าย UI: panel emoji 6 ตัว + ปุ่มใน Meeting Menu + กรอบเหลือง/badge ตาม Figma |
| Share screen ฝั่งดู | `zone-enter-screen-share.tsx` มี | layout ใหม่ · ฝั่งแชร์บนมือถือ = inventory A1 (Phase 3 native) |
| PIP ในแอป (ไม่ใช่ Document PiP) | ไม่มี — `use-document-pip.ts` เป็น Chromium desktop | component ใหม่: floating tile ใน Lite Home / บนแมพ + คง LiveKit room ระหว่างย่อ |
| Join meeting sheet / Request to join | lock ห้องมีแล้ว (`zone-enter-types.ts:108-111` `isLocked` / `onToggleLock`) · เข้า zone ด้วยการเดิน · ~~request-to-join ไม่พบ~~ **แก้ 2026-10-02: มีแล้ว = knock** — zyra-ws `handleKnock` (`internal/hub/room.go:2504`) รับ `zone_id` ตรง ไม่เช็คตำแหน่ง · broadcast `knock_request` ทุกคน · `knock_decision` / `knock_decided` / `knock_cancelled` · cooldown + เก็บใน Redis ให้ reload แล้วยังเห็น · web แสดงเป็น `vo-knock-notification.tsx` | zyra-ws: join by id (TD §16.2) · request ห้องล็อกใช้ knock เดิม ไม่ต้องเพิ่ม backend |
| All rooms are busy | ไม่มี (Instant meeting ยังไม่มีในโค้ด) | ผูกกับ feature Instant meeting (clickup-spec §18 ข้อ 5) |
| Low battery | ไม่มี Battery API ใน WKWebView → `@capacitor/device` (inventory B15) | ตาม clickup-spec §18 ข้อ 14 |
| สลับกล้องหน้า/หลัง | task 0.8 | ✅ วางไว้แล้ว |

### 8.5 ผลต่อเอกสารอื่น (อัปเดตแล้วหลังคำตอบ §8.6 — screens D, task 0.17–0.20, TD §16.2, clickup-spec §18 ข้อ 30–31)

- screens.md D: เพิ่มแถว Emoji/Raise hand, PIP tile, Join sheet, Busy sheet, Low battery toast · header 5 ปุ่ม · tile layout ตามจำนวน
- task-breakdown 0.7/0.8: แตก task meeting มือถือ (tiles 1–6+, 1-tap hide, PIP, emoji/hand ต้องมี zyra-ws event, request-to-join)
- spec.md open question: เพิ่มข้อจาก §8.6
- clickup-spec §18: ข้อ 16 (active speaker + strip) — Figma ใช้ **grid 2 คอลัมน์** ไม่ใช่ active speaker ใหญ่ + strip · ข้อ 23 screen share vs tooltip "only available in your browser"

### 8.6 คำถาม / ข้อสงสัย HP-04 — คำตอบจาก Ten (2026-09-30 ค่ำ)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | **ชื่อ Meeting** (Daily stand up) โชว์ตรงไหน — ทุก frame มีแค่ชื่อห้อง "Meeting Hall" · Instant meeting มีชื่อ meeting ไหม หรือชื่อ meeting มีเฉพาะที่นัดจาก Calendar | ✅ **ชื่อ meeting แสดงแทนชื่อห้องถ้ามี** (ไม่มีชื่อ meeting → โชว์ชื่อห้อง) |
| 2 | **กดชื่อห้อง → Setting** ตั้งอะไรได้บ้าง (เปลี่ยนชื่อ, lock, เตะคน, mic/cam device, background?) · ปุ่ม settings ใน Join sheet เป็นชุดเดียวกันไหม | ✅ **แก้ 2026-10-02 (Ten): Setting = bottom sheet มี 3 เมนู — Voice output · Camera filter · Invite** · **ไม่มี Room name** (ตัดการเปลี่ยนชื่อ) · ~~เดิม 2026-09-30: เปลี่ยนชื่อ, lock, เตะคน, เลือกไมค์/กล้อง~~ · lock ยังอยู่ที่ปุ่ม lock ใน header · ✅ **เตะคน → เมนู ⋯ ท้ายแถวใน Participants sheet (host)** (§8.8 ข้อ 6) · ⏳ เลือกไมค์ ยังไม่อยู่ในรายการใหม่ |
| 3 | **ชวนคน** (ปุ่ม user-plus): sheet Internal ผ่าน Chat / External Copy link / ส่งเมล — UI อยู่ subtask ไหน (ไม่มีใน HP-04) | ✅ **Internal = ส่งเป็น link ผ่านแชท** · External = copy link / ส่งเมล — UI sheet ยังไม่มี 🔍 |
| 4 | **Private zone > คนอื่นเข้ามา > เรากลายเป็นหน้าจอ Meeting** — หมายถึงคน Lite ที่ "อยู่" ใน private zone? Lite ไม่มีตำแหน่งบนแมพ (ghost) จะอยู่ private zone ได้ยังไง — หรือหมายถึง Spatial (แนวนอน) ที่นั่งใน private zone แล้วมีคนเดินเข้ามา → เปิดหน้า meeting อัตโนมัติ | ✅ **ปรับใหม่:** นาย A (Lite แนวตั้ง, ไม่ได้โหลด ws/แมพ) เข้า meeting กับนาย B → **ทุกคนที่โหลด ws เห็น avatar ของ A โผล่ที่จุดเกิดแล้วเดินไปห้อง meeting นั้น** แต่เครื่อง A ไม่เก็บตำแหน่ง A ไม่รู้ว่าตัวเองอยู่ไหน · **ถ้าไม่มี meeting avatar ของคน Lite จะหายไปจากแมพ** มี meeting ค่อยโผล่จากจุดเกิดแล้วเดินไปหา · Ten: "ต้องทำดี ๆ ให้เนียน ๆ" → TD §16.2 |
| 5 | **Screen share บนมือถือ**: tooltip เขียน "only available in your browser" — ตกลงบนมือถือ (ก) mobile web ❌ / app ✅ ReplayKit (Phase 3 ตาม HP-11) หรือ (ข) ❌ ทั้งคู่รอบแรก · ถ้า (ข) ข้อความ tooltip ต้องเปลี่ยนเป็น "available on desktop" | ✅ **ถ้าทำให้มือถือแชร์ได้จะดีมาก** (app ผ่าน ReplayKit/MediaProjection = Phase 3 inventory A1) · tooltip เป็นกรณีที่แชร์ไม่ได้ (mobile web) |
| 6 | **ฝั่งคนแชร์** เลือก: (ก) แชร์ทันที (ข) ถามก่อนว่าแชร์หน้าจออย่างเดียว/พร้อมเสียง (ค) auto ห้ามรบกวน · ข้อจำกัด: iOS ReplayKit มี system dialog ถามเสมอ (ปิดไม่ได้) และ **iOS ไม่ให้แอปเปิด Do Not Disturb/Focus เอง** — (ค) ทำได้แค่ Android (Notification Policy permission) | ✅ **ตามที่เสนอ**: ถามก่อนแชร์ (iOS system dialog อยู่แล้ว) · DND อัตโนมัติทำเฉพาะ Android ถ้าจะทำ |
| 7 | **Tap 2 ครั้ง / ขยายจอแชร์** (sticky 2 อัน): เสนอ double-tap tile = ขยายเต็มจอ (ซ่อน tile อื่น) · tap 1 ครั้ง = ซ่อน/แสดงเมนู ตามเดิม | ✅ **ตามที่เสนอ**: tap 1 ครั้ง = ซ่อน/แสดงเมนู · **double-tap tile = ขยายเต็มจอ** (ใช้กับจอแชร์ด้วย) |
| 8 | **Request to join** ห้องล็อก: ใครอนุมัติ (เจ้าของห้อง/คนในห้อง), แจ้งเตือนยังไง, timeout — โค้ดยังไม่มี flow นี้ | ✅ **คนในห้องกดอนุญาตได้** · Ten ขอให้ **เพิ่มเมนู popup** สำหรับคนในห้อง ("X ขอเข้าร่วม [อนุญาต] [ปฏิเสธ]") — UI ใหม่ต้องให้ design ทำ 🔍 · **แก้ 2026-10-02 (Pai + Ten): ไม่ใช่ popup ที่มีปุ่ม แต่เป็น toast "Someone is requesting to join your meeting." → แตะแล้วไป Requesting list ท้าย Participants sheet (Accept / Deny)** ดู §8.8 |
| 9 | **PIP แนวนอน** tile อยู่ตำแหน่ง minimap → minimap หายระหว่าง PIP ใช่ไหม · PIP แนวตั้งลากได้ไหม (ClickUp HP-04 บอก self-view draggable) | ✅ **แนวนอน: minimap ไม่หาย** → PIP tile ย้ายไปขวาล่างเหนือ minimap (ข้อเสนอ — design ยืนยัน) · ✅ **แนวตั้ง: ลาก PIP ไม่ได้** — tile อยู่ตำแหน่งตาม Figma (`left 203 top 606` เหนือ bottom nav) ตายตัว · แตะ = กลับหน้า meeting เต็มจอ (Ten 2026-10-01) · ClickUp "self-view draggable" ตัดออก |
| 10 | **Join meeting modal บนแมพ (แนวนอน)** เปิดตอนไหน — แตะห้องบนแมพ? หรือจากรายชื่อสมาชิก? (Spatial ปกติเดินเข้าห้อง) | ✅ **เปิดจากการแตะห้องบนแมพ** (Ten 2026-10-01) · ✅ รายละเอียด (Ten ยืนยันครบ 3 ข้อ 2026-10-01): แตะ**ภายในพื้นที่ห้อง meeting จากนอกห้อง** = เปิด modal แทนการเดิน (แตะที่อื่นยังเป็น tap-to-walk) · กด Join → avatar **เดินเข้าห้องอัตโนมัติ** (path click-to-walk เดิม) แล้วเข้า meeting ตามปกติเมื่อถึง zone · Cancel = อยู่ที่เดิม · อยู่ในห้องแล้วแตะ = ไม่เปิด · ห้องล็อก = ปุ่ม Request to join |

### 8.7 UI ที่ต้องขอเพิ่มจาก design (ไม่มีใน HP-04 แต่จำเป็นตามคำตอบ)

| UI | เหตุผล |
|---|---|
| **bottom sheet Setting ห้อง** — Voice output · Camera filter · Invite (Invite เปิด sheet ชวนคน) | ข้อ 2 — กดชื่อห้อง/ปุ่ม settings ใน Join sheet |
| **Participants sheet** (มงกุฎ host · ไมค์ท้ายแถว · ⋯ Kick · Mute all · Requesting list) | §8.8 — Pai เขียนโน้ตแล้ว รอวาด frame |
| sheet **ชวนคน** แท็บ Chat / Link / Email (Link ตั้งวันหมดอายุได้) | ข้อ 3 · §8.8 — Pai เขียนโน้ตแล้ว รอวาด frame |
| **toast คำขอเข้าห้อง** + Requesting list (แทน popup เดิม) + สถานะรอฝั่งคนขอ | ข้อ 8 · §8.8 — Pai เขียนโน้ตแล้ว รอวาด frame |
| tile **ขยายเต็มจอ** หลัง double-tap (+ วิธีย่อกลับ) | ข้อ 7 |
| animation avatar ghost **โผล่ที่จุดเกิด → เดินไปห้อง** บนเครื่องคนอื่น | ข้อ 4 (เป็น engine ไม่ใช่ UI แต่ต้องกำหนด spawn point / ความเร็ว) |

### 8.8 Participants · Invite · คำขอเข้าห้องล็อก (โน้ต Pai 2026-10-02 · Ten ตอบ 2026-10-02)

**ที่มา:** sticky note ของ Pai (UX/UI) บน mockup card 02 "ชวนคนเข้าห้อง" และ card 03 "popup ขอเข้าห้องที่ล็อก" ใน [mobile-ui-proposals](https://zyra-mobile-ui-proposals.vercel.app) · **ยังไม่มี frame ใน Figma** ค่า px ด้านล่างเป็นข้อเสนอจาก mockup 🎨 Pai วาดแล้วค่อยยึด Figma

#### 8.8.1 ระบบทำงานยังไง

```
header [Users] ──แตะ──▶ Participants sheet
                         ├─ หัว: "Participants (N)" ·············· [UserPlus] Invite ──▶ Invite sheet
                         ├─ แถว host (มงกุฎ) → แถวคนที่เข้าตามลำดับ · ท้ายแถว: ไมค์ · ⋯ (host)
                         └─ Requesting (N) — Deny / Accept

มีคนขอเข้าห้องล็อก ──▶ toast "Someone is requesting to join your meeting." (5 วิ)
                      + ตัวเลขบนไอคอน Users ค้างจนตัดสินครบ
                      แตะ toast ──▶ Participants sheet เลื่อนไปที่ Requesting

Invite sheet (จาก Participants หรือ Setting ห้อง → Invite)
  [Chat] [Link] [Email]   ← Owner/Admin เห็น 3 แท็บ · สมาชิกทั่วไปเห็นแค่เนื้อหา Chat ไม่มีแถบแท็บ
```

#### 8.8.2 Participants sheet

| ส่วน | spec |
|---|---|
| ทางเข้า | ปุ่ม **`Users`** บน header (แทน `UserPlus` เดิม) · แนวตั้ง = bottom sheet · แนวนอน = modal กลางจอ w 390 แบบเดียวกับ Join modal (ข้อเสนอ 🎨) · tablet = sheet กว้างสุด 600 กลางจอ (§17.7 ข้อ 11) |
| หัว | "Participants (N)" Sub/Bold ซ้าย · ขวา ปุ่ม Invite (icon `UserPlus` 42×42 bg white 5%) |
| แถวที่ 2 (host เท่านั้น) | "In meeting · N" Caption 1 `#8C99A6` ซ้าย · ขวา ปุ่มข้อความ **Mute all** |
| ลำดับรายชื่อ | host ขึ้นก่อนพร้อม **`Crown`** บน avatar (host = คนแรกที่เข้าห้อง · host ออก → มงกุฎย้ายตาม `ws:meeting:ownerUpdate` เดิม) · ที่เหลือเรียงตามลำดับที่เข้า |
| ท้ายแถว | **ไมค์**: host เห็น `Mic` กดได้ = ปิดไมค์คนนั้น (`ForceMute` ผ่าน `ws:media:request` ฝั่ง zyra-ws ล็อกให้ host เท่านั้น) · ไมค์ปิดอยู่แล้ว = `MicOff` แดง กดไม่ได้ (เปิดไมค์ให้คนอื่นไม่ได้) · คนที่ไม่ใช่ host เห็นแค่ไอคอนสถานะ · **⋯ (`Ellipsis`) host เท่านั้น** → Kick (`ws:meeting:kick` เดิม) |
| แตะแถว | เปิด profile ของคนนั้น (จากตรงนั้นเข้าแชทได้) · ตัดปุ่ม Chat ในแถวที่เว็บมีออก |
| Requesting (N) | อยู่ท้ายรายชื่อ ซ่อนเมื่อไม่มีคำขอ · แถว: avatar + ชื่อ + ปุ่ม **Deny** (ghost) / **Accept** (เขียว) · **ทุกคนในห้องกดได้** · มีคนกดแล้ว / คนขอยกเลิก → แถวหายทุกเครื่อง (`knock_decided` / `knock_cancelled`) |

#### 8.8.3 Invite sheet

| แท็บ | spec |
|---|---|
| **Chat** (ทุกคน) | ช่องค้นหา · รายชื่อ: **คน online ที่ไม่ได้อยู่ในห้องขึ้นก่อน ต่อด้วยคน offline** เรียงตามชื่อภายในกลุ่ม · **แตะตรงไหนของแถวก็ติ๊ก checkbox** · ปุ่ม **Send link in chat (N)** = ส่งลิงก์ห้องเป็น DM ทีละคน (chip ลิงก์ห้องเดิม SC-VO-15 · คน offline ได้ push จากแชท) |
| **Link** (Owner/Admin) | = **ลิงก์เชิญเข้า workspace** (`/join/{token}`) ไม่ใช่ลิงก์ห้อง · บนสุด ปุ่ม **Copy link** → toast "Invite link copied" · ใต้ลงมา 2 ตัวเลือก: **No expiry** / **Set expiry date** (toggle เปิด = เลือกวันหมดอายุ) · ใช้ API เดิม `getWorkspaceJoinLinkConfig` / `updateWorkspaceJoinLinkConfig` (`lib/api/workspace-members.ts:129,140`) · role และจำนวนครั้งที่ใช้ได้ของลิงก์ไม่แสดงบนมือถือ ใช้ค่าที่ตั้งไว้บนเว็บ (สมมติ ⏳) |
| **Email** (Owner/Admin) | ช่องพิมพ์อีเมล**หลายอัน** (Enter / comma / เว้นวรรค → chip · ตรวจรูปแบบ) · ปุ่ม **Send invite** ล่างสุด · role = **Member เสมอ** (เชิญเป็น Admin ทำบนเว็บ) · อีเมลหมดอายุ 7 วันตาม backend เดิม |

ผลของการเชิญผ่าน Link / Email: คนที่ได้รับเข้า **workspace** ก่อน แล้วค่อยเดินเข้าห้องเอง · คนที่อยู่ใน workspace แล้วใช้แท็บ Chat เชิญเข้าห้อง

#### 8.8.4 Toast คำขอเข้าห้องล็อก (ฝั่งคนในห้อง)

| เรื่อง | spec |
|---|---|
| ข้อความ | **"Someone is requesting to join your meeting."** ไม่ใส่ชื่อ · หลายคนพร้อมกัน → toast เดียว **"3 people are requesting to join your meeting."** |
| ตำแหน่ง | แนวตั้ง: ใต้ header ของหน้า meeting · แนวนอน: บนกลางจอ ใต้ header ของหน้า meeting (บนแมพใช้ตำแหน่งเดียวกับ toast อื่น) · ตอน PIP (อยู่ Lite Home / แมพ) ใช้ตำแหน่ง toast ปกติของหน้านั้น |
| อายุ | หายเองใน **5 วินาที** · **ตัวเลขบนไอคอน `Users`** ค้างจนคำขอถูกตัดสินครบ |
| แตะ | เปิด Participants sheet แล้วเลื่อนไปที่ Requesting |
| ใครเห็น | ทุกคนในห้อง (zyra-ws broadcast `knock_request` แล้ว client กรองตาม zone) |
| backend | ใช้ knock เดิมทั้งหมด — `handleKnock` รับ `zone_id` ตรงไม่เช็คตำแหน่ง → คน Lite (ghost) ขอเข้าได้เลย · มี cooldown และเก็บคำขอใน Redis ให้ reload แล้วยังเห็น |

#### 8.8.5 คำตอบ (Ten 2026-10-02 — ข้อ 11 ตอบเอง ที่เหลือ "ตามแนะนำ")

| # | คำถาม | คำตอบ |
|---|---|---|
| 1 | Copy link / Email เป็นเมนูด้านบน (โน้ตใบ 2) หรือแท็บ Chat / Link / Email (โน้ตใบ 3) | ✅ **แท็บ** ตามใบ 3 เพราะแท็บ Link ต้องมีที่ตั้งวันหมดอายุ |
| 2 | Link / Email เชิญเข้า workspace หรือเข้าห้องโดยตรง | ✅ **เข้า workspace** ใช้ API เดิม ไม่ต้องแก้ backend (ลิงก์ห้องหมดอายุเองเมื่อ meeting รอบนั้นจบ ตั้งวันเองไม่ได้) |
| 3 | สมาชิกทั่วไปเห็นแท็บไหน | ✅ เห็นแค่ **Chat** · Owner/Admin เห็นครบ 3 แท็บ (ตามสิทธิ์ `canShareLink` บนเว็บ) |
| 4 | แท็บ Email ต้องเลือก role ไหม | ✅ ไม่ต้อง · **Member เสมอ** |
| 5 | ปุ่มไมค์ท้ายแถว | ✅ host **ปิดได้อย่างเดียว** · คนอื่นเห็นแค่สถานะ |
| 6 | Mute all / Kick / Chat ในแถว | ✅ Mute all ที่หัว list (host) · Kick ในเมนู ⋯ (host) · ตัดปุ่ม Chat ในแถว (แตะชื่อ → profile → แชท) |
| 7 | ใครกด Accept / Deny | ✅ **ทุกคนในห้อง** เหมือนเว็บ |
| 8 | รายชื่อในแท็บ Chat | ✅ online ที่ไม่อยู่ในห้องก่อน → offline · เรียงชื่อ · ค้นหาได้ทั้งหมด |
| 9 | toast อยู่นานแค่ไหน | ✅ **5 วินาที** + ตัวเลขบนไอคอน `Users` |
| 10 | หลายคนขอพร้อมกัน | ✅ toast เดียว "N people are requesting…" |
| 11 | ใส่ชื่อคนขอใน toast ไหม | ✅ **ไม่ใส่** — "Someone is requesting to join your meeting." (Ten) |
| 12 | ตำแหน่ง toast แนวนอน | ✅ บนกลางจอ ตำแหน่งเดียวกับ toast อื่น |

**ไม่ต้องถาม (ตามโน้ต Pai):** ปุ่ม header เป็น `Users` · host มีมงกุฎ · Requesting list อยู่ท้ายรายชื่อ · แตะทั้งแถวติ๊ก checkbox ได้

## 9. HP-05 · Mobile Responsive — Chat (รับ 2026-09-30 ดึก · Ten ตอบ 2026-10-01)

**Node:** แนวตั้ง section `6351-578634` (390×844) · แนวนอน section `6547-591562` (844×390) — ตรงกับลิงก์ที่ Ten ส่ง 2026-10-01 (`?node-id=6351-578634&m=dev` / `?node-id=6547-591562&m=dev`) และ [clickup-spec.md §17](clickup-spec.md) · ดึงผ่าน `get_metadata` ทั้ง 2 section + `get_design_context` 11 frame + screenshot 22 frame (frame `6604-179027` preview แนวนอน zoom ดึงไม่ขึ้น timeout 🔍)

### 9.1 โครง section (7 แถวเหมือนกันทั้งแนวตั้ง/แนวนอน)

| แถว | แนวตั้ง (Lite Mode) | แนวนอน (Spatial Mode) |
|---|---|---|
| 1. Chat (รายการแชท) | Lite Home → bottom nav แท็บ Chat → หน้า **Chat list** เต็มจอ (search + tab All/Channel/Group/Direct message + Threads Messages + รายการ) → แตะแถว → หน้า conversation เต็มจอ (มีปุ่ม back) | แตะปุ่ม chat มุมขวาบนของแมพ → **overlay 2 คอลัมน์ทับแมพ** (× ปิดซ้ายบน · รายการ 249 px ซ้าย · conversation 515 px ขวา) ไม่มี bottom nav ไม่มีปุ่ม back |
| 2. Send DM | FAB `+` ขวาล่าง → overlay blur + FAB หมุนเป็น × + เมนู 2 ข้อ "Create chat" / "Start a new chat" → หน้า **Start a new chat** (search member + รายชื่อ Member (100) พร้อมสถานะ) → แตะคน → conversation | เหมือนกัน — FAB อยู่มุมขวาล่างของคอลัมน์ซ้าย · Start a new chat เป็นหน้าเต็ม overlay |
| 3. Keyboard Alphabet / Emoji | focus input → คีย์บอร์ด iOS (dark + suggestion bar) · กดปุ่ม 😊 ในช่องพิมพ์ → **emoji keyboard ของระบบ** (Search Emoji + หมวด) · input ลอยเหนือคีย์บอร์ด | sticky: **"หา Keyboard landscape สำเร็จรูปไม่เจอ ขออนุญาตไม่ใส่ พอกดอยากให้ Keyboard ขยายเต็มพื้นที่เลย"** → frame `6707-139456` แถบ input ย้ายมาอยู่ที่ y≈200 เต็มกว้าง ใต้เป็นพื้นที่คีย์บอร์ด (h 190) ทับทั้งรายการและ conversation |
| 4. Media – Image | รูปในข้อความเป็น grid 2 คอลัมน์ + "Download all" → **แตะ 1 ครั้ง = preview เต็มจอ** (header ผู้ส่ง+เวลา, download, ⋮ · filmstrip ล่าง) · sticky: **pinch out = zoom + เมนูหาย, แตะอีกที = เมนูกลับมา · pinch in = กลับขนาดเดิม + เมนูโชว์** | preview กลางจอ (รูปตั้งกลาง มีขอบเทาซ้าย-ขวา) + filmstrip ล่าง · พฤติกรรม pinch เหมือนกัน |
| 5. Message – Long pressed | กดค้างข้อความ → overlay blur ทั้งจอ ข้อความที่กดยกขึ้นมาบน overlay → **Emoji panel** (7 ตัว + ➕) + **Submenu** Reply / Thread / Copy / Pin / Forward / Select ┃ Delete (แดง) | เหมือนกัน — panel + submenu ชิดขวาบนของคอลัมน์ conversation |
| 6. Mention | พิมพ์ `@` → **Submenu ลอยเหนือ input** (3 คน + `@Everyone` "Notify everyone in this chat") · sticky: **แนะนำ 3–4 คนที่คุยบ่อย, เลื่อนดูได้, พิมพ์ต่อแล้วกรองชื่อ** · เมื่อถูก mention: แถวใน Chat list มี chip `@You` สีฟ้า + ข้อความในห้องมี chip `@You` (frame `6361-638015` "หน้า Chat กรณีเราถูก Mention") | เหมือนกัน — Submenu ลอยเหนือ input ของคอลัมน์ขวา (bottom 66) |
| 7. Load older message | เลื่อนขึ้นสุด → **ไอคอนโหลด** (Reload 16 px) เหนือเส้น "Today" · sticky: "Scroll ขึ้นไปบนสุด แสดง loading icon" | เหมือนกัน |

### 9.2 Spec ต่อหน้า (จาก `get_design_context`)

**Chat list แนวตั้ง (`5944-134033`)**

| ส่วน | ค่า |
|---|---|
| พื้นหลัง | `#1A1B1E` · title "Chat" Sub/Bold 16/22 กลาง top 24 กว้าง 358 (ปุ่ม back opacity 0 = ไม่มีที่หน้านี้) |
| Search | h 42 · bg `#232427` · border white 20% · radius 8 · px 12 py 8 · icon search 16 · placeholder "Search for chat or message" `#636D76` 14/18 · top 72 |
| Tab filter | แถว gap 8 · แต่ละ tab h 32 p 8 radius 8 text 14/18 white · active = bg `rgba(88,214,141,0.2)` · **All / Channel / Group / Direct message** (3 อันแรก flex-1, Direct message shrink-0) |
| Threads Messages | แถว px 16 py 12 gap 8 · icon 16 · text 14/18 white · badge unread bg `#D41818` radius 90 text 10/14 Medium กว้าง 16 |
| แถวแชท | px 16 py 8 gap 8 (list gap 4) · avatar 40: channel = bg `#7EA2FC` radius 90 icon `#` inset 20% · group = icon member · คน = avatar + status dot ขวาล่าง · ชื่อ 14/18 white ellipsis + เวลา 10/13 `#8C99A6` ("10:52" / "Yesterday" / "2 days ago") · บรรทัด 2: ยังไม่อ่าน = Caption 1 **Medium white** + badge · อ่านแล้ว = Regular `#8C99A6` ขึ้นต้น "You: …" |
| chip `@You` | bg `rgba(45,182,255,0.2)` text `#2DB6FF` 12/15 Medium · radius 8 · px 4 py 2 · อยู่หน้าข้อความ preview |
| Bottom bar | เหมือน Lite Home (§3): h 56 bg `rgba(26,27,30,0.5)` radius 1000 bottom 16 · แท็บ Chat active bg white 20% + badge "10" |
| FAB | 48×48 bg `#58D68D` radius 90 · right 16 bottom 80 · icon plus 16 |

**Chat – Create (`5944-134262`)**: overlay `rgba(0,0,0,0.5)` blur 6 ทั้งจอ · FAB เดิมหมุน 45° เป็น × · เมนูชิดขวาเหนือ FAB (left 217 top 636) gap 16 · แต่ละข้อ icon 24 + text 16/22 white: "Create chat" (plus) · "Start a new chat" (send) · **Figma อัปเดต 2026-10-05 (`5944-134262`): เมนู 3 ข้อ — Create channel (`hash`) · Create group (`users`) · Start a new chat (`send`)** ชิดขวาเหนือ FAB 8 px gap 16 · icon 24 + Sub/Regular 16/22 ขาว ไม่มีพื้นหลัง → **ไม่ต้องมี sheet เลือก Group / Channel แล้ว** (§22.1)

**Start a new chat (`5944-274509`)**: title bar เหมือน Chat list แต่มีปุ่ม back (bg white 5% p 8 radius 8 chevron 16) + title "Start a new chat" · search "Search for member" · header "Member (100)" 14/18 `#8C99A6` + chevron-up 14 (พับได้) · แถว member h 56 px 16 py 8 radius 8 gap 8: avatar 40 + status · ชื่อ 14/18 **Medium** white · บรรทัด 2 12/15 `#8C99A6` = "Active" / "Busy" / custom status พร้อม emoji ("🚧 I'm doing my stuff") / "Active • 📅 In meeting" (In meeting สี `#996ADF`)

**Conversation แนวตั้ง (`5944-284186` DM · `6352-636709` group)**

| ส่วน | ค่า |
|---|---|
| Header cahr (ชื่อ layer ตาม Figma) | absolute top · pt 24 pb 8 px 16 · gap 8 · bg gradient `#1A1B1E` (36.9%) → โปร่ง + blur 6 · แถว gap 16: ปุ่ม back (bg white 5% p 8 radius 8) · **pill กลาง** flex-1 bg white 5% radius 90 px 8 py 4: ชื่อ 12/15 Medium white + สถานะ 10/13 `#8C99A6` (DM = "Active" · group = "● 10 Online" จุด 4 px) · avatar 32 ขวา (DM = avatar กลม border white 20% · group = สี่เหลี่ยม radius 8 bg `#FFA8A8` icon member) |
| Pinned | bg white 5% radius 90 px 16 py 8 gap 8 · indicator 3 ขีด 4 px (2 ขีด white 10% + 1 ขีด white = อันที่ 3 ของ 3) · "Pinned messages #1" 10/13 grey + ข้อความ 12/15 white |
| Chat display | py 8 gap 8 · **Message type** px 16 py 8 gap 8: avatar 32 + status dot · ชื่อ 14/18 Medium + เวลา 10/13 grey ("09:00 AM") · ข้อความ 14/18 white กว้าง 248 + icon สถานะ 12 (✓✓ read / ✓ sent) · divider วัน "Today" 10/13 SemiBold grey มีเส้นซ้าย-ขวา p 8 |
| Input message (`5944-284232`) | absolute bottom · pt 8 pb 16 px 16 gap 8 · bg gradient ขึ้น + blur 6 · ปุ่มแนบ 42 bg `#232427` radius 8 icon 16 · input flex-1 h 42 bg `#232427` radius 8 px 12 py 8 gap 8: icon emoji 16 + "Message" `#636D76` · **ปุ่มไมค์ 42** ขวาสุด · เมื่อมีข้อความ (`6352-636729`): ปุ่มไมค์หาย ปุ่มส่ง bg `#58D68D` p 8 radius 8 icon 16 อยู่**ในช่อง** ขวา (pr 8) |
| รูปในข้อความ (`6352-589348`) | grid 2 คอลัมน์ radius 8 (5 รูป = 2+2+1) + ลิงก์ "Download all" 10/13 grey ใต้ grid |
| Reaction ใต้ข้อความ (`6352-634561`) | chip emoji + จำนวน ("👍1 🎉1 ❤️1 …") แถวเดียวใต้ข้อความ |

**Long pressed (`6352-634416`)**: overlay `rgba(0,0,0,0.5)` blur 6 · ข้อความที่กดค้าง render ซ้ำเหนือ overlay ตำแหน่งเดิม (top 589) · **Chat menu** w 200 gap 5 อยู่เหนือข้อความชิดขวา (left 174 top 218): **Emoji panel** bg `#1A1B1E` radius 8 p 8 gap 8 emoji 16 × 7 = 👋 ❤️ 🎉 👍 🤣 👏 💯 + icon ➕ 16 · **Submenu** w 184 bg `#1A1B1E` radius 16 p 8 gap 8: Menu item min-h 42 p 12 radius 8 icon 16 + label 14/18 white = Reply · Thread · Copy · Pin · Forward · Select ┃ divider ┃ Delete `#F03A3A`

**Mention (`6361-638009`)**: input มี "@" + ปุ่มส่ง (ไมค์หายแล้ว) · **Submenu** absolute bottom 404 (เหนือคีย์บอร์ด) left/right 4.1% · bg `#1A1B1E` radius 16 p 8 · shadow `0 4 16 rgba(255,255,255,0.08)` · แถว Member list p 8 radius 8 gap 8: avatar 32 + status · ชื่อ 14/18 Medium · "Active" 12/15 grey (3 คน) · แถวสุดท้าย Menu p 12: "@Everyone" 14/18 Medium white + "Notify everyone in this chat" 14/18 `#8C99A6` ชิดขวา · คีย์บอร์ด iOS dark (`rgba(32,32,32,0.92)` blur 10, key `#434343` h 42 radius 4.6, suggestion bar h 34) = component ระบบ ไม่ต้องทำ

**Loading (`6361-639382`)**: ข้อความเก่าที่ยังไม่โหลด opacity 0 · icon Reload 16 อยู่กลางแถว (ใน Chat display ก่อน divider "Today")

**Preview image (`6352-633794` + variants `633795` เต็ม / `633882` zoom / `633890` zoom+เมนู)**: รูปเต็มจอ radius 8 · **header** bg `#1A1B1E` blur 6 pt 24 pb 8 px 16 กว้าง 358: ปุ่ม × (bg white 5% p 8 radius 8) · avatar 32 + "You" 14/18 white (w 150) + "Today, 09:00 AM" 10/13 grey · ขวา: ปุ่ม download + ปุ่ม ⋮ (bg white 5% p 8 radius 8 gap 8) · **bottom** bg `#1A1B1E` blur 6 pt 16 pb 24: filmstrip thumb 24×40 radius 4 opacity 60% gap 4 · รูปปัจจุบัน 28×44 opacity 100 · variant zoom = header/bottom หาย

**แนวนอน (`6580-167869` / `6580-169952`)**

| ส่วน | ค่า |
|---|---|
| กรอบ | Chat ที่ left 32 top 16 w 780 justify-between (ไม่ใช่เต็มจอ — ทับแมพ ไม่มี bottom nav) |
| คอลัมน์ซ้าย 249 | แถวบน gap 8: icon × 16 (ปิด overlay) · search h 42 (ไม่มี icon) · **ปุ่ม filter 42** bg white 5% border white 20% radius 8 icon 16 · ด้านล่างเป็นการ์ด bg `#232427` radius 16: Threads Messages + แถวแชทเหมือนแนวตั้ง (px 16 py 8) · แถวที่เปิดอยู่ bg white 5% · **ไม่มี tab All/Channel/Group/DM** (ใช้ปุ่ม filter แทน) · FAB 48 absolute left 193 top 318 (มุมขวาล่างคอลัมน์) |
| คอลัมน์ขวา 515 | h 374 radius 16 overflow clip · Header cahr เหมือนแนวตั้งแต่**ไม่มีปุ่ม back** (pill ชื่อ + avatar 32) + Pinned · "Chat display + Menu" p 8 gap 16 · Input message pb 16: ปุ่มแนบ 42 + input (emoji + ข้อความ + ปุ่มส่งใน) |
| Create (`6580-168687`) | overlay blur ทั้งจอ · เมนู 2 ข้อชิดขวาคอลัมน์ซ้าย เหนือ FAB |
| Start a new chat (`6580-169390`) | overlay เต็มจอ: back + title กลาง · search กว้างเต็ม · Member (100) list |
| Keyboard (`6707-139456`) | **Input message block** absolute bottom h 190 เต็มกว้าง blur 6: แถว input px 16 (แนบ 42 + input "@" + ส่ง) + พื้นที่เทา `#D9D9D9` = คีย์บอร์ดระบบ · ทับทั้ง 2 คอลัมน์ |
| Mention (`6604-180983`) | Submenu absolute bottom 66 left 35.19% right 3.79% (ทับคอลัมน์ขวา) 2 แถว · shadow เหมือนแนวตั้ง |
| Long pressed (`6604-180058`) | Emoji panel + Submenu อยู่มุมขวาบนคอลัมน์ขวา (ทับ header) · ข้อความที่กดค้างยกขึ้นเหนือ overlay |
| Preview (`6604-178984`) | header เต็มกว้าง (× + You + download/⋮) · รูปตั้งกลาง (สูงเต็ม ขอบเทาซ้ายขวา) · filmstrip ล่าง |
| Loading (`6604-246255`) | icon Reload ใต้ Pinned ก่อน divider "Today" |

### 9.3 พฤติกรรมจาก sticky note ใน Figma (คำพูด design)

| จุด | sticky |
|---|---|
| Preview image | "Tap ที่ภาพ 1 ครั้ง = Preview ภาพเต็ม" · "Pinch out = ขยายภาพ + เมนูหาย, Tap ที่ภาพ = เมนูขึ้น" · "Pinch in = ภาพกลับขนาดเดิม + เมนูขึ้น" |
| Mention | "แนะนำรายชื่อคนที่คุยด้วยบ่อย 3–4 คน · เลื่อนดูได้ · พิมพ์ชื่อต่อจะขึ้นรายชื่อที่ตรง" |
| Load older | "Scroll ขึ้นไปบนสุด แสดง loading icon" |
| Keyboard แนวนอน | "หา Keyboard landscape สำเร็จรูปไม่เจอ ขออนุญาตไม่ใส่ พอกดอยากให้ Keyboard ขยายเต็มพื้นที่เลย" |
| ถูก mention | frame `6361-638015` ชื่อ "หน้า Chat กรณีเราถูก Mention" = แถวแชทมี chip @You |

### 9.4 เทียบกับโค้ดจริง (`zyra-app/views/chat/**`)

| Figma HP-05 | โค้ดปัจจุบัน | สถานะ |
|---|---|---|
| Chat list เต็มจอ → conversation เต็มจอ (stack) | `chat-surface.tsx:294,338-353` เป็น 2 คอลัมน์ sidebar 320 + flex-1 | ⚠️ ต้อง stack บนแนวตั้ง (screens E CH4 มีแล้ว) · **แนวนอนใช้ 2 คอลัมน์เดิมได้เลย** แค่ย่อเป็น 249/515 |
| Tab All / Channel / Group / Direct message | `chat-sidebar.tsx:523-541` เป็น 3 section พับได้ (Channels / Groups / Direct messages) + search + filter popover `search-filter-popover.tsx` | ⚠️ แนวตั้งเปลี่ยนเป็น tab · แนวนอนใช้ปุ่ม filter เดิม |
| Threads Messages + badge | `chat-sidebar.tsx:55-57` `onOpenThreads` + unread count · `threads-messages-panel.tsx` | ✅ มีแล้ว |
| FAB → Create chat / Start a new chat | `chat-surface.tsx:222-223` `onCreateGroup` / `onCreateChannel` → `create-group-modal.tsx` · `start-new-chat-panel.tsx` | ✅ มีทั้งคู่ — แต่โค้ดแยก Group กับ Channel เป็น 2 ปุ่ม Figma มี "Create chat" ปุ่มเดียว (คำถาม 1) |
| Start a new chat: รายชื่อ + สถานะ | `start-new-chat-panel.tsx:49-56` ใช้ `useWorkspaceMembers` กรอง `status === "confirm"` — แสดงเฉพาะชื่อ **ไม่มี** Active/Busy/custom status/In meeting | ⚠️ ต้องต่อ presence + custom status + meeting state เข้าแถว |
| Long-press → Emoji panel + Submenu | `message-context-menu.tsx:51-81` มี Reply · Thread (`replyInThread`) · Copy · Pin/Unpin · Forward **disabled** · Select **disabled** · Download/Download all · Delete = ชุดเดียวกับ Figma · quick bar `emoji-picker.tsx:85` `QUICK_EMOJIS` = 👋 ❤️ 🎉 👍 🤣 👏 💯 **ตรง Figma ทั้ง 7 ตัว** | ✅ เมนูมีครบ · ⚠️ trigger เป็น hover/right-click ไม่มี `onTouchStart`/long-press (`message-item.tsx` grep = 0) → ต้องเพิ่ม long-press + overlay blur + ยกข้อความ (screens E CH1) · Forward/Select ยัง disabled (คำถาม 3) |
| Mention popup + @Everyone | `message-input.tsx:84-116` + `EVERYONE_SUGGESTION` (`message-input-utils.ts:4-7`) · เรียงตาม member ของห้องกรองด้วย query · เลือกด้วย Arrow/Enter | ✅ มี · ⚠️ **ไม่มีการจัดอันดับ "คุยบ่อย 3–4 คน"** (คำถาม 4) · ต้องเปลี่ยน Arrow/Enter → tap (screens E) |
| chip @You ใน Chat list | `chat-sidebar.tsx` preview บรรทัด 2 — ยังไม่เห็น logic chip mention 🔍 | 🔍 ต้องเช็ค unread/mention flag จาก store |
| Load older + spinner | `message-list.tsx:105,249` IntersectionObserver โหลดหน้าเก่าเมื่อเลื่อนถึงบน | ✅ logic มี · ⚠️ ต้องใส่ icon Reload 16 ตาม Figma |
| รูป grid + Download all | `message-attachment-block.tsx:20,29,49-57` grid 160×160 + "Download all" | ✅ มี · ⚠️ มือถือเป็น 2 คอลัมน์เต็มกว้าง |
| Preview image + filmstrip + pinch | `file-preview.tsx:84-139` zoom ด้วย wheel + drag pan เฉพาะ mouse · filmstrip + nav chevron ✅ | ⚠️ ต้องเพิ่ม pinch (pointer events) + แตะสลับซ่อน/โชว์ header-bottom + zoom แล้วซ่อนเมนูอัตโนมัติ (screens E CH6) · download → Filesystem/Share plugin (B5) |
| ปุ่มไมค์ในช่องพิมพ์ (voice message) | grep `mic` / `MediaRecorder` ใน `message-input.tsx` = **0** | ❌ **ไม่มีในโค้ด** (คำถาม 2) |
| Emoji keyboard ของระบบ | `emoji-picker.tsx` เป็น picker ของเราเอง (custom popover) | ⚠️ Figma ใช้คีย์บอร์ด emoji iOS — แอปสลับคีย์บอร์ดเป็น emoji เองไม่ได้ (คำถาม 5) |
| Pinned bar | `pin-banner.tsx` | ✅ มี |
| สถานะ ✓ / ✓✓ ท้ายข้อความ | `message-item.tsx:83` มี reader count สำหรับ channel/group เท่านั้น | 🔍 DM read receipt ยังไม่เห็น (คำถาม 11) |
| Thread panel / info panel / media panel | `thread-panel.tsx`, `conversation-info-panel.tsx`, `conversation-media-panel.tsx` (320 px ขวา) | ⚠️ **ไม่มีใน HP-05** (คำถาม 10) |

### 9.5 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §9.6)

- screens.md E: เพิ่ม 9 แถว (Chat list tab / landscape overlay ทับแมพ engine render ต่อ / FAB + Start a new chat status / long-press overlay + Forward + Select / mention ranking + chip @You / preview pinch + Photos / **voice message ใหม่** / create group+channel บนมือถือ / thread-info-media full-screen / DM read receipt / คีย์บอร์ดดันข้อความล่าสุด)
- task-breakdown 0.21–0.27: chat มือถือ 7 task (layout, long-press + Forward/Select, preview, mention, **voice message**, Start a new chat + create + panel, DM read receipt)
- clickup-spec §18 ข้อ 33–36: swipe/pull-to-refresh ไม่มีใน Figma · เมนู long-press 7 ข้อไม่ใช่ 4 · emoji = picker ของเรา · voice message ไม่มีใน ClickUp
- spec.md: ตารางโหมดเพิ่มแถว "แชท" · OQ 17–19 (Create chat ค้าง, เกณฑ์ "คุยบ่อย", เมนู ⋮ ใน preview) · OQ 16 เพิ่ม UI จาก §9.7
- technical-design: ยังไม่แก้ — overlay แชทแนวนอนให้ engine render ต่อ (ไม่ใช้ `setRenderSuspended`) จะใส่ตอนเขียน §17 chat/voice message

### 9.6 คำถาม / ข้อสงสัย HP-05 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | **"Create chat"** ในเมนู FAB = สร้าง Group หรือ Channel? โค้ดแยกเป็น 2 ปุ่ม (`onCreateGroup` / `onCreateChannel`) แต่ Figma มีปุ่มเดียว — และหน้า create group/channel บนมือถือไม่มีใน HP-05 | ✅ **มีให้เลือกสร้างทั้งสอง** (Ten 2026-10-01) — "Create chat" เปิด sheet เลือก **Group / Channel** แล้วต่อยอด `create-group-modal.tsx` · 🎨 sheet เลือกประเภท + หน้าสร้างยังไม่มี frame (§9.7) · **ปิดแล้ว 2026-10-05: Figma แยกเป็น Create channel / Create group ในเมนู FAB เอง** (§22.1) |
| 2 | **ปุ่มไมค์** = voice message (ใหม่ทั้ง backend + player) หรือ dictation ของคีย์บอร์ด | ✅ **ทำรอบแรก** — voice message จริง (task 0.25) |
| 3 | **Forward / Select** ยัง disabled บน desktop — ทำใน scope mobile ไหม | ✅ **ต้องทำใน scope mobile** (task 0.22 — ทำบน desktop ไปด้วยเพราะเป็น component เดียวกัน) |
| 4 | **Mention "คุยบ่อย 3–4 คน"** นับจากอะไร · @Everyone ล่างสุดเสมอ? | ✅ **@Everyone ล่างสุดเสมอ** · เกณฑ์ "คุยบ่อย" Ten ไม่ได้ระบุ → สมมติ: เรียงตามคนที่มีข้อความถึงกันล่าสุดในห้องนี้ (spec OQ 18) |
| 5 | **Emoji** — iOS สลับคีย์บอร์ดเป็น emoji เองไม่ได้ เสนอปุ่ม 😊 เปิด picker ของเราเป็น bottom sheet | ✅ **โอเค** — ใช้ `emoji-picker.tsx` เป็น bottom sheet |
| 6 | **overlay แชทแนวนอน** แมพยัง render อยู่ หรือหยุด | ✅ **render อยู่** — ไม่ใช้ `setRenderSuspended` · เสียง/knock ยังทำงานตามปกติ |
| 7 | **คีย์บอร์ดแนวนอน** บังทั้งหมด ยอมรับ หรือเลื่อนให้เห็นข้อความ | ✅ **ดันข้อความล่าสุดขึ้นไป** ให้เห็นเหนือ input (ไม่ปล่อยให้บัง) |
| 8 | **Preview** ⋮ มีอะไร · download = Photos + permission? | ✅ **download = บันทึกลง Photos (ขอ permission)** · เมนู ⋮ ยังไม่ระบุ (spec OQ 19) |
| 9 | **แท็บ Channel** สร้าง channel บนมือถือได้ไหม | ✅ **ทำ** — สร้างได้บนมือถือ |
| 10 | **Thread / info / media panel** ไม่มีใน HP-05 — ทำบนมือถือไหม | ✅ **"สร้างได้"** — ทำบนมือถือ ต่อยอดจาก desktop เป็น full-screen push (UI ยังไม่มีใน Figma 🔍 §9.7) · **2026-10-02: Chat info เป็นแท็บแบบ Telegram ตามโน้ต Pai → §9.8** |
| 11 | **✓ / ✓✓ ใน DM** — read receipt มีใน backend ไหม | ✅ **"อะไรไม่มีเพิ่มได้เลย"** — ถ้า backend ไม่มี DM read receipt ให้เพิ่ม (task 0.27 🔍 ต้องเช็ค zyra-ws/zyra-api ก่อน) |
| 12 | แนวตั้งมีแท็บ แนวนอนใช้ปุ่ม filter — ตั้งใจให้ต่างกัน? | ✅ **ใช่** — ตามนั้น |

### 9.7 UI ที่ต้องขอเพิ่มจาก design (ไม่มีใน HP-05 แต่จำเป็นตามคำตอบ)

| UI | เหตุผล |
|---|---|
| **Voice message**: สถานะกำลังอัด (ปุ่มไมค์กดค้าง? / แตะ), ยกเลิก, bubble เสียง + player (เล่น/หยุด, คลื่นเสียง, ความยาว) ทั้งฝั่งส่งและรับ | ข้อ 2 |
| **Create chat** sheet (เลือก Group / Channel) + หน้าสร้าง Group / Channel บนมือถือ (ชื่อ, เลือกสมาชิก, รูป) | ข้อ 1 + 9 · **แก้ 2026-10-02 (โน้ต Pai): หน้า New group ตามโน้ต Pai §19.1 → ux-ui-plan §19** · **sheet ไม่ต้องมีแล้ว (Figma 5944-134262 แยกเมนู)** เหลือแค่หน้า New group / New channel |
| **Thread panel / Conversation info / Media panel** แบบ full-screen บนมือถือ — ทางเข้า = แตะชื่อห้องที่ header · Chat info เป็นแท็บแบบ Telegram (§9.8 · Pai เขียนโน้ตแล้ว รอวาด frame) | ข้อ 10 |
| เมนู **⋮ ใน preview image** (รายการคำสั่ง) | ข้อ 8 |
| **Forward** (เลือกห้องปลายทาง) + **Select** (multi-select + แถบคำสั่ง) บนมือถือ | ข้อ 3 |
| **Create chat** sheet ตอนเปิดจากแนวนอน | ข้อ 1 |

### 9.8 Chat info แบบแท็บคล้าย Telegram (โน้ต Pai 2026-10-02 · Ten ตอบ "ตามแนะนำ" 2026-10-02)

**ที่มา:** sticky note ของ Pai บน mockup card 06 "ปรับ UI เป็น Tap คล้าย Telegram" + ภาพอ้างอิงหน้า group info ของ Telegram · **ยังไม่มี frame ใน Figma** ค่าด้านล่างเป็นข้อเสนอจาก mockup 🎨 Pai วาดแล้วค่อยยึด Figma

**ข้อมูลมีครบแล้วบนเว็บ งานนี้เป็น UI อย่างเดียว:** Members + role Owner/Admin/Member + ตั้ง/ถอด Admin (`conversation-info-panel.tsx`) · images / files / links / pinned / threads (`conversation-media-panel.tsx` type `MediaTab`) · Mute / Settings / Leave (`conversation-menu.tsx`) · ค้นหา (`use-chat-search.ts`) · `addMembers` / `removeMember` (`lib/api/chat.ts:289,302`)

```
[‹]                              [Edit]   ← Edit เฉพาะ Owner/Admin (group/channel)
            avatar 72
            Design review
            Group · 6 members
   [Mute]     [Search]     [Leave]          ← 3 ปุ่ม ไม่มี More
[Members][Media][Files][Links][Threads][Pinned]   ← เลื่อนซ้ายขวา · ติดบนสุดเมื่อเลื่อนจอ
 + Add members
 รายชื่อ (จุด presence + สถานะ · ป้าย owner / admin)
```

| ส่วน | spec |
|---|---|
| ทางเข้า | แตะชื่อห้องที่ header ของห้องแชท → เปิดเต็มจอ (push) |
| หัว | ปุ่ม back ซ้าย · **Edit** ขวา = Settings ของกลุ่มที่เว็บมีอยู่ (Owner/Admin เท่านั้น) · avatar 72 · ชื่อ · "Group · N members" / "Channel · N members" |
| แถวปุ่ม | **Mute · Search · Leave** (3 ปุ่ม เท่ากัน) · Mute สลับเป็น Unmute เมื่อปิดเสียงอยู่ · Search = ค้นข้อความในห้อง · Leave → หน้ายืนยันก่อนออก · ตัด More ออก (ไม่มีเมนูเหลือ) |
| แท็บ | **Members · Media · Files · Links · Threads · Pinned** เลื่อนซ้ายขวาได้ · ไม่มี GIFs · แต่ละแท็บว่าง = ข้อความ empty state |
| ตอนเลื่อน | หัวและแถวปุ่มเลื่อนหายขึ้นไป · แถบแท็บติดบนสุด · ชื่อกลุ่มย่อลงไปอยู่บน header |
| Members | แถว **Add members** บนสุด (สิทธิ์ตามเว็บเดิม) · รายชื่อ: avatar + จุด presence · ใต้ชื่อเป็นสถานะ **Active / Away / Busy / Do not disturb / Offline** (Zyra ไม่มีข้อมูล last seen) · ป้าย **owner / admin** ท้ายแถว |
| แตะสมาชิก | action sheet: View profile · Send message · (Owner/Admin) Make admin / Remove admin · Remove from group |
| DM | ไม่มีแท็บ Members · ปุ่มเหลือ **Mute · Search** · ไม่มี Leave · ไม่มี Edit · ใต้ชื่อเป็นสถานะของอีกฝ่าย |
| ที่ตัดออกจาก mockup เดิม | สวิตช์ Mute notifications และปุ่ม Leave group สีแดง (ซ้ำกับแถวปุ่ม) · รายการ Members / Media and files / Threads / Pinned messages แบบเมนู → เป็นแท็บแทน |

| # | คำถาม | คำตอบ |
|---|---|---|
| 1 | แท็บมีอะไร | ✅ Members · Media · Files · Links · Threads · Pinned เลื่อนได้ ไม่มี GIFs |
| 2 | ปุ่มบนแถว | ✅ Mute · Search · Leave ตัด More |
| 3 | ปุ่ม Edit | ✅ เปิด Settings ของกลุ่มเดิม Owner/Admin เท่านั้น |
| 4 | DM | ✅ ไม่มี Members / Leave / Edit · ปุ่ม Mute + Search |
| 5 | ข้อความใต้ชื่อสมาชิก | ✅ สถานะ presence แทน last seen |
| 6 | Add members / จัดการสมาชิก | ✅ สิทธิ์ตามเว็บ · แตะสมาชิก = action sheet |
| 7 | ตอนเลื่อน | ✅ แท็บติดบนสุด ชื่อย่อขึ้น header |
| 8 | สวิตช์ Mute และปุ่ม Leave สีแดงเดิม | ✅ ตัดออก · Leave ต้องยืนยันก่อน |

## 10. HP-06 · Mobile Responsive — Sidebar & Navigation (รับ 2026-10-01 · Ten ตอบ 2026-10-01)

**Node:** แนวตั้ง section `6377-27023` (ลิงก์จาก Ten `?node-id=6377-27023&m=dev`) · **แนวนอน: Ten แจ้ง "Landscape ไม่มี Bottom bar"** — ไม่มี section Figma · ดึงผ่าน `get_metadata` + `get_design_context` 3 frame (Workspace lists, Notification, Profile) + screenshot 6 frame · Homepage / Chat ในส่วนนี้เป็น instance เดียวกับ HP-03 §3.8 / HP-05 §9.2 (เอามาแสดงสถานะ active ของ bottom nav)

### 10.1 โครง section (5 frame แนวตั้ง + sticky 1)

| frame | node | ทำหน้าที่ใน flow |
|---|---|---|
| Homepage | `6377-27025` (instance ของ 5800:425090) | Lite Home = แท็บ **Home** active · header: โลโก้ 40 + "Starlight Workspace ⌄" + "100 Members · 50 Online" + ปุ่ม user-plus + กระดิ่ง badge 10 |
| **Worksapce lists** (ชื่อ layer ตาม Figma) | `6379-34971` | เปิดจาก **chevron ⌄ ข้างชื่อ workspace** บน header → หน้าเต็มจอรายการ workspace · sticky `6379-34974`: **"เลือกแล้ว Reload > เข้า Workspace > Flow ถามว่าจะเข้าสู่ Lite Mode (ตั้ง) หรือ Spatial Mode (นอน)"** = เลือก workspace ใหม่ → โหลดใหม่ → ผ่านหน้า Select workspace mode (§3.4) อีกครั้ง |
| Notification | `6104-81581` | เปิดจาก**กระดิ่ง**บน header → หน้าเต็มจอ (มีปุ่ม back, ไม่มี bottom nav) |
| Chat | `6668-244303` (instance ของ 5944:134033) | แท็บ **Chat** active + badge 10 (รายละเอียด §9.2) |
| Profile | `6668-244816` (instance ของ 5889:432902) | แท็บ **Profile** active (ปุ่มที่ 4 = avatar ของตัวเอง) |

**Bottom nav (ทุก frame ที่มี):** h 56 · bg `rgba(26,27,30,0.5)` · radius 1000 · p 4 · `left/right 4.1%` (= 16 px) · `bottom 16` · 4 ปุ่ม flex-1 h-full p 8 icon 24: **Home · Chat · Calendar · Profile (avatar 24)** · active = bg white 20% radius 90 · badge แดง `#D41818` radius 90 text 10/14 Medium w 16 ที่มุมขวาบน icon (`top 8`, Chat = "10") · ไม่มี label ข้อความ · **หน้าลูก (Workspace lists / Notification / ห้องแชท / Start a new chat) ไม่มี bottom nav** ใช้ปุ่ม back แทน · แนวนอน (Spatial) **ไม่มี bottom nav เลย** — nav อยู่ที่ปุ่มกลม 5 ปุ่มขวาบน + Meeting Menu (§3.9)

### 10.2 Spec ต่อหน้า (จาก `get_design_context`)

**Workspace lists (`6379-34971`)**

| ส่วน | ค่า |
|---|---|
| Title menu | `left 16 top 16 w 358` gap 8 · ปุ่ม back bg white 5% p 8 radius 8 chevron-left 16 · "Workspace Lists" Sub/Bold 16/22 กลาง · ช่องว่างขวา 32 |
| Search | `top 72` · input w 305 h 42 bg `#232427` border white 20% radius 8 px 12 py 8 placeholder "Search for your workspace" `#636D76` 14/18 (ไม่มี icon) + ปุ่ม filter 42 bg white 5% border white 20% radius 8 icon 16 |
| รายการ | flex-col gap 8 (ใต้ search gap 16) |
| **Worksapce card** | bg `#232427` radius 16 p 8 · แถว gap 8: รูป 80×80 radius 8 · คอลัมน์ขวา justify-between: ชื่อ 14/18 **Medium** white ellipsis · "Last visited : Sep 18, 2025 (13:00 PM)" 12/15 `#8C99A6` · แถวล่าง gap 8: **Tag บทบาท** px 4 py 2 radius 4 icon 14 + text 12/15 — Owner = `rgba(255,128,0,0.1)` + border เดียวกัน text `#FF8000` (icon user-star) · Admin = `rgba(45,182,255,0.1)` text `#2DB6FF` (icon user) · Member = `rgba(88,214,141,0.1)` text `#58D68D` (icon member) · เส้นคั่นแนวตั้ง 16 · **Workspace capacity** pill bg white 5% radius 16 px 4 py 2 w 70 icon member 12 + "15/50" 12/16 `#58D68D` (**แสดงเฉพาะ Owner/Admin**; Member ไม่มี) · **ppl online** pill bg white 5% radius 16 px 4 py 2 จุดเขียว 10 + "10" 12/16 white |
| ไม่มี | bottom nav · ปุ่ม Create workspace · ปุ่ม join ด้วย link (🔍 ไม่มีใน frame) |

**Notification (`6104-81581`)**

| ส่วน | ค่า |
|---|---|
| Title menu | `top 24 w 358` · ปุ่ม back + "Notification" Sub/Bold กลาง |
| แถวแท็บ | `top 72 w 358` justify-between · ซ้าย: **Tap underline** "All" / "Unread" p 8 text 14/18 white · active = `border-b` 1 px `#58D68D` · ขวา: icon read (✓✓) 12 + "Mark as read" 12/15 `#8C99A6` |
| กลุ่มตามวัน | หัวข้อ "Today" / "Yesterday" 12/15 white · `top 122` · gap 16 ระหว่างหัวข้อกับการ์ด · การ์ด gap 8 |
| **Notification card** | p 8 radius 8 gap 8 · **ยังไม่อ่าน = bg white 5%** · อ่านแล้ว = โปร่ง · avatar 32 (ระบบ = วงกลม `#7EA2FC` icon กระดิ่ง · คน = avatar + status dot) · แถวบน: ชื่อ/หัวข้อ 14/18 Medium white flex-1 + เวลา "1 min ago" 12/16 `#8C99A6` · ข้อความ 14/18 `#8C99A6` **คำสำคัญเป็น white** ("Our **new chat feature** is here!", "X **invited** you to **Marketing Team**", "X **mentioned** you in **Threads**", "X **waved** at you!") |
| ประเภทที่เห็น | New update (ระบบ) · invited to group · mentioned in Threads · waved |
| ไม่มี | bottom nav · ปุ่มลบ/swipe · การตั้งค่าแจ้งเตือน (อยู่ Profile → Setting → Notification) |

**Profile (`6668-244816` = 5889:432902)**

| ส่วน | ค่า |
|---|---|
| Title menu | `top 24` "Profile" Sub/Bold กลาง (ปุ่ม back opacity 0 = ไม่มี เพราะเป็นแท็บหลัก) · เนื้อหา `left 16 top 72 w 358` flex-col gap 16 |
| การ์ด **User status** | bg `#232427` radius 16 p 16 gap 16 · แถวบน gap 16: avatar 40 + status dot · ชื่อ 14/18 Medium + "Active" 14/18 `#8C99A6` · **chevron-right 16** (ไปหน้าแก้โปรไฟล์) · divider white 10% · **status picker 3 ปุ่ม** flex-1 p 8 radius 8 gap 8 จุด 10 + text 14/18: Active (active = bg `rgba(88,214,141,0.1)` border `rgba(88,214,141,0.2)`) · Busy (จุด `#FF8000`) · Away (จุดวงแหวน) · ปุ่มไม่ active border white 10% · **custom status input** h 42 bg `#232427` border white 20% radius 8 icon emoji 16 + placeholder "What are you thinking?" |
| กลุ่ม **Setting** | หัวข้อ 12/15 `#8C99A6` p 8 · การ์ด bg `#232427` radius 16 p 8 · แต่ละ Menu min-h 42 p 12 radius 8 gap 8 icon 16 + label 14/18 white flex-1 + (ค่า 14/18 `#8C99A6`) + chevron-right 16: **Account and Security** · **Language** (ค่า "English") · **Audio** · **Camera** · **Notification** |
| กลุ่ม **Workspace** | **Manage member** · **Environment** · **Workspace mode** (ค่า "Lite mode") |
| กลุ่ม **Support** | **Help** · **Legals** |
| การ์ดสุดท้าย | **Switch workspace** (icon leave) · **Log out** text `#F03A3A` (icon exit) |
| Bottom nav | แท็บที่ 4 active (avatar) |

### 10.3 Navigation model ที่ได้จาก HP-06 (สรุปเป็นกฎ)

| กฎ | รายละเอียด |
|---|---|
| **ระดับ 1 = แท็บ** | Home / Chat / Calendar / Profile — bottom nav โชว์เฉพาะ 4 หน้านี้ (**รอบแรกซ่อน Calendar → 3 แท็บ** — Ten 2026-10-01) (Calendar ยังไม่มี frame ใน HP-06 🔍) |
| **ระดับ 2 = หน้าลูก** | Workspace lists, Notification, ห้องแชท, Start a new chat, หน้าย่อยใน Profile (Account and Security / Language / Audio / Camera / Notification / Manage member / Environment / Workspace mode / Help / Legals) → **ซ่อน bottom nav + ปุ่ม back ซ้ายบน** (Title menu: back + หัวข้อกลาง Sub/Bold) |
| **ทางเข้าจาก header** | chevron ⌄ ข้างชื่อ workspace → Workspace lists · กระดิ่ง → Notification · user-plus → ชวนคน (sheet ชวนคนตาม §8.7) |
| **สลับ workspace** | เลือกการ์ด → reload → **Select workspace mode (§3.4) อีกครั้ง** (sticky `6379-34974`) · มีทางเข้าซ้ำที่ Profile → "Switch workspace" |
| **เปลี่ยนโหมด** | Profile → Workspace → **Workspace mode** (ค่าปัจจุบัน "Lite mode") = ที่เดียวที่เปลี่ยน Lite ↔ Spatial ได้ (ตรงมติ §7 ข้อ 1 / TD §16.1) |
| **แนวนอน** | **ไม่มี bottom nav** — Spatial ใช้ปุ่มกลม 5 ปุ่มขวาบน + ปุ่ม chat ซ้ายล่าง + Meeting Menu (avatar = Settings/status/Profile) ตาม §3.9 · Profile/Notification/Workspace lists ในแนวนอนยังไม่มี frame 🔍 (เป็น modal ทับแมพ? — คำถาม 4) · **แก้ 2026-10-02 (โน้ต Pai): Notification แนวนอน = drawer กว้าง 390 สูงเต็มจอจากขวา แตะข้างนอกปิด (§19.2) → ux-ui-plan §19** |
| **ClickUp HP-06 ที่ต่าง** | ClickUp: "Active state: icon + label + underline" → Figma **icon-only, ไม่มี label, active = วงกลม bg white 20%** · "More → bottom sheet" → ไม่มีปุ่ม More · "Workspace switcher: กด workspace name → bottom sheet" → Figma เป็น **หน้าเต็มจอ** ไม่ใช่ sheet · "Back: swipe right (iOS) / back button (Android)" → Figma มีปุ่ม back ในหน้าเสมอ |

### 10.4 เทียบกับโค้ดจริง

| Figma HP-06 | โค้ดปัจจุบัน | สถานะ |
|---|---|---|
| Bottom nav 4 แท็บ icon-only + badge | ไม่มี — desktop ใช้ `components/app-navbar.tsx` (navbar บน) + HUD ซ้ายใน VO · Lite shell = task 0.14 | ❌ ใหม่ (0.14 มีอยู่แล้ว แค่เพิ่มกฎซ่อน nav ในหน้าลูก) |
| Workspace lists (การ์ด: รูป, Last visited, Tag บทบาท, 15/50, online) | `views/user/workspace/hero-user-workspace.tsx` + `components/workspace-card.tsx:253-257` มี `last_visited_at`, `member_role`, `capacity`, `member_count`, `online_count` **ครบทุก field** | ✅ ข้อมูลครบ · ⚠️ layout เป็น grid desktop → การ์ดแนวนอน 80 px + ซ่อน capacity สำหรับ Member · search/filter ยังไม่มี (🔍 filter กรองอะไร — คำถาม 2) |
| เลือก workspace → reload → Select mode อีกครั้ง | `localStorage zyra_workspace_mode` (TD §16.1) จำ 24 ชม. **ทุก workspace** | ⚠️ **ขัดกัน**: sticky บอกถามโหมดทุกครั้งที่สลับ workspace แต่มติ §7 ข้อ 3 บอกจำ 1 วันทุก workspace (คำถาม 1) |
| Notification เต็มจอ: All / Unread + Mark as read + กลุ่ม Today/Yesterday + ยังไม่อ่าน bg | `vo-notification-panel.tsx:109-243` มี tab all/unread, `notificationUnread`, `clearUnread`, mark-all-read (`:243`) · REST-only ไม่มี WS push (`:109`) | ✅ logic ครบ · ⚠️ panel 322 px → หน้าเต็มจอ + กลุ่มตามวัน + ข้อความ highlight คำสำคัญ · ประเภท "New update" (ระบบ) ยังไม่มีใน backend 🔍 |
| Profile: status picker Active/Busy/Away + custom status | `vo-profile-panel.tsx:13-14,70` มี busy/away + custom status (emoji + text) · `lib/presence-status.ts:6` มี `meeting`/`dnd` เพิ่มด้วย | ✅ มี · ⚠️ panel 322 px → การ์ดในแท็บ Profile · `dnd` ไม่มีใน Figma (คำถาม 5) |
| Setting: Account and Security / Language / Audio / Camera / Notification | `vo-setting-modal.tsx:719-736` tab = profile · general · audio · notifications · manage · integrations · environment · `/setting` (`views/profile/*`) + `/setting/change-password` · `components/language-switcher.tsx` | ⚠️ ไม่มี **Camera** แยก (อยู่ใน media device menu) · ไม่มี "Account and Security" รวม (= `/setting` + change-password) · `general` / `integrations` ไม่มีใน Figma (คำถาม 3) |
| Workspace: Manage member / Environment / Workspace mode | `manage-members-modal.tsx` ✅ · `vo-environment-tab.tsx` (flag `isEnvironmentTabVisible`) ✅ · Workspace mode = ใหม่ (task 0.12) | ✅/⚠️ modal 934×800 → หน้าเต็มจอ · Manage member บน desktop เฉพาะ owner/admin — Figma ไม่บอกว่าซ่อนสำหรับ Member (คำถาม 6) |
| Support: Help / Legals | `views/help-center/help-center-panel.tsx` · `/legal` (`views/legal/hero-legal.tsx`) | ✅ มี |
| Switch workspace / Log out | `vo-profile-panel.tsx:453` logout ✅ · switch = กลับ `/` (workspace list) | ✅ |
| Calendar แท็บ | ไม่มี feature ในโค้ด (clickup-spec §18 ข้อ 5) | ❌ ไม่มี frame ใน HP-06 ด้วย (คำถาม 7) |

### 10.5 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §10.6)

- screens.md: B แถว `/` workspace list (การ์ดมือถือ + filter เวลา + join ด้วย link) · F แถว Notification (เต็มจอแนวตั้ง / modal แนวนอน) · H แถว Profile tab + Setting ยึด Figma + Manage member/Environment เฉพาะ Owner/Admin · Lite shell กฎซ่อน nav ในหน้าลูก
- task-breakdown 0.14 (กฎ nav ระดับ 1/2 + badge) · 0.28 Workspace lists มือถือ · 0.29 Notification เต็มจอ/modal · 0.30 Profile tab + หน้าย่อย Setting
- clickup-spec §18 ข้อ 38–41: HP-06 AC ต่างจาก Figma (icon-only, ไม่มี More, switcher เต็มจอ, back button) + sticky ถามโหมดซ้ำถูก Ten ยกเลิก
- spec.md OQ 20–22 (dnd, Calendar tab, สร้าง workspace บนมือถือ) · OQ 13 เพิ่มหมายเหตุ sticky
- technical-design §16.1: **ไม่แก้** — Ten ยืนยันจำโหมดรวม 1 วันทุก workspace (sticky `6379-34974` ไม่ใช้) · เพิ่ม: Profile/Notification/Workspace lists ในแนวนอนเป็น modal ทับแมพ engine render ต่อ (เหมือน chat §9.6 ข้อ 6)

### 10.6 คำถาม / ข้อสงสัย HP-06 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | สลับ workspace แล้วถามโหมดใหม่ทุกครั้ง (sticky) หรือจำรวม 1 วันตามมติเดิม | ✅ **จำรวม 1 วันตามมติเดิม** — sticky `6379-34974` ไม่ใช้ · TD §16.1 คงเดิม · สลับ workspace ภายใน 24 ชม. ไม่ถามซ้ำ |
| 2 | ปุ่ม filter กรองอะไร · สร้าง workspace / join ด้วย link บนมือถือไหม | ✅ **filter = กรองตามเวลา** (last visited) · **join ด้วย link บนมือถือ ทำ** · สร้าง workspace บนมือถือ **ยังไม่ตอบ** (OQ 22) |
| 3 | Setting ยึด Figma (ตัด general/integrations, เพิ่ม Camera) · Account and Security = `/setting` + เปลี่ยนรหัสผ่าน | ✅ **ใช่** |
| 4 | แนวนอน: Profile / Notification / Workspace lists เป็น modal หรือเต็มจอ | ✅ **modal ทับแมพ** (เหมือน chat overlay — แมพ render ต่อ) · UI ยังไม่มี frame 🔍 §10.7 |
| 5 | สถานะ `dnd` ในโค้ด — ตัดบนมือถือ หรือรวมใน Busy | ✅ **ไม่ตัด ไม่รวม — เพิ่ม Do not disturb เข้าไป** (Ten 2026-10-01) → status picker มือถือ 4 ตัว Active / Busy / Away / Do not disturb (ใช้สีจาก `lib/presence-status.ts` เดิม) · 🎨 แถว DND ไม่มีใน Figma — design ยืนยัน |
| 6 | Manage member / Environment โชว์ทุกคน หรือเฉพาะ Owner/Admin | ✅ **เฉพาะ Owner/Admin** (Member ไม่เห็นกลุ่ม Workspace 2 แถวนี้ เหลือ Workspace mode) |
| 7 | แท็บ Calendar ไม่มีทั้ง Figma/โค้ด — ซ่อนหรือ Coming soon | ✅ **ซ่อนไปก่อน** (Ten 2026-10-01) → bottom nav เหลือ **3 แท็บ Home / Chat / Profile** · ✅ **ซ่อนทั้งหมด** (Ten ยืนยัน 2026-10-01): ปุ่ม calendar กลมขวาบน Spatial (เหลือ 4 ปุ่ม weather / megaphone / member / notifications) + กลุ่ม Calendar ใน Notification settings · กลับมาเมื่อมี feature Calendar · **แก้ 2026-10-02 (โน้ต Pai): ฟีเจอร์ที่ยังไม่มีอื่น ๆ ก็ซ่อนแบบเดียวกัน ไม่มี Coming soon (§19.7) → ux-ui-plan §19** |
| 8 | ยืนยันหน้าลูกซ่อน bottom nav + Android back / iOS swipe-back = ปุ่ม back | ✅ **ใช่** (Ten 2026-10-01) — หน้าลูกไม่มี bottom nav · Android back / iOS swipe-back = ปุ่ม back |

### 10.7 UI ที่ต้องขอเพิ่มจาก design

| UI | เหตุผล |
|---|---|
| **modal แนวนอน** ของ Profile / Notification / Workspace lists ทับแมพ (ขนาด, ตำแหน่ง, ปุ่มปิด) | ข้อ 4 |
| หน้าย่อย Setting ทุกหน้า: **Account and Security, Language, Audio, Camera, Notification, Manage member, Environment, Workspace mode** (มีแค่แถวเมนู ยังไม่มีหน้าใน) | ข้อ 3 |
| **filter sheet** ของ Workspace lists (เรียงตามเวลา) + หน้า **join ด้วย link** บนมือถือ | ข้อ 2 |
| แท็บ **Calendar** (หน้าใน หรือ Coming soon) | ข้อ 7 |

## 11. HP-07 · App Conversion — Install & Onboarding (รับ 2026-10-01 · Ten ตอบ 2026-10-01)

**Node:** แนวตั้ง section `6407-1130015` · "แนวนอน" section `6663-237832` — ⚠️ **section แนวนอนเป็นสำเนาของแนวตั้ง** (frame ชุดเดียวกันทุกตัว ขนาด 390×844 ทั้งหมด ไม่มี 844×390 สักตัว) → ยังไม่มี design แนวนอนของ HP-07 (คำถาม 1) · ดึงผ่าน `get_metadata` ทั้ง 2 section + `get_design_context` 5 frame + screenshot 30 frame · ชื่อ section ใน Figma คือ "HP-07 · App Conversion — Install & Onboarding"
**ซ้ำกับ HP-03:** Splash, Onboarding 3 slide, Get started (Login), Space builder Empty/Fill ถอดไว้แล้วใน §3.1–3.3 · ส่วนนี้บันทึกเฉพาะ**ของใหม่** + ค่าที่ต่างจาก §3

### 11.1 โครง section (2 แถว)

| แถว | ลำดับ frame (ตามลูกศร) |
|---|---|
| **PWA Install** | Mobile landing page (`6407-1130019`, เว็บใน browser มือถือ แถบ URL "https://zyra-world…") → sticky `6411-1138264` **"โชว์ประมาณ 5 วินาที"** → Mobile landing page + **bottom sheet "Meet Zyra on mobile"** (`6411-1136764`) → หน้าแอปใน App Store (`6411-1141481`) |
| **App store** | App Store Today (`6411-1138267`, ภาพจริง IMG_8415) → Search (`6411-1138268`) → Search + คีย์บอร์ด (`6411-1138269`) → หน้าแอป Zyra ใน store (`6411-1136502`) → **Splash** (`6411-1142335`) → Slide 1 / 2 / 3 (`6411-1141300` / `1141306` / `1141313`) → Get started ว่าง / กรอกแล้ว (`6411-1141320` / `1141321`) → **Space builder – Empty** (`6411-1141322`) → **Create workspace** (เลือก template `5878-409509` / filter `5878-409778` / filter ตั้งค่าแล้ว `5889-415552` / เลือกแล้ว `5878-410434`) → **details** ว่าง / กรอกแล้ว (`5878-411780` / `5878-411781`) → **Workspace created** (`5878-414845`) → Space builder (`5840-1013823` Empty · `5833-1005970` Fill · `5837-1007062` Profile menu · `5840-1014009` + Submenu ⋮ 3 แบบ · `5840-1014307` Filter + sticky skeleton · `5840-1016017` ค้นหาเจอ · `5840-1014917` ค้นหาไม่เจอ) |

### 11.2 Spec ต่อหน้า (ของใหม่)

**Mobile landing page (`6407-1130019`)** — เว็บการตลาดในแท็บ browser: header โลโก้ ZYRA WORLD + ปุ่ม hamburger · hero "Real-Time Collaboration Starts with **One Workspace**" (คำว่า One Workspace บนแถบม่วง) · "Keep conversations, collaboration, and work together in one place." · ปุ่ม **Contact for Demo** (ขาวขอบ) + **Create workspace** (เขียว) · ภาพแมพ isometric · section "Feature": Everything your team needs to work together · Virtual office · Real-time chat · Avatar … (เนื้อหาเดียวกับ §2.2 node `6382:35915`)

**Bottom sheet "Meet Zyra on mobile" (`6411-1136764`)** — โผล่หลังเปิดหน้า **~5 วินาที** (sticky) · พื้นหลังเว็บ blur · sheet ขาวมุมบนโค้ง: โลโก้ Z เขียว · หัวข้อ **"Meet Zyra on mobile"** · "Download the app and stay connected to your workspace anytime, anywhere." · ปุ่ม **Later** (ขาวขอบ) + **Open Zyra** (เขียว) → ลูกศรไปหน้าแอปใน App Store · ⚠️ sheet เป็น**ธีมสว่าง** (ต่างจากแอปที่ dark) เพราะอยู่บนเว็บการตลาด 🔍 ยังไม่ได้ดึงค่า px

**หน้าแอปใน App Store (`6411-1141481` / `6411-1136502`, 440×956)** — mock หน้า listing: icon Z · "Zyra" · "Company name" · ปุ่มดาวน์โหลด (เมฆ) · 171K ratings 4.8 · Age 12+ · Chart No.1 Education · What's New "Version 7.98.0" (ข้อความ placeholder ของแอปอื่น) · Preview "Your Text Here" ×2 = **placeholder ทั้งหมด** ยังไม่ใช่เนื้อหาจริง

**App Store Today / Search (`6411-1138267–69`)** — ภาพหน้าจอ iPhone จริง (Aniimo, Shopee, Ragnarok…) ใช้แสดงว่าผู้ใช้ค้นหา Zyra จาก store · ไม่ใช่ UI ที่ต้องทำ

**Splash (`6411-1142335`)** — โลโก้ Z แบบ pixel สีเขียวกลางจอ พื้น `#1A1B1E` (ตรง §3.1)

**Slide 1–3 (`6411-1141300/1306/1313`)** — copy ตรง §3.1: "Real-Time Collaboration Starts with One Workspace." · "Everything You Need to Collaborate, All in One Space" (คำอธิบายสั้นลงเหลือ "Everything you need to collaborate happens in one seamless space. Chat, meet, and share instantly.") · "Transform Your Workspace Into a Place People Love"

**Get started (`6411-1141320` / `1141321`)** — ตรง §3.2 App: มาสคอต + "Welcome to Zyra World" · "Enter Zyra to collaborate with your team" · Continue with Google · Continue with Apple · or · Email / Password (eye toggle) · Forget password · **Sign in** เขียว · "Don't have an account yet? Sign up" · "By joining space, you agree with Terms of Services and Privacy Policy" · state กรอกแล้ว = ค่าในช่อง white (ปุ่ม Sign in สีเดียวกัน — ไม่มี disabled state ใน frame 🔍)

**Space builder – Empty (`6411-1141322`)** — header โลโก้ 40 + avatar 40 · "Space builder" Sub/Bold + ปุ่ม `+` เขียว 42 · search "Search for your workspace" + ปุ่ม filter 42 · กลางจอ: ภาพกล่อง + **"No workspaces created"** + "Let's create workspace to work or gather with your team." + ปุ่ม **"+ Create workspace"** เขียว

**Create workspace – เลือก template (`5878-409509`)**

| ส่วน | ค่า |
|---|---|
| Header | โลโก้ 40 + avatar 40 `left 16 top 16 w 358` |
| Title menu | `top 80` · ปุ่ม back (bg white 5% p 8 radius 8) + "Create workspace" Sub/Bold 16/22 กลาง |
| หัวข้อ | `top 128` · "Choose map template" 14/18 white + ปุ่ม filter (bg white 5% border white 20% **radius 6** p 8 icon 16) |
| Map template list | grid **2 คอลัมน์** gap 8 · แถว gap 16 |
| **Map template card** | bg `#232427` radius 8 · รูป h 100 (มุมบนโค้ง 8) · p 8 gap 8: ชื่อ 12/15 **Medium** white ("Modern office") · แถว gap 8: Tag category (bg `rgba(45,182,255,0.1)` border เดียวกัน radius 4 px 4 py 2 text 12/15 `#2DB6FF` "Office") · เส้นคั่น 16 · icon member 14 + "100 people" 12/15 `#8C99A6` · **เลือกแล้ว = border `#58D68D`** (`5878-410434`) |
| Bottom button | `top 769` เต็มกว้าง bg `#232427` p 16 · ปุ่ม **Next ›** ขวา h 42 radius 8 px 16 border white 20% text 16/22 · **ยังไม่เลือก = opacity 50%** · เลือกแล้ว = ปกติ |

**Create workspace – Filter sheet (`5878-409778` / `5889-415552`)** — overlay `rgba(0,0,0,0.5)` blur 6 · sheet bg `#232427` **h 700** radius บน 24 p 16 gap 16 · "Filter" Sub/Bold กลาง + × 16 มุมขวาบน · การ์ด Filter menu bg white 5% radius 16 p 16:
- **Capacity** (พับได้ chevron-up 14): **range slider 2 หัว** (track h 4 white 20% radius 90 · ช่วงที่เลือก gradient `#58D68D → #8FE4B3` · หัวจับ 12) + input 2 ช่อง h 42 ("0" — "1,000") · ตั้งแล้วตัวอย่าง 10 — 50
- **Category** (radio): All · Country · Garage · Nature · Office · Educational institution · แถว Menu min-h 42 p 12 radio 16 + text 14/18
- ปุ่มล่าง: **Clear all** (bg white 5% border white 20% icon trash) + **Save** (bg `#58D68D` icon check) flex-1 h 42

**Create workspace – details (`5878-411780` / `5878-411781`)** — "Workspace details" 14/18 · การ์ด bg `#232427` radius 16 p 16 gap 16: **Workspace name** (label 14/18 + input h 42 placeholder "Please input your workspace name") · รูป template h 160 radius 16 · ข้อมูลอ่านอย่างเดียว (label `#8C99A6` / ค่า white 14/18): Workspace template name "Modern office" · Category "Office" · Room count "20 rooms" · Capacity "100 people" · Version "V 2.0" · Updated date "Sep 18, 2025 (13:00 PM)" · Bottom: **‹ Back** (ซ้าย border white 20%) + **Confirm** (ขวา) — ยังไม่กรอกชื่อ = disabled (bg `#DBDFE3` border `#B2BBC3` text `#A3ADB8`) · กรอกแล้ว = bg `#58D68D` text white

**Workspace created (`5878-414845`)** — การ์ด `left 16 top 96 w 358` bg `#232427` radius 16 p 16 gap 40: "Workspace created" **Title/Bold 20/25** กลาง · ภาพ h 160 (spotlight เหลือง opacity 50% + มาสคอตกลาง + avatar 2 ตัว + confetti 2 ข้าง) · "Your space is ready" white + "Your workspace is ready to explore." `#8C99A6` · ปุ่มเต็มกว้าง h 42 gap 16: **Enter Workspace** (เขียว) · **Back to Space Builder** (bg white 5% border white 20%)

**Space builder – Fill (`5833-1005970`)** — การ์ด workspace แบบเดียวกับ HP-06 §10.2 (รูป 80, Last visited, Tag บทบาท, 15/50, online) **+ icon ⋮ 16 ข้างชื่อ** · ไม่มี bottom nav (ยังไม่ได้เข้า workspace)

**Profile menu (`5837-1007062`)** — แตะ avatar มุมขวาบน → Submenu `left 174 top 64 w 200` bg `#232427` radius 16 p 8 shadow `0 4 16 rgba(255,255,255,0.08)`: **Account setting** (icon user-cog) ┃ divider ┃ อีเมล "Conan_Grey@mail.com" 12/15 `#8C99A6` · **Sign out** `#F03A3A` (icon leave)

**Submenu ⋮ ของการ์ด (3 แบบ ข้าง frame `5840-1014009`)** — w 200 bg `#232427` radius 16:
| node | รายการ | บทบาทที่น่าจะใช้ (อนุมานจากจำนวนเมนู — ยังไม่ยืนยัน) |
|---|---|---|
| `5840-1007676` (h 142) | Enter workspace · Copy workspace · Manage workspace | Owner (ออกจาก workspace ตัวเองไม่ได้) |
| `5840-1007677` (h 200) | Enter workspace · Copy workspace · Manage workspace ┃ **Leave workspace** (แดง) | Admin |
| `5840-1007678` (h 158) | Enter workspace · Copy workspace ┃ **Leave workspace** (แดง) | Member |

**Space builder – Filter sheet (`5840-1014307`)** — layout เดียวกับ filter ของ Create workspace: **Workspace** (radio): All workspace · My workspace · Shared with me · **Sort by** (radio): Last visited · Name · Create at · Clear all / Save · sticky `5840-1016357`: **"กด Save → โหลดข้อมูลเป็น Skeleton UI · Loading: Link ใน Video เหมือนว่าจะมี Text ของเรา ขอแบบไม่ต้องมี Text แต่มีแค่ Animation ไล่ Gradient แทน"**

**ค้นหา (`5840-1016017` / `5840-1014917`)** — พิมพ์ "Star" → เหลือการ์ดเดียว ส่วนที่ตรงคำค้นเป็นตัว white ส่วนที่เหลือเทา (highlight match) · พิมพ์ "A" ไม่เจอ → ภาพกล่อง + **"No workspaces found"** + "Try another name or check the spelling."

### 11.3 พฤติกรรมจาก sticky (คำพูด design)

| จุด | sticky |
|---|---|
| Landing page → sheet | "โชว์ประมาณ 5 วินาที" (หน้าเว็บโชว์ ~5 วิ แล้ว sheet "Meet Zyra on mobile" ค่อยขึ้น) |
| Filter Save ใน Space builder | "กด Save → Skeleton UI Loading แบบไม่มี Text มีแค่ Animation ไล่ Gradient" |

### 11.4 เทียบกับโค้ดจริง

| Figma HP-07 | โค้ดปัจจุบัน | สถานะ |
|---|---|---|
| Landing page + sheet "Meet Zyra on mobile" | landing page = เว็บแยก (§7 ข้อ 12) · zyra-app ไม่มี smart banner / `beforeinstallprompt` / meta `apple-itunes-app` (grep = 0) | ❌ ใหม่ · อยู่ repo ไหนขึ้นกับคำถาม 3 |
| PWA install | `app/manifest.ts` มีแล้ว (standalone) แต่ **`orientation: "landscape"`** + `background_color #2B3540` (Figma ใช้ `#1A1B1E`) · `public/sw.js` pass-through | ⚠️ manifest บังคับแนวนอน **ขัดกับ Lite Mode แนวตั้ง** — ต้องแก้เป็น `any` (คำถาม 2) |
| Splash + Onboarding 3 slide | ไม่มี (ของใหม่ฝั่งแอป · `views/onboarding/onboarding-modal.tsx` เป็นทัวร์ในแอปคนละอย่าง) | ❌ ใหม่ (task 1.x splash + slide) |
| Get started (Login) | `views/login/*` + Google implicit flow · ไม่มี Apple | ⚠️ ตาม inventory B1/B2 (native sign-in) |
| Space builder Empty/Fill + search + filter | `views/user/workspace/hero-user-workspace.tsx` · tab `all/my/shared` (`:79`) · `SortBy = updated_at/name/created_at` (`workspace-constants.ts:11`) · empty `noWorkspaces` (`:453`) · skeleton มี (`components/ui/skeleton.tsx`) | ✅ logic ครบ ตรง Figma ทุกตัวเลือก · ⚠️ desktop ใช้ dropdown sort + tab → มือถือรวมเป็น filter sheet · skeleton ต้องเป็นแบบไม่มี text ไล่ gradient |
| ⋮ menu การ์ด | `workspace-card.tsx:129-197` — Enter (ทุกคน) · Copy / **Workspace editor** / Manage = Owner+Admin · **Delete** = Owner · Leave = Member (+Admin?) | ⚠️ Figma ไม่มี **Workspace editor** (desktop only — screens J ✅) และไม่มี **Delete** · Figma ให้ **Member กด Copy ได้** แต่โค้ดจำกัด Owner/Admin (คำถาม 7) · **แก้ 2026-10-02 (โน้ต Pai): ซ่อน Workspace editor บนมือถือ · เปิด URL ตรง → Space builder + toast → ux-ui-plan §19** |
| Profile menu (Account setting / email / Sign out) | `components/app-navbar.tsx:129-157` accountSetting + logOut | ✅ มี · dropdown → submenu เดิมได้ |
| Create workspace: template grid + filter | `views/user/space-builder/components/create-workspace-modal.tsx` 2-step + confirmation · Capacity filter = **ปุ่มตัวเลือกตายตัว** 10/25/50/100/200/300/400/500/1000 (`:48-55`) · Category = Country/Garage/Nature/Office/**School** (`left-panel-constants.ts:44`) | ✅ flow ตรง · ⚠️ Figma ใช้ **range slider 0–1,000** แทนปุ่มตายตัว (คำถาม 5) · "Educational institution" = label ของ `School` (แค่ข้อความ) |
| details: Category / Capacity อ่านอย่างเดียว | โค้ดให้ owner **แก้ category/capacity ได้** (`create-workspace-modal.tsx:134`) | ⚠️ Figma อ่านอย่างเดียว (คำถาม 6) |
| Workspace created → Enter Workspace / Back to Space Builder | desktop ไปหน้า `/workspace/new/[templateId]/welcome` (`hero-welcome-space.tsx`, 934 px) | ⚠️ มือถือใช้การ์ด "Workspace created" แทนหน้า welcome · Enter Workspace → Select workspace mode (§3.4) ก่อนเข้า (คำถาม 8) |

### 11.5 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §11.6)

- spec.md: **OQ 22 ปิด** (สร้าง workspace บนมือถือ = ทำ) · **OQ 9 ปิดบางส่วน** (หน้าก่อนเข้า workspace = แนวตั้งอย่างเดียว · tablet ยังค้าง) · OQ 23 ใหม่ (PWA install + sheet บน zyra-app) · ตารางโหมดเพิ่มแถว "ก่อนเข้า workspace"
- technical-design §16.6: หน้าก่อนเข้า workspace **แนวตั้งอย่างเดียว** — native lock portrait ด้วย `@capacitor/screen-orientation` แล้วปลด lock หลังเลือกโหมด · mobile web lock ไม่ได้ → ใช้หน้า Rotate ("Rotate your phone") · `manifest.ts orientation` → `"any"` (เดิม)
- screens.md A (smart banner, splash + slide) · B (Space builder มือถือ + ⋮ ตามบทบาท + filter sheet + skeleton, Create workspace มือถือ 3 step แทน modal 900×600)
- task-breakdown 0.31–0.33 (Space builder มือถือ, Create workspace มือถือ, smart banner + PWA) · 1.2 (splash 2 วิ + slide ไม่มี Skip + lock portrait ก่อนเข้า workspace)
- clickup-spec §18 ข้อ 43–46

### 11.7 UI ที่ต้องขอเพิ่มจาก design

| UI | เหตุผล |
|---|---|
| **PWA install prompt** (Android: ปุ่ม Install · iOS: คำแนะนำ Share → Add to Home Screen) | ข้อ 2 — Ten ยังรองรับ PWA แต่ Figma มีแค่ sheet "Meet Zyra on mobile" ที่ไปแอป |
| ภาพประกอบ onboarding 3 slide (ยังเป็นวงกลม placeholder) | §3.1 |

### 11.6 คำถาม / ข้อสงสัย HP-07 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | ลิงก์แนวนอนเป็นสำเนาแนวตั้ง — Splash / Slide / Login / Space builder / Create workspace ใช้แนวตั้งอย่างเดียว? | ✅ **ใช่ แนวตั้งอย่างเดียว** · วิธีบังคับ (ผมเสนอ): native = lock portrait ด้วย `@capacitor/screen-orientation` จนเลือกโหมดเสร็จ แล้วปลด lock · mobile web lock ไม่ได้ → หน้า Rotate |
| 2 | sheet "Open Zyra" ไป App Store = smart app banner ใช่ไหม · ยังต้องรองรับติดตั้ง PWA ไหม | ✅ **ยังรองรับติดตั้ง PWA** (Ten 2026-10-01) — ทำทั้ง 2 อย่าง: **smart banner ตาม Figma** (Open Zyra → แอป / App Store / Play Store) **+ PWA install** ตาม ClickUp (Android Chrome: `beforeinstallprompt` หลัง 2 visits + engagement · iOS Safari ไม่มี API → แสดงคำแนะนำ Share → Add to Home Screen) · manifest แก้ `orientation` → `any`, `background_color` → `#1A1B1E` · ⚠️ UI ของ install prompt ยังไม่มีใน Figma (มีแต่ sheet "Meet Zyra on mobile") · ลำดับ: banner ก่อน → กด Later แล้วค่อยมี install prompt (Ten ยืนยัน) |
| 3 | sheet อยู่บน landing page หรือบน zyra-app ด้วย · Later ซ่อนนานแค่ไหน · Android ไป Play Store? | ✅ **Android → Play Store** (iOS → App Store) · ✅ **ยืนยัน:** sheet โชว์ทั้ง landing page + zyra-app ในเบราว์เซอร์มือถือ · กด Later ซ่อน 7 วัน · PWA install prompt ขึ้นเฉพาะคนที่กด Later แล้ว (spec OQ 23) |
| 4 | สร้าง workspace บนมือถือทำไหม | ✅ **ทำ** — ปิด spec OQ 22 |
| 5 | Capacity เป็น range slider 0–1,000 เฉพาะมือถือ หรือ desktop ด้วย | ✅ **เฉพาะมือถือ** (desktop คงปุ่มตัวเลือกเดิม) |
| 6 | details: ตัดการแก้ Category / Capacity บนมือถือ | ✅ **ใช่** — อ่านอย่างเดียวตาม Figma |
| 7 | ⋮ Owner = Enter/Copy/Manage · Admin = +Leave · Member = Enter/Copy/Leave · Member Copy ได้ · ไม่มี Delete บนมือถือ | ✅ **ใช่ทั้งหมด** · ⚠️ Member Copy ได้ = **ต่างจากสิทธิ์ backend/desktop ปัจจุบัน** (Copy เฉพาะ Owner/Admin `workspace-card.tsx:154`) → ต้องเช็ค zyra-api ว่า endpoint copy อนุญาต Member ไหม 🔍 |
| 8 | Enter Workspace → Select workspace mode → ไม่ผ่านหน้า welcome ของ desktop? | ✅ **แนวตั้ง (Lite) ไม่ผ่าน · แนวนอน (Spatial) ต้องผ่าน** — หน้า welcome ของ desktop (`hero-welcome-space.tsx`, Figma 1740:268182 "Before enter space": preview กล้อง + Join) = หน้า Lobby/pre-join เดียวกับ §3.6 → ตรงมติ spec OQ 12 |
| 9 | Slide โชว์เฉพาะครั้งแรก · Skip · Splash นานเท่าไร | ✅ **ไม่มีปุ่ม Skip** (ยึด Figma — ต่างจาก ClickUp AC "skip ได้") · **Splash ตาม ClickUp = animated 2 วินาที** · โชว์เฉพาะเปิดครั้งแรก: ไม่ได้ตอบตรง ๆ → สมมติ เฉพาะครั้งแรกต่อเครื่อง (Capacitor Preferences) |
| 10 | asset หน้า listing ใน store ใครเตรียม · category | ✅ **"เดี๋ยวจะมีคนมาจัดการ"** — นอก scope เอกสารนี้ · ติดไว้ใน "สิ่งที่ต้องได้ก่อนเริ่ม" ของ task-breakdown |

## 12. HP-08 · App — Push Notifications (Meeting, Chat, Spotlight, Alerts) (รับ 2026-10-01 · Ten ตอบ 2026-10-01)

**Node:** แนวตั้ง section `6411-1141652` · แนวนอน section `6610-253136` (มี frame แนวนอนจริง 844×390) · ดึงผ่าน `get_metadata` ทั้ง 2 + `get_design_context` 4 frame + screenshot 9 frame

### 12.1 โครง section

| แนวตั้ง | แนวนอน |
|---|---|
| Splash (`6411-1142362`) → **Push notification access** = alert ระบบ iOS ทับ splash (`6411-1142417`) → Homepage (Lite, `6416-1143094`) → Profile (`5889-432902`) → **Notification settings** (`6436-67120`) | Splash (`6610-253138`) → Push access (`6610-253139`) → **Workspace – Horizon** (แมพ, `6610-254276`) → **Profile – HORIZON** (`6610-255449`) → **Profile – Notification** (`6610-256229`) |
| แถวล่าง: **ตัวอย่าง notification บน lock screen** 2 ชุด (`6414-1142591`, `6415-1143076` — ชุดที่ 2 มีวงไฮไลต์ที่ icon = แตะเปิด) + **ตารางประเภท notification** 2 ภาพ (`6415-1142968`, `6415-1142969`) ที่มี**เส้นขีดแดงทับบางแถว** | แถวล่าง: lock screen 2 ชุดเดียวกัน (`6610-253155`, `6610-253156`) — ไม่มีตาราง |

### 12.2 Spec ต่อหน้า

**Push notification access (`6411-1142417`)** — alert มาตรฐาน iOS ทับ splash: **"“Zyra” Would Like to Send You Notifications"** (SF Pro Semibold 17/22) · "Notifications may include alerts, sounds, and icon badges. These can be configured in Settings." (13) · ปุ่ม **Allow** / **Don't Allow** (`#007AFF` 17) = dialog ของระบบ ไม่ต้องทำ UI เอง (`PushNotifications.requestPermissions()`) · ⚠️ ขอสิทธิ์**ตอน splash** = ก่อน login / ก่อน onboarding (คำถาม 1)

**ตัวอย่าง lock screen (`6414-1142591` / `6415-1143076`)** — notification ของแอป: icon Z เขียว · หัวข้อ bold + ข้อความ 1–2 บรรทัด + เวลา "9:41 AM":
| หัวข้อ | ข้อความ | ประเภท |
|---|---|---|
| Alice | @Bob, could you take a look? | mention |
| Alice | Do you have a moment to chat? | DM |
| Meeting starts soon | Your meeting starts in 5 minutes. | meeting reminder |
| Meeting has started | Join your meeting when you're ready. | meeting start |
| A broadcast is live | Bob is broadcasting in your workspace. | spotlight / broadcast |
| Emergency Alert | Severe flooding in Bangkok… | weather emergency |
| While in Do Not Disturb | Zyra, Facebook, Instagram, + 4 more | **summary ของ iOS** (ไม่ใช่ของเรา — แสดงว่า notification ถูกกักตอน DND) |
- ⚠️ หัวข้อ DM/mention ใช้**ชื่อผู้ส่ง** ("Alice") ไม่มีชื่อห้อง / workspace (คำถาม 4)

**ตารางประเภท notification (`6415-1142968` / `1142969`)** — 3 คอลัมน์: ประเภท · หัวข้อ · ข้อความ
| ประเภท | หัวข้อ | ข้อความ |
|---|---|---|
| Meeting Cancelled | Your meeting was cancelled | The meeting is no longer scheduled. |
| Meeting Rescheduled | Your meeting time changed | Check the new time for your meeting. |
| Meeting Invitation | You have a new meeting invitation | Alex invited you to join a meeting. |
| Meeting Reminder | Your meeting is coming up | Your meeting starts in 15 minutes. |
| Broadcast Started | A broadcast has started | A live broadcast is now available in your workspace. |
| Broadcast Ended | The broadcast has ended | The broadcast is no longer live. |
| New Group Message | New message in your group | Alice sent a message in UX/UI. |
| Mention in Thread | You were mentioned in a thread | Alice mentioned you in a conversation. |
| Weather Warning | Weather warning | Severe weather is expected in your area. |
| Weather Emergency | Severe weather alert | Take care and follow local safety guidance. |
- ภาพแรกถูกตัดด้านบน (แถวแรกที่เห็นคือ Meeting Cancelled — อาจมีแถวก่อนหน้า 🔍)
- **เส้นขีดแดง 6 เส้น** (`Line 24–29`) ทับคอลัมน์หัวข้อ/ข้อความของแถว **Mention in Thread**, **Weather Warning**, **Weather Emergency** — ยังไม่รู้ว่าหมายถึง "ตัดออก" หรือ "แก้ข้อความ" (คำถาม 3)
- ⚠️ ตาราง Meeting Reminder = **15 นาที** · lock screen = **5 นาที** · Calendar setting = **10 นาที** (คำถาม 5)

**Notification settings แนวตั้ง (`6436-67120`)** — หน้าลูกจาก Profile → Setting → Notification · Title menu back + "Notification" · **ยังมี bottom nav** (แท็บ Profile active — ⚠️ ขัดกฎ HP-06 ที่หน้าลูกซ่อน nav, คำถาม 6) · เนื้อหา `left 16 top 72 w 358` gap 16 · กลุ่ม = หัวข้อ 12/15 `#8C99A6` p 8 + การ์ด bg `#232427` radius 16 p 8 · แถว Menu min-h 42 p 12 gap 16: ชื่อ 14/18 white + คำอธิบาย 14/18 `#8C99A6` gap 8 · **Switch 48×24** (เปิด = เขียว `#58D68D`) · ทุกตัว default เปิด

| กลุ่ม | สวิตช์ (คำอธิบาย) |
|---|---|
| **Chat** | Messages (Get a notification when a new chat message comes in.) · Mentions (… someone **@mentions** you in a chat.) · Thread (… replies to a thread you follow.) |
| **Meeting & Circle** | Meeting (… you or someone else enters a meeting room.) · Circle (Hear a sound when you or someone else joins a Circle.) · Knock (… asks to join a locked room or Circle.) · Raised hands · Mic & Camera requests · Screen sharing |
| **Calendar** | Event invitations · Event reminders (… 10 minutes before …) · Event start · Event changes · Event cancellations |
| **Pet** | Pet activity (… progress, milestones, and evolution.) |
| **Activities** | Waves (Get a quick alert when someone waves at you.) |

**Profile – HORIZON (`6610-255449`)** — **หน้าเต็มจอแนวนอน** bg `#1A1B1E` px 32 py 16 gap 16 · Title menu: ปุ่ม **×** (ไม่ใช่ back) + "Profile" กลาง · การ์ด status: **avatar 56** (แนวตั้ง 40) + ชื่อ + chevron · Active / Busy / Away · "What are you thinking?" · กลุ่ม Setting (Account and Security, Language English, Audio, Camera, Notification) · Support (Help, Legals) · Switch workspace / Log out · ⚠️ **ไม่มีกลุ่ม Workspace** (Manage member, Environment, Workspace mode) ที่แนวตั้งมี (HP-06 §10.2) · ⚠️ เป็นหน้าเต็มจอ ไม่ใช่ modal ทับแมพ ตามที่ตอบใน HP-06 ข้อ 4 (คำถาม 7)

**Profile – Notification แนวนอน (`6610-256229`)** — เต็มจอ px 32 · back + "Notification" · กลุ่มและสวิตช์ชุดเดียวกับแนวตั้ง (การ์ดกว้างเต็ม 780) · ไม่มี bottom nav

**Workspace – Horizon (`6610-254276`)** — แมพ Spatial เดิม (§3.9): ปุ่มกลม 5 ปุ่มขวาบน (weather, spotlight, calendar, members, กระดิ่ง) · joystick ซ้ายล่าง · minimap ขวาล่าง · Meeting Menu (avatar / cam / mic / leave) · ปุ่ม chat ซ้ายล่าง = ทางเข้า Profile คือปุ่ม avatar ใน Meeting Menu

### 12.3 เทียบกับโค้ดจริง

| Figma HP-08 | โค้ดปัจจุบัน | สถานะ |
|---|---|---|
| ขอสิทธิ์ push + รับ push (FCM/APNs) | **ไม่มีเลย** — ไม่มี FCM/APNs/web-push, zyra-notifications ส่ง email อย่างเดียว (TD §1, Phase 2 task 2.1–2.5) | ❌ ใหม่ทั้งเส้น (device token, `tb_user_device`, FCM HTTP v1, trigger จาก zyra-ws) |
| Notification settings 5 กลุ่ม 15 สวิตช์ | `vo-setting-modal.tsx:230-460` `NOTIFICATION_SECTIONS` — Messages(3) · Meeting & Circle(6 **+2**) · Calendar(5) · Pet(1 **+ Pet sounds**, ซ่อนถ้า flag ปิด) · Activities(1) · Environment(sounds) · label/คำอธิบาย**เกือบตรงทุกคำ** | ✅ field มีครบ (`event_invitations` … `pet_activity`) · ⚠️ มือถือ**ไม่มี**: Hide chat notifications / Mute chat sounds in meeting / Pet sounds / Environment sounds (คำถาม 8) · ⚠️ ตอนนี้เป็น**เสียง/แจ้งเตือนในแอป** ("Hear a sound…") — ต้องตัดสินว่าสวิตช์เดียวคุมทั้งเสียงในแอป + push หรือแยก (คำถาม 2) |
| ประเภท push (meeting / broadcast / chat / mention / weather) | in-app มีแล้ว: `notifTypeNewMessage`, `Mentioned`, `Replied`, `AddedToGroup`, `Reacted`, `Announcement`, `WeatherAlert`, `notifBroadcastLive/Ended`, pet grown/milestone, wave, knock, media request | ✅ เนื้อหามีใน in-app · ❌ Meeting Invitation / Reminder / Cancelled / Rescheduled ผูกกับ **Calendar ที่ยังไม่มี feature** (spec OQ 21) |
| แตะ notification → เปิดแอปไปหน้าที่เกี่ยวข้อง (วงไฮไลต์ `6415-1143082`) | deep link `zyra://workspace/{id}` = task 1.3 · ยังไม่มี routing ตาม payload | ❌ ใหม่ (คำถาม 9) |
| Profile แนวนอน = หน้าเต็มจอ | HP-06 ข้อ 4 ตอบว่าแนวนอน = modal ทับแมพ | ⚠️ ขัดกัน (คำถาม 7) |

### 12.4 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §12.5)

- technical-design §6: จังหวะขอสิทธิ์ตอน splash · สวิตช์ push แยกจาก in-app · payload DM/mention มีข้อความจริง + ชื่อห้อง + workspace · routing ตอนแตะ · foreground = banner ในแอป · badge = unread chat + notification · ประเภทรอบแรก
- task-breakdown 2.4 (trigger ตามประเภทรอบแรก) · 2.5 (push toggle แยก in-app) · 2.6 ใหม่ (routing + foreground banner + badge) · 0.34 ใหม่ (Notification settings มือถือ + state ขอ Allow)
- screens.md H: Notification settings มือถือ (แนวตั้งคง bottom nav · แนวนอนเต็มจอ · 19 สวิตช์ · banner ขอ Allow) · Profile แนวนอนเพิ่มกลุ่ม Workspace
- clickup-spec §18 ข้อ 47–51 · spec OQ 24–26

### 12.5 คำถาม / ข้อสงสัย HP-08 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | ขอสิทธิ์ตอน splash หรือหลัง login · ถ้า Don't Allow หน้า settings แสดงอะไร | ✅ **ตาม Figma = ขอตอน splash** (ขัด ClickUp AC "หลัง onboarding" → clickup §18 ข้อ 47) · **เพิ่มหน้า/state ใน Notification settings ให้กดขอ Allow** → ข้อเสนอ spec §12.6 (Figma ยังไม่มี frame — ต้องให้ design ยืนยัน) |
| 2 | สวิตช์เดียวคุมทั้ง in-app + push หรือแยก | ✅ **แยกกัน** — หน้า Notification ของมือถือ (Figma) = สวิตช์ **push** · เสียง/แจ้งเตือนในแอปใช้ field เดิม (`enable_*_sounds` ฯลฯ) · ✅ **แสดงเป็น 2 สวิตช์ต่อแถว** (in-app + push) — 🔍 layout แถวยังต้องให้ design ทำ (OQ 24) · **แก้ 2026-10-02 (โน้ต Pai): **สวิตช์เดียวต่อแถว = push** ตาม Figma 6436-67120 (ยกเลิก 2 สวิตช์ต่อแถว) → ux-ui-plan §19** |
| 3 | เส้นขีดแดง = ตัดออก หรือแก้ข้อความ · มีแถวก่อน Meeting Cancelled ไหม | ✅ **ตัดออก** — **Mention in Thread, Weather Warning, Weather Emergency** ไม่ส่ง push · ✅ ตารางเริ่มที่ **Meeting Cancelled** ถูกต้อง (ไม่มีแถวก่อนหน้า) · ⚠️ ข้อ 9 ยังพูดถึง weather (แตะแล้วเปิดแอป) และ lock screen มี "Emergency Alert" → ✅ **ยืนยัน: weather ไม่ส่ง push ในรอบนี้** · ถ้ากลับมาส่งเมื่อไหร่ แตะแล้วแค่เปิดแอป (OQ 25) |
| 4 | หัวข้อ DM/mention มีชื่อห้อง/workspace ไหม · แสดงข้อความจริงไหม | ✅ **แสดงข้อความจริง** + **ชื่อห้อง + ชื่อ workspace** · **แตะแล้วเปิดห้องแชทนั้น** |
| 5 | Meeting reminder กี่นาที · Calendar ไว้ทีหลัง? | ✅ **15 นาที** · ✅ **Calendar ไว้ทีหลัง** — meeting push 4 ประเภท (Invitation / Reminder / Cancelled / Rescheduled) + กลุ่ม Calendar 5 สวิตช์รอ feature Calendar |
| 6 | Notification settings แนวตั้งมี bottom nav แต่ HP-06 ให้หน้าลูกซ่อน | ✅ **ยังคงแสดง bottom nav** — ข้อยกเว้นของหน้านี้ (HP-06 ข้อ 8 สำหรับหน้าลูกอื่นยังค้าง) |
| 7 | Profile แนวนอนเต็มจอ vs modal · กลุ่ม Workspace หาย | ✅ **กลุ่ม Workspace ตกหล่น → เพิ่มกลับ** (Manage member + Environment เฉพาะ Owner/Admin, Workspace mode ทุกคน) · ✅ **ยึด frame HP-08 = หน้าเต็มจอ มีปุ่ม ×** ไว้ก่อน (แทน modal ของ HP-06 ข้อ 4 · OQ 26) |
| 8 | มือถือตัดสวิตช์ Hide chat / Mute chat sounds ระหว่างประชุม / Pet sounds / Environment sounds? | ✅ **ให้เพิ่มมา** — มือถือมีครบเหมือน desktop (ตำแหน่ง: Hide/Mute chat → กลุ่ม Meeting & Circle · Pet sounds → Pet · Environment sounds → กลุ่ม Environment ใหม่) 🔍 UI ยังไม่มีใน Figma |
| 9 | แตะ notification ไปไหน · foreground | ✅ DM/mention → ห้องแชทนั้น · **broadcast → หน้ารองรับในส่วนอื่น รอ UI** · **weather → แค่เปิดแอป** · **แอปเปิดอยู่ → banner ในแอปแทน push** · ⏳ meeting (Calendar) ไว้ทีหลัง |
| 10 | Badge บน icon แอปนับอะไร | ✅ **unread chat + notification รวมกัน** (= badge แท็บ Chat + กระดิ่ง) |

### 12.6 ข้อเสนอ: state "ยังไม่ได้เปิด notification" ในหน้า Notification settings (Ten ขอให้เพิ่ม — **ยังไม่มีใน Figma ต้องให้ design ยืนยัน**)

ใช้ component ที่มีอยู่แล้วใน Figma ไม่ได้คิดค่าใหม่:

| ส่วน | ข้อเสนอ (อ้าง component เดิม) |
|---|---|
| ตำแหน่ง | ใต้ Title menu "Notification" บนสุดของเนื้อหา (`top 72`) ก่อนกลุ่ม Chat |
| กล่องแจ้ง | ใช้ **Alert banner** แบบหน้า Select workspace mode (§3.4): bg `rgba(45,182,255,0.1)` border `rgba(45,182,255,0.2)` radius 8 p 8 gap 8 · icon bell-off 16 · text `#2DB6FF` 14/18 — "Notifications are turned off. Allow notifications to get messages and alerts." |
| ปุ่ม | ปุ่มหลัก h 42 radius 8 bg `#58D68D` text white 16/22 เต็มกว้าง — **"Allow notifications"** |
| พฤติกรรมปุ่ม | สถานะ `prompt` (ยังไม่เคยถาม) → `PushNotifications.requestPermissions()` เด้ง alert ระบบอีกครั้ง · สถานะ `denied` (เคยกด Don't Allow) → iOS ถามซ้ำไม่ได้ → เปิดหน้า Settings ของแอปในเครื่อง (`App.openUrl` → `app-settings:` / Android `ACTION_APP_NOTIFICATION_SETTINGS`) · กลับเข้าแอป (`appStateChange` active) → เช็ค `checkPermissions()` ใหม่ ถ้าอนุญาตแล้ว banner หาย |
| สวิตช์ระหว่างยังไม่อนุญาต | แต่ละแถวมี 2 สวิตช์ (in-app + push — Ten) · สวิตช์ **push** opacity 50% แตะไม่ได้ · สวิตช์ in-app ยังใช้ได้ · **แก้ 2026-10-02 (โน้ต Pai): เหลือสวิตช์เดียว (push) กดไม่ได้จนกว่าจะอนุญาต → ux-ui-plan §19** |
| แนวนอน | banner + ปุ่มเหมือนกัน กว้างเต็ม 780 |
| ที่อื่นที่ควรมี (เสนอ) | แถว "Notification" ในหน้า Profile แสดงค่า "Off" สีเทาเมื่อยังไม่อนุญาต (แบบค่า "English" ของ Language) |

### 12.7 UI ที่ต้องขอเพิ่มจาก design

| UI | เหตุผล |
|---|---|
| state **ยังไม่อนุญาต notification** ในหน้า Notification settings (ข้อเสนอ §12.6) | ข้อ 1 |
| layout **2 สวิตช์ต่อแถว** (in-app + push) — หัวคอลัมน์ / ความกว้าง / แนวนอน | ข้อ 2 (Ten เลือกแบบ 2 สวิตช์ต่อแถว) · **แก้ 2026-10-02 (โน้ต Pai): ไม่ใช้แล้ว — สวิตช์เดียวต่อแถว → ux-ui-plan §19** |
| สวิตช์ที่เพิ่ม 4 ตัว (Hide chat / Mute chat sounds ระหว่างประชุม · Pet sounds · Environment sounds) | ข้อ 8 |
| **กลุ่ม Workspace** ใน Profile แนวนอน | ข้อ 7 |
| **หน้ารองรับ broadcast** ตอนแตะ push | ข้อ 9 |
| **banner ในแอป** ตอน foreground (ใช้ toast/notification ในแอปที่มีอยู่ได้ไหม) | ข้อ 9 |

## 13. HP-09 · App — Camera & Microphone Permissions (รับ 2026-10-01 · Ten ตอบ 2026-10-01)

**Node:** แนวตั้ง section `6450-67121` (frame 390×844) · แนวนอน section `6616-256230` (frame meeting 844×390) — ⚠️ ข้อความที่ Ten ส่งมาสลับป้าย ("แนวนอน" = 6450, "แนวตั้ง" = 6616) แต่ขนาด frame ยืนยันว่า 6450 = แนวตั้ง, 6616 = แนวนอน · ดึงผ่าน `get_metadata` ทั้ง 2 + `get_design_context` 4 alert + screenshot 15 frame

### 13.1 โครง section (2 แถว: Camera / Mic — flow เดียวกัน)

| ขั้น | แนวตั้ง (Lite) | แนวนอน (Spatial) |
|---|---|---|
| 0 | Lite Home (`6450-67123` / `6455-70861`) → Instant meeting | — (เริ่มในห้องประชุมเลย) |
| 1 | ห้อง Meeting Hall 2 คน กล้อง/ไมค์ปิด (`6452-67765` / `6455-70862`) | ห้อง 2 tile (`6636-55130` / `6636-56866`) |
| 2 | กดปุ่มกล้อง/ไมค์ → **Camera / Microphone permission alert** (`6455-70476` / `6455-70492`) | alert เดียวกัน (`6616-256264` / `6616-256280`) |
| 3a **Allow** | กล้อง: tile ตัวเองเป็นวิดีโอ + **ปุ่มสลับกล้องโผล่ที่ header** (`6455-70662`) · ไมค์: ไอคอนไมค์ปกติ + tile มี**กรอบเขียว = กำลังพูด** + ป้ายชื่อไม่มีไอคอน mic-off (`6455-71507`) | เหมือนกัน (`6636-55238` / `6636-56994`) |
| 3b **Don't Allow** | กลับห้องเดิม กล้อง/ไมค์ยังปิด (`6455-70762` / `6455-71622`) → กดปุ่มอีกครั้ง → **settings alert "Unable to access camera / microphone"** (`6455-70464` / `6455-70524`) → **Settings** → หน้า Settings ของแอปในเครื่อง (`6455-71723` / `6455-71722`) | เหมือนกัน (`6636-55348` / `6636-57120` → `6616-256242` / `6616-256253` → `6636-55455` / `6616-256297`) |

### 13.2 Spec ต่อหน้า

**Camera permission alert (`6455-70476`, 480×455)** — สไตล์ alert **iOS 26**: bg `#111` border `#383838` **radius 52** p 24 gap 24 · ไอคอน 96 radius 27 (กล้อง bg `#A9A9AF` · ไมค์ bg `#F4A252`) + badge มือ 44 bg `#3478F6` radius 11 มุมขวาล่าง · หัวข้อ Inter Bold **25/39** `#F5F5F7` · คำอธิบาย Regular 23/35 `#A4A4A8` · ปุ่ม 2 ตัว flex-1 **h 70 radius 36** bg `#2C2C2E` text Medium 25/30 `#F5F5F7` gap 12: **Don't Allow** · **Allow**
- กล้อง: **"“Zyra” would like to access the Camera."** · "Zyra needs access to your camera so others can see you during meetings and when you use camera features."
- ไมค์: **"“Zyra” would like to access the Microphone."** · "Zyra needs access to your microphone so others can hear you during meetings and conversations."
- = **dialog ของระบบ** iOS (ขนาดเป็น @2x ของจอจริง) — เราคุมได้แค่**ข้อความคำอธิบาย** ผ่าน `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` ใน Info.plist · หัวข้อ/ปุ่ม/ไอคอนเป็นของ iOS (คำถาม 1)

**Settings alert (`6455-70464` / `6455-70524`, 480×289)** — กล่องเดียวกันแต่ไม่มีไอคอน · gap ข้อความ 12 · หัวข้อ Bold 25/30:
- กล้อง: **"Unable to access camera"** · "To use your camera in meetings, enable access in:  Settings → Privacy & Security → Camera"
- ไมค์: **"Unable to access microphone"** · ~~"… Settings → Privacy & Security → Camera"~~ → **แก้แล้ว (Ten ข้อ 2)** เป็นข้อความใน §13.6
- ปุ่ม **Cancel** · **Settings** → เปิดหน้า Settings ของแอปในเครื่อง
- iOS ไม่มี dialog นี้ให้ → **เราต้องแสดงเอง** (คำถาม 3: native `Dialog.confirm` หรือ modal ของเรา)

**หน้า Settings ของเครื่อง (`6455-71723`, ภาพ IMG_8430)** — ภาพหน้าจอ iOS Settings จริง (หัวข้อแก้เป็น "Zyra" แต่ข้อความใต้หัวยังเป็น "Allow **Zoom** to Access" = ภาพอ้างอิงจากแอปอื่น) · รายการ Microphone (ปิด) · Camera (ปิด) · Calendars · Notifications · Live Activities · Background App Refresh · Mobile Data = หน้าที่ระบบสร้างให้ ไม่ต้องทำ

**ห้องประชุมหลังได้สิทธิ์** — ใช้ layout HP-04 §8.2 เดิม · กล้องเปิด → ปุ่มสลับกล้อง (refresh icon) เพิ่มเป็นปุ่มแรกของ header ขวา · ไมค์เปิด → ปุ่มไมค์ใน Meeting Menu เปลี่ยนจาก mic-off แดงเป็น mic ขาว · tile คนพูดมี border `#58D68D`

### 13.3 เทียบกับโค้ดจริง

| Figma HP-09 | โค้ดปัจจุบัน | สถานะ |
|---|---|---|
| ขอสิทธิ์ตอนกดปุ่มกล้อง/ไมค์ครั้งแรก (ในห้อง) | `use-entry-media-permission.ts:194,265` ขอ **ตอนเข้า office / pre-join** · `sfu-client.ts:576-616` จับ `NotAllowedError` → `MicPermissionDeniedError` / `CameraPermissionDeniedError` | ⚠️ จังหวะต่างกัน — Lite ไม่ผ่าน pre-join (OQ 12) จึงขอตอนกดปุ่มในห้องตาม Figma · Spatial ผ่าน pre-join ขอที่นั่นได้เลย (คำถาม 4) |
| ข้อความใน system dialog | ไม่มี (ยังไม่มีโปรเจกต์ native) | ❌ ใส่ `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` ตามข้อความ Figma (task 1.x) · Android ไม่มีข้อความให้ตั้ง (dialog ระบบ fixed) |
| "Unable to access …" + ปุ่ม Settings | desktop: `vo-permission-snackbar.tsx` (snack bar "Learn more") + `vo-permission-guide-modal.tsx` (คำแนะนำต่อ browser Chrome/Safari, 700 px) | ⚠️ มือถือ (app) ใช้ alert ใหม่ + เปิด Settings ของแอปตรง · mobile web ยังใช้ guide เดิมได้ แต่ต้องเขียนวิธีสำหรับ Safari/Chrome มือถือ (screens H) |
| ปุ่มสลับกล้องหน้า/หลัง | `vo-media-device-menu.tsx` เลือก device จาก list · ไม่มีปุ่มสลับ 1 แตะ | ⚠️ ปุ่มใหม่ใน header (HP-04 §8.1 แถว 2 มีแล้ว) |
| Android | ไม่มี frame | 🔍 Android ใช้ dialog ระบบของ Android ("Allow Zyra to take pictures and record video?" / While using the app / Only this time / Don't allow) · กด Don't allow 2 ครั้ง = ถามซ้ำไม่ได้เหมือน iOS |

### 13.4 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §13.5)

- technical-design D1 + §13.x: จังหวะขอสิทธิ์ = ตอนกดปุ่มทั้ง 2 โหมด · pre-permission ของเรา → dialog ระบบ · denied → native alert (`@capacitor/dialog`) → เปิด app settings · mobile web → guide Safari/Chrome มือถือ
- task-breakdown 0.35 (permission flow มือถือ + indicator) · 1.14 (Info.plist / AndroidManifest strings)
- screens.md D (ปุ่มกล้อง/ไมค์ + indicator) · H (permission guide มือถือ)
- clickup-spec §18 ข้อ 52–55

### 13.5 คำถาม / ข้อสงสัย HP-09 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | ข้อความใน dialog ระบบตาม Figma · ต้องการ pre-permission ของเราไหม | ✅ ข้อความ usage description ตาม Figma · ✅ **ต้องการ pre-permission** → ข้อเสนอ spec §13.6 (Figma ยังไม่มี — ต้องให้ design ยืนยัน) |
| 2 | แก้ "→ Camera" ใน alert ไมค์ + path ให้ตรงกับหน้าที่ปุ่ม Settings เปิดจริง | ✅ **แก้ให้เลย** → ข้อความใหม่ใน §13.6 (path = หน้า Settings ของแอป Zyra) |
| 3 | "Unable to access…" ใช้ native alert หรือ modal ของเรา | ✅ **native alert ของระบบ** (`@capacitor/dialog` `confirm` · ปุ่ม Cancel / Settings) — หน้าตาเป็น iOS/Android ตามเครื่องอัตโนมัติ ไม่ต้องทำ UI |
| 4 | จังหวะขอสิทธิ์ Spatial (pre-join) vs ตอนกดปุ่ม | ✅ **เลื่อนไปตอนกดปุ่มเหมือนกันทั้ง 2 โหมด** · ⚠️ ผลกระทบ: หน้า pre-join ของ Spatial (preview กล้อง) **ไม่ขอสิทธิ์อัตโนมัติ** → ถ้ายังไม่มีสิทธิ์ แสดง avatar แทน preview จนกว่าผู้ใช้กดปุ่มกล้องในหน้านั้น (ซึ่งจะเข้า flow pre-permission → dialog ระบบ) |
| 5 | mobile web ใช้ dialog browser + guide ไหม | ✅ **ปรับ guide เป็น Safari / Chrome มือถือ** (web เปิดหน้า Settings ของเครื่องไม่ได้) · ใช้ `vo-permission-guide-modal.tsx` เดิมทำเป็น sheet |
| 6 | Android ใช้ dialog ระบบ + alert เดียวกัน path Settings → Apps → Zyra → Permissions | ✅ **ใช่** |
| 7 | ถูกปฏิเสธแล้ว ปุ่มกล้อง/ไมค์มีเครื่องหมายเตือนไหม | ✅ **ขึ้นบอก** → indicator บนปุ่ม (ข้อเสนอ §13.6 — design ยืนยัน) |

### 13.6 ข้อเสนอ spec (Ten ขอให้เพิ่ม — **ยังไม่มีใน Figma ต้องให้ design ยืนยัน**)

**A. Pre-permission (ก่อนเด้ง dialog ระบบ)** — แสดงเมื่อสิทธิ์อยู่สถานะ `prompt` (ยังไม่เคยถาม) และผู้ใช้กดปุ่มกล้อง/ไมค์
| ส่วน | ข้อเสนอ (อ้าง component เดิม) |
|---|---|
| รูปแบบ | **bottom sheet** แบบ "Keep This Setting?" (§3.4): bg `#232427` radius บน 24 p 16 gap 16 · overlay `rgba(0,0,0,0.5)` blur 6 · แนวนอน = sheet กว้าง 390 กลางล่าง (เหมือน Join meeting modal HP-04) |
| ไอคอน | ไอคอน camera / mic 24 ในวงกลม 56 bg white 5% (แบบ placeholder ในการ์ด Select mode) |
| หัวข้อ | Sub/Bold 16/22 — กล้อง: "Turn on your camera" · ไมค์: "Turn on your microphone" |
| คำอธิบาย | Body 14/18 `#8C99A6` — ใช้ข้อความ usage description เดิม: "Zyra needs access to your camera so others can see you during meetings…" |
| ปุ่ม | **Continue** (เขียว `#58D68D` h 42 เต็มกว้าง) → เรียก dialog ระบบ · **Not now** (ghost h 42) → ปิด sheet ปุ่มยังปิด (ถามใหม่ได้ครั้งหน้า เพราะยังไม่ได้แตะ dialog ระบบ) |
| ไม่แสดงเมื่อ | สิทธิ์ `granted` (เปิดเลย) · `denied` (ไปข้อ B) |

**B. Denied → native alert** (`@capacitor/dialog` `confirm`, ข้อความแก้แล้วตามข้อ 2)
| | iOS | Android |
|---|---|---|
| กล้อง | **Unable to access camera** · "To use your camera in meetings, turn on Camera in Settings → Zyra." | "To use your camera in meetings, turn on Camera in Settings → Apps → Zyra → Permissions." |
| ไมค์ | **Unable to access microphone** · "To speak in meetings, turn on Microphone in Settings → Zyra." | "To speak in meetings, turn on Microphone in Settings → Apps → Zyra → Permissions." |
| ปุ่ม | Cancel · **Settings** → เปิดหน้า Settings ของแอป (iOS `app-settings:` · Android `ACTION_APPLICATION_DETAILS_SETTINGS`) | เหมือนกัน |
| กลับเข้าแอป | `appStateChange` active → เช็คสิทธิ์ใหม่ ถ้าได้แล้วเปิดกล้อง/ไมค์ให้อัตโนมัติ? (🔍 design/Ten ยืนยัน — ข้อเสนอ: **ไม่เปิดเอง** ให้ผู้ใช้กดอีกครั้ง) | |

**C. Indicator บนปุ่มเมื่อถูกปฏิเสธ (Ten ข้อ 7)** — ปุ่มกล้อง/ไมค์ใน Meeting Menu (HP-04 §8.2) + หน้า pre-join · badge วงกลม 12 bg `#ECC819` (เหลืองเดียวกับ raise hand) icon `!` 8 สีดำ มุมขวาบนของปุ่ม · แตะปุ่ม → native alert ข้อ B ทันที

**D. Mobile web (Ten ข้อ 5)** — dialog ของ browser · ถ้าถูกปฏิเสธ → sheet คำแนะนำ (ปรับจาก `vo-permission-guide-modal.tsx`): **Safari iOS**: แตะ "aA" ในแถบ URL → Website Settings → Camera / Microphone → Allow → รีเฟรช · **Chrome Android**: แตะไอคอนแม่กุญแจ → Permissions → Camera / Microphone → Allow → รีเฟรช · indicator ข้อ C ใช้ด้วย

### 13.7 UI ที่ต้องขอเพิ่มจาก design

| UI | เหตุผล |
|---|---|
| **Pre-permission sheet** กล้อง / ไมค์ (ข้อเสนอ §13.6 A) ทั้ง 2 orientation | ข้อ 1 |
| **Indicator** บนปุ่มกล้อง/ไมค์เมื่อถูกปฏิเสธ (ข้อเสนอ §13.6 C) | ข้อ 7 |
| **Permission guide sheet** มือถือ (Safari iOS / Chrome Android) สำหรับ mobile web | ข้อ 5 |
| หน้า **pre-join (Spatial)** ตอนยังไม่มีสิทธิ์กล้อง — avatar แทน preview | ข้อ 4 |

## 14. HP-10 · App — Offline / Poor Connection Handling (รับ 2026-10-01 · Ten ตอบ 2026-10-01)

**Node:** แนวตั้ง section `6462-71727` (390×844) · แนวนอน section `6636-57227` (844×390) · ดึงผ่าน `get_metadata` ทั้ง 2 + `get_design_context` 2 component + screenshot 18 frame · ⚠️ ชื่อ frame ฝั่ง meeting เป็น "Meeting - Low battery" ทุกตัว (ชื่อ copy มาจาก HP-04) แต่เนื้อหาเป็นเรื่อง connection

### 14.1 โครง section (3 แถว)

| แถว | แนวตั้ง | แนวนอน |
|---|---|---|
| **Meeting** | ① toast **"Poor connection" + ×** (`6462-91343`) · ② toast **"Lost connection"** + ป้ายชื่อคนที่หลุดมี spinner (`6465-165858`) → ③ **"Reconnecting…"** (`6465-165986`) → ④ sticky **"ภาพค้าง"** = วิดีโอค้างภาพสุดท้าย + Reconnecting… (`6465-166403`) → sticky **"เกิน 5 ครั้ง > Meeting ตัดจบ กลายเป็น Skeleton load + Wording reconnecting... > ถ้าโหลดไม่ได้กลับ workspace list ภายใน 30s"** → ⑤ **Lite Home** + toast **"Meeting has ended due to lost connection"** (`6465-166650`) | ①–④ เหมือนกัน (`6657-59562` / `59935` / `60069` / `60203`) → sticky **"เกิน 5 ครั้ง > Meeting ตัดจบ Reconnecting > เชื่อมต่อไม่ได้กลับไป Workspace list"** → ⑤ **แมพ Spatial** (`6657-60442`, ไม่มี toast ใน frame) |
| **Chat** | พิมพ์ข้อความ (`6465-167224`) → ส่งไม่ได้ → **bottom sheet "Message not sent"** (`6668-245339`) · sticky **"กรณี Lost internet ส่ง 5 ครั้ง ไม่ได้ > เคสเดิม"** + **"Service ล่ม ส่งไม่ไป ข้อความโหลดเพิ่มไม่ได้"** | ห้องแชท 2 คอลัมน์ (`6657-60610`) → **modal กลางจอ** "Message not sent" (`6658-61461`) · sticky "กรณี Lost internet" |
| **Calendar** | (แถวว่าง — แถบสีส้ม = ยังไม่ได้ทำ) | (ว่าง) |

### 14.2 Spec ต่อ component

**Text notification bottom (toast, `6465-165860`)** — กลางจอ เหนือ Meeting Menu (แนวตั้ง `y 736` · แนวนอน `y 282`) · bg `rgba(0,0,0,0.7)` blur 4 radius 8 px 8 py 4 gap 8 · icon 16 + text Body 14/18 white
| ข้อความ | icon | ปิดได้ |
|---|---|---|
| Poor connection | สัญญาณอ่อน (เหลือง) | ✅ ปุ่ม × |
| Lost connection | wifi-off (`#F03A3A`) | ❌ |
| Reconnecting… | spinner | ❌ |
| Meeting has ended due to lost connection | — | (หายเอง 🔍) |
- toast นี้เป็น component เดียวกับ "Low battery. Charge to stay connected." ใน HP-04 §8.1 แถว 8

**ป้ายชื่อบน tile** — คนที่กำลัง reconnect: ไอคอน mic-off ถูกแทนด้วย **spinner** หน้าชื่อ (เห็นทั้ง tile ตัวเองและ tile คนอื่น) · วิดีโอค้างภาพสุดท้าย (ไม่ดำ)

**Message not sent (`6668-245357`)** — แนวตั้ง = **bottom sheet** h 254 (overlay blur) · แนวนอน = **modal กลาง 390** · bg `#232427` radius บน 24 (sheet) p 16 gap 40 · × 16 มุมขวาบน · วงกลม placeholder 80 (ไอคอนยังไม่มี 🔍) · "Message not sent" Body/Medium white · "Check your connection and try again." Body `#8C99A6` · ปุ่ม **Done** เต็มกว้าง h 42 `#58D68D` (ปุ่มที่ 2 ซ่อนอยู่ใน layer — น่าจะเป็น Retry 🔍)

### 14.3 พฤติกรรมจาก sticky (คำพูด design)

| จุด | sticky |
|---|---|
| วิดีโอระหว่าง reconnect | "ภาพค้าง" |
| Meeting reconnect ไม่สำเร็จ (แนวตั้ง) | "เกิน 5 ครั้ง > Meeting ตัดจบ กลายเป็น Skelton load + Wording reconnecting... > ถ้าโหลดไม่ได้กลับ workspace list ภายใน 30s" |
| Meeting reconnect ไม่สำเร็จ (แนวนอน) | "เกิน 5 ครั้ง > Meeting ตัดจบ Reconnecting > เชื่อมต่อไม่ไก้กลับไป Workspace list" |
| Chat lost internet | "กรณี Lost internet ส่ง 5 ครั้ง ไม่ได้ > เคสเดิม" |
| Chat service ล่ม | "Service ล่ม ส่งไม่ไป ข้อความโหลดเพิ่มไม่ได้" |

### 14.4 เทียบกับโค้ดจริง

| Figma HP-10 | โค้ดปัจจุบัน | สถานะ |
|---|---|---|
| retry 5 ครั้ง / ~30 วิ | `workspace-ws.ts:82-83` `RECONNECT_BACKOFF_MS = [1s, 2s, 4s, 8s, 16s]` = **5 ครั้ง รวม ~31 วิ** แล้วหยุด | ✅ **ตรงกับ sticky พอดี** |
| toast Lost connection / offline | `vo-connection-toast.tsx` + `connectionLostMsg` "You're lost connection. Others can not reach out to you." / `connectionOfflineMsg` · ฟัง `online`/`offline` (`workspace-ws.ts`, `hero-virtual-office.tsx`) | ✅ มี · ⚠️ ข้อความต่างจาก Figma ("Lost connection") + ต้องย้ายเป็น toast ล่างในห้องประชุม |
| Reconnecting… / Unable to reconnect | `reconnectFailedTitle` "Unable to reconnect" + body · `WorkspaceLoading.reconnectNowCta` "Reconnect Now" · LiveKit `RoomEvent.Reconnected/Disconnected` (`sfu-client.ts:481-482`) | ✅ มี flow · ⚠️ Figma ไม่มีหน้า "Unable to reconnect" — ตัดจบแล้วกลับ Home/แมพ + toast (คำถาม 2) |
| **Poor connection** | ไม่มี `ConnectionQuality` ใน `use-meeting-media.ts` / `sfu-client.ts` (grep = 0) | ❌ ใหม่ — LiveKit `ParticipantConnectionQualityChanged` (Poor/Lost) |
| spinner บนป้ายชื่อคนที่หลุด | ไม่มี (มีแค่ mic-off) | ❌ ใหม่ — ใช้ connection quality ของ participant คนอื่นด้วย |
| วิดีโอค้างภาพสุดท้าย | LiveKit track paused → `<video>` ค้างเฟรมสุดท้ายอยู่แล้วโดยปกติ | ✅ น่าจะได้ฟรี 🔍 ทดสอบบนเครื่อง |
| Message not sent | `chat-store.ts:24` `status: "sending" \| "sent" \| "failed"` · `message-item.tsx:198` `isFailed` | ✅ state มี · ⚠️ UI ตอนนี้เป็น bubble ใน list — Figma ใช้ sheet/modal + ปุ่ม Done (คำถาม 4) |
| Chat ส่งซ้ำ 5 ครั้ง | 🔍 ยังไม่พบ retry อัตโนมัติของ REST send | ⚠️ (คำถาม 5) |
| ClickUp "offline chat queue" (§18 ข้อ 20) | ไม่มี | ⚠️ Figma ไม่มี queue — ส่งไม่ได้ = แจ้ง "Message not sent" (คำถาม 6) |

### 14.5 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §14.6)

- technical-design §12.x: timeline หลุด 2 ช่วง (ในห้อง 5 ครั้ง ~31 วิ → หน้าหลัก skeleton + Reconnecting… ≤ 30 วิ → Workspace list) · chat auto-resend 5 ครั้ง backoff เดียวกับ WS · ไม่มี offline queue · zyra-ws grace period ต้อง ≥ ช่วงที่ 1 (~31 วิ) ไม่งั้นที่นั่ง/ห้องหลุดก่อน client ยอมแพ้
- task-breakdown 0.36 (connection states ในห้อง + หน้าหลัก) · 0.37 (chat auto-resend + failed bubble + Message not sent)
- screens.md D / E · clickup-spec §18 ข้อ 56–59

### 14.6 คำถาม / ข้อสงสัย HP-10 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | Poor connection ขึ้นเมื่อไหร่ · คนอื่นเน็ตแย่แสดงยังไง · × ซ่อนนานแค่ไหน | ✅ toast **"Poor connection" เฉพาะเน็ตของเราแย่** · **คนอื่นเน็ตแย่/หลุด → spinner หมุน ๆ บนป้ายชื่อ tile ของคนนั้น** · ✅ **กด × ซ่อน 20 วินาที** (Ten) — ถ้ายังแย่หลังครบ 20 วิ toast ขึ้นใหม่ |
| 2 | Reconnect ไม่สำเร็จกลับไหน (frame Home/แมพ vs sticky workspace list) | ✅ **2 ช่วง:** ① ในห้อง Lost connection → Reconnecting… (ภาพค้าง) **5 ครั้ง** (1/2/4/8/16 วิ ~31 วิ) → **meeting ตัดจบ** → ② หน้าหลักของ workspace (**Lite Home / แมพ รวมแชท**) แสดงเป็น **skeleton** + ข้อความ **"Reconnecting..."** → ต่อได้ใน **30 วิ** = โหลดหน้ากลับมาปกติ · **ไม่ได้ = กลับ Workspace list** (Space builder) |
| 3 | toast "Meeting has ended…" ในแนวนอนด้วยไหม | ✅ **แนวนอนต้องมีด้วย** (frame แมพ `6657-60442` ขาด toast) |
| 4 | ข้อความที่ส่งไม่ได้ค้างใน list ไหม · ปุ่มที่ซ่อน · ไอคอน | ✅ **ค้างใน list เป็น bubble สถานะ failed แตะเพื่อส่งใหม่** · sheet ใช้ปุ่ม **Done** อย่างเดียว (ปุ่มที่ซ่อนไม่ใช้ — retry ทำจาก bubble) · ✅ **ให้หา icon ที่เหมาะ** → ข้อเสนอ §14.7 (lucide-react ตาม rule 12) |
| 5 | "ส่ง 5 ครั้ง" = ส่งซ้ำอัตโนมัติ · ช่วงห่าง | ✅ **ส่งซ้ำอัตโนมัติ 5 ครั้งก่อนขึ้น sheet** · ช่วงห่าง **1/2/4/8/16 วิ แบบ WebSocket** (~31 วิ) · ระหว่างนี้ bubble สถานะ sending |
| 6 | Service ล่มใช้ sheet เดียวกันไหม · ตัด offline queue | ✅ **ใช่** — Service ล่มใช้ sheet "Message not sent" เดียวกัน · **ตัด offline chat queue** ของ ClickUp |
| 7 | หลุดตอนไม่ได้อยู่ในห้องประชุม | ✅ **ใช้ toast แบบเดียวกัน** (Lost connection / Reconnecting…) บน Lite Home / แมพ / แชท |
| 8 | แถว Calendar | ✅ **รอ feature Calendar** (เหมือน HP-08) |

### 14.7 ข้อเสนอ icon (Ten ข้อ 4 — lucide-react เท่านั้น ตาม rule 12 · design ยืนยัน)

| จุด | icon | ขนาด / สี (อ้าง token เดิม) |
|---|---|---|
| วงกลม 80 ใน sheet "Message not sent" | `WifiOff` | วงกลม bg `rgba(240,58,58,0.1)` (แบบ Danger button) · icon 40 `#F03A3A` |
| bubble ข้อความที่ส่งไม่ได้ | `CircleAlert` แทน ✓/✓✓ ท้ายข้อความ + ข้อความ "Not sent · Tap to retry" 10/13 `#F03A3A` | icon 12 `#F03A3A` (ขนาดเดียวกับ read icon 12) |
| bubble ระหว่างส่งซ้ำอัตโนมัติ | `LoaderCircle` หมุน แทน ✓ | 12 `#8C99A6` |
| toast Poor connection | `SignalLow` (หรือ `WifiLow`) | 16 `#ECC819` |
| toast Lost connection | `WifiOff` (Figma ใช้ wifi-offline อยู่แล้ว) | 16 `#F03A3A` |
| toast / ป้ายชื่อ Reconnecting… | `LoaderCircle` หมุน | 16 white (toast) · 12 white (ป้ายชื่อ) |
| toast Meeting has ended due to lost connection | `PhoneOff` | 16 white |

### 14.8 ข้อเสนอ: หน้าหลักแบบ skeleton + "Reconnecting..." (ช่วง ② · Ten ขอให้ทำ — **ยังไม่มีใน Figma ต้องให้ design ยืนยัน**)

**หลักการ:** ใช้ layout จริงของหน้าหลัก (Lite Home §3.8 / แมพ §3.9) แทนเนื้อหาด้วยแท่ง skeleton ตามกฎ HP-07 §11.3 (**ไม่มี text ในแท่ง · animation ไล่ gradient**) · ส่วนที่เป็น chrome ของแอปยังเห็นเหมือนเดิมเพื่อให้รู้ว่ายังอยู่ใน workspace เดิม · มีข้อความ "Reconnecting..." จุดเดียว

| ส่วน | Lite (แนวตั้ง) | Spatial (แนวนอน) |
|---|---|---|
| ยังแสดงจริง | header ชื่อ workspace + โลโก้ (ข้อมูลมีใน cache) · bottom nav (กดไม่ได้ opacity 50%) | ปุ่มกลม 5 ปุ่มขวาบน (opacity 50% กดไม่ได้) · Meeting Menu เฉพาะ avatar (cam/mic/leave ซ่อน) |
| แทนด้วย skeleton | บรรทัด "100 Members · 50 Online" → แท่ง 140×12 · ปุ่มคู่ Start spotlight / Instant meeting → แท่ง 2 อัน h 42 radius 8 · search → แท่ง h 42 · section "In meeting" → หัวข้อแท่ง 80×12 + การ์ด 2 ใบ (h 96 radius 8: แท่งชื่อ 120×14 · แท่ง 160×12 · วงกลม 24 ×4) · "Circle" → วงกลม 48 ×4 · "Online" → แถว 56 ×4 (วงกลม 40 + แท่ง 140×14 + แท่ง 80×12) | แมพ → พื้นทั้งจอเป็น skeleton `#232427` (ไม่โหลด PixiJS ใหม่จนกว่าจะต่อได้) · minimap → กล่อง 169×100 radius 16 skeleton · joystick ซ่อน |
| แชท | ถ้าอยู่แท็บ Chat: แถวแชท 56 ×8 (วงกลม 40 + แท่ง 2 บรรทัด) · ถ้าอยู่ในห้องแชท: bubble skeleton 4–5 อันสลับซ้ายขวา + input ปิด (opacity 50%) | ถ้า overlay แชทเปิดอยู่: คอลัมน์ 249 แถว skeleton + คอลัมน์ 515 bubble skeleton |
| ข้อความ | **toast "Reconnecting..."** แบบ §14.2 (bg black 70% blur 4 radius 8 + `LoaderCircle` 16) ตำแหน่งเดิมเหนือ bottom nav / Meeting Menu — ไม่ใส่ข้อความในแท่ง | เหมือนกัน กลางล่างเหนือ Meeting Menu |
| สี skeleton | แท่ง bg white 5% (`rgba(255,255,255,0.05)`) บนพื้น `#1A1B1E` · การ์ด bg `#232427` · animation ไล่ gradient white 5% → white 10% → white 5% วิ่งซ้ายไปขวา 1.2 วิ วนซ้ำ (ใช้ `components/ui/skeleton.tsx` เดิม) | เหมือนกัน |
| จบช่วง | ต่อได้ภายใน 30 วิ → แทนแท่งด้วยข้อมูลจริง (ไม่ต้องรีเฟรช) · ไม่ได้ → ไป Workspace list + toast "Meeting has ended due to lost connection" | ต่อได้ → โหลดแมพ + คืน joystick/minimap · ไม่ได้ → Workspace list + toast |

**ทำไมไม่เป็นหน้าว่าง/สปินเนอร์เต็มจอ:** ผู้ใช้เห็นว่ายังอยู่ใน workspace เดิม (header/ปุ่มยังอยู่) และ layout ไม่กระโดดตอนข้อมูลกลับมา

**ภาพประกอบ:** mockup ที่แสดงในแชท 2026-10-01 (portrait + landscape) — ใช้อธิบาย ไม่ใช่ spec ระดับ px จาก Figma

## 15. EP-01 · Virtual Office บน Mobile — Performance Fallback (รับ 2026-10-01 · Ten ตอบ 2026-10-01)

**Node:** แนวนอนเท่านั้น section `6662-204168` (844×390) — **แนวตั้งไม่มี เพราะ Lite ไม่มี VO/แมพ** (Ten) · ดึงผ่าน `get_metadata` + `get_design_context` 3 toast + screenshot 11 frame · ClickUp EP-01 อ้าง node `6471-172948` เพิ่ม (ไม่ได้ส่งมา — ไม่ได้ดึง)

### 15.1 โครง section (5 level — แถวละ 1 level)

| Level (หัวแถว Figma) | sticky / frame | สิ่งที่ผู้ใช้เห็น |
|---|---|---|
| **0: FPS ≥ 30 → ปกติ (full quality)** | `6662-204174` | แมพเต็มคุณภาพ |
| **1: ลด canvas resolution (devicePixelRatio 2 → 1)** | sticky **"FPS < 25"** · `6663-205869` | ภาพหยาบลงเล็กน้อย · **ไม่มี toast** |
| **2** (หัวแถวไม่มีคำอธิบาย) | sticky **"ปิด Nature animations (ใบไม้หยุดสั่น) ปิด Weather particles FPS < 21"** · ก่อน `6663-206031` → ฝนตก `6663-207636` → หลัง `6663-234536` | ฝน/เมฆหยุด · toast **"Visual effects reduced"** · "Nature and weather effects were turned off." |
| **3: ลด avatar animation fps (12fps → 6fps)** | sticky **"ปิด Time of Day overlay FPS < 15"** · `6663-234731` → `6663-234732` → `6663-235101` | ท้องฟ้า/แดดหาย (ไม่มี overlay กลางวัน-กลางคืน) · avatar เดินกระตุกขึ้น · toast **"Animations reduced"** · "Avatar animations slowed and Time of Day overlay turned off." |
| **4: Simple mode — static map + dots แทน avatars** | sticky **"static map + dots แทน avatars"** (ไม่มีตัวเลข FPS) · `6663-235292` → `6663-235655` | **แมพกลายเป็น minimap ขยายเต็มจอ** (พื้นดำ `#1A1B1E` + กรอบห้องเส้นขาว · ตัวเรา = **จุดเขียว** กลางจอ + **วงประ** = ระยะได้ยิน · คนอื่น = **วงกลม avatar 24 + "+10"** เป็นกลุ่ม) · minimap มุมขวาล่างหายไป · joystick ยังอยู่ (แบบเส้นบาง) · Meeting Menu / ปุ่มขวาบน / chat ยังอยู่ · toast **"Simplified map"** · "Using a simpler map to improve performance." |

### 15.2 Spec — Notification toast (performance)

ตำแหน่ง `left 269 top 16` w **300** (กลางบน) · bg `#1A1B1E` radius 12 p 8 gap 8 · **Icon Button** bg `rgba(255,212,0,0.1)` radius 8 p 8 + icon **warning-triangle** 16 (เหลือง `#ECC819`) · หัวข้อ Caption 1/Medium 12/15 white · คำอธิบาย Caption 2 10/13 `#8C99A6` · ปุ่ม × 16 · **progress bar** ล่าง h 4 white 20% radius 90 + ช่วงที่วิ่ง gradient `#58D68D → #8FE4B3` (= นับถอยหลังปิดเอง) — layout เดียวกับ notification toast ของ wave (§3.9)

### 15.3 เทียบกับโค้ด / ClickUp

| เรื่อง | Figma EP-01 | ClickUp EP-01 | โค้ดปัจจุบัน |
|---|---|---|---|
| เกณฑ์ FPS | L1 **< 25** · L2 **< 21** · L3 **< 15** · L4 ไม่ระบุ | L1 < 30 · L2 < 25 · L3 < 20 · L4 < 15 | **ระดับเดียว**: `lib/nature-performance.ts:6-12` FPS < **30** นาน 10 วิ (2 sample × 5 วิ) → ปิด nature/weather · กลับ > 45 นาน 30 วิ → เสนอเปิดคืน |
| Level 1 DPR 2 → 1 | ✅ (ไม่มี toast) | ✅ | ❌ `scene.ts:1603` `resolution: window.devicePixelRatio` ไม่ cap (= 3 บน iPhone — TD C13) |
| Level 2 nature + weather | ✅ toast "Visual effects reduced" | ✅ | ✅ มีแล้ว (`use-nature-performance.ts` + toast `natureFxReducedTitle` "Performance optimized") — ⚠️ ข้อความ toast ต่างจาก Figma |
| Level 3 avatar 12 → 6 fps + Time of Day | ✅ | ✅ | ❌ ใหม่ · `scene.ts:5300` `animationSpeed` ปรับได้ · Time of Day overlay 🔍 ยังไม่เจอใน engine (น่าจะอยู่ใน `use-environment.ts`) |
| Level 4 simple mode | minimap เต็มจอ + avatar head cluster | colored dots + ชื่อ · tap-to-move ทำงาน · chat/meeting ปกติ | ❌ ใหม่ · minimap renderer มีแล้ว (ใช้ซ้ำได้?) |
| Toast | 1 ต่อ level (L2–L4) | "⚡ ลด visual effects" 1 ครั้ง | 1 ครั้งตอน degrade + offer toast ตอน recover |
| ผู้ใช้เลือกเอง | — | Settings: "Mobile Performance Mode" (เปิด L3 ทันที) + "เปิด effects เต็ม" · RAM < 200MB เตือน | มี setting เปิด/ปิด nature effects (offer toast) |

### 15.4 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §15.5)

- technical-design §8.x: ladder 5 ระดับเฉพาะมือถือ (เกณฑ์ Figma) · ลดทีละขั้น · recover อัตโนมัติ + toast · toast 10 วิ · RAM warning (native plugin)
- task-breakdown 0.38 (ladder L1–L4 + toast) · 0.39 (เมนู Performance ใน Profile → Setting) · 1.15 (RAM warning plugin) · 0.9 ชี้มาที่ 0.38
- screens.md C (VO core) +1 แถว · clickup-spec §18 ข้อ 60–63 · spec OQ 29–30

### 15.5 คำถาม / ข้อสงสัย EP-01 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | เกณฑ์ FPS Figma หรือ ClickUp · L4 · ระยะเวลาต่อ level | ✅ **ใช้ของ Figma**: L1 < 25 · L2 < 21 · L3 < 15 · ⏳ L4 + ระยะเวลาไม่ได้ระบุ → **สมมติ:** ระยะ 10 วิ (2 sample × 5 วิ เหมือนโค้ด) ต่อขั้น · L4 = อยู่ L3 แล้ว FPS ยัง < 15 ต่ออีก 10 วิ (OQ 29) |
| 2 | ลดทีละ level หรือกระโดด | ✅ "ใช่" → ตีความเป็น **ลดทีละ level** (ตัวเลือกแรก) — ถ้าหมายถึงกระโดด แก้ได้ |
| 3 | กลับขึ้นอัตโนมัติหรือ toast ให้กด | ✅ **ขึ้น toast แล้วกลับเองอัตโนมัติ** · กลับทีละขั้น · **สมมติ:** เกณฑ์ขาขึ้นใช้ของโค้ด (FPS > 45 นาน 30 วิ ต่อขั้น) · ข้อความ toast ขาขึ้นไม่มีใน Figma → ข้อเสนอ §15.6 |
| 4 | L1 ไม่มี toast | ✅ **ใช่** |
| 5 | Simple mode หน้าตา Figma + เดิน/ประชุม/นั่งได้ | ✅ **ใช่** — avatar วงกลม + cluster ตาม Figma · joystick / แตะเดิน / เข้าห้องประชุม / zone / นั่งเก้าอี้ได้ปกติ |
| 6 | Settings "Mobile Performance Mode" | ✅ **ต้องมี** → ข้อเสนอเมนู §15.7 (ไม่มีใน Figma — design ยืนยัน) · **แก้ 2026-10-02 (โน้ต Pai): **ตัดเมนูออก** ปรับเองอย่างเดียว → ux-ui-plan §19** |
| 7 | toast ปิดเองกี่วิ · ข้อความ L2 | ✅ **ปิดเองหลัง 10 วิ** (progress bar 10 วิ) · ✅ **ข้อความ L2 ใช้ของ Figma** ("Visual effects reduced") แทน "Performance optimized" ของโค้ด |
| 8 | มือถือหรือ desktop ด้วย | ✅ **เฉพาะมือถือ** — desktop คงระบบเดิม (ระดับเดียว < 30) |
| 9 | เตือน RAM ต่ำไหม (native plugin) | ⏳ Ten ตอบกลับเป็นคำถามเดิม → **สมมติ: ทำ** ผ่าน native plugin (task 1.15) รอยืนยัน (OQ 30) |

### 15.6 ข้อเสนอ: toast ขาขึ้น (recover อัตโนมัติ — ไม่มีใน Figma)

ใช้ toast เดียวกับ §15.2 แต่ไอคอนเปลี่ยนเป็น `Sparkles` 16 ใน Icon Button bg `rgba(88,214,141,0.1)` สี `#58D68D` · ปิดเองใน 10 วิ
| กลับจาก → ไป | หัวข้อ | คำอธิบาย |
|---|---|---|
| L4 → L3 | Full map restored | Your device can handle the full map again. |
| L3 → L2 | Animations restored | Avatar animations and Time of Day overlay are back. |
| L2 → L1 | Visual effects restored | Nature and weather effects are back on. |
| L1 → L0 | (ไม่มี toast — เหมือนขาลง) | |

### 15.7 ~~ข้อเสนอ: เมนู Performance ใน Profile → Setting~~ — **ตัดออก 2026-10-02 (โน้ต Pai + Ten) → §19.8** (เก็บไว้เป็นประวัติ)

| ส่วน | ข้อเสนอ (อ้าง component HP-06 §10.2) |
|---|---|
| ตำแหน่ง | กลุ่ม **Setting** แถวใหม่ต่อจาก Notification: icon `Gauge` 16 + **"Performance"** + ค่าปัจจุบัน `#8C99A6` ("Auto" / "Performance mode" / "Full effects") + chevron · **แสดงเฉพาะ Spatial** (Lite ไม่มีแมพ) |
| หน้าย่อย | Title menu back + "Performance" · การ์ด radio (แบบ filter sheet HP-07): **Auto** (default — ลด/คืนตาม FPS อัตโนมัติ) · **Performance mode** (ล็อก L3 ทันที ตาม ClickUp) · **Full effects** (ปิด fallback อัตโนมัติ เปิดทุกอย่างเต็ม — ตาม ClickUp "เปิด effects เต็ม") · คำอธิบายใต้แต่ละตัว Body 14/18 `#8C99A6` |
| จำค่า | localStorage ต่อเครื่อง (เหมือน `zyra_workspace_mode`) — key ใหม่ `zyra_perf_mode` |
| แนวนอน | หน้าเต็มจอแบบ Profile – HORIZON (HP-08) |
| RAM ต่ำ (ถ้าทำ) | toast เดียวกับ §15.2 ไอคอนเตือน: "Low memory" · "Close other apps to keep Zyra running smoothly." + แนะนำสลับเป็น Performance mode |

## 16. EP-02 · Meeting Video บน Mobile — Bandwidth ต่ำ / Audio-Only Fallback (รับ 2026-10-01 · Ten ตอบ 2026-10-01)

**Node:** แนวตั้ง section `6471-172948` (390×844, Lite) · แนวนอน section `6662-61731` (844×390, Spatial) · ดึงผ่าน `get_metadata` ทั้ง 2 + `get_design_context` 4 toast + screenshot 9 frame · flow เดียวกันทั้ง 2 แนว (6 frame)

### 16.1 โครง section (1 แถว · 6 ขั้นตามลูกศร)

| ขั้น | sticky (bandwidth) | frame แนวตั้ง / แนวนอน | สิ่งที่เห็น |
|---|---|---|---|
| 1 | **"> 2 Mbps = 720"** | `6472-172956` / `6662-62413` | วิดีโอชัด 720p · ไม่มี toast |
| 2 | **"1 - 2 Mbps = 480"** (แนวนอนพิมพ์ "481") | `6474-173105` / `6662-62523` | 480p · ไม่มี toast |
| 3 | **"500 kbps - 1 Mbps = 360"** | `6474-174442` / `6662-62666` | 360p ภาพเบลอ · toast **"Poor connection."** (icon wifi อ่อนเหลือง + ×) |
| 4 | **"200–500kbps = Auto-switch"** | `6474-173480` / `6662-62913` | **กล้องปิดเอง** (tile เป็น avatar · ปุ่มกล้องเป็น cam-off แดง) · toast **"Camera turned off automatically."** (icon video-off แดง + ×) |
| 5 | (< 200 kbps — ไม่มี sticky) | `6474-174326` / `6662-63031` | กล้องยังปิด · toast **"Very poor connection."** (icon warning-triangle เหลือง + ×) |
| 6 | (กลับมาดี — ไม่มี sticky) | `6481-174457` / `6662-63157` | toast **"Connection restored. Camera is ready."** (icon wifi เขียว `#58D68D` + ×) · **กล้องยังปิด** (ผู้ใช้กดเปิดเอง) |

### 16.2 Spec

toast = **Text notification bottom** เดียวกับ HP-10 §14.2 (bg `rgba(0,0,0,0.7)` blur 4 radius 8 px 8 py 4 gap 8 · icon 16 + Body 14/18 white) **+ ปุ่ม × 16 ทุกอัน** · ตำแหน่งเหนือ Meeting Menu (แนวตั้ง `y 736` · แนวนอน `y 282`) · ข้อความมีจุด "." ท้าย (ต่างจาก HP-10 "Poor connection" ไม่มีจุด ⚠️)

### 16.3 เทียบกับโค้ด / ClickUp

| เรื่อง | Figma EP-02 | ClickUp (HP-10 / EP-02) | โค้ดปัจจุบัน |
|---|---|---|---|
| ระดับวิดีโอ | 720 / **480** / 360 / ปิดกล้อง | HP-10: 720 → 480 → 360 → audio only | `sfu-client.ts:434-443` simulcast **720 / 360 / 180** · `adaptiveStream` + `dynacast` เปิดแล้ว (`:409-410`) — **ไม่มี layer 480** · LiveKit ลด layer ฝั่งผู้รับเองตาม bandwidth |
| ปิดกล้องอัตโนมัติ (200–500 kbps) | ✅ + toast | ✅ "audio only แสดง avatar แทนกล้อง" | ❌ ไม่มี — ตอนนี้กล้องเปิดค้างแม้ uplink แย่ |
| วัด bandwidth | sticky เป็นตัวเลข Mbps/kbps | — | ❌ ไม่มี `ConnectionQuality` (HP-10 §14.4) · ต้องอ่าน uplink bitrate จาก `getStats()` / LiveKit connection quality |
| กล้องกลับมาเมื่อเน็ตดี | ไม่เปิดเอง — toast "Camera is ready." | — | — |

### 16.4 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §16.5)

- technical-design §13.x: uplink ladder บน simulcast เดิม 720/360/180 · auto camera-off 10 วิ · toast · spinner ฝั่งคนดู · ใช้ทั้งมือถือ + desktop
- task-breakdown 0.40 · screens.md D +1 แถว · clickup-spec §18 ข้อ 64–66 · spec OQ 31

### 16.5 คำถาม / ข้อสงสัย EP-02 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | bandwidth = uplink ของเรา · ฝั่งดูไม่ต้องมี toast | ✅ **ใช่** |
| 2 | เพิ่ม layer 480 หรือใช้ 720/360/180 เดิม | ✅ **ใช้ 720/360/180 เดิม** → map แถบ Figma (สมมติ, OQ 31): **> 2 Mbps = 720** · **0.5–2 Mbps = 360** (รวมแถบ 480 + 360 ของ Figma) · toast "Poor connection." เมื่อ < 1 Mbps ตาม Figma · 180 = layer ฐานที่ LiveKit คุมเอง |
| 3 | 200–500 kbps = ปิดกล้องอัตโนมัติ ไมค์ยังเปิด · นานเท่าไร | ✅ **ใช่ · ต่ำต่อเนื่อง 10 วิ** แล้วปิดกล้อง |
| 4 | Very poor < 200 kbps · ต่ำกว่านั้นต่อเป็น HP-10 | ✅ **ใช่** — < 200 kbps = "Very poor connection." · เสียงขาด/หลุด → flow HP-10 (Lost connection → Reconnecting…) |
| 5 | กล้องไม่เปิดเอง · ปิดกล้องเองอยู่แล้วไม่ขึ้น toast | ✅ **ไม่เปิดเอง** · ✅ **ผู้ใช้ปิดกล้องเองอยู่ก่อนแล้ว = ไม่ขึ้น** "Camera turned off automatically." / "Camera is ready." · ⏳ เกณฑ์กลับมาดีไม่ได้ระบุ → **สมมติ: > 1 Mbps นาน 10 วิ** |
| 6 | Poor connection อันเดียวกับ HP-10 · กฎ × 20 วิ · toast อื่นปิดเองกี่วิ | ✅ **ใช่ อันเดียวกัน** กด × ซ่อน 20 วิ · toast อื่น **สมมติปิดเอง 10 วิ** (เท่า EP-01) |
| 7 | คนอื่นเห็นอะไรตอนกล้องเราปิดอัตโนมัติ | ✅ คนอื่นเห็น **รูปโปรไฟล์ (avatar) ของเรา + spinner โหลด ๆ บอกว่าคนนั้นเน็ตไม่ดี** = spinner บนป้ายชื่อแบบ HP-10 §14.2 |
| 8 | มือถือ / desktop · แชร์จอ | ✅ **ทั้งสอง (มือถือ + desktop)** · แชร์จอ: **สมมติ** ไม่หยุดแชร์อัตโนมัติ ให้ LiveKit ลดคุณภาพเอง (OQ 31) |

## 17. EC-03 · Screen Size หลากหลาย — Small Phone vs Tablet vs iPad (รับ 2026-10-01 · Ten ตอบ 2026-10-01)

**Node:** แนวตั้ง section `6511-36398` · แนวนอน section `6662-63286` · ดึงผ่าน `get_metadata` ทั้ง 2 + `get_design_context` iPad mini แนวตั้ง `6580-51729` + screenshot 8 frame + title flow 8 แถว · **ไม่มี sticky note** ใน section นี้ (ไม่มีคำอธิบายพฤติกรรมจาก design)

### 17.1 โครง section (4 แถว · แถวละ 1 ขนาดจอ · แต่ละแถวมีแค่ 1 หน้า)

| แถว | label ใน Figma (title flow) | แนวตั้ง = Lite Home | แนวนอน = Spatial (แมพ) |
|---|---|---|---|
| 1 | iPhone 13/14 : 390×844 | `6577-50371` 390×844 | `6662-65101` 844×390 |
| 2 | iPhone 14 PM : 430×932 | `6577-51276` 430×932 | `6662-65889` 932×430 |
| 3 | iPad Mini : 768×1024 | `6580-51729` **744×1133** ⚠️ (ขนาด iPad mini 8.3 ไม่ใช่ 768×1024 ตาม label) | `6662-203817` 1133×744 |
| 4 | iPad Pro 12.9 : 1024×1366 | `6580-52183` 1024×1366 | `6662-203992` **1399×1024** ⚠️ (label/เครื่องจริง = 1366×1024) |

- **ไม่มีจอเล็ก (Small Phone 320–375)** ใน Figma เลย — แถวเล็กสุด 390×844 ทั้งที่ ClickUp ระบุ iPhone SE 375×667 เป็นเคสหลักของ EC-03 ⚠️
- มีแค่หน้า Lite Home กับหน้าแมพ — **ไม่มี** chat / meeting / modal / settings / onboarding ในขนาด tablet (ClickUp Responsive Testing Checklist มี 10 หน้า)

### 17.2 Spec — แนวตั้ง (Lite Home) เทียบ phone ↔ iPad

| ส่วน | Phone 390 / 430 | iPad 744 / 1024 (`get_design_context` 6580-51729) |
|---|---|---|
| ขอบซ้าย-ขวา | **16** | **24** |
| Header | กว้างเต็ม − 32 (358 / 398) | `left 24 top 24` กว้าง 696 / 976 · logo 40 · ชื่อ workspace Sub/Medium 16/22 + chevron 16 · "100 Members · 50 Online" Caption 12/15 `#8C99A6` · ปุ่ม user-plus 40 + bell 40 (badge `#D41818` Caption 2 10/14) |
| ปุ่มคู่ | แบ่งครึ่ง (195 ที่ 430) gap 8 | `flex-1` ทั้งคู่ (344 / 484) h 42 radius 8 px 16 · Sub/Regular 16/22 · ซ้าย bg white 5% border white 20% · ขวา `#58D68D` · ⚠️ frame ยังเขียน **"Create schedule"** — sticky HP-03 (`6714:163081`) เปลี่ยนเป็น **Start spotlight** แล้ว → ยึด Start spotlight · **แก้ 2026-10-05:** Start spotlight = icon 42×42 ตายตัว · Instant meeting ยืดเต็มที่เหลือ |
| Search + filter | 348 + 42 ที่ 430 | input `flex-1` (646 / 926) h 42 bg `#232427` border white 20% radius 8 px 12 · placeholder Body 14/18 `#636D76` · filter 42×42 |
| การ์ด In meeting | เต็มความกว้าง | **เต็มความกว้าง เรียงลงทีละใบ** (ไม่เป็น grid) bg `#232427` border white 5% p 12 radius 8 gap 16 · badge Locked `#F03A3A` |
| Circle | วงกลม 56 wrap | เหมือนกัน 56 (bg orange 20% border orange 20%) |
| แถวสมาชิก | h 56 avatar 40 | h 56 px 24 avatar 40 · ชื่อ Body/Medium 14/18 · สถานะ Caption 12/15 · "In meeting" `#996ADF` |
| Bottom bar | 358 / ~395 · h 56 · ลอย bottom 16 | `left/right 3.23%` (= 24) → 696 / 976 · h 56 p 4 pill radius 1000 bg `rgba(26,27,30,0.5)` · 4 icon 24 เท่าเดิม (ไม่มี label) |
| จำนวนคอลัมน์ | 1 | **1 คอลัมน์ ยืดเต็มจอ** — ไม่มี 2-column / sidebar / max-width |

### 17.3 Spec — แนวนอน (Spatial) เทียบ phone ↔ iPad

| ส่วน | Phone 932×430 (`6662-65889`) | iPad 1133×744 / 1399×1024 |
|---|---|---|
| ปุ่มกลมขวาบน 5 ปุ่ม (weather, megaphone, calendar, member, notifications) | **32×32** gap 8 → กล่อง 192×32 · `right 32 top 16` · icon 16 | **44×44** gap 16 → กล่อง 284×44 · `right 32 top 16` · icon 16 เท่าเดิม (padding 14) |
| ปุ่ม Chat ซ้ายล่าง | 32×32 `left 32 bottom 56` | **32×32 เท่าเดิม** ⚠️ (ไม่ขยายตามปุ่มบน) · `left 32 bottom 16` |
| Joystick | 128×140 `left 88` | **128×140 เท่าเดิม** `left 88 bottom 16` |
| Minimap | 169×100 `right 32 bottom 16` | **169×100 เท่าเดิม** |
| Meeting Menu (avatar · cam · mic · leave) | 200×56 กลางล่าง bottom 16 | **200×56 เท่าเดิม** |
| Notification toast | 300×48 top 16 (hidden) | เหมือนกัน (hidden) |
| ป้าย workspace ซ้ายบน (`Frame 2`, logo + "Office workspace") | hidden | hidden — ทุกขนาด |
| แมพ | ซูมเท่าเดิม เห็นพื้นที่มากขึ้นตามจอ | เห็นพื้นที่มากขึ้น (ไม่ได้ซูมขยาย) |

→ ต่างกันแค่ **ปุ่มขวาบน 32 → 44** บน iPad · ที่เหลือขนาดคงที่ ยึดมุมจอ

### 17.4 ระบบทำงานยังไง (ตามที่ Figma บอก)

1. **iPad / tablet ใช้ UI มือถือ ไม่ใช่ UI desktop** — แนวตั้งเป็น Lite Home + bottom nav · แนวนอนเป็น Spatial HUD + joystick → แปลว่า tablet ต้องผ่านหน้า Select workspace mode + หน้า Rotate + จำโหมด 1 วันเหมือนมือถือ ⚠️ **ขัดกับ spec.md "Tablet ≥ 768px ใช้ layout desktop"** (OQ 9)
2. ดังนั้น **ตัดสิน "มือถือ/ไม่ใช่มือถือ" ด้วยความกว้าง < 768px ไม่ได้แล้ว** (iPad Pro แนวนอน 1366 กว้างกว่า laptop หลายเครื่อง) → ต้องตัดสินจาก **ชนิดอุปกรณ์** (ข้อเสนอใน §17.6)
3. Layout เป็น **fluid** — ยึดขอบ (16 phone / 24 tablet) แล้วยืดกลาง · ไม่มี breakpoint จัดคอลัมน์ใหม่
4. ขนาดปุ่มแตะบน tablet ขยาย (44) เฉพาะปุ่มบนของแนวนอน · ส่วนอื่นเท่ามือถือ

### 17.5 เทียบกับ ClickUp / โค้ด / มติเดิม

| เรื่อง | Figma EC-03 | ClickUp EC-03 | โค้ด / มติเดิม |
|---|---|---|---|
| Tablet layout | 1 คอลัมน์ยืด (Lite) / HUD มือถือ (Spatial) | **2-column หรือ sidebar-content · sidebar collapsed icon-only** | spec: tablet = desktop layout (OQ 9 ค้าง) · โค้ด: `mobile-unsupported-overlay.tsx:9` ใช้ `max-md` (< 768) CSS ล้วน → iPad ทุกรุ่นได้หน้า desktop |
| Small phone 320–375 | ❌ ไม่มี frame | ไม่มี horizontal overflow · modal max-height 90vh scroll · keyboard ไม่บัง input · VO HUD ย่อ controls | technical-design C5: modal/panel fixed 320–934px ~20+ ไฟล์ ล้นจอ |
| Meeting บน tablet | ❌ ไม่มี frame | **6–9 tiles (grid 3×3)** | HP-04 §8 มีแค่ phone |
| iPad Split View / Slide Over | ❌ ไม่มี | ✅ ต้องรองรับ | ⚠️ ขัดกับมติ HP-07 "หน้าก่อนเข้า workspace = แนวตั้งอย่างเดียว (native lock)" — iPad ที่รองรับ multitasking ต้องรองรับทุก orientation (Apple) · ทางเลี่ยงเดิม `UIRequiresFullScreen` ถูกประกาศเลิกใช้ใน iPadOS 26 🔍 (ต้องเช็คเอกสาร Apple ล่าสุดอีกครั้ง) → บน iPad lock orientation ไม่ได้จริง ต้องใช้หน้า Rotate แทน |
| Font scaling (accessibility) | ❌ | ✅ ตาม user setting | ไม่มีในโค้ด · iOS WKWebView ไม่ขยายตาม Dynamic Type เอง · Android WebView ขยายตาม font size ระบบเอง (textZoom) → layout fixed px อาจแตก |
| Dark mode ตาม system | — (Figma dark ทั้งหมด) | ✅ | app dark-only (clickup-spec §18 ข้อ 19) |
| Android tablet (Galaxy Tab 800×1280) | ❌ | อยู่ใน device matrix | — |
| Calendar / Tarot / Participation Dashboard ใน checklist | — | อยู่ใน Responsive Testing Checklist | ไม่มีในโค้ด (clickup-spec §18 ข้อ 5) |

### 17.6 กติกา (Ten รับข้อเสนอทั้งหมด 2026-10-01 — §17.7)

- **ตัวตัดสิน UI มือถือ (ข้อ 2):** ใน app (Capacitor) = **มือถือ + tablet ใช้ UI มือถือเสมอ** (`Capacitor.isNativePlatform()`) · บนเว็บ = `(pointer: coarse)` **และ** ด้านยาวของจอ ≤ 1366 → UI มือถือ · นอกนั้น = desktop · หมายเหตุ: iPad Safari ส่ง UA เป็น Mac โดย default → ห้ามใช้ UA อย่างเดียว (ใช้ `navigator.maxTouchPoints > 1` ช่วย) · **iPad ที่ต่อคีย์บอร์ด/trackpad บนเว็บ = ยังเป็น UI มือถือ**
- **Orientation บน tablet (ข้อ 7):** รองรับ Split View / Slide Over → **ไม่ lock native บน tablet** · หน้าก่อนเข้า workspace บน tablet **แสดงแนวนอนได้ โดยจัดคอลัมน์ layout แนวตั้งไว้กลางจอ** (กว้างไม่เกิน ~480 🔍 design ยืนยันค่า) · มือถือยังคงกฎ HP-07 (lock แนวตั้ง) · โหมด Lite/Spatial ตัดสิน "แนวตั้ง/แนวนอน" จาก **สัดส่วนหน้าต่าง** (`innerWidth < innerHeight`) ไม่ใช่การหมุนเครื่อง — Split View ครึ่งจอบน iPad แนวนอนจะนับเป็นแนวตั้ง · **แก้ 2026-10-05 (Ten): แยก 2 แบบ** — **หน้ารายการเต็มจอ ขอบ 24**: Space builder (การ์ด 2 คอลัมน์บน iPad ทั้ง 2 แนว) · Create workspace เลือก template (grid 3 คอลัมน์แนวตั้ง / 4 คอลัมน์แนวนอน) · **หน้าฟอร์ม / ข้อความ คงคอลัมน์ ~480 กลางจอ**: Splash · onboarding · Get started / login · สมัคร · OTP · ลืม / ตั้งรหัสใหม่ · Select workspace mode · Keep This Setting? · Workspace details · Workspace created · Connecting · Rotate · รับคำเชิญ · ลิงก์ใช้ไม่ได้ · signed out · Update required · maintenance · พื้นนอกคอลัมน์ใช้สีเดียวกับหน้า (`#1A1B1E`) ไม่มีแถบมืด
- **Breakpoint ภายใน UI มือถือ (ข้อ 5):** ด้านสั้นของหน้าต่าง ≥ 744 → ขอบ 24 + ปุ่มกลมขวาบน 5 ปุ่ม **และปุ่ม Chat ซ้ายล่าง = 44** · น้อยกว่านั้น → ขอบ 16 + ปุ่ม 32 · joystick / minimap / Meeting Menu ขนาดเดิมทุกจอ · **ไม่มี max-width** (ข้อ 3) · bottom sheet กว้างสุด 600 อยู่กลางจอ (ข้อ 11)
- **Small phone ≤ 375 (ข้อ 4):** ใช้ layout 390 เดิม ขอบ 16 · ข้อความยาวตัดเป็น … ตามความเหมาะสมของแต่ละจุด (ปุ่มคู่ ชื่อ workspace ชื่อสมาชิก ชื่อห้อง) · Spatial 667×375: HUD ขนาดเดิม (joystick 128 + Meeting Menu 200 + minimap 169 + ขอบ ≈ 600 < 667 พอดี) · modal ทุกตัว `max-h-[90dvh]` scroll + `scrollIntoView` ตอนคีย์บอร์ดขึ้น
- **Font scaling (ข้อ 8):** รอบแรก lock ขนาดตัวอักษร 100% (Android `textZoom` = 100 ผ่าน plugin `@capacitor/text-zoom`) · รองรับ scaling เป็นงานรอบหลัง

### 17.7 คำถาม / ข้อสงสัย EC-03 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | Tablet (iPad / Android tablet) ใช้ **UI มือถือ** (Lite/Spatial + เลือกโหมด + หน้า Rotate) ตาม Figma ใช่ไหม — แปลว่ายกเลิก "tablet ≥ 768 = desktop" ใน spec | ✅ **ใช่** — tablet ใช้ UI มือถือ · ยกเลิก "tablet ≥ 768 = desktop" |
| 2 | ใช้อะไรตัดสินว่าเป็น UI มือถือ — app = มือถือเสมอ · เว็บ = จอสัมผัส + ด้านยาว ≤ 1366 · iPad ที่ต่อคีย์บอร์ด/trackpad บนเว็บยังนับเป็นมือถือไหม | ✅ **app = มือถือเสมอ · เว็บ = จอสัมผัส + ด้านยาว ≤ 1366** · iPad + trackpad บนเว็บ = **นับเป็นมือถือ** |
| 3 | ClickUp ขอ tablet **2-column / sidebar** แต่ Figma เป็น 1 คอลัมน์ยืดเต็มจอ — ยึดอันไหน · ถ้ายึด Figma จะจำกัดความกว้างการ์ด/แถว (max-width) บน iPad Pro ไหม | ✅ **ยึด Figma ไม่จำกัด max-width** |
| 4 | **Small phone 320–375** (iPhone SE 375×667) ไม่มี frame — ใช้ layout 390 ย่อเอาตาม §17.6 ได้ไหม หรือจะมี design เพิ่ม | ✅ **ได้** ใช้ layout 390 · ข้อความยาวตัดเป็น … ตามความเหมาะสม |
| 5 | ปุ่มขวาบน Spatial บน iPad = **44** แต่ปุ่ม Chat ซ้ายล่างยัง 32 · joystick / minimap / Meeting Menu ไม่ขยาย — ตั้งใจไหม · ขนาด 44 เริ่มที่จอขนาดไหน | ✅ **ปุ่ม Chat = 44 ด้วย** · เริ่มที่ด้านสั้น ≥ 744 |
| 6 | **Meeting บน tablet**: ClickUp ขอ grid 3×3 (6–9 tiles) — ทำไหม หรือใช้ layout HP-04 ของมือถือยืดเอา | ✅ **ทำ** grid 3×3 บน tablet (รอ design) |
| 7 | **iPad Split View / Slide Over** ต้องรองรับไหม — ถ้ารองรับ iPad จะ lock แนวตั้งก่อนเข้า workspace ไม่ได้ (มติ HP-07) ต้องเปลี่ยนเป็นหน้า Rotate หรือยอมให้แนวนอน · โหมดตัดสินจากสัดส่วนหน้าต่าง | ✅ **รองรับ** · ตัดสินโหมดจากสัดส่วนหน้าต่าง · หน้าก่อนเข้า workspace แนวนอนได้ จัดกลางจอ |
| 8 | **Font scaling** ตามที่ตั้งในเครื่อง — รอบแรก lock 100% ได้ไหม | ✅ **ได้** lock 100% รอบแรก — Android ขยายตัวอักษรเองทำให้ layout แตก |
| 9 | **Dark mode ตาม system** — app เป็น dark อย่างเดียวอยู่แล้ว ไม่ทำ light ใช่ไหม | ✅ **ใช่** dark อย่างเดียว |
| 10 | label ใน Figma ไม่ตรง frame (iPad Mini 768×1024 vs 744×1133 · iPad Pro แนวนอน 1399 vs 1366) — ยึดขนาด frame เป็นตัวอย่าง แล้ว layout fluid ได้ทุกขนาดใช่ไหม | ✅ **ใช่** fluid ทุกขนาด |
| 11 | หน้าอื่นใน Responsive Testing Checklist (chat, meeting, calendar, profile/settings, modal/bottom sheet) บน tablet — จะมี frame เพิ่ม หรือให้ยืดจาก phone ตามกติกาเดียวกัน (ขอบ 24 · 1 คอลัมน์) | ✅ **ยืดจาก phone** · bottom sheet กว้างสุด 600 อยู่กลางจอ |

### 17.8 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §17.7)

- spec.md: **OQ 9 ปิด** (tablet = UI มือถือ) · **OQ 32 ปิด** · ย่อหน้าโหมด "มือถือ (< 768px)" → "มือถือและ tablet" · ลบ out-of-scope "Tablet layout เฉพาะ — ใช้ layout desktop" · ตารางโหมดแถว "ก่อนเข้า workspace" เพิ่มข้อยกเว้น tablet
- technical-design §16.1 / §16.4: orientation ตัดสินจาก **สัดส่วนหน้าต่าง** แทน `screen.orientation` · §16.5 แถว HP-07: lock แนวตั้งเฉพาะมือถือ · §16.6 iPad/Android tablet config · **§16.8 ใหม่** device class + breakpoint tablet
- task-breakdown 0.41–0.46 + 1.16 · 0.12 อ้าง 0.42 · screens.md §0.1 +2 แถว · clickup-spec §18 ข้อ 67–75
- §11 HP-07 "แนวตั้งอย่างเดียว" ยังถูกสำหรับมือถือ · บน tablet ใช้กติกา §17.6 ข้อ 7

## 18. HP-11 · Mobile Responsive — Spotlight (Presenter + Viewer) (รับ 2026-10-01 · Ten ตอบ 2026-10-01)

> ⚠️ **§18.1–18.6 เป็นเวอร์ชันเก่า (Figma 2026-10-01)** — Figma อัปเดต 2026-10-05 ทั้งแนวตั้งและแนวนอน ดู **§18.9 / §18.10**

**Node:** แนวตั้ง section `6710-161801` (390×844, Lite) · **แนวนอนไม่มีใน Figma — Ten ให้ปรับจากแนวตั้ง (ข้อเสนอ §18.6)** · ดึงผ่าน `get_metadata` section + `get_design_context` หน้า Spotlight `6716-163539`, bottom sheet `6716-214633`, toast `6726-219289` / `6729-221605` + screenshot 6 frame · **ไม่มี sticky note** · มีแต่ฝั่ง **Presenter** — ฝั่ง Viewer ไม่มี frame ⚠️

### 18.1 โครง section (1 แถว + 1 frame ใต้ขั้น 2)

| ขั้น | frame | สิ่งที่เห็น |
|---|---|---|
| 1 | Homepage `6710-161803` | Lite Home (§3.8) — ปุ่ม **Start spotlight** ซ้ายบน (คู่ Instant meeting) · Chat tab มี badge 10 |
| 2 | Instant Meeting `6716-163539` (ชื่อ layer เดิม แต่เป็นหน้า Spotlight) | หน้า **Spotlight** ก่อน live: header "Spotlight" · tile ตัวเอง (Matthew) · Meeting Menu มีปุ่ม **Play** |
| 2a | Spotlight - More menu `6716-204281` | กด ⋮ → **Bottom sheet - Spotlight** |
| 3 | Spotlight `6726-219288` | กด Play → toast **"Spotlight will be started within 5 seconds"** + ปุ่ม **Stop** |
| 4 | Spotlight `6729-221524` | นับถอยหลัง "…within **4** seconds" (frame เดียวกัน เปลี่ยนแค่ตัวเลข) |
| 5 | Spotlight `6729-221603` | toast **"Spotlight started now"** (ไม่มีปุ่ม) · ปุ่ม Play เปลี่ยนเป็น **Stop (สี่เหลี่ยม)** = live แล้ว |

### 18.2 Spec — แนวตั้ง (get_design_context)

**หน้า Spotlight** bg `#1A1B1E` — โครงเดียวกับหน้า Meeting HP-04 (§8.2)
- **Header** `top 24 w 358` กลาง gap 16: ซ้าย ปุ่ม **chevron-down** (bg white 5% p 8 radius 8 icon 16) + "Spotlight" Body/Medium 14/18 ขาว ellipsis · ขวา gap 8 ปุ่ม **chat** + **speaker (unmute)** แบบเดียวกัน · ไม่มี lock / user-plus / สลับกล้อง (ต่างจาก Meeting)
- **Display** `left 16 top 96 w 358 h 636` · tile 1 คน h 338 กลาง: bg white 5% radius 12 p 4 · avatar 56 วงกลม (สีพื้นตามคน) กลาง · name tag ซ้ายล่าง bg black blur 4 radius 8 px 6 py 4: mic-off 14 แดง + Caption 1/Regular 12/15
- **Meeting Menu** `bottom 16 w 358` bg `#232427` radius 16 p 8 justify-between · ปุ่ม icon 24 p 8 radius 8: **cam (off แดง)** · **mic (off แดง)** · **share screen** · **⋮ more** ┃ **Play** (ขาว) · **leave** (bg `rgba(212,24,24,0.2)` icon แดง) — ต่างจาก Meeting: ไม่มี emoji / raise hand ในแถบ (ย้ายไปอยู่ใน sheet) + มีปุ่ม Play/Stop
- live แล้ว (`6729-221603`): ปุ่ม Play → icon **square (Stop)** ขาว

**Toast** = Text notification bottom (§14.2) bg `rgba(0,0,0,0.7)` blur 4 radius 8 · Body/Regular 14/18 ขาว · `y 736` (เหนือ Meeting Menu 4 px · กลางจอ)
- นับถอยหลัง: w 341 h 32 · pl 8 pr 4 py 4 gap 8 · "Spotlight will be started within **N** seconds" + ปุ่ม **Stop** (h 24 px 8 bg white 5% border white 20% radius 4 Body 14)
- live: w 159 h 32 px 8 py 4 · "Spotlight started now" ไม่มีปุ่ม

**Bottom sheet - Spotlight** `y 588` w 390 h 256 bg `#232427` radius บน 24 · pt 40 px 16 pb 16 gap 16 · grabber 34×4 white 20% `top 8` กลาง
- แถว 1: **Start spotlight** (icon play 16 + Body/Regular 14/18) เต็มกว้าง h 56 bg white 5% radius 8
- แถว 2 (3 ช่อง flex-1 gap 16 h 56 icon 16 ไม่มี label): **speaker** · **share screen** · **raise hand**
- แถว 3: **settings** · **emoji** · **chat**
- ⚠️ ซ้ำกับปุ่มอื่น: Start spotlight = Play ในแถบ · speaker / chat = ปุ่มใน header · share screen = ปุ่มในแถบ

### 18.3 ระบบทำงานยังไง (ตาม Figma + โค้ด web)

1. Lite Home → กด **Start spotlight** → เปิดหน้า Spotlight (**ยังไม่ live** — ตั้งไมค์/กล้องก่อนได้) = เทียบกับ web ที่ "ยืนบน marker แล้วเห็นปุ่ม Play" (`use-spotlight-broadcast.ts:7-14`)
2. กด **Play** → นับถอยหลัง 5 วิ (toast + Stop ยกเลิกได้) → server ยืนยัน → toast "Spotlight started now" + ปุ่มเป็น Stop · web มีอยู่แล้ว: นับ 5 วิ (`getSpotlightCountdownSeconds` `:130`, ข้อความ web "Going live in {seconds} seconds." / "Cancel broadcast") · **live = ถือว่าเริ่มเมื่อ server ส่ง speaker set ที่มีตัวเรา** เท่านั้น
3. live = ออกอากาศให้ **ทั้ง floor** (room `spotlight:<floorId>`) · คนอื่นที่ไม่อยู่ใน meeting ฟัง/ดูอัตโนมัติ · คนใน meeting ต้องให้ห้องรับก่อน (`accepted_meeting_ids`, ปุ่ม web "Join spotlight" / "Stay in meeting")
4. กด Stop / leave ตอน live → web มี confirm "Stop broadcasting?" (`spotlightExitTitle`) 🔍 Figma ไม่มี

### 18.4 เทียบกับโค้ด / ClickUp

| เรื่อง | Figma HP-11 | ClickUp HP-11 | โค้ด web ปัจจุบัน |
|---|---|---|---|
| เริ่ม Spotlight | ปุ่ม Start spotlight บน Lite Home → หน้า Spotlight → Play | Presenter **เดินเข้า marker** → prompt "แตะเพื่อขึ้น Stage" → **confirm bottom sheet** | ต้อง**ยืนบน spotlight tile** — server ตรวจตำแหน่ง (`spotlightStartNotOnTile` "Stand on the Spotlight marker…") · ⚠️ **Lite ไม่มีตำแหน่ง (ghost)** → zyra-ws ต้องรับ start จาก Lite โดยไม่ตรวจตำแหน่ง (งานใหม่) |
| ยืนยันก่อน live | นับถอยหลัง 5 วิ + Stop | confirm sheet "ขึ้น Stage A? [ขึ้น Stage] [ยกเลิก]" | นับ 5 วิ + Cancel ✅ ตรง Figma |
| HUD ตอน live | ปุ่ม Stop แทน Play · ไม่มี LIVE / จำนวนผู้ชม | "⭐ LIVE" + viewer count + ปุ่มออก | stage มี Viewers list (`vo-spotlight-stage.tsx:286`) |
| Controls | cam · mic · share · ⋮ ┃ Play/Stop · leave (+ sheet: speaker, share, hand, settings, emoji, chat) | 🎤 📹 📺 💬 ≥ 44px | — |
| Screen share | ปุ่มอยู่ในแถบ + sheet | iOS ReplayKit / Android MediaProjection · browser → "รองรับเฉพาะแอป" | มือถือ = Phase 3 native (clickup-spec §18 ข้อ 23, 31) |
| Viewer ไม่อยู่ใน meeting | ❌ ไม่มี frame | เปิดเต็มจอทันที · portrait: video + chat bar ล่าง · landscape: video ซ้าย chat ขวา · swipe down → mini bar | web: stage ลอย + expand / PiP (`:304, :948`) |
| Viewer อยู่ใน meeting | ❌ ไม่มี frame | toast "Bob กำลัง Present [ดู] [เดี๋ยวก่อน]" → sheet 40–60vh · ได้ยินเสียง meeting | web: "Join spotlight" / "Stay in meeting" · ห้องรับแล้วปิดให้ทั้งห้อง (`spotlightLeaveBodyMeeting`) |
| Multiple Spotlight | ❌ | tabs บน "Stage A (Bob) / Stage B (Alice)" | web: **speaker set เดียวต่อ floor** (หลายคนพูดใน broadcast เดียว) ไม่ใช่หลาย stage |
| Spotlight ใน Spatial | ❌ (ไม่มีแนวนอน) | — | Spatial HUD มีปุ่ม megaphone ขวาบน (§3.9) |
| Status Busy/Away/DND | — | — | web บล็อกการเริ่ม (`blockedByStatus`) |
| Feature flag | — | — | `NEXT_PUBLIC_SPOTLIGHT` + zyra-ws `SPOTLIGHT` (`lib/spotlight-feature.ts`) |

### 18.5 Spec ที่ไม่ได้มาจาก Figma (ต้องใช้กติกาจาก subtask อื่น)

- chevron-down = ย่อเป็น **PIP** แบบ HP-04 (tile 168×158) — presenter ยัง live อยู่ 🔍 (ข้อ 6)
- ปุ่ม cam / mic ขอ permission ตอนกดตาม HP-09 §13.6 · เน็ตแย่ตาม EP-02 §16 (ปิดกล้องอัตโนมัติก็ใช้กับ spotlight)
- Tablet ตาม EC-03 §17.6 (ขอบ 24 · ไม่มี max-width · sheet กว้างสุด 600 กลางจอ)

### 18.6 แนวนอน (Spatial 844×390) — ปรับจากแนวตั้ง (Ten รับข้อเสนอ 2026-10-01 ข้อ 14 · **design ยืนยันภาพ**)

ยึดโครงหน้า Meeting แนวนอนของ HP-04 (§8.2) ที่ design ทำไว้แล้ว เพื่อให้เหมือนกันทั้งแอป:

| ส่วน | แนวตั้ง (Figma) | แนวนอน (ข้อเสนอ) |
|---|---|---|
| พื้น | `#1A1B1E` เต็มจอ | `#1A1B1E` เต็มจอทับแมพ (แมพหยุด paint ด้วย `setRenderSuspended` ระหว่างอยู่หน้า Spotlight · WS/LiveKit ยังต่อ) |
| Header | `top 24 w 358` | `left 32 top 16 w 780` · ซ้าย chevron + "Spotlight" · ขวา chat + speaker (ปุ่มเดียวกัน 32) |
| Display | `left 16 top 96 w 358 h 636` · tile 1 คน h 338 | `left 32 top 64 w 780 h 238` · tile 1 คน **358×238 กลาง** · หลายคน = ตาราง HP-04 แนวนอน (2 = 358 คู่ gap 16 · 3 = 249.33 · 4–6 = 2×3 h 111) |
| Meeting Menu | `bottom 16 w 358` | **เหมือนเดิม** `bottom 16 w 358` กลาง · ปุ่มชุดเดียวกัน |
| Toast นับถอยหลัง / started | `y 736` | กลางจอ `bottom 76` (= `y 282`) ตำแหน่งเดียวกับ toast HP-10 / EP-02 แนวนอน |
| More (⋮) | bottom sheet เต็มกว้าง radius บน 24 | **modal กลางจอ w 390** radius 16 bg `#232427` p 16 gap 16 ไม่มี grabber (แบบ Join meeting แนวนอน HP-04) · ภายใน 3 แถวเหมือนเดิม (h 56) · overlay black 50% แตะนอกเพื่อปิด · สูง 16+56+16+56+16+56+16 = 232 < 390 พอดี |
| เข้าจาก | ปุ่ม Start spotlight บน Lite Home | **ปุ่ม megaphone ขวาบนของ Spatial HUD** → หน้า Spotlight (ข้อ 3) |
| Tablet (≥ 744) | ขอบ 24 | ขอบ 24 · ปุ่ม header 44 ตาม EC-03 · Display ยืดเต็ม − 48 |

### 18.7 คำถาม / ข้อสงสัย HP-11 — คำตอบจาก Ten (2026-10-01)

| # | คำถาม | คำตอบ / สถานะ |
|---|---|---|
| 1 | **Viewer ไม่มี frame** — คนที่ไม่อยู่ใน meeting: เปิดหน้า Spotlight เต็มจอให้อัตโนมัติ (ตาม ClickUp) ใช้หน้าเดียวกับ presenter แต่แถบมีแค่ speaker / chat / emoji / raise hand / leave ใช่ไหม | ✅ **ใช่** — เปิดหน้า Spotlight เต็มจออัตโนมัติทั้ง Lite และ Spatial · แถบคนดู = speaker / chat / emoji / raise hand / leave · ไม่มี cam / mic / share / Play · **แก้ 2026-10-05 (Figma HP-11 v2): คนดูนอก meeting ได้ toast ✓ / × แทนการเปิดเอง → ux-ui-plan §18.9** |
| 2 | **Viewer ที่อยู่ใน meeting** — ClickUp: toast [ดู] [เดี๋ยวก่อน] → sheet ครึ่งจอ ฟังเสียง meeting ต่อ · web: ห้องกด Join แล้วเปิดให้ทั้งห้อง — ยึดอันไหน | ✅ **ยึด web** — toast "Join spotlight" / "Stay in meeting" · Join แล้วหน้า Spotlight แทนหน้า meeting (เปิดให้ทั้งห้องตาม `accepted_meeting_ids`) · กลับ meeting ด้วย chevron · **แก้ 2026-10-05 (Figma HP-11 v2): ✓ = ทั้งห้อง · Undo = ทั้งห้องเลิกดู · ไอคอนแทนข้อความ Join / Stay → ux-ui-plan §18.9** |
| 3 | **เริ่มจาก Lite (ไม่มีตำแหน่ง)** — server ตอนนี้บังคับยืนบน marker · ให้ Lite เริ่มได้เลยโดยไม่ต้องอยู่บน marker ใช่ไหม · คนบนแมพเห็นอะไร (avatar โผล่ที่ spawn แล้วเดินไป marker แบบ ghost เข้า meeting?) | ✅ **ใช่** — Lite เริ่มได้โดยไม่อยู่บน marker · คนบนแมพเห็น avatar ghost โผล่ที่ spawn แล้วเดินไปยืนที่ marker (แบบ ghost เข้า meeting TD §16.2) |
| 4 | **เริ่มจาก Spatial** — กดปุ่ม megaphone ขวาบนแล้วเปิดหน้า Spotlight ได้เลย หรือต้องเดินไปยืน marker แล้วกด Play แบบ desktop | ✅ **ใช่** — megaphone → avatar เดินไป marker อัตโนมัติ + เปิดหน้า Spotlight · เดินไปเองแล้วเห็นปุ่ม Play ใน Meeting Menu ได้ด้วย |
| 5 | ถ้า workspace มี **หลาย floor / หลาย marker** — Lite เริ่ม spotlight ที่ floor ไหน | ✅ **ใช่** — floor แรก ไม่มีตัวเลือกรอบแรก |
| 6 | **chevron-down** = ย่อเป็น PIP แบบ meeting (ยัง live ต่อ) ใช่ไหม · กด leave ตอน live ต้องถามยืนยัน "Stop broadcasting?" แบบ web ไหม (Figma ไม่มี) | ✅ **ใช่** — chevron = PIP (ยัง live) · leave / Stop ตอน live ขึ้น sheet ยืนยัน (ข้อความ web "Stop broadcasting?") · Stop ใน toast นับถอยหลังไม่ต้องยืนยัน · **แก้ 2026-10-05 (Figma HP-11 v2): sheet "Leave Spotlight?" Cancel / Leave → ux-ui-plan §18.9** |
| 7 | **"Spotlight started now"** ปิดเองกี่วิ | ✅ **3 วิ** |
| 8 | **Bottom sheet ซ้ำกับปุ่มอื่น** (Start spotlight = Play · speaker / chat = header · share = แถบ) — ตั้งใจไหม · raise hand ใน spotlight ใช้กับใคร (presenter ยกมือเอง?) · settings ตั้งอะไร | ✅ **ยึด Figma** · Start spotlight ใน sheet เปลี่ยนเป็น "Stop spotlight" ตอน live · raise hand = ของคนดู (presenter เห็นคิว) · settings = เลือกไมค์ / กล้อง / ลำโพง · **แก้ 2026-10-02 (โน้ต Pai): คนดู**ไม่มี** emoji / raise hand · bottom menu คนดู = Chat · Speaker · Leave → ux-ui-plan §19** · **แก้ 2026-10-05 (Figma HP-11 v2): ไม่มี Play / Stop ในแถบ · More = Emoji · Chat · Setting · Invite → ux-ui-plan §18.9** |
| 9 | **LIVE badge + จำนวนผู้ชม** (ClickUp AC) ไม่มีใน Figma — เพิ่มไหม | ✅ **เพิ่ม** chip "LIVE · N" ข้าง "Spotlight" ใน header ตอน live · แตะ = รายชื่อผู้ชม · 🎨 design ยืนยัน · **แก้ 2026-10-02 (โน้ต Pai): ป้าย LIVE (ไม่มีเลข) + ตัวนับ `Mic` N / `Eye` N ขวาสุด → sheet 2 แท็บ On stage / Viewers → ux-ui-plan §19** · **แก้ 2026-10-05 (Figma HP-11 v2): ชิป `Users` "N | M" → ux-ui-plan §18.9** |
| 10 | **Screen share** ในหน้า Spotlight บนมือถือ — รอบแรกปุ่ม disabled + tooltip แบบ HP-04 · app ทำได้ Phase 3 (ReplayKit / MediaProjection) ใช่ไหม | ✅ **ใช่** — รอบแรก disabled + tooltip แบบ HP-04 · app แชร์ได้ Phase 3 |
| 11 | **Multiple Spotlight** (ClickUp tabs Stage A / Stage B) — web เป็น broadcast เดียวต่อ floor หลายคนพูดได้ · บนมือถือหลายคนพูด = tile หลายอันแบบ meeting ไม่มี tab ใช่ไหม | ✅ **ใช่** — หลายคนพูด = tile หลายอันแบบ meeting ไม่มี tab |
| 12 | **chat** ใน spotlight เปิดแบบไหน — หน้าเต็มจอแบบห้องแชท HP-05 · ถ้าอยู่ใน meeting ด้วยมี tab Spotlight / Meeting แบบ web | ✅ **ใช่** — แชทเต็มจอแบบ HP-05 · อยู่ใน meeting ด้วยมี tab Spotlight / Meeting |
| 13 | ใครเริ่ม Spotlight ได้ — ทุกคน · สถานะ Busy / Away / DND ปุ่ม Start spotlight disabled แบบ web ใช่ไหม | ✅ **ใช่** — ทุกคนเริ่มได้ · Busy / Away / DND ปุ่ม Start spotlight disabled |
| 14 | **แนวนอนตาม §18.6** ได้ไหม (ยึดหน้า Meeting แนวนอน HP-04 · More เป็น modal กลางจอ · เข้าจาก megaphone) | ✅ **ได้** — แนวนอนตาม §18.6 |

### 18.8 ผลต่อเอกสารอื่น (อัปเดตแล้ว 2026-10-01 หลังคำตอบ §18.7)

- spec.md: OQ 33 (ปิด) · technical-design **§16.9 ใหม่** Spotlight บนมือถือ (Lite เริ่มโดยไม่ตรวจตำแหน่ง · ghost เดินไป marker · Spatial auto-walk · ขั้น live)
- task-breakdown 0.47–0.51 · screens.md D แถว Spotlight stage + G แถว Spotlight (ดู/เริ่ม) แก้สถานะ · clickup-spec §18 ข้อ 76–83
- UI ที่ต้องขอ design: chip LIVE + รายชื่อผู้ชม · แนวนอนทั้งหน้า (§18.6) · sheet ยืนยัน Stop broadcasting · หน้าคนดู (แถบปุ่มชุดคนดู)

### 18.9 HP-11 v2 — Figma อัปเดต 2026-10-05 · Ten ตอบ "ตามแนะนำ" ทุกข้อ

**Node:** แนวตั้ง section `6710-161801` (3 แถว: presenter · Spotlight - Meeting · Spotlight - Not in meeting) · **แนวนอนมีใน Figma แล้ว** section `6927-66368` (3 แถวเหมือนกัน) → **§18.1, §18.2, §18.6 เป็นเวอร์ชันเก่า** · §19.4 (ตัวนับ Mic / Eye) ถูกแทนด้วยข้อ 1 ด้านล่าง · รายละเอียดทุก frame อยู่ §18.10

#### 18.9.1 ระบบทำงานยังไง (ตาม Figma ใหม่ + มติ)

| flow | ขั้นตอน |
|---|---|
| **คนเริ่ม · แนวตั้ง (Lite)** | ปุ่ม megaphone 42×42 บน Lite Home → sheet ยืนยัน **"Start Spotlight"** ("Share what you’re doing with others in the workspace." · Cancel / Start spotlight) → **นับถอยหลัง 5→1 บน Lite Home** (toast "Spotlight will be started within N seconds" + Stop · ใช้ "1 second" ตอนเหลือ 1) → เปิดหน้า Spotlight **live แล้ว** + toast "Spotlight started now" 3 วิ · **ไม่มีปุ่ม Play / Stop ในแถบ** · พื้นที่เต็ม → sheet **"Spotlight is full"** |
| **คนเริ่ม · แนวนอน (Spatial)** | **เดินเข้าจุด Spotlight เอง** (sticky) **หรือกด megaphone ให้เดินไปเอง** (คงมติ §18.7 ข้อ 4) → หน้า Spotlight → นับถอยหลัง**บนหน้า Spotlight** → "Spotlight started now" |
| **ออก (คนเริ่ม)** | Leave → sheet **"Leave Spotlight?"** ("You’ll stop sharing with everyone in the workspace." · Cancel / **Leave สีเขียวตาม Figma**) → กลับหน้าเดิม + toast **"Broadcast ended"** · คนดูได้ toast เดียวกันและหน้าคนดู / PIP ปิดเอง |
| **More** (ทั้ง 2 แนว ใช้ชุดแนวตั้ง) | **Emoji · Chat · Setting · Invite** มีชื่อกำกับ · ไม่มี Start/Stop และ raise hand · **Invite = Invite sheet แท็บ Chat** (ส่งลิงก์ชวนดู) · ปุ่ม speaker / share / raise hand ในแถบเป็น toggle ค้างจนกดซ้ำ (sticky) |
| **คนดูไม่อยู่ใน meeting** | toast **"<ชื่อ> · Spotlight is starting"** มี × / ✓ + แถบนับ **10 วิ** · ✓ = เปิดหน้าคนดู (Chat · Speaker ┃ Leave) · × หรือครบเวลา = ปิด toast · **ไม่เปิดหน้าให้เองแล้ว** (แก้ §18.7 ข้อ 1) · ข้อเสนอ: แถว **"Spotlight · Live"** บนสุดของ Lite Home ไว้กดดูทีหลัง 🎨 · ลูกศรลง = PIP Spotlight 168×158 |
| **คนดูอยู่ใน meeting** | toast เดียวกันทับหน้า meeting · **✓ = ทั้งห้องเข้าดู** (zyra-ws `handleSpotlightMeetingJoin` ให้สมาชิกคนใดก็ได้รับแทนห้อง) → หน้าคนดู + แถบรายชื่อคนในห้อง (แนวตั้งล่าง / แนวนอนซ้าย) + เมนู **Undo · Chat · Speaker ┃ Leave** · **Undo = ทั้งห้องเลิกดู** (`ws:spotlight:meetingLeave`) กลับหน้า meeting · **ลูกศรลง = ย่อเฉพาะเครื่องเรา** → หน้า meeting + PIP Spotlight (แตะ PIP กลับ Spotlight — sticky) · ย่อทั้งคู่บน Home / แมพ = PIP รวม 168×100 "Spotlight \| Meeting" · แถบล่างบนแมพคุมแค่ meeting ของตัวเอง (sticky) · แชทมีแท็บ Spotlight / Meeting |
| **Header** | ป้าย **Live** แดง + **ชิปเดียว `Users` "N \| M"** (ซ้าย = คนบนเวที · ขวา = คนดู) แตะ → sheet 2 แท็บ On stage / Viewers (§19.5 คงเดิม เพราะ Figma ยังไม่มี frame) · ภาพ Figma ที่ขึ้น "1" ทั้งที่มี 2 คนบนเวที = ข้อมูลตัวอย่างผิด |
| **กล้อง** | เปิดกล้อง = tile สี่เหลี่ยมรูปจริง + กรอบเขียว · ปิด = avatar วงกลม (sticky) |

#### 18.9.2 คำตอบ (Ten 2026-10-05 "ตามแนะนำ" · ข้อ 10–11 ถามเพิ่มหลังทำ prototype)

| # | คำถาม | คำตอบ |
|---|---|---|
| 1 | ชิป "1 \| 50" แทน Mic / Eye | ✅ ยึด Figma · ซ้าย = บนเวที ขวา = คนดู · แตะ = sheet 2 แท็บ (§19.5) |
| 2 | คนดูนอก meeting ได้ toast แทนเปิดเอง | ✅ ✓ เปิด · × / 10 วิ ปิด · เพิ่มแถว "Spotlight · Live" บน Lite Home (ข้อเสนอให้ Pai วาด) |
| 3 | ✓ ใน meeting ใช้กับใคร | ✅ ทั้งห้อง (ตาม zyra-ws) · Undo = ทั้งห้องเลิกดู · ลูกศรลง = ย่อเฉพาะเครื่อง |
| 4 | ทางเริ่มแนวนอน | ✅ ได้ทั้งเดินเข้าจุดเองและกด megaphone ให้เดินไป · นับถอยหลังบนหน้า Spotlight |
| 5 | More ไม่เหมือนกัน 2 แนว | ✅ ใช้ชุดแนวตั้ง Emoji · Chat · Setting · Invite · หยุดด้วย Leave อย่างเดียว · Invite = Invite sheet แท็บ Chat |
| 6 | Leave สีเขียว | ✅ ยึด Figma · จดเป็นข้อสังเกตให้ Pai |
| 7 | "Spotlight is full" เมื่อไร | ✅ ทุกจุด Spotlight บนชั้นมีคนพูดแล้ว · Lite ได้จุดว่างจุดแรก ไม่มีจุดว่าง = sheet นี้ · **ต้องแก้ zyra-ws** (task 0.54) |
| 8 | คนดูได้ "Broadcast ended" ไหม | ✅ ได้ · หน้าคนดู / PIP ปิดเอง |
| 9 | Figma ขัดกันเอง | ✅ ส่ง Pai แก้ (ด้านล่าง) · ระหว่างนี้ยึดแนวตั้ง |
| 10 | คนดูที่อยู่ใน meeting กด **Leave** | ✅ **ออกจากทั้ง Spotlight และ meeting แล้วกลับ Home** (เหมือน Leave ในแถบ meeting) · Undo = ทั้งห้องเลิกดูกลับ meeting (ข้อ 3) |
| 11 | PIP Spotlight / PIP รวม บนแมพทับตำแหน่ง minimap | ✅ **ยึด Figma: ซ่อน minimap ระหว่างมี PIP Spotlight หรือ PIP รวม** (มุมขวาล่าง `right 30 bottom 16`) · PIP meeting อย่างเดียวยังอยู่เหนือ minimap ตามมติ HP-04 §8.6 ข้อ 9 |

#### 18.9.3 ส่งให้ Pai แก้ใน Figma

- ข้อความ "within **1 seconds**" → "1 second"
- ชื่อ layer ผิด เช่น sheet "Spotlight is full" ชื่อ "Chat - Message not sent" · หลาย frame ชื่อ "Spotlight - Meeting" ทั้งที่อยู่แถว Not in meeting
- แถวแนวนอน Not in meeting: แถบล่างบนแมพ 2 แบบไม่เหมือนกัน
- ปุ่มสลับกล้องมีแค่แนวตั้ง · ปุ่ม speaker บน header คนดูมีแค่แนวนอน · More แนวนอนยังมี Start/Stop + raise hand
- ชิปตัวนับในภาพเขียน "1" ทั้งที่มี 2 คนบนเวที
- ปุ่ม Leave ใน "Leave Spotlight?" เป็นสีเขียว (ปุ่มที่หยุดออกอากาศมักใช้สีแดง) — ยืนยันอีกครั้ง
- ยังไม่มี frame: sheet รายชื่อ On stage / Viewers · แถว "Spotlight · Live" บน Lite Home

### 18.10 รายละเอียดทุก frame ของ HP-11 v2 (ดึงด้วย `get_metadata` + `get_design_context` 2026-10-05)

> ค่าที่อ่านไม่ได้เขียนไว้ว่า "not read" · ภาพทุก frame เก็บระหว่างทำงาน (ไม่ได้ commit)

#### 0. Section layout

Both sections have the same title bars ("Title Flow" instances):

| Title bar text (verbatim) | A node / y | B node / y |
|---|---|---|
| `HP-11 · Mobile Responsive — Spotlight (Presenter + Viewer)` (green bar) | `6710:161802` y435 | `6927:66369` y435 |
| `Spotlight - Meeting` (purple bar) | `6894:106623` y3224 | `6927:66370` y3224 |
| `Spotlight - Not in meeting` (purple bar) | `6927:62224` y6013 | `6927:66371` y4869 |

Sticky notes (shape-with-text, light-blue `#C9E6FF`-ish fill (colour not read)). The text below is copied exactly. Line breaks follow the render.

| Node | Section / where | Text (verbatim) |
|---|---|---|
| `6927:66237` | A · row 1b, under the standalone Meeting Menu `6927:66240` | • Speaker phone<br>• Share screen<br>• Raise hand<br>เป็นปุ่ม Active เสมอถ้ามีการทำ Action จนกว่าจะมีการกดซ้ำอีกครั้งเพื่อยกเลิก |
| `6927:64058` | A · row 2, left of the viewer page `6927:62116` | ใน Meeting<br>• เปิดกล้อง 4 เหลี่ยม<br>• ไม่ได้เปิดกล้อง เป็นรูปโปรไฟล์วงกลม |
| `6894:1063503` | A · row 2, left of the Meeting + Spotlight PIP frame `6894:1063494` | กดที่ PIP กลับมาที่ Spotlight |
| `6934:74316` | B · row 1, left of the first frame `6929:69982` | เดินเข้าจุด Spotlight |
| `6934:73447` | B · row 2, left of the map + combined PIP frame `6927:66453` | Bottom bar ใช้ได้กับแค่ Meeting ตนเองเท่านั้น ไม่ยุ่งเกี่ยวกับ Spotlight |

---

#### 1. Shared components (full spec once, referenced below as **[C-x]**)

Typography tokens used: Body/Medium = Inter 500 14/18 · Body/Regular = Inter 400 14/18 · Sub/Regular = Inter 400 16/22 · Sub/Bold = Inter 700 16/22 · Caption 1/Regular = Inter 400 12/15 ls −0.43 · Caption 2/Semi = Inter 600 10/13 ls −0.43 · Caption 2/Medium = Inter 500 10/14.

##### [C-1] Spotlight header ("Meeting Title", type=Spotlight, main comp `6716:215158`)
- Portrait: `left 50% (centred) top 24 w 358` · Landscape: `top 16 w 780` centred. Row with gap 16.
- **Left** (flex-1, gap 8):
  - chevron-down button: bg `rgba(255,255,255,0.05)` p 8 radius 8, icon 16.
  - `Spotlight` Body/Medium white, ellipsis.
  - **Live pill**: bg `#F03A3A` (Red/500), radius 90, px 4 py 2, text `Live` Caption 2/Semi 10/13 white. The text is "Live", not "LIVE".
- **Right** (gap 8):
  - **Counter chip** ("Icon Button"): bg white 5%, radius 8, px 8 py 4, gap 4, full height of the row. Icon `member` (users) 16, then `1` (Body/Regular 14/18 white, w 25 centred), then a vertical divider 16 px, then `50` (same style, w 25). **The chip has one icon only. Neither number is labelled.**
  - Optional **camera switch** button (icon `Reset` = rotate arrows, 16, bg white 5% p 8 r 8). Component prop `showCamaraSwitch`. It is on only in the portrait cam-on frame `6894:1062712`.
  - **Speaker** button (icon `Unmute` 16, bg white 5% p 8 r 8). Present on the presenter pages (portrait and landscape) and on the landscape viewer pages. **Absent on the portrait viewer pages** (`6927:62116`, `6927:63574`).
- No chat button, lock, user-plus or Play button in the header.

##### [C-2] Display tile ("Display" / "Meeting Display")
- Container: portrait `left 16 top 96 w 358`. Height 636 (presenter, not-in-meeting viewer) or 545 (in-meeting viewer, which leaves room for the carousel). Flex column, gap 16, centred.
- Tile: bg `rgba(255,255,255,0.05)`, radius 12, p 4, justify-end.
  - 1 person, portrait: h 338 (presenter).
  - 2 people, portrait: two tiles flex-1 stacked, gap 16.
- Avatar: circle with a per-user colour bg (`#FFA8A8`, `#E1ADFF`, `#7EA2FC`, `#95F7F6`, `#C4FCB6`, `#FFCEA8`). Its top and bottom are inset 32.5%, so its height is 35% of the tile (≈118 px in a 338 tile). Aspect 1:1, centred. *(§18.2 said "avatar 56"; that is not what the frame shows.)*
- Name tag (bottom-left): bg `#000000` + backdrop-blur 4, radius 8, px 6 py 4, gap 4. It holds `Mic-off` 14 (red) when the mic is off, then the name in Caption 1/Regular white.
- **Cam on** (`6894:1062712`, `6932:70369`): tile gets **border 2 px `#58D68D`** and `overflow-clip`. The photo fills the tile (object-cover). The name tag sits at bottom 3 / left 3 and drops the mic icon (mic on).
- Landscape, presenter alone: tile `w 358 h 238`, centred, `top 64`.
- Landscape, 2 viewers: two tiles side by side (from screenshot `6934:74010`, dimensions **(not read)**).
- Landscape, in-meeting viewer: 2×3 grid (see [C-8]).

##### [C-3] Meeting Menu (bottom bar)
Base for every variant: bg `#232427`, radius 16, p 8, `bottom 16`, centred. Buttons are `Element of bottom bar` (p 8, radius 8, icon 24). Divider: vertical line, full height.

| Variant | Node | Width | Buttons left → right |
|---|---|---|---|
| Presenter, portrait | inside `6947:499229` / `6894:1062712` | 358, justify-between | cam (Video-off red-slash / Video-on white) · mic (Mic-off red-slash / Mic-on white) · share screen · **⋮ more** · ┃ · **leave** (bg `rgba(212,24,24,0.2)` icon red) |
| Presenter, landscape | `6927:66448` | **304**, justify-between | same as portrait |
| Viewer in meeting (portrait + landscape) | `6894:1062993` / `6927:66429` | hug, gap 8 | **Undo** (↶) · Chat · Speaker (Unmute) · ┃ · leave |
| Viewer not in meeting (portrait) | `6927:63432` | hug, gap 8 | Chat · Speaker · ┃ · leave |
| Viewer not in meeting (landscape) | in `6934:74010` | (not read) | Chat · Speaker · ┃ · leave (from screenshot) |
| Standalone illustration (A row 1b) | `6927:66240` | 312, justify-between | cam off · mic off · **share screen ACTIVE bg `#2C5AE4` (Navy/500)** · ┃ · emoji · **raise hand ACTIVE bg `#ECC819` (Yellow/500)** · ┃ · leave. Goes with sticky `6927:66237` (toggle buttons stay active until pressed again). This is the regular *meeting* bar (emoji and hand are in it), not a spotlight bar. |

**There is no Play/Stop button in any spotlight menu.**

##### [C-4] Text notification bottom (bottom toast)
- bg `rgba(0,0,0,0.7)` + backdrop-blur 4, radius 8, py 4, gap 8. Text Body/Regular 14/18 white.
- **Countdown with Stop** (`6947:498292`, `6947:498760`, `6931:70174`, `6932:70269`): pl 8 pr 4.
  - Text `Spotlight will be started within N seconds`.
  - Stop button: **h 32, px 16, py 8, radius 6**, bg white 5%, border 1 white 20%, `Stop` Body/Regular.
  - Instance box: portrait `x 13.5 y 724 w 357 h 44` (frame 4: `x 14.5 w 355`). Landscape `x 244 y 266 w 357 h 44`.
- **Info only** (px 8):
  - `Spotlight started now`: `6932:70364` landscape `x 343 y 266 w 159 h 44`. Portrait `6947:499230` is the same size, `x 112.5 y 724`; I read its copy from the screenshot and did not query its spec.
  - `Broadcast ended`: `6947:539268`, portrait `x 127.5 y 724 w 129 h 44`.
- Portrait position: y 724 with h 44, so its bottom edge is at 768. The Meeting Menu starts at 844−16−56 = 772, leaving a 4 px gap. Landscape: bottom edge at 310, Menu top at 318, an 8 px gap.

##### [C-5] Bottom sheet - Modal (confirm / info sheet, main comp `6934:75586`)
- bg `#232427`, radius top 24 (portrait), p 16, gap 40, items centred. `×` close (`Cancel` 16) absolute at `left 358 top 16`. No grabber.
- Content (gap 16): grey circle 80 (`Ellipse15` placeholder illustration, exact fill **(not read)**, renders light grey). Then a text block (gap 8): title Body/Medium white and description Body/Regular `#8C99A6` centred.
- Button row (gap 8, each flex-1, h 42, px 16, py 8, radius 8, gap 8, icon 16, label Sub/Regular 16/22 white):
  - Secondary: bg white 5%, border 1 white 20%.
  - Primary: bg `#58D68D`.
- Overlay behind it: `bg rgba(0,0,0,0.5)` + backdrop-blur 6, full frame.

| Use | Node | Size / pos | Title | Description | Buttons |
|---|---|---|---|---|---|
| Start confirm (Lite) | `6947:491954` | `y 572 w 390 h 272` | `Start Spotlight` | `Share what you’re doing with others in the workspace.` (2 lines: "…with others in" / "the workspace.") | `×` Cancel · **▷ Start spotlight** (primary) |
| Spotlight full (error) | `6934:75697` (frame named `Chat - Message not sent`) | `y 572 w 388 h 272` | `Spotlight is full` | `All Spotlight areas are currently in use.` / `Please try again later.` | **Done** (primary, full width, no icon) |
| Leave confirm (presenter live) | `6947:501099` | `y 590 w 388 h 254` | `Leave Spotlight?` | `You’ll stop sharing with everyone in the workspace.` | `×` Cancel · **⇥ Leave** (primary **green** `#58D68D`, not red) |

##### [C-6] Bottom sheet - Spotlight (More menu)
**Portrait** (`6716:214633`, in frame `6716:204281` at `y 588 w 390 h 256`):
- bg `#232427`, radius top 24, pt 40, px 16, pb 16, gap 16. Grabber 34×4 white 20%, radius 90, `top 8`, centred.
- Tiles are `Element of Tap`: bg white 5%, radius 8, p 8, gap 8, h 56, flex-1, icon 16. The 3 rows are gap 16:
  - Row 1, icon-only: **Speaker (Unmute)** · **Share screen** · **Raise hand (Hand)**
  - Row 2, labelled: **😊 `Emoji`** · **💬 `Chat`**
  - Row 3, labelled: **⚙ `Setting`** · **👤+ `Invite`** (user-plus)
- **No Start/Stop spotlight row.**

**Landscape** (`6933:70689` symbol, `6933:70693` instance, both at `x 227 y 63 w 390 h 264`): centred modal.
- bg `#232427`, **radius 16 (all corners)**, pt 48, px 16, pb 16, gap 16. `×` 16 absolute `right 16 top 16`. No grabber.
- Row 1: full-width tile h 56: `▷ Start spotlight` (`6932:70478`) or `☐ Stop spotlight` (`6933:70690`, square icon). Copy for the Stop variant is from the screenshot; that instance was not queried.
- Row 2, icon-only: Speaker · Share screen · Raise hand.
- Row 3, icon-only: Setting · Emoji · Chat.
- **No Invite. No labels.**
- Overlay `rgba(0,0,0,0.5)` + blur 6.

##### [C-7] Notification toast "Spotlight is starting" (shown to viewers)
Nodes: `6894:106858` / `6927:62228` portrait, `6934:74132` landscape.
- bg `#1A1B1E`, radius 8, pt 8, px 8, **pb 11**, gap 8, overflow-clip.
- Shadow `0 4 16 rgba(255,255,255,0.08)` in portrait. **The landscape instance has no shadow.**
- Avatar 32 circle with a status dot (inset −12.5%), then a text column (gap 4):
  - Name: Body/Medium white, ellipsis (`Eric`, or landscape `Dechawat Phondechaphiphat` truncated to "Dechawat Phondecha…").
  - Second line: Caption 1 with `Spotlight` in white and ` is starting` in `#8C99A6`.
- Buttons (gap 8, p 8, radius 6, icon 16): **×** on bg white · **✓** on bg `#58D68D`.
- **Progress bar** at the bottom: h 2, track white 20%, radius 90, fill gradient `#58D68D → #8FE4B3`. The fill shows 40% (inset right 60%), which reads as a countdown timer. Its duration is **not stated**.
- Positions:
  - Portrait over the Meeting page: `x 16 y 64 w 358 h 56` (just under the header).
  - Portrait over Lite Home: `x 16 y 16 w 358 h 56` (covers the Home header).
  - Landscape over the Meeting page: `x 269 y 16 w 298 h 56`.
  - Landscape over the map: inside instance `6934:73450`, position **(not read)**, visually top-centre.

##### [C-8] Participants carousel (in-meeting viewer)
**Portrait** (`6894:1062970`):
- w 390, pt 8, radius top 16, gap 16. Vertical centre at `50% + 288.5` (≈ y 710).
- Track: px 16, gap 16, horizontal, overflow-clip.
- Each item: w 64, gap 6. A 56 Display or avatar, then the name in Caption 1/Regular white, centred, ellipsis (`Conan Gr…`).
  - Cam on: **square**, radius 12, photo (`Matthew`).
  - Cam off: **circle** avatar with colour bg (matches sticky `6927:64058`).
  - Mic-off badge: bg `#F03A3A`, border 1 `#242B32`, radius 90, bottom-right quarter (`Elin`, `Ivy`).
  - Presence status dot (`Eric`).
- Page indicators: 3 dots of 6 px, gap 6, centred (first active, green).
- Items: Matthew (cam) · Conan Grey · Elin (mic off) · Ivy (mic off) · Eric (5th, clipped).
- **These are the user's meeting members (Meeting Hall), not the stage.**

**Landscape** (`6927:66430`): a vertical strip **on the left**.
- `left 32 top 65 w 101 h 317`, py 16, gap 16, radius 16. Same items.
- No dots. The bottom item is clipped.
- The stage grid sits to its right: `left 16.67%+24.33 (≈165) top 64 w 647`, gap 24 to the menu.
  - Grid h 238: 2 rows (gap 16) × 3 tiles (flex-1, gap 16).
  - Tiles: Dechawat Phondechaphiphat · Conan Grey · Eric / Taylor · Nishida · Alice.
- Pager arrows `6927:66416` (`right 16 top 171 w 679`, justify-between):
  - ‹ and › buttons: w 26, p 4, radius 4, bg white 5%, border 1 white 20%.
  - Icons Cheron-Left / Cheron-Right 16.

##### [C-9] PIPs
- **Spotlight PIP (single)**, `Display` 168×158 portrait/landscape (`6894:1063495`, `6927:64050`, `6934:74308`) or 117×110 landscape-in-meeting (`6929:69805`):
  - bg `#232427`, **border 2 `#58D68D`**, radius 12, p 4.
  - Avatar 35% height, centred. Name tag `Spotlight`.
  - Positions:
    - Portrait: `x 203 y 606` (right 19, bottom 80; sits above the Lite bottom bar, or above the Meeting Menu on the Meeting page).
    - Landscape over the map: `x 646 y 216` (right 30, bottom 16).
    - Landscape over the Meeting page: `x 695 y 264 w 117 h 110` (right 32, bottom 16).
- **Spotlight & Meeting PIP (combined)** `6934:73303`, 168×100:
  - Outer: bg `rgba(255,255,255,0.15)`, p 2, radius 16.
  - Two halves, each flex-1, bg `#232427`, p 4. Left half: radius 16/0/0/16 with a 1 px right border white 20%. Right half: radius 0/16/16/0.
  - Each half: avatar 35% centred and a name tag (`Spotlight` | `Meeting`).
  - **No green border.**
  - Positions: portrait over Lite Home `x 203 y 664` (bottom 80). Landscape over the map `x 646 y 274` (right 30, bottom 16).
- Sticky `6894:1063503`: tapping the PIP goes back to Spotlight.

##### [C-10] Meeting chat
**`6947:539897`, with tabs:**
- Title bar `top 24 w 358`:
  - hidden chevron-left (opacity 0).
  - `Meeting chat`: Sub/Bold 16/22 white, centred.
  - `×` button: bg white 5%, p 8, r 8.
- Body: `top 72 h 772`, radius 16.
- **Tab fill** (px 16):
  - Container: border 1 white 20%, radius 8, p 4.
  - Two tabs h 32, flex-1, p 8. Active tab bg `rgba(88,214,141,0.2)`.
  - Labels: `Spotlight` (active) and `Meeting`, plus a count badge `1` (bg `#D41818`, radius 90, Caption 2/Medium 10/14, w 16).
- Empty state above the input: two 16 px avatars (border 1 white, overlap −4) and the line `Eric and Elon participated`. "and" and "participated" are `#8C99A6`; the names are white.
- Input bar:
  - Container: px 16, pt 8, pb 16, gap 8, gradient `#1A1B1E → transparent` (upwards), blur 6.
  - Attach button 42 (bg `#232427` r 8).
  - Input h 42 (bg `#232427` r 8 px 12): emoji 16 + `Message` placeholder in `#636D76`.
  - Mic button 42.

**`6947:539901`, no tabs:** same layout without the Tab fill. The empty state reads `Matthew and Conan Grey participated`. There is no annotation saying when this version (no tabs) is shown. The two names are the Meeting Hall members.

##### [C-11] Lite Homepage start button (`6710:161803`, Home `I…;5944:272015`)
- **Icon-only 42×42 button**: bg white 5%, border 1 white 20%, radius 8, p 8. The icon is a **megaphone** (layer `Plus`, asset `imgSpotlightOn`) at 16 px.
- Sits left of the green `Instant meeting` button (flex-1, h 42, bg `#58D68D`, icon Video-on 16, Sub/Regular 16/22).
- Row top 85, gap 8. There is no "Start spotlight" text label.

---

#### 2. Section A — portrait 390×844

##### Row 1 — main presenter flow (y 936)

| # | Node | Name | What it shows | Copy (verbatim) | Notes / states |
|---|---|---|---|---|---|
| 1 | `6710:161803` | Homepage | Lite Home (Starlight Workspace) with the megaphone button **[C-11]** | `Starlight Workspace` · `100 Members` · `50 Online` · `Instant meeting` · `Search for members or meeting rooms` · `In meeting` · `Meeting hall 01` · `Meeting room • 70 participants` · `Xspace room` · `Locked` · `Meeting room • 10 participants` · `Circle` · `Online (50)` · list (Dechawat Phondechaphiphat / Active, Conan Grey / Busy, Taylor / 🚧 I’m doing my stuff, Eric / 🚨 If have any urgent CALL ME, Nishida / Active • In meeting, RAYE / Active, Olivia / Active • In meeting) · `Offline (5)` | Bottom bar: Home (active), Chat badge `10`, Calendar, Profile. Bell badge `10`. |
| 2 | `6947:491953` | Spotlight | Home + overlay + **Start confirm sheet [C-5]** | `Start Spotlight` · `Share what you’re doing with others in the workspace.` · `Cancel` · `Start spotlight` | New confirm step |
| 3 | `6947:497817` | Spotlight | **Still on Home**, countdown toast [C-4] | `Spotlight will be started within 5 seconds` · `Stop` | The countdown runs on Home, before the Spotlight page opens |
| 4 | `6947:498300` | Spotlight | Home, countdown toast | `Spotlight will be started within 1 seconds` | The copy says **"1 seconds"** (not 4). Grammar left as in Figma. |
| 5 | `6947:499228` | Spotlight | **Spotlight page, live**: header [C-1] (Live + `1 \| 50` + speaker), single tile `Matthew` (mic off, avatar), presenter menu [C-3], toast | `Spotlight` · `Live` · `1` · `50` · `Matthew` · `Spotlight started now` | Cam off, mic off |
| 6 | `6894:1062712` | Instant Meeting (instance) | Same page, **cam on + mic on**: green 2 px border, photo; header gains the camera-switch button | `Spotlight` · `Live` · `1` · `50` · `Matthew` | No toast |
| 7 | `6947:501017` | Spotlight | Page (cam off) + toast under overlay + **Leave confirm [C-5]** | `Leave Spotlight?` · `You’ll stop sharing with everyone in the workspace.` · `Cancel` · `Leave` | Leave button is green |
| 8 | `6947:501139` | Spotlight | Back on Lite Home + toast | `Broadcast ended` | End state after leaving |

##### Row 1b (y 2080, sub-states)

| # | Node | Name | What it shows | Copy | Notes |
|---|---|---|---|---|---|
| 1b-1 | `6934:74790` | Chat - Message not sent *(layer name is wrong; the content is Spotlight)* | Home + overlay + **"Spotlight is full" sheet** [C-5]. Placed under frame 2 = the error branch of the Start confirm | `Spotlight is full` · `All Spotlight areas are currently in use.` · `Please try again later.` · `Done` | New |
| 1b-2 | `6927:66240` + sticky `6927:66237` | Meeting Menu (standalone) | Toggle-state illustration [C-3]: share = blue `#2C5AE4`, hand = yellow `#ECC819` | (sticky text in §0) | This is the normal meeting bar, not a spotlight bar |
| 1b-3 | `6716:204281` | Spotlight - More menu | Live page + **portrait More sheet [C-6]** (no overlay layer in this frame) | `Emoji` · `Chat` · `Setting` · `Invite` | No Start/Stop spotlight row |

##### Row 2 — "Spotlight - Meeting" (viewer who is in a meeting) (y 3725)

| # | Node | Name | What it shows | Copy | Notes |
|---|---|---|---|---|---|
| 1 | `6894:106649` | Spotlight - Meeting | HP-04 Meeting page + **Notification toast [C-7]** at y 64 | Meeting header `Meeting Hall` (buttons: chevron · lock · user · chat · speaker) · tiles `Matthew`, `Conan Grey` (mic off) · toast `Eric` / `Spotlight is starting` | Meeting menu: cam off · mic off · share ┃ emoji · hand ┃ leave |
| — | sticky `6927:64058` | — | Note for the carousel in frame 2 | (§0) | |
| 2 | `6927:62116` (symbol) | Spotlight - Meeting | **Viewer Spotlight page**: header [C-1] (Live + `1 \| 50`, **no speaker**), 2 stage tiles (h 545 container) `Eric`, `Elon` (mic off), **carousel [C-8]**, menu Undo · Chat · Speaker ┃ Leave | `Spotlight` · `Live` · `1` · `50` · `Eric` · `Elon` · `Matthew` · `Conan Grey` · `Elin` · `Ivy` · `Eric` | 2 people on stage, but the chip still shows `1` |
| — | sticky `6894:1063503` | — | Note for frame 3 | `กดที่ PIP กลับมาที่ Spotlight` | |
| 3 | `6894:1063494` | Spotlight - Meeting | Meeting page (no toast) + **Spotlight PIP 168×158 [C-9]** at `x 203 y 606`, overlapping the Conan Grey tile | `Meeting Hall` · `Matthew` · `Conan Grey` · `Spotlight` | Result of using chevron-down / Undo on the Spotlight page (inferred from placement; no arrow present) |
| 4 | `6894:1063968` | PIP | Lite Home + **combined PIP 168×100 [C-9]** at `x 203 y 664` | `Spotlight` · `Meeting` | Both minimised. Chat tab badge is absent in this frame's bottom bar. |

##### Row 2b (y 4869)

| # | Node | What it shows | Copy |
|---|---|---|---|
| 2b-1 | `6947:539901` (instance) | Meeting chat **without tabs** [C-10] | `Meeting chat` · `Matthew and Conan Grey participated` · `Message` |
| 2b-2 | `6947:539897` (symbol) | Meeting chat **with tabs Spotlight / Meeting(1)** [C-10] | `Meeting chat` · `Spotlight` · `Meeting` · `1` · `Eric and Elon participated` · `Message` |

##### Row 3 — "Spotlight - Not in meeting" (y 6514)

| # | Node | Name | What it shows | Copy | Notes |
|---|---|---|---|---|---|
| 1 | `6927:62226` | Spotlight - Meeting *(layer name)* | Lite Home + **Notification toast [C-7]** at `y 16` (covers the Home header) | `Eric` · `Spotlight is starting` | Viewer gets ✓ / × with a progress bar. **The page does not open automatically.** |
| 2 | `6927:63574` (symbol) | Spotlight | **Viewer page**: header [C-1] (Live + `1 \| 50`, no speaker), 2 tiles in a 636 container (`Eric`, `Elon`), menu **Chat · Speaker ┃ Leave** | `Spotlight` · `Live` · `1` · `50` · `Eric` · `Elon` | No carousel, no Undo |
| 3 | `6927:63575` | Spotlight - Meeting *(layer name)* | Lite Home + **single Spotlight PIP 168×158** at `x 203 y 606` (green border) | `Spotlight` | |

---

#### 3. Section B — landscape 844×390

##### Row 1 — presenter (y 936)

| # | Node | What it shows | Copy | Notes |
|---|---|---|---|---|
| — | sticky `6934:74316` | Entry note | `เดินเข้าจุด Spotlight` | Landscape entry = walk into the spotlight spot (no Start confirm sheet, no countdown on the map) |
| 1 | `6929:69982` (symbol) | Spotlight page: header [C-1] (`left 32 top 16 w 780`, **Live already shown**, `1 \| 50`, speaker), tile 358×238 `top 64` centred (avatar, mic off), presenter menu w 304 | `Spotlight` · `Live` · `1` · `50` · `Dechawat Phondechaphiphat` | No toast. The header shows Live **before** the countdown frames. |
| 2 | `6931:70173` | Same + countdown toast `x 244 y 266` | `Spotlight will be started within 5 seconds` · `Stop` | Countdown runs **on the Spotlight page** (portrait runs it on Home) |
| 3 | `6932:70182` | Same, toast | `Spotlight will be started within 4 seconds` · `Stop` | |
| 4 | `6932:70277` | Same, toast `x 343 y 266 w 159` overlapping the name tag | `Spotlight started now` | |
| 5 | `6932:70369` (instance) | Cam on + mic on: green border, photo; **no camera-switch button** in the header | `Dechawat Phondechaphiphat` | |

##### Row 1b (y 1626)

| # | Node | What it shows | Copy |
|---|---|---|---|
| 1b-1 | `6932:70478` | Page + overlay + **landscape More modal [C-6]** with `Start spotlight` | `Start spotlight` |
| 1b-2 | `6933:70690` | Same modal with `Stop spotlight` (square icon) | `Stop spotlight` |

##### Row 1c (y 2157)

| # | Node | What it shows | Notes |
|---|---|---|---|
| 1c-1 | `6947:539958` | "Spotlight - Meeting - PIP": Spatial map (instance `Worksapce - Horizon`) with **combined PIP** `x 646 y 274`. Map HUD visible: weather, **megaphone**, calendar, people, bell (top-right); chat bubble (bottom-left); joystick ring; meeting bar (avatar · cam off · mic off · share ┃ emoji · hand ┃ leave). | Sits in the presenter row; it is the same frame type as B row 2 #4. **No arrow or note explains why the presenter has a combined Spotlight/Meeting PIP.** |

##### Row 2 — "Spotlight - Meeting" (y 3725)

| # | Node | What it shows | Copy | Notes |
|---|---|---|---|---|
| 1 | `6934:74131` | Landscape Meeting page (header `Meeting Hall` + lock/user/chat/speaker; 2 tiles; meeting menu) + **Notification toast** `x 269 y 16 w 298` (no shadow) | `Dechawat Phondechaphiphat` (truncated) · `Spotlight is starting` · `Conan Grey` | |
| 2 | `6934:73200` (symbol) | **Viewer page**: header (Live, `1 \| 50`, **speaker present**), **left participant strip [C-8]**, 2×3 stage grid with ‹ › arrows, menu Undo · Chat · Speaker ┃ Leave | `Matthew` · `Conan Grey` · `Elin` · `Ivy` · `Eric` · `Dechawat Phondechaphiphat` · `Taylor` · `Nishida` · `Alice` | |
| 3 | `6934:73301` | Meeting page + **Spotlight PIP 117×110** `x 695 y 264` | `Spotlight` | |
| — | sticky `6934:73447` | | `Bottom bar ใช้ได้กับแค่ Meeting ตนเองเท่านั้น ไม่ยุ่งเกี่ยวกับ Spotlight` | |
| 4 | `6927:66453` | Map + meeting bar + **combined PIP** `x 646 y 274` | `Spotlight` · `Meeting` | |

##### Row 3 — "Spotlight - Not in meeting" (y 5370)

| # | Node | What it shows | Copy | Notes |
|---|---|---|---|---|
| 1 | `6934:73450` (instance `Worksapce - Horizon`) | Map + **Notification toast** top-centre. Bottom HUD bar: avatar · cam off · mic off ┃ leave(?) (red icon). **Minimap** bottom-right. | `Dechawat Phondecha…` · `Spotlight is starting` | Inner positions **(not read)**; this is a single instance |
| 2 | `6934:74010` (instance) | Viewer page: header (Live, `1 \| 50`, speaker), 2 tiles side by side, menu **Chat · Speaker ┃ Leave** | `Dechawat Phondechaphiphat` · `Conan Grey` | Dimensions **(not read)** |
| 3 | `6934:74179` | Map + **Spotlight PIP 168×158** `x 646 y 216` | `Spotlight` | ⚠ The map bar in this frame is the **meeting** bar (cam · mic · share ┃ emoji · hand ┃ leave). Frame 1 of the same row shows a different bar (avatar · cam · mic ┃ leave + minimap). The design looks inconsistent here, or it was copied from row 2. |

---

## 19. รอบโน้ต Pai บน mockup ทั้งชุด (2026-10-02 · Ten ตอบครบ)

**ที่มา:** Pai (UX/UI) เขียน sticky note บน mockup [mobile-ui-proposals](https://zyra-mobile-ui-proposals.vercel.app) ทีละ card · Ten ตอบคำถามแต่ละข้อในแชท 2026-10-02 · card 02, 03 อยู่ §8.8 · card 06 อยู่ §9.8 · หัวข้อนี้รวม card ที่เหลือ · **ยังไม่มี frame ใน Figma** (ยกเว้น 19.3 ที่ Pai ชี้ Figma เดิม) ค่าเป็นข้อเสนอจาก mockup 🎨

### 19.1 New group (card 05 · HP-05 §9.6 ข้อ 1/9)

| เรื่อง | spec |
|---|---|
| Header | "New group" **จัดกลาง** · ปุ่ม back ซ้าย |
| รูป + ชื่อ | avatar (icon `Camera`) แล้วช่อง Group name ต่อลงมา **เรียงแนวตั้งจัดกลาง** · **ไม่มี label/title เหนือช่อง** (ใช้ placeholder "Group name") |
| ค้นหา | placeholder **"Search for member"** (เดิม "Add members") |
| คนที่เลือก | **ไม่มีแท็กชื่อ (chip)** · คนที่ติ๊กแล้วขึ้นไปอยู่**บนสุดของรายชื่อ** · แตะทั้งแถวติ๊ก checkbox |
| ปุ่ม | **"Create group (N)"** นับจำนวนคนที่เลือก (Ten ตกลง) |

### 19.2 Notification แนวนอน (card 07 · HP-06 §10.6 ข้อ 4)

| เรื่อง | spec |
|---|---|
| รูปแบบ | **drawer เลื่อนจากขวาไปซ้าย** · กว้าง **390** · **สูงเต็มจอ** · ชิดขอบขวา · มุมซ้ายมน 16 |
| ปิด | แตะพื้นที่ทางซ้าย (overlay มืดทับแมพ) · ปุ่ม × ยังมี |
| แถวแท็บ | All / Unread ซ้าย · **Mark all as read แถวเดียวกัน ชิดขวาสุด** · แถวบนเหลือ "Notifications" + × |
| ใช้กับ | Workspace lists / member list แนวนอนใช้ drawer รูปแบบเดียวกัน (ข้อเสนอ) |

### 19.3 Notification settings — สวิตช์เดียวต่อแถว (card 09 · HP-08 §12.5 ข้อ 2, 8)

**Pai ชี้ Figma:** `5889-432902` (Profile → Setting → Notification) และ `6436-67120` (หน้า Notification) · Ten: **"ถ้ามี Push / In-app มันดูงงมากสำหรับผู้ใช้"** → เลือกแบบ ก

| เรื่อง | spec (จาก `get_design_context` 6436-66903) |
|---|---|
| แถว | p 12 radius 8 gap 16 · ชื่อ Body/Regular 14/18 ขาว (บางแถว Medium) + คำอธิบาย 14/18 `#8C99A6` gap 8 · **สวิตช์เดียว 48×24** ขวาสุด (component Switch Medium · on `#58D68D`) |
| กลุ่ม | หัวข้อ Caption 1 12/15 `#8C99A6` p 8 · การ์ด bg `#232427` radius 16 p 8 |
| ความหมายสวิตช์ | สวิตช์ของแต่ละประเภท = **push** ของประเภทนั้น · เสียง/แจ้งเตือนในแอปรายประเภท (`enable_*_sounds`) ตั้งบนเว็บ · **ยกเลิกมติ §12.5 ข้อ 2 ส่วน "2 สวิตช์ต่อแถว"** |
| กลุ่มตาม Figma | Chat (Messages · Mentions · Thread) · Meeting & Circle (Meeting · Circle · Knock · Raised hands · Mic & Camera requests · Screen sharing) · Calendar (5 แถว — **ซ่อน** ตาม §10.6 ข้อ 7) · Pet (Pet activity) · Activities (Waves) |
| 4 แถวใหม่ (§12.5 ข้อ 8) | เป็นพฤติกรรมในแอป ไม่มี push คู่ · สวิตช์เดียวเหมือนกัน · ข้อความเสนอ: **Hide chat during meetings** "Hide the chat panel while you're in a meeting." · **Mute chat sounds in meetings** "Silence chat sounds while you're in a meeting." (กลุ่ม Meeting & Circle) · **Pet sounds** "Play sounds from pets on the map." (กลุ่ม Pet) · **Environment sounds** "Play weather and nature sounds on the map." (กลุ่ม Environment ใหม่) |

### 19.4 หน้า Spotlight ฝั่งคนดู (card 11 · HP-11 §18.7 ข้อ 1, 8, 9) — ⚠️ **ตัวนับ Mic / Eye ถูกแทนด้วยชิป "N | M" ตาม Figma v2 (§18.9)** · bottom menu คนดูยังเป็น Chat · Speaker · Leave (+ Undo เมื่ออยู่ใน meeting)

| เรื่อง | spec |
|---|---|
| Header | chevron-down · "Spotlight" + ป้าย **"LIVE"** (ไม่มีตัวเลข) · **ขวาสุด 2 ตัวนับ: `Mic` N (คนบนเวที) · `Eye` N (คนดู)** แตะ → sheet รายชื่อกลุ่มนั้น · ปุ่ม chat / speaker บน header ย้ายลงล่าง |
| Bottom menu | **Chat · Speaker · Leave** เท่านั้น · **ตัด emoji และ raise hand ของคนดู** (Ten "ตามแนะนำ") — แก้ §18.7 ข้อ 8 ที่เคยให้ raise hand เป็นของคนดู |
| แทน | chip "LIVE · N" เดิมของ §18.7 ข้อ 9 |

### 19.5 รายชื่อใน Spotlight (card 12)

| เรื่อง | spec |
|---|---|
| รูปแบบ | **sheet เดียว 2 แท็บ: On stage (N) / Viewers (N)** · แตะ `Mic` เปิดแท็บ On stage · แตะ `Eye` เปิดแท็บ Viewers · แท็บ Viewers มีช่องค้นหา |
| คำขอ | Spotlight **ไม่มี Request เข้า** (ไม่มี Requesting list) |
| แถวคนดู | ไม่มีอะไรท้ายแถว (ตัด ✋ / "Watching") |
| แถวคนบนเวที | ไอคอน `Mic` / `MicOff` **แสดงสถานะอย่างเดียว กดไม่ได้** · **เห็นเฉพาะคนบนเวทีด้วยกัน** คนดูไม่เห็น |
| backend | ไม่ต้องแก้ — zyra-ws spotlight ไม่มีคำสั่งปิดไมค์คนอื่น (มีแค่ `ws:spotlight:start` / `stop` / `stateUpdate` / `meetingJoin` / `meetingLeave`) และปิดไมค์ = หยุดออกอากาศ (`internal/hub/spotlight.go:179`) |

### 19.6 หน้าที่ใช้ได้บน desktop เท่านั้น (card 14 · EC-01)

| เรื่อง | spec |
|---|---|
| เมนู | **ซ่อนบนมือถือ**: Workspace editor ในเมนู ⋮ ของการ์ด workspace (`workspace-card.tsx:129-197`) · ทางเข้า admin / map editor / object-management |
| เปิด URL ตรง | **ไม่มีหน้า "Open this on a desktop" / QR** · พาไป **Space builder** ทันที + toast **"This page is available on desktop only."** |
| ผล | ไม่ต้องเพิ่ม QR library (clickup-spec §18 ข้อ 20 ตัด) · ⚠️ **ต่างจาก ClickUp EC-01** ที่ขอหน้า banner + QR → แจ้ง PM |

### 19.7 ฟีเจอร์ที่ยังไม่มี (card 16)

**ซ่อนทั้งหมด ไม่มี Coming soon** — Tarot widget · Participation Dashboard · Quiz / Poll · AI Meeting Summary · Meeting alert (เหมือน Calendar) · เหตุผลเสริม: Apple Guideline 2.1 (App Completeness) ปฏิเสธแอปที่มีปุ่ม/หน้า placeholder ได้ · ⚠️ **เปลี่ยนมติข้อ 4 ในเอกสาร PM** ("กดแล้วขึ้น Coming soon") → แจ้ง PM

### 19.8 เมนู Performance (card 22 · EP-01 §15.6 ข้อ 6, §15.7)

**ตัดเมนู Performance ออก · ระบบปรับเองอย่างเดียว (Auto)** — ladder L1–L4 และ toast ขาลง/ขาขึ้น (§15, card 21) คงเดิม · ไม่ใช้ localStorage `zyra_perf_mode` · ⚠️ **ต่างจาก ClickUp EP-01** ที่ขอ "Mobile Performance Mode" toggle → แจ้ง PM

### 19.9 ที่ต้องแจ้ง PM (ต่างจาก ClickUp หรือมติเดิมในเอกสาร PM)

| เรื่อง | เดิม | ใหม่ |
|---|---|---|
| EC-01 desktop-only | หน้า banner + QR + copy link | ซ่อนเมนู · เปิด URL ตรง → Space builder + toast |
| EP-01 Performance Mode | toggle ใน Settings | ไม่มีเมนู ปรับเองอย่างเดียว |
| ฟีเจอร์ที่ยังไม่มี | กดแล้วขึ้น Coming soon (เอกสาร PM ข้อ 4) | ซ่อน |
| HP-11 viewer count | chip LIVE · N | ป้าย LIVE + ตัวนับ Mic / Eye แยก |
| HP-08 สวิตช์ | 2 สวิตช์ต่อแถว (in-app + push) | สวิตช์เดียว = push |

## 20. ลบบัญชีในแอป — spec (ข้อเสนอ 2026-10-05 · ✅ Ten ตอบ "ตามแนะนำ" ครบ 7 ข้อ · 🎨 รอ Pai วาด)

**ทำไมต้องมี:** Apple App Store Review Guideline **5.1.1(v)** — แอปที่ให้สมัครสมาชิกได้ต้องมีทางลบบัญชี**ในแอป** ไม่ใช่แค่ส่งเมลหรือลิงก์เว็บ · ไม่มี = โดน reject ตอนส่ง store (open-items §4 · เอกสาร PM ข้อ 1) · **ยังไม่มีใน Figma**

### 20.1 ของที่มีอยู่แล้วในโค้ด

| ของ | ที่อยู่ | ผลต่อมือถือ |
|---|---|---|
| ลบบัญชีฝั่ง admin | `zyra-api internal/service/user_admin_service.go:1046` `DeleteAccount` + handler `user_admin_lifecycle_handler.go:167` | **ใช้ logic เดิมได้เกือบหมด**: soft-delete (`deleted_at`, `account_status='deleted'`) · แปลงอีเมลเป็น hash `…@hashed-anonymized.net` · โอน workspace ที่เป็นเจ้าของให้ Admin / member ที่อยู่นานที่สุด · ไม่มีสมาชิกอื่น = workspace ไม่มีเจ้าของ (`owner_id` NULL) · bump `token_version` = ออกจากระบบทุกเครื่อง · บันทึก audit · ยืนยันด้วยการพิมพ์อีเมลให้ตรง |
| ข้อจำกัด | `ErrCannotActOnSelf` — admin ลบบัญชีตัวเองไม่ได้ · route อยู่ใต้ `/api/admin/*` | ต้องเพิ่ม route ใหม่ใต้ `/api/user/*` (rule 15 ห้าม member เรียก admin) ที่เรียก service เดิมโดยให้ actor = ตัวเอง |
| ชื่อผู้ใช้ | service เดิม**ไม่เปลี่ยน username** (FK `tb_authen.username`) | ข้อความเก่าในแชท / รายชื่อ ยังโชว์ชื่อเดิม ถ้าไม่จัดการฝั่ง API (ดู §20.5 ข้อ 5) |

### 20.2 Flow ที่เสนอ (มือถือ + เว็บใช้ร่วมกัน)

```
Profile → Account and Security → [Delete account] (แถวสีแดงล่างสุด)
  → หน้า "Delete account"
      - อธิบายผล: ออกจากทุก workspace · ข้อมูลส่วนตัวถูกลบ · กู้คืนไม่ได้
      - รายการ workspace ที่เราเป็นเจ้าของ + จะโอนให้ใคร / ไม่มีสมาชิกอื่น = ถูกลบ
      - ช่องพิมพ์อีเมลของเราเพื่อยืนยัน
      - ปุ่ม "Delete my account" (danger) · ปุ่มกดได้เมื่ออีเมลตรง
  → loading → ออกจากระบบ → หน้า Get started + toast "Your account has been deleted."
```

### 20.3 Spec หน้า (ข้อเสนอ — ใช้ component เดิม)

| ส่วน | spec |
|---|---|
| ทางเข้า | Profile → Setting → **Account and Security** → แถว **Delete account** (icon `Trash2` + ข้อความ `#F03A3A`) อยู่การ์ดแยกล่างสุด |
| หน้า | Title menu back + "Delete account" กลาง · ซ่อน bottom nav (หน้าลูก §10) |
| คำเตือน | alert banner สีแดง (bg `rgba(240,58,58,0.05)` border `rgba(240,58,58,0.2)`) icon `TriangleAlert`: "This can't be undone." |
| ผลที่จะเกิด | รายการ 3 ข้อ Body 14/18 `#8C99A6`: "You'll leave every workspace." · "Your profile, email and settings will be removed." · "Messages you sent stay, shown as Deleted user." |
| workspace ที่เป็นเจ้าของ | การ์ด bg `#232427` radius 16 แต่ละแถว: ชื่อ workspace + "Ownership moves to <ชื่อ>" หรือ "No other members — this workspace will be deleted" (แดง) · ซ่อนการ์ดถ้าไม่ได้เป็นเจ้าของ |
| ยืนยัน | label "Type your email to confirm" + input 42 · ปุ่ม **Delete my account** danger เต็มกว้าง h 42 · disabled จนกว่าอีเมลตรง (ไม่สนตัวพิมพ์เล็กใหญ่) |
| หลังลบ | เรียก native: ลบ push token ของเครื่อง · ล้าง session (`clearSession`) · ไป Get started + toast |
| error | เน็ตหลุด → toast + คงอยู่หน้าเดิม · อีเมลไม่ตรง (server) → ข้อความใต้ช่อง |

### 20.4 Backend ที่ต้องเพิ่ม (zyra-api)

- `DELETE /api/user/me` (UserGuard) body `{ "confirm_email": "…" }` → service เดิมแบบ self-delete (แยก method `DeleteOwnAccount` ไม่แตะ guard `ErrCannotActOnSelf` ของ admin) · response `model.APIResponse` + `workspaces_transferred` / `workspaces_deleted`
- `GET /api/user/me/deletion-preview` → รายการ workspace ที่เป็นเจ้าของ + ผู้รับโอน (ใช้แสดงในหน้า)
- workspace ที่ไม่มีสมาชิกอื่น → **ลบ workspace** ใน transaction เดียวกัน (ต่างจาก admin เดิมที่ตั้ง `owner_id` NULL — แยก behaviour ใน method self-delete)
- API ที่คืนข้อมูลผู้ใช้ (แชท, member list, notification) แสดง **"Deleted user" + avatar ว่าง** เมื่อ `account_status='deleted'`
- ลบ device token ของ user (`tb_user_device`, task 2.1) ใน transaction เดียวกัน
- **Sign in with Apple:** Apple กำหนดให้แอปที่ใช้ SIWA ต้อง **revoke token** ผ่าน Apple REST API ตอนลบบัญชี → เก็บ refresh token ของ Apple ตอน login (task 1.5) แล้วเรียก revoke ตอนลบ
- table-driven test ครบทุก sentinel error (rule 04)

### 20.5 คำถาม — ✅ Ten ตอบ "ตามแนะนำ" ทุกข้อ (2026-10-05)

| # | คำถาม | คำตอบ (= ที่แนะนำ) |
|---|---|---|
| 1 | ลบจริงทั้งแถว หรือ soft-delete + ลบข้อมูลส่วนตัว | **soft-delete + anonymize ตาม service admin เดิม** มี audit อยู่แล้ว และข้อมูลแชทของคนอื่นไม่พัง · Apple ยอมรับแบบนี้ถ้าข้อมูลส่วนตัวถูกลบจริง |
| 2 | workspace ที่ไม่มีสมาชิกอื่น | **ลบ workspace นั้นทิ้ง** แทนการปล่อยไม่มีเจ้าของ (โค้ด admin ตอนนี้ตั้ง `owner_id` NULL) · แสดงเตือนในหน้าก่อนกด |
| 3 | ยืนยันด้วยอะไร | **พิมพ์อีเมล** ใช้ guard เดิม · คน login ด้วย Google / Apple ก็รู้อีเมลตัวเอง |
| 4 | ลบทันที หรือมีช่วงรอ (เช่น 30 วันกู้คืนได้) | **ลบทันที** ตามโค้ดเดิม · ง่ายกว่าและ Apple ไม่บังคับให้มีช่วงรอ |
| 5 | ข้อความเก่า / ชื่อในรายชื่อ | **API คืนชื่อ "Deleted user" + avatar ว่าง** เมื่อ `account_status='deleted'` ทุกจุดที่แสดงชื่อ (แชท, member list, notification) |
| 6 | ทำบนเว็บด้วยไหม | **ทำ** ใช้หน้าเดียวกัน (codebase เดียว) |
| 7 | Sign in with Apple revoke token | **ทำตามที่ Apple บังคับ** ผูกกับ task 1.5 |

### 20.6 ลบบัญชีโดยไม่กระทบคนอื่น + ใครลบได้ (Ten ตอบ "ตามแนะนำ" 2026-10-05)

**ปัญหาที่เจอในโค้ดเดิม:** `DeleteAccount` (`user_admin_service.go:1046`) แตะแค่ `tb_user`, `tb_authen`, `tb_workspace` (โอนเจ้าของ) และ `tb_user_status_history` · **ยังไม่ลบ `tb_workspace_member` และ `tb_conversation_member`** → บัญชีที่ลบแล้วยังโผล่ในรายชื่อสมาชิก และกลุ่มแชทอาจเหลือแบบไม่มี admin

**ขั้นตอนเก็บกวาดที่ต้องเพิ่ม** (ใน transaction เดียวกัน · ใช้ร่วมกันทั้ง user ลบเองและ admin ลบ — แยกเป็น helper เดียว)

| ของ | ทำอะไร | ผลต่อคนอื่น |
|---|---|---|
| workspace ที่เป็นเจ้าของ | โอนให้ Admin / สมาชิกที่อยู่นานที่สุด (มีแล้ว) · ไม่มีสมาชิกอื่น = ลบ workspace | workspace ใช้ต่อได้ |
| `tb_workspace_member` | ลบทุกแถวของ user | ไม่โผล่ในรายชื่อสมาชิก |
| `tb_conversation_member` | ลบทุกแถว · ถ้าเป็น admin คนเดียวของกลุ่ม / channel → ตั้งสมาชิกที่อยู่นานที่สุดเป็น admin แทน | กลุ่มยังมีคนดูแล |
| ข้อความเก่า | เก็บไว้ · API แสดง "Deleted user" + avatar ว่าง | ประวัติแชทไม่หาย |
| DM กับคนอื่น | อีกฝ่ายอ่านได้ · ช่องพิมพ์ปิด แสดง "This account has been deleted" · API ปฏิเสธการส่งข้อความหาบัญชีที่ถูกลบ | ไม่ส่งข้อความเข้าหาบัญชีที่ไม่มีแล้ว |
| private zone ที่จอง · สัตว์เลี้ยง | ปล่อยคืน / ยกเลิกการเป็นเจ้าของ | คนอื่นใช้ zone ต่อได้ |
| meeting / Spotlight ที่อยู่ตอนลบ | token ถูกยกเลิก → หลุดทันที · host ย้ายตาม `ws:meeting:ownerUpdate` เดิม · ถ้ากำลัง Spotlight → จบการออกอากาศ | meeting ไม่สะดุด |
| ลิงก์เชิญที่เคยสร้าง | เก็บไว้ (เป็นของ workspace) | ลิงก์ยังใช้ได้ |
| push token ของทุกเครื่อง | ลบ (`tb_user_device`) | — |

**ใครลบบัญชีได้**

| ใคร | ทำได้ | ที่อยู่ |
|---|---|---|
| ผู้ใช้เอง | ลบบัญชีตัวเอง (บังคับทั้ง Apple 5.1.1(v) และ Google Play) | ใหม่ §20.2–20.4 · `DELETE /api/user/me` |
| admin ของระบบ (ทีม Zyra) | ลบบัญชีใครก็ได้ยกเว้นตัวเอง พิมพ์อีเมลยืนยัน — ใช้ตอนผู้ใช้ขอตาม PDPA, เข้าแอปไม่ได้, บัญชีทำผิดกฎ | มีแล้ว `user_admin_lifecycle_handler.go` · ต้องใช้ helper เก็บกวาดชุดเดียวกัน |
| Owner / Admin ของ workspace | **ลบบัญชีไม่ได้** · ทำได้แค่ Remove member ออกจาก workspace | มีแล้ว `workspace_member_handler.go` (DELETE members) |

**Google Play:** ต้องกรอก **ลิงก์เว็บสำหรับขอลบบัญชี** ใน Play Console (Data safety / Account deletion) → ใช้หน้า Delete account บนเว็บ (§20.5 ข้อ 6) เป็นลิงก์นั้น · ถ้ายังไม่ login ให้ login ก่อนแล้วพาไปหน้านี้

## 21. Session หมดอายุ / บังคับอัปเดตแอป / ปิดปรับปรุง — spec (ข้อเสนอ 2026-10-05 · ✅ Ten ตอบ "ตามแนะนำ" ครบ 7 ข้อ · 🎨 รอ Pai วาด)

**ที่มา:** เจอตอนไล่ UI ที่ขาด (ยังไม่อยู่ใน Figma / ClickUp) · ต้องมีตั้งแต่ปล่อยเวอร์ชันแรก

### 21.1 Session หมดอายุ / ถูกออกจากระบบ — **เว็บมีครบแล้ว ใช้ต่อได้**

| กรณี | เว็บตอนนี้ | บนมือถือ (เสนอ) |
|---|---|---|
| token หมดอายุ (refresh ไม่ผ่าน) | `lib/api/client.ts:27` toast **"Session expired — please log in again"** → `/login?redirect_url=…` | toast เดิม → หน้า **Get started** (แทน `/login`) · login แล้วกลับหน้าเดิมด้วย `redirect_url` |
| ถูกออกจากระบบจากที่อื่น (`session revoked` — เช่น ลบบัญชี §20, admin ระงับ) | `/signed-out` = `views/login/hero-session-ended.tsx`: **"You've been signed out"** · "Your session on this device has ended." · "Sign in again to continue using Zyra World." · ปุ่ม **Back to Login** | หน้าเดิมแบบเต็มจอแนวตั้ง · ปุ่มพาไป Get started · ลบ push token ของเครื่อง |
| เปลี่ยนรหัสผ่านจากอีกเครื่อง (`password change`) | `components/auth-guard.tsx:160-190` dialog **"Password changed"** · "Your password has been changed from another device" · "Please log in again to continue" · ปุ่ม **Log in again** | dialog เดิมกลางจอ (กว้างสุด 360) · ปุ่มพาไป Get started |
| ระหว่างอยู่ใน meeting / Spotlight | — | ออกจาก LiveKit + ws ก่อน แล้วค่อยแสดงตามกรณีข้างบน (ไม่ค้างจอ meeting) |

### 21.2 บังคับอัปเดตแอป (ใหม่ทั้งหมด)

**ทำไมต้องมี:** แอปใช้ Capacitor แบบ remote URL (TD) → **โค้ดเว็บอัปเดตเองทุกครั้งที่ deploy** แต่ **ตัวแอป native (plugin: push, sign-in, share ฯลฯ) อัปเดตผ่าน store เท่านั้น** · ถ้าเว็บใหม่เรียก plugin ที่แอปเก่าไม่มี แอปจะพัง → ต้องเช็คเวอร์ชันแอปเทียบกับขั้นต่ำ

| ส่วน | spec (เสนอ) |
|---|---|
| ค่าตั้ง | zyra-api `GET /api/app/config` (public) → `{ ios: { min_version, latest_version, store_url }, android: { … } }` อ่านจาก runtime env (แก้ผ่าน ESO secret ได้โดยไม่ต้อง deploy ใหม่ — rule 06) |
| เช็คเมื่อไร | เปิดแอป (หลัง Splash) และตอนกลับจาก background · อ่านเวอร์ชันแอปจาก `@capacitor/app` `App.getInfo()` · ไม่เช็คบน mobile web |
| ต่ำกว่า `min_version` | **หน้า "Update required" เต็มจอ ปิดไม่ได้**: logo · "Update required" · "This version of Zyra World is no longer supported. Update to keep using the app." · ปุ่ม **Update now** (เปิด store) |
| ต่ำกว่า `latest_version` แต่ ≥ min | **sheet "Update available"** ครั้งเดียวต่อวัน: "A new version of Zyra World is ready." · ปุ่ม Update / Later |
| ดึงค่าไม่ได้ (offline) | ข้ามการเช็ค ไม่บล็อกผู้ใช้ |

### 21.3 ปิดปรับปรุง (maintenance) — **เว็บมีแล้ว**

เว็บ: `proxy.ts` เช็ค flag จาก backend ทุก 5 วิ แล้ว redirect ไป `/maintenance` (`views/maintenance/hero-maintenance.tsx`): **"Zyra World is under maintenance"** · "We're making improvements to provide a better experience. Please try again later." · ปุ่ม Back to Homepage · มี bypass cookie สำหรับทีม

บนมือถือ (เสนอ): หน้าเดิมแบบเต็มจอแนวตั้ง · **เปลี่ยนปุ่มเป็น "Try again"** (โหลดใหม่ — ในแอปไม่มี Homepage) · ระหว่าง maintenance ไม่ขึ้นหน้า offline / reconnecting ของ HP-10 ซ้อน

### 21.4 คำถาม — ✅ Ten ตอบ "ตามแนะนำ" ทุกข้อ (2026-10-05)

| # | คำถาม | คำตอบ (= ที่แนะนำ) |
|---|---|---|
| 1 | session หมดอายุ / ถูกออก / เปลี่ยนรหัส บนมือถือ | **ใช้ 3 แบบเดิมของเว็บ** แค่พาไป Get started แทน `/login` · ให้ Pai วาดหน้า "You've been signed out" แบบมือถือ |
| 2 | ระหว่างอยู่ใน meeting แล้ว session หลุด | **ออกจาก meeting / Spotlight ก่อน** แล้วค่อยแสดงหน้า |
| 3 | เก็บค่าเวอร์ชันขั้นต่ำที่ไหน | **zyra-api `GET /api/app/config` อ่านจาก env** แก้ได้ทันทีโดยไม่ต้อง build ใหม่ |
| 4 | มีแบบ "Update available" (ไม่บังคับ) ด้วยไหม | **มี** ขึ้นวันละครั้ง กด Later ได้ |
| 5 | ดึงค่าไม่ได้ตอน offline | **ไม่บล็อก** ข้ามไปก่อน |
| 6 | หน้า maintenance บนมือถือ | **ใช้หน้าเดิม** เปลี่ยนปุ่มเป็น "Try again" |
| 7 | ติดตั้ง PWA บน Android | **เพิ่มแบบ Android** ใช้ปุ่ม Install ของ Chrome (`beforeinstallprompt`) ใน sheet "Meet Zyra on mobile" แทนขั้นตอน Add to Home Screen ของ iOS |

## 22. UI ที่ตกหล่นรอบ 2 + มติ 4 เรื่องที่ค้าง (2026-10-05 · Ten ตอบ "ตามแนะนำ")

### 22.1 เมนู FAB ในหน้า Chat (Figma `5944-134262` อัปเดต)

แตะ FAB `+` → overlay `rgba(0,0,0,0.5)` blur 6 ทั้งจอ · FAB หมุน 45° เป็น × (ปิด) · เมนูชิดขวาเหนือ FAB 8 px gap 16 ไม่มีพื้นหลัง: **Create channel** (`hash` 24) · **Create group** (`users` 24) · **Start a new chat** (`send` 24) ตัวหนังสือ Sub/Regular 16/22 ขาว · Create channel → หน้า New channel · Create group → หน้า New group (§19.1) · Start a new chat → panel เดิม · **เลิกใช้ sheet "Create chat" (Group / Channel)** ที่เสนอไว้ตาม Figma เวอร์ชันก่อน (มีแค่ 2 ข้อ)

### 22.2 มติ 4 เรื่องที่ค้าง

| เรื่อง | มติ |
|---|---|
| **สมัคร / OTP / ลืมรหัสผ่าน** | ใช้ขั้นตอนเดิมของเว็บ (`views/signup`, `views/verify`, `views/reset-password`) เปลี่ยนแค่ layout มือถือ · หน้าข้อเสนอใน prototype เป็นจุดเริ่มให้ Pai วาด |
| **Lite: แตะคนในรายชื่อ** | sheet โปรไฟล์: avatar · ชื่อ · สถานะ · ปุ่ม **Message** (เปิด DM) + **Wave** · ถ้าคนนั้นอยู่ในห้องประชุม มีปุ่ม **Join** (เปิด Join meeting sheet ของห้องนั้น) · **ไม่มี Follow ใน Lite** (มีเฉพาะ Spatial เพราะ Lite ไม่มีตำแหน่ง) |
| **Lite: แตะ Circle** | sheet **"Join Circle"** layout เดียวกับ Join meeting (ตาม sticky HP-04 "ถ้าเป็น Circle ก็เปลี่ยน Join meeting > Join Circle") · คน Lite เข้า Circle ด้วย id → **ต้องเพิ่ม zyra-ws "join circle by id"** สำหรับ ghost (คู่กับ join meeting by id TD §16.2) |
| **เปิดลิงก์เชิญ / deep link** | ยังไม่ login → Get started → login แล้วไปต่อที่ลิงก์ · ยังไม่เป็นสมาชิก → **หน้ารับคำเชิญ** (ใช้ `/join/{token}` เดิม: โลโก้ + "You're invited to join <workspace>" + คนเชิญ + Accept / Decline) → Select mode · workspace ถูกลบ / ไม่มีสิทธิ์ → **หน้า "This link is no longer available"** ("The workspace may have been deleted or you don't have access.") + ปุ่ม Go to Space builder · เปิดจากเว็บในเครื่องที่ไม่มีแอป → mobile web + smart banner "Open in Zyra app" |

### 22.3 UI ที่ตกหล่น (ข้อเสนอ — ยังไม่มีใน Figma 🎨)

| UI | spec (ข้อเสนอ) |
|---|---|
| **หน้าแก้โปรไฟล์** (ลูกศรบนการ์ดสถานะใน Profile §10) | avatar + เปลี่ยนรูป (sheet: Take photo / Choose from library / Remove — รูปขึ้น S3 ตาม rule 11) · Display name · Custom status · ปุ่ม Save กดได้เมื่อมีการแก้ · toast "Profile updated" · ใช้ API profile เดิม |
| **หน้าเลือกตัวละคร** (ปุ่ม Change character ใน Lobby §3.6 และในหน้าแก้โปรไฟล์) | preview ตัวละครด้านบน · grid 3 คอลัมน์ (tablet 5) · เลือกแล้วกรอบเขียว · Save · ใช้ `/api/user/avatars` + `lib/avatar-selection.ts` เดิม (rule 15) |
| **error ตอน login** | อีเมลหรือรหัสผิด → ข้อความแดงใต้ช่อง "Incorrect email or password." · อีเมลยังไม่ยืนยัน → sheet "Verify your email" ("We sent a code to <email>.") + Enter code (→ OTP) / Resend · กด cancel ตอนเลือกบัญชี Google / Apple → ไม่มี error อยู่หน้าเดิม · เน็ตหลุด → toast "Can't connect. Check your internet and try again." |
| **หน้าว่าง** | รายการแชท "No conversations yet" + "Start a chat with your team." + ปุ่ม Start a new chat · Notification "You're all caught up" · ค้นหาไม่เจอ (แชท / สมาชิก / workspace) "No results for "<คำค้น>"" · Threads Messages "No threads yet" · icon lucide ในวง 56 bg white 5% |

### 22.4 iPad

Ten แจ้ง 2026-10-05: บางหน้าใน prototype บน iPad ไม่เต็มจอ / ดูแปลก ทั้งแนวตั้งและแนวนอน → ไล่แก้ใน prototype ตามกติกา §17 (fluid เต็มกว้าง ขอบ 24 · หน้าก่อนเข้า workspace คอลัมน์กลาง ~480 · sheet กว้างสุด 600 กลางจอ · modal คงความกว้างกลางจอ · meeting grid 3×3 · HUD Spatial ยึดขอบ · drawer 390 สูงเต็ม)

**แก้แล้ว 2026-10-05:** แถบมืดข้างคอลัมน์ 480 (ทาพื้นเต็มจอ) · Space builder / template เต็มจอตามกติกาใหม่ใน §17 ข้อ 7 · Spotlight viewer แนวนอน avatar ใหญ่เกิน + toast ทับแถบปุ่ม · grid meeting แถวสุดท้ายไม่เต็มให้จัดกลาง

## 24. Mobile web = UI เดียวกับแอป + desktop แนวตั้งใช้ UI มือถือ (2026-10-05 · Ten "ตามแนะนำ")

**มติ:** responsive mobile web ใช้หน้าตาและขั้นตอน**เหมือนแอปทุกหน้า** (ทุก spec ใน §3–§23 ใช้กับ mobile web ด้วย) ต่างกันเฉพาะส่วนที่เป็นความสามารถ native ซึ่งบนเว็บใช้แบบเว็บแทนหรือซ่อน:

| ความสามารถ native | บน mobile web |
|---|---|
| push notification (§12) | ไม่มี push · ใช้ notification ในแอปเดิม · ไม่ขอสิทธิ์ตอน Splash |
| login Google / Apple แบบ native (§11) | ใช้ sign-in บนเว็บ (Google implicit flow เดิม / Sign in with Apple JS) |
| haptics · badge ไอคอน | ไม่มี |
| เสียงประชุมตอนสลับแอป (background audio) | ไม่รองรับ · ใช้ banner เตือนบน iOS Safari เดิม |
| แชร์จอ (§8) | tooltip "Screen sharing is only available in your browser." ตามเดิม (desktop browser แชร์ได้) |
| share sheet | คัดลอกลิงก์ |
| บังคับอัปเดตแอป (§21.2) | ไม่เช็ค |

**desktop browser:**

| หน้าต่าง | UI |
|---|---|
| แนวตั้ง (สูง > กว้าง) | **UI มือถือ · Lite เสมอ** · ข้ามหน้า Select workspace mode · ไม่มีหน้า Rotate (หมุนเครื่องไม่ได้) |
| แนวนอน แต่กว้าง < 768 | UI มือถือ Lite เหมือนกัน (แทนหน้า "Mobile unsupported" เดิม) |
| แนวนอน กว้าง ≥ 768 | **UI desktop เดิม** (ไม่ใช่ Spatial มือถือ เพราะใช้เมาส์) |
| ย่อ / ขยายระหว่างใช้ | สลับทันทีหลังขนาดนิ่ง 300 ms · ห้องประชุมไม่หลุด · การเดินบนแมพหยุดตอนเป็น Lite · ไม่สลับระหว่างพิมพ์ |

กติกาเต็มใน technical-design §16.8 · ใช้ร่วมกับ §17 (EC-03): จอสัมผัสด้านยาว ≤ 1366 ยังเป็นมือถือเหมือนเดิม และ laptop จอสัมผัสด้านยาว > 1366 ยังเป็น desktop ถ้าหน้าต่างเป็นแนวนอน
