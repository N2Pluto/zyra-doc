# Load Test — ZYRA Platform (app / api / ws / notifications / landing)

> **สถานะ:** Draft spec — **ยังไม่ approve** · 2026-09-24 · โครง `zyra-loadtest` + smoke (`GET /api/user/me`) ผ่านบน local แล้ว — ดู [progress.md](progress.md)
> **repo ที่เกี่ยว:** `zyra-loadtest` (`feat/smoke-structure`, ยังไม่ commit) · อ่านอย่างเดียว: `zyra-api`, `zyra-ws`, `zyra-app`, `zyra-notifications`, `zyra-landing`
> **ClickUp:** — (ยังไม่มี task)
> **ข้อมูลใน §3 มาจากการอ่านโค้ด 2026-09-24** ตาม branch ปัจจุบันของแต่ละ repo (api `feat/admin-roadmap-api`, ws/notifications `feat/spotlight`, app `feat/tree-sway`) — ไม่ใช่ `develop` ทุกตัว ก่อนเริ่มเขียน script ให้เทียบกับ `develop` อีกรอบ
> **ต้องตอบ [§10 Open Questions](#10-open-questions) ข้อ Q1–Q3 ก่อนเริ่ม implement**

---

## 0. Sources

| แหล่ง | ใช้เรื่อง |
|---|---|
| [Real-time-Engine/capacity-scaling.md §1, §14](../Real-time-Engine/capacity-scaling.md) | target capacity + Load Test Plan เดิม (pass criteria ต้นทาง) |
| [Real-time-Engine/tick-overhaul-plan.md](../Real-time-Engine/tick-overhaul-plan.md) | Phase B/C gate ด้วยผล load test 1000 คน/map · DoD tick |
| [Real-time-Engine/test-plan.md](../Real-time-Engine/test-plan.md) | 50 concurrent/workspace p95 < 500ms |
| [VirtualOffice/next-step-scaling.md](../VirtualOffice/next-step-scaling.md) | A-01..A-03 (load test 50–100 คน) + hotspot ws |
| [VO-Movement-V2/staging-soak-checklist.md](../VO-Movement-V2/staging-soak-checklist.md) | soak ก่อน default-on |
| [ops/node-saturation-2026-09-18.md](../../ops/node-saturation-2026-09-18.md) | node target + PromQL ที่ใช้ได้ทันที |
| [ops/livekit-sfu-capacity-2026-08-20.md](../../ops/livekit-sfu-capacity-2026-08-20.md) | SFU cost / join churn |
| [ops/prod-app-crashloop-2026-09-10.md](../../ops/prod-app-crashloop-2026-09-10.md) · [ops/node-cpu-burst-argocd-2026-09-22.md](../../ops/node-cpu-burst-argocd-2026-09-22.md) · [ops/grafana-optimize-2026-08-20.md](../../ops/grafana-optimize-2026-08-20.md) | incident ที่ผ่านมา + วิธีเข้า cluster/Grafana |
| [Real-time-Engine/technical-design/00-architecture-overview.md](../Real-time-Engine/technical-design/00-architecture-overview.md) | ภาพรวม service |

---

## 1. What / Why

**What:** วัด capacity จริงของ ZYRA ต่อ 1 workspace (map) และทั้งระบบ ด้วย synthetic users ที่ทำตัวเหมือน client จริง (REST + WebSocket) แล้วหาว่า service/resource ไหนพังก่อน

**Why:**
- ตัวเลข capacity ทุกตัวในเอกสารเดิมเป็น **ประมาณการ** ("ต้องยืนยันด้วย load test จริง" — capacity-scaling, tick-overhaul-plan)
- tick overhaul **Phase B/C ถูก gate ด้วยผล load test** ที่ 1000 คน/map
- VO-Movement-V2 ต้อง soak ก่อน default-on
- prod saturate ที่ ~40–50 CCU (ops 09-18) — ต้องรู้ baseline ก่อนตัดสินใจ resize node / แยก SFU node

**Expected outcome:**
1. repo `zyra-loadtest` มี seeder + script ที่รันซ้ำได้
2. ผล baseline ต่อ scenario (§6) พร้อมตัวเลข p95/p99, error rate, CPU/mem ต่อ service
3. รายการ bottleneck ที่พบ (ส่งต่อเป็น issue แยก — ไม่แก้ใน scope นี้)

---

## 2. Scope

### In scope
- **REST ผ่าน zyra-app (Next.js)** — เพราะ client จริงยิง `/api/*` ผ่าน Next rewrite ไม่ได้ยิง api ตรง
- **REST ตรง zyra-api** — เพื่อแยก cost ของ Next ออกจาก api
- **WebSocket zyra-ws** — connect, movement v2, ping, chat/typing, room enter/leave
- **zyra-api `/api/internal/*`** ที่ ws เรียกกลับ (โดนทางอ้อมจาก WS connect)
- **Seeder** สร้าง/ลบ user + workspace + membership สำหรับทดสอบ
- **Report** ผลต่อรอบ

### Out of scope (รอบนี้)
- **แก้ bottleneck** ที่เจอ — บันทึกเป็น issue แยกเท่านั้น
- **Media plane (LiveKit SFU)** — ต้องใช้ `livekit-load-tester`/`lk load-test` แยก และ SFU เคยกิน 2.1/4 core ที่ 47 คน → แยกเป็น phase ถัดไป (ดู Q5)
- **Email flow** (register/OTP, forgot/reset password, invite, lockout, digest) — ส่ง Gmail จริง (ดู §4)
- **zyra-landing** — static บน Cloudflare Pages ไม่คุ้มยิง; endpoint ที่ landing เรียก (`GET /api/public/roadmap`) รวมไว้เป็น optional ใน SC-LT-07
- **Client-side FPS / render** (capacity-scaling §14 "Client อ่อน") — เป็น browser test ไม่ใช่ server load
- **Failover / multi-node sharding** — ws ยังไม่มี sharding (§3.3)
- **Admin endpoints** `/api/admin/*`

---

## 3. Current Implementation (baseline จากโค้ด)

> ส่วนนี้คือ **ข้อเท็จจริงจากโค้ด** ไม่ใช่ข้อเสนอ

### 3.1 Infrastructure (จาก ops docs)

- **ทุก env อยู่ node เดียว:** GCE `zyra-k3s` e2-standard-4 (4 vCPU / 15.6 GiB) รัน prod, uat, dev, sfu, monitoring, argocd
- **CPU requests ถูกจอง 91%** (3665m/4000m) หลัง PR #28 + ArgoCD limits 09-22
- **Postgres = AlloyDB (ZONAL)**, **Redis = Memorystore BASIC 7.2** — private IP, shared ทุก env?  → ดู Q1
- **prod saturate ที่ ~40–60 CCU** · Next.js ตายก่อน (SSR CPU-bound, probe timeout) · `/api/img` สงสัยว่ากิน CPU
- **Traefik p95 รวม WS** → ใช้ดู latency ไม่ได้ ต้องแยกตาม service

### 3.2 zyra-app (Next.js 16)

- REST ทุก call ผ่าน rewrite `/api/:path*` → `BACKEND_URL` (`zyra-app/next.config.ts:130-148`)
- `proxy.ts` ทุก page request: เช็ค maintenance (cache 5s) + `GET /api/authen/session-state` (cache ต่อ token 60s, in-memory ต่อ pod)
- `app/api/img/route.ts` ดึงรูป S3/R2 แล้วส่งต่อ — map texture โหลดผ่านตัวนี้
- WS ต่อ **ตรง** ไป `NEXT_PUBLIC_SOCKET_URL` ไม่ผ่าน Next (`zyra-app/lib/api/workspace-ws.ts`)
- Polling ขณะเปิด tab ที่ login แล้ว (verify แล้ว):

| Call | ความถี่ | ที่มา |
|---|---|---|
| `GET /api/authen/session-state` | 30s | `components/auth-guard.tsx:41` |
| `/api/maintenance` | 10s | `components/auth-guard.tsx:42` |
| `POST /api/user/presence` | 30s + ตอน tab visible | `components/app-presence.tsx:21` |
| `POST /api/user/workspaces/:id/presence` | 30s (ใน VO) | `views/user/virtual-office/hero-virtual-office.tsx:~3396` |
| WS `ping {client_time_ms}` | 300ms, 1.2s หลัง connect แล้วทุก 3s | `hero-virtual-office.tsx:~3280`, `workspace-ws.ts:658` |
| WS `input {dx,dy,run,sitting}` | ตอนเปลี่ยนปุ่ม + keepalive ~150ms ขณะกดค้าง | `zyra-engine/pixi-game/scene.ts:~1203` |
| WS `goto {tile_x,tile_y,path}` | 1 ครั้ง/คลิก | `hero-virtual-office.tsx:~5468` |

### 3.3 zyra-ws (Go, gorilla/websocket)

- Connect: `GET /ws?workspace_id=&token=<jwt>&client_session_id=&tile_x=&tile_y=&floor_id=...` (`internal/handler/handler.go:130`)
- **ทุก connect เรียก zyra-api แบบ sync** `GET /api/internal/workspaces/{ws}/members/{user}` timeout 5s ไม่มี cache, fail-closed → 503 (`internal/authz/membership.go:30`)
- **movement v2 hardcode เปิด** (`internal/hub/hub.go:92` `movementV2: true`) → client ต้องส่ง `input`/`goto` ไม่ใช่ `move`
- **ไม่มี capacity check ใน ws** — `capacity` param ถูกทิ้ง (`hub.go:195`); seat limit บังคับที่ zyra-api ตอนเพิ่ม member (ดู §9 G-01)
- Tick move 20ms (50Hz) → binary `moved_bin` ไปยัง AOI 3×3 cell (cell = 16×16 tile) · snapshot ทุก 3s
- **1 workspace = 1 pod** — nginx `hash $arg_workspace_id consistent` (`deploy/nginx-ws.conf`), state อยู่ใน memory, ไม่มี cross-instance fanout
- Buffer ต่อ conn: `send`/`sendBin` อย่างละ 256 — `send` เต็ม = **evict client**
- ไม่มี message rate limit, ไม่มี max connection · reaper ตัด conn ที่เงียบระดับ app > 3 นาที
- `user_id` ซ้ำ → `session_replaced` (เว้นแต่ `client_session_id` ตรงกัน)
- ไม่มี Prometheus — มีแค่ log `vo tick metrics` ทุก 10s/room + `/healthz` (`total_online`, per-room)
- Flag: `VO_TICK_REALTIME_DT`, `VO_TICK_ACTIVE_SET` default off (`internal/config/config.go:91-92`)

### 3.4 zyra-api (Go, Gin, pgx)

- Login `POST /api/authen/login` **form-data** (`username`, `password`, `rememberMe`) · access JWT HS256 (`tokenKey`) อายุ 15m (`ACCESS_TOKEN_EXPIRE`) · refresh = httpOnly cookie
- **Lockout ผิด 3 ครั้ง** (`internal/config/config.go:226`)
- reCAPTCHA: app ส่ง `captchaToken` แต่ api ไม่ได้ verify (ไม่พบโค้ดที่ใช้ `RECAPTCHA_SECRET`)
- ไม่มี dev-login / test-token endpoint · ไม่มี bulk seed
- **DB pool ไม่ tune** `pgxpool.New(dsn)` (`internal/database/postgres.go:1118`) → default `max(4, NumCPU)` เว้นแต่ใส่ `pool_max_conns` ใน DSN
- UserGuard query `account_status` ทุก request (`internal/middleware/account_status_guard.go:20`)
- ไม่มี Write/Idle timeout, ไม่มี request deadline, ไม่มี HTTP rate limiter
- Chat rate limit 30 msg/นาที/user ด้วย `COUNT(*)` บน `tb_message` (`internal/service/chat_service.go:941`)
- Workspace presence อยู่ใน memory ต่อ process (`internal/service/workspace_presence_service.go`)
- `ENVIRONMENT_ENABLED=true` → poll weather provider ภายนอก (มีค่าใช้จ่าย)

### 3.5 zyra-notifications

- `POST /v1/email` → **Gmail SMTP sync ไม่มี sandbox** · ถ้า `EMAIL_AUTHEN_USER/PASS` ว่าง → log "skipping" แล้วตอบสำเร็จ (`mailer.go` `Send` → `!m.IsReady()`)
- zyra-api เรียกด้วย timeout 30s + retry 3 ครั้ง

---

## 4. Safety Constraints (บังคับ)

| # | กฎ | เหตุผล |
|---|---|---|
| S-01 | **ห้ามยิง prod** | ลูกค้าจริง |
| S-02 | **ห้ามยิง dev/uat บน node ปัจจุบันเกิน smoke (≤5 VU)** จนกว่าจะตอบ Q1 | อยู่ node เดียวกับ prod → prod ช้า/ล่มตาม (incident 09-10, 09-22) |
| S-03 | env ที่ยิงต้อง `EMAIL_AUTHEN_USER`/`EMAIL_AUTHEN_PASS` ว่าง และ script ห้ามแตะ email flow | Gmail quota/lock กระทบอีเมล prod |
| S-04 | env ที่ยิงต้อง `ENVIRONMENT_ENABLED=false` | provider เสียเงิน |
| S-05 | test data ทุกแถวใช้ prefix `lt_` (username/email/workspace name) และมีคำสั่ง clean | ลบทิ้งได้ครบ ไม่ปนข้อมูลจริง |
| S-06 | email ของ test user ใช้ domain ที่ส่งไม่ได้ (เช่น `@loadtest.invalid`) | กัน digest/อีเมลหลุดถ้า S-03 พลาด |
| S-07 | script ห้ามส่ง password ผิด | lockout 3 ครั้ง |
| S-08 | ห้าม deploy service ใดๆ ระหว่างรอบ test | `server_drain` → reconnect storm ทำให้ผลเพี้ยน |
| S-09 | secret (`tokenKey`, DB URL) อ่านจาก env เท่านั้น ห้าม commit | rule 01 DoD |

---

## 5. Load Model (user หนึ่งคน)

> ข้อเท็จจริงจาก §3.2 — script ต้องทำตามนี้ ไม่ใช่ตามที่ "คิดว่าน่าจะ"

### 5.1 Journey

1. **Login** — `POST /api/authen/login` (หรือใช้ token ที่ seed ไว้ ดู §7)
2. **Workspace list** — page `/workspace` (SSR) + `GET /api/user/workspaces`
3. **Enter office** (`/workspace/[id]/play`)
   - `GET /api/user/workspaces/:id` ∥ `GET /api/user/workspaces/:id/maps`
   - `GET /api/user/maps/:mapId/zones?limit=200` ∥ `GET /api/user/maps/:mapId/objects?limit=500`
   - `GET /api/user/me`, `/api/user/chat/conversations`, `/api/user/chat/unread`, `/api/user/avatars`, workspace members, `/api/objects/all`
   - `/api/img?url=…` หลายไฟล์ (map texture)
   - `POST /api/user/workspaces/:id/presence`
   - WS connect → รับ `welcome`
4. **Idle/อยู่ในออฟฟิศ** — polling ตาม §3.2 (ping 3s, presence 30s×2, session-state 30s, maintenance 10s)
5. **Move** — `input` keepalive ~150ms ขณะเดิน หรือ `goto` ต่อคลิก · รับ `moved_bin` จากเพื่อนบ้าน
6. **Chat** — `GET/POST /api/user/chat/conversations/:id/messages`, `POST …/read`, WS typing start/stop
7. **Leave** — ปิด WS

### 5.2 Behaviour mix (ข้อเสนอ — ปรับได้)

| กลุ่ม | สัดส่วน | ทำอะไร |
|---|---|---|
| Idle | 60% | อยู่ในออฟฟิศ polling อย่างเดียว |
| Walker | 30% | เดิน WASD เป็นช่วง (5–15s เดิน / 10–30s หยุด) + `goto` บ้าง |
| Chatter | 10% | ส่งข้อความ ≤ 1 msg/10s/user (ต่ำกว่า limit 30/นาที) + typing |

### 5.3 ข้อบังคับของ bot (จาก §3.3)

- 1 bot = 1 user จริงที่เป็น member ของ workspace (ห้ามใช้ user ซ้ำ)
- ต้อง **อ่าน** ทั้ง text และ binary frame ตลอด (ไม่งั้น buffer เต็ม → evict)
- ต้องส่ง `ping` ระดับ app (ไม่งั้นโดน reaper 3 นาที)
- กระจายจุด spawn ตาม scenario (กระจาย vs กระจุก AOI cell เดียว)

---

## 6. Scenarios & Acceptance Criteria

> **Pass criteria ที่มีที่มา** อ้าง source ไว้ · ตัวที่ไม่มี source = **ข้อเสนอ** ต้องยืนยันใน Q4

| ID | Scenario | Target/load | Pass criteria | ที่มาของเกณฑ์ |
|---|---|---|---|---|
| **SC-LT-01** | Smoke — ทุก step ใน §5.1 ทำงาน | 1–5 VU, 2 นาที | 0 error, ทุก check ผ่าน | ข้อเสนอ |
| **SC-LT-02** | Baseline 1 workspace — ramp ถึง 50 คน | 50 CCU, mix §5.2, 15 นาที | WS/REST p95 < 500ms, 0% 5xx | RTE test-plan:61 |
| **SC-LT-03** | Scale 1 workspace 100 คน | 100 CCU, 20 นาที | เห็นกันครบ, ไม่มี phantom หลัง reconnect, p95 < 500ms | VO next-step-scaling A-03 |
| **SC-LT-04** | Step ramp 1 workspace หา breaking point | 50 → 100 → 250 → 500 → 1000 (step ละ 5 นาที) | บันทึกจุดที่ p95 > 500ms หรือ error > 1% หรือ evict/`session_replaced` เกิด · ที่ 1000: tick p95 < 20ms, sim ≥ ~45Hz, force_sync rate แบน | capacity-scaling §14 · tick-overhaul DoD |
| **SC-LT-05** | Worst-case fanout — ทุก bot อยู่ AOI cell เดียว | 20 → 50 → 100 ใน cell เดียว, walker 100% | บันทึก fanout/tick time — ไม่มี pass/fail (หา limit) | tick-overhaul-plan:139 |
| **SC-LT-06** | Many workspaces | N workspace × 20–25 คน (N ตาม env) | ไม่มี pod saturate, p95 < 500ms | capacity-scaling §14 (ย่อส่วน) |
| **SC-LT-07** | REST-only enter-office spike ("9 โมงเช้า") | ทุก VU login + enter office ภายใน 60s | p95 enter-office < 1s, error < 1% · (optional) `GET /api/public/roadmap` | ข้อเสนอ |
| **SC-LT-08** | Soak | 50–100 CCU 1–2 ชม. | memory/goroutine ไม่โตต่อเนื่อง, ไม่มี restart | VO-Movement-V2 soak checklist |
| **SC-LT-09** | Connect storm / reconnect | ตัดทุก conn พร้อมกันแล้วต่อใหม่ | reconnect ครบภายใน grace, `/api/internal/.../members` ไม่ 503 | capacity-scaling §14 Failover (ย่อส่วน) |

**Node-level (ทุก scenario ที่ยิงบน k3s):** app p95 < 150ms, p99 < 1200ms, load/core < 2, 0% 5xx — ที่มา ops/node-saturation-2026-09-18

**SC-LT-04/05 รันซ้ำ 2 รอบ:** flag `VO_TICK_REALTIME_DT`/`VO_TICK_ACTIVE_SET` = off และ on (ตาม tick-overhaul-plan)

### 6.1 แต่ละ scenario ตอบคำถามอะไร

> ไฟล์ใน `zyra-loadtest/k6/scenarios/` ชื่อตรงกับ ID (`lt01-smoke.js` = SC-LT-01) · lt01 = เช็คว่า script ถูก ส่วน lt02–lt09 = วัด capacity จริง

| ไฟล์ | คำถาม | ทำอะไร | ทำไมต้องมี |
|---|---|---|---|
| `lt01-smoke` | script ทำงานถูกไหม | 1–5 VU, 30s | ยืนยัน URL/token/user/script ก่อนยิงหนัก — script พัง = ตัวเลขใช้ไม่ได้ |
| `lt02-baseline-50` | รับ 50 คนสบายไหม | 50 คน 1 workspace 15 นาที mix idle/walker/chatter | ตัวเลขตั้งต้นไว้เทียบทุกรอบ · prod อิ่มที่ ~40–60 คน |
| `lt03-scale-100` | 100 คนไหวไหม | 100 คน 20 นาที + เช็คเห็นกันครบ / ไม่มี phantom หลัง reconnect | ปิด A-03 ใน VirtualOffice/next-step-scaling |
| `lt04-ramp-1000` | พังที่กี่คน | เพิ่มทีละขั้น 50→100→250→500→1000 ขั้นละ 5 นาที · รัน flag off/on | ผลนี้ใช้ตัดสินว่าต้องทำ tick overhaul Phase B/C ไหม |
| `lt05-aoi-cluster` | ยืนรวมจุดเดียวไหวไหม | ทุก bot อยู่ AOI cell เดียวแล้วเดินพร้อมกัน 20→50→100 | fanout โต ~N² — เกิดจริงตอนรวมพล/event · ไม่มี pass/fail ใช้หาเพดาน |
| `lt06-many-workspaces` | หลายบริษัทพร้อมกันไหวไหม | เช่น 40 workspace × 25 คน | ws ส่ง 1 workspace ไป pod เดียว → ดูว่ามี pod ไหนรับหนักผิดปกติ |
| `lt07-morning-spike` | 9 โมงทุกคนเข้าพร้อมกันไหวไหม | ทุกคน login + enter office ภายใน 60s (REST อย่างเดียว) | วัดแรงกระแทกตอนเริ่ม — login, โหลด map, `/api/img` |
| `lt08-soak` | เปิดนานๆ แล้วแย่ลงไหม | 50–100 คน 1–2 ชม. | หา memory/goroutine leak ที่รอบสั้นไม่เห็น · soak ก่อน VO-Movement-V2 default-on |
| `lt09-reconnect-storm` | หลุดพร้อมกันแล้วกลับมาได้ไหม | ตัดทุก connection พร้อมกันแล้วต่อใหม่ทันที | เกิดตอน deploy (`server_drain`) · ทุก connect ws เรียก api เช็ค membership แบบ sync ไม่มี cache |

**ลำดับรันที่แนะนำ:** lt01 → lt02 → lt03 → lt07 → lt04 → lt05 → lt06 → lt09 → lt08 (เบาไปหนัก · soak ไว้ท้ายเพราะนานสุด) · ระหว่าง scenario พัก 1–2 นาทีให้ระบบกลับสู่ปกติ

**เงื่อนไข:** lt02 ขึ้นไปต้องมี user ตามจำนวน VU จาก `make seed` (1 bot = 1 user — §5.3)

---

## 7. Test Data & Auth (ข้อเสนอ)

- **Seeder** (Go CLI ใน `zyra-loadtest/seeder`) insert ตรง DB:
  - `tb_user` (`is_verifyed='Y'`) + `tb_authen` (password hash รูปแบบเดียวกับ `migrations/seed_admin_user.sql`)
  - workspace + map (clone map จริง 1 แบบให้ payload objects/zones สมจริง) + membership
  - ทุกแถว prefix `lt_` · `clean` ลบตาม prefix
- **Token 2 แบบ:**
  - (A) mint JWT เองด้วย `tokenKey` ของ env เป้าหมาย `exp` ยาว — ใช้กับ scenario ส่วนใหญ่
  - (B) login จริงผ่าน form — ใช้ใน SC-LT-07 เท่านั้น
- เพราะ seed ตรง DB จึงข้าม seat limit ของ api ได้ (ดู G-01) — ต้องแน่ใจว่า membership ที่ insert ครบ field ที่ `/api/internal/.../members` ใช้
- **Implemented 2026-09-24** (`zyra-loadtest/seeder`):
  - user = `lt_NNNN@loadtest.invalid`, `MEMBER`, verified, `onboarding_status=completed` · workspace = `lt_ws_NN` clone จาก template (owner NULL + published main map) ด้วย SQL เดียวกับ `CloneWorkspaceFromTemplate` · user แรกของแต่ละ workspace = owner
  - **ต่างจาก api:** ไม่สร้าง `#general` channel (api สร้างแบบ best-effort หลัง clone) · `tb_map_version.map_json` ใช้ `published_objects_json` ของ template แทน snapshot ที่ api สร้างเอง
  - clean: ลบตารางที่ block (FK `NO ACTION`: `tb_message.sender_id`, `tb_map_version.saved_by_id`, `tb_conversation.created_by`, …) และตารางไม่มี FK (`user_activities`, `tb_private_zone_access_log`) ก่อน → `tb_workspace` → `tb_user` (ที่เหลือ cascade) · transaction เดียว · Redis `vo:*<ws id>*`

---

## 8. Observability

| ต้องดู | จาก |
|---|---|
| p95/p99 ต่อ endpoint, error rate, WS connect time, message RTT (`ping`/`pong`) | ฝั่ง load tool |
| CPU/mem ต่อ pod, node load, CPU pressure | Prometheus (PromQL ใน ops/node-saturation-2026-09-18) |
| DB: `pg_stat_activity` (pool เต็ม?), `pg_stat_statements` top query | AlloyDB |
| Redis: `INFO` ops/sec, memory | Memorystore |
| ws: log `vo tick metrics` (ทุก 10s), `/healthz` `total_online` (poll ≤ 1 ครั้ง/10s) | Loki / HTTP |
| restart/OOM | `kubectl get pods`, events |

---

## 9. Gaps & Conflicts

| ID | เรื่อง | ต้นทาง | ของจริง | ผลต่อ load test |
|---|---|---|---|---|
| G-01 | Capacity gate | VO/next-step-scaling A-01: "ถ้าไม่ตั้ง `tb_workspace.capacity` ≥100 คนที่ 51+ โดน `capacity_reached`" | ws ทิ้ง param `capacity` แล้ว (`zyra-ws/internal/hub/hub.go:195`) — seat limit บังคับที่ api ตอนเพิ่ม member | seed ตรง DB ไม่ติด limit · **เอกสาร A-01 น่าจะล้าสมัย** — ต้องแก้ที่ VirtualOffice แยก (ไม่อยู่ใน scope นี้) |
| G-02 | ที่ยิง test | tick-overhaul/next-step: "staging load test" | ไม่มี staging แยก — uat/dev อยู่ node เดียวกับ prod | ดู Q1 |
| G-03 | Movement protocol | บางเอกสาร/ตัวอย่างใช้ `move`/`heartbeat` | ws hardcode v2 → client จริงส่ง `input`/`goto`/`ping` | script ต้องใช้ v2 |
| G-04 | Observability ws | — | ไม่มี Prometheus endpoint | ใช้ log + `/healthz` · (เพิ่ม metrics = งานแยก) |
| G-05 | Docker stack | guides/docker-stack.md (Cloud Run + SFU VM) · `zyra-app/docker-compose.yml` | k3s node เดียว · compose ของ app ใช้ env ที่ไม่มีโค้ดอ่าน | ห้ามใช้ compose app เดิมสร้าง env ทดสอบ |

---

## 10. Open Questions

| # | คำถาม | Block อะไร |
|---|---|---|
| **Q1** | **ยิงที่ไหน?** (ก) local ทั้ง stack บนเครื่อง (ข) VM/node ชั่วคราวแยก (ค) dev บน k3s นอกเวลางาน (เสี่ยงกระทบ prod) · **ตอบบางส่วน 2026-09-24:** DB `35.247.177.198` ที่ api local ใช้ = **dev** (ผู้ใช้ยืนยันกับทีม) · ยังไม่ได้ตัดสินว่าจะยิงแบบไหน | ทุก scenario เกิน smoke |
| **Q2** | **Tool** — เสนอ k6 (REST + WS ในสคริปต์เดียว, JS, threshold, ส่งออก Prometheus) ok ไหม | โครง `zyra-loadtest` |
| ~~Q3~~ | ~~seed ตรง DB (§7) ยอมรับไหม~~ · **ตอบแล้ว 2026-09-24:** seed ลง dev DB ได้ **โดยต้อง clean ได้หมด** → `make seed` / `make clean` (verify แล้ว ดู progress) | — |
| Q4 | pass criteria ที่เป็นข้อเสนอ (SC-LT-01, 07) และ target CCU จริงที่ธุรกิจต้องการรอบนี้ (50? 100? 1000?) | SC-LT-04 จุดหยุด |
| Q5 | media plane (LiveKit) จะทำใน spec นี้ phase 2 หรือแยก feature | scope |
| Q6 | ต้องมี report format/ที่เก็บผลแบบไหน (md ใน `zyra-doc/plan/LoadTest/results/`?) | report |
| Q7 | ยิงผ่าน Next (realistic) + ตรง api (isolate) ทั้งคู่ หรือเลือกอย่างเดียว | SC-LT-02..07 |

---

## 11. Readiness

- [x] อ่านโค้ด 5 repo + ops docs → baseline §3
- [x] ระบุ safety constraints §4
- [x] ร่าง scenario + criteria พร้อม source §6
- [x] ตอบ Q3 (seed ลง dev ได้ ต้อง clean ได้) · seeder `seed`/`clean` verify บน dev แล้ว
- [ ] ตอบ Q1 (ยิงแบบไหน) — รู้แล้วว่า DB = dev
- [ ] ตอบ Q4–Q7
- [ ] approve spec
- [x] `progress.md`
- [x] โครง `zyra-loadtest` + SC-LT-01 smoke (`GET /api/user/me`) ผ่าน
- [ ] สร้าง `task-breakdown.md`
