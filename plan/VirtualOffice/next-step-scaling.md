# Virtual Office — Scaling & Gather Parity (Next Steps)

**เป้าหมาย:** รองรับผู้ใช้ ~100 คน/ห้องให้ลื่น แล้วต่อยอดสู่ระดับ Gather (movement + WebRTC spatial A/V)
**วันที่:** 2026-06-28

---

## สัญลักษณ์

| สัญลักษณ์ | ความหมาย |
|---|---|
| `[WS]` | zyra-ws (Go) |
| `[API]` | zyra-api (Go) |
| `[FE]` | zyra-app (Next.js) |
| `[DB]` | PostgreSQL / data |
| `[OPS]` | deployment / infra / testing |
| **S** | Small (~0.5 day) |
| **M** | Medium (~1 day) |
| **L** | Large (~2 days) |
| **XL** | Extra large (หลายวัน / infra) |

---

## ✅ ทำไปแล้ว (2026-06-28)

| ID | งาน | Type | ไฟล์ |
|---|---|---|---|
| D-01 | แก้ race condition presence — เครื่องนึงเห็น 2 คน อีกเครื่องเห็น 1 คน (เพิ่ม `lifecycleMu` ครอบ register/unregister ให้ join/leave atomic) | `[WS]` | `zyra-ws/internal/hub/room.go` |
| D-02 | ยก capacity fallback `50 → 100` (ยัง override ด้วย env `DEFAULT_CAPACITY` ได้) | `[WS]` | `zyra-ws/internal/config/config.go` |
| D-03 | Client coalescing — buffer movement events (`moved`/`moving`/`stopped`) แล้ว flush เข้า React state ~10Hz (ลด re-render จาก ~100-200Hz) โดย engine ยัง render real-time ผ่าน direct call | `[FE]` | `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` |
| D-04 | HUD redesign: avatar เปิด profile panel, status dot, mic/cam toggle, leave → กลับหน้า workspace list | `[FE]` | `vo-hud.tsx`, `hero-virtual-office.tsx` |
| D-05 | Reconnecting overlay (จอเทาตอน WS reconnect) | `[FE]` | `hero-virtual-office.tsx` |

> **หลักการที่ยึด (Option A):** *ไม่แตะ* server broadcast `moving`/`stopped` → ยังเห็นทุกคนเดินทั้ง map / ซูมออกเห็นครบ คอขวดจริงที่ 100 คนคือ React re-render ฝั่ง client ไม่ใช่ network/render

---

## 🟡 Phase A.1 — ปิดงาน 100 คนให้สมบูรณ์ (ทำก่อน)

| ID | งาน | Type | Size | หมายเหตุ |
|---|---|---|---|---|
| A-01 | ตั้ง `tb_workspace.capacity` ของ workspace เป้าหมาย ≥ 100 | `[DB]` | S | **gate ตัวจริง** — ถ้าไม่ตั้ง คนที่ 51+ ยังโดน `capacity_reached` |
| A-02 | Restart `zyra-ws` ให้ capacity/`lifecycleMu` มีผล | `[OPS]` | S | — |
| A-03 | Load test จริง: หลายเครื่อง/หลาย tab เดินพร้อมกัน 50-100 คน — เช็ค (ก) เห็นกันครบ (ข) ลื่นตอนคนเยอะ (ค) ไม่มี phantom ตอน reconnect | `[OPS]` | M | ใช้ headless/bot client หรือเปิดหลาย tab |

---

## 🟠 Phase A.2 — ดัน 100→300 คน (ทำเมื่อเจอ bottleneck จริง)

| ID | งาน | Type | Size | ปัญหาที่แก้ |
|---|---|---|---|---|
| A-10 | ย้าย Redis lookup (`GetPendingKnocks`, `GetWorkspaceKnockRequests`, `GetFollow`) ออกนอก `lifecycleMu` — ให้ critical section เหลือแค่ snapshot→store→broadcast | `[WS]` | M | mass-join 100 คนพร้อมกัน lock ค้างข้าม Redis I/O → join ช้าเป็นวินาที |
| A-11 | เพิ่มขนาด `send`/`sendBin` buffer (256 → 512/1024) + ทบทวน backpressure ใน `Client.Send` | `[WS]` | S | client lag โดน force-disconnect ตอน broadcast burst |
| A-12 | จัดการ reconnect storm ตอน `Drain()`/restart (เพิ่ม jitter ฝั่ง client / stagger reconnect) | `[WS]` `[FE]` | M | 100 คนต่อใหม่พร้อมกันชน lock+Redis (ทำพร้อม A-10) |
| A-13 | ลด allocation ใน AOI `Subscribers` (reuse slice / sync.Pool) + ทบทวน move-ticker goroutine เดียว/room | `[WS]` | M | CPU/GC ที่ CCU สูง |
| A-14 | (optional) ทำ welcome payload เป็น delta/บีบอัด ถ้า join ก้อนใหญ่ช้า | `[WS]` `[FE]` | M | welcome เป็น O(N) ต่อคน |

---

## 🔴 Phase B — WebRTC Spatial Audio/Video (Gather parity)

> ปุ่ม mic/cam ใน HUD ตอนนี้เป็น **UI เปล่า** ยังไม่มี media pipeline
> **ของดี:** logic proximity มีครบแล้ว (`lib/chat-partner.ts` + zone-sections) → ใช้เป็น "subscription set" ของ media ได้เลย ไม่ต้องสร้างใหม่

| ID | งาน | Type | Size | หมายเหตุ |
|---|---|---|---|---|
| B-00 | **ตัดสินใจ: LiveKit Cloud vs self-host** | `[OPS]` | S | ตัดสินก่อนเริ่มทุกอย่าง |
| B-01 | ติดตั้ง/เชื่อม LiveKit SFU server | `[OPS]` | M | มี TURN/NAT ในตัว |
| B-02 | `zyra-api` ออก LiveKit access token ต่อ workspace/room (มี JWT infra อยู่แล้ว) | `[API]` | M | — |
| B-03 | Client เชื่อม LiveKit room = workspace, publish mic/cam จากปุ่ม HUD ที่ทำไว้ | `[FE]` | M | — |
| B-04 | **Subscription manager**: proximity group เปลี่ยน (`computeChatPartner`/zone) → (un)subscribe tracks + distance attenuation | `[FE]` | L | หัวใจของ spatial audio |
| B-05 | เชื่อม zone-sections: private zone = subscribe เฉพาะ member; meeting zone = subscribe ทั้งห้อง | `[FE]` | M | — |
| B-06 | Active-speaker + simulcast/SVC สำหรับ video หลายคนใน meeting zone | `[FE]` | M | bandwidth optimization |

---

## 🔵 Phase C — Scale พันคน / หลาย room (roadmap ยาว)

| ID | งาน | Type | Size | หมายเหตุ |
|---|---|---|---|---|
| C-01 | Tick-based state sync + binary delta (แทน per-event broadcast `moving`/`stopped`) | `[WS]` `[FE]` | XL | cap fan-out เป็น O(N)/tick |
| C-02 | WS horizontal scaling — room sharding + Redis pub/sub fan-out (ตอนนี้ room ผูก process เดียว) | `[WS]` | XL | — |
| C-03 | Sprite LOD ตอนซูมออก — วาดคนไกลเป็นจุด/sprite เล็ก batch เดียว | `[FE]` | M | PixiJS รองรับอยู่แล้ว |
| C-04 | Server-side interest management + LOD tiers (คนไกลส่งถี่น้อยลงจาก server) | `[WS]` | L | — |

---

## 🧹 เก็บกวาด / หนี้ทางเทคนิค

| ID | งาน | Type | Size |
|---|---|---|---|
| T-01 | กลับมาทำ PiP / tab-away widget ที่ disable ค้างไว้ (`VOGlobalWidget` return null) | `[FE]` | M |
| T-02 | แก้ lint warnings (z-index/border arbitrary values) ใน `hero-virtual-office.tsx` (~L3423, L3424, L3426, L3975) | `[FE]` | S |

---

## ลำดับที่แนะนำ

```
1. A-01 → A-02 → A-03   (ปิด 100 คนให้สมบูรณ์ + ยืนยันด้วย load test)
2. ถ้า join ช้าตอนคนเยอะ → A-10 + A-12
3. B-00 (ตัดสินใจ hosting) → Phase B (feature ที่ผู้ใช้รู้สึกได้ชัดสุด)
4. Phase C เมื่อต้องการเกิน ~300 คน หรือหลาย room scale
```
