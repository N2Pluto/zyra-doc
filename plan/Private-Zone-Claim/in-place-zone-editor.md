# In-place Zone Editor — แก้ zone บน VO Pixi scene (ไม่มีจอโหลด, เห็นตัวละคร)

> ต่อยอดจาก [plan.md](./plan.md) SC-PZ-05/06 · เป้าหมาย: เปลี่ยนการ "Decorate" zone จากการ mount editor คนละตัว (2D canvas + full reload + ไม่มี avatar) → **edit mode บน VO Pixi scene เดิม** ที่กำลังรันอยู่

## ปัญหาปัจจุบัน (ตามที่สำรวจโค้ด)

กด "Decorate" (`pz-zone-card.tsx:129` → `hero-virtual-office.tsx:4958` `setPzEditorOpen(true)`) — **ไม่เปลี่ยน route** แต่ mount `ZoneEditorOverlay` (`hero-workspace-editor.tsx`) เป็น `fixed inset-0 z-100` overlay ทับ VO

overlay นั้น:
- ใช้ **2D HTML canvas** `MapEditorCanvas` — ไม่ใช่ Pixi scene ของ VO
- โหลดข้อมูลใหม่หมด (maps + objects + zones + palette) → จอ `EditorLoadingScreen` (`hero-workspace-editor.tsx:3921`)
- **ไม่ render avatar**

ทั้งที่ข้อมูลชุดเดียวกัน + avatar อยู่ใน VO Pixi ข้างล่างแล้ว

## เป้าหมาย UX

- กด Decorate → **ไม่มีจอโหลดเต็มจอ** (palette โหลดด้วย spinner เล็กใน panel เท่านั้น)
- กล้อง pan/zoom ไปที่ zone ของตัวเอง, วาด grid + ขอบ zone
- **avatar ยืนอยู่ในฉากตลอด** (freeze การเดิน, ยังเห็นตัว)
- วาง/ย้าย/หมุน/ลบ object ได้บน Pixi scene เดิม → เห็นทันที + คนอื่นเห็นทันที (map_object_changed ทำงานแล้วหลังเปิด Redis)

## หลักการออกแบบ

- **ไม่ mount `hero-workspace-editor` อีก** — ใช้ VO Pixi scene ที่รันอยู่ + toggle edit mode
- Reuse ให้มากที่สุด: write API (`lib/api/user-workspace-editor` ผ่าน `use-editor-api` userMode), palette panel (`object-library-panel.tsx`), `applyObjectDelta` ที่มีอยู่
- ทุก mutation = **write-through** (เขียน API ทันที) → backend broadcast `map_object_changed` → live sync
- ทุก edit ถูก clamp ใน `ZoneScope.rect` (client) + server enforce ซ้ำ

## จุดเชื่อมที่มีอยู่แล้ว (ใช้ได้เลย)

| ของ | ที่ | หมายเหตุ |
|---|---|---|
| ScopeRect (tile coords) + objectLimit | `hero-virtual-office.tsx:5020` (pzEditorZone) | คำนวณอยู่แล้ว |
| write API userMode | `views/admin/workspace-editor/hooks/use-editor-api.ts` | add/remove/move/updateMeta |
| single-object mutation | `scene.ts:520 applyObjectDelta(action, record, tiles)` | add/move/update/remove |
| live receive delta | `hero-virtual-office.tsx:2008 client.on("map_object_changed")` | ทำงานแล้ว |
| camera/zone helpers | `scene.ts` zoomTo / panToWorldPoint / getZoneScreenRect / getCameraState / setFreeCamera / setInputFrozen / setBlockWalk | มีครบ |
| palette panel | `views/admin/workspace-editor/components/object-library-panel.tsx` | ต้อง decouple จาก MapEditorCanvas |
| dbTiles / map data ใน VO | `hero-virtual-office.tsx` dbTilesRef, data | ไม่ต้อง refetch |

## สิ่งที่ต้องสร้างใหม่ (ยังไม่มีใน Pixi)

**ระบบ edit-input บน `PixiGameScene`** — ตอนนี้ scene มีแค่ walk/sit/camera input; ไม่มี placement/select/drag/grid-edit (พวกนั้นอยู่ใน MapEditorCanvas 2D ทั้งหมด)

---

## Phasing

### Phase 1 — Edit shell (แก้ pain หลักทันที) ⭐ ✅ DONE (tsc+eslint ผ่าน, รอ verify ใน browser)
เป้า: เข้า/ออก edit mode บน VO, กล้องโฟกัส zone, avatar ยืน, palette เปิดได้ — **ยังไม่วาง object**

**ไฟล์ที่แก้/สร้าง:**
- `zyra-engine/pixi-game/scene.ts` — เพิ่ม `_editMode`/`_editZoneRect`/`_editGridGfx`, methods `enterEditMode(rect)` / `exitEditMode()` / `isEditMode()` / `_drawEditGrid()` (freeze input + block walk + free camera + pan/zoom to zone + grid overlay world-space)
- `zyra-engine/types.ts` — `PlayTestHandle.enterEditMode?` / `exitEditMode?`
- `components/game-canvas/pixi-canvas.tsx` — expose 2 methods บน handle
- `views/user/virtual-office/components/pz-edit-hud.tsx` — **ใหม่**: top bar (zone name + count/limit + Done) + palette panel (lazy `listAllActiveObjects` → `/api/objects/all`, UserGuard) display-only
- `views/user/virtual-office/hero-virtual-office.tsx` — state `pzEditMode` (แทน `pzEditorOpen`), `pzEditRect` memo, `pzPlacedCount` (นับ mapObjects ที่ zone_id ตรง), effect เข้า/ออก edit mode (deps = numeric bounds กัน camera snap-back เมื่อ data churn), Decorate → `setPzEditMode(true)`, ลบ `ZoneEditorOverlay` dynamic import + mount ทิ้ง

**Verify (ทำเองไม่ได้ — port 3000 ถูกอีก session ถือ):** เปิด My Zone card → Decorate → ควรได้: ไม่มีจอโหลด, avatar ยืนในฉาก, กล้อง pan+zoom ไป zone + เห็น grid เขียว, palette ขวา, ปุ่ม Done ออก

- FE: state `pzEditMode` แทน `pzEditorOpen` (เลิก mount ZoneEditorOverlay)
- Scene: `enterEditMode(scope)` / `exitEditMode()` —
  - `setInputFrozen(true)` + `setBlockWalk(true)` → avatar หยุดเดินแต่ยังอยู่
  - pan+zoom ไป zone center (`panToWorldPoint` + `zoomTo`)
  - วาด grid + zone boundary overlay (ใช้ pattern `_drawScreenOverlay` / lockedZones ที่มี)
- HUD overlay (React, Tailwind ตาม rule 08): top bar (zone name + count/limit + Done/Exit) + palette panel (lazy list, spinner ใน panel)
- ยืนยัน: กด Decorate → ไม่มีจอโหลด, เห็น avatar ยืน, กล้องอยู่ที่ zone, palette แสดง object

### Phase 2 — Stamp placement
- Scene: `beginPlaceGhost(tileId, tile)` → ghost sprite ตามเมาส์, grid-snap, clamp ใน rect
- click → `addMapObject` (write-through) + `applyObjectDelta("add", record)` (optimistic)
- object count เพิ่ม, เช็ค objectLimit

### Phase 3 — Select / move / rotate / delete
- Scene: pointer hit-test object ใน zone → highlight
- drag → `moveMapObject` + delta "move"
- rotate → `updateMapObjectMeta(facing)` + delta "update"
- delete / eraser → `removeMapObject` + delta "remove"

### Phase 4 — Polish
- objectLimit UI (disable stamp เมื่อเต็ม), zone-bounds error toast, undo (optional), exit confirm ถ้ามีการเปลี่ยน, cleanup debug console.log ใน scene.ts (525/529/537/539)

## Non-goals (ไม่ทำ ตาม no-overreach)
- ไม่แตะ admin workspace-editor (2D) — ยังใช้ path เดิม
- ไม่เพิ่ม zone/floor management, version history ใน in-place mode
- ไม่ทำ multi-select / copy-paste (ยกไป backlog)

## Verify plan
- preview port 3000 (zyra-ws origin check), 2 client ใน VO เดียวกัน, วาง object ฝั่งหนึ่ง อีกฝั่งเห็นทันที (ดู [[vo-realtime-redis-bus]] + [[vo-preview-e2e-verify]])
