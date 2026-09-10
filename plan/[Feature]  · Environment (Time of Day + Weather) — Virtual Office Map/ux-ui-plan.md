# SC-ENV-01 · UX/UI Plan

> **สถานะ:** ถอดจาก Figma จริงบางส่วน (ดึงเมื่อ 2026-09-09 ด้วย Figma MCP) — **ยังไม่ครบทุก node** ดู [§7](#7-สิ่งที่ยังต้องถอดเพิ่ม)
> **อัปเดต 2026-09-10:** ได้ asset **พระจันทร์ 5 phase** แล้ว อัปขึ้น R2 เรียบร้อย → [§7.2.5](#725-พระจันทร์-5-phase--ได้รับ--อัปขึ้น-r2-แล้ว-2026-09-10) (ข้อ **57–59** ต้องตัดสินก่อนใช้)
> **อัปเดต 2026-09-09 (C4):** ถอด weather panel + การ์ดครบแล้ว → [§9](#9-weather-panel--widget-c4--ถอดจริง-2026-09-09) · เจอ 5 จุดที่ design ยังไม่มีแต่ spec บังคับ (ข้อ **52–56**)
> **asset:** โฟลเดอร์ + checklist ชื่อไฟล์รออยู่ที่ `storage/env-weather/` (MANIFEST.md) — mapping กับ WMO code อยู่ใน [§7.2](#72-asset-ที่รออยู่--วางที่-storageenv-weather)
> **ไฟล์:** `Map8gX0L2hk7HnkaFRfhtj` — Zyra design (More Organised ver.)
> ⚠️ **ภาพที่ถอดมาพลิกความเข้าใจเดิม 4 ข้อ** — ดู [§6](#6-จุดที่-design-ขัดกับ-spec--ต้องเคลียร์ก่อน-implement) ก่อนอ่านส่วนอื่น
> ค่า spacing/px ที่ **ยังไม่ได้ดึง** ถูกทำเครื่องหมาย `ต้องดึง` ไว้ — ห้ามเดาตาม [10-figma-fidelity](../../../.claude/rules/10-figma-fidelity.md)

---

## 1. โครงหลัก: Setting modal → tab "Environment"

**ไม่ใช่หน้าใหม่** — เป็น **tab ที่ 7 ใน Setting modal ที่มีอยู่แล้ว**
`Profile · General · Audio · Notifications · Manage member · Integrations · **Environment**`

```
┌─ Setting (modal 1440×1024 viewport) ─────────────────────────────┐
│ Setting          │ Environment                                [X]│
│  Profile         │ Manage your workspace environment and         │
│  General         │ personalize how effects appear on your screen. │
│  Audio           │ ───────────────────────────────────────────── │
│  Notifications   │ Workspace weather                             │
│  Manage member   │   [ การ์ดสภาพอากาศ ]                          │
│  Integrations    │ ───────────────────────────────────────────── │
│ ▸Environment     │ <toggle rows ต่างกันตาม role — ดู §2/§3>      │
└──────────────────┴───────────────────────────────────────────────┘
```

- tab item ที่ active: พื้น `#2B3540` (Theme colour/Secondary) + ตัวอักษร `#58D68D` (Primary/500) + icon นาฬิกา/ดวงอาทิตย์ `ต้องดึงชื่อ icon`
- หัวข้อ "Environment" = `Title/Bold` (Inter Bold 20/25) · คำบรรยาย = `Body/Regular` (Inter 14/18) สี `Grey/500 #8C99A6`
- เส้นคั่นระหว่าง section: `White opacity/White 10%`
- **หมายเหตุฟอนต์:** token ระบุ `Inter` แต่โปรเจกต์ห้ามใช้ `font-['Inter']` กับข้อความไทย (ทำให้สระ/วรรณยุกต์เพี้ยน) → ใช้ `font-sans` ตาม [[thai-font-inter-override]]

---

## 2. หน้า Owner — `Environment setting - Owner` (node `4635:150663`)

| แถว | ข้อความจริงจาก Figma | สถานะ default |
|---|---|---|
| **Workspace weather** | การ์ด — empty state: ไอคอน info + *"Enable location to see local weather."* | ว่าง |
| **Workspace location** | *"Automatically use your current location to determine workspace weather, lighting, and visual effects."* | toggle **OFF** |
| **Weather alert notification** | *"Notify workspace members about severe weather conditions."* | toggle **ON** |
| **Time of day lighting** | *"Show lighting effects based on the current time in your workspace."* | toggle **ON** |
| **Weather visual effects** | *"Show weather effects such as rain, snow, and storms based on your workspace location."* | toggle **ON** |

- toggle เปิด = `#58D68D` · ปิด = `White opacity/White 20%` — ทำเป็น `<button>` custom ตาม [08-shadcn-ui](../../../.claude/rules/08-shadcn-ui.md) (ห้ามใช้ shadcn Switch)
- ขนาด/ระยะของ toggle + ระยะห่างแถว: `ต้องดึง`
- ⚠️ **ไม่มี location picker / ไม่มีปักหมุด / ไม่มีช่องค้นชื่อเมืองในหน้านี้เลย** → ดู [§6](#6-จุดที่-design-ขัดกับ-spec--ต้องเคลียร์ก่อน-implement) ข้อ A
- คำว่า **"snow"** อยู่ในคำบรรยายของ Weather visual effects → design คาดหวัง effect หิมะ (ตอบข้อ 29 บางส่วน)

### สถานะที่เหลือของหน้า Owner (มีใน Figma แล้ว ยังไม่ถอดรายละเอียด)
| node | สถานะ | sticky note ที่ PM เขียนไว้ |
|---|---|---|
| `4635:172688` | Owner + **browser permission dialog** (380×132) | "Location ขอ Access ทางด้านหน้าตั้งแต่เริ่มแรกเข้ามาใน Workspace" |
| `4635:174281` | Owner + **General modal** (458×188) | "(เผื่อ) กรณีที่ผู้ใช้งานกด Block access" |
| `4635:173005` / `4635:173981` | Owner สถานะอื่น | — |
| `4853:206702` | Owner + General modal (ชุดที่ 2) | — |

**browser permission dialog** ที่วาดไว้ในไฟล์ (เป็น mock ของ dialog ที่เบราว์เซอร์แสดงเอง):
`dialog-header-row` (site-title + ปุ่มปิด 16×16) · `permission-item-row` (icon Location 16×16 + label) · `dialog-actions-row` (button-allow 74×32 / button-block 75×32)
→ **เป็นภาพประกอบ flow เท่านั้น เราวาด dialog นี้เองไม่ได้** เบราว์เซอร์เป็นคนแสดง — สิ่งที่เราทำได้คือหน้า "ก่อนขอ" และ "หลังถูก block"

---

## 3. หน้า Member / Admin — `Environment setting - Member` (node `4722:490642`)

| แถว | ข้อความจริงจาก Figma | ต่างจาก Owner |
|---|---|---|
| **Workspace weather** | การ์ด — empty state: *"Weather information isn't available yet."* | **ข้อความ empty ต่างจาก owner** |
| **My location** | *"Automatically use your current location to determine **your local weather and severe weather alerts**."* | **แถวนี้แทน "Workspace location"** |
| **Time of day lighting** | *"Show lighting effects based on the current time in your workspace."* | เหมือน owner |
| **Weather visual effects** | *"Show weather effects such as rain, snow, and storms based on your workspace location."* | เหมือน owner |
| ~~Weather alert notification~~ | — | **ไม่มีในหน้า member** (owner-only) |

### สถานะเปิด My location แล้ว (node `4836:34396`) — **2 การ์ด**

```
Workspace weather                    Mon, 01 Aug 2026, 14:00 (GMT+7)
┌───────────┬──────────────────────────────────────────────────┐
│  [icon]   │  Asoke District                Precipitation: 0% │
│  Mostly   │  19°                             Humidity: 73%  │
│  cloudy   │                                   Wind: 27 km/h │
│           │  ┌────────────────────────────────────────────┐  │
│           │  │ Source : Open-Meteo                        │  │
└───────────┴──┴────────────────────────────────────────────┴──┘

Your weather                         Mon, 01 Aug 2026, 14:00 (GMT+7)
┌───────────┬──────────────────────────────────────────────────┐
│  [icon]   │  Chiang Mai                    Precipitation: 0% │
│  Mostly   │  19°                             Humidity: 73%  │
│  cloudy   │                                   Wind: 27 km/h │
│           │  │ Source : Open-Meteo                        │  │
└───────────┴──┴────────────────────────────────────────────┴──┘
```

ข้อมูลที่การ์ดต้องมี (ตรงกับ field ที่ provider ให้ได้ทั้งหมด):
`ชื่อสถานที่ระดับเขต/อำเภอ` · `อุณหภูมิ °` · `ข้อความสภาพอากาศ` · `Precipitation %` · `Humidity %` · `Wind km/h` · `วันที่ + เวลา + timezone` · `แถบ Source พร้อมลิงก์`

⚠️ **3 จุดที่ต้องตัดสิน**: ชื่อสถานที่ละเอียดระดับ **"Asoke District"** (เขต ไม่ใช่จังหวัด) · แถบ **"Source : Open-Meteo"** ขัดกับมติ MD · การ์ด "Your weather" = per-user (ดู §6)

---

## 4. Design tokens (ดึงจริงจาก Figma — ใช้ค่าเหล่านี้เท่านั้น)

| Token | ค่า | ใช้กับ |
|---|---|---|
| `Background/Primary` · `Theme colour/Primary` | `#242B32` | พื้น modal / พื้นการ์ด |
| `Theme colour/Secondary` | `#2B3540` | พื้น tab ที่ active / พื้น sidebar |
| `Primary/500` | `#58D68D` | toggle เปิด · ตัวอักษร tab active |
| `Red/500` | `#F03A3A` | ปุ่ม/สถานะอันตราย |
| `Red/20%` | `#D41818` | — |
| `Purple/500` | `#996ADF` | — |
| `Grey/500` | `#8C99A6` | ข้อความรอง |
| `Grey/200` | `#CAD0D6` | ข้อความ/เส้นอ่อน |
| `Grey/800` | `#4D545B` | เส้น/พื้นจาง |
| `Shade Black/500` · `Shade Black/50%` | `#1A1B1E` | เงา / overlay |
| `Solid White` 100/20/10/5% | `#FFFFFF` + alpha | ข้อความหลัก · เส้นคั่น · พื้น hover |

| Typography | ค่า |
|---|---|
| `Title/Bold` | Inter Bold 20 / line 25 / ls 0 |
| `Body/Medium` | Inter Medium 14 / line 18 / ls 0 |
| `Body/Regular` | Inter Regular 14 / line 18 / ls 0 |
| `Caption/Regular` | Inter Regular 12 / line 16 / ls 0 |
| `Caption 1/Medium` | Inter Medium 12 / line 15 / **ls −0.43** |

---

## 5. Node index ต่อ scenario

| Scenario | Figma node | ถอดแล้ว? |
|---|---|---|
| HP-01 Owner ตั้งค่า Location | `4635-149039` (section) → `4635:150663` owner · `4722:490642` member · `4836:34396` location ON · `4635:172688` permission dialog · `4635:174281` block case | ✅ owner/member/location-on · ⏳ dialog + block |
| HP-02 Time of Day | `4635-175947` | ❌ |
| HP-03 Weather effect + widget | `4646-531699` | ⏳ ถอด metadata แล้ว — **มีแต่ effect บน map ไม่มีตัว widget/ปุ่มเปิดเลย** (ดู [§9.2](#92-สิ่งที่ design-ไม่มี-แต่-spec-บังคับ)) |
| HP-04 Alert banner | `4654-536054` | ❌ |
| HP-05 ปิด effect (personal) | `4839-34795` | ❌ |
| HP-06 ปิด Workspace Location | `4872-587869` *(ซ้ำกับ EP-01)* | ⏳ ได้ภาพรวม section แล้ว ยังไม่ zoom |
| HP-07 ปิด Alert Notification | `4872-593891` | ❌ |
| EP-01 API ล่ม | `4872-587869` | ⏳ |
| EP-02 นอกไทย | *(ไม่มี node แนบ)* | — |
| EC-01 คนละ timezone | `4779-678975` → panel `4779:680515` · การ์ด `4779:680767` | ✅ ถอดครบแล้ว (C4) — ดู [§9](#9-weather-panel--widget-c4--ถอดจริง-2026-09-09) |
| EC-02 Emergency alert | `4779-682160` | ❌ |
| EC-03 เปลี่ยน location กลางคัน | `5505-952140` | ❌ |

---

## 6. จุดที่ design ขัดกับ spec — ต้องเคลียร์ก่อน implement

| # | ประเด็น | spec เขียนไว้ | Figma แสดง |
|---|---|---|---|
| **41** | **วิธีได้ location** | HP-01: "ปักหมุด location ได้" (และ EP-02: autocomplete ค้นเมืองทั่วโลก) | **ไม่มี picker เลย** — เป็น toggle *"Automatically use your current location"* คือขอ **ตำแหน่งจากเบราว์เซอร์** ⇒ ตอบข้อ 9 ว่า **ไม่ใช่ทั้งปักหมุดและค้นชื่อ** แต่พลิกทั้ง flow: ต้องขอ permission, จัดการกรณี block, และ owner ต้องอยู่ ณ ที่ตั้งนั้นตอนเปิด |
| **42** | **ใครเป็นเจ้าของ location** | Location Policy: "ยึดตาม location ของ Workspace Owner — **ไม่ใช่ user แต่ละคน** · ทุกคนเห็น environment เดียวกัน" (EC-01 ทั้ง scenario สร้างมาเพื่อยืนยันข้อนี้) | หน้า member มี **"My location"** + การ์ด **"Your weather"** แยกอีกใบ ⇒ เป็นโมเดล **2 ชั้น**: workspace (effect บน map) + personal (อากาศ/alert ของตัวเอง) — **ยังไม่มีใน spec เลย** |
| **43** | **แหล่งข้อมูลที่โชว์ผู้ใช้** | มติ MD 9 ก.ย.: ใช้ Google + กรมอุตุฯ + GDACS · **Open-Meteo เลื่อน** | การ์ดมีแถบ **"Source : Open-Meteo"** เป็นลิงก์ ⇒ ต้องเปลี่ยนป้ายเป็นแหล่งจริง และตรวจข้อกำหนด attribution ของ Google |
| **44** | **ความละเอียดของชื่อสถานที่** | ไม่ระบุ | **"Asoke District"** = ระดับเขต/แขวง ⇒ reverse geocode ต้องคืนระดับ district ไม่ใช่จังหวัด (กระทบการเลือก provider geocode และขนาด cache cell 28 กม. ที่ออกแบบไว้) |
| **45** | **PII: เก็บตำแหน่งของ member** | ไม่มีใน spec | ถ้ามี "My location" จริง = เก็บพิกัดของบุคคล ⇒ ต้องมี consent + นโยบายความเป็นส่วนตัว + สิทธิ์ลบ · และ **quota/ค่าใช้จ่ายเปลี่ยนจาก "ต่อ workspace" เป็น "ต่อผู้ใช้"** ซึ่งกระทบงบที่เสนอ MD ไปแล้ว |
| **46** | ตำแหน่ง toggle ของ owner vs member | HP-06/07 เขียนว่าอยู่ "Settings บน VO HUD หรือ User Preferences" | อยู่ใน **Setting modal → tab Environment** ทั้งคู่ โดย**สลับชุด toggle ตาม role** (owner เห็น Workspace location + alert notification · member เห็น My location) ⇒ ตอบข้อ 34 |

**ข้อ 33 ตอบแล้วจาก design:** HP-07 = toggle **"Weather alert notification"** ตัวเดียวกับที่อยู่ในหน้า Owner ของ HP-01 — **ไม่ใช่ toggle ใหม่** · และ HP-06 = toggle **"Workspace location"** ตัวเดียวกัน ⇒ ทั้งสอง scenario เป็นการอธิบายสถานะ OFF ของ toggle ที่มีอยู่แล้ว ไม่ใช่ฟีเจอร์เพิ่ม

---

## 7. สิ่งที่ยังต้องถอดเพิ่ม

### 7.1 node ที่ต้องดึงก่อน implement แต่ละส่วน (ดึงเองได้ ไม่ต้องขอภาพ)
`4635-175947` (HP-02 แสง) · `4646-531699` (HP-03 effect + widget บน map) · `4654-536054` (HP-04 banner) · `4839-34795` (HP-05) · `4872-593891` (HP-07) · `4779-678975` (EC-01 tooltip) · `4779-682160` (EC-02 emergency) · `5505-952140` (EC-03 toast) · `4635:172688` + `4635:174281` (permission / block case)
⇒ ต้องเรียก `get_design_context` ก่อนเขียนโค้ดของแต่ละส่วน เพื่อได้ spacing/px จริง (ไฟล์นี้ยังมีแต่โครงกับข้อความ)

### 7.2 asset ที่ได้รับแล้ว (2026-09-09) — `storage/[Feature]  · Environment (Time of Day + Weather) — Virtual Office Map/`

**27 GIF + 1 PNG · รวม 4.7 MB** — เป็น **pixel art แบบเคลื่อนไหวสำหรับวางบนฉาก** ไม่ใช่ไอคอนแบนสำหรับการ์ด (ต่างจากที่คาดไว้ตอนแรก)

| โฟลเดอร์ | ไฟล์ | ขนาด canvas | ใช้ทำ |
|---|---|---|---|
| `Bg/` | `Bg_zyra.png` | 2560×1440 | **backdrop นอกแมพ** — ท้องฟ้า + เส้นขอบฟ้า/ทะเล + ทุ่งหญ้า |
| `gif for dev/sun/` | `Sun.gif` | 1600×1600 · ~5 เฟรม | ดวงอาทิตย์บนแถบฟ้า |
| `gif for dev/moon/` | `moon.gif` | 1600×1600 | ดวงจันทร์ (กลางคืน) |
| `gif for dev/star/` | `big-star` `small-yellow-star` `yellow-star` `white-star` `blue-star` `purple-star` `shooting-star` | 320×320 (shooting-star 2560×2240) | **ดาวระยิบ 6 แบบ + ดาวตก** |
| `gif for dev/cloud/` | `cloud1` `cloud2` `cloud3` | 1700×1600 · 1600×960 · 1920×640 · ~6 เฟรม | ก้อนเมฆลอย |
| `gif for dev/fog/` | `fog.gif` | 2240×480 · ~6 เฟรม | แถบหมอกแนวนอน (ต่อกันซ้าย-ขวาได้) |
| `gif for dev/rain/` | `rain1` `rain2` (512×512) · `rain3` (274×458) · `rain4` (224×224) · `thunder` (1600×1600) | | ฝน 4 ระดับ + ฟ้าแลบ |
| `gif for dev/snow/` | `snow1` (70×1600) `snow2` (137×1600) `snow3` (64×1600) `snow4` (80×1600) | ~8 เฟรม | **แถบหิมะตกแนวตั้ง** — เกล็ดตกในตัว GIF เอง ไม่ต้องเขียน particle |
| `gif for dev/wind/` | `wind1` (553×305) `wind2` (494×195) `wind3` (226×252) · `leaf` (930×434) `leaf2` (964×293) | | ลมพัด + ใบไม้ปลิว |

### 7.2.1 ⚠️ ต้องขอไฟล์ต้นฉบับขนาด 1× ก่อนนำไปใช้

ไฟล์ที่ได้เป็น pixel art ที่ถูก **upscale ราว 100 เท่า** (ตรวจจาก `Sun.gif`: พิกเซลจริงกว้างประมาณ 100 px บน canvas 1600 px ⇒ อาร์ตจริงคือ ~16×16)

ปัญหาถ้าใช้ไฟล์ปัจจุบันตรง ๆ ใน Pixi — GIF ถูก decode เป็นเท็กซ์เจอร์ทุกเฟรม:

| ไฟล์ | ประมาณหน่วยความจำ (กว้าง × สูง × 4 ไบต์ × เฟรม) |
|---|---|
| `cloud1.gif` 1700×1600 × 6 | **≈ 65 MB** |
| `Sun.gif` 1600×1600 × 5 | **≈ 51 MB** |
| `shooting-star.gif` 2560×2240 | **≈ 100 MB+** |
| `fog.gif` 2240×480 × 6 | ≈ 25 MB |

⇒ โหลดพร้อมกันหลายไฟล์ = **หลายร้อย MB** จะพังบนมือถือและ Safari แน่ (เคยเจอเพดานหน่วยความจำ canvas บน iOS มาแล้ว) และยังซ้ำรอย "กินเน็ตแล้วว้าป" จากการโหลด asset พรวดตอน mount

**ตัวคูณจริงที่วัดได้** (วัดจากความกว้างของบล็อกพิกเซลในไฟล์ ไม่ได้เดา) — **ไม่เท่ากันทุกไฟล์**:

| ไฟล์ | canvas | บล็อกพิกเซล | ขนาด 1× ที่ควรเป็น |
|---|---|---|---|
| `Sun.gif` · `moon.gif` | 1600×1600 | 10 px | **160×160** |
| `cloud1.gif` | 1700×1600 | 10 px | **170×160** |
| `snow1.gif` | 70×1600 | 10 px | **7×160** |
| `fog.gif` | 2240×480 | 5 px | **448×96** |
| `rain1.gif` | 512×512 | 2 px | **256×256** |
| `leaf.gif` | 930×434 | 6 px | **155×72** |
| `shooting-star.gif` | 2560×2240 | **วัดไม่ได้** (มี anti-alias/ไล่สี) | ต้องขอต้นฉบับ |

### ✅ ย่อแล้ว (2026-09-09) — `storage/env-weather/1x/`

**4.41 MB → 909 KB (−79.9%)** · หา factor ด้วยการทดสอบ *ย่อแล้วขยายกลับต้องได้พิกเซลเดิมเป๊ะ* แล้วตรวจซ้ำทั้ง timeline (ลำดับภาพ + duration ต่อช่วง + เวลารวม) — **ผ่านทุกไฟล์ ไม่มีพิกเซลไหนเปลี่ยน**

| ไฟล์ | ย่อ | ผลลัพธ์ |
|---|---|---|
| `sun/Sun` `moon/moon` `rain/thunder` | 10× | 160×160 · 51 MB → 0.5 MB ตอน decode |
| `cloud/cloud1–3` | 10× | ถึง 170×160 |
| `fog/fog` | 5× | 448×96 |
| `snow/snow1` `snow4` | 10× | 7×160 / 8×160 |
| `snow/snow3` `rain/rain4` `wind/wind3` | 2× | — |
| `star/*` (4 ไฟล์) | 5–10× | 32×32 / 64×64 |
| `wind/leaf` | 6× | 155×72 |

**ยังย่อไม่ได้ (คงไฟล์เดิม)** — เป็นไฟล์ที่ไม่ใช่ pixel art แท้ (มี anti-alias/ไล่สี) จึงย่อแบบไม่เสียพิกเซลไม่ได้:
`star/shooting-star` (**153 MB ตอน decode — ต้องขอต้นฉบับ**) · `bg/zyra-backdrop.png` (14 MB) · `wind/leaf2` (8.6 MB) · `wind/wind1` (5.1 MB) · `snow/snow2` (6.7 MB) · `rain/rain1` `rain2` (6 MB ต่อไฟล์) · `star/big-star` `white-star` · `rain/rain3` · `wind/wind2`

⇒ ถ้าโหลด `shooting-star` + `bg` + `leaf2` พร้อมกันจะเกินงบ 24 MB ที่ตั้งไว้ใน [technical-design §14.2](technical-design.md#142-งบหน่วยความจำ--บังคับ) ⇒ **ขอต้นฉบับ 1× ของ 3 ไฟล์นี้ หรืออนุญาตให้ย่อแบบยอมเสียรายละเอียด**

### 7.2.2 ยังขาด: ไอคอนสำหรับการ์ดใน Setting
asset ชุดนี้เป็นของฉาก — **การ์ด "Workspace weather" / "Your weather" และ widget บนแมพยังไม่มีไอคอน** (ในภาพ Figma เป็นภาพประกอบ 3D คนละสไตล์กับ pixel art ชุดนี้)
2 ทางเลือก — ต้องให้ดีไซน์ตัดสิน:
1. ใช้ GIF ชุดนี้เป็นไอคอนในการ์ดด้วย (มี sun / moon / cloud / rain / snow / fog ครบ) → สไตล์ pixel art ทั้งแอป แต่ต่างจากที่วาดไว้ใน Figma
2. ส่งไอคอน 3D ตามที่ Figma วาด เพิ่มอีกชุด (11 ไฟล์ตามตารางเดิมด้านล่าง)

### 7.2.3 mapping asset → condition (ที่ทำได้จากของที่มี)

| condition | WMO | asset ที่ใช้ | หมายเหตุ |
|---|---|---|---|
| `clear` (วัน) | 0, 1 | `sun/Sun.gif` | |
| `clear` (คืน) | 0, 1 | `moon/moon.gif` + `star/*` | ดาวเป็นของใหม่ที่ spec ไม่มี |
| `partly_cloudy` | 2 | `sun/Sun.gif` + `cloud/cloud1..3` | ประกอบเอง ไม่มีไฟล์รวม |
| `cloudy` | 3 | `cloud/cloud1..3` | |
| `fog` / `haze` | 45, 48 | `fog/fog.gif` | ต่อกันแนวนอน |
| `drizzle` | 51–57 | `rain/rain4.gif` (เล็กสุด) | **ต้องยืนยันว่าใช้ตัวไหนแทนฝนปรอย** |
| `rain` | 61–67, 80–82 | `rain/rain1..3` | 3 ระดับความหนัก |
| `thunderstorm` | 95–99 | `rain/rain1..3` + `rain/thunder.gif` | |
| `snow` | 71–77, 85–86 | `snow/snow1..4` | แถบแนวตั้ง ต่อกันแนวนอน |
| `windy` | *(คำนวณจากลมกระโชก)* | `wind/wind1..3` + `wind/leaf`, `leaf2` | |

### 7.2.4 เส้นทางไฟล์
`storage/...` เป็นที่เก็บต้นฉบับ · ตอน implement ต้องอัปขึ้น **Cloudflare R2** แล้วเก็บ public URL ตาม [11-s3-storage](../../../.claude/rules/11-s3-storage.md)
key ที่เสนอ (ชื่อสะอาด ไม่มีช่องว่าง/วงเล็บแบบชื่อโฟลเดอร์ปัจจุบัน): `static/env/sky/sun.gif` · `static/env/sky/moon.gif` · `static/env/sky/star-<name>.gif` · `static/env/sky/cloud-<n>.gif` · `static/env/fx/rain-<n>.gif` · `static/env/fx/snow-<n>.gif` · `static/env/fx/fog.gif` · `static/env/fx/wind-<n>.gif` · `static/env/fx/leaf-<n>.gif` · `static/env/bg/zyra-backdrop.png`

### 7.2.5 พระจันทร์ 5 phase — ได้รับ + อัปขึ้น R2 แล้ว (2026-09-10)

ต้นฉบับ: `storage/[Feature] · Environment .../gif for dev/พระจันทร์แบบแยก/moon1–5.gif` (1600×1600 · 1 เฟรม · 92–121 KB)
ย่อ 1× ไว้ที่ `storage/env-weather/1x/moon/` แล้วอัปขึ้น **R2 bucket `zgather-dev`** ตาม [11-s3-storage](../../../.claude/rules/11-s3-storage.md)

| ไฟล์ต้นฉบับ | phase | key บน R2 | public URL | ขนาด 1× |
|---|---|---|---|---|
| moon1 | เต็มดวง | `static/env/sky/moon-full.gif` | [ดู](https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/env/sky/moon-full.gif) | 6,700 B |
| moon5 | เสี้ยวข้างขึ้น (สว่างขวา) | `static/env/sky/moon-waxing-crescent.gif` | [ดู](https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/env/sky/moon-waxing-crescent.gif) | 4,909 B |
| moon4 | ขึ้น 8 ค่ำ (สว่างขวา) | `static/env/sky/moon-first-quarter.gif` | [ดู](https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/env/sky/moon-first-quarter.gif) | 5,242 B |
| moon2 | แรม 8 ค่ำ (สว่างซ้าย) | `static/env/sky/moon-last-quarter.gif` | [ดู](https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/env/sky/moon-last-quarter.gif) | 5,188 B |
| moon3 | เสี้ยวข้างแรม (สว่างซ้าย) | `static/env/sky/moon-waning-crescent.gif` | [ดู](https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/env/sky/moon-waning-crescent.gif) | 4,897 B |

ทั้ง 5 ไฟล์ยิงจริงแล้วได้ `HTTP 200 · image/gif` · `static/env/` เป็น prefix ใหม่ ไม่ได้ทับของเดิม

**การย่อเป็น lossless จริง** — ต้นฉบับเป็นงาน 160 px ที่ถูกขยาย 10× แบบสะอาด (ตรวจแล้ว: บล็อก 10×10 ทุกบล็อกเป็นสีเดียวล้วน 25,600/25,600 บล็อก) ย่อกลับด้วย NEAREST ที่ 1/10 แล้วขยายคืนได้ pixel ตรงกันเป๊ะทั้ง 5 ไฟล์ (differing px = 0)
**494 KB → 27 KB** และหน่วยความจำตอน decode **51.2 MB → 0.51 MB** (สำคัญ เพราะเคสเดียวกับ `shooting-star` ที่กิน 153 MB จนใช้ไม่ได้)

#### 3 เรื่องที่ต้องตัดสินก่อนเอาไปใช้

| # | เรื่อง |
|---|---|
| **57** | **`moon/moon.gif` เดิมใช้ต่อไม่ได้** — มันคือ 5 phase นี้เอามาเล่นวนกันทุก 2.5 วินาที (ตรวจแล้วว่าเป็นภาพชุดเดียวกัน ต่างกันแค่ offset 1 px) ซึ่งเป็นเหตุผลที่ design แยกไฟล์มาให้ · phase ต้องมาจาก **อายุดวงจันทร์ของวันนั้น** ไม่ใช่วนไปเรื่อย ๆ |
| **58** | **มีแค่ 5 จาก 8 phase** — ขาด **เดือนดับ (new moon)** และ **gibbous ทั้งสองข้าง** ⇒ ต้องเลือกว่า ขอไฟล์เพิ่ม 3 แบบ หรือยุบ 8 ช่วงลงใน 5 ไฟล์ที่มี (gibbous ใช้ full แทน · เดือนดับไม่วาดอะไรเลย) |
| **59** | **ซีกโลกใต้เห็นกลับข้าง** — "สว่างขวา = ข้างขึ้น" เป็นมุมมองซีกโลกเหนือ · workspace ที่ซิดนีย์จะเห็นเสี้ยวกลับด้าน ⇒ ฟีเจอร์นี้รองรับทั่วโลก จึงต้องเลือกว่า **กลับด้าน sprite เมื่อ `lat < 0`** หรือยอมให้ผิดสำหรับซีกโลกใต้ |

### 7.3 ยังไม่มีใน Figma ที่พบ
- **"shotcut หน้าหลัก"** ที่ HP-06/HP-07 บอกว่าจะหายไปด้วย — ยังไม่เห็นใน node ที่ถอด (ข้อ 36 ยังค้าง)
- หน้าจอกรณี **ประเทศที่ provider ไม่รองรับ** (จีน ญี่ปุ่น เกาหลี เวียดนาม) — design ยังไม่มีสถานะนี้ ทั้งที่รอบแรกจะเกิดขึ้นจริง ([spec §D.2](spec.md#d2-ความสามารถต่อประเทศในรอบแรก)) — **C4 ทำข้อความชั่วคราวไปแล้ว** (ข้อ 54)
- **ตัว widget บน map + ปุ่มเปิด weather panel** — ไม่มีใน node ใดเลย (ข้อ 52) ปัจจุบันสร้างจาก token ของการ์ด


---

## 9. Weather panel + widget (C4) — ถอดจริง 2026-09-09

**node:** panel `4779:680515` (458×992 · วางที่ x=966 y=16 ในเฟรม 1440×1024) · การ์ด `Weather widget` `4779:680767`
**implement:** `views/user/virtual-office/components/vo-weather-panel.tsx` (`VOWeatherPanel` + `VOWeatherBadge`) · logic แยกที่ `lib/environment-weather-display.ts`

### 9.1 ค่าที่ดึงมาจริง (ห้ามเดาเพิ่ม)

| ส่วน | spec จาก Figma |
|---|---|
| panel shell | `flex flex-col items-start gap-[16px] p-[8px] rounded-tr-[16px] rounded-br-[16px] backdrop-blur-[2px]` · bg = `linear-gradient(-90deg, #000 38.428%, transparent 100%)` (จางไปทางซ้าย ไม่ใช่พื้นทึบ) |
| header | `Weather` = `text-[20px]/[25px] font-bold` ขาว + `text-shadow: 0 2px 6px rgba(0,0,0,0.6)` · ปุ่มปิด 32×32 = `bg-white rounded-[6px] p-[8px]` ไอคอน 16px สี `#1A1B1E` |
| การ์ด | `bg-[#242B32] rounded-[16px] p-[16px] gap-[16px] flex-col justify-center overflow-clip` · สูง 170 · การ์ดที่ 2 ห่างจากใบแรก 16px |
| แถวบนการ์ด | `text-[12px]/[15px] tracking-[-0.0516px]` · ป้ายซ้ายขาว · ขวา = วันที่+เวลาขาว แล้ว `(GMT+9)` สี `#8C99A6` |
| กล่องไอคอน | `w-[107px] h-full bg-[rgba(255,255,255,0.05)] rounded-[16px] p-[8px] flex-col gap-[8px] items-center justify-center` · ตัวไอคอน 64×51 · คำบรรยาย `text-[12px] #8C99A6` |
| ชื่อเมือง | `text-[14px]/[18px]` ขาว |
| อุณหภูมิ | `text-[32px]/[36px] font-bold` + `bg-clip-text` gradient `to-b from-white to-[#383838]` |
| 3 แถวขวา | `flex-col items-end justify-between h-full` · `text-[12px]/[15px] tracking-[-0.0516px]` ป้าย `#8C99A6` ค่าขาว · `Precipitation:` / `Humidity:` / `Wind:` |
| แถบแหล่งข้อมูล | `bg-[rgba(45,182,255,0.1)] rounded-[8px] p-[8px] w-full` · `text-[10px]/[13px] tracking-[-0.043px] #2DB6FF` · ชื่อ provider **ขีดเส้นใต้** |

token ยืนยันเพิ่ม: `Shade Black/500 #1A1B1E` (ไอคอนบนปุ่มขาว) · `Title/Bold 20/25` · `Caption 2/Regular 10/13`

### 9.2 สิ่งที่ design ไม่มี แต่ spec บังคับ

| # | เรื่อง | ทำอะไรไป |
|---|---|---|
| **52** | **ไม่มี widget มุมขวาบน map และไม่มีปุ่มเปิด panel เลย** — HP-03 เขียนชัดว่า "widget มุมขวาบน map · กด widget เปิด popup" แต่เฟรม HP-03 ทั้ง 5 (`5522:988863`, `5522:990213`, `5522:989413`, `5543:1019179`, `5522:989596`) มีแต่ effect กับ Map tools/Minimap เดิม | สร้าง `VOWeatherBadge` จาก **token ของการ์ดเอง** (#242B32 / radius 16 / 12-15 / #8C99A6) ไม่คิดค่าใหม่ · **ยังไม่มี node — ถ้า design ทำมาให้ ต้องแก้ตาม** |
| **53** | ไอคอนสภาพอากาศในการ์ดเป็น **ภาพ 3D** (`4624:148020-22` = เงาเบลอ + ดวงอาทิตย์ + เมฆ) ยังไม่ส่งมอบ (ต่อจากข้อ 49) — asset ที่ได้มาเป็น pixel art ของบนแผนที่ | ใช้ `lucide-react` แทนชั่วคราว **ในกรอบเดิม** (107px / 64×51) เปลี่ยนกลับได้ที่จุดเดียว |
| **54** | ไม่มีเฟรมของ **สถานะ stale** (EP-01) และไม่มีเฟรมของ **3 สาเหตุที่ไม่มีข้อมูล** ([technical-design §13.1](technical-design.md)) | ทำ badge "May be out of date" + การ์ดว่าง 3 ข้อความแยกกัน จาก token เดิม (`White/5%` + `Grey/500`) · **ห้ามยุบเป็นข้อความเดียว** |
| **55** | การ์ด `Precipitation:` ต้องมีค่า แต่ `WeatherSnapshot` เดิมไม่มีฟิลด์นี้เลย | เพิ่ม `precip_pct` (api commit `6142a24`) — อ่านจาก `precipitation.probability.percent` ของ Google · เป็น **pointer/optional** เพราะ "0% = ไม่มีฝน" ต่างจาก "provider ไม่รายงาน" (แสดง `—`) |
| **56** | การ์ดที่ 2 **"Your weather"** ยังทำไม่ได้ — ผูกกับโมเดล "My location" ที่ยังไม่ตัดสิน (ข้อ 42/45) | ทำแค่การ์ด workspace · `WeatherCard` รับ label เป็น prop ไว้แล้ว เพิ่มการ์ดที่ 2 = เพิ่ม call site เดียว |

**ตำแหน่งบนจอ:** panel/badge ใช้ slot มุมขวาบนเดิม (`fixed right-[24px] top-[24px] z-40`) ร่วมกับ pet panel / player card / PZ card และ **หลบให้ทั้งสาม** (การ์ดเหล่านั้นเกิดจากคลิกบนแผนที่โดยเจตนา) — design วาง panel ที่ x=966 y=16 ซึ่งกินพื้นที่เดียวกัน

---

## 8. Layer model ที่ได้จาก asset (ยืนยันจาก `Bg_zyra.png`)

`Bg_zyra.png` เป็นฉากหลัง **นอกแมพ** (ท้องฟ้า → เส้นขอบฟ้า/ทะเล → ทุ่งหญ้า) ⇒ ตอบคำถามว่าดวงอาทิตย์/ดวงจันทร์/ดาว วางที่ไหน: **ในแถบท้องฟ้าของฉากหลัง** ไม่ใช่ทับบนพื้นแมพ

| z | เลเยอร์ | asset | ขอบเขต |
|---|---|---|---|
| 0 | ฉากหลังนอกแมพ | `Bg_zyra.png` | รอบขอบแมพ (ต่อกับ outside display ที่มีอยู่แล้วใน VO) |
| 1 | วัตถุบนท้องฟ้า | `Sun` / `moon` / `star/*` / `cloud/*` | เฉพาะแถบฟ้าของฉากหลัง |
| 2 | แมพ (tiles + object + avatar) | — | ของเดิม ไม่แตะ |
| 3 | เอฟเฟกต์อากาศทับทั้งจอ | `rain/*` `snow/*` `fog` `wind/*` `leaf*` | ทับทั้ง viewport |
| 4 | แผ่นสีตามช่วงเวลา | วาดด้วยโค้ด (ค่า rgba อยู่ใน spec) | ทับทั้ง viewport |
| 5 | HUD / widget / banner | — | DOM overlay ต้องกำหนด z เอง ไม่งั้นจะไปอยู่หลังแมพ |

⚠️ **สิ่งที่ spec ยังไม่มีและต้องเพิ่ม**: ดาว 6 แบบ + ดาวตก + ดวงจันทร์ + ฉากหลังท้องฟ้า — ตาราง Night stage ในสเปกพูดถึงแค่ "overlay มืด สีน้ำเงินเข้ม" (ข้อ 47 ใน [spec ภาคผนวก F](spec.md))
