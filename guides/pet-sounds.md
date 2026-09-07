# Room Pet — เสียงสัตว์เลี้ยง (R2 layout + วิธีเพิ่ม Category ใหม่)

> อัปโหลดครั้งแรก 2026-09-07 · กระทบ zyra-app (`lib/pet-sound.ts`), zyra-api (`pet_type_category`) · ไฟล์ต้นทางจาก `zyra-new/storage/sound/`

เสียงของสัตว์เลี้ยงผูกกับ **category ของ pet type** ไม่ใช่ตัว type — แมวทุกตัวร้องเหมือนกัน สุนัขทุกตัวเห่าเหมือนกัน
พอ admin สร้าง type ใหม่แล้วเลือก category ที่มีเสียงอยู่แล้ว ก็ได้เสียงทันทีโดยไม่ต้องอัปไฟล์เพิ่ม

## โครงบน R2 (bucket `zgather-dev`)

```
static/pet/sound/
  shared/evolution.mp3              ← เสียงตอนโตข้าม stage (ใช้ร่วมทุก category)
  <category>/baby/01.mp3 … NN.mp3   ← วัยเด็ก
  <category>/adult/01.mp3 … NN.mp3  ← วัยโตเต็มวัย + วัยวิวัฒน์ (โฟลเดอร์ "Adult & Evolve" ของศิลปิน)
```

- `<category>` = ค่าใน `model.PetCategories` ของ zyra-api: `buffalo, bird, cat, chicken, dog, elephant, exotic, fish, reptile, small`
- **ไข่ไม่มีเสียง** — ไม่ต้องมีโฟลเดอร์ `egg`
- ไฟล์เรียงเลขจาก `01` โดย **เรียงจากคลิปสั้นไปยาว** (01 = สั้นที่สุด = ตอบสนองไวที่สุด)
- อัปด้วย `Content-Type: audio/mpeg` และ `Cache-Control: public, max-age=86400` (แทนไฟล์เดิมชื่อเดิมได้ กระจายภายใน 1 วัน)

### ที่มีตอนนี้ (3 category)

| category | baby | adult | ที่มา |
|---|---|---|---|
| `cat` | 6 | 3 | โฟลเดอร์ `Cat/` |
| `dog` | 2 | 2 | โฟลเดอร์ `Dog/` |
| `bird` | 2 | 4 | โฟลเดอร์ `Chicken/` — category `chicken` (เพิ่ม 2026-09-07) อ่านโฟลเดอร์ `bird/` นี้ผ่าน `PET_SOUND_FOLDER` ไม่ต้องอัปซ้ำ |

**category ที่ admin เลือกได้ตอนนี้มีแค่ ไก่ / หมา / แมว** — สามตัวที่มีเสียงแล้ว กำหนดที่ `PET_SELECTABLE_CATEGORIES` (`zyra-app/views/admin/pet-management/pet-options.ts`) ตัวที่เหลือ backend ยังรับอยู่แต่ซ่อนจาก dropdown จนกว่าจะอัปเสียง

## เพิ่ม category ใหม่ (3 ขั้น)

1. **อัปไฟล์** — จากโฟลเดอร์ `zyra-api/` (เพื่อให้ `. ./.env` อ่านคีย์ได้):

   ```bash
   set -a && . ./.env && set +a
   export AWS_ACCESS_KEY_ID="$AWS_BUCKET_ACCESSKEY" AWS_SECRET_ACCESS_KEY="$AWS_BUCKET_SERETKEY" AWS_DEFAULT_REGION=auto
   aws s3 cp --endpoint-url "$AWS_BUCKET_ENDPOINT" --recursive \
     --content-type "audio/mpeg" --cache-control "public, max-age=86400" \
     <โฟลเดอร์ที่จัดชื่อ 01.mp3, 02.mp3 …> "s3://$AWS_BUCKET_NAME/static/pet/sound/<category>/"
   ```

2. **บอกแอปว่ามีกี่ไฟล์** — `zyra-app/lib/pet-sound.ts`:

   ```ts
   export const PET_SOUND_SET = {
     cat: { baby: 6, adult: 3 },
     …
     fish: { baby: 2, adult: 3 },   // ← บรรทัดใหม่
   }
   ```

3. **เปิดให้ admin เลือก** — เพิ่ม id ลง `PET_SELECTABLE_CATEGORIES` ใน `zyra-app/views/admin/pet-management/pet-options.ts` (ถ้า category นั้นยังไม่มีใน `model.PetCategories` ของ zyra-api ต้องเพิ่มพร้อม migration ที่ขยาย CHECK ของ `tb_pet_type.category` ด้วย — ดู `94_pet_category_chicken.sql`)

category ที่ยังไม่มีเสียง = สัตว์เงียบ ไม่พัง ไม่มี error

## เล่นตอนไหน

| จังหวะ | เสียง | ใครได้ยิน |
|---|---|---|
| ลูบหัวสำเร็จ (SC-PET-03) | เสียงตาม category + ช่วงวัยของ pet ตัวนั้น (สุ่มในแพ็ก) | คนที่ลูบเท่านั้น |
| เกิด pop กับ pet | สุ่มจากแพ็กเดียวกัน ครั้งเดียวตอน pop ก่อตัว | คนที่ pop ด้วยเท่านั้น |
| ลำดับการเติบโต (SC-PET-04/05) | `shared/evolution.mp3` ครั้งเดียวตอนเริ่มเล่น | เฉพาะคนที่ XP ทำให้ข้าม (คนอื่นเห็นแค่ modal จึงไม่ได้ยิน) |

- ระดับเสียงคูณกับ **Notification volume** ใน Settings → Audio (ตั้ง 0 = ปิดจริง) — ยังไม่มีสวิตช์แยกของ pet
- เสียงสัตว์ตัดที่ **2.5 วินาที** แล้ว fade (คลิปต้นทางบางไฟล์ยาว 8–15 วิ ซึ่งยาวเกินไปสำหรับการตอบสนองตอนลูบ) ส่วนเสียงเติบโตปล่อยจนจบ
- ทั้งสองจุดเกิดจากการคลิกของผู้ใช้ จึงไม่ติด autoplay policy ของเบราว์เซอร์

## ฟังทั้งหมด

`/dev/preview/room-pat` มีส่วน "เสียงของสัตว์เลี้ยง" กดฟังได้ทุกคลิปทุก category (public ไม่ต้อง login)
