# Room Pet — UX/UI Spec (from Figma) ยึด component VO ที่มีอยู่แล้ว

> ดึงจาก Figma MCP (`get_metadata` → `get_design_context` → `get_screenshot`) ทั้ง 8 section ของ SC-PET-01 ~ 08 · ไฟล์: [Zyra design — More Organised ver.](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-) · 2026-09-02
> **หลักการ:** ทุกชิ้นในนี้เป็นของที่ **เพิ่มเข้าไปในหน้า Virtual Office ที่มีอยู่แล้ว** — ไม่ใช่หน้าใหม่ ทุก section จึงแบ่งเป็น **"reuse ของเดิม"** กับ **"ของใหม่ที่ต้องเพิ่ม"** และระบุ component/ไฟล์เดิมที่ต้องแก้ ห้ามสร้าง nameplate / tooltip / minimap / toast / panel / modal ซ้ำ ([`.claude/rules/09-component-reuse.md`](../../../.claude/rules/09-component-reuse.md))
> **ตัวเลขทั้งหมดเป็น px ตรงจาก Figma** (ไม่เดา) — ค่าที่ Figma **ไม่มี** จะเขียนว่า "ไม่มีใน Figma" ห้าม implement จากการคาดเดา
> **spec ฝั่ง flow / business rule อยู่ที่ [spec.md](spec.md)** — ไฟล์นี้พูดเฉพาะหน้าตา, ตำแหน่ง, state ของ UI
> path ไฟล์โค้ดในตาราง "reuse" อ้างจากการสำรวจ zyra-app ณ 2026-09-02 — ก่อนแก้ให้ `grep` ยืนยันอีกครั้ง
> **ยังไม่ implement · ยังไม่ได้ review กับ Design/PM** — คำถาม 12 ข้อที่เกิดจากการเทียบ Figma ↔ ClickUp ↔ โค้ด อยู่ที่ §11 ท้ายไฟล์

---

## 0. ภาพรวม — Figma วางอะไรทับหน้า VO เดิม

ทุก frame ใน Figma เป็น instance ของ `Pet - Virtual working space` (1440×1024) = หน้า VO ปัจจุบันทั้งหมด (sidebar 72px, map 1352×992 radius 16, bottom menu, map tools, minimap, zone label pill, avatar + nameplate) **แล้ววางของ Pet เพิ่มเข้าไป** ดังนี้

| ชิ้นใหม่ | โผล่ที่ไหน | ต่อยอดจากของเดิม | Scenario |
|---|---|---|---|
| Pet sprite บน map (40×40 @ zoom ปกติ) | ในห้อง ตำแหน่งที่ admin วาง | render บน PixiGameScene ด้วยกฎ z-order เดิม `encodeZ(sortRowDrawOrder(row, slot), isFloor, objectZIndex)` — **ไม่มี `OBJECT_Z_INDEX` ในโค้ด** (ชื่อนั้นมาจาก ClickUp card) · walkable | 01, 02, 08 |
| Pet nameplate (ชื่อ + mood emoji + XP bar) | เหนือ sprite | **`Display on avatar head` ของ avatar คนอื่น** (bg `#242B32`) เพิ่ม icon/emoji/progress | 01 |
| Mood bubble (emoji 16px ใน tooltip) | เหนือ nameplate เป็นระยะ | **Tooltips component เดิม** variant `Emoji` | 01, 06 |
| Minimap pet dot 6px | ใน minimap เดิม | เพิ่ม dot อีกชั้นใน `Minimap` state `Pet` | 01 |
| Pet menu marker 32×32 (ปุ่มมือ) | ที่ตัว pet เมื่อคลิก | pattern เดียวกับ marker menu ของ object/zone (bg `#242B32` p-4 radius 8) | 03 |
| Tooltip คีย์ลัด `Press [P] pet` / `+5 XP` / ♥ | เหนือ pet | **Tooltips component เดิม** (variant text + key badge / Emoji) | 03 |
| Pet menu panel 320px | มุมขวาบน `top-24 right-24` | **side-panel pattern เดิม** (bg `#242B32` p-16 gap-16 radius 16) | 03, 06 |
| Overlay + pet 320px + "Click to start evolve your pet" | กลางจอ | overlay `rgba(0,0,0,0.5)` เดิม | 04, 05 |
| Pet evolution modal 458px | กลางจอ | **modal pattern เดิม** (bg `#242B32` radius 16) | 04, 05, 07 |
| Share modal ("General modal") 458px + Toast | กลางจอ / `top-24 right-24` | **General modal + Toast เดิมทั้งชิ้น** ไม่มีอะไรใหม่ | 04 |
| Notification card "Your team pet evolved" | ใน Notification panel เดิม | **Notification card เดิม** เพิ่ม type + icon สีม่วง | 07 |
| Daily reminder banner (avatar+vine + กล่องข้อความ) | มุมซ้ายล่าง `left-65.5 bottom-4` | **Announcement "No require acknowledge" banner เดิม** เปลี่ยน icon เป็น pet | 07 |
| Setting → Notifications → section **PET** | Setting modal เดิม | เพิ่ม 1 section + 1 row + Switch เดิม | 07 |

### สิ่งที่ Figma **ไม่มี** ทั้งที่ ClickUp card เขียน (ห้าม implement จนกว่าจะมี design)

| ClickUp card บอกว่ามี | Figma | ทำอย่างไร |
|---|---|---|
| Hover tooltip ชื่อ / stage badge / XP bar / mood (SC-PET-01 AC4) | hover ไม่มี tooltip แยก — ข้อมูลอยู่บน **nameplate ถาวร** แล้ว sticky: "Hover สัตว์เลี้ยง **ไม่ปรากฎเมนู** Pet" | ยึด Figma: nameplate แสดงตลอด, hover = แสดงแค่ tooltip คีย์ลัดเมื่ออยู่ใกล้ |
| Pet Status Panel มี "ผู้ดูแลวันนี้ Top 3" + ปุ่ม 🤚 ลูบหัว + Feed X/3 (SC-PET-06) | Pet menu panel มี **Mood / Stage / streak banner / Daily quest 5 รายการ** ไม่มี Top 3, ไม่มีปุ่มลูบหัวในพาเนล, ไม่มี Feed | ยึด Figma — ต้องแจ้ง PM ว่า card กับ design ไม่ตรง (ดู [spec.md § จุดที่ขัดกัน](spec.md)) |
| Mood 4 state (Hungry) | Figma มี **3 emoji**: Smiling Face With Hearts / Slightly Smiling Face / Crying Face | 3 state ตรงกับ PetManagement — ตัด Hungry |
| Banner HUD "🥚 [ชื่อ] ฟักแล้ว!" 5 วินาที + ปุ่ม "ไปดู" (SC-PET-04/07) | ไม่มี banner แบบนั้น — stage change ใช้ **Pet evolution modal** เต็มจอ (มี overlay) แทน | ยึด Figma: modal ไม่ใช่ banner |
| Stage badge สี Egg=เทา Hatch=เหลือง Grow=เขียว Evolve=ม่วง | Figma มีแค่ 2 สี: Egg `#8C99A6`, Baby `#2DB6FF` | Adult / Evolved **ไม่มีใน Figma** ต้องขอ design เพิ่ม (ห้ามเดา) |
| Sad: sad sprite "นอนซม" | มี frame `shiba - sad 1` เป็น placeholder ANIMATION เท่านั้น | ใช้ slot `Sad` ของ pet type จาก PetManagement |
| Prestige XP สีพิเศษ (SC-PET-05) | Figma มี variant **MAX XP** (บาร์เต็มสีขาว + คำว่า `MAX XP`) ไม่มีสี prestige | ยึด Figma: แสดง `MAX XP` |

---

## 1. Shared Design Tokens (เฉพาะที่ Pet ใช้ — ชุดเดียวกับ VO เดิม)

### Colors

| Token (Figma) | Hex / Value | ใช้กับ |
|---|---|---|
| Background/Primary · Theme colour/Primary | `#242B32` | nameplate pet, pet menu marker, pet menu panel, modal, reminder text box |
| Theme colour/Secondary | `#2B3540` | Notification panel, Setting content |
| Shade Black/500 | `#1A1B1E` | Tooltips ทุกตัว, Toast, minimap bg |
| Shade Black/50% | `rgba(26,27,30,0.5)` | progress track ใน pet menu panel, map tools container |
| Primary/500 | `#58D68D` | XP bar gradient start, ปุ่ม Confirm, key badge `P`, quest count ที่ครบ, tab active |
| Primary gradient (XP bar) | `linear-gradient(90deg, #58D68D → #8FE4B3)` | XP progress fill ทุกที่ (nameplate, panel, modal) |
| Primary/20% · Primary/10% | `rgba(88,214,141,0.2)` · `rgba(88,214,141,0.1)` | tab active, toast icon bg · setting menu active |
| Blue/500 | `#2DB6FF` | stage badge **Baby** (2), ปุ่ม Locate ใน map tools |
| Grey/500 | `#8C99A6` | stage badge **Egg** (1), secondary text ทุกตัว |
| Grey/Secondary | `#697384` | placeholder "Search members" |
| Purple/500 | `#996ADF` | nameplate ของ **ตัวเอง** (ไม่ใช่ของ pet) |
| Yellow/500 | `#ECC819` | ตัวหนังสือ `+5 XP` ใน XP tooltip |
| Orange/500 · Orange/10% | `#FF8000` · `rgba(255,128,0,0.1)` | streak banner "Together for 100 days" |
| Red/500 (badge) | `#D41818` | count number บน bell icon sidebar |
| Solid White 5% / 10% / 20% | `rgba(255,255,255,0.05/0.1/0.2)` | ghost button bg / progress track (nameplate), quest icon tile / border ทุกตัว |
| Pet avatar circle bg | `#FFA8A8` | วงกลม 56px หลังรูป pet ใน panel header |
| Notification pet icon bg | `#E1ADFF` | วงกลม 32px ของ card "Your team pet evolved" |
| White shadow | `drop-shadow(0 4px 8px rgba(255,255,255,0.08))` | Tooltips, Toast |
| Overlay | `rgba(0,0,0,0.5)` | ทับทั้งจอ (1440×1042) ตอน hatch/evolve และหลัง modal |

### Typography (Inter — **ใช้ `font-sans` ไม่ใส่ `font-['Inter']`** เพราะข้อความไทยจะพัง ดู [[thai-font-inter-override]])

| Style | Size / Weight / Line-height / tracking |
|---|---|
| Title/Bold | 20 / 700 / 25 |
| Sub/Medium · Sub/Regular | 16 / 500 · 400 / 22 |
| Body/Medium · Body/Regular · Body/Bold | 14 / 500 · 400 · 700 / 18 |
| Caption 1/Medium · Caption 1/Regular | 12 / 500 · 400 / 15 / `-0.43` (Figma ส่งเป็น `tracking-[-0.0516px]`) |
| Caption/Regular | 12 / 400 / 16 / 0 (ใช้ใน zone label pill + time "1 min ago") |
| Caption 2/Medium · Caption 2/Semi | 10 / 500 · 600 / 13 / `-0.43` (key badge `P`, stage number badge) |
| Pixelony Regular 12 (+ `text-shadow 0 1px 0 black`) | ตัวเลข `+5` / `+10` บน quest icon tile — เป็น pixel font ของเกม ต้องเช็คว่ามีใน repo ไหม ถ้าไม่มี = asset ใหม่ |

### Geometry ที่ใช้ซ้ำ

- Tooltips: `bg-[#1A1B1E] p-[8px] rounded-[8px]` + หางสามเหลี่ยม 20px หมุน 60° ยื่นล่าง `bottom-[-12.32px]` กลาง
- Nameplate (avatar และ pet): `p-[4px] gap-[4px] rounded-[6px]` text Caption 1/Medium white
- Panel: `p-[16px] gap-[16px] rounded-[16px]` (pet menu, notification, modal share) · modal evolution `px-[16px] py-[40px] gap-[40px]`
- ปุ่ม: h-42 rounded-8 (modal) · h-24 rounded-4 px-8 (quest row) · h-32 rounded-8 (tab)
- Progress: `h-[4px] rounded-[90px]` (nameplate, panel) · `h-[8px] w-[200px]` (modal)

### Icon mapping (lucide-react เท่านั้น — [`.claude/rules/12-icons.md`](../../../.claude/rules/12-icons.md))

| Figma | lucide-react | หมายเหตุ |
|---|---|---|
| Hand (pet menu marker, 16px) | `Hand` | ปุ่มลูบหัว |
| palm_down_hand (15–20px PNG) | — | **ไม่ใช่ icon** เป็น animation asset มือลูบหัว ต้องเป็น sprite/PNG |
| Cancel | `X` | |
| Cheron-Right | `ChevronRight` | ปุ่ม "Go to", ลูกศรใน stage row |
| Check (toast) | `Check` | |
| read (Mark as read, 12px) | `CheckCheck` | มีใน notification panel เดิมแล้ว |
| Medal (XP tooltip 16px) | — | Figma ส่งเป็น PNG emoji-style → ใช้ asset เดิมถ้ามี ไม่มีให้ export |
| Fire, Smiling Face With Hearts, Slightly Smiling Face, Crying Face, Red Heart | — | **emoji PNG 16px** (ชุดเดียวกับ reaction/emoji picker เดิม) ไม่ใช่ lucide |
| Move (cursor 40px บน overlay) | `MousePointer2` หรือ asset | เป็นภาพ cursor บอกว่าให้คลิก — เช็คว่า onboarding เดิมมี asset นี้ไหม |
| pet icon บน nameplate (Frame 427323403, 16px SVG) | — | custom SVG (รูปอุ้งเท้า/pet) → `components/ui/icon.tsx` |

---

## 2. SC-PET-01 · Pet บน VO map — [node 4206-126170](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4206-126170)

### Frames ใน section
`Pet - Virtual working space` ×6 (base + variant) · `Pet mood - Happy` / `- Neutral` / `- Sad` (มี mood bubble) · sticky 2 ใบ

**Sticky (designer note):**
- "Hover สัตว์เลี้ยง หรือ คลิกที่สัตว์เลี้ยง (จะมี Panel สัตว์เลี้ยงด้วย) จะปรากฎ HUD ของสัตว์เลี้ยง"
- "แสดงอารมณ์ Happy Neutral Sad — Bubble mood จะแสดงออกมาเป็นระยะๆ **อาจจะ 30 วิ : ครั้ง (ค่อยกำหนด)**"

### 2.1 Pet in map (node `4206:201103` egg · `4215:519137` variant 2)

```
Pet in map  (flex-col, items-center, gap 8)
├─ Container → Display on avatar head   ← มีเฉพาะ variant 2 (หลังฟัก); symbol Egg ไม่มี
│   bg #242B32 · p 4 · gap 4 · rounded 6 · flex-col items-center
│   ├─ row (gap 4): [pet icon 16×16 SVG] [ชื่อ pet · Caption1/Medium white] [mood emoji 16×16 PNG]
│   └─ Progress  h 4 · w-full · bg rgba(255,255,255,0.1) · rounded 90
│        fill: gradient #58D68D→#8FE4B3 · rounded 90 · width = % XP ใน stage (ตัวอย่าง 60%)
└─ Pet sprite 40×40   (component `Pet` default 36×36 แต่ instance บน map = 40)
```

ตำแหน่งใน frame: `left calc(50% - 56px)`, `bottom 185px` (ในห้อง Lobby ตัวอย่าง) — จริงคือ `tile_x/tile_y` จาก `tb_room_pet`

**เทียบกับ avatar nameplate เดิม (`Display on avatar head`):**

| | Avatar "Other" (เดิม) | Avatar "Me" (เดิม) | **Pet (ใหม่)** |
|---|---|---|---|
| bg | `#242B32` | `#996ADF` · w 140 · ellipsis | `#242B32` (เหมือน Other) |
| ซ้ายชื่อ | status dot 10px | status dot 10px (no stroke) | **pet icon 16px** |
| ขวาชื่อ | — | — | **mood emoji 16px** |
| แถวสอง | — | — | **XP progress h 4** |
| padding/gap/radius/font | 4 / 4 / 6 / Caption1 Medium | เท่ากัน | เท่ากัน |

→ **reuse** nameplate renderer ของ avatar (Pixi): `makeNameTag()` ใน `zyra-app/zyra-engine/pixi-game/utils.ts` + `PixiGameScene._updateNameTag()` ใน `zyra-engine/pixi-game/scene.ts` + ค่าคงที่ `NAME_TAG_PAD 4 / NAME_TAG_GAP 4 / NAME_TAG_RADIUS 6 / NAME_TAG_LINE_H 15` ใน `pixi-game/constants.ts` — เพิ่ม option `leadingIcon` (แทน status dot), `trailingEmoji`, `progress` — ห้ามเขียน pill ใหม่
> ⚠️ โค้ดปัจจุบันวาด pill ของ **peer** เป็น `0x141420 @ alpha 0.88` ไม่ใช่ `#242B32` ตาม Figma (ของเดิมเบี่ยงจาก Figma อยู่แล้ว) — pet ให้ใช้ค่าเดียวกับ peer pill ในโค้ดเพื่อให้กลมกลืน แล้วบันทึกเป็นคำถามข้อ 11 · font ของ nameplate ใช้ `sans-serif` ไม่ใช่ Inter (ภาษาไทย) ตามที่ `_updateNameTag` ทำอยู่

### 2.2 Mood bubble (node `4250:565368` "Happy" 40×31 · `4345:852999` Tooltips variant Emoji 32×32)

- Tooltips เดิม: `bg #1A1B1E · p 8 · rounded 8 · drop-shadow 0 4 8 rgba(255,255,255,0.08)` + หางล่าง
- เนื้อใน: emoji PNG 16×16 ตัวเดียว → Happy = *Smiling Face With Hearts*, Neutral = *Slightly Smiling Face*, Sad = *Crying Face*
- ตำแหน่ง: กึ่งกลางเหนือ nameplate (frame วางที่ x 644 y 717 เทียบ pet ที่ x ~664 y 760) ≈ **เหนือ nameplate 8px**
- แสดง "เป็นระยะ" — ค่า **30 วินาที/ครั้ง ยังไม่เคาะ** (sticky) → ทำเป็น const ปรับได้ ไม่ hardcode ใน component
- **reuse:** วาดในแคนวาสแบบเดียวกับ talking bubble ของ avatar — `makeTalkingBubble()` (`zyra-engine/pixi-game/utils.ts`) + `scene._updateTalkingBubble` + ค่าคงที่ `TALKING_BUBBLE_*` (body + หางสามเหลี่ยม, ดัน nameplate ขึ้นด้วย `TALKING_BUBBLE_NAMETAG_GAP`) — เปลี่ยนเนื้อในจากจุด `•••` เป็น emoji texture 16px และใช้สี/ขนาดตาม Figma (`0x1a1b1e`, p 8, radius 8) · **ห้ามใช้ `components/ui/tooltip.tsx`** (Radix/shadcn — ผิด rule 08)

### 2.3 Minimap (node `4215:325070` state `Pet`)

- Minimap เดิม 169×100 `bg #1A1B1E rounded 16` มี avatar dot 6px หลายสี (`#FFA8A8` `#E1ADFF` `#7EA2FC` `#C4FCB6`) + self dot (Status 6px) กลาง
- state `Pet` เพิ่ม **ellipse 6×6** อีก 1 จุด (`left 61.5 top 47`) เป็น SVG asset `Ellipse 4` — **อ่านจาก SVG แล้ว 2026-09-02: `<circle r="3" fill="#996ADF"/>` = Purple/500** (ไม่ใช่ชมพูตามที่ ClickUp เดา) → const `PET_MINIMAP_DOT_COLOR` ใน `lib/pet-minimap.ts` ✅ ทำแล้ว (`VOMinimap` prop `petDots`)
- ต่อยอด: `VOMinimap` (`views/user/virtual-office/components/vo-minimap.tsx`) รับ prop ใหม่ `petDots` (คู่กับ `PlayerDot[]`) แล้ว render ใน `MinimapContent` ใต้ avatar
  - ⚠️ โค้ดจริงไม่ได้วาด avatar เป็นจุด 6px ตาม Figma — วาดเป็น `MiniAvatar` วงกลม **14px** (collapsed) / **22px** (expanded) และ self = วงกลม `dotSize × 0.55` → pet dot ต้อง**สเกลตาม `dotSize` เดียวกัน** (เสนอ `dotSize × 0.45` ให้เล็กกว่า self) ไม่ใช่ 6px ตายตัว — บันทึกเป็นคำถามข้อ 3

### 2.4 ของเดิมที่แค่ต้อง "รับรู้" pet (ไม่แก้หน้าตา)

- zone label pill `Workspace-ppl online`: `bg rgba(0,0,0,0.7) opacity-50 px-8 py-4 rounded-16 Caption/Regular` — ไม่เปลี่ยน
- Bottom menu / Map tools / Sidebar — **ไม่มีปุ่ม Pet เพิ่มใน HUD** ใน Figma ทั้ง 8 section (ClickUp SC-PET-06 บอก "Pet icon บน HUD" แต่ Figma เปิด panel จากการคลิก pet เท่านั้น)

---

## 3. SC-PET-02 · AI Movement — [node 4215-519205](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4215-519205)

Section นี้ **ไม่มี UI ใหม่** — เป็นภาพประกอบ behavior 3 กลุ่ม (Title Flow สีม่วง):

| กลุ่ม | Frame | สิ่งที่เห็น |
|---|---|---|
| Egg Stage (Wobbling) | 4 frames VO เต็ม | ไข่ 40px อยู่ที่เดิม |
| Baby, Adult and Evolved Stage (Walking) | VO เต็ม + ห้องซูม (`4624:148228`) + ป้าย `ANIMATION` | `shiba - walk 1` **120×120** ในห้องที่ซูมเข้า (map scale ~3×) — ยืนยันว่า pet sprite ขยายตาม zoom เท่า avatar |
| Baby, Adult and Evolved Stage (Sitting) | VO เต็ม + ห้องซูม (`4624:148403`) | `shiba - sit 1` 120×120 นั่งข้างโซฟา |

- ป้าย `ANIMATION` = text Pixelony 100px สีขาว — เป็น placeholder ให้ทีม animation ไม่ใช่ UI
- ไม่มีภาพ "notice animation" (หูตั้ง) หรือ "react to avatar" ใน Figma → ยึด slot ที่มีจริง (ดู [spec.md ข้อ 13](spec.md))
- **ไม่มี idle animation แยก** ใน Figma — มีแค่ Wobbling / Walking / Sitting ตรงกับ slot vocabulary ของ PetManagement (`Idle` ถูกถอดแล้ว 2026-09-01) → idle บน map = เฟรมนิ่งของ `Walking` หรือเข้า `Sitting`

---

## 4. SC-PET-03 · Interact — [node 4256-567590](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4256-567590)

### Flow ตาม arrow ใน Figma

```
VO ปกติ ─click pet─▶ Pet - Interact (marker มือ + Pet menu panel เปิด)
   │                         └─ click marker (อยู่ไกล) ─▶ avatar วิ่งไปหา pet, HUD+menu หาย ─▶ ถึงแล้วเล่น Happy
   └─hover pet (ใกล้)─▶ tooltip "Press [P] pet"
                              └─ กด P / click มือ ─▶ มือลูบหัว + ♥ tooltip ─▶ (ถ้าได้ XP) "+5 XP" tooltip ก่อน ─▶ Happy
```

**Sticky ทั้งหมด (ตัดสินหน้าตา):**
- "คลิกที่สัตว์เลี้ยง (จะมี Panel สัตว์เลี้ยงด้วย) จะปรากฎ HUD ของสัตว์เลี้ยง"
- "**Hover สัตว์เลี้ยง ไม่ปรากฎเมนู Pet**"
- "กรณีอยู่ไกลกับสัตว์เลี้ยง เมื่อกด Icon Pet **ตัวละครเราจะวิ่งไปหาสัตว์เลี้ยง + HUD และ Menu จะหายไป**"
- "กรณีอยู่ใกล้กับสัตว์เลี้ยง ถ้า Hover → คีย์ลัด Pet"
- "วิ่งเข้ามาและเริ่มทำ Animation pet ซึ่งน่าจะดึง Animation สัตว์เลี้ยง **Happy** มา"
- "เมื่อ Interaction กับสัตว์เลี้ยงจะแสดงอาการ Happy มี Animation **มือลูบหัว**สัตว์เลี้ยง"
- "กรณี Interaction แล้วได้ XP **ให้ขึ้นว่าได้รับ XP ก่อน แล้วค่อยแสดง Happy** แต่ถ้าไม่มี XP ก็ให้แสดง Happy ได้เลย"

### 4.1 Pet menu marker (node `4381:406266`, 32×32)

```
Pet menu   bg #242B32 · p 4 · gap 8 · rounded 8
└─ Element of marker   p 4 · rounded 4
   └─ Hand icon 16×16 (white)
```
- ตำแหน่ง: ที่ตัว pet (x 648 y 843 ใน frame = ใต้ nameplate / ทับตัว pet ล่างซ้าย)
- pattern เดียวกับ popover/marker ของ VO เดิม (bg `#242B32` radius 8 + ปุ่ม icon) — วางเป็น DOM overlay ตำแหน่ง screen-space แบบ `PZZoneHover` (`views/user/virtual-office/components/pz-zone-hover.tsx` — คำนวณ `sx/sy` + `translate(-50%,-50%)`, `pointer-events-auto` เฉพาะตอน interactive) ใส่ปุ่ม `Hand` 1 ปุ่ม · **ระวัง** HUD layer เป็น `pointer-events-none` ทั้งชั้น ([[vo-hud-pointer-events-none]]) ต้องเปิด pointer-events ที่ปุ่มเอง
- แสดงเฉพาะหลัง **click** pet (hover ไม่แสดง) และหายเมื่อคลิกแล้ว avatar เริ่มวิ่ง

### 4.2 Tooltip คีย์ลัด (node `4256:570876`, 91×31)

```
Tooltips   bg #1A1B1E · p 8 · gap 4 · rounded 8 · drop-shadow · items-center · หางล่างกลาง
├─ "Press"  Caption1/Regular white
├─ key badge  w 16 · p 1 · rounded 2 · border 1 #58D68D · "P" Caption2/Medium #58D68D
└─ "pet"    Caption1/Regular white
```
- แสดงเมื่อ hover pet **และ** avatar อยู่ใน radius (ClickUp: 2 tiles) · ตำแหน่งเหนือ pet (x 618 y 752)
- **ของเดิมที่ใกล้ที่สุด:** VO ยังไม่มี tooltip คีย์ลัดแบบนี้ (HUD ใช้ `title=` attribute ล้วน) · in-canvas มี tooltip ของ compact avatar ใน `scene._updateCompactAvatar` (`roundRect` radius 6, fill `0x1a1b1e @0.95`) — ให้ทำเป็น DOM overlay ตาม pattern `PZZoneHover` แล้ววาด key badge ด้วย Tailwind · ห้ามใช้ `components/ui/tooltip.tsx` (Radix)

### 4.3 ตอนลูบหัว (node `4689:564655` / `4261:588071`)

| ชิ้น | spec | ตำแหน่ง |
|---|---|---|
| มือลูบหัว `palm_down_hand` | PNG **20×20** (เฟรมแรก) → **15×15** (เฟรมถัดไป) = animation ขยับ/ย่อ | ทับหัว pet (x 653 y 785 → 656 y 789) |
| ♥ tooltip (`4689:564658`, Tooltips variant `Emoji`) | `bg #1A1B1E p 8 rounded 8 gap 4` + *Red Heart* PNG 16 · 32×32 | เหนือ pet x 647 y 748 |
| `+5 XP` tooltip (`4276:151515`, 71×32) | `bg #1A1B1E p 8 gap 4 rounded 8 items-start` + *Medal* PNG 16 + "+5 XP" **Caption1/Medium `#ECC819`** | เหนือ pet x 628 y 752 |

ลำดับ: `+X XP` → ♥ + มือลูบหัว + `Happy` animation (ถ้าไม่ได้ XP ข้ามข้อแรก) — ClickUp เขียน "+X XP ✨ float ขึ้นและ fade" แต่ Figma เป็น tooltip นิ่ง → **ยึด tooltip**; จะ float/fade เพิ่มได้แต่ต้องคง geometry นี้

### 4.4 Pet menu panel เปิดพร้อมกัน — spec เต็มอยู่ §7 (SC-PET-06) ใช้ตัวเดียวกัน

---

## 5. SC-PET-04 · Egg → Baby (Figma ใช้ชื่อ **Baby** ไม่ใช่ Hatch) — [node 4280-151858](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4280-151858)

Section กว้าง 52,552px = flow ยาว 20+ frame · 2 แถว (แถวบน = ลำดับ animation, แถวล่าง = ตัวอย่างเฟรม + share flow)

### Flow

```
VO (ไข่ XP เต็ม) ─▶ [A] Overlay + ไข่ 320 + "Click to start evolve your pet" + cursor
  ─click ไข่─▶ [B] egg animation (asset 1000×1000 ทับ overlay) ×หลายเฟรม
  ─▶ [C] แสงวาบเต็มจอ (overlay ฟ้าอ่อน) ─▶ แสงหดกลับจุด center ─▶ [D] ร่างใหม่ 320 + cursor (+ เสียงสัตว์)
  ─click─▶ [E] Pet evolution modal ─Confirm─▶ กลับ VO
                                   └─Share your friends─▶ [F] General modal "Share to your friends" ─Send─▶ [G] Toast "Share successfully." ─▶ [H] Direct message - Full view
```

**Sticky:**
- "**คลิกที่ไข่ก่อน แล้วค่อยเริ่ม animation Evolve**" (ไม่ auto-play)
- "หลังจากไข่แตก แสงสว่างวาบ > แสงค่อยๆกลับมาที่จุด Center > ปรากฎรูปลักษณ์สัตว์เลี้ยงใหม่"
- "พอโชว์ร่างนี้แล้ว**ต้องมีเสียงสัตว์เลี้ยง** หลังจาก Click โชว์ Modal"
- "Animation **หลอด XP ลดลง** เพื่อเข้าสู่ Stage ต่อไป **ตัวเลข XP ค่อยๆเปลี่ยน**" (ใน modal)
- "Animation ตัวอย่างช่วงแรก" / "ช่วงหลัง" = frame [B] และ [D] เป็นตัวอย่างเท่านั้น

### 5.1 [A] Hatch prompt (node `4284:167462`)

| ชิ้น | spec |
|---|---|
| Overlay | `absolute inset-0 bg-[rgba(0,0,0,0.5)]` ขนาด 1440×**1042** (ยื่นเกินจอ 18px — เก็บเป็น `inset-0` ก็พอ) ทับทุกอย่างรวม sidebar/bottom menu/minimap แต่ **HUD เดิมยังเห็นจาง ๆ** |
| Pet (ไข่) | component `Pet` **320×320** กึ่งกลางจอ (`left-1/2 top-1/2 -translate-1/2`) — asset Egg stage 1 |
| ข้อความ | "Click to start evolve your pet" **Title/Bold 20/25 white** · `left calc(50% - 141px)` `top 696` = ใต้ pet ~24px กึ่งกลาง |
| cursor hint `Move` | SVG 40×40 ที่ `left 780 top 632` = มุมขวาล่างของ pet (บอกว่าให้คลิก) |

- overlay + center content = pattern เดียวกับ modal overlay เดิมของ VO → **reuse overlay container** เปลี่ยนเนื้อใน
- คลิกที่ไข่เท่านั้นที่เริ่ม animation (คลิก overlay ไม่ทำอะไร — Figma ไม่มี dismiss)

### 5.2 [B]–[D] Animation frames

- asset `Pet - egg animation2 1` / `Pet - dog evo baby 1` ขนาด **1000×1000** วางที่ `left 207–220 top 12` (เต็มความสูงจอ) — เล่นทับ overlay
  - **ไข่แตก (egg → baby) ใช้ GIF กลางตัวเดียวทุก pet type** — อัปโหลดขึ้น R2 แล้ว 2026-09-02: `https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/pet/shared/egg-evolution.gif` (key `static/pet/shared/egg-evolution.gif` · 960×960 · 24 เฟรม @150ms ≈ 3.6 วิ · loop · 159 KB · `Cache-Control: immutable`) · ต้นฉบับ `storage/pet-egg-animation.gif` ใน repo root (ไม่ commit) — ตอน render ขยายเป็น 1000×1000 ตาม Figma หรือแสดง 960 กึ่งกลางก็ได้ (ต่างกัน 4%)
  - **PM เคาะ 2026-09-02: slot `Evolution` ทุก stage = GIF** — เมื่อ pet ถึง threshold จะเข้า "สถานะ evo" แล้วเล่น GIF นี้ 1 รอบทับ overlay ก่อน switch sprite · baby → adult และ adult → evolved ใช้ GIF ของ stage ต้นทาง **ต่อ pet type** (อัปใน PetManagement SC-PM-03) · egg → baby ใช้ GIF กลางด้านบน · renderer: `<img>` หรือ PixiJS `GifSprite` (`pixi.js/gif`) วางกึ่งกลาง ขนาด = `frame_width × frame_height` ของ row นั้น (GIF ไม่เกิน 1000×1000) · กฎไฟล์/validation: [PetManagement/spec.md § Evolution = GIF](../PetManagement/spec.md)
  - **PM ยืนยัน 2026-09-02:** egg และ evolved **ยังมี slot `Evolution`** (17 slot เท่าเดิม) · **egg `Evolution` ถูก prefill ด้วยไฟล์กลางอัตโนมัติทุก pet type** (API fallback เมื่อไม่มี row → `is_default: true`) และ admin อัป GIF ของตัวเองทับได้ → client VO **อ่าน `sprite_url` จาก response เสมอ ห้าม hardcode URL กลาง** ([spec.md ข้อ 19](spec.md), [PetManagement/spec.md § Prefill](../PetManagement/spec.md))
- [C] เฟรม `Overlay` ล้วน 1440×1042 สีฟ้าอ่อน (แสงวาบ) → effect ฝั่ง client ไม่ใช่ sprite
- [D] ร่างใหม่ `Pet - dog baby 1` **320×320** กลางจอ + `Move` 40×40 ตำแหน่งเดียวกับ [A]

### 5.3 [E] Pet evolution modal (node `4287:179918`, 458×498)

```
modal  w 458 · bg #242B32 · rounded 16 · px 16 · py 40 · flex-col · gap 40 · items-center · กึ่งกลางจอ (x 491 y 263–296)
├─ Title (gap 8, center)
│   ├─ "Your Pet Evolved"                           Title/Bold 20/25 white
│   └─ "Your pet has grown into its next stage.     Body/Regular 14/18 #8C99A6 · text-center
│       Keep earning XP to unlock what's next!"
├─ Pet container (gap 8, center)
│   ├─ stage row (gap 8, items-start, justify-center)
│   │   ├─ [badge 16×16 rounded 4 bg #8C99A6 · "1" Caption2/Semi white (มี ellipse highlight มุมซ้ายบน)] + "Egg"  Sub/Regular 16/22 white
│   │   ├─ Cheron-Right 24×24
│   │   └─ [badge bg #2DB6FF · "2"] + "Baby"
│   ├─ Progress  w 200 · h 8 · bg white · rounded 90 · fill gradient #58D68D→#8FE4B3 (100%)
│   ├─ "100 / 100 XP"   Caption1/Regular 12/15 #8C99A6 (4 ชิ้น gap 4)
│   └─ Pet image 160×160 (`Pet - dog baby 1`) วางบน BG หญ้า ellipse 240×80 (`absolute bottom 117`)
└─ Buttons row (gap 16, w-full)
    ├─ "Share your friends"  flex-1 · h 42 · rounded 8 · bg rgba(255,255,255,0.05) · border rgba(255,255,255,0.2) · Sub/Regular white
    └─ "Confirm"             flex-1 · h 42 · rounded 8 · bg #58D68D · Sub/Regular white
```

- **animation ใน modal:** บาร์ 100% → ลดลงเป็น % ของ stage ใหม่ พร้อมตัวเลขนับ (sticky) — ใช้ค่า relative ตาม [spec.md ข้อ 5](spec.md) (`xp - threshold_ปัจจุบัน` / ช่วง stage)
- stage badge สี: **Egg `#8C99A6` · Baby `#2DB6FF`** — Adult / Evolved **ไม่มีใน Figma**
- BG หญ้า 240×80 เป็น PNG asset → ต้อง export เก็บใน `public/` (ห้ามฝัง base64 SVG ใหญ่ ดู [[oversized-svg-bitmaps-in-public]])
- **reuse** modal shell เดิมของ VO (overlay + `bg-[#242B32] rounded-[16px]`) ปุ่ม ghost/primary ตาม pattern `.claude/rules/08-shadcn-ui.md`

### 5.4 [F] Share modal = `General modal` เดิม (node `4354:866488`, 458×702)

ชิ้นนี้ **เป็น component เดิมทั้งหมด** ("Share to your friends" ใช้ในที่อื่นอยู่แล้ว) — spec เก็บไว้เพื่อยืนยันว่าไม่ต้องทำใหม่:
- `w 458 · p 16 · gap 24 · rounded 16 · bg #242B32 · backdrop-blur 4`
- Title row: "Share to your friends" Sub/Medium white + `X` 24 · divider
- Search input `h 42 · bg #242B32 · border rgba(255,255,255,0.2) · rounded 8 · px 12 py 8` icon Search 16 + placeholder "Search members" Body/Regular `#697384`
- Tab fill `border rgba(255,255,255,0.2) p 4 rounded 8 w 427`: DM (active `bg rgba(88,214,141,0.2) h 32 rounded 8`) / Group / Channel — Body/Regular white
- Member grid 4 คอลัมน์ × 4 แถว: cell `px 8 py 16 gap 8` avatar 40 (border rgba(255,255,255,0.2)) + ชื่อ Body/Regular center ellipsis
- Footer `border-t rgba(255,255,255,0.2) pt 16 gap 8`: "Clear all" / "Send" **disabled state** `bg #DBDFE3 border #B2BBC3 text #A3ADB8` h 42 rounded 8
- สิ่งที่ share = การ์ด "pet evolved" เข้า DM/Group/Channel → เปิด `Direct message - Full view` (หน้า Chat เดิม)

### 5.5 [G] Toast (node `4354:867868`, 336×72) — Toast เดิม

`bg #1A1B1E · p 16 · rounded 16 · drop-shadow` · icon button 40 `bg rgba(88,214,141,0.2) rounded 8` + `Check` 24 · "Share successfully." Body/Regular white · `X` 16 · ตำแหน่ง `top 24 right 24` — **reuse toast helper เดิม** ไม่สร้างใหม่

---

## 6. SC-PET-05 · Baby → Adult → Evolved — [node 4284-171408](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4284-171408)

**ไม่มี UI ใหม่** — 2 แถว (Title Flow):
- "คนที่ให้ XP สัตว์เลี้ยงเต็มจะเห็น Animation **Baby > Adult**"
- "คนที่ให้ XP สัตว์เลี้ยงเต็มจะเห็น Animation **Adult > Evolve**"

แต่ละแถว: VO ปกติ → Overlay + pet 320 กลางจอ (`Pet - dog baby 1` / `Pet - dog evo 1`) → แสงวาบเต็มจอ → วงกลมแสงหดกลับ center (asset 1000×1000 `dog evo evo 1` / `dog evo adult 2`) — sticky ทั้ง 2 แถว: "**อิง Animation ตาม SC-PET-04**"

**ข้อสังเกตสำคัญจาก title:** animation เต็มจอเล่นให้ **"คนที่ให้ XP จนเต็ม"** (คนที่ทำให้ข้าม threshold) เท่านั้น — คนอื่นในทีมได้ modal + notification ตาม SC-PET-07 · ต่างจาก ClickUp ที่บอกว่า broadcast animation ให้ทุกคนในห้อง → ดู [spec.md](spec.md)

- ไม่มี frame "Click to start evolve" ในแถวนี้ (มีแต่ใน SC-PET-04) แต่ sticky บอกอิง 04 → ตีความว่า **มี prompt คลิกก่อนเหมือนกัน**; ต้องยืนยันกับ design
- Grow/Evolve animation ระยะเวลา 4–6 / 6–8 วินาที (ClickUp) — Figma ไม่ระบุเวลา

---

## 7. SC-PET-06 · Pet Status = Pet menu panel — [node 4308-277780](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4308-277780)

**Sticky:** "Click ที่สัตว์เลี้ยง" (เปิด panel) · "Bubble จะแสดง Mood ของสัตว์เป็นระยะๆ" · "กรณีอยู่ Evolve stage + MAX XP แต่มีการปรับเปลี่ยน Stage ลงมา" (variant MAX)

### 7.1 Pet menu panel (node `4345:343306` Default, 320×599 · `4689:572008` Variant2 MAX, 320×595)

ตำแหน่ง: `top 24–25 · right 24` (x 1096 ใน 1440) ลอยทับ map มุมขวาบน **ไม่ดันแผนที่** — เหมือน popover ไม่ใช่ side panel เต็มความสูงแบบ Notification
**reuse shell:** รูปทรงตรงกับ `VOProfilePanel` (`views/user/virtual-office/components/vo-profile-panel.tsx` — `w-[322px] rounded-[16px] bg-[#242B32] p-[16px] gap-[16px] shadow-2xl`) มากกว่า member/notification panel (ที่เป็น `bg-[#2B3540]` ชิดซ้าย) → สร้าง `VOPetPanel` ด้วย shell เดียวกัน (`w-[320px]`) และ mount แบบ conditional ใน `hero-virtual-office.tsx` เหมือน profile panel · **ไม่ต้องเพิ่ม `VOSidebarTab`** เพราะ Figma เปิดจากการคลิก pet ไม่ใช่จาก rail

```
Pet menu   w 320 · bg #242B32 · p 16 · gap 16 · rounded 16 · flex-col
├─ Header (gap 16, items-start) + X 16 absolute (left 274, top 0)
│   ├─ Avatar circle 56×56 · bg #FFA8A8 · border 1 rgba(255,255,255,0.2) · rounded 90 · overflow-clip
│   │    └─ รูป pet (aspect 1:1, ล้นล่างเหมือน avatar profile เดิม)
│   └─ col (gap 4, flex-1)
│       ├─ ชื่อ pet                         Sub/Medium 16/22 white · ellipsis
│       ├─ row (gap 8): Progress h 4 flex-1 · bg rgba(26,27,30,0.5) · rounded 90 · fill gradient (60%)
│       │              + "350" Caption1/**SemiBold** white + "/500 XP" Caption1/Regular #8C99A6
│       └─ "150 XP to evolve next stage"    Caption1/Regular #8C99A6
├─ Stats row (2 cell เท่ากัน, p 8, gap 8, col center) · เส้นแบ่งกลาง border-r rgba(255,255,255,0.2)
│   ├─ [emoji 16 + "Happy" Body/Regular white] / "Mood" Caption1 #8C99A6
│   └─ [stage badge 16 (bg #8C99A6 "1") + "Egg" Body/Regular] / "Stage" Caption1 #8C99A6
├─ Streak banner  w-full · p 8 · gap 8 · rounded 8 · bg rgba(255,128,0,0.1) · center
│   └─ Fire 16 + "Together for 100 days. Keep it up"  Body/Regular #FF8000
├─ Divider (rgba(255,255,255,0.2))
├─ "Daily quest"   Sub/Medium 16/22 white
└─ Quest list (gap 16) — 5 แถว
    แถว (gap 8, items-center):
    ├─ icon tile  w 50 · h-full · rounded 8 · bg rgba(255,255,255,0.1) + ภาพ PNG · ตัวเลข "+5"/"+10" Pixelony 12 white text-shadow 0 1 0 black (ล่างกลาง)
    └─ col (gap 8, flex-1)
        ├─ ชื่อ quest   Body/Regular white
        └─ row justify-between
            ├─ "1" Body/**Bold** (#58D68D ถ้าครบ · white ถ้ายังไม่ครบ) + "/" + "1" Body/Regular #8C99A6
            └─ ปุ่ม h 24 · rounded 4 · bg rgba(255,255,255,0.05) · border rgba(255,255,255,0.2)
                 ├─ ครบแล้ว: "Complete"  px 8 py 4 · **opacity 50%** (disabled)
                 └─ ยังไม่ครบ: "Go to" + ChevronRight 16  px 8 py 6 (กดแล้วพาไปทำ)
```

Quest ตัวอย่างใน Figma (ตรงกับ 10 activities ของ PetManagement เพียงบางส่วน):

| Quest | XP | ตัวอย่าง | map → activity ใน `tb_pet_xp_config` |
|---|---|---|---|
| Daily login | +5 | 1/1 Complete | `xp_login_per_day` |
| Stay in workspace for 10 minutes | +5 | 1/1 Complete | `xp_office_10min` |
| React with an emoji | +5 | 1/10 Go to | `xp_react_message_fo_day` (`times` = 10) |
| Join a meeting | +10 | 1/1 Complete | `xp_team_meeting` |
| Send message | +5 | 1/5 Go to | `xp_10_message_fo_day` / `xp_first_message_fo_day` |

→ รายการต้อง **render จาก config จริง** (activity ที่ `enabled`) ไม่ hardcode 5 แถว · ตัวเลข XP ในภาพ (+5) เป็น mock ไม่ตรง default (1/2/6/10) — ห้ามลอก

**Variant2 — MAX XP** (`4689:572008`): Progress ใช้ `bg white` เต็ม 100% + "MAX" SemiBold white + " XP" #8C99A6 · **ไม่มี**บรรทัด "XP to evolve next stage" · ที่เหลือเหมือนเดิม — ใช้เมื่อ stage = evolved (และเคส admin ปรับ threshold ลง)

**เทียบกับ ClickUp layout:** ไม่มี Top 3 contributors · ไม่มีปุ่มลูบหัว/Feed ในพาเนล · มี Daily quest + streak แทน → design ใหม่กว่า card ยึด Figma

### 7.2 Mood bubble ซ้ำกับ §2.2 — 3 frame `Pet - Happy / Neutral / Sad` วาง Tooltips 32×32 ที่ (647, 717)

---

## 8. SC-PET-07 · Notification — [node 4354-854173](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4354-854173)

5 แถว (Title Flow):

| แถว | Flow ใน Figma |
|---|---|
| Stage Change : กรณีคนที่ให้ XP สัตว์เลี้ยงเต็ม | [แสงวาบ] → pet 320 + cursor → **Pet evolution modal** → VO → Notification panel มี card |
| Stage Change : กรณีคนในทีม | **Pet evolution modal โผล่เลย** (ไม่มี animation ไข่) → VO → Notification panel · sticky: "เฉพาะคนที่อยู่ใน Room และมี **Status Active ต้องไม่อยู่ใน Bubble**" — ในโค้ด: status ผ่าน `!optedOutOfSharedSpace(status)` (`lib/presence-status.ts`, ตัด busy/away/dnd) **และ** ไม่อยู่ใน proximity chat-space circle (`ChatSpaceCircle` / `vo-chat-space-overlay.tsx`) — "Bubble" ในระบบนี้คือวงคุยใกล้กัน ไม่ใช่ private zone |
| XP Milestone | VO → Notification panel เท่านั้น (ไม่มี modal/banner) |
| Daily Reminder | Loading "Connecting to Standard" → VO + **banner มุมซ้ายล่าง** → (variant มี X) → Notification panel |
| ปิด Notification ของสัตว์เลี้ยง | Setting → Notifications → toggle **PET / Pet activity** → Toast |

**Sticky:** "Hover เรียงลำดับความสำคัญ (มาก > น้อย) **Announcement > Pet Announcement** — Announcement จะโชว์ก่อนเสมอ เพราะสำคัญกว่า"

### 8.1 Notification panel (node `4354:870345`) — **panel เดิม** เพิ่ม card type

- panel เดิม: `w 320 · h 992 · bg #2B3540 · p 16 · gap 16 · rounded 16` ชิดซ้ายถัดจาก sidebar (`top 16`) · Title "Notification" Title/Bold + "Mark as read" (icon 12 + Caption1 #8C99A6) · Tab fill "View all"/"Unread" (active `bg rgba(88,214,141,0.2) h 32`) · section label "Today"/"Yesterday" Caption1/Regular
- Notification card เดิม: `p 8 · rounded 8 · h 96` · unread `bg rgba(255,255,255,0.05)` / read ไม่มี bg · ซ้าย icon 32 · ขวา Text (gap 8): title Body/Medium white + time Caption/Regular 12/16 #8C99A6 · body Body/Regular #8C99A6 (คำสำคัญเป็น white)
- **card ใหม่ (pet):** icon = `Group profile` 32×32 `rounded 90 p 4 bg #E1ADFF` + pet/paw icon (SVG `member`-style) · title **"Your team pet evolved"** · body **"Your pet has reached *a new stage*. Come see its new form!"** (ตัวเอนคือ white) · time "1 min ago"
- bell icon ใน sidebar: `Count number` badge `bg #D41818 rounded 90 top -4 right -4` ตัวเลข Caption2/Medium 10/14 white — ของเดิม
- XP milestone และ Daily reminder ใช้ card เดียวกัน เปลี่ยนแค่ข้อความ (Figma ไม่ได้วาด copy ของ 2 ชนิดนี้ใน panel — ใช้ข้อความจาก ClickUp)
- กด card → navigate ไปห้องนั้น (ClickUp) — Figma ไม่มี state hover/press ของ card
- **reuse:** `VONotificationPanel` + `NotificationCard` + `TYPE_META` + `typeLabel()` ใน `views/user/virtual-office/components/vo-notification-panel.tsx` — เพิ่ม type ใหม่ใน `NotificationType` (`lib/api/chat.ts`) และ accent ใน `TYPE_META`
  - ⚠️ card ในโค้ดใช้ `ChatAvatar size={32}` + badge ชนิดมุมขวาล่าง 16px (icon 10px สี accent) ไม่ใช่วงกลม `bg #E1ADFF` เต็มใบตาม Figma → pet card ต้องเพิ่ม branch "icon-only avatar" (วงกลม 32 `bg-[#E1ADFF] p-[4px]` + pet icon) ใน `NotificationCard` ไม่ fork component · unread `bg-[rgba(255,255,255,0.05)]` / hover `bg-[rgba(255,255,255,0.08)]` ตามเดิม

### 8.2 Daily reminder banner (node `4422:228432`, 353×124 ที่ `left 65.5 top 896` = มุมซ้ายล่าง)

```
Frame 353×124 (absolute, ล่างซ้ายทับขอบ sidebar)
├─ กล่องข้อความ  absolute left 92 · top 26 · w 266 · h 72
│    bg #242B32 · border 1 solid #FFFFFF · rounded-r 16 (ซ้ายเหลี่ยม) · pl 32 pr 16 py 8 · items-center
│    ├─ "Team pet is waiting for you. Come visit and earn some XP!"   Body/Regular white · flex-1
│    └─ X 16  absolute right 10 top 8   (variant 2 เท่านั้น — variant 1 ไม่มีปุ่มปิด)
└─ Avatar block 124×124 (absolute left 0 top 0, ทับกล่องข้อความด้านซ้าย)
     ├─ วงกลม 80×80 rounded 90 กึ่งกลาง: รูป avatar profile + overlay rgba(0,0,0,0.5) + **pet 56×56** ตรงกลาง
     └─ "Vine Decoration 2" PNG 120×120 ทับขอบวงกลม (aspect 150/150)
```

- **นี่คือ Announcement banner แบบ "No require acknowledge" ตาม Figma** (frame ชื่อ `Announcement - No require acknowledge` ใช้ `Idle UI`) — reuse ทั้งชิ้น เปลี่ยน avatar → pet + vine และข้อความ
  - ⚠️ โค้ดปัจจุบันของ announcement (`views/user/virtual-office/components/announcement/announcement-card.tsx` = card `w-[322px] rounded-[16px] bg-[#242B32]` + ปุ่มปิดวงกลม 28px, orchestrate โดย `announcement-gate.tsx` `AnnouncementGate`, dismiss เก็บใน `lib/announcement-dismiss.ts`) **ไม่ใช่รูปทรง avatar+vine มุมซ้ายล่างแบบใน Figma** → ต้องเช็คก่อนว่า banner แบบ Figma นี้ implement แล้วหรือยัง (ค้นชื่อ `Vine Decoration`) ถ้ายัง = ชิ้นใหม่ที่ทั้ง Announcement และ Pet ใช้ร่วมกัน ห้ามทำเฉพาะ pet
- ลำดับแสดง: ถ้ามี Announcement จริงค้างอยู่ ให้ Announcement ขึ้นก่อน pet reminder (sticky) → ต่อคิวผ่าน `AnnouncementGate` ไม่ทำ queue แยก
- แสดงหลังเข้า VO ครั้งแรกของวัน (จาก loading) · ClickUp: cron 9:00 ICT + ครั้งเดียว/วัน

### 8.3 Setting → Notifications (node `4369:309920`, 934×800) — **Setting modal เดิม** เพิ่ม 1 section

- modal `934×800 rounded 16`: เมนูซ้าย `w 238 p 16 gap 16 bg #242B32 backdrop-blur 4` (Profile / General / Audio / **Notifications** active `bg rgba(88,214,141,0.1)` text `#58D68D` / Manage member / Integrations / Environment) · เนื้อหาขวา `bg #2B3540 p 16 gap 16`
- Title "Notifications" Title/Bold + desc "Manage your notification preferences for updates, messages, and calendar events." Body/Regular #8C99A6 + X 24 · divider
- Section label Body/Medium **#8C99A6 uppercase**: `MESSAGES` → `MEETING & CIRCLE` → `CALENDAR` → **`PET`** → `ACTIVITIES` (คั่นด้วย divider, gap 24)
- **row ใหม่ใน PET:** title "Pet activity" Body/Medium white · desc "Stay updated on your pet's progress, milestones, and evolution." Body/Regular #8C99A6 · **Switch 48×24** (component เดิม) default **on**
- กด toggle → Toast เดิม (336×72 `top 24 right 24`) — ข้อความไม่ได้ระบุใน Figma (ใช้ pattern เดียวกับ toggle อื่นใน Setting)
- **มีอยู่แล้วในโค้ด — แค่เปิด:** `NOTIFICATION_SECTIONS` ใน `views/user/virtual-office/components/vo-setting-modal.tsx` มี section `notifSectionPet` + row `{ source: "notif", field: "pet_activity", labelKey: "notifPetActivityLabel", descKey: "notifPetActivityDesc" }` ติด **`hidden: true`** (comment: "Pet feature has not launched") · field `NotificationSettings.pet_activity` (default `true`) อยู่ใน `lib/api/profile.ts` · store `stores/notification-settings-store.ts` · API `GET/PATCH /api/user/me/notification-settings` → งานคือเอา `hidden` ออก (filter `VISIBLE_NOTIFICATION_SECTIONS`) และเช็คว่า i18n key 2 ตัวมีข้อความตรง Figma ("Pet activity" / "Stay updated on your pet's progress, milestones, and evolution.")
- `ToggleRow` เดิม = Switch `h-[24px] w-[48px] rounded-full` on `bg-[#58D68D]` off `bg-[rgba(255,255,255,0.2)]` knob 20px — ตรง Figma 48×24 แล้ว

---

## 9. SC-PET-08 · Neglected State — [node 4372-310825](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4372-310825)

**ไม่มี UI ใหม่** — 3 แถว Happy / Neutral / Sad แต่ละแถวมีป้าย `ANIMATION` + ห้องซูมที่วาง sprite 120×120: `shiba - happy 1` · `shiba - Neutral 1` · `shiba - sad 1`

- Happy = slot `Happy` · Sad = slot `Sad` · **Neutral ไม่มี slot** → ใช้ `Walking`/`Sitting` ปกติ (ClickUp: "animation ช้าลง" → ลด `animationSpeed`)
- mood ที่แสดงบน nameplate/bubble/panel มาจาก 3 emoji ใน §2.2
- ไม่มี "recovery animation" แยกใน Figma → ใช้ `Happy` ตาม SC-PET-03

---

## 10. Reuse map — component VO เดิมที่ต้องแก้ (ห้ามสร้างใหม่)

path เทียบจาก `zyra-app/` · สำรวจ 2026-09-02 (บรรทัดอาจเลื่อน — `grep` ชื่อ symbol ก่อนแก้)

| ของใหม่ | ต่อยอดจาก | สิ่งที่เพิ่ม |
|---|---|---|
| Pet sprite บน map | `zyra-engine/pixi-game/scene.ts` (`PixiGameScene`) · z-order `encodeZ` / `sortRowDrawOrder` ใน `zyra-engine/pixi-game/utils.ts` · walkable = **ไม่ใส่** ลง `blockedTiles` | entity ชนิด `pet` เล่น spritesheet จาก `PetAnimation` (`lib/api/pets.ts`) ตาม slot · ใช้ slot 0 (regular) ของ `sortRowDrawOrder` เพื่อให้ avatar เดินทับได้ตามแถว |
| Pet nameplate | `makeNameTag()` `utils.ts` + `_updateNameTag()` `scene.ts` + `NAME_TAG_*` `pixi-game/constants.ts` | option `leadingIcon` / `trailingEmoji` / `progress` · bg ตาม peer pill (`0x141420 @0.88`) |
| Mood bubble | `makeTalkingBubble()` `utils.ts` + `_updateTalkingBubble` + `TALKING_BUBBLE_*` | เนื้อใน emoji 16px · สี `0x1a1b1e` p 8 radius 8 ตาม Figma · interval const |
| Tooltip คีย์ลัด `Press [P] pet` / ♥ / `+5 XP` | DOM overlay pattern `PZZoneHover` (`views/user/virtual-office/components/pz-zone-hover.tsx`) — screen-space, `pointer-events` discipline | component ใหม่ตัวเดียว `PetTooltip` 3 variant (`key` / `emoji` / `xp`) Tailwind ล้วน |
| Minimap pet dot | `VOMinimap` + `PlayerDot` + `MinimapContent` (`vo-minimap.tsx`) | prop `petDots` · ขนาดสเกลตาม `dotSize` |
| Pet menu marker (ปุ่มมือ) | DOM overlay ตาม `PZZoneHover` · สี/ทรงตาม popover ใน `vo-hud.tsx` (`rounded-[8px] bg-[#242B32]`) | ปุ่ม `Hand` 16px 1 ปุ่ม (32×32) |
| Pet menu panel | shell `VOProfilePanel` (`vo-profile-panel.tsx`: `w-[322px] rounded-[16px] bg-[#242B32] p-[16px] gap-[16px] shadow-2xl`) · progress = geometry จาก `components/workspace-loading-screen.tsx` (`rounded-[90px]` gradient `#58d68d→#8fe4b3`) | `VOPetPanel` ใหม่ (เนื้อใน §7.1) mount ใน `hero-virtual-office.tsx` แบบ conditional เหมือน profile panel |
| Stage badge (Egg `#8C99A6` / Baby `#2DB6FF`) | สูตรสีของ `ObjectTypeBadge` (`views/admin/object-management/components/object-type-badge.tsx`: bg `color+1A`, border `color+33`) | `PetStageBadge` ใหม่ 16×16 rounded-4 ตัวเลข Caption2/Semi — ยังไม่มี stage badge ที่ไหนในระบบ |
| Overlay hatch/evolve | overlay `rgba(0,0,0,0.5)` เดิมของ modal ใน VO | pet 320 + text + cursor · เล่น slot `Evolution` |
| Pet evolution modal | modal shell เดิม (`bg-[#242B32] rounded-[16px]`) + ปุ่มตาม rule 08 | เนื้อใน §5.3 |
| Share modal / Toast / DM view | Share modal เดิมของ Chat · `zyraToast` (`lib/toast.tsx` — ตรง Figma Toast: `bg-[#1a1b1e] rounded-[16px] p-[16px]` icon box 40 สี 20%, duration 4000ms) · หน้า Chat | **ไม่แก้** เรียกด้วย payload การ์ด pet |
| Notification card | `NotificationCard` + `TYPE_META` + `typeLabel()` (`vo-notification-panel.tsx`) · `NotificationType` (`lib/api/chat.ts`) · store `stores/chat-store.ts` | type `pet_stage_change` / `pet_xp_milestone` / `pet_daily_reminder` · accent + branch icon-only avatar `bg-[#E1ADFF]` |
| Daily reminder banner | `AnnouncementGate` (`announcement/announcement-gate.tsx`) จัดคิว · surface ต้องเช็ค (`announcement-card.tsx` ปัจจุบันเป็น card 322 ไม่ใช่ทรง avatar+vine) | ถ้ายังไม่มี banner ทรง Figma → ทำเป็น shared component ให้ Announcement ใช้ด้วย |
| Setting → Notifications → PET | `vo-setting-modal.tsx` `NOTIFICATION_SECTIONS.notifSectionPet` (มีแล้ว `hidden: true`) · `NotificationSettings.pet_activity` (`lib/api/profile.ts`) · `stores/notification-settings-store.ts` | เอา `hidden` ออก + ตรวจ i18n copy |
| Gate banner/modal ด้วย status | `optedOutOfSharedSpace()` (`lib/presence-status.ts`) + `ChatSpaceCircle` (`zyra-engine/types.ts`, `vo-chat-space-overlay.tsx`) | เงื่อนไข "Active และไม่อยู่ใน bubble" |
| Avatar เดินไปหา pet (SC-PET-03 อยู่ไกล) | `PlayTestHandle.walkAdjacentTo` / `isTileWalkable` / `getBlockedTiles` (`zyra-engine/types.ts`) + `lib/zone-utils.ts` | เรียกด้วย tile ของ pet |
| Object ที่ pet นั่งได้ | ปัจจุบัน `isSittable = obj.type === "sofa"` ใน `zyra-engine/assets/tile-builder.ts` → `SpriteTile.sittable` · `isTileSittable()` | `pet_sittable` **ไม่มีในระบบ** — ถ้าต้องมีเป็น flag ใหม่บน `tb_object` + `ObjectItem` (`lib/api/objects.ts`) หรือ derive ใน `tile-builder.ts` |
| Feature flag | `isPetManagementEnabled()` (`lib/pet-feature.ts`, `NEXT_PUBLIC_PET`) ใช้แค่ admin sidebar | **ทำแล้ว 2026-09-02:** `isRoomPetEnabled()` (`lib/room-pet-feature.ts`, `NEXT_PUBLIC_ROOM_PET`, default false) — ทุก component ในเอกสารนี้ต้อง `return null` เมื่อปิด และ hook/API caller ต้องเช็คก่อนทำงาน |

> **สิ่งที่พบว่าโค้ดยังไม่ตรง PetManagement:** `PetAnimationSlot` ใน `lib/api/pets.ts` ยังมี `"Idle"` (20 slot) ทั้งที่ spec ถอดแล้ว 2026-09-01 — อยู่ในรายการแก้ของ [PetManagement/spec.md § ผลต่อโค้ด](../PetManagement/spec.md) แล้ว ไม่ต้องเปิดงานซ้ำ

---

## 11. คำถามถึง Design/PM ที่เกิดจากการดึง Figma รอบนี้

1. **Egg stage มี nameplate ไหม** — symbol `Pet in map` (egg) ไม่มี `Display on avatar head` แต่ variant 2 (dog) มี → ตั้งใจหรือหลุด
2. **สี stage badge Adult / Evolved** — Figma มีแค่ Egg `#8C99A6`, Baby `#2DB6FF`
3. ~~**สี pet dot บน minimap**~~ — **ปิดแล้ว 2026-09-02**: อ่านจาก SVG `Ellipse 4` ได้ `#996ADF` (Purple/500) — ClickUp ที่เขียน "สีชมพู" ตกไป · ขนาดสเกลตาม `dotSize` ด้วย ratio 6/14
4. **Mood bubble ความถี่** — sticky บอก "อาจจะ 30 วิ : ครั้ง (ค่อยกำหนด)"
5. **Pet menu panel ≠ ClickUp SC-PET-06** (ไม่มี Top 3 / ปุ่มลูบหัว / Feed แต่มี Daily quest + streak "Together for N days") — streak ต้องมี field ใหม่ (วันที่วาง pet → นับวัน?) ยังไม่มีใน schema
6. **SC-PET-05 ต้องคลิกก่อนเริ่ม animation เหมือน 04 ไหม** — sticky บอก "อิง 04" แต่ไม่มี frame prompt
7. **Toast หลัง toggle Pet activity** — ข้อความอะไร
8. **ไม่มีปุ่ม Pet บน HUD / bottom menu** ในทุก frame — ClickUp บอกมี "Pet icon บน HUD" → ตัดหรือเพิ่ม
9. **Prestige XP** — Figma ใช้ `MAX XP` (บาร์ขาวเต็ม) ไม่มีสี prestige
10. **font Pixelony** สำหรับตัวเลข +5 บน quest tile — มีใน repo หรือต้องเพิ่ม font asset (กระทบ bundle)
11. **สี nameplate pet** — Figma `#242B32` แต่ peer pill ในโค้ดวาด `0x141420 @0.88` อยู่แล้ว (เบี่ยงจาก Figma ตั้งแต่ avatar) → pet ตาม Figma หรือตามโค้ด (เสนอตามโค้ดเพื่อความกลมกลืน แล้วให้ design ตัดสินทีเดียวทั้ง avatar และ pet)
12. **Daily reminder banner ทรง avatar+vine** — ยังไม่พบใน `announcement/*` ของโค้ด (ปัจจุบันเป็น card 322px) → design ยืนยันว่า banner นี้คือของ Announcement ที่ยังไม่ทำ หรือของ pet โดยเฉพาะ

---

## Reference

- [spec.md](spec.md) — flow + business rules + จุดขัดกับ PetManagement
- [PetManagement/ux-ui.md](../PetManagement/ux-ui.md) — token ชุดเดียวกันฝั่ง admin · slot vocabulary sprite
- Figma sections: [01](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4206-126170) · [02](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4215-519205) · [03](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4256-567590) · [04](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4280-151858) · [05](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4284-171408) · [06](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4308-277780) · [07](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4354-854173) · [08](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=4372-310825)
- Sub-node ที่ดึง design context: `4215:324550` `4250:565368` `4215:519137` `4381:406266` `4256:570663` `4256:570876` `4261:588071` `4689:564658` `4284:167462` `4287:179918` `4354:866488` `4354:867868` `4345:343306` `4689:572008` `4345:852999` `4354:870345` `4369:309920` `4422:228432`
