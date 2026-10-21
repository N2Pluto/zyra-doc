# data/ — ไฟล์ส่งให้ทีมหน้าบ้าน (module แต่งตัวละครฝั่ง user)

> **สถานะ:** draft 2026-10-21 · ดึงจาก prototype [Zyra Avatar Studio](https://claude.ai/artifact/5CWTCN9yMtbQ4czt29FVty) · ยังไม่ผ่าน PM/ศิลปิน · **ยังไม่มี API จริงใน zyra-api** · ค่าใน parts/palettes เป็นชุดตัวอย่าง ของจริงมาจาก admin ใส่ผ่านโมดูลนี้

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| [avatar-outfit-data.json](avatar-outfit-data.json) | data contract: layout ชีท, slot 11 ตัว + ลำดับวาด, สี key 5 channel, palette 4 ชุด, ชิ้นส่วนตัวอย่าง 31 ชิ้น, รูป state ของชุด (payload save), ชุด default, จังหวะ animation, ข้อความ UI ภาษาไทย |
| [api-example.md](api-example.md) | API ตัวอย่าง 5 endpoint ใต้ `/api/user/avatar/*` + response/error + TS client (`lib/api/avatar-outfit.ts`) + วิธี mock |
| [frontend-guide.md](frontend-guide.md) | **คู่มือ dev หน้าบ้าน** — กฎที่กระทบ, โครงไฟล์, mock API, data flow, โค้ด palette swap + renderer + reducer, UI checklist, เทส, DoD รอบแรก, ถามใคร |

## อ่านยังไง (ลำดับที่แนะนำ)

1. `sheet` — เฟรม 48×48, 4 แถว (ลง/ซ้าย/ขวา/ขึ้น), walk 4–5 คอลัมน์ (col 1 = ยืน, col 4 = หลับตา), sit 4–5 คอลัมน์ (col 2 = นั่ง, col 3 = ลุก)
2. `slots` + `render_order` — วาดทับกันตามลำดับนี้ · `required` = ห้ามเป็น null · `occupies` = costume ทับ top+bottom
3. `color_channels` + `palettes` — ชิ้นวาดด้วยสี key (magenta/cyan/yellow/red/green) แล้ว swap เป็น palette ที่ user เลือก · scope `global` เก็บที่ `outfit.colors` · scope `slot` เก็บที่ `outfit.slots.<slot>.colors`
4. `outfit_state_shape` — state ที่หน้าบ้านถือ และส่งตอน Save · มี `rules` 7 ข้อที่ต้องทำใน UI
5. `animation` — tick 125ms, เดินวน col 0–3, ยืน col 1 กะพริบ col 4 (100ms ทุก 1.8–4.6s), นั่งไล่ col 0→1→2
6. `ui_text_th` — ข้อความที่ prototype ใช้ เอาไปลง `messages/th.json` ได้เลย

## สิ่งที่หน้าบ้านต้องทำเอง (ไม่อยู่ใน data file)

- render ตัวละครบน canvas: โหลด walk/sit sheet ของทุกชิ้นที่เลือก → ตัดเฟรมตาม (row, col) → แทนสี key ด้วย palette → วาดทับตาม `render_order` · ดูวิธีที่ prototype ทำใน spec §5.6 (ไล่เฉดตามความสว่าง ไม่ใช่ match สี 4 ค่าตรง ๆ)
- หน้า UI: 2 pane (stage ซ้าย / ตู้เสื้อผ้าขวา), tab ต่อ slot, grid item card + "ไม่ใส่", swatch สี, ปุ่ม สุ่ม / ชุดเริ่มต้น / ยกเลิก / บันทึก — **ยังไม่มี Figma** (AvatarCustomization ข้อค้าง 4) ให้ยึด prototype ไปก่อน

## เปลี่ยนแปลง

| วันที่ | อะไร |
|---|---|
| 2026-10-21 | สร้างครั้งแรกจาก prototype |
