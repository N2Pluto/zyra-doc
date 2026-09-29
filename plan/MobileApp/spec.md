# Mobile App — Spec

> **สถานะ:** Planning — **มติเลือก Capacitor + native feature จริง แล้ว (2026-09-29)** · ยังไม่ implement · **repo:** zyra-app (หลัก), zyra-mobile (ใหม่), zyra-api, zyra-notifications, zyra-ws
> **ที่มา:** ต้องการเอา Zyra World ขึ้น App Store + Play Store โดยใช้ Virtual Office ได้เต็มรูปแบบ · **ClickUp:** ยังไม่มี task
> **เอกสารคู่กัน:** [comparison.md](comparison.md) · [technical-design.md](technical-design.md) · [task-breakdown.md](task-breakdown.md) · [progress.md](progress.md)

## มติ

| เรื่อง | มติ |
|---|---|
| Framework | **Capacitor** (WebView shell ครอบ zyra-app) + native feature จริงผ่าน Capacitor plugin |
| Scope | **Full Virtual Office** — เดินในแมพ, นั่ง, เข้า zone, ประชุม mic/cam, แชท บนมือถือ |
| Distribution | App Store + Play Store ทั้งสอง |
| Web app | **zyra-app (Next.js) ยังเป็นแอปหลัก** — ไม่ rewrite, ไม่มี second codebase สำหรับ UI |
| Plan B | Expo / React Native — เฉพาะเมื่อชน trigger ใน [technical-design.md §9](technical-design.md#9-plan-b--expo) |

เปรียบเทียบสามตัว (Capacitor / Expo / Flutter) และตัวเลือกที่ปัดตก (PWA-only, RN+WebView, KMP, Tauri, Unity) อยู่ใน [comparison.md](comparison.md)

## What — สิ่งที่ผู้ใช้ทำได้บนมือถือ

### Scope ที่ต้องได้ (Full VO)

| ID | Scenario | หมายเหตุ |
|---|---|---|
| SC-MOB-01 | ติดตั้งแอปจาก App Store / Play Store แล้ว login ด้วย email, Google (native), Apple (native) | Sign in with Apple บังคับตามกฎ Apple 4.8 |
| SC-MOB-02 | เข้า workspace แล้วเห็นแมพ VO เต็มจอ (landscape + portrait) ไม่มี overlay "Mobile unsupported" | overlay เดิมอยู่ `zyra-app/components/mobile-unsupported-overlay.tsx` |
| SC-MOB-03 | เดินในแมพด้วย virtual joystick หรือแตะพื้นเพื่อเดิน (tap-to-walk) | เทียบเท่า WASD / click-to-walk บน desktop |
| SC-MOB-04 | นั่งเก้าอี้, เข้า/ออก zone, private zone, wave/knock/follow ได้เหมือน desktop | ใช้ ws protocol เดิม ไม่เปลี่ยน |
| SC-MOB-05 | เปิด mic/cam ในประชุม, เลือกกล้องหน้า/หลัง, เห็นวิดีโอคนอื่น | ผ่าน livekit-client ใน WebView |
| SC-MOB-06 | แชท (DM, channel, meeting chat) พร้อม keyboard ไม่บังช่องพิมพ์ | |
| SC-MOB-07 | ได้ push notification (DM, mention, knock, meeting invite) ตอนแอปอยู่ background หรือปิดอยู่ | ต้องมี push backend ใหม่ ([technical-design.md §6](technical-design.md#6-push-notification-flow)) |
| SC-MOB-08 | สลับแอปออกไประหว่างประชุม เสียงยังต่อ กลับมาแล้ว WS/LiveKit reconnect เอง | iOS background audio mode |
| SC-MOB-09 | เปิด deep link `zyra://workspace/<id>` หรือ universal link แล้วเข้า workspace นั้นตรง ๆ | |
| SC-MOB-10 | Server ล่ม/ไม่มีเน็ต → เห็นหน้า offline ของแอป (ไม่ใช่ error page ของ Safari/Chrome) + ปุ่ม retry | |

### Native feature — แบ่ง 3 Tier

| Tier | ต้องมีเมื่อ | รายการ |
|---|---|---|
| **1 — บังคับตั้งแต่ submit รอบแรก** | Phase 1 | Push (APNs/FCM) · Sign in with Apple + Google native · Deep link / universal link · Background audio · Permission กล้อง/ไมค์ native พร้อมข้อความอธิบาย · หน้า offline native + auto reconnect |
| **2 — ทำให้รู้สึกเป็นแอป** | Phase 1–2 | Haptics ตอน wave/knock · Badge count จาก unread · Share sheet ส่ง invite link · Keep-awake ตอนอยู่ใน VO · Keyboard handling ให้ chat input ไม่ถูกบัง · Splash / status bar สี `#1A1B1E` |
| **3 — ของที่ WebView ทำไม่ได้ ต้องเขียน plugin เอง** | Phase 3 (ตาม demand) | CallKit + VoIP push (meeting invite เด้งเหมือนสายเข้า) · Screen share ผ่าน ReplayKit / MediaProjection · Native Picture-in-Picture ของวิดีโอประชุม · Live Activities (Dynamic Island) แสดงว่ากำลังประชุม |

Tier 1 คือสิ่งที่ทำให้ผ่าน Apple Guideline 4.2 (minimum functionality) — แอปที่เป็นแค่ WebView เปล่าจะโดนปฏิเสธ

## Out of scope (รอบแรก)

- **Screen share บนมือถือ** — WKWebView / Android WebView ไม่มี `getDisplayMedia` ต้องซ่อนปุ่มบน mobile และแจ้งลูกค้าล่วงหน้า (Tier 3)
- Background blur / virtual background / noise suppression บนเครื่องอ่อน — ปิดโดย default บน mobile (MediaPipe หนัก) เปิดได้ใน settings
- Map Editor / admin pages บนมือถือ — desktop only ต่อไป
- Tablet layout เฉพาะ — ใช้ layout desktop เมื่อ ≥ 768px เหมือนเดิม
- Offline mode (ใช้แอปโดยไม่มีเน็ต) — แค่หน้า offline + retry

## Where — repo ที่กระทบ

| Repo | กระทบอะไร | Phase |
|---|---|---|
| **zyra-app** | mobile layout ของ VO, touch control ใน `zyra-engine`, flag เปิด mobile, branch เล็ก ๆ เมื่อรันใน Capacitor (native sign-in, ส่ง FCM token, ซ่อน screen share) | 0, 1 |
| **zyra-mobile** (repo ใหม่) | Capacitor project: iOS/Android shell, `capacitor.config.ts`, plugin native, CI build/sign/upload | 1 |
| **zyra-api** | `POST/DELETE /api/user/devices` + `tb_user_device`, `POST /api/authen/login_apple` | 1, 2 |
| **zyra-notifications** | provider FCM HTTP v1 ข้าง SMTP, endpoint ภายใน `POST /push` | 2 |
| **zyra-ws** | trigger push เมื่อ DM/mention/knock/meeting invite ถึง user ที่ offline | 2 |
| **zyra-infra** | ไม่มี service ใหม่บน k3s (zyra-mobile build ใน GitHub Actions ไม่ deploy) — เพิ่ม secret FCM ให้ zyra-notifications | 2 |

## Acceptance criteria ต่อ Phase

### Phase 0 — Mobile web ใช้ได้จริง (ไม่ขึ้นกับ framework)

- [ ] SC-MOB-02 ~ 06 ทำได้ครบบน **Safari iOS + Chrome Android** ผ่าน browser โดยไม่มีแอป
- [ ] FPS ≥ 30 คงที่ในแมพที่มี 20 คน บน iPhone 12 และ Android ระดับกลาง (Pixel 6a / Samsung A54) · memory < 400 MB
- [ ] Playwright mobile viewport test: login → enter workspace → เดิน → เข้า zone ผ่านใน CI
- [ ] ตัวเลข before/after บันทึกใน [progress.md](progress.md) ตามกฎ before/after metrics (before = "ถูกบล็อกทั้งหมด")

### Phase 1 — Capacitor shell ขึ้น store

- [ ] TestFlight + Play internal build ติดตั้งและเปิดได้
- [ ] SC-MOB-01, 07, 08, 09, 10 ผ่านบนเครื่องจริง
- [ ] Native feature Tier 1 ครบทุกข้อ
- [ ] ออกจากแอปกลางประชุม 30 วินาที กลับมาเสียงยังต่อ · WS reconnect ภายใน 5 วินาที
- [ ] มี test account + workspace สำหรับ App Review ใส่ใน review notes
- [ ] `GET /api/health` version ตรงกับ tag ที่ build แอป

### Phase 2 — Push backend

- [ ] DM ถึง user ที่ปิดแอปอยู่ → push ถึงเครื่องภายใน 5 วินาที
- [ ] Notification settings เดิม (`zyra-app/stores/notification-settings-store.ts`) คุมการส่ง push ได้
- [ ] Unit test ครอบ device_service (zyra-api) และ FCM provider (zyra-notifications) ≥ 80%

## Reference — Gather ทำยังไง

ตรวจจาก help center ของ Gather (2026-09-29):

- **Gather 2.0** (เปิด 2025-09-15) **ไม่มี mobile app** — มีแค่ desktop app (macOS/Windows) กับ browser และแนะนำให้ลูกค้าที่ต้องการ mobile อยู่บน 1.0 ต่อ
- **Gather 1.0** มีแอป "Gather Meetings" (ปล่อย 2023-08) เป็น **companion app** — สร้าง/เข้าประชุม, แชท, reaction, ดูใครออนไลน์ **เดินในแมพไม่ได้** avatar ถูกวาร์ปไปห้องประชุมให้
- ก่อนทำแอป Gather ลองให้ใช้ผ่าน mobile browser แล้วยอมรับเองว่า "limited functionality, poor usability, performance issues"
- Renderer ฝั่งเว็บของ Gather เป็น Pixi + canvas หลายชั้น เหมือน `zyra-engine` ของเรา

**นัย:** ยังไม่มีคู่แข่งในตลาดนี้ทำ Full VO บนมือถือสำเร็จ ความเสี่ยงหลักอยู่ที่ Phase 0 (touch control, performance, responsive HUD) ไม่ใช่ที่ Capacitor · ถ้าต้องการออก store เร็ว ทางถอยคือทำแบบ Gather 1.0 (companion: แชท/ประชุม/presence/push) ก่อน แล้วค่อยเปิด map — Capacitor รองรับทั้งสองทางโดยไม่เปลี่ยน stack

แหล่งอ้างอิง: [Gather 1.0 vs 2.0](https://support.gather.town/articles/2163640255-gather-1-0-vs-gather-2-0) · [Gather 1.0 Mobile App](https://support.gather.town/hc/en-us/articles/17580563233684-Gather-1-0-Mobile-App) · [Gather 1.0 on Mobile Browsers](https://support.gather.town/articles/7619450362-gather-1-0-on-mobile-browsers) · [Mobile app case study](https://shaop.me/projects/gather-town-mobile-app)

## Open questions (รอคำตอบก่อนเริ่ม Phase ที่เกี่ยว)

| # | คำถาม | บล็อก Phase | ถาม | สถานะ |
|---|---|---|---|---|
| 1 | Figma mobile design ของ VO HUD (chat, member list, meeting bar, zone modal, joystick) มีหรือยัง | 0 (ข้อ 4) | — | ยังไม่ถาม — กฎ Figma fidelity ห้ามเดา layout |
| 2 | Apple Developer account + Google Play Console ของบริษัทมีแล้วหรือยัง ใครถือ | 1 | — | ยังไม่ถาม |
| 3 | ชื่อแอปบน store / bundle id (`co.zyraworld.app`?) / ไอคอน | 1 | — | ยังไม่ถาม |
| 4 | ต้องการ companion-first (แบบ Gather 1.0) เพื่อออก store เร็ว หรือรอ Full VO ครบก่อน submit | 1 | — | มติปัจจุบัน: Full VO |
| 5 | Microsoft login บนมือถือต้องมีไหม (บนเว็บตอนนี้ยังไม่พบ MSAL ในโค้ด) | 1 | — | ยังไม่ถาม |
