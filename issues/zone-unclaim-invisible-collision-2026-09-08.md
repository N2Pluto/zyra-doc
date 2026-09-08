# Unclaim zone แล้วของหายแต่เดินผ่านไม่ได้ (invisible wall)

> สถานะ: **แก้แล้ว merge เข้า develop 2026-09-08** — ยังไม่ live-verify บน dev
> กระทบ: `zyra-api` (PR #99) · `zyra-ws` (PR #58)
> อาการที่รายงาน: กด **Unclaim zone** → เฟอร์นิเจอร์หายจากจอ แต่เดินผ่านจุดนั้นไม่ได้ "เหมือนมีอะไรล่องหนตั้งอยู่"

---

## Root cause

`PrivateZoneClaimService.unclaim()` ลบเฟอร์นิเจอร์ของ claimant ด้วย SQL ของตัวเอง
(`zyra-api/internal/service/private_zone_claim_service.go` — `DELETE FROM tb_map_object
WHERE zone_id = $1 AND placed_by_user_id IS NOT NULL`) แล้ว broadcast `map_updated`
— **แต่ไม่เคยสั่ง republish obstacle grid**

obstacle grid เป็น **server-authoritative** และถูก rebuild เฉพาะเมื่อมีคนสั่ง republish
อย่างชัดเจนเท่านั้น (ตั้งแต่ย้ายจาก client poller มาเป็น republish-on-edit เมื่อ 2026-08-20 —
ดู `guides/` / memory `obstacle-grid-server-authoritative`) เพราะฉะนั้น:

| ชั้น | สถานะหลัง unclaim | ผลที่เห็น |
|---|---|---|
| Client | **ถูก** — `map_updated` → refetch → `importMap()` reset `blockedTiles` จาก row ที่เหลือ | ของหายจากจอจริง |
| Redis grid | **ค้าง** — footprint ของ object ที่ถูกลบยังอยู่ | — |
| zyra-ws | validate ทุกก้าวกับ grid ที่ค้าง (`movement_v2.go` `applyStep` → `stepBlocked`) | ก้าวขึ้น tile นั้นถูกปฏิเสธ = กำแพงล่องหน |

VO_MOVEMENT_V2 เดินเส้นทางบน server เอง (client ส่งแค่ intent) เพราะฉะนั้นไม่ใช่อาการ
rubber-band — ตัวละคร **หยุดนิ่ง** ตรงนั้นเลย ซึ่งตรงกับคำว่า "เหมือนมีอะไรล่องหน"

**ค้างตลอดไป** จนกว่าจะมีการแก้ object อื่นในแมพเดียวกัน (ซึ่ง republish ให้โดยบังเอิญ) —
presence-heartbeat self-heal ซ่อมเฉพาะกรณี key **หาย** ไม่ใช่ key **เก่า**

### ช่องเดียวกันที่เจอเพิ่ม

`MapVersionService.RestoreMapVersion` ลบ object ทั้งแมพแล้ว insert ใหม่ โดยไม่ republish
เหมือนกัน → กู้ version เก่าแล้วเฟอร์นิเจอร์ชุดเก่ายังบล็อกอยู่ และชุดใหม่เดินทะลุได้
แก้ไปพร้อมกันใน PR เดียว

---

## สิ่งที่แก้

### zyra-api PR #99
- `WorkspaceService.RepublishObstacleGridForMapNow` — republish **ทันที** ข้าม debounce
  (1s delay / 3s max wait) เพราะ bulk delete ครั้งเดียวไม่มี burst ให้ coalesce และ event
  ที่ตามมาต้องไม่ออกก่อน grid ถูกเขียนลง Redis
- เรียกใน `unclaim()` (เมื่อ `RemovedObjectCount > 0`) **ก่อน** broadcast ทั้งสองตัว
  และใน `RestoreMapVersion` หลัง commit
- wire ทั้งสอง service ใน `main.go` — **ชิ้นนี้สำคัญที่สุด**: setter เฉย ๆ ไม่มีผลอะไร
  เพราะ nil-guard ทำให้ hook ที่ไม่ได้ wire เป็น no-op เงียบ ๆ (ซึ่งเป็นวิธีที่บั๊กนี้ ship ออกไป)

`Claim()` ไม่ต้อง republish — `UPDATE tb_map_object SET placed_by_user_id, zone_id`
เปลี่ยนแค่ ownership metadata ไม่แตะ geometry

### zyra-ws PR #58
`Room.invalidateObstacleGrid()` เรียกจาก `BroadcastZoneEvent` เมื่อ relay
`zone_claim_changed` — ถ้าไม่มีชิ้นนี้ กำแพงจะหายภายใน **≤30 วินาที** (`obstacleTTL`)
ไม่ใช่ทันที ปลอดภัยเพราะ api publish grid ลง Redis **ก่อน** broadcast แล้ว

⚠️ **ห้ามทำกับ `map_object_changed`** — path นั้นยัง debounce 1s/3s อยู่ ถ้า invalidate ตอนนั้น
จะไปโหลด grid **เก่า** มา cache ใหม่อีก 30s = แย่กว่าเดิม มี test pin ไว้แล้ว

**ลำดับ deploy**: `zyra-api` #99 ต้องขึ้นก่อน `zyra-ws` #58

---

## Before/After

| Metric | Before | After | แหล่ง |
|---|---|---|---|
| จำนวน republish หลัง unclaim ที่ลบของ | **0** | **1** (ทันที ไม่ debounce) | อ่านจากโค้ด — ไม่มี call site ของ `RepublishObstacleGridForMap*` ใน `unclaim()` เลยก่อนแก้ |
| ระยะเวลาที่ tile ค้างบล็อก | **ไม่มีขอบเขต** — จนมีการแก้ object อื่นในแมพ | **0** (≤30s ถ้าไม่มี zyra-ws #58) | derive จาก `obstacleTTL = 30s` + ไม่มี path อื่นที่ rebuild grid |

**ยังไม่ได้วัด** (ตรงตาม [[before-after-metrics]] — ห้ามเดาตัวเลข):
- ยังไม่มีตัวเลขจาก Grafana/Loki ของจริง เพราะบั๊กนี้ไม่ได้สร้าง error rate หรือ log pattern
  ที่วัดได้ — มันคือการ **ยอมรับ** step ที่ควรผ่านแล้วปฏิเสธ ซึ่ง server มองว่าเป็น
  พฤติกรรมปกติ (`stepBlocked` ไม่ log)
- ยังไม่ได้ live-verify บน dev — ตัวเลขในตารางมาจากการอ่านโค้ด ไม่ใช่การวัด runtime

### วิธี verify บน dev (ยังไม่ได้ทำ)

1. claim zone → วางเฟอร์นิเจอร์ 3–4 ชิ้น → unclaim
2. ดู log `obstacle grid published` ต้องโผล่ **ทันที** ตอน unclaim
3. อ่าน grid จาก Redis ตรง ๆ — tile ของ object ที่ลบต้องไม่อยู่ใน `blocked` แล้ว
4. เดินผ่านจุดเดิม — **ต้องผ่านได้ทันที** (ถ้ายังต้องรอ ~30s แปลว่า zyra-ws #58 ไม่ทำงาน)
5. ทดสอบ version restore ซ้ำแบบเดียวกัน

---

## หนี้ที่เจอตอนไล่บั๊ก (ยังไม่แก้)

1. **`RestoreMapVersion` ทิ้ง `zone_id` / `placed_by_user_id`** — INSERT ตอน restore ไม่มีสองคอลัมน์นี้
   และ `snapshotObjects` ก็ไม่เก็บ → owner กู้ version เก่าแล้ว attribution ของ claimant
   ทุกคนหลุดหมด (unclaim หลังจากนั้นจะไม่ลบของให้)
2. **`tileCoord` เขียน fractional key** (`71.5,10.75`) ที่ lookup ไหนก็ match ไม่ได้ →
   ~17% ของ blocked tile บน prod ไม่มี collision ต้องแก้ client+server พร้อมกัน
3. **obstacle grid เป็นของ main map เท่านั้น** (`ORDER BY is_main DESC LIMIT 1`) →
   workspace หลายชั้นมี server-side collision แค่ชั้นหลัก
