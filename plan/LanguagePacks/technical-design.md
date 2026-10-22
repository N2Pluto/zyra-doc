# Language Packs — แก้คำ / เพิ่มภาษาโดยไม่ต้อง deploy

> **สถานะ:** Planning v2 — ยังไม่ implement · **อัปเดต:** 2026-10-14 (ปรับตามคำตอบ Ten) · **ที่มา:** ClickUp B-45 · **repo ที่กระทบ:** zyra-app (+ R2) — **ไม่ต้องแก้ zyra-api**

## มติ Ten (2026-10-14)

| คำถาม | คำตอบ |
|---|---|
| ใครแก้คำ / เพิ่มภาษา | **dev** เป็นคนเพิ่ม / แก้เอง |
| เผยแพร่ | กดแล้วขึ้นเลย ย้อนกลับได้ |
| แยกต่อ env ไหม | **แก้ทีเดียวขึ้นทุก env** |
| หน้า admin / ภาษาแรก | ไม่ได้ระบุ → ไม่ทำหน้า admin (dev แก้ใน repo) · ยังไม่เพิ่มภาษาใหม่ในรอบนี้ |

## 1. ตอนนี้เป็นยังไง

- ข้อความอยู่ใน `zyra-app/messages/en.json` / `th.json` · `i18n/request.ts` โหลดตอน server render ตาม cookie `zyra_locale`
- ภาษาที่รองรับ fix ไว้ใน `i18n/config.ts` (`locales = ["en", "th"]`, type `Locale` = `"en" | "th"`) — ใช้อยู่ ~19 ไฟล์
- แก้คำหนึ่งคำ = PR + merge + **deploy zyra-app ทุก env** (dev → uat → prod)

## 2. ออกแบบ (v2 — เรียบกว่าเดิม: ไม่มี DB ไม่มีหน้า admin)

```
dev แก้ messages/<locale>.json ใน zyra-app (PR เหมือนเดิม)
   │ merge
   ▼
GitHub Action "Publish language packs" (zyra-app)
   ├─ ตรวจไฟล์ (JSON ถูก · key อยู่ใน en · placeholder ตรงกับ en)
   ├─ อัปโหลด R2: i18n/<locale>/<git sha>.json   (ไม่ทับของเดิม)
   └─ เขียน R2: i18n/manifest.json  { locales: [{ locale, name, url }], sha, published_at }
   ▲
   │ ทุก env อ่าน manifest เดียวกัน (cache 60 วิ) + pack (cache ถาวร — URL มี sha)
zyra-app server (dev / uat / prod)  i18n/request.ts
   └─ messages = ไฟล์ที่ bundle มากับ image (fallback) ← ทับด้วย pack จาก R2
```

- **เผยแพร่ = merge PR** แล้ว Action อัปโหลด → ขึ้นทุก env ภายใน ~1–2 นาที โดยไม่ deploy zyra-app
- **ย้อนกลับ** = รัน Action แบบ manual เลือก commit เก่า (manifest ชี้กลับไปไฟล์เดิมที่ยังอยู่บน R2)
- **ทุก env ใช้ manifest เดียวกัน** ตามมติ — ต้องระวัง: แก้แล้ว prod เห็นทันที (ไม่ผ่าน uat) → Action รันเฉพาะเมื่อ merge เข้า `main` หรือสั่งเอง (ไม่รันจาก develop)
- **key ใหม่** ยังต้องมากับโค้ดที่ใช้มัน (deploy ปกติ) — pack ใช้สำหรับ**แก้คำของ key ที่มีอยู่**และ**เพิ่มภาษา**

### 2.1 R2 (rule 11)
- bucket เดียวกับ asset อื่น (public URL) · prefix `i18n/` · pack immutable · `manifest.json` ตั้ง `Cache-Control: max-age=60`
- **ต้องเพิ่ม GitHub secrets ใน zyra-app** (ตอนนี้ไม่มี): `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_PUBLIC_URL` — ใช้ key ที่สิทธิ์เขียนแค่ prefix `i18n/` ถ้าทำได้
- **ต้องเพิ่ม env runtime** `I18N_MANIFEST_URL` ให้ zyra-app ทุก env (ค่าเดียวกัน)

### 2.2 zyra-app
- `i18n/request.ts`: โหลด manifest (`fetch` + `revalidate: 60`, timeout 1.5 วิ) → หา locale → โหลด pack (`force-cache`) → `deepMerge(bundled[locale] ?? bundled.en, pack)` · ล่ม / ไฟล์เสีย → ใช้ไฟล์ที่ bundle อย่างเดียว + log Sentry
- `i18n/config.ts`: locale ที่รองรับ = ไฟล์ที่ bundle ∪ manifest · เปลี่ยน type `Locale` จาก union fix เป็น `string` ที่ผ่าน `isLocale` (แก้ ~19 ไฟล์ที่อ้าง `Locale` / `localeMeta`) · ชื่อภาษา / ธงมาจาก manifest
- ตัวเลือกภาษา (Lite / Spatial / web settings): อ่านรายการจาก manifest
- ภาษาที่ตัวอักษรไม่ใช่ละติน / ไทย ต้องเพิ่มฟอนต์ใน `app/layout.tsx` — deploy ครั้งเดียวต่อระบบตัวอักษร
- `.github/workflows/publish-language-packs.yml`: trigger `push` main (path `messages/**`) + `workflow_dispatch` (เลือก ref สำหรับย้อนกลับ) · script `scripts/publish-language-packs.mjs` (validate + upload ด้วย S3 API)

## 3. แบ่งงาน

| # | งาน | ขึ้นกับ |
|---|---|---|
| 1 | script validate + upload + workflow (+ test ของ validate) | secrets R2 |
| 2 | `request.ts` โหลด manifest + pack + merge + fallback (+ test) | 1 |
| 3 | `config.ts` locale แบบ dynamic + ไล่แก้ ~19 ไฟล์ + ตัวเลือกภาษาอ่านจาก manifest (+ test) | 2 |
| 4 | guides/ วิธีแก้คำ / เพิ่มภาษา / ย้อนกลับ | 1–3 |

ประมาณ 2–3 วัน · ข้อ 1–2 อย่างเดียวก็แก้คำ en / th ได้โดยไม่ deploy แล้ว · ข้อ 3 จำเป็นเฉพาะตอนเพิ่มภาษาใหม่

## 4. ความเสี่ยง

| ความเสี่ยง | กันยังไง |
|---|---|
| แก้ผิดแล้ว prod เห็นทันที (ทุก env ใช้ร่วม) | Action รันเฉพาะ `main` (ผ่าน review PR แล้ว) · validate placeholder · ย้อนกลับได้ใน 1 นาที |
| R2 / manifest ล่ม | merge กับไฟล์ที่ bundle เสมอ · timeout 1.5 วิ |
| image เก่ายังไม่มี key ใหม่ แต่ pack มี | key เกินไม่มีผล (ไม่มีโค้ดเรียก) |
| pack เก่ากว่า image (ขาด key ใหม่) | merge ทับไฟล์ bundle → key ใหม่ยังมาจากไฟล์ใน image |

## 5. Before / After (rule 18)

| Metric | Before | After (เป้า) |
|---|---|---|
| แก้คำจนขึ้นทุก env | PR + deploy dev → main (uat) → tag (prod) | merge PR เข้า main → ~1–2 นาที |
| เพิ่มภาษา | แก้โค้ด + deploy ทุก env | เพิ่มไฟล์ + merge (+ ฟอนต์ครั้งเดียวถ้าตัวอักษรใหม่) |

**ยังไม่ได้วัด** — วัดเวลา deploy จริงจาก GitHub Actions ก่อนเริ่ม

## 6. ต้องเตรียมก่อนเริ่ม (นอกโค้ด)
1. R2 access key สำหรับ GitHub Action (สิทธิ์เขียน prefix `i18n/`) → ใส่ secrets ใน zyra-app
2. ค่า `I18N_MANIFEST_URL` ใน runtime secret ของ zyra-app ทุก env (ค่าเดียวกัน)
