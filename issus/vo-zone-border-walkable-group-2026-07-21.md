# VO Zone Border — Renders In Front of walkable_group Objects (รายงาน 21 ก.ค. 2026)

> **สถานะ:** แก้แล้ว (2026-07-21) — ยังไม่ได้ live-test จริงใน browser
> รายงานโดย: ten_dev@hpktechnology.com
> ขอบเขต: Pixi map renderer ใน Virtual Office (`zyra-app/zyra-engine/pixi-game/`) — ไม่ใช่ Meeting feature โดยตรง จึงแยกจาก `vo-meeting-issues-2026-07-21.md`

---

## (Bug) กรอบสีขาวของ Active Zone เรนเดอร์อยู่หน้า object ที่เป็น Category = walkable_group

**คำอธิบายภาษาชาวบ้าน (พร้อมภาพหน้าจอ):** กรอบสีขาวที่แสดงขอบเขตของ zone ที่เราเข้าไป (private zone) ตอนนี้เรนเดอร์อยู่**หน้า** object ที่ตั้ง Category เป็น walkable_group แทนที่จะอยู่หลัง — ทำให้เส้นตัดผ่าน object แทนที่ object จะบัง/อยู่หน้าเส้น

**ขยายความเชิงเทคนิค (สำหรับ AI):**
- กรอบขาวนี้คือ `_activeZoneBorderGfx` / `_drawActiveZoneBorder()` ใน `zyra-engine/pixi-game/scene.ts` — เป็นส่วนหนึ่งของ zone-focus feature ([[vo-zone-dim-tint-rework]]: per-sprite tint + world-space floor-dim + white active-zone border)
- Render-order source of truth อยู่ที่ `zyra-engine/pixi-game/utils.ts`: `effectiveObjectSortRow()` ให้ object ประเภท `walkable_group` มี zIndex ติดลบมากๆ (≈ -30,000,000, ผ่าน `FLOOR_LAYER = 100000` คูณเข้าไปใน `encodeZ`) เพื่อให้ sort ไปอยู่ "หลังสุด" เทียบกับ object อื่นๆ **ภายใน `mainContainer`**
- **Root cause ที่แท้จริง (ยืนยันด้วยการอ่าน `scene.ts` โดยตรง, บรรทัด ~443-469 เดิม):** `worldContainer.sortableChildren = false` และ children ถูก add ตามลำดับนี้: `_floorDimGfx` → `_teleportPadGfx` → `_hoverBorderGfx` → `_activeZoneBorderGfx` → `_claimHoverGfx` → `_editGridGfx` → **`mainContainer` (เพิ่มเข้ามาลำดับสุดท้าย)** เพราะ `worldContainer` ไม่ sort, Pixi วาดตามลำดับ insertion ตรงๆ — `mainContainer` (ที่เก็บ object ทุกตัวรวมถึง walkable_group) เลยเรนเดอร์ทับทุกอย่างที่ถูก add ก่อนหน้ารวมถึง `_activeZoneBorderGfx` เสมอ **โดยไม่สนใจ zIndex ภายใน mainContainer เลย** — zIndex ติดลบมากๆ ของ walkable_group มีผลแค่กับการจัดลำดับ "ภายใน mainContainer" (หลัง object อื่น, หลัง avatar) แต่ไม่มีผลข้าม container boundary ไปถึง sibling container อย่าง `_activeZoneBorderGfx`
- มี **precedent การแก้ปัญหาแบบเดียวกันอยู่แล้ว** ในไฟล์เดียวกัน: `_chatCapsuleGfx` (comment เดิมบอกตรงๆ ว่า "lives in mainContainer with zIndex 0 so it paints ABOVE all walkable_group floor sprites (zIndex ≈ −30M) but BELOW regular objects (zIndex ≥ ~11) and avatars") — คือ ย้าย Graphics เข้าไปอยู่ใน `mainContainer` (ที่ sort ได้จริง) แล้วกำหนด zIndex ให้อยู่ระหว่าง walkable_group กับ object ปกติ

**✅ Fix (`zyra-engine/pixi-game/scene.ts`):**
- ย้าย `_activeZoneBorderGfx` จาก `worldContainer.addChild(...)` → `mainContainer.addChild(...)` (mirror `_chatCapsuleGfx` เป๊ะๆ)
- กำหนด `this._activeZoneBorderGfx.zIndex = -1` — อยู่เหนือ walkable_group (~-30M) แต่ต่ำกว่า chat capsule (zIndex 0) กันไม่ให้บัง speech bubble ถ้าเผอิญซ้อนกัน
- ยืนยันว่า `mainContainer` ไม่มี position/scale offset แยกจาก `worldContainer` (grep ไม่พบการตั้งค่า) → coordinate ที่ `_drawActiveZoneBorder()` วาดด้วย world-space x/y ยังถูกต้องเหมือนเดิมหลังย้าย container
- ยืนยันว่า `mainContainer` ไม่เคยถูก `removeChildren()` แบบเหมารวม (มีแต่ removeChild ทีละตัว) — child ที่ add ตอน init (เหมือน `_chatCapsuleGfx`) จะอยู่ถาวรข้าม map reload ไม่ต้องกังวลเรื่องถูกล้างทิ้ง
- ไม่พบการอ้างอิง `_activeZoneBorderGfx` จากไฟล์อื่นเลย — การเปลี่ยนแปลงจำกัดอยู่แค่ `scene.ts`

**Verify:** `npx tsc --noEmit` และ `npx eslint zyra-engine/pixi-game/scene.ts` ผ่าน 0 error, dev server compile สะอาด ไม่มี console error, grep ยืนยันไม่มีไฟล์อื่นอ้างอิง `_activeZoneBorderGfx` — **ยังไม่ได้ live-test จริงใน browser** (ต้อง login เข้า workspace ที่มี private zone + วาง object category walkable_group ใกล้ขอบ zone แล้วดูภาพจริงว่ากรอบขาวไปอยู่หลัง object ถูกต้องหรือไม่ — ต้องใช้ full VO stack ซึ่งไม่สามารถ setup ได้ในสภาพแวดล้อมนี้)

---

## (Follow-up) `_hoverBorderGfx` และ `_claimHoverGfx` — แก้เพิ่มตามที่ user ขอ

**คำอธิบายภาษาชาวบ้าน:** user ขอให้แก้ `_hoverBorderGfx` (กรอบเขียวตอน hover zone) และ `_claimHoverGfx` (กรอบขาวของ claimable zone) ด้วย — ทั้งสองมีบั๊กเดียวกันเป๊ะกับ active-zone border ที่แก้ไปแล้วด้านบน

> ✅ **แก้แล้ว (2026-07-21)**

**✅ Fix (`zyra-engine/pixi-game/scene.ts`):**
- ย้ายทั้ง `_hoverBorderGfx` และ `_claimHoverGfx` จาก `worldContainer.addChild(...)` → `mainContainer.addChild(...)` แบบเดียวกับ `_activeZoneBorderGfx`
- กำหนด `zIndex = -1` ให้ทั้งคู่ — ค่าเดียวกับ `_activeZoneBorderGfx` เพราะทั้ง 3 ตัวเป็น "boundary outline indicator" ประเภทเดียวกัน (แค่คนละสถานการณ์: active zone / hover / claim-hover) ไม่มีความจำเป็นต้อง sort ลำดับกันเองอย่างเคร่งครัด (เป็นเส้น outline บางๆ ที่ตามปกติไม่ overlap กันในการใช้งานจริง — ใช้ทีละอันต่อผู้เล่นหนึ่งคน)
- อัปเดต comment ของ `_editGridGfx` ที่เดิมอ้างอิงตำแหน่งเก่าของ `_hoverBorderGfx` ("sits above the hover border") ให้ตรงกับความจริงใหม่ — ตอนนี้ grid (ที่ยังอยู่ใน `worldContainer` เหมือนเดิม, ไม่แตะ) จะ render **อยู่หลัง** border ทั้ง 3 ตัว (สลับจากเดิม) เพราะ border ย้ายไปอยู่ใน `mainContainer` ซึ่ง add หลัง `_editGridGfx` — ผลกระทบเล็กน้อยเฉพาะตอน edit/decoration mode เท่านั้น (grid line บางๆ อาจถูก border บังเล็กน้อยตรงขอบ zone) ไม่ใช่ scope ที่ user ขอ จึงแค่แก้ comment ให้ตรงความจริง ไม่ได้แก้พฤติกรรมเพิ่ม
- ยืนยันว่าทั้งสอง graphics ไม่ถูกอ้างอิงจากไฟล์อื่นเลย (grep ทั้ง repo) — การเปลี่ยนแปลงจำกัดอยู่แค่ `scene.ts`

**Verify:** `npx tsc --noEmit` และ `npx eslint` ผ่าน 0 error, dev server compile สะอาด ไม่มี console error — **ยังไม่ได้ live-test จริงใน browser** เหตุผลเดียวกับด้านบน
