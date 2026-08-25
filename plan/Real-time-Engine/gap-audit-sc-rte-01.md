# Gap Audit — SC-RTE-01 · Avatar Position Sync

> [Spec](spec.md#sc-rte-01--avatar-position-sync--ทุก-module) · [Design](technical-design/01-avatar-position-sync.md) · ClickUp [86d2wetb9](https://app.clickup.com/t/86d2wetb9)
> **วิธี:** อ่านโค้ดจริง `zyra-ws` + `zyra-app` + `zyra-api` (ไม่ใช่เดา) · **ข้อสรุป:** SC-RTE-01 สร้างไว้แล้ว ~90% — งานที่เหลือคือ verify + ตัดสิน 1 discrepancy + อุด 1 gap

---

## 1. ผลตรวจต่อ Acceptance Criteria

| # | Criteria | สถานะ | หลักฐาน (โค้ดจริง) |
|---|----------|:-----:|--------------------|
| 1 | 1 WS ต่อ user (ไม่ใช่ต่อ tab) | ✅ ทำแล้ว | `room.go:161–183` evict old client by userID; แยก same-tab (`ClientSessionID`) vs different-tab → `session_replaced` |
| 2 | Position latency < 100ms | ⚠️ **ยังไม่ verify** | mechanism มี: move ticker 20ms `room.go:836` + AOI `aoi.go` + binary frame `client.SendBin`. **ต้อง load test** |
| 3 | Interpolation smooth (ไม่กระตุก) | ✅ ทำแล้ว | path-based `handleMoveTo` `room.go:576` + `MovingPayload.ServerTimeMs` (`:693`) + snapshot ticker 3s `:860` + `sendNeighborSnapshot` `:519` |
| 4 | Status sync ทุก module | ✅ **ทำแล้ว (fixed)** | Map ✅ + Member Panel ✅ + DM ✅ (ดู §2 — DM มี presence อยู่แล้ว, แก้ mapping ให้ตรง canonical) |
| 5 | Offline avatar หายภายใน 5s | ✅ ทำแล้ว | clean close → `unregister`→`MsgLeft` `room.go:332` ทันที (silent disconnect ~60s ผ่าน pongWait) |
| 6 | 50 CCU ไม่ lag | ⚠️ **ยังไม่ verify** | AOI + latest-wins coalescing มีแล้ว. **ต้อง load test** |
| 7 | Heartbeat 30s detect silent disconnect | ✅ ทำแล้ว | WS ping 45s/pongWait 60s `client.go:16–19` + `handleHeartbeat` Redis TTL `room.go:1701` + client heartbeat 30s |
| 8 | Presence sync ระหว่าง multiple tabs | ❌ **ขัด architecture** | evict model — 1 connection/user (ดู §3) |

---

## 2. DM presence — ✅ แก้แล้ว (แก้ไขจากที่ audit รอบแรกสรุปผิด)

> **แก้ record:** audit รอบแรกสรุปผิดว่า "DM ไม่แสดง status" — ความจริง **DM มี presence dot อยู่แล้ว** (`dm-panel.tsx` + `chat-sidebar.tsx` อ่าน `onlineUserIds` สดจาก WS). ปัญหาจริงคือ **chat มี status mapping ของตัวเองที่เพี้ยน** — โดยเฉพาะ `dnd` แสดงเป็น dot เทา + label "Online" (bug privacy)

**Fix ที่ทำ (เชื่อม canonical mapping ตาม rule 09):**
- สร้าง `lib/presence-status.ts` — single source of truth (`MemberStatus`, `STATUS_DOT_COLOR`, `STATUS_LABEL`, `normalizeWsStatus`)
- `vo-member-constants.ts` re-export จาก lib (VO ไม่เปลี่ยน logic)
- `chat-avatar.tsx` / `chat-sidebar.tsx` / `dm-panel.tsx` เลิกใช้ `statusDotOf` copy ของตัวเอง → ใช้ canonical
- ผล: `dnd` → 🔴 แดง + "Do Not Disturb", `busy` → 🟠 ส้ม, `available` → 🟢 "Active", `away`/offline → ⚪️ "Offline" — ตรงกับ VO member panel ทั้งแอป
- verify: `tsc --noEmit` ✅ · eslint ✅

### (ต่อ) รายละเอียดเดิม — Status ไม่ถึง DM

**Status persistence + broadcast แข็งแรงแล้ว** (ดีกว่าที่ spec คาด):
- Client เปลี่ยน status → `handleStatusChange` (`hero-virtual-office.tsx:2289`) ยิง **3 ทาง**:
  - WS `setStatus` → `status_changed` broadcast (`workspace-ws.ts:625`)
  - REST `updateUserStatus` → **persist ลง DB** `tb_user.availability_status` (`profile_service.go:359`, `PATCH /me/status`)
  - Phaser `setPlayerStatus` → avatar บน map
- Restore ตอน join: อ่าน `availability_status` จาก profile (`hero:2186, 2196`) ✅
- Member Panel: consume ผ่าน `otherPlayers` (`vo-member-panel.tsx:415–431`, `normalizeWsStatus`) ✅

**Gap:** **DM / chat ไม่แสดง availability status สด** — chat views ใช้ `status` แค่กับ message state (`sending/failed`) และ member `confirm` filter เท่านั้น (`views/chat/components/*`) ไม่มีการ subscribe `status_changed` หรืออ่าน `availability_status` ของคู่สนทนา

- **Sidebar** (`vo-sidebar.tsx`): ไม่แสดง status เลย (เป็น nav icon) → **ไม่ใช่ gap** (spec เขียน sidebar แต่ UI จริงไม่มี status ตรงนั้น)
- **DM:** เป็น gap จริง **ถ้า** product ต้องการ presence dot ใน chat/DM. ถ้าไม่ต้องการ → แก้ spec

> **หมายเหตุ:** `status_changed` scope อยู่ที่ workspace room ใน zyra-ws — DM อยู่คนละ context จึงไม่ได้รับ event นี้. ถ้าต้อง sync DM ต้องมี presence channel ระดับ user (ข้าม workspace) — งานเพิ่ม ไม่ใช่แค่ wiring

---

## 3. Discrepancy #2 — Multi-tab (spec ขัดกับ architecture)

| | Spec เขียน | โค้ดจริง |
|---|-----------|----------|
| หลาย tab พร้อมกัน | "presence sync ระหว่าง multiple tabs" | **evict tab เก่า** → `session_replaced` (`room.go:161`) |
| Status หลาย tab | "priority DND>Busy>Away>Available" | **ไม่มี** — 1 connection/user, last-wins |

→ Architecture ปัจจุบัน = **1 tab active ต่อ user** (tab ใหม่เตะ tab เก่าออก). Multi-tab merge + priority **ใช้ไม่ได้โดย design**

**ตัวเลือก:**
- (ก) **คง evict model** — ทำงานแล้ว, เสถียร, UX ชัด (แนะนำ) → แก้ spec/design ให้ตรง
- (ข) เปลี่ยนเป็นรองรับหลาย tab พร้อมกัน + status priority merge → rework ใหญ่ (register, presence, status resolve)

---

## 4. สรุป — งานที่เหลือจริง (ไม่ใช่ build ใหม่)

| งาน | ประเภท | ความสำคัญ |
|-----|--------|-----------|
| Load test 50 CCU (verify criteria #2, #6: latency < 100ms, ไม่ lag) | verify | สูง — criterion ที่ยังไม่ยืนยัน |
| ตัดสิน multi-tab (evict vs concurrent) → แก้ spec/design | decision | สูง — กัน scope เพี้ยน |
| ตัดสิน: DM ต้องมี presence dot ไหม | decision | กลาง |
| ถ้าต้อง: เพิ่ม presence ระดับ user ให้ DM เห็น status | build | กลาง (งานเพิ่มจริง ไม่ใช่ wiring) |
| แก้ spec/design SC-RTE-01 mark ส่วนที่ done + ปรับ 50ms→path-based/20ms, heartbeat จริง | docs | ต่ำ |

**ไม่ต้องทำ (มีแล้ว):** WS-per-user, path interpolation, status broadcast + DB persist, member panel status, offline cleanup, heartbeat/liveness, snapshot resync

---

## 5. แนะนำลำดับถัดไป
1. **เคาะ multi-tab** (ก/ข) — บล็อกการปิด task
2. **เคาะ DM presence** — ต้องมี dot ไหม
3. **Load test 50 CCU** — verify latency/lag (ตัวชี้ขาดว่า SC-RTE-01 ปิดได้)
4. แก้ [spec](spec.md) + [design 01](technical-design/01-avatar-position-sync.md) ให้ตรงโค้ดจริง แล้ว mark criteria ที่ผ่าน
