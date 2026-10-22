# SC-AV-02 — Avatar Customization (Client) — UX/UI Spec จาก Figma

> **สถานะ:** Draft · 2026-10-22 · ค่าทั้งหมดดึงจาก Figma MCP (`get_design_context` / `get_variable_defs` / `get_metadata` / screenshot) ไม่ได้เดา — ส่วนที่ยังไม่ได้ดึงระบุไว้ใน §0 · ยังไม่ implement · **repo:** zyra-app
> **Source:** Figma `pQlFqPDRdEsTAVnfOrcO5h` (Zyra design COPY) · canvas `7454:438285` "🚧 Avatar customisation" · frame 1440 × 1024 (Desktop)
> **เอกสารคู่กัน:** [spec.md](spec.md) (AC IDs §4, มติ §8.3, แนวทาง §9) · [technical-design.md](technical-design.md) · [technical-design-member.md](technical-design-member.md) · ฝั่ง Admin: [ux-ui-plan.md](<../[Module] Avatar & Accessories Management (Admin)/ux-ui-plan.md>)
> **ข้อสำคัญ:** Figma ต่างจาก ClickUp / spec หลายจุดที่เปลี่ยน behavior (auto-save, revert ตอน error, หน้าเต็ม, Slot preset ฯลฯ) — รวมไว้ใน §8 **ยังไม่ได้ตัดสิน ห้าม implement ส่วนนั้นจนกว่าจะได้มติ**

---

## 0. สิ่งที่ยังไม่ได้ดึง (ต้องดึงเพิ่มก่อน implement ส่วนนั้น)

| # | เรื่อง | node | เหตุผล |
|---|---|---|---|
| N-1 | สี stroke ของ Divider ใน Category column | `7648:358142`, `7692:55515` (ใน `7535:1845`) | เป็น SVG asset — ได้แค่ว่าเส้นหนา ~4 px (inset −4 px) ยังไม่ได้อ่าน stroke |
| N-2 | สี icon ใน Undo / Redo / Clear / chevron-up / chevron-down | `7611:202643`, `7648:361855`, `7611:202658`, `7537:184469`, `7537:184493` | เป็น SVG asset |
| N-3 | สี / รูปของ spinner บนตัวละคร | `7698:140809` (และ `7698:183308`, `7698:140816`, `7709:208092`, `7698:180249`) | layer ชื่อ `fa-solid:spinner` (Font Awesome) ยังไม่ได้ดึง design context |
| N-4 | state "เลือกแล้ว" ของ swatch สี และ gradient ของแถบ Shade | `I7698:78496;7692:55760`…, `I7698:78496;7709:203564` | design context คืนแค่ wrapper (sparse) — swatch เป็น SVG |
| N-5 | hover / pressed / disabled / focus ของทุก component | — | component ใน Figma มีแค่ variant ที่ระบุใน §5 (ไม่มี hover variant) |
| N-6 | tooltip ใน frame `7615:207396` | `7615:209200` (x 25, y 645, 82 × 31) | ไม่ได้ screenshot frame นี้ — น่าจะเป็นชื่อ item ตอน hover ช่องใน Costume panel (ยังไม่ยืนยัน) |
| N-7 | frame ปลายทางของ HP-06 / EC-03 / EP-01 บางอัน | `7698:180245`, `7698:180246`, `7709:208088`, `7709:208089`, `7698:183305`, `7698:187936`, `7698:198158` | ดูจาก screenshot ระดับ section เท่านั้น ไม่ได้ดึง design context |
| N-8 | iPhone frames 9 อัน | `7557:186254`, `7568:186440`, `7568:186455`, `7568:186460`, `7561:186324`, `7567:186377`, `7561:186340`, `7564:186349`, `7565:186367` | ดู screenshot แค่ `7557:186254` = ภาพ promo "Walk around your Virtual Workspace" (ไม่ใช่หน้าแต่งตัว) · อีก 8 อันยังไม่ได้ดู |
| N-9 | Asset raster: ฉากพื้นหลัง "Dressing room", `base_platform`, `wardrobe 1`, `slote`, ลาย `Layer_1` ใน card | `7535:1845`, `7709:220614`, `7680:45463`, `7648:213498`, `7537:113405` | ต้อง export ไฟล์จริงตอน implement (URL ของ MCP หมดอายุ 7 วัน) |
| N-10 | ขนาดสเกลตัวละครบนเวที | `7691:55444` (400 × 600) | Figma ใช้รูปนิ่ง 400 × 600 — ไม่ใช่ผลคูณของเฟรม 48 px (ดู Q-D11) |
| N-11 | Section ว่าง / รูป 512 px นอก section | `7675:16312`, `7675:16313`, `7679:16345`, `7621:213239`, `7648:213241`, `7648:213422`, `7648:213244`, `7621:213240`, `7648:213242` | ไม่อยู่ใน flow — ไม่ได้ตรวจ |

---

## 1. Scenario → หน้าจอ (Screen inventory)

| Scenario (ClickUp) | Section node | Frame / node | หน้าจอแสดงอะไร | AC ที่ครอบ |
|---|---|---|---|---|
| HP-01 เปิด | `7454:600826` | `7454:661540` Before enter space | หน้า lobby "Welcome to Starlight world" มีปุ่ม **Customise avatar** ใต้ตัวละคร | AC-HP01-1 (บางส่วน — entry ต่างจาก ClickUp §8 CF-4) |
| HP-01 เปิด | `7454:600826` | `7454:661263` Availability Status - Set status | VO + panel โปรไฟล์ เมนู **Customise avatar** | AC-HP01-1 (บางส่วน) |
| HP-01 เปิด | `7454:600826` | `7535:1845` Dressing room (symbol หลัก) | หน้าเต็ม "Customise avatar" + ชื่อ workspace · ตัวละคร default · Slot 1–5 · Costume / Accessory panel · Category column · Items | AC-HP01-2 (ภาพนิ่ง), AC-HP01-3, AC-HP01-4, AC-HP01-5 (ต่างถ้อยคำ) |
| HP-01 | `7454:600826` | `7732:67665` Category | แถบหมวดเต็มความยาว 19 ปุ่ม + divider 2 เส้น (ไว้ดูลำดับ) | AC-HP03-1 (แทนด้วย 19 หมวด) |
| HP-01 | `7454:600826` | `7726:221660` Dressing room | สถานะ Slot (มี sticky `7726:222732`) | — (ไม่มีใน ClickUp) |
| HP-02 เลือก Skin | `7454:600826` | `7615:207397` Customise avatar - Skin tone | หมวด Skin tone · 5 card + tooltip ชื่อเฉด · tooltip Undo/Redo/Clear · tag **Used** | AC-HP02-1, -2, -4, -5 (เป็น "Used"), -6, -7 |
| HP-02 | `7454:600826` | `7615:207396` Customise avatar - Skin tone | สถานะหลังเลือกเฉด (tooltip ที่ช่อง Costume panel) | AC-HP02-2, -3 |
| HP-03 สวม | `7621:209204` | `7648:337705` → `7698:140811` → `7695:76412` | เลือก Dress → **spinner บนตัวละคร** → ใส่แล้ว + แถบสี | AC-HP03-4, -5 |
| HP-03 | `7621:209204` | `7695:77451` → `7698:78496` | หมวด Neck → ใส่ผ้าพันคอ + แถบ Shade + palette (ช่อง Accessory panel highlight ฟ้า) | AC-HP03-4, -5, -8 |
| HP-04 ถอด | `7648:348156` | `7698:79547` → `7698:82581` | double-click ผ้าพันคอใน Accessory panel → ถอด | AC-HP04-2 (วิธีต่างจาก ClickUp) |
| HP-04 | `7648:348156` | `7648:357077` | หลังกด Clear (ถังขยะ) → เหลือชุดขาว + skin default | AC-HP04-5, -6 (ความหมายต่าง) |
| HP-05 บันทึก | `7698:83967` | `7698:140813` → `7698:140814` (spinner) → `7698:140812` → `7698:145174` → `7698:145740` | แต่ง → spinner → ใส่แล้ว → กดย้อนกลับ → lobby เห็นชุดใหม่ → VO เห็นชุดใหม่ | AC-HP05-2, -4 (ไม่มีปุ่มบันทึก — CF-1) |
| HP-06 ต่าง workspace | `7698:146753` | Workspace A: `7698:175980` → `7698:175981` → `7698:175985` → `7698:175982` · Workspace B: `7698:179141` → `7698:179240` → `7698:180246` → `7698:180247` → `7698:180245` | A "Starlight world" เปลี่ยนผิว · B "Home Sweet Home" ใส่ Dress — subtitle ใต้หัวเปลี่ยนตาม workspace | AC-HP06-2, -3 |
| EP-01 error | `7698:183253` | `7698:183305` → `7698:183306` (spinner) → `7698:186582` (toast) → `7698:187936` | เลือกชุด → spinner นาน → toast "Unable to update avatar" → **กลับเป็นชุดเดิม** | AC-EP01-1 (ข้อความต่าง), -4 · ขัด AC-EP01-2/-3 (CF-2) |
| EC-02 ถูกซ่อน | `7698:188932` | `7698:194988` → `7698:193963` → `7698:198158` | lobby (ผิว Tan) → เปิดแต่งตัว: card Tan หาย, ช่อง skin ใน Costume panel เป็นสีแดง (Error), toast "Item no longer available" → เลือกเฉดใหม่ | AC-EC02-1, -2, -3 (ข้อความต่าง) — แต่ขัดมติ C-13 (CF-13) |
| EC-02 ถูกลบ | `7698:188932` | `7698:199164` | toast "Item removed" — skin กลับค่าตั้งต้น | AC-EC02-6 |
| EC-03 หลาย tab | `7709:208066` (ชื่อ layer ว่า HP-06 แต่หัว Title Flow คือ EC-03) | แถว "Tap 1": `7709:208070` → `7709:208072` → `7709:208077` → `7709:208074` · แถว "Tap 2": `7709:208071` → `7709:208073` → `7709:208089` → `7709:208090` → `7709:208088` → `7709:215360` | สอง tab แต่งพร้อมกัน → tab 2 save ทีหลัง → VO แสดงชุดล่าสุด | AC-EC03-1, -2, -3, -6 · ไม่มี AC-EC03-4 (refresh panel tab อื่น) |
| Mobile | — (อยู่นอก section, ระดับ canvas) | iPhone frames 9 อัน (N-8) | อันที่ดู = ภาพ promo ไม่ใช่หน้าแต่งตัว | — |

### 1.1 Sticky note ของ designer (อ้างตามหน้าจอ)

| Sticky | อยู่ข้าง | ข้อความ (คงต้นฉบับ) |
|---|---|---|
| `7648:255732` | HP-01 lobby → Dressing room | เมนู Change Avatar > เปลี่ยนเป็น Customise avatar มีชื่อ Workspace กำกับตรงข้างล่างปุ่มย้อนกลับ |
| `7691:55511` | HP-01 | ตัวละคร Default ใส่ชุดขาว สีผิว Default |
| `7648:336814` | HP-01 | เมื่อมีการสวมใส่อุปกรณ์แต่ละอัน ตรง Costume Panel ก็จะบอกว่า Avatar กำลังใส่อะไรอยู่ ส่วน Accessory ก็จะแยกไปอยู่อีก Panel หนึ่ง |
| `7648:336818` | HP-02 | เมื่อมีการคลิกที่ Item card ด้านขวา เช่น สีผิว ช่อง Costume Panel จะแสดงของที่เรากำลังสวมใส่และมีไฮไลท์สีฟ้าปรากฎ + ข้างล่างจะเป็น Colour palate ของ Items นั้นๆ ให้เลือก Hover ตรง Panel ก็จะมีชื่อของ Item นั้นปรากฎเหมือนกับการ์ด |
| `7695:74142` | HP-02 | *Skin tone ไม่สามารถถอดได้ ต้องเปลี่ยน Skin tone เท่านั้น **ถ้ากด Clear Skin tone กลับมาที่ Default |
| `7732:68087` | Category column | Skin tone Hair Eye Face Facial hair Top Outer Bottom Shoes Dress Dress/Outfit Special Costume Hat Glasses Mask Neck Bag Belt Back Companion |
| `7648:336822` | HP-02 | Hover แสดงชื่อ Items Menus |
| `7726:222732` | Slot | Slot หรือก็คือ Preset เครื่องแต่งกาย ถ้าสมมุติอยากใช้เครื่องแต่งกายของ Slot 2 ก็ต้องเลือก Slot 2 และพอย้อนกลับใน Workspace ก็จะโชว์เครื่องแต่งกายใน Slot 2 แต่ถ้าอยากได้เครื่องแต่งกายจาก Slot 1 ก็ต้องกลับเข้ามาเลือก Slot 1 และกดย้อนกลับไป Workspace |
| `7732:67658` | Slot / สี | Special costume จะไม่มีความเข้มของเฉดสี เพราะเป็นการกำหนดสีเองที่หลังบ้าน |
| `7698:119248` | HP-03 | ตอนสวมใส่อุปกรณ์ ถ้าอินเทอร์เน็ตผู้ใช้ช้าให้มี Icon reload บนตัวละคร |
| `7695:78447` | HP-03 | Double click ที่ Panel เพื่อถอดเสื้อ Avatar |
| `7709:204981` | HP-03 | สามารถเลื่อนเฉดสี และ Items เปลี่ยนเฉดสีตามได้ |
| `7698:79543` | HP-03 | เปลี่ยนสีของ Item |
| `7698:80536` | HP-04 | กด Double click ที่ ผ้าพันคอ |
| `7648:360156` | HP-04 | กด ย้อนกลับ Action |
| `7648:358156` | HP-04 | Clear all · ลบแค่ Items · Skin tone กลับไปเป็น Default · อยู่ Slot ไหน ลบแค่เฉพาะ Slot นั้น |
| `7698:143821` | HP-05 | ฟีเจอร์ห้องแต่งตัวจะเป็นการ **บันทึกอัตโนมัติ** เมื่อมีการเปลี่ยนเสื้อผ้า สามารถกด ย้อนกลับได้เลย ถ้าผู้ใช้งานแต่งตัวอะไรเสร็จ |
| `7698:187581` | EP-01 | Reload นานเกินไปเนื่องจาก Network error · Reload หาย กลับมาเป็นชุดเดิม · Toast ปรากฎ |
| `7698:194984` | EC-02 | ถ้าอยู่ใน Workspace จะแสดงสีผิว Tan ปกติ แต่พอเข้าใน Customise avatar Tan skin tone card หาย และมีขึ้นแจ้งเตือนให้เปลี่ยน |
| `7698:200256` | EC-02 | ถ้ามีการลบ Item Skin tone จะกลับมาค่าตั้งต้น |
| `7709:215560` | EC-03 | Tap 2 เซฟทีหลัง ระบบจะแสดงข้อมูลล่าสุด |

---

## 2. Design tokens (จาก `get_variable_defs` ของ `7535:1845` + ที่ component อ้าง)

| Token | ค่า | ใช้ที่ | ตรงกับฝั่ง Admin |
|---|---|---|---|
| Shade Black/500 | `#1A1B1E` | tooltip, toast | ✅ |
| Shade Black/50% | `rgba(26,27,30,0.5)` | Costume/Accessory panel, item card, แถบสี | ใหม่ |
| Shade Black/400 | `#232427` | ปุ่มหมวด inactive, Slot inactive | ใหม่ (admin ใช้ใน colour picker dropdown) |
| Solid Black/70% | `rgba(0,0,0,0.7)` | Headbar | ใหม่ |
| Primary/500 | `#58D68D` | label Slot ที่เลือก, tag Used, ปุ่ม Join space | ✅ |
| Primary/10% | `rgba(88,214,141,0.1)` | bg + border tag Used | ✅ |
| Grey/500 | `#8C99A6` | label Slot ไม่ได้เลือก | ✅ |
| Blue/500 | `#2DB6FF` | border ช่องที่เลือกใน Costume/Accessory panel | ✅ |
| Blue/10% | `rgba(45,182,255,0.1)` | กล่อง icon toast info | ⚠ admin ใช้ 20% กับ toast สำเร็จ |
| Yellow/500 · Yellow/10% | `#ECC819` · `rgba(255,212,0,0.1)` | toast EP-01 | — |
| Red/500 · Red/50% | `#F03A3A` · `rgba(240,58,58,0.5)` | ช่อง panel สถานะ Error | ✅ (Red/500) |
| Solid White/5% · 10% · 20% | `rgba(255,255,255,.05/.1/.2)` | ปุ่ม Customise avatar / พื้นรูปใน card / ช่อง panel + border | ✅ |
| Theme colour/Primary | `#242B32` | panel lobby, panel โปรไฟล์ VO, input | ✅ (= Background/Primary) |
| White shadow | drop-shadow `0 4 8 rgba(255,255,255,0.08)` (token เขียน radius 16 แต่โค้ดที่ export ใช้ blur 8) | tooltip, toast | ✅ (toast) |

Typography (Inter ยกเว้นระบุ):

| Style | size / line-height / weight / letter-spacing | ใช้ที่ |
|---|---|---|
| H/Bold | 20 / normal / 700 | "Customise avatar", ชื่อหมวดเหนือ Items |
| Sub/Regular | 16 / 22 / 400 | ปุ่ม Join space |
| Sub/Medium | 16 / 22 / 500 | ชื่อใน panel โปรไฟล์ VO |
| Body/Bold · Body/Regular | 14 / 18 / 700 · 400 | หัว toast · ข้อความ toast, ชื่อ workspace, หัว panel "Costume"/"Accessory" |
| Caption 1/Regular | 12 / 15 / 400 / −0.43% | tooltip, tag Used |
| Caption 2/Regular | 10 / 13 / 400 / −0.43% | "+N" ใต้ card |
| **Bagel Fat One** Regular | 16 / normal | label "SLOT 1"–"SLOT 5" — **ฟอนต์นี้ยังไม่มีใน zyra-app** (Q-D9) |

---

## 3. Layout ระดับหน้า — Dressing room (`7535:1845`, 1440 × 1024)

ทุกชิ้นวางแบบ absolute บนฉากเต็มจอ:

| ส่วน | node | ตำแหน่ง (left, top) | ขนาด |
|---|---|---|---|
| ฉากพื้นหลัง (raster "Dressing room") | `7535:1845` | 0, 0 | 1440 × 1024 · object-cover |
| Overlay | `7691:55488` | 0, 0 | 1440 × 1024 · bg `rgba(0,0,0,0.1)` · mix-blend **soft-light** |
| Headbar | `7611:199938` | 0, 72 | 380 × 82 |
| Slot bar | `7496:35299` | 248, 170 | 384 × 71 |
| Costume panel | `7581:189585` | 17, 274 | 170 × 482 |
| Accessory panel | `7581:190186` | 661, 274 | 170 × 338 |
| เวที (`base_platform`) | `7709:220614` | 104, 772 | 640 × 154 |
| ตัวละคร (`Dressed character`) | `7691:55444` | 226, 321 | 400 × 600 |
| Spinner (ตอนโหลด) | `7698:140809` | 366, 628 | 120 × 120 |
| Action (Undo/Redo/Clear) | `7648:361698` | 789, 630 | 42 × 158 |
| แถบ Shade | `7709:202855` | 229, 916 | 394 × 42 |
| แถบ Palette | `7615:207339` | 341, 966 | 170 × 42 (hug ตามจำนวนสี) |
| Container ขวา (Category + Items) | `7611:199955` | 847, 0 | 593 × 1024 · flex row · py 40 |
| Toast | `7698:187921` ฯลฯ | 1088, 16 (ขวาบน inset 16) | 336 × 94 |

> ปุ่ม `Button` 80 × 80 + `Cheron-left` 40 สองอัน (`7508:194764`, `7508:194766`) วางที่ x 1714 — **อยู่นอกเฟรม** ไม่เห็นในหน้าจอ ไม่ต้องทำ (Q-D12)

---

## 4. Entry points

### 4.1 Lobby — Before enter space (`7454:661540`, ส่วนขวา `7698:145547`)

| ส่วน | ค่า |
|---|---|
| Container ขวา | flex-col · gap 40 · items-center · w 324 |
| Character name | label Body/Regular white · input h 42 · px 12 · py 8 · radius 8 · bg `#242B32` · border 1 white 20% |
| ตัวละคร | 67 × 100 (`Dressed character`) · gap 8 กับปุ่ม |
| ปุ่ม **Customise avatar** | h 32 · px 16 · py 8 · radius 6 · bg white 5% · border 1 white 20% · Body/Regular white |
| ปุ่ม Join space | h 42 · w 100% · radius 8 · bg `#58D68D` · Sub/Regular white |

### 4.2 VO — panel โปรไฟล์ (`7454:661263` › `7454:661265`)

| ส่วน | ค่า |
|---|---|
| Panel | w 322 · bg `#242B32` · radius 16 · padding 16 · gap 16 |
| แถวเมนู | min-h 42 · padding 12 · radius 8 · gap 8 · icon 16 · Body/Regular white (ellipsis) |
| รายการ | "Edit profile" · **"Customise avatar"** · "Back to workspace" |

ของเดิมใน zyra-app: panel ใช้ `t("changeAvatar")` = "Change avatar" / "เปลี่ยนอวาตาร์" (`messages/*.json` บรรทัด 1484) และหน้า welcome space ใช้ `changeCharacter` = "Change character" / "เปลี่ยนตัวละคร" (บรรทัด 4003 · `views/user/space-builder/hero-welcome-space.tsx`, `mobile-welcome-space.tsx`) → sticky `7648:255732` ให้เปลี่ยนชื่อเป็น "Customise avatar"

---

## 5. Component

### 5.1 Headbar (`7611:199938`)

| ส่วน | ค่า |
|---|---|
| กล่อง | bg Solid Black/70% `rgba(0,0,0,0.7)` · backdrop-blur 2 · pl 128 · pr 40 · py 16 · radius ขวาบน/ขวาล่าง 90 (ซ้ายเป็นมุมฉาก) · gap 16 |
| Profile row | gap 16 · items-center · ปุ่มย้อนกลับ `Cheron-left` 24 |
| ข้อความ | flex-col gap 8 · "Customise avatar" H/Bold white · ชื่อ workspace (เช่น "Starlight world", "Home Sweet Home") Body/Regular white |
| รูปตู้ (`wardrobe 1`, `7680:45463`) | 120 × 120 · absolute left 16 · top −48 (ล้นขึ้นด้านบน) |

### 5.2 Slot bar + Item slot (`7496:35299`, component `7698:143831`)

| ส่วน | ค่า |
|---|---|
| Bar | flex row · gap 16 · 5 ช่อง |
| Item slot | flex-col · w 64 · items-center |
| วงกลม | 64 × 64 · border 2 white · radius 90 · padding 8 · margin-bottom −16 (label ซ้อนขอบล่าง) |
| icon `slote` (`7648:213498`) | 40 × 40 (raster) · ตอนเลือกมี drop-shadow `0 4 2 rgba(0,0,0,0.2)` |
| เลือกอยู่ (`Property 1=Default` `7648:213495`) | bg linear-gradient ลง `#D1FFDB` → `#54E7B6` (48.077%) → `#C9D658` · label `#58D68D` |
| ไม่ได้เลือก (`Variant2` `7698:143832`) | bg `#232427` · label `#8C99A6` |
| Label | Bagel Fat One 16 / normal · กึ่งกลาง · "SLOT 1"…"SLOT 5" (component master สะกด "SLOT1" ไม่มีเว้นวรรค) |

### 5.3 เวที + ตัวละคร

| ส่วน | ค่า |
|---|---|
| ตัวละคร | `Dressed character` 400 × 600 · ยืนหันหน้า (ภาพนิ่ง ไม่มี animation/ปุ่มหมุน) |
| เวที | `base_platform` 640 × 154 (raster) |
| Loading | spinner 120 × 120 ทับกลางลำตัว (`fa-solid:spinner`) — แสดงระหว่างสวมใส่เมื่อเน็ตช้า (sticky `7698:119248`) · สีไม่ได้ดึง (N-3) |

### 5.4 Costume panel / Accessory panel (`Costume` component `7581:189584`)

| ส่วน | ค่า |
|---|---|
| กล่อง | w 170 · bg Shade Black/50% `rgba(26,27,30,0.5)` · backdrop-blur 6 · radius 16 · padding 16 · gap 8 · flex-wrap กึ่งกลาง |
| หัว | "Costume" / "Accessory" Body/Regular white |
| Grid | 2 คอลัมน์ · gap 8 · w 136 · Costume 6 แถว (h 424) · Accessory 4 แถว |
| ช่อง (`Outfit item` `7581:190796`) | 64 × 64 · radius 8 · padding 8 · border 1 · icon หมวด 40 กลาง (หรือรูปชิ้นที่ใส่ 48 × 48 ถ้ามี) |
| State=Default (`7579:189233`) | bg white 20% · border white 20% |
| State=Click (`7581:190797`) | bg white 20% · **border `#2DB6FF`** (ไฮไลท์ฟ้าของชิ้นที่กำลังแก้) |
| State=Error (`7698:195088`) | bg Red/50% `rgba(240,58,58,0.5)` · border white 20% (ชิ้นที่ใส่อยู่แต่ไม่พร้อมใช้ — EC-02) |

ช่องในแต่ละ panel (ลำดับตาม grid ใน `7535:1845`):

| Panel | ช่องตามลำดับ |
|---|---|
| Costume (11) | Hair · Eye · Face · Facial hair (moustache) · Top · Outer (jecket) · Bottom · Shoes · Dress · Special costume (santa) · **Skin tone** (ช่องสุดท้าย แสดงรูปตัวละครเล็ก) |
| Accessory (8) | Hat · Glasses · Mask · Neck (necklace) · Bag · Belt · Back (wings) · Companion (paw) |

> ใน `7698:193963` (EC-02) ช่อง Top แสดง icon จานสี (skin tone) แทน icon เสื้อ — น่าจะเป็น override ผิดใน Figma (Q-D10)

### 5.5 Action column (`7648:361698`)

flex-col · gap 16 · ปุ่ม 42 × 42 · bg white · radius 8 · padding 8 · icon 16 (สีใน SVG — N-2)

| ปุ่ม | node | icon (ชื่อ layer) | tooltip |
|---|---|---|---|
| Undo | `7611:202643` | `imgUndo` | "Undo" |
| Redo | `7648:361855` | `imgRedo` | "Redo" |
| Clear | `7611:202658` | `imgTrash` | "Clear" |

### 5.6 Category column (`7611:199955` › `7508:224590`, ภาพรวม `7732:67665`)

| ส่วน | ค่า |
|---|---|
| Category group | flex-col · w 102 · px 8 · gap 16 · items-center · สูงเต็ม (944) |
| ปุ่มเลื่อนขึ้น / ลง | 42 × 42 · bg white · radius 8 · padding 8 · icon chevron-up / chevron-down 16 |
| List | flex-col · gap 16 · overflow-clip (เลื่อนด้วยปุ่ม/scroll — เห็นได้ ~8 ปุ่ม) |
| ปุ่มหมวด (`Category Dress room` `7691:47778`) | 80 × 80 · radius 1000 · padding 8 · icon 56 สีขาว |
| Status=Active (`7691:47777`) | bg linear-gradient 180° `rgb(199,253,226)` 0% → `rgb(46,226,172)` 26.923% → `rgb(139,244,148)` 64.904% → `rgb(88,214,141)` 100% · border 2 white · shadow `0 4 12 rgba(0,0,0,0.25)` |
| Status=Inactive (`7691:47779`) | bg `#232427` |
| Divider | w 40 · h 0 · เส้นหนา ~4 (สี N-1) · คั่นกลุ่ม |
| Hover | tooltip ชื่อหมวด (เช่น "Skin tone") เหนือปุ่ม (sticky `7648:336822`) |

**ลำดับหมวด (19 ปุ่ม, 3 กลุ่ม):**

| # | กลุ่ม | ปุ่ม (ใน `7535:1845`) | ชื่อแสดง (tooltip/หัว) | icon symbol | ตรงกับ admin `AccessoryCategoryId` |
|---|---|---|---|---|---|
| 1 | 1 | `7691:47788` | Skin tone | `skin tone 1` `7680:45472` (จานสี) | — (ไม่มี — skin เป็นของระบบ มติ C-13) |
| 2 | 1 | `7691:47858` | Hair | `hair 1` `7680:45456` | `hair` |
| 3 | 1 | `7691:47941` | Eye | `eye 1` `7680:45458` | `eyes` |
| 4 | 1 | `7691:47945` | Face | `face 1` `7680:45457` | `face` |
| 5 | 1 | `7691:47949` | Facial hair | `moustache 1` `7680:45468` | `facial_hair` |
| — | divider | `7648:358142` | | | |
| 6 | 2 | `7691:47937` | Top | `top 1` `7680:45466` | `top` |
| 7 | 2 | `7691:47933` | Outer | `jecket 1` `7680:45455` | `outer` |
| 8 | 2 | `7691:47929` | Bottom | `bottom 1` `7680:45460` | `bottoms` |
| 9 | 2 | `7691:47953` | Shoes | `shoes 1` `7680:45470` | `shoes` |
| 10 | 2 | `7691:53386` | Dress | `dress 1` `7680:45459` | `dress` |
| 11 | 2 | `7691:53442` | Special Costume | `santa 1` `7680:45467` | `special_costume` |
| — | divider | `7692:55515` | | | |
| 12 | 3 | `7691:53498` | Hat | `hat 1` `7680:45464` | `hat` |
| 13 | 3 | `7691:53932` | Glasses | `glasses 1` `7680:45471` | `glasses` |
| 14 | 3 | `7691:54002` | Mask | `mask 1` `7680:45461` | `mask` |
| 15 | 3 | `7691:54072` | Neck | `necklace 1` `7680:45469` | `neck` |
| 16 | 3 | `7691:54142` | Bag | `bag 1` `7680:45462` | `bag` |
| 17 | 3 | `7691:54212` | Belt | `belt 1` `7680:45474` | `belt` |
| 18 | 3 | `7691:54478` | Back | `wings 1` `7680:45473` | `back` |
| 19 | 3 | `7691:54534` | Companion | `paw 1` `7680:45465` | `companion` |

icon อื่นใน section `7648:213497`: `wardrobe 1` `7680:45463` (Headbar) · `slote` `7648:213498` (Slot)

ชื่อแสดงอิงจาก sticky `7732:68087` + หัวหมวดที่เห็นใน frame ("Skin tone", "Dress", "Neck", "Top") — ชื่ออื่นยังไม่เห็นเป็นข้อความใน frame จริง

> ต่างจากฝั่ง Admin (`lib/avatar-part/constants.ts` บน develop): ลำดับในกลุ่ม 2 ของ Admin คือ Top, Outer, **Dress**, Bottoms, Shoes, Special แต่ Figma client คือ Top, Outer, Bottom, Shoes, **Dress**, Special · กลุ่ม 3 Admin คือ …Neck, **Belt, Bag**… แต่ Figma client คือ …Neck, **Bag, Belt**… · sticky `7732:68087` มี **"Dress/Outfit"** เพิ่มอีกหมวด (รวม 20) แต่ไม่มีปุ่มใน column (Q-D3)

### 5.7 Items panel + Item card

| ส่วน | ค่า |
|---|---|
| Items (`7615:205641`) | flex-col · w 491 · h 950 · padding 16 · gap 16 · items-end |
| หัว | ชื่อหมวด H/Bold white · text-shadow `0 2 4 rgba(0,0,0,0.5)` · แถว justify-between เต็มกว้าง |
| Grid (`7695:57292`) | flex-wrap · gap 16 · justify-center · content-start · 3 card ต่อแถว (459 กว้าง) · เลื่อนได้ (frame มี 18 card สูง 920) |
| Card (`Outfit item` `7537:112291`) | 140 × 140 (master 146 × 140) · bg Shade Black/50% · backdrop-blur 6 · radius 16 · pt 4 · px 4 · pb 8 · gap 8 · overflow-clip |
| กล่องรูป | flex-1 (≈107) · bg white 10% · radius 12 · ลาย `Layer_1` opacity 20% เป็นพื้น · รูปชิ้นกลาง (top/bottom 17.5%, aspect ตามรูป) |
| Tag "Used" (`7615:204454`) | absolute top 4 · right 4 · 38 × 19 · bg Primary/10% · border 1 Primary/10% · radius 4 · px 4 · py 2 · Caption 1 `#58D68D` — แสดงบน card ที่สวมอยู่ |
| แถวสี (`7610:198617`) | gap 4 · จุด 10 × 10 สูงสุด 5 จุด + "+N" Caption 2 white (เช่น "+7") |
| Hover | tooltip ชื่อ item เหนือ card (เช่น "Fair") |

**Skin tone card (หมวด Skin tone, `7615:207397`):** 5 card · รูป = ตัวละครชุดขาวผิวเฉดนั้น · จุดสีเดียว 10 px fill ตามเฉด + stroke white

| ลำดับ | ชื่อ (tooltip) | hex จุดสี (จาก SVG) | node card |
|---|---|---|---|
| 1 | Fair (มี tag Used ใน frame นี้) | `#F6D5B3` | `I7615:208297;7695:57293` |
| 2 | Light Beige | `#E0B491` | `I7615:208297;7695:57294` |
| 3 | Tan | `#C58F69` | `I7615:208297;7695:57295` |
| 4 | Brown | `#9C694E` | `I7615:208297;7695:57296` |
| 5 | Dark Brown | `#684B3D` | `I7615:208297;7695:57297` |

> ค่าสีนี้เป็นข้อมูลให้ตัดสิน **Q-4c** ของ spec (5 เฉดคือชุดไหน, เฉดไหนเป็น Default) — ยังไม่ใช่มติ · ความกว้าง stroke ของจุดยังไม่ได้อ่าน

### 5.8 แถบสี — Shade + Palette (`7709:202855`, `7615:207339`)

| ส่วน | ค่า |
|---|---|
| แถบ Shade ("Colour Saturation") | 394 × 42 · bg Shade Black/50% · border 1 white 20% · radius 90 · padding 8 · ข้างในกว้าง 376 gap 10: icon pipette (`Color-Picker`) 24 + แถบ 342 × 12 + handle วงกลม 8 × 8 |
| แถบ Palette ("Colour") | สูง 42 · bg Shade Black/50% · border 1 white 20% · radius 90 · padding 8 · gap 8 · swatch (`Colour wheel`) 24 × 24 สูงสุด 12 อัน (ใน `7698:78496` เปิด 5 ซ่อน 7) · กว้างตามจำนวน |
| เมื่อไหร่แสดง | หลังคลิก item card / ช่องใน panel (sticky `7648:336818`) · ซ่อนเมื่อยังไม่ได้เลือก (frame `7698:140811` ไม่มีแถบ) |
| Special costume | ไม่มีแถบ Shade (sticky `7732:67658`) |
| Skin tone | ไม่มีแถบสี (เลือกจาก card ตรง ๆ) — ตาม `7615:207397` |

### 5.9 Tooltip (`7615:207399`)

bg `#1A1B1E` · padding 8 · radius 8 · drop-shadow `0 4 8 rgba(255,255,255,0.08)` · Caption 1 white nowrap · หางสามเหลี่ยม (polygon 20 หมุน 60°) กลางขอบล่าง ล้นลง ~12 px · วางเหนือเป้าหมาย

### 5.10 Toast (`7698:187921`, `7698:195099`, `7698:199166`)

w 336 · มุมขวาบน inset 16 · bg `#1A1B1E` · radius 16 · padding 16 · drop-shadow `0 4 8 rgba(255,255,255,0.08)` · แถว gap 16 · กล่อง icon w 40 · padding 8 · radius 8 · icon 24 · Text container gap 8 · Body/Bold (title) + Body/Regular (ข้อความ) white 14/18 · ปุ่ม Cancel (x) 16

| แบบ | node | กล่อง icon | icon | Title | ข้อความ |
|---|---|---|---|---|---|
| EP-01 บันทึกไม่ได้ | `7698:187921` | `rgba(255,212,0,0.1)` | Warning-triangle (Yellow/500 `#ECC819`) | "Unable to update avatar" | "Check your connection and try again." |
| EC-02 ชิ้นไม่พร้อมใช้ | `7698:195099` | `rgba(45,182,255,0.1)` | Info (Blue/500) | "Item no longer available" | "This item is no longer available. Please choose another item." |
| EC-02 ชิ้นถูกลบ | `7698:199166` | `rgba(45,182,255,0.1)` | Info (Blue/500) | "Item removed" | "Your avatar has been updated with the default item." |

---

## 6. ข้อความใน Figma (ตามต้นฉบับ)

| ที่ | ข้อความ (EN — ตาม Figma) | คำแปลเสนอ (TH — Figma ไม่มี) |
|---|---|---|
| ปุ่ม lobby / เมนู VO | Customise avatar | แต่งตัวอวาตาร์ |
| หัวหน้า | Customise avatar | แต่งตัวอวาตาร์ |
| ใต้หัว | {ชื่อ workspace} เช่น "Starlight world" | — |
| Slot | SLOT 1 … SLOT 5 | — (Q-D9) |
| หัว panel | Costume · Accessory | เครื่องแต่งกาย · เครื่องประดับ |
| หัวหมวด / tooltip หมวด | Skin tone · Hair · Eye · Face · Facial hair · Top · Outer · Bottom · Shoes · Dress · Special Costume · Hat · Glasses · Mask · Neck · Bag · Belt · Back · Companion | ใช้ชุดเดียวกับ namespace `AdminAccessoryManagement` ได้ถ้าตรงกัน (Q-D3) |
| ชื่อเฉดผิว | Fair · Light Beige · Tan · Brown · Dark Brown | — |
| tag card | Used | ใช้อยู่ |
| tooltip ปุ่ม | Undo · Redo · Clear | ย้อนกลับ · ทำซ้ำ · ล้าง |
| toast | ดู §5.10 | — |
| lobby | Welcome to {workspace} · Character name · Join space | (มีใน i18n เดิมแล้ว) |
| เมนู VO | Edit profile · Customise avatar · Back to workspace | (มีเดิม ยกเว้น Customise avatar) |

---

## 7. Interaction / behaviour ต่อ scenario (Figma + sticky → AC)

| Scenario | การกระทำ | ผลตาม Figma | AC |
|---|---|---|---|
| HP-01 | กด "Customise avatar" ใน lobby หรือเมนูโปรไฟล์ VO | เปิดหน้าเต็ม Dressing room · หัว "Customise avatar" + ชื่อ workspace · หมวดแรก = Skin tone (active) · Slot 1 เลือกอยู่ | AC-HP01-1, -5 |
| HP-01 | เปิดครั้งแรก / workspace ใหม่ | ตัวละคร Default ชุดขาว สีผิว Default (`7691:55511`) | AC-HP06-4 |
| HP-01 | กดปุ่มย้อนกลับ (chevron ใน Headbar) | กลับหน้าที่มา (lobby / VO) — ไม่มี X / ESC / คลิกนอก (หน้าเต็ม) | AC-HP01-6 ⚠ |
| ทุกหมวด | hover ปุ่มหมวด / card / ช่อง panel | tooltip ชื่อ (`7648:336822`, `7648:336818`) | — |
| HP-02 | คลิกการ์ดเฉดผิว | ตัวละครเปลี่ยนเฉด · ช่อง Skin tone ใน Costume panel แสดงค่าใหม่ + ไฮไลท์ฟ้า · card ที่ใส่อยู่มี tag "Used" | AC-HP02-2, -3, -4, -5 |
| HP-02 | ถอด skin | ทำไม่ได้ — เปลี่ยนเท่านั้น · Clear ที่ skin = กลับ Default (`7695:74142`) | — |
| HP-03 | คลิก item card หมวดอื่น | ระหว่างรอ: spinner บนตัวละคร (`7698:140811`) → ใส่แล้ว · ช่องของหมวดใน Costume/Accessory panel แสดงรูปชิ้น + ไฮไลท์ฟ้า · แถบ Shade + Palette โผล่ใต้เวที | AC-HP03-4, -5 |
| HP-03 | เลือก swatch / เลื่อน Shade | ชิ้นเปลี่ยนสี / ความเข้มตาม (`7709:204981`, `7698:79543`) · Special costume ไม่มี Shade | — (ไม่มีใน ClickUp) |
| HP-03 | สลับหมวด | ของที่ใส่หมวดอื่นยังอยู่ (เห็นใน panel) | AC-HP03-8 |
| HP-04 | double-click ช่องใน Costume / Accessory panel | ถอดชิ้นนั้น (`7695:78447`, `7698:80536`) | AC-HP04-2 (แทน "None") |
| HP-04 | กด Clear (ถังขยะ) | ลบเฉพาะ item · Skin tone กลับ Default · ลบเฉพาะ Slot ที่อยู่ (`7648:358156`) | AC-HP04-5, -6 ⚠ |
| HP-04 | Undo / Redo | ย้อน/ทำซ้ำการแต่ง (ไม่มี sticky อธิบาย — Q-D5) | — |
| Slot | คลิก SLOT n | สลับไปชุด preset n · ออกจากหน้าแล้ว workspace ใช้ชุดของ Slot ที่เลือกอยู่ (`7726:222732`) | — (ไม่มีใน ClickUp) |
| HP-05 | เปลี่ยนชุด | **บันทึกอัตโนมัติทุกครั้งที่เปลี่ยน** · ไม่มีปุ่มบันทึก/ยกเลิก · กดย้อนกลับได้เลย (`7698:143821`) | AC-HP05-1~3 ⚠ |
| HP-05 | ย้อนกลับ | lobby แสดงตัวละครชุดใหม่ (`7698:145174`) → VO แสดงชุดใหม่ (`7698:145740`) | AC-HP05-2, -4 |
| HP-06 | แต่งใน Workspace A แล้ว B | ใต้หัวแสดงชื่อ workspace ของตัวเอง · ชุดแยกกัน | AC-HP06-2, -3 |
| EP-01 | เลือกชุดแล้วเน็ตล่ม | spinner ค้าง → spinner หาย **กลับเป็นชุดเดิม** + toast "Unable to update avatar" (`7698:187581`) | AC-EP01-1 ⚠, -4 ✓, ขัด -2 / -3 · ไม่มี -5 |
| EC-02 | ชิ้นที่ใส่อยู่ (ตัวอย่างคือ skin Tan) ถูกซ่อน | ใน workspace ยังเห็น Tan · เข้าหน้าแต่งตัว: card Tan หาย · ช่องใน panel เป็น State=Error (แดง) · toast "Item no longer available" ให้เปลี่ยน (`7698:194984`) | AC-EC02-1, -2, -3 ⚠ (ขัดมติ C-13) |
| EC-02 | ชิ้นถูกลบ | skin กลับค่าตั้งต้น + toast "Item removed" (`7698:200256`) | AC-EC02-6 |
| EC-03 | 2 tab แต่ง · tab 2 save ทีหลัง | VO แสดงชุดล่าสุด (`7709:215560`) | AC-EC03-1~3, -6 · ไม่เห็น -4 (refresh panel tab อื่น) |

---

## 8. ขัดกับ ClickUp / spec — **ต้องตัดสิน (ไม่ได้เลือกเอง)**

| # | เรื่อง | Figma | ClickUp / spec.md | กระทบ |
|---|---|---|---|---|
| CF-1 | วิธีบันทึก | **Auto-save ทุกการเปลี่ยน** · ไม่มีปุ่มบันทึก/ยกเลิก · ไม่มี confirm (`7698:143821`) | HP-05 ปุ่ม "บันทึก"/"ยกเลิก" · AC-HP05-5/-6 confirm "ยังไม่บันทึก ต้องการออกไหม?" · AC-HP04 ขั้น 5 กดบันทึก · spec §9.5 | API (PUT + **bake ทุกครั้งที่เปลี่ยน**), realtime, Undo/Redo, EP-01 |
| CF-2 | Network error | spinner หาย **กลับเป็นชุดเดิม** + toast | AC-EP01-2 panel เปิด selection **ไม่หาย** · AC-EP01-3 ปุ่มบันทึก active · AC-EP01-5 auto-retry 1 ครั้งหลัง 3 s | state ฝั่ง client, retry |
| CF-3 | ข้อความ toast EP-01 | "Unable to update avatar" / "Check your connection and try again." (EN, มี title) | AC-EP01-1 "บันทึกไม่สำเร็จ กรุณาลองใหม่" | i18n |
| CF-4 | Entry point | ปุ่มใน lobby + เมนูโปรไฟล์ VO | AC-HP01-1 avatar icon บน sidebar / VO HUD / Workspace Settings → Avatar | entry (spec Q-7) |
| CF-5 | รูปแบบหน้า | **หน้าเต็ม** 1440 × 1024 ปิดด้วยปุ่มย้อนกลับ | modal / side panel · AC-HP01-6 ปิดด้วย X / ESC / คลิกนอก | layout, route (spec C-18 / Q-7) |
| CF-6 | label workspace | หัว "Customise avatar" + ชื่อ workspace บรรทัดล่าง | AC-HP01-5 / AC-HP06-2 "แต่งตัว Avatar สำหรับ [ชื่อ Workspace]" | ถ้อยคำ |
| CF-7 | Slot preset 5 ชุด | มี SLOT 1–5 · ชุดที่ใช้ = Slot ที่เลือกตอนออก (`7726:222732`) | ไม่มีใน ClickUp / data model (spec Q-8) · มติ C-14 เก็บ 1 ชุดต่อ (user, workspace) | **schema** (ชุดต่อ slot?), API, Clear |
| CF-8 | วิธีถอด | double-click ช่องใน panel · ไม่มีการ์ด "None" | AC-HP03-3 / AC-HP04-1 / AC-HP04-4 "None" ตัวแรกทุกหมวด + highlight | UI, accessibility (ไม่มีทางถอดด้วยคีย์บอร์ด/มือถือ) |
| CF-9 | Clear all | ถังขยะ: ลบ item ทั้งหมดของ Slot นี้ · skin กลับ Default | AC-HP04-6 "ถอดทั้งหมด" optional (Q-9) · spec มี "ชุดเริ่มต้น" (reset เป็นชุด default) · sticky `7691:55511` default = **ชุดขาว** | ผลลัพธ์หลัง Clear = ตัวเปล่าหรือชุดขาว? slot บังคับ (TD) ถอดได้ไหม |
| CF-10 | Undo / Redo | มีปุ่ม | ไม่มีใน ClickUp | scope + ถ้า auto-save แต่ละ undo = save อีกครั้ง |
| CF-11 | หมวด | 19 ปุ่ม (Skin tone + 18) · sticky มี 20 (มี "Dress/Outfit") · ลำดับต่างจาก Admin constants (Dress, Bag/Belt) | ClickUp 5 tab (AC-HP03-1) · มติ Q-5 = 18 หมวด ✓ | ลำดับ + หมวดที่ 20 |
| CF-12 | dot บน tab | ไม่มี — ใช้ Costume/Accessory panel บอกว่าใส่อะไร | AC-HP03-2 / AC-HP04-3 dot indicator บน tab | UI |
| CF-13 | Skin ถูก admin ซ่อน | EC-02 ทั้ง section ใช้ตัวอย่าง **skin Tan ถูกซ่อน** (card หาย + Error + toast) | มติ C-13 / Q-4b: skin = 5 เฉดของระบบ ซ่อนไม่ได้ → AC-EC02-1~4 ไม่มีผล | ถ้าใช้ flow นี้ต้องย้ายไปเป็นตัวอย่าง "ชิ้นอื่นถูกซ่อน" |
| CF-14 | ชิ้นที่ถูกซ่อน (ไม่ใช่ skin) | toast "Please choose another item" + State=Error — สื่อว่าต้องเปลี่ยน | Admin TD §8.1: ชิ้น hidden ที่ใส่อยู่ save ผ่าน **ไม่บังคับเปลี่ยน** · AC-EC02-4 บังคับเฉพาะ skin | UX + validate API |
| CF-15 | badge "ปัจจุบัน" | tag "Used" (เขียว) | AC-HP02-5 badge "ปัจจุบัน" · AC-HP02-4 / AC-HP01-4 selected = border ฟ้า | card ใน Figma ไม่มี border ฟ้า — ฟ้าอยู่ที่ช่องใน panel |
| CF-16 | Preview | ภาพนิ่งหันหน้า · ไม่มีปุ่มหมุน / tab Idle-Walking-Sitting | AC-HP01-2 / AC-HP02-3 animated `idle_s` | renderer |
| CF-17 | สีของชิ้น | Palette ต่อชิ้น + แถบ Shade · Special costume ไม่มี Shade | ClickUp ไม่มีเรื่องสี (data contract มี palette) | scope + ตรงกับ POC admin แถบ Shade (admin U1) |
| CF-18 | Loading ระหว่างแต่ง | spinner บนตัวละครทุกครั้งที่สวม (เน็ตช้า) — แปลว่ามี network call ต่อการเปลี่ยน | ClickUp preview "ทันที ไม่ต้อง confirm" (AC-HP02-2, AC-HP03-4) · spec §9.5 preview ฝั่ง client, bake ตอน save | performance / ต้นทุน bake |
| CF-19 | Mobile | iPhone frames บน canvas (อันที่ดูเป็นภาพ promo) | ClickUp ติ๊ก Desktop อย่างเดียว (spec Q-12) | scope |
| CF-20 | EC-03 refresh tab อื่น | ไม่มีหน้าจอ tab ที่เปิดค้างได้ event · แถว "Tap 2" ขึ้น "Welcome to Home Sweet Home" (อาจเป็นอีก workspace — copy จาก HP-06) | AC-EC03-4 tab อื่นรับ WS แล้ว refresh panel · EC-03 = workspace เดียวกัน | realtime (spec C-16) |
| CF-21 | icon spinner | layer `fa-solid:spinner` (Font Awesome) | rule 12 ใช้ lucide-react เท่านั้น | ใช้ lucide แทน (ต้องให้ designer รับทราบ) |

---

## 9. Reuse และการปฏิบัติตาม rules

| เรื่อง | ของเดิมที่ใช้ได้ | หมายเหตุ |
|---|---|---|
| Toast | `zyraToast` ใน `zyra-app/lib/toast.tsx` — กล่อง w 336 / bg `#1A1B1E` / radius 16 / padding 16 / drop-shadow ตรง Figma | EP-01 = `cautionWithTitle` (กล่อง `rgba(255,212,0,0.1)` + `#ECC819` + TriangleAlert **ตรงเป๊ะ**) · EC-02 = `infoWithTitle` แต่ variant info ใช้กล่อง alpha **0.2** ส่วน Figma 0.1 → ส่ง `options.boxAlpha: 0.1` (มี option อยู่แล้ว) ไม่ต้องสร้าง toast ใหม่ |
| icon หมวด | `AccessoryCategoryIcon` ใน `components/ui/icon.tsx` (อยู่บน `origin/develop`, branch ปัจจุบันของ zyra-app คือ `fix/ipad-full-width-lobby`) — 18 หมวด, viewBox 16, `currentColor` | ชื่อ layer icon ตรงกับฝั่ง Admin (`hair 1`, `jecket 1`, `santa 1` …) → น่าจะเป็น SVG ชุดเดียวกัน (ยังไม่ได้เทียบ path) · ต้องเพิ่ม `skin tone 1` (จานสี) ตามข้อยกเว้น custom asset ของ rule 12 |
| หมวด + layer + สี | `lib/avatar-part/constants.ts`, `render.ts`, `shade.ts`, `color-name.ts` (develop) | ห้ามเขียน renderer ซ้ำ (spec §9.5) · `shade.ts` ใช้กับแถบ Shade ได้ · ลำดับแสดงผลของ client ต่างจาก `ACCESSORY_CATEGORIES` (§5.6) — ต้องตัดสินว่าใช้ลำดับไหน (Q-D3) |
| ชีท base | `public/avatar/base/walk.png`, `sit.png` (develop) | ตัวละคร default บนเวที |
| Entry | `views/user/virtual-office/components/vo-profile-panel.tsx` (`onChangeAvatar`, `changeAvatar`) · `views/user/workspace-enter/hero-workspace-enter.tsx` + `components/change-character-modal.tsx` (ระบบเลือก character เดิม) | เปลี่ยน label + ปลายทาง · ระบบเดิมคงไว้จนระบบใหม่ขึ้น prod (spec §9.5) |
| Tooltip | `components/ui/tooltip.tsx` เป็น shadcn (`bg-foreground`, `rounded-md`, `text-xs`) | **rule 08 ห้ามใช้ shadcn ใน zyra-app** และค่าไม่ตรง Figma → ทำ tooltip Tailwind ตาม §5.9 (หรือ extract ของที่มีใน feature อื่นถ้ามี — ตาม rule 09 ต้องค้นก่อน) |
| ปุ่ม / panel | — | rule 08: raw HTML + Tailwind arbitrary values ตาม §5 (rule 10) |
| icon ทั่วไป (rule 12) | lucide-react | chevron-left / up / down → `ChevronLeft/Up/Down` · Undo / Redo / Trash → ตัวที่ path ตรง (ยังไม่ได้เทียบ) · Warning-triangle → `TriangleAlert` · Info → `Info` · Cancel → `X` · Color-Picker → `Pipette` · spinner → lucide (`LoaderCircle`/`Loader`) แทน Font Awesome (CF-21) |
| Asset raster | ฉาก Dressing room, `base_platform`, `wardrobe 1`, `slote`, ลาย `Layer_1` | ต้อง export จาก Figma ลง `public/` (N-9) — ห้ามใช้ URL ชั่วคราวของ MCP |
| ฟอนต์ | Bagel Fat One (label Slot) | ไม่มีใน zyra-app — ต้องเพิ่มผ่าน `next/font` หรือเปลี่ยนเป็นรูป (Q-D9) |
| Tokens ร่วมกับ Admin | `#1A1B1E`, `#242B32`, `#58D68D`, Primary/10%, `#8C99A6`, `#2DB6FF`, `#F03A3A`, White 5/10/20%, Caption 1, Body | เพิ่มเฉพาะฝั่ง client: Shade Black/50%, `#232427`, Solid Black/70%, Red/50%, Blue/10%, Yellow/10% |

---

## 10. คำถามถึง Designer

| # | คำถาม |
|---|---|
| Q-D1 | (CF-1/CF-2) ยืนยัน auto-save ทุกการเปลี่ยนใช่ไหม — ถ้าใช่ EP-01 ตอน error ให้ revert เฉพาะชิ้นที่เพิ่งเปลี่ยน หรือกลับเป็นชุดล่าสุดที่บันทึกสำเร็จ? |
| Q-D2 | (CF-7) Slot 1–5 เก็บต่อ workspace ใช่ไหม · Slot ว่างเริ่มเป็นชุด default ขาว? · ชื่อ Slot แก้ได้ไหม? |
| Q-D3 | (CF-11) หมวด "Dress/Outfit" ใน sticky คืออะไร (ไม่มีปุ่มใน column) · ลำดับหมวด client ต่างจากหน้า Admin (Dress, Bag/Belt) — ใช้ลำดับไหน · ชื่อหมวดภาษาไทย |
| Q-D4 | (CF-8) นอกจาก double-click มีวิธีถอดอื่นไหม (เช่น คลิก card ที่ใส่อยู่ซ้ำ / ปุ่ม x ในช่อง panel) |
| Q-D5 | (CF-10) Undo / Redo เก็บประวัติกี่ขั้น · ข้าม Slot ได้ไหม · disabled state ของปุ่มเมื่อไม่มีประวัติ |
| Q-D6 | (CF-9) หลัง Clear ตัวละครใส่ชุดขาว default หรือไม่ใส่อะไร · หมวดที่บังคับ (เช่น ตา) ถูกล้างไหม |
| Q-D7 | สถานะที่ยังไม่มีใน Figma: hover/pressed ของปุ่มหมวด, card, ช่อง panel, Slot · swatch ที่เลือก · หมวดที่ไม่มี item (empty state) · โหลด catalog ครั้งแรก |
| Q-D8 | (CF-13/14) EC-02 ควรใช้ตัวอย่างชิ้นอื่นแทน skin (skin เป็นของระบบ ซ่อนไม่ได้) · ชิ้นที่ถูกซ่อนบังคับเปลี่ยนจริงไหม (Admin TD บอกไม่บังคับ) |
| Q-D9 | ฟอนต์ Bagel Fat One สำหรับ "SLOT n" — ใช้ฟอนต์นี้จริงหรือทำเป็นรูป · มีข้อความไทยไหม |
| Q-D10 | `7698:193963` ช่อง Top ใน Costume panel แสดง icon จานสี — ตั้งใจหรือ override ผิด |
| Q-D11 | ขนาดตัวละครบนเวที (Figma 400 × 600 ภาพนิ่ง) — ใช้สเกลกี่เท่าของเฟรม 48 px · ต้องมี animation / หมุนทิศไหม (CF-16) |
| Q-D12 | ปุ่ม 80 × 80 สองอันที่ x 1714 (`7508:194764`, `7508:194766`) อยู่นอกเฟรม — ลบได้ไหม |
| Q-D13 | Skin tone 5 เฉด (§5.7) — เฉดไหนเป็น Default (Fair มี tag Used ใน `7615:207397`) · hex ชุดนี้ใช้เป็นค่าสุดท้ายได้ไหม (spec Q-4c) |
| Q-D14 | (CF-5) ความกว้างจอต่ำกว่า 1440 / iPad — layout absolute นี้ปรับอย่างไร · iPhone frames บน canvas เกี่ยวกับ feature นี้ไหม (CF-19) |
| Q-D15 | (CF-20) EC-03: แถว "Tap 2" เป็น workspace เดียวกันหรือ "Home Sweet Home" · tab ที่เปิดค้างควรเห็นอะไรเมื่ออีก tab บันทึก |
| Q-D16 | ข้อความไทยของ toast / tooltip / ปุ่ม ทั้งหมด (Figma มีแต่ EN) |

---

## Changelog

| วันที่ | เปลี่ยนอะไร |
|---|---|
| 2026-10-22 | สร้างเอกสาร: ดึงค่าจาก Figma `pQlFqPDRdEsTAVnfOrcO5h` canvas `7454:438285` — Dressing room symbol, component Outfit item / Item slot / Category Dress room / Costume, toast 3 แบบ, tooltip, แถบสี, lobby, panel โปรไฟล์ VO · ค่าสี 5 เฉดผิว · รายการขัดกับ ClickUp/spec 21 ข้อ · คำถาม designer 16 ข้อ |
