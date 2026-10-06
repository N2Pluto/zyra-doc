# Load Test บน Prod Clone — แผน

> **สถานะ:** Planning · **Phase 0 เสร็จ 2026-10-06** (อ่านอย่างเดียว) · ยังไม่ได้สร้างอะไรบน cloud · รอตอบ Q1–Q8 + อนุมัติงบ (§11.4 ≈ $1.17/ชม. ครบชุด)
> **ตอบ:** [spec §10 Q1](spec.md#10-open-questions) "ยิงที่ไหน" → ข้อ (ข) แบบละเอียด: **env แยกที่ spec เครื่องเท่า prod ทุกตัว ไม่แชร์อะไรกับ prod**
> **repo ที่กระทบ:** `zyra-infra` (terraform root ใหม่ + gitops path ใหม่) · `zyra-loadtest` (target/guard) · `zyra-app` (build image ด้วย URL ของ clone) · อ่านอย่างเดียว: `zyra-api`, `zyra-ws`, `zyra-notifications`, `zyra-sfu`
> **Phase 0 verify กับของจริงแล้ว 2026-10-06** (gcloud + kubectl อ่านอย่างเดียวบน `zyra-k3s` + Prometheus 7 วัน) — ผลอยู่ที่ [§11](#11-phase-0--ผล-verify-ของจริง-2026-10-06) · §2 แก้ตามของจริงแล้ว
> **ต้องตอบ [§9 Open Questions](#9-open-questions) ก่อนเริ่ม Phase 1**

---

## 1. What / Why

**What:** สร้าง env ชั่วคราวชื่อ `loadtest` ที่ **topology + machine type + resource request/limit + image version เท่า prod** แต่เป็นของแยกทั้งหมด (VM, DB, Redis, SFU, bucket, secret, DNS) → ยิง lt02–lt19 ขนาดเต็มได้โดยไม่กระทบ prod → ยิงเสร็จลบทิ้ง

**Why:**
- S-02 ห้ามยิงเกิน 5 VU บน node ปัจจุบัน เพราะ dev/uat/prod อยู่ `zyra-k3s` ตัวเดียวกัน — ตัวเลข capacity ทุกตัวตอนนี้จึงยังเป็นประมาณการ
- ยิงจาก local → dev DB ได้ตัวเลขที่ปนเวลาเน็ตบ้าน→GCP (lt07 enter p95 1.7s ที่ 5 VU — progress 2026-09-25) ใช้ตัดสินเรื่อง capacity ไม่ได้
- อยากได้คำตอบที่ใช้ได้กับ prod ตรงๆ เช่น "e2-standard-4 ตัวนี้รับได้กี่ CCU ก่อน Next.js ตาย" → ต้องยิงบนเครื่องสเปกเดียวกัน

**ไม่ทำ:**
- ไม่ยิง prod ตัวจริง (S-01 คงเดิม)
- ไม่ resize / แก้ prod ใดๆ ในแผนนี้ — ถ้าผลบอกว่าต้อง resize ให้เปิดเป็นงานแยก

---

## 2. Prod ที่จะ clone (baseline จาก repo)

| ส่วน | Prod ตอนนี้ | ที่มา |
|---|---|---|
| Main node | `zyra-k3s` **e2-standard-4** (4 vCPU / 16 GB) · Ubuntu 24.04 · disk 40 GB · k3s server · `asia-southeast1-b` | `zyra-infra/terraform/k3s-vm.tf`, `variables.tf:317-327` |
| SFU node | `zyra-sfu-node-0` **c2d-highcpu-4** (4 vCPU / 8 GB) · k3s agent · taint `dedicated=sfu:NoSchedule` · hostNetwork UDP 50000-60000 | `terraform/sfu-node.tf` (ย้ายมา 2026-09-24) |
| Postgres | AlloyDB `zyra-prod` / `zyra-prod-primary` **2 vCPU / 16 GB ZONAL** · **POSTGRES_17** · private IP `10.66.122.2` (PSA `10.66.0.0/16`) · continuous backup 14 วัน (PITR ได้) · automated backup **ปิด** · `max_connections` 1000 | `gcloud alloydb … describe` |
| Redis | Memorystore `zyra-prod-redis` **BASIC 1 GB REDIS_7_2** · AUTH · no TLS · DIRECT_PEERING | `gcloud redis instances list` |
| Object storage | **GCS** `zyra-prod-gather-dev-458614` (endpoint `storage.googleapis.com`) — prod กับ uat ใช้ bucket เดียวกัน · dev ใช้ R2 `zgather-dev` | secret `zyra-api-{prod,uat,dev}-env-json` (อ่านเฉพาะ host/ชื่อ bucket) |
| Ingress / TLS | Traefik (k3s) host 80/443 · cert-manager (prod = DNS-01 Cloudflare) · DNS grey-cloud → IP ของ VM | `gitops/cluster-addons/traefik/`, `gitops/apps/cert-issuer.yaml` |
| GitOps | Argo CD app-of-apps → ApplicationSet env × service · SFU เป็น Application แยก | `gitops/bootstrap/root-app.yaml`, `gitops/apps/services-appset.yaml` |
| Secrets | ESO → GCP Secret Manager `zyra-<svc>-<env>-env-json` · SA ของ node มี secretAccessor **ทั้ง project** | `terraform/secrets-k8s.tf`, `k3s-vm.tf:58-63` |
| Observability | kube-prometheus-stack + Loki + Promtail บน node เดียวกัน · service ไม่มี app metrics | `gitops/observability/` |

### 2.1 Workload ของ prod (ของจริงใน cluster 2026-10-06 = `origin/main` ของ `zyra-infra`)

| Service | Image | Replicas | Request | Limit | Node |
|---|---|---|---|---|---|
| zyra-app | `web-prod:v1.7.3` | 2 | 500m / 256Mi | mem 512Mi | zyra-k3s |
| zyra-api | `backend-prod:v1.7.3` | 1 | 300m / 128Mi | mem 512Mi | zyra-k3s |
| zyra-ws | `ws-prod:v1.7.0` | 1 | 300m / 128Mi | mem 512Mi | zyra-k3s |
| zyra-notifications | `notifications-prod:v1.5.1` | 2 | 50m / 64Mi | mem 128Mi | zyra-k3s |
| zyra-sfu (LiveKit) | `sfu-preview:latest` = `sha256:93d5f7c3…41941` | 1 | 1500m / 1Gi | 3500m / 4Gi | zyra-sfu-node-0 |
| zyra-sfu-lite | `sfu-preview:latest` (digest เดียวกัน) | **1** (เปิด 2026-09-24) | 500m / 512Mi | 1500m / 2Gi | **zyra-k3s** |

- ไม่มี HPA · ws ของ prod **ไม่ได้** เปิด `VO_TICK_REALTIME_DT`/`VO_TICK_ACTIVE_SET` (uat เปิด) → clone ต้องปิดตาม prod
- Argo CD ทุก app `Synced/Healthy` → `origin/main` = ของจริง · **checkout `zyra-infra` ในเครื่องตามหลัง `origin/main` 63 commit** (อยู่ branch `feat/traefik-5xx-access-log`) — ตอนสร้าง clone ต้อง copy จาก `origin/main` ไม่ใช่ไฟล์ในเครื่อง
- SFU ใช้ tag `latest` → clone ต้อง **pin ด้วย digest** ที่ prod รันอยู่ ณ วันยิง ไม่งั้นอาจได้ LiveKit คนละตัว
- `sfu-lite` อยู่บน main node (ไม่ใช่ SFU node) → ต้องอยู่ใน clone ด้วย เพราะกิน CPU ของ node เดียวกับ app

### 2.2 สิ่งที่ prod node แบกอยู่นอกจาก prod (ต้องจำลองด้วย ไม่งั้นผลดีเกินจริง)

- dev + uat (ทุก service 1 replica, request 10m) · Argo CD · ESO · cert-manager · Traefik · cloudflared · Prometheus/Loki/Grafana
- จาก [ops/service-cpu-ram-breakdown-2026-09-24](../../ops/service-cpu-ram-breakdown-2026-09-24.md) (ก่อนย้าย SFU): platform overhead ≈ 58% ของ CPU ที่ใช้ · peak 3.36 core
- **วัดใหม่ 2026-10-06 (หลังย้าย SFU, Prometheus 7 วัน)** — CPU peak ต่อ namespace บน `zyra-k3s`: prod 0.70 · sfu (sfu-lite + nightly job) 0.80 · monitoring 0.29 · argocd 0.27 · kube-system 0.24 · dev 0.09 · uat 0.04 core → ส่วนที่ไม่ใช่ prod ≈ **1.7 core ที่พีค** (ไม่ได้พีคพร้อมกันทุกตัว) · รายละเอียด §11.3

> ถ้า clone มีแค่ prod workload บน e2-standard-4 เปล่าๆ จะได้ CPU ว่างมากกว่า prod จริงเกือบเท่าตัว → ตัวเลข CCU ที่ได้ **ใช้กับ prod ตรงๆ ไม่ได้** · ดู Q3

---

## 3. Architecture ของ clone

```
                      ┌──────────────────────────── VPC เดียวกับ prod (subnet แยก / firewall แยก) ───────────────────────────┐
 Load generator VM    │  lt-k3s  (e2-standard-4, k3s server)                lt-sfu-node (c2d-highcpu-4, k3s agent)      │
 (k6 + lk, แยกเครื่อง) ──▶ Traefik ─▶ ns loadtest: app×2 · api · ws · notif     LiveKit v1.13.5 (hostNetwork)            │
 e2-standard-8?       │            ns monitoring: prometheus/loki/grafana                                                │
                      │            ns argocd · eso · cert-manager                                                        │
                      │            (+ dummy dev/uat ถ้าเลือก Q3-ข)                                                      │
                      │        │                    │                                                                   │
                      │        ▼                    ▼                                                                   │
                      │  AlloyDB lt-alloydb (2 vCPU ZONAL)   Memorystore lt-redis (BASIC 1 GB 7.2)   bucket lt-…         │
                      └──────────────────────────────────────────────────────────────────────────────────────────────────┘
 DNS (Cloudflare, grey-cloud):  app.lt.zyra.center · ws.lt.zyra.center · sfu.lt.zyra.center  → IP ของ lt-k3s / lt-sfu
```

**หลักการ:**
1. **ไม่มีอะไรชี้กลับไป prod** — ไม่ใช้ AlloyDB/Redis/bucket/LiveKit/secret/Argo ของ prod แม้แต่ db index อื่น (prod Redis แชร์ db0/db1/db2 อยู่แล้ว — clone ห้ามเพิ่มเข้าไป)
2. **ชื่อทุก resource ขึ้นต้น `lt-`** และติด label `env=loadtest` → ลบได้ครบ, ค้นหาค่าใช้จ่ายได้
3. **Load generator อยู่คนละเครื่องกับ server** — ไม่งั้น k6/lk แย่ CPU กับ app (ปัญหาเดียวกับที่รันบน MacBook — progress 2026-09-28)
4. **ชั่วคราว** — สร้างก่อนรอบยิง ลบหลังยิงเสร็จ (DB snapshot/ผลเก็บไว้ ดู Phase 6)

---

## 4. Decision ที่เสนอ (รอยืนยันใน §9)

| เรื่อง | เสนอ | เหตุผล |
|---|---|---|
| Terraform | **root ใหม่** `zyra-infra/terraform-loadtest/` + state prefix ใหม่ใน bucket เดิม (`zyra-infra/terraform-loadtest`) | `terraform apply` บน root prod ตอนนี้จะ **replace VM prod** (cloud-init hash drift — `variables.tf:384-411`, `ACCESS.md:396-400`) · ชื่อ resource ใน root prod hardcode (`zyra-prod`, `zyra-k3s`) ไม่มี env prefix · แยก state = `destroy` ลบแค่ clone |
| GCP project | project เดิม `gather-dev-458614` VPC เดิม subnet ใหม่ | AlloyDB ต้อง PSA, image อยู่ Artifact Registry เดิม · ถ้าจะ isolate เต็มที่ใช้ project ใหม่ได้แต่ต้องตั้ง PSA/AR/IAM ใหม่หมด (ดู Q2) |
| Service account ของ VM clone | SA ใหม่ `lt-k3s-vm` ได้ `secretAccessor` **เฉพาะ secret `zyra-*-loadtest-env-json`** | SA prod มีสิทธิ์อ่าน secret ทั้ง project — ถ้า clone ใช้แบบเดียวกัน pod ใน clone อ่าน secret prod ได้ |
| GitOps | Argo CD ของ clone เอง · root app ใหม่ชี้ `gitops/apps-loadtest/` (appset env `[loadtest]` อย่างเดียว) · values ที่ `gitops/envs/loadtest/` copy จาก `envs/prod` | ถ้าเพิ่ม `loadtest` ใน appset เดิม → ไปลงบน node prod (ไม่ isolate) · ถ้าชี้ `gitops/apps/` เดิม → clone จะ deploy prod workload |
| Image | api / ws / notifications / sfu ใช้ **tag เดียวกับ prod** · app ต้อง **build ใหม่** ด้วย `NEXT_PUBLIC_SOCKET_URL` / `NEXT_PUBLIC_LIVEKIT_URL` ของ clone (bake ตอน build) จาก **commit เดียวกับ tag prod** | ให้โค้ดตรง prod · `NEXT_PUBLIC_*` เปลี่ยนตอน runtime ไม่ได้ |
| ข้อมูลใน DB | ดู Q1 — เสนอ **(ก) restore จาก backup prod + scrub** | ขนาดตาราง / index / map จริง มีผลต่อ query time · seed อย่างเดียวได้ DB เล็กกว่าจริงมาก |
| Monitoring | stack เดียวกับ prod ลงใน clone (ใช้ chart `gitops/observability/` เดิม) | ต้องมีอยู่แล้วเพื่อวัดผล + เป็นส่วนหนึ่งของ overhead ที่ prod แบก |

---

## 5. Phases & Tasks

> แต่ละ task = 1 PR ได้ · Phase 0 อ่านอย่างเดียว · Phase 1 ขึ้นไป **สร้าง resource ที่เสียเงิน — ต้อง confirm ผู้ใช้ก่อนทุกครั้ง**

### Phase 0 — Verify ของจริง (อ่านอย่างเดียว, ไม่เสียเงิน)

| # | Task | ผลที่ต้องได้ |
|---|---|---|
| P0-1 | `gcloud auth login` แล้วเช็ค machine type / disk / zone ของ `zyra-k3s`, `zyra-sfu-node-0` | ยืนยันตาราง §2 |
| P0-2 | `gcloud alloydb instances describe` + backup / PITR config | ยืนยัน 2 vCPU ZONAL · มี backup ให้ restore ไหม · `max_connections` |
| P0-3 | อ่าน key `AWS_BUCKET_ENDPOINT` (ชื่อ key เท่านั้น ไม่ log ค่า) ใน `zyra-api-prod-env-json` | prod ใช้ GCS หรือ R2 |
| P0-4 | `kubectl top` / PromQL ของ node prod ช่วงพีค 7 วัน (CPU, mem, overhead ต่อ namespace) | ตัวเลขที่ใช้ตั้ง dummy load ใน Q3-ข · baseline สำหรับเทียบ |
| P0-5 | ประเมินค่าใช้จ่ายต่อชั่วโมง/วันของชุด §3 จาก GCP pricing จริง | ตัวเลขให้ผู้ใช้อนุมัติ — **ยังไม่ได้คำนวณ** |
| P0-6 | เคลียร์ข้อขัดแย้ง: dev DB อยู่ `35.247.177.198` (spec Q1) หรือ AlloyDB `postgres` (ACCESS.md:73) | ไม่เกี่ยวกับ clone ตรงๆ แต่ต้องรู้ว่า DB ไหนคือ prod จริงก่อน restore |

### Phase 1 — Infra (terraform-loadtest)

| # | Task |
|---|---|
| P1-1 | `terraform-loadtest/`: provider + backend prefix ใหม่ · subnet `lt-subnet` · firewall (80/443 จาก load generator + ทีม, UDP 50000-60000/7881 ไป sfu node, IAP SSH) |
| P1-2 | VM `lt-k3s` e2-standard-4 / Ubuntu 24.04 / 40 GB + static IP + cloud-init k3s server (เอาจาก `k3s-vm.tf` แต่ชี้ gitops path ของ clone) · SA `lt-k3s-vm` สิทธิ์จำกัด |
| P1-3 | VM `lt-sfu-node` c2d-highcpu-4 + k3s agent + taint เดียวกับ prod · แก้ ICE filter (`10.148.0.0/20` ใน `sfu-node.tf:97-100`) ให้ตรง subnet ใหม่ |
| P1-4 | AlloyDB `lt-alloydb` 2 vCPU ZONAL (สร้างจาก backup ตาม Q1 หรือว่าง) · Memorystore `lt-redis` BASIC 1 GB 7.2 + AUTH |
| P1-5 | bucket `lt-…` (หรือ prefix แยกบน R2 ตาม P0-3) + HMAC key ของ clone |
| P1-6 | VM load generator (เสนอ e2-standard-8 ในโซนเดียวกัน — ดู Q5) ติด k6 v2.3.0 + `lk` + Go · clone `zyra-loadtest` |

### Phase 2 — Secrets + DNS

| # | Task |
|---|---|
| P2-1 | Secret Manager `zyra-{app,api,ws,notifications,sfu}-loadtest-env-json` จาก `scripts/secret-templates/prod/` → แก้ DB/Redis/bucket/LiveKit/URL เป็นของ clone · **`tokenKey`, `INTERNAL_API_SECRET`, LiveKit key ใหม่ทั้งหมด** (ไม่ใช้ของ prod) · api↔ws ต้องตรงกัน |
| P2-2 | ค่าที่ต้องปิดใน secret clone: `EMAIL_AUTHEN_USER/PASS` ว่าง (S-03) · `ENVIRONMENT_ENABLED=false` (S-04) · `DISCORD_FEEDBACK_WEBHOOK_URL` ว่าง · Sentry DSN ว่างหรือ environment `loadtest` (กันปน issue prod) · `RTC_LIVE_*` ว่าง |
| P2-3 | Cloudflare: `app.lt.zyra.center`, `ws.lt.zyra.center`, `sfu.lt.zyra.center` grey-cloud → IP clone · cert-manager issuer ของ clone (HTTP-01 พอ) · `ALLOWED_ORIGINS`/`APP_URL` ใน secret |

### Phase 3 — GitOps + images

| # | Task |
|---|---|
| P3-1 | `gitops/apps-loadtest/` (root + appset `env: [loadtest]` + sfu app) · `gitops/envs/loadtest/services/*` copy จาก `envs/prod` — replicas / request / limit / image tag / flag **เหมือนกันทุกตัว** ต่างแค่ hostname + secret ID · AppProject แยก `zyra-loadtest` |
| P3-2 | build `web` image ของ clone จาก commit ของ tag prod ปัจจุบัน ด้วย build-arg URL ของ clone · tag `loadtest-<prod tag>` · (ต้องเพิ่ม GitHub Environment `loadtest` ใน `zyra-app` หรือ build มือ — ดู Q6) |
| P3-3 | observability ใน clone: values ของ `gitops/observability/` + promtail regex `(dev\|uat\|prod\|sfu)` เพิ่ม `loadtest` · exporter ชี้ AlloyDB/Redis ของ clone · `externalLabels.cluster: lt-k3s` |
| P3-4 | (ถ้า Q3-ข) workload จำลอง dev+uat: deploy service ชุดเดียวกันใน ns `dev`/`uat` ของ clone ด้วย values ของ dev/uat (request 10m) ให้ overhead ตรงกับ node prod |

### Phase 4 — Data

| # | Task |
|---|---|
| P4-1 | (Q1-ก) restore backup prod เข้า `lt-alloydb` → **scrub ทันทีก่อนเปิด service:** email ทุกแถว → `u<id>@loadtest.invalid`, ลบ refresh token/session, ลบ webhook/integration ที่ชี้ภายนอก, `tb_workspace_invite` ที่ค้าง · migration ล่าสุดของ tag prod ครบ (`prod-schema-check.sql`) |
| P4-1′ | (Q1-ข) schema จาก migrations ของ tag prod + template map + `make seed` อย่างเดียว |
| P4-2 | `make seed` user `lt_` ตามจำนวน scenario ใหญ่สุด (lt04 = 1000, lt11 = 501, lt06 = หลาย workspace) ผ่าน IAP tunnel ไป `lt-alloydb` · `tokenKey` ของ clone |

### Phase 5 — Harness + pre-flight

| # | Task |
|---|---|
| P5-1 | `zyra-loadtest`: profile `.env.loadtest` (BASE_URL / WS_URL / LIVEKIT_URL ของ clone) · guard ใน `k6/lib/config.js` + `scripts/lib/livekit.sh` อนุญาต `*.lt.zyra.center` แต่ **ยังบล็อก host prod** (`zyraworld.co`, `zyra.center` ที่ไม่ใช่ `lt.`, IP `34.142.169.153`) |
| P5-2 | สคริปต์ pre-flight (รันก่อนทุกรอบ): resolve DNS ทุก URL ต้องได้ IP clone · secret clone ไม่มี host/IP ของ prod (`10.66.122.2`, `10.107.20.91`, bucket prod, `sfu.zyra.center`) · `EMAIL_AUTHEN_*` ว่าง · `/api/health` version = tag prod |
| P5-3 | `make smoke` บน clone (1 VU) → ผ่านแล้วค่อยไป Phase 6 |

### Phase 6 — ยิงจริง + เก็บผล + ลบ

| # | Task |
|---|---|
| P6-1 | รันตามลำดับ spec §6: lt01 → lt02 → lt03 → lt07 → lt04 (flag off/on) → lt05 → lt06 → lt09 → lt08 · แล้ว spotlight lt10–13 · meeting lt14–19 · พักระหว่างรอบ 1–2 นาที · ห้าม deploy ระหว่างรอบ (S-08) |
| P6-2 | เก็บ: `reports/` ทุกรอบ + export Grafana panel (CPU/mem ต่อ pod, node load, PSI, AlloyDB connections, Redis ops) ช่วงเวลาเดียวกัน → สรุปลง `zyra-doc/plan/LoadTest/results/` (Q6 ของ spec) ด้วยตาราง before/after ตาม rule 18 |
| P6-3 | teardown: `terraform destroy` ของ `terraform-loadtest` · ลบ secret `*-loadtest-*` · ลบ DNS `*.lt` · ลบ bucket · ลบ backup ที่ restore มา · เช็คใน billing ว่าไม่มี resource `lt-` ค้าง |

---

## 6. Safety เพิ่มจาก spec §4

| # | กฎ |
|---|---|
| S-10 | clone ห้ามอ่าน/เขียน resource prod ใดๆ — pre-flight (P5-2) ต้องผ่านก่อนยิงทุกรอบ |
| S-11 | ห้าม `terraform apply`/`plan -replace` ใน root prod (`zyra-infra/terraform/`) ระหว่างทำงานนี้ — มี drift ที่จะ replace VM prod |
| S-12 | ถ้า restore ข้อมูลจริง (Q1-ก): scrub email/token **ก่อน** start service ใดๆ · clone ไม่มี public endpoint ที่คนนอกเข้าได้นอกจากทีม (firewall / Cloudflare Access) · ลบ DB ทิ้งหลังจบ |
| S-13 | สร้าง / ลบ resource cloud ทุกครั้ง confirm ผู้ใช้ก่อน (เสียเงิน + เป็น production project) |
| S-14 | ห้ามใช้ secret ของ prod ใน clone (`tokenKey`, `INTERNAL_API_SECRET`, LiveKit key, HMAC) — token ที่ mint ให้ clone ต้องใช้กับ prod ไม่ได้ |

S-01 (ห้ามยิง prod) และ S-02 (≤5 VU บน node ปัจจุบัน) ยังใช้เหมือนเดิม — clone ไม่ได้ยกเลิก

---

## 7. ความเหมือน prod — อะไรเหมือน อะไรไม่เหมือน

| เรื่อง | เหมือน prod? | หมายเหตุ |
|---|---|---|
| Machine type / disk / OS / k3s | ✅ | |
| Resource request/limit, replicas, image tag, flag | ✅ | copy จาก `envs/prod` |
| AlloyDB / Redis tier | ✅ | |
| ขนาดข้อมูลใน DB | ✅ ถ้า Q1-ก · ❌ ถ้า Q1-ข | |
| Overhead บน node (dev/uat/monitoring/argo) | ✅ ถ้า Q3-ข · ⚠️ บางส่วนถ้า Q3-ก (มีแค่ monitoring/argo) | |
| Traffic จริงที่ prod รับอยู่ตลอด (~9.4 rps ที่ app) | ❌ | clone เริ่มจาก 0 — ตัวเลขที่ได้คือ "รับเพิ่มได้อีกกี่คนจากศูนย์" ต้องหักของจริงออกตอนตีความ |
| Network ผู้ใช้ (บ้าน/มือถือ → GCP) | ❌ | load generator อยู่ในโซนเดียวกัน latency ต่ำกว่าจริง — ตัวเลข latency เป็น server-side เป็นหลัก |
| TURN (`turn.zyraworld.co`) | ❌ (ไม่ทำในแผนนี้) | `lk load-test` ต่อ UDP ตรง |
| Client (browser render) | ❌ | นอก scope ตาม spec §2 |

---

## 8. Before/After (ตาม rule 18)

ผลของงานนี้คือ baseline ใหม่ — ตัวเลขที่ต้องได้อย่างน้อย:

| Metric | Before (ตอนนี้) | After (หลังยิงบน clone) |
|---|---|---|
| CCU สูงสุดต่อ 1 workspace ที่ p95 < 500ms | ยังไม่ได้วัด — มีแค่ประมาณการ "prod saturate ~40–60 CCU" (ops 09-18) | lt04 |
| จุดที่ Next.js เริ่ม probe fail | ยังไม่ได้วัด | lt02/lt04/lt07 + Grafana |
| ห้องประชุมพร้อมกันก่อน loss > 2% แยกโปรไฟล์ | ยังไม่ได้วัดบน SFU node จริง (local MacBook เท่านั้น) | lt15 / meeting-media |
| คนดู Spotlight สูงสุด | ยังไม่ได้วัดขนาดเต็ม (40 viewers บน local) | lt11 / spotlight-media |

---

## 9. Open Questions

| # | คำถาม | Block |
|---|---|---|
| **Q1** | **ข้อมูลใน DB:** (ก) restore แบบ point-in-time จาก continuous backup ของ prod (มี 14 วัน — §11.2) + scrub PII — สมจริงสุด แต่มีข้อมูลลูกค้าอยู่ใน env ชั่วคราว ต้องผ่านคนที่ดูแลเรื่องข้อมูล · (ข) schema + seed อย่างเดียว — ปลอดภัย แต่ DB เล็กกว่าจริง query เร็วเกินจริง | Phase 1 (P1-4), Phase 4 |
| **Q2** | project เดิม (`gather-dev-458614`, VPC เดิม subnet ใหม่) หรือ project ใหม่ | Phase 1 ทั้งหมด |
| **Q3** | overhead บน node: (ก) prod workload + monitoring/argo อย่างเดียว · (ข) จำลอง dev+uat ด้วย ให้ CPU ว่างเท่า prod จริง | P3-4, การตีความผล |
| **Q4** | รวม SFU node + LiveKit (lt10–19 media) ในรอบแรกเลย หรือทำ control plane (lt02–09) ก่อน แล้วเพิ่ม SFU ทีหลัง | P1-3, ค่าใช้จ่าย |
| **Q5** | load generator เครื่องเดียวพอไหม (k6 1000 VU + WS อาจต้อง ≥ 8 vCPU — ต้องดูจาก lt04 รอบแรก) | P1-6 |
| **Q6** | build image app ของ clone: เพิ่ม GitHub Environment `loadtest` ใน `zyra-app` (ใช้ `deploy-gitops.yml` `workflow_dispatch`) หรือ build มือครั้งเดียว | P3-2 |
| **Q7** | งบ + ระยะเวลาที่ clone จะเปิดค้าง (เสนอ: สร้างเช้า ยิงทั้งวัน ลบเย็น ≈ $12/วัน · หรือเปิดค้างทั้งสัปดาห์ ≈ $197 — §11.4) | อนุมัติ Phase 1 |
| **Q8** | ยิงนอกเวลางานไหม — clone ไม่กระทบ prod แต่อยู่ project/VPC เดียวกัน (ถ้า Q2 = เดิม) และ Artifact Registry / Cloudflare ร่วมกัน | P6-1 |

---

## 10. Readiness

- [x] อ่าน infra prod จาก repo (`zyra-infra`, ops docs) → §2
- [x] Phase 0 verify ของจริง → §11 (2026-10-06)
- [ ] ตอบ Q1–Q8
- [x] ประเมินค่าใช้จ่าย (P0-5) → §11.4
- [ ] ผู้ใช้อนุมัติงบ
- [ ] Phase 1–5
- [ ] smoke บน clone ผ่าน
- [ ] ยิงขนาดเต็ม + สรุปผล
- [ ] teardown ครบ

---

## 11. Phase 0 — ผล verify ของจริง (2026-10-06)

> วิธีเข้า: `gcloud` (ten_dev@, project `gather-dev-458614`) · IAP SSH `zyra-k3s` แล้ว `k3s kubectl get/top` + `curl` Prometheus ใน cluster (`10.43.26.121:9090`) · secret อ่านเฉพาะ host / ชื่อ bucket / มีค่าหรือไม่ — ไม่ได้ log ค่าลับ · **ไม่ได้สร้าง/แก้อะไรเลย**

### 11.1 P0-1 Compute — ตรงกับ repo

| VM | Zone | Type | Disk | สถานะ |
|---|---|---|---|---|
| `zyra-k3s` | asia-southeast1-b | e2-standard-4 | 40 GB pd-standard | RUNNING · k3s v1.36.2 · Ubuntu 24.04.4 |
| `zyra-sfu-node-0` | asia-southeast1-b | c2d-highcpu-4 | 40 GB pd-standard | RUNNING · k3s agent |
| `zyra-sfu` | asia-southeast1-b | e2-standard-4 | 20 GB | TERMINATED (rollback เก่า) |
| `gather-dev` | asia-southeast1-**c** | e2-medium | 100 GB + 100 GB pd-balanced | RUNNING · IP `35.247.177.198` |

- VPC มี subnet เดียว `default` `10.148.0.0/20` → clone ใช้ subnet ใหม่ใน VPC นี้ได้ (ต้องแก้ ICE filter ของ LiveKit ตาม P1-3) หรือใช้ `default` เดิมแล้วแยกด้วย network tag/firewall
- Node `zyra-k3s` ตอนนี้ **CPU requests 3165m (79%)** · limits mem 83% — ค่า 38% ใน ops 09-24 เป็นช่วงก่อนเปิด sfu-lite บน node นี้

### 11.2 P0-2 / P0-3 Data stores

- AlloyDB: ตาม §2 · **continuous backup เปิด 14 วัน → restore แบบ point-in-time เข้า cluster ใหม่ได้** (`gcloud alloydb clusters restore --point-in-time=… --source-cluster=zyra-prod`) — ทาง Q1-ก ทำได้โดยไม่ต้อง pg_dump · automated backup ปิด
- AlloyDB `max_connections` = 1000 · connection peak 7 วัน = 40 → DB ไม่ใช่ตัวจำกัดที่โหลดปัจจุบัน
- Redis peak 7 วัน: 8.3 MiB, 197 ops/s (1 GB ใช้ไม่ถึง 1%)
- Bucket prod = GCS ไม่ใช่ R2

### 11.3 P0-4 โหลดของ node prod (Prometheus, retention 7.2 วัน)

| Metric | `zyra-k3s` | `zyra-sfu-node-0` |
|---|---|---|
| CPU ที่ใช้ peak 7 วัน (rate 5m) | **2.50 core** | 0.81 core |
| CPU ที่ใช้ p95 7 วัน | 1.78 core | 0.23 core |
| load1 peak 7 วัน | **14.99** (4 core) | 1.54 |
| mem ใช้ peak 7 วัน | **13.4 GiB** / 16 | 1.35 GiB / 8 |
| CPU PSI (some) peak | 0.40 | 0.04 |
| ตอนวัด (snapshot) | 1.29 core (32%) · 6.3 GiB | 0.27 core |

| Namespace บน `zyra-k3s` | CPU p95 7 วัน | CPU peak 7 วัน |
|---|---|---|
| prod | 0.45 | 0.70 |
| sfu (sfu-lite + nightly restart) | 0.29 | 0.80 |
| monitoring | 0.25 | 0.29 |
| kube-system (traefik, coredns, metrics) | 0.18 | 0.24 |
| argocd | 0.06 | 0.27 |
| dev / uat | 0.01 / 0.01 | 0.09 / 0.04 |

- prod pod peak: app 0.18–0.27 core/pod, ~117–154 MiB · api 0.06–0.08 core, ≤75 MiB · ws 0.12 core, 24 MiB
- Traefik → prod app peak **30.4 rps** (5m rate)
- **ws `/healthz` ตอนวัด: `total_online` 75** (workspace เดียว 74 คน) ขณะ node ใช้ CPU 32% → ข้อสรุปเดิม "prod saturate ~40–60 CCU" (ops 09-10/09-18) เป็นช่วงที่ SFU ยังอยู่ node นี้ — ใช้เป็น baseline ไม่ได้แล้ว ต้องวัดใหม่บน clone
- load1 15 กับ mem 13.4 GiB ที่พีค ยังไม่ได้หาว่าเกิดตอนไหน/จากอะไร (nightly restart? argocd sync?) — ควรดูก่อนยิง เพราะถ้าเป็น job ประจำ clone ต้องมีด้วย

**ผลต่อ Q3:** ส่วนที่ไม่ใช่ prod บน node นี้ (sfu-lite + monitoring + argocd + kube-system + dev/uat) peak รวมราว 1.7 core ถ้าตัดออก clone จะมี CPU ว่างมากกว่าจริงเกือบ 2 core จาก 4 → **แนะนำ Q3-ข** (ลง sfu-lite + monitoring + argocd + dev/uat ชุดเดียวกัน)

### 11.4 P0-5 ค่าใช้จ่าย (ราคา on-demand Singapore จาก Cloud Billing Catalog API 2026-10-06, USD, ยังไม่หักส่วนลด)

| Resource | สูตร | $/ชม. |
|---|---|---|
| `lt-k3s` e2-standard-4 | 4 × 0.026909 + 16 GiB × 0.003606 | 0.165 |
| `lt-sfu-node` c2d-highcpu-4 | 4 × 0.036471 + 8 GiB × 0.004884 | 0.185 |
| `lt-alloydb` 2 vCPU / 16 GB | 2 × 0.08128 + 16 × 0.01378 | 0.383 |
| `lt-redis` BASIC 1 GB | 1 × 0.065 | 0.065 |
| load generator e2-standard-8 | 8 × 0.026909 + 32 × 0.003606 | 0.331 |
| disk 3 × 40 GB pd-standard + static IP 2–3 ตัว | 0.044/GB-เดือน + ~0.01/ชม./IP | ~0.04 |
| **รวม (ครบชุด)** | | **≈ 1.17** |
| รวมถ้ายังไม่ทำ SFU (Q4 control plane ก่อน) | − sfu node | ≈ 0.98 |

| ระยะเวลา | ครบชุด | ไม่มี SFU |
|---|---|---|
| 1 วันทำงาน (10 ชม.) | ≈ $12 | ≈ $10 |
| เปิดค้าง 24 ชม. | ≈ $28 | ≈ $24 |
| เปิดค้าง 7 วัน | ≈ $197 | ≈ $165 |

**ยังไม่ได้รวม:** storage ของ AlloyDB ที่ restore มา (คิดตาม GB ที่ใช้) · network egress (ถ้า load generator ยิงผ่าน external IP) · Cloud Logging · ค่า build image app ใน CI · ตัวเลขนี้เป็นราคา list ที่ดึงจาก API ไม่ใช่ใบแจ้งหนี้จริง

### 11.5 P0-6 dev DB อยู่ไหน — เคลียร์แล้ว

- `35.247.177.198:3500/zyra-db` = Postgres บน VM **`gather-dev`** (e2-medium, zone c) — ไม่ใช่ AlloyDB · `ACCESS.md:73` ที่บอกว่า AlloyDB `postgres` เป็น "prod+dev" **ไม่ตรงของจริง** (secret dev ชี้ `gather-dev`)
- AlloyDB `zyra-prod`: database `postgres` = prod · `zyra_uat` = uat

### 11.6 สิ่งที่เจอระหว่าง verify (นอก scope — ต้องตัดสินแยก)

| # | เรื่อง | ทำไมสำคัญ |
|---|---|---|
| F-1 | **dev ใช้ Redis ของ prod db 0 เดียวกับ prod** (`zyra-api-dev-env-json` → `10.107.20.91:6379` ไม่มี db index; prod ก็ db 0; uat ใช้ `/2`) | key `vo:*` ของ dev กับ prod ปนกัน · `make clean` ของ loadtest ลบ `vo:*<ws id>*` — ถ้ารันกับ env dev บน cluster จะลบใน Redis เดียวกับ prod (ลบตาม ws id ของ `lt_ws_*` เท่านั้น แต่ก็ยังเป็น Redis prod) · ต้องเช็ค zyra-ws dev ด้วย |
| F-2 | uat ใช้ bucket GCS เดียวกับ prod | upload ทดสอบบน uat ไปอยู่ bucket prod |
| F-3 | secret ของ dev มี `EMAIL_AUTHEN_USER` และ `ENVIRONMENT_ENABLED=true` (prod/uat ก็ `ENVIRONMENT_ENABLED=true`) | ถ้าจะยิงบน dev ในอนาคต S-03/S-04 ไม่ผ่าน |
| F-4 | `zyra-infra` ในเครื่องตามหลัง `origin/main` 63 commit | เอกสาร/การ copy values ต้องอ้าง `origin/main` |
| F-5 | ยังไม่ได้ยืนยันเรื่อง terraform drift ที่จะ replace VM prod (ไม่ได้รัน `terraform plan` เพราะต้อง init + lock state ของ prod) | S-11 ยังคงไว้เป็นข้อห้าม |
