# Test ของ pet AI (pop 5 นาที) flaky — ล้มประมาณ 2 ใน 12 รอบ

> สถานะ: **แก้ครบ 3 ตัว merge เข้า develop 2026-09-09** (`zyra-ws` PR #61 → `200ae39` · PR #63 → `21bc205`) — verify ด้วยการรัน test ซ้ำ ยังไม่ต้อง live-verify (เป็น test-only, production เป็น no-op)
> กระทบ: `zyra-ws` เท่านั้น — `internal/hub/pets.go`, `internal/hub/pets_test.go`
> อาการที่รายงาน: `go test ./internal/hub/ -count=1` บน `develop` ที่ tree สะอาด ล้ม **~2 ใน 12 รอบ** ทุกครั้งที่ test เดิมคือ `TestPetAttention_TimesOutAfterFiveMinutesAndWalksAway` — ไม่ได้เกิดจากงานรอบไหนเป็นพิเศษ
> รอบที่ 2 (สแกนต่อ) เจออีก 2 ตัวที่ flaky น้อยกว่าแต่คนละสาเหตุ — ดู [รอบที่ 2](#รอบที่-2--2026-09-09--สแกนหา-flaky-ที่เหลือ) ท้ายไฟล์

---

## Root cause

test นี้เป็น regression test ของกฎ "pop อยู่ได้นานสุด 5 นาทีแล้วหาย แล้ว pet เดินออกมา"
(user 2026-09-07) แบ่งเป็น 3 ช่วง:

1. คนยืนข้าง pet → `pet.attention` จับที่คนนั้น
2. ผ่าน `petPopMaxDuration` (5 นาที) → attention ว่าง + จำไว้ใน `pet.ignored` แล้วเดินหนี
3. คนนั้น **ขยับ** → ignore ถูกล้าง แล้ว pet หันมาสนใจใหม่

ช่วงที่ 3 คือที่ล้ม (บรรทัด 1590 ทุกครั้ง — `assert.Equal([]string{"u1"}, pet.attention)`)

pet AI ตัดสินใจเดินเล่น/เล่นสนุกด้วย `rand` ที่ share ทั้ง process:

| ค่า | ไฟล์ | ความหมาย |
|---|---|---|
| `petWanderChance = 0.5` | `zyra-ws/internal/hub/pets.go` | ครึ่งหนึ่งของ decision = ออกเดิน |
| `petHappyRunChance = 0.10` | เดียวกัน | pet อารมณ์ดีวิ่งข้ามห้อง |
| `petHappyTailChaseChance = 0.05` | เดียวกัน | วิ่งไล่หางตัวเองรอบ 2×2 |

ตัว test เอง **บังคับ `restUntil` ให้หมดอายุทุก tick** เพื่อให้ pet ตัดสินใจได้ทุกครั้ง —
เท่ากับเปิดโอกาสให้ roll ทุก tick ด้วย

ลำดับเหตุการณ์ที่ทำให้ล้ม:

1. หลัง timeout test เดิน pet ออกไป 40 tick (tick ละ 200 ms) ในห้องขนาด **30×12**
2. แล้วค่อยวางคนที่ "ขยับ" ไว้ที่ tile ข้าง ๆ **ตำแหน่งที่ pet บังเอิญไปหยุด** (`pet.x + 1`)
3. แต่ pet ยัง roll wander ได้อีก 20 tick ถัดมา — `petStepMs = 900` ms ต่อ tile
   เดินได้อีกหลาย tile ก่อนที่ loop จะหมด
4. ถ้าเดินไกลเกิน `petNoticeRadius = 3` จาก tile ที่ตรึงคนไว้ → ไม่มีวันเห็นคนนั้นอีก →
   `pet.attention` ว่างจนจบ loop → assert ล้ม

พูดอีกแบบ: assertion ผูกกับ **ตำแหน่ง tile ที่งอกจากการสุ่ม** ไม่ใช่ state ที่กฎนิยามไว้

---

## สิ่งที่แก้ (`zyra-ws` PR #61)

### 1. แยก source ของ randomness ออกมาให้ pin ได้ — `internal/hub/pets.go`

เพิ่ม field `jitter petJitter` บน `petAI` และ helper `p.roll()` / `p.pick(n)`
แทนที่ call site ของ `rand.Float64()` / `rand.Intn()` ทั้ง 5 จุดใน pet AI

- `jitter == nil` = pet ทุกตัวใน production → ตกไปใช้ `rand` ตัวเดิม **พฤติกรรมจริงไม่เปลี่ยนเลย**
- ทำเป็น **field ต่อ pet** ไม่ใช่ package-level var ตั้งใจ เพราะ hub test อื่นมี room ที่ tick
  ใน goroutine อยู่ — ถ้า swap ตัวแปร global กลางคัน `-race` จะจับได้

### 2. pin jitter ใน test + ย่อห้องให้เล็กลง — `internal/hub/pets_test.go`

```go
type pinnedJitter struct{}

func (pinnedJitter) Float64() float64 { return 1 } // สูงกว่าทุก chance → ไม่เดินเอง
func (pinnedJitter) Intn(int) int     { return 0 } // เลือก candidate tile ตัวแรกเสมอ
```

เหลือการเดินเฉพาะที่พฤติกรรมภายใต้การทดสอบสั่งเท่านั้น

พร้อมกันนั้นย่อห้องจาก **30×12 → 4×4** เพื่อให้ tile ที่ pet เดินหนีไป **ยังอยู่ในรัศมี
`petNoticeRadius` ของคนที่ AFK** — สิ่งที่กันไม่ให้ pet หันกลับมาจึงต้องเป็น `pet.ignored` จริง ๆ
ไม่ใช่ระยะทาง (ของเดิมสุ่มได้ทั้งสองแบบ) แล้ว assert ทั้งสองข้อนั้นออกมาตรง ๆ:

```go
assert.NotEqual(t, [2]int{5, 5}, [2]int{pet.x, pet.y}, "it walked off the tile ...")
require.LessOrEqual(t, chebyshev(pet.x, pet.y, 6, 5), petNoticeRadius, "still close enough ...")
```

---

## Before/After

| Metric | Before | After | Δ |
|---|---|---|---|
| `go test ./internal/hub/ -count=1` รอบที่ล้ม | **2 / 12** (≈17%) | **0 / 25** | −100% |
| test ที่ล้ม | `TestPetAttention_TimesOutAfterFiveMinutesAndWalksAway` บรรทัด 1590 ทุกครั้ง | — | — |
| assertion ที่ผูกกับตำแหน่งจากการสุ่ม | 1 (`pet.x + 1`) | 0 (ตำแหน่ง deterministic + assert รัศมีตรง ๆ) | — |

**วัดยังไง**: รัน `go test ./internal/hub/ -count=1` ใน loop แล้วนับ exit code ที่ไม่ใช่ 0
before วัดบน `develop` ที่ tree สะอาด (12 รอบ) · after วัดบน branch `fix/pet-ai-test-jitter` (25 รอบ)
**ช่วงเวลาที่วัด**: 2026-09-09 ทั้งสองชุด บนเครื่อง dev เดียวกัน

ตรวจเพิ่ม:

- `go test ./... -count=1` เขียวทั้ง repo · `go test ./internal/hub/ -race` เขียว · `go vet` สะอาด
- **mutation check** — ปิด branch `petPopMaxDuration` ใน `pets.go` ชั่วคราว test ยังล้มเหมือนเดิม
  (บรรทัด 1584/1585/1592) แปลว่า test ไม่ได้ถูกทำให้ "ผ่านลอย ๆ"

---

## บทเรียน

1. **AI ที่มี randomness ต้องมีทางให้ test pin ได้ตั้งแต่แรก** — `zyra-ws/internal/hub/pets.go`
   มี chance-based decision อยู่ 6 จุด (`petWanderChance`, `petHappyRunChance`,
   `petHappyTailChaseChance`, `petSadWanderChance`, `petVisitChance` และการสุ่ม tile
   ใน `pickWanderTarget`) ตอนนี้ทุกจุดผ่าน `p.roll()` / `p.pick()` แล้ว test ใหม่ที่ต้อง
   deterministic ใส่ `pet.jitter = pinnedJitter{}` ได้เลย
2. **อย่า assert ตำแหน่ง tile ที่งอกจากพฤติกรรมสุ่ม** — assert state ที่กฎนิยามไว้แทน
   (`pet.attention` / `pet.ignored`) แบบเดียวกับ `TestPetStep_DoesNotApproachABusyResidentFromAcrossTheRoom`
   ที่ตรึง zone ให้เท่ากับ tile ของ pet เองเพื่อตัดสาขา wander ออกไป
3. **flaky test ที่ปล่อยไว้ = CI ที่ไม่มีใครเชื่อ** — 17% ต่อรอบ แปลว่าเจอเกือบทุกวัน
   และคนจะเริ่ม re-run จนติดนิสัย

---

## รอบที่ 2 — 2026-09-09 — สแกนหา flaky ที่เหลือ

ปิดตัวแรกแล้วสแกนต่อว่า pet AI ยังมี test ไหน flaky อีก — **เจออีก 2 ตัว**
แก้ใน `zyra-ws` PR #63 → `21bc205` (ไม่แตะ production code เลย)

### วิธีสแกน

รัน binary ที่ compile ไว้ซ้ำ ๆ แล้วนับชื่อ test ที่ล้ม แทนการรัน `go test` ปกติ (เร็วกว่ามาก):

```bash
go test -c -o /tmp/hub.test ./internal/hub/
for i in $(seq 1 150); do /tmp/hub.test -test.run 'Pet|pet' 2>&1 | grep -E '^--- FAIL'; done \
  | sed 's/ (.*//' | sort | uniq -c | sort -rn
```

ตัวที่ล้มน้อยกว่า 1% หาแบบนี้ไม่เจอในเวลาที่รับได้ (600 รอบยังได้ 0 ครั้ง) เลยเขียน
**harness ชั่วคราว** ในแพ็กเกจเดียวกัน รัน loop ของ test นั้น **3000 ครั้ง** แล้วพิมพ์
min / p50 / p99 / max ของตัวเลขที่ assertion ใช้ออกมาดูตรง ๆ — วิธีนี้บอกได้ทั้ง
**อัตราล้มจริง** และ **margin ห่างจากเพดานกี่ σ** ซึ่งเดาเอาไม่ได้
(harness เป็นไฟล์ชั่วคราว ลบทิ้งหลังวัดเสร็จ ไม่ได้ commit)

> วิธีสแกน วิธีวัด margin และผลสแกน repo อื่น ย้ายไปอยู่ที่
> [`guides/flaky-test-hunting.md`](../guides/flaky-test-hunting.md) แล้ว — ใช้ซ้ำได้กับทุก Go repo

### สิ่งที่เจอ — สาเหตุเดียวกันทั้งคู่ และไม่ใช่เรื่อง seed

ทั้งสอง test **นับทุก tick ที่ pet ขยับ** ซึ่งเท่ากับวัด *ความยาวเส้นทาง*
ไม่ใช่ *ความถี่ที่ pet ตัดสินใจ* เดิน/วิ่ง — การวิ่งข้ามห้องกินหลาย tile และ sad shuffle
ก็หลาย tile เลข step จึงไต่ขึ้นไปชนเพดานที่ตั้งไว้สำหรับ "decision"
(comment ในโค้ดเขียนว่า *"over many decisions"* อยู่แล้ว — assertion วัดผิดตัวมาตลอด)

| Test | Assertion ที่ล้ม | การกระจายตัวที่วัดได้ (3000 รอบ) | อัตราล้ม |
|---|---|---|---|
| `TestPetStep_HappyPetSometimesRunsOrChasesItsTail` | `walks > runs` | walks p50 **183** vs runs p50 **66** — หางชนกัน | **22 / 3000** (0.73%) |
| `TestPetStep_SadPetOnlyShufflesSlowly` | `walks < 200` | p50 **142** · p99 186 · max **210** | **3 / 3000** (0.1%) |

ตัว happy ยังวัดได้ `runs: min = 0` ด้วย แปลว่า `runs > 0` ก็ล้มได้เหมือนกัน

**ปัญหาซ้อนของตัว happy**: ส่ง `players` เป็น `nil` → `p.lastSeenOccupied` ไม่เคยถูกรีเฟรช →
AI หยุดตัดสินใจหลัง `petIdleRoomAfter` (5 นาที = 300 iteration) ทั้งที่ loop เขียนไว้ 600
เท่ากับได้ sample แค่ ~30 decision ซึ่งเป็นเหตุผลจริง ๆ ที่ margin เหลือแค่ ~2.5σ

### สิ่งที่แก้

ข้าม tick ที่อยู่ระหว่างเดิน (`len(pet.path) > 0`) แล้วนับเฉพาะ decision ที่ **เริ่ม** เดิน

- **sad** — เปลี่ยนไป assert *สัดส่วน* ของ decision ที่เดิน (`4*walks < decisions` = ต่ำกว่า 25%)
  แทนเลข step ที่ไม่มีความหมายอีกแล้ว ส่วนการเช็ค pace (`petSadStepMs` ห้ามวิ่ง) ยังเช็คทุก tick เหมือนเดิม
- **happy** — เพิ่มคนยืนมุมห้อง 1 คนที่ **ไม่ใช่ resident** (`isResident` = false → ไม่มี attention,
  ไม่มี pop, ไม่มีการเดินไปหา) เพื่อให้ห้อง "มีคน" AI จึงไม่ idle out แล้วขยาย loop เป็น 6000 tick
  ได้ sample ใหญ่พอจริง

### Before/After (รอบที่ 2)

| Metric | Before | After | Δ |
|---|---|---|---|
| `TestPetStep_HappyPetSometimesRunsOrChasesItsTail` ล้ม | **22 / 3000** (0.73%) | **0 / 3000** | −100% |
| `TestPetStep_SadPetOnlyShufflesSlowly` ล้ม | **3 / 3000** (0.1%) | **0 / 3000** | −100% |
| margin ของ happy (walks vs runs) | ~2.5σ (walks p50 183 / runs p50 66) | ~15σ — runs **110–187** vs walks **377–466** | — |
| margin ของ sad (walk share) | max 210 ชนเพดาน 200 | worst **8%** ของ decision (เพดาน 25%) | — |

**วัดยังไง**: harness ชั่วคราวรัน loop ของแต่ละ test 3000 รอบ นับครั้งที่ assertion ถูกละเมิด
**ช่วงเวลาที่วัด**: 2026-09-09 before วัดบน `develop` (`200ae39`) · after วัดบน branch `fix/pet-ai-statistical-test-flakes` เครื่องเดียวกัน

ตรวจเพิ่มหลังแก้: pet tests **400 รอบ** + ทั้ง package `internal/hub` **150 รอบ** = ล้ม **0** ·
`-race` เขียว · `go vet` สะอาด

### สรุป flaky ทั้งชุด

| Test | อัตราล้ม (before) | สาเหตุ | แก้ที่ |
|---|---|---|---|
| `TestPetAttention_TimesOutAfterFiveMinutesAndWalksAway` | 2 / 12 (17%) | assert ตำแหน่ง tile ที่งอกจาก `rand` | PR #61 → `200ae39` |
| `TestPetStep_HappyPetSometimesRunsOrChasesItsTail` | 22 / 3000 (0.73%) | นับ step แทน decision + sample เล็กเพราะ AI idle out | PR #63 → `21bc205` |
| `TestPetStep_SadPetOnlyShufflesSlowly` | 3 / 3000 (0.1%) | นับ step แทน decision | PR #63 → `21bc205` |

### บทเรียนเพิ่ม (รอบที่ 2)

4. **flaky ไม่ได้แปลว่าต้อง pin randomness เสมอ** — สองตัวนี้ pin ไม่ช่วย เพราะ assertion
   วัดผิดตัวตั้งแต่แรก (นับ step ที่ตั้งใจจะนับ decision) การ pin จะกลบอาการโดยที่ test
   ยังพิสูจน์ผิดเรื่องอยู่ดี
5. **statistical test ต้องรู้ว่า margin ห่างกี่ σ** — ถ้าตอบไม่ได้ว่าเพดานอยู่ห่างจาก
   p50 เท่าไร แปลว่ายังไม่รู้ว่ามันจะล้มบ่อยแค่ไหน วัดด้วย harness 3000 รอบใช้เวลาไม่ถึงนาที
6. **ระวัง gate ที่ตัด loop ทิ้งเงียบ ๆ** — `petIdleRoomAfter` ทำให้ครึ่งหลังของ loop 600 tick
   ไม่ได้ทำอะไรเลยโดยไม่มีใครรู้ ถ้า test เดินเวลาจำลองยาว ๆ ต้องเช็คว่า production gate
   ตัวไหนจะเตะเข้ามาระหว่างทางบ้าง
