# SC-ENV-01 — เสียงบรรยากาศ (R2 layout + วิธีเพิ่มคลิป)

> อัปโหลดครั้งแรก 2026-09-10 · กระทบ `zyra-app` (`lib/environment-sound.ts`, `lib/environment-sound-player.ts`, `views/user/virtual-office/use-environment-sound.ts`) · ไฟล์ต้นทางจาก `storage/[Feature] · Environment .../Environment/`
> คู่มือของเสียงสัตว์เลี้ยงอยู่ที่ [pet-sounds.md](pet-sounds.md) — ใช้กลไกเดียวกันแต่ **player คนละตัว** เหตุผลอยู่ท้ายหน้า

## โครงบน R2 (bucket `zgather-dev`)

```
static/env/sound/
  ambient/<name>.mp3    ← bed: วนลูปตลอดเท่าที่สภาพอากาศ/ช่วงเวลานั้นยังอยู่
  oneshot/<name>.mp3    ← ช็อตเดียว: ไก่ขันตอนเช้า, ฟ้าผ่า, ลมกระโชก
```

อัปด้วย `Content-Type: audio/mpeg` · `Cache-Control: public, max-age=86400` (แทนไฟล์ชื่อเดิมได้ กระจายภายใน 1 วัน)
public base: `https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/env/sound`

### ที่มีตอนนี้ 16 ไฟล์ · 26.3 MB

| key | ไฟล์ | ยาว | ใช้เมื่อ |
|---|---|---|---|
| `rain` | `ambient/rain.mp3` | 90s | `rain` · `drizzle` (เบาลง 55%) |
| `rain-thunder` | `ambient/rain-thunder.mp3` | 48s | `thunderstorm` |
| `rain-thunder-light` | `ambient/rain-thunder-light.mp3` | 20s | *(สำรอง ยังไม่ถูกเรียก)* |
| `wind-strong` | `ambient/wind-strong.mp3` | 82s | `windy` |
| `wind` | `ambient/wind.mp3` | 14s | *(สำรอง)* |
| `winter-wind` | `ambient/winter-wind.mp3` | 19s | `snow` |
| `morning-birds` | `ambient/morning-birds.mp3` | 90s | `dawn` · `morning` · `afternoon` ที่ไม่ร้อน |
| `morning-farmyard` | `ambient/morning-farmyard.mp3` | 45s | *(สำรอง)* |
| `night` | `ambient/night.mp3` | 90s | `evening` |
| `night-crickets` | `ambient/night-crickets.mp3` | 90s | `night` |
| `hot-day-cicadas` | `ambient/hot-day-cicadas.mp3` | 90s | `afternoon` ที่อุณหภูมิ ≥ 30 °C |
| `hot-day` | `ambient/hot-day.mp3` | 41s | *(สำรอง)* |
| `rooster` | `oneshot/rooster.mp3` | 2.8s | ครั้งเดียวตอน stage เปลี่ยนเข้า `morning` |
| `thunder-1` / `thunder-2` | `oneshot/thunder-*.mp3` | 4.5s / 2.9s | ทุก 10 วินาทีระหว่างพายุ |
| `snow-gust` | `oneshot/snow-gust.mp3` | 2.5s | ทุก 26 วินาทีระหว่างหิมะตก |

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

## เรื่องที่ห้ามพลาด

- **ตัด bed ให้สั้นก่อนอัป** — ไฟล์ที่ได้มาทั้งชุด encode ที่ 256–320 kbps และ `Rain.mp3` ยาว **10 นาที = 19.2 MB** ซึ่งทุกคนใน workspace ที่ฝนตกต้องโหลด ทั้งที่มันวนลูปอยู่แล้ว · ตัดเหลือ 90 วินาทีด้วยการ **copy ทีละ MPEG frame** (`scratchpad/sound/trim.py`) เสียงส่วนที่เหลือจึงตรงบิตกับต้นฉบับ ไม่ได้ re-encode · **49.5 MB → 26.3 MB** และไฟล์ใหญ่สุด 19.2 → 3.4 MB
- **ยังควร re-encode ให้ต่ำกว่า 256 kbps** — เสียงบรรยากาศที่ 96 kbps mono ฟังไม่ต่างและจะลดอีกราว 60% · เครื่องที่ทำงานอยู่ไม่มี ffmpeg จึงยังไม่ได้ทำ
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
| **60** | **ไม่มีสวิตช์ปิดเสียงบรรยากาศ** — ตอนนี้ระดับเสียงอิงกับ "Notification volume" ซึ่งเป็น volume เดียวที่มีใน settings · โค้ดอ่าน `enable_environment_sounds` แบบ "ไม่ใช่ false" ไว้แล้ว เติม key นี้ทีหลังได้โดยไม่ต้องแก้อะไรอีก · **ที่อยู่ของสวิตช์คือ C7** (HP-05 personal prefs) แต่ดีไซน์ของ C7 มีแค่ 2 toggle ไม่มีเสียง ⇒ ต้องขอ design เพิ่ม |
| **61** | **เกณฑ์ 30 °C ของเสียงจักจั่น** ผมตั้งเอง — โฟลเดอร์ที่ได้มาชื่อ "Summer" แต่โมเดลไม่มีฤดู มีแต่อุณหภูมิ · ควรตัดสินคู่กับเกณฑ์ "ลมแรง" ([ข้อ 11](../plan/%5BFeature%5D%20%20%C2%B7%20Environment%20%28Time%20of%20Day%20%2B%20Weather%29%20%E2%80%94%20Virtual%20Office%20Map/spec.md)) |
| **62** | **จังหวะฟ้าผ่าเป็นของชั่วคราว** — ตอนนี้ยิงทุก 10 วินาทีด้วย timer ของตัวเอง · เมื่อ C3 วาดฟ้าแลบแล้ว **ต้องให้แสงเป็นตัวสั่งเสียง** ไม่ใช่ timer สองตัวเดินแยกกันจนหลุดจังหวะ |
| **63** | **โฟลเดอร์ `Running` ไม่ได้อัป** — footstep ในระบบ**สังเคราะห์เสียงด้วย Web Audio โดยเจตนา** (`views/user/virtual-office/footstep-sound.ts`) เพราะ sample คงที่จะฟังเหมือนปืนกลเวลาเดินเร็ว และไม่ต้องมี asset ให้ license · ถ้าอยากได้เสียงตามพื้น (กรวด/หญ้าเปียก) เป็นงานของฟีเจอร์ footstep ไม่ใช่ SC-ENV-01 |
| **64** | ไม่มี bed ของ `fog` และ `cloudy` — ตกไปใช้เสียงตามช่วงเวลา ซึ่งพอใช้ได้ แต่ถ้าอยากได้บรรยากาศอึมครึมต้องขอไฟล์เพิ่ม |
