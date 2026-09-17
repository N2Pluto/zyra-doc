# Object hitbox — default collision mode ไม่ถูกบันทึกลง cells

> **สถานะ:** พบจากการอ่านโค้ด (2026-09-17) ระหว่างออกแบบ [SC-OBJ-NAT-01](../plan/%5BFeature%5D%20Nature%20Object%20Management%20%E2%80%94%20Object%20Management/technical-design.md) — **ยังไม่แก้ · ยังไม่ได้วัดผลกระทบกับข้อมูลจริง**
> **Repo ที่กระทบ:** `zyra-app` (admin object management)
> **ความรุนแรง:** object ที่ควรเดินทะลุได้ อาจถูกบันทึกเป็นกำแพง — กระทบ gameplay ใน Virtual Office

---

## อาการ

Object type ที่ระบบตั้งใจให้ **เดินทะลุได้เป็นค่าเริ่มต้น** (`walkable_group`, `decoration`, `machine`, `foods_and_drink` — และ `nature` ที่กำลังจะเพิ่ม) **จะถูกบันทึกเป็น `blocked` เต็มรอยเท้า** ถ้า admin ไม่เข้าไประบาย hitbox เองด้วยพู่กันบน Object Preview

ผลปลายทาง: ผู้เล่นเดินชนของที่ควรเดินผ่านได้ (เช่น ของตกแต่ง, ต้นไม้)

## Root cause

`deriveCollisionModeFromType` ตั้งค่าได้แค่ **โหมดพู่กันบน toolbar** ไม่ได้ตั้ง type ของ cells ที่ถูก save

```
zyra-app/views/admin/object-management/
├── constants.ts:90   deriveCollisionModeFromType()
│                     walkable_group | decoration | machine | foods_and_drink → "walkable"
│                     ที่เหลือ → "blocked"
│                     ↓ ค่านี้ไหลไปที่ ObjectPreviewCanvas เป็น "โหมดพู่กันเริ่มต้น" เท่านั้น
│
├── constants.ts:115  buildCellsFromHitbox(hitbox)
│                     → cells.push({ col, row, type: "blocked" })   ← ❌ hardcode
│
├── constants.ts:158  applyFootprintToComposition(composition, fallbackHitbox, fallbackCells)
│                     :179-182  dirCells = current.hitboxCells?.length
│                                            ? current.hitboxCells    ← ระบายเองแล้ว = ใช้ของจริง
│                                            : dirFallbackCells       ← ไม่ระบาย = ได้ blocked ทั้งแผง
│
└── components/object-preview-canvas.tsx:431  buildCellsFromHitbox() ตัวที่วาด
                                              → type: "blocked"      ← ❌ hardcode เหมือนกัน
```

จุดที่เรียกใช้ตอน save: [`object-add-form.tsx:687-699`](../../zyra-app/views/admin/object-management/components/object-add-form.tsx) — `wall` ถูก skip ไว้ (ใช้ edge-based collision) นอกนั้นเข้า `applyFootprintToComposition` ทั้งหมด

ฝั่งที่อ่านค่าไปใช้จริง:
- **Server** `zyra-api/internal/service/obstacle_grid_builder.go` — นับเฉพาะ cell ที่ `type != "walkable"` เข้า obstacle grid ที่ `zyra-ws` ใช้ validate การเดิน
- **Client** `zyra-app/zyra-engine/assets/tile-builder.ts:102-114`

## วิธีแก้ที่เสนอ

แก้จุดเดียว — ให้ fallback cells ใช้ collision mode แทน hardcode:

```ts
// constants.ts
export const buildCellsFromHitbox = (
  hitbox: PieceHitbox,
  mode: CollisionMode = "blocked",   // default เดิม → call site ที่ไม่ส่ง mode พฤติกรรมไม่เปลี่ยน
): HitboxCell[] => {
  const cells: HitboxCell[] = []
  for (let dx = 0; dx < hitbox.cols; dx += 1) {
    for (let dy = 0; dy < hitbox.rows; dy += 1) {
      cells.push({ col: hitbox.col + dx, row: hitbox.row + dy, type: mode })
    }
  }
  return cells
}
```

แล้วส่ง `collisionMode` เข้ามาจาก `object-add-form.tsx` (มี state อยู่แล้วที่ `:144`) และจาก `ObjectPreviewCanvas` (มี prop `collisionMode` อยู่แล้วที่ `:63`)

**สิ่งที่ต้องตัดสินคู่กัน:** object เก่าที่บันทึกไปแล้วด้วย cells `blocked` — จะ backfill หรือปล่อย? ถ้า backfill ต้องระวังของที่ admin **ตั้งใจ**ระบาย blocked ทับ default (แยกไม่ออกจากข้อมูลที่มีตอนนี้ เพราะ cells ที่ระบายเองกับ fallback หน้าตาเหมือนกันทุกประการ) → ทางที่ปลอดภัยคือ **แก้ไปข้างหน้าอย่างเดียว** แล้วให้ admin แก้ของเก่าเองเป็นราย object

## Test ที่ต้องมีคู่กับการแก้

- `buildCellsFromHitbox(hb)` ไม่ส่ง mode → cells ทุกตัว `blocked` (พฤติกรรมเดิมต้องไม่เปลี่ยน)
- `buildCellsFromHitbox(hb, "walkable")` → cells ทุกตัว `walkable`
- save object type `decoration` โดยไม่ระบายอะไรเลย → composition ที่ส่งขึ้น API มี cells `walkable`
- save object type `sofa` โดยไม่ระบาย → ยังได้ `blocked`
- cells ที่ระบายเองแล้วต้องไม่ถูก fallback ทับ (`applyFootprintToComposition` เคสมี `hitboxCells` อยู่แล้ว)

## Before/After

**ยังไม่ได้วัด** — เหตุผล: เจอจากการอ่านโค้ด ยังไม่ได้ query ข้อมูลจริงว่ามี object กี่ตัวที่โดนอาการนี้ และยังไม่มีการแก้ให้เทียบ (ตาม [18-before-after-metrics](../../.claude/rules/18-before-after-metrics.md) — ห้ามเดาตัวเลข)

**วิธีวัดเมื่อจะแก้จริง** — นับ object ที่ type ควร walkable แต่ cells เป็น blocked (รันผ่าน `zyra-service/prod-db.sh` ดู [prod-db-access.md](../guides/prod-db-access.md)):

```sql
SELECT o.type, count(*) AS objects_with_blocked_cells
FROM tb_object o
JOIN object_compositions oc ON oc.object_id = o.id
WHERE o.type IN ('walkable_group','decoration','machine','foods_and_drink')
  AND (o.is_deleted IS NULL OR o.is_deleted = false)
  AND EXISTS (
    SELECT 1
    FROM jsonb_array_elements(oc.composition->'variants') v,
         jsonb_each(v->'directions') d,
         jsonb_array_elements(d.value->'hitboxCells') c
    WHERE COALESCE(c->>'type', 'blocked') = 'blocked'
  )
GROUP BY o.type
ORDER BY 2 DESC;
```

ตัวเลขที่ควรบันทึกคู่กัน: จำนวน object ต่อ type (ก่อน/หลังแก้ + backfill ถ้าทำ) และจำนวน placement ที่ได้รับผลกระทบ (`JOIN tb_map_object`)

## เกี่ยวข้องกับ

- [SC-OBJ-NAT-01 technical-design §3.2](../plan/%5BFeature%5D%20Nature%20Object%20Management%20%E2%80%94%20Object%20Management/technical-design.md) — เป็น **prerequisite ของ HP-02** เพราะ Nature ต้อง walkable เป็น default
- ZYR-1088 (`zyra-app/__tests__/tile-builder-hidden-objects.test.ts`) — คนละเรื่อง แต่แตะ tile-builder เหมือนกัน ระวังตอนแก้
