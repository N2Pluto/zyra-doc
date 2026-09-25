# Load Test — วิธีรัน (คู่มือ)

> repo: `zyra-loadtest` · spec: [spec.md](spec.md) (อ่าน §4 Safety ก่อนรัน) · ผล/สถานะล่าสุด: [progress.md](progress.md)
> อัปเดต 2026-09-25 · option ทุกตัวไล่จากโค้ดจริง (`k6/scenarios/*`, `k6/lib/*`, `Makefile`, `scripts/spotlight-media.sh`)

---

## 1. ก่อนเริ่ม

**ติดตั้ง (ครั้งเดียว)**

```bash
brew install k6 livekit-cli
cd zyra-loadtest
cp .env.example .env     # แล้วใส่ TOKEN_KEY และ DATABASE_URL ให้ตรงกับ zyra-api ที่จะยิง
```

**Service ที่ต้องเปิด**

| Service | Port | ใช้กับ | วิธีเปิด |
|---|---|---|---|
| Redis | 6379 | ทุก scenario | `docker compose up -d` ที่ root ของ workspace |
| zyra-api | 3002 | ทุก scenario | รันตามปกติ |
| zyra-ws | 3003 | ทุก scenario (ยกเว้น lt07 และ lt01 ที่ใส่ `WS=0`) | รันตามปกติ |
| zyra-app | 3000 | เฉพาะ `VIA=app` | รันตามปกติ |
| LiveKit | 7880 | เฉพาะ `make spotlight-media` | `make livekit-up` |

**รูปแบบคำสั่ง**

```bash
make smoke [option...]                 # lt01
make run S=<ชื่อไฟล์> [option...]        # lt02–lt12
make spotlight-media [option...]       # ภาพ/เสียง (LiveKit)
```

**กฎสำคัญ**

- 1 bot = 1 user ที่ seed ไว้ — `VUS` มากกว่าจำนวน user script จะไม่ยอมรัน
- token หมดอายุทุก 2 ชม. — ห่างจากรอบก่อนนานให้ `make refresh` ก่อน
- รันทีละ scenario อย่าซ้อนกัน (user ชุดเดียวกันจะเตะกันเอง)
- อย่ากด Ctrl+Z ระหว่างรัน (process ค้างและจับ port dashboard 5665 ไว้) — หยุดด้วย Ctrl+C

---

## 2. Option ที่ใช้ได้กับทุก scenario

| Option | ทำอะไร | ตัวอย่าง |
|---|---|---|
| `D=1` | dashboard สดที่ http://127.0.0.1:5665 (เปิดได้เฉพาะตอนเทสรันอยู่) | `make run S=lt02-baseline-50 D=1` |
| `SAMPLES=0` | ไม่เขียนไฟล์ `samples.json.gz` (ข้อมูลทุกจุด) — ใช้กับรอบใหญ่/ยาวที่ไม่ต้องการกราฟเอง | `make run S=lt08-soak SAMPLES=0` |
| `VIA=api` \| `app` | `api` = ยิง REST ตรง zyra-api · `app` = ผ่าน Next.js เหมือน browser | `make smoke VIA=app` |
| `BASE_URL` / `API_URL` / `WS_URL` | ที่อยู่ app / api / ws (default `localhost:3000` / `3002` / `3003`) | `make smoke API_URL=http://localhost:4002` |
| `LT_ALLOW_SHARED_NODE=1` | ยอมให้ยิง `*.zyra.center` เกิน 5 คน (node เดียวกับ prod) — ใช้เมื่อทีมอนุมัติเท่านั้น | — |

prod (`zyraworld.co` / `zyra-world.com`) ยิงไม่ได้เลย ไม่มี option ปลดล็อก

---

## 3. แต่ละ scenario

### lt01-smoke — script ทำงานถูกไหม

- **คำสั่ง:** `make smoke`
- **ค่าเริ่มต้น:** 1 คน 30 วินาที · เรียก `/me` ทุกวินาที + ต่อ WS
- **ต้องมี user:** เท่ากับ `VUS`

| Option | ทำอะไร |
|---|---|
| `VUS=5` | จำนวนคน (1–5 ถ้ายิง dev บน k3s) |
| `DURATION=2m` | ระยะเวลา |
| `WS=0` | ไม่ต่อ WebSocket — REST อย่างเดียว (ใช้กับ `LT_TOKEN` ที่ไม่มี workspace) |
| `LT_TOKEN=...` | ใช้ token จาก browser (cookie `zyra_token`) เมื่อยังไม่ได้ seed |

```bash
make smoke
make smoke VUS=5 DURATION=1m
make smoke WS=0 LT_TOKEN=eyJhbGci...
```

**ดูผล:** ทุกบรรทัดใน THRESHOLDS ต้อง ✓ · error แม้ครั้งเดียวเทสหยุดเอง

### lt02-baseline-50 · lt03-scale-100 · lt08-soak — รับ 50 / 100 คนไหม · เปิดนาน ๆ แย่ลงไหม

- **คำสั่ง:** `make run S=lt02-baseline-50` (หรือ `lt03-scale-100` / `lt08-soak`)
- **ค่าเริ่มต้น:** lt02 = 50 คน 15 นาที · lt03 = 100 คน 20 นาที · lt08 = 100 คน 1 ชม.
- **ต้องมี user:** 50 / 100 / 100

| Option | ทำอะไร |
|---|---|
| `VUS=10` | จำนวนคน |
| `DURATION=2m` | ระยะเวลา |
| `MIX=idle:60,walker:30,chatter:10` | สัดส่วนพฤติกรรม (default ตามนี้) · `idle` นั่งเฉย · `walker` เดิน · `chatter` แชท · `cluster` กระโดดรอบจุดเดียว |
| `LOGIN=1` | login ด้วยฟอร์มจริงก่อน (`DURATION` ≤ 14 นาที — token จาก login อายุ 15 นาที) |

```bash
make run S=lt02-baseline-50 VUS=10 DURATION=2m
make run S=lt02-baseline-50 MIX=idle:50,walker:40,chatter:10
make run S=lt03-scale-100 D=1
make refresh TTL=3h && make run S=lt08-soak DURATION=2h    # soak เกิน 2 ชม. ต่ออายุ token ก่อน
```

**ดูผล:** `http_req_failed` < 1% · `/me` p95 < 500ms · `ws_welcome_ok` > 99% · `ws_ping_rtt_ms` p95 < 500ms · lt03: เปิด browser ดูว่าเห็นกันครบ · lt08: memory/goroutine ของ api/ws ต้องไม่โตต่อเนื่อง

### lt04-ramp-1000 — พังที่กี่คน

- **คำสั่ง:** `make run S=lt04-ramp-1000`
- **ค่าเริ่มต้น:** 50 → 100 → 250 → 500 → 1000 คน ขั้นละ 5 นาที รวม 25 นาที
- **ต้องมี user:** 1000 (ต้อง `make clean YES=1` แล้ว seed ใหม่ `USERS=1000`)

| Option | ทำอะไร |
|---|---|
| `VUS=100` | จำนวนคนสูงสุด — ทุกขั้นย่อตามสัดส่วน (100 → 5, 10, 25, 50, 100) |
| `DURATION=10m` | ระยะเวลารวม — จุดเริ่มแต่ละขั้นย่อตามสัดส่วน |
| `MIX=...` | เหมือน lt02 |

```bash
make run S=lt04-ramp-1000 VUS=100 DURATION=10m
```

**ดูผล:** ไม่มีผ่าน/ไม่ผ่าน — ดูว่าขั้นไหนเริ่มช้าหรือ error · ควรรัน 2 รอบ ปิด/เปิด flag `VO_TICK_REALTIME_DT` / `VO_TICK_ACTIVE_SET` ของ zyra-ws

### lt05-aoi-cluster — ทุกคนยืนรวมจุดเดียวไหวไหม

- **คำสั่ง:** `make run S=lt05-aoi-cluster`
- **ค่าเริ่มต้น:** 20 → 50 → 100 คน ขั้นละ 5 นาที รวม 15 นาที · ทุกตัวกระโดดรอบจุดเดียว
- **ต้องมี user:** 100

| Option | ทำอะไร |
|---|---|
| `CLUSTER_TILE=40,30` | บังคับทุก bot เกิดที่ tile นี้ (ควรเป็น tile ที่เดินได้ — ไม่ใส่ bot เกิดที่ 0,0) |
| `VUS` / `DURATION` | เหมือน lt04 |

```bash
make run S=lt05-aoi-cluster CLUSTER_TILE=40,30 VUS=30 DURATION=5m
```

**ดูผล:** ไม่มีผ่าน/ไม่ผ่าน — ดู log `vo tick metrics` ของ zyra-ws (tick time / fanout) · `ws_goto_rejected` = คลิกเดินชนกำแพง ปกติ

### lt06-many-workspaces — หลายบริษัทพร้อมกันไหวไหม

- **คำสั่ง:** `make run S=lt06-many-workspaces`
- **ค่าเริ่มต้น:** 100 คน กระจายทุก workspace 15 นาที
- **ต้องเตรียม:** seed หลาย workspace

```bash
make clean YES=1
make seed SOURCE=<template id> USERS=100 WORKSPACES=4 YES=1
make run S=lt06-many-workspaces VUS=40 DURATION=5m
```

| Option | ทำอะไร |
|---|---|
| `VUS` / `DURATION` / `MIX` | เหมือน lt02 · bot วนกระจายทีละ workspace เสมอไม่ว่า `VUS` เท่าไหร่ |

**ดูผล:** p95 < 500ms · CPU ของ ws แต่ละ pod ไม่มีตัวไหนหนักผิดปกติ

### lt07-morning-spike — 9 โมงทุกคนเข้าพร้อมกันไหวไหม

- **คำสั่ง:** `make run S=lt07-morning-spike`
- **ค่าเริ่มต้น:** 100 คน login จริง + เข้า office ภายใน 60 วินาที แล้วอยู่ต่อ 3 นาที (ไม่ต่อ WS)
- **ต้องมี user:** 100

| Option | ทำอะไร |
|---|---|
| `VUS` / `DURATION` | เหมือน lt02 (`DURATION` ≤ 14 นาที) |
| `LOGIN=0` | ไม่ login จริง ใช้ token ที่ seed ไว้ |
| `LT_PASSWORD=...` | รหัสของ user ทดสอบ (default `LoadTest#2026` — ต้องตรงกับตอน seed) |

```bash
make run S=lt07-morning-spike VUS=20 DURATION=2m
```

**ดูผล:** `enter_office_ms` p95 < 1s · `login_ok` > 99% · error < 1%
**ความปลอดภัย:** ก่อนเริ่มลอง login 1 คน ถ้ารหัสผิดหยุดทันที (บัญชีล็อกเมื่อผิด 3 ครั้ง)

### lt09-reconnect-storm — หลุดพร้อมกันแล้วกลับมาได้ไหม

- **คำสั่ง:** `make run S=lt09-reconnect-storm`
- **ค่าเริ่มต้น:** 100 คน 6 นาที · ตัด WS ทุกคนพร้อมกันที่นาทีที่ 3 แล้วต่อใหม่ทันที
- **ต้องมี user:** 100

| Option | ทำอะไร |
|---|---|
| `RECONNECT_AT=2m` | เวลาที่ตัดพร้อมกัน |
| `VUS` / `DURATION` | เหมือน lt02 |

```bash
make run S=lt09-reconnect-storm VUS=20 DURATION=3m RECONNECT_AT=1m30s
```

**ดูผล:** `ws_welcome_ok` > 99% · ไม่มี 503 จากการเช็กสมาชิก

### lt10-spotlight-smoke — Spotlight ทำงานครบทุกขั้นไหม

- **คำสั่ง:** `make run S=lt10-spotlight-smoke`
- **ค่าเริ่มต้น:** presenter 1 + คนดู 4 (1 คนอยู่ในห้องประชุม) ไลฟ์ 1 รอบ 40 วินาที รวม 1.5 นาที
- **ต้องเตรียม:** `make spotlight YES=1` (ใส่ Spotlight zone ครั้งเดียว)
- **ต้องมี user:** 5

| Option | ทำอะไร |
|---|---|
| `LT_DEBUG=1` | พิมพ์ทุก event ของ Spotlight ที่คนดูได้รับ |

```bash
make run S=lt10-spotlight-smoke
make run S=lt10-spotlight-smoke LT_DEBUG=1
```

**ดูผล:** ทุกข้อ 100% — `spotlight_start_ok`, `_state_ok`, `_bell_ok`, `_meeting_ok`, `_end_ok`

### lt11-spotlight-audience — 1 เวทีรับคนดูได้กี่คน (ws/api)

- **คำสั่ง:** `make run S=lt11-spotlight-audience`
- **ค่าเริ่มต้น:** คนดู 50 → 100 → 250 → 500 ขั้นละ 5 นาที รวม 20 นาที · ไลฟ์ 90 วินาที พัก 30 วินาที · 20% อยู่ในห้องประชุม
- **ต้องมี user:** คนดู + 1 (presenter) → ขนาดเต็ม 501

| Option | ทำอะไร |
|---|---|
| `VUS=40` | จำนวนคนดูทั้งหมด — ทุกขั้นย่อตามสัดส่วน (presenter +1 ให้อัตโนมัติ) |
| `DURATION=8m` | ระยะเวลารวม — จุดเริ่มแต่ละขั้นย่อตาม แต่ไลฟ์รอบแรกยังเริ่มที่ 90 วินาที |
| `LIVE=60s` | ไลฟ์รอบละนานเท่าไหร่ |
| `GAP=30s` | พักระหว่างรอบ |
| `MEETING_PCT=0` | สัดส่วนคนดูในห้องประชุม (0 = ไม่มี, default 20) |
| `LT_DEBUG=1` | log event |

```bash
make run S=lt11-spotlight-audience VUS=40 DURATION=8m
make run S=lt11-spotlight-audience VUS=100 LIVE=60s GAP=30s MEETING_PCT=0
```

**ดูผล:** `state_ok` / `bell_ok` / `end_ok` / `meeting_ok` ≥ 99% · `spotlight_fanout_ms` p95 < 1s · `spotlight_bell_ms` p95 < 3s · media-token p95 < 500ms · `http_req_failed` < 1% — ดูว่าเริ่มตกตอนคนดูกี่คน

### lt12-spotlight-reconnect — presenter หลุดกลางไลฟ์แล้วเป็นยังไง

- **คำสั่ง:** `make run S=lt12-spotlight-reconnect`
- **ค่าเริ่มต้น:** คนดู 30 คน ~7 นาที · รอบ 1 presenter หลุดแล้วกลับใน 20 วินาที · รอบ 2 หลุดแล้วไม่กลับ
- **ต้องมี user:** คนดู + 1

| Option | ทำอะไร |
|---|---|
| `VUS=5` | จำนวนคนดู |
| `LT_DEBUG=1` | log event |

ไม่ควรย่อ `DURATION` — ต้องรอให้ server ครบเวลารอ 2 นาที

```bash
make run S=lt12-spotlight-reconnect VUS=5
```

**ดูผล:** `spotlight_resume_ok` > 99% (รอบ 1 กลับมาเป็นไลฟ์เดิม) · `spotlight_end_ok` > 99% (รอบ 2 server จบไลฟ์เอง)

### spotlight-media — ภาพ/เสียงส่งให้คนดูได้กี่คน (LiveKit)

- **คำสั่ง:** `make livekit-up` แล้ว `make spotlight-media`
- **ค่าเริ่มต้น:** presenter 1 (วิดีโอ + เสียง) · คนดู 10 → 25 → 50 → 100 → 150 → 200 ขั้นละ 60 วินาที · หยุดเมื่อ loss > 2% หรือมี error

| Option | ทำอะไร |
|---|---|
| `SUBS="10 50 100"` | จำนวนคนดูแต่ละขั้น |
| `STEP=90` | วินาทีต่อขั้น |
| `SCREEN=1` | presenter แชร์จอด้วย (วิดีโอ 2 track) |
| `RESOLUTION=medium` | `high` / `medium` / `low` (default `high`) |
| `MAX_LOSS=5` | หยุดเมื่อ packet loss เกินกี่ % (default 2) |
| `NUM_PER_SECOND=20` | คนดูเข้าห้องกี่คนต่อวินาที (default 10) |
| `LK_IN_DOCKER=0` | ใช้ `lk` บนเครื่องแทนใน docker (ยิง LiveKit บนเครื่อง default = ใน docker เพราะ proxy ของ Docker Desktop ตันก่อน) |
| `LIVEKIT_URL` / `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET` | LiveKit ที่จะยิง (ใน `.env` · default `localhost:7880` / `devkey` / `secret`) |
| `LT_ALLOW_REMOTE_SFU=1` | ยอมยิง LiveKit ที่ไม่ใช่ localhost |
| `LT_ALLOW_SHARED_NODE=1` | ต้องใส่เพิ่มถ้าเป็น `*.zyra.center` |

```bash
make spotlight-media
make spotlight-media SUBS="50 100 150" STEP=90 SCREEN=1
LT_ALLOW_REMOTE_SFU=1 make spotlight-media SUBS="100 200 300 500"   # หลังแก้ LIVEKIT_* ใน .env เป็น server จริง
make livekit-down
```

**ดูผล:** ตารางในเทอร์มินัล + `reports/spotlight-media-<เวลา>/summary.md` — ขั้นที่หยุดคือเพดาน · bitrate ต่อคนตกมาก = LiveKit เริ่มลดคุณภาพภาพแล้ว แม้ loss ยังไม่ถึงเกณฑ์

**ยิง server จริง:** ใช้ script เดิม แก้แค่ `.env` · รันจาก VM ใกล้ LiveKit ไม่ใช่ MacBook (คนดู 100 คน ≈ 140 Mbps) · ยิง LiveKit ที่แยกจาก prod (spec S-01) · คอลัมน์ CPU/RAM จะว่าง ต้องดูจาก Grafana / `kubectl top`

---

## 4. คำสั่งจัดการข้อมูลทดสอบ

| คำสั่ง | ทำอะไร |
|---|---|
| `make seed` | ดูรายการ template ที่ clone ได้ |
| `make seed SOURCE=<id> USERS=100 WORKSPACES=1 YES=1` | สร้าง `lt_0001…` + `lt_ws_01…` (+ Spotlight zone) · ต้อง clean ก่อนถ้ามีอยู่แล้ว · `TTL=3h` = อายุ token (default 2h) |
| `make refresh [TTL=3h]` | ต่ออายุ token โดยไม่แตะ DB |
| `make spotlight YES=1` | ใส่ Spotlight zone ลงทุก workspace ทดสอบ (seed ทำให้อัตโนมัติ) |
| `make tokens USER_ID=<id> USERNAME=<u>` | token ให้ user จริง 1 คน (ใช้กับ smoke) |
| `make clean-dry` | ดูว่าจะลบอะไร (ลบจริงแล้ว rollback) |
| `make clean YES=1` | ลบ user/workspace/ข้อมูลทดสอบ `lt_` ทั้งหมด (DB + Redis) |
| `make livekit-up` / `make livekit-down` | เปิด/ปิด LiveKit บนเครื่อง (service `livekit` ใน `docker-compose.yaml` ที่ root) |
| `make check` | เช็ก seeder + ทุก scenario |

ไม่ใส่ `YES=1` = ไม่เขียนอะไรลง DB (dry run)

User ทดสอบ: `lt_NNNN@loadtest.invalid` / `LoadTest#2026` — เปิดดูใน browser ได้ แต่อย่าใช้ user ที่ bot กำลังใช้อยู่ (จะเตะกัน)

---

## 5. ดูผล

- **เทอร์มินัล:** ส่วน `THRESHOLDS` ตอนจบ — ✓ ผ่าน · ✗ ไม่ผ่าน
- **เช็กเร็ว:** `echo $?` หลังจบ — `0` ผ่านทุกเกณฑ์ · `99` มีเกณฑ์ไม่ผ่าน
- **ไฟล์ผล:** ทุกครั้งที่ `make smoke` / `make run` ได้โฟลเดอร์ของรอบนั้น `reports/<scenario>-<วันที่-เวลา>/`

  | ไฟล์ในโฟลเดอร์ | คืออะไร | เปิดยังไง |
  |---|---|---|
  | `summary.json` | ค่าสรุปตอนจบ (p95, rate, ผ่าน/ไม่ผ่าน) | editor / script |
  | `report.html` | dashboard ของ k6 แบบบันทึกไว้ — กราฟตามเวลาของทั้งรอบ | ดับเบิลคลิกเปิดใน browser · เทสสั้นกว่า ~30 วินาทีจะไม่ได้ไฟล์นี้ |
  | `samples.json.gz` | ทุกค่าที่วัดได้พร้อมเวลา 1 บรรทัดต่อ 1 จุด (k6 `--out json`) — ไว้ทำกราฟเอง | `zcat < samples.json.gz \| head` · รอบใหญ่/ยาวไฟล์ใหญ่มาก `SAMPLES=0` ถ้าไม่ต้องการ |

  `make spotlight-media` เขียนแยกที่ `reports/spotlight-media-<เวลา>/summary.md`
- **Progress bar ค้าง 0% จนจบ = ปกติ:** bot แต่ละตัวทำงานรอบเดียวยาว ๆ · ดูเวลาจากบรรทัด `running (…)` หรือใช้ `D=1` · ✓ หน้าชื่อ scenario ในแถบ = รันจบ ไม่ใช่ผ่านเกณฑ์
