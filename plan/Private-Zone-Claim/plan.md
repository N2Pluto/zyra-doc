# [Feature] Private Zone Claim — Virtual Office (Client)

> **ClickUp:** [86d3ej2nq](https://app.clickup.com/t/86d3ej2nq) · Status: `pending` · Tag: `client` · Assignee: Ponlawat Lueakaew
> **Figma file:** `Map8gX0L2hk7HnkaFRfhtj` — Zyra design (More Organised ver.)
> **เอกสารนี้:** Requirement (จาก ClickUp), Figma Spec, Technical Design, Task Breakdown, Test Plan

---

## 1. Overview

Feature ให้ Workspace Member ทุกคน **claim Private Zone** ใน Virtual Office เป็นพื้นที่ส่วนตัวของตัวเองได้ และสามารถจัดวาง/แก้ไข **Furniture, Decoration, Structure** ใน zone นั้นได้อย่างอิสระผ่าน **Zone Editor** (Space Builder แบบจำกัดขอบเขต)

### Business Rules

- **1 user = 1 zone ต่อ workspace** (claim ได้พร้อมกันแค่ 1 zone)
- เฉพาะ zone ที่ยังไม่มีเจ้าของ (unclaimed) เท่านั้น claim ได้
- เจ้าของ zone สามารถแก้ไข Furniture / Decoration / Structure ใน zone ได้อิสระ
- Unclaim ได้โดย: user เจ้าของเอง หรือ Workspace Owner/Admin



### Scenario Matrix


| ID       | ClickUp                                          | Scenario                                                  | Type       | Priority |
| -------- | ------------------------------------------------ | --------------------------------------------------------- | ---------- | -------- |
| SC-PZ-01 | [86d3ej2ry](https://app.clickup.com/t/86d3ej2ry) | ดู Private Zone Status บน Map (Claimed / Unclaimed)       | Happy Path | high     |
| SC-PZ-02 | [86d3ej2wz](https://app.clickup.com/t/86d3ej2wz) | Claim Private Zone                                        | Happy Path | high     |
| SC-PZ-03 | [86d3ej30a](https://app.clickup.com/t/86d3ej30a) | Claim ไม่ได้ (zone ถูก claim แล้ว / มี zone แล้ว)         | Error Path | normal   |
| SC-PZ-04 | [86d3ej32g](https://app.clickup.com/t/86d3ej32g) | เข้า Private Zone ของตัวเอง                               | Happy Path | high     |
| SC-PZ-05 | [86d3ej37k](https://app.clickup.com/t/86d3ej37k) | จัดวาง / เปลี่ยน Furniture, Decoration, Structure ใน Zone | Happy Path | high     |
| SC-PZ-06 | [86d3ej3at](https://app.clickup.com/t/86d3ej3at) | ย้าย / Rotate / ลบ Object ใน Zone                         | Happy Path | high     |
| SC-PZ-07 | [86d3ej3db](https://app.clickup.com/t/86d3ej3db) | Unclaim Zone (เจ้าของยกเลิกเอง)                           | Happy Path | high     |
| SC-PZ-08 | [86d3ej3fg](https://app.clickup.com/t/86d3ej3fg) | Admin Force Unclaim Zone                                  | Happy Path | normal   |


---



## 2. Scenario Detail (จาก ClickUp Subtasks)

> ⚠️ Section นี้คือ requirement ดิบจาก ClickUp — จุดที่ขัดกับ Figma ให้ยึดตาม **Design Decisions §3.6** (PM confirm แล้ว: เอา Figma เป็นหลัก)



### SC-PZ-01 · ดู Private Zone Status บน Map

**Persona:** Workspace Member · **Pre-condition:** VO map มี Private Zone ≥ 1 zone

**Steps**

1. User เข้า Virtual Office — map โหลดเสร็จ
2. Private Zone แสดงบน map พร้อม visual indicator บอกสถานะ
3. Unclaimed zone: "Available" label + 🔓 icon
4. Claimed zone (ของคนอื่น): ชื่อเจ้าของ + 🔒 icon
5. Claimed zone (ของตัวเอง): "My Zone" label + 🏠 icon
6. Hover zone: tooltip แสดงรายละเอียด

**Zone Tooltip Details**


| สถานะ             | เนื้อหา tooltip                                                                |
| ----------------- | ------------------------------------------------------------------------------ |
| Unclaimed         | 🔓 Zone ว่างอยู่ · "Claim เพื่อเป็นพื้นที่ส่วนตัวของคุณ" · ปุ่ม `[Claim Zone]` |
| Claimed by others | 🔒 พื้นที่ของ [ชื่อ user] · claimed เมื่อ [วันที่] · (Knock เพื่อขอเข้า)       |
| My Zone           | 🏠 พื้นที่ของคุณ · ปุ่ม `[จัดแต่งห้อง]` `[Unclaim]`                            |


**Acceptance Criteria**

- Label บน zone: ชื่อ zone (ถ้ามี) + status icon
- Hover tooltip แสดงรายละเอียดและ action buttons
- Status อัปเดต real-time เมื่อมีคน claim/unclaim (WebSocket)
- Minimap: แสดง zone status ด้วยสีเดียวกัน
- Zone ที่ `knock_required = true`: แสดง 🔒 icon เพิ่มเติม

**Business Logic**

- Zone status เก็บใน `private_zone_claims` table
- Real-time update: `ws:zone:statusChanged { zone_id, status, owner_id, owner_name }`
- ถ้า user มี zone แล้ว: Unclaimed zones แสดง tooltip "คุณมีพื้นที่แล้ว ต้อง unclaim ก่อน"

**Figma:** [node 2536-72765](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2536-72765)

---



### SC-PZ-02 · Claim Private Zone

**Persona:** Workspace Member ที่ยังไม่มี zone · **Pre-condition:** Zone เป้าหมายยัง unclaimed, user ยังไม่มี zone ใน workspace นี้

**Steps**

1. User hover บน Unclaimed zone — เห็น tooltip "Zone ว่างอยู่"
2. กดปุ่ม "Claim Zone" ใน tooltip
3. Confirmation dialog: "ต้องการ Claim พื้นที่นี้เป็นของคุณใช่ไหม?" + input ตั้งชื่อ zone (optional, max 30 chars) + ปุ่ม "Claim" (primary) / "ยกเลิก"
4. กด Claim → server validate และสร้าง claim record
5. Zone overlay เปลี่ยนจากเขียว → น้ำเงิน "My Zone" ทันที
6. Toast: "🏠 คุณ Claim '[ชื่อ zone]' สำเร็จแล้ว!"
7. Broadcast ให้ทุกคนใน workspace เห็น zone เปลี่ยนเป็น claimed
8. ~~Notification ส่งให้ Workspace Owner/Admin~~ (ถูกตัดออกจาก scope — strikethrough ใน ClickUp)

**Acceptance Criteria**

- Claim ได้เฉพาะ Unclaimed zone เท่านั้น
- User ที่มี zone อยู่แล้ว: ปุ่ม Claim disabled + tooltip "Unclaim zone เดิมก่อน"
- ชื่อ zone: optional, max 30 chars — ถ้าไม่ตั้ง ใช้ "พื้นที่ของ [ชื่อ user]"
- Claim สำเร็จ: overlay เปลี่ยนทันที, toast, broadcast
- Race condition: คนแรกที่ server รับได้ zone, คนที่สองเห็น error
- ~~Owner/Admin ได้รับ in-app notification~~ (ตัดออก)

**Business Logic**

- Server validate ก่อน claim: (1) zone ยัง unclaimed (2) user ยังไม่มี zone ใน office นี้ (UNIQUE constraint)
- Race condition: DB transaction + `SELECT ... FOR UPDATE` เพื่อ atomic claim
- หลัง claim: zone ยังมี `knock_required = true` เหมือนเดิม (behavior ไม่เปลี่ยน)

**Figma:** [node 2566-281548](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2566-281548)

---



### SC-PZ-03 · Claim ไม่ได้ (Error Path)

**Persona:** Workspace Member พยายาม claim แต่มีเงื่อนไขขัดขวาง

**Error Case 1 — Zone ถูก Claim ไปแล้ว (Race Condition)**

1. User เห็น zone เป็น unclaimed (tooltip "Available")
2. ระหว่างอ่าน tooltip มีคน claim ตัดหน้า
3. User กด "Claim Zone" → server ตรวจ → zone ถูก claim แล้ว
4. Error dialog: "Zone นี้เพิ่งถูก claim โดย [ชื่อ user] กรุณาเลือก Zone อื่น"
5. Zone overlay บน map อัปเดตเป็น claimed ทันที

**Error Case 2 — User มี Zone แล้ว**

1. ปุ่ม "Claim Zone" disabled + tooltip: "คุณมีพื้นที่แล้ว กรุณา Unclaim '[ชื่อ zone เดิม]' ก่อน"
2. กด link "[ชื่อ zone เดิม]": camera pan ไปยัง zone เดิม + highlight 3 วินาที

**Acceptance Criteria**

- Race condition error: dialog แสดงชื่อ user ที่ claim ก่อน
- Zone overlay อัปเดต real-time ผ่าน WebSocket ก่อนที่ user จะ retry
- User มี zone แล้ว: disabled ตั้งแต่ต้น (ไม่ใช่ error หลัง submit)
- Link ไปยัง zone เดิม: camera pan + highlight 3 วินาที
- ไม่มี partial state: claim fail = ไม่มีผลกระทบใด ๆ

**Business Logic**

- Disable ปุ่ม: check ฝั่ง client ก่อน (เร็ว) แต่ server validate ซ้ำเสมอ
- `ws:zone:statusChanged` broadcast ทันทีเมื่อ claim สำเร็จ

**Figma:** [node 2572-377181](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2572-377181)

---



### SC-PZ-04 · เข้า Private Zone ของตัวเอง

**Persona:** Zone Owner · **Pre-condition:** user มี zone claim แล้ว

**Steps**

1. User เดิน avatar เข้า My Zone
2. Zone ตัวเองไม่ต้อง Knock — เข้าได้ทันที (bypass knock requirement)
3. เข้าสำเร็จ: แสดง zone name label "🏠 พื้นที่ของคุณ"
4. HUD แสดงปุ่ม "Zone Editor" มุมขวาล่าง (→ SC-PZ-05)
5. คนอื่นเข้า My Zone: ยังต้อง Knock ตามปกติ (SC-VO-08)

**Owner vs Visitor**


| Action               | Zone Owner       | Visitor    |
| -------------------- | ---------------- | ---------- |
| เข้า zone            | ทันที (no knock) | ต้อง Knock |
| เห็นปุ่ม Zone Editor | ✅                | ❌          |
| แก้ไข furniture      | ✅                | ❌          |
| Allow/Deny knock     | ✅                | —          |


**Acceptance Criteria**

- Owner เข้าได้ทันที ไม่มี knock dialog
- Owner เห็นปุ่ม "Zone Editor" บน HUD เมื่ออยู่ใน zone ตัวเอง
- Owner เห็น knock notification จากคนอื่นตามปกติ
- Visitor: knock ปกติตาม SC-VO-08
- Zone label แสดงชื่อที่ตั้งตอน claim (หรือ "พื้นที่ของ [ชื่อ]")

**Business Logic**

- Knock bypass: server check `owner_id === current_user_id` ก่อน allow instant entry
- ปุ่ม Zone Editor: แสดงเฉพาะเมื่อ user อยู่ใน zone ตัวเอง (zone boundary overlap) — ออกจาก zone แล้วหายอัตโนมัติ

**Figma:** [node 2572-382731](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2572-382731)

---



### SC-PZ-05 · จัดวาง / เปลี่ยน Furniture, Decoration, Structure ใน Zone

**Persona:** Zone Owner อยู่ใน zone ตัวเอง · **Pre-condition:** กดปุ่ม "Zone Editor"

**Steps**

1. กด "Zone Editor" บน HUD
2. Zone Editor mode เปิด — overlay เฉพาะ zone นั้น (ไม่ใช่ทั้ง map)
3. Object Library panel เปิดทางซ้าย: ทุกหมวดยกเว้น wall
4. Canvas แสดง zone boundary highlight + grid overlay
5. ลาก object จาก Library ลง zone — snap to grid, footprint preview (เขียว/แดง)
6. วาง / ย้าย / rotate / ลบ ได้อิสระ (→ SC-PZ-06)
7. กด "บันทึก" — save + hot reload สำหรับ users online ใน workspace

**Zone Editor Scope (เทียบ Space Builder)**


| Feature                | Zone Editor            | Space Builder (Admin) |
| ---------------------- | ---------------------- | --------------------- |
| วาง Object             | ✅ ใน zone เท่านั้น     | ✅ ทั้ง map            |
| ย้าย Object            | ✅ เฉพาะ object ใน zone | ✅ ทุก object          |
| ลบ Object              | ✅ เฉพาะ object ใน zone | ✅ ทุก object          |
| แก้ไข Object นอก zone  | ❌                      | ✅                     |
| เปลี่ยน Room Zone size | ❌                      | ✅                     |
| แก้ไข Tile / Floor     | ❌                      | ✅                     |
| Collision Toggle       | ✅ (ต่อ object)         | ✅                     |
| Undo/Redo              | ✅ (20 steps)           | ✅ (20 steps)          |


**Acceptance Criteria**

- Zone Editor เปิดแบบ overlay mode — ไม่แทน map ทั้งหมด
- Object Library: Furniture, Decoration, Structure (ไม่มี Walkable Group)
- Drop นอก zone: shake animation + "วางได้เฉพาะในพื้นที่ของคุณ"
- Object นอก zone: click ไม่ได้ (readonly)
- Zone boundary highlight: dashed border สีน้ำเงิน ขณะ editor mode
- **Object limit ใน zone: 20 objects**
- บันทึก: save พร้อม hot reload เหมือน Space Builder (SC-SB-10)
- Undo/Redo: Cmd+Z / Cmd+Shift+Z สูงสุด 20 steps

**Business Logic**

- Zone Editor แก้ map.json ของ workspace (Objects layer) เหมือน Space Builder
- Server validate ว่า object ที่แก้อยู่ใน zone boundary เท่านั้น
- Object ที่วางใน zone: เก็บ `zone_id` ใน placed_object metadata เพื่อ track ownership
- Permission: user ต้องเป็น owner ของ zone + อยู่ใน zone ขณะแก้ไข

**Figma:** [node 2591-575929](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2591-575929)

---



### SC-PZ-06 · ย้าย / Rotate / ลบ Object ใน Zone

**Persona:** Zone Owner ใน Zone Editor mode · **Pre-condition:** มี objects ใน zone แล้ว

**Steps**

- **ย้าย:** click object → selection highlight + handles → drag ภายใน zone → snap to grid → footprint แดงถ้าใกล้ boundary/collision → drop สำเร็จ
- **Rotate:** click object → กด `R` หรือ rotate handle → 90°/180°/270°/0° เหมือน Space Builder
- **ลบ:** click object → `Delete` key หรือ Trash icon → ลบทันทีไม่มี confirmation (มี Undo)
- **Drop นอก zone:** object snap กลับตำแหน่งเดิม + toast "วางได้เฉพาะในพื้นที่ของคุณ"

**Acceptance Criteria**

- Selection: click object → handles ปรากฏ
- Move: snap to grid + footprint preview
- Drop นอก zone: snap กลับ + toast warning
- Rotate: R key หรือ handle 4 ทิศ
- Delete: ไม่มี confirmation (มี Undo)
- Multi-select: Shift+Click หลาย objects (max 20)
- Object นอก zone: click ไม่ได้ (engine ignore click นอก boundary)
- Undo/Redo สูงสุด 20 steps

**Business Logic**

- ทุก drop/move validate ว่า object footprint **ทั้งหมด** อยู่ใน zone rect
- Object ที่ Admin วางใน zone: user ย้าย/ลบได้ (zone เป็นของ user)
- Object นอก zone: readonly ใน Zone Editor mode

**Figma:** [node 2624-23813](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2624-23813)

---



### SC-PZ-07 · Unclaim Zone (เจ้าของยกเลิกเอง)

**Persona:** Zone Owner · **Pre-condition:** มี zone claim อยู่

**Steps**

1. Hover My Zone → tooltip "🏠 พื้นที่ของคุณ"
2. กดปุ่ม "Unclaim" ใน tooltip
3. Confirmation dialog: "ต้องการปล่อย Zone นี้คืนให้ Workspace ใช่หรือไม่?" + ปุ่ม "Unclaim" (สีแดง) / "ยกเลิก"
4. กด Unclaim → objects ที่ **user วาง** ถูกลบ, objects ที่ **Admin วาง** คงอยู่
5. Claim record ถูกลบ → zone overlay เปลี่ยนเป็นเขียว "Available" ทันที
6. Broadcast ให้ทุกคนใน workspace + toast "คุณปล่อย Zone คืนแล้ว"

**Acceptance Criteria**

- Unclaim button ใน tooltip ของ My Zone
- Confirmation dialog เน้น warning ว่า objects ของ user จะหายไป
- Objects ที่ admin วาง: คงอยู่หลัง unclaim
- Hot reload: users online เห็น objects หายทันที
- Zone status broadcast: ทุกคนเห็น zone กลับเป็น unclaimed
- หลัง unclaim: claim zone ใหม่ได้ทันที (ไม่มี cooldown)

**Business Logic**

- Keep admin objects: `WHERE zone_id = {zone_id} AND placed_by_user_id IS NULL` → keep
- Hot reload: map.json update + `ws:map:updated` broadcast

**Figma:** [node 2615-103354](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2615-103354)

---



### SC-PZ-08 · Admin Force Unclaim Zone

**Persona:** Workspace Owner / Admin · **Pre-condition:** zone ถูก claim โดย member

**Flow 1 — จาก Workspace Settings**

1. เข้า Workspace Settings → Tab Members หรือ Map
2. "Zone Claims" section: รายชื่อ member ที่ claim + ชื่อ zone + วันที่ claim
3. กด "Force Unclaim" → confirmation dialog: "ต้องการยกเลิก Claim ของ [ชื่อ user] ใช่หรือไม่?" + ⚠️ "Objects ที่ [ชื่อ user] วางไว้จะถูกลบออก"
4. Confirm → ลบ claim + objects ของ user นั้น
5. In-app notification ถึง user: "[ชื่อ Admin] ยกเลิก Zone claim ของคุณแล้ว"

**Flow 2 — จาก VO Map (Admin only)**

1. Admin hover zone ที่ถูก claim → tooltip แสดง owner + ปุ่ม "Force Unclaim" (เฉพาะ Admin)
2. กด → same flow

**Acceptance Criteria**

- Zone Claims list แสดง: ชื่อ zone, owner, claimed_at, object_count
- Force Unclaim: เฉพาะ Workspace Owner/Admin
- Warning dialog แสดงชื่อ user + object count ที่จะหายไป
- หลัง force unclaim: objects ของ user ถูกลบ, zone กลับ unclaimed
- Notification ถึง user ที่ถูก force unclaim พร้อมชื่อ Admin
- Hot reload broadcast ให้ทุกคน

**Business Logic**

- ใช้ logic เดียวกับ SC-PZ-07 แต่ caller ไม่ใช่ owner
- Permission: `workspace.zone.unclaim` (Workspace Owner/Admin role)
- Notification type: `zone_force_unclaimed`

**Figma:** [node 2615-184115](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2615-184115)

---



## 3. Figma Design Spec (แบบละเอียด)

> ดึงจาก Figma MCP (`get_metadata` + `get_design_context` + screenshot) — file `Map8gX0L2hk7HnkaFRfhtj`, base screen 1440×1024, font **Inter** ทั้งหมด



### 3.0 Design Tokens ที่ใช้ร่วมทุก scenario


| Token                                 | Value                                                     | Tailwind                                                                      |
| ------------------------------------- | --------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Background/Primary (panel/modal/menu) | `#242B32`                                                 | `bg-[#242B32]`                                                                |
| Shade Black/500 (toast/tooltip/label) | `#1A1B1E`                                                 | `bg-[#1A1B1E]`                                                                |
| Primary/500 (ปุ่มเขียว)               | `#58D68D`                                                 | `bg-[#58D68D]`                                                                |
| Primary/10% / 20%                     | `rgba(88,214,141,0.1)` / `rgba(88,214,141,0.2)`           | footprint เขียว / icon bg                                                     |
| Red/500                               | `#F03A3A`                                                 | ปุ่ม Unclaim, invalid border                                                  |
| Red/5% / 20%                          | `rgba(240,58,58,0.05)` / `rgba(240,58,58,0.2)`            | circle lock / error icon bg                                                   |
| Purple/500 (Me name tag)              | `#996ADF`                                                 | `bg-[#996ADF]`                                                                |
| Grey/100 / 300 / 400 / 500 / 700      | `#DBDFE3` / `#B2BBC3` / `#A3ADB8` / `#8C99A6` / `#636D76` | disabled btn / disabled border / disabled text / secondary text / placeholder |
| White 5% / 10% / 20%                  | `rgba(255,255,255,0.05 / 0.1 / 0.2)`                      | ghost btn / progress track / border                                           |
| Overlay                               | `rgba(0,0,0,0.5)`                                         | modal backdrop                                                                |
| Sub/Medium                            | Inter 16/22 w500                                          | modal title, card title                                                       |
| Body/Bold · Medium · Regular          | Inter 14/18 w700 · w500 · w400                            | toast title · panel header · body                                             |
| Caption 1/Medium                      | Inter 12/15 w500, ls -0.43px                              | zone label                                                                    |
| Caption/Regular                       | Inter 12/16 w400                                          | timestamps                                                                    |
| White shadow (toast/menu)             | `drop-shadow 0px 4px 8~16px rgba(255,255,255,0.08)`       |                                                                               |


**Pattern components ที่ใช้ซ้ำทุก scenario:**

- **Zone highlight overlay**: `bg-[rgba(0,0,0,0.2)]` (hover) หรือ `bg-[rgba(255,255,255,0.2)]` (editor/lock), `border-4 border-solid border-white`, ไม่มี radius, ขนาดตาม zone rect
- **Zone name label** ("Display on avatar head"): `bg-[#1A1B1E] border border-[rgba(255,255,255,0.2)] rounded-[6px] px-[6px] py-[4px] gap-[4px]` — avatar chip 24×24 (rounded-90px + status dot) + ชื่อ Inter Medium 12/15 white เช่น "Dechawat Phondechaphiphat's zone"
- **Toast มุมขวาบน** (x≈1048, y=16-24, w 336–368): `bg-[#1A1B1E] rounded-[16px] p-[16px] gap-[16px]` + icon button 40px (`p-[8px] rounded-[8px]` bg เขียว 20% = success / แดง 20% = error) + text 14/18 + Close X 16px
- **Submenu/context menu**: `bg-[#242B32] rounded-[16px] p-[8px] w-[200px]` shadow white 8%; item `p-[12px] min-h-[42px] rounded-[8px] gap-[8px]` icon 16px + Inter Regular 14/18 white
- **General modal**: `bg-[#242B32] backdrop-blur-[4px] rounded-[16px] p-[16px] gap-[24px] w-[458px]` กึ่งกลางจอ บน overlay ดำ 50% — header title 16/22 Medium + X 24px + divider `rgba(255,255,255,0.2)`; body 14/18 `#8C99A6`; ปุ่ม `h-[32px] px-[16px] py-[8px] rounded-[6px]` text 14/18
- **User status card** (profile popup มุมขวาบน x=1094 y=24): `bg-[#242B32] rounded-[16px] p-[16px] gap-[16px] w-[322px]` — avatar 56px + ชื่อ 16/22 + username `#8C99A6` 14/18 + divider + menu items + footer ปุ่ม Message (ขาว) / Wave (เขียว) `flex-1 h-[32px] rounded-[6px]`

---



### 3.1 SC-PZ-01 / SC-PZ-02 — node `2536-72765`, `2566-281548` (Zone Status + Claim)

**Frames PZ-01:** `2591:580773` base · `2566:285072`/`2566:285372` hover unclaimed (บน room / corridor) · `2566:285084`/`2566:285671` hover zone คนอื่น claim · `2615:183573` เรา claim แล้ว hover zone ว่าง
**Frames PZ-02:** `2566:287060` hover+ปุ่ม Claim · `2619:22035` claim สำเร็จ+toast · `2566:287692` hover my zone · `2566:290787`/`2566:298454`/`2566:298789` Edit zone name modal (ปกติ/พิมพ์/error) · `2566:299136` rename toast · `2619:22049` click my zone (self card) · `2566:288084`/`2566:288947` click zone คนอื่น (online/offline)

**PZ-01 — Zone status บน map:**


| Element                                                                   | Spec                                                                                                                                             |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Zone hover highlight (ทุก state)                                          | `bg-[rgba(0,0,0,0.2)]` + `border-4 border-solid border-white` ไม่มี radius — ขนาดตาม zone footprint จริง (ไม่ fix)                               |
| ปุ่ม **"Claim zone"** (zone ว่าง + เรายังไม่ claim) `2538:110615`         | `bg-[#58D68D] h-[24px] px-[8px] py-[6px] rounded-[4px] gap-[4px]` text Inter Regular 14/18 white — กลาง highlight                                |
| Tag **"Unclaimed zone"** (เรา claim แล้ว → hover zone ว่าง) `2615:183586` | `bg-[#1A1B1E] border border-white/20 rounded-[6px] px-[6px] py-[4px]` text Inter Medium 12/15 ls-0.43 white (104×32, **ไม่มี avatar ไม่มีปุ่ม**) |
| Tag **"{Owner}'s zone"** (zone คนอื่น) `2566:281658`                      | container เดียวกัน + avatar 24px วงกลม (`rounded-[90px]` + status dot เขียว=online / เทา=offline) + text 12/15 white (146×32)                    |


**สรุป state matrix (PZ-01):**


| สถานะ zone       | สถานะเรา        | Hover แสดง                                                                                  |
| ---------------- | --------------- | ------------------------------------------------------------------------------------------- |
| Unclaimed        | ยังไม่เคย claim | highlight ขาว + ปุ่มเขียว "Claim zone"                                                      |
| Unclaimed        | claim แล้ว      | highlight ขาว + tag "Unclaimed zone" (ไม่มีปุ่ม)                                            |
| Claimed by other | ใด ๆ            | highlight ขาว + tag "{Owner}'s zone" + avatar + status dot                                  |
| My zone          | —               | tag ชื่อ zone + avatar + **white glow** `drop-shadow 0 2px 6px #FFF` (marker ว่าเป็นของเรา) |


**PZ-02 — Claim flow (ตาม Figma):**

1. Hover unclaimed → กด "Claim zone" → **claim ทันที ไม่มี confirmation dialog** → toast "**Zone claimed successfully.**" + ชื่อ default = **"{ชื่อ user}'s zone"**
2. ตั้ง/แก้ชื่อทีหลัง: click my zone → self card → kebab ⋮ → **"Edit zone name" modal**
3. Click zone คนอื่น (online) → owner card เต็ม (Go to zone / Follow / Request to lead + Message / Wave) · (offline) → card ย่อ เหลือปุ่ม Message เดียว + dot เทา


| Element                                                            | Spec                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Edit zone name modal** `2566:298427` (458×243)                   | pattern General modal (§3.0) — Title "**Edit zone name**" 16/22 + X 24px + divider · Label "**Zone name**" 14/18 white · Input `h-[42px] bg-[#242B32] border border-white/20 rounded-[8px] px-[12px]` · **Char counter "{n}/30"** ชิดขวา (เลข = Medium white, /30 = `#8C99A6`) · **Error เกิน 30 ตัว: border + counter →** `#F03A3A` · Footer: "Cancel" (`bg-white text-[#1A1B1E]`) + "**Confirm**" (`bg-[#58D68D]` white) `h-[32px] px-[16px] rounded-[6px]` |
| Toast claim / rename `2619:22036`, `2619:22357` (368×72 top-right) | pattern toast (§3.0) icon check เขียว — "**Zone claimed successfully.**" / "**Zone name changed successfully.**"                                                                                                                                                                                                                                                                                                                                              |
| **Self card** (click my zone) `2619:22049`                         | `bg-[#242B32] rounded-[16px] p-[16px] w-[322px]` — avatar 56 + "My zone" 16/22 + ชื่อเรา `#8C99A6` + ปุ่ม: **Edit profile** (`bg-[#58D68D]` flex-1 h-32) + **Decorate** icon btn (`bg-white p-[8px] rounded-[6px]`) + **kebab ⋮** (`bg-white/5 border-white/20`) → เข้า Edit zone name                                                                                                                                                                        |
| Owner card online `2566:288084`                                    | pattern User status card (§3.0): "{Owner}'s zone" 16/22 + owner name + menu 3 รายการ + Message/Wave                                                                                                                                                                                                                                                                                                                                                           |
| Owner card offline `2566:288947`                                   | ตัด menu + Wave ออก — เหลือ Message เต็มกว้าง, dot เทา                                                                                                                                                                                                                                                                                                                                                                                                        |


**Text copy:** `Claim zone` · `Unclaimed zone` · `Zone claimed successfully.` · `Zone name changed successfully.` · `Edit zone name` · `Zone name` · `{n}/30` · `Cancel` · `Confirm` · `Go to zone` · `Follow` · `Request to lead` · `Message` · `Wave` · `Edit profile` · `My zone`

> ⚠️ **ต่างจาก ClickUp**: brief บอกกด Claim แล้วมี confirmation dialog + ตั้งชื่อในนั้น — Figma **claim ทันที** แล้วค่อย rename ผ่าน modal แยก · minimap ไม่มี state พิเศษใน Figma node นี้ (ดู §3.6)

---



### 3.2 SC-PZ-03 — node `2572-377181` (Claim ไม่ได้)

**Frames:** `2572:377205` hover unclaimed (claim ได้) · `2572:377207`+toast `2572:377209` race error · `2572:382720` hover ทั้งที่มี zone แล้ว · `2572:382172` click ทั้งที่มี zone แล้ว (ปุ่ม disabled)


| Element                                          | Spec                                                                                                                                                                                                                                                                                                          |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ปุ่ม Claim zone (enabled)                        | `bg-[#58D68D] h-[24px] px-[8px] py-[6px] rounded-[4px]` text "Claim zone" Inter Regular 14/18 white — ลอยบน zone highlight                                                                                                                                                                                    |
| ปุ่ม Claim zone (**disabled**)                   | `bg-[#DBDFE3] border border-[#B2BBC3] h-[24px] px-[8px] py-[4px] rounded-[4px]` text `#A3ADB8`                                                                                                                                                                                                                |
| Tag "Unclaimed zone" (user มี zone แล้ว → hover) | `bg-[#1A1B1E] border border-[rgba(255,255,255,0.2)] rounded-[6px] px-[6px] py-[4px]` text Inter Medium 12/15 white ~104×32                                                                                                                                                                                    |
| **Error toast (race)** `2572:377209`             | มุมขวาบน 368×~108 · icon X แดงใน `bg-[rgba(240,58,58,0.2)] w-[40px] rounded-[8px]` · Title **"Claim zone faild"** Bold 14/18 (typo ตาม Figma — ควรแก้เป็น failed ตอน implement?) · Body: "This zone was just claimed by **Conan Grey**. Please select another available area on the map." Regular 14/18 white |


**States:** (1) hover unclaimed ยังไม่มี zone → overlay + ปุ่มเขียว (2) race → error **toast** (3) hover เมื่อมี zone แล้ว → เห็นแค่ tag ดำ ไม่มีปุ่ม (4) click เมื่อมี zone แล้ว → ปุ่ม disabled เทา

> ⚠️ **ต่างจาก ClickUp**: brief บอก error เป็น **dialog** + link camera-pan ไป zone เดิม — Figma ใช้ **toast** และไม่มี link pan ไป zone เดิม (ดู §3.5 Open Questions)

---



### 3.3 SC-PZ-04 — node `2572-382731` (เข้า Zone ตัวเอง)

**Frames:** `2572:384303` my zone claimed · `2572:384728` own profile card · `2572:385685-86` Go to my zone · `2572:570964-65` เข้า zone ตัวเอง (เจ้าของอยู่/ไม่อยู่) · `2572:575644`/`2572:575294` visitor เจอ circle + Ask to join · `2572:571920` เจ้าของ lock ห้อง · `2572:573644`/`2572:574049` visitor ขอ permission → เข้าได้


| Element                                               | Spec                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Zone name label                                       | pattern "Display on avatar head" (§3.0) — "Dechawat Phondechaphiphat's zone"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Own profile card                                      | User status card แบบ collapsed: Edit profile (เขียว pill) + grid icon + kebab ⋮ → เปิด Zone owner submenu                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **Zone owner submenu** `2572:571933` (200×184)        | pattern submenu (§3.0) 4 items: **Go to zone** (pin) / **Unclaim zone** (X) / **Edit zone name** (pencil) / **Clear decoration** (eraser)                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| User status card (zone คนอื่น)                        | menu: Go to zone / Follow / Request to lead + ปุ่ม Message (ขาว) / Wave (เขียว)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **Circle (วงสนทนาใน zone)** `2572:573599`             | ellipse 200×50 `bg-[rgba(240,58,58,0.05)] border border-dashed border-[#F03A3A] rounded-[90px]`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ปุ่ม **"Ask to join"** `2572:573629`                  | `bg-[#58D68D] px-[8px] py-[6px] rounded-[4px]` text 14/18 white 85×24 — โผล่เมื่อ hover circle                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| Lock overlay                                          | rect `bg-[rgba(255,255,255,0.2)] border-4 border-white` 196×126                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **Display panel (media room ของ zone)** `2572:574454` | กลางบนจอ y=24, `bg-[rgba(36,43,50,0.8)] backdrop-blur-[6px] rounded-[16px] p-[8px] gap-[8px]` — header: zone name Medium 14/18 + member count chip (`h-[24px] p-[4px] rounded-[6px] bg-white/5 border-white/20` + icon + count + chevron) + ปุ่ม icon 4 ปุ่ม (`p-[4px] rounded-[4px]` 16px): **Lock** (locked = `bg-[rgba(240,58,58,0.1)] border-[rgba(240,58,58,0.2)]`), Link, Chat, Expand — video tiles `flex-1 h-[160px] bg-[#1A1B1E] rounded-[12px] p-[4px]` + avatar 56px + name pill (`bg-black backdrop-blur-[4px] px-[6px] py-[4px] rounded-[8px]` + mic-off แดง 14px + ชื่อ 12/15) |


**Owner behavior (จาก stickies):** เข้า zone ตัวเองได้ทันทีทั้งกรณีมี/ไม่มีคนในห้อง · Display panel เปิดอัตโนมัติ · owner กด Lock ห้องได้ · มี submenu จัดการ zone
**Visitor behavior:** ใช้ "Go to zone" จาก status card · เจอวงสนทนา → circle แดง dashed + hover → "Ask to join" · เจ้าของ lock → ต้องขอ permission หรือรอ Wave · ได้ permission → เข้าได้ + tile ถูกเพิ่ม

> ⚠️ **ต่างจาก ClickUp**: brief บอกมีปุ่ม "Zone Editor" บน HUD มุมขวาล่าง — Figma ใช้ **submenu จาก profile card** (Clear decoration / Edit zone name) และเข้า editor ผ่านเมนู "Decorate" · Figma ยังเพิ่ม flow "Circle + Ask to join + Lock" ที่ไม่อยู่ใน brief (ดู §3.5)

---



### 3.4 SC-PZ-05 / SC-PZ-06 — node `2591-575929`, `2624-23813` (Zone Editor)

**Frames PZ-05:** `2591:581785` จุดเริ่ม (กด Decorate) · `2599:700046` editor เปล่า · `2599:700225` ghost drag · `2599:727916`/`2599:728529` object menu (walkable/block) · `2639:222223+` tooltips · `2639:229648` search empty · `2599:731639`/`2603:732060` limit 21 ชิ้น + toast · `2615:17706` save failed · `2603:732790` save success
**Frames PZ-06:** `2624:141496-141509` select/rotate flow · `2624:144250` rotate directions · `2599:729587+` lock · `2599:730257+` delete · `2639:221508+` undo · `2639:220469+` clear · `2599:730921`/`2599:731279` drop นอก zone + snap back

**Layout editor (**`2599:700046`**):**

- **Grid overlay**: เส้น 1px white low-opacity ระยะ **40px** (1 tile = 40×40px) ทับทั้ง map area
- **Zone boundary highlight** `2591:582504`: `bg-[rgba(255,255,255,0.2)] border-4 border-solid border-white` (330×326 ตัวอย่าง) — **ขาวทึบ ไม่ใช่ dashed น้ำเงินตาม brief**
- **Panel อยู่ขวา** (ไม่ใช่ซ้ายตาม brief): "Map editor - Right panel" `2591:582860` — `absolute left-[1096px] top-[24px] w-[320px] h-[976px] bg-[#242B32] rounded-[16px] p-[16px] gap-[16px]`

**Right panel breakdown:**


| ส่วน        | Spec                                                                                                                                                                                                                                                              |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Header      | Title **"Decoration"** 16/22 Medium white + ปุ่ม **Cancel** (`bg-white text-[#1A1B1E] h-[24px] px-[8px] py-[6px] rounded-[4px]`) + **Save** (`bg-[#58D68D] text-white` เท่ากัน) gap 8px                                                                           |
| Search      | `h-[42px] rounded-[8px] border border-white/20 bg-[#242B32] px-[12px]` icon 16px + placeholder "Search for objects" `#636D76`                                                                                                                                     |
| Categories  | ปุ่ม icon 7 ปุ่ม `p-[8px] rounded-[6px]` 16px — active `bg-[#58D68D]`, inactive `bg-white/5 border-white/20` — Objects/Desk/Machine/Decor/Structure/Door/Walkable                                                                                                 |
| Object grid | `flex flex-wrap gap-[8px]`, card `size-[65px] rounded-[8px] p-[8px]` + tooltip hover (`bg-[#1A1B1E] rounded-[8px] p-[8px]` + หางสามเหลี่ยม + text 12/15)                                                                                                          |
| Footer      | "**Object limit**" 14/18 + progress bar `h-[8px] rounded-[90px] bg-white/10` fill `#58D68D` + counter "0**/20**" (เลข = Medium white, /20 = `#8C99A6`) · ปุ่ม **Undo / Redo** ซ้าย + **Clear** ขวา (`p-[4px] rounded-[4px] bg-white/5 border-white/20` icon 16px) |


**Object interaction:**


| Element                                                            | Spec                                                                                                                                                                                                                                                                                                  |
| ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Footprint valid (ghost drag / selection)                           | `size-[40px] p-[8px] bg-[rgba(88,214,141,0.1)] border border-[rgba(88,214,141,0.2)]` — object `opacity-80`                                                                                                                                                                                            |
| Footprint **invalid (นอก zone)** `2599:730923`                     | bg เดิม + **border** `#F03A3A` **ทึบ**                                                                                                                                                                                                                                                                |
| **Object menu** (select แล้ว, 152×32 ลอยเหนือ object ~40px)        | `bg-[#242B32] rounded-[8px] p-[4px] gap-[8px]` items `p-[4px] rounded-[4px]` icon 16px: [tint colour-wheel + chevron] [rotate] [lock/unlock toggle] [trash]                                                                                                                                           |
| **Rotate direction menu** `2624:145320` (128×32 ซ้อนเหนือเมนูหลัก) | โครงเดียวกัน 4 ลูกศร ←↑→↓ — **rotate ผ่านเมนูทิศทาง ไม่มี rotate handle ลาก**                                                                                                                                                                                                                         |
| Drop นอก zone                                                      | footprint แดง + **bottom notification** `2599:731256` (608×32 ล่างกลางจอ y=968): `bg-[rgba(0,0,0,0.7)] backdrop-blur-[4px] rounded-[8px] px-[8px] py-[4px]` text 14/18 white "**This area does not belong to your zone. Please place objects inside your designated zone**" + object shake + เด้งกลับ |


**Toasts (PZ-05):**


| Toast        | ขนาด    | Copy                                                                                                                             |
| ------------ | ------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Save success | 368×72  | "**Object saved successfully.**" (icon check เขียว)                                                                              |
| Object limit | 336×108 | Title Bold "**Object limit**" / "**Zone limit exceeded (Max 20 objects). Please delete an item to free up space.**" (icon X แดง) |
| Save failed  | 336×90  | Title Bold "**Save failed**" / "**Due to a network or system error. Please try again later.**" (icon X แดง)                      |


> ⚠️ **ต่างจาก ClickUp**: (1) panel อยู่**ขวา** ไม่ใช่ซ้าย (2) boundary = ขาวทึบ 4px ไม่ใช่ dashed น้ำเงิน (3) rotate ใช้เมนูทิศทาง ←↑→↓ ไม่ใช่ R key/handle (4) มีปุ่ม **Clear** (ลบทั้ง zone) ที่ brief ไม่ได้พูดถึง (5) object tint (colour wheel) โผล่ในเมนู (6) delete ผ่าน trash ในเมนู ไม่พูดถึง Delete key

---



### 3.5 SC-PZ-07 / SC-PZ-08 — node `2615-103354`, `2615-184115` (Unclaim / Force Unclaim)

**Frames PZ-07:** `2615:103361` hover my zone · `2615:103362` click → submenu · `2615:103363`+`2615:103366` confirm modal · `2619:23780`+toast `2619:23781` success
**Frames PZ-08:** `2615:184117` เริ่ม · `2615:190990` admin click zone คนอื่น → **Zone profile card** · `2615:184122`+modal `2615:184125` warning · `2619:23794`+toast · `2615:338631`+`2615:338633` notification toast ฝั่ง user · `2615:338630` Notification panel entry

**PZ-07 — Unclaim (เจ้าของ):**


| Element                                   | Spec                                                                                                                                                                                                                                                                                     |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hover my zone                             | zone highlight + name label **มี white drop-shadow** `0 2px 6px` (เฉพาะ zone ตัวเอง)                                                                                                                                                                                                     |
| Click my zone → **submenu** (200px)       | Go to zone / **Unclaim zone** / Edit zone name / Clear decoration (pattern §3.0)                                                                                                                                                                                                         |
| **Confirm modal** `2615:103366` (458×188) | Title "**Unclaim zone**" · Body: "**Are you sure This zone will become Unclaimed, and you'll lose access to its private features.**" 14/18 `#8C99A6` · Footer ขวา: ปุ่ม "Confirm" ขาว + "**Unclaim**" `bg-[#F03A3A]` white (Cancel ghost ซ้าย `opacity:0` ใน design — ดู Open Questions) |
| Success toast `2619:23781` (368×72)       | "**Zone unclaimed successfully.**" icon check เขียว                                                                                                                                                                                                                                      |


**PZ-08 — Force Unclaim (Admin):**


| Element                                                           | Spec                                                                                                                                                                                                                                                                                                                                  |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Zone profile card** (admin click zone คนอื่น) `I2615:190990`    | User status card 322px: avatar 56 + "**Conan Grey's zone**" 16/22 + "Conan Grey" `#8C99A6` + menu: Go to zone / Follow / Request to lead / **Force to unclaim zone** (X icon — admin เท่านั้น) + ปุ่ม Message / Wave                                                                                                                  |
| **Warning modal** `2615:184125` (458×206)                         | Title "**Force to unclaim zone?**" · Body 14/18 `#8C99A6` โดยส่วนเน้นเป็น**สีขาว**: "This will remove **Conan Grey's** claim from **Conan Grey's zone** and change the zone status to Unclaimed. They'll **no longer be able to use this zone's private features** until it's claimed again." · Footer: Confirm ขาว + **Unclaim** แดง |
| Success toast (admin) `2619:23795`                                | "**Zone removed successfully.**"                                                                                                                                                                                                                                                                                                      |
| **Notification toast ฝั่ง user** `2615:338633` (322×124 มุมขวาบน) | `bg-[#242B32] rounded-[16px] p-[16px] gap-[16px]` — avatar 40px + "**Conan Grey**" 16/22 + "**Remove** your zone • right now" (Remove = ขาว, ที่เหลือ `#8C99A6`) + ปุ่ม "**View detail**" full-width `bg-[#58D68D] h-[32px] rounded-[6px]` + X 16px top-right                                                                         |
| **Notification panel entry** `2615:338630`                        | panel เดิม (`bg-[#2B3540] w-[320px]`) — card unread `bg-white/5 p-[8px] rounded-[8px]`: avatar 32 + "Conan Grey" Medium 14/18 + "1 min ago" 12/16 `#8C99A6` + body "Conan Grey **remove** your zone and You'll need to claim it again to use its private features." · bell badge `bg-[#D41818]` เลข 10/14                             |


---



### 3.6 Design Decisions — ClickUp brief vs Figma (✅ confirm แล้ว 2026-07-08)

> **หลักการที่ PM ตัดสิน: เอา Figma เป็นหลัก** — ข้อที่เหลือ default ตาม Figma (rule 10 Figma fidelity 95–100%) เว้นแต่ระบุไว้ต่างหาก


| #   | ประเด็น                   | ✅ Decision                                                                                                                                                                                                                                   |
| --- | ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Q1  | Interaction บน zone       | **ตาม Figma: click zone → submenu/card** (hover = highlight + label; zone ว่าง hover เห็นปุ่ม Claim zone)                                                                                                                                    |
| Q2  | SC-PZ-08 admin UI         | **ตาม Figma: ไม่มี Zone Claims list ใน Settings** — Force Unclaim ผ่าน Zone profile card บน map เท่านั้น → **ตัด task E1 (settings list) ทิ้ง**                                                                                              |
| Q3  | ปุ่มใน confirm modal      | ตาม Figma pattern destructive: Cancel ghost + **Unclaim แดง** (ปุ่ม "Confirm" ขาวใน design เป็น variant showcase)                                                                                                                            |
| Q4  | SC-PZ-03 race error       | ตาม Figma: error **toast** มุมขวาบน (ไม่ใช่ dialog)                                                                                                                                                                                          |
| Q5  | SC-PZ-03 มี zone แล้ว     | ตาม Figma: hover = tag "Unclaimed zone" / click = ปุ่ม disabled เทา — **ไม่มี camera pan link**                                                                                                                                              |
| Q6  | เปิด Zone Editor          | ตาม Figma: ผ่านปุ่ม **Decorate** ใน self card (click zone ตัวเอง) — ไม่มีปุ่ม HUD แยก                                                                                                                                                        |
| Q7  | Editor panel              | **ตาม Figma: panel ขวา** — ✅ ตรงกับของจริงแล้ว: `object-library-panel.tsx` เป็น floating panel **dock ขวาโดย default** (มี search + category + grid + history tab อยู่แล้ว ที่ `/workspace/builder/[id]`) · boundary ใช้ขาวทึบ 4px ตาม Figma |
| Q8  | Rotate                    | **ตาม Figma: เมนูทิศทาง ←↑→↓** — ✅ มีอยู่แล้ว: `object-context-menu.tsx` มี direction picker (DIR_ARROW grid ←↑→↓) + tint color + lock + delete ครบ ตรง Figma object menu                                                                    |
| Q9  | สี overlay zone           | ตาม Figma: white border overlay + label/tag แยกสถานะ (ไม่ใช้เขียว/น้ำเงิน/ม่วง)                                                                                                                                                              |
| Q10 | ฟีเจอร์เกิน brief         | รวมตาม Figma: **Edit zone name**, **Clear decoration**, object tint, toast "Save failed" · ส่วน **Circle + Ask to join + Lock ห้อง** (PZ-04) เป็น zone-section/meeting flow เดิม — ไม่ใช่ scope ใหม่ของ feature นี้                          |
| Q11 | Copy ภาษา                 | **English ตาม Figma** (ตรง convention เดิมของโปรเจกต์: UI copy = English)                                                                                                                                                                    |
| Q12 | Typo "Claim zone faild"   | แก้เป็น "failed" ตอน implement + แจ้ง designer                                                                                                                                                                                               |
| Q13 | Claim flow                | **ตาม Figma: claim ทันที ไม่มี confirmation dialog** — ชื่อ default "{User}'s zone", rename ผ่าน "Edit zone name" modal (kebab ใน self card) → เพิ่ม endpoint PATCH rename                                                                   |
| Q14 | Minimap                   | ไม่มีใน Figma — ไม่ทำในเฟสนี้ (เพิ่มได้ภายหลังถ้า PM ต้องการ)                                                                                                                                                                                |
| Q15 | Owner card online/offline | ทำทั้ง 2 variants ตาม Figma (online เต็ม / offline เหลือ Message + dot เทา)                                                                                                                                                                  |


**ผลจากการไปดูโค้ดจริงที่** `/workspace/builder/[id]` **(HeroWorkspaceEditor userMode):**

- `object-library-panel.tsx` — panel dock ขวา + search + category filter 8 หมวด + object grid + hover preview + history tab **มีครบแล้ว** → Zone Editor แค่ (1) filter หมวดที่ไม่อนุญาต (2) เพิ่ม header Decoration + Save/Cancel (3) เพิ่ม footer Object limit progress (x/20) + Undo/Redo/Clear ตาม Figma
- `object-context-menu.tsx` — object menu ลอยเหนือ object: duplicate + tint color picker + rotate/direction picker (←↑→↓) + lock + delete **มีครบแล้ว** → D3 เหลือแค่ boundary clamp + snap-back + bottom warning
- ⚠️ หมวดใน Figma Decoration panel แสดง 7 ปุ่ม (รวม Door, Walkable) แต่ ClickUp บอกตัด wall + walkable group — ยึด ClickUp เรื่อง permission (ห้าม wall/walkable) และให้ category ที่เหลือตรง Figma

---



## 4. Technical Design



### 4.1 ของที่มีอยู่แล้ว (reuse ได้เลย)


| ส่วน                                       | ที่อยู่                                                                                                                                                                                   | สถานะ                                          |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| Zone type `private` + `knock_required`     | `zyra-api/migrations/34_create_tb_map_zone.sql` — `zone_type_enum ('room','meeting','spotlight','private')`, `knock_required BOOLEAN`                                                     | ✅ มีแล้ว                                       |
| Knock flow (SC-VO-08)                      | zyra-ws `hub/room.go` — `handleKnock:1584`, `handleKnockDecide:1652`, `handleKnockCancel:1728` + FE `vo-knock-notification.tsx`, `zone-locked-overlay.tsx`, `workspace-ws.ts:660 knock()` | ✅ ครบ — retarget จาก meeting เป็น private zone |
| Zone hover tooltip                         | `views/user/virtual-office/components/zone-hover-card.tsx` + `hero-virtual-office.tsx:4812` (`hoveredZone`)                                                                               | ✅ extend ได้ (ห้าม fork — rule 09)             |
| Zone boundary detection                    | `hero-virtual-office.tsx:3253` (`activeZone` useMemo point-in-rect)                                                                                                                       | ✅ ใช้ตรวจ "อยู่ใน zone ตัวเอง" ได้เลย          |
| Space Builder (userMode)                   | `views/admin/workspace-editor/hero-workspace-editor.tsx:111-127` — มี props `userMode`, `readOnly` แล้ว                                                                                   | ✅ เพิ่ม prop `zoneScope`                       |
| Undo/Redo 20 steps                         | `views/admin/workspace-editor/hooks/use-undo-redo.ts` (`MAX_HISTORY`)                                                                                                                     | ✅ ใช้ต่อ                                       |
| Multi-select cap 20                        | `stores/space-builder-store.ts` (`MULTI_SELECT_CAP=20`)                                                                                                                                   | ✅ ตรงกับ object limit พอดี                     |
| Zone-section grant/lock (analog ของ claim) | `zyra-api/internal/service/zone_section_service.go` + `handler/zone_section_handler.go` (`router.go:132-140`)                                                                             | ✅ ใช้เป็น pattern ต้นแบบ                       |
| Access log table                           | `migrations/49_private_zone_access_log.sql` (`tb_private_zone_access_log`) — migrate ไว้แล้ว แต่ยังไม่มี writer                                                                           | ✅ เพิ่ม writer                                 |
| Minimap zone-aware                         | `vo-minimap.tsx:323` (รับ `zones: MapZone[]` อยู่แล้ว)                                                                                                                                    | ✅ เพิ่มสีตาม claim status                      |
| Notification (in-app)                      | `notification_service.go` + `tb_notification` (type: mention/reply/group_add/reaction)                                                                                                    | ⚠️ ต้อง extend type + ปลด FK conversation      |
| Member management UI                       | `views/user/virtual-office/components/manage-members-modal.tsx:392`                                                                                                                       | ✅ เพิ่ม "Zone Claims" section                  |




### 4.2 Gaps ที่ต้องสร้างใหม่

1. **ตาราง claim + endpoints** — ยังไม่มีที่เก็บว่าใคร claim zone ไหน
2. **Map hot-reload broadcast** — **ยังไม่มี** `ws:map:updated` **ในระบบเลย** (ตรวจแล้วทั้ง zyra-app/zyra-ws) — Zone Editor save / unclaim จะไม่สะท้อนให้คน online เห็น ถ้าไม่สร้าง
3. **Zone-scoped restriction mode** ใน `HeroWorkspaceEditor`
4. **Object ownership tracking** — `tb_map_object` ยังไม่มี `placed_by_user_id` / `zone_id`
5. **Notification type ใหม่** `zone_force_unclaimed` (ปัจจุบัน notification ผูก conversation FK)



### 4.3 DB Migration (ต้องรันก่อน implement)

Migration ถัดไปคือ **58** (ล่าสุด = `57_avatar_audit_performed_by_text.sql`)
⚠️ migrations ไม่ auto-run — ต้อง apply ด้วย psql เอง

```sql
-- 58_create_tb_private_zone_claim.sql
CREATE TABLE IF NOT EXISTS tb_private_zone_claim (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES tb_workspace(id) ON DELETE CASCADE,
    map_id UUID NOT NULL REFERENCES tb_map(id) ON DELETE CASCADE,
    zone_id UUID NOT NULL REFERENCES tb_map_zone(id) ON DELETE CASCADE,
    user_id VARCHAR(36) NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,  -- tb_user.id เป็น VARCHAR ไม่ใช่ UUID
    zone_name VARCHAR(30),                       -- ชื่อที่ user ตั้ง (nullable → fallback "พื้นที่ของ [ชื่อ]")
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pz_claim_zone UNIQUE (zone_id),               -- 1 zone = 1 เจ้าของ
    CONSTRAINT uq_pz_claim_user UNIQUE (workspace_id, user_id)  -- 1 user = 1 zone ต่อ workspace
);
CREATE INDEX IF NOT EXISTS idx_pz_claim_workspace ON tb_private_zone_claim(workspace_id);

-- 59_map_object_ownership.sql — track ว่า object ไหน user วางใน zone ไหน
ALTER TABLE tb_map_object ADD COLUMN IF NOT EXISTS zone_id UUID REFERENCES tb_map_zone(id) ON DELETE SET NULL;
ALTER TABLE tb_map_object ADD COLUMN IF NOT EXISTS placed_by_user_id VARCHAR(36) REFERENCES tb_user(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_map_object_zone ON tb_map_object(zone_id) WHERE zone_id IS NOT NULL;
```

- Rollback script คู่กัน: `DROP TABLE tb_private_zone_claim;` / `ALTER TABLE tb_map_object DROP COLUMN ...`
- Objects ที่ Admin วาง: `placed_by_user_id IS NULL` → คงอยู่หลัง unclaim (ตรง SC-PZ-07)



### 4.4 zyra-api — API Contract

ทุก endpoint อยู่ใต้ `/api/user/*` (UserGuard) ตาม Member API Separation Policy — ห้ามใช้ `/api/admin/*`
Force unclaim ใช้ role check ใน service (owner/admin) แบบเดียวกับ `workspace_member_service.go` ไม่ใช่ AdminGuard


| Method | Path                                                 | ใช้ใน                         | Response `Data`                                                                               |
| ------ | ---------------------------------------------------- | ----------------------------- | --------------------------------------------------------------------------------------------- |
| GET    | `/api/user/workspaces/:id/zone-claims`               | SC-PZ-01, 08                  | `[]ZoneClaimInfo{ zone_id, zone_name, owner_id, owner_name, claimed_at, object_count }`       |
| POST   | `/api/user/workspaces/:id/zones/:zoneId/claim`       | SC-PZ-02                      | `ZoneClaimInfo` — **ไม่มี body** (Q13: claim ทันที, ชื่อ default "{User}'s zone" ฝั่ง server) |
| PATCH  | `/api/user/workspaces/:id/zones/:zoneId/claim`       | SC-PZ-02 Edit zone name (Q13) | `ZoneClaimInfo` — body (FormData): `zone_name` ≤30 chars, owner เท่านั้น                      |
| DELETE | `/api/user/workspaces/:id/zones/:zoneId/claim`       | SC-PZ-07                      | `{ removed_object_count }` — owner เท่านั้น                                                   |
| DELETE | `/api/user/workspaces/:id/zones/:zoneId/claim/force` | SC-PZ-08                      | `{ removed_object_count }` — workspace owner/admin เท่านั้น                                   |


ทุก response ใช้ `model.APIResponse` envelope · Error mapping:


| Sentinel error (service)                                 | HTTP      | ใช้ใน scenario  |
| -------------------------------------------------------- | --------- | --------------- |
| `ErrZoneAlreadyClaimed` (+ ชื่อคน claim ใน message/data) | 409       | SC-PZ-03 case 1 |
| `ErrUserAlreadyHasZone`                                  | 409       | SC-PZ-03 case 2 |
| `ErrZoneNotPrivate` / `ErrZoneNotFound`                  | 400 / 404 | validate        |
| `ErrNotZoneOwner`                                        | 403       | SC-PZ-07        |
| `ErrInsufficientRole`                                    | 403       | SC-PZ-08        |
| `ErrZoneNameTooLong`                                     | 400       | SC-PZ-02        |


**Service layer** — `internal/service/private_zone_claim_service.go` (pattern ตาม `zone_section_service.go`):

```go
// Claim: atomic ด้วย transaction + SELECT FOR UPDATE กัน race condition (SC-PZ-02/03)
func (s *PrivateZoneClaimService) Claim(ctx context.Context, wsID, mapID, zoneID, userID, zoneName string) (*model.ZoneClaimInfo, error) {
    tx, err := s.db.BeginTx(ctx, pgx.TxOptions{})
    if err != nil { return nil, fmt.Errorf("begin tx: %w", err) }
    defer tx.Rollback(ctx)
    // 1. SELECT zone FOR UPDATE — ตรวจ zone_type='private'
    // 2. ตรวจ claim ซ้ำ (zone_id) → ErrZoneAlreadyClaimed พร้อม owner_name
    // 3. ตรวจ user มี zone แล้ว (workspace_id,user_id) → ErrUserAlreadyHasZone
    // 4. INSERT claim  (UNIQUE constraints เป็น safety net ชั้นสุดท้าย)
    // 5. INSERT tb_private_zone_access_log (action='claim' — ขยาย CHECK constraint หรือ log แยก)
    return info, tx.Commit(ctx)
}

// Unclaim / ForceUnclaim: ลบ claim + ลบเฉพาะ objects ที่ user วาง
//   DELETE FROM tb_map_object WHERE zone_id=$1 AND placed_by_user_id IS NOT NULL
//   (admin objects: placed_by_user_id IS NULL → keep)
```

**Zone Editor write-guard** — เพิ่มใน `user_workspace_handler.go` path เดิม (`AddUserMapObject:319`, `MoveUserMapObject:353`, `RemoveUserMapObject:417`):

- ถ้า request มาจาก Zone Editor (มี `zone_id` ใน payload): validate (1) caller เป็น claim owner ของ zone (2) object footprint ทั้งหมดอยู่ใน zone rect (3) object count ใน zone ≤ 20 (4) object type ไม่ใช่ wall/walkable
- ปัจจุบัน user editor endpoints เป็น owner-only (`ownerErr` ที่ `user_workspace_handler.go:35`) → ต้อง**ผ่อน guard เป็น "workspace owner หรือ zone-claim owner (เฉพาะ scope zone ตัวเอง)"**

**Knock bypass (SC-PZ-04):** เช็คใน zone enter path — ถ้า `claim.user_id == current_user` → ข้าม knock (ฝั่ง zyra-ws `handleKnock` + FE ไม่แสดง `ZoneLockedOverlay`)

### 4.5 zyra-ws — Realtime Events

Pattern: เพิ่ม const + payload ใน `hub/message.go`, เพิ่ม `case` ใน `handleClientMessage` switch (`room.go:372-475`)


> ✅ **User confirm (2026-07-09): realtime แบบสด** — คนอื่นใน map เห็น object ที่วาง/ย้าย/หมุน/ลบ **ทันทีทุก action** ไม่ต้องรอกด Save

| Direction     | Message                                 | Payload                                                                       | ใช้ใน                                                            |
| ------------- | --------------------------------------- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| S→C broadcast | `zone_claim_changed`                    | `{ zone_id, status: "claimed"|"unclaimed", owner_id, owner_name, zone_name }` | SC-PZ-01/02/03/07/08 — สอดคล้อง spec `ws:zone:statusChanged`     |
| S→C broadcast | **`map_object_changed`**                | `{ map_id, zone_id, action: "add"|"move"|"update"|"remove", object }`         | SC-PZ-05/06 — **live per-action**: client อื่น apply delta ใน engine ทันที (add/move/remove sprite) ไม่ต้อง refetch ทั้ง map |
| S→C broadcast | `map_updated`                           | `{ map_id, updated_by, scope: "zone", zone_id }`                              | bulk change เท่านั้น: unclaim/force ลบหลาย objects, version restore → refetch — **ทั้งสอง event ใหม่ (ยังไม่มีในระบบ)** |
| welcome state | `zone_claims` sync ใน `welcome` message | claims ทั้งหมดของ workspace                                                   | join แล้วเห็นสถานะถูกทันที (pattern เดียวกับ `PendingKnock:161`) |


**เส้นทาง trigger:** REST (zyra-api) เป็น source of truth — Zone Editor เป็น **write-through**: ทุก action (วาง/ย้าย/หมุน/ลบ/undo) ยิง endpoint object เดิมทันที (per-object endpoints มีอยู่แล้ว: `AddUserMapObject:319`, `MoveUserMapObject:353`, `RemoveUserMapObject:417`) → server validate zone scope → publish ผ่าน Redis (pattern เดียวกับ `cache.NotificationPublisher` → zyra-ws) → zyra-ws `broadcast()` ทั้ง workspace room
**ฝั่ง client เมื่อรับ** `map_object_changed`**:** apply delta ตรงเข้า engine (วาง/ย้าย/ลบ sprite ตัวเดียว) — ลื่นและถูกกว่า refetch · เมื่อรับ `map_updated` (bulk): refetch `getPublishedMapData(workspaceId)` (`lib/api/virtual-office.ts:29`) → update `useVOPrefetchStore.mapData` → engine reload objects (ไม่เตะ player ออก)
**Knock bypass:** `handleKnock` ฝั่ง hub ไม่ต้องแก้ — client เจ้าของ zone ไม่เรียก `knock()` ตั้งแต่แรก แต่ zyra-ws ควร validate เพิ่มว่า owner เข้าได้เลย (defense in depth ผ่าน internal API เช็ค claim)

### 4.6 zyra-app — Frontend Design

**Lib ใหม่:** `lib/api/private-zone-claims.ts` (authFetch → `/api/user/`* เท่านั้น)

```ts
export interface ZoneClaimInfo {
  zone_id: string
  zone_name: string | null
  owner_id: string
  owner_name: string
  claimed_at: string
  object_count: number
}
export async function listZoneClaims(workspaceId: string): Promise<ZoneClaimListResponse>
export async function claimZone(workspaceId: string, zoneId: string): Promise<ZoneClaimResponse> // Q13: ไม่ส่งชื่อ — server ตั้ง default
export async function renameZoneClaim(workspaceId: string, zoneId: string, zoneName: string): Promise<ZoneClaimResponse>
export async function unclaimZone(workspaceId: string, zoneId: string): Promise<UnclaimResponse>
export async function forceUnclaimZone(workspaceId: string, zoneId: string): Promise<UnclaimResponse>
```

TanStack Query key: `["zone-claims", workspaceId]` — invalidate เมื่อรับ `zone_claim_changed`

**Component ใหม่/แก้ไข** (Tailwind-only ตาม rule 08, icon จาก lucide-react เท่านั้น ตาม rule 12):


| Component                                          | ใหม่/แก้                         | หน้าที่                                                                                                                                                                                                                                                                         |
| -------------------------------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `zone-hover-card.tsx` / hover layer ใน hero        | **แก้** (เพิ่ม prop — ห้าม fork) | Hover states ตาม Figma PZ-01: highlight ขาว 4px + ปุ่ม "Claim zone" (zone ว่าง+เรายังไม่ claim) / tag "Unclaimed zone" (เรา claim แล้ว) / tag "{Owner}'s zone" + avatar + status dot                                                                                            |
| **Zone click → card/submenu**                      | **แก้/ใหม่**                     | Click zone ตัวเอง → self card (Edit profile / **Decorate** / kebab → Edit zone name + submenu Unclaim zone, Clear decoration) · click zone คนอื่น → owner card (online เต็ม / offline = Message เดียว) + "Force to unclaim zone" เฉพาะ admin — extend จาก User status card เดิม |
| `components/pz-edit-zone-name-modal.tsx`           | ใหม่                             | "Edit zone name" modal — input + counter {n}/30 + error border แดงเกิน limit (Figma `2566:298427`)                                                                                                                                                                              |
| `components/pz-unclaim-modal.tsx`                  | ใหม่                             | Confirm unclaim: Cancel ghost + ปุ่ม **Unclaim แดง** (Q3) — reuse สำหรับ force unclaim (เปลี่ยน copy + ชื่อ owner/zone เป็นสีขาว ตาม Figma `2615:184125`)                                                                                                                       |
| Error toast (race claim)                           | ใช้ `lib/toast.tsx` เดิม         | `zyraToast.errorWithTitle("Claim zone failed", "This zone was just claimed by {name}. ...")` — Q4 ใช้ toast ไม่ใช่ dialog (แก้ typo faild→failed, Q12)                                                                                                                          |
| Notification toast + panel entry (force unclaim)   | **แก้**                          | extend notification panel เดิม + toast card 322px "View detail" ตาม Figma `2615:338633` — SC-PZ-08                                                                                                                                                                              |
| `manage-members-modal.tsx` ~~Zone Claims section~~ | **ตัดออก (Q2)**                  | Force Unclaim ผ่าน card บน map เท่านั้น                                                                                                                                                                                                                                         |
| `vo-minimap.tsx` ~~zone status~~                   | **ตัดออก (Q14)**                 | ไม่มีใน Figma — ไว้เฟสหลัง                                                                                                                                                                                                                                                      |
| `hero-virtual-office.tsx`                          | **แก้**                          | โหลด claims, subscribe `zone_claim_changed`/`map_updated`, knock bypass owner, zone click handler → card, เปิด Zone Editor (Decoration mode) จากปุ่ม Decorate                                                                                                                   |


**Zone Editor (SC-PZ-05/06)** — ✅ **user confirm: ใช้ UI วาง object ชุดเดิมจาก `workspace/builder` ทั้งหมด** ไม่ rebuild ตาม Figma pixel — reuse `HeroWorkspaceEditor` + `object-library-panel` + `object-context-menu` + `drag-ghost-layer` + `use-undo-redo` ตามที่มีอยู่ (Figma เป็น reference เฉพาะส่วนที่ต้องเพิ่มใหม่: limit footer, boundary highlight, bottom warning) — เพิ่ม prop:

```ts
interface ZoneScope {
  zoneId: string
  rect: { x: number; y: number; width: number; height: number }
  objectLimit: number  // 20
}
// HeroWorkspaceEditorProps + zoneScope?: ZoneScope
```

พฤติกรรมเมื่อ `zoneScope` ถูกส่ง (ของเดิมมีเยอะแล้ว — ดู §3.6):

- **Object Library** (`object-library-panel.tsx` — dock ขวาอยู่แล้ว ✅): filter หมวด `wall` + `walkable_group` ออก · เพิ่ม header "Decoration" + ปุ่ม Save/Cancel · เพิ่ม footer **Object limit progress bar (x/20)** + Undo/Redo/Clear ตาม Figma
- **Object menu** (`object-context-menu.tsx` — tint/direction ←↑→↓/lock/delete มีครบแล้ว ✅): ซ่อนปุ่ม Duplicate ใน zone mode (Figma zone menu ไม่มี) หรือคงไว้ถ้านับ limit ถูก
- `placeObject:895` / move / drop: clamp ว่า footprint ทั้งหมดอยู่ใน `rect` — footprint border เปลี่ยนเป็นแดง `#F03A3A` เมื่อออกนอก zone · drop นอก zone: shake + snap กลับ + **bottom notification** "This area does not belong to your zone. Please place objects inside your designated zone" (Figma `2599:731256`)
- `findObjectAtTile:861`: object นอก zone → ไม่ selectable (readonly)
- Zone tool / tile tool / room-size / left-panel markers: ปิด
- Boundary highlight: **ขาวทึบ** `border-4 border-white` **+** `bg-white/20` (Q7 ตาม Figma) + grid overlay 40px
- Object count ≥ 20: บล็อกวางเพิ่ม + toast "Object limit — Zone limit exceeded (Max 20 objects). ..."
- **Clear**: ลบ object ทุกชิ้นใน zone (counter → 0/20, undo ได้)
- **Write mode = write-through (user confirm: realtime สด)** — **ไม่ใช้** `use-editor-write-buffer.ts` ใน zone mode: ทุก action ยิง endpoint ทันที (`addMapObject`/`moveMapObject`/`removeMapObject` + `zone_id`) → server validate + broadcast `map_object_changed` → คนอื่นใน map เห็น object โผล่/ย้าย/หายทันที · undo/redo = inverse operation ที่ write-through เหมือนกัน (คนอื่นเห็น undo ด้วย) · action fail → revert local + toast "Save failed — Due to a network or system error. Please try again later."
- **Save** = `saveMapVersion` snapshot + ปิด editor + toast "Object saved successfully." (ข้อมูล persist ไปแล้วระหว่างแต่ง) · **Cancel** = ปิด editor เฉย ๆ ไม่ revert (ทุกอย่าง commit แล้ว)
- เปิดแบบ overlay บน VO (ไม่ navigate ออกจาก `/workspace/...`) — เข้าจากปุ่ม **Decorate** ใน self card (Q6)



### 4.7 Notification (SC-PZ-08)

- ขยาย `tb_notification.type` ให้รองรับ `zone_force_unclaimed` และทำ `conversation_id`/`message_id` เป็น nullable (ตอนนี้ผูก chat FK) — รวมใน migration 58/59
- เพิ่ม `CreateZoneForceUnclaimedNotification` ใน `notification_service.go` (pattern `batchInsert:199`) → push ผ่าน `notificationPusher` เดิม



### 4.8 Data Flow สรุป

```
Claim:   กดปุ่ม Claim zone → POST /api/user/.../zones/:id/claim → service (tx + FOR UPDATE, ชื่อ default)
         → Redis publish → zyra-ws broadcast zone_claim_changed → ทุก client update overlay/tag

Edit:    ทุก action ใน Zone Editor (วาง/ย้าย/หมุน/ลบ/undo) → POST/PATCH/DELETE /api/user/maps/:mapId/objects ทันที
         (+zone_id, server validate boundary/limit-20/owner) → Redis publish → zyra-ws broadcast map_object_changed
         → client อื่น apply delta ใน engine ทันที (realtime สด — user confirm)
         กด Save → saveMapVersion snapshot + ปิด editor (ไม่มี batch write ตอน save)

Unclaim: DELETE claim → ลบ objects (placed_by_user_id IS NOT NULL) → broadcast zone_claim_changed + map_updated (bulk)
Force:   เหมือน Unclaim + role check (owner/admin) + notification zone_force_unclaimed → user ที่โดน
```

---



## 5. Task Breakdown

แบ่งให้แต่ละ task จบใน 1 PR (Conventional Commits) — เรียงตาม dependency

> ✅ Design decisions confirm แล้ว (§3.6 — เอา Figma เป็นหลัก): claim ทันทีไม่มี dialog, rename ผ่าน modal แยก, force unclaim ผ่าน card บน map (ไม่มี settings list), panel ขวา + object menu เดิม reuse ได้เลย — เริ่มได้ทุก phase



### Phase A — Backend Foundation (zyra-api)


| #   | Task                                                                                                                                                                                               | Commit                                        | Scope             | SC          |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- | ----------------- | ----------- |
| A1  | Migration 58+59: `tb_private_zone_claim`, object ownership columns, notification type + rollback scripts                                                                                           | `feat(api): add private zone claim schema`    | migrations        | ทั้งหมด     |
| A2  | `private_zone_claim_service.go`: Claim (tx + FOR UPDATE, ชื่อ default "{User}'s zone"), Rename (≤30), Unclaim, ForceUnclaim (role check), List (+object_count), sentinel errors, access-log writer | `feat(api): private zone claim service`       | service + model   | 02,03,07,08 |
| A3  | Handler + routes **5 endpoints** (claim/rename/unclaim/force/list) ใต้ `/api/user/workspaces/:id` + `APIResponse` envelope + error mapping                                                         | `feat(api): private zone claim endpoints`     | handler + router  | 02,03,07,08 |
| A4  | Zone-scoped write-guard ใน user map-object endpoints (boundary/limit-20/owner/ไม่ใช่ wall) + ผ่อน owner-only guard                                                                                 | `feat(api): zone-scoped object write guard`   | handler + service | 05,06       |
| A5  | Redis publish: `zone_claim_changed` หลัง claim/rename/unclaim + **`map_object_changed` ทุก object write** (write-through, realtime สด) + `map_updated` ตอน bulk + notification `zone_force_unclaimed` | `feat(api): zone claim events + notification` | service           | 01,05,06,08 |




### Phase B — Realtime (zyra-ws)


| #   | Task                                                                             | Commit                                              | Scope | SC          |
| --- | -------------------------------------------------------------------------------- | --------------------------------------------------- | ----- | ----------- |
| B1  | Message types `zone_claim_changed`, **`map_object_changed`** (per-action delta), `map_updated` (bulk) + Redis subscriber → broadcast | `feat(ws): zone claim + map update broadcasts`      | hub   | 01,05,06,07,08 |
| B2  | Sync `zone_claims` ใน welcome message + knock bypass validate สำหรับ zone owner  | `feat(ws): zone claims welcome sync + knock bypass` | hub   | 01,04       |




### Phase C — Frontend: Map Layer (zyra-app)


| #   | Task                                                                                                                                                                                                             | Commit                                          | Scope         | SC      |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | ------------- | ------- |
| C1  | `lib/api/private-zone-claims.ts` (5 functions) + TanStack Query hooks + WS handlers `zone_claim_changed` / **`map_object_changed` (apply delta เข้า engine)** / `map_updated` (refetch) ใน `workspace-ws.ts` + hero | `feat(app): private zone claim api + ws wiring` | lib           | ทั้งหมด |
| C2  | Zone hover states บน map: highlight ขาว 4px + ปุ่ม "Claim zone" / tag "Unclaimed zone" / tag "{Owner}'s zone" + avatar/status dot + white glow zone ตัวเอง                                                       | `feat(app): private zone status on map`         | VO components | 01      |
| C3  | Claim flow (instant): กดปุ่ม → POST claim → toast "Zone claimed successfully." + tag update + broadcast · self card (Decorate/kebab) · `pz-edit-zone-name-modal` + PATCH rename + counter 30 chars + error state | `feat(app): claim + edit zone name`             | VO components | 02      |
| C4  | Error paths: race → error toast (`zyraToast.errorWithTitle`) · มี zone แล้ว → hover เห็น tag เฉย ๆ / click เห็นปุ่ม disabled เทา                                                                                 | `feat(app): claim error handling`               | VO components | 03      |
| C5  | Owner entry: knock bypass ฝั่ง client, zone name label, zone click → self card / owner card (online+offline variants)                                                                                            | `feat(app): private zone owner entry + cards`   | hero-vo       | 04      |
| C6  | Unclaim flow: submenu "Unclaim zone" → `pz-unclaim-modal` (Unclaim แดง) → toast "Zone unclaimed successfully." + hot reload objects                                                                              | `feat(app): unclaim private zone`               | VO components | 07      |




### Phase D — Frontend: Zone Editor (zyra-app)


| #   | Task                                                                                                                                                                                                                                                                         | Commit                                 | Scope            | SC  |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- | ---------------- | --- |
| D1  | `zoneScope` prop ใน `HeroWorkspaceEditor`: filter หมวด wall/walkable ใน `object-library-panel` (dock ขวาอยู่แล้ว ✅) + header Decoration/Save/Cancel + footer Object limit (x/20) + Clear + boundary clamp + readonly นอก zone + ปิด zone/tile tools + boundary highlight ขาว | `feat(app): zone-scoped editor mode`   | workspace-editor | 05  |
| D2  | Zone Editor overlay mode ใน VO (เปิดจากปุ่ม Decorate ใน self card ไม่ navigate) + **write-through ทุก action** (ไม่ใช้ write-buffer ใน zone mode — คนอื่นเห็นสดทันที) + object limit 20 + toasts (saved/limit/failed) + Save = version snapshot + ปิด | `feat(app): zone editor overlay in vo` | VO + editor      | 05  |
| D3  | Move/rotate/delete ใน zone (reuse `object-context-menu` เดิม ✅ มี direction ←↑→↓/tint/lock/delete แล้ว): footprint แดงนอก boundary + snap-back + bottom warning + multi-select ≤20 + undo/redo ใน scope                                                                      | `feat(app): zone object manipulation`  | editor           | 06  |




### Phase E — Frontend: Admin (zyra-app)


| #   | Task                                                                                                                                                                        | Commit                                  | Scope         | SC  |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- | ------------- | --- |
| E1  | ~~Zone Claims section ใน Settings~~ — **ตัดออกตาม Q2** (Figma ไม่มี)                                                                                                        | —                                       | —             | —   |
| E2  | Force Unclaim จาก Zone profile card บน map (menu item เฉพาะ admin) + warning modal + toast "Zone removed successfully." + notification toast/panel entry ฝั่งผู้ถูก unclaim | `feat(app): admin force unclaim on map` | VO components | 08  |




### Phase F — Tests & Verification


| #   | Task                                                                                                | Commit                                        |
| --- | --------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| F1  | Go: table-driven tests `private_zone_claim_service` (ทุก sentinel error + race) + write-guard tests | `test(api): private zone claim service tests` |
| F2  | Vitest: `private-zone-claims.ts` + dialogs + hover-card states                                      | `test(app): private zone claim tests`         |
| F3  | Multiplayer runtime verification (2 browsers) ตาม Test Plan §6.4                                    | —                                             |


**Dependency:** A1 → A2 → A3 → {A4, A5} → B1 → B2 → C1 → {C2..C6, E2} · D1 → D2 → D3 (D1 เริ่มขนานกับ Phase B ได้)

---



## 6. Test Plan



### 6.1 Go Unit Tests (zyra-api) — target ≥ 80% ของ service

ใช้ `testify/assert` + mock DB ด้วย interface (ห้ามต่อ PostgreSQL จริง) — table-driven ตามมาตรฐานโปรเจกต์

`private_zone_claim_service_test.go`


| Case                                            | Input/State                                | Expect                                             |
| ----------------------------------------------- | ------------------------------------------ | -------------------------------------------------- |
| claim unclaimed zone สำเร็จ                     | zone private, ไม่มี claim, user ไม่มี zone | claim record + info ถูกต้อง                        |
| claim zone ที่ถูก claim แล้ว                    | มี claim ของคนอื่น                         | `ErrZoneAlreadyClaimed` + owner_name               |
| claim ทั้งที่ user มี zone แล้ว                 | user มี claim ใน workspace เดิม            | `ErrUserAlreadyHasZone`                            |
| claim zone ที่ไม่ใช่ private                    | zone_type = meeting                        | `ErrZoneNotPrivate`                                |
| claim zone ไม่มีจริง                            | zone_id ปลอม                               | `ErrZoneNotFound`                                  |
| claim → ชื่อ default                            | claim สำเร็จ                               | zone_name = "{display name}'s zone" อัตโนมัติ      |
| rename สำเร็จ                                   | owner rename ≤30 chars                     | zone_name อัปเดต                                   |
| rename > 30 chars                               | zone_name 31 ตัว                           | `ErrZoneNameTooLong`                               |
| rename โดยคนที่ไม่ใช่ owner                     | caller ≠ owner                             | `ErrNotZoneOwner`                                  |
| unclaim โดย owner                               | caller = claim owner                       | claim หาย + ลบเฉพาะ user objects                   |
| unclaim โดยคนอื่น                               | caller ≠ owner                             | `ErrNotZoneOwner`                                  |
| unclaim: admin objects คงอยู่                   | mix objects (placed_by NULL / user)        | ลบเฉพาะ `placed_by_user_id IS NOT NULL`            |
| force unclaim โดย admin/owner                   | role = admin                               | สำเร็จ + notification สร้าง                        |
| force unclaim โดย member                        | role = member                              | `ErrInsufficientRole`                              |
| force unclaim: workspace owner ไม่มี member row | owner ผ่าน `tb_workspace.owner_id`         | สำเร็จ (owner อาจไม่มี row ใน tb_workspace_member) |
| tx fail ระหว่าง claim                           | INSERT error                               | rollback — ไม่มี partial state                     |


**Write-guard tests (zone-scoped object endpoints)**


| Case                                      | Expect                                         |
| ----------------------------------------- | ---------------------------------------------- |
| owner วาง object ใน zone ตัวเอง           | สำเร็จ + `zone_id`/`placed_by_user_id` ถูก set |
| วาง object footprint ล้นออกนอก zone rect  | reject 400                                     |
| วาง object ที่ 21 ใน zone                 | reject (limit 20)                              |
| วาง wall ผ่าน zone scope                  | reject                                         |
| non-owner พยายามแก้ object ใน zone คนอื่น | reject 403                                     |
| แก้ object นอก zone ผ่าน zone scope       | reject 403                                     |


**Race condition test:** goroutine 2 ตัว claim zone เดียวพร้อมกัน (mock tx serialize) → ตัวเดียวสำเร็จ, อีกตัว `ErrZoneAlreadyClaimed`

### 6.2 Vitest (zyra-app) — target ≥ 80% ของ `lib/*.ts`

ห้าม call `/api/*` จริง — `vi.mock` เสมอ, test happy + error path ทุก function

`lib/api/private-zone-claims.test.ts`

- `listZoneClaims` / `claimZone` / `renameZoneClaim` / `unclaimZone` / `forceUnclaimZone`: happy path → response ถูก parse
- status 409 `ErrZoneAlreadyClaimed` → error ถูกส่งต่อพร้อม owner_name
- status 403 → error ถูกส่งต่อ
- `renameZoneClaim` reject ชื่อ > 30 chars ก่อนยิง

**Component tests (critical paths)**

- `pz-edit-zone-name-modal`: Confirm เรียก `renameZoneClaim`, counter {n}/30 นับถูก, เกิน 30 → border/counter แดง + Confirm ไม่ทำงาน, Cancel ไม่เรียก
- `pz-unclaim-modal`: Unclaim (แดง) เรียก `unclaimZone`, variant force แสดงชื่อ owner/zone สีขาว + เรียก `forceUnclaimZone`
- Zone hover layer: render states ตาม Figma (ว่าง+เรายังไม่ claim → ปุ่ม "Claim zone" / เรา claim แล้ว → tag "Unclaimed zone" / zone คนอื่น → tag ชื่อ+avatar+status dot / zone เรา → white glow)
- Self card / owner card: Decorate + kebab แสดงเฉพาะ zone ตัวเอง, "Force to unclaim zone" แสดงเฉพาะ admin, offline variant เหลือ Message
- WS handler: รับ `zone_claim_changed` → query invalidate + overlay update, รับ `map_object_changed` → apply delta เข้า engine (add/move/remove ถูก object), รับ `map_updated` → trigger refetch



### 6.3 Manual E2E — Scenario Acceptance (ทำครบทุก SC ก่อน mark done)


| #   | Test                        | Steps                                                                    | Pass criteria                                                                                                                        |
| --- | --------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| T01 | SC-PZ-01 สถานะบน map        | เข้า VO ที่มี zone ครบ 3 สถานะ                                           | icon/label/tooltip/minimap ตรง spec ทั้ง 3 แบบ                                                                                       |
| T02 | SC-PZ-02 claim สำเร็จ       | hover → Claim (flow ตามที่ confirm ใน Q13)                               | overlay/tag เปลี่ยนทันที + toast + client อื่นเห็น realtime · ชื่อ default "{User}'s zone"                                           |
| T03 | SC-PZ-02 rename zone        | self card → kebab → Edit zone name → พิมพ์ ≤30 / เกิน 30                 | บันทึกสำเร็จ + toast · เกิน limit เห็น border+counter แดง, Confirm ไม่ผ่าน                                                           |
| T04 | SC-PZ-03 race               | 2 browsers claim zone เดียวพร้อมกัน                                      | คนแรกได้, คนสองเห็น error dialog + ชื่อคนแรก + overlay update                                                                        |
| T05 | SC-PZ-03 มี zone แล้ว       | user มี zone → hover / click zone ว่างอื่น                               | hover เห็น tag "Unclaimed zone" (ไม่มีปุ่ม) · click เห็นปุ่ม Claim disabled เทา (Q5)                                                 |
| T06 | SC-PZ-04 owner เข้า zone    | เดินเข้า zone ตัวเอง (knock_required=true)                               | ไม่มี knock dialog, เห็น label + ปุ่ม Zone Editor, ออกแล้วปุ่มหาย                                                                    |
| T07 | SC-PZ-04 visitor เข้า zone  | user อื่นเดินเข้า                                                        | knock flow ปกติ (SC-VO-08 ไม่ regress)                                                                                               |
| T08 | SC-PZ-05 วาง object (realtime สด) | เปิด Zone Editor → ลากวาง (browser B เปิดดูอยู่)                    | snap grid, footprint เขียว/แดง, ไม่มี wall ใน library, **B เห็น object โผล่ทันทีที่วาง — ก่อนกด Save** · undo ที่ A → B เห็นหาย |
| T09 | SC-PZ-05 drop นอก zone      | ลาก object ออกนอก boundary                                               | shake + toast + ไม่วาง                                                                                                               |
| T10 | SC-PZ-05 limit              | วาง object ตัวที่ 21                                                     | ถูกบล็อก + แจ้งเตือน                                                                                                                 |
| T11 | SC-PZ-06 move/rotate/delete | ครบ 3 action + undo/redo 20 steps + multi-select                         | ตรง AC ทุกข้อ, object นอก zone click ไม่ได้                                                                                          |
| T12 | SC-PZ-07 unclaim            | tooltip → Unclaim → confirm                                              | user objects หาย, admin objects อยู่, zone เขียว, claim ใหม่ได้ทันที                                                                 |
| T13 | SC-PZ-08 force unclaim      | admin click zone ที่ถูก claim → card → "Force to unclaim zone" → confirm | warning modal มีชื่อ owner/zone, objects ของ user หาย, toast "Zone removed successfully.", notification toast + panel entry ถึง user |
| T14 | SC-PZ-08 permission         | member (non-admin) click zone คนอื่น                                     | **ไม่เห็น** menu "Force to unclaim zone"                                                                                             |
| T15 | Reload persistence          | refresh browser หลัง claim/วาง object                                    | สถานะ + objects คงอยู่ (welcome sync ทำงาน)                                                                                          |
| T16 | Security                    | ยิง claim/edit/force ตรงด้วย curl ข้าม validation client                 | server reject ทุก case (403/409) — client check เป็นแค่ UX                                                                           |




### 6.4 Multiplayer Runtime Verification

ตาม convention โปรเจกต์ (chat-space rebuild เคยต้องทำ): เปิด 2+ browsers ด้วย user คนละคน

- Claim/unclaim จาก browser A → browser B เห็น overlay/tooltip/minimap เปลี่ยน **โดยไม่ refresh**
- Zone Editor: A วาง/ย้าย/หมุน/ลบ object → B เห็นเปลี่ยน**ทันทีทุก action** โดยไม่ refresh และไม่ถูกเตะออกจาก map · unclaim (bulk ลบ) → B เห็น objects หายพร้อมกัน
- Force unclaim โดย admin → เจ้าของ zone ได้ notification ทันที
- Knock: B knock zone ของ A → A ได้ notification card, A อยู่นอก zone ก็ยังได้รับ



### 6.5 Regression Checklist

- [ ] Meeting zone knock flow เดิม (SC-VO-08) ไม่พัง
- [ ] Space Builder (admin + userMode เต็ม map) ไม่ได้รับผลจาก `zoneScope` prop ใหม่
- [ ] `go test ./...` + `vitest run` ผ่านทั้งหมด
- [ ] `npx tsc --noEmit` + `npm run lint` ผ่าน (zyra-app)
- [ ] Zone-section (meeting) enter/leave/grant/lock เดิมทำงานปกติ