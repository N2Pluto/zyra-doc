# zyra-doc

เอกสารทั้งหมดของโปรเจกต์ **ZYRA** อยู่ที่ repo นี้ที่เดียว — ห้ามสร้างโฟลเดอร์ `docs/` ใหม่ใน `zyra-app/`, `zyra-api/`, `zyra-ws/` หรือ repo อื่น

> ถ้าเพิ่งเข้าทีม เริ่มที่ [`web/onboarding/index.html`](web/onboarding/index.html) (เปิดในเบราว์เซอร์) แล้วอ่าน [`guides/glossary.md`](guides/glossary.md) ให้จบ

---

## จะเขียนเอกสารใหม่ — วางไว้ที่ไหน?

| ถ้าเอกสารคือ… | วางที่ | ตั้งชื่อไฟล์ |
|---|---|---|
| แผน / spec / design / task breakdown ของฟีเจอร์ | `plan/<Feature>/` | `spec.md`, `technical-design.md`, `task-breakdown.md`, `test-plan.md`, `ux-ui-plan.md` |
| วิธีทำ, วิธีต่อระบบ, คำศัพท์, convention — ของที่กลับมาอ่านซ้ำได้เรื่อย ๆ | `guides/` | `<topic>.md` |
| บั๊ก / ปัญหาในตัวแอป + root cause + สิ่งที่แก้ | `issues/` | `<topic>-YYYY-MM-DD.md` |
| ปัญหา infra, k3s, DB, deploy, observability, capacity | `ops/` | `<topic>-YYYY-MM-DD.md` |
| release note ต่อเวอร์ชัน | `releases/` | `v<x.y.z>.md` |
| batch งานที่ปิดแล้ว ไม่แก้ต่อ | `archive/` | โฟลเดอร์ต่อ batch |
| หน้าเว็บ HTML ที่ deploy ให้คนอ่าน | `web/` | โฟลเดอร์ต่อ site |

**ไม่แน่ใจว่าหมวดไหน → `guides/`**

---

## 7 หมวด

### [`plan/`](plan/) — แผนและ spec ต่อฟีเจอร์
หนึ่งโฟลเดอร์ต่อหนึ่งฟีเจอร์/โมดูล ชื่อโฟลเดอร์เป็น PascalCase (`Chat`, `VirtualOffice`, `PetManagement`)
ดูสารบัญ + สถานะแต่ละฟีเจอร์ที่ [`plan/README.md`](plan/README.md)

### [`guides/`](guides/) — เอกสารที่ต้องอ่านซ้ำ (evergreen)
ของที่ต้อง**อัปเดตให้ตรงความจริงเสมอ** ไม่ใช่บันทึกเหตุการณ์

| ไฟล์ | เนื้อหา |
|---|---|
| [`glossary.md`](guides/glossary.md) | พจนานุกรมคำศัพท์ — Single Source of Truth ของภาษาที่ใช้ในโปรเจกต์ |
| [`docker-stack.md`](guides/docker-stack.md) | รัน dev stack (sfu + redis ใน Docker, app/api/ws รัน native) |
| [`prod-db-access.md`](guides/prod-db-access.md) | ต่อ prod AlloyDB + Redis จากเครื่องตัวเองผ่าน IAP tunnel |
| [`i18n-migration.md`](guides/i18n-migration.md) | next-intl — โครงสร้าง locale และวิธีเพิ่มคำแปล |
| [`tanstack-query-migration.md`](guides/tanstack-query-migration.md) | TanStack Query v5 — pattern ที่ใช้ใน zyra-app |

### [`issues/`](issues/) — บั๊ก/ปัญหาในตัวแอป
บันทึกต่อรอบรายงาน: อาการ → root cause จากโค้ดจริง → สิ่งที่แก้ → verify แล้วหรือยัง
เอกสารเก่าไม่ต้องลบและไม่ต้องแก้ย้อนหลัง — เจอรอบใหม่ให้เปิดไฟล์ใหม่ตามวันที่

### [`ops/`](ops/) — infra / platform / observability
audit และปัญหาระดับ cluster, DB, SFU, Grafana รวมถึง **กับดักที่ยังค้างอยู่** (เช่น [`argocd-helm-values-drift.md`](ops/argocd-helm-values-drift.md)) — ไฟล์ประเภทกับดักไม่ต้องใส่วันที่ในชื่อ เพราะยังมีผลอยู่ตอนนี้
`prod-schema-check.sql` เป็นสคริปต์ที่ใช้คู่กับ [`guides/prod-db-access.md`](guides/prod-db-access.md)

### [`releases/`](releases/) — release note
หนึ่งไฟล์ต่อ tag ที่ขึ้น prod (`v1.2.0.md`)

### [`archive/`](archive/) — ปิดแล้ว อ่านได้ ห้ามแก้
batch งานที่จบไปแล้ว เก็บไว้เป็นหลักฐาน/อ้างอิงย้อนหลังเท่านั้น
ข้อมูลในนี้ **อาจไม่ตรงกับโค้ดปัจจุบันแล้ว** — ต้อง verify กับโค้ดจริงก่อนใช้ตัดสินใจ

### [`web/`](web/) — หน้าเว็บที่ deploy
static HTML บน Vercel

| site | URL | deploy ยังไง |
|---|---|---|
| `onboarding/` (คู่มือคนใหม่ TH/EN) | https://zyra-onboarding.vercel.app | **อัตโนมัติ** — push เข้า `main` แล้ว Vercel build ให้เลย (~1s) |
| `vo-audio-fixes-summary/` | https://vo-audio-fixes-summary.vercel.app | ด้วยมือ — `cd web/vo-audio-fixes-summary && vercel deploy --prod` |
| `noise-vendor-review/` (เทียบเจ้าตัดเสียงรบกวน — ให้ PM เสนอ) | https://zyra-noise-vendor-review.vercel.app | **อัตโนมัติ** — push เข้า `main` |

**auto-deploy ของสอง site ใช้กลไกคนละแบบ — อย่าสับสน**

**onboarding auto-deploy ทำงานยังไง:** project `zyra-onboarding` ต่อ GitHub repo นี้ไว้ · Root Directory ของ project เป็น `.` เลยชี้ปลายทางผ่าน [`vercel.json`](vercel.json) → `outputDirectory: web/onboarding` และ [`.vercelignore`](.vercelignore) จำกัดให้ upload แค่โฟลเดอร์นั้น — **ถ้าย้าย/เปลี่ยนชื่อโฟลเดอร์ `web/onboarding` ต้องแก้ 2 ไฟล์นั้นด้วย ไม่งั้นเว็บ live พัง**

**noise-vendor-review auto-deploy ทำงานยังไง:** project `zyra-noise-vendor-review` ต่อ GitHub repo นี้เหมือนกัน แต่ตั้ง **Root Directory = `web/noise-vendor-review`** บน Vercel แทน — เลย**ไม่แตะ** [`vercel.json`](vercel.json) และ [`.vercelignore`](.vercelignore) ที่เป็นของ onboarding · ถ้าจะเพิ่ม site ใหม่ในอนาคต ให้ใช้วิธีนี้ (project แยก + Root Directory) ห้ามไปแก้ 2 ไฟล์นั้น ไม่งั้น onboarding พัง

ต้องใช้ `vercel` CLI ≥ 47.2.2 (ที่ลงผ่าน homebrew อาจเก่ากว่า — ใช้ `npx vercel@latest` แทนได้)

---

## อัปเดตความคืบหน้า — "ทำถึงไหนแล้ว" เขียนตรงไหน

สถานะงานเก็บไว้ **3 ชั้น** คนละหน้าที่ ทำงานเสร็จรอบหนึ่งให้อัปเดตจากล่างขึ้นบน:

| ชั้น | ที่อยู่ | ตอบคำถามว่า | อัปเดตเมื่อไหร่ |
|---|---|---|---|
| 3. log ต่อรอบ | `plan/<Feature>/progress.md` | ใครทำอะไร ถึงไหน PR ไหน ติดอะไร | ทุกครั้งที่หยุดงาน / ส่งต่อคนอื่น |
| 2. สถานะล่าสุด | blockquote หัวเอกสารนั้น | ตอนนี้เชื่อได้แค่ไหน ของจริงเป็นยังไง | ทุกครั้งที่สถานะเปลี่ยน |
| 1. ภาพรวม | ตารางใน [`plan/README.md`](plan/README.md) | ทั้งโปรเจกต์มีอะไรบ้าง อันไหนถึงไหน | เมื่อฟีเจอร์ข้ามเฟส (planning → implement → done) |

### งานแต่ละแบบเขียนที่ไหน

| งานที่ทำ | เขียนที่ |
|---|---|
| ฟีเจอร์ที่มีโฟลเดอร์ใน `plan/` แล้ว | ต่อท้าย `plan/<Feature>/progress.md` (ไม่มีก็สร้าง) |
| ฟีเจอร์ใหม่ที่ยังไม่มีโฟลเดอร์ | สร้าง `plan/<Feature>/spec.md` + `progress.md` พร้อมกัน |
| ไล่บั๊กเรื่องเดิมต่อ (อาการเดียวกัน) | **ต่อในไฟล์เดิม** ใน `issues/` — เพิ่มหัวข้อ `## รอบที่ n — YYYY-MM-DD` ท้ายไฟล์ ห้ามเปิดไฟล์ใหม่ |
| บั๊กใหม่ที่ไม่เกี่ยวกับของเดิม | ไฟล์ใหม่ `issues/<topic>-YYYY-MM-DD.md` |
| งาน infra / DB / cluster | `ops/` กฎเดียวกับ `issues/` |
| migration ข้ามฟีเจอร์ (i18n, TanStack Query) | อัปเดตไฟล์เดิมใน `guides/` — ไม่ต้องมี progress.md แยก |

### รูปแบบ entry ใน `progress.md`

ใหม่ไว้บนสุด (คนอ่านจะเห็นสถานะล่าสุดก่อน ไม่ต้องเลื่อน):

```md
# <Feature> — Progress / Handoff

> **สถานะรวม:** SC-XX-01~05 เสร็จ · SC-XX-06 กำลังทำ · 07~08 ยังไม่เริ่ม
> **อัปเดตล่าสุด:** 2026-08-31 · **คนล่าสุด:** <ชื่อ>

## 2026-08-31 · <ชื่อคน>

- **ทำอะไร:** implement SC-XX-05 (avatar picker) ตาม `task-breakdown.md` §5
- **ถึงไหน:** API + UI เสร็จ, migration 86 apply บน dev แล้ว (prod ยัง)
- **PR:** zyra-app#201 (merged) · zyra-api#52 (open — ต้อง merge api ก่อน app)
- **verify ถึงไหน:** tsc/eslint/vitest เขียว · live-test บน dev แล้ว 1 คน · ยังไม่ได้เทส 2 คนพร้อมกัน
- **ต่อจากนี้:** SC-XX-06 — เริ่มที่ `views/user/...` บรรทัด ~340
- **ติดอะไร:** รอ PM ยืนยันว่า limit 5 ตัวหรือ 10 ตัว (ถาม 08-30 ยังไม่ตอบ)

## 2026-08-27 · <ชื่อคนก่อนหน้า>
...
```

**บังคับ 3 อย่าง** ที่ทำให้คนต่อไปทำงานต่อได้จริง: `ถึงไหน` (ไม่ใช่แค่ "ทำแล้ว"), `verify ถึงไหน` (แยก build เขียว ออกจาก live-test ผ่าน), `ติดอะไร` (ไม่ติดก็เขียนว่า `—`)

> ตัวอย่างจริงที่ทำถูกอยู่แล้ว: [`plan/UserManagement/progress.md`](plan/UserManagement/progress.md)

## กฎการเขียน

1. **ชื่อไฟล์** kebab-case ตัวเล็กทั้งหมด (`vo-media-session-audit-2026-08-19.md`) — ยกเว้นชื่อโฟลเดอร์ใน `plan/` ที่เป็น PascalCase
2. **หัวเอกสาร** ทุกไฟล์เริ่มด้วย `# <ชื่อเรื่อง>` แล้วต่อด้วย blockquote บอกสถานะ:
   ```md
   # VO Media Session — Bug Audit

   > **สถานะ:** แก้แล้ว 2026-08-19 (ยังไม่ live-test) · **repo:** zyra-app, zyra-ws
   > **ที่มา:** รายงานจาก QA · **PR:** zyra-app#119
   ```
   คนที่มาอ่านต่อต้องรู้ภายใน 3 บรรทัดว่า "เชื่อได้แค่ไหน" และ "ของจริงตอนนี้เป็นยังไง"
3. **อัปเดตของเดิมก่อนสร้างไฟล์ใหม่** — เอกสาร evergreen (`guides/`, `plan/`) ให้แก้ที่เดิม; เอกสารเหตุการณ์ (`issues/`, `ops/`) ให้เปิดไฟล์ใหม่
4. **ศัพท์เทคนิคต้องตรงกับ** [`guides/glossary.md`](guides/glossary.md) — เพิ่มคำใหม่ที่นั่นก่อน
5. **ลิงก์เอกสารอื่นแบบ relative** (`../guides/glossary.md`) ไม่ใช้ absolute path เพื่อให้ลิงก์ยังใช้ได้เวลาย้ายไฟล์
6. อ้างอิงโค้ดให้ใส่ path จาก root ของ repo นั้น (`` `zyra-ws/internal/hub/client.go` ``) — ไม่ต้องทำเป็นลิงก์ เพราะข้ามคนละ repo

> ฝั่ง AI (Claude Code) มีกฎเดียวกันย่อไว้ที่ `.claude/rules/16-documentation.md` ของ workspace — **ถ้าแก้โครงสร้างที่นี่ ต้องแก้ไฟล์นั้นด้วย**
