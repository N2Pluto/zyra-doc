# ใครกิน CPU / RAM บน zyra-k3s — แยกราย service + ตรวจ graceful shutdown (2026-09-24)

> สถานะ: **audit เสร็จ · รอบที่ 2 เพิ่ม preStop sleep 5s ขึ้นแล้วทุก env ([zyra-infra#44](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/44)) — 502 ตอน deploy ลด ~ครึ่ง แต่ยังไม่หมด** — RAM นิ่ง ไม่มี leak · CPU มากกว่าครึ่งเป็นของ platform (k3s/monitoring/traefik/argocd) ไม่ใช่ service ของเรา · graceful shutdown ครบทุก service และไม่มี process ค้าง
> วัดเมื่อ: 2026-09-24 05:12 UTC (12:12 ไทย, livekit participants = 38 ตอนวัด)
> กระทบ: รอบที่ 1 ไม่มี (ตรวจอย่างเดียว) · รอบที่ 2 roll api/app/notifications/ws ทั้ง dev/uat/prod 1 ครั้ง (05:34–05:36 UTC)
> ต่อจาก: [node-saturation-2026-09-18.md](node-saturation-2026-09-18.md) · [node-cpu-burst-argocd-2026-09-22.md](node-cpu-burst-argocd-2026-09-22.md)

## คำถาม

"ทำไม service กิน RAM และ CPU — ทุก service ทำ graceful shutdown หรือเปล่า"

## สรุปสั้น

| คำถาม | คำตอบ | หลักฐาน |
|---|---|---|
| RAM มีปัญหาไหม | **ไม่มี** — 6.5 / 16 GB (39%) นิ่งตลอด 7 วัน ไม่มี OOMKilled | §RAM |
| ใครกิน CPU | platform **58%** · SFU **26%** · service ของเรา 4 ตัวรวมกัน **15%** | §CPU |
| graceful shutdown ครบไหม | **ครบทุก service** · ไม่มี process/pod ค้าง | §Graceful shutdown |
| graceful shutdown เกี่ยวกับ CPU/RAM ไหม | **ไม่เกี่ยว** — ทำงานเฉพาะตอน pod กำลังปิด ไม่มีผลตอนรันอยู่ | — |
| ปัญหาจริงคืออะไร | node 4 core เล็กเกินสำหรับทุกอย่างที่รวมกันอยู่ — peak 3.36/4 core, CPU requests 91%, PSI cpu some 28% | §สถานะ node |

## สถานะ node (ณ 05:12 UTC)

| Metric | ค่า |
|---|---|
| CPU ใช้จริง (`kubectl top node`) | 2235m / 4000m (55%) |
| CPU requests จองแล้ว | **3665m / 4000m (91%)** — เท่ากับหลัง [09-22](node-cpu-burst-argocd-2026-09-22.md) ไม่ขยับ |
| CPU limits | 4100m (102%) |
| load1 / load5 / load15 | 4.29 / 5.55 / 5.92 |
| PSI cpu `some` avg10 / avg60 / avg300 | **28.12% / 27.83% / 28.07%** — 28% ของเวลามี task รอคิว CPU |
| PSI memory | 0.00 ทุกช่วง |
| Memory used / total | 6508 MiB / 15987 MiB · available 9479 MiB · ไม่มี swap |
| peak node busy (5m) ใน 7 วัน | **3.36 core** |
| pod ที่ไม่ใช่ Running/Completed | ไม่มี |

## CPU — แยกรายตัว (เฉลี่ย 24 ชม. ล่าสุด, node busy รวม 1.665 core)

| ใคร | core | สัดส่วน | ประเภท |
|---|---|---|---|
| k3s-server + containerd + OS (host process ไม่ใช่ pod) | 0.551 | **33%** | platform |
| **zyra-sfu** (LiveKit) | 0.431 | **26%** | media |
| monitoring (prometheus 0.123 · promtail 0.053 · grafana 0.025 · loki 0.019 · อื่น ๆ) | 0.244 | 15% | platform |
| zyra-app (Next.js × 2 pod) | 0.160 | 9.6% | service |
| kube-system (traefik, coredns, metrics-server) | 0.097 | 5.8% | platform |
| zyra-ws | 0.058 | 3.5% | service |
| argocd | 0.056 | 3.4% | platform |
| zyra-api | 0.027 | 1.6% | service |
| dev + uat (ทุก service รวมกัน) | 0.024 | 1.4% | non-prod |
| cloudflared + external-secrets + cert-manager | 0.017 | 1.0% | platform |
| zyra-notifications (× 2 pod) | 0.001 | ~0% | service |

- **platform รวม ≈ 0.96 core (58%)** · SFU 0.43 (26%) · service ของเรา (app+api+ws+notif) 0.25 (15%)
- ค่า host 0.551 คำนวณจาก `node busy − ผลรวม CPU ทุก container` — `ps` บน host ตอนวัดเห็น `k3s-server` ~29% ของ 1 core, RSS 2 GB สอดคล้องกัน

### รายวัน 7 วัน (daily avg / daily peak 5m, หน่วย core)

| service | 09-18 | 09-19 | 09-20 (ส.) | 09-21 (อา.) | 09-22 | 09-23 | 09-24 |
|---|---|---|---|---|---|---|---|
| zyra-sfu avg | 0.338 | 0.387 | 0.160 | 0.162 | 0.331 | 0.304 | 0.431 |
| zyra-sfu peak | 1.336 | 1.237 | 0.481 | 1.237 | 1.432 | 1.331 | 1.513 |
| zyra-app avg | 0.143 | 0.128 | 0.066 | 0.075 | 0.147 | 0.123 | 0.160 |
| zyra-app peak | 0.419 | 0.977 | 0.276 | 0.415 | 0.813 | 0.503 | 0.491 |
| zyra-ws avg | 0.055 | 0.049 | 0.040 | 0.037 | 0.053 | 0.045 | 0.058 |
| zyra-api avg | 0.024 | 0.021 | 0.010 | 0.011 | 0.025 | 0.020 | 0.027 |
| zyra-notifications avg | 0.001 | 0.001 | 0.001 | 0.001 | 0.001 | 0.000 | 0.001 |
| host (k3s etc.) avg | 0.505 | 0.514 | 0.594 | 0.502 | 0.534 | 0.412 | 0.551 |
| **node busy avg** | 1.458 | 1.487 | 1.243 | 1.132 | 1.497 | 1.253 | 1.665 |
| livekit participants avg | 21.3 | 18.7 | 9.0 | 10.1 | 19.2 | 18.0 | 21.1 |

CPU ของ SFU/app/ws/api **ขึ้นลงตามคนใช้** (เสาร์-อาทิตย์ลดครึ่ง) — ไม่มีตัวไหนไต่ขึ้นเรื่อย ๆ แบบ leak ส่วน host ~0.5 core คงที่ทุกวันไม่ขึ้นกับจำนวนคน = ค่าโสหุ้ยตายตัวของ k3s

### ทำไม zyra-app (frontend) กิน CPU มากกว่า zyra-api 5–6 เท่า

[`zyra-app/next.config.ts:105`](../../zyra-app/next.config.ts) rewrite `/api/:path*` → `BACKEND_URL` — API call จาก browser ต้องผ่าน Next.js ก่อนถึง zyra-api

| Traefik service (rate 24h) | rps |
|---|---|
| prod-zyra-app | **9.387** |
| prod-zyra-ws | 0.038 |
| sfu-zyra-sfu | 0.025 |
| prod-zyra-api | **0.017** |

API traffic เกือบทั้งหมดเข้าทาง zyra-app แล้วถูก proxy ต่อ — Next.js จึงรับภาระทั้ง SSR + proxy ขณะที่ zyra-api ทำงานจริงแต่เบา
**ข้อนี้อนุมานจาก config + สัดส่วน traffic — ยังไม่ได้ profile Next.js จริง** ว่า proxy กินกี่ % เทียบกับ SSR/middleware

## RAM — นิ่ง ไม่มี leak

| Metric | 7 วันก่อน | ตอนนี้ | max 7 วัน |
|---|---|---|---|
| node memory used | 6336 MiB | 6499 MiB | 6690 MiB |

working set ของตัวใหญ่ (MiB):

| container | 7 วันก่อน | ตอนนี้ | max 7 วัน | limit |
|---|---|---|---|---|
| prometheus | 761 | 719 | 998 | — |
| argocd application-controller | 365 | 544 | 617 | 1Gi (ตั้ง 09-22) |
| grafana | 185 | 190 | 498 | — |
| loki | 115 | 158 | 169 | — |
| k3s-server (host, จาก `ps`) | — | ~1980 (RSS) | — | — |

service ของเรา (daily max, MiB):

| service | 09-18 | 09-19 | 09-20 | 09-21 | 09-22 | 09-23 | 09-24 | limit |
|---|---|---|---|---|---|---|---|---|
| zyra-sfu | 374 | 391 | 130 | 442 | 533 | 533 | 489 | 3Gi |
| zyra-app (2 pod รวม) | 284 | 286 | 243 | 280 | 310 | 261 | 288 | — |
| zyra-api | 58 | 84 | 46 | 51 | 53 | 48 | 50 | 512Mi |
| zyra-ws | 20 | 19 | 14 | 18 | 19 | 20 | 21 | 512Mi |
| zyra-notifications (2 pod รวม) | 20 | 20 | 16 | 17 | 17 | 19 | 17 | 128Mi/pod |

- `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}` = **ว่าง** (ไม่มีใครโดน OOM)
- ตัวกิน RAM อันดับต้นเป็น platform ทั้งหมด (k3s-server, prometheus, argocd controller, grafana) — service ของเรารวมกัน ~600 MiB

## Graceful shutdown — ครบทุก service

| Service | จัดการ SIGTERM | timeout | ที่ |
|---|---|---|---|
| zyra-api | `signal.NotifyContext` → `FlushObstacleRepublishes()` → `server.Shutdown` → `wg.Wait()` (background loop 10 ตัว) | 10s | `zyra-api/main.go:390-462` |
| zyra-ws | `h.Drain()` (ส่ง `server_shutdown` ให้ client reconnect) → sleep 3s → `srv.Shutdown` | 3s + 10s | `zyra-ws/main.go:148-167` |
| zyra-notifications | `signal.NotifyContext` → `server.Shutdown` | 5s | `zyra-notifications/main.go:75-84` |
| zyra-app | Next.js 16.2.4 handler ในตัว (`start-server.js` — `server.close()` → `nextServer.close()` → exit 143) · Dockerfile `CMD ["node","server.js"]` เป็น exec form จึงรับ signal ตรงในฐานะ PID 1 | ไม่กำหนด (ถูกคุมด้วย grace period 30s) | `zyra-app/Dockerfile:107` |
| zyra-sfu | LiveKit จัดการเอง | — | — |

- Helm chart (`zyra-infra/gitops/charts/zyra-service/templates/deployment.yaml`) **ไม่ได้ตั้ง `terminationGracePeriodSeconds`** → ใช้ default 30s ซึ่งยาวกว่า timeout ของทุก service (ยาวสุดคือ ws ~13s) — ปิดตัวเองทันก่อนโดน SIGKILL
- ไม่มี `preStop` hook — ไม่กระทบ CPU/RAM แต่อาจมี request ไม่กี่ตัวหลุดไปถึง pod ที่กำลังปิดตอน deploy (endpoint ถูกถอดพร้อมกับที่ส่ง SIGTERM) — ไม่ได้วัดว่าเกิดจริงไหม

### ไม่มี process ค้าง (ตรวจบน host)

| binary | จำนวน process | pod ที่ควรมี |
|---|---|---|
| `next-server` | 4 | prod 2 + dev 1 + uat 1 = 4 ✅ |
| `server` (zyra-api) | 3 | prod + dev + uat = 3 ✅ |
| `zyra-ws` | 3 | prod + dev + uat = 3 ✅ |
| `zyra-notifications` | 4 | prod 2 + dev 1 + uat 1 = 4 ✅ |
| `livekit-server` | 1 | sfu 1 ✅ |

`kubectl get pods -A` ไม่มี pod ค้าง Terminating · prod `zyra-app` 2 pod restart = 0 (สร้างใหม่ 2026-09-23 10:40 UTC ตอน deploy v1.6.1)

## ทางเลือกถ้าจะลด CPU (ยังไม่ได้ทำ — รอตัดสินใจ)

| ทางเลือก | ลดได้ | ต้นทุน / ความเสี่ยง |
|---|---|---|
| 1. ขยาย node / แยก media node ตาม [capacity plan](../web/media-node-capacity-plan/) | แก้ตรงจุดที่สุด — ปัญหาคือ node เล็ก ไม่ใช่ service ผิดปกติ | ค่าใช้จ่าย + VM recreate (ติด terraform state ที่อยู่บนเครื่อง `hashtagf`) |
| 2. ให้ browser เรียก API ตรงที่ zyra-api ไม่ผ่าน Next.js rewrite | น่าจะลด CPU zyra-app ได้ส่วนหนึ่ง — **ยังไม่ได้วัด** | ต้องแก้ CORS, cookie domain, auth flow ทั้งฝั่ง app/api |
| 3. ลดโสหุ้ย monitoring (scrape interval, promtail) | ~0.24 core มีช่องให้ลดบางส่วน | เสีย resolution ของ metric/log |

## วัดยังไง

- **Live snapshot**: SSH เข้า `zyra-k3s` ผ่าน IAP (`gcloud compute ssh zyra-k3s --zone asia-southeast1-b --project gather-dev-458614 --tunnel-through-iap`) → `uptime`, `cat /proc/pressure/{cpu,memory}`, `free -m`, `kubectl top node/pod -A`, `kubectl describe node | grep -A8 'Allocated resources'`, `ps -eo pcpu,rss,comm`, `ps -eo comm | sort | uniq -c`
- **Prometheus**: `kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 19090:9090` บน VM แล้ว `curl /api/v1/query{,_range}` — query หลัก:
  - CPU ราย service: `sum by (svc)(label_replace(rate(container_cpu_usage_seconds_total{namespace=~"prod|sfu",container!="",container!="POD"}[1d]),"svc","$1","pod","(.*)-[a-z0-9]+-[a-z0-9]+"))` (chart ตั้งชื่อ container ว่า `app` ทุก service จึงต้องแยกด้วยชื่อ pod)
  - host overhead: `sum(rate(node_cpu_seconds_total{mode!="idle"}[1d])) - sum(rate(container_cpu_usage_seconds_total{container!="",container!="POD"}[1d]))`
  - RAM: `container_memory_working_set_bytes`, `node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes`
  - traffic: `sum by (service)(rate(traefik_service_requests_total[24h]))`
- **ช่วงเวลา**: 2026-09-18 ถึง 2026-09-24 05:12 UTC — Prometheus retention = **1w** (`storage.tsdb.retention.time`) ข้อมูล 09-17 ไม่ครบ จึงตัดทิ้ง เทียบย้อนหลังไกลกว่านี้ไม่ได้
- **โค้ด**: อ่าน shutdown path ของทุก `main.go`, Dockerfile, `node_modules/next/dist/server/lib/start-server.js` (Next 16.2.4), Helm chart template
- script ชั่วคราวบน VM (`/tmp/prom*.sh`) ลบแล้วหลังดึงข้อมูล

## รอบที่ 2 — 2026-09-24 · เพิ่ม preStop sleep 5s ([zyra-infra#44](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/44))

- **ทำอะไร:** เพิ่ม `preStopSleepSeconds` (opt-in) ใน chart `zyra-service` → render เป็น `lifecycle.preStop.sleep.seconds` (native, ไม่ต้องมี binary — ws/notifications เป็น distroless) · ตั้ง 5s ให้ api/app/notifications/ws ทั้ง dev/uat/prod (12 Deployment) · SFU ไม่ใส่
- **ถึงไหน:** merge 05:31:54 UTC → Argo sync ~05:34 → rollout ครบ 12/12 เวลา 05:36:03 · Argo ทุกตัว Synced/Healthy · SFU ไม่ถูกแตะ · livekit participants ตอน merge = 33
- **verify ถึงไหน:** ก่อน merge — template-only render เหมือนเดิมทุกไบต์, rendered diff = lifecycle block × 12, `kubectl apply --dry-run=server` ผ่าน 12/12 · หลัง merge — lifecycle อยู่ใน spec ครบ 12/12, ไม่พบ event `FailedPreStopHook` · **ยังไม่ได้ยืนยัน exit code** ของ pod เก่า (watcher จับ terminated state ไม่ทันก่อน pod ถูกลบ)

| Metric (prod, `increase(traefik_service_requests_total{service=~"prod-.*",code=~"5.."}[5m])`) | Before — deploy v1.6.1 (09-23 10:39–10:44 UTC, app อย่างเดียว) | After — rollout นี้ (09-24 05:33–05:37 UTC, 4 service) |
|---|---|---|
| 5xx รวม | 25.6 | **15.5** |
| 502 | 25.6 | **12.2** (-52%) |
| 500 / 504 | 0 / 0 | 2.2 / 1.1 |
| request รวม 5 นาที | 5,735.6 | 5,677.8 |
| baseline 5xx ช่วงไม่มี deploy | 0 ต่อ 5m (05:12/05:22/05:27/05:32 UTC) · เฉลี่ย 24 ชม. 0.21 ต่อ 5m | — |

เทียบกันไม่ตรง 100% (รอบก่อน roll แค่ zyra-app, รอบนี้ roll 4 service พร้อมกัน) · ค่าเป็น extrapolation ของ `increase()`

- **ต่อจากนี้:** ยังมี 502 ~12 ครั้งต่อ rollout — preStop แก้ได้ราวครึ่ง สาเหตุที่เหลือยังไม่ยืนยัน (สมมติฐาน: Traefik reuse keep-alive connection กับ pod ที่กำลังปิด · zyra-app `maxSurge: 0` เหลือ 1 pod + proxy `/api` ไป zyra-api ที่ roll พร้อมกัน) · deploy ครั้งหน้าให้ดัก exit code (0/143 vs 137)
- **ติดอะไร:** ไม่มี
