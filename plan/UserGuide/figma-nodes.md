# Figma Nodes — User Guide Module

**File:** `Map8gX0L2hk7HnkaFRfhtj`
**Base URL:** `https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-`
**Date fetched:** 2026-07-14 (ผ่าน Figma MCP: `get_metadata`, `get_design_context`, `get_screenshot`)

---

## Quick Index

| Scenario | Section Node ID | Section Name |
|---|---|---|
| SC-UG-01 | `2286:623285` | Onboarding Flow — สร้าง Workspace ครั้งแรก (กดครบทุก Step) |
| SC-UG-02 | `2329:27226` | Onboarding Flow — ข้าม (Skip All) |
| SC-UG-03 | `2329:30521` | Onboarding Flow — กลับมาทำต่อ (Resume) |
| SC-UG-04 (V.1) | `2144:22099` | Help Center — เปิดและค้นหาบทความ |
| SC-UG-04 (V.2) | `2207:145327` | Help Center — เปิดและค้นหาบทความ **V.2 แบบมีรูป** ← ใช้ตัวนี้เป็นหลัก |
| SC-UG-05 | `2156:558556` | Help Center — ไม่พบบทความที่ค้นหา |
| SC-UG-06 | `2207:238216` | Tooltip / Walkthrough — แนะนำ Feature ใหม่ (ตัวอย่าง: Virtual Pets) |
| SC-UG-07 | `2156:568237` | Contact Support — ส่ง Feedback / Bug Report |
| SC-UG-08 | `2186:16834` | Contact Support — ติดต่อทีม Support โดยตรง + Email Templates |

---

## SC-UG-01 — Onboarding screens (8 screens)

| # | Frame | Modal node | Tab / Step | Progress |
|---|---|---|---|---|
| 1 | `2291:93995` | `2291:639507` Welcome | Welcome active | 0% |
| 2 | `2291:639508` | `2291:640130` Office Setup | 1/3 "Create & Choose Theme" | 33% |
| 3 | `2291:639891` | `2291:640131` | 2/3 "Review Details & Preview" | 33% |
| 4 | `2291:640240` | `2291:640243` | 3/3 "Name & Create Workspace" | 33% |
| 5 | `2291:640855` | `2291:641480` Invite Team | 1/2 "Access Invite Menu" | 67% |
| 6 | `2291:641481` | `2291:641484` | 2/2 "Choose Invite Method" | 67% |
| 7 | `2291:641710` | `2291:642056` How to Play | "Walk & Talk Naturally" | 100% |
| 8 | `2291:642554` | `2291:642980` **Success Modal** 458×332 | "You're All Set!" | — |

Sticky notes สำคัญ:
- `2291:649922` — "ทันทีที่ Login สำเร็จครั้งแรก ให้ขึ้น Modal ทันที"
- `2291:643782` — ตัวอย่าง animation เปลี่ยน page: https://gemini.google.com/share/6c3cd8e9d3e9
- `2322:26228` / `2322:26232` — behaviour notes ของ flow สร้าง workspace / invite team จริง

## SC-UG-02 — Skip All (4 frames)

| # | Frame | เนื้อหา |
|---|---|---|
| 1 | `2329:27232` | Welcome modal (เหมือน SC-UG-01 screen 1) → กด Skip |
| 2 | `2329:27240` | + overlay ชั้นที่สอง + **skip-confirmation modal** `2329:27245` (458×332) |
| 3a | `2329:27254` | Yes, Skip → Space Builder + **spotlight overlay** `2329:27256` (เจาะรู 214×70 ที่ปุ่ม Create workspace, x=1196 y=98) + coach-mark tooltip `2329:27259` (ขาว 300×46, x=884 y=110) |
| 3b | `2329:27236` | Cancel → กลับ tutorial modal เดิม |

Sticky: "เมื่อกด Skip ให้ขึ้น Modal แจ้งเตือน" / "กด Yes Skip ให้ปิด Modal เข้า Workspace ทันที" / "กด Cancel ให้แสดง Modal เหมือนเดิม"

## SC-UG-03 — Resume (rule-only)

| Node | เนื้อหา |
|---|---|
| `2329:30634` | Sticky: "ถ้ากรณีหลุด หรือไม่มี Action การกด skip หรือ Let's go ให้กลับมาแสดงใหม่หลัง Login" |
| `2329:30637` | image reference (ลิงก์เสีย — render เป็น Google 404; ต้องให้ designer แนบใหม่) |
| `2329:30606` | Frame: Welcome modal instance `2329:30609` แสดงซ้ำหลัง login (0% progress) |

## SC-UG-04 — Help Center (V.2 authoritative)

| Screen | V.1 node | V.2 node |
|---|---|---|
| Idle UI (VO, ก่อนเปิด panel) | `2156:558360` | — |
| Help Center main | `2145:90566` | `2207:236884` |
| Search results | `2145:553620` | `2207:236166` |
| Open Categories (list) | `2156:558046` | `2207:236493` |
| Search in category | `2207:143212` | — |
| Article Detail | `2145:554846` | `2207:235824` (มี hero image 304×140) |
| Feedback (thank-you state) | `2156:561991` | — |

## SC-UG-05 — Search Not Found

| Screen | Node |
|---|---|
| Help Center main | instance `2156:561994` |
| Search (มีผล) | instance `2156:561995` |
| **Search Not found** (query "hh") | `2170:578050` (illustration `2203:129320`) |
| Contact Support / Report Issue (auto-fill) | `2170:578350` |

Sticky: "เมื่อกดปุ่ม Report issue about "hh" เด้งไปหน้า Contact support Auto fill ว่าค้นหาอะไรไป"

## SC-UG-06 — Feature Walkthrough (Virtual Pets ตัวอย่าง, 6 screens)

| Step | Node (modal) |
|---|---|
| Step 1 of 5 — Meet Your New Office Buddy! 🎉 | `2267:20599` (frame `2207:240140`) |
| Step 2 of 5 — How to Adopt | `2267:20603` |
| Step 3 of 5 — They Follow You Everywhere | `2267:20838` |
| Step 4 of 5 — Interactive Reactions | `2267:21073` |
| Step 5 of 5 — Ready to Find Your Pet? (Let's Go!) | `2267:21308` |
| Success Modal — You're all set! | `2267:621777` (frame `2267:68802`) |

> เป็น **centered modal carousel** (600px) บน overlay — ไม่มี anchored pointer / spotlight แม้ชื่อ scenario จะเป็น "Tooltip"

## SC-UG-07 — Contact Support form

| Screen | Node |
|---|---|
| Base form | `2170:578349` |
| Contact Type dropdown open | `2174:581489` (menu `2156:576472`) |
| Impact dropdown open | `2174:582301` (menu `2174:582649`) |
| Bug Report — empty / filled | `2174:580885` / `2174:582677` |
| macOS file picker (mock) | `2174:589591` |
| File attached | `2174:589596` |
| **My Tickets + success toast** | `2174:582300` |
| Upload failed state + error toast | `2174:591999` / `2174:592320` |
| Feature Request — empty / filled | `2174:579696` / `2174:589966` |
| General Feedback — empty / filled | `2174:579994` / `2174:590346` |

## SC-UG-08 — Contact Support directly + Email templates

| Screen | Node |
|---|---|
| Contact Support form (type = Contact Support) — empty / filled | `2186:20564` / `2207:237552` |
| My Tickets + success toast | `2186:113945` |
| Email — User acknowledgement (auto) | `2203:110232` |
| Email — Admin new ticket (Bug Report, มี Impact + Attachment) | `2207:145124` |
| Email — Admin new ticket (Feature Request / Feedback / Contact Support) | `2351:372431` |
| Email — Reply: Bug resolved | `2354:372608` |
| Email — Reply: Feature Request | `2362:372786` |
| Email — Reply: General Feedback | `2362:372946` |
| Email — Reply: Request received | `2362:373106` |

Sticky: "แบบที่ 1 รวมกับ Contact type เลย" — Contact Support เป็น option ที่ 4 ใน dropdown เดียวกับ SC-UG-07 (ไม่ใช่หน้าแยก)

---

## Shared Components (ใช้ข้าม Scenario)

| Component | ใช้ใน | ขนาด / หมายเหตุ |
|---|---|---|
| Onboarding modal shell (sidebar 212 + content 688) | UG-01, 02, 03 | 900×600, radius 16, bg `#242B32` |
| Success/Confirm modal shell | UG-01, 02, 06 | 458×332, radius 24, p-40 — สลับ icon (check เขียว / warning เหลือง) |
| Full-screen overlay | ทุก scenario | `rgba(0,0,0,0.5)` |
| Spotlight overlay (boolean subtract) | UG-02 | เจาะรูรอบปุ่มเป้าหมาย |
| Coach-mark tooltip (ขาว) | UG-02 | radius 12, text ดำ 16/22 |
| Help Center panel shell | UG-04, 05, 07, 08 | 336×1024 docked ขวา, p-16, gap 24 |
| Tab fill (Articles / My Tickets) | UG-04, 05, 07, 08 | active = `rgba(88,214,141,0.2)` |
| Search input 42px | UG-04, 05 | placeholder `#636D76` |
| Article cards (Recommend 275w / Search 304w / List 304w) | UG-04, 05 | thumb 80×80 (V.2) |
| Mention highlight (search match) | UG-04 | text `#FF8000` + bg `rgba(255,128,0,0.2)` |
| Breadcrumb block (back 32×32 + title) | UG-04, 05, 07, 08 | title `#8C99A6` Bold 14 |
| Info alert banner (ฟ้า) | UG-05, 07, 08 | Blue/10% bg + Blue/20% border + `#2DB6FF` text |
| Form input / textarea + counter | UG-05, 07, 08 | h-42 / h-100, counter 12/15 `#8C99A6` |
| Dropdown menu | UG-07, 08 | bg `#242B32`, radius 16, item h-42 |
| File upload drop area | UG-05, 07 | h-58, "No file upload", JPG/PNG ≤ 5MB |
| Send button disabled/enabled | UG-05, 07, 08 | disabled `#DBDFE3`/`#B2BBC3`/`#A3ADB8` → enabled `#58D68D` |
| Toast (success / error) | UG-07, 08 | 368w, bg `#1A1B1E`, radius 16, มุมขวาบน |
| History Card (My Tickets) | UG-07, 08 | 304w — `#ZYR-xxxx` + title + date |
| New Feature Modal (carousel) | UG-06 | 600w, step badge `#255A3B`/`#58D68D`, dots + Back/Next |

## Layout Constants

| ค่า | จาก Figma |
|---|---|
| Canvas | 1440×1024 px |
| Onboarding modal | 900×600 at (270, 212) — centered |
| Success/Confirm modal | 458×332 at (491, 346) |
| Help Center panel | 336×1024 docked `right-0 top-0` |
| New Feature modal (UG-06) | 600w at (420, ~256) |
| Toast | left 1088, top 16 |
| Spotlight hole (UG-02) | 214×70 at (1196, 98) — รอบปุ่ม Create workspace |
| Coach-mark tooltip (UG-02) | 300×46 at (884, 110) |

> **หมายเหตุ asset**: hero images / illustration (กล่อง question marks 100×100, Virtual Pets artwork, product screenshots ใน onboarding) เป็น raster ใน Figma — ต้อง export แล้วอัปโหลดขึ้น R2 (`static/...`) ก่อน implement; URL asset จาก MCP หมดอายุใน 7 วัน
