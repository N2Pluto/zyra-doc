# NodeSystemSaturation บน zyra-k3s — SFU กิน CPU โตขึ้น 2 เท่าใน 3 วัน จน zyra-app p95 แย่ลง 9 เท่า (2026-09-18)

> สถานะ: **วินิจฉัยเสร็จ · ข้อ 1 (camera 1080p→720p) live บน dev และ uat แล้ว ([#423](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/423) → [#424](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/424)) — ยังไม่ tag ขึ้น prod จึงยังไม่มีตัวเลข after** · ทางเลือกอื่นยังไม่ได้ทำ — ยืนยันแล้วว่า alert เป็นของจริงและกระทบ user (zyra-app p95 99ms → 866ms ใน 3 วัน ที่ rps เท่าเดิม) · ต้นเหตุคือ node 4 core เต็ม ไม่ใช่บั๊กในโค้ด (SFU ไม่ได้เปลี่ยนตั้งแต่ 2026-08-25) · **รอตัดสินใจ capacity** — เป็น item 3 ของ [prod-app-crashloop-2026-09-10.md](prod-app-crashloop-2026-09-10.md) ที่ค้างมาตั้งแต่ 8 วันก่อน ตอนนี้ไม่ใช่ความเสี่ยงแล้ว แต่กระทบจริง
> กระทบ: prod `app.zyraworld.co` (latency) · ทุก workload บน node `zyra-k3s` (10.148.0.18) · zyra-infra (`terraform/variables.tf` k3s_machine_type)
> ต่อจาก: [prod-app-crashloop-2026-09-10.md](prod-app-crashloop-2026-09-10.md) item 3 · [livekit-sfu-capacity-2026-08-20.md](livekit-sfu-capacity-2026-08-20.md)

## อาการ

Alert `NodeSystemSaturation` (severity warning) จาก kube-prometheus-stack ดังที่ node `10.148.0.18:9100`

```
node_load1 / จำนวน core  >  2   ติดต่อกัน 15 นาที
```

ค่า ณ เวลาตรวจ (18:00 ICT) = **2.56** บน node 4 core (load1 10.4 / load5 10.53 / load15 11.7)
และ **21.1% ของ 12 ชม.ล่าสุดอยู่เหนือเกณฑ์** — ไม่ใช่ spike ครั้งเดียว

## ไม่ใช่อะไร (ตัดทิ้งด้วยตัวเลข)

| สมมติฐาน | ค่าที่วัดได้ | สรุป |
|---|---|---|
| Disk / I/O ช้า | `iowait` **0.004 cores (0.1%)** · `node_procs_blocked` ~0.0 | ❌ ตัดทิ้ง |
| Memory เต็ม / swap | ใช้ **39.8%** ของ 15.6 GiB · PSI memory waiting 0.0 | ❌ ตัดทิ้ง |
| โดน CFS throttle | **0.00%** ทุก pod รวม SFU (limit 2500m, ใช้จริง 1095m) | ❌ ตัดทิ้ง |
| SFU goroutine leak กลับมา | peak วันนี้ **4,315** (ส.ค. เคยถึง 28,633) · working set 301 MiB จาก limit 3 Gi | ❌ คุมอยู่ — PR #164 + nightly restart ทำงาน |
| Noisy neighbour (GCE steal) | steal 0.019 → 0.095 cores | ⚠️ ขึ้น 5 เท่าแต่ยังเล็ก ไม่ใช่ตัวหลัก |

**เป็น CPU run-queue ล้วน ๆ**: `node_procs_running` เฉลี่ย **12–17 บน 4 core**, PSI cpu waiting **0.404** (40% ของเวลามี task รอ CPU)

> สังเกต: node busy แค่ 2.62 cores (idle 28.6%) แต่ load1 ~10 — ต่างกัน 3.7 เท่า
> เป็นลายเซ็นของ workload ที่ปลุก thread จำนวนมากพร้อมกันเป็นจังหวะสั้น ๆ (timer ต่อ packet ของ LiveKit ทุก 20ms)
> แล้วหลับหมด ไม่ใช่ CPU ตันแบบต่อเนื่อง — load average จับ burst พวกนี้ ส่วน utilization เฉลี่ยกลบมันหายไป

## ใครกิน CPU (ชั่วโมงเดียวกัน 17:00 ทั้ง 3 วัน)

| namespace | 09-16 | 09-17 | **09-18** |
|---|---|---|---|
| **sfu** | 0.525c | 0.669c | **1.095c** |
| prod (app+api+ws+notif) | 0.283c | 0.420c | 0.447c |
| monitoring | 0.172c | 0.211c | 0.253c |
| kube-system | 0.112c | 0.150c | 0.170c |
| argocd | 0.044c | 0.053c | 0.061c |
| dev + uat | 0.034c | 0.019c | 0.020c |
| **node busy รวม** | **1.50c** | **1.98c** | **2.62c** |

SFU = **42% ของ CPU ที่ node ใช้จริง / 58% ของ container CPU ทั้งหมด** — อันดับ 2 คือ prometheus ที่ 0.147c ห่างกัน 7 เท่า

## ทำไม SFU โตขึ้น — ไม่ใช่โค้ด แต่เป็น video fan-out

โค้ด zyra-sfu ล่าสุดคือ `2691f97` (2026-08-25, turn over tls) — **ไม่ได้เปลี่ยนมา 3 สัปดาห์** และ `values.yaml` แตะครั้งสุดท้าย 09-17 (reloadOnChange, ไม่เกี่ยว CPU)

ที่เปลี่ยนคือ workload:

| 17:00 | 09-14 | 09-15 | 09-16 | 09-17 | **09-18** |
|---|---|---|---|---|---|
| participants | 40 | 28 | 46 | 43 | **50** |
| published AUDIO | 30.4 | 19.0 | 32.9 | 33.5 | 39.0 |
| published VIDEO | 10.1 | 1.7 | 4.2 | 6.4 | **13.6** |
| subscribed AUDIO | 149.8 | 105.6 | 132.6 | 141.8 | 188.5 |
| **subscribed VIDEO** | 49.6 | 5.1 | 10.2 | 10.7 | **80.0** |
| outgoing | 18.96 Mbps | 2.19 Mbps | 12.29 Mbps | 11.16 Mbps | 18.79 Mbps |
| SFU cores | 0.521 | 0.249 | 0.525 | 0.669 | **1.095** |

**subscribed VIDEO กระโดด 10.7 → 80.0 ในวันเดียว** (13.6 publisher × ~6 subscriber = fan-out 80 เส้น)
ต่างจาก audit [2026-08-20](livekit-sfu-capacity-2026-08-20.md) ที่วัดได้ **0 VIDEO tracks** — ตอนนั้นสรุปว่า CPU ไม่ได้มาจาก media forwarding **ข้อสรุปนั้นหมดอายุแล้ว** วันนี้มี video จริง

> **ข้อควรระวัง — video ไม่ได้อธิบายได้ทั้งหมด**: 09-14 มี subscribed VIDEO 49.6 ที่ 18.96 Mbps (egress พอ ๆ กับวันนี้)
> แต่ใช้แค่ 0.521 cores เทียบกับ 1.095 วันนี้ แปลว่ายังมีตัวแปรอื่นร่วมอยู่ — ตัวที่น่าสงสัยคือ join churn
> (joins/person/hr วันนี้ 17.6 เทียบ 09-14 ที่ 14.1) ซึ่งเป็นกลไกเดิมจาก [audit ส.ค.](livekit-sfu-capacity-2026-08-20.md)
> **ยังไม่ได้แยกสัดส่วนว่า video กับ churn อย่างละเท่าไหร่** — ต้องวัดเพิ่มถ้าจะ optimize แทนที่จะขยาย node

## ผลกระทบต่อ user (prod, ชั่วโมงเดียวกัน 17:00)

| Metric | 09-15 | 09-16 | 09-17 | **09-18** |
|---|---|---|---|---|
| **zyra-app p95** | 99.9ms | 98.6ms | 484.9ms | **865.7ms** |
| zyra-app p99 | 2054.7ms | 885.4ms | 3671.1ms | **4000.0ms** |
| zyra-api p95 | 95.0ms | 95.0ms | 95.0ms | 95.5ms |
| rps (prod รวม) | 16.9 | 17.9 | 19.7 | 18.9 |
| 5xx | 0.000% | 0.000% | 0.001% | 0.015% |
| node load1 | 1.58 | 3.46 | 4.51 | **9.65** |
| participants | 28 | 46 | 43 | 50 |

**zyra-app p95 แย่ลง ~9 เท่าใน 3 วัน ที่ request rate เท่าเดิม** — zyra-api (Go) ยังนิ่งที่ 95ms
ตรงกับลักษณะของ Next.js SSR ที่เป็น CPU-bound และโดนแย่ง CPU ก่อนใคร (เหมือนเคสวันที่ [09-10](prod-app-crashloop-2026-09-10.md) ที่หนักกว่านี้จน probe ฆ่า pod)

> ข้อจำกัดของตัวเลข: Traefik ใช้ histogram bucket default `[0.1, 0.3, 1.2, 5.0]` ค่า 95ms = "ต่ำกว่า 100ms"
> และ 4000ms = "อยู่ใน bucket 1.2–5.0s" ความละเอียดหยาบ แต่ทิศทางและขนาดของการเปลี่ยนแปลงชัดเจน

## Before/After

ยังไม่มี "after" — **ยังไม่ได้แก้อะไร** ตารางนี้คือ baseline สำหรับวัดผลหลังตัดสินใจ capacity

| Metric | Before (09-16 17:00) | ปัจจุบัน (09-18 17:00) | Δ | เป้าหมายหลังแก้ |
|---|---|---|---|---|
| node load1 (1h avg) | 3.46 | 9.65 | **+179%** | < 8.0 (load/core < 2) |
| load per core | 0.87 | 2.41 | +177% | < 2.0 (ไม่ดัง alert) |
| zyra-app p95 | 98.6ms | 865.7ms | **+778%** | กลับไป < 150ms |
| zyra-app p99 | 885.4ms | 4000.0ms | +352% | < 1200ms |
| SFU cores | 0.525 | 1.095 | +109% | (ไม่ใช่เป้า — เป็น workload จริง) |
| node busy | 1.50c | 2.62c | +75% | < 50% ของ core ที่มี |
| 5xx rate | 0.000% | 0.015% | +0.015pp | 0.000% |
| node cpu requests | 3480m / 4000m (87%) | 3480m / 4000m (87%) | — | < 70% |

**วัดยังไง**: PromQL ผ่าน Grafana datasource proxy (uid `prometheus`) — expr ทั้งหมดอยู่ท้ายไฟล์
**ช่วงเวลาที่วัด**: instant query ที่ `17:00` ของแต่ละวัน ด้วย range `[1h]` (เทียบชั่วโมงเดียวกันเพื่อคุมผลของ daily pattern)
**แหล่งข้อมูล**: Prometheus บน zyra-k3s ผ่าน tunnel ตาม [วิธีเข้าถึง](grafana-optimize-2026-08-20.md) — ไม่ได้ใช้ค่าจากความจำ

## ทางเลือกระยะสั้น — ก่อนตัดสินใจขยาย node

### หลักฐานใหม่: ingest มากกว่า egress (18:15 ICT)

```
incoming  25.88 Mbps  /  4,243 pps     ← SFU รับเข้า
outgoing  18.79 Mbps  /  6,985 pps     ← SFU ส่งออก
subscribed VIDEO 77 เส้น → 378.7 kbps ต่อเส้น
```

**SFU รับ 25.9 Mbps เพื่อส่งออกแค่ 18.8 Mbps** — รับมากกว่าส่ง ทั้งที่ปกติ SFU ต้องขยาย (1 publisher → หลาย subscriber)
แปลว่า publisher อัป simulcast ladder เต็มขึ้นมาแล้ว **SFU ทิ้งเลเยอร์บนเกือบทั้งหมด** เพราะ `adaptiveStream`
เห็นว่า tile ใน VO เล็ก เลยให้ subscriber กินแค่เลเยอร์ ~379 kbps

ต้นทาง: `zyra-app/lib/api/sfu-client.ts:422-426` ตั้ง camera ไว้ที่ **1080p30 / ~3 Mbps**

```ts
videoCaptureDefaults: {
  resolution: VideoPresets.h1080.resolution, // 1920×1080 @ 30fps
},
publishDefaults: {
  videoEncoding: VideoPresets.h1080.encoding, // ~3 Mbps @ 30fps max
```

เลเยอร์บนสุดนั้น **แทบไม่มีใคร subscribe** แต่ SFU ต้องรับ depacketize ทุก packet ของมันอยู่ดี — เป็น CPU ต่อ publisher ที่จ่ายฟรี
มีบรรทัดฐานอยู่แล้ว: ทีมเคยตัด screen share `1080p60` ทิ้งด้วยเหตุผลเดียวกันเมื่อ 2026-08-21 (comment ที่ `sfu-client.ts:128-131`)

### เรียงตามผลต่อ CPU ต่อความเสี่ยง

| # | ทำอะไร | แตะที่ไหน | ผลที่คาด | ความเสี่ยง |
|---|---|---|---|---|
| 1 | **camera 1080p30 → 720p30 (หรือ 540p)** | `zyra-app/lib/api/sfu-client.ts:422-426` | ลด ingest ต่อ publisher จาก ~3 Mbps → ~1.7 Mbps (720p) / ~0.8 Mbps (540p) · ลด packet ที่ SFU ต้อง process ตรง ๆ | **ต่ำ** — 2 บรรทัด, revert ง่าย, ไม่แตะ infra · VO tile เล็กอยู่แล้วจึงแทบไม่เห็นความต่าง |
| 2 | ลด Prometheus (scrape interval / retention / drop series ที่ไม่ใช้) | `zyra-infra` observability | prometheus = **0.172c** เป็นตัวกินอันดับ 2 รองจาก SFU · คาดคืน ~0.08-0.10c | ต่ำ — เสีย resolution ของ metric เอง (ซึ่งกำลังใช้ debug อยู่) |
| 3 | ย้าย dev + uat ออกจาก node prod | `zyra-infra` gitops | คืน **requests 80m** (ช่วย scheduling headroom) แต่ CPU จริงแค่ 0.020c | ต่ำ — แต่ผลน้อยมาก |
| 4 | ย้าย `/api/img` + `/_next/image` ไป CDN/R2 ตรง | zyra-app (มี `NEXT_PUBLIC_CDN_URL` อยู่แล้ว) | ตัด CPU ของ Next server ที่ proxy asset ให้ทุก client — ตีตรงที่ p95 ที่แย่ | กลาง — ต้องเปิด CORS ที่ bucket · เป็น [item 4 ของ 09-10](prod-app-crashloop-2026-09-10.md) ที่ยังค้าง |
| 5 | **ขยาย `e2-standard-4` → `e2-standard-8`** | `zyra-infra/terraform/variables.tf:320` | แก้ทั้ง load และ request pressure จบในช็อตเดียว | +$120/เดือน · **downtime ทั้ง cluster ~5 นาที** ต้องทำนอกเวลางาน |

**ประเมินตรง ๆ**: ข้อ 1 เป็นตัวเดียวในกลุ่ม 1-4 ที่มีโอกาสขยับเข็มพอ (SFU = 42% ของ CPU ที่ node ใช้จริง)
ข้อ 2-3 รวมกันคืนได้ ~0.1c จากปัญหาขนาด 2.62c — ช่วยแต่ไม่พอเดี่ยว ๆ
ข้อ 4 ไม่ลด load ของ node แต่ตีตรงอาการที่ user เจอ (p95 ของ app)

**ยังไม่ได้วัดว่าข้อ 1 คืน CPU เท่าไหร่จริง** — ต้อง deploy แล้ววัด ingest Mbps + SFU cores เทียบก่อน/หลัง
ห้ามสรุปว่า "พอแล้ว" จากการเดา ([18-before-after-metrics](../../.claude/rules/18-before-after-metrics.md))

## ยังไม่ปิด / ต้องตัดสินใจ

node `zyra-k3s` เป็น `e2-standard-4` (4 vCPU / 15.6 GiB) แบก **prod + uat + dev + monitoring + argocd + SFU** ทั้งหมด
`terraform/variables.tf:319` เขียนไว้เองว่า *"bump if room load grows"* — ตอนนี้คือจุดนั้น

1. **ขยาย `k3s_machine_type` → `e2-standard-8`** — ตรงที่สุด แก้ทั้ง load และ request pressure ในช็อตเดียว
   ต้นทุน ≈ **+$120/เดือน** · ต้อง stop VM = **downtime ทั้ง cluster ~5 นาที ทำนอกเวลางาน** (ประเมินไว้ตั้งแต่ [09-10 item 3](prod-app-crashloop-2026-09-10.md))
2. **แยก SFU ไป node ของตัวเอง** — แพงกว่า แต่กัน media plane ไม่ให้เบียด web/api ถาวร
   ตรงกับเจตนาที่เขียนไว้ใน `gitops/envs/prod/services/sfu/values.yaml` แล้วว่า *"SFU ต้องพังก่อน web/api"* (cpu limit 2500m) — แยก node คือทำให้เจตนานั้นจริงแทนที่จะพึ่ง limit
3. **ลด workload แทนขยาย** — ต้องรู้ก่อนว่า video fan-out ที่โต 7.5 เท่าเป็นของถาวรไหม (ฟีเจอร์ใหม่? พฤติกรรมเปลี่ยน?)
   ถ้าถาวร → ข้อ 1/2 หนีไม่พ้น · ถ้าชั่วคราว → รอดูอีก 2-3 วันก่อนจ่ายเงินได้
4. **แยกสัดส่วน video vs join churn** (ดูกล่องเตือนข้างบน) — ถ้า churn เป็นตัวใหญ่ การ debounce เพิ่มถูกกว่าขยาย node มาก

ข้อ 1 และ 2 เป็น production change — **ต้อง confirm กับผู้ใช้ก่อนทำเสมอ** ([17-git-branch-workflow](../../.claude/rules/17-git-branch-workflow.md))

## วิธี reproduce การตรวจนี้

ต้องมี tunnel ไป Grafana ก่อน (ดู [grafana-optimize-2026-08-20.md](grafana-optimize-2026-08-20.md) §วิธี reproduce) แล้ว:

```bash
KEY=<grafana-sa-token>
B=http://localhost:3000/api/datasources/proxy/uid/prometheus/api/v1
q() { curl -s -H "Authorization: Bearer $KEY" -G "$B/query" --data-urlencode "query=$1" -d "time=$2"; }
```

| อยากรู้ | PromQL |
|---|---|
| ค่า alert ตรง ๆ | `node_load1{job="node-exporter"} / count without (cpu,mode) (node_cpu_seconds_total{job="node-exporter",mode="idle"})` |
| CPU แยก mode (ตัด iowait) | `sum by (mode) (rate(node_cpu_seconds_total[5m]))` |
| run queue จริง | `node_procs_running` / `node_procs_blocked` |
| CPU ต่อ namespace | `sum by (namespace) (rate(container_cpu_usage_seconds_total{container!="",container!="POD"}[1h]))` |
| โดน throttle ไหม | `rate(container_cpu_cfs_throttled_periods_total[5m]) / rate(container_cpu_cfs_periods_total[5m])` |
| video fan-out | `sum(livekit_track_subscribed_total{kind="VIDEO"})` · `sum(livekit_track_published_total{kind="VIDEO"})` |
| join churn | `sum(rate(livekit_participant_join_total[1h]))*3600` |
| p95 ต่อ service | `histogram_quantile(0.95, sum by (le) (rate(traefik_service_request_duration_seconds_bucket{service="prod-zyra-app-80@kubernetes"}[1h])))` |
| requests ที่จองไว้ (นับเฉพาะ Running) | `sum(kube_pod_container_resource_requests{resource="cpu"} * on(pod,namespace) group_left kube_pod_status_phase{phase="Running"})` |

> กับดัก: `sum(kube_pod_container_resource_requests{resource="cpu"})` เฉย ๆ จะนับ pod ที่จบแล้วด้วย
> (`zyra-sfu-nightly-restart-*` ที่ Completed ค้างอยู่ 3 ตัว) ได้ 3.81 cores แทนที่จะเป็น **3.480 (87%)** ของจริง
> ต้อง join กับ `kube_pod_status_phase{phase="Running"}` เสมอ

---

## รอบที่ 2 — 2026-09-18 18:20 ICT (ลงมือข้อ 1)

ผู้ใช้สั่งเริ่มจากข้อ 1 ก่อน (ขยาย node เป็นทางเลือกสุดท้าย)

**ทำอะไร**: `zyra-app` branch `fix/vo-camera-capture-cap` commit `f31ffd0` —
`lib/api/sfu-client.ts:438-443` เปลี่ยน `videoCaptureDefaults.resolution` และ
`publishDefaults.videoEncoding` จาก `VideoPresets.h1080` (~3 Mbps) → `h720` (~1.7 Mbps)
พร้อมแก้ mock `VideoPresets` ใน test 6 ไฟล์ให้ตรงกับ preset ที่โค้ดอ่านจริง

เลือก **720p ไม่ใช่ 540p** เพราะ ladder ยังเหลือ 720/360/180 ซึ่งครอบ spotlight main stage
(surface เดียวของกล้องที่ขยายใหญ่ได้) — 540p ประหยัดกว่าเท่าตัวแต่เสี่ยงเห็นความต่างตรงนั้น
ถ้าวัดแล้ว 720p คืน CPU ไม่พอค่อยลง 540p เป็นขั้นถัดไป

**ถึงไหน**: [PR #423](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/423) merge เข้า `develop` แล้ว (merge commit `5e7ae0d`, ผู้ใช้ merge เองจาก GitHub 18:20 ICT) → **live บน dev แล้ว** · **ยังไม่ขึ้น uat/prod**

**verify ถึงไหน** (แยก build เขียว ออกจาก live-test):
- ✅ `vitest run` เต็มชุด: **179 files / 2,471 passed / 3 skipped** (ก่อนแก้ mock มี 37 fail — mock เดิม stub แค่ `h1080` ทำให้ `h720.resolution` เป็น undefined)
- ✅ `eslint` + `prettier --check` บนไฟล์ที่แก้ทั้ง 7: สะอาด
- ✅ `next build`: ผ่าน
- ⚠️ `tsc --noEmit`: เหลือ error 7 ตัวใน `__tests__/` (weather-fx, pet-creation-wizard, pixi-game-scene) — **มีอยู่ก่อนแล้ว** ยืนยันด้วย `git stash` แล้วรันบน develop สะอาดได้ error ชุดเดียวกันเป๊ะ ไม่เกี่ยวกับ commit นี้
- ✅ CI บน PR เขียวครบ 6 ตัว (CodeRabbit · e2e-parse · lint-and-build · summary · visual-regression · vitest-coverage)
- ✅ deploy chain ครบ: CI push `web:dev-5e7ae0d` → gitops commit `52d6541` bump `envs/dev/services/app/values.yaml` → Argo sync → pod `zyra-app-5cfddf6895-cq8t5` รัน image นั้นจริง (ยืนยันด้วย `kube_pod_container_info`)
- ❌ **ยังไม่มีตัวเลข after** — dev แทบไม่มีผู้ใช้ จึงวัด SFU ingest/CPU ไม่ได้เลย บน dev ตรวจได้แค่ว่ากล้องยังทำงานและภาพยังคมพอ ตัวเลขจริงต้องรอ prod

**ต่อจากนี้**: push → PR → merge เข้า `develop` (deploy dev อัตโนมัติ) → verify บน dev → ค่อยขึ้น uat/prod ตาม [17-git-branch-workflow](../../.claude/rules/17-git-branch-workflow.md)

### Baseline สำหรับวัดผลข้อ 1 (เก็บไว้ 18:15 ICT ก่อน deploy)

| Metric | Before | After (รอวัด) |
|---|---|---|
| SFU incoming | **25.88 Mbps** / 4,243 pps | — |
| SFU outgoing | **18.79 Mbps** / 6,985 pps | — |
| ingest ต่อ video publisher | **1.99 Mbps** (upper bound, รวม audio) | — |
| SFU cores | **1.095c** | — |
| node load1 | **9.65** (1h avg @17:00) | — |
| zyra-app p95 | **865.7ms** | — |

**วัดยังไง**: PromQL ชุดเดียวกับตาราง "วิธี reproduce" ท้ายไฟล์
**เงื่อนไขการเทียบ**: ต้องเทียบชั่วโมงเดียวกัน (17:00-18:00) และตรวจว่า participants อยู่ในช่วงใกล้กัน (~40-50)
ไม่งั้นตัวเลขไม่มีความหมาย — ถ้าวันที่วัดคนน้อยกว่ามากให้รอวันที่ traffic ใกล้เคียง

**ติดอะไร**: ยังไม่รู้ว่า 720p คืน CPU ได้เท่าไหร่จริง — ห้ามสรุปว่า "พอแล้ว" จนกว่าจะมีตัวเลข after
ถ้าคืนไม่พอ ลำดับถัดไปคือ 540p → ข้อ 2/3 → แล้วค่อยขยาย node

---

## รอบที่ 3 — 2026-09-20 20:05 ICT (ขึ้น uat)

**ทำอะไร**: [PR #424](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/424) `develop` → `main` merge commit `d3cf3ac`
ยกขึ้น uat 2 commit (ไม่ใช่แค่ตัวเดียว): `f31ffd0` camera cap + `fcd813f` mic/camera failure toast ([#422](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/422))

**verify ถึงไหน**:
- CI บน `main` เขียวครบ 3 workflow (CI web / CI web test reporting / Deploy GitOps)
- gitops commit `ad4b39a` bump `envs/uat/services/app/values.yaml` -> `tag: uat-d3cf3ac`
- **uat live จริง**: `GET https://app.uat.zyra.center/api/health` -> `{"status":"ok","version":"uat-d3cf3ac"}` ตรงกับ merge commit
- **ยังไม่มีตัวเลข after** - uat แชร์ node เดียวกับ prod และแทบไม่มีผู้ใช้ วัด SFU ingest/CPU ไม่ได้
- ยังไม่มีใครลองเปิดกล้องบน uat ดูว่า 720p คมพอไหม (โดยเฉพาะ spotlight main stage)

**ติดอะไร - 2 อย่างที่บล็อกการวัดผลรอบหน้า**:

1. **GitHub Actions ล่มทั้งวัน 2026-09-19** - ทุก job fail ใน 2-3 วินาทีโดยไม่รัน step สักตัว (`"steps": []`)
   รวม `Server Health Monitor` ที่เป็น schedule ทุก 6 ชม. ซึ่งวันนั้น**ไม่ถูก queue เลยแม้แต่รอบเดียว**
   ตอนแรกเดาว่า Actions minutes หมด/spending limit - **เดาผิด** วันที่ 20 กลับมาเองโดยไม่มีใครแก้อะไร
   น่าจะเป็น incident ชั่วคราวของ GitHub - ระหว่างนั้น prod ปกติดี (`app`/`api` ตอบ 200 ที่ ~0.18s ทั้งคู่ เช็คตรงไม่ได้เชื่อ monitor)
   **บทเรียน**: job ที่ fail เร็วผิดปกติ + `steps: []` = runner ไม่ได้เริ่ม ไม่ใช่โค้ดพัง อย่าไปไล่แก้โค้ด

2. **เข้า Prometheus ไม่ได้ตอนนี้** - gcloud credentials หมดอายุ (`gcloud auth login` ต้องทำเอง)
   tunnel เปิดไม่ได้ -> วัด before/after บน prod ไม่ได้จนกว่าจะ re-auth
   (system git ในเครื่องก็ใช้ไม่ได้ ติด Xcode license - เลี่ยงด้วย `gh --repo` ที่ไม่พึ่ง git)

**ต่อจากนี้**: ให้คนลองเปิดกล้องบน uat ดูคุณภาพภาพก่อน -> ถ้าผ่าน tag `v*` บน `main` ขึ้น prod (ต้อง confirm) -> วัด after ที่ 17:00-18:00 ตอน participants 40-50 เทียบกับ baseline ในรอบที่ 2
