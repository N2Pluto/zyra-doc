# Room Pet — เสียง pat ทำให้ media panel ของเบราว์เซอร์มีรายการ "Zyra" ค้างเป็นตับ

> แก้แล้ว รอ merge · 2026-09-08 · กระทบ zyra-app (`lib/pet-sound-player.ts`) · branch `fix/pet-sound-media-panel-leak`

## อาการ

pat สัตว์เลี้ยงใน Virtual Office ไปสัก 4–5 ครั้ง แล้วเปิด media panel ของ Zen (เบราว์เซอร์ฐาน Firefox)
จะเจอรายการ "Zyra" ซ้อนกันเป็นสิบแถว แต่ละแถวเป็น player คนละตัว ค้างอยู่ที่ `0:00 / 0:14` ไม่หายไปเอง
(ผู้ใช้แจ้ง 2026-09-08 พร้อมภาพหน้าจอ)

## Root cause

`lib/pet-sound-player.ts` เก็บ `HTMLAudioElement` **หนึ่งตัวต่อหนึ่ง URL** ไว้ใน `cache` เพื่อไม่ให้โหลดคลิปซ้ำ
แล้วไม่เคยปล่อยเลย — หนึ่ง session จึงมี element ค้างได้สูงสุด ~20 ตัว (cat 9 + dog 4 + bird 6 + evolution)

สองอย่างประกอบกันจนกลายเป็นแถวใน media panel:

1. Firefox/Zen ผูก **media controller หนึ่งตัวต่อ media element ที่ยังถือ resource อยู่** — `pause()` ไม่ทำให้แถวหาย
   ต้องคืน resource (`removeAttribute("src")` + `load()`) หรือทิ้ง element ไปเลย แถวถึงจะหาย
2. เบราว์เซอร์ไม่นับ media สั้น ๆ เข้า panel แต่คลิปต้นทางยาวพอที่จะเข้าเกณฑ์จริง —
   `bird/adult/04` = 224 KB ≈ 14 วิ (ตรงกับ `0:14` ในภาพ), `cat/baby/06` = 421 KB ≈ 26 วิ
   (เราตัดเสียงที่ 2.5 วิด้วย fade แต่ element ยังรู้จัก duration เต็มอยู่ดี)

## สิ่งที่แก้

เปลี่ยนไปเล่นผ่าน **Web Audio API** แทน `<audio>` ทั้งหมด — `AudioBuffer` ไม่มี media element อยู่เบื้องหลัง
จึงไม่ลงทะเบียน media controller เลย ทั้งใน Zen/Firefox และ Chrome

- fetch คลิปผ่าน `/api/img?url=…` (proxy ของแอปเอง) แล้ว `decodeAudioData` —
  ต้องผ่าน proxy เพราะ R2 (`pub-*.r2.dev`) **ไม่ส่ง `Access-Control-Allow-Origin`** ต่างจาก `<audio src>` ที่ข้าม origin ได้
- cache เป็น `AudioBuffer` ต่อ URL: คลิปเดิม pat ซ้ำ = ไม่มี request ใหม่ ไม่ decode ใหม่
- ตัดที่ `PET_SOUND_MAX_MS` (2.5 วิ) ด้วย `linearRampToValueAtTime` บน `GainNode` แทน `setInterval` —
  fade เดินตาม audio clock จึงไม่กระตุกตาม main thread
- `suspend()` context เมื่อเงียบครบ 5 วิ แล้ว `resume()` ตอนเล่นครั้งถัดไป (แท็บ VO เปิดค้างเป็นชั่วโมง ไม่ควรจองอุปกรณ์เสียงไว้)
- fallback: ถ้าเบราว์เซอร์ไม่มี `AudioContext` หรือ decode ไม่ผ่าน ถอยไปใช้ `<audio>` **ตัวเดียว** ที่คืน `src` ทันทีที่เล่นจบ
  — แถวใน panel จึงหายไปพร้อมเสียง ไม่ค้างเหมือนเดิม

API ภายนอกเหมือนเดิมทุกอย่าง (`playPetVoice` / `playPetEvolutionSound` / `stopPetSound`) call site ไม่ต้องแก้

## Verify

| ตรวจ | ก่อนแก้ | หลังแก้ |
|---|---|---|
| media controller ที่ลงทะเบียน หลังเล่น 4 คลิป | 4 แถว (1 ต่อ URL, ค้าง) | 0 — `navigator.mediaSession.metadata` = null, `playbackState` = `none` |
| `document.querySelectorAll("audio").length` / element ที่ถูกสร้าง | 4 | 0 |
| request ของ `cat/baby/01.mp3` เมื่อเล่นคลิปเดิม 4 ครั้ง | โหลดครั้งแรกครั้งเดียว (แต่ element ค้าง) | 1 ครั้ง ผ่าน `/api/img` แล้ว reuse buffer |
| คลิปยาว 13.2 วิ | ตัดที่ 2.5 วิ | ตัดที่ 2.5 วิ (`source.stop()` ที่ +2.500) — เท่าเดิม |

วัดที่ `/dev/preview/room-pat` (public) บน dev server ผ่าน Browser pane (Chromium):
patch `AudioBufferSourceNode.prototype.start/stop` เพื่ออ่านเวลาเริ่ม/หยุดจริง + `read_network_requests`

**ยังไม่ได้ทดสอบบน Zen เอง** — เครื่องมือที่ขับได้เป็น Chromium จึงยืนยันได้แค่ว่า "ไม่มี media element / ไม่มี media session"
ซึ่งเป็นเงื่อนไขเดียวที่ทำให้ Zen สร้างแถวนั้น ควรให้ผู้ใช้เปิด media panel ของ Zen ยืนยันซ้ำหลัง merge เข้า dev

## Test

- `__tests__/pet-sound-player-web-audio.test.ts` (ใหม่) — decode ผ่าน proxy, ไม่สร้าง element, cap 2.5 วิ, decode ครั้งเดียว, stop จริง, สวิตช์ปิดแล้วเงียบสนิท
- `__tests__/pet-sound-player-mute.test.ts` (เดิม) — ยังคุม path fallback (jsdom ไม่มี `AudioContext`)
