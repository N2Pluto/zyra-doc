# Autoscaling ตามช่วงใช้งาน — แผน

> **สถานะ:** P1-1 ขึ้น prod แล้ว 2026-10-20 ([zyra-infra#74](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/74), Ten อนุมัติ) · P1-3/P1-4 ยังไม่ทำ · log: [progress.md](progress.md) · ข้อมูลจาก Prometheus prod 7 วัน (13–20 ต.ค. 2026) + load test 19 ต.ค. ([LoadTest/results](../LoadTest/results/2026-10-19.md))
> **repo ที่กระทบ:** zyra-infra (terraform + gitops) · ภายหลัง zyra-api / zyra-ws
> **ผู้เสนอ:** Ten — "ช่วงไหนคนใช้เยอะสั่งเปิด VM เพิ่ม ช่วงไหนคนน้อยปิดส่วนที่ไม่ได้ใช้"

## สรุป

**ตอนนี้ยังไม่ต้องขยายเครื่องตอนคนเยอะ แต่ปิดเครื่องวิดีโอ (SFU node) ตอนคนน้อยได้** — peak จริงใช้ CPU เครื่องหลัก 2.25 / 4 core (56%) และมี connection สูงสุด 257 ขณะที่ load test วัดได้ว่าทั้งระบบรับ ~1,000 คน · เครื่อง SFU ว่างเกือบทั้งวัน (CPU median 0.03 core, สูงสุด 0.53) · ปิดนอกเวลางานประหยัด ≈ **$87/เดือน** (ราคา list) แต่ต้องแก้ทางเข้า signaling ก่อน ไม่งั้นคนเข้าประชุมไม่ได้ตอนเครื่องปิด

## การใช้งานจริง (prod, 13–20 ต.ค. 2026, เวลาไทย)

`conn` = WebSocket/HTTPS connection ที่เปิดค้างบน Traefik (รวม dev/uat ด้วย — prod เป็นส่วนใหญ่) · `rps` = request/วิ ของ service prod · `lk` = คนใน LiveKit (sfu + sfu-lite)

| ช่วง (วันทำงาน) | conn เฉลี่ย / สูงสุด | rps เฉลี่ย | CPU เครื่องหลัก เฉลี่ย / สูงสุด | CPU เครื่อง SFU | lk เฉลี่ย / สูงสุด |
|---|---|---|---|---|---|
| 00–08 | 38–65 / 102 | 3–5 | 0.9–1.1 / 1.4 core | ~0 | 10–24 / 35 |
| 09 | 58 / 105 | 5.4 | 1.1 / 1.5 | 0.0 | 19 / 25 |
| **10–17 (peak)** | **128–169 / 257** | **13–15** | **1.4–1.5 / 2.3** | **0.1–0.2 / 0.5** | **35–52 / 92** |
| 18 | 116 / 202 | 10.8 | 1.3 / 1.8 | 0.1 | 39 / 75 |
| 19–23 | 63–84 / 134 | 5–7 | 1.1 / 1.6 | ~0 | 18–26 / 36 |
| **วันหยุด ทั้งวัน** | **30–49 / 74** | **2–4** | **0.8–0.9 / 1.2** | **~0** | **10–24 / 29** |

- peak ต่อวัน: พ. 257 · พฤ. 242 · จ. 243 · อ./ศ. 69–89 (13 ต.ค. วันหยุด) · ส./อา. 63–74
- กลางคืนยังมีคนค้างใน LiveKit ~10–24 คน (เปิดแท็บค้าง) ซึ่ง sfu-lite บนเครื่องหลักรับอยู่แล้ว (CPU เครื่อง SFU ตอนกลางคืน ≈ 0)
- CPU เครื่องหลักขั้นต่ำ ~0.8 core = overhead คงที่ (monitoring, Argo, dev/uat, Traefik)
- **ข้อจำกัดข้อมูล:** Prometheus เก็บแค่ 7 วัน · ช่วงนี้มีวันหยุด 1 วัน · `conn` ไม่ใช่จำนวน user ตรง ๆ (1 user อาจมีหลาย connection) · zyra-ws ไม่มี metric จำนวนคน online

## อะไรเปิด/ปิดตามโหลดได้บ้าง

| ส่วน | ปรับตามโหลดได้ไหม | เงื่อนไข |
|---|---|---|
| เครื่อง SFU (`zyra-sfu-node-0`, c2d-highcpu-4) | ✅ ปิด/เปิดตามเวลา | ต้องแก้ signaling ให้เข้า sfu-lite ได้ด้วย (ข้อ P1-1) |
| เว็บ (zyra-app, Next.js) | ✅ HPA เพิ่ม/ลด replica | stateless · แต่หลังแก้ ingress `/api` (zyra-infra #73) Next.js ไม่ใช่คอขวดแล้ว → ยังไม่จำเป็น |
| api | ⚠️ ต้องแก้โค้ด | presence เก็บใน memory ต่อ process (`WorkspacePresenceHub`) → 2 replica แยกรายชื่อ online กัน ต้องย้ายไป Redis |
| realtime (zyra-ws) | ❌ | room state ใน memory ไม่มี fan-out ข้ามเครื่อง ต้อง route ตาม workspace (Traefik ทำไม่ได้) |
| เครื่องหลัก (`zyra-k3s`) | ❌ ตามเวลา | node เดียวรันทุกอย่าง (control plane + prod + dev/uat) เปลี่ยนขนาด = restart ~5 นาที |
| AlloyDB / Redis | ❌ | หยุดชั่วคราวไม่ได้ (ราคาคงที่) |

## แนวทาง — ปรับอัตโนมัติตามโหลด (คนน้อยลด คนเยอะเพิ่ม)

> Ten ถาม 2026-10-20: "ทำไมไม่ปรับอัตโนมัติ คนใช้น้อยก็ลด คนใช้เยอะก็เพิ่ม" — ทำได้ แต่ทำได้ทีละส่วนตามที่โครงสร้างระบบรองรับ ส่วนนี้คือลำดับที่ตกลงไว้

### ทำไมยังเพิ่ม/ลดทั้งระบบอัตโนมัติไม่ได้ (ข้อเท็จจริง 2026-10-20)

| ส่วน | ปรับอัตโนมัติได้ไหม | เหตุผล |
|---|---|---|
| เครื่องประชุม SFU (`zyra-sfu-node-0`) | ✅ **ได้แล้ว** | หลัง [zyra-infra#74](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/74) signaling เข้าทั้ง 2 LiveKit pod — ปิดเครื่อง SFU แล้ว sfu-lite รับห้องใหม่แทน (เทสบน clone: drain ก่อนปิด → join fail 0) |
| เว็บ (zyra-app) | ⚠️ เพิ่ม pod ได้ แต่ยังไม่จำเป็น | stateless · หลัง ingress `/api` ตรง (#73) ไม่ใช่คอขวด |
| api | ❌ ต้องแก้โค้ดก่อน | รายชื่อคน online (`WorkspacePresenceHub`) อยู่ใน memory ต่อ process — 2 replica จะเห็นคน online ไม่ตรงกัน |
| realtime (zyra-ws) | ❌ ต้องออกแบบใหม่ | สถานะห้องอยู่ใน memory ของ process เดียว — คนในห้องเดียวกันต้องอยู่ instance เดียวกัน · เป็นคอขวดหลักจาก load test |
| เครื่องหลัก (`zyra-k3s`) | ❌ ไม่ทำอัตโนมัติ | เปลี่ยนขนาด 4 ↔ 8 vCPU ต้อง restart VM = ทุก env ล่ม ~2–3 นาที (สั่งตอนคนเยอะ = ล่มตอนคนเยอะ) · ลดตอนคนน้อยแทบไม่ประหยัด เพราะ dev/uat/monitoring อยู่เครื่องนี้ด้วย |

ตอนนี้ไม่มี HPA / KEDA / node autoscaler ใน cluster หรือ GCE เลย (เช็ค 2026-10-20) — replica และขนาดเครื่องตายตัวทั้งหมด

### ลำดับที่จะทำ

**ขั้น A — ตอนนี้: เครื่อง SFU เปิด/ปิดตามโหลดจริง (แทนตามเวลาอย่างเดียว)** → P1-6

ตัวควบคุมเล็ก ๆ (CronJob ใน cluster ทุก 1 นาที หรือ Cloud Scheduler + Cloud Run) อ่าน Prometheus แล้วตัดสินใจ:

| สถานะ | เงื่อนไข (ค่าเริ่มต้น ปรับได้) | ทำอะไร |
|---|---|---|
| SFU ปิดอยู่ → **เปิด** | sfu-lite CPU > 50% ของ limit นาน 3 นาที **หรือ** คนบน sfu-lite > 20 | `gcloud compute instances start zyra-sfu-node-0` → `kubectl uncordon` |
| SFU เปิดอยู่ → **ปิด** | ไม่มีห้องบนเครื่อง SFU นาน 30 นาที **และ** sfu-lite CPU < 30% ของ limit **และ** อยู่นอก 09:00–18:00 จ.–ศ. | `kubectl drain` (รอห้องหมด) → `gcloud compute instances stop` |
| กันแกว่ง | หลังเปิด/ปิด ห้ามสลับอีก 30 นาที | — |
| ตัวสำรอง | GCE schedule (P1-3) เปิดเครื่อง 08:00 จ.–ศ. เสมอ + alert (P1-5, [#75](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/75)) ถ้าตัวควบคุมพัง | — |

- **ทำไมเปิดที่ 50% ไม่รอใกล้เต็ม:** เครื่อง SFU ใช้เวลาเปิดจนรับห้องได้ ~1–2 นาที (clone: pod Ready 46 วินาทีหลัง start) LiveKit ตัดรับห้องใหม่ที่ 80% — ต้องเหลือเวลาก่อนถึงจุดนั้น
- **ทำไมต้อง drain ก่อนปิด:** clone 2026-10-20 — ปิดโดยไม่ drain: join fail 5 ครั้ง (~33 วินาที) · drain ก่อน: 0
- **ห้าม roll LiveKit ทั้ง 2 ตัวพร้อมกัน:** ต้อง pause ตัวหนึ่งไว้ (บทเรียนจาก rollout #74)
- **ประหยัด:** ≥ $87/เดือน (เท่ากับแบบตามเวลา หรือมากกว่า ถ้าวันทำงานบางช่วงคนน้อยจนปิดได้)
- **ข้อจำกัด:** ห้องที่ค้างบนเครื่อง SFU ตอน drain จะรอจนจบเอง (สูงสุด 90 นาที) — แท็บที่เปิดค้างทั้งคืนจะทำให้ปิดเครื่องช้า

**ขั้น B — เมื่อ alert เตือน: ขยายเครื่องหลักครั้งเดียว** → P2-1

- trigger: `ZyraMainNodeCPUHigh` (CPU > 60% นาน 30 นาที) หรือ `ZyraEdgeConnectionsHigh` (> 600) เกิดซ้ำหลายวันในชั่วโมง peak
- ทำ: resize `zyra-k3s` 4 → 8 vCPU นอกเวลางาน (คนสั่ง ไม่อัตโนมัติ) — load test ยืนยันแล้ว 1,000 คน/workspace p95 288 ms
- ระหว่างรอ: alert บอกล่วงหน้าพอให้นัดเวลา resize ได้

**ขั้น C — ระยะยาว: เพิ่ม/ลด pod อัตโนมัติจริง (HPA)** → P2-2, P2-3, P2-4

ต้องทำตามลำดับ เพราะแต่ละขั้นเป็นเงื่อนไขของขั้นถัดไป:

1. api presence → Redis (P2-2) → แล้วใส่ HPA ให้ api + app (2–4 replica ตาม CPU)
2. zyra-ws: AOI / batching ก่อน (ลดงานต่อคน) → แล้วออกแบบหลาย instance แบบ route ตาม workspace (P2-4) — ต้องออกแบบร่วม ws + app (กฎ VO desync: ใครได้ `moving` ต้องได้ `stopped`)
3. แยก dev/uat ออกจากเครื่อง prod หรือทำ agent node pool สำหรับ app/api (P2-3) → เพิ่ม/ลด**เครื่อง**ได้โดยไม่แตะ control plane
4. ถ้าโตเกินนั้น: GKE + cluster autoscaler (P2-5)

ผลลัพธ์หลังขั้น C: ทั้งระบบเพิ่มเครื่องตอนคนเยอะ ลดตอนคนน้อยได้จริง — เป็นงานหลาย PR ข้าม zyra-api / zyra-ws / zyra-app / zyra-infra จึงเริ่มเมื่อถึงเกณฑ์ Phase 2 เท่านั้น

## แผน

### Phase 1 — ปิดเครื่อง SFU นอกเวลางาน (ประหยัด ≈ $87/เดือน)

| # | Task | หมายเหตุ |
|---|---|---|
| P1-1 | ✅ **ทำแล้ว (prod 2026-10-20)** — Service `zyra-livekit` select ทั้ง `zyra-sfu` และ `zyra-sfu-lite` · ingress `sfu.*` ชี้ไปที่นี่ | [zyra-infra#74](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/74) · roll เสร็จ 03:31 |
| P1-2 | ✅ **เทสบน clone แล้ว** — ปิด SFU node: route เดิม join สำเร็จ 5/78 · route ใหม่ 30/35 · drain ก่อน 36/36 | ยังไม่ได้เทส Spotlight ผ่านหน้าเว็บ และ sfu-lite รับคนทั้งหมดได้กี่คน ([progress](progress.md)) |
| P1-3 | GCE instance schedule (`google_compute_resource_policy` แบบ `instance_schedule_policy`) ผูกกับ `zyra-sfu-node-0`: **เปิด 08:00 · ปิด 20:00 จ.–ศ. · ปิดเสาร์–อาทิตย์** (Asia/Bangkok) | VM ที่ stop ไม่คิดค่า CPU/RAM (ยังคิด disk 40 GB + static IP ~$7/เดือน) |
| P1-4 | ก่อนปิด 20:00: ให้ LiveKit drain (ไม่รับห้องใหม่) ~10 นาที เพื่อไม่ตัดประชุมที่ค้าง | หรือยอมให้ห้องที่ค้างตอน 20:00 reconnect ไป sfu-lite (~30 วินาที) |
| P1-5 | Alert เตือนก่อนเต็ม: CPU เครื่องหลัก > 60% นาน 30 นาที · Traefik connection > 600 · LiveKit pod > 70% ของ CPU limit · LiveKit ทุก pod > 70% (critical) | PR [zyra-infra#75](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/75) (ยังไม่ merge) · backtest 7 วันไม่ fire |
| P1-6 | **ตัวควบคุมเปิด/ปิดเครื่อง SFU ตามโหลด** — PR [zyra-infra#79](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/79) เทสบน clone ผ่าน (เปิดที่ 60% ตาม Ten) (ดู §แนวทาง ขั้น A) — เปิดเมื่อ sfu-lite > 50% / > 20 คน · drain + ปิดเมื่อไม่มีห้อง 30 นาทีนอกเวลางาน · P1-3 เป็นตัวสำรอง | เทสบน clone ก่อน · ต้องการ SA ที่ start/stop VM ได้เฉพาะ `zyra-sfu-node-0` |

**ค่าใช้จ่าย:** c2d-highcpu-4 ≈ $0.185/ชม. · ปิด 108 ชม./สัปดาห์ (จ.–ศ. 12 ชม. + ส.–อา. 48 ชม.) = 64% ของเวลา → ≈ **$87/เดือน** (ราคา list Singapore, ยังไม่หักส่วนลด/CUD)

**ความเสี่ยง:** เครื่องหลักต้องรับ media ช่วงปิด (sfu-lite limit 1.5 core) — ข้อมูลกลางคืน/วันหยุด lk สูงสุด 36 คน · TURN LB (`terraform/turn-lb.tf`) ชี้ทั้งสองเครื่องอยู่แล้ว ต้องเช็คว่า health check ไม่พาไปเครื่องที่ปิด

### Phase 2 — เตรียมขยายตอนคนเยอะ (ทำเมื่อถึงเกณฑ์ ไม่ใช่ตอนนี้)

**เกณฑ์ที่ควรเริ่ม:** peak conn > ~600 หรือ CPU เครื่องหลัก > 60% ต่อเนื่องในชั่วโมง peak หลายวัน (ตอนนี้ 257 / 56% สูงสุด)

| # | Task |
|---|---|
| P2-1 | ขยาย `zyra-k3s` 4 → 8 vCPU (ทางที่ load test ยืนยันแล้ว: 1,000 คน/workspace p95 288 ms) — ครั้งเดียว ไม่ใช่ตามเวลา · ✅ **ทำแล้ว 2026-10-20** (ก่อนไลฟ์ — [ops](../../ops/live-event-2026-10-20.md)) |
| P2-2 | api presence → Redis แล้วให้ api / app มี HPA (2–4 replica) |
| P2-3 | แยก dev/uat ออกจากเครื่อง prod หรือ agent node pool สำหรับ app/api (แบบเดียวกับ SFU pool) — ให้เครื่องเพิ่ม/ลดได้โดยไม่แตะ control plane |
| P2-4 | zyra-ws: AOI / batching (fix-plan ข้อ 4) แล้วค่อยออกแบบหลาย instance (route ตาม workspace) |
| P2-5 | ระยะยาว: GKE + cluster autoscaler แทน k3s node เดียว |

## Open questions

| # | คำถาม |
|---|---|
| Q1 | เวลาเปิด/ปิด SFU 08:00–20:00 จ.–ศ. เหมาะกับลูกค้าไหม (มีลูกค้าที่ประชุมกลางคืน/เสาร์ไหม) |
| Q2 | ยอมให้ประชุมที่ค้างตอน 20:00 สะดุด ~30 วิ หรือต้อง drain |
| Q3 | เก็บ Prometheus นานขึ้น (7 วัน → 30 วัน) เพื่อดู pattern รายเดือนก่อนตัดสินใจ Phase 2 ไหม |
| Q4 | เกณฑ์ตัวควบคุม SFU (P1-6): เปิดเมื่อ sfu-lite > 50% / > 20 คน · ปิดเมื่อไม่มีห้อง 30 นาที และนอก 09:00–18:00 จ.–ศ. — ตั้งค่าเริ่มต้นตามนี้ หรือให้ปิดในเวลางานได้ด้วยถ้าคนน้อย |
