# Analytics & Event Tracking — Mixpanel · GTM · Sentry

> สถานะ: ใช้งานจริงแล้ว (prod v1.5.0 ขึ้นไป) · อัปเดต 2026-09-17 · กระทบ repo: `zyra-app`

เอกสารนี้อธิบายว่าแอปเก็บ event อะไรบ้าง ชื่อ event ตั้งยังไง เพิ่ม event ใหม่ยังไง และอะไรที่ **ห้าม** เก็บ

---

## ภาพรวม — 3 เครื่องมือ ชื่อเดียว

ทุก action ยิงออกครั้งเดียวผ่าน `trackAppEvent()` แล้วกระจายเข้า 3 ที่พร้อมกัน:

| เครื่องมือ | ได้ชื่อแบบไหน | ใช้ดูอะไร |
|---|---|---|
| **Mixpanel** | Title Case — `Message Sent` | funnel, retention, ใครทำอะไรบ่อยแค่ไหน |
| **GTM / GA4** | snake_case — `message_sent` (แปลงอัตโนมัติ) | marketing, conversion |
| **Sentry** | breadcrumb `ui.action` / `ui.click` | ไล่ย้อนว่าก่อน error ผู้ใช้กดอะไรมาบ้าง |

ไม่ต้องจำสองชื่อ — เขียนชื่อเดียวใน `AppEvent` แล้ว `toGtmEventName()` แปลงให้เอง

```
lib/analytics/
  events.ts          ← แคตตาล็อกชื่อ event + trackAppEvent() + trackSettingChange()  ← ไม่ import SDK ใดๆ
  sinks.ts           ← ผูก Mixpanel/GTM/Sentry เข้ากับ events.ts (ลงทะเบียนฝั่ง client)
  click-tracking.ts  ← ชั้นอัตโนมัติ: อ่าน DOM แล้วสร้าง event เอง
  ws-events.ts       ← แปลง WebSocket frame ของ VO เป็น event
  mixpanel.ts        ← init + identify + session replay
components/click-tracker.tsx  ← ตัว mount listener (อยู่ใน app/layout.tsx)
instrumentation-client.ts     ← เรียก registerDefaultAnalyticsSinks() ก่อน React hydrate
```

**`events.ts` ตั้งใจไม่ import SDK เลย** — store กับ API helper เรียก `trackAppEvent()` ได้จากทุกที่รวมถึง test ที่รันบน Node ส่วน SDK จริงถูกต่อเข้ามาทีหลังเป็น "sink" เฉพาะฝั่ง browser ถ้า import Sentry เข้าไปใน Zustand store ตรงๆ จะทั้งถ่วง bundle และทำให้ test ที่ไม่ได้รันในเบราว์เซอร์พังทันที (เคยพังมาแล้วตอนทำ)

---

## กติกาตั้งชื่อ event

**`<สิ่งของ> <กริยาอดีต>` Title Case เสมอ** — อ่านแล้วรู้ทันทีว่าเกิดอะไรขึ้น

```
✅ Message Sent · Meeting Joined · Screen Share Started · Audio Setting Changed
❌ click_send · sendMsg · btn_click_1 · Message  (ไม่มีกริยา / ไม่สื่อ / ซ้ำกับตัวอื่นไม่ได้)
```

- ชื่อต้อง**ไม่ซ้ำ**และ**ต่างกันชัด** — มี unit test บังคับไว้ใน `__tests__/analytics-events.test.ts`
- ชื่อต้อง **ไม่ผูกกับภาษา UI** — ห้ามเอา text บนปุ่มมาเป็นชื่อ event เพราะปุ่มเดียวกันคนไทยเห็น "เข้าร่วมพื้นที่" คนอังกฤษเห็น "Join space" ถ้าใช้ text จะกลายเป็นคนละ event
- รายละเอียดปลีกย่อยให้ใส่เป็น **property** ไม่ใช่สร้างชื่อใหม่ เช่น `Mic Toggled` + `{enabled: false}` ดีกว่ามี `Mic Off` แยกอีกตัว

---

## 3 ชั้นของการเก็บ

### ชั้นที่ 1 — อัตโนมัติ (ไม่ต้องแก้โค้ดฟีเจอร์)

`<ClickTracker>` ดัก event ที่ `document` แบบ capture phase ครอบทั้งแอป จับได้แม้ component จะ `stopPropagation()`

| Event | เกิดเมื่อ | property |
|---|---|---|
| `UI Click` | กด `button`, `a`, `summary`, `[role=button\|link\|menuitem\|tab\|switch\|checkbox\|option]` | `label`, `tag`, `role`, `path` |
| `UI Toggle Changed` | checkbox/radio เปลี่ยน หรือปุ่ม toggle ที่มี `aria-pressed`/`aria-checked` | `label`, `enabled` |
| `UI Input Changed` | `<select>`, slider (`type=range`), เลือกไฟล์ | `label`, `value` หรือ `fileCount` |
| `UI Form Submitted` | form submit (**รวมกรณีกด Enter**) | `label` |

ปุ่ม toggle ในโปรเจกต์นี้เป็น `<button>` ธรรมดา (เพราะกฎห้ามใช้ component library) ค่าใหม่จึงอ่านจาก `aria-pressed`/`aria-checked` **หลัง React re-render 1 เฟรม** ไม่งั้นจะได้ค่าเก่า

### ชั้นที่ 2 — Semantic (แก้ที่ "คอขวด")

Action ที่มีความหมายทางธุรกิจ ดักที่จุดที่ทุกทางเดินมาบรรจบ — คุ้มกว่าไล่ใส่ทีละปุ่ม และครอบคลุม trigger ที่ DOM มองไม่เห็น (คีย์ลัด, เดินเข้าโซน)

| จุดที่ดัก | ครอบคลุม | event |
|---|---|---|
| `views/chat/components/message-input.tsx` → `doSend()` | ปุ่ม Send **และปุ่ม Enter** | `Message Sent` |
| `views/user/virtual-office/components/zone-enter-chat.tsx` → `handleSend()` | แชทในห้องประชุม (ปุ่ม + Enter) | `Message Sent` (`surface: meeting`) |
| `use-meeting-media.ts` → `applyMicToggle` / `applyCamToggle` | ปุ่ม HUD **และคีย์ `M` / `V`** | `Mic Toggled`, `Camera Toggled` |
| `lib/api/zone-sections.ts` → enter/leave | กดปุ่ม join **และเดินเข้า/ออกโซนเอง** | `Meeting Joined`, `Meeting Left` |
| `lib/api/workspace-ws.ts` → `_send()` | ทุก action ที่ส่งผ่าน WS | ดูตารางล่าง |
| `stores/{audio,notification,general}-settings-store.ts` → `setAndPersist()` | toggle ในหน้า Settings ~30 ตัว | `* Setting Changed` |

**WS mapping** (`lib/analytics/ws-events.ts`) — frame ไหนไม่อยู่ในตารางนี้ = ไม่เก็บ:

`status` → `Status Changed` · `wave` → `Wave Sent` · `follow` → `Follow Started`/`Follow Stopped` · `knock` → `Knock Sent` · `pet_follow` → `Object Interacted` · `ws:hand:changed` → `Hand Raised` · `ws:reaction:send` → `Reaction Sent` · `ws:spotlight:*` → `Spotlight Started`/`Stopped` · `ws:share:*` → `Screen Share Started`/`Stopped`

### ชั้นที่ 3 — `data-track-id` (ชื่อคงที่ ไม่ขึ้นกับภาษา)

ปุ่มสำคัญที่ยังไม่มี semantic event ให้ใส่ `data-track-id` เพื่อล็อกชื่อไว้:

```tsx
<button data-track-id="workspace-join" onClick={...}>{t("joinSpace")}</button>
```

`label` ของ event จะกลายเป็น `workspace-join` เหมือนกันทุกภาษา

---

## สิ่งที่ "ไม่" เก็บ (ตั้งใจ)

| ไม่เก็บ | เหตุผล |
|---|---|
| การเดิน (click-to-walk, WASD) และเดินไปนั่งเก้าอี้ | ตกลงกับทีมว่าไม่เก็บ + ที่ tick 20ms จะท่วม event อื่นหมด |
| ข้อความที่ผู้ใช้พิมพ์ (แชท, ช่องค้นหา, ชื่อ, สถานะ) | เป็นเนื้อหาของผู้ใช้ ไม่ใช่ metric — เก็บแค่ `length` ของข้อความ |
| ชื่อไฟล์ที่อัปโหลด | เก็บแค่ `fileCount` |
| user id ของ "คนอื่น" (เช่นโบกมือหาใคร) | นับจำนวนพอ ไม่ต้องรู้ว่าใครถูกโบก |
| คลิกบน backdrop โปร่งใส (ปิด modal/dropdown ด้วยการคลิกข้างนอก) | ไม่ใช่ปุ่มจริง เป็นแค่ affordance ปิดหน้าต่าง |

**ตัวกันหลุด PII มี 3 ชั้น** — regex ลบอีเมลออกจาก label, ไม่อ่านค่าจาก text input เลย, และใส่ `data-no-track` ที่ element หรือ ancestor ตัวไหนก็ได้เพื่อตัดออกทั้งก้อน

```tsx
<div data-no-track>{/* ทุกอย่างข้างในนี้ไม่ถูกเก็บ */}</div>
```

---

## Session Replay

เปิดทั้ง Sentry และ Mixpanel — ดูย้อนได้ว่าผู้ใช้คนไหนกดอะไรไปบ้าง

| | Sentry Replay | Mixpanel Replay |
|---|---|---|
| ตั้งค่าที่ | `instrumentation-client.ts` | `lib/analytics/mixpanel.ts` |
| จุดแข็ง | ผูกกับ error อัตโนมัติ — session ที่เจอ error เก็บ 100% เสมอ | กดจาก event `UI Click` ใน Mixpanel ไปดูคลิปตรงนั้นได้เลย |
| ใครกด | จาก `Sentry.setUser({id})` ใน `components/analytics-identity.tsx` | จาก `mixpanel.identify(userId)` |

**ทุก text ถูก mask หมด** (`maskAllText`, `record_mask_text_selector: "*"`) รูป/วิดีโอถูก block และ **ไม่อัด canvas ของแผนที่ VO** (ไฟล์จะใหญ่มากโดยไม่ได้อะไรเพิ่ม เพราะ event ของ HUD บอกอยู่แล้วว่ากดอะไร)

### ปรับสัดส่วนที่อัด

ค่าเริ่มต้นอัด **10%** ของ session เพราะ replay คิดเงินต่อ session ปรับผ่าน env เดียวคุมทั้งสองเครื่องมือ:

```
NEXT_PUBLIC_REPLAY_SAMPLE_PERCENT=100    # 0–100
```

ตั้งใน GitHub Environment (`dev` / `uat` / `production`) ของ repo `zyra-app` เพราะเป็น build-time env (`NEXT_PUBLIC_*` ถูก bake ตอน build — ดู [[06-release]])

---

## เพิ่ม event ใหม่

1. เพิ่มชื่อใน `AppEvent` (`lib/analytics/events.ts`) ตามกติกา `<สิ่งของ> <กริยาอดีต>`
2. หา **คอขวด** ให้เจอก่อนใส่ — จุดที่ทุก trigger (ปุ่ม / คีย์ลัด / อัตโนมัติ) วิ่งผ่าน แล้วเรียก `trackAppEvent()` ตรงนั้นจุดเดียว
3. ใส่ property ที่ทำให้ตอบคำถามได้จริง (`enabled`, `surface`, `kind`) — อย่าใส่ข้อความที่ผู้ใช้พิมพ์
4. เพิ่ม test ใน `__tests__/analytics-events.test.ts`

```ts
import { AppEvent, trackAppEvent } from "@/lib/analytics/events"

trackAppEvent(AppEvent.WorkspaceCreated, { template: "open-office" })
```

---

## วิธีตรวจว่าทำงานจริง

```js
// ใน DevTools console บนหน้าเว็บ — GTM
window.dataLayer.filter(e => e.event === "ui_click")

// Mixpanel init สำเร็จไหม (ต้องเจอ distinct_id + environment)
Object.keys(localStorage).find(k => k.startsWith("mp_") && k.includes("mixpanel"))
```

- **Mixpanel**: Events → กรอง `UI Click` → กางดู property `environment` ต้องตรงกับ env ที่ทดสอบ
- **Sentry**: เปิด Issue ไหนก็ได้ → แท็บ Breadcrumbs → ต้องเห็น `ui.click` เรียงตามลำดับที่กด
- **Network**: Sentry ยิงผ่าน tunnel `/monitoring` (เลี่ยง ad-blocker), Mixpanel ยิงไป `api-js.mixpanel.com/track/`
