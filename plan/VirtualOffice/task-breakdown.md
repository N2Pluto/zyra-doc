# [Module] Virtual Office — Task Breakdown

**Technical Design:** [technical-design.md](./technical-design.md) | **Spec:** [spec.md](./spec.md)  
**วันที่:** 2026-06-17

---

## สัญลักษณ์

| สัญลักษณ์ | ความหมาย |
|---|---|
| `[API]` | zyra-api (Go) |
| `[WS]` | zyra-ws (Go) |
| `[FE]` | zyra-app (Next.js) |
| `[DB]` | PostgreSQL migration |
| `[REDIS]` | Redis key design/integration |
| `→` | depends on |
| **S** | Small (~0.5 day) |
| **M** | Medium (~1 day) |
| **L** | Large (~2 days) |

---

## Phase 0 — Foundation (ทำก่อนทุกอย่าง)

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| F-01 | เพิ่ม column `capacity`, `transferred_to`, `transferred_at` ใน `tb_workspace` | `[DB]` | S | — |
| F-02 | เพิ่ม column `last_position_x`, `last_position_y`, `last_map_id` ใน `tb_workspace_member` | `[DB]` | S | — |
| F-03 | สร้าง `tb_private_zone_access_log` | `[DB]` | S | — |
| F-04 | สร้าง `tb_workspace_audit_log` | `[DB]` | S | — |
| F-05 | ออกแบบ Redis key schema + helper functions ใน `zyra-ws/internal/store/redis.go` | `[REDIS]` | M | — |
| F-06 | เพิ่ม message constants ทั้งหมดใน `zyra-ws/internal/hub/message.go` + payload structs | `[WS]` | M | — |
| F-07 | เพิ่ม field `Status`, `CustomMsg`, `RoomID`, `Direction` ใน `Player` struct | `[WS]` | S | F-06 |
| F-08 | ตั้งค่า Redis client ใน `zyra-ws/cmd/server/main.go` | `[WS]` | S | F-05 |

---

## Phase 1 — SC-VO-01 Workspace List

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO01-1 | Workspace list page `/workspace` — แสดง grid ของ workspace ที่ user เป็น member | `[FE]` | M | — |
| VO01-2 | แสดง online count badge ดึงจาก Redis presence key | `[API]` `[REDIS]` | M | F-05 |
| VO01-3 | "Enter" button → redirect to `/workspace/[id]` (loading page) | `[FE]` | S | VO01-1 |

---

## Phase 2 — SC-VO-02 Loading Page

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO02-1 | GET `/api/user/workspaces/:id` — เพิ่ม capacity check ก่อน allow join | `[API]` | S | F-01 |
| VO02-2 | Loading page `/workspace/[id]` — progress bar (connecting → map → members → done) | `[FE]` | M | — |
| VO02-3 | `useVirtualOfficeWS` hook — connect, receive `welcome`, dispatch to store | `[FE]` | M | F-06 |
| VO02-4 | `zyra-ws` Join handler — ดึง capacity จาก API/DB และ call `checkCapacity()` | `[WS]` | M | F-01, F-07 |
| VO02-5 | ถ้า office เต็ม → ส่ง `capacity_reached` แล้ว close; FE แสดง modal + redirect | `[WS]` `[FE]` | S | VO02-4 |
| VO02-6 | `welcome` payload ต้องรวม player list พร้อม status ของทุกคนใน office | `[WS]` | M | F-07 |

---

## Phase 3 — SC-VO-03 Render Map

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO03-1 | Phaser scene `VirtualOfficeScene` skeleton — init layers จาก Tiled JSON | `[FE]` | L | — |
| VO03-2 | `CollisionSystem` — โหลด boolean grid จาก Tiled collision layer | `[FE]` | M | VO03-1 |
| VO03-3 | `ZoneDetectionSystem` — โหลด zone rectangles จาก Tiled objectgroup | `[FE]` | M | VO03-1 |
| VO03-4 | Render remote players จาก `welcome` payload เป็น sprite | `[FE]` | M | VO03-1, VO02-6 |
| VO03-5 | `InterpolationSystem` — lerp remote player positions | `[FE]` | M | VO03-4 |
| VO03-6 | `CameraSystem` — smooth follow local player | `[FE]` | S | VO03-1 |
| VO03-7 | Avatar label (display_name) overlay เหนือ sprite | `[FE]` | S | VO03-4 |
| VO03-8 | Status indicator dot บน avatar | `[FE]` | S | VO03-4 |

---

## Phase 4 — SC-VO-04 Avatar Movement

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO04-1 | WASD input handler → call `canMoveTo()` → send `move` WS message | `[FE]` | M | VO03-2 |
| VO04-2 | `PathfindingSystem` — A* implementation บน collision grid | `[FE]` | L | VO03-2 |
| VO04-3 | Click-to-move → A* path → queue move commands (50ms interval) | `[FE]` | M | VO04-2 |
| VO04-4 | Throttle WS move send 50ms | `[FE]` | S | VO04-1 |
| VO04-5 | Server-side move validation + `direction` field | `[WS]` | M | F-07 |
| VO04-6 | Broadcast `moved` with direction, update Redis presence tile | `[WS]` | M | VO04-5, F-05 |
| VO04-7 | Animation: walking cycle per direction, idle state | `[FE]` | M | VO04-1 |

---

## Phase 5 — SC-VO-05 Collision Detection

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO05-1 | Client-side collision guard ก่อน send move | `[FE]` | S | VO03-2, VO04-1 |
| VO05-2 | Server-side teleport detection (dx/dy > 3 tiles) → reject + send correction | `[WS]` | M | VO04-5 |
| VO05-3 | Visual feedback: bump animation เมื่อ move ถูก block | `[FE]` | S | VO05-1 |

---

## Phase 6 — SC-VO-06 Multiple Room

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO06-1 | Detect zone transition เมื่อ player tile เปลี่ยน — compare ต่อ zone | `[FE]` | M | VO03-3, VO04-1 |
| VO06-2 | Send `room_enter` / `room_exit` WS message เมื่อ enter/leave zone | `[FE]` | S | VO06-1 |
| VO06-3 | WS handler สำหรับ `room_enter` / `room_exit` → update Redis `vo:room:{wsId}:{userId}` | `[WS]` | M | F-06, F-05 |
| VO06-4 | Broadcast `room_entered` / `room_exited` ให้ทุกคนใน office | `[WS]` | S | VO06-3 |
| VO06-5 | `RoomDisplayPanel` — top bar แสดงชื่อห้อง + จำนวนสมาชิกในห้อง | `[FE]` | M | VO06-1 |
| VO06-6 | Filter room member list ในหน้า member panel | `[FE]` | S | VO06-5 |

---

## Phase 7 — SC-VO-07 Private Zone Knock

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO07-1 | Private zone: invisible collision wall + hover card เมื่อเข้าใกล้ (<3 tiles) | `[FE]` | M | VO03-3 |
| VO07-2 | "Knock" button บน hover card → send `knock { zone_id }` | `[FE]` | S | VO07-1 |
| VO07-3 | WS handler สำหรับ `knock`: ตรวจ cooldown ใน Redis → generate request_id → ส่ง `knock_request` ให้ owner | `[WS]` | L | F-06, F-05 |
| VO07-4 | Knock cooldown logic: 1st=0s, 2nd=30s, 3rd=30s, 4th+=5min | `[WS]` | M | VO07-3 |
| VO07-5 | `KnockNotification` toast บน owner side: avatar + name + zone name + allow/deny buttons (30s timer) | `[FE]` | M | VO07-3 |
| VO07-6 | Send `knock_decision { allow: true }` | `[FE]` | S | VO07-5 |
| VO07-7 | WS handler สำหรับ `knock_decision { allow: true }` → set Redis `zone_granted` TTL 30s → ส่ง `knock_granted` | `[WS]` | M | VO07-3 |
| VO07-8 | Client receives `knock_granted` → แสดง overlay "กำลังเปิด..." → เปิด collision gate 30s | `[FE]` | M | VO07-7 |
| VO07-9 | Server validates zone access เมื่อ player move เข้า private zone tile | `[WS]` | M | VO07-7 |
| VO07-10 | บันทึก audit log ใน `tb_private_zone_access_log` | `[WS]` | S | VO07-3 |

---

## Phase 8 — SC-VO-08 Private Zone Denied

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO08-1 | Owner: เมื่อ timer 30s หมด โดยไม่ response → auto-deny | `[WS]` | S | VO07-3 |
| VO08-2 | Send `knock_decision { allow: false }` | `[FE]` | S | VO07-5 |
| VO08-3 | WS handler สำหรับ `knock_decision { allow: false }` → increment deny counter → ส่ง `knock_denied` | `[WS]` | M | VO07-4 |
| VO08-4 | Client receives `knock_denied` → แสดง toast + อัปเดต cooldown state | `[FE]` | S | VO08-3 |
| VO08-5 | Progressive cooldown ขยายตาม deny_count (30s → 5min) | `[WS]` | S | VO07-4 |
| VO08-6 | บันทึก deny log ใน `tb_private_zone_access_log` | `[WS]` | S | VO08-3 |

---

## Phase 9 — SC-VO-09 Availability Status

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO09-1 | `StatusPicker` component — popover 4 status + custom message input | `[FE]` | M | — |
| VO09-2 | Send `status { status, custom_msg }` WS message เมื่อเลือก | `[FE]` | S | VO09-1 |
| VO09-3 | WS handler สำหรับ `status` → update Redis presence hash → broadcast `status_changed` | `[WS]` | M | F-06, F-05 |
| VO09-4 | Client receives `status_changed` → update player dot + tooltip | `[FE]` | S | VO09-3 |
| VO09-5 | Store status ใน `tb_workspace_member.last_active` (optional: เพิ่ม `status` column) | `[API]` | S | — |
| VO09-6 | Heartbeat mechanism — client ส่ง `heartbeat` ทุก 20s → server renew Redis TTL | `[WS]` `[FE]` | M | F-05 |
| VO09-7 | TTL expiry handler — เมื่อ Redis key หมดอายุ → broadcast `left` | `[WS]` | M | VO09-6 |

---

## Phase 10 — SC-VO-10 Wave Notification

| ID | Task | Size | Depends |
|---|---|---|---|
| VO10-1 | Wave button บน avatar click popup | `[FE]` | S | VO03-4 |
| VO10-2 | Send `wave { target_user_id }` | `[FE]` | S | VO10-1 |
| VO10-3 | WS handler สำหรับ `wave` → ตรวจ cooldown Redis `vo:wave_cd` (10s) → ส่ง `wave_received` ให้ target | `[WS]` | M | F-06, F-05 |
| VO10-4 | `WaveNotification` toast — avatar + name + "is waving at you" | `[FE]` | S | VO10-3 |
| VO10-5 | Wave animation บน avatar ของ sender (2s) | `[FE]` | S | VO10-2 |
| VO10-6 | Wave back button บน toast → send `wave { target }` ทันที (bypass cooldown once) | `[FE]` | S | VO10-4 |

---

## Phase 11 — SC-VO-11 Follow Mode

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO11-1 | Follow button บน avatar click popup | `[FE]` | S | VO03-4 |
| VO11-2 | Send `follow { target_user_id }` | `[FE]` | S | VO11-1 |
| VO11-3 | WS handler สำหรับ `follow` → store ใน Redis `vo:follow` → ส่ง `follow_started` ให้ target | `[WS]` | M | F-06, F-05 |
| VO11-4 | `FollowNotificationToast` — target เห็น "X is following you" + Stop button | `[FE]` | S | VO11-3 |
| VO11-5 | Follow loop (client): ทุก 200ms ถ้า target tile เปลี่ยน → A* recalculate → send move | `[FE]` | M | VO04-2, VO11-2 |
| VO11-6 | `FollowBar` — bottom bar แสดงชื่อ target + Unfollow button | `[FE]` | S | VO11-5 |
| VO11-7 | Unfollow: send `follow { target_user_id: "" }` → WS delete Redis key → ส่ง `follow_ended` | `[WS]` `[FE]` | S | VO11-3 |
| VO11-8 | Auto-unfollow เมื่อ target `left` | `[WS]` `[FE]` | S | VO11-3 |

---

## Phase 12 — SC-VO-14 Member Panel

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| VO14-1 | `MemberPanel` — sidebar right: avatar, name, status dot, online/offline indicator | `[FE]` | M | VO03-4 |
| VO14-2 | Real-time sync: update panel เมื่อ `joined`, `left`, `status_changed` | `[FE]` | S | VO14-1 |
| VO14-3 | Click member → camera pan ไปหา player + avatar popup | `[FE]` | S | VO14-1 |
| VO14-4 | Filter: "In this room" / "All" toggle | `[FE]` | S | VO14-1, VO06-5 |
| VO14-5 | GET `/api/admin/workspaces/:id/members` → load offline members (ที่ไม่ได้ online) ด้วย | `[API]` | S | — |

---

## Phase 13 — SC-SB-10 Invite Member (existing user)

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| SB10-1 | `POST /api/admin/workspaces/:id/invites` — batch invite, max 10 emails/request | `[API]` | M | — |
| SB10-2 | `GET /api/admin/workspaces/:id/invites` — list pending invites | `[API]` | S | — |
| SB10-3 | `DELETE /api/admin/workspaces/:id/invites/:invId` — cancel invite | `[API]` | S | — |
| SB10-4 | `POST /api/admin/workspaces/:id/invites/:invId/resend` — resend invite email | `[API]` | S | SB10-1 |
| SB10-5 | Email template สำหรับ invite (zyra-notifications) | `[API]` | M | — |
| SB10-6 | `InviteModal` component — email list input + role selector + invite button | `[FE]` | M | SB10-1 |
| SB10-7 | Pending invites table ใน member management page | `[FE]` | M | SB10-2, SB10-3 |
| SB10-8 | Accept invite: `POST /api/invite/:token/accept` | `[API]` | M | — |
| SB10-9 | Accept flow: user login → redirect with token → call accept → join workspace | `[FE]` | M | SB10-8 |

---

## Phase 14 — SC-SB-11 Invite New User

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| SB11-1 | `GET /api/invite/:token` — public endpoint, return workspace + inviter info | `[API]` | S | — |
| SB11-2 | Register page: ตรวจ `?invite_token` query param → store ใน sessionStorage | `[FE]` | S | — |
| SB11-3 | หลัง OTP verify สำเร็จ → ถ้ามี token → call `POST /api/invite/:token/accept` | `[FE]` | M | SB11-1, SB10-8 |
| SB11-4 | Redirect ไป workspace หลัง accept | `[FE]` | S | SB11-3 |
| SB11-5 | Invite landing page `/invite/:token` — แสดงข้อมูล workspace + "Join" button | `[FE]` | M | SB11-1 |

---

## Phase 15 — SC-PROFILE-06 Leave Workspace

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| P06-1 | `DELETE /api/user/workspaces/:id/membership` — ต้อง confirm name match | `[API]` | M | F-04 |
| P06-2 | Guard: owner ไม่สามารถ leave โดยไม่ transfer ownership ก่อน | `[API]` | S | P06-1 |
| P06-3 | Audit log เมื่อ leave | `[API]` | S | P06-1, F-04 |
| P06-4 | Leave workspace UI ใน `/profile` → workspace tab → "Leave" button + confirm modal | `[FE]` | M | P06-1 |
| P06-5 | หลัง leave → redirect to `/workspace` + remove workspace จาก list | `[FE]` | S | P06-4 |

---

## Phase 16 — SC-PROFILE-07 Transfer Ownership

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| P07-1 | `POST /api/admin/workspaces/:id/transfer` — ตรวจ target เป็น active admin ใน workspace | `[API]` | M | F-01 |
| P07-2 | Update `tb_workspace.owner_id`, บันทึก audit log | `[API]` | S | P07-1, F-04 |
| P07-3 | Previous owner role เปลี่ยนเป็น admin (ไม่ถูก kick) | `[API]` | S | P07-1 |
| P07-4 | Transfer ownership modal — dropdown admin list + confirm | `[FE]` | M | P07-1 |
| P07-5 | Admin list ต้องกรอง เฉพาะ active admin (online ใน office หรือ member ที่ active ล่าสุด) | `[API]` | S | P07-1 |

---

## Phase 17 — Last Position Save

| ID | Task | Type | Size | Depends |
|---|---|---|---|---|
| LP-1 | `POST /api/user/workspaces/:id/presence` — บันทึก last_position เมื่อออก office | `[API]` | S | F-02 |
| LP-2 | FE: call API เมื่อ `beforeunload` / unmount | `[FE]` | S | LP-1 |
| LP-3 | WS: เมื่อ client disconnect → บันทึก last position จาก Redis ไป DB ผ่าน API call หรือ shared DB | `[WS]` | M | F-02, F-05 |
| LP-4 | Spawn at `last_position` เมื่อ join ครั้งต่อไป | `[WS]` | S | LP-3 |

---

## Dependency Graph (ระดับ Phase)

```
Phase 0 (Foundation)
    ↓
Phase 2 (Loading) ←→ Phase 3 (Map Render)
    ↓                      ↓
Phase 1 (List)       Phase 4 (Movement)
                           ↓
                     Phase 5 (Collision)
                           ↓
              ┌────────────┼────────────┐
           Phase 6      Phase 9      Phase 10
           (Rooms)      (Status)     (Wave)
              ↓
    ┌─────────┴─────────┐
 Phase 7              Phase 11
 (Knock)              (Follow)
    ↓
 Phase 8
 (Denied)
```

Parallel tracks (ไม่ block กัน):
- Phase 12 (Member Panel) → parallel กับ Phase 6+
- Phase 13/14 (Invite) → parallel กับ Phase 7+
- Phase 15/16 (Leave/Transfer) → parallel กับ Phase 9+
- Phase 17 (Last Position) → parallel กับ Phase 4+

---

## Effort Summary

| Phase | Scope | Total |
|---|---|---|
| Phase 0 — Foundation | DB + Redis + WS constants | ~3d |
| Phase 1 — Workspace List | FE + API | ~1.5d |
| Phase 2 — Loading Page | FE + WS | ~2d |
| Phase 3 — Map Render | FE (Phaser) | ~3d |
| Phase 4 — Avatar Movement | FE + WS | ~3d |
| Phase 5 — Collision | FE + WS | ~1d |
| Phase 6 — Multiple Room | FE + WS | ~2d |
| Phase 7 — Private Zone Knock | FE + WS | ~3d |
| Phase 8 — Private Zone Denied | FE + WS | ~1d |
| Phase 9 — Status | FE + WS | ~2d |
| Phase 10 — Wave | FE + WS | ~1.5d |
| Phase 11 — Follow | FE + WS | ~2d |
| Phase 12 — Member Panel | FE | ~1.5d |
| Phase 13 — Invite Member | FE + API | ~3d |
| Phase 14 — Invite New User | FE + API | ~2d |
| Phase 15 — Leave Workspace | FE + API | ~1.5d |
| Phase 16 — Transfer Ownership | FE + API | ~2d |
| Phase 17 — Last Position | FE + WS + API | ~1.5d |
| **รวม** | | **~35–40d** |

---

## MVP Subset (ถ้าต้องการ ship เร็ว)

MVP = SC ที่ "In Progress" + WS + basic movement  
ตัด: Phase 11 (Follow), Phase 13-14 (Invite), Phase 7-8 (Private Zone) ออกก่อน

| Phase | MVP? |
|---|---|
| 0 Foundation | ✅ |
| 1 List | ✅ |
| 2 Loading | ✅ |
| 3 Map Render | ✅ |
| 4 Movement | ✅ |
| 5 Collision | ✅ |
| 6 Rooms | ✅ |
| 7–8 Private Zone | ❌ defer |
| 9 Status | ✅ |
| 10 Wave | ✅ |
| 11 Follow | ❌ defer |
| 12 Member Panel | ✅ |
| 13–14 Invite | ❌ defer |
| 15–16 Leave/Transfer | ✅ |
| 17 Last Position | ✅ |

MVP ≈ **~22d**
