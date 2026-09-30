# Load Test — วิธีรัน (คู่มือ)

> repo: `zyra-loadtest` · spec: [spec.md](spec.md) (อ่าน §4 Safety ก่อนรัน) · ผล/สถานะล่าสุด: [progress.md](progress.md)
> อัปเดต 2026-09-28 · option ทุกตัวไล่จากโค้ดจริง (`k6/scenarios/*`, `k6/lib/*`, `Makefile`, `scripts/spotlight-media.sh`, `analyze/`)

---

## 1. ก่อนเริ่ม

**ติดตั้ง (ครั้งเดียว)**

```bash
brew install k6 livekit-cli
cd zyra-loadtest
cp .env.example .env     # แล้วใส่ TOKEN_KEY และ DATABASE_URL ให้ตรงกับ zyra-api ที่จะยิง
                         # ถ้าจะใช้ AI สรุปผล ใส่ ANTHROPIC_API_KEY ด้วย (ไม่ใส่ก็รันเทสได้ตามปกติ)
```

**Service ที่ต้องเปิด**

| Service | Port | ใช้กับ | วิธีเปิด |
|---|---|---|---|
| Redis | 6379 | ทุก scenario | `docker compose up -d` ที่ root ของ workspace |
| zyra-api | 3002 | ทุก scenario | รันตามปกติ |
| zyra-ws | 3003 | ทุก scenario (ยกเว้น lt07 และ lt01 ที่ใส่ `WS=0`) | รันตามปกติ |
| zyra-app | 3000 | เฉพาะ `VIA=app` | รันตามปกติ |
| LiveKit | 7880 (+ metrics 6789) | `make spotlight-media` / `meeting-media` / `meeting-churn` | `make livekit-up` (v1.13.0 เหมือน prod) |

**รูปแบบคำสั่ง**

```bash
make smoke [option...]                 # lt01
make run S=<ชื่อไฟล์> [option...]        # lt02–lt17
make spotlight-media [option...]       # ภาพ/เสียง Spotlight (LiveKit)
make meeting-media [option...]         # ภาพ/เสียง meeting หลายห้อง (LiveKit)
make summarize [RUN=...]               # ให้ AI สรุปผลของรอบที่รันไปแล้ว
make dashboard                         # หน้ารวมผลทุกรอบ + แชทถาม AI → http://127.0.0.1:5666
```

**กฎสำคัญ**

- 1 bot = 1 user ที่ seed ไว้ — `VUS` มากกว่าจำนวน user script จะไม่ยอมรัน (ตอนนี้ seed ไว้ 500 คน)
- token หมดอายุทุก 2 ชม. — ห่างจากรอบก่อนนานให้ `make refresh` ก่อน
- รันทีละ scenario อย่าซ้อนกัน (user ชุดเดียวกันจะเตะกันเอง)
- หยุดเทสด้วย **Ctrl+C** เท่านั้น ห้ามกด **Ctrl+Z** — Ctrl+Z แค่พัก process ไว้ มันจะค้างและจับ port 5665 ทำให้รอบต่อไปเปิด dashboard ไม่ได้ (ถ้าเผลอกด ให้พิมพ์ `fg` แล้วกด Ctrl+C หรือ `kill -9 <PID>`)

---

## 2. Option ที่ใช้ได้กับทุก scenario

| Option | ทำอะไร | ตัวอย่าง |
|---|---|---|
| `D=1` | dashboard สดที่ http://127.0.0.1:5665 (เปิดได้เฉพาะตอนเทสรันอยู่) · ไม่ใส่ก็ยังได้ `report.html` ไว้ดูย้อนหลัง (ส่วนที่ 6) | `make run S=lt02-baseline-50 D=1` |
| `AI=1` | พอเทสจบ ให้ AI (Claude) อ่านผลแล้วเขียนสรุปภาษาไทย `analysis.md` ลงโฟลเดอร์ของรอบนั้น (ส่วนที่ 5) · สรุปให้แม้เทสไม่ผ่าน และไม่เปลี่ยนผลของเทส · ใส่ `AI=1` ใน `.env` ถ้าอยากให้สรุปทุกรอบ | `make run S=lt11-spotlight-audience VUS=40 AI=1` |
| `SAMPLES=0` | ไม่เขียน `samples.json.gz` (ข้อมูลทุกจุดพร้อมเวลา) — ใช้กับรอบใหญ่/ยาวที่ไม่ต้องการทำกราฟเอง เพราะไฟล์อาจใหญ่มาก | `make run S=lt08-soak SAMPLES=0` |
| `VIA=api` \| `app` | `api` = ยิง REST ตรง zyra-api (ค่าเริ่มต้นใน `.env.example`) · `app` = ผ่าน Next.js เหมือน browser จริง | `make smoke VIA=app` |
| `BASE_URL` / `API_URL` / `WS_URL` | ที่อยู่ app / api / ws (default `localhost:3000` / `3002` / `3003`) | `make smoke API_URL=http://localhost:4002` |
| `LT_ALLOW_SHARED_NODE=1` | ยอมให้ยิง `*.zyra.center` เกิน 5 คน (node เดียวกับ prod) — ใช้เมื่อทีมอนุมัติเท่านั้น | — |

prod (`zyraworld.co` / `zyra-world.com`) ยิงไม่ได้เลย ไม่มี option ปลดล็อก

---

## 3. แต่ละ scenario

### lt01-smoke

- **ทดสอบอะไร:** script ทำงานถูกไหม — เช็กว่า URL, token, user และการต่อ WebSocket ใช้ได้ก่อนรันตัวอื่น
- **ทำไมต้องมี:** ถ้า script พัง ตัวเลขจากการรันหนัก ๆ จะเชื่อไม่ได้ทั้งหมด
- **คำสั่ง:** `make smoke`
- **ค่าเริ่มต้น:** 1 คน 30 วินาที · เรียก `/api/user/me` ทุกวินาที + ต่อ WS ค้างไว้
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

### lt02-baseline-50

- **ทดสอบอะไร:** 1 office รับ 50 คนพร้อมกันสบายไหม — bot นั่งเฉย 60% / เดิน 30% / แชท 10% เหมือนการใช้งานจริง
- **ทำไมต้องมี:** เป็นตัวเลขตั้งต้นไว้เทียบทุกรอบ · prod เริ่มอิ่มที่ประมาณ 40–60 คน

### lt03-scale-100

- **ทดสอบอะไร:** 1 office รับ 100 คนไหวไหม และทุกคนยังเห็นกันครบ ไม่มีตัวละครผี (ค้างหลังคนออก/ต่อใหม่)
- **ทำไมต้องมี:** ปิดข้อ A-03 ของ VirtualOffice (เป้า 100 คนต่อ office)

### lt08-soak

- **ทดสอบอะไร:** เปิดทิ้งไว้นาน 1–2 ชั่วโมงแล้วระบบแย่ลงไหม (memory / goroutine รั่ว, service restart)
- **ทำไมต้องมี:** ปัญหารั่วเห็นแค่ในรอบยาว · ต้องผ่านก่อนเปิด Movement V2 เป็นค่าเริ่มต้น

### lt02 · lt03 · lt08 — คำสั่งและ option ชุดเดียวกัน

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
make refresh TTL=3h && make run S=lt08-soak DURATION=2h SAMPLES=0   # soak เกิน 2 ชม. ต่ออายุ token ก่อน · SAMPLES=0 กันไฟล์ใหญ่เกิน
```

**ดูผล:** `http_req_failed` < 1% · `/me` p95 < 500ms · `ws_welcome_ok` > 99% · `ws_ping_rtt_ms` p95 < 500ms · lt03: เปิด browser ดูว่าเห็นกันครบ · lt08: memory/goroutine ของ api/ws ต้องไม่โตต่อเนื่อง

### lt04-ramp-1000

- **ทดสอบอะไร:** ระบบพังที่กี่คน — เพิ่มคนทีละขั้นใน office เดียวจนเจอจุดที่เริ่มช้าหรือ error
- **ทำไมต้องมี:** ผลนี้ใช้ตัดสินว่าต้องทำ tick overhaul Phase B/C ของ zyra-ws หรือไม่
- **คำสั่ง:** `make run S=lt04-ramp-1000`
- **ค่าเริ่มต้น:** 50 → 100 → 250 → 500 → 1000 คน ขั้นละ 5 นาที รวม 25 นาที
- **ต้องมี user:** 1000 (ตอนนี้มี 500 ต้อง `make clean YES=1` แล้ว seed ใหม่ `USERS=1000`)

| Option | ทำอะไร |
|---|---|
| `VUS=100` | จำนวนคนสูงสุด — ทุกขั้นย่อตามสัดส่วน (100 → 5, 10, 25, 50, 100) |
| `DURATION=10m` | ระยะเวลารวม — จุดเริ่มแต่ละขั้นย่อตามสัดส่วน |
| `MIX=...` | เหมือน lt02 |

```bash
make run S=lt04-ramp-1000 VUS=100 DURATION=10m
```

**ดูผล:** ไม่มีผ่าน/ไม่ผ่าน — ดูว่าขั้นไหนเริ่มช้าหรือ error (`report.html` เห็นเป็นกราฟตามเวลา) · ควรรัน 2 รอบ ปิด/เปิด flag `VO_TICK_REALTIME_DT` / `VO_TICK_ACTIVE_SET` ของ zyra-ws

### lt05-aoi-cluster

- **ทดสอบอะไร:** ทุกคนยืนรวมจุดเดียวแล้วขยับพร้อมกันไหวไหม (กรณีแย่สุดของการส่งตำแหน่ง)
- **ทำไมต้องมี:** คนที่อยู่ใกล้กันต้องส่งตำแหน่งหากันทุกคน ข้อมูลโตแบบ ~N² · เกิดจริงตอนรวมพลหรือจัด event
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

### lt06-many-workspaces

- **ทดสอบอะไร:** หลายบริษัท (หลาย workspace) ใช้งานพร้อมกันไหวไหม
- **ทำไมต้องมี:** zyra-ws ส่งแต่ละ workspace ไปอยู่ pod เดียว จึงต้องดูว่ามี pod ไหนรับหนักผิดปกติ
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

### lt07-morning-spike

- **ทดสอบอะไร:** 9 โมงเช้าทุกคน login และเข้า office พร้อมกันไหวไหม — วัดแรงกระแทกตอนเริ่มงาน
- **ทำไมต้องมี:** ช่วงเข้าพร้อมกันหนักสุดของวัน ทั้ง login และโหลดข้อมูล map ก้อนใหญ่
- **คำสั่ง:** `make run S=lt07-morning-spike`
- **ค่าเริ่มต้น:** 100 คน login จริง + เข้า office ภายใน 60 วินาที แล้วอยู่ต่อ 3 นาที (REST อย่างเดียว ไม่ต่อ WS)
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
**ความปลอดภัย:** ก่อนเริ่มลอง login 1 คน ถ้ารหัสผิดหยุดทันที ไม่ปล่อยให้คนอื่นลองต่อ (บัญชีล็อกเมื่อผิด 3 ครั้ง)

### lt09-reconnect-storm

- **ทดสอบอะไร:** ทุกคนหลุดพร้อมกันแล้วต่อกลับเข้ามาได้ครบไหม
- **ทำไมต้องมี:** เกิดจริงตอน deploy · ทุกการต่อ WS ต้องให้ zyra-api เช็กสมาชิกทันที (ไม่มี cache) api จึงโดนหนักพร้อมกัน
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

**ดูผล:** `ws_welcome_ok` > 99% (ต่อกลับได้ครบ) · ไม่มี 503 จากการเช็กสมาชิก

### lt10-spotlight-smoke

- **ทดสอบอะไร:** Spotlight ทำงานครบทุกขั้นไหม — เริ่มไลฟ์ → คนดูได้แจ้งเตือน → ขอ media token → กระดิ่งขึ้น → ห้องประชุมกด Join → จบไลฟ์
- **ทำไมต้องมี:** เช็กความพร้อมก่อนรัน Spotlight ตัวอื่น
- **คำสั่ง:** `make run S=lt10-spotlight-smoke`
- **ค่าเริ่มต้น:** presenter 1 + คนดู 4 (1 คนอยู่ในห้องประชุม) ไลฟ์ 1 รอบ 40 วินาที รวม 1.5 นาที
- **ต้องเตรียม:** `make spotlight YES=1` (ใส่ Spotlight zone ลง map ครั้งเดียว)
- **ต้องมี user:** 5

| Option | ทำอะไร |
|---|---|
| `LT_DEBUG=1` | พิมพ์ทุก event ของ Spotlight ที่คนดูได้รับ (ใช้ตอนหาสาเหตุ) |

```bash
make run S=lt10-spotlight-smoke
make run S=lt10-spotlight-smoke LT_DEBUG=1
```

**ดูผล:** ทุกข้อ 100% — `spotlight_start_ok`, `_state_ok`, `_bell_ok`, `_meeting_ok`, `_end_ok`

### lt11-spotlight-audience

- **ทดสอบอะไร:** 1 เวที Spotlight รับคนดูได้กี่คน (ฝั่ง ws/api) — เพิ่มคนดูทีละขั้นจนเจอจุดที่เริ่มตก
- **ทำไมต้องมี:** ทุกครั้งที่เริ่มไลฟ์ ws ต้องแจ้งทุกคนบน floor, api เขียนแถวกระดิ่งเท่าจำนวนคนดู และทุกคนขอ token พร้อมกัน
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

### lt12-spotlight-reconnect

- **ทดสอบอะไร:** presenter เน็ตหลุดกลางไลฟ์แล้วระบบจัดการถูกไหม
- **ทำไมต้องมี:** ต้องยืนยันว่าหลุดแล้วกลับมาทันใน 2 นาทีเป็นไลฟ์เดิม ถ้าไม่กลับ ระบบต้องจบไลฟ์เองและคนดูได้แจ้งเตือน
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

### spotlight-media (`scripts/spotlight-media.sh`)

- **ทดสอบอะไร:** ภาพและเสียงของ presenter 1 คน ส่งให้คนดูได้กี่คนก่อนคุณภาพแย่ (ฝั่ง LiveKit)
- **ทำไมต้องมี:** LiveKit ต้องส่งต่อ stream ให้คนดูทุกคน ภาระโตตามจำนวนคนดู น่าจะเป็นจุดที่ตันก่อน ws/api (k6 ต่อ WebRTC ไม่ได้ จึงใช้ `lk load-test` ของ LiveKit แทน)
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

**ดูผล:** ตารางในเทอร์มินัล + `reports/spotlight-media-<เวลา>/summary.md` — ขั้นที่หยุดคือเพดาน · bitrate ต่อคนตกมาก = LiveKit เริ่มลดคุณภาพภาพแล้ว แม้ loss ยังไม่ถึงเกณฑ์ · ตัวนี้ไม่ได้ `report.html` / `samples.json.gz` เพราะไม่ได้ใช้ k6 · `AI=1` ใช้ไม่ได้ ให้สรุปด้วย `make summarize RUN=reports/spotlight-media-<เวลา>` แทน

**ยิง server จริง:** ใช้ script เดิม แก้แค่ `.env` · รันจาก VM ใกล้ LiveKit ไม่ใช่ MacBook (คนดู 100 คน ≈ 140 Mbps) · ยิง LiveKit ที่แยกจาก prod (spec S-01) · คอลัมน์ CPU/RAM จะว่าง ต้องดูจาก Grafana / `kubectl top`

---

### lt14-meeting-smoke

- **ทดสอบอะไร:** meeting ทำงานครบทุกขั้นไหม — เข้าห้อง → ขอ media token → ได้ข้อมูลห้อง → ไมค์/กล้อง/ยกมือ/emoji/แชท → แชร์จอ → ออก
- **ทำไมต้องมี:** เช็กความพร้อมก่อนรัน meeting ตัวอื่น
- **คำสั่ง:** `make run S=lt14-meeting-smoke`
- **ค่าเริ่มต้น:** 1 ห้อง 3 คน เปิดกล้อง + คนแรกแชร์จอ ทำทุกอย่างภายใน ~1 นาที รวม 1 นาทีครึ่ง
- **ต้องมี user:** 3

**ดูผล:** ทุกข้อ 100% — `meeting_enter_ok`, `meeting_echo_ok`, `meeting_share_ok`

### lt15-meeting-count

- **ทดสอบอะไร:** มีกี่ห้องประชุมพร้อมกันถึงเริ่มพัง (ฝั่ง ws/api)
- **ทำไมต้องมี:** ทุกห้องมีคนพูด เปิดกล้อง ยกมือ แชท แชร์จอ พร้อมกัน และทุกครั้งที่มีคนเข้า-ออกห้อง ws แจ้งทั้ง workspace
- **คำสั่ง:** `make run S=lt15-meeting-count`
- **ค่าเริ่มต้น:** เพิ่มห้องทีละขั้น 1 → 5 → 10 → 18 ห้อง ห้องละ 5 คน ขั้นละ 3 นาที รวม 12 นาที · รูปแบบ `mixed`
- **ต้องมี user:** ห้อง × คน (ค่าเริ่มต้น 90)

| Option | ทำอะไร |
|---|---|
| `PROFILE=audio` \| `camera` \| `share` \| `mixed` | `audio` ไมค์อย่างเดียว · `camera` ทุกคนเปิดกล้อง · `share` เปิดกล้อง + คนแรกของห้องแชร์จอ · `mixed` ทุก 10 ห้อง = แชร์จอ 1 / กล้อง 3 / เสียง 6 (default) |
| `MEETINGS=36` | จำนวนห้องรวม — ทุกขั้นย่อ/ขยายตามสัดส่วน (ปัดต่อขั้น อย่างน้อยขั้นละ 1) |
| `PEOPLE=6` | คนต่อห้อง |
| `DURATION=6m` | ระยะเวลารวม |
| `WORKSPACES_MAX=2` | ใช้กี่ workspace (เกิน 18 ห้องต้อง seed หลาย workspace) |

```bash
make run S=lt15-meeting-count PROFILE=camera
make run S=lt15-meeting-count MEETINGS=6 PEOPLE=3 DURATION=4m
make clean YES=1 && make seed SOURCE=<id> USERS=400 WORKSPACES=4 YES=1
make run S=lt15-meeting-count MEETINGS=60 PROFILE=share            # เกิน 18 ห้อง
```

**ดูผล:** `meeting_enter_ms` p95 < 2s · `meeting_enter_ok` / `meeting_echo_ok` / `meeting_share_ok` ≥ 99% · media-token p95 < 500ms · error < 1% — ดูว่าขั้นไหนเริ่มตก (`report.html`)

### lt16-meeting-size

- **ทดสอบอะไร:** ห้องประชุมเดียวรับได้กี่คน
- **ทำไมต้องมี:** ทุกข้อความในห้อง (ไมค์/กล้อง/ยกมือ/แชท) ต้องส่งถึงทุกคน ภาระโตตามจำนวนคนในห้อง · LiveKit รับได้ 50 คนต่อห้อง
- **คำสั่ง:** `make run S=lt16-meeting-size`
- **ค่าเริ่มต้น:** ห้องเดียว 5 → 10 → 20 → 50 คน ขั้นละ 3 นาที รวม 12 นาที · เปิดกล้องทุกคน
- **ต้องมี user:** 50

| Option | ทำอะไร |
|---|---|
| `PEOPLE=20` | ขนาดห้องขั้นสุดท้าย (ขั้นก่อนหน้าย่อตาม) |
| `PROFILE=share` | รูปแบบ (เหมือน lt15) |
| `DURATION=6m` | ระยะเวลารวม |

**ดูผล:** เหมือน lt15

### lt17-meeting-churn

- **ทดสอบอะไร:** คนเดินเข้า-ออกห้องประชุมบ่อย ๆ แล้วระบบยังไหวไหม
- **ทำไมต้องมี:** ทุกครั้งที่เข้าห้องต้องขอ token ใหม่ และ ws แจ้งทั้ง workspace · prod เคยเจอปัญหาจากการเข้า-ออกถี่
- **คำสั่ง:** `make run S=lt17-meeting-churn`
- **ค่าเริ่มต้น:** 5 ห้อง × 5 คน 10 นาที · ทุกคนอยู่ 20–40 วินาที ออก 3–8 วินาที แล้วกลับเข้าใหม่
- **ต้องมี user:** 25

| Option | ทำอะไร |
|---|---|
| `MEETINGS` / `PEOPLE` / `DURATION` / `PROFILE` | เหมือน lt15 |

**ดูผล:** `meeting_enter_ms` p95 < 2s ตลอดรอบ ไม่แย่ลงตามเวลา (ดูกราฟใน `report.html`) · `meeting_enters` = จำนวนครั้งที่เข้าห้องทั้งหมด

### meeting-media (`scripts/meeting-media.sh`)

- **ทดสอบอะไร:** **มีกี่ห้องประชุมพร้อมกันถึงพัง แยกตามรูปแบบการใช้** (ฝั่ง LiveKit) — เสียงอย่างเดียว / เปิดกล้องทุกคน / เปิดกล้อง + แชร์จอ
- **ทำไมต้องมี:** ภาพและเสียงหนักที่ LiveKit ไม่ใช่ ws/api · ทุกคนในห้องต้องได้ stream ของทุกคน
- **คำสั่ง:** `make livekit-up` แล้ว `make meeting-media`
- **ค่าเริ่มต้น:** ทุกรูปแบบ (`audio camera share`) · ห้อง 1 → 2 → 5 → 10 → 20 → 40 · ห้องละ 5 คน · ขั้นละ 60 วินาที · รูปแบบไหนห้องแย่สุด loss > 2% หรือมี error ก็หยุดรูปแบบนั้น

| Option | ทำอะไร |
|---|---|
| `PROFILES="camera share"` | รูปแบบที่จะทดสอบ |
| `ROOMS="5 10 15 20"` | จำนวนห้องแต่ละขั้น |
| `PEOPLE=6` | คนต่อห้อง |
| `STEP=90` | วินาทีต่อขั้น |
| `RESOLUTION=high` | ความละเอียดกล้อง (default `medium`) |
| `SHARE_RESOLUTION=medium` | ความละเอียดจอที่แชร์ (default `high`) |
| `LAYOUT=4x4` | layout ของคนดู (default `3x3`) |
| `MAX_LOSS=5` | หยุดเมื่อ loss เกินกี่ % (default 2) |
| `LIVEKIT_*` / `LT_ALLOW_REMOTE_SFU` / `LT_ALLOW_SHARED_NODE` | เหมือน spotlight-media |

```bash
make meeting-media
make meeting-media PROFILES=share ROOMS="5 10 15 20" PEOPLE=6
```

**ดูผล:** `reports/meeting-media-<เวลา>/summary.md` — ตารางแยกรูปแบบ × จำนวนห้อง (loss ห้องแย่สุด/เฉลี่ย, bitrate ต่อคน, CPU/RAM/goroutine ของ LiveKit) และท้ายไฟล์บอกว่า **แต่ละรูปแบบพังที่กี่ห้อง**
**ข้อจำกัด:** ใน `lk load-test` คนส่งกับคนดูเป็นคนละ connection — ห้อง 5 คนเปิดกล้อง = 15 connection (stream ที่ LiveKit ส่งต่อใกล้ของจริง แต่จำนวน connection มากกว่า) · ผลบน MacBook ใช้ดูแนวโน้ม

### meeting-churn (`scripts/meeting-churn.sh`)

- **ทดสอบอะไร:** คนเข้า-ออกห้อง LiveKit ซ้ำ ๆ แล้ว goroutine ค้างไม่คืนเหมือนที่ prod เจอไหม
- **ทำไมต้องมี:** prod (v1.13.0, 2026-08-20) ค้าง ~15.5 goroutine ต่อการ join 1 ครั้ง คืนเฉพาะตอนห้องปิดสนิท — เป็นต้นเหตุ CPU ของ LiveKit ไม่ใช่การส่ง media
- **คำสั่ง:** `make meeting-churn`
- **ค่าเริ่มต้น:** ห้องเดียว มี 1 คนอยู่ค้างให้ห้องไม่ปิด · คนชุดเดิม 5 คนเข้า-ออก 30 รอบ รอบละ 10 วินาที · แล้วรอห้องว่าง 330 วินาที (LiveKit ปิดห้องว่างหลัง 300 วินาที)

| Option | ทำอะไร |
|---|---|
| `CYCLES=60` | จำนวนรอบเข้า-ออก |
| `PEOPLE=8` | คนต่อรอบ |
| `CYCLE_SECS=20` | อยู่ในห้องกี่วินาทีต่อรอบ |
| `IDLE=60` | รอห้องว่างกี่วินาทีตอนจบ |
| `PROFILE=camera` | `audio` (default) / `camera` |
| `ANCHOR=0` | ไม่มีคนอยู่ค้าง (ห้องปิดได้ระหว่างรอบ) |
| `SAME_PEOPLE=0` | ใช้คนใหม่ทุกรอบแทนคนชุดเดิม |

**ดูผล:** `reports/meeting-churn-<เวลา>/summary.md` — goroutine ค้างต่อ 1 join (เทียบ 15.5 ของ prod) และหลังห้องว่าง · ≈ 0 = ไม่เจอปัญหา · > 0 แล้วคืนหลังห้องว่าง = แบบเดียวกับ prod · ยังสูงหลังห้องว่าง = รั่วจริง

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
| `make summarize [RUN=reports/<รอบ>] [DRY=1]` | ให้ AI สรุปผลของรอบนั้น (ไม่ใส่ `RUN` = รอบล่าสุด) · `DRY=1` ดูข้อมูลที่จะส่งโดยไม่ส่งจริง |
| `make meeting-media` / `make meeting-churn` | ทดสอบภาพ/เสียงของ meeting (ดูส่วนที่ 3) |
| `make check` | เช็ก seeder, ตัวสรุป AI และทุก scenario |

ไม่ใส่ `YES=1` = ไม่เขียนอะไรลง DB (dry run)

User ทดสอบ: `lt_NNNN@loadtest.invalid` / `LoadTest#2026` — เปิดดูใน browser ได้ แต่อย่าใช้ user ที่ bot กำลังใช้อยู่ (จะเตะกัน)

---

## 5. สรุปผลด้วย AI (`analysis.md`)

ให้ Claude อ่านผลของรอบหนึ่งแล้วเขียนสรุปภาษาไทยเป็น `reports/<รอบ>/analysis.md` 9 หัวข้อ: สรุป · ผลตามเกณฑ์ · **จุดที่เริ่มพัง / แนวโน้มตามเวลา** · ตัวเลขที่ควรดู · **error ที่เจอ** · เทียบกับรอบก่อน · สาเหตุที่เป็นไปได้ (ติดป้าย "จากข้อมูล" / "สันนิษฐาน" + วิธียืนยัน) · **ความน่าเชื่อถือของผล** · ทำอะไรต่อ

```bash
make run S=lt02-baseline-50 VUS=10 AI=1                       # สรุปอัตโนมัติหลังรันจบ
make summarize                                                # สรุปรอบล่าสุดใน reports/
make summarize RUN=reports/lt11-spotlight-audience-20260925-132244
make summarize RUN=reports/spotlight-media-20260925-134524    # ใช้กับผลภาพ/เสียงได้
make summarize DRY=1                                          # ดูข้อมูลที่จะส่งให้ AI (ไม่ส่งจริง ไม่เสียเงิน)
```

| ตั้งค่า (`.env`) | ทำอะไร |
|---|---|
| `ANTHROPIC_API_KEY` | key ของ Claude API (จำเป็น) |
| `LT_AI_MODEL` | model ที่ใช้ เช่น `claude-opus-5` (ไม่ใส่ = `claude-sonnet-5`) |
| `AI=1` | สรุปทุกรอบโดยไม่ต้องพิมพ์ `AI=1` |

- **ค่าใช้จ่ายต่อครั้งโดยประมาณ:** `claude-sonnet-5` ~1–2 บาท · `claude-opus-5` ~3–5 บาท (รอบยาว/หลาย step ข้อมูลเยอะขึ้น แพงขึ้นเล็กน้อย)
- **ส่งอะไรไปบ้าง:**
  - ค่าสรุปของรอบ (เกณฑ์คิดเป็น PASS/FAIL แล้ว)
  - **ตารางย่อจาก `samples.json.gz`** ที่ทำบนเครื่อง: ต่อ step, ต่อช่วงเวลา และ error แยกตาม endpoint/status/สาเหตุ (ไม่ส่งไฟล์ดิบ)
  - **option ที่ใช้รัน** (`run-options.txt` ที่ `make smoke` / `make run` บันทึกไว้ในโฟลเดอร์ของรอบ เช่น `MEETINGS=6 PEOPLE=3`)
  - คำอธิบาย scenario, ผลรอบก่อนของ scenario เดียวกัน, host ที่ยิง และบอกแค่ว่า DB อยู่ในเครื่องหรือระยะไกล
  - ไม่มี token / รหัสผ่าน
- **ข้อควรรู้:** AI สรุปจากตัวเลขที่ให้เท่านั้น ข้อ "สาเหตุที่เป็นไปได้" เป็นข้อสันนิษฐาน อ่านทวนก่อนส่งต่อ · ถ้าไม่มี key หรือสรุปล้ม ผลของเทสยังเหมือนเดิม แค่ไม่ได้ `analysis.md`

---

## 6. ดูผล

- **เทอร์มินัล:** ส่วน `THRESHOLDS` ตอนจบ — ✓ ผ่าน · ✗ ไม่ผ่าน
- **เช็กเร็ว:** `echo $?` หลังจบ — `0` ผ่านทุกเกณฑ์ · `99` มีเกณฑ์ไม่ผ่าน
- **ไฟล์ผล:** ทุกครั้งที่ `make smoke` / `make run` ได้โฟลเดอร์ของรอบนั้น `reports/<scenario>-<วันที่-เวลา>/`

  | ไฟล์ในโฟลเดอร์ | คืออะไร | เปิดยังไง |
  |---|---|---|
  | `summary.json` | ค่าสรุปตอนจบ (p95, rate, ผ่าน/ไม่ผ่าน) | editor / script |
  | `report.html` | dashboard ของ k6 แบบบันทึกไว้ — กราฟตามเวลาของทั้งรอบ | ดับเบิลคลิกเปิดใน browser · เทสสั้นกว่า ~30 วินาทีจะไม่ได้ไฟล์นี้ |
  | `analysis.md` | สรุปจาก AI (มีเมื่อใช้ `AI=1` หรือ `make summarize`) | editor / preview Markdown |
  | `run-options.txt` | option ที่ใช้รันรอบนั้น (ไม่มีค่าลับ) | editor |
  | `samples.json.gz` | ทุกค่าที่วัดได้พร้อมเวลา 1 บรรทัดต่อ 1 จุด (k6 `--out json`) — ไว้ทำกราฟเอง | `zcat < samples.json.gz \| head` · รอบใหญ่/ยาวไฟล์ใหญ่มาก `SAMPLES=0` ถ้าไม่ต้องการ |

  `make spotlight-media` ได้โฟลเดอร์ `reports/spotlight-media-<เวลา>/` มี `summary.md` (ตารางสรุป) + log ของแต่ละขั้น
- **หน้ารวมผลทุกรอบ:** `make dashboard` แล้วเปิด http://127.0.0.1:5666 (ส่วนที่ 7)
- **Progress bar ค้าง 0% จนจบ = ปกติ:** bot แต่ละตัวทำงานรอบเดียวยาว ๆ · ดูเวลาจากบรรทัด `running (…)` หรือใช้ `D=1` · ✓ หน้าชื่อ scenario ในแถบ = รันจบ ไม่ได้แปลว่าผ่านเกณฑ์

---

## 7. Dashboard รวมผล + แชทถาม AI (`make dashboard`)

```bash
make dashboard                  # เปิด http://127.0.0.1:5666 — Ctrl+C เพื่อปิด
make dashboard DASH_PORT=5700   # เปลี่ยน port (5665 เป็นของ k6 dashboard ตอนใช้ D=1)
```

- ปิดด้วย **Ctrl+C** เท่านั้น — **Ctrl+Z** แค่พัก process ไว้ มันจะจับ port 5666 ค้าง แล้วรอบหน้าขึ้น `port 5666 is taken` (แก้: `lsof -nP -iTCP:5666 -sTCP:LISTEN` แล้ว `kill <PID>` หรือพิมพ์ `fg` แล้ว Ctrl+C)

- **แต่ละ scenario ทดสอบอะไร (ภาษาไทย):** ทุกหน้าบอกคำถามที่ scenario ตอบ (เช่น lt07 = "9 โมงเช้าทุกคนเข้าพร้อมกันไหวไหม") · หน้า scenario บอกเพิ่มว่าทำอะไร / ทำไมต้องมี / ผ่านเมื่อไหร่ · หน้า run อยู่ในหัวข้อ "Scenario นี้ทดสอบอะไร" — ข้อความมาจาก spec §6.1 / §12.2 / §13.2 (เก็บใน `analyze/web/metrics.js` → `SCENARIOS_TH` ถ้าแก้ spec ให้แก้ที่นี่ด้วย)
- **หน้าตา:** เรียบ อ่านง่าย — แถบบน (ชื่อหน้า, เมนู "ไปที่ scenario…", รีโหลด, ถาม AI) + เนื้อหาคอลัมน์เดียว · ชื่อ scenario เป็นภาษาคน (เช่น Morning spike) มีรหัส lt07 กำกับ · ชี้ที่ชื่อ metric เพื่อดูคำอธิบาย/ชื่อจริง
- **ภาพรวม:** ตัวเลขสรุป 4 ตัว · กล่องแดง "ต้องดู" ถ้ามี scenario ที่รอบล่าสุดไม่ผ่าน (กดไปที่รอบนั้นได้) · รายการ scenario แยก Office / Spotlight / Meeting — จุดสี = ผลรอบล่าสุด (เขียว ผ่าน · แดง ไม่ผ่าน · ฟ้า media · วงกลมเปล่า ยังไม่รัน) ด้านขวาเป็น p95 ตัวหลัก + รันเมื่อไหร่
- **หน้า scenario:** กราฟ p95 ข้ามรอบ (เลือก metric ได้, เส้นประส้ม = เกณฑ์, สีจุด = ผลรอบนั้น, ชี้ดู option) + ตารางทุกรอบ — เทียบกันตรง ๆ ได้เฉพาะรอบที่ option เหมือนกัน
- **หน้า run** — คำตอบก่อน รายละเอียดพับไว้:
  1. **คำตัดสิน:** "ผ่านครบทุกเกณฑ์" หรือ "ไม่ผ่าน 2 จาก 4 เกณฑ์" + ข้อที่ไม่ผ่านพร้อมค่าจริงเทียบเกณฑ์
  2. **ตัวเลขหลัก 4 ตัว:** p95 ตัวหลัก, REST request (+ล้มเหลว), WS session (+error), check — ตัวที่มีปัญหาเป็นสีแดง
  3. **เกณฑ์:** ทุกข้อเป็นประโยค (เช่น "p95 ต้องน้อยกว่า 1.00s") + ค่าจริง + แถบเทียบเกณฑ์
  4. **ตลอดการรัน:** กราฟเล็กทีละค่า (bot, p95/p50 ของ latency แต่ละตัว, WS error และอัตราที่ไม่ถึง 100% เมื่อมี) — มาจาก `samples.json.gz` (รอบใหญ่โหลดช้าหน่อย, `SAMPLES=0` ไม่มีส่วนนี้)
  5. **พับไว้ (กดเปิด):** ราย step · ทุก metric (avg/min/med/p90/p95/max/n แยกหมวด) · Error (เปิดเองถ้ามี) · Check ราย endpoint (เปิดเองถ้ามีไม่ผ่าน) · บทวิเคราะห์จาก AI · Scenario นี้ทดสอบอะไร
- **ไม่ต้องสร้างใหม่หลังรัน:** อ่าน `reports/` สดทุกครั้งที่เปิด/รีโหลดหน้า — ไม่มีไฟล์ dashboard ให้เขียนทับ · ลบโฟลเดอร์รอบที่ไม่อยากเห็นออกจาก `reports/` แล้วรีโหลดก็หายไป
- **ถาม AI:** ปุ่ม "ถาม AI" มุมขวาล่าง (หรือ "ถาม AI เรื่องรันนี้" / "ให้ AI สรุป scenario นี้") — AI รู้ว่ากำลังดูหน้าไหน แล้วไปอ่านผลเองผ่าน tool อ่านอย่างเดียว 3 ตัว (รายการ scenario, รายการรอบ, ผลเต็มของรอบ) ตอบเป็นไทย
  - ใช้ `ANTHROPIC_API_KEY` และ model `LT_AI_MODEL` ตัวเดียวกับ `make summarize` · ทุกคำถามเสียเงิน (ประมาณคำถามละไม่กี่ cent ขึ้นกับจำนวนรอบที่ต้องอ่าน)
  - ส่งข้อมูลชุดเดียวกับ `analyze` (ตัวเลขที่ย่อแล้ว, timeline, error, `run-options.txt`, `analysis.md`, คำอธิบาย scenario) — ไม่ส่ง `samples.json.gz` ดิบ, `setup_data` ใน `summary.json` (มี token) หรือค่าใน `.env`
  - ประวัติแชทอยู่ในหน้าเว็บเท่านั้น — รีโหลดหน้าแล้วหาย ไม่ได้บันทึกที่ไหน
- **ความปลอดภัย:** เปิดแค่ `127.0.0.1` (เครื่องอื่นเข้าไม่ได้), ไม่เสิร์ฟ `summary.json` / `samples.json.gz`, ปฏิเสธ request ที่ Host ไม่ใช่ localhost และแชทรับเฉพาะ `application/json` (เว็บอื่นที่เปิดใน browser เดียวกันยิงแทนไม่ได้)
- โค้ด: `zyra-loadtest/analyze/serve.go` (server), `runs.go` (อ่าน reports/), `chat.go` (แชท), `web/` (หน้าเว็บ — `metrics.js` = ชื่อไทย/คำอธิบายของทุก metric, `run.js` = หน้า run ฝังใน binary — ไม่ต้อง build frontend) · หน้าตาอิง zyra-app (dark admin, สีเขียว `#58D68D`, icon lucide) + zyra-landing (หัวข้อ Poppins, ปุ่ม pill)
