# Spotlight — ต้องกด Play หลายครั้ง (มักเป็น 3 ครั้ง) บน prod ถึงจะเริ่ม broadcast

> **สถานะ:** แก้ในโค้ดแล้ว 2026-09-16 (รอบที่ 2 ด้านล่าง) — verify ถึงระดับ **unit/integration test เขียว + live-test บน dev บางส่วน** (happy path + stop ยืนยันจริง, edge case ที่เหลือยังไม่ได้ลอง) · **ยังไม่วัด before/after** · **repo:** zyra-app, zyra-ws
> **branch:** zyra-ws `fix/spotlight-start-tolerant-tile` (merged → develop) · zyra-app `fix/spotlight-start-confirmed-state` (merged → develop) · **PR:** zyra-ws [#66](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/66) **merged** (`0b6a42e`) · zyra-app [#399](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/399) **merged** (`bfe2a1b`) — ทั้งคู่ deploy เข้า dev แล้ว/กำลังรัน
> **ที่มา:** รายงานจากผู้ใช้ว่ากด Play บน spotlight tile บน prod ต้องกดประมาณ 3 ครั้งกว่าจะติด
> **สำคัญ:** ห้ามถือว่า fixed จนกว่าจะมี live-test บน dev/uat + ตาราง before/after ตาม [`.claude/rules/18-before-after-metrics.md`](../../.claude/rules/18-before-after-metrics.md)

## อาการที่รายงาน

กดปุ่ม **Play** (เริ่ม Spotlight broadcast) ขณะยืนบน spotlight tile บน production แล้วบางครั้งไม่ติดในครั้งแรก ต้องเดินออกจาก tile แล้วกลับเข้าไปกด Play ใหม่ ทำซ้ำจนกว่าจะติด (ผู้ใช้รายงานว่าประมาณ 3 ครั้ง) ปัญหาไม่ reproduce ง่ายบน local/dev เพราะ network latency ต่ำกว่ามาก

## Root cause — client ล็อกสถานะ "ส่งไปแล้ว" แบบ optimistic โดยไม่รอ ack จาก server

### 1) client ยิง `ws:spotlight:start` แล้วตั้ง `startedRef.current = true` ทันที ไม่รอ server ยืนยัน

`zyra-app/views/user/virtual-office/use-spotlight-broadcast.ts:329-343`

```ts
useEffect(() => {
  const action = deriveSpotlightSpeakerAction({
    onSpotlightTile,
    broadcastRequested,
    started: startedRef.current,
  })
  if (action === "start" && wsClient) {
    wsClient.spotlightStart(armedRef.current)
    startedRef.current = true   // ← ตั้งเป็น true ทันทีที่ยิง ไม่สนใจว่า server รับหรือปฏิเสธ
    armedRef.current = false
  } else if (action === "stop") {
    wsClient?.spotlightStop()
    startedRef.current = false
  }
}, [onSpotlightTile, broadcastRequested, wsClient])
```

`wsClient.spotlightStart()` / `spotlightStop()` เป็น fire-and-forget ธรรมดา (`_send`) — ไม่มี ack, ไม่มี retry:

`zyra-app/lib/api/workspace-ws.ts:967-973`
```ts
spotlightStart(notify: boolean) {
  this._send("ws:spotlight:start", { notify })
}
spotlightStop() {
  this._send("ws:spotlight:stop", {})
}
```

`zyra-app/lib/api/workspace-ws.ts:1056-1060`
```ts
private _send(type: string, payload: unknown) {
  if (this.ws?.readyState === WebSocket.OPEN) {
    this.ws.send(JSON.stringify({ type, payload }))
  }
}
```

ถ้า socket ไม่ `OPEN` ตอนนั้น (กำลัง reconnect ฯลฯ) message หายเงียบๆ — เทียบกับ `spotlightMeetingJoin` ที่ผ่านการแก้ไปแล้วรอบ 2026-09-09 (ดู [`plan/Spotlight/progress.md`](../plan/Spotlight/progress.md)) ให้ queue แล้ว flush ตอน `welcome` แต่ `ws:spotlight:start`/`stop` ไม่เคยถูกแก้แบบเดียวกัน

### 2) server ปฏิเสธ start ได้ถ้าตำแหน่ง tile ที่ server รู้ยังไม่ทันจริง — โอกาสสูงกว่ามากบน prod

`zyra-ws/internal/hub/spotlight.go:98-108`
```go
// Verify the sender is actually standing on a spotlight tile (against the
// zone geometry published by zyra-api) — previously pure client-trusted,
// per the package doc comment above.
if !r.getZoneSet().HasZoneType("spotlight", c.TileX, c.TileY) {
    r.sendError(c, "not on a spotlight tile")
    return
}
```

`c.TileX`/`c.TileY` เป็นตำแหน่งที่ server แม็พจาก movement stream แยกต่างหาก (V2 server-authoritative step ทุก 20ms tick — `zyra-ws/internal/hub/movement_v2.go`) ไม่ใช่ตำแหน่งที่ client เห็นบนจอ ถ้า movement message ล่าสุดยังมาไม่ถึง/ประมวลผลไม่ทันตอนกด Play (มี countdown 5 วิ ก่อนยิง start จริง แต่ยังไม่การันตีว่า movement sync ทัน) server จะ reject ด้วย `"not on a spotlight tile"` — บน prod ที่ network latency สูงกว่า local มาก โอกาส race นี้แพ้สูงกว่าเห็นได้ชัด

### 3) ไม่มี error handler ฝั่ง frontend รับ error นี้เลย — error หายเงียบ ไม่ rollback state

ค้นทั้ง `hero-virtual-office.tsx` พบ error listener 2 จุดเท่านั้น:

- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx:2663` — จับเฉพาะ `"wave cooldown active"` / `"wave target unavailable"` / `"wave target not in office"`
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx:7489` — จับเฉพาะ error ของ `spotlightMeetingJoin` ผ่าน `spotlightMeetingJoinErrorKey()` (`"spotlight has ended"`, `"not in this meeting"`, `"meeting geometry unavailable"`, `"not a meeting zone"`/`"invalid meeting room"`)

**ไม่มีจุดไหนฟัง `"not on a spotlight tile"` หรือ error อื่นของ `handleSpotlightStart` เลย** — เมื่อ server ปฏิเสธ ผู้ใช้ไม่เห็น toast อะไรทั้งสิ้น และ `startedRef.current` (จากข้อ 1) ก็ไม่ถูก rollback กลับเป็น `false`

### 4) เพราะ state ค้างว่า "started" การกด Play ซ้ำในที tile entry เดิม "ไม่ resend" จริง

หลัง `startedRef.current = true` (ผิดๆ) `deriveSpotlightSpeakerAction` จะไม่คืนค่า `"start"` อีกตราบใดที่ `started` อ่านว่า true — ปุ่ม Play ยังกลับมากดได้ (เพราะ `spotlight.broadcasting` มาจาก speaker list ของ server ซึ่งไม่มีเราอยู่จริง) แต่พอกด Play ใหม่แล้ว countdown ครบ 5 วิ, `requestedSpotlightZoneId` (`hero-virtual-office.tsx:7096-7107` `beginSpotlightCountdown`) จะถูก set เป็นค่า**เดิมที่ไม่เปลี่ยน** (zone id เดียวกัน) → React ไม่ re-render ค่า primitive ที่เท่าเดิม → effect ที่ dependency คือ `[onSpotlightTile, broadcastRequested, wsClient]` (ข้อ 1) **ไม่ re-run** → ไม่มีการยิง `ws:spotlight:start` ซ้ำอีกเลยตราบที่ยังยืนอยู่บน tile entry เดิม

วิธีเดียวที่ reset สถานะได้คือ **เดินออกจาก spotlight tile แล้วกลับเข้าไปใหม่** (`hero-virtual-office.tsx:7058-7068` reset `requestedSpotlightZoneId` เป็น `null` เมื่อ `activeSpotlightZoneId` เป็น null) ซึ่งพา `broadcastRequested` วนจาก false→true ใหม่ ทำให้ effect รันใหม่และยิง start ใหม่จริง — ผู้ใช้จึงต้อง "เดินออก-เดินเข้า-กด Play" ซ้ำหลายรอบ จนกว่า race ข้อ 2 จะพ้นช่วงพอดี ตรงกับอาการ "กดสามครั้งถึงจะติด"

## สรุป chain

```
1. เดินขึ้น spotlight tile → client แสดงปุ่ม Play (onSpotlightTile=true ฝั่ง client ทันที)
2. กด Play → countdown 5 วิ → broadcastRequested เปลี่ยนเป็น true
3. effect ยิง ws:spotlight:start + ตั้ง startedRef.current = true (optimistic, ไม่รอ ack)
4. [race] server ยังเห็น c.TileX/TileY ไม่ตรง spotlight tile (movement sync ตามไม่ทันบน prod)
   → sendError("not on a spotlight tile")
5. frontend ไม่มี handler ฟัง error นี้ → เงียบ ไม่ toast ไม่ rollback
6. startedRef.current ค้างเป็น true (ผิด) → ปุ่ม Play กดใหม่ได้แต่ effect ไม่ re-run
   (requestedSpotlightZoneId set เป็นค่าเดิม → ไม่เกิด re-render → ไม่ resend)
7. ผู้ใช้ต้องเดินออก-เข้า tile ใหม่เพื่อ reset state แล้วลองใหม่ ซ้ำจนกว่า race ข้อ 4 จะผ่าน
```

## แนวทางแก้ที่เสนอ (ยังไม่ implement)

1. **อย่าตั้ง `startedRef.current = true` แบบ optimistic** — รอ server ยืนยันจริงก่อน (เช่น เช็คว่า self อยู่ใน `ws:spotlight:stateUpdate.speakers` ที่ตอบกลับมา) แล้วค่อย mark started
2. **เพิ่ม error handler เฉพาะสำหรับ spotlight start** (คู่ขนานกับที่มีให้ `spotlightMeetingJoin` แล้วที่ `hero-virtual-office.tsx:7489`) ฟัง `"not on a spotlight tile"` และ error อื่นของ `handleSpotlightStart` → rollback `startedRef.current` เป็น false + toast แจ้งผู้ใช้ + (ถ้าเป็นไปได้) retry อัตโนมัติหลัง movement sync ทันแล้ว
3. พิจารณาให้ `ws:spotlight:start` มี pending-queue เหมือน `spotlightMeetingJoin` (`workspace-ws.ts` มี pattern นี้อยู่แล้ว) เผื่อ socket ไม่ `OPEN` ตอนกด

## ยัง verify ไม่ถึงระดับไหน

- วิเคราะห์จากการอ่านโค้ดเท่านั้น — **ยังไม่ได้ reproduce จริงบน local/dev/prod** และยังไม่มีวิธี confirm ว่า error message ที่ server ส่งจริงตอน incident คือ `"not on a spotlight tile"` (อาจมีสาเหตุอื่นร่วมด้วย เช่น socket ไม่ OPEN ชั่วคราวตามข้อ 1)
- ยังไม่มี Grafana/Loki query ยืนยันความถี่ของ error `"not on a spotlight tile"` บน prod — ควรดึง log ก่อนเริ่มแก้เพื่อยืนยันสมมติฐาน (ดู [`ops/`](../ops/) หรือ `mcp__grafana` — ตอน diagnose ครั้งนี้ Grafana MCP เชื่อมต่อไม่ได้ ต้องต่อใหม่ก่อนใช้)
- ยังไม่มี fix/PR ใดๆ — ห้ามถือว่า "fixed" จนกว่าจะมี live-test + before/after metric ตาม [`.claude/rules/18-before-after-metrics.md`](../../.claude/rules/18-before-after-metrics.md)

---

## รอบที่ 2 — 2026-09-16 · แก้ทั้งสองฝั่ง (ยังไม่ live-test)

ระหว่างออกแบบพบต้นเหตุเพิ่มอีก 2 ชิ้นที่รอบแรกยังไม่เห็น:

- **ปุ่ม Play โชว์/กดได้ก่อนตัวละครถึง** — `onSpotlightTile` มาจาก `activeZone` ← `settledTile` ซึ่ง (#56) กระโดดไปปลายทางตั้งแต่คลิก → countdown 5 วิ จบได้ทั้งที่ยังเดินไม่ถึง (ดู `hero-virtual-office.tsx` comment เหนือ `liveZoneId`: claim ตำแหน่งต่อ server ต้องใช้ live tile เสมอ)
- **ทำไมเป็นเฉพาะ prod** — `store.ZoneSet.HasZoneType` บน zone set `nil` คืน `true` (fail-open) → local ที่ไม่ได้ publish `vo:zones:<workspaceId>` ลง Redis ไม่เคยเห็นบั๊ก; prod publish แล้วจึงเช็คจริง
- **เปลือง SFU** — `spotlightRoomId` เปิด LiveKit publisher (connect + mic pre-warm) ตั้งแต่ *request* ไม่ใช่ตอน server *confirm* → ทุกครั้งที่ล้มเหลวเสีย 1 session + linger 8s (`MEDIA_LEAVE_GRACE_MS`)

### สิ่งที่แก้ — zyra-ws (`fix/spotlight-start-tolerant-tile`)

| ไฟล์ | เปลี่ยนอะไร |
|---|---|
| `internal/hub/room.go` | แยก body ของ `zoneClaimTileOK` เป็น `zoneClaimTileMatches(c, inZone)` (reconcile in-flight walk + ยอมรับ leg END tile) แล้วเพิ่ม `zoneTypeClaimTileOK(c, zoneType)` ที่ใช้ `HasZoneType` — nil zone set ยัง fail-open เหมือนเดิม |
| `internal/hub/spotlight.go` | `handleSpotlightStart` ใช้ `zoneTypeClaimTileOK(c, "spotlight")` แทน `HasZoneType(c.TileX, c.TileY)` ดิบ (จุดเดียวในโค้ดเบสที่ยังใช้ tile ดิบ) · เพิ่ม `slog.Warn("spotlight start rejected", …)` ไว้วัด before/after จาก Loki · ข้อความ error `"not on a spotlight tile"` **คงเดิม** (client match string นี้) |
| `internal/hub/zone_validation_test.go` | pin error string + 4 test ใหม่: mid-leg entry ผ่าน, leg ชี้ออกจาก tile ยัง reject, reconcile in-flight walk ที่หมดเวลาแล้วผ่าน, reconcile หยุดที่ tile ที่ blocked |

**ไม่ทำ:** ไม่ยอมรับปลายทาง `PendingGoto` ที่อยู่ไกล — tolerance แค่ leg ที่กำลังเดิน (trust เท่าที่ tick กำลังจะ commit อยู่แล้ว)

### สิ่งที่แก้ — zyra-app (`fix/spotlight-start-confirmed-state`)

| ไฟล์ | เปลี่ยนอะไร |
|---|---|
| `views/user/virtual-office/use-spotlight-broadcast.ts` | **ลบ** `startedRef` (optimistic) และ listener `welcome` re-assert · `confirmed = self ∈ speakers && !disconnected` (ตัด `disconnected` เพื่อไม่ทำ EC-04 resume พัง) · state `{attempts, pending, exhausted, lastError}` · `deriveSpotlightSpeakerAction({onSpotlightTile, broadcastRequested, arrived, confirmed, pending, attemptsLeft}) → start/stop/giveUp/null` · ack timeout 1500ms → resend · ฟัง `error` เฉพาะขณะ pending: `"not on a spotlight tile"` → retry หลัง 500ms, `disabled/no floor/invalid payload` → fail ทันที · budget 3 ส่ง → `onStartFailed(key)` · `welcome` bump `connectionEpoch` ให้ effect ลองใหม่หลัง socket กลับมา · `armedRef` เคลียร์ตอน confirm ไม่ใช่ตอนส่ง (retry หลัง reject ยังขอ notify=true — server dedupe เอง) · stop ส่งครั้งเดียวต่อ exit (`stopSentRef`) · export `starting` ให้ HUD |
| `lib/api/workspace-ws.ts` | `spotlightStart()/spotlightStop()` คืน `boolean` (false = socket ไม่ OPEN, ไม่ส่ง) — ไม่ queue เหมือน meetingJoin |
| `views/user/virtual-office/hero-virtual-office.tsx` | `spotlightArrived = liveZoneId === spotlightStageZoneId` · guard `handleSpotlightStart`/`beginSpotlightCountdown` ด้วย `spotlightArrived` + `spotlightStartInForce` · ย้าย `useSpotlightBroadcast` ขึ้นก่อน `useMeetingMedia` แล้ว `spotlightRoomId` ต้องมี `spotlight.broadcasting` (confirm) ด้วยถึงเปิด publisher · `onStartFailed` → reset `requestedSpotlightZoneId` + toast |
| `views/user/virtual-office/components/vo-hud.tsx` | prop `spotlightArrived` — ปุ่ม Play โชว์ตั้งแต่เข้าโซนแต่ **disabled + B shortcut เงียบ** จนกว่าจะถึงจริง; `spotlightStarting` รวม pending (กัน countdown ซ้อน); สถานะ "ยังไม่ถึง" ใช้ `text-[rgba(255,255,255,0.4)]` (ไม่มี Figma spec — ควร confirm กับ design) |
| `messages/en.json`, `messages/th.json` | `spotlightStartFailedTitle`, `spotlightStartNotOnTile`, `spotlightStartDisabled`, `spotlightStartFailed`, `spotlightStartTimedOut` |

### Test

| ไฟล์ | ครอบอะไร |
|---|---|
| `zyra-ws internal/hub/zone_validation_test.go` | 4 เคสใหม่ข้างบน + `go test ./internal/hub/` ผ่านทั้งหมด, `go vet`, `gofmt` สะอาด |
| `__tests__/spotlight-broadcast.test.ts` | `deriveSpotlightSpeakerAction` signature ใหม่ 9 เคส (ไม่ start ก่อน arrived, ไม่ซ้อน pending, giveUp, stop ตอน cancel ขณะ pending, ไม่ stop ระหว่าง exit grace) + `spotlightStartErrorKey` |
| `__tests__/use-spotlight-broadcast-hook.test.tsx` | mock ws เป็น handler registry: arrival gate, `starting`, retry หลัง reject (notify=true คงอยู่) → giveUp ครบ 3, fail ทันทีบน disabled, ignore error คนละ flow, ack timeout ×3 → timedOut, socket ปิดไม่นับ + ส่งหลัง welcome, re-assert notify=false หลัง speakers ว่าง, `disconnected:true` = ยังไม่ confirm, stop ครั้งเดียวตอน cancel, stop ตอน unmount |
| `__tests__/vo-hud-spotlight.test.tsx` | `spotlightArrived=false` → disabled + B ไม่ยิง, label ยังเป็น Start |
| `__tests__/workspace-ws-spotlight.test.ts` | `spotlightStart` คืน false ก่อน open / true หลัง open, ไม่ replay หลัง welcome |

รวม: 4 ไฟล์ / 86 tests ผ่าน · `npx tsc --noEmit` ไม่มี error ใหม่ (เหลือ error เดิม 7 ตัวใน `environment-weather-fx.test.ts`, `pet-creation-wizard.test.tsx`, `pixi-game-scene.test.ts` ที่มีบน develop อยู่แล้ว) · eslint เหลือ 1 warning เดิมใน hook (unused directive บรรทัด `setAudioMuted`) ที่มีบน develop เท่ากัน · prettier ผ่าน

บั๊กที่เจอระหว่างเขียน test แล้วแก้ก่อน commit: effect reset `[floorId]` รันตอน mount ทับ `pending` ที่ effect ส่ง start ตั้งไว้ใน flush เดียวกัน (กรณี `broadcastRequested=true` ตั้งแต่ mount) → ลบ effect นั้นทิ้ง (floor เปลี่ยน = request หลุดอยู่แล้ว)

### ยัง verify ไม่ถึงระดับไหน

**Live-test บน dev 2026-09-16 หลัง merge ทั้งสอง PR — ทำได้บางส่วน:**

- workspace `n2pluto` มี zone จริงชื่อ **"Spotlight 1"** (`zone_type: spotlight`, pixel `x:1376,y:768` → tile `(43,24)`) สร้างไว้ตอน 08:45 UTC วันเดียวกัน — ใช้ทดสอบได้จริง มี zone set publish แล้ว (ไม่ fail-open) ตรงเงื่อนไขที่ต้องการ
- **ยืนยันแล้วจริง (สังเกตตอนเข้า workspace):** happy path กด Play → ติด broadcast สำเร็จ (`"You're live to everyone in the workspace"`, ปุ่ม Stop broadcast โชว์, LiveKit connect เข้าห้อง `spotlight:820c3314-a25e-4f69-a776-24413eeae8a2` ตรงตาม `spotlight:<floorId>`) — ไม่มีอาการต้องกดหลายครั้ง · กด **Stop broadcast** → เจอ EC-03 confirm modal → confirm → จบ broadcast สำเร็จ ถูกต้อง
- **ทำไม่ได้ในรอบนี้ (ข้อจำกัดเครื่องมือ ไม่ใช่โค้ด):** ชุด checklist (a)-(e) เดิม (arrival-gate ระหว่างเดิน, forced reject → retry/toast, restart zyra-ws, stop-while-pending, cancel-during-countdown) ต้องเดินตัวละครไปยัง tile (43,24) อย่างแม่นยำซ้ำหลายรอบ — browser automation ใน session นี้เดิน click-to-walk ไม่เสถียร (double-click บน canvas ไม่ landed ตามพิกัดที่คำนวณจาก debug panel ได้แน่นอน, เจอ Browser pane สลับ hidden/visible ระหว่าง turn ทำให้ click หลุดเป็นพักๆ) ผู้ใช้ขอให้หยุดแล้วไปทดสอบต่อเอง — **cross-client viewer test ก็ยังไม่ได้ทำ** (ต้อง 2 account ที่ login พร้อมกัน)
- **before/after ยังไม่ได้วัด** — metric ที่วางไว้: อัตรา log `spotlight start rejected` (slog ใน PR 1) ต่อ `ws:spotlight:start` บน prod 24h ก่อน/หลัง; ตัวที่สอง participant-join ห้อง `spotlight:*` ที่ไม่มี speaker (ถ้า SFU metric มี) · Grafana MCP ต่อไม่ติดตอนทำงานรอบนี้
- สี disabled ของปุ่ม Play (ยังไม่ถึง tile) ไม่มี Figma spec — ใช้ `rgba(255,255,255,0.4)` ไปก่อน ต้อง confirm กับ design
