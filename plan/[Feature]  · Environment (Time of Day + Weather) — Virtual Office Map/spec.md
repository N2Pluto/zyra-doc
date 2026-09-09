# SC-ENV-01 · Environment (Time of Day + Weather) — Virtual Office Map

> **สถานะ (2026-09-09):** **implement แล้ว 10/17 PR — Track A (zyra-api A1–A6 + `precip_pct`) + B (zyra-ws B1) ครบ · ฝั่ง app ทำ C1+C2+C4 แล้ว (แสงตามเวลา + widget สภาพอากาศขึ้นจอ)** · mig 98/99/100 รันบน dev · PR draft api#108 / ws#64 / app#336 · เริ่มต่อที่ C7 หรือ C3 · รายละเอียด + วิธีกลับมาทำต่อดู [progress.md](progress.md)
> **MD อนุมัติแหล่งข้อมูลแล้ว 2026-09-09 (Google + TMD + GDACS · Open-Meteo เลื่อน)** · **PM เพิ่ม HP-06/HP-07 เมื่อ 2026-09-09 — ดู [ภาคผนวก E](#ภาคผนวก-e--task-ที่-pm-เพิ่มรอบ-2026-09-09-hp-06-hp-07)** — ดู [ภาคผนวก D](#ภาคผนวก-d--มติ-md-2026-09-09-และขอบเขตรอบแรก) · ยังไม่เริ่ม implement
> **วันที่ถอด:** 2026-09-08 · **ClickUp:** [86d3p6098](https://app.clickup.com/t/86d3p6098) (`in progress`)
> **Repo ที่กระทบ (คาด):** `zyra-app` (Pixi VO scene + settings UI), `zyra-api` (workspace location/env settings + weather fetcher), `zyra-ws` (broadcast weather/alert), `zyra-notifications` (weather alert ใน bell panel)
> **เนื้อหาส่วนหลักคือ spec ตามที่ ClickUp เขียนไว้เท่านั้น** ยังไม่ผ่านการ verify กับโค้ดจริง และมีข้อขัดแย้งในตัว spec เอง — ดู [§ ข้อขัดแย้ง & คำถามที่ต้องเคลียร์](#ข้อขัดแย้ง--คำถามที่ต้องเคลียร์-ก่อน-implement)
> **[ภาคผนวก A](#ภาคผนวก-a--provider-capability-check-ตรวจจริง-2026-09-09)** = ผลตรวจ provider จริง (ยิง API เอง 2026-09-09): Open-Meteo ทำได้แค่ weather + timezone · **ไม่มี alert, ไม่มี reverse-geocode, ไม่มี webhook** → ต้องมี provider เสริม
> **[ภาคผนวก B](#ภาคผนวก-b--แนวทางทดแทนส่วนที่-open-meteo-ไม่มี-ตรวจจริง-2026-09-09)** = ทางเลือกทดแทน · **[ภาคผนวก C](#ภาคผนวก-c--รองรับทั่วโลก-ตรวจจริง-2026-09-09)** = โจทย์ global ซึ่ง **ล้มข้อสรุป "Google เจ้าเดียวจบ" ของภาคผนวก B** (alerts ของ Google มีแค่ ~30/195 ประเทศ และ JP/KR/VN/CN ไม่มีข้อมูลอากาศเลย)

---

## Overview & Goal

Virtual Office map เปลี่ยน visual ตาม **เวลาจริง** (Time of Day) และ **สภาพอากาศจริง** (Real-time Weather) ของ location ที่ Workspace Owner กำหนด

**Key Design**

- Time of Day: เปลี่ยน lighting overlay บน map (เช้า / กลางวัน / เย็น / กลางคืน)
- Weather: เปลี่ยน weather effect overlay บน map (ฝน / แดด / เมฆ / พายุ)
- Weather Alert: แจ้งเตือนภัยธรรมชาติใน in-app notification

**Module:** Virtual Office — Project Zyra
**Persona:** Workspace Member (ทุกคนเห็น) · Workspace Owner (ตั้งค่า location)
**Priority:** Normal · **Tag:** `client` · **Assignees:** P A, Ponlawat Lueakaew

---

## Location Policy

- **ยึดตาม location ของ Workspace Owner** — ไม่ใช่ของ user แต่ละคน
- Owner ตั้งค่า location ใน Workspace Settings (จังหวัด หรือ lat/lng — subtask HP-01 ระบุว่า **ใช้แบบปักหมุด**)
- ทุกคนใน workspace เห็น environment เดียวกัน (based on owner's location)

---

## Scenario Index (12 subtasks)

| # | Scenario | Type | Priority | ClickUp status | ClickUp |
|---|---|---|---|---|---|
| HP-01 | Owner ตั้งค่า Location ของ Workspace | Happy Path | High | pending | [86d3p60cz](https://app.clickup.com/t/86d3p60cz) |
| HP-02 | Time of Day เปลี่ยน Visual บน Map | Happy Path | High | pending | [86d3p60ft](https://app.clickup.com/t/86d3p60ft) |
| HP-03 | Weather Real-time เปลี่ยน Visual บน Map | Happy Path | High | pending | [86d3p60jd](https://app.clickup.com/t/86d3p60jd) |
| HP-04 | Weather Alert แจ้งเตือนภัยธรรมชาติ | Happy Path | High | pending | [86d3p60p2](https://app.clickup.com/t/86d3p60p2) |
| HP-05 | User ปิด Environment Effects เอง (Personal Preference) | Happy Path | Normal | pending | [86d3p60rh](https://app.clickup.com/t/86d3p60rh) |
| HP-06 | Owner ปิด Workspace Location | Happy Path | *(ไม่ระบุ)* | pending | [86d4a9694](https://app.clickup.com/t/86d4a9694) |
| HP-07 | Owner ปิด Workspace Location Notification | Happy Path | *(ไม่ระบุ)* | pending | [86d4a99uj](https://app.clickup.com/t/86d4a99uj) |
| EP-01 | API สภาพอากาศ ไม่ตอบสนอง / Timeout | Error Path | High | pending | [86d3p60v1](https://app.clickup.com/t/86d3p60v1) |
| EP-02 | Location นอกประเทศไทย / ไม่มีใน TMD Database | Error Path | Normal | **Closed** | [86d3p60xe](https://app.clickup.com/t/86d3p60xe) |
| EC-01 | Members คนละ Timezone — Time of Day ยึด Workspace Location | Edge Case | Normal | pending | [86d3p60z3](https://app.clickup.com/t/86d3p60z3) |
| EC-02 | Weather Alert ระดับ Emergency (แดง) — ปิดไม่ได้ | Edge Case | Normal | pending | [86d3p6116](https://app.clickup.com/t/86d3p6116) |
| EC-03 | Owner เปลี่ยน Location กลางคัน — Members เห็นทันที | Edge Case | Normal | pending | [86d3p6124](https://app.clickup.com/t/86d3p6124) |

> EP-02 ถูกปิดใน ClickUp (2026-10-01 ตาม `date_closed`) แต่ **เนื้อหายังถูกเก็บไว้ครบในไฟล์นี้** เพราะยังไม่ได้ระบุเหตุผลว่าปิดเพราะทำเสร็จ หรือปิดเพราะ out-of-scope — ต้องถาม PM

---

## Weather API Integration

### ตามที่เขียนใน parent task (ฉบับเดิม)

| ลำดับ | Provider | ขอบเขต | รอบอัปเดต |
|---|---|---|---|
| Primary | กรมอุตุนิยมวิทยา (TMD) — `https://data.tmd.go.th/api/` | สภาพอากาศปัจจุบัน + คำเตือนภัยธรรมชาติ (ไทยเท่านั้น) | ทุก 1 ชั่วโมง |
| Fallback | OpenWeatherMap | ใช้เมื่อ TMD ไม่ตอบสนอง หรือ location นอกไทย | ทุก 30 นาที |

### ตามที่ subtask ถูกแก้ทีหลัง (HP-01 / HP-03 / HP-04)

- HP-01: "Preview weather หลังเลือก location: แสดงข้อมูลปัจจุบันจาก **Source : Open-Meteo**" และ "ถ้า location นอกประเทศไทย: ใช้ **Source : Open-Meteo** อัตโนมัติ (แจ้ง user)"
- HP-03: "Weather fetch ทุก **60 นาที** จาก **Open-Meteo API** (cron job server-side)"
- HP-04: "Server poll **Source : Open-Meteo** API ทุก **15 นาที** ตรวจ weather alerts"

→ **ต้องเคลียร์ว่า provider จริงคืออะไร** (ดู § ข้อขัดแย้ง ข้อ 1)

---

## Time of Day Stages

| Stage | เวลา (ICT) | Overlay | Effect |
|---|---|---|---|
| 🌅 Dawn (รุ่งเช้า) | 05:00–07:00 | `rgba(255, 160, 50, 0.25)` | warm orange tint · แสงยังน้อย |
| ☀️ Morning (เช้า) | 07:00–12:00 | ไม่มี overlay | แสงปกติ bright |
| 🌤 Afternoon (บ่าย) | 12:00–17:00 | `rgba(255, 240, 180, 0.15)` | warm bright · แสงสว่างจัด |
| 🌇 Evening (เย็น) | 17:00–19:00 | `rgba(255, 100, 50, 0.30)` | sunset orange-purple |
| 🌙 Night (กลางคืน) | 19:00–05:00 | `rgba(20, 30, 80, 0.55)` | dark blue overlay |

---

## Weather Conditions → Map Effects

| Condition | Map Effect (สรุปจาก parent) |
|---|---|
| Clear / Sunny | แสงปกติ ไม่มี overlay พิเศษ |
| Cloudy | overlay สีเทาอ่อน ลด brightness |
| Rain / Drizzle | rain particle effect + เมฆ overlay |
| Thunderstorm | rain heavy + lightning flash animation |
| Fog / Haze | fog overlay ลด visibility |
| Windy | wind particle effect เบา ๆ |

ค่าตัวเลขต่อ effect อยู่ใน [HP-03](#hp-03--weather-real-time-เปลี่ยน-visual-บน-map)

---

# Subtask Detail (ถอดครบทุก task)

## HP-01 · Owner ตั้งค่า Location ของ Workspace

**Type:** Happy Path · **Persona:** Workspace Owner · **Priority:** High
**Pre-condition:** Owner เข้า Workspace Settings

### Scenario Steps

1. Owner เข้า **Workspace Settings → Environment**
2. เห็น section "Environment Settings" พร้อม toggle on/off
3. กด **"ตั้งค่า Location"**
4. เลือกวิธีระบุ location: (ใช้แบบปักหมุด)
5. Preview แสดง: ชื่อ location ที่เลือก + weather ปัจจุบัน (ถ้า API พร้อม)
6. กด "บันทึก" → location ถูกบันทึก, ระบบ fetch weather ทันที
7. Virtual Office map เริ่มแสดง environment effects

### Settings Page Layout (จาก ClickUp)

```
⚙️ Environment Settings

Location ของ Workspace:
  📍 Bangkok, Thailand (13.7563° N, 100.5018° E)
  [เปลี่ยน Location]

Effects:
  ✅ Time of Day lighting          [toggle]
  ✅ Weather visual effects        [toggle]
  ✅ Weather Alerts notification   [toggle]

Current Weather Preview:
  🌤 Partly Cloudy · 32°C · ความชื้น 75%
  ข้อมูลจาก: กรมอุตุนิยมวิทยา
  อัปเดตล่าสุด: 14:00 ICT

[บันทึก]
```

### Acceptance Criteria

- เฉพาะ **Workspace Owner** ตั้งค่า location ได้
- ปักหมุด location ได้
- Preview weather หลังเลือก location: แสดงข้อมูลปัจจุบันจาก Source : Open-Meteo
- บันทึกแล้ว: ทุก member ใน workspace เห็น environment ใหม่ภายใน **5 วินาที**
- Toggle แยก: Time of Day / Weather Effects / Weather Alerts
- ถ้า location นอกประเทศไทย: ใช้ Source : Open-Meteo อัตโนมัติ (แจ้ง user)

### UX/UI

[Figma node `4635-149039`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4635-149039)

---

## HP-02 · Time of Day เปลี่ยน Visual บน Map

**Type:** Happy Path · **Persona:** Workspace Member ทุกคน · **Priority:** High
**Pre-condition:** Time of Day enabled, Workspace มี location ตั้งค่าแล้ว

### Scenario Steps

1. User เข้า Virtual Office map
2. Engine ตรวจสอบ **เวลาปัจจุบัน** ตาม timezone ของ location ที่ตั้งไว้
3. ใช้ lighting overlay บน map ตาม Time of Day stage
4. Transition: เปลี่ยน stage → lighting เปลี่ยนแบบ **smooth fade (30 วินาที)**
5. ทุกคนใน workspace เห็น lighting เดียวกันพร้อมกัน

### Time of Day Visual Spec

ดู [§ Time of Day Stages](#time-of-day-stages) — ค่า overlay rgba ทั้ง 5 stage อยู่ในตารางนั้น

### Acceptance Criteria

- Overlay เปลี่ยนตาม timezone ของ **workspace location** — ไม่ใช่ timezone ของ user
- Transition smooth: fade in/out ใช้เวลา **30 วินาที** ไม่กระตุก
- Overlay แสดงเป็น **canvas layer บน Phaser.js** เหนือ map แต่ใต้ UI (z-index = UI-1) — ⚠️ ดู § ข้อขัดแย้ง ข้อ 2 (VO จริงใช้ **Pixi**)
- ทุกคน sync: lighting เดียวกันพร้อมกัน (**ดึงเวลาจาก server ไม่ใช่ client clock**)
- Night mode: avatar ยังเดินได้ปกติ — lighting ไม่กระทบ gameplay
- User ที่ปิด effects: map แสดงแบบ default ไม่มี overlay

### UX/UI

[Figma node `4635-175947`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4635-175947)

---

## HP-03 · Weather Real-time เปลี่ยน Visual บน Map

**Type:** Happy Path · **Persona:** Workspace Member ทุกคน · **Priority:** High
**Pre-condition:** Weather Effects enabled, location ตั้งค่าแล้ว

### Scenario Steps

1. Server fetch weather จาก Open-Meteo API ทุก **60 นาที**
2. Weather condition เปลี่ยน (เช่น clear → rain)
3. Server broadcast weather update ไปยังทุก member ใน workspace
4. Client apply weather effect บน map ทันที
5. Weather widget เล็ก ๆ แสดงมุมขวาบน map: icon + อุณหภูมิ

### Weather Effects Spec

**🌧 Rain / Drizzle**

```yaml
particle system: rain drops ตกลงมาจากบน
เส้น rain: สีขาวโปร่งใส opacity 0.3
angle: 15° (ลมพัดเล็กน้อย)
density: drizzle = 50 drops/s, rain = 200 drops/s
map overlay: blue-gray tint rgba(100, 120, 150, 0.2)
```

**⛈ Thunderstorm**

```yaml
rain heavy: 500 drops/s
lightning flash: random interval 5–15 วินาที
flash: white overlay rgba(255,255,255,0.8) ค้าง 80ms
thunder sound: optional (user toggle)
```

**☁️ Cloudy**

```
overlay: gray rgba(150, 150, 150, 0.15)
ไม่มี particle effects
```

**🌫 Fog / Haze**

```
overlay: white fog rgba(255, 255, 255, 0.35)
ขอบ map blur effect เล็กน้อย
```

**💨 Windy**

```yaml
wind particle: leaf/dust elements เคลื่อนไหวขวา
```

### Weather Widget (Map Corner)

```
┌──────────────────┐
│ 🌧 31°C  Bangkok │
│ ฝนตกเล็กน้อย      │
│ ความชื้น 82%      │
│ แหล่ง: กรมอุตุฯ    │
└──────────────────┘
```

### Acceptance Criteria

- Weather fetch ทุก **60 นาที** จาก Open-Meteo API (cron job server-side)
- Weather เปลี่ยน: broadcast ให้ทุก member ใน workspace ทันที
- Rain particles แสดงบน **canvas layer บน Phaser.js** (ไม่ใช่ CSS) — ⚠️ ดู § ข้อขัดแย้ง ข้อ 2
- Weather widget มุมขวาบน map: แสดงได้โดยไม่รบกวน gameplay
- กด widget: เปิด weather detail popup (อุณหภูมิ, ความชื้น, ลม, แหล่งข้อมูล)
- User ปิด weather effects: particle หายแต่ widget ยังแสดง
- Performance: rain particles ไม่ทำให้ FPS ต่ำกว่า **30 FPS** บน mid-range device

### UX/UI

[Figma node `4646-531699`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4646-531699)

---

## HP-04 · Weather Alert แจ้งเตือนภัยธรรมชาติ

**Type:** Happy Path · **Persona:** Workspace Member ทุกคน · **Priority:** High
**Pre-condition:** Weather Alerts enabled, location ตั้งค่าแล้ว

### Scenario Steps

1. Server poll Source : Open-Meteo API ทุก **15 นาที** ตรวจ weather alerts ของ location นั้น
2. Open-Meteo ออกประกาศเตือนภัย (เช่น พายุ, น้ำท่วม, คลื่นสูง)
3. Server broadcast alert ไปยังทุก member ใน workspace
4. **Alert Banner** แสดงบน HUD ของ Virtual Office ทุกคน
5. Map effect เปลี่ยนเป็น severe weather (thunderstorm / dark overlay)
6. Notification เก็บใน bell panel

### Alert Severity Levels

| Level | สี | Description |
|---|---|---|
| 🟡 Watch | เหลือง | ระวัง — อาจเกิดสภาพอากาศเลวร้าย |
| 🟠 Warning | ส้ม | เตือน — สภาพอากาศเลวร้ายกำลังจะเกิด |
| 🔴 Emergency | แดง | ฉุกเฉิน — เกิดขึ้นแล้ว อันตราย |

### Alert Banner Layout (All Members)

```
┌────────────────────────────────────────────────────┐
│ 🔴  ประกาศเตือนภัย กรมอุตุนิยมวิทยา            [X]  │
│     พายุฝนฟ้าคะนองและลมกระโชกแรงในกรุงเทพมหานคร   │
│     "ประชาชนควรอยู่ในที่ปลอดภัย"                    │
│     ออกประกาศ: 14:30 ICT  [อ่านเพิ่มเติม ↗]        │
└────────────────────────────────────────────────────┘
```

### Acceptance Criteria

- Poll Source : Open-Meteo ทุก **15 นาที** สำหรับ alerts
- Alert ใหม่: broadcast ให้ทุก member ใน workspace ทันที
- Alert Banner แสดงบน Virtual Office HUD ทุกคน
- Severity สีชัดเจน: เหลือง / ส้ม / แดง
- Emergency (แดง): banner **ปิดไม่ได้** จนกว่าจะหมดประกาศ (safety)
- Watch/Warning: กด X ปิดได้ แต่ notification ยังอยู่ใน bell panel
- "อ่านเพิ่มเติม": link ไปหน้า TMD alert โดยตรง
- Alert หมดอายุ: banner หายอัตโนมัติ map effect กลับปกติ
- Deduplication: alert เดิมไม่ส่งซ้ำ (ตรวจ `alert_id` จาก Source : Open-Meteo)

### UX/UI

[Figma node `4654-536054`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4654-536054)

---

## HP-05 · User ปิด Environment Effects เอง (Personal Preference)

**Type:** Happy Path · **Persona:** Workspace Member (preference ส่วนตัว) · **Priority:** Normal
**Pre-condition:** Environment effects เปิดอยู่ใน workspace

### Scenario Steps

1. User กด **⚙️ Settings** บน Virtual Office HUD หรือ User Preferences
2. เห็น section **"Visual Effects"**
3. User toggle ปิด: Time of Day lighting / Weather effects (particles) / หรือทั้งคู่พร้อมกัน "ปิดทั้งหมด"
4. Map เปลี่ยนเป็น default lighting ทันที (ไม่มี overlay)
5. Setting บันทึกใน user preferences (persist ข้าม session)

### User Preferences Layout

```
⚙️  Visual Effects (Personal)

  ✅ Time of Day lighting          [toggle]
  ✅ Weather visual effects        [toggle]
  [ปิดทั้งหมด]

หมายเหตุ: การตั้งค่านี้เป็นการตั้งค่าส่วนตัว
ไม่กระทบกับ member คนอื่น
```

### Acceptance Criteria

- User preference แยกจาก Workspace settings — ปิดเฉพาะตัวเองได้
- ปิด Time of Day: map แสดง default lighting (**Morning stage ตลอด**)
- ปิด Weather effects: particles หาย overlay สี weather หาย — แต่ weather widget ยังแสดง
- Setting persist: reload / session ใหม่ ยังคง preference เดิม
- เปิดใหม่: effects กลับมาทันที ปรับตามเวลาและ weather ปัจจุบัน
- Weather Alert: **ไม่สามารถปิดได้จาก user preference** — เป็น workspace-level setting (Owner เท่านั้นปิด)
- Performance mode: ปิด effects → FPS เพิ่มขึ้นสังเกตได้บน low-end device

### UX/UI

[Figma node `4839-34795`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4839-34795)

---

## HP-06 · Owner ปิด Workspace Location

**Type:** Happy Path · **Persona:** Workspace Owner · **Priority:** *(ClickUp ไม่ได้ตั้ง)* · **เพิ่มเมื่อ** 2026-09-09
**Pre-condition:** Workspace Location เปิดอยู่ใน workspace

### Scenario Steps

1. User กด **⚙️ Settings** บน Virtual Office HUD หรือ User Preferences
2. เห็น section **"Workspace location"**
3. Owner toggle ปิด: Workspace location
4. Workspace weather เปลี่ยนเป็นไม่มีข้อมูลแสดง และ shotcut หน้าหลักไม่แสดง

### Acceptance Criteria

- Owner preference แยกจาก Workspace settings — **ปิดทั้ง workspace**
- ปิด Weather location: **Weather widget หาย**
- Setting persist: reload / session ใหม่ ยังคง preference เดิม
- เปิดใหม่: location กลับมาทันที ปรับตามเวลาและ weather ปัจจุบัน

### UX/UI

[Figma node `4872-587869`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4872-587869) — ⚠️ **node เดียวกับ EP-01** (ดู [ภาคผนวก E](#ภาคผนวก-e--task-ที่-pm-เพิ่มรอบ-2026-09-09-hp-06-hp-07) ข้อ 4)

---

## HP-07 · Owner ปิด Workspace Location Notification

**Type:** Happy Path · **Persona:** Workspace Owner · **Priority:** *(ClickUp ไม่ได้ตั้ง)* · **เพิ่มเมื่อ** 2026-09-09
**Pre-condition:** Workspace Location เปิดอยู่ใน workspace

### Scenario Steps

1. User กด **⚙️ Settings** บน Virtual Office HUD หรือ User Preferences
2. เห็น section **"Workspace Alert Notification"**
3. Owner toggle ปิด: Workspace Alert Notification
4. Workspace weather เปลี่ยนเป็นไม่มีข้อมูลแสดง และ shotcut หน้าหลักไม่แสดง — ⚠️ **ประโยคนี้ขัดกับ AC ของตัวเอง** (AC บอกว่า widget ยังแสดงสภาพอากาศอยู่) น่าจะ copy มาจาก HP-06

### Acceptance Criteria

- Owner preference แยกจาก Workspace settings — **ปิดทั้ง workspace**
- ปิด Weather Alert Notification: **Weather Widget ยังบอกสภาพอากาศ แต่ไม่มี Alert Notification แจ้งเมื่อเกิดภัย**
- Setting persist: reload / session ใหม่ ยังคง preference เดิม
- เปิดใหม่: Alert Notification กลับมาทันที ตามเวลาและ weather ปัจจุบัน

### UX/UI

[Figma node `4872-593891`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4872-593891)

---

## EP-01 · API สภาพอากาศ ไม่ตอบสนอง / Timeout

**Type:** Error Path · **Priority:** High
**Trigger:** API down หรือ response time > 5 วินาที

### Scenario Steps

1. Server fetch API → timeout หรือ error 5xx
2. Server retry **3 ครั้ง** ด้วย exponential backoff (30s → 2m → 5m)
3. ถ้า retry ล้มเหลวทั้งหมด → **fallback ไป OpenWeatherMap**
4. ถ้า fallback ก็ล้มเหลว → ใช้ **cache ล่าสุด** ที่มีอยู่

### Fallback Strategy

```yaml
Priority 1: TMD API (กรมอุตุนิยมวิทยา)
     ↓ ถ้า fail
Priority 2: OpenWeatherMap API
     ↓ ถ้า fail
Priority 3: Cache ล่าสุด (stale data)
     ↓ ถ้า cache หมดอายุ (> 3 ชั่วโมง)
Priority 4: Default state (Clear/Sunny)
```

### Acceptance Criteria

> ⚠️ ต้นฉบับ ClickUp ใช้คำว่า "Operator" แทนชื่อ provider ในหลายบรรทัด (น่าจะเป็น find-replace ที่พลาด) — คงข้อความไว้ตามต้นฉบับ พร้อมกำกับสิ่งที่น่าจะหมายถึง

- Operator fail: auto-fallback Operator ภายใน **30 วินาที** — *(น่าจะ: primary fail → fallback provider ภายใน 30 วินาที)*
- Weather widget: แสดง source เปลี่ยนเป็น "Operator" อัตโนมัติ — *(น่าจะ: แสดงชื่อ provider ที่ใช้จริง)*
- ทั้งคู่ fail: ใช้ cache ล่าสุด + แสดง badge เล็ก ๆ "ข้อมูลอาจไม่อัปเดต"
- Cache หมดอายุ (> 3 ชั่วโมง): ใช้ Default state (Clear) ไม่แสดง effects
- **ไม่มี error crash** บน Virtual Office — environment gracefully degrade
- Map ยังใช้งานได้ปกติทุกฟังก์ชันแม้ weather API down
- Log error ฝั่ง server สำหรับ monitoring

### Weather Widget State (Error)

```
┌──────────────────┐
│ ☀️ -- °C  Bangkok│
│ ⚠ ข้อมูลล่าช้า     │
└──────────────────┘
```

### UX/UI

[Figma node `4872-587869`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4872-587869)

---

## EP-02 · Location นอกประเทศไทย / ไม่มีใน TMD Database

**Type:** Error Path · **Priority:** Normal · **ClickUp status: Closed**
**Trigger:** Owner ตั้ง location นอกประเทศไทย หรือพิกัดที่ TMD ไม่ครอบคลุม

### Scenario Steps

1. Owner ตั้ง location เป็นเมืองนอกไทย เช่น "Tokyo, Japan"
2. ระบบพยายาม fetch จาก TMD → ไม่มีข้อมูล
3. Auto-switch ไป **OpenWeatherMap** สำหรับ location นั้น
4. Owner เห็น note ใน Settings: "Location นี้ใช้ OpenWeatherMap (ไม่ใช่ TMD)"

### Acceptance Criteria

- Location นอกไทย: auto-use OpenWeatherMap โดยไม่ต้องแจ้ง error
- Settings page แสดง source: "แหล่งข้อมูล: OpenWeatherMap (กรมอุตุฯ ครอบคลุมเฉพาะไทย)"
- Weather alerts: แสดงเฉพาะ location ในไทย — ถ้านอกไทย alerts section ซ่อน
- ถ้า OpenWeatherMap ไม่มีข้อมูล location นั้น (ห่างไกลมาก): default to Clear/Sunny
- Owner ค้นหา location นอกไทยได้: autocomplete รองรับ global cities
- ไม่มี error message ที่ confusing — graceful fallback

### Settings Note Layout

```
📍 Tokyo, Japan (35.6762° N, 139.6503° E)
   ⚠️ แหล่งข้อมูล: OpenWeatherMap
      (กรมอุตุฯ ครอบคลุมเฉพาะในประเทศไทย)

   ✅ Time of Day lighting
   ✅ Weather visual effects
   ❌ Weather Alerts  ← ปิดอัตโนมัติ (ไม่รองรับนอกไทย)
```

### UX/UI

ไม่มี Figma node แนบใน task นี้

---

## EC-01 · Members คนละ Timezone — Time of Day ยึด Workspace Location

**Type:** Edge Case · **Priority:** Normal
**Trigger:** Members ใน workspace อยู่คนละ timezone แต่ environment ยึด location ของ Owner

### Scenario

```
Owner location: กรุงเทพฯ (+07:00) → เวลา 22:00 = Night stage
Alice (Bangkok):   เห็น Night stage ✅ ถูกต้อง
Bob (Tokyo +09:00): เวลา 00:00 ก็ยังเห็น Night stage ✅ (ถูกต้อง เพราะ workspace = Bangkok)
Carol (London ±00:00): เวลา 15:00 แต่เห็น Night stage ← อาจแปลกใจ
```

### Acceptance Criteria

- Time of Day ยึดตาม **timezone ของ Workspace location** เสมอ — ไม่ใช่ user timezone
- **ไม่มี option** ให้ user เลือก timezone แยก (ยึด workspace location เป็น single source of truth)
- Weather widget แสดง: "🌙 Bangkok 22:00 ICT" — บอก timezone ชัดเจน
- Carol เห็น Night overlay แม้ London เป็นบ่าย — **เป็น design intent**
- ถ้า user แปลกใจ: hover widget ดู tooltip "เวลาตามสถานที่ของ Workspace: Bangkok, Thailand"

### Widget Tooltip

```
🌙 Night  22:00 ICT
📍 ตามสถานที่ Workspace: Bangkok, Thailand
```

### UX/UI

[Figma node `4779-678975`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4779-678975)

---

## EC-02 · Weather Alert ระดับ Emergency (แดง) — ปิดไม่ได้

**Type:** Edge Case · **Priority:** Normal
**Trigger:** TMD ออกประกาศเตือนภัยระดับฉุกเฉิน เช่น พายุ, แผ่นดินไหว, สึนามิ

### Scenario

1. TMD ออก Emergency Alert ระดับแดง: "พายุหมุนเขตร้อน"
2. ระบบ broadcast ทันที — **ไม่รอ poll 15 นาที** (webhook จาก TMD ถ้ารองรับ)
3. ทุก member เห็น Emergency Banner สีแดง

### Emergency Banner (ปิดไม่ได้)

```
┌──────────────────────────────────────────────────────┐
│ 🔴🔴  ประกาศฉุกเฉิน — กรมอุตุนิยมวิทยา                │
│       พายุหมุนเขตร้อน "ทกซูรี" กำลังแรงสูงสุด          │
│       พื้นที่เสี่ยง: กรุงเทพฯ และปริมณฑล               │
│       "ห้ามออกจากอาคารโดยเด็ดขาด"                    │
│       ออกประกาศ: 16:45 ICT                           │
│       [อ่านประกาศฉบับเต็ม ↗]                          │
│       (ปิดอัตโนมัติเมื่อประกาศสิ้นสุด)                   │
└──────────────────────────────────────────────────────┘
```

### Acceptance Criteria

- Emergency Alert: broadcast **ทันที** ไม่รอ poll รอบถัดไป
- Emergency Banner: **ปิดไม่ได้ด้วยปุ่ม X** — ปิดเองเมื่อ `expires_at` ถึง
- Map effect: เปลี่ยนเป็น thunderstorm severe + dark overlay ทันที
- Notification เก็บใน bell panel ด้วย (persistent)
- Alert ซ้อนกัน: ถ้ามีหลาย alerts พร้อมกัน → แสดง severity สูงสุดก่อน
- TMD Webhook: ถ้า TMD รองรับ push notification → register webhook endpoint ฝั่ง Zyra
- หมดอายุ: banner หาย, map effect กลับ weather ปกติ, notification mark เป็น expired

### Technical Note (จาก ClickUp)

```
TMD Emergency Alert:
- ถ้า TMD รองรับ webhook: receive real-time → broadcast ทันที
- ถ้า TMD ไม่รองรับ: poll ทุก 5 นาที (สำหรับ emergency level เท่านั้น)
- Regular alerts: poll ทุก 15 นาที ตามปกติ
```

### UX/UI

[Figma node `4779-682160`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4779-682160)

---

## EC-03 · Owner เปลี่ยน Location กลางคัน — Members เห็นทันที

**Type:** Edge Case · **Priority:** Normal
**Trigger:** Owner เปลี่ยน Workspace location ขณะ members กำลังใช้งาน Virtual Office

### Scenario

```
เดิม: Bangkok → เวลา 14:00 ICT → Afternoon stage + ฝนตก
Owner เปลี่ยน → Chiang Mai
ใหม่: Chiang Mai → เวลา 14:00 ICT → Afternoon stage + แดดออก
```

### Acceptance Criteria

- เปลี่ยน location: server fetch weather ใหม่ของ Chiang Mai ทันที
- Broadcast ไปทุก member ที่ online: environment เปลี่ยนภายใน **5 วินาที**
- Transition smooth: ไม่ป๊อป ไม่กระตุก — fade weather effects เก่าออก fade ใหม่เข้า
- Toast แจ้ง members: **"🌍 Location ของ Workspace เปลี่ยนเป็น Chiang Mai"**
- Time of Day: ถ้า timezone เดิมเหมือนกัน (ทั้งไทย = +07:00) → stage ไม่เปลี่ยน
- ถ้าเปลี่ยน timezone จริง (เช่น Bangkok → London): Time of Day stage เปลี่ยนทันที
- Weather widget อัปเดต location ใหม่ทันที

### UX/UI

[Figma node `5505-952140`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=5505-952140)

---

# ข้อขัดแย้ง & คำถามที่ต้องเคลียร์ (ก่อน implement)

| # | ประเด็น | ที่มา | ต้องการคำตอบจาก |
|---|---|---|---|
| 1 | **Provider จริงคืออะไร** — *(มีข้อมูลประกอบแล้วใน [ภาคผนวก A](#ภาคผนวก-a--provider-capability-check-ตรวจจริง-2026-09-09): ตัวเดียวจบไม่ได้)* — parent บอก TMD (primary) + OpenWeatherMap (fallback) แต่ HP-01/03/04 ถูกแก้เป็น Open-Meteo และ EP-01/EP-02 ยังเขียน TMD → OpenWeatherMap อยู่ | parent vs HP-01/03/04 vs EP-01/02 | PM |
| 2 | **Renderer ผิด** — HP-02/HP-03 ระบุ "canvas layer บน **Phaser.js**" แต่ VO จริงใช้ **Pixi** (`PixiGameScene`) → ต้องเขียน overlay/particle เป็น Pixi layer | HP-02, HP-03 vs โค้ดจริง | ทีม dev (ไม่ต้องถาม PM — spec เขียนผิด engine) |
| 3 | **Weather alert รองรับนอกไทยหรือไม่** — *(A.4: Open-Meteo ไม่มี alert เลย · TMD ไทยเท่านั้น · นอกไทยต้องพึ่ง OWM/CAP)* — EP-02 บอกนอกไทยให้ซ่อน alerts (เพราะ TMD ครอบคลุมแค่ไทย) แต่ถ้าย้ายไป Open-Meteo (มี alert ทั่วโลก) เงื่อนไขนี้อาจไม่จำเป็น | EP-02 vs HP-04 | PM |
| 4 | **"อ่านเพิ่มเติม" ลิงก์ไปไหน** — *(A.4: TMD ให้ `WebUrlThai` เป็นไฟล์ PDF)* — HP-04 บอก link ไปหน้า TMD alert โดยตรง แต่ถ้า provider เป็น Open-Meteo จะไม่มีหน้า alert ให้ลิงก์ | HP-04 | PM |
| 5 | **รอบ fetch ไม่ตรงกัน** — parent: TMD 1 ชม. / OWM 30 นาที · HP-03: 60 นาที · HP-04 (alerts): 15 นาที · EC-02: emergency 5 นาที | ทุก task | PM (สรุปเป็นตารางเดียว) |
| 6 | **EP-01 ใช้คำว่า "Operator"** แทนชื่อ provider — น่าจะ find-replace พลาด ทำให้ AC อ่านไม่ได้ความ | EP-01 | PM (ขอ AC ฉบับแก้) |
| 7 | **EP-02 ถูก Closed** — ปิดเพราะทำเสร็จ, ตัด scope, หรือ superseded ด้วยการเปลี่ยน provider? | EP-02 | PM |
| 8 | **"ดึงเวลาจาก server ไม่ใช่ client clock"** (HP-02) — ต้องออกแบบว่า time-of-day stage คำนวณที่ไหน (server push stage / client คำนวณจาก server time + tz offset) | HP-02 | ทีม dev (technical-design) |
| 9 | **Personal preference เก็บที่ไหน** — HP-05 บอก persist ข้าม session; ในระบบมี settings model อยู่แล้ว (4 JSONB blobs) ต้องเลือกว่าเข้า blob ไหน หรือ stay-local | HP-05 | ทีม dev (technical-design) |
| 10 | **Location picker ปักหมุด** — HP-01 ระบุ "ใช้แบบปักหมุด" (map picker) แต่ EP-02 ต้องมี autocomplete ค้นชื่อเมืองด้วย → เอาทั้งสอง หรือปักหมุดเท่านั้น | HP-01 vs EP-02 | PM |
| 11 | **Thunder sound** (HP-03) — "optional (user toggle)" แต่ HP-05 ไม่มี toggle เสียงในรายการ | HP-03 vs HP-05 | PM |
| 12 | **Emergency banner ปิดไม่ได้** ทับ HUD ของ VO — ต้องกำหนดตำแหน่ง/ความสูง และ z-order กับ HUD/modal เดิม | HP-04, EC-02 | ทีม dev + design |

---

# ยังไม่มีในเอกสารชุดนี้ (ขั้นถัดไป)

- `technical-design.md` — API contract (`/api/user/workspaces/{id}/environment`, weather fetcher/cron, ws event), DB migration (workspace location/tz + env toggles + weather cache + alert dedup), flow ของ broadcast
- `task-breakdown.md` — แบ่ง PR ต่อ service
- `test-plan.md` — case ต่อ scenario ID
- `ux-ui-plan.md` — spec exact px/hex จาก Figma 9 node ที่แนบไว้ในแต่ละ subtask (ยังไม่ได้ดึงจาก Figma MCP)
- `progress.md` — เปิดเมื่อเริ่มเขียนโค้ด

---

# ภาคผนวก A — Provider capability check (ตรวจจริง 2026-09-09)

> ทุกบรรทัดในภาคผนวกนี้ **ยิง API จริง หรืออ่าน doc ของ provider เอง** ไม่ใช่การเดา
> คำสั่งที่ใช้ยิงและ response ตัวอย่างอยู่ใน [§ A.5](#a5-หลักฐานที่ใช้ยิงจริง)

## A.1 สรุปสั้น

**Open-Meteo ทำได้ ~70% ของ req — แต่ขาด 3 อย่างที่ต้องหาตัวเสริม**

| # | สิ่งที่ขาด | กระทบ scenario | ต้องเพิ่ม |
|---|---|---|---|
| 1 | **Weather alerts / warnings — Open-Meteo ไม่มี endpoint นี้เลย** | HP-04, EC-02 (พังทั้ง scenario) | TMD `WeatherWarningNews` (ไทย) และ/หรือ OpenWeatherMap One Call (นอกไทย) |
| 2 | **Reverse geocoding (ปักหมุด → ชื่อเมือง)** — Geocoding API ของ Open-Meteo เป็น forward-only | HP-01 ("ใช้แบบปักหมุด"), EC-03 (toast บอกชื่อเมือง) | Nominatim / BigDataCloud / LocationIQ / OpenCage — หรือเปลี่ยน UX เป็นค้นด้วยชื่อ |
| 3 | **Push / webhook** — Open-Meteo และ TMD เป็น poll-only ทั้งคู่ | EC-02 ("broadcast ทันที ไม่รอ poll") | ไม่มี provider ไหนให้ webhook → ต้องลด poll interval แทน (ดู A.4) |

## A.2 Open-Meteo — ทำได้อะไร (verified)

**Forecast API** `https://api.open-meteo.com/v1/forecast` — ไม่ต้องมี API key (non-commercial), latency ~0.9s, `interval: 900` (โมเดลอัปเดตทุก 15 นาที)

| Req ใน spec | Open-Meteo | สถานะ |
|---|---|---|
| อุณหภูมิ | `current.temperature_2m` (31.1 °C) | ✅ |
| ความชื้น (widget แสดง 82%) | `current.relative_humidity_2m` (67 %) | ✅ |
| ลม (weather detail popup) | `current.wind_speed_10m`, `wind_gusts_10m`, `wind_direction_10m` | ✅ |
| Weather condition → 6 effect | `current.weather_code` (WMO 0–99) | ✅ แต่ต้อง map เอง (ดู A.3) |
| Timezone ของ location (HP-02, EC-01) | `timezone=auto` → `"timezone":"Asia/Bangkok"`, `utc_offset_seconds: 25200`, `timezone_abbreviation:"GMT+7"` | ✅ ได้ IANA tz name มาเลย ไม่ต้องใช้ tz library แยก |
| ค่า `is_day` (กลางวัน/กลางคืน) | `current.is_day` (1/0) | ✅ (ของแถม) |
| Sunrise / sunset | `daily.sunrise` / `daily.sunset` (`06:06` / `18:24` @ Bangkok) | ✅ **ดีกว่าที่ spec เขียน** — ดู A.6 ข้อเสนอ |
| ฝนตกจริงหรือไม่ (ยืนยัน rain effect) | `current.precipitation`, `current.rain`, `showers`, `snowfall` | ✅ |
| เมฆ (cloudy overlay) | `current.cloud_cover` (93 %) | ✅ |
| **Weather alert** | ❌ ไม่มี | ❌ |
| **Visibility** (Fog/Haze "ลด visibility") | ❌ ไม่มี variable `visibility` | ❌ ใช้ `weather_code 45/48` + Air Quality API แทน |

**Air Quality API** `https://air-quality-api.open-meteo.com/v1/air-quality` (คนละ host) — `pm2_5`, `pm10`, `us_aqi`, `european_aqi`, `dust`, `aerosol_optical_depth` (ค่านี้คือ haze), UV, pollen · global 0.4° 3-hourly / Europe 0.1° hourly · ไม่ต้องมี key
→ ถ้าอยากให้ **Haze effect ตรงกับหน้าจริงในไทย (PM2.5 ฤดูหมอกควัน)** ต้องเรียก API ตัวนี้เพิ่ม เพราะ `weather_code` 45/48 คือ fog อย่างเดียว ไม่ครอบ haze

**Geocoding API** `https://geocoding-api.open-meteo.com/v1/search` — ค้นด้วยชื่อ (prefix ≥ 3 ตัวอักษร, `language=th` คืน "เชียงใหม่" / "จังหวัดเชียงใหม่" ได้), คืน `timezone`, `population`, `admin1–4`, `country` · **ไม่มี reverse** (lat/lng → ชื่อ)

**ข้อควรระวังเรื่อง license:** Open-Meteo free = non-commercial (CC-BY-NC 4.0). Zyra เป็น commercial product → ต้องใช้ plan แบบ `customer-` prefix + API key ก่อนขึ้น prod — **ต้องเคลียร์กับ PM/ฝ่ายจัดซื้อ ไม่ใช่ข้อจำกัดทางเทคนิค**

## A.3 WMO code → 6 effect buckets ของ spec

Open-Meteo ให้ `weather_code` เป็นเลข WMO — ต้อง map เองในฝั่งเรา:

| Effect ใน spec | WMO code |
|---|---|
| Clear / Sunny | 0, 1 |
| Cloudy | 2, 3 |
| Fog / Haze | 45, 48 (+ เสริมด้วย `pm2_5` / `aerosol_optical_depth` จาก Air Quality API) |
| Rain / Drizzle | 51, 53, 55, 56, 57 (drizzle) · 61, 63, 65, 66, 67, 80, 81, 82 (rain/showers) |
| Thunderstorm | 95, 96, 99 |
| **Windy** | ❌ **ไม่มี WMO code** — ต้อง derive จาก `wind_speed_10m` / `wind_gusts_10m` โดยกำหนด threshold เอง (ยังไม่มีใน spec — ต้องให้ PM ตัดสิน เช่น gusts ≥ 30 km/h) |
| (snow 71–86) | spec ยังไม่ระบุ effect สำหรับหิมะ — ไทยไม่เจอ แต่ถ้า location นอกไทยจะตกช่องนี้ |

## A.4 Weather Alert — ทางเลือกที่มีจริง

### ตัวเลือก 1: TMD `WeatherWarningNews` v2 — **ยิงได้จริงแล้ว** (ไทยเท่านั้น)

`https://data.tmd.go.th/api/WeatherWarningNews/v2/?uid=<uid>&ukey=<ukey>` · XML · ตอบ 200 ใน ~1.4s (42 KB)
ยิงวันนี้ได้ประกาศจริง 1 ใบ: *"ฝนตกหนักถึงหนักมากบริเวณประเทศไทย ... ฉบับที่ 5 (195/2569)"*

Schema จริงต่อ 1 `<Warning>`:
```
IssueNo, EffectStartDate, EffectEndDate, AnnounceDate,
TitleThai, HeadlineThai, DescriptionThai, WebUrlThai, ContactThai,
TitleEnglish, HeadlineEnglish, DescriptionEnglish, WebUrlEnglish, ContactEnglish
```

| Req ใน HP-04 / EC-02 | TMD ให้ไหม |
|---|---|
| ข้อความประกาศ (หัวข้อ + เนื้อหา) ไทย/อังกฤษ | ✅ `TitleThai`/`HeadlineThai`/`DescriptionThai` + ชุด English |
| เวลาออกประกาศ ("ออกประกาศ 14:30 ICT") | ✅ `AnnounceDate` |
| `expires_at` (banner หายเอง) | ✅ `EffectEndDate` |
| "อ่านเพิ่มเติม ↗" ลิงก์ประกาศเต็ม | ✅ `WebUrlThai` / `WebUrlEnglish` — **แต่เป็นไฟล์ PDF** และ URL ภาษาไทยมีอักขระไทยดิบ ต้อง encode ก่อนใช้ |
| **Severity 3 ระดับ (🟡 Watch / 🟠 Warning / 🔴 Emergency)** | ❌ **ไม่มี field severity เลย** → ต้อง derive เองจาก keyword ในหัวข้อ (เช่น "พายุหมุนเขตร้อน" = แดง) — เป็น **design decision ที่ PM ต้องอนุมัติ** ก่อน implement เพราะกระทบกฎ "แดงปิดไม่ได้" |
| **พื้นที่เสี่ยง / filter ตาม location ของ workspace** | ❌ ไม่มี field พื้นที่แบบ structured — ประกาศเป็นระดับ**ประเทศ/ภาค** อยู่ในข้อความไทย → ถ้าจะกรองตามจังหวัดของ workspace ต้อง parse ข้อความ (เปราะ) หรือแสดงทุกประกาศระดับประเทศ |
| `alert_id` สำหรับ dedup | ⚠️ ไม่มี field ชื่อนี้ — ใช้ `IssueNo` + เลขประกาศใน title (`195/2569`) + `AnnounceDate` ประกอบเป็น key เอง |
| Webhook / push (EC-02) | ❌ ไม่มี — poll เท่านั้น |

**กับดักที่เจอตอน parse:** ใน `<Warning>` เดียว มี `TitleEnglish` / `HeadlineEnglish` / `DescriptionEnglish` / `WebUrlEnglish` / `ContactEnglish` **ซ้ำ 2 ชุด** — ชุดแรกเนื้อหาเป็น**ภาษาไทย** ชุดที่สองเป็นอังกฤษจริง ("Heavy to Very Heavy Rain in Thailand No.5") ถ้า parser ใช้ `findtext()` แบบเอา element แรกจะได้ภาษาไทยมาโชว์ในฝั่ง EN

**Credential:** demo `uid=api&ukey=api12345` ใช้ได้ตอนทดสอบ แต่ prod ต้องลงทะเบียนขอ uid/ukey ของตัวเองที่ TMD (ยังไม่ได้ทำ)

### ตัวเลือก 2: OpenWeatherMap One Call — alerts แบบ per-coordinate ทั่วโลก

คืน `alerts[]`: `sender_name`, `event`, `start`, `end`, `description`, `tags` — ตรงกับ HP-04 มากกว่า TMD (มี event + ช่วงเวลาเป็น structured, ได้เป็นพิกัด ไม่ใช่ทั้งประเทศ)
ข้อติดที่ยังไม่เคลียร์: ต้องมี API key + subscription (free tier ~1,000 calls/day แต่หน้า pricing วันนี้เปลี่ยนไปโปรโมต One Call **4.0** แล้ว — **ยังไม่ยืนยันว่าต้องผูกบัตรหรือไม่ และ 3.0 ยังเปิดรับสมัครใหม่อยู่ไหม**) และ **ยังไม่ยืนยันว่ารายชื่อ alert source ของ OWM ครอบคลุม TMD ไทยหรือเปล่า** (doc บอกว่ามี "full list" แต่ดึงรายชื่อจริงไม่ได้จากหน้าเว็บ) → ต้องเข้าไปดูในบัญชี OWM เอง

### ตัวเลือก 3: WMO Alert Hub / CAP feed
`severeweather.wmo.int` มีระบบรวม CAP feed หลายประเทศ แต่หน้า feed list โหลดข้อมูลแบบ dynamic — **ยืนยันไม่ได้ว่าไทย/TMD อยู่ในลิสต์** ต้องเปิดหน้าจริงดู ถ้ามี จะได้ CAP XML ที่มี severity/urgency/area มาตรฐาน (แก้ปัญหา A.4 ข้อ severity ได้ตรง ๆ)

### ผลต่อ EC-02 ("broadcast ทันที ไม่รอ poll 15 นาที")
ไม่มี provider ไหนในสามตัวเลือกให้ webhook → **ต้องแก้ AC** เป็น "poll ถี่ขึ้นสำหรับ emergency (เช่น 5 นาที ตามที่ EC-02 เขียนไว้เองใน Technical Note) แล้ว broadcast ทันทีที่เจอ" และตัดข้อ "register webhook endpoint" ออก จนกว่า TMD จะมีจริง

## A.5 หลักฐานที่ใช้ยิงจริง

```bash
# Open-Meteo — current + sunrise/sunset + timezone (Bangkok)
curl "https://api.open-meteo.com/v1/forecast?latitude=13.7563&longitude=100.5018\
&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,weather_code,cloud_cover,wind_speed_10m,wind_gusts_10m\
&daily=sunrise,sunset&timezone=auto&forecast_days=1"
# → 200 / 0.92s · timezone "Asia/Bangkok" utc_offset 25200 · weather_code 3 · interval 900

# Open-Meteo geocoding (forward, ภาษาไทย)
curl "https://geocoding-api.open-meteo.com/v1/search?name=Chiang%20Mai&count=2&language=th"
# → "เชียงใหม่" / admin1 "จังหวัดเชียงใหม่" / timezone "Asia/Bangkok"

# TMD weather warning (demo credential)
curl "https://data.tmd.go.th/api/WeatherWarningNews/v2/?uid=api&ukey=api12345"
# → 200 / 1.45s / 42 KB · 1 Warning: IssueNo 5, Effect 2026-09-09 05:00→18:00
```

## A.6 ข้อเสนอให้ PM ตัดสิน (เพิ่มจาก 12 ข้อเดิม)

| # | ข้อเสนอ | เหตุผล |
|---|---|---|
| 13 | **แยก provider ตามหน้าที่**: Open-Meteo = weather + timezone (ทุก location ทั่วโลก) · TMD = alert เฉพาะไทย · reverse-geocode = provider ที่สาม | Open-Meteo ไม่มี alert, TMD ไม่มี weather แบบพิกัด — ไม่มีตัวไหนตัวเดียวจบ |
| 14 | **ใช้ `sunrise`/`sunset` จริง แทนเวลาคงที่ 05:00–07:00** ในการตัด stage Dawn/Night | Open-Meteo ให้มาฟรีต่อวันต่อพิกัด, ทำให้ Dawn/Evening ตรงกับฟ้าจริงทั้งปีและทุก location (ตอนนี้ Bangkok 06:06/18:24 — ไม่ตรงตาราง spec) |
| 15 | **กำหนด threshold ของ Windy** (`wind_gusts_10m` กี่ km/h) | WMO code ไม่มี "windy" — ไม่กำหนดคือ implement ไม่ได้ |
| 16 | **Severity ของ TMD alert จะ derive จากอะไร** และถ้า derive ไม่ได้จะให้ทุกประกาศเป็นระดับไหน | กฎ "แดงปิดไม่ได้" เป็น safety rule — ต้องมีเกณฑ์ที่ตกลงกันไว้ ไม่ให้ AI/dev เดา |
| 17 | **alert ระดับประเทศ vs location ของ workspace** — TMD ประกาศเป็นภาค/ประเทศ จะแสดงให้ทุก workspace ในไทยเห็นหมด หรือพยายามกรองตามจังหวัด | กระทบ HP-04 ข้อ "ของ location นั้น" |
| 18 | **Haze**: จะเรียก Air Quality API เพิ่มไหม (PM2.5) หรือใช้แค่ fog code 45/48 | ไทยมีฤดูหมอกควัน — ถ้าไม่เรียก AQ API, Haze effect จะแทบไม่ทำงานเลย |
| 19 | **Open-Meteo commercial license** — ต้องซื้อ plan `customer-` ก่อน prod | free tier เป็น non-commercial (CC-BY-NC) — Zyra เป็นสินค้า |
| 20 | **แหล่งข้อมูลที่โชว์ใน widget** ("แหล่ง: กรมอุตุฯ") จะโชว์อะไรเมื่อ weather มาจาก Open-Meteo แต่ alert มาจาก TMD | widget ปัจจุบันใน spec เขียน "กรมอุตุฯ" ทั้งที่ตัวเลขจะมาจาก Open-Meteo |

---

# ภาคผนวก B — แนวทางทดแทนส่วนที่ Open-Meteo ไม่มี (ตรวจจริง 2026-09-09)

> คำถามที่ตั้งไว้: *"ส่วนที่ไม่มี มีอะไรมาทดแทนได้"* และ *"อยากได้ครบ ไม่จำเป็นต้องใช้ Open-Meteo ก็ได้ — มีไหม"*
> **คำตอบสั้น: มี — [Google Maps Platform Weather API](#b1-ทางที่ครบในเจ้าเดียว--google-maps-platform) ทำได้ครบทุก req ในเจ้าเดียว และรองรับไทยครบทุก endpoint รวม alerts**

## B.1 ทางที่ครบในเจ้าเดียว — Google Maps Platform

### Coverage: ไทยได้ครบ
ตารางความครอบคลุมของ Google ระบุแถวไทยเป็น `TH | Thailand | ⬤ | ⬤ | ⬤ | ⬤ | ⬤` — ครบทั้ง 5: current conditions · daily forecast · hourly forecast · hourly history · **weather alerts** (alert มาจากหน่วยงานราชการ/หน่วยงานอุตุฯ ของแต่ละประเทศ ~60+ ประเทศ)

### `currentConditions:lookup` ให้อะไร
`https://weather.googleapis.com/v1/currentConditions:lookup?key=…&location.latitude=…&location.longitude=…`

| Req ใน spec | Google ให้ |
|---|---|
| อุณหภูมิ / รู้สึกเหมือน | `temperature`, `feelsLike` ✅ |
| ความชื้น | `relativeHumidity` ✅ |
| ลม (+ gust) | `wind` (direction องศา+ทิศ, speed, gust) ✅ |
| Condition → effect | `weatherCondition` (type + description + icon) ✅ |
| กลางวัน/กลางคืน | `isDaytime` ✅ |
| **timezone ของ location** | `timeZone` (IANA id) มาในคำตอบเดียวกัน ✅ → **ไม่ต้องซื้อ Time Zone API แยก** |
| ฝน | `precipitation` (probability, type, qty) ✅ |
| เมฆ | `cloudCover` ✅ |
| **visibility** (Fog/Haze "ลด visibility") | `visibility` ✅ — **Open-Meteo ไม่มีตัวนี้** |
| UV / ความกดอากาศ | `uvIndex`, `airPressure` ✅ (ของแถม) |

### `weatherAlerts` ให้อะไร — แก้ปัญหาใหญ่สุดของ TMD
| Req ใน HP-04 / EC-02 | Google ให้ |
|---|---|
| **Severity 3 ระดับ** | ✅ **มี field จริง**: `Extreme` / `Severe` / `Moderate` / `Minor` / `Unknown` (+ `certainty`, `urgency` แบบ CAP) → map เข้า 🟡🟠🔴 ได้โดย **ไม่ต้องเดาจาก keyword ภาษาไทย** |
| **พื้นที่เสี่ยง / filter ตาม location** | ✅ affected areas เป็น **polygon coordinates** → ตรวจได้ว่า lat/lng ของ workspace อยู่ในเขตประกาศไหม (TMD ทำไม่ได้) |
| `expires_at` (banner หายเอง) | ✅ start / expiration time |
| alert id (dedup) | ✅ alert ID + title |
| ข้อความ + คำแนะนำความปลอดภัย | ✅ event type + safety recommendations (`languageCode` เลือกภาษาได้) |
| แหล่งข้อมูล ("ข้อมูลจาก…") | ✅ source attribution ของหน่วยงานที่ออกประกาศ |
| Webhook / push | ❌ ไม่มี (ไม่มีเจ้าไหนมี — ดู B.3 ข้อ 4) |

**severity mapping ที่เสนอ** (ต้องให้ PM เคาะ): `Minor` → 🟡 Watch · `Moderate` + `Severe` → 🟠 Warning · `Extreme` → 🔴 Emergency (ปิดไม่ได้)

### ราคา (Google Maps Platform pricing)
| SKU | ราคา tier แรก | ฟรีต่อเดือน | Zyra ใช้ตอนไหน |
|---|---|---|---|
| Weather API | **$0.15 / 1,000 requests** | 10,000 events | poll weather + alerts |
| Geocoding API (reverse) | $5.00 / 1,000 | 10,000 events | เฉพาะตอน owner ปักหมุด/เปลี่ยน location |
| Time Zone API | $5.00 / 1,000 | 10,000 events | **ไม่ต้องใช้** (ได้ `timeZone` จาก Weather API แล้ว) |

**ประมาณการค่าใช้จ่าย** — สมมติ dedupe เป็น "จำนวน location ที่ไม่ซ้ำ" (N) โดย cache ต่อพิกัดปัด 0.1° หรือต่อจังหวัด, weather poll 60 นาที (720 ครั้ง/เดือน) + alerts poll 15 นาที (2,880 ครั้ง/เดือน) = **N × 3,600 calls/เดือน**

| N (location ไม่ซ้ำ) | calls/เดือน | เกินโควตาฟรี | ค่าใช้จ่าย/เดือน |
|---|---|---|---|
| 5 | 18,000 | 8,000 | ~$1.2 |
| 20 | 72,000 | 62,000 | ~$9.3 |
| 77 (ทุกจังหวัด) | 277,200 | 267,200 | ~$40 |

Reverse geocode อยู่ในโควตาฟรี 10,000/เดือนสบาย ๆ (owner เปลี่ยน location นาน ๆ ครั้ง)
⚠️ ตัวเลขนี้เป็น **การคำนวณจาก rate card ไม่ใช่บิลจริง** — ต้องยืนยันกับบัญชี GCP ของทีมเอง (โปรแกรม $200 credit/เดือนมีเงื่อนไขต่างกันตามการสมัคร)

### ตัวเลือกสำรองที่รองรับไทย: Tomorrow.io
มีรายชื่อไทยใน severe-weather coverage (alert จากหน่วยงานราชการเหมือนกัน) — แต่หน้า doc ตอบ **403** ตอนเข้าไปอ่าน จึง **ยังไม่ยืนยัน** field/severity/free-tier ต้องเข้าไปดูด้วยบัญชีเอง

## B.2 ตารางเทียบทุก req × ทุกทางเลือก

| Req | Open-Meteo + TMD | **Google** | OpenWeatherMap | Weatherbit |
|---|---|---|---|---|
| current weather (temp/humidity/wind) | ✅ | ✅ | ✅ | ✅ |
| timezone ของ location | ✅ (`timezone=auto`) | ✅ (ในคำตอบเดียวกัน) | ⚠️ ได้แค่ offset | ⚠️ |
| visibility | ❌ | ✅ | ✅ | ✅ |
| alert **ในไทย** | ✅ TMD (ตรงจากกรมอุตุฯ) | ✅ (TH = supported) | ⚠️ ยืนยันไม่ได้ว่ามีไทย | ❌ **ไม่รองรับไทย** (มีแค่ US/EU/UK/CA/CN) |
| alert **severity เป็น field** | ❌ ต้อง derive เอง | ✅ 5 ระดับ + certainty/urgency | ✅ (`tags`) | — |
| alert **พื้นที่เป็น polygon** | ❌ (ประกาศระดับภาค/ประเทศ) | ✅ | ⚠️ per-coordinate | — |
| reverse geocoding | ❌ ต้องหาเจ้าที่สาม | ✅ Geocoding API | ✅ มี Geocoding API | ⚠️ |
| webhook / push | ❌ | ❌ | ❌ | ❌ |
| ราคา / license สำหรับสินค้าเชิงพาณิชย์ | ⚠️ Open-Meteo free เป็น **non-commercial** → ต้องซื้อ plan อยู่ดี | ชัดเจน จ่ายตามใช้ ($0.15/1k) | free 1,000/วัน (ต้องยืนยันเงื่อนไขบัตร) | มี free tier |

**ข้อสังเกตที่เปลี่ยนการตัดสินใจ:** เหตุผลเดียวที่จะเลือกกอง Open-Meteo คือ "ฟรี" — แต่ free tier ของ Open-Meteo เป็น CC-BY-NC (non-commercial) ซึ่ง Zyra ใช้ไม่ได้ตามเงื่อนไข ⇒ **ต้องจ่ายทั้งสองทาง** ข้อได้เปรียบด้านราคาจึงเหลือน้อยกว่าที่เห็นตอนแรก

## B.3 ถ้าเลือกไม่จ่าย Google — ทดแทนรายข้อ (ทดสอบแล้วทั้งหมด)

### 1. Reverse geocoding (ปักหมุด → ชื่อสถานที่)
**Nominatim (OSM) — ยิงจริงได้ผลภาษาไทยครบ:**
```bash
curl -H "User-Agent: zyra/1.0 (contact)" \
 "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=13.7563&lon=100.5018&accept-language=th&zoom=10"
# → display_name "แขวงบวรนิเวศ, เขตพระนคร, กรุงเทพมหานคร, 10200, ประเทศไทย"
#   address.city "กรุงเทพมหานคร" · ISO3166-2-lvl4 "TH-10"  ← ได้รหัสจังหวัดมาเลย
```
- ข้อจำกัด: **1 request/second**, ห้าม bulk, ต้องใส่ `User-Agent` ระบุตัวตน, ต้อง attribution "© OpenStreetMap contributors, ODbL"
- **พอใช้จริง** เพราะ reverse ถูกเรียกแค่ตอน owner ปักหมุด (นาน ๆ ครั้ง) แล้ว **cache ชื่อ+tz ลง DB** ไม่ต้องเรียกซ้ำตอน poll weather
- ทางเลือกอื่น: BigDataCloud (ฟรี ไม่ต้อง key) · LocationIQ (ฟรี 5,000/วัน) · OpenCage (ฟรี 2,500/วัน)
- **ทางที่ไม่ต้องพึ่งใครเลย**: เก็บตาราง centroid 77 จังหวัดไว้ใน DB แล้วหา nearest → ได้ชื่อจังหวัดไทยแบบ offline 0 dependency (และพอดีกับที่ TMD ประกาศเป็นระดับจังหวัด/ภาค) นอกไทยค่อย fallback ไป Nominatim

### 2. Severity ที่ TMD ไม่มี — 3 ทางเลือก
**(a) GDACS (EU JRC) — ยิงจริงได้ 200, ฟรี ไม่ต้อง key**
```bash
curl "https://www.gdacs.org/gdacsapi/api/events/geteventlist/SEARCH?alertlevel=Orange;Red&country=Thailand"
# → FeatureCollection · eventtype "FL" · alertlevel ในชื่อไอคอน (Green/Orange/Red)
#   geometry Point + bbox · "Flood in Malaysia, Thailand"
```
- ✅ มี **severity 3 ระดับ (Green/Orange/Red) ตรงกับ 🟡🟠🔴 ของ spec** + พิกัด + eventtype (FL น้ำท่วม / TC พายุหมุน / EQ แผ่นดินไหว / TS สึนามิ / VO ภูเขาไฟ)
- ⚠️ **threshold สูงมาก** (orange ≈ >100 เสียชีวิต หรือ >80,000 อพยพ) → ไม่ยิงสำหรับ "ฝนตกหนัก" ปกติ ⇒ **ใช้เป็นชั้น Emergency (แดง) เท่านั้น** ไม่ใช่ Watch/Warning
- ⚠️ query ที่ไม่ใส่ช่วงวันจะคืน event เก่าติดมาด้วย (ที่ทดสอบได้ event ของ 12 Dec 2025) → ต้อง filter วันเองเสมอ
- ต้องเครดิต "Global Disaster Alert and Coordination System, GDACS"

**(b) Keyword table จาก `TitleThai` ของ TMD** — เร็วที่สุด ต้นทุน 0 แต่ต้องให้ PM อนุมัติตารางคำ (เช่น "พายุหมุนเขตร้อน"/"สึนามิ" = แดง · "ฝนตกหนักมาก"/"ลมกระโชกแรง" = ส้ม · "ฝนฟ้าคะนอง" = เหลือง)

**(c) Derive เองจาก forecast** — ไม่ต้องมี alert provider เลย
Open-Meteo `hourly` ให้วัตถุดิบครบ (ยิงจริงเมื่อกี้ที่ Bangkok):
```
11:00 precip 0.0mm prob 23% gusts 22.7km/h code 3
13:00 precip 2.0mm prob 41% gusts 30.6km/h code 95   ← thunderstorm
16:00 precip 1.8mm prob 100% gusts 33.1km/h code 80
```
→ ตั้ง threshold เองแล้วออก in-app notice "ระวังฝนฟ้าคะนองช่วง 13:00–16:00"
⚠️ **ห้ามติดตรา "ประกาศกรมอุตุนิยมวิทยา"** กับ notice ที่เราคำนวณเอง — ต้องเขียนชัดว่าเป็นการคาดการณ์ของระบบ (ประเด็นความรับผิด ไม่ใช่ประเด็นเทคนิค)

### 3. แผ่นดินไหว / สึนามิ (EC-02 พูดถึงโดยตรง)
**TMD `DailySeismicEvent` — ยิงจริงได้ 200 (685 KB)** มี `Magnitude`, `Latitude`, `Longitude`, `Depth`, `OriginThai` ("มณฑลยูนนาน, ประเทศจีน"), `DateTimeThai`, `TitleThai`
⚠️ payload ใหญ่และคืนรายการย้อนหลังยาว → ต้อง filter ตามวันที่ + รัศมีจาก workspace เอง
(ทางเลือกสำรอง: USGS FDSN `earthquake.usgs.gov/fdsnws/event/1/query` ฟรี ไม่ต้อง key รองรับ filter รัศมี/แมกนิจูด — รูปแบบ query ต้องปรับ ที่ทดสอบครั้งแรกยัง parse ไม่ผ่าน)

### 4. Webhook / push (EC-02 "ทันที ไม่รอ poll")
ไม่มี provider ไหนให้ (Open-Meteo, TMD, Google, OWM เหมือนกันหมด) — ทดแทนด้วย:
- **Single global poller** ไม่ใช่ poll ต่อ workspace: TMD warning เป็น feed ระดับประเทศใบเดียว → ดึง **1 ครั้งต่อรอบ** แล้ว broadcast ให้ทุก workspace ในไทย ⇒ poll ถี่ถึง 2–5 นาทีได้โดยไม่เปลือง quota
- ⚠️ **TMD ไม่ส่ง `ETag` / `Last-Modified` / `Cache-Control`** (ตรวจ HEAD แล้ว) → ประหยัด bandwidth ด้วย conditional request ไม่ได้ ต้องดึง 42 KB ทุกครอบ (ยังถูกมากถ้า poller เดียว)
- แก้ AC ของ EC-02: ตัด "register webhook endpoint" ออก เปลี่ยนเป็น "poll 5 นาทีสำหรับชั้น emergency + broadcast ทันทีที่พบ" (ซึ่ง Technical Note ของ EC-02 เองก็เขียนไว้แบบนี้แล้ว)

### 5. Visibility / Haze ที่ Open-Meteo ไม่มี
`weather_code` 45/48 = fog เท่านั้น → เสริมด้วย Air Quality API (`pm2_5`, `aerosol_optical_depth`) เพื่อให้ Haze effect ทำงานในฤดูหมอกควันของไทย
(ถ้าใช้ Google: มี `visibility` มาให้ตรง ๆ ไม่ต้องต่อ API เพิ่ม)

## B.4 สรุป 2 ทางให้เลือก

| | **ทาง A — Google เจ้าเดียว** | **ทาง B — ประกอบเอง 4 เจ้า** |
|---|---|---|
| Provider | Google Weather API + Google Geocoding | Open-Meteo (weather+tz) + TMD WeatherWarningNews (alert ไทย) + Nominatim (reverse) + GDACS (emergency) |
| ครอบคลุม req | ~ทุกข้อ ยกเว้น webhook | ทุกข้อ ยกเว้น webhook — แต่ severity/area ต้อง derive เอง |
| Severity 3 ระดับ | ✅ field จริง | ⚠️ ต้องตั้งกฎเอง (PM ต้องเคาะ) |
| Filter alert ตาม location | ✅ polygon | ⚠️ parse ข้อความ / แสดงระดับประเทศ |
| จำนวนจุดที่ต้องดูแล | 2 SKU, 1 บัญชี | 4 provider, 4 รูปแบบ error/rate-limit, XML+JSON ผสม, TMD credential |
| ต้นทุน | ~$1–40/เดือน ตาม N (ดู B.1) | Open-Meteo commercial plan (ต้องขอราคา) + ค่าดูแลโค้ดที่มากกว่า |
| ความเสี่ยงหลัก | ผูกกับ Google + ต้องเปิด billing | 4 จุดพัง, severity ที่เราเดาเองใน scenario เกี่ยวกับความปลอดภัย |

**ข้อเสนอ:** ถ้างบผ่านได้ → **ทาง A** เพราะ scenario ที่เปราะที่สุด (HP-04 / EC-02 ซึ่งเป็นเรื่องความปลอดภัย) ได้ severity + polygon จากต้นทางจริง ไม่ต้องให้ dev เดาจากคำในหัวข้อประกาศ
ถ้าต้องเริ่มโดยไม่มีงบ → **ทาง B** แต่ต้องยอมรับว่า severity เป็นกฎที่เราตั้งเอง และเปลี่ยนไป Google ทีหลังได้ถ้าออกแบบ provider layer เป็น interface เดียวตั้งแต่ต้น

## B.5 ข้อที่ต้องให้ PM ตัดสินเพิ่ม (ต่อจาก 20 ข้อเดิม)

| # | ข้อ |
|---|---|
| 21 | **เลือกทาง A (Google) หรือทาง B (ประกอบเอง)** — ตัวชี้ขาดคือ งบ vs การยอมให้ severity เป็นกฎที่เราตั้งเอง |
| 22 | ถ้าเลือก A: ยืนยัน severity mapping `Minor→เหลือง / Moderate+Severe→ส้ม / Extreme→แดง` |
| 23 | ถ้าเลือก B: อนุมัติ **ตาราง keyword → severity** สำหรับ `TitleThai` ของ TMD (จำเป็นเพราะกฎ "แดงปิดไม่ได้") |
| 24 | จะเปิด **in-app notice ที่ระบบคำนวณเอง** (B.3 ข้อ 2c) หรือไม่ — ถ้าเปิด ต้องมีข้อความกำกับว่าไม่ใช่ประกาศราชการ |
| 25 | ขอบเขต EC-02 ("แผ่นดินไหว/สึนามิ") — จะต่อ TMD `DailySeismicEvent` / GDACS ด้วยไหม หรือจำกัดที่ประกาศสภาพอากาศเท่านั้น |

---

# ภาคผนวก C — รองรับทั่วโลก (ตรวจจริง 2026-09-09)

> โจทย์เพิ่ม: *"จริง ๆ อยากทำรองรับทั่วโลกด้วย"*
> **ผลตรวจเปลี่ยนข้อสรุปของภาคผนวก B: ไม่มี provider เจ้าเดียวจบสำหรับ global** — ทาง A (Google เจ้าเดียว) ใช้ไม่ได้ทั่วโลก
> ต้องผสมตามภูมิภาคอยู่ดี ⇒ provider layer ใน [technical-design.md](technical-design.md) §3 กลายเป็น **ข้อบังคับ ไม่ใช่ทางเลือก**

## C.1 รูในความครอบคลุมของ Google (อ่านตารางทีละแถว ไม่ได้อนุมาน)

ตาราง coverage มี 195 แถว · คอลัมน์: `Region code · Current conditions · Daily forecast · Hourly forecast · Hourly history · Weather alerts`
**คอลัมน์ alerts มีเพียง ~30 ประเทศ** จาก 195

| ประเทศ | weather (4 คอลัมน์แรก) | alerts | ผลต่อเรา |
|---|---|---|---|
| TH ไทย | ✅ | ✅ | ครบ |
| US · GB · DE · AU · BR · SG · PH | ✅ | ✅ | ครบ |
| **IN อินเดีย · MY มาเลเซีย · ID อินโดนีเซีย** | ✅ | ❌ | มีอากาศ **ไม่มีประกาศเตือนภัย** |
| **JP ญี่ปุ่น · KR เกาหลีใต้ · VN เวียดนาม** | ❌ | ✅ | **มีแต่ประกาศ ไม่มีข้อมูลอากาศเลย** |
| **CN จีน** | ❌ | ❌ | Google ใช้ไม่ได้ทั้งใบ |
| CU · IR · KP | ❌ | ❌ | ใช้ไม่ได้ทั้งใบ |

**ผลที่ตามมา**
- ถ้าใช้ Google เจ้าเดียว → workspace ที่ **โตเกียว / โซล / โฮจิมินห์** จะ **ไม่มีข้อมูลอากาศแสดงเลย** (แต่มีประกาศเตือนภัย) และที่ **จีน** จะไม่มีอะไรเลย
- Open-Meteo ยิงได้ทุกพิกัดรวมจีน/ญี่ปุ่น/เกาหลี (ทดสอบแล้วหลายเมือง) ⇒ **weather ควรมาจาก Open-Meteo/หรือเจ้าที่ครอบคลุมทั่วโลก แล้วใช้ Google เฉพาะ alerts**
- ประเทศที่ Google ไม่มี alerts (อินเดีย มาเลเซีย อินโดฯ แคนาดา รัสเซีย ฯลฯ) ⇒ ถ้าจะมี alert จริงต้องต่อหน่วยงานรายประเทศ (ไม่ scale) หรือใช้ตัวรวม CAP ระดับโลก

## C.2 ตัวรวม alert ระดับโลก — สถานะจริง

| ตัวเลือก | ครอบคลุม | สถานะการตรวจ |
|---|---|---|
| **Google Weather alerts** | ~30 ประเทศ (รวมไทย) | ✅ ยืนยันจากตาราง coverage แล้ว |
| **TMD** | ไทยเท่านั้น | ✅ ยิงได้จริง (ภาคผนวก A) |
| **GDACS** | ทั่วโลก แต่เฉพาะภัยพิบัติใหญ่ | ✅ ยิงได้จริง — เกณฑ์สูงมาก ใช้เป็นชั้นแดงเท่านั้น |
| **WMO Alert Hub / alert-hub.org** | ทั่วโลก (รวม CAP feed ของหน่วยงานที่ WMO รับรอง) | ⚠️ **มีอยู่จริงตามเอกสาร แต่หา endpoint ที่ยิงได้จริงไม่ได้** — เดา URL แล้ว 404 ทุกอัน (`severeweather.wmo.int/v2/cap-alerts/rss.xml`, `alert-hub.s3.amazonaws.com/atom.xml`) และหน้า feed list โหลดข้อมูลแบบ dynamic อ่านจากภายนอกไม่ได้ ⇒ **ถ้าจะพึ่งตัวนี้ ต้องติดต่อขอ endpoint/สิทธิ์เข้าถึงก่อน ห้ามใส่ในแผนเป็นของที่มีแน่** |
| **Tomorrow.io** | ทั่วโลก (government alerts) | ⚠️ มี Events API + ระบุว่ารวม government alerts แต่หน้า coverage/pricing ตอบ 403 → free-tier limit และรายชื่อประเทศ **ยังยืนยันไม่ได้** |
| **MeteoAlarm** | ยุโรป ~38 ประเทศ (CAP ฟรี) | ยังไม่ตรวจ — แต่ยุโรปอยู่ในกลุ่มที่ Google ครอบคลุมแล้ว จึงเป็นตัวสำรองไม่ใช่ตัวหลัก |

**สรุป C.2:** ทุกวันนี้ *"alert ครอบคลุมทั่วโลกจริง ๆ"* ยังไม่มีเจ้าไหนให้ในราคาที่ยืนยันได้ — แผนที่ทำได้จริงคือ **แบ่งชั้นตามภูมิภาค** (C.4)

## C.3 4 เรื่องที่ spec ปัจจุบันใช้กับทั่วโลกไม่ได้

### 1. ตารางเวลา Time of Day คงที่ → ใช้ไม่ได้นอกเขตร้อน
ค่าที่ยิงได้จริงวันเดียวกัน (9 ก.ย. 2026):

| เมือง | sunrise | sunset | ช่วงกลางวัน |
|---|---|---|---|
| Bangkok | 06:06 | 18:24 | 12.3 ชม. |
| Sydney | 06:03 | 17:42 | 11.7 ชม. |
| London | 06:26 | 19:29 | 13.1 ชม. |
| Svalbard | 04:52 | 20:56 | 16.1 ชม. |

ตาราง `05:00–07:00 = Dawn` ของ spec ทำให้ Svalbard เข้าสู่ Dawn ตอนที่ฟ้าสว่างมาแล้ว ⇒ **ต้องผูก stage กับ sunrise/sunset จริง** (ข้อเสนอ 14 ในภาคผนวก A กลายเป็นข้อบังคับ)

### 2. Polar day / polar night — ต้องมี branch พิเศษ
Open-Meteo **ไม่คืน null** แต่คืนค่าที่ดูเหมือนปกติ:
```
Svalbard 21 ธ.ค. 2025 (polar night): sunrise 00:00 · sunset 00:00 · daylight_duration 0
Svalbard 21 มิ.ย. 2025 (polar day) : sunrise 00:00 · sunset (วันถัดไป) 00:00 · daylight_duration 86400
```
ถ้าเอา sunrise/sunset ไปตัด stage ตรง ๆ จะได้ Dawn/Evening ที่เที่ยงคืนตลอดฤดู
⇒ **ตรวจ `daylight_duration` ก่อนเสมอ**: `0` → Night ค้างทั้งวัน · `86400` → Morning/Afternoon ค้างทั้งวัน · อื่น ๆ → คำนวณตามปกติ

### 3. หิมะไม่มีในตาราง effect
WMO code 71–77 (snow), 85–86 (snow showers) ไม่มีแถวใน "Weather Conditions → Map Effects" ⇒ workspace ที่ Oslo หน้าหนาวจะไม่มี effect อะไรเลยทั้งที่หิมะตก
⇒ ต้องเพิ่ม effect หิมะ (+ พิจารณา freezing rain 56/57/66/67 กับคลื่นความร้อน)

### 4. หน่วยวัดและภาษาของประกาศ
- อุณหภูมิ/ความเร็วลม: °C·km/h กับ °F·mph — จะยึด locale ของ workspace หรือของ user แต่ละคน
- ข้อความ alert ของบางหน่วยงานมีแต่ภาษาท้องถิ่น ⇒ member ไทยที่อยู่ workspace โตเกียวจะเห็นประกาศเป็นภาษาญี่ปุ่น (Google มี `languageCode` แต่ไม่รับประกันทุกหน่วยงาน)
- **ยังไม่มีข้อไหนใน spec พูดถึงสองเรื่องนี้เลย**

## C.4 แผนที่ทำได้จริงสำหรับ global — แบ่งชั้นตามภูมิภาค

```
weather + timezone + sunrise/sunset   → Open-Meteo (ครอบทุกพิกัดรวมจีน/ญี่ปุ่น/เกาหลี)
                                         หรือ Google เฉพาะประเทศที่มี weather ถ้าต้องการเจ้าเดียว
alert ชั้น 1  ไทย                      → TMD (ตรงจากกรมอุตุฯ, ฟรี, 1 poller ทั้งระบบ)
alert ชั้น 2  ~30 ประเทศที่ Google มี   → Google weatherAlerts (severity + polygon)
alert ชั้น 3  ที่เหลือทั้งโลก            → GDACS (ภัยพิบัติใหญ่เท่านั้น = ชั้นแดง)
              + WMO Alert Hub ถ้าติดต่อขอ endpoint ได้ (ยังไม่ยืนยัน)
reverse geocode                        → Google Geocoding หรือ Nominatim (ทั้งคู่ global)
```

**สิ่งที่ต้องเขียนใน service layer เพิ่มจาก technical-design เดิม**
- ตาราง `country_code → alert provider` (config ไม่ hardcode) + สถานะ "ประเทศนี้ไม่มีประกาศเตือนภัย"
- UI ต้องบอกตรง ๆ เมื่อ location นั้นไม่มี alert รองรับ — ตอนนี้ EP-02 พูดถึงแค่ "นอกไทยซ่อน alerts" ซึ่งเขียนไว้ตอนที่คิดว่ามีแค่ไทย/ไม่ไทย ⇒ **ต้องแก้เป็น 3 สถานะ: มีประกาศ / ไม่มีประกาศในประเทศนี้ / มีแต่ภัยพิบัติใหญ่ (GDACS)**
- เก็บ **ชื่อ timezone แบบ IANA** (`Asia/Bangkok`) ไม่ใช่ offset วินาที — ยิงจริงยืนยันว่า Open-Meteo คืน DST ถูกต้อง (London = GMT+1 ตอนนี้, New York = GMT-4) แต่ offset เปลี่ยนปีละ 2 ครั้ง ถ้า cache offset ไว้จะเพี้ยน 1 ชั่วโมง

## C.5 ผลต่อโควตา/ค่าใช้จ่ายเมื่อเป็น global

สูตรเดิมยังใช้ได้ (ผูกกับ "ช่องกริดที่มีคน online" ไม่ผูกกับจำนวน workspace) แต่ตัวคูณเปลี่ยน:
- **weather**: ถ้าใช้ Open-Meteo (ต้องซื้อ commercial plan) ⇒ ไม่กินโควตา Google เลย
- **alerts**: ไทยฟรี (TMD) · ~30 ประเทศใช้ Google per-point ทุก 15 นาที = 2,880 ครั้ง/เดือน/ช่อง ⇒ **โควตาฟรี 10,000 รองรับได้เพียง ~3 ช่องกริด** ⇒ ถ้ามีลูกค้าหลายประเทศ ต้องขยาย interval เป็น 30 นาที (1,440/เดือน/ช่อง ≈ 6 ช่อง) หรือยอมจ่าย (ยังถูก: $0.15/1,000)
- ประเทศชั้น 3 ใช้ GDACS ⇒ ฟรี และเป็น poller เดียวทั้งระบบเหมือน TMD

## C.6 ข้อที่ต้องให้ PM ตัดสินเพิ่ม (ต่อจาก 25 ข้อเดิม)

| # | ข้อ |
|---|---|
| 26 | **ขอบเขต global รอบแรก** — รองรับทุกประเทศเลย หรือเปิดเฉพาะกลุ่มที่มีประกาศเตือนภัยครบก่อน (ไทย + ~30 ประเทศของ Google) |
| 27 | ประเทศที่ **ไม่มีประกาศเตือนภัย** (อินเดีย มาเลเซีย อินโดฯ แคนาดา ฯลฯ) — ซ่อนฟีเจอร์ alert, แสดงเฉพาะ GDACS ระดับแดง, หรือแจ้งว่า "ไม่รองรับในประเทศนี้" |
| 28 | **จีน/ญี่ปุ่น/เกาหลี/เวียดนาม** — ยอมรับได้ไหมที่ข้อมูลอากาศกับประกาศมาจากคนละเจ้า (และจีนต้องพึ่ง Open-Meteo อย่างเดียว) |
| 29 | **หิมะ / ฝนน้ำแข็ง / คลื่นความร้อน** — จะทำ effect เพิ่มไหม หรือ fallback เป็น Cloudy |
| 30 | **หน่วยวัด** °C/km/h ยึด workspace หรือ user |
| 31 | **ภาษาประกาศ** — ถ้าหน่วยงานให้แต่ภาษาท้องถิ่น จะแสดงตามต้นฉบับ, แปลด้วยเครื่อง, หรือแสดงเฉพาะหัวข้อที่แปลได้ |
| 32 | จะให้ทีมติดต่อ **WMO Alert Hub** เพื่อขอ endpoint สำหรับ alert ทั่วโลกไหม (เป็นทางเดียวที่จะครอบคลุมจริงในระยะยาว) |

---

# ภาคผนวก D — มติ MD (2026-09-09) และขอบเขตรอบแรก

> **มติ:** ใช้ **Google Maps Platform + กรมอุตุนิยมวิทยา (TMD) + GDACS** ไปก่อน · **Open-Meteo เลื่อนไปรอบที่เปิดสร้างรายได้แล้ว**
> ⇒ ภาคผนวก C ข้อ 26 (ขอบเขต global รอบแรก) **ถือว่าตอบแล้วโดยปริยาย**: เปิดทั่วโลกได้ แต่คุณภาพต่างกันตามประเทศ ตามตาราง D.2

## D.1 ช่องว่างที่มตินี้เปิดขึ้น และวิธีปิด (ตรวจแล้ว)

ถ้าไม่มี Open-Meteo แล้ว **เวลาท้องถิ่นและพระอาทิตย์ขึ้น–ตกจะเอาจากไหน** — เพราะ `timeZone` กับ `sunEvents` ของ Google มาพร้อม weather ซึ่ง **ไม่มีในจีน ญี่ปุ่น เกาหลี เวียดนาม**

| ข้อมูลที่ต้องใช้ | แหล่งในรอบแรก | ครอบคลุม | ต้นทุน |
|---|---|---|---|
| **timezone (IANA)** | **Google Time Zone API** — `maps.googleapis.com/maps/api/timezone/json` คืน `timeZoneId`, `timeZoneName`, `rawOffset`, `dstOffset` | ทั่วโลก · **ไม่ผูกกับ coverage ของ Weather API** | เรียกครั้งเดียวตอน owner ตั้ง location → อยู่ในโควตาฟรี 10,000/เดือนสบาย |
| **sunrise / sunset** | **คำนวณเองจาก lat/lng + วันที่** (สูตร solar position มาตรฐาน) | ทั่วโลก รวมขั้วโลก (รู้เองว่าวันนั้นไม่มีพระอาทิตย์ขึ้น) | **0 call** |
| อากาศ (effect + widget) | Google `currentConditions:lookup` | ~190 ประเทศ · **ยกเว้น CN, JP, KR, VN, CU, IR, KP** | $0.15/1,000 |
| ประกาศเตือนภัย | TMD (ไทย) → Google (~30 ประเทศ) → GDACS (ทั่วโลก เฉพาะระดับแดง) | ตาราง D.2 | TMD/GDACS ฟรี · Google $0.15/1,000 |
| ปักหมุด → ชื่อสถานที่ | Google Geocoding (reverse) | ทั่วโลก | อยู่ในโควตาฟรี |

**ผลพลอยได้:** Google daily forecast มี `sunEvents` (sunrise/sunset) และ `moonEvents` ให้ก็จริง แต่เป็น **call เพิ่มอีกหนึ่งรายการ** และไม่มีในประเทศที่ไม่มี weather ⇒ **เลือกคำนวณเองดีกว่าทั้งด้านต้นทุนและความครอบคลุม** (0 call · เท่ากันทุกประเทศ · จัดการเคสขั้วโลกได้ในโค้ดเดียว)

## D.2 ความสามารถต่อประเทศในรอบแรก

| กลุ่มประเทศ | แสงตามเวลา | Weather effect + widget | ประกาศเตือนภัย |
|---|---|---|---|
| **ไทย** | ✅ | ✅ | ✅ TMD (ตรงจากต้นทาง) + Google + GDACS |
| **~30 ประเทศที่ Google มี alerts** (US, GB, DE, AU, BR, SG, PH …) | ✅ | ✅ | ✅ Google (มี severity + polygon) + GDACS |
| **ประเทศที่มี weather แต่ไม่มี alerts** (IN, MY, ID, CA, RU …) | ✅ | ✅ | ⚠️ เฉพาะภัยพิบัติใหญ่ (GDACS) |
| **JP, KR, VN** | ✅ | ❌ **ไม่มีข้อมูลอากาศ** | ✅ Google + GDACS |
| **CN, CU, IR, KP** | ✅ | ❌ | ⚠️ เฉพาะ GDACS |

**สมมติฐานที่ใช้ไปก่อน (PM ยืนยันได้ ไม่บล็อกงาน):** ประเทศที่ไม่มี weather **ยังให้ตั้ง location ได้** — map จะแสดงแสงตามเวลาจริง (ซึ่งทำงานทุกที่ในโลก) แต่ไม่มี effect อากาศ และ widget บอกตรง ๆ ว่ายังไม่รองรับข้อมูลอากาศในพื้นที่นี้ · ทางเลือกอื่นคือบล็อกไม่ให้เลือกประเทศเหล่านั้น (ไม่แนะนำ — ผู้ใช้จะไม่เข้าใจว่าทำไมเลือกไม่ได้)

## D.3 สิ่งที่ต้องดำเนินการก่อนเริ่มโค้ด

| # | งาน | ผู้รับผิดชอบ | หมายเหตุ |
|---|---|---|---|
| 1 | เปิด billing บน Google Cloud + สร้าง API key + **เปิดใช้ 3 API: Weather, Time Zone, Geocoding** | ทีม infra / MD อนุมัติแล้ว | ตั้งเพดานงบ (budget alert) ไว้ด้วย |
| 2 | จำกัดสิทธิ์ key ให้เรียกได้แค่ 3 API นั้น + จำกัด IP ของ zyra-api | ทีม infra | key ต้องอยู่ใน secret ของ k8s (`zyra-api-<env>-env-json`) ไม่ใช่ `NEXT_PUBLIC_*` |
| 3 | ลงทะเบียนขอ `uid` / `ukey` ของ TMD ในนามบริษัท | PM / ทีม | ตอนนี้ทดสอบด้วย credential ตัวอย่าง — ห้ามใช้ใน prod |
| 4 | ใส่เครดิต "Global Disaster Alert and Coordination System, GDACS" ในหน้าที่แสดงข้อมูล | ทีม frontend | เงื่อนไขการใช้ของ GDACS |
| 5 | ยืนยันว่าโควตาฟรี 10,000/เดือน นับ Weather API เป็นรายการเดียวหรือแยกตาม endpoint | ทีม infra (ดูในบัญชี) | กระทบตัวเลขงบใน [ภาคผนวก B §B.1](#b1-ทางที่ครบในเจ้าเดียว--google-maps-platform) |

## D.4 ข้อที่ตกไป / เปลี่ยนสถานะจากมตินี้

| ข้อเดิม | สถานะใหม่ |
|---|---|
| ข้อ 1 (เลือก provider) | ✅ **ปิด** — MD ตัดสินแล้ว |
| ข้อ 19 (Open-Meteo commercial license) | ⏸ **เลื่อน** ไปรอบที่เปิดสร้างรายได้ |
| ข้อ 3 / 23 (ตารางคำ → severity ของ TMD) | ⚠️ **ยังต้องทำ** — ไทยใช้ TMD เป็นแหล่งหลักซึ่งไม่มี severity |
| ข้อ 2 / 22 (แปลง severity ของ Google) | ⚠️ **ยังต้องยืนยัน** |
| ข้อ 26 (ขอบเขต global) | ✅ ปิดโดยปริยาย — เปิดทั่วโลก คุณภาพต่างกันตาม D.2 |
| ข้อ 28 (ยอมรับได้ไหมที่อากาศกับประกาศมาจากคนละเจ้า) | ✅ ปิด — รอบแรกจีน/ญี่ปุ่น/เกาหลี/เวียดนามจะ **ไม่มีอากาศเลย** ซึ่งแรงกว่าที่ถามไว้ ⇒ ต้องแจ้ง PM ให้รู้ตัวข้อนี้ชัด ๆ |
| ข้อ 32 (ติดต่อ WMO Alert Hub) | ⏸ เลื่อน — ไว้แก้ปัญหาประเทศที่ไม่มี alerts ในรอบถัดไป |

---

# ภาคผนวก E — task ที่ PM เพิ่มรอบ 2026-09-09 (HP-06, HP-07)

> ดึงจาก ClickUp 2026-09-09 · 2 subtask ใหม่ ทั้งคู่เป็น **owner-level toggle** ไม่ใช่ personal preference
> เนื้อหาเต็มอยู่ที่ [HP-06](#hp-06--owner-ปิด-workspace-location) และ [HP-07](#hp-07--owner-ปิด-workspace-location-notification)

## E.1 สิ่งที่เพิ่มเข้ามาจริง

| | HP-06 | HP-07 |
|---|---|---|
| toggle | **Workspace location** (ปิดทั้งชุด) | **Workspace Alert Notification** |
| ปิดแล้วเกิดอะไร | weather ไม่มีข้อมูล · weather widget หาย · "shotcut หน้าหลัก" ไม่แสดง | widget **ยังบอกสภาพอากาศ** แต่ไม่มี alert แจ้งเตือน |
| ขอบเขต | ทั้ง workspace (ทุก member) | ทั้ง workspace |
| Figma | `4872-587869` (ซ้ำกับ EP-01) | `4872-593891` |

## E.2 จุดที่ขัดกับของเดิม — ต้องเคลียร์ก่อน implement

| # | ประเด็น | ทำไมสำคัญ |
|---|---|---|
| 33 | **HP-07 ซ้ำกับ toggle ที่ 3 ของ HP-01** — HP-01 มี "✅ Weather Alerts notification [toggle]" ในหน้า Workspace Settings อยู่แล้ว · HP-07 คือ toggle เดียวกันเขียนเป็น scenario แยก หรือเป็นตัวใหม่คนละที่ | ถ้าเป็นตัวเดียวกัน = ไม่ต้องทำงานเพิ่ม แค่เขียน test เพิ่ม · ถ้าเป็นตัวใหม่ = จะมี 2 ที่ที่ปิด alert ได้ ซึ่งผู้ใช้จะสับสน |
| 34 | **ที่ตั้ง UI ขัดกัน** — HP-06/07 เขียนว่าอยู่ที่ "⚙️ Settings บน Virtual Office HUD หรือ User Preferences" ซึ่งเป็น**ที่เดียวกับ HP-05 (personal)** แต่เนื้อหาเป็น workspace-level | ถ้าเอา toggle ระดับ workspace ไปวางในหน้า personal settings member จะเข้าใจผิดว่าปิดแค่ตัวเอง (และต้องซ่อน/disable สำหรับ non-owner) — HP-01 บอกว่า setting ของ owner อยู่ใน **Workspace Settings** |
| 35 | **ปิด location แล้ว Time of Day ยังทำงานไหม** — AC พูดถึงแต่ weather widget · แต่แสงตามเวลาต้องใช้ timezone ของ location เหมือนกัน | ต้องเลือก: (ก) ปิด location = ปิดทั้ง environment รวมแสงตามเวลา · (ข) แสงตามเวลายังทำงานจาก timezone ที่เก็บไว้ · (ค) แสงตามเวลากลับไป Morning ค้าง — **กระทบ HP-02 โดยตรง** |
| 36 | **"shotcut หน้าหลัก" คืออะไร** — ปรากฏทั้ง 2 task และใน HP-07 ขัดกับ AC ของตัวเอง | เดาว่าเป็น weather widget/shortcut บนหน้า lobby หรือ home ซึ่ง **ยังไม่มีใน scenario ไหนของ SC-ENV-01 เลย** ⇒ ถ้ามีจริงคืองานเพิ่มอีกหน้า ต้องระบุว่าอยู่หน้าไหน |
| 37 | **Figma node ของ HP-06 = `4872-587869` ซ้ำกับ EP-01** (สถานะ error ของ widget) | ต้องยืนยันว่าแนบถูก node หรือไม่ ก่อนถอด spec หน้าจอ |
| 38 | **AC ประโยคแรกของทั้งสอง task อ่านขัดกันเอง** — "Owner preference แยกจาก Workspace settings — ปิดทั้ง workspace" | ถ้าปิดทั้ง workspace มันคือ workspace setting ไม่ใช่ owner preference (ประโยคนี้น่าจะ copy มาจาก HP-05 ที่เป็น personal จริง) — ขอ AC ที่ตรงกับความตั้งใจ |
| 39 | ทั้งสอง task **ยังไม่มี priority** ใน ClickUp (HP-01–05 มีครบ) | จัดลำดับงานไม่ได้ |
| 40 | **HP-07 ขัดกับ EC-02 โดยตรง** — HP-07 ให้ owner ปิด alert ได้ทั้ง workspace แต่ EC-02 กำหนดว่า alert ระดับ emergency (แดง) **ปิดไม่ได้ด้วยเหตุผลความปลอดภัย** | ต้องเลือก: ปิดได้ทุกระดับ (ยอมรับความเสี่ยง) หรือ toggle ปิดได้แค่ระดับเหลือง/ส้ม และแดงยังส่งเสมอ — **เป็นการตัดสินใจเรื่องความปลอดภัย ไม่ใช่เรื่อง UI** |

## E.3 ผลต่อ design ที่ทำไว้แล้ว

- **DB**: ต้องเพิ่ม `env_location_enabled BOOLEAN NOT NULL DEFAULT TRUE` เป็น **master switch** แยกจาก 3 toggle เดิม (`env_time_of_day` / `env_weather` / `env_alerts`) — เพราะ AC บอกว่า "เปิดใหม่ location กลับมาทันที" ⇒ **ห้ามลบค่า lat/lng/timezone ตอนปิด** ต้องเก็บไว้แล้วแค่หยุดใช้ (ดู [technical-design §13](technical-design.md#13-master-switch-ของ-workspace-location-hp-06--hp-07))
- **API**: snapshot ต้องมีสถานะ `location_enabled: false` แยกจาก `weather_coverage: "none"` — สองอย่างนี้หน้าตาเหมือนกันสำหรับผู้ใช้ (ไม่มีข้อมูลอากาศ) แต่คนละเหตุผล และหน้าบ้านต้องแสดงข้อความต่างกัน
- **Quota**: ปิด location = **หยุดยิง provider ทั้งหมดของ workspace นั้น** (ไม่ใช่แค่ซ่อน UI) → ช่วยประหยัดโควตาโดยตรง
- **Task breakdown**: กระทบ A1 (คอลัมน์เพิ่ม) · A3 (ข้าม fetch เมื่อปิด) · C4/C5 (สถานะใหม่) · C6 (2 toggle) — ดู [task-breakdown.md](task-breakdown.md)


---

# ภาคผนวก F — asset ที่ได้รับ 2026-09-09 และสิ่งที่ต้องเพิ่มใน spec

> ไฟล์อยู่ที่ `storage/[Feature]  · Environment (Time of Day + Weather) — Virtual Office Map/` (27 GIF + 1 PNG, 4.7 MB)
> รายการเต็ม + mapping + layer model: [ux-ui-plan.md §7.2](ux-ui-plan.md#72-asset-ที่ได้รับแล้ว-2026-09-09--storagefeature--environment-time-of-day--weather--virtual-office-map) และ [§8](ux-ui-plan.md#8-layer-model-ที่ได้จาก-asset-ยืนยันจาก-bg_zyrapng)

| # | สิ่งที่ต้องเพิ่ม/ตัดสิน | เหตุผล |
|---|---|---|
| 47 | **ดาว 6 แบบ + ดาวตก + ดวงจันทร์ + ฉากหลังท้องฟ้า** ไม่มีใน spec เลย — ตาราง Night stage เขียนแค่ "overlay มืด สีน้ำเงินเข้ม" | asset ส่งมาแล้ว ⇒ กลางคืนจะมีดาวระยิบและดาวตก ต้องระบุพฤติกรรม (ความถี่ดาวตก, จำนวนดาว, สุ่มตำแหน่งไหม) |
| 48 | **ต้องขอ asset ขนาด 1×** — ไฟล์ปัจจุบันเป็น pixel art ที่ upscale ~100 เท่า | ถ้าใช้ตรง ๆ `cloud1` กินหน่วยความจำ ~65 MB, `shooting-star` ~100 MB+ ⇒ พังบนมือถือ/Safari |
| 49 | **ไอคอนของการ์ดใน Setting ยังไม่มี** | asset ที่ได้เป็นของฉาก ไม่ใช่ไอคอนแบนตามที่ Figma วาด — ต้องเลือกว่าใช้ pixel art ชุดนี้เป็นไอคอนด้วย หรือส่งไอคอนอีกชุด |
| 50 | **ฝนปรอย (drizzle) ใช้ไฟล์ไหน** | มี rain 4 แบบแต่ไม่ได้ระบุว่าอันไหนคือปรอย/หนัก/หนักมาก |
| 51 | **ฉากหลัง `Bg_zyra.png` ทับซ้อนกับ outside display ที่มีอยู่แล้วใน VO หรือไม่** | ต้องดูว่าแทนของเดิม หรือเป็นเลเยอร์ใหม่ |
