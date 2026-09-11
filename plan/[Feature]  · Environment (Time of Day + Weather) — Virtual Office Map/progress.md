# SC-ENV-01 · Progress

> entry ใหม่อยู่**บนสุด** · แยก "build เขียว" ออกจาก "live-test ผ่าน" ให้ชัดทุกครั้ง

## สถานะล่าสุด — 2026-09-11 (รอบที่ 19)

**เสร็จ 13 / 17 PR** · ฝั่ง server ครบ (Track A + B) · ฝั่งหน้าบ้าน **6 ใน 7** (C1 + C2 + C3 + C4 + C6 + C7) — เหลือ **C5** (แจ้งเตือนสภาพอากาศรุนแรง) อย่างเดียว
**ทุกอย่างอยู่บน `develop` และขึ้น dev แล้ว** (ล่าสุด app `3b9d304` — debug panel สภาพอากาศ/นาฬิกา · กฎกล้องใหม่ · ดวงจมน้ำ · badge ลากได้ — และ api `f8dd85d`) — ไม่มี PR ค้างของ SC-ENV-01
**asset:** ครบทุกสภาพอากาศบน R2 แล้ว (เพิ่ม moon ×5 · star ×6 · snow ×4 · wind ×5 · backdrop ตัวใหม่จากดีไซน์ 4056×2976 = 1352:992 พอดี ไม่ crop + ตัวฤดูหนาว `zyra-backdrop-winter-4056.png`) — ยังค้างเฉพาะ **1× ต้นฉบับของ wind/snow/star** จากดีไซน์
**preview ให้ทีมตรวจ:** [artifact](https://claude.ai/code/artifact/17865a33-4c40-445d-b84c-4e52a20c1ac6) — ตอนนี้ **โค้ดวาดเหมือนหน้านี้แล้ว** (ดูรอบที่ 14)

| Repo | Branch | Commit | PR (draft, base `develop`) |
|---|---|---|---|
| zyra-api | `feat/sc-env-01-api-settings` | **8** (A1–A6 + `precip_pct` + prefs) | [zyra-api#108](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/108) |
| zyra-ws | `feat/sc-env-01-ws-relay` | **1** (B1) | [zyra-ws#64](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/64) |
| zyra-app | `feat/sc-env-01-app-client` | **6** (C1, C2, C4, C6, เสียง, C7) | [zyra-app#336](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/336) |

**ทั้ง 3 PR เป็น draft และยังไม่ merge**
⚠️ **ห้ามใช้ `gh pr merge --auto` บน zyra-app** — merge ทันทีไม่เข้าคิว (ดู [[gh-auto-merge-not-queued]])

**Migration:** 98 / 99 / 100 **รันบน dev แล้ว** · **ยังไม่รันบน uat/prod** · C7 **ไม่ต้องมี migration** (ใช้ JSONB blob เดิม)

**credential (2026-09-10):**
- ✅ **Google** — เปิด 3 API (`weather` / `timezone-backend` / `geocoding-backend`) บน project `gather-dev-458614` แล้ว · สร้าง key **"zyra-api SC-ENV-01 (dev)"** จำกัดเฉพาะ 3 API นั้น · ใส่ `GOOGLE_MAPS_API_KEY` + `ENVIRONMENT_ENABLED=true` ลง secret `zyra-api-dev-env-json` **version 5** และ ESO sync เข้า k8s secret `dev/zyra-api-secrets` แล้ว
- ✅ **key ใช้ได้จริง ยิงครบทั้ง 3 API แล้ว** (2026-09-10) — Weather คืน `CLOUDY / 29.7°C / humidity 73 / precip 21% / wind 10 kph` · Time Zone คืน `Asia/Bangkok` offset `25200` · Geocoding reverse คืนถึงระดับ **แขวง/เขต** ("แขวงห้วยขวาง เขตห้วยขวาง") ⇒ **ปิดข้อ 44** ที่ค้างว่า provider จะให้ความละเอียดระดับเขตได้ไหม
- ✅ **`precip_pct` เห็นค่าจริงจาก Google แล้ว** (`precipitation.probability.percent = 21`) — เดิมมีแต่ mock ตาม doc
- ✅ **`ENVIRONMENT_ENABLED=true` + `GOOGLE_MAPS_API_KEY` เข้าถึง process บน dev แล้ว** (ยืนยันด้วย `kubectl exec ... env`) หลังแก้บักที่ทำให้ pod บูตไม่ขึ้น (ดูข้างล่าง)
- ✅ **ตั้ง `NEXT_PUBLIC_ENVIRONMENT=true`** เป็น Environment secret ของ `dev` แล้ว · ยืนยันว่า **uat / production ไม่มี** (ยังมืดตามเดิม) · `ARG`/`ENV` ใน Dockerfile + `--build-arg` ใน workflow มีอยู่บน branch แล้วตั้งแต่ C1
- ⛔ **แต่ยังทดสอบ environment บน dev ไม่ได้** — `develop` **ยังไม่มีโค้ด SC-ENV-01 เลย** (`grep ENVIRONMENT_ENABLED` ใน config บน develop = 0 · route `environment` ตอน boot = 0) ⇒ env พร้อมแล้วแต่ไม่มีใครอ่าน · **ต้อง merge api#108 + ws#64 + app#336 เข้า develop ก่อนถึงจะเห็นของจริง**
- ⏳ **TMD** — ต้องลงทะเบียนที่ `https://data.tmd.go.th` ในนามบริษัทเพื่อขอ `uid`/`ukey` (ข้อ 3 ในตารางท้าย spec) · ตอนนี้ทดสอบด้วย demo `uid=api&ukey=api12345` ซึ่ง **ห้ามใช้ prod**

**เริ่มทำต่อที่:** C3 (weather effects บน Pixi) ที่ยังติด asset 1× ของ 3 ไฟล์ (ข้อ 48) + เกณฑ์ลมแรง (ข้อ 11) · หรือ C5 (alert banner) ที่ยังติดมติ severity + ข้อ 40

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
- ❌ **ยังไม่เคยยิง TMD ด้วย credential จริง** — เป็น httptest mock ทั้งหมด · **Google ยิงจริงแล้ว 2026-09-10** ครบ 3 API (ดูหัวเอกสาร) แต่เป็นการยิงตรงด้วย `curl` **ไม่ใช่ผ่านโค้ดของเรา** เพราะโค้ดยังไม่ได้ deploy
- ❌ **ยังไม่เคยเห็นแสงหรือ widget จริงบนจอด้วยตา** — ต่อเข้า `hero-virtual-office.tsx` แล้วและ build เขียว แต่ยังไม่มี live run (ต้องมี key + `ENVIRONMENT_ENABLED=true`) · ยังไม่ได้วัด FPS ก่อน/หลังตาม DoD ของ C2
- ✅ **เห็นค่า `precip_pct` จาก Google จริงแล้ว** — `precipitation.probability.percent = 21` ตรงกับที่ mapping ไว้
- ❌ dedup กับ DB จริง (`xmax = 0`), poller lock กับ Redis จริง, insert notification จริง — ยังไม่ทดสอบ
- ❌ ยังไม่มี e2e ตั้งแต่ poller → ws → client

---

## รอบที่ 19 — 2026-09-11 · debug panel ทุกสภาพอากาศ + เร่งเวลา · กฎกล้องใหม่ · ดวงจมน้ำ · badge ลากได้

**ทำอะไร** — [zyra-app#359](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/359) merge เข้า `develop` เป็น `3b9d304` (squash จาก 21 commit ที่ค้าง local ระหว่างรอบทดสอบยาวบน :3100 กับผู้ใช้)

| เรื่อง | รายละเอียด |
|---|---|
| **debug panel (Cmd + /)** | section ENVIRONMENT: บังคับ 9 สภาพอากาศ · นาฬิกา 60×/600×/1800×/3600× + hold + slider เวลา · เลือกข้างจันทร์ 8 ข้าง/tonight · เครื่องนี้เท่านั้น เขียนทับ view หลัง snapshot มาถึง (`lib/environment-debug.ts` pure) · workspace ไม่มี location ได้ที่แทน "Bangkok (debug)" · stats overlay ย้ายไป Cmd + > |
| **เดือนดับ** | 11 ก.ย. 2026 เป็นเดือนดับจริง โค้ดเดิมไม่วาดดวงเลย ดูเหมือนพัง → วาด full disc ที่ 30% (`MOON_NEW_OPACITY`) halo หรี่ตาม · คืนที่ composition ไม่มีดวง (นอกจาก clear) ไม่วาด halo · opacity/flip เข้า key ของ layer ไม่งั้นสลับข้างจันทร์แล้ว sprite ไม่ rebuild |
| **ท้องฟ้า/ภาพ** | เมฆวาด 2× (`ENV_CLOUD_SCALE`) · แมพลงจากเส้นหญ้า 6% ของเฟรม (`BACKDROP_HORIZON_GAP`, เดิม 442 px) · wash กลางคืนต่อขึ้นเหนือกรอบดีไซน์ (เดิมเหลือฟ้ากลางวันแถบบนตอน zoom out) |
| **ดวงอาทิตย์/จันทร์ตก** | ปลาย arc (40.5%) ห่างเส้นตัด (38.9%) แค่ ~32 px บนแถบฟ้าจริง → ดวงจมได้ 1/3 แล้วหาย → ระหว่างเส้นตัด→ปลาย arc ดันลงเพิ่มเท่ารัศมี จมทั้งดวง · เส้นตัดย้ายจาก "เส้นหญ้า" (23.2%) ไป **ขอบบนของทะเล** (`ENV_BACKDROP_SKYLINE` 22.35%) — รูปยังแขวนด้วยเส้นหญ้า |
| **กฎกล้อง (เปลี่ยนใหญ่)** | เดิมจุดกลางกล้องไปได้ถึงขอบโลก → zoom out เห็นพื้นที่ว่างครึ่งจอทุกด้าน · ใหม่: **ขอบจอหยุดที่ pan bounds = สิ่งที่ zoom out สุดเห็น** (ออฟฟิศ+ฟ้า+ทะเล/หญ้าที่ล้นสองข้าง) เท่ากันทุก zoom → zoom in ลากออกไปถึงขอบเดียวกันได้ ไม่เลยไปกว่านั้น · ฉากเล็กกว่าจอ = จัดกลางจอ · `zoomTo`/resize re-clamp กล้องที่จอด (เดิมไม่ clamp กล้องค้างเลยขอบได้) · backdrop/ฟ้า ขยายเท่า reach นี้พอดี (`screenReachAtZoom`) ไม่มี canvas ดำ · **panel ด้านข้างเป็น overlay** ไม่ยุ่งกับกล้อง (กลไก inset ที่ลองใส่ระหว่างทางถอดออกแล้ว — ทะเลที่ล้น 472 px กว้างกว่า rail 56 px ดึงขอบแมพออกจากใต้ rail ได้ด้วยการลากปกติ) |
| **badge สภาพอากาศ** | `VODraggable`: ลากไปวางที่ไหนก็ได้ จำตำแหน่งต่อ browser (`zyra_weather_widget_pos`) ดับเบิลคลิกกลับมุม · กดเฉยๆ ยังเปิด (จับ pointer capture เฉพาะเมื่อเป็นการลาก — จับตั้งแต่กดทำให้ click ไม่ถึงปุ่ม) · panel ที่เปิดปักมุมขวาบนเสมอ · หลบแถบ meeting (`data-vo-avoid="weather"` เลื่อนลงใต้ +12 px) · ซ่อนตอน meeting ขยาย / chat full |

**verify ถึงไหน** · ทั้งชุด vitest ผ่าน (2243+ ตอนเปลี่ยนกล้อง; ไฟล์ใหม่ `environment-debug` 9 · `vo-draggable` 3 · scene 348) · CI เขียวครบ · **ดูจริงบน local prod build ต่อ dev (office ไม่มี location → ที่แทน)**: snow→พื้นหิมะ 264 sprite · clear→ดวงอาทิตย์+halo บนเส้นทะเล · thunderstorm 399 sprite ฟ้าผ่า on · นาฬิกา 3600× เดิน 14:45→17:15 ใน 2.5 นาทีจริง · เดือนดับ alpha 0.3/halo 0.078 → full 1.0/0.26 · ตะวันตก 18:15 ดวงจมหลังเส้นน้ำ (−139) · zoom 0.4 ภาพคลุมจอพอดี · zoom 1.2 ลากถึง pan bounds ครบ 4 ด้าน · เปิด Members ที่ zoom 0.4 กล้อง/ภาพ/ขนาด canvas ไม่เปลี่ยนเลย · badge ลาก/เปิด/ปิด/หลบแถบจำลอง ครบ · ⛔ ยังไม่ได้ลองใน meeting จริง (headless เข้าไม่ได้)

**กับดักที่เจอ** · แผงเปิดด้วย `Cmd + >` มาก่อน ไม่ใช่ `Cmd + /` (สลับแล้ว) · `zoomTo` ไม่ clamp กล้อง · pointer capture บน holder กิน click ของลูก · service worker บน :3100 ไม่ได้ cache — สาเหตุจริงของ "ยังไม่เปลี่ยน" ส่วนมากคือแท็บยังไม่รีโหลดหลัง restart

**ต่อจากนี้** · ลอง badge/meeting บน dev ใน browser จริง · ดีไซน์: ไฟล์ข้างจันทร์ที่ยังยืม full (gibbous ×2) และดวงจันทร์คืนมีเมฆ · วัด FPS ก่อน uat · C5 · TMD credential

## รอบที่ 18 — 2026-09-11 · ฉากอยู่แม้ปิด location · พื้นหิมะ · warm ฟ้าที่ /loading · ขอตำแหน่งตอนเข้า map

**ทำอะไร** — merge เข้า `develop` 4 PR (zyra-app) จากคำสั่ง 4 ข้อในวันเดียว:

| PR | เรื่อง | commit บน develop |
|---|---|---|
| [#355](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/355) | ปิด **Workspace location** แล้ว bg ยังต้องอยู่ | `139f31e` |
| [#356](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/356) | หิมะตก → พื้นหลังฤดูหนาว `Bg_wimter_zyra.png` | `3430081` |
| [#357](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/357) | โหลด bg/effect ตั้งแต่ /loading ไม่ให้เห็นรอยโหลดใน VO | `a07a95b` |
| [#358](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/358) | ขอสิทธิ์ตำแหน่งรวมกับไมค์/กล้องตอนเข้า map | `5b42168` |

| อาการ / งาน | สาเหตุ | แก้ |
|---|---|---|
| ปิด location แล้วฉาก (ทะเล หญ้า headroom) หายไปด้วย | `isEnvironmentSceneOn` บังคับ `location_enabled && location` (เหลือจากตอนแยกฉากออกจากสวิตช์ส่วนตัว รอบที่ 15) | ฉากตามแค่ `flagEnabled && feature_enabled` · ไม่มี location = ไม่มีดวง/อากาศ/แสง แต่ออฟฟิศยังยืนบนหญ้า · API ส่ง snapshot มาอยู่แล้วไม่ว่าสวิตช์เป็นอะไร |
| รูปฤดูหนาว | 4056×2976 ตัดเส้นเดียวกับรูปหญ้า (ทะเล 22.4% หิมะ 23.3%) | อัปโหลด R2 key ใหม่ `bg/zyra-backdrop-winter-4056.png` · `backdropFileFor(condition)`: `snow` → หิมะ อื่นๆ (รวมฝน) → หญ้า · engine สลับรูปเองเมื่อ URL เปลี่ยน · **ตัดสินใจ (ค้านได้)**: พื้นหิมะตาม weather ของ workspace ไม่ตามสวิตช์ส่วนตัว — เกล็ดคือ effect พื้นขาวคือฉาก |
| เข้า VO แล้วฟ้ามาช้ากว่าออฟฟิศ | /loading warm แค่รูปหญ้าผ่าน `loadTex` · GIF ถูก fetch+decode หลัง /play mount · snapshot ก็ fetch หลัง mount | /loading ยิง `GET …/environment` คู่กับ members แล้ว `setQueryData(["environment", id])` (key/shape เดียวกับ `useEnvironment`, `staleTime: Infinity`) · `collectEnvironmentAssetUrls(snapshot)` = backdrop ของอากาศนั้น + GIF ทุกตัวใน composition (dedupe) · `PreloadEntry.gif` → `Assets.load({parser:"gif"})` ประตูเดียวกับ scene |
| ขอสิทธิ์ตำแหน่งแยกทีหลังในแท็บ Environment | ขอเฉพาะตอน owner กดสวิตช์ | `useEntryMediaPermission` ขอ geolocation ต่อจากไมค์/กล้องตอน mount office (flag เปิดเท่านั้น, กติกาซ้ำถามเหมือนอุปกรณ์) · **ตัดสินใจ (ค้านได้)**: ใช้ตำแหน่งเฉพาะ **owner** และเฉพาะ workspace **ยังไม่มี place** → `PUT …/environment {location_enabled:true, lat, lng}` (save เดียวกับสวิตช์ในแท็บ) แล้ว seed cache · member ขอแล้วไม่ตั้งอะไร |

**verify ถึงไหน**
- vitest: `environment-layer` 9+1 · `environment-weather-fx` +1 · `vo-preload` 20 · `use-entry-media-permission` 5 เคสใหม่ (owner+ไม่มี place → save · member → ไม่ save · มี place แล้ว → ไม่ save · grant มาก่อน snapshot → save เมื่อ snapshot มา · ปฏิเสธ → เงียบ, `denied` ไม่ถามซ้ำ) · tsc/eslint/prettier สะอาด · CI เขียวครบทั้ง 4
- **#355 ดูจริง** (local prod build ต่อ dev, office ปิด location): payload `location_enabled:false, location:null` → backdrop วาด, ขอบฟ้า −442 / headroom 894 **เท่าตอนมี location** (กรอบกล้องไม่ขยับ), sprite 0, tint 0 — บน develop เดิม layer = null
- **#357 วัดจริง** (office ชี้ Bangkok ชั่วคราว, `performance` resource timing + path logger): /loading mount 22 371 ms · environment fetch ครั้งเดียว 22 669 · cloud1-3 + Sun + backdrop โหลด 25 181–25 292 · /play mount 26 678 → ไฟล์อากาศ **5/5 ก่อน /play, 0 หลัง /play**, ไม่มี environment fetch ซ้ำ — บน develop ทั้งหมดเกิดหลัง /play
- ⛔ **#356 ยังไม่เห็นจริง** — ไม่มี workspace บน dev ที่หิมะตกตอนนี้ (เส้นทางสลับรูป = `_ensureBackdrop` เดียวกับที่รูป 2x→4056 ผ่านมาแล้วใน #353)
- ⛔ **#358 ยังไม่เห็นจริง** — headless browser กด allow ตำแหน่งไม่ได้ · ต้องลอง browser จริง: เข้า workspace ที่เป็น owner และยังไม่ตั้งที่อยู่ → dialog ไมค์/กล้อง แล้ว dialog ตำแหน่ง → แท็บ Environment มี place + badge ขึ้น

**dev DB** · `office` ปิด env_location กลับแล้ว (ชี้ Bangkok ชั่วคราวเพื่อวัด #357)

**ต่อจากนี้** · ลอง #358 บน browser จริง · ดูพื้นหิมะ/ดวงอาทิตย์ตก/ดวงจันทร์/ฝน/ลมของจริง · ดวงจันทร์คืนมีเมฆ (ช่องว่างจาก preview รอดีไซน์ตัดสิน) · วัด FPS ก่อน uat · C5 · asset 1× wind/snow/star · TMD credential

## รอบที่ 17 — 2026-09-11 · เมฆขึ้นฟ้า · ดวงอาทิตย์วิ่งเต็มจอ · backdrop ตัวใหม่จากดีไซน์ · เสียงเบา

**ทำอะไร** — merge เข้า `develop` 2 PR (zyra-app): [#354](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/354) (`ac2caa5` เสียงเบาลง) และ [#353](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/353) (`8dabb9d` 5 commit รวมกัน) จากรายงาน 4 ข้อ: เมฆอยู่บนหญ้า · เมฆมีแค่กลุ่มกลาง ซ้าย-ขวาว่าง · เสียงดังไป · "เช็คขึ้น-ตกของดวงอาทิตย์ ไม่ให้อยู่แค่ตรงกลาง" + ได้รูปพื้นหลังใหม่มาแทน

| อาการ / งาน | สาเหตุ | แก้ |
|---|---|---|
| เมฆ ดาว ฟ้าผ่า อยู่บนหญ้าใต้ทะเล | สองไม้บรรทัด: ดวงอาทิตย์วางกับเฟรมออฟฟิศ แต่ sprite อื่นวางกับ tile 1:1 (`y% × 992` เหนือขอบแมพ) ซึ่งต่ำกว่าเส้นทะเลของ backdrop | ไม้บรรทัดเดียว: สัดส่วนท้องฟ้าของ design (0…เส้น clip 38.9%) กางลงบน**แถบท้องฟ้าจริง** จากเพดานกล้องถึงเส้นทะเล (`_horizonY` บันทึกตอนวางรูป) — เมฆ/ดาว/ดวง/halo/mask ใช้หมด ฝน-หิมะ-หมอก-ลมยังไล่ลง tile |
| เมฆมีแค่เหนือออฟฟิศ | tile ท้องฟ้าจาก x=0 กว้างเท่าแมพ | tile กว้างเท่า reach ของกล้อง (`vw/zoomMin` ทั้งสองข้าง) เท่าที่รูปทะเลไป · ของที่ตกคลุมแมพ +1 tile ข้างละด้าน |
| ดวงอาทิตย์ขึ้น-ตกใน 1/3 กลางจอตอน zoom out | arc = `bodyX% × worldW` | arc = `max(worldW, vw/zoomMin)` กึ่งกลางแมพ → zoom out สุดขึ้นขอบจอด้านหนึ่งตกอีกด้านเหมือน preview **ยังปักกับโลก ไม่ตามกล้อง** · เส้น clip 38.9% ตรงเส้นทะเล → ตอนตกจมน้ำ ไม่ค้างเหนือน้ำ |
| รูปใหม่ `Bg_zyra copy.png` | 4056×2976 = 1352:992 เป๊ะ | อัปโหลด R2 key ใหม่ `static/env/weather/bg/zyra-backdrop-4056.png` (ตัวเก่ายังอยู่) · วัดเส้นขอบฟ้าจากไฟล์: ทะเล 22.4% หญ้าเริ่ม 23.3% → `ENV_BACKDROP_HORIZON = 0.232` |
| **บั๊กใหม่ที่โผล่ตอนใส่รูปใหม่**: ทะเลหายไปเหนือเพดานกล้อง เมฆหายด้วย | รูปถูกขยายรอบ*จุดกลางเฟรม*เพื่อคลุม reach ของกล้อง (2.4× ที่ 1440×900) — ขอบฟ้าที่ 23% เลยถูกดันขึ้นไป y −2325 เหนือเพดาน −894 | แขวนรูปจาก**เส้นขอบฟ้าของ design** (`frameTop + 23.2% × frameH` = −442) แล้วขยายรอบเส้นนั้น · สีฟ้าต่อเหนือขอบรูปเหมือนเดิม · เส้นขอบฟ้านิ่งทุกขนาดจอ |
| เสียงสภาพอากาศดังไป | `ENV_BED_VOLUME` / `ENV_ONESHOT_VOLUME` เดิม | ลดเป็น `0.04` / `0.07` (#354) |

**verify ถึงไหน**
- vitest: `pixi-game-scene` 343 ผ่าน (ใหม่: `hangs clouds in the sky above the horizon` · `runs the sun's arc across the zoomed-out screen, not the office alone` · `sets the sun into the sea, not a hand's width above it` · `hangs the picture from the design's horizon`) · `environment-weather-fx` อัปเดตไฟล์/ขอบฟ้าใหม่ · build เขียว · CI เขียวครบทั้งสอง PR
- **ดูจริงบน local prod build ของ `296a6b7` ต่อ dev API** (`office` ชี้ Las Palmas ชั่วคราว, partly_cloudy, 08:05 หลังพระอาทิตย์ขึ้น 21 นาที) — อ่านค่าจาก scene ที่รันอยู่ + screenshot 1440×900 และ 1440×2400: รูป 4056×2976 ถูกวาด · เส้นขอบฟ้า **−442** (ในเพดานกล้อง เหนือออฟฟิศ) ทั้งสองจอ · เมฆ 6 ก้อน y −770 อยู่ระหว่างเพดาน −894 กับทะเล −442 เต็มความกว้างซ้าย-ขวา · ดวงอาทิตย์ศูนย์กลาง x **2891** y −457 = สูงกว่าทะเล 15 px เลยขอบขวาแมพ (2656) บน span −472…3128
- tint กลางคืน: Honolulu 20:31 เห็น `0x141e50` หลัง fade 30 วิ — ที่ Auckland "ไม่เห็น" รอบก่อนคือถ่ายระหว่าง fade
- ⛔ **ยังไม่เห็น*ดวง*บนจอจริง / ตอนตก / ดวงจันทร์** — avatar ทดสอบยืนปีกซ้าย สั่งเดินจาก headless browser ไม่ได้ (click/WASD ไม่ขยับ สาเหตุยังไม่รู้ ไม่เกี่ยว branch นี้) · ยังไม่เห็นฝน/หิมะ/ลมของจริงเช่นเดิม

**ช่องว่างของ composition (จาก preview เอง)** · `FX_NIGHT_LAYERS` มีให้ `clear` อย่างเดียว ⇒ คืนที่ `partly_cloudy`/อื่น ๆ **ไม่มีดวงจันทร์** — ต้องให้ดีไซน์ตัดสินว่าจะเพิ่มไหม

**กับดัก harness ที่เจอรอบนี้** · session ไม่เปิดในหน้าต่างไหน ⇒ Browser pane hidden ⇒ `requestAnimationFrame` ไม่ยิงเลย (Pixi ค้าง) และ timer ถูก throttle ⇒ ต้อง polyfill rAF ด้วย Worker `postMessage` **ก่อน** กด Join · zyra-ws local ที่รันอยู่ต้องมี `ALLOWED_ORIGINS` รวม `http://localhost:3100` ไม่งั้น socket ถูกปฏิเสธเงียบ ๆ

**dev DB** · `office` ปิด env_location กลับแล้ว (ชี้ Auckland/Honolulu/Las Palmas ชั่วคราวเพื่อทดสอบ) · `ฟหกฟหก` มีคนเปิดอยู่ ไม่ได้แตะ

**ต่อจากนี้** · ดูดวงอาทิตย์ตก/ดวงจันทร์/ฝน/หิมะ/ลมของจริงบน dev · วัด FPS ก่อน uat (DoD ของ C3) · C5 · asset 1× wind/snow/star · TMD credential

## รอบที่ 16 — 2026-09-11 · "ต้องกด badge ก่อนเมฆถึงขึ้น" — เจอต้นเหตุจริงแล้ว

**ทำอะไร** — [zyra-api#113](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/113) (`f8dd85d`) + [zyra-app#352](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/352) (`c2adf20`) merge เข้า `develop` ทั้งคู่

**ต้นเหตุ** — ภาพจากผู้ใช้คือหลักฐาน: badge มีแค่ชื่อเมือง+เวลา **ไม่มีอุณหภูมิ/ไอคอน** = snapshot ที่ถืออยู่มี `weather: null`
- `UpdateSettings` (owner บันทึก / เปิด location / สลับ toggle ของ workspace) สร้าง snapshot จากแถว DB **โดยไม่ดึง weather** แล้ว `PublishSnapshot` ให้ทุกคนทันที + reset signature เป็นสถานะไม่มี weather
- **server ไม่มี poll loop ที่อ่าน snapshot เลย** — ตัวเดียวที่เรียก `GetSnapshot` คือ HTTP handler ⇒ ทุกคนถือ snapshot เปล่าค้าง จนมี*ใครสักคน*กด badge → refetch → `GetSnapshot` ดึง weather, signature เปลี่ยน, publish ใหม่ให้ทุกคน
- ฝั่ง client `useEnvironment` เป็น push-driven (`staleTime: Infinity`, ไม่ refetch on focus) จึงไม่มีทางฟื้นเอง — สวิตช์ส่วนตัวที่รอบที่ 15 คิดว่าเป็นผู้ต้องสงสัยแค่ทำให้*สังเกตเห็น*

**แก้ 2 ชั้น**
| ชั้น | อะไร |
|---|---|
| API #113 | แยก `fillLive()` (weather + alerts) ออกจาก `GetSnapshot` ให้ `UpdateSettings` เรียกก่อน publish · กติกาเดิมครบ (feature/location/พิกัด/weather toggle ปิด = ไม่ยิง provider) · ราคาสูงสุด 1 provider call ต่อการบันทึก ปกติตอบจาก cell cache · เทสต์ table-driven 5 เคส |
| app #352 | ถ้า snapshot บอกว่าควรมี weather (feature+location+weather ของ workspace เปิด) แต่เป็น null → refetch เองทุก 5 วิ สูงสุด 6 ครั้ง หยุดทันทีที่ได้ · key ด้วย `dataUpdatedAt` ไม่ใช่ object (TanStack คืน object เดิมเมื่อคำตอบเหมือนเดิม — เทสต์จับได้เอง) · กันกรณี provider timeout ที่ API แก้ไม่ถึง |

**verify ถึงไหน** · Go `go test ./...` เขียว · vitest 2217 ผ่าน (`use-environment.test.tsx` 3 เคสใหม่) · build เขียว · CI เขียวครบทั้งสอง repo · ⛔ **ยังไม่ได้ยืนยันบน dev** — ต้องรอ api deploy แล้วลอง owner เปิด location ใหม่: สมาชิกต้องเห็น badge มีอุณหภูมิ + เมฆ**ทันที**โดยไม่กดอะไร

**ต่อจากนี้** · ยืนยันบน dev ตามข้างบน · ของเดิม: ฝน/หิมะ/ลม/ดวงอาทิตย์กลางวันของจริง · วัด FPS ก่อน uat · C5

## รอบที่ 15 — 2026-09-11 · สวิตช์ส่วนตัว 3 อาการ (ฉากกระโดด · เปิดแล้วไม่ทำงาน · เสียงไม่ปิด)

**ทำอะไร** — [zyra-app#351](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/351) merge เข้า `develop` แล้ว (`8c049ba`) จากรายงาน 3 ข้อในแท็บ Setting → Environment

| อาการ | สาเหตุ | แก้ |
|---|---|---|
| สลับ **Weather visual effects** แล้วขอบบนของจอเพิ่ม-ลดเอง · เปิดหน้ามาตอนสวิตช์ปิด = ไม่มีฉากเลย | backdrop + headroom ของกล้อง**ผูกกับ layer สภาพอากาศ** สวิตช์ส่วนตัวเลยเอาพื้นที่ออฟฟิศยืนอยู่ออกไปด้วย | แยกกฎเป็น `lib/environment-layer.ts` — **ฉากตาม environment ของ workspace** (พิกัด + feature) สวิตช์ส่วนตัวตัดสินแค่ว่าวาดอะไรในฉาก · แผ่นม่วงกลางคืนย้ายไปตาม Time of day · `setEnvironmentWeather(null)` เอา backdrop ลงด้วย |
| เปิดสวิตช์แล้ว "ไม่ทำงานจนกด badge สภาพอากาศ" | **reproduce ไม่ได้** ทั้ง build เก่า/ใหม่ · build เก่าตอนสวิตช์ปิดไม่ mount อะไรเลย พอเปิดต้องโหลด backdrop 2560×1440 + GIF จาก R2 ก่อน (หลายวิบน dev) — น่าจะเป็นช่วงที่กด badge พอดี | หายไปพร้อมข้อบน: ฉากขึ้นอยู่แล้วตลอด (และ preload จาก /loading) เปิดสวิตช์ = โหลดแค่ GIF |
| ปิด **Environment sounds** แล้วยังได้ยินฝน | player อ่านสวิตช์ตอน**เริ่ม** bed เท่านั้น (`volumeScale()` ใน `setEnvironmentBed`) ส่วน `useEnvironmentSound` ไม่ subscribe สวิตช์ | สวิตช์เป็น input ของ hook → ปิด = `setEnvironmentBed(null, 0)` ทันที + one-shot (ไก่ขัน/ฟ้าร้อง/ลมหิมะ) เงียบด้วย |

**verify ถึงไหน**
- vitest 2214 ผ่าน (ใหม่: `environment-layer.test.ts` 7 เคส · scene test ว่า backdrop ถูกทำลายพร้อม layer · hook test ที่ **fail บนโค้ดเดิม** `expected [null, 0], got ["rain", …]`) · build เขียว · CI เขียวครบทั้ง 5
- **ดูจริงบน local prod build ต่อ dev API** (office, cloudy): ปิดตั้งแต่โหลด → ฉากครบ ไม่มีเมฆ (develop เดิม: จอเปล่า) · เปิด → เมฆมาใน 7 วิ กรอบไม่ขยับ ไม่แตะ badge · ปิดอีก → เมฆหาย กรอบไม่ขยับ
- ⛔ เสียง: มีแต่เทสต์ — browser harness ไม่มีเสียง

**ตัดสินใจในรอบนี้ (ทีมค้านได้)** · ฉาก (backdrop/headroom) **ไม่ตาม** sticky `5732:212734` ("ปิดทั้งคู่ = ไม่วาด layer อะไรเลย") — ตีความว่า sticky พูดถึงแสงกับสภาพอากาศ ไม่ใช่พื้นที่ออฟฟิศตั้งอยู่ เพราะการให้สวิตช์ส่วนตัวย้ายขอบกล้องคือตัวอาการที่ถูกรายงาน

**คำตอบเรื่อง "ขนาด canvas จริง" ที่ถามมา** · ไม่มีเลขเดียว (ขึ้นกับขนาดแมพ · หน้าต่าง · zoom 0.4–2) แต่โค้ดวางรูปลง**กรอบสัดส่วน 1352:992** โดยแมพกินเต็มความกว้างและขอบบนแมพอยู่ที่ **45.9%** ของความสูง (455/992) → ทำรูปสัดส่วนนั้นที่ **4056×2976 (3×)** ให้เส้นขอบฟ้าอยู่เหนือ 45.9% แล้วโค้ดจะไม่ crop เลย มีแต่ย่อ-ขยาย · office ปัจจุบัน = 2656×1948 px

**ต่อจากนี้** · รอดูฝน/หิมะ/ลม/ดวงอาทิตย์กลางวันของจริงบน dev · วัด FPS ก่อนขึ้น uat · C5

## รอบที่ 14 — 2026-09-11 · C3 ขึ้น dev + ยกท้องฟ้าให้เท่า preview + ปิดบั๊ก Leave

**ทำอะไร** — merge เข้า `develop` 5 PR (ทั้งหมดเป็น zyra-app):

| PR | เรื่อง | commit บน develop |
|---|---|---|
| [#346](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/346) | backdrop เต็มขอบจอทุกมุมกล้อง + preload ตั้งแต่หน้า `/loading` | `e1c0413` |
| [#348](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/348) | **บั๊ก: กด Leave workspace แล้วแอปพังทั้งหน้า** | `2df7b9f` |
| [#347](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/347) | ท้องฟ้าเท่า preview ทั้งชุด (323 layer) | `2efdaa7` |
| [#349](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/349) | CI lint OOM + lint error 9 ตัวที่ซ่อนอยู่ใต้ OOM | `d3149da` |
| [#350](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/350) | สภาพอากาศครอบคลุมทั้งแมพ ไม่ใช่มุมเดียว | `2c1b06f` |

**C3 ต่างจากเดิมยังไง** — เดิมลอกพิกัดจากเฟรม Figma ตรง ๆ ได้ฝน 8 ช่องเรียงกัน เมฆ 6 ก้อนนิ่ง ๆ ไม่มีพระจันทร์ ไม่มีดาว ไม่มีการเคลื่อนไหว เพราะเฟรมเป็นภาพนิ่ง สิ่งที่ภาพนิ่งบอกไม่ได้ (ระยะลึก · การเคลื่อนที่ · สำเนาที่เหลื่อมจังหวะกัน) คือสิ่งที่แยก "สภาพอากาศ" ออกจาก "ลายซ้ำ" ตอนนี้ตาราง layer ของ preview ถูกพอร์ตมาทั้งชุดที่ `lib/environment-fx-composition.ts` (gen ด้วย `scripts/gen-environment-fx.py` จาก payload ของ [artifact](https://claude.ai/code/artifact/17865a33-4c40-445d-b84c-4e52a20c1ac6)) พร้อม:

- ฝน 56 เม็ด 3 ขนาด · เมฆมาก 19 ก้อน 3 ระยะ · ฝนปรอย = เม็ดละเอียดกว่าแต่มากกว่า
- ทุกชิ้นลอยขวา→ซ้าย คนละรอบ คนละความเร็ว GIF (`FX_SPEEDS`)
- กลางคืน: พระจันทร์ตาม phase จริงจากปฏิทิน (`lib/environment-sky.ts`, ไม่ยิง provider) + ดาว 14 ดวง · เดือนดับ = ไม่วาดพระจันทร์ · ใต้เส้นศูนย์สูตรกลับด้านเสี้ยว
- ดวงอาทิตย์เดินส่วนโค้งจากพระอาทิตย์ขึ้น→ตก **ของพิกัดนั้นจริง** ตัดที่เส้นขอบฟ้า + แสงประกายอยู่ใต้ sprite (เมฆบังได้)
- แสงไล่ต่อเนื่องจากนาฬิกาเดียวกับดวงอาทิตย์ — ค้างแต่ละช่วงแล้วข้ามในชั่วโมงสุดท้าย (`SKY_FADE_MINUTES`) แทนการกระโดดระหว่าง 5 ค่า
- `snow` / `windy` วาดแล้ว (เดิม return null)

**การวาง** — composition เป็น **tile ขนาดจริงของดีไซน์** (1 design px = 1 world px) ปูซ้ำทั่วแมพ: ฝน/หิมะ/หมอก/ลม ปูทุกแถวลงไปจนพ้นขอบล่าง · เมฆ/ดาว/ฟ้าผ่า แถวบนอย่างเดียว · ดวงอาทิตย์กับพระจันทร์ชิ้นเดียวบนส่วนโค้ง · แมพใหญ่ = thin pattern แทนการ mount sprite เป็นพัน (`ENV_FX_SPRITE_BUDGET = 400`)

**asset** — อัป R2 เพิ่ม 21 ไฟล์: `bg/zyra-backdrop-2x.png` (2560×1440 ตัวเต็ม แทนตัวย่อที่เบลอ) + moon ×5 + star ×6 + snow ×4 + wind ×5 · มีเทสต์ล็อกรายชื่อไฟล์ไว้ เพราะตัวโหลด sprite เป็น fire-and-forget → 404 จะเงียบ

**verify ถึงไหน**
- build เขียว · `npm run lint` 0 error · vitest 2205 ผ่าน (เพิ่ม `environment-sky.test.ts` + เขียน fx test ใหม่ + เทสต์ layout/drift/arc/ฟ้าผ่า/wash/halo/tiling)
- **ดูจริงบน local prod build**: backdrop คมเต็มขอบ · เมฆกระจายทั่วฟ้าและไม่ตกลงพื้นออฟฟิศ · wash ม่วงกลางคืน + แสง night
- **ดูจริงบน dev**: บั๊ก Leave หายแล้ว (`window.onerror` 0 error จากเดิมพังทุกครั้ง)
- ⛔ **ยังไม่ได้เห็นด้วยตา**: ฝน · หิมะ · ลม · ดวงอาทิตย์ตอนกลางวัน + แสงประกาย · พระจันทร์ — สภาพอากาศจริงของพิกัดทดสอบเป็น cloudy/drizzle ตลอดช่วงที่ทำ (ลองย้ายพิกัดไป Jakarta / Mumbai / Colombo / Singapore ก็ยังไม่เจอฝน) ทั้งหมดใช้โค้ดเส้นเดียวกับเมฆ มีแต่เทสต์คุม

**บั๊กที่เจอระหว่างทาง (ไม่ใช่ของ SC-ENV-01 ทั้งคู่ แต่ต้องแก้ก่อนถึงจะเดินต่อได้)**
1. **กด Leave workspace แล้วแอปพังทั้งหน้า ต้องรีโหลด** — `scene.destroy()` เรียก `gif.destroy(true)` ซึ่งทำลาย **GifSource** ด้วย แต่ `Assets` cache source ไว้ไฟล์ละตัวเดียวแล้วแจกให้ทุก sprite ที่ใช้ไฟล์นั้น → ตัวแรกฆ่า source ตัวที่เหลือยังอยู่บน shared ticker → `TypeError: Cannot read properties of null (reading 'findIndex') at GifSprite.update` โยนออกจาก ticker ซึ่งไม่มีใคร catch · แก้เป็น `destroy()` + มีเทสต์ที่ fail บนโค้ดเดิม
2. **CI `lint-and-build` ตายทุก PR ด้วย heap OOM** (`exit 134`) ไม่ว่าจะแก้อะไร → ใส่ `NODE_OPTIONS: --max-old-space-size=8192` · พอ lint รันจบก็เผย error จริง 9 ตัวจาก spotlight #329 ที่ซ่อนอยู่ใต้ OOM — แก้ด้วยการใส่ `useState` setter (identity คงที่) ลง dep array 7 callback ไม่แตะ logic

**ต่อจากนี้**
- ดูของจริงบน dev ตอนฝนตก/กลางวัน แล้วให้ทีมตัดสินว่าองค์ประกอบโอเคไหม
- C5 (การแจ้งเตือนสภาพอากาศรุนแรง) ยังไม่เริ่ม — รอ decision เรื่อง severity
- วัด FPS (DoD ข้อสุดท้ายของ C3) ยังไม่ได้ทำ — ตอนนี้ sprite ต่อฉากมากขึ้นมาก ควรวัดก่อนขึ้น uat

**ติดอะไร**
- asset 1× ต้นฉบับของ wind/snow/star ยังไม่ได้ — snow/wind ยังเป็นไฟล์ใหญ่ (decode 12.3 / 8.6 / 6.7 MB) ใช้ memory มากกว่าสภาพอากาศอื่น
- TMD `uid`/`ukey` ยังไม่ได้ (Google ไม่มีข้อมูลเตือนภัยของไทย — พิสูจน์ด้วยการยิงจริงแล้วในรอบที่ 13)
- dev DB: workspace `office` เปิด `env_location_enabled` ที่พิกัด Bangkok ไว้สำหรับทดสอบ

## รอบที่ 13 — 2026-09-10 · C7 (preference ส่วนตัว) + เปิด credential ของ Google บน dev

**ทำอะไร** — `zyra-app` commit `f673a95` (PR #336) · `zyra-api` commit `32cc571` (PR #108)

ดึง Figma `4839:34795` ก่อนเขียนตาม rule 10 แล้วพบเรื่องที่พลิกโครง: **HP-05 ไม่ใช่หน้าใหม่ แต่เป็น member variant ของ Setting → Environment tab เดียวกับ C6** (`4839:38016` "Environment setting - Member") ⇒ tab นี้เลิกเป็น owner-only แล้ว **สลับแถวตาม role แทนการซ่อนทั้ง tab** ซึ่งกลับมติของ C6 (ตอนนั้นถูกต้อง เพราะทุกแถวยังเป็น workspace-wide ที่ member โดน 403) — ค่าที่ถอดมาทั้งหมดอยู่ใน [ux-ui-plan §10](ux-ui-plan.md#10-personal-preference-c7--hp-05--ถอดจริง-2026-09-10)

1. **`env_time_of_day` / `env_weather_effects` ใน general-settings blob เดิม** — ไม่มี endpoint ใหม่ ไม่มี migration · default **ON** ทั้งคู่
2. **`PatchGeneralSettings` bind ทับ default แทน zero struct** — ของเดิม bind ลง struct เปล่า ⇒ เบราว์เซอร์ที่ยังถือ bundle เก่าจะไม่ส่ง key ใหม่มา แล้ว Go เขียนทับเป็น `false` เงียบ ๆ ตอน user ไปกดแถวอื่นใน General tab · ฝั่งอ่านเป็น merge-over-default อยู่แล้ว อันนี้แค่ทำให้ฝั่งเขียนตรงกัน
3. **preference ลบได้อย่างเดียว** — `shouldRenderStageTint` AND สวิตช์ส่วนตัวเข้าไปข้าง ๆ สวิตช์ของ owner ⇒ member ปิดเอฟเฟกต์ที่ออฟฟิศเปิดไว้ได้ แต่**เปิดเอฟเฟกต์ที่ owner ปิดไม่ได้** · แถวที่ workspace ปิดอยู่จึง **disable** ไม่ใช่ปล่อยให้กด (สวิตช์ที่กดแล้วไม่มีอะไรเกิดขึ้นแย่กว่าสวิตช์เทา) และ**ค่าที่เก็บไว้ไม่ถูกแตะ**
4. **ปิดแล้วไม่วาด layer เลย** ไม่ใช่ fallback เป็น Morning ตามที่ AC ของ HP-05 เขียน — morning = alpha 0 อยู่แล้ว บนจอจึงเท่ากัน และ "ไม่มี layer" คือสิ่งที่ทำให้ AC ข้อ FPS เป็นจริง (ข้อ 60)
5. **`shouldRenderWeatherEffects`** เพิ่มไว้ทั้งที่ยังไม่มีใครเรียกนอกจากเทสต์ — C3 ต้อง AND สวิตช์ส่วนตัวเข้าไปด้วย และวิธีลืมที่ง่ายที่สุดคือไม่มี gate ให้เรียก

**ไม่ได้ทำจาก design รอบนี้** — **"My location" + การ์ด "Your weather"** (ต้องมี location ราย user ที่ API ยังไม่มี + ติดมติ PII ข้อ 42/45) และ **ปุ่ม "ปิดทั้งหมด"** ที่ spec วาดไว้แต่ design ตัดออก (ข้อ 61/62)

**verify ถึงไหน**
- ✅ Go: `gofmt` / `go vet` / `go test ./...` เขียว · TS: eslint สะอาด · **`next build` production เขียวพร้อม flag เปิด** · **vitest 145 ไฟล์ / 1,953 test** (ใหม่ 17 เคส — gate 12 + member tab 5)
- ✅ ครบ DoD ระดับเทสต์: reload แล้ว preference คงอยู่ (มาจาก blob ที่ server merge over default — pin ด้วยเทสต์ Go 3 เคส) · เปิดใหม่กลับมาตามเวลา/อากาศปัจจุบัน · ครบทั้ง 4 คู่สถานะ
- ❌ **ยังไม่เคยกดจริงบนจอ** — ต้องรอ dev บูตได้ก่อน (ดูข้างล่าง)
- ❌ **สวิตช์ Weather visual effects ยังไม่มีผลอะไรให้เห็น** จนกว่า C3 จะมา — ค่าถูกเก็บและ gate พร้อมแล้ว แต่วันนี้ไม่มี layer ให้ปิด · **ถ้ามีคนเทสต์ก่อน C3 จะรายงานว่าเป็นบัก**

**credential ที่จัดการให้แล้ว (Google)**
- เปิด `weather.googleapis.com` / `timezone-backend.googleapis.com` / `geocoding-backend.googleapis.com` บน `gather-dev-458614` (billing เปิดอยู่แล้ว account `01B129-524F19-1584DC`)
- สร้าง API key **"zyra-api SC-ENV-01 (dev)"** (uid `56ab900d-b2ea-4441-9421-582631d2b9e0`) **จำกัดเฉพาะ 3 API นั้น** — ยังไม่ได้จำกัด IP เพราะ egress ของ k3s ยังไม่ได้ยืนยัน
- `zyra-api-dev-env-json` **version 5** = ของเดิม 39 key + `ENVIRONMENT_ENABLED=true` + `GOOGLE_MAPS_API_KEY` · force-sync ESO แล้ว ยืนยันว่า 2 key เข้า `dev/zyra-api-secrets` จริง

**บักที่เจอระหว่างทางและแก้แล้ว:** **dev zyra-api รีสตาร์ทไม่ขึ้นมาตั้งแต่ 2026-09-09 ~10:10 UTC** เพราะ migration ตอนบูต DROP-แล้ว-ADD `tb_notification_type_check` แล้วมีแถว `type='spotlight_live'` 25 แถว (จาก `zyra-app` branch `feat/spotlight`) ที่ไม่อยู่ในลิสต์ — ไม่เกี่ยวกับ SC-ENV-01 เจอเพราะ restart เพื่อฟีเจอร์นี้ · แก้ด้วย [api#110](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/110) merge เข้า `develop` แล้ว **ยืนยันบน dev แล้วว่า pod บูตผ่านและ constraint กลับมา** — ตาราง before/after: [ops/dev-api-unrestartable-notification-constraint-2026-09-10.md](../../ops/dev-api-unrestartable-notification-constraint-2026-09-10.md)

**ติดอะไร (เดิม)** — TMD credential · มติ severity 2 ข้อ + ข้อ 40 · asset 1× 3 ไฟล์สำหรับ C3 · ไฟล์ดวงจันทร์อีก 3 phase (ข้อ 58) + มติซีกโลกใต้ (ข้อ 59) · `NEXT_PUBLIC_ENVIRONMENT` ฝั่ง GitHub Environment

## รอบที่ 12 — 2026-09-10 · เสียงบรรยากาศ (นอกแผน 17 PR เดิม)

**ทำอะไร** — `zyra-app` commit `3a5deaf` (PR #336) · คู่มือเต็ม: [guides/environment-sounds.md](../../guides/environment-sounds.md)

ได้ไฟล์เสียงมา 19 ไฟล์ 6 โฟลเดอร์ · อัปขึ้น R2 **16 ไฟล์** ที่ `static/env/sound/{ambient,oneshot}/` แล้วต่อเข้าออฟฟิศ

1. **`lib/environment-sound.ts`** — layout + `environmentBedFor()` map (stage × condition × อุณหภูมิ) → bed · **สภาพอากาศชนะช่วงเวลา** · condition ที่ไม่มีเสียงของตัวเอง (fog/cloudy/clear) ตกไปใช้เสียงตามเวลา ไม่ใช่เงียบ · **ปิดตาม toggle ที่คุมภาพตัวเดียวกัน**
2. **`lib/environment-sound-player.ts`** — player แยกจาก pet เพราะ bed ต่างกัน 3 ข้อ (วนลูปไม่จำกัด · ต้องให้ฟ้าผ่าดังทับได้ · **ไม่มีคลิกให้เริ่ม**) ⇒ จำ bed ที่อยากเล่นแล้วเริ่มตอน gesture แรก · วนลูปด้วย source 2 ตัวสลับกันพร้อม gain ramp บนนาฬิกาของ audio engine ให้ crossfade คร่อมรอยตัด (ถ้า `loop = true` เฉย ๆ จะสะดุดทุก 90 วิ)
3. **`use-environment-sound.ts`** — bed ตาม snapshot เดียวกับที่ภาพใช้ + ไก่ขันตอน stage เปลี่ยนเข้า morning (ไม่ขันตอน mount) + ฟ้าผ่าทุก 10 วิระหว่างพายุ + ลมกระโชกทุก 26 วิระหว่างหิมะ

**ตัด bed ก่อนอัป** — ไฟล์ที่ได้ทั้งชุด encode 256–320 kbps และ `Rain.mp3` ยาว **10 นาที = 19.2 MB** ที่ทุกคนใน workspace ฝนตกต้องโหลดทั้งที่มันวนลูปอยู่แล้ว ⇒ ตัดเหลือ 90 วินาทีด้วยการ copy ทีละ MPEG frame (ไม่ re-encode เสียงที่เหลือตรงบิต ยืนยัน trailing bytes = 0) · **49.5 MB → 26.3 MB** ไฟล์ใหญ่สุด 19.2 → 3.4 MB

**verify ถึงไหน**
- ✅ eslint สะอาด · `next build` เขียว · **vitest 145 ไฟล์ / 1,936 test** (ใหม่ 15 เคส — mapping 9 + hook 6)
- ✅ ยิง public URL จริงได้ `HTTP 200 · audio/mpeg` · ตรวจว่าจุดตัดลงท้าย frame พอดีทุกไฟล์
- ❌ **ยังไม่เคยฟังจริงในเบราว์เซอร์** — ทั้ง crossfade ตรงรอยลูป, การเริ่มตอน gesture แรก และระดับเสียงเทียบกับ voice chat ยังไม่เคยทดสอบด้วยหู

**5 เรื่องที่ต้องตัดสิน (ข้อ 60–64 ในคู่มือ)** — ไม่มีสวิตช์ปิดเสียง (ที่อยู่คือ C7 แต่ดีไซน์ C7 ไม่มี toggle เสียง) · เกณฑ์ 30 °C ของเสียงจักจั่นผมตั้งเอง · จังหวะฟ้าผ่าเป็นของชั่วคราวรอ C3 มาสั่งจากแสง · โฟลเดอร์ `Running` ไม่ได้อัปเพราะ footstep สังเคราะห์เสียงอยู่แล้วโดยเจตนา · ไม่มี bed ของ fog/cloudy

**ต่อจากนี้** — C5 หรือ C7 · ถ้าจะ re-encode เสียงให้เล็กลงอีก ~60% ต้องมี ffmpeg ซึ่งเครื่องนี้ยังไม่มี

## รอบที่ 11 — 2026-09-10 · C6 (หน้าตั้งค่าของ owner) + asset ดวงจันทร์ + preview ให้ทีม

**ทำอะไร** — `zyra-app` commit `31b92f4` (PR #336)

ดึง Figma `4635:150663` + `4635:174601` ก่อนเขียน แล้วพบว่า **`ToggleRow` ที่มีอยู่ใน `vo-setting-modal.tsx` ตรงสเปค Figma อยู่แล้ว** (48×24 track / knob 20px / `#58D68D` / gap-24 / รองรับ disabled) เลย reuse ไม่สร้างใหม่ · `NavItem` ก็ตรง (`bg-[rgba(88,214,141,0.1)]` + `#58D68D`) · dialog ใช้ shell เดียวกับ `vo-leave-workspace-modal.tsx` ซึ่งเป็น "General modal" ตัวเดียวกันในดีไซน์

1. **`components/vo-environment-tab.tsx`** — tab ที่ 7 ของ Setting modal: การ์ดสภาพอากาศ + 4 toggle (Workspace location / Weather alert notification / Time of day lighting / Weather visual effects) + divider ตามตำแหน่งจริงใน Figma (คั่นหลังแถว 1 และ 2 ไม่คั่นระหว่าง 2 แถวท้าย)
2. **master switch ปิด → 3 toggle ล่าง disable** และค่า location ยังอยู่
3. **`isEnvironmentTabVisible()`** ใน `lib/environment-feature.ts` — กฎ 3 ชั้น (flag + owner + workspaceId) แยกออกมาให้ทดสอบได้โดยไม่ต้อง mount Setting modal ทั้งตัว · **ซ่อน tab จาก member ไม่ใช่ disable** เพราะทุก toggle เป็น workspace-wide ที่ server ปฏิเสธให้ member อยู่แล้ว
4. **reuse `WeatherCard` จาก C4** (export เพิ่ม) ไม่ก็อปเรขาคณิตมาใหม่ — ดีไซน์ใช้ component instance ตัวเดียวกันจริง
5. ใช้ **query key เดียวกับ hook บนแมพ** ⇒ owner กด toggle แล้วแมพหลัง modal เปลี่ยนทันทีโดยไม่ยิงซ้ำ

**2 การตัดสินใจข้างในที่ต้องรู้**
- **ขอตำแหน่งจากเบราว์เซอร์เฉพาะตอนที่ workspace ยังไม่มี location** · เปิด master กลับมาทีหลังแค่เปิด flag ไม่ถามใหม่ เพราะ HP-06 สัญญาว่าที่ตั้งไม่หายตอนปิด — ถ้าถามใหม่จะย้ายออฟฟิศไปที่ที่ owner ยืนอยู่วันนั้นเงียบ ๆ ซึ่งตรงข้ามกับสัญญานั้น
- **permission ถูกปฏิเสธ ≠ หาตำแหน่งไม่สำเร็จ** ⇒ ปฏิเสธ → เปิด dialog `4635:174601` (แก้ได้ที่ตั้งค่าเบราว์เซอร์เท่านั้น) · timeout → error inline ที่ลองซ้ำได้ · ถ้าใช้ข้อความเดียวกัน owner ครึ่งหนึ่งจะไปแก้ผิดที่

**ข้อ 9 / 33 / 34 ที่ค้างมานาน ตอบแล้วจาก design เอง** — ไม่มี picker/ปักหมุด/ช่องค้นเมืองเลย เป็น toggle ขอตำแหน่งจากเบราว์เซอร์ · toggle ทั้งของ owner และ member อยู่ใน Setting modal tab เดียวกัน สลับชุดตาม role · HP-07 คือ toggle เดิม ไม่ใช่ตัวใหม่

**verify ถึงไหน**
- ✅ eslint สะอาด · `next build` production เขียวพร้อม flag เปิด · **vitest ทั้ง repo 143 ไฟล์ / 1,921 test เขียว** (ของใหม่ 15 เคส — tab 10 + กฎ visibility 5)
- ✅ ครบ DoD: non-owner ไม่เห็น tab · master ปิดแล้ว 3 toggle disable · ปิดแล้วไม่ส่ง lat/lng · เปิดกลับไม่ถามเบราว์เซอร์ · ครั้งแรกถาม · ปฏิเสธ vs ล้มเหลวแยกข้อความ · save ทีละ field
- ❌ **ยังไม่เคยกดของจริงบนจอ** — ต้องมี Google key + `ENVIRONMENT_ENABLED=true` และต้องเป็น owner จริงบน dev
- ❌ **ยังไม่ได้ทดสอบ 2 browser** ตาม DoD ("บันทึกแล้ว member อื่นเห็นภายใน 5 วินาที") — ฝั่ง broadcast ทำไว้แล้วใน A6 แต่ยังไม่เคยรันคู่กันจริง

**asset ดวงจันทร์ (2026-09-10)** — ได้ sprite 5 phase ย่อ 10× แบบ lossless (494 KB → 27 KB · decode 51.2 MB → 0.51 MB) อัปขึ้น R2 `static/env/sky/` ยืนยัน `HTTP 200` ทั้ง 5 · เจอว่า **`moon.gif` เดิมคือ 5 phase นี้วนกันทุก 2.5 วินาที ใช้ต่อไม่ได้** · ขาด 3 phase จาก 8 (เดือนดับ + gibbous 2 ข้าง) · ซีกโลกใต้ต้องกลับด้าน sprite · สูตร phase จากวันที่อยู่ใน [technical-design §19](technical-design.md) ไม่ต้องยิง API

**ต่อจากนี้** — C5 (alert banner) ถ้าได้มติ severity หรือ C7 (personal prefs) ที่ต้องรอ C3

**ติดอะไร** — credential 2 ชุด · flag ฝั่ง server · มติ severity 2 ข้อ + ข้อ 40 · asset 1× 3 ไฟล์สำหรับ C3 · **ใหม่:** ไฟล์ดวงจันทร์อีก 3 phase (ข้อ 58) + มติซีกโลกใต้ (ข้อ 59) + overlay 3 ตัวจาก preview ที่ยังไม่มีใน tint table

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
