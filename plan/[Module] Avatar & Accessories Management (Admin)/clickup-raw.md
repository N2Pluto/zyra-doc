# ClickUp raw dump — [Module] Avatar & Accessories Management (Admin)

> **ดึงเมื่อ:** 2026-10-21 · workspace `36898257` · เนื้อหา description คัดลอกตรงจาก ClickUp (markdown) ไม่ตัดต่อ — ใช้เทียบเมื่อสงสัยว่า [spec.md](spec.md) ตีความผิด
> ทุกใบ: comments = 0 · attachments = 0 · checklists = 0 · dependencies = 0 · linked_tasks = 0

---

## 86d43pbbj · [Module] · Avatar & Accessories Management (Admin)

| field | value |
|---|---|
| url | https://app.clickup.com/t/86d43pbbj |
| status | in progress (#ee5e99) |
| priority | high |
| tags | admin |
| custom_fields | Desktop (checkbox) = true |
| creator | Moss Pm (101028210) |
| assignees | P A (282712619, pai@hpktechnology.com) · Ponlawat Lueakaew (312660967, ten_dev@hpktechnology.com) |
| date_created | 1787303262493 → 2026-08-17 |
| date_updated | 1792554450720 → 2026-10-21 |
| due_date | 1791493200000 → 2026-10-08 |
| start_date / time_estimate / time_spent | null / null / 0 |
| list | List (901614367195) · folder Zyra World (90169187867) · space 90166731836 |
| watchers | 3 |
| git_links | error: Resource not found |

### description

```markdown
## Avatar & Accessories Management (Admin)

**Module:** Admin — Project Zyra
**Persona:** System Admin
**Priority:** High

* * *

## Overview & Goal
System Admin จัดการ Avatar Skin และ Accessories ทั้งหมดใน platform — upload sprites, จัดหมวดหมู่, เปิด/ซ่อน ให้ user เลือกใช้ได้ฟรีทั้งหมด

**Avatar Model:**
*   Avatar = 1 base character ต่อ platform (ทุกคนใช้ตัวเดียวกัน)
*   Skin = Color/Style variant ของ character (เช่น สีผิว, สีผม, ชุด base)
*   Accessories = ของตกแต่งแยก slot: Hat, Glasses, Outfit, Bag, Wings/Cape

**Scope Admin:**
*   จัดการ Skin library (upload, ตั้งชื่อ, เปิด/ซ่อน)
*   จัดการ Accessories library แต่ละ category
*   กำหนด preview และ metadata

* * *

## Subtasks

| # | Scenario | Type |
| ---| ---| --- |
| SC-AV-01-HP-01 | List Skin และ Accessories ทั้งหมด | Happy Path |
| SC-AV-01-HP-02 | Upload Skin ใหม่ | Happy Path |
| SC-AV-01-HP-03 | Upload Accessory ใหม่ | Happy Path |
| SC-AV-01-HP-04 | แก้ไข Metadata (ชื่อ, category, status) | Happy Path |
| SC-AV-01-HP-05 | Hide / Unhide Skin หรือ Accessory | Happy Path |
| SC-AV-01-HP-06 | ลบ Skin หรือ Accessory | Happy Path |
| SC-AV-01-EP-01 | Upload Sprite ไม่ผ่าน Validation | Error Path |
| SC-AV-01-EC-01 | ลบ Item ที่มี User ใช้งานอยู่ | Edge Case |

* * *

## Avatar System Architecture

```erlang
Base Character (1 ตัวสำหรับ platform)
     │
     ├── Skins (Color/Style variants)
     │     ├── Default (สีผิวปกติ)
     │     ├── Tan
     │     ├── Dark
     │     └── ...
     │
     └── Accessories Slots (สวมทับ skin)
           ├── Hat     → Hat A / Hat B / Helmet / ...
           ├── Glasses → Round / Square / Sunglasses / ...
           ├── Outfit  → Casual / Formal / Hoodie / ...
           ├── Bag     → Backpack / Satchel / ...
           └── Wings   → Angel / Fairy / ...
```

* * *

##
```

(description จบด้วย `##` ว่าง — ใน ClickUp ไม่มีเนื้อหาต่อจากนี้)

---

## 86d43pbfu · SC-AV-01-HP-01 · List Skin และ Accessories ทั้งหมด

| field | value |
|---|---|
| url | https://app.clickup.com/t/86d43pbfu |
| status | in progress · priority high · assignees — · due — |
| created / updated | 2026-08-17 / 2026-10-21 · creator Moss Pm · watchers 3 |

```markdown
## SC-AV-01-HP-01 · List Skin และ Accessories ทั้งหมด

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Admin เข้าหน้า Avatar Management

* * *

## Scenario Steps

1. Admin เข้า System Admin Dashboard → **Avatar Management**
2. หน้าแบ่ง 2 tabs: **Skins** และ **Accessories**
3. Tab Skins: แสดง skin ทั้งหมดเป็น grid พร้อม thumbnail
4. Tab Accessories: แบ่ง sub-tabs ตาม category (Hat, Glasses, Outfit, Bag, Wings)
5. แต่ละ item แสดง: thumbnail, ชื่อ, status badge, จำนวน users ที่ใช้, action buttons

* * *

## Acceptance Criteria
*   Tab Skins: แสดง skins ทั้งหมดเป็น grid, pagination 20/หน้า
*   Tab Accessories: sub-tabs Hat / Glasses / Outfit / Bag / Wings
*   แต่ละ item card: thumbnail, ชื่อ, status badge (✅ Active / 🚫 Hidden), user count
*   Filter: All / Active / Hidden
*   Search: ค้นหาชื่อ item
*   Sort: ใหม่สุด / เก่าสุด / ชื่อ A-Z / ใช้มากสุด
*   กด item card: เปิด detail/edit page

* * *

## UX/UI

https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6942-489346&t=x3XAuSnXb5QzUGej-0
```

---

## 86d43pbne · SC-AV-01-HP-02 · Upload Skin ใหม่

| field | value |
|---|---|
| url | https://app.clickup.com/t/86d43pbne |
| status | **Closed** (date_closed 1792033334544 → 2026-10-15) · priority high · assignees — · due — |
| created / updated | 2026-08-17 / 2026-10-15 · creator Moss Pm · watchers 2 |

```markdown
## SC-AV-01-HP-02 · Upload Skin ใหม่

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Admin กด "+ Upload Skin ใหม่"

* * *

## Scenario Steps
1. Admin กด **"+ Upload Skin ใหม่"**
2. Upload form เปิด
3. Admin upload **Spritesheet PNG** ของ skin (4 directions: N/S/E/W + animations)
4. กรอก metadata: ชื่อ skin, sort order, status (Active/Hidden)
5. Preview: แสดง skin บน base character ทั้ง 4 ทิศ
6. กด "บันทึก" → skin พร้อมใช้งานใน Avatar Customization (ถ้า Active)

* * *

## Skin Spritesheet Spec

```yaml
Format: PNG, transparent background
Layout: horizontal strip ต่อ animation state
Size per frame: 64×64px หรือ 32×32px (ตาม tile_size)

Required animation states:
- walk_s (South ↓) : 4 frames
- walk_n (North ↑) : 4 frames
- walk_e (East →)  : 4 frames
- walk_w (West ←)  : 4 frames
- idle_s           : 2 frames
- sit              : 2 frames (optional)

Total spritesheet: width = frames × 64px, height = states × 64px
```

* * *

## Acceptance Criteria
*   Upload PNG: max 5MB, transparent background, spritesheet format
*   ชื่อ skin: required, max 50 ตัวอักษร, unique
*   Status default: Hidden (ต้อง review ก่อน Active)
*   Preview: แสดง idle\_s animation บน base character หลัง upload
*   Thumbnail: auto-generate จาก frame แรกของ idle\_s (400×400px)
*   Validate spritesheet dimensions: ต้องหารด้วย frame size (64px) ลงตัว
*   "Default" skin: ลบ/ซ่อนไม่ได้ (ต้องมีอย่างน้อย 1 skin active เสมอ)

* * *
```

(ไม่มี UX/UI link)

---

## 86d43pbv6 · SC-AV-01-HP-03 · Upload Accessory ใหม่

| field | value |
|---|---|
| url | https://app.clickup.com/t/86d43pbv6 |
| status | in progress · priority high · assignees — · due — |
| created / updated | 2026-08-17 / 2026-10-21 · creator Moss Pm · watchers 3 |

```markdown
## SC-AV-01-HP-03 · Upload Accessory ใหม่

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Admin กด "+ Upload Accessory ใหม่" ใน category ที่ต้องการ

* * *

## Scenario Steps
1. Admin เลือก tab Accessories → sub-tab ที่ต้องการ (เช่น Hat)
2. กด **"+ Upload Accessory ใหม่"**
3. Upload form เปิด พร้อม category pre-selected
4. Admin upload **Overlay PNG** ของ accessory
5. กรอก metadata: ชื่อ, category, status
6. ตั้งค่า **slot position**: offset x/y ต่อ direction (ปรับตำแหน่งบน avatar)
7. Preview: แสดง accessory overlay บน base character ทั้ง 4 ทิศ
8. กด "บันทึก"

* * *

## Acceptance Criteria
*   Category: dropdown Hat / Glasses / Outfit / Bag / Wings (required)
*   Upload PNG overlay: max 2MB, transparent background
*   Upload per direction (4 files) หรือ 1 spritesheet รวม 4 direction
*   Slot position editor: drag accessory บน avatar preview เพื่อตั้ง offset x/y
*   "Copy to all directions": copy offset ของ South ไป N/E/W เป็น baseline
*   Preview: แสดง accessory บน default skin ทั้ง 4 ทิศ
*   Thumbnail: auto-generate จาก South direction frame แรก
*   Status default: Hidden

* * *

## Error Codes

```css
400 INVALID_FILE_TYPE     — PNG เท่านั้น
400 FILE_TOO_LARGE        — เกิน 2MB
400 MISSING_DIRECTION     — ต้องมีครบ 4 direction
409 ACCESSORY_NAME_EXISTS — ชื่อซ้ำใน category เดียวกัน
```

## UX/UI

https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7122-77613&t=x3XAuSnXb5QzUGej-0
```

---

## 86d43pc0v · SC-AV-01-HP-04 · แก้ไข Metadata (ชื่อ, Category, Status)

| field | value |
|---|---|
| url | https://app.clickup.com/t/86d43pc0v |
| status | in progress · priority normal · assignees — · due — |
| created / updated | 2026-08-17 / 2026-10-21 · creator Moss Pm · watchers 3 |

```markdown
## SC-AV-01-HP-04 · แก้ไข Metadata (ชื่อ, Category, Status)

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Item มีอยู่แล้ว

* * *

## Scenario Steps

1. Admin คลิก item card → เปิด Edit page
2. แก้ไข fields ที่ต้องการ: ชื่อ, status
3. Accessory: แก้ไข offset position ต่อ direction ได้
4. Replace sprite: upload sprite ใหม่แทนของเดิม
5. กด "บันทึก"

* * *

## Acceptance Criteria
*   แก้ไขได้: ชื่อ, status
*   Replace sprite: upload PNG ใหม่แทนของเดิม → thumbnail regenerate
*   ชื่อซ้ำ: แจ้ง error ถ้าชื่อใหม่ซ้ำกับ item อื่น
*   Audit log: บันทึกทุกการแก้ไข
*   Default skin: เปลี่ยนชื่อได้ แต่เปลี่ยน status เป็น Hidden ไม่ได้

* * *

## UX/UI

https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7143-246946&t=x3XAuSnXb5QzUGej-0
```

---

## 86d43pc2z · SC-AV-01-HP-05 · Hide / Unhide Skin หรือ Accessory

| field | value |
|---|---|
| url | https://app.clickup.com/t/86d43pc2z |
| status | in progress · priority normal · assignees — · due — |
| created / updated | 2026-08-17 / 2026-10-21 · creator Moss Pm · watchers 3 |

```markdown
## SC-AV-01-HP-05 · Hide / Unhide Skin หรือ Accessory

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Item มีอยู่แล้ว

* * *

## Scenario Steps
### Hide
1. Admin กด "ซ่อน" บน item card หรือเปลี่ยน status เป็น Hidden ใน Edit page
2. Item หายออกจาก Avatar Customization ของ users ทันที
3. Users ที่ใช้ item นั้นอยู่: **ยังใช้ต่อได้** (avatar ไม่เปลี่ยน) แต่ไม่สามารถเลือกใหม่ได้
4. Admin เห็น item ยังอยู่ใน list พร้อม badge "🚫 Hidden"
### Unhide
1. Admin เปลี่ยน status กลับเป็น Active
2. Item ปรากฏใน Avatar Customization ของ users ทันที

* * *

## Acceptance Criteria
*   Hide ทันที: item หายจาก user picker ทันที (ไม่ต้อง reload)
*   User ที่ใช้อยู่: avatar ไม่เปลี่ยน — item ยังติดตัวจนกว่า user จะเปลี่ยนเอง
*   Hidden item: แสดงใน list ของ Admin พร้อม badge "Hidden"
*   Default skin: ซ่อนไม่ได้ถ้าเป็น skin เดียวที่ Active
*   Unhide: item กลับมาทันที ไม่ต้องรอ

## UX/UI

https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7419-288399&t=x3XAuSnXb5QzUGej-0
```

---

## 86d43pc3z · SC-AV-01-HP-06 · ลบ Skin หรือ Accessory

| field | value |
|---|---|
| url | https://app.clickup.com/t/86d43pc3z |
| status | in progress · priority normal · assignees — · due — |
| created / updated | 2026-08-17 / 2026-10-21 · creator Moss Pm · watchers 3 |

```markdown
## SC-AV-01-HP-06 · ลบ Skin หรือ Accessory

**Type:** Happy Path
**Persona:** System Admin
**Pre-condition:** Item มีอยู่ และไม่ใช่ Default skin

* * *

## Scenario Steps
1. Admin กด "ลบ" บน item
2. Confirmation dialog แสดง user count ที่ใช้ item นั้น
3. Admin กด Confirm → soft delete item
4. Users ที่ใช้ item นั้น: item ถูกลบออกจาก avatar → กลับ default skin / ไม่มี accessory ใน slot นั้น
5. Hard delete: storage assets ลบหลัง 30 วัน

* * *

## Acceptance Criteria
*   Confirmation: แสดง "Item นี้ถูกใช้โดย X users หากลบ avatars จะถูกรีเซ็ต item นี้"
*   Default skin: ลบไม่ได้ — ปุ่มลบ disabled + tooltip
*   Users ที่ใช้ item ที่ถูกลบ: slot นั้นถูก clear → default skin / ไม่มี accessory ใน slot
*   Soft delete: status = `deleted`, ซ่อนจาก Admin list (ดูผ่าน filter "Deleted" ได้)
*   Hard delete: cron job ลบ storage assets หลัง 30 วัน

* * *

## UX/UI

https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7419-321660&t=x3XAuSnXb5QzUGej-0
```

---

## 86d43pc80 · SC-AV-01-EP-01 · Upload Sprite ไม่ผ่าน Validation

| field | value |
|---|---|
| url | https://app.clickup.com/t/86d43pc80 |
| status | in progress · priority normal · assignees — · due — |
| created / updated | 2026-08-17 / 2026-10-21 · creator Moss Pm · watchers 3 |

```markdown
## SC-AV-01-EP-01 · Upload Sprite ไม่ผ่าน Validation

**Type:** Error Path
**Trigger:** Admin upload sprite ที่ไม่ถูกต้อง

* * *

## Error Cases

| Case | Message | Trigger |
| ---| ---| --- |
| ไม่ใช่ PNG | "รองรับเฉพาะ PNG" | file.type ≠ image/png |
| Skin เกิน 5MB | "ขนาดไฟล์เกิน 5 MB" | size > 5MB |
| Accessory เกิน 2MB | "ขนาดไฟล์เกิน 2 MB" | size > 2MB |
| Dimensions ไม่ลงตัว | "Width ต้องหารด้วย 64px ลงตัว (ของคุณ: {W}px)" | skin spritesheet |
| ไม่มี transparency | "แนะนำ PNG ที่มี transparent background" | warning เท่านั้น |
| ชื่อซ้ำ | "ชื่อนี้มีอยู่แล้ว" | duplicate name |

* * *

## Acceptance Criteria
*   Validate client-side ทันทีที่เลือกไฟล์
*   Error แสดง inline ใต้ upload area
*   Warning transparency: สีเหลือง ไม่บล็อก save
*   Server magic bytes validate: PNG signature 89 50 4E 47
*   Error หายเมื่อ user เลือกไฟล์ใหม่ที่ถูกต้อง

* * *

## API Error Codes

```plain
400 INVALID_FILE_TYPE
400 FILE_TOO_LARGE
400 INVALID_DIMENSIONS
409 NAME_EXISTS
```

## UX/UI

https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7420-408848&t=x3XAuSnXb5QzUGej-0
```

---

## 86d43pc8w · SC-AV-01-EC-02 · ลบ Item ที่มี User ใช้งานอยู่จำนวนมาก

| field | value |
|---|---|
| url | https://app.clickup.com/t/86d43pc8w |
| status | **Closed** (date_closed 1792470384560 → 2026-10-20) · priority normal · assignees — · due — |
| created / updated | 2026-08-17 / 2026-10-20 · creator Moss Pm · watchers 2 |

```markdown
## SC-AV-01-EC-02 · ลบ Item ที่มี User ใช้งานอยู่

**Type:** Edge Case
**Trigger:** Admin ลบ skin หรือ accessory ที่มี users ใช้งานอยู่จำนวนมาก (เช่น 1,000+ users)

* * *

## Scenario
1. Admin ลบ "Tan Skin" ที่มี 892 users ใช้งาน
2. ระบบต้อง reset skin ของ users เหล่านั้นทั้งหมด

* * *

## Acceptance Criteria
*   Confirmation dialog แสดง: "892 users จะถูกรีเซ็ตกลับ Default skin"
*   ถ้า user count > 100: ต้องพิมพ์ชื่อ item ยืนยันก่อน Confirm
*   Reset เป็น async job (ไม่บล็อก API response): อัปเดตทีละ batch 100 users
*   Admin เห็น progress: "กำลัง reset 892 users... (450/892)"
*   Users ที่กำลัง online และ avatar ถูก reset: เห็น avatar เปลี่ยนทันที (broadcast WebSocket)
*   Users offline: เห็น avatar เปลี่ยนเมื่อเข้า Virtual Office ครั้งต่อไป
*   Audit log: บันทึก admin\_id, item\_id, affected\_user\_count

* * *
```

(ไม่มี UX/UI link)
