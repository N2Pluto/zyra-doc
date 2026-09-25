# Load Test — Progress / Handoff

> **สถานะรวม:** spec draft · seeder + WS + office journey + form login + lt01–lt09 + Spotlight lt10–lt12 / media ใช้ได้ · verify แบบย่อ (≤41 VU) บน local→dev ครบทุกตัวยกเว้น lt06 (ต้อง seed หลาย workspace) · ยังไม่ได้รันขนาดเต็ม
> **อัปเดตล่าสุด:** 2026-09-25 · **คนล่าสุด:** rif (ร่วมกับ Claude Code)

## 2026-09-25 (รอบ 3) · rif (ร่วมกับ Claude Code) — Spotlight load test (spec §12)

- **ผู้ใช้สั่ง:** load test Spotlight ทุกขั้น หาว่ารับได้กี่คน · ทั้ง ws/api + LiveKit · LiveKit local ก่อน · seeder สร้าง zone · LiveKit อยู่ใน `docker-compose.yaml` ที่ root
- **ทำอะไร** (`zyra-loadtest@feat/smoke-structure`, ยังไม่ commit · workspace root `docker-compose.yaml`):
  - seeder `spotlight` (seed เรียกเองด้วย): เพิ่ม `lt_spotlight` 2×2 tile ลง main map ของ `lt_ws_*` ที่ owner เป็น lt user (idempotent) + เขียน `vo:zones:<ws>` ใหม่ทั้ง workspace รูปแบบเดียวกับ api `publishWorkspaceZones` · `lt_ws_01` ได้ zone ที่ tile 41,24 · ถ้าเพิ่ม zone ไม่ได้ seed แค่เตือน (ไม่ทิ้ง tokens)
  - `k6/lib/spotlight.js` + `lt10`/`lt11`/`lt12`: presenter = scenario แยก 1 VU (k6 ไม่รับประกันว่า VU id ไหนอยู่ scenario ไหน) · ไลฟ์ตามตารางเวลาเดียวกันทุก VU → วัด `ได้รับ − เวลานัด` · metric `spotlight_{start,state,bell,meeting,end,resume}_ok` + `_ms` + media-token · คนในห้องประชุมทุกคนกด meetingJoin (server idempotent) · วัด latency เฉพาะรอบที่คนดูอยู่ก่อนเริ่มไลฟ์ · `LT_DEBUG=1` log event
  - `lib/api/media.js` (mint token เท่านั้น k6 ไม่ต่อ LiveKit) · `visit` ส่ง `onMessage` ต่อได้
  - `scripts/spotlight-media.sh` + `make spotlight-media` / `livekit-up` / `livekit-down` (SC-LT-13): ไล่คนดู 10→200 ขั้นละ 60s หยุดเมื่อ loss > 2% / มี error · เก็บ CPU/mem ของ container · กัน URL ไม่ใช่ local (`LT_ALLOW_REMOTE_SFU`, `LT_ALLOW_SHARED_NODE` สำหรับ `*.zyra.center`) · LiveKit local รัน `lk` ใน network ของ container (`livekit/livekit-cli`)
  - `.env` เพิ่ม `LIVEKIT_*` · สร้าง `.env.example` (เดิมไม่มีในไฟล์จริง ทั้งที่ progress รอบ 09-24 เขียนว่ามี)
- **บั๊กของ script ที่เจอและแก้ระหว่าง verify:** จับคู่ event กับรอบผิด (ช่วงรอบแรกกว้างเกิน) · รอบที่ presenter หลุดแล้วกลับมาไม่ส่ง stop → ไลฟ์ค้างข้ามรอบ · late joiner ได้ snapshot/กระดิ่งแล้วถูกนับเป็น latency (bell p95 81s ปลอม) · CPU sample เพี้ยนจาก `docker stats` (ตัดค่าที่เกิน 100% × core)
- **verify (local app :3000 → api :3002 / ws :3003 → dev DB · LiveKit local docker):**
  - lt10 1 presenter + 4 viewers: ทุก rate 100% · fanout 1ms · กระดิ่ง ~145ms · meetingJoin 2ms · media-token ~200ms
  - lt12 5 viewers: resume 5/5 session เดิม · หลุดไม่กลับ → `stopped` ตรง grace 2 นาที (debug log: หลุด +110s → stopped +230s) · bell/end 10/10
  - lt11 40 viewers / 8m / 3 รอบ / 20% ในห้องประชุม: ทุก rate 100% · fanout p95 1ms · กระดิ่ง p95 300ms · meeting p95 4ms · media-token p95 311ms · http fail 0/1848
  - media (lk ใน docker network, high, 1 video + 1 audio): 10 → 0% · 25 → 0% (1.4 Mbps/คน) · 50 → 0.05% · 100 → 0.6% (285–437 kbps/คน = LiveKit ลด simulcast layer) · **150 → 2.3% หยุด** · lk จาก host ผ่าน Docker proxy ตันก่อน (25 คน loss 1%) จึงไม่ใช้
  - `make check` · `git diff --check` · `make clean-dry` (500 users, rollback, ไม่ติด FK — zone/กระดิ่ง cascade)
- **ความหมายของตัวเลข:** control plane 40 คนยังสบายมาก ยังไม่ถึงเพดาน · media 100–150 คนดูคือเพดานของ **MacBook เครื่องนี้** (lk + LiveKit แย่ง CPU 8 core เดียวกัน) ไม่ใช่ของ server จริง
- **ยังไม่ได้รัน:** lt11 ขนาดเต็ม (500 viewers — ต้อง seed 501 user และ DB เป็น dev ที่ยังไม่รู้ว่าแชร์กับ prod ไหม: Q1) · media บน SFU จริง · `SCREEN=1`
- **ต่อจากนี้:** ตัดสิน Q1 → `make seed USERS=501` → lt11 เต็ม · media บน VM/SFU แยกด้วย `LIVEKIT_URL` + `LT_ALLOW_REMOTE_SFU=1`

## 2026-09-25 (รอบ 2) · rif (ร่วมกับ Claude Code) — form login, lt06 spread, verify lt03/04/08

- **ทำอะไร** (`zyra-loadtest@feat/smoke-structure`, ยังไม่ commit):
  - `k6/flows/login.js` (แทน stub) + `lib/api/auth.js` `postLogin` — `POST /api/authen/login` form-data ตาม `auth_handler.go` · metric `login_ms`/`login_ok` · กัน S-07: `setup()` login user แรก 1 ครั้งก่อน ถ้ารหัสผิดหยุดทันที · VU ไหนโดนปฏิเสธ credential (body.status 400/403/423) → abort ทั้ง test · 5xx/timeout = นับเป็นผล แล้วใช้ token ที่ mint ต่อ
  - poller เรียก `GET /api/authen/session-state` ทุก 30s เมื่อ login จริง (refresh_token cookie ใน jar ของ VU) → ปิด gap "session-state ไม่ครอบคลุม"
  - `lt07` ใช้ form login เป็นค่าเริ่มต้น (spec §7 token B) · `LOGIN=0/1` override ได้ทุก scenario · กัน `LOGIN=1` กับ DURATION > 14m (access token อายุ 15m, bot ไม่ refresh)
  - `lib/users.js` — `single` (default): ใช้เฉพาะ user ของ workspace แรกใน tokens.json · `spread` (lt06): round-robin ทุก workspace → เดิม lt06 ที่ VUS < จำนวน user จะไปกองที่ workspace แรก และ scenario 1 office จะหลุดไป workspace อื่นถ้า seed หลาย workspace
  - Makefile `TTL=` ส่งให้ `seed`/`refresh` (lt08 2h ต้อง `make refresh TTL=3h`)
- **verify (local app :3000 → api :3002 / ws :3003 → dev DB, 500 lt_ users / 1 workspace):**
  - `make check` ผ่าน · `git diff --check` สะอาด
  - lt07 `LT_PASSWORD` ผิด → ส่ง login 1 ครั้งแล้ว setup หยุด (`lt_0001` attempts=1 แล้วรีเซ็ตตอน login ถูกรอบถัดไป)
  - lt07 5 VU 1m: login 5/5, session-state 200 ทุกครั้ง, checks 251/251 · **enter p95 1.72s ✗** — 5 VU ก็ยังเกิน → เป็น latency (api local → dev DB, `/me` ~180ms/รอบ × 4 รอบ) ไม่ใช่ load
  - lt03 10 VU 1m ✓ · lt04 VUS=12 → 13 VU ครบ 5 step / 2m30s ✓ (goto ชนผนัง 3) · lt08 5 VU 1m ✓ · smoke 3 VU ✓ (regression)
  - lt06: ทดสอบ offline ด้วย tokens ปลอม 3 workspace → VU กระจาย ws1/ws2/ws3 ถูก · single abort เมื่อ user ไม่พอ · **ยังไม่ได้ยิงจริง** (ต้อง clean + seed `WORKSPACES>1`)
- **ยังไม่ได้รัน:** ทุก scenario ขนาดเต็ม · lt06 จริง · lt04/lt05 flag `VO_TICK_*` off/on
- **ไม่ครอบคลุม:** `/api/img` (ผ่าน Next เท่านั้น), meeting/media (Q5)
- **สถานะ dev ตอนนี้:** lt_ users 500 คน / `lt_ws_01` (seed 11:52) ยังค้าง — `make clean YES=1` เมื่อเลิกใช้
- **ต่อจากนี้:** ตัดสิน Q1 ก่อนยิงขนาดเต็ม · lt06 ต้อง `make clean YES=1` → `make seed … USERS=100 WORKSPACES=4 YES=1` · หาสาเหตุ lt07 ช้า (ลองยิงจาก network เดียวกับ DB)

## 2026-09-25 · rif (ร่วมกับ Claude Code) — WS + office journey + lt02–lt09

- **ทำอะไร** (`zyra-loadtest@feat/smoke-structure`, ต่อจาก commit `16af079` ของ rif — ยังไม่ commit ส่วนนี้):
  - `k6/lib/ws.js` — ต่อ `/ws` (ส่ง `Origin` = BASE_URL ไม่งั้น ws ตอบ 403), รอ `welcome`, `ping` 300ms/1.2s/ทุก 3s, อ่านทุก frame (text + binary), metric `ws_welcome_ok`/`ws_welcome_ms`/`ws_ping_rtt_ms`/`ws_errors`/`ws_goto_rejected`
  - `k6/lib/api/` แยกตามหมวด (user, workspace, map, chat, auth) + `getMany` (parallel แบบ `Promise.all` ของ app) · body.status รับทั้ง `200` และ `"success"` (chat, members ตอบแบบหลัง)
  - `k6/lib/poller.js` — maintenance 10s, app presence 30s, workspace presence 30s (start แบบ random offset)
  - `k6/flows/enterOffice.js` — ลำดับเดียวกับ app: workspace∥maps → zones∥objects → me∥conversations∥unread∥avatars∥default avatar∥members∥objects/all → workspace presence · `k6/flows/visit.js` — entry → polling → WS → behavior → ออก
  - `k6/behaviors/` — idle · walker (movement v2 `input` + keepalive 150ms, `goto` บ้าง, โหมด cluster) · chatter (`chat:join` → typing → REST POST message → WS `chat:message` relay, 1 ข้อความ/10–20s)
  - `k6/lib/scenario.js` — builder ที่ lt02–lt09 ใช้ร่วม (steps + spread, `VUS`/`DURATION`/`MIX` override) · เขียน lt02–lt09 ตาม spec §6
  - seeder: สร้าง `#general` + สมาชิกครบตอน seed (ปิด gap "ไม่สร้าง #general" ของรอบก่อน) · `refresh` (re-mint token จาก `seed.json` ไม่แตะ DB) · token มี `display_name`
  - local ws = **:3003** (`zyra-ws/.env`) ไม่ใช่ 3004 (3004 = zyra-notifications) → แก้ `.env` + default ใน `config.js`
- **verify (local api :3002 / ws :3003 → dev DB):**
  - smoke 5 VU 30s + WS: ทุก threshold ผ่าน, welcome 5/5, ping p95 51ms
  - lt02 10 VU 2m: check 570/570, http fail 0%, `/me` p95 344ms, enter office p95 1.51s, welcome 10/10 · chatter ส่งจริง 9 ข้อความ (เห็นใน clean-dry `tb_message`)
  - lt09 10 VU 2m (drop ที่ 1m): 20 sessions, welcome 100%, http fail 0%
  - lt05 6 VU 1m: ผ่าน · goto ชนผนัง 52 ครั้ง → นับแยก `ws_goto_rejected` (server ตอบ `error: no path to destination`)
  - lt07 10 VU 1m: **enter office p95 1.71s ✗ เกินเกณฑ์ 1s** — ที่ 10 คน · entry มี 4 รอบต่อกัน แต่ละรอบ ~300–500ms (api บนเครื่อง → dev DB ข้ามเน็ต) → ต้องแยกว่าช้าที่ DB/network หรือที่ api ก่อนสรุป
  - clean-dry หลังเทส: ลบ `tb_message` 9, `tb_conversation` 1 (#general), workspace, user ได้ครบ (rollback)
  - แก้ bug ระหว่างทาง: idle behavior คืน stop ผิดชั้น · `DURATION` สั้นกว่าเวลาเริ่ม step ทำ maxDuration ติดลบ (ตอนนี้ step start ยืด/หดตาม DURATION) · lt09 เดิม drop ตามเวลาเริ่มของแต่ละ VU (ไม่พร้อมกัน) → เปลี่ยนเป็นเวลาเดียวกันของทั้ง test
- **ยังไม่ได้รัน:** lt02 เต็ม (50/15m), lt03, lt04 (ต้อง 1000 user), lt06, lt08 · lt04/lt05 flag `VO_TICK_*` off/on
- **ไม่ครอบคลุม:** `session-state` (ต้องใช้ refresh cookie — token ที่ mint ไม่มี), form login (`flows/login.js` ยัง stub), `/api/img` (มีแค่ผ่าน Next), meeting/media (Q5)
- **สถานะ dev ตอนนี้:** มี lt_ users 100 คน + `lt_ws_01` ค้างอยู่ (seed 10:46) — ลบด้วย `make clean YES=1` เมื่อเลิกใช้
- **ต่อจากนี้:** รัน lt02 เต็ม → lt03 → เช็คผล lt07 ว่าช้าที่ไหน · ตัดสิน Q1 ก่อนยิงเกิน ~100 คน (MacBook เครื่องเดียวรันทั้ง k6 + api/ws)

## 2026-09-24 (รอบ 2) · rif (ร่วมกับ Claude Code) — seeder seed/clean

- **ทำอะไร:**
  - Q3 ตอบแล้ว: seed ลง **dev** DB ได้ แต่ต้อง clean ได้หมด
  - `seeder seed` — ไม่ใส่ `--source` = แสดงรายการ template · `--source <id> --users N --workspaces W --yes` → สร้าง `lt_NNNN@loadtest.invalid` + `lt_ws_NN` (clone จาก template) + membership → `data/seed.json`, `data/tokens.json` (มี `workspaceId`/`mapId`) · ไม่ยอมถ้ามี lt_ user อยู่แล้ว
  - `seeder clean` — `--dry-run` (รัน DELETE จริงแล้ว rollback → จำนวนแถวถูกต้อง) / `--yes` · transaction เดียว · ลบตาราง FK `NO ACTION` + ตารางไม่มี FK ก่อน → workspace → user · ลบ Redis `vo:*<ws id>*` · ลบ `data/tokens.json`/`seed.json`
  - Makefile: `make seed SOURCE= USERS= WORKSPACES= YES=1`, `make clean-dry`, `make clean YES=1` · `.env.example` เพิ่ม `REDIS_URL`, `LT_PASSWORD`
  - `tokens` default role เปลี่ยนจาก `user` เป็น `MEMBER` (ตรงกับ `register_service.go`)
- **verify (บน dev `35.247.177.198:3500/zyra-db`):**
  - อ่าน FK graph จาก DB จริง (read-only) → ลำดับ DELETE ใน `seeder/clean.go`
  - ไม่ใส่ `--yes` → ไม่เขียน ✓
  - seed 3 users / 1 workspace จาก template "Zyra World" (`4bac2b15-…`): users MEMBER/verified/active/onboarding completed, มี authen, owner + 2 member · workspace live, 1 map published, objects 1277 / zones 123 / version 1 ตรงกับ template ✓
  - `clean --dry-run` → นับได้ user 3 / workspace 1 / map_version 1 แล้ว rollback, ข้อมูลยังอยู่ ✓
  - `clean --yes` → commit · ตรวจทุกตาราง (user, authen, workspace, member, map, object, zone, version, activities) = 0 · ยอดรวม dev กลับเป็น user 79 / workspace 46 เท่ากับก่อน seed ✓
  - แก้ bug ที่เจอตอน verify: arg count ไม่ตรงกับ placeholder · `tb_workspace` step ระบุ type `$1` ไม่ได้ (เพิ่ม `AND owner_id = ANY($1)`)
- **ยังไม่ได้ verify:**
  - ยิง api/ws ด้วย token ของ user ที่ seed — ตอน verify api local (:3002) ปิดอยู่
  - clean หลังจากที่ bot สร้างข้อมูลระหว่างเทสจริง (message, session, presence, notification) — รอบนี้ลบได้แค่ข้อมูลที่ seed สร้าง
  - clean Redis — Redis local (:6379) ปิดอยู่ ตอนนั้นยังไม่มี key (ไม่มี ws connection)
- **ต่างจาก api:** ไม่สร้าง `#general` channel · `map_version.map_json` ใช้ `published_objects_json` ของ template
- **PR:** — (ยังไม่ commit)
- **ต่อจากนี้:** เปิด api/ws local → `make seed SOURCE=4bac2b15-02d5-4523-be9d-90b0c7ea32eb USERS=5 YES=1` → `make smoke VUS=5` → `make clean YES=1` · จากนั้น `ws.js` + ใส่ WS ใน smoke
- **ติดอะไร:** Q1 (ยิงแบบไหน) · ยังไม่ตัดสิน: meeting (Q5) / `lt10-full-office` / สัดส่วน bot

## 2026-09-24 · rif (ร่วมกับ Claude Code)

- **ทำอะไร:**
  - ร่าง [spec.md](spec.md) — baseline จากโค้ด 5 repo, safety §4, load model §5, SC-LT-01..09 §6 (+ §6.1 คำอธิบายแต่ละ scenario), gap §9, open questions §10
  - สร้างโครง `zyra-loadtest` บน `feat/smoke-structure` (แตกจาก `main` — repo ไม่มี `develop`):
    - `seeder/` Go CLI — `tokens` ใช้ได้ (mint JWT HS256 ด้วย `TOKEN_KEY`, claim `type=access`) · `seed`/`clean` = stub
    - `k6/lib/` — `config.js` (URL + guard prod / >5 VU บน `*.zyra.center`), `users.js` (1 VU = 1 user), `api.js` (`getMe` + log สาเหตุ failure แรก) · `poller.js`/`ws.js` = stub
    - `k6/behaviors/`, `k6/flows/` = stub · `k6/scenarios/lt01-smoke.js` ใช้ได้ · `lt02`–`lt09` = stub (abort "not implemented")
    - `Makefile` (`tokens`, `smoke`, `run S=`, `check`), `.env.example`, `.gitignore` (`data/`, `reports/`, `.env`)
- **verify:**
  - `make check` (go vet + `k6 inspect` ทุก scenario) ผ่าน
  - guard prod URL → abort ✓ · ไม่มี token → setup error ✓
  - smoke บน local (api :3002 → dev DB `35.247.177.198`) ด้วย user ที่ active: check 78/78, `http_req_failed` 0%, p95 242ms, 26 req (`reports/lt01-smoke-20260924-135355.json`)
  - user แรกที่ลองได้ 403 `account_deleted` — token ถูก แต่ user ถูกลบ
- **PR:** — (ยังไม่ commit ทั้ง `zyra-loadtest` และ `zyra-doc`)
- **ยืนยันแล้ว:** DB `35.247.177.198` (api local) = **dev**
