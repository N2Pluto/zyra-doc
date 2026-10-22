# Mobile App — Code Map (หลักฐานจากโค้ดจริงต่อ task)

> **สถานะ:** ตรวจกับโค้ดจริงแล้ว 2026-10-05 · เอกสารอย่างเดียว ยังไม่แตะโค้ด · ยังไม่ sync Notion · **repo:** zyra-app, zyra-api, zyra-ws, zyra-notifications, zyra-infra, zyra-mobile (ยังไม่มี repo)
> **เลขบรรทัดอ่านจาก branch:** zyra-app `fix/evening-office-lights` @ `d3585bc` · zyra-api และ zyra-ws `fix/object-catalog-collision-sync` · zyra-notifications `develop` — **ไม่ใช่ `develop` ของทุก repo** ถ้าเปิดบน branch อื่นเลขอาจเลื่อน ให้ค้นด้วยชื่อ symbol ที่ให้ไว้คู่กัน
> **เป็นภาคผนวกของ:** [task-breakdown.md](task-breakdown.md) (ตารางงานแบ่งตาม module ของโค้ด) · [technical-design.md](technical-design.md) §0 (แผนที่โค้ดภาพรวม + flow) และ §23 (จุดที่เอกสารเดิมผิดจากโค้ด)

## วิธีอ่าน

- task ละ 1 หัวข้อ มี anchor `#t-<id>` เช่น `code-map.md#t-0-16` · task ที่แตกหลาย repo (เช่น 0.16a / 0.16b / 0.16c) มีหัวข้อเต็มที่ module หลัก module อื่นมีบรรทัดชี้กลับ
- ทุกหัวข้อมีบล็อก:
  - **ข้อความเดิม** — คัดจาก task-breakdown ฉบับแบ่งตาม Phase (ก่อน 2026-10-05) ครบทุกคำ: มติ, Done เมื่อ, Figma node, § ของ ux-ui-plan, test ID · ส่วนที่ code map พบว่าผิดดูในบล็อก "ผิดจากเอกสาร"
  - **มีอยู่แล้ว (verified)** · **ต้องแก้** · **ไฟล์ใหม่** (ชื่อไฟล์เป็นข้อเสนอ เว้นแต่ระบุว่าบังคับ) · **ผิดจากเอกสาร** · **ขึ้นกับ**
- ตัวย่อ path:
  - path ที่ไม่มีชื่อ repo นำหน้า = zyra-app · repo อื่นเขียนชื่อนำหน้า (`zyra-ws/internal/hub/room.go`)
  - `hero` = `views/user/virtual-office/hero-virtual-office.tsx` · `scene.ts` = `zyra-engine/pixi-game/scene.ts`
  - ไฟล์ `vo-*.tsx`, `zone-enter-*.tsx`, `pz-*.tsx`, `zone-*.tsx` ที่ไม่มี path เต็ม อยู่ใน `views/user/virtual-office/components/`
  - ไฟล์แชทที่ไม่มี path เต็ม (`message-input.tsx`, `chat-sidebar.tsx` …) อยู่ใน `views/chat/components/` · ยกเว้น `views/chat/chat-surface.tsx`
- 🔍 = ยังต้องเช็คต่อ · ⚠️ = ขัดกับเอกสารอื่น รอตัดสิน
- **task ที่ code map รอบนี้ไม่ได้ไล่:** 0.10 (Playwright mobile — รู้แค่ว่า `e2e/` + `playwright.config.ts:32-36` มีแต่ project desktop) · 0.39 (ตัดออกแล้ว 2026-10-02) · ทั้งสองยังอยู่ในรายการ
- **task ใหม่จาก code map (เพิ่ม 2026-10-05):** [1.17](#t-1-17) Android foreground service ตอนประชุม (TD §13.1 / §14.1 A2) · [0.62](#t-0-62) zyra-ws presence grace (TD §12.3 ข้อ 1–2)

## ข้อเท็จจริงร่วม (ใช้กับทุก module)

1. **ยังไม่มีโค้ด mobile เลย** — ไม่มี `lib/platform.ts`, `lib/workspace-mode.ts`, `views/user/virtual-office/lite/`, `components/mobile-rotate-screen.tsx` · grep `matchMedia` / `maxTouchPoints` / `screen.orientation` / `visualViewport` / `safe-area` / `viewportFit` ใน path member = 0 จุด (มีแค่ `components/admin/admin-sidebar.tsx:112` ที่ใช้ `matchMedia` วัดความกว้าง)
2. **ยังไม่มี Capacitor** — `zyra-app/package.json` ไม่มี `@capacitor/*` · repo `zyra-mobile` ยังไม่มี · แอปจะโหลด zyra-app จาก URL จริง (remote URL) ดังนั้นโค้ดที่เรียก plugin อยู่ใน bundle ของ zyra-app → ต้องลง `@capacitor/core` + JS ของ plugin ใน `zyra-app/package.json` ด้วย (task 1.1) · ก่อนลง ให้ตรวจ native ผ่าน `window.Capacitor?.isNativePlatform?.()` ห้าม import `@capacitor/core`
3. **ไม่มี repo `zyra-engine` แยก** — engine อยู่ใน `zyra-app/zyra-engine/` · VO ใช้ `zyra-engine/pixi-game/scene.ts` (PixiJS 8, 11,235 บรรทัด) · ส่วน Phaser (`zyra-engine/{scenes,systems,assets,canvas-game}`) เป็นของ play-test/editor (AGENTS.md เขียนว่า Phaser หมายถึงส่วนนี้)
4. **Movement V2 เป็น protocol เดียว** — comment `hero:3426` บอกว่า flag ถูกเอาออกแล้ว · เดินหาเส้นทางส่ง `goto` (`lib/api/workspace-ws.ts:558`) · `moveTo()` (`:540`) ยังมีแต่ไม่ได้ใช้ → ไม่มี "legacy `move_to`" ให้ map เข้า
5. **convention ของ zyra-app ที่แผนเดิมมองข้าม:**
   - `lib/` ไม่มี React hook สักตัว — logic ล้วนอยู่ `lib/*.ts` (เช่น `lib/nature-performance.ts`) · hook อยู่ `hooks/use-*.ts` (มี `"use client"` เช่น `hooks/use-user-guard.ts`) หรือ `views/<feature>/use-*.ts` (เช่น `views/user/virtual-office/use-nature-performance.ts`) → "hook ใน `lib/platform.ts`" ของ TD §16.4/§16.8 ย้ายไป `hooks/`
   - test อยู่ `__tests__/*.test.ts(x)` ที่ root (202 ไฟล์ ไม่มีโฟลเดอร์ย่อย) · `vitest.config.ts` env = `node` · test hook ใส่ `// @vitest-environment jsdom` บรรทัดแรก + `renderHook` จาก `@testing-library/react` (ตัวอย่าง `__tests__/use-nature-performance.test.tsx:1-4`)
   - localStorage key = `zyra_<snake>` กัน `typeof window` + `try/catch` (ดู `lib/patch-note-seen.ts:10-38`, `lib/media-preference.ts:42-62`)
   - component ย่อยของ feature อยู่ `views/<feature>/components/` · component ของ VO ตั้งชื่อ `vo-*.tsx`
6. **ไม่มี bottom sheet** — `components/ui/` มี dialog (Radix), dropdown-menu, select, switch, skeleton … ไม่มี sheet และไม่มี vaul · ⚠️ code map เสนอ `components/ui/bottom-sheet.tsx` แต่ **rule 08 ห้าม import `@/components/ui/*` ยกเว้น skeleton / icon** → เอกสารนี้ใช้ `components/bottom-sheet.tsx` (Tailwind ล้วน) แทน ตัดสินชื่อจริงตอนทำ 0.15
7. **ไฟล์ใหญ่ที่ทุก module แตะ:** `hero` 14,838 บรรทัด · `scene.ts` 11,235 · `views/user/virtual-office/use-meeting-media.ts` 2,582 · `lib/api/sfu-client.ts` 1,865 · `lib/api/workspace-ws.ts` 1,117 · `zyra-ws/internal/hub/room.go` 3,313
8. **migration ถัดไปของ zyra-api = 108** — ล่าสุด `107_environment_place_label_lang.sql` (ไม่มีเลข 104) · README zyra-api บอกให้ apply ด้วยมือ แต่ `internal/database/postgres.go:13-16` มี slice `migrations` ที่รันตอน start (mirror ล่าสุดคือ 103 ที่ `:1020` · 105–107 ไม่ได้ mirror) · task ที่ต้องมี migration (0.25b, 0.37b, 2.1) **ห้ามจองเลขในเอกสาร** ใคร merge ก่อนได้ 108 ถัดไป 109, 110
9. **flag `NEXT_PUBLIC_*` ใหม่ต้องเพิ่ม 2 ที่** — `Dockerfile` (ARG + ENV) และ `.github/workflows/deploy-gitops.yml` (env จาก secrets + `--build-arg`) + GitHub Environment secret ต่อ env

---

## <a id="mod-a"></a>A. App shell & platform

zyra-app `app/`, `proxy.ts`, `lib/platform.ts` (ใหม่), `hooks/` (ใหม่), `components/` ระดับ root, `instrumentation-client.ts`, `lib/analytics/*`

### <a id="t-0-1"></a>0.1 Feature flag `NEXT_PUBLIC_MOBILE_VO` + overlay (0.1a zyra-app · 0.1b build → [K](#mod-k))
> **ข้อความเดิม (Phase 0):** งาน — Feature flag `NEXT_PUBLIC_MOBILE_VO` — overlay "Mobile unsupported" แสดงเฉพาะเมื่อ flag ปิด หรือหน้า admin/editor · ไฟล์ที่เอกสารเดิมระบุ — `components/mobile-unsupported-overlay.tsx`, `app/layout.tsx` · ขึ้นกับ (เดิม) — — · Done เมื่อ — flag เปิด → หน้า VO เข้าได้บนมือถือ · flag ปิด → เหมือนเดิม
- **มีอยู่แล้ว (verified):**
  - `components/mobile-unsupported-overlay.tsx:8` `MobileUnsupportedOverlay({title, description})` — server component CSS ล้วน `hidden … max-md:flex` (`:9`) ไม่มี JS ไม่มี `"use client"`
  - `app/layout.tsx:19` import · `:140` `getTranslations("MobileUnsupported")` · `:171` จุด render (ใน `<Providers>` ใต้ `<Toaster>`)
  - ข้อความแปล `messages/en.json:4041`, `messages/th.json:4041` namespace `MobileUnsupported` {title, description}
  - pattern ของ flag: `lib/room-pet-feature.ts:15-19` (`ROOM_PET_FLAG_ENV`, `isRoomPetEnabled()` ค่าเริ่มต้น OFF ต้องเป็น `"true"` เท่านั้น) · `lib/spotlight-feature.ts:21-25` (ค่าเริ่มต้น ON) · test `__tests__/room-pet-feature.test.ts`
  - flag ไหลเข้า build: `Dockerfile:24,27` (ARG) + `:64-65` (ENV) · `.github/workflows/deploy-gitops.yml:142-143` (env จาก secrets) + `:168-169` (`--build-arg`)
  - pathname ฝั่ง server: `proxy.ts:36` set header `x-zyra-pathname` (`i18n/messages-scope.ts:37` `PATHNAME_HEADER`, `:46` `needsAdminMessages()`)
  - route ที่นับเป็น admin/editor: `app/admin/**`, `app/workspace/builder/[id]/page.tsx` (`HeroWorkspaceEditor userMode`), `app/dev/**`, `app/object-management/page.tsx` (redirect ไป admin)
- **ต้องแก้:**
  - `components/mobile-unsupported-overlay.tsx` → `"use client"` + `usePathname()` + `isMobileVoEnabled()` · แสดงเมื่อ flag ปิด หรืออยู่ route `/admin`, `/workspace/builder`, `/dev` · props title/description รับจาก layout เหมือนเดิม (`app/layout.tsx:171` ไม่ต้องแก้)
  - **0.1b:** `Dockerfile` + `deploy-gitops.yml` เพิ่ม `NEXT_PUBLIC_MOBILE_VO` (ARG/ENV/env/build-arg) + ตั้ง GitHub Environment secret ของ dev / uat / production
- **ไฟล์ใหม่:** `lib/mobile-vo-feature.ts` (`MOBILE_VO_FLAG_ENV`, `isMobileVoEnabled(value = process.env.NEXT_PUBLIC_MOBILE_VO)` ค่าเริ่มต้น OFF ตาม pattern room-pet) · `__tests__/mobile-vo-feature.test.ts`
- **ผิดจากเอกสาร:**
  - root layout ไม่ re-render ตอน soft navigation → ถ้าใช้ header `x-zyra-pathname` ใน `layout.tsx` ตัดสิน admin/editor ค่าจะค้างเมื่อเปลี่ยนหน้าฝั่ง client ต้องตัดสินใน client component ด้วย `usePathname`
  - "editor" ในเอกสารไม่ระบุ path · path จริงคือ `/workspace/builder/[id]`
- **ขึ้นกับ:** — (ฐานของทุก task ใน Phase 0)

### <a id="t-0-2"></a>0.2 Viewport + safe area (route `/workspace/[id]/play`)
> **ข้อความเดิม (Phase 0):** งาน — Viewport + safe area สำหรับหน้า VO — `viewport-fit=cover`, `user-scalable=no` เฉพาะ route `/workspace/[id]/play`, ใช้ `env(safe-area-inset-*)` ใน HUD container · ไฟล์ที่เอกสารเดิมระบุ — `app/layout.tsx`, `views/user/virtual-office/hero-virtual-office.tsx` · ขึ้นกับ (เดิม) — 0.1 · Done เมื่อ — ไม่มี horizontal scroll · HUD ไม่โดน notch
- **มีอยู่แล้ว (verified):**
  - `app/layout.tsx:85-87` `export const viewport: Viewport = { themeColor: "#2B3540" }` · `:96` `statusBarStyle: "black-translucent"` · `:157` body `min-h-full flex flex-col`
  - `app/workspace/[id]/play/page.tsx:3` `WorkspacePlayPage` — server component render `<HeroVirtualOffice />`
  - `app/workspace/[id]/layout.tsx:1` **เป็น `"use client"`** (export `viewport` ไม่ได้)
  - `hero:487` `HeroVirtualOffice` · `:12180` root `relative h-screen w-full overflow-hidden` · `:13795` HUD wrapper `pointer-events-none absolute inset-0 z-10 flex` (sidebar `:13798`, `VOHud` `:14248`, minimap `:14376`)
  - `vo-error-state.tsx:8`, `vo-loading-skeleton.tsx:8` ใช้ `h-screen`
- **ต้องแก้:**
  - `app/workspace/[id]/play/page.tsx` เพิ่ม `export const viewport = { viewportFit: "cover", maximumScale: 1, userScalable: false, interactiveWidget: … }` และตรวจว่า `themeColor` จาก root ยัง merge มา
  - `hero:12180` `h-screen` → `h-dvh` · `hero:13795` เพิ่ม padding `env(safe-area-inset-*)` (Tailwind v4 arbitrary เช่น `pt-[env(safe-area-inset-top)]` หรือ utility ใน `app/globals.css` ที่มี `@custom-variant` / `@theme` อยู่แล้ว `:61,63`)
  - `vo-error-state.tsx:8`, `vo-loading-skeleton.tsx:8` → `h-dvh`
- **ไฟล์ใหม่:** ไม่มี (อาจเพิ่ม utility `safe-*` ใน `app/globals.css`)
- **ผิดจากเอกสาร:**
  - เอกสารให้แก้ `app/layout.tsx` แต่ viewport ต่อ route ต้องอยู่ที่ `app/workspace/[id]/play/page.tsx` (ใส่ใน `app/workspace/[id]/layout.tsx` ไม่ได้เพราะเป็น client component)
  - ใส่ `viewport-fit=cover` ทั้งแอปใน root จะกระทบทุกหน้า (`black-translucent` ทำให้เนื้อหาซ้อน status bar อยู่แล้ว ตาม TD §15.1 S3)
- **ขึ้นกับ:** 0.1

### <a id="t-0-10"></a>0.10 Playwright mobile viewport
> **ข้อความเดิม (Phase 0):** งาน — Playwright mobile viewport (iPhone 13 preset) — login → enter workspace → joystick เดิน → เข้า zone · Spatial 844×390 + หมุนเป็นแนวตั้งเห็นหน้า Rotate · Lite 390×844 ไม่โหลด engine · ไฟล์ที่เอกสารเดิมระบุ — `e2e/` ของ zyra-app · ขึ้นกับ (เดิม) — 0.3, 0.7, 0.13, 0.14 · Done เมื่อ — ผ่านใน CI ทั้งสองโหมด
- **ไม่มีใน code map รอบนี้** — ที่รู้: `e2e/` ของ zyra-app + `playwright.config.ts:32-36` มีแต่ project desktop (TD §15.6 P11: viewport 1440×1024, Desktop Chrome/Firefox/Safari) · ไม่มี project mobile · 🔍 ไล่โครง e2e ตอนเริ่ม task
- **ไฟล์ใหม่ (ข้อเสนอ):** project `iPhone 13` + project landscape 844×390 ใน `playwright.config.ts` · spec ใหม่ใน `e2e/`
- **ขึ้นกับ:** 0.3, 0.7, 0.13, 0.14

### <a id="t-0-11"></a>0.11 Sentry / Mixpanel tag `platform`
> **ข้อความเดิม (Phase 0):** งาน — Sentry/Mixpanel tag `platform=mobile-web` เพื่อแยก metric · ไฟล์ที่เอกสารเดิมระบุ — `instrumentation-client.ts` / analytics helper · ขึ้นกับ (เดิม) — 0.1 · Done เมื่อ — เห็นใน Sentry/Mixpanel แยก platform
- **มีอยู่แล้ว (verified):**
  - `instrumentation-client.ts:16-35` `Sentry.init({...})` · `:39` `registerDefaultAnalyticsSinks()` (ทำงานก่อน hydrate)
  - `lib/analytics/mixpanel.ts:41` `initMixpanel()` · `:87` `mixpanel.register({ environment: APP_ENV })`
  - `lib/analytics/events.ts:117` `trackAppEvent()` สร้าง payload `:122` (`{...props, path}`) · `lib/analytics/sinks.ts:31` `registerDefaultAnalyticsSinks` (Mixpanel / GTM / GA4 / Sentry breadcrumb)
  - `components/analytics-identity.tsx:16` (`Sentry.setUser`, `identifyUser`) · GTM dataLayer `app/layout.tsx:152` `{ environment: APP_ENV }` (render ฝั่ง server)
  - ทั้ง repo ยังไม่มี `Sentry.setTag`
- **ต้องแก้:**
  - `instrumentation-client.ts` หลัง `Sentry.init` → `Sentry.setTag("platform", getPlatform())` (หรือ `initialScope.tags`)
  - `lib/analytics/mixpanel.ts:87` → `register({ environment, platform })`
  - GA4 / GTM: เติม `platform` ใน payload `events.ts:122` หรือเฉพาะ sink GA `sinks.ts:46`
  - test ที่จะพัง: `__tests__/mixpanel-analytics.test.ts:56` (assert `register` แบบ exact) · `__tests__/analytics-events.test.ts:46-61` (ถ้าเติม platform ลง payload)
- **ไฟล์ใหม่:** ไม่มี · ใช้ `getPlatform(): "web" | "mobile-web" | "app"` จาก `lib/platform.ts` (0.41) เป็นฟังก์ชันล้วน เพราะ `instrumentation-client` ทำงานก่อน React
- **ผิดจากเอกสาร:** ไม่มีไฟล์ "analytics helper" · ไฟล์จริงคือ `lib/analytics/{mixpanel,events,sinks}.ts`
- **ขึ้นกับ:** 0.1, 0.41

### <a id="t-0-12"></a>0.12 Mode setting `zyra_workspace_mode`
> **ข้อความเดิม (Phase 0):** งาน — Mode setting — `zyra_workspace_mode` {mode, scope day/always, expiresAt} helper + `useDeviceOrientation()` จาก `screen.orientation.type` (fallback `matchMedia`) + debounce · guard คีย์บอร์ด Android · vitest · **orientation ตัดสินจากสัดส่วนหน้าต่าง → ดู 0.42 (EC-03)** · ไฟล์ที่เอกสารเดิมระบุ — `lib/platform.ts`, `lib/workspace-mode.ts` (ใหม่) + test · ขึ้นกับ (เดิม) — 0.1 · Done เมื่อ — day หมดอายุถูกต้อง · always ไม่หมดอายุ · หมุนเครื่อง → orientation เปลี่ยนภายใน 200ms · คีย์บอร์ด Android ไม่หลอก
- **มีอยู่แล้ว (verified):** ยังไม่มีอะไร · แบบ helper ที่ใช้อ้างอิง: `lib/patch-note-seen.ts:15-38` (load/save JSON + try/catch + SSR guard), `lib/environment-alerts.ts:14-35`
- **ต้องแก้:** ไม่มี
- **ไฟล์ใหม่:**
  - `lib/workspace-mode.ts` — `type WorkspaceMode = "lite" | "spatial"` · `ModeMemory {mode, scope: "day" | "always", expiresAt?}` · `WORKSPACE_MODE_KEY = "zyra_workspace_mode"` · `loadWorkspaceMode(now = Date.now())` (คืน null เมื่อหมดอายุ / parse ไม่ได้) · `saveWorkspaceMode(mode, scope, now)` (day = now + 24h) · `clearWorkspaceMode()`
  - `__tests__/workspace-mode.test.ts` (env node ส่ง `now` ตรง ๆ)
  - ส่วน orientation ย้ายไปทำใน [0.42](#t-0-42)
- **ผิดจากเอกสาร:**
  - `useDeviceOrientation()` (จาก `screen.orientation.type`) ถูกแทนด้วย `useWindowOrientation()` ใน 0.42 / TD §16.4 แล้ว ไม่ต้องทำทั้งสองตัว
  - hook อยู่ `hooks/` ไม่ใช่ `lib/` (ข้อเท็จจริงร่วมข้อ 5)
  - `clearSession()` (`lib/auth/session.ts:343`) ไม่ล้าง key นี้ — ตรงกับมติ "ต่อเครื่อง"
- **ขึ้นกับ:** 0.1

### <a id="t-0-13"></a>0.13 หน้า Rotate your phone
> **ข้อความเดิม (Phase 0):** งาน — หน้า **Rotate your phone** (ux-ui-plan §3.5) ทับ Spatial เมื่อแนวตั้ง → `setRenderSuspended(true)` (path เดิม `hero-virtual-office.tsx:6262`) กลับมา → resume + resize · ทับ Lite เมื่อแนวนอน · ไฟล์ที่เอกสารเดิมระบุ — `views/user/virtual-office/hero-virtual-office.tsx`, `components/mobile-rotate-screen.tsx` (ใหม่) · ขึ้นกับ (เดิม) — 0.12, 0.2 · Done เมื่อ — หมุนกลางประชุมแล้วหมุนกลับ state ไม่หาย · seat / zone คงเดิม · ไม่มี network event
- **มีอยู่แล้ว (verified):**
  - `hero:6262-6270` effect ของ announcement เรียก `playTestRef.current?.setRenderSuspended?.(covered)` · cleanup `:6267` set `false`
  - `hero:509` `playTestRef` · `:514` `sceneReady` · `:365` `GameCanvas = dynamic(...)` · `:6253` `setInputFrozen`
  - `components/game-canvas/pixi-canvas.tsx:75-76` ส่งต่อ `setRenderSuspended` · `zyra-engine/types.ts:345` `setRenderSuspended?`
  - `scene.ts:3074` `setRenderSuspended()` (render ต่อใน rAF ถัดไป) · `:1605` `resizeTo: this.canvas.parentElement ?? window`
- **ต้องแก้:**
  - `hero:6262-6270` รวมเงื่อนไขใน effect เดียว `covered = activeTab === "announcements" || rotateBlocking` — ถ้าแยก effect cleanup ของ announcement จะ set `false` ทับตอนหน้า Rotate ยังขึ้นอยู่
  - `hero:12180` render `<MobileRotateScreen mode="spatial">` ใต้ root (z สูงกว่า HUD `z-10` และ modal `z-[130]`) · เรียก `setInputFrozen` (`:6253`) ร่วมด้วย
  - ข้อความแปลใน `messages/en.json`, `messages/th.json`
- **ไฟล์ใหม่:** `components/mobile-rotate-screen.tsx` (prop `mode: WorkspaceMode` ใช้ทั้ง Lite / Spatial · ใช้ `useWindowOrientation` 0.42 + `useMobileUi` 0.41) · `__tests__/mobile-rotate-screen.test.tsx`
- **ผิดจากเอกสาร:**
  - เลข `hero:6262`, `scene.ts:3074`, `:1605` ถูกต้อง
  - comment `scene.ts:1595` บอก "ResizeObserver" แต่ Pixi v8 ResizePlugin ฟัง `globalThis.addEventListener("resize")` (`node_modules/pixi.js/lib/app/ResizePlugin.mjs:20`) — หมุนเครื่องแล้วยัง resize ได้ แค่ไม่ใช่กลไกที่ comment อ้าง
- **ขึ้นกับ:** 0.12, 0.42, 0.2 · ส่วน overlay ทับ Lite ขึ้นกับ 0.14

### <a id="t-0-15"></a>0.15 Select workspace mode + sheet Keep This Setting
> **ข้อความเดิม (Phase 0):** งาน — หน้า **Select workspace mode** + sheet **Keep This Setting?** (ux-ui-plan §3.4) แสดงหลังเลือก workspace เมื่อไม่มี mode ที่ยังไม่หมดอายุ · เมนูเปลี่ยนโหมดใน Settings → leave + join ใหม่ · ไฟล์ที่เอกสารเดิมระบุ — `views/user/workspace-enter/select-mode.tsx` (ใหม่), `vo-setting-modal.tsx` · ขึ้นกับ (เดิม) — 0.12 · Done เมื่อ — ตรง Figma ≥ 95% (6392-1128974, 6407-1129791) · Remind me again ถามอีกหลัง 24 ชม. · Always ไม่ถามอีก · ทั้งคู่ localStorage ไม่มี API · เลือก Lite → ข้าม pre-join ไป Connecting เลย
- **มีอยู่แล้ว (verified):**
  - จุดเข้า workspace ทุกทางไป `/workspace/[id]`: `views/user/workspace/hero-user-workspace.tsx:478` (`WorkspaceCard onOpen`) · `views/user/space-builder/components/create-workspace-modal.tsx:232` · `copy-workspace-modal.tsx:103` · `views/user/accept-invite/hero-accept-invite.tsx:238`
  - `/workspace/[id]` = `app/workspace/[id]/page.tsx` → `views/user/workspace-enter/hero-workspace-enter.tsx:36` `HeroWorkspaceEnter` (pre-join) · `handleJoinSpace` (`:279`) เรียก `saveSelectedAvatar` แล้ว `router.push(/loading)` (`:333`)
  - `views/user/workspace-loading/hero-workspace-loading.tsx:84` (Connecting) โหลด `vo-preload` `:179` · `initSession({...})` `:493` (`stores/vo-session-store.ts:50` `VOSessionParams` ต้องมี `avatarUrl`, `characterName`) · `router.replace(/play)` `:575`
  - Settings: `vo-setting-modal.tsx:719` `type SettingTab` (ไม่ได้ export) · `:722` `NAV_ITEMS` · `:481` `GeneralTab` · `:815` `VOSettingModal`
  - ออกจาก session: `stores/vo-session-store.ts:457` `destroySession()` (ลำดับใช้งานดู `hero:4815-4833` `handleLogout`)
  - UI primitive: `components/ui/dialog.tsx` (Radix) เท่านั้น ไม่มี bottom sheet
- **ต้องแก้:**
  - `hero-workspace-enter.tsx`: ถ้า `useMobileUi()` และ `loadWorkspaceMode()` เป็น null → แสดง Select mode ก่อน pre-join · เลือก Lite → ข้าม pre-join ไป `/loading` (ต้องเตรียม avatar / charName ที่ `initSession` ใช้ หรือแก้ใน 0.14 / 0.16b)
  - `vo-setting-modal.tsx` เพิ่มแถว "Workspace mode" (ใน `GeneralTab` หรือ tab ใหม่) → `saveWorkspaceMode` → `destroySession()` → `router.replace(/workspace/[id]/loading)` · บนมือถือ Settings จริงอยู่ Profile tab (0.30)
- **ไฟล์ใหม่:** `views/user/workspace-enter/components/select-mode.tsx` · `views/user/workspace-enter/components/keep-setting-sheet.tsx` · **`components/bottom-sheet.tsx` (ตัวแรกที่สร้าง ใช้ร่วม 0.6, 0.43, 0.44 และทุก sheet — ดูข้อเท็จจริงร่วมข้อ 6)** · helper จาก `lib/workspace-mode.ts` (0.12)
- **ผิดจากเอกสาร:**
  - `views/user/workspace-enter/select-mode.tsx` ผิด convention — component ย่อยอยู่ `views/user/workspace-enter/components/` (เช่น `change-character-modal.tsx`)
  - `vo-setting-modal.tsx` path เต็ม `views/user/virtual-office/components/vo-setting-modal.tsx`
  - หน้า "Connecting" = `/workspace/[id]/loading` (`HeroWorkspaceLoading`)
- **ขึ้นกับ:** 0.12, 0.41, 0.42 · การข้าม pre-join ของ Lite ขึ้นกับ 0.14, 0.16

### <a id="t-0-33"></a>0.33 Smart app banner + PWA install
> **ข้อความเดิม (Phase 0):** งาน — **Smart app banner + PWA install** — sheet "Meet Zyra on mobile" หลัง ~5 วิ (Later / Open Zyra → แอป หรือ App Store / Play Store) · banner โชว์บน landing + zyra-app ในเบราว์เซอร์มือถือ · Later ซ่อน 7 วัน · **PWA install ยังรองรับ (Ten)**: ขึ้นเฉพาะคนที่กด Later แล้ว · Android `beforeinstallprompt` หลัง 2 visits + engagement · iOS คำแนะนำ Add to Home Screen · `manifest.ts orientation` → `any`, `background_color` → `#1A1B1E` · `sw.js` ให้ผ่านเกณฑ์ installable · ไฟล์ที่เอกสารเดิมระบุ — landing page repo (ถ้ายืนยัน), `components/mobile-app-banner.tsx` (ใหม่), `app/manifest.ts` · ขึ้นกับ (เดิม) — 1.3 (deep link), **Figma install prompt (ยังไม่มี)** · Done เมื่อ — กด Open Zyra บนเครื่องที่มีแอป → เปิดแอป · ไม่มีแอป → store ถูก platform · Later ไม่ขึ้นซ้ำตามระยะที่กำหนด · Lighthouse installable ผ่าน · ติดตั้ง PWA แล้วเปิด standalone ได้ทั้งแนวตั้ง/แนวนอน · **เพิ่ม 2026-10-05: Android ใช้ปุ่ม Install ของ Chrome (`beforeinstallprompt`) ใน sheet "Meet Zyra on mobile" แทนขั้นตอน iOS** (ux-ui-plan §21.4 ข้อ 7)
- **มีอยู่แล้ว (verified):**
  - `app/manifest.ts:12` `orientation: "landscape"` · `:13-14` `background_color` / `theme_color: "#2B3540"`
  - `public/sw.js` (passthrough + offline fallback `:25-43`) · `components/pwa-register.tsx` (register เฉพาะ production `:13-14`)
  - ยังไม่มี `beforeinstallprompt` / banner
  - `components/mobile-unsupported-overlay.tsx` mount ที่ `app/layout.tsx:171` (บังทั้งจอบนมือถือ — ต้องจบ 0.1 ก่อน)
  - repo `zyra-landing/` มีอยู่ (🔍 ยังไม่ได้เปิดดูข้างใน)
- **ต้องแก้:** `app/manifest.ts` → `orientation: "any"`, `background_color: "#1A1B1E"` (ทับซ้อน 1.2)
- **ไฟล์ใหม่:** `components/mobile-app-banner.tsx`
- **ผิดจากเอกสาร:** ช่อง "ขึ้นกับ 1.3 (deep link)" ผิด — deep link คือ **1.9** (1.3 คือ reCAPTCHA / email login)
- **ขึ้นกับ:** 0.1, 1.9, Figma install prompt

### <a id="t-0-41"></a>0.41 Device class `useMobileUi()` (EC-03)
> **ข้อความเดิม (Phase 0):** งาน — **Device class (EC-03)** — `useMobileUi()` ใน `lib/platform.ts`: app = true เสมอ · เว็บ = (`pointer: coarse` หรือ `maxTouchPoints > 1`) และด้านยาว ≤ 1366 · แทนเงื่อนไข `max-md` ของ overlay · iPad + trackpad = มือถือ (technical-design §16.8) · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `lib/platform.ts`, `components/mobile-unsupported-overlay.tsx`, `app/layout.tsx` · ขึ้นกับ (เดิม) — 0.1 · Done เมื่อ — iPad mini / iPad Pro / Galaxy Tab ได้หน้า Select mode · laptop จอสัมผัส > 1366 ได้ desktop
- **มีอยู่แล้ว (verified):** `components/mobile-unsupported-overlay.tsx:9` (`max-md:flex`) เท่านั้น
- **ต้องแก้:** overlay เปลี่ยนเงื่อนไข `max-md` → `useMobileUi()` (ต่อจาก 0.1) ใช้ `useSyncExternalStore` + `getServerSnapshot` กัน hydration mismatch · `app/layout.tsx` ไม่ต้องแก้ถ้า overlay เป็น client component
- **ไฟล์ใหม่:**
  - `lib/platform.ts` (ฟังก์ชันล้วน SSR-safe): `isNativeApp()` = `window.Capacitor?.isNativePlatform?.()` (ห้าม import `@capacitor/core` จนกว่า 1.1) · `isIOS()` / `isAndroid()` · `detectMobileUi()` = (coarse หรือ `maxTouchPoints > 1`) และ `max(screen.w, screen.h) <= 1366` · `getPlatform()`
  - `hooks/use-mobile-ui.ts` (`useMobileUi`, `useTabletScale` คำนวณใหม่ตอน resize)
  - `__tests__/platform.test.ts`
  - ทางเลือก: set `data-mobile-ui` บน `<html>` แล้วทำ `@custom-variant` ใน `globals.css` ให้ Tailwind ใช้ได้
- **ผิดจากเอกสาร:** hook ไม่อยู่ `lib/platform.ts` (convention) นอกนั้นตรง
- **ขึ้นกับ:** 0.1

### <a id="t-0-42"></a>0.42 `useWindowOrientation()` จากสัดส่วนหน้าต่าง
> **ข้อความเดิม (Phase 0):** งาน — **Orientation จากสัดส่วนหน้าต่าง** — `useWindowOrientation()` (`innerWidth < innerHeight`) แทน `screen.orientation` · ไม่คำนวณใหม่ตอนคีย์บอร์ดเปิด · ใช้กับหน้า Rotate + Lite/Spatial (TD §16.4) · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `lib/platform.ts` · ขึ้นกับ (เดิม) — 0.12 · Done เมื่อ — iPad Split View ครึ่งจอ = แนวตั้ง · เปิดคีย์บอร์ด Android ไม่เด้งหน้า Rotate
- **มีอยู่แล้ว (verified):** ไม่มี (`visualViewport`, `orientationchange` = 0 จุด) · pattern ฟัง resize: `vo-draggable.tsx:217,267`
- **ต้องแก้:** ไม่มี
- **ไฟล์ใหม่:**
  - logic ล้วนใน `lib/platform.ts`: `orientationFromWindow(w, h)` · `isKeyboardLikelyOpen(vv, activeEl)` (visualViewport สูงลด + มี input / textarea / contenteditable โฟกัส)
  - `hooks/use-window-orientation.ts` (ฟัง `resize` + `screen.orientation` `change`, debounce 150ms, SSR คืน null = ไม่แสดงหน้า Rotate)
  - test ใน `__tests__/platform.test.ts` + `__tests__/use-window-orientation.test.tsx` (jsdom + fake timers)
- **ผิดจากเอกสาร:** ทาง Capacitor `keyboardWillShow` ยังใช้ไม่ได้ (ยังไม่ติดตั้ง) → ใช้ fallback `visualViewport` ไปก่อน เพิ่มทาง Capacitor ใน 1.10
- **ขึ้นกับ:** 0.12 (แทนส่วน orientation ของ 0.12)

### <a id="t-0-43"></a>0.43 Tablet scale (ด้านสั้น ≥ 744)
> **ข้อความเดิม (Phase 0):** งาน — **Tablet scale** — ด้านสั้นหน้าต่าง ≥ 744 → ขอบ 24 · ปุ่มกลม Spatial 5 ปุ่ม + Chat = 44 (icon 16) · ต่ำกว่า → 16 / 32 · layout fluid ไม่มี max-width · bottom sheet กว้างสุด 600 กลางจอ (ux-ui-plan §17.2–17.3, §17.6) · ไฟล์ที่เอกสารเดิมระบุ — zyra-app Lite Home, Spatial HUD, bottom sheet · ขึ้นกับ (เดิม) — 0.14, 0.41 · Done เมื่อ — ตรง Figma 744×1133 / 1024×1366 / 1133×744 / 1399×1024
- **มีอยู่แล้ว (verified):** Spatial HUD ยังเป็นแบบ desktop — `vo-hud.tsx` (491 บรรทัด, `HudControl` `:289,309`) · `components/hud-control.tsx:26` · `vo-sidebar.tsx` · `vo-minimap.tsx` · ยังไม่มี Lite Home / ปุ่มกลม 5 ปุ่ม / bottom sheet
- **ต้องแก้:** component ที่ 0.5 / 0.14 สร้าง รับขนาดจาก `useTabletScale()` (ขอบ 24/16, ปุ่ม 44/32, icon 16) · ใช้ `components/bottom-sheet.tsx` (0.15) ใส่ `max-w-[600px] mx-auto`
- **ไฟล์ใหม่:** ไม่มี — แค่ `useTabletScale` ใน `hooks/use-mobile-ui.ts` (0.41) · อาจเพิ่ม token `--mobile-gutter` ใน `app/globals.css` `@theme`
- **ผิดจากเอกสาร:** "Lite Home, Spatial HUD, bottom sheet" ยังไม่มีในโค้ด → เริ่มทำจริงได้หลัง 0.5 / 0.14
- **ขึ้นกับ:** 0.14, 0.41 (ในทางปฏิบัติ 0.5)

### <a id="t-0-44"></a>0.44 Small phone ≤ 375
> **ข้อความเดิม (Phase 0):** งาน — **Small phone ≤ 375** — layout 390 ขอบ 16 · ellipsis ตามจุด (ปุ่มคู่ ชื่อ workspace/สมาชิก/ห้อง) · modal `max-h-[90dvh]` scroll · `scrollIntoView` ตอนคีย์บอร์ดขึ้น · Spatial 667×375 HUD ไม่ทับกัน · ไฟล์ที่เอกสารเดิมระบุ — zyra-app ทุกหน้ามือถือ · ขึ้นกับ (เดิม) — 0.14 · Done เมื่อ — ไม่มี horizontal overflow บน 320 / 375×667 / 667×375
- **มีอยู่แล้ว (verified) — จุดที่จะล้นจอ:**
  - modal ใช้ 100vh: `vo-setting-modal.tsx:911` (`max-h-[calc(100vh-32px)] w-[934px]`), `vo-pet-panel.tsx:115`, `vo-weather-panel.tsx:85` · `dvh` มีแค่ใน admin (`views/admin/roadmap-scene/components/upload-object-modal.tsx:183`, `views/admin/pet-management/components/pet-preview-modal.tsx:513`)
  - toast: `lib/toast.tsx:112` `w-[336px]` · `views/verify/hero-verify.tsx:64` `w-[336px]` · `app/layout.tsx:170` `<Toaster position="top-right" />`
  - modal กว้างตายตัว: `create-workspace-modal.tsx:271` `w-[900px]`, `:385` `w-[458px]` · `views/user/workspace/components/join-workspace-modal.tsx:50` `w-[480px]`
  - ไฟล์ใน `views/user` + `components` ที่มี `fixed inset-0`: 36 ไฟล์ · ยังไม่มี `scrollIntoView` ตอนคีย์บอร์ดขึ้น
- **ต้องแก้:** modal `100vh` → `max-h-[90dvh] overflow-y-auto` (เฉพาะ path มือถือ) · toast → `w-[min(336px,calc(100vw-32px))]` · `truncate` / `min-w-0` ที่ชื่อ workspace / สมาชิก / ห้อง · handler `focusin` → `scrollIntoView` (เขียนครั้งเดียวใช้ร่วม)
- **ไฟล์ใหม่:** `hooks/use-keyboard-scroll-into-view.ts` (ไม่บังคับ — ใช้ `isKeyboardLikelyOpen` จาก 0.42)
- **ผิดจากเอกสาร:** TD §15.1 S6 อ้าง Toaster `app/layout.tsx:172` → จริง **`:170`** (S1 `:171` ถูก)
- **ขึ้นกับ:** 0.14 (และหน้ามือถือทุกหน้าใน 0.5–0.32)

### <a id="t-0-46"></a>0.46 หน้าก่อนเข้า workspace บน tablet แนวนอน
> **ข้อความเดิม (Phase 0):** งาน — **หน้าก่อนเข้า workspace บน tablet แนวนอน** — splash / slide / login / Space builder / Create workspace / Select mode แสดงคอลัมน์ layout แนวตั้งกลางจอ (ไม่ lock · กว้าง ~480 🔍 design ยืนยัน) · ไฟล์ที่เอกสารเดิมระบุ — zyra-app views ของ HP-07 · ขึ้นกับ (เดิม) — 0.31, 0.32, 0.41 · Done เมื่อ — iPad แนวนอน + Split View ใช้ได้ไม่ต้องหมุน
- **มีอยู่แล้ว (verified) — root container ของแต่ละหน้า:** login `views/login/hero-login.tsx:37` (`min-h-screen … px-4`) · signup `views/signup/hero-signup.tsx:244` · Space builder `views/user/workspace/hero-user-workspace.tsx:297` + `:301` (`h-[calc(100vh-72px-32px)] min-h-[600px]`, grid `:471` `sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4`) · welcome `views/user/space-builder/hero-welcome-space.tsx:59,79` · Create workspace `create-workspace-modal.tsx:271` · pre-join `hero-workspace-enter.tsx:347` (`h-screen`) · navbar `components/app-navbar.tsx:87` (`sticky h-[72px]`)
- **ต้องแก้:** ทุก root ข้างบน เมื่อ `useMobileUi()` + แนวนอน ครอบด้วยคอลัมน์ `mx-auto w-full max-w-[480px]` และบังคับ layout แนวตั้ง (grid ของ hero-user-workspace เป็น 1 คอลัมน์) — **ยกเว้นหน้ารายการที่มติ iPad 2026-10-05 (ux-ui-plan §17 ข้อ 7) ให้เต็มจอ:** Space builder 2 คอลัมน์ · template 3/4 คอลัมน์ · หน้าฟอร์มคงคอลัมน์ 480
- **ไฟล์ใหม่:** `components/mobile-portrait-column.tsx` (wrapper ใช้ทุกหน้า HP-07 · ใช้ `useMobileUi` + `useWindowOrientation`)
- **ผิดจากเอกสาร:** "splash / slide" ไม่มีใน zyra-app — splash เป็นของ native (1.2) · slide (onboarding 3 หน้า) ยังไม่มี view · `views/home/hero-home.tsx:22` ไม่มีใคร import (dead code) · Select mode เป็นไฟล์ใหม่ของ 0.15
- **ขึ้นกับ:** 0.31, 0.32, 0.41 (+ 0.15, 0.42)

### <a id="t-3-1"></a>3.1 วัด crash-free / FPS / session แยก platform
> **ข้อความเดิม (Phase 3):** งาน — วัด crash-free / FPS / session length จาก Sentry + Mixpanel แยก platform 2 สัปดาห์แรก · หมายเหตุ — ตัดสินใจ Plan B จากตัวเลขนี้
- **มีอยู่แล้ว (verified):** `instrumentation-client.ts:17-35` `Sentry.init` (ไม่มี tag platform, replay 10%) · `lib/analytics/mixpanel.ts:41-92`, `:87` `register({ environment })` · `registerDefaultAnalyticsSinks` (`lib/analytics/sinks.ts`)
- **ต้องแก้:** ทับซ้อน 0.11 (tag platform) — ถ้า 0.11 เสร็จแล้ว เหลือสร้าง dashboard
- **ไฟล์ใหม่:** (ไม่บังคับ) `@sentry/capacitor` ใน zyra-mobile สำหรับ native crash
- **ขึ้นกับ:** 0.11, 1.13

---

## <a id="mod-b"></a>B. Engine & Spatial HUD

`zyra-app/zyra-engine/pixi-game/*` (ไม่มี repo แยก) · `components/game-canvas/pixi-canvas.tsx` · `views/user/virtual-office/components/vo-*`

### <a id="t-0-3"></a>0.3 Virtual joystick
> **ข้อความเดิม (Phase 0):** งาน — Virtual joystick component (**128×140 ซ้ายล่าง ตาม Figma** ux-ui-plan §3.9) + ส่ง `{dx,dy}` เข้า scene ผ่าน `pixi-canvas.tsx` ref · map เข้า V2 `input` intent / legacy `move_to` · ไฟล์ที่เอกสารเดิมระบุ — `views/user/virtual-office/components/vo-joystick.tsx` (ใหม่), `components/game-canvas/pixi-canvas.tsx`, `zyra-engine/pixi-game/scene.ts`, `zyra-engine/constants.ts` · ขึ้นกับ (เดิม) — 0.1 · Done เมื่อ — เดินได้ 8 ทิศบน Safari iOS + Chrome Android
- **มีอยู่แล้ว (verified):**
  - `scene.ts` `MOVE_KEY_CODES` `:1125-1134` · `pressedKeys` (Set) `:1181` · `_mountInput()` `:2383` → `onKeyDown` `:2384` (ลุกจากที่นั่ง `:2407-2421`, ตัดการเดินหาเส้นทาง `:2440`, Space `:2443`, Escape `:2444`) · `onKeyUp` `:2457` (นั่งเมื่อปล่อยปุ่ม)
  - `_updateMovement` `:3398` อ่านปุ่มค้าง `:3405-3408`, หาทิศ `:3676-3679` · `_tickOverlapTimer` อ่านปุ่ม `:8350-8357`
  - **`_heldWasdDir()` `:10334` ได้ 4 ทิศเท่านั้น** ("X wins over Y") · `_emitInputChanged()` `:10344` อ่าน Shift / `_autoRun` เป็นวิ่ง
  - `setOnInputChanged` `:9926` · `releaseMovementKeys()` `:9940` · `setAutoRun` `:9620` · `_triggerSitRise` `:7596`
  - `pixi-canvas.tsx` ส่งต่อ `setOnInputChanged` `:132`, `releaseMovementKeys` `:138` · ตั้ง `touchAction:"none"` บน canvas `:384` · type `PlayTestHandle` `zyra-engine/types.ts:323`
  - `hero:5686` ส่ง `client.input({dx,dy,run,sitting,tile_x,tile_y})` + keepalive `:5701` · `workspace-ws.ts` `input()` `:552`, `goto()` `:558`
  - server `zyra-ws/internal/hub/movement_v2.go:122` `handleInput` รับ dx/dy 8 ทิศ (comment `client.go:218`) ตัด input เก่าหลัง 600ms (`inputStaleAfter` `:23`)
- **ต้องแก้:**
  - `scene.ts` เพิ่ม `setVirtualInput(dx, dy, run?)` เก็บ field ใหม่ รวมเข้า `_heldWasdDir`, `_updateMovement`, `:8350` · ต้องมีผลข้างเคียงเหมือน `onKeyDown`: ตัด path, ลุกจากที่นั่ง, callback ตอน follow (`blockWalk`), เคารพ `_inputFrozen`
  - `zyra-engine/types.ts` เพิ่ม method optional ใน `PlayTestHandle` · `pixi-canvas.tsx` เปิด method ผ่าน `useImperativeHandle`
  - `zyra-engine/constants.ts` เพิ่ม `JOYSTICK_DEADZONE`, `JOYSTICK_RUN_RADIUS` ฯลฯ · hero mount joystick ซ้ายล่าง
- **ไฟล์ใหม่:** `views/user/virtual-office/components/vo-joystick.tsx` · test ใน `__tests__/` (ต่อจาก `__tests__/pixi-game-scene.test.ts` 8.5k บรรทัด describe `setOnInputChanged` `:1682`)
- **ผิดจากเอกสาร:**
  - "legacy `move_to`" ไม่มีใช้แล้ว (ข้อเท็จจริงร่วมข้อ 4)
  - **"เดินได้ 8 ทิศ" ทำไม่ได้กับ engine ตอนนี้** — client ตัดเหลือ 4 ทิศ (`:10341`, `:3678`) · ต้องการ 8 ทิศต้องแก้ prediction + reconcile ฝั่ง server (เสี่ยง desync — ดู skill `vo-desync-debug`) ไม่งั้น joystick ต้องเหลือ 4 ทิศ → **ต้องตัดสินก่อนเริ่ม**
  - TD §7 "touchstart ~L1421" → handler `:2867` listener `:2958` · "pointer ~L2946" → `:2946` คือ listener keydown · pointer handler `:2831-2858` listener `:2955-2957`
- **ขึ้นกับ:** 0.1, 0.41

### <a id="t-0-4"></a>0.4 Tap-to-walk แยกจาก pan / pinch
> **ข้อความเดิม (Phase 0):** งาน — Tap-to-walk แยกจาก pan/pinch ด้วย threshold — ใช้ click-to-walk path เดิม · ไฟล์ที่เอกสารเดิมระบุ — `zyra-engine/pixi-game/scene.ts`, `zyra-engine/constants.ts` · ขึ้นกับ (เดิม) — 0.3 · Done เมื่อ — แตะพื้น = เดิน · ลาก = pan · สองนิ้ว = zoom ไม่ชนกัน
- **มีอยู่แล้ว (verified):**
  - `scene.ts` `onClick` `:2506` เดินแบบ **2 คลิก**: คลิกแรกเลือก tile (`:2732`) คลิกซ้ำที่เดิมค่อยเดิน (`:2619`) ผ่าน `_pathToNearestReachable` `:8094` · click หลังลากถูกกลืน `:2508-2511` แล้วเรียก `onCameraDragClick`
  - `onPointerDown/Move/Up` `:2831` / `:2841` / `:2856` แยก pan ด้วย **ระยะ 4px** (`:2845`) ไม่ติดตาม pointerId (`:2874`)
  - pinch: `onTouchStart` `:2867` (2 นิ้วพอดี) · `onTouchMove` `:2883` · `onTouchEnd` `:2904` · `gestureTargetIsMap` `:2773` · `onMouseMove` `:2819` = hover (touch ไม่ทำงาน)
  - `zyra-engine/constants.ts` `PINCH_ZOOM_SENSITIVITY` `:132`, `CAMERA_ZOOM_MIN` `:30`, `CAMERA_ZOOM_MAX` `:40`
  - test: `pinch-to-zoom (touch)` `__tests__/pixi-game-scene.test.ts:645` · click-walk `:442`, `:1873`
- **ต้องแก้:** บน coarse pointer แตะครั้งเดียวเดินเลย (ข้ามการเลือก tile) หรือ double-tap ตามที่ design ตัดสิน · threshold เวลา ≤ 200ms + ติดตาม pointerId · กลืน click หลังจบ pinch · ย้ายเลข 4 ที่ `:2845` เป็น `TAP_MAX_MOVE_PX` / `TAP_MAX_MS` ใน `zyra-engine/constants.ts`
- **ไฟล์ใหม่:** ไม่มี
- **ผิดจากเอกสาร:** TD §14.3 C3 "ยังไม่แยก threshold" — มีระยะ 4px แล้ว ขาดแค่เงื่อนไขเวลา
- **ขึ้นกับ:** 0.3

### <a id="t-0-5"></a>0.5 Responsive HUD ชุด 1
> **ข้อความเดิม (Phase 0):** งาน — Responsive HUD ชุดที่ 1 — bottom toolbar, sidebar, status picker, minimap ตาม Figma mobile · ไฟล์ที่เอกสารเดิมระบุ — `views/user/virtual-office/components/vo-hud.tsx`, `vo-sidebar.tsx`, `vo-status-picker.tsx`, `vo-minimap.tsx` · ขึ้นกับ (เดิม) — **Figma mobile design** · Done เมื่อ — ตรง Figma ≥ 95% · ต้องดึง spec ผ่าน Figma MCP ก่อน
- **มีอยู่แล้ว (verified):**
  - `vo-hud.tsx` (`VOHud` `:120`, 491 บรรทัด) ปุ่ม spotlight `:448-472`, ปุ่มลัด B `:191-206` · `vo-sidebar.tsx` (`VOSidebar` `:52`, rail `w-[56px]`) · `vo-minimap.tsx` (`VOMinimap` `:537`, ย่อ 169×100 / ขยาย 400×236 fix ขนาด)
  - `components/hud-control.tsx` (ปุ่ม mic/cam ใช้ร่วม) · `vo-hud-tooltip.tsx:40` (`hidden group-hover:flex`)
  - จุด mount: `hero:13795` container `absolute inset-0 z-10 flex` · `VOSidebar` `:13798` · `VOHud` `:14248` · `VOMinimap` `:14376` (ใน placeholder `w-[169px]` `:14373`)
  - ทุกไฟล์ข้างบน (รวม member / notification / follow / zone-enter-panel) **ไม่มี** `md:`, `sm:`, `max-md`, `dvh`, `safe-area`
- **ต้องแก้:** layout มือถือ 4 ไฟล์ตาม Figma · hover tooltip ใช้ได้บน `(hover:none)`
- **ไฟล์ใหม่:** ปุ่มกลม 5 ปุ่มขวาบน + ปุ่ม chat ซ้ายล่าง (ux-ui-plan §3.9) เช่น `vo-mobile-hud.tsx` · ปุ่ม megaphone อยู่ในชุดนี้ (ใช้โดย 0.49)
- **ผิดจากเอกสาร:** `vo-status-picker.tsx` มีไฟล์ (`VOStatusPicker` `:29`) แต่ **ไม่ถูก mount ที่ไหน** · UI เปลี่ยนสถานะจริงอยู่ `vo-profile-panel.tsx` (`VOProfilePanel` `:137`) และ `vo-outside-display.tsx` ผ่าน `onStatusChange`
- **ขึ้นกับ:** Figma mobile, 0.2, 0.41

### <a id="t-0-6"></a>0.6 Responsive HUD ชุด 2 (bottom sheet)
> **ข้อความเดิม (Phase 0):** งาน — Responsive HUD ชุดที่ 2 — member panel, chat panel, notification panel เป็น bottom sheet · ไฟล์ที่เอกสารเดิมระบุ — `vo-member-panel.tsx`, chat panels, `vo-notification-panel.tsx` · ขึ้นกับ (เดิม) — 0.5 · Done เมื่อ — เปิด/ปิดได้ · keyboard ไม่บัง input
- **มีอยู่แล้ว (verified):**
  - `vo-member-panel.tsx` (`VOMemberPanel` `:423`, `w-[320px]`) mount `hero:13871` · `vo-notification-panel.tsx` (`VONotificationPanel` `:112`, `w-[320px]`) mount `hero:13959`
  - chat = `views/chat/chat-surface.tsx` (`ChatSurface` 383 บรรทัด, dynamic import `hero:381`, mount `:14045` / `:14058`) + `views/chat/components/*`
  - primitive: `components/ui/dialog.tsx` เท่านั้น · ไม่มี `visualViewport` ที่ไหน
- **ต้องแก้:** 3 panel แสดงเป็น sheet บนมือถือ · ย้ายตำแหน่ง side panel ใน hero (`absolute inset-y-0 left-[56px]`)
- **ไฟล์ใหม่:** ใช้ `components/bottom-sheet.tsx` (สร้างใน 0.15) · `hooks/use-visual-viewport.ts` (คีย์บอร์ด)
- **ผิดจากเอกสาร:** "chat panels" ไม่ได้อยู่ใน `views/user/virtual-office` แต่อยู่ `views/chat/` (งานแชทเต็มอยู่ module E)
- **ขึ้นกับ:** 0.5, 0.15

### <a id="t-0-7"></a>0.7 Responsive HUD ชุด 3
> **ข้อความเดิม (Phase 0):** งาน — Responsive HUD ชุดที่ 3 — meeting bar, zone enter modal, wave/knock toast, follow bar · ไฟล์ที่เอกสารเดิมระบุ — ไฟล์ที่เกี่ยวใน `views/user/virtual-office/components/` · ขึ้นกับ (เดิม) — 0.5 · Done เมื่อ — เข้า zone + ประชุมได้ครบบนมือถือ
- **มีอยู่แล้ว (verified):**
  - meeting bar = `MeetingToolbar` `zone-enter-header.tsx:270` (+ `PanelHeader` `:99`)
  - zone enter modal = `ZoneEnterPanel` `zone-enter-panel.tsx:45` (mount `hero:14583`, `:14709`) · `ZoneLockedOverlay` `zone-locked-overlay.tsx:31` (`hero:12495`)
  - wave toast `VOWaveNotification` `vo-wave-notification.tsx:31` (`w-[300px]`, `hero:13192`) · knock toast `VOKnockNotification` `vo-knock-notification.tsx:41` (`w-[322px]`, `hero:13211`)
  - follow bar `VOFollowBar` / `VOPetWalkBar` / `VOBeingFollowedBar` `vo-follow-bar.tsx:13/44/74` (`w-[322px]`, `hero:14161`)
  - tile `zone-enter-tiles.tsx` (`CompactDisplayCard` `:251`, `ExpandedDisplayCard` `:520`) · `RoomEntryPopup` `vo-room-entry-popup.tsx`
- **ต้องแก้:** ไฟล์ข้างบน เปลี่ยนความกว้างตายตัว + hover → แตะ · layout meeting เต็ม ๆ อยู่ 0.17
- **ไฟล์ใหม่:** ไม่มี
- **ผิดจากเอกสาร:** —
- **ขึ้นกับ:** 0.5, 0.6

### <a id="t-0-9"></a>0.9 Performance profile + tuning
> **ข้อความเดิม (Phase 0):** งาน — Performance profile + tuning บน mobile — resolution, filters, nature/pet fallback, culling · บันทึก FPS/memory before/after · ไฟล์ที่เอกสารเดิมระบุ — `zyra-engine/pixi-game/scene.ts`, `constants.ts`, `components/game-canvas/pixi-canvas.tsx` · ขึ้นกับ (เดิม) — 0.3 · Done เมื่อ — FPS ≥ 30 / memory < 400 MB บน iPhone 12 + Pixel 6a ในแมพ 20 คน — ตัวเลขใน progress.md | · **มือถือ: ladder 5 ระดับตาม EP-01 → task 0.38**
- **มีอยู่แล้ว (verified):**
  - `scene.ts` `init()` `:1559` · `app.init` `:1598-1606` `resolution: devicePixelRatio` `:1603` (ไม่ cap), `antialias:false`, ไม่มี `powerPreference`, `resizeTo` `:1605`
  - `app.ticker.stop()` `:1614` แล้วใช้ rAF ของตัวเอง `_tick` `:3086` (cap ~60fps `:3096`) · `_step` `:2989` นับ FPS `:3047-3052` · `getFPS()` `:3057` · Worker ticker 100ms `:3104` · `_handleResumeFromBackground` `:3155` · `destroy()` `:11163`
  - `NAME_TAG_RESOLUTION` = DPR × 3 `zyra-engine/pixi-game/constants.ts:144` (ใช้ `scene.ts:842`) · `ENV_FX_SPRITE_BUDGET = 560` `scene.ts:289`
  - culling มีแค่ต้นไม้ (`nature-layer.ts:330-334`) · ไม่มี `cullable`, `Culler`, `powerPreference`, `webglcontextlost` · `pixi-filters` ใน `package.json` แต่ไม่มีใคร import
  - `vo-stats-overlay.tsx` (`StatsSnapshot` มี fps/ping ไม่มี memory) hero ดึงค่า `:1734-1745`
  - `pixi-canvas.tsx:365-372` เรียก `init()` ไม่ await ไม่มี guard ตอน cancel (race G7)
- **ต้องแก้:** `scene.ts` cap `resolution` บนมือถือ + ตั้ง `powerPreference` · `pixi-game/constants.ts` cap `NAME_TAG_RESOLUTION` (คำนวณครั้งเดียวตอนโหลด module ถ้าจะเปลี่ยนตอนรันต้อง refactor) · `vo-stats-overlay.tsx` เพิ่ม memory · `pixi-canvas.tsx` guard ตอน cancel init
- **ไฟล์ใหม่:** ไม่มี (ตัวเลข before/after ลง progress.md ตาม rule 18)
- **ผิดจากเอกสาร:** task ระบุ `pixi-canvas.tsx` เรื่อง resolution — resolution ตั้งใน `scene.ts:1603`
- **ขึ้นกับ:** 0.3

### <a id="t-0-16c"></a>0.16c hero: วาด ghost บนแมพ (Spatial / desktop)
เนื้อหาเต็มอยู่ [0.16 ใน module G](#t-0-16) · ส่วนของ module นี้: `hero:3958` (effect `setRemotePlayers`) ไม่ส่ง ghost เข้า scene จนกว่าได้ `ghost_join_zone` แล้ว replay path spawn → ห้องด้วย `walkToTile` / pathfinding เดิม · `hero:10223` `getZoneParticipants` นับ ghost ตาม zone id ไม่ใช่พิกัด · `hero:890` (`!p.floor_id || …`) ต้องไม่วาด ghost ที่ไม่มี floor

### <a id="t-0-38"></a>0.38 Performance ladder (EP-01)
> **ข้อความเดิม (Phase 0):** งาน — **Performance ladder มือถือ (EP-01)** — เฉพาะ Spatial บนมือถือ · FPS sample ทุก 5 วิ · L1 < 25 → `resolution` DPR → 1 (ไม่มี toast) · L2 < 21 → ปิด nature + weather · L3 < 15 → avatar `animationSpeed` 12→6 fps + ปิด Time of Day overlay · L4 (ยัง < 15 อีก 10 วิ) → simple mode = minimap เต็มจอ + avatar cluster · ลดทีละขั้น 10 วิ · กลับเองทีละขั้น (> 45 นาน 30 วิ) + toast · toast ปิดเอง 10 วิ ข้อความตาม Figma · ไฟล์ที่เอกสารเดิมระบุ — `lib/nature-performance.ts` (ขยายเป็นหลายระดับ), `use-nature-performance.ts`, `zyra-engine/pixi-game/scene.ts`, `use-environment.ts`, `vo-minimap*` · ขึ้นกับ (เดิม) — 0.9, 0.36 · Done เมื่อ — วัด FPS ก่อน/หลังบน Android ต่ำ (rule 18) · simple mode เดิน/เข้าห้องได้ · desktop ไม่เปลี่ยน
- **มีอยู่แล้ว (verified):**
  - `lib/nature-performance.ts` (71 บรรทัด) state ระดับเดียว (`PerfState.degraded`) · `PERF_SAMPLE_MS` 5000, `LOW_FPS` 30 × `LOW_SAMPLES` 2, `RECOVER_FPS` 45 × `RECOVER_SAMPLES` 6 · `samplePerf()`, `restorePerf()`
  - `views/user/virtual-office/use-nature-performance.ts` (154) `useNaturePerformance()` คืน `frozen` · degrade → ปิด switch weather / `setSuppressWeather` · **ขาขึ้นเป็น toast ให้กดเอง** (Keep off / Turn on) ไม่คืนอัตโนมัติ
  - hero: `useNaturePerformance` `:1629-1642` · `weatherFxOn` `:1111-1112` · effect ToD tint `:1436-1470` (`setEnvironmentTint`, `shouldRenderStageTint` `lib/environment-tint.ts:70`) · effect weather `:1482+` (`buildEnvironmentLayer` `lib/environment-layer.ts:128`)
  - `scene.ts` `setEnvironmentTint` `:5055` · `setNaturePerformanceMode` `:5082` (→ `NatureLayer.setPerformanceMode` `nature-layer.ts:277`) · `setEnvironmentWeather` `:5116` · `_drawEnvironmentTint` `:5872`
  - animation avatar: `_updateAnimation` `:4022` นับ frame เอง walkFps = max(`WALK_FPS`=8, 4 × speed ÷ 32) = 15fps เดิน / 45fps วิ่ง · คนอื่น `scene-remote-movement.ts:358-372`
  - minimap: `groupPlayersByZone` `vo-minimap.tsx:76` (รวมกลุ่มเฉพาะ meeting zone) · **minimap ไม่มี click-to-walk** · compact avatar ตอนซูมไกลมีแล้ว (`FAR_ZOOM_COMPACT_AVATAR_THRESHOLD` `zyra-engine/constants.ts:168`)
  - test: `__tests__/nature-performance.test.ts`, `use-nature-performance.test.tsx`, `vo-minimap-grouping.test.tsx`
- **ต้องแก้:** `lib/nature-performance.ts` ขยายเป็น L0–L4 ลดทีละขั้นทุก 10 วิ คืนอัตโนมัติ (> 45 นาน 30 วิ ต่อขั้น) · hook: toast เสนอ → toast แจ้งปิดเองใน 10 วิ · `scene.ts` setter resolution ตอนรัน (`app.renderer.resolution`) สำหรับ L1 + ตัวคูณอัตรา walk-frame สำหรับ L3 (ตัวเรา + คนอื่น) · `hero:1436` บังคับ alpha ToD tint = 0 ที่ L3 · L4: `setRenderSuspended(true)` + minimap เต็มจอ
- **ไฟล์ใหม่:** `vo-simple-map.tsx` (minimap เต็มจอ + แตะเรียก `walkToTile` + รวมกลุ่ม avatar) · ข้อความ i18n `messages/en.json` / `th.json` namespace `VirtualOffice`
- **ผิดจากเอกสาร:**
  - "avatar `animationSpeed` 12→6 fps" ไม่ตรงโค้ด — avatar ไม่ใช้ `animationSpeed` (มีแค่ GifSprite ของ weather `:5300` และ marker) · อัตราจริง 15fps ตอนเดิน → L3 = ลดครึ่งของอัตราจริง
  - `use-environment.ts` (`useEnvironment` `:108`) เป็นแค่ hook ดึง snapshot · ปิด ToD ต้องทำที่ effect `hero:1436` หรือ engine
  - `vo-minimap*` = `vo-minimap.tsx` + `vo-pip-minimap.tsx` (canvas ของ PiP)
  - DPR "2→1" — iPhone เป็น DPR 3
- **ขึ้นกับ:** 0.9, 0.36 (ช่อง toast), 0.41

### <a id="t-0-39"></a>0.39 ~~เมนู Performance~~ — ตัดออก
> **ข้อความเดิม (Phase 0):** งาน — ~~เมนู Performance ใน Profile → Setting (Spatial เท่านั้น) — Auto / Performance mode (ล็อก L3) / Full effects (ปิด fallback) · จำใน localStorage `zyra_perf_mode`~~ **ตัดออก 2026-10-02 (โน้ต Pai + Ten) — ปรับเองอย่างเดียว ux-ui-plan §19.8** · ไฟล์ที่เอกสารเดิมระบุ — `lite/profile-tab.tsx`, หน้าย่อยใหม่ · ขึ้นกับ (เดิม) — 0.30, 0.38, **Figma (ยังไม่มี — ข้อเสนอ ux-ui-plan §15.7)** · Done เมื่อ — เปลี่ยนค่าแล้วมีผลทันทีโดยไม่ reload แมพ
- **ไม่มีงานโค้ด** — ตัดออก 2026-10-02 (โน้ต Pai + Ten · ux-ui-plan §19.8) ladder 0.38 ปรับเองอย่างเดียว · ผลต่อ task อื่น: 1.15 ต้องเปลี่ยนข้อความ toast ไม่ให้แนะนำ Performance mode

### <a id="t-0-49"></a>0.49 Megaphone เดินไป Spotlight เอง
> **ข้อความเดิม (Phase 0):** งาน — **Spatial megaphone → Spotlight** — auto-walk ไป marker แรกของ floor + เปิดหน้า Spotlight · Play loading จน `arrived` · เดินเองบน marker = ปุ่ม Play ใน Meeting Menu · ไฟล์ที่เอกสารเดิมระบุ — zyra-app Spatial HUD, `scene.ts` click-to-walk เดิม · ขึ้นกับ (เดิม) — 0.47 · Done เมื่อ — เริ่มจาก megaphone ได้โดยไม่ต้องเดินเอง · **แก้ 2026-10-05 (Figma HP-11 v2): เดินเข้าจุดเองหรือกด megaphone ให้เดินไป · นับถอยหลังบนหน้า Spotlight → ux-ui-plan §18.9**
- **มีอยู่แล้ว (verified):**
  - marker = `data.zones` ที่ `zone_type==="spotlight"` (`hero:5837-5852`) → `scene.setSpotlightZones` `:11086`, `_updateSpotlightMarkers` `:6237`
  - state hero: `onSpotlightTile` `:7148` · `requestedSpotlightZoneId` `:7150` (หมายถึง "กด Start ค้างอยู่") · `liveZoneId` `:6325` · `spotlightArrived` `:7209` · `useSpotlightBroadcast` `:7360` รับ arg `arrived` (`use-spotlight-broadcast.ts:54`, `deriveSpotlightSpeakerAction` `:308`) · `handleSpotlightStart` `:7885` ทำงานเมื่อ `spotlightArrived`
  - **pattern เดินกลับเข้า marker มีแล้ว:** `handleSpotlightExitCancel` (~`:7779-7799`) เรียก `walkToTile` ไปกลาง zone ตั้ง state `"returning"` + timeout `SPOTLIGHT_RETURN_MS` 15 วิ (`:454`, `:7806`)
  - `VOHud` ปุ่ม Play disabled จน `spotlightArrived` (`:466`) + ปุ่มลัด B · `scene.ts` `walkToTile` `:9756` คืน bool ตั้ง `_pathFromGoto` ส่ง `goto` · `workspace-ws.ts` `spotlightStart()` `:971` · `zyra-ws/internal/hub/spotlight.go:89` `handleSpotlightStart` (error "not on a spotlight tile" `:121`)
- **ต้องแก้:** hero เพิ่ม handler megaphone: เลือก marker แรกของ floor → `walkToTile(กลาง zone)` → เปิดหน้า Spotlight · state "กำลังเดินไป" **แยกจาก** `requestedSpotlightZoneId` · ปุ่ม Play loading จน `spotlightArrived` (v2: นับถอยหลังบนหน้า Spotlight แทน Play — ux-ui-plan §18.9) · joystick / WASD ขัด → ยกเลิก · `walkToTile` คืน false → toast
- **ไฟล์ใหม่:** ปุ่มกลม megaphone (ชุด HUD 0.5) · หน้า Spotlight มือถือจาก 0.47 (ตอนนี้มีแค่ `vo-spotlight-stage.tsx` 1,164 บรรทัดของ desktop)
- **ผิดจากเอกสาร:**
  - "click-to-walk เดิม / `move_to`" → ใช้ `walkToTile` (programmatic `goto`) ไม่ใช่ path ของ `onClick`
  - "marker แรกของ floor" ไม่มี field ลำดับ — ใช้ลำดับ `data.zones` (`getPublishedMapData` `lib/api/virtual-office.ts:32`) ต้องตกลงให้ตรงกับที่ zyra-ws 0.48a เลือก (ใช้ `map_id` + sort key จาก 0.48b)
  - VO HUD ตอนนี้ไม่มีปุ่ม megaphone (`Megaphone` ใน `vo-sidebar.tsx:49` เป็นปุ่ม announcements)
- **ขึ้นกับ:** 0.47, 0.48, 0.5

---

## <a id="mod-c"></a>C. Lite Mode shell

`views/user/virtual-office/lite/*` (ใหม่ทั้งโฟลเดอร์) · `app/workspace/[id]/play/page.tsx` · `/loading` · `stores/vo-session-store.ts` · `lib/api/workspace-ws.ts`

### <a id="t-0-14"></a>0.14 Lite Home + Lite shell (ไม่โหลด engine)
> **ข้อความเดิม (Phase 0):** งาน — **Lite Home + Lite shell** ตาม ux-ui-plan §3.8 + §10.3 — header workspace (chevron → 0.28, กระดิ่ง → 0.29, user-plus → 0.20), Start spotlight / Instant meeting, ค้นหา, In meeting cards, Circle, Online/Offline list, **bottom nav 4 icon-only โชว์เฉพาะ 4 หน้าหลัก + badge · หน้าลูกซ่อน nav + ปุ่ม back · แนวนอนไม่มี nav** + หดตอนเลื่อน · **ไม่ import GameCanvas** · Calendar tab placeholder · **bottom nav 3 แท็บ Home / Chat / Profile** (Calendar ซ่อนไปก่อน — Ten 2026-10-01) · หน้าลูกซ่อน nav · Android back / iOS swipe-back = back · Spatial HUD ปุ่มกลมขวาบน **ซ่อน calendar เหลือ 4 ปุ่ม** · ไฟล์ที่เอกสารเดิมระบุ — `views/user/virtual-office/lite/*` (ใหม่), route `/workspace/[id]/play` branch ตาม mode · ขึ้นกับ (เดิม) — 0.12, 0.16 · Done เมื่อ — ตรง Figma ≥ 95% (node 5800-425090) · network tab ไม่โหลด PixiJS chunk / map / spritesheet · memory วัดเทียบ Spatial ใน progress.md
- **มีอยู่แล้ว (verified):**
  - `app/workspace/[id]/play/page.tsx:1-5` render `<HeroVirtualOffice />` ทุกครั้ง ไม่แยก mode
  - `hero:365-368` `GameCanvas = dynamic(() => import("@/components/game-canvas/pixi-canvas"))`
  - **`hero:28` static import** `import { mapBackgroundUrls } from "@/lib/vo-preload"` และ `lib/vo-preload.ts:46` static import `@/zyra-engine/pixi-game/pet-layer` → chunk ของ hero ดึง pixi มาด้วยเสมอ
  - `/loading` (`hero-workspace-loading.tsx`) warm engine เสมอ: `:179` `import("@/lib/vo-preload")` · `:180` `import("@/components/game-canvas/pixi-canvas")` · preload asset `:386-440`, `:533-555`
  - store ที่ Lite ใช้ต่อได้: `stores/vo-session-store.ts` `players` (`:104`), `chatSpaceSessions` (`:122` — ทำรายการ Circle ได้), `spotlightSpeakers` (`:129`) · กรอง floor ฝั่ง client `hero:889-892` (`sameFloorPlayers`)
  - **ข้อมูล "In meeting" ไม่มีให้ Lite:** รายชื่อคนในห้องคำนวณจากพิกัดล้วน (`getZoneParticipants` `hero:10223`) · ตำแหน่ง (`moved_bin`) ส่งเฉพาะ peer ใน AOI + floor เดียวกัน (`zyra-ws/internal/hub/room.go:1779-1821` `flushMoves`) Lite ที่ tile 0,0 ไม่ได้ตำแหน่งคนไกล · `ws:meeting:memberLeft` ส่งแค่ในห้อง media (`audio.go:713-718`) · `ws:meeting:memberRemoved` ส่งทั้ง workspace แต่เฉพาะตอน kick (`audio.go:479`)
- **ต้องแก้:**
  - **`app/workspace/[id]/play/page.tsx` แยก mode ที่ระดับ route** — Lite → render Lite shell **ห้าม import hero** (แยกใน hero ไม่ได้เพราะ `:28` ดึง pixi แล้ว)
  - `hero-workspace-loading.tsx` — Lite ข้าม `:179-180` และ preload asset ทั้งหมด แต่ยังเรียก `initSession` (`:493`) ตามเดิม
  - `stores/vo-session-store.ts` `VOSessionParams` (`:50`) เพิ่ม `clientMode` (ทำใน 0.16b)
  - zyra-ws ต้องส่งข้อมูลห้องประชุมระดับ workspace ให้การ์ด In meeting (0.16a)
- **ไฟล์ใหม่:** `views/user/virtual-office/lite/` เช่น `lite-shell.tsx`, `lite-home.tsx`, `lite-bottom-nav.tsx`, `lite-meeting-card.tsx`, `lite-circle-list.tsx` · ใช้ `lib/platform.ts` + `lib/workspace-mode.ts` (0.41 / 0.12)
- **ผิดจากเอกสาร:** TD §16.2 "แค่ไม่เรียก dynamic import บรรทัด 365" ไม่พอ — static import `hero:28` + warm-up ใน `/loading` ดึง pixi มาอยู่ดี → ต้องแยกที่ route
- **ขึ้นกับ:** 0.12, 0.41, 0.16 (ghost join + ข้อมูลห้องประชุม)

### <a id="t-0-16b"></a>0.16b zyra-app: WS client + store ส่ง `client_mode`
เนื้อหาเต็มอยู่ [0.16 ใน module G](#t-0-16) · ส่วนของ module นี้: `lib/api/workspace-ws.ts` constructor (พารามิเตอร์ตามลำดับ `:180-201`) + URL (`:248-275`) ส่ง `client_mode=lite` · `stores/vo-session-store.ts:50` (`VOSessionParams`) + `:417-429` (สร้าง client) เพิ่ม `clientMode` · `hero-workspace-loading.tsx:493-512` ส่งค่าจาก `loadWorkspaceMode()` · type `Player` ใน `lib/api/workspace-ws-types.ts:19` เพิ่ม `client_mode` / `ghost_zone_id`

### <a id="t-0-28"></a>0.28 Workspace lists มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Workspace lists มือถือ** ตาม ux-ui-plan §10.2 — หน้าเต็มจอจาก chevron บน Lite Home · การ์ด 80 px (Last visited, Tag บทบาท, 15/50 เฉพาะ Owner/Admin, online) · search + filter ตามเวลา · join ด้วย link · แนวนอน = modal ทับแมพ · เลือกแล้ว reload (ไม่ถามโหมดซ้ำใน 24 ชม.) · ไฟล์ที่เอกสารเดิมระบุ — `hero-user-workspace.tsx`, `workspace-card.tsx`, `join-workspace-modal.tsx`, `lite/workspace-lists.tsx` (ใหม่) · ขึ้นกับ (เดิม) — 0.14, 0.12 · Done เมื่อ — ตรง Figma 6379-34971 · Member ไม่เห็น 15/50 · join link จากมือถือเข้า workspace ได้
- **มีอยู่แล้ว (verified):**
  - `app/page.tsx` → `HeroUserWorkspace` (`views/user/workspace/hero-user-workspace.tsx:59`) · ค้นหา + debounce `:200-217` · `listParams` `:252-259` (`search, sort_by, order, page, limit, tab`)
  - `SortBy` มีแค่ `updated_at | name | created_at` (`views/user/workspace/workspace-constants.ts:11-17`) **ยังไม่มีตัวกรองตามช่วงเวลา**
  - การ์ด render `:470-488` · `onOpen` → `/workspace/${w.id}` → `HeroWorkspaceEnter` → `/loading` (`hero-workspace-enter.tsx:333`)
  - `views/user/workspace/components/workspace-card.tsx`: `RoleBadge` `:89` · last visited `:253`, `:316` · online `:286-293` · **ตัวเลข 15/50 แสดงทุก role** (`:296-307` เงื่อนไขแค่ `maxCap != null`)
  - `views/user/workspace/components/join-workspace-modal.tsx:13` (`JoinWorkspaceModal`)
- **ต้องแก้:** `workspace-card.tsx` แสดง capacity เฉพาะ `role === "owner" || "admin"` + variant การ์ดสูง 80px · `hero-user-workspace.tsx` ตัวกรองช่วงเวลา (ต้องเพิ่ม param ฝั่ง zyra-api `workspace_handler.go` 🔍) + โหมดเต็มจอ / modal · `join-workspace-modal.tsx` layout มือถือ · "ไม่ถามโหมดซ้ำใน 24 ชม." อยู่ `lib/workspace-mode.ts` (0.12)
- **ไฟล์ใหม่:** `views/user/virtual-office/lite/workspace-lists.tsx`
- **ผิดจากเอกสาร:** `workspace-card.tsx` / `join-workspace-modal.tsx` อยู่ใต้ `views/user/workspace/components/` · `hero-user-workspace.tsx` อยู่ `views/user/workspace/`
- **ขึ้นกับ:** 0.14, 0.12 · zyra-api ถ้ากรองเวลาฝั่ง server

### <a id="t-0-29"></a>0.29 Notification มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Notification มือถือ** — แนวตั้งหน้าเต็มจอ (All/Unread, Mark as read, กลุ่ม Today/Yesterday, ยังไม่อ่าน bg, คำสำคัญ white) · แนวนอน modal ทับแมพ · เปิดจาก push tap (B3) · ไฟล์ที่เอกสารเดิมระบุ — `vo-notification-panel.tsx`, `lite/notification-page.tsx` (ใหม่) · ขึ้นกับ (เดิม) — 0.14, **Figma modal แนวนอน (ยังไม่มี)** · Done เมื่อ — ตรง Figma 6104-81581 · Mark as read ล้าง badge ที่กระดิ่ง + แท็บ
- **มีอยู่แล้ว (verified):** `vo-notification-panel.tsx` `VONotificationPanel` `:112` แท็บ `all` / `unread` (`:128`, `:258-272`) · `markAllNotificationsRead` `:152-158` · จัดกลุ่มตามวัน (comment `:110`) · กล่อง `w-[320px]` `:234` · ใช้ `n.conversation_id` `:194` · API `lib/api/chat.ts:589-608`
- **ต้องแก้:** แยก layout แนวตั้งเต็มจอ · แนวนอน modal / drawer 390 (ux-ui-plan §19)
- **ไฟล์ใหม่:** `views/user/virtual-office/lite/notification-page.tsx`
- **ผิดจากเอกสาร:** —
- **ขึ้นกับ:** 0.14 · เปิดจาก push tap = 2.6a

### <a id="t-0-59a"></a>0.59a Lite: sheet แตะสมาชิก + แตะ Circle
เนื้อหาเต็มอยู่ [0.59 ใน module G](#t-0-59) · ส่วนของ module นี้: `lite/member-profile-sheet.tsx` (Message / Wave / Join) · `lite/join-circle-sheet.tsx` · ใช้ `workspace-ws.ts` `wave` `:762`, `circleAskJoin` `:820`, `circleLeave` `:843` + handler "join circle by id" ใหม่จาก 0.59b

---

## <a id="mod-d"></a>D. Meeting / LiveKit / Spotlight UI

`zone-enter-*`, `views/user/virtual-office/use-meeting-media.ts`, `lib/api/sfu-client.ts`, `vo-spotlight-*`, `use-spotlight-broadcast.ts`

### <a id="t-0-8"></a>0.8 Meeting บนมือถือ: ซ่อน share / PiP, ปิด effect, สลับกล้อง
> **ข้อความเดิม (Phase 0):** งาน — Meeting บนมือถือ — ซ่อน screen share/Document PiP เมื่อไม่มี API · ปิด blur/noise-suppressor default บน mobile · สลับกล้องหน้า/หลัง · ไฟล์ที่เอกสารเดิมระบุ — `views/user/virtual-office/use-meeting-media.ts`, `lib/api/sfu-client.ts`, `vo-background-effects-modal.tsx` · ขึ้นกับ (เดิม) — 0.7 · Done เมื่อ — mic/cam ทำงานบน iOS Safari (ต้องกดหลัง user gesture)
- **มีอยู่แล้ว (verified):**
  - screen share: `sfu-client.ts:905` `getDisplayMedia` · `switchScreenShareSource` `:896` · ปุ่มใน `MeetingToolbar` `zone-enter-header.tsx:417-441` และ `vo-hud.tsx:70-77` (prop `screenOn`, `onScreenToggle`, `screenDisabled`) · `handleScreenToggle` `hero:7868`
  - Document PiP: `views/user/virtual-office/use-document-pip.ts` `getPipApi` `:75`, `getSupportedSnapshot` `:146`, field `supported` `:134-136`, `useDocumentPip` `:151` · hero ใช้ `:8219` (`outsidePip`) และซ่อนปุ่มเมื่อ `outsidePip.supported` false `:14393` อยู่แล้ว
  - ค่าเริ่มต้น: `lib/media-preference.ts:109` `loadNoiseReductionLevel()` คืน **"high"** (RNNoise) · `:337` `loadBackgroundEffect()` คืน `NO_BACKGROUND_EFFECT` (`lib/api/video-background.ts:29`) = **blur ปิดอยู่แล้ว** · `isBackgroundEffectSupported()` `video-background.ts:112` (ใช้ `vo-background-effects-modal.tsx:86`)
  - กล้อง: `sfu-client.ts:1099` `switchDevice()` (เรียก `switchActiveDevice`) · `:1195` `restartCamera(deviceId?)` · **ไม่มี API facingMode** (มีแค่ comment `:1191`)
- **ต้องแก้:** ซ่อนปุ่ม share ใน `MeetingToolbar` + `vo-hud.tsx` เมื่อไม่มี `getDisplayMedia` · `loadNoiseReductionLevel` หรือ initial state `use-meeting-media.ts:517` คืน "off" บนมือถือ · `isBackgroundEffectSupported` คืน false บนเครื่องอ่อน · `SFUClient.switchCamera()` restart track ด้วย `facingMode: user / environment`
- **ไฟล์ใหม่:** `lib/media-capabilities.ts` (`canScreenShare`, `isMobileMedia`) คู่กับ device class 0.41
- **ผิดจากเอกสาร:** ค่าเริ่มต้น blur / noise ไม่ได้อยู่ใน `vo-background-effects-modal.tsx` แต่อยู่ `lib/media-preference.ts` + `lib/api/video-background.ts` · `hooks/use-document-pip.ts` (90 บรรทัด) เป็นไฟล์ซ้ำไม่มีใครใช้ ตัวจริงคือ `views/user/virtual-office/use-document-pip.ts`
- **ขึ้นกับ:** 0.7, 0.1, 0.41

### <a id="t-0-17"></a>0.17 Meeting layout มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Meeting layout มือถือ** ตาม ux-ui-plan §8.2 — header 5 ปุ่ม + ชื่อ meeting แทนห้อง · tiles 1–6+ ทั้ง 2 orientation + ลูกศรเลื่อนหน้า · Meeting Menu 7 ปุ่ม · emoji panel + raise hand badge/กรอบเหลือง (ใช้ `onSendReaction`/`handRaised` เดิม) · 1-tap ซ่อนเมนู · double-tap ขยาย tile · low battery toast · ไฟล์ที่เอกสารเดิมระบุ — `zone-enter-header.tsx`, `zone-enter-tiles.tsx`, `zone-enter-panel.tsx`, `vo-media-device-menu.tsx` · ขึ้นกับ (เดิม) — 0.7, 0.8 · Done เมื่อ — ตรง Figma ≥ 95% (6254-606885, 6346-547052, 6547-578842) · 7 คนขึ้นไปเลื่อนหน้าได้
- **มีอยู่แล้ว (verified):**
  - header `PanelHeader` `zone-enter-header.tsx:99`: ซ้าย ชื่อ zone + ปุ่มนับคน (`MemberIcon`) `:140-151` · ขวา `MeetingTimer` `:42`, Lock `:157-186`, Copy link `:187-205`, Chat `:209-227`, Expand `:230-240` · `ZoneParticipantsSubmenu` `:244-259`
  - toolbar `MeetingToolbar` `:270`: mic + chevron `:357` · cam + chevron `:387` · screen `:417` · emoji `:447` (`MEETING_EMOJIS` `:266` **8 ตัว** ใช้ร่วมกับ `vo-hud.tsx`) · hand `:481` · stop broadcast `:499`
  - panel `ZoneEnterPanel` `zone-enter-panel.tsx:45`: expanded `:281` grid 5×2 (`GRID_COLS` `:197`, class `:389`) · compact `:454` 6 tile/หน้า (`OTHERS_PAGE_SIZE` `:208`) + Chevron เลื่อนหน้า + `chunkArray` `:20`
  - tiles: `CompactDisplayCard` `zone-enter-tiles.tsx:251` · `ExpandedDisplayCard` `:520` · `HandQueueBadge` `:94` · `TileReactions` `:226` · `FloatingReaction` `:129` · `ReactionBurst` `:164` · กรอบเหลืองยกมือ (`#ECC819`) ใน borderClass
  - types `MeetingMediaControls` `zone-enter-types.ts:11`: `handRaised` `:29`, `onHandToggle` `:31`, `onSendReaction` `:33`, `memberHands` `:143`, `reactions` `:145` · mount `hero:14583`, `:14709` · `use-meeting-media.ts:820` `activeSpeakersChanged`
- **ต้องแก้:** header มือถือ (chevron PIP + ชื่อ meeting + ปุ่ม icon 5 ปุ่ม) · ปุ่ม hover-only ใช้บนจอสัมผัสไม่ได้: `SelfTileControls` `:435`, `RequestMediaControls` `:476`, `CardHoverOverlay` `:243` → แตะ · layout tile 1–6+ ทั้ง 2 แนว (grid 5×2 / 6 ต่อหน้า ปรับตามจอ) · Meeting Menu 7 ปุ่มเป็น variant แยกจาก `MeetingToolbar` · emoji ชุดมือถือแยก ไม่แตะ `MEETING_EMOJIS` · state แตะครั้งเดียวซ่อนเมนู + แตะสองครั้งขยาย tile ใน `ZoneEnterPanel`
- **ไฟล์ใหม่:** `zone-enter-mobile-*.tsx` · hook low battery (WKWebView ไม่มี Battery API → `@capacitor/device` ตาม inventory B15)
- **ผิดจากเอกสาร:** ux-ui-plan §8.4 เขียน `onToggleHand` ชื่อจริง `onHandToggle` (`types:31`) · "`:142` raise-queue" จริง `memberHands :143` · ไม่มีโค้ด low battery / double-tap
- **ขึ้นกับ:** 0.7, 0.8, Figma

### <a id="t-0-18"></a>0.18 PIP ในแอป
> **ข้อความเดิม (Phase 0):** งาน — **PIP ในแอป** — กดลูกศรลงย่อเป็น tile 168×158 ลอย (Lite Home ตำแหน่งตายตัว **ลากไม่ได้** / ขวาล่างแมพ**เหนือ minimap — minimap ไม่หาย**) แสดง active speaker · แตะกลับเต็มจอ · คง LiveKit room + WS ระหว่างย่อ · ไฟล์ที่เอกสารเดิมระบุ — `views/user/virtual-office/lite/meeting-pip.tsx` (ใหม่), `use-meeting-media.ts` · ขึ้นกับ (เดิม) — 0.14, 0.17 · Done เมื่อ — ย่อแล้วเสียงยังต่อ · สลับคนพูดภายใน 1 วิ · ตรง Figma 6350-571263
- **มีอยู่แล้ว (verified):** ใกล้เคียงที่สุด `VOSpotlightMiniWindow` `vo-spotlight-stage.tsx:815` การ์ดลากได้ 340×280 (**ไม่ได้ export**) · hero `spotlightViewerPip` `:7321`, `spotlightPresenterPip` `:7324`, `handleSpotlightViewerPip` ~`:8228` · ตัวช่วยลาก `VODraggable` `vo-draggable.tsx:58`, `clampToViewport` `:36` · active speaker `meetingAudio.speakingUserIds` (`use-meeting-media.ts:820`) · **session อยู่ต่อเองระหว่างย่อ** — `useMeetingMedia` mount `hero:7394` ผูกกับ `meetingZoneId` ไม่ใช่ panel · `TileVideo` `zone-enter-tiles.tsx:17` ไม่ได้ export
- **ต้องแก้:** prop `onMinimize` ใน `ZoneEnterPanel` · state meeting-PIP ใน hero · export `TileVideo` หรือใช้ `CompactDisplayCard` ซ้ำ · วางเหนือ `vo-minimap.tsx`
- **ไฟล์ใหม่:** meeting PIP — เอกสารเดิม `lite/meeting-pip.tsx` แต่ Spatial ใช้ด้วย → วาง `views/user/virtual-office/components/vo-meeting-pip.tsx` เหมาะกว่า
- **ผิดจากเอกสาร:** "คง LiveKit room" **ไม่ต้องแก้ `use-meeting-media.ts`** — ที่ต้องระวังคือ hero ห้ามล้าง `meetingZoneId` ตอนย่อ
- **ขึ้นกับ:** 0.14, 0.17

### <a id="t-0-19"></a>0.19 Join meeting sheet / modal + Request to join
> **ข้อความเดิม (Phase 0):** งาน — **Join meeting sheet/modal + Request to join** — แตะการ์ดห้อง → sheet (แนวตั้ง) · **Spatial: แตะห้องบนแมพ → modal** (hit-test zone ห้อง meeting จาก tap ใน `scene.ts` ก่อนส่งเป็น tap-to-walk · Join = auto-walk เข้าห้องด้วย path เดิม · อยู่ในห้องแล้วไม่เปิด) · ห้องล็อก → Request (ส่ง `knock` เดิมพร้อม `zone_id` — zyra-ws ไม่เช็คตำแหน่ง ใช้ได้กับ Lite) → คนในห้องเห็น toast → Accept/Deny ใน Requesting list (task 0.52) · All rooms are busy sheet · ไฟล์ที่เอกสารเดิมระบุ — `lite/join-meeting-sheet.tsx` (ใหม่) · backend ใช้ knock เดิม (`zyra-ws internal/hub/room.go:2504`) · ขึ้นกับ (เดิม) — 0.16 · Done เมื่อ — คนในห้องกด Accept แล้วผู้ขอเข้าได้ · Deny แจ้งผู้ขอ
- **มีอยู่แล้ว (verified):**
  - **hit-test ห้องอยู่ใน hero ไม่ใช่ `scene.ts`:** `handleCanvasClick` `hero:11357` → `zoneForPointer` `:11223` · ห้อง meeting เปิด `ZoneHoverCard` ผ่าน `setClickedZone` `:11438` · ห้องล็อกเปิด `ZoneLockedOverlay` ผ่าน `setZoneAccessState` `:11425-11435` · อยู่ในห้องแล้วไม่เปิด (`:11418`) · `ZoneHoverCard` mount `:13761` · `handleZoneJoin` `:11461` · `ZoneLockedOverlay` `zone-locked-overlay.tsx:31` (`ZoneAccessStatus` `:8`)
  - ผู้ขอ: `handleAskPermission` `hero` ~`:5262` → `ws.knock(zoneId)` (`workspace-ws.ts:793`) · `knockCancel` `:803`
  - คนในห้อง: listener `knock_request` `hero:2817` ส่งต่อเฉพาะ `section?.is_member === true` · `knock_decided` / `knock_cancelled` `:2857-2865` · **`handleKnockAllow` `:5027` เรียก REST `grantZoneSectionAccess` (`lib/api/zone-sections.ts:209`) ก่อน** `knockDecision` (`workspace-ws.ts:798`)
  - zyra-ws `handleKnock` `room.go:2504` · `handleKnockDecide` `:2585` · `handleKnockCancel` `:2661`
- **ต้องแก้:** มือถือ — `handleCanvasClick` เปิด Join modal แทน `ZoneHoverCard` / `ZoneLockedOverlay` · ปุ่ม Join เรียก `handleZoneJoin` เดิม · Accept ต้องเรียก `handleKnockAllow` ไม่ใช่ `knockDecision` ตรง ๆ
- **ไฟล์ใหม่:** `lite/join-meeting-sheet.tsx` · Join modal ฝั่ง Spatial
- **ผิดจากเอกสาร:** hit-test ไม่ได้อยู่ `scene.ts` แต่อยู่ hero (`zoneForPointer` / `handleCanvasClick`) · ขั้น Accept มี REST grant คั่น ไม่ใช่ knock ล้วน · "All rooms are busy" ไม่มีโค้ด Instant meeting รองรับ
- **ขึ้นกับ:** 0.16, 0.4, 0.52

### <a id="t-0-20"></a>0.20 Setting ห้อง (Voice output / Camera filter / Invite)
> **ข้อความเดิม (Phase 0):** งาน — **Setting ห้อง + sheet ชวนคน** — bottom sheet 3 เมนู: **Voice output** (เลือกเสียงออก ลำโพง / หูฟัง / Bluetooth) · **Camera filter** (background blur / virtual background — ปิดเป็นค่าเริ่มต้นบนเครื่องอ่อน) · **Invite** (เปิด Invite sheet ของ task 0.52) · ไม่มี Room name (Ten 2026-10-02) · ไฟล์ที่เอกสารเดิมระบุ — ต่อยอด `zone-enter-header.tsx`, `vo-media-device-menu.tsx` · ขึ้นกับ (เดิม) — 0.17, **Figma (ยังไม่มี)** · Done เมื่อ — ตรง Figma เมื่อได้
- **มีอยู่แล้ว (verified):** `VOMediaDeviceMenu` `vo-media-device-menu.tsx:66` variant audio มีรายการลำโพง `audiooutput` (`:104-138`) + `onOpenBackgroundEffects` (`:203`) · เปลี่ยนลำโพงด้วย `setSinkId` ผ่าน `sfu.switchDevice` (`sfu-client.ts:1083-1102`) · `VOBackgroundEffectsModal` `:76` · Invite = `InviteMemberModal` mount `hero:12590` (`activeModal === "invite"`)
- **ต้องแก้:** header ยังไม่มีปุ่ม Setting · Voice output บน iOS Safari / WKWebView ใช้ `setSinkId` + list `audiooutput` ไม่ได้ → ซ่อน หรือ native audio route 🔍
- **ไฟล์ใหม่:** meeting settings sheet
- **ผิดจากเอกสาร:** device menu ไม่ได้อยู่ `PanelHeader` แต่อยู่ `MeetingToolbar` (`deviceMenu` `zone-enter-header.tsx:321`)
- **ขึ้นกับ:** 0.17, 0.52, Figma

### <a id="t-0-35"></a>0.35 Camera / Mic permission flow มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Camera / Mic permission flow มือถือ** ตาม ux-ui-plan §13.6 — ขอตอนกดปุ่มทั้ง Lite + Spatial (เลิกขอตอนเข้า office / pre-join บนมือถือ) · `prompt` → pre-permission sheet → dialog ระบบ · `denied` → native alert (`@capacitor/dialog`) → เปิด app settings · indicator บนปุ่ม · mobile web → guide sheet Safari / Chrome มือถือ · pre-join Spatial แสดง avatar ถ้ายังไม่มีสิทธิ์ · ไฟล์ที่เอกสารเดิมระบุ — `use-entry-media-permission.ts`, `use-meeting-media.ts`, `zone-enter-panel.tsx`, `vo-permission-guide-modal.tsx`, `lib/media-permissions.ts` · ขึ้นกับ (เดิม) — 0.17, 1.1, **Figma pre-permission / indicator (ยังไม่มี)** · Done เมื่อ — กด Don't Allow → กดซ้ำ → alert Settings · เปิดสิทธิ์ใน Settings แล้วกลับมากดได้ทันที · ไม่ crash ทุก state (granted / prompt / denied)
- **มีอยู่แล้ว (verified):** ขอตอนเข้า office: `useEntryMediaPermission` `use-entry-media-permission.ts:208` (`SESSION_ASKED_KEY` `:56`, `requestAndRelease` `:192`) ขอ location ด้วย + ช่วย Auto-PiP · `lib/media-permissions.ts` `queryMediaPermission` `:28`, `queryPermissionState` `:39`, `watchMediaPermission` `:67` · `use-meeting-media.ts` `permissionOutcome` `:356`, `describeMediaToggleError` `:371` + field `micPermissionDenied`, `camPermissionDenied`, `permissionPrompt`, `permissionPromptVariant` · `VOPermissionSnackbar` `vo-permission-snackbar.tsx:58` (mount `hero:14141`) · `VOPermissionGuideModal` `vo-permission-guide-modal.tsx:23` กว้าง 700px logo Chrome / Safari / Edge desktop `:13-15` + `BrowserGuide` `:176` (mount `hero:12616`)
- **ต้องแก้:** ข้ามการขอตอนเข้า office บนมือถือ (ย้ายการขอ location ไปที่อื่น) · ก่อน `toggleMic` / `toggleCamera` ถ้า `prompt` → pre-permission sheet · `denied` → guide sheet Safari / Chrome มือถือ (native ใช้ `@capacitor/dialog`) · indicator บนปุ่ม
- **ไฟล์ใหม่:** pre-permission sheet · guide sheet มือถือ · `@capacitor/dialog` ลงใน 1.1
- **ผิดจากเอกสาร:** `zone-enter-panel.tsx` ไม่มี logic permission — UI อยู่ hero + snackbar
- **ขึ้นกับ:** 0.17, 1.1, Figma

### <a id="t-0-36"></a>0.36 Connection states มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Connection states มือถือ** ตาม ux-ui-plan §14 — toast Poor connection (LiveKit `ConnectionQualityChanged` ของตัวเอง, × ซ่อน 20 วิ) / Lost connection / Reconnecting… · spinner บนป้ายชื่อ tile ของคนที่เน็ตแย่/หลุด · retry 5 ครั้ง → ตัด meeting → หน้าหลัก skeleton + "Reconnecting..." ≤ 30 วิ (ข้อเสนอ ux-ui-plan §14.8 — header/nav จริง + แท่ง skeleton + toast) → Workspace list · toast "Meeting has ended due to lost connection" ทั้ง 2 แนว · ใช้ toast เดียวกันนอกห้องประชุม · ไฟล์ที่เอกสารเดิมระบุ — `vo-connection-toast.tsx`, `use-meeting-media.ts`, `sfu-client.ts`, `zone-enter-tiles.tsx`, `workspace-ws.ts`, `hero-virtual-office.tsx`, `lite/home.tsx` · ขึ้นกับ (เดิม) — 0.17, 0.14, zyra-ws grace (TD §12) · Done เมื่อ — ปิด wifi กลาง meeting → เห็นลำดับ toast ตรง Figma · เปิด wifi ภายใน 30 วิ → กลับมาโดยไม่ต้อง login ใหม่ · เกิน → Workspace list
- **มีอยู่แล้ว (verified):** `VOConnectionToast` variant `lost`, `offline`, `reconnected` มุมขวาบน กว้าง 322 (render `hero:12427-12439`) · state hero `connectionStatus` `:1328`, `showReconnectedToast` `:1560`, `isOffline` `:1570` · handler WS `onReconnecting` `:3265`, `onReconnected` `:3272` (toast 3 วิ), `onReconnectExhausted` `:3349` · scrim `:12423` · `VOReconnectFailedModal` `:12443` (Leave → `router.push("/workspace")`) · WS backoff `workspace-ws.ts:82-83` → `onReconnectExhausted` `:403`, `onReconnecting` `:408` · tiles: `ConnectionState` `types:48`, prop `:63`, spinner `RotateCw` **เฉพาะ tile ตัวเอง** (`zone-enter-tiles.tsx:296/373`, `:556/624`) tile คนอื่นแค่จาง · SFU `scheduleReconnect` `use-meeting-media.ts:1304` 3 ครั้ง 1/3/6 วิ → toast voiceUnavailable · **ไม่มี ConnectionQuality เลย** (`SFUEventMap` `sfu-client.ts:148`, binding `:475-495`)
- **ต้องแก้:** `sfu-client.ts` bind `RoomEvent.ConnectionQualityChanged` → event `connectionQualityChanged` · `use-meeting-media.ts` เปิด `selfQuality` + map `memberConnectionQuality` · tiles spinner บนป้ายชื่อตาม quality รายคน · toast เพิ่ม variant poor / reconnecting / meeting-ended + ย้ายตำแหน่งในห้องประชุม · ต่อไม่ได้บนมือถือ → Workspace list + toast แทน modal
- **ไฟล์ใหม่:** หน้าหลัก skeleton (ขึ้นกับ 0.14)
- **ผิดจากเอกสาร:** `lite/home.tsx` ยังไม่มี · TD อ้าง `hero:12423-12462` จริง `12423-12464` · `sfu-client.ts:481-482`, `:1687` ตรง · **"zyra-ws grace (TD §12)" ไม่มี task รับ → เพิ่ม [0.62](#t-0-62)**
- **ขึ้นกับ:** 0.14, 0.17, 0.62

### <a id="t-0-40"></a>0.40 Bandwidth / audio-only fallback (EP-02)
> **ข้อความเดิม (Phase 0):** งาน — **Bandwidth / audio-only fallback (EP-02)** — มือถือ + desktop · อ่าน uplink bitrate (`RTCPeerConnection.getStats` ของ publisher / LiveKit connection quality) ทุก 2–5 วิ · cap publish layer บน simulcast เดิม 720/360/180 · 200–500 kbps นาน 10 วิ → `setCameraEnabled(false)` + flag `autoDisabled` · < 200 kbps toast Very poor · กลับ > 1 Mbps นาน 10 วิ → toast Camera is ready (ไม่เปิดเอง, ไม่ขึ้นถ้าผู้ใช้ปิดเอง) · ส่ง state "เน็ตไม่ดี" ให้คนอื่นแสดง spinner บนป้ายชื่อ · ไฟล์ที่เอกสารเดิมระบุ — `lib/api/sfu-client.ts`, `use-meeting-media.ts`, `vo-connection-toast.tsx`, `zone-enter-tiles.tsx` · ขึ้นกับ (เดิม) — 0.36 · Done เมื่อ — จำลอง network throttle (Chrome DevTools / Network Link Conditioner) → toast ตรงลำดับ · วัด bitrate ก่อน/หลัง (rule 18)
- **มีอยู่แล้ว (verified):** room options `sfu-client.ts:405-462` — `adaptiveStream` / `dynacast` `:409-410`, `videoCaptureDefaults` h720 `:438-440`, `publishDefaults.videoEncoding` h720 `:441-443` · simulcast 720/360/180 = default ของ LiveKit (comment `:434`) **ไม่ได้ตั้ง `videoSimulcastLayers` เอง** · `setCameraEnabled` `:639` · **ไม่มี `getStats`**
- **ต้องแก้:** `SFUClient` ตัววัด uplink + method จำกัด layer ที่ publish (🔍 เช่น `LocalVideoTrack.setPublishingQuality` ต้องเช็คใน livekit-client 2.20) · `use-meeting-media` ref `autoDisabled` + timer 10 วิ + toast
- **ไฟล์ใหม่:** `lib/api/uplink-monitor.ts` · `__tests__/sfu-uplink-ladder.test.ts` (ตาม pattern `sfu-*.test.ts`)
- **ผิดจากเอกสาร:** "ส่ง state เน็ตไม่ดีให้คนอื่น" ไม่ต้องทำช่อง WS ใหม่ — SFU กระจาย connection quality ให้ทุกคนอยู่แล้ว ใช้ event เดียวกับ 0.36
- **ขึ้นกับ:** 0.36

### <a id="t-0-45"></a>0.45 Grid 3×3 บน tablet
> **ข้อความเดิม (Phase 0):** งาน — **Meeting grid 3×3 บน tablet** (6–9 tile) · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `zone-enter-tiles.tsx` / meeting มือถือ · ขึ้นกับ (เดิม) — 0.7, รอ design · Done เมื่อ — 🎨 รอ Figma
- **มีอยู่แล้ว (verified):** grid expanded 5×2 fix ที่ `zone-enter-panel.tsx:197` (`GRID_COLS`) + `:389` (Tailwind ต้องเขียนตัวเลขตรง ๆ)
- **ต้องแก้:** เลือกขนาด grid ตาม device class (`useTabletScale` 0.43)
- **ไฟล์ใหม่:** ไม่มี (hook มาจาก 0.41)
- **ผิดจากเอกสาร:** ไม่พบ
- **ขึ้นกับ:** 0.7, 0.43, รอ Figma

### <a id="t-0-47"></a>0.47 หน้า Spotlight presenter มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **หน้า Spotlight presenter มือถือ** ตาม ux-ui-plan §18.2 / §18.6 — header (chevron, chat, speaker + chip LIVE · N) · tile ตาราง HP-04 · Meeting Menu cam / mic / share (disabled) / ⋮ ┃ Play-Stop / leave · toast นับ 5 วิ + Stop · "Spotlight started now" 3 วิ · sheet ⋮ (แนวตั้ง bottom sheet / แนวนอน modal 390) · sheet ยืนยัน Stop broadcasting · ใช้ state machine เดิม `use-spotlight-broadcast.ts` · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `views/user/virtual-office/lite/*` + Spatial overlay · ขึ้นกับ (เดิม) — 0.14, 0.18, 0.48 · Done เมื่อ — presenter เริ่ม/หยุดได้ทั้ง 2 แนว · 🎨 chip LIVE / แนวนอน รอ design ยืนยัน · **แก้ 2026-10-02 (โน้ต Pai): chip LIVE · N เปลี่ยนเป็นป้าย LIVE + ตัวนับ Mic / Eye → ux-ui-plan §19** · **แก้ 2026-10-05 (Figma HP-11 v2): megaphone → sheet ยืนยัน → นับถอยหลังบน Home → หน้า live · ไม่มี Play/Stop · Leave → "Leave Spotlight?" → "Broadcast ended" · sheet "Spotlight is full" · More = Emoji/Chat/Setting/Invite · header Live + ชิป N | M → ux-ui-plan §18.9**
- **มีอยู่แล้ว (verified):** `useSpotlightBroadcast` `use-spotlight-broadcast.ts:340` (interface `:63`) · `deriveSpotlightSpeakerAction` `:308` · `SPOTLIGHT_START_ACK_TIMEOUT_MS` / `RETRY_DELAY` / `MAX_ATTEMPTS` `:274-280` · `spotlightStartErrorKey` `:291` · นับถอยหลัง 5 วิอยู่ hero `:7151-7298` (`Date.now()+5000` `:7285`) UI `:14077`, `:14233` (`spotlightGoingLive`) · `VOSpotlightStage` mount `:14089`, `:14406`, `:14514` · stop ผ่าน `MeetingToolbar` (`onStopBroadcast` `:499`) · `VOSpotlightExitConfirmModal` mount `:13283`, `handleSpotlightExitConfirm` `:7771` · header นับคน `StageCountMenu` `vo-spotlight-stage.tsx:740` (stage / Viewers `:286`) viewers คำนวณ `hero:7518` `resolveSpotlightViewers(spotlight.roomParticipantIds)` · flag `isSpotlightEnabled` `lib/spotlight-feature.ts:23` · `spotlightBlockedByStatus` `hero:7155` · i18n `spotlightExitTitle` / `Body` `en.json:1053-1054`, `spotlightEndedTitle` "Broadcast ended" `:1057`
- **ต้องแก้:** หน้า Spotlight มือถือห่อ `VOSpotlightStage` หรือแยก layout · header Live + ชิป N \| M (Figma v2) · sheet ยืนยันก่อนนับถอยหลัง + "Leave Spotlight?"
- **ไฟล์ใหม่:** `lite/spotlight-*.tsx` + overlay ฝั่ง Spatial
- **ผิดจากเอกสาร:** "Spotlight is full" ไม่มีทั้ง i18n และ limit ฝั่ง zyra-ws (`spotlight.go` ไม่มี max speakers) → ต้องทำ 0.54 ก่อน · ไม่มี i18n "Spotlight started now" · TD §16.9 ยังพูดถึง Play / Stop ซึ่ง v2 ตัดแล้ว
- **ขึ้นกับ:** 0.14, 0.18, 0.48

### <a id="t-0-48c"></a>0.48c zyra-app: Lite เริ่ม Spotlight
เนื้อหาเต็มอยู่ [0.48 ใน module G](#t-0-48) · ส่วนของ module นี้: `use-spotlight-broadcast.ts` เพิ่มทาง Lite ให้ `onSpotlightTile` และ `arrived` เป็น true (`deriveSpotlightSpeakerAction` `:308-320`) · ส่ง `zone_id` / `floor_id` ใน `spotlightStart()` (`workspace-ws.ts:971`) ถ้าเลือกทาง payload · แปลง error ใหม่ใน `spotlightStartErrorKey` (`:282-300`)

### <a id="t-0-50"></a>0.50 หน้า Spotlight คนดู
> **ข้อความเดิม (Phase 0):** งาน — **หน้า Spotlight คนดู** — นอก meeting เปิดเต็มจออัตโนมัติ (Lite + Spatial) · แถบ speaker / chat / emoji / raise hand / leave + confirm · ใน meeting = toast Join spotlight / Stay in meeting ตาม web · chevron = PIP / กลับ meeting · ไฟล์ที่เอกสารเดิมระบุ — zyra-app · ขึ้นกับ (เดิม) — 0.47 · Done เมื่อ — 🎨 แถบคนดูรอ design · พฤติกรรมตรง web · **แก้ 2026-10-02 (โน้ต Pai): header ป้าย LIVE + ตัวนับ `Mic` / `Eye` · bottom menu **Chat · Speaker · Leave** (ไม่มี emoji / raise hand) · sheet รายชื่อ 2 แท็บ On stage / Viewers ไมค์คนบนเวทีแสดงสถานะ เห็นเฉพาะคนบนเวที → ux-ui-plan §19** · **แก้ 2026-10-05 (Figma HP-11 v2): toast ✓ / × 10 วิ แทนเปิดเอง · ใน meeting ✓ = ทั้งห้อง + แถบรายชื่อคนในห้อง + Undo (meetingLeave) · ลูกศรลง = PIP เฉพาะเครื่อง · PIP รวม Spotlight | Meeting · "Broadcast ended" ปิดหน้าคนดู · แถว "Spotlight · Live" บน Lite Home (ข้อเสนอ) → ux-ui-plan §18.9**
- **มีอยู่แล้ว (verified):** `VOSpotlightNotification` mount `hero:13262` · `VOSpotlightBanner` `:13331` · `VOSpotlightMeetingPrompt` `vo-spotlight-notification.tsx:68` (Join spotlight / Stay in meeting) mount `:13310` · `handleJoinSpotlightFromMeeting` `:7677` → `ws.spotlightMeetingJoin` `workspace-ws.ts:984` · Undo `spotlightMeetingLeave` `:996` · `VOSpotlightLeaveConfirmModal` mount `:13293`, `handleSpotlightLeaveConfirm` `:7832` · PIP `spotlightViewerPip` + `VOSpotlightMiniWindow` `:815` · ปุ่ม Speaker = `toggleAudioMuted`
- **ต้องแก้:** เปิดเต็มจออัตโนมัติ → toast ✓ / × 10 วิ · แถบรายชื่อคนในห้อง + Undo · เมนูล่าง Chat · Speaker · Leave · sheet 2 แท็บ On stage / Viewers ใช้ `ZoneParticipantsSubmenu` + `statusLabelFor` ได้ แต่**ยังไม่มีไอคอนสถานะไมค์ในแถว** · PIP รวม Spotlight \| Meeting
- **ไฟล์ใหม่:** viewer page + PIP รวม
- **ผิดจากเอกสาร:** TD §16.9 "เปิดเต็มจออัตโนมัติ" ถูกแทนด้วย v2 แล้ว
- **ขึ้นกับ:** 0.47

### <a id="t-0-51"></a>0.51 แชท Spotlight มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **แชท Spotlight มือถือ** — หน้าเต็มจอแบบ HP-05 · มี tab Spotlight / Meeting เมื่ออยู่ใน meeting ด้วย (web `spotlightChatTab*`) · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `views/chat` + spotlight chat · ขึ้นกับ (เดิม) — 0.21–0.27 (แชทมือถือ) · Done เมื่อ — ส่ง/อ่านได้ทั้ง 2 tab · **แก้ 2026-10-05 (Figma HP-11 v2): Meeting chat แท็บ Spotlight / Meeting ตาม Figma → ux-ui-plan §18.9**
- **มีอยู่แล้ว (verified):** `SpotlightChatColumn` `vo-spotlight-stage.tsx:1074` แท็บ spotlight / meeting + draft แยกต่อแท็บ + `UnreadTabBadge` `:1157` · `MeetingChatPanel` `zone-enter-chat.tsx:526` (prop `tabs`, `speakerUserIds`) · hero `spotlightChatOpen` / `Tab` `:8666-8667`, `spotlightChatEntries` `:8693`, `spotlightChatSource` `:11045` · `handleSendSpotlightChat` `:8697` → `ws.meetingChatSend` `workspace-ws.ts:1041` (+ `meetingChatJoin` `:1031`) · i18n `spotlightChatTabSpotlight` / `Meeting` `en.json:1069-1070`
- **ต้องแก้:** `MeetingChatPanel` / `SpotlightChatColumn` แบบเต็มจอบนมือถือ
- **ไฟล์ใหม่:** wrapper เต็มจอ
- **ผิดจากเอกสาร:** **แชท Spotlight ไม่ได้อยู่ `views/chat`** (ระบบ conversation REST) แต่เป็นแชท meeting ชั่วคราวผ่าน WS → 0.21–0.27 เกี่ยวแค่หน้าตาให้สอดคล้อง
- **ขึ้นกับ:** 0.17 · 0.21 (หน้าตา)

### <a id="t-0-52"></a>0.52 Participants sheet + Invite sheet + toast คำขอเข้าห้อง
> **ข้อความเดิม (Phase 0):** งาน — **Participants sheet + Invite sheet + toast คำขอเข้าห้อง** (ux-ui-plan §8.8 · โน้ต Pai 2026-10-02) — ปุ่ม header `UserPlus` → `Users` · Participants: host + มงกุฎ (`ws:meeting:ownerUpdate`) แล้วเรียงตามลำดับที่เข้า · ไมค์ท้ายแถว host ปิดได้อย่างเดียว (`ForceMute` เดิม) · ⋯ Kick + Mute all (host) · Requesting list Accept/Deny (ทุกคนในห้อง · `knock_decision`) · Invite แท็บ Chat (online ไม่อยู่ในห้อง → offline · แตะทั้งแถวติ๊ก · ส่ง DM ลิงก์ห้อง) / Link (Owner/Admin · ลิงก์ workspace + toggle วันหมดอายุ) / Email (Owner/Admin · หลายอีเมล · Member) · toast "Someone is requesting to join your meeting." / "N people…" 5 วิ + ตัวเลขบน `Users` · ไฟล์ที่เอกสารเดิมระบุ — ต่อยอด `zone-participants-submenu.tsx`, `zone-hover-card.tsx`, `invite-member-modal.tsx`, `customize-invite-link-panel.tsx`, `vo-knock-notification.tsx` · API เดิม `lib/api/workspace-members.ts:129,140` · ไม่มีงาน backend · ขึ้นกับ (เดิม) — 0.17, 0.19, **frame จาก Pai** · Done เมื่อ — test FE-MEET-12, 14, 19–25 · BE-WS-05, 14
- **มีอยู่แล้ว (verified):**
  - `ZoneParticipantsSubmenu` `zone-participants-submenu.tsx:136` (`MemberRow` `:31`) เรียง host ก่อน, Crown, Mute all, Remove (`UserX`), Chat (`MessageSquare`), `statusLabelFor`
  - host `meetingAudio.meetingOwnerUserId` จาก `ws:meeting:ownerUpdate` (`use-meeting-media.ts:1583`, type `workspace-ws-types.ts:543`)
  - Mute all `muteAll` `workspace-ws.ts:918` → server `audio.go:371` **ไม่จำกัดว่าใครกด** · ปิดไมค์คนอื่น `requestMediaOff(..., "mic")` `:899` → `handleMediaRequest` `audio.go:285` → `MsgAudioForceMuted` · Kick `kickFromMeeting` `:908` → `handleMeetingKick` `audio.go:435` · hero `handleRequestMediaOff` `:10869`, `handleKickParticipant` `:10905`
  - Invite: `ZoneHoverCard` มี `invitableMembers`, `showInvite`, ปุ่ม Bell ยังไม่ทำงาน (`onClick={() => {}}`) · `InviteMemberModal` `invite-member-modal.tsx:95` (`canShareLink` `:104`, `emailAllowedRoles` `:111`, `inviteWorkspaceMembers` `:211`, get / update link config `:148` / `:270`, `CustomizeInviteLinkPanel` `:449`) · `customize-invite-link-panel.tsx:87` (`onConfirm({maxUses, expiresAt})`)
  - API `lib/api/workspace-members.ts` `inviteWorkspaceMembers` `:87`, `getWorkspaceJoinLinkConfig` `:130`, `updateWorkspaceJoinLinkConfig` `:141`, `regenerateWorkspaceJoinLink` `:161` · DM `lib/api/chat.ts` `getOrCreateDM` `:226`, `sendMessageREST` `:405` · hero `handleOpenDm` `:5003` · ลิงก์ห้อง `?zone_id=` `zone-enter-header.tsx:196`
  - knock `VOKnockNotification` `:42` (`KnockEvent` `:5`) · `knockEvents` `hero:1143` · `handleKnockAllow` `:5027`
- **ต้องแก้:** ปุ่มนับคนใน header → `Users` + badge จำนวนคำขอ · submenu → sheet (ไอคอนไมค์ท้ายแถว, ⋯ Kick, ส่วน Requesting, ตัดปุ่ม Chat) · **ซ่อน Mute all / Kick จากคนที่ไม่ใช่ host ที่ฝั่ง UI** (server ไม่ล็อก Mute all) · แยก `InviteMemberModal` เป็นแท็บ Chat / Link / Email
- **ไฟล์ใหม่:** participants sheet · invite sheet · toast คำขอเข้าห้องแบบรวมจำนวน
- **ผิดจากเอกสาร:** header **ไม่มีปุ่ม `UserPlus`** — ที่มีคือ `MemberIcon` (`zone-enter-header.tsx:140-151`) `UserPlus` มีแค่ใน `zone-hover-card.tsx` · ไม่มี symbol `ForceMute` — ทางจริง `ws:media:request` → `handleMediaRequest` → `MsgAudioForceMuted` · `workspace-members.ts:129,140` จริง **`:130` / `:141`** · "เรียงตามลำดับที่เข้า": รายชื่อมาจากตำแหน่งบนแมพ (`getAuthoritativeZoneParticipants` `hero:14570`) ไม่มีเวลาเข้า → ใช้ ts ของ event `participated` ใน meeting chat (panel ใช้คำนวณ `meetingStartedAt` อยู่แล้ว) · `KnockEvent` ไม่มีเวลา · `knock_request` ถึงเฉพาะสมาชิก section · "ไม่มีงาน backend" จริง ยกเว้นถ้าจะล็อก Mute all ฝั่ง server (ยังไม่มีมติ)
- **ขึ้นกับ:** 0.17, 0.19, frame จาก Pai

### <a id="t-0-54b"></a>0.54b zyra-app: sheet "Spotlight is full"
เนื้อหาเต็มอยู่ [0.54 ใน module G](#t-0-54) · ส่วนของ module นี้: `use-spotlight-broadcast.ts` `spotlightStartErrorKey` (`:291-300`) เพิ่ม key ใหม่ · ข้อความใน `messages/en.json` / `th.json` · sheet "Spotlight is full" (ux-ui-plan §18.9)

---

## <a id="mod-e"></a>E. Chat

`views/chat/**`, `lib/api/chat.ts`, `lib/api/chat-ws.ts`, `stores/chat-store.ts` · backend ของแชทอยู่ zyra-api (zyra-ws แค่ relay)

### <a id="t-0-21"></a>0.21 Chat layout มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Chat layout มือถือ** ตาม ux-ui-plan §9.2 — แนวตั้ง stack list → ห้อง + tab All/Channel/Group/DM + chip @You · แนวนอน overlay 2 คอลัมน์ 249/515 ทับแมพ (engine render ต่อ) · คีย์บอร์ดเปิดดันข้อความล่าสุดขึ้นเหนือ input · spinner Reload 16 ตอนโหลดหน้าเก่า · emoji picker เป็น bottom sheet · ไฟล์ที่เอกสารเดิมระบุ — `chat-surface.tsx`, `chat-sidebar.tsx`, `message-list.tsx`, `message-input.tsx`, `emoji-picker.tsx`, `vo-chat-space-overlay.tsx` · ขึ้นกับ (เดิม) — 0.5, 0.14 · Done เมื่อ — ตรง Figma ≥ 95% (5944-134033, 5944-284186, 6580-167869) · พิมพ์แล้วยังเห็นข้อความล่าสุด ทั้ง 2 orientation
- **มีอยู่แล้ว (verified):**
  - `views/chat/chat-surface.tsx` `ChatSurface` รับ `view: "half" | "full"` · half = `w-[320px]` `:294` · full = `flex ... p-[16px]` + คอลัมน์ `w-[320px]` + `flex-1` `:338-353` · Cmd+K `:76-87` · panel สลับด้วย state `groupModalOpen / channelModalOpen / startNewChatOpen / settingsOpen / threadsOpen` `:66-73`
  - mount `hero:381` (dynamic) · `:14043-14068` half `absolute inset-y-0 left-[56px] z-[55]` / full `absolute inset-0 left-[56px] z-[9998]`
  - `chat-sidebar.tsx` `ChatSidebar` `w-[320px]` `:362` · `Section` Channels / Groups / Direct messages (`:171`, `:522-548`) **ยังไม่มีแท็บ All / Channel / Group / DM**
  - `message-list.tsx` `PAGE_SIZE = 30` `:78` · IntersectionObserver `:249` · โหลดหน้าเก่าแสดงแค่ `t("loading")` `:381-383` (ไม่มี spinner)
  - `message-input.tsx` textarea `:575` · Enter ส่ง `:457` (ไม่มี `enterKeyHint` / `isComposing`) · emoji popover portal `:76-80`
  - `emoji-picker.tsx` `variant: "reaction" | "full"` `:17`, `w-[280px]` `:113`, `autoFocus` `:120`, ปิดด้วย mousedown `:58`
- **ต้องแก้:** `chat-surface.tsx` mode มือถือ (แนวตั้ง stack list → ห้อง · แนวนอน 2 คอลัมน์ 249/515) · `chat-sidebar.tsx` แถบแท็บกรองตาม `conv.type` (ใช้ `channels/groups/dms` `:341-343`) · `message-list.tsx:381` spinner Reload 16 · `message-input.tsx` เลื่อนตามคีย์บอร์ด (visualViewport) + emoji เป็น bottom sheet · `hero:14043-14068` wrapper มือถือ (ตอนนี้ fix `left-[56px]`)
- **ไฟล์ใหม่:** `views/chat/components/use-chat-layout.ts` (breakpoint / orientation — ใช้ hook จาก 0.41 / 0.42) · sheet ใช้ `components/bottom-sheet.tsx`
- **ผิดจากเอกสาร:** **`vo-chat-space-overlay.tsx` ไม่ใช่ chat overlay** — คือ `ChatSpaceOverlay` วาดแคปซูลระหว่างเท้าผู้เล่น 2 คน (proximity) · chat overlay จริงอยู่ `hero:14043-14068` · แท็บ All / Channel / Group / DM ยังไม่มี (มีแค่ section พับได้)
- **ขึ้นกับ:** 0.5, 0.14

### <a id="t-0-22"></a>0.22 Long-press, Forward, Select (0.22a zyra-app · 0.22b zyra-api)
> **ข้อความเดิม (Phase 0):** งาน — **Long-press ข้อความ** → overlay blur + ยกข้อความ + Emoji panel 7 + Submenu (tap) · **Forward** (เลือกห้องปลายทาง) + **Select** (multi-select) ทำจริงทั้ง mobile + desktop · ไฟล์ที่เอกสารเดิมระบุ — `message-item.tsx`, `message-context-menu.tsx:65-66`, `emoji-picker.tsx`, zyra-api forward endpoint (ถ้าไม่มี 🔍) · ขึ้นกับ (เดิม) — 0.21, **Figma Forward/Select (ยังไม่มี)** · Done เมื่อ — กดค้าง 500 ms เปิดเมนู ไม่ trigger scroll · Forward ส่งไปห้องอื่นได้ · Select ลบ/copy หลายข้อความได้
- **มีอยู่แล้ว (verified):** `message-item.tsx` action bar เปิดด้วย hover (`isHovered` `:139`, `onMouseEnter/Leave` `:398-399`, portal `:403-515`) ไม่มี touch / long-press / `onContextMenu` · ปิดเมนูเมื่อ scroll `:250` · `message-context-menu.tsx` `MessageContextMenu` Reply / Thread / Copy / Pin / Download / Delete · **Forward `:65` และ Select `:66` เป็น `disabled`** · `emoji-picker.tsx` variant `reaction` มี quick bar 7 emoji (comment `:29`) · `file-preview.tsx:55` มี prop Forward · API `zyra-api/internal/router/router.go:317-364` ไม่มี forward route ไม่มี bulk delete
- **ต้องแก้ (0.22a):** `message-item.tsx` long-press 500ms (pointer events) → overlay blur + ยกข้อความ + `EmojiPicker variant="reaction"` + `MessageContextMenu` · `message-context-menu.tsx:65-66` เปิด Forward / Select ด้วย `onForward` / `onSelect` · `chat-store.ts` state เลือกหลายข้อความ · `message-list.tsx` โหมด select
- **ไฟล์ใหม่:** 0.22a `views/chat/components/forward-message-panel.tsx` + `lib/api/chat.ts` `forwardMessage()` · **0.22b** route `POST /api/user/chat/messages/:id/forward` ใน `router.go` กลุ่ม `chat` + `ChatHandler.ForwardMessage` (`internal/handler/chat_handler.go`) + `ChatService.ForwardMessage` (`internal/service/chat_service.go`) — ทำ FE เรียก `sendMessageREST` ซ้ำไม่ได้ เพราะ attachment ผูกกับ `conversation_id` เดิม (`attachment_service.go:174-177`)
- **ผิดจากเอกสาร:** `message-context-menu.tsx:65-66` ตรง · "forward endpoint (ถ้าไม่มี 🔍)" → ยืนยันแล้วว่าไม่มี ต้องทำ 0.22b
- **ขึ้นกับ:** 0.21, Figma Forward / Select

### <a id="t-0-23"></a>0.23 Preview image มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Preview image มือถือ** — pinch zoom (pointer events) · แตะสลับซ่อน/โชว์ header + filmstrip · zoom แล้วซ่อนอัตโนมัติ · swipe เปลี่ยนรูป · download → บันทึกลง Photos (ขอ permission) · เมนู ⋮ · ไฟล์ที่เอกสารเดิมระบุ — `file-preview.tsx`, `@capacitor/filesystem` + photo permission (B5) · ขึ้นกับ (เดิม) — 0.21, 1.1 · Done เมื่อ — ตรง Figma 6352-633794/633882/633890 · รูปอยู่ใน Photos หลังกด download บนทั้ง iOS/Android
- **มีอยู่แล้ว (verified):** `file-preview.tsx` wheel non-passive `:122` · `mousemove` `:153-156` · `onMouseDown={startDrag}` `:299`, `:406` · filmstrip `:325-345` · download `:258`, `:452` · ปุ่ม download ต่อ thumb ซ่อนจน hover (`group-hover/thumb:flex` `:456`) · `chat-utils.ts:40-62` `downloadRemoteFile` fallback `<a target=_blank>` · `lib/download-blob.ts` `downloadBlob` (blob URL + `<a download>`)
- **ต้องแก้:** `file-preview.tsx` mouse → pointer events + pinch · แตะสลับซ่อน / แสดง header + filmstrip · swipe · เมนู ⋮ · `lib/download-blob.ts` branch native (Filesystem / Photos)
- **ไฟล์ใหม่:** `lib/native/save-photo.ts`
- **ผิดจากเอกสาร:** ยังไม่มี `@capacitor/*` ใน repo — ส่วนบันทึกลง Photos ทำได้หลัง 1.1
- **ขึ้นกับ:** 0.21, 1.1, TD B5

### <a id="t-0-24"></a>0.24 Mention มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Mention มือถือ** — จัดอันดับ 3–4 คนคุยบ่อย (เกณฑ์ OQ 18) + เลื่อนได้ + @Everyone ล่างสุด · แตะเลือกแทน Arrow/Enter · chip @You ใน Chat list · ไฟล์ที่เอกสารเดิมระบุ — `message-input.tsx:84-116`, `message-input-utils.ts`, `chat-sidebar.tsx`, store mention flag · ขึ้นกับ (เดิม) — 0.21 · Done เมื่อ — ตรง Figma 6361-638009 / 6604-180983 · ถูก mention แล้วแถวใน list มี chip
- **มีอยู่แล้ว (verified):** `message-input.tsx:84-116` `mentionSuggestions` (`useMemo`) กรองด้วย prefix handle / username / name · **ใส่ @Everyone บนสุด** · `slice(0, 8)` · **ไม่จัดอันดับคุยบ่อย** · `applyMention` `:118` · คีย์ Arrow / Enter / Tab / Esc `:435-456` · `message-input-utils.ts` `EVERYONE_SUGGESTION`, `activeMentionAt` · `lib/api/chat.ts:124` `NotificationType` มี `"mention"` · `chat-store.ts` **ไม่มี mention flag** · `chat-sidebar.tsx` `ConversationRow` `:78-169` ไม่มี chip @You
- **ต้องแก้:** `message-input.tsx:110-115` Everyone ท้ายสุด + จัดอันดับ + เลือกด้วยแตะ · `chat-store.ts` derive `mentionedConversationIds` จาก notifications `type === "mention"` + `!is_read` (ใช้ `n.conversation_id` แบบ `vo-notification-panel.tsx:194`) · `ConversationRow` แสดง chip
- **ไฟล์ใหม่:** ไม่จำเป็น (อาจแยก `views/chat/components/mention-ranking.ts`)
- **ผิดจากเอกสาร:** "store mention flag" ยังไม่มีให้แก้ ต้องสร้างใหม่ · เกณฑ์จัดอันดับรอ OQ 18
- **ขึ้นกับ:** 0.21

### <a id="t-0-25"></a>0.25 Voice message (0.25a zyra-app · 0.25b zyra-api)
> **ข้อความเดิม (Phase 0):** งาน — **Voice message** (ใหม่ทั้งเส้น) — ปุ่มไมค์อัดเสียงด้วย `MediaRecorder` (ขอ permission mic) → upload S3 → message type `audio` → bubble + player (เล่น/หยุด/ความยาว) ทุก platform รวม desktop · ไฟล์ที่เอกสารเดิมระบุ — `message-input.tsx`, `message-attachment-block.tsx` (ใหม่ audio), zyra-api `chat` service + migration message type, zyra-ws broadcast · ขึ้นกับ (เดิม) — 0.21, **Figma (ยังไม่มี UI)**, rule 11 · Done เมื่อ — อัด → ส่ง → อีกเครื่องเล่นได้ภายใน 3 วิ · ไฟล์อยู่บน R2 ไม่แตะ disk · ยกเลิกระหว่างอัดได้
- **มีอยู่แล้ว (verified):** `message-input.tsx` ไม่มี MediaRecorder / ปุ่ม Mic · file input `:597`, `:606` · `uploadAttachment` (XHR) `lib/api/chat.ts:530` · `message-attachment-block.tsx` `AttachmentBlock` แยกรูป / ไฟล์ด้วย `isImageMime` เท่านั้น · API `zyra-api/internal/service/attachment_service.go:49-61` `allowedMIME` **ไม่มี audio/*** (`resolveMIME` `:276`) · `chat_service.go:999-1009` content type ได้แค่ `text` / `pet_card` / `attachment` · DB CHECK `migrations/92_message_pet_card.sql:12-13` (`text, attachment, system, pet_card`) · zyra-ws `relayChat` ส่ง message แบบ opaque (`zyra-ws/internal/hub/chat.go:77`, `:154`)
- **ต้องแก้:** **0.25b** `attachment_service.go` เพิ่ม `audio/webm`, `audio/mp4`, `audio/mpeg` ใน `allowedMIME` (`http.DetectContentType` อาจ sniff webm / m4a ไม่ได้ → เพิ่ม `extToMIME`) · `chat_service.go` SendMessage ตั้ง content type `audio` · `model/chat.go` `SendMessageRequest` `:123-132` · **0.25a** `message-attachment-block.tsx` audio player · `message-input.tsx` ปุ่มไมค์
- **ไฟล์ใหม่:** 0.25b migration `NNN_message_audio.sql` + `.down.sql` (ALTER CHECK constraint · เลขถัดไป 108 — ข้อเท็จจริงร่วมข้อ 8) · 0.25a `views/chat/components/voice-recorder.tsx`, `audio-message-player.tsx`
- **ผิดจากเอกสาร:** "zyra-ws broadcast" ไม่ต้องแก้ (relay opaque) · migration ล่าสุด `107_*`
- **ขึ้นกับ:** 0.21, Figma, rule 11

### <a id="t-0-26"></a>0.26 Start new chat + Create chat + panel มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Start a new chat + Create chat + panel มือถือ** (แก้ 2026-10-05: เมนู FAB 3 ข้อ Create channel / Create group / Start a new chat ตาม Figma `5944-134262` ไม่มี sheet เลือก) — รายชื่อแสดง Active / Busy / custom status / In meeting · FAB "Create chat" → สร้าง Group / Channel บนมือถือ (OQ 17 ค้างว่า sheet เลือกประเภทหรือไม่) · Thread / info / media panel เป็น full-screen push · ไฟล์ที่เอกสารเดิมระบุ — `start-new-chat-panel.tsx:49-56`, `create-group-modal.tsx`, `thread-panel.tsx`, `conversation-info-panel.tsx`, `conversation-media-panel.tsx` · ขึ้นกับ (เดิม) — 0.21, **Figma create/panel (ยังไม่มี)** · Done เมื่อ — ตรง Figma 5944-274509 · สร้าง channel จากมือถือสำเร็จ · เปิด thread จากเมนู long-press ได้ · **แก้ 2026-10-02 (โน้ต Pai): หน้า New group: header กลาง · รูป + ชื่อเรียงกลาง ไม่มี label · "Search for member" · ไม่มี chip · คนที่เลือกขึ้นบน · "Create group (N)" → ux-ui-plan §19**
- **มีอยู่แล้ว (verified):** `chat-sidebar.tsx` ปุ่ม "+" เปิดเมนู 2 ข้อ Create channel / Create group (`:377-422`) · ปุ่ม Start a new chat แยกท้าย (`:559-571`) · `start-new-chat-panel.tsx:49-56` กรองสมาชิก `status === "confirm"` + ไม่ใช่ตัวเอง **ไม่แสดง presence / custom status / In meeting** · `create-group-modal.tsx` `entity: "group" | "channel"`, `mode: "create" | "edit"` (`:45-47`), `w-[320px]` `:332`, Search `:463-472` (placeholder `searchForMembers`) · `thread-panel.tsx:77` `absolute inset-y-0 right-0 ... w-[320px]` · `conversation-media-panel.tsx:110`, `conversation-info-panel.tsx` overlay กว้าง 320
- **ต้องแก้:** `chat-sidebar.tsx` มือถือรวม "+" กับ Start new chat เป็น FAB 3 ข้อ · `start-new-chat-panel.tsx` เพิ่ม status จาก `onlineUserIds` (ส่ง prop จาก `chat-surface.tsx:280-289`) · `create-group-modal.tsx` layout New group ตาม §19 · thread / info / media panel full-screen push · `message-item.tsx` เปิด thread จากเมนู long-press (ต่อ 0.22)
- **ไฟล์ใหม่:** `views/chat/components/chat-create-fab.tsx`
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** 0.21, 0.22, Figma

### <a id="t-0-27"></a>0.27 DM read receipt ✓ / ✓✓ — มีครบแล้ว เหลือ verify
> **ข้อความเดิม (Phase 0):** งาน — **DM read receipt ✓ / ✓✓** — เช็ค zyra-ws/zyra-api ว่ามี read state ต่อ DM ไหม ถ้าไม่มีเพิ่ม (`read_at` + event `message_read`) แล้วแสดง icon 12 ท้ายข้อความ · ไฟล์ที่เอกสารเดิมระบุ — zyra-api chat service + migration, zyra-ws handler, `message-item.tsx:83` · ขึ้นกับ (เดิม) — 0.21 · Done เมื่อ — อีกฝั่งเปิดห้องแล้วฝั่งส่งเห็น ✓✓ ภายใน 2 วิ · group/channel ยังใช้ reader count เดิม
- **มีอยู่แล้ว (verified) — ครบทั้ง 3 repo:**
  - DB `zyra-api/migrations/52_create_chat_tables.sql:110-115` `tb_user_last_read(last_read_at)`
  - API `chat_service.go:1781` `MarkRead` · `:1469-1488` ตั้ง `Seen` / `ReadCount` · `:1498` `dmCounterpartLastReadFor` · `:1533` `groupMemberLastReadFor` · `model/chat.go:74-81` · route `POST /conversations/:id/read` `router.go:330`
  - WS `zyra-ws/internal/hub/message.go:160` `MsgChatReadReceipt = "chat:read:receipt"` · `:493` `ClientMsgChatRead = "chat:read"` · `chat.go:239` `handleChatRead` · `room.go:706`
  - FE `workspace-ws.ts:633` `relayReadReceipt` · `lib/api/chat-ws.ts:143` · `stores/chat-store.ts:311-337` `recordReadReceipt` · `message-list.tsx:148-155` · `hero:2068-2079` (mark read อีกครั้งเมื่อมีข้อความเข้าในห้องที่เปิด) · `message-item.tsx:202-232` `receiptBadge` (`Check` / `CheckCheck size={12}`)
- **ต้องแก้:** ไม่มีงานหลัก · (ไม่บังคับ) `hero:2076-2078` ย้าย `relayReadReceipt` ไปหลัง `markRead` resolve (ตอนนี้ยิงคู่กันไม่ await)
- **ไฟล์ใหม่:** ไม่มี
- **ผิดจากเอกสาร:** "ถ้าไม่มีเพิ่ม `read_at` + event `message_read`" — มีแล้วในชื่อ `last_read_at` / `chat:read` / `chat:read:receipt` · `message-item.tsx:83` เป็น doc comment ของ `showReadCount` badge จริง `:210-232` · **task เหลือแค่ตรวจ ✓ / ✓✓ บนมือถือ**
- **ขึ้นกับ:** 0.21 (layout)

### <a id="t-0-37"></a>0.37 Chat ส่งไม่ได้: auto-resend (0.37a zyra-app · 0.37b zyra-api)
> **ข้อความเดิม (Phase 0):** งาน — **Chat ส่งไม่ได้** — auto-resend 5 ครั้ง (1/2/4/8/16 วิ) · bubble sending (`LoaderCircle`) → failed (`CircleAlert` + "Not sent · Tap to retry") ค้างใน list · แตะส่งใหม่ · sheet/modal "Message not sent" ปุ่ม Done (icon `WifiOff`) · service ล่มใช้ sheet เดียวกัน · ไม่ทำ offline queue · ไฟล์ที่เอกสารเดิมระบุ — `chat-store.ts`, `message-item.tsx`, `message-input.tsx`, `lib/api/chat*.ts` · ขึ้นกับ (เดิม) — 0.21 · Done เมื่อ — ปิดเน็ต → ส่ง → retry 5 ครั้ง → sheet + bubble failed · เปิดเน็ต → แตะ bubble → ส่งสำเร็จไม่ซ้ำ (idempotency key 🔍)
- **มีอยู่แล้ว (verified):** `chat-store.ts:22-24` `ChatMessage` มี `temp_id` + `status: "sending" | "sent" | "failed"` · `replaceOptimistic` `:276` · `message-input.tsx:337-430` `doSend` optimistic `tempId = crypto.randomUUID()` (`:367`) catch → `failed` (`:424-426`) **ไม่มี retry อัตโนมัติ** thread reply ที่ล้มไม่ถูก mark failed · `message-item.tsx:517-531` ปุ่ม resend (`RotateCw`) · retry ด้วยมือ `dm-panel.tsx:71-96` `onRetry`, `channel-panel.tsx:92` **ส่งแค่ `content`** (attachments / `reply_to_id` / `is_thread_reply` หาย) · API `model/chat.go:123-132` ไม่มี client message id · `chat_service.go:995` `checkRateLimit` (retry 5 ครั้งอาจชน)
- **ต้องแก้:** **0.37a** retry / backoff 1/2/4/8/16s ใน `chat-store.ts` หรือ helper กลาง ใช้ร่วม `dm-panel` / `channel-panel` (ตอนนี้ซ้ำกัน) · `message-item.tsx` `LoaderCircle` / `CircleAlert` + "Not sent · Tap to retry" · **0.37b** `model/chat.go` + `chat_service.go` เพิ่ม `client_msg_id` (idempotency) · ดู rate limit ให้ retry ไม่โดนตัด
- **ไฟล์ใหม่:** 0.37a `views/chat/components/message-send-queue.ts`, `message-not-sent-sheet.tsx` · 0.37b migration `NNN_message_client_id.sql` + `.down.sql` (unique `(sender_id, client_msg_id)` · เลขดูข้อเท็จจริงร่วมข้อ 8)
- **ผิดจากเอกสาร:** `lib/api/chat*.ts` = `chat.ts` + `chat-ws.ts` · "idempotency key 🔍" → ยืนยันแล้วว่ายังไม่มี ต้องทำ 0.37b
- **ขึ้นกับ:** 0.21, 0.36

### <a id="t-0-53"></a>0.53 Chat info มือถือแบบแท็บ
> **ข้อความเดิม (Phase 0):** งาน — **Chat info มือถือแบบแท็บ (Telegram)** (ux-ui-plan §9.8 · โน้ต Pai 2026-10-02) — แตะชื่อห้องที่ header → หน้าเต็มจอ · หัว avatar + ชื่อ + จำนวนสมาชิก · Edit (Owner/Admin → Settings เดิม) · ปุ่ม Mute / Search / Leave (ยืนยันก่อนออก) · แท็บ Members / Media / Files / Links / Threads / Pinned เลื่อนได้และติดบนสุดตอนเลื่อน · Members: Add members + สถานะ presence + ป้าย owner/admin · แตะสมาชิก = action sheet (profile, message, make/remove admin, remove) · DM ไม่มี Members / Leave / Edit · ไฟล์ที่เอกสารเดิมระบุ — ต่อยอด `conversation-info-panel.tsx`, `conversation-media-panel.tsx`, `conversation-menu.tsx`, `use-chat-search.ts` · API เดิม `lib/api/chat.ts` · ไม่มีงาน backend · ขึ้นกับ (เดิม) — 0.21, **frame จาก Pai** · Done เมื่อ — test FE-CHAT-14–17
- **มีอยู่แล้ว (verified):** `conversation-info-panel.tsx` `ConversationInfoPanel` รายชื่อสมาชิก + Mute + เปลี่ยน role (`changeConversationMemberRole`) เฉพาะ owner ของ group (`:41-42`) ปิดด้วย mousedown `:55` · `conversation-media-panel.tsx:23` `MediaTab = "images" | "files" | "links" | "pinned" | "threads"` โหลด `:75-78` · `conversation-menu.tsx` Members / Images / Files / Links / Pin / Threads / Mute / Settings / Leave (`:109-138`) · `channel-panel.tsx` ยืนยันก่อน Leave (`:59`, `:78-82`, `:224-248`) · `use-chat-search.ts:53` `useChatSearch(workspaceId)` ค้นทั้ง workspace (ยังไม่มี scope ต่อห้อง) · API `lib/api/chat.ts:289-401` `addMembers` / `removeMember` / `changeConversationMemberRole` / `leaveConversation` / `listConversationAttachments` / `listConversationLinks` / `listPinnedMessages` / `listConversationThreads`
- **ต้องแก้:** รวม info + media panel เป็นหน้าเต็มจอแท็บ sticky · action sheet ต่อสมาชิก (`removeMember` มีใน API แต่ยังไม่ใช้ใน info panel) · ปุ่ม Search → `useChatSearch` รับ conversation filter (`SearchFilters` `use-chat-search.ts:12`)
- **ไฟล์ใหม่:** `views/chat/components/conversation-info-page.tsx`
- **ผิดจากเอกสาร:** "ไม่มีงาน backend" จริง (search รับ filter ได้ — เช็ค `SearchParams` `chat.ts:195` 🔍)
- **ขึ้นกับ:** 0.21, frame จาก Pai

---

## <a id="mod-f"></a>F. Account / onboarding / profile / settings

`views/login`, `views/signup`, `views/verify`, `views/user/workspace`, `views/user/space-builder`, `views/user/accept-invite`, `views/profile`, `views/maintenance`, `vo-profile-panel.tsx`, `vo-setting-modal.tsx`, `components/auth-guard.tsx`, `lib/auth/session.ts`, `lib/api/client.ts`

### <a id="t-0-30"></a>0.30 Profile tab + หน้าย่อย Setting
> **ข้อความเดิม (Phase 0):** งาน — **Profile tab + หน้าย่อย Setting** — การ์ด status (Active/Busy/Away/**Do not disturb** + custom status — DND เพิ่มตาม Ten 2026-10-01) · เมนู Setting (Account and Security = `/setting` + change-password, Language, Audio, Camera, Notification) · Workspace (Manage member + Environment เฉพาะ Owner/Admin, Workspace mode → 0.12) · Support (Help, Legals) · Switch workspace / Log out · ตัด tab general/integrations บนมือถือ · แนวนอน = modal ทับแมพ · ไฟล์ที่เอกสารเดิมระบุ — `vo-profile-panel.tsx`, `vo-setting-modal.tsx`, `views/profile/*`, `lite/profile-tab.tsx` (ใหม่) · ขึ้นกับ (เดิม) — 0.14, 0.12, **Figma หน้าย่อย (ยังไม่มี)** · Done เมื่อ — ตรง Figma 6668-244816 · Member ไม่เห็น Manage member/Environment · เปลี่ยนภาษา/ไมค์/กล้องมีผลทันที
- **มีอยู่แล้ว (verified):** `vo-profile-panel.tsx` `AvailabilityStatus` มี `"dnd"` (`:9`) แต่ `STATUS_PILLS` `:11-15` มี 3 ตัว (ไม่มี DND) · props `onEditProfile / onChangeAvatar / onBackToWorkspace / onLogout` `:120-134` · `w-[322px]` `:246` · backend รับ `dnd` แล้ว (`zyra-api/internal/service/profile_service.go:612-613`) · `vo-setting-modal.tsx` `SettingTab` `:719-720` (`profile, general, audio, notifications, manage, integrations, environment`) · `NAV_ITEMS` `:722-737` · layout `w-[934px] h-[800px]` `:911` · `LanguageRow` `:554` · **ไม่มีแท็บ Camera** (อุปกรณ์อยู่ `vo-device-switch-modal.tsx`, `vo-media-device-menu.tsx`) · environment กรองตามบทบาทแล้ว `:832` · `views/profile/components/profile-sidebar.tsx:18-20` (`/setting`, `/setting/change-password`, billing comingSoon) · `views/change-password/hero-change-password.tsx`
- **ต้องแก้:** pill DND ใน `STATUS_PILLS` · ซ่อนแท็บ general / integrations บนมือถือ · ซ่อน Manage member / Environment จาก Member · แถว Workspace mode → 0.15
- **ไฟล์ใหม่:** `views/user/virtual-office/lite/profile-tab.tsx` + หน้าย่อย Language / Audio / Camera
- **ผิดจากเอกสาร:** "Camera" ยังไม่มีแท็บใน setting modal (ต้องสร้าง)
- **ขึ้นกับ:** 0.14, 0.12, 0.15

### <a id="t-0-31"></a>0.31 Space builder มือถือ (0.31a zyra-app · 0.31b zyra-api)
> **ข้อความเดิม (Phase 0):** งาน — **Space builder มือถือ** ตาม ux-ui-plan §11.2 — Empty / Fill / ค้นหา (highlight + not found) · การ์ด ⋮ ตามบทบาท (ไม่มี editor/Delete) · Profile menu · filter sheet (All/My/Shared + Sort) · Save → skeleton ไม่มี text · แนวตั้งอย่างเดียว · ไฟล์ที่เอกสารเดิมระบุ — `hero-user-workspace.tsx`, `workspace-card.tsx`, `components/ui/skeleton.tsx`, zyra-api copy permission (ถ้าให้ Member copy) · ขึ้นกับ (เดิม) — 0.28 · Done เมื่อ — ตรง Figma 6411-1141322, 5833-1005970, 5840-1014307 · Member เห็นเมนู Enter/Copy/Leave และ copy สำเร็จ · **แก้ 2026-10-02 (โน้ต Pai): เมนู ⋮ ไม่มี Workspace editor · เปิด URL หน้า desktop-only → มาหน้านี้ + toast → ux-ui-plan §19**
- **มีอยู่แล้ว (verified):** `hero-user-workspace.tsx` แท็บจาก query `all` / `my` / `shared` (`:78-89`) · search debounce `:200-217` · sort `:202-203` · mousedown `:226`, `:237` · `h-[calc(100vh-72px-32px)] min-h-[600px]` `:301` · callback การ์ด `:478-483` (`onOpenEditor` → `/workspace/builder/${id}`) · `workspace-card.tsx` `WorkspaceContextMenu` `:104-200` (Enter ทุกบทบาท · Copy / Editor / Manage เฉพาะ Owner/Admin `:154-165` · Delete เฉพาะ owner `:176` · Leave เฉพาะ member `:191`) · `WorkspaceCardSkeleton` `:47` · mousedown `:248` · `components/ui/skeleton.tsx` มีจริง (ใช้ได้ตาม rule 08) · API `zyra-api/internal/handler/workspace_handler.go:669-695` `CreateUserWorkspace` → `workspace_service.go:2217` `CloneWorkspaceFromTemplate` **ไม่ตรวจ membership / role ของ source** ตรวจแค่มี map published (`:2225-2238`)
- **ต้องแก้:** **0.31a** เมนูการ์ดมือถือ เอา Workspace editor / Delete ออก + Member เห็น Copy · หน้า desktop-only → redirect มาหน้านี้ + toast (ยังไม่มีกลไกใน `proxy.ts`) · **0.31b** zyra-api ตรวจสิทธิ์ copy (เป็นสมาชิก หรือเป็น template ที่ published) — **ต้องทำไม่ว่าจะให้ Member copy หรือไม่** (ตอนนี้ใครที่ login แล้ว clone workspace ไหนก็ได้ที่มี map published จำกัดสิทธิ์แค่ฝั่ง FE)
- **ไฟล์ใหม่:** 0.31a `views/user/workspace/components/workspace-filter-sheet.tsx` · 0.31b test ใน `internal/service/workspace_service_test.go` 🔍
- **ผิดจากเอกสาร:** "zyra-api copy permission (ถ้าให้ Member copy)" ไม่ใช่เรื่อง "ถ้า" — backend ไม่ตรวจสิทธิ์เลย
- **ขึ้นกับ:** 0.28

### <a id="t-0-32"></a>0.32 Create workspace มือถือ 3 step
> **ข้อความเดิม (Phase 0):** งาน — **Create workspace มือถือ 3 step** — template grid 2 คอลัมน์ + filter (Capacity range slider 0–1,000 เฉพาะมือถือ, Category) → details (ชื่อ, อ่านอย่างเดียว) → Workspace created → Enter Workspace ไป Select workspace mode (Lite ข้าม welcome / Spatial ผ่าน welcome) · ไฟล์ที่เอกสารเดิมระบุ — `create-workspace-modal.tsx` (แยก layout มือถือ), `lite/create-workspace/*` (ใหม่) · ขึ้นกับ (เดิม) — 0.31, 0.15 · Done เมื่อ — ตรง Figma 5878-409509 → 5878-414845 · สร้างจากมือถือแล้วเข้า workspace ได้ทั้ง 2 โหมด
- **มีอยู่แล้ว (verified):** `views/user/space-builder/components/create-workspace-modal.tsx` type `CreateWorkspaceModalStep = "gallery" | "detail"` (`:29`) แต่ข้างในมี step `"done"` (`:219`) · `CapacityFilter` ค่าตายตัว (`:48-60`) ไม่ใช่ slider · กรอง category `:93`, `:165-176` · Enter → `router.push('/workspace/${id}')` (`:232`) · เปิด builder `:237` · `views/user/space-builder/hero-welcome-space.tsx`
- **ต้องแก้:** layout มือถือ (`w-[900px]` `:271`) · capacity → range slider 0–1000 · Enter → หน้า Select workspace mode (0.15)
- **ไฟล์ใหม่:** `views/user/virtual-office/lite/create-workspace/*` (หรือ `views/user/space-builder/components/` ตาม convention 🔍 ตัดสินตอนทำ)
- **ผิดจากเอกสาร:** ยังไม่มีหน้า Select workspace mode / concept workspace mode ในโค้ด
- **ขึ้นกับ:** 0.31, 0.15

### <a id="t-0-34"></a>0.34 Notification settings มือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Notification settings มือถือ** ตาม ux-ui-plan §12.2 — แนวตั้งคง bottom nav · แนวนอนเต็มจอ · 6 กลุ่ม 19 แถว **แถวละ 2 สวิตช์ (in-app + push)** (เพิ่ม Hide/Mute chat ระหว่างประชุม, Pet sounds, Environment sounds) · กลุ่ม Calendar ซ่อนจนมี feature · state ยังไม่อนุญาต = banner + "Allow notifications" (request หรือเปิด Settings เครื่อง) · Profile แนวนอนเพิ่มกลุ่ม Workspace · **ซ่อนกลุ่ม Calendar** จนกว่าจะมี feature (Ten 2026-10-01) · ไฟล์ที่เอกสารเดิมระบุ — `vo-setting-modal.tsx` (`NOTIFICATION_SECTIONS`), `lite/notification-settings.tsx` (ใหม่), `@capacitor/push-notifications` · ขึ้นกับ (เดิม) — 0.30, 2.5, **Figma state ขอ Allow (ยังไม่มี)** · Done เมื่อ — ตรง Figma 6436-67120 / 6610-256229 · ปฏิเสธแล้วกดปุ่ม → ไปหน้า Settings ของเครื่อง → กลับมา banner หายเมื่ออนุญาต · **แก้ 2026-10-02 (โน้ต Pai): สวิตช์เดียวต่อแถว 48×24 + คำอธิบาย ตาม Figma 6436-67120 · 4 แถวใหม่มีคำอธิบาย → ux-ui-plan §19**
- **มีอยู่แล้ว (verified):** `vo-setting-modal.tsx:266-421` `NOTIFICATION_SECTIONS` 5 กลุ่ม 19 แถว — Messages 3 · Meeting & Circle 8 (มี `hide_chat_in_meeting`, `silence_chat_during_meetings` แล้ว) · **Calendar 5 ยังไม่ตั้ง `hidden`** · Pet 2 (`hidden: !isRoomPetEnabled()`, มี `pet_sound` แล้ว) · Activities 1 · Environment sounds ย้ายไปแท็บ Audio แล้ว (`EnvironmentSoundRow` `:203`) · `VISIBLE_NOTIFICATION_SECTIONS` `:423` · `NotificationsTab` `:432` **สวิตช์เดียวต่อแถว** (`ToggleRow` `:55`) · `stores/notification-settings-store.ts` `hydrate` / `setAndPersist` · `lib/api/profile.ts:373-430` `NotificationSettings` GET / PATCH `/api/user/me/notification-settings` · API `router.go:149-150`, `profile_handler.go:330`, `:353`, `profile_service.go:529`, `:553`, `model/auth.go:215`
- **ต้องแก้:** **หลักคือใส่ `hidden: true` ให้กลุ่ม Calendar (`:343`)** + layout มือถือ + state ขอ Allow · ถ้าสวิตช์ต่อแถวคุม push ต้องได้ field `push_*` จาก 2.5a
- **ไฟล์ใหม่:** `views/user/virtual-office/lite/notification-settings.tsx`
- **ผิดจากเอกสาร:** เนื้อ task มีทั้ง "2 สวิตช์ต่อแถว" และ "สวิตช์เดียว" (แก้ 2026-10-02) ขัดกันเอง → ยึดมติล่าสุด **สวิตช์เดียวต่อแถว = push** (ux-ui-plan §19) · "เพิ่ม Hide/Mute chat, Pet sounds, Environment sounds" มีในโค้ดแล้วทั้งหมด · โค้ดเป็นสวิตช์เดียวอยู่แล้ว
- **ขึ้นกับ:** 0.30, 2.5

### <a id="t-0-55b"></a>0.55b zyra-app: หน้า Delete account
เนื้อหาเต็มอยู่ [0.55 ใน module H](#t-0-55) · ส่วนของ module นี้: แถว Delete account ใน Account and Security · หน้า `app/setting/delete-account/page.tsx` → `views/profile/hero-delete-account.tsx` (หรือ `views/profile/components/delete-account-*.tsx`) · `lib/api/profile.ts` `deleteMyAccount()`, `getDeletionPreview()` · หลังลบ `clearSession` → Get started (ยังไม่มี route — 0.56)

### <a id="t-0-56"></a>0.56 Session หลุดบนมือถือ
> **ข้อความเดิม (Phase 0):** งาน — **Session หลุดบนมือถือ** (ux-ui-plan §21.1) — ใช้ 3 แบบเดิมของเว็บ (expired toast · `/signed-out` · dialog Password changed) แต่พาไป Get started แทน `/login` · หน้า signed out แบบมือถือ · ถ้าอยู่ใน meeting / Spotlight ให้ออกก่อน (disconnect LiveKit + ws) · ลบ push token ของเครื่อง · ไฟล์ที่เอกสารเดิมระบุ — `lib/api/client.ts`, `lib/auth/session.ts`, `views/login/hero-session-ended.tsx`, `components/auth-guard.tsx` · ขึ้นกับ (เดิม) — 1.1, **frame จาก Pai** · Done เมื่อ — test FE-CONN-12
- **มีอยู่แล้ว (verified):** `lib/api/client.ts:12-33` `handleUnauthorized` — `session_revoked` → `/signed-out` · กรณีอื่น → toast **hardcode** "Session expired — please log in again" แล้ว `/login?redirect_url=` · `lib/auth/session.ts` `refreshAccessToken` `:217` (reason `password_changed` / `session_revoked`), `checkSessionState` `:258`, `clearSession(reason)` `:343-360` · `components/auth-guard.tsx` `PUBLIC_PATHS` `:24-36`, poll 30s / 10s, dialog "Password changed" (**hardcode ไม่ผ่าน i18n**), redirect `/login` · `views/login/hero-session-ended.tsx` (`Link href="/login"`) · `app/signed-out/page.tsx`
- **ต้องแก้:** redirect เป็น Get started เฉพาะ native ใน `client.ts:28-29`, `auth-guard.tsx:75-87, 116-125, 155-158`, `hero-session-ended.tsx` · `clearSession` disconnect ws / LiveKit + ลบ push token (ต้องเรียก DELETE ก่อน `setAccessToken(null)` — ดู 1.8)
- **ไฟล์ใหม่:** layout มือถือของหน้า signed-out
- **ผิดจากเอกสาร:** ยังไม่มีหน้า / route "Get started" ในโค้ด
- **ขึ้นกับ:** 1.1, 1.8

### <a id="t-0-58"></a>0.58 หน้าปิดปรับปรุงบนมือถือ
> **ข้อความเดิม (Phase 0):** งาน — **หน้าปิดปรับปรุงบนมือถือ** (ux-ui-plan §21.3) — ใช้ `/maintenance` เดิม layout มือถือ · ปุ่ม Try again แทน Back to Homepage · ไม่ซ้อนกับ UI offline / reconnecting · ไฟล์ที่เอกสารเดิมระบุ — `views/maintenance/hero-maintenance.tsx`, `proxy.ts` · ขึ้นกับ (เดิม) — 0.36 · Done เมื่อ — test FE-CONN-13
- **มีอยู่แล้ว (verified):** `views/maintenance/hero-maintenance.tsx` `HOMEPAGE_URL = "https://zyra.center/"` ปุ่ม `backToHomepage` `max-w-[458px]` · `proxy.ts` `MAINTENANCE_PATH` `:16`, `maintenanceEnabled` `:95`, redirect `:233-237` · `auth-guard.tsx` poll 10s → `window.location.replace("/maintenance")` · `lib/api/maintenance.ts` `getMaintenanceStatus`
- **ต้องแก้:** ปุ่ม Try again (เรียก `getMaintenanceStatus` ซ้ำ) แทนปุ่ม homepage บน native · กันซ้อนกับ `vo-connection-toast.tsx`
- **ไฟล์ใหม่:** ไม่มี
- **ผิดจากเอกสาร:** —
- **ขึ้นกับ:** 0.36

### <a id="t-0-60"></a>0.60 Deep link 4 กรณี + error ตอน login
> **ข้อความเดิม (Phase 0):** งาน — **deep link 4 กรณี + error ตอน login** (ux-ui-plan §22.2–22.3) — เก็บ redirect หลัง login · หน้ารับคำเชิญมือถือ (`views/user/accept-invite`) · หน้า "This link is no longer available" · error รหัสผิด / อีเมลยังไม่ยืนยัน (sheet → OTP) / เน็ตหลุด · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `views/login/*`, `views/user/accept-invite/*`, Capacitor App URL listener (B4) · ขึ้นกับ (เดิม) — 1.1, **frame จาก Pai** · Done เมื่อ — test FE-EDGE-04, FE-ONB-16
- **มีอยู่แล้ว (verified):** `views/login/components/card-login.tsx` `afterLogin` รับเฉพาะ same-origin `:112-131` · ยังไม่ยืนยันอีเมล (`response.id`) → `router.push('/verify/${id}')` ทันทีไม่มี sheet (`:188-191`) · รหัสผิด / attempts `:193-201` · locked `:173-179` · blocked `:181-186` · network error มีแค่ track (`session.ts:196`) · `views/user/accept-invite/hero-accept-invite.tsx` สถานะ `checking / unauthenticated / success / expired / capacity_full / wrong_email / error` · สร้าง `redirectUrl` `:143` · bounce `/login?redirect_url=…` `:179,192` · การ์ด `w-[458px]` `:68` · `app/join/[token]/page.tsx` · `views/verify/hero-verify.tsx` OTP 6 ช่อง `maxLength={1}` `:536-537` ไม่มี `autoComplete="one-time-code"`
- **ต้องแก้:** **`proxy.ts:5-15` `PUBLIC_PATHS` ไม่มี `/join`** (`auth-guard.tsx:32` มี) → คนที่ยังไม่ login ถูกส่งไป `/login` ก่อนเห็นสถานะ `unauthenticated` · `card-login.tsx` sheet อีเมลยังไม่ยืนยัน + กรณีเน็ตหลุด
- **ไฟล์ใหม่:** `views/user/accept-invite/hero-link-unavailable.tsx` · listener `appUrlOpen` อยู่ 1.9 (`lib/native/deep-link.ts`) · `public/.well-known/` อยู่ 1.9
- **ผิดจากเอกสาร:** —
- **ขึ้นกับ:** 1.1, 1.9

### <a id="t-0-61"></a>0.61 หน้าแก้โปรไฟล์ + เลือกตัวละคร
> **ข้อความเดิม (Phase 0):** งาน — **หน้าแก้โปรไฟล์ + เลือกตัวละคร** (ux-ui-plan §22.3) — แก้รูป (S3) / ชื่อ / custom status · grid ตัวละครจาก `/api/user/avatars` + `lib/avatar-selection.ts` · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `views/profile/*`, `views/user/workspace-enter/*` · ขึ้นกับ (เดิม) — **frame จาก Pai** · Done เมื่อ — test FE-LITE-17
- **มีอยู่แล้ว (verified):** `views/profile/hero-profile.tsx` `HeroProfile` `:92` (draft name / lastname / display_name / bio · `updateProfile` `:236`) · `upload-avatar-modal.tsx`, `delete-avatar-modal.tsx`, `profile-form.tsx` · `lib/api/profile.ts` `uploadAvatarTemp` `:96`, `uploadAvatar` `:158`, `updateUserStatus` `:123` · backend `profile_service.go:347` `UploadAvatar` → S3 `UploadJPEG` · **`UploadAvatarTemp` เขียนลง disk** (`os.MkdirAll` `:239`, serve `router.go:71` `/profile-file`) — เป็นข้อยกเว้น `TempAvatarDir` ที่ rule 11 ยอม · ตัวละคร `lib/avatar-selection.ts` (`AVATAR_SELECTION_KEY = "zyra_selected_avatar"`, `saveSelectedAvatar`, `loadSelectedAvatar`, `saveCharacterName`) · `lib/api/avatars.ts:108` `listAvatarsForUser` → `/api/user/avatars` · `:133` `setMyAvatarSelection` → `PUT /api/user/me/avatar-selection` · route `router.go:157-161` · `views/user/workspace-enter/components/change-character-modal.tsx` (`w-[820px]`, `grid-cols-5`, `useUserAvatars`)
- **ต้องแก้:** layout มือถือ `change-character-modal.tsx` + หน้าแก้โปรไฟล์ (custom status ผ่าน `updateUserStatus`)
- **ไฟล์ใหม่:** `views/user/virtual-office/lite/edit-profile.tsx`, `lite/character-picker.tsx`
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** frame จาก Pai

### <a id="t-2-5b"></a>2.5b zyra-app: UI สวิตช์ push
เนื้อหาเต็มอยู่ [2.5 ใน module H](#t-2-5) · ส่วนของ module นี้: `lib/api/profile.ts:373-435` type + default `push_*` · `stores/notification-settings-store.ts:39-62` · UI `NOTIFICATION_SECTIONS` ใน `vo-setting-modal.tsx` (ร่วมกับ 0.34)

---

## <a id="mod-g"></a>G. zyra-ws

`zyra-ws/internal/hub/*`, `internal/handler/handler.go`, `internal/store/redis.go`

### <a id="t-0-16"></a>0.16 Ghost client `client_mode: "lite"` (0.16a zyra-ws · 0.16b zyra-app WS client → [C](#t-0-16b) · 0.16c hero → [B](#t-0-16c))
> **ข้อความเดิม (Phase 0):** งาน — **zyra-ws ghost client** — join ด้วย `client_mode: "lite"` ไม่มี position/seat, ปฏิเสธ move/input, presence online · เข้า meeting/zone ด้วย id (ไม่ต้องเดิน) · ghost **ไม่มี avatar บนแมพจนกว่าจะเข้า meeting** → broadcast `ghost_join_zone` ให้ client อื่น animate avatar โผล่ที่ spawn แล้วเดินไปห้อง (TD §16.2 ทาง ก) · ออก meeting → avatar หาย · `join_request`/approve สำหรับห้องล็อก · ไฟล์ที่เอกสารเดิมระบุ — zyra-ws `internal/hub/*.go`, `room.go` · zyra-app `lib/api/workspace-ws.ts`, `hero-virtual-office.tsx` (แยก join ออกจาก scene ready) · ขึ้นกับ (เดิม) — — · Done เมื่อ — Lite user เข้า meeting แล้วคน desktop เห็นเป็น tile · ไม่มี avatar บนแมพ · unit test hub ≥ 80%
- **มีอยู่แล้ว (verified):**
  - **join ส่งข้อมูลทาง query string ไม่มี hello / join payload:** `internal/handler/handler.go:130-194` (`Connect`) อ่าน `workspace_id, token, avatar_url, character_name, nickname, capacity, tile_x, tile_y, client_session_id, floor_id, spawn_override` → `hub.Join` (`hub.go:186-309`) → `Room.register` (`room.go:220-406`) · ไม่มี field mode
  - ไม่ส่ง tile = 0,0 (`handler.go:184-186`) · restore ตำแหน่งจาก Redis เฉพาะ `lastFloor == floorID` (`hub.go:230-244`)
  - `register` ใส่ client ลง AOI ทันที (`room.go:268`) · `welcome.players` ส่งทั้ง workspace (`:257`) · broadcast `joined` ทุกคน (`:392-394`)
  - `Client` struct `client.go:27-292` (`MediaRoomID` `:124`, `FloorID` `:129`) · `Player()` `:295-327` · DTO `Player` `message.go:200-226` ยังไม่มี mode / ghost flag
  - **client วาด player ที่ไม่มี floor_id เป็น floor เดียวกัน** (`hero:890` `!p.floor_id || …`) → ghost ที่ไม่ส่ง floor โผล่บนแมพที่ 0,0
  - dispatch `room.go:632-759` · handler ที่ต้องปฏิเสธ ghost: `handleMove` `room.go:891` · `handleMoveTo` `:1251` · `handleStop` `:1426` · `handleInput` `movement_v2.go:122` · `handleGoto` `movement_v2.go:304` · `handleFollow` `room.go:2165` · `handlePetFollow` `pets.go:2017` · `handleVisibility` `room.go:2319` (`forceSync "visibility_resume"` `:2341`)
  - seat ผูกกับ sit ใน `handleMove` เท่านั้น (`claimSeat` `:786`, `releaseSeat` `:801`, `applySit` `:831`) → ghost ไม่มี seat อยู่แล้ว
  - **การเข้า zone:** `room_enter` → `handleRoomEnter` `room.go:1925-1945` ไม่ตรวจตำแหน่ง แค่ตั้ง `RoomID` (ขอบเขต broadcast ของ move) · zyra-app ไม่เคยเรียก `enterRoom()` (`workspace-ws.ts:867`) · **`ws:room:enter` → `handleMediaRoomEnter` `audio.go:123-213` ตรวจตำแหน่ง: zone ที่รู้จักแต่ tile ไม่อยู่ในโซน → `forceSync("zone_claim_rejected")` (`:144-149`) → ghost เข้าไม่ได้** · `chat_space:zone` `room.go:3283` ตรวจ + force_sync (`:3299-3301`) · `section_sync` `:3117` ตรวจเงียบ (`:3129`) · `meeting_chat:join` `meetingchat.go:42` ไม่ตรวจ
  - บล็อก Bug #50 (`audio.go:190-212`) re-broadcast `moved` ด้วย tile ผู้เข้าห้อง → ghost จะส่ง 0,0 ให้สมาชิกห้อง
  - ตรวจตำแหน่ง: `zoneClaimTileOK` `room.go:2952` · `zoneTypeClaimTileOK` `:2963` · `zoneClaimTileMatches` `:2934`
  - **ห้องล็อกใช้ knock ได้เลย ไม่ต้องเพิ่ม `join_request`:** `handleKnock` `room.go:2504-2583` · `handleKnockDecide` `:2585-2656` · `handleKnockCancel` `:2661-2706` · register กู้ `pending_knocks` / `active_knock_requests` (`:311-336`)
  - zyra-api ออก LiveKit token ห้องประชุมโดยเช็คแค่ zone อยู่ใน workspace ไม่เช็คตำแหน่ง (`zyra-api/internal/handler/media_handler.go:177-178`)
  - zyra-app: client สร้างใน store (`stores/vo-session-store.ts:417-429`) เรียกจาก `hero-workspace-loading.tsx:493-512` · constructor `WorkspaceWSClient` พารามิเตอร์ตามลำดับ (`lib/api/workspace-ws.ts:180-201`) URL `:248-275`
- **ต้องแก้ (0.16a zyra-ws):**
  - `handler.go Connect` อ่าน `client_mode` · `hub.go Join` เพิ่มพารามิเตอร์ ตั้งค่าบน `Client` ข้าม Redis restore · `client.go` เพิ่ม `ClientMode` (หรือ `IsGhost`) · `Player()` ใส่ flag + zone ของ ghost
  - `message.go Player` เพิ่ม `client_mode` / `ghost_zone_id` + const `MsgGhostJoinZone = "ghost_join_zone"` (+ คู่ตอนออก)
  - `room.go register` ghost ไม่ลง AOI (`:268`) · `handleClientMessage` ปฏิเสธ move / move_to / stop / input / goto / follow / pet_follow จาก ghost · `handleVisibility` ห้ามส่ง forceSync ให้ ghost
  - `audio.go handleMediaRoomEnter` ghost ข้ามตรวจ tile (`:144-149`) ไม่ re-broadcast `moved` (`:190-212`) แต่ broadcast `ghost_join_zone` ทั้ง workspace · `handleMediaRoomLeave` / `removeFromAudioRoom` (`:659`) ส่ง event ghost ออก
  - `room.go unregister` (`:506`) ghost ไม่บันทึก last position
  - ข้อมูลห้องประชุมระดับ workspace (ใส่ `MediaRoomID` ใน Player หรือ broadcast enter/leave) ให้ Lite ทำการ์ด In meeting (0.14)
  - **Circle (`chatspace.go`):** ghost ทุกคนอยู่ 0,0 + floor "" เหมือนกัน → ถูกจับเป็น circle เดียวกันใน step 2 (`:509-571`) → ต้องไม่ใส่ ghost ใน `snapshotChatPositions` (`:272-304`)
- **ต้องแก้ (0.16b / 0.16c):** ดู [C 0.16b](#t-0-16b) · [B 0.16c](#t-0-16c)
- **ไฟล์ใหม่:** `internal/hub/lite_client.go` + `lite_client_test.go` (ชื่อนี้เพราะมี `ghost_state_test.go` อยู่แล้ว = ghost จาก reconnect คนละเรื่อง) · helper test ใช้ของเดิม `newTestRoom` / `newTestClient` / `drain` / `encodePayload` (`room_status_test.go:13-84`), `zoneSetFixture` (`zone_validation_test.go:15`)
- **ผิดจากเอกสาร:**
  - TD §16.2 บอก join ผูกกับ `sceneReady` (`hero:512-520`) — **จริง join เกิดใน `/loading`** (`hero-workspace-loading.tsx:493` → `vo-session-store.ts:429`) · hero แค่ redirect ไป `/loading` ถ้ายังไม่มี client (`hero:2311-2315`) · `sceneReady` (`:514`) คุมแค่ effect ฝั่ง render
  - **"เข้า meeting ด้วย id" ทำไม่ได้ตอนนี้** — `ws:room:enter` ปฏิเสธด้วย tile check (`audio.go:144`)
  - ทาง (ก) ใช้ไม่ได้ถ้า server ไม่เก็บ zone ของ ghost — TD บอก "เครื่องที่เข้ามาทีหลังเห็น avatar อยู่ในห้องเลย" แต่ welcome / joined ส่งแค่ tile → ต้องใส่ `ghost_zone_id` ใน Player
  - แถว 0.16 เขียน "`join_request` / approve" — ยึด knock ตามโค้ดจริง (TD แก้แล้ว 2026-10-02)
  - TD §16.2 ไม่ได้บอกว่า maintenance ของ circle จะเตะ ghost (ดู 0.59)
- **ขึ้นกับ:** — (ฐานของ 0.14, 0.48, 0.59)

### <a id="t-0-48"></a>0.48 Lite เริ่ม Spotlight โดยไม่ตรวจตำแหน่ง (0.48a zyra-ws · 0.48b zyra-api → [H](#t-0-48b) · 0.48c zyra-app → [D](#t-0-48c))
> **ข้อความเดิม (Phase 0):** งาน — **zyra-ws: Lite เริ่ม Spotlight ไม่ตรวจตำแหน่ง** — `client_mode: "lite"` ส่ง `ws:spotlight:start` ได้โดยไม่ต้องยืนบน tile · floor แรก + marker แรก · broadcast ghost เดินไป marker (กลไก 0.16) · table-driven test · ไฟล์ที่เอกสารเดิมระบุ — zyra-ws `internal/hub/spotlight.go` (+ `spotlight_test.go`) · ขึ้นกับ (เดิม) — 0.16 · Done เมื่อ — Lite เริ่มได้ · desktop เห็น avatar เดินไป marker · Spatial/desktop ยังถูกตรวจตำแหน่งเหมือนเดิม
- **มีอยู่แล้ว (verified):** `handleSpotlightStart` `spotlight.go:89-177` — ต้องมี `c.FloorID` (`:99-102`) ไม่งั้น "no floor" · ตรวจตำแหน่ง `:109-123` (`zoneTypeClaimTileOK(c,"spotlight")`) ไม่ผ่าน = **"not on a spotlight tile"** (`:121`) · state ต่อ floor `spotlightFloors[floorID][userID]` (`:131-155`) · payload มีแค่ `Notify` (`message.go:1391-1393`) **ไม่มี `arrived`** · `SpotlightSpeaker` `{UserID, Name, Disconnected}` (`message.go:1289-1297`) **ไม่ผูก speaker กับ marker** · `store.ZoneInfo{ZoneType, Tiles}` (`store/redis.go:714-724`) **ไม่มี `map_id` ไม่มีลำดับ** · zyra-api ส่งโซนทุก floor รวมกัน (`zyra-api/internal/service/map_zone_service.go:105-140`, `internal/cache/zones.go:21-25`) · TODO ยอมรับไว้แล้ว `spotlight.go:428-431` · state ส่งเฉพาะ floor เดียวกัน (`broadcastExceptOnFloor` `room.go:2776`) → Lite ไม่มี floor = ไม่ได้ state · test `TestHandleSpotlightStart` table-driven (`spotlight_test.go:250`) · client `use-spotlight-broadcast.ts:282-300` แปลง "not on a spotlight tile" → `spotlightStartNotOnTile` · `deriveSpotlightSpeakerAction` (`:308-320`) ต้องการ `onSpotlightTile && arrived`
- **ต้องแก้:** **0.48a** `spotlight.go handleSpotlightStart` lite ข้าม `:109-123` → เลือก floor แรก + marker แรก (ใช้ `map_id` + sort key จาก 0.48b) → ส่ง `ghost_join_zone` ด้วย zone id ของ marker · `store/redis.go:714-731` `zoneGeometryJSON` / `ZoneInfo` เพิ่ม `map_id` (+ sort) · `ClientSpotlightStartPayload` เพิ่ม `zone_id` / `floor_id` (optional — ทางเลือกคือให้ Lite ส่งมาเอง) · Lite ต้องมี `FloorID` (ตอน connect หรือ start) ไม่งั้น "no floor" · ให้ Lite ได้ state spotlight แม้ไม่มี floor · **0.48b / 0.48c** ดูลิงก์บนหัวข้อ
- **ไฟล์ใหม่:** ไม่มี · เพิ่ม case ใน `spotlight_test.go`
- **ผิดจากเอกสาร:** TD §16.9 พูดถึง "`arrived`, error `spotlightStartNotOnTile`" เหมือนเป็นของ server — ทั้งคู่อยู่ zyra-app (`use-spotlight-broadcast.ts:283,294`) ฝั่ง server คือข้อความ "not on a spotlight tile" · **"floor แรก + marker แรก" ทำใน zyra-ws ตอนนี้ไม่ได้** เพราะไม่รู้ว่าโซนไหนอยู่ floor ไหน → zyra-api ต้องเพิ่ม `map_id`
- **ขึ้นกับ:** 0.16 · 0.48b

### <a id="t-0-54"></a>0.54 Spotlight เต็ม (0.54a zyra-ws · 0.54b zyra-app → [D](#t-0-54b))
> **ข้อความเดิม (Phase 0):** งาน — **zyra-ws: Spotlight เต็ม** (ux-ui-plan §18.9 ข้อ 7) — Lite เริ่มที่จุด Spotlight ที่ว่างจุดแรกของชั้น (เดิมจุดแรกเสมอ) · ทุกจุดมีคนพูดแล้ว → ปฏิเสธ `ws:spotlight:start` ด้วย error เฉพาะ ให้ client ขึ้น sheet "Spotlight is full" · table-driven test · ไฟล์ที่เอกสารเดิมระบุ — zyra-ws `internal/hub/spotlight.go` + test · ขึ้นกับ (เดิม) — 0.48 · Done เมื่อ — test BE-WS-15 · FE-SPOT-18
- **มีอยู่แล้ว (verified):** speaker set ต่อ floor ไม่มีข้อมูล marker (`message.go:1289-1297`, `spotlight.go:131-141`) · marker แต่ละอัน = แถว `tb_map_zone` `zone_type = "spotlight"` (`zyra-api/internal/model/map_zone.go:13`) · `HasZoneType` (`store/redis.go:781-795`) ตอบได้แค่ว่ามีโซนชนิดนี้ไหม · `spotlight.go` ไม่มี max speakers
- **ต้องแก้ (0.54a):** `SpotlightSpeaker` หรือ map ใน Room เก็บ `ZoneID` ของ marker ต่อ speaker · Spatial หา zone id จาก tile ที่ยืน (helper ใน ZoneSet เช่น `ZoneIDAt(type, tx, ty)`) · Lite เลือก marker ว่างจุดแรกของ floor · ทุก marker มีคน → error ใหม่ เช่น "spotlight is full"
- **ไฟล์ใหม่:** ไม่มี · เพิ่มใน `spotlight_test.go`
- **ผิดจากเอกสาร:** "เดิมจุดแรกเสมอ" ไม่ตรงโค้ด — ปัจจุบันไม่มีการเลือก marker เลย · นับ "เต็ม" ไม่ได้จนกว่าจะผูก speaker กับ marker
- **ขึ้นกับ:** 0.48

### <a id="t-0-59"></a>0.59 Lite: แตะสมาชิก + แตะ Circle (0.59a zyra-app → [C](#t-0-59a) · 0.59b zyra-ws)
> **ข้อความเดิม (Phase 0):** งาน — **Lite: แตะสมาชิก + แตะ Circle** (ux-ui-plan §22.2) — sheet โปรไฟล์ Message / Wave / Join (ถ้าอยู่ในห้อง) · sheet Join Circle · zyra-ws: ghost เข้า Circle ด้วย id (คู่ join meeting by id TD §16.2) + test · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `views/user/virtual-office/lite/*` · zyra-ws `internal/hub/*` · ขึ้นกับ (เดิม) — 0.16, 0.19, **frame จาก Pai** · Done เมื่อ — test FE-LITE-13, FE-LITE-16 · BE-WS-13
- **มีอยู่แล้ว (verified):** `handleWave` (`room.go:1968-2036`) ไม่ตรวจตำแหน่ง เรียก `inviteToChatSession` (`chatspace.go:163-175`) แต่ invite เข้าได้เมื่อยืนติดกัน (`:353-381`) · `handleCircleAskJoin` (`room.go:3144-3186`) ไม่ตรวจตำแหน่ง แค่ broadcast `circle_join_request` · `handleCircleJoinDecide` (`room.go:3189-3246`) เรียก `addToChatSession` (`chatspace.go:585-612`) เมื่ออนุญาต แต่ไม่เช็คว่าคนกดเป็นสมาชิก circle · **ghost ที่ถูกใส่จะหลุดภายใน 0.1–1 วิ** — step 1 ของ `recomputeChatSessions` (`chatspace.go:387-489`) ใช้ `largestConnectedComponent` ตามตำแหน่ง · token เสียง circle: zyra-api ตรวจกับ snapshot session ใน Redis (`media_handler.go:156-167` `UserInSession`) → ghost อยู่ใน session ก็ได้ token · client `workspace-ws.ts` `circleAskJoin` `:820`, `wave` `:762`, `circleLeave` `:843`
- **ต้องแก้ (0.59b):** `chatspace.go` ghost member ไม่ถูกตัดใน step 1 และไม่ถูกรวมใน step 2 / `snapshotChatPositions` · `chatStateSnapshotLocked` (`:739-777`) ghost ไม่มี position ใน DTO · handler "join circle by id" ใน `room.go` (หรือใช้ ask / decide เดิม + ยกเว้น ghost จาก maintenance) ถ้าทำใหม่ต้องเพิ่ม const ใน `message.go` + case ใน dispatch · (ควรพิจารณา) `handleCircleJoinDecide` เช็คว่าคนกดเป็นสมาชิก circle
- **ไฟล์ใหม่:** test ใน `lite_client_test.go`
- **ผิดจากเอกสาร:** TD §16.2 ไม่ได้บอกว่า maintenance ของ circle จะเตะ ghost ออก
- **ขึ้นกับ:** 0.16, 0.19, frame จาก Pai

### <a id="t-0-62"></a>0.62 Presence grace สำหรับ mobile — **เพิ่ม 2026-10-05 จาก code map**
> **งาน (ใหม่):** zyra-ws ค้าง seat + `MediaRoomID` + presence ไว้ช่วงหนึ่งเมื่อ client mobile หลุด (แทน broadcast `left` ทันที) แล้ว mark `away` · reconnect ด้วย `client_session_id` เดิมภายในเวลา → คืนสถานะรวม sitting · ครบเวลาค่อย `unregister` จริง (TD §12.3 ข้อ 1–2, §13.3 ช่องว่าง #1–2) · **Done เมื่อ (ข้อเสนอ):** กด Home 60 วิ ระหว่างประชุม / นั่งเก้าอี้ แล้วกลับมา → คนอื่นไม่เห็น "ออกจาก office" · กลับมายังนั่งเก้าอี้เดิม + อยู่ในห้องประชุมเดิม · เกินเวลา grace → ออกตามปกติ · table-driven test ใน zyra-ws · **ต้องได้ก่อน** 0.36, 1.6
- **ที่มา:** TD §12.3 + §13.3 มีงานนี้แต่ไม่มี task รับ · 0.36 อ้างแค่ "zyra-ws grace (TD §12)" · code map ยืนยันว่าตอนนี้มีแค่ grace เฉพาะเรื่อง: `room.go:141` (`chatMemberLeaveAt`), `:181` (`spotlightGrace`), `:435` (superseded) — **ไม่มี grace ของ seat / presence**
- **มีอยู่แล้ว (verified ใน code map):** `room.go unregister` `:506` · `handleVisibility` `room.go:2319` · `Client.Hidden` `client.go:144` · `hub.go Join` restore ตำแหน่ง `:230-244` (เฉพาะ `lastFloor == floorID`)
- **มีอยู่แล้ว (จาก TD §12.2 อ่าน 2026-09-29 บน develop — ยังไม่ได้อ่านซ้ำ 🔍):** unregister `room.go:506-626` ไม่มี grace (releaseSeat → ออก meeting chat / audio room / share → `MediaRoomID = ""` → `SetLastPosition` tile+direction ไม่เก็บ sitting → `DeletePresence` → `MsgLeft`) · presence TTL 35s (`store/redis.go:17`) · `reclaimSuperseded` คืนแค่ follow (`room.go:420-441`) · ping 45s / pong 60s (`client.go:17-20`)
- **ต้องแก้:** `room.go unregister` แยกทาง grace (client ที่ `Hidden` หรือ platform mobile) · `store/redis.go` TTL ของ presence ระหว่าง grace · `hub.go Join` restore sitting / seat / `MediaRoomID` เมื่อ `client_session_id` ตรง · ระยะ grace ต้อง **≥ ~31 วิ** (WS backoff ฝั่ง client · TD §11.x) — TD เสนอ 90s · ghost (0.16) ไม่มี seat แต่ควรได้ grace ของ meeting เหมือนกัน
- **ไฟล์ใหม่:** `internal/hub/presence_grace.go` + `presence_grace_test.go` (ข้อเสนอ)
- **ขึ้นกับ:** — (ทำคู่ขนานกับ 0.16 ได้ แต่ต้องตกลงพฤติกรรม ghost ร่วมกัน)

### <a id="t-2-4b"></a>2.4b zyra-ws: ส่ง push ของ event ที่เกิดใน WS
เนื้อหาเต็มอยู่ [2.4 ใน module H](#t-2-4) · ส่วนของ module นี้: `handleWave` `room.go:1968` · `handleKnock` `:2504` · `handleMediaRequest` `audio.go:285` · `handleHandChanged` `audio.go:523` เรียก `postInternalJSON("/api/internal/push", …)` (`hub.go:151-182`, header `X-Internal-Secret`) เมื่อ target `Hidden` (`client.go:144`) หรืออยู่ในช่วง grace (0.62) · knock ต้องกำหนดผู้รับ (ตอนนี้ broadcast ให้ทุกคนแล้ว client กรอง) — ใช้เจ้าของ claim (`zoneClaimOwner` `zoneclaims.go:185`) หรือคนในห้อง · **ไม่ต้องเพิ่ม URL / key ของ zyra-notifications ใน zyra-ws** (ส่งผ่าน zyra-api) · test ใน `internal/hub/push_test.go` (ต่อยอด `notification_push_test.go`)

---

## <a id="mod-h"></a>H. zyra-api

`zyra-api/internal/{handler,service,model,router,notify,config}`, `migrations/` (ถัดไป 108 — ข้อเท็จจริงร่วมข้อ 8)

**งาน backend ของ task ที่หัวข้อเต็มอยู่ module อื่น:** [0.22b](#t-0-22) forward endpoint · [0.25b](#t-0-25) audio MIME + content type + migration · [0.31b](#t-0-31) ตรวจสิทธิ์ copy workspace · [0.37b](#t-0-37) `client_msg_id` + migration · [1.4b](#t-1-4) Google หลาย aud · [1.5b](#t-1-5) `login_apple` · [2.3b](#t-2-3) `notify.SendPush` · [2.6b](#t-2-6) payload + unread รวมข้าม workspace

### <a id="t-0-48b"></a>0.48b zone cache ส่ง `map_id` + ลำดับ
เนื้อหาเต็มอยู่ [0.48 ใน module G](#t-0-48) · ส่วนของ module นี้: `internal/cache/zones.go:21-25` `ZoneGeometry` + `internal/service/map_zone_service.go:105-140` เพิ่ม `map_id` (floor) และ sort key ของ marker ให้ zyra-ws (`store/redis.go:714-731`) รู้ว่าโซนไหนอยู่ floor ไหน · ลำดับต้องตรงกับที่ zyra-app ใช้ (`data.zones` จาก `getPublishedMapData` `lib/api/virtual-office.ts:32`) · test ของ service

### <a id="t-0-55"></a>0.55 ลบบัญชีในแอป (0.55a zyra-api · 0.55b zyra-app → [F](#t-0-55b))
> **ข้อความเดิม (Phase 0):** งาน — **ลบบัญชีในแอป (Apple 5.1.1(v))** (ux-ui-plan §20 · Ten ตอบครบ 2026-10-05) — zyra-api: `DELETE /api/user/me` + `GET /api/user/me/deletion-preview` เรียก logic `DeleteAccount` เดิมแบบ self · workspace ไม่มีสมาชิกอื่น = ลบ · ลบ device token · SIWA revoke (ผูก task 1.5) · ชื่อ "Deleted user" ใน API · zyra-app: แถว Delete account ใน Account and Security + หน้า Delete account (พิมพ์อีเมลยืนยัน) · หลังลบ clearSession → Get started · ไฟล์ที่เอกสารเดิมระบุ — zyra-api `internal/service/user_admin_service.go` (แยก method), handler + route ใต้ UserGuard, test · zyra-app `views/profile/*` หน้าใหม่ · ขึ้นกับ (เดิม) — 2.1, 1.5, **frame จาก Pai** · Done เมื่อ — ลบแล้ว login ไม่ได้ · workspace โอนถูกคน · ออกทุกเครื่อง · ผ่าน review Apple · **เพิ่ม 2026-10-05 (§20.6): helper เก็บกวาดใช้ร่วมกับ admin delete** — ลบ `tb_workspace_member` + `tb_conversation_member` (โอน chat admin ถ้าเป็นคนเดียว) · DM ปิดช่องพิมพ์ + API ปฏิเสธส่งหาบัญชีที่ลบ · ปล่อย private zone / สัตว์เลี้ยง · จบ Spotlight ที่กำลังออกอากาศ · ลิงก์เว็บลบบัญชีสำหรับ Google Play
- **มีอยู่แล้ว (verified):** `internal/service/user_admin_service.go:1046` `DeleteAccount(ctx, group, id, actorID, confirmEmail)` — **`id == actorID` → `ErrCannotActOnSelf`** (`:1047-1049`) · โอน workspace ให้สมาชิก `joined_at` เก่าสุด ไม่มีสมาชิกอื่นตั้ง `owner_id = NULL` (ไม่ลบ workspace) (`:1086-1104`) · anonymize `name='Deleted', lastname='User'` · bump `token_version` · `revokeAllSecuritySessions` (`security_session_service.go:88`) · **ไม่ลบ `tb_workspace_member` / `tb_conversation_member`** · handler `user_admin_lifecycle_handler.go:166-193` (`deleteBody{confirm_email}`, ส่ง `TemplateAccountDeleted`) · route admin `router.go:535`, `:573` · กลุ่ม user `router.go:126` `api.Group("/user", middleware.UserGuard(cfg, db))` ยังไม่มี `DELETE /me` · ไม่มีตาราง device token
- **ต้องแก้ (0.55a):** **แยก logic เป็น helper ที่ไม่มี self-guard** แล้วให้ admin + self เรียกร่วม · ขั้นเก็บกวาดตาม ux-ui-plan §20.6 (member rows, โอน chat admin, ลบ workspace ที่ไม่มีสมาชิกอื่น, ปล่อย private zone / pet, จบ Spotlight, ลบ device token) · `router.go` ใต้ `user` เพิ่ม `DELETE /me` + `GET /me/deletion-preview` · `chat_service.go` ปฏิเสธส่งข้อความหาบัญชี `account_status='deleted'`
- **ไฟล์ใหม่:** `internal/handler/user_self_delete_handler.go` (หรือ method ใน `profile_handler.go`) + test · FE อยู่ 0.55b
- **ผิดจากเอกสาร:** "เรียก logic `DeleteAccount` เดิมแบบ self" ทำตรง ๆ ไม่ได้ ติด self-guard · spec ใช้ "Deleted user" แต่ DB เก็บ name / lastname แยก "Deleted" / "User"
- **ขึ้นกับ:** 2.1 (ลบ device token), 1.5 (SIWA revoke), frame จาก Pai

### <a id="t-0-57"></a>0.57 บังคับอัปเดตแอป (0.57a zyra-api · 0.57b zyra-app → [J](#t-0-57b))
> **ข้อความเดิม (Phase 0):** งาน — **บังคับอัปเดตแอป** (ux-ui-plan §21.2) — zyra-api `GET /api/app/config` (public, อ่าน runtime env: min / latest version + store url ต่อ platform) + test · zyra-app เช็คตอนเปิดแอปและกลับจาก background ด้วย `@capacitor/app` `App.getInfo()` · ต่ำกว่า min = หน้า Update required ปิดไม่ได้ · ต่ำกว่า latest = sheet Update available วันละครั้ง · ดึงค่าไม่ได้ = ข้าม · เฉพาะแอป native · ไฟล์ที่เอกสารเดิมระบุ — zyra-api handler + service + env key ใหม่ · zyra-app component ใหม่ · ขึ้นกับ (เดิม) — 1.1, **frame จาก Pai** · Done เมื่อ — test FE-STORE-05, BE-API-06
- **มีอยู่แล้ว (verified):** ยังไม่มี `/api/app/config` · แบบอ้างอิง: public route `router.go:78` (`/maintenance`) · `maintenance_handler.go:31` `Status` · env bool `internal/config/config.go:139`, `:214` · FE `components/version-check-modal.tsx` (poll 30 นาที เช็คเวอร์ชันเว็บ)
- **ต้องแก้:** route `api.GET("/app/config")` (public)
- **ไฟล์ใหม่ (0.57a):** `internal/handler/app_config_handler.go` · `internal/service/app_config_service.go` + test · key ใหม่ใน `internal/config/config.go` (min / latest version + store url ต่อ platform) · key ใน `zyra-infra/scripts/secret-templates/*/api.json` (K)
- **ผิดจากเอกสาร:** —
- **ขึ้นกับ:** — (0.57b ขึ้นกับ 1.1)

### <a id="t-2-1"></a>2.1 Migration `tb_user_device` + `POST/DELETE /api/user/devices`
> **ข้อความเดิม (Phase 2):** งาน — Migration `tb_user_device` + `POST/DELETE /api/user/devices` (handler → service, UserGuard) + table-driven test · ไฟล์ที่เอกสารเดิมระบุ — zyra-api `migrations/`, `internal/handler/device_handler.go`, `internal/service/device_service.go` · ขึ้นกับ (เดิม) — — · Done เมื่อ — test ≥ 80% · migration รันบน dev
- **มีอยู่แล้ว (verified):** กลุ่ม user `router.go:127` `api.Group("/user", middleware.UserGuard(cfg, db))` · handler อ่าน user ด้วย `userIDFromContext(c)` (เช่น `profile_handler.go:331`) · `model.APIResponse` `internal/model/auth.go:330-338` · **`tb_user.id` เป็น `VARCHAR`** (`migrations/01_init_tables.sql:8`) · handler สร้างใน `main.go` ส่งเข้า `router.New(...)` (`main.go:381`, signature `router.go:13+`)
- **ต้องแก้:** `router.go` ใต้ `user` เพิ่ม `POST("/devices")`, `DELETE("/devices/:token")` (หรือ body) · `router.New` เพิ่ม `deviceHandler` · `main.go` สร้าง service / handler · `internal/database/postgres.go` mirror DDL ใน slice `migrations`
- **ไฟล์ใหม่:** `migrations/NNN_user_device.sql` + `.down.sql` (เลขถัดไป 108) · `internal/model/device.go` · `internal/service/device_service.go` + `_test.go` · `internal/handler/device_handler.go` + `_test.go` · **service method ภายใน** "ดึง token ตาม user" + "ลบ token ที่ invalid" ให้ 2.3 / 2.4 ใช้
- **ผิดจากเอกสาร:** TD §6.1 `user_id TEXT` → จริง VARCHAR (ใช้ได้แต่ควรตรง) · `DELETE /devices/{token}` — FCM token ยาวและมี `:` ควร escape หรือส่งใน body · เอกสารไม่ได้ระบุ method ภายในสำหรับ 2.3 / 2.4
- **ขึ้นกับ:** —

### <a id="t-2-4"></a>2.4 Trigger push (2.4a zyra-api · 2.4b zyra-ws → [G](#t-2-4b))
> **ข้อความเดิม (Phase 2):** งาน — zyra-ws trigger — DM/mention/knock/meeting invite ถึง user ที่ไม่มี connection → publish ไป zyra-notifications · เช็ค notification settings · ไฟล์ที่เอกสารเดิมระบุ — zyra-ws `internal/hub/*.go` จุดที่ส่ง DM/knock/invite, `store/redis.go` · ขึ้นกับ (เดิม) — 2.3 · Done เมื่อ — DM ถึง user offline → push ภายใน 5 วิ | · **ประเภทรอบแรก (Ten 2026-10-01):** DM, mention (แสดงข้อความจริง + ชื่อห้อง + workspace), group message, knock, wave, mic/cam request, raised hand, screen share, pet activity, broadcast started/ended · **ไม่ส่ง:** mention in thread, weather warning/emergency · meeting invitation/reminder (15 นาที)/cancelled/rescheduled **รอ Calendar**
- **มีอยู่แล้ว (verified):**
  - **แชทบันทึกที่ zyra-api ไม่ใช่ zyra-ws:** `ChatService.SendMessage` `chat_service.go:956` → `CreateForMessage` `:1056-1062` · `notification_service.go:87-158` (สร้าง row เฉพาะ mention / reply — **DM ธรรมดาไม่สร้าง row** ตาม comment `:80-86`) · `pushForMessage` `:625-664` → Redis `vo:notify` (`internal/cache/notification.go:14`) · `SetPresence` `:75` + `shouldSkipOnlineDigest` `:1010` · spotlight `CreateSpotlightLive` `:255` · ตัวเช็ค online `PresenceHub.IsOnline` (`presence_service.go:122`, ต่อสาย `main.go:262`; `presenceChecker` `notification_service.go:48-51`, `workspace_presence_service.go:269`)
  - zyra-ws: `Hub.PushNotification` `hub.go:316-334` ส่งให้คนที่ online เท่านั้น (ไม่เจอ client = ไม่ทำอะไร `:320-328`) · subscriber `vo:notify` (`main.go:88-100`, `store/redis.go:819-841`) · `postInternalJSON` `hub.go:151-182` ใช้ที่ `spotlight.go:568,584,595` · config มีแค่ `ZyraAPIURL`, `InternalAPISecret` (`config.go:36-37,88-89`) · ไม่มี helper `IsPresent` ราย user (`store/redis.go:45-53` มี `presenceKey` + member set)
  - event ที่เกิดใน zyra-ws อย่างเดียว: wave `room.go:1968` (target ต้องอยู่ใน room — "wave target not in office" `:1997-2001`) · knock `room.go:2504` · mic/cam request `audio.go:285` · raised hand `audio.go:523` · screen share `screenshare.go:106` · spotlight started `spotlight.go:563` (ผ่าน zyra-api `CreateSpotlightLive`)
  - กลุ่ม internal ของ zyra-api `router.go:383` `InternalGuard` (`middleware/internal_guard.go:17-29`) · settings `NotificationSettings` (`model/auth.go:215-241`) ยังไม่มี field push · zyra-notifications มีแค่ `POST /v1/email`
- **ต้องแก้ (2.4a):** `chat_service.go:1059` ยิง push DM / group ธรรมดา (ไม่มี notif row) ให้คน offline · `notification_service.go pushForMessage` + `CreateSpotlightLive` ยิง push คน offline · route `internal.POST("/push")` ให้ zyra-ws เรียก (2.4b)
- **ไฟล์ใหม่ (2.4a):** `internal/service/push_service.go` + `_test.go` (เลือกผู้รับ → เช็ค `IsOnline` → กรองตามสวิตช์ `push_*` → ดึง token (2.1) → `notify.SendPush` (2.3b) → ลบ token ที่ invalid) · `internal/handler/push_internal_handler.go`
- **ผิดจากเอกสาร:**
  - task 2.4 + TD §6 วาง trigger DM / mention ใน zyra-ws — **zyra-ws แค่ relay chat** การบันทึกข้อความ + notification อยู่ zyra-api และ DM ธรรมดาไม่มี row ใน `vo:notify` เลย → trigger แชทอยู่ zyra-api · zyra-ws รับแค่ wave / knock / ขอสื่อ / ยกมือ
  - repo ที่ task ระบุ `zyra-ws store/redis.go` มีจริง แต่ยังไม่มี helper เช็ค presence ราย user และไม่จำเป็นถ้าส่งผ่าน zyra-api
  - target ของ knock / wave ต้องต่ออยู่ (`getClient`) ตามนิยาม → "user ที่ไม่มี connection" ใช้ไม่ได้ ต้องใช้ `Hidden` หรือ grace (0.62) · zyra-ws มีหลาย instance (ดู chat relay `chatspace.go:822-855`) ห้ามดูแค่ instance ตัวเอง
  - zyra-ws ไม่มี URL / key ของ notifications → ส่งผ่าน zyra-api ไม่ต้องเพิ่ม secret
- **ขึ้นกับ:** 2.1, 2.3, 2.5

### <a id="t-2-5"></a>2.5 Toggle push ต่อประเภท (2.5a zyra-api · 2.5b zyra-app → [F](#t-2-5b))
> **ข้อความเดิม (Phase 2):** งาน — Notification settings บน zyra-app มี toggle push ต่อประเภท · sync ไป backend · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `stores/notification-settings-store.ts` + settings UI, zyra-api · ขึ้นกับ (เดิม) — 2.4 · Done เมื่อ — ปิด toggle แล้วไม่ได้ push | · **Ten: push แยกจาก in-app** → field push ใหม่ต่อประเภท (ไม่ใช้ `enable_*_sounds` เดิม) · server กรองตามสวิตช์ push ก่อนส่ง
- **มีอยู่แล้ว (verified):** `internal/model/auth.go:215+` `NotificationSettings` (thread_replies, joining_circle, hide_chat_in_meeting, event_*, pet_activity, pet_sound) · `profile_service.go:529-560` (JSONB `tb_user.notification_settings` + default) · route `router.go:149-150` · app `lib/api/profile.ts:373-435`, `stores/notification-settings-store.ts:39-62` · เสียง in-app อยู่ audio-settings `enable_*_sounds` (`use-vo-sounds.ts:54-70`)
- **ต้องแก้ (2.5a):** `model/auth.go NotificationSettings` + `DefaultNotificationSettings` เพิ่ม `push_*` · `push_service.go` (2.4a) กรองตามสวิตช์
- **ไฟล์ใหม่:** ไม่มี — JSONB ไม่ต้อง migration
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** 2.4 (ใช้งาน) · ทำ schema ก่อน 2.4 ได้

---

## <a id="mod-i"></a>I. zyra-notifications

`zyra-notifications/main.go`, `internal/{handler,config,mailer}` — **ไม่มี DB ไม่มี Redis** (`go.mod` มีแค่ gin, godotenv, testify)

### <a id="t-2-3"></a>2.3 FCM provider + `POST /v1/push` (2.3a zyra-notifications · 2.3b zyra-api client)
> **ข้อความเดิม (Phase 2):** งาน — zyra-notifications provider FCM HTTP v1 + `POST /push` ภายใน + ลบ token เมื่อ UNREGISTERED + test · ไฟล์ที่เอกสารเดิมระบุ — zyra-notifications `internal/push/fcm.go`, handler · ขึ้นกับ (เดิม) — 2.1, 2.2 · Done เมื่อ — ส่ง push ทดสอบถึงเครื่องจริง
- **มีอยู่แล้ว (verified):** `main.go:63-64` route มีแค่ `GET /healthz`, `POST /v1/email` · CORS `*` ทุก route `:48-57` · `internal/handler/handler.go:53-60` `SendEmail` เช็ค `X-Notification-Key` (**ปล่อยผ่านเมื่อ `APIKey==""`**) · `internal/config/config.go` · `internal/mailer/mailer.go` (SMTP `net/smtp`, `smtpHostPort` gmail `:439-444`) · ไม่มี `cmd/`, DB, Redis, `internal/push` · ผู้เรียก `zyra-api/internal/notify/client.go:70-150` (`POST /v1/email` + `X-Notification-Key` + retry 3 ครั้ง)
- **ต้องแก้:** **2.3a** `main.go` เพิ่ม route · `config.go` เพิ่ม `FCMServiceAccountJSON` · **2.3b** `zyra-api/internal/notify/client.go` เพิ่ม `SendPush` (แบบเดียวกับ `/v1/email`)
- **ไฟล์ใหม่ (2.3a):** `internal/push/fcm.go` + `fcm_test.go` (OAuth2 service account → FCM HTTP v1, แยกผล `UNREGISTERED`) · handler `SendPush` ใน `internal/handler/handler.go` หรือ `push_handler.go`
- **ผิดจากเอกสาร:**
  - TD §6.3 ใช้ `POST /push` — แบบที่มีอยู่คือ `/v1/...` → **`POST /v1/push`**
  - TD §6 ให้ notifications "lookup tb_user_device" — service นี้ไม่มี DB → **zyra-api ส่ง `tokens[]` มาเอง** notifications ตอบ `invalid_tokens[]` ให้ zyra-api ลบ
  - endpoint push ต้อง **fail closed** (ปฏิเสธเมื่อไม่มี key) ไม่ใช่ปล่อยผ่านเหมือน email
- **ขึ้นกับ:** 2.1, 2.2

---

## <a id="mod-j"></a>J. Native shell `zyra-mobile` + `zyra-app/lib/native/*`

repo ใหม่ `zyra-mobile` (Capacitor) · wrapper plugin ฝั่งเว็บ `zyra-app/lib/native/*.ts` (ใหม่ ไฟล์ละ plugin) · `zyra-app/package.json` ต้องมี `@capacitor/core` + JS ของ plugin

### <a id="t-0-57b"></a>0.57b zyra-app: gate บังคับอัปเดต
เนื้อหาเต็มอยู่ [0.57 ใน module H](#t-0-57) · ส่วนของ module นี้: `components/app-update-gate.tsx` + `lib/api/app-config.ts` · เช็คตอนเปิดแอป + กลับจาก background ด้วย `@capacitor/app` `App.getInfo()` (ผ่าน `lib/native/lifecycle.ts` ของ 1.6) · ทำงานเฉพาะ native · ดึงค่าไม่ได้ = ข้าม

### <a id="t-1-1"></a>1.1 สร้าง repo `zyra-mobile` + `capacitor.config`
> **ข้อความเดิม (Phase 1):** งาน — สร้าง repo `zyra-mobile` — `npm init @capacitor/app`, `capacitor.config.ts` (server.url ต่อ flavor dev/uat/prod, allowNavigation), README สั้นชี้มา zyra-doc · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile · ขึ้นกับ (เดิม) — 0.1 · Done เมื่อ — เปิดแอปบน simulator/emulator แล้วเห็นหน้า login ของ dev
- **มีอยู่แล้ว (verified):** ไม่มีโค้ด Capacitor เลย · `zyra-app/package.json` `"next": "16.2.4"`, `@sentry/nextjs`, `mixpanel-browser` ไม่มี `@capacitor/*` · `zyra-app/next.config.ts:35` `output: "standalone"`, rewrites `:111-127` (`/api/*`, `/uploads/*`, `/profile-file/*` → `BACKEND_URL`) → ต้องใช้ remote URL · origin ต่อ env (จาก `zyra-infra/scripts/secret-templates/*/notifications.json` + `ws.json`): dev `https://app.dev.zyra.center` · uat `https://app.uat.zyra.center` · prod `https://app.zyraworld.co` (+ `app.zyra-world.com`, `app.zyra.center` ใน prod `ALLOWED_ORIGINS`) · zyra-ws ตรวจ origin `zyra-ws/internal/handler/handler.go:76-93` (remote URL = โดเมนจริง ผ่าน)
- **ต้องแก้:** `zyra-app/package.json` เพิ่ม `@capacitor/core` + JS plugin ทุกตัว · `lib/platform.ts` (0.41) เปลี่ยนจาก `window.Capacitor` เป็น import `@capacitor/core` ได้หลังนี้
- **ไฟล์ใหม่ (zyra-mobile):** `package.json` · `capacitor.config.ts` (อ่าน `CAP_FLAVOR` dev / uat / prod → `server.url`, `server.allowNavigation` ตามโดเมนข้างบน, `android.allowMixedContent:false`) · `www/index.html` (webDir ขั้นต่ำ) + `www/offline.html` · `ios/App/App/{Info.plist, AppDelegate.swift, App.entitlements}` · `android/app/src/main/{AndroidManifest.xml, java/.../MainActivity.java}` · `README.md` ชี้ไป zyra-doc
- **ไฟล์ใหม่ (zyra-app):** `lib/native/` (wrapper plugin แยกไฟล์)
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** 0.1

### <a id="t-1-2"></a>1.2 Splash / icon / status bar / orientation
> **ข้อความเดิม (Phase 1):** งาน — Splash, icon, status bar `#1A1B1E`, orientation ทั้ง landscape/portrait **ไม่ lock** (มติ Lite/Spatial — technical-design §16.6) + `manifest.ts` `orientation: "any"`, permission string กล้อง/ไมค์/notification · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile (`ios/App/App/Info.plist`, `android/app/src/main/AndroidManifest.xml`) · ขึ้นกับ (เดิม) — 1.1 · Done เมื่อ — เปิดแอปแล้วไม่มีจอขาว · ขอ permission ตอนใช้ครั้งแรก | · **HP-07 (2026-10-01):** splash animated 2 วิ (ClickUp) → onboarding 3 slide ไม่มี Skip โชว์ครั้งแรก · หน้าก่อนเข้า workspace (splash / slide / login / Space builder / Create workspace) **lock portrait** ด้วย `@capacitor/screen-orientation` แล้วปลดหลังเลือกโหมด
- **มีอยู่แล้ว (verified):** `app/manifest.ts:12` `orientation: "landscape"` · `:13-14` `background_color` / `theme_color: "#2B3540"` · `app/layout.tsx:85-87` viewport `themeColor: "#2B3540"` · `:92-100` `appleWebApp.statusBarStyle: "black-translucent"` icon `/icons/icon-192.png` · `public/icons/` มีอยู่
- **ต้องแก้:** `app/manifest.ts:12` → `"any"` + `background_color` → `#1A1B1E` (ร่วมกับ 0.33) · `app/layout.tsx` viewport (ทับซ้อน 0.2)
- **ไฟล์ใหม่:** `zyra-mobile/resources/{icon.png,splash.png}` (`@capacitor/assets`) · Info.plist `UISupportedInterfaceOrientations` + `~ipad` · Android `screenOrientation="fullSensor"` · plugin `@capacitor/splash-screen`, `@capacitor/status-bar`, `@capacitor/screen-orientation` · `zyra-app/lib/native/screen-orientation.ts` (lock portrait ก่อนเลือกโหมด)
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** 1.1, ชื่อแอป / bundle id (`co.zyraworld.app`) / ไอคอน

### <a id="t-1-3"></a>1.3 reCAPTCHA + email login ใน WebView — เหลือทดสอบอย่างเดียว
> **ข้อความเดิม (Phase 1):** งาน — ตรวจว่า reCAPTCHA + email login ทำงานใน WebView · ถ้าไม่ได้ทำ fallback ตาม technical-design §4 · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `views/login/*`, zyra-mobile · ขึ้นกับ (เดิม) — 1.1 · Done เมื่อ — login email/password ในแอปผ่าน
- **มีอยู่แล้ว (verified):** `lib/auth/session.ts:164-173` `loginWithEmail` ส่ง `captchaToken: payload.captchaToken ?? ""` (`:170`) · `lib/auth/register.ts:48,74` ก็ส่ง `""` · `views/login/components/card-login.tsx:161` เรียก `loginWithEmail` · `zyra-api/internal/handler/auth_handler.go:25-30` อ่านแค่ username / password / rememberMe · grep `captcha` ใน `zyra-api/internal` ไม่เจอ · `NEXT_PUBLIC_RECAPTCHA_SECRET` ถูก bake (`deploy-gitops.yml:138,163`, `Dockerfile:16`) แต่ไม่มีโค้ดอ่าน
- **ต้องแก้:** ไม่มี — ทดสอบ email login ในแอป
- **ไฟล์ใหม่:** ไม่มี
- **ผิดจากเอกสาร:** **reCAPTCHA ไม่ได้ใช้จริงทั้งสองฝั่ง** → TD §4 / §10 / §11.2 ที่ให้เตรียม fallback ไม่ต้องทำ (TD §14.2 B2 บอกแบบนี้อยู่แล้ว)
- **ขึ้นกับ:** 1.1

### <a id="t-1-4"></a>1.4 Google native sign-in (1.4a zyra-app + zyra-mobile · 1.4b zyra-api)
> **ข้อความเดิม (Phase 1):** งาน — Google native sign-in — plugin + zyra-app branch `isNativePlatform` → `loginWithGoogle(idToken)` เดิม · zyra-api รับหลาย `GOOGLE_CLIENT_ID` · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile, zyra-app `lib/auth/session.ts` + login view, zyra-api `internal/service/authen_service.go` (verify aud) · ขึ้นกับ (เดิม) — 1.1 · Done เมื่อ — login Google ในแอปผ่านทั้ง iOS/Android
- **มีอยู่แล้ว (verified):** `lib/auth/session.ts:175-179` `loginWithGoogle({token})` → `POST /api/authen/login_google` (form) · `card-login.tsx:310-330` `openGooglePopup` (`window.open("/login/google","_blank")` `:314`) เรียกที่ `:355` และ `<GoogleLoginButton onClick>` `:487-488` · ฟัง event `zyra_google_login_event` `:233-290` · timeout 120s `:293-300` · `app/login/google/page.tsx` implicit flow (`response_type: "id_token"`, nonce ใน sessionStorage) · `app/login/google/callback/page.tsx:47-84` ตรวจ nonce → `loginWithGoogle` → `window.close()` · API `zyra-api/internal/service/auth_service.go:246-260` `LoginGoogle` → `idtoken.Validate(ctx, googleToken, s.cfg.GoogleClientID)` **รับ aud ค่าเดียว** · user id = Google `sub` (`:270`, `:303-313` `AuthenType:"GOOGLE"`) ผูก email `:278-298` · config `internal/config/config.go:26,164` · secret `GOOGLE_CLIENT_ID` ใน `secret-templates/*/api.json`
- **ต้องแก้:** **1.4a** `card-login.tsx` `openGooglePopup` branch native → plugin → `loginWithGoogle({token: idToken})` ใช้ logic success / blocked / isNew เดียวกับ `:250-275` (แยกเป็นฟังก์ชัน) · **1.4b** `auth_service.go:257` วนเช็คทีละ client id ของ `GoogleClientID` ที่คั่น comma · `config.go:164` parse เป็น slice
- **ไฟล์ใหม่:** 1.4a `zyra-app/lib/native/google-auth.ts` · zyra-mobile `GoogleService-Info.plist` / config plugin · 1.4b เคสหลาย aud ใน `internal/service/auth_service_test.go` (มีไฟล์อยู่แล้ว)
- **ผิดจากเอกสาร:** `internal/service/authen_service.go` **ไม่มี** ไฟล์จริงคือ `auth_service.go` · TD §14.2 B1 อ้าง `session.ts:177` (จริงเริ่ม `:175`) · `card-login.tsx:314` ตรง · ⚠️ ถ้า plugin ตั้ง `serverClientId` = web client id ค่า `aud` อาจเป็น web client id อยู่แล้ว → ดูจาก token จริงก่อนสรุปว่าต้องรับหลายค่า
- **ขึ้นกับ:** 1.1 · secret หลายค่า → K 1.5c

### <a id="t-1-5"></a>1.5 Sign in with Apple (1.5a zyra-app + zyra-mobile · 1.5b zyra-api · 1.5c secret → [K](#t-1-5c))
> **ข้อความเดิม (Phase 1):** งาน — Sign in with Apple — plugin (app) + **Sign in with Apple JS บนเว็บ** (Services ID + return URL — หน้า login เว็บแนวตั้ง/แนวนอนมีปุ่ม Apple ตาม Figma + ux-ui-plan §7 ข้อ 11) + `POST /api/authen/login_apple` (verify JWT กับ Apple keys, ผูก user ด้วย sub/email) + table-driven test · ไฟล์ที่เอกสารเดิมระบุ — zyra-api handler/service ใหม่, zyra-app login view, zyra-mobile · ขึ้นกับ (เดิม) — 1.4 · Done เมื่อ — login Apple ผ่าน · test ≥ 80%
- **มีอยู่แล้ว (verified):** ไม่มีโค้ด Apple sign-in (grep `apple` เจอแค่ `layout.tsx:99` icon + font stack) · กลุ่ม route authen `zyra-api/internal/router/router.go:83-96` · `/login/*` เป็น public ผ่าน `PUBLIC_PATHS "/login"` (`proxy.ts:6`)
- **ต้องแก้:** **1.5b** `router.go` `authen.POST("/login_apple", authHandler.LoginApple)` · `auth_handler.go` `LoginApple` (แบบ `LoginGoogle` `:196-237` + `setRefreshTokenCookie` `:243`) · `auth_service.go` `LoginApple` (id = Apple `sub`, `AuthenType "APPLE"`, **ห้ามเขียนชื่อว่างทับ** แบบ `mergeGoogleClaims` `:811` เพราะ Apple ส่งชื่อครั้งแรกครั้งเดียว) · `config.go` `APPLE_CLIENT_IDS` (bundle id + Services ID) · **1.5a** `lib/auth/session.ts` `loginWithApple` · `card-login.tsx` ปุ่มข้าง `GoogleLoginButton` `:487`
- **ไฟล์ใหม่:** 1.5b `internal/service/apple_auth.go` (ดึง JWKS + verify) + `apple_auth_test.go` (table-driven) · 1.5a `views/login/components/apple-login-button.tsx` · `lib/native/apple-auth.ts` · หน้ารับผล SIWA JS บนเว็บใต้ `app/login/apple/` (อยู่ใต้ public prefix)
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** 1.4, Apple Developer account

### <a id="t-1-6"></a>1.6 Lifecycle (`appStateChange` → ws / SFU / Pixi + keep-awake)
> **ข้อความเดิม (Phase 1):** งาน — Lifecycle — `appStateChange` → ws `visibility` + reconnect, SFU re-attach, Pixi ticker pause/resume · keep-awake ใน VO · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `stores/vo-session-store.ts`, `components/game-canvas/pixi-canvas.tsx` · ขึ้นกับ (เดิม) — 1.1 · Done เมื่อ — สลับแอป 30 วิ กลับมา ws ต่อภายใน 5 วิ
- **มีอยู่แล้ว (verified):** WS `lib/api/workspace-ws.ts:498-513` `_onWake` / `_bindLifecycle` (online / focus / visibilitychange) → `reconnectNow()` `:430-457` · backoff `:82-83` · liveness 30s `:87-88` · `visibility()` `:788` · onopen ส่ง visibility `:315` · hero `:4041-4097` (visibility → `wsClient.visibility(hidden)` + `reconnectNow()` + resync remotes) · `beforeunload` presence / zone keepalive `:4612-4647` · tab-keepalive `:8451-8460` · media `use-meeting-media.ts:1006` (ws reconnected), `:1025` startAudio, `:1037-1057` visibility, `:1304` scheduleReconnect, `:1325` sfu reconnected, `:1349` disconnected · engine `scene.ts:2949` visibilitychange → `_handleResumeFromBackground` `:3155` · `setRenderSuspended` `:3074` · `app.ticker.stop()` `:1614` · `pixi-canvas.tsx:75-76` · **store `stores/vo-session-store.ts:417` สร้าง client, `:432` heartbeat 20s — ไม่มี visibility handler** · polling `components/auth-guard.tsx:41-42,101,143`, `app-presence.tsx:21,43`, `version-check-modal.tsx:73` · ไม่มี `wakeLock`
- **ต้องแก้:** `workspace-ws.ts _bindLifecycle` รับ `appStateChange` → `_onWake` · `hero:4042` แยก `onVisibilityChange` เป็นฟังก์ชันที่ native lifecycle เรียกได้ + `App.pause` → POST presence keepalive (logic เดียวกับ `:4613-4644`) · `use-meeting-media.ts:1037` รับสัญญาณเดียวกัน · ปิด tab-keepalive `:8451` บน native · หยุด poll 3 ตัวตอน inactive
- **ไฟล์ใหม่:** `zyra-app/lib/native/lifecycle.ts` (`@capacitor/app`) · `lib/native/keep-awake.ts` (เรียกตอน mount / unmount hero)
- **ผิดจากเอกสาร:** TD §5 + task ให้ใส่ hook ใน `stores/vo-session-store.ts` แต่ store ไม่มี lifecycle logic — ตัวจริงอยู่ `workspace-ws.ts:504` และ `hero:4041` · TD §12.3 อ้าง `hero:4035-4097` จริง `4041-4097` · `beforeunload :4613` ตรง
- **ขึ้นกับ:** 1.1 · **0.62 (zyra-ws grace — เดิมไม่มี task)**

### <a id="t-1-7"></a>1.7 iOS background audio
> **ข้อความเดิม (Phase 1):** งาน — iOS background audio — `UIBackgroundModes: audio` + AVAudioSession category ผ่าน plugin · ทดสอบเสียงประชุมค้างตอน background · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile iOS · ขึ้นกับ (เดิม) — 1.6 · Done เมื่อ — ออกจากแอปกลางประชุม ยังได้ยินเสียง
- **มีอยู่แล้ว (verified):** `lib/api/sfu-client.ts:319` `connect()` · ไม่มี `navigator.audioSession` ที่ไหน · `startAudio()` `:1037-1039` · `use-meeting-media.ts:995,1011` `mediaRoomEnter`
- **ต้องแก้:** `sfu-client.ts connect()` ตั้ง `navigator.audioSession.type = "play-and-record"` (iOS 17+)
- **ไฟล์ใหม่:** `zyra-mobile/ios/App/App/Info.plist` `UIBackgroundModes=[audio]` · ตรวจ / override `mediaTypesRequiringUserActionForPlayback=[]` ใน `AppDelegate.swift` หรือ subclass `CAPBridgeViewController` · deployment target iOS 17.5
- **ผิดจากเอกสาร:** Android foreground service (A2 — TD §13.1 / §14.5 "Phase 1 ต้องมีก่อน submit") **ไม่มี task รับ** → เพิ่ม [1.17](#t-1-17)
- **ขึ้นกับ:** 1.6

### <a id="t-1-8"></a>1.8 Push client
> **ข้อความเดิม (Phase 1):** งาน — Push client — `@capacitor/push-notifications` + Firebase SDK (iOS) → `POST /api/user/devices` หลัง login · `DELETE` ตอน logout · tap payload → route · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile, zyra-app `lib/api/devices.ts` (ใหม่) + `lib/auth/session.ts` · ขึ้นกับ (เดิม) — 2.1 · Done เมื่อ — token ถูกบันทึกใน DB · แตะ push เปิดหน้าที่ถูก
- **มีอยู่แล้ว (verified):** `lib/auth/session.ts:326-334` `persistSession` · `:343-360` `clearSession` (ล้าง token `:347-349` ก่อน POST `/api/authen/logout`) · ยังไม่มี `lib/api/devices.ts`, `lib/push.ts` · grep `fcm|apns|firebase|device_token` ทุก repo ไม่เจอ
- **ต้องแก้:** `persistSession` → register token หลัง login · `clearSession` → `DELETE /api/user/devices/:token` **ก่อน** `setAccessToken(null)` (ต้องผ่าน UserGuard) · 🔍 Google callback `app/login/google/callback/page.tsx:69` ใช้ `persistSession` หรือไม่
- **ไฟล์ใหม่:** `zyra-app/lib/api/devices.ts` · `lib/native/push.ts` (`@capacitor/push-notifications`) · zyra-mobile Firebase iOS SDK + `GoogleService-Info.plist` + `android/app/google-services.json` (ใส่ผ่าน CI secret) · entitlement `aps-environment`
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** 2.1, 2.2

### <a id="t-1-9"></a>1.9 Deep link + universal links
> **ข้อความเดิม (Phase 1):** งาน — Deep link `zyra://` + universal links (AASA + assetlinks.json serve จาก zyra-app `public/.well-known/`) · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile, zyra-app `public/.well-known/` · ขึ้นกับ (เดิม) — 1.1 · Done เมื่อ — เปิดลิงก์ workspace แล้วเข้าแอปตรง
- **มีอยู่แล้ว (verified):** ยังไม่มี `public/.well-known/` · **`proxy.ts:255` `config.matcher` ไม่ได้ยกเว้น `.well-known` / `.json`** (ยกเว้นแค่ `api|_next/static|_next/image|favicon.ico|image|icons|sw\.js|manifest\.webmanifest|monitoring` + ไฟล์รูป) และ `PUBLIC_PATHS` (`:5-15`) ไม่มี → Apple / Google ดึง AASA / assetlinks โดยไม่มี cookie จะถูก redirect ไป `/login` · `next.config.ts:41-53` `headers()` มีแค่ `/sw.js` · ปลายทาง: `app/join/[token]/page.tsx` · `hero-accept-invite.tsx:179,192` (`/login?redirect_url=…`) · ลิงก์ห้อง `hero:11484-11486` · ตรวจ redirect same-origin `card-login.tsx:108-120`, `:252-262` · email link สร้างใน zyra-api (`workspace_member_service.go`, `forgot_password_service.go`)
- **ต้องแก้:** `proxy.ts:255` matcher ยกเว้น `\\.well-known` · `next.config.ts headers()` ตั้ง `Content-Type: application/json` ให้ AASA (ไฟล์ไม่มีนามสกุล) · `/join` ใน `PUBLIC_PATHS` (ดู 0.60)
- **ไฟล์ใหม่:** `zyra-app/public/.well-known/{apple-app-site-association, assetlinks.json}` (รวม appID / SHA256 ทุก flavor เพราะไฟล์ static ใช้เหมือนกันทุก env) · `lib/native/deep-link.ts` (`appUrlOpen` → `router.push`) · zyra-mobile `App.entitlements` `applinks:` + Android intent-filter `autoVerify`
- **ผิดจากเอกสาร:** TD §14.2 B4 อ้าง `hero-accept-invite.tsx:143` — `:143` คือที่สร้าง `redirectUrl` · จุด bounce จริง `:179,192` · code map รอบแรกจด matcher เป็น `proxy.ts:135-141` → อ่านซ้ำแล้ว matcher อยู่ **`:255`**
- **ขึ้นกับ:** 1.1

### <a id="t-1-10"></a>1.10 Native polish Tier 2 (haptics, badge, share, keyboard)
> **ข้อความเดิม (Phase 1):** งาน — Native polish Tier 2 — haptics (wave/knock/join zone), badge count, share sheet ส่ง invite, keyboard handling · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile, zyra-app จุดที่เรียก wave/knock + invite modal · ขึ้นกับ (เดิม) — 1.1 · Done เมื่อ — ครบตามรายการ Tier 2 ใน spec
- **มีอยู่แล้ว (verified):** จุดใส่ haptics ใน hero: wave `:2749` · knock `:2848` · เข้าห้อง `:3008`, `:11752` · ขอไมค์ / กล้อง `:10988` (sound refs จาก `use-vo-sounds.ts:79-136` · ไม่มี `navigator.vibrate`) · badge: `stores/chat-store.ts:413` รวม unread (ต่อ workspace), `:123` unread notification · server `chat_service.go:1804` `GetUnreadCounts` ต่อ workspace (ไม่มียอดรวมข้าม workspace) · share: มีแค่ copy — `invite-member-modal.tsx:246`, `hero:11486,11495`, `zone-enter-header.tsx:197` · keyboard: `message-input.tsx:432-457` (Enter ส่ง) · `zone-enter-chat.tsx:808-814` (input Enter), `:709` focus · ไม่มี `visualViewport`, `enterKeyHint`, `isComposing`
- **ต้องแก้:** 4 จุดใน hero เรียก `haptic()` · 3 จุด copy → `share()` บน native · `message-input.tsx:457` / `zone-enter-chat.tsx:814` เพิ่ม `enterKeyHint` + guard `isComposing` · ทาง Capacitor `keyboardWillShow` ให้ `isKeyboardLikelyOpen` (0.42)
- **ไฟล์ใหม่:** `lib/native/{haptics.ts, share.ts, badge.ts, keyboard.ts}` · plugin `@capacitor/haptics`, `@capacitor/share`, `@capacitor-community/badge`, `@capacitor/keyboard` (ตั้ง `resize` ใน `capacitor.config.ts`)
- **ผิดจากเอกสาร:** TD §14.2 B10 อ้าง `hero:2101,2127,2752,2851` — wave / knock จริง `:2749` / `:2848` (`2098` / `2124` เป็นเสียงแชท / mention)
- **ขึ้นกับ:** 1.1 · badge ขึ้นกับ 2.6

### <a id="t-1-11"></a>1.11 หน้า offline native
> **ข้อความเดิม (Phase 1):** งาน — หน้า offline native + retry — ตรวจ `server.url` reachable ก่อนโหลด, error page ของ WebView ถูกแทนด้วยหน้าของแอป · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile · ขึ้นกับ (เดิม) — 1.1 · Done เมื่อ — ปิดเน็ตแล้วเปิดแอป → เห็นหน้า offline ของเรา
- **มีอยู่แล้ว (verified):** `public/sw.js:25-43` offline HTML สำหรับ navigation แต่ SW ไม่รันใน WKWebView · `components/pwa-register.tsx:13-14` register เฉพาะ production
- **ต้องแก้:** `pwa-register.tsx` ข้ามบน native (ไม่บังคับ)
- **ไฟล์ใหม่:** `zyra-mobile/www/offline.html` (+ retry) · iOS `WKNavigationDelegate didFailProvisionalNavigation` · Android `WebViewClient.onReceivedError` · ตรวจ server เข้าถึงได้ก่อนโหลด
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** 1.1

### <a id="t-1-14"></a>1.14 Permission strings
> **ข้อความเดิม (Phase 1):** งาน — **Permission strings** — iOS Info.plist `NSCameraUsageDescription` = "Zyra needs access to your camera so others can see you during meetings and when you use camera features." · `NSMicrophoneUsageDescription` = "Zyra needs access to your microphone so others can hear you during meetings and conversations." (Figma HP-09 · แปลไทยใน `InfoPlist.strings`) · Android `CAMERA` / `RECORD_AUDIO` ใน AndroidManifest · ไฟล์ที่เอกสารเดิมระบุ — `zyra-mobile/ios/App/App/Info.plist`, `android/app/src/main/AndroidManifest.xml` · ขึ้นกับ (เดิม) — 1.1 · Done เมื่อ — dialog ระบบแสดงข้อความตรง Figma ทั้ง EN/TH
- **มีอยู่แล้ว (verified):** ไม่มี (repo ยังไม่มี)
- **ไฟล์ใหม่:** `zyra-mobile/ios/App/App/Info.plist` (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSLocationWhenInUseUsageDescription` ถ้าทำ B7) · `ios/App/App/th.lproj/InfoPlist.strings` · `android/app/src/main/AndroidManifest.xml` (`CAMERA`, `RECORD_AUDIO`, `POST_NOTIFICATIONS`)
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** 1.1

### <a id="t-1-15"></a>1.15 RAM ต่ำ (plugin native)
> **ข้อความเดิม (Phase 1):** งาน — **RAM ต่ำ (EP-01, สมมติว่าทำ — OQ 30)** — native plugin อ่าน available memory (iOS `os_proc_available_memory` / Android `ActivityManager.MemoryInfo`) + event `didReceiveMemoryWarning` / `onTrimMemory` → toast "Low memory" + แนะนำ Performance mode เมื่อ < 200MB · ไฟล์ที่เอกสารเดิมระบุ — `zyra-mobile` plugin (Swift/Kotlin) + bridge · ขึ้นกับ (เดิม) — 1.1, 0.38 · Done เมื่อ — จำลอง memory pressure บนเครื่องจริงแล้ว toast ขึ้นครั้งเดียวต่อ session
- **มีอยู่แล้ว (verified):** `lib/nature-performance.ts:7` `LOW_FPS = 30` · `:46` `samplePerf` · `:69` `restorePerf` · ไม่มีโค้ดอ่าน `deviceMemory` / memory
- **ต้องแก้:** จุดแสดง toast (ใช้ร่วมกับ ladder 0.38)
- **ไฟล์ใหม่:** `zyra-mobile/ios/App/App/Plugins/MemoryPlugin.swift` (`os_proc_available_memory`, `didReceiveMemoryWarning`) · `android/.../MemoryPlugin.kt` (`ActivityManager.MemoryInfo`, `onTrimMemory`) · `zyra-app/lib/native/memory.ts` (`registerPlugin`)
- **ผิดจากเอกสาร:** **toast "แนะนำ Performance mode" ใช้ไม่ได้แล้ว** — 0.39 (เมนู Performance) ตัดไป 2026-10-02 → ข้อความ toast ต้องไม่พูดถึง Performance mode (เช่นบอกว่าระบบลดเอฟเฟกต์ให้แล้ว / แนะนำปิดแอปอื่น — รอ copy)
- **ขึ้นกับ:** 1.1, 0.38

### <a id="t-1-16"></a>1.16 Tablet + font config
> **ข้อความเดิม (Phase 1):** งาน — **Tablet + font config (EC-03)** — iPad รองรับ 4 ทิศ + multitasking (ไม่ตั้ง `UIRequiresFullScreen`) · Android `resizeableActivity` · `ScreenOrientation.lock('portrait')` ก่อนเข้า workspace **เฉพาะมือถือ** (ด้านสั้น < 600) · Android `setTextZoom(100)` / `@capacitor/text-zoom` lock ขนาดตัวอักษร 100% (TD §16.6) · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile `ios/App/Info.plist`, `android/.../MainActivity`, zyra-app จุดเรียก lock · ขึ้นกับ (เดิม) — 1.2 · Done เมื่อ — iPad Split View ใช้ได้ · ตั้ง font ใหญ่สุดใน Android แล้ว layout ไม่แตก
- **มีอยู่แล้ว (verified):** ยังไม่มีจุดเรียก lock เพราะหน้า Select mode (0.15) ยังไม่มี
- **ต้องแก้:** หน้าที่ 0.15 สร้าง (`unlock()` หลัง Confirm)
- **ไฟล์ใหม่:** Info.plist `UISupportedInterfaceOrientations~ipad` (ไม่ใส่ `UIRequiresFullScreen`) · Android `resizeableActivity` · `MainActivity` `setTextZoom(100)` หรือ `@capacitor/text-zoom` · `lib/native/screen-orientation.ts` (lock เฉพาะด้านสั้น < 600)
- **ผิดจากเอกสาร:** path หน้า Select mode = `views/user/workspace-enter/components/select-mode.tsx` (ไม่ใช่ `views/user/workspace-enter/select-mode.tsx`)
- **ขึ้นกับ:** 1.2, 0.15, 0.41

### <a id="t-1-17"></a>1.17 Android foreground service ตอนประชุม — **เพิ่ม 2026-10-05 จาก code map**
> **งาน (ใหม่):** Kotlin service type `microphone|mediaPlayback` + ongoing notification · เริ่มเมื่อเข้าห้องประชุม (`mediaRoomEnter`) หยุดเมื่อออก · Android 14+ ต้องประกาศ `foregroundServiceType` + permission (TD §13.1, §14.1 A2, §14.5 "Phase 1 ต้องมีก่อน submit") · **Done เมื่อ (ข้อเสนอ):** Android 14 ขึ้นไป ออกจากแอปกลางประชุม ≥ 5 นาที ยังได้ยินและพูดได้ + notification ค้าง · ออกจากห้อง → service หยุด notification หาย · ไม่มี crash ตอน OS ปฏิเสธ permission
- **ที่มา:** TD บอกว่าเป็น "งาน native ชิ้นเดียวใน Tier 1" แต่ task-breakdown ไม่มีข้อไหนรับ (1.7 เป็น iOS อย่างเดียว)
- **มีอยู่แล้ว (verified):** จุดเริ่ม / หยุด service = `use-meeting-media.ts:995,1011` (`mediaRoomEnter`) · ไม่มีโค้ด native
- **ไฟล์ใหม่:** `zyra-mobile/android/app/src/main/java/.../MeetingForegroundService.kt` · `AndroidManifest.xml` `<service android:foregroundServiceType="microphone|mediaPlayback">` + `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` 🔍 · `zyra-app/lib/native/foreground-service.ts` (bridge) · ทางเลือก: plugin community `capacitor-plugin-background-mode` ถ้ารองรับ type ของ Android 14 🔍
- **ขึ้นกับ:** 1.1, 1.6 · ทำคู่กับ 1.7

### <a id="t-2-6"></a>2.6 แตะ push + foreground + badge (2.6a zyra-app · 2.6b zyra-api)
> **ข้อความเดิม (Phase 2):** งาน — **แตะ push + foreground + badge** — แตะ DM/mention → เปิดห้องแชทนั้น · broadcast → หน้ารองรับ (รอ UI) · weather (ถ้ากลับมาส่ง) → เปิดแอปเฉย ๆ · แอปเปิดอยู่ → banner ในแอปแทน push (`pushNotificationReceived`) · badge icon = unread chat + notification (silent push อัปเดต badge) · ไฟล์ที่เอกสารเดิมระบุ — zyra-app `lib/push.ts` (ใหม่), zyra-notifications payload `data.route` + `badge` · ขึ้นกับ (เดิม) — 1.3, 2.3 · Done เมื่อ — แตะ push จาก lock screen เปิดห้องถูกห้องทั้งแอปปิด/เปิด · badge ตรงกับ unread ในแอป
- **มีอยู่แล้ว (verified):** ยังไม่มี `lib/push.ts` · unread `chat-store.ts:413` (ต่อ workspace) · `notification_service.go:965` `GetUnreadCount(userID, workspaceID)` (ต่อ workspace)
- **ต้องแก้:** **2.6b** payload ใน `push_service.go` (`data.route`, `badge`, `thread-id` = conversation id) · query ยอด unread รวมข้าม workspace (ยังไม่มี)
- **ไฟล์ใหม่:** **2.6a** `zyra-app/lib/push.ts` (`pushNotificationActionPerformed` → `router.push` · `pushNotificationReceived` → banner ในแอป) · badge ผ่าน `lib/native/badge.ts` (1.10)
- **ผิดจากเอกสาร:** ช่อง "ขึ้นกับ 1.3" ต้องเป็น **1.8** (1.3 คือ reCAPTCHA) · 0.33 อ้าง "1.3 (deep link)" ซึ่ง deep link คือ 1.9
- **ขึ้นกับ:** 1.8, 2.3

### <a id="t-3-2"></a>3.2 Screen share native
> **ข้อความเดิม (Phase 3):** งาน — Custom plugin screen share — ReplayKit (iOS) / MediaProjection (Android) → publish track เข้า LiveKit · หมายเหตุ — งานใหญ่ ต้อง native ทั้งสอง platform
- **มีอยู่แล้ว (verified):** `lib/api/sfu-client.ts:816-829` `setScreenShareEnabled` · `:905` `getDisplayMedia` (ไม่มี support check)
- **ต้องแก้:** `sfu-client.ts` branch native → publish track จาก plugin
- **ไฟล์ใหม่:** `zyra-mobile/ios/` Broadcast Upload Extension (ReplayKit) · `android/.../ScreenCaptureService.kt` (MediaProjection) · `lib/native/screen-share.ts`
- **ขึ้นกับ:** 1.13

### <a id="t-3-3"></a>3.3 CallKit + VoIP push — ⚠️ ขัดกับ TD §11.1 / §13.1 รอตัดสิน
> **ข้อความเดิม (Phase 3):** งาน — CallKit + VoIP push สำหรับ meeting invite · หมายเหตุ — iOS ต้องผ่าน PushKit review เพิ่ม
- **มีอยู่แล้ว (verified):** ไม่มีโค้ด
- **ผิดจากเอกสาร:** ⚠️ **ขัดกันเอง** — TD §11.1, §13.1, §14.1 A5 บอก "ไม่ทำ / Plan B เท่านั้น" (CallKit แย่ง AVAudioSession กับ WebRTC ใน WKWebView) แต่ task-breakdown ยังมี 3.3 · ต้องตัดสิน: ตัด 3.3 หรือย้ายไปเป็นงานของ Plan B (native LiveKit SDK)
- **ขึ้นกับ:** การตัดสินใจเรื่อง Plan B

### <a id="t-3-4"></a>3.4 Native PiP / Live Activities
> **ข้อความเดิม (Phase 3):** งาน — Native PiP ของวิดีโอประชุม · Live Activities · หมายเหตุ — —
- **มีอยู่แล้ว (verified):** `views/user/virtual-office/use-document-pip.ts`, `use-autopip-eligibility.ts`
- **ต้องแก้:** ปิด `use-autopip-eligibility` บน native (TD §14.1 A4 — ถือ mic ค้างโดยไร้ประโยชน์) · ทำได้ตั้งแต่ Phase 1
- **ไฟล์ใหม่:** plugin `AVPictureInPictureController` (iOS) / Android PiP · ActivityKit extension
- **ขึ้นกับ:** 1.13

### <a id="t-3-5"></a>3.5 ประเมิน bundle asset ลงแอป
> **ข้อความเดิม (Phase 3):** งาน — ประเมิน bundle asset ลงแอป (technical-design §3.2) ถ้าต้องการ offline shell หรือลด dependency กับ server · หมายเหตุ — —
- **มีอยู่แล้ว (verified):** `next.config.ts:35` standalone · `:111-127` rewrites · `app/api/{img,health,version,maintenance-bypass,admin}` · cookie `zyra_token` (`lib/auth/session.ts:19`) + refresh cookie (`zyra-api/internal/handler/auth_handler.go:243`, Secure=false) · `zyra-api/internal/middleware/public_cors.go` · ws origin `zyra-ws/internal/handler/handler.go:76-93`
- **ต้องแก้ (ถ้าทำ):** TD §3.2 ทั้ง 4 ข้อ + `ALLOWED_ORIGINS` เพิ่ม `capacitor://localhost`
- **ขึ้นกับ:** 3.1

---

## <a id="mod-k"></a>K. Infra / CI / store

`zyra-infra/scripts/secret-templates/*`, `zyra-infra/terraform/*`, `.github/workflows/*` ของแต่ละ repo, store console

### <a id="t-0-1b"></a>0.1b build-arg `NEXT_PUBLIC_MOBILE_VO`
เนื้อหาเต็มอยู่ [0.1 ใน module A](#t-0-1) · ส่วนของ module นี้: `zyra-app/Dockerfile:24,27` (ARG) + `:64-65` (ENV) · `zyra-app/.github/workflows/deploy-gitops.yml:142-143` (env) + `:168-169` (`--build-arg`) · GitHub Environment secret ของ dev / uat / production

### <a id="t-1-5c"></a>1.5c secret key ของ login (Google หลายค่า + Apple)
เนื้อหาเต็มอยู่ [1.4](#t-1-4) และ [1.5](#t-1-5) · ส่วนของ module นี้: `zyra-infra/scripts/secret-templates/{dev,uat,prod}/api.json` — `GOOGLE_CLIENT_ID` เป็นค่าคั่น comma (web + iOS + Android) · เพิ่ม `APPLE_CLIENT_IDS` (bundle id + Services ID) · ค่าจริงใส่ใน secret ผ่าน ESO · key ของ 0.57a (min / latest version, store url) ใส่ไฟล์เดียวกัน

### <a id="t-1-12"></a>1.12 CI (TestFlight + Play internal)
> **ข้อความเดิม (Phase 1):** งาน — CI — GitHub Actions: iOS (macos runner + fastlane match/sign + TestFlight), Android (AAB + Play internal) · secrets ใน GitHub Environment · version = tag `v*` · ไฟล์ที่เอกสารเดิมระบุ — zyra-mobile `.github/workflows/` · ขึ้นกับ (เดิม) — 1.2 · Done เมื่อ — push tag → build ขึ้น TestFlight + Play internal อัตโนมัติ
- **มีอยู่แล้ว (verified):** แบบอ้างอิง `zyra-notifications/.github/workflows/deploy-gitops.yml` (develop → dev, main → uat, tag `v*` → prod ผ่าน Environment `production`, `concurrency`) · zyra-app `.github/workflows/{ci.yml, deploy-gitops.yml}` (ci trigger `main`) · zyra-api / zyra-ws มี `deploy-gitops.yml` แบบเดียวกัน
- **ไฟล์ใหม่:** `zyra-mobile/.github/workflows/release.yml` (macOS runner + fastlane match → TestFlight · AAB → Play internal · flavor ตาม tag / branch) · `zyra-mobile/fastlane/{Fastfile, Appfile, Matchfile}`
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** 1.2, Apple / Play accounts

### <a id="t-1-13"></a>1.13 Store listing + review notes
> **ข้อความเดิม (Phase 1):** งาน — Store listing + review notes (test account, workspace demo, วิดีโอ) · submit · ไฟล์ที่เอกสารเดิมระบุ — store consoles · ขึ้นกับ (เดิม) — ทุกข้อใน Phase 1 · Done เมื่อ — approve ทั้งสอง store
- **มีอยู่แล้ว (verified):** ไม่มีโค้ด — งานใน store console · เตรียม test account + workspace demo
- **ผิดจากเอกสาร:** ช่องขึ้นกับเดิม "ทุกข้อใน Phase 1" — ต้องรวม **0.55 (ลบบัญชี — Apple 5.1.1(v))** และ 1.17 (Android FGS) ด้วย
- **ขึ้นกับ:** ทุกข้อใน Phase 1 (รวม 1.17) · 0.55

### <a id="t-2-2"></a>2.2 Firebase + APNs + `FCM_SERVICE_ACCOUNT_JSON`
> **ข้อความเดิม (Phase 2):** งาน — Firebase project + APNs key + service account · ใส่ `FCM_SERVICE_ACCOUNT_JSON` ใน secret ผ่าน ESO (dev/uat/prod) · ไฟล์ที่เอกสารเดิมระบุ — Firebase console, zyra-infra secret · ขึ้นกับ (เดิม) — Apple dev account · Done เมื่อ — secret sync เข้า cluster
- **มีอยู่แล้ว (verified):** `zyra-infra/scripts/secret-templates/{dev,uat,prod}/notifications.json` (keys `PORT, PROJECTNAME, APP_URL, EMAIL_*, NOTIFICATION_API_KEY`) · README ของ template: secret id `zyra-<svc>-<env>-env-json` → ESO `dataFrom.extract` → `envFrom` · `gitops/envs/dev/services/notifications/values.yaml` `secrets.secretId: zyra-notifications-dev-env-json` · prod จาก `terraform/outputs.tf:170` `prod_notifications_env_infra` + `:298` `prod_notifications_env_json` · `terraform/secrets-k8s.tf:31`
- **ต้องแก้:** `notifications.json` 3 env + `terraform/outputs.tf:170,298` เพิ่ม `FCM_SERVICE_ACCOUNT_JSON: ""` (แนะนำ base64 เพราะเป็น JSON ซ้อน JSON) · `zyra-notifications/.env.example`
- **ไฟล์ใหม่:** ไม่มี
- **ผิดจากเอกสาร:** ไม่มี
- **ขึ้นกับ:** Apple Developer account
