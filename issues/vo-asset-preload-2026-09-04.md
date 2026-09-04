# VO โหลดซ้ำอีกรอบหลังหน้าโหลดบอก 100%

> สถานะ: แก้แล้ว รอ review · วันที่: 2026-09-04 · repo ที่กระทบ: `zyra-app`
> Branch: `fix/vo-preload-assets-on-loading`

## อาการที่ผู้ใช้รายงาน

"ตอนเข้าหน้า VO เหมือนจะมีการโหลด แต่พอเข้าไปมันเหมือนจะมีการโหลดนู้นนี่นั่นเพิ่ม อยากให้ปรับให้มันโหลดตั้งแต่ตอนอยู่หน้าโหลด"

## Root cause

`/workspace/[id]/loading` โหลด **JSON อย่างเดียว** — 6 REST call + WS `welcome` handshake — แล้วขึ้น 100% เด้งเข้า `/play` โดย **ไม่โหลดรูปแม้แต่ไฟล์เดียว**

งานโหลดรูปทั้งหมดเกิดหลัง `/play` mount และถูกซ่อนไว้หลัง overlay "Starting…" ที่ไม่มีตัวเลข %:

| ลำดับ | สิ่งที่โหลด | ที่ | gate `sceneReady`? |
|---|---|---|---|
| 1 | Pixi chunk (`GameCanvas` เป็น `next/dynamic`) | `hero-virtual-office.tsx:235` | ก่อน init |
| 2 | map background เต็ม + thumbnail | `scene.ts:1068`, `1073` | **ไม่ await** — พื้นค่อย ๆ ชัดหลังหน้าโหลดหายไปแล้ว |
| 3 | spritesheet เดิน/นั่งของตัวเอง | `scene.ts:1082` | await |
| 4 | PNG ทุกชิ้นของ object ที่วางบนแผนที่ | `scene.ts:1336`, await ที่ `1470` | await — ตัวที่กินเวลาที่สุด |
| 5 | spritesheet ของ peer (2 ไฟล์/คน) | `scene.ts:8547`, `8654` | **หลัง** `sceneReady` (roster effect gate ด้วย `sceneReady`) |

ทุกไฟล์ผ่าน `loadTex` → คิวจำกัด 4 ไฟล์พร้อมกัน (`utils.ts:610`) → `/api/img` route เดียว

URL ทุกตัวถูก resolve ที่หน้า loading อยู่ก่อน `setReady()` แล้ว (`mainMap.image_url`, `ComposedPiece.imageUrl` ที่ proxy แล้วจาก `tile-builder.ts:29`, `MinimapPlayer.avatar_url`) — แค่ไม่เคยถูก fetch

## สิ่งที่แก้

- **`lib/vo-preload.ts` (ใหม่)** — collector แบบ pure (map bg, avatar ตัวเอง, piece ของ object ที่วางจริง, peer sheet) + `preloadAssets` แบบ best-effort ไม่ throw
- **`hero-workspace-loading.tsx`** — warm chunk (`vo-preload` + `pixi-canvas` + `router.prefetch`), ยิง wave A หลัง `buildDbTiles` ให้วิ่งคู่ขนานกับ step 4 และ WS handshake, wave B (peer) หลัง `waitForWelcome`, แถบ progress รีบาลานซ์ (JSON 0–60, asset 60–95) ขับด้วยจำนวนไฟล์จริง, watchdog เปลี่ยนเป็น stall-based
- **`zyra-engine/pixi-game/utils.ts`** — `MAX_CONCURRENT_LOADS` เป็น phase-aware (preload นอก scene ใช้ 8, คืนเป็น 4 ก่อนเข้าเกม)
- **`hero-virtual-office.tsx`** — `mapConfig` เรียก `mapBackgroundUrls()` ร่วมกัน กัน URL drift (cache key ต้องตรงเป๊ะ)

`texCache` เป็น module-level และรอดข้าม client-side navigation `/loading → /play` → รูปที่ warm ไว้กลายเป็น cache hit ทันทีที่ scene ขอ

### กับดักที่ต้องระวังถาวร

`loadTex(url, pixelated)` set `scaleMode = "nearest"` บน texture ที่อยู่ใน cache แต่ `scene.ts:1310` อ่าน `_texCache.get()` ตรง ๆ — **ถ้า cache hit จะไม่เรียก `loadTex` เลย** flag จึงไม่ถูก apply ถ้า preload object piece ด้วย `pixelated=false` จะได้ pixel art เบลอทั้งออฟฟิศ เห็นเฉพาะบน production เท่านั้น มี unit test (`__tests__/vo-preload.test.ts`) ล็อกไว้แล้ว

## Before/After

| Metric | Before | After | Δ |
|---|---|---|---|
| คลื่นโหลดรอบสอง (`/play` mount → ออฟฟิศโผล่จริง) | 6000 ms | 0 ms | **−100%** |
| จำนวน request `/api/img` หลัง `/play` mount | 158 | 0 | **−158** |
| ปริมาณข้อมูลที่โหลดหลัง `/play` mount | 1128 KB | 0 KB | **−100%** |
| เวลารวม `/loading` mount → ออฟฟิศโผล่ | 14000 ms | 10000 ms | **−29%** |
| รูปที่โหลดระหว่างอยู่หน้า loading | 0 | 165 | +165 |

**วัดยังไง**: `performance.getEntriesByType("resource")` กรอง `/api/img` เทียบกับ mark 3 จุด — URL เปลี่ยนเป็น `/loading`, URL เปลี่ยนเป็น `/play`, และ overlay `.z-[999]` (`WorkspaceLoadingScreen`) หลุดจาก DOM พร้อมมี `<canvas>` = "ออฟฟิศโผล่จริง" เก็บด้วย poller ใน document เดียวตลอด flow (SPA navigation ผ่าน `window.next.router.push`)

**ช่วงเวลาที่วัด**: 1 cold run ต่อ build · **แหล่งข้อมูล**: local prod stack (`next build && next start`) + zyra-api :3002 + zyra-ws :3003 · workspace `office` (`256893ae-…`) ซึ่งมี **1609 placed objects**

**Cold cache ทำยังไง**: `/api/img` ตอบ `Cache-Control: public, max-age=86400` ทำให้ run ที่สองขึ้นไปเป็น disk cache หมด (`transferSize: 0`) ซึ่ง**กลบปัญหาที่จะวัดพอดี** จึงวัดแต่ละ build บนคนละ origin (`127.0.0.1:3000` สำหรับ before, `[::1]:3000` สำหรับ after) เพราะ HTTP cache แยกตาม origin ยืนยันว่าเย็นจริงด้วย `transferSize > 0` ครบทุกไฟล์ทั้งสองฝั่ง

### ข้อจำกัดของตัวเลขชุดนี้ (ระบุตามจริง)

- **timestamp มี granularity ~1 วินาที** — pane ถูก background ทำให้ `setInterval(20ms)` ถูก throttle เหลือ ~1s ตัวเลขเวลาจึงกลมผิดปกติ (6000/14000/10000) ขนาดของ effect ใหญ่กว่า error มาก และ metric ที่เป็น **จำนวน request/bytes ไม่ได้พึ่งเวลาเลย** (158 → 0) จึงเป็นหลักฐานที่แข็งที่สุด
- **cold run ทั้งสองฝั่ง WS ต่อไม่ติด** — `zyra-ws` อนุญาตเฉพาะ origin `http://localhost:3000` (ดู log `ws origin rejected`) การใช้ origin อื่นเพื่อให้ cache เย็นจึงทำให้ `waitForWelcome()` timeout ครบ 4s **ทั้ง before และ after เท่ากัน** ผลคือ: peer wave ได้ roster ว่าง (ยังไม่ได้วัดเคสมี peer จริง) และเวลารวมทั้งสองฝั่งรวม 4s นี้อยู่ ส่วนต่าง −4s จึงไม่ได้มาจาก WS
- **ยังไม่ได้วัด**: เคสที่มี peer ≥ 3 คนบนชั้นเดียวกัน (wave B เป็น dead code ในรอบที่วัด), การวัดหลาย run เพื่อหา median, และการวัดแบบ throttle เครือข่าย

## Verify ถึงไหน

- `npx tsc --noEmit` ไม่มี error ใหม่ (3 error ที่เหลือใน `__tests__/` มีอยู่บน develop ก่อนแล้ว — ยืนยันด้วยการ stash เทียบ)
- `npm run lint` + Prettier สะอาดทุกไฟล์ที่แตะ
- `npx vitest run` — **124 ไฟล์ / 1582 tests ผ่าน** (รวม 14 tests ใหม่ของ `vo-preload`)
- `next build && next start` — live test บน local prod stack:
  - เข้าครั้งแรก: ออฟฟิศเรนเดอร์ครบ **pixel art คมชัด** ไม่มีจังหวะพื้นเบลอ→ชัด
  - re-entry (`/play → /loading → /play` ซึ่งล้าง `texCache` ผ่าน `destroy()` แล้ว preload ใหม่): เรนเดอร์ครบ ไม่มี GPU texture corruption 2 รอบติด
  - ไม่มี modal "Unable to reconnect" เมื่อ WS ปกติ

### ที่เจอระหว่างทาง (ไม่ใช่บั๊กของงานนี้)

จอ VO ว่างเปล่าตอน re-entry **reproduce เฉพาะบน origin ที่ `zyra-ws` ปฏิเสธ** (`127.0.0.1` / `[::1]`) — ตอน WS ตาย session ค้างแล้ว scene ไม่ได้ข้อมูล ทดสอบซ้ำบน `localhost:3000` ทั้ง develop และ branch นี้เรนเดอร์ปกติทั้งคู่ ยืนยันแล้วว่าไม่ใช่ regression

## งานที่แยกไว้ ไม่ได้ทำใน PR นี้

- `hero-virtual-office.tsx:733` `listMaps()` เป็น refetch ซ้ำของข้อมูลที่ `/loading` มีอยู่แล้วใน `mapData`
- `hero-virtual-office.tsx:1703` `listAvatarsForUser()` เมื่อ resolve จะเรียก `saveSelectedAvatar` → `setStoredAvatar` ทำให้ WS effect รันใหม่
- profile headshot ของ peer, click-walk GIF, mp3 10 ไฟล์ — จงใจไม่ preload (เหตุผลอยู่ในหัวข้อ "สิ่งที่ไม่ทำ" ของแผน: headshot ใช้เฉพาะตอน zoom ไกลซึ่งไม่ใช่ default view, GIF โหลดผ่าน `Assets` คนละ cache กับ `loadTex`)
