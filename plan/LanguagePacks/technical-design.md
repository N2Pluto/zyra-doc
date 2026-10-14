# Language Packs — แก้คำ / เพิ่มภาษาโดยไม่ต้อง deploy

> **สถานะ:** Planning — ยังไม่ implement · **วันที่:** 2026-10-14 · **ที่มา:** ClickUp B-45 "แยกไฟล์ภาษาเป็น Package ให้ดาวน์โหลด" · **มติ Ten:** เป้าหมาย = แก้คำ / เพิ่มภาษาได้โดยไม่ต้อง deploy zyra-app · **repo ที่กระทบ:** zyra-api, zyra-app (+ R2)

## 1. ตอนนี้เป็นยังไง

- ข้อความทั้งหมดอยู่ใน repo: `zyra-app/messages/en.json` (~257 KB) และ `messages/th.json` (~436 KB)
- `i18n/request.ts` โหลดไฟล์ตาม cookie `zyra_locale` ตอน server render → `NextIntlClientProvider` ใน `app/layout.tsx` ส่งลงหน้า (ตัด namespace admin ออกสำหรับหน้าที่ไม่ใช่ admin — `i18n/messages-scope.ts`)
- ภาษาที่มี fix ไว้ใน `i18n/config.ts` (`locales = ["en", "th"]`)
- **แก้คำหนึ่งคำ = PR + review + merge + deploy zyra-app** (~10–20 นาทีถึง dev, ต้องผ่าน develop → main → tag ถึง prod)
- แอปมือถือเป็น remote URL — ไม่มีไฟล์ภาษาในเครื่อง ไม่ต้องดาวน์โหลดแยก

## 2. เป้าหมาย / ไม่ใช่เป้าหมาย

**เป้าหมาย**
1. Admin แก้คำ (en / th) แล้วขึ้นทุก env ภายใน ~1 นาที โดยไม่ deploy zyra-app
2. เพิ่มภาษาใหม่ (เช่น ja, zh) ได้โดยไม่แก้โค้ด — ภาษาที่แปลไม่ครบ fallback เป็นอังกฤษทีละคำ
3. ย้อนกลับเวอร์ชันได้ถ้าแก้ผิด

**ไม่ใช่เป้าหมาย (รอบนี้)**
- ใช้งาน offline (ต้องเปลี่ยนแอปให้มีหน้าเว็บในตัว — งานแยก)
- เก็บไฟล์ภาษาในเครื่องมือถือ (server render ข้อความอยู่แล้ว ไม่ได้ประโยชน์)
- ระบบแปลอัตโนมัติ / workflow อนุมัติหลายขั้น

## 3. ออกแบบ

```
Admin (zyra-app /admin/settings/languages)
   │ upload / edit JSON
   ▼
zyra-api  POST /api/admin/i18n/{locale}      ──► R2: i18n/{locale}/{version}.json  (immutable)
          GET  /api/i18n/manifest  (public)  ──► tb_i18n_pack (active version ต่อภาษา)
   ▲
   │ fetch manifest (cache 60s) + pack (cache ถาวร — URL มี version)
zyra-app server  i18n/request.ts
   └─ merge: ไฟล์ใน repo (fallback) ← pack จาก R2 (ทับเฉพาะ key ที่มี)
```

### 3.1 R2 (rule 11)
- `i18n/{locale}/{version}.json` — เนื้อหา namespace ทั้งหมดของภาษานั้น · version = timestamp + hash สั้น · **ไม่เขียนทับไฟล์เดิม** (URL เปลี่ยนทุกเวอร์ชัน → cache ถาวรได้)
- ไม่มีไฟล์ manifest บน R2 — manifest มาจาก DB ผ่าน API (ย้อนกลับ = เปลี่ยน active row)

### 3.2 zyra-api
**DB (migration)**
```sql
CREATE TABLE tb_i18n_pack (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  locale      VARCHAR(10)  NOT NULL,          -- en, th, ja …
  name        VARCHAR(50)  NOT NULL,          -- ชื่อภาษาที่แสดงใน switcher (เช่น "日本語")
  version     VARCHAR(40)  NOT NULL,
  url         TEXT         NOT NULL,          -- public R2 URL
  key_count   INT          NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT false,
  created_by  VARCHAR(36)  NOT NULL REFERENCES tb_user(id),
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_i18n_pack_active ON tb_i18n_pack(locale) WHERE is_active;
```
`.down.sql` คู่กัน (rule 06)

**Endpoints**
| Method | Path | Guard | ทำอะไร |
|---|---|---|---|
| GET | `/api/i18n/manifest` | public | `{ locales: [{ locale, name, version, url }] }` เฉพาะ active · `Cache-Control: max-age=60` |
| GET | `/api/admin/i18n` | AdminGuard | ทุกเวอร์ชันของทุกภาษา (ดูประวัติ) |
| POST | `/api/admin/i18n/{locale}` | AdminGuard | อัปโหลด JSON (multipart) → validate → R2 → row ใหม่ (ยังไม่ active) |
| POST | `/api/admin/i18n/{locale}/{id}/activate` | AdminGuard | ตั้งเป็น active (ใน transaction: ปิดตัวเก่า เปิดตัวใหม่) — ใช้ทั้งเผยแพร่และย้อนกลับ |

**Validate ตอนอัปโหลด**
- JSON object ซ้อนได้ไม่เกิน 4 ชั้น · ค่าเป็น string เท่านั้น · ขนาด ≤ 1 MB
- key ต้องมีใน base `en` (กันพิมพ์ชื่อ key ผิดแล้วไม่ถูกใช้) — key ที่ขาดได้ (fallback)
- placeholder `{name}` / ICU plural ต้องตรงกับ `en` ของ key เดียวกัน (กันข้อความพังตอน render)
- ไม่ยอมรับ HTML tag นอกเหนือจาก tag ที่ `en` ใช้ใน rich text ของ key นั้น

### 3.3 zyra-app
- `i18n/request.ts`: `messages = deepMerge(bundled[locale] ?? bundled.en, await remotePack(locale))`
  - `remotePack`: `fetch(manifestUrl, { next: { revalidate: 60 } })` → หา locale → `fetch(pack.url, { cache: "force-cache" })` (URL มี version จึง cache ถาวรได้)
  - API ล่ม / timeout 1.5 วิ / JSON เสีย → ใช้ไฟล์ใน repo อย่างเดียว (หน้าไม่พัง) + log ไป Sentry
  - ภาษาที่ไม่มีไฟล์ใน repo (เช่น ja) → `deepMerge(bundled.en, pack.ja)` = แปลไม่ครบ fallback อังกฤษทีละคำ
- `i18n/config.ts`: locale ที่รองรับ = ไฟล์ใน repo ∪ manifest · `isLocale` เช็คกับรายการนี้ (cookie ภาษาที่ถูกลบไปแล้ว → defaultLocale)
- ตัวเลือกภาษา (Lite / Spatial / web settings): อ่านรายการจาก manifest แทน hardcode
- ฟอนต์: ภาษาที่ไม่ใช่ละติน / ไทย ต้องเพิ่มฟอนต์ใน `app/layout.tsx` — **ต้อง deploy ครั้งเดียวต่อระบบตัวอักษรใหม่** (เช่น ญี่ปุ่น / จีน)
- หน้า admin `/admin/settings/languages` (AdminSidebar, Tailwind, Figma ต้องมีก่อน — rule 10): รายการภาษา + เวอร์ชัน · ดาวน์โหลด JSON ปัจจุบัน · อัปโหลดไฟล์ใหม่ (แสดงผล validate) · เผยแพร่ · ย้อนกลับ

### 3.4 Cache / ความเร็วที่เห็นการแก้
- หลังกดเผยแพร่: server ของ zyra-app เห็นภายใน ≤ 60 วิ (revalidate) · ผู้ใช้เห็นตอนโหลดหน้าใหม่ / เปลี่ยนหน้า (ไม่ refresh หน้าที่เปิดค้างอยู่)
- R2 pack เป็น immutable → ไม่มีปัญหา cache ค้างของ CDN

## 4. แบ่งงาน (แต่ละอัน = 1 PR)

| # | งาน | repo | ขึ้นกับ |
|---|---|---|---|
| 1 | migration `tb_i18n_pack` (+ down) | zyra-api | — |
| 2 | service + handler: upload / validate / activate / manifest + unit test (table-driven, mock DB) | zyra-api | 1 |
| 3 | seed: อัปโหลด en / th ปัจจุบันเป็นเวอร์ชันแรก (script) | zyra-api / ops | 2 |
| 4 | `i18n/request.ts` โหลด + merge + fallback · `config.ts` locale แบบ dynamic + test | zyra-app | 2 |
| 5 | ตัวเลือกภาษาอ่านจาก manifest (Lite / Spatial / web) + test | zyra-app | 4 |
| 6 | หน้า admin Languages (ต้องมี Figma) + test | zyra-app | 2, Figma |
| 7 | เอกสาร guides/ วิธีแก้คำ + runbook ย้อนกลับ | zyra-doc | 6 |

ประมาณ 4–6 วันทำงาน (ไม่รวมรอ Figma ของข้อ 6) · ข้อ 1–5 ทำได้ก่อน — แก้คำผ่าน API (curl / script) ได้ตั้งแต่ข้อ 3

## 5. ความเสี่ยง

| ความเสี่ยง | กันยังไง |
|---|---|
| แก้ placeholder ผิด → หน้าพัง | validate placeholder / ICU ตอนอัปโหลด + fallback ไฟล์ใน repo ถ้า parse ไม่ได้ |
| API ล่ม → ข้อความหาย | merge กับไฟล์ใน repo เสมอ · timeout 1.5 วิ |
| คนแก้ใน repo กับคนแก้บน R2 ชนกัน | key ใหม่ต้องเพิ่มใน repo (PR) เหมือนเดิม · R2 ใช้แก้คำของ key ที่มีอยู่ — เขียนเป็นกติกาใน guides/ |
| ภาษาใหม่ไม่มีฟอนต์ | deploy ฟอนต์ครั้งเดียวต่อระบบตัวอักษร (ระบุใน runbook) |
| ขนาดหน้าเพิ่ม (merge ทั้งก้อน) | ไม่เพิ่ม — ยังส่งเฉพาะภาษาที่เลือก และตัด namespace admin เหมือนเดิม |

## 6. Before / After (rule 18)

| Metric | Before | After (เป้า) |
|---|---|---|
| เวลาตั้งแต่แก้คำจนขึ้น dev | PR + CI + deploy (~10–20 นาที วัดจาก GitHub Actions ของ zyra-app) | ≤ 1 นาที หลังกดเผยแพร่ |
| เพิ่มภาษาใหม่ | แก้โค้ด + deploy ทุก env | อัปโหลด pack + (ฟอนต์ครั้งเดียวถ้าตัวอักษรใหม่) |

**ยังไม่ได้วัด** — วัดเวลา deploy จริงจาก GitHub Actions ก่อนเริ่มงาน

## 7. คำถามที่ต้องตอบก่อนเริ่ม

1. ใครแก้คำได้ — Admin ของระบบเท่านั้น หรือมี role "translator" แยก?
2. ต้องมีขั้น preview / อนุมัติก่อนเผยแพร่ไหม หรือกดแล้วขึ้นเลย (ย้อนกลับได้)?
3. แก้ทีเดียวใช้ทุก env (dev / uat / prod) หรือแยกต่อ env? (เสนอ: แยกต่อ env — แต่ละ env มี DB / R2 prefix ของตัวเอง)
4. ภาษาใหม่ที่จะเพิ่มก่อน (ถ้ามี) — เพื่อเตรียมฟอนต์
5. หน้า admin Languages — มี Figma ไหม หรือใช้ layout หน้า admin settings ที่มีอยู่?
