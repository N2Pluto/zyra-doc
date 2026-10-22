# Mobile App — Open items (UI ที่ขาด · คำถามค้าง · scenario ที่ไม่สมบูรณ์)

> **สถานะ:** checklist รวม ณ 2026-10-01 หลังถอด Figma ครบ HP-03 ถึง HP-11, EP-01, EP-02, EC-03 · ยังไม่แตะโค้ด · **repo:** zyra-app, zyra-api, zyra-ws
> **ที่มา:** ตรวจจาก [ux-ui-plan.md](ux-ui-plan.md), [spec.md](spec.md) open questions, [screens.md](screens.md), [task-breakdown.md](task-breakdown.md), [technical-design.md](technical-design.md), [clickup-spec.md](clickup-spec.md)
> **mockup ทุกข้อในหมวด 1–2:** https://zyra-mobile-ui-proposals.vercel.app (source `zyra-doc/web/mobile-ui-proposals/`)
> **วิธีใช้:** ติ๊ก `[x]` เมื่อได้คำตอบหรือได้ frame แล้ว และบันทึกผลลงเอกสารต้นทางตาม ref · ผู้รับผิดชอบ: 🎨 design · 🙋 Ten · 📋 PM · 🛠 dev

## 1. UI ที่ยังไม่มีใน Figma — ต้องให้ design วาดใหม่

### Meeting (HP-04)
- [ ] 🎨 **bottom sheet ตั้งค่าห้อง** — Voice output · Camera filter · Invite · ไม่มี Room name (Ten 2026-10-02) · ref ux-ui-plan §8.6 ข้อ 2, §8.7
- [ ] 🎨 **Participants sheet + Invite sheet (แท็บ Chat / Link / Email)** — Pai เขียนโน้ตแล้ว · Ten ตอบคำถาม 12 ข้อครบ 2026-10-02 · **เหลือ Pai วาด frame** · ref §8.8.2–8.8.3 · task 0.52
- [ ] 🎨 **toast คำขอเข้าห้องล็อก + Requesting list** (แทน popup อนุญาต / ปฏิเสธ) — spec ครบแล้ว **เหลือ Pai วาด frame** · ref §8.8.4 · task 0.52
- [ ] 🎨 **Meeting grid 3×3 บน tablet** (6–9 tile) · ref §17.7 ข้อ 6 · task 0.45

### Chat (HP-05)
- [ ] 🎨 **หน้าสร้าง Group / Channel แบบเต็มจอ** — เมนู FAB แยก Create channel / Create group ตาม Figma `5944-134262` แล้ว (ไม่ต้องมี sheet เลือก) §22.1 · Pai เขียนโน้ตหน้า New group แล้ว (§19.1) · **เหลือ Pai วาด frame** · ref ux-ui-plan §9.6 ข้อ 9, §9.7, §19.1
- [ ] 🎨 **Chat info แบบแท็บ Telegram** (ทางเข้า thread / ข้อมูลห้อง / ไฟล์สื่อ) — Pai เขียนโน้ตแล้ว · Ten ตอบ 8 ข้อ "ตามแนะนำ" 2026-10-02 · **เหลือ Pai วาด frame** · ref §9.8 · task 0.53

### Navigation / Profile / Settings (HP-06, HP-08)
- [ ] 🎨 **Profile / Notification / Workspace lists แนวนอน** — Notification = drawer 390 สูงเต็มจอจากขวา (Pai + Ten §19.2) · **เหลือ Pai วาด frame** · ref §10.6 ข้อ 4, §10.7, §19.2
- [x] 🎨 ~~**หน้า Calendar** ในแท็บล่าง~~ — ไม่ต้องทำรอบนี้ (Ten: ซ่อนไปก่อน) · ref §10.6 ข้อ 7
- [ ] 🎨 **แถว Do not disturb ใน status picker** (Profile tab) — Figma มีแค่ Active / Busy / Away · ref §10.6 ข้อ 5
- [ ] 🎨 **Notification settings สวิตช์ใหม่** — สวิตช์เดียวต่อแถวตาม Figma 6436-67120 (§19.3) · 4 แถวใหม่มีข้อความเสนอแล้ว · **เหลือ Pai วาด 4 แถว** · ref §12.5 ข้อ 8, §12.7, §19.3
- [ ] 🎨 **หน้าย่อยใน Profile → Setting** — Account and Security · Language · Audio · Camera · Manage member · Environment · Workspace mode · Help · Legals · Figma มีแค่แถวเมนู ยังไม่มีหน้าใน (prototype มีหน้าข้อเสนอแล้ว) · ref ux-ui-plan §10.7 · เพิ่ม 2026-10-05
- [ ] 🎨 **หน้าแก้โปรไฟล์** (ลูกศรบนการ์ดสถานะใน Profile) · ref §22.3 · task 0.61 · เพิ่ม 2026-10-05
- [ ] 🎨 **หน้าเลือกตัวละคร** (Change character ใน Lobby / แก้โปรไฟล์) · ref §22.3 · task 0.61 · เพิ่ม 2026-10-05
- [ ] 🎨 **error ตอน login** (รหัสผิด / อีเมลยังไม่ยืนยัน / เน็ตหลุด) · ref §22.3 · task 0.60 · เพิ่ม 2026-10-05
- [ ] 🎨 **หน้าว่าง** (แชท / Notification / ค้นหาไม่เจอ / Threads) · ref §22.3 · เพิ่ม 2026-10-05

### Install (HP-07)
- [ ] 🎨 **หน้า/prompt ติดตั้ง PWA** (Figma มีแค่ sheet "Meet Zyra on mobile") · ref §11.6 ข้อ 2, §11.7

### Spotlight (HP-11)
- [x] ~~🎨 **หน้า Spotlight คนดู**~~ — **Figma มีแล้ว** (v2 2026-10-05 ทั้ง 2 แนว) · ref §18.9
- [ ] 🎨 **sheet รายชื่อ Spotlight 2 แท็บ On stage / Viewers** (เปิดจากชิป N | M) — spec ครบ §19.5 · Figma v2 ยังไม่มี frame · **เหลือ Pai วาด**
- [ ] 🎨 **แถว "Spotlight · Live" บน Lite Home** (กดเข้าดูทีหลังเมื่อปิด toast ไปแล้ว) — ข้อเสนอ §18.9 ข้อ 2 · **Pai วาด**
- [ ] 🎨 **แก้จุดที่ Figma HP-11 v2 ขัดกันเอง** ("1 seconds", ชื่อ layer, แถบล่างบนแมพ, ปุ่มสลับกล้อง / speaker, More แนวนอน, Leave สีเขียว) · ref §18.9.3
- [x] ~~🎨 **sheet ยืนยัน Stop broadcasting**~~ — **Figma มีแล้ว** = "Leave Spotlight?" · ref §18.9

### Edge cases ที่ไม่มีลิงก์ Figma (EC-01, EC-02)
- [x] ~~🎨 **หน้า "ใช้ได้บน Desktop เท่านั้น"** + QR~~ — **ไม่ทำ** (Pai + Ten 2026-10-02): ซ่อนเมนู · เปิด URL ตรง → Space builder + toast · ref §19.6 · 📋 แจ้ง PM (ต่างจาก EC-01)
- [x] ~~🎨 **หน้า/toast "Coming soon"**~~ — **ไม่ทำ** (Pai + Ten 2026-10-02): ซ่อนฟีเจอร์ที่ยังไม่มีทั้งหมด · ref §19.7 · 📋 แจ้ง PM (เปลี่ยนมติข้อ 4 ในเอกสาร PM)
- [ ] 🎨 **banner บน iOS Safari** "บางฟีเจอร์ทำงานได้ดีกว่าในแอป Zyra" + เตือนเสียงอาจหลุดตอนสลับแอประหว่างประชุม (sheet HP-07 ครอบได้บางส่วน) · ref clickup-spec §15

### รูป / asset ที่รอจาก UX/UI (เพิ่ม 2026-10-02 — **ยังไม่แก้ mockup จนกว่าจะได้รูป**)
- [ ] 🎨 **โลโก้แบบพื้นเขียว + ตัว Z ขาว** ตาม Figma (`Zyra_System_Logo2`) — ไฟล์ที่ได้ (`zyra-logo.svg`) เป็นตัว Z เขียวพื้นใส
- [ ] 🎨 **โลโก้ Google "G" และ Apple** สำหรับปุ่ม login (Figma = ปุ่มพื้นขาว) — mockup ข้อ 23 ยังใช้ icon lucide ที่ไม่ใช่โลโก้แบรนด์
- [ ] 🎨 **avatar ตัวละคร pixel ตัวอย่าง** แทนวงกลมตัวอักษรใน mockup
- [ ] 🎨 **ภาพแมพตัวอย่าง** สำหรับ mockup แนวนอน
- [ ] 🎨 **ภาพประกอบ onboarding 3 slide** (Figma ยังเป็นวงกลม placeholder) · icon 56 ในการ์ด Select workspace mode · icon หน้า Rotate your phone · วงกลม 80 ใน "All rooms are busy" และ "You're sharing your screen"
- [ ] 🎨 **ภาพสำหรับหน้าใหม่**: sheet ติดตั้ง PWA · ~~Coming soon~~ (ตัดแล้ว) · ยืนยันหยุดออกอากาศ (ตอนนี้ mockup ยืมภาพ Workspace created / มาสคอต login มาใช้ชั่วคราว)
- [ ] 🎨 **asset สำหรับ store / native**: ไอคอนแอป 1024×1024 มีพื้นหลัง · Android adaptive icon (foreground + background) · ไอคอน notification Android (ขาวล้วนพื้นใส) · splash · screenshot store มือถือ + iPad · Play feature graphic 1024×500
- หมายเหตุ: `spotlight-celebrate.png` = ภาพหน้า **Workspace created** ใน Figma · `mascot-sparkle.png` = มาสคอตหน้า **Get started / login** ใน Figma (เก็บไว้ที่ R2 dev `static/mobile-app/` แล้ว)

## 2. ข้อเสนอที่เขียน spec แล้ว — รอ design ยืนยันภาพ

- [ ] 🎨 หน้า / state ขอเปิด notification (Allow) ใน Notification settings · ref ux-ui-plan §12.6
- [ ] 🎨 pre-permission sheet กล้อง/ไมค์ · indicator บนปุ่มเมื่อถูกปฏิเสธ · คู่มือเปิดสิทธิ์บนเว็บ (Safari / Chrome) · ref §13.6
- [ ] 🎨 icon สถานะการเชื่อมต่อ / แชทส่งไม่ได้ (lucide) · ref §14.7
- [ ] 🎨 หน้าหลัก skeleton + "Reconnecting..." · ref §14.8
- [ ] 🎨 toast ขาขึ้นตอนประสิทธิภาพกลับมาปกติ · ref §15.6
- [x] ~~🎨 เมนู Performance ใน Profile → Setting~~ — **ไม่ทำ** (Pai + Ten 2026-10-02): ปรับเองอย่างเดียว · ref §19.8 · 📋 แจ้ง PM (ต่างจาก EP-01)
- [ ] 🎨 ความกว้างคอลัมน์กลางจอ (~480) ของหน้าก่อนเข้า workspace บน tablet แนวนอน · ref §17.6
- [x] ~~🎨 Spotlight แนวนอน~~ — **Figma มีแล้ว** section `6927-66368` · ref §18.9
- [ ] 🎨 **ตำแหน่ง PIP แนวนอน** ขวาล่างเหนือ minimap (Figma แถว PIP แนวนอนไม่มี frame) · ref §8.2 PIP

## 3. คำถามที่ Ten ยังไม่ได้ตอบ

### ยังไม่ได้ตอบเลย
- [x] 🙋 **HP-04 ข้อ 9** — แนวนอน minimap ไม่หาย · แนวตั้งลาก PIP ไม่ได้ (Ten 2026-10-01) · ref §8.6 · spec OQ 14
- [x] 🙋 **HP-04 ข้อ 10** — modal Join meeting เปิดจาก**การแตะห้องบนแมพ** (Ten 2026-10-01) · ref §8.6 · spec OQ 15
- [x] 🙋 **HP-04 ข้อ 10 (ต่อ)** — ✅ Ten ยืนยันครบ 3 ข้อ (2026-10-01): แตะในห้องจากนอกห้อง = เปิด modal (ที่อื่นยังเดินตามแตะ) · Join = avatar เดินเข้าห้องเอง · อยู่ในห้องแล้วแตะไม่เปิด · ref §8.6 ข้อ 10
- [x] 🙋 **HP-05 ข้อ 1** — ✅ เลือกสร้างได้ทั้ง Group และ Channel · ~~FAB "Create chat" สร้าง Group หรือ Channel~~ · ref §9.6 · spec OQ 17
- [x] 🙋 **HP-06 ข้อ 5** — ✅ ไม่ตัด ไม่รวม เพิ่ม Do not disturb เป็นตัวที่ 4 · ref §10.6 · spec OQ 20
- [x] 🙋 **HP-06 ข้อ 7** — ✅ ซ่อนไปก่อน (bottom nav 3 แท็บ) · ref §10.6 · spec OQ 21
- [x] 🙋 **HP-06 ข้อ 8** — ✅ ใช่ · หน้าลูกซ่อน bottom nav + Android back / iOS swipe-back = ปุ่ม back · ref §10.6
- [x] 🙋 **HP-03 ข้อ 10** — ✅ ยึด Figma · ref §7
- [x] 🙋 **HP-03 ข้อ 11** — ✅ เพิ่มปุ่ม Continue with Apple ในแนวนอน (Browser) · ref §7
- [x] 🙋 **HP-03 ข้อ 12** — ✅ ใช่ "Space builder" = รายการ workspace · ref §7

### สมมติค่าไว้แล้ว — รอยืนยัน
- [x] 🙋 **Calendar ซ่อน (ต่อ)** — ✅ ซ่อนทั้งหมด: ปุ่ม calendar ขวาบน Spatial + กลุ่ม Calendar ใน Notification settings (Ten 2026-10-01) · ref §10.6 ข้อ 7
- [ ] 🙋 **EP-01** Level 4 เข้าที่ FPS เท่าไร · ต่ำต่อเนื่องกี่วิต่อขั้น (สมมติ 10 วิ) · เกณฑ์ขาขึ้น (สมมติ > 45 นาน 30 วิ) · ref §15.5 · spec OQ 29
- [ ] 🙋 **EP-01** เตือน RAM ต่ำ (สมมติ: ทำ — task 1.15) · ref §15.5 ข้อ 9 · spec OQ 30
- [ ] 🙋 **EP-02** map แถบ bandwidth (> 2 Mbps = 720 · 0.5–2 Mbps = 360) · กลับมาดี > 1 Mbps นาน 10 วิ · toast อื่นปิดเอง 10 วิ · แชร์จอไม่หยุดเอง · ref §16.5 · spec OQ 31
- [ ] 🙋 **HP-05** mention "คนที่คุยบ่อย 3–4 คน" นับจากอะไร (สมมติ: ล่าสุดก่อน) · ref spec OQ 18
- [ ] 🙋 **HP-05** เมนู ⋮ ตอน preview รูปมีอะไรบ้าง · ref spec OQ 19

### เรื่องธุรกิจ / store (ยังไม่ได้ถาม)
- [ ] 📋 Apple Developer account + Google Play Console ของบริษัทมีแล้วหรือยัง · ref spec OQ 2
- [x] 📋 ชื่อแอป ✅ **Zyra World** · ไอคอน ✅ **logo ตัว Z** · bundle id ✅ **`co.zyraworld.app`** (Ten 2026-10-01) · ref spec OQ 3, clickup-spec §18 ข้อ 6
- [x] 📋 Microsoft login บนมือถือ — ✅ ยังไม่ต้องทำ (Ten 2026-10-01) · ref spec OQ 5

## 4. Scenario ที่ยังไม่สมบูรณ์ (ไม่มี spec หรือไม่มี flow)

- [ ] 🎨🛠 **ลบบัญชีในแอป** — Apple App Store Review Guideline 5.1.1(v): แอปที่สมัครสมาชิกได้ต้องลบบัญชีได้ในแอป ไม่มี = reject · ยังไม่มีในเอกสารเลย · ต้องมี UI (Profile → Setting) + API ใหม่ใน zyra-api (ลบ/anonymize ข้อมูล, ยกเลิก session, จัดการ workspace ที่เป็น owner) · **ร่าง spec แล้ว 2026-10-05 → ux-ui-plan §20** (ใช้ service ลบบัญชีฝั่ง admin เดิม · เพิ่ม `DELETE /api/user/me`) · ✅ Ten ตอบครบ 2026-10-05 · 🎨 **เหลือ Pai วาด frame** · เพิ่มขั้นตอนเก็บกวาด + ใครลบได้ §20.6 · 📋 PM กรอกลิงก์ลบบัญชีใน Play Console
- [ ] 🎨 **Sign up / OTP verify / Forgot password บนมือถือ** — ✅ มติ 2026-10-05: ใช้ขั้นตอนเดิมของเว็บ เปลี่ยน layout (§22.2) · prototype มีหน้าข้อเสนอ · **เหลือ Pai วาด**
- [ ] 🎨 **Lite: แตะคนในรายชื่อสมาชิก** — ✅ มติ 2026-10-05: sheet โปรไฟล์ Message / Wave / Join (ถ้าอยู่ในห้อง) ไม่มี Follow (§22.2) · **เหลือ Pai วาด** · task 0.59
- [ ] 🎨🛠 **Lite: แตะ Circle** — ✅ มติ 2026-10-05: sheet "Join Circle" · zyra-ws ต้องเพิ่ม join circle by id (§22.2) · task 0.59
- [ ] 🎨 **เปิดลิงก์เชิญ / deep link** — ✅ มติ 2026-10-05 ครบ 4 กรณี (§22.2) · หน้ารับคำเชิญ + หน้า "This link is no longer available" **เหลือ Pai วาด** · task 0.60
- [ ] 🙋🎨 **Session หมดอายุ / ถูกออกจากระบบ / เปลี่ยนรหัสจากอีกเครื่อง บนมือถือ** — เว็บมีครบ 3 แบบแล้ว · spec ux-ui-plan §21.1 · ✅ Ten ตอบครบ · 🎨 **เหลือ Pai วาดหน้า signed out แบบมือถือ** · task 0.56
- [ ] 🙋🎨🛠 **บังคับอัปเดตแอป (Update required / Update available)** — ใหม่ทั้งหมด · ต้องมีก่อนปล่อยเวอร์ชันแรก · spec §21.2 · ✅ Ten ตอบครบ · 🎨 **เหลือ Pai วาด** · task 0.57
- [ ] 🙋🎨 **หน้าปิดปรับปรุงบนมือถือ** — เว็บมี `/maintenance` แล้ว · spec §21.3 · ✅ Ten ตอบครบ (ปุ่ม Try again) · 🎨 **เหลือ Pai วาด** · task 0.58
- [ ] 🙋🎨 **ติดตั้ง PWA บน Android** — ตอนนี้มีแต่ขั้นตอน iOS · §21.4 ข้อ 7 · ✅ ใช้ปุ่ม Install ของ Chrome ใน sheet "Meet Zyra on mobile" · 🎨 **เหลือ Pai วาด** · task 0.33
- [ ] 📋 **HP-02 ขนาดปุ่มกด** — ClickUp AC ≥ 44×44 (Apple HIG) vs Figma 42 / 32 / 24 · font เล็กสุด 10 vs AC 14 · ยังไม่มีใครตัดสิน · ref clickup-spec §2, §18 ข้อ 3
- [x] 📋 **Calendar / Tarot / Participation Dashboard / Quiz / Poll / AI Meeting Summary** — ✅ Ten 2026-10-01: กดแล้วขึ้น "Coming soon" (Calendar ซ่อนทั้งหมด) · เดิม: — ClickUp อ้างหลาย subtask แต่ไม่มีในโค้ด · PM ยืนยันว่าตัดออกจากรอบแรก · ref clickup-spec §18 ข้อ 5 · **แก้ 2026-10-02: ไม่ใช้ Coming soon แล้ว — ซ่อนทั้งหมด (§19.7)**
- [ ] 📋 **ClickUp ต้องแก้ตามมติ** — รวมข้อที่ต่างจาก Figma/มติใน clickup-spec §18 (ข้อ 1–83) ให้ PM อัปเดต AC

## 5. สรุปจำนวน (อัปเดต 2026-10-01 หลัง Ten ตอบคำถามค้างครบ)

| หมวด | ยังไม่ติ๊ก | ใครทำ |
|---|---|---|
| UI ที่ต้องวาดใหม่ | 16 | 🎨 design |
| ข้อเสนอรอ design ยืนยัน | 9 | 🎨 design |
| รูป / asset รอจาก UX/UI | 7 | 🎨 design |
| คำถามที่ Ten ยังไม่ได้ตอบ | 0 | — |
| ค่าที่สมมติรอยืนยัน | 5 | 🙋 Ten |
| เรื่องธุรกิจ / store | 1 | 📋 PM |
| Scenario ไม่สมบูรณ์ | 7 | 📋 PM · 🎨 design · 🙋 Ten |
| **รวม** | **45** | |
