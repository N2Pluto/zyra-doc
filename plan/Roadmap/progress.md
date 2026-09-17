# Roadmap (admin) — Progress / Handoff

> **สถานะรวม:** UI 2 หน้า + API ครบ (feature CRUD, scene, asset library, public read) ต่อกันแล้ว · **ตารางสร้างบน dev แล้ว** (DDL อยู่ใน `internal/database/postgres.go` จึงขึ้นเองตอน service start ทุก env) · ฝั่ง landing ยังไม่ต่อ
> **อัปเดตล่าสุด:** 2026-09-17 · **คนล่าสุด:** rif (pair กับ Claude Code)

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
