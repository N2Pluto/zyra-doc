# Language packs — แก้คำโดยไม่ต้อง deploy

> **สถานะ:** โค้ดอยู่ใน zyra-app#583 · ใช้งานได้เมื่อตั้ง R2 secrets + `I18N_MANIFEST_URL` แล้ว · **วันที่:** 2026-10-14 · **repo:** zyra-app · แผน: [plan/LanguagePacks/technical-design.md](../plan/LanguagePacks/technical-design.md)

## ทำงานยังไง

1. dev แก้ข้อความใน `zyra-app/messages/en.json` / `th.json` แล้วเปิด PR ตามปกติ
2. merge เข้า **`main`** → GitHub Action **Publish language packs** ตรวจไฟล์ แล้วอัปโหลดขึ้น R2
3. ทุก env (dev / uat / prod) อ่าน manifest เดียวกัน → เห็นคำใหม่ภายในประมาณ 1–2 นาที **โดยไม่ deploy zyra-app**

ถ้า R2 ล่ม / ไม่ได้ตั้ง `I18N_MANIFEST_URL` / ไฟล์เสีย → แอปใช้ไฟล์ภาษาที่มากับ image ตามปกติ หน้าไม่พัง

## กติกา

- **แก้คำของ key ที่มีอยู่แล้ว** ได้เลยผ่านทางนี้
- **key ใหม่** ต้องมากับโค้ดที่ใช้มัน (deploy ปกติ) — pack ใส่ key ใหม่ได้แต่จะไม่มีผลจนกว่าโค้ดจะ deploy
- แก้แล้ว **prod เห็นทันที** (ทุก env ใช้ร่วมกัน) → ต้องผ่าน review PR ก่อน merge เข้า `main`
- merge เข้า `develop` อย่างเดียว **ไม่** publish

## Action ตรวจอะไรบ้าง (ไม่ผ่าน = ไม่ publish)

| ตรวจ | ตัวอย่างที่ไม่ผ่าน |
|---|---|
| key ต้องมีใน `en.json` | พิมพ์ชื่อ key ผิด |
| ค่าต้องเป็นข้อความ | ใส่ตัวเลข / object แทนข้อความ |
| `{argument}` ต้องตรงกับ en | en `Hi {name}` แต่แปลเป็น `สวัสดี {nmae}` หรือลืม `{name}` |
| `<tag>` ต้องตรงกับ en | en `Read the <b>terms</b>` แต่แปลแล้ว `<b>` หาย |

ข้อความใน plural branch (`{count, plural, one {# person} other {# people}}`) ไม่นับเป็น argument — แปลเป็น `{count, plural, other {# คน}}` ได้

ตรวจในเครื่องก่อนเปิด PR:
```bash
node scripts/language-packs.mjs build --sha 0000000 --public-url https://example.invalid --out /tmp/lp
```

## ย้อนกลับ

GitHub → zyra-app → Actions → **Publish language packs** → Run workflow → ใส่ commit / tag เก่าในช่อง `ref` → Run · manifest จะชี้กลับไปที่ไฟล์ของ commit นั้น (ไฟล์เก่ายังอยู่บน R2) — ขึ้นทุก env ภายใน ~1 นาที

## ตั้งค่าครั้งแรก

1. **R2 access key** สำหรับ GitHub Action (สิทธิ์เขียน prefix `i18n/` พอ) → repo secrets ของ zyra-app: `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_PUBLIC_URL`
2. **runtime env** ของ zyra-app ทุก env (secret `zyra-app-<env>-env-json` ผ่าน ESO, ค่าเดียวกัน): `I18N_MANIFEST_URL=<R2_PUBLIC_URL>/i18n/manifest.json` แล้ว restart pod
3. รัน Action ครั้งแรกเอง (Run workflow บน `main`) เพื่อสร้าง manifest

## ไฟล์ที่เกี่ยวข้อง (zyra-app)

| ไฟล์ | หน้าที่ |
|---|---|
| `scripts/language-packs.mjs` | ตรวจ + สร้าง pack / manifest |
| `.github/workflows/publish-language-packs.yml` | publish ขึ้น R2 |
| `i18n/remote-pack.ts` | server โหลด manifest + pack แล้ววางทับไฟล์ที่ bundle |
| `i18n/request.ts` | ใช้ `withRemoteMessages` |
| `messages/locales.json` | ชื่อ / ธง / label ของแต่ละภาษาใน manifest |

## ยังไม่รองรับ

**เพิ่มภาษาใหม่โดยไม่ deploy** — ตอนนี้รายการภาษาใน `i18n/config.ts` ยัง fix ไว้ (`en`, `th`) · ต้องทำ task 3 ของแผน (ทำให้ `Locale` เป็น dynamic) ก่อน · ภาษาที่ตัวอักษรไม่ใช่ละติน / ไทยต้องเพิ่มฟอนต์ (deploy หนึ่งครั้ง)
