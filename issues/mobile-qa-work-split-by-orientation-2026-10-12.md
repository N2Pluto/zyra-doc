# Mobile App — แบ่งงาน Issue QA ตามแนวจอ (แนวตั้ง / แนวนอน)

> **สถานะ:** พร้อมแจกงาน · **วันที่:** 2026-10-12 · **Repo ที่กระทบ:** zyra-app, zyra-ws, zyra-api, zyra-mobile
> **ที่มา:** การ์ด ClickUp ทั้ง 68 ใบใต้ [Mobile Responsive + App Conversion](https://app.clickup.com/t/86d4bfpym) (เดิม 41 + เปิดใหม่จาก FigJam 27) — รายละเอียด step / root cause / วิธีแก้อยู่ใน description ของแต่ละการ์ดแล้ว
> **เอกสารคู่กัน:** [mobile-qa-issues-by-orientation-2026-10-12.md](mobile-qa-issues-by-orientation-2026-10-12.md) (รายการเต็ม + บันทึกการไล่โค้ด)
> ผลทั้งหมดมาจากการอ่านโค้ด `origin/develop` — **ยังไม่ได้ทดสอบบนเครื่องจริง**

## วิธีแบ่ง

- แบ่งเป็น 3 สาย: **แนวตั้ง (Lite)** · **แนวนอน (Spatial)** · **ทั้งสองแนว / ตัวแอป**
- จัดสายตาม **จุดที่ต้องแก้ในโค้ด** ไม่ใช่ตามจอที่ QA เห็น — เช่น V-02 "web เห็นคนแนวตั้งเดินเอง" เห็นบนจอ web แต่ต้นเหตุอยู่ที่ Lite → อยู่สายแนวตั้ง
- ในแต่ละสายแบ่งเป็น **ก้อนงาน** ข้อในก้อนเดียวกันต้นเหตุเดียวกันหรือแตะไฟล์ชุดเดียวกัน → **ให้คนเดียวทำทั้งก้อน** กันแก้ชนกัน
- แนวจอในเอกสารนี้ใช้ผลหลังไล่โค้ด บางข้อจึงต่างจากตารางรอบที่ 1 ในเอกสารคู่กัน (เช่น V-04 ย้ายไปแนวนอน)

| สัญลักษณ์ | ความหมาย | ใครทำต่อ |
|---|---|---|
| ✅ | แก้แล้วบน `develop` — รอ QA เทสซ้ำบน dev | QA |
| 🛠 | root cause ชัด พร้อมแก้ | Dev |
| ❓ | ยังหา root cause ไม่ชัด — ต้องให้ QA ให้ข้อมูล (จอไหน / วิดีโอ / device) | QA → Dev |
| 🗳 | ต้องมติ PM / Ten ก่อนทำ (spec ขัดกัน หรือเป็นฟีเจอร์ใหม่) | PM |
| ⚙️ | config ไม่ใช่โค้ด | DevOps |
| 🔥 | sticky ในบอร์ดติดไอคอนไฟ (เร่งด่วน) | |

## ภาพรวม

| สาย | การ์ด | ✅ | 🛠 | ❓ | 🗳 | ⚙️ |
|---|---:|---:|---:|---:|---:|---:|
| แนวตั้ง (Lite) | 32 | 13 | 12 | 2 | 4 | 1 |
| แนวนอน (Spatial) | 21 | 1 | 9 | 6 | 5 | 0 |
| ทั้งสองแนว / ตัวแอป | 15 | 0 | 8 | 4 | 3 | 0 |
| **รวม** | **68** | **14** | **29** | **12** | **12** | **1** |

> นับตามสถานะหลักของแต่ละการ์ด · การ์ดที่มีหลายส่วน (เช่น B-01 มือถือแก้แล้วแต่เว็บยัง) นับที่ส่วนที่ยังต้องทำ

---

## สาย 1 — แนวตั้ง (Lite) · 32 การ์ด

### ก้อน V1 — Meeting ของ Lite หลุด/ค้าง: เทสซ้ำหลัง #537 ก่อน

#537 (merged develop 2026-10-12 14:10) แก้ SFU session ที่ต่อใหม่ทุกครั้งที่ meeting ของ Lite re-render — น่าจะเป็นต้นเหตุของทุกข้อในก้อนนี้ **ให้ QA เทสซ้ำทั้งก้อนก่อน** ข้อที่ยังเป็นค่อยแจก dev

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| B-02 | [เข้าร่วม Meeting แล้วจอขาว](https://app.clickup.com/t/14zd0zubp9b) (รวม sticky B-10 จอขาวแล้วเด้งออกแต่สถานะยังอยู่) | retest · ถ้ายังเป็นขอวิดีโอ + device + เวลา แล้วดู Sentry · ส่วน "สถานะยังค้างในห้อง" ทำใน V2 | ✅ ❓ |
| B-05 | [Action in meeting กดไม่ได้](https://app.clickup.com/t/14zd0zubp9p) | retest + QA ระบุว่าปุ่มไหน (แถบล่าง หรือ ⋯ ที่ non-host ไม่ควรเห็นอยู่แล้ว) | ✅ ❓ |
| B-06 | [กด Instant Meeting แล้วจอกระพริบ](https://app.clickup.com/t/14zd0zubp9t) | retest | ✅ |
| B-09 | [ปุ่ม ‹ › กระพริบเมื่อมี 6 คนขึ้นไป](https://app.clickup.com/t/14zd0zuc0dc) | retest · ถ้ายังเป็น debounce การลบ tile (จำนวน tile แกว่ง 6↔7) | ✅ |
| V-08 | [แนวตั้งเข้า Meeting แต่แนวนอนไม่เห็น + พูดไม่มีเสียง](https://app.clickup.com/t/14zd0zuc0d5) | retest (แก้ด้วย #537 + zyra-ws #75) | ✅ |
| V-09 | [เมนูในห้อง Meeting กดไม่ได้ทุกเมนู](https://app.clickup.com/t/14zd0zuc0d6) | retest + ระบุเมนูที่กดไม่ได้ | ✅ |
| V-10 | [กด Instant Meeting แล้วไม่เข้าหน้า Meeting](https://app.clickup.com/t/14zd0zuc0d9) | retest + บอกว่าขึ้น toast "Meeting has ended" ไหม | ✅ ❓ |

### ก้อน V2 — ตัวตนของ Lite ในห้อง Meeting (zone-section / heartbeat) — คนเดียวทำทั้งก้อน

ต้นเหตุร่วม: Lite **ไม่ส่ง heartbeat ห้องทุก 2 นาที** แบบ Spatial → zyra-api ตัดเป็น offline หลัง 3 นาที · Lite **ไม่ leave ห้องเดิม** ตอนเข้าห้องใหม่ · ปิดแอปแล้ว **ไม่มีใครเคลียร์ zone-section**

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| Q-02 | [ออกจาก Meeting 8 แล้วไม่เจอตัวเองในห้อง](https://app.clickup.com/t/14zd0zubp9u) | `LiteMeeting` เรียก `heartbeatZoneSection` ทุก 2 นาทีเหมือน hero + test | 🛠 · 2026-10-14 แก้ใน `fix/lite-meeting-heartbeat` ([#558](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/558)) (PR เปิดแล้ว รอ review) |
| B-11 | [จำนวนคนในห้อง Meeting ไม่อัปเดต / ผิดคน](https://app.clickup.com/t/14zd0zuc0df) | ต้นเหตุเดียวกับ Q-02 + B-03 — ทำพร้อมกัน (การ์ดนี้เป็น "ทั้งสองแนว" แต่โค้ดที่ต้องแก้อยู่ฝั่ง Lite) | 🛠 · 2026-10-14 แก้ใน `fix/lite-meeting-heartbeat` ([#558](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/558)) (PR เปิดแล้ว รอ review) |
| B-03 | [Join อีกห้องแล้วเห็นตัวเองค้างห้องเดิม](https://app.clickup.com/t/14zd0zubp9e) | `enter()` ใน `lite-shell.tsx` เรียก `liteLeaveMeeting` ห้องเดิมก่อน `liteEnterMeeting` | 🛠 · 2026-10-14 แก้ใน `fix/lite-switch-room-leave` ([#559](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/559)) (PR เปิดแล้ว รอ review) |
| V-11 | [ปิดแอปแล้วคนอื่นยังเห็นอยู่ในห้อง](https://app.clickup.com/t/14zd0zuc0de) | กรอง tile ด้วย WS roster · หลัง presence grace หมด ให้ zyra-ws แจ้ง zyra-api `LeaveZone` | 🛠 · 2026-10-14 แก้ใน `fix/lite-meeting-heartbeat (client)` (PR เปิดแล้ว รอ review) |
| V-12 | [กด Leave แล้วหน้า Meeting ยังค้าง](https://app.clickup.com/t/14zd0zuc0dh) | กด Leave → `onLeft()` ทันที แล้วส่ง REST leave แบบไม่รอ + timeout | 🛠 · 2026-10-14 แก้ใน `fix/lite-switch-room-leave` ([#559](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/559)) (PR เปิดแล้ว รอ review) |
| Q-01 | [อยู่นอกห้องแต่ถูกนับในกลุ่ม Meeting](https://app.clickup.com/t/14zd0zubp91) | retest หลัง zyra-ws #77 + #537 | ✅ |

### ก้อน V3 — ตัวละคร Lite บนแมพที่คนอื่นเห็น: รอมติก่อน 🔥

spec (technical-design §16.2) บอกว่าคน Lite ที่ไม่อยู่ในห้องไม่มีตัวบนแมพ แต่โค้ดตอนนี้ให้ server ขับตัวละครเดินเอง (มติ Ten 2026-10-09 ที่อยู่แค่ใน comment ของโค้ด) · **ถ้ารับ V-13 (วาร์ป) จะตัด V-02 และ V-03 ทิ้งได้ทั้งคู่**

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| V-13 🔥 | [Web เห็นคน Lite วาร์ปพร้อมประกายแสงแทนการเดิน](https://app.clickup.com/t/14zd0zuc0dk) | PM/Ten ตัดสิน → zyra-ws (place + teleport flag) แล้ว zyra-app (snap + sparkle) | 🗳 |
| V-02 | [Web เห็นตัวละครคนแนวตั้งเดินไปมาเอง](https://app.clickup.com/t/14zd0zubp93) | ตามมติ V-13 | 🗳 |
| V-03 | [ตัวละคร Lite เดินเฉียง](https://app.clickup.com/t/14zd0zubp9d) | ถ้ายังเดิน: path ของ autopilot เป็น 4 ทิศ (`pathfind.go`) · ถ้าวาร์ป: ปิดการ์ด | 🗳 |

### ก้อน V4 — สถานะ / WS ของ Lite

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| B-28 | [ตัดการเชื่อมต่อบ่อยทั้งที่ 5G เต็ม](https://app.clickup.com/t/14zd0zuc0dv) | ย้าย ping keepalive เข้า `WorkspaceWSClient` (Lite ไม่ส่ง ping → client ปิด socket ที่เงียบ 30 วิ) + ปุ่ม Retry หลัง reconnect หมด | 🛠 · 2026-10-14 แก้ใน `fix/ws-keepalive-ping` ([#560](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/560)) (PR เปิดแล้ว รอ review) |
| B-23 | [Status ตัวละครไม่อัปเดตจนกว่าจะ Refresh](https://app.clickup.com/t/14zd0zubp8t) (รวม sticky "Server ไม่อัปเดตสถานะ") | กรณี A/B แก้แล้ว (zyra-ws #76, zyra-app #535) · ที่เหลือเป็นของ Lite: ส่ง `setStatus` หลัง welcome/reconnect · เพิ่มคนใน roster ที่ยังไม่อยู่ใน member list | 🛠 · 2026-10-14 แก้ใน `fix/lite-restate-status (C, D)` (PR เปิดแล้ว รอ review) |
| B-25 | [Wave / แจ้งเตือนซ้ำหลังปิดแอป](https://app.clickup.com/t/14zd0zubp9r) | QA ยืนยันว่าซ้ำแบบไหน (รูปเป็น Raised hand ×5) · Lite ส่ง `visibility` · zyra-ws push เฉพาะยกมือใหม่ · ใส่ collapse key | ❓ |
| B-24 | [Wave คนที่ Away ได้](https://app.clickup.com/t/14zd0zubzhw) (รวม sticky "Wave คนไม่ว่างต้องแจ้งเตือน") | PM ตัดสินว่า away อัตโนมัติ (แอปไป background) กัน Wave ไหม · Lite ย้าย toast ไปหลังรู้ผล + ฟัง `error` | 🗳 🛠 · 2026-10-14 แก้ใน `fix/lite-wave-result-toast (client)` (PR เปิดแล้ว รอ review) |
| B-22 | [Web ไม่เห็น User ที่ login ผ่านมือถือ](https://app.clickup.com/t/14zd0zubp8q) | retest (zyra-ws #75/#76) | ✅ |

### ก้อน V5 — Spotlight ฝั่ง Lite

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| V-05 | [Start Spotlight นับครบ 5 วิแล้วไม่ขึ้น live](https://app.clickup.com/t/14zd0zuc0dt) | store ของ Lite ไม่ทิ้ง state Spotlight ของชั้นอื่น (`vo-session-store.ts:383`) · ยกเลิกแล้วส่ง `spotlight:stop` เสมอ | 🛠 · 2026-10-14 แก้ใน `fix/lite-spotlight-floor` ([#563](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/563)) (PR เปิดแล้ว รอ review) |

### ก้อน V6 — หน้าจอ Lite

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| V-07 | [ไม่แสดงป้าย Owner / Admin](https://app.clickup.com/t/14zd0zuc0d4) | ส่ง `role` เข้า `LitePerson` แล้วแสดง pill ใน member row + profile sheet | 🛠 · 2026-10-14 แก้ใน `fix/lite-role-badge` ([#564](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/564)) (PR เปิดแล้ว รอ review) |
| B-43 | [แชร์ Meeting ให้คนที่ไม่เคยคุย ห้องแชทไม่ขึ้น](https://app.clickup.com/t/14zd0zuc0dm) | `sendInChat` relay ผ่าน WS หลังส่ง REST (pet-share, forward มีปัญหาเดียวกัน) | 🛠 · 2026-10-14 แก้ใน `fix/lite-invite-chat-relay` ([#557](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/557)) (PR เปิดแล้ว รอ review) |
| B-48 | [ปุ่ม Copy กับ Share เป็น Action เดียวกัน](https://app.clickup.com/t/14zd0zuc0dr) | เพิ่ม `copyLink()` แยกจาก `shareOrCopy` | 🛠 · 2026-10-14 แก้ใน `fix/lite-copy-link` ([#555](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/555)) (PR เปิดแล้ว รอ review) |
| B-39 | [Manage Member ไม่เต็มจอ](https://app.clickup.com/t/14zd0zubnhm) | ทางเมนูแก้แล้ว (#525) · เหลือทาง "Workspace is full → Manage members" ยังเปิด modal desktop | ✅ 🛠 · 2026-10-14 แก้ใน `fix/lite-capacity-manage-members` ([#556](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/556)) (PR เปิดแล้ว รอ review) |
| V-01 | [Profile เลื่อนลงไม่ได้](https://app.clickup.com/t/14zd0zubp90) | retest (#536) | ✅ |
| B-41 | [กดคีย์บอร์ดใน Chat แล้วมีเส้นขาว](https://app.clickup.com/t/14zd0zubp9k) | retest (#536) ทั้ง Lite และแชทแนวนอน | ✅ |
| B-35 | [Account & Security → Something went wrong](https://app.clickup.com/t/14zd0zubp8z) | ดึง stack trace จาก Sentry (org `zyra-rm`) 2026-10-09 ~14:25 · เพิ่ม error boundary ให้หน้า setting | ❓ |

### ก้อน V7 — ก่อนเข้า workspace / Login / ลิงก์

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| B-38 | [Invite ผ่าน Gmail แล้ว 404](https://app.clickup.com/t/14zd0zuby77) | ลิงก์ชี้ host Cloud Run เก่า → ตรวจ `APP_URL` ใน secret `zyra-api-<env>-env-json` (+ zyra-notifications) แล้ว restart pod | ⚙️ |
| B-33 | [Remind me again แล้วเลือกโหมดไม่ได้](https://app.clickup.com/t/14zd0zubh45) | แก้แล้ว #512 (การ์ด completed) | ✅ |
| B-34 | [เคลียร์ Session Google เพื่อเลือกบัญชีใหม่](https://app.clickup.com/t/14zd0zubncm) | แก้แล้ว #519 (การ์ด completed) | ✅ |

---

## สาย 2 — แนวนอน (Spatial) · 21 การ์ด

### ก้อน H1 — หน้า Spotlight บนแมพกดอะไรไม่ได้ — PR เดียวแก้ 4 ข้อ

ต้นเหตุ: หน้า Spotlight บนมือถือ/iPad ในแอปอยู่ใต้ HUD ที่เป็น `pointer-events-none` และไม่มีที่เปิดกลับ → tap ทะลุลงแมพ · หน้า Meeting มีวิธีแก้แบบเดียวกันอยู่แล้ว (`vo-mobile-meeting.tsx:219-222`) · **แก้: ห่อทุกอย่างที่ `VOMobileSpotlight` render ด้วย `pointer-events-auto`** แล้วเทสซ้ำทั้งก้อน

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| B-17 | [หน้า Spotlight กดอะไรไม่ได้ (Host + Member)](https://app.clickup.com/t/14zd0zuc0du) | แก้หลักของก้อน + test ที่เช็ค class/computed style (`fireEvent` จับไม่ได้) | 🛠 |
| B-14 | [Host กดปิด Spotlight ไม่ได้](https://app.clickup.com/t/14zd0zubyh0) | ตาม B-17 · ส่วน "ยังค้างบน stage" ทำใน B-21 | 🛠 |
| B-18 | [กดดู Viewer แล้วแผง Member เปิดทับ](https://app.clickup.com/t/14zd0zuc0dy) | ตาม B-17 (ชิป N \| M ทับปุ่ม Members ของแมพ) | 🛠 |
| B-19 | [เลื่อนรายชื่อในหน้า Spotlight ไม่ได้](https://app.clickup.com/t/14zd0zuc0dz) | ตาม B-17 แล้วเทสบนเครื่องจริง · ถ้ายังไม่ได้ดู touch handler ของ joystick | 🛠 ❓ |
| B-20 | [หลัง Spotlight จบ คนในห้องประชุมกดอะไรไม่ได้](https://app.clickup.com/t/14zd0zuc0e0) | คืน `meetingExpanded` เมื่อ Spotlight จบ · ส่วน "กดไม่ได้" เทสหลัง B-17 | 🛠 ❓ |
| B-15 | [ให้กดปุ่ม Play เริ่ม Spotlight ได้](https://app.clickup.com/t/14zd0zubpa2) | **มติ Ten 2026-10-14:** เดินเข้าจุดเองแล้วกด Play ในแถบล่าง → เพิ่ม Play ในแถบล่างมือถือใน [zyra-app#550](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/550) | 🛠 PR |
| B-16 | [การ์ดซ้ำ B-15](https://app.clickup.com/t/14zd0zubpa3) | ปิดเป็นซ้ำ (ติดตามที่ B-15) | 🗳 |

### ก้อน H2 — Bubble / เข้าร่วม Meeting บนแมพ

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| H-04 | [อยู่ใน Bubble กด Request to join ไม่ได้](https://app.clickup.com/t/14zd0zubp9a) | ปุ่ม Ask to Join โผล่เฉพาะตอน hover — มือถือไม่มี hover → แสดงตลอด หรือ tap Bubble เปิด JoinMeetingSheet | 🛠 |
| H-09 | [เมนู Member: ปุ่มเข้าร่วม Meeting/Circle](https://app.clickup.com/t/14zd0zuc0dd) | การ์ด meeting/Bubble ใน drawer แค่เลื่อนกล้อง → เพิ่มปุ่ม Join (Lite มีให้ reuse) | 🛠 |
| B-07 | [เพิ่มปุ่ม Invite ใน Meeting](https://app.clickup.com/t/14zd0zubpa4) | แนวตั้งมีแล้ว (#526) · แนวนอนยังไม่มี → ส่ง prop `invite` เข้า `VOMobileMeeting` | 🛠 |
| H-05 | [อยู่ใน Meeting room แล้วเข้าร่วมไม่ได้ ต้องกด Meeting](https://app.clickup.com/t/14zd0zubp9c) | น่าจะเป็นเสียงถูกบล็อกจนกว่าจะมี click (เดิน joystick ไม่นับเป็น click) → ปลดล็อกเสียงด้วย `pointerdown`/`touchend` · QA ยืนยันว่า "เข้าร่วมไม่ได้" หมายถึงอะไร | 🛠 ❓ |
| H-08 | [Meeting Menu กดห้องที่มีคนไม่ได้](https://app.clickup.com/t/14zd0zuc0db) | QA บอกว่าห้องล็อกไหม · ไม่ล็อก: Join ใช้ `findSeatOrStandTile` แทนเดินไปกลางห้อง · ล็อก: overlay เป็น modal | ❓ |
| H-03 | [จับ Bubble แล้ว flow ไม่เป็น Meeting](https://app.clickup.com/t/14zd0zubp95) | QA บอกว่าคาดหวังอะไร (ตอนนี้เปิดเป็น PIP ไม่มีแชท) | ❓ |
| H-10 | [เมนู Meeting rooms: แสดงห้องไม่ว่าง](https://app.clickup.com/t/14zd0zuc0dg) | spec ไม่ได้ระบุ → ขอ design | 🗳 |

### ก้อน H3 — เข้า / สลับเข้า Spatial — ต้องได้ข้อมูลจาก QA ก่อน

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| H-01 | [เข้า Workspace แนวนอนครั้งแรกไม่ได้](https://app.clickup.com/t/14zd0zubp8b) | QA บอกอาการจริง (ค้างที่ %, จอขาว, แอปปิด) + device + log · สงสัย: permission prompt ครั้งแรก, rotate lock, โหลด asset ครั้งแรก · มี local branch `fix/spatial-entry-crash` ว่างอยู่ — เช็คว่าใครถือ | ❓ |
| H-02 | [Spatial → Lite → Spatial แมพไม่ขึ้น](https://app.clickup.com/t/14zd0zubp96) | repro พร้อม Web Inspector · ให้ `changeMode` ตั้ง `leavingRef` ก่อน `endSession()` · ตรวจ WebGL context ถูกคืน | ❓ |

### ก้อน H4 — HUD / control บนแมพ

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| V-04 | [ปุ่มย้อนกลับ Meeting บัง Island](https://app.clickup.com/t/14zd0zubp8j) | retest (#532) ทั้งหมุนซ้ายและขวา | ✅ |
| H-06 | [ปุ่มเดินไปหาในโปรไฟล์คนอื่น](https://app.clickup.com/t/14zd0zubpa8) | ปุ่ม Go to มีแล้ว (#499) → QA บอกว่าเปิดโปรไฟล์จากจอไหน (ถ้า Lite ต้องคุย) | ❓ |
| H-07 | [ขอบเขตของ joystick](https://app.clickup.com/t/14zd0zubpa9) | โซนตอนนี้ = ซ้าย 43% จากความสูง 35% ลงไป (มติ Ten 2026-10-08) ไม่มีขอบให้เห็น → ตัดสินว่าจะลดโซนหรือแค่แสดงขอบ | 🗳 |
| B-42 | [ไอคอนประกาศให้ทำงานเหมือนเว็บ](https://app.clickup.com/t/14zd0zubpab) | **มติ Ten 2026-10-14:** megaphone = Announcement (Owner / Admin) แบบเว็บ → แก้ใน [zyra-app#550](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/550) (ux-ui-plan §18.10) | 🛠 PR |
| B-44 | [เรียง Z-Index ของ UI ตามห้อง](https://app.clickup.com/t/14zd0zuc0dn) | ขอภาพ/วิดีโอว่าอะไรทับอะไร → ทำ z-index token กลาง | ❓ |

---

## สาย 3 — ทั้งสองแนว / ตัวแอป · 15 การ์ด

ใครว่างจากสาย 1–2 หยิบได้ · ก้อน A3 ต้องคนที่ทำ zyra-mobile (native)

### ก้อน A1 — Meeting ที่ใช้ร่วมกันทั้งสองแนว

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| B-04 | [Request to join ห้องล็อก Accept แล้วยังเข้าไม่ได้](https://app.clickup.com/t/14zd0zubp9n) | Accept จาก Participants sheet ส่งแค่ WS ไม่บันทึก access grant → ทำลำดับเดียวกับ `use-lite-knocks.ts` (`grantZoneSectionAccess` → `sectionSync` → decision) + test | 🛠 |
| B-01 | [Non-host กด Mute all ได้](https://app.clickup.com/t/14zd0zubp8p) | มือถือแก้แล้ว (#528) · เหลือเว็บ desktop ส่ง `onMuteAll` ให้ทุกคน + server ไม่ล็อก (ต้องมติ) | ✅ 🛠 |
| B-08 | [Preview กล้องไม่เต็มจอ](https://app.clickup.com/t/14zd0zubzmd) (รวม sticky iPhone 18 PM / iOS 27) | กล่อง preview ใช้สัดส่วนของ stream (`videoWidth/videoHeight`) หรือ `aspect-[3/4]` ในแนวตั้ง | 🛠 |
| B-12 | [รูป Profile ใน Chat Meeting เป็นรูปตัวละคร](https://app.clickup.com/t/14zd0zuc0dj) | `MeetingChatPanel` รับ `photoFor(userId)` จาก member list แทนการ crop sprite | 🛠 |
| Q-03 | [PIP ควรลากย้ายได้](https://app.clickup.com/t/14zd0zubpa0) | ขัดกับมติ HP-04 ข้อ 9 (PIP ลากไม่ได้) → PM ตัดสิน | 🗳 |

### ก้อน A2 — Spotlight ที่ใช้ร่วมกัน

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| B-21 | [Spotlight ค้าง ~1 นาทีหลัง Host ออก](https://app.clickup.com/t/14zd0zuc0e2) | ส่ง `spotlight:stop` ก่อน `destroySession()` · zyra-ws ไม่ใช้ presence grace กับ speaker | 🛠 |
| B-13 | [ยอด Spotlight ไม่แสดง](https://app.clickup.com/t/14zd0zubp8x) | QA บอกว่า "ยอด" คือตัวเลขไหน · เกี่ยวกับ V-05 (store ของ Lite) | ❓ |

### ก้อน A3 — ตัวแอป (zyra-mobile / lifecycle)

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| B-30 | [ปัดแอปทิ้งแล้วเปิดใหม่จอดำ](https://app.clickup.com/t/14zd0zubp9h) | splash ซ่อนตามเวลา 2 วิ ไม่ใช่ตอนหน้าพร้อม → `launchAutoHide: false` แล้ว `SplashScreen.hide()` หลัง mount | 🛠 |
| B-32 | [ให้แอปทำงานต่อตอน lock จอ](https://app.clickup.com/t/14zd0zuc0d2) | task 1.17 Android foreground service ตอนประชุม · ตกลงกับ PO ว่า "ตลอด" = เฉพาะตอนประชุม (นอกประชุมบน iOS ทำไม่ได้) | 🛠 |
| B-29 | [สลับแอปแล้วกลับมาจอขาว](https://app.clickup.com/t/14zd0zubp9g) | retest หลัง #536 · ถ้ายังเป็น จัดการ WebGL context lost/restore ของแมพ | ❓ |
| B-31 🔥 | [Android Build ไม่ผ่าน](https://app.clickup.com/t/14zd0zuc0d1) | CI 40 รันล่าสุดเขียว · น่าจะเป็น APK ลงทับของเดิมไม่ได้ → แก้แล้วใน zyra-mobile #8 · QA ถอนแอปเดิมครั้งเดียวแล้วลงใหม่ และบอกว่า "ไม่ผ่าน" หมายถึงอะไร | ❓ |

### ก้อน A4 — รอมติ / รอข้อมูล

| ข้อ | การ์ด | สิ่งที่ต้องทำ | สถานะ |
|---|---|---|---|
| B-36 | [Login 2 เครื่อง เครื่องเก่าต้องถูก logout](https://app.clickup.com/t/14zd0zubya4) | โค้ดตั้งใจให้ login ได้หลายเครื่อง · PO ตัดสินนโยบาย | 🗳 |
| B-45 | [แยกไฟล์ภาษาเป็น Package ให้ดาวน์โหลด](https://app.clickup.com/t/14zd0zuc0dp) | ฟีเจอร์ใหม่ → ตกลง requirement แล้วทำ plan | 🗳 |
| B-47 | [ช่องค้นหาใน Private zones](https://app.clickup.com/t/14zd0zuc0dq) | ทำได้เลยในโค้ด (sheet เดียวกันทั้งสองแนว) แต่ต้องมี Figma ก่อน (rule 10) | 🛠 |
| B-40 | [iPad เลื่อนจอลงไม่ได้](https://app.clickup.com/t/14zd0zubp8k) | QA บอกหน้า + วิดีโอ + แอปหรือ Safari | ❓ |

---

## ลำดับที่แนะนำ

1. **QA เทสซ้ำทั้งก้อน V1 + ข้อ ✅ ทั้งหมดบน dev** (build หลัง 2026-10-12 14:10 ที่มี #537) — น่าจะปิดได้หลายใบโดยไม่ต้องแก้โค้ดเพิ่ม
2. **DevOps แก้ B-38** (`APP_URL` ใน secret) — เร็วที่สุด
3. **Dev สายแนวตั้ง: ก้อน V2** (heartbeat / leave ห้องเดิม) — ปิดได้ 5 ใบด้วยกลไกเดียว
4. **Dev สายแนวนอน: ก้อน H1** (`pointer-events-auto`) — PR เดียวปิดได้ 4 ใบ
5. **PM ตัดสินข้อ 🗳** — โดยเฉพาะ V-13 (วาร์ป) ที่ชี้ชะตา V-02/V-03
