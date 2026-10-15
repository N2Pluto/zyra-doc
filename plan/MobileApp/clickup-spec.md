# Mobile App — ClickUp Spec (SC-MOB-01 ถอดครบทุก subtask)

> **สถานะ:** ถอดจาก ClickUp ครบ 2026-09-30 · task หลัก `pending` · HP-01, EC-01 `Closed` · HP-11 `Open` (เพิ่ม 2026-09-30 11:48) · ที่เหลือ `pending` · **UI Figma มีแล้วแต่จะได้รับภายหลัง** — ยังไม่ดึง spec จาก Figma
> **ที่มา:** [Feature · Mobile Responsive + App Conversion (iOS & Android)](https://app.clickup.com/t/86d4bfpym) · สร้าง 2026-09-16 11:20 · แก้ล่าสุด 2026-09-30 10:34 · **due 2026-10-02** · priority High · assignee: P A (pai), Ponlawat (ten_dev), rif · custom field Mobile ✅ (Desktop/Tablet ไม่ติ๊ก) · ไม่มี attachment/checklist/dependency
> **เอกสารคู่กัน:** [spec.md](spec.md) (มติของเรา) · [screens.md](screens.md) · [technical-design.md](technical-design.md) · §18 ท้ายไฟล์นี้ = จุดที่ ClickUp ต่างจากโค้ดจริง/มติ

## 0. Task หลัก — SC-MOB-01 · Mobile Responsive + App Conversion — Project Zyra

- **Module:** Platform — Project Zyra · **Persona:** Workspace Member (mobile user) · **Priority:** High
- **Overview & Goal:** ทำให้ Zyra ใช้งานได้บน **iOS และ Android** แบบ full feature parity กับ web — ครอบคลุม Virtual Office, Meeting, Chat, Dashboard และทุก feature ที่มีอยู่
- **2 deliverables:** (1) **Mobile Responsive Web** — web ที่ใช้งานได้บน mobile browser (2) **Mobile App** — install บน iOS/Android (approach TBD → ดู HP-01)
- **Data Model:** ไม่มี data model เพิ่ม — เป็น presentation layer
- **Tech Comparison (สำหรับ HP-01)**

| Approach | Pro | Con | เหมาะถ้า |
|---|---|---|---|
| PWA | เร็ว, ไม่ต้อง App Store, ใช้ codebase เดิม | Push notification iOS จำกัด, ไม่ได้ native feel | Budget จำกัด, ต้องการเร็ว |
| Capacitor | ใช้ web code เดิม + native APIs, App Store ได้ | Build complexity, performance ไม่เท่า native | **แนะนำ — best of both worlds** |
| React Native | Native performance, native UI | ต้อง rewrite ทั้งหมด, expensive | ถ้าต้องการ full native |
| Flutter | Native performance, cross-platform | Dart language, rewrite ทั้งหมด | ถ้าต้องการ native อนาคต |

### Subtask ทั้งหมด (16)

| # | Subtask | Type | Priority | Status | ClickUp |
|---|---|---|---|---|---|
| HP-01 | Tech Approach Decision (PWA vs Capacitor vs React Native) | Happy Path (Decision) | urgent | **Closed** (2026-09-29) | [86d4bfq3c](https://app.clickup.com/t/86d4bfq3c) |
| HP-02 | Mobile Responsive — Layout & Breakpoints | Happy Path | high | pending | [86d4bfq5y](https://app.clickup.com/t/86d4bfq5y) |
| HP-03 | Mobile Responsive — Virtual Office (Map + Avatar) | Happy Path | high | pending | [86d4bfq88](https://app.clickup.com/t/86d4bfq88) |
| HP-04 | Mobile Responsive — Meeting (Video/Audio) | Happy Path | high | pending | [86d4bfqcg](https://app.clickup.com/t/86d4bfqcg) |
| HP-05 | Mobile Responsive — Chat | Happy Path | high | pending | [86d4bfqeg](https://app.clickup.com/t/86d4bfqeg) |
| HP-06 | Mobile Responsive — Sidebar & Navigation | Happy Path | high | pending | [86d4bfqge](https://app.clickup.com/t/86d4bfqge) |
| HP-07 | App Conversion — Install & Onboarding | Happy Path | high | pending | [86d4bfqkp](https://app.clickup.com/t/86d4bfqkp) |
| HP-08 | App — Push Notifications (Meeting, Chat, Spotlight, Alerts) | Happy Path | high | pending | [86d4bfqq2](https://app.clickup.com/t/86d4bfqq2) |
| HP-09 | App — Camera & Microphone Permissions | Happy Path | high | pending | [86d4bfquk](https://app.clickup.com/t/86d4bfquk) |
| HP-10 | App — Offline / Poor Connection Handling | Happy Path | normal | pending | [86d4bfqy7](https://app.clickup.com/t/86d4bfqy7) |
| HP-11 | Mobile Responsive — Spotlight (Presenter + Viewer) | Happy Path | high | **Open** (ใหม่ 2026-09-30) | [14zd0zua7x9](https://app.clickup.com/t/14zd0zua7x9) |
| EP-01 | Virtual Office บน Mobile — Performance Fallback | Error Path | high | pending | [86d4bfr08](https://app.clickup.com/t/86d4bfr08) |
| EP-02 | Meeting Video บน Mobile — Bandwidth ต่ำ / Audio-Only Fallback | Error Path | high | pending | [86d4bfr1r](https://app.clickup.com/t/86d4bfr1r) |
| EC-01 | Features ที่ Mobile ทำได้จำกัด — Bowncer Only Features (Phaser.js Constraints) | Edge Case | normal | **Closed** (2026-09-28) | [86d4bfr33](https://app.clickup.com/t/86d4bfr33) |
| EC-02 | iOS Safari WebRTC Limitations — Capacitor App แก้ไขได้ | Edge Case | normal | pending | [86d4bfr5a](https://app.clickup.com/t/86d4bfr5a) |
| EC-03 | Screen Size หลากหลาย — Small Phone vs Tablet vs iPad | Edge Case | normal | pending | [86d4bfr8j](https://app.clickup.com/t/86d4bfr8j) |

Comment บน task หลัก: ไม่มี · Comment มีที่ HP-02 และ HP-06 (จาก P A, ดูใน section นั้น)

---

## 1. HP-01 · Tech Approach Decision (PWA vs Capacitor vs Native) — Closed

- **Type:** Happy Path (Decision Task) · **Persona:** Tech Lead / PM · **Pre-condition:** ต้องตัดสินใจก่อน dev เริ่ม
- **Overview:** Decision Task ไม่ใช่ feature — PM และ Tech Lead ต้องตัดสินใจ approach ก่อน เพราะกระทบ architecture ทั้งหมด

**Option A: PWA ⭐ เร็วที่สุด** — ทำอะไร: manifest.json + Service Worker · "Add to Home Screen" · Push (Android ได้, iOS ≥ 16.4 ได้บางส่วน) · Offline บางส่วน · ข้อดี: codebase เดิม 100%, ไม่ต้องผ่าน App Store review, update instant, เร็วสุด (2–4 สัปดาห์) · ข้อเสีย: iOS Safari push จำกัด + WebRTC บางอย่างไม่รองรับ, ไม่ได้ native feel, camera/mic permission flow ต่างจาก native

**Option B: Capacitor ⭐⭐ แนะนำ** — ทำอะไร: wrap web app เป็น native shell · deploy App Store + Google Play · native APIs: Camera, Push, File, Haptics · ข้อดี: web codebase เดิม 80–90%, อยู่ใน store น่าเชื่อถือ/discoverable, native push ทั้งสอง OS, camera/mic stable กว่า, 4–8 สัปดาห์ · ข้อเสีย: manage 2 release channels (App Store + web), App Store review 7–14 วันครั้งแรก, **Phaser.js performance ต้องทดสอบบน device จริง**

**Option C: React Native / Flutter ❌ ไม่แนะนำตอนนี้** — rewrite ส่วนใหญ่, 3–6 เดือน+, ทีมต้องเรียนรู้เพิ่ม, Phaser.js ไม่รองรับใน RN → พิจารณาระยะยาวเท่านั้น

**Recommendation ใน ClickUp:** Phase 1 (ทันที) Mobile Responsive Web → Phase 2 (1–2 เดือน) PWA installability + offline → Phase 3 (3–4 เดือน) Capacitor native app + push + native APIs

**Acceptance Criteria:** PM + Dev review comparison และตัดสินใจ approach · Document decision ใน ADR · กำหนด timeline ต่อ phase · ตัดสินใจ: ใช้ Capacitor หรือ PWA ก่อน

**Key Questions ที่ต้องตอบก่อนตัดสินใจ:** (1) VO บน mobile ต้องใช้ Phaser.js (2D map) ไหม หรือ simplified view (2) ต้องการให้ค้นหาใน App Store ได้ไหม (3) ต้องการ native push ไหม (4) มี budget/timeline สำหรับ Capacitor build ไหม

> **สถานะจากฝั่งเรา:** ตอบครบแล้วใน [spec.md](spec.md) — Capacitor + native feature จริง, Full VO (PixiJS ไม่ใช่ Phaser), ขึ้น store ทั้งสอง, push native · ADR = technical-design.md · timeline ต่อ phase = task-breakdown.md · เราข้าม Phase 2 (PWA) ไป Capacitor ตรง แต่ Phase 0 ของเรา = "Mobile Responsive Web" ของ ClickUp

## 2. HP-02 · Mobile Responsive — Layout & Breakpoints

- **Persona:** Workspace Member บน mobile browser · **Pre-condition:** เปิด Zyra บน iOS Safari / Android Chrome

**Breakpoints**

| ชื่อ | ช่วง | อุปกรณ์ |
|---|---|---|
| Mobile S | 320–374px | iPhone SE, small Android |
| Mobile M | 375–767px | iPhone 14, Pixel — **primary target** |
| Tablet | 768–1023px | iPad, Android tablet |
| Desktop | 1024px+ | เดิม |

**Layout Rules — Mobile (375–767px)**
- Navigation: Sidebar ซ่อน → **bottom navigation bar (5 icons)** · Header compact — workspace name + avatar icon + hamburger
- Content: full width 100vw ไม่มี sidebar ค้าง · font body min 14px, **input 16px** (กัน iOS auto-zoom) · **touch target min 44×44px** (Apple HIG) · padding 16px horizontal
- Virtual Office: map full screen (**แนะนำ landscape**) · HUD ย้ายลงล่างเหนือ safe area (notch-aware)
- Meeting: video tiles stack แนวตั้ง หรือ 2 columns · controls bottom bar เหนือ home indicator
- Chat: full screen message view · keyboard-aware scroll
- Sidebar widgets (Tarot, Participation): bottom sheet แทน side panel

**Layout Rules — Tablet (768–1023px)**
- Sidebar แสดง icon-only (collapsed) ด้านซ้าย · main content full width ที่เหลือ · VO ใช้งานได้ปกติ (landscape preferred)

**Acceptance Criteria**
- [ ] Breakpoints ครบ 4 ระดับ
- [ ] ไม่มี horizontal scroll บน mobile (ยกเว้น overflow ที่ตั้งใจ)
- [ ] Touch targets ≥ 44×44px ทุก interactive element
- [ ] Font size input ≥ 16px
- [ ] Safe area: notch, Dynamic Island, home indicator ด้วย `env(safe-area-inset-*)`
- [ ] Orientation: รองรับทั้ง Portrait และ Landscape
- [ ] Viewport meta: `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`

**Comment (P A, 2026-09-21 15:44) — ค่าจริงจาก Figma ปัจจุบัน:**
- Mobile ขนาดเล็กสุดที่ใช้ตาม Figma = **iPhone 13 & 14 (390×844)**
- ตัวอักษร: ปกติ **14px** · เล็กสุด **10px** · ใหญ่สุด **24px**
- ปุ่ม: ใหญ่ **42×42** · กลาง **32×32** · เล็กสุด **24×24**
- Field สูง **42px**

> ⚠️ ขัดกับ AC: ปุ่ม 42/32/24 < 44px และ font เล็กสุด 10px < 14px · ต้องเคลียร์กับ design/PM (ดู §18)

## 3. HP-03 · Mobile Responsive — Virtual Office (Map + Avatar)

- **Pre-condition:** เข้า VO บน mobile
- **Steps:** เปิด VO → map เต็มจอ (full screen canvas) → เดินด้วย **virtual joystick (on-screen D-pad)** หรือ **tap-to-move** → HUD ด้านล่าง (safe area aware) → interact ด้วย tap บน object / avatar

**Acceptance Criteria**
- [ ] Canvas ปรับ resolution ตาม screen size (devicePixelRatio)
- [ ] Virtual D-Pad: **ซ้ายล่าง ขนาด 100×100px**
- [ ] Tap-to-move: tap บน map → avatar เดินไป (ถ้า walkable)
- [ ] Pinch-to-zoom (ถ้า map ใหญ่)
- [ ] **Double-tap: center camera บน avatar ตัวเอง**
- [ ] Tap avatar คนอื่น → profile popup
- [ ] Tap objects: interact (เข้า room, หยิบ item)
- [ ] Landscape mode: banner แนะนำให้หมุนจอ
- [ ] Performance: **FPS ≥ 30 บน mid-range (iPhone 12, Pixel 5)**
- [ ] Memory: ไม่ crash จาก memory overload ใน **30 นาที**

**Landscape Mode Banner:** "📱 หมุนจอเพื่อประสบการณ์ที่ดีขึ้น — Virtual Office ดูได้ดีกว่าในแนวนอน [เข้าใจแล้ว]"

> ⚠️ มติ 2026-09-30 (ยืนยันจาก Figma HP-03): **ผู้ใช้เลือก Lite / Spatial เองที่หน้า Select workspace mode และเปลี่ยนใน Settings เท่านั้น** · Lite = แนวตั้ง ไม่โหลดแมพ · Spatial = แนวนอน · ถือผิด orientation → หน้าเต็มจอ "Rotate your phone to use … Mode." — banner นี้ไม่มีแล้ว (ดู §18 ข้อ 25, technical-design §16, ux-ui-plan §3.4–3.5)

**Performance Targets (Mobile)**

| Metric | Target |
|---|---|
| FPS | ≥ 30 fps (mid-range device) |
| Initial load | ≤ 5 วินาที (4G) |
| Memory usage | **≤ 200MB** |
| Battery drain | ≤ 15%/ชั่วโมง |

**Figma:** [node 6379-34977](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6379-34977) · [node 6511-44108](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6511-44108)

## 4. HP-04 · Mobile Responsive — Meeting (Video/Audio)

- **Steps:** join meeting → video tiles ปรับ layout ตาม screen → controls (mic, camera, share, leave) bottom bar → swipe ซ้าย/ขวาดู participants เพิ่ม

**Acceptance Criteria**
- [ ] Portrait: active speaker ใหญ่ + thumbnail strip ด้านล่าง
- [ ] Landscape: side-by-side grid (2–3 tiles)
- [ ] Swipe: scroll thumbnail strip แนวนอน
- [ ] Tap tile: สลับ active speaker
- [ ] Controls bar: bottom safe area, icon ≥ 44px
- [ ] Self-view: draggable PiP ไม่บัง content
- [ ] Mic/Camera: **haptic feedback** เมื่อ mute/unmute
- [ ] Screen share: mobile แสดง shared screen ได้ แต่ share จาก mobile อาจจำกัด (ดู EC-02)
- [ ] Background blur: optional (ขึ้นกับ device capability)
- [ ] **Battery warning: battery < 20% ขณะ meeting → "🔋 แบตเตอรี่ต่ำ ควรชาร์จ"**

**Figma:** [node 6111-125216](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6111-125216) · [node 6511-139220](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6511-139220)

## 5. HP-05 · Mobile Responsive — Chat

- **Steps:** กด Chat icon บน bottom nav → chat list เต็มจอ → เลือก channel → message view เต็มจอ → keyboard เปิด list เลื่อนขึ้น → พิมพ์และส่ง

**Acceptance Criteria**
- [ ] Chat list: **swipe left → archive/mute channel**
- [ ] Keyboard-aware scroll
- [ ] Input: min-height 44px, grows with multiline
- [ ] ส่งด้วย return key หรือ send button
- [ ] Emoji picker: native emoji keyboard หรือ custom picker
- [ ] Media: tap รูป → full screen preview (pinch-to-zoom)
- [ ] **Long press message → context menu: Reply, React, Copy, Delete**
- [ ] Mention: `@` → member suggestion list
- [ ] Unread badge: tab icon + channel list
- [ ] **Pull-to-refresh: load older messages**

**Figma:** [node 6351-578634](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6351-578634) · [node 6547-591562](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6547-591562)

## 6. HP-06 · Mobile Responsive — Sidebar & Navigation

- **Steps:** desktop sidebar ถูกแทนด้วย **Bottom Navigation Bar** → กด icon navigate → workspace switcher: กด workspace name บน header → bottom sheet แสดง workspace list

**Acceptance Criteria**
- [ ] Bottom navigation: **4 items (Home, Chat, Calendar, Profile)**
- [ ] Active state: icon + label สีตาม theme, underline indicator
- [ ] "More" → bottom sheet พร้อม drag-to-dismiss
- [ ] Bottom sheet: สูงสุด 70vh, scroll ได้
- [ ] Workspace switcher: กด workspace name บน header
- [ ] Back navigation: swipe right (iOS) หรือ back button (Android)
- [ ] Badge: unread count บน Chat icon
- [ ] Haptic feedback: กด navigation items
- [ ] Safe area: bottom nav เหนือ home indicator (`env(safe-area-inset-bottom)`)

**Comment (P A, 2026-09-21 16:00):** Bottom bar ตอนนี้มี **4 เมนู: Home, Chat, Calendar, Profile** · Active state: **activate ที่ icon ไม่มี text**

> ⚠️ HP-02 บอก 5 icons, HP-06 + comment บอก 4 · AC บอก "icon + label" แต่ comment บอก "ไม่มี text" · **Calendar ยังไม่มีในโค้ด zyra-app** (ดู §18)

**Figma:** [node 6377-27023](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6377-27023) · [node 6604-246256](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6604-246256)

## 7. HP-07 · App Conversion — Install & Onboarding

- **Persona:** New mobile user · **Pre-condition:** app พร้อมบน App Store / Google Play (Capacitor) หรือ PWA install prompt

**Steps — PWA Install:** เปิดบน Chrome/Safari → หลังเยี่ยมชม 2+ ครั้ง แสดง install banner "Add Zyra to Home Screen" → Install → icon บน home screen → เปิดแบบ full screen
**Steps — Capacitor App:** ค้นหา "Zyra" ใน store → install → **Splash (Zyra logo, animated)** → Login / Sign up → **Onboarding 3 slides** ("Virtual Office", "Meeting", "Team Chat") → Select / Create Workspace → เข้า VO

**Splash Screen:** logo 🌐 Zyra + tagline "Virtual Office for Modern Teams" + loading spinner · **Duration 2 วินาที → Login screen**

**Onboarding Slides (3 หน้า)**
1. Virtual Office — 🏢 "ออฟฟิศเสมือนจริง สำหรับทีมของคุณ" [illustration: VO map]
2. Meeting — 🎙 "ประชุมพร้อม AI Meeting Summary" [illustration: video call]
3. Team Features — 🌟 "Quiz, Poll, Tarot ทีมของคุณจะสนุกกว่าเดิม" [illustration: features collage]
- ปุ่ม [Skip] / [ถัดไป →] / [เริ่มใช้งาน] · dots pagination ● ○ ○

**Acceptance Criteria — PWA**
- [ ] Install prompt หลัง 2 visits + engagement threshold
- [ ] Manifest: name, short_name, icons 192/512, theme_color, display standalone
- [ ] Splash จาก manifest icons
- [ ] Start URL: `/` หรือ last visited workspace

**Acceptance Criteria — Capacitor App**
- [ ] Splash animated 2 วินาที
- [ ] Onboarding 3 slides, skip ได้, dots
- [ ] Login: Email/Password + Social login (Google ถ้ามี)
- [ ] Deep link: `zyra://workspace/{id}`
- [ ] App version ใน Settings → About
- [ ] Auto-update check: แจ้งเมื่อมี update ใหม่

**App Store Requirements**
- iOS: Bundle ID **`com.zyra.app`** · category Business / Productivity · screenshots 6.7", 6.1", iPad (required) · Privacy policy URL · Support URL
- Google Play: package **`com.zyra.app`** · content rating Everyone · screenshots phone + tablet · feature graphic 1024×500

> **มติ (Ten 2026-10-01):** bundle id iOS + package Android = **`co.zyraworld.app`** (ไม่ใช้ `com.zyra.app`) · ชื่อแอป **Zyra World** · ไอคอน logo ตัว Z — ดู §18 ข้อ 6

**Figma:** [node 6663-237832](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6663-237832)

## 8. HP-08 · App — Push Notifications (Meeting, Chat, Spotlight, Alerts)

- **Steps:** เปิดครั้งแรก → request notification permission → อนุมัติ → register device token → server ส่ง push เมื่อมี event → กด notification → deep link เข้า context นั้น

**Notification Types**

| Event | Title | Body |
|---|---|---|
| Meeting Alert 5 min | "⏰ Weekly Sync" | "เริ่มในอีก 5 นาที" |
| Meeting Started | "🎙 Weekly Sync เริ่มแล้ว" | "มี 3 คนรออยู่" |
| Chat Mention | "💬 Alice mentioned you" | "@Bob ช่วยดูด้วยนะ" |
| Chat DM | "💬 Alice" | "มีเวลาคุยไหม?" |
| Spotlight | "⭐ Bob กำลัง Present" | "Stage A — Q3 Review" |
| Weather Alert | "⚠️ ประกาศเตือนภัย" | "พายุฝนฟ้าคะนอง กรุงเทพฯ" |

**Acceptance Criteria**
- [ ] Permission request **หลัง onboarding เสร็จ** (ไม่ prompt ทันที)
- [ ] Denied: in-app notification แทน ไม่ crash
- [ ] Device token register พร้อม platform (iOS/Android)
- [ ] Grouping: notifications จาก channel เดียวกัน group รวม
- [ ] Silent notification: update badge count ไม่มี sound/banner
- [ ] Background: รับได้แม้ app ปิด
- [ ] Notification settings: user เลือกประเภทได้
- [ ] เคารพ system Do Not Disturb

**Push service:** iOS APNs · Android FCM · server: event → notification service → push ไป device token · Capacitor plugin `@capacitor/push-notifications` · PWA: Web Push API (Chrome/Edge/Firefox, Safari iOS 16.4+)

**Figma:** [node 6411-1141652](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6411-1141652) · [node 6610-253136](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6610-253136)

## 9. HP-09 · App — Camera & Microphone Permissions

- **Steps:** join meeting ครั้งแรก → request Camera + Microphone → อนุมัติ → ปกติ · ปฏิเสธ → เข้าได้แต่ไม่มี camera/mic
- **Permission dialog (iOS system, customize ไม่ได้):** "Zyra ต้องการเข้าถึงกล้อง เพื่อให้คนอื่นในการประชุมเห็นคุณ [ไม่อนุญาต] [อนุญาต]"

**Permission States**

| State | Camera | Mic | UX |
|---|---|---|---|
| Granted | ✅ | ✅ | Meeting ปกติ |
| Camera denied | ❌ | ✅ | Join ได้ ไม่มีกล้อง + banner |
| Mic denied | ✅ | ❌ | Join ได้ ไม่มีเสียง + banner |
| Both denied | ❌ | ❌ | Join ได้ แต่ View Only mode |
| Not determined | — | — | Prompt ทันทีก่อน join |

**Acceptance Criteria**
- [ ] Request permission ก่อน join ครั้งแรก
- [ ] Denied: ไม่ crash — graceful degradation
- [ ] Banner: "📹 กล้องไม่ได้รับอนุญาต — [เปิดใน Settings]"
- [ ] Deep link ไป app settings โดยตรง
- [ ] iOS: เคยปฏิเสธ → ต้องเปิดใน Settings เอง (prompt ซ้ำไม่ได้)
- [ ] **Background audio: meeting audio ต่อเมื่อ switch app (iOS Audio Session)**
- [ ] **Screen lock: meeting audio ยังทำงานเมื่อ lock**

**iOS Specific:** Info.plist `NSCameraUsageDescription: "Zyra ใช้กล้องเพื่อ Video Meeting"`, `NSMicrophoneUsageDescription: "Zyra ใช้ไมค์เพื่อ Voice/Video Meeting"` · Audio Session background: `AVAudioSessionCategoryPlayAndRecord` + `AVAudioSessionModeVoiceChat`
**Android Specific:** `CAMERA`, `RECORD_AUDIO`, `FOREGROUND_SERVICE`

**Figma:** [node 6450-67121](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6450-67121)

## 10. HP-10 · App — Offline / Poor Connection Handling

**Connection States**

| State | Indicator | Behavior |
|---|---|---|
| Online | ✅ (ไม่แสดง) | ปกติ |
| Poor connection | 🟡 "สัญญาณอ่อน" | ลด video quality |
| Offline | 🔴 "ไม่มีสัญญาณ" | แสดง cached content |
| Reconnecting | ⏳ "กำลังเชื่อมต่อ..." | retry อัตโนมัติ |

**Offline Behavior ต่อ Feature**

| Feature | Online | Offline |
|---|---|---|
| Virtual Office | ✅ | ❌ แสดง "ต้องการ connection" |
| Meeting | ✅ | ❌ disconnect อัตโนมัติ |
| Chat | ✅ | ⚠️ อ่าน cached ได้, ส่งไม่ได้ |
| Calendar | ✅ | ⚠️ แสดง events ที่ cache |
| Tarot History | ✅ | ⚠️ แสดง history ที่ cache |

**Poor Connection (Meeting):** auto-reduce 720p → 480p → 360p → audio only · banner "🟡 สัญญาณอ่อน — ลด video quality อัตโนมัติ" · audio-only แสดง avatar แทนกล้อง · Disconnect: reconnect อัตโนมัติ **5 ครั้ง** → ถ้า fail "การประชุมถูกตัดการเชื่อมต่อ — [เชื่อมต่อใหม่]"

**Acceptance Criteria**
- [ ] Network status monitor real-time
- [ ] Status banner ด้านบนเมื่อ connection เปลี่ยน
- [ ] WebSocket auto-reconnect เมื่อ network กลับ
- [ ] Chat offline: อ่าน cache ได้, **queue messages ที่ส่งไม่ได้**
- [ ] Chat reconnect: ส่ง queued messages
- [ ] Meeting adaptive quality ตาม bandwidth
- [ ] VO: error state graceful ไม่ crash
- [ ] PWA/App: **cache static assets ด้วย Service Worker**

**Network indicator (header mobile):** ✅ online ไม่แสดง · 🟡 สัญญาณอ่อน · 🔴 ออฟไลน์ · ⏳ กำลังเชื่อมต่อ

**Figma:** [node 6462-71727](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6462-71727)

## 11. HP-11 · Mobile Responsive — Spotlight (Presenter + Viewer) — Open (ใหม่ 2026-09-30)

- **Pre-condition:** map มี Spotlight marker · รองรับ 2 role: Presenter (เดินเข้า zone → ขึ้น Stage) และ Viewer

**Scenario A — Presenter:** เดินเข้าใกล้ marker (2 tiles) → prompt บน HUD ล่าง **"⭐ แตะเพื่อขึ้น Stage"** → tap ปุ่ม HUD หรือ tap marker → **confirmation bottom sheet** "ขึ้น Stage A? [ขึ้น Stage] [ยกเลิก]" → session เริ่ม → Spotlight Presenter HUD (Mobile)
**Scenario B — Viewer ไม่อยู่ใน Meeting:** session เริ่ม → **full screen Spotlight view เปิดทันที** (กล้อง presenter / screen share + chat panel)
**Scenario C — Viewer อยู่ใน Meeting:** toast บน Meeting HUD มุมขวาบน compact "⭐ Bob กำลัง Present — Stage A [ดู] [เดี๋ยวก่อน]" → กด "ดู" → **second session เป็น bottom sheet half-screen** (ไม่ full screen) → meeting ยังทำงาน ได้ยิน audio meeting
**Multiple Spotlight:** horizontal scroll tabs ด้านบน "⭐ Stage A (Bob) | ⭐ Stage B (Alice)"

**Acceptance Criteria — Presenter:** prompt บน HUD ล่าง · confirmation เป็น bottom sheet · HUD compact "⭐ LIVE" + viewer count + ปุ่มออก · controls [🎤][📹][📺 screen share][💬] ≥ 44px
**AC — Viewer not in meeting:** full screen เปิดทันทีไม่ confirm · portrait: video เต็มจอ + chat bar ล่าง · landscape: split (video ซ้าย chat ขวา) · ปุ่ม "กลับ Virtual Office" มุมขวาบน ≥ 44px · **swipe down → mini bar ยังดูต่อได้**
**AC — Viewer in meeting:** toast ไม่บัง tiles, สูง ≤ 80px · "ดู" → bottom sheet drag-to-dismiss, สูง 40–60vh ปรับได้ · meeting audio ยังได้ยิน · spotlight audio muted เหมือน web (audio isolation)
**AC — Multiple:** tabs ด้านบน · swipe ซ้าย/ขวาสลับ
**AC — Screen Share (Mobile Presenter):** iOS ReplayKit → system dialog "เริ่ม Screen Recording" · Android MediaProjection · ถ้า share ไม่ได้ (browser) → "Screen Share รองรับเฉพาะแอป Zyra" + download link · meeting screen share ถูกปิด → toast เหมือน web

**Mobile vs Web**

| Feature | Web | Mobile |
|---|---|---|
| Enter prompt | "กด E" | "แตะเพื่อขึ้น Stage" |
| Confirmation | Modal กลางจอ | Bottom sheet |
| Second session | Split view | Bottom sheet 40–60vh |
| Multiple spotlight | Tab switcher ล่าง | Horizontal tabs บน |
| Swipe down | ไม่มี | ย่อเป็น mini bar |
| Screen share | Browser API | ReplayKit / MediaProjection |

**Figma:** ไม่มีลิงก์ใน task นี้

## 12. EP-01 · Virtual Office บน Mobile — Performance Fallback

- **Trigger:** VO map ทำให้ FPS < 20 บน low-end mobile · **Steps:** low-end Android (2GB RAM) → canvas render map + avatars + animations → FPS < 20 ต่อเนื่อง **10 วินาที** → performance mode

**Performance Fallback Levels**

| Level | เงื่อนไข | ทำอะไร |
|---|---|---|
| 0 | FPS ≥ 30 | ปกติ full quality |
| 1 | FPS < 30 | ลด canvas resolution (DPR 2 → 1) |
| 2 | FPS < 25 | ปิด Nature animations (ใบไม้หยุดสั่น) + ปิด Weather particles |
| 3 | FPS < 20 | ลด avatar animation fps (12 → 6) + ปิด Time of Day overlay |
| 4 | FPS < 15 | **Simple mode** — static map + dots แทน avatars |

**Acceptance Criteria**
- [ ] FPS monitor ทุก 5 วินาที บน mobile
- [ ] Auto fallback ตาม level
- [ ] Toast "⚡ ลด visual effects เพื่อ performance" (1 ครั้ง)
- [ ] Simple mode: colored dots + ชื่อ แทน sprite
- [ ] Settings: "Mobile Performance Mode" toggle (เปิด Level 3 ทันที)
- [ ] User restore: Settings → Visual Effects → "เปิด effects เต็ม"
- [ ] Memory warning: RAM available < 200MB → เตือน

**Simple Mode (Level 4):** map thumbnail/simplified · avatars = colored circle dots + ชื่อ · ไม่มี animation · tap-to-move ยังทำงาน · Chat/Meeting ปกติ

**Figma:** [node 6471-172948](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6471-172948) · [node 6662-204168](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6662-204168)

## 13. EP-02 · Meeting Video บน Mobile — Bandwidth ต่ำ / Audio-Only Fallback

- **Trigger:** join meeting บน 2G/3G/ขอบ 4G

**Bandwidth Thresholds**

| Bandwidth | Quality | Action |
|---|---|---|
| > 2 Mbps | 720p HD | ปกติ |
| 1–2 Mbps | 480p | Auto-reduce |
| 500kbps–1Mbps | 360p | Auto-reduce + banner |
| 200–500kbps | Audio only + avatar | Auto-switch |
| < 200kbps | Audio only (compressed) | Warning |

**Steps:** join บน 3G → LiveKit SFU detect bandwidth → auto-reduce → < 500kbps switch audio-only → banner "📶 สัญญาณอ่อน — เปลี่ยนเป็น Audio Mode"

**Acceptance Criteria**
- [ ] Adaptive bitrate ผ่าน LiveKit SFU
- [ ] Audio-only fallback เมื่อ < 500kbps
- [ ] Banner แจ้งเมื่อ quality ลด
- [ ] Manual override: ปุ่ม "เปิด Video" force
- [ ] Bandwidth ดีขึ้น → offer "เปิด Video อีกครั้งไหม?"
- [ ] Network indicator 1–4 bars บน meeting HUD
- [ ] Echo cancellation เปิดเสมอบน mobile

**LiveKit Mobile Settings:** videoBitrate adaptive 200kbps–2Mbps · audioBitrate 32kbps · echoCancellation/noiseSuppression/autoGainControl true · dynacast true

**Figma:** [node 6471-172948](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6471-172948) · [node 6662-61731](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6662-61731)

## 14. EC-01 · Features ที่ Mobile ทำได้จำกัด — Closed

| Feature | Web Desktop | Mobile | Solution |
|---|---|---|---|
| Space Builder | drag-drop objects บน map | ยาก (touch ไม่แม่น) | disable บน mobile |
| Admin Map Editor | เต็ม features | จำกัดมาก | Desktop only (redirect) |
| Object Composer | วาง furniture | จำกัด | Desktop only |

**Acceptance Criteria:** desktop-only → banner "ฟีเจอร์นี้ใช้งานได้บน Desktop เท่านั้น" + **QR code** เปิดบน desktop + copy link · Space Builder บน mobile → redirect หรือ read-only preview · Admin Map Editor → "กรุณาใช้บน Desktop" · **ไม่มี feature ที่ crash silently — graceful fallback เสมอ**

> **แก้ 2026-10-02 (โน้ต Pai + Ten): ไม่มีหน้า banner/QR — ซ่อนเมนู · เปิด URL ตรง → Space builder + toast "This page is available on desktop only." (ux-ui-plan §19.6) · ต่างจาก AC ข้างบน ต้องแจ้ง PM**
> ตรงกับมติ "mobile ไม่ทำ admin" ใน [screens.md](screens.md) §J · เพิ่มเติมจาก ClickUp: ต้องมี QR code ในหน้า desktop-only

## 15. EC-02 · iOS Safari WebRTC Limitations — Capacitor App แก้ไขได้

| Limitation | Impact | Solution |
|---|---|---|
| Background WebRTC | audio หยุดเมื่อ switch app | Capacitor + AudioSession |
| Screen Share | ต้อง ReplayKit ผ่าน native | web: ไม่รองรับ iOS Safari |
| Push | Safari iOS < 16.4 ไม่รองรับ Web Push | Capacitor app |
| getUserMedia | ต้อง user gesture ก่อน | ปุ่ม "Join" ก่อน request |
| Multiple AudioContext | อาจ conflict กับ game engine | single AudioContext |

**Acceptance Criteria**
- [ ] iOS Safari: banner "บางฟีเจอร์ทำงานได้ดีกว่าในแอป Zyra"
- [ ] Meeting background: เตือน "iOS Safari อาจตัดเสียงเมื่อเปลี่ยนแอป — ใช้แอป Zyra"
- [ ] Screen share บน iOS Safari: ซ่อนปุ่มหรือ "ต้องใช้แอป Zyra"
- [ ] Push บน Safari iOS < 16.4: in-app notification แทน
- [ ] getUserMedia หลัง user กด "Join Meeting" เสมอ
- [ ] **iOS Smart App Banner** `<meta name="apple-itunes-app" content="app-id=XXXXXXX, app-argument=zyra://deep-link">` แสดง "[Zyra icon] Zyra — HPK Technology [เปิดแอป]"

**Capacitor vs iOS Safari:** Video Call ✅/✅ · Background Audio ✅/⚠️ · Screen Share ✅ ReplayKit/❌ · Push ✅ APNs/✅ iOS 16.4+ · VO ✅/✅ (performance ต่ำกว่า)

## 16. EC-03 · Screen Size หลากหลาย — Small Phone vs Tablet vs iPad

**Device Matrix**

| Device | Screen | Challenge |
|---|---|---|
| iPhone SE (3rd) | 375×667 | เล็กสุด — content อาจล้น |
| iPhone 14 Pro Max | 430×932 | Standard large |
| iPad Mini | 768×1024 | Tablet portrait |
| iPad Pro 12.9" | 1024×1366 | ใกล้ desktop |
| Samsung Galaxy S23 | 393×873 | Android standard |
| Samsung Galaxy Tab | 800×1280 | Android tablet |

**AC — Small Phone (320–375px):** ไม่มี horizontal overflow · bottom nav icons เล็กลง ไม่มี label · modal max-height 90vh scroll ได้ · keyboard ไม่บัง input (scroll-into-view) · VO HUD ย่อ controls
**AC — Tablet (768px+):** 2-column หรือ sidebar-content · sidebar collapsed icon-only · meeting 6–9 tiles (grid 3×3) · VO ใช้งานสบายกว่า portrait · **iPad Split View (Multitasking)**
**AC — Cross-device:** test บน real devices iPhone SE, iPhone 14, Pixel 7, Samsung Galaxy · emulator ทุก breakpoint · **font scaling ตาม user setting (accessibility)** · **dark mode ตาม system**

**Responsive Testing Checklist — หน้าที่ต้อง test ทุก breakpoint:** Login / Onboarding · Virtual Office · Meeting Room · Chat (list + message) · Calendar · Member List · Profile / Settings · Tarot Widget · Participation Dashboard · Modals / Bottom Sheets

**Figma:** [node 6511-36398](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6511-36398) · [node 6662-63286](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6662-63286)

---

## 17. Figma nodes ทั้งหมดที่ระบุใน ClickUp (ไฟล์ `Map8gX0L2hk7HnkaFRfhtj` — Zyra design More Organised ver.)

| Subtask | Node IDs |
|---|---|
| HP-03 VO | 6379-34977 · 6511-44108 |
| HP-04 Meeting | 6111-125216 · 6511-139220 |
| HP-05 Chat | 6351-578634 · 6547-591562 |
| HP-06 Navigation | 6377-27023 · 6604-246256 |
| HP-07 Install & Onboarding | 6663-237832 |
| HP-08 Push | 6411-1141652 · 6610-253136 |
| HP-09 Permissions | 6450-67121 |
| HP-10 Offline | 6462-71727 |
| EP-01 Performance | 6471-172948 · 6662-204168 |
| EP-02 Bandwidth | 6471-172948 · 6662-61731 |
| EC-03 Screen size | 6511-36398 · 6662-63286 |
| HP-01, HP-02, HP-11, EC-01, EC-02 | ไม่มีลิงก์ |

**ยังไม่ได้ดึง spec จาก Figma ตามที่แจ้งว่า UI จะให้ภายหลัง** — เมื่อได้รับให้ทำ `ux-ui-plan.md` ตามกฎ Figma fidelity (get_design_context ทุก node ก่อนแตะ layout)

## 18. จุดที่ ClickUp ต่างจากโค้ดจริง / มติ / inventory ของเรา (ต้องเคลียร์กับ PM/design)

| # | ClickUp บอก | ของจริง / มติ | ต้องทำ |
|---|---|---|---|
| 1 | Engine = **Phaser.js** (HP-01, HP-03, EP-01, EC-01, EC-02) | VO ใช้ **PixiJS 8** (`zyra-engine/pixi-game/`) · Phaser มีแค่ play-test/editor | แก้ข้อความใน ClickUp · ข้อจำกัด "Phaser ไม่รองรับ RN" ยังจริงสำหรับ Pixi |
| 2 | HP-01 แนะนำ Phase 2 = PWA ก่อน Capacitor | มติเรา: Capacitor ตรง (Phase 0 responsive web → Phase 1 Capacitor) ข้าม PWA install prompt | ยืนยันกับ PM ว่าตัด PWA deliverable (HP-07 ส่วน PWA) หรือทำ manifest ให้ครบเฉย ๆ |
| 3 | Touch target ≥ 44px, font body ≥ 14px (HP-02 AC) | Comment P A: ปุ่ม 42/32/24px, font เล็กสุด 10px, field 42px · โค้ดปัจจุบันปุ่ม 42px | design ต้องเลือก: ตาม Apple HIG 44 หรือตาม Figma 42 |
| 4 | Bottom nav 5 icons (HP-02) vs **4 items Home/Chat/Calendar/Profile** (HP-06 + comment) · AC "icon + label" vs comment "icon ไม่มี text" | — | ยึด comment ล่าสุด (4 เมนู, icon-only) แต่ต้องยืนยัน |
| 5 | **Calendar**, **Tarot widget**, **Participation dashboard**, **Quiz/Poll**, **Meeting Alert 5 min**, **AI Meeting Summary** (HP-02/06/07/08/10, EC-03) | **ไม่มีในโค้ด zyra-app** ตอนนี้ (ไม่มี route `/calendar`, ไม่มี tarot/participation/quiz/poll) | ถาม PM ว่าเป็น feature อนาคตหรือ scope นี้ · ถ้าอนาคต ตัดออกจาก AC mobile รอบแรก · **Ten 2026-10-01: ฟีเจอร์ที่ยังไม่มี กดแล้วขึ้น "Coming soon" · Calendar ซ่อนทั้งหมด** · **แก้ 2026-10-02 (โน้ต Pai): ซ่อนทั้งหมด ไม่มี Coming soon → ux-ui-plan §19** |
| 6 | Bundle ID `com.zyra.app` (HP-07) | เราเสนอ `co.zyraworld.app` ใน spec.md open question | ยึด ClickUp `com.zyra.app` เว้นแต่ PM เปลี่ยน · **Ten 2026-10-01: ชื่อแอป Zyra World · ไอคอน logo ตัว Z** · **bundle id = `co.zyraworld.app`** (PM แก้ HP-07) |
| 7 | Splash 2 วินาที + onboarding 3 slides ใหม่ (HP-07) | โค้ดมี onboarding modal desktop (900×600) อยู่แล้ว คนละอย่าง | เป็นหน้าใหม่ 4 หน้า (splash + 3 slides) รอ Figma 6663-237832 |
| 8 | Push types: Meeting Alert 5 min, Meeting Started, Weather Alert (HP-08) | zyra-ws ไม่มี meeting scheduling event · weather alert มีใน `vo-alert-banner.tsx` (env feature) | trigger ใน task 2.4 ต้องเพิ่ม weather alert · meeting schedule รอ feature Calendar |
| 9 | Auto-update check แจ้ง update ใหม่ (HP-07) | `version-check-modal.tsx` มีอยู่แล้ว (poll `/api/version` 30 นาที) ใช้ได้ในโหมด remote URL | ครอบคลุมแล้ว · เพิ่ม "App version ใน Settings → About" |
| 10 | Offline: Chat อ่าน cache + queue ส่ง, Service Worker cache static (HP-10) | ไม่มี offline cache ในโค้ด (`sw.js` pass-through, chat ไม่มี queue) · SW ไม่รันใน WKWebView โหมด remote URL | งานใหม่: chat queue (zustand + IndexedDB มี dexie แล้ว) · static cache ใช้ WebView cache แทน SW |
| 11 | Reconnect 5 ครั้ง (HP-10) | `workspace-ws.ts` backoff 5 ครั้งอยู่แล้ว ✅ · SFU rejoin 3 ครั้ง | ตรง ✅ |
| 12 | Performance level 1–4 + Simple mode dots (EP-01) | มี FPS fallback แค่ nature/weather (`lib/nature-performance.ts` 30fps/10s) · ไม่มี DPR reduce, avatar fps reduce, simple mode | งานใหม่ใน engine (ต่อยอด task 0.9) · Level 1 = cap DPR ที่เราวางไว้ |
| 13 | Memory ≤ 200MB (HP-03) | spec.md เราตั้ง < 400MB · inventory พบ texCache ไม่มี LRU, alpha hit-test 4MB/sheet | ยึด ClickUp 200MB เป็น target ต้องวัดจริงก่อน (ยังไม่มีตัวเลข) |
| 14 | Battery warning < 20% ในประชุม (HP-04), battery drain ≤ 15%/ชม (HP-03) | `navigator.getBattery` ไม่ใช้ในโค้ด · iOS ไม่มี Battery API ใน WebView → ต้อง plugin (`@capacitor/device` getBatteryInfo) | เพิ่ม B15 ใน inventory |
| 15 | Haptic ตอน mute/unmute (HP-04) และกด nav (HP-06) | inventory B10 มี haptics ที่ wave/knock | เพิ่มจุด mute/unmute + nav |
| 16 | Self-view draggable PiP (HP-04), swipe thumbnails, tap tile = active speaker | ปัจจุบัน `zone-enter-tiles.tsx` grid ไม่มี active-speaker layout · **Ten 2026-10-01: PIP ลากไม่ได้** (แนวตั้งตายตัวตาม Figma · แนวนอนอยู่เหนือ minimap) → PM ตัด AC "draggable" | รอ Figma 6111-125216 |
| 17 | Chat: swipe-left archive/mute, pull-to-refresh, long-press menu (HP-05) | ไม่มี swipe/pull ใน `views/chat` · long-press ตรงกับ CH1 ในของเรา | เพิ่มใน screens.md E |
| 18 | Double-tap center camera (HP-03) | engine ไม่มี double-tap (มีแค่ 2-click walk) | เพิ่มใน task 0.4 |
| 19 | iPad Split View, font scaling, dark mode (EC-03) | app dark-only (`globals.css` `.dark` ไม่ toggle) · ไม่มี font scaling | dark mode = ตรงอยู่แล้ว (dark ตลอด) · font scaling งานใหม่ · Split View ต้องทดสอบ |
| 20 | QR code ในหน้า desktop-only (EC-01) | ไม่มี QR lib ในโค้ด | เพิ่ม dependency ตอนทำ J ใน screens.md · **แก้ 2026-10-02 (โน้ต Pai): **ไม่ทำ** — ไม่มีหน้า desktop-only → ux-ui-plan §19** |
| 21 | Smart App Banner `apple-itunes-app` (EC-02) | ยังไม่มี app-id | ทำหลังได้ app-id จาก App Store Connect |
| 22 | LiveKit audioBitrate 32kbps, videoBitrate 200kbps–2Mbps, dynacast (EP-02) | `sfu-client.ts:405-410` มี `adaptiveStream: true, dynacast: true` แล้ว · bitrate ยังไม่ตั้งเฉพาะ mobile | เพิ่มใน task 0.8 |
| 23 | Spotlight มี screen share จาก mobile presenter (HP-11) | inventory A1: screen share ต้อง native (Phase 3) | HP-11 ส่วน presenter screen share = Phase 3 · ส่วน viewer/presenter ไม่ share ทำ Phase 2 ตาม screens.md G |
| 24 | Due date ClickUp **2026-10-02** | ยังไม่มี UI, ยังไม่เริ่มโค้ด | due นี้เป็นของ task หลัก — ต้องคุยกับ PM ว่าหมายถึงอะไร (spec approve? implement?) |
| 25 | HP-02 "รองรับทั้ง Portrait และ Landscape" + HP-03 "Landscape banner แนะนำให้หมุนจอ" (แมพใช้ได้ทั้งสอง orientation, แนวนอนแค่แนะนำ) | **มติ 2026-09-30 (ยืนยันจาก Figma HP-03 + Ten): ผู้ใช้เลือก Lite / Spatial เองที่หน้า Select workspace mode, จำ 1 วัน/ตลอด, เปลี่ยนได้ใน Settings เท่านั้น · Lite = แนวตั้ง ไม่โหลดแมพ · Spatial = แนวนอน · ถือผิด orientation → หน้าเต็มจอ "Rotate your phone" ไม่ใช่ banner** (spec.md, technical-design §16, ux-ui-plan §3.4–3.5) | PM อัปเดต ClickUp HP-02/HP-03 ให้ตรง Figma |
| 28 | HP-03 AC "Virtual D-Pad ซ้ายล่าง 100×100px" | Figma joystick **128×140** (node 6519-209485) · Ten ยืนยันยึด Figma | แก้ AC เป็น 128×140 |
| 29 | HP-07 onboarding 3 slide = VO / Meeting + AI Summary / Quiz Poll Tarot | Figma HP-03 ใช้ copy คนละชุด (Collaboration / One Space / Pet & achievements) ไม่มี AI Summary, Quiz, Poll, Tarot (ux-ui-plan §3.1) | ยึด Figma · PM ปรับ HP-07 |
| 30 | HP-04 AC "Portrait: active speaker ใหญ่ + thumbnail strip ด้านล่าง" | Figma HP-04 ใช้ **grid** (แนวตั้ง 2 คอลัมน์ / แนวนอน 3 คอลัมน์, > 6 คนเลื่อนหน้า) ไม่มี active-speaker + strip · active speaker ใช้เฉพาะตอน PIP (ux-ui-plan §8.2) | ยึด Figma · PM ปรับ AC |
| 31 | HP-04 "Screen share: share จาก mobile อาจจำกัด (EC-02)" · Figma tooltip "Screen sharing is only available in your browser." | Ten: ถ้าทำให้มือถือแชร์ได้จะดีมาก → app ผ่าน ReplayKit/MediaProjection = Phase 3 (A1) · tooltip = กรณี mobile web · ฝั่งแชร์ถามก่อนเสมอ (iOS system dialog) · DND อัตโนมัติทำได้เฉพาะ Android | ปรับข้อความ tooltip ให้ตรง ("available in the Zyra app / on desktop") |
| 32 | HP-04 ไม่มีเรื่อง ghost | Ten: คน Lite ไม่มี avatar บนแมพ จนกว่าจะเข้า meeting → คนอื่นเห็น avatar โผล่ที่ spawn แล้วเดินไปห้อง (TD §16.2) | PM เพิ่มใน spec HP-03/HP-04 |
| 33 | HP-05 AC "swipe left → archive/mute" + "Pull-to-refresh: load older messages" | Figma HP-05 ไม่มี swipe · โหลดข้อความเก่า = เลื่อนถึงบนสุดแล้วโชว์ icon โหลด (sticky design) ไม่ใช่ pull-to-refresh · โค้ดใช้ IntersectionObserver อยู่แล้ว (`message-list.tsx:249`) | ยึด Figma · PM ปรับ AC (archive/mute ไม่มีใน scope) |
| 34 | HP-05 AC "Long press → Reply, React, Copy, Delete" (4 ข้อ) | Figma มี Emoji panel 7 ตัว + Submenu 7 ข้อ: Reply / Thread / Copy / Pin / Forward / Select / Delete · Ten: **Forward + Select ต้องทำใน scope mobile** (desktop ยัง disabled `message-context-menu.tsx:65-66`) | PM เพิ่ม AC · ต้องขอ design Forward/Select flow |
| 35 | HP-05 AC "Emoji picker: native emoji keyboard หรือ custom picker" | Figma โชว์คีย์บอร์ด emoji ของ iOS แต่แอปสลับคีย์บอร์ดเองไม่ได้ · Ten: ใช้ **custom picker ของเรา** (`emoji-picker.tsx`) เป็น bottom sheet | ยึด custom picker |
| 36 | HP-05 ClickUp ไม่มี **voice message** | Figma มีปุ่มไมค์ในช่องพิมพ์ · Ten: **ทำรอบแรก** (task 0.25 — ใหม่ทั้ง web/api/ws, UI ยังไม่มี) | PM เพิ่ม AC + subtask · design ทำ UI อัด/player |
| 37 | HP-05 "Keyboard-aware scroll" (list เลื่อนขึ้น) | Ten ยืนยัน: คีย์บอร์ดเปิดแล้ว**ดันข้อความล่าสุดขึ้น**ทั้ง 2 orientation (แนวนอน Figma ไม่มี keyboard mock — design ขอไม่ใส่) | ตรงกัน · ยึด Figma + คำตอบ |
| 38 | HP-06 AC "Active state: icon + label สีตาม theme, underline indicator" + "More → bottom sheet" | Figma HP-06: bottom nav **icon-only ไม่มี label**, active = วงกลม bg white 20%, badge แดง · **ไม่มีปุ่ม More** (4 แท็บพอดี) | ยึด Figma · PM ปรับ AC |
| 39 | HP-06 AC "Workspace switcher: กด workspace name → bottom sheet แสดง workspace list" | Figma: chevron ข้างชื่อ → **หน้าเต็มจอ Workspace lists** (search + filter เวลา + การ์ด) ไม่ใช่ sheet · แนวนอน = modal ทับแมพ (Ten) | ยึด Figma |
| 40 | HP-06 AC "Back navigation: swipe right (iOS) หรือ back button (Android)" | Figma ทุกหน้าลูกมี**ปุ่ม back** ซ้ายบน + ซ่อน bottom nav · hardware back ให้ทำงานเหมือนปุ่ม back (สมมติ รอ Ten ยืนยัน ux-ui-plan §10.6 ข้อ 8) | เพิ่มปุ่ม back ใน AC |
| 41 | Figma sticky 6379-34974 "เลือก workspace แล้ว reload → ถามโหมด Lite/Spatial อีกครั้ง" | **Ten ยกเลิก** — จำโหมดรวม 1 วันทุก workspace ตามมติเดิม (TD §16.1) · สลับ workspace ใน 24 ชม. ไม่ถามซ้ำ | design ลบ sticky / PM ไม่ต้องใส่ใน AC |
| 42 | HP-06 "Bottom navigation: 4 items (Home, Chat, Calendar, Profile)" — Calendar | ไม่มี frame Calendar ใน Figma และไม่มี feature ในโค้ด (ข้อ 5) · Ten ยังไม่ตอบว่าซ่อนหรือ Coming soon (OQ 21) | PM ตัดสินใจ · **Ten 2026-10-01: ซ่อน Calendar ไปก่อน → 3 แท็บ** |
| 43 | HP-07 "Install prompt หลัง 2 visits + engagement threshold" ("Add Zyra to Home Screen") | Figma: แถว "PWA Install" เป็น **smart app banner** "Meet Zyra on mobile" หลัง ~5 วิ → Open Zyra = แอป / App Store / Play Store · **Ten: ยังรองรับ PWA install** → ทำทั้ง banner (ไปแอป) และ install prompt ตาม ClickUp | design ทำ UI install prompt (Figma ยังไม่มี) · ลำดับ (Ten): banner ก่อน → กด Later ซ่อน 7 วัน → install prompt ขึ้นเฉพาะคนที่กด Later แล้ว |
| 44 | HP-07 "Onboarding 3 slides, skip ได้" + copy "Virtual Office / Meeting (AI Summary) / Team Features (Quiz, Poll, Tarot)" | Figma: **ไม่มีปุ่ม Skip** (Ten ยืนยัน) · copy คนละชุด (ไม่มี AI Summary / Quiz / Poll / Tarot — ux-ui-plan §3.1) · Splash 2 วิ animated ตาม ClickUp ✅ | ยึด Figma · PM แก้ AC เรื่อง Skip + copy |
| 45 | HP-07 Steps "Login → Onboarding slides → Select / Create workspace" | Figma: **Splash → slides → Get started (Login)** → Space builder (slide มาก่อน login) · Create workspace 3 step บนมือถือ (Ten: ทำ) | ยึด Figma |
| 46 | HP-07 ไม่ระบุ orientation | Ten: หน้าก่อนเข้า workspace (splash, slide, login, Space builder, Create workspace) **แนวตั้งอย่างเดียว** · section แนวนอนใน Figma เป็นสำเนาแนวตั้ง | PM เพิ่มใน AC |
| 47 | HP-08 AC "Permission request หลัง onboarding เสร็จ (ไม่ prompt ทันที)" | Figma + Ten: **ขอตอน splash** (เปิดแอปครั้งแรก) · ปฏิเสธแล้วมีปุ่มขอ Allow ในหน้า Notification settings (ข้อเสนอ ux-ui-plan §12.6) | ยึด Figma · PM แก้ AC |
| 48 | HP-08 Notification Types (Meeting 5 min, Spotlight, Weather Alert) | Figma + Ten: reminder **15 นาที** · **ไม่ส่ง** mention in thread / weather warning / weather emergency · meeting 4 ประเภทรอ Calendar · DM/mention แสดง**ข้อความจริง + ชื่อห้อง + ชื่อ workspace** | PM อัปเดตตาราง |
| 49 | HP-08 AC "Notification settings: user เลือกประเภทได้" | Figma 5 กลุ่ม 15 สวิตช์ + Ten เพิ่ม 4 สวิตช์จาก desktop · **push แยกจาก in-app** | ตรงกัน + ละเอียดกว่า |
| 50 | HP-08 AC "Denied: in-app notification แทน" + "deep link เข้า context นั้น" | Ten: แอปเปิดอยู่ → **banner ในแอปแทน push** · แตะ DM/mention → ห้องแชทนั้น · broadcast → หน้าที่รอ UI · weather → เปิดแอปเฉย ๆ | ตรงกัน |
| 51 | HP-08 AC "Silent notification: update badge count" | Ten: badge = **unread chat + notification รวมกัน** | ตรงกัน + ระบุนิยาม |
| 52 | HP-09 AC "Request permission ก่อน join ครั้งแรก" + "Not determined → Prompt ทันทีก่อน join" | Figma + Ten: ขอ**ตอนกดปุ่มกล้อง/ไมค์ในห้อง ทั้ง 2 โหมด** (ไม่ขอก่อน join) · มี **pre-permission sheet ของเรา** ก่อน dialog ระบบ | PM แก้ AC |
| 53 | HP-09 AC "Banner: 📹 กล้องไม่ได้รับอนุญาต — [เปิดใน Settings]" | Figma: **alert "Unable to access camera / microphone"** (Cancel / Settings) ตอนกดปุ่ม · Ten: ใช้ **native alert** + **indicator บนปุ่ม** แทน banner | PM แก้ AC |
| 54 | HP-09 Info.plist "Zyra ใช้กล้องเพื่อ Video Meeting" | ใช้ข้อความ Figma: "Zyra needs access to your camera so others can see you during meetings and when you use camera features." / ไมค์ "…so others can hear you during meetings and conversations." (task 1.14) | ยึด Figma |
| 55 | HP-09 Permission States "Both denied → View Only mode" | Figma ไม่มี View Only mode — ถูกปฏิเสธทั้งคู่ = อยู่ในห้องได้ ปุ่มทั้งสองมี indicator · ฟัง/ดูคนอื่นได้ตามปกติ | ยึด Figma · ไม่ทำ View Only แยก |
| 56 | HP-10 "Status banner ด้านบน" + "Network indicator (header mobile)" | Figma: **toast ล่าง** เหนือ Meeting Menu (Poor connection / Lost connection / Reconnecting… / Meeting has ended…) · คนอื่นเน็ตแย่ = spinner บนป้ายชื่อ · ไม่มี indicator ใน header | ยึด Figma |
| 57 | HP-10 "Chat offline: queue messages ที่ส่งไม่ได้" + "Chat reconnect: ส่ง queued messages" | Ten: **ตัด offline queue** · ส่งซ้ำอัตโนมัติ 5 ครั้ง (1/2/4/8/16 วิ) → bubble failed แตะส่งใหม่ + sheet "Message not sent" | PM แก้ AC |
| 58 | HP-10 "Disconnect: reconnect 5 ครั้ง → การประชุมถูกตัดการเชื่อมต่อ — [เชื่อมต่อใหม่]" | Ten: 5 ครั้ง ✅ → meeting ตัดจบ **ไม่มีปุ่มเชื่อมต่อใหม่** → หน้าหลัก skeleton + Reconnecting… ≤ 30 วิ → ไม่ได้ = Workspace list + toast "Meeting has ended due to lost connection" | PM แก้ AC |
| 59 | HP-10 Poor connection "auto-reduce 720p → 480p → 360p → audio only" | Figma ไม่ระบุ — LiveKit simulcast/adaptive stream ลด layer อัตโนมัติอยู่แล้ว 🔍 · Offline Calendar / Tarot history cache = ไม่มี feature | ใช้ adaptive ของ LiveKit · ตัด Tarot/Calendar cache |
| 60 | EP-01 เกณฑ์ FPS L1 < 30 · L2 < 25 · L3 < 20 · L4 < 15 · "FPS < 20 ต่อเนื่อง 10 วิ" | Ten: **ใช้ของ Figma** L1 < 25 · L2 < 21 · L3 < 15 · L4 = ยัง < 15 หลัง L3 อีก 10 วิ (สมมติ) · ลดทีละขั้น · **เฉพาะมือถือ** | PM แก้ตาราง |
| 61 | EP-01 "Toast ⚡ ลด visual effects (1 ครั้ง)" | Figma: toast **ต่อ level** (L2 Visual effects reduced · L3 Animations reduced · L4 Simplified map · L1 ไม่มี) ปิดเอง 10 วิ · Ten: **กลับขึ้นเองอัตโนมัติ + toast** | PM แก้ AC |
| 62 | EP-01 Simple mode "colored dots + ชื่อ แทน sprite" | Figma + Ten: **minimap ขยายเต็มจอ + avatar วงกลม / cluster "+10"** · เดิน / ประชุม / นั่งได้ปกติ ✅ | ยึด Figma |
| 63 | EP-01 Settings "Mobile Performance Mode" + "เปิด effects เต็ม" + RAM < 200MB เตือน | Ten: **ต้องมีเมนู** (ข้อเสนอ ux-ui-plan §15.7: Auto / Performance mode / Full effects) · RAM warning สมมติว่าทำ (OQ 30) | design ทำ UI · ยืนยัน RAM · **แก้ 2026-10-02 (โน้ต Pai): **ตัดเมนู** ปรับเองอย่างเดียว · แจ้ง PM → ux-ui-plan §19** |
| 64 | HP-10/EP-02 "auto-reduce 720p → 480p → 360p → audio only" | Figma EP-02: > 2 Mbps 720 · 1–2 Mbps 480 · 0.5–1 Mbps 360 · 200–500 kbps ปิดกล้อง · Ten: **ใช้ simulcast เดิม 720/360/180** (ไม่เพิ่ม 480) · ปิดกล้องหลังต่ำ 10 วิ · กล้องไม่เปิดเองเมื่อดีขึ้น | PM แก้ตาราง |
| 65 | EP-02 audio-only "แสดง avatar แทนกล้อง" | Ten: คนอื่นเห็น **avatar + spinner บนป้ายชื่อ** บอกว่าเน็ตไม่ดี | ตรงกัน + ละเอียดกว่า |
| 66 | EP-02 ขอบเขต mobile | Ten: ใช้**ทั้งมือถือและ desktop** | PM เพิ่ม desktop ใน AC |
| 67 | EC-03 Tablet "2-column หรือ sidebar-content · sidebar collapsed icon-only" | Figma: 1 คอลัมน์ยืดเต็มจอ (Lite) / HUD มือถือ (Spatial) · Ten: **ยึด Figma ไม่จำกัด max-width** | PM แก้ AC tablet |
| 68 | EC-03 tablet layout (spec เดิม: ≥ 768 = desktop) | Ten: **tablet ใช้ UI มือถือ** · app = เสมอ · เว็บ = จอสัมผัส + ด้านยาว ≤ 1366 (iPad + trackpad นับ) | task 0.41 · PM เพิ่ม AC "iPad ได้หน้า Select mode" |
| 69 | EC-03 Small phone "bottom nav icons เล็กลง ไม่มี label · VO HUD ย่อ controls" | bottom nav icon-only อยู่แล้ว (HP-06) · Figma ไม่มี frame ≤ 375 · Ten: **ใช้ layout 390 + ตัดข้อความยาวเป็น …** · HUD ขนาดเดิม | task 0.44 · ถ้าอยากได้ HUD ย่อต้องมี design |
| 70 | EC-03 "meeting 6–9 tiles (grid 3×3)" | Figma ไม่มี · Ten: **ทำ** | task 0.45 รอ design |
| 71 | EC-03 "iPad Split View (Multitasking)" | Ten: **รองรับ** · โหมดตัดสินจากสัดส่วนหน้าต่าง · หน้าก่อนเข้า workspace บน tablet แนวนอนได้ จัดกลาง (ยกเว้นจากมติ HP-07 แนวตั้งอย่างเดียว) | task 0.42, 0.46, 1.16 |
| 72 | EC-03 "font scaling ตาม user setting (accessibility)" | Ten: **รอบแรก lock 100%** (Android ขยายเองทำ layout แตก) | task 1.16 · PM ย้าย font scaling ไปรอบหลัง |
| 73 | EC-03 "dark mode ตาม system" | Ten: **dark อย่างเดียว** (app dark-only) | PM แก้ AC |
| 74 | EC-03 Device matrix iPad Mini 768×1024 | Figma frame 744×1133 (label 768×1024) · iPad Pro แนวนอน frame 1399 (เครื่องจริง 1366) · Ten: **layout fluid ทุกขนาด** | ทดสอบทั้ง 744 และ 768 |
| 75 | EC-03 Responsive Testing Checklist (chat, meeting, calendar, profile/settings, modal) บน tablet | Figma มีแค่ Lite Home + แมพ · Ten: **ยืดจาก phone · bottom sheet กว้างสุด 600 กลางจอ** · Tarot / Participation Dashboard / Calendar ไม่มีในโค้ด (ข้อ 5) | ไม่ต้องรอ design เพิ่ม |
| 76 | HP-11 Presenter "เดินเข้า marker → prompt แตะเพื่อขึ้น Stage → confirm bottom sheet" | Figma: **Lite Home ปุ่ม Start spotlight → หน้า Spotlight → Play → นับ 5 วิ + Stop** (ไม่มี confirm sheet) · Ten: Lite เริ่มได้โดยไม่ต้องอยู่บน marker · Spatial = megaphone → auto-walk | PM แก้ Scenario A · zyra-ws task 0.48 |
| 77 | HP-11 HUD "⭐ LIVE + viewer count + ปุ่มออก" | Figma ไม่มี · Ten: **เพิ่ม chip LIVE · N ข้างชื่อ Spotlight แตะ = รายชื่อผู้ชม** | design ยืนยัน chip · **แก้ 2026-10-02 (โน้ต Pai): ป้าย LIVE + ตัวนับ Mic / Eye · ปุ่มออกอยู่ bottom menu → ux-ui-plan §19** · **แก้ 2026-10-05 (Figma HP-11 v2): ป้าย Live + ชิป N | M → ux-ui-plan §18.9** |
| 78 | HP-11 Controls 🎤 📹 📺 💬 | Figma: cam / mic / share / ⋮ ┃ Play-Stop / leave + sheet (speaker, share, raise hand, settings, emoji, chat) · Ten: ยึด Figma · raise hand = คนดู · settings = ไมค์ / กล้อง / ลำโพง | — |
| 79 | HP-11 Viewer ไม่อยู่ใน meeting "full screen ทันที · portrait video + chat bar · landscape split video/chat · swipe down → mini bar" | Ten: **เปิดหน้า Spotlight เต็มจออัตโนมัติ** (หน้าเดียวกับ presenter) · แชทเปิดเป็นหน้าเต็มจอแบบ HP-05 ไม่ใช่ split · ย่อด้วย chevron → PIP (ไม่ใช่ swipe → mini bar) | PM แก้ AC |
| 80 | HP-11 Viewer ใน meeting "toast [ดู] [เดี๋ยวก่อน] → bottom sheet 40–60vh · ได้ยินเสียง meeting" | Ten: **ยึด web** — toast Join spotlight / Stay in meeting · Join แล้วหน้า Spotlight แทน meeting ทั้งห้อง | PM แก้ AC |
| 81 | HP-11 Multiple Spotlight "horizontal tabs Stage A / Stage B" | ระบบจริง = broadcast เดียวต่อ floor หลายคนพูดได้ · Ten: **tile หลายอัน ไม่มี tab** · Lite เริ่มที่ **floor แรก** | PM ตัด AC tabs |
| 82 | HP-11 Screen share mobile presenter (ReplayKit / MediaProjection) | Ten: รอบแรกปุ่ม disabled + tooltip · app = Phase 3 | ตรงข้อ 23, 31 |
| 83 | HP-11 Figma | ClickUp ไม่มีลิงก์ · Ten ส่ง 2026-10-01: แนวตั้ง `6710-161801` (presenter อย่างเดียว) · **แนวนอนไม่มี — ใช้ข้อเสนอ ux-ui-plan §18.6** | design ทำแนวนอน + หน้าคนดู + chip LIVE |
| 84 | EC-01 "Space Builder บน mobile → redirect หรือ read-only" (= editor) | Figma + Ten 2026-10-01: ในแอป **"Space builder" = หน้ารายการ workspace** (มีบนมือถือ) · editor ยังเป็น desktop only | PM เปลี่ยนชื่อใน EC-01 เป็น "Workspace editor" กันสับสน |
| 85 | HP-07 onboarding copy (VO / Meeting AI Summary / Quiz Poll Tarot) | Ten 2026-10-01: **ยึด Figma** (Collaboration / Collaborate in One Space / Pet & achievements) | PM แก้ AC |
| 26 | HP-04 portrait (active speaker + strip) / landscape (grid) และ HP-11 portrait / landscape เป็น layout ของ "หน้าเดียวกัน" | portrait = Lite Mode (ผู้ใช้เป็น ghost tile, ไม่มีแมพ) · landscape = Spatial (Figma HP-03 มี tile คนพูด 168×158 ซ้อนแมพ) · เปลี่ยนโหมด = leave + join ใหม่ ไม่ใช่หมุนเครื่อง (technical-design §16) | ยืนยัน grid เต็มกับ design ตอนได้ Figma 6111-125216 |
| 27 | EP-01 **Simple Mode** (level 4 dots) | คนละอย่างกับ **Lite Mode** — Simple Mode เป็น fallback ภายใน Spatial Mode เมื่อ FPS < 15 · Lite Mode เป็นโหมดตาม orientation ที่ไม่มีแมพเลย | ใช้ชื่อให้ไม่ปนกันใน ClickUp / Figma / โค้ด |
