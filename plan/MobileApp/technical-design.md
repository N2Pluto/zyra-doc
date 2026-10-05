# Mobile App — Technical Design

> **สถานะ:** Design — มติเลือก Capacitor แล้ว (2026-09-29) · §11–15 native-vs-WebView + background WS/audio/reconnect + native feature inventory ครบทั้ง repo (A5 · B14 · C~53 · D15 · E4) เพิ่ม 2026-09-29 · ยังไม่ implement · **repo:** zyra-app, zyra-mobile (ใหม่), zyra-api, zyra-notifications, zyra-ws
> **อิงโค้ด ณ:** zyra-app — Next.js 16.2.4 · React 19.2 · PixiJS 8.18 · livekit-client 2.20 · ถ้า stack เปลี่ยนให้ทบทวน §1 ก่อนใช้ตัดสินใจ
> **เอกสารคู่กัน:** [spec.md](spec.md) · [comparison.md](comparison.md) (ฉบับเต็มของ §2) · [task-breakdown.md](task-breakdown.md) · [progress.md](progress.md)

## 1. ข้อเท็จจริงจากโค้ดที่ตัดสินใจเลือก

| เรื่อง | ของจริง (path จาก root ของ zyra-app) | ผลต่อการเลือก |
|---|---|---|
| Game engine | PixiJS 8 ใน `zyra-engine/pixi-game/` ~27k บรรทัด (`scene.ts` 11k) — class `PixiGameScene` ไม่ import React แต่ผูก `window` keydown/keyup/blur/wheel/pagehide, `document.visibilityState`, pointer/touch บน canvas | React Native / Flutter ต้อง rewrite engine ทั้งก้อน — PixiJS v8 ไม่มี renderer บน RN/Flutter |
| HUD ของ VO | `views/user/virtual-office/` ~49k บรรทัด React + Tailwind (`hero-virtual-office.tsx` 14.8k) | RN/Flutter rewrite UI ทั้งหมด · Capacitor ใช้ซ้ำได้ 100% แต่ต้องทำ responsive |
| WebRTC | `lib/api/sfu-client.ts` (class `SFUClient`, livekit-client) + `views/user/virtual-office/use-meeting-media.ts` — mic, cam, screen share, blur/virtual bg (MediaPipe), noise suppression, Document PiP | WKWebView (iOS ≥ 14.3) และ Android System WebView รองรับ `getUserMedia` · **ไม่รองรับ `getDisplayMedia`** (screen share) |
| Realtime | raw `new WebSocket()` ตัวเดียวใน `lib/api/workspace-ws.ts` (`WorkspaceWSClient`) สร้างที่ `stores/vo-session-store.ts` · chat ใช้ client เดียวกัน | ใช้ได้ทุก platform ไม่ต้องแก้ |
| Auth | `lib/auth/session.ts` — access token ใน memory + mirror เป็น cookie `zyra_token` (JS-readable, 7 วัน) · refresh token เป็น httpOnly cookie จาก server · `proxy.ts` (Next 16 ใช้แทน middleware) เช็ค cookie ฝั่ง server | WebView ที่โหลดจาก domain จริง → cookie ทำงานเหมือน browser · ถ้า bundle ไฟล์ลงแอป (origin `capacitor://localhost`) cookie/proxy พังทันที |
| Google login | ไม่มี SDK — `app/login/google/page.tsx` ทำ implicit flow เอง (`response_type=id_token`) แล้ว `lib/auth/session.ts` POST `/api/authen/login_google` `{token}` | Google block OAuth ใน embedded WebView (`disallowed_useragent`) → ต้องใช้ native sign-in แล้วส่ง id_token เข้า endpoint เดิม |
| Microsoft login | ไม่พบ MSAL / Microsoft flow ในโค้ด (มีแค่ env `NEXT_PUBLIC_MICROSOFT_*`) | ไม่กระทบรอบแรก |
| Next.js build | `next.config.ts` → `output: "standalone"`, rewrite `/api/*` → `BACKEND_URL`, server route `app/api/img`, `app/api/health`, `app/api/version` | `output: "export"` ไม่ได้ทันที → Capacitor ต้องใช้โหมด **remote URL** |
| Mobile ตอนนี้ | `components/mobile-unsupported-overlay.tsx` render ใน `app/layout.tsx` ด้วย `max-md:flex` → บล็อกทุกหน้า < 768px · engine มี pinch-zoom (`touchstart`) และ pan แต่ **ไม่มี joystick** · เดินด้วย WASD / click-to-walk | ต้องทำ touch control + mobile layout ก่อนเสมอ ไม่ว่าเลือก framework ไหน |
| PWA | `app/manifest.ts` (standalone, landscape) + `public/sw.js` pass-through ไม่มี offline/push · `components/pwa-register.tsx` | ไม่ช่วยเรื่อง store แต่ Phase 0 ทำให้ PWA ดีขึ้นฟรี |
| Push | ไม่มีเลย — ไม่มี FCM/APNs/web-push ใน zyra-api, zyra-ws, zyra-notifications · zyra-notifications ส่ง email (SMTP) อย่างเดียว · in-app notification มาทาง WS | ต้องเพิ่ม device token + FCM ทั้ง backend และแอป |
| Observability | `@sentry/nextjs`, `mixpanel-browser`, GTM มีอยู่แล้ว | ใช้วัด crash-free / FPS บนมือถือได้เลย |

## 2. เปรียบเทียบตัวเลือก

### 2.1 ตารางคะแนน (เชิงคุณภาพ — ยังไม่ได้วัดจริง)

| เกณฑ์ | Capacitor | Expo / RN | Flutter |
|---|---|---|---|
| ใช้โค้ดเดิมได้ | ●●●●● | ●○○○○ | ○○○○○ |
| เวลาถึง store | ●●●●● | ●●○○○ | ●●○○○ |
| Performance ในแมพใหญ่ | ●●●○○ | ●●●●○ | ●●●●● |
| Native feel | ●●○○○ | ●●●●○ | ●●●●○ |
| Meeting / background audio | ●●●○○ | ●●●●● | ●●●●● |
| ค่าดูแลระยะยาว (codebase เดียว) | ●●●●● | ●●○○○ | ●○○○○ |
| ความเสี่ยง App Store review | ●●○○○ | ●●●●● | ●●●●● |
| Update โดยไม่ submit ใหม่ | ●●●●● | ●●●●○ (EAS Update) | ●●○○○ (Shorebird 3rd-party) |

### 2.2 Capacitor — เลือก

**ข้อดี**
- ใช้โค้ดเดิม 100% (engine + HUD + livekit + ws + auth) · deploy เว็บ = deploy mobile
- ขึ้น store ทั้งสองจาก project เดียว · plugin official: push, camera, haptics, status bar, splash, keep-awake, app lifecycle, deep links, share
- WebRTC + WebGL รันใน WKWebView / Android WebView ได้
- Google/Apple sign-in ผ่าน plugin แล้วยิง id_token เข้า endpoint เดิม
- ทีม React/TS เดิมทำได้ทันที · ของที่ไม่มี plugin เขียน Swift/Kotlin เองผ่าน Capacitor plugin API ได้
- โหมด remote URL: แก้บั๊กเว็บแล้วมือถือได้ทันที ไม่ต้อง submit ใหม่ (Apple อนุญาต JS ที่รันใน WebKit ตาม Guideline 2.5.2)

**ข้อเสีย / ความเสี่ยง**
- Apple Guideline 4.2 (minimum functionality) — ต้องมี native feature จริง (Tier 1 ใน spec)
- Performance ต่ำกว่า native โดยเฉพาะ Android เครื่องล่าง — ต้อง profile บนเครื่องจริง
- Screen share ทำไม่ได้ใน WebView — ต้องเขียน native plugin (ReplayKit / MediaProjection) เอง
- iOS background: WS + LiveKit ถูกหยุดเมื่อไป background → ต้อง `UIBackgroundModes: audio` + reconnect
- Remote URL: server ล่ม = แอปล่ม · ต้อง whitelist navigation
- Native feel ต่ำสุดในสามตัว

### 2.3 Expo / React Native — Plan B

**ข้อดี:** native UI · `@livekit/react-native` official · EAS Build/Submit/Update · แชร์ types/ws/api client ได้ถ้า refactor ให้ไม่แตะ DOM
**ข้อเสีย:** rewrite engine 27k (ต้อง react-native-skia หรือ expo-gl + engine ใหม่) · rewrite HUD 49k · two codebases ถาวร (บั๊ก VO desync ต้องไล่สองที่) · auth เปลี่ยนเป็น bearer + SecureStore · เวลาถึง store หลักเดือน

### 2.4 Flutter — ไม่เลือก

**ข้อดี:** performance และ consistency ดีที่สุด · `livekit_client` official · Flame เหมาะ 2D tile map
**ข้อเสีย:** rewrite ทั้งหมด ~76k บรรทัด TS → Dart แชร์กับ zyra-app ไม่ได้แม้แต่ types · 2 ภาษา 2 stack · ไม่มี OTA official

### 2.5 ตัวเลือกอื่นที่พิจารณาแล้ว

| ตัวเลือก | ทำไมไม่เลือก |
|---|---|
| PWA อย่างเดียว | ไม่ขึ้น store · iOS PWA ไม่มี background audio, getUserMedia ใน standalone มีบั๊ก |
| RN shell + WebView สำหรับ VO | ได้ข้อเสีย WebView ทั้งหมด + ต้องดูแล RN เพิ่ม ไม่คุ้มกว่า Capacitor |
| Kotlin / Compose Multiplatform | rewrite ทั้งหมด · ecosystem WebRTC/LiveKit บน KMP ยังไม่ mature |
| Tauri 2 mobile | plugin mobile ยังน้อย · push/sign-in ต้องเขียนเอง · เสี่ยงกว่าโดยไม่ได้อะไรเพิ่ม |
| Unity / Godot | overkill · HUD/chat/meeting ทำยากมากใน game engine |

## 3. สถาปัตยกรรม

```
┌──────────────────────────── zyra-mobile (repo ใหม่) ────────────────────────────┐
│  iOS app (Swift shell)            Android app (Kotlin shell)                    │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │  WKWebView / Android System WebView                                       │   │
│  │  server.url = https://app.zyraworld.co  (dev/uat/prod ตาม build flavor)   │   │
│  │  ── โหลด zyra-app (Next.js) ตัวเดียวกับเว็บ ──                            │   │
│  │  PixiGameScene · HUD · SFUClient (livekit) · WorkspaceWSClient           │   │
│  └───────────────▲──────────────────────────────────────────────────────────┘   │
│                  │ Capacitor bridge (window.Capacitor)                           │
│  plugins: push-notifications · app (lifecycle) · haptics · status-bar · splash  │
│           keep-awake · share · browser · google-auth · sign-in-with-apple       │
│  custom (Phase 3): screen-share (ReplayKit/MediaProjection) · callkit           │
└─────────────────────────────────────────────────────────────────────────────────┘
        │ HTTPS (cookie zyra_token เหมือน browser)      │ WSS                │ WebRTC
        ▼                                                ▼                    ▼
   zyra-app (k3s) ──rewrite──▶ zyra-api            zyra-ws               zyra-sfu (LiveKit)
                                   │ push
                                   ▼
                          zyra-notifications ──FCM HTTP v1──▶ APNs / Android
```

### 3.1 โหมด remote URL (รอบแรก)

- `capacitor.config.ts`: `server.url` ชี้ไป origin ของ env นั้น · `server.allowNavigation` เฉพาะ domain ของเรา (+ Google/Apple auth domain ถ้าจำเป็น) · `android.allowMixedContent: false`
- Origin ใน WebView = domain จริง → cookie `zyra_token`, refresh cookie, `proxy.ts` ทำงานเหมือน browser **ไม่ต้องแก้ auth**
- Build flavor: `dev` / `uat` / `prod` แต่ละตัว `server.url` คนละค่า ผูกกับ env ของ zyra-app ตามกฎ GitOps
- ข้อแลกเปลี่ยน: server ล่ม = แอปล่ม → ต้องมีหน้า offline native (Tier 1)

### 3.2 ทางเลือก bundle asset ลงแอป (ถ้าโดน 4.2 หรือต้องการ offline shell)

ทำหลัง Phase 1 ได้ ต้องแก้ zyra-app:
1. ย้าย `app/api/img` (image proxy) ไป zyra-api หรือ CDN ตรง
2. เปลี่ยน rewrite `/api/*` เป็นเรียก `NEXT_PUBLIC_API_URL` ตรงจาก client
3. Auth เปลี่ยนจาก cookie เป็น bearer header + เก็บ token ใน `@capacitor/preferences` (secure)
4. `output: "export"` + ตัด server route ทั้งหมด
ประเมินราว 1 sprint — ไม่ทำในรอบแรก

### 3.3 ตรวจว่ารันในแอป

ฝั่ง zyra-app ใช้ `Capacitor.isNativePlatform()` (จาก `@capacitor/core` ที่ inject มากับ WebView) หรือ `navigator.userAgent` ที่ shell ตั้งเอง เพื่อ:
- สลับปุ่ม Google จาก redirect flow → เรียก native plugin
- แสดงปุ่ม Sign in with Apple (iOS)
- ส่ง FCM token หลัง login
- ซ่อน screen share, Document PiP, ปุ่ม download ที่ WebView ทำไม่ได้
- ปิด blur / noise-suppressor โดย default

## 4. Auth flow บนแอป

```
[แอป] กด "Sign in with Google"
  → zyra-app เช็ค isNativePlatform → เรียก plugin google-auth
  → native Google Sign-In sheet → ได้ idToken
  → zyra-app เรียก loginWithGoogle(idToken) เดิม (lib/auth/session.ts → POST /api/authen/login_google)
  → response set cookie เหมือน browser → persistSession() เดิม
```

- **ไม่แก้ zyra-api** สำหรับ Google — endpoint เดิมรับ id_token อยู่แล้ว ต้องเช็คว่า `aud` ตรงกับ iOS/Android client id ด้วย (Google ออก client id แยกต่อ platform) → zyra-api ต้องรับ `GOOGLE_CLIENT_ID` หลายค่า (comma-separated)
- **Sign in with Apple** — ใหม่ทั้งหมด: plugin → identityToken (JWT จาก Apple) → `POST /api/authen/login_apple` ใหม่ใน zyra-api verify กับ Apple public key (`https://appleid.apple.com/auth/keys`) → สร้าง/ผูก user ด้วย `sub` + email (Apple ให้ email ครั้งแรกครั้งเดียว ต้องเก็บทันที)
- Email/password login ใช้ form เดิมใน WebView ได้เลย (captcha ต้องเช็คว่า reCAPTCHA render ใน WebView ได้ — ถ้าไม่ได้ให้ใช้ `@capacitor/browser` เปิด SFSafariViewController หรือปิด captcha สำหรับ native user-agent)

## 5. Lifecycle / background

| เหตุการณ์ | ทำอะไร | ที่ไหน |
|---|---|---|
| `appStateChange` → background | ส่ง `visibility` ให้ ws เหมือน tab hidden · หยุด render loop ของ Pixi | zyra-app: hook ใน `stores/vo-session-store.ts` + `components/game-canvas/pixi-canvas.tsx` |
| `appStateChange` → active | `WorkspaceWSClient.reconnect()` ถ้าหลุด · `SFUClient` re-attach tracks · resume Pixi ticker | zyra-app |
| อยู่ในประชุม + ไป background (iOS) | `UIBackgroundModes: audio` ใน Info.plist ให้ AVAudioSession ค้าง · LiveKit audio ยังไหล · วิดีโอหยุดตามปกติ | zyra-mobile (iOS) |
| อยู่ใน VO | `KeepAwake.keepAwake()` · ออกจาก VO → `allowSleep()` | zyra-app |
| Push tap | plugin ให้ payload `{workspace_id, type, target}` → `router.push` ไปหน้าที่ตรง | zyra-app |
| Deep link `zyra://` / universal link | `App.addListener("appUrlOpen")` → map เป็น Next route | zyra-app + zyra-mobile (AASA file + assetlinks.json ต้อง serve จาก domain ของ zyra-app) |

## 6. Push notification flow

```
[แอป] เปิดครั้งแรก/หลัง login → PushNotifications.register() → ได้ FCM token (Android) / APNs token→FCM (iOS ผ่าน Firebase SDK)
  → POST /api/user/devices {platform, token, app_version}     (zyra-api, UserGuard)
[zyra-ws] มี DM/mention/knock/meeting invite → user ปลายทางไม่มี WS connection อยู่ (offline)
  → publish event ไป zyra-notifications (Redis pub/sub หรือ HTTP ภายใน POST /push)
[zyra-notifications] lookup tb_user_device ของ user → เช็ค notification settings → ส่ง FCM HTTP v1 (ครอบ APNs + Android)
  → token invalid (UNREGISTERED) → ลบ row
```

### 6.1 DB — zyra-api

```sql
-- migration: user device tokens for mobile push
CREATE TABLE tb_user_device (
  id           BIGSERIAL PRIMARY KEY,
  user_id      TEXT NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
  platform     TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  fcm_token    TEXT NOT NULL UNIQUE,
  app_version  TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tb_user_device_user ON tb_user_device(user_id);
```
(ชื่อคอลัมน์ `tb_user.id` ให้ตรวจกับ schema จริงก่อนเขียน migration)

### 6.2 API contract — zyra-api (UserGuard, `/api/user/*` ตามกฎ member API separation)

| Method | Path | Body | Response |
|---|---|---|---|
| POST | `/api/user/devices` | `{platform, token, app_version}` | `APIResponse{status:200}` — upsert ตาม token |
| DELETE | `/api/user/devices/{token}` | — | `APIResponse{status:200}` — เรียกตอน logout |
| POST | `/api/authen/login_apple` | `{identity_token, authorization_code?, full_name?}` | เหมือน `login_google` (token + user) |

### 6.3 zyra-notifications

- Provider ใหม่ `internal/push/fcm.go` ใช้ service account JSON (`FCM_SERVICE_ACCOUNT_JSON` ใน env secret ผ่าน ESO) · endpoint ภายใน `POST /push` `{user_ids[], title, body, data{}}` ป้องกันด้วย internal token เหมือน endpoint email เดิม
- ต้องเพิ่ม Firebase project + APNs key (.p8) ใน Firebase console — คนถือ Apple Developer account ทำ

## 7. Touch control ใน engine (Phase 0)

- เพิ่ม input source ใหม่ใน `zyra-engine/pixi-game/scene.ts` ข้าง keyboard handler: virtual joystick (DOM overlay ใน HUD ส่ง `{dx, dy}` เข้า scene ผ่าน `useImperativeHandle` ของ `pixi-canvas.tsx`) + tap-to-walk (ใช้ click-to-walk path เดิม แยกจาก pan ด้วย threshold ระยะ/เวลา)
- Movement V2 (`input` intent) รองรับ `{dx, dy}` อยู่แล้ว → joystick map เข้า intent ตรง ๆ · legacy protocol ใช้ `move_to` เหมือน click
- ค่า tuning (deadzone, threshold แยก tap/pan, pinch) ไป `zyra-engine/constants.ts`
- Pinch-zoom / pan ที่มีอยู่ (`touchstart` ~L1421, pointer ~L2946) เก็บไว้ แต่ต้องไม่ชนกับ joystick overlay (joystick อยู่นอก canvas hit area)

## 8. Performance บนมือถือ (Phase 0)

ลำดับที่จะลองเมื่อ FPS ไม่ถึง 30: ลด `resolution` ของ renderer เป็น 1 (ไม่ใช่ DPR) → ปิด `pixi-filters` → ลด nature/pet layer (มี FPS fallback ของ SC-NAT-01 อยู่แล้ว) → cull aggressive ขึ้น → ลด tick ของ remote interpolation · ทุกครั้งบันทึกตัวเลขจริงตามกฎ before/after metrics

## 9. Plan B — Expo

**Trigger** (อย่างใดอย่างหนึ่ง):
1. FPS < 20 บน iPhone 12 / Pixel 6a หลังทำ §8 ครบแล้ว
2. Apple reject 4.2 สองรอบหลังใส่ Tier 1 ครบ + ลอง §3.2 แล้ว

**สิ่งที่ใช้ต่อได้จาก Capacitor track:** Phase 0 ทั้งหมด (responsive HUD ใช้เป็น reference), push backend (Phase 2), auth endpoint Apple, Firebase project, store account/listing

## 10. ความเสี่ยง

| ความเสี่ยง | ระดับ | ทางลด |
|---|---|---|
| Apple 4.2 minimum functionality | สูง | Tier 1 ครบตั้งแต่รอบแรก · test account ใน review notes · ถ้ายังไม่ผ่านใช้ §3.2 |
| Figma mobile design ยังไม่มี | สูง (บล็อก Phase 0 ข้อ 4) | ขอ design ก่อนเริ่ม HUD · ระหว่างรอทำ joystick + performance ก่อน |
| Performance PixiJS ใน WebView Android เครื่องล่าง | กลาง | §8 + กำหนด minimum spec ที่รองรับ |
| Screen share ไม่ได้ | กลาง (ลูกค้าคาดหวัง) | แจ้งล่วงหน้า · Tier 3 |
| reCAPTCHA ใน WebView | ต่ำ | ทดสอบตั้งแต่ Phase 1 ข้อแรก · fallback ตาม §4 |
| Google client id ต่อ platform | ต่ำ | zyra-api รับหลาย client id |
| Apple ให้ email ครั้งเดียว | ต่ำ | เก็บทันทีใน `login_apple` |

---

## 11. Native feature จริง vs ทำใน WebView ได้ (ตรวจ 2026-09-29)

คำถาม: feature ไหน **ต้องเขียน native จริง** (Swift/Kotlin หรือ plugin) และอันไหนโค้ดเว็บเดิมทำได้เลย

### 11.1 ต้อง native (WebView ทำไม่ได้ หรือ OS บังคับ)

| Feature | ทำไม WebView ทำไม่ได้ | วิธีทำ | งาน native จริง |
|---|---|---|---|
| Push notification | WKWebView ไม่มี `pushManager` · Android WebView ก็ไม่มี | `@capacitor/push-notifications` + Firebase SDK (iOS ต้อง APNs key) | config อย่างเดียว |
| Sign in with Google | Google block OAuth ใน embedded WebView (`disallowed_useragent`) | plugin Google Sign-In → id_token → endpoint เดิม | config + client id ต่อ platform |
| Sign in with Apple | Apple บังคับ (4.8) และเป็น native API | plugin Sign in with Apple → identityToken → `login_apple` ใหม่ | config + endpoint ใหม่ใน zyra-api |
| Background audio (iOS) | ต้องประกาศ `UIBackgroundModes: audio` ใน Info.plist — เว็บประกาศเองไม่ได้ | แก้ Info.plist (ดู §13) | config |
| Keep WS alive ตอน background (Android) | Android freeze cached process / Doze ตัด network | foreground service (type `microphone` ตอนประชุม) — plugin community หรือเขียน Kotlin เอง | **plugin เล็ก ~1 ไฟล์ Kotlin** |
| Haptics | `navigator.vibrate` ไม่มีบน iOS | `@capacitor/haptics` | config |
| Badge count | ไม่มี web API บน WebView | `@capacitor-community/badge` | config |
| Deep link / universal link | ต้องประกาศ scheme + AASA / assetlinks ที่ระดับแอป | `@capacitor/app` `appUrlOpen` + ไฟล์ `.well-known` บน zyra-app | config |
| หน้า offline ของแอป | error page ของ WebView เป็นของ Safari/Chrome | shell native เช็ค reachability ก่อน load + fallback HTML ใน bundle | Swift/Kotlin เล็กน้อย |
| Screen share | `getDisplayMedia` ไม่มีใน WKWebView / Android WebView | ReplayKit (iOS) + MediaProjection (Android) → publish track เข้า LiveKit | **งานใหญ่ทั้งสอง platform** (Tier 3) |
| CallKit / VoIP push | CallKit กับ WebRTC ใน WKWebView **ชนกัน** — คนละ thread คนละ AVAudioSession แย่ง mic/speaker (Apple forum ไม่มีคำตอบจาก Apple) | ทำได้จริงต่อเมื่อย้ายเสียงไป native LiveKit SDK — นอก scope Capacitor | **ไม่แนะนำ** ในท่านี้ |
| Native PiP ของวิดีโอประชุม | WebRTC stream ใน `<video>` ไม่เข้า PiP ของ WKWebView อัตโนมัติ | plugin native (Tier 3) | งานกลาง |
| Download ไฟล์ (chat attachment) | WebView ไม่ handle `blob:` download / `<a download>` | `@capacitor/filesystem` + `@capacitor/share` | config + branch ใน zyra-app |
| Local notification (ตอน app เปิดอยู่แต่อยู่หน้าอื่น) | `Notification` API ไม่มีใน WKWebView | `@capacitor/local-notifications` | config |
| Splash / status bar / orientation lock | ระดับ OS | `@capacitor/splash-screen`, `@capacitor/status-bar`, `@capacitor/screen-orientation` | config |

### 11.2 ทำใน WebView ได้ (โค้ด zyra-app เดิม + config WebView)

| Feature | ทำได้ไหม | เงื่อนไข / สิ่งที่ต้องตรวจ |
|---|---|---|
| WebRTC mic + cam (`getUserMedia`) | ✅ iOS ≥ 14.3, Android ✅ | `WKWebViewConfiguration.allowsInlineMediaPlayback = true` และ **`mediaTypesRequiringUserActionForPlayback = []`** — ถ้าไม่ตั้ง iOS 18 เสียง WebRTC ไม่ออก (Apple forum 764453) · เชื่อว่า Capacitor ตั้งให้แล้ว **ต้องตรวจใน `CAPBridgeViewController`** ถ้าไม่ให้ override ใน `AppDelegate` |
| สลับกล้องหน้า/หลัง | ✅ | `facingMode` ใน constraints — โค้ดเว็บล้วน |
| WebSocket (foreground) | ✅ | `WorkspaceWSClient` เดิม ไม่ต้องแก้ |
| Cookie auth + `proxy.ts` | ✅ | เฉพาะโหมด remote URL (origin = domain จริง) |
| Touch: joystick / tap-to-walk / pinch | ✅ | โค้ด Phase 0 ใน `zyra-engine` |
| Keyboard ไม่บัง input | ✅ (ปรับ CSS) | `@capacitor/keyboard` ให้ event `keyboardWillShow` + `resize: body/native` |
| Wake lock (จอไม่ดับ) | ⚠️ | `navigator.wakeLock` ใน WKWebView ไม่แน่ใจว่าได้ → ใช้ `@capacitor/keep-awake` (config) |
| Web Share | ⚠️ | `navigator.share` ใน WKWebView ไม่แน่ใจ → ใช้ `@capacitor/share` (config) |
| Clipboard, IndexedDB (dexie), localStorage | ✅ | `sessionStorage` (`ws-tab-session.ts`) **อาจไม่รอด** เมื่อ OS kill WebView process — ผลแค่ได้ `client_session_id` ใหม่เหมือน reload |
| reCAPTCHA ตอน login | ⚠️ ต้องทดสอบ | เว็บโหลดจาก domain จริงจึงน่าจะได้ · ถ้าไม่ได้ดู §4 |
| i18n, TanStack Query, zustand, Sentry, Mixpanel | ✅ | โค้ดเว็บล้วน — ควร tag `platform=ios-app/android-app` |
| Audio playback unlock | ✅ | `sfu.startAudio()` มีอยู่แล้วบน click/keydown (`use-meeting-media.ts:1025`) — บนแอปยังต้อง gesture แรกเหมือน Safari |

**สรุป:** Tier 1 ทั้งหมดเป็น **config + plugin official** ไม่ต้องเขียน Swift/Kotlin เอง ยกเว้น (1) foreground service บน Android และ (2) หน้า offline ของ shell ซึ่งเล็ก · งาน native ใหญ่จริงมีแค่ screen share กับ PiP (Tier 3) · CallKit ไม่ควรทำในท่า WebView

## 12. Background WebSocket — ทำได้ไหม (ระดับโค้ด)

### 12.1 พฤติกรรม OS

| | iOS (WKWebView) | Android (System WebView) |
|---|---|---|
| JS timers / WebSocket ตอน background | **ถูก suspend ภายในไม่กี่วินาที** หลัง `didEnterBackground` (Apple forum 111247, Cordova CB-12815) — `setInterval`, `requestAnimationFrame`, callback ทั้งหมดหยุด · socket ถูก OS ปิดหรือค้างจนอีกฝั่ง timeout | Capacitor **ไม่เรียก** `webView.onPause()` / `pauseTimers()` (ตรวจจาก `Bridge.java`) → JS วิ่งต่อจนกว่า OS จะ freeze cached process หรือ Doze ตัด network (ปกติหลายนาที ขึ้นกับเครื่อง) |
| ยกเว้น | ถ้าแอปมี `UIBackgroundModes: audio` **และ** กำลังเล่น/จับเสียงอยู่จริง (อยู่ในประชุม) iOS ไม่ suspend → WebView + WebSocket วิ่งต่อ (ยืนยันบน iOS 17.5.1+, Apple forum 689182) | foreground service ที่มี notification ค้าง → process ไม่ถูก freeze, network ไม่ถูกตัด |
| Background Runner ของ Capacitor | ไม่ช่วย — event-driven, context ใหม่ทุกครั้ง, ≤30 วินาที, **ไม่มี WebSocket ไม่มี DOM** | เหมือนกัน |
| Native WS relay (Swift/Kotlin ถือ socket แทน) | iOS ยัง suspend แอปทั้งตัวถ้าไม่มี background mode ที่เข้าเงื่อนไข → ไม่ช่วยนอกประชุม · VoIP mode ใช้ค้าง socket โดยไม่มีสายเข้าจริง = Apple reject | ทำได้แต่ = foreground service อยู่ดี |

### 12.2 สิ่งที่เกิดกับ zyra-ws เมื่อแอปถูก suspend (จากโค้ดจริง)

```
client: heartbeat ทุก 20s (vo-session-store.ts:432) หยุด · Worker ticker 100ms (scene.ts:3100) หยุด
server: pingPeriod 45s / pongWait 60s (client.go:17-20)
  ├─ OS ปิด socket ทันที → ReadPump ออก → room.unregister (client.go:370)
  └─ OS ค้าง socket → pong ไม่ตอบ → ปิดหลัง 60s → unregister
unregister (room.go:506-626) — ไม่มี grace period:
  releaseSeat → ออกจาก meeting chat / audio room / screen share → MediaRoomID = ""
  → SetLastPosition (tile+direction เท่านั้น ไม่เก็บ sitting) → DeletePresence → broadcast MsgLeft ทันที
presence TTL 35s (redis.go:17) หมดอายุก่อนหน้านั้นอยู่แล้ว
สิ่งที่รอดข้ามการหลุด: follow 30s (redis.go:277) · chat circle 5s (chatspace.go:47) · spotlight 2 นาที (spotlight.go:34)
```

ผล: ผู้ใช้กด Home 1 นาที → คนอื่นเห็น "ออกจาก office" · กลับมาอีกครั้ง = join ใหม่ ยืนอยู่ tile เดิม (ไม่นั่งแล้ว) · ต้อง `mediaRoomEnter` ใหม่ (client ทำให้อยู่แล้ว `use-meeting-media.ts:1006-1021`)

### 12.3 คำตอบ

| สถานการณ์ | iOS | Android | วิธีแก้ที่ถูก |
|---|---|---|---|
| Background WS **ระหว่างประชุม** | ✅ ได้ — ด้วย `UIBackgroundModes: audio` (iOS ≥ 17.5) | ✅ ได้ — foreground service type `microphone` ตอนอยู่ในประชุม | native config (iOS) + plugin เล็ก (Android) |
| Background WS **นอกประชุม** (เดินเล่น/แชท) | ❌ ทำไม่ได้ — OS suspend, ไม่มี background mode ที่ Apple ยอม | ⚠️ best-effort — ได้หลายนาทีแล้วโดน freeze | **ไม่ใช่ native** — แก้ที่ zyra-ws: grace period |

**สิ่งที่ต้องทำจริง (ไม่ใช่ native):**
1. **zyra-ws — grace period สำหรับ mobile**: เมื่อ client ที่ส่ง `visibility{hidden:true}` (หรือ platform=mobile) หลุด ให้ค้าง seat + `MediaRoomID` + presence ไว้ N วินาที (เสนอ 90s) แล้ว mark status `away` แทน broadcast `left` ทันที · ถ้า reconnect ด้วย `client_session_id` เดิมภายใน N → คืนสถานะ (ต่อยอด `reclaimSuperseded` ที่ตอนนี้คืนแค่ follow, `room.go:420-441`) · ครบ N ค่อย `unregister` จริง — เปลี่ยน `room.go` + `redis.go` (TTL ใหม่) + `hub.go Join` ให้ restore sitting
2. **zyra-app — ผูก Capacitor lifecycle เข้า handler เดิม**: `App.addListener("appStateChange")` → เรียก `wsClient.visibility(!isActive)` และตอน active เรียก `reconnectNow()` (ทำเหมือน `hero-virtual-office.tsx:4035-4097` ที่ผูกกับ `visibilitychange`) — อย่าพึ่ง `visibilitychange` อย่างเดียว เพราะบน Android WebView ที่ไม่ถูก pause ไม่แน่ว่า event ยิง
3. **zyra-app — ส่ง presence ตอน `pause`**: `beforeunload` (`hero-virtual-office.tsx:4613`) ไม่ยิงตอนแอปไป background → เพิ่ม `App.addListener("pause")` → `POST /presence` ด้วย `keepalive: true` (มีเวลาไม่กี่วินาทีก่อน suspend)

## 13. Background audio mode + reconnect — ทำได้ไหม (ระดับโค้ด)

### 13.1 Background audio (iOS)

| iOS | พฤติกรรม WebRTC ใน WKWebView ตอน background | แหล่ง |
|---|---|---|
| 14.7 – 17.4 | ได้ยินเสียงคนอื่น แต่ **mic ตัวเองถูก mute** (`microphoneCaptureState` เป็น muted หลัง `didEnterBackground`, สั่งกลับไม่ได้) | Apple forum 689182 |
| **≥ 17.5.1** | ใส่ `audio` ใน `UIBackgroundModes` แล้ว **ทำงานเหมือน Safari** ทั้งฟังและพูด | Apple forum 689182 (Aug 2024) |
| 18 | เสียง WebRTC ไม่ออกถ้าไม่ตั้ง `mediaTypesRequiringUserActionForPlayback = []` (foreground ก็เป็น) | Apple forum 764453 |
| 26 (Element X iOS = LiveKit web ใน WKWebView) | ยังมีรายงานเสียงหายสองทางใน 1–3 วิ เมื่อ media ตกไป **TCP** (UDP ชนพอร์ต) — iOS ตัด TCP background แรงกว่า | element-call #4184 (ยังเปิดอยู่) |

**ต้องทำ (native config ทั้งหมด ไม่ต้องเขียนโค้ด Swift):**
- `Info.plist`: `UIBackgroundModes = [audio]` + `NSMicrophoneUsageDescription` / `NSCameraUsageDescription`
- `WKWebViewConfiguration`: `allowsInlineMediaPlayback = true`, `mediaTypesRequiringUserActionForPlayback = []` (ตรวจ default ของ Capacitor)
- ฝั่งเว็บ (iOS ≥ 17): ตั้ง `navigator.audioSession.type = "play-and-record"` ตอนเข้าประชุม (`sfu-client.ts` ตอน `connect`) เพื่อบอก OS ว่าเป็น call — Web API, ไม่ต้อง native
- **zyra-sfu**: ตรวจว่า UDP port range ของ LiveKit ไม่ชน TURN และ client ไม่ตกไป TCP-only — ถ้าตก background audio บน iOS จะไม่รอด (บทเรียนจาก Element)
- ตั้ง **minimum iOS 17.5** สำหรับแอป (ต่ำกว่านั้น mic mute ตอน background — แจ้งผู้ใช้แทน)

**Android:** ต้องมี foreground service ตอนอยู่ในประชุม (Android 14+ บังคับ `foregroundServiceType="microphone|mediaPlayback"` + permission) ไม่งั้น OS ตัด mic เมื่อแอปไป background — นี่คือ **งาน native ชิ้นเดียวใน Tier 1** (~1 ไฟล์ Kotlin + AndroidManifest หรือใช้ plugin community `capacitor-plugin-background-mode` แล้วตรวจว่ารองรับ Android 14 type)

**CallKit:** ไม่ทำ — WKWebView กับ CallKit ถือ AVAudioSession คนละ thread แย่ง mic/speaker กัน (Apple forum 685268) ถ้าต้องการ "สายเข้า" จริงต้องย้ายเสียงไป native LiveKit SDK ซึ่งเป็น Plan B ไม่ใช่ Capacitor

### 13.2 Reconnect — ที่มีอยู่แล้วในโค้ด (ไม่ต้องเขียนใหม่)

| ชั้น | มีอะไรแล้ว | ไฟล์:บรรทัด |
|---|---|---|
| WS client | auto-reconnect backoff `[1,2,4,8,16]s` สูงสุด 5 ครั้ง → `onReconnectExhausted` | `lib/api/workspace-ws.ts:82-83, 394-413` |
| | liveness: ไม่มี frame เข้า 30s → `ws.close()` → reconnect (ตอน hidden แค่ ping ไม่ recycle) | `:87-88, 464-486` |
| | wake: `online` / `focus` / `visibilitychange`(visible) → `reconnectNow()` — ถ้า socket OPEN แต่ stale >30s ปิดแล้วต่อใหม่, ถ้าไม่มี socket reset attempts แล้ว `_connect()` | `:430-457, 499-513` |
| | ทุกครั้งที่ต่อ ส่ง `client_session_id` เดิม (sessionStorage) → server ไม่ยิง `session_replaced` (`sameTab`) | `ws-tab-session.ts:7-19`, `room.go:278` |
| | `onopen` ส่ง `visibility` ตาม `document.visibilityState` แล้วยิง `onReconnected` | `:314-329` |
| SFU | LiveKit default resume/reconnect · `reconnected` → hook re-assert `setMicrophoneEnabled/setCameraEnabled` + `announceLiveState()` | `sfu-client.ts:1687`, `use-meeting-media.ts:1325-1347` |
| | `disconnected(recoverable)` → rejoin ใหม่ delay `[1,3,6]s` 3 ครั้ง → toast "voice unavailable" | `use-meeting-media.ts:1300-1360` |
| | visible หลัง hidden ≥5s → `resyncRemoteAudio()` + `startAudio()` · ถ้า `!sfu.state.connected` → `scheduleReconnect()` | `use-meeting-media.ts:1037-1057` |
| | WS reconnected → re-send `mediaRoomEnter`, mute/cam state, hand, `shareStart` (server wipe ไปแล้ว) | `use-meeting-media.ts:1006-1021` |
| Hero | `onReconnecting` freeze input + scrim · `onReconnected` set status, `stop(tile)`, re-subscribe chat, `meetingChatJoin`, resync remote players · `onReconnectExhausted` → modal Retry/Leave | `hero-virtual-office.tsx:3265-3353, 12423-12462` |
| Engine | `visibilitychange` hidden → `releaseAllKeys()` + flush pending sit · visible → `_handleResumeFromBackground()` (collapse remote buffers, settle glide ≤4 tiles) · Worker ticker 100ms กัน rAF starvation | `scene.ts:2911-2968, 3100-3170` |
| Server | `visibility{hidden:false}` → `forceSync("visibility_resume")` + neighbor snapshot · `Join` restore last tile/direction + status (ถ้า presence ยังไม่หมด 35s) | `room.go:2319-2350`, `hub.go:230-252` |

**สรุป reconnect: ✅ ทำได้ และมีอยู่แล้ว ~90%** — ตอนกลับจาก background ทางเดิม `visibilitychange` → `reconnectNow()` → `Join` → `onReconnected` ทำงานได้ใน WebView ถ้า event ยิง

### 13.3 ช่องว่างที่ต้องปิด (เรียงตามผลกระทบ)

| # | ช่องว่าง | ผล | แก้ที่ | native? |
|---|---|---|---|---|
| 1 | server ไม่มี grace → หลุดแล้ว `left` ทันที, seat/meeting หาย | กด Home 1 นาทีเท่ากับออกจาก office | zyra-ws (§12.3 ข้อ 1) | ❌ |
| 2 | `Join` ไม่ restore `sitting`/seat/`MediaRoomID` — client re-assert เฉพาะ media | กลับมาแล้วยืนอยู่ข้างเก้าอี้ | zyra-ws `hub.go Join` + `unregister` เก็บ sitting | ❌ |
| 3 | พึ่ง `visibilitychange`/`focus` อย่างเดียว — Android WebView ที่ไม่ถูก pause อาจไม่ยิง | ไม่ reconnect จนกว่า liveness 30s จะจับได้ | zyra-app: bridge `appStateChange` → handler เดิม | ❌ (plugin official) |
| 4 | `beforeunload` presence POST ไม่ยิงตอน background | last position บน REST ไม่อัปเดต | zyra-app: `App.pause` → `POST /presence` keepalive | ❌ |
| 5 | backoff timers ถูก freeze พร้อม JS → กลับมาแล้ว timer ค้าง | ปกติ `_onWake` ยิง `reconnectNow()` ทับให้อยู่แล้ว — แค่ต้องมี test | zyra-app test | ❌ |
| 6 | Android ไม่มี foreground service → OS ตัด mic/socket ตอนประชุมใน background | เสียงหายเมื่อสลับแอปบน Android | zyra-mobile (Kotlin เล็ก) | ✅ ชิ้นเดียว |
| 7 | iOS < 17.5 mic mute ตอน background | พูดไม่ได้ตอนสลับแอป | minimum iOS 17.5 + แจ้งผู้ใช้ | config |
| 8 | media ตก TCP → iOS ตัดตอน background | เสียงหายสองทาง | zyra-sfu port/TURN config | ❌ |

### 13.4 คำตอบสั้น

- **Background WebSocket:** ระหว่างประชุมทำได้ทั้งสอง OS (iOS ด้วย audio mode, Android ด้วย foreground service) · นอกประชุม iOS ทำไม่ได้และไม่ควรพยายาม — แก้ด้วย grace period ฝั่ง zyra-ws แทน
- **Background audio:** ทำได้บน iOS ≥ 17.5 ด้วย config ล้วน (Info.plist + WKWebView flags + UDP media path) · Android ต้อง foreground service (native ชิ้นเดียวใน Tier 1)
- **Reconnect:** โค้ดมีครบแล้ว ต้องเพิ่มแค่ bridge `appStateChange`/`pause` เข้า handler เดิม และปิดช่องว่างฝั่ง server (grace + restore sitting)

แหล่งอ้างอิงภายนอก: [Apple forum 689182 — mic muted in background](https://developer.apple.com/forums/thread/689182) · [Apple forum 764453 — iOS 18 WebRTC audio](https://developer.apple.com/forums/thread/764453) · [Apple forum 685268 — CallKit + WKWebView](https://developer.apple.com/forums/thread/685268) · [Apple forum 111247 — WKWebView JS in background](https://developer.apple.com/forums/thread/111247) · [element-call #4184](https://github.com/element-hq/element-call/issues/4184) · [Capacitor Background Runner](https://capacitorjs.com/docs/apis/background-runner) · [Capacitor App API](https://capacitorjs.com/docs/apis/app) · [Capacitor Android Bridge.java](https://github.com/ionic-team/capacitor/blob/main/android/capacitor/src/main/java/com/getcapacitor/Bridge.java) · [WebKit 173932](https://bugs.webkit.org/show_bug.cgi?id=173932)

---

## 14. Native feature inventory — ไล่จากโค้ดทั้ง zyra-app (2026-09-29)

ไล่ทุก browser API / desktop assumption ใน `app/`, `views/`, `components/`, `lib/`, `hooks/`, `stores/`, `zyra-engine/` แล้วจัดเป็น 4 ระดับ · path จาก root ของ zyra-app · เลขบรรทัด ณ develop 2026-09-29

| ระดับ | ความหมาย | จำนวน |
|---|---|---|
| **A — native code จริง** | ต้องเขียน Swift/Kotlin หรือ plugin ที่ยังไม่มี | 5 |
| **B — plugin official + branch ในเว็บ** | ลง plugin Capacitor + เพิ่ม `if (isNativePlatform)` ในโค้ดเว็บ | 13 |
| **C — โค้ดเว็บต้องแก้ (ไม่ native)** | WebView ทำได้ แต่โค้ดปัจจุบันเขียนแบบ desktop | 14 |
| **D — ทำงานได้เลย / ปิดเฉย ๆ** | ไม่ต้องทำอะไร หรือแค่ปิดบน native | 8 |

### 14.1 ระดับ A — ต้องเขียน native code จริง

| # | Feature | โค้ดที่เกี่ยว | ทำไม WebView ไม่ได้ | ต้องทำ | Phase |
|---|---|---|---|---|---|
| A1 | **Screen share** (เริ่มแชร์ / สลับ source / share audio) | `lib/api/sfu-client.ts:816-877` (`setScreenShareEnabled` + preset 720p30–1080p30), `:905` (`getDisplayMedia` ใน `switchScreenShareSource`), `:1506-1649` remote screen tracks · **ไม่มี support check เลย** ปุ่มแสดงเสมอ · `hero-virtual-office.tsx:8139` queue share จาก PiP window | WKWebView / Android WebView ไม่มี `getDisplayMedia` | Phase 1: ซ่อนปุ่มเมื่อ `!navigator.mediaDevices?.getDisplayMedia` · Phase 3: plugin ReplayKit (iOS) + MediaProjection (Android) → สร้าง LocalVideoTrack จาก native → publish เข้า LiveKit | 1 (ซ่อน) / 3 (native) |
| A2 | **Foreground service ตอนประชุม (Android)** | ไม่มีในโค้ด — ต้องใหม่ทั้งหมด | Android freeze cached process / Doze ตัด mic + socket | Kotlin service type `microphone\|mediaPlayback` + ongoing notification เริ่มเมื่อ `mediaRoomEnter` หยุดเมื่อออก · Android 14+ ต้องประกาศ `foregroundServiceType` | 1 |
| A3 | **หน้า offline ของ shell** | ไม่มีในโค้ด · `public/sw.js` มี offline HTML เฉพาะ navigation แต่ SW ไม่รันใน WKWebView (ดู D6) | error page ของ WebView เป็นของ Safari/Chrome · โหมด remote URL server ล่ม = จอขาว | shell เช็ค reachability ก่อน `load` + bundle `offline.html` + ปุ่ม retry (Swift `WKNavigationDelegate didFailProvisionalNavigation` / Kotlin `onReceivedError`) | 1 |
| A4 | **Native Picture-in-Picture ของวิดีโอประชุม** | Document PiP `views/user/virtual-office/use-document-pip.ts:57-80,166-205` (Mini Mode / Outside display) · Auto-PiP `use-autopip-eligibility.ts` (ถือ mic stream ค้าง) · `mediaSession.setActionHandler("enterpictureinpicture")` `:71-72,313-323` · ไฟล์ตาย: `hooks/use-document-pip.ts`, `vo-pip-video.tsx` (ไม่ถูก import) | Document PiP เป็น Chromium desktop เท่านั้น · feature-check อยู่แล้ว → บน WebView ปิดเอง | Phase 1: ไม่ทำอะไร (ปิดเองอยู่แล้ว) · ต้องปิด `use-autopip-eligibility` บน native เพราะถือ mic ค้างโดยไร้ประโยชน์ · Phase 3: native PiP (AVPictureInPictureController + sample buffer จาก LiveKit track) | 1 (ปิด) / 3 |
| A5 | **CallKit / VoIP push** | ไม่มีในโค้ด | CallKit กับ WebRTC ใน WKWebView แย่ง AVAudioSession (§13.1) | ไม่ทำในท่า Capacitor — Plan B เท่านั้น | — |

### 14.2 ระดับ B — plugin official + branch ในโค้ดเว็บ

| # | Feature | โค้ดที่เกี่ยว | ปัญหาใน WebView | Plugin | branch ในเว็บ | Phase |
|---|---|---|---|---|---|---|
| B1 | **Google login** | `views/login/components/card-login.tsx:314` `window.open("/login/google","_blank")` + รอ `storage` event key `zyra_google_login_event` `:218,241,288` + poll popup ปิด `:321` + timeout 120s `:294` · `app/login/google/page.tsx:10-29` redirect implicit flow · `callback/page.tsx:39,76,85` เขียน localStorage แล้ว `window.close()` · nonce ใน `sessionStorage google_login_nonce` | `window.open` ไม่มี popup ใน WKWebView · Google block OAuth ใน embedded WebView (`disallowed_useragent`) | `@codetrix-studio/capacitor-google-auth` หรือ `@capacitor-firebase/authentication` | ใน `card-login.tsx`: `if (Capacitor.isNativePlatform()) → GoogleAuth.signIn() → idToken → loginWithGoogle(idToken)` (`lib/auth/session.ts:177` มีอยู่แล้ว) · zyra-api ต้องรับ `GOOGLE_CLIENT_ID` ของ iOS/Android ด้วย (`aud` ต่างกัน) | 1 |
| B2 | **Sign in with Apple** | ไม่มีในโค้ด · `captchaToken` ส่ง `""` เสมอ (`lib/auth/session.ts:56,170`) reCAPTCHA ยังไม่ implement → ไม่มีปัญหา captcha ใน WebView | Apple บังคับเมื่อมี Google login (4.8) | `@capacitor-community/apple-sign-in` | ปุ่มใหม่ใน `card-login.tsx` (iOS เท่านั้น) → `POST /api/authen/login_apple` ใหม่ | 1 |
| B3 | **Push notification** | ไม่มีเลย — ไม่มี `Notification`, `pushManager`, `requestPermission` ใน zyra-app · notification ทั้งหมดเป็น toast ใน `vo-notification-panel.tsx` + `stores/chat-store.ts` ผ่าน WS | WKWebView ไม่มี Push API | `@capacitor/push-notifications` + Firebase iOS SDK | หลัง login: `register()` → `POST /api/user/devices` · `pushNotificationActionPerformed` → `router.push` ตาม payload · logout → `DELETE` · ผูกกับ `stores/notification-settings-store.ts` | 1 + 2 |
| B4 | **Deep link** | ลิงก์ที่ zyra-notifications ส่งอีเมล: `/join/{token}` (`zyra-api workspace_member_service.go:1039` → `app/join/[token]/page.tsx` → bounce `/login?redirect_url=/join/…` `hero-accept-invite.tsx:143`), `/reset-password/{token}` (`forgot_password_service.go:729`), `/api/maintenance-bypass?token=` (`maintenance_service.go:81`) · ในแอป: `/workspace/{id}/play?zone_id=&session_id=` (`hero:11484`) · `redirect_url` รับเฉพาะ same-origin (`card-login.tsx:108-120`) | แตะลิงก์ในอีเมลเปิด Safari ไม่เปิดแอป | `@capacitor/app` `appUrlOpen` + iOS Associated Domains (AASA) + Android App Links (`assetlinks.json`) — ไฟล์ทั้งสองต้อง serve จาก zyra-app `public/.well-known/` | listener แปลง URL → `router.push(pathname+search)` · `redirect_url` ต้องยอม path เหล่านี้ | 1 |
| B5 | **Download ไฟล์** | `lib/download-blob.ts:3-11` (`createObjectURL` + `<a download>`) ใช้โดย chat `views/chat/components/chat-utils.ts:49` (fallback `:55-60` เปิด tab ใหม่ — ก็ไม่ได้ใน WebView), admin CSV `hero-admin-management.tsx:142`, `hero-customer-management.tsx:125` | WKWebView / Android WebView ไม่ทำอะไรกับ `download` attribute บน blob URL | `@capacitor/filesystem` (เขียน Cache dir) + `@capacitor/share` (เปิด share sheet) | ใน `download-blob.ts`: `if native → Filesystem.writeFile(base64) → Share.share({url})` | 1 |
| B6 | **ลิงก์ออกนอกแอป** | `message-text.tsx:196,269,293` (ลิงก์ในแชท `window.open` / `target=_blank`), `conversation-media-panel.tsx:167,191`, `zone-enter-chat.tsx:406` (attachment), `vo-alert-banner.tsx:98` (แหล่ง weather alert), `hero-support-detail.tsx:156`, `lib/announcement-html.ts:179-180` (sanitizer บังคับ `_blank`), `mailto:` `hero-reset-password.tsx:266`, `https://zyra-world.com/Contactus` `card-login.tsx:59,397,440`, `https://zyra.center/` `hero-maintenance.tsx:7,45` | Capacitor iOS โหลด `target=_blank` **ใน WebView เดิม** (navigate ออกจากแอป) ถ้าไม่ intercept · `mailto:` ใน WKWebView ต้อง handle เอง | `@capacitor/browser` (SFSafariViewController / Custom Tabs) | helper `openExternal(url)` ตัวเดียว: native → `Browser.open` · เว็บ → `window.open` แล้วแทนทุกจุดข้างต้น · `mailto:` → `App.openUrl` หรือ copy address | 1 |
| B7 | **Geolocation (weather / environment)** | `vo-environment-tab.tsx:157-166` (owner ตั้ง location), `use-entry-media-permission.ts:109,289-341` (ขอตอนเข้า office ถ้าเปิด env feature) · มี unsupported fallback | WKWebView ใช้ `navigator.geolocation` ได้แต่ต้องมี `NSLocationWhenInUseUsageDescription` · Android WebView ต้อง bridge `onGeolocationPermissionsShowPrompt` (Capacitor ทำให้ แต่ต้อง `ACCESS_FINE_LOCATION` ใน manifest) | `@capacitor/geolocation` (ปลอดภัยกว่าพึ่ง WebView) | `lib/media-permissions.ts:40-79` เพิ่ม branch ถาม permission ผ่าน plugin | 1 |
| B8 | **Android hardware back** | ไม่มี `popstate` handler ทั่วไป · มีแค่ `hooks/use-navigation-guard.ts:49-65` (sentinel pushState สำหรับ admin) และ `router.back()` ที่ `hero-workspace-preview.tsx:20` · Backspace ถูก preventDefault ใน decorate mode `hero:~9560` | ปุ่ม back บน Android = ออกจากแอปทันที (Capacitor default ถ้ามี listener จะ override) | `@capacitor/app` `backButton` | listener: ถ้ามี modal เปิด → ปิด (ตอนนี้ปิดด้วย Escape 16 ที่ `hero:957`, `vo-status-picker:61`, `vo-profile-panel:215`, `player-context-menu:67`, `zone-enter-chat:265`, `vo-teleport-zone-picker:130` …) · ไม่มี → `router.back()` · ที่ root → `App.exitApp()` หรือ minimize | 1 |
| B9 | **Keyboard บนมือถือ** | `zone-enter-chat.tsx:814` (`<input>` Enter ส่ง), `:708-709` `el.focus()` ใน rAF หลังใส่ emoji (เปิดคีย์บอร์ด iOS ซ้ำ), `:125,674,691` clamp picker กับ `innerWidth` · `message-input.tsx:575` textarea autosize `:177-183`, `:432-457` Enter ส่ง/Shift+Enter ขึ้นบรรทัด · `autoFocus`: `hero:14806`, `pz-edit-zone-name-modal.tsx:102`, `emoji-picker.tsx:120` · ไม่มี `visualViewport` / `enterKeyHint` / `virtualKeyboard` | คีย์บอร์ดบัง input · iOS ไม่ resize viewport เมื่อคีย์บอร์ดขึ้น | `@capacitor/keyboard` (`resize: "native"` หรือ `"body"`, `keyboardWillShow/Hide`) | เลื่อน chat input ขึ้นตาม `keyboardHeight` · เพิ่ม `enterKeyHint="send"` · ปุ่มส่งบนจอ (Enter บนมือถือ = ขึ้นบรรทัดใหม่) | 0/1 |
| B10 | **Haptics** | ไม่มีในโค้ด (คำว่า "vibrated" มีแค่ใน comment `scene.ts:7918`) | `navigator.vibrate` ไม่มีบน iOS | `@capacitor/haptics` | จุด: wave/knock รับ (`hero:2101,2127,2752,2851` ที่เล่นเสียง), เข้า zone, ประชุมมีคนเข้า, pet ตอบ | 1–2 |
| B11 | **Badge count** | ไม่มีในโค้ด · unread อยู่ใน `stores/chat-store.ts` | ไม่มี web API | `@capacitor-community/badge` | subscribe unread total → `Badge.set(n)` · เคลียร์เมื่อ foreground | 2 |
| B12 | **Keep screen awake ใน VO** | ไม่มี `wakeLock` ในโค้ด | จอดับตอนเดินในแมพ/ประชุม | `@capacitor/keep-awake` | `keepAwake()` เมื่อ mount `hero-virtual-office`, `allowSleep()` เมื่อ unmount | 1 |
| B13 | **Status bar / splash / orientation / theme** | `app/layout.tsx:85-87` viewport มีแค่ `themeColor "#2B3540"` · `app/manifest.ts:12` `orientation: "landscape"`, `display: "standalone"` (Capacitor **ไม่อ่าน manifest**) · `appleWebApp.statusBarStyle: "black-translucent"` | ต้องตั้งที่ระดับแอป | `@capacitor/status-bar`, `@capacitor/splash-screen`, `@capacitor/screen-orientation` | ตัดสินใจ: VO บนมือถือรองรับ portrait+landscape หรือ lock landscape ตาม manifest เดิม (spec ยังไม่ระบุ) | 1 |

### 14.3 ระดับ C — WebView ทำได้ แต่โค้ดเว็บต้องแก้ (งาน Phase 0 ส่วนใหญ่)

| # | เรื่อง | โค้ดที่เกี่ยว | ปัญหา | ต้องแก้ |
|---|---|---|---|---|
| C1 | **Movement เป็น keyboard-only** | `scene.ts:1126-1133` `MOVE_KEY_CODES` (Arrow/WASD), `:2384` onKeyDown, `:2443` Space ลุก, `:2444` Escape, `:10349,10473` Shift = sprint, `:2457` onKeyUp = นั่งเมื่อปล่อยปุ่มบน chair tile, `:3405-3408,8350-8357,10335-10338` อ่าน held keys ทุก frame · `hero:4761` WASD ออกจาก Away, `:8311` M/V toggle mic/cam, `:6977` P ลูบ pet, `vo-hud.tsx:204` B spotlight | ไม่มี joystick / D-pad / touch movement เลย — มีแค่ pinch 2 นิ้ว (`scene.ts:2867-2904`, return ถ้า `touches.length !== 2`) | Virtual joystick → feed `{dx,dy}` เข้าที่เดียวกับ held keys + ปุ่ม "ลุก" แทน Space + ปุ่ม sprint · tap-to-walk ต่อจาก `onClick` `:2506` (ตอนนี้ต้อง 2 คลิก: เลือก `:2619` → เดิน `:2731`) · ปุ่มบนจอแทน M/V/P/B |
| C2 | **Hover ใน engine** | `scene.ts:2819` mousemove → `mouseWorldX/Y` · hover: pet `:3010-3023`, avatar ตัวเอง `:4470-4476`, avatar คนอื่น `:4628-4635`, ต้นไม้ `:5093-5103`, room-label rename chip `:10200-10212` · `pet-tooltip.tsx:13` "Press [P]" · `:2530` Shift+click | touch ไม่มี hover | long-press = hover (แสดง context/ปุ่ม) · rename chip ต้องมีทางเข้าอื่น |
| C3 | **Camera drag / wheel** | `scene.ts:2786` wheel บน `window` `passive:false`, `:2800` ctrlKey = trackpad pinch, `:2773` `gestureTargetIsMap` · `:2831-2856` pointer drag เริ่มหลัง 4px `:2845`, `setPointerCapture` `:2838`, "single-pointer-naive" `:2874` · constants `CAMERA_ZOOM_MIN 0.4`, `MAX 3.0`, `PINCH_ZOOM_SENSITIVITY 2.5`, `CAMERA_PINCH_WHEEL_BOOST 5` (`zyra-engine/constants.ts:29-132`) | tap-to-walk กับ pan ใช้ pointer เดียวกัน ยังไม่แยก threshold | แยก tap (≤4px, ≤200ms) / pan / pinch ให้ชัด · joystick overlay อยู่นอก canvas hit area |
| C4 | **HUD ซ่อนจนกว่าจะ hover** (touch เข้าไม่ถึง) | `vo-hud-tooltip.tsx:40` `hidden group-hover:flex` (ใช้ใน vo-hud ×4, zone-enter-header ×4, vo-outside-display ×2) · `zone-enter-tiles.tsx:245,438,487` · `zone-enter-screen-share.tsx:221` · `zone-enter-chat.tsx:215` (message action bar) · `pz-layers-panel.tsx:104` · `vo-ask-to-join-button.tsx:55` · รวม `hover:` 359 จุด / `onMouseEnter` 13 จุดใน `vo-member-panel` (locate on hover `:639-717`), `hero:12190` `onMouseMove` → ZoneHoverCard | ปุ่มไม่โผล่บนมือถือ | บน `(hover: none)` แสดงเสมอหรือเปลี่ยนเป็น tap-to-reveal |
| C5 | **Fixed width ≥ 320px + 100vh** | 934px: `manage-members-modal:879`, `vo-setting-modal:911` · 700: `vo-permission-guide-modal:32` · 696: `invite-member-modal:292` · 660: `vo-teleport-zone-picker:160` · 653: `vo-permission-snackbar:69` · 480: `vo-device-switch-modal:56` · 458: 14 modal (`vo-leave-workspace-modal:40`, `pz-unclaim-modal:37`, `pet-share-modal:196`, `vo-reconnect-failed-modal:19`, `vo-weather-panel:78`, `vo-environment-tab:495` …) · 366: `zone-enter-chat:280` · 320/322: member/notification/announcement/pet/profile panel, follow bar, knock, alert, toast (~20 ไฟล์) · `h-screen` `hero:12180` · `100vh` `vo-pet-panel:115`, `vo-weather-panel:85`, `vo-pip-minimap:151`, `vo-setting-modal:911` · side panel `absolute inset-y-0 left-[56px]` `hero:13870,13958,14044`, right stack `:13843`, sidebar rail `vo-sidebar.tsx:72` 56px | ล้นจอ 390px · `100vh` บน iOS นับรวม address bar / คีย์บอร์ด | bottom sheet + `100dvh` + `env(safe-area-inset-*)` (ตอนนี้ **0 จุด** ใน VO) · ต้องมี Figma mobile |
| C6 | **ไม่มี device/touch detection** | ไม่มี `isMobile`, `(pointer: coarse)`, `(hover: none)`, `maxTouchPoints` ที่ไหนเลย · มีแค่ `mobile-unsupported-overlay.tsx:8` (CSS `max-md:flex`, ไม่มี JS), `admin-sidebar.tsx:112` `matchMedia(max-width:1439px)`, `nature-layer.ts:155` `prefers-reduced-motion`, `lib/api/support.ts:84` userAgent (support ticket) | ไม่มีจุดกลางให้ branch | สร้าง `lib/platform.ts`: `isNative`, `isTouch`, `isIOS`, `isAndroid` ใช้ทั้ง C และ B |
| C7 | **Outside-click ใช้ `document` mousedown** | 20 จุด: `hero:4733`, `vo-background-effects-modal:154`, `vo-setting-modal:567`, `pz-zone-card:86`, `vo-screen-share-menu:51`, `vo-status-picker:45`, `vo-profile-panel:194,206`, `invite-member-modal:53`, `manage-members-modal:190,405`, `player-context-menu:61`, `vo-hud:179`, `vo-outside-display:158`, `zone-enter-header:295`, `vo-media-device-menu:94,259`, `announcement-list-panel:512`, `announcement-date-time:170,367` | touch ยิง mousedown ตามหลัง touchend ~300ms (ปกติใช้ได้) แต่ถ้ามี `touch-action: none` / preventDefault จะไม่ยิง | เปลี่ยนเป็น `pointerdown` ทีเดียวทั้งหมด (helper เดียว) |
| C8 | **IME / Thai keyboard** | ไม่มี `isComposing` / `onCompositionStart` ที่ไหนเลย · Enter ส่งใน `zone-enter-chat.tsx:814`, `message-input.tsx:457` | พิมพ์ไทย/ญี่ปุ่นบน iOS กด Enter กลาง composition = ส่งข้อความครึ่งเดียว | guard `e.nativeEvent.isComposing` |
| C9 | **Video element ต้อง `playsInline`** | `<video autoPlay>`: `vo-spotlight-stage.tsx:689,1055`, `vo-background-effects-modal.tsx:287`, `zone-enter-tiles.tsx:44,83`, `hero-workspace-enter.tsx:458` (`.play()` `:207`) — **ยังไม่ได้ตรวจว่ามี `playsInline`** | iPhone เปิด fullscreen player เองถ้าไม่มี `playsinline` แม้ตั้ง `allowsInlineMediaPlayback` แล้ว | ใส่ `playsInline` ทุก `<video>` |
| C10 | **Fullscreen ของ screen share ที่ดู** | `zone-enter-screen-share.tsx:97-116` `requestFullscreen` ไม่มี webkit fallback ไม่มี support check | iOS WKWebView ไม่มี element fullscreen | pseudo-fullscreen ด้วย CSS `fixed inset-0` |
| C11 | **Speaker picker / setSinkId** | `vo-media-device-menu.tsx:106,137-138,166`, `use-meeting-media.ts:527,936-964`, `media-preference.ts:103` (`zyra_device_speaker`) · `mic-test.ts:126-129` มี check | iOS ไม่มี `setSinkId` — picker ยังแสดง | ซ่อน speaker section บน iOS · เพิ่มปุ่ม "ลำโพง/หูฟัง" ผ่าน `navigator.audioSession` หรือ plugin ถ้าต้องการ |
| C12 | **Web Audio + autoplay** | AudioContext: `sfu-client.ts:1152-1160,1426`, `local-speaking-vad.ts:64`, `mic-test.ts:74`, `footstep-sound.ts:51`, `pet-sound-player.ts:65-70` (fallback `<audio>`), `environment-sound-player.ts:57-62` (เงียบถ้าไม่มี) · UI sounds `use-vo-sounds.ts:116` `new Audio()` 10 ไฟล์ เล่นที่ `hero:2101…11901` · unlock: `sfu.startAudio()` บน click/keydown `use-meeting-media.ts:1025-1027`, `use-spotlight-broadcast.ts:741-745`, `environment-sound-player.ts:144` | เหมือน Safari: ต้อง gesture แรก · iOS silent switch ปิดเสียง Web Audio ถ้า audioSession เป็น ambient | ตั้ง `navigator.audioSession.type = "play-and-record"` ตอนเข้าประชุม / `"playback"` ตอนอยู่ใน VO (iOS ≥ 17) · gesture แรกหลังเปิดแอป (splash → tap) |
| C13 | **Performance ต่อ device** | Pixi init `scene.ts:1599-1606` `resolution: devicePixelRatio` **ไม่ cap** (iPhone = 3×), `antialias:false`, ไม่ตั้ง `powerPreference` · `NAME_TAG_RESOLUTION = DPR × CAMERA_ZOOM_MAX` (`pixi-game/constants.ts:144-145`) = **9×** บนมือถือ · ไม่มี Culler/`cullable` (มีแค่ nature `nature-layer.ts:330-353`) · `ENV_FX_SPRITE_BUDGET = 560` weather sprites `scene.ts:289` (comment `:286` "FPS ยังไม่เคยวัด") · `pixi-filters` ใน package.json แต่ไม่ถูก import · rAF loop นอก engine: `hero:11946-12000` (3 loop), `vo-offscreen-self-indicator:112`, `pet-interaction-overlay:88`, `pet-sheet-player:115,133` · interval ≤100ms: `hero:916,3387`, `scene.ts:3107`, `local-speaking-vad.ts:40` (80ms), `mic-test.ts:52` (50ms) · FPS fallback มีแล้ว `lib/nature-performance.ts` (LOW_FPS 30 ×2 sample 5s → ปิด weather/แช่ต้นไม้) · Sentry replay 10% `instrumentation-client.ts:32` + Mixpanel `record_sessions_percent` `mixpanel.ts:77` | GPU/CPU มือถือ | cap `resolution ≤ 2`, `NAME_TAG_RESOLUTION` ≤ 4, `powerPreference: "high-performance"`, cull sprite นอกจอ, ลด `ENV_FX_SPRITE_BUDGET` บน mobile, ปิด background blur default, ลด replay sample บน native · **วัดตัวเลขก่อน/หลัง** |
| C14 | **Polling / keepalive ที่ไร้ประโยชน์บน native** | `tab-keepalive.ts` loopback `RTCPeerConnection` (`hero:8451`) กัน Chrome freeze tab · `auth-guard.tsx:41-42` poll session 30s + maintenance 10s · `version-check-modal.tsx:15` 30 นาที + on visible · `app-presence.tsx:21` 30s | ทำงานได้แต่เปลือง batt / ไม่มีความหมายในแอป | ปิด tab-keepalive บน native · หยุด poll ตอน `appStateChange` inactive |

### 14.4 ระดับ D — ทำงานได้เลย หรือแค่ปิดบน native

| # | เรื่อง | โค้ด | สถานะใน WebView |
|---|---|---|---|
| D1 | mic/cam `getUserMedia` | `use-entry-media-permission.ts:194,265`, `hero-workspace-enter.tsx:200`, `sfu-client.ts:578-744` | ✅ ต้อง `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` + Android runtime permission (Capacitor bridge `onPermissionRequest` ให้) · ตรวจ `mediaTypesRequiringUserActionForPlayback = []` |
| D2 | `enumerateDevices` / `devicechange` / สลับกล้อง | `lib/media-device-watch.ts:100-217`, `sfu-client.ts:1077,1102` · `facingMode` ไม่ได้ตั้งเอง (LiveKit จัดการ `:1191`) | ✅ เพิ่มปุ่มสลับหน้า/หลังผ่าน `switchActiveDevice` |
| D3 | Noise suppression worklet / background blur | `noise-processors.ts:91` `audioWorklet.addModule` (fallback raw mic `sfu-client.ts:1270`) · `video-background.ts:116-129` check WebGL2 + OffscreenCanvas + `MediaStreamTrackProcessor` (fallback `captureStream`) | ✅ มี feature-check ครบ · แนะนำปิด default บน mobile (CPU) |
| D4 | Clipboard `writeText` (7 จุด) | `message-item.tsx:351`, `hero:11486,11495`, `zone-enter-header.tsx:197`, `invite-member-modal.tsx:246`, `manage-members-modal.tsx:631`, admin ×3 | ✅ WKWebView iOS 13.4+ / Android WebView รองรับใน secure context · `@capacitor/clipboard` เป็น fallback |
| D5 | File input / drag-drop / paste | `<input type=file>` chat `message-input.tsx:597,606`, `zone-enter-chat.tsx:827,835`, profile, group icon, background effects, announcement, support + admin ×8 · ไม่มี `capture=` · drag-drop files `message-input.tsx:330` (ไม่มีบน touch แต่มีปุ่มแนบอยู่แล้ว) · `@dnd-kit` เฉพาะ admin | ✅ picker native ของ OS · เพิ่ม `capture="environment"` ให้ถ่ายรูปส่งแชทได้ · HTML5 drag ใน `pz-edit-hud.tsx:373-378` (decorate mode) ไม่ทำงานบน touch → ต้องเปลี่ยนเป็น pointer |
| D6 | Service worker / PWA | `pwa-register.tsx:15` register `/sw.js` (production) · `manifest.ts` | ปิดบน native — WKWebView รัน SW เฉพาะ App-Bound Domains · ไม่มีผลเสีย |
| D7 | Storage | cookie `zyra_token` (JS, 7 วัน) + `refresh_token` httpOnly + `zyra_locale` + `zyra_maintenance_bypass` · localStorage ~30 key (`user`, `zyra_selected_avatar`, `zyra_device_*`, `zyra_mic_enabled`, `zyra_seen_patch_notes`, …) · sessionStorage: `zyra_ws_tab_session`, `google_login_nonce`, `zyra_entry_media_prompted`, `zyra_otp_*`, `profile:*`, `forgot_password_state` · Dexie: `zyra-space-builder-drafts`, `zyra-draft-images` (admin) | ✅ ทั้งหมดใช้ได้ในโหมด remote URL · sessionStorage หายเมื่อ OS kill process → ผลแค่ต้องเข้า flow ใหม่ (OTP timer, ws session id) |
| D8 | Analytics / Sentry / GTM | `instrumentation-client.ts`, `lib/analytics/mixpanel.ts:45`, `app/layout.tsx:148-155` GTM | ✅ ทำงาน · เพิ่ม `@sentry/capacitor` ถ้าต้องการ native crash · tag `platform` |

### 14.5 สรุปเป็น list สั้น — "ต้อง native จริง ๆ" เรียงตาม Phase

**Phase 1 (ต้องมีก่อน submit):**
1. A2 Foreground service Android ตอนประชุม — Kotlin
2. A3 หน้า offline ของ shell — Swift + Kotlin เล็ก
3. B1 Google native sign-in + B2 Sign in with Apple — plugin + endpoint
4. B3 Push — plugin + Firebase + backend (Phase 2)
5. B4 Deep link — plugin + AASA/assetlinks
6. B5 Download → Filesystem + Share — plugin
7. B6 ลิงก์นอกแอป → Browser plugin (ไม่งั้น WebView navigate ออกจากแอป)
8. B7 Geolocation — plugin + permission string
9. B8 Android back button — plugin
10. B9 Keyboard — plugin
11. B12 Keep-awake — plugin
12. B13 Status bar / splash / orientation — plugin + Info.plist/Manifest
13. `Info.plist`: `UIBackgroundModes audio`, permission strings 3 ตัว · WKWebView: `mediaTypesRequiringUserActionForPlayback = []` (§13.1)

**Phase 1–2 (ทำให้เป็นแอปจริง):** B10 Haptics · B11 Badge · ปิด A4 auto-PiP mic hold + C14 tab-keepalive บน native

**Phase 3 (งาน native ใหญ่):** A1 Screen share (ReplayKit/MediaProjection) · A4 Native PiP · A5 CallKit ไม่ทำ

**ไม่ใช่ native แต่เป็นงานใหญ่กว่า native ทั้งหมดรวมกัน (Phase 0):** C1–C7 (joystick, hover, drag/pinch, HUD hidden-on-hover 7 จุด, fixed width ~40 จุด, platform detection, outside-click 20 จุด), C8 IME, C9 playsInline 6 จุด, C10 fullscreen, C11 speaker picker, C12 audioSession, C13 performance (DPR cap, name tag 9×, culling, 560 weather sprites)

---

## 15. Inventory รอบ 2 — ส่วนที่เหลือทั้งหมดนอก VO (2026-09-29)

ไล่ต่อจาก §14 ให้ครบทั้ง repo: หน้า member นอก VO ทุก route, chat, auth/OTP, GPU/memory/asset, CSS global, headers/backend/env, admin/dev, test · เกณฑ์เดียวกับ §14 · path จาก root ของ zyra-app

### 15.1 App shell (กระทบทุกหน้า)

| # | เรื่อง | โค้ด | ปัญหาบนมือถือ | ระดับ |
|---|---|---|---|---|
| S1 | Overlay บล็อกทุก route < 768px รวม admin | `app/layout.tsx:171` → `components/mobile-unsupported-overlay.tsx:9` (`max-md:flex`, CSS ล้วน ไม่มี JS) | ต้องเปลี่ยนเป็น flag + ตัด admin/editor route ออก | C |
| S2 | `viewport` export มีแค่ `themeColor` | `app/layout.tsx:85-87` | ไม่มี `viewportFit: "cover"`, `interactiveWidget`, `maximumScale` | C |
| S3 | `env(safe-area-inset-*)` = **0 จุดทั้ง repo** แต่ `appleWebApp.statusBarStyle: "black-translucent"` (`layout.tsx:96`) | ทุกหน้า | เนื้อหาซ้อน notch/status bar | C |
| S4 | ไม่มี `dvh`/`svh` ใน member pages (มี `100dvh` 2 จุดใน admin) · `h-screen`: `hero-workspace-enter.tsx:347`, `hero-workspace-loading.tsx:597`, `hero-user-workspace.tsx:301` (`calc(100vh-72px-32px) min-h-[600px]`), `vo-*` 14 จุด | | address bar / คีย์บอร์ดกิน viewport | C |
| S5 | **Body scroll lock ไม่มี** — ไม่มี `body.style.overflow` ที่ไหน · เฉพาะ Radix Dialog 5 ตัวได้ lock (create/copy-workspace-modal, confirm-modal, delete-avatar-modal, auth-guard) · modal `fixed inset-0` อีก ~20 ตัวไม่มี | ทั่ว repo | เปิด modal แล้วเลื่อนพื้นหลังทะลุบน iOS | C |
| S6 | Toaster `top-right` + toast `w-[336px]` | `app/layout.tsx:172`, `lib/toast.tsx:112,163`, `hero-verify.tsx:64` | ทับ status bar / ล้นจอแคบ | C |
| S7 | Manifest `orientation: landscape` — Capacitor ไม่อ่าน | `app/manifest.ts:11-12` | ต้องตัดสินใจใน Info.plist/Manifest (B13) | B |
| S8 | Error surface: มีแค่ `app/global-error.tsx` (English-only, `Sentry.captureException`) · ไม่มี `error.tsx`, `not-found.tsx`, ErrorBoundary, `unhandledrejection` handler, Sentry `beforeSend`/`ignoreErrors` | | crash ใน VO บนมือถือ = จอขาว ไม่มีทางกลับ | C |
| S9 | Provider/mount order: AuthGuard → AppPresence (30s) → Mixpanel → ClickTracker → PwaRegister → VersionCheckModal → VOGlobalWidget → Toaster → Overlay | `app/layout.tsx` | ต้องหยุด poll ตอน background (C14) และปิด PwaRegister บน native (D6) | C |

### 15.2 หน้า member นอก VO — route ต่อ route

Route ทั้งหมด 53 page + 5 API (public 13 · member 10 · admin 28 · dev 2) · `/workspace/[id]/chat` redirect ไป `/play` (chat มีแค่ overlay ใน VO `hero-virtual-office.tsx:14045`) · `/workspace/preview/[id]` และ `/workspace/builder/[id]` ใช้ **admin workspace-editor** ตรง ๆ (desktop only) · `views/home/hero-home.tsx` เป็นไฟล์ตาย

| Route | View | Fixed width / layout ที่พังบนจอ 390px | อื่น ๆ |
|---|---|---|---|
| `/` | `views/user/workspace/hero-user-workspace.tsx` | `:301` `h-[calc(100vh-72px-32px)] min-h-[600px]` · dropdown `:408` 200px · grid `:439,472` responsive แล้ว ✅ · `workspace-capacity-modals.tsx:23,79,148` 458/458/554px · `join-workspace-modal:50` 480 · `workspace-leave-modal:30`, `idle-removed-modal:16` 458 | outside-click mousedown `:226,237`, `workspace-card.tsx:248` |
| `/workspace/[id]` (lobby) | `views/user/workspace-enter/hero-workspace-enter.tsx` | `:347` h-screen · `:442` `w-[934px] max-w-[calc(100vw-32px)]` · `:451` 562px · device menu `:406` 289px · `change-character-modal.tsx:86` `min-h-[600px] w-[820px]` + `grid-cols-5` `:145,158` | getUserMedia preview `:200`, enumerateDevices `:186`, devicechange `:257`, Escape `:74`, mousedown `:170,268` |
| `/workspace/[id]/loading` | `hero-workspace-loading.tsx`, `components/workspace-loading-screen.tsx` | `:597` h-screen · `:612-643` 696/580/456px (`:613` มี 100vw clamp) · loading-screen `:50-73` 696/664/580/456 | preload avatar sheets `lib/vo-preload.ts:54` |
| `/workspace/new/[t]/welcome` | `views/user/space-builder/hero-welcome-space.tsx` | `:80` `w-[934px] max-w-full` · `:88-89` 562×344 · `100vh/100vw` `:66,79` · `create-workspace-modal.tsx:271` **`h-[600px] w-[900px] sm:max-w-[900px]`** (override Radix max-w) + pane `:652` 537px + `grid-cols-3` `:560,570` · `copy-workspace-modal.tsx:141,180` เหมือนกัน · `:385/:286` 458 | mousedown `create-workspace-modal:896`, Enter `copy-workspace-modal:242`, `.focus()` `:66,:157` |
| `/join/[token]` | `views/user/accept-invite/hero-accept-invite.tsx` | `:68` 458 + `p-[40px]` | bounce `/login?redirect_url=/join/…` `:143` (B4) |
| `/setting` | `views/profile/*` | responsive แล้ว (`sm:` 41, `lg:` 25) ✅ · `upload-avatar-modal.tsx:187` 550px · `confirm-modal:24`/`delete-avatar-modal:32` `w-[calc(100vw-32px)] sm:w-[458px]` ✅ | `react-easy-crop` รองรับ touch ✅ · Radix Tooltip `profile-form.tsx:258` ไม่เปิดด้วย touch |
| `/setting/change-password` | `views/change-password` | responsive ✅ (`sm:` 10, `lg:` 5) | |
| `/login`, `/signup`, `/forgot-password`, `/reset-password/[t]`, `/signed-out`, `/maintenance` | auth cards | `max-w-[458px]` fluid ✅ | Google popup `card-login.tsx:314` (B1) · `autoComplete` ครบ ✅ |
| `/verify/[id]` (OTP) | `views/verify/hero-verify.tsx` | `:64` toast `fixed top-4 right-4 w-[336px]` | **6 ช่อง `maxLength=1` ไม่มี `autoComplete="one-time-code"`** `:526-548` → iOS SMS/Mail autofill ใส่ทั้ง code ลงช่องเดียว `handleChange :398` เก็บแค่ตัวสุดท้าย · paste ผ่าน wrapper `:527→431` ✅ · `.focus()` ×9 · `inputMode="numeric"` ✅ |
| `/legal` | `views/legal` | `w-[1097px]` ใน `hidden lg:block` ✅ | IntersectionObserver `:63` |
| help center (panel ใน VO) | `views/help-center/help-center-panel.tsx` | `:143` `w-[336px]` · `grid-cols-2` `:385` | mousedown `contact-support-form.tsx:74` |
| onboarding / feature tour | `views/onboarding/onboarding-modal.tsx:96` **900×600** · `onboarding-skip-modal:20`, `-success-modal:19` 458 · `views/feature-tour/feature-tour-modal.tsx:37,62` 458/600 | | `create-workspace-spotlight.tsx:59` ใช้ `click` ✅ |
| navbar | `components/app-navbar.tsx:123` `absolute right-0 min-w-[289px]` | | mousedown `:71` |
| version check | `components/version-check-modal.tsx:104,149,186` 320 / max 458 | | |

Responsive prefix = **0** ทั้ง folder: app, accept-invite, workspace-enter, workspace-loading, workspace-preview, **chat**, help-center, reset-password, maintenance, feature-tour, onboarding, rich-text, toast · มี responsive แล้ว: profile, legal, change-password, user/workspace (บางส่วน)

### 15.3 Chat module (`views/chat/**`, responsive prefix = 0)

| # | เรื่อง | โค้ด | ระดับ |
|---|---|---|---|
| CH1 | **Message actions ซ่อนจน hover** — react / reply / thread / more (copy, edit, delete) ทั้งหมดอยู่ใน `isHovered` state + portal `fixed` | `message-item.tsx:152,398-412` · ไม่มี `onContextMenu`, long-press, touch handler ที่ไหนเลยใน chat | C — ต้อง long-press / swipe / ปุ่ม "…" ถาวร |
| CH2 | ปุ่มลบ attachment / cancel upload ซ่อนจน hover | `pending-attachment-card.tsx:49-50,65,89` | C |
| CH3 | ปุ่ม download ไฟล์ซ่อนจน hover | `message-attachment-block.tsx:172` (`hidden group-hover/file:flex`), `file-preview.tsx:456` | C (+ B5 download) |
| CH4 | Layout 2 คอลัมน์ fixed: sidebar `w-[320px] shrink-0` + conversation `flex-1` ไม่มี breakpoint | `chat-surface.tsx:294,338-353`, `chat-sidebar.tsx:362` | C — mobile ต้อง stack: list → conversation |
| CH5 | Panel ขวา `absolute inset-y-0 right-0 w-[320px]` | `thread-panel.tsx:77` (ไม่มี max-w), `conversation-info-panel.tsx:91`, `conversation-media-panel.tsx:110` (`max-w-full` ✅) · `create-group-modal.tsx:332` 320 · `search-filter-popover.tsx:120` `absolute left-[16px] top-[116px] w-[340px]` · `reaction-modal.tsx:37` 366 · `message-text.tsx:50` 400 · `file-preview.tsx:375`, `file-error-modal.tsx:61` 600 (`max-w-[calc(100vw-32px)]` ✅) · `file-preview.tsx:307` `70vh` | C |
| CH6 | **Image preview pan/zoom เป็น mouse-only**: `onMouseDown` + window `mousemove/mouseup`, zoom ด้วย non-passive `wheel` | `file-preview.tsx:122,156-157,299,406` | C — ต้อง pointer + pinch |
| CH7 | **Message list ไม่ virtualize** — โหลดทีละ 30 prepend ลง zustand ไม่จำกัด, jump-to-message โหลดได้ถึง 10 หน้า, ทุก message อยู่ใน DOM | `message-list.tsx:76,78` · IntersectionObserver `:249` มีแค่ pagination · ไม่มี react-window/virtual ใน package.json | C — memory บนมือถือ |
| CH8 | Enter ส่ง / ไม่มี `enterKeyHint` / ไม่มี `isComposing` | `message-input.tsx:457,575` | C (=C8) |
| CH9 | Drop file desktop-only (มีปุ่มแนบแล้ว ✅) · mention popup ใช้ Arrow/Enter/Tab `:436-455` · `onMouseDown preventDefault` `:488` | `message-input.tsx:330,468-473` | D |
| CH10 | Outside-click mousedown: `conversation-info-panel:55`, `conversation-menu:87`, `search-filter-popover:85,100`, `chat-sidebar:328`, `message-item:251`, `emoji-picker:58` · Escape ×9 · Cmd+K `chat-surface.tsx:85` · gallery Arrow `file-preview.tsx:108` (มีปุ่มบนจอ ✅) | | C (=C7) |
| CH11 | `window.innerWidth` clamp popover `message-item.tsx:146,269-282`, `message-input.tsx:154-171` · `title=` 56 จุด | | D |

### 15.4 GPU / memory / asset (engine) — เพิ่มจาก C13

| # | เรื่อง | โค้ด | ผลบนมือถือ | ระดับ |
|---|---|---|---|---|
| G1 | **ไม่มี WebGL context-loss handling เลยทั้ง repo** — ไม่มี `webglcontextlost`/`contextrestored`/`isContextLost`/`renderer.on(` | `zyra-engine/pixi-game/scene.ts` ทั้งไฟล์ | iOS ยึด GPU context เมื่อสลับแอป/memory pressure → canvas ดำจนกว่าจะ reload | C (สำคัญ) |
| G2 | `app.init` ไม่ตั้ง `powerPreference`, `preference`, ไม่ cap `resolution` (= DPR 3 บน iPhone) | `scene.ts:1598-1606` | render 3× pixel | C |
| G3 | ไม่มี `cullable`/`Culler`/`cullArea` — ทุก object ถูก submit ทุก frame (มีแค่ nature `nature-layer.ts:330-353`) | | draw call ไม่ลดตามจอ | C |
| G4 | ไม่มี texture size cap (ไม่มี 4096/8192 check) · แผนที่พื้นหลัง full-res ไม่จำกัด `scene.ts:1755-1765` · upload crop cap เดียวคือ `lib/canvas-utils.ts:11` 1024 | | iOS WebGL max texture 4096 บนเครื่องเก่า → texture หาย | C |
| G5 | `texCache` Map ไม่มี LRU/ขนาดจำกัด, `_texCache.clear()` ตอน destroy ไม่ `texture.destroy()` · `app.destroy(false)` ไม่ส่ง `{children,texture}` | `utils.ts:591,663-728`, `scene.ts:11216,11224` | GPU memory ไม่คืนเมื่อสลับ workspace | C |
| G6 | Alpha hit-test สร้าง RGBA copy ทั้ง sheet ต่อ texture (~4 MB ต่อ sheet 1000²) + outline canvas ต่อสี | `utils.ts:762,780-836` | RAM ต่อ peer สูง (peer ละ 2 sheet walk+sit `scene.ts:10865-10982`) | C |
| G7 | **Init race**: `pixi-canvas.tsx:360-376` เรียก `scene.init()` ไม่ await, unmount ระหว่าง init → `destroy()` เห็น `app === null` แล้ว Application + loop เริ่มทีหลัง (admin preview มี `cancelled` guard `sprite-pixi-preview.tsx:28-81` แต่ VO ไม่มี) | | leak เมื่อออกจาก VO เร็ว (บนมือถือเกิดบ่อยกว่า) — อนุมานจากโค้ด ยังไม่ทดสอบ | C |
| G8 | Name tag `NAME_TAG_RESOLUTION = DPR × 3.0` = 9 บนมือถือ · `BitmapText` ไม่ใช้ | `pixi-game/constants.ts:144`, `scene.ts:842` | texture ข้อความใหญ่ 81× พื้นที่ | C |
| G9 | Weather `ENV_FX_SPRITE_BUDGET = 560` GifSprite (`Assets.load parser gif` `:5254,6079,6134`) · nature 32 row × 150 leaves · world default 100×100 tile = 3200² px (`hero:5905`), ไม่มี cap map size/object count | `scene.ts:289,5236` | FPS fallback มี (`lib/nature-performance.ts` 30fps/10s) แต่ threshold ควรต่างบน mobile | C |
| G10 | Asset: `public/` 24 MB — MediaPipe 19 MB (lazy เฉพาะ background effect ✅), RNNoise wasm lazy ✅, VO เริ่มโหลด: avatar sheet default 192² (32 KB), map thumb → full, pieces ทุกชิ้นผ่าน `/api/img` (ไม่ resize ไม่แปลง format `app/api/img/route.ts:25`), **10 mp3 preload `auto`** `use-vo-sounds.ts:116-117` · concurrency 4 (12 ตอน preload) timeout 8s `utils.ts:618-637` | | cellular: preload เสียง 10 ไฟล์ + full-res map ทันที | C |
| G11 | ไม่มี `deviceMemory`/`hardwareConcurrency`/`performance.memory`/`requestIdleCallback` · member list ไม่ virtualize | | ไม่มี adaptive ตาม spec เครื่อง นอกจาก FPS fallback | C |
| G12 | `pixi-filters` ใน package.json ไม่ถูก import · `RenderTexture` ไม่ใช้ · `phaser` + `phaser3-rex-plugins` ติดตั้งแต่ไม่ถูก import (dead dep) | | bundle size | D |

### 15.5 CSS / render cost (Tailwind class count)

| Class | views/user | views/chat | components | หมายเหตุ |
|---|---|---|---|---|
| `backdrop-blur` | **50** | 0 | 2 | GPU หนักบน mobile · hotspot `zone-enter-tiles.tsx` 8, `hero-virtual-office.tsx` 5 |
| `animate-*` | 48 | 19 | 15 | |
| `shadow-2xl` | 12 | 0 | 0 | |
| `transition-all` | 16 | 1 | 2 | |
| CSS filter | 12 | 0 | 1 | |
| `hover:` | 436 | 101 | 50 | |
| `h-screen`/`100vh` | 14 | 0 | 0 | |
| `will-change` / `mix-blend` | 0 | 0 | 0 | |

`globals.css`: ไม่มี `:hover`, `position: fixed`, `100vh`, `backdrop-filter`, `touch-action`, `overscroll`, `-webkit-tap-highlight`, safe-area · มี `cursor: pointer` global `:200-206` · `scrollbar-gutter: stable both-edges` `:184` (บน iOS ไม่มีผล) · keyframes 10 ตัว, `.nature-sway` infinite + `will-change: transform` `:347`, `.nature-leaf` infinite `steps(8)` + box-shadow `:392-398` · `@custom-variant dark` แต่ dark class ไม่เคย toggle (app dark-only) · Fonts: Inter 4 น้ำหนัก + Poppins 3 + Pixelify Sans 4 + Noto Sans Thai 4 (subset thai) ทั้งหมด `next/font/google display:swap` `app/layout.tsx:51-77` → 15 font file แรกเข้า

### 15.6 Platform / headers / backend / env

| # | เรื่อง | ข้อเท็จจริง | ผลต่อ Capacitor | ระดับ |
|---|---|---|---|---|
| P1 | Security headers | **ไม่มี** CSP, X-Frame-Options, Permissions-Policy, HSTS, COOP/COEP ทั้ง zyra-app และ zyra-api · `next.config.ts headers()` มีแค่ `/sw.js` | ไม่มีอะไรบล็อก WebView ✅ (แต่ควรมี HSTS/Permissions-Policy ในอนาคต — ไม่เกี่ยว mobile) | D |
| P2 | WASM | RNNoise (`noise-processors.ts:77-110`) + MediaPipe (`vision_wasm_internal.js`) **single-thread ไม่ใช้ SharedArrayBuffer/Atomics** · MediaPipe ต้อง WebGL2 + OffscreenCanvas + `VideoFrame` + `createImageBitmap` (`video-background.ts:112-125`) | ไม่ต้อง cross-origin isolation ✅ · MediaPipe บน WKWebView ต้องทดสอบ (`VideoFrame` iOS ≥ 16.4?) | D/⚠️ |
| P3 | **zyra-ws origin check** | `zyra-ws/internal/handler/handler.go:76-93` match `Origin` กับ `ALLOWED_ORIGINS` exact (default `*`) | โหมด remote URL origin = domain เดิม ✅ · ถ้าย้ายเป็น bundle (§3.2) ต้องเพิ่ม `capacitor://localhost` + `http://localhost` | E (config) |
| P4 | **Cookie `refresh_token`** | `zyra-api/internal/handler/auth_handler.go:244` `SetCookie(..., Secure=false, HttpOnly=true)` ไม่มี SameSite (browser default Lax) · `zyra_token` JS cookie SameSite=Lax ไม่ Secure (`lib/auth/session.ts:24`) | remote URL HTTPS ใช้ได้ ✅ แต่ควรตั้ง `Secure=true` · bundle mode ใช้ไม่ได้ (cross-site) | E |
| P5 | zyra-api CORS | มีเฉพาะ `/api/public/*` (`public_cors.go`) ไม่มี `Allow-Credentials` · ทุก route อื่นพึ่ง same-origin ผ่าน Next rewrite | remote URL ✅ · bundle mode ต้องเพิ่ม credentialed CORS ทั้ง API | E |
| P6 | `/api/img` proxy | `app/api/img/route.ts` **ไม่มี host allowlist ไม่มี size limit** (open proxy) · ไม่ resize | ไม่กระทบ mobile โดยตรง แต่ควรปิดช่อง + เพิ่ม resize สำหรับ mobile (G10) | E |
| P7 | `NEXT_PUBLIC_*` bake ตอน build ต่อ env (dev/uat/prod ผ่าน GitHub Environment) | `SOCKET_URL`, `CDN_URL`, `GOOGLE_CLIENT_ID`, `APP_ENV`, `GTM_*`, `MIXPANEL_TOKEN`, `SENTRY_DSN`, flags `PET/ROOM_PET/SPOTLIGHT/ROADMAP/ENVIRONMENT` · **ไม่ถูกอ่านเลย**: `LIVEKIT_URL`, `RECAPTCHA_SECRET`, `MICROSOFT_CLIENT_ID/TENANT_ID`, `VO_MOVEMENT_V2` (hard-code true) | Capacitor build flavor ต้อง map `server.url` ↔ env เดียวกัน · `NEXT_PUBLIC_CDN_URL` ใช้แค่ 2 ไฟล์ ที่เหลือ hard-code R2 URL 10+ ไฟล์ (`layout.tsx:81`, `pixi-game/constants.ts:204,214`, `environment-sound.ts:35` …) | B14 |
| P8 | SSE | `app/api/admin/presence/events/route.ts` proxy `text/event-stream` · client `lib/api/presence.ts:62-110` fetch+reader retry 5s · `EventSource` ไม่ใช้ | admin only ✅ · fetch streaming ใน WKWebView ได้ | D |
| P9 | Browser API อื่น | `crypto.randomUUID` 16 จุด (guard แค่ `ws-tab-session.ts:15`) — secure context ✅ · `Intl.Segmenter` `vo-profile-panel.tsx:100` (iOS 15.4+ ✅ มี fallback) · `TextDecoder`, `scrollIntoView`, `replaceAll`, `Array.at` ✅ · tsconfig `target ES2017` ไม่มี browserslist → Next default | ✅ | D |
| P10 | i18n | next-intl ไม่มี routing, `zyra_locale` cookie 1 ปี, `i18n/request.ts` **ไม่ตั้ง `timeZone`** → ใช้ของเครื่อง · `Intl.DateTimeFormat` 5 จุด, `toLocale*String` 46 จุด | ✅ · timezone ต่างเครื่อง = เวลาต่างกันอยู่แล้วบน desktop | D |
| P11 | Test | Playwright `playwright.config.ts` viewport 1440×1024 projects Desktop Chrome/Firefox/Safari **ไม่มี mobile project** · Vitest env `node` | ต้องเพิ่ม project `iPhone 13` (task 0.10) | C |

### 15.7 Admin / dev — desktop only ตาม spec (ไม่ทำ mobile)

overlay S1 บล็อกอยู่ · `components/admin/admin-sidebar.tsx:172-193` มี hamburger `lg:hidden` แล้ว แต่ body ทุกหน้า desktop-only

| Folder | ตัวบล็อกหลัก |
|---|---|
| workspace-editor (21.7k บรรทัด, serve `/workspace/builder` + `/workspace/preview` ด้วย) | custom canvas editor `map-editor-canvas.tsx:2997`, mouse-move 16 handler, draggable LeftPanel `hero-workspace-editor.tsx:5658`, `onDragStart :6808` |
| object-management (12.5k) | Konva `Stage` `konva-canvas.tsx:4` + dnd-kit `object-composer.tsx:1348` |
| roadmap-scene | HTML5 draggable → canvas `scene-library-panel.tsx:112`, `setPointerCapture` `scene-editor-canvas.tsx:102` |
| roadmap | `w-[368px]` + `w-[420px]` (`roadmap-list-panel:101`, `hero-roadmap:345`) |
| map-management | mouse-only pan + wheel `map-preview-canvas.tsx:237,272-276` |
| avatar-management / pet-management | Pixi preview modal · `grid-cols-[346px_…]` `pet-upload-step:585` · `w-[650px]` `xp-configuration-panel:577` |
| user-management / support / patch-notes / workspace-management | ตาราง `min-w-[900px]`–`[1048px]` (`role-list-panel:170`, `hero-workspace-list:154`, `hero-customer-management:199`, `hero-support-list:96`, `hero-patch-note-management:116`) · `grid auto-fill 350px` |
| online / settings / status | `w-[640px]` ใน `h-screen` |
| views/dev/* | Pixi canvas + `<table>` + `min-w` กว้าง |

**ข้อควรระวัง:** member route `/workspace/preview/[id]` และ `/workspace/builder/[id]` ใช้ admin editor → บนมือถือต้องซ่อนทางเข้า หรือแสดงหน้า "เปิดบน desktop"

### 15.8 สรุปรวม §14 + §15

| ระดับ | §14 | §15 เพิ่ม | รวม |
|---|---|---|---|
| **A** native code จริง | 5 | 0 | **5** |
| **B** plugin + branch | 13 | +1 (B14 env/flavor mapping) | **14** |
| **C** โค้ดเว็บต้องแก้ | 14 | +9 shell (S1–S6, S8, S9, P11) +11 member pages (15.2) +8 chat (CH1–CH8) +11 GPU/memory (G1–G11) | **~53** |
| **D** ทำงานได้ | 8 | +7 (CH9, CH11, G12, P1, P2, P8–P10) | **15** |
| **E** backend/infra config (ไม่ใช่ native ไม่ใช่ web) | — | +4 (P3 ws origins, P4 cookie Secure, P5 CORS, P6 img proxy) | **4** |

**สิ่งที่ยังไม่ได้ทำใน inventory นี้ (โดยตั้งใจ):** วัดตัวเลข performance/memory จริงบนเครื่อง · ทดสอบ MediaPipe/`VideoFrame` บน WKWebView · ตรวจ `playsInline` ทีละไฟล์ (C9) · ingress annotations ใน zyra-infra (ไม่ได้ค้น — อาจมี header เพิ่มที่ระดับ ingress) · i18n string ใหม่สำหรับ UI mobile
