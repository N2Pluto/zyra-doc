# "New device detected" เด้งซ้ำ + เสียงห้องแชทย้ายเองเมื่ออุปกรณ์เดิมต่อกลับ (ZYR-1144)

> **สถานะ:** รอบที่ 2 แก้แล้ว — **ยังไม่ได้ live-test** (ต้องมีอุปกรณ์ Bluetooth ถอด/ต่อจริง) · unit test เขียว (`media-preference`, `media-device-watch`, `media-settings-store`, `sfu-capture-device-recovery` รวม 91 เคส) + `tsc`/eslint/prettier สะอาด (tsc มี 7 error เดิมใน test file อื่นบน develop อยู่แล้ว ไม่เกี่ยว) · **repo:** zyra-app (client-only)
> **branch:** zyra-app `fix/device-switch-prompt-once` · **ticket:** ZYR-1144
> **ขอบเขต:** เฉพาะ prompt + preference ของเสียง **ห้องแชท (LiveKit)** — เสียงแจ้งเตือนของระบบ (chat/knock/wave ฯลฯ) ไม่ได้แตะ และไม่เคยผูกกับ picker ใน Zyra อยู่แล้ว (ดู §เสียงระบบ vs เสียงพูด)

## อาการที่รายงาน (ticket ZYR-1144, bug_report, impact: partially usable)

> zyra ชอบเปลี่ยน input output เองเวลาเจออุปกรณ์ใหม่ และเปลี่ยนกลับ/เลือกเองไม่ได้ ทำให้บางทีเปลี่ยนไป output ที่ใช้งานไม่ได้จริงทำให้ไม่ได้ยินเสียง แล้วเปลี่ยนกลับเองใน app ไม่ได้

สิ่งที่ผู้ใช้ต้องการ (สรุปจากที่คุยกัน 2026-09-28):

1. เสียงพูดยึดตามที่เลือกใน Zyra · เสียงแจ้งเตือนระบบดังตาม default ของ OS (แบบ Discord)
2. อุปกรณ์ที่**เคยตอบ modal แล้ว** (กด Switch หรือ X) ต่อกลับมาอีก → **ไม่ขึ้น modal ซ้ำ และไม่สลับให้เอง** — อยู่กับอุปกรณ์เดิมที่ใช้อยู่ ผู้ใช้ไปเลือกเองใน device menu
3. กด Switch ต้องเปลี่ยนเฉพาะเสียงห้องแชท ไม่แตะเสียงระบบ

## เสียงระบบ vs เสียงพูด — แยกกันอยู่แล้วในโค้ด

| เสียง | เล่นผ่าน | ผูกกับอุปกรณ์ที่ |
|---|---|---|
| เสียงพูด/ห้องแชท | LiveKit `<audio>` ใน `sfu-client.ts` | `room.switchActiveDevice("audiooutput")` → `setSinkId` = ที่เลือกใน Zyra |
| แจ้งเตือน (chat, mention, knock, wave, enterRoom, shareScreen ฯลฯ) | `new Audio()` ใน `use-vo-sounds.ts` — ไม่มี `setSinkId` | OS default เสมอ |
| pet / environment / footstep | `AudioContext.destination` | OS default เสมอ |

ข้อ 1 และ 3 จึงเป็นไปตามที่ต้องการอยู่แล้ว ไม่ได้แก้อะไร — browser เปลี่ยน OS default ไม่ได้อยู่แล้ว สิ่งที่ผู้ใช้เห็นว่า "เปลี่ยนเอง" คือเสียงห้องแชทย้ายตาม OS default (root cause ด้านล่าง) ไม่ใช่เสียงระบบ

## รอบที่ 1 — 2026-09-02 (commit `a4c0f99`)

กด X แล้วไม่ได้ save preference → join/reconnect ครั้งถัดไป `establish()` ไม่มี pref รั้งไว้ เลยตาม OS default ไปหาอุปกรณ์ที่เพิ่งปฏิเสธ → แก้โดย pin อุปกรณ์ที่ใช้อยู่เป็น pref ตอนกด X (`kindsNeedingPinOnDismiss`) + จำ "no" ต่ออุปกรณ์ใน `zyra_dismissed_devices`

## รอบที่ 2 — 2026-09-28

### Root cause ที่เหลือ

`use-meeting-media.ts` ตอน join meeting: ถ้าอุปกรณ์ที่ pin ไว้ (เช่น AirPods) ไม่ได้ต่ออยู่ตอนนั้น โค้ด**ล้าง preference เป็น `""`** (= ตาม OS default) ทิ้งเลย

```
กด Switch → AirPods ถูก pin
ถอด AirPods → เข้า meeting → pref ถูกล้างเป็น ""
ต่อ AirPods กลับ → macOS ย้าย default ไป AirPods
  → เสียงห้องแชทย้ายตาม (pref ว่าง)            ← "zyra ชอบเปลี่ยนเอง"
  → modal เด้งอีกรอบ (pref ≠ AirPods, และ Switch ไม่เคยถูกจำ)  ← "น่ารำคาญ"
```

ซ้ำอีกชั้น: การกด **Switch** ไม่ถูกจำ (จำเฉพาะ X) และการเลือกจาก device menu ยัง "ลืม" คำตอบเดิม (`forgetDismissedDevice`) → เคยกด Switch ให้ AirPods, แล้วต่อมาเลือก AirPods จาก menu, ต่อกลับ → ถามอีก

### สิ่งที่แก้ (zyra-app)

| ไฟล์ | เปลี่ยน |
|---|---|
| `lib/media-preference.ts` | `isDeviceDismissed`/`rememberDismissedDevice` → `isDeviceAnswered`/`rememberAnsweredDevice` (จำทั้ง Switch และ X) · ลบ `forgetDismissedDevice` · **คง localStorage key `zyra_dismissed_devices` เดิม** ให้ "no" ที่จำไว้แล้วยังใช้ได้ |
| `use-meeting-media.ts` — `confirmDeviceSwitch` | กด Switch → `rememberAnsweredDevice` (เดิม forget) |
| `use-meeting-media.ts` — `selectDevice` | ไม่ลืมคำตอบเดิมอีก (ลบ forget) |
| `use-meeting-media.ts` — join (`establish`) | อุปกรณ์ที่ pin ไว้ไม่อยู่ → **ไม่ล้าง pref** ใช้ OS default ชั่วคราว; UI ของ picker โชว์ "System default" ระหว่างนั้น (เหมือน path `devicesChanged` ที่ทำอยู่แล้ว) |
| `vo-device-switch-modal.tsx` | comment ให้ตรง behavior ใหม่ |
| `__tests__/media-preference.test.ts` | rename + เพิ่มเคสอ่าน key เดิม, ตัดเคส un-decline |

พฤติกรรมหลังแก้เมื่ออุปกรณ์ที่เคยตอบ modal ต่อกลับมา: **ไม่ขึ้น modal, ไม่สลับให้** (ตามที่ผู้ใช้เลือก) — ถ้าอุปกรณ์นั้นเป็น pref ที่ pin ไว้ จะกลับไปใช้ตอน join meeting ครั้งถัดไป (เพราะ pref ไม่ถูกล้างแล้ว) หรือผู้ใช้เลือกเองจาก device menu ได้ทันที

### สิ่งที่ไม่ได้แก้ / ยังเปิดอยู่

- "เปลี่ยนกลับเองใน app ไม่ได้" — ยังไม่รู้สถานการณ์จริงว่าผู้ใช้เจออะไร (menu ไม่มีอุปกรณ์? เลือกแล้วไม่ย้าย? หาที่เปลี่ยนไม่เจอ — picker มีเฉพาะใน HUD ตอนอยู่ใน meeting + zone-enter header) ถามไปแล้วยังไม่ได้คำตอบ ไม่ได้เดา
- ค่าเริ่มต้นที่ยังไม่เคยเลือกอะไรใน Zyra = ตาม OS default (เหมือน "Default" ของ Discord) — คงเดิม

### Before/After

**ยังไม่ได้วัด** — เหตุผล: behavior ทั้งหมดอยู่ใน localStorage ฝั่ง client ไม่มี metric ฝั่ง server/Grafana ที่จับได้ว่า modal เด้งกี่ครั้ง; สิ่งที่วัดได้จริงคือ ticket ซ้ำเรื่องเดียวกันหลัง deploy dev/uat ให้ผู้รายงาน ZYR-1144 ลองถอด/ต่อ AirPods ซ้ำ

### Verify ถึงไหน

- ✅ build: `tsc` (ไม่มี error ในไฟล์ที่แตะ), eslint, prettier, vitest 91/91
- ❌ live-test: ยังไม่ได้ — ต้องมีอุปกรณ์ Bluetooth ถอด/ต่อจริงบน dev หลัง merge

### ต่อจากนี้

1. commit + push `fix/device-switch-prompt-once` → PR เข้า `develop`
2. ให้ผู้รายงาน ZYR-1144 ทดสอบบน dev: (a) กด Switch ให้ AirPods → ถอด → เข้า meeting → ต่อกลับ → ต้อง**ไม่มี modal** และเสียงห้องแชท**ไม่ย้าย**จนกว่าจะเลือกเอง / join ใหม่ (b) กด X แล้วต่อกลับ → ไม่มี modal
3. ถามผู้รายงานเรื่อง "เปลี่ยนกลับใน app ไม่ได้" ให้ชัดก่อนแตะ picker
