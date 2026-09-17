# Object hitbox — default collision mode ไม่ถูกบันทึกลง cells

> **สถานะ:** พบจากการอ่านโค้ด (2026-09-17) ระหว่างออกแบบ [SC-OBJ-NAT-01](../plan/%5BFeature%5D%20Nature%20Object%20Management%20%E2%80%94%20Object%20Management/technical-design.md) — **ยังไม่แก้ · วัดกับ prod แล้ว ยืนยันว่าเกิดจริง: 24 object · 2,453 placement · 47 workspace** (ดู [ผลการวัด](#ผลการวัดกับ-prod-จริง-2026-09-17))
> **Repo ที่กระทบ:** `zyra-app` (admin object management)
> **ความรุนแรง:** object ที่ควรเดินทะลุได้ ถูกบันทึกเป็นกำแพง — **กระทบ gameplay จริงบน prod 2,453 จุดใน 47 workspace**

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

**After ยังไม่มี** — ยังไม่ได้แก้โค้ด · Before วัดแล้วด้านล่าง ([18-before-after-metrics](../../.claude/rules/18-before-after-metrics.md))

**SQL ที่ใช้วัด** — นับ object ที่ type ควร walkable แต่ cells เป็น blocked (รันผ่าน `zyra-service/prod-db.sh` ดู [prod-db-access.md](../guides/prod-db-access.md)):

```sql
-- นับ object ที่ type ควร walkable แต่มี hitbox cell เป็น blocked
-- ทนกับ composition 2 แบบ: ใหม่ {variants:[{directions:{...}}]} และ legacy {directions:{...}}
WITH cells AS (
  SELECT o.id, o.type, c->>'type' AS cell_type
  FROM tb_object o
  JOIN object_compositions oc ON oc.object_id = o.id
  CROSS JOIN LATERAL (
    SELECT CASE
      WHEN jsonb_typeof(oc.composition->'variants') = 'array' THEN oc.composition->'variants'
      ELSE jsonb_build_array(oc.composition)
    END AS variants
  ) vs
  CROSS JOIN LATERAL jsonb_array_elements(vs.variants) v
  CROSS JOIN LATERAL jsonb_each(COALESCE(v->'directions', '{}'::jsonb)) d
  CROSS JOIN LATERAL jsonb_array_elements(
    CASE WHEN jsonb_typeof(d.value->'hitboxCells') = 'array'
         THEN d.value->'hitboxCells' ELSE '[]'::jsonb END
  ) c
  WHERE o.type IN ('walkable_group','decoration','machine','foods_and_drink')
    AND (o.is_deleted IS NULL OR o.is_deleted = false)
)
SELECT
  type,
  count(DISTINCT id) FILTER (WHERE COALESCE(cell_type,'blocked') = 'blocked') AS objects_with_blocked_cells,
  count(DISTINCT id) AS objects_with_composition
FROM cells
GROUP BY type
ORDER BY 2 DESC;
```

> **ทำไมต้อง guard `jsonb_typeof`:** `jsonb_array_elements()` จะ error ทันที (`cannot extract elements from an object`) ถ้าเจอ row ที่ `composition` เป็น legacy shape `{directions: {...}}` ซึ่งไม่มีคีย์ `variants` — migration `15` backfill ของเก่ามาจาก `tb_object.composition` ตรง ๆ จึงมีสิทธิ์เจอ

**นับ placement ที่ได้รับผลกระทบจริง** (สำคัญกว่าจำนวน object เพราะคือจุดที่ผู้เล่นชนจริง):

```sql
WITH blocked_objects AS (
  SELECT DISTINCT o.id
  FROM tb_object o
  JOIN object_compositions oc ON oc.object_id = o.id
  CROSS JOIN LATERAL (
    SELECT CASE
      WHEN jsonb_typeof(oc.composition->'variants') = 'array' THEN oc.composition->'variants'
      ELSE jsonb_build_array(oc.composition)
    END AS variants
  ) vs
  CROSS JOIN LATERAL jsonb_array_elements(vs.variants) v
  CROSS JOIN LATERAL jsonb_each(COALESCE(v->'directions', '{}'::jsonb)) d
  CROSS JOIN LATERAL jsonb_array_elements(
    CASE WHEN jsonb_typeof(d.value->'hitboxCells') = 'array'
         THEN d.value->'hitboxCells' ELSE '[]'::jsonb END
  ) c
  WHERE o.type IN ('walkable_group','decoration','machine','foods_and_drink')
    AND (o.is_deleted IS NULL OR o.is_deleted = false)
    AND COALESCE(c->>'type','blocked') = 'blocked'
)
SELECT count(*) AS affected_placements,
       count(DISTINCT mo.map_id) AS affected_maps
FROM tb_map_object mo
JOIN blocked_objects b ON b.id = mo.object_id;
```

ตัวเลขที่ควรบันทึกคู่กัน: จำนวน object ต่อ type และจำนวน placement/map ที่ได้รับผลกระทบ (ก่อน/หลังแก้ + backfill ถ้าทำ)

> หมายเหตุ: `prod-db.sh` อนุญาตเฉพาะ statement ที่ขึ้นต้นด้วย `SELECT/EXPLAIN/SHOW/TABLE/VALUES` (`prod-db.sh:69-73`) — query ที่ขึ้นต้นด้วย `WITH` จะถูกปฏิเสธว่าเป็น write ต้องเขียนเป็น subquery ใน `FROM` แทน

## ผลการวัดกับ prod จริง (2026-09-17)

**วัดแล้ว — ยืนยันว่าบั๊กนี้เกิดขึ้นจริงบน production**

### Object ที่มี hitbox cell เป็น blocked ทั้งที่ type ควร walkable

| type | มี blocked cell | มี composition ทั้งหมด | สัดส่วน |
|---|---|---|---|
| `decoration` | **18** | 68 | 26% |
| `machine` | **14** | 18 | **78%** |
| `foods_and_drink` | 0 | 32 | 0% |
| `walkable_group` | 0 | 46 | 0% |
| **รวม** | **32** | 164 | 20% |

### แยก "น่าจะเป็น fallback ของบั๊ก" ออกจาก "admin ตั้งใจระบาย"

object ที่ **ไม่มี cell `walkable` เลยแม้แต่ช่องเดียว** = ตรงกับลายเซ็นของ fallback (`buildCellsFromHitbox` ปั๊ม `blocked` ทั้งแผง) · ถ้า admin เข้าไประบายเองจะเห็น cell ผสมกัน

| type | ทุก cell เป็น blocked (**น่าจะเป็นบั๊ก**) | ผสม blocked+walkable (admin ตั้งใจ) |
|---|---|---|
| `decoration` | **15** | 3 |
| `machine` | **9** | 5 |
| **รวม** | **24** | 8 |

### ผลกระทบที่ผู้เล่นเจอจริง

| ขอบเขต | placement | map | workspace |
|---|---|---|---|
| object ที่มี blocked cell ทั้งหมด (32 ตัว) | 2,711 | 50 | 47 |
| **เฉพาะ 24 ตัวที่น่าจะเป็นบั๊ก** | **2,453** | **50** | **47** |

→ **ของที่ควรเดินทะลุได้ แต่กันทางอยู่จริง ~2,453 จุด กระจายใน 47 workspace**

**วัดยังไง:** SQL 4 ชุดด้านบน รันผ่าน `zyra-service/prod-db.sh query` (read-only) บน prod AlloyDB ผ่าน IAP tunnel
**ช่วงเวลา:** snapshot 2026-09-17 ~15:10 (ก่อนแก้ — ยังไม่มี after เพราะยังไม่ได้แก้)

### ข้อควรระวังในการตีความ

- ตัวเลข **24 ตัว = "น่าจะเป็นบั๊ก" ไม่ใช่ยืนยัน 100%** — ข้อมูลที่เก็บไว้แยกไม่ออกระหว่าง "fallback ปั๊มให้" กับ "admin ตั้งใจระบาย blocked ทั้งแผง" เพราะ cells หน้าตาเหมือนกันทุกประการ · ที่ใช้เป็นเกณฑ์คือ **ไม่มี cell walkable เลย** ซึ่งเข้ากับลายเซ็นของ fallback มากกว่า
- `machine` โดน 78% สูงผิดปกติเมื่อเทียบกับ `decoration` 26% — น่าจะเพราะ machine ส่วนใหญ่ถูกสร้างโดยไม่ระบาย hitbox (สมมติฐาน ยังไม่ได้ยืนยัน)
- `foods_and_drink` และ `walkable_group` **0 ทั้งคู่** — แปลว่าของ 2 type นี้ admin ระบาย walkable ครบทุกตัว หรือถูกสร้างผ่านเส้นทางอื่นที่ไม่ผ่าน fallback

### ผลต่อการตัดสินใจ backfill

เดิมเสนอว่า "แก้ไปข้างหน้าอย่างเดียว" — ตัวเลข 2,453 placement ใน 47 workspace **ใหญ่พอที่ควรพิจารณา backfill** สำหรับ 24 object ที่ไม่มี cell walkable เลย (ความเสี่ยงต่ำกว่าที่ประเมินไว้ตอนแรก เพราะกลุ่มผสม 8 ตัวที่ admin ตั้งใจระบาย แยกออกได้ด้วยเงื่อนไข `walkable_cells = 0`) — **ต้องให้ PM/ทีมเคาะ** ว่าจะ backfill หรือให้ admin ไล่แก้เอง 24 ตัว

## เกี่ยวข้องกับ

- [SC-OBJ-NAT-01 technical-design §3.2](../plan/%5BFeature%5D%20Nature%20Object%20Management%20%E2%80%94%20Object%20Management/technical-design.md) — เป็น **prerequisite ของ HP-02** เพราะ Nature ต้อง walkable เป็น default
- ZYR-1088 (`zyra-app/__tests__/tile-builder-hidden-objects.test.ts`) — คนละเรื่อง แต่แตะ tile-builder เหมือนกัน ระวังตอนแก้
