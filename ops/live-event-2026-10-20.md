# ไลฟ์ 20:00 วันที่ 2026-10-20 — เตรียมเครื่อง + ผลจริงบน prod

> **สถานะ:** ไลฟ์จบแล้ว ราว 21:35 · ไม่มี incident · ระบบรับได้สบาย (CPU ของ SFU สูงสุด 6.6% ของ limit)
> **repo ที่กระทบ:** zyra-infra (gitops + terraform) · เครื่อง prod `zyra-k3s`, `zyra-sfu-node-0`
> **ที่มา:** Ten แจ้ง 18:30 ว่า 20:00 จะมีไลฟ์ คาดว่าคนเข้า 100–200 คน · MD ให้ scale เครื่องไว้ก่อน

## สิ่งที่เปลี่ยนบน prod (Ten อนุมัติในแชททุกข้อ)

| เวลา | เปลี่ยนอะไร | PR | ผลกระทบตอนเปลี่ยน |
|---|---|---|---|
| 18:33 | ปิด `zyra-sfu-lite` (replicas 0) — ให้ห้องไลฟ์ไปลงเครื่อง SFU หลักแน่นอน เพราะ LiveKit วางห้องหนึ่งห้องไว้บนเครื่องเดียว และ lite รับได้แค่ราว 30 คน | [zyra-infra#76](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/76) | ไม่มีคนหลุด (drain) |
| 18:33 | ingress `/api` วิ่งตรงเข้า zyra-api ไม่ผ่าน Next.js — เทสบน clone 2026-10-19 ไว้แล้ว (500 คน/workspace: p95 1,083 → 174 ms) | [zyra-infra#73](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/73) | ไม่มี · เช็คแล้ว route ของ Next.js ใน v1.9.2 มีเท่ากับที่ยกเว้นไว้ (6 route) |
| 18:35–18:40 | `zyra-k3s` e2-standard-4 → **e2-standard-8** | terraform: [zyra-infra#77](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/77) (ยังไม่ merge) | ทุก env ล่ม ~5 นาที (18:34:45 → 18:39:42) |
| 18:59–19:05 | `zyra-sfu-node-0` c2d-highcpu-4 → **c2d-highcpu-8** + LiveKit limit 3500m/4Gi → **7000m/8Gi** | [zyra-infra#78](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/78) | ห้องประชุมใช้ไม่ได้ ~6 นาที · ~15 คนที่อยู่ในห้องต้อง refresh เอง (client ไม่ต่อกลับเองหลังดับนานขนาดนั้น) |
| 21:50 | promtail memory limit 128Mi → 256Mi (หลังไลฟ์ ตามที่ตกลงไว้) | [zyra-infra#80](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/80) | ไม่มี |

ทำไมไม่เพิ่ม node: ห้องเดียวแบ่งไปหลายเครื่อง SFU ไม่ได้ (LiveKit OSS) และ zyra-ws รันได้ตัวเดียว (state อยู่ใน memory) — การเพิ่มเครื่องจึงไม่ช่วยงานนี้ ใช้วิธีขยายเครื่องเดิมแทน

## Before/After

| Metric | ก่อนเตรียม (prod 7 วันก่อนหน้า) | ระหว่างไลฟ์ 19:55–21:36 | ความจุหลังขยาย |
|---|---|---|---|
| คนใน LiveKit พร้อมกัน | สูงสุด 64 | **สูงสุด 83** (สถิติใหม่) | ~150–220 (ประมาณการใน `terraform/variables.tf`) |
| CPU ของ SFU (ต่อ limit) | สูงสุด 0.58 core / 3.5 = 17% | **สูงสุด 6.6%** (0.46 core / 7) | หยุดรับห้องใหม่ที่ 80% |
| CPU เครื่องหลัก | สูงสุด 67% (4 vCPU) | **สูงสุด 20%** จากงานจริง (8 vCPU) | — |
| packet loss (LiveKit) | — | **สูงสุด 0.53%** | — |
| SFU ส่งออก | สูงสุด ~80 Mbps | **สูงสุด 207 Mbps** | — |
| Traefik connection | สูงสุด 257 | สูงสุด 232 | alert ที่ 600 (#75) |
| app `/api/health` | — | **200 ครบ 53/53 รอบ** | — |
| HTTP 5xx ของ prod | — | 0 | — |

**วัดยังไง:** script `live-probe.sh` บน zyra-k3s query Prometheus ทุก 2 นาที (`livekit_participant_total`, CPU ของ container `zyra-sfu` หารด้วย limit, `node_cpu_seconds_total`, `livekit_packet_loss_total / livekit_packet_total`, `traefik_open_connections`) + `curl` health ของ app และ `ws.zyraworld.co/healthz`
**ช่วงเวลา:** before = 13–20 ต.ค. (Prometheus prod 7 วัน) · during = 2026-10-20 19:55–21:36

**ข้อจำกัด:** คนดูจริงมีแค่ราว 83 คน ไม่ถึง 100–200 ที่คาดไว้ ระบบจึงยังไม่เคยถูกทดสอบจริงที่ 200 คนในห้องเดียว แต่ถ้าคิดจากตัวเลขคืนนี้ (83 คน = 6.6%) ที่ 200 คนน่าจะต่ำกว่า 20%

## เหตุที่เจอระหว่างไลฟ์

### Grafana ทำ disk ของเครื่องหลักตัน 20:51–20:55 (ไม่กระทบผู้ใช้)
- CPU เครื่องหลักขึ้นไป 71% แต่เป็น **iowait 4.4 core** ไม่ใช่งานจริง · disk ถูกใช้ 95% · อ่าน disk ~37 MB/s
- ตัวที่อ่าน disk คือ pod Grafana (~75 MB/s) เพราะ memory ขึ้นไป 490/512 MiB → page cache thrash (restart ไปแล้ว 3 ครั้งในประวัติ)
- service ของผู้ใช้ไม่ได้รอ disk (DB และ Redis อยู่นอกเครื่อง) — app 200, LiveKit ปกติ ตลอดช่วงนั้น
- **ยังไม่แก้** — เสนอขึ้น Grafana 512Mi → 1Gi (Ten ยังไม่สั่ง)

### Dashboard "Node CPU" บอกเครื่อง SFU 72% ตอน 19:10 (ค่าเพี้ยน)
- ค่าจริงในหน้าต่าง 2 นาทีคือ 0.3% · panel เฉลี่ยคร่อมตอนรีบูต (เครื่องดับ 5 นาที + core 5–8 เพิ่งมีข้อมูล + ตัวนับเริ่มใหม่) → หายเองหลัง ~30–60 นาที

### `ZyraContainerNearMemoryLimit` promtail บนเครื่อง SFU (121/128 MiB)
- เป็นตัวเก็บ log ไม่กระทบการประชุม · แก้แล้วหลังไลฟ์ (#80)

## ค้าง / ต่อจากนี้

| เรื่อง | สถานะ |
|---|---|
| เปิด `zyra-sfu-lite` กลับเป็น 1 | ตกลงว่าทำพรุ่งนี้เช้า 2026-10-21 (revert #76) |
| เครื่อง 8 vCPU ทั้งสองตัว | Ten เลือกคงไว้ (ยังไม่ลด) · terraform #77 (k3s) ยังไม่ merge · #78 (SFU) merge แล้ว |
| Grafana memory 1Gi | เสนอแล้ว ยังไม่สั่ง |
| alert เตือนก่อนเต็ม | [zyra-infra#75](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/75) ยังไม่ merge |
| autoscaler เปิด/ปิดเครื่อง SFU ตามโหลด | [zyra-infra#79](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/79) เทสบน clone ผ่าน · ยังไม่ merge ([plan/Autoscaling/progress.md](../plan/Autoscaling/progress.md)) |
| runbook "งานที่มีคน > 100" | ยังไม่เขียน — ขั้นตอนคืนนี้ใช้เป็นต้นแบบได้: ปิด sfu-lite → ขยายเครื่องล่วงหน้า ≥ 1 ชม. → ให้ทุกคน refresh หลังขยาย SFU → freeze deploy → ซ้อม → เฝ้าดู |
