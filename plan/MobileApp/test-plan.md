# Test Plan — Mobile App (Capacitor + mobile web) · รายการทดสอบสำหรับ QA

> **สถานะ:** เขียน 2026-10-02 จากมติที่ตกลงครบทุก subtask (HP-03 ถึง HP-11, EP-01, EP-02, EC-01 ถึง EC-03) — **ยังไม่มีโค้ด mobile ให้รัน** รายการนี้เตรียมไว้ล่วงหน้าเพื่อให้ QA วางแผนและให้ dev ใช้เป็น acceptance
> **repo ที่กระทบ:** frontend = zyra-app (+ zyra-mobile shell Capacitor) · backend = zyra-api, zyra-ws, zyra-notifications
> **ที่มาของค่า:** [ux-ui-plan.md](ux-ui-plan.md) (UI จาก Figma) · [spec.md](spec.md) · [technical-design.md](technical-design.md) · [task-breakdown.md](task-breakdown.md) · mockup หน้าที่ยังไม่มีใน Figma: https://zyra-mobile-ui-proposals.vercel.app
> **กฎ "Comp 80%":** ก่อนเปลี่ยน ClickUp task เป็น Completed ต้องทดสอบผ่านอย่างน้อย 80% ของรายการที่เกี่ยวกับ task นั้น (คนละเรื่องกับ code coverage)

---

## 0. วิธีอ่านและเตรียมทดสอบ

**รหัส:** `FE-<กลุ่ม>-<เลข>` = frontend (สิ่งที่เห็นและกดบนเครื่อง) · `BE-<กลุ่ม>-<เลข>` = backend (API / WebSocket / push ที่ตรวจด้วยเครื่องมือหรือดูผลข้ามเครื่อง)

**Priority:** **P0** = กั้นการขึ้น store หรือใช้งานหลักไม่ได้ · **P1** = ฟีเจอร์หลักของรอบแรก · **P2** = รายละเอียด / edge case

**สถานะ (QA กรอก):** ⬜ ยังไม่ทดสอบ · ✅ ผ่าน · ❌ ไม่ผ่าน (ใส่ลิงก์ bug) · ⏸️ ยังทดสอบไม่ได้ (blocked)

**ป้าย blocked ที่มีอยู่แล้ว:** 🎨 รอ UI จาก design · ⏳ รอมติ · 🔜 อยู่ Phase หลัง

**เครื่องทดสอบ (EC-03 device matrix)**

| เครื่อง | ขนาด | ใช้ทดสอบ |
|---|---|---|
| iPhone SE (3rd) | 375×667 | จอเล็ก · Spatial 667×375 |
| iPhone 13 / 14 | 390×844 | เครื่องหลัก (ขนาด Figma) |
| iPhone 14 Pro Max | 430×932 | จอใหญ่ |
| Samsung Galaxy S23 หรือ Pixel 7 | 393×873 | Android หลัก |
| Android เครื่องกลาง (เช่น Galaxy A54 / Pixel 6a) | — | performance EP-01 |
| iPad mini | 744×1133 | tablet + Split View |
| iPad Pro 12.9" | 1024×1366 | tablet ใหญ่ |
| Galaxy Tab | 800×1280 | Android tablet |
| Desktop Chrome | — | ฝั่งคนดู/คนในห้องที่ใช้ desktop + EP-02 desktop |

**ช่องทาง:** แอป iOS (TestFlight) · แอป Android (Play internal) · mobile web Safari iOS · mobile web Chrome Android · desktop web (เพื่อดูผลข้ามเครื่อง)

**ข้อมูลที่ต้องเตรียม:** บัญชีทดสอบอย่างน้อย 4 คน (Owner, Admin, Member 2 คน) · workspace ทดสอบที่มีห้องประชุม ห้องล็อก Circle spotlight marker และ 2 floor · Google account ทดสอบ · Apple ID ทดสอบ · ใช้ Network Link Conditioner (iOS) / Chrome DevTools throttling สำหรับเน็ตแย่

---

# ส่วน A — Frontend

## FE-ENV · ตัวตัดสิน UI มือถือ และขนาดจอ (EC-03 · task 0.41–0.44, 1.16)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-ENV-01 | P0 | แอปบนมือถือและ tablet ใช้ UI มือถือเสมอ | เปิดแอปบน iPhone, Android, iPad | ได้หน้า Select workspace mode / Lite / Spatial ไม่ใช่หน้า desktop | §17.6 | ⬜ |
| FE-ENV-02 | P0 | เว็บบนจอสัมผัส ด้านยาว ≤ 1366 | เปิดเว็บใน Safari iPad Pro, Chrome Android | ได้ UI มือถือ | §17.6 | ⬜ |
| FE-ENV-03 | P1 | iPad + trackpad บนเว็บ | ต่อ Magic Keyboard แล้วเปิดเว็บ | ยังเป็น UI มือถือ | §17.7 ข้อ 2 | ⬜ |
| FE-ENV-04 | P1 | laptop จอสัมผัสด้านยาว > 1366 | เปิดเว็บบน laptop จอสัมผัส (หน้าต่างแนวนอน กว้าง ≥ 768) | ได้หน้า desktop เดิม (ถ้าย่อเป็นแนวตั้งจะเป็น UI มือถือตาม FE-ENV-14) | §17.6 | ⬜ |
| FE-ENV-05 | P1 | tablet scale | iPad (ด้านสั้น ≥ 744) | ขอบซ้ายขวา 24 · ปุ่มกลมขวาบน Spatial และปุ่ม Chat = 44 | §17.6 | ⬜ |
| FE-ENV-06 | P1 | phone scale | iPhone 390 / 430 | ขอบ 16 · ปุ่มกลม 32 | §17.2 | ⬜ |
| FE-ENV-07 | P1 | จอเล็ก 375×667 | ใช้ทุกหน้าหลักบน iPhone SE | ไม่มีการเลื่อนซ้ายขวา · ข้อความยาวถูกตัดเป็น … · modal สูงไม่เกิน 90% ของจอและเลื่อนได้ · คีย์บอร์ดไม่บังช่องพิมพ์ | §17.6 | ⬜ |
| FE-ENV-08 | P1 | Spatial บนจอเล็ก 667×375 | เข้า Spatial บน iPhone SE | joystick, Meeting Menu, minimap ไม่ทับกัน | §17.6 | ⬜ |
| FE-ENV-09 | P1 | iPad Split View | แบ่งจอครึ่งตอนเครื่องแนวนอน | ระบบนับเป็นแนวตั้ง (ใช้ Lite / ขึ้นหน้า Rotate ถ้าอยู่ Spatial) | §17.6 | ⬜ |
| FE-ENV-10 | P1 | ปรับขนาด Split View ระหว่างใช้ | ลากเส้นแบ่งจอให้กว้าง/แคบ | layout และ tablet scale ปรับตามทันที ไม่ค้าง | TD §16.8 | ⬜ |
| FE-ENV-11 | P1 | ตัวอักษรไม่ขยายตามเครื่อง | Android ตั้ง font size ใหญ่สุด แล้วเปิดแอป | layout ไม่แตก ตัวอักษรขนาดเดิม | §17.7 ข้อ 8 | ⬜ |
| FE-ENV-12 | P2 | dark mode อย่างเดียว | ตั้งเครื่องเป็น light mode | แอปยังเป็นธีมมืด | §17.7 ข้อ 9 | ⬜ |
| FE-ENV-13 | P1 | safe area | iPhone ที่มี Dynamic Island / home indicator ทั้ง 2 แนว | ปุ่มและแถบล่างไม่ถูกบัง | task 0.2 | ⬜ |
| FE-ENV-14 | P0 | desktop หน้าต่างแนวตั้ง | Chrome desktop ย่อหน้าต่างเป็น 600×900 แล้วเข้า workspace | ได้ UI มือถือ Lite · ไม่มีหน้า Select workspace mode · ไม่มีหน้า Rotate | §24 · TD §16.8 | ⬜ |
| FE-ENV-15 | P1 | desktop หน้าต่างแคบแนวนอน | ย่อหน้าต่างเป็น 700×500 | ได้ UI มือถือ Lite แทนหน้า Mobile unsupported | §24 | ⬜ |
| FE-ENV-16 | P0 | ย่อ / ขยายหน้าต่างระหว่างประชุม | อยู่ใน meeting บน desktop แล้วย่อเป็นแนวตั้ง แล้วขยายกลับ | สลับ UI หลังขนาดนิ่ง ~300 ms · เสียง / วิดีโอไม่หลุด · กลับแนวนอน ≥ 768 ได้ UI desktop เดิม · ไม่สลับระหว่างพิมพ์ | §24 | ⬜ |
| FE-ENV-17 | P1 | mobile web หน้าตาเหมือนแอป | เปิด mobile web บน iPhone Safari เทียบกับแอป | ทุกหน้าเหมือนแอป · ต่างแค่ native (ไม่มี push, login แบบเว็บ, share = คัดลอกลิงก์, ไม่มี haptics) | §24 | ⬜ |

## FE-ONB · ติดตั้ง เปิดแอป login (HP-07 · task 0.31–0.33, 0.46, 1.2–1.5)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-ONB-01 | P1 | splash | เปิดแอปครั้งแรก | splash 2 วินาที แล้วไป slide | §11.2 | ⬜ |
| FE-ONB-02 | P1 | onboarding 3 slide | เลื่อน slide | มี 3 slide ข้อความตาม Figma **ไม่มีปุ่ม Skip** | §11.6 | ⬜ |
| FE-ONB-03 | P0 | ขอสิทธิ์ notification ตอนเปิดครั้งแรก | เปิดแอปครั้งแรก | dialog ขอสิทธิ์ notification ขึ้นช่วง splash | §12.5 ข้อ 1 | ⬜ |
| FE-ONB-04 | P0 | หน้าก่อนเข้า workspace เป็นแนวตั้ง (มือถือ) | หมุนเครื่องแนวนอนที่ splash / slide / login / Space builder / Create workspace / Select mode | แอปล็อกแนวตั้ง · mobile web ขึ้นหน้า Rotate | TD §16.5 | ⬜ |
| FE-ONB-05 | P1 | หน้าก่อนเข้า workspace บน tablet | หมุน iPad เป็นแนวนอน | ไม่ล็อก แสดงคอลัมน์ layout แนวตั้งกลางจอ (~480 🎨 รอ design ยืนยัน) | task 0.46 | ⬜ |
| FE-ONB-06 | P0 | login ด้วย Google ในแอป | กด Continue with Google | เปิดหน้าเลือกบัญชีแบบ native (ไม่ใช่หน้าเว็บที่ Google บล็อก) · login สำเร็จ | task 1.4 | ⬜ |
| FE-ONB-07 | P0 | login ด้วย Apple ในแอป iOS | กด Continue with Apple | sheet Apple native · login สำเร็จ · กรณีซ่อนอีเมลก็ login ได้ | task 1.5 | ⬜ |
| FE-ONB-08 | P1 | login ด้วย Apple บนเว็บ | เปิด login บนเว็บทั้งแนวตั้งและแนวนอน | มีปุ่ม Continue with Apple ทั้ง 2 แนว · login สำเร็จ | §7 ข้อ 11 | ⬜ |
| FE-ONB-09 | P0 | login ด้วย email | กรอก email + password ในแอป | login ได้ · reCAPTCHA ไม่ขวาง (ถ้ามี) | task 1.3 | ⬜ |
| FE-ONB-10 | P2 | ไม่มี Microsoft login | ดูหน้า login บนมือถือ | ไม่มีปุ่ม Microsoft | spec OQ 5 | ⬜ |
| FE-ONB-11 | P1 | Space builder (รายการ workspace) | login แล้ว | หน้า Space builder: Empty / มีรายการ / ค้นหาเจอ (highlight) / ค้นหาไม่เจอ · เมนู ⋮ ของการ์ด | §11.2 | ⬜ |
| FE-ONB-12 | P1 | สร้าง workspace บนมือถือ | Create workspace 3 ขั้น | เลือก template (filter Capacity) → details → Workspace created → Enter Workspace | task 0.32 | ⬜ |
| FE-ONB-13 | P1 | sheet "Meet Zyra on mobile" บนเว็บ | เปิดเว็บบนมือถือ รอ ~5 วิ | sheet ขึ้น · Open Zyra → เปิดแอป (ถ้ามี) หรือไป App Store / Play Store · Later → ซ่อน 7 วัน | task 0.33 | ⬜ |
| FE-ONB-14 | P2 | ชวนติดตั้ง PWA | กด Later แล้วเข้าเว็บครั้งที่ 2 | ขึ้นหน้า Add to Home Screen (Android ปุ่ม Install · iOS บอกขั้นตอน) 🎨 | §11.6 ข้อ 2 | ⏸️ |
| FE-ONB-15 | P1 | แจ้งมี version ใหม่ | deploy version ใหม่ระหว่างใช้แอป | modal แจ้ง update ขึ้นภายใน 30 นาที | clickup-spec §18 ข้อ 9 | ⬜ |
| FE-ONB-16 | P1 | error ตอน login | รหัสผิด · อีเมลยังไม่ยืนยัน · กด cancel ตอนเลือกบัญชี Google · ปิดเน็ต | ข้อความแดง "Incorrect email or password." · sheet "Verify your email" → OTP · cancel แล้วอยู่หน้าเดิมไม่มี error · toast "Can't connect…" 🎨 | §22.3 · task 0.60 | ⏸️ |

## FE-MODE · เลือกโหมด Lite / Spatial และหน้า Rotate (HP-03 · task 0.12–0.15, 0.42)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-MODE-01 | P0 | เลือกโหมดครั้งแรก | เลือก workspace | ขึ้นหน้า Select workspace mode (Lite / Spatial) → Confirm → sheet Keep This Setting? | §3.4 | ⬜ |
| FE-MODE-02 | P0 | Remind me again = จำ 1 วัน ทุก workspace | เลือก Remind me again แล้วสลับไป workspace อื่นภายใน 24 ชม. | ไม่ถามโหมดซ้ำ · ครบ 24 ชม. ถามใหม่ | TD §16.1 | ⬜ |
| FE-MODE-03 | P1 | Always = จำตลอด | เลือก Always แล้วปิดเปิดแอป | ไม่ถามอีก | TD §16.1 | ⬜ |
| FE-MODE-04 | P0 | เปลี่ยนโหมดได้จาก Settings เท่านั้น | Profile → Setting → Workspace mode | เปลี่ยนแล้วโหลดหน้าใหม่ในโหมดใหม่ · การหมุนเครื่องไม่สลับโหมด | §3.4 | ⬜ |
| FE-MODE-05 | P0 | Lite ถือแนวนอน | อยู่ Lite แล้วหมุนเครื่องแนวนอน | หน้า "Rotate your phone to use Lite Mode." ทับ · หมุนกลับแล้วหาย | §3.5 | ⬜ |
| FE-MODE-06 | P0 | Spatial ถือแนวตั้ง | อยู่ Spatial แล้วหมุนแนวตั้ง | หน้า Rotate ทับ · แมพหยุดวาด แต่เสียงประชุมยังต่อ · หมุนกลับแมพกลับมา | §3.5, TD §16.3 | ⬜ |
| FE-MODE-07 | P1 | คีย์บอร์ดไม่ทำให้หน้า Rotate เด้ง | Android พิมพ์แชทใน Lite | ไม่ขึ้นหน้า Rotate ตอนคีย์บอร์ดเปิด | TD §16.4 | ⬜ |
| FE-MODE-08 | P0 | Lite ไม่โหลดแมพ | เข้า Lite แล้วดู network | ไม่มีการโหลด engine / map / spritesheet | TD §16.2 | ⬜ |
| FE-MODE-09 | P1 | Lite เข้าเลยไม่ผ่าน pre-join | เลือก Lite → Enter Workspace | ไป Connecting → Lite Home ทันที (ไม่มีหน้า preview กล้อง/ชื่อตัวละคร) | TD §16.1 | ⬜ |
| FE-MODE-10 | P1 | Spatial ผ่าน pre-join | เลือก Spatial | หน้า welcome / pre-join แนวนอน → Connecting → แมพ | §3.6 | ⬜ |

## FE-LITE · Lite Home และ navigation (HP-03, HP-06 · task 0.14, 0.28–0.30)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-LITE-01 | P0 | Lite Home | เข้า Lite | header workspace + Start spotlight / Instant meeting + ค้นหา + In meeting + Circle + Online / Offline | §3.8 | ⬜ |
| FE-LITE-02 | P0 | แท็บล่าง 3 ปุ่ม | ดูแท็บล่าง | Home / Chat / Profile แบบ icon ไม่มี label · **ไม่มี Calendar** · หดตอนเลื่อน | §10.6 ข้อ 7 | ⬜ |
| FE-LITE-03 | P1 | badge แชท | มีข้อความใหม่ | badge บนแท็บ Chat | §10.2 | ⬜ |
| FE-LITE-04 | P1 | หน้าย่อยซ่อนแท็บล่าง | เปิดหน้าย่อย (Setting, Notification settings ฯลฯ) | แท็บล่างหาย · ปุ่ม back กลับได้ | §10.6 ข้อ 8 | ⬜ |
| FE-LITE-05 | P1 | back ของ Android / ปัดย้อน iOS | กด back ของเครื่อง / ปัดจากขอบซ้าย | ทำงานเหมือนปุ่ม back ในแอป | §10.6 ข้อ 8 | ⬜ |
| FE-LITE-06 | P1 | รายการ workspace | แตะ chevron ข้างชื่อ workspace | หน้าเต็มจอ Workspace lists · ค้นหา · filter เวลา · join ด้วย link | §10.2 | ⬜ |
| FE-LITE-07 | P1 | Notification | แตะกระดิ่ง | หน้าเต็มจอ All / Unread · Mark as read · กลุ่ม Today / Yesterday · ยังไม่อ่าน = พื้นอ่อนกว่า | task 0.29 | ⬜ |
| FE-LITE-08 | P1 | Profile + สถานะ 4 แบบ | แท็บ Profile → เปลี่ยนสถานะ | Active / Busy / Away / **Do not disturb** + custom status · สถานะเปลี่ยนบนเครื่องอื่นด้วย | §10.6 ข้อ 5 | 🎨 แถว DND |
| FE-LITE-09 | P1 | Setting ตามสิทธิ์ | เข้า Setting ด้วย Member และ Owner/Admin | Member ไม่เห็น Manage member / Environment · Owner/Admin เห็น | §10.6 ข้อ 6 | ⬜ |
| FE-LITE-10 | P1 | Switch workspace / Log out | กดจาก Profile | Switch กลับ Space builder · Log out ล้าง session และลบ push token ของเครื่อง | task 0.30, 1.8 | ⬜ |
| FE-LITE-11 | P1 | ฟีเจอร์ที่ยังไม่มีถูกซ่อน | ไล่ดู Lite Home, Spatial, Meeting, Profile | ไม่มีทางเข้า Tarot, Participation Dashboard, Quiz / Poll, AI Meeting Summary, Meeting alert · ไม่มีคำว่า Coming soon ที่ไหนเลย | §19.7 | ⬜ |
| FE-LITE-12 | P1 | Calendar ซ่อนทุกที่ | ดูแท็บล่าง, ปุ่มกลม Spatial, Notification settings | ไม่มี Calendar ทั้ง 3 จุด | §10.6 ข้อ 7 | ⬜ |
| FE-LITE-13 | P1 | แตะสมาชิก / แตะ Circle ใน Lite | แตะคนในรายชื่อ (คนว่าง และคนที่อยู่ในห้อง) · แตะ Circle | sheet โปรไฟล์มี Message / Wave · คนที่อยู่ในห้องมี Join ด้วย · ไม่มี Follow · แตะ Circle ได้ sheet "Join Circle" → เข้า Circle ได้ 🎨 | §22.2 · task 0.59 | ⏸️ |
| FE-LITE-14 | P0 | ลบบัญชีในแอป (HP-01) | Profile → Account → Delete account · กรอก Password 2 ช่อง + ติ๊ก → Delete account → Delete anyway | ปุ่มกดไม่ได้จนกรอกครบ + ติ๊ก · sheet บอก Register date, Workspace own และใครเป็นเจ้าของต่อ · ลบแล้วไปหน้า "Goodbye for now" · ได้อีเมล "Account deleted" · login ด้วยบัญชีเดิมไม่ได้ | §20.7 · SC-ACC-DEL-01 | ⬜ |
| FE-LITE-15 | P1 | DM กับบัญชีที่ถูกลบ | เปิด DM กับคนที่ลบบัญชีไปแล้ว | เห็นข้อความเก่า ชื่อเป็น "Deleted User" · ช่องพิมพ์ปิด ขึ้น "This account has been deleted" 🎨 | §20.6 | ⏸️ |
| FE-LITE-16 | P2 | หน้าว่าง | workspace ที่ไม่มีแชท / ไม่มี notification · ค้นหาคำที่ไม่มี | "No conversations yet" + ปุ่ม Start a new chat · "You're all caught up" · "No results for "<คำค้น>"" · "No threads yet" 🎨 | §22.3 | ⏸️ |
| FE-LITE-17 | P1 | แก้โปรไฟล์ + เลือกตัวละคร | Profile → การ์ดสถานะ → แก้ชื่อ รูป status → Save · Change character | Save กดได้เมื่อแก้ · toast "Profile updated" · รูปใหม่ขึ้นทุกที่ · เลือกตัวละครแล้วตัวบนแมพเปลี่ยน 🎨 | §22.3 · task 0.61 | ⏸️ |

## FE-VO · Spatial Mode บนแมพ (HP-03 · task 0.3–0.7)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-VO-01 | P0 | joystick | ลาก joystick ซ้ายล่าง | avatar เดินตามทิศ · ขนาด 128×140 | task 0.3 | ⬜ |
| FE-VO-02 | P0 | tap-to-walk | แตะพื้นแมพ | avatar เดินไปจุดนั้น · ไม่สับสนกับการลาก / pinch | task 0.4 | ⬜ |
| FE-VO-03 | P1 | pinch zoom / pan | ใช้ 2 นิ้ว | zoom ได้ ไม่ทำให้เดิน | task 0.4 | ⬜ |
| FE-VO-04 | P1 | HUD | ดูหน้าจอ | ปุ่มกลมขวาบน 4 ปุ่ม (weather, megaphone, members, notifications) · chat ซ้ายล่าง · minimap 169×100 ขวาล่าง · Meeting Menu กลางล่าง | §3.9 | ⬜ |
| FE-VO-05 | P0 | นั่งเก้าอี้ / เข้า zone / private zone | เดินไปนั่งและเข้า zone | ทำได้เหมือน desktop · คนบนเครื่องอื่นเห็นตรงกัน | spec SC-MOB-04 | ⬜ |
| FE-VO-06 | P1 | wave / knock / follow | ใช้กับคนอื่นจากมือถือ | ทำงานเหมือน desktop · มี haptic | spec SC-MOB-04, task 1.10 | ⬜ |
| FE-VO-07 | P1 | แชทแนวนอน | กดปุ่มแชท | overlay 2 คอลัมน์ทับแมพ · แมพยังเคลื่อนไหว | §9.6 ข้อ 6 | ⬜ |
| FE-VO-08 | P1 | Profile / Notification / Workspace lists แนวนอน | กดปุ่มกระดิ่งบนแมพ · แตะพื้นที่ข้างนอก | Notification เป็น drawer กว้าง 390 สูงเต็มจอ เลื่อนจากขวา · Mark all as read อยู่แถวเดียวกับแท็บ All / Unread ชิดขวา · แตะข้างนอกแล้วปิด · Profile เต็มจอมีปุ่ม × 🎨 | §10.6 ข้อ 4, §19.2 | ⏸️ |
| FE-VO-09 | P1 | Lite user บนแมพ (ดูจาก Spatial/desktop) | ให้อีกคนเข้า Lite | ไม่เห็น avatar ของคน Lite จนกว่าเขาจะเข้า meeting · เข้าแล้ว avatar โผล่ที่จุดเกิดแล้วเดินไปห้อง | TD §16.2 | ⬜ |

## FE-MEET · Meeting (HP-04 · task 0.8, 0.17–0.20, 0.45)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-MEET-01 | P0 | เข้า meeting จาก Lite | แตะการ์ดห้องใน In meeting | sheet Join meeting → Join → หน้า Meeting | §8.2 | ⬜ |
| FE-MEET-02 | P0 | Instant meeting | กด Instant meeting | เปิด meeting ห้องว่าง · ไม่มีห้องว่าง → sheet "All rooms are busy" | §8.2 | ⬜ |
| FE-MEET-03 | P0 | เข้า meeting จาก Spatial ด้วยการแตะห้อง | แตะในห้อง meeting จากนอกห้อง | modal Join meeting · Join → avatar เดินเข้าห้องเอง → เข้า meeting · Cancel = อยู่ที่เดิม | §8.6 ข้อ 10 | ⬜ |
| FE-MEET-04 | P1 | แตะห้องตอนอยู่ในห้องแล้ว / แตะนอกห้อง | แตะพื้นในห้องที่อยู่ / แตะพื้นที่อื่น | ไม่เปิด modal · แตะที่อื่น = เดินไป | §8.6 ข้อ 10 | ⬜ |
| FE-MEET-05 | P0 | layout tile ตามจำนวนคน | 1, 2, 3, 4–5, 6, > 6 คน ทั้ง 2 แนว | ตรงตาราง §8.2 · > 6 มีลูกศรเลื่อนหน้า | §8.2 | ⬜ |
| FE-MEET-06 | P1 | ชื่อ meeting | เข้า meeting ที่มีชื่อ | header แสดงชื่อ meeting แทนชื่อห้อง | §8.6 ข้อ 1 | ⬜ |
| FE-MEET-07 | P1 | แตะ 1 ครั้งซ่อนเมนู · double-tap ขยาย | แตะหน้าจอ / แตะ tile 2 ครั้ง | เมนูบนล่างเลื่อนหาย · double-tap tile ขยายเต็มจอ (ใช้กับจอแชร์ด้วย) | §8.6 ข้อ 7 | ⬜ |
| FE-MEET-08 | P0 | เปิด/ปิด cam mic | กดปุ่มใน Meeting Menu | สถานะเปลี่ยนทั้งเครื่องตัวเองและคนอื่น · มี haptic · เปิดกล้องแล้วมีปุ่มสลับกล้องหน้า/หลัง | §8.2, task 0.8 | ⬜ |
| FE-MEET-09 | P1 | emoji / ยกมือ | กด emoji / ยกมือ | emoji ลอยบน tile · ยกมือ = กรอบเหลือง + ✋ + เลขคิว | §8.2 | ⬜ |
| FE-MEET-10 | P1 | ย่อเป็นจอเล็ก (PIP) แนวตั้ง | กดลูกศรลง | tile 168×158 ลอยบน Lite Home ตำแหน่งตายตัว **ลากไม่ได้** · สลับไปคนที่พูด · แตะกลับเต็มจอ · เสียงไม่หลุด | §8.6 ข้อ 9 | ⬜ |
| FE-MEET-11 | P1 | PIP แนวนอน | กดลูกศรลงใน Spatial | tile อยู่ขวาล่าง **เหนือ minimap** (minimap ไม่หาย) 🎨 ตำแหน่งรอยืนยัน | §8.2 PIP | ⬜ |
| FE-MEET-12 | P0 | ห้องล็อก → ขอเข้า | ขอเข้าห้องล็อก (ทั้งจาก Lite และ Spatial) | ปุ่ม Request to join · คนในห้องเห็น toast "Someone is requesting to join your meeting." (ไม่มีชื่อ) · Accept ใน Requesting list แล้วผู้ขอเข้าห้องได้ · Deny แจ้งผู้ขอ 🎨 | §8.8.4 | ⏸️ |
| FE-MEET-13 | P1 | ตั้งค่าห้อง | แตะชื่อห้อง / settings ใน Join sheet | bottom sheet 3 เมนู **Voice output · Camera filter · Invite** · ไม่มี Room name 🎨 | §8.6 ข้อ 2 | ⏸️ |
| FE-MEET-14 | P1 | ชวนคนผ่านแชท | Participants → Invite → แท็บ Chat · แตะกลางแถว 2 คน → Send link in chat | แตะตรงไหนของแถวก็ติ๊กได้ · ปุ่มนับ (2) · ทั้ง 2 คนได้ DM ลิงก์ห้อง · รายชื่อ online ที่ไม่อยู่ในห้องขึ้นก่อน แล้วตามด้วย offline 🎨 | §8.8.3 | ⏸️ |
| FE-MEET-15 | P1 | แชร์จอบนมือถือ | กดปุ่มแชร์จอ | รอบแรก: ปุ่มกดไม่ได้ + tooltip · ดูจอที่คนอื่นแชร์ได้ปกติ | §8.6 ข้อ 5 | ⬜ |
| FE-MEET-16 | P2 | แบตต่ำ | แบต < 20% ระหว่างประชุม (แอป) | toast "Low battery. Charge to stay connected." | §8.2 | ⬜ |
| FE-MEET-17 | P0 | เสียงไม่หลุดเมื่อสลับแอป (iOS app) | อยู่ในประชุม ออกไปแอปอื่น 30 วิ แล้วกลับ | เสียงต่อเนื่อง · WS กลับมาภายใน 5 วิ | task 1.6–1.7 | ⬜ |
| FE-MEET-18 | P2 | grid 3×3 บน tablet | ประชุม 9 คนบน iPad | grid 3×3 🎨 | task 0.45 | ⏸️ |
| FE-MEET-19 | P1 | Participants sheet | แตะปุ่ม `Users` บน header | หัว "Participants (N)" + ปุ่ม Invite · host อยู่บนสุดพร้อมมงกุฎ · ที่เหลือเรียงตามลำดับที่เข้า · host ออกแล้วมงกุฎย้าย · ท้ายแถวมีไอคอนไมค์ 🎨 | §8.8.2 | ⏸️ |
| FE-MEET-20 | P1 | host ปิดไมค์คนอื่น | host กดไมค์ท้ายแถวของคนที่เปิดไมค์ | ไมค์คนนั้นปิด · กดเปิดไมค์ให้คนอื่นไม่ได้ · คนที่ไม่ใช่ host เห็นแค่ไอคอน กดไม่ได้ 🎨 | §8.8.2 | ⏸️ |
| FE-MEET-21 | P1 | Mute all / Kick | host กด Mute all · host กด ⋯ → Kick | ทุกคนยกเว้น host ถูกปิดไมค์ · คนที่ถูก Kick ออกจากห้อง · คนที่ไม่ใช่ host ไม่เห็นปุ่ม Mute all และ ⋯ 🎨 | §8.8.2 | ⏸️ |
| FE-MEET-22 | P1 | toast คำขอ + Requesting list | 1 คนขอเข้า แล้ว 3 คนขอพร้อมกัน · แตะ toast | 1 คน: "Someone is requesting…" · 3 คน: toast เดียว "3 people are requesting…" · หายใน 5 วิ · ตัวเลขบนไอคอน `Users` ค้าง · แตะแล้วไป Requesting · มีคนกด / ผู้ขอยกเลิก → แถวหายทุกเครื่อง · แนวนอน toast อยู่บนกลางจอ 🎨 | §8.8.4 | ⏸️ |
| FE-MEET-23 | P1 | แท็บ Invite ตาม role | เปิด Invite ด้วย Owner / Admin / Member | Owner, Admin เห็นแท็บ Chat / Link / Email · Member เห็นแค่เนื้อหา Chat ไม่มีแถบแท็บ 🎨 | §8.8.3 | ⏸️ |
| FE-MEET-24 | P1 | แท็บ Link + วันหมดอายุ | Owner กด Copy link · เปิด toggle Set expiry date เลือกวัน · เปิดลิงก์หลังวันหมดอายุ | toast "Invite link copied" · ลิงก์พาเข้า workspace (`/join/…`) · หลังหมดอายุเปิดไม่ได้ · ค่าที่ตั้งตรงกับบนเว็บ 🎨 | §8.8.3 | ⏸️ |
| FE-MEET-25 | P1 | แท็บ Email หลายอีเมล | พิมพ์ 3 อีเมลคั่นด้วย Enter / comma / เว้นวรรค + 1 อีเมลผิดรูปแบบ → Send invite | ขึ้นเป็น chip · อีเมลผิดรูปแบบถูกเตือน · ทั้ง 3 คนได้อีเมลเชิญเข้า workspace เป็น Member 🎨 | §8.8.3 | ⏸️ |

## FE-CHAT · Chat (HP-05 · task 0.21–0.27, 0.37)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-CHAT-01 | P0 | รายการแชท + ห้องแชท | แท็บ Chat | list เต็มจอ (tab All / Channel / Group / DM) → แตะเข้าห้องเต็มจอ | §9.2 | ⬜ |
| FE-CHAT-02 | P0 | ส่งข้อความ / รับข้อความ | ส่งระหว่าง 2 เครื่อง | ได้รับทันที | §9.2 | ⬜ |
| FE-CHAT-03 | P1 | คีย์บอร์ดดันข้อความล่าสุดขึ้น | เปิดคีย์บอร์ด | ข้อความล่าสุดยังเห็น ไม่ถูกบัง | §9.6 ข้อ 7 | ⬜ |
| FE-CHAT-04 | P1 | กดค้างข้อความ | long-press | overlay + emoji 7 ตัว + เมนู Reply / Thread / Copy / Pin / Forward / Select / Delete | task 0.22 | ⬜ |
| FE-CHAT-05 | P1 | Forward / Select | เลือก Forward / Select | ส่งต่อไปห้องอื่นได้ · เลือกหลายข้อความได้ | §9.6 ข้อ 3 | ⬜ |
| FE-CHAT-06 | P1 | ข้อความเสียง | กดค้างปุ่มไมค์ในช่องพิมพ์ | อัด → ส่ง → อีกฝั่งเล่นได้ · ขอสิทธิ์ไมค์ตามกติกา FE-PERM | task 0.25 | ⬜ |
| FE-CHAT-07 | P1 | mention | พิมพ์ @ | รายชื่อคนคุยบ่อย 3–4 คน (เกณฑ์ ⏳ OQ 18) · @Everyone อยู่ล่างสุด | task 0.24 | ⬜ |
| FE-CHAT-08 | P1 | ดูรูป | แตะรูปในแชท | pinch zoom · แตะซ่อน/โชว์ header · download บันทึกลง Photos | task 0.23 | ⬜ |
| FE-CHAT-09 | P1 | เมนู FAB + New group | แตะ FAB `+` · แตะ Create group · พิมพ์ชื่อ เลือก 2 คน | overlay blur · FAB เป็น × · เมนู 3 ข้อ Create channel / Create group / Start a new chat ชิดขวาเหนือ FAB · New group: header กลาง · รูปและช่องชื่อเรียงกลาง ไม่มี label · "Search for member" · ไม่มีแท็กชื่อ · คนที่ติ๊กขึ้นบน · "Create group (2)" 🎨 | §22.1, §19.1 | ⏸️ |
| FE-CHAT-10 | P1 | Start a new chat | FAB → Start a new chat | รายชื่อแสดงสถานะ Active / Busy / custom / In meeting · เปิด DM ได้ | task 0.26 | ⬜ |
| FE-CHAT-11 | P1 | ✓ / ✓✓ ใน DM | ส่ง DM แล้วให้อีกฝั่งอ่าน | ✓ ส่งแล้ว → ✓✓ อ่านแล้ว | task 0.27 | ⬜ |
| FE-CHAT-12 | P0 | ส่งไม่ได้ → ส่งซ้ำเอง | ตัดเน็ตแล้วส่งข้อความ | bubble กำลังส่ง (หมุน) · ส่งซ้ำเอง 5 ครั้ง (1/2/4/8/16 วิ) · เน็ตกลับระหว่างนั้นส่งสำเร็จ · **ไม่เกิดข้อความซ้ำ** | task 0.37 | ⬜ |
| FE-CHAT-13 | P0 | ส่งไม่สำเร็จครบ 5 ครั้ง | ตัดเน็ตนาน > 31 วิ | bubble "Not sent · Tap to retry" + sheet "Message not sent" · แตะส่งใหม่ได้ · ไม่มีคิวออฟไลน์ | §14.6 ข้อ 4 | ⬜ |
| FE-CHAT-14 | P1 | Chat info กลุ่ม | แตะชื่อห้องที่ header ของกลุ่ม | หน้าเต็มจอ avatar + ชื่อ + "Group · N members" · ปุ่ม Mute / Search / Leave · แท็บ Members · Media · Files · Links · Threads · Pinned เลื่อนได้ · ข้อมูลแต่ละแท็บตรงกับเว็บ 🎨 | §9.8 | ⏸️ |
| FE-CHAT-15 | P1 | เลื่อนหน้า Chat info | เลื่อนลงในแท็บ Media | หัวและแถวปุ่มเลื่อนหาย · แถบแท็บติดบนสุด · ชื่อกลุ่มอยู่บน header · กด Leave แล้วมีหน้ายืนยัน 🎨 | §9.8 | ⏸️ |
| FE-CHAT-16 | P1 | สมาชิกและสิทธิ์ | เปิด Members ด้วย Owner และ Member · แตะสมาชิก | ใต้ชื่อเป็นสถานะ presence · ป้าย owner / admin · Owner เห็น Edit + Make admin / Remove · Member ไม่เห็นเมนูจัดการ · Add members ตามสิทธิ์เว็บ 🎨 | §9.8 | ⏸️ |
| FE-CHAT-17 | P2 | Chat info ของ DM | แตะชื่อใน DM | ไม่มีแท็บ Members · ปุ่มเหลือ Mute + Search · ไม่มี Leave / Edit 🎨 | §9.8 | ⏸️ |

## FE-PUSH · Push notification ฝั่งเครื่อง (HP-08 · task 0.34, 1.8, 2.5, 2.6)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-PUSH-01 | P0 | ได้ push ตอนแอปอยู่ background / ปิด | อีกคนส่ง DM / mention | push ขึ้น · เนื้อหาเป็นข้อความจริง + ชื่อห้อง + ชื่อ workspace | §12.5 ข้อ 4 | ⬜ |
| FE-PUSH-02 | P0 | แตะ push DM / mention | แตะ push | เปิดแอปเข้าห้องแชทนั้นตรง ๆ | §12.5 ข้อ 4 | ⬜ |
| FE-PUSH-03 | P1 | แตะ push broadcast / weather | แตะ push | เปิดแอปเฉย ๆ (หน้าเฉพาะรอ subtask อื่น) | §12.5 ข้อ 9 | ⬜ |
| FE-PUSH-04 | P1 | แอปเปิดอยู่ | ได้ notification ตอนใช้แอป | ไม่ขึ้น push ของระบบ · ขึ้น banner ในแอปแทน | §12.5 ข้อ 9 | ⬜ |
| FE-PUSH-05 | P1 | badge บนไอคอนแอป | มีแชทยังไม่อ่าน + notification ยังไม่อ่าน | ตัวเลข = รวม 2 อย่าง · อ่านแล้วลดตาม | §12.5 ข้อ 10 | ⬜ |
| FE-PUSH-06 | P0 | สวิตช์เดียวต่อแถว = push | ปิดสวิตช์ Messages ในหน้า Notification settings | ไม่ได้ push ข้อความใหม่ · ยังเห็นในหน้า Notification ในแอป · หน้าตั้งค่ามีสวิตช์เดียว 48×24 + คำอธิบายทุกแถว | §19.3 | ⬜ |
| FE-PUSH-07 | P1 | ยังไม่อนุญาต notification | ปฏิเสธตอนแรก แล้วเปิด Notification settings | banner + ปุ่ม Allow notifications · สวิตช์ Push กดไม่ได้ · กด Allow → ไป Settings ของเครื่อง · กลับมาแล้ว banner หายถ้าอนุญาตแล้ว | §12.6 | ⬜ |
| FE-PUSH-08 | P1 | สวิตช์ใหม่ | ดู Notification settings | มี Hide chat during meetings · Mute chat sounds in meetings · Pet sounds · Environment sounds พร้อมคำอธิบาย · ไม่มีกลุ่ม Calendar 🎨 | §12.5 ข้อ 8, §19.3 | ⏸️ |
| FE-PUSH-09 | P1 | logout แล้วไม่ได้ push | logout แล้วให้อีกคนส่ง DM | เครื่องนี้ไม่ได้ push | task 1.8 | ⬜ |
| FE-PUSH-10 | 🔜 | Meeting reminder 15 นาที | — | รอฟีเจอร์ Calendar | §12.5 ข้อ 5 | ⏸️ |

## FE-PERM · สิทธิ์กล้องและไมค์ (HP-09 · task 0.35, 1.14)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-PERM-01 | P0 | ขอสิทธิ์ตอนกดปุ่ม | กดปุ่มกล้องครั้งแรก (Lite และ Spatial) | sheet "Turn on your camera" (Continue / Not now) → Continue → dialog ระบบ · ไม่มีการขอก่อน join | §13.6 A | ⬜ |
| FE-PERM-02 | P1 | Not now | กด Not now | ปิด sheet · กล้องยังปิด · กดครั้งหน้า sheet ขึ้นอีก | §13.6 A | ⬜ |
| FE-PERM-03 | P0 | ถูกปฏิเสธแล้ว | ปฏิเสธใน dialog ระบบ แล้วกดปุ่มอีกครั้ง | native alert "Unable to access camera" · Settings เปิดหน้า Settings ของแอป · กลับมาแล้วต้องกดปุ่มเอง | §13.6 B | ⬜ |
| FE-PERM-04 | P1 | เครื่องหมายเตือนบนปุ่ม | หลังถูกปฏิเสธ | ปุ่มกล้อง/ไมค์มีวงกลมเหลือง ! มุมขวาบน | §13.6 C | ⬜ |
| FE-PERM-05 | P1 | ปฏิเสธทั้งคู่ | ปฏิเสธกล้องและไมค์ | ยังอยู่ในห้องได้ ฟังและดูคนอื่นได้ (ไม่มี View Only mode แยก) | clickup-spec §18 ข้อ 55 | ⬜ |
| FE-PERM-06 | P1 | mobile web | ปฏิเสธใน Safari / Chrome มือถือ | sheet คู่มือเปิดสิทธิ์ (Safari: aA → Website Settings · Chrome: แม่กุญแจ → Permissions) | §13.6 D | ⬜ |
| FE-PERM-07 | P0 | ข้อความ usage description | ดู dialog ระบบ iOS | ข้อความตาม Figma ("Zyra needs access to your camera so others can see you…") | task 1.14 | ⬜ |

## FE-CONN · เน็ตหลุด / เน็ตแย่ (HP-10, EP-02 · task 0.36, 0.40, 1.11)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-CONN-01 | P0 | เน็ตเราแย่ | ลด bandwidth ของเครื่องตัวเอง | toast "Poor connection" ล่างจอ · × ซ่อน 20 วิ | §14.6 ข้อ 1 | ⬜ |
| FE-CONN-02 | P1 | เน็ตคนอื่นแย่ | ลด bandwidth ของอีกเครื่อง | เราไม่ได้ toast · เห็น spinner บนป้ายชื่อของคนนั้น | §14.6 ข้อ 1 | ⬜ |
| FE-CONN-03 | P0 | เชื่อมต่อใหม่ไม่เกิน 5 ครั้ง | ตัดเน็ต < 31 วิ แล้วเปิด | toast Lost connection → Reconnecting... → กลับมาเองไม่ต้องรีเฟรช · ยังอยู่ meeting เดิม | §14.6 ข้อ 2 | ⬜ |
| FE-CONN-04 | P0 | เชื่อมต่อใหม่ไม่สำเร็จครบ 5 ครั้ง | ตัดเน็ต > 31 วิ | meeting ตัดจบ (ไม่มีปุ่มเชื่อมต่อใหม่) → หน้าหลัก skeleton + "Reconnecting..." ≤ 30 วิ → ต่อได้ = แสดงข้อมูลจริง · ต่อไม่ได้ = ไป Workspace list + toast "Meeting has ended due to lost connection" | §14.6 ข้อ 2, §14.8 | ⬜ |
| FE-CONN-05 | P1 | skeleton ทั้ง 2 แนว | ทำ FE-CONN-04 ใน Lite และ Spatial | Lite: header จริง + แท่ง skeleton · Spatial: พื้นแมพ skeleton + minimap skeleton + joystick ซ่อน | §14.8 | ⬜ |
| FE-CONN-06 | P1 | แอปเปิดตอนไม่มีเน็ต | เปิดแอปตอนโหมดเครื่องบิน | หน้า offline ของแอป + ปุ่ม retry (ไม่ใช่หน้า error ของ WebView) | task 1.11 | ⬜ |
| FE-CONN-07 | P1 | uplink แย่ → กล้องปิดเอง | uplink 200–500 kbps ต่อเนื่อง 10 วิ ขณะเปิดกล้อง | กล้องปิดเอง + toast "Camera turned off automatically." · ไมค์ยังเปิด · คนอื่นเห็น avatar + spinner | §16.5 | ⬜ |
| FE-CONN-08 | P1 | เน็ตกลับมาดี | uplink > 1 Mbps นาน 10 วิ | toast "Connection restored. Camera is ready." · **กล้องไม่เปิดเอง** | §16.5 ข้อ 5 | ⬜ |
| FE-CONN-09 | P1 | ปิดกล้องเองอยู่แล้ว | ปิดกล้องเองแล้วลด uplink | ไม่ขึ้น toast เรื่องกล้อง | §16.5 ข้อ 5 | ⬜ |
| FE-CONN-10 | P2 | เน็ตแย่มาก | uplink < 200 kbps | toast "Very poor connection." | §16.5 ข้อ 4 | ⬜ |
| FE-CONN-11 | P1 | EP-02 บน desktop | ทำ FE-CONN-07/08 บน desktop | พฤติกรรมเดียวกัน | §16.5 ข้อ 8 | ⬜ |
| FE-CONN-12 | P0 | session หลุด 3 แบบ | (ก) ปล่อย token หมดอายุ (ข) ลบ session จากอีกเครื่อง (ค) เปลี่ยนรหัสจากอีกเครื่อง · ทำตอนอยู่ใน meeting ด้วย | (ก) toast "Session expired — please log in again" → Get started แล้วกลับหน้าเดิมหลัง login (ข) หน้า "You've been signed out" → Get started (ค) dialog "Password changed" → Get started · ถ้าอยู่ใน meeting ออกจาก meeting ก่อน 🎨 | §21.1 · task 0.56 | ⏸️ |
| FE-CONN-13 | P1 | ปิดปรับปรุง | เปิด maintenance flag ที่ backend | หน้า "Zyra World is under maintenance" + ปุ่ม Try again · ไม่ซ้อนกับ toast offline / reconnecting · ปิด flag แล้วกด Try again กลับเข้าใช้ได้ 🎨 | §21.3 · task 0.58 | ⏸️ |

## FE-PERF · Performance fallback (EP-01 · task 0.38, 0.39, 1.15)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-PERF-01 | P1 | L1 FPS < 25 | เครื่องกลางในแมพคนเยอะ | ลดความละเอียด (DPR 1) · ไม่มี toast | §15.5 | ⬜ |
| FE-PERF-02 | P1 | L2 FPS < 21 | ต่อจาก L1 | ปิด nature / weather + toast "Visual effects reduced" | §15.5 | ⬜ |
| FE-PERF-03 | P1 | L3 FPS < 15 | ต่อจาก L2 | avatar 12 → 6 fps + ปิด Time of Day + toast "Animations reduced" | §15.5 | ⬜ |
| FE-PERF-04 | P1 | L4 simple mode | ยัง < 15 หลัง L3 (เกณฑ์ ⏳ OQ 29) | minimap ขยายเต็มจอ + avatar วงกลม / cluster + toast "Simplified map" | §15.5 | ⬜ |
| FE-PERF-05 | P1 | ลดทีละขั้นและกลับเอง | FPS ดีขึ้น > 45 นาน 30 วิ (⏳) | กลับทีละขั้น + toast ขาขึ้น · toast ทุกอันปิดเอง 10 วิ | §15.6 | ⬜ |
| FE-PERF-06 | P1 | เฉพาะมือถือ | ทำแบบเดียวกันบน desktop | ไม่มี ladder นี้ (มีแค่ fallback เดิม) | §15.5 ข้อ 8 | ⬜ |
| FE-PERF-07 | P2 | ไม่มีเมนู Performance | Profile → Setting | ไม่มีแถว Performance · ระบบลด/คืนเอฟเฟกต์เองตาม FPS อย่างเดียว | §19.8 | ⬜ |
| FE-PERF-08 | P2 | RAM ต่ำ (⏳ OQ 30) | เปิดหลายแอปจน RAM เหลือน้อย | toast "Low memory" | task 1.15 | ⏸️ |
| FE-PERF-09 | P1 | วัดผลจริง (rule 18) | iPhone 12 + Android กลาง แมพ 20 คน | บันทึก FPS ≥ 30 และ memory ≤ 200 MB ก่อน/หลัง ลงใน progress | task 0.9 | ⬜ |

## FE-SPOT · Spotlight (HP-11 · task 0.47–0.51)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-SPOT-01 | P1 | เริ่มจาก Lite | Lite Home → ปุ่ม megaphone | sheet "Start Spotlight" (Cancel / Start spotlight) · Start → นับถอยหลังบน Lite Home | §18.9 | ⬜ |
| FE-SPOT-02 | P1 | นับถอยหลัง | กด Start spotlight แล้วกด Stop ระหว่างนับ | toast "Spotlight will be started within N seconds" 5→1 ("1 second") · Stop = ยกเลิก ไม่ออกอากาศ | §18.9 | ⬜ |
| FE-SPOT-03 | P1 | เริ่มออกอากาศ | รอนับครบ | เปิดหน้า Spotlight ที่ live แล้ว + toast "Spotlight started now" 3 วิ · ไม่มีปุ่ม Play / Stop ในแถบ | §18.9 | ⬜ |
| FE-SPOT-04 | P1 | เริ่มจาก Spatial ด้วย megaphone | กด megaphone ขวาบน | avatar เดินไปจุด Spotlight เอง → หน้า Spotlight → นับถอยหลังบนหน้านั้น | §18.9 ข้อ 4 | ⬜ |
| FE-SPOT-05 | P1 | เดินเข้าจุดเอง | เดินเข้าจุด Spotlight บนแมพ | เปิดหน้า Spotlight แล้วนับถอยหลังเหมือน FE-SPOT-04 | §18.9 ข้อ 4 | ⬜ |
| FE-SPOT-06 | P1 | ออก | กด Leave ตอน live → Leave | sheet "Leave Spotlight?" (Cancel / Leave) · กลับหน้าเดิม + toast "Broadcast ended" · คนดูได้ toast เดียวกันและหน้าคนดูปิด | §18.9 | ⬜ |
| FE-SPOT-07 | P1 | ย่อ | กดลูกศรลงตอน live | ย่อเป็น PIP · ยังออกอากาศต่อ | §18.7 ข้อ 6 | ⬜ |
| FE-SPOT-08 | P1 | คนดูนอก meeting | อีกคนเริ่ม spotlight · ลองกด ✓ / กด × / ปล่อยไว้ | toast "<ชื่อ> · Spotlight is starting" มี × / ✓ และแถบ 10 วิ · ✓ เปิดหน้าคนดู · × หรือครบ 10 วิ toast หาย · ยังเข้าดูทีหลังได้จากแถว "Spotlight · Live" บน Lite Home 🎨 | §18.9 ข้อ 2 | ⏸️ |
| FE-SPOT-09 | P1 | คนดูใน meeting | อยู่ใน meeting 2 คน คนหนึ่งกด ✓ · กด Undo · กดลูกศรลง | ✓ คนเดียว ทั้งห้องเข้าดู + แถบรายชื่อคนในห้อง · Undo ทั้งห้องกลับหน้า meeting · ลูกศรลง ย่อเฉพาะเครื่องเรา เห็น PIP Spotlight บนหน้า meeting · แตะ PIP กลับ Spotlight | §18.9 ข้อ 3 | ⬜ |
| FE-SPOT-10 | P1 | ป้าย Live + ชิปตัวนับ | ดู header ตอน live 2 คนบนเวที 24 คนดู · แตะชิป | ป้าย "Live" · ชิป `Users` "2 \| 24" · แตะแล้วเปิด sheet แท็บ On stage / Viewers · Viewers ค้นหาได้ 🎨 | §18.9 ข้อ 1, §19.5 | ⏸️ |
| FE-SPOT-11 | P2 | หลายคนพูด | 2 คนขึ้นพูดพร้อมกัน | tile หลายอันแบบ meeting ไม่มีแท็บ | §18.7 ข้อ 11 | ⬜ |
| FE-SPOT-12 | P1 | สถานะห้ามเริ่ม | ตั้ง Busy / Away / Do not disturb | ปุ่ม Start spotlight กดไม่ได้ | §18.7 ข้อ 13 | ⬜ |
| FE-SPOT-13 | P2 | แชท Spotlight | กดแชทในหน้า Spotlight | หน้าเต็มจอ · ถ้าอยู่ใน meeting ด้วยมีแท็บ Spotlight / Meeting | §18.7 ข้อ 12 | ⬜ |
| FE-SPOT-14 | P1 | แนวนอน | หน้า Spotlight ใน Spatial | layout แบบหน้า Meeting แนวนอน · ⋮ เป็น modal กลางจอ 🎨 ยืนยันภาพ | §18.6 | ⬜ |
| FE-SPOT-15 | P1 | ปุ่มของคนดู | เปิดหน้าคนดูตอนไม่อยู่ และอยู่ใน meeting | ไม่อยู่ใน meeting: Chat · Speaker · Leave · อยู่ใน meeting: Undo · Chat · Speaker · Leave · ไม่มี emoji และ raise hand | §18.9 | ⬜ |
| FE-SPOT-16 | P2 | แถวในรายชื่อ Spotlight | เปิดรายชื่อด้วยบัญชีคนดู แล้วด้วยบัญชีคนบนเวที | ไม่มี Requesting · แถวคนดูไม่มีอะไรท้ายแถว · ไอคอนไมค์ของคนบนเวทีเห็นเฉพาะตอนเราอยู่บนเวที และกดไม่ได้ 🎨 | §19.5 | ⏸️ |
| FE-SPOT-17 | P1 | เมนู More | กด ⋮ ในหน้า Spotlight ทั้งแนวตั้งและแนวนอน · กด Invite | มี Emoji · Chat · Setting · Invite ทั้ง 2 แนว · ไม่มี Start / Stop และ raise hand · Invite เปิด Invite sheet แท็บ Chat | §18.9 ข้อ 5 | ⬜ |
| FE-SPOT-18 | P1 | Spotlight เต็ม | ทุกจุด Spotlight บนชั้นมีคนพูดแล้ว กด Start spotlight | sheet "Spotlight is full" + Done · ไม่เริ่มออกอากาศ | §18.9 ข้อ 7 · task 0.54 | ⬜ |
| FE-SPOT-19 | P2 | PIP รวม + minimap | อยู่ทั้ง meeting และดู Spotlight แล้วกลับ Lite Home / แมพ · แล้วออกจาก Spotlight เหลือแค่ meeting | PIP รวม 168×100 "Spotlight \| Meeting" · บนแมพ minimap ซ่อนระหว่างมี PIP Spotlight / PIP รวม และกลับมาเมื่อเหลือแค่ PIP meeting (อยู่เหนือ minimap) · แถบล่างบนแมพคุมแค่ meeting ของตัวเอง | §18.9 ข้อ 11 | ⬜ |
| FE-SPOT-20 | P1 | คนดูใน meeting กด Leave | ดู Spotlight พร้อมห้อง แล้วกด Leave | ออกจากทั้ง Spotlight และ meeting กลับ Home · คนอื่นในห้องยังดูต่อ | §18.9 ข้อ 10 | ⬜ |

## FE-EDGE · หน้า desktop only / Safari (EC-01, EC-02)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-EDGE-01 | P1 | เปิดหน้า admin / editor บนมือถือ | เปิด URL `/admin/...`, map editor, workspace editor | ไปหน้า Space builder + toast "This page is available on desktop only." · ไม่ crash · ไม่มีหน้า QR | §19.6 | ⬜ |
| FE-EDGE-02 | P1 | ไม่มีทางเข้าหน้า admin ในแอป | ไล่ทุกเมนูในแอป | ไม่มีปุ่ม Build / Edit / Preview | screens J | ⬜ |
| FE-EDGE-03 | P2 | banner Safari | เปิดเว็บใน Safari iOS | banner แนะนำให้ใช้แอป · เตือนเสียงหลุดตอนเข้า meeting ครั้งแรก 🎨 | clickup-spec §15 | ⏸️ |
| FE-EDGE-04 | P1 | deep link 4 กรณี | แตะลิงก์เชิญ / `zyra://workspace/<id>` ตอน (ก) ยังไม่ login (ข) ยังไม่เป็นสมาชิก (ค) workspace ถูกลบ (ง) เปิดจากเว็บเครื่องที่ไม่มีแอป | (ก) Get started แล้วไปต่อที่ลิงก์หลัง login (ข) หน้ารับคำเชิญ Accept / Decline → Select mode (ค) "This link is no longer available" + Go to Space builder (ง) mobile web + banner "Open in Zyra app" 🎨 | §22.2 · task 0.60 | ⏸️ |

## FE-STORE · ก่อนส่ง store

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| FE-STORE-01 | P0 | ลบบัญชีในแอป (Apple 5.1.1(v)) | — | ⏳ รอมติ PM + UI + API | open-items §4 | ⏸️ |
| FE-STORE-02 | P0 | bundle id / ชื่อ / ไอคอน | ดูแอปบนเครื่อง | ชื่อ Zyra World · bundle id `co.zyraworld.app` · ไอคอนตัว Z 🎨 ไฟล์ไอคอน | spec OQ 3 | ⏸️ |
| FE-STORE-03 | P0 | ติดตั้งจาก TestFlight / Play internal | ติดตั้งบนเครื่องจริง | ติดตั้งและเปิดได้ · version ตรงกับ tag | task 1.12 | ⬜ |
| FE-STORE-04 | P1 | splash / status bar | เปิดแอป | status bar สี `#1A1B1E` · ไม่มีจอขาวกระพริบ | task 1.2 | ⬜ |
| FE-STORE-05 | P0 | บังคับอัปเดตแอป | ตั้ง min_version สูงกว่าแอป · ตั้ง latest สูงกว่าแต่ min ต่ำกว่า · ปิดเน็ตตอนเปิดแอป | หน้า "Update required" ปิดไม่ได้ ปุ่มพาไป store · sheet "Update available" วันละครั้ง กด Later ได้ · offline ข้ามการเช็ค · mobile web ไม่เช็ค 🎨 | §21.2 · task 0.57 | ⏸️ |

---

# ส่วน B — Backend

## BE-AUTH · login (zyra-api · task 1.4, 1.5)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| BE-AUTH-01 | P0 | Google id_token จากแอป | `POST /api/authen/login_google` ด้วย id_token ของ client iOS / Android / web | ยอมรับทั้ง 3 audience · ได้ token ใน `model.APIResponse` | task 1.4 | ⬜ |
| BE-AUTH-02 | P0 | Google token ผิด / หมดอายุ / audience อื่น | ส่ง token ไม่ถูกต้อง | 401 พร้อม envelope · ไม่สร้าง user | task 1.4 | ⬜ |
| BE-AUTH-03 | P0 | Sign in with Apple | `POST /api/authen/login_apple` ด้วย identityToken | ตรวจ JWT กับ Apple keys · ผูก user ด้วย `sub` · login ครั้งต่อไปด้วย sub เดิมได้ user เดิม | task 1.5 | ⬜ |
| BE-AUTH-04 | P1 | Apple ซ่อนอีเมล | login ด้วย private relay email | สร้าง/ผูก user ได้ · ไม่ชนกับ user อื่น | task 1.5 | ⬜ |
| BE-AUTH-05 | P1 | Apple บนเว็บ | login จากเว็บ (Services ID) | ใช้ endpoint เดียวกัน · ได้ user เดียวกับในแอป | task 1.5 | ⬜ |
| BE-AUTH-06 | P1 | cookie / session ใน WebView | login ในแอปแล้วปิดเปิดแอป | session ยังอยู่ · refresh token ทำงาน | TD §2 | ⬜ |
| BE-AUTH-07 | P0 | `DELETE /api/user/me` | ลบบัญชีตัวเองด้วยรหัสผ่านถูก / ผิด / ไม่ตรงกัน (EP-01: `invalid_password` / `password_mismatch`) · เป็นเจ้าของ workspace ที่มีสมาชิก และที่ไม่มีสมาชิก | รหัสผิด = error ไม่มีอะไรถูกลบ · ถูก = soft-delete + email hash + username `deleted-<id>` + ลบ `tb_authen` / `tb_user_avatar` · workspace โอนให้คนที่อยู่นานที่สุด · workspace ไม่มีสมาชิก = ถูกลบ · token ทุกเครื่องใช้ไม่ได้ · device token ถูกลบ · เรียกด้วย route admin ไม่ได้ | §20.4 · task 0.55 | ⬜ |
| BE-AUTH-08 | P1 | ชื่อของบัญชีที่ถูกลบ | ดึงแชท / member list ที่มีข้อความของบัญชีที่ถูกลบ | แสดง "Deleted User" + avatar ว่าง |
| BE-AUTH-12 | P0 | Google / Apple ลบด้วยรหัสอีเมล (EC-03) | `POST /api/user/me/deletion-otp` → `DELETE /api/user/me {otp}` · ลองรหัสผิด 5 ครั้ง · ขอรหัสซ้ำภายใน 1 นาที | ได้อีเมลรหัส 6 หลัก · ถูก = ลบ · ผิด = `invalid_otp` นับครั้ง · ครบ 5 = `otp_too_many_attempts` · เกิน 10 นาที = `otp_expired` · ขอซ้ำเร็วไป = 429 `otp_cooldown` · บัญชีรหัสผ่านขอรหัส = `otp_not_needed` | §20.7 | ⬜ |
| BE-AUTH-13 | P0 | ลบระหว่างอยู่ในห้องประชุม (EC-01) | ลบบัญชีจากเครื่อง A ขณะเครื่อง B อยู่ใน meeting | B ถูกออกจาก meeting ทันที (คนในห้องเห็นออก · LiveKit ตัด) · B ไปหน้า Goodbye · ไม่ค้างเป็น "away" 90 วิ | §20.7 | ⬜ |
| BE-AUTH-14 | P1 | private zone ว่างทันที | ลบบัญชีที่จอง private zone ขณะคนอื่นเปิดแมพอยู่ | zone ขึ้นว่างบนแมพคนอื่นโดยไม่ต้อง reload · ของตกแต่งของคนนั้นหาย | §20.7 | ⬜ | §20.5 ข้อ 5 | ⬜ |
| BE-AUTH-09 | P1 | Sign in with Apple revoke | ลบบัญชีที่สมัครด้วย Apple | เรียก Apple revoke token สำเร็จ · log ไม่มี token | §20.4 · task 1.5 | ⬜ |
| BE-AUTH-10 | P0 | ลบแล้วไม่กระทบคนอื่น | ลบบัญชีที่เป็นสมาชิก workspace, admin คนเดียวของกลุ่มแชท, จอง private zone และมี DM กับคนอื่น | ไม่อยู่ในรายชื่อสมาชิก workspace / กลุ่ม · กลุ่มมี admin ใหม่ (คนที่อยู่นานที่สุด) · private zone ว่าง · อีกฝ่ายยังอ่าน DM ได้แต่ส่งไม่ได้ · ข้อความเก่าขึ้น "Deleted user" | §20.6 · task 0.55 | ⬜ |
| BE-AUTH-11 | P1 | admin ลบใช้ logic เดียวกัน | admin ของระบบลบบัญชีเดียวกันจากหน้า admin | ผลเหมือน BE-AUTH-10 ทุกข้อ · admin ลบตัวเองไม่ได้ · Owner / Admin ของ workspace ไม่มีทางลบบัญชี (ทำได้แค่ Remove member) | §20.6 | ⬜ |

## BE-DEV · device token (zyra-api · task 2.1)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| BE-DEV-01 | P0 | ลงทะเบียน token | `POST /api/user/devices` {platform, fcm_token, app_version} | บันทึกลง `tb_user_device` · ตอบ envelope 200 | task 2.1 | ⬜ |
| BE-DEV-02 | P1 | token ซ้ำ | ส่ง token เดิมซ้ำ | ไม่สร้างแถวซ้ำ · อัปเดต `last_seen_at` | task 2.1 | ⬜ |
| BE-DEV-03 | P1 | token ย้าย user | login user B บนเครื่องเดิม | token ผูกกับ B ไม่ใช่ A อีก (A ไม่ได้ push บนเครื่องนี้) | task 2.1 | ⬜ |
| BE-DEV-04 | P0 | ลบ token | `DELETE /api/user/devices/{token}` (logout) | ลบแล้ว ไม่ส่ง push ไปเครื่องนี้ | task 2.1 | ⬜ |
| BE-DEV-05 | P0 | สิทธิ์ | เรียกโดยไม่มี token / เรียก token ของคนอื่น | 401 / 403 · route อยู่ใต้ `/api/user/*` (UserGuard) ไม่ใช่ `/api/admin/*` | rule 15 | ⬜ |
| BE-DEV-06 | P1 | migration | รัน migration บน dev / uat | มี `.down.sql` คู่ · rollback ได้ | rule 06 | ⬜ |

## BE-PUSH · ส่ง push (zyra-notifications, zyra-ws · task 2.2–2.6)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| BE-PUSH-01 | P0 | ส่งผ่าน FCM ทั้ง iOS และ Android | trigger DM ถึง user ที่ offline | FCM HTTP v1 ส่งถึงทั้ง APNs และ Android | task 2.3 | ⬜ |
| BE-PUSH-02 | P0 | ส่งเฉพาะคนที่ไม่ได้ต่อ WS | ผู้รับเปิดแอปอยู่ (มี connection) | ไม่ส่ง push (แอปแสดง banner เอง) | task 2.4 | ⬜ |
| BE-PUSH-03 | P0 | payload | ตรวจ payload DM / mention | มีข้อความจริง + ชื่อห้อง + ชื่อ workspace + type + id สำหรับเปิดห้อง | §12.5 ข้อ 4 | ⬜ |
| BE-PUSH-04 | P0 | เคารพสวิตช์ Push ต่อประเภท | ผู้รับปิด Push ของ DM | ไม่ส่ง push DM · ยังเก็บ notification ในแอป | task 2.5 | ⬜ |
| BE-PUSH-05 | P1 | ประเภทที่ไม่ส่ง | trigger mention in thread / weather warning / weather emergency | ไม่ส่ง push | §12.5 ข้อ 3 | ⬜ |
| BE-PUSH-06 | P1 | ประเภทที่ส่ง | DM, mention, group message, knock, wave, mic/cam request, raised hand, screen share, pet, broadcast started | ส่งครบตามตาราง | TD §6.x | ⬜ |
| BE-PUSH-07 | P1 | token ตายแล้ว | FCM ตอบ UNREGISTERED | ลบ token ออกจาก `tb_user_device` | task 2.3 | ⬜ |
| BE-PUSH-08 | P1 | badge | ส่ง push | ค่า badge = แชทยังไม่อ่าน + notification ยังไม่อ่าน | §12.5 ข้อ 10 | ⬜ |
| BE-PUSH-09 | P1 | secret | ตรวจ config | `FCM_SERVICE_ACCOUNT_JSON` มาจาก secret (ESO) · ไม่ hardcode · ไม่ log token / PII | rule 05 | ⬜ |
| BE-PUSH-10 | ⏳ | DND ปิด push ไหม | ตั้ง Do not disturb แล้วให้คนส่ง DM | ยังไม่มีมติ | — | ⏸️ |

## BE-WS · WebSocket โหมด Lite / meeting / reconnect (zyra-ws · task 0.16, 0.19, 0.48)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| BE-WS-01 | P0 | join แบบ ghost | join ด้วย `client_mode: "lite"` | presence online · ไม่มีตำแหน่ง / ที่นั่ง · ไม่ broadcast ตำแหน่ง | TD §16.2 | ⬜ |
| BE-WS-02 | P0 | ghost ส่ง move / input | ส่ง move จาก lite client | server ปฏิเสธ | TD §16.2 | ⬜ |
| BE-WS-03 | P0 | เข้า meeting ด้วย id | lite client ขอเข้า zone/meeting ด้วย id | ได้เข้า media room · คนอื่นเห็นเป็น tile | TD §16.2 | ⬜ |
| BE-WS-04 | P1 | ghost บนแมพของคนอื่น | lite เข้า meeting | broadcast `ghost_join_zone` · client แมพแสดง avatar เดินจาก spawn ไปห้อง · ออก meeting แล้ว avatar หาย | TD §16.2 | ⬜ |
| BE-WS-05 | P0 | ขอเข้าห้องล็อก (knock เดิม) | lite client ส่ง `knock` พร้อม `zone_id` | ไม่เช็คตำแหน่ง · ทุกคนได้ `knock_request` · คนในห้องคนแรกที่ส่ง `knock_decision` มีผล → ผู้ขอได้ `knock_granted` / `knock_denied` · ทุกเครื่องได้ `knock_decided` · กดพร้อมกันไม่เกิดผลซ้ำ · ขอซ้ำติด cooldown | `room.go:2504` · §8.8.4 | ⬜ |
| BE-WS-06 | P0 | grace period ≥ 31 วิ | ตัด connection แล้วต่อใหม่ภายใน 31 วิ | presence / ห้อง meeting / ที่นั่งยังอยู่ · เกิน grace แล้วถูกนำออก | TD §11.x | ⬜ |
| BE-WS-07 | P0 | backoff ฝั่ง client | ดูจังหวะ reconnect | 1, 2, 4, 8, 16 วิ รวม 5 ครั้ง | `workspace-ws.ts:82-83` | ⬜ |
| BE-WS-08 | P1 | สถานะ dnd | ตั้ง dnd | server รับค่า `dnd` · ถือว่าออกจาก meeting / circle เหมือน busy / away | `lib/presence-status.ts` | ⬜ |
| BE-WS-09 | P1 | Spotlight จาก Lite | lite client ส่ง `ws:spotlight:start` | เริ่มได้โดยไม่ตรวจตำแหน่ง · ใช้ floor แรก + marker แรก · speaker set มีผู้เริ่ม | task 0.48 | ⬜ |
| BE-WS-10 | P1 | Spotlight จาก Spatial / desktop | ส่ง start ตอนไม่ได้ยืนบน marker | ยังถูกปฏิเสธเหมือนเดิม | task 0.48 | ⬜ |
| BE-WS-11 | P1 | Spotlight ห้ามตามสถานะ | ผู้เริ่มเป็น busy / away / dnd | ปฏิเสธการเริ่ม | §18.7 ข้อ 13 | ⬜ |
| BE-WS-12 | P1 | Spotlight กับ meeting | สมาชิก meeting คนหนึ่งส่ง `ws:spotlight:meetingJoin` แล้วอีกคนส่ง `meetingLeave` | `accepted_meeting_ids` มีห้องนั้นหลัง join (ทั้งห้องเห็น spotlight) · หลัง leave ห้องหายจากรายการ · ส่งซ้ำไม่ error | §18.9 ข้อ 3 | ⬜ |
| BE-WS-13 | P1 | เข้า Circle จาก Lite | lite client ขอเข้า Circle ด้วย id | ได้เข้า Circle · คนอื่นเห็น ghost เดินจาก spawn ไปที่ Circle เหมือน meeting | §22.2 · task 0.59 | ⬜ |
| BE-WS-14 | P1 | ปิดไมค์คนอื่น | host และคนที่ไม่ใช่ host ส่ง force mute ผ่าน `ws:media:request` | host ทำได้ · คนอื่นถูกปฏิเสธ · ไม่มีคำสั่งเปิดไมค์ให้คนอื่น | `audio_test.go` ForceMute_OwnerGated · §8.8.2 | ⬜ |
| BE-WS-15 | P1 | Spotlight เต็ม | lite client ส่ง `ws:spotlight:start` ตอนจุดแรกมีคนพูด · แล้วตอนทุกจุดมีคนพูด | ได้จุดที่ว่างจุดแรก · ทุกจุดเต็ม → ปฏิเสธด้วย error เฉพาะ | task 0.54 | ⬜ |

## BE-CHAT · แชท (zyra-api, zyra-ws · task 0.25, 0.27, 0.37)

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| BE-CHAT-01 | P0 | ส่งซ้ำไม่เกิดข้อความซ้ำ | client ส่งข้อความเดิมซ้ำ (retry 5 ครั้ง) ด้วย client message id เดิม | เก็บแค่ 1 ข้อความ · ทุก retry ได้ผลลัพธ์เดียวกัน | task 0.37 | ⬜ |
| BE-CHAT-02 | P1 | ข้อความเสียง | upload ไฟล์เสียง | เก็บใน R2 ผ่าน `storage.S3Client` (ไม่เก็บบน disk) · บันทึก URL · จำกัดขนาด / ความยาว · content-type ถูก | task 0.25, rule 11 | ⬜ |
| BE-CHAT-03 | P1 | read receipt DM | อีกฝั่งอ่าน DM | ส่ง read state ให้ผู้ส่ง (✓✓) | task 0.27 | ⬜ |
| BE-CHAT-04 | P1 | Forward | ส่งต่อข้อความไปห้องอื่น | ข้อความใหม่ในห้องปลายทาง · เช็คสิทธิ์ผู้ส่งในห้องปลายทาง | task 0.22 | ⬜ |
| BE-CHAT-05 | P1 | สร้าง Group / Channel | สร้างจากมือถือ | ใช้ API เดิมของ desktop ได้ครบ | §9.6 ข้อ 1 | ⬜ |

## BE-API · ทั่วไป

| ID | P | กรณี | ขั้นตอน | ผลที่คาด | ref | สถานะ |
|---|---|---|---|---|---|---|
| BE-API-01 | P0 | health / version | `GET /api/health` หลัง deploy | 200 · version ตรงกับ tag | rule 06 | ⬜ |
| BE-API-02 | P0 | endpoint ของ member | ไล่ endpoint ที่แอปมือถือเรียก | อยู่ใต้ `/api/user/*` หรือ `/api/objects` ทั้งหมด · ไม่มี `/api/admin/*` | rule 15 | ⬜ |
| BE-API-03 | P1 | response envelope | ทุก endpoint ใหม่ | ใช้ `model.APIResponse` | rule 02 | ⬜ |
| BE-API-04 | P1 | notification settings | บันทึกสวิตช์ push จากมือถือ | เก็บฝั่ง server · ใช้ร่วมกับ desktop · ค่า in-app เดิมไม่ถูกเปลี่ยน | task 2.5 · §19.3 | ⬜ |
| BE-API-05 | P0 | ลบบัญชี (Apple 5.1.1(v)) | — | ⏳ รอมติ PM (ลบจริงหรือ anonymize, workspace ที่เป็น owner) | open-items §4 | ⏸️ |
| BE-API-06 | P1 | `GET /api/app/config` | เรียกโดยไม่ login · เปลี่ยนค่า env แล้ว restart pod | คืน min / latest version + store url ของ iOS และ Android · เปลี่ยนค่าได้โดยไม่ต้อง build image ใหม่ | §21.2 · task 0.57 | ⬜ |

---

## สรุปจำนวน

| ส่วน | กลุ่ม | จำนวน case | blocked ตอนนี้ |
|---|---|---|---|
| Frontend | ENV 17 · ONB 16 · MODE 10 · LITE 17 · VO 9 · MEET 25 · CHAT 17 · PUSH 10 · PERM 7 · CONN 13 · PERF 9 · SPOT 20 · EDGE 4 · STORE 5 | 179 | 37 (รอ UI 🎨 / รอมติ ⏳ / Phase หลัง 🔜) |
| Backend | AUTH 11 · DEV 6 · PUSH 10 · WS 15 · CHAT 5 · API 6 | 53 | 2 |
| **รวม** | | **232** | **39** |

## สิ่งที่ยังไม่อยู่ในรายการนี้

- **Unit test ของ dev** (Vitest / Go testify ตาม rule 04) — dev เขียนคู่กับแต่ละ task ไม่ใช่งาน QA
- **ค่า px / สีตาม Figma** — ตรวจกับ ux-ui-plan ตอน design review ไม่ได้ใส่เป็น case แยก
- **รายการที่รอ UI หรือรอมติ** — จะเติมขั้นตอนละเอียดเมื่อได้คำตอบ ดู [open-items.md](open-items.md)
