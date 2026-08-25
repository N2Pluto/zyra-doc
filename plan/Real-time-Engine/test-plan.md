# Test Plan — Real-time Engine Module

> **Module:** [Real-time Engine](spec.md) · ClickUp [86d2weryr](https://app.clickup.com/t/86d2weryr)
> **Scope:** SC-RTE-01 → SC-RTE-09 (Avatar Position Sync, Room State, Mute/Camera, Screen Sharing)

---

## Coverage Targets

| Test Level | Target | Tooling | Scope |
|------------|--------|---------|-------|
| **Unit** | **≥ 80%** | Go `testify` (zyra-api) · Vitest (zyra-app) | business logic, state machines, throttle/backoff, pure functions |
| **Integration** | **≥ 70%** | Go `httptest` + WS test client · Vitest + mocked WS + mocked LiveKit client | handler ↔ service ↔ WS hub, event contracts, DB/Redis, token minting |
| **E2E** | **≥ 50%** | Playwright (multi-context/tab) + LiveKit (`zyra-sfu` local) | full user flow ผ่าน browser จริง + media plane |

> **SFU = LiveKit** (`zyra-sfu` :7880) — media plane. Unit/Integration: **mock LiveKit client + token** (ห้ามต่อ SFU จริง). E2E: รัน `zyra-sfu` local (`docker compose up`) + Chromium fake device
> Mock DB / Redis / LiveKit ด้วย interface — ห้าม connect ของจริงใน unit test
> ห้าม call `/api/*` หรือ WS จริงใน unit test — ใช้ `vi.mock`
> LiveKit token minting (zyra-api) มี unit test แยก: assert grants/identity/room ถูกต้อง (mock ด้วย fake key/secret)

---

## Test Matrix (Scenario → Level)

| Scenario | Unit | Integration | E2E |
|----------|:----:|:-----------:|:---:|
| SC-RTE-01 Avatar Position Sync | ✅ | ✅ | ✅ |
| SC-RTE-02 Reconnect / Desync Recovery | ✅ | ✅ | ✅ |
| SC-RTE-03 Room State Management | ✅ | ✅ | ✅ |
| SC-RTE-04 Room Member Join / Leave | ✅ | ✅ | ✅ |
| SC-RTE-05 Mute / Unmute Audio | ✅ | ✅ | ✅ |
| SC-RTE-06 Camera On / Off | ✅ | ✅ | ⚠️ (manual perm) |
| SC-RTE-07 Screen Share — Full Screen | ✅ | ✅ | ⚠️ (fake device) |
| SC-RTE-08 Screen Share — Window / Tab | ✅ | ✅ | ⚠️ (fake device) |
| SC-RTE-09 Screen Share — Viewer View | ✅ | ✅ | ✅ |

⚠️ = media-device dependent — ใช้ Chromium fake device flags (`--use-fake-ui-for-media-stream`, `--use-fake-device-for-media-stream`)

---

## SC-RTE-01 · Avatar Position Sync

### Unit (≥80%)
- `throttlePosition()` — ส่งไม่ถี่กว่า 50ms ขณะ moving; หยุดส่งเมื่อ idle
- `interpolatePosition()` — คำนวณ intermediate frame ราบรื่น (no jump)
- `resolveMultiTabStatus()` — priority DND > Busy > Away > Available
- `heartbeat` state machine — miss ping 3 ครั้ง → mark offline
- presence register/deregister mapping (user → workspace members)

### Integration (≥70%)
- Client connect WS → server broadcast `presence` ไปยัง members ทุกคน
- Position update event → fan-out ถึง member อื่นถูก throttle
- Status change → broadcast พร้อมกันทุก channel (DM/Sidebar/Map/Member Panel)
- App close → server broadcast `offline` ภายใน 5s
- Redis Pub/Sub fan-out ข้าม node (horizontal scale) — 2 hub instances
- Same user 2 tabs → 1 WS connection ต่อ user (ไม่ใช่ต่อ tab)

### E2E (≥50%)
- 2 browser contexts: A ขยับ avatar → B เห็น position เปลี่ยน latency < 100ms
- A ปิด tab → avatar หายจาก map ของ B ภายใน 5s
- Load test: 50 concurrent users ต่อ workspace ไม่ lag (assert p95 < 500ms)

---

## SC-RTE-02 · Reconnect / Desync Recovery

### Unit (≥80%)
- `backoff()` sequence — 1s, 2s, 4s, 8s, 16s, 30s (cap), หยุดที่ 5 ครั้ง
- message queue — enqueue สูงสุด 10, เกินนั้น drop oldest (FIFO)
- `mergeSnapshot()` — server state ชนะ local เสมอ
- reconnect indicator state — non-blocking (ไม่ freeze game loop)
- ws_token validity check — อายุ 24h

### Integration (≥70%)
- WS drop → reconnect ด้วย `ws_token` เดิม → rejoin room เดิม (ภายใน grace 2 นาที)
- Server ส่ง full state (positions, room states, presence) หลัง reconnect
- Queued messages ถูก flush ตามลำดับหลัง reconnect
- Mute/Camera state คงเดิมหลัง reconnect (ไม่ reset)
- เกิน grace period 2 นาที → server clear session → client ได้ signal redirect
- Multi-tab: tab อื่น reconnect ก่อน → ใช้ session นั้นแทน

### E2E (≥50%)
- Kill network ของ A → indicator แสดงใน HUD ทันที, UI ยังใช้ได้
- Restore network → A rejoin ห้อง/session เดิม ไม่ผ่าน loading screen
- Avatar ของ A ยังอยู่บน map ของ B ตลอด grace period
- Retry ครบ 5 ครั้งไม่สำเร็จ → error banner + ปุ่ม "ลองใหม่" / "ออกจาก Office"

---

## SC-RTE-03 · Room State Management

### Unit (≥80%)
- `addMember()` / `removeMember()` — mutate `members[]` ถูกต้อง
- `has_active_share` toggle เมื่อเริ่ม/หยุด share
- reset room state → default เมื่อห้องว่าง
- member count derive จาก `members[]`

### Integration (≥70%)
- Enter room → `members[]` update + broadcast ทุกคนในห้อง + minimap
- Start share → `has_active_share = true` → indicator บน room label
- Leave room → `members[]` update + broadcast
- ห้องว่าง (คนสุดท้ายออก) → state reset default
- State update ผ่าน WS events เท่านั้น (assert ไม่มี REST mutation)

### E2E (≥50%)
- A เข้าห้อง → B เห็น member count + minimap อัปเดต real-time
- A share screen → screen share indicator แสดงบน room label ฝั่ง B

> **Out of scope (ขีดฆ่าใน spec):** Admin lock ห้อง / `is_locked` — ไม่ต้องเขียน test

---

## SC-RTE-04 · Room Member Join / Leave

### Unit (≥80%)
- join validation — reject เมื่อ lock หรือ capacity เต็ม
- overlap detection (avatar ↔ room zone)
- presenter-left → force `ws:share:stopped { reason: presenter_left }`

### Integration (≥70%)
- `ws:room:enter` → validate → เพิ่ม member → `ws:room:stateUpdate`
- `ws:room:leave` → ลบ member → broadcast
- Join ห้อง lock → reject + lock indicator
- Presenter leave → share หยุดทันที + แจ้งทุกคน
- SFU media room join/leave sync กับ WS room events
- Audio auto-join ตาม user preference
- คนสุดท้ายออก → reset room state

### E2E (≥50%)
- A เดินเข้า zone → join room → B เห็น A ใน member list ทันที
- A เดินออก → B เห็น A หายทันที
- A (presenter) ออก → screen share หยุด, B ได้ system message

---

## SC-RTE-05 · Mute / Unmute Audio

### Unit (≥80%)
- toggle mute state (client-side stop/resume audio track)
- shortcut `M` → toggle
- default mute ตาม user preference เมื่อ join
- force-mute rule — target ต้อง unmute เอง (member อื่น unmute แทนไม่ได้)
- `audio_active_count` = จำนวน user ที่ unmute

### Integration (≥70%)
- Mute → server track state → broadcast mute indicator ทุก member
- Unmute → indicator หาย + `audio_active_count` update
- Force mute → server ส่ง `ws:audio:forceMuted { by_user_id }` ให้ target
- Target ได้ toast "User name ได้ปิดไมค์ของคุณ"

### E2E (≥50%)
- A กด Mute → B เห็น mic-slash icon บน avatar/tile ของ A (< 200ms)
- A unmute + พูด → B เห็น speaking animation รอบ avatar A
- Member force-mute A → A ได้ toast, ต้องกด unmute เองถึงกลับมา

---

## SC-RTE-06 · Camera On / Off

### Unit (≥80%)
- toggle camera state (client-side stop/resume video track)
- shortcut `V` → toggle
- fallback render: avatar preview / initials เมื่อ camera off
- default camera-off ตาม user preference
- permission-denied → disable button + tooltip
- rule: admin force camera-off ไม่รองรับ (privacy)

### Integration (≥70%)
- Camera off → broadcast camera-off indicator ทุก member (< 500ms)
- Camera on → video track กลับ + feed แสดง
- permission request เกิดครั้งแรกที่ join ห้อง

### E2E (⚠️ fake device, ≥50% where feasible)
- A camera off → B เห็น camera-slash icon + avatar/initials แทน video
- A camera on → B เห็น video feed
- permission denied (deny fake UI) → ปุ่ม disable + tooltip

---

## SC-RTE-07 · Screen Share — Full Screen

### Unit (≥80%)
- single-presenter guard — reject share เมื่อห้องมี active share
- layout switch logic → featured (share tile กลาง + video tiles ข้าง)
- stop-share sources — HUD button และ browser native stop → state เดียวกัน
- screen track แยกจาก camera track (2 tracks พร้อมกันได้)

### Integration (≥70%)
- Share → server validate ห้องไม่มี active share → `has_active_share = true`
- Screen track เข้า SFU session → forward ให้ member ทุกคน
- Stop → `has_active_share = false` → layout กลับ default grid < 1s
- Presenter leave/tab close → server ตรวจจับ disconnect → force stop + system message
- คน share อยู่แล้ว → user ที่สองได้ "[ชื่อ] กำลัง share อยู่ กรุณารอ"

### E2E (⚠️ fake device, ≥50%)
- A share entire screen → B เห็น featured layout + share tile
- A กด Stop (HUD) → layout ทุกคนกลับ grid < 1s
- Browser permission denied → error toast พร้อมวิธีแก้
- assert target resolution/fps hint (1920×1080 @ 15fps) ผ่าน track settings

---

## SC-RTE-08 · Screen Share — Window / Tab

### Unit (≥80%)
- source-type mapping (Entire Screen / Window / Tab)
- frame-rate config — Window 15fps, Tab 30fps
- tab-audio flag สำหรับ Tab share

### Integration (≥70%)
- Window share → forward เฉพาะ window ที่เลือก (ไม่รั่ว source อื่น)
- Tab share → รวม tab audio track เข้า session
- ทุกคนเห็น window/tab share tile (featured)

### E2E (⚠️ fake device, ≥50%)
- native picker แสดง 3 tab (assert browser จัดการเอง — ไม่มี custom UI)
- เลือก Window → B เห็น share tile
- Stop จาก HUD หรือ browser banner → หยุดทั้งคู่

---

## SC-RTE-09 · Screen Share — Viewer View

### Unit (≥80%)
- auto layout switch เมื่อเข้าห้องที่มี active share
- 2-presenter → split-screen layout (แบ่งครึ่งจอ)
- max concurrent share = 2 users (reject คนที่ 3)
- zoom clamp — max 2x
- presenter-name overlay (มุมซ้ายบน)

### Integration (≥70%)
- Viewer เข้าห้อง active share → SFU auto-subscribe screen stream + audio
- Presenter stop → viewer layout กลับ default grid อัตโนมัติ
- Simulcast: SFU เลือก quality ตาม viewer bandwidth
- 2 presenters พร้อมกัน → ทั้งคู่ได้รับ split layout event

### E2E (≥50%)
- B เดินเข้าห้องที่ A กำลัง share → B เห็น featured layout + ชื่อ A + audio
- B zoom in share tile ได้ (สูงสุด 2x)
- 2 คน share พร้อมกัน → viewer เห็นแบ่งครึ่งจอ
- Latency presenter→viewer < 500ms (assert timestamp diff)

---

## Edge Cases

> เคสขอบที่ต้องมี test ครอบ นอกเหนือจาก happy/alternate path — จัดกลุ่มตาม feature + cross-cutting

### SC-RTE-01 · Avatar Position Sync
- ส่ง position เร็วกว่า 50ms (spam) → server ต้อง throttle/drop ไม่ fan-out ทุก packet
- Position ออกนอก map bounds / พิกัดติดลบ → clamp หรือ reject
- Status เปลี่ยนถี่มาก (flapping DND↔Available) → debounce, ไม่ broadcast ทุก tick
- User เดียว 3+ tabs พร้อมกัน แล้วปิดทีละ tab → presence ยัง online จนกว่า tab สุดท้ายปิด
- Clock skew ระหว่าง client → server (interpolation ต้องใช้ server timestamp)
- Member เข้า workspace ระหว่างที่คนอื่นกำลังเคลื่อนที่ → ได้ snapshot ตำแหน่งล่าสุดทันที
- เกิน 50 concurrent users (เช่น 51–100) → graceful degrade ไม่ crash

### SC-RTE-02 · Reconnect / Desync
- Network flapping (หลุด-ต่อ-หลุด ถี่ ๆ) → backoff reset ถูกต้อง ไม่ค้าง timer ซ้อน
- Reconnect สำเร็จ "พอดี" นาทีที่ 2 (boundary ของ grace period)
- `ws_token` หมดอายุ 24h ระหว่าง disconnect → บังคับ full re-auth ไม่ใช่ rejoin
- Message queue เต็ม 10 พอดี แล้วมี message ที่ 11 → drop oldest, ลำดับที่เหลือถูกต้อง
- Reconnect แล้ว server state ขัดกับ local (ตำแหน่ง/room ต่างกัน) → server ชนะเสมอ
- Server restart ระหว่าง user หลาย ๆ คน disconnect พร้อมกัน (thundering herd) → backoff กระจาย
- Tab A reconnect สำเร็จ ขณะ Tab B ยัง retry → B ใช้ session ของ A ไม่สร้างซ้อน
- WS reconnect สำเร็จ แต่ SFU reconnect ยังไม่เสร็จ (parallel, คนละ timing)

### SC-RTE-03 / SC-RTE-04 · Room State & Join/Leave
- Enter + Leave zone แทบพร้อมกัน (เดินผ่าน zone เร็ว) → ไม่ค้างใน `members[]`
- 2 users เข้า/ออกห้องเดียวกันพร้อมกัน (concurrent mutate `members[]`) → ไม่มี race, count ถูก
- Join ห้อง capacity เต็มพอดี (คนที่ N+1) → reject + indicator
- คนสุดท้ายออกพร้อมมี active share ค้าง → stop share + reset state พร้อมกัน
- Enter event มาถึงก่อน presence register เสร็จ (out-of-order) → buffer/retry
- Duplicate `ws:room:enter` event เดิมซ้ำ → idempotent ไม่เพิ่ม member ซ้ำ
- User disconnect ทันทีหลังเข้าห้อง (ไม่ส่ง leave) → server cleanup member ผ่าน disconnect

### SC-RTE-05 · Mute / Unmute
- กด `M` รัว ๆ (double-toggle เร็วกว่า 200ms) → state สุดท้ายถูกต้อง ไม่ค้าง
- Force mute ขณะ target กำลังพูด → track หยุดทันที, speaking animation หาย
- Force mute 2 คนสั่ง target เดียวกันเกือบพร้อมกัน → ไม่ conflict
- Target ที่ถูก force mute reconnect → ยังคง mute state (ไม่ auto-unmute)
- Unmute แต่ไม่มี mic device / device ถูกถอด → error handling + ปุ่มสะท้อนสถานะ
- `audio_active_count` เมื่อทุกคน mute หมด = 0 (ไม่ติดลบ)

### SC-RTE-06 · Camera On / Off
- Camera on แต่ device ถูกใช้โดย app อื่น (device busy / NotReadableError) → error toast
- Permission เคย deny แล้ว → ปุ่ม disable ตั้งแต่ต้น ไม่ prompt ซ้ำ
- Toggle camera ถี่กว่า 500ms → track cleanup ไม่ leak (assert ไม่มี ghost track)
- Camera on ขณะกำลัง screen share → 2 tracks แยกกัน ไม่ชนกัน
- ไม่มี camera device เลย → ปุ่ม disable + tooltip

### SC-RTE-07 / SC-RTE-08 · Screen Share (Full / Window / Tab)
- 2 users กด Share พร้อมกันในห้องว่าง (race) → มีแค่ 1 คนได้ อีกคนได้ข้อความรอ
- Presenter ปิด tab กะทันหันขณะ share (ไม่กด stop) → server cleanup ผ่าน disconnect
- Presenter กด browser native stop (ไม่ใช่ HUD button) → state sync ตรงกัน
- Share Tab แล้วปิด tab ที่ share นั้นเอง → stream จบ + layout reset
- Share Window แล้ว minimize/close window นั้น → track ended → หยุด share
- Permission denied กลางคัน (revoke ระหว่าง share) → graceful stop
- Presenter ถูก disconnect (grace period) ขณะ share → share หยุดทันที ไม่รอ grace

### SC-RTE-09 · Viewer View
- Viewer เข้าห้อง "ระหว่าง" presenter เพิ่งกด stop (race) → layout ไม่ค้าง featured
- Presenter คนที่ 3 พยายาม share ขณะมี 2 active แล้ว → reject
- 1 ใน 2 presenter หยุด → เหลือ single featured (ไม่ค้าง split)
- Viewer bandwidth ต่ำมาก → simulcast ลง quality ต่ำสุด ไม่ drop connection
- Viewer เข้า/ออกห้อง active share รัว ๆ → subscribe/unsubscribe ไม่ leak stream
- Zoom เกิน 2x (spam zoom) → clamp ที่ 2x

### Cross-cutting (ทุก scenario)
- **Auth:** WS connect โดยไม่มี/มี expired token → reject 401 ไม่ crash hub
- **Malformed payload:** event ที่ field ขาด/ผิด type → validate + reject ไม่ panic (Go) / ไม่ throw uncaught (TS)
- **Ordering:** WS events มาถึงสลับลำดับ → state converge ถูกต้อง
- **Horizontal scale:** user คนละ hub instance (Redis Pub/Sub) → เห็น event ครบ
- **Idempotency:** ส่ง event เดิมซ้ำ (retry/dup) → ไม่เกิด side-effect ซ้อน
- **Cleanup on disconnect:** ทุก resource (member, share, presence, media track) ถูกเก็บกวาดเมื่อ WS ปิด
- **Backpressure:** slow consumer / client ค้าง → server ไม่ block คนอื่น (drop หรือ buffer cap)

## Definition of Done

- [ ] Unit coverage ≥ 80% (`internal/service/*`, `lib/*.ts`)
- [ ] Integration coverage ≥ 70% (WS handlers, event contracts)
- [ ] E2E coverage ≥ 50% (critical multi-user flows)
- [ ] `go test ./...` และ `vitest run` ผ่านทั้งหมด
- [ ] Playwright multi-context suite ผ่าน (2+ users)
- [ ] ไม่มี WS/SFU/DB จริงใน unit test — mock ทั้งหมด
- [ ] Happy path + error path ครบทุก scenario
