# ย้าย Sentry ไป org ใหม่ แล้วเจอ secret ถูก interpolate ลง shell + token ติดไปใน image layer (2026-09-23)

> สถานะ: **ปิดแล้ว 05:47 UTC · ทดสอบ end-to-end ผ่าน 05:54** — Sentry ทุก env ชี้ org `zyra-rm` แล้ว (dev/uat/prod/landing), ช่องโหว่ทั้ง 2 จุดแก้และ deploy ขึ้น prod ผ่าน `v1.6.0` เรียบร้อย, ยิง error ทดสอบบน uat แล้ว event เข้า + source map แปลกลับได้จริง
> กระทบ: `zyra-app` (CI พัง 1 run, workflow + Dockerfile แก้) · `zyra-api` (tag v1.6.0 ตามไปด้วย) · `zyra-landing` (เปลี่ยน DSN + redeploy) · Sentry org เดิม `zyra-3h` เข้าไม่ได้อีก
> ที่มา: ผู้ใช้ถามวิธีย้าย Sentry project ให้คนอื่น แล้วพบว่า account `info@zyra-world.com` โดน deactivate ใน org เดิมเพราะ Developer plan รองรับ 1 member

---

## ที่มา

Sentry free plan (Developer) รองรับ **1 member ต่อ org** — `info@zyra-world.com` เป็น member คนที่ 2 ใน org `zyra-3h` เลยโดนปิดสิทธิ์อัตโนมัติ เรียก API ใดก็ตอบ `member-disabled-over-limit` เปิด Settings ไม่ได้เลยแม้แต่จะ transfer project ออก

ตัดสินใจไม่ย้าย project แต่เปิดใหม่ใน org `zyra-rm` (สร้าง 2026-09-16, `info@zyra-world.com` เป็นเจ้าของคนเดียว → อยู่ free plan ได้) แล้ว Leave ออกจาก `zyra-3h`

| | org เดิม | org ใหม่ |
|---|---|---|
| slug | `zyra-3h` | `zyra-rm` |
| org id | `4512055591370752` | `4512095523176448` |
| project | (เข้าไม่ได้) | `zyra-app` `4512133793251328` · `zyra-landing` `4512133811404800` |

---

## บักที่ 1 — secret ถูกวางลง shell script ตรง ๆ

ตอนหมุน `SENTRY_AUTH_TOKEN` ใหม่ CI พังทันที:

```
/home/runner/work/_temp/....sh: line 2: e: unbound variable
##[error]Process completed with exit code 1.
```

[zyra-app run 35820043361](https://github.com/Maximumsoft-Co-LTD/zyra-app/actions/runs/35820043361)

**Root cause:** `deploy-gitops.yml` step `Build and push image` เขียน `--build-arg X="${{ secrets.X }}"` ตรง ๆ ใน `run:` — GitHub แทนค่า secret **ก่อน** bash เริ่มทำงาน ตัวอักษรใน secret จึงกลายเป็น script text

ค่าที่หลุดเข้าไปตอนนั้นมี `$e` อยู่ → `set -u` เจอตัวแปรไม่มีค่า → ตาย

**ความรุนแรงจริงสูงกว่าที่เห็น:** build พังเป็นเคสที่เบาที่สุด ถ้า secret มี backtick หรือ `$(...)` มันจะถูก **execute บน runner** ที่ถือ GCP credential + gitops deploy key อยู่ = command injection

**แก้:** ย้าย secret ทั้ง 21 ตัวไป `env:` block แล้วอ่านเป็น `"$VAR"` — [zyra-app#445](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/445)

---

## บักที่ 2 — auth token ติดไปกับ image layer

Docker เตือนในทุก build ที่ผ่านมา:

```
SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data
  (ARG "SENTRY_AUTH_TOKEN") (line 43)
  (ENV "SENTRY_AUTH_TOKEN") (line 69)
```

build-arg ถูกบันทึกใน image layer history → ใครที่ pull image จาก Artifact Registry ได้ ก็อ่าน token กลับออกมาได้ รวมถึง image `web-prod`

**แก้:** เปลี่ยนเป็น BuildKit secret mount ที่อยู่แค่ระหว่าง `RUN` — [zyra-app#448](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/448)

```dockerfile
# syntax=docker/dockerfile:1
RUN --mount=type=secret,id=sentry_auth_token \
    SENTRY_AUTH_TOKEN="$(cat /run/secrets/sentry_auth_token 2>/dev/null || true)" \
    npm run build
```

คู่กับ `--secret id=sentry_auth_token,env=SENTRY_AUTH_TOKEN` + `DOCKER_BUILDKIT: "1"` ใน workflow (classic builder ไม่รองรับ `--secret`)

ไม่มี secret (build local) → token ว่าง → `sourcemaps.disable: !process.env.SENTRY_AUTH_TOKEN` ปิด upload เอง build ยังผ่าน

---

## Before / After

| Metric | Before | After | Δ |
|---|---|---|---|
| step `Build and push image` | ❌ fail exit 1 (`e: unbound variable`) | ✅ success | แก้ได้ |
| secret ที่ถูก interpolate ลง run script | **21 ตัว** | **0** | -21 |
| Docker `SecretsUsedInArgOrEnv` warning | 2 | **0** | -2 |
| `SENTRY_AUTH_TOKEN` ใน image layer history | มี (ARG + ENV) | ไม่มี (tmpfs เฉพาะ RUN) | — |
| source map ที่ upload เข้า Sentry ต่อ build | 0 | **1,330 ไฟล์** (980 + 350) | +1,330 |
| Sentry org ที่ prod รายงานเข้า | `zyra-3h` (เข้าไม่ได้) | `zyra-rm` | — |
| error event ที่ Sentry รับได้ (uat) | 0 | **2 events / 1 issue** (`ZYRA-APP-1`) | +2 |
| `tb_object_animation` บน prod ที่ต้อง normalize ใหม่ | — | **0 row** | ไม่มีของค้าง |

**วัดยังไง:**
- build/warning — GitHub Actions run conclusion + `gh run view --log | grep -c SecretsUsedInArgOrEnv`
- source map — Sentry API `GET /api/0/projects/zyra-rm/zyra-app/files/artifact-bundles/` (release `v1.6.0` → bundle `f2bb7b0a…` 980 ไฟล์ + `11db46ed…` 350 ไฟล์ upload 05:41:43–46)
- org ที่ prod ใช้จริง — แกะ JS chunk ที่ `app.zyraworld.co` เสิร์ฟ ผ่าน browser: `orgId 4512095523176448 / projectId 4512133793251328`
- DB — `zyra-service/prod-db.sh query "SELECT count(*) FROM tb_object_animation"` ผ่าน IAP tunnel

**ช่วงเวลา:** before = run 04:51 UTC · after = run 05:06 (dev), 05:41 (prod) — วันเดียวกัน 2026-09-23

---

## Timeline (UTC)

| เวลา | เกิดอะไร |
|---|---|
| 04:33 | ตั้ง `NEXT_PUBLIC_SENTRY_DSN` / `SENTRY_ORG` / `SENTRY_PROJECT` ใหม่ ทั้ง dev/uat/production |
| 04:49 | ตั้ง `SENTRY_AUTH_TOKEN` — **ได้ค่าขยะ** (clipboard ไม่ใช่ token) |
| 04:51 | dev deploy พังที่ `e: unbound variable` |
| 05:02 | merge #445 → dev build ผ่านทั้งที่ค่าขยะยังอยู่ = ยืนยัน root cause |
| 05:04 | ตั้ง `SENTRY_AUTH_TOKEN` สำเร็จ |
| 05:15 | dispatch #448 บน branch → build ผ่าน, warning = 0, bundle เข้า Sentry |
| 05:31 | merge release PR → uat |
| 05:39 | merge `zyra-api` #139 → main |
| 05:40 | push tag `v1.6.0` ทั้ง `zyra-app` และ `zyra-api` |
| 05:43 | prod build + gitops bump เสร็จ |
| ~05:47 | Argo sync เสร็จ — prod เสิร์ฟ v1.6.0 ชี้ org ใหม่ |

---

## ทดสอบ end-to-end บน uat (05:54 UTC)

โยน error เข้าไปบน `app.uat.zyra.center/login` เพื่อยืนยันว่า pipeline ทำงานครบวง ไม่ใช่แค่ "DSN อยู่ในโค้ด"

```js
setTimeout(() => { throw new Error('ZYRA SENTRY PIPELINE TEST 2 (claude, uat) — safe to ignore') }, 100)
```

ผล → issue [`ZYRA-APP-1`](https://zyra-rm.sentry.io/issues/7750046879/)

| | ค่าที่ได้ |
|---|---|
| Events / Users | 2 / 0 |
| release | `uat-92f9af8` (100%) |
| environment | `uat` (100%) |
| culprit | `/login` |
| `handled` | `false` — unhandled path ทำงาน |
| mechanism | `auto.browser.browserapierrors.setTimeout` |
| Session Replay | จับได้ 1 replay, ข้อความ/input ถูก mask ครบตาม `maskAllText` + `maskAllInputs` |

**source map ใช้งานได้จริง** — frame ที่ browser เห็นเป็น `0ia9p_56m-13b.js:7:5342` ถูกแปลกลับเป็น path ต้นฉบับพร้อมบรรทัด/คอลัมน์:

```
<anonymous>:1:27                                              [In App]
Called from: node_modules/@sentry/browser/src/helpers.ts:116:58 in r
```

**ข้อจำกัดของการทดสอบนี้:** frame ที่ถูก symbolicate เป็นโค้ดใน `@sentry/browser` ไม่ใช่ `.tsx` ของเราเอง เพราะ error ถูก throw จาก script ที่ inject เข้าไป ไม่ได้เกิดจากโค้ดแอปจริง — ทั้งคู่อยู่ใน bundle และ source map ชุดเดียวกัน frame ของแอปจึงควรแปลได้เหมือนกัน แต่ **ยังไม่ได้ทดสอบตรง ๆ** และทดสอบเฉพาะ uat ยังไม่ได้ยิงบน prod

---

## กับดักที่เสียเวลาที่สุด — clipboard

ตั้ง `SENTRY_AUTH_TOKEN` พลาด 3 รอบ เพราะ **ปุ่ม Run บน code block ของ Claude Code เขียนคำสั่งทับ clipboard ตอนกด** → `$(pbpaste)` ได้ข้อความคำสั่ง ไม่ใช่ token (ค่าที่ค้างอยู่ใน secret รอบแรกคือตัวคำสั่งที่มี `"$e"` อยู่ข้างใน — ที่มาของบักที่ 1 พอดี)

**วิธีที่ใช้ได้:** ให้คำสั่ง **poll clipboard** แล้วค่อยไปกด copy ทีหลัง — กลับลำดับจาก "copy ก่อน run" เป็น "run ก่อน copy"

```bash
for i in $(seq 1 60); do T=$(pbpaste); case "$T" in sntrys_*) ...; break;; esac; sleep 2; done
```

ใส่ guard `case "$T" in sntrys_*)` ไว้ด้วย ไม่งั้นเขียนค่าขยะทับ secret ซ้ำโดยไม่รู้ตัว

---

## กับดักที่ 2 — `curl` ยืนยัน frontend deploy ไม่ได้

เช็คว่า prod ขึ้นของใหม่หรือยังด้วยการ `curl` หน้า `/login` แล้ว grep chunk หา DSN → **ได้ false negative ตลอด** เพราะ curl เห็นเฉพาะ `<script>` ใน HTML (14 ไฟล์) ส่วน chunk ที่มี DSN โหลดตอน runtime (23 ไฟล์)

ต้องเช็คผ่าน browser จริงถึงจะเห็น:

```js
const srcs = Array.from(document.scripts).map(s=>s.src).filter(s=>s.startsWith(location.origin))
// fetch แต่ละตัวแล้ว match /o(\d{10,})\.ingest\.[a-z.]*sentry\.io\/(\d+)/
```

---

## ยังไม่ปิด

- **ยังไม่เคย symbolicate frame ที่เป็นโค้ดแอปเอง (`.tsx`)** — การทดสอบบน uat แปล frame ใน `@sentry/browser` กลับมาได้ถูกต้อง แต่ยังไม่มี error ที่เกิดจากโค้ดเราเองมาให้ดู · **และยังไม่ได้ยิงทดสอบบน prod** (ใช้ pipeline เดียวกันแต่คนละ environment secret)
- **issue `ZYRA-APP-1` เป็นขยะจากการทดสอบ** — ยังไม่ได้ resolve/archive ทิ้ง
- **`environment: production` ไม่มี protection rule เลย** — `GET /repos/.../environments/production` ตอบ `protection_rules: []` ขัดกับ [06-release.md](../../.claude/rules/06-release.md) ที่เขียนว่ามี gate → push tag = deploy prod ทันที ไม่มีใครต้องอนุมัติ ควรแก้ที่ใดที่หนึ่ง
- **prod ส่ง OTP email ไม่ได้** — `/api/health` ตอบ `email: not_configured` (`EMAIL_AUTHEN_USER` / `EMAIL_AUTHEN_PASS` ไม่ได้ตั้งใน `zyra-api-prod-env-json`) ของเดิม ไม่เกี่ยวกับ deploy รอบนี้ แต่แปลว่าคนสมัครใหม่บน prod ไม่ได้รับ OTP
- **project เก่าใน `zyra-3h` ยังอยู่** — เข้าไม่ได้จาก account นี้ ต้อง login ด้วย account เจ้าของเดิมถ้าจะลบ
- **`zyra-api` / `zyra-ws` / `zyra-notifications` ยังไม่มี Sentry** — มีเฉพาะฝั่ง frontend

---

## สรุปสิ่งที่เปลี่ยน

| Repo | PR / tag |
|---|---|
| `zyra-app` | [#445](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/445) secrets → `env:` · [#448](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/448) BuildKit secret · [#449](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/449) release · tag `v1.6.0` |
| `zyra-api` | [#139](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/139) release (SC-OBJ-NAT-01 backend) · tag `v1.6.0` |
| `zyra-landing` | ไม่มี PR — เปลี่ยน repo secret `SENTRY_DSN` แล้ว `workflow_dispatch` redeploy |
| `zyra-ws` / `zyra-notifications` | ไม่แตะ — ไม่มี commit ใหม่ตั้งแต่ v1.5.1 |
