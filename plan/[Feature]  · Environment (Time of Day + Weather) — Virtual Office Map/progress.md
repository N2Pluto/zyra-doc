# SC-ENV-01 · Progress

> entry ใหม่อยู่**บนสุด** · แยก "build เขียว" ออกจาก "live-test ผ่าน" ให้ชัดทุกครั้ง

## สถานะล่าสุด — 2026-09-09

**เสร็จ 10 / 17 PR** · ฝั่ง server ครบ (Track A + B) · ฝั่งหน้าบ้านทำแล้ว 3 ใน 7 (C1 + C2 + C4) — **แสงตามเวลา + widget สภาพอากาศขึ้นจอแล้ว**

| Repo | Branch | Commit | PR (draft, base `develop`) |
|---|---|---|---|
| zyra-api | `feat/sc-env-01-api-settings` | **7** (A1–A6 + `precip_pct`) | [zyra-api#108](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/108) |
| zyra-ws | `feat/sc-env-01-ws-relay` | **1** (B1) | [zyra-ws#64](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/64) |
| zyra-app | `feat/sc-env-01-app-client` | **3** (C1, C2, C4) | [zyra-app#336](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/336) |

**ทั้ง 3 PR เป็น draft และยังไม่ merge** — ตั้งใจ เพราะยังไม่เคยยิง provider ด้วย key จริง · merge เข้า `develop` = deploy dev อัตโนมัติ ซึ่งตอนนี้จะพา flag ที่ปิดอยู่ขึ้นไปเฉย ๆ
⚠️ **ห้ามใช้ `gh pr merge --auto` บน zyra-app** — merge ทันทีไม่เข้าคิว (ดู [[gh-auto-merge-not-queued]])

**Migration:** 98 / 99 / 100 **รันบน dev แล้ว** (ยืนยันคอลัมน์ + index + constraint ทุกตัว) · **ยังไม่รันบน uat/prod**

**เริ่มทำต่อที่:** C7 (personal prefs — ไม่ติดอะไร) หรือ C3 (weather effects บน Pixi) ที่ยังติด asset 1× ของ 3 ไฟล์ (ข้อ 48) + เกณฑ์ลมแรง (ข้อ 11) · C5 (alert banner) ยังติดมติ severity + ข้อ 40 · C6 (owner settings) ต้องถอด Figma เพิ่ม

### วิธีกลับมาทำต่อ

**ทั้ง 3 branch อยู่บน remote แล้ว** (push 2026-09-09) — ดึงมาทำต่อได้จากที่ไหนก็ได้:

```bash
git fetch origin && git checkout feat/sc-env-01-api-settings   # หรือ -ws-relay / -app-client
```

โค้ดที่ทำอยู่เดิมอยู่ใน git worktree ใต้ scratchpad ของ session ซึ่ง **หายได้** แต่ commit อยู่ทั้งใน repo จริงและบน remote แล้ว จึงไม่หาย:

```bash
cd zyra-api && git log --oneline develop..feat/sc-env-01-api-settings   # 6 commit ยังอยู่
git worktree list                                                        # ดูว่า worktree เดิมยังอยู่ไหม
# ถ้า worktree หายไปแล้ว — ล้างทะเบียนแล้วสร้างใหม่ที่ไหนก็ได้
git worktree prune
git worktree add /path/ใหม่ feat/sc-env-01-api-settings
```

ถ้าจะ `next build` ใน worktree ของ zyra-app: Turbopack ไม่ยอม `node_modules` ที่เป็น symlink ออกนอก filesystem root ⇒ ใช้ `cp -al` (hardlink copy) จาก checkout หลัก

### ยังต้องได้จากคนอื่นก่อนจะ verify ได้ครบ

| # | รออะไร | บล็อกอะไร |
|---|---|---|
| 1 | `GOOGLE_MAPS_API_KEY` + เปิด billing + เปิด 3 API (Weather / Time Zone / Geocoding) | verify weather + alert ของจริงทั้งเส้น |
| 2 | `TMD_UID` / `TMD_UKEY` ในนามบริษัท | alert ไทย (ตอนนี้ทดสอบด้วย fixture ที่จำลอง defect จริง) |
| 3 | `ENVIRONMENT_ENABLED=true` บน dev | ทั้งฟีเจอร์ (default off โดยเจตนา กันยิง provider ไม่ตั้งใจ) |
| 4 | มติ severity 2 ข้อ — [ข้อ 2/22](spec.md#a6-ข้อเสนอให้-pm-ตัดสิน-เพิ่มจาก-12-ข้อเดิม) (Google) และ [3/23](spec.md#e2-จุดที่ขัดกับของเดิม--ต้องเคลียร์ก่อน-implement) (keyword ของ TMD) | C5 — กระทบกฎ "แดงปิดไม่ได้" (EC-02) |
| 5 | asset ขนาด 1× ของ `shooting-star` / `bg` / `leaf2` ([ข้อ 48](spec.md#ภาคผนวก-f--asset-ที่ได้รับ-2026-09-09-และสิ่งที่ต้องเพิ่มใน-spec)) | C3 — `shooting-star` กิน ~153 MB ตอน decode |
| 6 | [ข้อ 40](spec.md#e2-จุดที่ขัดกับของเดิม--ต้องเคลียร์ก่อน-implement) — owner ปิด alert ระดับแดงได้ไหม | C5 |

### verify แล้วจริงเท่าไหน (แยกให้ชัด)

**ผ่านจริง**
- `go build` / `go vet` / `go test ./...` เขียวทั้ง zyra-api และ zyra-ws · `eslint` + `vitest` (49 เคส) + **`next build` production** เขียวที่ zyra-app
- **relay ผ่าน Redis จริง** — publish 3 ข้อความ มี warn drop เฉพาะ control case
- **migration รันจริงบน dev** ทั้ง 3 ตัว
- สูตรดวงอาทิตย์ **pin กับค่าจริงของ provider** 4 เมือง (Bangkok/London/Sydney/Svalbard) + polar 2 ฤดู

**ยังไม่ผ่าน / ยังไม่เคยทำ**
- ❌ **ยังไม่เคยยิง Google หรือ TMD ด้วย credential จริง** — ทุกอย่างเป็น httptest mock ตาม schema ที่ดึงจาก reference ของ provider
- ❌ **ยังไม่เคยเห็นแสงหรือ widget จริงบนจอด้วยตา** — ต่อเข้า `hero-virtual-office.tsx` แล้วและ build เขียว แต่ยังไม่มี live run (ต้องมี key + `ENVIRONMENT_ENABLED=true`) · ยังไม่ได้วัด FPS ก่อน/หลังตาม DoD ของ C2
- ❌ **ยังไม่เคยเห็นค่า `precip_pct` จาก Google จริง** — mapping มาจากเอกสาร `currentConditions` + test ที่ mock ทั้งกรณีมีและไม่มีฟิลด์
- ❌ dedup กับ DB จริง (`xmax = 0`), poller lock กับ Redis จริง, insert notification จริง — ยังไม่ทดสอบ
- ❌ ยังไม่มี e2e ตั้งแต่ poller → ws → client

---

## รอบที่ 10 — 2026-09-09 · C4 (weather widget + panel) · **มีของกดดูได้แล้ว**

**ทำอะไร** — `zyra-app` commit `6b884b5` (PR #336) + `zyra-api` commit `6142a24` (PR #108)

ดึง Figma ก่อนเขียนตาม rule 10 แล้วพบว่า **สิ่งที่ spec เรียกว่า "popup" คือ panel ฝั่งขวาเต็มความสูง** (`4779:680515`, 458×992) ที่มีการ์ด `Weather widget` (`4779:680767`, 442×170) อยู่ข้างใน — ค่าที่ดึงมาทั้งหมดอยู่ใน [ux-ui-plan §9.1](ux-ui-plan.md#91-ค่าที่ดึงมาจริงห้ามเดาเพิ่ม)

1. **`lib/environment-weather-display.ts`** — logic ล้วน แยกออกมาให้ทดสอบได้: `weatherPanelState`, `weatherIconKey`, `formatWeatherTimestamp`, `formatUtcOffset`, `formatTemperature`
   - `weatherPanelState` คืน **5 สถานะ** และสถานะ `ready` **พาข้อมูลไปด้วย** (`weather` + `location`) ⇒ เรียกวาดการ์ดโดยไม่มีค่าไม่ได้เลยตั้งแต่ระดับ type ไม่ต้องมี `!`
   - **`unsupported_area` ชนะ `loading`**: ที่ญี่ปุ่นไม่มีค่ามาแน่นอน ถ้าโชว์ "กำลังตรวจสภาพอากาศ…" คือสัญญาสิ่งที่ทำไม่ได้
   - **`isLoading` เป็น argument** เพราะ snapshot ที่ยังไม่มา ถ้าไม่บอก จะอ่านเป็น "ยังไม่ได้ตั้ง location" แล้วไปบอก owner ให้ไปตั้งของที่ตั้งอยู่แล้ว
   - `formatWeatherTimestamp` เลื่อน instant ด้วย offset ของ workspace แล้ว format แบบ UTC ⇒ ได้ **นาฬิกาของ workspace** ไม่ว่าเครื่องอยู่โซนไหน (EC-01) · ใช้ `hourCycle: "h23"` เพราะ `hour12:false` ทำให้บางภาษาแสดงเที่ยงคืนเป็น `24:00`
2. **`components/vo-weather-panel.tsx`** — `VOWeatherPanel` (panel + การ์ด) + `VOWeatherBadge` (chip บน map) · Tailwind arbitrary values ล้วน (rule 08) · icon lucide ล้วน (rule 12)
3. **ต่อเข้า `hero-virtual-office.tsx`** — ใช้ slot มุมขวาบนเดิมร่วมกับ pet/player/PZ card และ **หลบให้ทั้งสาม**
4. **เปิด panel = refetch** (`refresh()` ใหม่ใน `use-environment.ts`) — เพราะ `environmentSignature` ฝั่ง server **ตัด temperature/humidity/wind ออกโดยเจตนา** (ไม่ใช่ค่าที่วาด) ⇒ ถ้าไม่มี refetch ตัวเลขในการ์ดจะค้างอยู่ที่ค่าตอน member เข้าห้อง · 1 request บน cell ที่ cache ไว้แล้ว ตอนที่มีคนเปิดดูจริง
5. **`precip_pct` ฝั่ง api** — การ์ดมีแถว `Precipitation:` แต่ `WeatherSnapshot` ไม่มีฟิลด์นี้ ทั้งที่ Google ส่งมาใน `currentConditions` · ทำเป็น **pointer** เพราะ "0% = ไม่มีฝน" ต่างจาก "provider ไม่รายงาน" (การ์ดแสดง `—`) · **ไม่ใส่ใน broadcast signature** — ไม่ใช่ค่าที่วาด และเปลี่ยนทุก fetch จะกลายเป็น push ทุกรอบเพื่อเลขที่มองบนแมพไม่เห็น

**5 จุดที่ design ไม่มีแต่ spec บังคับ** (บันทึกเป็นข้อ 52–56 ใน [ux-ui-plan §9.2](ux-ui-plan.md#92-สิ่งที่-design-ไม่มี-แต่-spec-บังคับ))
- **ข้อ 52 — ไม่มีตัว widget บน map และไม่มีปุ่มเปิด panel เลย** ทั้งที่ HP-03 เขียนว่า "widget มุมขวาบน · กดเปิด popup" ⇒ สร้าง `VOWeatherBadge` จาก **token ของการ์ดเอง** ไม่คิดค่าใหม่ · ถ้า design ทำมาให้ต้องแก้ตาม
- **ข้อ 53** ไอคอนในการ์ดเป็นภาพ 3D ที่ยังไม่ส่งมอบ (ต่อจากข้อ 49) ⇒ lucide แทนใน**กรอบเดิม** (107px / 64×51)
- **ข้อ 54** ไม่มีเฟรมของ stale และของ 3 สาเหตุที่ไม่มีข้อมูล ⇒ ทำจาก token เดิม
- **ข้อ 55** ไม่มีฟิลด์ precipitation ⇒ เพิ่มฝั่ง api
- **ข้อ 56** การ์ด "Your weather" ยังทำไม่ได้ (ผูกข้อ 42/45 ที่ยังไม่ตัดสิน) ⇒ `WeatherCard` รับ label เป็น prop ไว้แล้ว เพิ่มการ์ดที่ 2 = เพิ่ม call site เดียว

**verify ถึงไหน**
- ✅ eslint สะอาด · `next build` production เขียวพร้อม `NEXT_PUBLIC_ENVIRONMENT=true`
- ✅ **vitest 27 เคสใหม่** — `environment-weather-display` 15 + `vo-weather-panel` (render จริงด้วย RTL) 12 · ครบ DoD 5 สถานะ + **AC HP-05** (ปิด effect แล้ว widget ยังรายงาน) + **AC HP-06** (ปิด location แล้ว chip หายจริง) + เคส "3 ข้อความต้องไม่ซ้ำกัน" ที่ fail ถ้าใครมายุบรวม
- ✅ `go test ./internal/service/` เขียว — เพิ่ม 2 เคสของ `precip_pct` (มีฟิลด์ → 40, ไม่มีฟิลด์ → nil ไม่ใช่ 0)
- ❌ **ยังไม่เคยเห็นบนจอจริง** — ต้องมี Google key + `ENVIRONMENT_ENABLED=true`
- ⚠️ `npx tsc --noEmit` มี error 3 ตัวใน `__tests__/pet-creation-wizard.test.tsx` + `__tests__/pixi-game-scene.test.ts` — **มีอยู่บน `develop` ก่อนแล้ว** ไม่เกี่ยวกับ C4 (ยืนยันด้วยการเทียบไฟล์บน `origin/develop`)

**ต่อจากนี้** — C7 (personal prefs, ไม่ติดอะไร) หรือ C3 ถ้าได้ asset ครบ

**ติดอะไร** — เหมือนเดิม (credential 2 ชุด, flag ฝั่ง server, มติ severity 2 ข้อ, asset 1× 3 ไฟล์) · เพิ่ม: **ข้อ 52 ต้องให้ design ยืนยันตัว widget บน map** และ **ข้อ 56 รอมติ "My location" (ข้อ 42/45)** ก่อนจะทำการ์ด "Your weather"

## รอบที่ 9 — 2026-09-09 · C2 (แสงตามเวลาบน Pixi) · **เห็นผลบนจอได้แล้ว**

**ทำอะไร** — `zyra-app` commit `73ff8c3` (push แล้ว, อยู่ใน PR #336 เดิม)

1. **`lib/environment-tint.ts`** — ตาราง stage → {color, alpha} แปลงจาก rgba() ใน spec ตรง ๆ + `STAGE_FADE_MS = 30_000` + `shouldRenderStageTint()`
   - **morning = alpha 0** ไม่ใช่ขาวจาง ๆ ⇒ ที่ 0 layer หยุดวาดทั้งหมด เคสกลางวัน (พบบ่อยสุด) จึงไม่มี draw call
   - stage ว่าง (ไม่มี location / ปิดฟีเจอร์) → ไม่วาดอะไร **ไม่ใช่ default wash** ที่จะทำให้แมพของ workspace ที่ปิดฟีเจอร์มืดลง
   - **gate เป็น AND 4 ชั้น**: build flag (เรา) + server switch (ops) + location toggle + time-of-day toggle (owner) — HP-05/HP-06 ขึ้นอยู่กับข้อนี้ มี test ต่อวิธีปิดแต่ละแบบ
2. **`zyra-engine/pixi-game/scene.ts`** — `_envTintGfx` (screen-space Graphics) + `setEnvironmentTint(color, alpha, fadeMs)` + `_drawEnvironmentTint()` ใน render loop
   - **วางใต้ `screenOverlay`** เพราะ layer นั้นถือ zone/spotlight effect ซึ่งเป็น "ไฟที่ส่อง" ต้องชนะแสง ambient ไม่ใช่ถูกกดให้มืด
   - fade ขับด้วย **elapsed frame time** ไม่ใช่สัดส่วนต่อเฟรม ⇒ 30 วินาทีเท่ากันทั้งที่ 30fps และ 144fps (canvas ไม่มี CSS ให้ transition จึงต้องทำในเอนจิน)
   - **fade ออกทันที** (ไม่รอ 30 วิ) เมื่อ toggle ถูกปิด — คนกดปิดแล้วต้องเห็นผลเดี๋ยวนั้น ไม่งั้นเหมือน toggle เสีย
   - repaint เฉพาะเมื่อ สี/alpha/ขนาด viewport เปลี่ยน · setter idempotent ⇒ React เรียกทุก render ได้ไม่รีเซ็ต fade
3. **`PlayTestHandle.setEnvironmentTint?`** (optional เหมือน `setRenderSuspended` เพราะ GameCanvas ตัวเก่าไม่มี) + expose ใน `pixi-canvas.tsx`
4. **ต่อ hook เข้า `hero-virtual-office.tsx`** — hook รับ **ref ของ ws client + `connectionStatus` เป็น re-subscribe key** (อ่าน ref ตอน render คือสิ่งที่ React Compiler lint ห้าม) ⇒ reconnect แล้ว handler ผูกกับ socket ใหม่
5. **`FakeGraphics` ใน scene test บันทึก fills** ⇒ ทดสอบได้ว่า "วาดอะไรจริง" ไม่ใช่แค่ "ไม่ crash"

**verify ถึงไหน**
- ✅ eslint สะอาด · tsc ไม่มี error ใหม่ · **`next build` production เขียวพร้อม flag เปิด**
- ✅ **vitest ทั้ง suite เขียว: 140 ไฟล์ / 1,879 test** (ของใหม่ 21 เคส — scene 6: fade เป็น time-based, clear เมื่อ fade จบ, skip redraw, repaint ตอน resize, re-target ไม่รีเซ็ต, clamp alpha · tint table + gate 15)
- ❌ **ยังไม่เคยเห็นด้วยตาบนจอจริง** — ต้องมี Google key + `ENVIRONMENT_ENABLED=true` บน dev
- ❌ **ยังไม่ได้วัด FPS ก่อน/หลัง** ตาม DoD ของ C2 (ต้องวัดบน production build ไม่ใช่ `next dev`)

**ต่อจากนี้** — C3 (weather effects) ⚠️ ติด asset 1× 3 ไฟล์ + เกณฑ์ลมแรง · หรือข้ามไป C4 (widget) / C7 (personal prefs) ที่ไม่ติดอะไร

**ติดอะไร** — เหมือนเดิม (credential 2 ชุด, flag ฝั่ง server, มติ severity 2 ข้อ, asset 1× 3 ไฟล์)

## รอบที่ 8 — 2026-09-09 · C1 (flag + api client + hook ฝั่ง app)

**ทำอะไร** — `zyra-app` commit `5d99542` บน `feat/sc-env-01-app-client` (แตกจาก `origin/develop` @ b1a7e62)

1. **`lib/environment-feature.ts`** — flag `NEXT_PUBLIC_ENVIRONMENT` **default off** (build-time, คนละตัวกับ `ENVIRONMENT_ENABLED` ฝั่ง API ที่เป็น runtime — ต้องเปิดทั้งคู่) + build-arg ใน `Dockerfile` และ `deploy-gitops.yml` ตาม pattern ของ pet flags
2. **`lib/api/environment.ts`** — types ครบทั้ง snapshot/settings/alert + `getEnvironment` / `saveEnvironment` ชี้ `/api/user/*` เท่านั้น (rule 15) · มี test ยืนยันว่า URL ไม่มี `/api/admin/`
3. **`lib/environment-stage.ts`** — คำนวณ stage ฝั่ง client (pure, ทดสอบได้): `stageAt`, `locationMinutesOfDay`, `clockToMinutes`, `serverClockOffsetMs`, `msUntilNextStageBoundary`
   - derive จาก **นาฬิกาของ server** (server_time + offset ที่วัดกับเครื่อง) ไม่ใช่ของเครื่อง ⇒ EC-01 (คนละ timezone เห็น stage เดียวกัน) + ทนเครื่องที่นาฬิกาเพี้ยน
   - polar: ตัดสินด้วย `daylight_seconds` **ก่อน** อ่าน sunrise/sunset
   - timer **นอนถึง boundary ถัดไป** ไม่ใช่ tick ทุกวินาที
4. **`lib/api/workspace-ws-types.ts`** — เพิ่ม 2 event เข้า union (`environment_changed`, `weather_alert`) ⇒ `client.on(...)` ได้ type-safe
5. **`use-environment.ts`** — fetch 1 ครั้งตอน mount + subscribe ws · **ไม่มี polling เลย** (server publish เฉพาะเมื่อค่าที่วาดเปลี่ยน ⇒ refetch loop จะย้ายต้นทุนจาก provider มาที่ zyra-api ต่อ member ต่อ tick) · alert ที่หมดอายุถูก **ลบออกจาก cache** ไม่ใช่กรองตอน render (banner emergency ที่ปิดไม่ได้ต้องหายจริงเมื่อหมดอายุ)

**2 จุดที่ React Compiler lint บังคับให้เขียนดีขึ้น**
- ห้าม `setState` ตรง ๆ ใน effect → เปลี่ยนเป็น derive + timer callback
- ห้ามเรียก `Date.now()` ตอน render (impure) → ย้ายการอ่านนาฬิกาเข้าไปใน timer callback และ **ใช้ stage ที่ server ส่งมาเป็นค่าเริ่มต้น** ⇒ ไม่มี frame ว่างตอน mount

**verify ถึงไหน**
- ✅ `tsc --noEmit` ไม่มี error ในไฟล์ใหม่ (มี error ค้างอยู่ก่อน 3 จุดใน 2 ไฟล์ test ของ develop — ไม่ใช่ของงานนี้)
- ✅ `eslint` สะอาดทุกไฟล์ใหม่
- ✅ `vitest` 49 เคสผ่าน (stage 34 · api 5 · flag 10) รวมเคส polar 2 ฤดู, EC-01, boundary sync กับ `TWILIGHT_HALF_WIDTH_MINUTES`
- ✅ **`next build` (production) ผ่าน** พร้อม `NEXT_PUBLIC_ENVIRONMENT=true` — VO ต้อง verify ด้วย prod build เสมอ ไม่เชื่อ `next dev`
- ❌ ยังไม่มีอะไรแสดงบนจอ (C2 คือ Pixi layer) และยังไม่ได้ต่อ hook เข้า `hero-virtual-office.tsx`
- ❌ ยังไม่ได้ทดสอบ e2e จริง (ต้องมี API key + `ENVIRONMENT_ENABLED=true` บน dev)

**หมายเหตุ worktree** — Turbopack ไม่ยอม `node_modules` ที่เป็น symlink ออกนอก filesystem root ⇒ ต้องใช้ `cp -al` (hardlink copy) ถ้าจะ `next build` ใน worktree

**ต่อจากนี้** — **C2** (Pixi time-of-day layer + fade 30 วินาที + polar branch) ทำได้ทันทีไม่ต้องรอ credential เพราะ stage คำนวณเองทั้งหมด

**ติดอะไร** — ไม่มีใหม่ · ที่ค้าง: credential 2 ชุด + `ENVIRONMENT_ENABLED=true` + มติ severity 2 ข้อ (2/22, 3/23) + asset ขนาด 1× ของ `shooting-star` / `bg` / `leaf2` (ข้อ 48)

## รอบที่ 7 — 2026-09-09 · B1 (ws relay) · **ยืนยันผ่าน Redis จริงแล้ว**

**ทำอะไร** — `zyra-ws` commit `faab342` บน `feat/sc-env-01-ws-relay` (แตกจาก `origin/develop` @ 21bc205)

1. **ตรวจก่อนแก้ตามที่ task-breakdown กำกับไว้** — `BroadcastZoneEvent` (`internal/hub/zoneclaims.go`) **มี allowlist + `default` ที่ drop type ไม่รู้จักพร้อม warn** ⇒ ถ้าไม่เพิ่ม case ข้อความทั้งสองจะถูกทิ้งเงียบ ๆ (มีแต่ log) และแมพจะอัปเดตแค่ตอน client refetch = ผิดสัญญา 5 วินาทีของ HP-01/EC-03
2. เพิ่ม `MsgEnvironmentChanged` / `MsgWeatherAlert` ใน `message.go` + case ใน relay
3. **forward verbatim ไม่ mirror อะไรเลยบน ws** — ต่างจาก pet events ที่อยู่ข้าง ๆ ซึ่งอัปเดต AI mirror ด้วย · เพราะ stage คำนวณที่ client จาก `server_time` + `sun` ใน payload และ banner (รวม `dismissible`) เป็น client display state
4. อัปเดตคอมเมนต์ที่ระบุรายการ type ทั้งใน `main.go` และ `ZoneEventPush` ให้ครบตามจริง

**verify ถึงไหน**
- ✅ `go build` / `go vet` / `go test ./...` ผ่านทุก package (authz, handler, hub, store)
- ✅ unit test ใหม่ 3 เคส: relay verbatim ทั้งสอง type · payload ว่างก็ยัง relay · workspace อื่นไม่รั่วเข้าห้องนี้
- ✅ **ยืนยันกับ Redis จริง (ไม่ใช่แค่ unit test)** — รัน ws จาก worktree ต่อ Redis local แล้ว `PUBLISH vo:zone` 3 ข้อความ (`environment_changed`, `weather_alert`, `bogus_type_control`) → log มี warn `unknown zone event type — dropped` **เพียง 1 ครั้ง และเป็น `bogus_type_control` เท่านั้น** ⇒ 2 type ใหม่ผ่าน allowlist จริง และกลไก drop ยังทำงาน
- ❌ ยังไม่ได้ทดสอบ end-to-end ถึง client จริง (ต้องมี client เชื่อม ws + zyra-api publish ของจริง = รอ C1)

**ถึงไหน** — **Track A + B ครบ** (zyra-api 6 commit, zyra-ws 1 commit) · ฝั่ง server พร้อมส่งข้อมูลให้หน้าบ้านแล้ว

**ต่อจากนี้** — **C1** (flag `NEXT_PUBLIC_ENVIRONMENT` + api client + hook) → C2 (Pixi lighting layer, ใช้งานได้จริงเลยเพราะ time-of-day ไม่ต้องรอ key)

**ติดอะไร** — ไม่มีอะไรใหม่ · ที่ค้างเหมือนเดิมคือ credential 2 ชุด + `ENVIRONMENT_ENABLED=true` + มติ severity 2 ข้อ (2/22, 3/23)

## รอบที่ 6 — 2026-09-09 · A6 (realtime broadcast + bell notification) · **Track A ครบ**

**ทำอะไร** — commit `4e807b4` + **migration 100 (รันบน dev แล้ว)**

1. **reuse `vo:zone` channel เดิม** ไม่สร้าง channel ใหม่ — `ZoneEventPublisher.PublishZoneEvent(workspaceID, type, payload)` เป็น generic อยู่แล้ว ⇒ เพิ่มแค่ 2 type: `environment_changed`, `weather_alert` (ws subscribe ช่องนี้อยู่แล้ว)
2. **หัวใจของ A6 คือ "ไม่ส่ง" ไม่ใช่ "ส่ง"** — snapshot ถูกสร้างใหม่ทุก read และอุณหภูมิขยับตลอด ⇒ ถ้า publish ทุกครั้งจะ push ให้ทุก member หลายครั้งต่อนาที และ restage แมพเพราะ 0.1° ที่มองไม่เห็น
   - เก็บ **signature** ใน Redis (`env:sig:<workspaceID>`) จาก **เฉพาะฟิลด์ที่เปลี่ยนภาพ**: condition, stage, toggles, place, coverage, stale, alert ids
   - **อุณหภูมิ/ความชื้น/ลม ไม่อยู่ใน signature** โดยเจตนา (มี test ยืนยัน)
3. **asymmetry 2 จุดที่ตั้งใจ**
   - บันทึก settings → **publish ทันทีไม่เช็ค signature** เพราะ HP-01/EC-03 สัญญา 5 วินาที และต้องไม่ขึ้นกับว่าอากาศเปลี่ยนด้วยไหม
   - Redis ล่ม → **เงียบ ไม่ใช่ flood** (ไม่มี signature store = แยกใหม่/เดิมไม่ออก · restage ที่หายไปแก้เองตอน client fetch รอบหน้า แต่ flood แก้ไม่ได้)
4. **fan-out alert ตาม scope ของ alert เอง** — country-wide (TMD/GDACS) → ทุก workspace ในประเทศ · per-point (Google) → เฉพาะ workspace ใน cell นั้น · **คัด workspace ที่ปิด location/alerts ออกตอน resolve audience** ไม่ใช่กรองทีหลัง ⇒ workspace ที่ opt-out ไม่ถูกแจ้งเลย
5. **migration 100** — type `weather_alert` + `weather_alert_id` + **unique index (weather_alert_id, user_id)** เป็น backstop ถ้า poll ส่งซ้ำ · `actor_id = NULL` เพราะไม่มีคนโพสต์
6. publisher/notifier ใช้ **setter** (Redis กับ notification service สร้างทีหลังใน main) — pattern เดียวกับ `roomPetService.SetPublisher`

**ถึงไหน** — **Track A (A1–A6) ครบทั้ง track** · 6 commit · migration 98/99/100 รันบน dev แล้ว

**verify ถึงไหน**
- ✅ `go vet` เงียบ · `go test ./...` ผ่านทุก package · test ใหม่ 16 เคส (signature 7 กรณี รวม "อุณหภูมิเปลี่ยนต้องไม่ส่ง", publish-once-then-quiet, Redis ล่มต้องเงียบ, settings publish ทุกครั้ง)
- ✅ migration 100 รันบน dev + ยืนยัน `weather_alert` อยู่ใน CHECK constraint แล้ว
- ❌ **ยังไม่ได้ทดสอบ end-to-end ผ่าน Redis จริง** (publish → ws → client) — ต้องทำใน B1
- ❌ ยังไม่ได้ทดสอบ fan-out กับ workspace จริง (ต้องมี workspace ที่ตั้ง location + flag เปิด)
- ❌ notification ยังไม่เคย insert จริง (ต้องมี alert จริงจาก poller)

**ต่อจากนี้** — **B1** (ws relay: เพิ่ม 2 case ใน subscriber ของ `vo:zone` ที่ `zyra-ws/internal/store/redis.go`) แล้วจึงเข้า C1–C7 ฝั่ง app

**ติดอะไร** — เหมือนเดิม: credential (`GOOGLE_MAPS_API_KEY`, `TMD_UID/UKEY`) + `ENVIRONMENT_ENABLED=true` + มติ severity 2 ข้อ (2/22 กับ 3/23)

## รอบที่ 5 — 2026-09-09 · A5 (Google alerts + routing per cell)

**ทำอะไร** — commit `2ff3abf` + **migration 99 (รันบน dev แล้ว)**

1. ดึง schema จริงก่อนเขียน — endpoint คือ **`publicAlerts:lookup` ไม่ใช่ `weatherAlerts:lookup`** · response: `weatherAlerts[]` ที่มี `alertId`, `alertTitle.text`, `eventType`, `areaName`, `polygon` (GeoJSON string), `severity`, `startTime`, `expirationTime`, `dataSource.authorityUri` · severity enum เป็น **ตัวพิมพ์ใหญ่**: `SEVERITY_UNKNOWN / EXTREME / SEVERE / MODERATE / MINOR` · ถ้าไม่มี alert จะคืนแค่ `regionCode`
2. **`environment_google_alerts.go`** — provider แบบ **per-point** (ต่างจาก TMD/GDACS ที่เป็น feed ใบเดียว)
   - severity mapping แบบอนุรักษ์นิยม: **EXTREME เท่านั้น = emergency** เพราะ banner แดงปิดไม่ได้ (EC-02) และ SEVERE เป็นระดับที่พบบ่อย · `SEVERITY_UNKNOWN` → watch ไม่ escalate (รอ PM ข้อ 2/22)
   - ประเทศที่ Google ไม่มี alert (เช่นอินเดีย) → **ไม่ยิงเลย** GDACS ครอบให้แล้ว
   - publisher ที่ไม่ส่ง title → ใช้ชื่อประเภทภัยเป็นไทย
3. **migration 99** — `tb_weather_alert.cell_key` + index
   - **เหตุผล**: Google เป็น per-point ⇒ ถ้าเก็บต่อ country อย่างเดียว **ประกาศของกรุงเทพจะไปโผล่ที่เชียงใหม่** ซึ่งขัด HP-04 ที่ต้องกรองตามพื้นที่ ⇒ Google ผูกกับ cell · TMD/GDACS `cell_key = NULL` (ทั้งประเทศ) · snapshot อ่านทั้งสอง scope
4. **`PollPointAlerts`** — หา cell ที่ active จาก DB (workspace ที่เปิด location+alerts และประเทศที่ Google ครอบ) group ตาม grid 0.25° เดียวกับ weather ⇒ 1 metro = 1 call · per-cell interval 15 นาทีเก็บใน Redis ⇒ tick 5 นาทีของ loop ไม่ทำให้ยิงซ้ำ · ใช้ soft cap เดียวกัน
5. **ไม่ต้องทำ point-in-polygon** — task-breakdown เดาว่าต้องทำ แต่ per-point query ตอบมาให้ตรงพิกัดแล้ว ⇒ เก็บ polygon ไว้แค่แสดงผล (ประหยัดงานไปทั้งก้อน)

**verify ถึงไหน**
- ✅ `go vet` เงียบ · `go test ./...` ผ่านทุก package · test ใหม่ ~20 เคส (severity 8 ค่า, per-cell dedup key, empty response, fallback title, coverage skip, poll guards 3 เคส)
- ✅ **migration 99 รันบน dev จริงแล้ว** — ยืนยัน `cell_key` + `idx_weather_alert_cell`
- ❌ ยังไม่ได้ยิง Google publicAlerts จริง (ไม่มี key) — mock ด้วย httptest ตาม schema ที่ดึงจาก reference
- ❌ ยังไม่ได้ทดสอบ `activeAlertCells` กับข้อมูลจริง (ต้องมี workspace ที่ตั้ง location + flag เปิด)

**ต่อจากนี้** — A6 (publish `vo:zone` + bell notification จาก alert ที่ `xmax=0` บอกว่าใหม่) → B1 (ws relay) → ฝั่ง app C1–C7

**ติดอะไร**
- severity mapping ของ Google (ข้อ 2/22) และตาราง keyword ของ TMD (ข้อ 3/23) **ยังรอ PM ทั้งคู่** — ทั้งสองกระทบกฎ "แดงปิดไม่ได้"
- ต้องมี `GOOGLE_MAPS_API_KEY` + `TMD_UID/UKEY` + `ENVIRONMENT_ENABLED=true` จึง verify ได้ทั้งเส้น
- ยังไม่รู้ว่าโควตาฟรีนับ `publicAlerts` แยกจาก `currentConditions` หรือรวมกัน (ข้อ 5 ใน spec §D.3) — กระทบงบที่เสนอ MD

## รอบที่ 4 — 2026-09-09 · A4 (TMD + GDACS poller + alert ledger)

**ทำอะไร** — commit `5a19580`

1. **`environment_tmd.go`** — ดึง WeatherWarningNews v2 (XML) → normalize
   - **กับดักที่เจอจากการยิงจริงและกันไว้ในโค้ด**: ทุก field ชื่อ `*English` มา **2 ชุด และชุดแรกเป็นภาษาไทย** ⇒ ประกาศเป็น `[]string` แล้วเลือกค่าที่ไม่มีอักษรไทย (ถ้า TMD แก้ bug เหลือชุดเดียวก็ยังทำงาน)
   - severity ไม่มีในฟีด → derive จาก keyword (config-driven) · **default = warning ไม่ใช่ emergency** เพราะ banner แดงปิดไม่ได้ (EC-02) ⇒ over-claim อันตรายกว่า under-claim
   - dedup key = `IssueNo|เลขประกาศจาก title|AnnounceDate` (TMD ไม่มี alert id)
   - เวลาอ่านเป็น ICT ไม่ใช่ zone ของ server (pod รัน UTC จะเพี้ยน 7 ชม.)
   - `Country = "TH"` ตายตัว เพราะประกาศเป็น prose ระดับประเทศ/ภาค ไม่มี geometry (ข้อ 4 ยังค้าง)
2. **`environment_gdacs.go`** — ตาข่ายทั่วโลก ฟรี ไม่ต้องมี key
   - **ยืนยันกับ API จริง 2 อย่าง**: (ก) event list คืน **event เก่า** (ทุก event ของไทยเป็นของ 2025) (ข) `iscurrent` เป็น **string "false"** ไม่ใช่ boolean ⇒ กรอง 2 ชั้น (flag + todate + grace 24 ชม.)
   - `affectedcountries[].iso2` มีให้แล้ว ⇒ ไม่ต้องทำตาราง ISO3→ISO2 · 1 event หลายประเทศ → **เก็บ 1 แถวต่อประเทศ** (ตาราง alert คีย์ด้วย country เดียว ตาม query ของ snapshot)
   - Red→emergency · Orange→warning · Green ไม่รับ
3. **`environment_alerts.go`** — ledger + dedup + poll orchestration
   - dedup ด้วย `UNIQUE (source, source_alert_id)` จาก mig 98 · insert คืนว่า **แถวใหม่จริงไหม** ด้วย `xmax = 0` ⇒ A6 จะ broadcast ครั้งเดียวต่อประกาศ ไม่ใช่ทุกรอบ poll
   - `ActiveAlertsFor(country)` เรียง severity สูงสุดก่อน (EC-02) · `Dismissible` derive จาก severity **ไม่เก็บใน DB** (กันคอลัมน์ค้างทำกฎ safety พัง)
   - source ล้ม 1 ตัวไม่หยุดตัวอื่น · `PurgeExpiredAlerts` เก็บ 7 วันให้ bell panel
4. **poller loop ใน `main.go`** — **ไม่สตาร์ตเลยถ้า `ENVIRONMENT_ENABLED` ไม่ได้เปิด** · singleton ต่อคลัสเตอร์ด้วย Redis lock (`AcquirePollerLock`) · tick 5 นาที
   - EC-02 ขอ webhook แต่**ไม่มีเจ้าไหนให้** (ยืนยันแล้วทั้ง TMD/GDACS/Google/OWM) ⇒ ทำได้ดีสุดคือ poll 5 นาทีตาม technical note ของ EC-02 เอง
5. snapshot อ่าน alerts จาก ledger **ไม่ยิง provider ตอน member เปิดแมพ**
6. config: `TMD_UID` / `TMD_UKEY`

**verify ถึงไหน**
- ✅ `go vet` เงียบ · `go test ./...` ผ่านทุก package · test ใหม่ ~45 เคส (TMD parse จาก fixture ที่จำลอง defect จริง + severity 9 วลี + GDACS filter 6 เคส + multi-country + poll orchestration 4 เคส + sort severity)
- ✅ ยิง GDACS จริงเพื่อยืนยัน field/ค่า (`iscurrent`, `affectedcountries[].iso2`, alertlevel) ก่อนเขียน parser
- ❌ **ยังไม่ได้ยิง TMD ด้วย credential จริง** (ใช้ fixture; ของจริงต้องลงทะเบียนขอ uid/ukey)
- ❌ ยังไม่ได้ทดสอบ dedup กับ DB จริง (`xmax = 0` path) — ต้องรันบน dev
- ❌ ยังไม่ได้ทดสอบ poller lock กับ Redis จริง

**ต่อจากนี้** — A5 (Google alerts + coverage routing เข้า snapshot) หรือ A6 (publish `vo:zone` + bell notification) · ฝั่ง app C1/C2 ยังทำขนานได้

**ติดอะไร**
- **ตาราง keyword → severity ยังเป็นค่าที่ผมตั้งเอง** (ข้อ 3/23) — ต้องให้ PM อนุมัติก่อนเปิดใช้จริง เพราะกระทบกฎ "แดงปิดไม่ได้"
- ต้องมี `TMD_UID`/`TMD_UKEY` จริง + `ENVIRONMENT_ENABLED=true` จึงจะ verify ได้ทั้งเส้น
- alert ของ TMD ยังกรองตามจังหวัดไม่ได้ (ไม่มี geometry) — ทุก workspace ในไทยจะเห็นประกาศเดียวกัน (ข้อ 4 รอมติ)

## รอบที่ 3 — 2026-09-09 · feature flag + A3 (cache/quota ladder)

**ทำอะไร** — commit `3a0d15d`

1. **`ENVIRONMENT_ENABLED` (ผู้ใช้สั่งกลางรอบ)** — flag ฝั่ง API, runtime, **default off** เพราะทุก provider call เสียเงิน
   - ปิดแล้ว: `GET` ตอบ 200 + `feature_enabled:false` (client เงียบ ไม่ error) · `PUT` = 404 `FEATURE_DISABLED` · **ไม่ยิง provider จากทางไหนเลย** (weather, timezone, geocode)
   - test บังคับ 3 จุด รวมเคส "มี key แต่ flag ปิด → ต้องไม่เรียก resolver"
2. **`internal/cache/environment.go`** — cache ต่อ **grid cell 0.25° (~28 กม.)** ไม่ใช่ต่อ workspace + single-flight lock + ตัวนับโควตารายเดือน · nil-safe ทั้งไฟล์ตาม pattern `ZoneCache`
3. **`internal/service/environment_weather.go`** — ladder ตาม EP-01: hot cache → quota guard (95% ของ 10k) → single-flight → provider → snapshot ใน DB (≤3 ชม.) → clear+stale
   - **ไม่คืน error เลย** ทุกชั้น เพราะ AC ห้ามให้แผนที่พังตาม provider
   - ประเทศที่ไม่มี coverage: ไม่ยิง ไม่ lock ไม่นับโควตา
   - fetch เฉพาะเมื่อ owner เปิดทั้ง location และ weather toggle
4. GET คืน `weather` ได้แล้ว (ก่อนหน้านี้ nil ตลอด)

**verify ถึงไหน**
- ✅ `go vet` เงียบ · `go test ./...` ผ่านทุก package · test ใหม่: ladder 8 เคส + cache 4 กลุ่ม (cell key, negative zero, nil cache, monthly key)
- ✅ **test จับ panic จริง** — `saveCellSnapshot`/`loadCellSnapshot` ยังไม่ guard `db == nil` เจอตอนรัน ladder แล้วแก้
- ❌ ยังไม่ได้ยิง Google จริง (ไม่มี key) · ยังไม่ได้ทดสอบกับ Redis จริง (ไม่มี miniredis ในโปรเจกต์ — cache ทดสอบเฉพาะ logic + nil path)
- ❌ ยังไม่ live-test endpoint ด้วย token

**ต่อจากนี้** — A4 (TMD + GDACS poller · ⚠️ ต้องเช็ค flag ก่อนเข้า loop) หรือ C1/C2 ฝั่ง app

**ติดอะไร**
- ต้องได้ `GOOGLE_MAPS_API_KEY` + เปิด `ENVIRONMENT_ENABLED=true` บน dev ก่อนจะ verify ของจริงได้ทั้งเส้น
- **ยังไม่มีวิธีทดสอบ Redis ในโปรเจกต์** (ไม่มี miniredis) — ถ้าจะยืนยัน TTL/lock ของจริงต้องเพิ่ม dependency หรือทดสอบบน dev

## รอบที่ 2 — 2026-09-09 · A2 (provider layer + สูตรดวงอาทิตย์)

**ทำอะไร** — `feat/sc-env-01-api-settings` เพิ่ม 2 commit: `c75d808` (A1) · `8cddf99` (A2)

1. **`environment_sun.go`** — คำนวณ sunrise/sunset เอง (สูตร NOAA) + `StageAt` ที่ผูก stage กับดวงอาทิตย์จริง ไม่ใช่นาฬิกาคงที่
   - **pin ด้วย ground truth จาก provider จริง**: Bangkok / London (BST) / Sydney (ซีกโลกใต้) / Svalbard (78°N) — คลาด ≤1 นาทีในเขตอบอุ่น และ ~5 นาทีเหนือ 65° (เขียนเหตุผล + ข้อจำกัดไว้ในโค้ดตรง ๆ ว่าถ้าจะ**แสดงเวลา**พระอาทิตย์เป็นตัวเลขต้องใช้สูตรที่แม่นกว่า)
   - polar day/night รายงานผ่าน `DaylightSeconds` (0 / 86400) ไม่ใช่ timestamp เที่ยงคืน → กัน "รุ่งเช้าตอนเที่ยงคืน" ตลอดฤดู
2. **`environment_coverage.go`** — ตาราง coverage ต่อประเทศจากที่อ่าน Google มาทีละแถว (CN/CU/IR/KP ไม่มีทั้งคู่ · JP/KR/VN มี alert ไม่มี weather · IN/MY/ID/CA/RU มี weather ไม่มี alert)
   - **test จับ bug จริง**: ผมลืมใส่ JP/KR/VN ใน alert list ทั้งที่ยืนยันมาแล้วว่ามี — แก้แล้ว
3. **`environment_google.go`** — 3 endpoint (currentConditions / Time Zone / Geocoding reverse) + normalize
   - ดึงชื่อ field จาก reference ของ Google ทุกตัวก่อนเขียน parser (`temperature.degrees`, `wind.speed.value`, `visibility.distance` ฯลฯ) ไม่เดา
   - **Google ไม่มี condition type "fog" เลย** (enum 41 ค่า) → derive จาก `visibility < 1 km` (เกณฑ์ WMO) นี่คือเหตุผลที่ต้องอ่าน visibility
   - condition ที่ไม่รู้จัก → `cloudy` ไม่ใช่ `clear` (clear = ไม่มี effect เลย ผู้ใช้จะเห็นเป็นฟีเจอร์เสีย)
   - ประเทศที่ไม่มี coverage → **ไม่ยิง request เลย** (ไม่เปลืองโควตา ไม่ปั่น log) เพราะเป็นข้อจำกัดถาวร ไม่ใช่ error ชั่วคราว
4. **ต่อเข้า service เฉพาะ write path** — owner เปลี่ยนพิกัด → resolve timezone + ชื่อสถานที่ครั้งเดียว (ไม่ต้องมี cache, คุมโควตาได้) · GET ยังไม่ยิง weather **จนกว่า A3 จะมี cache/quota guard** เพราะถ้าต่อตอนนี้จะยิง provider ทุก request
5. snapshot เพิ่ม `stage`, `sun`, `utc_offset_seconds` (คำนวณใหม่ทุกครั้งจากชื่อ zone — ไม่เก็บ offset กัน DST เพี้ยน)
6. config: `GOOGLE_MAPS_API_KEY` (server-side เท่านั้น)

**ถึงไหน** — A2 เสร็จ · **หลัง A2 นี้ time-of-day ใช้งานได้จริงทั้งโลกแล้ว** (ไม่ต้องรอ weather) → C2 เริ่มได้

**verify ถึงไหน**
- ✅ `go vet` เงียบ · `go test ./...` ผ่านทุก package · test ใหม่ 60+ เคส (sun 4 เมือง + polar 2 ฤดู, stage 11 ช่วงเวลา, condition mapping 22 ค่า, coverage 7 ประเทศ, provider failure 3 โหมด, reverse geocode 2 เคส)
- ✅ ยิง Google API ผ่าน `httptest` mock ครบทุก endpoint
- ❌ **ยังไม่ได้ยิง Google API จริง** — ยังไม่มี `GOOGLE_MAPS_API_KEY` (รอ infra เปิด billing + สร้าง key ตาม [spec §D.3](spec.md#d3-สิ่งที่ต้องดำเนินการก่อนเริ่มโค้ด))
- ❌ ยังไม่ได้ยิง endpoint ของเราจริงด้วย token

**ต่อจากนี้** — A3 (cache 2 ชั้น + single-flight + quota guard) แล้ว GET จึงจะคืน weather ได้ · หรือ C1/C2 ฝั่ง app ขนานไปเลย

**ติดอะไร**
- **ต้องมี API key ก่อนจะ verify ของจริงได้** — ตอนนี้ provider ปิดตัวเองเมื่อไม่มี key (API ยัง boot ได้ ไม่มี weather)
- `windyGustKphMin = 30` เป็นค่าชั่วคราวที่ผมตั้งเอง — รอ PM ตอบข้อ 11
- เกณฑ์ fog `< 1 km` ใช้มาตรฐาน WMO ไปก่อน · haze จาก PM2.5 (ข้อ 18) ยังไม่ทำ เพราะ Google ไม่มีค่าฝุ่น

## รอบที่ 1 — 2026-09-09 · asset 1× + A1 (settings API)

**ทำอะไร**

1. **ย่อ asset เป็น 1×** — ไฟล์ที่ได้จาก designer เป็น pixel art ที่ upscale ไว้ (ตัวคูณต่างกันต่อไฟล์ 2×–10×)
   - หา factor ด้วยการทดสอบ **ย่อแล้วขยายกลับต้องได้พิกเซลเดิมเป๊ะ** ไม่ใช่เดาจากสายตา
   - บันทึก GIF ด้วย palette ร่วมทุกเฟรม (หรือ palette ต่อเฟรมเมื่อสีเกิน 255) แล้ว **ตรวจซ้ำทั้ง timeline** (ลำดับภาพ + duration ต่อช่วง + เวลารวม) — ผ่านทุกไฟล์
   - ผลลัพธ์: `storage/env-weather/1x/` · **4.41 MB → 909 KB (−79.9%)**
2. **A1 — settings API** บน worktree `feat/sc-env-01-api-settings` (แตกจาก `origin/develop` @ 4233fbd)
   - `migrations/98_environment.sql` + `.down.sql` — 9 คอลัมน์ `env_*` บน `tb_workspace` (รวม master switch `env_location_enabled` ของ HP-06) + `tb_environment_snapshot` + `tb_weather_alert` (UNIQUE source+source_alert_id สำหรับ dedup ของ HP-04)
   - `internal/model/environment.go` — condition 9 ค่า, coverage 3 ค่า, severity 3 ระดับ, snapshot/settings/update-request
   - `internal/service/environment_service.go` — `GetSnapshot` / `UpdateSettings` (partial update ด้วย pointer), validate lat/lng, **ปิด location ไม่ล้างพิกัด** (AC HP-06), เปลี่ยนพิกัด → ล้าง label/timezone/country กัน label ค้างจากที่เก่า
   - `internal/handler/environment_handler.go` — `GET` = member (`VerifyUserIsMember`), `PUT` = owner (`VerifyUserOwnsWorkspace`) · 403 ทั้งกรณีไม่ใช่สมาชิกและ workspace ไม่มีจริง (ไม่ยืนยัน id ให้คนนอก)
   - route ใต้ `userWS` + wiring ใน `main.go`
   - test: handler 14 เคส (guard/สถานะ/body พัง) + service 10 เคส (`validLatLng`, `snapshotFrom` รวมเคส "ปิดแต่เก็บพิกัด")

**ถึงไหน** — A1 เสร็จตาม DoD ที่เขียนไว้ใน [task-breakdown](task-breakdown.md#a1--featapi-add-workspace-environment-settings)

**PR** — ยังไม่ commit/push (รอสั่ง) · โค้ดอยู่ใน worktree `scratchpad/wt-env-api` ไม่แตะ WIP ของ `fix/pet-heartbeat-query-fanout` ที่ค้างอยู่ใน working tree หลัก

**verify ถึงไหน**
- ✅ `go build ./...` ผ่าน · `go vet ./...` เงียบ · `go test ./...` ผ่านทุก package
- ✅ **migration รันบน dev จริงแล้ว** (`zyra-db` @ 35.247.177.198:3500) ยืนยันครบ 9 คอลัมน์ + 2 ตาราง + index
- ❌ **ยังไม่ได้ยิง endpoint จริงด้วย token** (ยังไม่ได้ live-test) — ต้องทำตอนมี client หรือด้วย curl + token ของ dev
- ❌ asset 1× ยังไม่ได้เอาขึ้น R2 และ **designer ยังไม่ตรวจ**

**ต่อจากนี้** — A2 (Google adapters + `sun.go` + Time Zone API) หรือ C1 (flag + api client ฝั่ง app) ทำขนานได้

**ติดอะไร**
- `shooting-star.gif` ย่อแบบไม่เสียพิกเซลไม่ได้ (มี anti-alias/ไล่สี) → **ยังหนัก 153 MB ตอน decode** ต้องขอต้นฉบับ หรือขออนุญาตย่อแบบยอมเสียรายละเอียด
- `bg/zyra-backdrop.png` (2560×1440 = 14 MB) และ `wind/leaf*.gif` (8–12 MB) ก็ย่อ lossless ไม่ได้ — รวมแล้วยังเกินงบ 24 MB ที่ตั้งไว้ใน [technical-design §14.2](technical-design.md#142-งบหน่วยความจำ--บังคับ) ถ้าโหลดพร้อมกัน
- คำถาม PM ที่ยังบล็อกงานอื่น: ข้อ 3/23 (ตารางคำ→severity ของ TMD) กระทบ A4 · ข้อ 40 (owner ปิด alert ระดับแดงได้ไหม) กระทบ C5 · ข้อ 41/42 (ไม่มี location picker + member มี My location) กระทบ C6 และอาจกระทบ Location Policy ทั้งข้อ
