# Mobile App — Task Breakdown

> **สถานะ:** Planning — ยังไม่เริ่ม task ไหน (2026-09-29) · **repo:** zyra-app, zyra-mobile, zyra-api, zyra-notifications, zyra-ws
> ทุก task ขนาด 1 PR · branch จาก `develop` ตามกฎ git branch workflow · ตัวเลข before/after ลง [progress.md](progress.md)
> **เอกสารคู่กัน:** [spec.md](spec.md) · [technical-design.md](technical-design.md)

ลำดับ: **Phase 0 ก่อนทุกอย่าง** · Phase 1 กับ Phase 2 ทำคู่ขนานได้ · Phase 3 หลัง store approve

## Phase 0 — Mobile web ใช้ได้จริง (zyra-app)

| # | Task | ไฟล์หลัก | ขึ้นกับ | Done เมื่อ |
|---|---|---|---|---|
| 0.1 | Feature flag `NEXT_PUBLIC_MOBILE_VO` — overlay "Mobile unsupported" แสดงเฉพาะเมื่อ flag ปิด หรือหน้า admin/editor | `components/mobile-unsupported-overlay.tsx`, `app/layout.tsx` | — | flag เปิด → หน้า VO เข้าได้บนมือถือ · flag ปิด → เหมือนเดิม |
| 0.2 | Viewport + safe area สำหรับหน้า VO — `viewport-fit=cover`, `user-scalable=no` เฉพาะ route `/workspace/[id]/play`, ใช้ `env(safe-area-inset-*)` ใน HUD container | `app/layout.tsx`, `views/user/virtual-office/hero-virtual-office.tsx` | 0.1 | ไม่มี horizontal scroll · HUD ไม่โดน notch |
| 0.3 | Virtual joystick component + ส่ง `{dx,dy}` เข้า scene ผ่าน `pixi-canvas.tsx` ref · map เข้า V2 `input` intent / legacy `move_to` | `views/user/virtual-office/components/vo-joystick.tsx` (ใหม่), `components/game-canvas/pixi-canvas.tsx`, `zyra-engine/pixi-game/scene.ts`, `zyra-engine/constants.ts` | 0.1 | เดินได้ 8 ทิศบน Safari iOS + Chrome Android |
| 0.4 | Tap-to-walk แยกจาก pan/pinch ด้วย threshold — ใช้ click-to-walk path เดิม | `zyra-engine/pixi-game/scene.ts`, `zyra-engine/constants.ts` | 0.3 | แตะพื้น = เดิน · ลาก = pan · สองนิ้ว = zoom ไม่ชนกัน |
| 0.5 | Responsive HUD ชุดที่ 1 — bottom toolbar, sidebar, status picker, minimap ตาม Figma mobile | `views/user/virtual-office/components/vo-hud.tsx`, `vo-sidebar.tsx`, `vo-status-picker.tsx`, `vo-minimap.tsx` | **Figma mobile design** | ตรง Figma ≥ 95% · ต้องดึง spec ผ่าน Figma MCP ก่อน |
| 0.6 | Responsive HUD ชุดที่ 2 — member panel, chat panel, notification panel เป็น bottom sheet | `vo-member-panel.tsx`, chat panels, `vo-notification-panel.tsx` | 0.5 | เปิด/ปิดได้ · keyboard ไม่บัง input |
| 0.7 | Responsive HUD ชุดที่ 3 — meeting bar, zone enter modal, wave/knock toast, follow bar | ไฟล์ที่เกี่ยวใน `views/user/virtual-office/components/` | 0.5 | เข้า zone + ประชุมได้ครบบนมือถือ |
| 0.8 | Meeting บนมือถือ — ซ่อน screen share/Document PiP เมื่อไม่มี API · ปิด blur/noise-suppressor default บน mobile · สลับกล้องหน้า/หลัง | `views/user/virtual-office/use-meeting-media.ts`, `lib/api/sfu-client.ts`, `vo-background-effects-modal.tsx` | 0.7 | mic/cam ทำงานบน iOS Safari (ต้องกดหลัง user gesture) |
| 0.9 | Performance profile + tuning บน mobile — resolution, filters, nature/pet fallback, culling · บันทึก FPS/memory before/after | `zyra-engine/pixi-game/scene.ts`, `constants.ts`, `components/game-canvas/pixi-canvas.tsx` | 0.3 | FPS ≥ 30 / memory < 400 MB บน iPhone 12 + Pixel 6a ในแมพ 20 คน — ตัวเลขใน progress.md |
| 0.10 | Playwright mobile viewport (iPhone 13 preset) — login → enter workspace → joystick เดิน → เข้า zone | `e2e/` ของ zyra-app | 0.3, 0.7 | ผ่านใน CI |
| 0.11 | Sentry/Mixpanel tag `platform=mobile-web` เพื่อแยก metric | `instrumentation-client.ts` / analytics helper | 0.1 | เห็นใน Sentry/Mixpanel แยก platform |

## Phase 1 — Capacitor shell ขึ้น store

| # | Task | Repo / ไฟล์ | ขึ้นกับ | Done เมื่อ |
|---|---|---|---|---|
| 1.1 | สร้าง repo `zyra-mobile` — `npm init @capacitor/app`, `capacitor.config.ts` (server.url ต่อ flavor dev/uat/prod, allowNavigation), README สั้นชี้มา zyra-doc | zyra-mobile | 0.1 | เปิดแอปบน simulator/emulator แล้วเห็นหน้า login ของ dev |
| 1.2 | Splash, icon, status bar `#1A1B1E`, orientation ทั้ง landscape/portrait, permission string กล้อง/ไมค์/notification | zyra-mobile (`ios/App/App/Info.plist`, `android/app/src/main/AndroidManifest.xml`) | 1.1 | เปิดแอปแล้วไม่มีจอขาว · ขอ permission ตอนใช้ครั้งแรก |
| 1.3 | ตรวจว่า reCAPTCHA + email login ทำงานใน WebView · ถ้าไม่ได้ทำ fallback ตาม technical-design §4 | zyra-app `views/login/*`, zyra-mobile | 1.1 | login email/password ในแอปผ่าน |
| 1.4 | Google native sign-in — plugin + zyra-app branch `isNativePlatform` → `loginWithGoogle(idToken)` เดิม · zyra-api รับหลาย `GOOGLE_CLIENT_ID` | zyra-mobile, zyra-app `lib/auth/session.ts` + login view, zyra-api `internal/service/authen_service.go` (verify aud) | 1.1 | login Google ในแอปผ่านทั้ง iOS/Android |
| 1.5 | Sign in with Apple — plugin + `POST /api/authen/login_apple` (verify JWT กับ Apple keys, ผูก user ด้วย sub/email) + table-driven test | zyra-api handler/service ใหม่, zyra-app login view, zyra-mobile | 1.4 | login Apple ผ่าน · test ≥ 80% |
| 1.6 | Lifecycle — `appStateChange` → ws `visibility` + reconnect, SFU re-attach, Pixi ticker pause/resume · keep-awake ใน VO | zyra-app `stores/vo-session-store.ts`, `components/game-canvas/pixi-canvas.tsx` | 1.1 | สลับแอป 30 วิ กลับมา ws ต่อภายใน 5 วิ |
| 1.7 | iOS background audio — `UIBackgroundModes: audio` + AVAudioSession category ผ่าน plugin · ทดสอบเสียงประชุมค้างตอน background | zyra-mobile iOS | 1.6 | ออกจากแอปกลางประชุม ยังได้ยินเสียง |
| 1.8 | Push client — `@capacitor/push-notifications` + Firebase SDK (iOS) → `POST /api/user/devices` หลัง login · `DELETE` ตอน logout · tap payload → route | zyra-mobile, zyra-app `lib/api/devices.ts` (ใหม่) + `lib/auth/session.ts` | 2.1 | token ถูกบันทึกใน DB · แตะ push เปิดหน้าที่ถูก |
| 1.9 | Deep link `zyra://` + universal links (AASA + assetlinks.json serve จาก zyra-app `public/.well-known/`) | zyra-mobile, zyra-app `public/.well-known/` | 1.1 | เปิดลิงก์ workspace แล้วเข้าแอปตรง |
| 1.10 | Native polish Tier 2 — haptics (wave/knock/join zone), badge count, share sheet ส่ง invite, keyboard handling | zyra-mobile, zyra-app จุดที่เรียก wave/knock + invite modal | 1.1 | ครบตามรายการ Tier 2 ใน spec |
| 1.11 | หน้า offline native + retry — ตรวจ `server.url` reachable ก่อนโหลด, error page ของ WebView ถูกแทนด้วยหน้าของแอป | zyra-mobile | 1.1 | ปิดเน็ตแล้วเปิดแอป → เห็นหน้า offline ของเรา |
| 1.12 | CI — GitHub Actions: iOS (macos runner + fastlane match/sign + TestFlight), Android (AAB + Play internal) · secrets ใน GitHub Environment · version = tag `v*` | zyra-mobile `.github/workflows/` | 1.2 | push tag → build ขึ้น TestFlight + Play internal อัตโนมัติ |
| 1.13 | Store listing + review notes (test account, workspace demo, วิดีโอ) · submit | store consoles | ทุกข้อใน Phase 1 | approve ทั้งสอง store |

## Phase 2 — Push backend

| # | Task | Repo / ไฟล์ | ขึ้นกับ | Done เมื่อ |
|---|---|---|---|---|
| 2.1 | Migration `tb_user_device` + `POST/DELETE /api/user/devices` (handler → service, UserGuard) + table-driven test | zyra-api `migrations/`, `internal/handler/device_handler.go`, `internal/service/device_service.go` | — | test ≥ 80% · migration รันบน dev |
| 2.2 | Firebase project + APNs key + service account · ใส่ `FCM_SERVICE_ACCOUNT_JSON` ใน secret ผ่าน ESO (dev/uat/prod) | Firebase console, zyra-infra secret | Apple dev account | secret sync เข้า cluster |
| 2.3 | zyra-notifications provider FCM HTTP v1 + `POST /push` ภายใน + ลบ token เมื่อ UNREGISTERED + test | zyra-notifications `internal/push/fcm.go`, handler | 2.1, 2.2 | ส่ง push ทดสอบถึงเครื่องจริง |
| 2.4 | zyra-ws trigger — DM/mention/knock/meeting invite ถึง user ที่ไม่มี connection → publish ไป zyra-notifications · เช็ค notification settings | zyra-ws `internal/hub/*.go` จุดที่ส่ง DM/knock/invite, `store/redis.go` | 2.3 | DM ถึง user offline → push ภายใน 5 วิ |
| 2.5 | Notification settings บน zyra-app มี toggle push ต่อประเภท · sync ไป backend | zyra-app `stores/notification-settings-store.ts` + settings UI, zyra-api | 2.4 | ปิด toggle แล้วไม่ได้ push |

## Phase 3 — หลัง store approve (ตาม demand)

| # | Task | หมายเหตุ |
|---|---|---|
| 3.1 | วัด crash-free / FPS / session length จาก Sentry + Mixpanel แยก platform 2 สัปดาห์แรก | ตัดสินใจ Plan B จากตัวเลขนี้ |
| 3.2 | Custom plugin screen share — ReplayKit (iOS) / MediaProjection (Android) → publish track เข้า LiveKit | งานใหญ่ ต้อง native ทั้งสอง platform |
| 3.3 | CallKit + VoIP push สำหรับ meeting invite | iOS ต้องผ่าน PushKit review เพิ่ม |
| 3.4 | Native PiP ของวิดีโอประชุม · Live Activities | |
| 3.5 | ประเมิน bundle asset ลงแอป (technical-design §3.2) ถ้าต้องการ offline shell หรือลด dependency กับ server | |

## สิ่งที่ต้องได้ก่อนเริ่ม (ไม่ใช่ task โค้ด)

- [ ] Figma mobile design ของ VO HUD (บล็อก 0.5–0.7)
- [ ] Apple Developer account + Google Play Console (บล็อก 1.5, 1.12, 2.2)
- [ ] ชื่อแอป / bundle id / ไอคอน (บล็อก 1.2)
- [ ] เครื่องทดสอบจริง: iPhone 12 (หรือใกล้เคียง) + Android กลาง (Pixel 6a / Samsung A54)
