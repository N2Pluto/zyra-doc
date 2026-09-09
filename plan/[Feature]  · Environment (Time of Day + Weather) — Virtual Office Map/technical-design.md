# SC-ENV-01 · Technical Design — Environment Aggregator API (ของเราเอง)

> **สถานะ:** design เท่านั้น ยังไม่ implement · **วันที่:** 2026-09-09
> **โจทย์:** รวมทุก provider ไว้หลังบ้าน ทำเป็น API ของ Zyra เอง + cache ให้ **ไม่เกินโควตาฟรี** แล้วหน้าบ้านเรียกแต่ของเรา
> **คำตอบ: ทำได้ และควรทำแบบนี้** — เหตุผลอยู่ใน [§1](#1-ทำไมต้องผ่าน-api-ของเราเสมอ) · ตัวเลขโควตาอยู่ใน [§4](#4-cache--งบโควตา-ไม่ให้เกินฟรี)
> อ่าน [spec.md](spec.md) ก่อน — ภาคผนวก A/B ในไฟล์นั้นคือผลตรวจ provider จริงที่ design นี้ยืนอยู่บน
> **โจทย์ global (2026-09-09):** ไม่มี provider เจ้าเดียวครอบทั้งโลก ⇒ อ่าน [§11](#11-รองรับทั่วโลก--สิ่งที่เพิ่มจาก-1-10) คู่กับ §3 เสมอ
> **มติ MD 2026-09-09:** รอบแรกใช้ Google + TMD + GDACS (Open-Meteo เลื่อน) ⇒ [§12](#12-รอบแรกตามมติ-md-2026-09-09--google--tmd--gdacs) คือสิ่งที่ implement จริงในรอบนี้
> **PM เพิ่ม HP-06/HP-07 (2026-09-09):** master switch ของ workspace location ⇒ [§13](#13-master-switch-ของ-workspace-location-hp-06--hp-07)
> ยึดตามของที่มีอยู่จริงในโค้ด: `zyra-api/internal/cache/*.go` (nil-safe Redis cache), `run*Loop` + ticker ใน `main.go`, Redis pub/sub `vo:zone` ที่ `zyra-ws` subscribe อยู่แล้ว, `tb_workspace.owner_id` (mig 47), migration ถัดไป = **98**

---

## 1. ทำไมต้องผ่าน API ของเราเสมอ

| เหตุผล | รายละเอียด |
|---|---|
| **API key ไม่รั่ว** | Google/OWM key ต้องอยู่ฝั่ง server เท่านั้น — ถ้าใส่ใน `NEXT_PUBLIC_*` จะถูก bake เข้า bundle และใครก็เอาไปใช้ได้ (โควตาเราจ่าย) |
| **คุมโควตาได้จริง** | 1 workspace ที่มี 50 คน online = 50 client — ถ้าแต่ละ client ยิง provider เอง = 50× ของที่จำเป็น. ผ่าน server = **1 ครั้งต่อ cell ต่อ TTL** ไม่ว่าจะมีคนดูกี่คน |
| **spec บังคับ server-authoritative** | HP-02: "ดึงเวลาจาก server ไม่ใช่ client clock" · HP-01/EC-03: "ทุก member เห็นเหมือนกันภายใน 5 วินาที" — ต้องมีค่ากลางฝั่ง server อยู่แล้ว |
| **CORS / provider ที่เรียกจาก browser ไม่ได้** | TMD ตอบ XML และไม่ส่ง CORS header ที่ใช้ได้ทั่วไป · Nominatim ห้ามยิงจาก client จำนวนมาก (1 rps + ต้องมี User-Agent ระบุตัวตน) |
| **EP-01 graceful degrade** | logic retry 3 ครั้ง → fallback → cache → default state ต้องอยู่ที่เดียว ไม่กระจายใน client |
| **สลับ provider ทีหลังได้** | ถ้า PM ยังไม่เคาะทาง A (Google) หรือ B (ประกอบเอง) — เขียนเป็น interface เดียวแล้วเปลี่ยนได้โดยหน้าบ้านไม่ต้องแก้ |

---

## 2. สถาปัตยกรรม

```
                    ┌──────────── zyra-api ─────────────┐
 provider ภายนอก    │                                    │
 ─────────────────  │  runEnvironmentLoop (ticker)        │
 Google Weather ──┐ │    ├─ WeatherFetcher  (per cell)    │
 Open-Meteo ──────┼─┼──▶ ├─ AlertPoller     (global, TH)  │
 TMD Warning ─────┤ │    └─ SeismicPoller   (global, TH)  │
 Nominatim ───────┘ │              │                      │
 (reverse geocode)  │              ▼                      │
                    │   EnvironmentCache (Redis)          │──▶ Redis pub/sub "vo:zone"
                    │   + tb_environment_snapshot (PG)    │        │ type: environment_changed
                    │              │                      │        │       weather_alert
                    │              ▼                      │        ▼
                    │   GET /api/user/workspaces/{id}/     │    zyra-ws ──▶ ทุก client ใน room
                    │       environment   (UserGuard)      │
                    └──────────────┬───────────────────────┘
                                   │ 1 ครั้งตอน mount
                                   ▼
                        zyra-app (Pixi VO + HUD)
                        - time-of-day คำนวณ client จาก tz + serverTime  → 0 API call
                        - weather effect / widget / alert banner จาก snapshot
                        - อัปเดตต่อจาก ws push (ไม่ poll)
```

**หัวใจ 3 ข้อ**
1. **จำนวน call ผูกกับ "cell × TTL" ไม่ผูกกับจำนวน user หรือ workspace** — 100 workspace ในกรุงเทพฯ = 1 cell
2. **alert ของไทยไม่กิน quota เลย** — TMD เป็น feed ระดับประเทศใบเดียว → poller ตัวเดียวทั้งระบบ แล้ว fan-out ผ่าน Redis
3. **Time of Day ไม่เรียก provider เลย** — เก็บ `timezone` (IANA) + sunrise/sunset ของวันนั้นไว้ แล้วให้ client คำนวณ stage เอง

---

## 3. Provider layer — 1 interface หลาย backend

```go
// internal/service/environment/provider.go
type WeatherProvider interface {
    Name() string                                    // "google" | "open-meteo"
    Current(ctx context.Context, lat, lng float64) (*model.WeatherSnapshot, error)
}

type AlertProvider interface {
    Name() string                                    // "tmd" | "google" | "gdacs"
    Poll(ctx context.Context) ([]model.WeatherAlert, error)   // TMD/GDACS = ทั้งประเทศ
    PollAt(ctx context.Context, lat, lng float64) ([]model.WeatherAlert, error) // Google = per point
}

type GeocodeProvider interface {
    Reverse(ctx context.Context, lat, lng float64) (*model.PlaceRef, error) // → ชื่อ + tz + country
    Search(ctx context.Context, q string) ([]model.PlaceRef, error)
}
```

**chain ตาม EP-01** (ลำดับกำหนดด้วย env var ไม่ hardcode · สำหรับ global ต้องเลือกตาม `country_code` ด้วย — ดู [§11.1](#111-เลือก-provider-จาก-country_code-ไม่ใช่จาก-config-เดียวทั้งระบบ)):
```
WeatherProvider:  primary → secondary → Redis cache → tb_environment_snapshot (stale ≤ 3 ชม.) → default Clear
AlertProvider:    TH → TMD  ·  non-TH → Google (ถ้าเปิด)  ·  ชั้น Emergency → GDACS (optional)
GeocodeProvider:  Google Geocoding (ถ้าเลือกทาง A) → Nominatim (ทาง B) → ตาราง 77 จังหวัด offline
```

`model.WeatherSnapshot` ให้ normalize เป็นรูปแบบเดียวเสมอ ไม่ปล่อยรูป provider ออกไปหน้าบ้าน:
```go
type WeatherSnapshot struct {
    Condition   string  `json:"condition"`    // clear|cloudy|rain|drizzle|thunderstorm|fog|haze|windy|snow
    TempC       float64 `json:"temp_c"`
    FeelsLikeC  float64 `json:"feels_like_c"`
    Humidity    int     `json:"humidity"`
    WindKph     float64 `json:"wind_kph"`
    GustKph     float64 `json:"gust_kph"`
    CloudPct    int     `json:"cloud_pct"`
    IsDay       bool    `json:"is_day"`
    Pm25        *float64 `json:"pm25,omitempty"`   // haze (Open-Meteo AQ / provider ที่มี)
    Source      string  `json:"source"`            // ชื่อที่โชว์ใน widget
    FetchedAt   time.Time `json:"fetched_at"`
    Stale       bool    `json:"stale"`             // → badge "ข้อมูลอาจไม่อัปเดต" (EP-01)
}
```

> **Windy** ไม่มีใน WMO code — normalize จาก `GustKph ≥ threshold` (ค่า threshold รอ PM เคาะ ข้อ 15 ใน spec)

---

## 4. Cache + งบโควตา (ไม่ให้เกินฟรี)

### 4.1 Cell key — ตัวคูณที่สำคัญที่สุด
ปัดพิกัดเป็น grid ก่อนทำ cache key เสมอ:
```go
func cellKey(lat, lng float64) string {           // 0.25° ≈ 28 km
    return fmt.Sprintf("env:wx:%.2f:%.2f", math.Round(lat/0.25)*0.25, math.Round(lng/0.25)*0.25)
}
```
- 0.25° ทำให้ทั้งกรุงเทพฯ+ปริมณฑลเหลือ ~2–3 cell (สภาพอากาศระดับ effect บนแมพไม่ต่างกันในระยะ 28 km)
- ทุก workspace ที่ตกใน cell เดียวกัน **ใช้ผลลัพธ์เดียวกัน** — นี่คือสิ่งที่ทำให้อยู่ในโควตาฟรีได้

### 4.2 งบต่อวัน
โควตาฟรี Google = **10,000 events/เดือน** ≈ **333 calls/วัน** (สมมติว่า Weather API เป็น SKU เดียวรวมทุก endpoint — **ต้องยืนยันในบัญชี GCP ก่อน** เพราะถ้าแยก SKU งบจะมากกว่านี้)

| TTL weather | calls/วัน/cell | จำนวน **active cell** ที่ยังฟรี (alert ไทยใช้ TMD) |
|---|---|---|
| 15 นาที | 96 | 3 |
| 30 นาที | 48 | 6 |
| **60 นาที (ตรงกับ HP-03)** | **24** | **13** |
| 3 ชั่วโมง | 8 | 41 |

→ **ตั้ง TTL 60 นาทีตามที่ spec เขียนไว้แล้ว รับได้ ~13 cell พร้อมกันโดยไม่เสียเงิน** (ถ้าโตเกินนั้น ค่าใช้จ่ายคือ ~$0.15 ต่อ 1,000 call เพิ่ม — ดูตาราง B.1 ใน spec)

**ตัวคูณที่ต้องมี ไม่ใช่ optional:**
- **fetch เฉพาะ cell ที่มีคนอยู่จริง** — join กับ presence ที่มีอยู่แล้ว (`workspace_presence_service`) → workspace ที่ไม่มีใคร online = 0 call
- **Time of Day = 0 call** (คำนวณจาก tz ที่เก็บไว้)
- **sunrise/sunset = 1 call/วัน/cell** (ถ้าใช้; หรือคำนวณเองจาก lat/lng ด้วยสูตร solar position ก็ได้ = 0 call)
- **alert ไทย = 0 Google call** (TMD ฟรี)

### 4.3 Cache 2 ชั้น
| ชั้น | ที่ | Key | TTL | หน้าที่ |
|---|---|---|---|---|
| Hot | Redis | `env:wx:<cell>` | 60 นาที | ตอบ request ปกติ |
| Hot | Redis | `env:alert:th` | 5 นาที | ผล TMD ล่าสุด (ทั้งประเทศ) |
| Hot | Redis | `env:place:<cell>` | ไม่มี TTL | ผล reverse geocode (แทบไม่เปลี่ยน) |
| Durable | Postgres `tb_environment_snapshot` | `cell_key` | — | รอด Redis restart + เป็นแหล่ง "stale ≤ 3 ชม." ของ EP-01 |
| Durable | Postgres `tb_weather_alert` | `source_alert_id` UNIQUE | — | dedup + bell panel (HP-04) + `expires_at` |

### 4.4 กัน call ซ้ำ + กันเกินโควตา
```go
// single-flight: หลาย pod / หลาย request พร้อมกัน → ยิง provider ครั้งเดียว
ok, _ := rdb.SetNX(ctx, "env:lock:"+cell, podID, 20*time.Second).Result()
if !ok { return cachedOrStale(cell) }   // อีก pod กำลังยิงอยู่ — อ่าน cache ไปก่อน

// quota guard: นับต่อเดือนต่อ provider แล้วหยุดเองก่อนถึงเพดาน
month := time.Now().UTC().Format("2006-01")
n, _ := rdb.Incr(ctx, "env:quota:google:"+month).Result()
rdb.Expire(ctx, "env:quota:google:"+month, 40*24*time.Hour)
if n > googleSoftCap {                  // soft cap = 95% ของ 10,000
    slog.Warn("weather provider soft cap reached", "provider", "google", "count", n)
    return fallbackChain(ctx, lat, lng) // → provider สำรอง → cache → stale → default Clear
}
```
- soft cap ทำให้ **บิลไม่บานโดยไม่ตั้งใจ** และพฤติกรรมตอนชนเพดานตรงกับ EP-01 ที่ spec เขียนไว้แล้ว (degrade ไม่ crash)
- `stale=true` ที่ส่งไปหน้าบ้าน = badge "ข้อมูลอาจไม่อัปเดต"

---

## 5. Background loops (ต่อ pattern เดิมใน `main.go`)

```go
const (
    envWeatherInterval = 10 * time.Minute  // สแกนว่า cell ไหนหมด TTL แล้วค่อยยิง (ไม่ใช่ยิงทุก 10 นาที)
    envAlertInterval   = 5 * time.Minute   // TMD ทั้งประเทศ — 1 request ต่อรอบ
    envSeismicInterval = 30 * time.Minute  // TMD DailySeismicEvent (payload 685 KB)
)

func runEnvironmentLoop(ctx context.Context, svc *service.EnvironmentService) { /* ticker เหมือน runSectionCleanupLoop */ }
```
- **AlertPoller เป็น singleton ต่อคลัสเตอร์** — ใช้ Redis lock (`env:lock:alert-poller`, TTL 2× interval) เพื่อไม่ให้ทุก replica ยิง TMD ซ้อนกัน
- TMD **ไม่ส่ง `ETag`/`Last-Modified`** (ตรวจแล้ว) → conditional request ทำไม่ได้ ต้องดึง 42 KB ทุกรอบ (poller ตัวเดียว = ~12 MB/วัน ยอมรับได้)
- เจอ alert ใหม่ (ตาม dedup key) → เขียน `tb_weather_alert` → publish `vo:zone` → notification เข้า bell panel (ใช้ NotificationService ที่มีอยู่)

---

## 6. API contract (หน้าบ้านเรียกแต่ของเรา)

ทุก endpoint อยู่ใต้ `api.Group("/user", middleware.UserGuard(...))` ตาม [15-member-api-separation](../../../.claude/rules/15-member-api-separation.md) — **ห้ามให้ member แตะ `/api/admin/*`**

### 6.1 อ่าน snapshot (member ทุกคน)
```
GET /api/user/workspaces/{workspaceId}/environment
```
```json
{
  "status": 200, "message": "success",
  "data": {
    "enabled": { "time_of_day": true, "weather": true, "alerts": true },
    "location": { "label": "กรุงเทพมหานคร", "lat": 13.7563, "lng": 100.5018,
                  "timezone": "Asia/Bangkok", "utc_offset_seconds": 25200, "country": "TH" },
    "server_time": "2026-09-09T17:45:12+07:00",
    "sun": { "sunrise": "06:06", "sunset": "18:24" },
    "weather": { "condition": "thunderstorm", "temp_c": 31.1, "humidity": 67,
                 "wind_kph": 3.3, "gust_kph": 21.2, "cloud_pct": 93, "is_day": true,
                 "source": "กรมอุตุนิยมวิทยา / Google", "fetched_at": "...", "stale": false },
    "alerts": [ { "id": "tmd-195-2569-5", "severity": "warning",
                  "title": "ฝนตกหนักถึงหนักมากบริเวณประเทศไทย ฉบับที่ 5",
                  "headline": "...", "url": "https://tmd.go.th/...pdf",
                  "announced_at": "...", "expires_at": "...", "dismissible": true } ]
  }
}
```
- `server_time` + `timezone` = วัตถุดิบให้ client คำนวณ Time of Day stage เอง (HP-02 ข้อ "sync จาก server")
- `severity` normalize เป็น `watch | warning | emergency` เท่านั้น — **map มาจาก provider ไม่ใช่จากหน้าบ้าน** (`dismissible=false` เมื่อ emergency ตาม EC-02)

### 6.2 Owner ตั้งค่า (HP-01, EC-03)
```
PUT /api/user/workspaces/{workspaceId}/environment
{ "lat": 18.7904, "lng": 98.9847, "time_of_day": true, "weather": true, "alerts": true }
```
- ตรวจสิทธิ์จาก `tb_workspace.owner_id` — **owner ไม่มีแถวใน tb_workspace_member** จึงเช็คผ่าน member table เพียว ๆ ไม่ได้
- flow: reverse geocode (cache) → เก็บ label + tz + country → fetch weather ทันที (bypass TTL 1 ครั้ง) → publish `environment_changed` → members เห็นใน ≤ 5 วินาที (AC ของ HP-01/EC-03)
- ถ้า `country != "TH"` → alerts source สลับเป็น Google (หรือปิด + แจ้ง) ตาม EP-02

### 6.3 ค้น / ปักหมุด location (owner)
```
GET /api/user/environment/places?q=chiang            → autocomplete (forward)
GET /api/user/environment/places/reverse?lat=&lng=   → ปักหมุด → ชื่อ + tz + country
```
proxy ฝั่งเราเสมอ: key ไม่รั่ว + บังคับ `User-Agent` ของ Nominatim + rate-limit ต่อ user ได้ + cache `env:place:<cell>` ถาวร

### 6.4 Personal preference (HP-05)
ไม่สร้าง endpoint ใหม่ — ใส่ 2 คีย์ในโครง settings ที่มีอยู่ (JSONB blob ของ user settings): `environment.time_of_day`, `environment.weather_effects`
**Weather alerts ไม่มีในนี้** — เป็น workspace-level (owner เท่านั้นปิด) ตาม AC ของ HP-05

---

## 7. Realtime — reuse `vo:zone` ที่ ws subscribe อยู่แล้ว

`zoneEventEnvelope` ปัจจุบันคือ `{workspace_id, type, payload}` ซึ่งรองรับ type ใหม่ได้ทันที เสนอเพิ่ม 2 type:

| type | เมื่อไหร่ | payload |
|---|---|---|
| `environment_changed` | weather เปลี่ยน condition, owner เปลี่ยน location/toggle | snapshot ย่อ (เหมือน §6.1 แต่ไม่มี alerts) |
| `weather_alert` | alert ใหม่ / alert หมดอายุ | `{action: "new"\|"expired", alert: {...}}` |

- ต้องเพิ่ม case ใน `zyra-ws/internal/store/redis.go` (จุดที่ subscribe `zoneEventChannel`) — **ยังไม่ตรวจว่ามี default case ที่ทิ้ง type ไม่รู้จักเงียบ ๆ หรือไม่ ต้องอ่านก่อนเขียน**
- ทางเลือก: แยก channel `vo:env` ถ้าไม่อยากผสมกับ zone traffic — แลกกับต้องเพิ่ม subscriber ใหม่ใน ws
- ห้าม broadcast ทุกรอบ fetch — **publish เฉพาะเมื่อค่าที่ส่งผลต่อภาพเปลี่ยน** (condition / severity / location / toggle) ไม่ใช่เมื่ออุณหภูมิขยับ 0.1°

---

## 8. DB (migration 98)

```sql
-- 98_environment.sql
ALTER TABLE tb_workspace
    ADD COLUMN IF NOT EXISTS env_location_enabled BOOLEAN NOT NULL DEFAULT TRUE,  -- master switch (HP-06)
    ADD COLUMN IF NOT EXISTS env_lat            DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS env_lng            DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS env_place_label    TEXT,
    ADD COLUMN IF NOT EXISTS env_timezone       TEXT,          -- IANA เช่น Asia/Bangkok
    ADD COLUMN IF NOT EXISTS env_country        VARCHAR(2),
    ADD COLUMN IF NOT EXISTS env_time_of_day    BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS env_weather        BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS env_alerts         BOOLEAN NOT NULL DEFAULT TRUE;

-- cache ถาวรต่อ grid cell (ไม่ใช่ต่อ workspace) — รอด Redis restart + เป็นแหล่ง stale ของ EP-01
CREATE TABLE IF NOT EXISTS tb_environment_snapshot (
    cell_key    TEXT        PRIMARY KEY,        -- "13.75:100.50"
    provider    TEXT        NOT NULL,
    payload     JSONB       NOT NULL,           -- WeatherSnapshot ที่ normalize แล้ว
    fetched_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tb_weather_alert (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    source          TEXT        NOT NULL,       -- tmd | google | gdacs
    source_alert_id TEXT        NOT NULL,       -- TMD: IssueNo+เลขประกาศ+AnnounceDate
    severity        TEXT        NOT NULL,       -- watch | warning | emergency
    country         VARCHAR(2),
    area_label      TEXT,                       -- ข้อความพื้นที่ (TMD) — polygon ถ้ามาจาก Google
    title           TEXT        NOT NULL,
    headline        TEXT,
    url             TEXT,
    announced_at    TIMESTAMPTZ NOT NULL,
    expires_at      TIMESTAMPTZ,
    payload         JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (source, source_alert_id)             -- dedup ตาม AC ของ HP-04
);
CREATE INDEX IF NOT EXISTS idx_weather_alert_active ON tb_weather_alert (country, expires_at DESC);
```
ต้องมี `98_environment.down.sql` คู่กันตาม [06-release](../../../.claude/rules/06-release.md) · migration รันมือ ([[migrations-not-auto-run]])

---

## 9. หน้าบ้าน (zyra-app) — ไม่แตะ provider เลย

| สิ่งที่ทำ | ทำอย่างไร | ต้นทุน API |
|---|---|---|
| Time of Day stage + fade 30 วินาที | คำนวณจาก `server_time` + `timezone` + `sun` ที่ได้มาครั้งเดียว แล้วเดินต่อด้วย clock ในเครื่อง (มี drift correction จาก ws) | **0** |
| Weather effect (rain/fog/thunder) | อ่าน `weather.condition` จาก snapshot · เปลี่ยนตาม ws push | **0** |
| Weather widget + popup | จาก snapshot ตัวเดียวกัน | **0** |
| Alert banner + bell | จาก `alerts[]` + ws `weather_alert` | **0** |
| ตั้ง/ปักหมุด location (owner) | เรียก `/api/user/environment/places*` ของเรา | ต่อ 1 การกระทำของ owner |

- fetch snapshot **1 ครั้งตอน mount** แล้วรอ ws — **ไม่ต้อง setInterval poll** (ถ้า poll จะกลายเป็นภาระของ zyra-api แทน)
- overlay/particle ต้องทำเป็น **Pixi layer** ไม่ใช่ Phaser (spec เขียนผิด engine — ดูข้อ 2 ใน spec) และ DOM overlay ข้าง canvas z-1 ต้องกำหนด z เอง ไม่งั้นจะไปอยู่หลังแมพ ([[vo-hud-pointer-events-none]])
- ปิด effects (HP-05) = ไม่ render layer แต่ **ยังเรียก snapshot** เพราะ widget ยังต้องแสดง (ตาม AC)

---

## 10. สรุปตัวเลขที่ทำให้อยู่ในของฟรี

| มาตรการ | ผล |
|---|---|
| cell 0.25° | ทุก workspace ในกรุงเทพฯ+ปริมณฑล = ~2–3 call ต่อรอบ ไม่ใช่ต่อ workspace |
| TTL weather 60 นาที | 24 calls/วัน/cell → **~13 active cell ยังฟรี** |
| fetch เฉพาะ cell ที่มีคน online | workspace ที่ไม่มีคนใช้ = 0 call |
| alert ไทยใช้ TMD (ฟรี) + poller singleton | alert **ไม่กิน quota Google เลย** และไม่โตตามจำนวน workspace |
| Time of Day คำนวณเอง | 0 call ทั้งที่เป็นฟีเจอร์ที่เห็นบ่อยสุด |
| reverse geocode cache ถาวร | หลักสิบ call/เดือน อยู่ในฟรี 10,000 สบาย |
| quota guard + soft cap 95% | ชนเพดาน → degrade ตาม EP-01 ไม่ใช่บิลบาน |

**ข้อจำกัดที่ยังเหลือ (ไม่ได้แก้ด้วย design นี้)**
- ไม่มี provider ไหนให้ webhook → EC-02 "ทันที" ทำได้ดีสุดคือ poll 5 นาที (ต้องแก้ AC)
- severity ของ TMD ยังต้อง derive ถ้าเลือกทาง B (ข้อ 23 ใน spec)
- Open-Meteo free = non-commercial → ถ้าใช้เป็น provider ใน production ต้องซื้อ plan (ข้อ 19)
- โควตาฟรี Google ต่อ SKU ยัง **ยืนยันไม่ได้จากนอกบัญชี** ว่า alerts นับ SKU เดียวกับ currentConditions หรือไม่ — ตัวเลขใน §4.2 จะเปลี่ยนถ้าแยก SKU

---

## 11. รองรับทั่วโลก — สิ่งที่เพิ่มจาก §1–10

> ที่มา: [spec.md ภาคผนวก C](spec.md#ภาคผนวก-c--รองรับทั่วโลก-ตรวจจริง-2026-09-09) · **ไม่มี provider เจ้าเดียวจบสำหรับ global** ⇒ provider layer ใน §3 เป็นข้อบังคับ

### 11.1 เลือก provider จาก country_code ไม่ใช่จาก config เดียวทั้งระบบ
```go
// internal/service/environment/routing.go
// alertRouteFor คืน provider chain ตามประเทศของ location — Google alerts ครอบเพียง ~30
// ประเทศ, TMD เฉพาะไทย, GDACS ทั่วโลกแต่เฉพาะภัยพิบัติใหญ่. ตารางนี้มาจาก config
// (env/DB) ไม่ hardcode เพราะ coverage ของ provider เปลี่ยนได้ตลอด.
func (s *EnvironmentService) alertRouteFor(country string) []AlertProvider {
    switch {
    case country == "TH":                 return []AlertProvider{s.tmd, s.gdacs}
    case s.googleAlertCountries[country]: return []AlertProvider{s.google, s.gdacs}
    default:                              return []AlertProvider{s.gdacs}   // ชั้นแดงเท่านั้น
    }
}
```
- `weatherRouteFor` แยกกันอีกตัว: **Open-Meteo เป็นค่าตั้งต้นทุกพิกัด** (ครอบจีน/ญี่ปุ่น/เกาหลี/เวียดนามที่ Google ไม่มีข้อมูลอากาศ) และใช้ Google เฉพาะประเทศที่มี ถ้าอยากได้ visibility ตรง ๆ
- snapshot ต้องมี field ใหม่ `alert_coverage: "full" | "disaster_only" | "none"` ให้หน้าบ้านแสดงสถานะได้ตรง — EP-02 เดิมคิดแค่ 2 สถานะ (ไทย/ไม่ไทย) ซึ่งไม่พออีกแล้ว

### 11.2 Time of Day ต้องผูกกับ sunrise/sunset จริง + branch ขั้วโลก
```go
// stageAt เลือก stage จากพระอาทิตย์จริงของวันนั้น ไม่ใช่ตารางนาฬิกาคงที่ — ตาราง
// 05:00–07:00 ของ spec ใช้ได้แค่เขตร้อน (Svalbard 9 ก.ย. sunrise 04:52 / sunset 20:56).
// polar day/night: Open-Meteo ไม่คืน null แต่คืน sunrise=sunset=T00:00 พร้อม
// daylight_duration 0 (คืนทั้งวัน) หรือ 86400 (วันทั้งวัน) — ต้องเช็คตัวนี้ก่อนเสมอ
// ไม่งั้นจะได้ Dawn ตอนเที่ยงคืนตลอดฤดู.
func stageAt(now time.Time, sun SunTimes) Stage {
    switch {
    case sun.DaylightSeconds <= 0:      return StageNight     // polar night
    case sun.DaylightSeconds >= 86400:  return StageAfternoon // polar day
    }
    // ปกติ: Dawn = [sunrise-45m, sunrise+45m] · Evening = [sunset-45m, sunset+45m]
    // Morning = ถึงเที่ยงสุริยะ · Afternoon = จนถึงช่วง Evening · ที่เหลือ Night
    ...
}
```
- ค่า `daylight_duration` ขอมาจาก Open-Meteo พร้อม `sunrise,sunset` ใน call เดียว (ไม่มีต้นทุนเพิ่ม)
- ค่า overlay rgba ของ 5 stage ใน spec ใช้ได้ตามเดิม — เปลี่ยนแค่ "วิธีตัดว่าอยู่ stage ไหน"

### 11.3 เก็บ timezone เป็นชื่อ IANA ห้ามเก็บ offset
`tb_workspace.env_timezone` เก็บ `Europe/London` แล้วคำนวณ offset ตอนใช้ทุกครั้ง —
ยิงจริงยืนยันว่า Open-Meteo คืน DST ถูก (London = GMT+1 ตอนนี้, New York = GMT-4)
แต่ค่านั้นเปลี่ยนปีละ 2 ครั้ง **ถ้า cache offset ไว้จะเพี้ยน 1 ชั่วโมงทุกครั้งที่ DST สลับ**
(`utc_offset_seconds` ส่งไปหน้าบ้านได้ แต่ต้องส่งใหม่ทุก snapshot ไม่ใช่เก็บลง DB)

### 11.4 condition ที่ต้องเพิ่มสำหรับซีกโลกหนาว
`WeatherSnapshot.Condition` เพิ่ม `snow` (WMO 71–77, 85–86) และ `freezing_rain` (56, 57, 66, 67)
ถ้ายังไม่ทำ effect ให้ map ลง `cloudy` ชั่วคราว **แต่ต้องเป็นการตัดสินใจที่บันทึกไว้** ไม่ใช่ปล่อยตกช่อง default เงียบ ๆ (ข้อ 29 ใน spec)

### 11.5 หน่วยวัด + ภาษา
- API ส่งค่า **หน่วยเมตริกเสมอ** แล้วให้หน้าบ้านแปลงตาม preference — ไม่ส่งค่าที่แปลงแล้วมาจาก server เพื่อไม่ให้ cache แตกเป็นสองชุด
- `alerts[].lang` บอกภาษาต้นฉบับของประกาศ ให้หน้าบ้านตัดสินใจแสดง/เตือนได้ (บางหน่วยงานให้แต่ภาษาท้องถิ่น — ข้อ 31)

### 11.6 โควตาเมื่อเป็น global
| แหล่ง | ต้นทุนต่อเดือน | หมายเหตุ |
|---|---|---|
| Open-Meteo (weather ทุกพิกัด) | ตาม commercial plan | ไม่กินโควตา Google |
| TMD (alert ไทย) | ฟรี | 1 poller ทั้งระบบ |
| GDACS (alert ชั้นแดงทั่วโลก) | ฟรี | 1 poller ทั้งระบบ เหมือน TMD |
| Google alerts (~30 ประเทศ) | 2,880/เดือน/ช่องกริด ถ้า poll 15 นาที | โควตาฟรี 10,000 ≈ **3 ช่อง** ⇒ ถ้าหลายประเทศ ให้ขยายเป็น 30 นาที (≈ 6 ช่อง) หรือยอมจ่าย $0.15/1,000 |

**poller ระดับโลกต้องเป็น singleton ต่อคลัสเตอร์ทั้ง TMD และ GDACS** (Redis lock เหมือน §5) — จำนวน call จึงไม่โตตามจำนวน workspace หรือจำนวนประเทศ

---

## 12. รอบแรกตามมติ MD (2026-09-09) — Google + TMD + GDACS

> Open-Meteo เลื่อนออกไป ⇒ `WeatherProvider` รอบแรกมี backend เดียว (Google) แต่ **ยังต้องคงรูป interface ไว้** เพราะรอบถัดไปจะเสียบ Open-Meteo กลับเข้ามาเพื่ออุดช่อง CN/JP/KR/VN
> รายละเอียดผลกระทบต่อผู้ใช้: [spec.md ภาคผนวก D](spec.md#ภาคผนวก-d--มติ-md-2026-09-09-และขอบเขตรอบแรก)

### 12.1 แหล่งข้อมูลต่อหน้าที่
```go
// เวลาท้องถิ่น: Time Zone API ครอบทั่วโลกและไม่ผูกกับ coverage ของ Weather API
// เรียกครั้งเดียวตอน owner ตั้ง location แล้วเก็บ timeZoneId ลง tb_workspace.env_timezone
//   GET https://maps.googleapis.com/maps/api/timezone/json?location=<lat>,<lng>&timestamp=<unix>&key=...
//   → { timeZoneId: "Asia/Bangkok", rawOffset, dstOffset }
// เก็บเฉพาะ timeZoneId — rawOffset/dstOffset คำนวณใหม่ทุกครั้งที่ใช้ (§11.3)

// พระอาทิตย์: คำนวณเองจาก lat/lng ไม่เรียก API
// Google daily forecast มี sunEvents ให้ แต่เป็น call เพิ่ม และไม่มีในประเทศที่ไม่มี weather
// ⇒ สูตร solar position ให้ผลเท่ากันทุกประเทศ ต้นทุน 0 และรู้เองว่าวันนั้นไม่มีพระอาทิตย์ขึ้น (ขั้วโลก)
func sunTimes(lat, lng float64, day time.Time, loc *time.Location) SunTimes
```

### 12.2 weather ที่ขาดในบางประเทศ — ต้อง degrade ไม่ใช่ error
`currentConditions:lookup` ไม่มีข้อมูลสำหรับ CN / JP / KR / VN / CU / IR / KP
⇒ snapshot เพิ่ม field `weather_coverage: "full" | "none"` คู่กับ `alert_coverage` จาก §11.1

| coverage | หน้าบ้านทำอะไร |
|---|---|
| `weather_coverage: "none"` | ไม่ render weather layer · widget แสดงเวลา/stage เท่านั้น + ข้อความว่ายังไม่รองรับข้อมูลอากาศในพื้นที่นี้ · **แสงตามเวลายังทำงานปกติ** |
| `alert_coverage: "disaster_only"` | แสดง banner เฉพาะที่มาจาก GDACS · ไม่โฆษณาว่ามีระบบเตือนภัยครบ |

**ห้าม** ปล่อยให้ประเทศที่ไม่มี coverage ตกลงไปที่ retry/fallback chain ของ EP-01 — มันไม่ใช่ error ชั่วคราว แต่เป็นข้อจำกัดถาวรของ provider ⇒ ตรวจจาก country ก่อนยิง แล้วข้ามไปเลย (ไม่เสียโควตา ไม่ปั่น log)

### 12.3 โควตารอบแรก (Google อย่างเดียว)
| รายการ | รอบเรียก | ต่อเดือน/พื้นที่ | หมายเหตุ |
|---|---|---|---|
| currentConditions | 60 นาที | 720 | เฉพาะพื้นที่ที่มีคน online และประเทศที่มี coverage |
| weatherAlerts | 15 นาที (5 นาทีสำหรับชั้น emergency) | 2,880 | **เฉพาะ ~30 ประเทศ** — ไทยไม่นับเพราะใช้ TMD |
| Time Zone | ครั้งเดียวตอนตั้ง location | ~0 | อยู่ในโควตาฟรี |
| Geocoding (reverse) | ครั้งเดียวตอนปักหมุด | ~0 | อยู่ในโควตาฟรี |
| TMD / GDACS | 5 / 30 นาที | 0 (ฟรี) | poller singleton ต่อคลัสเตอร์ |

⇒ โควตาฟรี 10,000/เดือน รองรับได้ราว **13 พื้นที่** ถ้าเป็นไทยล้วน (ไม่ต้องจ่าย alert) หรือราว **3 พื้นที่** ถ้าเป็นประเทศที่ต้องดึง alert จาก Google ทุก 15 นาที — เกินจากนั้น $0.15/1,000

### 12.4 ที่ต้องคงไว้เพื่อรอบถัดไป
- `WeatherProvider` interface + chain config ผ่าน env (อย่า hardcode Google ในโค้ด service)
- `weather_coverage` / `alert_coverage` ใน snapshot — รอบถัดไปที่เสียบ Open-Meteo จะพลิกค่าจาก `none` เป็น `full` โดยหน้าบ้านไม่ต้องแก้
- ตาราง `country_code → provider` เก็บใน config ไม่ใช่โค้ด (coverage ของ Google เปลี่ยนได้)


---

## 13. Master switch ของ workspace location (HP-06 / HP-07)

> ที่มา: [spec.md ภาคผนวก E](spec.md#ภาคผนวก-e--task-ที่-pm-เพิ่มรอบ-2026-09-09-hp-06-hp-07) · ⚠️ ยังมี 7 ข้อ (33–39) ที่ต้องให้ PM เคลียร์ — ส่วนที่เขียนไว้นี่คือสิ่งที่ทำได้เลยโดยไม่ขัดกับคำตอบใด ๆ

### 13.1 แยก "ปิดเอง" ออกจาก "ไม่มีข้อมูล"
สามสถานะที่หน้าตาเหมือนกันสำหรับผู้ใช้ (ไม่มีอากาศแสดง) แต่คนละเหตุผล — snapshot ต้องบอกให้แยกได้:

| สถานะ | field | ข้อความที่หน้าบ้านแสดง |
|---|---|---|
| owner ปิด location เอง | `location_enabled: false` | "Workspace ปิดการแสดงสภาพอากาศไว้" (owner เห็นปุ่มเปิดกลับ) |
| ยังไม่เคยตั้ง location | `location: null` | "ยังไม่ได้ตั้งสถานที่ของ workspace" |
| ตั้งแล้วแต่ provider ไม่ครอบคลุม | `weather_coverage: "none"` | "ยังไม่รองรับข้อมูลอากาศในพื้นที่นี้" ([§12.2](#122-weather-ที่ขาดในบางประเทศ--ต้อง-degrade-ไม่ใช่-error)) |

**ห้ามยุบสามอันนี้เป็น flag เดียว** — owner ที่ปิดเองต้องได้ทางกลับ ส่วนคนที่อยู่ในประเทศที่ไม่รองรับกดเปิดยังไงก็ไม่มีข้อมูล

### 13.2 ปิดแล้วต้องหยุดยิง provider จริง ไม่ใช่ซ่อน UI
```go
// อยู่ก่อน cache lookup ใน EnvironmentService.Snapshot()
if !ws.EnvLocationEnabled {
    return snapshotDisabled(ws), nil   // ไม่ยิง provider · ไม่กิน quota · ไม่เขียน cache
}
```
- poller ของ weather ต้องข้าม workspace ที่ปิดไว้ตอนสร้างชุด cell ที่จะ fetch
- **เก็บ `env_lat` / `env_lng` / `env_timezone` / `env_place_label` ไว้เสมอ** — AC บอก "เปิดใหม่ location กลับมาทันที" ⇒ ปิดคือหยุดใช้ ไม่ใช่ล้างค่า
- เปิดกลับ → fetch ทันที (bypass TTL 1 ครั้ง) แล้ว publish `environment_changed` เหมือน flow ของ EC-03

### 13.3 alert notification toggle
`env_alerts` ที่มีอยู่แล้วใน [§8](#8-db-migration-98) คือ toggle ของ HP-07 — **ถ้า PM ยืนยันว่าเป็นตัวเดียวกับ toggle ที่ 3 ของ HP-01 ก็ไม่ต้องเพิ่ม field ใหม่** (ข้อ 33)
พฤติกรรมตาม AC ของ HP-07: ปิดแล้ว **widget ยังทำงาน** (ยังยิง weather) แต่:
- ไม่ publish `weather_alert` ให้ workspace นั้น
- ไม่สร้าง notification เข้า bell panel
- ⚠️ **ต้องถาม PM ว่ารวม alert ระดับ emergency ด้วยหรือไม่** — EC-02 กำหนดว่าแดง "ปิดไม่ได้" ด้วยเหตุผลความปลอดภัย ซึ่งขัดกับการให้ owner ปิด alert ทั้งหมดได้ (ยังไม่ใส่ไว้ในข้อ 33–39 เพราะเพิ่งเห็นตอนเขียน design — **เพิ่มเป็นข้อ 40**)

### 13.4 สิทธิ์
ทั้งสอง toggle เป็น workspace-level ⇒ ตรวจ `tb_workspace.owner_id` เหมือน `PUT settings` · non-owner เรียก = 403 และ **หน้าบ้านต้องไม่แสดง toggle นี้ให้ member เห็น** (ข้อ 34 ยังค้างว่าจะวาง UI ที่ไหน)


---

## 14. การโหลด asset ของ environment (GIF pixel art)

> asset จริงที่ได้รับ: [ux-ui-plan.md §7.2](ux-ui-plan.md#72-asset-ที่ได้รับแล้ว-2026-09-09--storagefeature--environment-time-of-day--weather--virtual-office-map) · ⚠️ **รอไฟล์ขนาด 1× ก่อนเริ่ม C3** (ข้อ 48)

### 14.1 GIF ใน Pixi ต้องนำเข้าแบบ side-effect
```ts
import "pixi.js/gif"                       // ลงทะเบียน loader ของ GIF
const src = await Assets.load<GifSource>(url)
const sprite = new GifSprite({ source: src, animationSpeed: 1, loop: true })
```
ใช้ GifSource ตัวเดียวสร้าง GifSprite หลายตัวได้ (เมฆ/ดาว/หิมะหลายชิ้น) — **อย่า `Assets.load` ซ้ำต่อชิ้น**

### 14.2 งบหน่วยความจำ — บังคับ
- โหลด **เฉพาะ condition ปัจจุบัน** เท่านั้น ไม่ preload ทั้งชุด (บทเรียนจาก asset burst ที่ทำให้ผู้ใช้บ่นว่า "กินเน็ตแล้วว้าป")
- เปลี่ยน condition → `Assets.unload()` ตัวเก่าก่อนโหลดตัวใหม่
- เพดานที่ตั้งไว้: asset ของ environment รวม **≤ 24 MB** ในหน่วยความจำ ณ เวลาใดก็ตาม — ถ้าไฟล์ 1× มาแล้วยังเกิน ให้ลดจำนวนชิ้นบนฉาก ไม่ใช่ลดคุณภาพ
- ปิด time-of-day/weather ใน setting → **unload ทั้งเลเยอร์** ไม่ใช่แค่ `visible = false`

### 14.3 การขยายภาพ
pixel art ต้องคมตาม grid ของแมพ:
```ts
texture.source.scaleMode = "nearest"
```
และใช้ **world scale เดียวกับแมพ** (ห้าม fit-to-box ต่อชิ้น) — กฎเดียวกับอาร์ตของ pet

### 14.4 หิมะ / หมอก ที่ออกแบบมาให้ต่อกัน
`snow1..4` เป็นแถบแนวตั้ง (เช่น 70×1600) และ `fog` เป็นแถบแนวนอน (2240×480) ⇒ วางซ้ำเป็นแถวแล้วให้ GIF วิ่งเอง **ไม่ต้องเขียน particle system** — ลดงานของ C3 ลงมาก (แก้จากแผนเดิมที่จะใช้ `ParticleContainer`)


---

## 15. Feature flag — `ENVIRONMENT_ENABLED` (implemented A3)

> ผู้ใช้สั่งเพิ่มเมื่อ 2026-09-09: "ทำเป็นแบบ env ที่เปิดปิดได้"

| | ค่า |
|---|---|
| env var | `ENVIRONMENT_ENABLED` (ฝั่ง API, runtime — เปลี่ยนแล้ว restart pod ไม่ต้อง rebuild) |
| default | **`false`** — ตั้งใจให้ปิด เพราะทุก provider call มีค่าใช้จ่าย environment ที่ไม่เคยตั้งค่าต้องไม่ยิงเลย |
| คู่กับฝั่ง app | `NEXT_PUBLIC_ENVIRONMENT` (build-time, C1) — คนละตัว เพราะฝั่ง Next ต้อง bake ตอน build |

**ปิดแล้วเกิดอะไร**

| จุด | พฤติกรรม |
|---|---|
| `GET .../environment` | ตอบ 200 พร้อม `feature_enabled: false` · ไม่มี `sun` / `stage` / `weather` · coverage = `none` ⇒ client ที่ build มาพร้อมฟีเจอร์จะเงียบ ไม่ error |
| `PUT .../environment` | **404 `FEATURE_DISABLED`** — ไม่ใช่ 403 เพราะไม่ใช่เรื่องสิทธิ์ แต่ฟีเจอร์ไม่มีอยู่ใน environment นี้ |
| weather fetch | ไม่ยิงเลย |
| resolve timezone / reverse geocode ตอน owner บันทึก | ไม่ยิงเลย |
| poller (A4) | ต้องเช็ค flag ก่อนเข้า loop ด้วย |

มี test บังคับไว้ 3 จุด: `WeatherFor` ไม่เรียก provider · `resolveLocation` ไม่เรียก resolver ทั้งที่มี key · `UpdateSettings` คืน `ErrEnvironmentDisabled`

---

## 16. สิ่งที่ implement จริงใน A3 (ต่างจาก §4 ที่ร่างไว้)

| ร่างไว้ใน §4 | ที่ทำจริง |
|---|---|
| `env:wx:<cell>` TTL 60 นาที | ตรงตามร่าง (`WeatherCacheTTL`) |
| single-flight `SETNX env:lock:<cell>` 20s | ตรงตามร่าง — **และปล่อย lock ทันทีเมื่อจบ** ไม่รอ TTL |
| quota guard soft cap 95% | ตรงตามร่าง (`GoogleMonthlySoftCap = 9500`, key `env:quota:<provider>:<YYYY-MM>` หมดอายุ 40 วัน) |
| stale ≤ 3 ชม. จาก `tb_environment_snapshot` | ตรงตามร่าง (`WeatherStaleMax`) |
| เกิน 3 ชม. → default Clear | ตรงตามร่าง + **`stale = true` เสมอ** เพื่อไม่ให้ค่า default ถูกเข้าใจว่าเป็นค่าสด |
| — | **เพิ่ม:** ทุกฟังก์ชันของ cache ทน nil (ไม่มี Redis = ไม่มีอะไร cache, lock ผ่านตลอด, quota อ่านเป็น 0) ตาม pattern `ObstacleCache`/`ZoneCache` |
| — | **เพิ่ม:** `s.db == nil` guard ในทั้ง save/load snapshot — test จับ panic ได้ก่อนขึ้น dev |
| — | **เพิ่ม:** `WeatherFor` ไม่คืน error เลย (คืน nil หรือค่า stale) เพราะ EP-01 ห้ามให้แผนที่พังตามการล้มของ provider |


---

## 17. Alert scope: country vs grid cell (A5, migration 99)

สามแหล่งมี granularity ไม่เท่ากัน — และ §6/§8 ที่ร่างไว้แรกโมเดลไว้แค่แบบเดียว:

| แหล่ง | รูปแบบ query | เก็บอย่างไร | เหตุผล |
|---|---|---|---|
| TMD | feed ใบเดียวทั้งประเทศ | `country='TH'`, `cell_key=NULL` | ประกาศเป็น prose ระดับประเทศ/ภาค ไม่มี geometry |
| GDACS | feed ใบเดียวทั้งโลก | 1 แถวต่อประเทศ, `cell_key=NULL` | `affectedcountries[].iso2` |
| **Google** | **per-point** (`publicAlerts:lookup`) | **`cell_key` = grid cell ที่ยิง** | ถ้าเก็บต่อ country ประกาศของกรุงเทพจะโผล่ที่เชียงใหม่ |

snapshot อ่านทั้งสอง scope: `WHERE country=$1 AND (cell_key IS NULL OR cell_key=$2)`
⇒ อ่านแค่ country จะเห็นประกาศของเมืองอื่น · อ่านแค่ cell จะไม่เห็นประกาศระดับชาติ

**ผลพลอยได้:** ไม่ต้องทำ point-in-polygon เลย (ต่างจากที่ [task-breakdown A5](task-breakdown.md#a5--featapi-add-google-weather-alerts-and-coverage-routing) เดาไว้) เพราะ per-point query ตอบให้ตรงพิกัดแล้ว — polygon เก็บไว้แสดงผลเท่านั้น

**ต้นทุน:** Google alerts กินโควตา **ต่อ cell** ไม่ใช่ต่อประเทศ ⇒ per-cell interval 15 นาที (เก็บใน Redis) + soft cap เดียวกับ weather · cell มาจาก `tb_workspace` ที่เปิดใช้จริง group ด้วย grid 0.25° เดียวกัน ⇒ 1 metro = 1 call

---

## 18. ตัวเลขในการ์ดไม่ได้มาจาก broadcast (C4)

`environmentSignature` (§ broadcast, A6) **ตัด temperature / humidity / wind / precipitation ออกโดยเจตนา** เพราะไม่ใช่ค่าที่วาดบนแมพ ถ้าใส่เข้าไป อุณหภูมิที่ขยับ 0.1° จะ push snapshot ใหม่ให้ทุก member ทั้ง workspace ทุกครั้งที่ refresh cache — ต้นทุนย้ายจาก provider มาที่ zyra-api + ws แทน โดยไม่มีอะไรบนจอเปลี่ยน

ผลข้างเคียงคือ **ตัวเลขในการ์ดจะค้างอยู่ที่ค่าตอน member เข้าห้อง** จนกว่าจะมี event ที่เปลี่ยนค่าที่วาด (condition / stage / coverage / alert)

**ทางแก้ที่เลือก:** เปิด panel = refetch หนึ่งครั้ง (`useEnvironment().refresh()`)

| ทางเลือก | ทำไมไม่เอา |
|---|---|
| ใส่ค่าตัวเลขเข้า signature | push ทุกรอบ refresh × ทุก member เพื่อเลขที่มองบนแมพไม่เห็น |
| polling ฝั่ง client | ต้นทุน N member × ทุก tick ทั้งที่ไม่มีใครเปิดดู — เหตุผลเดียวกับที่ C1 ตัด polling ออก |
| ปล่อยให้ค้าง | การ์ดบอกอุณหภูมิผิดโดยไม่มีอะไรบอกว่าเก่า (badge `stale` ดูจาก cache ฝั่ง server ไม่ใช่ความสดของ snapshot ที่ client ถืออยู่) |

refetch ตอนเปิดถูกที่สุดเพราะ **cell นั้น cache ไว้แล้ว** (TTL 60 นาที) ⇒ ปกติไม่มี provider call เกิดขึ้นเลย มีแค่ query DB/Redis หนึ่งครั้ง ณ วินาทีที่มีคนเปิดดูจริง

### 18.1 `precip_pct` เป็น pointer

การ์ดใน design มีแถว `Precipitation:` ⇒ เพิ่ม `WeatherSnapshot.PrecipPct *int` อ่านจาก `precipitation.probability.percent` ของ Google

เป็น **pointer ไม่ใช่ `int`** เพราะ `0` มีความหมายจริง ("ไม่มีโอกาสฝน") ถ้าใช้ zero value provider ที่ไม่รายงานฟิลด์นี้จะกลายเป็น "0% โอกาสฝน" ซึ่งอ่านผิดได้ตอนฝนตกอยู่ · หน้าบ้านแสดง `—` เมื่อเป็น nil
