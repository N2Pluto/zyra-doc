# prod zyra-app ดับ "no available server" — liveness probe ฆ่า Next.js ตอน node CPU แย่งกัน (2026-09-10)

> สถานะ: **แก้แล้ว 05:02 UTC (12:02 ไทย) · เว็บ 200 ต่อเนื่อง · pod ใหม่ restart 0 แม้ load node กลับไป 10 อีกครั้งตอน 05:11 · alert + probe ใหม่ apply แล้ว 05:11** — root cause = probe default 1 วิ + CPU request 100m บน node ที่ SFU กิน CPU · **CPU rebalance (item 2) ปิดแล้ว 15:37 UTC (22:37 ไทย)** PR #28 merged → node requests 3850m (96%) → **3480m (87%)** · **ยังไม่ปิด: capacity ของ node** (4 core, PSI CPU 30–40%, load avg 8–10 ตอนเวลางาน) ต้องตัดสินใจขยาย/แยก SFU
> กระทบ: prod `app.zyraworld.co` (frontend เท่านั้น) · zyra-infra (chart + prod app values + observability)
> สรุปสำหรับผู้บริหาร (PM → MD): [exec-brief-capacity-2026-09-10.md](exec-brief-capacity-2026-09-10.md) · หน้าเว็บ https://zyra-exec-brief-2026-09-10.vercel.app

## อาการ

- ~04:00–05:02 UTC (11:00–12:02 ไทย) ผู้ใช้เห็น `app.zyraworld.co` ตอบ **503 "no available server"** (ข้อความของ Traefik = route มี แต่ไม่มี pod Ready สักตัว)
- API (`api.zyraworld.co` v1.3.3), WS (40 คน online), SFU, AlloyDB **ปกติทั้งหมด** — ไม่เกี่ยวกับการสลับ AlloyDB เป็น ZONAL เมื่อวาน
- `app.zyra-world.com` (domain สำรอง pod ชุดเดียวกัน) บางช่วงตอบ 200 — เพราะ pod ทั้ง 2 ตัวสลับกันตายเป็นระลอก ไม่ได้ตายพร้อมกันตลอด
- ไม่มี alert ดัง: blackbox probe เฝ้าแค่ `api.zyraworld.co` กับ `ws.zyraworld.co` **ไม่มี app**; workflow "Server Health Monitor" ยิง `app.zyra-world.com` ทุก 6 ชม. ซึ่งเผอิญตอบ 200

## หลักฐาน (kubectl บน zyra-k3s, 04:55 UTC)

| สิ่งที่ดู | ค่า |
|---|---|
| `zyra-app` pods | 2 ตัว, **RESTARTS 12 และ 10 ใน 12 ชม.** (pod เกิด 16:20 UTC เมื่อวาน = ตอน deploy v1.3.4), restart ล่าสุด 4–5 นาทีก่อน |
| Last State | `Terminated / Error / Exit Code 143` = SIGTERM จาก kubelet ไม่ใช่ OOM |
| Memory | 107–116 Mi จาก limit 512 Mi |
| Events | `Liveness probe failed: context deadline exceeded` ×51 ใน 3 ชม. · `Killing … failed liveness probe` ×9 ใน 55 นาที · `Readiness … connection refused` ระหว่าง restart |
| Probe spec (default k8s) | `timeout=1s period=10s failure=3` → Next.js ไม่ตอบ `/api/health` ใน 1 วิ 3 ครั้งติด = โดนฆ่า |
| Node | e2-standard-4 · load avg **10.55 (15 นาที)** บน 4 core · CPU PSI `some avg300 = 34%` · k3s-server 56% · LiveKit 43% (730m) · Prometheus 190m |
| CPU request | app 100m ×2 · **sfu 1500m** · api/ws 100m · notifications 50m → เวลาแย่ง CPU, app ได้ CFS share น้อยกว่า SFU ~15 เท่า |
| dev/uat `zyra-app` (โค้ดเดียวกัน v1.3.4) | restart 0 — ไม่มี load |
| `/api/health` ของ app | route ธรรมดา return JSON ไม่แตะ backend — ช้าเพราะ event loop ไม่ได้ CPU ไม่ใช่ dependency |

## Root cause

1. **Probe เข้มเกินสำหรับ Next.js บน node ที่ CPU แย่งกัน**: chart ไม่ได้ตั้ง `timeoutSeconds`/`failureThreshold` เลย → default 1 วิ/3 ครั้ง · ตอนคน online 40 คน + ประชุมหลายห้อง SFU กิน CPU, k3s-server สูง → Next.js ตอบ health ช้ากว่า 1 วิ → kubelet ฆ่า → ระหว่าง restart ทั้ง 2 ตัว Service ไม่มี endpoint → 503
2. **CPU request ของ app ต่ำมาก (100m)** เทียบ SFU 1500m → ตอน saturate app โดนแย่งก่อน
3. (พื้นหลัง) node 4 core ใกล้เต็ม: หลังแก้ CPU requests รวม = **3850m / 4000m (96%)**, PSI CPU some 36–49% ระหว่างเวลางาน

ทำไมเพิ่งเกิด: restart เริ่มตั้งแต่ pod v1.3.4 เกิด (16:20 UTC) แต่กระจายทั้งคืน (x37 ใน 12 ชม.) และ**ถี่ขึ้นมากตอน 11:00–12:00 ไทย** ที่ SFU โหลดสูง — ไม่พบหลักฐานว่า v1.3.4 เองทำให้ช้าขึ้น (uat โค้ดเดียวกัน 0 restart) แต่ยังไม่ได้ profile Next.js บน prod จึงตัดไม่ได้ 100%

## สิ่งที่แก้ (GitOps → Argo auto-sync)

| เวลา UTC | commit (zyra-infra main) | อะไร | ผล |
|---|---|---|---|
| 05:00 | `a7e96c1` | chart: `probe:` map แบบ opt-in ต่อ component (`initialDelaySeconds/periodSeconds/timeoutSeconds/livenessFailureThreshold/readinessFailureThreshold`) · prod app: `timeout 5s`, liveness 6 ครั้ง (60 วิ), readiness 3 ครั้ง | helm template ของ api/ws/notifications **เหมือน HEAD ทุก byte** (ไม่ roll), SFU ไม่มี probe ไม่ roll · app roll เสร็จ 05:03 |
| 05:04 | `b3b94a5` | prod app `resources.requests.cpu` 100m → **500m** | roll เสร็จ 05:05 · node requests 3850m/4000m |
| 05:10 | `267d4b8` | observability: blackbox probe `app.zyraworld.co` + alert `ZyraProdContainerRestarting` | ไม่แตะ workload |
| 05:03–05:04 | — | probe `app.zyraworld.co/login` 20/20 = 200, `/api/health` v1.3.4 | เว็บกลับมา |

Argo sync ถูกเร่งด้วย `kubectl -n argocd annotate application app-prod argocd.argoproj.io/refresh=hard` (ปกติรอ 3 นาที)

## Before/After

| Metric | Before (04:00–05:00 UTC) | After | วัดจาก |
|---|---|---|---|
| `app.zyraworld.co` HTTP | 503 (ทุก path รวม `/api/health`) | 200 ×20/20 (05:03–05:04) + probe ทุก 5 วิ 05:06–05:16 ไม่มี non-200 | curl ทุก 3–5 วิ |
| restart ของ zyra-app pods | 12 + 10 ใน 12 ชม. · `Killing ×9` ใน 55 นาทีสุดท้าย | 0 ถึง 05:12 ทั้งที่ load avg กลับไป 10.0 (เงื่อนไขเดียวกับตอนตาย) — ดูต่อทั้งวัน | `kubectl get pods -n prod` |
| liveness spec | 1s × 3 | 5s × 6 | deployment spec |
| app cpu request | 100m | 500m | deployment spec |

## ยังไม่ปิด / ต้องทำต่อ

1. ~~Alert ไม่ดัง~~ **ทำแล้ว 05:10 UTC** (zyra-infra `267d4b8`): blackbox เพิ่ม `https://app.zyraworld.co/api/health` (เดิมมีแค่ `app.zyra-world.com` ซึ่งเผอิญโดน replica ที่ยังอยู่) + alert ใหม่ `ZyraProdContainerRestarting` = container prod ตัวเดียว restart ≥3 ครั้งใน 3 ชม. → critical (KubePodCrashLooping ของ kube-prometheus ต้องอยู่ใน CrashLoopBackOff 15 นาที เลยไม่เคยจับเคสที่ probe ฆ่าแล้วกลับมา Ready ใน 10 วิ)
2. ~~**CPU rebalance**~~ **ทำแล้ว 15:37 UTC (22:37 ไทย)** — ดู [รอบที่ 3](#รอบที่-3--2026-09-10-2237-ict-merge-pr-28-แล้ว) ท้ายไฟล์ · ของเดิมที่เตรียมไว้:: zyra-infra branch `fix/cpu-shares-rebalance` → dev/uat api/app/ws 50m→10m, notifications 25m→10m · prod api/ws 100m→**300m** · SFU request 1500m→1000m (ใช้จริง ~730m ที่ 40 คน) + **limit 3000m→2500m** · node requests 3850m → **3480m (87%)** และเผื่อ surge pod 500m ของ app ตอน rolling update — **ที่ 3850m วันนี้ app rolling update จะค้าง Pending** (ต้อง +500m ที่ไม่มี) จึงต้อง merge PR นี้ก่อน deploy app ครั้งหน้า · ห้าม merge เวลางาน: SFU Recreate หลุดทุกห้อง ~30 วิ, ws restart ทุกคน reconnect
3. **Capacity**: node 4 core อยู่ที่ requests 96% และ PSI CPU 30–50% ตอนเวลางาน — ทางเลือก: ขยาย `zyra-k3s` เป็น e2-standard-8 (≈ +$120/เดือน, ต้อง stop VM = downtime ทั้ง cluster ~5 นาที ทำนอกเวลางาน) หรือแยก SFU ไป node/VM ของตัวเอง หรือลด Prometheus/Loki (190m + retention) · ควรตัดสินก่อน user เพิ่ม
4. **Profile Next.js บน prod**: `/api/img` + `/_next/image` proxy asset ให้ทุก client (pet spritesheet/GIF/เสียง) กิน CPU บน Next server — ถ้าเป็นตัวหนักควรย้ายให้ client โหลดจาก R2/GCS ตรง (ต้องเปิด CORS บน bucket) หรือ cache ที่ Traefik/Cloudflare
5. ใส่ `probe:` ให้ prod api/ws/notifications ด้วย (ตอนนี้ยัง default 1s×3 เหมือนกัน แค่ Go ตอบเร็วกว่าเลยยังไม่ตาย) — ทำนอกเวลางานเพราะจะ roll pod

## รอบที่ 2 — 2026-09-10 22:25 ICT (scheduled task, ยังไม่ merge)

Scheduled task นอกเวลางานรันตามที่ตั้งไว้ **แต่ไม่ merge PR #28** เพราะ occupancy guard ไม่ผ่าน — ยังมีคนใช้จริง 22 คน

| เช็ค | ค่าที่วัดได้ 15:25–15:27 UTC (22:25–22:27 ICT) | เกณฑ์ | ผล |
|---|---|---|---|
| `ws.zyraworld.co/healthz` → `total_online` | **22** (ทั้งหมดอยู่ workspace `d498edfa`) | ต้อง ≤ 10 | ❌ ไม่ผ่าน |
| ws log `avg_active` / `max_active` | **22 / 22**, `fanout` 473–516, `dropped_ticks` 0 | — | ยืนยันว่าไม่ใช่ ghost session (มี movement/visibility event สดๆ) |
| SFU 30 นาทีล่าสุด | `participant active` 5 · `participant closing` 10 · `room closed` 3 · event สุดท้าย 15:24:27 UTC | ไม่มีห้องสด | มีคนเข้า-ออก zone media เป็นระยะ → Recreate เสี่ยงตัดสาย |
| node cpu requests | **3850m (96%)** — เท่าเดิม, ยังไม่ได้แก้ | เป้า 3480m (87%) | รอ merge |
| node load / PSI | load avg **0.97 / 1.20 / 1.96** · PSI cpu some avg10 **13.45%** | — | node ว่างแล้ว (ตอน incident load 10, PSI 30–50%) |
| pod prod/sfu | api 28h · app ×2 10h · ws 35h · notifications ×2 15d · sfu 18h — **RESTARTS 0 ทุกตัว** | — | ✅ probe fix ยังนิ่ง ไม่มี liveness kill ซ้ำใน ~10 ชม. |

**สรุป**: item 2 (CPU rebalance) **ยังไม่ปิด** — PR #28 ยัง OPEN รอ merge ตอนที่ไม่มีคนใช้ ต้องขอ confirm จากผู้ใช้ก่อน
เพราะ merge = SFU Recreate (หลุดทุกห้อง ~30 วิ) + ws/api roll (22 คน reconnect)

**ข้อสังเกตข้างเคียง (ยังไม่ปิด)**: probe fix รอบแรกอยู่ได้ ~10 ชม. โดย restart 0 ทั้งที่ตอนกลางวัน node มีโหลด — เป็นหลักฐานเพิ่มว่า root cause คือ probe timeout ไม่ใช่ image

## Runbook ถ้าเกิดอีก

```bash
# 1) ตายชั้นไหน
for u in https://app.zyraworld.co/api/health https://api.zyraworld.co/api/health https://ws.zyraworld.co/healthz; do curl -s -o /dev/null -w "$u %{http_code}\n" $u; done
# 2) ดู pod (ต้อง gcloud auth ยังไม่หมดอายุ)
gcloud compute ssh zyra-k3s --zone asia-southeast1-b --project gather-dev-458614 --tunnel-through-iap \
  --command "sudo k3s kubectl -n prod get pods -o wide; sudo k3s kubectl -n prod get events --sort-by=.lastTimestamp | tail -20; uptime; cat /proc/pressure/cpu"
# 3) exit 143 + 'failed liveness probe' = probe ฆ่า ไม่ใช่ crash → ดู load/PSI ก่อนโทษ image
# 4) ถ้าต้อง rollback image: แก้ image.tag ใน zyra-infra gitops/envs/prod/services/app/values.yaml แล้ว push main
```

## รอบที่ 3 — 2026-09-10 22:37 ICT (merge PR #28 แล้ว)

ผู้ใช้ override occupancy guard ของรอบที่ 2 เอง (22:30 ICT: "merge เลย 22 คนนั้นไม่ใช่คนจริง / ยอมให้หลุด") แล้วสั่งรันทันที — จึง merge ในเวลา 22:37 ทั้งที่ `total_online` = 22

| เวลา (ICT) | ทำอะไร | ผล |
|---|---|---|
| 22:24 | preflight: gcloud auth ผ่าน (`zyra-k3s RUNNING`), `total_online` 22, node requests **3850m (96%)** / limits 3000m (75%) | เก็บค่า before |
| 22:37:49 | `gh pr merge 28 --merge --delete-branch` (zyra-infra, 11 files) | MERGED |
| 22:39 | hard refresh Argo 11 apps (sfu/api/ws prod + api/app/ws/notifications dev + uat) | annotated ครบ |
| 22:39–22:44 | rollout: `zyra-sfu` (Recreate) → `zyra-api` → `zyra-ws` prod + dev/uat ทั้งหมด | successfully rolled out ทุกตัว |
| 22:44 | Argo `get app` ทั้ง cluster (24 apps) | **Synced + Healthy ทุกตัว** |

### Before/After (item 2 — CPU rebalance)

| Metric | Before (22:24) | After (22:44) | Δ |
|---|---|---|---|
| node cpu **requests** | 3850m (96%) | **3480m (87%)** | −370m (−9 จุด%) |
| node cpu **limits** | 3000m (75%) | **2500m (62%)** | −500m |
| prod `zyra-api` request | 100m | 300m | +200m |
| prod `zyra-ws` request | 100m | 300m | +200m |
| prod `zyra-app` request | 500m | 500m (ไม่แตะ) | — |
| SFU request / limit | 1500m / 3000m | **1000m / 2500m** | −500m / −500m |
| dev+uat api/app/ws/notifications request | 50m/50m/50m/25m ต่อ env | **10m ทุกตัวทั้ง 2 env** | −265m รวม |
| pod prod/dev/uat/sfu | — | Running 1/1 ทุกตัว **RESTARTS 0** (api 91s · ws 94s · sfu 41s · dev ×4 ~90s · uat ×4 ~80s · app ×2 10h ไม่ roll) | — |
| `app.zyraworld.co/api/health` | — | **200 ×24/24** probe ทุก 5 วิ 22:39:32–22:41:30 | ไม่มี non-200 |
| 4 host หลัก (app/api/ws/sfu) | — | 200 ทั้งหมด (0.14–0.22s) · ws `v1.3.1` `total_online` 23 (คน reconnect กลับครบหลัง ws roll) | — |

**วัดยังไง**: `kubectl describe node | grep -A6 'Allocated resources'` บน zyra-k3s (before 22:24 / after 22:44) · `kubectl get deploy -o custom-columns` สำหรับ request/limit ต่อ service · `curl -o /dev/null -w '%{http_code}'` ทุก 5 วิ 2 นาทีสำหรับ app health

### สิ่งที่เจอเพิ่ม (จดไว้สำหรับรอบหน้า)

- **ลำดับ rollout สำคัญ**: prod `zyra-api` เป็น RollingUpdate → pod ใหม่ (300m) **ค้าง Pending ~1 นาที** จนกว่า SFU (Recreate) จะลงและคืน 1500m ให้ node ถึงจะ schedule ได้ — เห็นเป็น `0/1 Pending` ชั่วคราวเป็นเรื่องปกติของ PR นี้ ไม่ใช่ error
- ตอนอ่านค่าทันทีหลัง hard refresh, Argo ยังโชว์ `OutOfSync` อยู่ครู่หนึ่งก่อน sync จริงจะจบ — ต้องรอ `rollout status` ไม่ใช่ตัดสินจาก column เดียว
- ยังไม่ปิด: **item 3 capacity** (node เหลือ headroom 520m ที่ 87% — พอสำหรับ surge pod 500m ของ app rolling update แบบเฉียดฉิว), item 4 profile Next.js, item 5 `probe:` ให้ prod api/ws/notifications
