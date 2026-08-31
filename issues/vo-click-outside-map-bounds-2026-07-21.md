# VO Map — Click Outside Map Bounds Shows Tooltip / Allows Walk (รายงาน 21 ก.ค. 2026)

> **สถานะ:** แก้แล้ว (2026-07-21) — ยังไม่ได้ live-test จริงใน browser
> รายงานโดย: ten_dev@hpktechnology.com
> ขอบเขต: Pixi map renderer ใน Virtual Office (`zyra-app/zyra-engine/pixi-game/scene.ts`) — ไม่ใช่ Meeting feature โดยตรง จึงแยกจาก `vo-meeting-issues-2026-07-21.md`

---

## (Bug) คลิกนอกขอบเขตแผนที่ (map bounds) ยังขึ้น "Double click to move here" + เดินได้

**คำอธิบายภาษาชาวบ้าน (พร้อมภาพหน้าจอ):** ตอนกล้องมุมมองแสดงพื้นที่ว่างเกินขอบแผนที่ (เช่น มุมด้านซ้ายที่เป็นพื้นหลังมืดๆ ไม่ใช่ตัวแผนที่จริง) ถ้าคลิกในพื้นที่ว่างนั้น ระบบยังขึ้น tooltip "Double click to move here" พร้อมกรอบเขียวเลือก tile — อยากให้คลิกนอกแผนที่แล้วไม่มีอะไรขึ้นเลย

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- Click handler อยู่ที่ `onClick` ใน `zyra-engine/pixi-game/scene.ts` (~L1049 เดิม) — คำนวณ `worldX`/`worldY` จาก `_screenToWorld()` แล้วแปลงเป็น tile ทันที **โดยไม่มีการเช็คขอบเขต** ว่า `worldX`/`worldY` อยู่ในช่วง `[0, worldW)` × `[0, worldH)` หรือไม่ก่อนเลย — เป็นสาเหตุตรงๆ ของบั๊กนี้
- `this.selKey = clickKey` (บรรทัดที่ set tile selection) ถูก set ได้แม้ tile นั้นอยู่นอกแผนที่ ทำให้ `_selTooltipText` (ข้อความ "Double click to move here") และกรอบเขียว selection ขึ้นได้ทั้งที่ไม่ควร — คลิกครั้งที่ 2 บน tile เดียวกันจะเรียก `_findPath` พยายามเดินไปด้วย (แม้ pathfinding อาจจะ fail เงียบๆ เพราะ tile นอก grid แต่ UI ทั้งหมดขึ้นมาก่อนแล้ว)
- `worldW`/`worldH` มีอยู่แล้วเป็น field ของ scene (`this.worldW = worldWidth * TILE_SIZE`, เช่นเดียวกับ `worldH`) ใช้ตรวจสอบขอบเขตในหลายที่ของโค้ดอยู่แล้ว (เช่น `_clampCamera`, hit-testing อื่นๆ) — เป็น single source of truth ที่ใช้ตรวจสอบได้ตรงๆ

**✅ Fix (`zyra-engine/pixi-game/scene.ts`):**
- เพิ่ม bounds check เป็นบรรทัดแรกสุดหลังคำนวณ `worldX`/`worldY` ใน `onClick` — **ก่อน**ทุก branch อื่น (shift-click, remote-player click, locked-zone, teleport, follow-mode walk, tile selection): `if (worldX < 0 || worldY < 0 || worldX >= this.worldW || worldY >= this.worldH) return`
- วางไว้จุดนี้ (จุดแรกสุด) ทำให้คลิกนอกแผนที่เป็น **no-op เต็มรูปแบบ** — ไม่ set selection, ไม่ trigger tooltip, ไม่เดิน, ไม่ trigger shift-click/teleport/locked-zone logic ใดๆ เลย ตรงกับที่ user ขอ ("ไม่ต้องขึ้นอะไร")

**Verify:** `npx tsc --noEmit` และ `npx eslint zyra-engine/pixi-game/scene.ts` ผ่าน 0 error, dev server compile สะอาด ไม่มี console error — **ยังไม่ได้ live-test จริงใน browser** (ต้อง login เข้า workspace จริง แล้ว zoom/pan กล้องไปจนเห็นพื้นที่นอกแผนที่ แล้วคลิกดูว่าไม่มี tooltip/selection ขึ้นจริงหรือไม่)
