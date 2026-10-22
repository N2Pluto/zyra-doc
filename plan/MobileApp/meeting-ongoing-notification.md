# Mobile App — แจ้งเตือนค้างระหว่างประชุม / คุยกับคนใกล้ ๆ (แบบ Google Meet)

> **สถานะ:** Merge เข้า `develop` แล้ว รอเทสบนเครื่องจริง (2026-10-19) — zyra-app #614 · zyra-mobile #22 (Android), #23 (iOS) · ยังไม่ขึ้น UAT / TestFlight · **repo:** zyra-mobile (Android + iOS), zyra-app · **ClickUp:** ยังไม่มี task
> **ที่มา:** rif ขอ 2026-10-19 — "ตอน mobile ถ้าเราอยู่ในห้องประชุมหรือคุยกับใครอยู่ อยากให้ขึ้นใน noti ของโทรศัพท์ คล้าย ๆ Google Meet"
> **เอกสารคู่กัน:** [spec.md](spec.md) (SC-MOB-11) · [task-breakdown.md](task-breakdown.md) (1.18–1.20) · [technical-design.md](technical-design.md) §13, §14.1 A2 · [progress.md](progress.md)

## 1. Requirement ต้นทาง (คำตอบ rif 2026-10-19)

| # | คำถาม | คำตอบ |
|---|---|---|
| 1 | ขึ้นตอนไหน | **ทั้งสองกรณี** — อยู่ในห้องประชุม (meeting / private zone) และคุยกับคนใกล้ ๆ (proximity circle) · **+ Spotlight** (OQ 1) |
| 2 | แสดงอะไร | **ทั้งหมด** — ชื่อห้อง/วงคุย · เวลาที่อยู่ในห้อง · จำนวนคน · ปุ่ม Mute และ Leave |
| 3 | iOS | **ทำพร้อมกันเลย** ไม่แยกเฟส |
| 4 | แตะ notification | **กลับเข้าแอป** ไปที่ห้องนั้นเลย |
| 5 | หน้าตา | **ใช้แบบมาตรฐานของ OS** ไม่มี Figma |

## 2. Current implementation (ตรวจ 2026-10-19)

| ส่วน | มีแล้ว | ที่อยู่ |
|---|---|---|
| Android foreground service ระหว่างอยู่ใน media room | ✅ (B-32 · task 1.17) — type `microphone\|mediaPlayback` · ไม่มีสิทธิ์ไมค์ → `mediaPlayback` อย่างเดียว | zyra-mobile `develop`: `android/.../MeetingForegroundService.java`, `MeetingServicePlugin.java` |
| Notification ของ Android | ✅ แต่เป็นข้อความตายตัว "Zyra — in a meeting" / "Your meeting keeps running while the screen is off. Tap to return." · ไม่มีชื่อห้อง เวลา จำนวนคน หรือปุ่ม · แตะ = เปิด `MainActivity` | `MeetingForegroundService#buildNotification` · `res/values{,-th}/strings.xml` |
| ฝั่งเว็บสั่งเปิด/ปิด | ✅ `setMeetingForegroundService(on)` เรียกพร้อม call-audio hold — เปิดเมื่อ media room แรกต่อติด ปิดหลังห้องสุดท้าย 2 วิ · **ครอบ meeting, circle และ Spotlight อยู่แล้ว** เพราะทุกอย่างผ่าน SFU room เดียวกัน | zyra-app `lib/native/foreground-service.ts`, `lib/native/audio-session.ts`, `lib/api/sfu-client.ts` (`acquireCallAudio`) |
| ห้องที่กำลังอยู่ | ✅ id เดียว `meetingZoneId ?? spotlightRoomId ?? chatSpaceRoomId` | zyra-app `views/user/virtual-office/use-meeting-media.ts:533` |
| ปุ่ม Mute / Leave ในแอป | ✅ `toggleMic` · `handleLeaveMeetingGoHome` (meeting) | `use-meeting-media.ts:1890` · `hero-virtual-office.tsx:5254` |
| iOS | ❌ ไม่มีอะไรที่ผู้ใช้เห็น นอกจากจุดไมค์ของ OS · `UIBackgroundModes: audio` ทำให้แอปไม่ถูก suspend ระหว่างประชุม | zyra-mobile `ios/App/App/Info.plist` |

## 3. Gap

1. Android: notification ไม่มีข้อมูลห้อง เวลา จำนวนคน และไม่มีปุ่ม · plugin มีแค่ `start()` / `stop()` ส่งข้อมูลจากเว็บไม่ได้ · ไม่มีช่องให้ native ส่งการกดปุ่มกลับมาที่หน้าเว็บ
2. iOS: ต้องสร้างใหม่ทั้งหมด — iOS **ไม่มี notification ค้างแบบ Android** ของที่ใกล้ที่สุดคือ **Live Activity** (บนหน้าล็อก + Dynamic Island) ซึ่งเดิมจัดไว้ Tier 3 → มติข้อ 3 ดึงขึ้นมาทำตอนนี้
3. zyra-app: ต้องส่งชื่อห้อง/เวลาเริ่ม/จำนวนคน/สถานะไมค์ไปให้ native และรับ action Mute / Leave กลับมา

## 4. Proposal (ข้อเสนอของ Agent — ยังไม่ approve)

### 4.1 Contract เว็บ ↔ native (plugin `MeetingService` เดิม ขยายเพิ่ม)

ใช้ชื่อ plugin เดิมทั้งสอง OS · method เดิมยังใช้ได้ (shell เก่าไม่มี `update` ก็แค่ไม่มีข้อมูล)

```ts
type OngoingCallKind = "meeting" | "circle" | "spotlight"

interface OngoingCallInfo {
  kind: OngoingCallKind
  roomId: string          // id จาก use-meeting-media (zone id / "cs_…" / "spotlight:<floorId>")
  title: string           // ชื่อ zone · "กำลังคุยกับ N คน" (ไม่ใส่ชื่อ — OQ 3) · "Spotlight" — แปลแล้วจากฝั่งเว็บ
  startedAt: number       // epoch ms ตอนเข้าห้อง — native นับเวลาเอง ไม่ต้องส่งทุกวินาที
  participantCount: number
  micOn: boolean
  canMute: boolean        // false เมื่อไม่มีสิทธิ์ไมค์ หรือถูก host ล็อก
}

interface MeetingServicePlugin {
  start(info?: OngoingCallInfo): Promise<void>   // เดิม start() ไม่มี argument
  update(info: OngoingCallInfo): Promise<void>   // ใหม่ — จำนวนคน / ไมค์ / ย้ายห้อง
  stop(): Promise<void>
  addListener(event: "action", cb: (e: { action: "toggleMic" | "leave"; roomId: string }) => void): Promise<PluginListenerHandle>
}
```

- `update` ส่งเมื่อค่าเปลี่ยนเท่านั้น (จำนวนคน, ไมค์, ย้ายห้อง) · debounce ~500 ms กันคนเข้าออกถี่
- action ที่ `roomId` ไม่ตรงห้องปัจจุบัน → ทิ้ง (กันกดปุ่มของห้องเก่า)
- แตะตัว notification → เปิดแอปเฉย ๆ · หน้าเว็บยังอยู่ในห้องเดิม จึงเห็นห้องนั้นทันที (ข้อ 4)

### 4.2 Android (zyra-mobile)

- `MeetingForegroundService` รับ `OngoingCallInfo` ผ่าน Intent extra · `update` = `NotificationManager.notify(4101, …)` ด้วย id เดิม
- ใช้ **`NotificationCompat.CallStyle.forOngoingCall(person, hangUpIntent)`** — หน้าตาเดียวกับ Google Meet / โทรศัพท์บน Android 12+ (ปุ่มวางสายสีแดง) · ต่ำกว่า 12 compat จะ render เป็น notification ธรรมดาที่มีปุ่ม
- เวลา: `setWhen(startedAt)` + `setUsesChronometer(true)` — OS นับเอง
- เนื้อหา: title = ชื่อห้อง · text = "3 คน" · ปุ่ม Mute/Unmute (ซ่อนเมื่อ `canMute=false`) + Leave
- ปุ่ม → `PendingIntent` ไป `BroadcastReceiver` ใน app → `MeetingServicePlugin.notifyListeners("action", …)`
- คงพฤติกรรม B-32 เดิมทั้งหมด (fallback type, `START_NOT_STICKY`, `onTaskRemoved`)
- strings ใหม่ EN / TH

### 4.3 iOS (zyra-mobile)

- เพิ่ม target **Widget Extension** (SwiftUI + ActivityKit) · `NSSupportsLiveActivities = YES` ใน `Info.plist`
- iOS ขั้นต่ำ: **16.1** แสดงได้ · **ปุ่ม Mute / Leave ต้อง iOS 17+** (`LiveActivityIntent`) · ต่ำกว่า 17 แสดงอย่างเดียว
- plugin Swift `MeetingService` (ไฟล์ใหม่ข้าง `ZyraAssetPackPlugin.swift`): `start` → `Activity.request` · `update` → `activity.update` · `stop` → `activity.end(dismissalPolicy: .immediate)`
  - `start` ต้องเรียกตอนแอปอยู่ foreground — เป็นอยู่แล้วเพราะผู้ใช้เดินเข้าห้องเอง
  - `update` ตอน background ทำได้เพราะ audio mode ทำให้แอปยังรันอยู่ระหว่างประชุม (§13) · **ไม่ต้องใช้ push** สำหรับ Live Activity
- เวลา: `Text(timerInterval: startedAt...)` — ระบบนับเอง
- หน้าล็อก: ชื่อห้อง · เวลา · จำนวนคน · ปุ่ม · Dynamic Island: compact = icon + เวลา, expanded = ทั้งหมด
- `LiveActivityIntent` รันใน process ของแอป → ส่งเข้า plugin → `notifyListeners("action", …)`
- แตะ → `widgetURL(zyra://…)` เปิดแอป (ใช้ deep link scheme เดิมของ 1.9)
- กัน Live Activity ค้าง: ตั้ง `staleDate` · ตอนเปิดแอปใหม่ / `stop` ปิดทุก activity ที่ค้าง (แอปถูก kill ระหว่างประชุม activity จะค้างได้ถึง 8 ชม.)
- หมายเหตุ: ผู้ใช้ปิด Live Activities ใน Settings ได้ → แค่ไม่แสดง ประชุมยังทำงานตามเดิม

### 4.4 zyra-app

- ขยาย `lib/native/foreground-service.ts`: `setMeetingForegroundService` คงเดิม (เปิด/ปิดตาม call-audio hold) + เพิ่มฟังก์ชันส่ง `OngoingCallInfo` และรับ `action` · เรียก native บน `"android"` **และ** `"ios"` (เดิม Android อย่างเดียว)
- ข้อมูลประกอบจาก `hero-virtual-office.tsx` (ชื่อ zone, roster/จำนวนคน) + `use-meeting-media.ts` (`roomId`, `micOn`)
- action:
  - `toggleMic` → `toggleMic()` เดิม (ผ่าน permission / host-lock check เดิมทั้งหมด)
  - `leave` → meeting / circle = `handleLeaveMeetingGoHome()` (เดินกลับ) · Spotlight = action ของปุ่ม Leave ของ Spotlight เดิม (OQ 2)
- เว็บ / PWA: ไม่เปลี่ยนอะไร

## 5. Scenario / Acceptance criteria — SC-MOB-11

| # | ทำ | ผลที่ต้องได้ | Android | iOS |
|---|---|---|---|---|
| 1 | เข้า meeting zone แล้วออกไปหน้า Home / ล็อกจอ | notification / Live Activity แสดงชื่อ zone, เวลานับขึ้น, จำนวนคน | ✓ | ✓ (16.1+) |
| 2 | เดินไปคุยกับคนใกล้ ๆ (circle) / ยืนบน Spotlight | แสดงเหมือนข้อ 1 · circle = "กำลังคุยกับ N คน" ไม่มีชื่อคน · Spotlight = "Spotlight" | ✓ | ✓ |
| 3 | มีคนเข้า/ออกห้อง | จำนวนคนอัปเดตภายใน ~2 วิ | ✓ | ✓ |
| 4 | กด Mute ใน notification | ไมค์ปิดจริง · ปุ่มในแอปและ indicator ของคนอื่นตรงกัน · ปุ่มเปลี่ยนเป็น Unmute | ✓ | ✓ (17+) |
| 5 | ไม่มีสิทธิ์ไมค์ / host ล็อกไมค์ | ไม่มีปุ่ม Mute หรือกดแล้วไม่เปิดไมค์ | ✓ | ✓ |
| 6 | กด Leave | ออกจากห้องเหมือนกดในแอป · notification หาย | ✓ | ✓ (17+) |
| 7 | แตะตัว notification | เปิดแอปอยู่ในห้องนั้น | ✓ | ✓ |
| 8 | เดินออกจากห้อง / ย้ายห้อง | หายหลังห้องสุดท้าย (เกณฑ์ 2 วิเดิม) · ย้ายห้อง = อัปเดตเป็นห้องใหม่ ไม่ขึ้นซ้ำสองอัน | ✓ | ✓ |
| 9 | ปัดแอปทิ้งกลางประชุม | ไม่มี notification / Live Activity ค้าง (iOS: ปิดตอนเปิดแอปครั้งถัดไปอย่างช้าสุด) | ✓ | ✓ |
| 10 | shell เก่าที่ไม่มี `update` | ประชุมทำงานปกติ ไม่มี error · Android แสดงข้อความเดิม | ✓ | ✓ |

ทดสอบบนเครื่องจริงเท่านั้น (simulator iOS ไม่มี Dynamic Island ครบ และไม่มีไมค์จริง)

## 6. Open questions

| # | คำถาม | ข้อเสนอ | สถานะ |
|---|---|---|---|
| 1 | Spotlight (ทั้งคนพูดและคนดู) ให้ขึ้นด้วยไหม | ขึ้นด้วย — โค้ดเปิด service ให้ Spotlight อยู่แล้ว (B-32) · title = "Spotlight" | ✅ rif 2026-10-19: ขึ้น |
| 2 | ปุ่ม Leave ของวงคุย (circle) / Spotlight หมายถึงอะไร — วงคุยไม่มีปุ่ม Leave ในแอป | circle = เดินกลับที่นั่ง/Home แบบ `handleLeaveMeetingGoHome` · Spotlight = ทำแบบปุ่ม Leave ของ Spotlight เดิม | ✅ rif 2026-10-19: ตามข้อเสนอ |
| 3 | หน้าล็อกแสดงชื่อห้อง/ชื่อคนได้ไหม (คนอื่นเห็นหน้าจอที่ล็อกได้) | แสดงชื่อ zone + จำนวนคน · วงคุยแสดง "กำลังคุยกับ 2 คน" ไม่ใส่ชื่อ | ✅ rif 2026-10-19: ตามข้อเสนอ |
| 4 | iOS 16.x แสดงได้แต่ไม่มีปุ่ม — รับได้ไหม | รับได้ (ข้อจำกัดของ OS) | ✅ rif 2026-10-19: รับได้ |

## 7. Readiness

- **พร้อมเริ่ม:** contract §4.1 + Android 1.18 (ต่อยอดของเดิม) · zyra-app 1.20 ส่วนส่งข้อมูล
- **Open questions:** ตอบครบแล้ว (2026-10-19)
- **ต้องได้ก่อน 1.19:** Apple: เพิ่ม Widget Extension = bundle id ใหม่ `<app-id>.LiveActivity` ใน provisioning profile + fastlane match (กระทบ CI `release.yml`)
- **ความเสี่ยง:** Live Activity + audio mode ใน WKWebView ยังไม่เคยลองบนเครื่องจริงใน repo นี้ · ต้องเช็กว่า intent ปุ่มไปถึงหน้าเว็บตอนจอล็อกจริง

## 8. Implementation (2026-10-19)

ต่างจาก proposal §4:

- **Contract:** ส่ง `subtitle` (แปลแล้ว) แทน `participantCount` — ภาษาของแอปเป็น cookie ฝั่งเว็บ ไม่ใช่ภาษาเครื่อง · มี `canLeave` (ไม่มี handler = ซ่อนปุ่ม)
- **iOS ขั้นต่ำของแอปคือ 17.5 อยู่แล้ว** (`IPHONEOS_DEPLOYMENT_TARGET`) → ปุ่มใช้ได้ทุกเครื่อง · OQ 4 ไม่เกิด
- **iOS:** เก็บข้อมูลทั้งหมดใน content state (ไม่ใช่ attributes) → ย้ายห้องตอนจอล็อก = update การ์ดเดิม (สร้างใหม่ทำได้เฉพาะตอนแอปอยู่ foreground) · ไม่ใส่ `widgetURL` → แตะแล้วเปิดแอปเฉย ๆ ไม่วิ่งผ่าน deep link
- **Android:** ปุ่ม Leave เป็นปุ่มวางสายของ `CallStyle` — ข้อความ "Hang up" มาจาก OS ตั้งค่า label เองไม่ได้
- **วงคุย (circle) ที่ไม่มีที่นั่ง (claim):** `handleLeaveMeetingGoHome` ไม่มีที่ให้เดินกลับ → ไม่แสดงปุ่ม Leave
- **หลายห้องพร้อมกัน** (เช่น อยู่ในประชุม + ดู Spotlight): แสดงห้องที่เริ่มล่าสุด · คนดู Spotlight ขึ้นการ์ดเฉพาะตอนไม่อยู่ในห้องอื่น
- **Spotlight presenter กด Leave บนการ์ด:** จบการถ่ายทอดเลย ไม่มี sheet ยืนยัน (การกดบนการ์ดถือเป็นคำตอบ)

| repo | branch | ไฟล์หลัก |
|---|---|---|
| zyra-app | `feat/meeting-ongoing-notification` | `lib/native/foreground-service.ts`, `lib/native/ongoing-call.ts` (ใหม่), `hooks/use-ongoing-call.ts` (ใหม่), `hero-virtual-office.tsx`, `lite/lite-meeting.tsx`, `lite/lite-spotlight.tsx`, `messages/{en,th}.json` (`OngoingCall`) |
| zyra-mobile | `feat/meeting-call-card-android` | `MeetingForegroundService.java`, `MeetingServicePlugin.java`, `OngoingCall.java` (ใหม่), `res/drawable/ic_action_*.xml` |
| zyra-mobile | `feat/meeting-call-card-ios` | target ใหม่ `ZyraLiveActivity/`, `App/MeetingServicePlugin.swift`, `App/ZyraCallActivity.swift`, `Info.plist`, `MainViewController.swift`, `project.pbxproj` (เพิ่มด้วย gem `xcodeproj`) |
