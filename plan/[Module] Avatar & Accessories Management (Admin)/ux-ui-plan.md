# Accessory Management (Admin) — UX/UI Plan (Pixel-Perfect)

> **สถานะ:** Draft v1.0 · 2026-10-21 · ค่าทั้งหมดดึงจาก Figma MCP (`get_design_context`) ไม่ได้เดา · ยังไม่ implement · **repo:** zyra-app
> **Source:** Figma `Map8gX0L2hk7HnkaFRfhtj` (Zyra design — More Organised ver.) · canvas 1440 × 1024
> **POC ที่ตกลงแล้ว:** [poc/accessory-admin-poc.html](poc/accessory-admin-poc.html) · live: https://claude.ai/artifact/EHWxezQ31xnvz5vWBCeUNv (version 10) — ส่วนที่ POC ต่างจาก Figma อยู่ใน §11
> **เอกสารคู่กัน:** [spec.md](spec.md) · [requirements.md](requirements.md) · [progress.md](progress.md)

---

## 0. Scenario → Figma node

| Scenario | หน้าจอหลัก (master) | node ของ state ที่ต้องดู |
|---|---|---|
| HP-01 List | `7000:442197` Empty · `7000:443507` Accessory list | category panel `7508:36620` · empty list `7122:84110` · filter submenu `7000:443557` |
| HP-03 Add | `7031:170181` Special costume – Add · `7031:171040` Other categories – Add | Set expiration `7124:105726` · กรอกครบ `7124:106094` · Top 2 ชีท `7143:111586` · upload แล้ว `7490:34297` · colour picker `7488:28727` |
| HP-04 Edit | `7024:48803` Special costume – Edit | view `7143:253878` · edit mode `7143:254249` · toast `7143:113033` |
| HP-05 Hide | `7024:48803` | toggle Hidden `7419:295869` |
| HP-06 Delete | `7024:48803` + General modal | modal ลบ `7419:357581` · มีผู้ใช้ `7419:406890` · พิมพ์ชื่อยืนยัน `7419:357967` |
| EP-01 Upload error | `7031:170181` | ชื่อซ้ำ `7428:416286` · toast `7428:416201` / `7428:416215` / `7428:416229` |

Sticky note ในไฟล์ Figma (กฎ business ที่อยู่ในดีไซน์):

| Sticky | ข้อความ (สรุป) |
|---|---|
| `7031:171024`, `7434:416846` | Top, Outer, Dress, Bottoms, Special Costume อัปโหลด 2 ชีท (Walking + Sitting) · Special Costume อัปโหลดทุกสี |
| `7434:416851` | หมวดที่เหลืออัปโหลดแค่ Walking |
| `7031:171029` | Special Costume มีแบบกำหนดเวลาและไม่กำหนดเวลา · สีเป็น custom colour (กำหนดเอง) · หมวดอื่นสีเป็น auto-generate |
| `7488:32649` | เลือกสี → พิมพ์ชื่อสี หรือ generate ชื่อตามสี |

---

## 1. Layout ระดับหน้า

| ส่วน | ค่า |
|---|---|
| Canvas | 1440 × 1024 · bg `#2B3540` |
| Sidebar | ใช้ `AdminSidebar` เดิม (275 px) — เพิ่มเมนู **Accessory management** (จัดการเครื่องประดับ) icon `wand-sparkles` ระหว่าง Pet management กับ Map management |
| Headbar | ใช้ `AppNavbar` เดิม (72 px) |
| Panel ซ้าย (category) | left 288 · top 88 · 368 × 920 |
| Panel ขวา (list / empty) | left 672 · top 88 · 752 × 920 |
| Panel form (add / edit) | left 288 · top 88 · **1136** × 920 (กว้างเต็ม แทน 2 panel) |
| ทุก panel | bg `#242B32` · radius 16 · padding 16 |
| ระยะระหว่าง panel | 16 |

---

## 2. Design tokens (จาก Figma variables)

| Token | ค่า | ใช้ที่ |
|---|---|---|
| Background/Primary | `#242B32` | panel, input |
| Background/Secondary | `#2B3540` | page bg, card, preview box, upload block |
| Shade Black/500 | `#1A1B1E` | toast, colour picker, count badge, ตัวหนังสือปุ่มขาว |
| Primary/500 | `#58D68D` | ปุ่มหลัก, active, Active status |
| Primary/10% | `rgba(88,214,141,.1)` | แถวที่เลือก, tag Active |
| Primary/20% | `rgba(88,214,141,.2)` | tab ที่เลือก, icon box toast สำเร็จ |
| Red/500 | `#F03A3A` | Delete, error |
| Red/5% · Red/20% | `rgba(240,58,58,.05)` · `rgba(240,58,58,.2)` | ปุ่ม Delete (outline) |
| Blue/500 · 10% · 20% | `#2DB6FF` · `rgba(45,182,255,.1)` · `.2` | alert banner |
| Grey/100 · 300 · 400 | `#DBDFE3` · `#B2BBC3` · `#A3ADB8` | ปุ่ม disabled |
| Grey/500 | `#8C99A6` | ข้อความรอง, หัวกลุ่ม |
| Grey/600 | `#7F8B97` | ค่าใน input read-only |
| Grey/700 | `#636D76` | placeholder, icon ค้นหา |
| Grey/900 | `#3B4046` | เส้นใต้แถวตาราง |
| White 5% · 10% · 20% | `rgba(255,255,255,.05/.1/.2)` | ghost bg / hover / border |

Typography (Inter):

| Style | size / line-height / weight |
|---|---|
| H/Bold | 20 / normal / 700 |
| Sub/Medium · Sub/Regular | 16 / 22 / 500 · 400 |
| Body/Bold · Medium · Regular | 14 / 18 / 700 · 500 · 400 |
| Caption 1/Regular | 12 / 15 / 400 · letter-spacing −0.43 |
| Caption 2/Medium | 10 / 14 / 500 |

---

## 3. Category panel (`7508:36620`)

| ส่วน | ค่า |
|---|---|
| Container | flex-col · gap 16 |
| Title | "Accessory category" (หมวดหมู่เครื่องประดับ) H/Bold white · gap 8 · "18 Category" (18 หมวดหมู่) Body/Regular `#8C99A6` |
| Search | input h 42 · px 12 · radius 8 · border white 20% · icon search 16 `#636D76` · placeholder "Search for category" (ค้นหาหมวดหมู่) |
| กลุ่ม | gap 24 ระหว่างกลุ่ม · gap 8 ภายในกลุ่ม |
| หัวกลุ่ม | Body/Regular `#8C99A6` + chevron-up 14 · กดพับ/กางได้ |
| แถว | min-h 42 · padding 12 · radius 8 · gap 8 · icon 16 · ชื่อ Body/Regular white (ellipsis) · จำนวน `#8C99A6` · chevron-right 16 |
| แถวที่เลือก | bg Primary/10% · ตัวหนังสือ + icon `#58D68D` |
| list เกินความสูง | เนื้อหาสูง 1002 > 920 → เลื่อนในกล่อง (Figma ตัดที่ Mask) |

18 หมวด และ icon (SVG จาก Figma ชื่อ layer ตามนี้ ใช้ไฟล์ตรง ๆ):

| กลุ่ม | หมวด → layer icon |
|---|---|
| Head (ศีรษะ) | Hair → `hair 1` · Eyes → `eye 1` · Face → `face 1` · Facial Hair → `moustache 1` |
| Body (ร่างกาย) | Top → `top 1` · Outer → `jecket 1` · Dress → `dress 1` · Bottoms → `bottom 1` · Shoes → `shoes 1` · Special Costume → `santa 1` |
| Accessory (เครื่องประดับ) | Hat → `hat 1` · Glasses → `glasses 1` · Mask → `mask 1` · Neck → `necklace 1` · Belt → `belt 1` · Bag → `bag 1` · Back → `wings 1` · Companion → `paw 1` |

icon พวกนี้เป็น custom SVG (fill ขาว) ไม่ใช่ lucide → เก็บใน `components/ui/icon.tsx` ตาม [12-icons.md](../../../.claude/rules/12-icons.md) (ข้อยกเว้น custom asset) และให้สีตาม `currentColor` เพื่อเปลี่ยนเป็นเขียวตอน active

---

## 4. Panel ขวา — empty / list

### 4.1 Empty states

| state | node | รูป | Title (Sub/Bold 16/22) | ข้อความ (Body/Regular `#8C99A6`) | ปุ่ม |
|---|---|---|---|---|---|
| ยังไม่เลือกหมวด | `7000:442197` | 100 × 100 | "No category selected" (ยังไม่ได้เลือกหมวดหมู่) | "Select a category and accessory will appear here." (เลือกหมวดหมู่แล้วเครื่องประดับจะแสดงที่นี่) | — |
| หมวดยังไม่มีของ | `7122:84110` | 100 × 100 | "No accessory added" (ยังไม่มีเครื่องประดับ) | "Create accessory for your workspace to make them available for users." (สร้างเครื่องประดับเพื่อให้ผู้ใช้เลือกใช้ได้) | Add accessory |

รูปกล่อง = `NoObjectsIcon` ที่มีอยู่แล้วใน `components/ui/icon.tsx`

### 4.2 Header ของ list (`7000:443507`)

| ส่วน | ค่า |
|---|---|
| Header | flex-col gap 16 |
| แถว title | ชื่อหมวด H/Bold · ปุ่ม "Add accessory" (เพิ่มเครื่องประดับ) h 42 · px 16 · radius 8 · bg `#58D68D` · Sub/Regular white · icon plus 16 |
| แถวค้นหา | input "Search" (ค้นหา) h 42 flex-1 · ปุ่ม filter 42 × 42 bg white 5% border white 20% radius 8 icon `list-filter` 16 · gap 8 |
| แถว meta | "{n} Item" Body/Regular white · "Latest" + chevron-down (เรียงล่าสุด) |

### 4.3 Accessory card

| ส่วน | ค่า |
|---|---|
| Card | w 168 · bg `#2B3540` · radius 8 · padding 8 · gap 16 · overflow hidden · grid wrap gap 16 (4 คอลัมน์) |
| แถวบน | tag สถานะ ซ้าย + count badge ขวา (width 152) |
| Tag Active | bg Primary/10% · border Primary/10% · radius 4 · px 4 py 2 · gap 4 · icon eye 14 · Caption 1 `#58D68D` "Active" (ใช้งาน) |
| Tag Hidden | icon eye-off 14 · "Hidden" (ซ่อน) สีเทา — **ค่า bg/border ยังไม่ได้ดึงจาก node** (ดูจาก screenshot `7419:317378`) |
| Count badge | bg `#1A1B1E` · radius 90 · padding 1 · Caption 2/Medium white · กว้าง 16 · ความหมาย = จำนวนผู้ใช้ที่ใส่ชิ้นนี้ (SC HP-01 "user count") |
| รูป | h 80 · padding 8 · radius 8 · รูปกลาง |
| จุดสี | absolute กลาง · bottom 61 · จุด 10 × 10 gap 4 · แสดง 3 สีแรก + "+N" (10/13 white) — เฉพาะของที่มีหลาย variant |
| ชื่อ | Body/Medium white · ellipsis 1 บรรทัด |
| วันที่ | icon calendar 14 + Caption 1 `#8C99A6` รูปแบบ "Sep 18, 2025 (10:00)" · gap 4 |

### 4.4 Pagination

ปุ่ม 32 × 32 radius 6 bg white 5% border white 20% · หน้าปัจจุบัน bg `#58D68D` · ตัวเลือก "20 / page" + chevron-down · ชิดขวา gap 8 · 20 รายการต่อหน้า (ตรง SC HP-01)

### 4.5 Filter submenu (`7000:443557`)

w 200 · bg `#242B32` · radius 16 · padding 8 · shadow `0 4 16 rgba(255,255,255,.08)` · หัว "Status" (สถานะ) Caption 1 `#8C99A6` padding 8 · ตัวเลือก All / Active / Hidden (ทั้งหมด / ใช้งาน / ซ่อน) แถว min-h 42 padding 12 checkbox 16 เขียว · วางใต้ปุ่ม filter

---

## 5. Form — Add / Edit (`7031:170181`, `7031:171040`, `7024:48803`)

### 5.1 Header

| ส่วน | ค่า |
|---|---|
| ซ้าย | chevron-left 16 + "Add accessory" (เพิ่มเครื่องประดับ) H/Bold · gap 8 |
| ปุ่มขวา gap 8 · h 40 · px 16 · radius 8 · Sub/Regular · icon 16 | |
| Add | **Cancel** (ยกเลิก) bg white text `#1A1B1E` icon x · **Save** (บันทึก) disabled = bg `#DBDFE3` border `#B2BBC3` text `#A3ADB8` icon check · พร้อม = bg `#58D68D` text white |
| Edit — ดู | **Delete** (ลบ) bg Red/5% border Red/20% text `#F03A3A` icon trash · **Edit** (แก้ไข) bg `#58D68D` icon pencil |
| Edit — แก้ | Delete · Cancel · Save |

> Figma ใช้หัว "Add accessory" ในหน้า Edit ด้วย — POC เปลี่ยนเป็น "Edit accessory" ในโหมดดู/แก้ (ดู §11)

### 5.2 Layout

แถวเนื้อหา gap 40 · คอลัมน์ซ้าย w 640 gap 24 (เลื่อนได้) · คอลัมน์ขวา flex-1 gap 24 กึ่งกลาง

### 5.3 Property setting (คอลัมน์ซ้ายส่วนบน)

| ส่วน | ค่า |
|---|---|
| หัว section | "Property setting" (ตั้งค่าคุณสมบัติ) Sub/Medium · "Configure accessory properties." (กำหนดคุณสมบัติของเครื่องประดับ) Body/Regular `#8C99A6` · gap 8 · h 48 |
| field gap | 16 |
| Accessory name | label Body/Regular white · input h 42 · placeholder "Please input accessory name" (กรอกชื่อเครื่องประดับ) · counter ใต้ input ชิดขวา Caption 1 "**{n}**/50" (ตัวเลขปัจจุบัน semibold white) |
| Category | select แสดงหมวดที่เลือกมาจาก list (read-only: bg white 5% บน `#242B32` text `#7F8B97`) + chevron-down 16 |
| (Special Costume เท่านั้น) | radio "No determine" (ไม่กำหนดเวลา) / "Set expiration" (กำหนดวันหมดอายุ) · gap 16 · ปุ่ม radio 16 |
| (เมื่อ Set expiration) | Start date / End date (วันเริ่ม / วันสิ้นสุด) 2 ช่อง gap 16 · placeholder "DD/MM/YYYY" · icon calendar 16 |
| Status | label "Status" (สถานะ) · switch 48 × 24 + "Active" `#58D68D` / "Hidden" `#8C99A6` · แถวสูง 42 · gap 8 |
| โหมดดู (Edit view) | ทุก input เป็น read-only สี `#7F8B97` · radio ตัวที่ไม่ได้เลือกเป็นสีเทาทึบ |
| Divider | 1 px white 20% |

### 5.4 Upload accessory (คอลัมน์ซ้ายส่วนล่าง)

| ส่วน | ค่า |
|---|---|
| หัว | "Upload accessory" (อัปโหลดเครื่องประดับ) Sub/Medium + icon info 16 · "Add custom accessories for users to personalize their avatars." (เพิ่มเครื่องประดับให้ผู้ใช้แต่งตัวละคร) |
| Alert | bg Blue/10% · border Blue/20% · radius 8 · padding 8 · icon info 16 · Body/Regular `#2DB6FF` "Upload a PNG image with only transparent background (max 2 MB)." (อัปโหลด PNG พื้นโปร่งใสเท่านั้น ไม่เกิน 2 MB) |

**แบบ A — Special Costume (ตารางสี)**

| ส่วน | ค่า |
|---|---|
| หัวตาราง | h 56 · padding 12 · border-bottom white 20% · Body/Regular `#8C99A6` · คอลัมน์ "Colour" (สี, flex-1) · "Walking spritesheet" (ชีทเดิน, w 200) · "Sitting spritesheet" (ชีทนั่ง, w 200) |
| แถว | h 56 · border-bottom `#3B4046` · วงสี 16 (กดเปิด colour picker) · ชื่อสี Body/Regular (ว่าง = placeholder "Input colour name" `#8C99A6`) |
| ยังไม่มีไฟล์ | ปุ่ม "Choose file" (เลือกไฟล์) h 32 · px 16 · radius 6 · bg white 5% · border white 20% · icon plus |
| มีไฟล์แล้ว | chip bg white 5% · radius 8 · padding 8 · ชื่อไฟล์ ellipsis + icon x 16 (โหมดดูไม่มี x) |
| ปุ่มเพิ่มแถว | "Add colour varient" (เพิ่มสี) h 32 · radius 6 · bg `#58D68D` · icon plus · ชิดขวา — **Figma สะกด "varient"** ให้ใช้ "variant" ในแอป |

**แบบ B — หมวดอื่น (auto-generate สี)**

| ส่วน | ค่า |
|---|---|
| block | bg `#2B3540` · radius 8 · padding 8 · gap 16 · label Body/Medium "Walking spritesheet" (+ block ที่ 2 "Sitting spritesheet" สำหรับ Top/Outer/Dress/Bottoms) |
| dropzone | bg white 5% · border **dashed** white 20% · radius 8 · py 24 px 8 · gap 8 · ปุ่ม upload 32 · "Drag and drop file here or **choose file**" (ลากไฟล์มาวาง หรือเลือกไฟล์) — "choose file" ขีดเส้นใต้ white |
| มีไฟล์แล้ว | แถว bg white 5% radius 8 padding 8 gap 16 · กล่อง icon image 40 · ชื่อไฟล์ + Caption "Size: {x} • **Completed**" (ขนาด • อัปโหลดเสร็จ, คำว่า Completed สีเขียว) · icon trash แดง |

### 5.5 Preview (คอลัมน์ขวา)

| ส่วน | ค่า |
|---|---|
| หัว | "Preview" (ตัวอย่าง) Sub/Medium · "Review your accessory before adding it to the collection." (ตรวจดูก่อนเพิ่มเข้าคอลเลกชัน) |
| Tab | border white 20% · radius 8 · padding 4 · 3 ช่องเท่ากัน h 32 radius 8 · Idle / Walking / Sitting (ยืน / เดิน / นั่ง) · ที่เลือก bg Primary/20% |
| กล่อง | h 300 · bg `#2B3540` · radius 16 · ตัวละคร 160 × 160 กลาง (sprite 48 px ขยาย ×3 แบบ pixelated) |
| ปุ่มหมุน | 2 ปุ่ม 32 × 32 radius 6 bg white 5% border white 20% · icon rotate-cw / rotate-ccw 16 · มุมขวาล่าง inset 8 · gap 8 |
| แถวสี | 376 × 24 · 12 จุด 24 px gap 8 — ดู §11 เรื่องแถบ Shade |

### 5.6 Colour picker (`7488:28727`)

280 × 488 · bg `#1A1B1E` · border white 20% · radius 8 · padding 16 · gap 16 · drop-shadow `0 12 8 rgba(5,32,81,.09)`, `0 4 3 rgba(5,32,81,.04)`
- กล่องสี 248 สูง radius 8 · handle วงกลม
- icon pipette 24 + แถบ hue และ saturation สูง 12 radius 100
- dropdown "HSL" กว้าง 72 (bg `#232427` border `#B1B6BF` radius 8) + ช่องค่า 4 ช่อง (Caption Medium 12/18)
- "Saved Colors" (สีที่บันทึกไว้) Body semibold 14/20 `#8C99A6` · จุด 24 gap 8 wrap
- วางที่ x 356 y 497 ของ frame (ใต้วงสีในตาราง)

---

## 6. Modal ลบ (`7419:357581`, `7419:406890`, `7419:357967`)

| ส่วน | ค่า |
|---|---|
| Overlay | เต็มจอ (Figma layer "Overlay" ไม่มีค่าสี — POC ใช้ดำ 50%) |
| Modal | w 458 · bg `#242B32` · radius 16 · padding 16 · gap 24 · backdrop-blur 4 |
| หัว | "Delete accessory?" (ลบเครื่องประดับ?) Sub/Medium + ปุ่ม x 24 · divider white 20% · gap 16 |
| Footer | ชิดขวา gap 8 · Cancel (ยกเลิก) bg white text `#1A1B1E` h 32 radius 6 · Delete (ลบ) bg `#F03A3A` text white h 32 radius 6 |

| แบบ | เมื่อไหร่ | ข้อความ |
|---|---|---|
| 1 | ไม่มีผู้ใช้ | "This accessory will be permanently removed from the system. This action cannot be undone." (เครื่องประดับนี้จะถูกลบถาวรและย้อนกลับไม่ได้) |
| 2 | มีผู้ใช้ | "This accessory is currently used by {n} users. Deleting it may affect their avatars and remove the accessory from their appearance." (มีผู้ใช้ {n} คนใช้อยู่ การลบจะถอดชิ้นนี้ออกจากตัวละครของเขา) |
| 3 | ผู้ใช้ > 100 (SC EC-02) | label "Confirm delete “{name}”" (ยืนยันการลบ “{name}”) + input placeholder "Enter “{name}” to delete this accessory" (พิมพ์ “{name}” เพื่อลบ) · ปุ่ม Delete disabled (สี disabled แบบ §5.1) จนพิมพ์ตรง |

---

## 7. Toast (`7143:113033`, `7428:416201`, `7428:416215`, `7428:416229`)

w 336 · มุมขวาบน inset 16 · bg `#1A1B1E` · radius 16 · padding 16 · gap 16 · shadow `0 4 8 rgba(255,255,255,.08)` · กล่อง icon 40 radius 8 padding 8 (icon 24) · ข้อความ Body · ปุ่ม x 16

| แบบ | กล่อง icon | Title (Body/Bold) | ข้อความ |
|---|---|---|---|
| สำเร็จ | Primary/20% + check | — | "Accessory saved successfully." (บันทึกเครื่องประดับแล้ว) |
| ไม่ใช่ PNG | Red/20% + x | "Upload failed" (อัปโหลดไม่สำเร็จ) | "Only PNG files are supported." (รองรับเฉพาะไฟล์ PNG) |
| เกินขนาด | Red/20% + x | "Upload failed" | "The file must be 2 MB or smaller." (ไฟล์ต้องไม่เกิน 2 MB) |
| ไม่โปร่งใส | Red/20% + x | "Invalid PNG image" (ไฟล์ PNG ไม่ถูกต้อง) | "The uploaded PNG must include a transparent background." (PNG ต้องมีพื้นโปร่งใส) |

ใช้ `zyraToast` ใน `lib/toast.tsx` (tokens ตรงกันอยู่แล้ว) — ไม่ต้องสร้าง toast ใหม่

> Figma ใช้ **toast** สำหรับ "ไม่โปร่งใส" แต่ SC EP-01 บอกว่าเป็นแค่ **warning สีเหลืองไม่บล็อก** → ต้องถาม PM (§12)

## 8. Inline error ชื่อซ้ำ (`7428:416286`)

input border `#F03A3A` · ข้อความ Caption 1 `#F03A3A` ชิดซ้ายใต้ input แถวเดียวกับ counter: "This accessory name already exists. Please use a different name." (ชื่อนี้มีอยู่แล้ว กรุณาใช้ชื่ออื่น)

---

## 9. Interaction & state

| การกระทำ | ผล |
|---|---|
| กดหมวดในแถบซ้าย | แถวเป็น active · panel ขวาเปลี่ยนเป็น list ของหมวดนั้น (หรือ empty §4.1) |
| พิมพ์ในช่องค้นหาหมวด | กรองชื่อหมวดทันที · กลุ่มที่ไม่เหลือหมวดถูกซ่อน |
| Add accessory | เปิด form กว้าง 1136 · category = หมวดที่เลือกอยู่ · แบบ A ถ้าเป็น Special Costume ไม่งั้นแบบ B |
| Save | disabled จนกว่าจะมีชื่อ + ไฟล์ครบตามกฎ sticky (Walking ทุกหมวด · Sitting เฉพาะ Top/Outer/Dress/Bottoms/Special) |
| Save สำเร็จ | กลับหน้า list + toast สำเร็จ |
| กด card | เปิดโหมดดู (Delete + Edit) |
| Edit → Cancel | กลับโหมดดู ไม่บันทึก |
| toggle Status | Active ↔ Hidden · หน้า list แสดง tag Hidden (SC HP-05) |
| Delete | เปิด modal แบบ 1/2/3 ตามจำนวนผู้ใช้ · ลบสำเร็จ → list + toast |
| Tab Idle/Walking/Sitting | Idle = walk col 1 · Walking = วน col 0–3 ทุก 125 ms · Sitting = sit col 2 + เก้าอี้ (§11) |
| ปุ่มหมุน | เปลี่ยนทิศ ลง → ขวา → ขึ้น → ซ้าย (หมุนกลับได้) |

---

## 10. Component reuse (ตาม [09-component-reuse.md](../../../.claude/rules/09-component-reuse.md))

| ใช้ของเดิม | ที่ |
|---|---|
| `AdminSidebar` | `components/admin/admin-sidebar.tsx` (+ เมนูใหม่) |
| `AppNavbar` | `components/app-navbar` |
| `NoObjectsIcon` | `components/ui/icon.tsx` |
| `zyraToast` | `lib/toast.tsx` |
| pagination / filter / sort / delete dialog | ดูของ `views/admin/avatar-management/components/` ก่อน — extract ขึ้น `components/admin/` ถ้าใช้ซ้ำ ไม่ copy |

สร้างใหม่: `views/admin/accessory-management/` (hero + category panel + list + card + form + preview) · route `app/admin/accessory-management/page.tsx` · namespace i18n `AdminAccessoryManagement` (en/th) + ลงทะเบียนใน `i18n/messages-scope.ts`

---

## 11. สิ่งที่ POC ตกลงต่างจาก Figma (Ten รีวิวแล้ว 2026-10-21)

| เรื่อง | Figma | POC (ใช้ตามนี้) |
|---|---|---|
| รูปใน card list | รูปชิ้นอย่างเดียว | **ตัวละคร base ใส่ชิ้นนั้น** + ตา default (Eye 1) |
| tab Sitting | ตัวละครลอย | **มีเก้าอี้** = object จริง "Office Chair" (Blue) วางตามสูตร VO engine: piece กลางที่ `(x−176, y−176)` · เท้าตัวละครที่ sit point + `SIT_HIP_TO_FOOT_OFFSET_Y` (5) · piece `above_character` วาดทับ |
| เลือกสี (auto-generate) | 12 จุด | **12 จุดสีหลัก + แถบ "Shade"** (ความเข้ม) — ซ้ายจางถึงพาสเทล (ผสมขาว 85%) · กลาง = สีหลัก · ขวาเข้มถึงเกือบดำ (ผสมดำ 75%) · แสดงจุดสี + hex ด้านขวาของคำว่า Shade · เปลี่ยนสีหลักแล้วคงระดับความเข้มเดิม |
| สีลงตรงไหน | ไม่ระบุ | เสื้อผ้า/เครื่องประดับ → primary/secondary · Eyes → สีตา · Hair/Facial Hair → สีผม · Face (บลัชออน) สีตายตัว |
| หัวหน้า Edit | "Add accessory" | "Edit accessory" (แก้ไขเครื่องประดับ) |
| icon sidebar | custom | lucide ที่ path ตรงกัน: Avatar `person-standing` · Object `armchair` · Pet `paw-print` · Accessory `wand-sparkles` · Workspace `pencil-ruler` · Customer `user-round` · Admin `user-round-cog` · Map ใช้ `files` (ยังไม่เจอตัวตรง) — **แต่ในแอปจริงคง icon ของ `AdminSidebar` เดิม** เปลี่ยนเฉพาะเมื่อ design สั่ง |

---

## 12. คำถามค้างก่อน implement

| # | เรื่อง | รอใคร |
|---|---|---|
| U1 | แถบ Shade ไม่มีใน Figma — design ต้องวาดเพิ่มหรือใช้ตาม POC | Designer |
| U2 | Tag Hidden ใน card — ต้องการ node / ค่าสีจริง | Designer |
| U3 | ไม่โปร่งใส = toast error (Figma) หรือ warning เหลืองไม่บล็อก (SC EP-01) | PM |
| U4 | หมวดในดีไซน์มี 18 ตัว แต่ data contract ฝั่ง user ([data/avatar-outfit-data.json](data/avatar-outfit-data.json)) มี 11 slot ตาม prototype — ต้อง map ให้ตรงกัน (เช่น Outer, Dress, Mask, Belt, Bag, Back, Companion ยังไม่มี slot) | PM + Ten |
| ~~U5~~ ✅ | ~~Hair / Eyes / หมวดอื่นอัปโหลด Walking อย่างเดียว — เพิ่มช่อง Sitting ไหม~~ → ฟอร์มขึ้นช่อง Sitting (บังคับ) ให้ Hair, Facial Hair, Shoes ด้วย · Eyes / Face / Hat / Glasses คง Walking อย่างเดียว (Ten 2026-10-22) | Ten |
| U6 | ตัวเลือก sort มีแค่ "Latest" ใน Figma · SC HP-01 ต้องการ ใหม่สุด / เก่าสุด / ชื่อ A-Z / ใช้มากสุด | Designer |
| U7 | Overlay หลัง modal ไม่มีค่าสีใน Figma | Designer |
| U8 | icon Map management ใน Figma ไม่ตรง lucide ตัวไหน | Designer |
