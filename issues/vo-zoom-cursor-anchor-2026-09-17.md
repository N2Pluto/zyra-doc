# VO Zoom — zoom ไม่ยึดเมาส์ และ scroll ไม่ติดบนวงกลมกลุ่มคน

> **สถานะ:** แก้แล้วบน branch `fix/vo-zoom-cursor-anchor` (2026-09-17) — **build + unit test เขียว · ยังไม่ได้ live-test บน dev** (ติด login, ดู [Verify ถึงไหน](#verify-ถึงไหน))
> **Repo ที่กระทบ:** `zyra-app` (Virtual Office — `zyra-engine/pixi-game`)
> **ที่มา:** support ticket ZYR-1188 และ ZYR-1189 (ผู้ใช้รายเดียวกันแจ้งสองใบ ระบุเองว่า "สองเรื่องนี้เกี่ยวกับการ zoom in zoom out")

---

## อาการ

**ZYR-1188** — zoom out เป็นภาพใหญ่เพื่อหาห้อง/หาคน พอเจอแล้วจะ zoom in เข้าไปที่ห้องนั้น ทำไม่ได้ เพราะ zoom แล้วภาพวิ่งไปกลางจอแทน ต้องลากหาจุดที่ต้องการใหม่อีกรอบ

**ZYR-1189** — ตอนอยู่ในมุมมองภาพใหญ่ ถ้าเอาเมาส์ไปชี้ที่ไอคอนคนที่เป็น **"วงใหญ่"** แล้วเลื่อน scroll จะไม่ zoom เลย (ผู้ใช้ระบุว่าเหมือนพยายามเลื่อนขึ้นลงแทน) ส่วน **"วงเล็ก"** ปกติ

---

## Root cause

ทั้งคู่อยู่ใน handler เดียวกัน: `onWheel` ใน `zyra-app/zyra-engine/pixi-game/scene.ts`

### 1. Zoom ยึด anchor ของกล้อง ไม่ใช่เคอร์เซอร์ (ZYR-1188)

`onWheel` ไม่เคยอ่าน `e.clientX/clientY` เลย — คำนวณ `factor` แล้วเรียก `zoomTo()` ซึ่งแตะแค่ `this.zoom` ส่วน transform ของกล้องปัก pivot ไว้ที่ `(vw/2, vh*0.53)` ตายตัวทุกเฟรม เพราะฉะนั้น zoom จะ pivot ที่จุดนั้นเสมอ

ซ้ำร้ายกว่านั้น: กล้องเป็น exponential follower ที่ไล่ตามตัวละคร (`camX += (px - camX) * min(1, dt*8)`) ต่อให้ขยับกล้องไปที่เคอร์เซอร์ ก็จะถูกดึงกลับมาที่ตัวละครภายใน ~125ms — เลยเป็นที่มาของอาการ "วิ่งไปตรงกลางจอ" ที่ผู้ใช้เห็น

น่าสังเกตว่าอีกสอง engine ในโปรเจกต์ anchor ที่เคอร์เซอร์อยู่แล้ว (`zyra-engine/systems/camera.system.ts` ของ play-test และ `map-editor-canvas.tsx` ของ workspace editor) — มีแต่ VO ที่ไม่ทำ

### 2. Overlay บนแผนที่กิน wheel event ทิ้ง (ZYR-1189)

Listener อยู่บน `window` แต่มี guard `if (e.target !== this.canvas) return` — เพราะฉะนั้น**ทุก DOM overlay ที่เป็น `pointer-events-auto` และลอยอยู่บนแผนที่ จะกลืน gesture ทิ้งทั้งดุ้น** ไม่ zoom และหน้าเว็บก็ไม่ scroll ตาม (root เป็น `h-screen overflow-hidden`) เลยรู้สึกเหมือนจุดตาย

**"วงใหญ่" คือ proximity-circle click target** — ปุ่ม `rounded-full` ที่ครอบกลุ่มคนตั้งแต่ 2 คนขึ้นไป (`hero-virtual-office.tsx`, ใช้ `circleScreenBox()`) ส่วน **"วงเล็ก" คือคนเดี่ยว** ที่วาดด้วย Pixi ใน canvas ล้วน ไม่มี DOM overlay ทับ — จึง scroll ได้ตามปกติ ตรงกับที่ผู้ใช้อธิบายเป๊ะ

ตัวอื่นที่โดนกฎเดียวกัน: meeting facepile, Ask-to-Join hover rect, zone label/rename chip, off-screen self indicator, การ์ด zone ล็อกแบบ inline

> อาการสองข้อนี้เสริมกันเอง: พอ zoom out ต่ำกว่า 0.775 facepile จะโผล่มาใต้เคอร์เซอร์พอดี แล้ว gesture ก็ค้างกลางคัน — ข้อ 2 จึงต้องแก้คู่กับข้อ 1 ถึงจะรู้สึกว่าใช้ได้จริง

---

## สิ่งที่แก้

| ที่ | แก้อะไร |
|---|---|
| `zyra-engine/pixi-game/scene.ts` | pure helper `screenToWorldAt()` + `cameraForZoomAt()` (`camX += (sx - vw/2) * (1/from - 1/to)`), `_screenToWorld` delegate มาที่ helper ตัวแรกเพื่อให้ projection มีนิยามเดียว |
| เดียวกัน | `_setZoomClamped()` คืนค่า zoom **ที่ใช้จริง** — สำคัญเพราะ `_zoomFloor()` เป็น per-screen ถ้าเอาค่าที่ "ขอ" ไปคิด anchor กล้องจะไถลต่อทั้งที่ภาพไม่เปลี่ยนแล้ว |
| เดียวกัน | `zoomToAt(level, sx, sy)` — anchor ที่จุดใต้เคอร์เซอร์ + `_cameraParked = true` + clamp. `zoomTo()` เดิมไม่แตะ ยังเป็น path ของปุ่ม ± บน minimap (center-anchored, ยัง follow) |
| เดียวกัน | `onWheel` ส่งพิกัดเคอร์เซอร์เข้า `zoomToAt`; `onTouchMove` ส่ง midpoint ของสองนิ้ว |
| เดียวกัน | รวม guard `e.target !== canvas` + `isScrollableTarget` เป็น `gestureTargetIsMap()` ตัวเดียว — ไล่ ancestor: เจอ canvas → zoom, เจอ scrollable จริง → ปล่อยให้ panel scroll, เจอ layer ที่ mark ไว้ → zoom |
| `zyra-engine/constants.ts` | `VO_WHEEL_PASSTHROUGH_ATTR` / `_PROP` |
| `hero-virtual-office.tsx` | ติด attribute บน world-space overlay layer **2 ตัว** (ไม่ไล่แก้ทีละ component) + `handleZoomChange` publish กล้องทั้งก้อนแทน zoom อย่างเดียว |
| `zone-locked-overlay.tsx` | ติด attribute เฉพาะ `mode === "inline"` (modal ต้องกิน wheel ต่อไป) |

### การตัดสินใจที่ต้องรู้: wheel zoom ตอนนี้ "park" กล้อง

ยืนยันกับผู้ใช้แล้ว — scroll zoom = pan ที่จุดเมาส์ ถ้าไม่ park กล้อง follow lerp จะดึงกลับใน ~125ms และ ticket จะแก้ไม่ได้เลย กลับมาหาตัวเองได้ด้วย WASD / click-to-walk / ปุ่ม Locate me บน minimap (ทั้งหมด un-park อยู่แล้ว) และ off-screen self indicator ก็โผล่เฉพาะตอนกล้อง park อยู่ห่างตัวละครพอดี

### บั๊กพ่วงที่เจอระหว่างแก้

`handleZoomChange` เดิมเรียก `setCameraZoom(zoom)` ซึ่ง publish zoom ใหม่คู่กับ `scrollX/scrollY` **เก่า** — เดิมมองไม่เห็นเพราะ `zoomTo` แทบไม่ขยับกล้อง แต่พอ anchor ที่เคอร์เซอร์แล้ว callback นี้ยิงสดใน wheel event ก่อน rAF loop จะ publish คู่ที่ถูก → overlay ทุกตัวจะวาดผิด 1 เฟรมต่อ 1 notch (เห็นเป็นอาการกระตุกไปกลับ) แก้ด้วยการอ่าน `getCameraState()` แล้ว `setCamera()` ทั้งก้อน

---

## Verify ถึงไหน

**ผ่านแล้ว (build เขียว):**
- `npx tsc --noEmit` — ไม่มี error ใหม่ (เหลือ 8 error เดิมใน test file ที่มีอยู่ก่อนแล้วบน `develop` ตรวจด้วย `git stash` ยืนยัน)
- `npm run lint` — 0 error, 3 warning ที่มีอยู่เดิมทั้งหมด
- `npm run build` — ผ่าน
- `npx vitest run` — **2,464 passed** รวม 14 เทสใหม่:
  - invariant "จุดใต้เคอร์เซอร์ต้องเป็น world point เดิม" ครบทุกมุมจอ × zoom 0.4–3.0 ทั้งเข้าและออก
  - เคอร์เซอร์ทับ anchor พอดี → กล้องไม่ขยับ · zoom ไม่เปลี่ยน → identity
  - ที่ขอบ scene: clamp ชนะ แต่กล้องเดินเข้าหามุมแบบ monotonic ไม่แกว่งกลับ
  - wheel จริงผ่าน listener: anchor ถูก, park กล้อง, ชนเพดาน zoom แล้วไม่ขยับและไม่ park
  - `zoomTo` (ปุ่ม ± minimap) ยังไม่ park ไม่ anchor
  - guard table: overlay ที่ mark ไว้ → zoom ได้ · panel ที่ scroll ได้จริง → ไม่ zoom · scrollable ที่ซ้อน**ใน** layer ที่ mark → ยัง scroll (ตัวที่ใกล้กว่าชนะ) · UI ที่ไม่ mark → ไม่ zoom · `_zoomLocked` → ไม่ zoom
  - pinch: anchor ที่ midpoint สองนิ้ว (ค่า `PINCH_ZOOM_SENSITIVITY` ไม่เปลี่ยน)

**ยังไม่ได้ทำ — live test บน dev:** dev server รันขึ้นและ serve หน้า login ได้ แต่เข้าหน้า Virtual Office จริงต้อง login ซึ่ง AI กรอก credential ไม่ได้ จึงยังไม่ได้ยืนยันด้วยตาบนแผนที่จริง ต้องเช็คต่อ:
- [ ] zoom out สุด → ชี้ห้องที่มุมจอ → scroll เข้า → ห้องอยู่ใต้เคอร์เซอร์ตลอด (ZYR-1188)
- [ ] scroll ตอนเคอร์เซอร์อยู่บนวงกลมกลุ่มคน 2+ คน / facepile / ปุ่ม Ask to Join → zoom ได้ (ZYR-1189)
- [ ] scroll ใน member panel / chat → ยังเลื่อนรายการ ไม่ zoom
- [ ] เปิด modal → ไม่ zoom
- [ ] กด W / click-to-walk / ปุ่ม Locate me → กล้องกลับมาที่ตัวละคร
- [ ] zoom สุดสองทาง → ไม่กระตุกที่ขอบแผนที่
- [ ] ปุ่ม ± minimap → ยัง zoom ที่ตัวเรา และกรอบ viewport บน minimap ตามถูก
- [ ] trackpad pinch → zoom เข้าที่จุดนิ้ว

---

## Before/After

ยังไม่ได้วัดเป็นตัวเลข — เป็น UI behaviour bug ไม่ใช่ perf/incident จึงไม่มี metric ที่ตรงกับปัญหา (ตาม [กฎ before/after](../../.claude/rules/18-before-after-metrics.md) เคสนี้ไม่บังคับ) เกณฑ์ผ่านคือ checklist live-test ข้างบน
