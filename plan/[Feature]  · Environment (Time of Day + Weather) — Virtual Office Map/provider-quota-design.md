# ออกแบบ: ไม่ยิง provider ซ้ำในพื้นที่ที่รู้คำตอบแล้ว

> **สถานะ:** ข้อเสนอ ยังไม่ implement · **วันที่:** 2026-09-10 · **repo ที่กระทบ:** `zyra-api`
> เขียนหลังพบว่า dev ยิง Google รับ 404 ทุก 15 นาทีต่อ cell โดยไม่มีวันได้คำตอบอื่น

## TL;DR

ชั้น cache ที่ออกแบบไว้ **ทำงานถูกต้องอยู่แล้วเกือบทั้งหมด** — แบ่งพื้นที่เป็น cell 0.25° (~28 กม.) ใช้ร่วมกันทุก workspace ในเมืองเดียวกัน · single-flight · fallback ค่าเก่า · soft cap รายเดือน

รูอยู่ที่จุดเดียว: **ระบบไม่จำคำตอบว่า "ที่นี่ไม่มีข้อมูล"** พอ provider ตอบ 404 ระบบอ่านว่า "ล่มชั่วคราว" แล้วถามใหม่ทุก 15 นาที ตลอดไป

**1 cell ของไทย = 2,880 call/เดือน = 30% ของโควตาฟรี ทิ้งเปล่า 100%**

---

## 1. ของที่มีอยู่แล้ว (อย่าออกแบบซ้ำ)

| กลไก | ที่อยู่ | ทำอะไร |
|---|---|---|
| **แบ่ง cell** | `cache.WeatherCellDegrees = 0.25` | ปัดพิกัดเป็นตาราง ~28 กม. ⇒ ทุก workspace ในกรุงเทพใช้ call เดียวกัน |
| **cache ร้อน** | `env:wx:<cell>` (Redis) TTL 60 นาที | `WeatherCacheTTL` — ตรงกับรอบ refresh ของ HP-03 |
| **cache ถาวร** | `tb_environment_snapshot` | รอด Redis restart · เสิร์ฟเป็น "stale" ได้ ≤ 3 ชม. (`WeatherStaleMax`) |
| **single-flight** | `AcquireFetchLock(cell)` TTL 20 วิ | คนที่สองไม่ยิงซ้ำ ได้ค่าเก่าไปก่อน |
| **ล็อกต่อ cell (alert)** | `AcquirePollerLock("alerts:"+cell)` 15 นาที | ทั้ง cluster ยิง cell ละครั้งต่อรอบ |
| **soft cap** | `GoogleMonthlySoftCap = 9500` | 95% ของโควตาฟรี 10,000 — หยุดเองก่อนโดนบิล |
| **ตารางความครอบคลุมรายประเทศ** | `environment_coverage.go` | กันไม่ให้ยิงประเทศที่รู้อยู่แล้วว่าไม่มีข้อมูล — **ต้นทุน 0** |

**ต้นทุนต่อ cell ต่อเดือน ตามที่ตั้งไว้ตอนนี้**

| งาน | รอบ | call/เดือน/cell |
|---|---|---|
| weather | 60 นาที | **720** |
| alert (per-point) | 15 นาที | **2,880** ← แพงกว่า weather 4 เท่า |

โควตาฟรี 10,000/เดือน ⇒ ถ้านับเฉพาะ weather จะได้ ~13 cell ตามที่คอมเมนต์ในโค้ดเขียนไว้ แต่ **พอรวม alert เข้าไป 1 cell กิน 3,600** เหลือที่ให้แค่ **2 เมือง**

---

## 2. รูที่เจอจริง (มีหลักฐาน)

### 2.1 ตารางความครอบคลุมบอกว่าไทยมี Google alert — แต่ไม่มี

`environment_coverage.go` เขียน `googleAlertCountries{"TH": true, ...}` พร้อมคอมเมนต์ว่าเป็น "รายชื่อที่ **CONFIRMED** แล้ว" — แต่ confirm มาจาก**การอ่านตาราง coverage ของ Google** ไม่ใช่การยิงจริง

ยิงจริงด้วย key ของเราเมื่อ 2026-09-10:

| พิกัด | `publicAlerts:lookup` |
|---|---|
| กรุงเทพ · เชียงใหม่ · ภูเก็ต · ขอนแก่น | **404 NOT_FOUND** ทั้งหมด — *"Information is not supported for this location"* |
| Miami US · Tokyo JP · Berlin DE · Sydney AU · Singapore SG · Manila PH | **200** พร้อม `alerts: []` |
| Hanoi VN · Jakarta ID · KL MY · Phnom Penh KH | **404 NOT_FOUND** |

`200 + []` (ครอบคลุม แต่ตอนนี้ไม่มีประกาศ) ต่างจาก `404` (ไม่ครอบคลุมเลย) อย่างชัดเจน
⇒ **TH ต้องออกจาก `googleAlertCountries`** และ VN ก็ผิดด้วย (อยู่ในลิสต์แต่ตอบ 404)

### 2.2 ทุก non-200 กลายเป็น "ล่มชั่วคราว"

`environment_google_alerts.go`:

```go
if resp.StatusCode != http.StatusOK {
    slog.Warn("environment: google alerts returned an error status", "status", resp.StatusCode)
    return nil, ErrProviderUnavailable      // ← 404 ก็มาทางนี้
}
```

`ErrProviderUnavailable` แปลว่า "ลองใหม่รอบหน้า" ส่วน `ErrProviderNoCoverage` แปลว่า "ไม่ต้องลองอีก" — **404 ถูกจัดผิดกล่อง**

ผลที่เห็นใน log ของ dev ทุก 5 นาที:

```
WARN environment: google alerts returned an error status status=404
WARN environment: per-point alert poll failed cell=13.75:100.50 country=TH
                  error="weather provider unavailable"
```

### 2.3 ระบบไม่เรียนรู้จากคำตอบเลย

ความรู้เรื่องความครอบคลุมมีแหล่งเดียวคือ**ตารางที่คนเขียนมือ** พอ provider ตอบ 404 ระบบไม่ได้จำอะไรไว้ ⇒ ต่อให้แก้ตารางรอบนี้ ประเทศถัดไปที่ตารางผิดก็จะเสียเงินแบบเดียวกันจนกว่าจะมีคนสังเกต

**นี่คือข้อที่ต้องออกแบบจริง ๆ** ข้อ 2.1 กับ 2.2 เป็นแค่การแก้บั๊ก

---

## 3. ที่เสนอ: จำคำตอบ "ไม่มีข้อมูล" เหมือนที่จำค่าอากาศ

เพิ่ม **ชั้นเดียว** ต่อจากของเดิม — negative cache ระดับ cell

```
ถามความครอบคลุมของ cell นี้
  ↓ ตารางประเทศบอกว่าไม่ครอบคลุม   → จบ ต้นทุน 0            (มีอยู่แล้ว)
  ↓ Redis จำไว้ว่า cell นี้ = none  → จบ ต้นทุน 0            (ใหม่)
  ↓ ไม่รู้                          → ยิง 1 ครั้ง
       ├ 200 → ใช้ผล + จำว่า cell นี้ = full  (TTL 30 วัน)
       ├ 404 → ไม่มีผล + จำว่า cell นี้ = none (TTL 30 วัน)
       └ 5xx / timeout → ไม่จำอะไร ลองใหม่รอบหน้า
```

### 3.1 ทำไมเก็บที่ระดับ cell ไม่ใช่ระดับประเทศ

- **cell คือหน่วยที่เรา poll อยู่แล้ว** — ใช้คีย์เดียวกับ `env:wx:<cell>` ไม่ต้องคิดโครงใหม่
- ความครอบคลุมไม่ได้ตรงตามพรมแดนเสมอ (เกาะ ดินแดนโพ้นทะเล พื้นที่พิพาท) ตารางประเทศจะผิดเป็นก้อนใหญ่ ส่วน cell ผิดได้ทีละ ~28 กม.
- ตารางประเทศยัง**อยู่ต่อ**ในฐานะด่านแรกฟรี ๆ — ชั้นใหม่แค่แก้ตอนตารางผิด

### 3.2 ทำไม TTL 30 วัน ไม่ใช่ถาวร

Google เพิ่มประเทศเรื่อย ๆ ถ้าจำว่า "ไม่มี" ตลอดไป วันที่เขาเปิดไทยเราจะไม่มีวันรู้
30 วัน = **ยอมเสีย 1 call ต่อ cell ต่อเดือน** เพื่อไม่ตกขบวน — เทียบกับ 2,880 ที่เสียอยู่ตอนนี้

### 3.3 ทำไมไม่ทำเป็นตารางใน DB

Redis หายก็แค่ยิงใหม่ 1 call ต่อ cell แล้วเรียนรู้ใหม่ — ราคาถูกกว่า migration + โค้ดอ่าน/เขียนอีกตาราง
**ถ้าวันหนึ่ง Redis ล่มบ่อยจนแพง ค่อยย้ายลง `tb_environment_snapshot`** (มีคอลัมน์ว่างอยู่แล้ว)

### 3.4 คีย์ที่เสนอ

```
env:cov:<provider>:<kind>:<cell>   →  "full" | "none"     TTL 30 วัน
เช่น  env:cov:Google:alerts:13.75:100.50  → "none"
      env:cov:Google:weather:35.75:139.50 → "none"
```

แยก `<kind>` เพราะ **ความครอบคลุมของ weather กับ alert ไม่เท่ากัน** — ญี่ปุ่นมี alert แต่ไม่มี weather ซึ่งเป็นเคสที่คอมเมนต์ใน `environment_coverage.go` เตือนไว้เองอยู่แล้ว

---

## 4. ผลต่อโควตา

สมมติ dev มี workspace ในกรุงเทพ 1 cell (สภาพจริงตอนนี้)

| | ก่อน | หลัง |
|---|---|---|
| weather | 720 | 720 |
| alert (Google) | **2,880** ทิ้งทั้งหมด | **1** (ยิงเดือนละครั้งเพื่อเช็คว่าเปิดหรือยัง) |
| **รวม/เดือน/cell** | **3,600** | **721** |
| **% ของโควตาฟรี** | 36% | **7.2%** |
| จำนวนเมืองที่รองรับได้ในโควตาฟรี | **2** | **13** |

ถ้าลบ `TH` ออกจากตารางประเทศด้วย (ข้อ 2.1) ตัวเลข alert จะเป็น **0** ตั้งแต่ call แรก — ชั้น negative cache ยังจำเป็นอยู่ เพราะมันคุ้มครองประเทศถัดไปที่ตารางเดายังผิด

---

## 5. สิ่งที่ต้องแก้ (ไล่ตามไฟล์)

| ไฟล์ | แก้อะไร |
|---|---|
| `internal/service/environment_google_alerts.go` | แยก `404` → `ErrProviderNoCoverage` · non-200 อื่นคงเป็น `ErrProviderUnavailable` |
| `internal/service/environment_google.go` | เหมือนกันสำหรับ weather (`currentConditions` ก็ตอบ 404 แบบเดียวกัน — ยืนยันแล้วที่โตเกียว) |
| `internal/cache/environment.go` | เพิ่ม `Coverage(ctx, provider, kind, cell)` / `SetCoverage(...)` TTL 30 วัน |
| `internal/service/environment_alerts.go` | `PollPointAlerts` เช็ค learned coverage ก่อนยิง · เมื่อได้ `ErrProviderNoCoverage` ให้เขียนจำ |
| `internal/service/environment_weather.go` | เส้นทางเดียวกันสำหรับ weather |
| `internal/service/environment_coverage.go` | เอา `TH` และ `VN` ออกจาก `googleAlertCountries` พร้อมคอมเมนต์ว่าพิสูจน์ด้วยการยิงจริงวันไหน |

### เทสต์ที่ควรมี

- 404 ต้องได้ `ErrProviderNoCoverage` ไม่ใช่ `ErrProviderUnavailable` · 500 ต้องยังเป็น `Unavailable`
- `200 + alerts:[]` **ต้องไม่**ถูกจำว่า none (นี่คือกับดักที่จะทำให้ประเทศที่ครอบคลุมจริงเงียบไปทั้งเดือน)
- timeout ต้องไม่เขียน coverage
- cell ที่จำว่า none แล้ว ต้องไม่มี call ออกไปเลย
- ตารางประเทศกับ learned coverage ขัดกัน → learned ชนะ

---

## 6. ที่ยัง**ไม่**เสนอ

- **ไม่ขยาย cell ให้ใหญ่กว่า 0.25°** — 28 กม. พอดีกับที่ Google reverse-geocode คืนระดับแขวง/เขต ถ้าขยายเป็น 1° (~111 กม.) กรุงเทพกับชลบุรีจะใช้อากาศก้อนเดียวกัน
- **ไม่ลดรอบ alert จาก 15 นาที** — EC-02 ต้องการ 5 นาทีสำหรับ emergency อยู่แล้ว การลดรอบแก้ปัญหาผิดจุด: ปัญหาคือยิงในที่ที่ไม่มีคำตอบ ไม่ใช่ยิงถี่เกินในที่ที่มี
- **ไม่แตะ soft cap 9,500** — มันทำงานถูกต้อง เป็นตาข่ายกันบิล ไม่ใช่กลไกประหยัด
