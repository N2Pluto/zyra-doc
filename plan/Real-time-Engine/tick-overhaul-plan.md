# Server-Tick Overhaul — Plan

> **Status:** **Phase 0 + A IMPLEMENTED** (flag-gated, default OFF) 2026-07-24 — build/test/`-race`/vet เขียว, existing tests ไม่เปลี่ยน (flag off = พฤติกรรมเดิม). **Phase B/C ยังไม่ทำ** (รอผล load test).
> **เปิดใช้:** `VO_TICK_REALTIME_DT=true` (A1 real-elapsed dt), `VO_TICK_ACTIVE_SET=true` (A2 skip idle) — Phase 0 metrics เปิดตลอด (log `vo tick metrics` ทุก 10s). เปิดใน staging + load test ก่อน prod.
> **Module:** [Real-time Engine](spec.md) · scaling context: [capacity-scaling.md](capacity-scaling.md) §3 (Control plane), §6 (intra-map sharding)
> **Why now:** client-side fixes ที่ ship ไป (2026-07-24, ดู memory `vo-rubberband-under-load`) แค่ **กลบอาการ** rubber-band. ต้นเหตุจริงอยู่ที่ server tick — เอกสารนี้คือแผนแก้ root cause
> **ตัวเลขทั้งหมดเป็นประมาณการ — ต้องยืนยันด้วย load test จริง** (ดู §8)

---

## 1. ปัญหา (What / Why)

Rubber-band ("เดิน/วิ่งแล้วเด้งกลับ") ตอนคนเยอะ เกิดเพราะ **server authoritative tile ล้าหลังกว่าที่ client predict** แล้วโดน force_sync/`desync_start`/`stop_rejected` ดึงกลับ. สาเหตุที่ทำให้ server ตามไม่ทัน:

1. **Sim เดินช้ากว่าเวลาจริง (root cause หลัก).** `runMoveTicker` เรียก `stepSimulation(dt)` ด้วย **dt คงที่ = 20.0ms** เสมอ ([room.go `runMoveTicker`](../../../zyra-ws/internal/hub/room.go)). แต่ `time.Ticker` **ทิ้ง tick** ที่ค้าง (channel buffer=1) เมื่องานต่อ tick เกิน 20ms — ดังนั้นถ้า tick จริงเกิดทุก ~40ms sim ยังนับว่าเวลาผ่านไปแค่ 20ms → **โลกในเซิร์ฟเวอร์เดินช้าลง (slow-motion)** ทั้งที่ผู้เล่นทำนายด้วยเวลานาฬิกาจริง → ยิ่งเดินนาน ยิ่ง drift → เด้ง
2. **งานต่อ tick โตตาม N.** `stepSimulation` วน `clients.Range` **ทุกคน** เรียก `stepClientSimulation` (จับ `c.mu` 2 ครั้ง/คนแม้อยู่นิ่ง) ([movement_v2.go:406](../../../zyra-ws/internal/hub/movement_v2.go)) → O(N)
3. **Fan-out โตแบบ O(k²) ใน cluster หนาแน่น.** `flushMoves` วน pendingMoves → ต่อ mover เรียก `aoi.Subscribers` (alloc `[]*Client` cap 64 ทุกครั้ง) + `SendBin` ต่อ peer ([room.go `flushMoves`](../../../zyra-ws/internal/hub/room.go)) — lobby/meeting ที่คนกระจุกใน 3×3 AOI เดียว = ทุก mover fan-out หาทุกคน
4. **ทั้ง step + flush อยู่ goroutine เดียวต่อ room แบบ serial** → ข้อ 2+3 บวกกันดัน tick ให้เกิน 20ms → กลับไปข้อ 1
5. **Snapshot burst.** `runSnapshotTicker` ทุก 3s วนทุก client ทำ `sendNeighborSnapshot` = O(N × neighbors) เป็นก้อนเดียว แย่ง CPU กับ move ticker + WritePump ([room.go `runSnapshotTicker`](../../../zyra-ws/internal/hub/room.go))

> **หลักฐาน:** วิเคราะห์จาก 2 workflow (server-tick reader + review pass, 2026-07-24). `time.Ticker` drop-tick = พฤติกรรม Go มาตรฐาน; dt คงที่ยืนยันจาก `stepSimulation(float64(tickMs / time.Millisecond))`

---

## 2. Goals / Non-goals

**Goals**
- Sim เดินตรงเวลานาฬิกาจริงแม้ tick overrun (แก้ slow-motion) — ให้ force_sync rate **นิ่ง** เมื่อ N โต
- ลด CPU ต่อ tick (O(N) → O(active)) และ bound ต้นทุน fan-out
- **วัดผลได้** ก่อน/หลังทุก phase (metrics)
- รองรับ target [capacity-scaling](capacity-scaling.md): 100–1000 คน/map

**Non-goals (เอกสารนี้ไม่แตะ)**
- Media plane (zyra-sfu) · cross-node sharding by `workspace_id` (นั่นคือ capacity-scaling §7)
- เปลี่ยน wire protocol หรือ DB (ทั้งหมดเป็น internal server change)
- Client reconciliation (ทำไปแล้ว Phase 1–3)

---

## 3. Where (ขอบเขตไฟล์)

`zyra-ws/internal/hub/` เท่านั้น: `room.go` (ticker/flush/snapshot), `movement_v2.go` (stepSimulation/stepClientSimulation), `aoi.go` (Subscribers), `client.go` (SendBin — mutex-safe แล้วจาก MF4). **ไม่กระทบ** `zyra-api`, `zyra-app` (ยกเว้นถ้า Phase C เพิ่ม metric ให้ debug overlay — optional)

---

## 4. Design — แบ่งเป็น Phase ตาม "ความเสี่ยง" (ต่ำ→สูง)

### Phase 0 — Observability (ทำก่อนเสมอ — prerequisite) 🟢 low risk
วัดก่อนแก้ ไม่งั้นบินตาบอด (บทเรียนจาก MF3 ที่ ship แบบ inert เพราะไม่มีตัววัด)
- เพิ่ม per-room metrics: **tick duration (p50/p95/max)**, **dropped-tick count**, **effective sim Hz**, **active-client count**, **flush fan-out count**, **snapshot burst duration**
- Expose ผ่าน log แบบ throttle (เช่นทุก 10s) และ/หรือ `/healthz` หรือ endpoint metrics ภายใน; optional ส่งบางค่าไป debug overlay ฝั่ง client
- **DoD:** เห็นตัวเลขจริงจาก staging load test → ยืนยันปัญหา + เป็น baseline วัด phase ถัดไป

### Phase A — ทำให้ sim เดินตรงเวลา + ข้ามคนนิ่ง 🟢🟡 low–med, **impact สูงสุด**

> ⚠️ **กลไกที่ต้องระวังทั้ง A1/A2: `autoStopPending` (deferred natural-stop).** ถูก arm ใน `closeV2WalkDeferred` ([movement_v2.go:341-353](../../../zyra-ws/internal/hub/movement_v2.go)) ที่ปลายทางหยุดตามธรรมชาติ (click-cancel ไม่มี follow-up / goto ถึงปลายทาง / ปล่อยปุ่ม) และ**ยิงได้เฉพาะใน `ageAutoStopGrace` ซึ่งรันใน `stepClientSimulation` เท่านั้น** ([movement_v2.go:355-394](../../../zyra-ws/internal/hub/movement_v2.go), `v2StopGraceMs=180`). ตอนถูก arm นั้น **`IsMoving/InputDX/DY/PendingGoto` เป็น false/ว่างหมด** — เป็นกับดักของทั้งสอง sub-phase

**A1. Real-elapsed dt + catch-up (แก้ slow-motion โดยตรง)**

> **การตัดสินใจตอน implement (2026-07-24):** เลือก **`MAX_SUBSTEPS = 1` + `MAX_CATCHUP = 150ms` (< sprint leg 152ms)** → commit ได้ ≤1 leg/tick เสมอ → **เลี่ยง multi-leg loop + combined-moving (review-fix #3) + grace-once-in-loop (#5) ไปเลย** และเพราะ 150 < grace 180ms → stale-deferred-stop (#2) ไม่ trigger (แต่ยังใส่ synchronous clear เป็น defense). เหลือแค่ **surplus clamp (#4):** carried remainder clamp ≤ MAX_CATCHUP กัน backlog สะสมข้าม speed-change (walk 377ms → sprint 152ms). วิธีนี้แก้ slow-motion **เคสทั่วไป** (tick overrun ปานกลาง <150ms) ที่เป็นตัวหลัก; เคส stall รุนแรง (>150ms/tick) ปล่อยให้ A2/B ลดเวลา tick แทน. Full multi-leg loop เก็บไว้ทำทีหลังถ้า load test ชี้ว่า single-commit ไม่พอ

- วัด elapsed จริงต่อ tick แทน dt คงที่ 20ms: `elapsed = now - lastTick`, **clamp ที่ `MAX_CATCHUP`** กัน spiral-of-death หลัง GC pause
- ป้อน `elapsed` เข้า accumulator `stepAccumMs`; **loop commit หลาย leg** ขณะ `stepAccumMs >= legDurationMs` (ปัจจุบัน commit ได้แค่ 1 leg/tick). Loop bounded ด้วย `MAX_SUBSTEPS`
- ทุก substep ต้องผ่าน `applyStep` (validate collision ต่อ tile) — ห้าม fast-path (collision bypass แบบ MF1)
- **[review-fix #5] `ageAutoStopGrace` เรียก "ครั้งเดียวต่อ tick" ด้วย elapsed เต็มที่ clamp แล้ว — ต้องอยู่ *นอก* substep loop** ไม่งั้น aging ซ้ำหลายรอบ → grace 180ms ยุบเหลือเสี้ยว → ยิง stop เร็วผิด
- **[review-fix #2 — HIGH] ต้องเคลียร์ `autoStopPending`/`autoStopGraceMs` แบบ synchronous ตอนรับ intent ใหม่ใน `handleGoto`/`handleInput`** (ปัจจุบันเคลียร์แค่ตอน Phase-2 leg-start ของ tick ถัดไป). เพราะ `MAX_CATCHUP` (เช่น 250ms) > `v2StopGraceMs` (180ms) ได้ → tick ที่ catch-up จะยิง `stopped` ที่ tile เก่า *ก่อน* ที่ walk ใหม่จะ cancel = hitch. เสริม guard: `ageAutoStopGrace` ไม่ยิงถ้า client ได้ intent กลับมาแล้ว (`IsMoving || len(PendingGoto)>0 || InputDX/DY!=0`)
- **[review-fix #3] Multi-leg WASD ต้อง broadcast `moving` "ครั้งเดียว" หลัง loop** ด้วย path หลายจุดรวม + `MoveStartedAt` เดียว (เลียน goto). ปัจจุบัน `broadcastV2Moving` ยิงต่อ leg ([movement_v2.go:580-583](../../../zyra-ws/internal/hub/movement_v2.go)) — ถ้า loop commit ≥2 WASD legs จะยิงหลาย `moving` ที่ `ServerTimeMs` เกือบเท่ากัน → peer teleport (goto ไม่โดนเพราะ `if !hasGoto`)
- **[review-fix #4] เมื่อชน `MAX_SUBSTEPS` ให้ *ทิ้ง* surplus (clamp `stepAccumMs < legDurationMs`) ไม่ carry** — ไม่งั้น backlog สะสมทุก tick = slow-motion กลับมาในรูปแบบใหม่
- **Broadcast cadence คงที่ 20ms** (แยกจาก sim advancement) — *ยกเว้น* WASD moving ที่รวมเป็นก้อนเดียวตาม #3
- **Risk/test:** table-driven ครอบ elapsed=20/60/300/1000ms, leg เดียว/หลาย, ชนกำแพงกลาง substep, goto vs WASD, catch-up + click ใหม่ (ทดสอบ #2), MAX_SUBSTEPS cap (ทดสอบ #4)

**A2. ข้าม client ที่นิ่ง (O(N) → O(active))**
- เก็บ set `activeMovers` ของ client ที่กำลังต้องการ tick; `stepSimulation` วนเฉพาะ set นี้
- **[review-fix #1 — CRITICAL] predicate ต้องรวม `autoStopPending` ด้วย:** `IsMoving || InputDX/DY!=0 || len(PendingGoto)>0 || autoStopPending`. เหตุ: ตอน `closeV2WalkDeferred` arm deferred stop ทุก term อื่นเป็น false → ถ้าไม่รวม `autoStopPending` client จะหลุด set ทันที → `ageAutoStopGrace` ไม่รัน → **deferred `stopped` ไม่เคยยิง → peer ค้างท่าเดินจนกว่า heartbeat 3s (rubber-band)**. ดังนั้น `closeV2WalkDeferred` เป็น *keep-in-set* ไม่ใช่ stop transition; เอาออกจาก set เมื่อ `autoStopPending` เคลียร์ (ยิงแล้ว / cancel / explicit stop)
- อัปเดต set ที่จุด: handleInput / handleGoto / handleStop / leg-start / leg-end / blocked-stop / **closeV2WalkDeferred (keep) + deferred-fire (remove)**
- **[review-fix #7] Safety full-sweep เป็น backstop เท่านั้น** (หลัง predicate ครบตาม #1 แล้ว) — ถ้าเก็บไว้เป็น functional insurance ให้ **สั้นลง ~200–250ms** (ไม่ใช่ 1s ที่ทำให้ค้าง 1 วิ) และตอน sweep re-add ต้อง apply elapsed-since-left เข้า accumulator ให้ถูก

### Phase B — bound & offload fan-out + ลด allocation 🟡 med

**B1. ใช้ buffer ซ้ำใน Subscribers** — เพิ่ม `SubscribersInto(dst []*Client)` เลี่ยง `make([]*Client,0,64)` ทุก call ใน flushMoves (50Hz × movers) → ลด GC jitter. AOI ใช้ RWMutex อยู่แล้ว (read ปลอดภัย)
- **[review-fix #6] buffer ต้องเป็น per-worker (หรือ `sync.Pool`) ไม่ใช่ buffer เดียวแชร์** — มิฉะนั้นชนกับ B2 (workers เขียน dst เดียวกัน = data race/slice corrupt). คง `Subscribers` ตัว alloc เดิมไว้ให้ call site อื่น (`sendNeighborSnapshot` [room.go:819], `applyStep` [movement_v2.go:648]) หรือแจก buffer แยกแต่ละที่

**B2. Fan-out แบบขนาน** — flushMoves ปัจจุบัน serial ต่อ mover. กระจาย movers ไป worker pool เล็ก (bounded ~GOMAXPROCS) แต่ละ worker ทำ `SubscribersInto` (buffer ของตัวเอง ตาม #6) + `SendBin` ของ subset
- ปลอดภัยเพราะ (ยืนยันจาก review): `flushMoves` อ่าน `entry.moved` เป็น **value copy** จาก sync.Map → ไม่ถือ `mover.mu` ระหว่าง fan-out; `peer.SendBin` จับแค่ `sendBinMu` ไม่แตะ `peer.mu` → ไม่ผิดกฎ "ห้ามถือ 2 client mu"; `aoi.Subscribers` = RLock; แต่ละ mover frame stamp/encode โดย worker เดียว + peer มี WritePump เดียว serialize การเขียน → ไม่ reorder
- **[review-fix — rationale] อย่าอ้าง client seq-gate ว่ากัน peer reorder** — seq-gate อ่านเฉพาะ branch own-player ของผู้รับ ([client.go:44-51](../../../zyra-ws/internal/hub/client.go)); peer frames ไม่ได้ใช้ seq. ความปลอดภัย peer มาจาก single-stamp/mover + `sendBinMu` + WritePump เดียว/peer
- **Risk:** ต้อง `-race` (รวม snapshot ticker ทำงานพร้อม flush) + threshold mover ขั้นต่ำที่คุ้มขนาน (mover < X → serial)

**B3. กระจาย snapshot ticker** — แทนที่ 3s burst ทั้งห้อง ให้ทยอยทำ 1/K ของ client ต่อ sub-tick (amortize O(N×neighbors)) ลด spike ที่แย่ง CPU กับ move ticker
- **[review-fix #8] bucket ด้วย stable hash `UserID % K` ไม่ใช่ตำแหน่งใน `clients.Range`** (sync.Map Range order ไม่แน่นอน + เปลี่ยนเมื่อ join/leave → อาจข้าม/ซ้ำ client). sound นอกจากนี้: `sendNeighborSnapshot` idempotent/convergent, joiner ใหม่มี welcome + on-cell-cross snapshot อยู่แล้ว

### Phase C — intra-map tick sharding 🔴 high risk (gate ด้วยผล load test ก่อน)
ทำเฉพาะถ้า Phase A+B ยังไม่พอที่ 1000 คน/map (ดู capacity-scaling §6)
- แบ่ง client ในห้องเป็น S shard (ตาม AOI region — สำคัญเพราะ fan-out เป็น spatial) แต่ละ shard มี tick goroutine ของตัวเอง
- ปัญหาหลัก: mover ใกล้ขอบ shard ต้อง fan-out ข้ามไป shard เพื่อนบ้าน → AOI ต้อง shard-aware หรือใช้ read-only AOI snapshot ต่อ tick
- **Risk สูงมาก** (concurrency: shared maps/AOI/locking discipline "ห้ามถือ 2 client mu พร้อมกัน"). **ต้อง**: design doc แยก + load test + `-race` เข้ม
- **Alternative:** ถ้า 1000/map เป็น event นานๆครั้ง อาจเลือก cap ที่ tier ต่ำกว่า + พึ่ง Phase A+B แทนความซับซ้อนของ C

---

## 5. Rollout & Safety

- **Flag-gate ทุก phase** (env, เช่น `VO_TICK_REALTIME_DT`, `VO_TICK_ACTIVE_SET`, `VO_TICK_PARALLEL_FANOUT`) → เปิดทีละตัว, rollback = ปิด flag
- Internal-only: **ไม่มี protocol/DB change** → deploy zyra-ws ได้อิสระ ไม่ต้อง sync กับ app pipeline
- ลำดับ deploy: preview → staging (load test) → prod (`v*` tag, ดู [prod-vm-deploy]) ทีละ phase, เฝ้า metrics Phase 0

---

## 6. PR Breakdown (แต่ละอันจบใน 1 PR ตาม rule 01-plan)

1. `feat(ws): tick observability metrics` (Phase 0) — **ต้องมาก่อน**
2. `perf(ws): real-elapsed dt with catch-up cap` (A1) + table-driven tests
3. `perf(ws): active-mover set to skip idle clients` (A2) + safety full-sweep + tests
4. `perf(ws): reuse Subscribers buffer (SubscribersInto)` (B1)
5. `perf(ws): parallel fan-out worker pool` (B2) + `-race` tests
6. `perf(ws): staggered neighbor-snapshot ticker` (B3)
7. *(evidence-gated, design doc แยก)* `feat(ws): intra-map tick sharding` (C)

---

## 7. ความเสี่ยง & ผู้ต้องตัดสินใจ (Open questions)

> **ค่าคงที่จริงที่ต้องคำนวณ trade-off ด้วย (ไม่ใช่ placeholder):** leg duration = **orthogonal ~267ms**, **diagonal ~377ms**, **sprint ~152ms** ([message.go:1235-1237](../../../zyra-ws/internal/hub/message.go)); `v2StopGraceMs = 180ms`.

| หัวข้อ | ต้องตัดสินใจ |
|---|---|
| `MAX_CATCHUP` (spiral guard) | ต้องสัมพันธ์กับ `v2StopGraceMs=180` และ diagonal leg 377ms. **ถ้า MAX_CATCHUP > 180 ต้องมี review-fix #2 (clear autoStopPending sync) ก่อน**; MAX_CATCHUP < 377 = catch-up leg เดียวจาก cold start ยังไม่ครบ |
| `MAX_SUBSTEPS` ต่อ tick | 2–4? เลือกเทียบกับ leg durations จริงข้างบน; surplus ทิ้ง (review-fix #4) |
| Worker pool size (B2) | GOMAXPROCS-based? threshold mover ขั้นต่ำที่คุ้มขนาน; buffer per-worker (review-fix #6) |
| active-set safety sweep interval (A2) | ~200–250ms (ไม่ใช่ 1s — review-fix #7); predicate ต้องรวม `autoStopPending` (review-fix #1) |
| Phase C ทำไหม | รอผล load test A+B ที่ 1000 คน ก่อน |

> **หมายเหตุ:** แผนนี้ผ่าน adversarial review รอบหนึ่งแล้ว (2026-07-24) — พบ 1 Critical (A2 orphaned deferred-stop) + 1 High (A1 stale deferred-stop) + 6 med/low ซึ่ง fold เข้าเป็น `[review-fix #n]` ในแต่ละ phase แล้ว. ควร re-review อีกครั้งตอน implement จริงแต่ละ PR

---

## 8. Load-test plan (Verification)

อาการนี้ **load-only** — ต้องมี synthetic WS client harness:
- N client (100 / 500 / 1000) ในห้องเดียว, mix idle/WASD-walk/click-move, บางส่วนกระจุกใน AOI cell เดียว (worst case fan-out)
- วัด (จาก Phase 0 metrics): tick p95 duration, dropped-tick, effective sim Hz, **force_sync rate ต่อ client** (ตัวชี้ rubber-band), CPU/goroutine
- อ้างอิง [VO-Movement-V2/staging-soak-checklist.md](../VO-Movement-V2/staging-soak-checklist.md) + [prod-db tunnel] สำหรับดู state จริง

**Definition of Done (ทั้ง overhaul):** ที่ target CCU — effective sim Hz ≥ ~45Hz (จากที่ตกลงตอน overrun), tick p95 < 20ms, **force_sync rate แบนเมื่อ N โต** (ไม่พุ่ง), `go test -race ./...` ผ่าน, ไม่มี regression ใน soak checklist

---

## 9. หมายเหตุความสอดคล้อง

- Phase A1/A2 ทำ **ก่อน** และคาดว่าให้ผลมากสุดต่อความเสี่ยงต่ำสุด — แนะนำหยุดประเมินหลัง A+B ก่อนตัดสินใจ Phase C
- ทุก substep คง `applyStep` validation — อย่าเปิดช่อง collision bypass ซ้ำรอย MF1
- Fan-out ขนานพึ่ง `sendBinMu` (MF4) + client seq-gate (Phase 3) ที่มีแล้ว — เป็นเหตุผลว่าทำไม B2 ปลอดภัยกว่าถ้าทำ *หลัง* งานชุด 2026-07-24
