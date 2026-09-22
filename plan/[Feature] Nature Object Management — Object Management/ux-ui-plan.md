# SC-OBJ-NAT-01 · UX/UI Plan — Nature Object Management (Admin)

> **สถานะ:** ถอดจาก Figma จริงครบทั้ง 8 section แล้ว (ดึงเมื่อ 2026-09-16 ด้วย Figma MCP `get_design_context` + `get_metadata` + `get_variable_defs`) — **ยังไม่ implement**
> **🔄 ClickUp รอบที่ 2 (2026-09-16 ~11:09, ดู [spec.md §รอบที่ 2](spec.md#รอบที่-2--2026-09-16-pm-update-clickup)):** PM ขยับ spec เข้าหา Figma บางส่วน — **HP-04 ถูกถอดออกจาก scope** (§14.1 ข้อ 4 ปิด) · HP-03 ระบุแล้วว่า **กด Upload → Modal** และ HP-05 **Preview = popup จากหน้า Upload** (§14.1 ข้อ 6 ปิดสำหรับ HP-03/05; HP-02 ยังเขียน redirect อยู่) · PM **ลบ ASCII mock ของ preview** แต่ AC state buttons/Current State/playback **ยังอยู่** (ข้อ 11 ยังเปิด) · AC ใหม่: preview **fallback เป็น idle** สำหรับ state ที่ยังไม่ upload · AC ใหม่: **หลังบันทึกกำหนดสี/ประเภทของ box object ได้** → ตอบ `ต้องดึง` เรื่อง hitbox toolbar ใน §4.4 แต่เปิดคำถามใหม่ (ข้อ 14a) ว่าขัด "always walkable" ไหม
> **🔄 ClickUp รอบที่ 3 (2026-09-17 ~10:36):** status ทุก task → **`in progress`** แต่ **description/comment ไม่เปลี่ยนเลย** → §14.1 ยังเปิดอยู่ (**ข้อ 14a ปิดแล้ว 2026-09-17** — สี/ประเภท box ใช้กลไกเดิม เหลือเปิด 11 ข้อ)
> **✅ Implement ครบทุก node แล้ว 2026-09-22** ([zyra-app#429](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/429) + [#432](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/432)): HP-01 tree card · HP-02 create form · HP-03 upload modal (`nature-upload-modal.tsx`) · **HP-05 preview modal (`nature-preview-modal.tsx`) — ทำแล้วรอบ 10** · HP-06 saved/edit · EP-01 toasts (`nature-upload-validation.ts`) · EC-01 replace (`replace-spritesheet-dialog.tsx`) · HP-07 ใช้ของเดิมที่ตรงอยู่แล้ว · HP-04 descoped
> **ตั้งใจต่างจาก design 3 จุด:** Frame count/rate โชว์ `1`/`12` (ค่าที่ API เก็บจริง) ไม่ใช่ `50`/`24` ของ mock · HP-06 ยังมีปุ่ม Delete (§14.3 ข้อ 28 — Figma ขัดกันเอง ถ้าเอาออกจะลบ object ไม่ได้เลย) · weather icon ใน HP-05 ใช้ lucide monochrome ไม่ใช่ภาพประกอบมีสีของ Figma ([rule 12](../../../.claude/rules/12-icons.md) บังคับ lucide)
> **verify ถึงไหน:** HP-05 วัด geometry จาก DOM เทียบ Figma แล้ว (dev harness ชั่วคราว) · **ที่เหลือยังไม่ได้เปิดดูในหน้า admin จริง** เพราะต้อง login — ดู [progress.md รอบที่ 10](progress.md)
> **✅ 2026-09-20 — เคาะเพิ่ม 5 ข้อ: 1, 2, 3, 7, 8 ปิดหมด** → **§14.1 ไม่เหลือข้อที่กระทบ schema/API อีกแล้ว เขียน migration ได้** · ที่ยังเปิดคือเรื่อง UI/design ล้วน (5, 6 บางส่วน, 9, 10, 11, 12, 13, 14) ซึ่งไม่บล็อก backend — ต้องเคลียร์กับ PM ก่อนเริ่ม UI ที่ผูกกับ schema · ดู [spec.md §รอบที่ 3](spec.md#รอบที่-3--2026-09-17-status-เปลี่ยนเป็น-in-progress) · test ที่อิง §14.1 ห้ามล็อกค่า — ดู [test-plan.md §0](test-plan.md#0-สิ่งที่ห้ามล็อกค่าใน-test-จนกว่า-pm-จะเคาะ)
> **ไฟล์:** `Map8gX0L2hk7HnkaFRfhtj` — Zyra design (More Organised ver.) · อ่านคู่กับ [spec.md](spec.md) (ClickUp) และ [technical-design.md](technical-design.md)
> **ข้อค้นพบใหญ่ที่พลิกความเข้าใจจาก spec** — ดู [§14](#14-จุดที่-design-ขัดกับ-spec--ต้องเคลียร์ก่อน-implement) ก่อนอ่านส่วนอื่น:
> 1. **ไม่มี "Nature menu/tab" แยก** — Nature เป็น **Category ตัวที่ 10** ใน Object Management หน้าเดิม (โผล่เป็น checkbox ใน Filter, option ใน Category dropdown, และ badge บน card) — sidebar ไม่มี sub-item
> 2. **ไม่มีปุ่ม "บันทึกและตั้งค่า Animation" / ไม่มี redirect ไป Animation Manager** — เป็น section `Upload stage & animation` **inline ในฟอร์มเดิม** + ปุ่ม `+ Upload` เปิด modal 900×600
> 3. **Required state = Idle ตัวเดียว** (PM sticky ×2) ไม่ใช่ idle+sway_light+sway_strong ตาม spec · state ที่ 3 ชื่อ **`Sway normal`** ไม่ใช่ `sway_strong`
> 4. **ไม่มีช่องกรอก frame_count / frame_rate ใน modal** — มีแค่ dropdown read-only บนฟอร์มหลัก (`50` / `24`) ที่ PM เขียนว่า "อนาคต ยังไม่มีให้กรอก"
> 5. **Preview modal ไม่มี state buttons / Current State label / playback controls** ตาม spec — มีแค่ weather dropdown (5 ตัว) + wind slider + zoom
> 6. **Delete ต้องพิมพ์ชื่อ object ยืนยันทั้ง 2 เงื่อนไข** (ไม่ใช่เฉพาะเมื่อถูกวางบน map) · Hide = Status switch + Save (ไม่มี action แยก) · ไม่มี "(Hidden)" badge ใน Map Editor
> 7. **Nature เป็น shedding_tree ตัวเดียวในทุกเฟรม** — ไม่มีเฟรมของ bush/flower_bush/pine ฯลฯ · **ไม่มี `Custom`** ใน nature-type dropdown (6 ตัว)
> ค่าที่ **ยังไม่ได้ดึง** ทำเครื่องหมาย `ต้องดึง` ไว้ทุกจุด — ห้ามเดาตาม [10-figma-fidelity](../../../.claude/rules/10-figma-fidelity.md) · UI ทั้งหมด Tailwind-only ([08](../../../.claude/rules/08-shadcn-ui.md)) · icon lucide-only ([12](../../../.claude/rules/12-icons.md)) · reuse ก่อนสร้าง ([09](../../../.claude/rules/09-component-reuse.md))
> **หมายเหตุฟอนต์:** token ทุกตัวระบุ `Inter` แต่ห้ามใช้ `font-['Inter']` กับข้อความไทย (สระ/วรรณยุกต์เพี้ยน) → ใช้ `font-sans`

---

## 0. Design tokens ที่ใช้ทั้ง feature (จาก `get_variable_defs`)

| Token | ค่า | Tailwind | ใช้ที่ |
|---|---|---|---|
| Theme colour/Secondary · Background/Secondary | `#2B3540` | `bg-[#2B3540]` | page bg, card bg, Object files panel, upload card |
| Theme colour/Primary · Background/Primary | `#242B32` | `bg-[#242B32]` | sidebar, headbar, list/detail panel, modal, dropdown panel, input |
| Shade Black/500 | `#1A1B1E` | `bg-[#1A1B1E]` | toast, zoom pill, weather dropdown, count badge, Cancel-button text |
| Primary/500 | `#58D68D` | `bg-[#58D68D]` / `text-[#58D68D]` | primary button, active tab/page, toggle ON, Active tag, slider fill, selected row |
| Primary/10% · 20% | `rgba(88,214,141,0.1)` · `0.2` | | sidebar active bg, Active tag bg/border · active tab bg, toast icon box |
| Primary/700 | `#3E9864` | | checkbox checked (`ต้องดึง` ยืนยัน) |
| Grey/500 | `#8C99A6` | `text-[#8C99A6]` | caption, description, Hidden tag, read-only unit text |
| Grey/600 | `#7F8B97` | `text-[#7F8B97]` | **read-only / disabled input text** (ไม่มีชื่อ token ในชุดที่ดึงได้ — ค่าจริงจาก node) |
| Grey/700 | `#636D76` | `text-[#636D76]` | placeholder |
| Grey/100 · 300 · 400 | `#DBDFE3` · `#B2BBC3` · `#A3ADB8` | | **disabled primary button** bg · border · text |
| Grey/200 | `#CAD0D6` | | toggle OFF track (`ต้องดึง` ยืนยันจาก component 35:2604) |
| Red/500 · 5% · 20% | `#F03A3A` · `rgba(240,58,58,0.05)` · `0.2` | | Delete button, error toast icon box, Trash icon |
| Blue/500 · 10% · 20% | `#2DB6FF` · `rgba(45,182,255,0.1)` · `0.2` | | info alert banner, nature_type tag "Shedding tree" |
| Navy/500 · 10% | `#2C5AE4` · `rgba(44,90,228,0.1)` | | **category tag "Nature"** |
| Yellow/500 | `#ECC819` | | (ไม่พบใช้ในเฟรม Nature) |
| Solid White 5% · 10% · 20% | `rgba(255,255,255,0.05/0.1/0.2)` | | ghost button/canvas bg · slider track/position pill bg · border ทุกชนิด |
| Shade Black/20% | `rgba(0,0,0,0.2)` | | thumbnail overlay บน card |
| White shadow | `0px 4px 16px 0px rgba(255,255,255,0.08)` | `shadow-[0px_4px_16px_0px_rgba(255,255,255,0.08)]` | dropdown / submenu · (toast ใช้ `0 4px 8px` — MCP คืนต่างกัน `ต้องดึง` ตัวไหนถูก) |

Typography (Inter ทั้งหมด):

| Token | size/lh/weight | Tailwind |
|---|---|---|
| H/Bold | 20 / normal / 700 | `text-[20px] font-bold leading-normal` |
| Sub/Bold · Sub/Medium · Sub/Regular | 16 / 22 / 700·500·400 | `text-[16px] leading-[22px]` + weight |
| Body/Bold · Body/Medium · Body/Regular | 14 / 18 / 700·500·400 | `text-[14px] leading-[18px]` + weight |
| Caption 1/Regular | 12 / 15 / 400 · ls −0.43 | `text-[12px] leading-[15px] tracking-[-0.0516px]` |
| Caption/Regular (file-card meta) | 12 / 16 / 400 | `text-[12px] leading-[16px]` (`ต้องดึง` ว่าเป็น token คนละตัวจริงหรือ Figma ตั้งค่าหลุด) |
| Caption 2/Medium | 10 / 14 / 500 | `text-[10px] leading-[14px] font-medium` |

Radius: panel/modal/toast 16 · card/input/button-42/tag-bg 8 · button-32/pagination/zoom pill 6 · tag 4 · toggle/thumb/badge 90

---

## 1. โครงหลัก: Nature อยู่ **ใน** หน้า Object Management เดิม

```
/admin/object-management  (หน้าเดิม — 1440×1024)
┌ Sidebar 275 ─┬ Headbar 1165×72 ────────────────────────────────────────┐
│ Workspace    │                                                          │
│  Avatar mgmt │ ┌ List panel 368×920 ───┐ ┌ Detail panel 752×920 ──────┐ │
│ ▸Object mgmt │ │ Object          [+]   │ │ Add object   [Preview][…] │ │
│  Pet mgmt    │ │ [Search…] [Filter]    │ │ Property setting           │ │
│  Map mgmt    │ │ 100 objects   Name ▾  │ │  Object name | Category    │ │
│  Workspace…  │ │ ┌ Tree card ────────┐ │ │  Nature type | Z-index     │ │  ← แถวใหม่เมื่อ Category = Nature
│ User mgmt    │ │ │[img] Maple tree   │ │ │  Status  (●) Active        │ │
│  Customer    │ │ │ 🌲 State : 4      │ │ │ ───────────────────────    │ │
│  Admin       │ │ │ Shedding tree ✓Act│ │ │ Upload stage & animation   │ │  ← section ใหม่ (แทน Object Composer)
│              │ │ └───────────────────┘ │ │   [+ Upload]               │ │
│              │ │ …                     │ │  Frame count | Frame rate  │ │
│              │ │ ‹ 1 2 3 › 10/page     │ │  [Object files][Preview]   │ │
│              │ └───────────────────────┘ └────────────────────────────┘ │
└──────────────┴──────────────────────────────────────────────────────────┘
```

- **Sidebar ไม่เปลี่ยน** (`components/admin/admin-sidebar.tsx:62` เป็น flat item ไม่มี children) — Figma ก็ไม่มี sub-item Nature
- Nature โผล่ 3 ที่: **Filter submenu** (checkbox "Nature") · **Category dropdown** (option "Nature" + description) · **badge** บน card (category tag Navy / nature_type tag Blue)
- Modal ใหม่ 3 ตัว (ทุกตัว centered บน overlay): `Upload stage & animation` 900×600 ([§4](#4-hp-03--upload-stage--animation-modal-node-6034345420-master)) · `Nature preview` 900×600 ([§6](#6-hp-05--nature-preview-modal-node-5199369528)) · `Replace spritesheet?` 458×188 ([§10](#10-ec-01--replace-spritesheet-modal-node-6037509126))
- Side panel ใหม่ 1 ตัว (มีใน code แล้ว): `Affected Workspaces & Maps` 384×full ([§8.3](#83-side-panel-affected-workspaces--maps-node-5228769283))

### 1.1 Scenario → Figma node → component

| Scenario | Figma node หลัก | ของเดิม | Verdict |
|---|---|---|---|
| HP-01 List | Filter `5030:270503` · Sort `5008:246606` · List `5046:281042` · Tree card `5045:273291` · Nature detail `5167:317944` · Empty `5008:246599` | `object-list-panel.tsx`, `object-filter-menu.tsx`, `object-sort-menu.tsx`, `object-card.tsx`, `object-pagination.tsx`, `object-detail-empty.tsx` | **reuse + เพิ่ม nature variant ใน card / เพิ่ม option ใน filter** |
| HP-02 Create | Creating `5167:330557` · Category dropdown `5167:331169` · Nature-type dropdown `5167:331371` · Fill `5167:331415` | `object-add-form.tsx`, `tw-dropdown.tsx`, `constants.ts` | **reuse + condition `category === "nature"`** |
| HP-03 Upload | Modal master `6034:345420` · states `6035:352007`, `6035:352894` · form after save `6035:489923` · toast `5185:364950` | `pet-management/components/pet-upload-step.tsx` (AnimationUploadCard), `pet-upload-validation.ts`, `object-composer-preview-modal.tsx` (shell + tab strip), `object-preview-canvas.tsx`, `lib/toast.tsx` | **new modal ประกอบจากชิ้นเดิม** |
| HP-04 Config | *(ไม่มีเฟรมแยก)* — frame fields บน `5167:331415` / `5219:760257` | `tw-dropdown.tsx` | **ยังไม่มี design ที่กรอกได้** → ดู §5 |
| HP-05 Preview | `5199:369528` · dropdown open `5219:751880` · Thunderstorm `5219:477041` | `object-composer-preview-modal.tsx` (shell), `object-preview-canvas.tsx`, `tw-dropdown.tsx` | **new modal ประกอบจากชิ้นเดิม + slider/zoom pill ใหม่** |
| HP-06 Edit | Saved `5219:760257` · Complete `5185:340707` · toast `5219:761371` · upload instance `6037:502949` | `object-detail-panel.tsx`, `object-detail-content.tsx`, `object-add-form.tsx` (readOnly) | **reuse + ปุ่ม Preview + lock nature_type** |
| HP-07 Hide/Delete | Modals `5228:767857`, `5228:769279`, `5228:769300`, `5228:769304` · Side panel `5228:769283` · toasts `5228:768463`, `5219:761389` · hide `5228:764179`→`5228:765855`→`5219:761387` | `delete-object-dialog.tsx` (simple/warning/ConfirmNameModal/AffectedWorkspacesPanel/AffectedWorkspaceCard), status switch ใน `object-add-form.tsx`, `object-status-badge.tsx` | **reuse ทั้งหมด + แก้ copy/ค่าเล็กน้อย** |
| EP-01 Validation | Toasts `5230:784624`…`5230:791921` · frame `5230:784622` | `lib/toast.tsx` `errorWithTitle`, `pet-upload-validation.ts` | **reuse** |
| EC-01 Replace | `6037:509126` · upload modal `6037:508259` | shell ของ `delete-object-dialog.tsx` | **new `replace-spritesheet-dialog.tsx`** |

---

## 2. HP-01 · List Nature Objects

### 2.1 Filter submenu (node `5030:270503`, 200×472)

`flex-col gap-[8px] p-[8px] rounded-[16px] bg-[#242B32] shadow-[0px_4px_16px_0px_rgba(255,255,255,0.08)] overflow-clip`

| Element | Spec |
|---|---|
| Section title | `flex items-center p-[8px]` · Caption 1 `#8C99A6` · **"Filter"** / **"Status"** |
| Item | `flex items-center gap-[8px] p-[12px] min-h-[42px] rounded-[8px] w-full` · icon 16 (CheckBox / RadioButton asset) · Body/Regular white truncate |
| Divider ระหว่าง section | SVG asset 1px — สี `ต้องดึง` (คาด Solid White/20%) |

Strings ตามลำดับ: `Filter` · `Furniture` · `Decoration` · `Structure` · `Sofa` · `Walkable group` · **`Nature`** · `Status` · `All` · `Active` · `Hidden`
→ Figma มี category แค่ 6 (ไม่มี Interactive Barrier / Wall / Machine / Foods & Drink ที่ code มี) และมี radio `All` ที่ code ไม่มี — **คงของ code เดิม แค่เพิ่ม `nature` เข้า `TYPE_OPTIONS`** (rule 14 ห้ามแก้ของที่ไม่ได้สั่ง) · checked/hover state `ต้องดึง`

### 2.2 Sort submenu (node `5008:246606`, 200×142)

`flex-col p-[8px] rounded-[16px] bg-[#242B32] shadow-[…]` · item `p-[12px] min-h-[42px] rounded-[8px]` Body/Regular white · options `Name` · `Created at` · `Type` = ตรง `object-sort-menu.tsx` เดิม → **reuse as-is** (spec ขอ "ใช้มากสุด" — ไม่มีใน Figma, ดู §14)

### 2.3 หน้า List (node `5046:281042`, 1440×1024) — ส่วนที่เปลี่ยน

List panel (368×920 ที่ 288,88): `flex-col gap-[24px] items-end p-[16px] rounded-[16px] bg-[#242B32]`
- Title row: `Object` H/Bold + Add `size-[42px] p-[8px] rounded-[8px] bg-[#58D68D]` Plus 16
- Search row `gap-[8px]`: input `flex-1 h-[42px] bg-[#242B32] border border-[rgba(255,255,255,0.2)] rounded-[8px] px-[12px] py-[8px]` Search 16 + placeholder `Search for object` `#636D76` · Filter `size-[42px] bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)]` Filter 16
- Count row: `100 objects` Body/Regular white · Sort trigger `Name` + ChevronDown 16
- Card list `gap-[8px]` · Pagination: prev/next `p-[8px] rounded-[6px] bg-[rgba(255,255,255,0.05)] border …0.2` · page `size-[32px] rounded-[6px]` active `bg-[#58D68D]` · `10 / page` + ChevronDown
→ ทั้งหมด **ตรง `object-list-panel.tsx` เดิม — reuse as-is**

### 2.4 **Tree card** (component `5045:273291`, 336×96) — variant ใหม่ของ `object-card.tsx`

| Part | Tree card (Nature) | Object card เดิม |
|---|---|---|
| Container | `flex gap-[8px] items-start p-[8px] rounded-[8px] bg-[#2B3540] overflow-clip` | เท่ากัน |
| Selected | border 1px `#58D68D` (screenshot only — exact `ต้องดึง`) | — |
| Image | `size-[80px] rounded-[8px] border border-[rgba(255,255,255,0.2)]` + overlay `bg-[rgba(0,0,0,0.2)]` + `<img class="object-cover rounded-[8px] size-full">` **full-bleed** | `size-[80px] rounded-[6px] bg-[rgba(0,0,0,0.2)]` + image 40×40 กลางกล่อง |
| Context | `flex-1 flex-col justify-between self-stretch` → top `gap-[4px]` | `gap-[6px]` |
| Name | Body/Medium white (`Maple tree`, `Sakura tree`, `Canada maple tree`) | เท่ากัน |
| Meta row | **tree icon 14** `#8C99A6` + Caption 1 `#8C99A6` **`State : 4`** | LayoutGrid 12 + `Grid size : WxH` |
| Tint swatches | **ไม่มี** | มี |
| Bottom row | `justify-between` · **nature_type tag** `Shedding tree` (`px-[4px] py-[2px] rounded-[4px] gap-[4px]` bg/border `rgba(45,182,255,0.1)` text Caption 1 `#2DB6FF`) + Status tag | category tag + Status tag |
| Status tag | Eye 14 + `Active` `#58D68D` bg/border `rgba(88,214,141,0.1)` · EyeOff 14 + `Hidden` `#8C99A6` bg/border `rgba(140,153,166,0.1)` | เท่ากัน (`object-status-badge.tsx`) |

- Thumbnail ใน Figma เป็น **ภาพนิ่ง** (spec ขอ animated loop) — ดู §14
- `State : 4` = ตัวเลขเดี่ยว (จำนวน state ทั้งหมดของ nature_type) **ไม่ใช่** `uploaded/required` ตาม spec
- **Category tag `Nature`** (บน card ทั่วไปเช่น `Flower jar`): `#2C5AE4` Navy bg/border `rgba(44,90,228,0.1)` → เพิ่ม `TYPE_CONFIG.nature = "#2C5AE4"` ใน `object-type-badge.tsx` + `objectTypeBadgeNature = "Nature"`
- **nature_type tag** ใช้ Blue/500 `#2DB6FF` = **สีเดียวกับ furniture badge ใน code** (`TYPE_CONFIG.furniture = "#2DB6FF"`) → ต้องเป็น component แยก `NatureTypeBadge` (หรือ generalize `ObjectTypeBadge` รับ `color`/`label`) ไม่ใช่ใส่ใน TYPE_CONFIG เดียวกัน
- Tag ใน Figma border = colour **10%**, code เดิม `${color}33` (20%) และ `px-[6px] h-[19px] min-w-[50px] font-medium` — pre-existing drift ไม่แก้ในรอบนี้

### 2.5 Empty states (node `5008:246599` — screenshot only)

`0 object` · illustration 100×100 · `No objects added` Sub/Bold · `Add objects to boosts workspace with creativity.` Body/Regular grey · `+ Add object` primary h42 · detail panel `No object selected` / `Add an object to your workspace and it will appear here.` — ทุก string มีใน `en.json` แล้ว (`objectListPanelEmpty*`, `objectDetailEmpty*`) → **reuse as-is**

---

## 3. HP-02 · สร้าง Nature Object

Flow ใน Figma: `Nature - Creating` (ยังไม่เลือก Category) → Category dropdown → เลือก `Nature` → แถว `Nature type` + section `Upload stage & animation` โผล่ (`Nature - Fill`) → กด `+ Upload` เปิด modal §4 → Save

### 3.1 Detail panel — Creating (node `5167:330557`)

Panel `flex-col gap-[40px] p-[16px] rounded-[16px] bg-[#242B32]` (752 wide)

| Block | Spec |
|---|---|
| Title row | `Add object` H/Bold white · ปุ่มขวา `gap-[8px]`: **Preview** (ghost, `opacity-50` disabled) · **Cancel** `h-[42px] px-[16px] py-[8px] gap-[8px] rounded-[8px] bg-white` X 16 + `Cancel` Sub/Regular `#1A1B1E` · **Save disabled** `bg-[#DBDFE3] border border-[#B2BBC3]` Check 16 + `Save` Sub/Regular `#A3ADB8` |
| Property setting title | `Property setting` Sub/Medium white · `Configure object properties.` Body/Regular `#8C99A6` (block `h-[48px] gap-[8px]`) |
| Row 1 `gap-[16px]` | `Object name` input `h-[42px] px-[12px] py-[8px] rounded-[8px] bg-[#242B32] border border-[rgba(255,255,255,0.2)]` placeholder `Please enter object name` `#636D76` · counter ขวา `0` (12/15 semibold white) `/100` (Caption grey) · `Category` dropdown placeholder `Please select category` + ChevronDown 16 |
| Row 2 | `Z-index` + Info 16 (`gap-[8px]`) dropdown `Please select Z-index` · `Status` toggle 48×24 **ON** + `Active` Body/Regular `#58D68D` |
| ไม่มี | Nature type · Divider · Upload section · Collision · Object Composer |

Figma ใช้ Cancel/Save `h-[40px]` ในเฟรมนี้แต่ `h-[42px]` ในเฟรมอื่น → **ใช้ 42** ตาม code เดิม

### 3.2 Category dropdown (node `5167:331169`, 352×669)

Panel `flex-col p-[8px] rounded-[16px] bg-[#242B32] shadow-[…]` · item "Menu with description" `flex gap-[12px] items-start p-[12px] min-h-[42px] rounded-[8px]` · icon 16 · title Body/Regular white · description Caption 1 `#8C99A6`

| # | Title | Description (verbatim) |
|---|---|---|
| 1 | Furniture | Solid objects that block avatar movement, such as tables, shelves, or cabinets. |
| 2 | Sofa | Interactive seating objects that avatars can sit on, such as sofas, lounge chairs, or benches. |
| 3 | Decoration | Decorative objects that avatars can walk through, such as paintings or small plants. |
| 4 | Structure | Structural objects placed above avatars that block movement, such as walls, pillars or partitions. |
| 5 | Machine | Electronic and technology related objects used for decoration, such as computers, monitors, or office equipment. |
| 6 | **Nature** | **Animated nature objects that react to changing weather.** |
| 7 | Interactive Barrier | Define interactive areas that allow users to perform actions with an object, such as opening doors or triggering interactions. |
| 8 | Walkable group | Walkable objects or zones that avatars can move across freely, such as large rugs, paths(tile), or custom areas. |

- Figma ไม่มี `Wall` / `Foods & Drink` และลำดับต่างจาก `OBJECT_TYPES` เดิม · description ของตัวเดิมต่างจาก `en.json` เล็กน้อย → **ไม่แก้ของเดิม** เพิ่มแค่ `{ value: "nature", labelKey: "objectTypeNature", descriptionKey: "objectTypeNatureDescription" }` ใน `constants.ts` + `OBJECT_TYPE_ICONS.nature`
- icon "tree" ของ Nature → lucide `TreePine` (glyph Figma เป็นต้นสนเส้นเดี่ยว — ถ้าไม่ตรง flag custom SVG ใน `components/ui/icon.tsx`)
- `tw-dropdown.tsx` รองรับ `icon` + `description` อยู่แล้ว → **reuse**

### 3.3 Nature type dropdown (node `5167:331371`, 349×268)

Panel style = §2.2 · item `p-[12px] min-h-[42px] rounded-[8px]` Body/Regular white (ไม่มี icon/description)
Options ตามลำดับ: `Big tree` · `Pine tree` · `Bush` · `Shedding tree` · `Bamboo` · `Flower bush` — **6 ตัว ไม่มี `Custom`**

### 3.4 Detail panel — Fill (node `5167:331415`) — หลังเลือก Category = Nature

| Block | เปลี่ยนจาก §3.1 |
|---|---|
| Row 1 | `Object name` = `Maple tree` (white) counter `50` `/100` · `Category` = `Nature` (white) |
| **Row 2 ใหม่** | **`Nature type`** = `Shedding tree` ▾ (ซ้าย) · `Z-index` + Info = **`3 ` white + `(Middle Layer)` `#8C99A6`** ▾ (ขวา — **prefill อัตโนมัติ** ตาม PM sticky "Pre fill z-index หลังจากเลือก Category") |
| Row 3 | `Status` block `h-[68px] gap-[8px]` · toggle ON + `Active` |
| Divider | Line8 asset 1px (สี `ต้องดึง` คาด White 20%) |
| **Upload stage & animation** (ใหม่) | header `flex gap-[16px] items-center`: ซ้าย `flex-1 gap-[8px]` — `Upload stage & animation` Sub/Medium white + Info 16 · `Upload the stage images and animation assets.` Body/Regular grey · ขวา **Upload** `h-[42px] px-[16px] py-[8px] gap-[8px] rounded-[8px] bg-[#58D68D]` Plus 16 + `Upload` Sub/Regular white |
| Frame row `gap-[16px]` | `Frame count` dropdown value `50` · label `Frame rate ` white + `(fps)` `#8C99A6` dropdown value `24` — **ทั้งคู่ read-only style** (text `#7F8B97` + overlay `rgba(255,255,255,0.05)` + ChevronDown) ทุกเฟรม |
| Upload object area | `flex flex-1 gap-[16px] min-h-px overflow-clip` · **Object files** panel `w-[256px] p-[16px] gap-[8px] rounded-[8px] bg-[#2B3540]` title `Object files` Body/Medium + Info 16 · scrollbar thumb `absolute right-px top-[40px] w-[4px] h-[56px] rounded-[90px] bg-[rgba(255,255,255,0.2)]` · **Object Preview** `flex-1 h-[425px] rounded-[8px] bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)]` grid 40px |
| Save | **ยัง disabled** จนกว่าจะ upload ผ่าน modal (ดู §4 states) |

**Logic ที่ต้องเพิ่มใน `object-add-form.tsx`** เมื่อ `category === "nature"`: แสดง Nature type dropdown · `DEFAULT_Z_INDEX.nature = 3` · `deriveCollisionModeFromType("nature") = "walkable"` (ปัจจุบัน `constants.ts:90-100` ไม่มี nature → return blocked) · ซ่อน collision/hitbox UI · ซ่อน Object Composer · แสดง Upload section แทน · `MAX_NAME_LENGTH` 50 → **100** ตาม Figma `/100` + spec (กระทบทุก type — ดู §14)

---

## 4. HP-03 · Upload stage & animation modal (node `6034:345420` master)

**นี่คือ "Animation Manager" ของ spec** — เปิดจากปุ่ม `+ Upload` บนฟอร์มหลัก ไม่ใช่หน้าแยก

### 4.1 Layout tree (900×600 centered ที่ 270,221)

```
Upload stage & animation  900×600 · flex-col · gap 16 · p 16 · bg #242B32 · rounded 16 · backdrop-blur 4
├─ Title (row justify-between, 868×48)
│  ├─ Container (col gap 8) → "Upload stage & animation" Sub/Medium white
│  │                          "Upload and manage object placement for more accurate scene composition." Body/Regular #8C99A6
│  └─ Cancel 24×24 (X)
├─ Divider 1px (สี ต้องดึง — คาด White 20%)
├─ body (col gap 16 flex-1)
│  ├─ Tab group (row gap 8) → 4 × tab
│  └─ Upload object (row gap 16 flex-1)
│     ├─ LEFT (col gap 16, w 523)
│     │  ├─ Object Composser Preview 523×346  (grid canvas + zoom pill)
│     │  └─ row gap 16 → Position [X:][Y:] + Position [W:][H:]
│     └─ RIGHT (col gap 16, w 329, overflow-clip)
│        ├─ Alert banner (blue info)
│        └─ Upload file card (label + dropzone | file row)
└─ Footer (row justify-between) → Preview (ghost) | Cancel · Save
```

### 4.2 ค่าต่อ element

| Element | Spec |
|---|---|
| Tab ACTIVE | `flex h-[32px] items-center justify-center gap-[8px] p-[8px] rounded-[8px] bg-[rgba(88,214,141,0.2)]` label Body/Regular white |
| Tab inactive | box เดียวกัน **ไม่มี bg** · hover `ต้องดึง` |
| Count badge | `bg-[#1A1B1E] rounded-[90px] p-px` · Caption 2/Medium white `w-[16px] text-center` → ≈18×16 · ค่า = จำนวนไฟล์ใน state นั้น (**0 หรือ 1**) |
| Tabs (ลำดับ) | **`Idle` · `Sway light` · `Sway normal` · `Falling`** — ชุดเดียวทุกเฟรม (shedding_tree) · **ไม่มี Required/Optional marker ใดๆ** |
| Preview canvas | `w-[523px] flex-1 bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)] rounded-[8px] overflow-clip` · grid 1px pitch **40px** (`gap-[40px] px-[16px] py-[16px]`) สีเส้น `ต้องดึง` (SVG ≈ white 10–20%) |
| Zoom pill | `absolute bottom-[7px] right-[7px] h-[30px] flex items-center gap-[4px] px-[8px] py-[6px] rounded-[6px] bg-[#1A1B1E] border border-[rgba(255,255,255,0.2)]` → `100%` Body/Regular white `w-[38px]` · Minus 16 · track 80×8 (fill `#58D68D` + thumb white) · Plus 16 |
| Position pill ×2 | `flex-1 h-[30px] flex items-center gap-[16px] px-[8px] py-[6px] rounded-[6px] bg-[rgba(255,255,255,0.1)]` · label `X:`/`Y:` · `W:`/`H:` Body/Regular white · value `w-[60px] p-[4px]` Body/Regular `#8C99A6` = `0` ทุก state (ไม่อัปเดตใน design — `ต้องดึง` ความหมาย) |
| Alert banner | `w-full flex items-center gap-[8px] p-[8px] rounded-[8px] bg-[rgba(45,182,255,0.1)] border border-[rgba(45,182,255,0.2)]` · Info 16 `#2DB6FF` · **"Upload a PNG image only (max 2 MB, transparent background)."** Body/Regular `#2DB6FF` |
| Upload card | `w-full flex-col gap-[16px] p-[8px] rounded-[8px] bg-[#2B3540]` · label **`Idle spritesheet`** Body/Medium white (pattern `{state} spritesheet` — เห็นแค่ Idle) |
| Dropzone (No file) | `w-full flex-col items-center justify-center gap-[8px] px-[8px] py-[24px] rounded-[8px] bg-[rgba(255,255,255,0.05)] border border-dashed border-[rgba(255,255,255,0.2)]` · icon button `p-[8px] rounded-[6px] bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)]` 32×32 + Upload 16 white · text `Drag and drop file here or` `#8C99A6` + ` ` + `choose file` white **underline** |
| File row (uploaded) | card `w-full flex items-end justify-center p-[8px] rounded-[8px] bg-[rgba(255,255,255,0.05)]` (ไม่มี border) → inner `flex flex-1 items-center gap-[8px]` · icon box `size-[42px] p-[8px] rounded-[8px] bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)]` + Image 16 (**ไม่ใช่ thumbnail จริง**) · text `gap-[4px]`: `Maple.png` Body/Medium white · meta `gap-[4px]` Caption 12/16: `Size: 100 mb` `#8C99A6` · `•` · `Completed` **`#58D68D`** · Trash2 16 `#F03A3A` ชิดขวา |
| Footer Preview | `h-[32px] px-[16px] py-[8px] rounded-[6px] bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)]` `Preview` Body/Regular white |
| Footer Cancel | `h-[32px] px-[16px] py-[8px] rounded-[6px] bg-white` `Cancel` `#1A1B1E` |
| Footer Save | disabled `bg-[#DBDFE3] border border-[#B2BBC3] text-[#A3ADB8]` · enabled `bg-[#58D68D] text-white` |
| Overlay | rounded-rectangle full-viewport — สี `ต้องดึง` (code เดิม `rgba(0,0,0,0.6)` + `backdrop-blur-[2px]` หรือ `rgba(26,27,30,0.8)`) |

### 4.3 States ที่ออกแบบไว้

| State | Node | Tabs badge | ขวา | Canvas | Save |
|---|---|---|---|---|---|
| Empty | `6034:345420` | 0/0/0/0 (Idle active) | banner + dropzone | grid ว่าง | disabled |
| Idle uploaded | `6035:352007` (+`6037:504694`) | **1**/0/0/0 | banner + file row `Maple.png` | `Object/Maple/Front` 88×119 **ภาพนิ่ง 1 เฟรม** กลาง canvas | **enabled** |
| All uploaded | `6035:352894` | 1/1/1/1 | เดิม (Idle tab) | เดิม | enabled |

**ไม่ได้ออกแบบ:** tab อื่นที่ active · uploading/progress · drag-over · error ใน card · hover/focus · Required/Optional · placeholder เมื่อ canvas ว่าง · ชุด tab ของ nature_type อื่น (bush/flower_bush มี 2 state ตาม PM sticky)

### 4.4 ฟอร์มหลักหลัง Save modal (node `6035:489923`)

- `Object files` panel มี 1 แถว "Menu" (224×42): colour dot 16 (ส้ม) · **`Maple`** `#58D68D` (selected, `bg-[rgba(88,214,141,0.1)] rounded-[8px] p-[12px] min-h-[42px]`) · Trash2 16 `#F03A3A` · Pencil 16 white — **คือ variant-list row ของ `object-add-form.tsx` เดิม** ไม่ใช่ list ต่อ state
- `Object Preview` 448×425 = `ObjectPreviewCanvas` เดิม วาด Maple sprite + footprint cell 1×1 ไฮไลต์ + label `1×1` + hitbox toolbar (ตาม screenshot) — **รอบที่ 2: HP-03 AC ใหม่ "หลังบันทึกสามารถกำหนดสีและประเภทของ box object ได้" ยืนยันว่าโชว์ toolbar** แต่ขัด HP-02 "always walkable" → ดู §14.1 ข้อ 14a
- header Save เปลี่ยนเป็น enabled green
- **ไม่มี per-state thumbnail strip / ไม่มี "X/Y required states" / ไม่มี state badge บนฟอร์มหลัก**

### 4.5 Reuse — ประกอบจากของเดิม

| ชิ้น | ของเดิม | Action |
|---|---|---|
| Modal shell 900 / p-16 / gap-16 / title+desc+X / divider | `object-composer-preview-modal.tsx:413` (`w-[900px] … shadow-[0px_24px_48px_rgba(0,0,0,0.6)]`) | reuse pattern · X 24 (เดิม 14–16) · shadow Figma ไม่คืนค่า `ต้องดึง` |
| Tab strip + count badge | `object-composer-preview-modal.tsx:445-471` DIR_TABS (`h-[32px] rounded-[8px]` active `bg-[rgba(88,214,141,0.2)]` badge `rounded-[90px] bg-[#1A1B1E] p-px`) | **identical** → extract เป็น shared `components/admin/count-tab-strip.tsx` แล้วใช้ทั้ง 2 ที่ |
| Grid canvas | `object-preview-canvas.tsx` (`readOnly`, `hideHitboxTools`, `canvasZoom` wheel-zoom, `GRID_LINE_COLOR = rgba(61,80,104,0.6)`) | reuse + **เพิ่ม zoom pill UI** (ไม่มี) + **เล่น spritesheet แบบ horizontal strip loop** (ไม่มี — ปัจจุบันวาด piece นิ่ง) |
| Upload card (label + dropzone + file row) | `views/admin/pet-management/components/pet-upload-step.tsx` → `AnimationUploadCard` (private) | **extract → `components/admin/animation-upload-card.tsx`** แล้วปรับ: p-8 (Pet p-16), `border` 1px dashed `rounded-[8px] py-[24px]` (Pet `border-2 rounded-[16px] min-h-[180px]`), icon box 42 (Pet 48), meta Caption 12/16 |
| Client validation (type/size/dimension/width÷frames/transparency) | `views/admin/pet-management/pet-upload-validation.ts` (`validatePetUploadFile`, `readPetImageDimensions`, `detectPetSheetDust`) | **reuse + generalize** (limit 2 MB; ตัด 1000px cap) → ย้ายไป `lib/` |
| Blue info banner | red banner pattern ใน `object-add-form.tsx` (`gap-[8px] rounded-[8px] border p-[8px]` + icon 16) | reuse สลับสี Blue/10%–20% + `Info` |
| Footer buttons h-32 rounded-6 | dialogs เดิม | reuse + disabled Save `#DBDFE3/#B2BBC3/#A3ADB8` |
| i18n | `AdminShared`: `petUploadTitle` = **"Upload stage & animation"** ✓ ตรง · `petUploadDropPrompt` · `petUploadChooseFile` · `petUploadCompleted` · `petUploadFileSize` · `petUploading` · `petUploadFrameCount` = "Frame count" · `petUploadFrameRate` = "Frame rate (fps)" | reuse key กลางได้ (หรือ copy เป็น `nature*` ใน `AdminObjectManagement`) · **ต่าง:** `petUploadPngNotice` มี `{maxWidth} × {maxHeight}` แต่ Nature = "(max 2 MB, transparent background)" → key ใหม่ |

---

## 5. HP-04 · Animation Config — **ยังไม่มี design ที่กรอกได้**

สิ่งที่ Figma มี: dropdown `Frame count` (`50`) และ `Frame rate (fps)` (`24`) บน**ฟอร์มหลัก** (ระดับ object ไม่ใช่ต่อ state) สไตล์ read-only ทุกเฟรม + PM sticky ×3 "Case Frame count กับ Rate น่าจะอนาคต เพราะตอนนี้ยังไม่มีให้กรอก"
สิ่งที่ Figma **ไม่มี:** config panel ทางขวา · `wind_threshold_kmh` · `base_intensity_multiplier` · speed slider 0.25x–2.0x · "Reset to defaults" — ทุกอย่างใน spec HP-04
→ HP-04 ปิดใน ClickUp แล้ว (ผู้ใช้ยืนยัน) แต่ **ไม่มี UI ให้ implement** — ถ้าจะทำต้องมี Figma เพิ่ม หรือยอมรับว่ารอบแรก frame_count/frame_rate เป็นค่า derive/ค่า default ฝั่ง server (technical-design §5.2 รับ field จาก multipart อยู่ — ต้องตัดสินว่า client ส่งค่าอะไร)

---

## 6. HP-05 · Nature preview modal (node `5199:369528`)

> **✅ implement แล้ว 2026-09-22** — `views/admin/object-management/components/nature-preview-modal.tsx` ([zyra-app#432](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/432)) · เปิดจาก footer `Preview` ของ upload modal (ส่ง draft ของ modal เองมา เพราะไฟล์ที่เพิ่งเลือกยังไม่เข้า state ของฟอร์ม) และจากปุ่ม `Preview` บน header ทั้งโหมด create/edit และ view · zoom pill + grid 40px แยกไป `nature-canvas.tsx` ใช้ร่วมกับ HP-03

เปิดจาก (a) footer `Preview` ของ Upload modal (b) header `Preview` ของ Saved view · **read-only simulation** · shell เดียวกับ §4 (900×600, p-16, gap-16, blur 4)

| # | Element | Spec |
|---|---|---|
| 1 | Title | `Nature preview` Sub/Medium white · `Preview nature object across all stages and animations before publishing.` Body/Regular `#8C99A6` · X 24 |
| 2 | Divider | 868×1 **white 20%** (ตรวจ SVG แล้ว) |
| 3 | Canvas | 868×488 `bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)] rounded-[8px] overflow-clip` · grid white 20% 1px pitch 40 |
| 3b | Zoom pill | เหมือน §4.2 (fill 45/80 ≈ 56% ที่ "100%") |
| 4 | Anchor cell | 40×40 ที่ (430,360) `bg-[rgba(88,214,141,0.1)] border border-[rgba(88,214,141,0.2)]` (1 tile) |
| 5 | Sprite | PNG 119×160 ที่ (391,240) `rounded-[8px]` — **bottom-centre anchored บน tile** (ขอบล่าง y=400 = ขอบล่าง cell) |
| 6 | Weather dropdown trigger | 161×30 `absolute bottom-[24px] right-[210px]` · `bg-[#1A1B1E] border border-[rgba(255,255,255,0.2)] rounded-[8px] p-[8px] flex justify-between` · Weather icon 17×14 + label Body/Regular white · ChevronDown 16 |
| 6b | Dropdown panel (open, `5219:751880`) | 161×140 `bottom-[62px] right-[210px]` (**เปิดขึ้นบน** ห่าง trigger 8) · `bg-[#1A1B1E] border …0.2 rounded-[8px] p-[8px] flex-col gap-[8px]` · row 18px (icon 17×14 + label 14/18 white) → pitch 26 · options **`Clear` · `Cloudy` · `Rain` · `Strong rain` · `Thunderstorm`** · selected/hover **ไม่ได้วาด** `ต้องดึง` |
| 7 | Wind slider block | 260×50 `absolute left-[24px] bottom-[20px]` · `bg-[#1A1B1E] rounded-[8px] p-[8px]` (**ไม่มี border**) · inner col gap 8 (244 wide) |
| 7a | header | `justify-between items-end` · `Wind thresholds` Body/Regular white · value `9` **Body/Medium** white + ` km/h` Caption 1 `#8C99A6` |
| 7b | track | 244×8 `bg-[rgba(255,255,255,0.1)] rounded-[90px]` · fill `bg-[#58D68D] rounded-[90px]` anchored left · thumb ⌀16 **white** centre = fill end · สี fill **ไม่เปลี่ยนตาม state** |

Wind ทั้ง 6 เฟรม (track 244px):

| Weather | km/h | fill px | px/kmh |
|---|---|---|---|
| Clear | 9 | 23 | 2.56 |
| Cloudy | 10 | 30 | 3.0 |
| Cloudy | 19 | 48 | 2.53 |
| Rain | 29 | 93 | 3.2 |
| Strong rain | 49 | 131 | 2.67 |
| Thunderstorm | 80 | 215 | 2.69 |

→ ไม่ linear · ถ้า max = 100 แล้ว 80 km/h ควร = 195px (design 215) → **min/max/step `ต้องดึง`** (best-fit ≈ 0–90)
PM sticky: เลือก weather → slider กระโดดไป **ค่าเริ่มของ band นั้น** (Cloudy = 10) — แต่เฟรม Clear แสดง 9 ไม่ใช่ 0, Rain 29 ไม่ใช่ 30 (spec `sway_strong ≥30`) → ตาราง default `ต้องดึง`

Weather icons (Figma component "Weather" เป็น **ภาพประกอบมีสี**: sun gradient `#FFEF9A`, cloud raster, bolt `#FFED8D`) ↔ rule 12 lucide-only:

| Option | lucide candidate |
|---|---|
| Clear | `Sun` |
| Cloudy | `CloudSun` |
| Rain | `CloudRain` |
| Strong rain | `CloudRainWind` |
| Thunderstorm | `CloudLightning` |

→ ต้องเลือก: lucide monochrome (fidelity ตก) หรือ export 5 SVG ลง `components/ui/icon.tsx` (ข้อยกเว้นที่อนุญาต) — `ต้องดึง` มติ designer

**Canvas เหมือนกันทุก weather** (Clear = Thunderstorm) — ไม่มี rain overlay / tint / floor tile · sprite เป็น PNG นิ่ง ไม่ใช่เฟรม spritesheet

### 6.1 Reuse

| ชิ้น | ของเดิม | Action |
|---|---|---|
| Shell | `object-composer-preview-modal.tsx` (props `composition, initialDir?, category?, onClose, onBackToEdit` — ไม่มี nature) | extract shell → `NaturePreviewModal` หรือเพิ่ม branch |
| Canvas | `ObjectPreviewCanvas` `readOnly hideHitboxTools` | reuse + zoom pill + spritesheet playback (เหมือน §4.5) |
| Weather dropdown | `TwDropdown` (trigger `#242b32 h-42`, panel `rounded-16 #242b32 shadow` เปิดลง, มี Check บน selected) | **เพิ่ม props** `size="compact"` (h-30 w-161 `#1A1B1E` rounded-8) · `placement="top"` · ปิด Check — ห้าม fork |
| Wind slider | — | **new** `<input type="range">` styled หรือ custom div + pointer events (rule 08) |
| Zoom pill | — | **new** sub-component ใน canvas |

---

## 7. HP-06 · Saved / Complete detail view

### 7.1 Saved — view mode (node `5219:760257` master)

Panel `flex-col gap-[40px] p-[16px] rounded-[16px] bg-[#242B32]` 752 wide

| Block | Spec |
|---|---|
| Header | title **`Add object`** H/Bold (Figma คงชื่อนี้ในหน้า view — code เดิมโชว์ `object.name`; `ต้องดึง` มติ) · ปุ่ม `gap-[8px]`: **Preview** ghost `bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)] rounded-[8px] h-[42px] px-[16px] py-[8px]` Sub/Regular white · **Edit** `bg-[#58D68D] rounded-[8px] h-[42px]` Pencil 16 + `Edit` white · **ไม่มี Delete** |
| Read-only field | input `h-[42px] rounded-[8px] border border-[rgba(255,255,255,0.2)] px-[12px] py-[8px]` bg `#242B32` + overlay `rgba(255,255,255,0.05)` · text **`#7F8B97`** · ChevronDown 16 · **ไม่มี lock icon / tooltip** |
| Row 1 | `Object name` = `Canada maple tree` + counter `50` `/100` · `Category` = `Nature` |
| Row 2 | `Nature type` = `Shedding tree` · `Z-index` + Info = `3 (Middle Layer)` (ทั้งก้อนเทา) |
| Row 3 | `Status` · toggle 48×24 variant **True / Disabled** + `Active` `#58D68D` |
| Divider | 720×1 white 20% |
| Upload section | title/subtitle เหมือน §3.4 · **Upload disabled** `bg-[#DBDFE3] border border-[#B2BBC3] text-[#A3ADB8]` · `Frame count` `50` / `Frame rate (fps)` `24` เทา |
| Object files | 256×420 · 1 แถว `Maple` selected (`rgba(88,214,141,0.1)`) + Trash2 + Pencil · (มี hidden rows อีก 5 = รองรับหลายไฟล์) |
| Object Preview | 448×425 `p-[24px]` grid 40 · red cell 16×16 `rgba(240,58,58,0.2)` (hitbox marker) · label `1×1` (screenshot only `ต้องดึง`) |

**ไม่มีใน design:** per-state list พร้อม Replace · "used in N workspaces" · version/hot-reload info · audit log · **เฟรม edit-mode หลังกด Edit** (จึงไม่รู้ว่า lock nature_type แสดงยังไงเมื่อ field อื่น enable)

### 7.2 Complete — create/edit mode ครบแล้ว (node `5185:340707` master)

ต่างจาก §7.1:

| Area | Complete |
|---|---|
| Header | **Delete** (red ghost `bg-[rgba(240,58,58,0.05)] border border-[rgba(240,58,58,0.2)]` Trash2 + `Delete` `#F03A3A` — **opacity-0 แต่กินพื้นที่ 105px**) · **Cancel** (bg white, X 16, `#1A1B1E`) · **Save** (`#58D68D`, Check 16) — **h-40** |
| Fields | enabled `bg-[#242B32]` text white · `Nature type` **enabled** (create mode — lock เฉพาะหลัง save ตาม PM "Nature type แก้ไขไม่ได้") · Z-index `3 ` white + `(Middle Layer)` grey (= `objectZIndexLayer3Sublabel` เดิม) |
| Status | toggle True / **Default** (enabled) |
| Upload | **enabled** green · Frame count/rate **ยังเทา** |
| Object Preview | box เดียว `h-[425px]` ไม่มี inner padding |

### 7.3 Toast (node `5219:761371`) — `Saved object successfully` (ไม่มีจุด) — ตำแหน่ง top 16 / right 16 · spec เหมือน §9 success · key เดิม `heroEditorObjectSavedSuccess` = "Object saved successfully." **ต่างคำ** → key ใหม่

### 7.4 Reuse

`object-detail-panel.tsx` + `object-detail-content.tsx` (header h2 20 bold `object.name` + Delete/Edit h-40) + `object-add-form.tsx readOnly` → เพิ่มปุ่ม **Preview** · read-only style เดิม `opacity-70` → เปลี่ยนเป็น `text-[#7F8B97]` + overlay 5% ตาม Figma · switch เดิม 40×22 (`#58D68D` / `#636D76`) ↔ Figma 48×24 (OFF track `#CAD0D6` `ต้องดึง`) · Delete visibility ใน edit mode `ต้องดึง`

---

## 8. HP-07 · Hide / Delete

### 8.1 Hide = Status switch + Save (nodes `5228:764179` → `5228:765855` → `5219:761387`)

- ไม่มีปุ่ม/เมนู Hide แยก · ไม่มี confirm · toast = `Saved object successfully`
- Switch 48×24: ON track `#58D68D` knob white + `Active` `#58D68D` · OFF track Grey/200 `#CAD0D6` (`ต้องดึง`) + `Hidden` `#8C99A6`
- หลัง Save: detail กลับ view mode · `+ Upload` disabled · card badge EyeOff + `Hidden` (สี `ต้องดึง` card Hidden ไม่ได้ pull ตรง)
- code เดิมมี inline amber warning `objectFormHiddenUsageWarning` ใต้ switch เมื่อ `map_count > 0` — **Figma ไม่มี** (มี Alert banner slot hidden=true "Label" บน Property setting `ต้องดึง` จุดประสงค์)
- **ไม่พบ "(Hidden)" badge บน placed object ใน Map Editor** ทั้ง Figma และ code

### 8.2 Delete modals (General modal 458 wide)

Shell ทุกตัว: `flex-col gap-[24px] p-[16px] rounded-[16px] bg-[#242B32] backdrop-blur-[4px]` · title row `justify-between` Sub/Medium white + X 24 · divider 1px (`ต้องดึง` คาด White 20%) · footer `justify-between`: ซ้าย ghost (`h-[32px] px-[16px] py-[8px] rounded-[6px] bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)]` white) · ขวา `gap-[8px]` Cancel (`bg-white text-[#1A1B1E]`) + Delete (`bg-[#F03A3A] text-white`) ทุกปุ่ม h-32 rounded-6 Body/Regular

| Node | ขนาด | เนื้อหา |
|---|---|---|
| `5228:767857` general | 458×188 | `Delete object?` · body `#8C99A6` **"This action will permanently remove the object from Object Management and cannot be undone."** · ghost ซ้าย opacity-0 |
| `5228:769279` used | 458×206 | body `#8C99A6` ทั้งประโยค (**ตัวเลขไม่ bold**): **"This object is currently used in 5 workspaces and 10 maps. Deleting it may affect existing maps, layouts, and user experiences."** · ghost ซ้าย **`View all`** visible |
| `5228:769300` = `6037:504703` confirm empty | 458×220 | label Body/Regular white **`Confirm delete “Maple tree”`** · input `h-[42px] px-[12px] py-[8px] rounded-[8px] bg-[#242B32] border border-[rgba(255,255,255,0.2)]` placeholder `#636D76` **`Enter “Maple tree” to delete this object`** · footer `justify-end` · Delete **disabled** `#DBDFE3/#B2BBC3/#A3ADB8` |
| `5228:769304` = `6037:504707` confirm filled | 458×220 | value white `Comfortable sofa` (ตัวอย่างไม่ตรงชื่อแต่ Delete enabled → placeholder ของ designer; code บังคับ exact-match) · Delete enabled red |

**Confirm-name modal ปรากฏทั้ง 2 เงื่อนไข** (general ก็ต้องพิมพ์ชื่อ) = ตรง code เดิม (`goToConfirm` จาก `simple`) **ขัด spec** (spec: เฉพาะ `placed_objects_count > 0`)

### 8.3 Side panel "Affected Workspaces & Maps" (node `5228:769283`, 384×1086 ชิดขวา)

| Element | Spec |
|---|---|
| Panel | `flex-col gap-[24px] p-[16px] bg-[#242B32]` · shadow White shadow (MCP แปล `drop-shadow-[0px_4px_8px_rgba(255,255,255,0.08)]`) · **ไม่มี Back / ไม่มี X** |
| Header | `Affected Workspaces & Maps` Sub/Medium white · `View where this object is currently being used.` Body/Regular `#8C99A6` (`gap-[8px]`) |
| Alert banner 352×34 | `flex items-center justify-center gap-[8px] p-[8px] rounded-[8px] bg-[rgba(45,182,255,0.1)] border border-[rgba(45,182,255,0.2)]` Info 16 + **`Used in 5 workspaces • 10 maps affected`** `#2DB6FF` |
| List | `flex-col gap-[8px] flex-1 min-h-0` (scroll) |
| Card expanded 352×96 | `flex-col gap-[16px] px-[8px] py-[12px] rounded-[8px] bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)]` · header `justify-between`: `Stardust` **Body/Bold** white · ขวา `gap-[4px]` Caption 1 `#8C99A6` `Used in ` + **`2 ` Medium white** + `maps` · ChevronDown 16 · body `<ul>` `list-disc ms-[18px]` Caption 1 `#8C99A6`: `School map`, `Park map` |
| Card collapsed 352×42 | header เท่านั้น · chevron หมุนหรือไม่ `ต้องดึง` |
| Footer | `gap-[8px] justify-end` ปุ่ม 2 อัน `flex-[1_0_0]` 172×32: Cancel (white) · Delete (red) |

**Reuse:** `delete-object-dialog.tsx` มีครบแล้ว — `simple` / `warning` / `ConfirmNameModal` / `AffectedWorkspacesPanel` / `AffectedWorkspaceCard` — ต้องแก้: (1) `warning` body ตัวเลขเป็น `<strong>` white → Figma เทาทั้งประโยค (2) `deleteObjectConfirmDeleteLabel` "Confirm delete" → `Confirm delete “{name}”` (3) placeholder ใช้ “ ” โค้ง (4) panel ลบ Back+X ตาม Figma → ต้องมีทางปิดอื่น (overlay/Cancel) (5) shadow `0 4px 8px` (code 16px) · usage data = `getObjectUsage` → `ObjectUsageData{workspace_count, map_count, workspaces[{id,name,maps[]}]}` ครบ · **ไม่มี `placed_objects_count`** ทั้ง FE/API

### 8.4 Toasts

| Node | ข้อความ verbatim | code เดิม |
|---|---|---|
| `5228:768463` | **`Deleted object successfully.`** (มีจุด) | `deleteObjectSuccessToast` = "Object deleted." → เปลี่ยน |
| `5219:761389` | **`Saved object successfully`** (ไม่มีจุด) | `objectFormSaveSuccess` = "Object saved successfully." → เปลี่ยน |

---

## 9. EP-01 · Error toasts (336 wide, top 16 / right 16)

Shared: `bg-[#1A1B1E] rounded-[16px] p-[16px] drop-shadow-[0_4px_8px_rgba(255,255,255,0.08)]` · row `gap-[16px] items-start` · icon box `w-[40px] p-[8px] rounded-[8px]` **error** `bg-[rgba(240,58,58,0.2)]` + X **24** `#F03A3A` / **success** `bg-[rgba(88,214,141,0.2)]` + Check 24 `#58D68D` · text `gap-[8px]`: title **Body/Bold** white · body Body/Regular white · dismiss X 16 ขวา

| Node | H | Title | Body (EN verbatim) | Spec (TH) | ตรง? |
|---|---|---|---|---|---|
| `5230:784624` | 76 | Upload failed | Only PNG files are supported. | รองรับเฉพาะ PNG | ✅ |
| `5230:784627` | 94 | Upload failed | The file must be 2 MB or smaller. | ขนาดไฟล์เกิน 2 MB (ไฟล์ของคุณ: X.X MB) | ⚠️ ไม่มี actual size |
| `5230:787955` | 94 | Invalid PNG image | The uploaded PNG must include a transparent background. | **warning เหลือง ไม่บล็อก** | ❌ design = **error แดง บล็อก** |
| `5230:790027` | 94 | Invalid frame count | Frame count must be between 1 and 64. | 1–64 | ✅ (PM: อนาคต) |
| `5230:791907` | 94 | Invalid frame rate | Frame rate must be between 4 and 24 FPS. | 4–24 | ✅ (PM: อนาคต) |
| `5230:791921` | 112 | Invalid sprite sheet width | The image width (960 px) must be evenly divisible by the frame count (7). | + "frame width = {W/N}px" | ⚠️ ไม่มี suffix |

- **ไม่มี field-level error** บนฟอร์ม/modal (`5230:784622`): ไม่มี red border / helper text — toast อย่างเดียว · modal ปิดอยู่ในเฟรม error (`ต้องดึง` ว่า validate ใน modal แล้วค้างเปิดไหม — Pet precedent ค้างเปิด + inline error)
- **Reuse:** `zyraToast.errorWithTitle(title, message)` (`lib/toast.tsx:120`) ตรง variant · ต่างเล็กน้อย: glyph 20→24, gap 4→8, `items-center`→`items-start` (ตัดสินว่าแก้ shared component หรือปล่อย) · i18n pattern ตาม `petUploadValidation<CODE>` keyed ด้วย backend error `code` (single source of truth client+server ตาม `AGENTS.md`)

---

## 10. EC-01 · Replace spritesheet modal (node `6037:509126`)

Flow: Saved → Edit → `+ Upload` → Upload modal (มี `Maple.png • Completed` ทุก tab) → **`Replace spritesheet?` modal ทับ** → OS picker → Upload modal เดิม (เฟรมก่อน/หลัง replace **byte-identical** — ไม่ได้วาด state หลัง replace)

| หมวด | ค่า |
|---|---|
| Shell | = §8.2 General modal 458×188 ที่ (491,425) ทับ Upload modal + Overlay (`ต้องดึง` สี) |
| Title | `Replace spritesheet?` |
| Body | Body/Regular: span แรก **white** `{objectName} ` + span ที่เหลือ `#8C99A6` **`is used in {workspaceCount} workspaces and {mapCount} maps. Replacing it will update the object everywhere it’s used.`** |
| Footer | ghost ซ้าย opacity-0 · Cancel (white) · **Replace** `bg-[#58D68D] text-white` h-32 rounded-6 |

- ยืนยัน **ก่อน** เลือกไฟล์ (ตามลำดับเฟรม) · trigger จริง (Trash บน file row? เลือกไฟล์ทับ?) `ต้องดึง` — Figma ไม่มี interaction
- ไม่มี "ทันที"/30 วินาที/version/cache-bust ใน UI · code เดิม cache-bust ด้วย `thumbSrc(url, updated_at)` → `?t=<ms>` (`lib/utils.ts`) ไม่ใช่ `?v=` (technical-design §5.4 ใช้ helper เดิมอยู่แล้ว ✓)
- **Reuse:** shell จาก `delete-object-dialog.tsx` (`ModalHeader` 458/p-16/gap-24) — **ไม่ใช่** `save-object-dialog.tsx`/`leave-page-dialog.tsx` (420 · p-24 · shadow ต่าง) → **new `replace-spritesheet-dialog.tsx`** · data จาก `getObjectUsage`

---

## 11. Icon → lucide (รวมทุกหน้า)

| Figma | ขนาด | lucide | หมายเหตุ |
|---|---|---|---|
| Plus | 16 | `Plus` | |
| Search | 16 | `Search` | |
| Filter (3 เส้น) | 16 | `ListFilter` | code เดิม `AdminFilterMenu` ใช้ `SlidersHorizontal` (pre-existing) |
| Cheron-Down/Up/Left/Right | 16 (Up 14) | `ChevronDown/Up/Left/Right` | |
| More menu (2×2) | 14 | `LayoutGrid` | code เดิม |
| eye-on / eye-off | 14 | `Eye` / `EyeOff` | code เดิม |
| **tree** (Tree card meta, Nature category) | 14 / 16 | `TreePine` (candidate) | glyph Figma = ต้นสนเส้นเดี่ยว — ถ้าไม่ตรง → custom SVG ใน `components/ui/icon.tsx` `ต้องดึง` asset `5045:273299` |
| Info | 16 | `Info` | ใช้ `components/tooltip.tsx` `InfoTooltip` |
| Trash | 16 | `Trash2` | สี `#F03A3A` |
| Edit | 16 | `Pencil` | |
| Cancel (Close, component 2:1087) | 24 modal / 16 toast | `X` | |
| Check | 16 button / 24 toast | `Check` | |
| Upload (dropzone) | 16 | `Upload` | |
| Image (file row) | 16 | `Image` | Pet ใช้ `FileImage` 20 — เลือกอันเดียว |
| Minus / Plus (zoom) | 16 | `Minus` / `Plus` | |
| PanelLeftClose | 16 | `PanelLeftClose` | sidebar เดิม |
| Weather ×5 | 17×14 | `Sun` / `CloudSun` / `CloudRain` / `CloudRainWind` / `CloudLightning` | **มีสีใน Figma** — ดู §6 |
| Category icons เดิม | 16 | `OBJECT_TYPE_ICONS` (`Armchair, Sparkles, Building2, Sofa, Footprints, DoorOpen, BrickWall, Monitor, UtensilsCrossed`) | เพิ่ม `nature: TreePine` |
| CheckBox / RadioButton | 16 | custom `<span>` (existing `AdminFilterMenu`) | radio variant ยังไม่มี |
| Toggle 48×24 | — | custom `<button>` (pattern เดิม) | |

---

## 12. i18n — English strings ใหม่ (verbatim จาก Figma = source of truth) → `messages/en.json` namespace `AdminObjectManagement` (+ th.json คู่กัน — **ไทยยังไม่มีใน design ทุกตัว ต้องเขียนกับ PM**)

| Key (เสนอ) | EN |
|---|---|
| objectTypeNature · objectTypeNatureDescription | Nature · Animated nature objects that react to changing weather. |
| objectTypeBadgeNature · objectFilterTypeNature | Nature · Nature |
| objectNatureTypeLabel | Nature type |
| natureTypeBigTree / PineTree / Bush / SheddingTree / Bamboo / FlowerBush | Big tree · Pine tree · Bush · Shedding tree · Bamboo · Flower bush |
| objectCardStateCount | State : {count} |
| natureUploadSectionTitle · natureUploadSectionSubtitle | Upload stage & animation · Upload the stage images and animation assets. |
| natureUploadButton | Upload |
| natureFrameCount · natureFrameRate | Frame count · Frame rate (fps)  *(หรือ reuse `AdminShared.petUploadFrameCount/Rate`)* |
| natureUploadModalTitle · natureUploadModalSubtitle | Upload stage & animation · Upload and manage object placement for more accurate scene composition. |
| natureStateIdle / SwayLight / SwayNormal / Falling | Idle · Sway light · Sway normal · Falling |
| natureUploadPngNotice | Upload a PNG image only (max 2 MB, transparent background). |
| natureUploadSlotLabel | {state} spritesheet |
| naturePositionX/Y/W/H | X: · Y: · W: · H: |
| naturePreviewTitle · naturePreviewSubtitle | Nature preview · Preview nature object across all stages and animations before publishing. |
| natureWindThresholds · natureWindUnit | Wind thresholds · km/h |
| natureWeatherClear / Cloudy / Rain / StrongRain / Thunderstorm | Clear · Cloudy · Rain · Strong rain · Thunderstorm |
| objectSavedToast | Saved object successfully |
| deleteObjectSuccessToast (แก้) | Deleted object successfully. |
| deleteObjectConfirmDeleteLabel (แก้) | Confirm delete “{name}” |
| deleteObjectConfirmPlaceholder (แก้เครื่องหมาย) | Enter “{name}” to delete this object |
| replaceSpritesheetTitle · replaceSpritesheetBody · replaceSpritesheetConfirm | Replace spritesheet? · {objectName} is used in {workspaceCount} workspaces and {mapCount} maps. Replacing it will update the object everywhere it’s used. · Replace |
| natureUploadErrorPngTitle/Body | Upload failed · Only PNG files are supported. |
| natureUploadErrorSizeTitle/Body | Upload failed · The file must be 2 MB or smaller. |
| natureUploadErrorTransparencyTitle/Body | Invalid PNG image · The uploaded PNG must include a transparent background. |
| natureUploadErrorFrameCountTitle/Body | Invalid frame count · Frame count must be between 1 and 64. |
| natureUploadErrorFrameRateTitle/Body | Invalid frame rate · Frame rate must be between 4 and 24 FPS. |
| natureUploadErrorWidthTitle/Body | Invalid sprite sheet width · The image width ({width} px) must be evenly divisible by the frame count ({frameCount}). |

มีอยู่แล้วและตรง Figma (reuse): `deleteObjectDialogTitle` · `deleteObjectSimpleWarning` · `deleteObjectWarningBody` (ข้อความตรง — แค่ตัด `<strong>`) · `deleteObjectViewAllButton` · `deleteObjectAffectedWorkspacesTitle/Subtitle` · `deleteObjectUsageSummary` · `deleteObjectUsedInMaps` · `objectFormStatusActive/Hidden` · `objectZIndexLayer3Sublabel` = "(Middle Layer)" · `objectListPanelEmpty*` · `objectDetailEmpty*` · `AdminShared.petUpload*` (§4.5)

---

## 13. Reuse map รวม (ไฟล์ → ต้องทำอะไร)

| ไฟล์ | Action |
|---|---|
| `lib/api/objects.ts` | เพิ่ม `"nature"` ใน `ObjectType` · type `NatureType` (6 ค่า + `custom` ถ้า PM ยืนยัน) · `AnimationState` · `ObjectAnimation` · `NATURE_REQUIRED_STATES` (ตาม technical-design §4 — **แต่ Figma บอก required = idle เท่านั้น** ดู §14) · ฟังก์ชัน `listObjectAnimations`, `upsertObjectAnimation` |
| `views/admin/object-management/constants.ts` | `OBJECT_TYPES` + nature · `DEFAULT_Z_INDEX.nature = 3` · `deriveCollisionModeFromType`: nature → `"walkable"` · `MAX_NAME_LENGTH` 50 → 100 (ยืนยันก่อน) |
| `components/object-add-form-constants.ts` | `OBJECT_TYPE_ICONS.nature = TreePine` |
| `components/object-filter-menu.tsx` | `TYPE_OPTIONS` + `{ value: "nature", labelKey: "objectFilterTypeNature" }` |
| `components/object-type-badge.tsx` | `TYPE_CONFIG.nature = "#2C5AE4"` (Navy) · **ใหม่** `nature-type-badge.tsx` (Blue `#2DB6FF`, 6 labels) หรือ generalize รับ `color`/`label` |
| `components/object-card.tsx` | variant `type === "nature"`: thumb full-bleed 80 + border · แถว `State : N` (TreePine 14) · `NatureTypeBadge` แทน `ObjectTypeBadge` · ซ่อน grid size + swatches · `justify-between` |
| `components/object-add-form.tsx` | condition `category === "nature"`: Nature type dropdown · prefill z-index 3 · ซ่อน collision/composer · แสดง **`nature-stage-upload-section.tsx`** (ใหม่: header + Upload btn + Frame count/rate dropdown + Object files + `ObjectPreviewCanvas`) · read-only style `text-[#7F8B97]` + overlay 5% · switch 48×24 · lock nature_type หลัง save |
| `components/object-detail-content.tsx` | เพิ่มปุ่ม **Preview** (ghost h-42) · Delete visibility ตาม `ต้องดึง` |
| **ใหม่** `components/nature-upload-modal.tsx` | §4 — ประกอบจาก: shell (`object-composer-preview-modal` pattern) + `count-tab-strip` (extract จาก DIR_TABS) + `ObjectPreviewCanvas` + zoom pill (ใหม่) + `animation-upload-card` (extract จาก Pet) + blue banner + footer |
| **ใหม่** `components/nature-preview-modal.tsx` | §6 — shell + `ObjectPreviewCanvas readOnly hideHitboxTools` + zoom pill + `TwDropdown` compact/top + wind slider (ใหม่) |
| **ใหม่** `components/replace-spritesheet-dialog.tsx` | §10 — shell จาก `delete-object-dialog.tsx` |
| **ใหม่ (shared)** `components/admin/count-tab-strip.tsx` · `components/admin/animation-upload-card.tsx` | extract จาก `object-composer-preview-modal.tsx:445-471` และ `pet-management/components/pet-upload-step.tsx` แล้วให้ทั้ง Pet/Object ใช้ร่วม (rule 09: ย้ายก่อน ห้าม copy) |
| `views/admin/pet-management/pet-upload-validation.ts` → `lib/spritesheet-validation.ts` | generalize (limit 2 MB, ตัด 1000px cap, param frame_count) |
| `components/delete-object-dialog.tsx` | แก้ copy 3 จุด + ลบ Back/X ใน panel + shadow (§8.3) |
| `lib/toast.tsx` | (optional) glyph 24 / gap 8 / items-start ให้ตรง Figma |
| `messages/en.json` · `th.json` | §12 |
| `components/ui/icon.tsx` | เฉพาะถ้ามติเลือก custom SVG (tree / weather ×5) |

---

## 14. จุดที่ design ขัดกับ spec — ต้องเคลียร์ก่อน implement

### 14.1 ต้องตัดสินก่อนเริ่มโค้ด (กระทบ schema / API / flow)

| # | เรื่อง | Spec (ClickUp) | Figma | กระทบ |
|---|---|---|---|---|
| ~~1~~ | ~~**Required states**~~ | 3 state ต่อ type | **Idle เท่านั้น** | **✅ ปิดแล้ว 2026-09-20** — **required = `idle` ตัวเดียวทุก type** · state ที่ยังไม่มีไฟล์ให้ **fallback ไป `idle`** ตอน render (ทั้ง preview และ VO จริง ไม่ใช่แค่ preview) → `NatureRequiredStates` map ถูกยุบเหลือ constant เดียว ดู [technical-design §4](technical-design.md#4-animation-states--required--optional--fallback-ตัดสินแล้ว-2026-09-20) |
| ~~2~~ | ~~**ชื่อ state ที่ 3**~~ | `sway_strong` | `Sway normal` | **✅ ปิดแล้ว 2026-09-20** — **แยก key กับ label**: DB/S3/API ใช้ `sway_strong` · UI โชว์ `Sway normal` ผ่าน i18n `natureAnimStateSwayStrong` · **มี 4 state ไม่ใช่ 5** (sway_normal ไม่ใช่ state ใหม่) |
| ~~3~~ | ~~**frame_count / frame_rate**~~ | กรอกต่อ state | dropdown read-only ระดับ object | **✅ ปิดแล้ว 2026-09-20** — **ไม่ต้องมีเลยทั้ง field และ dropdown** ตัดออกจากฟอร์มด้วย · คอลัมน์ใน DB มี DEFAULT (`frame_count=1` `frame_rate=12`) client ไม่ส่งค่ามา · ภาพนิ่ง interim = `frame_count 1` พอดี |
| ~~4~~ | ~~**HP-04 ทั้ง scenario**~~ | config panel: wind_threshold_kmh, base_intensity_multiplier, speed slider, Reset | **ไม่มี UI เลย** | **✅ ปิดแล้ว (รอบที่ 2)** — PM ถอด HP-04 ออกจากตาราง Subtasks ของ main task = descoped · ไม่ต้องทำ UI · schema field ใน technical-design คงไว้ได้เป็น server default |
| ~~5~~ | ~~**Nature menu / entry point**~~ | menu "Nature" ข้างเมนูอื่น | เป็น category ที่ 10 ใน Object Management | **✅ ปิดแล้ว 2026-09-22** — ทำตาม Figma: ไม่มี route/tab/sidebar item ใหม่เลย · Nature เป็น option ใน Category dropdown + checkbox ใน Filter + badge บน card · list ใช้ `GET /api/admin/objects` เดิม ไม่ต้องมี query ใหม่ |
| 6 | **"บันทึกและตั้งค่า Animation" + redirect** | ปุ่มนี้ redirect ไป Animation Manager | ไม่มี — inline section + modal | **✅ ปิดบางส่วน (รอบที่ 2)** — HP-03 AC ใหม่ "กดปุ่ม Upload แล้วแสดง Modal" + HP-05 "Preview บนหน้า Upload แล้วแสดง popup" = ตรง Figma · **HP-02 ยังเขียน "redirect ไป Animation Manager" / ปุ่ม "บันทึกและตั้งค่า Animation" อยู่ (stale)** → ขอ PM แก้ HP-02 ให้สอดคล้อง · ไม่มี route `/animations` ฝั่ง FE |
| ~~7~~ | ~~**`custom` nature_type**~~ | 7 ตัวรวม custom | 6 ตัว | **✅ ปิดแล้ว 2026-09-20** — **ไม่มี `custom`** เหลือ 6 ตัวตาม Figma → `state` เป็นชุดปิด 4 ค่า ใส่ DB `CHECK` ได้ · ตัด regex slug `^[a-z][a-z0-9_]{1,29}$` ทิ้ง |
| ~~8~~ | ~~**Status default**~~ | Hidden + gate ที่ toggle | Active + gate ที่ Save | **✅ ปิดแล้ว 2026-09-20** — **กันสองชั้น**: server reject `status=active` เมื่อยังไม่มี `idle` (บังคับ) + client disable ปุ่ม Save (UX) · toggle ปล่อยอิสระ ดู [technical-design §6.1](technical-design.md#61-active-gating--กันสองชั้น) |
| ~~9~~ | ~~**Delete: พิมพ์ชื่อยืนยัน**~~ | เฉพาะ `placed_objects_count > 0` | **ทั้ง 2 เงื่อนไข** (= code เดิม) | **✅ ปิดแล้ว 2026-09-22** — ไม่ต้องแก้โค้ด: `delete-object-dialog.tsx` เดิมบังคับพิมพ์ชื่อทั้ง 2 เงื่อนไขอยู่แล้ว = ตรง Figma · **spec ใน ClickUp ยังเขียนผิดอยู่** → ขอ PM แก้ |
| ~~10~~ | ~~**Transparency check**~~ | warning เหลือง ไม่บล็อก | **error แดง บล็อก** | **✅ ปิดแล้ว 2026-09-22** — ทำตาม Figma (บล็อก) ทั้งสองฝั่ง: client `validateNatureUploadFile` → `NO_TRANSPARENCY` + toast `natureUploadErrorTransparency*` · server `readAndValidateNatureSprite` reject เหมือนกัน |
| ~~11~~ | ~~**Preview controls**~~ | state buttons · Current State label + reason · playback pause/step/speed 0.25x–2x · wind 0–100 | **ไม่มีเลย** — weather dropdown 5 ตัว + wind slider + zoom | **✅ implement ตาม Figma แล้ว 2026-09-22** (`nature-preview-modal.tsx`) — **ไม่ทำ** state buttons / Current State label / playback controls เพราะไม่มีในเฟรมใดเลย · ทำ weather dropdown 5 ตัว + wind slider + zoom pill · **idle fallback ทำแล้ว** (`resolveNaturePreviewState`) · ⚠️ **AC 3 ข้อใน ClickUp ยังค้างอยู่** → ขอ PM ลบ ไม่งั้น QA จะ fail ตาม AC ที่ design ไม่มี |
| 12 | **Weather 5 vs 4 + mapping** | Clear/Cloudy/Rain/Storm | Clear/Cloudy/Rain/**Strong rain**/**Thunderstorm** | **⚠️ implement ด้วยสมมติฐาน รอ PM ยืนยัน** — 3 ตัวแรกใช้ mapping ของ PM ตรง ๆ (Clear→idle, Cloudy→sway_light, Rain→sway_strong) · **Strong rain / Thunderstorm ไม่เคยมี mapping** → ตีความว่า "แรงอย่างน้อยเท่า Rain" แล้ว resolve ไป state ที่แรงที่สุดเท่าที่ `nature_type` นั้นมี ⇒ มีแต่ `shedding_tree` ที่ถึง `falling` ที่เหลือกลับมาที่ `sway_strong` · เลือก weather แล้ว slider เด้งไปค่าของเฟรมนั้น (9/10/29/49/80) แต่ **ค่า wind ไม่เปลี่ยน state** เพราะตาราง band ยัง `ต้องดึง` และ Rain 29 ขัดกับ `sway_strong ≥ 30` ในตัว spec เอง |
| ~~13~~ | ~~**"(Hidden)" badge ใน Map Editor**~~ | มี | ไม่มีทั้ง Figma และ code | **✅ ปิดแล้ว 2026-09-22 — ตัดทิ้ง** ไม่มีทั้งใน Figma และใน code เดิม และไม่ใช่แค่เรื่อง nature (จะกระทบ object ทุกชนิดที่ถูก hide) · ถ้าจะเอาจริงต้องขอ Figma เพิ่มแล้วเปิดเป็นงานแยก ไม่ใช่ scope นี้ |
| ~~14~~ | ~~**Name max length**~~ | 100 | `/100` | **✅ ปิดแล้ว 2026-09-22** — `MAX_NAME_LENGTH` 50 → **100** (`constants.ts`) · spec กับ Figma ตรงกันทั้งคู่ และ `tb_object.name` เป็น `VARCHAR(100)` ตั้งแต่ `migrations/10_create_tb_object.sql` แล้ว = ของเดิม 50 เป็น client-only · **กระทบ object ทุก type** (ขยาย limit ไม่ทำให้ของเดิมพัง) · ⚠️ ฝั่ง server **ไม่มี** length validation เลย ถ้าใครยิง API ตรงด้วยชื่อ >100 จะพังที่ DB — งานแยก |
| ~~**14a**~~ | ~~**สี/ประเภทของ box object หลังบันทึก**~~ | HP-03 AC: "หลังบันทึกสามารถกำหนดสีและประเภทของ box object ได้" vs HP-02 "Collision: fixed = walkable" | hitbox toolbar + colour dot ใน Object Preview (§4.4 / §7.1) | **✅ ปิดแล้ว 2026-09-17** — ตรวจโค้ดแล้วทั้ง 2 อย่างเป็น**ของเดิมที่มีอยู่ในฟอร์มเดียวกับที่ Nature reuse**: 🎨 = piece tag colour (`PRESET_COLORS` 13 สี, `color-picker-popup.tsx:7`) ไม่ลง DB ไม่กระทบ gameplay · 🖌 = collision brush ที่ default มาจาก `deriveCollisionModeFromType` (`constants.ts:90`) → **เพิ่ม `"nature"` เข้าลิสต์ walkable 1 บรรทัด** · "walkable เสมอ" = **default ของ type** ไม่ใช่ล็อกไม่ให้แก้ (เหมือน `decoration`) จึงไม่ขัดกัน · Nature **มีแถว `object_compositions` เหมือน object ทั่วไป** (ฉบับก่อนของ technical-design §3 ที่เขียนว่าไม่มี — ผิด แก้แล้ว) · ⚠️ ต้องแก้บั๊ก `buildCellsFromHitbox` hardcode `blocked` ก่อน ดู [issues/object-hitbox-default-collision-mode-2026-09-17.md](../../issues/object-hitbox-default-collision-mode-2026-09-17.md) |

### 14.2 ต่างจาก spec แต่ทำตาม Figma ได้เลย (แจ้งให้ PM ทราบ)

15. Sort ไม่มี "ใช้มากสุด" (Figma = Name/Created at/Type ตรง code)
16. Filter ไม่มี nature_type sub-filter — มีแค่ category checkbox
17. `State : 4` = จำนวน state ทั้งหมด ไม่ใช่ `uploaded/required`
18. Thumbnail บน card เป็นภาพนิ่ง (spec: animated) — ถ้าจะ animate ต้องทำเอง ไม่มีใน design
19. ไม่มี "Object Status X/Y required states" ทุกหน้า — มีแค่ count badge 0/1 ต่อ tab ใน modal
20. Preview canvas ไม่มี floor-tile background / weather ไม่เปลี่ยน visual บน canvas
21. Hide = switch + Save (spec เขียน "status → Hidden" — ตรงกันในสาระ) · toast เป็น save ทั่วไป
22. EC-01 warning เป็น modal `Replace spritesheet?` ก่อนเลือกไฟล์ (นับ workspaces + maps, ไม่มีคำว่า "ทันที") — ไม่ใช่ inline
23. Error copy เป็น EN แยก title/body — TH ใน spec ใช้เป็นแนวแปล ไม่ใช่ copy จริง · 2 MB toast ไม่มี actual size · width toast ไม่มี "frame width = …"
24. Detail view หลัง save ไม่มี per-state list พร้อม Replace / ไม่มี "used in N workspaces" / ไม่มี audit / ไม่มี version — replace ทำผ่าน modal เดิม (Trash แถวไฟล์ → dropzone กลับมา — assumed)
25. Category/nature_type lock: Figma แสดงแค่ view mode (ทุก field เทา) — **ไม่มีเฟรม edit mode** จึงไม่มี lock icon/tooltip ตาม spec

### 14.3 ความไม่สอดคล้องภายใน Figma เอง (ไม่ต้องทำตาม)

26. Title หน้า view/edit เป็น `Add object` ทุกเฟรม (code โชว์ `object.name`) · 27. ปุ่ม h-40 vs h-42 สลับกันตามเฟรม → ใช้ 42 · 28. Delete button ใน Complete opacity-0 แต่กินพื้นที่ / view mode ไม่มี Delete เลย → จุดกด Delete `ต้องดึง` · 29. Confirm-name filled ใส่ `Comfortable sofa` แต่ enabled · 30. `Size: 100 mb` vs limit 2 MB · 31. Modal subtitle "Upload and manage object placement…" เป็น copy ของ composer · 32. typo `Gird size`, `Nuture type`, `Natue validate` · 33. Category dropdown ขาด Wall/Foods & Drink และเรียงต่างจาก code · 34. `Sakura tree` เป็นแค่ชื่อ object ตัวอย่าง (badge = Shedding tree ✓) · 35. Position pills X/Y/W/H = 0 ทุก state

---

## 15. `ต้องดึง` รวม (ยังไม่มีค่าจริง — ห้ามเดา)

| กลุ่ม | รายการ | Node / วิธี |
|---|---|---|
| Overlay | สี/alpha ของ overlay ใต้ modal ทุกตัวและ side panel | `6035:351148`, `5199:369527`, `5219:756127`, `5228:769282`, `6037:508258`, `6037:506531` |
| Divider | สีเส้นคั่น (Filter menu, form, modal) — SVG asset | คาด White 20% (preview modal ตรวจแล้ว = 20%) |
| Grid | สีเส้น grid ใน canvas (SVG) + scale ตาม zoom ไหม | `1179:215208` |
| ~~Zoom~~ | ~~track/fill/knob สี, min/max zoom~~ | **ตัดสินเอง 2026-09-22** — ใช้ชุดเดียวกับ HP-03 ที่ ship ไปแล้ว: step `50/75/100/150/200`, track 80×8 white 20% + fill `#58D68D`, default `100%` (ค่าที่ทุกเฟรมโชว์) · ถ้า designer มีค่าจริงค่อยแก้ที่ `nature-canvas.tsx` ที่เดียว |
| Slider ลม | ~~min/max/step~~ · ~~default ต่อ weather~~ · snap band ไหม · hover/active/disabled | **ตัดสินเอง 2026-09-22** — min/max = **0–90** (best-fit จาก 6 เฟรม), step 1 · default ต่อ weather ใช้ค่าจากเฟรมตรง ๆ (9/10/29/49/80) · **ยังเปิด:** ค่า wind ไม่ได้เปลี่ยน state (ดู §14.1 ข้อ 12) และ hover/active/disabled ยังไม่มีในเฟรม |
| Weather | selected/hover row · mapping Strong rain/Thunderstorm → state | ~~icon~~ **ตัดสินแล้ว: lucide** (`Sun`/`CloudSun`/`CloudRain`/`CloudRainWind`/`CloudLightning`) ตาม [rule 12](../../../.claude/rules/12-icons.md) — Figma เป็นภาพประกอบมีสี ยอมรับว่า fidelity ตกตรงนี้ · ~~chevron หมุน~~ ทำแล้ว (`rotate-180` ตอนเปิด) · **ยังเปิด:** selected/hover ของแถวใน panel (ตอนนี้ selected = white 100%, ที่เหลือ 80% — เดาเอง) · mapping ดู §14.1 ข้อ 12 |
| Toggle | ON/OFF/Disabled สี track/knob (48×24) | component `35:2604` / `35:2622` |
| Checkbox/Radio | สี unchecked/checked (คาด `#D1D1D6` / `#3E9864`) | asset |
| Badge Hidden บน Tree card | สี bg/border/text | card ใน `5219:761387` |
| Tree card selected | border exact | ไม่มี variant |
| Tree icon | glyph custom หรือ `TreePine` | asset `5045:273299` |
| Tabs | hover/focus · non-Idle active · badge เมื่อ count > 0 · ชุด tab ต่อ nature_type อื่น | ถาม designer |
| Dropzone | drag-over / uploading / error variants | component set ของ `1463:85080` |
| File row | Uploading สี · failed state · state หลัง replace | ถาม designer / reuse Pet (`#2DB6FF`) |
| Tooltip | copy ของ Info ทุกจุด (Z-index, Upload section, Object files) | ไม่อยู่ใน node |
| Frame count/rate | option list · default · disabled จริงไหม · editable เมื่อไหร่ | PM |
| Header buttons | disabled สีของปุ่ม (Preview) · Delete อยู่ไหน | **ครึ่งหนึ่งตัดสินเอง 2026-09-22** — ปุ่ม Preview ใช้ h-40 ให้เท่ากับ Cancel/Save ที่มีอยู่ (§7.2 ก็เป็น h-40) ไม่ใช่ 42 · disabled ใช้ `opacity-50` (Figma ไม่ได้วาด) · Delete ยังอยู่ที่เดิมตาม §14.3 ข้อ 28 |
| Edit mode HP-06 | เฟรมหลังกด Edit — field ไหน enable, lock nature_type แสดงยังไง | ไม่มีเฟรม — ต้องออกแบบ |
| Object Preview บนฟอร์ม | `1×1` label style · red cell 16×16 semantics · ~~โชว์ hitbox toolbar ไหม~~ (ตอบแล้วรอบที่ 2: โชว์ — แต่ "ประเภท box" หมายถึงอะไร ดู §14.1 ข้อ 14a) | screenshot only |
| Side panel | chevron rotate ตอน expand · วิธีปิด panel เมื่อไม่มี Back/X | component states `971:122521/122509` |
| Replace | trigger ของ modal · state หลัง replace | ไม่มีในเฟรม |
| Toast | duration · shadow `0 4px 8px` vs `0 4px 16px` (White shadow token) | — |
| Caption | 12/16 (file meta) เป็น token คนละตัวจริงไหม | `get_variable_defs` บน `1458:7166` |
| Thai copy | ทุก string ใน §12 | PM |

---

## 16. สิ่งที่ต้องกลับไปแก้ใน [technical-design.md](technical-design.md) หลังเห็น Figma

| technical-design | สิ่งที่ Figma บอก | ต้องทำ |
|---|---|---|
| §4 `NatureRequiredStates` (idle+sway_light+sway_strong …) | required = **idle** ตัวเดียว (PM) | ลด required เหลือ `idle` ทุก type; state อื่น optional — หรือรอ PM ยืนยันว่า sticky ชนะ spec |
| §4 `AnimStateSwayStrong = "sway_strong"` | label `Sway normal` | เก็บ key เดิม + label map, หรือ rename → ต้องตัดสิน (#2) |
| §5.2 `PUT /:id/animations/:state` รับ `frame_count`/`frame_rate` required | ไม่มีช่องกรอกใน UI | ทำ optional + server default/derive, หรือรับจาก dropdown ระดับ object |
| §6.4 active-gating (`status=active` reject ถ้า required ไม่ครบ) | Status ON ตั้งแต่ต้น · gating อยู่ที่ Save | เปลี่ยนเป็น: create ได้เมื่อมี idle (หรือ create ก่อน upload ทีหลัง?) — ลำดับ create → upload ต้องเคลียร์ เพราะ Figma Save disabled จนกว่า upload แต่ modal ต้องมี object_id สำหรับ S3 key |
| §4 `NatureTypeCustom` | ไม่มี Custom ใน dropdown | คง enum ฝั่ง API แต่ไม่โชว์ หรือตัด |
| §5.4 cache-bust `?v=` ผ่าน `thumbSrc` | code ใช้ `?t=` อยู่แล้ว | ตรงกันแล้ว — แค่ระบุว่าเป็น `?t=<updated_at ms>` ไม่ใช่ `?v=` |
| HP-04 config fields (`wind_threshold_kmh`, `base_intensity_multiplier`) | ไม่มี UI | schema คงไว้ได้ (server default ตาม state) แต่ไม่มีหน้าแก้ในรอบแรก |
| Delete confirm | ทั้ง 2 เงื่อนไขพิมพ์ชื่อ · ใช้ `workspace_count`+`map_count` | ไม่ต้องเพิ่ม `placed_objects_count` |
| Weather ใน preview | 5 conditions | ถ้า preview เป็น client-only simulation ไม่กระทบ API — แต่ threshold default ต่อ weather ต้องมีที่เก็บ (constant ฝั่ง FE) |

---

## 17. ลำดับงาน UI ที่แนะนำ (สอดคล้อง task-breakdown ใน technical-design §9)

1. **Foundation** — `ObjectType` + nature ทุกที่ (§13 แถว 1–5) + i18n keys พื้นฐาน · Tree card variant · badge — เห็นผลใน list ทันทีเมื่อ API มี type=nature
2. **Form** — `object-add-form.tsx` nature branch (Nature type dropdown, z-index prefill, ซ่อน composer, `nature-stage-upload-section.tsx`) + read-only style + switch 48×24
3. **Extract shared** — `count-tab-strip.tsx` จาก preview-modal · `animation-upload-card.tsx` + validation จาก Pet (แก้ Pet ให้ใช้ของ shared ด้วย — rule 09)
4. **Upload modal** (§4) — ประกอบจาก 3 + `ObjectPreviewCanvas` + zoom pill + spritesheet playback + error toasts (§9)
5. **Preview modal** (§6) — shell + weather dropdown (TwDropdown props) + wind slider — **รอมติ #11/#12 ก่อน** ถ้า PM ต้องการ controls ตาม spec
6. **Hide/Delete/Replace** (§8/§10) — แก้ copy ใน `delete-object-dialog.tsx` + `replace-spritesheet-dialog.tsx`
7. Verify ทุกหน้าใน browser จริงกับ Figma screenshot (dev server) ก่อนบอกว่าเสร็จ — ตาม [18-before-after-metrics](../../../.claude/rules/18-before-after-metrics.md) UI tweak ไม่บังคับตัวเลข แต่ต้องมี live-test ไม่ใช่แค่ build เขียว
