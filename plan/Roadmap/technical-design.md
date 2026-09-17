# Roadmap (Zyra Spotlight) — Technical Design

> **สถานะ:** implemented บน `zyra-api@feat/admin-roadmap-api` + `zyra-app@feat/admin-product-updates` · ยังไม่ apply migration บน dev/prod
> **อัปเดตล่าสุด:** 2026-09-17

## 1. ขอบเขต

ไทม์ไลน์ "Zyra Spotlight" บนหน้า landing + หน้าจัดการฝั่ง admin

| ส่วน | ที่อยู่ |
|---|---|
| Admin UI | `zyra-app/views/admin/roadmap` (จัดการฟีเจอร์) · `zyra-app/views/admin/roadmap-scene` (scene editor) |
| API | `zyra-api/internal/{model,service,handler}/roadmap*.go` |
| Migration | `zyra-api/migrations/103_roadmap.sql` (+ `.down.sql`) |

**การตัดสินใจที่ผู้ใช้เคาะ (2026-09-17):** อ่านสาธารณะได้ (landing ไม่ล็อกอิน) · scene object เก็บเป็น **ตารางแยก** ไม่ใช่ JSONB · asset อัปขึ้น **S3 ทันที** และเป็น **คลังกลาง** ใช้ซ้ำข้ามฟีเจอร์

## 2. Database (migration 103)

### `tb_roadmap_feature` — 1 จุดบนไทม์ไลน์
`id` · `name` (≤120) · `summary` · `release_date DATE` · `quarter` (คำนวณฝั่ง service) · `status` (`upcoming|released`) · `is_visible` · `is_teaser` · `thumbnail_url` · soft delete (`is_deleted`, `deleted_at`) · `created_by/updated_by/created_at/updated_at`

index: `(release_date) WHERE NOT is_deleted` · `(is_visible, release_date) WHERE NOT is_deleted` · `(quarter) WHERE NOT is_deleted`

### `tb_roadmap_scene_object` — 1 แถว = 1 วัตถุบน canvas
`feature_id` (FK CASCADE) · `kind` (`ground|decoration|character|board|sign|mystery|custom`) · `name` · `asset_id` (FK SET NULL) · `pos_x/pos_y/width` (**% ของ stage 16:9** 0–100) · `aspect` · `z_index` · `is_locked/is_flipped/is_hidden` · `text` · `color`

index: `(feature_id, z_index)`

### `tb_roadmap_asset` — คลัง asset กลาง
`name` · `kind` (`image|sprite|gif`) · `image_url` (S3) · `sprite_columns/rows/fps` · `frame_width/height` · `frames JSONB` (กรอบเฟรมที่ detect จาก alpha ด้วย `lib/sprite-grid`) · `aspect` · soft delete

**quarter** เป็นช่วง 4 เดือน: `q1` Jan–Apr · `q2` May–Aug · `q3` Sep–Dec (`service.RoadmapQuarterFromDate`) — client ส่งมาแค่ `release_date`

## 2.5 Feature flag (kill switch)

| ที่ | ตัวแปร | ค่า default | ผลเมื่อปิด |
|---|---|---|---|
| zyra-api | `ROADMAP_ENABLED` | **false** | ไม่ลงทะเบียน route เลย ทั้ง `/api/admin/roadmap*` และ `/api/public/roadmap*` → ทุก path ตอบ 404 |
| zyra-app | `NEXT_PUBLIC_ROADMAP` | **false** | เมนู Roadmap หายจาก AdminSidebar · `/admin/roadmap` และ `/admin/roadmap/[id]/scene` เรียก `notFound()` |

เปิดต้องเป็นสตริง `"true"` เท่านั้น (ตัดช่องว่าง/ไม่สนตัวพิมพ์) — แพตเทิร์นเดียวกับ `NEXT_PUBLIC_PET` / `ENVIRONMENT_ENABLED`
`NEXT_PUBLIC_*` ถูก inline ตอน build → เปลี่ยนค่าต้อง rebuild (ผูกเป็น build-arg ใน `Dockerfile` + `deploy-gitops.yml` แล้ว)
ตารางใน DB ยังถูกสร้างตามปกติแม้ flag ปิด (DDL อยู่ใน startup migrations) — ปิดแค่ทางเข้า ไม่ได้ปิด schema

## 3. API contract

Envelope เดียวกับ patch note: `{ status, message, data }` · error: `{ status, message: <CODE>, detail: { code } }`

### Public (`/api/public/roadmap`) — ไม่ต้องล็อกอิน, `middleware.PublicCORS()`
| Method | Path | ตอบ |
|---|---|---|
| GET | `/api/public/roadmap?page&limit&quarter` | เฉพาะ `is_visible` เรียง `release_date` **พร้อม objects ของทุกฟีเจอร์** |
| GET | `/api/public/roadmap/:featureId` | ฟีเจอร์เดียว (404 ถ้าไม่ visible) |

### Admin (`/api/admin/roadmap`) — `AdminGuard`
| Method | Path | Body | ตอบ |
|---|---|---|---|
| GET | `` | — | list (`search`, `status`, `quarter`, `sort=release_date\|name\|status`, `page`, `limit`) |
| POST | `` | `RoadmapFeatureInput` | 201 + feature |
| GET | `/:featureId` | — | feature + objects |
| PUT | `/:featureId` | `RoadmapFeatureInput` | feature |
| DELETE | `/:featureId` | — | soft delete |
| PUT | `/:featureId/scene` | `{ objects: [...] }` | **เขียนทับทั้งฉาก** ลำดับใน array = z-index |
| POST | `/:featureId/thumbnail` | multipart `file` | feature (อัป S3 + ลบไฟล์เก่า) |
| GET | `/assets` | — | คลัง asset |
| POST | `/assets` | multipart `file,name,kind,sprite_*,frame_*,frames,aspect` | 201 + asset |
| PATCH | `/assets/:assetId` | `{ name, sprite_*, frames, aspect }` | แก้ metadata (ไฟล์เดิม) |
| DELETE | `/assets/:assetId` | — | soft delete (ฉากที่ใช้อยู่ยังแสดงได้) |

`RoadmapFeatureInput` = `{ name, summary, release_date (YYYY-MM-DD), status, is_visible, is_teaser, thumbnail_url }` — **ไม่รับ `quarter`** (server คำนวณ)

**Error codes:** `ROADMAP_FEATURE_NOT_FOUND` · `ROADMAP_ASSET_NOT_FOUND` · `NAME_REQUIRED` · `NAME_TOO_LONG` · `SUMMARY_TOO_LONG` · `INVALID_RELEASE_DATE` · `INVALID_STATUS` · `INVALID_SCENE_OBJECT` · `TOO_MANY_SCENE_OBJECTS` (>100) · `INVALID_ASSET_KIND` · `INVALID_SPRITE_LAYOUT` · `INVALID_FILE_TYPE` · `FILE_TOO_LARGE` (>2MB) · `STORAGE_UNAVAILABLE` · `INVALID_PAYLOAD`

**Authorization:** public = ไม่มี auth (เห็นเฉพาะ visible) · admin = `AdminGuard` ระดับเดียวกับ patch note/avatar (rule 15: member ห้ามเรียก `/api/admin/*`)

## 4. S3

| ไฟล์ | key |
|---|---|
| asset ในคลัง | `static/roadmap/asset/<uuid>.<png\|jpg\|gif>` |
| thumbnail ฟีเจอร์ | `static/roadmap/feature/<featureId>/thumbnail_<uuid>.<ext>` |

ตรวจชนิดไฟล์จาก **ไบต์จริง** (`http.DetectContentType` + decode config) ไม่ใช่นามสกุล · sprite รับเฉพาะ PNG/WebP · GIF รับเฉพาะ kind `gif` · เพดาน 2MB · อัปทับ thumbnail แล้วลบไฟล์เก่า (พลาดได้ ไม่ทำให้คำขอล้ม)

## 5. Frontend integration

`zyra-app/lib/api/roadmap.ts` — typed client (`authFetch` / `authFetchForm`) + `listPublicRoadmap()` สำหรับ landing
`zyra-app/views/admin/roadmap/roadmap-data.ts` — ชนิดฝั่ง UI + mapper `featureFromDTO` / `sceneObjectFromDTO` / `scenePayloadFromObjects` / `presetFromAsset` (UI ใช้ camelCase, API ใช้ snake_case — แปลงที่ขอบเขตนี้ที่เดียว)

TanStack Query keys: `["admin-roadmap-features"]` · `["admin-roadmap-feature", id]` · `["admin-roadmap-assets"]`

**thumbnail** ต้องมี feature id ก่อนจึงอัปได้ → UI เก็บ `File` ไว้ใน draft แล้วอัปหลัง create/update สำเร็จ

## 6. Rollout

1. apply `103_roadmap.sql` ด้วยมือทั้ง dev และ prod (migration ไม่ auto-run — ดู `rules/06-release.md`)
2. deploy zyra-api (`feat/admin-roadmap-api` → develop)
3. deploy zyra-app (`feat/admin-product-updates` → develop)
4. rollback: `103_roadmap.down.sql` ลบ 3 ตาราง (ข้อมูล roadmap หายทั้งหมด — ยังไม่มีข้อมูล production ตอนนี้)

## 7. ยังไม่ทำ

- ฝั่ง landing (`zyra-landing`) ยังไม่ต่อ `/api/public/roadmap`
- ยังไม่มี handler test / integration test ที่ยิง DB จริง (มีแต่ unit test ของ validation + quarter)
- ยังไม่มีการ reorder ไทม์ไลน์แบบลากสลับ (ลำดับมาจาก `release_date` อย่างเดียว)
