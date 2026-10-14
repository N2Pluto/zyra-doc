# Mobile App — รวม Issue / Feedback จาก QA แยกตามแนวจอ (แนวตั้ง / แนวนอน)

> **สถานะ:** รอบที่ 2 — ไล่ root cause จากโค้ด `origin/develop` ครบทุกข้อแล้ว และเขียนลง ClickUp แล้ว (แก้ description การ์ดเดิม 41 ใบ + เปิดการ์ดใหม่ 27 ใบ) · **ยังไม่ได้ทดสอบบนเครื่องจริง** · ดู [รอบที่ 2](#รอบที่-2--2026-10-12) · **วันที่:** 2026-10-12
> **Repo ที่กระทบ:** zyra-app (Capacitor app + mobile web), zyra-ws, zyra-api
> **ที่มา:**
> - ClickUp — subtask ประเภท `Issue` / `Feedback` ใต้ [[Feature] · Mobile Responsive + App Conversion (iOS & Android)](https://app.clickup.com/t/86d4bfpym) (สร้างโดย QA, 2026-10-08 → 2026-10-12)
> - FigJam — [Zyra-refine › Page 1](https://www.figma.com/board/c4lGPkIUagCV9J6m9hHLzy/Zyra-refine?node-id=537-301) (sticky จาก session refine)
>
> สถานะ ClickUp ในเอกสารนี้เป็น snapshot ณ 2026-10-12 — ดูค่าล่าสุดใน ClickUp

## นิยามแนวจอ

ตามมติ 2026-09-30 ([plan/MobileApp/clickup-spec.md](../plan/MobileApp/clickup-spec.md) §18 ข้อ 25):

| แนวจอ | Mode | ลักษณะ |
|---|---|---|
| **แนวตั้ง** (Portrait) | **Lite** | ไม่โหลดแมพ — ใช้เมนู/list (Meeting, Member, Chat) |
| **แนวนอน** (Landscape) | **Spatial** | โหลดแมพ Phaser — เดิน, joystick, minimap, Bubble |

## วิธีจัดหมวด

- **ระบุชัด** = sticky อยู่ใต้หัว "แนวตั้ง"/"แนวนอน" ในบอร์ด หรือชื่อ issue บอกแนวจอ/mode ไว้เอง
- **อนุมาน** = ไม่ได้ระบุ แต่ฟีเจอร์นั้นมีอยู่แค่ในแนวเดียว (เช่น เดิน/joystick/Bubble มีแค่บนแมพ = แนวนอน)
- **ทั้งสองแนว** = ฟีเจอร์ใช้ได้ทั้งสองแนว (Meeting, Spotlight, Chat, Login, lifecycle ของแอป, server)
- **ต้องถาม QA** = อ่านจากชื่ออย่างเดียวแล้วจัดหมวดไม่ได้

## สรุปจำนวน

| หมวด | ClickUp | FigJam | รวม |
|---|---:|---:|---:|
| แนวตั้ง (Lite) | 4 | 9 | 13 |
| แนวนอน (Spatial) | 7 | 3 | 10 |
| ทั้งสองแนว | 27 | 21 | 48 |
| ต้องถาม QA | 3 | 0 | 3 |
| **รวม** | **41** | **33** | **74** |

> FigJam มี sticky ซ้ำกัน 1 คู่ ("เปลี่ยนภาษาเป็น Package ให้ Download") และ ClickUp มี Feedback ซ้ำกัน 1 คู่ ("ปรับเปลี่ยนปุ่ม Sportlight ให้กดปุ่ม Play ได้") — ตัวเลขข้างบนนับรวมตัวซ้ำด้วย ถ้าตัดซ้ำออกเหลือ 72 รายการ
> 🔥 = sticky ที่มีไอคอนไฟในบอร์ด (เร่งด่วน)

---

## 1. แนวตั้ง (Portrait / Lite)

| # | รายการ | ที่มา | สถานะ | จัดหมวดจาก |
|---|---|---|---|---|
| V-01 | [บางกรณีในแนวตั้ง] กดมาที่ Profile แล้วเลื่อนลงไม่ได้ | [ClickUp](https://app.clickup.com/t/14zd0zubp90) | in progress | ระบุชัด |
| V-02 | ในคอมเห็นตัวละครเดินไปมา แต่ฝั่ง mobile อยู่ใน Mode แนวตั้ง | [ClickUp](https://app.clickup.com/t/14zd0zubp93) | Open | ระบุชัด |
| V-03 | Lite Mode ตัวละครเดินเฉียง | [ClickUp](https://app.clickup.com/t/14zd0zubp9d) | Open | ระบุชัด (Lite) — น่าจะเป็นมุมที่ web เห็นคน Lite เหมือน V-02 |
| V-04 | ปุ่มย้อนกลับใน Meeting บัง Dynamic Island | [ClickUp](https://app.clickup.com/t/14zd0zubp8j) | in progress | อนุมาน — Island อยู่ขอบบนเฉพาะแนวตั้ง |
| V-05 | Start Spotlight ในแนวตั้งไม่ได้ (นับครบ 5 วิแล้ว) | FigJam `537:322` | — | ระบุชัด |
| V-06 | Pop chat space ควรกดเข้าร่วมได้เหมือนเมนู Meeting | FigJam `537:19` | — | ใต้หัว "แนวตั้ง" |
| V-07 | คนแนวตั้งไม่เห็นว่าใครเป็น Owner / Admin (แนวนอนเห็น) | FigJam `537:83` | — | ใต้หัว "แนวตั้ง" |
| V-08 | คนแนวตั้งเข้าห้อง Meeting ได้ แต่คนแนวนอนไม่เห็นว่าเข้ามา และคนแนวตั้งพูดไม่ได้ | FigJam `537:113` | — | ใต้หัว "แนวตั้ง" |
| V-09 | เมนู Meeting ใช้ไม่ได้ทุกเมนู เหมือนเราไม่มีตัวตน | FigJam `537:156` | — | ใต้หัว "แนวตั้ง" |
| V-10 | แนวตั้งกด Instant Meeting → คนแนวนอนวิ่งเข้าห้อง Meeting แต่ฝั่งแนวตั้งไปเห็นห้อง Meeting ในเมนูหน้าแรก | FigJam `537:190` | — | ใต้หัว "แนวตั้ง" |
| V-11 | แนวตั้งเห็นแนวตั้งด้วยกัน — ปิดแอป (Q app) ไปแล้วยังเห็นว่าอยู่ใน Meeting | FigJam `537:266` | — | ใต้หัว "แนวตั้ง" |
| V-12 | แนวตั้งกดออกจากห้องประชุมแล้ว ขึ้นว่าออกแล้ว แต่หน้าจอยังค้าง | FigJam `537:308` | — | ใต้หัว "แนวตั้ง" |
| V-13 | 🔥 Web เห็นคน Mobile วาร์ปมาพร้อมประกายแสง ไม่ต้องเดิน | FigJam `537:11` | — | อนุมาน — คน Lite ไม่มีแมพ เดินไม่ได้ |

## 2. แนวนอน (Landscape / Spatial)

| # | รายการ | ที่มา | สถานะ | จัดหมวดจาก |
|---|---|---|---|---|
| H-01 | เข้า Workspace แนวนอนครั้งแรกไม่ได้ แต่เข้า Workspace แนวนอนอื่นได้ | [ClickUp](https://app.clickup.com/t/14zd0zubp8b) | in progress | ระบุชัด |
| H-02 | กด Spatial → เปลี่ยนเป็น Lite → กลับเป็น Spatial แล้วแมพไม่แสดง | [ClickUp](https://app.clickup.com/t/14zd0zubp96) | Open | ระบุชัด (อาการเกิดตอนกลับเข้า Spatial) |
| H-03 | จับ Bubble แล้ว flow ไม่ถูก ต้องแสดงเป็น Meeting | [ClickUp](https://app.clickup.com/t/14zd0zubp95) | Open | อนุมาน — Bubble มีแค่บนแมพ |
| H-04 | อยู่ใน Bubble แล้วกด Request to join ไม่ได้ | [ClickUp](https://app.clickup.com/t/14zd0zubp9a) | Open | อนุมาน — Bubble |
| H-05 | ตัวละครอยู่ใน Meeting room บนแมพ พอมีคนเข้าร่วมกลับเข้าร่วมไม่ได้ ต้องกดเมนู Meeting เอง | [ClickUp](https://app.clickup.com/t/14zd0zubp9c) | Open | อนุมาน — ยืนในห้องบนแมพ |
| H-06 | Feedback: เพิ่มปุ่ม "เดินไปหา" เมื่อกดโปรไฟล์คนอื่น | [ClickUp](https://app.clickup.com/t/14zd0zubpa8) | Open | อนุมาน — เดินได้แค่บนแมพ |
| H-07 | Feedback: ขอบเขตของ joystick | [ClickUp](https://app.clickup.com/t/14zd0zubpa9) | Open | อนุมาน — joystick มีแค่ Spatial |
| H-08 | เมนู Meeting กดเข้าห้องที่มีคนอยู่ไม่ได้ แต่กดห้องว่างได้ | FigJam `537:170` | — | ใต้หัว "แนวนอน" |
| H-09 | เมนู Member — ถ้า Member อยู่ใน Meeting หรือ Circle ให้แสดงปุ่มเข้าร่วม | FigJam `537:207` | — | ใต้หัว "แนวนอน" |
| H-10 | เมนู Meeting ที่เป็นวงกลม (ด้านขวา) — ห้องที่มีคนใช้อยู่ควรแสดงว่าไม่ว่าง หรือแสดงต่างจากห้องปกติ | FigJam `537:214` | — | ใต้หัว "แนวนอน" |

## 3. ทั้งสองแนว (ไม่ขึ้นกับแนวจอ)

### 3.1 Meeting

| # | รายการ | ที่มา | สถานะ |
|---|---|---|---|
| B-01 | User ที่ไม่ใช่ Host กด Mute Mic all ได้ | [ClickUp](https://app.clickup.com/t/14zd0zubp8p) | in progress |
| B-02 | กดเข้าร่วม Meeting แล้วหน้าจอขาว | [ClickUp](https://app.clickup.com/t/14zd0zubp9b) | Open |
| B-03 | กด Join Meeting อีกห้องแล้วเห็นตัวเองอยู่อีกห้อง | [ClickUp](https://app.clickup.com/t/14zd0zubp9e) | Open |
| B-04 | Request to Join ห้องที่ล็อค — Accept แล้วยังเข้าห้องไม่ได้ | [ClickUp](https://app.clickup.com/t/14zd0zubp9n) | Open |
| B-05 | Action in meeting กดไม่ได้ | [ClickUp](https://app.clickup.com/t/14zd0zubp9p) | Open |
| B-06 | กด Instant Meeting แล้วหน้าจอกะพริบ | [ClickUp](https://app.clickup.com/t/14zd0zubp9t) | Open |
| B-07 | Feedback: เพิ่มปุ่ม Invite ใน Meeting | [ClickUp](https://app.clickup.com/t/14zd0zubpa4) | Open |
| B-08 | Preview กล้องแสดงไม่เต็มหน้าจอ (ซ้ำกับ B-37) | [ClickUp](https://app.clickup.com/t/14zd0zubzmd) | Open |
| B-09 | ปุ่ม `<` `>` ใน Meeting กะพริบเป็นจังหวะเมื่อมี 6 คนขึ้นไป | FigJam `537:315` | — |
| B-10 | จอขาวบางครั้ง แล้วเด้งออกจาก Meeting แต่สถานะยังอยู่ใน Meeting | FigJam `537:329` | — |
| B-11 | จำนวนคนไม่อัปเดต และขึ้นผิดคนในห้อง Meeting | FigJam `537:294` | — |
| B-12 | รูป Profile ใน Chat ของ Meeting เป็นรูปตัวละคร | FigJam `537:163` | — |

### 3.2 Spotlight

| # | รายการ | ที่มา | สถานะ |
|---|---|---|---|
| B-13 | ยอด Spotlight ไม่แสดง | [ClickUp](https://app.clickup.com/t/14zd0zubp8x) | in progress |
| B-14 | เริ่ม Spotlight แล้ว Host กดปิด Spotlight ไม่ได้ | [ClickUp](https://app.clickup.com/t/14zd0zubyh0) | Open |
| B-15 | Feedback: ปรับปุ่ม Spotlight ให้กดปุ่ม Play ได้ | [ClickUp](https://app.clickup.com/t/14zd0zubpa2) | Open |
| B-16 | Feedback: ปรับปุ่ม Spotlight ให้กดปุ่ม Play ได้ (**ซ้ำกับ B-15**) | [ClickUp](https://app.clickup.com/t/14zd0zubpa3) | Open |
| B-17 | Spotlight กด Action ไม่ได้ (ทั้ง Host spotlight และ Member กดไม่ได้ทุก Action) | FigJam `537:221` | — |
| B-18 | กดดู Member Viewer แล้วทับซ้อนกับ Member | FigJam `537:231` | — |
| B-19 | Member เลื่อนเมนู Member ขึ้นลงไม่ได้ เลยดูอะไรไม่ได้ | FigJam `537:238` | — |
| B-20 | หลัง Spotlight หยุด ฝั่ง Participants ที่อยู่ในห้อง Meeting มาก่อน Display หายไป และกด Action ไม่ได้ | FigJam `537:245` | — |
| B-21 | ให้ Spotlight หายไปหลังผ่านไป 1 นาที | FigJam `537:259` | — |

### 3.3 สถานะ / Presence / Real-time

| # | รายการ | ที่มา | สถานะ |
|---|---|---|---|
| B-22 | Login บน Web แล้วไม่เห็น User ที่ Login ผ่าน Mobile | [ClickUp](https://app.clickup.com/t/14zd0zubp8q) | in progress |
| B-23 | Status ตัวละครไม่แสดงเมื่อมี User ใหม่ Join แต่ Refresh แล้วเห็นปกติ | [ClickUp](https://app.clickup.com/t/14zd0zubp8t) | in progress |
| B-24 | Wave หาบัญชีที่ Status เป็น Away | [ClickUp](https://app.clickup.com/t/14zd0zubzhw) | Open |
| B-25 | Wave แล้วปิดแอป — แจ้งเตือนซ้ำ | [ClickUp](https://app.clickup.com/t/14zd0zubp9r) | Open |
| B-26 | Server ไม่อัปเดตสถานะตัวละครให้เป็นปัจจุบัน (มีหลายกรณี) — อาการเดียวกับ B-23 | FigJam `537:301` | — |
| B-27 | Wave บนมือถือ ต้องมีแจ้งเตือนเมื่อ Wave หาคนที่ไม่ว่าง — เกี่ยวกับ B-24 | FigJam `537:149` | — |
| B-28 | ตัดการเชื่อมต่อและต้อง Reload หน้าบ่อยมาก ทั้งที่สัญญาณ 5G เต็ม | FigJam `537:97` | — |

### 3.4 App lifecycle / Build

| # | รายการ | ที่มา | สถานะ |
|---|---|---|---|
| B-29 | สลับไปแอปอื่นแล้วกลับเข้ามา หน้าจอขาว | [ClickUp](https://app.clickup.com/t/14zd0zubp9g) | Open |
| B-30 | ปัดแอปทิ้งแล้วเปิดใหม่ หน้าจอดำ | [ClickUp](https://app.clickup.com/t/14zd0zubp9h) | Open |
| B-31 | 🔥 Android Build ไม่ผ่าน | FigJam `537:120` | — |
| B-32 | ให้ทำงานใน Background ต่อตอนล็อคหน้าจอ | FigJam `537:128` | — |

### 3.5 Account / Login / Workspace

| # | รายการ | ที่มา | สถานะ |
|---|---|---|---|
| B-33 | [HP-03] เลือก Keep this setting เป็น Remind me again แล้วสร้าง Workspace ใหม่ เลือกโหมดไม่ได้ | [ClickUp](https://app.clickup.com/t/14zd0zubh45) | completed |
| B-34 | [HP-03] เคลียร์ Session ใหม่เพื่อเข้าสู่ระบบ | [ClickUp](https://app.clickup.com/t/14zd0zubncm) | completed |
| B-35 | กด Account & Security แล้ว Redirect ไปหน้า Something went wrong | [ClickUp](https://app.clickup.com/t/14zd0zubp8z) | Open |
| B-36 | Login 2 เครื่องด้วยบัญชีเดียวกัน — ต้องออกจากระบบที่เครื่องเก่า | [ClickUp](https://app.clickup.com/t/14zd0zubya4) | Open |
| B-37 | Preview กล้องใน Setting View ไม่เต็มจอ (iPhone 18 PM, iOS 27) — ซ้ำกับ B-08 | FigJam `537:142` | — |
| B-38 | Invite member ผ่าน Gmail แล้วขึ้น 404 page not found | [ClickUp](https://app.clickup.com/t/14zd0zuby77) | Open |

### 3.6 UI / Layout / อื่น ๆ

| # | รายการ | ที่มา | สถานะ |
|---|---|---|---|
| B-39 | [HP-03] หน้า Manage Member แสดงผลไม่เต็มจอ | [ClickUp](https://app.clickup.com/t/14zd0zubnhm) | in progress |
| B-40 | เข้าผ่าน iPad แล้วเลื่อนจอลงไม่ได้ | [ClickUp](https://app.clickup.com/t/14zd0zubp8k) | in progress |
| B-41 | กดคีย์บอร์ดในช่อง Chat แล้วมีเส้นขาวขึ้นมา | [ClickUp](https://app.clickup.com/t/14zd0zubp9k) | Open |
| B-42 | Feedback: ไอคอนประกาศบน Mobile ให้ทำงานเหมือนบน Web | [ClickUp](https://app.clickup.com/t/14zd0zubpab) | Open |
| B-43 | คนที่ไม่เคยคุยกันกดแชร์ Meeting ในแชทส่วนตัว แชทไม่ขึ้น แต่ขึ้นแจ้งเตือน | FigJam `537:183` | — |
| B-44 | เรียงลำดับ UI Z-Index ใหม่ตามห้องที่อยู่ | FigJam `537:252` | — |
| B-45 | เปลี่ยนภาษาเป็น Package ให้ Download | FigJam `537:280` | — |
| B-46 | เปลี่ยนภาษาเป็น Package ให้ Download (**sticky ซ้ำกับ B-45**) | FigJam `537:287` | — |
| B-47 | เพิ่มช่องค้นหาใน Private zone — ค้นได้ทั้งชื่อห้องและชื่อคน | FigJam `537:273` | — |
| B-48 | ให้ปุ่ม Copy กับ Share เป็น Action เดียวกัน | FigJam `537:90` | — |

## 4. ต้องถาม QA (ชื่อ issue ไม่พอให้จัดหมวด)

| # | รายการ | ที่มา | สถานะ | ต้องถามอะไร |
|---|---|---|---|---|
| Q-01 | ตัวละครอยู่นอก Meeting Mode Mobile แต่แสดงอยู่ในกลุ่ม Meeting | [ClickUp](https://app.clickup.com/t/14zd0zubp91) | in progress | ตัวละครอยู่นอกห้องบนแมพ (แนวนอน) หรือออกจาก Meeting ผ่านเมนู (แนวตั้ง)? |
| Q-02 | อยู่ใน Meeting 8 แล้วออกมา ไม่เจอตัวเองในห้อง Meeting | [ClickUp](https://app.clickup.com/t/14zd0zubp9u) | Open | "ไม่เจอตัวเอง" หมายถึงบนแมพ (แนวนอน) หรือใน list เมนู Meeting (แนวตั้ง)? |
| Q-03 | Feedback: จอเล็กด้านล่าง (PIP) ควรลากไปมาได้ | [ClickUp](https://app.clickup.com/t/14zd0zubpa0) | Open | แนวไหน? — มติ Ten 2026-10-01 ให้ PIP ลากไม่ได้ (แนวตั้งตำแหน่งตายตัวตาม Figma · แนวนอนอยู่เหนือ minimap) PM ตัด AC "draggable" ไปแล้ว ([open-items.md](../plan/MobileApp/open-items.md) HP-04 ข้อ 9) ต้องให้ PM ยืนยันว่าจะเปิดเรื่องนี้ใหม่หรือไม่ |

---

## ข้อสังเกต

- **ClickUp กับ FigJam ซ้ำกันบางข้อ** — ควรรวมเป็น ticket เดียวก่อนแจก dev:
  - B-08 ↔ B-37 (Preview กล้องไม่เต็มจอ)
  - B-23 ↔ B-26 (สถานะตัวละครไม่อัปเดตจนกว่าจะ Refresh)
  - B-24 ↔ B-27 (Wave หาคนที่ Away / ไม่ว่าง)
  - B-10 ↔ V-11 (หลุด/ปิดแอปแล้วสถานะยังค้างใน Meeting) — คนละแนวจอ แต่น่าจะเป็นต้นเหตุเดียวกัน (presence ไม่ถูกเคลียร์ตอน disconnect)
- **ข้อจาก FigJam ยังไม่มี ticket ใน ClickUp** — ทุกข้อใต้หัว "แนวตั้ง"/"แนวนอน" และส่วนใหญ่ในกลุ่มที่ยังไม่จัดหมวด (โดยเฉพาะ 🔥 B-31 Android Build, 🔥 V-13) ถ้าต้องการให้ track ใน ClickUp ต้องให้ PM/QA สร้าง ticket (AI สร้าง task ใน ClickUp ไม่ได้ตามกฎโปรเจกต์)
- **B-33, B-34** เป็น completed แล้ว — ใส่ไว้ให้รายการครบเท่านั้น
- Sticky ใน FigJam 23 ใบทางซ้ายของบอร์ด (x < −544) **ไม่ได้อยู่ใต้หัวแนวจอใดเลย** — หมวดของใบพวกนี้มาจากการอ่านเนื้อหาในเอกสารนี้ ไม่ใช่จากตำแหน่งในบอร์ด

---

## รอบที่ 2 — 2026-10-12

**ทำอะไร:** ไล่โค้ดจริงทุกข้อบน `origin/develop` (zyra-app `2671257` · zyra-ws `a1bc56b` · zyra-api `bb0762e` · zyra-mobile `134c067`) ให้ได้ Steps to reproduce / Actual / Expected (อ้าง spec) / Root cause (`repo/path:line`) / วิธีแก้ / สถานะการแก้ / ความมั่นใจ แล้วเขียนลง description ของการ์ด ClickUp (ผู้ใช้อนุญาตให้ยกเว้นกฎ ClickUp read-only สำหรับงานนี้ · ไม่ได้แตะ status)
- การ์ดเดิม 41 ใบ: เขียน description · ใบที่ QA มี description อยู่แล้ว เก็บของเดิมไว้ใต้หัว "จาก QA (เดิม)"
- การ์ดใหม่ 27 ใบ จาก sticky FigJam (สร้างเป็น subtask ของ [Mobile Responsive + App Conversion](https://app.clickup.com/t/86d4bfpym))
- sticky ที่ซ้ำการ์ดเดิม รวมเข้าการ์ดเดิม ไม่เปิดใบใหม่: `537:142` → B-08 · `537:301` → B-23 · `537:149` → B-24 · `537:329` (B-10) → B-02 · `537:287` ซ้ำ `537:280` → B-45 · B-16 เขียนว่าซ้ำ B-15

**verify ถึงไหน:** อ่านโค้ดอย่างเดียว — ไม่ได้รัน ไม่ได้ทดสอบบนเครื่อง · step ที่ไม่มีใน description ของ QA ติดป้าย "สันนิษฐานจากโค้ด — QA ยืนยัน" ในการ์ด

### แก้หมวดแนวจอจากรอบที่ 1

| ข้อ | รอบที่ 1 | หลังไล่โค้ด | เหตุผล |
|---|---|---|---|
| V-04 ปุ่มย้อนกลับบัง Island | แนวตั้ง | **แนวนอน** | Dynamic Island ไปอยู่ขอบซ้าย/ขวาเมื่อหมุนจอ · มี fix `fix/landscape-island-meeting` (#532) |
| Q-01 | ต้องถาม QA | **แนวตั้ง** | "Mode Mobile" = คน join จาก Lite · คนเห็นคือฝั่ง web/แนวนอน |
| Q-02 | ต้องถาม QA | **แนวตั้ง** (อนุมาน) | Lite ไม่ส่ง heartbeat ห้อง → zyra-api ตัดเป็น offline หลัง 3 นาที |
| Q-03 PIP ลากได้ | ต้องถาม QA | **ทั้งสองแนว** | มี PIP ทั้ง Lite Home และบนแมพ — ยังต้องมติ PM (ขัดกับ HP-04 ข้อ 9) |
| B-28 หลุดบ่อย | ทั้งสองแนว | **แนวตั้งเป็นหลัก** | Lite ไม่ส่ง `ping` → client ปิด socket ที่เงียบ 30 วิ ทุก ~30 วิ |

### การ์ดใหม่

| ข้อ | การ์ด |
|---|---|
| V-05 | [Start Spotlight แนวตั้งนับครบ 5 วิแล้วไม่ขึ้น live](https://app.clickup.com/t/14zd0zuc0dt) |
| V-07 | [แนวตั้งไม่แสดงป้าย Owner / Admin](https://app.clickup.com/t/14zd0zuc0d4) |
| V-08 | [แนวตั้งเข้า Meeting แต่แนวนอนไม่เห็น + พูดไม่มีเสียง](https://app.clickup.com/t/14zd0zuc0d5) |
| V-09 | [แนวตั้ง เมนูในห้อง Meeting กดไม่ได้](https://app.clickup.com/t/14zd0zuc0d6) |
| V-10 | [แนวตั้งกด Instant Meeting แล้วไม่เข้าหน้า Meeting](https://app.clickup.com/t/14zd0zuc0d9) |
| V-11 | [แนวตั้งปิดแอปแล้วคนอื่นยังเห็นอยู่ในห้อง](https://app.clickup.com/t/14zd0zuc0de) |
| V-12 | [แนวตั้งกด Leave แล้วหน้า Meeting ยังค้าง](https://app.clickup.com/t/14zd0zuc0dh) |
| V-13 🔥 | [Web เห็นคน Lite วาร์ปพร้อมประกายแสงแทนการเดิน](https://app.clickup.com/t/14zd0zuc0dk) |
| H-08 | [แนวนอน Meeting Menu กดห้องที่มีคนไม่ได้](https://app.clickup.com/t/14zd0zuc0db) |
| H-09 | [แนวนอน เมนู Member — ปุ่มเข้าร่วม Meeting/Circle](https://app.clickup.com/t/14zd0zuc0dd) |
| H-10 | [แนวนอน เมนู Meeting rooms — แสดงห้องไม่ว่าง](https://app.clickup.com/t/14zd0zuc0dg) |
| B-09 | [ปุ่ม ‹ › กระพริบเมื่อมี 6 คนขึ้นไป](https://app.clickup.com/t/14zd0zuc0dc) |
| B-11 | [จำนวนคนในห้อง Meeting ไม่อัปเดต / ผิดคน](https://app.clickup.com/t/14zd0zuc0df) |
| B-12 | [รูป Profile ใน Chat Meeting เป็นรูปตัวละคร](https://app.clickup.com/t/14zd0zuc0dj) |
| B-17 | [หน้า Spotlight แนวนอนกดอะไรไม่ได้](https://app.clickup.com/t/14zd0zuc0du) |
| B-18 | [กดดู Viewer ใน Spotlight แล้วเปิดแผง Member ทับ](https://app.clickup.com/t/14zd0zuc0dy) |
| B-19 | [หน้า Spotlight เลื่อนรายชื่อไม่ได้](https://app.clickup.com/t/14zd0zuc0dz) |
| B-20 | [หลัง Spotlight จบ คนในห้องประชุมกดอะไรไม่ได้](https://app.clickup.com/t/14zd0zuc0e0) |
| B-21 | [Spotlight ค้าง ~1 นาทีหลัง Host ออก](https://app.clickup.com/t/14zd0zuc0e2) |
| B-28 | [ตัดการเชื่อมต่อบ่อยทั้งที่ 5G เต็ม](https://app.clickup.com/t/14zd0zuc0dv) |
| B-31 🔥 | [Android Build ไม่ผ่าน](https://app.clickup.com/t/14zd0zuc0d1) |
| B-32 | [ให้แอปทำงานต่อตอน lock หน้าจอ](https://app.clickup.com/t/14zd0zuc0d2) |
| B-43 | [แชร์ Meeting ให้คนที่ไม่เคยคุย ห้องแชทไม่ขึ้น](https://app.clickup.com/t/14zd0zuc0dm) |
| B-44 | [เรียง Z-Index ของ UI ตามห้อง](https://app.clickup.com/t/14zd0zuc0dn) |
| B-45 | [แยกไฟล์ภาษาเป็น Package ให้ดาวน์โหลด](https://app.clickup.com/t/14zd0zuc0dp) |
| B-47 | [ช่องค้นหาใน Private zones](https://app.clickup.com/t/14zd0zuc0dq) |
| B-48 | [ปุ่ม Copy กับ Share เป็น Action เดียวกัน](https://app.clickup.com/t/14zd0zuc0dr) |

### สถานะการแก้ (จากโค้ด ไม่ใช่จาก ClickUp)

- **แก้แล้วบน develop รอ QA เทสซ้ำ** (merged 2026-10-08 → 10-12, ยังไม่ขึ้น main): B-33 (#512) · B-34 (#519) · B-39 (#525, เหลือทาง "Workspace is full") · B-41 + V-01 (#536) · V-04 (#532) · B-22 (zyra-ws #75/#76) · B-01 มือถือ (#528 — เว็บ desktop + server ยังไม่ล็อก) · B-07 แนวตั้ง (#526 — แนวนอนยังไม่มี)
- **น่าจะหายด้วย #537** (SFU session reconnect loop ใน Lite meeting) แต่ยังไม่ยืนยัน: B-02/B-10, B-05, B-06, B-09, V-08, V-09, V-10
- **หา root cause ชัด ยังไม่มีใครแก้:** B-03 (Lite join ห้องใหม่ไม่ leave ห้องเดิม) · B-04 (Accept ไม่บันทึก access grant) · B-11 + Q-02 + V-11 (Lite ไม่ส่ง heartbeat ห้อง / ไม่เคลียร์ zone-section ตอนปิดแอป) · B-12 · B-14/B-17/B-18 (หน้า Spotlight แนวนอนอยู่ใต้ HUD `pointer-events-none` — แก้จุดเดียวครบ 3 ข้อ) · V-05 · B-24 · B-28 · B-43 · H-04 (Ask to Join ต้อง hover) · H-09 · V-07
- **config ไม่ใช่โค้ด:** B-38 — ลิงก์ invite ชี้ host Cloud Run เก่า → `APP_URL` ใน runtime secret น่าจะค้าง
- **ต้องมติ PM / Ten:** Q-03 (PIP ลากได้) · V-02/V-03/V-13 (Lite ให้ตัวละครเดินเองหรือวาร์ป — spec TD §16.2 ขัดกับโค้ด) · B-24 (away อัตโนมัติตอนแอปไป background ควรกัน Wave ไหม) · B-36 (นโยบาย login หลายเครื่อง) · B-42, B-15 (spec §18.7/§18.9 ขัดกันเอง)
- **ต้องให้ QA ให้ข้อมูลเพิ่ม (ความมั่นใจต่ำ):** H-01, H-02, H-03, H-05, B-13, B-29, B-31 (CI 40 รันล่าสุดเขียว), B-35 (ต้อง stack trace จาก Sentry), B-40, B-44

**ต่อจากนี้:** QA เทสซ้ำกลุ่ม "แก้แล้วบน develop" บน build dev ใหม่ · PM ตัดสินกลุ่ม "ต้องมติ" · dev หยิบกลุ่ม "root cause ชัด"
**ติดอะไร:** Figma MCP (plugin) ยังไม่ได้ authorize ใน agent — sticky ใช้ข้อความจากบอร์ดที่อ่านในรอบที่ 1 · Grafana/Loki เข้าไม่ได้ จึงยังไม่มีตัวเลข before/after ของ B-25/B-28
