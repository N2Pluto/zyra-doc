# Roadmap (admin) — Progress / Handoff

> **สถานะรวม:** UI 2 หน้า + API ครบ (feature CRUD, scene, asset library, public read) ต่อกันแล้ว · **ตารางสร้างบน dev แล้ว** (DDL อยู่ใน `internal/database/postgres.go` จึงขึ้นเองตอน service start ทุก env) · ฝั่ง landing ยังไม่ต่อ
> **อัปเดตล่าสุด:** 2026-10-05 · **คนล่าสุด:** rif (pair กับ Claude Code)

## 2026-10-05 (รอบ 14) · rif — landing มือถือ: ไตรมาสเป็นข้อความ + summary กล่องเทา (ตาม Figma mobile)

- **อาการ:** รอบ 13 จอแคบยังใช้รูปป้าย/รูปกระดาษย่อเล็กใต้ฉาก แต่ Figma mobile ไม่ใช้รูปเลย
- **แก้ (zyra-landing, เฉพาะ ≤600px):** แถว `#spQuarterHead` เหนือฉาก ("2026, Q1" ตัวหนา 18px ซ้าย / "Jan - Apr" 16px muted ขวา — JS เติมทุกครั้งที่สลับฟีเจอร์) · ซ่อนรูปป้าย · กล่อง summary เป็นพื้น `#F4F4F5` r16 ข้อความ 14px `#3A3F49` ไม่แสดงรูปกระดาษ · stage เรียงเป็นคอลัมน์: แถวไตรมาส → ฉาก → summary · จอใหญ่ไม่เปลี่ยน · bump `spotlight.css?v=10` / `spotlight.min.js?v=12`
- **verify:** `npm run build` + เปิดหน้าจริงกับ mock ที่ 375px ได้ลำดับตาม Figma · 1440px แถวไตรมาสซ่อน รูปป้าย/กระดาษยังแสดงตามเดิม
- **ยังไม่ได้ทำ:** ลูกศร ˅ หลัง "2026, Q1" (Figma มีทั้ง desktop/mobile ยังไม่รู้ว่ากดได้หรือตกแต่ง) · ยังไม่ commit

## 2026-10-05 (รอบ 13) · rif — ป้ายไตรมาส/กล่อง summary ย้ายไปขอบ stage (ตาม Figma)

- **โจทย์:** ป้ายกับ summary มีทุกฟีเจอร์อยู่แล้ว แต่ต้องวางเองในกรอบ 16:9 เลยแย่งที่กับฉาก → ให้อยู่ขอบ stage ตาม Figma
- **decision (ตามข้อเสนอที่ผู้ใช้สั่งให้ทำ):** landing ข้ามวัตถุ sign/summary เดิม ไม่ลบข้อมูลใน DB · จอแคบเอาป้าย+summary ไว้ใต้ฉาก
- **zyra-api:** `RoadmapFeatureListResult.PresetAssets` (`preset_assets`, เฉพาะ public list) + `RoadmapService.PresetAssetURLs` · ถ้าโหลดไม่ได้แค่ log ไม่ทำให้ endpoint ล้ม
- **zyra-landing:** markup stage ใหม่ `#spSign` / `.sp-canvas-wrap > #spStage` / `#spSummary` (en/th) · `signNode()` / `summaryNode()` ใช้ `presetUrls` (ป้ายสำรองเป็นรูปใน repo, summary สำรองเป็นกล่องดำ) · `objectNode()` คืน null ให้ kind sign/summary · CSS: stage เป็น flex (ซ้าย 16% / กลาง canvas `min(100%, stage-h×16/9)` / ขวา 30%), ≤600px wrap ฉากขึ้นบน · bump `spotlight.css?v=9` / `spotlight.min.js?v=11`
- **zyra-app:** ป้าย/summary ออกจากคลังของ scene editor · `featureFromDTO` ไม่โหลดวัตถุ sign/summary (บันทึกฉากครั้งถัดไปจะหายจาก DB) · พรีวิวหน้า management เป็นโครงเดียวกับ stage ของ landing (`aspect 1264/500`) ดึงรูปผ่าน `useRoadmapPresetUrls()` (admin assets API)
- **verify:** api `go build` + `go vet` + `go test ./internal/service ./internal/router` เขียว · app `eslint`/`prettier`/`tsc` (ไม่มี error ใหม่) + `vitest roadmap-feature` · landing `npm run build` + เปิดหน้าจริงกับ mock (มี `preset_assets` + วัตถุ summary เก่าในฉาก): 1440px ป้ายซ้ายล่าง/ฉากกลาง/summary ขวา และวัตถุ summary เก่าถูกข้าม · 375px ฉากบน ป้าย+summary ล่าง
- **ยังไม่ได้ทำ:** ยังไม่ได้เปิด editor/หน้า management จริง (ต้องล็อกอิน admin) · scene editor ยังเป็น canvas 16:9 อย่างเดียว ไม่แสดงป้าย/summary ข้าง ๆ (ดูผลรวมได้ที่พรีวิวหน้า management) · ฉากเดิมที่จัดเฟอร์นิเจอร์หลบป้าย/summary ไว้อาจต้องจัดใหม่ให้เต็มกรอบ · ยังไม่ commit

## 2026-10-05 (รอบ 12) · rif — ตัวอักษรกล่อง summary ใน editor ให้ตรงกับ landing

- **อาการ:** ข้อความเดียวกันใน scene editor พอดีกล่อง แต่บน landing ตัวใหญ่กว่าและถูกตัด "…" ที่บรรทัด 5
- **สาเหตุ:** admin ใช้ฟอนต์หลักของหน้า (Inter) ขนาดตายตัว 11px/15px ส่วน landing ใช้ Poppins ขนาด `clamp(8px, 6cqw, 15px)` ตามความกว้างกล่อง line-height 1.4
- **แก้ (zyra-app `scene-object-visual.tsx`):** กล่อง summary ทั้งแบบกระดาษและแบบกล่องดำใช้ `SUMMARY_TEXT_CLASS` = Poppins → Noto Sans Thai, `clamp(8px,6cqw,15px)`, leading 1.4, ตัดที่ 5 บรรทัด + `@container` ที่กล่อง (เท่ากับ `.sp-obj` ของ landing) — landing ไม่ต้องแก้
- verify: `eslint` + `prettier` + `tsc` (ไม่มี error ใหม่) · ยังไม่ได้เปิด editor จริงดูผล

## 2026-10-05 (รอบ 11) · rif — ถอด Mystery silhouette ออกจากคลัง + Mystery รายวัตถุผูกกับ teaser

- **ถอด preset "Mystery silhouette"** ออกจากคลังของ scene editor (วัตถุ kind `mystery` ในฉากเดิมยังแสดงได้)
- **Mystery รายวัตถุ:** toggle ใน Properties ของวัตถุที่อัปเอง · เปิด teaser ของฟีเจอร์แล้วทุกชิ้นที่ติ๊กไว้จะเป็นเงาดำ + "?" พร้อมกัน
- **decision ที่ผู้ใช้เลือก:** teaser = แสดงฉาก + ปิดเฉพาะชิ้น (ไม่ซ่อนทั้งฉากแบบเดิม) · กล่อง summary ตอน teaser แสดง "Upcoming soon" ตายตัว · editor เห็นเงาดำตาม teaser · toggle ใช้ได้เฉพาะวัตถุที่อัปเอง
- **zyra-api:** migration `109_roadmap_object_mystery` (+ down, mirror ใน `postgres.go`) · `is_mystery` ใน model/input/insert/select · validation ปฏิเสธ `is_mystery` บนวัตถุที่ไม่ใช่ custom (+ เทสต์)
- **zyra-app:** `mystery` ใน `RoadmapSceneObject` + mapper/payload · `SceneObjectVisual` prop `concealed` · canvas/พรีวิวเลิกปิดทั้งฉาก (canvas เหลือป้ายบอกโหมดมุมซ้ายบน) · toggle ใน Properties · ไอคอน ? ใน Layers · i18n en/th (`propMystery`, `propMysteryHint`, `layerMystery`, `teaserSummary`, แก้ `fieldTeaserHint`, `teaserOverlay`)
- **zyra-landing:** เลิกซ่อนทั้งฉากตอน teaser · วัตถุ `is_mystery` ได้ class `.is-mystery` (`brightness(0)`) + `.sp-mystery-mark` · summary เป็น "Upcoming soon"/"เร็ว ๆ นี้" · ลบ CSS `.sp-teaser`/`.sp-teaser-shadow` ที่ไม่ใช้แล้ว · bump `spotlight.css?v=8` / `spotlight.min.js?v=10`
- **verify:** api `go build` + `go vet` + `go test ./internal/service -run Roadmap` เขียว · app `eslint` + `prettier` + `tsc` (ไม่มี error ใหม่) + `vitest roadmap-feature` ผ่าน · landing `npm run build` + เปิดหน้าจริงกับ mock (teaser, วัตถุ 2 ชิ้นเปิด Mystery 1 ชิ้น + กล่อง summary) เห็นเงาดำ + ? เฉพาะชิ้นที่เปิด และ summary ขึ้น "Upcoming soon"
- **ยังไม่ได้ทำ/ข้อควรรู้:** ยังไม่ได้เปิด scene editor จริงในเบราว์เซอร์ (ต้องล็อกอิน admin) · บรรทัดวันที่ตอน teaser ยังเป็น "Upcoming" ตามเดิม (ในภาพตัวอย่างเป็นวันที่) · public API ยังส่งรูปจริงของวัตถุ Mystery มาด้วย · migration 109 จะขึ้นเองตอน API start · ยังไม่ commit (ทำต่อบน branch เดิม `feat/roadmap-quarter-sign-asset` ของ api/app)

## 2026-10-05 (รอบ 10) · rif — landing: ไทม์ไลน์ตามภาพใหม่ + scroll พาเดินถึงฟีเจอร์ปัจจุบัน

- **โจทย์:** ปรับ UI ไทม์ไลน์ของ section 07 ให้เหมือนภาพที่ผู้ใช้ส่ง (ไม่มี Figma กะจากภาพ) · เข้ามาให้เริ่มที่ฟีเจอร์แรก แล้วระหว่าง scroll ลงให้เดินทีละอันจนถึงฟีเจอร์ปัจจุบัน ไม่ข้ามไป upcoming
- **decision ที่ผู้ใช้เลือก:** ตรึง section (sticky) ระหว่างเดิน · ชื่อฟีเจอร์อยู่ในรูป thumbnail แล้ว ไม่ต้องวาดทับ · ย้ายปุ่มลูกศรจากข้างฉากมาไว้หัว/ท้ายแถบการ์ด (ปุ่มซ้ายซ่อนตอนอยู่อันแรก)
- **UI (`css/spotlight.css`):** รางเทา 8px `#EBEBEB` + แถบเขียวไล่เฉดจากซ้ายถึงจุดที่เลือก (`.sp-rail-fill`) · จุดปกติ `#C4C6C9` · ชิดซ้ายแทนการเว้นครึ่งจอ · เอาเงาดำและชื่อบนการ์ดออก · การ์ดที่ล้นขวาจางหาย (`mask-image` ยกเว้นตอนเลื่อนสุด) · วันที่ย้ายมาอยู่ใต้การ์ด จัดกึ่งกลาง (แก้ markup ใน `Feature.html` ทั้ง en/th) · ขนาดการ์ด/จุดใช้ค่าเดิม (ภาพที่ส่งมาคือขนาดเดิมซูม ~1.35 เท่า)
- **การตรึง (`component/spotlight.js`):** ห่อ `.sp-panel` ด้วย `.sp-pin` ที่สูง = panel + (index ฟีเจอร์ปัจจุบัน × STEP) แล้วตั้ง panel เป็น sticky กลางจอ · STEP = 45% ของความสูงจอ (160–360px) · ทุกครั้งที่ข้ามขั้นจะ `select(index)` scroll ขึ้นก็ถอยกลับ · ถ้ายังไม่มีฟีเจอร์ที่ปล่อยเกิน 1 อันจะไม่ตรึง · `.sp-section` เปลี่ยน `overflow: hidden` → `clip` (hidden ทำให้ sticky ไม่ทำงาน)
- bump `spotlight.css?v=7` / `spotlight.min.js?v=9` (+ `tools/build.js`)
- **verify:** รันหน้า Feature จริงผ่าน http server + mock API 7 ฟีเจอร์ (released 4 / upcoming 3) ใน browser pane: ที่ 1440×900 หน้าตาตรงกับภาพ, scroll แล้วเดิน 0→1→2→3 แล้วหยุดที่ index 3 (ไม่ไป upcoming) และ panel ติดกลางจอระหว่างเดิน · ที่จอแคบ 534px การ์ดจางขวาตามภาพ (แก้ความสูงแถวการ์ดบนมือถือให้เท่าการ์ด 70px) · `npm run build` ผ่าน
- **ข้อควรรู้:** หน้า Feature ใช้ Lenis (smooth scroll) ถ้า scroll เร็วมากอาจข้ามบางขั้นไปเลย ฉากก็ข้ามตาม (ไทม์ไลน์ยังถูกต้อง) · ถ้าตอนโหลดหน้าอยู่เลย section ไปแล้ว ไทม์ไลน์จะอยู่ที่ฟีเจอร์ปัจจุบันเลย
- **ยังไม่ได้ทำ:** ยังไม่ได้ลองกับ thumbnail จริงบน dev (ข้อมูลจริงมีแค่ 2 ฟีเจอร์) · ยังไม่ได้ลองบน iOS Safari จริง · ยังไม่ commit

## 2026-10-05 (รอบ 9) · rif — ตัวอักษรบนป้ายไตรมาส

- เปลี่ยนตามภาพที่ผู้ใช้ส่ง: ตัวอักษรเป็นสีขาว ฟอนต์ Poppins · บรรทัดไตรมาสตัวหนา `clamp(6px, 7.5cqw, 48px)` · บรรทัดช่วงเดือนตัวปกติ `clamp(5px, 5.6cqw, 36px)` · ระยะห่างระหว่างบรรทัด `3cqw` · ขนาดเป็น cqw จึงย่อ/ขยายตามป้าย (เดิมฝั่ง admin เป็น px ตายตัว)
- zyra-app `SceneObjectVisual` (เพิ่ม `@container`) · zyra-landing `.sp-sign-label` / `.sp-sign-range` / `.sp-sign-text` + bump `spotlight.css?v=6`
- **ยังไม่ทำ:** ลูกศร ˅ หลัง "2026, Q1" ในภาพ ยังไม่ได้ถามว่าเป็นแค่ตกแต่งหรือเป็น dropdown เลือกไตรมาส
- verify: app `eslint`/`prettier`/`tsc` (ไม่มี error ใหม่) · landing `npm run build` · render ด้วย headless Chrome เทียบกับภาพตัวอย่างแล้ว

## 2026-10-05 (รอบ 8) · rif — กล่อง summary เปลี่ยนเป็นกระดาษ + ไม้ (asset ในคลัง)

- **โจทย์:** เปลี่ยน Summary box จากกล่องดำโปร่งแสงเป็นกระดาษมีไม้บน/ล่าง ผู้ใช้ให้มา 3 ชิ้นแยก (`frame.png`, `zyra_wood_top_with_leaves 2.png`, `zyra_wood_bottom_with_leaves 2.png`)
- **decision ที่ผู้ใช้เลือก:** ประกอบ 3 ชิ้นเป็นรูปเดียว (ย่อขยายแบบคงสัดส่วนเหมือนเดิม ไม่ทำแบบยืดความสูง) · เก็บขนาดเต็ม ไม่ย่อ → `summary-box.png` 4528×3417 ≈4.5MB · ใช้กลไก seed เดียวกับป้ายไตรมาส
- **ประกอบรูป:** วางกระดาษกลาง แล้ววางไม้บน/ล่างทับขอบตามสัดส่วนที่วัดจากภาพตัวอย่างที่ผู้ใช้ส่ง (ทั้ง 3 ชิ้นสเกลเดียวกันอยู่แล้ว)
- **zyra-api:** `EnsureQuarterSignAsset` → `EnsurePresetAssets` วนตามรายการ `roadmapPresetAssetSpecs` (`quarter_sign` → `sign`, `summary_box` → `summary`) · เพิ่ม `model.RoadmapAssetPresetSummaryBox` · timeout ของ seed 30s → 60s เพราะไฟล์ใหญ่ขึ้น · เทสต์เปลี่ยนเป็น `TestRoadmapPresetAssetsEmbedded` (ทุกรูปอ่านได้, key/kind ไม่ซ้ำ)
- **zyra-app:** `presetFromAsset` แปลงตาม `PRESET_ASSET_OBJECTS` · เอา summary ออกจาก preset ตายตัว (มาจากคลัง asset แทน) · `SceneObjectVisual` วางข้อความสี `#5C6570` ในกระดาษ (22–85%, ขอบ 11%) ถ้าไม่มีรูปจะแสดงเป็นกล่องดำแบบเดิม
- **zyra-landing:** summary ที่มี `asset.image_url` แสดงรูป + ข้อความในกระดาษ (`.sp-summary.is-framed` / `.sp-summary-body`) ไม่มีรูปจะใช้กล่องดำแบบเดิม (ไม่ใส่รูปสำรองใน repo เพราะไฟล์ 4.5MB) · `KIND_ASPECT.summary` = 0.75 · bump `spotlight.css?v=5` / `spotlight.min.js?v=8`
- **verify:** api `go build` + `go vet` + `go test ./internal/service -run Roadmap` เขียว · app `tsc` ไม่มี error ใหม่, `eslint` + `prettier` เขียว · landing `npm run build` ผ่าน (restore ไฟล์ blog/compare/sitemap ที่ build เขียนทับ) · render รูปพร้อมข้อความ 2 ขนาดด้วย headless Chrome แล้ว ตรงกับภาพตัวอย่าง
- **ข้อควรรู้:** กล่อง summary ที่วางไว้แล้วจะถูกผูกกับ asset ตอน API start และ `aspect` เปลี่ยนจาก 0.5 เป็น ≈0.755 จึงสูงขึ้น ต้องจัดตำแหน่งใหม่ถ้าไปทับวัตถุอื่น · landing โหลดรูป 4.5MB ต่อหน้า (ใช้ `loading="lazy"`)
- **ยังไม่ได้ทำ:** ยังไม่ได้รัน seed กับ S3/DB ของ dev · ยังไม่ได้เปิด editor/landing กับข้อมูลจริง · ยังไม่ commit (ต่อจาก commit ป้ายไตรมาสที่ผู้ใช้ commit ไว้แล้ว)

## 2026-10-05 (รอบ 7) · rif — ป้ายไตรมาสย้ายเข้าคลัง asset (S3) + เปลี่ยนรูปเป็น Frame Q

- **โจทย์:** ป้ายไตรมาสเดิมเป็นไฟล์ `zyra-app/public/image/roadmap/sign.png` ไม่ได้อยู่บน S3 → ให้เก็บรวมกับ asset อื่น และเปลี่ยนรูปเป็น `Frame Q.png` (892×516 ป้ายไม้แนวนอนมีใบไม้)
- **decision ที่ผู้ใช้เลือก:** (1) API seed ป้ายเข้าคลังให้เองตอน start โดยระบุด้วยคอลัมน์ `preset_key` (2) ผูกวัตถุป้ายเดิมที่ `asset_id` ว่างเข้ากับ asset ใหม่ แล้วลบไฟล์ใน `public/` · รายละเอียดอยู่ที่ [technical-design.md §2](technical-design.md)
- **zyra-api** (`feat/roadmap-quarter-sign-asset` แตกจาก develop): migration `108_roadmap_asset_preset` (+ down) และ mirror ใน `postgres.go` · `model.RoadmapAsset.PresetKey` · `roadmap_preset_assets.go` (`EnsureQuarterSignAsset` ใช้ go:embed) · `ListAssets` ส่ง `preset_key` · `DeleteAsset` ลบ preset ไม่ได้ · เรียก seed แบบ goroutine ใน `main.go` เมื่อ `ROADMAP_ENABLED`
- **zyra-app** (`feat/roadmap-quarter-sign-asset` แตกจาก develop): `presetFromAsset` แปลง asset `quarter_sign` เป็น preset kind `sign` (width 20) · `libraryPresets()` เรียงคลังเป็น asset ที่อัปเอง → Ground → ป้าย → ที่เหลือ · ปุ่มลบในคลังแสดงเฉพาะ `kind = custom` · `SceneObjectVisual` ย้ายข้อความไปช่วง 15–65% และเว้นขอบ 14% ถ้าไม่มีรูปจะแสดงเป็นกล่องไม้สีพื้นแทน · ลบ `public/image/roadmap/sign.png` และ fallback ตาม kind ใน `sceneObjectFromDTO`
- **zyra-landing** (`feat/roadmap-spotlight`): renderer ใช้ `object.asset.image_url` อยู่แล้ว จึงแก้แค่ตำแหน่ง `.sp-sign-text` · `KIND_ASPECT.sign` = 0.58 · เปลี่ยนรูป fallback `assets/roadmap-sign.png` เป็นรูปใหม่ · bump `spotlight.css?v=4` / `spotlight.min.js?v=7` (`npm run build` จะเขียนไฟล์ blog/compare/sitemap ใหม่ด้วย ซึ่งไม่เกี่ยวกับงานนี้ เลย restore กลับ)
- **verify:** api `go build ./...` + `go vet` + `go test ./internal/service -run Roadmap` เขียว (เพิ่มเทสต์ `TestRoadmapQuarterSignEmbedded`) · รัน SQL ของ migration 103+108 พร้อม seed บน Postgres 16 ชั่วคราวใน docker: seed ครั้งแรกได้แถว, ครั้งที่สองชน conflict ได้ 0 แถว, ป้ายเดิมถูกผูกและได้ aspect ใหม่ ส่วน ground ไม่ถูกแตะ, ลบ preset ไม่ได้, down migration รันผ่าน · app `tsc` ไม่มี error ใหม่ (เหลือ error เดิม 7 ตัวใน `__tests__`) + `eslint` + `prettier` เขียว · render รูปพร้อมข้อความทับ 3 ขนาดด้วย headless Chrome แล้ว ข้อความอยู่กลางแผ่นไม้
- **ยังไม่ได้ทำ/ยังไม่ verify:** ยังไม่ได้รัน seed จริงกับ S3 + DB ของ dev (ต้อง deploy หรือรัน API ที่ต่อ dev) · ยังไม่ได้เปิด scene editor และ landing ในเบราว์เซอร์กับข้อมูลจริง · ข้อความบรรทัดช่วงเดือน (`#6B4F2E`) อ่านยากบนไม้สีส้มน้ำตาลของรูปใหม่ ยังไม่ได้เปลี่ยนสีเพราะยังไม่มีแบบ · ยังไม่ commit ทั้ง 3 repo

## 2026-09-21 (รอบ 6) · rif — ไล่เคส "landing ไม่ยิง API เลย"

- **อาการที่แจ้ง:** เปิดหน้าแรกแล้ว section 07 ไม่ขึ้น และ DevTools → Fetch/XHR ว่างเปล่า (0 request)
- **สาเหตุจริง:** section 07 ถูกใส่ไว้ใน **`output/index.html`** แต่หน้าที่ผู้ใช้เปิดคือ **`output/Feature.html`** ซึ่งเป็นหน้าที่มี section 01–06 (Figma บอกว่า "ต่อจาก 06" = หน้า Feature) — ไม่มี markup/สคริปต์ของ 07 อยู่เลย จึงไม่มีอะไรไปยิง API (ไม่เกี่ยวกับ summary box ที่เพิ่งเพิ่ม: renderer รองรับ kind `summary` อยู่แล้ว)
- **แก้:** ย้าย section 07 + `<link css/spotlight.css>` + `<script component/spotlight.min.js>` ไปที่ `Feature.html` (วางต่อจาก 06 ก่อน `#testimonials`) และถอดออกจาก `index.html`; ปรับ markup ให้ใช้คลาสของหน้านั้น (`fx-feature center` / `fx-wm` / `fx-head` / `fx-title` / `fx-lead`) แล้วลบ `.sp-ghost`/`.sp-head` ที่ไม่ได้ใช้ออกจาก `spotlight.css` · bump `?v=3` (ทั้ง `tools/build.js` V map)
- **เช็คด้วยว่าไม่ใช่:** prod `https://zyra-world.com` ซึ่งยังไม่ได้ deploy สาขา `feat/roadmap-spotlight` — ตัว HTML บน prod ไม่มี markup ของ section 07 และไม่มี `component/spotlight.min.js` เลย จึงไม่มีอะไรไปยิง API (เทียบ: prod ข้ามจาก 06 ไป `#testimonials` ตรง ๆ, ไฟล์ local มี `id="spotlight"` คั่นอยู่) — โค้ดฝั่ง local ทำงานปกติ
- **verify:** render ด้วย headless Chrome ทั้ง `Feature.html` และ `th/Feature.html` — section เปิด, ยิง API สำเร็จ, วัตถุครบ 30 ชิ้นรวมกล่อง summary, การ์ด `test-01`/`test-02`, วันที่ `17 Sep 2026` · ต้องเปิดผ่าน http เท่านั้น (เช่น Live Server :5500 หรือ `python3 -m http.server` ใน `output/`) — `file://` origin เป็น `null` แล้วโดน CORS บล็อก
- **แก้เพิ่มระหว่างทาง (zyra-landing):**
  - `output/component/spotlight.js` — เดิมเงียบสนิททุกเคสที่ไม่ผ่าน ทำให้แยกไม่ออกว่า "ไม่มี markup / ไม่มี API_URL / API ล้ม / ไม่มีข้อมูล"; ตอนนี้ warn ใน console เป็น `[spotlight] ...` ทุกเคส (ยังซ่อน section เหมือนเดิม)
  - เลือกการ์ดเริ่มต้นเป็นฟีเจอร์ล่าสุดที่ **`status === "released"`** เท่านั้น — เดิมดูแค่ `release_date <= today` จึงเผลอเปิดมาที่ตัว upcoming/teaser แล้วเห็นเป็นเงา `?` ทั้งที่มีฉากอยู่
  - ป้ายไตรมาสและกล่อง summary เดิมใช้ font-size คงที่ (12/10/14px) พอจอแคบวัตถุย่อแต่ตัวอักษรไม่ย่อ → ข้อความล้นกล่อง; เปลี่ยนเป็น `container-type: inline-size` บน `.sp-obj` + `clamp(..cqw..)` ให้ย่อตามขนาดวัตถุเหมือนตอนจัดฉาก (เบราว์เซอร์เก่าตกไปใช้ px เดิม)
- **ไทม์ไลน์: ยึดฟีเจอร์ที่ปล่อยล่าสุดไว้กลางจอ** (ตามที่ผู้ใช้ขอ) — ซ้าย = ที่ปล่อยไปแล้ว, ขวา = upcoming เลื่อนไปดูได้
  - `.sp-rail` / `.sp-thumbs` เปลี่ยนจาก `justify-content: center` เป็น `flex-start` + `padding-inline: calc(50% - 80px)` (จอ ≤600px ใช้ `calc(50% - 56px)` ตามการ์ด active ที่แคบลง) — การ์ดที่เลือกจึงเลื่อนมากึ่งกลางได้เสมอแม้เป็นอันแรก/อันสุดท้าย
  - `syncActive(scrollIntoView, instant)` — ครั้งแรกเลื่อนแบบไม่อนิเมต, กดการ์ดอื่นค่อยเลื่อนแบบ smooth (เคารพ `prefers-reduced-motion` เหมือนเดิม)
  - API เรียงมาตาม `release_date ASC` อยู่แล้ว (`roadmap_service.go`) ลำดับซ้าย→ขวาจึงเป็นอดีต→อนาคตตรงตามที่ต้องการ
  - verify ด้วย mock 5 ฟีเจอร์ (released 3 / upcoming 2): เปิดมาการ์ด `released-C` อยู่กลางจอพอดี มีของเก่า 2 ใบซ้าย ของใหม่ 2 ใบขวา
- **เส้นไทม์ไลน์ + ปุ่มเลื่อนซ้าย/ขวา ตาม Figma**
  - `.sp-rail::before` จากแถบหนา 8px `--surface-2` → เส้น 1px `#d9d9d9` (จุดวางทับบนเส้น)
  - เพิ่มปุ่ม `.sp-nav` (44px r10 ขอบ `#e3e4e6` พื้นขาว, จอ ≤600px เหลือ 36px) วางชิดขอบจอด้วย `left/right: calc(50% - 50vw + clamp(8px, 4vw, 64px))` และกึ่งกลาง stage ด้วยตัวแปรใหม่ `--sp-stage-h` (500/320/220 ตาม breakpoint แทน height ที่ hardcode)
  - ปุ่มเกาะกับกรอบ stage โดยตรง: `buildNav()` ห่อ `.sp-stage` ด้วย `.sp-stage-row` (position: relative) แล้ววางปุ่ม `top: 50%` ในแถวนั้น — รอบแรกผูกไว้กับ `.sp-panel` + `top: calc(var(--sp-stage-h)/2)` แล้วบางเครื่องปุ่มไปเกาะขอบบน (ถ้า custom property/containing block ไม่เป็นไปตามที่คิด abs child ของ flex จะตกไปที่มุมบนซ้าย) ตอนนี้ไม่พึ่งตัวแปรแล้ว · ต้องมีแถวครอบเพราะ `.sp-stage` เองเป็น `overflow: hidden`
  - ปุ่มสร้างจาก JS (`buildNav()` ใน `spotlight.js`) ใช้ svg chevron ไม่ต้องพึ่ง icon lib และได้ aria-label ไทย/อังกฤษตาม `isTH()` โดยไม่ต้องแก้ markup สองหน้า · `disabled` อัตโนมัติเมื่ออยู่ใบแรก/ใบสุดท้าย · มีฟีเจอร์เดียวไม่สร้างปุ่ม
- **Teaser mode ของฟีเจอร์ใหม่เริ่มที่ปิด** (เดิมเปิดไว้ตั้งแต่แรก ทำให้ของที่เพิ่งสร้างโชว์เป็นเงา `?` บน landing ทั้งที่จัดฉากไว้แล้ว)
  - app: draft ใน `hero-roadmap.tsx` → `teaser: false` (ค่าอื่นคงเดิม: `status: upcoming`, `visible: false`)
  - api: `is_teaser` default เป็น `FALSE` ทั้ง `migrations/103_roadmap.sql` และ DDL ตอน service start + `ALTER TABLE tb_roadmap_feature ALTER COLUMN is_teaser SET DEFAULT FALSE` สำหรับตารางที่สร้างไปแล้ว (มีผลหลังรีสตาร์ต service)
- **ไทม์ไลน์แยกกลุ่มตามสถานะ — เรียงที่ API ไม่ใช่ที่ client**
  - เพิ่ม sort mode `"timeline"` ใน `roadmapOrderSQL()` (แยกออกมาจาก `ListFeatures`): `CASE WHEN f.status = 'released' THEN 0 ELSE 1 END, f.release_date ASC, f.created_at ASC` → ปล่อยแล้วทั้งกลุ่มมาก่อน แล้วค่อย upcoming ไม่ปนกันแม้วันปล่อยจะคาบเกี่ยว
  - `ListPublic` ตั้ง `Sort: "timeline"` ตายตัว (ไม่ให้ query string เปลี่ยนลำดับของ landing) · `/api/admin/roadmap` ยังเลือก sort ได้เหมือนเดิม
  - **ทำรอบแรกผิดที่**: ไปเรียงใน `spotlight.js` หลัง fetch ซึ่งใช้ไม่ได้เพราะผลลัพธ์แบ่งหน้า (`limit=100`) — เรียงฝั่ง client จะได้แค่หน้าที่โหลดมา ย้ายมาไว้ที่ SQL แล้วถอดโค้ดเรียงฝั่ง landing ออก
  - การ์ดเริ่มต้น = ตัวสุดท้ายของกลุ่ม released (จุดรอยต่อพอดี) ยังคำนวณฝั่ง client เพราะเป็นเรื่องการแสดงผล
  - verify: unit test `TestRoadmapOrderSQL` (5 เคส) · รัน API ชั่วคราวที่พอร์ต 3009 ยิง `/api/public/roadmap` จริง — SQL รันผ่านบน Postgres ได้ 200 · ก่อนหน้านี้เคยลอง mock 5 ฟีเจอร์ที่จงใจสลับวัน ได้ `released × 3 | upcoming × 2` ตามที่ต้องการ
- **ไล่เช็กงานทั้งหมดอีกรอบ:** `go build` + `go vet` + `go test -count=1 ./internal/...` เขียว (เจอ `https://www.zyra-world.com` หายไปจาก allowlist ของ `public_cors.go` อีกครั้ง — ใส่กลับแล้ว test ผ่าน) · app `tsc` เหลือแต่ error เดิมใน `__tests__/*` ที่ไม่เกี่ยว roadmap, `eslint`/`prettier` เขียว, `vitest __tests__/roadmap-feature.test.ts` 3 เคสผ่าน · ฝั่ง landing ตรวจ `spotlight.js`/`spotlight.css` ว่าไม่มีคลาสตายค้าง (`.sp-ghost`, `.sp-head` และใน media query) และแก้ warn ซ้ำสองครั้งตอน API ตอบไม่ 200
- **สถานะ branch:** api `feat/admin-roadmap-api` merge เข้า develop ไปแล้ว (PR #128) เหลือของใหม่ที่ยัง uncommitted (kind `summary`, `sheet_width/height`, CORS www) · app `feat/admin-product-updates` มี commit ถึง `00d275d` เหลือไฟล์ roadmap ที่แก้รอบ summary ยัง uncommitted · landing `feat/roadmap-spotlight` commit `47dfe7e` แล้ว เหลือการย้ายไป Feature.html ยัง uncommitted
- **ต่อจากนี้:** commit/push 3 repo แล้วเปิด PR · ตั้ง `ROADMAP_ENABLED` (api) + `NEXT_PUBLIC_ROADMAP` (app) + `API_URL` ของ landing บน uat/prod ก่อนถึงจะเห็น section 07 บนโดเมนจริง

## 2026-09-21 (รอบ 5) · rif — landing section 07 + object ชนิด summary

- **ทำอะไร:**
  1. **zyra-landing** (branch `feat/roadmap-spotlight` แตกจาก main) — section 07 "Zyra Spotlight" ตาม Figma node `2567:28420`: ghost 07, capsule, หัวข้อ/คำโปรย, stage, บรรทัดวันที่, รางจุด (ปกติ 16px `#D9D9D9` / active 24px `#58D68D`), การ์ดฟีเจอร์ (120×74 opacity .5 → active 160×100 + gradient + ชื่อ)
     - `component/spotlight.js` ดึง `GET {API_URL}/api/public/roadmap` แล้ววาดฉากจาก objects ด้วยพิกัด % เดียวกับที่จัดในหน้า admin (sprite เล่นตาม frames/fps) · ไม่มี API / flag ปิด / ไม่มีข้อมูล = ซ่อน section เงียบ ๆ
     - **กับดัก:** `index.html` โหลด `css/bundle.min.css` ซึ่งเป็น artifact ที่ commit ไว้และไม่มีตัว generate ใน repo → แก้ `styles.css` แล้วไม่มีผล จึงแยกเป็น `css/spotlight.css` + `<link>` (คอมเมนต์เตือนไว้ในไฟล์)
     - พื้น stage เป็น **สีขาว** ตามที่ทีมขอ (Figma เป็น #EBECED) และฉากวาดในกรอบ `.sp-canvas` **16:9** ซ้อนใน stage — ถ้าวาดลงกรอบ 2.53:1 ของ Figma ตรง ๆ ตำแหน่งวัตถุจะเพี้ยนจากที่จัดไว้
  2. **CORS**: `middleware/public_cors.go` เดิมรับแค่ `https://zyra.center` + `POST` → เพิ่ม `https://zyra-world.com`, `www.`, `http://localhost:*`/`127.0.0.1:*` และเมธอด `GET` (+ test 3 เคส)
  3. **object ชนิดใหม่ `summary`** — กล่องดำโปร่งแสง `rgba(0,0,0,.45)` โชว์ข้อความ summary ของฟีเจอร์ (ไม่ต้องพิมพ์ซ้ำต่อวัตถุ) เป็น default object ในคลังของ scene editor: เพิ่ม kind ใน CHECK constraint (มี `ALTER ... DROP/ADD CONSTRAINT` ให้ตารางเดิมบน dev), model/validator ฝั่ง API, preset + visual ฝั่ง admin, และ renderer ฝั่ง landing
- **verify:** zyra-api `go build` + `go test ./internal/...` เขียว (CHECK ใหม่ apply บน dev แล้ว) · zyra-app `tsc`/`eslint`/`vitest`/`npm run build` ผ่าน · zyra-landing `npm run build` ผ่าน และตรวจการเรนเดอร์จริงด้วย Chrome + mock API (ฉาก 2 วัตถุ, สลับการ์ด, teaser)
- **ติดอะไร:** ยังไม่มีฟีเจอร์ที่ `is_visible = true` บน dev (มี `test-01` แต่ยังปิดอยู่) landing จึงยังซ่อน section · asset ที่อัปก่อน 2026-09-17 ไม่มี `sheet_width/height` ต้องอัปใหม่ถึงจะตัดเฟรมตรง

## 2026-09-17 (รอบ 4) · rif — feature flag เปิด/ปิดทั้งฟีเจอร์

- **ทำอะไร:** เพิ่ม kill switch คู่กันทั้งสองฝั่ง (ดู [technical-design.md §2.5](technical-design.md))
  - **zyra-api** `ROADMAP_ENABLED` (default `false`) — `cfg.RoadmapEnabled` ใน `internal/config/config.go`; router ไม่ลงทะเบียน group ของ roadmap เลยเมื่อปิด (ทั้ง admin และ public → 404) + test `internal/router/roadmap_routes_test.go` ยืนยันทั้งเปิดและปิด
  - **zyra-app** `NEXT_PUBLIC_ROADMAP` (default `false`) — `lib/roadmap-feature.ts` (แพตเทิร์นเดียวกับ `lib/pet-feature.ts`), ซ่อนเมนูใน `AdminSidebar`, สองหน้า `notFound()` เมื่อปิด, ผูก build-arg ใน `Dockerfile` + `.github/workflows/deploy-gitops.yml` (secret `NEXT_PUBLIC_ROADMAP`) + test `__tests__/roadmap-feature.test.ts`
  - ตั้งค่า `.env` ของเครื่อง dev ให้เป็น `true` ทั้งสอง repo แล้ว (ไฟล์ .env ไม่เข้า git — บน dev/uat/prod ต้องตั้ง env/secret เอง)
- **verify:** `go build` + `go test ./internal/...` เขียว · app `eslint` / `tsc` / `vitest` (3 เคส) / `npm run build` ผ่าน
- **ข้อควรรู้:** flag ปิดแค่ทางเข้า — ตารางยังถูกสร้างตามปกติเพราะ DDL อยู่ใน startup migrations

## 2026-09-17 (รอบ 3) · rif — ตารางขึ้น DB จริง + ลบ asset ได้ + แก้ sprite เพี้ยน

- **ทำอะไร:**
  1. **ตารางไม่ขึ้น DB:** repo นี้ `migrations/*.sql` ไม่ auto-run — ตารางจริงมาจาก DDL idempotent ใน `internal/database/postgres.go` (`runMigrations` ตอนต่อ DB) จึง mirror DDL ของ roadmap เข้า slice นั้น (เหมือน migration 88/91) แล้วรัน entrypoint ชั่วคราวเพื่อ apply บน **dev** (`zyra-db` 35.247.177.198) — ยืนยันแล้วว่า `tb_roadmap_feature` / `tb_roadmap_scene_object` / `tb_roadmap_asset` มีจริง
  2. **ลบ asset ออกจากคลังได้:** ไทล์ของ asset ที่อัปเองมีปุ่มถังขยะ (hover) → กล่องยืนยัน (ปุ่มแดง) → `DELETE /api/admin/roadmap/assets/:assetId` (soft delete ฉากที่ใช้อยู่ยังแสดงได้) + toast + refetch คลัง
  3. **sprite เรนเดอร์เพี้ยนบน canvas:** เดิมคำนวณขนาดชีทเต็มจาก `frame_width × columns` ซึ่งไม่ตรงกับไฟล์ที่มีช่องว่างระหว่างเฟรม → เพิ่มคอลัมน์ `sheet_width` / `sheet_height` ใน `tb_roadmap_asset` (+ `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` สำหรับตารางที่สร้างไปแล้ว) เก็บขนาดไฟล์จริงตอนอัปโหลด แล้ว client ใช้ค่านี้คำนวณ background-position
     - หมายเหตุ: canvas เรนเดอร์ sprite ด้วย CSS background ไม่ใช่ Pixi (Pixi ใช้เฉพาะพรีวิวใน modal) เพราะ 1 วัตถุ = 1 WebGL context จะชนลิมิตเบราว์เซอร์เมื่อฉากมีหลายชิ้น
- **verify:** `go build` / `gofmt` / `go test ./internal/service -run Roadmap` เขียว · ฝั่ง app `tsc` ไม่มี error ใหม่, `eslint` เขียว, `npm run build` ผ่าน
- **ยังไม่ทำ:** asset ที่อัปก่อนรอบนี้ (ถ้ามี) จะไม่มี `sheet_width/height` ต้องอัปใหม่หรือเติมค่าให้ก่อนจึงจะตัดเฟรมตรง

## 2026-09-17 (รอบ 2) · rif — ต่อ API แทน mock ทั้งหมด

- **ทำอะไร:** ทำ backend ของ roadmap ใน `zyra-api` แล้วเปลี่ยนหน้า admin จาก mock เป็นเรียก API จริง · contract + schema เต็มอยู่ใน [technical-design.md](technical-design.md)
- **decision ที่ผู้ใช้เคาะก่อนลงโค้ด:** อ่านสาธารณะได้ (landing ไม่ล็อกอิน) · scene object เก็บเป็นตารางแยก (ไม่ใช่ JSONB) · asset อัปขึ้น S3 ทันที + เป็นคลังกลางใช้ซ้ำข้ามฟีเจอร์
- **ถึงไหน:**
  - **zyra-api** (branch `feat/admin-roadmap-api` แตกจาก `develop`): migration `103_roadmap.sql` (3 ตาราง + index + down), `internal/model/roadmap.go`, `internal/service/roadmap_service.go`, `internal/handler/roadmap_handler.go`, wire ใน `router.go` + `main.go`
    - admin: list/create/get/update/delete + `PUT /:id/scene` (เขียนทับทั้งฉากใน 1 tx, ลำดับ array = z-index) + `POST /:id/thumbnail` + asset library (`GET/POST /assets`, `PATCH/DELETE /assets/:assetId`)
    - public: `GET /api/public/roadmap` (เฉพาะ `is_visible` พร้อม objects, กัน N+1 ด้วยคิวรีเดียว) + `GET /api/public/roadmap/:featureId`
    - quarter คำนวณจาก `release_date` ฝั่ง service (ช่วง 4 เดือน) — client ส่งมาแค่วันที่
    - อัปโหลดตรวจชนิดจากไบต์จริง เพดาน 2MB เก็บ `frames` (กรอบเฟรมที่ detect ด้วย `lib/sprite-grid`) ไว้ใน DB เพื่อให้ตัดเฟรมตรงตอนโหลดกลับมา
  - **zyra-app** (branch `feat/admin-product-updates`): `lib/api/roadmap.ts` (typed client + `listPublicRoadmap`), `roadmap-data.ts` เปลี่ยนจาก mock store เป็น mapper API↔UI, หน้า management และ scene editor ใช้ TanStack Query + mutation จริง (loading/error/retry/toast ครบ), thumbnail อัปหลังบันทึกเพราะ endpoint ต้องมี feature id
- **PR:** ยังไม่เปิด · zyra-api `feat/admin-roadmap-api` (ยังไม่ commit) · zyra-app `feat/admin-product-updates` (ยังไม่ commit)
- **verify ถึงไหน:** `go build ./...`, `gofmt`, `go vet`, `go test ./internal/...` เขียว (เพิ่ม `roadmap_service_test.go`: quarter 7 เคส + validation ฟีเจอร์/ฉาก) · ฝั่ง app `tsc --noEmit` ไม่มี error ใหม่, `eslint` เขียว, `npm run build` ผ่าน · **ยังไม่ได้รันกับ DB จริง เพราะยังไม่ apply migration และยังไม่ได้ทดสอบ end-to-end ในเบราว์เซอร์**
- **ต่อจากนี้:** apply migration 103 บน dev → ทดสอบ CRUD + อัปโหลด + scene save จริง → ต่อฝั่ง `zyra-landing` กับ `/api/public/roadmap` → handler test ที่ยิง DB
- **ติดอะไร:** ไทม์ไลน์ยังเรียงตาม `release_date` อย่างเดียว (ยังไม่มี manual order) · ลบ asset เป็น soft delete ฉากเก่าที่อ้างอยู่ยังเห็นรูปเดิม

## 2026-09-17 (รอบ 1) · rif

- **ทำอะไร:** ออกแบบ + implement UI ฝั่ง admin ของ Roadmap ("Zyra Spotlight" บน landing) ตาม Figma/สกรีนช็อตที่ผู้ใช้ส่งระหว่างทาง — **UI อย่างเดียวตามที่ตกลง** ยังไม่แตะ API/DB
- **ถึงไหน:**
  - **`/admin/roadmap`** (`views/admin/roadmap/`) — ยึดมาตรฐาน pet-management: tab bar (Feature Library / Timeline) → list panel ซ้าย (search, `AdminFilterMenu` สถานะ+ไตรมาส, `AdminSortMenu`, `WorkspacePagination`) + detail panel ขวา + empty state `NoObjectsIcon`
    - detail แบ่งเป็น 3 slice ผ่าน stepper (แสดงสถานะอย่างเดียว กดไม่ได้ เดินด้วยปุ่ม Back/Next ที่โผล่เฉพาะโหมด Edit): **General information** (thumbnail 240px + ชื่อ + Release date + Quarter อ่านอย่างเดียว + Summary) · **Scene** (พรีวิวฉากพอดีกรอบ ไม่มี scroll + ปุ่มเปิด editor เฉพาะโหมด Edit) · **Publish** (Status, Timeline slot, toggle แสดงบน landing / โหมดปิดบัง, readiness checklist)
    - สถานะมีแค่ **upcoming / released** (ตัด in_progress ออกตามที่ผู้ใช้แจ้งว่าไม่มีใช้) · **Quarter คำนวณจาก Release date** อัตโนมัติ (ช่วง 4 เดือน: Q1 Jan–Apr, Q2 May–Aug, Q3 Sep–Dec) แก้เองไม่ได้
  - **`/admin/roadmap/[id]/scene`** (`views/admin/roadmap-scene/`) — ยึดมาตรฐาน workspace-editor: เต็มจอ `#1A1B1E`, top bar 72px (Back, ชื่อฟีเจอร์, Grid/Snap/Zoom, ปุ่ม Save เดียว), left panel แท็บ Objects/Layers, canvas 16:9 กลาง, Properties ขวา
    - ลาก/วางอิสระ, ลูกศรขยับ 0.5%, **ลากมุมย่อ-ขยายโดยตรึงมุมตรงข้าม** (คงสัดส่วน), snap 2.5%, **⌘/Ctrl+Z undo** (1 การลาก = 1 undo), **Delete ลบ**, Layers สลับลำดับ/ล็อก/ซ่อน, ground เปลี่ยนสีได้
    - **อัปโหลด object เอง** ผ่าน modal: เลือกประเภท Image / Sprite sheet / GIF → drag&drop หรือเลือกไฟล์ → ตั้ง Columns/Rows/FPS → **พรีวิวด้วย PixiJS `AnimatedSprite` แบบเดียวกับ pet-preview-modal** + กริดซ้อนบนไฟล์เต็ม; ตัดเฟรมด้วย `lib/sprite-grid` (detect alpha) ไม่ใช่หารกริดดิบ ๆ; แก้ asset ที่อัปแล้วได้จากปุ่ม Edit asset ใน Properties
  - **flow/กันบั๊กรอบสุดท้าย:** discard dialog เมื่อออกจากโหมด Edit ทั้งทาง (เลือกฟีเจอร์อื่น / +สร้างใหม่ / สลับแท็บ), ยกเลิกฟีเจอร์ที่เพิ่งสร้าง = ลบทิ้งไม่ทิ้งรายการเปล่า, confirm ก่อนลบฟีเจอร์, Save ต้องมีชื่อ, กด "Open scene editor" จะ save ก่อนออกจากหน้า, กลับจาก editor ผ่าน `?feature=&slice=&edit=1` ได้สถานะเดิม, เตือนก่อนออกจาก editor ทั้งที่ยังไม่ save, ปิดคีย์ลัด canvas ตอนมี dialog เปิด, clamp หน้าของ pagination หลังกรอง, วัตถุที่ล็อกลบไม่ได้ (ปุ่ม disabled)
  - asset: `Sign.png` → `zyra-app/public/image/roadmap/sign.png` (ลบพื้นขาวเป็น alpha ด้วย flood fill จากขอบ) · object library เหลือ 3 ชิ้นตามที่สั่ง: Ground / Quarter sign / Mystery
  - i18n ครบทั้ง en/th 2 namespace: `AdminRoadmap`, `AdminRoadmapScene`
- **PR:** ยังไม่เปิด — งานอยู่บน `feat/admin-product-updates` (zyra-app) ยังไม่ commit
- **verify ถึงไหน:** `npx tsc --noEmit` ไม่มี error ใหม่ (เหลือ error เดิมใน `__tests__/*` ที่มีอยู่ก่อน), `npx eslint` เขียวทุกไฟล์ใหม่, `npm run build` ผ่าน — build เห็น route `/admin/roadmap` และ `/admin/roadmap/[id]/scene`, prettier format แล้ว · **ยังไม่ได้เขียน unit/E2E test และผู้ใช้เป็นคนกดทดสอบ UI เองในเบราว์เซอร์**
- **ต่อจากนี้ (ยังไม่ทำ):**
  1. spec + technical design: ตาราง roadmap feature + scene object, API `/api/admin/roadmap/*`, อัปโหลด asset ขึ้น S3/R2 ตาม `rules/11-s3-storage.md` (ตอนนี้เป็น `URL.createObjectURL` ในเครื่อง)
  2. ต่อ API จริงแทน mock store `views/admin/roadmap/roadmap-data.ts` (`MOCK_FEATURES`, `upsertFeature`, `removeFeature`, `saveFeatureObjects`)
  3. ฝั่ง member/landing ที่จะ render timeline + scene จากข้อมูลชุดนี้ (ยังไม่เริ่ม)
  4. test-plan + vitest/E2E
- **ติดอะไร:** ยังไม่มี decision เรื่อง schema/endpoint และรูปแบบเก็บ scene (ตอนนี้เก็บตำแหน่งเป็น % ของ stage 16:9) · asset ของ object ยัง placeholder ยกเว้นป้ายไม้
