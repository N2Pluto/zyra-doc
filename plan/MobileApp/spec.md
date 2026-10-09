# Mobile App — Spec

> **สถานะ:** Planning — **มติเลือก Capacitor + native feature จริง แล้ว (2026-09-29)** · ยังไม่ implement · **repo:** zyra-app (หลัก), zyra-mobile (ใหม่), zyra-api, zyra-notifications, zyra-ws
> **ที่มา:** ต้องการเอา Zyra World ขึ้น App Store + Play Store โดยใช้ Virtual Office ได้เต็มรูปแบบ · **ClickUp:** [86d4bfpym](https://app.clickup.com/t/86d4bfpym) — spec ถอดครบใน [clickup-spec.md](clickup-spec.md) (16 subtask, due 2026-10-02)
> **เอกสารคู่กัน:** [ux-ui-plan.md](ux-ui-plan.md) (ถอดจาก Figma — HP-03 แล้ว, มี 12 คำถามค้าง) · [clickup-spec.md](clickup-spec.md) (spec จาก PM ถอดครบ) · [comparison.md](comparison.md) · [technical-design.md](technical-design.md) · [screens.md](screens.md) (แบ่งตามหน้า, ไม่ทำ admin) · [task-breakdown.md](task-breakdown.md) · [progress.md](progress.md)

## มติ

| เรื่อง | มติ |
|---|---|
| Framework | **Capacitor** (WebView shell ครอบ zyra-app) + native feature จริงผ่าน Capacitor plugin |
| Scope | **Full Virtual Office** — เดินในแมพ, นั่ง, เข้า zone, ประชุม mic/cam, แชท บนมือถือ |
| โหมดบนมือถือ | **Lite Mode (แนวตั้ง, ไม่โหลดแมพ, ผู้ใช้เป็น ghost ใน meeting)** และ **Spatial Mode (แนวนอน, แมพ VO เต็มจอ)** — **ผู้ใช้เลือกเองที่หน้า Select workspace mode และเปลี่ยนได้ใน Settings เท่านั้น** ถือผิด orientation → หน้า "Rotate your phone" (มติ 2026-09-30 ยืนยันจาก Figma HP-03) · รายละเอียดในหัวข้อ "โหมดการแสดงผลบนมือถือ" |
| Distribution | App Store + Play Store ทั้งสอง |
| Web app | **zyra-app (Next.js) ยังเป็นแอปหลัก** — ไม่ rewrite, ไม่มี second codebase สำหรับ UI |
| Plan B | Expo / React Native — เฉพาะเมื่อชน trigger ใน [technical-design.md §9](technical-design.md#9-plan-b--expo) |

เปรียบเทียบสามตัว (Capacitor / Expo / Flutter) และตัวเลือกที่ปัดตก (PWA-only, RN+WebView, KMP, Tauri, Unity) อยู่ใน [comparison.md](comparison.md)

## What — สิ่งที่ผู้ใช้ทำได้บนมือถือ

### Scope ที่ต้องได้ (Full VO)

| ID | Scenario | หมายเหตุ |
|---|---|---|
| SC-MOB-01 | ติดตั้งแอปจาก App Store / Play Store แล้ว login ด้วย email, Google (native), Apple (native) | Sign in with Apple บังคับตามกฎ Apple 4.8 |
| SC-MOB-02 | เข้า workspace แล้วไม่มี overlay "Mobile unsupported" · เห็นหน้า **Select workspace mode** เลือก Lite / Spatial + Keep This Setting · **Spatial** = แมพ VO เต็มจอแนวนอน · **Lite** = Lite Home แนวตั้ง ไม่โหลดแมพ · ถือผิด orientation เห็นหน้า "Rotate your phone" · เปลี่ยนโหมดได้ใน Settings | overlay เดิมอยู่ `zyra-app/components/mobile-unsupported-overlay.tsx` · UI ใน ux-ui-plan.md §3.4–3.9 |
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

## โหมดการแสดงผลบนมือถือ — Lite / Spatial (มติ 2026-09-30 · ยืนยันจาก Figma HP-03 + คำตอบ Ten)

มือถือ **และ tablet** (ในแอป = เสมอ · เว็บ = จอสัมผัส + ด้านยาว ≤ 1366 — Figma EC-03, technical-design §16.8) มี **2 โหมด ผู้ใช้เลือกเองที่หน้า "Select workspace mode"** หลังเลือก workspace · ระบบจำค่าไว้เฉพาะ Always (Remind me again = ถามใหม่ทุกครั้งที่เข้า workspace — แก้ 2026-10-08 QA HP-03) · **เปลี่ยนโหมดได้จาก Settings ในแอปเท่านั้น** · orientation **ไม่ใช่ตัวสลับโหมด** — ถ้าถือเครื่องไม่ตรงโหมด จะเห็นหน้าเต็มจอ "Rotate your phone to use Lite/Spatial Mode." บล็อกไว้ (รายละเอียด UI ใน [ux-ui-plan.md §3.4–3.5](ux-ui-plan.md))

| | **Lite Mode** | **Spatial Mode** |
|---|---|---|
| Orientation ที่ใช้ได้ | **แนวตั้ง** เท่านั้น (แนวนอน → หน้า Rotate) | **แนวนอน** เท่านั้น (แนวตั้ง → หน้า Rotate) |
| แมพ VO (PixiJS) | **ไม่โหลดเลย** — ไม่โหลด map / object / spritesheet / engine (เหตุผลจาก Ten: ประหยัดเวลาและทรัพยากร) | โหลดเต็ม + joystick 128×140 + HUD |
| ตัวตนในออฟฟิศ | **ghost** — ไม่มี avatar บนแมพ, เดินไม่ได้, ไม่รู้ว่าคนอื่นอยู่ตรงไหน · คน desktop/Spatial เห็นเป็น **tile ใน meeting เท่านั้น** | avatar ปกติเหมือน desktop |
| หน้าหลัก | **Lite Home**: header workspace + Start spotlight / Instant meeting + ค้นหา + "In meeting" + "Circle" + Online / Offline list | แมพเต็มจอ |
| Navigation | bottom nav **3 ปุ่ม Home / Chat / Profile** (icon-only, หดตอนเลื่อน · Calendar ซ่อนไปก่อน — OQ 21) | ปุ่มกลม 5 ปุ่มขวาบน (weather, spotlight, calendar, members, notifications) + chat ซ้ายล่าง · Settings / status / Profile อยู่ที่ปุ่ม avatar ในแถบ Meeting Menu ข้างปุ่มไมค์ |
| ประชุม | Instant meeting / แตะห้องใน "In meeting" (พฤติกรรมตอนแตะ — รอ subtask ถัดไป, open question 11) · **ไม่ผ่านหน้า pre-join** (preview กล้อง/ตั้งชื่อตัวละคร) | เดินเข้า zone · แถบ cam/mic/leave กลางล่าง · tile คนพูด 168×158 |
| แชท (Figma HP-05) | หน้า Chat list เต็มจอ (tab All/Channel/Group/DM) → ห้องเต็มจอ · FAB Create chat / Start a new chat · long-press เมนู · voice message · emoji picker ของเราเป็น sheet | overlay 2 คอลัมน์ 249/515 ทับแมพ (แมพ render ต่อ) · ปุ่ม filter แทน tab · พฤติกรรมอื่นเหมือนกัน |
| ก่อนเข้า workspace (Figma HP-07) | Splash → 3 slide (ไม่มี Skip) → Login → Space builder / Create workspace — **แนวตั้งอย่างเดียว** ทั้งสองโหมด (**tablet**: แนวนอนได้ จัดคอลัมน์กลางจอ เพราะรองรับ Split View — EC-03) · Enter Workspace → Select workspace mode → Lite เข้า Home เลย | → Spatial ผ่านหน้า welcome / pre-join ก่อนเข้าแมพ |
| การเปลี่ยนโหมด | Settings → เลือกโหมดใหม่ → โหลดพื้นผิวใหม่ (Lite ↔ Spatial ไม่มีการสลับสด) | เหมือนกัน |

**ไม่ใช่สิ่งเดียวกัน:** *Simple Mode* ใน ClickUp EP-01 (performance level 4: map นิ่ง + dots) เป็น fallback **ภายใน Spatial Mode** · *Lite Mode* ไม่มีแมพเลย

**ประวัติมติ:** เช้า 2026-09-30 เคยวางว่า "หมุนเครื่องแล้วสลับโหมดทันที" → เปลี่ยนตอนเย็นหลังเห็น Figma HP-03 (Select workspace mode + Keep This Setting + หน้า Rotate) และ Ten ยืนยัน "ต้องไปตั้งค่าในแอปเท่านั้น"

รายละเอียดเชิงโค้ด (mode setting, หน้า Rotate, Lite ไม่โหลด engine, ghost client ใน zyra-ws) อยู่ใน [technical-design.md §16](technical-design.md)

## Out of scope (รอบแรก)

- **Screen share บนมือถือ** — WKWebView / Android WebView ไม่มี `getDisplayMedia` ต้องซ่อนปุ่มบน mobile และแจ้งลูกค้าล่วงหน้า (Tier 3)
- Background blur / virtual background / noise suppression บนเครื่องอ่อน — ปิดโดย default บน mobile (MediaPipe หนัก) เปิดได้ใน settings
- Map Editor / admin pages บนมือถือ — desktop only ต่อไป · **ซ่อนเมนูบนมือถือ เปิด URL ตรง → Space builder + toast "This page is available on desktop only."** (ux-ui-plan §19.6)
- Microsoft login บนมือถือ — ยังไม่ทำ (Ten 2026-10-01, OQ 5)
- Tarot widget / Participation Dashboard / Quiz / Poll / AI Meeting Summary / Meeting alert — ยังไม่มีฟีเจอร์ · จุดที่จะมีปุ่มให้กดแล้วขึ้น **"Coming soon"** (Ten 2026-10-01) · Calendar ซ่อนทั้งหมดตามมติเดิม (OQ 21) · **แก้ 2026-10-02: ซ่อนทั้งหมด ไม่มี Coming soon** (ux-ui-plan §19.7)
- Tablet layout เฉพาะ (2 คอลัมน์ / sidebar) — tablet ใช้ UI มือถือยืดเต็มจอ 1 คอลัมน์ตาม Figma EC-03 (OQ 9 ปิด 2026-10-01) · ยกเว้น meeting grid 3×3 บน tablet ที่ทำ (รอ design)
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
| 3 | ชื่อแอปบน store / bundle id (`co.zyraworld.app`?) / ไอคอน | 1 | Ten 2026-10-01 | **ปิด** — ชื่อแอป **Zyra World** · ไอคอน = **logo Zyra World ตัว Z** · bundle id / package = **`co.zyraworld.app`** (iOS + Android · ไม่ใช้ `com.zyra.app` ของ ClickUp) |
| 4 | ต้องการ companion-first (แบบ Gather 1.0) เพื่อออก store เร็ว หรือรอ Full VO ครบก่อน submit | 1 | — | มติปัจจุบัน: Full VO |
| 5 | Microsoft login บนมือถือต้องมีไหม (บนเว็บตอนนี้ยังไม่พบ MSAL ในโค้ด) | 1 | Ten 2026-10-01 | **ปิด — ยังไม่ต้องทำ** (รอบแรกมีแค่ email, Google, Apple) |
| 6 | **Lite Mode มีอะไรบ้าง** | 0 | Figma HP-03 | **ตอบแล้ว** — Lite Home: header workspace, Start spotlight / Instant meeting, ค้นหา, In meeting, Circle, Online/Offline, bottom nav 4 (ux-ui-plan §3.8) · Calendar tab ยังไม่มี feature ในโค้ด (ค้าง) |
| 7 | ใน Lite Mode ผู้ใช้ยัง "อยู่ในออฟฟิศ" ไหม | 0 | Ten 2026-09-30 | **ตอบแล้ว** — เป็น **ghost**: ไม่มี avatar บนแมพ, เดินไม่ได้, ไม่รู้ตำแหน่งคนอื่น · คน desktop/Spatial เห็นเป็น tile ใน meeting เท่านั้น (TD §16.2) |
| 8 | Lite Mode โหลด engine เบื้องหลังไหม | 0 | Ten 2026-09-30 | **ตอบแล้ว** — **ไม่โหลด** map / object / engine เลย (ประหยัดเวลา + ทรัพยากร) |
| 9 | Tablet ≥ 768px มี 2 โหมดไหม หรือ desktop layout ทั้งสอง orientation · หน้าไหน lock orientation (login / onboarding portrait only?) | 0, 1 | — | **ปิด 2026-10-01** | · **2026-10-01 (HP-07): หน้าก่อนเข้า workspace = แนวตั้งอย่างเดียว** (splash, slide, login, Space builder, Create workspace) · tablet ยังค้าง · **2026-10-01 (Figma EC-03): iPad แนวตั้ง = Lite Home ยืด 1 คอลัมน์ · แนวนอน = Spatial HUD มือถือ → tablet ใช้ UI มือถือ ไม่ใช่ desktop** → **Ten ยืนยัน: tablet = UI มือถือ** (ux-ui-plan §17.7)
| 11 | ใน Lite Home แตะการ์ดห้อง "In meeting" หรือ Circle แล้ว (ก) เข้าห้องทันทีเป็น tile ghost + เปิดหน้าประชุมแนวตั้ง หรือ (ข) ดูรายชื่อก่อนแล้วกด Join | 0 | — | **ข้ามไปก่อน** — Ten: จะกำหนดใน subtask ถัดไป (HP-04/05/06) |
| 12 | Lite Mode ต้องผ่านหน้า pre-join ("Welcome to …" preview กล้อง + ชื่อตัวละคร + Join space) ไหม · Figma มีแต่แนวนอน | 0 | Ten 2026-09-30 | **ตอบแล้ว — ไม่ต้องผ่าน** Lite เข้า Home เลย |
| 13 | Remind me again / Always เก็บที่ไหน | 0 | Ten 2026-09-30 | **ตอบแล้ว — localStorage ต่อเครื่อง, จำ 1 วัน** (ตีความ 24 ชม. จากตอนกด Confirm) · Always = ไม่หมดอายุ · ไม่ต้องมี API · **ยืนยันซ้ำ 2026-10-01 (HP-06):** จำรวมทุก workspace — sticky Figma 6379-34974 ที่ให้ถามซ้ำตอนสลับ workspace ไม่ใช้ · **แก้ 2026-10-08 (QA HP-03, Ten เลือก "ถามทุกครั้ง"):** Remind me again = **ถามใหม่ทุกครั้งที่เข้า workspace** (รวม workspace ที่เพิ่งสร้าง) · มีแค่ Always ที่ข้ามหน้าเลือกโหมด |
| 14 | PIP บนมือถือ: แนวนอน tile แทนที่ minimap ใช่ไหม · แนวตั้งลากได้ไหม | 0 | Ten 2026-10-01 | **ปิด 2026-10-01** — แนวนอน minimap ไม่หาย → PIP อยู่ขวาล่างเหนือ minimap (design ยืนยันตำแหน่ง) · แนวตั้ง **ลาก PIP ไม่ได้** (ตำแหน่งตายตัวตาม Figma) |
| 15 | Join meeting modal บนแมพ (Spatial) เปิดจากไหน — แตะห้องบนแมพ / รายชื่อสมาชิก | 0 | Ten 2026-10-01 | **ปิด** — **แตะห้องบนแมพ** เปิด modal · แตะในห้องจากนอกห้องเท่านั้น (ที่อื่น tap-to-walk) · Join = avatar เดินเข้าห้องอัตโนมัติ · อยู่ในห้องแล้วไม่เปิด (Ten ยืนยัน 2026-10-01) |
| 16 | UI ที่ต้องขอ design เพิ่ม: Setting ห้อง, ~~sheet ชวนคน, popup อนุญาต Request to join~~ → **Participants sheet + Invite sheet แท็บ Chat/Link/Email + toast คำขอ** (Pai เขียนโน้ต 2026-10-02 · Ten ตอบครบ ux-ui-plan §8.8 · รอ frame), tile ขยายเต็มจอ (ux-ui-plan §8.7) · **HP-05:** voice message (อัด + player), Create chat sheet + หน้าสร้าง Group/Channel, Thread/info/media panel มือถือ, เมนู ⋮ ใน preview, Forward/Select flow (ux-ui-plan §9.7) | 0 | — | รอ design |
| 17 | HP-05 FAB **"Create chat"** = สร้าง Group หรือ Channel (โค้ดแยก 2 ปุ่ม) · มี sheet เลือกประเภทไหม | 0 | Ten 2026-10-01 | **ปิด** — มีให้เลือกสร้างทั้ง Group และ Channel (sheet เลือกประเภท) |
| 18 | HP-05 mention "คนที่คุยบ่อย 3–4 คน" นับจากอะไร | 0 | Ten 2026-10-01 | ตอบแค่ **@Everyone ล่างสุด** · เกณฑ์ยังไม่ระบุ → **สมมติ: เรียงตามคนที่มีข้อความถึงกันล่าสุดในห้องนี้** (เปลี่ยนได้ตอน implement) |
| 19 | HP-05 preview image เมนู ⋮ มีอะไร | 0 | Ten 2026-10-01 | download = บันทึกลง Photos ✅ · รายการใน ⋮ ยังไม่ระบุ |
| 20 | สถานะ `dnd` (ห้ามรบกวน) ในโค้ด — Figma HP-06 มีแค่ Active / Busy / Away บนมือถือ | 0 | Ten 2026-10-01 | **ปิด** — ไม่ตัด ไม่รวม · **เพิ่ม Do not disturb** เป็นตัวที่ 4 ใน status picker มือถือ (design ยืนยันแถว) |
| 21 | แท็บ Calendar ใน bottom nav — ไม่มี frame ใน Figma และไม่มี feature ในโค้ด | 0 | Ten 2026-10-01 | **ปิด** — **ซ่อนไปก่อน** · bottom nav 3 แท็บ Home / Chat / Profile · **ซ่อน Calendar ทั้งหมด** (Ten ยืนยัน): ปุ่ม calendar ขวาบน Spatial + กลุ่ม Calendar ใน Notification settings ด้วย |
| 22 | สร้าง workspace ใหม่บนมือถือทำไหม | 0 | Ten 2026-10-01 | **ตอบแล้ว — ทำ** (Figma HP-07 มี flow Create workspace 3 step · Capacity slider เฉพาะมือถือ · details อ่านอย่างเดียว) |
| 23 | PWA install + smart banner "Meet Zyra on mobile" | 0 | Ten 2026-10-01 | **ตอบแล้ว — ยังรองรับติดตั้ง PWA** (ทำคู่กับ smart banner) · Android → Play Store · **ยืนยันแล้ว (Ten 2026-10-01):** banner โชว์ทั้ง landing page + zyra-app บนเบราว์เซอร์มือถือ · กด Later ซ่อน 7 วัน · PWA install prompt ขึ้นเฉพาะคนที่กด Later ไปแล้ว (หลัง 2 visits) · เหลือแค่ UI install prompt ที่ยังไม่มีใน Figma |
| 24 | Push แยกจาก in-app — บนมือถือแสดงสวิตช์ in-app ที่ไหน | 0, 2 | Ten 2026-10-01 | **ตอบแล้ว — 2 สวิตช์ต่อแถว** (in-app + push ในแถวเดียวกัน) · layout แถว/หัวคอลัมน์ยังต้องให้ design ทำ · **แก้ 2026-10-02 (โน้ต Pai): สวิตช์เดียวต่อแถว = push · in-app รายประเภทตั้งบนเว็บ → ux-ui-plan §19** |
| 25 | Weather push — ตารางขีดตัด Weather Warning/Emergency (ไม่ส่ง) แต่คำตอบข้อ 9 บอกแตะ weather แล้วเปิดแอป และ lock screen มี "Emergency Alert" | 2 | Ten 2026-10-01 | **ตอบแล้ว — รอบนี้ไม่ส่ง weather push** · ถ้ากลับมาส่งเมื่อไหร่ แตะแล้วแค่เปิดแอป |
| 26 | Profile / Notification settings แนวนอน = หน้าเต็มจอ (frame HP-08) หรือ modal ทับแมพ (คำตอบ HP-06 ข้อ 4) | 0 | Ten 2026-10-01 | **ตอบแล้ว — ยึด frame HP-08 = หน้าเต็มจอ มีปุ่ม ×** ไว้ก่อน (แทนคำตอบ HP-06 ข้อ 4 ที่ว่า modal) |
| 27 | HP-10 toast "Poor connection" กด × แล้วซ่อนนานแค่ไหน | 0 | Ten 2026-10-01 | **ตอบแล้ว — ซ่อน 20 วินาที** · ถ้ายังแย่หลังครบ 20 วิ toast ขึ้นใหม่ |
| 28 | HP-10 หน้าหลักแบบ skeleton + "Reconnecting..." (ช่วง ② หลังตัด meeting) ไม่มี frame ใน Figma | 0 | Ten 2026-10-01 | **Ten ขอให้ทำ** → ข้อเสนอ spec ux-ui-plan §14.8 (ใช้ layout Lite Home §3.8 / แมพ §3.9 + กฎ skeleton HP-07) · ต้องให้ design ยืนยันก่อนทำจริง |
| 29 | EP-01 Level 4 เข้าที่ FPS เท่าไร · ต้องต่ำต่อเนื่องนานแค่ไหนต่อ level · เกณฑ์ขาขึ้น | 0 | — | Ten ตอบแค่ "ใช้ของ Figma" (L1 < 25 · L2 < 21 · L3 < 15) · **สมมติ:** 10 วิต่อขั้น · L4 = ยัง < 15 หลัง L3 อีก 10 วิ · ขาขึ้น > 45 นาน 30 วิต่อขั้น |
| 30 | EP-01 เตือน RAM ต่ำ (< 200MB, ต้อง native plugin) ทำไหม | 1 | — | Ten ตอบกลับเป็นคำถามเดิม · **สมมติ: ทำ** (task 1.15) รอยืนยัน |
| 31 | EP-02 map แถบ bandwidth ของ Figma (720/480/360) เข้ากับ simulcast เดิม 720/360/180 · เกณฑ์กลับมาดี · toast ปิดเองกี่วิ · ระหว่างแชร์จอทำยังไง | 0 | — | **สมมติ:** > 2 Mbps = 720 · 0.5–2 Mbps = 360 · Poor connection < 1 Mbps · กลับมาดี > 1 Mbps นาน 10 วิ · toast อื่นปิดเอง 10 วิ · แชร์จอไม่หยุดอัตโนมัติ ให้ LiveKit ลดคุณภาพเอง |
| 32 | EC-03 ตัวตัดสิน UI มือถือ (app = เสมอ · เว็บ = จอสัมผัส + ด้านยาว ≤ 1366) · iPad Split View กับ orientation lock · small phone 320–375 · font scaling · meeting grid tablet | 0, 1 | Ten 2026-10-01 | **ปิด** — app = UI มือถือเสมอ · เว็บ = จอสัมผัส + ด้านยาว ≤ 1366 (iPad + trackpad นับ) · รองรับ Split View, โหมดตัดสินจากสัดส่วนหน้าต่าง, หน้าก่อนเข้า workspace บน tablet แนวนอนได้จัดกลาง · small phone ใช้ layout 390 + ellipsis · font lock 100% รอบแรก · meeting grid 3×3 บน tablet ทำ · dark อย่างเดียว |
| 33 | HP-11 Spotlight บนมือถือ — ฝั่งคนดู (ไม่มี Figma), Lite เริ่มโดยไม่มีตำแหน่ง, Spatial เริ่มจาก megaphone, หลาย floor, LIVE + ผู้ชม, multiple spotlight | 0 | Ten 2026-10-01 | **ปิด** — คนดูนอก meeting เปิดเต็มจออัตโนมัติ · ใน meeting ยึด web (Join spotlight / Stay in meeting) · Lite เริ่มได้เลย ghost เดินไป marker · Spatial megaphone → auto-walk + เปิดหน้า · floor แรก · chevron = PIP · Stop/leave ตอน live ถามยืนยัน · started toast 3 วิ · chip LIVE · N (design ยืนยัน) · share = Phase 3 · หลายคนพูด = tile ไม่มี tab · ทุกคนเริ่มได้ยกเว้น Busy/Away/DND · **แก้ 2026-10-02 (โน้ต Pai): คนดู: LIVE + Mic/Eye · menu Chat/Speaker/Leave · รายชื่อ 2 แท็บ → ux-ui-plan §19** · **แก้ 2026-10-05 (Figma HP-11 v2): Figma มีแนวนอนแล้ว · คนดูได้ toast ✓/× · ใน meeting ✓ ทั้งห้อง → ux-ui-plan §18.9** |
| 10 | Meeting ใน Spatial Mode — grid ซ้อนบนแมพ (เห็นแมพข้างหลัง) หรือ meeting เต็มจอแทนแมพ | 0 | — | Figma HP-03 แสดง tile คนพูด 168×158 ซ้อนบนแมพ (ux-ui-plan §3.9) · grid เต็มรอ Figma HP-04 |
