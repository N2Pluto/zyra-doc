# SC-ENV-01 — เสียงบรรยากาศ (R2 layout + วิธีเพิ่มคลิป)

> อัปโหลดครั้งแรก 2026-09-10 · **re-encode + normalize 2026-09-10** (47.2 MB → 9.4 MB) · กระทบ `zyra-app` (`lib/environment-sound.ts`, `lib/environment-sound-player.ts`, `views/user/virtual-office/use-environment-sound.ts`) · ไฟล์ต้นทางจาก `storage/[Feature] · Environment .../Environment/`
> คู่มือของเสียงสัตว์เลี้ยงอยู่ที่ [pet-sounds.md](pet-sounds.md) — ใช้กลไกเดียวกันแต่ **player คนละตัว** เหตุผลอยู่ท้ายหน้า

## โครงบน R2 (bucket `zgather-dev`)

```
static/env/sound/
  ambient/<name>.mp3    ← bed: วนลูปตลอดเท่าที่สภาพอากาศ/ช่วงเวลานั้นยังอยู่
  oneshot/<name>.mp3    ← ช็อตเดียว: ไก่ขันตอนเช้า, ฟ้าผ่า, ลมกระโชก
```

อัปด้วย `Content-Type: audio/mpeg` · `Cache-Control: public, max-age=86400` (แทนไฟล์ชื่อเดิมได้ กระจายภายใน 1 วัน)
public base: `https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/env/sound`

### ที่มีตอนนี้ 16 ไฟล์ · **9.4 MB** (จากต้นฉบับ 47.2 MB)

ทุกไฟล์ **96 kbps joint-stereo · 44.1 kHz · −23 LUFS (EBU R128)**

| key | ไฟล์ | ยาว | ใช้เมื่อ |
|---|---|---|---|
| `rain` | `ambient/rain.mp3` | 90s | `rain` · `drizzle` (เบาลง 55%) |
| `rain-thunder` | `ambient/rain-thunder.mp3` | 48s | `thunderstorm` |
| `rain-thunder-light` | `ambient/rain-thunder-light.mp3` | 20s | *(สำรอง ยังไม่ถูกเรียก)* |
| `wind-strong` | `ambient/wind-strong.mp3` | 82s | `windy` |
| `wind` | `ambient/wind.mp3` | 14s | *(สำรอง)* |
| `winter-wind` | `ambient/winter-wind.mp3` | 19s | `snow` |
| `morning-birds` | `ambient/morning-birds.mp3` | 90s | `dawn` · `morning` · `afternoon` ที่ไม่ร้อน |
| `morning-farmyard` | `ambient/morning-farmyard.mp3` | 90s | *(สำรอง)* |
| `night` | `ambient/night.mp3` | 90s | `evening` |
| `night-crickets` | `ambient/night-crickets.mp3` | 90s | `night` |
| `hot-day-cicadas` | `ambient/hot-day-cicadas.mp3` | 90s | `afternoon` ที่อุณหภูมิ ≥ 30 °C |
| `hot-day` | `ambient/hot-day.mp3` | 82s | *(สำรอง)* |
| `rooster` | `oneshot/rooster.mp3` | 2.8s | ครั้งเดียวตอน stage เปลี่ยนเข้า `morning` |
| `thunder-1` / `thunder-2` | `oneshot/thunder-*.mp3` | 4.5s / 2.9s | ทุก 10 วินาทีระหว่างพายุ |
| `snow-gust` | `oneshot/snow-gust.mp3` | 5s | ทุก 26 วินาทีระหว่างหิมะตก |

**สภาพอากาศชนะช่วงเวลา** — ยืนอยู่ในพายุต้องได้ยินพายุ ไม่ใช่เสียงนกยามเช้า · condition ที่ไม่มีเสียงของตัวเอง (`fog` `cloudy` `clear` `partly_cloudy`) ตกลงไปใช้เสียงตามช่วงเวลา ไม่ใช่เงียบ

**ปิดตาม toggle ที่คุมภาพตัวเดียวกัน** — ปิด weather effect แล้วเสียงฝนหายไปด้วย · ปิด time of day แล้วเสียงนก/จิ้งหรีดหายไปด้วย · คนที่ปิดภาพฝนแล้วยังได้ยินฝนจะเรียกว่าบั๊กอย่างถูกต้อง

## เพิ่มคลิปใหม่ (2 ขั้น)

1. **อัปไฟล์** — จากโฟลเดอร์ `zyra-api/` (ให้ `. ./.env` อ่านคีย์ได้):

   ```bash
   set -a && . ./.env && set +a
   export AWS_ACCESS_KEY_ID="$AWS_BUCKET_ACCESSKEY" AWS_SECRET_ACCESS_KEY="$AWS_BUCKET_SERETKEY" AWS_DEFAULT_REGION=auto
   aws s3 cp <ไฟล์> "s3://$AWS_BUCKET_NAME/static/env/sound/ambient/<name>.mp3" \
     --endpoint-url "$AWS_BUCKET_ENDPOINT" \
     --content-type "audio/mpeg" --cache-control "public, max-age=86400"
   ```

2. **เพิ่มบรรทัดใน `ENV_BEDS` / `ENV_ONESHOTS`** (`zyra-app/lib/environment-sound.ts`) พร้อม `seconds` และ `volume` · ถ้าจะให้ถูกเรียกอัตโนมัติ ต้องแก้ `environmentBedFor()` ด้วย

## การเตรียมไฟล์ (`scratchpad/sound/encode.py`)

```bash
ffmpeg -nostdin -i <src> -t 90 \
  -af loudnorm=I=-23:LRA=7:TP=-2:linear=true:measured_I=…:measured_LRA=…:measured_TP=…:measured_thresh=…:offset=… \
  -c:a libmp3lame -b:a 96k -ar 44100 -ac 2 -map_metadata -1 <dst>
```

สามอย่างที่ทำ และเหตุผลของแต่ละอย่าง:

| ขั้น | ทำไม |
|---|---|
| **`-t 90`** | bed วนลูป ยาวกว่านาทีครึ่งจึงไม่ได้อะไรนอกจากกิน bandwidth · `Rain.mp3` มาเป็น **10 นาที / 19.2 MB** ที่ทุกคนใน workspace ฝนตกต้องโหลด |
| **`loudnorm` 2 pass** | ระดับเสียงต้นฉบับ**กระจายถึง 28 LU** (−13.8 ถึง −41.8 LUFS) ⇒ ถ้าไม่ทำ สลับ bed ทีนึงเสียงจะกระโดดเป็นสิบ ๆ dB · pass เดียวยังพลาดในไฟล์ที่ระดับเสียงแกว่งมาก (คลาด 5 LU) จึงต้องวัดแล้วป้อนค่ากลับ · **หลังทำเหลือกระจาย 1.0 LU** |
| **96k joint-stereo** | **ไม่ยุบเป็น mono** ต้นฉบับ stereo ทุกไฟล์ และ bed ฝนที่เป็น mono จะยุบเป็นเสียงจากจุดเดียว ซึ่งเป็นสิ่งเดียวที่เสียงบรรยากาศต้องไม่เป็น · 96k ให้ผลประหยัดตามที่ต้องการอยู่แล้ว |

**ผล: 47.2 MB → 9.4 MB (20%)** · ไฟล์ใหญ่สุด 19.2 → 1.03 MB

เพราะทุกไฟล์อยู่ที่ −23 LUFS เท่ากันแล้ว ค่า volume ต่อ bed จึงไม่ต้องไล่ปรับมือ — เหลือค่าเดียว `ENV_BED_VOLUME` กับข้อยกเว้นเดียว (drizzle ยืม bed ฝนมาเบา ๆ)

> **ความยาวเอาจาก `ffprobe` เท่านั้น** — ตอนแรกผมนับจาก MPEG frame header เอง แล้วได้ค่าผิดไปราวครึ่งใน 4 ไฟล์
- **โหลดผ่าน `/api/img?url=…` เท่านั้น** — R2 ไม่ส่ง CORS header `decodeAudioData` จึงต้องผ่าน proxy (เหมือนเสียง pet)
- **ห้ามใช้ `<audio>`** — Firefox/Zen ขึ้นแถวค้างใน media panel หนึ่งแถวต่อคลิป ([issue](../issues/pet-sound-media-panel-rows-2026-09-08.md))

## ทำไม player คนละตัวกับ pet

`lib/pet-sound-player.ts` ออกแบบมาสำหรับ **เสียงตอบสนอง** — หยุดตัวที่เล่นอยู่ ตัดที่ 2.5 วินาที แล้ว fade · bed ต่างกัน 3 ข้อ และแต่ละข้อต้องมีกลไกของตัวเอง:

| | pet | environment bed |
|---|---|---|
| ความยาว | ตัดที่ 2.5 วิ | วนลูปไม่จำกัด |
| ทับกันได้ไหม | ไม่ — เสียงใหม่หยุดเสียงเก่า | ได้ — ฟ้าผ่าดังทับเสียงฝน ไม่ใช่แทน |
| autoplay | ทุกจุดเรียกเกิดจากการคลิก จึงผ่าน policy อยู่แล้ว | ฝนตกอยู่ก่อนที่ใครจะคลิกอะไร ⇒ **จำ bed ที่อยากเล่นไว้ แล้วเริ่มตอน gesture แรก** |

การวนลูป: bed ถูกตัดที่ 90 วินาที ปลายเพลงจึงไม่ต่อกับต้นเพลง ⇒ ใช้ **source 2 ตัวสลับกันพร้อม gain ramp ที่ตั้งบนนาฬิกาของ audio engine** ให้ crossfade คร่อมรอยต่อ · ถ้าใช้ `loop = true` เฉย ๆ จะได้ยินสะดุดทุก 90 วินาที · ตั้งคิวล่วงหน้าด้วย `setInterval` แต่เวลาจริงอ่านจาก `context.currentTime` จึงไม่เพี้ยนเวลา tab ถูก throttle

## ที่ยังไม่ได้ทำ / ต้องตัดสิน

| # | เรื่อง |
|---|---|
| ~~60~~ | ✅ **ทำแล้ว 2026-09-10** — สวิตช์อยู่ที่ **Setting → Notifications → ENVIRONMENT → "Environment sounds"** ตามแบบเดียวกับ `pet_sound` ที่อยู่ใน tab นั้นอยู่แล้ว · field `enable_environment_sounds` ใน `audio_settings` (JSONB **ไม่ต้อง migration** เพราะ Go unmarshal ทับ struct ที่เติม default ไว้ ⇒ คนที่บันทึก settings ไว้ก่อนหน้านี้ได้ค่า on) · สวิตช์เดียวปิดทั้ง bed, ฟ้าผ่า และไก่ขัน · **ระดับเสียงยังอิง "Notification volume"** — slider แยกของเสียงบรรยากาศยังควรทำใน C7 |
| ~~61~~ | ✅ **ยืนยันแล้ว 2026-09-10** — ใช้เกณฑ์ **30 °C** สำหรับสลับเป็นเสียงจักจั่น (`ENV_CICADA_TEMP_C`) |
| **62** | **จังหวะฟ้าผ่าเป็นของชั่วคราว — ยอมรับแล้ว** (ผู้ใช้ 2026-09-10) ยิงทุก 10 วินาทีด้วย timer ของตัวเองไปก่อน · **เมื่อ C3 วาดฟ้าแลบ ต้องย้ายให้แสงเป็นตัวสั่งเสียง** ไม่ใช่ timer สองตัวเดินแยกกันจนหลุดจังหวะ |
| ~~63~~ | ✅ **ยืนยันแล้ว — ไม่อัป `Running`** — footstep ในระบบ**สังเคราะห์เสียงด้วย Web Audio โดยเจตนา** (`views/user/virtual-office/footstep-sound.ts`) เพราะ sample คงที่จะฟังเหมือนปืนกลเวลาเดินเร็ว และไม่ต้องมี asset ให้ license · ถ้าอยากได้เสียงตามพื้น (กรวด/หญ้าเปียก) เป็นงานของฟีเจอร์ footstep ไม่ใช่ SC-ENV-01 |
| **64** | ไม่มี bed ของ `fog` และ `cloudy` — ตกไปใช้เสียงตามช่วงเวลา ซึ่งพอใช้ได้ แต่ถ้าอยากได้บรรยากาศอึมครึมต้องขอไฟล์เพิ่ม |
