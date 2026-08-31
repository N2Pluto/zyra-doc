# plan/ — แผนและ spec ต่อฟีเจอร์

หนึ่งโฟลเดอร์ = หนึ่งฟีเจอร์/โมดูล · ชื่อโฟลเดอร์เป็น **PascalCase**

> **สถานะในตารางนี้คือสถานะที่เขียนอยู่ในเอกสารนั้น ไม่ใช่ผลตรวจโค้ด**
> ถ้าพบว่าไม่ตรงกับของจริง ให้แก้ที่ blockquote หัวเอกสารนั้นก่อน แล้วค่อยแก้บรรทัดในตารางนี้ตาม

| Feature | เนื้อหา | สถานะตามเอกสาร |
|---|---|---|
| [Announcement](Announcement/) | SC-ANC-07 patch-note announcement (กลไก `/api/version` + `NEXT_PUBLIC_BUILD_ID`) | design + runbook · 2026-08-27 · `feat/sc-anc-07-patch-notes` |
| [AvatarManagement](AvatarManagement/) | SC-AV-01 — แก้ตัวเลข "จำนวนผู้ใช้งาน" ใน Avatar list | รอ review ก่อน implement · 2026-07-17 |
| [Chat](Chat/) | โมดูล Chat ครบชุด SC-CHAT-01 ~ 12 (spec, technical design, task breakdown, test plan, UX/UI, Figma nodes, usage guide) | Implemented · 2026-06-29 |
| [HelpCenterSupportEmails](HelpCenterSupportEmails/) | Support email — field fixes + admin reply (zyra-api, zyra-notifications, zyra-app) | approved — พร้อม implement |
| [PetManagement](PetManagement/) | โมดูล Pet (admin) — spec, DB schema + API contract, UX/UI, decision log, work split, progress | Admin (library/API/XP config) implemented บน `develop` + ตรวจโค้ดแล้ว 2026-08-31 · SC-PM-05 (วาง pet ในห้อง) ยังไม่เริ่ม · `NEXT_PUBLIC_PET` ยังปิด |
| [Private-Zone-Claim](Private-Zone-Claim/) | จอง private zone ใน VO + in-place zone editor บน Pixi scene | plan.md: ClickUp `pending` |
| [Real-time-Engine](Real-time-Engine/) | SC-RTE-01 ~ 09 — position sync, room state, mute/camera, screen share + `technical-design/00–09`, capacity, tick overhaul | in progress · tick overhaul: Phase 0+A implemented (flag off by default) |
| [Refactor-ZyraApp](Refactor-ZyraApp/) | จัดโครงสร้าง zyra-app / ลดขนาดไฟล์ยักษ์ แบบ no-behavior-change | Phase 1 analysis · 2026-08-06 · `refactor/project-structure` |
| [UserGuide](UserGuide/) | SC-UG-01 ~ 08 — onboarding / user guide | Implemented · 2026-07-14 |
| [UserManagement](UserManagement/) | SC-UM-01 ~ 16 — admin user management + capacity/scaling | 16/16 E2E-verified (Phase 0, 2, 3, 5) · 2026-07-15 |
| [VirtualOffice](VirtualOffice/) | โมดูล VO หลัก — spec, technical design, task breakdown, test plan, UX/UI + scaling next steps + meeting bug batch | spec: In Progress · meeting-bugs-2026-08-07: planning only |
| [VO-Idle-Away](VO-Idle-Away/) | idle → Away → auto-return → auto-leave | Planning only — ยังไม่ implement |
| [VO-Movement-V2](VO-Movement-V2/) | soak checklist ก่อนเปิด `VO_MOVEMENT_V2` เป็น default บน prod | staging soak (PR8) ก่อน default-on (PR9) |

---

## เปิดฟีเจอร์ใหม่ — สร้างไฟล์ชุดนี้

```
plan/<FeatureName>/
├── spec.md              # What / Acceptance criteria / ClickUp link / scenario IDs (SC-XXX-nn)
├── technical-design.md  # API contract, DB impact + migration SQL, flow
├── task-breakdown.md    # แบ่งเป็น task ที่จบได้ใน 1 PR
├── test-plan.md         # case ต่อ scenario
├── ux-ui-plan.md        # spec จาก Figma (exact px / hex — ห้ามเดา)
└── progress.md          # log ว่าใครทำอะไรถึงไหน — ต่อท้ายทุกครั้งที่หยุดงาน/ส่งต่อ
```

ไม่ต้องครบทั้ง 6 ไฟล์ตั้งแต่วันแรก — เริ่มจาก `spec.md` ก่อนเสมอ แล้วเพิ่มเมื่อถึงเฟสนั้น
แต่ **`progress.md` ต้องมีตั้งแต่เริ่มลงมือเขียนโค้ด** ไม่ใช่มาเขียนตอนจบ
ฟีเจอร์ที่เล็กพอ (patch เดียว) ใช้ไฟล์เดียวชื่อ `plan.md` ก็ได้ (ดู `HelpCenterSupportEmails/`)

เสร็จแล้วมาเพิ่ม 1 บรรทัดในตารางข้างบนด้วย

## ทำงานต่อจากคนอื่น / ส่งต่อให้คนอื่น

1. อ่าน `progress.md` ของฟีเจอร์นั้นก่อน (entry บนสุด = ล่าสุด) — ถ้าไม่มี ให้ดู blockquote หัว `spec.md`
2. **อย่าเชื่อสถานะในเอกสารทั้งดุ้น** — ตรวจกับโค้ดจริง/`git log` ก่อนเริ่ม แล้วถ้าไม่ตรง แก้เอกสารให้ตรงเป็นอย่างแรก
3. หยุดงาน/ส่งต่อ → เพิ่ม entry ใหม่บนสุดใน `progress.md` (รูปแบบ + 3 ช่องบังคับ ดู [`../README.md`](../README.md#อัปเดตความคืบหน้า--ทำถึงไหนแล้ว-เขียนตรงไหน))
4. ฟีเจอร์ข้ามเฟส (planning → implement → done) → อัปเดตช่อง "สถานะตามเอกสาร" ในตารางข้างบน
