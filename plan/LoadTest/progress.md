# Load Test — Progress / Handoff

> **สถานะรวม:** spec draft · โครง `zyra-loadtest` เสร็จ · smoke 1 endpoint ผ่าน · seeder `seed`/`clean` ใช้ได้ (verify บน dev) · k6 ส่วนอื่นยังเป็น stub
> **อัปเดตล่าสุด:** 2026-09-24 · **คนล่าสุด:** rif (ร่วมกับ Claude Code)

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
