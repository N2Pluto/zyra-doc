# SC-AV-01 · Test Plan — Accessory Management (Admin)

> **สถานะ:** Draft v1.0 · 2026-10-21 · ยังไม่มีโค้ด (zyra-app#636 ปิดไปแล้ว) — ชื่อ function / endpoint ตรงกับ [technical-design.md](technical-design.md) แล้ว (2026-10-21) · **repo:** zyra-api, zyra-app, zyra-ws
> **อ้างอิง:** [spec.md](spec.md) (scenario จาก ClickUp) · [requirements.md](requirements.md) (AV-*) · [ux-ui-plan.md](ux-ui-plan.md) (ค่า Figma + สิ่งที่ POC ตกลง) · POC [poc/accessory-admin-poc.html](poc/accessory-admin-poc.html)
> **กฎที่ยึด:** [04-test.md](../../../.claude/rules/04-test.md) (testify table-driven, mock DB, Vitest + `vi.mock`, test ทุก sentinel error) · [05-review.md](../../../.claude/rules/05-review.md)

---

## หลักการออกแบบ test ที่ใช้ในเอกสารนี้

| เทคนิค | ใช้กับ | ทำไม |
|---|---|---|
| **Equivalence partitioning** (แบ่งกลุ่มค่า) | ชนิดไฟล์, สถานะ, หมวด | เทสตัวแทน 1 ค่าต่อกลุ่ม ไม่ต้องเทสทุกค่า |
| **Boundary value analysis** (ค่าขอบ) | ขนาดไฟล์ 2 MB, ความยาวชื่อ 50, จำนวนผู้ใช้ 100, หน้าละ 20, batch 100 | บักส่วนใหญ่อยู่ที่ขอบ (`<` กับ `<=`) — เทส ขอบ−1 / ขอบ / ขอบ+1 เสมอ |
| **Decision table** (ตารางเงื่อนไข) | หมวด × ชีทที่ต้องอัปโหลด, ปุ่ม Save กดได้เมื่อไหร่, modal ลบแบบไหน | เงื่อนไขหลายตัวรวมกัน ต้องครบทุก combination |
| **State transition** (การเปลี่ยนสถานะ) | Active ↔ Hidden → Deleted → Hard-deleted, โหมดหน้า form (add/view/edit) | เทสทั้งทางที่ไปได้ และทางที่ **ต้องไปไม่ได้** |
| **Error guessing** (เดาจุดพัง) | ไฟล์นามสกุล .png แต่ไม่ใช่ PNG, ชื่อมีแต่ช่องว่าง, ลบซ้อนกัน 2 คน | จากบักที่เคยเจอใน avatar-management เดิม |
| **Traceability** (ตามรอยได้) | ทุก test case มี SC / AV-* | ใช้นับกฎ 80% ก่อนปิดการ์ด ClickUp (§9) |

รูปแบบ ID: `AC-<ชั้น>-<เลข>` — ชั้น `U` unit Go · `A` API · `T` unit TS · `C` component · `E` E2E · `M` manual

---

## Coverage Targets

| Layer | ขอบเขต | Target |
|---|---|---|
| Unit Go | `internal/service/avatar_part_service.go` (+ validator) | ≥ 80% |
| Unit TS | `lib/api/avatar-parts.ts`, `lib/avatar-part/*.ts` (validate, shade, chair, render) | ≥ 80% |
| API | ทุก route ใต้ `/api/admin/avatar-parts*` + route member ที่แตะ | 100% endpoint |
| Component | critical paths: category panel, form Save gating, delete modal | ตาม §4 |
| E2E | 6 scenario happy + error path | ตาม §5 |

---

## 0. สิ่งที่ห้ามล็อกค่าใน test จนกว่าจะตอบ

ใช้ constant ตัวเดียว (Go ↔ TS ค่าเดียวกัน — เทส parity ใน §3.2) ห้าม hardcode ตัวเลขกระจายในเทส

| ค่า | ค่าตอนนี้ | ขัดกันที่ | รอ |
|---|---|---|---|
| `ACCESSORY_MAX_BYTES` | 2 MB (Figma alert + EP-01 accessory) | ClickUp skin = 5 MB | ใช้ 2 MB ไปก่อน · PM |
| ขนาดชีท | 192 × 192 (4 × 4 เฟรม 48 px — ไฟล์จริง 72 ไฟล์) | ClickUp HP-02 = เฟรม 64 px | requirements Q13 |
| พื้นไม่โปร่งใส | Figma = toast **error** (บล็อก) | EP-01 = warning เหลือง **ไม่บล็อก** | ux-ui-plan U3 |
| สถานะเริ่มต้นตอนสร้าง | Figma = toggle Active | ClickUp = Hidden | PM |
| หมวดที่ต้องมี Sitting | Top, Outer, Dress, Bottoms, Special Costume (sticky) | ไฟล์จริงของ Hair / Facial Hair มีชีทนั่ง | ux-ui-plan U5 |
| ชื่อซ้ำนับยังไง | ซ้ำ **ในหมวดเดียวกัน** (HP-03 `ACCESSORY_NAME_EXISTS`) · ไม่สนตัวพิมพ์เล็กใหญ่? | ยังไม่ระบุ | PM |
| จำนวนหมวด | 18 (Figma) | data contract ฝั่ง user 11 slot | ux-ui-plan U4 |

---

## 1. Unit Tests — Go (`zyra-api`)

Framework `testify/assert` + `require` · DB mock ผ่าน interface · S3 mock ผ่าน interface (ไม่ต่อ R2 จริง)

### 1.1 Validator ไฟล์ — `ValidateAccessorySheet(data []byte)` (table-driven)

| ID | กลุ่ม / ค่าขอบ | Input | Expected |
|---|---|---|---|
| AC-U-01 | PNG ถูกต้อง | PNG 192×192 RGBA โปร่งใส 1.5 MB | `nil` |
| AC-U-02 | ไม่ใช่ PNG | JPEG | `ErrInvalidFileType` |
| AC-U-03 | ปลอมนามสกุล (error guessing) | ไฟล์ชื่อ `.png` แต่ header เป็น GIF | `ErrInvalidFileType` (ตรวจ magic bytes `89 50 4E 47 0D 0A 1A 0A`) |
| AC-U-04 | ไฟล์ว่าง | 0 byte | `ErrInvalidFileType` |
| AC-U-05 | ขอบขนาด −1 | 2,097,151 byte | `nil` |
| AC-U-06 | ขอบขนาด | 2,097,152 byte (= 2 MB) | `nil` |
| AC-U-07 | ขอบขนาด +1 | 2,097,153 byte | `ErrFileTooLarge` |
| AC-U-08 | มิติถูก | 192 × 192 | `nil` |
| AC-U-09 | มิติผิด | 193 × 192 · 192 × 191 · 1000 × 1000 | `ErrInvalidDimensions` |
| AC-U-10 | ไม่มี alpha channel | PNG RGB (ไม่มีช่อง alpha) | ตาม §0 แถว "พื้นไม่โปร่งใส" — `ErrNotTransparent` หรือ warning |
| AC-U-11 | alpha ครึ่ง ๆ | มี pixel alpha 1–254 | warning (`SemiTransparentPixels > 0`) ไม่ error |
| AC-U-12 | PNG เสีย | header ถูก แต่ chunk พัง | `ErrInvalidFileType` ไม่ panic |

### 1.2 Validator ข้อมูล — `ValidateAccessoryInput` (table-driven)

| ID | เทคนิค | Input | Expected |
|---|---|---|---|
| AC-U-13 | BVA ชื่อ | ยาว 0 | `ErrNameRequired` |
| AC-U-14 | BVA ชื่อ | ยาว 1 | `nil` |
| AC-U-15 | BVA ชื่อ | ยาว 50 | `nil` |
| AC-U-16 | BVA ชื่อ | ยาว 51 | `ErrNameTooLong` |
| AC-U-17 | error guessing | ช่องว่างล้วน `"   "` | `ErrNameRequired` (trim ก่อนนับ) |
| AC-U-18 | error guessing | ชื่อไทย 50 ตัวอักษร (UTF-8 > 50 byte) | `nil` — นับเป็น **rune** ไม่ใช่ byte |
| AC-U-19 | EP หมวด | หมวดใน 18 ตัว | `nil` |
| AC-U-20 | EP หมวด | หมวดที่ไม่มี (`"wings"`) | `ErrInvalidCategory` |
| AC-U-21 | Expiration | Special + Set expiration + start < end | `nil` |
| AC-U-22 | BVA วันที่ | start = end | ตัดสินที่ PM — default `nil` (วันเดียว) |
| AC-U-23 | Expiration | start > end | `ErrInvalidDateRange` |
| AC-U-24 | Expiration | หมวดอื่นแต่ส่งวันที่มา | ไม่สนวันที่ หรือ `ErrExpirationNotAllowed` — ตามที่ตกลง |
| AC-U-25 | Variant (Special) | 0 variant | `ErrVariantRequired` |
| AC-U-26 | Variant (Special) | variant ไม่มีชื่อสี | `ErrVariantNameRequired` |
| AC-U-27 | Variant (Special) | ชื่อสีซ้ำในชิ้นเดียวกัน | `ErrVariantDuplicate` |

### 1.3 Decision table — ชีทที่ต้องมีตามหมวด

| หมวด | Walking | Sitting | ผล |
|---|---|---|---|
| Top / Outer / Dress / Bottoms | ✓ | ✓ | ผ่าน |
| Top / Outer / Dress / Bottoms | ✓ | ✗ | `ErrMissingSheet{sit}` |
| Top / Outer / Dress / Bottoms | ✗ | ✓ | `ErrMissingSheet{walk}` |
| Special Costume (ทุก variant) | ✓ | ✓ | ผ่าน |
| Special Costume — variant ใดขาดชีท | ✓ | ✗ | `ErrMissingSheet{variant, sit}` |
| หมวดอื่น (Hair, Eyes, Hat …) | ✓ | — | ผ่าน |
| หมวดอื่น | ✓ | ✓ (ส่งมาเกิน) | ผ่าน · เก็บหรือทิ้ง sitting ตาม U5 |
| ทุกหมวด | ✗ | ✗ | `ErrMissingSheet{walk}` |

→ เขียนเป็น test เดียวแบบ table-driven `TestRequiredSheets` (AC-U-28)

### 1.4 `AvatarPartService` — CRUD (mock DB + mock S3)

| ID | Test | Expected |
|---|---|---|
| AC-U-29 | `Create_Success` | อัปโหลด S3 key `static/avatar-part/{part_id}/…` · บันทึก URL ไม่ใช่ path local ([11-s3-storage.md](../../../.claude/rules/11-s3-storage.md)) · สถานะเริ่มต้นตาม §0 |
| AC-U-30 | `Create_DuplicateNameSameCategory` | `ErrNameExists` · ไม่อัปโหลด S3 |
| AC-U-31 | `Create_SameNameOtherCategory` | ผ่าน (ซ้ำได้ข้ามหมวด) |
| AC-U-32 | `Create_S3Nil` | `ErrStorageNotConfigured` |
| AC-U-33 | `Create_S3Fails_RollsBack` | ไม่มี row ค้างใน DB (`defer tx.Rollback`) |
| AC-U-34 | `Update_ReplaceSheet` | ลบ object S3 เก่า · thumbnail ใหม่ · audit log 1 แถว |
| AC-U-35 | `Update_NotFound` | `ErrAccessoryNotFound` |
| AC-U-36 | `Update_RenameToExisting` | `ErrNameExists` |
| AC-U-37 | `List_Pagination` | BVA ทั้งหมด 0 / 1 / 20 / 21 / 40 / 41 รายการ → จำนวนหน้า 0(หรือ 1) / 1 / 1 / 2 / 2 / 3 |
| AC-U-38 | `List_FilterStatus` | All / Active / Hidden / Deleted คืนเฉพาะกลุ่มนั้น · All **ไม่รวม** Deleted |
| AC-U-39 | `List_Search` | ค้นชื่อไม่สนตัวพิมพ์ · ค้นว่าง = ทั้งหมด · SQL ใช้ `$1` ไม่ต่อ string |
| AC-U-40 | `CountByCategory` | 18 หมวด คืน 0 ให้หมวดว่าง (ไม่หายจาก map) |

### 1.5 State transition — สถานะของชิ้น

```
          ┌──── hide ────┐
  (create)│              ▼
  ───────► Active      Hidden ──── delete ───► Deleted ──(cron 30 วัน)──► Hard-deleted
            ▲  └── unhide ┘  │                    │
            └──── delete ────┼────────────────────┘
                             (Deleted ห้ามกลับ Active / Hidden)
```

| ID | จาก → ไป | Expected |
|---|---|---|
| AC-U-41 | Active → Hidden | ผ่าน · ผู้ใช้ที่ใส่อยู่ **ยังใส่ต่อ** (ไม่แตะ `tb_user_*`) |
| AC-U-42 | Hidden → Active | ผ่าน |
| AC-U-43 | Active → Deleted | ผ่าน · `deleted_at` ถูกตั้ง · ผู้ใช้ที่ใส่อยู่ถูก reset slot นั้น |
| AC-U-44 | Hidden → Deleted | ผ่าน |
| AC-U-45 | Deleted → Active / Hidden | `ErrAccessoryDeleted` (ทางที่ต้องไปไม่ได้) |
| AC-U-46 | Deleted → Deleted (ลบซ้ำ) | idempotent หรือ `ErrAccessoryNotFound` — ห้าม reset ผู้ใช้ซ้ำ |
| AC-U-47 | cron: deleted_at 29 วัน 23 ชม. | ยังไม่ลบไฟล์ S3 (BVA) |
| AC-U-48 | cron: deleted_at 30 วันพอดี / 30 วัน + 1 นาที | ลบไฟล์ S3 + row |
| AC-U-49 | cron: S3 ลบไม่ได้ | log error แล้วไปชิ้นถัดไป ไม่หยุดทั้ง job |

### 1.6 Delete + reset ผู้ใช้ (SC HP-06, EC-02)

| ID | จำนวนผู้ใช้ (BVA) | Expected |
|---|---|---|
| AC-U-50 | 0 | ลบทันที · ไม่สร้าง job |
| AC-U-51 | 1 | reset 1 คน · 1 batch |
| AC-U-52 | 100 | 1 batch |
| AC-U-53 | 101 | 2 batch (100 + 1) |
| AC-U-54 | 892 (ตัวอย่างใน EC-02) | 9 batch · progress 0 → 892 ไม่ข้าม ไม่เกิน |
| AC-U-55 | job ตายกลางทาง | ทำต่อจาก batch ที่ค้างได้ (ไม่ reset ซ้ำคนที่เสร็จแล้ว) |
| AC-U-56 | audit log | มี `admin_id`, `item_id`, `affected_user_count` ครบ |
| AC-U-57 | ไม่ log PII | log ไม่มี email ผู้ใช้ ([07-monitor.md](../../../.claude/rules/07-monitor.md)) |

### 1.7 Sentinel errors — ต้องมีเทสครบทุกตัว

`ErrInvalidFileType` · `ErrFileTooLarge` · `ErrInvalidDimensions` · `ErrNotTransparent` (ถ้า U3 = error) · `ErrNameRequired` · `ErrNameTooLong` · `ErrNameExists` · `ErrInvalidCategory` · `ErrInvalidDateRange` · `ErrVariantRequired` · `ErrVariantNameRequired` · `ErrVariantDuplicate` · `ErrMissingSheet` · `ErrAccessoryNotFound` · `ErrAccessoryDeleted` · `ErrStorageNotConfigured`

ทุกตัวต้องมีเทสทั้ง **service คืน error ถูกตัว** (`errors.Is`) และ **handler map เป็น HTTP + code ถูก** (§2)

### 1.8 `zyra-ws` — broadcast เมื่อชุดผู้ใช้ถูก reset

| ID | Test | Expected |
|---|---|---|
| AC-U-58 | ผู้ใช้ online ใน workspace | ได้ event เปลี่ยน avatar 1 ครั้ง · คนอื่นในห้องเห็น URL ใหม่ |
| AC-U-59 | ผู้ใช้ offline | ไม่มี event · เข้า VO ครั้งหน้าได้ชุดที่ reset แล้ว (อ่านจาก DB) |
| AC-U-60 | ผู้ใช้อยู่หลาย workspace | ได้ event ทุก workspace ที่อยู่ |

---

## 2. API / Handler Tests (`zyra-api`)

ใช้ `httptest` + service mock · ตรวจ envelope `model.APIResponse` ทุก response

| ID | Endpoint (เสนอ) | Case | Expected |
|---|---|---|---|
| AC-A-01 | ทุก route `/api/admin/avatar-parts*` | ไม่มี token | 401 |
| AC-A-02 | ทุก route `/api/admin/avatar-parts*` | token ของ MEMBER | 403 (AdminGuard) |
| AC-A-03 | `GET /api/admin/avatar-parts?category=&status=&search=&page=&limit=` | ปกติ | 200 · `data.items` + `total` |
| AC-A-04 | `GET …?limit=0` / `limit=1000` | ค่าขอบ | clamp เป็น 1 / 100 หรือ 400 — ตามที่กำหนด |
| AC-A-05 | `GET /api/admin/avatar-parts/category-counts` | ปกติ | 200 · ครบ 18 key |
| AC-A-06 | `POST /api/admin/avatar-parts` (multipart) | ไฟล์ไม่ใช่ PNG | 400 `INVALID_FILE_TYPE` |
| AC-A-07 | 〃 | > 2 MB | 400 `FILE_TOO_LARGE` |
| AC-A-08 | 〃 | มิติผิด | 400 `INVALID_DIMENSIONS` |
| AC-A-09 | 〃 | ขาดชีท | 400 `MISSING_DIRECTION` / `MISSING_SHEET` |
| AC-A-10 | 〃 | ชื่อซ้ำในหมวด | 409 `ACCESSORY_NAME_EXISTS` |
| AC-A-11 | `PATCH /api/admin/avatar-parts/{id}` | เปลี่ยน status | 200 · status ใหม่ |
| AC-A-12 | `PATCH …/{id}` ของชิ้นที่ Deleted | — | 409 / 410 |
| AC-A-13 | `GET /api/admin/avatar-parts/{id}/usage` | — | 200 · `user_count` ตรง DB (ห้ามเป็น 0 ตายตัว — บักเดิม [AvatarManagement/SC-AV-01-user-count-fix.md](../AvatarManagement/SC-AV-01-user-count-fix.md)) |
| AC-A-14 | `DELETE /api/admin/avatar-parts/{id}` | ผู้ใช้ > 100 ไม่ส่งชื่อยืนยัน | 400 `CONFIRM_NAME_REQUIRED` |
| AC-A-15 | 〃 | ส่งชื่อยืนยันไม่ตรง | 400 `CONFIRM_NAME_MISMATCH` |
| AC-A-16 | 〃 | ตรง | 202 · `job_id` (ไม่บล็อก) |
| AC-A-17 | `GET /api/admin/avatar-parts/reset-jobs/{job_id}` | กำลังทำ | 200 · `done` / `total` |
| AC-A-18 | ฝั่ง member `/api/user/*` ที่คืน catalog | ชิ้น Hidden / Deleted | **ไม่อยู่ในผลลัพธ์** ([15-member-api-separation.md](../../../.claude/rules/15-member-api-separation.md)) |

---

## 3. Unit Tests — TypeScript (`zyra-app`, Vitest)

ห้าม call `/api/*` จริง — `vi.mock("@/lib/api/client")` เสมอ

### 3.1 `lib/api/avatar-parts.ts`

| ID | Test |
|---|---|
| AC-T-01 | แต่ละ function เรียก path `/api/admin/avatar-parts…` ถูก method / query (happy path) |
| AC-T-02 | status ≠ 200 → คืน error code ให้ UI map เป็น toast ถูกตัว (error path) |
| AC-T-03 | upload ใช้ `FormData` ตาม pattern [02-design.md](../../../.claude/rules/02-design.md) |

### 3.2 Constant parity Go ↔ TS

AC-T-04 — `ACCESSORY_MAX_BYTES`, ขนาดชีท, ความยาวชื่อ, รายชื่อ 18 หมวด, หมวดที่ต้องมี Sitting ต้องตรงกันทั้งสองฝั่ง (อ่านค่าจาก fixture JSON ร่วม หรือเทสเทียบ snapshot)

### 3.3 Client-side validation `validateAccessoryFile(file)` (ทำงานทันทีที่เลือกไฟล์ — EP-01)

| ID | Input | Expected |
|---|---|---|
| AC-T-05 | `image/png` 1 MB 192×192 | ok |
| AC-T-06 | `image/jpeg` | `INVALID_FILE_TYPE` → toast "Only PNG files are supported." |
| AC-T-07 | 2,097,152 / 2,097,153 byte | ok / `FILE_TOO_LARGE` |
| AC-T-08 | 191×192 | `INVALID_DIMENSIONS` |
| AC-T-09 | เลือกไฟล์ผิดแล้วเลือกไฟล์ถูก | error หายไป (EP-01 AC) |

### 3.4 Save gating `canSave(form)` — decision table

| มีชื่อ | ชื่อซ้ำ | ชีทครบตามหมวด | วันที่ถูก (ถ้า Set expiration) | Save |
|---|---|---|---|---|
| ✗ | — | — | — | disabled |
| ✓ | ✓ | ✓ | ✓ | disabled + inline error |
| ✓ | ✗ | ✗ | ✓ | disabled |
| ✓ | ✗ | ✓ | ✗ | disabled |
| ✓ | ✗ | ✓ | ✓ | **enabled** |

AC-T-10 — table-driven ครบ 5 แถว

### 3.5 สีและ preview (pure functions จาก POC)

| ID | Function | Case | Expected |
|---|---|---|---|
| AC-T-11 | `shadeHex(hex, shade)` | shade 50 | คืนสีหลักเดิม |
| AC-T-12 | 〃 | shade 0 | ผสมขาว 85% (เช่น `#FF8000` → `#FFECD9`) |
| AC-T-13 | 〃 | shade 100 | ผสมดำ 75% (`#FF8000` → `#402000`) |
| AC-T-14 | 〃 | shade −1 / 101 | clamp เป็น 0 / 100 ไม่คืนค่าเกิน `#FFFFFF` / ต่ำกว่า `#000000` |
| AC-T-15 | `paletteFor(colour, category)` | Eyes / Hair / Facial Hair / Top | ลงช่อง eye / hair / hair / primary+secondary ตามลำดับ · ช่องอื่นคง default |
| AC-T-16 | `classifyKey(r,g,b)` | สี key 5 channel × 4 เฉด | ได้ channel ถูก · `#672924` (outline แดงเข้ม) = `null` |
| AC-T-17 | `chairOffsets(composition, dir)` | Office Chair ทิศ south | piece อยู่ที่ (10, 11) ในเฟรม 48 · เท้าที่ sit point + 5 |
| AC-T-18 | 〃 | piece `above_character` | ถูกวาด **หลัง** ตัวละคร |
| AC-T-19 | `pickFrame(mode, tick)` | idle / walking / sitting | walk col 1 / วน 0–3 / sit col 2 |

---

## 4. Component Tests (critical paths only)

| ID | Component | Test |
|---|---|---|
| AC-C-01 | `AccessoryCategoryPanel` | render 18 แถว 3 กลุ่ม · กดแล้ว `onSelect(id)` · แถว active มี `aria-pressed=true` |
| AC-C-02 | 〃 | ค้นหา "ha" → เหลือ Hair / Facial Hair / Hat · กลุ่มที่ว่างถูกซ่อน |
| AC-C-03 | 〃 | กดหัวกลุ่มพับ/กาง · `aria-expanded` เปลี่ยน |
| AC-C-04 | Form | Special Costume → แสดงตาราง variant + radio expiration · Hair → dropzone Walking อย่างเดียว · Top → Walking + Sitting |
| AC-C-05 | Form | Save disabled ↔ enabled ตาม §3.4 |
| AC-C-06 | Delete modal | ผู้ใช้ 0 / 1–100 / > 100 → แบบ 1 / 2 / 3 · แบบ 3 ปุ่ม Delete เปิดเมื่อพิมพ์ชื่อตรงทุกตัวอักษร (ช่องว่างหน้า-หลังไม่นับ) |
| AC-C-07 | Shade slider | เลื่อนแล้ว hex + จุดสีเปลี่ยน · เปลี่ยนสีหลักแล้วคงระดับความเข้ม · ใช้คีย์บอร์ด (ลูกศร) ได้ |

---

## 5. E2E (Playwright, `zyra-app/e2e/`)

ใช้บัญชี admin ทดสอบบน **dev** (`app.dev.zyra.center`) · ข้อมูลทดสอบสร้างและลบเองในเทส · ใช้ไฟล์จริงจาก `demo file/custom avatar` เป็น fixture

| ID | Scenario | ขั้นตอนสรุป | ผ่านเมื่อ |
|---|---|---|---|
| AC-E-01 | HP-01 | เปิด `/admin/accessory-management` → เลือก Special Costume | เห็น card, จำนวน, pagination |
| AC-E-02 | HP-03 Special | Add → ชื่อ → Set expiration → 2 variant → upload 4 ไฟล์ → Save | toast สำเร็จ · card ใหม่ขึ้นหัว list · จุดสี 2 สี |
| AC-E-03 | HP-03 Other | Hair → upload Walking → เลือกสีหลัก + Shade → Save | preview เปลี่ยนสี · Save สำเร็จ |
| AC-E-04 | HP-04 | เปิด card → Edit → เปลี่ยนชื่อ + replace sheet → Save | ชื่อใหม่ใน list · thumbnail ใหม่ |
| AC-E-05 | HP-05 | toggle Hidden → Save → login เป็น member | card ขึ้น tag Hidden · ชิ้นไม่อยู่ใน picker ของ member |
| AC-E-06 | HP-06 | ลบชิ้นที่ไม่มีคนใช้ | หายจาก list · filter Deleted เห็น |
| AC-E-07 | EC-02 | ชิ้นที่มีผู้ใช้ > 100 (seed) → ลบ → พิมพ์ชื่อ | progress เดินจนครบ · ผู้ใช้ถูก reset |
| AC-E-08 | EP-01 | upload JPEG / 3 MB / ชื่อซ้ำ | toast + inline error ตรงข้อความ Figma |
| AC-E-09 | Sitting preview | tab Sitting ทั้ง 4 ทิศ | เก้าอี้ขึ้นใต้ตัวละคร · ทิศขึ้นพนักพิงบังหลัง |

---

## 6. Regression — ของเดิมต้องไม่พัง

| ID | ส่วน | ตรวจ |
|---|---|---|
| AC-R-01 | `AdminSidebar` | เมนูเดิมครบ ลำดับถูก · เมนูใหม่อยู่ระหว่าง Pet กับ Map · ทุกเมนู active ถูกหน้า |
| AC-R-02 | Avatar management เดิม | list / add / delete ยังทำงาน (จนกว่าจะตัดสินใจแทนที่) |
| AC-R-03 | i18n | `__tests__/i18n-namespace-split.test.ts` ผ่าน · `AdminAccessoryManagement` อยู่ใน admin-only list · ไม่มี key หายใน th |
| AC-R-04 | Member VO | ตัวละครใน VO แสดงปกติหลัง admin ซ่อน/ลบชิ้น |
| AC-R-05 | Object management | Office Chair ที่ preview ใช้ยังเป็นของ object เดิม ไม่ถูกแก้ |

---

## 7. Manual QA checklist — ใช้นับกฎ 80% ก่อนเปลี่ยนการ์ดเป็น Completed

> "80%" = ทำ test case ในตารางนี้ผ่านอย่างน้อย 80% ของการ์ดนั้น ไม่ใช่ code coverage ([04-test.md](../../../.claude/rules/04-test.md))

| ID | การ์ด ClickUp | เช็ค |
|---|---|---|
| AC-M-01 | HP-01 | ไม่เลือกหมวด → empty "No category selected" ตรง Figma |
| AC-M-02 | HP-01 | หมวดว่าง → "No accessory added" + ปุ่ม Add accessory |
| AC-M-03 | HP-01 | card: tag, count, รูปตัวละครใส่ชิ้น, ชื่อตัด ellipsis, วันที่ |
| AC-M-04 | HP-01 | 21 ชิ้น → 2 หน้า · หน้า 2 มี 1 ชิ้น |
| AC-M-05 | HP-01 | filter Active / Hidden · ค้นชื่อ · ค้นหมวด |
| AC-M-06 | HP-03 | Special: radio expiration, วันที่, ตาราง variant, colour picker, Save disabled จนครบ |
| AC-M-07 | HP-03 | Hair: dropzone ลากวางได้ · ไฟล์ขึ้น "Completed" · ลบไฟล์ได้ |
| AC-M-08 | HP-03 | Top: ต้องมีทั้ง Walking และ Sitting |
| AC-M-09 | HP-03 | Preview: Idle / Walking / Sitting + หมุน 4 ทิศ · เก้าอี้ในท่านั่ง |
| AC-M-10 | HP-03 | สี: เลือกสีหลัก + เลื่อน Shade · ตา/ผมเปลี่ยนสีได้ |
| AC-M-11 | HP-04 | โหมดดู read-only · Edit → Cancel ไม่บันทึก · Save บันทึก + toast |
| AC-M-12 | HP-05 | Hidden → member ไม่เห็นใน picker ทันที · คนที่ใส่อยู่ยังใส่ต่อ |
| AC-M-13 | HP-06 | modal 3 แบบตามจำนวนผู้ใช้ · ข้อความตรง Figma |
| AC-M-14 | EP-01 | ไม่ใช่ PNG / เกิน 2 MB / ไม่โปร่งใส / ชื่อซ้ำ → ข้อความตรง Figma |
| AC-M-15 | ทุกใบ | เทียบ Figma ที่ 1440 × 1024 (สี, ระยะ, ฟอนต์) ตาม [ux-ui-plan.md](ux-ui-plan.md) |
| AC-M-16 | ทุกใบ | ภาษาไทยครบ ไม่มี key ดิบหลุด |

---

## 8. Entry / Exit criteria

| | เงื่อนไข |
|---|---|
| **เริ่มเทสได้เมื่อ** | technical-design ล็อก endpoint + schema · §0 ตอบอย่างน้อย U3 กับ ขนาดชีท · fixture ไฟล์จริงพร้อม |
| **ปิดเทสได้เมื่อ** | unit + API + TS ผ่าน 100% · coverage ตาม target · E2E happy path ผ่านบน dev · manual ผ่าน ≥ 80% ต่อการ์ด · ไม่มีบัก severity สูงค้าง |
| **ห้ามบอกว่า verified** | ถ้ามีแค่ build เขียว — ต้องมีผล live-test บน dev ระบุใน progress.md ([16-documentation.md](../../../.claude/rules/16-documentation.md)) |

---

## 9. Traceability — Scenario → Test

| Scenario (ClickUp) | Requirement | Unit / API / TS | Component / E2E / Manual |
|---|---|---|---|
| HP-01 List | AV-UI-01~06, AV-API-01~02 | U-37~40, A-03~05, T-01 | C-01~03, E-01, M-01~05 |
| HP-02 Upload Skin *(Closed)* | AV-UP-01~06 | U-01~12 | — |
| HP-03 Upload Accessory | AV-UP-03, 11~17, AV-API-04 | U-01~31, A-06~10, T-05~19 | C-04~05, C-07, E-02~03, E-09, M-06~10 |
| HP-04 Edit | AV-UI-10, AV-API-05 | U-34~36, A-11 | E-04, M-11 |
| HP-05 Hide / Unhide | AV-API-06, AV-RT-01 | U-41~42, A-18 | E-05, M-12 |
| HP-06 Delete | AV-API-07, AV-RT-04 | U-43~49, A-12~16 | C-06, E-06, M-13 |
| EP-01 Upload error | AV-UP-07~09 | U-01~12, A-06~10, T-05~09 | E-08, M-14 |
| EC-02 ลบเมื่อมีผู้ใช้มาก *(Closed)* | AV-API-08, AV-RT-02 | U-50~60, A-14~17 | C-06, E-07 |
