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
| LiveKit | 7880 | เฉพาะ `make spotlight-media` | `make livekit-up` |

**รูปแบบคำสั่ง**

```bash
make smoke [option...]                 # lt01
make run S=<ชื่อไฟล์> [option...]        # lt02–lt12
make spotlight-media [option...]       # ภาพ/เสียง (LiveKit)
make summarize [RUN=...]               # ให้ AI สรุปผลของรอบที่รันไปแล้ว
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
| `make check` | เช็ก seeder, ตัวสรุป AI และทุก scenario |

ไม่ใส่ `YES=1` = ไม่เขียนอะไรลง DB (dry run)

User ทดสอบ: `lt_NNNN@loadtest.invalid` / `LoadTest#2026` — เปิดดูใน browser ได้ แต่อย่าใช้ user ที่ bot กำลังใช้อยู่ (จะเตะกัน)

---

## 5. สรุปผลด้วย AI (`analysis.md`)

ให้ Claude อ่านผลของรอบหนึ่งแล้วเขียนสรุปภาษาไทยเป็น `reports/<รอบ>/analysis.md` — สรุปผ่าน/ไม่ผ่าน, ตารางเกณฑ์ทุกข้อ, ตัวเลขที่ควรดู, เทียบกับรอบก่อนของ scenario เดียวกัน, สาเหตุที่เป็นไปได้, สิ่งที่ควรทำต่อ

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
| `LT_AI_MODEL` | model ที่ใช้ เช่น `claude-sonnet-5` (ไม่ใส่ = `claude-opus-5`) |
| `AI=1` | สรุปทุกรอบโดยไม่ต้องพิมพ์ `AI=1` |

- **ค่าใช้จ่ายต่อครั้งโดยประมาณ:** `claude-sonnet-5` ~1 บาท · `claude-opus-5` ~3 บาท
- **ส่งอะไรไปบ้าง:** ค่าสรุปของรอบ (ไม่ส่ง `samples.json.gz` ไม่มี token/รหัสผ่าน), คำอธิบาย scenario, ผลรอบก่อนของ scenario เดียวกัน, host ที่ยิง และบอกแค่ว่า DB อยู่ในเครื่องหรือระยะไกล
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
  | `samples.json.gz` | ทุกค่าที่วัดได้พร้อมเวลา 1 บรรทัดต่อ 1 จุด (k6 `--out json`) — ไว้ทำกราฟเอง | `zcat < samples.json.gz \| head` · รอบใหญ่/ยาวไฟล์ใหญ่มาก `SAMPLES=0` ถ้าไม่ต้องการ |

  `make spotlight-media` ได้โฟลเดอร์ `reports/spotlight-media-<เวลา>/` มี `summary.md` (ตารางสรุป) + log ของแต่ละขั้น
- **Progress bar ค้าง 0% จนจบ = ปกติ:** bot แต่ละตัวทำงานรอบเดียวยาว ๆ · ดูเวลาจากบรรทัด `running (…)` หรือใช้ `D=1` · ✓ หน้าชื่อ scenario ในแถบ = รันจบ ไม่ได้แปลว่าผ่านเกณฑ์
