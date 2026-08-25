# [Module] User Guide — Spec

**ClickUp:** https://app.clickup.com/t/86d2wzrwb
**Priority:** Normal (SC-UG-01, SC-UG-04 = High)
**Assignee:** Ponlawat Lueakaew
**Status:** In Progress
**Version:** 1.0 · **Date:** 2026-07-14

---

## Overview

Module สำหรับช่วยเหลือและแนะนำผู้ใช้งาน ครอบคลุม 5 Feature (ตาม ClickUp):

- Onboarding Flow (First-time setup)
- Help Center / FAQ
- Tooltip / Walkthrough (New Feature announcement)
- Keyboard Shortcuts Guide *(ไม่มี scenario/design แยก — ดู Open Questions ท้ายเอกสาร)*
- Contact Support / Feedback

**หลักการสำคัญ:** เนื้อหาของ onboarding / help articles ต้องอ้างอิง **flow จริงที่มีอยู่แล้วในโค้ด** (สร้าง workspace, invite member, เดินด้วย WASD ฯลฯ) — ไม่ใช่ flow สมมติ ดู "Existing Flows ที่ต้อง Guide" ด้านล่าง

## Codebase Alignment (v1.0 — 2026-07-14)

ผลสำรวจโค้ดจริงก่อนเขียน spec:

- **ยังไม่มีโค้ด onboarding / tour / walkthrough / help center / FAQ / feedback / support อยู่เลย** ทั้ง zyra-app และ zyra-api (ไม่มี tour library เช่น driver.js/shepherd ติดตั้ง) — ทุกอย่างในเอกสารนี้คือของใหม่ (NEW)
- **Landing หลัง login ของ member คือ `/`** (`views/user/workspace/hero-user-workspace.tsx` — Space builder lobby); admin ถูก redirect ไป `/admin/workspace` → onboarding เป็นของ member เท่านั้น
- **`tb_user` ยังไม่มี onboarding flag** — ต้องเพิ่ม migration ใหม่ (migration ล่าสุด = `59_map_object_fractional_tiles.sql` → เริ่มที่ **60**; migrations ต้อง apply เอง ไม่ auto-run)
- **Email ทั้งหมดออกผ่าน zyra-notifications microservice** (`notify.Client` → `POST /v1/email` + `X-Notification-Key`) — zyra-api ไม่มี SMTP ในตัว; template support ใหม่ต้องเพิ่มทั้งสองฝั่ง
- **File upload ต้องขึ้น Cloudflare R2 เท่านั้น** (`storage.S3Client`) ตาม rule 11
- **UI ใหม่ทั้งหมดใช้ Tailwind-only** (rule 08) + icon จาก `lucide-react` (rule 12); toast ใช้ `zyraToast` (`lib/toast.tsx`); modal ใช้ pattern hand-rolled overlay + panel ตามตัวอย่างใน `views/user/workspace/hero-user-workspace.tsx`
- **Member API ต้องอยู่ใต้ `/api/user/*`** (UserGuard) ตาม rule 15

## Existing Flows ที่ต้อง Guide (อ้างโค้ดจริง)

| Guide topic | Flow จริงในโค้ด |
|---|---|
| สร้าง Workspace | `views/user/space-builder/components/create-workspace-modal.tsx` — step `gallery` (เลือก template + filter capacity/category) → `detail` (ตั้งชื่อ ≤64 chars + Preview) → `done` ("Workspace is ready") |
| Invite Team | เมนู Member / Setting member ใน workspace → ปุ่ม Invite member → email invite หรือ copy link (`workspace_member_service.go` ส่ง invite email อยู่แล้ว) |
| How to Play (เดิน/คุย) | `PixiGameScene` — arrow keys / WASD; เดินเข้าใกล้เพื่อนแล้ว video chat popup (proximity) |
| Mic / Camera | ปุ่ม mic/camera ใน bottom bar ของ VO + browser permission |

---

## Scenario Index

| ID | Scenario | Feature | Type | Priority | ClickUp |
|----|----------|---------|------|----------|---------|
| SC-UG-01 | Onboarding Flow — สร้าง Workspace ครั้งแรก | Onboarding | Happy Path | High | https://app.clickup.com/t/86d2wzt1x |
| SC-UG-02 | Onboarding Flow — ข้าม (Skip All) | Onboarding | Alternate Path | Normal | https://app.clickup.com/t/86d2wzt6b |
| SC-UG-03 | Onboarding Flow — กลับมาทำต่อ (Resume) | Onboarding | Alternate Path | Normal | https://app.clickup.com/t/86d2wztbf |
| SC-UG-04 | Help Center — เปิดและค้นหาบทความ | Help Center | Happy Path | High | https://app.clickup.com/t/86d2wztgd |
| SC-UG-05 | Help Center — ไม่พบบทความที่ค้นหา | Help Center | Alternate Path | Normal | https://app.clickup.com/t/86d2wztkk |
| SC-UG-06 | Tooltip / Walkthrough — แนะนำ Feature ใหม่ | Walkthrough | Happy Path | Normal | https://app.clickup.com/t/86d2wzttr |
| SC-UG-07 | Contact Support — ส่ง Feedback / Bug Report | Support | Happy Path | Normal | https://app.clickup.com/t/86d2wzuk1 |
| SC-UG-08 | Contact Support — ติดต่อทีม Support โดยตรง | Support | Happy Path | Normal | https://app.clickup.com/t/86d2wzutf |

---

## SC-UG-01 · Onboarding Flow — สร้าง Workspace ครั้งแรก

**Type:** Happy Path · **Persona:** Member (first login) · **Figma:** node `2286:623285`
**Pre-condition:** สมัคร + verify แล้ว, login สำเร็จครั้งแรก, `onboarding_status = 'pending'`, role = member

**Flow:**
1. Login สำเร็จครั้งแรก → เข้า `/` (Space builder lobby) → **onboarding modal (900×600) ขึ้นทันที** บน overlay ดำ 50%
2. Modal มี sidebar 4 tabs: **Welcome → Office Setup (3 หน้า) → Invite Team (2 หน้า) → How to Play (1 หน้า)** พร้อม Overall Progress 0→33→67→100%
3. กด **Next** เดินหน้าไปทีละหน้า (มี Back ย้อนกลับ ยกเว้นหน้า Welcome); tab ที่จบแล้วขึ้น ✓
4. หน้าสุดท้าย (How to Play) ปุ่มเป็น **"Let's Go!"** → แสดง **Success Modal** "You're All Set!"
5. กด **"Back to Workspace"** → ปิด onboarding, กลับ lobby, บันทึก `onboarding_status = 'completed'`

**Acceptance Criteria:**
- [ ] Modal ขึ้นอัตโนมัติเมื่อ member ที่ `onboarding_status='pending'` เข้าหน้า `/` (ทันทีหลัง login ครั้งแรก)
- [ ] เนื้อหา 7 หน้า + Success modal ตรง copy ใน Figma ทุกคำ (ดู `ux-ui-plan.md`)
- [ ] Welcome title ใส่ชื่อผู้ใช้จริง: `Welcome to Zyra, {display name}!`
- [ ] Progress bar และ ✓ ต่อ tab อัปเดตถูกต้อง (0/33/67/100)
- [ ] "Let's Go!" → Success modal → "Back to Workspace" ปิดและ **persist** `completed` (ไม่ขึ้นอีกใน login ถัดไป)
- [ ] Admin ไม่เห็น onboarding
- [ ] มี transition animation ระหว่างหน้า (fade/slide — reference ใน sticky)

## SC-UG-02 · Onboarding Flow — ข้าม (Skip All)

**Type:** Alternate Path · **Figma:** node `2329:27226`
**Pre-condition:** onboarding modal กำลังแสดง (step ใดก็ได้ — ปุ่ม Skip มีทุกหน้า)

**Flow:**
1. กด **Skip** (มุมขวาบนของ hero image) → **confirmation modal** ขึ้นบน overlay ชั้นที่สอง (tutorial modal ยัง mount อยู่ข้างใต้)
2. Confirmation: icon warning เหลือง, title "Skip the onboarding tutorial?", subtitle "You can always configure settings from the Profile menu"
3. กด **Cancel** → ปิด confirmation, กลับ tutorial ที่ step เดิม
4. กด **Yes, Skip** → ปิด onboarding ทั้งหมด, `onboarding_status = 'skipped'`, เข้า Space Builder ทันที
5. หลัง skip: แสดง **spotlight overlay** (เจาะรูรอบปุ่ม "Create workspace" มุมขวาบน) + coach-mark tooltip ขาว **"Click to start creating a workspace."** (one-shot)

**Acceptance Criteria:**
- [ ] Skip จาก step ไหนก็ได้ → confirmation เสมอ
- [ ] Cancel กลับ step เดิม (state ไม่หาย)
- [ ] Yes, Skip → persist `skipped` (login ถัดไปไม่ขึ้น modal อีก)
- [ ] Spotlight + tooltip แสดงครั้งเดียวหลัง Yes, Skip; คลิกปุ่ม Create workspace (หรือคลิกที่อื่น — ดู open question) แล้วหายไป ไม่แสดงซ้ำ
- [ ] ปิด browser ระหว่าง confirmation ค้าง = ยังไม่ตัดสินใจ → login หน้าขึ้น modal อีก (ดู SC-UG-03)

## SC-UG-03 · Onboarding Flow — กลับมาทำต่อ (Resume)

**Type:** Alternate Path · **Figma:** node `2329:30521`
**Pre-condition:** user เคยเห็น onboarding แต่หลุดออกไปโดยไม่กด "Yes, Skip" และไม่กด "Let's Go!" (ปิด browser / network หลุด / navigate ออก)

**Rule (revised 2026-07-16 — เดิมเป็น "restart ที่ Welcome/0%" จาก sticky note, เปลี่ยนตาม issue report):** สถานะ onboarding (`onboarding_status`) ยังสิ้นสุดด้วย 2 action เดิมเท่านั้น — ยืนยัน **Yes, Skip** (→ `skipped`) หรือกด **Let's Go!** จนจบ (→ `completed`) แต่ระหว่างที่ยัง `pending`, **step ปัจจุบัน (`onboarding_page_index`) ถูก persist ทุกครั้งที่กด Next/Back** — login ใหม่จึง resume ที่ step เดิม ไม่ใช่ restart

**Flow:**
1. User หลุดออกกลาง onboarding (เช่น ปิด tab ที่ Office Setup 2/3)
2. Login ครั้งถัดไป → เข้า `/` → onboarding modal ขึ้นอีกครั้ง **ที่ step เดิมที่ค้างไว้** (Office Setup 2/3, ไม่ใช่ Welcome)

**Acceptance Criteria:**
- [ ] กด Next ไปกี่หน้าก็ตาม (ไม่จบ) ไม่นับเป็น terminal action — `onboarding_status` ยัง `pending` แต่ `onboarding_page_index` อัปเดตทุกครั้ง
- [ ] Login ใหม่ระหว่าง `pending` → modal ขึ้นที่ step ล่าสุดที่บันทึกไว้เสมอ
- [ ] `skipped`/`completed` แล้ว → onboarding_page_index reset กลับ 0 (กัน resume เพี้ยนถ้า admin reset กลับ pending ทาง SQL เพื่อ QA)
- [ ] `skipped` / `completed` แล้ว → ไม่ขึ้นอีก

## SC-UG-04 · Help Center — เปิดและค้นหาบทความ

**Type:** Happy Path · **Figma:** `2144:22099` (V.1), `2207:145327` (V.2 มีรูป — authoritative)
**Pre-condition:** user อยู่ใน Virtual Office (`/workspace/[id]/play`)

**Flow:**
1. กดปุ่ม **"?"** ใน VO sidebar ซ้าย (เหนือปุ่ม Settings) → **Help Center panel** เปิด docked ขวา 336px (pattern เดียวกับ chat/member panel — ไม่ใช่ modal)
2. หน้า main: search input, "Recommended for you" (การ์ดเลื่อนนอน), "All Categories" grid 5 หมวด (Getting Started / Virtual Office / Account / Chat / Billing), footer "Need more help?" + Contact Support
3. **Search:** พิมพ์ → ผลค้นหาแบบ live พร้อม **highlight ตัวอักษรที่ match สีส้ม** (`#FF8000` บนพื้น 20%)
4. **Category:** คลิก tile → รายการบทความในหมวด (มี thumbnail 80×80 + วันที่อัปเดต) + ค้นหาภายในหมวดได้ ("Search in this category...")
5. **Detail:** คลิกบทความ → hero image 304×140, title, วันที่, body card (ขั้นตอนเป็นเลขเขียว), Tips card
6. **Feedback:** "Was this article helpful?" → Helpful / Not helpful → เปลี่ยน state เป็น ✓ "Thank you for your feedback!"

**Acceptance Criteria:**
- [ ] "?" toggle panel; X ปิด; back arrow ย้อนหน้าใน panel
- [ ] Search live-filter + highlight substring ที่ match; ค้นหาภายใน category กรองเฉพาะหมวดนั้น
- [ ] บทความชุดแรก (seed content) ครอบคลุม flow จริง: mic/camera, movement, screen share, create workspace, invite ฯลฯ
- [ ] Feedback กดได้ครั้งเดียวต่อบทความ → thank-you state
- [ ] Tabs Articles / My Tickets สลับได้ (My Tickets → SC-UG-07)

## SC-UG-05 · Help Center — ไม่พบบทความที่ค้นหา

**Type:** Alternate Path · **Figma:** node `2156:558556`

**Flow:**
1. ค้นหาแล้วไม่มีผลลัพธ์ (เช่น "hh") → **empty state**: illustration กล่อง 100×100, "No results found", "No content found for \"hh\""
2. แสดง **Popular Articles** card (ลิงก์เขียว 3 บทความ) — คลิกเปิด Detail ได้
3. ปุ่ม **"Report issue about \"hh\""** → เด้งไปหน้า **Contact Support / Report Issue** พร้อม **Topic auto-fill** = `Cannot find "hh" in Articles` (counter นับตามจริง เช่น 27/100)

**Acceptance Criteria:**
- [ ] 0 ผลลัพธ์ → empty state แทนที่รายการ (query คงอยู่ในช่อง search)
- [ ] Report button embed query ปัจจุบันใน label
- [ ] Auto-fill template `Cannot find "{query}" in Articles` (query ยาวเกิน → truncate ให้ Topic ≤ 100)
- [ ] Popular Articles + footer Contact Support ยังใช้งานได้

## SC-UG-06 · Tooltip / Walkthrough — แนะนำ Feature ใหม่

**Type:** Happy Path · **Figma:** node `2207:238216` (ตัวอย่างเนื้อหา: Virtual Pets)

> ตาม design จริงเป็น **centered announcement-modal carousel** (ไม่มี anchored pointer/spotlight) — 5 steps + success modal, แสดงบน VO

**Flow:**
1. User เข้า VO ครั้งแรกหลังมี feature announcement ใหม่ที่ยังไม่เคยเห็น → modal ขึ้น (STEP 1 OF 5)
2. **Next / Back** เลื่อน step, pagination dots ตาม; **Skip tour** ปิดได้ทุก step
3. Step 5 ปุ่มเป็น **"Let's Go!"** → **Success modal** "You're all set!" → **"Back to Office"** ปิด
4. เห็นแล้ว (skip หรือจบ) → ไม่ขึ้นซ้ำสำหรับ announcement เดิม

**Acceptance Criteria:**
- [ ] Framework เป็น data-driven: announcement 1 ตัว = config (id, tag, steps[title, body, image], date) — เพิ่มตัวใหม่ได้โดยไม่แก้ logic
- [ ] Seen-state persist ต่อ user ต่อ announcement id
- [ ] Skip tour / Back to Office ปิดและ mark seen
- [ ] Virtual Pets เป็นเพียง**ตัวอย่างเนื้อหา** — ห้าม hardcode

## SC-UG-07 · Contact Support — ส่ง Feedback / Bug Report

**Type:** Happy Path · **Figma:** node `2156:568237`
**Entry:** Help Center panel → ปุ่ม "Contact Support" (footer) หรือ "Report issue about..." (SC-UG-05)

**Flow:**
1. ฟอร์ม "Contact Support / Report Issue" ใน panel เดิม: info banner (auto-attach URL/Browser/OS), **Contact Type*** dropdown 4 options:
   `Report an Issue (Bug Report)` / `Suggest a Feature (Feature Request)` / `General Feedback` / `Contact Support`
2. Bug Report เพิ่ม field **Impact on Usage***: `Cannot use at all (e.g., white screen)` / `Partially usable (e.g., no mic)` / `Annoyance / Visual Glitch`
3. **Topic*** (≤100) + **Description*** (≤1,000) — placeholder เปลี่ยนตาม type
4. **Attachments (Optional)**: JPG/PNG ≤ 5MB → uploaded card (filename + size + Completed + trash); เกิน 5MB → error toast "Upload failed / The selected file exceeds the 5 MB size limit."
5. **Send Message** disabled จนกรอก required ครบ → กดแล้ว: สร้าง ticket, ส่ง email (ack ถึง user + new-ticket ถึง support), เด้งไป **My Tickets tab** + success toast `Message sent! Ticket ID #ZYR-xxxx / We'll review and respond within 24 hours.`
6. **My Tickets** ("Your Contact History"): การ์ด ticket ID + title + วันที่

**Acceptance Criteria:**
- [ ] Validation ฝั่ง client + server: required fields, Topic ≤100, Description ≤1,000, ไฟล์ JPG/PNG ≤5MB
- [ ] Attachment ขึ้น R2 เท่านั้น (`support/{userID}/{uuid}.png`) — ห้ามลง disk
- [ ] Ticket persist ใน DB พร้อม running number → code `ZYR-{n}`
- [ ] Metadata (page URL, browser, OS) เก็บอัตโนมัติจาก client
- [ ] Email 2 ฉบับออกผ่าน zyra-notifications (async, ไม่ block response)
- [ ] My Tickets แสดง ticket ของ user ตัวเองเท่านั้น

## SC-UG-08 · Contact Support — ติดต่อทีม Support โดยตรง

**Type:** Happy Path · **Figma:** node `2186:16834`

> จาก sticky "แบบที่ 1 รวมกับ Contact type เลย" — **ไม่ใช่หน้าแยก**: เป็น Contact Type ตัวที่ 4 ของฟอร์ม SC-UG-07

**Flow (ความต่างจาก SC-UG-07):**
1. เลือก Contact Type = **Contact Support** → ฟอร์มเปลี่ยน: แสดง strip read-only **"Send to support@zyra.app"** (แทน Impact), field แรกใช้ label **Subject*** (ไม่ใช่ Topic), **ไม่มี Attachments**
2. Send Message → เหมือนเดิม: ticket + emails + My Tickets + success toast

**Email templates (zyra-notifications ใหม่):**
- **User ack (auto):** subject `We've received your message! (Ticket #ZYR-xxxx)` + summary box (Topic/Details) + CTA "Visit Help Center"
- **Admin new-ticket:** subject `[New Ticket] {Topic} - {User Name} (Ticket #ZYR-xxxx)` + detail box (Topic / Impact ถ้ามี / Details / Time Submitted / OS-Browser / Attachment) + CTA "Reply to User" (mailto user)
- Reply templates 4 แบบ ([Resolved], Feature thanks, Feedback thanks, Received) = **support playbook copy** — ไม่ build ใน product (ดู open question)

**Acceptance Criteria:**
- [ ] Type = Contact Support: Subject label, send-to strip, ไม่มี Impact/Attachments
- [ ] Admin email มี/ไม่มีบรรทัด Impact ตาม type
- [ ] Email address จริงมาจาก env (`SUPPORT_EMAIL`) — ไม่ hardcode `support@zyra.app`

---

## Open Questions (ต้องถาม PM/Designer ก่อน implement ส่วนที่เกี่ยว)

| # | คำถาม | กระทบ | คำแนะนำเริ่มต้น |
|---|---|---|---|
| Q1 | Sidebar tabs ใน onboarding คลิกข้ามได้ไหม? (copy บอก "explore at your own pace" แต่ไม่มี state click ใน design) | UG-01 | v1: คลิกไม่ได้ — เดินหน้าด้วย Next เท่านั้น |
| Q2 | Progress 0/33/67/100 นับตอนไหน (เข้า tab หรือจบ tab)? | UG-01 | นับเมื่อ**จบ** tab (ตรงกับ ✓) |
| Q3 | "Back to Workspace" ไปที่ไหน — lobby หรือ workspace ที่เพิ่งสร้าง? | UG-01 | ปิด modal อยู่ที่ lobby เดิม |
| Q4 | Spotlight tooltip หลัง skip: dismiss ด้วยอะไร? แสดงเฉพาะ skip จาก Welcome หรือทุก step? | UG-02 | คลิกที่ใดก็ได้ dismiss; แสดงทุกกรณี skip; one-shot |
| Q5 | Subtitle "configure settings from the Profile menu" — ต้องมีเมนู re-open tutorial ใน Profile ไหม? (ไม่มี design) | UG-02 | เพิ่ม menu item "Getting Started Guide" ใน app-navbar dropdown (nice-to-have, phase หลัง) |
| Q6 | Resume = restart ที่ 0% ใช่ไหม (design) หรือต้อง resume กลาง step (ชื่อ scenario)? | UG-03 | ตาม design: restart 0% |
| Q7 | บทความ Help Center มาจากไหน — admin CMS หรือ static? ทุก date ใน design เป็น placeholder | UG-04 | v1: static content ใน frontend (`lib/help-content.ts`); ออกแบบ type ให้ย้ายไป API ได้ภายหลัง |
| Q8 | Recommended / Popular Articles ใช้ logic อะไร? | UG-04/05 | v1: curated list ใน content config |
| Q9 | Feedback (Helpful/Not helpful) ต้อง persist ฝั่ง server ไหม? | UG-04 | v1: persist (นับสถิติได้); ต่อ user ต่อบทความ ครั้งเดียว |
| Q10 | Trigger ของ feature walkthrough (UG-06) — ผูก release / feature flag / admin สร้าง announcement? | UG-06 | v1: config ใน frontend + seen ใน localStorage; server-driven เป็น phase หลัง |
| Q11 | Support email จริง: design มี 3 ค่า (`support@zyra.app`, `noreply@zyra.com`, `Zyra@mail.com`) | UG-07/08 | ใช้ env `SUPPORT_EMAIL` + `EMAIL_SEND_FROM`; ให้ PM ยืนยัน address |
| Q12 | Reply templates 4 แบบ เป็น feature ใน product หรือ playbook ของทีม support? | UG-08 | Playbook — เก็บเป็น doc ไม่ build |
| Q13 | **Keyboard Shortcuts Guide** อยู่ใน overview ของ module แต่ไม่มี scenario/design — scope ไหน? (ตาราง ClickUp พิมพ์ Feature ของ SC-UG-07/08 เป็น "Tooltip"/"Shortcuts" ซึ่งน่าจะ mislabel) | module | รอ design; ไม่อยู่ใน breakdown นี้ |
| Q14 | Ticket มี status (open/resolved) + detail view ไหม? design มีแค่ list card | UG-07 | v1: เก็บ status ใน DB (default `open`) แต่ UI แสดง list อย่างเดียว |
| Q15 | My Tickets empty state ไม่มี design | UG-07 | ใช้ pattern empty state เดียวกับ UG-05 (illustration + ข้อความ) |
| Q16 | รูป reference login ใน SC-UG-03 เป็นลิงก์เสีย (Google 404) | UG-03 | แจ้ง designer แนบใหม่ |
