# User Guide Module — คู่มือการใช้งาน & วิธีทำงาน

**Version:** 1.0 · **Date:** 2026-07-14 · **Status:** Implemented (SC-UG-01 ~ SC-UG-08)
**Refs:** `spec.md` · `technical-design.md` · `task-breakdown.md` · `test-plan.md` · `ux-ui-plan.md`

> เอกสารนี้สรุปว่า **แต่ละฟีเจอร์ทำงานยังไง** และ **ผู้ใช้กดตรงไหนเพื่อทำอะไร**
> โค้ดอยู่ใน 3 services: `zyra-app` (Next.js FE), `zyra-api` (Go REST), `zyra-notifications` (Go email)

---

## 1. ภาพรวม (TL;DR)

| SC | ฟีเจอร์ | ผู้ใช้กดตรงไหน (สั้น ๆ) |
|---|---------|--------------------------|
| UG-01 | **Onboarding — สร้าง Workspace ครั้งแรก** | Login ครั้งแรก → modal เด้งบน lobby → Next จนจบ → Let's Go! |
| UG-02 | **Onboarding — Skip All** | ปุ่ม Skip → ยืนยัน "Yes, Skip" → spotlight ชี้ปุ่ม Create workspace |
| UG-03 | **Onboarding — Resume** | หลุดโดยไม่กด Skip/Let's Go → login ใหม่ modal ขึ้นอีก (เริ่ม 0%) |
| UG-04 | **Help Center — ค้นหาบทความ** | VO sidebar → ปุ่ม "?" → search / เลือก category / อ่าน + Helpful |
| UG-05 | **Help Center — ไม่พบผลลัพธ์** | ค้นหาไม่เจอ → empty state + Popular + "Report issue about…" |
| UG-06 | **Feature Walkthrough** | เข้า VO ที่มี announcement ใหม่ → modal carousel → Let's Go! |
| UG-07 | **Contact Support — Feedback/Bug** | Help Center → Contact Support → เลือก type → กรอก → Send |
| UG-08 | **Contact Support — ติดต่อทีมตรง** | Contact Type = "Contact Support" → Subject + ส่งเข้า support inbox |

---

## 2. สถาปัตยกรรม (ใครรับผิดชอบอะไร)

```
┌──────────────────────────────────────────────────────────┐
│  zyra-app (Next.js, :3000)                                │
│  views/onboarding/*     — onboarding modal + skip + spotlight
│  views/help-center/*    — panel + article + contact form + tickets
│  views/feature-tour/*   — announcement carousel
│  lib/onboarding.ts · lib/help-content.ts · lib/feature-tours.ts
│  lib/api/help.ts · lib/api/support.ts                     │
└──────────────┬───────────────────────────────────────────┘
               │ REST (authFetch / authFetchForm)
               ▼
┌───────────────────────────────┐   ┌──────────────────────────┐
│  zyra-api (:3001/3002 dev)    │   │  zyra-notifications       │
│  PATCH /api/user/me/onboarding│   │  support_ticket_ack (user)│
│  POST/GET /api/user/support/  │──▶│  support_ticket_new(admin)│
│           tickets             │   └──────────────────────────┘
│  POST /api/user/help/articles │
│           /:slug/feedback     │   ┌──────────────────────────┐
│  tb_user.onboarding_status    │   │  Cloudflare R2           │
│  tb_support_ticket (ZYR-{n})  │──▶│  support/{userID}/*.png  │
│  tb_help_article_feedback     │   └──────────────────────────┘
└───────────────────────────────┘
```

- **Onboarding** — content (7 หน้า) เป็น static ใน `lib/onboarding.ts`; state จริงเก็บใน `tb_user.onboarding_status` (`pending`/`skipped`/`completed`)
- **Help articles** — static content ใน `lib/help-content.ts` (v1, ค้นหา client-side); เฉพาะ vote "helpful" ที่ยิง API
- **Feature tours** — data-driven ใน `lib/feature-tours.ts` (`ACTIVE_TOURS` ว่างจนกว่าจะ publish); seen-state ใน localStorage
- **Support tickets** — persist ใน DB + email 2 ฉบับผ่าน zyra-notifications; attachment ขึ้น R2

---

## 3. Onboarding (SC-UG-01/02/03)

**Trigger:** member login ครั้งแรก → landing `/` (Space builder lobby) → ถ้า `onboarding_status='pending'` modal 900×600 เด้งทันที (admin ไม่เห็น)

**Flow:**
- Sidebar 4 tabs: Welcome → Office Setup (3 หน้า) → Invite Team (2 หน้า) → How to Play; progress 0→33→67→100%
- **Next/Back** เดินหน้า/ถอยหลัง; tab ที่จบขึ้น ✓
- หน้าสุดท้าย → **Let's Go!** → Success "You're All Set!" → **Back to Workspace** → `onboarding_status='completed'`
- **Skip** (ทุกหน้า) → confirm modal → **Yes, Skip** → `skipped` + spotlight ชี้ปุ่ม Create workspace (one-shot ต่อ session); **Cancel** → กลับ step เดิม
- **Resume:** ถ้าปิด browser/หลุดโดยไม่ยืนยัน Skip และไม่กด Let's Go → ยัง `pending` → login ครั้งหน้าเด้งอีก (เริ่มที่ Welcome/0%)

**โค้ด:** `views/onboarding/onboarding-modal.tsx` mount ใน `views/user/workspace/hero-user-workspace.tsx` gate ด้วย `getProfile().onboarding_status`

---

## 4. Help Center (SC-UG-04/05)

**เปิด:** ปุ่ม **"?"** (CircleHelp) ใน VO sidebar ซ้าย (เหนือ Settings) → panel docked ขวา 336px

**Flow:**
- **Main:** Recommended cards (เลื่อนนอน) + All Categories (5 หมวด: Getting Started/Virtual Office/Account/Chat/Billing)
- **Search:** พิมพ์ → live filter + highlight ตัวที่ match สีส้ม + category label เขียว
- **Category:** คลิก tile → รายการบทความ + "Search in this category…"
- **Detail:** title + วันที่ + steps (เลขเขียว) + Tips card → **Helpful / Not helpful** → "Thank you for your feedback!" (persist `tb_help_article_feedback`)
- **Empty (UG-05):** ค้นไม่เจอ → "No results found" + Popular Articles + **"Report issue about \"{q}\""** → เปิด Contact form + auto-fill Topic

**เพิ่มบทความใหม่:** แก้ `lib/help-content.ts` → เพิ่ม object ใน `HELP_ARTICLES` (slug ต้อง unique; ตั้ง `recommended`/`popular` ได้)

---

## 5. Feature Walkthrough (SC-UG-06)

**เป็น centered modal carousel** (ไม่ใช่ anchored tooltip)

**Trigger:** เข้า VO แล้วมี tour ใน `ACTIVE_TOURS` ที่ user ยังไม่เคยเห็น → modal 600px เด้ง (STEP n OF m badge, Skip tour, hero, tag/byline, dots, Back/Next) → step สุดท้าย **Let's Go!** → Success → **Back to Office** → mark seen (ไม่ขึ้นซ้ำ)

**ประกาศฟีเจอร์ใหม่:** append `FeatureTour` config ลง `ACTIVE_TOURS` ใน `lib/feature-tours.ts` (ดู `VIRTUAL_PETS_TOUR_EXAMPLE` เป็นแม่แบบ) — bump `id` ทุกครั้งที่เปลี่ยนเนื้อหาเพื่อให้ผู้ใช้เห็นใหม่

---

## 6. Contact Support (SC-UG-07/08)

**เปิด:** Help Center footer ปุ่ม **"Contact Support"** หรือปุ่ม Report ใน empty state

**Contact Type 4 แบบ:**
| Type | Field พิเศษ |
|---|---|
| Report an Issue (Bug Report) | + **Impact on Usage** (3 ระดับ) + Attachment |
| Suggest a Feature | Attachment |
| General Feedback | Attachment |
| **Contact Support** (UG-08) | **Subject** (แทน Topic) + strip "Send to support@zyra.app" + **ไม่มี Attachment** |

**Flow:**
- Info banner แจ้งว่าระบบแนบ URL/Browser/OS ให้อัตโนมัติ (parse จาก userAgent จริง)
- Topic ≤100, Description ≤1,000 (มี counter); Attachment JPG/PNG ≤5MB (เกิน → toast "Upload failed")
- **Send Message** disabled จนกรอก required ครบ → กดแล้วสร้าง ticket `ZYR-{n}` + email 2 ฉบับ + เด้งไป **My Tickets** + success toast
- **My Tickets:** "Your Contact History" — การ์ด ticket code + topic + วันที่ (ของ user ตัวเองเท่านั้น)

**Support inbox:** ตั้ง env `SUPPORT_EMAIL` (ถ้าว่าง = ไม่ส่ง email ให้ inbox แต่ ticket ยังสร้าง); user ได้ ack email เสมอถ้ามี email

---

## 7. Deploy checklist (module นี้)

- [ ] Apply migration **60** (onboarding), **61** (support tickets), **62** (article feedback) บน DB ปลายทาง — ไม่ auto-run
- [ ] ตั้ง env `SUPPORT_EMAIL` บน zyra-api (PM ยืนยัน address จริง — spec Q11)
- [ ] zyra-notifications มี template `support_ticket_ack` + `support_ticket_new` (deploy พร้อมกัน)
- [ ] R2 พร้อม (attachment `support/{userID}/*`)
- [ ] `ACTIVE_TOURS` = [] (ไม่มี announcement ค้าง) เว้นแต่ตั้งใจ publish

---

## 8. ข้อจำกัด v1 / Asset ที่ยังค้าง

- Onboarding hero images + Help empty-state illustration + Feature-tour hero = ใช้ icon/gradient fallback รอ export asset จริงจาก Figma → R2
- Article feedback thank-you state เป็น per-mount (revisit แล้ว footer กลับมาถามใหม่ — vote ยัง upsert ปกติ)
- My Tickets ไม่มี status badge / detail view (design มีแค่ list) — status เก็บใน DB (`open`) ไว้ต่อยอด
- Reply email templates 4 แบบใน Figma = playbook ของทีม support (ไม่ได้ build เข้า product)
- ClickUp status ไม่ถูกแตะ (project rule: read-only) — PM/QA เป็นผู้เปลี่ยนเอง
