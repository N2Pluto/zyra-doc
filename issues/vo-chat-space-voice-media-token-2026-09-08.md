# VO Chat Space + Spotlight — เสียงใช้งานไม่ได้ ("Voice unavailable") เพราะ media-token 500

> **สถานะ:** แก้แล้วในโค้ด (2026-09-08) — ยังไม่ deploy, ยังไม่ได้วัด after
> รายงานโดย: ten_dev@hpktechnology.com (พบบน dev, กระทบ dev/uat/prod ทั้งหมด)
> ขอบเขต: `zyra-api` (media token authz) + `zyra-ws` (chat-session snapshot TTL)
> PR: zyra-api `fix/media-token-non-zone-rooms` · zyra-ws `fix/chat-session-snapshot-ttl`

---

## อาการ

อยู่ใน chat space (pop/circle) กับอีกคน — คุยกันไม่ได้ ไมค์เป็นรูปขีดทับทั้งสองฝั่ง
และขึ้น toast **"Voice unavailable / Lost connection to the meeting media server."**

toast นี้มาจาก `use-meeting-media.ts` → `scheduleReconnect()` หลัง rejoin ล้มเหลว 3 ครั้ง
(backoff 1s/3s/6s) — ไม่ใช่ปัญหาเน็ต/TURN/SFU อย่างที่เคยเจอใน
[[vo-media-connect-fail-no-turn]] รอบนี้ **ไม่มีการต่อ LiveKit เกิดขึ้นเลย** เพราะขอ token ไม่ผ่าน

## Root cause

`POST /api/user/workspaces/:id/rooms/:roomId/media-token` ตรวจสิทธิ์ด้วย
`ZoneInWorkspace(roomID, workspaceID)` — คือ **สมมติว่า roomId เป็น zone id เสมอ**

แต่ media plane ใช้ชื่อห้อง 3 แบบ:

| roomId | ที่มา (zyra-app) | เป็น zone ไหม |
|---|---|---|
| `<uuid>` | `activeZone.id` — meeting / room / private zone | ✅ |
| `spotlight:<mapId>` | `use-spotlight-broadcast.ts` | ❌ |
| `cs_<hex>` | chat space session id จาก zyra-ws (`chat_space_state`) | ❌ |

สองแบบหลังไม่มีใน `tb_map_zone` และ **ไม่ใช่ UUID** ด้วย → `WHERE z.id = 'cs_18d3…'`
ชน `tb_map_zone.id UUID` → Postgres ตอบ `invalid input syntax for type uuid (SQLSTATE 22P02)`
→ handler คืน **500 "failed to verify room"** → client retry 3 ครั้งแล้วขึ้น toast

การตรวจนี้ถูกเพิ่มใน `c195ba1 fix(api): patch auth/IDOR/image-decode security-audit findings`
(2026-08-31, ข้อ **H3** — กัน IDOR ที่ member คนไหนก็ mint token เข้าห้องประชุมของ workspace อื่นได้)
commit อยู่ใน `develop` และใน tag `v1.2.2` / `v1.3.0` → **prod โดนด้วย ตั้งแต่ v1.2.2**

## Before/After

| Metric | Before | After | Δ |
|---|---|---|---|
| media-token requests สำหรับห้อง `cs_*` / `spotlight:*` ที่สำเร็จ (prod, 24h) | **0 จาก 243** (100% เป็น 500) | ยังไม่ได้วัด | — |
| เดียวกัน (uat, 24h) | **0 จาก 97** | ยังไม่ได้วัด | — |
| เดียวกัน (dev, 24h) | **0 จาก 26** | ยังไม่ได้วัด | — |
| สัดส่วน media-token ที่ error ทั้ง endpoint (prod, 24h) | 243/1091 = **22.3%** (200: 821, 401: 27) | ยังไม่ได้วัด | — |
| media-token ห้องที่เป็น zone id (meeting/private) | 200 ปกติ — ไม่กระทบ | ไม่เปลี่ยน | — |

**วัดยังไง**: LogQL บน Loki datasource `loki`
```logql
sum by (env, status) (count_over_time(
  {namespace=~"dev|uat|prod"} |= "media-token" |~ "cs_|spotlight:"
  | pattern `[GIN] <_> - <_> | <status> |<_>| <_> | POST     "<_>"` [24h]))
```
(ตัด `|~ "cs_|spotlight:"` ออก = ตัวเลขรวมทั้ง endpoint)

**ช่วงเวลาที่วัด**: before = 24h ย้อนหลังถึง 2026-09-08 ~10:25 UTC (ก่อนแก้, ยังไม่ deploy)
after = ต้องรัน query เดิมอีกครั้งหลัง Argo sync image ใหม่ **ยังไม่ได้ทำ**

**แหล่งข้อมูล**: Grafana → Loki, `{namespace=~"dev|uat|prod"} |= "media-token"`

## Fix

### zyra-api (`fix/media-token-non-zone-rooms`)

แยก authz ตามชนิดห้อง แทนที่จะ lookup zone ทุกกรณี (`classifyMediaRoom`):

- `<uuid>` → `ZoneInWorkspace` (เหมือนเดิม)
- `spotlight:<mapId>` → `MapInWorkspace(mapId, workspaceID)` (ฟังก์ชันใหม่) — floor ต้องอยู่ใน workspace นั้น
- `cs_<hex>` → `ChatSessionCache.UserInSession(...)` (ใหม่) — อ่าน snapshot `vo:chatspace:<wsID>`
  ที่ zyra-ws เขียนไว้ (`SaveChatSessions`) แล้วเช็คว่า **ผู้เรียกอยู่ใน session นั้นจริง**
  ไม่มี snapshot / ไม่มี session / ไม่ได้เป็นสมาชิก = 403 (ไม่ปล่อยผ่าน — ชื่อห้อง `cs_*`
  ไม่ผูกกับ workspace ใดๆ ด้วยตัวมันเอง ถ้าปล่อยผ่านจะเปิด IDOR ที่ H3 ปิดไปกลับมา)
  ถ้าไม่ได้ตั้ง `REDIS_URL` เลย → 503 + log error (ไม่ authorize แบบมั่ว)
- `ZoneInWorkspace` / `MapInWorkspace` เช็ค `isUUID()` ก่อน query → id ที่ไม่ใช่ uuid ตอบ
  403 ไม่ใช่ 500 อีก (defense in depth ของ 22P02 เดิม)

### zyra-ws (`fix/chat-session-snapshot-ttl`)

`vo:chatspace:<wsID>` มี TTL 35s (`presenceTTL`) และ `broadcastChatState` เขียนเฉพาะตอน
membership **เปลี่ยน** — วงที่นั่งคุยกันนิ่งๆ เกิน 35s snapshot จะหมดอายุ แล้ว zyra-api
จะปฏิเสธ token ตอน re-join (SFU restart / เปลี่ยน device / refresh)
→ เพิ่ม `refreshChatSessionSnapshot()` ใน `runSessionTicker` ทุก 10s (เขียนเฉพาะเมื่อมี session,
เขียนแบบ detached goroutine เหมือน relay publish เพื่อไม่ให้ Redis ช้าไปหยุด tick)

## Verify

- `go build ./...` + `go vet ./...` + `go test ./...` ผ่านทั้ง zyra-api และ zyra-ws
- Unit test ใหม่ (table-driven, testify): `classifyMediaRoom` (3 ชนิดห้อง + fallback),
  `userInSessionSnapshot` (สมาชิก/ไม่ใช่สมาชิก/ห้องไม่มีจริง/snapshot ว่าง/JSON เสีย), `isUUID`
- **ยังไม่ได้ live-test** — ต้อง deploy dev แล้วเข้าไป pop chat space 2 คนจริง แล้วเช็คว่า
  media-token ตอบ 200 และเสียงเข้าทั้งสองฝั่ง (+ ตรวจ spotlight tile ด้วย)

## เจอเพิ่มระหว่างไล่ (ยังไม่แก้)

`ERROR room pet handler path=/api/user/maps/:mapId/pets error="get zone: ERROR: invalid input
syntax for type uuid: \"temp_zone_1_1788861076537\" (SQLSTATE 22P02)"` — โผล่ซ้ำๆ บน **prod**
บักคนละตัว อาการเดียวกัน: client (workspace editor) ส่ง temp zone id ที่ยังไม่ commit ลง DB
ไปให้ endpoint วางเพ็ต แล้ว handler ยิง query ด้วย id ที่ไม่ใช่ uuid → 500
ควรกันที่ฝั่ง client (อย่าส่ง `temp_zone_*`) และ/หรือ validate ที่ handler
