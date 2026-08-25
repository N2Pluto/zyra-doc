# Grafana Mission Control — Optimization Audit (2026-08-20)

อ่านจาก Prometheus + Loki จริงบน `zyra-k3s` ผ่าน Grafana datasource proxy (window: now-6h / now-24h)
เทียบกับ dashboard `zyra-mission-control` (commit `c28ba50`, origin/main)

**สภาพ ณ เวลาตรวจ (12:15 +07):** 36–47 participants / 11 rooms, node CPU 70–90%, prod endpoints ทั้ง 3 ตัว `probe_success=1`

---

## สรุปสิ่งที่ optimize ได้ เรียงตาม leverage

| # | เรื่อง | ผลกระทบวัดได้ | Severity |
|---|---|---|---|
| 1 | `obstacles` 403 retry loop | **44% ของ traffic prod ทั้งหมด** + 53% ของ log prod | P0 |
| 2 | Alertmanager ตายมา 2d19h | ไม่มี Discord alert ออกเลย — alert ทุกตัวไร้ผล | P0 |
| 3 | Grafana OOMKilled 9 ครั้ง | dashboard ล่มเป็นระยะ (limit 256Mi) | P0 |
| 4 | SFU ชน memory limit → OOMKilled | ประชุมที่กำลังคุยอยู่หลุดทั้ง node | P0 |
| 5 | Node CPU 90% ที่ 47 คน | เพดาน capacity อยู่ที่ ~50 concurrent | P1 |
| 6 | Disk 73% — containerd cache 18G | node เต็ม = ทุก env ล่มพร้อมกัน | P1 |
| 7 | resource requests ไม่ตรงจริง 10x | scheduler มองว่า node ว่างครึ่งนึงทั้งที่ 90% | P1 |
| 8 | Panel "Prometheus PVC used" อ่านผิด | ตัวเลขบน dashboard เชื่อไม่ได้ | P2 |
| 9 | Traefik p95 รวม WebSocket | p95 ค้างที่ 5s ตลอด อ่านไม่ได้ความ | P2 |

---

## 1. P0 — `POST /api/user/workspaces/{id}/obstacles` 403 วนไม่หยุด

**หลักฐาน**

```
sum by (service) (rate(traefik_service_requests_total{code="403"}[15m]))
  prod-zyra-app-80@kubernetes => 19.48 rps        ← ปัจจุบัน
sum(rate(traefik_service_requests_total[6h]))         => 15.67 rps (ทั้ง cluster)
sum(rate(traefik_service_requests_total{code="403"}[6h])) => 6.85 rps
```

**403 = 44% ของ request ทั้งหมดที่เข้า Traefik** (peak 19.5 rps เมื่อ 12:14) — มาจาก workspace เดียว
`d498edfa-f649-4795-979d-d3e0ba472cd3` และเป็น path เดียว:

```
[GIN] 403 | 1.37ms | POST "/api/user/workspaces/d498edfa-.../obstacles"   ← ซ้ำ ~20 ครั้ง/วินาที
```

Log ของ `zyra-api` ใน prod = 36.5 lines/s (88% ของ log volume prod ทั้งหมด) โดย **~53% เป็นบรรทัด 403 นี้**

**สาเหตุ — บั๊กสองฝั่งประกบกัน**

ฝั่ง server ([router.go:141](zyra-api/internal/router/router.go#L141) → [user_workspace_handler.go:190](zyra-api/internal/handler/user_workspace_handler.go#L190)):

```go
if err := h.wsSvc.VerifyUserOwnsWorkspace(ctx, workspaceID, userID); err != nil {
    h.ownerErr(c, err)   // ErrUnauthorized → 403 "forbidden"
}
```

`VerifyUserOwnsWorkspace` ([workspace_service.go:2252](zyra-api/internal/service/workspace_service.go#L2252)) เทียบ `owner_id` ตรงๆ —
**endpoint นี้เป็น owner-only** ทั้งที่ comment ฝั่ง client ([hero-virtual-office.tsx:3174](zyra-app/views/user/virtual-office/hero-virtual-office.tsx#L3174))
เขียนว่า *"Any member can publish because the data is deterministic"* → สอง assumption ไม่ตรงกัน

ฝั่ง client ([hero-virtual-office.tsx:3185-3235](zyra-app/views/user/virtual-office/hero-virtual-office.tsx#L3185)):

```ts
const timer = setInterval(tryPublish, 3000)      // poll ทุก 3 วิ ไม่มี jitter
...
if (status !== 200) {
  obstaclesSigRef.current = ""                   // ← ล้าง dedup guard = ยิงซ้ำ tick หน้า
}
```

dedup guard ถูกล้างทุกครั้งที่ไม่ใช่ 200 → **403 (ซึ่งจะไม่สำเร็จตลอดชาติ) ถูก retry แบบเดียวกับ 500 ชั่วคราว**
ไม่มี backoff, ไม่มี circuit breaker, ไม่มี stop-after-N, สังเกตได้แค่ `console.warn`
1 tab non-owner = 1 POST/3s → 19.5 rps ≈ **~60 session non-owner ที่เปิดค้างอยู่**

payload ไม่ใช่ของเล็ก: ส่ง grid เต็ม (`blocked` + `walls`, server รับได้ถึง 500k entries ต่อ field)
และทุก 403 ยังเสีย DB query (`SELECT owner_id FROM tb_workspace`) ทิ้งด้วย

**แก้**

1. ฝั่ง client — permanent failure ต้องหยุด: 403/400 → `clearInterval` แล้วเลิก (อย่าล้าง sig), เก็บ retry ไว้แค่ 5xx/network + ใส่ exponential backoff
2. ฝั่ง server — ตัดสินให้ชัดว่า obstacles เป็น owner-only จริงไหม ถ้า member ควร publish ได้ ให้เปลี่ยนเป็น membership check (ระวัง [owner ไม่มี member row](../doc/) ตามที่เจอมาก่อน)
3. ถ้าเลือกให้เป็น owner-only ต่อ → client ต้องไม่ยิงเลยตอนไม่ใช่ owner (มี flag owner อยู่แล้วในหน้า VO)

**ผลที่คาด:** traffic prod ลด 44%, log prod ลดครึ่งนึง, DB query ทิ้ง ~20/s หายไป

---

## 2. P0 — Alertmanager ตาย = alert ทุกตัวไร้ผล (2 วัน 19 ชม.)

```
$ kubectl -n monitoring get alertmanager
NAME                                 READY   RECONCILED   AVAILABLE   AGE
kube-prometheus-stack-alertmanager    0        False        False      2d19h

Reconciled=False ReconciliationFailed provision alertmanager configuration:
  failed to initialize from secret: yaml: unmarshal errors:
  line 30: field webhook_url_file not found in type alertmanager.discordConfig
```

`kubectl -n monitoring get sts` → มีแค่ `loki` และ `prometheus` — **ไม่มี StatefulSet ของ Alertmanager เลย**
operator ปฏิเสธ config แล้วไม่สร้างอะไรให้ ส่วน Prometheus ก็ยัง fire alert ส่งไปที่ที่ไม่มีคนรับ:

```
ALERTS{alertstate="firing"}:
  PrometheusNotConnectedToAlertmanagers  (warning)
  PrometheusOperatorSyncFailed           controller=alertmanager
  ZyraContainerOOMKilled                 pod=zyra-sfu-758db9f48c-8h572
```

ตรงกับที่ `gitops/observability/README.md` เตือนไว้เองว่า config ที่ operator ปฏิเสธ = ไม่มี StatefulSet
**และ fix มีอยู่แล้ว** — commit `bc8d2d3` บน branch `fix/alertmanager-discord-apiurl`
("route Discord via AlertmanagerConfig, not webhook_url_file") ยังไม่ merge เข้า main

**แก้:** merge branch นั้น แล้วยืนยันด้วย `kubectl -n monitoring get alertmanager` ว่า `Reconciled=True`
(ดู pod list เฉยๆ ไม่พอ — README เขียนเตือนไว้ตรงตัว)

> ระหว่างที่ยังไม่ merge: SFU OOMKill ข้อ 4 fire อยู่ตอนนี้ และไม่มีใครได้รับแจ้ง

---

## 3. P0 — Grafana OOMKilled 9 ครั้ง (limit 256Mi ตึงเกินไป)

```
lastState: {"terminated":{"exitCode":137,"reason":"OOMKilled","finishedAt":"2026-08-20T05:07:50Z"}}
restarts = 9   (4 ครั้งใน 6 ชม.ล่าสุด)

grafana mem limit           => 256.0 MiB
grafana working set (now)   => 224.3 MiB
max_over_time 24h           => 255.6 MiB   ← ชนเพดานพอดี
```

`kube-prometheus-stack-grafana` ตั้ง `limits.memory: 256Mi` / `requests: 128Mi` ส่วน sidecar สองตัว
(`grafana-sc-dashboard`, `grafana-sc-datasources`) **ไม่มี limit เลย** และกินอีก 75 MiB ต่อตัว

trigger คือ dashboard ใหม่เอง: `zyra-mission-control` = **33 panels, refresh 30s** เข้ามา 08-19 17:30
ซึ่งตรงกับช่วงที่ restart เริ่มถี่

**แก้:** ขึ้น `limits.memory` เป็น 512Mi (node เหลือเยอะ — ดูข้อ 5), ใส่ limit ให้ sidecar,
และลด `refresh` ของ mission-control จาก 30s เป็น 1m (33 panel × ทุก 30 วิ ไม่ได้ช่วยให้ตัดสินใจเร็วขึ้น)

---

## 4. P0 — SFU ชน memory limit → OOMKilled กลางประชุม

```
sfu limit (container app)        => 1536 MiB
max_over_time 24h               => 1534.4 MiB   ← ชนเพดานเป๊ะ (peak 08-19 17:24)
now (36 participants/11 rooms)   => 417–443 MiB
restarts                        => 2 (ครั้งล่าสุด ~28 นาทีก่อนตรวจ)
ZyraContainerOOMKilled           => firing
```

LiveKit เป็น single pod (`hostNetwork`) — OOMKill = **ทุกห้องที่กำลังประชุมหลุดพร้อมกัน**
และเพราะข้อ 2 ไม่มีใครได้ alert เลย

**แก้:** ขึ้น limit เป็น 3Gi (node มี 15.6 GiB allocatable, ใช้จริงแค่ 37%, requests รวมทั้ง cluster 3.0 GiB)
พร้อมตั้ง `requests.memory` ให้สมจริง แล้วดู max_over_time อีกรอบว่าโตแบบมีเพดานหรือ leak

---

## 5. P1 — Node CPU 90% ที่ 47 participants (เพดาน capacity จริง)

```
node CPU (24h)          max 0.90 @ 08-20 11:34   now 0.70–0.79
livekit participants    max 47   @ 08-20 11:34            ← peak ตรงกัน
sfu cpu cores (24h)     max 2.10 @ 08-20 11:24   now 0.9–1.02
iowait + steal          0.044 cores (ยังไม่ใช่คอขวด)
```

CPU by namespace (5m): `sfu 1.02` · `prod 0.58` · `monitoring 0.29` · `kube-system 0.24` · `argocd 0.08`

**SFU กินคนเดียว 2.1 จาก 4 cores ที่ 47 คน** → node e2-standard-4 หมดที่ประมาณ **50–60 concurrent**
และ dev/uat/prod/monitoring/argocd แชร์ node เดียวกับ prod อยู่ทั้งหมด

**แก้ (เรียงตามความคุ้ม):**
1. ย้าย SFU ออกไป VM ของตัวเอง — LiveKit ใช้ `hostNetwork` + media UDP อยู่แล้ว แยกง่ายสุดและตัด 50% ของ CPU peak ออกจาก prod
2. ถ้ายังไม่ย้าย: ปิด/ลด replica ของ dev+uat ตอนกลางคืน (dev+uat กิน 0.047 cores แต่กิน memory 150 MiB — ผลน้อย, ทำก็ได้ไม่ทำก็ได้)
3. ใส่ CPU limit ให้ monitoring stack กัน Prometheus แย่ง CPU ตอน SFU peak

---

## 6. P1 — Disk 73%: containerd image cache 18G

```
/dev/root  38G  28G  11G  73% /
sudo du -sh /var/lib/rancher/k3s/agent/containerd  →  18G
sudo k3s crictl images | wc -l                      →  180 images
```

PVC ทั้งหมดรวมกันเล็กมาก (Prometheus TSDB 142k series / 0.06 GiB head chunks, Loki 0.009 MB/s ingest, 38 streams)
ตัวกินคือ **image cache** — CI สร้าง tag ใหม่ทุก commit (`web:dev-<sha>`, `uat-<sha>`) แล้วไม่มีใครลบ

**แก้:** ตั้ง kubelet image GC (`--image-gc-high-threshold=70 --image-gc-low-threshold=55` ใน k3s config)
หรือ cron `k3s crictl rmi --prune` และ retention policy ที่ Artifact Registry ด้วย
node เต็ม = dev+uat+prod+monitoring ตายพร้อมกันหมด เพราะอยู่ node เดียว

---

## 7. P1 — resource requests ไม่ตรงกับของจริง 10 เท่า

| pod | request | ใช้จริง (peak) | ห่าง |
|---|---|---|---|
| `sfu/zyra-sfu` cpu | **0.2** cores | **2.1** cores | 10.5x |
| `sfu/zyra-sfu` mem | 512 MiB | 1534 MiB | 3x (ชน limit 1536) |

```
sum(kube_pod_container_resource_requests{resource="cpu"})     => 1.8   (จาก 4 cores)
sum(kube_pod_container_resource_requests{resource="memory"})  => 3.0 GiB (จาก 15.6)
```

scheduler เห็น node ว่าง "1.8/4 cores" ขณะที่ของจริง 90% → ถ้าเพิ่ม workload ใหม่มันจะยอมลง
แล้ว SFU จะถูกแย่ง CPU ตอนประชุมพีค (และ SFU มี request ต่ำสุด = ถูก throttle ก่อนใครตอน contention)

**แก้:** ตั้ง requests จาก p95 ที่วัดได้จริง — sfu cpu ≥ 1.5, mem 1Gi

---

## 8. P2 — Panel "Prometheus PVC used" อ่านค่าผิด

```
kubelet_volume_stats_used_bytes / capacity:
  prometheus-...-db-...-0        => 27895 / 38608 MiB
  storage-loki-0                => 27892 / 38608 MiB
  kube-prometheus-stack-grafana => 27892 / 38608 MiB   ← เท่ากันทั้ง 3 ตัว
```

PVC จริงคือ 5Gi / 10Gi / 2Gi แต่ทุกตัวรายงาน 27.9G จาก 38.6G — เพราะ `local-path` เป็น hostPath
kubelet จึงรายงาน **node root filesystem** ไม่ใช่ตัว PVC

panel นี้เลยแสดง "Prometheus PVC used = 27.9 GB" ของ PVC ขนาด 5Gi ซึ่งเป็นไปไม่ได้
ถ้าตั้ง threshold บนตัวเลขนี้ = alert ผิดตลอด

**แก้:** เปลี่ยน panel ไปใช้ `node_filesystem_avail_bytes{mountpoint="/"}` (ซึ่งคือสิ่งที่มันวัดจริงๆ อยู่แล้ว)
แล้วเปลี่ยนชื่อ panel เป็น "Node disk" หรือถ้าอยากได้ขนาด TSDB จริงใช้ `prometheus_tsdb_storage_blocks_bytes`

---

## 9. P2 — Traefik p95 latency รวม WebSocket เข้าไปด้วย

```
histogram_quantile(0.95, ... traefik_entrypoint_request_duration_seconds_bucket) => 1.42 s

p95 by service:
  prod-zyra-ws-80    => 5.0   ← ชน bucket ceiling
  sfu-zyra-sfu-80    => 5.0   ← ชน bucket ceiling
  prod-zyra-app-80   => 1.11
  prod-zyra-api-80   => 0.16
```

`zyra-ws` เป็น WebSocket → "request duration" คืออายุของ connection ทั้งเส้น ไม่ใช่ latency
panel รวม entrypoint `web|websecure` ทั้งหมด ตัวเลข 1.42s จึงเป็นค่าที่ตีความไม่ได้
(latency จริงของ API คือ 0.16s ซึ่งดีมาก)

**แก้:** เปลี่ยน panel เป็น per-service แล้วตัด ws/sfu ออก หรือ split เป็นสอง panel (HTTP vs WS connection age)

---

## 10. ช่องว่างของ alert (นอกเหนือจากข้อ 2)

ไม่มี alert ตัวไหนจับเรื่องพวกนี้ได้เลย ทั้งที่มันเกิดอยู่จริงตอนนี้:

| อาการที่เกิดจริง | ทำไมไม่มีใครรู้ |
|---|---|
| 403 = 44% ของ traffic | ไม่มี rule เรื่อง HTTP error ratio (มีแต่ up/down + probe_success) |
| node CPU 90% | ไม่มี rule CPU saturation ของ node (defaultRules ไม่ครอบ) |
| SFU ชน memory limit | มี `ZyraContainerOOMKilled` และ fire อยู่ — แต่ Alertmanager ตาย |
| latency prod สูง | ไม่มี app metric — ทุกอย่างต้องอ่านจาก Loki regex |

`metrics.enabled: false` ทุก service (known limit ที่ documented ไว้) → error signal เดียวที่มีคือ
`|~ "(?i)error"` บน log text ซึ่ง **53% ของ text นั้นคือ 403 loop ข้อ 1**

**แนะนำเพิ่ม 3 rule (ไฟล์ใหม่ใน `chart/alerts/`, ทำได้ทันทีไม่ต้องรอ app metrics):**

```yaml
# 4xx/5xx ratio จาก Traefik
sum(rate(traefik_service_requests_total{code=~"4..|5.."}[10m]))
  / sum(rate(traefik_service_requests_total[10m])) > 0.2   for 15m

# node CPU saturation
1 - avg(rate(node_cpu_seconds_total{mode="idle"}[10m])) > 0.85   for 15m

# container ใกล้ชน memory limit (จับ OOM ก่อนเกิด ไม่ใช่หลังเกิด)
container_memory_working_set_bytes / on(...) kube_pod_container_resource_limits{resource="memory"} > 0.9  for 10m
```

ข้อสาม จะจับได้ทั้ง Grafana (ข้อ 3) และ SFU (ข้อ 4) **ก่อน** ที่มันจะถูก kill

---

## 11. เรื่องเบ็ดเตล็ด

- **`node_load1` ไม่มีข้อมูล** — query `node_load1 / count(count by (cpu) (node_cpu_seconds_total))` คืนค่าว่าง
  (loadavg collector ของ node-exporter ไม่ได้ผลิต series) ไม่กระทบ dashboard ปัจจุบันเพราะไม่มี panel ใช้
- **`zyra-app` proxy พัง ECONNRESET เป็นชุด** — 500 ที่ `prod-zyra-app` 0.23 rps:
  `Failed to proxy http://zyra-api/api/user/workspaces/{id}/obstacles Error: write ECONNRESET`
  path เดียวกับข้อ 1 → client ปิด connection ก่อน proxy เขียน response เสร็จ น่าจะหายไปพร้อมกับ fix ข้อ 1
- **SFU log noise** — `zyra-sfu` ปล่อย 3.85 lines/s โดย 3.11 (81%) เป็น
  `warn ... "error reading data channel"` จาก `rtc/transport.go:942`
  เข้า Loki filter `|~ "(?i)error"` ทั้งหมดทั้งที่เป็น warn ปกติของ WebRTC → ทำให้ panel
  "Error lines by app" ชี้ว่า sfu เป็นตัวป่วนอันดับหนึ่งตลอดเวลา ทั้งที่ไม่ใช่
  แนะนำเปลี่ยน panel เป็น `| json | level="error"` แทน regex บน text ดิบ
- **Grafana ย้ายไปอยู่หลัง Cloudflare Access แล้ว** (มี ns `cloudflared` อายุ 20h) — ปิดช่อง GITOPS-REVIEW F2
  ได้แล้วจริง แต่ `gitops/observability/README.md` กับ `ACCESS.md` ยังเขียนว่า "public, no allowlist/SSO"
  และตาราง Known limits ยังไม่ตัดบรรทัดนั้นออก → เอกสารล้าสมัย

---

## สถานะการแก้ (2026-08-20)

| # | เรื่อง | PR | สถานะ |
|---|---|---|---|
| 1 | obstacles 403 loop — server-authoritative grid | [zyra-api#21](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/21) → develop | open |
| 1 | obstacles 403 loop — ลบ poller ฝั่ง client | [zyra-app#128](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/128) → develop | open · **merge หลัง api#21 deploy** |
| 2 | Alertmanager ตาย | [zyra-infra#10](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/10) | **merged 06:03** · ⚠️ ยังไม่จบ — ดูด้านล่าง |
| 3 | Grafana 256Mi→512Mi + sidecar limits + refresh 1m | [zyra-infra#11](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/11) | **merged 06:14 · live verified** |
| 4 | SFU limit 1536Mi→3Gi, requests 1500m/1Gi | zyra-infra#11 | **merged · live verified** |
| 7 | resource requests ตรงกับ p95 จริง (SFU) | zyra-infra#11 | **merged** |
| 8 | panel "Prometheus PVC used" → node-exporter | zyra-infra#11 | **merged** |
| 10 | alert rules 5 ตัว (`chart/alerts/saturation.yaml`) | zyra-infra#11 | **merged · โหลดเข้า Prometheus แล้ว** |
| — | zyra-ws log ตอน grid หาย (fail-open ไม่เงียบอีก) | [zyra-ws#22](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/22) → develop | open |

### ผลหลัง merge infra#10 + #11 (วัดจริง 13:25 +07)

```
sfu mem      123 MiB = 4% ของ limit ใหม่ 3072Mi   (เดิมชน 1534/1536 = 99.9%)
grafana mem  304 MiB = 59% ของ limit ใหม่ 512Mi   (เดิม 255/256 = 99.6% → OOMKilled 9 ครั้ง)
node cpu     0.655                                 restart หลัง rollout: 0
cpu requests 3.13 / 4.0 cores                      pods not running: 1 (= alertmanager ด้านล่าง)
livekit      13 participants / 5 rooms             คนกลับเข้าห้องได้ปกติหลัง SFU rollout
403 rps      17.4  ← ยังไม่ลด (รอ app#128)
```

alert rules ทั้ง 5 ตัวโหลดเข้า Prometheus แล้ว และ **`ZyraHighClientErrorRatio` = pending** ทันที
(รอครบ `for: 15m` แล้วจะ firing) — จับ 403 loop ได้จริงตามที่ออกแบบไว้

### ⚠️ infra#10 merge แล้วแต่ Alertmanager ยังไม่ขึ้น — ติด credential

error เปลี่ยนจาก config bug เป็น secret หาย ซึ่งคือ**ความคืบหน้า** แต่ยังส่ง Discord ไม่ได้:

```
Reconciled=False  provision alertmanager configuration: failed to initialize from
                  global AlertmanagerConfig: failed to retrieve API URL:
                  unable to get secret "alertmanager-discord": secrets "alertmanager-discord" not found

pod alertmanager-...-0   0/2  Init:0/1
  Warning FailedMount  MountVolume.SetUp failed for volume "secret-alertmanager-discord"
```

ตรวจแล้วว่า **ไม่มีทั้งสองที่**: `kubectl -n monitoring get secret | grep discord` ว่าง และ
`gcloud secrets list --filter="name~discord"` ก็ว่าง — ตรงกับที่ README เตือนไว้เองว่า secret นี้
"ปั้นมือบนโน้ด ไม่ได้อยู่ใน GitOps → rebuild node แล้ว alerting กลับมาพังเงียบๆ" ซึ่งเกิดขึ้นจริงแล้ว

**ไม่มี regression**: ก่อน merge ก็ไม่มี alert ส่งออกอยู่แล้ว (ไม่มี StatefulSet เลย) หลัง merge ก็ยังไม่ส่ง
แต่เหลือแค่ credential ใบเดียว ไม่ใช่บั๊ก config อีกแล้ว

**ทางแก้ (ต้องเป็นคนทำ — เป็น credential):** เลือกทางที่ 2 ดีกว่า เพราะรอด VM rebuild

```bash
# ทางที่ 1 — เร็ว แต่ credential อยู่บน VM ใบเดียว (หายอีกถ้า rebuild)
sudo k3s kubectl -n monitoring create secret generic alertmanager-discord \
  --from-literal=webhook-url='https://discord.com/api/webhooks/…'

# ทางที่ 2 — exit path ที่ documented ไว้แล้ว: ESO เป็นเจ้าของ
printf 'https://discord.com/api/webhooks/…' | \
  gcloud secrets create zyra-discord-alerts --project=gather-dev-458614 --data-file=-
# แล้วเปลี่ยน chart/values.yaml → alertmanagerDiscord.enabled: true (ExternalSecret เขียนไว้แล้ว)
```

หลังทำแล้วต้องเช็คว่า `kubectl -n monitoring get alertmanager` ขึ้น **`Reconciled=True`** —
ดู pod list เฉยๆ ไม่พอ (README เตือนตรงตัว)

**ยังไม่ได้ทำ:** ข้อ 5 (ย้าย SFU ออกจาก node), ข้อ 6 (image GC — ต้องแก้ k3s config บน VM ไม่ใช่ GitOps),
ข้อ 9 (panel Traefik p95 รวม WebSocket), `tileCoord` fractional 17% (ต้องแก้ client+server พร้อมกัน — ดู comment ใน `obstacle_grid_builder.go:96`)

### ลำดับ merge ที่ต้องเคารพ

```
zyra-infra#10  (Alertmanager)     ── independent, merge ก่อนได้เลย
zyra-infra#11  (limits + alerts)  ── independent · Argo sync = SFU restart 1 ครั้ง
zyra-api#21    (grid ฝั่ง server) ── ต้อง deploy ให้ขึ้น dev/prod ก่อน
      └── zyra-app#128 (ลบ poller) ── merge ตามหลัง ไม่ใช่พร้อมกัน
zyra-ws#22     (log)              ── independent
```

`zyra-app#128` merge ก่อน `zyra-api#21` deploy = grid หยุด refresh ทั้งระบบ (poller หายแต่ยังไม่มีใครแทน)

---

## ลำดับที่แนะนำให้ลงมือ

1. **merge `fix/alertmanager-discord-apiurl`** — ไม่มี alert = ทุกข้อที่เหลือรู้ช้าเสมอ (5 นาที)
2. **Grafana limit 256Mi → 512Mi + refresh 1m** — dashboard ที่ใช้ debug อยู่เองก็ล่ม (5 นาที)
3. **SFU memory limit → 3Gi** — กัน OOM ที่ทำประชุมหลุดทั้ง node (5 นาที)
4. **fix `obstacles` 403 loop ทั้งสองฝั่ง** — ลด traffic 44% / log 53% (ต้องตัดสินใจเรื่อง owner vs member ก่อน)
5. **image GC บน node** — disk 73% แล้ว
6. **เพิ่ม 3 alert rule** ข้อ 10
7. **แก้ 2 panel ที่อ่านค่าผิด** (PVC, p95)
8. **วางแผนย้าย SFU ออกจาก node** — เพดาน 50 concurrent ชัดแล้ว

---

## วิธี reproduce การตรวจนี้

Grafana อยู่หลัง Cloudflare Access และ ClusterIP ไม่ route จาก node — ต้องผ่าน port-forward:

```bash
# บน VM: port-forward ที่ทน pod restart
gcloud compute ssh zyra-k3s --project gather-dev-458614 --zone asia-southeast1-b --tunnel-through-iap
sudo k3s kubectl -n monitoring port-forward --address 127.0.0.1 svc/kube-prometheus-stack-grafana 8300:80

# บนเครื่อง: tunnel มาที่ localhost:3000
gcloud compute ssh zyra-k3s --project gather-dev-458614 --zone asia-southeast1-b \
  --tunnel-through-iap -- -N -L 3000:127.0.0.1:8300

# query ผ่าน datasource proxy (uid: prometheus / loki / alertmanager)
curl -H "Authorization: Bearer <grafana-sa-token>" \
  -G http://localhost:3000/api/datasources/proxy/uid/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service) (rate(traefik_service_requests_total{code="403"}[15m]))'
```

Grafana MCP server (`mcp-grafana`) ถูกตั้งไว้ที่ `.mcp.json` ของ workspace ชี้ไป `http://localhost:3000`
ผ่าน service account `claude-code-mcp` (role **Viewer**, read-only) — ใช้ tunnel เดียวกันนี้

---

# รอบ 2 — ตรวจ dashboard ที่ tag `zyra` ทั้ง 6 ตัว (2026-08-20 ช่วงบ่าย)

ทั้ง 6 อยู่ใน git ครบ ไม่มีตัวไหน drift มาจาก UI ✅
(`zyra-data` เข้ามาที่ commit `fb1b370` "scrape AlloyDB + Memorystore via postgres/redis exporters")

| uid | tags |
|---|---|
| `zyra-mission-control` | mission-control, zyra |
| `zyra-data` | data-plane, zyra |
| `zyra-node` | capacity, node, zyra |
| `zyra-services-overview` | services, zyra |
| `zyra-sfu` | livekit, sfu, zyra |
| `zyra-service-logs` | logs, zyra |

## A. Prometheus กำลังจะ OOM เป็นตัวถัดไป — และครึ่งหนึ่งของ series ไม่มีใครใช้

```
prometheus mem            928.8 MiB  = 90.7% ของ limit 1Gi
peak 24 ชม.               975.0 MiB  = 95.2%
tsdb head series          154,106
tsdb บน disk              3,085 MiB  (retentionSize ตั้งไว้ 4GB — ใกล้เพดานแล้ว)
```

รูปแบบเดียวกับ Grafana (255/256) และ SFU (1534/1536) ที่แก้ไปเมื่อเช้า — ตัวนี้ยังไม่ได้แก้

**Top-cardinality ทั้ง 10 อันดับเป็น histogram ของ Kubernetes apiserver/etcd/workqueue ทั้งหมด:**

```
18,598  apiserver_request_duration_seconds_bucket
13,124  etcd_request_duration_seconds_bucket
12,030  apiserver_request_sli_duration_seconds_bucket
 9,792  apiserver_request_body_size_bytes_bucket
 5,220  apiserver_watch_list_duration_seconds_bucket
 4,400  apiserver_response_sizes_bucket
 3,528  apiserver_watch_cache_read_wait_seconds_bucket
 2,268  apiserver_watch_events_sizes_bucket
 2,208  workqueue_work_duration_seconds_bucket
 2,208  workqueue_queue_duration_seconds_bucket
────────
~75,000 series = 49% ของทั้งหมด
```

ตรวจแล้วว่า **ทั้ง 10 ตัวถูกใช้ใน dashboard/alert ของ zyra = 0 ไฟล์**

**ทางแก้:** `metricRelabelings` drop บน ServiceMonitor ของ apiserver
(kube-prometheus-stack มี `kubeApiServer.serviceMonitor.metricRelabelings` ให้ตรงๆ)

⚠️ **ข้อควรระวัง:** `defaultRules` ของ chart มี apiserver SLO burnrate rules และ dashboard
"Kubernetes / API server" ที่กิน `apiserver_request_duration_seconds_bucket` อยู่ ถ้า drop ตัวนั้น
พวกนั้นจะพัง เพราะฉะนั้นเสนอทำสองขั้น:

1. **drop ที่ปลอดภัยแน่นอนก่อน** (ไม่มี defaultRule ใช้): `etcd_request_duration_seconds_bucket`,
   `apiserver_request_body_size_bytes_bucket`, `apiserver_watch_list_duration_seconds_bucket`,
   `apiserver_response_sizes_bucket`, `apiserver_watch_cache_read_wait_seconds_bucket`,
   `apiserver_watch_events_sizes_bucket`, `workqueue_*_seconds_bucket` ≈ **37,000 series (24%)**
2. แล้วค่อยตัดสินแยกว่า apiserver SLO rules คุ้มกับอีก 18,598 series บน node ตัวนี้ไหม
   (single-node k3s ที่ไม่มี HA control plane — SLO burn ของ apiserver มีประโยชน์จำกัด)

ทางเลือกที่ง่ายกว่าแต่แย่กว่า: ขึ้น limit เป็น 1.5Gi — แต่ node นี้ตึงอยู่แล้ว การลด series ดีกว่า

## B. Panel ที่อ่านค่าผิด/อ่านไม่ครบ

| dashboard | panel | ปัญหา |
|---|---|---|
| `zyra-node` | **Prometheus PVC used (approx)** | บั๊กเดียวกับที่แก้ใน mission-control แล้ว — `kubelet_volume_stats_used_bytes` รายงาน **node root fs** ไม่ใช่ PVC (local-path = hostPath) คำว่า "(approx)" ในชื่อบอกว่าคนเขียนก็สงสัยอยู่ ยังไม่ได้แก้ |
| `zyra-node` | **CPU by namespace** | regex `dev\|uat\|prod\|sfu\|monitoring\|argocd` ตก `kube-system`, `cloudflared`, `cert-manager`, `external-secrets` → แสดง 2.32 จาก 2.41 cores ที่ container ใช้จริง เทียบกับ gauge "Node CPU" ที่อยู่ panel เดียวกันไม่ได้ (ตอน traefik ยุ่ง kube-system เคยขึ้นถึง 0.24 cores) |
| `zyra-sfu` | ทั้ง dashboard | **ไม่มี `go_goroutines` และไม่มี `livekit_participant_join_total`** — dashboard อธิบาย CPU ของตัวเองไม่ได้ เพราะ CPU สัมพันธ์กับ join สะสม r=0.993 แต่สัมพันธ์กับ participant ที่ dashboard แสดงอยู่แค่ r=0.034 (ดู [livekit-sfu-capacity-2026-08-20.md](livekit-sfu-capacity-2026-08-20.md)) เพิ่ม 2 panel นี้จะทำให้มันวินิจฉัยได้ |
| `zyra-sfu` | Published tracks | รวม AUDIO+VIDEO เป็นเลขเดียว (มี by-kind แยกอยู่แล้ว) — ทำให้ stat หลักอ่านกำกวม |

## C. Data plane — สุขภาพดี ไม่ใช่คอขวด แต่มี 2 จุดสังเกต

```
pg cache hit ratio     1.000          ← ไม่ขาด memory เลย
connections            33 / 1000
prod db (postgres)     69 MB          zyra_uat 48 MB
commits/s              23.9 (postgres) + 14.1 (alloydbadmin overhead)
redis                  5.6 MiB / 1024 MiB · 240 keys · 10.6 ops/s · hit 0.94 · eviction 0
redis clients          53             ← pool ปกติของ ~12 pod ไม่ใช่ปัญหา
```

**จุดสังเกต 1 — deadlock ไม่เป็นศูนย์**

```
pg_stat_database_deadlocks  postgres (prod) = 496 สะสม
                            zyra_uat        = 236 สะสม
increase 24 ชม.                             = 3
```

496 ครั้งหมายถึงมี lock-ordering ที่ชนกันจริงในโค้ด ตอนนี้ ~3/วัน ไม่ฉุกเฉิน แต่ควรหาว่า query คู่ไหนชน
(เปิด `log_lock_waits` / ดู `pg_stat_activity` ตอนเกิด)

**จุดสังเกต 2 — query spill ลง disk ตลอด**

`sum(rate(pg_stat_database_temp_bytes[30m])) = 76 KB/s` — มี query ที่ sort/hash เกิน `work_mem`
เป็นประจำ ปรับ `work_mem` หรือใส่ index ให้ query นั้นได้ ต้องหาตัวการก่อน (`pg_stat_statements`)

## D. Alert ใหม่จากเมื่อเช้า — พิสูจน์ตัวเองแล้วทั้งสองตัว

```
ZyraHighClientErrorRatio      state=firing    -> prod-zyra-app-80@kubernetes   (403 loop)
ZyraContainerNearMemoryLimit  state=pending   -> monitoring/prometheus-...-0   (ข้อ A)
```

`ZyraContainerNearMemoryLimit` จับ Prometheus ได้**ก่อน** ที่มันจะถูก OOMKill ซึ่งเป็นเหตุผลที่ใส่ rule นี้เข้าไปตอนแรก
