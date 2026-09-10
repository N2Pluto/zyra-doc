# SC-ENV-01 · Task Breakdown

> **สถานะ:** แผนแบ่งงาน ยังไม่เริ่มเขียนโค้ด · **วันที่:** 2026-09-09
> อ่านคู่กับ [spec.md](spec.md) (ภาคผนวก D = มติ MD) และ [technical-design.md](technical-design.md) (§12 = สิ่งที่ implement รอบนี้)
> **แหล่งข้อมูลรอบนี้:** Google Maps Platform (Weather + Time Zone + Geocoding) · กรมอุตุนิยมวิทยา · GDACS — Open-Meteo เลื่อน
> ทุก PR แตกจาก `develop` เป็น `feat/sc-env-01-<slug>` ตาม [17-git-branch-workflow](../../../.claude/rules/17-git-branch-workflow.md) · migration ถัดไป = **98**

---

## ภาพรวม

> **ความคืบหน้า (2026-09-10):** ✅ **A1 A2 A3 A4 A5 A6 B1 C1 C2 C4 C6 C7 เสร็จแล้ว (12/17)** · ⏳ เหลือ C3 C5 และ D1–D3 · สถานะเต็ม + วิธีกลับมาทำต่ออยู่ใน [progress.md](progress.md)

| Track | จำนวน PR | เริ่มได้เมื่อ |
|---|---|---|
| A · backend (zyra-api) | 6 | ได้ทันที |
| B · realtime (zyra-ws) | 1 | หลัง A5 |
| C · frontend (zyra-app) | 7 | หลัง A1 (มี contract แล้ว — ระหว่างนั้น mock ได้) |
| D · test + verify | 3 | ตามหลังแต่ละ track |

**งานที่ยังไม่ควรเริ่ม** จนได้คำตอบ: ตารางคำ→ระดับความรุนแรงของกรมอุตุฯ (ข้อ 3/23) กระทบ **A4** · เกณฑ์ "ลมแรง" (ข้อ 11) กระทบ **C3** · effect หิมะ (ข้อ 29) กระทบ **C3** · หน่วยวัด/ภาษา (ข้อ 30/31) กระทบ **C4/C5** · ที่ตั้ง UI ของ toggle owner (ข้อ 34) + HP-07 ซ้ำ toggle เดิม (ข้อ 33) + **emergency ปิดได้ไหม (ข้อ 40)** กระทบ **C5/C6**
ทั้งหมด **ไม่บล็อก A1–A3, B1, C1–C2** — เริ่มได้เลย

**อัปเดต 2026-09-09:** PM เพิ่ม **HP-06** (master switch ปิด workspace location) และ **HP-07** (ปิด alert notification ทั้ง workspace) → ไม่เพิ่ม PR ใหม่ แต่ขยายขอบเขต **A1** (คอลัมน์ `env_location_enabled`) · **A3** (ข้าม fetch เมื่อปิด) · **C4/C5** (สถานะใหม่) · **C6** (master switch + 2 toggle) — ดู [spec ภาคผนวก E](spec.md#ภาคผนวก-e--task-ที่-pm-เพิ่มรอบ-2026-09-09-hp-06-hp-07)

---

## Track A · zyra-api

### A1 — `feat(api): add workspace environment settings`
**Branch** `feat/sc-env-01-api-settings`

- migration `98_environment.sql` + `.down.sql` (ตาม [technical-design §8](technical-design.md#8-db-migration-98)): คอลัมน์ `env_*` บน `tb_workspace` (**รวม `env_location_enabled` master switch ของ HP-06**), ตาราง `tb_environment_snapshot`, `tb_weather_alert`
- `internal/model/environment.go` — `WeatherSnapshot`, `WeatherAlert`, `PlaceRef`, `EnvironmentSettings` (+ `weather_coverage` / `alert_coverage`)
- `internal/service/environment_service.go` — อ่าน/เขียน settings, ตรวจสิทธิ์ owner จาก `tb_workspace.owner_id` (**owner ไม่มีแถวใน member table**)
- `internal/handler/environment_handler.go` + route ใน `router.go` ใต้ `api.Group("/user", middleware.UserGuard(...))`:
  - `GET /api/user/workspaces/{id}/environment` — คืน snapshot (ช่วงนี้ weather/alerts ยังเป็น `null`, coverage = `"none"`)
  - `PUT /api/user/workspaces/{id}/environment` — owner only
- response ใช้ `model.APIResponse` envelope

**DoD** · `go test ./...` เขียว · migration รันบน dev แล้ว · `PUT` ด้วย token ที่ไม่ใช่ owner ได้ 403 · snapshot แยก 3 สถานะได้ (`location_enabled:false` / `location:null` / `weather_coverage:"none"` — [§13.1](technical-design.md#131-แยก-ปิดเอง-ออกจาก-ไม่มีข้อมูล"))

---

### A2 — `feat(api): add google weather, timezone and geocode adapters`
**Branch** `feat/sc-env-01-api-google-adapter` · ต่อจาก A1

- `internal/service/environment/provider.go` — interface `WeatherProvider` / `AlertProvider` / `GeocodeProvider` ([§3](technical-design.md#3-provider-layer--1-interface-หลาย-backend))
- `internal/service/environment/google.go`
  - `currentConditions:lookup` → normalize เป็น `WeatherSnapshot` (map `weatherCondition` → 9 condition ของเรา)
  - Time Zone API → `timeZoneId` (เก็บชื่อ IANA **ห้ามเก็บ offset** — [§11.3](technical-design.md#113-เก็บ-timezone-เป็นชื่อ-iana-ห้ามเก็บ-offset))
  - Geocoding reverse → `PlaceRef` (ชื่อ + country)
- `internal/service/environment/sun.go` — คำนวณ sunrise/sunset/daylight จาก lat/lng เอง (**0 API call**) + คืนสถานะ polar day / polar night ([§12.1](technical-design.md#121-แหล่งข้อมูลต่อหน้าที่))
- `internal/service/environment/coverage.go` — ตาราง `country_code → weather/alert coverage` อ่านจาก config **ไม่ hardcode ในโค้ด service**
- key อ่านจาก env (`GOOGLE_MAPS_API_KEY`) → เข้า secret `zyra-api-<env>-env-json` ไม่ใช่ `NEXT_PUBLIC_*`

**DoD** · unit test map WMO/condition ครบทุกค่า · ประเทศที่ไม่มี coverage **ไม่ยิง API เลย** (ไม่เสียโควตา ไม่ปั่น log) · `sun.go` ผ่านเคส Svalbard 21 ธ.ค. (daylight 0) และ 21 มิ.ย. (86400)

---

### A3 — `feat(api): add environment cache, single-flight and quota guard`
**Branch** `feat/sc-env-01-api-cache` · ต่อจาก A2

- `internal/cache/environment.go` — ตาม pattern `cache/zones.go` (nil-safe, `NewEnvironmentCache(redisURL)` คืน nil เมื่อ URL ว่าง)
  - `env:wx:<cell>` TTL 60 นาที · `env:place:<cell>` ไม่มี TTL · cell = ปัดพิกัด 0.25°
- single-flight ด้วย `SETNX env:lock:<cell>` TTL 20s
- quota guard `env:quota:google:<YYYY-MM>` + soft cap 95% → degrade ตาม EP-01 (cache → snapshot ใน DB ถ้าอายุ ≤ 3 ชม. → default Clear + `stale=true`)
- เขียน `tb_environment_snapshot` ทุกครั้งที่ fetch สำเร็จ

**DoD** · test: cache hit ไม่ยิง provider · lock ตัวที่สองอ่าน cache · เกิน soft cap แล้วยังตอบ 200 พร้อม `stale=true` · ไม่มี panic เมื่อ Redis ปิด · **workspace ที่ปิด location (HP-06) ไม่ยิง provider เลยและไม่ถูกใส่ในชุด cell ของ poller** ([§13.2](technical-design.md#132-ปิดแล้วต้องหยุดยิง-provider-จริง-ไม่ใช่ซ่อน-ui))

---

### A4 — `feat(api): add tmd and gdacs alert pollers`
**Branch** `feat/sc-env-01-api-alert-poller` · ต่อจาก A3 · ⚠️ **ตารางคำ→ระดับ รอมติข้อ 3/23**

- `internal/service/environment/tmd.go` — ดึง `WeatherWarningNews/v2` (XML), parse `IssueNo` / `EffectStartDate` / `EffectEndDate` / `AnnounceDate` / `Title*` / `Headline*` / `WebUrl*`
  - ⚠️ **กับดักจริง:** ใน `<Warning>` เดียวมี `TitleEnglish`/`DescriptionEnglish`/`WebUrlEnglish` **ซ้ำ 2 ชุด — ชุดแรกเนื้อหาเป็นภาษาไทย** ถ้าใช้ `findtext()` แบบเอา element แรกจะได้ไทยไปโชว์ฝั่ง EN → ต้องเลือกชุดหลัง
  - dedup key = `IssueNo` + เลขประกาศจาก title (`195/2569`) + `AnnounceDate` → `tb_weather_alert.source_alert_id`
  - severity: อ่านจากตาราง keyword ใน **config** (ค่าเริ่มต้นชั่วคราว: ทุกประกาศ = `warning`) — เปลี่ยนเป็นตารางจริงเมื่อ PM อนุมัติ **โดยไม่ต้องแก้โค้ด**
- `internal/service/environment/gdacs.go` — `geteventlist/SEARCH?alertlevel=Orange;Red` + **filter ช่วงวันเองเสมอ** (ไม่ใส่วันจะได้ event เก่าติดมา) → map Red = `emergency`, Orange = `warning`
- `main.go` — `runEnvironmentLoop` / `runAlertPollerLoop` ตาม pattern `runSectionCleanupLoop` · **poller เป็น singleton ต่อคลัสเตอร์** ด้วย Redis lock (TMD 5 นาที · GDACS 30 นาที)

**DoD** · test parse XML ตัวอย่างจริง (ยืนยันว่า EN ไม่ได้ค่าไทย) · dedup ไม่สร้างแถวซ้ำเมื่อ poll ซ้ำ · alert หมดอายุถูก mark expired · 2 replica ไม่ poll ซ้อน

---

### A5 — `feat(api): add google weather alerts and coverage routing`
**Branch** `feat/sc-env-01-api-google-alerts` · ต่อจาก A4

- `weatherAlerts` adapter → normalize severity `Extreme→emergency` / `Severe|Moderate→warning` / `Minor→watch` (⚠️ รอยืนยันข้อ 2/22) + เก็บ polygon
- `alertRouteFor(country)` ([§11.1](technical-design.md#111-เลือก-provider-จาก-country_code-ไม่ใช่จาก-config-เดียวทั้งระบบ)): `TH → TMD+GDACS` · ประเทศที่ Google มี → `Google+GDACS` · อื่น → `GDACS` เท่านั้น
- เติม `alert_coverage` = `full | disaster_only` และ `weather_coverage` = `full | none` ลง snapshot
- กรอง alert ตาม polygon เทียบพิกัด workspace (เฉพาะที่มาจาก Google) · alert ของกรมอุตุฯ = ระดับประเทศ/ภาค (⚠️ ข้อ 4)

**DoD** · test routing ต่อประเทศครบ 5 กลุ่มใน [spec §D.2](spec.md#d2-ความสามารถต่อประเทศในรอบแรก) · workspace ในจีนได้ `weather_coverage:"none"` และไม่มี call ออกไปหา Google

---

### A6 — `feat(api): publish environment events and bell notifications`
**Branch** `feat/sc-env-01-api-events` · ต่อจาก A5

- `internal/cache/environment_events.go` — publish ลง channel `vo:zone` ที่ zyra-ws subscribe อยู่แล้ว (pattern จาก `cache/zone_events.go`) 2 type ใหม่: `environment_changed`, `weather_alert`
- **publish เฉพาะเมื่อค่าที่ส่งผลต่อภาพเปลี่ยน** (condition / severity / location / toggle) ไม่ใช่ทุกครั้งที่อุณหภูมิขยับ 0.1°
- alert ใหม่ → สร้าง notification เข้า bell panel ผ่าน `NotificationService` ที่มีอยู่
- `PUT settings` → fetch ใหม่ทันที (bypass TTL 1 ครั้ง) แล้ว publish → members เห็นภายใน 5 วินาที (AC HP-01/EC-03)

**DoD** · เปลี่ยน location แล้วเห็น event ออกจาก Redis จริง · เปลี่ยนแค่อุณหภูมิไม่ publish · notification ไม่ซ้ำเมื่อ poll ซ้ำ

---

## Track B · zyra-ws

### B1 — `feat(ws): relay environment and weather alert events`
**Branch** `feat/sc-env-01-ws-relay` · ต่อจาก A6

- เพิ่ม 2 case ใน subscriber ของ `zoneEventChannel` (`internal/store/redis.go` จุดที่ subscribe อยู่แล้ว) → broadcast เข้า workspace room
- **ต้องอ่านก่อนแก้:** ยังไม่ได้ตรวจว่ามี default case ที่ทิ้ง type ไม่รู้จักเงียบ ๆ หรือไม่ — ถ้ามี ต้องเพิ่ม log
- อัปเดตคอมเมนต์รายการ type ที่หัวไฟล์ให้ครบ

**DoD** · `go test ./...` เขียว · ทดสอบด้วย `redis-cli PUBLISH vo:zone '{...}'` แล้ว client ใน room ได้รับ

---

## Track C · zyra-app

### C1 — `feat(app): add environment feature flag and api client`
**Branch** `feat/sc-env-01-app-client` · ต่อจาก A1 (ใช้ contract; mock ได้ระหว่าง A2–A6)

- `lib/environment-feature.ts` — flag `NEXT_PUBLIC_ENVIRONMENT` **default off** (คัดลอกแนวจาก `lib/room-pet-feature.ts` — ต้องเป็นสตริง `"true"` เท่านั้น) + เพิ่ม build-arg ใน Dockerfile และ `deploy-gitops.yml` ทั้ง 3 environment
- `lib/environment.ts` — `getEnvironment(workspaceId)`, `saveEnvironment(...)`, `searchPlaces(q)`, `reversePlace(lat,lng)` — **ทุกตัวชี้ `/api/user/*` เท่านั้น** ([15-member-api-separation](../../../.claude/rules/15-member-api-separation.md))
- hook `use-environment.ts` — TanStack Query fetch ตอน mount + subscribe ws 2 event + คำนวณ stage ฝั่ง client จาก `server_time` + `timezone` + `sun` (มี polar branch)

**DoD** · flag off → ไม่มี network call ออกไปที่ `/environment` เลย · `npx tsc --noEmit` และ `npm run lint` ผ่าน · vitest ครอบการคำนวณ stage รวมเคสขั้วโลก

---

### C2 — `feat(app): add time-of-day lighting layer on pixi scene`
**Branch** `feat/sc-env-01-app-time-of-day` · ต่อจาก C1

- overlay layer ใน `components/game-canvas/pixi-canvas.tsx` — **Pixi ไม่ใช่ Phaser** (spec เขียนผิด engine)
- ค่าสี 5 stage ตาม [spec](spec.md#time-of-day-stages) · fade 30 วินาทีเมื่อเปลี่ยน stage · z อยู่เหนือ map ใต้ HUD
- DOM overlay ที่วางข้าง canvas ต้องกำหนด z ชัดเจน ไม่งั้นจะไปอยู่หลังแมพ (บทเรียนจาก pet panel)
- ปิด effect (HP-05) → ไม่ mount layer

**DoD** · เดินได้ปกติตอน Night · เปลี่ยน stage ไม่กระตุก · FPS ไม่ตกจากก่อนใส่ layer (วัดด้วย build production ไม่ใช่ `next dev`)

---

### C3 — `feat(app): add weather effect layers`
**Branch** `feat/sc-env-01-app-weather-fx` · ต่อจาก C2 · ⚠️ **เกณฑ์ลมแรง (ข้อ 11) + หิมะ (ข้อ 29) รอมติ**

- particle/overlay ต่อ condition ตามค่าใน [HP-03](spec.md#hp-03--weather-real-time-เปลี่ยน-visual-บน-map): drizzle 50 / rain 200 / thunderstorm 500 drops/s · lightning flash 5–15 วินาที ค้าง 80ms · cloudy / fog overlay
- ใช้ `ParticleContainer` ของ Pixi (ไม่ใช่ Sprite ต่อเม็ด) · หยุด ticker เมื่อ layer ไม่ทำงาน
- **AC: ไม่ต่ำกว่า 30 FPS บนเครื่องระดับกลาง** → ต้องวัดจริง ไม่ใช่ประเมิน

**DoD** · วัด FPS ก่อน/หลังบน production build แล้วบันทึกตัวเลข ([18-before-after-metrics](../../../.claude/rules/18-before-after-metrics.md)) · สลับ condition ไม่ leak particle · เสียงฟ้าร้องผูกกับ toggle (ถ้ามติให้มี)

---

### C4 — `feat(app): add weather widget and detail popup` ✅ **เสร็จ 2026-09-09**
**Branch** `feat/sc-env-01-app-client` (รวมกับ C1/C2 ไม่แตกใหม่) · commit `6b884b5` + api `6142a24` · [PR #336](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/336)
⚠️ ยังค้าง: หน่วยวัด (ข้อ 30) — ตอนนี้ตรึงเป็น °C / km/h ตาม design · ป้ายแหล่งข้อมูล (ข้อ 12/43) — แสดงชื่อ provider ที่ตอบจริงจาก `weather.source` แทนคำว่า Open-Meteo ใน design
🆕 พบ 5 ช่องว่างของ design (ข้อ **52–56**) ดู [ux-ui-plan §9.2](ux-ui-plan.md#92-สิ่งที่-design-ไม่มี-แต่-spec-บังคับ) — ข้อ 52 (ไม่มีตัว widget บน map) และข้อ 56 (การ์ด "Your weather") ต้องได้คำตอบก่อนปิดงานจริง

- widget มุมขวาบนของ map: icon + อุณหภูมิ + ชื่อสถานที่ + เวลา/เขตเวลา (tooltip "เวลาตามสถานที่ของ Workspace" ตาม EC-01)
- กดเปิด popup: อุณหภูมิ / ความชื้น / ลม / แหล่งข้อมูล / เวลาที่อัปเดต · badge "ข้อมูลอาจไม่อัปเดต" เมื่อ `stale`
- 3 สถานะที่ต้องแยกข้อความ ([§13.1](technical-design.md#131-แยก-ปิดเอง-ออกจาก-ไม่มีข้อมูล")): owner ปิดเอง (HP-06) / ยังไม่ตั้ง location / provider ไม่ครอบคลุม — **ห้ามยุบเป็นข้อความเดียว** และห้ามแสดงเป็น error
- Tailwind utility เท่านั้น ห้าม `@/components/ui/*` · icon จาก `lucide-react` เท่านั้น

**DoD** · vitest: 5 สถานะ (ปกติ / stale / ไม่มี coverage / owner ปิด location / ยังไม่ตั้ง location) · ปิด weather effect แล้ว widget ยังแสดง (AC HP-05) · ปิด location แล้ว widget หาย (AC HP-06)

---

### C5 — `feat(app): add weather alert banner and bell entry`
**Branch** `feat/sc-env-01-app-alert-banner` · ต่อจาก C1 · ⚠️ ภาษาประกาศ (ข้อ 31) รอมติ

- banner บน VO HUD 3 ระดับ: 🟡 watch · 🟠 warning · 🔴 emergency
- **emergency ปิดไม่ได้** จนกว่า `expires_at` ถึง (safety rule) · watch/warning กด X ได้แต่ยังอยู่ใน bell
- หลาย alert พร้อมกัน → แสดง severity สูงสุดก่อน
- "อ่านเพิ่มเติม" → เปิดลิงก์ต้นทาง (**ของกรมอุตุฯ เป็นไฟล์ PDF และ URL มีอักขระไทยต้อง encode**)
- `alert_coverage: "disaster_only"` → ไม่โฆษณาว่ามีระบบเตือนภัยครบ
- owner ปิด alert notification (HP-07) → ไม่มี banner และไม่มี bell entry แต่ widget ยังทำงาน · ⚠️ **ข้อ 40: ยังไม่ชัดว่า emergency (แดง) ปิดได้ด้วยไหม** — EC-02 บอกว่าปิดไม่ได้ ⇒ **อย่า implement การปิดระดับแดงจนได้คำตอบ**

**DoD** · vitest: emergency ไม่มีปุ่มปิด · dismiss แล้ว reload ยังไม่โผล่ซ้ำ (แต่ยังอยู่ใน bell) · alert หมดอายุ banner หายเอง

---

### C6 — `feat(app): add workspace environment settings for owner` ✅ **เสร็จ 2026-09-10**
**Branch** `feat/sc-env-01-app-client` (รวมกับ C1/C2/C4) · commit `31b92f4` · [PR #336](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/336) · **ครอบ HP-01 + HP-06 + HP-07**
ข้อ 9 / 34 / 33 **ตอบแล้วจาก design เอง** — ไม่มี picker เลย เป็น toggle ขอตำแหน่งจากเบราว์เซอร์ · อยู่ใน Setting modal tab ที่ 7 · HP-07 คือ toggle เดิมไม่ใช่ตัวใหม่

- section ใหม่ใน `views/user/workspace/` — location ปัจจุบัน + ปุ่มเปลี่ยน + **master switch "Workspace location" (HP-06)** + 3 toggle (time of day / weather / alerts — ตัวที่ 3 คือ HP-07) + preview อากาศปัจจุบัน
- ปิด master switch → ทุก toggle ข้างล่าง disable · **ค่า location ต้องยังอยู่** เปิดกลับได้ทันที
- ⚠️ **ที่ตั้ง UI ยังค้าง (ข้อ 34)** — HP-06/07 เขียนว่าอยู่ที่ Settings บน VO HUD ซึ่งเป็นที่เดียวกับ personal setting ของ HP-05 · ถ้า PM ยืนยันให้อยู่ที่นั้น ต้องแยกหัวข้อ "ทั้ง workspace" ออกจาก "ของฉัน" ให้ชัด และซ่อนสำหรับ non-owner
- location picker: ปักหมุด → `reversePlace()` แสดงชื่อ (+ ช่องค้นชื่อเมืองถ้ามติให้มี)
- ประเทศที่ coverage ไม่ครบ → แสดงตรง ๆ ในหน้านี้ก่อนบันทึก (3 สถานะตาม EP-02 ที่แก้แล้ว)
- **spec จาก Figma 9 node ยังไม่ได้ถอด** — ต้องดึงจาก Figma MCP ก่อนลงมือ ห้ามเดา px/hex ([10-figma-fidelity](../../../.claude/rules/10-figma-fidelity.md))

**DoD** · non-owner ไม่เห็น section นี้ · บันทึกแล้ว member อื่นเห็นภายใน 5 วินาที (ทดสอบ 2 browser) · ค่าจาก Figma ตรง 95–100%

---

### C7 — `feat(app): add personal visual effects preferences` ✅ **เสร็จ 2026-09-10**
**Branch** `feat/sc-env-01-app-prefs` · ต่อจาก C2 + C3

- 2 toggle ใน Setting ที่มีอยู่: time-of-day lighting / weather effects + ปุ่ม "ปิดทั้งหมด"
- เก็บใน settings JSONB blob เดิม (ไม่สร้าง endpoint ใหม่) · persist ข้าม session
- ปิด time-of-day → แสดง default lighting (Morning) · ปิด weather → particle หายแต่ widget ยังอยู่
- **ไม่มี toggle สำหรับ alert** — เป็น workspace-level (owner เท่านั้น)

**DoD** · reload แล้ว preference คงอยู่ · เปิดใหม่ effect กลับมาตรงกับเวลา/อากาศปัจจุบัน · vitest ครอบทั้ง 4 คู่สถานะ

---

## Track D · test + verify

### D1 — `test(api): environment service coverage`
table-driven ตาม [04-test](../../../.claude/rules/04-test.md): condition mapping · severity mapping · stage/solar (รวม polar) · quota guard · dedup · coverage routing · TMD XML parse (ทั้งกับดัก field ซ้ำ) · GDACS date filter
**เป้า** `internal/service/environment/*` ≥ 80%

### D2 — `test(app): environment client coverage`
vitest + `vi.mock` (ห้ามยิง `/api/*` จริง): stage calc · effect selection · widget 3 สถานะ · banner dismissible rule · flag off = ไม่มี call
**เป้า** `lib/environment*.ts` ≥ 80%

### D3 — verify บน dev แล้วบันทึกผล
- 2 browser คนละ account: เปลี่ยน location → เห็นเหมือนกันภายใน 5 วินาที
- ยิง alert ทดสอบ → banner ขึ้นทั้งสองฝั่ง + emergency ปิดไม่ได้ + หมดอายุแล้วหายเอง
- ตั้ง location ที่โตเกียว (ไม่มี weather) → แสงตามเวลายังทำงาน widget แจ้งถูกต้อง
- **วัด FPS + จำนวน call ที่ยิงออกจริงต่อชั่วโมง** เทียบกับที่ประเมินไว้ แล้วบันทึกใน `progress.md`
- ตรวจว่าโควตาที่ใช้จริงตรงกับตารางใน [technical-design §12.3](technical-design.md#123-โควตารอบแรก-google-อย่างเดียว)

---

## ลำดับที่แนะนำ

```
A1 ─┬─ A2 ── A3 ── A4 ── A5 ── A6 ── B1
    │                                 │
    └─ C1 ─┬─ C2 ── C3 ──────────────┤
           ├─ C4                      ├── D3 (verify บน dev)
           ├─ C5 ─────────────────────┘
           ├─ C6
           └─ C7
D1 ตามหลัง A5 · D2 ตามหลัง C5
```

**เริ่มวันนี้ได้เลย:** A1 · A2 · A3 · C1 (ไม่มีข้อไหนรอมติ)
**ต้องมีคำตอบก่อนปิด:** A4 (ตารางคำ→ระดับ) · A5 (ยืนยัน severity mapping) · C3 (ลมแรง + หิมะ) · C4/C5 (หน่วย + ภาษา) · C6 (ปักหมุด/ค้นชื่อ + Figma)
