# SC-AV-02 — Avatar Customization (Client)

> **สถานะ: Implementing (รอบ 7) — โค้ดอยู่บน `feat/avatar-customize` ทั้ง 3 repo ยังไม่ commit · ดู [progress.md](progress.md) · มติแล้ว: paper-doll (Q-1), ต่อ workspace (C-14), Skin = Default ไม่อัปโหลด (C-13), 18 หมวด (Q-5) — §8.3 · skin 5 เฉด (Q-4b) · ยังติด Q-4c (ค่าสี) · ฝั่ง Admin ทำตามมติ C-14 แล้ว (zyra-api#185 + zyra-ws#87 — `tb_user_outfit` PK `(user_id, workspace_id)`)**
> วันที่: 2026-10-22 · ผู้เขียน: rif (ผ่าน Claude Code)
> ClickUp: [[Module] Avatar Customization (Client)](https://app.clickup.com/t/86d43pc9w) — status `in progress`, priority High, due 2026-10-19 (เลยกำหนดแล้ว), tag `client`, Desktop ✓, assignee: P A, rif fullstack
> โมดูลคู่ฝั่ง Admin: [[Module] · Avatar & Accessories Management (Admin)](https://app.clickup.com/t/86d43pbbj) (SC-AV-01) — `in progress`
> **ระบบเป้าหมายฝั่ง Admin:** [`../[Module] Avatar & Accessories Management (Admin)/`](<../[Module] Avatar & Accessories Management (Admin)/>) — technical-design, requirements, data contract ฝั่ง member (`data/`) · อ้าง `AvatarCustomization/technical-design.md` (มติ 2026-10-05) ที่**ยังไม่ขึ้น git** — ถ้าผู้เขียนเดิม push โฟลเดอร์นี้ขึ้นมา ต้องรวมกับไฟล์นี้ (Q-3)
> **เอกสารในโฟลเดอร์นี้:** [technical-design.md](technical-design.md) (ต้นฉบับระบบ paper-doll 2026-10-05) · [technical-design-member.md](technical-design-member.md) (ฝั่ง member SC-AV-02 บน develop — 2026-10-22) · [ux-ui.md](ux-ui.md) (ค่า Figma `pQlFqPDRdEsTAVnfOrcO5h` canvas `7454:438285`)
> เอกสารที่เกี่ยวข้อง: [`../AvatarManagement/SC-AV-01-user-count-fix.md`](../AvatarManagement/SC-AV-01-user-count-fix.md) · [`../VirtualOffice/`](../VirtualOffice/) · [`../Real-time-Engine/`](../Real-time-Engine/)

เอกสารนี้แยก 4 ชั้นข้อมูลชัดเจน — **อย่าปนกัน**:

| ชั้น | หัวข้อ | ใครเป็นเจ้าของ |
|---|---|---|
| Requirement ต้นทาง | §3, §4 (ถอดจาก ClickUp / Figma แทบคำต่อคำ) | PM / Designer |
| Current implementation | §5 (ตรวจโค้ดจริง 2026-10-22 + PR Admin ที่กำลังทำ) | โค้ด |
| ระบบเป้าหมายที่ทีมกำลังสร้าง | §6 (สรุปจากเอกสาร Admin — ไม่ใช่ ClickUp SC-AV-02) | Ten / เอกสาร Admin |
| Gap + ข้อขัดแย้ง | §7, §8 | — |
| ข้อเสนอของ Agent | §9 (**ยังไม่ใช่ decision**) | รอทีมอนุมัติ |

---

## 0. สรุปสั้น

- **ต้องการ:** member แต่งตัว avatar ได้ = เลือก **Skin** 1 อัน + สวม **Accessories** แยก slot (Hat / Glasses / Outfit / Bag / Wings) มี **preview realtime** → บันทึก → avatar ใน VO เปลี่ยนให้ทุกคนเห็นภายใน **2 วินาที** · ตั้งค่า **แยกต่อ workspace** (1 avatar ต่อ user ต่อ workspace)
- **ของจริงตอนนี้:** ระบบเป็น "เลือก character ทั้งตัว" (`tb_avatar` 1 แถว = spritesheet ครบตัว) ไม่มีแนวคิด skin/accessory แยกชั้น · การเลือกเป็น **global ต่อ user** (`tb_user_avatar` PK = `user_id`) · preview เป็นภาพนิ่ง · ไม่มี WS event สำหรับ avatar (อาศัย `avatar_url` ใน `moved`)
- **ระบบที่ทีมกำลังสร้างจริง (ฝั่ง Admin, §6):** แบบ **paper-doll** — base `body` 1 ตัว + ชิ้นส่วน 18 หมวดตาม Figma วาดด้วยสี key แล้วเปลี่ยนสีด้วย palette · **server bake** เป็นชีทเดียวต่อชุด (VO/ws ยังรับ URL เดียวเหมือนเดิม) · schema `tb_avatar_part` / `tb_user_outfit` อยู่ใน PR zyra-api#179 (ยังไม่ merge) · member API มีแค่ข้อเสนอ `/api/user/avatar/*`
- **มติ 2026-10-22 (rif):** ระบบ **ประกอบเป็นชิ้น (paper-doll) 18 หมวด** ตามทีม Admin · **ชุดแยกต่อ workspace** ตาม ClickUp (`tb_user_outfit` ต้องเป็น PK `(user_id, workspace_id)` — แก้ใน zyra-api#179 ก่อน merge) · **Skin = Default ไม่อัปโหลด** — ชีท body ตัวเต็ม + ระบบดูดสีผิว 4 เฉดจากชีทเอง · ถูกลบออกจากสมาชิกแล้วกลับมา = ชุดเดิมยังอยู่ · รายละเอียด §8.3, §9.2–9.3
- **ข้อเสนอ (§9):** ให้ SC-AV-02 เป็น "ฝั่ง member" ของระบบ paper-doll เดียวกัน (ไม่สร้างระบบที่สอง) แล้วแก้ ClickUp SC-AV-02 ให้ตรง — ข้อเสนอรอบแรก (5 slot + renderer หลาย layer ใน VO) **ถอนแล้ว**
- ข้าม 3 repo (`zyra-api`, `zyra-ws`, `zyra-app`) · ขึ้นกับงาน Admin (PR #179/#180/#638/#639 + branch API-3~5)

---

## 1. Source

### 1.1 ClickUp — SC-AV-02 (Client)

| Scenario | ClickUp | Status | Priority | Figma node |
|---|---|---|---|---|
| Parent | [86d43pc9w](https://app.clickup.com/t/86d43pc9w) | in progress | High | — |
| SC-AV-02-HP-01 เปิด Avatar Customization | [86d43pcc0](https://app.clickup.com/t/86d43pcc0) | pending | High | `7454:600826` |
| SC-AV-02-HP-02 เลือก Skin | [86d43pcdt](https://app.clickup.com/t/86d43pcdt) | pending | High | `7454:600826` |
| SC-AV-02-HP-03 เลือกและสวม Accessories | [86d43pcg6](https://app.clickup.com/t/86d43pcg6) | pending | High | `7621:209204` |
| SC-AV-02-HP-04 ถอด Accessory (เลือก None) | [86d43pchv](https://app.clickup.com/t/86d43pchv) | pending | Normal | `7648:348156` |
| SC-AV-02-HP-05 บันทึก Avatar และอัปเดต VO | [86d43pcjp](https://app.clickup.com/t/86d43pcjp) | pending | High | `7698:83967` |
| SC-AV-02-HP-06 Avatar ต่าง Workspace | [86d43pckw](https://app.clickup.com/t/86d43pckw) | pending | Normal | `7698:146753` |
| SC-AV-02-EP-01 บันทึกไม่สำเร็จ (Network Error) | [86d43pcmv](https://app.clickup.com/t/86d43pcmv) | pending | Normal | `7698:183253` |
| SC-AV-02-EC-02 Skin/Accessory ที่ใช้อยู่ถูก Admin ซ่อน | [86d43pcp7](https://app.clickup.com/t/86d43pcp7) | pending | Normal | `7698:188932` |
| SC-AV-02-EC-03 หลาย Tab เปิด Customizer พร้อมกัน | [86d43pctk](https://app.clickup.com/t/86d43pctk) | pending | Low | `7709:208066` |

> ⚠ **ID ไม่ตรงกัน:** ตารางใน parent เรียก edge case ว่า `EC-01` / `EC-02` แต่ชื่อ subtask จริงเป็น `EC-02` / `EC-03` (ไม่มี `EC-01`) — เอกสารนี้ใช้ **ชื่อตาม subtask** (ดู §8 C-1)

Figma file: `Map8gX0L2hk7HnkaFRfhtj` (Zyra design — More Organised ver.) — ลิงก์ node ทั้งหมดมาจาก ClickUp

### 1.2 ClickUp — SC-AV-01 (Admin) ที่ spec นี้อ้างถึง

| Scenario | ClickUp | Status | ใช้ใน spec นี้เรื่อง |
|---|---|---|---|
| Parent (Avatar Model / Architecture) | [86d43pbbj](https://app.clickup.com/t/86d43pbbj) | in progress | นิยาม Skin / Accessory / slot |
| SC-AV-01-HP-02 Upload Skin | [86d43pbne](https://app.clickup.com/t/86d43pbne) | Closed | spritesheet spec, `idle_s`, Default skin |
| SC-AV-01-HP-03 Upload Accessory | [86d43pbv6](https://app.clickup.com/t/86d43pbv6) | in progress | overlay PNG, offset x/y ต่อทิศ |
| SC-AV-01-HP-05 Hide/Unhide | [86d43pc2z](https://app.clickup.com/t/86d43pc2z) | in progress | พฤติกรรม hidden → EC-02 |
| SC-AV-01-HP-06 ลบ Skin/Accessory | [86d43pc3z](https://app.clickup.com/t/86d43pc3z) | in progress | reset slot เมื่อ item ถูกลบ |
| SC-AV-01-EC-02 ลบ Item ที่มี user ใช้จำนวนมาก | [86d43pc8w](https://app.clickup.com/t/86d43pc8w) | Closed | async reset + WS broadcast |

> SC-AV-02-EC-02 อ้าง **"SC-AV-01-EC-01"** แต่ใน ClickUp มีแค่ `SC-AV-01-EC-02` (ตาราง parent เรียกมันว่า EC-01) → ถือว่าหมายถึง [86d43pc8w](https://app.clickup.com/t/86d43pc8w)

### 1.3 สิ่งที่ยังไม่ได้อ่าน

- **Figma:** อ่าน metadata ได้แค่ node `7454:600826` (HP-01/HP-02) — node อื่น 6 ตัว **ติด rate limit ของ Figma MCP (Collab seat)** ยังไม่ได้ดู → ค่า px/สี/ข้อความ UI ยังไม่ได้ถอด ต้องทำใน `ux-ui-plan.md` รอบถัดไป (ฝั่ง Admin ถอด Figma ของตัวเองครบแล้วใน `ux-ui-plan.md` ของ Admin — node คนละชุดกับ SC-AV-02)
- ClickUp ไม่มี comment และไม่มี attachment ใน parent/subtask ทุกตัว

---

## 2. Scope

### 2.1 In scope (ตาม ClickUp SC-AV-02)

- Panel แต่งตัว avatar ฝั่ง member: เปิด/ปิด, preview animated, Skin picker, Accessories 5 slot, None/ถอด, บันทึก/ยกเลิก
- เก็บค่าแต่งตัว **ต่อ (user, workspace)**
- Broadcast การเปลี่ยน avatar ให้คนใน workspace เห็นภายใน 2 วินาที
- Error handling ตอน save (retry 1 ครั้ง + toast)
- จัดการกรณี item ถูก admin ซ่อน
- หลาย tab → last-write-wins + sync preview

### 2.2 Out of scope (ของ SC-AV-01 Admin หรือไม่ได้ระบุ)

- Upload / แก้ / ซ่อน / ลบ skin & accessory (SC-AV-01) — **แต่เป็น dependency** (§11)
- การซื้อ/ปลดล็อก item — Admin parent ระบุ "ให้ user เลือกใช้ได้ฟรีทั้งหมด"
- Mobile — custom field มีแค่ `Desktop` ✓ (ดู Q-12 เรื่องหน้า mobile เดิม)
- ของที่มีใน Figma แต่ไม่มีใน ClickUp (21 หมวด, palette สี, preset slot, Special costume) — **รอตัดสิน** (§8 C-3, Q-1, Q-8) · ทีม Admin เลือกทาง Figma (18 หมวด + palette) ไปแล้ว — ดู §6

---

## 3. Requirement ต้นทาง — ภาพรวม (ClickUp)

### 3.1 Overview & Goal (parent 86d43pc9w)

> User เลือก Skin และตกแต่ง Avatar ด้วย Accessories ก่อนเข้า Virtual Office แต่ละ workspace มี avatar setting แยกกัน (**1 avatar ต่อ user ต่อ workspace**)

Flow หลัก:

1. เลือก Skin (color/style variant)
2. ตกแต่งด้วย Accessories (Hat, Glasses, Outfit, Bag, Wings)
3. Preview realtime
4. บันทึก → Avatar อัปเดตทันทีใน Virtual Office

Persona: Workspace Member · Module: Client

### 3.2 Avatar Model (จาก Admin parent 86d43pbbj)

```
Base Character (1 ตัวสำหรับ platform — ทุกคนใช้ตัวเดียวกัน)
     │
     ├── Skins (Color/Style variants: สีผิว, สีผม, ชุด base)
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
           └── Wings   → Angel / Fairy / ...   (Admin parent เรียก "Wings/Cape")
```

### 3.3 Asset spec ที่ client ต้อง render (จาก SC-AV-01-HP-02 / HP-03)

**Skin spritesheet** (SC-AV-01-HP-02):

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
Total: width = frames × 64px, height = states × 64px
```

- Thumbnail auto-generate จาก frame แรกของ `idle_s` (400×400px)
- "Default" skin: ลบ/ซ่อนไม่ได้ (ต้องมีอย่างน้อย 1 skin active เสมอ)

**Accessory overlay** (SC-AV-01-HP-03):

- Category: Hat / Glasses / Outfit / Bag / Wings
- PNG overlay ≤ 2MB, upload แยก 4 ทิศ (4 ไฟล์) หรือ spritesheet รวม 4 ทิศ
- **Slot position: offset x/y ต่อ direction** (มีปุ่ม copy offset ของ South ไป N/E/W)
- Thumbnail จาก South frame แรก
- ชื่อ unique ภายใน category

**Hide / Delete** (SC-AV-01-HP-05 / HP-06 / EC-02):

- Hidden: หายจาก user picker ทันที (ไม่ต้อง reload) · user ที่ใช้อยู่ **ยังใช้ต่อได้** จนกว่าจะเปลี่ยนเอง
- Deleted (soft, `status = deleted`): slot ของ user ที่ใช้อยู่ถูก clear → skin กลับ Default / accessory slot ว่าง · ทำเป็น async batch 100 users · user online เห็นเปลี่ยนทันที (WS broadcast) · offline เห็นตอนเข้า VO ครั้งหน้า · hard delete asset หลัง 30 วัน

---

## 4. Requirement ต้นทาง — Scenario & Acceptance Criteria (ClickUp)

> AC ถอดจาก ClickUp โดยคงความหมายเดิม · ใส่รหัส `AC-<scenario>-<n>` เพื่ออ้างใน test-plan · ข้อความในวงเล็บ *[หมายเหตุ]* เป็นของผู้เขียน spec ไม่ใช่ของ PM

### SC-AV-02-HP-01 · เปิด Avatar Customization

- **Persona:** Workspace Member · **Pre-condition:** User login อยู่ใน Workspace

**Steps**

1. User กด avatar ของตัวเองบน Workspace sidebar หรือ Virtual Office HUD
2. หรือเข้า **Workspace Settings → Avatar**
3. **Avatar Customization panel** เปิด (modal หรือ side panel)
4. แสดง avatar preview ปัจจุบันของ workspace นั้น
5. แบ่งส่วน: Skin picker + Accessories slots + preview

**Layout ตัวอย่าง (ClickUp)**

```
🎨 แต่งตัว Avatar — Workspace: HPK Technology
┌──────────────────────────────────────────────────┐
│              [Avatar Preview]                    │
│           (animated, idle_s stance)              │
├──────────────────────────────────────────────────┤
│  Skin                                            │
│  [Def] [Tan] [Dark] [Oliv] [...]                 │
├──────────────────────────────────────────────────┤
│  Accessories                                     │
│  [Hat🎩] [Glasses👓] [Outfit👕] [Bag🎒] [Wings🪽]  │
│  Hat:  [None] [A] [B] [C]                        │
├──────────────────────────────────────────────────┤
│                [บันทึก]  [ยกเลิก]                │
└──────────────────────────────────────────────────┘
```

**Acceptance Criteria**

| ID | เกณฑ์ |
|---|---|
| AC-HP01-1 | เปิดได้จาก: Avatar icon บน sidebar / Virtual Office HUD / Workspace Settings |
| AC-HP01-2 | Avatar Preview แสดง animated `idle_s` ด้วย skin + accessories ปัจจุบัน |
| AC-HP01-3 | โหลด skin + accessories list ทั้งหมดที่ `status = active` |
| AC-HP01-4 | Current selection highlight ชัดเจน (border สีฟ้า) |
| AC-HP01-5 | Workspace label แสดงชัด: "แต่งตัว Avatar สำหรับ [ชื่อ Workspace]" |
| AC-HP01-6 | ปิด panel: กด X หรือ ESC หรือ click นอก panel *[ดู §8 C-6 — ขัดกับ confirm ตอนยกเลิกของ HP-05]* |

### SC-AV-02-HP-02 · เลือก Skin

- **Pre-condition:** Avatar Customization panel เปิดอยู่

**Steps**

1. User เห็น Skin section: grid ของ skin thumbnails ทั้งหมดที่ Active
2. User กด skin ที่ต้องการ
3. **Avatar Preview อัปเดตทันที** — เปลี่ยน skin ใน preview โดยยังไม่บันทึก
4. Skin ที่เลือก: border สีฟ้า highlight
5. Accessories ที่สวมอยู่ยังคงแสดงบน skin ใหม่

**Acceptance Criteria**

| ID | เกณฑ์ |
|---|---|
| AC-HP02-1 | Skin grid แสดง thumbnail + ชื่อ ทุก skin ที่ `status = active` |
| AC-HP02-2 | กด skin → Preview อัปเดตทันที ไม่ต้อง confirm |
| AC-HP02-3 | Preview แสดง `idle_s` animation ด้วย skin ใหม่ + accessories เดิม |
| AC-HP02-4 | Skin ที่กำลัง selected: border/check icon highlight |
| AC-HP02-5 | Skin ที่ใช้อยู่ปัจจุบัน (saved): badge "ปัจจุบัน" เล็กๆ |
| AC-HP02-6 | Skin grid scroll ได้ถ้ามีมากกว่า 1 แถว |
| AC-HP02-7 | Default skin แสดงเป็นตัวแรกเสมอ (`sort_order = 0`) *[มติ C-13 รอบ 4: skin = Default ไม่อัปโหลด — §9.3]* |

### SC-AV-02-HP-03 · เลือกและสวม Accessories

- **Pre-condition:** panel เปิด, Skin เลือกแล้ว

**Steps**

1. User กด tab category: **[Hat] [Glasses] [Outfit] [Bag] [Wings]**
2. แสดง accessories ใน category นั้น พร้อม "None" (ไม่สวม) เป็นตัวเลือกแรกเสมอ
3. User กด accessory ที่ต้องการ
4. **Preview อัปเดตทันที** — overlay accessory บน avatar
5. User สลับ tab เพื่อเลือกหลาย slot พร้อมกัน
6. Preview แสดง avatar พร้อม accessories ทุก slot ที่เลือก

**Acceptance Criteria**

| ID | เกณฑ์ |
|---|---|
| AC-HP03-1 | Tab Accessories 5 tabs: Hat / Glasses / Outfit / Bag / Wings |
| AC-HP03-2 | Tab badge: slot ที่มี accessory สวมอยู่ → dot indicator บน tab |
| AC-HP03-3 | "None" เป็นตัวเลือกแรกทุก category — ถอด accessory ออกจาก slot |
| AC-HP03-4 | กด accessory → Preview อัปเดตทันที overlay บน avatar |
| AC-HP03-5 | Preview = composite render skin + hat + glasses + outfit + bag + wings พร้อมกัน |
| AC-HP03-6 | Z-order overlay ถูกต้อง (ตารางด้านล่าง) |
| AC-HP03-7 | Accessories grid scroll ได้ถ้ามีมากกว่า 1 แถว |
| AC-HP03-8 | เปลี่ยน skin แล้ว accessories ที่เลือกไว้ยังอยู่ (ไม่ reset) |

**Z-order (ClickUp ล่างสุด → บนสุด)**

| ลำดับ | Layer | หมายเหตุ ClickUp |
|---|---|---|
| 1 | Wings | behind avatar (`z = OBJECT_BEHIND_Z`) *[ไม่มีค่าคงที่นี้ในโค้ด (§5.4) · ระบบใหม่ใช้ `CATEGORY_LAYER` — C-15]* |
| 2 | Bag | behind avatar |
| 3 | Skin (body) | — |
| 4 | Outfit | on avatar body |
| 5 | Glasses | above face |
| 6 | Hat | above head (z สูงสุด) |

> *[หมายเหตุ]* ClickUp ไม่ได้ระบุว่า z-order เปลี่ยนตามทิศหรือไม่ — เช่นหันหน้าขึ้น (North) Bag/Wings ควรอยู่ **หน้า** ตัว (Q-6)

### SC-AV-02-HP-04 · ถอด Accessory (เลือก None)

- **Pre-condition:** User สวม accessory อยู่ใน slot หนึ่ง

**Steps**

1. กด tab ที่มี accessory สวมอยู่ (เช่น Hat)
2. กด **"None"** (ตัวเลือกแรก)
3. Preview อัปเดตทันที: hat หายออก
4. Tab "Hat" badge dot หาย
5. กด "บันทึก" เพื่อยืนยัน

**Acceptance Criteria**

| ID | เกณฑ์ |
|---|---|
| AC-HP04-1 | "None" แสดงเป็นตัวเลือกแรกทุก category เสมอ |
| AC-HP04-2 | กด None → preview ถอด accessory slot นั้นทันที |
| AC-HP04-3 | Tab badge dot หายเมื่อ slot = None |
| AC-HP04-4 | กด None แล้ว None ถูก highlight (border สีฟ้า) |
| AC-HP04-5 | ถอดทุก slot = กด None ทีละ tab |
| AC-HP04-6 | *(optional)* ปุ่ม "ถอดทั้งหมด" clear ทุก accessory slot พร้อมกัน — **ต้องตัดสินว่าทำหรือไม่ (Q-9)** |

### SC-AV-02-HP-05 · บันทึก Avatar และอัปเดต Virtual Office

- **Pre-condition:** User เลือก skin + accessories แล้ว

**Steps**

1. User กด **"บันทึก"**
2. ระบบ save `user_avatar_settings` สำหรับ workspace นั้น
3. Panel ปิด
4. **Avatar ใน VO อัปเดตทันที** — ทุกคนใน workspace เห็น avatar ใหม่

**Acceptance Criteria**

| ID | เกณฑ์ |
|---|---|
| AC-HP05-1 | บันทึก `skin_id + hat_id + glasses_id + outfit_id + bag_id + wings_id` |
| AC-HP05-2 | Avatar ใน VO อัปเดตทันที (WebSocket broadcast) |
| AC-HP05-3 | คนอื่นเห็น avatar ใหม่ภายใน **2 วินาที** |
| AC-HP05-4 | Name plate แสดงเหมือนเดิม (ชื่อ user ไม่เปลี่ยน) |
| AC-HP05-5 | กด "ยกเลิก" → ไม่บันทึก, avatar กลับเป็น setting เดิม |
| AC-HP05-6 | "ยกเลิก" ถามยืนยันถ้ามีการเปลี่ยนแปลง: "ยังไม่บันทึก ต้องการออกไหม?" |

### SC-AV-02-HP-06 · Avatar ต่าง Workspace (แต่งแยกได้)

- **Persona:** member ที่อยู่หลาย workspace · **Pre-condition:** เป็น member ของ 2+ workspaces

**Steps**

1. User เป็นสมาชิกทั้ง Workspace A และ B
2. ใน A → เลือก Dark Skin + Hat A
3. ใน B → เลือก Tan Skin + Glasses B
4. ใน A: avatar = Dark + Hat · ใน B: avatar = Tan + Glasses
5. เปลี่ยนใน A ไม่กระทบ B

**Acceptance Criteria**

| ID | เกณฑ์ |
|---|---|
| AC-HP06-1 | `user_avatar_settings` unique ต่อ `(user_id, workspace_id)` |
| AC-HP06-2 | Panel แสดง label workspace ชัดเจน: "แต่งตัวสำหรับ Workspace A" |
| AC-HP06-3 | เปลี่ยนใน A ไม่กระทบ B |
| AC-HP06-4 | Workspace ใหม่: เริ่มด้วย Default skin + ไม่มี accessory *[มติ C-14 ✅ ต่อ workspace — §9.2]* |
| AC-HP06-5 | ออกจาก workspace แล้วกลับเข้า: avatar setting ยังเหมือนเดิม (persist) *[ต้องไม่ลบ row ตอนออก workspace — §9.2]* |

### SC-AV-02-EP-01 · บันทึกไม่สำเร็จ (Network Error)

- **Trigger:** API บันทึก avatar settings ล้มเหลว (network error / 5xx)

**Steps**

1. User กด "บันทึก"
2. API call ล้มเหลว
3. Panel ยังเปิดอยู่

**Acceptance Criteria**

| ID | เกณฑ์ |
|---|---|
| AC-EP01-1 | Error toast: "บันทึกไม่สำเร็จ กรุณาลองใหม่" |
| AC-EP01-2 | Panel ยังเปิด — selection ที่เลือกไม่หาย |
| AC-EP01-3 | ปุ่ม "บันทึก" กลับมา active — ลองใหม่ได้ทันที |
| AC-EP01-4 | Avatar ใน VO **ไม่เปลี่ยน** (ยังเป็น setting ที่บันทึกครั้งก่อน) |
| AC-EP01-5 | Auto-retry 1 ครั้งอัตโนมัติหลัง 3 วินาที ก่อนแจ้ง user |

> *[หมายเหตุ]* Retry เฉพาะ network error / 5xx — 4xx (เช่น item ถูกซ่อนระหว่างแต่ง) ไม่ควร retry (Q-10)

### SC-AV-02-EC-02 · Skin/Accessory ที่ User ใช้อยู่ถูก Admin ซ่อน

- **Trigger:** Admin ซ่อน skin/accessory ที่ user กำลังใช้

```
Alice ใช้ Tan Skin + Hat A
Admin ซ่อน Tan Skin (status = hidden)
Alice เข้า Virtual Office / เปิด Customization
```

**Acceptance Criteria**

| ID | เกณฑ์ |
|---|---|
| AC-EC02-1 | Avatar ใน VO **ยังแสดง Tan Skin ต่อ** จนกว่า Alice จะเปลี่ยนเอง |
| AC-EC02-2 | Panel: Tan Skin ไม่แสดงใน picker |
| AC-EC02-3 | Panel: note "⚠ Skin ปัจจุบันของคุณไม่พร้อมใช้งาน กรุณาเลือก Skin ใหม่" |
| AC-EC02-4 | ต้องเลือก Skin ใหม่ก่อนบันทึก — บันทึกด้วย hidden skin ไม่ได้ |
| AC-EC02-5 | Accessory ที่ hidden: เหมือนกัน — ยังแสดงบน avatar แต่ picker ไม่แสดง |
| AC-EC02-6 | ถ้า Admin **ลบ** (ไม่ใช่ซ่อน): avatar reset อัตโนมัติ (SC-AV-01-EC-01 → จริงๆ คือ [SC-AV-01-EC-02](https://app.clickup.com/t/86d43pc8w)) |

**UX note สำหรับ Designer (ClickUp)**

```
Skin ที่ใช้อยู่:  [⚠ ไม่พร้อมใช้งาน]
เลือก Skin ใหม่:  [Def] [Dark] [Oliv]   ← Tan ไม่แสดง
⚠ กรุณาเลือก Skin ก่อนบันทึก
[บันทึก — disabled ถ้ายังไม่เลือก skin ใหม่]
```

> *[หมายเหตุ]* ClickUp ไม่ได้ระบุว่า **accessory hidden** บังคับเปลี่ยนก่อนบันทึกด้วยหรือไม่ — ถ้าบังคับ user ที่แค่อยากเปลี่ยนหมวกจะโดน block เพราะกระเป๋า hidden — Admin TD §8.1 ตอบแล้วว่า**ไม่บังคับ** (ชิ้น hidden ที่ใส่อยู่ save ผ่าน)

### SC-AV-02-EC-03 · หลาย Tab เปิด Customizer พร้อมกัน (Last-write-wins)

```
Tab 1: เปิด Customizer → เลือก Dark Skin
Tab 2: เปิด Customizer → เลือก Tan Skin → Save
Tab 1: Save (หลัง Tab 2)
```

**Acceptance Criteria**

| ID | เกณฑ์ |
|---|---|
| AC-EC03-1 | Last-write-wins: การบันทึกครั้งล่าสุดชนะเสมอ |
| AC-EC03-2 | Tab 2 บันทึก Tan → avatar = Tan |
| AC-EC03-3 | Tab 1 บันทึก Dark หลัง → avatar = Dark |
| AC-EC03-4 | Tab 2 รับ WS `ws:avatar:updated` → refresh preview ใน panel |
| AC-EC03-5 | ไม่มี conflict dialog — last-write-wins เงียบๆ |
| AC-EC03-6 | VO broadcast ทุกครั้งที่บันทึก → ทุกคนเห็น avatar ล่าสุด |

> *[หมายเหตุ]* ClickUp ไม่ระบุว่าถ้า tab ที่รับ event **มีการแก้ค้างที่ยังไม่ save** จะทับ draft หรือไม่ (Q-11)

---

## 5. Current implementation (ตรวจโค้ด 2026-10-22)

Branch ที่ตรวจ: `zyra-api@feat/calendar`, `zyra-ws@feat/calendar`, `zyra-app@fix/ipad-full-width-lobby` — `git log HEAD..develop` ว่างทั้ง 3 repo (ไม่มีโค้ด avatar ที่อยู่แค่บน `develop`)

### 5.1 zyra-api — Data

| ตาราง | ไฟล์ | สาระ |
|---|---|---|
| `tb_avatar` | `migrations/23_create_tb_avatar.sql`, `24_*`, `26_*`, `30_*` · startup DDL `internal/database/postgres.go:38-53` | 1 แถว = **character ทั้งตัว**: `name` (unique), `category` (`general`/`special`), `status` (`active`/`hidden`, default `hidden`), `is_default` (unique index ให้มีได้ 1), `walking_spritesheet_url`, `sitting_spritesheet_url`, `thumbnail_url`, `user_count`, `is_deleted`/`deleted_at`, `accessory_slots TEXT[]` (`hat`/`glasses`/`shirt` — **ไม่ได้ใช้งาน**) |
| `tb_user_avatar` | `migrations/27_create_tb_user_avatar.sql` | `user_id` **PRIMARY KEY**, `avatar_id`, `updated_at` → **global ต่อ user ไม่มี workspace** · ⚠ ไม่อยู่ใน startup DDL ของ `postgres.go` (ต้อง apply migration มือ) |
| `tb_avatar_audit_log` | `migrations/25_*` | audit ของ admin |
| `tb_workspace_member.character_name`, `nickname` | `postgres.go:350`, `migrations/72_*` | **per-workspace** อยู่แล้ว (ชื่อ ไม่ใช่ตัวละคร) |

ไม่พบ: ตาราง skin / accessory / wearable, `sort_order` บน avatar, `user_avatar_settings`, คอลัมน์เก็บ URL ของ metadata/accessory

### 5.2 zyra-api — Endpoint & Service

Member (`internal/router/router.go`):

| Method | Path | บรรทัด | พฤติกรรม |
|---|---|---|---|
| PUT | `/api/user/me/avatar-selection` | :189 | body `{avatar_id}` → `SetUserAvatar` (`avatar_service.go:310-336`) ปฏิเสธถ้าไม่ active/ถูกลบ (`ErrAvatarNotSelectable`) แล้ว UPSERT `ON CONFLICT (user_id)` · **ไม่ publish WS** |
| GET | `/api/user/avatars` | :191 | active เท่านั้น, sort by name, limit 100 |
| GET | `/api/user/avatars/default` | :193 | default avatar |
| GET | `/api/user/me` | — | คืน `selected_avatar` (`model/auth.go:87`, `profile_service.go:98-116`) — คืน `nil` ถ้า avatar ที่เลือก hidden/deleted |
| PATCH | `/api/user/workspaces/:id/members/me/character-name` | :263 | ชื่อตัวละครต่อ workspace (ตัด 50 runes) |

Admin `/api/admin/avatars` (:655-665, permission `admin.avatar.manage`): List/Create/Get/Update/Delete + `/:id/spritesheet`, `/:id/thumbnail`, `/:id/metadata`, `/:id/accessory`

- **Delete** (`avatar_service.go:513-583`): ห้ามลบ default ตัวเดียว · `UPDATE tb_user_avatar SET avatar_id=<default>` · soft delete + audit · คืน `users_reset` · **ไม่มี realtime broadcast**
- **Hide**: ไม่ reassign ใคร
- **Storage** (S3/R2 prefix `avatars/{id}/`): `walking_|sitting_{uuid}.png`, `thumbnail.png`, `metadata.json`, `accessory.png` (≤256×256) — sheet ต้อง **1000×1000** พอดี (:32) · metadata ต้องมี state `idle, walk_n, walk_s, walk_e, walk_w, wave, sit` (:37-39) — **ไม่มี `idle_s`**
- `cmd/avatar-cleanup/main.go`: hard delete หลัง soft-delete 30 วัน (ลบ prefix S3 + row)
- ช่องทาง API → WS ที่มีอยู่: Redis pub/sub `vo:zone` (`internal/cache/zone_events.go:19,53`) envelope `{workspace_id, type, payload}` — room pet ใช้อยู่ (`room_pet_service.go:752`)

### 5.3 zyra-app — UI ปัจจุบัน

| เรื่อง | ไฟล์ | สาระ |
|---|---|---|
| API client | `lib/api/avatars.ts` | `listAvatarsForUser` :108, `getDefaultAvatar` :120, `setMyAvatarSelection` :133 (ใช้ `/api/user/*` ✓) · `AVATAR_ACCESSORY_SLOTS` = hat/glasses/shirt :12 |
| Hook | `hooks/use-user-avatars.ts` | React Query stale 5 นาที |
| localStorage | `lib/avatar-selection.ts` | key `zyra_selected_avatar` (**global**) · `resolveSelectedAvatar` :65 — server ชนะ, ไม่มีค่อยใช้ local |
| Picker modal | `views/user/workspace-enter/components/change-character-modal.tsx` | grid avatar + preview **ภาพนิ่ง** + ปุ่ม Random · save = เขียน local แล้วยิง API **fire-and-forget** (error แค่ `console.warn`, ไม่มี toast) · overlay ทำมือ ไม่ใช้ `components/ui/dialog.tsx` · mobile ใช้ `mobile-character-page.tsx` |
| จุดเรียก modal | lobby `hero-workspace-enter.tsx:28` (save ตอน join :373-389) · `views/profile/components/profile-form.tsx:11` · VO `hero-virtual-office.tsx:13678-13697` | |
| Preview | `components/avatar/avatar-sprite.tsx` + `avatar-frames.ts` | CSS background crop เฟรม idle หันหน้า — **ไม่ animate** |
| Entry ใน VO | `vo-sidebar.tsx:313-318` → `VOProfilePanel` → ปุ่ม "Change avatar" `vo-profile-panel.tsx:515-521` (mobile :826) | |
| Settings | `vo-setting-modal.tsx:1063-1064` | tabs: profile, general, audio, notifications, manage, integrations, environment — **ไม่มี Avatar tab** · ไม่มี route "Workspace Settings" แยก |
| Admin | `app/admin/avatar-management/*`, `views/admin/avatar-management/*` (15 ไฟล์) | category มีแค่ general/special · ส่ง `accessory_slots: []` เสมอ · ไม่มี UI accessory |
| Toast / Dialog | `lib/toast.tsx:224` (`zyraToast.*`) · `components/ui/dialog.tsx` | reuse ได้ |

### 5.4 zyra-app — VO renderer (`zyra-engine/pixi-game/scene.ts`)

- Player โหลด texture จาก `mapConfig.playerSpriteUrl` (:2037-2051) ← `storedAvatar.walking_spritesheet_url` (hero :6123) · fallback `/sprites/characters/Character_001.png`
- `setPlayerAvatar(walkUrl, sitUrl)` :10306 — hot-swap texture ได้ไม่ต้อง reconnect
- Sheet layout = **grid 4×4** (`buildFrameCache` `utils.ts:775`; `zyra-engine/avatar-frames.ts`: row down/left/right/up, idle = column 1, walk 4 frames @8fps, sit 3 frames) · แสดงที่ 48×48 (`zyra-engine/constants.ts:190-191`)
- **1 sprite ต่อ player** — ไม่มี layer accessory
- Z-order: `encodeZ = drawOrder*100 + isFloor*10 + objectZIndex` (`utils.ts:166`), `sortRowDrawOrder(row, slot) = round(row*32)*3 + slot` (slot 0 object, 1 character, 2 aboveCharacter) (`utils.ts:197`) · `FLOOR_LAYER = 100000` · **ไม่มี `OBJECT_BEHIND_Z`**
- Name tag: `makeNameTag` `utils.ts:1041`, z = `MAX_SAFE_INTEGER-10` (`scene.ts:2058`) — แสดง `character_name` + `nickname`
- Remote player: `welcome`/`joined` → `avatar_url` → `walk_sprite_url` (hero :4103, :4204) · `moved` มี `avatar_url` → `updateRemotePlayerPos` (`scene.ts:12044`) reload texture ถ้า URL เปลี่ยน
- Local client ส่ง `avatar_url` ใน state poll ทุก 100ms (hero :3541-3610) — modal onSave ล้าง `lastTileRef` เพื่อบังคับส่ง → **ตอนนี้คนอื่นเห็นภายใน ~100ms แต่ส่งได้แค่ URL เดียว**
- ⚠ Stale pick: refresh catalog ตอน mount (hero :2336-2349) `if (!fresh) return` → avatar ที่ถูกซ่อน/ลบค้างใน localStorage และยัง broadcast ต่อ

### 5.5 zyra-ws

- Connect query: `avatar_url`, `character_name`, `nickname` (`internal/handler/handler.go:130-135`) → `hub.Join` · presence ใน Redis เก็บ `avatarURL` (`hub.go:328`)
- `Player` (`internal/hub/message.go:210-230`): `avatar_url`, `character_name`, `nickname`, sitting, direction — **ไม่มี avatar/accessory id**
- `moved` / `moving` มี `avatar_url` · `moved_bin` ไม่มี (message.go:1543) · V2 broadcast `moved` เมื่อ avatar URL หรือ sitting เปลี่ยน (`room.go:1046-1066`)
- `profile_updated` (`room.go:1994-2022`) — `avatar_url` ในนี้คือ**รูปโปรไฟล์** ไม่ใช่ sprite
- **ไม่มี event avatar ใดๆ** (ค้น `avatar_updated`, `avatar:updated`, `ws:avatar:*`)
- Naming ผสม: core VO = snake_case (`moved`, `profile_updated`, `pet_spawned`) · media/meeting = `ws:<domain>:<camelAction>` · chat = `chat:message:new`
- Relay API → WS ผ่าน `vo:zone` มี **allowlist** (`internal/hub/zoneclaims.go:38-55`) — type ใหม่ต้องเพิ่ม ไม่งั้นโดน drop · และ relay ไม่ได้อัปเดต `Client.AvatarURL` ที่ใช้ส่งให้คนเข้าใหม่ใน `welcome`

---

### 5.6 งานฝั่ง Admin (อัปเดต 2026-10-22 — merge เข้า `develop` และขึ้น dev แล้ว)

| PR | สาระ | สถานะ |
|---|---|---|
| zyra-api#179 (API-1) | migration **118** + embedded DDL: `tb_avatar_part`, `tb_avatar_part_variant`, `tb_avatar_part_audit`, `tb_avatar_reset_job`, `tb_user_outfit` + GIN · ค่าคงที่ 18 หมวด | merged |
| zyra-api#180–#184 (API-2~6) | validator ชีท · service CRUD · route `/api/admin/avatar-parts*` (+ `admin.avatar.manage`) · ลบ + reset job + `outfit_reset` · ลบถาวรหลัง 30 วัน | merged |
| **zyra-api#185** | **migration 119 — `tb_user_outfit` PK `(user_id, workspace_id)` ตามมติ C-14** · นับคนไม่ซ้ำ · reset ต่อแถว · `outfit_reset` มี `workspace_id` | merged |
| zyra-ws#86 / **#87** | `outfit_reset` → socket ของ user · #87 ส่งเฉพาะห้องของ workspace นั้น | merged |
| zyra-app#638–#644 (APP-1~6, QA-1) | renderer `lib/avatar-part/*` · หน้า admin ครบ (list, ฟอร์ม, Special Costume, hide/delete) · e2e | merged |

- ยังไม่มี member API (`/api/user/avatar/*`, `/api/user/workspaces/:id/avatar/outfit`) — เป็นงาน M-1~M-3 ของ spec นี้ · ข้อเสนอ path อยู่ใน [`data/api-example.md`](<../[Module] Avatar & Accessories Management (Admin)/data/api-example.md>) (อัปเดตเป็นต่อ workspace แล้ว)
- §5.1–5.5 ตรวจจาก working tree **ก่อน** PR ข้างบน merge — ต้องตรวจใหม่ก่อนเริ่ม M-1

---|---|---|
| zyra-api#179 `feat/avatar-part-schema` (API-1) | migration **118** + embedded DDL: `tb_avatar_part`, `tb_avatar_part_variant`, `tb_avatar_part_audit`, `tb_avatar_reset_job`, **`tb_user_outfit` (`user_id` PRIMARY KEY — ไม่มี `workspace_id`)** + GIN · ค่าคงที่ 18 หมวด | เปิด รอ review |
| zyra-api#180 `feat/avatar-part-validate` (API-2) | validator ชีท (`ValidateAccessorySheet` ฯลฯ) | เปิด รอ review |
| `feat/avatar-part-service`, `feat/avatar-part-routes`, `feat/avatar-part-delete` (API-3~5) | CRUD + routes + delete/reset job + `PublishOutfitReset` (`internal/cache/notification.go`) | มี branch บน origin แล้ว (ล้ำ progress.md) · ยังไม่เข้า `develop` |
| zyra-app#638 (APP-1) | `lib/avatar-part/{constants,shade,render,chair,validate}.ts` — renderer palette swap ยกจาก POC · base sheet `public/avatar/base/{walk,sit}.png` | เปิด รอ review |
| zyra-app#639 (APP-2) | shell หน้า admin + category panel 18 หมวด | เปิด รอ review |

- ยังไม่มี member API (`/api/user/avatar/*`) ในทุก branch (ตรวจ `git grep` บน `origin/feat/avatar-part-delete` 2026-10-22) — มีแค่ข้อเสนอใน [`data/api-example.md`](<../[Module] Avatar & Accessories Management (Admin)/data/api-example.md>)
- ตรวจ baseline §5.1–5.5 จาก working tree ที่ยัง**ไม่มี** PR ข้างบน — หลัง merge ต้องตรวจใหม่

---

## 6. ระบบเป้าหมายที่ทีมกำลังสร้าง (จากเอกสาร Admin — ไม่ใช่ ClickUp SC-AV-02)

> สรุปจาก [technical-design.md](<../[Module] Avatar & Accessories Management (Admin)/technical-design.md>) (Draft v1.0, 2026-10-21), [requirements.md](<../[Module] Avatar & Accessories Management (Admin)/requirements.md>), [data/](<../[Module] Avatar & Accessories Management (Admin)/data/>) — เอกสารเหล่านั้นอ้าง **"มติ AvatarCustomization 2026-10-05"** และ [`technical-design.md`](technical-design.md) — ต้นฉบับร่าง 2026-10-05 ขึ้น git แล้ว (2026-10-22) พร้อมหมายเหตุส่วนที่ถูกแทนด้วยมติใน §8.3

### 6.1 หลักการ

- **Paper-doll:** base `body` 1 ตัว (ไฟล์ใน repo) + ชิ้นส่วนวาดทับตามลำดับ layer
- **ชิ้นส่วนวาดด้วย "สี key"** แล้วเปลี่ยนสีด้วย palette swap — ยกเว้น Special Costume ใช้สีตามไฟล์ (1 variant = 1 สี)
- **Bake ฝั่ง server ตอนกด Save** → ได้ `walk.png` + `sit.png` (240×192, 5 คอลัมน์รวมหลับตา) + `thumb.png` ต่อชุด เก็บที่ `outfits/{hash}/` · ชุดเหมือนกัน = ไฟล์เดียวกัน (dedupe ด้วย `bake_hash`)
- **VO และ zyra-ws ยังรับ "URL เดียวต่อคน" เหมือนเดิม** — ไม่ต้องทำ renderer หลาย layer ใน VO
- Hide **ไม่แตะ** ชุดที่ผู้ใช้ใส่อยู่ · Delete **ถอดออก** จากทุกคน (slot บังคับ → ใส่ชิ้น default ของ slot) แล้ว re-bake
- ชีท: 48×48 ต่อเฟรม · grid 4 แถว (ลง/ซ้าย/ขวา/ขึ้น) × 4–5 คอลัมน์ · `walk` + `sit` แยกไฟล์ (D1 ยังรอยืนยัน 48 vs 64)

### 6.2 Slot / หมวด — 3 ชุดที่ยังไม่ตรงกัน

| ที่มา | จำนวน | รายการ |
|---|---|---|
| ClickUp SC-AV-02 (เอกสารนี้ §4) | Skin + 5 | Skin, Hat, Glasses, Outfit, Bag, Wings |
| Member data contract (`avatar-outfit-data.json`) | 11 slot | body, eyes, hair, facial_hair, top, bottom, shoes, hat, glasses, accessory, costume |
| Admin technical-design §2 / Figma | 18 หมวด (+ body) | hair, eyes, face, facial_hair, top, outer, dress, bottoms, shoes, special_costume, hat, glasses, mask, neck, belt, bag, back, companion |

Admin TD เลือก "หมวด = slot (18 ค่า) และขยาย data contract ฝั่ง member ตาม" — **รอ D4 (PM + Ten)**

### 6.3 "Skin" ใน ClickUp ↔ ระบบใหม่

ClickUp SC-AV-02 มอง Skin เป็น **item ที่ admin อัปโหลด/ซ่อนได้** (HP-02, EC-02) แต่ระบบใหม่:

- สีผิว = **palette** `colors.skin` (scope global) เลือกจาก palette `skin` 6 ค่า — ไม่ใช่ชิ้นส่วน
- `body` เป็นไฟล์ใน repo ไม่อยู่ในหน้า admin (TD §2)
- palette อยู่ใน `tb_avatar_palette` ซึ่ง migration 118 **ไม่สร้าง** ("admin ไม่ใช้")

→ AC ที่ผูกกับ "Skin เป็น item" (AC-HP02-1/5/7, AC-EC02-1~4) ไม่มีที่ยืนในระบบใหม่ — **มติ C-13 รอบ 4: Skin = Default ไม่อัปโหลด** (§9.3) — AC เหล่านี้ไม่มีผล ยกเว้นถ้า Q-4b ให้เลือกเฉดสีผิวได้

### 6.4 Member API ที่เสนอไว้ (data/api-example.md — proposal)

| # | Method | Path | ทำอะไร |
|---|---|---|---|
| 1 | GET | `/api/user/avatar/catalog` | slot + ชิ้นส่วน active + palette + สี key + sheet spec |
| 2 | GET | `/api/user/avatar/outfit` | ชุดปัจจุบัน + URL ที่ bake แล้ว (`is_default: true` ถ้าไม่เคยแต่ง) |
| 3 | PUT | `/api/user/avatar/outfit` | validate → normalize → bake → upload R2 → เก็บ → broadcast → ตอบ |
| 4 | POST | `/api/user/avatar/outfit/preview` | optional — server render preview |
| 5 | GET | `/api/user/avatar/outfit/default` | ชุด default (ปุ่ม "ชุดเริ่มต้น") |

- Error ของ PUT: `REQUIRED_SLOT_MISSING`, `PART_NOT_FOUND`, `PALETTE_NOT_FOUND`, `CHANNEL_NOT_ALLOWED` (400) · `BAKE_FAILED` (500)
- Hidden (TD §8.1): PUT ที่มีชิ้น hidden **ซึ่งผู้ใช้ใส่อยู่แล้ว** → ผ่าน · ชิ้น hidden ที่เพิ่งเลือก → 400 `PART_NOT_SELECTABLE` (ชื่อ code ไม่ตรงกับ api-example ที่ใช้ `PART_NOT_FOUND` — C-17)
- **ไม่มี `workspace_id` ในทุก path** — ชุดเดียวใช้ทุก workspace (ข้อความ UI ใน contract: "ใช้ชุดนี้ในทุก workspace", "บันทึกแล้ว ทุก workspace จะเห็นชุดนี้")

### 6.5 Realtime ที่ออกแบบไว้

- **Admin delete reset** (TD §9): api publish Redis channel notification (`outfit_reset_user_id`) → ws ส่ง `{"type":"outfit_reset"}` ไปทุก socket ของ user → client `GET /api/user/me/outfit` → ส่ง `avatar_url` ใหม่ใน `move` → `room.go` (`avatarChanged`) broadcast ตามกลไกเดิม
- **Save ของ member:** api-example เขียนแค่ "broadcast ให้ VO ที่ user อยู่" — **ยังไม่ออกแบบ** · กลไกเดิม (client ส่ง `avatar_url` ใน state poll 100ms) พาให้คนอื่นเห็นใน ~100ms ได้อยู่แล้วโดยไม่ต้องมี event ใหม่ แต่**ไม่ครอบ tab อื่นของ user เดียวกัน** (EC-03) และไม่ครอบคนที่ยังไม่อยู่ใน VO
- path ใน TD §9 เขียน `GET /api/user/me/outfit` แต่ api-example ใช้ `/api/user/avatar/outfit` (C-17)

### 6.6 UI ฝั่ง member ที่ร่างไว้ (data/frontend-guide.md)

- หน้าเดี่ยว 2 pane (stage ซ้าย / ตู้เสื้อผ้าขวา) · tab ต่อ slot · grid card + "ไม่ใส่" · swatch สี · ปุ่ม สุ่ม / ชุดเริ่มต้น / ยกเลิก / บันทึก · stage ยืน/เดิน/นั่ง + 4 ทิศ + หมุนอัตโนมัติ · ยึด prototype [Zyra Avatar Studio](https://claude.ai/artifact/5CWTCN9yMtbQ4czt29FVty) เพราะ "ยังไม่มี Figma"
- route รอ PM (`/avatar` หรือ `/profile/avatar`) · entry ตาม "AvatarCustomization spec": lobby, Profile, profile panel ใน VO — รอบแรกทำ route เดี่ยวก่อน
- ไม่ต้องทำ: หน้า admin, upload, validate ชีท, ws broadcast

---

## 7. Gap analysis — ClickUp SC-AV-02 เทียบกับ (ก) โค้ดตอนนี้ (ข) ระบบเป้าหมาย §6

| # | Requirement (ClickUp) | (ก) โค้ดตอนนี้ | (ข) ระบบเป้าหมาย §6 | สิ่งที่ยังต้องทำ / ตัดสิน |
|---|---|---|---|---|
| G-1 | Skin + accessories แยก layer | character ทั้งตัว | ✅ paper-doll + bake | ทำตาม §6 · ตกลงรายชื่อ slot (D4) |
| G-2 | Skin = item ที่ admin ซ่อนได้ | `tb_avatar` | ❌ skin = palette | **มติ C-13 ✅** → skin = Default ชีท body + ดูด ramp (§9.3) |
| G-3 | เก็บต่อ **(user, workspace)** | global (`tb_user_avatar`) | ❌ global (`tb_user_outfit`) | **มติ C-14 ✅** → ทำแล้ว: `workspace_id` + PK `(user_id, workspace_id)` ใน zyra-api#185 (migration 119) · path API ต่อ workspace ใน data contract (§9.2) |
| G-4 | Preview animated `idle_s` composite | ภาพนิ่ง | ✅ renderer palette swap ฝั่ง client (APP-1 #638) + animation ใน data contract | reuse `lib/avatar-part/render.ts` |
| G-5 | Z-order 5 layer (Wings/Bag หลังตัว) | ไม่มี | ✅ `CATEGORY_LAYER` (back = 1 หลังตัว, bag = 6) | ใช้ค่าตาม TD — ต่างจาก ClickUp (Bag ไม่ได้อยู่หลังตัว) C-15 |
| G-6 | VO แสดงชุดใหม่ | 1 sprite/URL | ✅ ยัง URL เดียว (baked) | ไม่ต้องแก้ renderer VO นอกจาก sheet 5 คอลัมน์ 240×192 vs grid เดิม (ตรวจ `avatar-frames.ts`) |
| G-7 | คนอื่นเห็น ≤ 2s | `moved.avatar_url` ~100ms | ✅ กลไกเดิม | ต้องให้ client ใช้ baked URL ทันทีหลัง PUT |
| G-8 | Sync tab อื่น (`ws:avatar:updated`) | ไม่มี | ❌ ยังไม่ออกแบบ (มีแค่ `outfit_reset`) | ตัดสิน C-16 — reuse `outfit_reset` หรือ event ใหม่ |
| G-9 | Hidden: ยังใส่ต่อ + picker ไม่แสดง | `/me` คืน nil ถ้า hidden | ✅ TD §8.1 (ใส่ต่อได้, เลือกใหม่ไม่ได้) | แต่ ClickUp บังคับเปลี่ยน **skin** ก่อน save — ไม่มีในระบบใหม่ (C-13) · ต้องให้ GET outfit บอกว่าชิ้นไหน hidden เพื่อแสดง note |
| G-10 | Delete → reset + broadcast | reassign ไม่ broadcast | ✅ reset job + `outfit_reset` | รอ admin API-5 |
| G-11 | Save error → toast + retry 1 ครั้ง/3s | fire-and-forget | ❌ ไม่ได้ระบุ | ทำฝั่ง app · 4xx ไม่ retry |
| G-12 | Cancel confirm "ยังไม่บันทึก ต้องการออกไหม?" | ไม่มี | 🟡 มีสถานะ dirty แต่ไม่ได้ระบุ confirm | ทำฝั่ง app |
| G-13 | Entry: sidebar / HUD / Workspace Settings | VO profile panel → modal | 🟡 route เดี่ยวก่อน · entry รอ PM | ตัดสิน Q-7 |
| G-14 | Panel เป็น modal/side panel + label workspace | modal | ❌ หน้าเต็ม 2 pane (prototype) / Figma "Dressing room" เต็มจอ | ตัดสิน Q-7 + C-14 |
| G-15 | Default skin แสดงก่อน (`sort_order = 0`) | sort by name | 🟡 palette เรียงตาม array · `tb_avatar_part_variant.sort_order` มีเฉพาะ variant | ตัดสินพร้อม C-13 |
| G-16 | "ถอดทั้งหมด" (optional) | — | 🟡 มี "ชุดเริ่มต้น" (reset เป็น default ไม่ใช่ถอดหมด) · slot required ถอดไม่ได้ | Q-9 |

---

## 8. ข้อขัดแย้ง (ห้ามเลือกเอง — รอตัดสิน)

### 8.1 ภายใน ClickUp / ClickUp ↔ โค้ดเดิม (จากรอบแรก)

| # | ระหว่าง | รายละเอียด | กระทบ |
|---|---|---|---|
| C-1 | ClickUp ↔ ClickUp | Parent ใช้ EC-01/EC-02, subtask ใช้ EC-02/EC-03 · SC-AV-02-EC-02 อ้าง "SC-AV-01-EC-01" ที่ไม่มีจริง (มีแต่ EC-02) | traceability |
| C-2 | ClickUp ↔ ClickUp | Admin model บอก Skin = "สีผิว, สีผม, **ชุด base**" แต่ Client มี slot **Outfit** แยก | asset, layer |
| C-3 | ClickUp ↔ Figma | Figma node `7454:600826` = หน้าเต็ม **"Dressing room"** · category 18–21 หมวด (sticky: Skin tone, Hair, Eye, Face, Facial hair, Top, Outer, Bottom, Shoes, Dress, Dress/Outfit, Special Costume, Hat, Glasses, Mask, Neck, Bag, Belt, Back, Companion) · Colour palette ต่อ item · **"Slot" = preset เครื่องแต่งกาย** · Special costume ไม่มีเฉดสี — ClickUp มีแค่ Skin + 5 slot | scope |
| C-4 | ClickUp ↔ Figma | Sticky: "Skin tone ถอดไม่ได้ · Clear Skin tone = กลับ Default" · "Default ใส่ชุดขาว สีผิว Default" · "เมนู Change Avatar → Customise avatar มีชื่อ Workspace ใต้ปุ่มย้อนกลับ" · "Costume Panel บอกว่ากำลังใส่อะไร, Accessory แยกอีก panel" · "Hover แสดงชื่อ item" | UI |
| C-6 | ClickUp ↔ ClickUp | HP-01: click นอก panel = ปิด · HP-05: ยกเลิกต้อง confirm ถ้ามีการเปลี่ยน | UX |
| C-9 | ClickUp ↔ โค้ด | `ws:avatar:updated` · โค้ดไม่มี event avatar · core VO ใช้ snake_case | ws |
| C-11 | ClickUp ↔ โค้ด | "Workspace Settings → Avatar" ไม่มีในระบบ | UI |

C-5, C-7, C-8, C-10, C-12 ของรอบแรก (per-workspace vs global, sheet format, `sort_order`, `OBJECT_BEHIND_Z`, ชื่อ slot) ถูกแทนด้วย C-13~C-18 ด้านล่าง เพราะระบบเป้าหมายไม่ได้ต่อยอดโค้ดเดิมแล้ว

### 8.2 ClickUp SC-AV-02 ↔ ระบบเป้าหมาย (เอกสาร Admin + member data contract)

| # | ClickUp SC-AV-02 | เอกสาร Admin / data contract | กระทบ |
|---|---|---|---|
| **C-13** ✅ | Skin = item อัปโหลด/ซ่อนได้ · EC-02 บังคับเลือก skin ใหม่เมื่อ skin ถูกซ่อน | สีผิว = palette ใน repo · admin จัดการไม่ได้ · ไม่มี "skin ถูกซ่อน" | **มติรอบ 4: Skin = Default ไม่อัปโหลด** (ใกล้ฝั่ง Admin) · เลือกสีผิวได้ไหม = Q-4b (§9.3) |
| **C-14** ✅ | **1 avatar ต่อ user ต่อ workspace** (HP-06 ทั้ง scenario, AC-HP01-5) | **ชุดเดียวทุก workspace** (`tb_user_outfit` ไม่มี workspace_id, API ไม่มี workspace, UI "ใช้ชุดนี้ในทุก workspace") | **มติ: ยึด ClickUp** (§8.3) |
| **C-15** | Z-order: Wings, Bag อยู่หลังตัว · Hat สูงสุด | `CATEGORY_LAYER`: back = 1 (หลังตัว), bag = 6, hat = 11, companion = 12 (สูงสุด) · ไม่มี Wings (ใกล้สุดคือ `back`) · ไม่มี Outfit (แตกเป็น top/outer/dress/bottoms) | layer |
| **C-16** | Tab อื่นรับ `ws:avatar:updated` แล้ว refresh preview | มีแค่ `outfit_reset` (ตอน admin ลบ) · ไม่มี event ตอน member save | ws contract |
| **C-17** | — | เอกสาร Admin เองไม่ตรงกัน: path `GET /api/user/me/outfit` (TD §9) vs `/api/user/avatar/outfit` (api-example) · error hidden `PART_NOT_SELECTABLE` (TD §8.1) vs `PART_NOT_FOUND` (api-example) | API contract |
| **C-18** | Modal/side panel · มี label workspace | หน้า route เดี่ยว 2 pane (prototype) · Figma "Dressing room" เต็มจอ | UI |
| C-19 | Status ใหม่ default — (ClickUp Admin: Hidden) | Figma default Active (D3) | ชิ้นใหม่โผล่ใน picker ทันทีหรือไม่ |

---

### 8.3 มติ (Decision log)

| วันที่ | # | มติ | ผู้ตัดสิน | ผลที่ตามมา |
|---|---|---|---|---|
| 2026-10-22 | C-14 | **ชุดแยกต่อ workspace** ตาม ClickUp SC-AV-02-HP-06 (1 avatar ต่อ user ต่อ workspace) — ไม่ใช้ "ชุดเดียวทุก workspace" ของ data contract | rif | §9.2 · แก้ schema/API/UI text ของระบบใหม่ · **ต้องแจ้ง Ten ก่อน zyra-api#179 merge** |
| ~~2026-10-22~~ | ~~C-13~~ | ~~Skin เป็นชิ้นที่ admin อัปโหลด/ซ่อนได้~~ — **ถูกแทนด้วยแถวรอบ 4 ด้านล่าง** | rif | — |
| 2026-10-22 (รอบ 4) | Q-1 | **ประกอบเป็นชิ้น ๆ (paper-doll + server bake)** ตามระบบของทีม Admin — ClickUp SC-AV-02 แบบ Skin + 5 accessory ต้องแก้ตาม | rif | §6, §9.1 |
| 2026-10-22 (รอบ 4) | C-13 | **Skin เป็น Default ไม่ได้อัปโหลด** — ไม่มีหมวด skin ในหน้า Admin | rif | §9.3 · AC-EC02-1~4 ไม่มีผล |
| 2026-10-22 (รอบ 4) | Q-4 | **Skin ใช้ชีท body ตัวเต็ม + ระบบดูดสีผิว 4 เฉดจากชีทเอง** ใช้เป็นสีผิวที่โผล่จากชิ้นอื่น | rif | §9.3 · ตัวดูด ramp ต้อง parity Go/TS |
| 2026-10-22 (รอบ 4) | Q-5 | **18 หมวด** ตาม Figma / Admin TD §2 (= D4 ของ Admin) | rif | data contract ฝั่ง member ต้องขยายจาก 11 slot |
| 2026-10-22 (รอบ 4) | Q-6b | ถูกลบออกจากสมาชิก workspace แล้วถูกเชิญกลับ → **เก็บชุดเดิมไว้** (ไม่ลบแถว) | rif | §9.2 · ลบแถวเฉพาะตอน user/workspace ถูกลบ |
| 2026-10-22 (รอบ 5) | Q-4b | **มี skin เริ่มต้น 5 เฉดให้ user เลือก** (ของระบบ ไม่ใช่ admin อัปโหลด) · ชีท body ตัวเดียว + palette swap · ค่าสียังไม่ยืนยัน (Q-4c) | rif | §9.3 · AC-HP02 ใช้ได้ |
| 2026-10-22 (รอบ 7) | D-M1 | **บันทึกอัตโนมัติตาม Figma** (ไม่มีปุ่มบันทึก/ยกเลิก) · error → กลับชุดที่บันทึกล่าสุด + toast ตาม Figma — แทน AC-HP05-5/6, AC-EP01-2/3/5 ของ ClickUp | rif | technical-design-member §8.2 |
| 2026-10-22 (รอบ 7) | D-M3 | **SLOT preset ยังไม่ทำ** — แสดง SLOT 1 อย่างเดียว · เก็บชุดเดียวต่อ workspace ตาม schema ปัจจุบัน | rif | ทำ SLOT ทีหลังได้โดยไม่ต้องรื้อ |
| 2026-10-22 (รอบ 7) | Default skin | **Fair** (`#F6D5B3`) = สีจากไฟล์ base body · เฉดอื่น = คูณอัตราส่วนเทียบ Fair | rif | Q-4c ✅ |

> มติ C-14 (ต่อ workspace) — **ทีม Admin อัปเดตเอกสารตามแล้ว 2026-10-22** (technical-design §4.1, §4.2, §8.2–8.3, §9 · data contract: path `/api/user/workspaces/:id/avatar/outfit` + ข้อความ "ใช้ชุดนี้ใน {workspace}") · ข้อความเดิมของย่อหน้านี้: เอกสาร Admin ยังขัดกับมติ ต้องให้เจ้าของ (Ten) อัปเดตตาม · มติ Q-1 / C-13 / Q-5 ตรงกับทิศทางของทีม Admin อยู่แล้ว · ClickUp SC-AV-02 ต้องแก้ให้ตรงกับมติทั้งหมด (ดู §11)

---

## 9. แนวทางที่ Agent เสนอ (ยังไม่ใช่ decision — ยกเว้นที่อ้าง §8.3)

> ถอนข้อเสนอรอบแรก (ตาราง `tb_avatar_item` 5 slot + renderer หลาย layer ใน VO) แล้ว · รอบ 3 ปรับตามมติ C-13 / C-14 · ห้าม implement จนกว่าข้อที่ block ใน §10 จะได้คำตอบ

### 9.1 ฐาน: ระบบ paper-doll + bake ของทีม Admin + ส่วนต่างจากมติ

- ใช้ `tb_avatar_part`, `tb_user_outfit`, renderer `lib/avatar-part/*`, server bake, `outfit_reset` ตามเอกสาร Admin — ไม่สร้างระบบที่สอง
- **ส่วนต่างจากเอกสาร Admin ตามมติ:** ชุดเก็บต่อ `(user, workspace)` (§9.2) · สีผิวดูดจากชีท body (§9.3)
- แปลง scenario ClickUp เป็นระบบใหม่:

| ClickUp | ในระบบใหม่ |
|---|---|
| เลือก Skin (HP-02) | เลือก 1 ใน **5 เฉดสีผิว** ของระบบ (`colors.skin`) บนชีท body ตัวเดียว · Default ตัวแรก (Q-4b) |
| Accessories 5 tab (HP-03) | tab ต่อหมวด **18 หมวด** (มติ Q-5) |
| None (HP-04) | "ไม่ใส่" (`slots.<slot> = null`) — เฉพาะหมวดที่ไม่บังคับ |
| บันทึก (HP-05) | `PUT /api/user/workspaces/:id/avatar/outfit` → baked URL |
| Avatar ต่าง Workspace (HP-06) | ✅ แถวแยกต่อ workspace (§9.2) |
| Network error (EP-01) | ใช้ได้ตรง ๆ |
| ถูก admin ซ่อน (EC-02) | ส่วน skin ไม่มีผล (skin = Default) · ชิ้นอื่น hidden → ใส่ต่อได้ เลือกใหม่ไม่ได้ (TD §8.1) |
| หลาย tab (EC-03) | event `outfit_updated` หลัง save (§9.4) |

### 9.2 ชุดแยกต่อ workspace (มติ C-14)

**DB** — ✅ ทำแล้วใน **zyra-api#185** (migration **119** `119_user_outfit_per_workspace.sql`) · #179 merge ไปก่อนที่ spec นี้ขึ้น main จึงแก้ด้วย migration ใหม่แทนการแก้ 118 — ผลเหมือนกัน (ตารางยังว่างทุกที่):

```sql
-- ปัจจุบันใน branch: tb_user_outfit (user_id VARCHAR PRIMARY KEY, outfit JSONB, bake_hash VARCHAR(64),
--                                    walk_url, sit_url, thumbnail_url TEXT, updated_at)
-- เปลี่ยนเป็น:
CREATE TABLE IF NOT EXISTS tb_user_outfit (
  user_id       VARCHAR      NOT NULL REFERENCES tb_user(id) ON DELETE CASCADE,
  workspace_id  UUID         NOT NULL REFERENCES tb_workspace(id) ON DELETE CASCADE,
  outfit        JSONB        NOT NULL,
  bake_hash     VARCHAR(64)  NOT NULL,
  walk_url      TEXT         NOT NULL,
  sit_url       TEXT         NOT NULL,
  thumbnail_url TEXT         NOT NULL,
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, workspace_id)
);
-- GIN (outfit jsonb_path_ops) เดิมใช้ต่อได้
```

> 119 เพิ่ม `workspace_id NOT NULL` + สลับ PK ด้วย `DO $$` ที่รันเฉพาะตอน PK ยังเป็น `user_id` คอลัมน์เดียว (รันซ้ำทุก boot ได้) · มีทั้งไฟล์ migration และ embedded DDL ใน `postgres.go` · ตรวจบน dev DB ใน transaction + ROLLBACK แล้ว

**API (member)**

| Method | Path | หมายเหตุ |
|---|---|---|
| GET | `/api/user/avatar/catalog` | ไม่ผูก workspace (ชิ้นส่วนเป็นของ platform) |
| GET | `/api/user/avatar/outfit/default` | ไม่ผูก workspace |
| GET | `/api/user/workspaces/:id/avatar/outfit` | ตรวจว่าเป็น member · ไม่มีแถว → ชุด default + `is_default: true` (AC-HP06-4) |
| PUT | `/api/user/workspaces/:id/avatar/outfit` | ตรวจ member · upsert `ON CONFLICT (user_id, workspace_id)` · last-write-wins (AC-EC03-1) |

- `403 NOT_WORKSPACE_MEMBER` ถ้าไม่ใช่ member
- path วางใต้ `/api/user/workspaces/:id/...` ให้เข้าชุดกับ `PATCH /api/user/workspaces/:id/members/me/character-name` เดิม — ข้อเสนอ ไม่ใช่มติ (รวมกับ Q-14)

**พฤติกรรม**

- Workspace ใหม่ / ไม่เคยแต่ง → ชุด default (AC-HP06-4)
- **ไม่ลบแถว** ตอนออกจาก VO หรือ logout (AC-HP06-5) · ลบตาม `ON DELETE CASCADE` เมื่อ user หรือ workspace ถูกลบ · ถูก**ลบออกจากสมาชิก**แล้วเชิญกลับ → **เก็บชุดเดิมไว้** (มติ Q-6b) — ห้ามลบแถวตอน remove member
- Bake dedupe ด้วย hash ใช้ข้าม workspace ได้ (ชุดเหมือนกัน = ไฟล์เดียวกัน)

**ผลต่อฝั่ง Admin — ✅ ทำแล้วใน zyra-api#185 + zyra-ws#87**

- นับผู้ใช้ต่อชิ้น (TD §4.2) → `count(DISTINCT user_id)` ไม่ใช่ `count(*)` — ไม่งั้นคนเดียวที่ใส่ใน 3 workspace นับเป็น 3 (ClickUp แสดง "ถูกใช้โดย X users")
- Reset job (TD §8.3) → loop ต่อ**แถว** `(user_id, workspace_id)` · `affected_user_count` ใน audit = จำนวนคนไม่ซ้ำ · progress "450/892" นับคนหรือแถว = ตัดสินฝั่ง Admin → **นับแถว (ชุด)** · `DELETE` คืน `{job_id, total = ชุด, user_count = คน}` · audit มี `affected_user_count` + `affected_outfit_count`
- `outfit_reset` (TD §9) → payload เพิ่ม `workspace_id` · ws ส่งเฉพาะห้องของ workspace นั้น

**UI**

- label "แต่งตัว Avatar สำหรับ [ชื่อ Workspace]" (AC-HP01-5, AC-HP06-2) แทนข้อความ "ใช้ชุดนี้ในทุก workspace" / "บันทึกแล้ว ทุก workspace จะเห็นชุดนี้" ใน data contract
- เปิดหน้าแต่งตัวจากนอก workspace (lobby/Profile) ต้องรู้ว่าแต่งให้ workspace ไหน — lobby รู้อยู่แล้ว · หน้า Profile ต้องมีตัวเลือก workspace หรือไม่ให้เปิดจากตรงนั้น (Q-7)
- VO: ดึง outfit ของ workspace นั้นก่อนต่อ ws แล้วส่ง `baked.walk_url` เป็น `avatar_url` ตามกลไกเดิม (§5.5)

### 9.3 Skin = Default (ไม่ได้อัปโหลด) · สีผิวดูดจากชีทตัวเต็ม (มติ C-13 แก้ + Q-4)

> มติรอบ 3 ("Skin เป็นชิ้นที่ admin อัปโหลด/ซ่อนได้") **ถูกแทน** ด้วยมติรอบ 4: **Skin เป็น Default ไม่ได้อัปโหลด**

**ที่ตกลงแล้ว**

- Skin มาจาก **ชีท body ตัวเต็ม** (`walk` + `sit` 192×192) ที่เป็นไฟล์ของระบบ ไม่มีหน้า admin อัปโหลด ไม่มีหมวด `skin` ใน `tb_avatar_part` — ตรงกับ Admin TD §2 ("base `body` ไม่อยู่ในหน้า admin — เป็นไฟล์ใน repo, ลำดับ 0") และ `public/avatar/base/{walk,sit}.png` ของ zyra-app#638
- **ระบบดูดสีผิว 4 เฉดจากชีท body เอง** (highlight / base / shadow / deep) แล้วใช้เป็น ramp ของ channel `skin` ตอน palette swap ชิ้นอื่นที่มีผิวโผล่ (แขนจากเสื้อ, เปลือกตาตอนกะพริบ, ฯลฯ) — ไม่ต้องกรอกสีเอง
- ไม่มี Skin ถูกซ่อน/ถูกลบ → **AC-EC02-1~4 (skin hidden) ไม่มีผล** · AC-EC02-5 (accessory hidden) และ AC-EC02-6 (ลบ → reset) ยังใช้กับหมวดอื่นตาม TD §8

**เฉดสีผิว 5 แบบ (Q-4b — rif 2026-10-22: "เหมือนจะมี skin เริ่มต้นให้ 5 เฉด")**

- ระบบมี **skin เริ่มต้น 5 เฉด** ให้ user เลือก — เป็นของระบบ **ไม่ใช่ admin อัปโหลด** · ชีท body ตัวเดียว เปลี่ยนเฉดด้วย palette swap
- เฉดหนึ่งเป็น **Default** (แสดงตัวแรก · user ใหม่/workspace ใหม่ได้เฉดนี้ · "Clear Skin tone" ใน Figma = กลับ Default) · skin ถอดไม่ได้ (Figma sticky)
- outfit JSON: `colors.skin = <id เฉด>` ตาม data contract เดิม
- ramp ที่ดูดจากชีท body = **เฉด Default** · อีก 4 เฉดเป็นค่าคงที่ในระบบ (ใช้ทั้ง bake ฝั่ง Go และ preview ฝั่ง TS)
- ⚠ **ค่าสีของ 5 เฉดยังไม่ยืนยัน** ("เหมือนจะ") — data contract (`avatar-outfit-data.json` → `palettes.skin`) มี **6** ค่า: `base` (สีจากไฟล์ base), `s1` ผิวขาวอมชมพู, `s3` ผิวแทน, `s4` ผิวน้ำตาล, `s5` ผิวเข้ม, `s0` เทาแบบตัวเดิม → ต้องยืนยันกับ Figma (node "Customise avatar - Skin tone" `7615:207396` / `7615:207397`) หรือ designer ว่า 5 เฉดคือชุดไหน (Q-4c)

ผลต่อ AC: **AC-HP02-1~4, 6, 7 ใช้ได้** (grid 5 เฉด, preview ทันที, highlight, Default ตัวแรก) · **AC-HP02-5 badge "ปัจจุบัน" ใช้ได้** (เฉดที่บันทึกไว้) · AC-EC02-1~4 (skin ถูกซ่อน) **ยังไม่มีผล** เพราะเฉดเป็นของระบบ ซ่อนไม่ได้

**ผลต่อฝั่ง Admin** — ไม่ต้องเพิ่มหมวด `skin` (ยกเลิกสิ่งที่รอบ 3 บอกให้แจ้ง Ten) · ต้องมีตัวดูด ramp จากชีท body ทั้งฝั่ง Go (bake) และ TS (preview) ให้ผลตรงกัน (parity แบบเดียวกับ `CATEGORY_LAYER`)

**Asset ที่มี** — โฟลเดอร์ `zyra/custom avatar/` (72 ไฟล์ 192×192 ทุกไฟล์ = 4×4 เฟรม 48 px → สนับสนุน D1 = 48 px) **ไม่มีชีท body / skin** → ต้องขอชีท body Default จากศิลปิน (หรือใช้ไฟล์ base ใน zyra-app#638)

### 9.4 Realtime หลัง member save (C-16)

- เสนอ reuse ช่องทางของ `outfit_reset` (Redis notify → ws → ทุก socket ของ user) เพิ่ม type `outfit_updated` payload `{workspace_id, walk_url, sit_url, updated_at}` → tab อื่นของ user **ใน workspace เดียวกัน** อัปเดต preview + avatar ของตัวเอง (AC-EC03-4) · tab ที่อยู่ workspace อื่นไม่สนใจ
- คนอื่นใน VO: ใช้ `moved.avatar_url` ตามกลไกเดิม (client ที่ save ส่ง URL ใหม่ใน poll ถัดไป ~100ms) — ไม่ต้องมี broadcast ใหม่ระดับ workspace (AC-HP05-2/3)
- กันลำดับสลับ: ไม่ apply event ที่ `updated_at` เก่ากว่าที่ถืออยู่
- tab ที่มี draft ค้าง: อัปเดต "ชุดที่บันทึก" + badge แต่ไม่ทับ draft (รอ Q-11)
- ชื่อ event: `outfit_updated` ให้เข้าคู่ `outfit_reset` (snake_case แบบ core VO) แทน `ws:avatar:updated` — รอ Q-13

### 9.5 ฝั่ง app

- หน้าแต่งตัวตาม frontend-guide (reuse `lib/avatar-part/*` ของ #638 — ห้ามเขียน renderer ซ้ำ) + 18 หมวด + label workspace
- Save: await + disable ปุ่ม ("กำลังประกอบชุด…") · 5xx/network → retry 1 ครั้งหลัง 3s → toast "บันทึกไม่สำเร็จ กรุณาลองใหม่" (AC-EP01-*) · 4xx → toast ตาม code + reload catalog ถ้า `PART_NOT_*`
- Cancel/ESC/คลิกนอก ขณะ dirty → confirm "ยังไม่บันทึก ต้องการออกไหม?" (ตัดสิน C-6)
- แทน `zyra_selected_avatar` (localStorage global) ด้วย outfit ต่อ workspace จาก API · VO ใช้ `baked.walk_url/sit_url` แทน `walking_spritesheet_url`
- ระบบเดิม (`tb_avatar`, change-character-modal) คงไว้จนระบบใหม่ขึ้น prod (TD §11)

### 9.6 ลำดับ PR (ร่าง — ต่อจาก task-breakdown ของ Admin)

| # | Repo | งาน | ขึ้นกับ |
|---|---|---|---|
| ~~M-0~~ ✅ | api | ~~แก้ `tb_user_outfit` เป็น PK `(user_id, workspace_id)`~~ → ทำแล้วใน zyra-api#185 (migration 119) | **มติ C-14 ✅** · Ten รับทราบ |
| M-0b | api + app | ตัวดูด ramp สีผิว 4 เฉดจากชีท body (Go bake + TS preview, parity test) | มติ Q-4 ✅ · ชีท body Default จากศิลปิน |
| M-1 | api | `GET catalog` (18 หมวด) / `GET default` / `GET workspaces/:id/avatar/outfit` + test | M-0, M-0b |
| M-2 | api | `PUT workspaces/:id/avatar/outfit` + validate (member, hidden) + bake + R2 + test | M-1, #180 |
| M-3 | api + ws | publish `outfit_updated` (มี `workspace_id`) + ws ส่งทุก socket ของ user + test | M-2, Q-13 |
| M-4 | app | หน้าแต่งตัว (stage + skin 5 เฉด + 18 tabs + swatch + none + label workspace) ต่อ API จริง | #638, M-1, Q-4c |
| M-5 | app | save flow / retry / toast / confirm / hidden note | M-2, M-4 |
| M-6 | app | VO ใช้ baked URL ต่อ workspace + รับ `outfit_updated` / `outfit_reset` + entry point | M-3, Q-7 |

---

## 10. Open questions

| # | คำถาม | ถามใคร | Block |
|---|---|---|---|
| ~~Q-1~~ ✅ | ~~ยึด paper-doll แทน Skin + 5 accessory?~~ → **มติ: ประกอบเป็นชิ้น ๆ** (§8.3) · เหลือ: แก้ ClickUp SC-AV-02 ให้ตรง | rif | — |
| ~~Q-2~~ ✅ | ~~(C-14) ชุดแยกต่อ workspace หรือชุดเดียว?~~ → **มติ 2026-10-22: แยกต่อ workspace** (§8.3) · ✅ ทำแล้ว zyra-api#185 / zyra-ws#87 | rif | — |
| Q-3 | เอกสาร `AvatarCustomization/spec.md` + `technical-design.md` ต้นฉบับ (มติ 2026-10-05) — โฟลเดอร์ `zyra/custom avatar/` ที่ได้มา **เป็นไฟล์ sprite 72 ไฟล์ ไม่ใช่เอกสาร** (ตรงกับ "demo file/custom avatar" ที่ Admin TD §3 อ้าง) → เอกสารต้นฉบับยังไม่มี · ถ้าไม่มีแล้วจริง ให้ถือไฟล์นี้เป็นฉบับหลัก · **อัปเดต 2026-10-22:** `technical-design.md` ต้นฉบับ (ร่าง 2026-10-05) ขึ้น git แล้วพร้อมหัวเอกสารบอกส่วนที่ถูกแทน · `spec.md` ต้นฉบับ (ร่าง 2026-10-08) ยังไม่ขึ้น git — มีสำเนาในเครื่อง Ten (`zyra-doc-local-backup-2026-10-22/`) ถ้าต้องใช้ให้บอก | rif / ผู้เขียนเดิม | ความครบของ spec |
| ~~Q-4~~ ✅ | ~~ชิ้น skin เก็บอะไร~~ → **ชีท body ตัวเต็ม + ดูดสีผิว 4 เฉดอัตโนมัติ** (§9.3) | rif | — |
| ~~Q-4b~~ ✅ | ~~เลือกเฉดสีผิวได้ไหม~~ → **มี skin เริ่มต้น 5 เฉดให้เลือก** (ของระบบ ไม่อัปโหลด) (§9.3) | rif | — |
| ~~Q-4c~~ ✅ | ~~ค่าสี 5 เฉด + Default~~ → Fair `#F6D5B3` · Light Beige `#E0B491` · Tan `#C58F69` · Brown `#9C694E` · Dark Brown `#684B3D` · **Default = Fair** (มติรอบ 7) | rif | — |
| ~~Q-5~~ ✅ | ~~รายชื่อ slot~~ → **18 หมวด** ตาม Figma / Admin TD §2 · เหลือ: Wings → `back`, Outfit → top/outer/dress/bottoms (ตาม TD) · โฟลเดอร์ asset มี "บลัชออน" ซึ่งไม่อยู่ใน 18 หมวด (น่าจะเป็น `face`?) | rif · Ten ยืนยัน mapping | — |
| Q-6 | (C-15) Bag อยู่หลังตัวตาม ClickUp หรือ layer 6 ตาม TD? z-order เปลี่ยนตามทิศไหม (หันหลังแล้ว `back` อยู่หน้า)? | Designer + Ten | layer |
| ~~Q-6b~~ ✅ | ~~ลบออกจากสมาชิกแล้วกลับมา~~ → **เก็บชุดเดิม** (§9.2) | rif | — |
| Q-7 | (C-18) หน้าแต่งตัวเป็น modal/side panel (ClickUp), หน้าเต็ม "Dressing room" (Figma) หรือ route เดี่ยว (frontend-guide)? เปิดจากไหน: sidebar / HUD / Settings / lobby / Profile? — หลังมติ C-14 ถ้าเปิดจาก Profile (นอก workspace) ต้องให้เลือก workspace ด้วย | PM + Designer | UI |
| Q-8 | Figma "Slot" = preset หลายชุด — อยู่ใน scope ไหม? (ClickUp ไม่มี, data contract ไม่มี) | PM | data model |
| Q-9 | "ถอดทั้งหมด" (optional) ทำไหม? ในระบบใหม่ slot required ถอดไม่ได้ → หมายถึงถอดเฉพาะ optional? มี "ชุดเริ่มต้น" แทนพอไหม? | PM | UI |
| Q-10 | Auto-retry เฉพาะ 5xx/network ใช่ไหม? ระหว่างรอ 3s ปุ่มแสดงอะไร? (bake อาจใช้เวลา — timeout เท่าไร) | PM + Ten | UX |
| Q-11 | Tab ที่มี draft ค้างแล้วได้ event — ทับ draft หรือแค่อัปเดตชุดที่บันทึก? | PM | UX |
| Q-12 | Mobile: ClickUp ติ๊ก Desktop อย่างเดียว — Lite mode / `mobile-character-page.tsx` ใช้ชุดใหม่ยังไง? | PM | scope |
| Q-13 | ชื่อ event: `ws:avatar:updated` (ClickUp) หรือ `outfit_updated` คู่กับ `outfit_reset`? | Ten | ws |
| Q-14 | (C-17) path `GET /api/user/me/outfit` หรือ `/api/user/avatar/outfit`? code hidden `PART_NOT_SELECTABLE` หรือ `PART_NOT_FOUND`? | Ten | API |
| Q-15 | User เดิมที่เลือก character `tb_avatar` ไว้ — ได้ชุด default ทั้งหมดเมื่อเปิดระบบใหม่ใช่ไหม? | PM | migration |
| Q-16 | ClickUp due 2026-10-19 เลยแล้ว subtask ทั้งหมด `pending` — กำหนดใหม่? ใครรับ member side (data/ บอกว่าส่งให้ "ทีมหน้าบ้าน") | PM | planning |

ข้อที่ยังรอจากเอกสาร Admin และกระทบ SC-AV-02 ด้วย: **D1** (48 vs 64px — asset จริงใน `zyra/custom avatar/` เป็น 192×192 = 48 px ทุกไฟล์), **D3** (default Active/Hidden), ~~D4~~ (มติ 18 หมวด), **D5** (sit ของ hair) — ดู Admin TD §12

---

## 11. Dependencies

- ~~Admin PR #179 / #180 / #638 / #639 merge → API-3~5~~ ✅ merge เข้า develop ครบแล้ว (api #179–#184, app #638–#644) + #185 / ws#87 (C-14)
- ~~แจ้งมติ C-14 ให้ Ten ก่อน #179 merge~~ ✅ Ten รับทราบ 2026-10-22 → แก้ตามใน zyra-api#185 + zyra-ws#87 + เอกสาร Admin
- แก้ ClickUp SC-AV-02 ให้ตรงกับมติ (paper-doll 18 หมวด, skin = Default)
- ยืนยันค่าสี 5 เฉดสีผิว (Q-4c)
- Asset: **ชีท body Default** (ไม่มีใน `zyra/custom avatar/`) + ชิ้น default ของหมวดบังคับ + palette ชุดสุดท้าย (ศิลปิน) · ชิ้นอื่นมีแล้ว 72 ไฟล์ใน `zyra/custom avatar/` (ยังไม่ได้อยู่ใน git — โฟลเดอร์อยู่ที่ root workspace ซึ่งไม่ใช่ repo)
- Figma node ของ SC-AV-02 ที่เหลือ 6 ตัว (ติด rate limit) ก่อนทำ `ux-ui-plan.md`

---

## 12. Non-functional / ข้อพิจารณา

- **Latency:** คนอื่นเห็น ≤ 2s นับจาก PUT 200 — รวมเวลา bake ไม่ได้ (bake อยู่ก่อน 200) แต่ user รอปุ่ม "กำลังประกอบชุด…" นานขึ้น → วัดเวลา bake
- **Cache:** baked URL ใช้ hash เป็น path → immutable cache ได้ · ชุดเหมือนกันใช้ไฟล์เดียว
- **Backward compat:** client เก่ายังส่ง `walking_spritesheet_url` ของ `tb_avatar` — VO ต้องแสดงได้ทั้งสองแบบช่วงเปลี่ยนผ่าน (sheet 4×4 เดิม vs 5 คอลัมน์ 240×192 ใหม่ — ตรวจ `zyra-engine/avatar-frames.ts`)
- **Authorization:** member อ่าน/เขียนได้เฉพาะชุดตัวเอง และเฉพาะ workspace ที่ตนเป็น member (`403 NOT_WORKSPACE_MEMBER`) · ห้ามใช้ `/api/admin/*` (rule 15)
- **Storage:** bake upload ผ่าน `storage.S3Client.UploadPNG` (rule 11)
- **Analytics:** ClickUp ไม่ได้ระบุ — ไม่ทำเอง

---

## 13. Readiness

| เกณฑ์ | สถานะ |
|---|---|
| Source link ครบ | ✅ ClickUp 9 subtask + Admin 6 ใบ + เอกสาร Admin (TD/requirements/data) |
| Scenario / AC (ClickUp) | ✅ ถอดครบ 9 scenario (55 AC) |
| Baseline โค้ด | 🟡 ตรวจ 2026-10-22 ก่อน Admin PR merge — ต้องตรวจใหม่ (§5.6) |
| ระบบเป้าหมาย | 🟡 สรุปจากเอกสาร Admin · ต้นฉบับ [technical-design.md](technical-design.md) ขึ้น git แล้ว (ร่าง 2026-10-05 บางส่วนถูกแทน) |
| Figma | ⚠ อ่านได้ 1/7 node (rate limit) |
| Scope ตกลงแล้ว | 🟡 Q-1 ✅ paper-doll · C-14 ✅ ต่อ workspace · C-13 ✅ skin = Default · Q-4 ✅ · Q-5 ✅ 18 หมวด · Q-6b ✅ · Q-4b ✅ 5 เฉด · ❌ Q-4c (ค่าสี 5 เฉด) |
| API / WS contract | ❌ ข้อเสนอ (§9.2, §9.4) — รอ Q-13, Q-14 + ทีม Admin รับมติ |
| Dependency Admin | ✅ API-1~6 + APP + C-14 (zyra-api#185 / zyra-ws#87) merge เข้า develop แล้ว |

**สรุป: ยังไม่พร้อม implement** — ขั้นต่อไป: ~~แจ้ง Ten เรื่องมติ C-14~~ (ทำแล้ว) · ยืนยัน Q-4c → แก้ ClickUp SC-AV-02 → `technical-design.md` (ฝั่ง member) + `ux-ui-plan.md` → `task-breakdown.md` / `test-plan.md`

---

## Changelog

| วันที่ | เปลี่ยนอะไร |
|---|---|
| 2026-10-22 | สร้าง spec ฉบับแรก: ถอด ClickUp SC-AV-02 ครบ 9 scenario + SC-AV-01 ที่เกี่ยว, baseline โค้ด 3 repo, gap, conflict, open question |
| 2026-10-22 (รอบ 2) | หลัง merge `origin/main` เข้า `rif`: อ่านเอกสาร Admin (`[Module] Avatar & Accessories Management (Admin)/` — TD, requirements, data contract, progress รอบ 6) → เพิ่ม §5.6 PR ที่กำลังทำ, §6 ระบบเป้าหมาย (paper-doll + bake), เขียน gap ใหม่เทียบ 2 ฐาน (§7), conflict ใหม่ C-13~C-19 (สำคัญ: **C-14 ต่อ workspace vs global**), ถอนข้อเสนอรอบแรก (5 slot + multi-layer VO) แทนด้วย §9, open questions ใหม่ 16 ข้อ |
| 2026-10-22 (รอบ 3) | **มติ rif: C-14 → ชุดแยกต่อ workspace · C-13 → Skin เป็นชิ้นที่ admin อัปโหลด/ซ่อนได้** (ยึด ClickUp ทั้งสองข้อ) → เพิ่ม §8.3 decision log, เขียน §9 ใหม่ (§9.2 schema/API/UI ต่อ workspace + ผลต่อ Admin, §9.3 หมวด `skin` + hidden/deleted + ทางเลือกเก็บข้อมูล skin, §9.6 PR M-0/M-0b), ปิด Q-2, เขียน Q-4 ใหม่, เพิ่ม Q-6b, Q-3 = rif มีไฟล์ต้นฉบับแล้ว |
| 2026-10-22 (รอบ 4) | มติ rif: **Q-1 paper-doll · C-13 แก้เป็น Skin = Default ไม่อัปโหลด · Q-4 ชีท body ตัวเต็ม + ดูดสีผิว 4 เฉด · Q-5 18 หมวด · Q-6b เก็บชุดเดิม** → เขียน §9.3 ใหม่, แก้ §8.3/§9.1/§9.6/§10/§11/§13 · เพิ่ม Q-4b (เลือกเฉดสีผิวได้ไหม) · Q-3: `zyra/custom avatar/` เป็นไฟล์ sprite 72 ไฟล์ (192×192 → 48 px) ไม่ใช่เอกสาร |
| 2026-10-22 (รอบ 5) | Q-4b: skin เริ่มต้น 5 เฉด (ของระบบ) → แก้ §9.3, §9.1, §8.3, AC ที่ใช้ได้ (AC-HP02 กลับมาใช้) · เพิ่ม Q-4c (ค่าสี 5 เฉด vs 6 ค่าใน data contract) |
| 2026-10-22 (รอบ 6) | ฝั่ง Admin (Ten ผ่าน Claude Code) อัปเดตตามมติ C-14: §5.6 สถานะ PR (merge แล้ว + #185 / ws#87) · §9.2 DB ทำแล้วด้วย migration 119 (แทนการแก้ 118 เพราะ #179 merge ก่อน spec ขึ้น main) · ผลต่อ Admin ทำแล้ว · M-0 / Q-2 / §11 / §13 อัปเดต · ต้นฉบับ `technical-design.md` (ร่าง 2026-10-05) ขึ้น git |
| 2026-10-22 (รอบ 6) | ถอด Figma `pQlFqPDRdEsTAVnfOrcO5h` canvas `7454:438285` ลง [ux-ui.md](ux-ui.md) (ขัดกับ ClickUp ~18 ข้อ — ux-ui §8: บันทึกอัตโนมัติ, EP-01 กลับชุดเดิม, หน้าเต็มจอ, SLOT 1–5, Undo/Redo, double-click ถอด ฯลฯ) · เพิ่ม [technical-design-member.md](technical-design-member.md) (ฝั่ง member บน develop — ไม่ทับ technical-design.md ต้นฉบับ) · Q-4c ได้ค่าสี 5 เฉด |
| 2026-10-22 (รอบ 7) | มติ D-M1 บันทึกอัตโนมัติ · D-M3 SLOT 1 อย่างเดียว · Default = Fair · เริ่ม implement (ดู progress.md) |
