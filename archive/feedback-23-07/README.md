# Feedback Triage — 23 ก.ค. 2569

สรุปและจัดหมวดหมู่ feedback batch วันที่ 23-07 (56 รายการ — UX/UI #1–44 + AI100 #45–56) พร้อมวิเคราะห์ไฟล์ที่เกี่ยวข้อง สาเหตุ และแนวทางแก้จาก codebase จริง

> เอกสารนี้แบ่ง feedback เป็น 2 กลุ่มหลักตามคอลัมน์ **Type**:
> - 🐞 **[bugs.md](bugs.md)** — ของที่ "พัง/ทำงานผิด" (Issue) — **23 รายการ**
> - 🔧 **[improvements.md](improvements.md)** — ของที่ "ต้องทำเพิ่ม/ปรับปรุง" (Improve) — **33 รายการ**

---

## ภาพรวม (Overview)

| ตัวชี้วัด | จำนวน |
|---|---|
| รวมทั้งหมด | **56** |
| 🐞 Issue (บัค) | 23 |
| 🔧 Improve (ปรับปรุง/ทำเพิ่ม) | 33 |
| Priority: High | 4 |
| Priority: Medium | 15 |
| Priority: Low | 36 |
| ไม่ระบุ Priority | 1 (#12) |

### แยกตามหมวดหมู่ (Category)

| หมวด | จำนวน | รายการ (No) |
|---|---|---|
| Chat | 14 | 11, 13, 14, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26 |
| Meeting | 11 | 4, 37, 38, 48, 49, 50, 51, 52, 54, 55, 56 |
| Avatar | 7 | 8, 9, 28, 41, 42, 45, 46 |
| Display | 6 | 1, 2, 3, 31, 43, 53 |
| Decoration | 5 | 32, 33, 34, 35, 36 |
| Object | 3 | 5, 6, 44 |
| Member | 2 | 7, 10 |
| Menu | 2 | 29, 39 |
| Sound | 1 | 12 |
| Feedback | 1 | 15 |
| Setting | 1 | 27 |
| Workspace | 1 | 30 |
| Map Template | 1 | 40 |
| Profile | 1 | 47 |

---

## ⚠️ หมายเหตุการจัดหมวด (Assumptions)

1. **#12 (Sound)** — ในตารางต้นฉบับไม่มีค่าในคอลัมน์ Type จัดเป็น **บัค (Issue)** เพราะเป็นอาการ "ได้ยินเสียงตอนคน join meeting ทั้งที่อยู่นอกห้อง" (เสียง sound effect รั่วข้ามสถานะ) → อยู่ใน [bugs.md](bugs.md)
2. **#36 (Decoration)** — ตารางต้นฉบับระบุ Type = **Improve** แต่เนื้อหาอธิบายพฤติกรรมที่ผิด (Clear all ทำตัวเป็น Undo all) จึงคงไว้ใน [improvements.md](improvements.md) ตาม Type เดิม แต่จริง ๆ เป็นการแก้บั๊กพฤติกรรม (ควรทำคู่กับ #35)
3. **#2 (Display)** — จากการตรวจ code จริง พบว่า hover-to-show-icon (ข้อ 2.2) และ no-idle-highlight (ข้อ 2.1) **ทำงานอยู่แล้ว** ช่องว่างจริงคือ Private zone ไม่ขึ้นไอคอน ซึ่งผูกกับ **#1** โดยตรง → แก้ #1 แล้ว #2 ส่วนใหญ่จบ
4. คอลัมน์ **Effort** = ประมาณการจากการอ่านโค้ด: `S` = < ครึ่งวัน, `M` = 1–2 วัน, `L` = > 2 วัน หรือข้ามหลาย service (DB/API/WS/FE)
5. คอลัมน์ **Conf.** = ความมั่นใจของการวิเคราะห์ (ไฟล์/สาเหตุถูกต้อง): high / med / low
6. **ชุด AI100 (#45–#56)** — feedback ทีม AI100 เดิมใช้เลข 1–12 (ชนกับเลข UX/UI 1–41) จึง **renumber ต่อจาก 44 เป็น #45–#56** รวมเป็น batch เดียว โดย entry แต่ละอันคงเลขเดิมของทีมไว้ในบรรทัด `Feedback เดิม (AI100 #k)` เพื่อ traceability · mapping: #45←1, #46←2, #47←3, #48←4, #49←5, #50←6, #51←7, #52←8, #53←9, #54←10, #55←11, #56←12
7. **#46 (เห็นเพื่อนลอย)** — ทับกับ item #2 ในเอกสารเก่า `zyra-doc/issues/ai100-feedback-2026-07-21.md` (เคย fix แล้ว 2026-07-21) → อาจเป็น regression/อีก vector; **#45/#46/#47** ทีม mark เป็น In-Progress
8. **#48 / #49 (Meeting)** — ทีม mark เป็น **Done** และยืนยันว่าเป็นเงื่อนไขระบบที่ตั้งใจ (by-design: knock-to-enter / In-Meeting status) จึงบันทึกเป็น context ใน [improvements.md](improvements.md) โดยไม่มีแผนแก้

---

## ตารางสรุปทั้งหมด (Master Table)

| No | หมวด | Type | Pri | Effort | Conf. | หัวข้อ |
|---:|---|:---:|:---:|:---:|:---:|---|
| 15 | Feedback | 🐞 | **High** | M | high | อีเมล feedback ไม่แนบรูป (ส่งแค่ลิงก์) |
| 1 | Display | 🐞 | Med | S | high | Private zone ไม่ขึ้นไอคอน Mic/Video ตอน hover |
| 9 | Avatar | 🐞 | Med | S | high | กด WASD/ลูกศรไม่ยกเลิกการเดินแบบ "Go to" |
| 22 | Chat | 🐞 | Med | M | med | แก้ไขสมาชิกได้ก่อนกดปุ่ม Edit |
| 33 | Decoration | 🐞 | Med | L | med | พื้นที่ว่าง (เขียว) แต่ขึ้น error "occupied" |
| 3 | Display | 🐞 | Low | M | med | ไม่มี notif เมื่อมี meeting chat + รูปโปรไฟล์ไม่ตรงตัวละคร |
| 12 | Sound | 🐞 | — | S | high | ได้ยินเสียง join meeting ทั้งที่อยู่นอกห้อง |
| 24 | Chat | 🐞 | Low | M | med | เมนู 3 จุดของข้อความค้าง ต้องกดซ้ำ |
| 25 | Chat | 🐞 | Low | M | high | เมนู 3 จุดใกล้กล่องพิมพ์ถูกตัด |
| 26 | Chat | 🐞 | Low | S | med | ข้อความรูป: ป้าย "Seen" อยู่ผิดตำแหน่ง |
| 27 | Setting | 🐞 | Low | S | med | หน้า Setting layout เลื่อน/กระเด้ง |
| 30 | Workspace | 🐞 | Low | S | high | เปิด tab sidebar ค้าง ทำให้เปิด popup แก้ชื่อ private zone ไม่ได้ |
| 37 | Meeting | 🔧 | Med | L | high | เพิ่มฟีเจอร์เตะ (kick) ออกจาก Meeting |
| 38 | Meeting | 🔧 | Med | L | high | เพิ่มปุ่มปิดไมค์ทุกคน (mute all) ยกเว้นตัวเอง |
| 39 | Menu | 🔧 | Med | L | high | ระบบแจ้งข่าว (announcement) ถึงทุกคนใน workspace |
| 11 | Chat | 🔧 | Med | S | high | Filter Sender: เพิ่ม dropdown + typeahead ค้นชื่อ |
| 29 | Menu | 🔧 | Med | M | high | Edit profile / Change Avatar เด้งออกจาก VO |
| 2 | Display | 🔧 | Low | S | med | Highlight/ไอคอนเมนูให้โผล่เฉพาะตอน hover (ผูกกับ #1) |
| 4 | Meeting | 🔧 | Low | S | med | Hover ควรมี overlay ดำให้ปุ่มเด่นขึ้น |
| 5 | Object | 🔧 | Low | M | med | selection ตอนเลือก object ไม่ชัด |
| 6 | Object | 🔧 | Low | M | med | เพิ่ม hover state ให้ object (In-Progress) |
| 7 | Member | 🔧 | Low | S | high | เมนูโปรไฟล์เพื่อน: ตัดชื่อ avatar ออกจาก label |
| 8 | Avatar | 🔧 | Low | L | high | Request to lead ไม่มี notification (ยังเป็น stub) |
| 10 | Member | 🔧 | Low | L | med | Meeting room / Circle ไม่ขึ้นเมนูห้องตาม Design |
| 13 | Chat | 🔧 | Low | S | high | แยกปุ่มแนบไฟล์ให้เลือกได้เฉพาะไฟล์ |
| 14 | Chat | 🔧 | Low | M | med | ขยาย UI preview รูปที่ส่งแล้ว |
| 16 | Chat | 🔧 | Low | S | med | เพิ่มขนาดฟอนต์ข้อความเป็น Body 14 |
| 17 | Chat | 🔧 | Low | S | high | เพิ่มขนาดรูปในบับเบิลแชท |
| 18 | Chat | 🔧 | Low | S | med | ปุ่ม Expand/Collapse ซ้ำ 2 ที่ ให้เหลือปุ่มเดียว |
| 19 | Chat | 🔧 | Low | M | high | เมนู 3 จุดของ DM เพิ่ม Image / File |
| 20 | Chat | 🔧 | Low | S | high | เพิ่ม hover highlight ที่แถวข้อความ |
| 21 | Chat | 🔧 | Low | S | high | Pinned: pin เดียวไม่แสดงขีดนำหน้า |
| 23 | Chat | 🔧 | Low | S | high | เพิ่มปุ่ม Select All ตอนเลือกสมาชิก |
| 28 | Avatar | 🔧 | Low | M | high | click-to-move ไม่ให้ลากเส้นทางทะลุ Meeting Room |
| 31 | Display | 🔧 | Low | S | high | Full view ตอน share screen ไม่มี bottom menu |
| 32 | Decoration | 🔧 | Low | S | high | เพิ่มปุ่มลัด Delete ลบ object ที่เลือก |
| 34 | Decoration | 🔧 | Low | S | high | ห้ามลบ walkable_group/กระเบื้องที่หลังบ้านวางไว้ |
| 35 | Decoration | 🔧 | Low | M | high | Clear all ต้องกดได้แม้ save แล้ว/กลับมา edit ใหม่ |
| 36 | Decoration | 🔧 | Low | M | high | Clear all หลังลบ object กลายเป็น Undo all |
| 40 | Map Template | 🔧 | Low | S | high | เปลี่ยน "โรงเรียน" → "สถานศึกษา" |
| 41 | Avatar | 🔧 | Low | L | med | เพิ่มฉายา/nickname บน name tag |
| 42 | Avatar | 🐞 | Med | M | med | เก้าอี้หันหลังชนกัน นั่งผิดตัว (ว๊าปไปตัวหลัง) |
| 43 | Display | 🐞 | Med | M | med | วาง object ชิดกำแพงแล้วทะลุ (z-order) |
| 44 | Object | 🔧 | Low | M | high | เพิ่มหมวดหมู่ object "Foods & Drink" |
| 45 | Avatar | 🐞 | Low | M | med | เดินชนตัวละครอื่นแล้วลากตัวนั้นไปด้วย *(AI100 #1)* |
| 46 | Avatar | 🐞 | Med | M | med | เห็นเพื่อนลอย *(AI100 #2)* |
| 47 | Profile | 🐞 | Med | S | high | เปลี่ยนชื่อแล้วเพื่อนเห็นไม่เปลี่ยน *(AI100 #3)* |
| 48 | Meeting | 🔧 | Low | — | — | ห้องประชุมล็อกเอง — ✅ by-design *(AI100 #4)* |
| 49 | Meeting | 🔧 | Low | — | — | สเตตัสเป็นไม่ว่างใน meeting — ✅ by-design *(AI100 #5)* |
| 50 | Meeting | 🐞 | **High** | L | med | อยู่ meeting แต่คนอื่นเห็นอยู่ข้างนอก/กล้องไม่โชว์ *(AI100 #6)* |
| 51 | Meeting | 🐞 | Med | S | high | Emoji ในแชท meeting กดไม่ได้ *(AI100 #7)* |
| 52 | Meeting | 🐞 | Low | S | high | ไม่มีโต๊ะ กดออกจาก meeting ไม่มี action *(AI100 #8)* |
| 53 | Display | 🔧 | Low | S | high | Zoom-in/out เร็วเกินไป *(AI100 #9)* |
| 54 | Meeting | 🐞 | Med | L | high | Req ปิดไมค์ ควรปิดไมค์คนนั้นจริง *(AI100 #10)* |
| 55 | Meeting | 🐞 | **High** | M | med | เสียงดีเล กลับมาได้ยินเสียงเก่า *(AI100 #11)* |
| 56 | Meeting | 🐞 | **High** | M | med | ดับเบิลคลิกเดินออก แต่ยังอยู่ในสนทนา *(AI100 #12)* |

---

## ลำดับที่แนะนำให้ทำ (Suggested Order)

**รอบที่ 1 — Quick wins (Effort S, ผลชัด):**
`#40` (แก้ i18n จุดเดียว) · `#7` · `#11` · `#20` · `#21` · `#23` · `#13` · `#17` · `#1` · `#9` · `#12` · `#30` · `#32` · `#34` · `#31` · `#47` (rename sync) · `#51` (emoji picker) · `#52` (leave meeting) · `#53` (zoom sensitivity)

**รอบที่ 2 — High/Medium priority ที่มีน้ำหนัก:**
`#15` (High — อีเมลไม่แนบรูป) · `#55`+`#56` (High — audio flush / walk-out teardown) · `#29` · `#22` · `#42` (seat resolution) · `#43` (wall z-order) · `#46` (peer floating) · `#25`+`#24` (ทำคู่กัน) · `#5`+`#6` (ทำคู่กัน) · `#35`+`#36` (ทำคู่กัน)

**รอบที่ 3 — งานใหญ่ข้าม service (Effort L):**
`#37` (kick) · `#38` (mute all) + `#54` (force-mute single target — ทำคู่กัน) · `#50` (High — meeting membership plane) · `#39` (announcement) · `#8` (request to lead) · `#41` (nickname) · `#33` (footprint collision) · `#10` (room/circle menu) · `#44` (object category — หลายจุด FE+BE) · `#45` (collision dodge)

> **ไม่ต้องทำ:** `#48` / `#49` — ทีม mark Done / by-design

---

## ที่มา (Provenance)

- **Feedback ต้นฉบับ:** batch วันที่ 22–23 ก.ค. 2569 — 2 ทีมรวมกัน (56 รายการ): **UX/UI** #1–44 + **AI100** #45–56 (ทีม AI100 renumber จากเลขเดิม 1–12) · เพิ่มชุด #42–#56 เมื่อ 2026-07-26
- **การวิเคราะห์ codebase:** สแกนอัตโนมัติ 13 หมวด (agent อ่านไฟล์จริงใน `zyra-app`, `zyra-api`, `zyra-ws`, `zyra-notifications`) — file/line ที่อ้างในเอกสารเป็นค่า ณ วันที่ตรวจ อาจเลื่อนได้เมื่อโค้ดถูกแก้ ให้ยึด "ชื่อ symbol/component" เป็นหลัก
- เอกสารนี้เป็น **การวิเคราะห์ + ข้อเสนอ** ยังไม่มีการแก้โค้ดใด ๆ
