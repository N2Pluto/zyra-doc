# Roadmap (admin) — Progress / Handoff

> **สถานะรวม:** UI-only เสร็จทั้ง 2 หน้า (`/admin/roadmap`, `/admin/roadmap/[id]/scene`) · ข้อมูลยังเป็น mock ใน client ยังไม่มี API/DB/upload จริง
> **อัปเดตล่าสุด:** 2026-09-17 · **คนล่าสุด:** rif (pair กับ Claude Code)

## 2026-09-17 · rif

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
