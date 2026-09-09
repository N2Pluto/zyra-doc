# ล่า flaky test — วิธีสแกน วัดผล และผลที่สแกนไปแล้ว

> เริ่มเขียน 2026-09-09 · กระทบทุก Go repo (`zyra-api`, `zyra-ws`, `zyra-notifications`) · เคสจริงที่มาของเอกสารนี้อยู่ที่ [`issues/pet-ai-flaky-pop-timeout-test-2026-09-09.md`](../issues/pet-ai-flaky-pop-timeout-test-2026-09-09.md)

flaky test คือ test ที่ผ่านบ้างล้มบ้างโดยที่โค้ดไม่เปลี่ยน ปัญหาไม่ใช่แค่ CI แดง
แต่คือ**คนเลิกเชื่อ CI** แล้วกด re-run จนติดนิสัย — พอของจริงพังจะไม่มีใครดู

เอกสารนี้เก็บ 3 อย่าง: **วิธีหา** · **วิธีวัดว่าล้มบ่อยแค่ไหน** · **สแกนไปถึงไหนแล้ว**

---

## 1. วิธีหา — compile ครั้งเดียว แล้ววนรัน binary

`go test` ซ้ำ ๆ ช้าเพราะ build/cache ทุกครั้ง วิธีที่เร็วกว่ามากคือ compile เป็น binary
แล้ววนรันตัวนั้น:

```bash
go test -c -o /tmp/hub.test ./internal/hub/
for i in $(seq 1 150); do /tmp/hub.test 2>&1 | grep -E '^--- FAIL'; done \
  | sed 's/ (.*//' | sort | uniq -c | sort -rn
```

ได้ผลออกมาเป็นตารางว่า test ตัวไหนล้มกี่ครั้งจากกี่รอบ

**สแกนทั้ง repo หลาย package พร้อมกัน** — compile ทีละ package แล้วยิงขนานกัน
(CPU contention ยิ่งช่วยดึง flake ที่ไวต่อ timing ออกมา ซึ่งตรงกับสภาพ CI จริง):

```bash
for p in cache config handler model rbac router service; do
  go test -c -o /tmp/api-$p.test ./internal/$p/
done
for p in cache config handler model rbac router service; do
  ( cd internal/$p && for i in $(seq 1 100); do
      /tmp/api-$p.test >/dev/null 2>&1 || echo "$p FAIL"
    done ) &
done; wait
```

> ⚠️ **ต้อง `cd` เข้าโฟลเดอร์ของ package ก่อนรัน binary เสมอ**
> `go test` ตั้ง CWD ให้เป็นโฟลเดอร์ package อัตโนมัติ แต่การรัน binary ตรง ๆ ไม่ตั้งให้
> test ที่อ่านไฟล์ด้วย relative path จะล้มทันทีและดูเหมือน flaky ทั้งที่ไม่ใช่
> — เจอจริงกับ `TestSectionLockOrderInvariant` (`zyra-api/internal/service/zone_section_service_test.go`)
> ที่อ่าน `os.ReadFile("zone_section_service.go")` เพื่อตรวจ lock order จาก source
> รันผิด CWD → ล้ม 12/100 · รันถูก → ล้ม 0/100

---

## 2. วิธีวัด — harness ชั่วคราวสำหรับ test เชิงสถิติ

test ที่ล้มต่ำกว่า ~1% หาด้วยการวนรันไม่คุ้ม (600 รอบยังได้ 0 ครั้งก็มี) และที่แย่กว่าคือ
**รู้แค่ว่า "นาน ๆ ล้มที" ไม่ได้บอกว่ามัน margin ห่างแค่ไหน**

วิธีที่ใช้ได้ผล: เขียนไฟล์ `_test.go` ชั่วคราวในแพ็กเกจเดียวกัน ก๊อป loop ของ test นั้นมา
รัน **3000 รอบ** แล้วพิมพ์ min / p50 / p99 / max ของ**ตัวเลขที่ assertion ใช้จริง**

```go
// zz_flakescan_test.go — ชั่วคราว ลบทิ้งหลังวัดเสร็จ ห้าม commit
func TestZZScan(t *testing.T) {
	var got []int
	for n := 0; n < 3000; n++ {
		// ...ก๊อป loop ของ test มาทั้งดุ้น เก็บตัวเลขที่ assert ใส่ got...
	}
	sort.Ints(got)
	fmt.Printf("min=%d p50=%d p99=%d max=%d\n",
		got[0], got[len(got)/2], got[len(got)*99/100], got[len(got)-1])
}
```

ได้คำตอบ 2 อย่างที่เดาเอาไม่ได้: **อัตราล้มจริง** และ **เพดานห่างจาก p50 กี่ σ**

**เกณฑ์ที่ใช้**: ถ้าเพดานห่างน้อยกว่า ~5σ ถือว่ายังไม่ปลอดภัย — ของจริงที่เจอมา
2.5σ = ล้ม 0.73% (เจอเกือบทุกวันถ้า CI รันวันละหลายรอบ)

---

## 3. สาเหตุที่เจอจริง (เรียงตามที่เจอบ่อย)

| สาเหตุ | อาการ | วิธีแก้ที่ใช้ |
|---|---|---|
| assert ตำแหน่ง/ผลลัพธ์ที่**งอกจาก `rand`** | ล้มเป็นช่วง ๆ ไม่มีแพตเทิร์น | assert **state ที่กฎนิยามไว้** แทน หรือ inject randomness ให้ pin ได้ |
| **นับผิดหน่วย** — นับ tick/step ทั้งที่ตั้งใจนับ decision | ตัวเลขไต่ไปชนเพดานที่ตั้งไว้คนละหน่วย | ข้าม tick ที่เป็นผลพวง นับเฉพาะครั้งที่ "ตัดสินใจ" |
| **sample เล็กเกินไป** เพราะมี gate ตัด loop เงียบ ๆ | margin แคบผิดคาด | หา gate ที่เตะเข้ามา (เช่น idle timeout) แล้วกันไว้ ก่อนขยายจำนวนรอบ |
| relative path / CWD | ล้ม 100% เมื่อรันนอก `go test` | ไม่ใช่ flake — แก้ที่วิธีรัน |
| `time.Sleep` margin แคบ | ล้มเฉพาะตอนเครื่องโหลด | stress ใต้ CPU load เพื่อยืนยัน แล้วขยาย margin ถ้าจำเป็น |

**ข้อสำคัญ**: flaky **ไม่ได้แปลว่าต้อง pin randomness เสมอ** — 2 ใน 3 เคสของ pet AI
pin ไปก็แค่กลบอาการ เพราะ assertion วัดผิดหน่วยตั้งแต่แรก ต้องแก้ที่การวัด

---

## 4. สแกนไปถึงไหนแล้ว

| Repo / package | วันที่ | จำนวนรอบ | ผล |
|---|---|---|---|
| `zyra-ws` `internal/hub` | 2026-09-09 | 150 (pet) + 120 (ทั้ง package) + harness 3000×2 | **เจอ 3 ตัว** — แก้แล้ว (PR #61, #63) ดู [issues](../issues/pet-ai-flaky-pop-timeout-test-2026-09-09.md) |
| `zyra-ws` `internal/hub` (หลังแก้) | 2026-09-09 | 400 (pet) + 150 (ทั้ง package) + `-race` | ล้ม **0** |
| `zyra-api` ทุก package | 2026-09-09 (`4233fbd`) | 100 รอบ × 7 package + `-race` 12 + full 30 | ล้ม **0** — ไม่เจออะไรเลย |
| `zyra-api` `internal/service` ใต้ CPU load | 2026-09-09 | 240 (6 process ขนาน × 40) | ล้ม **0** |
| `zyra-ws` package อื่น (`internal/store` ฯลฯ) | — | — | **ยังไม่ได้สแกน** |
| `zyra-notifications` | — | — | **ยังไม่ได้สแกน** |
| `zyra-app` (vitest) | — | — | **ยังไม่ได้สแกน** |

### ทำไม zyra-api ถึงสะอาด

- **ไม่มี `math/rand` ในไฟล์ test เลยสักไฟล์** — ซึ่งเป็นต้นตอของเคสแรกใน zyra-ws
- `time.Sleep` มีที่เดียวคือ `internal/service/obstacle_debounce_test.go` (debounce ที่ทดสอบ
  `time.AfterFunc` จริง margin 40 ms) — stress ใต้ load 240 รอบแล้วยังไม่ล้ม
- `t.Parallel` 13 จุดอยู่ใน `pet_service_test.go` ซึ่งเป็น pure function ล้วน ไม่มี shared state
- goroutine ในไฟล์ test มีแค่ 2 จุด

---

## 5. เช็กลิสต์ก่อนบอกว่า "แก้ flaky แล้ว"

- [ ] รู้ **อัตราล้มก่อนแก้** เป็นตัวเลข (x / n รอบ) ไม่ใช่ "นาน ๆ ที"
- [ ] รู้ **สาเหตุจริง** ไม่ใช่แค่ทำให้ผ่าน — pin seed ที่กลบอาการไม่นับ
- [ ] test ยัง**จับ regression เดิมได้อยู่** — พิสูจน์ด้วย mutation check: ปิด branch ที่ test คุ้มอยู่ชั่วคราว แล้วดูว่า test ล้มจริง
- [ ] รันซ้ำอย่างน้อย **20 รอบ** (statistical test ให้วัดด้วย harness แทน)
- [ ] `-race` เขียว
- [ ] ลบไฟล์ harness ชั่วคราวออกก่อน commit
