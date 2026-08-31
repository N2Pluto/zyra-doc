# LiveKit SFU — capacity audit (2026-08-20)

คำถามตั้งต้น: client config ของ LiveKit (simulcast / dynacast / adaptiveStream) แก้อะไรได้บ้าง
เพื่อให้ SFU รับ load มากขึ้น — จาก [grafana-optimize-2026-08-20.md](grafana-optimize-2026-08-20.md)
ที่พบว่า SFU กิน 2.1 จาก 4 cores ที่ 47 participants และเป็นเพดาน capacity ของทั้ง node

**ข้อสรุปกลับหัว: สามตัวที่ถามมาตั้งถูกอยู่แล้ว และวัดแล้วว่าช่วยไม่ได้ ต้นทุนจริงไม่ได้อยู่ที่การส่ง media**

---

## 1. สามตัวที่ถาม — ตั้งถูกแล้วทั้งหมด

`zyra-app/lib/api/sfu-client.ts:300` เป็น `new Room(...)` ตัวเดียวในโปรเจกต์

| setting | ค่า | สถานะ |
|---|---|---|
| `adaptiveStream` | `true` (`:304`) | ✅ เปิด — viewer รับเลเยอร์ตามขนาด `<video>` |
| `dynacast` | `true` (`:305`) | ✅ เปิด — พอสเลเยอร์ที่ไม่มีคนดู |
| `publishDefaults.simulcast` | ไม่ได้ตั้ง → SDK default `true` | ✅ เปิดอยู่ |

ไม่มีอะไรต้องแก้ในสามตัวนี้

---

## 2. ทำไมแก้ตรงนั้นไม่ช่วย — ตัวเลขวัดจริง

จับคู่ SFU CPU กับจำนวน participant ย้อนหลัง 24 ชม. (49 sample, step 30 นาที):

```
correlation  cpu ~ concurrent participants  =  0.034      ← แทบไม่มีความสัมพันธ์
slope                                       =  0.0016 cores ต่อคน
fixed cost                                  =  1.23 cores
```

| participants | n | median cpu | min | max |
|---|---|---|---|---|
| 0 คน | 17 | **0.003** | 0.003 | 1.590 |
| 1-5 คน | 11 | 1.294 | 0.013 | 1.699 |
| 6-15 คน | 11 | 1.648 | 0.236 | 1.704 |
| 16-25 คน | 7 | 0.925 | 0.354 | 1.731 |
| 26-44 คน | 3 | 1.713 | 0.946 | 1.966 |

CPU เป็น **bimodal**: ~0.003 cores เมื่อว่างจริง แล้วกระโดดไป ~1.6-1.7 cores ทันทีที่มีคนคนแรกเข้า
และ**แทบไม่ขึ้นอีกเลย** — 47 คนเพิ่มจาก baseline นั้นแค่ ~0.4 cores

การจูน simulcast/dynacast/adaptiveStream ไปแก้ที่ slope `0.0016 cores/คน` ซึ่งคือเศษ
ไม่ได้แตะ 1.23 cores ที่เป็นก้อนจริง

**ยืนยันซ้ำจาก track ที่ publish จริง** ตอนตรวจ: `12 participants / 12 AUDIO tracks / **0 VIDEO tracks**`
แต่ CPU 1.68 cores — ไม่มีวิดีโอเลยก็ยังกินเท่านี้ ตัดความเป็นไปได้ที่ video forwarding เป็นต้นเหตุ

Packet ก็ยืนยัน: `incoming 583 pps / 543 kbps` แต่ `outgoing 4.8 pps / 2.5 kbps`
(= 12 publisher × ~50 pps ของ Opus 20ms; LiveKit ไม่ forward track ที่ mute อยู่)
543 kbps ไม่ใช่งานที่ต้องใช้ 1.7 cores

---

## 3. ต้นเหตุจริง — goroutine ค้างตามจำนวนครั้งที่ join

```
correlation  goroutines ~ cumulative joins  =  0.993
slope                                       =  15.5 goroutines ต่อ 1 join (ไม่คืน)
```

ข้อมูล 2 ชม. (step 10 นาที) — คนลดลงแต่ goroutine ขึ้นตลอด:

```
joins สะสม   goroutines
   170          3,106
   359          4,972
   561          8,283
   687         10,016
   759         11,694     ← ขณะที่ participants ลดจาก 14 เหลือ 12
```

สภาพ ณ เวลาตรวจ: **5 rooms / 12 participants / 11,975 goroutines** = **2,395 goroutine ต่อห้องที่เปิดอยู่**
ตัวเลขนี้เป็นไปไม่ได้สำหรับงานจริงต่อห้อง

- ว่างจริง (ข้ามคืน) → goroutine ลงถึง **114** เพราะฉะนั้น**ไม่ใช่ leak ถาวร** แต่เป็นการค้างที่คืนเฉพาะเมื่อห้องปิดสนิท
- ระหว่างวันทำงานที่ห้องเปิด-ปิดตลอด SFU จึงแบก 10,000-30,000 goroutine ค้าง
  (peak ที่วัดได้ 28,633 ตอน 44 คน) และ 1.2-1.7 cores นั้นคือ Go scheduler + GC ไล่ goroutine เหล่านั้น ไม่ใช่งาน media

LiveKit ที่รัน: **v1.13.0** (`zyra-sfu/Dockerfile:13`)

---

## 4. ต้นทางของ churn — 759 joins ใน 2 ชม. ที่ concurrent แค่ 12-18

> **แก้ไข (ช่วงเย็นวันเดียวกัน):** ตอนแรกผมสรุปว่าเป็น proximity circle เพราะ chatSpaceRoomId
> คือ cluster-session id ที่เปลี่ยนทุกครั้งที่ server re-cluster — **สรุปผิด** วัดจริงแล้วไม่ใช่

วัดจาก log `starting RTC session` ตัวอย่าง 100 event:

```
meeting zone (uuid)   100  (100%)
circle (cs_)            0
spotlight               0
Reconnect: false      100  (ทุกอันเป็น join ใหม่ ไม่ใช่ resume)

unique rooms 20 - unique participants 35 - ช่วงเวลา 4,874 วินาที
```

circle จะสร้าง room ชื่อ `cs_<id>` (`zyra-ws/internal/hub/chatspace.go:521`) ซึ่ง**ไม่โผล่เลย**
และฝั่ง server กัน re-cluster ของคนที่อยู่ใน session แล้วอยู่
(`if _, inSession := r.playerSession[uid]; inSession { continue }`) พร้อมมี `chatFormDebounce`
อยู่ก่อนแล้ว — circle เสถียรกว่าที่ผมคิด

**ของจริงคือคนเดิม join ห้อง meeting zone เดิมซ้ำเร็วมาก:**

```
gap ระหว่าง join ซ้ำของคู่ (room, user) เดียวกัน - n=47
  min 0.6s / median 131.2s / max 3,943s
  ต่ำกว่า 10 วินาที : 12 ครั้ง
  ตัวอย่าง gap : 0.6, 1.0, 1.1, 2.2, 2.8, 3.7, 3.8, 5.3, 6.2, 6.2, 6.3, 7.3
```

median 131s คือคนเดินเข้าออกตามปกติ แต่หางที่ต่ำกว่า 10 วิคือ**ความเร็วเครื่อง ไม่ใช่ความเร็วคน**
และ close reason ยืนยันว่าฝั่งเราสั่งเอง:

```
CLIENT_REQUEST_LEAVE        143   <- อันดับ 1
departure timeout            44
PEER_CONNECTION_DISCONNECTED  7
DUPLICATE_IDENTITY            1
```

`CLIENT_REQUEST_LEAVE` = `sfu.disconnect()` ของเราเอง ซึ่งอยู่ใน cleanup ของ effect
(`use-meeting-media.ts:1057`) แปลว่า **effect ถูก teardown + re-run** ไม่ใช่เน็ตหลุด

dep array ของ effect นั้น:

```js
}, [roomId, workspaceId, getWsClient, wsClient, t, restartLocalVad, stopLocalVad])
```

`wsClient` น่าสงสัยที่สุด แต่**ตรวจแล้วว่าเสถียร** — `WorkspaceWSClient` ถูกสร้างครั้งเดียวใน
`initSession` (`stores/vo-session-store.ts:308`) และ socket reconnect ข้างในไม่เปลี่ยน object
(effect มี handler `"reconnected"` ของตัวเองอยู่แล้วที่บรรทัด 714)
เหลือผู้ต้องสงสัย: `t` จาก `useTranslations`, `restartLocalVad`/`stopLocalVad`,
หรือ `roomId` กระพริบ null แล้วกลับมาค่าเดิม

**ยังไม่พบตัวจริง** — ต้องมี instrumentation ฝั่ง client บอกว่า dep ตัวไหนเปลี่ยน
จงใจไม่เดาแก้ hook นี้ เพราะเป็นตัวที่ทำให้เกิด desync มา 9 รอบ แก้ผิดแย่กว่า churn

## 5. สิ่งที่แก้ได้ เรียงตามผลที่วัดได้

### P0 - หาสาเหตุที่ media effect รื้อตัวเองซ้ำ แล้วค่อยแก้
ตัวที่กด 1.2-1.7 cores ได้จริงคือลดจำนวน join แต่**ยังไม่รู้ว่าอะไร trigger** (ดูข้อ 4)
ขั้นแรกคือใส่ log ว่า dep ตัวไหนเปลี่ยนก่อน teardown แล้วดู 1 วัน ไม่ใช่เดาแก้ dep array

> **ผลการเฝ้าจับ (2026-08-21, live session บน dev):** instrumentation (commit `d2d52d0`,
> อยู่บน prod v1.1.17 แล้ว) ทำงานจริง — เดินออก/เข้า zone log
> `deps that changed: roomId` พร้อม gap ms ถูกต้องทุกครั้ง
>
> **ผู้ต้องสงสัยเดิมพ้นข้อหาหมด:** นั่งใน meeting zone 10+ นาที + toggle mic,
> ส่ง reaction, เปิด/ปิด member panel, จำลอง tab hide 7s แล้ว show —
> **ศูนย์ churn** ทั้ง `t`, VAD callbacks, `wsClient` ไม่มีตัวไหนรื้อ effect เอง
>
> **กลไกจริงที่ reproduce ได้:** ขยับตัวละครคร่อมขอบ zone (ก้าวออกแล้วก้าวกลับ) —
> ทุกการข้ามขอบ = teardown + full LiveKit rejoin ทันที gap วัดได้ 2.0-4.0s ต่อขา
> ตรงกับหางของ prod (12/47 rejoins < 10s); gap 0.6s ที่เร็วสุดใน prod สอดคล้องกับ
> การเดินเฉียดมุม zone (~1 tile = 200-400ms) **ไม่มี dep bug — โค้ดทำตามที่เขียนไว้
> แต่ไม่มี grace period ตอนออกจาก zone** ทุกก้าวที่เหยียบออกนอกขอบจ่ายเต็มราคา
> LiveKit join (และ ~22 goroutines ที่ leak บน SFU ต่อครั้ง — ดู incident 2026-08-21)
>
> **ทิศทางแก้:** debounce ฝั่ง teardown — ถือ session เดิมไว้หลัง roomId
> เปลี่ยนเป็น null แล้ว reattach ถ้ากลับเข้าห้องเดิม (ยกเลิก timer ถ้าเข้าห้องอื่น)
> ต้องออกแบบระวัง — hook นี้มีประวัติ desync 9 รอบ
>
> **→ Implemented (2026-08-21): zyra-app PR #164** — `useLeaveDebouncedRoomId`
> grace 8s (ครอบ prod tail สูงสุด 7.3s) ใน `use-meeting-media.ts`; E2E บน local
> stack: wiggle ชุดเดิม 3 รอบ = **0 rejoin / 1 token mint** (เดิม 4), teardown
> ยิงที่ 8047ms เมื่อออกจริง, เข้าอีกห้อง switch ทันที; unit test 7 ตัว
> trade-off ที่จงใจ: ระหว่าง grace ยังได้ยิน/ถูกได้ยิน (ไม่ mute — เลี่ยง
> re-entrancy state machine ใน hook ประวัติเสีย)
>
> **จุดบอดของ instrumentation ที่พบ:** `churnDepsRef` เป็น per-instance ref —
> ถ้า churn เกิดจาก component remount ทั้งตัว (เช่น /loading roundtrip) จะ**ไม่มี log เลย**
> (prev=null ทุกครั้ง) ถ้าดู console ผู้ใช้จริงแล้วเงียบแต่ SFU ยังเห็น rejoin เร็ว →
> ย้าย ref ไปเป็น module-level keyed ด้วย (workspaceId, roomId)

### P1 — `empty_timeout: 300` → ~30s
`zyra-sfu/livekit-prod.yaml`

```yaml
room:
  empty_timeout: 300   # ห้องว่างอยู่ต่ออีก 5 นาที พร้อม goroutine ของมัน
```

ห้องใน VO เป็นของชั่วคราว (circle เกิด-ดับตลอด) การถือไว้ 5 นาทีหลังคนออกหมด
ทำให้มีห้องตายค้างจำนวนมากตลอดวัน แก้บรรทัดเดียว

### P1 — อัป LiveKit จาก v1.13.0
15.5 goroutine ต่อ join ที่ไม่คืนจนห้องปิดคือพฤติกรรมที่ควรเช็ค release note ของ upstream
(ยังไม่ได้ตรวจว่า version ใหม่แก้แล้วหรือยัง)

### P2 — client config ที่เป็นของจริงแต่ผลรอง
- **screen share default 1080p60 / 12 Mbps / VP9** — `use-meeting-media.ts:266`
  (`DEFAULT_SCREEN_SHARE_QUALITY = "1080p60"`) ทับ default `"720p30"` ของ `SFUClient` เอง
  และ ceiling ถูกตั้งสูงกว่า `ScreenSharePresets` ของ LiveKit โดยเจตนา (`sfu-client.ts:1458-1463`)
  ที่ 2 presenter พร้อมกันคือ 24 Mbps ขาเข้า — ยังไม่เห็นกินตอนตรวจเพราะไม่มีใคร share
- **`dtx: false` + `red: true`** (`sfu-client.ts:355,360`) ทำให้ audio ส่งเต็มอัตราตลอดและ payload เกือบสองเท่า
  ⚠️ **ห้ามพลิก `dtx` เฉยๆ** — ถูกปิดโดยเจตนาเพื่อแก้อาการเสียงขาด (ดู [[vo-audio-quality-and-device-follow]] / PR #97)
- **mic pre-warm publish ตอน mute** (`use-meeting-media.ts:916-920`) + `stopMicTrackOnMute` default `false`
  → ทุกคนถือ audio publication ที่ยังส่ง packet อยู่แม้ mute (583 pps ที่วัดได้คือตัวนี้)
  แต่ LiveKit ไม่ forward ต่อ จึงเป็นต้นทุน ingress O(N) ไม่ใช่ O(N²)
- **ไม่มี subscription management เลย** — `autoSubscribe` default `true`, ไม่มี `setSubscribed` /
  `setVideoQuality` / `setTrackSubscriptionPermissions` ที่ไหนในโปรเจกต์
  ตัวเบรกเดียวคือ `adaptiveStream` + การ unmount tile จาก pagination (10 tiles ใน expanded, 6 ใน compact)
- **ไม่มี IntersectionObserver / visibility detach** — tile ที่ mount แต่เลื่อนพ้นจอไม่ถูก detach
- **tile order ไม่สน active speaker** (`zone-enter-panel.tsx:106-121` เรียงตาม raise-hand แล้วเวลาเข้า)
  คนที่พูดอยู่หน้า 3 จึงไม่ถูก render
- **preview modal เปิด MediaPipe pipeline ที่สอง** (`vo-background-effects-modal.tsx:176-181`,
  640×360@24) ขณะ modal เปิด — CPU ฝั่ง client ไม่ใช่ server

### P3 — config ตายแล้ว
`NEXT_PUBLIC_LIVEKIT_URL` และ `NEXT_PUBLIC_LIVEKIT_SERVER_URL` ไม่ถูกอ่านจากโค้ดเลย
(URL จริงมาจาก `mintMediaToken` ต่อการ join — `lib/api/media.ts:22-34`) ลบได้หรือทำ comment กำกับ

---

## 6. สิ่งที่ยังไม่รู้

- **ยังไม่ได้ CPU profile** — `:6789/debug/pprof/*` ตอบ 200 แต่คืน `/metrics` มาให้ทุก path
  (pprof ไม่ได้เปิดจริงบน build นี้) เพราะฉะนั้น "1.2 cores = Go scheduler/GC ไล่ goroutine ค้าง"
  เป็นข้อสรุปจาก correlation + goroutine count ไม่ใช่จาก profile ถ้าต้องการความแน่นอน 100%
  ต้องเปิด pprof (LiveKit `development: true`) แล้วเก็บ profile 30 วิ
- **ยังไม่ทดสอบว่าลด `empty_timeout` แล้ว goroutine ลงจริงแค่ไหน** — วัดได้ง่ายหลังแก้
  (`go_goroutines{job="livekit-sfu"}` เทียบกับ `livekit_participant_join_total`)
