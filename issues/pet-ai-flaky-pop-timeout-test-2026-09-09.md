# Test ของ pet AI (pop 5 นาที) flaky — ล้มประมาณ 2 ใน 12 รอบ

> สถานะ: **แก้แล้ว merge เข้า develop 2026-09-09** (`zyra-ws` PR #61 → `200ae39`) — verify ด้วยการรัน test ซ้ำ 25 รอบ ยังไม่ต้อง live-verify (เป็น test-only, production เป็น no-op)
> กระทบ: `zyra-ws` เท่านั้น — `internal/hub/pets.go`, `internal/hub/pets_test.go`
> อาการที่รายงาน: `go test ./internal/hub/ -count=1` บน `develop` ที่ tree สะอาด ล้ม **~2 ใน 12 รอบ** ทุกครั้งที่ test เดิมคือ `TestPetAttention_TimesOutAfterFiveMinutesAndWalksAway` — ไม่ได้เกิดจากงานรอบไหนเป็นพิเศษ

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
