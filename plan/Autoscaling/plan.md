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

## แผน

### Phase 1 — ปิดเครื่อง SFU นอกเวลางาน (ประหยัด ≈ $87/เดือน)

| # | Task | หมายเหตุ |
|---|---|---|
| P1-1 | ให้ signaling `sfu.zyraworld.co` เข้าได้ทั้ง `zyra-sfu` และ `zyra-sfu-lite` (Service ร่วมที่ select ทั้งสอง pod หรือ ingress ของ sfu-lite ที่ host เดียวกัน) | **ต้องทำก่อน** — ตอนนี้ signaling เข้าแค่ zyra-sfu (`envs/prod/services/sfu-lite/values.yaml` header) ถ้าเครื่อง SFU ปิด คนเข้าประชุมใหม่ไม่ได้ · LiveKit route ห้องข้ามเครื่องผ่าน Redis อยู่แล้ว |
| P1-2 | ทดสอบบน dev/clone: ปิด SFU node → เข้าประชุม / Spotlight ได้ผ่าน sfu-lite · เปิดกลับ → ห้องใหม่ไปลงเครื่อง SFU | วัด loss / CPU ของเครื่องหลักตอน sfu-lite รับคนเดียว |
| P1-3 | GCE instance schedule (`google_compute_resource_policy` แบบ `instance_schedule_policy`) ผูกกับ `zyra-sfu-node-0`: **เปิด 08:00 · ปิด 20:00 จ.–ศ. · ปิดเสาร์–อาทิตย์** (Asia/Bangkok) | VM ที่ stop ไม่คิดค่า CPU/RAM (ยังคิด disk 40 GB + static IP ~$7/เดือน) |
| P1-4 | ก่อนปิด 20:00: ให้ LiveKit drain (ไม่รับห้องใหม่) ~10 นาที เพื่อไม่ตัดประชุมที่ค้าง | หรือยอมให้ห้องที่ค้างตอน 20:00 reconnect ไป sfu-lite (~30 วินาที) |
| P1-5 | Alert ถ้าเครื่องหลัก CPU > 70% ตอน SFU ปิด หรือ LiveKit participant บน sfu-lite > 60 | ปลดล็อกให้เปิด SFU มือได้ทันที |

**ค่าใช้จ่าย:** c2d-highcpu-4 ≈ $0.185/ชม. · ปิด 108 ชม./สัปดาห์ (จ.–ศ. 12 ชม. + ส.–อา. 48 ชม.) = 64% ของเวลา → ≈ **$87/เดือน** (ราคา list Singapore, ยังไม่หักส่วนลด/CUD)

**ความเสี่ยง:** เครื่องหลักต้องรับ media ช่วงปิด (sfu-lite limit 1.5 core) — ข้อมูลกลางคืน/วันหยุด lk สูงสุด 36 คน · TURN LB (`terraform/turn-lb.tf`) ชี้ทั้งสองเครื่องอยู่แล้ว ต้องเช็คว่า health check ไม่พาไปเครื่องที่ปิด

### Phase 2 — เตรียมขยายตอนคนเยอะ (ทำเมื่อถึงเกณฑ์ ไม่ใช่ตอนนี้)

**เกณฑ์ที่ควรเริ่ม:** peak conn > ~600 หรือ CPU เครื่องหลัก > 60% ต่อเนื่องในชั่วโมง peak หลายวัน (ตอนนี้ 257 / 56% สูงสุด)

| # | Task |
|---|---|
| P2-1 | ขยาย `zyra-k3s` 4 → 8 vCPU (ทางที่ load test ยืนยันแล้ว: 1,000 คน/workspace p95 288 ms) — ครั้งเดียว ไม่ใช่ตามเวลา |
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
