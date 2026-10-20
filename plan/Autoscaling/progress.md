# Autoscaling — progress

> log ต่อรอบ (entry ใหม่อยู่บนสุด) · แผน: [plan.md](plan.md)

## 2026-10-20 — P1-5 alert เตือนก่อนเต็ม (PR เปิดไว้ ยังไม่ merge)

**ทำอะไร**
- เพิ่ม `gitops/observability/chart/alerts/capacity.yaml` (PrometheusRule `zyra-alerts-capacity`) ส่งเข้า Discord ตัวเดิม:
  - CPU zyra-k3s > 60% นาน 30 นาที
  - Traefik open connections > 600 นาน 15 นาที
  - LiveKit pod ใด pod หนึ่งใช้ CPU > 70% ของ limit นาน 10 นาที (LiveKit หยุดรับห้องใหม่ที่ 80%)
  - LiveKit ทุก pod > 70% นาน 5 นาที (critical)

**PR**
- [zyra-infra#75](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/75) ยังไม่ merge (Ten สั่งให้เปิด PR ไว้ก่อน)

**verify ถึงไหน**
- render แล้ว ได้ label `release` ตรงกับที่ ruleSelector ต้องการ
- `kubectl apply --dry-run=server` บน prod ผ่าน
- ทุก expression รันบน prod Prometheus ได้ (`success`) และตอนนี้ยังไม่มีตัวไหน fire
- backtest 7 วัน: CPU ช่วงที่ต่อเนื่องนานสุดในหน้าต่าง 30 นาทีอยู่ที่ 59.7% → ไม่ fire (ถ้าใช้ 15 นาทีจะ fire 1 ครั้ง) · connection peak 257 · LiveKit สูงสุด 0.54 ของ limit
- **ยังไม่ได้เทส:** ข้อความเข้า Discord จริง ต้องรอ merge ก่อน

**ต่อจากนี้**
- merge เมื่อ Ten สั่ง
- P1-3 schedule + P1-4 drain-before-stop

## 2026-10-20 03:31 — P1-1 roll เสร็จบน prod

- **03:20:** `zyra-sfu` เดิมครบ grace 90 นาทีแล้วถูกตัด ห้องที่ค้าง 3 ห้อง / 14 คนไม่จบเองระหว่าง drain (น่าจะเป็นแท็บที่เปิดค้างไว้)
- **03:22:** `zyra-sfu` ใหม่ Ready บน SFU node แล้ว `lk-resume-lite` resume lite ให้ (unit จบเองตามปกติ)
- **03:31:** `zyra-sfu-lite` ใหม่ Ready · ทั้ง 2 deployment `paused` ว่าง, ready 1/1 · pod ทั้งสองมี label `zyra.center/livekit-signaling=true` · endpoint ของ `zyra-livekit` = 10.148.0.19 + 10.148.0.18 (ready ทั้งคู่) · `https://sfu.zyraworld.co/` ตอบ 200
- **ห้องกระจาย 2 เครื่อง:** `max_over_time(livekit_room_total[15m])` → main 6 · lite 3 (lite รับห้องตอน main ถูกตัด) · ตอน 03:31 ห้องกลับไปอยู่ main ทั้งหมด (2 ห้อง / 10 คน) เพราะ lite เพิ่ง restart
- **คนออนไลน์รวม** (`sum(livekit_participant_total)` ทุก 5 นาที 01:45–03:31): 14–19 ตลอดช่วง drain แล้วลดเหลือ 10 ตอนจบ — คนส่วนหนึ่งไม่ได้ต่อกลับหลังโดนตัด (ตี 3 แท็บที่ค้างไว้อาจไม่ reconnect เอง) ยังไม่ได้แยกว่ากี่คนหลุดเพราะการตัด กี่คนออกเอง
- **ต่อ:** P1-3 schedule + P1-4 drain-before-stop · runbook ต้องมีขั้น pause lite ระหว่าง roll ทั้งสองตัว

## 2026-10-20 ~01:45 — P1-1 ขึ้น prod (zyra-infra#74)

**ทำอะไร**
- Ten อนุมัติในแชทให้ merge #74 → squash `b5fe2b3` เข้า main → Argo sync `sfu-prod` ทันที
- **ก่อน merge:** ติด label `zyra.center/livekit-signaling=true` ให้ pod เดิมทั้ง 2 ตัวด้วยมือ (`kubectl label pod`) — ไม่งั้น Service `zyra-livekit` จะไม่มี endpoint เลยช่วงแรก (pod เดิมยังไม่มี label) แล้ว ingress ที่ชี้มาจะ 503
- **หลัง merge:** `kubectl rollout pause deployment zyra-sfu-lite` ก่อน Argo sync `sfu-lite-prod` — เพราะ main SFU กำลัง drain อยู่ (ห้องค้าง 3 ห้อง / 14 คน) ถ้า lite drain พร้อมกัน ห้องใหม่จะไม่มีที่ลง
- ตั้ง unit `lk-resume-lite` (systemd-run บน zyra-k3s, `/tmp/resume-lite.sh`) รอจน pod main SFU ใหม่ Ready แล้ว `rollout resume` ให้ lite เอง

**ถึงไหน** (01:50)
- ingress `sfu.zyraworld.co` / `sfu.zyra.center` → `zyra-livekit` แล้ว · endpoint = lite (ready) + main เดิม (terminating/drain, not ready) → ห้องใหม่ลง lite
- `https://sfu.zyraworld.co/` ตอบ 200
- main SFU เดิมยัง drain (สูงสุด 90 นาที) · pod ใหม่ Pending รอ host port

**verify ถึงไหน**
- ✅ Argo `sfu-prod` Synced @ b5fe2b3 · ingress backend ถูก · Service มี endpoint ตลอด
- ⏳ ยังไม่เห็น join จริงลง lite (ตอนตี 2 ไม่มีห้องใหม่) — ดู `livekit_room_total` ต่อ instance (`10.148.0.18` = lite, `10.148.0.19` = main) ช่วงเช้า
- ⏳ ยังไม่ยืนยันว่า lite roll เสร็จ (`kubectl -n sfu get deploy zyra-sfu-lite` → `spec.paused` ต้องเป็น false, pod มี label ใหม่)

**ต่อจากนี้**
- เช็คเช้า: lite resume + roll เสร็จ, ทั้ง 2 pod Ready, ห้องกระจาย 2 instance
- P1-3 schedule + P1-4 drain-before-stop

**ติดอะไร**
- ไม่มี — บทเรียน: เปลี่ยน pod template ของ LiveKit ทั้งสองตัวใน commit เดียว = drain พร้อมกัน ต้อง pause ตัวหนึ่งไว้ (ใส่ใน runbook ของ P1-4)

## 2026-10-20 — P1-1 signaling เข้าทั้ง 2 LiveKit pod + เทสปิด SFU node บน clone

**ทำอะไร**
- chart `zyra-service` เพิ่ม `podLabels`, `extraServices` และ `ingress.service` (ค่า default ว่างทั้งหมด)
- `envs/prod` + `envs/loadtest`: เพิ่ม Service `zyra-livekit` ที่ select label `zyra.center/livekit-signaling: "true"` ซึ่งติดทั้ง `zyra-sfu` และ `zyra-sfu-lite` แล้วให้ ingress ของ `sfu.*` ชี้ไปที่ Service นี้

**ถึงไหน**
- เทสบน clone เสร็จ ผ่าน
- prod ยังไม่ได้แตะ

**PR**
- [zyra-infra#74](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/74) (draft → main) ยังไม่ merge
- ใช้ branch `lt/livekit-signaling-test` ให้ clone track ระหว่างเทสเท่านั้น ห้าม merge

**verify ถึงไหน**
- `helm template` ทุก service ทุก env เทียบก่อน/หลังแล้ว เปลี่ยนแค่ `sfu`/`sfu-lite` ของ prod กับ loadtest ส่วน dev/uat เหมือนเดิมทุกตัว
- live-test บน clone (สร้างใหม่ 2026-10-20 restore prod @ 2026-10-19T17:24Z):
  - probe เข้าห้องใหม่ทุก ~3–9 วินาทีจาก lt-loadgen ผ่าน `wss://sfu.<clone>` (`lk room join` timeout 6s)
  - ปิด `lt-sfu-node-0` 4 นาที แล้วเปิดกลับ

## Before/After

| Run | ปกติ | SFU node ปิด | node กำลังเปิด | หลัง pod ready | fail ติดกันนานสุด |
|---|---|---|---|---|---|
| Before — route เดิม (`zyra-sfu` อย่างเดียว) | 10/10 | **5/78** | 0/3 | 11/21 | **86 ครั้ง (~5 นาที จน node กลับมา)** |
| After — `zyra-livekit` (ทั้ง 2 pod) | 9/9 | **30/35** | – | 14/14 | 5 ครั้ง (~33 วินาที ช่วงที่ k8s ยังไม่ถอด node ที่ดับออกจาก endpoint) |
| After + drain ก่อน (`kubectl drain` → stop VM) | 10/10 | **36/36** | 5/5 | 14/14 | **0** |

**วัดยังไง**:
- `probe.sh` บน lt-loadgen เขียนผลลง `probe-<run>.csv` (epoch, ok, ms)
- แบ่งช่วงตาม timestamp ของ event ใน script (`events-<run>.txt`)

**ช่วงเวลาที่วัด**: 2026-10-20 ราว 00:50–01:30 (เวลาไทย) ช่วงละ ~9 นาที

**ยังไม่ได้วัด**:
- ห้องที่เปิดค้างอยู่บนเครื่อง SFU ตอนปิด: ห้องหลุดแน่ (คาดไว้แล้ว) เพราะฉะนั้น schedule ต้อง drain ก่อน (P1-4)
- sfu-lite รับคนทั้งหมดคนเดียวได้แค่ไหน: ยังไม่ได้ทำ load test (header บอกไว้ราว 30 คนตาม CPU limit 1500m)
- Spotlight/วิดีโอผ่านหน้าเว็บจริง: เทสแค่ระดับ signaling/join ด้วย `lk`
- หลังเปิด node กลับ ห้องใหม่ไปลงเครื่อง SFU หรือเปล่า: ยังไม่ได้เช็ค placement

**ต่อจากนี้**
- Ten อนุมัติ #74 แล้วค่อย merge นอกเวลางาน เพราะเพิ่ม label แล้ว LiveKit ทั้งสองตัวจะ roll แบบ drain
- จากนั้นทำ P1-3 schedule กับ P1-4 drain-before-stop ต่อ (ผลรอบนี้ยืนยันว่า drain ต้องมี)

**ติดอะไร**
- รอ Ten อนุมัติ #74
- ~~clone ยังเปิดอยู่~~ → ลบแล้ว 2026-10-20 (52 resources destroyed, เช็คแล้วไม่มี lt-* เหลือ) · ข้อมูลดิบ: `zyra-loadtest/reports/sfu-signaling-2026-10-20/`
- preflight ของ clone FAIL ข้อ app version (v1.8.2 vs prod v1.8.3) ไม่กระทบเทส SFU
