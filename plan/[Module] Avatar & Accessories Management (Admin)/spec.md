# [Module] Avatar & Accessories Management (Admin) — Spec (ดึงจาก ClickUp)

> **สถานะ:** Planning — ดึงข้อมูลจาก ClickUp มาเก็บครบ 2026-10-21 + ยกตัวอย่าง flow upload จาก prototype Avatar Studio (§5) · ยังไม่ได้ review กับโค้ดจริง/Figma · **repo:** zyra-api, zyra-app (zyra-ws ถ้ามี broadcast ตาม EC-02)
> **ที่มา:** ClickUp task หลัก [[Module] · Avatar & Accessories Management (Admin)](https://app.clickup.com/t/86d43pbbj) (`86d43pbbj`) + subtask 8 ใบ
> **เอกสารคู่กัน:** [requirements.md](requirements.md) (แยกเป็น req ว่าต้องการอะไร + ของเดิมที่มีแล้ว + คำถามค้าง) · [clickup-raw.md](clickup-raw.md) (เนื้อหาดิบจาก ClickUp ทุกใบ ไม่ตัดต่อ) · [data/](data/) (data contract JSON + API ตัวอย่าง ส่งทีมหน้าบ้านทำ module ฝั่ง user)
> **เกี่ยวข้อง:** [AvatarCustomization/](../AvatarCustomization/) (แผน paper-doll ที่มีมติ "ไม่มีหน้า admin อัปโหลดรูป" — **ขัดกับโมดูลนี้** ดู requirements §6) · [AvatarManagement/SC-AV-01-user-count-fix.md](../AvatarManagement/SC-AV-01-user-count-fix.md)

---

## 1. ข้อมูล task หลัก (ClickUp)

| Field | ค่า |
|---|---|
| Task | [[Module] · Avatar & Accessories Management (Admin)](https://app.clickup.com/t/86d43pbbj) |
| ID | `86d43pbbj` |
| Status | **in progress** |
| Priority | High |
| Tags | `admin` |
| Custom field | Desktop = ✅ |
| Creator | Moss Pm |
| Assignees | P A (pai@hpktechnology.com), Ponlawat Lueakaew (ten_dev@hpktechnology.com) |
| Created | 2026-08-17 |
| Due date | 2026-10-08 (**เลยกำหนดแล้ว**) |
| Updated | 2026-10-21 |
| List / Folder | List `901614367195` / Zyra World (`90169187867`) |
| Comments / Attachments / Checklist / Dependencies | ไม่มีทั้งหมด (0) |
| Git links | ดึงไม่ได้ (ClickUp ตอบ Resource not found) |

**Module:** Admin — Project Zyra · **Persona:** System Admin · **Priority:** High

### Overview & Goal (ตาม ClickUp)

System Admin จัดการ Avatar Skin และ Accessories ทั้งหมดใน platform — upload sprites, จัดหมวดหมู่, เปิด/ซ่อน ให้ user เลือกใช้ได้ **ฟรีทั้งหมด**

**Avatar Model**
- Avatar = **1 base character ต่อ platform** (ทุกคนใช้ตัวเดียวกัน)
- Skin = Color/Style variant ของ character (เช่น สีผิว, สีผม, ชุด base)
- Accessories = ของตกแต่งแยก slot: **Hat, Glasses, Outfit, Bag, Wings/Cape**

**Scope Admin**
- จัดการ Skin library (upload, ตั้งชื่อ, เปิด/ซ่อน)
- จัดการ Accessories library แต่ละ category
- กำหนด preview และ metadata

### Avatar System Architecture (ตาม ClickUp)

```
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

---

## 2. Subtask ทั้งหมด (8 ใบ)

| # | Scenario | Type | ClickUp | Status | Priority | Figma |
|---|---|---|---|---|---|---|
| SC-AV-01-HP-01 | List Skin และ Accessories ทั้งหมด | Happy Path | [86d43pbfu](https://app.clickup.com/t/86d43pbfu) | in progress | High | [node 6942-489346](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=6942-489346) |
| SC-AV-01-HP-02 | Upload Skin ใหม่ | Happy Path | [86d43pbne](https://app.clickup.com/t/86d43pbne) | **Closed** (2026-10-15) | High | — |
| SC-AV-01-HP-03 | Upload Accessory ใหม่ | Happy Path | [86d43pbv6](https://app.clickup.com/t/86d43pbv6) | in progress | High | [node 7122-77613](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7122-77613) |
| SC-AV-01-HP-04 | แก้ไข Metadata (ชื่อ, Category, Status) | Happy Path | [86d43pc0v](https://app.clickup.com/t/86d43pc0v) | in progress | Normal | [node 7143-246946](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7143-246946) |
| SC-AV-01-HP-05 | Hide / Unhide Skin หรือ Accessory | Happy Path | [86d43pc2z](https://app.clickup.com/t/86d43pc2z) | in progress | Normal | [node 7419-288399](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7419-288399) |
| SC-AV-01-HP-06 | ลบ Skin หรือ Accessory | Happy Path | [86d43pc3z](https://app.clickup.com/t/86d43pc3z) | in progress | Normal | [node 7419-321660](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7419-321660) |
| SC-AV-01-EP-01 | Upload Sprite ไม่ผ่าน Validation | Error Path | [86d43pc80](https://app.clickup.com/t/86d43pc80) | in progress | Normal | [node 7420-408848](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=7420-408848) |
| SC-AV-01-EC-02 | ลบ Item ที่มี User ใช้งานอยู่จำนวนมาก | Edge Case | [86d43pc8w](https://app.clickup.com/t/86d43pc8w) | **Closed** (2026-10-20) | Normal | — |

หมายเหตุ
- ทุก subtask: ไม่มี assignee, ไม่มี due date, ไม่มี comment/attachment/checklist
- ตารางใน description ของ task หลักเขียนว่า `SC-AV-01-EC-01` แต่ subtask จริงชื่อ `SC-AV-01-EC-02` (เลขไม่ตรงกัน — ยึดชื่อ subtask)
- Figma ทุก node อยู่ไฟล์เดียวกัน `Map8gX0L2hk7HnkaFRfhtj` (Zyra design – More Organised ver.) — ยังไม่ได้ดึง spec จาก Figma MCP (ต้อง authorize ก่อน)

---

## 3. รายละเอียดแต่ละ Scenario

### SC-AV-01-HP-01 · List Skin และ Accessories ทั้งหมด

**Type:** Happy Path · **Persona:** System Admin · **Pre-condition:** Admin เข้าหน้า Avatar Management

**Scenario Steps**
1. Admin เข้า System Admin Dashboard → **Avatar Management**
2. หน้าแบ่ง 2 tabs: **Skins** และ **Accessories**
3. Tab Skins: แสดง skin ทั้งหมดเป็น grid พร้อม thumbnail
4. Tab Accessories: แบ่ง sub-tabs ตาม category (Hat, Glasses, Outfit, Bag, Wings)
5. แต่ละ item แสดง: thumbnail, ชื่อ, status badge, จำนวน users ที่ใช้, action buttons

**Acceptance Criteria**
- Tab Skins: แสดง skins ทั้งหมดเป็น grid, **pagination 20/หน้า**
- Tab Accessories: sub-tabs Hat / Glasses / Outfit / Bag / Wings
- แต่ละ item card: thumbnail, ชื่อ, status badge (✅ Active / 🚫 Hidden), user count
- Filter: All / Active / Hidden
- Search: ค้นหาชื่อ item
- Sort: ใหม่สุด / เก่าสุด / ชื่อ A-Z / ใช้มากสุด
- กด item card: เปิด detail/edit page

### SC-AV-01-HP-02 · Upload Skin ใหม่ (Closed)

**Type:** Happy Path · **Persona:** System Admin · **Pre-condition:** Admin กด "+ Upload Skin ใหม่"

**Scenario Steps**
1. Admin กด **"+ Upload Skin ใหม่"**
2. Upload form เปิด
3. Admin upload **Spritesheet PNG** ของ skin (4 directions: N/S/E/W + animations)
4. กรอก metadata: ชื่อ skin, sort order, status (Active/Hidden)
5. Preview: แสดง skin บน base character ทั้ง 4 ทิศ
6. กด "บันทึก" → skin พร้อมใช้งานใน Avatar Customization (ถ้า Active)

**Skin Spritesheet Spec**

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

**Acceptance Criteria**
- Upload PNG: **max 5MB**, transparent background, spritesheet format
- ชื่อ skin: required, **max 50 ตัวอักษร**, unique
- Status default: **Hidden** (ต้อง review ก่อน Active)
- Preview: แสดง `idle_s` animation บน base character หลัง upload
- Thumbnail: auto-generate จาก frame แรกของ `idle_s` (**400×400px**)
- Validate spritesheet dimensions: ต้องหารด้วย frame size (64px) ลงตัว
- "Default" skin: ลบ/ซ่อนไม่ได้ (ต้องมีอย่างน้อย 1 skin active เสมอ)

### SC-AV-01-HP-03 · Upload Accessory ใหม่

**Type:** Happy Path · **Persona:** System Admin · **Pre-condition:** Admin กด "+ Upload Accessory ใหม่" ใน category ที่ต้องการ

**Scenario Steps**
1. Admin เลือก tab Accessories → sub-tab ที่ต้องการ (เช่น Hat)
2. กด **"+ Upload Accessory ใหม่"**
3. Upload form เปิด พร้อม category pre-selected
4. Admin upload **Overlay PNG** ของ accessory
5. กรอก metadata: ชื่อ, category, status
6. ตั้งค่า **slot position**: offset x/y ต่อ direction (ปรับตำแหน่งบน avatar)
7. Preview: แสดง accessory overlay บน base character ทั้ง 4 ทิศ
8. กด "บันทึก"

**Acceptance Criteria**
- Category: dropdown Hat / Glasses / Outfit / Bag / Wings (required)
- Upload PNG overlay: **max 2MB**, transparent background
- Upload **per direction (4 files)** หรือ **1 spritesheet รวม 4 direction**
- Slot position editor: **drag** accessory บน avatar preview เพื่อตั้ง offset x/y
- "Copy to all directions": copy offset ของ South ไป N/E/W เป็น baseline
- Preview: แสดง accessory บน default skin ทั้ง 4 ทิศ
- Thumbnail: auto-generate จาก South direction frame แรก
- Status default: Hidden

**Error Codes**

```
400 INVALID_FILE_TYPE     — PNG เท่านั้น
400 FILE_TOO_LARGE        — เกิน 2MB
400 MISSING_DIRECTION     — ต้องมีครบ 4 direction
409 ACCESSORY_NAME_EXISTS — ชื่อซ้ำใน category เดียวกัน
```

### SC-AV-01-HP-04 · แก้ไข Metadata (ชื่อ, Category, Status)

**Type:** Happy Path · **Persona:** System Admin · **Pre-condition:** Item มีอยู่แล้ว

**Scenario Steps**
1. Admin คลิก item card → เปิด Edit page
2. แก้ไข fields ที่ต้องการ: ชื่อ, status
3. Accessory: แก้ไข offset position ต่อ direction ได้
4. Replace sprite: upload sprite ใหม่แทนของเดิม
5. กด "บันทึก"

**Acceptance Criteria**
- แก้ไขได้: ชื่อ, status (ชื่อ task บอก "Category" ด้วย แต่ใน AC ไม่มี category — ดู requirements §6)
- Replace sprite: upload PNG ใหม่แทนของเดิม → thumbnail regenerate
- ชื่อซ้ำ: แจ้ง error ถ้าชื่อใหม่ซ้ำกับ item อื่น
- **Audit log: บันทึกทุกการแก้ไข**
- Default skin: เปลี่ยนชื่อได้ แต่เปลี่ยน status เป็น Hidden ไม่ได้

### SC-AV-01-HP-05 · Hide / Unhide Skin หรือ Accessory

**Type:** Happy Path · **Persona:** System Admin · **Pre-condition:** Item มีอยู่แล้ว

**Scenario Steps — Hide**
1. Admin กด "ซ่อน" บน item card หรือเปลี่ยน status เป็น Hidden ใน Edit page
2. Item หายออกจาก Avatar Customization ของ users ทันที
3. Users ที่ใช้ item นั้นอยู่: **ยังใช้ต่อได้** (avatar ไม่เปลี่ยน) แต่ไม่สามารถเลือกใหม่ได้
4. Admin เห็น item ยังอยู่ใน list พร้อม badge "🚫 Hidden"

**Scenario Steps — Unhide**
1. Admin เปลี่ยน status กลับเป็น Active
2. Item ปรากฏใน Avatar Customization ของ users ทันที

**Acceptance Criteria**
- Hide ทันที: item หายจาก user picker ทันที (ไม่ต้อง reload)
- User ที่ใช้อยู่: avatar ไม่เปลี่ยน — item ยังติดตัวจนกว่า user จะเปลี่ยนเอง
- Hidden item: แสดงใน list ของ Admin พร้อม badge "Hidden"
- Default skin: ซ่อนไม่ได้ถ้าเป็น skin เดียวที่ Active
- Unhide: item กลับมาทันที ไม่ต้องรอ

### SC-AV-01-HP-06 · ลบ Skin หรือ Accessory

**Type:** Happy Path · **Persona:** System Admin · **Pre-condition:** Item มีอยู่ และไม่ใช่ Default skin

**Scenario Steps**
1. Admin กด "ลบ" บน item
2. Confirmation dialog แสดง user count ที่ใช้ item นั้น
3. Admin กด Confirm → **soft delete** item
4. Users ที่ใช้ item นั้น: item ถูกลบออกจาก avatar → กลับ default skin / ไม่มี accessory ใน slot นั้น
5. Hard delete: storage assets ลบหลัง **30 วัน**

**Acceptance Criteria**
- Confirmation: แสดง "Item นี้ถูกใช้โดย X users หากลบ avatars จะถูกรีเซ็ต item นี้"
- Default skin: ลบไม่ได้ — ปุ่มลบ disabled + tooltip
- Users ที่ใช้ item ที่ถูกลบ: slot นั้นถูก clear → default skin / ไม่มี accessory ใน slot
- Soft delete: status = `deleted`, ซ่อนจาก Admin list (ดูผ่าน filter "Deleted" ได้)
- Hard delete: cron job ลบ storage assets หลัง 30 วัน

### SC-AV-01-EP-01 · Upload Sprite ไม่ผ่าน Validation

**Type:** Error Path · **Trigger:** Admin upload sprite ที่ไม่ถูกต้อง

**Error Cases**

| Case | Message | Trigger |
|---|---|---|
| ไม่ใช่ PNG | "รองรับเฉพาะ PNG" | `file.type ≠ image/png` |
| Skin เกิน 5MB | "ขนาดไฟล์เกิน 5 MB" | size > 5MB |
| Accessory เกิน 2MB | "ขนาดไฟล์เกิน 2 MB" | size > 2MB |
| Dimensions ไม่ลงตัว | "Width ต้องหารด้วย 64px ลงตัว (ของคุณ: {W}px)" | skin spritesheet |
| ไม่มี transparency | "แนะนำ PNG ที่มี transparent background" | **warning เท่านั้น** |
| ชื่อซ้ำ | "ชื่อนี้มีอยู่แล้ว" | duplicate name |

**Acceptance Criteria**
- Validate client-side ทันทีที่เลือกไฟล์
- Error แสดง inline ใต้ upload area
- Warning transparency: สีเหลือง ไม่บล็อก save
- Server magic bytes validate: PNG signature `89 50 4E 47`
- Error หายเมื่อ user เลือกไฟล์ใหม่ที่ถูกต้อง

**API Error Codes**

```
400 INVALID_FILE_TYPE
400 FILE_TOO_LARGE
400 INVALID_DIMENSIONS
409 NAME_EXISTS
```

### SC-AV-01-EC-02 · ลบ Item ที่มี User ใช้งานอยู่จำนวนมาก (Closed)

**Type:** Edge Case · **Trigger:** Admin ลบ skin หรือ accessory ที่มี users ใช้งานอยู่จำนวนมาก (เช่น 1,000+ users)

**Scenario**
1. Admin ลบ "Tan Skin" ที่มี 892 users ใช้งาน
2. ระบบต้อง reset skin ของ users เหล่านั้นทั้งหมด

**Acceptance Criteria**
- Confirmation dialog แสดง: "892 users จะถูกรีเซ็ตกลับ Default skin"
- ถ้า user count **> 100**: ต้องพิมพ์ชื่อ item ยืนยันก่อน Confirm
- Reset เป็น **async job** (ไม่บล็อก API response): อัปเดตทีละ **batch 100 users**
- Admin เห็น progress: "กำลัง reset 892 users... (450/892)"
- Users ที่กำลัง online และ avatar ถูก reset: เห็น avatar เปลี่ยนทันที (**broadcast WebSocket**)
- Users offline: เห็น avatar เปลี่ยนเมื่อเข้า Virtual Office ครั้งต่อไป
- Audit log: บันทึก `admin_id`, `item_id`, `affected_user_count`

---

## 4. สรุปกฎธุรกิจที่กระจายอยู่หลายใบ (รวมไว้ที่เดียว)

| กฎ | มาจาก |
|---|---|
| Status ใหม่ default = **Hidden** เสมอ (ทั้ง skin และ accessory) | HP-02, HP-03 |
| Default skin: **ลบไม่ได้**, **ซ่อนไม่ได้** (ถ้าเป็น skin เดียวที่ Active), เปลี่ยนชื่อได้ | HP-02, HP-04, HP-05, HP-06 |
| ต้องมี skin Active อย่างน้อย 1 ตัวเสมอ | HP-02 |
| Skin: PNG ≤ 5MB · Accessory: PNG ≤ 2MB · ตรวจ magic bytes ฝั่ง server | HP-02, HP-03, EP-01 |
| ชื่อ skin unique ทั้ง platform · ชื่อ accessory unique **ภายใน category** | HP-02, HP-03 |
| Hide = user เดิมใช้ต่อได้ แต่เลือกใหม่ไม่ได้ · Delete = user เดิมถูก reset | HP-05, HP-06 |
| Delete = soft delete → hard delete storage หลัง 30 วัน (cron) | HP-06 |
| Delete item ที่มี user > 100 → พิมพ์ชื่อยืนยัน · reset เป็น async batch 100 + progress + WS broadcast | EC-02 |
| ทุกการแก้ไข/ลบ ต้องลง audit log | HP-04, EC-02 |

---

## 5. ตัวอย่าง flow upload จาก prototype "Zyra Avatar Studio" (ใช้เป็นแบบ)

> ที่มา: [claude.ai artifact 5CWTCN9yMtbQ4czt29FVty](https://claude.ai/artifact/5CWTCN9yMtbQ4czt29FVty) (prototype ที่ [AvatarCustomization/spec.md](../AvatarCustomization/spec.md) อ้างถึง) · ดึงเนื้อหา 2026-10-21 · prototype นี้ทำไว้ฝั่ง **member แต่งตัว** + ส่วน "ทดสอบชิ้นที่วาดเอง (สำหรับ designer)" — ส่วนหลังคือ flow upload ที่ให้เอามาเป็นแบบให้หน้า admin
> หมายเหตุ: prototype เขียนไว้เองว่า "ชิ้นส่วนกับชุดสีมาจากไฟล์ใน repo ไม่มีหน้าให้ admin อัปโหลด" และ "ปุ่มบันทึกไม่ได้ส่งข้อมูลไปไหน" — สิ่งที่ยกมาคือ **กลไก upload/validate/preview** ไม่ใช่มติเรื่องใครเป็นคน upload (ดู requirements §6 Q1)

### 5.1 ไฟล์ที่ต้อง upload ต่อ 1 ชิ้น

| ไฟล์ | บังคับ? | ขนาด | เนื้อหา |
|---|---|---|---|
| ชีทเดิน (`walk`) | **บังคับ** | **192×192** หรือ **240×192** (ถ้ามีคอลัมน์หลับตา) | 4 แถว × 4 คอลัมน์ (หรือ 5) เฟรม 48×48 |
| ชีทนั่ง (`sit`) | ไม่บังคับ | 192×192 | ถ้าไม่ใส่ ระบบใช้เฟรมจากชีทเดินแทนชั่วคราว (ขึ้น warning) |

รูปแบบ: PNG พื้นโปร่ง · `accept="image/png"` · คลิกหรือลากไฟล์มาวาง (drop zone 2 ช่อง) · เลือกได้ทีละไฟล์

### 5.2 Layout ของชีท (เฟรม 48×48, 1 px = 1 px)

```
                 col 0     col 1      col 2     col 3     col 4 (optional)
walk  แถว 0 ลง   เดิน      ยืน (idle) เดิน      เดิน      หลับตา
      แถว 1 ซ้าย  ...
      แถว 2 ขวา   ...
      แถว 3 ขึ้น  ...

sit   แถว 0 ลง   -         -          นั่ง       ลุก       หลับตา
      แถว 1..3   (ซ้าย / ขวา / ขึ้น เหมือนกัน)
```

- ลำดับทิศ **ตายตัว**: ลง → ซ้าย → ขวา → ขึ้น (row 0–3)
- คอลัมน์ 1 ของ walk = เฟรมยืน · คอลัมน์ 2 ของ sit = นั่ง · คอลัมน์ 3 ของ sit = ลุก
- คอลัมน์ 4 (หลับตา) มีเฉพาะชิ้น "ตา" · ชิ้นอื่นใช้ 4 คอลัมน์ · ถ้าชิ้นไม่มีคอลัมน์ 4 ระบบ fallback ไปใช้คอลัมน์ยืน/นั่งแทน
- ผลลัพธ์ที่ server ประกอบให้ (bake) ต่อ user: `outfits/<hash>/walk.png` + `sit.png` (**240×192** ทั้งคู่ server เติมคอลัมน์หลับตาเอง) + `thumb.png`

### 5.3 ฟอร์ม upload (field ที่มี)

| Field | ค่า |
|---|---|
| "ชิ้นนี้คือ" (slot) | dropdown: เสื้อ / กางเกง / รองเท้า / ผม / ตา / หนวด / หมวก / แว่น / เครื่องประดับ / ชุด special (ทับเสื้อ+กางเกง · ใช้สีตามไฟล์ ไม่แปลงสี) |
| "ชื่อชิ้น" | text, placeholder "เช่น เสื้อเชิ้ตลายสก็อต" · ว่างได้ → ตั้งชื่ออัตโนมัติ "ชิ้นที่วาด N" |
| ชีทเดิน / ชีทนั่ง | drop zone แสดงชื่อไฟล์ + ขนาด + จำนวน pixel ทึบ หลังอ่านสำเร็จ |
| ปุ่ม "ใส่ให้ตัวละคร" | apply ชิ้นลง preview ทันที (ไม่ต้องกด save) · ถ้าไม่มีชีทเดิน → toast "ต้องมีชีทเดินก่อน" |
| toggle "ไฮไลต์จุดที่ควรแก้บนตัวละครด้านบน" | เปิด diagnostic overlay บน preview (ดู 5.5) |

### 5.4 Validation ตอนอ่านไฟล์ (client-side ทันทีที่เลือกไฟล์)

| ลำดับ | ตรวจอะไร | ผล | ข้อความ (ตาม prototype) |
|---|---|---|---|
| 1 | ขนาด: rows = 4, cols = 4 หรือ 5, w/h หาร 48 ลงตัว | **block** (bad) | "ขนาดต้องเป็น 192×192 หรือ 240×192 แต่ไฟล์นี้ {W}×{H}" |
| 2 | อ่านได้ → นับ pixel ทึบ + channel สี key ที่พบ | ok | "อ่านชีทเดินได้ · pixel ทึบ N · channel ที่พบ: ผิว, สีหลัก" หรือ "ไม่มี (สีตายตัวทั้งชิ้น)" |
| 3 | pixel โปร่งแสงครึ่ง ๆ (0 < alpha < 255) | warn | "มี pixel โปร่งแสงครึ่ง ๆ N จุด — ระบบจริงจะ reject ให้ใช้ alpha 0 หรือ 255 เท่านั้น" |
| 4 | สีใกล้ key แต่ไม่ตรง (hue ห่าง ≤ 14° แต่ไม่ pure) → น่าจะ anti-alias | warn | "สีใกล้ key แต่ไม่ตรง (น่าจะ anti-alias) เช่น (x,y) #hex→channel · …" (โชว์ 4 จุดแรก) |
| 5 | channel ที่ slot นี้ไม่ควรใช้ (เช่น ผม ใช้ได้แค่ `hair`) | warn | "ชิ้นประเภท {slot} ไม่ควรใช้ channel: …" |
| 6 | ผ่านทุกข้อ | ok | "ผ่านกฎทุกข้อ" |
| 7 | กด apply โดยไม่มีชีทนั่ง | warn | "ยังไม่มีชีทนั่ง — ท่านั่งใช้เฟรมจากชีทเดินไปก่อน" |

- รายงานแสดงเป็นกล่อง inline ใต้ drop zone สี ok=เขียว / warn=เหลือง / bad=แดง (ตรงกับ EP-01 ที่ต้องการ inline + warning สีเหลืองไม่บล็อก)
- เปลี่ยน slot หลังเลือกไฟล์แล้ว → parse ใหม่ทันที (เพราะกฎ channel ต่าง)

### 5.5 Preview + diagnostic หลัง apply

- ชิ้นขึ้นบน preview ตัวละครทันที: เลือกท่า ยืน / เดิน / นั่ง · เลือกทิศ 4 ทิศ · toggle "หมุนดูรอบตัวอัตโนมัติ"
- เปิดไฮไลต์: **ชมพู** = ผิวยังโผล่ในส่วนที่ชิ้นนี้ควรคลุม · **ฟ้า** = วาดเกินตัว base · แสดงตัวเลข "เฟรมนี้: ผิวโผล่ N px · เกินตัว M px"
- ส่วน "ไฟล์ที่ server ประกอบให้ตอนกดบันทึก": โชว์ walk.png / sit.png ที่ bake แล้ว + ชีทของชิ้นที่เลือก (สลับดู "สีจริง" / "สี key") กรอบเขียว = เฟรมที่กำลังแสดงอยู่

### 5.6 ระบบสี key (palette swap) — ส่วนที่ผู้ใช้เปลี่ยนสีได้

| channel | 1 highlight | 2 base | 3 shadow | 4 deep | ใช้กับ slot |
|---|---|---|---|---|---|
| skin (ผิว) | `#FFA0FF` | `#FF00FF` | `#A000A0` | `#500050` | ตา, เสื้อ (แขนโผล่) |
| hair (ผม) | `#A0FFFF` | `#00FFFF` | `#00A0A0` | `#005050` | ผม, หนวด, ตา |
| eye (ตา) | `#FFFFA0` | `#FFFF00` | `#A0A000` | `#505000` | ตา |
| primary (สีหลักของชิ้น) | `#FFA0A0` | `#FF0000` | `#A00000` | `#500000` | เสื้อ, กางเกง, รองเท้า, หมวก, แว่น, เครื่องประดับ |
| secondary (สีรองของชิ้น) | `#A0FFA0` | `#00FF00` | `#00A000` | `#005000` | เสื้อ, กางเกง, รองเท้า, หมวก, เครื่องประดับ |

- 4 สีคือเฉดหลัก แต่ใช้เฉดระหว่างกลางในโทนเดียวกันได้ไม่จำกัด ระบบไล่สีตามความสว่าง
- สีนอกโทนเหล่านี้ = สีตายตัว (ศิลปินวาดสีจริงมา เปลี่ยนไม่ได้)
- **ชุด special (`costume`) ไม่ใช้สี key เลย** เก็บตามไฟล์ทั้งชิ้น
- ห้ามโปร่งครึ่ง ๆ (alpha ต้องเป็น 0 หรือ 255)
- มีปุ่ม "คัดลอก palette .gpl (Aseprite / GIMP)" ให้ศิลปินโหลด palette ไปวาด

### 5.7 เครื่องมือช่วยศิลปิน (ควรมีในหน้า admin ด้วย)

- **Template สำหรับวาดชิ้นใหม่**: เลือกชีท (เดิน/นั่ง) · คอลัมน์ (4 ชิ้นทั่วไป 192×192 / 5 ตา 240×192) · ขนาด (1× ใช้วาด / 4× ไว้ดู) · toggle "ใส่ชุดที่ตัวละครใส่อยู่ลงไปจาง ๆ ด้วย" (เช่น วาดหมวกให้พอดีทรงผม) → ปุ่ม "ส่งออก PNG" / "คัดลอกรูป แล้วไปวางใน Aseprite"
- Template = base จาง 30% + เส้นแบ่งเฟรม 48 px สีฟ้า · ชื่อไฟล์ `template_<sheet>_<W>x192[_outfit][_x4].png`
- ไฟล์สำเร็จรูปที่แจกได้: `template_walk_192.png`, `template_sit_192.png`, `guide_walk_768.png`, `guide_sit_768.png`, `zyra-avatar-keys.gpl` (อยู่ใน `demo file/avatar/template/`)

### 5.8 เทียบ spec ClickUp กับ prototype (ต้องเลือกทางเดียว)

| เรื่อง | ClickUp (HP-02 / HP-03) | Prototype |
|---|---|---|
| ขนาดเฟรม | 64×64 (หรือ 32×32) | **48×48** |
| Layout | horizontal strip ต่อ state, แถวละ state (walk_s/n/e/w ×4, idle_s ×2, sit ×2) | grid 4 แถว (ลง/ซ้าย/ขวา/ขึ้น) × 4–5 คอลัมน์ แยก 2 ไฟล์ walk + sit |
| ไฟล์ต่อชิ้น | skin: 1 sheet · accessory: 4 ไฟล์ต่อทิศ หรือ 1 sheet | ทุกชิ้น: walk sheet (บังคับ) + sit sheet (optional) |
| ตำแหน่ง accessory | offset x/y ต่อทิศ ปรับด้วย drag | **ไม่มี offset** — วาดลงตำแหน่งจริงบน template เลย |
| สี | ไม่พูดถึง | palette swap 5 channel (skin/hair/eye/primary/secondary) |
| Validation | PNG, size ≤ 5MB/2MB, width หาร 64 ลงตัว, transparency warning | ขนาดตายตัว 192/240×192, alpha ครึ่ง warn, anti-alias warn, channel ผิด slot warn |
| Preview | idle_s animation 4 ทิศ | ยืน/เดิน/นั่ง 4 ทิศ + หมุนอัตโนมัติ + diagnostic overlay |
| Slot | Hat / Glasses / Outfit / Bag / Wings | เสื้อ / กางเกง / รองเท้า / ผม / ตา / หนวด / หมวก / แว่น / เครื่องประดับ / ชุด special |
| Thumbnail | auto จาก idle_s frame แรก 400×400 | server bake `thumb.png` (ขนาดไม่ระบุใน prototype) |
