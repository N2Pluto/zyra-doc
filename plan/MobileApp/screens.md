# Mobile App — Screen-by-Screen Breakdown (member เท่านั้น ไม่ทำ admin)

> **สถานะ:** Planning — แบ่ง scope ตามหน้า/พื้นผิว UI (2026-09-29) · **มติ 2026-09-30: Lite Mode (แนวตั้ง, ไม่โหลดแมพ) / Spatial Mode (แนวนอน) ผู้ใช้เลือกเอง เปลี่ยนใน Settings** (§0.1, ux-ui-plan.md) · **รอ UI mobile จาก design** สำหรับหน้าที่ติด 🎨 · **repo:** zyra-app
> **ที่มา:** [spec.md](spec.md) (scope SC-MOB) + [technical-design.md](technical-design.md) §14–15 (inventory รหัส A/B/C/D/E) + [task-breakdown.md](task-breakdown.md)
> **กติกา:** ✅ ทำใน Phase 0–1 · 🔜 ทำหลังขึ้น store (Phase 2–3) · ❌ ไม่ทำบนมือถือ (desktop only) · 🎨 ต้องรอ Figma mobile ก่อนแตะ layout · ⚙️ ทำได้เลยไม่ต้องรอ UI

## 0. สรุปจำนวน

| กลุ่ม | หน้า/พื้นผิว | ✅ ทำ | 🔜 หลัง store | ❌ ไม่ทำ |
|---|---|---|---|---|
| A. Auth & entry | 12 | 11 | 0 | 1 (`/legal` ใช้ของเดิม) |
| B. Workspace list & lobby | 4 | 4 | 0 | 0 |
| C. Virtual Office core | 9 | 8 | 1 | 0 |
| D. Meeting (zone) | 8 | 6 | 2 | 0 |
| E. Chat | 8 | 7 | 1 | 0 |
| F. Social / notification | 8 | 8 | 0 | 0 |
| G. Pet / Environment / Spotlight | 5 | 3 | 2 | 0 |
| H. Settings / profile | 4 | 4 | 0 | 0 |
| I. Help / onboarding | 5 | 4 | 1 | 0 |
| J. ตัดออก | — | — | — | admin 28 route + editor 2 route + dev 2 route + PZ decorate + PiP |

## 0.1 โหมด Lite / Spatial (มติ 2026-09-30 เย็น — ผู้ใช้เลือกเอง, Lite ไม่โหลดแมพ)

นิยามใน [spec.md](spec.md) หัวข้อ "โหมดการแสดงผลบนมือถือ" · วิธีทำใน [technical-design.md §16](technical-design.md) · UI จริงใน [ux-ui-plan.md](ux-ui-plan.md) · ตารางนี้บอกว่าแต่ละกลุ่มหน้าอยู่โหมดไหน

**หน้าใหม่จาก Figma HP-03 ที่ไม่มีในโค้ด (ทั้งสองโหมด):** Select workspace mode + sheet Keep This Setting (ux-ui-plan §3.4) · หน้า Rotate your phone (§3.5) · Connecting tips ใหม่ (§3.7) · Lite Home + Slide state (§3.8) · Splash + Onboarding 3 slide (App, §3.1)

| กลุ่ม | Lite (แนวตั้ง) | Spatial (แนวนอน) | หมายเหตุ |
|---|---|---|---|
| A. Auth & entry | ✅ หลัก | ✅ layout เดิม fluid | จะ lock portrait ไหม → spec OQ 9 |
| B. Workspace list & lobby | ✅ หลัก | ✅ | camera preview ต้องได้ทั้งสอง |
| C. VO core — canvas / HUD toolbar / sidebar / minimap / joystick | ❌ **ไม่โหลด engine เลย** (TD §16.2) | ✅ joystick 128×140, minimap 169×100, ปุ่มกลม 5 ปุ่มขวาบน, Meeting Menu กลางล่าง (ux-ui-plan §3.9) | Rotate ทับ Spatial → `setRenderSuspended` (TD §16.3) |
| C. Profile panel / status picker / player context menu | ✅ Profile tab / member list ใน Lite Home | ✅ เปิดจากปุ่ม avatar ในแถบ Meeting Menu ข้างปุ่มไมค์ (Ten) | |
| D. Meeting / zone | ✅ เข้าด้วย Instant meeting / การ์ด "In meeting" (พฤติกรรม = spec OQ 11) · ผู้ใช้เป็น ghost tile | ✅ tile คนพูด 168×158 ซ้อนแมพ · grid เต็มรอ HP-04 | เปลี่ยนโหมด = leave + join ใหม่ |
| E. Chat | ✅ Chat tab full screen | ✅ overlay | store เดียวกัน draft ไม่หาย |
| F. Social / notification | ✅ Home tab? (spec OQ 6) | ✅ toast / panel บนแมพ | |
| G. Pet / Env / Spotlight / PZ | Spotlight viewer ✅ portrait (HP-11) · pet / env / PZ ❌ (ผูกกับแมพ) | ✅ | |
| H. Settings / profile | ✅ Profile tab | ✅ modal | |
| I. Help / onboarding | ✅ | ✅ | splash / onboarding รอ Figma |
| **Lite Home ใหม่** — header workspace, Start spotlight / Instant meeting, ค้นหา, In meeting, Circle, Online/Offline, bottom nav **3** icon-only Home / Chat / Profile — Calendar ซ่อนไปก่อน (หดตอนเลื่อน) | ✅ component ใหม่ `views/user/virtual-office/lite/*` | — | 🎨 spec มีแล้ว ux-ui-plan §3.8 (node 5800-425090 / 5873-360244) · Calendar tab ยังไม่มี feature ในโค้ด (clickup-spec §18 ข้อ 5) |
| **Select workspace mode + Keep This Setting** | ✅ | ✅ (แนวนอน scroll) | 🎨 spec มีแล้ว ux-ui-plan §3.4 (6392-1128974, 6407-1129791) |
| **Rotate your phone** | ✅ ทับ Lite เมื่อแนวนอน | ✅ ทับ Spatial เมื่อแนวตั้ง | 🎨 spec มีแล้ว ux-ui-plan §3.5 · ไอคอนยังเป็น placeholder |
| Simple Mode (ClickUp EP-01 level 4) | — | fallback ภายใน Spatial เมื่อ FPS < 15 | คนละอย่างกับ Lite Mode |
| **Tablet / iPad (Figma EC-03)** — ใช้ UI มือถือ (ในแอปเสมอ · เว็บ = จอสัมผัส + ด้านยาว ≤ 1366) | ✅ Lite Home ยืด 1 คอลัมน์ ขอบ 24 · bottom nav ยาวเต็ม − 48 · ไม่มี max-width | ✅ HUD เดิม · ปุ่มกลม 5 ปุ่ม + Chat = 44 · joystick / minimap / Meeting Menu ขนาดเดิม | ด้านสั้น ≥ 744 · Split View รองรับ — โหมดตัดสินจากสัดส่วนหน้าต่าง · หน้าก่อนเข้า workspace แนวนอนได้ จัดกลาง · meeting grid 3×3 (รอ design) · bottom sheet ≤ 600 กลางจอ · ux-ui-plan §17 · task 0.41–0.46 |
| **Small phone ≤ 375 (EC-03)** | ✅ layout 390 ขอบ 16 + ellipsis | ✅ 667×375 HUD ขนาดเดิม | ไม่มี frame ใน Figma · modal 90dvh scroll · task 0.44 |

## A. Auth & entry (public routes)

| Route / หน้า | View | Mobile | งานที่ต้องทำ | UI |
|---|---|---|---|---|
| `/login` | `views/login/hero-login.tsx`, `components/card-login.tsx` | ✅ | card `max-w-[458px]` fluid อยู่แล้ว · **Google native sign-in** แทน popup `card-login.tsx:314` (B1) · เพิ่มปุ่ม **Sign in with Apple** iOS (B2) · ลิงก์ Contact us `:59,397,440` → Browser plugin (B6) · safe-area (S3) | ⚙️ layout เดิมใช้ได้ · 🎨 เฉพาะปุ่ม Apple |
| **Smart app banner "Meet Zyra on mobile" (Figma HP-07)** — โผล่หลังเปิดหน้า ~5 วิ · Later / Open Zyra → มีแอป = เปิดแอป · ไม่มี = iOS App Store / Android Play Store | ใหม่ — landing page (เว็บแยก) + zyra-app ในเบราว์เซอร์มือถือ (Ten ยืนยัน) | ✅ | universal link / app link + fallback URL store · Later ซ่อน 7 วัน · install prompt ขึ้นหลังกด Later · sheet ธีมสว่าง · **PWA install ยังรองรับ (Ten)**: `beforeinstallprompt` Android + คำแนะนำ iOS · `manifest.ts` orientation `any` | 🎨 banner มี spec · install prompt ยังไม่มี UI |
| **Splash + Onboarding 3 slide (แอปเท่านั้น, Figma HP-07)** — Splash animated **2 วินาที** (ClickUp) → slide 1–3 **ไม่มีปุ่ม Skip** (Ten) → Get started · โชว์เฉพาะเปิดครั้งแรก (สมมติ) · **แนวตั้งอย่างเดียว** | ใหม่ — `zyra-mobile` splash (`@capacitor/splash-screen`) + หน้า slide ใน zyra-app | ✅ | ภาพประกอบ slide ยังเป็น placeholder 🔍 · จำ "เคยดูแล้ว" ด้วย Capacitor Preferences | 🎨 spec มีแล้ว |
| `/login/google`, `/login/google/callback` | `app/login/google/**` | ✅ | บน native ไม่ผ่าน route นี้ (plugin ให้ id_token ตรง) · บนเว็บมือถือใช้ redirect flow เดิมได้ | ⚙️ |
| `/signup`, `/signup/google-success` | `views/signup/*` | ✅ | card fluid ✅ · Google/Apple เหมือน login · `hero-google-success.tsx:37` 458px + `p-10` → ลด padding | ⚙️ |
| `/verify/[id]` (OTP) | `views/verify/hero-verify.tsx` | ✅ | เพิ่ม `autoComplete="one-time-code"` + รับ autofill ทั้ง code ในช่องเดียว `:398,526-548` · toast `:64` fixed 336px → เต็มกว้าง · `.focus()` ×9 ระวังคีย์บอร์ดเด้ง | ⚙️ |
| `/forgot-password`, `/reset-password/[token]` | `views/forgot-password`, `views/reset-password` | ✅ | card fluid ✅ · `mailto:` `hero-reset-password.tsx:266` → copy address / `App.openUrl` (B6) · deep link `/reset-password/{token}` จากอีเมลเปิดแอป (B4) | ⚙️ |
| `/signed-out`, `/maintenance` | `views/login/hero-session-ended.tsx`, `views/maintenance` | ✅ | fluid ✅ · ลิงก์ `https://zyra.center/` `hero-maintenance.tsx:7,45` → Browser plugin · หน้า offline ของ shell (A3) แยกจาก maintenance | ⚙️ |
| `/join/[token]` (รับ invite) | `views/user/accept-invite/hero-accept-invite.tsx` | ✅ | `:68` 458px + `p-[40px]` → fluid · deep link จากอีเมล (B4) + `redirect_url` ยอม `/join/…` `:143` | ⚙️ |
| `/legal` | `views/legal` | ✅ (ใช้ของเดิม) | responsive แล้ว (`lg:` 26) ไม่ต้องแก้ | ⚙️ |
| หน้า offline / server unreachable | ไม่มีในโค้ด (A3) | ✅ | native shell + `offline.html` + retry | 🎨 หน้าใหม่ (เล็ก) |
| Splash / permission prompt | ไม่มีในโค้ด (B13) | ✅ | splash, status bar, permission string กล้อง/ไมค์/notification/location | 🎨 splash |

## B. Workspace list & lobby (member routes)

| Route / หน้า | View | Mobile | งานที่ต้องทำ | UI |
|---|---|---|---|---|
| `/` (workspace list) | `views/user/workspace/hero-user-workspace.tsx` | ✅ | grid responsive แล้ว `:439,472` ✅ · `:301` `h-[calc(100vh-72px-32px)] min-h-[600px]` → `dvh` · dropdown `:408` · modal `workspace-capacity-modals.tsx:23,79,148` 458/554, `join-workspace-modal:50` 480, `workspace-leave-modal:30`, `idle-removed-modal:16` 458 → bottom sheet · outside-click `:226,237` → pointerdown (C7) · navbar `app-navbar.tsx:123` 289px | 🎨 navbar + modal |
| **Workspace lists มือถือ (Figma HP-06)** — เปิดจาก chevron ข้างชื่อ workspace บน Lite Home · หน้าเต็มจอ ไม่มี bottom nav · search + **filter ตามเวลา** · การ์ด 80 px: Last visited, Tag Owner/Admin/Member, 15/50 (เฉพาะ Owner/Admin), online · **join ด้วย link ทำบนมือถือ** · เลือกแล้ว reload → ไม่ถามโหมดซ้ำถ้ายังอยู่ใน 24 ชม. (Ten ข้อ 1) · แนวนอน = modal ทับแมพ | `workspace-card.tsx:253-257` (field ครบ), `join-workspace-modal.tsx` | ✅ | ux-ui-plan §10.2 · สร้าง workspace บนมือถือ **ยังไม่ตอบ** (OQ 22) | 🎨 spec มีแล้ว · filter sheet / join page ยังไม่มี |
| **Space builder มือถือ (Figma HP-07)** — **แนวตั้งอย่างเดียว** · Empty "No workspaces created" + Create workspace · การ์ด + ⋮ ตามบทบาท (Owner: Enter/Copy/Manage · Admin: +Leave · Member: Enter/Copy/Leave · **ไม่มี Workspace editor / Delete บนมือถือ**) · Profile menu (Account setting / อีเมล / Sign out) · filter sheet (All / My / Shared with me · Sort Last visited / Name / Create at) · Save → **skeleton ไม่มี text ไล่ gradient** · ค้นหา highlight + "No workspaces found" | `hero-user-workspace.tsx:79,202,453`, `workspace-card.tsx:129-197`, `workspace-constants.ts:11`, `components/ui/skeleton.tsx` | ✅ | tab/sort/empty มีครบ → รวมเป็น filter sheet · **Member Copy ได้ = ต่างจากสิทธิ์ปัจจุบัน** เช็ค zyra-api 🔍 | 🎨 spec มีแล้ว |
| **Create workspace มือถือ 3 step (Figma HP-07)** — template grid 2 คอลัมน์ + filter sheet (**Capacity range slider 0–1,000 เฉพาะมือถือ** · Category radio) → details (ชื่อ + ข้อมูลอ่านอย่างเดียว **ไม่ให้แก้ category/capacity**) → Workspace created (Enter Workspace → Select workspace mode → Lite ข้าม welcome / Spatial ผ่าน welcome · Back to Space Builder) | `create-workspace-modal.tsx:24-55,89,134` (900×600 2-step) | ✅ | แยก layout มือถือเป็นหน้าเต็มจอ · ใช้ API create เดิม | 🎨 spec มีแล้ว |
| `/workspace/[id]` (lobby / pre-join) | `views/user/workspace-enter/hero-workspace-enter.tsx` | ✅ | `:347` h-screen, `:442` 934px, `:451` 562px, device menu `:406` 289px → stack แนวตั้ง · camera preview `:200` ต้อง `playsInline` (C9) · `change-character-modal.tsx:86` 820px + `grid-cols-5` → grid 3 คอลัมน์ · Escape `:74` → back button (B8) · permission กล้อง/ไมค์ native (D1) | 🎨 ทั้งหน้า |
| `/workspace/[id]/loading` | `hero-workspace-loading.tsx`, `components/workspace-loading-screen.tsx` | ✅ | `:597` h-screen · 696/580/456px `:612-643`, loading-screen `:50-73` → fluid · preload sheet `lib/vo-preload.ts:54` ลด concurrency บน cellular (G10) | 🎨 |
| `/workspace/new/[templateId]/welcome` + create/copy workspace modal | `views/user/space-builder/*` | ✅ | `hero-welcome-space.tsx:80` 934px, `:88-89` 562×344, `100vh/100vw` `:66,79` · **`create-workspace-modal.tsx:271` 900×600 + pane 537px + `grid-cols-3`** และ `copy-workspace-modal.tsx:141,180` → full-screen flow บนมือถือ · outside-click `:896` | 🎨 flow ใหม่ทั้งชุด |

## C. Virtual Office core (`/workspace/[id]/play`)

| พื้นผิว | Component | Mobile | งานที่ต้องทำ | UI |
|---|---|---|---|---|
| Canvas / แมพ | `components/game-canvas/pixi-canvas.tsx`, `zyra-engine/pixi-game/scene.ts` | ✅ | **joystick + tap-to-walk** (C1, task 0.3–0.4) · แยก tap/pan/pinch (C3) · hover → long-press (C2) · cap DPR, name tag res, culling, weather budget (C13/G2–G9) · **WebGL context-loss handling** (G1) · init race guard (G7) · `touchAction: none` มีแล้ว `pixi-canvas.tsx:384` | ⚙️ engine · 🎨 joystick visual |
| Root layout + safe area | `hero-virtual-office.tsx:12180` `h-screen` | ✅ | `100dvh` + `env(safe-area-inset-*)` (S2–S4, task 0.2) · keep-awake (B12) · lifecycle `appStateChange`/`pause` (§12.3) | ⚙️ |
| HUD bottom toolbar (cam/mic/locate/…) | `components/vo-hud.tsx` (+ `vo-hud-tooltip.tsx:40` hidden-until-hover) | ✅ | tooltip hover → ตัดออกหรือ long-press (C4) · shortcut M/V/B `hero:8311`, `vo-hud.tsx:204` → ปุ่มบนจอ · ซ่อน screen share (A1) | 🎨 |
| Sidebar rail ซ้าย 56px | `components/vo-sidebar.tsx:72` | ✅ | ย้ายเป็น bottom tab / hamburger | 🎨 |
| Minimap | `components/vo-minimap.tsx` (DOM/CSS) | ✅ | ย่อ/ซ่อนได้ · `title=` 7 จุด ตัดออก | 🎨 |
| Status picker | `components/vo-status-picker.tsx:45,57,61` | ✅ | outside-click mousedown → pointerdown · Enter/Escape → ปุ่ม | 🎨 (popover → sheet) |
| Profile panel | `components/vo-profile-panel.tsx:194-227,246` 322px | ✅ | panel → bottom sheet · `.focus()` `:227` · `Intl.Segmenter` `:100` ✅ | 🎨 |
| Player context menu (แตะ avatar คนอื่น) | `components/player-context-menu.tsx:61,67,76` 322px | ✅ | เปิดด้วย tap อยู่แล้ว `hero:4191` ✅ · outside-click, Escape → back | 🎨 |
| Outside display / Mini Mode / Auto-PiP | `use-document-pip.ts`, `vo-outside-display.tsx`, `use-autopip-eligibility.ts` | 🔜 (Phase 3 native PiP) | ปิดบน native ทั้งหมด (A4) · `vo-outside-display:158` outside-click | — |
| **Performance fallback มือถือ (Figma EP-01 — Spatial เท่านั้น)** — ladder 5 ระดับเกณฑ์ Figma: L1 < 25 DPR 2→1 (ไม่มี toast) · L2 < 21 ปิด nature + weather · L3 < 15 avatar 12→6 fps + ปิด Time of Day · L4 simple mode (minimap เต็มจอ + avatar cluster, เดิน/ประชุม/นั่งได้) · ลดทีละขั้น 10 วิ · กลับเองอัตโนมัติ + toast · toast กลางบนปิดเอง 10 วิ · เมนู Performance (Auto / Performance mode / Full effects) · desktop คงระบบเดิม | `lib/nature-performance.ts`, `use-nature-performance.ts`, `zyra-engine/pixi-game/scene.ts:1603,5300`, `use-environment.ts` | ✅ | ขยายจากระดับเดียวเป็น 5 ระดับเฉพาะมือถือ · cap DPR · simple mode renderer (ใช้ minimap?) | 🎨 ladder มี spec · toast ขาขึ้น / เมนู Performance ยังไม่มี (ข้อเสนอ ux-ui-plan §15.6–15.7) · **แก้ 2026-10-02 (โน้ต Pai): ไม่มีเมนู Performance → ux-ui-plan §19** |

## D. Meeting / Zone (`zone-enter-*`, ซ้อนใน VO)

| พื้นผิว | Component | Mobile | งานที่ต้องทำ | UI |
|---|---|---|---|---|
| Zone enter screen (ห้องประชุม) | `components/zone-enter-tiles.tsx` (`:245,438,487` hidden-until-hover) | ✅ | tile action overlay → tap-to-reveal (C4) · `<video autoPlay>` `:44,83` `playsInline` (C9) · grid tile ตามจอแคบ | 🎨 |
| Meeting header (ชื่อ zone, copy link, ออก) | `components/zone-enter-header.tsx:197,295,307,317` | ✅ | copy link ✅ (D4) · outside-click → pointerdown · B shortcut → ปุ่ม · `title=` 13 จุด | 🎨 |
| Media device menu (mic/cam/speaker) | `components/vo-media-device-menu.tsx:94,106,137-138,166,259` | ✅ | **ซ่อน speaker picker บน iOS** (C11) · mic test `mic-test.ts` ✅ · devicechange ✅ (D2) · เพิ่มปุ่มสลับกล้องหน้า/หลัง | 🎨 |
| Background effects modal (blur / virtual bg) | `components/vo-background-effects-modal.tsx:86,154,287,382` | ✅ (ปิด default บน mobile) | feature-check มีแล้ว (D3) · `<video>` `:287` `playsInline` · file input `:382` ✅ · ปิด default เพราะ MediaPipe 19 MB + CPU (G10) · ต้องทดสอบ `VideoFrame` บน WKWebView (P2) | 🎨 |
| Screen share — **เริ่มแชร์** | `lib/api/sfu-client.ts:816-905`, ปุ่มใน hud/header | 🔜 (Phase 3 native) | Phase 1 ซ่อนปุ่มเมื่อไม่มี `getDisplayMedia` (A1) | — |
| Screen share — **ดูของคนอื่น** | `components/zone-enter-screen-share.tsx:97-116,151,184,191,221` | ✅ | fullscreen → pseudo-fullscreen CSS (C10) · controls hidden-until-hover `:221` (C4) · pan/zoom pointer ✅ + เพิ่ม pinch | 🎨 |
| Meeting chat (zone chat) | `components/zone-enter-chat.tsx:215,265,280,406,708,814,827` | ✅ | message action bar hidden-until-hover `:215` (C4) · `w-[366px]` `:280` → เต็มกว้าง · Enter ส่ง + `isComposing` (C8) · `.focus()` rAF `:708` เปิดคีย์บอร์ดซ้ำ · keyboard plugin (B9) · attachment `target=_blank` `:406` → Browser plugin (B6) · file input `:827,835` ✅ | 🎨 |
| **Meeting บนมือถือ (Figma HP-04)** — header 5 ปุ่ม (PIP, lock, **Participants** `Users`, chat, ลำโพง) + ชื่อ meeting แทนชื่อห้องถ้ามี · tiles 1–6+ (แนวตั้ง 2 คอลัมน์ / แนวนอน 3 คอลัมน์, ลูกศรเลื่อนหน้าเมื่อ > 6) · Meeting Menu 7 ปุ่ม · 1-tap ซ่อนเมนู · double-tap ขยาย tile | ต่อยอด `zone-enter-header.tsx`, `zone-enter-tiles.tsx` | ✅ | ux-ui-plan §8.2 · emoji/raise hand มีแล้ว (`zone-enter-types.ts:28-33,142`) แค่ย้าย UI | 🎨 spec มีแล้ว |
| **PIP ในแอป** (tile 168×158 ลอยบน Lite Home / ขวาล่างแมพเหนือ minimap — minimap ไม่หาย, สลับคนพูด) | ใหม่ (`use-document-pip.ts` ใช้ไม่ได้) | ✅ | ux-ui-plan §8.2 PIP · ใช้ `activeSpeakersChanged` เดิม (`use-meeting-media.ts:820`) · คง LiveKit room ระหว่างย่อ | 🎨 spec มีแล้ว · ลากได้ไหม = §8.6 ข้อ 9 |
| **Join meeting sheet / modal + Request to join + toast คำขอ** ("Someone is requesting to join your meeting." 5 วิ + ตัวเลขบนไอคอน `Users` → แตะไป Requesting list) | ใหม่ · toast ต่อยอด `vo-knock-notification.tsx` | ✅ | ux-ui-plan §8.2, §8.8.4 · zyra-ws join by id (TD §16.2) · ขอเข้าห้องล็อกใช้ knock เดิม | 🎨 sheet มีแล้ว · **toast โน้ต Pai แล้ว รอ frame** |
| **Setting ห้อง** (bottom sheet: Voice output · Camera filter · Invite — ไม่มี Room name) | ต่อยอด `vo-media-device-menu.tsx` | ✅ | ux-ui-plan §8.7 | 🎨 **รอ design** |
| **Participants sheet** (มงกุฎ host · ไมค์ท้ายแถว host ปิดได้อย่างเดียว · ⋯ Kick · Mute all · Requesting list Accept/Deny) | ต่อยอด `zone-participants-submenu.tsx` | ✅ | ux-ui-plan §8.8.2 | 🎨 โน้ต Pai แล้ว รอ frame |
| **Invite sheet** แท็บ Chat / Link / Email (Member เห็นแค่ Chat · Link = ลิงก์ workspace ตั้งวันหมดอายุได้ · Email หลายอีเมล role Member) | ต่อยอด `zone-hover-card.tsx` (list ชวน), `invite-member-modal.tsx` + `customize-invite-link-panel.tsx` | ✅ | ux-ui-plan §8.8.3 | 🎨 โน้ต Pai แล้ว รอ frame |
| All rooms are busy sheet · Low battery toast | ใหม่ | ✅ | ux-ui-plan §8.2 · battery ผ่าน `@capacitor/device` (B15) | 🎨 spec มีแล้ว |
| Spotlight stage (broadcast) — **Figma HP-11: หน้า Spotlight เต็มจอแบบหน้า Meeting** (presenter + คนดู · แนวนอนตามข้อเสนอ ux-ui-plan §18.6) | `components/vo-spotlight-stage.tsx:689,892-935,1055` | ✅ (เดิม 🔜 Phase 2 — Ten 2026-10-01) | `<video>` ×2 `playsInline` · drag pointer capture ✅ · `backdrop-blur` ×3 · ดูได้ก่อน ส่วนเริ่ม spotlight ต้องมีปุ่มแทน B | 🎨 |

## E. Chat (`views/chat/**`, overlay ใน VO — responsive prefix = 0)

| พื้นผิว | Component | Mobile | งานที่ต้องทำ | UI |
|---|---|---|---|---|
| Chat surface (โครง 2 คอลัมน์) | `chat-surface.tsx:294,338-353` | ✅ | **stack เป็น list → conversation** แทน sidebar 320px + flex-1 (CH4) · Cmd+K `:85` → ปุ่มค้นหา | 🎨 flow ใหม่ |
| Conversation list (sidebar) | `chat-sidebar.tsx:328,334,362,392` | ✅ | `w-[320px]` → เต็มจอ · outside-click `:328` · dropdown `:392` 184px | 🎨 |
| Message list + message item | `message-list.tsx:76,78,249`, `message-item.tsx:146,152,251,269-282,351,398-412` | ✅ | **message actions (react/reply/copy/edit/delete) ซ่อนจน hover → long-press / ปุ่ม …** (CH1) · **virtualize list** (CH7) · popover clamp `innerWidth` ✅ · copy ✅ (D4) | 🎨 action sheet |
| Message input | `message-input.tsx:132,154-171,177-183,218,330,432-457,468-473,488,575,597,606` | ✅ | Enter ส่ง → ปุ่มส่ง + `enterKeyHint` + `isComposing` (CH8/C8) · keyboard plugin (B9) · mention popup Arrow/Enter → tap · drop file ไม่มีบน touch (มีปุ่มแนบ ✅) · เพิ่ม `capture="environment"` ถ่ายรูป (D5) · emoji picker `autoFocus` `:120` | 🎨 |
| Thread / info / media panel | `thread-panel.tsx:77`, `conversation-info-panel.tsx:55,91`, `conversation-media-panel.tsx:110,156,167,191` | ✅ | `absolute right-0 w-[320px]` → full-screen push · `grid-cols-3` `:156` · `target=_blank` `:167,191` → Browser plugin (B6) · outside-click `:55` | 🎨 |
| File preview (รูป/ไฟล์) | `file-preview.tsx:108,122,156-157,258,299,307,375,406,456` | ✅ | **pan/zoom mouse-only → pointer + pinch** (CH6) · `w-[600px]` `:375` (มี `max-w` ✅) `70vh` `:307` · download `:258,456` → Filesystem + Share (B5) · Arrow gallery → swipe | 🎨 |
| Create group / reaction / search filter / link confirm | `create-group-modal.tsx:158,217,332,414`, `reaction-modal.tsx:24,37`, `search-filter-popover.tsx:84,85,100,120`, `message-text.tsx:35,42,50,196,269,293` | ✅ | 320/366/340/400px → sheet · Escape ×4 → back · ลิงก์ในแชท `window.open`/`_blank` → Browser plugin (B6) · file input + FileReader `:217,414` ✅ | 🎨 |
| Pending attachment / attachment block | `pending-attachment-card.tsx:49-50,65,89`, `message-attachment-block.tsx:172` | ✅ | ปุ่มลบ/cancel/download ซ่อนจน hover → แสดงเสมอ (CH2/CH3) | 🎨 |
| **Chat ส่งไม่ได้ (Figma HP-10)** — ส่งซ้ำอัตโนมัติ **5 ครั้ง 1/2/4/8/16 วิ** (bubble sending) → ไม่สำเร็จ = **bubble failed ค้างใน list แตะเพื่อส่งใหม่** + sheet (แนวตั้ง) / modal (แนวนอน) **"Message not sent"** ปุ่ม Done · Service ล่มใช้ sheet เดียวกัน · **ไม่มี offline queue** | `chat-store.ts:24` (`sending/sent/failed` ✅), `message-item.tsx:198` (`isFailed`) | ✅ | เพิ่ม auto-resend + แตะ bubble ส่งใหม่ + sheet · icon `WifiOff` / `CircleAlert` (ux-ui-plan §14.7) | 🎨 spec มีแล้ว · icon รอ design ยืนยัน |
| **Chat list มือถือ (Figma HP-05)** — แนวตั้ง: tab All / Channel / Group / Direct message + Threads Messages + chip `@You` · แนวนอน: ปุ่ม filter เดิม (ไม่มี tab) | `chat-sidebar.tsx:523-541` (3 section พับ → tab), `search-filter-popover.tsx` | ✅ | ux-ui-plan §9.2 · chip @You ต้องมี mention flag จาก store 🔍 | 🎨 spec มีแล้ว |
| **แชทแนวนอน = overlay 2 คอลัมน์ 249/515 ทับแมพ** (× ปิดซ้ายบน) · **engine render ต่อ** (Ten ข้อ 6) · คีย์บอร์ดเปิด → **ดันข้อความล่าสุดขึ้น** (Ten ข้อ 7) | `chat-surface.tsx:294,338-353`, `vo-chat-space-overlay.tsx` | ✅ | ใช้โครง 2 คอลัมน์เดิม ย่อขนาด · keyboard plugin (B9) ปรับ scroll ให้ข้อความล่าสุดอยู่เหนือ input | 🎨 spec มีแล้ว |
| **FAB → Create chat / Start a new chat** + สถานะในรายชื่อ (Active / Busy / custom status / In meeting) + **สร้าง Group / Channel บนมือถือได้** (Ten ข้อ 9) | `chat-surface.tsx:222-223`, `start-new-chat-panel.tsx:49-56`, `create-group-modal.tsx` | ✅ | ต่อ presence + custom status + meeting state เข้าแถว · "Create chat" = Group หรือ Channel **ยังไม่ตอบ** (OQ 17) | 🎨 create sheet/หน้าสร้างยังไม่มี |
| **Long-press ข้อความ → overlay blur + Emoji panel 7 ตัว + Submenu 7 ข้อ** · **Forward + Select ต้องทำจริง** (Ten ข้อ 3) | `message-context-menu.tsx:51-81` (เมนูครบ, Forward/Select disabled), `emoji-picker.tsx:85` (QUICK_EMOJIS ตรง Figma) | ✅ | เพิ่ม long-press trigger (CH1) + render ข้อความซ้ำเหนือ overlay · Forward = เลือกห้องปลายทาง · Select = multi-select | 🎨 Forward/Select flow ยังไม่มี |
| **Mention**: แนะนำ 3–4 คนคุยบ่อย + @Everyone ล่างสุด (Ten ข้อ 4) · แตะเลือก | `message-input.tsx:84-116`, `message-input-utils.ts:4-7` | ✅ | เพิ่มการจัดอันดับ (เกณฑ์สมมติ: ข้อความถึงกันล่าสุดในห้อง — OQ 18) · Arrow/Enter → tap | 🎨 spec มีแล้ว |
| **Preview image มือถือ**: แตะ 1 = เต็มจอ · pinch out = zoom + ซ่อน header/filmstrip · แตะ = โชว์ · pinch in = คืน · **download = บันทึกลง Photos (ขอ permission)** (Ten ข้อ 8) · เมนู ⋮ | `file-preview.tsx:84-139` | ✅ | pinch ด้วย pointer events · `@capacitor/filesystem` + Media/Photos permission (B5) · ⋮ มีอะไร **ยังไม่ตอบ** (OQ 19) | 🎨 ⋮ ยังไม่มี |
| **Voice message** (ปุ่มไมค์ในช่องพิมพ์ → อัดเสียง → ส่ง → bubble + player) — **Ten: ทำรอบแรก** | **ใหม่** — ไม่มีในโค้ด (grep `MediaRecorder` ใน `views/chat` = 0) | ✅ | ฝั่ง web: `MediaRecorder` (WKWebView รองรับ iOS ≥ 14.3) + permission mic (A2) · ฝั่ง zyra-api: message type `audio` + S3 upload (rule 11) · ฝั่ง zyra-ws: broadcast เหมือน attachment | 🎨 **ยังไม่มี UI** (ux-ui-plan §9.7) |
| **Emoji บนมือถือ** = `emoji-picker.tsx` เป็น bottom sheet (Ten ข้อ 5 — iOS สลับคีย์บอร์ด emoji เองไม่ได้) | `emoji-picker.tsx` | ✅ | popover → sheet · `autoFocus` `:120` ปิดบนมือถือ | 🎨 |
| **Thread / Conversation info / Media panel บนมือถือ** — Ten: ทำ (full-screen push) · **DM read receipt ✓/✓✓** — Ten: ถ้า backend ไม่มีให้เพิ่ม | `thread-panel.tsx`, `conversation-info-panel.tsx`, `conversation-media-panel.tsx`, `message-item.tsx:83` | ✅ | ทางเข้า = แตะชื่อห้องที่ header · **Chat info แบบแท็บ Telegram** (Members · Media · Files · Links · Threads · Pinned · ปุ่ม Mute / Search / Leave · Edit = Owner/Admin) ux-ui-plan §9.8 · read receipt เช็ค zyra-ws/zyra-api ก่อน 🔍 | 🎨 โน้ต Pai แล้ว รอ frame |

## F. Social / notification (ใน VO)

| พื้นผิว | Component | Mobile | งานที่ต้องทำ | UI |
|---|---|---|---|---|
| Member panel | `components/vo-member-panel.tsx:594,639-717` (322px, `absolute inset-y-0 left-[56px]` `hero:13870`) | ✅ | locate-on-hover ×13 → tap · panel → bottom sheet · ไม่ virtualize (G11) | 🎨 |
| Notification panel | `components/vo-notification-panel.tsx:234` (322px, `hero:13958`) | ✅ | → bottom sheet · ผูก push tap → เปิด panel (B3) · badge count (B11) | 🎨 |
| **Notification มือถือ (Figma HP-06)** — แนวตั้ง: หน้าเต็มจอ (back, All/Unread underline, Mark as read, กลุ่ม Today/Yesterday, ยังไม่อ่าน bg white 5%, คำสำคัญ white) · แนวนอน: **modal ทับแมพ** (Ten ข้อ 4, UI ยังไม่มี) | `vo-notification-panel.tsx:109-243` (tab + mark read มีแล้ว) | ✅ | จัดกลุ่มตามวัน + highlight คำสำคัญ · ประเภท "New update" (ระบบ) ยังไม่มีใน backend 🔍 | 🎨 spec แนวตั้งมีแล้ว |
| Announcement panel + form + card | `announcement/announcement-list-panel.tsx:105,512`, `announcement-form.tsx:636,662`, `announcement-card.tsx:47`, `announcement-confirm-modal.tsx:54`, `announcement-date-time.tsx:170,367` | ✅ | 322/458px → sheet · rich-text editor `components/rich-text/rich-text-editor.tsx` (contentEditable + execCommand) **ทดสอบบน iOS** · outside-click ×3 · drop image → ปุ่มแนบ | 🎨 |
| Wave / knock / follow / circle-join / media-request / share-request toast | `vo-wave-notification.tsx`, `vo-knock-notification.tsx:98,190`, `vo-follow-bar.tsx:119,173`, `vo-circle-join-notification.tsx:76`, `vo-media-request-notification.tsx:84`, `vo-share-request-notification.tsx:78` | ✅ | 320px + `top-right` → top-center เต็มกว้าง · haptics ตอนรับ (B10) · เสียง `use-vo-sounds.ts` ต้อง gesture แรก (C12) | 🎨 |
| Connection toast / reconnect modal / alert banner | `vo-connection-toast.tsx:42`, `vo-reconnect-failed-modal.tsx:19`, `vo-alert-banner.tsx:77,98` | ✅ | 320/458px · alert source `target=_blank` `:98` → Browser plugin · reconnect flow มีแล้ว (§13.2) + bridge `appStateChange` | 🎨 |
| Invite member modal | `components/invite-member-modal.tsx:53,169,190,246,292` (696px) | ✅ | → full-screen · copy link ✅ · **share sheet** (`@capacitor/share`) · Enter/comma `:190` → chip input | 🎨 |
| Manage members modal | `components/manage-members-modal.tsx:190,405,631,879` (**934px**) | ✅ | → full-screen list · outside-click ×2 · copy id ✅ | 🎨 |
| Teleport zone picker | `components/vo-teleport-zone-picker.tsx:130,134,138,160` (660px) | ✅ | → sheet · Arrow/Enter → tap | 🎨 |

## G. Pet / Environment / Spotlight / Private zone

| พื้นผิว | Component | Mobile | งานที่ต้องทำ | UI |
|---|---|---|---|---|
| Pet panel + pet interaction + tooltip + share/evolution modal | `vo-pet-panel.tsx:64,115`, `pet-interaction-overlay.tsx:88`, `pet-tooltip.tsx:13`, `pet-share-modal.tsx:196`, `pet-evolution-modal.tsx:81,100`, `pet-sheet-player.tsx:94,115,133` | ✅ | `100vh` `:115` · "Press [P]" → ปุ่ม/long-press (C2) · rAF loops ×3 (C13) · pet sounds `pet-sound-player.ts` gesture (C12) · `pet-sheet-player` canvas DPR | 🎨 |
| Weather panel + weather widget (draggable) | `vo-weather-panel.tsx:78,85`, `vo-draggable.tsx:108,129,258,265,281,292` | ✅ | `100vh` · draggable pointer + `touch-none` ✅ · `onDoubleClick` `:292` → double-tap ✅ · ResizeObserver ✅ | 🎨 |
| Environment tab (ตั้ง location, owner) | `vo-environment-tab.tsx:157-166,495` (458px) | ✅ | geolocation → plugin + permission string (B7) · → sheet | 🎨 |
| Spotlight (ดู / เริ่ม) | `use-spotlight-broadcast.ts:380,669,741-745`, `vo-spotlight-*-confirm-modal.tsx:30,33` | ✅ (HP-11) | **เริ่ม:** Lite = ปุ่ม Start spotlight (ไม่ต้องอยู่บน marker — zyra-ws task 0.48) · Spatial = megaphone → auto-walk (0.49) · ปุ่ม Play แทนปุ่ม B · นับ 5 วิ toast + Stop · confirm modal 458px → sheet · **ดู:** นอก meeting เปิดเต็มจออัตโนมัติ · ใน meeting ตาม web (0.50) · task 0.47–0.51 | 🎨 |
| Private zone claim / edit HUD (decorate mode) | `pz-zone-card.tsx:86,93`, `pz-edit-hud.tsx:99,271,373-378`, `pz-layers-panel.tsx:87,104`, `pz-unclaim-modal.tsx:37`, `pz-edit-zone-name-modal.tsx:64,99,102`, `hero:9554,9737,9948` | 🔜 Phase 3 | **HTML5 drag `pz-edit-hud.tsx:373` ใช้บน touch ไม่ได้** (D5) · Delete/Backspace/Cmd+Z shortcuts · claim/unclaim (ไม่ต้อง drag) ทำได้ Phase 1 · decorate ทั้ง flow → หลัง store | 🎨 |

## H. Settings / profile

| Route / พื้นผิว | Component | Mobile | งานที่ต้องทำ | UI |
|---|---|---|---|---|
| `/setting` (profile) | `views/profile/*` (`sm:` 41, `lg:` 25) | ✅ | responsive แล้ว ✅ · `upload-avatar-modal.tsx:187` 550px (`react-easy-crop` touch ✅) · Radix Tooltip `profile-form.tsx:258` → ตัด · file input `:202` ✅ | ⚙️ (เกือบไม่ต้องแก้) |
| `/setting/change-password` | `views/change-password` | ✅ | responsive แล้ว ✅ | ⚙️ |
| VO settings modal (in-office) | `components/vo-setting-modal.tsx:567,911` (**934×800**) | ✅ | → full-screen settings page · outside-click · notification toggle push ต่อประเภท (task 2.5) · `zyra_*` localStorage ✅ | 🎨 |
| **Profile tab (Figma HP-06)** — การ์ด status (Active/Busy/Away + custom status + chevron ไป `/setting`) · Setting: Account and Security (= `/setting` + change-password), Language, Audio, **Camera**, Notification · Workspace: Manage member, Environment (**เฉพาะ Owner/Admin** — Ten ข้อ 6), Workspace mode · Support: Help, Legals · Switch workspace / Log out · **ตัด tab general / integrations บนมือถือ** (Ten ข้อ 3) · แนวนอน = modal ทับแมพ | `vo-profile-panel.tsx:13-14,70,453`, `vo-setting-modal.tsx:719-736`, `language-switcher.tsx`, `manage-members-modal.tsx`, `vo-environment-tab.tsx` | ✅ | หน้าย่อยทุกหน้า **ยังไม่มี UI** · `dnd` → แสดงเป็น Busy (สมมติ, OQ 20) | 🎨 เมนูมีแล้ว หน้าในยังไม่มี |
| **Notification settings มือถือ (Figma HP-08)** — แนวตั้ง: หน้าลูกจาก Profile **คง bottom nav** (Ten — ข้อยกเว้น) · แนวนอน: หน้าเต็มจอ · กลุ่ม Chat (3) / Meeting & Circle (6 **+ Hide chat, Mute chat sounds ระหว่างประชุม**) / Calendar (5 — **รอ feature Calendar**) / Pet (1 **+ Pet sounds**) / Activities (Waves) / **Environment sounds** · สวิตช์ = **push แยกจาก in-app แสดง 2 สวิตช์ต่อแถว** (Ten) · state **ยังไม่อนุญาต** = banner + ปุ่ม "Allow notifications" (ข้อเสนอ ux-ui-plan §12.6) | `vo-setting-modal.tsx:230-460` (`NOTIFICATION_SECTIONS` — label ตรง), `stores/notification-settings-store.ts` | ✅ | field in-app มีครบ · field push ใหม่ทั้งชุด (task 2.5) · `@capacitor/push-notifications` `checkPermissions` / `requestPermissions` + เปิด Settings ของเครื่องเมื่อ denied | 🎨 หน้าหลักมีแล้ว · state ขอ Allow / สวิตช์ในแอปแยก / 4 สวิตช์เพิ่ม ยังไม่มี · **แก้ 2026-10-02 (โน้ต Pai): สวิตช์เดียวต่อแถว = push → ux-ui-plan §19** |
| **Profile แนวนอน (Figma HP-08)** — **หน้าเต็มจอ ปุ่ม ×** (Ten ยืนยัน แทน modal ของ HP-06) · avatar 56 · **เพิ่มกลุ่ม Workspace ที่ Figma ตกหล่น** (Ten) | `vo-profile-panel.tsx`, `lite/profile-tab.tsx` (0.30) | ✅ | ใช้ component เดียวกับแนวตั้ง | 🎨 กลุ่ม Workspace แนวนอนยังไม่มี |
| Device switch modal / permission guide / permission snackbar | `vo-device-switch-modal.tsx:56` 480, `vo-permission-guide-modal.tsx:32` 700, `vo-permission-snackbar.tsx:69` 653 | ✅ | → sheet · เนื้อหา permission guide ต้องเขียนใหม่สำหรับ iOS/Android (ตอนนี้อธิบาย browser) | 🎨 + copy ใหม่ |
| **Camera / Mic permission มือถือ (Figma HP-09)** — ขอสิทธิ์**ตอนกดปุ่มกล้อง/ไมค์ทั้ง 2 โหมด** (Spatial ไม่ขอตอน pre-join แล้ว) · **pre-permission sheet ของเรา** → dialog ระบบ (ข้อความ usage description ตาม Figma) · denied → **native alert** "Unable to access camera / microphone" (Cancel / Settings → หน้า Settings ของแอป) · **indicator บนปุ่ม**เมื่อถูกปฏิเสธ · mobile web → guide sheet Safari iOS / Chrome Android | `use-entry-media-permission.ts:194,265`, `sfu-client.ts:576-616`, `vo-permission-snackbar.tsx`, `vo-permission-guide-modal.tsx`, `@capacitor/dialog` | ✅ | ย้ายจุดขอสิทธิ์ออกจากตอนเข้า office/pre-join · error class มีแล้ว (`MicPermissionDeniedError` / `CameraPermissionDeniedError`) | 🎨 pre-permission / indicator / guide มือถือ ยังไม่มี (ข้อเสนอ ux-ui-plan §13.6) |
| **Connection states มือถือ (Figma HP-10)** — toast ล่าง (bg black 70% blur 4 radius 8): **Poor connection ×** (เฉพาะเน็ตเรา, × ซ่อน 20 วิ) · **Lost connection** · **Reconnecting…** · คนอื่นเน็ตแย่/หลุด = **spinner บนป้ายชื่อ tile** · วิดีโอค้างภาพสุดท้าย · retry 5 ครั้ง (~31 วิ) → meeting ตัดจบ → **หน้าหลัก (Lite Home / แมพ รวมแชท) เป็น skeleton + toast "Reconnecting..." ≤ 30 วิ (ข้อเสนอ ux-ui-plan §14.8)** → ไม่ได้ = **Workspace list** · toast **"Meeting has ended due to lost connection"** ทั้ง 2 แนว · นอกห้องประชุมใช้ toast เดียวกัน | `vo-connection-toast.tsx`, `workspace-ws.ts:82-83` (backoff 5 ครั้ง ✅), `sfu-client.ts:481-482`, `use-meeting-media.ts` | ✅ | เพิ่ม LiveKit `ConnectionQualityChanged` (Poor) · spinner บน tile · skeleton หน้าหลัก · ข้อความ toast ตาม Figma · icon lucide ux-ui-plan §14.7 | 🎨 spec มีแล้ว · skeleton หน้าหลักยังไม่มี frame |
| **Bandwidth / audio-only fallback (Figma EP-02 — มือถือ + desktop)** — วัด **uplink ของเรา** · simulcast เดิม 720/360/180: > 2 Mbps = 720 · 0.5–2 Mbps = 360 (สมมติ map) · < 1 Mbps toast "Poor connection." (ตัวเดียวกับ HP-10, × ซ่อน 20 วิ) · 200–500 kbps นาน 10 วิ → **ปิดกล้องอัตโนมัติ** (ไมค์ยังเปิด) + "Camera turned off automatically." · < 200 kbps "Very poor connection." · ต่ำกว่านั้น → flow HP-10 · กลับมาดี (> 1 Mbps นาน 10 วิ — สมมติ) → "Connection restored. Camera is ready." **กล้องไม่เปิดเอง** · ถ้าผู้ใช้ปิดกล้องเองอยู่แล้วไม่ขึ้น toast · คนอื่นเห็น avatar + spinner บนป้ายชื่อ | `sfu-client.ts:407-443` (simulcast + adaptiveStream + dynacast ✅), `use-meeting-media.ts`, `vo-connection-toast.tsx`, `zone-enter-tiles.tsx` | ✅ | เพิ่มวัด uplink (`getStats` / connection quality) · auto camera-off + flag "ปิดโดยระบบ" · toast 4 แบบ | 🎨 spec มีแล้ว |

## I. Help / onboarding / system

| พื้นผิว | Component | Mobile | งานที่ต้องทำ | UI |
|---|---|---|---|---|
| Help center panel + contact support form | `views/help-center/help-center-panel.tsx:143,385`, `contact-support-form.tsx:74,279` | ✅ | `w-[336px]` → full-screen · `grid-cols-2` · file input `:279` + `capture` · userAgent `lib/api/support.ts:84` เพิ่ม platform/app version | 🎨 |
| Onboarding modal + create-workspace spotlight | `views/onboarding/onboarding-modal.tsx:96` (**900×600**), `onboarding-skip/success-modal` 458, `create-workspace-spotlight.tsx:59` | ✅ | → full-screen stepper · spotlight ใช้ `click` ✅ | 🎨 flow ใหม่ |
| Feature tour | `views/feature-tour/feature-tour-modal.tsx:37,62` (458/600) | ✅ | → sheet · target element ต่างจาก desktop (HUD ย้ายที่) | 🎨 |
| Version check / patch notes modal | `components/version-check-modal.tsx:15,44,83,104,149,186` | ✅ | 320/458 → sheet · poll 30 นาที + on visible ✅ · หยุดตอน background (C14) | 🎨 |
| Global error | `app/global-error.tsx:25` (400px, English only) | ✅ | เพิ่ม `error.tsx` ต่อ route + ปุ่มกลับ + i18n (S8) | 🎨 |
| Toaster global | `lib/toast.tsx:112,163`, `app/layout.tsx:172` top-right | ✅ | top-center เต็มกว้าง + safe-area (S6) | 🎨 |

## J. ตัดออกจาก mobile (ไม่ทำ)

| หน้า | เหตุผล | บนมือถือแสดงอะไร |
|---|---|---|
| `/admin/**` 28 route + `/object-management` | spec: desktop only · Konva/canvas editor, dnd-kit, ตาราง `min-w-[900px]`+ | ไม่มีทางเข้าในแอป · ถ้าเปิด URL ตรง → หน้า "เปิดบน desktop" · **แก้ 2026-10-02 (โน้ต Pai): ไม่มีหน้า desktop-only · เปิด URL ตรง → Space builder + toast → ux-ui-plan §19** |
| `/workspace/builder/[id]` (member เรียก admin editor) | `hero-workspace-editor.tsx` 21.7k บรรทัด canvas editor | ซ่อนปุ่ม Build/Edit บนมือถือ · route → "เปิดบน desktop" |
| `/workspace/preview/[id]` (member เรียก admin editor readOnly) | เดียวกัน | ซ่อนปุ่ม Preview · ใช้ `/workspace/[id]` lobby แทน |
| `/dev/**` 2 route | dev only | ไม่มี |
| Screen share **เริ่มแชร์** | WebView ไม่มี `getDisplayMedia` | ซ่อนปุ่ม · Phase 3 native |
| Outside display / Mini Mode / Auto-PiP | Chromium desktop only | ปิดเอง (feature-check) |
| Private zone **decorate mode** (drag วาง object) | HTML5 drag + shortcuts | Phase 3 · claim/unclaim ยังทำได้ |
| Map Editor ทุกอย่าง | admin | — |

## K. ลำดับทำ (ไม่ต้องรอ UI ก่อน)

| ลำดับ | ทำอะไร | หน้าที่กระทบ | อ้างอิง task |
|---|---|---|---|
| 1 | flag `NEXT_PUBLIC_MOBILE_VO` + ซ่อน route admin/editor บนมือถือ (J) | ทุกหน้า | 0.1 |
| 2 | joystick + tap-to-walk + แยก gesture | C canvas | 0.3, 0.4 |
| 3 | performance: DPR cap, name tag, culling, context-loss, init race | C canvas | 0.9 (+G1, G7) |
| 4 | safe-area + `dvh` + body scroll lock helper + outside-click → pointerdown helper + `lib/platform.ts` | ทุกหน้า | 0.2 (+S5, C6, C7) |
| 4b | mode setting (`zyra_workspace_mode` day/always) + `useDeviceOrientation()` + หน้า Rotate (ทับ Spatial ด้วย `setRenderSuspended`) + route Lite ที่ไม่ mount engine | C (ทุกหน้าใน VO) | 0.12, 0.13, 0.15 (TD §16) |
| 4c | zyra-ws: ghost client (`client_mode: lite` ไม่มี position, join meeting by id) + client Spatial ไม่ render avatar ghost | — (server + C) | 0.16 (TD §16.2) |
| 5 | `playsInline` ×6, `isComposing`, OTP one-time-code, speaker picker ซ่อน iOS | B, D, E, A | (C8, C9, C11) |
| 6 | Playwright mobile project + Sentry/Mixpanel tag | — | 0.10, 0.11 |
| 7 | zyra-ws grace period + restore sitting | — (server) | §12.3 |
| **รอ UI** | HUD toolbar/sidebar/minimap, panel → bottom sheet, chat stack, meeting tiles (portrait + landscape), modal ทุกตัวที่ ≥ 458px, onboarding/create-workspace flow, splash/offline, **Lite shell bottom nav 4 เมนู + หน้าใน Home/Calendar/Profile tab** | C, D, E, F, G, H, I, Lite shell | 0.5–0.7, 0.14 |
