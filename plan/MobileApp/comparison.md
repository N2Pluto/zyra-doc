# Mobile App — เปรียบเทียบ Capacitor vs Expo vs Flutter

> **สถานะ:** ตัดสินแล้ว — **เลือก Capacitor + native feature จริง** (2026-09-29) · Expo = Plan B · Flutter ไม่เลือก · **repo:** zyra-app (หลัก)
> **อิงโค้ด ณ:** zyra-app develop — Next.js 16.2.4 · React 19.2 · PixiJS 8.18 · livekit-client 2.20 · หน้าเว็บ: https://mobile-app-plan.vercel.app/comparison.html
> **เอกสารคู่กัน:** [spec.md](spec.md) · [technical-design.md](technical-design.md) (§1 ข้อเท็จจริง, §11–13 native/background/reconnect) · [task-breakdown.md](task-breakdown.md)

## มติ

| | Capacitor | Expo / React Native | Flutter |
|---|---|---|---|
| **ผล** | **เลือก** | Plan B | ไม่เลือก |
| เหตุผลหลัก | ใช้โค้ด zyra-app เดิม 100% ขึ้น store ทั้งสองได้เร็วสุด | native แท้แต่ต้อง rewrite engine 27k + HUD 49k บรรทัด | rewrite ทั้งหมด ~76k บรรทัดเป็น Dart แชร์กับ zyra-app ไม่ได้เลย |
| Trigger ที่จะสลับ | — | FPS < 20 บน iPhone 12 / Pixel 6a หลัง tuning ครบ **หรือ** Apple reject 4.2 สองรอบหลังใส่ native Tier 1 ครบ | — |

## 1. ข้อเท็จจริงในโค้ด → กระทบแต่ละตัวยังไง

| ข้อเท็จจริงในโค้ด zyra-app | Capacitor | Expo / RN | Flutter |
|---|---|---|---|
| PixiJS 8 engine `zyra-engine/pixi-game/` ~27k บรรทัด ผูก `window`/`document` events | ใช้ซ้ำได้ทั้งก้อน | **rewrite ทั้งก้อน** — ไม่มี PixiJS renderer บน RN ต้องใช้ react-native-skia หรือ expo-gl + engine ใหม่ | **rewrite เป็น Flame** |
| HUD React + Tailwind `views/user/virtual-office/` ~49k บรรทัด | ใช้ซ้ำ + ทำ responsive (Phase 0) | rewrite เป็น RN component (Tailwind → StyleSheet/NativeWind, radix → RN) | rewrite เป็น Widget |
| livekit-client (`lib/api/sfu-client.ts`) mic/cam/screen share/blur/noise | รันใน WebView ได้ ยกเว้น screen share (ไม่มี `getDisplayMedia`) | `@livekit/react-native` official ครบ รวม screen share | `livekit_client` official ครบ |
| raw WebSocket ตัวเดียว `lib/api/workspace-ws.ts` + reconnect ครบ | ใช้ได้เลย | ใช้ได้ถ้าแยก DOM (`document.visibilityState`, `window.focus`) ออก | เขียนใหม่เป็น Dart |
| Auth: cookie `zyra_token` + refresh httpOnly + `proxy.ts` | ใช้ได้ (โหมด remote URL origin = domain จริง) | เปลี่ยนเป็น bearer + SecureStore, `proxy.ts` ไม่ได้ใช้ | เปลี่ยนเป็น bearer |
| Google login implicit flow ทำเอง → `/api/authen/login_google` | native plugin → id_token → endpoint เดิม | expo-auth-session → endpoint เดิม | google_sign_in → endpoint เดิม |
| Next.js `output: standalone` + rewrite proxy + server route `/api/img` | ต้องใช้โหมด remote URL (static export ไม่ได้ทันที) | ไม่เกี่ยว (แอปแยก) | ไม่เกี่ยว |
| ไม่มี push, ไม่มี mobile layout, ไม่มี joystick | ต้องทำใหม่ทั้งสามอย่าง | ต้องทำใหม่ทั้งสามอย่าง | ต้องทำใหม่ทั้งสามอย่าง |
| ทีมเป็น React/TS | ทำได้ทันที | ทำได้ เรียน RN เพิ่ม | เรียน Dart + Flutter ใหม่ |

**บรรทัดล่างสุดสำคัญ:** งานที่หนักที่สุดของโปรเจกต์ (mobile layout, touch control, performance, push backend) **ต้องทำเท่ากันทั้งสามตัว** สิ่งที่ต่างคือ Expo/Flutter ต้องบวก rewrite ~76k บรรทัดเข้าไปอีก

## 2. ตารางคะแนน (เชิงคุณภาพ — ยังไม่ได้วัดจริงบนเครื่อง)

| เกณฑ์ | Capacitor | Expo / RN | Flutter |
|---|---|---|---|
| ใช้โค้ดเดิมได้ | ●●●●● | ●○○○○ | ○○○○○ |
| เวลาถึง store | ●●●●● | ●●○○○ | ●●○○○ |
| Performance ในแมพใหญ่ | ●●●○○ | ●●●●○ | ●●●●● |
| Native feel | ●●○○○ | ●●●●○ | ●●●●○ |
| Meeting / background audio | ●●●○○ | ●●●●● | ●●●●● |
| ค่าดูแลระยะยาว (codebase เดียว) | ●●●●● | ●●○○○ | ●○○○○ |
| ความเสี่ยง App Store review (4.2) | ●●○○○ | ●●●●● | ●●●●● |
| Update โดยไม่ submit ใหม่ | ●●●●● (remote URL) | ●●●●○ (EAS Update) | ●●○○○ (Shorebird 3rd-party) |
| ทีมเริ่มได้ทันที | ●●●●● | ●●●○○ | ●○○○○ |

ตัวเลข FPS/memory จริงจะได้จาก Phase 0 task 0.9 (ดู [task-breakdown.md](task-breakdown.md)) และบันทึกใน [progress.md](progress.md)

## 3. ข้อดี / ข้อเสีย

### 3.1 Capacitor — เลือก

**ข้อดี**
- ใช้โค้ดเดิม 100% (engine + HUD + livekit + ws + auth) · deploy เว็บ = deploy mobile · codebase เดียว
- ขึ้น store ทั้งสองจาก project เดียว · plugin official ครอบ Tier 1–2 ทั้งหมด (push, haptics, status bar, splash, keep-awake, share, deep link, sign-in)
- WebRTC + WebGL รันใน WKWebView (iOS ≥ 14.3) / Android System WebView ได้
- Google/Apple sign-in ผ่าน plugin แล้วยิง id_token เข้า endpoint เดิม ไม่ต้องแก้ backend (ยกเว้น `login_apple` ใหม่)
- ของที่ไม่มี plugin เขียน Swift/Kotlin เองผ่าน Capacitor plugin API ได้
- โหมด remote URL: แก้บั๊กเว็บแล้วมือถือได้ทันที ไม่ต้อง submit ใหม่ (Apple อนุญาต JS ใน WebKit ตาม 2.5.2)
- reconnect / visibility handling ที่มีอยู่แล้วใน `workspace-ws.ts`, `use-meeting-media.ts`, hero, engine ใช้ต่อได้ ~90% (technical-design §13.2)

**ข้อเสีย / ความเสี่ยง**
- Apple 4.2 minimum functionality — ต้องมี native feature จริง (Tier 1) ตั้งแต่ submit แรก
- Performance ต่ำกว่า native โดยเฉพาะ Android เครื่องล่าง — ต้อง profile บนเครื่องจริง
- Screen share ทำไม่ได้ใน WebView — ต้องเขียน native plugin (Tier 3)
- iOS background: WebView ถูก suspend นอกประชุม — WebSocket ค้างไม่ได้ ต้องแก้ด้วย grace period ฝั่ง zyra-ws (technical-design §12)
- Background audio ต้อง iOS ≥ 17.5 (ต่ำกว่านั้น mic mute ตอน background)
- CallKit ใช้กับ WebRTC ใน WKWebView ไม่ได้ (AVAudioSession ชนกัน)
- Remote URL: server ล่ม = แอปล่ม · ต้อง whitelist navigation
- Native feel ต่ำสุดในสามตัว

### 3.2 Expo / React Native — Plan B

**ข้อดี**
- Native UI, performance ดีกว่า WebView · ทีม React ใช้ tanstack-query / zustand เดิมได้
- `@livekit/react-native` official — background audio, CallKit, screen share ทำได้แบบ native
- EAS Build / Submit / Update ครบ — build ทั้งสอง platform บน cloud, OTA update JS ได้
- แชร์ types / ws client / api client ได้ถ้า refactor ให้ไม่แตะ DOM
- ไม่มีปัญหา 4.2 และไม่มีปัญหา WebView suspend

**ข้อเสีย / ความเสี่ยง**
- rewrite game engine 27k บรรทัด — PixiJS v8 ไม่มี RN renderer
- rewrite HUD 49k บรรทัด
- two codebases ถาวร — feature ใหม่ทำ 2 รอบ, บั๊ก VO desync (ที่ไล่มา 8 รอบแล้ว) ต้องไล่ 2 ที่
- auth เปลี่ยนเป็น bearer + SecureStore
- เวลาถึง store หลักเดือน

### 3.3 Flutter — ไม่เลือก

**ข้อดี**
- Performance และ consistency iOS/Android ดีที่สุด (Impeller render เอง)
- `livekit_client` official · Flame เหมาะ 2D tile map
- Tooling ครบ hot reload ดี

**ข้อเสีย / ความเสี่ยง**
- rewrite ทั้งหมด ~76k บรรทัด TS → Dart แชร์กับ zyra-app ไม่ได้แม้แต่ types
- ทีมต้องรักษา 2 ภาษา 2 stack · sprite/asset pipeline ทำใหม่
- ไม่มี OTA official (Shorebird เป็น third-party)
- เวลาถึง store นานเท่ากับหรือมากกว่า RN

## 4. ตัวเลือกอื่นที่พิจารณาแล้ว

| ตัวเลือก | สรุป | ทำไมไม่เลือก |
|---|---|---|
| PWA อย่างเดียว | ต่อยอด manifest / sw.js เดิม · iOS 16.4+ ทำ web push ได้ | ไม่ขึ้น store · iOS PWA ไม่มี background audio, getUserMedia ใน standalone มีบั๊ก — แต่ Phase 0 ของ Capacitor ทำให้ PWA ดีขึ้นฟรี |
| RN shell + WebView สำหรับ VO | native navigation/push, VO อยู่ใน WebView | ได้ข้อเสีย WebView ทั้งหมด + ต้องดูแล RN เพิ่ม ไม่คุ้มกว่า Capacitor |
| Kotlin / Compose Multiplatform | native แท้ 2 platform | rewrite ทั้งหมด · ทีมต้องเรียน Kotlin · ecosystem WebRTC/LiveKit บน KMP ยังไม่ mature |
| Tauri 2 mobile | เบากว่า Capacitor (Rust) | plugin mobile ยังน้อย · push/sign-in ต้องเขียนเอง · เสี่ยงกว่าโดยไม่ได้อะไรเพิ่ม |
| Unity / Godot | game engine เต็มรูปแบบ | overkill · rewrite ทั้งหมด · HUD/chat/meeting ทำยากมากใน game engine |

## 5. Reference — Gather

- Gather 2.0 (2025-09) **ไม่มี mobile app** — desktop + browser เท่านั้น
- Gather 1.0 มีแอป "Gather Meetings" (2023-08) เป็น companion — ประชุม/แชท/presence **เดินในแมพไม่ได้**
- Renderer ฝั่งเว็บของ Gather เป็น Pixi + canvas เหมือน zyra-engine

ไม่มีคู่แข่งทำ Full VO บนมือถือสำเร็จ ความเสี่ยงหลักของเราจึงอยู่ที่ Phase 0 (touch, performance, responsive HUD) ไม่ใช่ที่การเลือก framework — ซึ่ง Capacitor เป็นตัวเดียวที่ทำให้ Phase 0 นับเป็นงานของ mobile app โดยตรง ไม่ใช่งานที่ทำแล้วต้องทำซ้ำอีกรอบใน RN/Flutter
