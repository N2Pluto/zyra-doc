# Meeting Alert — อ่านตรงไหนก่อน (สำหรับ dev ที่รับงานนี้)

> **สถานะ (2026-10-29):** Ten แยก SC-MTG-CAL-03 Meeting Alert ให้ทำ**ก่อน** Calendar Integration (CAL-01) / Calendar Display (CAL-02) · **รอบ 1 implement แล้ว ยังไม่ commit / ยังไม่ live-test → [progress.md](progress.md)**
> **เอกสารนี้:** ลำดับการอ่าน — อ่านส่วนไหน / ข้ามส่วนไหน · เนื้อหาจริงอยู่ในไฟล์ที่ลิงก์ ไม่ได้คัดลอกมา
> **ClickUp:** [86d3nbdqn](https://app.clickup.com/t/86d3nbdqn) · **Figma:** file `Map8gX0L2hk7HnkaFRfhtj` page "Meeting Alert" (node ต่อ scenario อยู่ใน [spec §2](spec.md))

---

## ลำดับการอ่าน (ประมาณ 1.5–2 ชม.)

| ลำดับ | ไฟล์ | อ่านส่วนไหน | ได้อะไร | เวลา |
|---|---|---|---|---|
| **1** | [task-breakdown.md](task-breakdown.md) | **ทั้งไฟล์** — สำคัญสุด §0, §2, §3, §5 | ขอบเขต · ส่วนไหนเป็นของเรา / ห้ามแตะ · ข้อที่ตัดสินแล้ว + คำถามที่ยังเปิด (มีค่าแนะนำ) · ร่าง DB / API · ลำดับ PR · test · metric | 30 นาที |
| **2** | [spec.md](spec.md) | §1 Overview · §3 Scenarios (AC ของ MA-HP-01…MA-EP-03) · §4 Edge cases · §5 Business rules | requirement ต้นทาง — ใช้เป็น checklist ตอนเทส | 20 นาที |
| **3** | [ux-ui-plan.md](ux-ui-plan.md) | §2 Toast (ทุกข้อ — §2.4 คือ copy + สีของ 5 แบบ) · §3 Bell + badge · §4 Notification panel (§4.5–4.7 การ์ด meeting) · §5 ผลต่อ Calendar | ค่า Figma ที่ต้องทำให้ตรง (px, สี, copy) — §1 Tokens ใช้เปิดดูตอนเขียน | 25 นาที |
| **4** | [code-gap.md](code-gap.md) | **§B Building blocks** (file:line ของที่ใช้ต่อได้) · §C แค่ C.2, C.3, C.6, C.13, C.14 · §A เปิดดูราย AC ตอนทำ PR นั้น | โค้ดเดิมอยู่ไหน + กับดักที่เคยพัง | 20 นาที |
| **5** | [POC](<../[Feature] Meeting — Calendar Display/poc/index.html>) | แผงควบคุมด้านบน → แถว **"ส่ง Meeting Alert"** (5 นาที / เริ่ม / missed / ยกเลิก / เลื่อน — กดซ้ำ = ถูก dedupe) · กด bell ใน sidebar ดู panel | เห็นพฤติกรรมจริงก่อนเขียน — ค่าใน POC ยึด Figma | 10 นาที |

เปิด POC: ไฟล์ HTML ไฟล์เดียว เปิดใน browser ได้เลย (ต้องต่อเน็ตเพื่อโหลด icon / font) หรือเปิด artifact ของทีม https://claude.ai/artifact/1DWr6mXVQadovGAGRaQsNc (แชร์ในองค์กร)

## อ่านเฉพาะบางส่วน (เพราะใช้ร่วมกับฟีเจอร์อื่น)

| ไฟล์ | ส่วน | ทำไม |
|---|---|---|
| [CAL-01 spec](<../[Feature] Meeting — Calendar Integration/spec.md>) | §6.1 แค่ **D0** (ขัดกันให้ยึด Figma), **D1** (ยกเลิกแล้วยังอยู่เป็นขีดฆ่า), **D9** (เราเพิ่มคอลัมน์ `cancelled_at`) | 3 ข้อนี้กระทบงานเรา ที่เหลือเป็นเรื่อง Google / Outlook |
| [CAL-01 ux-ui-plan](<../[Feature] Meeting — Calendar Integration/ux-ui-plan.md>) | §1 ตาราง "ส่วนที่ 3 ฟีเจอร์ใช้ร่วมกัน" — แถว Toast, Sidebar + Bell, Notification panel, Event detail popup | รู้ว่าชิ้นไหนใช้ร่วมกัน ห้ามทำซ้ำ (rule 09) |
| [Calendar Display ux-ui-plan](<../[Feature] Meeting — Calendar Display/ux-ui-plan.md>) | §8 Event detail popup (**อ่านอย่างเดียว ใช้ของเดิม ไม่แก้**) · §12 แค่แถว **Toast** ใน §12.2 + C1, C6 ใน §12.3 + §12.4 ข้อ 7 | ปุ่ม "Open Calendar" เปิด popup นี้ · toast ซ้อนหลายใบต้องไม่ล้นจอ 720 |
| [Calendar Display spec](<../[Feature] Meeting — Calendar Display/spec.md>) | §7 ตาราง X1–X8 | ที่มาของการแบ่งเจ้าของใน task-breakdown §2 (อ่านแค่ถ้าสงสัย) |

## ข้ามได้

| ไฟล์ / ส่วน | เหตุผล |
|---|---|
| spec §6, §7, §8 · ux-ui-plan §7 | ข้อขัดแย้ง / สรุปเก่า — ตัดสินแล้วใน task-breakdown §3 |
| code-gap §D, §E | ร่างแรก — ฉบับที่ใช้คือ task-breakdown §4, §5 |
| ux-ui-plan §6 Display panel ในห้อง | ไม่ใช่ scope (UI meeting เดิม) |
| ส่วนอื่นของ CAL-01 / CAL-02 · โฟลเดอร์ `MeetingCalendarIntegration/`, `CalendarIntegration/` | เป็นงาน Google / Outlook / หน้า Calendar — ไม่เกี่ยวกับ alert |

## Rule ของ repo ที่ต้องรู้ก่อนเขียนโค้ด (`.claude/rules/`)

| Rule | เรื่องที่เกี่ยวกับงานนี้ |
|---|---|
| 17 git branch workflow | แตก `feat/*` จาก `develop` เท่านั้น · ห้าม push เข้า `develop` / `main` ตรง |
| 02 design · 03 develop | Handler → Service · `model.APIResponse` · wrap error · `defer tx.Rollback` · Prettier ไม่มี `;` |
| 15 member API | ใช้ `/api/user/notifications*` เท่านั้น ห้าม `/api/admin/*` |
| 04 test | Go table-driven + testify · Vitest `vi.mock` · ห้าม call API จริง |
| 08 Tailwind only · 09 reuse · 12 lucide · 10 Figma fidelity | toast ใช้ `zyraToast` เดิม (เพิ่ม prop ไม่ fork) · icon `Video` จาก lucide · ค่า px / สีตาม ux-ui-plan |
| 18 before / after | feature ใหญ่ → ตาราง metric ใน task-breakdown §7 ต้องมีตัวเลขจริงก่อนบอกว่าเสร็จ |
| 19 Thai translation | copy ใหม่ต้องมีทั้ง `messages/en.json` และ `th.json` |
| 16 documentation | บันทึกความคืบหน้าใน `progress.md` ในโฟลเดอร์นี้ (entry ใหม่ไว้บนสุด) |

## ก่อนเริ่มเขียนโค้ด — ต้องถาม Ten

- **Q3 (task-breakdown §3.2):** meeting ถูกเลื่อนแล้วส่ง alert 5 นาที / เริ่ม ใหม่ตามเวลาใหม่ไหม — **ต้องตอบก่อน PR แรก (API-1)** เพราะเปลี่ยน UNIQUE key ของตาราง
- คำถามอื่นใน §3.2 (Q1–Q13) มีค่าแนะนำแล้ว ใช้ไปก่อนได้ — ถ้าคำตอบต่างค่อยแก้

## ระวังชนกับงานที่กำลังทำ

- branch `fix/calendar-popup-edges` (zyra-app) แก้ `vo-calendar.tsx`, `calendar-schedule-event.tsx`, `calendar-parts.tsx`, `hero-virtual-office.tsx` — commit แล้ว ยังไม่ push / ยังไม่มี PR (2026-10-29) · PR ของเราที่แตะ `vo-calendar.tsx` / `hero-virtual-office.tsx` (APP-2) ให้รอ branch นั้น merge ก่อน หรือ rebase ก่อนเปิด PR (task-breakdown §2.1)
