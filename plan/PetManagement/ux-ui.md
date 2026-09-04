# Pet Management — UX/UI Spec (from Figma)

> ดึงจาก Figma MCP (`get_design_context` / `get_screenshot`) — ไฟล์: [Zyra design — More Organised ver.](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-)
> อัปเดตทีละ Scenario ตามที่ผู้ใช้ทยอยส่ง node — เริ่มจาก **SC-PM-01**

---

## Shared Design Tokens (ใช้ร่วมกันทุกหน้า Pet Management)

### Colors

| Token | Hex / Value | ใช้กับ |
|---|---|---|
| Background/Secondary | `#2B3540` | Page background |
| Background/Primary | `#242B32` | Panel/card/sidebar background, input background |
| Primary/500 | `#58D68D` | Primary button, active tab underline, active status text, sidebar active bg (`rgba(88,214,141,0.2)`) |
| Grey/700 | `#636D76` | Placeholder text |
| Grey/500 | `#8C99A6` | Secondary/description text |
| Grey/400 | `#A3ADB8` | Disabled button text |
| Grey/300 | `#B2BBC3` | Disabled button border |
| Grey/100 | `#DBDFE3` | Disabled button background |
| Shade Black/500 | `#1A1B1E` | Cancel button text (บน bg ขาว) |
| Solid White 5% / 10% / 20% | `rgba(255,255,255,0.05\|0.1\|0.2)` | Ghost button bg, borders, dividers |
| Danger | `#F03A3A` (bg `rgba(240,58,58,0.05)`, border `rgba(240,58,58,0.2)`) | Delete button |
| Category tag (purple) | text `#996ADF`, bg `rgba(153,106,223,0.1)` | Category badge บน pet card (เช่น "Cat") |
| Active tag (green) | text `#58D68D`, bg `rgba(88,214,141,0.1)`, border `rgba(88,214,141,0.1)` | Active/Hidden badge บน pet card |
| White shadow | `drop-shadow(0px 4px 16px rgba(255,255,255,0.08))` | Dropdown/submenu popover shadow |

### Typography (Inter)

| Style | Size / Weight / Line-height |
|---|---|
| H/Bold | 20px / 700 / normal |
| Sub/Bold | 16px / 700 / 22px |
| Sub/Medium | 16px / 500 / 22px |
| Sub/Regular | 16px / 400 / 22px |
| Body/Bold | 14px / 700 / 18px |
| Body/Regular | 14px / 400 / 18px |
| Caption 1/Regular | 12px / 400 / 15px, letter-spacing -0.43 |

### Layout constants

- Sidebar width: `275px` (fixed, full height) — **มีอยู่แล้วใน `zyra-app/components/admin/admin-sidebar.tsx` ตาม [[component-reuse]] rule ต้อง reuse ไม่สร้างใหม่**
- Headbar height: `72px`
- Content area padding: `16px`, gap ระหว่าง section หลัก `24px`
- Card/panel radius: `16px` (panel ใหญ่), `8px` (input/button/pet card), `6px` (small icon button)
- Input height: `42px`, padding `12px 8px`, border `1px solid rgba(255,255,255,0.2)`, radius `8px`
- Primary button height: `42px` (large) / `40px` (dialog header) / `32px` (footer nav)

### Icon mapping (ต้องแปลงเป็น lucide-react ตาม [[icons-policy]])

Figma ส่ง icon มาเป็น custom SVG asset — ตาม `.claude/rules/12-icons.md` ต้อง map ไปใช้ `lucide-react` แทนการ export asset ตรงๆ:

| Figma icon name | lucide-react equivalent |
|---|---|
| Plus | `Plus` |
| Search | `Search` |
| filter | `SlidersHorizontal` หรือ `Filter` |
| Cheron-Down / Cheron-Up | `ChevronDown` / `ChevronUp` |
| Cheron-left / Cheron-Right | `ChevronLeft` / `ChevronRight` |
| Info | `Info` |
| Upload | `Upload` |
| Check | `Check` |
| Cancel | `X` |
| Trash | `Trash2` |
| Edit | `Pencil` / `Edit` |
| Calendar | `Calendar` |
| Tag / pet | `Tag` (category) / custom pet icon (ดู `components/ui/icon.tsx` ถ้ามี asset เฉพาะ) |
| eye-on / eye-off | `Eye` / `EyeOff` |
| panel-left-close | `PanelLeftClose` |
| Characters, Objects, Template, Mapmaker, User, user-cog, setting | ตาม sidebar menu icons ที่มีอยู่แล้วใน `admin-sidebar.tsx` |

### Component reuse notes

- **Sidebar** (`Sidebar_backoffice` ทุก node) → reuse `AdminSidebar` ที่มีอยู่แล้ว ไม่สร้างใหม่ ([[component-reuse]])
- **Switch/Toggle** (Status Active/Hidden) → ต้องสร้างเป็น custom Tailwind toggle ตาม `.claude/rules/08-shadcn-ui.md` (ห้ามใช้ `@/components/ui/switch` จาก shadcn) — pattern: `<button>` + conditional `bg-[#58d68d]` / `bg-[rgba(255,255,255,0.2)]`
- **ทุก dropdown/filter panel** (submenu ที่ลอยขึ้นมา) → ต้อง implement เอง (useState + useRef + click-outside) ตาม Tailwind-only policy ห้ามใช้ shadcn Dropdown/Select

---

## SC-PM-01 · List Pet Types ทั้งหมด

5 Figma frames ที่ดึงมา ครอบคลุมทุก state ของหน้า Pet Library (list) + Add/Edit pet (general info step):

| # | Node ID | ชื่อ Frame ใน Figma | State ที่แสดง |
|---|---|---|---|
| 1 | [3997:197037](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3997-197037) | Map template | Empty list + "Add a new pet" panel เปิดอยู่ + **Sort submenu** (Name / Created at / Used count) เปิดอยู่ |
| 2 | [3997:197040](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3997-197040) | Map template | เหมือน #1 แต่เปิด **Filter submenu** แทน (Category checkboxes + Status checkboxes) |
| 3 | [4017:9895](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4017-9895) | Pet management - empty | List ว่าง + Detail panel ว่าง ("No pet selected") — **ยังไม่กด Add** |
| 4 | [4017:7415](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4017-7415) | Pet management - creating | List ว่าง + panel ขวาเป็นฟอร์ม **"Add a new pet" — Step 1: General information** |
| 5 | [4017:33276](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4017-33276) | Pet management - select | List **มี pet cards แล้ว** + panel ขวาแสดง **detail ของ pet ที่เลือก** (read-only style + ปุ่ม Delete/Edit) |

### Page structure (ทุก node ร่วมกัน)

```
┌─────────────┬──────────────────────────────────────────────┐
│             │  Headbar (72px): [Language EN] [Avatar+Name]  │
│  Sidebar    ├──────────────────────────────────────────────┤
│  (275px)    │  Tabs: [Pet Library] [XP Configuration]       │
│             ├───────────────┬──────────────────────────────┤
│             │  Pet Library  │   Detail / Add-pet panel      │
│             │  panel(368px) │   panel (752px)               │
│             │               │                                │
└─────────────┴───────────────┴──────────────────────────────┘
```

- Tabs "Pet Library" / "XP Configuration" — underline indicator สีเขียว `#58D68D` ที่ tab active (SC-PM-04 ใช้ tab "XP Configuration" ต่อไป)
- Two-panel layout ค้างที่ 178px จาก top, สูง 830px, gap ระหว่าง panel คือช่องว่างของ layout (ไม่ใช่ gap เดียวกับภายใน panel)

### 1) Pet Library panel (ซ้าย, 368px)

**Header**
- Title `Pet Library` (H/Bold 20px) + ปุ่ม `+` วงกลม-square สีเขียว (`#58D68D`, 42×42px, radius 8px) — เปิดฟอร์ม Add pet

**Search + Filter row**
- Search input (flex-1, 42px) — placeholder `Search for pet`, icon `Search` ซ้ายใน input
- Filter icon button (42×42px, ghost style `rgba(255,255,255,0.05)` + border `rgba(255,255,255,0.2)`) — เปิด **Filter submenu** (ดูด้านล่าง)

**Count + Sort row**
- ซ้าย: `{n} pet` (Body/Regular, สีขาว)
- ขวา: Sort trigger `Name ⌄` — เปิด **Sort submenu**

**Sort submenu** (node #1 — ลอยที่ตำแหน่ง approx `top:338px`, `width:200px`, bg `#242B32`, radius 16px, shadow white 8%)
- รายการ: `Name`, `Created at`, `Used count` — แต่ละอันเป็น menu item padding 12px, radius 8px, hover state

**Filter submenu** (node #2 — `top:307px`, `width:224px`)
- Section "Filter" (Caption 1, สีเทา `#8C99A6`) + checkbox list: `Bird, Cat, Dog, Elephant, Exotic Pets, Fish & Aquatic, Reptile, Small Pets`
- Divider (`h-0` + border line)
- Section "Status" + checkbox list: `Active, Hidden`
- Checkbox: 16×16px, border `#D1D1D6`, radius 4px (unchecked state)

**Empty state** (node #3, #4 — ยังไม่มี pet เลย)
- ภาพ illustration (กล่องเปิด) 100×100px
- Title `No pet added` (Sub/Bold 16px)
- Description `Add a pet to create an amazing creature for team collaboration.` (Body/Regular, สีเทา, center)
- ปุ่ม `+ Add pet` (primary, 42px height)

**Populated state — Pet card** (node #5, เมื่อมี pet แล้ว)
แต่ละ card: bg `#2B3540`, padding 8px, radius 8px, gap 8px, width 336px
- Thumbnail image 80×80px, radius 8px, border `rgba(255,255,255,0.2)`, overlay `rgba(0,0,0,0.2)`
- Content (flex-1):
  - แถวชื่อ: ชื่อ pet (Body/Medium 14px) + count badge วงกลมดำ (`#1A1B1E`, ตัวเลขสีขาว 10px)
  - แถว "pet" icon + `Stage : {n} stages` (Caption 1, สีเทา)
  - แถว Calendar icon + `Created date : {date} ({time})` (Caption 1, สีเทา)
  - แถว tags: Category tag (bg purple 10%, text `#996ADF`) + Active/Hidden tag (bg เขียว 10%, มี eye-on/eye-off icon, text `#58D68D` เมื่อ Active)
- **Selected card**: border `1px solid #58D68D` (ต่างจาก card ปกติที่ไม่มี border)

**Pagination** (footer ของ panel)
- ปุ่ม Chevron-left (ghost, 8px padding) → `[1]` (active page, bg เขียว, 32×32px) → `10 / page ⌄` dropdown → Chevron-Right

### 2) Detail / Add-pet panel (ขวา, 752px)

**Empty state** (node #3 — ยังไม่เลือก/ไม่ได้ add)
- Illustration 100×100px + Title `No pet selected` (Sub/Bold) + description `Select a pet from the library on the left to view details, or create a new pet type.` (center, สีเทา)

**Add-pet form — Step 1: General information** (node #4)

Header:
- Title `Add a new pet` (H/Bold 20px) + Button group ขวาบน: `✕ Cancel` (bg ขาว, text ดำ) + `✓ Save` (disabled style: bg `#DBDFE3`, border `#B2BBC3`, text `#A3ADB8` — enabled หลังกรอกครบ)

Step indicator (`CreatNewPetStep` component, reusable ทั้ง 3 steps):
- 3 steps เรียง horizontal เท่ากัน (`flex-1`), แต่ละ step = icon button (32px, radius 6px, bg `rgba(255,255,255,0.05)`, border `rgba(255,255,255,0.2)`) + label ด้านล่าง (Body/Regular 14px)
  1. `Info` icon → "General information" (step ปัจจุบัน)
  2. `Upload` icon → "Upload stage & animation"
  3. `Check` icon → "Complete"
- Progress bar เชื่อมระหว่าง step (bg `rgba(255,255,255,0.2)`, fill gradient `#58D68D → #8FE4B3` เมื่อ step ผ่านแล้ว — ปัจจุบัน opacity 0 คือยังไม่ผ่าน)

Form fields ("General information"):
- Section header: `General information` (Sub/Medium) + `Enter the basic pet information.` (Body/Regular, เทา)
- Row 1 (2 คอลัมน์ gap 16px):
  - **Pet name**: text input, placeholder `Please input pet name`, character counter `0/100` ขวาล่าง (ตัวเลขปัจจุบันสีขาว bold, `/100` สีเทา)
  - **Category**: select dropdown, placeholder `Please select category`, chevron-down icon
- **Status**: label + Toggle switch (default **ON/Active**, เขียว) + label `Active` (สีเขียวเมื่อ active)
- **Description** (Optional): textarea สูง 160px, placeholder `Add some detail about this pet`

Footer (sticky, drop-shadow บนขึ้น `0 4px 8px rgba(255,255,255,0.08)`):
- ซ้าย: `‹ Back` (ghost, disabled — เป็น step แรก)
- ขวา: `Next ›` (disabled style จนกรอกฟอร์มครบ)

**Detail view — pet ที่เลือกแล้ว** (node #5)
โครงเดียวกับ Add-pet form General information แต่:
- Header button group เปลี่ยนเป็น `🗑 Delete` (สีแดง, bg `rgba(240,58,58,0.05)`, border `rgba(240,58,58,0.2)`, text `#F03A3A`) + `✎ Edit` (primary เขียว)
- ฟิลด์แสดงค่าจริงแบบ read-only-ish (เช่น Pet name = "Golden dog", Category = "Dog") พร้อม input background เป็น gradient overlay (`rgba(255,255,255,0.05)` ทับบน `#242B32`) บ่งบอกว่าเป็นโหมดดู ไม่ใช่โหมดพิมพ์
- Step indicator ยังแสดงอยู่ (แต่บริบทนี้คือดูข้อมูลที่บันทึกแล้ว ไม่ใช่ wizard progress)

---

## Implementation notes สำหรับ dev

1. **Empty vs populated vs creating vs viewing เป็น 4 state ของหน้าเดียวกัน** — ควร implement เป็น component เดียว (`hero-pet-management.tsx` หรือใกล้เคียง) ที่ switch state ตาม: `pets.length === 0` / `selectedPetId` / `isCreating`
2. **Sort/Filter submenu** ทั้งสองใช้ pattern เดียวกัน (popover + checkbox list) — พิจารณาสร้าง shared component ใน `views/pet-management/components/` แล้ว reuse
3. Pet card "count badge" (เลขวงกลมดำมุมชื่อ) = ✅ `workspace_usage_count` (ปิดแล้ว ข้อ 9) — จำนวน room ที่ pet type นี้ถูกวาง ไม่ใช่ field ใหม่
4. ตาม `spec.md` SC-PM-01 ต้องมี pagination 20/หน้า แต่ Figma แสดง `10 / page` เป็น default ใน dropdown — ใช้ตาม spec.md (20/หน้า) เป็นค่า default จริง ส่วน dropdown ให้ผู้ใช้เลือกได้

---

## SC-PM-02 · สร้าง Pet Type ใหม่

4 Figma nodes ที่ดึงมา — 2 อันซ้ำกับ state ที่มีอยู่แล้วใน SC-PM-01 (ไม่มีข้อมูลใหม่), อีก 2 อันให้รายละเอียดเพิ่มของ wizard ("Add a new pet"):

| # | Node ID | ชื่อ Frame | สถานะ |
|---|---|---|---|
| 1 | [4017:33283](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4017-33283) | Pet management - empty | **ซ้ำกับ node 4017:9895 ใน SC-PM-01** ทุกประการ (empty list + empty detail) — ไม่มี field ใหม่ |
| 2 | [4017:33282](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4017-33282) | Pet management - creating | **ซ้ำกับ node 4017:7415 ใน SC-PM-01** ทุกประการ (Step 1: General information, ฟอร์มเปล่า) — ไม่มี field ใหม่ |
| 3 | [4017:96991](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4017-96991) | Pet management - creating | Step 1: General information **พร้อม Category dropdown เปิดอยู่** — เห็นรายการตัวเลือกครบ |
| 4 | [4032:163076](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4032-163076) | Pet management - upload image | Step 2: **Upload stage & animation** — หน้าถัดไปหลังกด Next จาก General information |

### Step 1 — General information: Category dropdown (node #3)

เมื่อกด Category input จะเปิด dropdown popover (ตำแหน่งลอย, `width:352px`, bg `#242B32`, radius 16px, shadow white 8%) แสดงรายการ:

```
Buffalo (highlighted/hover — bg rgba(255,255,255,0.1))
Bird
Cat
Dog
Elephant
Exotic Pets
Fish & Aquatic
Reptile
Small Pets
```

- รายการตรงกับ Category filter list ใน SC-PM-01 (Pet Library filter submenu) — ใช้ source เดียวกัน
- "Buffalo" อยู่บนสุดและมี hover state highlight (`rgba(255,255,255,0.1)`) — อาจเป็นแค่ state ตัวอย่างใน Figma ไม่จำเป็นต้องตรึงเป็นค่า default

### Step 2 — Upload stage & animation (node #4)

หลังกรอก General information ครบแล้วกด Next จะเข้าสู่ step 2 ของ wizard เดียวกัน (ยังอยู่ panel ขวา 752px, header "Add a new pet" เดิม):

**Step indicator**: step 1 (`Info`) เสร็จแล้ว (ไอคอนเขียว `#58D68D`, progress bar bg-white เต็มเส้น) → step 2 (`Upload`) active (ไอคอนเขียว) → step 3 (`Check`) ยังไม่ถึง (เทา)

**Section header**
- Title `Upload stage & animation` (Sub/Medium 16px) + info icon (tooltip) ข้างๆ
- Description: `Upload the pet's stage images and animation assets.`
- ปุ่ม `Preview` มุมขวาบน (ghost, disabled/opacity 50% จนกว่าจะมี asset ให้ preview)

**Frame settings row** (2 คอลัมน์ gap 16px)
- **Frame count**: input style เดียวกับ select (border, chevron-down icon), ค่าตัวอย่าง `50`
- **Frame rate (fps)**: input style เดียวกัน, ค่าตัวอย่าง `24`
- ⚠️ Field ทั้งสองมี chevron-down icon แบบเดียวกับ dropdown — เจตนาจริงอาจเป็น text/number input ที่ใช้ style เดียวกับ select เฉยๆ (ไม่ใช่ dropdown list) ต้อง confirm กับ design ก่อน implement

Divider line คั่นระหว่าง frame settings กับส่วน stage/upload ด้านล่าง

**Two-column layout**

Left — **Pet stages** sidebar (การ์ด bordered, width 257px):
- Header "Pet stages"
- รายการ stage menu items พร้อม required-count tag (แดง `rgba(240,58,58,0.1)` bg, text `#F03A3A`) + chevron-right:
  - `Egg` — **active/selected** (bg เขียว `rgba(88,214,141,0.1)`, text เขียว) — tag `0/1`
  - `Baby` — tag `0/4`
  - `Adult` — tag `0/4`
  - `Evolved` — tag `0/4`

> ✅ **ปิดแล้ว — ใช้ 4 stage ตาม Figma**: `Egg / Baby / Adult / Evolved` (ข้อ 1) โมเดล 6-stage เดิมใน spec.md (Egg/Hatch/Grow/Evolve/Lonely/Happy) ตกไป — `Lonely`/`Happy` กลายเป็น mood ที่ derive จาก `last_activity_at` ไม่ใช่ stage
>
> Required animation count: Egg = 2, Baby/Adult/Evolved = 5 (ดูตารางเต็มใน SC-PM-03 ด้านล่าง)

Right — Upload area:
- Alert banner (info, ฟ้า `bg rgba(45,182,255,0.1)`, border `rgba(45,182,255,0.2)`, text `#2DB6FF`): `Upload a PNG image only (max 1 MB, up to 1,000 × 1,000 px).`
  - ⚠️ ระบุ max dimension **1,000 × 1,000 px** ชัดเจน — spec.md (SC-PM-07) ไม่ได้ระบุ max dimension ไว้ ต้องเพิ่ม validation rule นี้
- Upload card (bg `#2B3540`, radius 8px): Title = ชื่อ animation slot ปัจจุบัน เช่น `Wobbling spritesheet` (สำหรับ Egg stage's "wobble" animation) + dropzone (`Files` component: dashed border `rgba(255,255,255,0.2)`, upload icon button, ข้อความ `Drag and drop file here or choose file` — "choose file" underline เป็น link)

**Footer**: `‹ Back` (ghost, enabled) / `Next ›` (disabled style จนครบ required)

### Design tokens เพิ่มเติมที่พบใน SC-PM-02

| Token | Hex | ใช้กับ |
|---|---|---|
| Grey/600 | `#7F8B97` | ข้อความ readonly-ish ใน view mode input |
| Red/500 | `#F03A3A` (bg 10%: `rgba(240,58,58,0.1)`) | Required-count tag ที่ยังไม่ครบ (`0/N`) |
| Blue/500 | `#2DB6FF` (bg 10%: `rgba(45,182,255,0.1)`, border 20%) | Info alert banner |
| Body/Medium | Inter 14px / 500 / 18px | Upload card title |

### Implementation notes เพิ่มเติม

1. Node #1 และ #2 ไม่มีข้อมูลใหม่ — ข้ามได้ ใช้ spec จาก SC-PM-01 แทน
2. Category dropdown list ควรดึงจาก source เดียวกับ Filter submenu ใน Pet Library (SC-PM-01) — อย่า duplicate hardcode
3. **ต้องยืนยัน stage names/count กับ PM ก่อน** เพราะ Figma (Egg/Baby/Adult/Evolved) ขัดกับ spec.md (Egg/Hatch/Grow/Evolve/Lonely/Happy) — รอ SC-PM-03 node เพิ่มเติมเพื่อ cross-check อีกครั้ง
4. เพิ่ม validation rule "max 1,000 × 1,000 px" เข้าไปใน SC-PM-07 (Sprite Upload Validation) ด้วย เนื่องจากไม่มีใน spec.md เดิม

---

## SC-PM-03 · Upload Sprite ต่อ Stage และ Animation

> ✅ **เคาะแล้ว 2026-08-17 — ยึด Figma** โมเดลใน Figma (1 slot = 1 ไฟล์รวมทุก direction) เป็นของจริง ส่วนตาราง per-direction ใน spec.md เดิม/ClickUp card ตกไป ดูสรุปที่ [spec.md](spec.md#animation-slots-ต่อ-stage--ปิดแล้ว-ข้อ-2-ยึด-figma) และ schema ที่ [db-schema-api-contract.md](db-schema-api-contract.md)
>
> การเปรียบเทียบข้างล่างเก็บไว้เป็นบันทึกว่าทำไมถึงเลือกทางนี้

10 nodes ที่ดึงมา หลายอันซ้ำกับ state ที่เคยเห็นแล้ว สรุปได้เป็น 4 กลุ่ม:

| # | Node ID | ชื่อ Frame | สถานะ |
|---|---|---|---|
| 1 | [4043:249228](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4043-249228) | Pet management - creating | ซ้ำกับ SC-PM-02 node #3 (Step 1 + Category dropdown) |
| 2 | [4141:29371](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4141-29371) | Pet management - upload image | ซ้ำกับ SC-PM-02 node #4 (Step 2 เริ่มต้น, ยังไม่ upload อะไร) |
| 3 | [4032:163077](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4032-163077) | Pet management - upload image | Step 2 **หลัง upload** Wobbling.png แล้ว — เห็น uploaded-file card |
| 4 | [4042:170354](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4042-170354) | Pet management - upload image 2 | Step 2 **ทุก stage ครบแล้ว** — เผยรายชื่อ required animations จริงต่อ stage |
| 5 | [4042:169941](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4042-169941) | Pet management - upload image (overlay) | **Pet preview modal** เปิดอยู่ — stage tab = Egg, animation dropdown ปิด |
| 6 | [4141:759250](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4141-759250) | Pet management - upload image (overlay) | Pet preview modal — stage tab = Baby, animation dropdown **เปิด** เห็นรายการครบ |
| 7 | [4043:175864](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4043-175864) | Pet management - select | ซ้ำกับ SC-PM-01 node #5 (populated list + detail) ไม่มีข้อมูลใหม่ |
| 8 | [4141:166269](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4141-166269) | Pet management - Edit 1 | ซ้ำกับ #7 อีกที (Edit entry point ใช้หน้า select เดิม) |
| 9 | [4141:756383](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4141-756383) | Pet management - Edit 2 | ซ้ำกับ #4 (Edit ใช้ wizard เดียวกับ Create ทุกอย่าง) |
| 10 | [4141:756384](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4141-756384) | Pet management - Edit 3 | ซ้ำกับ #4 แต่ปุ่ม `Preview` เป็น enabled state (ไม่ opacity-50) |

**สรุป**: ของจริงที่มีข้อมูลใหม่มีแค่ #3, #4, #5, #6 — ที่เหลือ dev ใช้ spec ที่บันทึกไว้แล้วได้เลย

### ⚠️ Stage & Animation model จริงจาก Figma (ต่างจาก spec.md ทั้งหมด)

**Stage names ใน Figma มี 4 stage** (ไม่ใช่ 6 ตาม spec.md):

```
Egg → Baby → Adult → Evolved
```

**Required animations ต่อ stage** (ดึงจาก "Pet stages" sidebar + Pet preview modal's animation dropdown):

| Stage | Required animations | Count ที่เห็นใน Figma |
|---|---|---|
| Egg | `Wobbling`, `Evolution` | 2/2 (อีก node นึงโชว์ 3/3 — ไม่ตรงกัน ดู note ด้านล่าง) |
| Baby | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5/5 |
| Adult | สันนิษฐานว่าเหมือน Baby (`Walking`, `Sitting`, `Happy`, `Sad`, `Evolution`) | 5/5 |
| Evolved | สันนิษฐานว่าเหมือน Baby ด้วย (แม้จะเป็น stage สุดท้ายที่ไม่ควรมี "Evolution" ต่อแล้ว) | 5/5 |

**สิ่งที่ขัดกับ spec.md (`SC-PM-03` เดิม):**

| หัวข้อ | spec.md เดิม | Figma จริง |
|---|---|---|
| จำนวน stage | 6 stages (Egg, Hatch, Grow, Evolve, Lonely, Happy) | 4 stages (Egg, Baby, Adult, Evolved) |
| หน่วยของ animation | แยกราย direction (`idle`, `walk_n`, `walk_s`, `walk_e`, `walk_w`, `sit`) ต่อ 1 spritesheet ต่อ 1 direction | รวมเป็น spritesheet เดียวต่อ "ท่า" (`Walking` ครอบคลุมทุก direction ในไฟล์เดียว, `Sitting`, `Happy`, `Sad`, `Evolution`) |
| Mood (Lonely/Happy) | เป็น stage แยกต่างหาก (คนละ tab จาก growth stage) | `Happy`/`Sad` เป็น **animation slot ภายใน growth stage** ไม่ใช่ stage แยก — และไม่มี "Lonely" เลย มีแต่ "Sad" |
| Egg required count | 1 (`wobble` เท่านั้น) | 2 (`Wobbling` + `Evolution`) |

**Egg count ไม่ตรงกันเองในคนละ node ของ Figma ด้วย** — node #3 (หลัง upload 1 ไฟล์) แสดง `2/2`, node #4 และ #9 แสดง `3/3`
→ ✅ **ตัดสินแล้ว: Egg = 2 slot** ยึด animation dropdown (node #5) ที่โชว์ `Wobbling` + `Evolution` เท่านั้น ส่วน counter `3/3` ถือเป็น mockup ที่ไม่ sync

**✅ ปิดแล้ว — ค่าที่ใช้จริง**:

| Stage | Required slots | Count |
|---|---|---|
| `egg` | `Wobbling`, `Evolution` | 2 |
| `baby` / `adult` / `evolved` | `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution` | 5 |

**ผลต่อ schema**: spritesheet เป็น **grid** ไม่ใช่ strip → ต้องมี `direction_rows` และ `frame_height = sprite_height / direction_rows` (ดู [db-schema-api-contract.md](db-schema-api-contract.md))

**`direction_rows` = `1` หรือ `4` เท่านั้น** (VO orthogonal-only) ลำดับแถวใช้ของ avatar เดิมเป๊ะ — `0 = down` · `1 = left` · `2 = right` · `3 = up` (`zyra-engine/avatar-frames.ts`)

### Step 2 — Upload stage & animation: หลัง upload สำเร็จ (node #3)

Upload file card เปลี่ยนจาก dropzone ว่างเป็นแสดงไฟล์ที่ upload แล้ว:
- Icon `image` (42×42px, ghost style)
- ชื่อไฟล์ (Body/Medium 14px) เช่น `Wobbling.png`
- Meta row: `Size: {n} mb` + bullet `•` + status สีเขียว `Completed` (Caption 12px)
- ปุ่ม `Trash` (ลบไฟล์) ชิดขวา

### Pet preview modal — "Object Composer" (node #5, #6)

เปิดจากปุ่ม `Preview` ที่ header ของ section "Upload stage & animation" (enable เมื่อมี asset upload แล้วอย่างน้อย 1 อัน — ดู node #10)

**Layout**: full-screen overlay (scrim ดำ) + panel กลางจอ 900×600px, bg `#242B32`, radius (ตาม card ทั่วไป)

- **Header**: Title `Pet preview` (Sub/Bold) + description `Preview your pet across all stages and animations before publishing.` (Body/Regular, เทา) + ปุ่ม Cancel (X) มุมขวาบน
- Divider
- **Tab row**: 4 stage tabs `Egg | Baby | Adult | Evolved` (แต่ละ tab กว้าง 80px, active = bg เขียว `rgba(88,214,141,0.2)`) — ด้านขวาของแถวเดียวกันมี **Animation dropdown** (input 160px) แสดงชื่อ animation ปัจจุบันของ stage ที่เลือก พร้อม chevron เปิด popup:
  - Egg dropdown: `Wobbling`, `Evolution`
  - Baby dropdown: `Walking`, `Sitting`, `Happy`, `Sad`, `Evolution`
- **Preview canvas** (868×430px): render animation loop ของ stage+animation ที่เลือกอยู่ (ตรงกับ spec.md's "Preview: แสดง animation loop บน canvas ก่อน save")
- **Object drag handle** (80×80px) ลอยอยู่กลาง canvas — น่าจะเป็นตัวสัตว์ที่ลาก/ทดสอบตำแหน่งได้ หรือ scrub ตำแหน่ง anchor ของ sprite

### Implementation notes เพิ่มเติม

1. ✅ stage/animation model ปิดแล้ว — implement ได้เลย ใช้ slot 6 ตัวตามตารางด้านบน + `direction_rows` ใน upload form
2. Pet preview modal เป็น component ใหม่ที่ spec.md ไม่ได้พูดถึงเลย (ไม่มีใน Acceptance Criteria เดิม) — ต้องเพิ่มลง spec.md ว่าเป็นส่วนหนึ่งของ "Preview: แสดง animation loop บน canvas ก่อน save" ที่ระบุไว้แล้ว แต่ implementation จริงคือ modal เต็มจอ ไม่ใช่ inline canvas เล็กๆ ในฟอร์ม
3. Edit flow (node #7-10) ใช้ UI ชุดเดียวกับ Create ทั้งหมด (ไม่มีหน้า Edit แยก) — คอนเฟิร์มว่า implementation ควร reuse component เดียวกันสำหรับทั้ง create และ edit mode
4. "Preview" ปุ่ม disabled จนกว่าจะมี asset อัปโหลดอย่างน้อย 1 ชิ้น (เห็นจาก node #10 ที่ enabled หลังมี asset)

---

## SC-PM-04 · กำหนด XP Config

> ✅ **ปิดแล้ว (ข้อ 3, 4)** — ใช้ **10 activities** + **mood 3-state** ตาม Figma/card ค่าตัวเลขทั้งหมดอยู่ใน [spec.md](spec.md#sc-pm-04--กำหนด-xp-config) และรูปร่าง JSONB ใน [db-schema-api-contract.md](db-schema-api-contract.md)
>
> ⚠️ ข้อยกเว้น: sticky note ใน Figma เขียน `Happy XP (50%)` — **ยึด card = 150%** (Happy = bonus) ไม่ใช่ Figma

Node เดียว [4066:205195](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4066-205195) เป็น **section รวมทั้ง flow** (ไม่ใช่ frame เดียว) มี 16 frames/instances ข้างใน: หน้า editing หลัก, หน้า saved (พร้อม toast 6 แบบ), confirm modal, และ sticky notes 6 อันที่เป็น edge-case notes จาก QA/Designer — ดึงมาครบทุกจุดแล้ว

### Page layout

```
┌─────────────┬──────────────────────────────────────────────┐
│  Sidebar    │  Headbar                                     │
│  (275px)    ├──────────────────────────────────────────────┤
│             │  Tabs: [Pet Library] [XP Configuration ●]     │
│             ├───────────────┬──────────────────────────────┤
│             │ Stats +       │  3 collapsible config sections│
│             │ Version       │  (Evolution XP /               │
│             │ history       │   Mood & Penalty /             │
│             │ (341px)       │   XP Sources & Limits)         │
│             │               │  (728px)                       │
└─────────────┴───────────────┴──────────────────────────────┘
```

Header: Title `XP Configuration` (H/Bold) + Button group ขวา: `✕ Cancel` (bg ขาว) / `✓ Save` (bg เขียว `#58D68D`)

### ซ้ายมือ — Stats & Version history (341px)

**Stat summary card** (มี donut-chart illustration ประกอบ):
- `Max evolution within` → เลขใหญ่ `40` + label `Days` (**คำนวณจาก** Growth-to-Evolved threshold รวม ÷ Max XP/Day โดยประมาณ)
- Divider
- `Total XP needed` : `2,000 XP` (= Growth to Baby + Growth to Adult + Growth to Evolved รวมกัน)
- `Max XP / Day` : `65 XP` (= ผลรวม XP ของทุก XP source ที่เปิด switch ไว้)
- Divider
- Footnote (Caption, เทา): `* Calculation assumes users maximise all available daily XP sources.`

**Status history** section:
- Header `Status history`
- Timeline แนวตั้ง (เส้น + จุด) แสดง version ล่าสุดอยู่บนสุด:
  - **Current** (มี `Locate` icon) — ตำแหน่งปัจจุบัน/unsaved state
  - **Save version** card ต่อ version: badge `V 2.0` / `V 1.9` / `V 1.8` + label `Save version` + mini profile row (avatar วงกลม 24px + ชื่อผู้บันทึก + เวลา `13:59`) + ปุ่ม `⋯ More` (ซ่อนอยู่ opacity 0 จนกว่าจะ hover) → เปิด tooltip/menu `Restore`
  - มี frame ที่ถูก hidden ไว้อีก 3 ชุด (`Frame 427323353/359/356`) — คือ version เพิ่มเติมที่ยังไม่แสดง ตรงกับ spec.md ที่ระบุ "Config history: บันทึก 10 versions ล่าสุด"

**Restore confirmation modal** (เปิดจากปุ่ม `Restore` ใน version card):
- Backdrop blur, panel 458×188px
- Title `Restore selected version?` + ปุ่ม X ปิด
- Divider
- Description: `The current workspace will be replaced with this version. Recent changes may be lost.`
- ปุ่ม: `Cancel` (ขาว) / `Restore` (เขียว)

**Toast แจ้งเตือนหลัง Save** (มุมขวาบน, 336px):
- Icon check เขียวใน badge กลม (bg `rgba(88,214,141,0.2)`)
- ข้อความ: `XP configuration saved successfully.`
- ปุ่มปิด (X) ด้านขวา

### ขวามือ — 3 Collapsible Config Sections (728px, แต่ละ section มี Chevron-Up ย่อ/ขยายได้)

#### 1) Evolution XP
> `Set the XP required for pets to level up to the next stage.`

| Field | Description | Input |
|---|---|---|
| **Growth to Baby** | Set the XP threshold required to hatch an Egg into a Baby. | number input + suffix `XP` |
| **Growth to Adult** | Set the XP threshold required for a Baby to grow into an Adult. | number input + suffix `XP` |
| **Growth to Evolved** | Set the XP threshold required to evolve an Adult to its final stage. | number input + suffix `XP` |

→ **ยืนยัน stage model 4 stages (Egg→Baby→Adult→Evolved) ตรงกับที่พบใน SC-PM-03 เป๊ะ** — เป็นหลักฐานยืนยันว่า spec.md's 6-stage model (Egg/Hatch/Grow/Evolve/Lonely/Happy) ผิด ต้องแก้ spec.md ให้ตรงกับ 4-stage model นี้

#### 2) Mood & Penalty Configuration
> `Define pet moods and their corresponding penalties.`

| Mood state | Description | Inputs |
|---|---|---|
| **Happy State** | Set the inactivity duration before transitioning to Neutral, and the bonus XP rate earned. | `[hours]` + `[XP%]` |
| **Neutral State** | Set the inactivity duration before transitioning to Sad, and the base XP rate earned. | `[hours]` + `[XP%]` |
| **Sad State** | Set the inactivity duration while Sad, and the reduced XP rate applied as a penalty. | `[hours]` + `[XP%]` |

Mood flow: **Happy → (idle N ชม.) → Neutral → (idle N ชม.) → Sad**, แต่ละ mood มี XP earning rate multiplier (`XP%`) เป็นของตัวเอง — ยิ่ง mood แย่ลง (Sad) ยิ่งได้ XP น้อยลง (penalty)

→ **ไม่ตรงกับ spec.md เลย** — spec.md มีแค่ 2 field (`sad_after_hours: -48`, `xp_happy: +48`) แต่ Figma จริงเป็น **3-state mood system** พร้อม XP% multiplier แยกราย mood (ดู sticky note: ตัวอย่างจริงคือ `Happy XP (50%)` vs `Neutral XP (100%)`)

#### 3) XP Sources & Limits
> `Configure how pets earn XP and set maximum earning limits.`

แต่ละ activity เป็น row: label + `[time]` input + `[XP]` input + `Switch` (เปิด/ปิด source นี้) — มีทั้งหมด **10 activities**:

| # | Activity |
|---|---|
| 1 | Daily login |
| 2 | Stay in workspace for 10 minutes |
| 3 | Stay in workspace for 30 minutes |
| 4 | Join a meeting |
| 5 | Attend a meeting for 10 minutes |
| 6 | Attend a meeting for 30 minutes |
| 7 | Send your first message of the day |
| 8 | Send 10 chat messages |
| 9 | React with an emoji |
| 10 | Play with your pet |

→ ✅ **ใช้ 10 activities ตาม Figma** (ข้อ 4) โมเดล 3 sources เดิมใน spec.md ตกไป
- `time` field ที่เห็นในดีไซน์ — **ไม่มีจริง** เวลาถูกฝังเข้าไปในชื่อ activity แล้ว (`_10min` / `_30min`) ไม่ใช่ input แยก
- Switch เปิด/ปิดต่อ activity — เผื่อ `enabled: boolean` ไว้ใน JSONB แล้ว (ยังรอ PM ยืนยันว่าต้องมีจริงไหม ไม่บล็อก)

### Edge-case validation notes (จาก sticky notes ของ Designer/QA — แปลไทยไว้เดิม)

พบ sticky notes 6 อันแนบอยู่กับ flow นี้ ล้วนเป็น validation rule ที่ designer ระบุไว้ ต้องเก็บเป็น acceptance criteria เพิ่มใน spec.md:

1. **กรณี Toggle ปิดหมด** — ถ้าปิด switch ทุก XP source เลย ระบบต้องมี fallback behavior (เช่น pet ไม่โต แต่ห้าม error/crash)
2. **กรณีเปอร์เซ็นต์ XP ขัดแย้งกับหลักความเป็นจริง** เช่น Happy XP (50%) แต่ Neutral XP (100%) — mood ที่ดีกว่าไม่ควรได้ XP น้อยกว่า mood ที่แย่กว่า ต้อง validate ลำดับ (Happy% ≥ Neutral% ≥ Sad%)
3. **กรอกระยะเวลาเป็น 0 hours** อาจทำให้ pet เปลี่ยน mood ทันทีจนวนลูปเปลี่ยน Mood ไม่หยุด — ต้องกำหนด min hours > 0
4. **เปิดสวิตช์ใช้งานแต่กรอกค่าเป็น 0** — XP source เปิดอยู่แต่ให้ 0 XP เป็นค่าที่ inconsistent ต้อง validate หรือเตือน
5. **หากกรอก XP% เป็นค่าติดลบ** (เช่น -50%) จะทำให้ XP ของ pet ลดลงเมื่อ user ทำกิจกรรม (กลับด้าน) — ต้อง validate ไม่ให้ติดลบ (หรือตั้งใจให้ติดลบได้สำหรับ penalty แต่ต้องมี UI บอกชัดว่าเป็นการลด)
6. **กรณี Evolution XP กรอก Growth to Baby (100) > Growth to Adult (50)** หรือ Growth to Evolved น้อยกว่าขั้นก่อนหน้า — thresholds ต้อง monotonically increasing (Baby < Adult < Evolved)
7. **กรณี Evolution XP กรอกค่าเป็น 0, ค่าว่าง (Empty/Null), ค่าติดลบ (-100), หรือทศนิยม/ตัวอักษร** — ต้อง validate เป็นจำนวนเต็มบวกเท่านั้น

### Design tokens เพิ่มเติมที่พบใน SC-PM-04

| Element | Detail |
|---|---|
| Section header chevron | `Cheron-Up` icon มุมขวาบนของแต่ละ section — ใช้ toggle collapse/expand |
| Switch (XP source) | component เดิม (`Track` + `Thumb`) ตาม pattern ที่เจอใน SC-PM-02 |
| Version badge | เช่น `V 2.0` — pill เล็ก border-radius สูง |
| Avatar (version history) | วงกลม 24px, initials fallback (`CG` = Conan Grey) |
| Toast | bg `#1A1B1E`, radius 16px, drop-shadow `0 4px 8px rgba(255,255,255,0.08)`, icon badge เขียว 40px |
| Restore modal | backdrop-blur 4px, panel bg gradient (`rgb(36,43,50)` ทับ white 100% เป็น mask) |

### Implementation notes

1. ✅ Mood 3-state + 10 activities ปิดแล้ว — implement ได้เลย schema เก็บเป็น **JSONB snapshot ต่อ version** ใน `tb_pet_xp_config` (ไม่ใช่ 19 คอลัมน์) เพื่อให้ history version เก่าแช่แข็งจริง ดู [db-schema-api-contract.md](db-schema-api-contract.md)
2. **Stat summary (Max evolution within / Total XP needed / Max XP per Day)** เป็นค่าที่ **คำนวณฝั่ง client** จากค่าที่กรอกในฟอร์มแบบ real-time (ไม่ต้อง API call) — ต้องผูก formula ให้ตรง
3. Version history + Restore ตรงกับ spec.md's "Config history: บันทึก 10 versions ล่าสุด ย้อนกลับได้" แต่ spec.md ไม่ได้พูดถึง UI detail (avatar/timestamp/More menu/confirm modal) — เพิ่มลง spec.md
4. Toast message ต้องเป็น "XP configuration saved successfully." ตาม Figma เป๊ะ (ไม่ใช่ข้อความ confirm แบบ blocking ตามที่ spec.md เขียนไว้ว่า "Save confirmation: ..." — Figma ใช้ toast แจ้งเตือนหลัง save เสร็จ ไม่ใช่ dialog ยืนยันก่อน save)
5. รวบรวม 7 validation rules จาก sticky notes เข้า spec.md ของ SC-PM-04 เป็น Acceptance Criteria เพิ่มเติม

---

## SC-PM-05 · วาง Pet ลง Room ผ่าน Map Editor

> ✅ **เคาะแล้ว 2026-08-17 — ยึด flow ใน Figma** drag-and-drop บน Map Editor เป็นของจริง, ตัด tab "Assign to Room" ในหน้า Pet Management ออก, **ตั้งชื่อ pet ได้ตอนวาง** (เหมือนตั้งชื่อห้อง) ส่วน flow ฟอร์มใน spec.md เดิม/ClickUp card ตกไป

Node [4114:199428](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4114-199428) เป็น section รวม 9 frames + 3 sticky notes อยู่ใน **Map Editor** (คอมโพเนนต์เดิมที่ใช้วาง object/furniture ทั่วไปในระบบ) ไม่ใช่หน้า Pet Management เลย

### Flow จริงจาก Figma

```
1. Admin เปิด Map Editor ของ Workspace Template (คอมโพเนนต์เดิม — ดู [[vo-renderer-and-data-flow]])
2. Object palette (sidebar ซ้าย) มี "Pet" object card:
   - Pet card แสดง sprite preview (80×80) + ชื่อ default (เช่น "Golden dog") + footprint "1x1"
   - แถวไอคอนเล็ก (24px × 4) ด้านล่าง card = pet types อื่นที่เลือกได้ (เหมือน object variant swatches)
3. Admin ลาก "Object drag" handle (40×40) จาก palette ไปวางบน room zone บน canvas
   - Room zone ถูก highlight ด้วย rounded-rectangle (เช่น "Rectangle 15/16" ในดีไซน์)
4. วางสำเร็จ → pet marker ปรากฏตรงตำแหน่งที่วาง (พร้อม sprite ตัวเล็ก 24×24 + drag handle overlay)
5. คลิก marker ที่วางแล้ว → เปิด "Marker menu" (popover เล็ก): แสดงชื่อ pet + ปุ่ม 🗑 Trash (ลบ pet ออกจาก room)
```

### Error / Edge-case states (จาก sticky notes + frames ที่ดึงมา)

**1) วางนอก Room zone** → sticky note: `Pet วางได้แค่ Room zone เท่านั้น`
- Toast แดง (bg `rgba(240,58,58,0.2)` icon, drop-shadow): Title `Unable to place pet` (Body/Bold) + message `Pet cannot be placed in this area. Choose another location.`

**2) วางในห้องที่มี pet อยู่แล้ว** → sticky note: `กรณีวางสัตว์เลี้ยงในห้องที่มีสัตว์เลี้ยงอยู่แล้ว`
- เปิด **"Replace this pet" confirmation modal** (backdrop-blur 4px, panel 458×188px — component เดียวกับ "Restore version" modal ใน SC-PM-04):
  - Title: `Replace this pet` + ปุ่ม X ปิด
  - Divider
  - Description: `This room already has a pet assigned. Replacing it will remove the current pet from this room.`
  - ปุ่ม: `Cancel` (ขาว) / `Replace` (เขียว `#58D68D`)
- ตรงกับ spec.md's "warning: ห้องนี้มี Pet อยู่แล้ว ต้องการแทนที่ไหม?" — **wording ต่างกันเล็กน้อย** (Figma ใช้ "Replace this pet" ไม่ใช่คำถามแบบ spec.md) แต่ concept ตรงกัน

**3) วางในพื้นที่ห้ามวาง (เช่น ทับ object อื่น)** → sticky note: `กรณีวางในพื้นที่ห้ามวาง`
- ใช้ toast เดียวกับกรณี (1) — `Unable to place pet`

**Marker menu** (คลิก pet ที่วางแล้วบน map):
- Popover เล็ก (bg `#242B32`, radius 8px): แสดงชื่อ pet (เช่น `Golden dog`) → Divider → ปุ่มไอคอน `🗑 Trash` (ลบ pet ออกจาก room ทันที — ตรงกับ spec.md's "สามารถลบ Pet ออกจาก Room ที่ต้องการได้")

### สิ่งที่ Figma มีเพิ่มจากที่เคยดึง (ตรวจซ้ำ 2026-09-04 ด้วย get_metadata + get_design_context ทุก frame)

> ครั้งแรก (08-17) ดึงมา 9 frame + 3 sticky — ตอนนี้ section มี **12 frame + 5 sticky** (เพิ่ม 4387:120740, 4688:562208, sticky 4387:121500, 4387:121470)

| Node | อะไร | spec ที่ได้ | สถานะ |
|---|---|---|---|
| 4141:760560 Object card | การ์ด pet ใน palette: bg `#242B32` radius 8 p-2 gap-2 · sprite 80×80 · เส้นคั่น `rgba(255,255,255,0.2)` · ชื่อ Caption 12/15 ขาว · footprint "1x1" `#8C99A6` · แถว swatch 24×24 gap-2 = pet type อื่น | ทำได้ — sprite = thumbnail/เฟรมจริงของ pet type (ไม่ใช่ asset จาก Figma) |
| 4114:282533 marker บน map | กรอบ zone highlight `rgba(45,182,255,0.1)` + border `#2DB6FF` (Blue/500) · pet icon 24×24 · "Object drag" handle 40×40 p-2 ทับมุมขวา | ทำได้ — ใช้ตัวแทน object drag ของ editor เดิม |
| 4114:281993 Marker menu | popover `#242B32` radius 8 p-1 gap-1 w-253: แถวชื่อ (Body 14/18 ขาว, px-2 py-1) → Divider → แถว [pet icon 24] [Trash 16 ใน p-1] | ทำได้ — Trash = `lucide Trash2` ตาม rule 12 · **ไม่มีปุ่ม rename ใน Figma** แต่ PM ให้แก้ชื่อทีหลังได้ → คลิกชื่อเพื่อแก้ (inline) เหมือน rename ห้อง |
| 4387:121093 Marker menu (stage row) | แถวไอคอน 4 stage (egg / baby / adult / evolved) 24×24 gap-2 ใน `#242B32` radius 8 p-1 — stage ปัจจุบัน opacity 100 ที่เหลือ 50 % | ⚠️ **scope ใหม่** ดูข้างล่าง |
| 4114:282877 General modal "Replace this pet" | panel 458×188 `#242B32` radius 16 p-4 gap-6 backdrop-blur 4 · title Sub/Medium 16/22 + ปุ่ม X 24 · Divider · body 14/18 `#8C99A6` · ปุ่ม `Cancel` (ขาว, text `#1A1B1E`) / `Replace` (`#58D68D`) h-32 px-4 radius 6 | ทำได้ — **มีผลแล้ว** เพราะ PM เคาะ 1 room = 1 pet |
| 4688:562222 General modal "Stage change unavailable" | โครงเดียวกัน · body: "All new pets begin at **Egg Stage(1)** and evolve as the workspace earns XP." · ปุ่มเดียว `Comfirm` (typo ใน Figma → ใช้ "Confirm") | ⚠️ ผูกกับ stage row |
| 4141:49687 Toast error | `#1A1B1E` radius 16 p-4 shadow `0 4px 8px rgba(255,255,255,0.08)` · icon box 40 `rgba(240,58,58,0.2)` radius 8 + X แดง 24 · title Body/Bold "Unable to place pet" + body "Pet cannot be placed in this area. Choose another location." · ปุ่ม X 16 | ทำได้ — reuse toast ของ editor |

**Sticky notes ใหม่ (ข้อความเต็มจาก node name):**
1. `4387:121500` — "Pet เป็น Stage 1 เสมอ แล้วถ้าจะเปลี่ยนเป็น Stage อื่นต้องมีประวัติว่าทีมนี้เคยเลี้ยงสัตว์เลี้ยง + XP สัตว์เลี้ยงไปถึง Stage ไหน"
2. `4114:282959` (replace) — "สัตว์เลี้ยงเดิมอยู่ Stage ไหน สัตว์เลี้ยงใหม่คง Stage นั้นไว้ เช่น สุนัข Stage 4 เปลี่ยนเป็นแมวก็ต้อง Stage 4" → ✅ **api รองรับแล้ว** `POST …/pets {replace: true}` ตัวใหม่รับ `xp` / `last_activity_at` / `last_seen_stage` จากตัวเดิม (zyra-api #65 commit 3)
3. `4387:121470` — "กรณีเลือกสัตว์ Stage ที่สูงกว่า แต่ทีมยังไม่เคยเลี้ยงสัตว์ หรือพัฒนาสัตว์เลี้ยงถึง Stage นั้น / กรณีเลือกสัตว์ Stage ที่ต่ำกว่าแต่สัตว์เลี้ยงยังไม่ Stage 4 → ไม่อนุญาตให้ทำได้" (→ modal "Stage change unavailable")

**⚠️ Stage row = scope ที่ contract ไม่มี** — Figma ให้ admin เลือก stage ของ pet จาก marker menu โดยมีเงื่อนไข "ทีมเคยถึง stage นั้นแล้ว" (ต้องมีประวัติ XP ของ workspace) · `stage` เป็นค่า derive จาก `xp` ตาม [db-schema-api-contract.md](db-schema-api-contract.md) จึงต้องนิยามว่า "เลือก stage" = set `xp` เป็น threshold ของ stage นั้น? และ "เคยถึง" อ่านจากอะไร (pet ตัวเดิมในห้อง? ทุกห้องใน workspace? ต้องมี ledger PR 9) → ✅ **เคาะ 2026-09-04: ตัดออกจาก v1** ใช้ Replace (เปลี่ยนชนิดสัตว์ XP/stage ติดห้อง) แทน — UI ที่ทำแล้ว: palette card, drag-drop, ตั้งชื่อ, marker menu (ชื่อ + trash), Replace modal, toast

### สิ่งที่ขัดกับ spec.md เดิม

| หัวข้อ | spec.md เดิม | Figma จริง |
|---|---|---|
| Entry point | Pet Management → Tab "Assign to Room" (หน้าฟอร์ม) | **Map Editor** ของ workspace template (คอมโพเนนต์คนละหน้า) |
| วิธีเลือก workspace/room | Search workspace + Room dropdown | เปิด Map Editor ของ workspace/room นั้นตรงๆ (ไม่มี dropdown ค้นหาในหน้านี้) |
| วิธีเลือก Pet Type | Dropdown "Pet Type" (เฉพาะ active) | เลือกจาก object palette แบบ drag-and-drop (icon swatches) |
| ชื่อ Pet | Input กรอกชื่อ optional | Figma ไม่มี input — ✅ **PM ยืนยันว่าตั้งชื่อได้ตอนวาง** (optional, max 30) UI ยังไม่มีใน mockup ให้ทำแบบเดียวกับตั้งชื่อห้อง |
| ตำแหน่ง spawn | "center ของ room zone boundary" (auto) | Admin **ลากวางตำแหน่งเองได้** ภายใน room zone ไม่ได้ auto-center |
| Confirm replace | "warning ห้องนี้มี Pet อยู่แล้ว ต้องการแทนที่ไหม?" | Modal "Replace this pet" — concept เดียวกัน wording ต่าง |
| ลบ pet | ไม่ระบุ UI ชัดเจน แค่บอกว่า "ลบได้" | Marker menu (คลิก pet บน map) → Trash icon |

### Implementation notes

1. **Flow นี้ควร implement เป็นส่วนขยายของ Map Editor เดิม** (เพิ่ม "Pet" เป็น object category ใหม่ในระบบ object placement) ไม่ใช่สร้างหน้าใหม่ใน Pet Management — reuse drag-drop/zone-validation logic ที่มีอยู่แล้วสำหรับ object ทั่วไป ([[component-reuse]])
2. ✅ **ตัด Tab "Assign to Room" ออกจาก Pet Management ทั้งหมด** — placement อยู่ใน Map Editor ที่เดียว
3. Zone validation ("Pet วางได้แค่ Room zone เท่านั้น") ต้องเช็คว่า room zone เป็น zone_type เดียวกับที่ระบบมีอยู่แล้ว ([[vo-block-zone-collision]] มี pattern การ forward blockZones→MapConfig ที่ใกล้เคียง) — zone เป็น tiles JSONB ไม่ใช่ AABB ให้ใช้ `lib/zone-utils.ts` และตรวจซ้ำฝั่ง service (`POSITION_OUTSIDE_ZONE`)
4. **ตั้งชื่อ pet ตอนวาง** — Figma ไม่มี mockup ของ UI นี้ ให้ทำ popup หลังวาง (optional, max 30 chars, default = ชื่อ Pet Type) และแก้ชื่อทีหลังได้จาก marker menu
5. ✅ **"Replace this pet" modal (เคส 2) ต้องทำแล้ว** — PM เคาะ 1 room = 1 pet (2026-09-04) · api: POST ซ้ำห้องเดิมได้ 409 `ZONE_ALREADY_HAS_PET` → เปิด modal → ยืนยันแล้วส่ง `replace: true` (ตัวใหม่รับ XP/stage ต่อจากตัวเดิม)

---

## SC-PM-07 · Sprite Upload ไม่ผ่าน Validation

Node [4043:252350](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4043-252350) เป็น section รวม 6 frames — ทุก frame คือหน้า **"Pet management - upload image" (Step 2 เดิม)** + Toast แดง (error) ลอยขวาบนคนละข้อความ ไม่มี UI ใหม่นอกจาก error toast

### Error Toast — Component เดียว, ใช้ร่วมกันทุก validation error

Layout เดียวกับ toast สีเขียว (success) ที่เจอใน SC-PM-04/05 แต่เปลี่ยนเป็นโทนแดง:
- Icon badge 40px, bg `rgba(240,58,58,0.2)`, icon `Cancel` (X) สีแดง `#F03A3A`
- Text: Title (Body/Bold 14px, สีขาว) + description (Body/Regular 14px)
- ปุ่มปิด (X) 16px มุมขวา
- bg `#1A1B1E`, radius 16px, drop-shadow `0 4px 8px rgba(255,255,255,0.08)`

### รายการ error message จริงจาก Figma (6 frames → 5 ข้อความ unique)

| Title | Message | Trigger (จับคู่กับ spec.md) |
|---|---|---|
| `Upload failed` | `Only PNG files are supported.` | `INVALID_FILE_TYPE` — ไม่ใช่ PNG |
| `Upload failed` | `The file must be 1 MB or smaller.` | `FILE_TOO_LARGE` — เกิน 1MB (ปรากฏซ้ำ 2 frame) |
| `Invalid frame count` | `Frame count must be between 1 and 64.` | `INVALID_FRAME_COUNT` |
| `Invalid frame rate` | `Frame rate must be between 4 and 24 FPS.` | `INVALID_FRAME_RATE` |
| `Invalid PNG image` | `The uploaded PNG must include a transparent background.` | transparency check |

### สิ่งที่ขัดกับ spec.md — ตัดสินแล้ว

1. **Transparency: ✅ ยึด PM = warning ไม่ block** — Figma แสดงเป็น error toast แดง (`Invalid PNG image`) แต่ PM ตอบชัดในข้อ 6 ว่าไม่บล็อก upload → ใช้ **yellow banner / warning toast** และ API คืน `200` พร้อม `data.warnings: ["NO_TRANSPARENCY"]` ไม่ใช่ 400
2. **ไม่มี toast สำหรับ `FRAME_SIZE_MISMATCH` / `FRAME_ROW_MISMATCH` ใน Figma** — ใช้ **inline error ใต้ field** (แสดงทันทีที่กรอก `frame_count` / `direction_rows` ตาม acceptance criteria ของ SC-PM-07) ส่วน toast แดงสงวนไว้สำหรับ error ที่เกิดตอนเลือกไฟล์
3. **Sticky note "Frame count กับ Rate น่าจะอนาคต เพราะตอนนี้ยังไม่มีให้กรอก"** — ✅ เคลียร์แล้ว: card ระบุว่า `frame_count` / `frame_rate` เป็น **per-animation** (ไม่ใช่ global ต่อ stage) และตอนนี้เพิ่ม `direction_rows` เข้ามาอีกตัว → upload form ต่อ slot ต้องมี **3 input**: `frame_count` (number), `frame_rate` (number), `direction_rows` (⏸ รอดู sprite จริงก่อนว่าจะเป็น toggle 1/4 หรือ number input) Figma ยังไม่มี mockup ส่วนนี้ ให้ทำตาม pattern input ปกติของหน้านี้

### Implementation notes

1. Error toast ใช้ component เดียวกับ success toast (พบใน SC-PM-04/05) แค่เปลี่ยนสีธีมและข้อความ — ทำเป็น shared `<Toast variant="success" | "error" | "warning">` component เดียว (`warning` ใช้กับเคส transparency)
2. Client-side validate ทันทีที่เลือกไฟล์ตาม spec.md (PNG type, size, dimension) ก่อนยิง request; Server-side validate PNG magic bytes ซ้ำอีกที (`89 50 4E 47`)
3. Validate **2 แกน** ตาม grid model ใหม่: `width % frame_count = 0` และ `height % direction_rows = 0` — แสดง "frame size = {W/N} × {H/R} px" เป็น preview ใต้ field
