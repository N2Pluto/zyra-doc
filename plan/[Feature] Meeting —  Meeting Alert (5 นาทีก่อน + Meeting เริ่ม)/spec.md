# SC-MTG-CAL-03 · Meeting — Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)

> **สถานะ (2026-10-27):** **Spec ถอดจาก ClickUp + ดึง Figma ครบ 6 section แล้ว ([ux-ui-plan.md](ux-ui-plan.md)) — ยังไม่ implement · ยังไม่ได้ตรวจโค้ด** · Figma ขัดกับ ClickUp 20 จุด → [ux-ui-plan §7](ux-ui-plan.md#7-figma-vs-clickup--ข้อขัดแย้งที่ต้องถาม)
> **ส่งต่อ dev (2026-10-29):** ทำก่อน CAL-01 / CAL-02 — เริ่มที่ [task-breakdown.md](task-breakdown.md) · **implement รอบ 1 แล้ว (ยังไม่ commit) → [progress.md](progress.md)**
> **กติกากลาง 3 ฟีเจอร์ (ผู้ใช้ตัดสิน 2026-10-29):** Figma กับ ClickUp ขัดกัน → **ยึด Figma** ยกเว้นข้อที่ผู้ใช้ตัดสินเป็นอย่างอื่น (ดู [CAL-01 spec §6.1](<../[Feature] Meeting — Calendar Integration/spec.md>)) · ข้อที่มีแค่ฝั่งเดียว (Figma ไม่ได้วาด) ยังเป็นคำถามเปิด จนกว่าจะตัดสิน
> **วันที่ถอด:** 2026-10-27 · **ClickUp:** [[Feature] Meeting — Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)](https://app.clickup.com/t/86d3nbdqn) (`in progress` · priority High · tag `client` · custom field Desktop ✓ · assignee P A, Ponlawat Lueakaew, rif fullstack · creator Moss Pm · สร้าง 2026-07-10 · due 2026-10-30 · แก้ล่าสุด 2026-10-29)
> **ตรวจ ClickUp ซ้ำ 2026-10-29:** เนื้อหา parent + 7 subtask **ตรงกับ §1–§5 ทุกคำ** (ไม่มี requirement ใหม่) · เปลี่ยนแค่ metadata: ทุกตัว `pending` → `in progress` · ทุก subtask assign ให้ rif fullstack · parent มี due date · ยังไม่มี comment / attachment / checklist
> **ฟีเจอร์คู่กัน:** [SC-MTG-CAL-02 Calendar Display](<../[Feature] Meeting — Calendar Display/spec.md>) — กด alert แล้วเปิด Calendar View + event detail popup (CLDD-HP-05) · ทั้งสองพึ่ง [SC-MTG-CAL-01 Calendar Integration](../MeetingCalendarIntegration/spec.md) (scheduled meeting)
> **CAL-01 (ใช้หน้าจอร่วมกัน):** [Calendar Integration spec](<../[Feature] Meeting — Calendar Integration/spec.md>) · ตารางส่วนที่ 3 ฟีเจอร์ใช้ร่วมกัน + ตารางสิทธิ์ตามบทบาท → [CAL-01 ux-ui-plan §1, §7.2](<../[Feature] Meeting — Calendar Integration/ux-ui-plan.md>)
> **โครงเอกสาร:** §1–§5 = requirement ต้นทางจาก ClickUp (ถอดตามที่เขียน ไม่แต่งเติม) · §6 = ข้อสังเกต / จุดขัดกันในต้นทาง (ยังไม่ใช่ decision)

---

## 1. Overview (จาก ClickUp parent)

**Module:** Meeting Module — Project Zyra
**Persona:** Workspace Member ที่มี meeting scheduled
**Channel:** In-app notification เท่านั้น
**Trigger Times:** 5 นาทีก่อน meeting + ตอน meeting เริ่ม

ระบบแจ้งเตือน user ผ่าน in-app notification เมื่อ meeting ใกล้จะเริ่ม และเมื่อ meeting เริ่มแล้ว เพื่อให้ user เข้า meeting ได้ทันเวลา

### Alert types ที่รองรับ

| # | Trigger | Alert |
|---|---|---|
| 1 | 5 นาทีก่อน meeting | Notification + Banner |
| 2 | Meeting เริ่มแล้ว | Notification + Banner + "Join Now" (เข้าร่วมเลย) |

### User Stories

```
As a Workspace Member
I want to be notified 5 minutes before my meeting starts
So that I have time to prepare and join on time

As a Workspace Member
I want to be notified when my meeting has started
So that I can join immediately with one click
```

(ฉันอยากได้รับแจ้งเตือน 5 นาทีก่อน meeting เริ่ม จะได้มีเวลาเตรียมตัวและเข้าทัน · ฉันอยากได้รับแจ้งเตือนเมื่อ meeting เริ่มแล้ว จะได้กดเข้าได้ทันทีในคลิกเดียว)

### Source links

| แหล่ง | ลิงก์ |
|---|---|
| ClickUp parent | [[Feature] Meeting — Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)](https://app.clickup.com/t/86d3nbdqn) |
| Figma file | `Map8gX0L2hk7HnkaFRfhtj` — Zyra design (More Organised ver.) · node ต่อ scenario ดู §2 |
| ClickUp comments | ไม่มี — ทั้ง parent และ 7 subtask (ตรวจ 2026-10-27) |
| Attachments / checklists / custom fields | ไม่มี (ตรวจ 2026-10-27) |

---

## 2. Scope & Scenario Index (7 subtasks + 5 edge cases)

| ID | ชื่อ | ClickUp | Figma node | สถานะ ClickUp |
|---|---|---|---|---|
| MA-HP-01 | Alert 5 นาทีก่อน Meeting | [MA-HP-01 · Alert 5 นาทีก่อน Meeting](https://app.clickup.com/t/86d3nf5bq) | [`7764-170718`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7764-170718) | in progress |
| MA-HP-02 | Alert ตอน Meeting เริ่ม | [MA-HP-02 · Alert ตอน Meeting เริ่ม](https://app.clickup.com/t/86d3nf5j5) | [`7766-463132`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7766-463132) | in progress |
| MA-HP-03 | Notification History | [MA-HP-03 · Notification History](https://app.clickup.com/t/86d3nf5qz) | [`7767-466425`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7767-466425) | in progress |
| MA-HP-04 | User ปิด Alert (Dismiss) | [MA-HP-04 · User ปิด Alert (Dismiss)](https://app.clickup.com/t/86d3nf66k) | [`7767-469956`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7767-469956) | in progress |
| MA-EP-01 | User ไม่ Online เมื่อ Alert ถูกส่ง | [MA-EP-01 · User ไม่ Online เมื่อ Alert ถูกส่ง](https://app.clickup.com/t/86d3nf6ay) | [`7771-8157`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7771-8157) | in progress |
| MA-EP-02 | Meeting ถูกยกเลิก / เลื่อนเวลาหลัง Alert ส่งไปแล้ว | [MA-EP-02 · Meeting ถูกยกเลิก / เลื่อนเวลาหลัง Alert ส่งไปแล้ว](https://app.clickup.com/t/86d3nf6g4) | [`7771-198052`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7771-198052) | in progress |
| MA-EP-03 | Notification ส่ง Duplicate (Race Condition) | [MA-EP-03 · Notification ส่ง Duplicate (Race Condition)](https://app.clickup.com/t/86d3nf6my) | — (backend ล้วน ไม่มีลิงก์ Figma) | in progress |
| EC-01 ~ EC-05 | Edge cases (อยู่ใน parent) | — | — | — |

ทุก subtask: assignee rif fullstack (ตั้ง 2026-10-29) · ไม่มี priority · ไม่มี due date · สร้าง 2026-07-10 โดย Moss Pm

---

## 3. Scenarios (ถอดจาก subtask)

### MA-HP-01 · Alert 5 นาทีก่อน Meeting

**Pre-condition:** User มี Zyra meeting scheduled, user online อยู่ใน Workspace

**Scenario Steps:**
1. Cron job ตรวจสอบทุก 1 นาที: meeting ใดที่จะเริ่มใน 5 นาที
2. ส่ง in-app notification ให้ทุก invited participants
3. Notification แสดงมุมขวาบน:
   - 🔔 **"[ชื่อ meeting] เริ่มในอีก 5 นาที"**
   - เวลาเริ่ม + ชื่อห้อง
   - ปุ่ม "เปิด Calendar" เพื่อดูรายละเอียด
4. Notification Badge (bell icon) บน navbar เพิ่ม count
5. User กด notification → เปิด event detail popup บน Calendar View

**Acceptance Criteria:**

| # | AC |
|---|---|
| AC-HP01-1 | Alert ส่งทุก invited participants พร้อมกัน ไม่เกิน **30 วินาที** ก่อนครบ 5 นาที |
| AC-HP01-2 | Notification แสดงมุมขวาบน (toast style) ค้างไว้ **3 นาที** แล้วหายเอง |
| AC-HP01-3 | กด notification → navigate ไป Calendar View + เปิด event detail popup |
| AC-HP01-4 | Notification badge count เพิ่มขึ้น 1 |
| AC-HP01-5 | Alert ส่ง **1 ครั้งเท่านั้น** ต่อ meeting ต่อ user (ไม่ spam ซ้ำ) |
| AC-HP01-6 | ถ้า user ไม่ online: notification เก็บไว้ แสดงเมื่อ user กลับมา online |

**Figma:** node `7764-170718`

---

### MA-HP-02 · Alert ตอน Meeting เริ่ม

**Pre-condition:** Meeting ถึงเวลาเริ่มตาม schedule

**Scenario Steps:**
1. Cron job ตรวจสอบ meeting ที่ถึงเวลาเริ่ม (`meeting_start_at <= now`)
2. ส่ง in-app notification ให้ทุก invited participants
3. Notification แสดง:
   - 🎙 **"[ชื่อ meeting] เริ่มแล้ว!"**
   - ชื่อห้อง + จำนวนคนที่อยู่ในห้องแล้ว
   - ปุ่ม **"Join Now"** สีเขียว (primary action)
4. User กด "Join Now" → navigate ไปยัง Virtual Office room ของ meeting ทันที

**Acceptance Criteria:**

| # | AC |
|---|---|
| AC-HP02-1 | Alert ส่งภายใน **1 นาที** หลัง `meeting_start_at` |
| AC-HP02-2 | Notification แสดงพร้อมปุ่ม **"Join Now"** สีเขียว |
| AC-HP02-3 | กด "Join Now" → navigate ไป Virtual Office room โดยตรง ไม่ผ่านหน้า Calendar |
| AC-HP02-4 | แสดงจำนวนคนที่อยู่ในห้องแล้ว เช่น "มี 3 คนรออยู่" |
| AC-HP02-5 | Notification ค้างไว้ **3 นาที** แล้วหายเอง (นานกว่า 5-min alert เพราะ urgent กว่า) — ⚠️ ดู §6 ข้อ 1 |
| AC-HP02-6 | Alert ส่ง **1 ครั้งเท่านั้น** ต่อ meeting ต่อ user |

**Figma:** node `7766-463132`

---

### MA-HP-03 · User ดู Notification History

**Pre-condition:** User มี alerts ที่ผ่านมาแล้ว

**Scenario Steps:**
1. User กด bell icon บน navbar
2. Notification panel เปิด: แสดง notifications ทั้งหมดเรียงจากใหม่ → เก่า
3. Meeting alerts แสดงพร้อม: ชื่อ meeting, เวลา, status (ผ่านไปแล้ว / ยัง active)
4. กด notification ที่ผ่านไปแล้ว → เปิด Calendar View ที่วันของ meeting นั้น

**Acceptance Criteria:**

| # | AC |
|---|---|
| AC-HP03-1 | Notification panel แสดง alerts ย้อนหลัง **7 วัน** |
| AC-HP03-2 | Meeting alerts ที่ "ผ่านไปแล้ว" แสดง greyed out |
| AC-HP03-3 | Meeting alerts ที่ยัง active: ปุ่ม "Join Now" ยังแสดงถ้า meeting ยังไม่จบ |
| AC-HP03-4 | ปุ่ม "Mark all as read" (อ่านทั้งหมดแล้ว) |
| AC-HP03-5 | Badge count รีเซ็ตเป็น 0 เมื่อ user เปิด panel |

**Figma:** node `7767-466425`

---

### MA-HP-04 · User ปิด Alert (Dismiss)

**Scenario Steps:**
1. Notification toast แสดงมุมขวาบน
2. User กด X เพื่อ dismiss
3. Toast หาย — notification ยังอยู่ใน notification history

**Acceptance Criteria:**

| # | AC |
|---|---|
| AC-HP04-1 | กด X: toast หายทันที |
| AC-HP04-2 | Notification ยังอยู่ใน history (ไม่ถูกลบ) |
| AC-HP04-3 | Dismiss 1 notification: ไม่กระทบ notifications อื่น |

**Figma:** node `7767-469956`

---

### MA-EP-01 · User ไม่ Online เมื่อ Alert ถูกส่ง

**Trigger:** Cron job trigger alert แต่ user offline

**Expected Behavior:**

| # | AC |
|---|---|
| AC-EP01-1 | Alert เก็บใน DB ด้วย status = `pending` |
| AC-EP01-2 | เมื่อ user กลับมา online: แสดง notification ที่ค้างอยู่ทันที |
| AC-EP01-3 | Notifications ที่ค้างไว้แสดงพร้อมกัน (bundle) ถ้ามีหลายอัน: "คุณมี 3 meeting alerts ที่พลาดไป" |

**Figma:** node `7771-8157`

---

### MA-EP-02 · Meeting ถูกยกเลิก / เลื่อนเวลาหลัง Alert ส่งไปแล้ว

**Trigger:** Meeting แก้ไขเวลาหรือยกเลิก หลัง 5-min alert ส่งไปแล้ว

**Expected Behavior:**

| # | AC |
|---|---|
| AC-EP02-1 | Alert ที่ส่งไปแล้ว: ไม่สามารถ recall ได้ (notification ส่งไปแล้ว) |
| AC-EP02-2 | ส่ง notification ใหม่: "🔄 [ชื่อ meeting] ถูกเลื่อน/ยกเลิกแล้ว" |
| AC-EP02-3 | ปุ่ม "Join Now" บน notification เดิม: redirect ไป Calendar View แทน (ไม่ navigate ไป room ที่ไม่มีแล้ว) |

**Figma:** node `7771-198052`

---

### MA-EP-03 · Notification ส่ง Duplicate (Race Condition)

**Trigger:** Cron job รันซ้ำหรือ server restart ขณะ sending

**Expected Behavior:**

| # | AC |
|---|---|
| AC-EP03-1 | Server-side idempotency: ตรวจ `alert_sent_log` ก่อนส่ง |
| AC-EP03-2 | ถ้าส่งแล้ว: skip ไม่ส่งซ้ำ |
| AC-EP03-3 | User ไม่ได้รับ notification ซ้ำ |

**Figma:** ไม่มี

---

## 4. Edge Cases (จาก ClickUp parent)

| # | Case | Expected Behavior |
|---|---|---|
| EC-01 | Meeting เริ่มในน้อยกว่า 5 นาที (สร้าง meeting ช่วง short notice) | ส่ง 5-min alert ทันที ถ้าเวลาเหลือ > 1 นาที / ส่ง start alert ทันทีถ้าเหลือ < 1 นาที |
| EC-02 | User มีหลาย meetings ในเวลาใกล้กัน | ส่ง alert แยกต่อ meeting — ไม่ bundle เป็นอันเดียว |
| EC-03 | Meeting Timezone ต่างกับ User | คำนวณเวลา alert ตาม user timezone เสมอ |
| EC-04 | User อยู่ใน meeting อื่นอยู่แล้ว | ยังส่ง alert ปกติ — user เลือกเองว่าจะ join หรือไม่ |
| EC-05 | Cron job ล่าช้า (server load สูง) | Alert อาจส่งช้าไม่เกิน 2 นาที — acceptable tolerance |

---

## 5. Business Logic / Rules (จาก ClickUp parent)

- **Deduplication:** เก็บ `meeting_alert_log (meeting_id, user_id, alert_type)` UNIQUE — ป้องกัน duplicate
- **Cron job:** ทำงานทุก **1 นาที** ตรวจ meetings ที่ `start_at BETWEEN now AND now + 5 minutes`
- **Start alert:** ตรวจ meetings ที่ `start_at BETWEEN now - 1 minute AND now`
- **User offline:** เก็บ alert ไว้ใน `notifications` table status = `pending` — deliver เมื่อ user reconnect

---

## 6. ข้อสังเกต / จุดขัดกันในต้นทาง

ข้อสังเกตจากการอ่าน ClickUp เท่านั้น — **ยังไม่ใช่ decision** ต้องถาม PM (Moss Pm)

| # | จุด | รายละเอียด | ต้องถาม |
|---|---|---|---|
| 1 | ระยะเวลาค้างของ toast | HP-01 = 3 นาที · HP-02 = 3 นาที แต่เขียนว่า "นานกว่า 5-min alert เพราะ urgent กว่า" — ตัวเลขเท่ากัน | HP-02 ค้างกี่นาทีจริง |
| 2 | ชื่อตาราง dedupe ไม่ตรงกัน | parent: `meeting_alert_log` · EP-03: `alert_sent_log` | ใช้ตารางเดียวกันใช่ไหม |
| 3 | Dedupe UNIQUE ชนกับการเลื่อนเวลา | UNIQUE `(meeting_id, user_id, alert_type)` → ถ้า meeting ถูก**เลื่อน**หลังส่ง 5-min alert แล้ว เวลาใหม่จะส่ง alert ไม่ได้อีก (EP-02 ไม่ได้บอกว่าให้ส่ง alert ตามเวลาใหม่หรือไม่) | เลื่อนเวลาแล้วต้องส่ง 5-min / start alert ใหม่ไหม (ถ้าใช่ ต้องใส่ `start_at` ใน key หรือลบ log) |
| 4 | Tolerance เวลาไม่ตรงกัน | HP-01: ไม่เกิน 30 วินาที · HP-02: ภายใน 1 นาที · EC-05: ช้าได้ไม่เกิน 2 นาที · cron รันทุก 1 นาที (granularity 1 นาทีอยู่แล้ว) | เกณฑ์ที่ใช้เทสจริง |
| 5 | EC-01 ช่วงเวลา 1–5 นาที | "เหลือ > 1 นาที → ส่ง 5-min alert ทันที" — ข้อความใน toast ยังเขียน "เริ่มในอีก 5 นาที" ได้หรือไม่ ถ้าจริงๆ เหลือ 2 นาที | copy ของ toast กรณี short notice |
| 6 | Bundle vs ไม่ bundle | EC-02: ไม่ bundle (user online) · EP-01: bundle เมื่อกลับมา online | ยืนยันว่าต่างกันตามสถานะ online |
| 7 | Event จาก Google / Outlook | Pre-condition เขียน "Zyra meeting" — event ที่ sync มาจาก Google/Outlook (CAL-01) ต้องได้ alert ไหม | scope ของ alert |
| 8 | ใครได้รับ alert | "ทุก invited participants" — รวม guest ที่ตอบ **No** (RSVP ใน Figma ของ CAL-02 HP-05) ไหม · organiser ได้ไหม | filter ตาม RSVP |
| 9 | "bell icon บน navbar" | Zyra ไม่มี navbar ด้านบน — Figma ของ CAL-02 มีไอคอน Notifications ใน **sidebar** ซ้าย | ใช้ไอคอน Notifications เดิมใน sidebar ใช่ไหม · เป็น notification panel เดิมหรือใหม่ |
| 10 | Badge reset | HP-03: badge = 0 เมื่อเปิด panel · มีปุ่ม "Mark all as read" ด้วย — ถ้าเปิด panel = อ่านแล้ว ปุ่มนี้ทำอะไรเพิ่ม (unread dot รายตัว?) | ความต่างระหว่าง "seen" กับ "read" |
| 11 | "Join Now" → Virtual Office room | ไม่ระบุ mapping meeting → workspace / room / zone (เหมือน CAL-02 §5 ข้อ 6) | meeting ผูกกับ room ยังไง |
| 12 | "มี 3 คนรออยู่" | จำนวนคน ณ เวลาส่ง alert (snapshot) หรือ live update ระหว่างที่ toast ค้าง 3 นาที | snapshot หรือ realtime |
| 13 | Cancelled meeting | EP-02 พูดถึงกรณีหลัง 5-min alert — ถ้ายกเลิก**ก่อน** alert ต้องไม่ส่ง (ไม่ได้เขียน แต่ควรตรวจ) · notification เดิมใน history แสดงสถานะอะไร | สถานะใน history |
| 14 | Channel | "In-app เท่านั้น" — แอปมือถือ (Capacitor) มี push อยู่แล้ว ([MobileApp](../MobileApp/)) | ยืนยันว่าไม่ส่ง push / email |
| 15 | 7 วันย้อนหลัง | ใช้กับ meeting alerts เท่านั้น หรือ notification ทุกชนิดใน panel | scope ของ retention |
| 16 | EC-03 timezone | alert คำนวณจาก `start_at` (absolute time) อยู่แล้ว — timezone มีผลแค่ตอนแสดงเวลาใน toast | แหล่ง timezone ของ user (browser / profile) |

---

## 7. ตรวจกับโค้ด (2026-10-27) — สรุป

รายละเอียดทุก AC + file:line อยู่ใน **[code-gap.md](code-gap.md)** (ตรวจ `origin/develop` zyra-app `22fc0d6d` / zyra-api `aaf5d7c` / zyra-ws `1ec265f` / zyra-notifications `20eab8f` · read-only · ยังไม่ได้รัน test)

**ภาพรวม:** ท่อส่ง notification **มีครบแล้วเกือบทั้งหมด** — `tb_notification` + `/api/user/notifications*` (UserGuard ✅ rule 15) + Redis `vo:notify` → zyra-ws `chat:notification:new` → bell panel (View all / Unread, Today / Yesterday, Mark all read) + badge ใน sidebar · มีแม่แบบใกล้ที่สุดคือ **Spotlight live/ended** (การ์ดมี Join + เปลี่ยนเป็น ended) · ที่ขาดคือ **ตัวตั้งเวลา + ประเภท notification ของ meeting + dedupe + สถานะ meeting**

| สถานะ | เรื่อง |
|---|---|
| ✅ มีแล้ว / ใช้ต่อได้ | panel + tabs + กลุ่มวัน + Mark all read · badge realtime · X ปิด toast โดยไม่ลบ history (HP-04 ครบ) · `zyraToast` layout figma (336, icon box 40, title/body, X, ปุ่ม primary เขียว/secondary ขาว) ที่ top 24 / right 24 ตรง Figma · Join → เดินไปห้อง (`joinCalendarMeeting`) · จำนวนคนในห้อง (`zoneSections`) · pattern dedupe (`ON CONFLICT DO NOTHING` ของ weather, atomic claim ของ announcement) · โครง background loop ใน `main.go` |
| ❌ ยังไม่มี | **scheduler ของ meeting** · notification type ของ meeting · ตาราง dedupe · `status` / `cancelled_at` ของ meeting · **API แก้/ยกเลิก meeting ใน Zyra** · RSVP · toast variant เทา/ส้ม + body 2 บรรทัด · การ์ด meeting ใน panel (Join เฉพาะยังไม่จบ, past, cancelled, rescheduled) · toast "You missed N meetings" ตอนกลับมา · เปิด Calendar ไปที่ event/วันที่กำหนด |
| ⚠️ ขัดกับโค้ด | ClickUp `notifications` + `status = pending` → ของจริง **`tb_notification` มีแค่ `is_read`** (ไม่มี status) · type ใหม่ต้องเพิ่มใน **superset CHECK ของ `postgres.go`** รอบเดียวกับ migration (เคยทำ dev boot ไม่ขึ้นมาแล้ว) · **digest email ไม่กรอง type** → ต้อง insert `email_suppressed = true` ไม่งั้นส่งอีเมล (ขัด "in-app เท่านั้น") · **setting "Event reminders" มีอยู่แล้วแต่บอก 10 นาที** และ toggle `event_reminders` / `event_start` / `event_changes` / `event_cancellations` ยังไม่มีผลกับอะไรเลย · badge = unread ใน 30 row ล่าสุด แค่**ซ่อน**ตอนเปิด panel ไม่ได้ reset (AC-HP03-5) · tick 1 นาทีทำ "≤30 วิ" ไม่ได้ (ต้อง 15–30 วิ) · cancel/reschedule เกิดได้ทางเดียวคือ Google inbound sync ที่ทำงาน**เฉพาะตอนมีคนเปิด Calendar** และลบ = **hard delete** · "online" ฝั่ง API = heartbeat ทั้งแอป แต่ toast ส่งถึงเฉพาะคนที่อยู่ใน room ของ workspace นั้น · Google event ไม่ได้เก็บ DB → alert ได้เฉพาะ Zyra meeting · panel ไม่มี load-more / ไม่มี 7 วัน |

งานแบ่งเป็น PR ได้ ~9 ข้อ (api 3 · app 5 · doc 1) → [code-gap.md §E](code-gap.md#e-suggested-pr-sized-task-list-suggestion) · ร่าง DB/API (ยังไม่ใช่ decision) → [code-gap.md §D](code-gap.md#d-db--api-impact-sketch-suggestion--ยังไม่ใช่-decision-ไม่มีโค้ด) — เช่นใส่ `start_at` ใน UNIQUE ของ alert log เพื่อแก้ §6 ข้อ 3

---

## 8. จุดที่ทับกับ Calendar Display (SC-MTG-CAL-02)

ตารางเต็ม X1–X8 อยู่ที่ [Calendar Display spec §7](<../[Feature] Meeting — Calendar Display/spec.md#7-จุดที่ทับกับ-meeting-alert-sc-mtg-cal-03>) — สรุป: ทั้งสองการ์ดต้อง (X1) เปิด Calendar ได้โดยไม่ผูก `GOOGLE_CALENDAR_ENABLED` · (X2) prop `focus` ใน `VOCalendar` · (X3) Event detail popup ตัวเดียว · (X4) นิยาม active + soft cancel ใน migration เดียว · (X5) ย้าย `use-calendar-data` ไป react-query ก่อน · (X6) เพิ่ม variant ใน `lib/toast.tsx` ครั้งเดียว · (X7) copy Join ชุดเดียว · (X8) ตัดสิน mobile พร้อมกัน — **แนะนำให้ทำ X1, X2, X4, X5 เป็นฐานร่วมก่อน แล้วค่อยแยกงานสองการ์ด**

---

## 9. ขั้นถัดไป

- ~~ดึงค่า Figma 6 node (§2) → [ux-ui-plan.md](ux-ui-plan.md)~~ — เสร็จ 2026-10-27
- ~~ตรวจโค้ดจริง แล้วเขียน baseline + gap~~ — เสร็จ 2026-10-27 ([code-gap.md](code-gap.md), สรุป §7)
- **2026-10-29: Ten แยกฟีเจอร์นี้ให้ dev อีกคนทำก่อน CAL-01 / CAL-02** → ขอบเขต, เจ้าของส่วนที่ใช้ร่วมกัน, ร่าง API / DB, ลำดับ PR, คำถามที่ยังเปิด (มีค่าแนะนำ) อยู่ที่ [task-breakdown.md](task-breakdown.md)
- **POC (HTML)** อยู่รวมกับ Calendar Display — [poc/index.html](<../[Feature] Meeting — Calendar Display/poc/index.html>) · ปุ่ม "ส่ง Meeting Alert" จำลอง HP-01/02, EP-01/02/03 (dedupe)
- ถาม PM เพิ่ม: 5 นาทีหรือ 10 นาที (setting เดิมบอก 10) · alert all-day meeting ไหม · EP-02 จาก Zyra ต้องมี edit/cancel meeting ก่อน (ยังไม่มี) — อยู่ใน scope ใคร
- ส่งคำถาม §6 ให้ PM (รวมกับ CAL-02 §5 เพราะเป็นชุดเดียวกัน)
