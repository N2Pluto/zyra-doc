# เครื่อง tester ค้างทั้งระบบ (จอดำ + เสียงซ่า) ขณะเดินใน VO บน Chrome

> สถานะ: รอหลักฐานจากเครื่องผู้รายงาน · วันที่: 2026-09-23 · repo ที่กระทบ: ยังไม่ระบุ (ประเมินว่าไม่ใช่โค้ด Zyra)
> ผู้รายงาน: Joe (Game tester) · เจอแล้ว 2 ครั้ง — ล่าสุด 2026-09-16 ที่ office, ก่อนหน้านั้นราว 1 สัปดาห์

## อาการที่ผู้ใช้รายงาน

กำลังเดินใน Virtual Office ผ่าน Chrome อยู่ดี ๆ **laptop ค้างทั้งเครื่อง** จอดำทั้งจอ มีสี่เหลี่ยมหนึ่งบล็อกที่ข้างในเป็นเส้นแนวนอนสีแดงคล้าย graphic garbage (ตำแหน่งไม่ซ้ำกันใน 2 ครั้ง) และ **ลำโพงมีเสียงซ่า** ต้องกดปิดเครื่อง

## ข้อมูลเครื่องและสภาพแวดล้อม

| รายการ | ค่า |
|---|---|
| Device | JoeInfinite — Intel Core 5 210H, RAM 16 GB |
| GPU | NVIDIA GeForce RTX 3050 6GB Laptop + Intel Graphics (hybrid) |
| Storage | ใช้ไป 378 / 477 GB |
| OS | Windows 11 Home Single Language 25H2, build 26200.9457 (ติดตั้ง 2025-11-14) |
| Browser | Chrome 152.0.7977.83 (Official Build) 64-bit — เวอร์ชันเดียวกันทั้ง 2 ครั้ง |
| Power | **เสียบสายชาร์จอยู่ทั้ง 2 ครั้ง** |
| แอปที่เปิดร่วม | Chrome (Zyra, Google Calendar, FigJam), VS Code, SourceTree, Discord |

## การประเมิน (ยังไม่มี log จากเครื่องจริง)

**สรุป: น่าจะเป็น GPU/driver hang ระดับระบบบนเครื่อง ไม่ใช่บั๊กในโค้ด Zyra — Zyra เป็นได้แค่ตัวกระตุ้นจากโหลด GPU ที่ต่อเนื่อง**

เหตุผล:

- จอดำทั้งเครื่อง + เสียงซ่าเป็นลายเซ็นของ kernel-level hang — CPU หยุด service audio buffer จึงลูปเสียงเดิม, GPU หยุด scan-out จอ แท็บเว็บทำแบบนี้ไม่ได้ เพราะ Chrome แยก GPU process ไว้ใน sandbox ถ้า WebGL ของ Zyra พังจริง อย่างมากคือแท็บ "Aw, Snap" หรือ `webglcontextlost` แล้ว Chrome กู้เอง
- บล็อกเส้นแดงตำแหน่งสุ่มคือ garbage ใน framebuffer/VRAM ตอน driver ตาย ไม่ได้มาจาก render logic ฝั่งเรา
- เครื่องเป็น hybrid graphics (Intel iGPU + RTX 3050) ซึ่งเป็นกลุ่มที่เจอ display driver hang บ่อยที่สุด และทั้ง 2 ครั้งเสียบสายชาร์จ → GPU boost แรงและร้อนกว่าตอนใช้แบต
- ฝั่ง Zyra: PixiJS v8 บน WebGL (`antialias: false`, resolution = devicePixelRatio) ที่ `zyra-app/zyra-engine/pixi-game/scene.ts` (`app.init`) และ LiveKit ที่ใช้ hardware video decode/encode ผ่าน WebRTC — ทั้งคู่กด GPU ต่อเนื่องแต่เป็น API มาตรฐาน ไม่มี path ที่ทำให้ระบบค้างได้เอง

## หลักฐานที่ต้องเก็บจากเครื่อง Joe (ก่อนสรุป root cause)

1. **Event Viewer** → Windows Logs → System ช่วงเวลาที่ค้าง หา
   - Event ID **41** Kernel-Power (เครื่องดับ/รีสตาร์ทแบบไม่ปกติ)
   - Event ID **4101** Display driver `nvlddmkm` หรือ `igfx` stopped responding and has recovered
   - **WHEA-Logger** 17 / 18 / 19 (hardware error)
   - Event ID **1001** BugCheck
2. **Reliability Monitor** (`perfmon /rel`) — ดูว่ามี hardware error / driver crash ในวันเดียวกันไหม
3. **Crash dump** — มีไฟล์ใน `C:\Windows\Minidump\` หรือ `C:\Windows\MEMORY.DMP` ไหม ถ้ามีเปิดด้วย WinDbg แล้วรัน `!analyze -v` จะบอกชื่อ driver ที่ทำให้ค้าง
4. **`chrome://gpu`** — Chrome รันบน Intel หรือ NVIDIA, ANGLE backend อะไร (D3D11 / Vulkan), Hardware video decode/encode เปิดอยู่ไหม; **`chrome://crashes`** มี GPU process crash ก่อนหน้าไหม
5. เวอร์ชัน **NVIDIA driver**, **Intel graphics driver** และ **BIOS**

## ขั้นแยกสาเหตุ (ทำทีละอย่าง ใช้งาน Zyra ต่อ 2–3 วันต่ออย่างก่อนสรุป)

| ลำดับ | ทำอะไร | ถ้าหายค้าง แปลว่า |
|---|---|---|
| 1 | อัปเดต NVIDIA driver + Intel graphics driver + BIOS จาก OEM | driver เวอร์ชันเดิมมีบั๊ก |
| 2 | Windows Settings → System → Display → Graphics → ล็อก Chrome ให้ใช้ GPU ตัวเดียว (ลอง Power saving = Intel ก่อน) | hybrid GPU switching |
| 3 | เปิด site WebGL หนักอื่น (WebGL Aquarium, Google Maps 3D) ใช้งานนาน ๆ | ถ้า **ค้างเหมือนกัน** → ยืนยันเป็นเครื่อง ไม่ใช่ Zyra |
| 4 | Chrome → Settings → System → ปิด "Use graphics acceleration when available" ชั่วคราว | ปัญหาอยู่ใน GPU driver path ของ Chrome |
| 5 | HWiNFO log อุณหภูมิ GPU/CPU ขณะอยู่ใน Zyra + ลองใช้แบตไม่เสียบสาย | thermal / power limit |
| 6 | Windows Memory Diagnostic หรือ MemTest86 | RAM/VRAM เสีย |

## สิ่งที่ Zyra ทำได้ฝั่งเรา

- ยังไม่มีอะไรต้องแก้ในโค้ดจนกว่าจะมี log ยืนยัน
- ถ้าผลจากข้อ 3 บอกว่าค้าง **เฉพาะ** ใน Zyra ให้กลับมาดูโหลด GPU ของ VO (จำนวน draw call, texture memory, video track ที่ decode พร้อมกัน) แล้วเปิดรอบใหม่ในไฟล์นี้

## ต่อจากนี้

- [ ] Joe เก็บหลักฐานข้อ 1–5 แล้วแปะผลกลับในไฟล์นี้ (`## รอบที่ 2 — YYYY-MM-DD`)
- [ ] ทำขั้นแยกสาเหตุลำดับ 1–2 ก่อน แล้วรายงานว่าเจอซ้ำอีกไหม
