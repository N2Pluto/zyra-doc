# Load Test — Progress / Handoff

> **สถานะรวม:** spec draft · seeder + WS + office journey + form login + lt01–lt09 + Spotlight lt10–lt12 / media ใช้ได้ · verify แบบย่อ (≤41 VU) บน local→dev ครบทุกตัวยกเว้น lt06 (ต้อง seed หลาย workspace) · ยังไม่ได้รันขนาดเต็ม
> **อัปเดตล่าสุด:** 2026-10-06 · **คนล่าสุด:** Claude Code

## 2026-10-06 (รอบ 2) · Claude Code — Phase 0 ของ prod-clone-plan (verify ของจริง)

- **ผู้ใช้สั่ง:** "login แล้ว ทำ Phase 0 ต่อเลย"
- **ทำอะไร (อ่านอย่างเดียว):** `gcloud` list/describe (VM, disk, AlloyDB, Redis, bucket, secret, subnet) · IAP SSH `zyra-k3s` → `kubectl top/get` + Prometheus 7 วัน · อ่าน secret เฉพาะ host/ชื่อ bucket · ราคาจาก Cloud Billing Catalog API → ผลลง [prod-clone-plan §11](prod-clone-plan.md#11-phase-0--ผล-verify-ของจริง-2026-10-06) + แก้ §2 ตามของจริง
- **ผลหลัก:** machine type ตรง repo · prod รัน `v1.7.3`/`ws v1.7.0` (repo ในเครื่องเก่า 63 commit) · sfu-lite เปิดอยู่บน main node · AlloyDB PITR 14 วัน → restore เข้า cluster ใหม่ได้ · node peak 7 วัน 2.5 core / load1 15 / mem 13.4 GiB · **ws online 75 คนขณะ node CPU 32%** (ตัวเลข saturate 40–60 CCU เดิมเป็นช่วงก่อนย้าย SFU) · ค่าใช้จ่าย clone ครบชุด ≈ $1.17/ชม. (list price) · dev DB = VM `gather-dev` (ACCESS.md ผิด)
- **เจอนอก scope:** dev ใช้ Redis prod db 0 ร่วมกับ prod · uat ใช้ bucket prod — §11.6
- **ไม่ได้ทำ:** `terraform plan` ของ prod (ต้อง lock state) · หาต้นเหตุ load1 15 / mem 13.4 GiB ที่พีค
- **ต่อจากนี้:** ผู้ใช้ตอบ Q1–Q8 + อนุมัติงบ → Phase 1

## 2026-10-06 · Claude Code — แผน load test บน prod clone

- **ผู้ใช้สั่ง:** "อยากให้มันทำงานบน prod … clone prod ออกมาก่อนหนึ่งตัว จะได้ไม่เกี่ยวข้องกัน แต่ใช้ spec เครื่องของ prod · สร้างเป็น plan ไว้"
- **ทำอะไร:** เขียน [prod-clone-plan.md](prod-clone-plan.md) — env `loadtest` แยกทั้งหมด (VM e2-standard-4 + SFU c2d-highcpu-4 + AlloyDB 2 vCPU + Memorystore 1 GB + bucket + secret + DNS + Argo ของตัวเอง) · terraform root แยก (root prod มี drift ที่จะ replace VM) · 7 phase · safety S-10..S-14 · Q1–Q8
- **ถึงไหน:** planning only — ไม่ได้สร้าง/แก้อะไรบน cloud
- **verify:** ข้อมูล infra อ่านจากไฟล์ใน repo เท่านั้น · gcloud login หมดอายุ, ไม่มี kubeconfig, Grafana MCP ต่อไม่ได้ → ยังไม่ได้ยืนยันกับของจริง (Phase 0)
- **ต่อจากนี้:** ผู้ใช้ตอบ Q1–Q8 · `gcloud auth login` แล้วทำ Phase 0 + ประเมินค่าใช้จ่าย
- **ติดอะไร:** credential GCP · Q1 (restore ข้อมูลจริงหรือไม่) ต้องให้คนดูแลข้อมูลตัดสิน
- **พบระหว่างทาง:** spec §3.1 ล้าสมัย (SFU ย้ายไป node แยกแล้ว 2026-09-24) · `ACCESS.md` บอก dev อยู่ AlloyDB `postgres` แต่ spec Q1 บอก `35.247.177.198` — ยังไม่ได้เคลียร์

## 2026-09-30 (รอบ 4) · rif (ร่วมกับ Claude Code) — บอกว่าแต่ละ scenario ทดสอบอะไร (ภาษาไทย)

- **ผู้ใช้สั่ง:** "อยากให้บอกด้วยแต่ละอัน test อะไร ภาษาไทย"
- **ทำอะไร:** `web/metrics.js` เพิ่ม `SCENARIOS_TH` (คำถาม / ทำอะไร / ทำไมต้องมี / ผ่านเมื่อ ของทั้ง 19 scenario — ย่อจาก spec §6.1 / §12.2 / §13.2) · ภาพรวมแสดงคำถามไทยใต้ชื่อแทนคำอธิบายอังกฤษ · หน้า scenario แสดงครบ 3 บรรทัด · หน้า run แสดงคำถามใต้ชื่อ + รายละเอียดในหัวข้อ "Scenario นี้ทดสอบอะไร"
- **verify:** `make check` ผ่าน · `node --check` · screenshot ภาพรวม / scenario / run ไม่มี JS error
- **หมายเหตุ:** ข้อความไทยซ้ำกับ spec — แก้ spec แล้วต้องแก้ `SCENARIOS_TH` ด้วย

## 2026-09-30 (รอบ 3) · rif (ร่วมกับ Claude Code) — รื้อ UI ใหม่แบบ minimal

- **ผู้ใช้สั่ง:** "แก้ UI ใหม่หมด เอาให้สวย ๆ อ่านง่าย ๆ ไม่รก minimal"
- **ทำอะไร** (`feat/dashboard`, ยังไม่ commit): เขียน `web/index.html`, `app.css`, `app.js`, `run.js` ใหม่ — ตัด sidebar เหลือแถบบน + คอลัมน์เดียว · เส้นบางแทนกล่อง · ชื่อ scenario เป็นภาษาคน · หน้า run เริ่มด้วยคำตัดสินเป็นประโยค → ตัวเลขหลัก 4 ตัว → เกณฑ์ → กราฟ แล้วพับรายละเอียดที่เหลือ · แชทเป็น drawer ทับหน้า (Esc/กดนอกกรอบปิด) · ข้อมูลเท่าเดิม ไม่แตะ Go/API — รายละเอียด [how-to-run §7](how-to-run.md#7-dashboard-รวมผล--แชทถาม-ai-make-dashboard)
- **verify:** `make check` ผ่าน · `node --check` ทุกไฟล์ · screenshot ภาพรวม / scenario / run (lt14 จริง + lt07 ปลอมมี error) / media / แชท / มือถือ 390px — ไม่มี JS error, ไม่มี scroll แนวนอน
- **ยังไม่ได้ verify:** ผู้ใช้ยังไม่ได้เปิดดูกับข้อมูลของตัวเอง

## 2026-09-30 (รอบ 2) · rif (ร่วมกับ Claude Code) — หน้า run แสดงข้อมูลครบ + อ่านง่ายขึ้น

- **ผู้ใช้สั่ง:** "แสดงข้อมูลให้ครบหน่อย ข้อมูลดูยากมาก"
- **ทำอะไร** (`feat/dashboard`, ยังไม่ commit):
  - หน้า run เขียนใหม่ (`web/run.js`): สรุป 6 ช่อง · เกณฑ์เป็นภาษาคน + แถบเทียบเกณฑ์ · กราฟตลอดการรัน (small multiples) + ตารางราย step · ทุก metric แยกหมวดพร้อม avg/min/med/p90/p95/max/n · error · check ราย endpoint · แถบลัดไปแต่ละส่วน — วิธีอ่าน [how-to-run §7](how-to-run.md#7-dashboard-รวมผล--แชทถาม-ai-make-dashboard)
  - `web/metrics.js`: ชื่อไทย + คำอธิบาย + หมวด ของทุก metric ที่ scenario ส่งออก · หน้าภาพรวม/scenario ใช้ชื่อไทยแทนชื่อ metric ดิบ
  - API: `/api/runs/{name}` ส่งทุก metric + checks · ใหม่ `/api/runs/{name}/timeline` (digest ของ `samples.json.gz` เป็น JSON)
  - `samples.go`: แยก `collectSamples` (เก็บข้อมูล) ออกจากการเขียนข้อความ — ข้อความที่ `analyze` ส่งให้ AI เหมือนเดิมทุกตัวอักษร (เทียบ lt14 จริง 2 รอบก่อน/หลังแล้ว)
- **verify:** `make check` ผ่าน · `node --check` ทุกไฟล์ JS · `git diff --check` · screenshot หน้า run ของ lt14 จริง + lt07 ปลอมแบบ 3 step มี error (desktop + มือถือ 390px ไม่มี scroll แนวนอน, ไม่มี JS error)
- **ยังไม่ได้ verify:** รอบใหญ่จริง (samples หลายร้อย MB — ส่วน "ตลอดการรัน" จะโหลดช้า แต่ส่วนอื่นขึ้นก่อน) · ผู้ใช้ยังไม่ได้เปิดดูกับข้อมูลของตัวเอง

## 2026-09-30 · rif (ร่วมกับ Claude Code) — Dashboard รวมผล + แชท AI

- **ผู้ใช้สั่ง:** อยากมี dashboard รวมของทุกอัน (วางแผนก่อน) → "ทำเลย อิง UI จาก app กับ landing และมี AI แชทบอทสำหรับถาม"
- **ทำอะไร** (`zyra-loadtest` branch `feat/dashboard` จาก `develop`, ยังไม่ commit):
  - `make dashboard` → `analyze serve` — local server 127.0.0.1:5666 อ่าน `reports/` สดทุก request (ไม่ generate ไฟล์) · spec [§14](spec.md#14-dashboard-รวมผล--แชท-ai-เพิ่ม-2026-09-30) · วิธีใช้ [how-to-run §7](how-to-run.md#7-dashboard-รวมผล--แชทถาม-ai-make-dashboard)
  - `analyze/runs.go` (index รอบ: สถานะจาก threshold, p95/rate หลัก, options, VUs, ไฟล์ที่มี) · `serve.go` (API + เสิร์ฟไฟล์เฉพาะ report.html/analysis.md/summary.md/run-options.txt, กัน Host แปลก + แชทต้อง JSON) · `chat.go` (Claude + tool อ่านอย่างเดียว 3 ตัว, stream SSE) · `web/` (หน้าเว็บฝังใน binary)
  - `main.go`: แยก prompt ส่วน "อ่านตัวเลขยังไง + ข้อเท็จจริงของระบบ" เป็น `readingGuide` ให้แชทใช้ร่วม · `aiModel()` · subcommand `serve` — prompt ของ `analyze` เหมือนเดิมทุกตัวอักษร (เทียบกับ HEAD แล้ว)
  - UI: dark แบบ zyra-app admin (`#1A1B1E` / `#242B32` / เขียว `#58D68D` / แดง `#F03A3A`), icon lucide (คัด path จาก lucide-react ของ app), หัวข้อ Poppins + ปุ่ม pill แบบ landing
- **verify:**
  - `make check` ผ่าน (go vet seeder/analyze + k6 inspect ทุก scenario) · `node --check web/app.js` · `git diff --check`
  - API กับ `reports/` จำลองใน scratchpad (lt14 จริง 2 รอบ + lt07 ปลอม 4 รอบ + meeting-media ปลอม 1 รอบ): runs/scenarios/detail ถูก · `summary.json` → 404 · path traversal → 404 · Host `evil.com` → 403 · แชท `text/plain` → 415
  - screenshot (Chrome headless / Playwright): ภาพรวม, scenario + กราฟ + tooltip, run, media, แผงแชท, มือถือ 390px (ไม่มี scroll แนวนอน) · ไม่มี JS error
  - แชทจริง 2 คำถาม (`claude-sonnet-5`): เรียก `list_runs` / `get_run` เอง ตอบไทยพร้อมตาราง ถูกตามข้อมูล, บอกเองว่า load shape ไม่เท่ากันเทียบตรงไม่ได้ · ส่งผ่านหน้าเว็บ stream แสดงผลถูก
- **ยังไม่ได้ทำ / ไม่ได้ verify:** ผู้ใช้ยังไม่ได้เปิดกับ `reports/` จริงของตัวเอง · ผล media ไม่มีสถานะผ่าน/ไม่ผ่าน (scripts เขียนแค่ summary.md) · แชร์ให้ทีม (Q6) · Google Fonts ต้องมีเน็ต (ไม่มีก็ใช้ font ระบบ)
- **PR:** — (ยังไม่ commit)

## 2026-09-28 (รอบ 3) · rif (ร่วมกับ Claude Code) — AI สรุปผลครอบคลุมขึ้น

- **ผู้ใช้สั่ง:** แก้ prompt ของ AI ตอนสรุปให้ครอบคลุมที่สุด
- **ทำอะไร** (`zyra-loadtest@feat/meeting-loadtest` · แก้เฉพาะ `analyze/` + Makefile แยก commit ได้):
  - `analyze/samples.go` ใหม่: ย่อ `samples.json.gz` บนเครื่อง → ตารางต่อ k6 scenario (step), timeline (≤30 ช่วง), error แยก endpoint+status / ws_errors reason / check ที่ล้ม · percentile จาก reservoir ≤5000 ค่า/ช่อง · ไม่ส่งไฟล์ดิบ
  - prompt ใหม่: glossary ของ metric ทุกกลุ่ม (office / spotlight / meeting / media) · ข้อเท็จจริงของ setup (DB ต่อทุก request, ws ถาม api ทุก connect, k6/lk อยู่เครื่องเดียวกับ server, LiveKit v1.13.0 goroutine) · วิธีหาจุดพังจาก step/timeline, drift ตามเวลา, แยกผลของเครื่องทดสอบ, ติดป้าย จากข้อมูล/สันนิษฐาน + วิธียืนยัน · output 9 หัวข้อ (เพิ่ม จุดที่เริ่มพัง/แนวโน้ม, error ที่เจอ, ความน่าเชื่อถือของผล)
  - `make smoke`/`run` บันทึก `run-options.txt` (VUS/DURATION/MEETINGS/PEOPLE/PROFILE/… ที่ตั้งไว้ ไม่มีค่าลับ) → ส่งให้ AI ตัดสินจากโหลดที่รันจริง ไม่ใช่ค่า default
- **verify:** dry-run lt15 ได้ตาราง step/timeline/error ถูก · เรียกจริง (claude-sonnet-5) กับ lt15: ได้ครบ 9 หัวข้อ, บอก "ไม่พบจุดพัง" พร้อมตารางต่อ step, เช็ก drift, จับได้เองว่ารอบถูกย่อขนาดและ n เล็ก · `run-options.txt` เขียนจริงจาก lt14 · `go vet`
- **ข้อสังเกต:** lt14 รอบหลัง media-token p95 1.12s (เดิม ~270ms) ขณะเครื่อง load average 20–35 (Chrome ฯลฯ) — เป็นเครื่อง/เครือข่าย ไม่ได้เกี่ยวกับโค้ด · มี k6 ค้างสถานะ T จาก 2026-09-25 อยู่ 4 ตัว (PID 14646, 16797, 17383, 53396) ไม่กิน CPU แต่ควร kill

## 2026-09-28 (รอบ 2) · rif (ร่วมกับ Claude Code) — Meeting load test (spec §13)

- **ผู้ใช้สั่ง:** "มีกี่ห้องถึงพัง" · ครอบคลุมทุกกรณี (เสียง / กล้องทุกคน / กล้อง + แชร์จอ) · LiveKit เวอร์ชันเดียวกับ prod · เกณฑ์ตามที่เสนอ · รวมแชร์จอ · **แยก branch**
- **branch:** `zyra-loadtest@feat/meeting-loadtest` (แตกจาก `develop` ที่มีงาน Spotlight/AI แล้ว) · `zyra-doc@rif` · ยังไม่ commit · workspace root `docker-compose.yaml`
- **ทำอะไร:**
  - LiveKit local → `livekit/livekit-server:v1.13.0` (เดิม `latest`) + `max_participants 50`, `empty_timeout 300`, `prometheus_port 6789` (อ่าน `go_goroutines`) · ตอนว่าง 115 goroutine (prod ว่าง 114)
  - `scripts/lib/livekit.sh` (guard, lk ใน docker, sampler CPU/RAM แบบ stream + goroutine ทุก 1s, parse ผล lk) · `spotlight-media.sh` ย้ายมาใช้ lib + คอลัมน์ goroutine
  - `scripts/meeting-media.sh` (SC-LT-18): `PROFILES` audio/camera/share × `ROOMS` 1→40 พร้อมกัน, ห้องละ `PEOPLE` · หยุดรูปแบบนั้นเมื่อห้องแย่สุด loss > 2% · สรุป "แต่ละรูปแบบพังที่กี่ห้อง"
  - `scripts/meeting-churn.sh` (SC-LT-19): คนชุดเดิมเข้า-ออกห้องซ้ำ + anchor ให้ห้องไม่ปิด → goroutine ค้างต่อ join, หลังห้องว่าง
  - `k6/lib/meeting.js` + `lt14`–`lt17` (ไฟล์เลขตรง SC ID): room_enter → media token → `ws:room:enter` → `ws:meeting:ownerUpdate` · ไมค์/กล้อง/ยกมือวัดแบบ echo (broadcast ในห้องถึงคนส่งด้วย) · meeting chat ใส่เวลาส่ง · แชร์จอ (คนแรกของห้อง) · churn · `PROFILE=audio|camera|share|mixed` · `sameMeeting` สำหรับ lt16 · `users.js userAt()` (เลือก user ตามลำดับ ไม่ใช้เลข VU)
  - 401 ตอน setup (token หมด) บอกให้ `make refresh` แทนข้อความผิดว่า "ไม่มี zone" (meeting + spotlight)
- **บั๊กของ script ที่เจอระหว่าง verify:** sampler `docker stats --no-stream` ช้าจนได้ 0–2 ตัวอย่าง → เปลี่ยนเป็น stream · goroutine sampler ตายเพราะ `awk exit` → curl SIGPIPE + `pipefail` · เอามือลงหลังออกห้อง → `not in this media room` · `mixed` วางห้องแชร์จอลำดับที่ 10 (รอบเล็กไม่มีเลย) → ย้ายขึ้นก่อน · รัน meeting-media ค่าเต็มโดยไม่ตั้งใจ 1 ครั้ง (local เท่านั้น) หยุดแล้ว ลบผล
- **verify (local → dev DB, 1000 lt_ users / 1 workspace):** lt14 3 คน: 100% ทุกข้อ (เข้าห้อง ~250ms ≈ เวลาขอ token) · lt15 7 ห้อง × 3 / 4m ✓ (เข้าห้อง p95 317ms) · lt16 10 คน share / 3m ✓ · lt17 2 × 3 churn / 2m ✓ (21 enters) · `meeting-media` รอบเล็ก (audio/camera/share 1–2 ห้อง) ✓ · `meeting-churn` 8 รอบ × 4 คน: ค้าง 0.1/join (lk client ไม่ reproduce ปัญหา prod — prod น่าจะมาจากพฤติกรรม browser client เช่น join ซ้ำใน < 10s / departure timeout) · `make check`
- **`meeting-media` เต็มชุดบน MacBook (v1.13.0, ห้องละ 5 คน, 60s/ขั้น):** เสียงอย่างเดียวเสียที่ 5 ห้อง (loss 11%) · กล้องและกล้อง + แชร์จอเสียตั้งแต่ 1 ห้อง (loss 3–3.5%) · CPU ของ LiveKit พุ่ง 700%+ จาก 8 core
- **A/B v1.13.0 กับ `latest` (โหลดเดียวกัน camera/audio 1 และ 3 ห้อง, 30s):** ทั้งสองเวอร์ชันเสียที่ ~3 ห้อง (15 คน) · ผลไม่นิ่ง (v1.13.0 audio 1 ห้อง track 17/25) · `latest` CPU ต่ำกว่าเล็กน้อยตอนโหลดน้อย (audio 1 ห้อง 30% vs 124%) แต่ที่ 3 ห้องพอกัน
- **สรุป:** ตัวเลข media ของ meeting บนเครื่องนี้ = **เพดานของ MacBook ไม่ใช่ของ LiveKit** — meeting หนักกว่า Spotlight มาก เพราะทุกคนต้องได้ stream ของทุกคน (P × P) และตัวจำลอง lk ใช้ 3 connection ต่อคน (ห้อง 3 ห้อง = 45 connection) ทั้งหมดแย่ง CPU กับ LiveKit ใน Docker 8 core เดียวกัน · **ต้องรันบน env ที่ทีม clone จาก prod** (LiveKit แยกเครื่อง + ตัวยิงบน VM อีกเครื่อง) ถึงจะได้คำตอบ "กี่ห้องถึงพัง" ที่เชื่อได้ · ฝั่ง ws/api (lt14–lt17) วัดบนเครื่องได้ตามปกติ
- **ยังไม่ได้รัน:** lt15–lt17 ขนาดเต็ม · lt15 เกิน 18 ห้อง (ต้อง seed หลาย workspace) · meeting-media / spotlight-media บนเครื่องแยก

## 2026-09-28 · rif (ร่วมกับ Claude Code) — แก้ meetingJoin ใน Spotlight load test

- **บั๊ก:** lt10–lt12 ให้คนดูในห้องประชุม**ทุกคน**กด `ws:spotlight:meetingJoin` แต่ zyra-ws `handleSpotlightMeetingJoin` broadcast state ทั้ง floor ทุกครั้ง (กดซ้ำก็ส่ง) → lt11 ขนาดเต็ม 100 คน × 500 viewer ≈ 50,000 ข้อความต่อรอบ เทียบของจริง 1 คน/ห้อง (5 ห้อง ≈ 2,500) — ภาระเกินจริง ~20 เท่า
- **แก้ (`k6/lib/spotlight.js`):** สมาชิกห้องเรียงลำดับ คนแรกกด +2s, สำรองคนถัดไป +1s ต่อคน (สูงสุด 5) และกดเฉพาะเมื่อห้องยังไม่ถูกรับ · เพิ่ม counter `spotlight_meeting_joins` (ควร ≈ ห้อง × รอบ)
- **verify:** lt11 40 viewers / 8m / 3 รอบ: joins = 7 (เดิมทุกคนกดทุกรอบ) · meeting_ok 7/7 · state/bell/end 32/32 · http fail 0 · `make check`
- **สถานะ dev:** seed ใหม่เป็น 1000 user (ผู้ใช้ seed เอง) → lt11 ขนาดเต็ม (501) และ lt04 (1000) มี user พอแล้ว

## 2026-09-25 (รอบ 4) · rif (ร่วมกับ Claude Code) — ไฟล์ผลต่อรอบ + สรุปด้วย AI

- **ทำอะไร** (`zyra-loadtest`, ยังไม่ commit):
  - ทุก `make smoke`/`run` ได้โฟลเดอร์ `reports/<scenario>-<ts>/` มี `summary.json` + `report.html` (k6 dashboard export, ไม่ต้อง `D=1`) + `samples.json.gz` (`--out json`, `SAMPLES=0` ปิด) · ย้ายผลเก่าเข้าโฟลเดอร์แล้ว
  - **แก้ token หลุด:** k6 ใส่ WS URL (มี `?token=<JWT>`) เป็น tag `url`/`name` ของทุก sample → `ws.js` ตั้ง `tags.name = 'WS /ws'` + `SYSTEM_TAGS` (ไม่เก็บ `url`) ในทุก scenario · verify: 3 ไฟล์ 0 token · ผลที่รันก่อนแก้ (`lt12-spotlight-reconnect-20260925-145152`) ยังมี token — ห้ามแชร์
  - `analyze/` (Go, Anthropic Go SDK v1.75, `claude-opus-5`, `fallbacks: "default"`): `make summarize [RUN=] [DRY=1]` / `AI=1` หลัง `smoke`/`run` → `analysis.md` ภาษาไทย · ส่ง summary แบบย่อ (threshold เป็น PASS/FAIL, rate metric เป็น true/false เพราะ `passes/fails` ของ k6 อ่านกลับด้าน) + หัวไฟล์ scenario + รอบก่อน + host · ไม่ส่ง samples
- **verify:** `make check` (seeder + analyze + scenarios) · dry-run ข้อมูลที่ส่งถูกต้อง · ไม่มี key → error บอกวิธีแก้ ไม่เขียนไฟล์ · `AI=1` คง exit code ของ k6 (0)
- **ยังไม่ได้ verify:** เรียก Claude API จริง — เครื่องนี้ยังไม่มี `ANTHROPIC_API_KEY` / `ant auth login`

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
