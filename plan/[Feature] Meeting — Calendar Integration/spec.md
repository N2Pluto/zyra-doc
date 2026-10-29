# SC-MTG-CAL-01 · Meeting — Calendar Integration (Google Calendar + Microsoft Outlook)

> **สถานะ (2026-10-29):** **Spec ถอดจาก ClickUp รอบใหม่ (9 subtask — มี HP-05 Cancel / HP-06 Reschedule เพิ่ม 2026-10-27)** · ค่า Figma อยู่ใน [ux-ui-plan.md](ux-ui-plan.md)
> **ClickUp:** [[Feature] Meeting — Calendar Integration](https://app.clickup.com/t/86d3nbcrq) (`in progress` · priority High · tag `client` · assignee Ponlawat Lueakaew, rif fullstack · creator Moss Pm · สร้าง 2026-07-10 · แก้ล่าสุด 2026-10-26)
> **ฟีเจอร์ชุดเดียวกัน (ใช้หน้าจอร่วมกัน):** [SC-MTG-CAL-02 Calendar Display](<../[Feature] Meeting — Calendar Display/spec.md>) · [SC-MTG-CAL-03 Meeting Alert](<../[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/spec.md>) — ส่วนที่ใช้ร่วมกันดู [ux-ui-plan §1](ux-ui-plan.md#1-ส่วนที่-3-ฟีเจอร์ใช้ร่วมกัน)
> **เอกสารเดิมของการ์ดนี้ (ยังใช้อ้างอิง):** [MeetingCalendarIntegration/](../MeetingCalendarIntegration/) — spec รอบแรก (2026-10-12) + decision log §9 + progress การ implement HP-01/HP-03 · [CalendarIntegration/](../CalendarIntegration/) — technical design + Google verification ของ N2Pluto · ไฟล์ในโฟลเดอร์นี้ถอดใหม่จาก ClickUp ณ 2026-10-29 · **ยังไม่ได้รวม/ย้ายโฟลเดอร์เดิม**
> **โครงเอกสาร:** §1–§5 = requirement ต้นทางจาก ClickUp (ถอดตามที่เขียน ไม่แต่งเติม) · §6 = ข้อสังเกตจากการอ่าน (ยังไม่ใช่ decision)

---

## 1. Overview (จาก ClickUp parent)

**Module:** Meeting Module — Project Zyra
**Persona:** Workspace Member (user แต่ละคน connect เอง)

User เชื่อมต่อ Google Calendar หรือ Microsoft Outlook ของตัวเองกับ Zyra เพื่อให้ events จากทั้งสองแหล่ง sync เข้า Zyra ได้อัตโนมัติ และเมื่อสร้าง Zyra meeting ก็ sync กลับไปยัง calendar ภายนอก

### User Stories

```
As a Workspace Member
I want to connect my Google Calendar / Outlook to Zyra
So that I can see all my meetings in one place without switching apps

As a Workspace Member
I want Zyra meetings I create to sync to my external calendar
So that colleagues who use Google/Outlook can also see them
```

(ฉันอยากเชื่อม Google Calendar / Outlook กับ Zyra จะได้เห็น meeting ทั้งหมดในที่เดียวโดยไม่ต้องสลับแอป · ฉันอยากให้ Zyra meeting ที่สร้าง sync ไป calendar ภายนอก เพื่อให้เพื่อนร่วมงานที่ใช้ Google/Outlook เห็นด้วย)

### Source links

| แหล่ง | ลิงก์ |
|---|---|
| ClickUp parent | [[Feature] Meeting — Calendar Integration](https://app.clickup.com/t/86d3nbcrq) |
| Figma | `Map8gX0L2hk7HnkaFRfhtj` page "✅ Calendar Integration" `3225:480433` · node ต่อ scenario ดู §2 |
| ClickUp comments | ไม่มี — parent + 9 subtask (ตรวจ 2026-10-29) |
| Attachments / checklists / custom fields | ไม่มี |

---

## 2. Scope & Scenario Index (9 subtasks + 4 edge cases)

| ID | ชื่อ | ClickUp | สถานะ ClickUp | Figma section |
|---|---|---|---|---|
| CLDI-HP-01 | Connect Google Calendar สำเร็จ | [CLDI-HP-01 · Connect Google Calendar สำเร็จ](https://app.clickup.com/t/86d3nf00n) | waitdeploy-dev | [`3237-609135`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3237-609135) |
| CLDI-HP-02 | Connect Microsoft Outlook สำเร็จ | [CLDI-HP-02 · Connect Microsoft Outlook สำเร็จ](https://app.clickup.com/t/86d3nf08e) | pending | [`3301-5048`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3301-5048) |
| CLDI-HP-03 | สร้าง Zyra Meeting แล้ว Sync ไป Calendar ภายนอก | [CLDI-HP-03 · สร้าง Zyra Meeting แล้ว Sync ไป Calendar ภายนอก](https://app.clickup.com/t/86d3nf0c9) | in progress | [`3583-77760`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3583-77760) |
| CLDI-HP-04 | Disconnect Calendar | [CLDI-HP-04 · Disconnect Calendar](https://app.clickup.com/t/86d3nf0gc) | waitdeploy-dev | [`3601-762611`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3601-762611) |
| CLDI-HP-05 | ยกเลิก Meeting / Event (Cancel) **ใหม่** | [CLDI-HP-05 · ยกเลิก Meeting / Event (Cancel)](https://app.clickup.com/t/14zd0zuegwe) | Open · assignee P A · High | ไม่มีลิงก์ใน ClickUp |
| CLDI-HP-06 | เลื่อน Meeting / Event (Reschedule) **ใหม่** | [CLDI-HP-06 · เลื่อน Meeting / Event (Reschedule)](https://app.clickup.com/t/14zd0zuegwh) | Open · assignee P A · High | ไม่มีลิงก์ใน ClickUp |
| CLDI-EP-01 | User ปฏิเสธ OAuth Consent | [CLDI-EP-01 · User ปฏิเสธ OAuth Consent](https://app.clickup.com/t/86d3nf0n6) | waitdeploy-dev | [`3601-766158`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3601-766158) |
| CLDI-EP-02 | Token หมดอายุ / Revoked | [CLDI-EP-02 · Token หมดอายุ / Revoked](https://app.clickup.com/t/86d3nf0qe) | pending | [`3601-769864`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3601-769864) |
| CLDI-EP-03 | Sync ล้มเหลว (Rate Limit / Server Error) | [CLDI-EP-03 · Sync ล้มเหลว (Rate Limit / Server Error)](https://app.clickup.com/t/86d3nf0vv) | pending | [`3602-834434`](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3602-834434) |
| EC-01 ~ EC-04 | Edge cases (parent) | — | — | — |

HP-01…EP-03: สร้าง 2026-07-10 โดย Moss Pm ไม่มี assignee · HP-05/HP-06: สร้าง 2026-10-27 โดย Moss Pm

---

## 3. Scenarios (ถอดจาก subtask)

### CLDI-HP-01 · Connect Google Calendar สำเร็จ

**Pre-condition:** User login Zyra แล้ว ยังไม่ได้เชื่อมต่อ calendar ใด ๆ

**Scenario Steps:**
1. User เข้า Workspace Settings → Integrations → Calendar
2. กด **"เชื่อมต่อ Google Calendar"**
3. Popup Google OAuth consent screen เปิด — ไม่ redirect ออกจาก Zyra
4. User เลือก Google account และ approve scopes: `calendar.readonly` + `calendar.events`
5. Popup ปิด กลับ Zyra อัตโนมัติ
6. calendars sync อัตโนมัติ
7. Toast: "เชื่อมต่อ Google Calendar สำเร็จ — กำลัง sync events..."
8. Zyra แสดง calendar selector: รายชื่อ Google Calendars (Primary, Work, Personal ฯลฯ) — Optional

| # | Acceptance Criteria |
|---|---|
| AC-HP01-1 | OAuth popup เปิดเป็น popup window — ไม่ redirect tab หลัก |
| AC-HP01-2 | Connected badge แสดงบน Google Calendar section ใน Settings |
| AC-HP01-3 | Events จาก Google sync เข้า Zyra ภายใน **30 วินาที** |
| AC-HP01-4 | Token เก็บ server-side encrypted — ไม่ปรากฏใน localStorage / URL |
| AC-HP01-5 | Zyra meetings ที่มีอยู่ถูก push ไปสร้างใน Google Calendar อัตโนมัติ |

---

### CLDI-HP-02 · Connect Microsoft Outlook สำเร็จ

**Pre-condition:** User login Zyra แล้ว ยังไม่ได้เชื่อมต่อ Outlook

**Scenario Steps:**
1. User เข้า Settings → Integrations → Calendar
2. กด **"เชื่อมต่อ Microsoft Outlook"**
3. Popup Microsoft OAuth เปิด (scope: `Calendars.ReadWrite`)
4. User login Microsoft account และ approve
5. Popup ปิด กลับ Zyra
6. Zyra แสดง calendar selector ของ Outlook
7. User เลือก calendars และกด "บันทึก"

| # | Acceptance Criteria |
|---|---|
| AC-HP02-1 | Connected badge แสดงบน Outlook section |
| AC-HP02-2 | User สามารถ connect ทั้ง Google + Outlook พร้อมกันได้ — ไม่ conflict |
| AC-HP02-3 | Events จาก Outlook sync เข้า Zyra ภายใน **30 วินาที** |

---

### CLDI-HP-03 · สร้าง Zyra Meeting แล้ว Sync ไป Calendar ภายนอก

**Pre-condition:** User connect Google + Outlook แล้ว

**Scenario Steps:**
1. User สร้าง meeting ใน Zyra (ชื่อ, เวลา, ห้อง, attendees)
2. ระบบ auto-create event ใน Google Calendar และ Outlook
3. Event มี: ชื่อ, เวลา, description, Zyra meeting join link
4. Attendees ได้รับ calendar invite จาก Google / Outlook (ถ้า email ตรงกัน)

| # | Acceptance Criteria |
|---|---|
| AC-HP03-1 | Event ปรากฏใน Google Calendar ภายใน **10 วินาที** |
| AC-HP03-2 | Event ปรากฏใน Outlook ภายใน **10 วินาที** |
| AC-HP03-3 | Zyra join link แนบใน description ของ calendar event ภายนอก |
| AC-HP03-4 | ถ้า sync ล้มเหลว: Zyra meeting ยังสร้างสำเร็จ พร้อม toast warning |

---

### CLDI-HP-04 · Disconnect Calendar

**Pre-condition:** User connect Google Calendar แล้ว

**Scenario Steps:**
1. User เข้า Settings → Integrations → กด **"ยกเลิกการเชื่อมต่อ"** ถัดจาก Google
2. Confirmation: "ยกเลิกการเชื่อมต่อ Google Calendar? Events จาก Google จะไม่แสดงใน Zyra"
3. User กด "ยกเลิกการเชื่อมต่อ"
4. Token revoke + synced Google events ลบออกจาก Zyra

| # | Acceptance Criteria |
|---|---|
| AC-HP04-1 | Google events หายออกจาก Zyra ทันทีหลัง disconnect |
| AC-HP04-2 | Token revoke ยืนยันได้ผ่าน Google Account → Security |
| AC-HP04-3 | Zyra meetings ที่เคย push ไป Google: **ยังอยู่ใน Google** (ไม่ลบ) |
| AC-HP04-4 | Settings badge เปลี่ยนเป็น "ไม่ได้เชื่อมต่อ" + ปุ่ม "เชื่อมต่อ" |

---

### CLDI-HP-05 · ยกเลิก Meeting / Event (Cancel) — ใหม่ 2026-10-27

**Type:** Happy Path (พร้อม Error Path และ Edge Case)
**Persona:** Meeting Organizer (ผู้สร้าง) / Workspace Admin
**Pre-condition:** มี Zyra meeting ที่ยังไม่เริ่ม

**Overview:** Organizer ยกเลิก Zyra meeting ที่ schedule ไว้ ระบบต้อง ไม่**ลบออกจาก Calendar View, ยกเลิก event ใน Google/Outlook, แจ้ง attendees และหยุด alert ที่ยังไม่ส่ง** (ข้อความตามต้นฉบับ — ขัดกับขั้นที่ 8 ดู §6 ข้อ 1)

| Event Source | ยกเลิกใน Zyra ได้ไหม |
|---|---|
| Google / Outlook event (sync เข้ามา) | ❌ Read-only — แสดงปุ่ม "เปิดใน Google/Outlook" เพื่อไปยกเลิกที่ต้นทาง |

**Scenario Steps:**
1. User กด meeting บน Calendar → Event detail popup เปิด
2. กดปุ่ม **"ยกเลิก Meeting"** (สีแดง)
3. Confirmation dialog:
   - "ยกเลิก [ชื่อ meeting]?"
   - แสดงวัน/เวลา + จำนวน attendees ที่จะได้รับแจ้ง
   - Textarea เหตุผล (optional, max 200 ตัวอักษร)
   - Checkbox "แจ้ง attendees ทาง notification" (default: ✅)
4. กด **"ยืนยันยกเลิก"**
5. Meeting status = `cancelled`
6. ระบบยกเลิก event ใน Google/Outlook ที่ sync ไว้ (ถ้ามี)
7. ส่ง in-app notification ให้ attendees และลบ pending alerts ของ meeting นี้
8. Event หายจาก Calendar View ทุกคน + Toast "ยกเลิก [ชื่อ meeting] แล้ว"

**Acceptance Criteria:**

| กลุ่ม | # | AC |
|---|---|---|
| UI / สิทธิ์ | AC-HP05-1 | ปุ่ม "ยกเลิก Meeting" แสดงเฉพาะ Organizer และ Workspace Admin |
| | AC-HP05-2 | Confirmation dialog บังคับทุกครั้ง ป้องกันกดพลาด |
| | AC-HP05-3 | เหตุผล optional แต่ถ้ากรอก จะแสดงใน notification ถึง attendees |
| Calendar / Data | AC-HP05-4 | Event หายจาก Calendar View ทุกคนภายใน **5 วินาที** (WebSocket) |
| | AC-HP05-5 | **Soft cancel**: เก็บ record status = `cancelled` ดูย้อนหลังใน Meeting History พร้อม badge "ยกเลิกแล้ว" |
| | AC-HP05-6 | Audit log: บันทึก `cancelled_by`, `cancelled_at`, `reason` |
| Sync ไป Google / Outlook | AC-HP05-7 | Event ใน Google/Outlook ถูกยกเลิกภายใน **10 วินาที** (ใช้ `sendUpdates=all` ให้ผู้เชิญได้รับอีเมลยกเลิกจาก provider) |
| | AC-HP05-8 | ถ้าเชื่อมต่อทั้ง Google + Outlook: ยกเลิกทั้งสอง |
| | AC-HP05-9 | ถ้าไม่ได้เชื่อมต่อ calendar: ข้ามขั้นตอนนี้ ไม่แสดง error |
| | AC-HP05-10 | ลบ record ใน `synced_events` ที่ผูกกับ meeting นี้ |
| Notification / Alert | AC-HP05-11 | Attendees ทุกคนได้ "❌ [ชื่อ meeting] ถูกยกเลิกโดย [Organizer]" (ยกเว้นผู้ยกเลิกเอง) |
| | AC-HP05-12 | Pending alerts (5 นาทีก่อน / meeting เริ่ม) ถูกลบ ไม่มีใครได้ alert ของ meeting ที่ยกเลิก |
| | AC-HP05-13 | Alert ที่ส่งไปแล้ว: ปุ่ม "Join Now" เปลี่ยนเป็น "ยกเลิกแล้ว" (disabled) |
| | AC-HP05-14 | Attendee offline: notification เก็บ pending ส่งเมื่อ online กลับมา |

**Error Path:**

| # | Case | Expected Behavior |
|---|---|---|
| EP-A | Attendee ทั่วไปพยายามยกเลิก | ไม่เห็นปุ่ม / ถ้า bypass API → `403 NOT_MEETING_ORGANIZER` · มีปุ่ม "ปฏิเสธเข้าร่วม" แทน |
| EP-B | Sync ยกเลิกไป Google/Outlook ล้มเหลว | Zyra state ชนะ ไม่ rollback · Toast "ยกเลิกใน Zyra แล้ว แต่ลบจาก Google Calendar ไม่สำเร็จ — [ลองใหม่]" · Auto-retry 30s → 2m → 5m ถ้ายังไม่สำเร็จ แจ้ง Organizer ให้ลบเอง พร้อม link · ถ้า token หมดอายุให้ใช้ flow เชื่อมต่อใหม่ (CLDI-EP-02) |
| EP-C | กดยกเลิกซ้ำ / 2 admin พร้อมกัน | Server idempotent ไม่ส่ง notification ซ้ำ · ปุ่มยืนยัน disabled หลังกดครั้งแรก · ครั้งที่สอง → `409 ALREADY_CANCELLED` |

**Edge Cases:**

| # | Case | Expected Behavior |
|---|---|---|
| EC-C | Organizer ถูกลบบัญชี | Meeting ที่ยังไม่เริ่มของ user นั้นยกเลิกอัตโนมัติ + แจ้ง attendees |
| EC-D | Event ที่ sync เข้ามาจาก Google/Outlook | Read-only — แสดง "เปิดใน Google Calendar" แทนปุ่มยกเลิก |
| EC-E | Recurring meeting | Out of scope เฟสนี้ (ถ้าทำในอนาคตต้องถาม "ครั้งนี้ / ครั้งนี้และต่อไป / ทั้งหมด") |

**QA Checklist (ตามต้นฉบับ):** Organizer ยกเลิกได้ / Attendee ยกเลิกไม่ได้ · Event หายจาก Calendar ทุกคนภายใน 5 วินาที · Event ใน Google + Outlook ถูกยกเลิก · ไม่มีใครได้ alert ของ meeting ที่ยกเลิกแล้ว · Sync ล้มเหลว: Zyra ยังยกเลิกสำเร็จ และมี retry · กดซ้ำ: ไม่ส่ง notification ซ้ำ · Meeting ที่ live อยู่ยกเลิกไม่ได้ · External event ไม่มีปุ่มยกเลิกใน Zyra

---

### CLDI-HP-06 · เลื่อน Meeting / Event (Reschedule) — ใหม่ 2026-10-27

**Type:** Happy Path (พร้อม Error Path และ Edge Case)
**Persona:** Meeting Organizer (ผู้สร้าง) / Workspace Admin
**Pre-condition:** มี Zyra meeting ที่ยังไม่เริ่ม

**Overview:** Organizer เปลี่ยนวัน/เวลาของ Zyra meeting ระบบต้อง **อัปเดต Calendar View, แก้ event ใน Google/Outlook, แจ้ง attendees และตั้ง alert ใหม่ตามเวลาใหม่**

| Event Source | เลื่อนใน Zyra ได้ไหม |
|---|---|
| Google / Outlook event (sync เข้ามา) | ❌ Read-only — แสดงปุ่ม "เปิดใน Google/Outlook" เพื่อไปแก้ที่ต้นทาง |

**Scenario Steps:**
1. User กด meeting บน Calendar → Event detail popup เปิด
2. กดปุ่ม **"เลื่อน Meeting"**
3. Reschedule dialog:
   - แสดงเวลาเดิม
   - เลือกวันที่ + เวลาเริ่ม + เวลาจบ ใหม่ (แสดงตาม timezone ของ user)
   - Textarea เหตุผล (optional, max 200 ตัวอักษร)
   - Checkbox "แจ้ง attendees ทาง notification" (default: ✅)
   - ระบบตรวจเวลาชน (conflict) กับ meeting อื่นของ user และห้องเดียวกัน แสดง warning ทันทีที่เลือกเวลา
4. กด **"ยืนยันเลื่อน"**
5. ระบบอัปเดต `start_at` / `end_at` ของ meeting
6. อัปเดต event ใน Google/Outlook ที่ sync ไว้ (ถ้ามี)
7. ส่ง notification ให้ attendees และ **ยกเลิก alert เดิม แล้วตั้ง alert ใหม่** ตามเวลาใหม่
8. Event ย้ายตำแหน่งบน Calendar View ทุกคน + Toast "เลื่อน [ชื่อ meeting] เป็น [วัน เวลา ใหม่] แล้ว"

**Acceptance Criteria:**

| กลุ่ม | # | AC |
|---|---|---|
| UI / สิทธิ์ | AC-HP06-1 | ปุ่ม "เลื่อน Meeting" แสดงเฉพาะ Organizer และ Workspace Admin |
| | AC-HP06-2 | เลือกเวลาในอดีตไม่ได้ (disabled) และเวลาจบต้องหลังเวลาเริ่ม |
| | AC-HP06-3 | เวลาแสดง/บันทึกตาม timezone ของ user (เก็บ UTC ใน DB) |
| | AC-HP06-4 | Conflict warning: "คุณมี [ชื่อ meeting อื่น] เวลาเดียวกัน" (เตือนอย่างเดียว ไม่บล็อก) |
| | AC-HP06-5 | ห้อง/ห้องประชุมชนเวลากับ meeting อื่น: แจ้ง "ห้องนี้ถูกใช้งานเวลานี้" และบล็อกการยืนยัน |
| Calendar / Data | AC-HP06-6 | Event ย้ายตำแหน่งบน Calendar View ทุกคนภายใน **5 วินาที** (WebSocket) |
| | AC-HP06-7 | เก็บประวัติเวลาเดิม (`previous_start_at` / `previous_end_at`) และ audit log (`rescheduled_by`, `reason`) |
| | AC-HP06-8 | Event detail popup แสดง badge "เลื่อนแล้ว" พร้อมเวลาเดิม |
| Sync ไป Google / Outlook | AC-HP06-9 | **แก้ event เดิม (update)** ไม่สร้างใหม่ เพื่อไม่ให้ซ้ำ ใช้ `external_event_id` เดิม |
| | AC-HP06-10 | เวลาใน Google/Outlook อัปเดตภายใน **10 วินาที** (ใช้ `sendUpdates=all`) |
| | AC-HP06-11 | ถ้าเชื่อมต่อทั้ง Google + Outlook: อัปเดตทั้งสอง |
| | AC-HP06-12 | ถ้าไม่ได้เชื่อมต่อ calendar: ข้ามขั้นตอนนี้ ไม่แสดง error |
| Notification / Alert | AC-HP06-13 | Attendees ทุกคนได้ "🔄 [ชื่อ meeting] ถูกเลื่อนเป็น [เวลาใหม่]" พร้อมเวลาเดิม + เหตุผล (ยกเว้นผู้เลื่อนเอง) |
| | AC-HP06-14 | Alert เดิมที่ยังไม่ส่งถูกลบ และตั้งใหม่ (5 นาทีก่อน / meeting เริ่ม) ตามเวลาใหม่ |
| | AC-HP06-15 | Alert ที่ส่งไปแล้วตามเวลาเดิม: ปุ่ม "Join Now" เปลี่ยนเป็นแสดงเวลาใหม่/ไป Calendar แทน |
| | AC-HP06-16 | เลื่อนใกล้เวลาเริ่ม (เหลือน้อยกว่า 5 นาที): ใช้กฎเดียวกับ meeting ที่สร้างกระชั้น (ส่ง alert ตามเวลาที่เหลือ) |
| | AC-HP06-17 | Attendee offline: notification เก็บ pending ส่งเมื่อ online กลับมา |

**Error Path:**

| # | Case | Expected Behavior |
|---|---|---|
| EP-A | Attendee ทั่วไปพยายามเลื่อน | ไม่เห็นปุ่ม / ถ้า bypass API → `403 NOT_MEETING_ORGANIZER` |
| EP-B | เลือกเวลาไม่ถูกต้อง (อดีต / จบก่อนเริ่ม) | Error inline ใต้ field ปุ่มยืนยัน disabled / API → `400 INVALID_TIME_RANGE` |
| EP-C | Sync อัปเดตไป Google/Outlook ล้มเหลว | Zyra state ชนะ ไม่ rollback · Toast "เลื่อนใน Zyra แล้ว แต่อัปเดต Google Calendar ไม่สำเร็จ — [ลองใหม่]" · Auto-retry 30s → 2m → 5m ถ้ายังไม่สำเร็จ แจ้ง Organizer ให้แก้เอง พร้อม link |
| EP-D | 2 คนเลื่อนพร้อมกัน | Last-write-wins ด้วย `updated_at` version check · คนที่ส่งทีหลังเห็น "Meeting ถูกแก้ไขแล้ว — [โหลดใหม่]" (`409 MEETING_MODIFIED`) |
| EP-E | Event ใน Google ถูกลบไปแล้วจากฝั่ง Google | อัปเดตไม่สำเร็จ (404) → สร้าง event ใหม่ใน Google และผูก `external_event_id` ใหม่ แจ้ง Organizer 1 ครั้ง |

**Edge Cases:**

| # | Case | Expected Behavior |
|---|---|---|
| EC-A | เลื่อนขณะ meeting กำลัง live | ห้ามเลื่อน (`409 MEETING_IN_PROGRESS`) ปุ่ม disabled พร้อม tooltip |
| EC-B | เลื่อนข้ามวัน / ข้ามสัปดาห์ | Calendar ย้าย event ไปวัน/สัปดาห์ใหม่ ถ้า user ดูวันเดิมอยู่ event หายพร้อม toast "Meeting ถูกเลื่อน" |
| EC-C | Attendee อยู่คนละ timezone | แสดงเวลาใหม่ตาม timezone ของแต่ละคน notification ใช้เวลา local ของผู้รับ |
| EC-D | Attendee มี meeting อื่นชนกับเวลาใหม่ | แสดง conflict ฝั่ง attendee (ใน event detail) ไม่บล็อกการเลื่อน |
| EC-E | เลื่อนหลายครั้งติดกัน | ทุกครั้งส่ง notification ใหม่ แต่ dedupe ภายใน **1 นาที** รวมเป็นเวลาล่าสุดอันเดียว |
| EC-G | Event ที่ sync เข้ามาจาก Google/Outlook | Read-only — แสดง "เปิดใน Google Calendar" แทนปุ่มเลื่อน |
| EC-H | Recurring meeting | Out of scope เฟสนี้ |

(ต้นฉบับไม่มี EC-F)

**QA Checklist (ตามต้นฉบับ):** Organizer เลื่อนได้ / Attendee เลื่อนไม่ได้ · Event ย้ายบน Calendar ทุกคนภายใน 5 วินาที · Google + Outlook: อัปเดต event เดิม ไม่สร้างซ้ำ · Alert เดิมถูกลบ ตั้ง alert ใหม่ตรงเวลาใหม่ · เวลาในอดีต / จบก่อนเริ่ม: เลือกไม่ได้ · Conflict warning แสดงถูกต้อง (user + ห้อง) · Sync ล้มเหลว: Zyra ยังเลื่อนสำเร็จ และมี retry · เลื่อนพร้อมกัน 2 คน: ไม่เกิดข้อมูลทับกัน · Meeting ที่ live อยู่เลื่อนไม่ได้ · Timezone: แต่ละ attendee เห็นเวลา local ถูกต้อง

---

### CLDI-EP-01 · User ปฏิเสธ OAuth Consent

**Trigger:** User กด "ยกเลิก" หรือ "Deny" ใน OAuth popup

**Steps:**
1. Popup ปิด
2. Error banner: "การเชื่อมต่อถูกยกเลิก — กรุณาอนุมัติสิทธิ์เพื่อ sync calendar"
3. ปุ่ม "ลองใหม่"

| # | Acceptance Criteria |
|---|---|
| AC-EP01-1 | ไม่มี token เก็บในระบบ |
| AC-EP01-2 | ไม่มี crash หน้า Settings |
| AC-EP01-3 | "ลองใหม่" เปิด OAuth popup ใหม่ทันที |
| AC-EP01-4 | Banner หายเองหลัง 10 วินาที หรือเมื่อกด X |

---

### CLDI-EP-02 · Token หมดอายุ / Revoked

**Trigger:** User revoke Zyra access ใน Google Account settings โดยตรง

**Steps:**
1. Zyra refresh token → `401 Unauthorized`
2. Mark status = `expired`
3. Notification: "การเชื่อมต่อ Google Calendar หมดอายุ กรุณาเชื่อมต่อใหม่"
4. Settings badge "หมดอายุ" สีเหลือง + ปุ่ม "เชื่อมต่อใหม่"

| # | Acceptance Criteria |
|---|---|
| AC-EP02-1 | Calendar ยังแสดง events เดิม (stale) — ไม่ blank ทันที |
| AC-EP02-2 | Warning icon บน calendar header + tooltip |
| AC-EP02-3 | Notification ส่ง **1 ครั้ง** ไม่ spam |
| AC-EP02-4 | "เชื่อมต่อใหม่" ไม่ต้อง re-enter email |

---

### CLDI-EP-03 · Sync ล้มเหลว (Rate Limit / Server Error)

**Trigger:** API ตอบ `429` หรือ `500`

**Steps:**
1. Retry exponential backoff: **30s → 2m → 5m**
2. หลัง 3 ครั้ง: warning badge บน header
3. Warning: "⚠ Events อาจไม่อัปเดต — [ลองใหม่]"

| # | Acceptance Criteria |
|---|---|
| AC-EP03-1 | Calendar ยังใช้งานได้ด้วย stale data |
| AC-EP03-2 | Zyra meetings ไม่ได้รับผลกระทบ |
| AC-EP03-3 | Warning badge หายหลัง sync สำเร็จ |

---

## 4. Edge Cases (จาก ClickUp parent)

| # | Case | Expected Behavior |
|---|---|---|
| EC-01 | Disconnect แล้ว Reconnect | Sync 30 วันย้อนหลัง + อนาคต, ไม่ duplicate event |
| EC-02 | Google Calendars > 10 อัน | Scrollable list + search, default = Primary เท่านั้น |
| EC-03 | Push Zyra Meeting ล้มเหลว | Meeting ยังสร้างสำเร็จ, toast "ลองใหม่" |
| EC-04 | ลบ Zyra Meeting ที่ Sync แล้ว | Auto-delete Google event ใน 10 วิ, Zyra state ชนะถ้า fail |

---

## 5. สถานะ implement (จาก ClickUp + เอกสารเดิม — ไม่ได้ตรวจโค้ดรอบนี้)

| Scenario | ClickUp | ตามเอกสารเดิม / code-gap ของ CAL-02 |
|---|---|---|
| HP-01 Google connect | waitdeploy-dev | implement แล้ว merge develop (app#634, api#178) — ดู [MeetingCalendarIntegration/progress.md](../MeetingCalendarIntegration/progress.md) |
| HP-02 Outlook | pending | ยังไม่ทำ (ไม่มี Azure directory — [CalendarIntegration/spec.md](../CalendarIntegration/spec.md)) |
| HP-03 สร้าง meeting + push Google | in progress | push Google ได้แล้ว · Outlook ยังไม่ได้ · ไม่มี edit/delete API |
| HP-04 Disconnect | waitdeploy-dev | มี disconnect (เอกสารเดิมบอกยังไม่มี confirm modal — ต้องตรวจซ้ำ) |
| HP-05 Cancel / HP-06 Reschedule | Open | **ยังไม่มีในโค้ด** — ไม่มี status/cancelled_at, ไม่มี update/delete endpoint ([Calendar Display code-gap](<../[Feature] Meeting — Calendar Display/code-gap.md>), [Meeting Alert code-gap](<../[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/code-gap.md>)) |
| EP-01 Deny consent | waitdeploy-dev | ต้องตรวจโค้ด |
| EP-02 / EP-03 | pending | มี `needs_reauth` / `reconnect_required` ฝั่ง API แล้ว (progress รอบ 2) · UI ตาม Figma ยังไม่ครบ |

---

## 6. ข้อสังเกต / จุดขัดกันในต้นทาง

ข้อสังเกตจากการอ่าน ClickUp เท่านั้น — **ยังไม่ใช่ decision** ต้องถาม PM (Moss Pm)

| # | จุด | รายละเอียด | ต้องถาม |
|---|---|---|---|
| 1 | HP-05 ขัดกันเอง: ซ่อนหรือไม่ซ่อน | Overview "ไม่**ลบออกจาก Calendar View**" แต่ขั้น 8 + AC-HP05-4 "Event **หายจาก** Calendar View ทุกคน" + AC-HP05-5 soft cancel ดูใน Meeting History · Figma Meeting Alert ล่าสุดก็ซ่อน (opacity 0) · POC แสดงเป็นสีเทา | ยึด "หายจาก calendar + ดูใน Meeting History" ใช่ไหม · Meeting History คือหน้าไหน (ยังไม่มีใน Figma/ClickUp) |
| 2 | ใครยกเลิก/เลื่อนได้ | HP-05/06: Organizer + **Workspace Admin** · Figma Event detail มี Trash/Edit ให้ทุกคน · โค้ดปัจจุบันไม่มีสิทธิ์ใด ๆ | admin ของ workspace ไหน (owner/manager?) |
| 3 | ปุ่ม "ปฏิเสธเข้าร่วม" (HP-05 EP-A) | ต้องมี RSVP ฝั่ง Zyra — โค้ดไม่มี RSVP · Figma มี Yes/No/Maybe ใน Event detail (CAL-02) | RSVP อยู่ในการ์ดไหน |
| 4 | Cancel ข้อความแจ้ง | HP-05 ❌ "[ชื่อ] ถูกยกเลิกโดย [Organizer]" · Meeting Alert EP-02 "🔄 [ชื่อ] ถูกเลื่อน/ยกเลิกแล้ว" · Figma MA "… has been cancelled" | copy เดียว (ดู MA spec §6, ux §7 A16) |
| 5 | Join Now หลังยกเลิก | HP-05: เปลี่ยนเป็น "ยกเลิกแล้ว" (disabled) · Meeting Alert EP-02: redirect ไป Calendar | ใช้แบบไหน |
| 6 | Reschedule = edit ทั้งฟอร์ม? | HP-06 มี dialog เฉพาะเวลา (+ เหตุผล + checkbox แจ้ง) · Figma มี Edit (ดินสอ) ใน Event detail ที่น่าจะแก้ได้ทุก field · POC ใช้ฟอร์ม Edit event ทั้งชุด | แยก "เลื่อน" กับ "แก้ไข" ไหม |
| 7 | Conflict ห้อง "บล็อก" แต่สร้างใหม่ไม่บล็อก | HP-06 บล็อกเมื่อห้องชน · HP-03 (สร้างใหม่) ไม่ได้พูดถึง conflict · ห้อง "Any available meeting room" ชนได้ไหม | กฎ conflict ตอนสร้าง |
| 8 | Meeting ที่ live | HP-05 QA "Meeting ที่ live อยู่ยกเลิกไม่ได้" แต่ไม่มีใน AC · HP-06 EC-A `409 MEETING_IN_PROGRESS` · ต้องมีนิยาม "live" (เวลาอยู่ระหว่าง start–end? มีคนในห้อง?) — ตรงกับคำถาม "active" ของ CAL-02 | นิยามเดียวสำหรับ 3 การ์ด |
| 9 | ชื่อตาราง `synced_events` | HP-05 อ้าง `synced_events` · โค้ดเก็บ `google_event_id` ในแถว `tb_calendar_meeting` | แค่ชื่อในเอกสาร หรือต้องแยกตาราง (รองรับ Google + Outlook พร้อมกัน) |
| 10 | EC-04 vs HP-05 | EC-04 "ลบ Zyra Meeting" auto-delete Google event · HP-05 "ยกเลิก" ใช้ cancel (`sendUpdates=all`) — ลบกับยกเลิกคือ action เดียวกันไหม | ใช้คำเดียว |
| 11 | HP-01 calendar selector "Optional" | Figma ไม่มี selector ใน Settings (เอกสารเดิม U3) · โค้ดใช้ Calendar list ใน panel แทน | ยืนยันว่าไม่ต้องมี |
| 12 | AC-HP01-5 push meeting เก่าตอน connect | ยังไม่ทำ (progress รอบ 1) | ยังอยู่ใน scope ไหม |

---

### 6.1 ตัดสินแล้ว (ผู้ใช้สั่งในแชท 2026-10-29)

| # | เรื่อง | กติกา | ปิดข้อ |
|---|---|---|---|
| D1 | ลบ / ยกเลิก meeting หรือการจองที่สร้างใน Zyra | **ไม่หายจากปฏิทิน** — ทิ้งไว้เป็นขีดฆ่า (พื้นเทา 10% + แถบ `#8C99A6` + เส้นแดง) ให้ทุกคนเห็น รวมผู้ยกเลิก · popup แสดง "Reason for cancellation" | §6 ข้อ 1 · ขัดกับ AC-HP05-4 ("หายจาก Calendar View ทุกคน") และ Figma HP-05 แถว 1 → ต้องแก้ ClickUp / Figma ตาม |
| D2 | Event ที่มาจาก Google / Outlook | **ลบใน Zyra ไม่ได้** · แสดงไอคอนถังขยะพร้อม tooltip ("ลบได้ที่ Google Calendar เท่านั้น") กดแล้วเปิด app ต้นทาง · ลบที่ต้นทางแล้ว sync กลับมา event หายจาก Zyra + toast "Event deleted" | ตรงกับ HP-05 EC-D และ Figma sticky `7841:498762` / `7858:499484` |
| D0 | กติกากลาง (ใช้กับ CAL-01/02/03) | Figma กับ ClickUp **ขัดกัน → ยึด Figma** · ยกเว้นข้อที่ผู้ใช้ตัดสินไว้ในตารางนี้ (เช่น D1) · ข้อที่มีแค่ใน ClickUp (Figma ไม่ได้วาด) ยังเปิดอยู่ จนกว่าจะตัดสิน — ทำแล้วใช้หน้าตาแบบ Zyra (General modal / token เดิม) | ปิด [ux-ui-plan §10](ux-ui-plan.md#10-figma-vs-clickup--ข้อขัดแย้งที่ต้องถาม) ส่วนใหญ่ → ดู §10.0 |
| D3 | เชื่อมหลายบัญชี | **เชื่อม Google และ Outlook พร้อมกันได้** · events ทั้ง 2 แหล่งแสดงรวมกันใน calendar | ตรงกับ Figma (Integrations มี 2 แถวแยกกัน) |
| D4 | สถานะ เชื่อมแล้ว / ไม่ได้เชื่อม / หมดอายุ | **ตาม Figma** — ไม่มี badge สถานะ · ไม่ได้เชื่อม = ปุ่ม "Connect" · เชื่อมแล้ว = การ์ดบัญชี + ปุ่ม "Disconnect" · หมดอายุ = ไอคอน × + info + ปุ่ม "Reconnect" | ux §10 I4 (ClickUp มี badge → ตัด) |
| D5 | เลือกปฏิทินที่จะ sync | **ทำ** — หลัง OAuth สำเร็จเปิดหน้า "Choose calendars to sync" (เลือกปฏิทินที่จะ sync) · ค่าเริ่มต้น = Primary เท่านั้น (EC-02) · มีช่องค้นหาเมื่อมีปฏิทินเกิน 10 · กด **"Save" (บันทึก)** แล้ว sync ตามที่เลือก · แก้ทีหลังได้จาก Integrations | ux §10 I5 · **Figma ไม่มีแบบ** → POC ใช้ General modal ของ Zyra ([ux §3.5](ux-ui-plan.md#35-choose-calendars-to-sync--ไม่มีใน-figma-poc-ทำแบบ-zyra)) · ต้องให้ designer วาด |
| D6 | Push meeting เดิมตอนเชื่อม | **ทำ (AC-HP01-5)** — เชื่อมสำเร็จแล้วสร้าง Zyra meeting ที่เราเป็นผู้จัด + ยังไม่จบ + ไม่ถูกยกเลิก ลงปฏิทินที่เพิ่งเชื่อม · reconnect หลังหมดอายุไม่ push ซ้ำ | ClickUp HP-01 (Figma ไม่มีหน้าจอ — เป็นงานฝั่ง server) |
| D7 | Disconnect | **ต้องยืนยันก่อน** (General modal ข้อความตาม Figma "Disconnect calendar integration") → events จาก provider นั้น**หายจาก Zyra ทันที** · Zyra meeting ที่เคย push ไปแล้ว**ยังอยู่ใน Google / Outlook** (ไม่ลบตาม) | ux §10 I7 (copy ตาม Figma) · ClickUp HP-04 |
| D8 | ปฏิเสธใน OAuth (EP-01) | **ตาม Figma** — toast แดง "Connection canceled" / "Your calendar wasn't connected." (ยกเลิกการเชื่อมต่อ / ยังไม่ได้เชื่อมปฏิทิน) ไม่มีปุ่มลองใหม่ ผู้ใช้กด Connect ใหม่เอง | ux §10 I8 (ClickUp banner + ลองใหม่ + หายใน 10 วิ → ตัด) |
| D9 | คอลัมน์สถานะยกเลิกของ meeting | **Meeting Alert (CAL-03) เป็นคนเพิ่ม** `tb_calendar_meeting.cancelled_at TIMESTAMPTZ NULL` ใน migration 122 (Alert ทำก่อน) · CAL-01 HP-05 / HP-06 **แค่ set ค่า** + เรียก `NotifyMeetingChanged` ของ Alert — ไม่เพิ่มคอลัมน์เอง | X4 ใน [Meeting Alert task-breakdown §2](<../[Feature] Meeting —  Meeting Alert (5 นาทีก่อน + Meeting เริ่ม)/task-breakdown.md>) |

## 7. ขั้นถัดไป

- ~~ค่า Figma ทุก scenario → [ux-ui-plan.md](ux-ui-plan.md) (รวมส่วนที่ 3 ฟีเจอร์ใช้ร่วมกัน)~~ — เสร็จ 2026-10-29
- **POC** (รวม 3 ฟีเจอร์) — [Calendar Display/poc/index.html](<../[Feature] Meeting — Calendar Display/poc/index.html>) · มี Settings → Integrations, OAuth (จำลอง), Disconnect, EP-01/02/03, Cancel (HP-05 ตาม Figma), Reschedule (HP-06 ตาม ClickUp) และปุ่มเปิดทุกกรณีสิทธิ์ Organiser / Guest / Admin / External · 2026-10-29: ทำ D3–D8 แล้ว (หน้าเลือกปฏิทิน + Save, push meeting เดิม, สถานะ / Disconnect / EP-01 ตาม Figma ทั้งสองโหมด)
- ให้ designer วาด HP-06 Reschedule (ยังไม่มีใน Figma)
- ตอนทำจริง เช็คขอบจอบัง / กดแล้วหาย ตาม [Calendar Display ux-ui-plan §12](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md#12-ขอบจอบัง--กดแล้วหาย--checklist-ตอนทำจริง-2026-10-29>) — โค้ด develop มีบั๊กแล้ว 5 จุด (ฟอร์มล้นล่างเพราะใช้สูง 711 ตายตัว, dropdown ถูกฟอร์มตัด, scrollbar ปิดเมนู, draft หายเงียบ, discard modal โดนทับ)
- ให้ designer วาดหน้า "Choose calendars to sync" (D5) — ตอนนี้ POC ใช้ General modal ของ Zyra
- แก้ ClickUp ให้ตรง D1 / D4 / D7 / D8 (ข้อความใน HP-01, HP-04, HP-05, EP-01 ยังเขียนตามแบบเดิม) — ต้องให้ PM แก้ หรือสั่งในแชทถึงจะแก้ให้
- ตัดสินว่าจะรวมโฟลเดอร์ `MeetingCalendarIntegration/` + `CalendarIntegration/` เข้ามาที่นี่ไหม (ยังไม่ย้าย — รอผู้ใช้สั่ง)
- ส่งคำถาม §6 ให้ PM รวมกับ CAL-02 §5 และ CAL-03 §6
