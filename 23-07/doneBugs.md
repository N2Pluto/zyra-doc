# ✅ Done Bugs — 23-07

รวม bug จาก `bugs.md` ที่แก้ไขเรียบร้อยแล้ว

---

## แก้ไขแล้ว (จาก bugs.md)


| #          | หัวข้อ                                                            | หมวด      | Priority  |
| ---------- | ----------------------------------------------------------------- | --------- | --------- |
| [#1](#1)   | Private zone ไม่ขึ้นไอคอน Mic/Video ตอน hover                     | Display   | 🟠 Medium |
| [#9](#9)   | กด WASD/ลูกศรไม่ยกเลิกการเดินแบบ "Go to"                          | Avatar    | 🟠 Medium |
| [#12](#12) | ได้ยินเสียง join meeting ทั้งที่อยู่นอกห้อง                       | Sound     | 🟡 Low    |
| [#22](#22) | แก้ไขสมาชิกได้ก่อนกดปุ่ม Edit                                     | Chat      | 🟠 Medium |
| [#24](#24) | เมนู 3 จุดของข้อความค้าง ต้องกดซ้ำ                                | Chat      | 🟡 Low    |
| [#25](#25) | เมนู 3 จุดใกล้กล่องพิมพ์ถูกตัด                                    | Chat      | 🟡 Low    |
| [#26](#26) | ข้อความรูป: ป้าย "Seen" อยู่ผิดตำแหน่ง                            | Chat      | 🟡 Low    |
| [#27](#27) | หน้า Setting layout เลื่อน/กระเด้ง                                | Setting   | 🟡 Low    |
| [#30](#30) | เปิด tab sidebar ค้าง ทำให้เปิด popup แก้ชื่อ private zone ไม่ได้ | Workspace | 🟡 Low    |
| [#47](#47) | เปลี่ยนชื่อแล้วเพื่อนเห็นไม่เปลี่ยน (จอตัวเองเปลี่ยน)             | Profile   | 🟠 Medium |
| [#51](#51) | Emoji ในแชท meeting กดไม่ได้                                      | Meeting   | 🟠 Medium |
| [#52](#52) | ไม่มีโต๊ะ กดออกจาก meeting ไม่มี action                           | Meeting   | 🟡 Low    |
| [#55](#55) | เสียงดีเล: กลับมาแล้วได้ยินเสียงที่เรียกไว้นานแล้ว                | Meeting   | 🔴 High   |
| [#56](#56) | อยู่ meeting ดับเบิลคลิกเดินไปหาคนอื่น แต่ยังอยู่ในสนทนาเดิม      | Meeting   | 🔴 High   |


---



## แก้ไขแล้ว (bug เพิ่มเติม นอกรายการ bugs.md)


| หัวข้อ                                                  | ไฟล์ที่แก้                | รายละเอียด                                                                                                             |
| ------------------------------------------------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| ตัวละครเดินอยู่กับที่แล้ว warp (WASD path ยกเลิกตัวเอง) | `scene.ts`                | เพิ่ม `_pathFromGoto` flag แยก WASD step path กับ Go-to path ป้องกันการ cancel path ตัวเอง                             |
| Zone hover ตอนนั่งเก้าอี้ยังขึ้นชื่อ zone               | `hero-virtual-office.tsx` | แสดงชื่อ zone tooltip ได้ขณะนั่ง แต่ suppress lock/knock overlay                                                       |
| ชื่อ zone ขึ้นค้างเมื่อสถานะ Away                       | `hero-virtual-office.tsx` | ลบ away-mode zone label feature ออก (awayZoneLabelsRef + RAF loop + JSX)                                               |
| ชื่อ zone ไม่หายเมื่อเลื่อนเมาส์ออก                     | `hero-virtual-office.tsx` | แก้ world coordinate ใน `handleCanvasMouseMove` ให้อ่านจาก engine โดยตรงแทน stale React state                          |
| Debug box ตัวละครใหญ่เกินไป                             | `scene.ts`                | เปลี่ยน box จาก body-centered (ล้นใต้เท้า) เป็น sprite-aligned + foot hitbox indicator                                 |
| ตัวละครเดินช้าผ่านขอบบน locked meeting zone             | `scene.ts`                | ใช้ `wp.y - TILE_SIZE/2` ใน path processing zone lock check แทน foot-position ที่ overflow 3px เข้า zone row ถัดไป     |
| Zoom ไม่ทำงานเมื่อเมาส์อยู่บน UI overlay                | `scene.ts`                | ย้าย wheel listener จาก canvas ไป `window` + skip เมื่อ target เป็น scrollable element                                 |
| Zoom เร็วเกินไป                                         | `scene.ts`                | ลด zoom step จาก `0.1` → `0.04` ต่อ scroll click                                                                       |
| FPS วิ่งแค่ ~45 แทนที่จะเป็น 60                         | `scene.ts`                | หยุด PixiJS auto-ticker (`app.ticker.stop()`) + manual render `app.renderer.render(app.stage)` — กำจัด double RAF loop |


---



## ยังไม่ได้แก้ (จาก bugs.md)


| #          | หัวข้อ                                                                | หมวด       | Priority  | เหตุผล                                  |
| ---------- | --------------------------------------------------------------------- | ---------- | --------- | --------------------------------------- |
| [#3](#3)   | ไม่มี notif เมื่อมี meeting chat + รูปโปรไฟล์ไม่ตรงตัวละคร            | Display    | 🟡 Low    | ต้องออกแบบ UX ก่อน                      |
| [#15](#15) | อีเมล feedback ไม่แนบรูป (ส่งแค่ลิงก์)                                | Feedback   | 🔴 High   | งาน cross-service (api + notifications) |
| [#33](#33) | พื้นที่ว่าง (เขียว) แต่ขึ้น error "occupied"                          | Decoration | 🟠 Medium | งาน cross-service + BE footprint logic  |
| [#42](#42) | เก้าอี้หันหลังชนกัน นั่งผิดตัว (วาร์ปไปตัวหลัง)                       | Avatar     | 🟠 Medium | ต้อง refactor seat-resolve logic        |
| [#43](#43) | วาง object ชิดกำแพงแล้วทะลุ                                           | Display    | 🟠 Medium | ต้องแก้ z-order / wall occlusion system |
| [#45](#45) | เดินชนตัวละครอื่นแล้วลากตัวนั้นไปด้วย                                 | Avatar     | 🟡 Low    | In-Progress (ทีม)                       |
| [#46](#46) | เห็นเพื่อนลอย                                                         | Avatar     | 🟠 Medium | In-Progress (ทีม)                       |
| [#50](#50) | อยู่ meeting แต่คนอื่นเห็นตัวละครอยู่ข้างนอก / เปิดกล้องคนอื่นไม่เห็น | Meeting    | 🔴 High   | ต้องออกแบบ participant plane ใหม่       |
| [#54](#54) | Request ปิดไมค์ ควรปิดไมค์คนนั้นจริง (ตอนนี้แค่ advisory)             | Meeting    | 🟠 Medium | งาน cross-service + policy decision     |


