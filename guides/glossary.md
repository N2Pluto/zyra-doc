# ZYRA — Glossary (พจนานุกรมคำศัพท์)

> ไฟล์นี้เป็นแหล่งอ้างอิงเดียว (Single Source of Truth) สำหรับคำศัพท์ทุกคำที่ใช้ในโปรเจกต์ ZYRA
> ทั้ง AI และทีมงานต้องใช้คำเหล่านี้ในความหมายเดียวกัน

---

## 1. ชื่อ Product & Module

| คำ (ใช้ใน doc/code) | ห้ามใช้ | ความหมาย |
|---|---|---|
| **Zyra** | ZyRA, ZYRA (ยกเว้นใน constant) | ชื่อผลิตภัณฑ์ |
| **Virtual Office** | Virtual Office Room, VO | โมดูล 2D avatar-based map หลัก |
| **Space Builder** | Workspace List, Workspace Page | หน้า `/workspace` — แสดง list ของ workspace ทั้งหมด (ชื่อ UI จาก Figma) |
| **Space** / **Workspace** | Office, Room | ใช้แทนกันได้ — Workspace ใช้ใน backend/DB; Space ใช้ใน UI copy |

---

## 2. Entities หลัก

| Entity | คำย่อ / alias | ความหมาย |
|---|---|---|
| **Workspace** | Space | พื้นที่ทำงาน 1 ชุด มี map, member, capacity; เก็บใน `tb_workspace` |
| **Map** | — | แผนที่ 2D Tiled ภายใน Workspace หนึ่ง; เก็บใน `tb_map` |
| **Room** | Room Zone | พื้นที่ย่อยบน Map (polygon/rectangle จาก Tiled Rooms layer) มีได้สูงสุด 20 ห้องต่อ map |
| **Private Zone** | Private Area, Private Room | Room ที่ปิด — ต้อง Knock ก่อนเข้า; Tiled PrivateZones layer + `knock_required: true` |
| **Avatar** | Character, Sprite | ตัวละคร pixel-art ที่แทน user บน map |
| **Spawn Point** | — | จุดเกิดของ avatar เมื่อเข้า workspace ครั้งแรกหรือหลัง re-join |
| **Office Session** | — | session ของ user ที่กำลัง active บน map; เก็บใน Redis (ไม่ใช่ DB) |
| **Presence** | Online status | ข้อมูล user ที่ online บน map ณ ขณะนั้น (จาก WebSocket + Redis) |

---

## 3. User Roles & Permissions

| Role | badge สี | สิทธิ์ย่อ |
|---|---|---|
| **Owner** | orange/amber | สิทธิ์สูงสุด; invite ทุก role; ออก workspace ไม่ได้ (ต้อง Transfer Ownership ก่อน) |
| **Admin** / **Space Admin** | purple | invite ได้เฉพาะ Member; จัดการ member ได้ |
| **Member** | blue | ใช้งาน workspace ได้; ออกได้ตลอด |
| **Pending** | gray | ถูก invite แล้วแต่ยังไม่ยืนยัน; แสดงเป็น "รอยืนยัน" |

---

## 4. Map & Room Concepts

| คำ | ความหมาย |
|---|---|
| **Tiled** | map editor ที่ใช้ออกแบบ map; ส่งออกเป็น `map.json` |
| **Collision Layer** | layer บน Tiled สำหรับกำหนด tile ที่ avatar เดินผ่านไม่ได้ (boolean grid) |
| **Rooms Layer** | layer บน Tiled สำหรับกำหนด Room zone (polygon/rectangle) |
| **PrivateZones Layer** | layer บน Tiled สำหรับกำหนด Private Zone (`knock_required: true`) |
| **Floor Layer** | layer แสดงพื้น |
| **Wall Layer** | layer แสดงกำแพง |
| **Object Layer** | layer แสดง furniture/object |
| **Decoration Layer** | layer แสดงของตกแต่ง |
| **zIndex** | ลำดับการ render: `floor < objects < avatars < UI overlay` |
| **Barrier** | invisible collision tile ที่ขอบ Private Zone — ป้องกัน avatar เดินเข้าโดยไม่ได้รับอนุญาต |
| **Room Label** | ชื่อห้องที่แสดงเมื่อ avatar เดินเข้าใกล้ zone |
| **Room Entry Badge** | badge แสดงจำนวน member ใน room บนแผนที่ |
| **last_position** | ตำแหน่ง tile ล่าสุดที่ user อยู่; ใช้เป็น spawn point เมื่อ re-join |
| **default_spawn_point** | spawn point fallback เมื่อไม่มี `last_position` |

---

## 5. Avatar Movement & Engine

| คำ | ความหมาย |
|---|---|
| **WASD** | การเดินด้วยคีย์บอร์ด W/A/S/D |
| **Click-to-move** | การคลิกบน map เพื่อให้ avatar เดินไปยังจุดนั้น ใช้ A* pathfinding |
| **A\* Pathfinding** | อัลกอริทึมหาเส้นทางสำหรับ Click-to-move |
| **Smooth Interpolation** | การเคลื่อนที่ avatar แบบลื่นระหว่าง position update (WebSocket 50ms) |
| **Walk Speed** | ความเร็วเดินของ avatar (ค่า default 150 px/s) |
| **Idle Animation** | animation เมื่อ avatar หยุดนิ่ง 3 วินาที |
| **Position Broadcast Throttle** | ส่ง position ทาง WS ทุก 50ms ขณะเดิน |
| **Silent Block** | UX เมื่อ avatar ชน collision — หยุดเฉยๆ ไม่แสดง error |
| **zyra-engine** | game engine module (`zyra-engine/`); ใช้ PixiJS; import จาก `@/zyra-engine` |

---

## 6. Social & Presence Features

| คำ | ชื่อใน UI | ความหมาย |
|---|---|---|
| **Wave** | ทักทาย | ส่ง gesture ทักทายไป member อื่น; ไม่ต้องอยู่ใกล้กัน; cooldown 10s/คน |
| **Wave Back** | ทักทายกลับ | ตอบ Wave ที่ได้รับ |
| **Follow** | ติดตาม | เดิน follow อีก avatar ระยะ 1–2 tile; เก็บใน Redis เท่านั้น (ไม่ลง DB) |
| **Follow Mode** | — | state ที่ avatar recalc A* ทุก 200ms มุ่งหา target |
| **Knock** | ขอเข้าห้อง | request เข้า Private Zone; ส่ง WS event ไปหา owner ของห้อง |
| **Allow** | อนุญาต | owner ยอมให้ Knock เข้า Private Zone |
| **Deny** | ปฏิเสธ | owner ปฏิเสธ Knock |
| **Progressive Cooldown** | — | cooldown หลัง Deny: deny ครั้ง 1–2 = 30s, ครั้ง 3+ = 5min |
| **Proximity Chat** | — | chat ที่ scoped ตาม room หรือ open area (`room_id`) |
| **HUD** | — | overlay UI บนแผนที่ (member panel, chat, minimap, status) |

---

## 7. Availability Status

| Status | label ใน UI | สี | ความหมาย |
|---|---|---|---|
| **Available** | Active | green | พร้อมคุย |
| **Busy** | Busy | red | ไม่ต้องรบกวน (แต่ยัง receive Wave) |
| **Away** | Away | yellow | ไม่อยู่หน้าจอชั่วคราว |
| **Do Not Disturb** | Do Not Disturb | red (darker) | บล็อก Wave notification ทั้งหมด |
| **Offline** | — | gray | ออกจาก office แล้ว; set อัตโนมัติเมื่อ leave |
| **Custom** | — | — | user กำหนด text status เอง |

**กฎ:**
- DND = บล็อก Wave notification
- Status reset เป็น Offline อัตโนมัติเมื่อ leave office

---

## 8. UI Screens & Components

| Component | Route / Location | ความหมาย |
|---|---|---|
| **Space Builder** | `/workspace` | หน้า list workspace ทั้งหมด (3 tab) |
| **Before Enter Space** | modal | popup preview avatar ก่อน join |
| **Loading Workspace** | `/workspace/[id]/loading` | loading screen "Connecting to Stardust" (progress 0–100%) |
| **Virtual Office — Idle UI** | `/workspace/[id]/play` | หน้า map หลัก พร้อม HUD |
| **Left Sidebar** | — | แถบ icon 72px ด้านซ้าย (Map, People, Chat, Calendar, Notifications, Help, Settings, Profile) |
| **Headbar / Topbar** | — | แถบด้านบน 72px (logo, language, user avatar, Create workspace) |
| **Bottom Toolbar** | — | แถบด้านล่าง (Mic, Cam, Screen Share, Record, Emoji, Wave) |
| **Minimap** | — | แผนที่ขนาดเล็ก bottom-right แสดง room + สถานะ member |
| **Display Panel** | — | top bar ที่แสดงเมื่อ avatar เดินเข้า Room zone (ยังอยู่บน map) |
| **Full Meeting Room View** | — | UI video-grid เมื่อ enter meeting |
| **Knock Overlay** | — | card 415×288 px แสดงบนห้องเมื่อ Knock |
| **Knock Notification** | — | popup แจ้ง owner เมื่อมี Knock (Deny / Allow) |
| **Status Picker Popover** | — | popover เลือก availability status (เปิดจาก avatar ตัวเอง / sidebar profile) |
| **Context Menu** | — | menu เมื่อคลิก avatar อื่น (Wave, Follow, Chat, View Profile) |
| **Space Member Panel** | — | overlay ~300px ด้านซ้าย แสดง member จัดกลุ่มตาม room |
| **Workspace Card** | Space Builder | card แสดง thumbnail, ชื่อ, last active, role, online/capacity |
| **Kebab Menu (⋮)** | Workspace Card | context menu บน card: Enter, Copy Link, Editor, Leave |
| **Invite Member Dialog** | — | modal กรอก email + invite link สำหรับ invite member |
| **Manage Members Modal** | — | modal 934×800 px แสดง member table |
| **Transfer Ownership Modal** | — | modal ยืนยัน transfer ownership ไปหา Admin อื่น |
| **Leave Confirmation Modal** | — | modal ยืนยัน leave workspace (ต้องพิมพ์ชื่อ workspace) |
| **Toast / Notification** | — | social toast 322×142 px (top-right) หรือ standard 336×72 px |
| **Text Notification Bar** | — | banner ด้านล่างสำหรับ Follow / Away state |

**Workspace Card Tabs:**
- **All workspace** — รวมทุก workspace ที่มีสิทธิ์
- **My workspace** — เฉพาะ Owner
- **Shared with me** — เฉพาะ Member

---

## 9. Invite & Membership Flow

| คำ | ความหมาย |
|---|---|
| **Invitation Token** | random string สำหรับ link invite (cryptographically secure) |
| **Invitation Link** | `https://zyra.app/invite/[token]` — link ที่ส่งทาง email |
| **Join Link** | permanent link ต่อ workspace (ต่างจาก invitation token ที่ expire) |
| **Pending Invite** | invite ที่ส่งไปแล้วแต่ยังไม่ถูก accept; แสดงสถานะ "รอยืนยัน" |
| **Accept Invitation Page** | หน้า landing เมื่อคลิก link จาก email |
| **Resend Invite** | ส่ง email invite ใหม่ไปหา Pending member |
| **Cancel Invite** | ยกเลิก invite ที่ยัง Pending |
| **Transfer Ownership** | Owner ส่งสิทธิ์ ownership ให้ Admin คนอื่น; owner เดิมกลายเป็น Admin |
| **Auto-accept Invite** | invite token ถูก accept อัตโนมัติหลัง Register + OTP หรือ Google OAuth เสร็จ |

**กฎ:**
- Invite token expire ใน 7 วัน
- 1 batch invite ได้สูงสุด 10 email
- Admin invite ได้เฉพาะ Member role เท่านั้น
- Owner ออก workspace ไม่ได้ถ้ายังไม่ Transfer Ownership
- เมื่อ Transfer เสร็จ: owner เดิม → Admin (ไม่ใช่ Member)
- Leave Confirmation ต้องพิมพ์ชื่อ workspace ให้ตรง (case-sensitive)

---

## 10. WebSocket Events

| Event | ทิศทาง | ความหมาย |
|---|---|---|
| `welcome` | Server → Client | ส่ง state ทั้งหมดเมื่อ connect (`me`, `players[]`) |
| `joined` | Server → Client | player อื่น join room |
| `left` | Server → Client | player disconnect |
| `moved` | Server → Client | player เปลี่ยน tile |
| `chat` | Server ↔ Client | ส่ง/รับ chat message |
| `pong` | Server → Client | ตอบ ping |
| `error` | Server → Client | validation/server error |
| `move` | Client → Server | player เดิน (throttle 200ms) |
| `ping` | Client → Server | keep-alive |
| `ws:privateZone:granted` | Server → Client | Knock ได้รับอนุมัติ — barrier ถูกเปิดชั่วคราว |
| `ws:privateZone:denied` | Server → Client | Knock ถูก Deny |

---

## 11. Loading Progress Phases (SC-VO-02)

| Phase | Progress | Label |
|---|---|---|
| **Connecting** | 0–30% | กำลัง connect server |
| **Loading map** | 30–70% | โหลด map asset |
| **Loading members** | 70–100% | โหลด member list |

---

## 12. Scenario & Test ID Prefixes

| Prefix | Module |
|---|---|
| `SC-VO-*` | Virtual Office scenarios |
| `SC-SB-*` | Space Builder scenarios |
| `SC-PROFILE-*` | Profile / Settings scenarios |
| `TC-VO-*` | Virtual Office test cases |
| `TC-SB-*` | Space Builder test cases |
| `TC-PROFILE-*` | Profile test cases |

**Scenario types:**
- **Happy Path** — flow ปกติที่สำเร็จ
- **Alternate Path** — flow ที่ diverge จาก happy path แต่ยังสำเร็จ
- **Error Path** — flow ที่ error หรือถูก block

---

## 13. Business Rules Vocabulary

| คำ | ความหมาย |
|---|---|
| **Capacity** | จำนวน member สูงสุดที่ workspace รับได้; ถ้าเต็ม = block WS join |
| **Office เต็ม** | error state เมื่อ online count ≥ capacity |
| **Solo Workspace** | workspace ที่ owner เป็น member คนเดียว; อาจถูกลบเมื่อ leave |
| **Max 20 rooms** | จำนวน Room สูงสุดต่อ map |
| **allow_follow: false** | user preference ที่บล็อก Follow จาก user อื่น |
| **Connecting to Stardust** | ชื่อ loading modal (ชื่อ Stardust มาจาก workspace name placeholder) |

---

## 14. Design Tokens (Figma → Tailwind)

| Token | Hex | Tailwind arbitrary |
|---|---|---|
| `bg-primary` | `#0f1117` | `bg-[#0f1117]` |
| `bg-card` | `#1a1f2e` | `bg-[#1a1f2e]` |
| `bg-sidebar` | `#111827` | `bg-[#111827]` |
| `green-primary` | `#22c55e` | `bg-[#22c55e]` |
| `red-danger` | `#ef4444` | `bg-[#ef4444]` |
| `text-secondary` | `#9ca3af` | `text-[#9ca3af]` |
| `border-default` | `#374151` | `border-[#374151]` |

> ต้องใช้ exact hex จาก Figma เสมอ — ห้ามใช้ Tailwind default class แทน

---

## 15. Canvas Baseline (Virtual Office Desktop)

| Property | Value |
|---|---|
| Viewport | 1440 × 1024 px |
| Left Sidebar width | 72 px |
| Headbar height | 72 px |
| Map canvas area | 1352 × 992 px (x=72, y=16) |
| Standard modal width | 458 px |
| Settings/Members modal | 934 × 800 px |
| Social notification toast | 322 × 142 px (top-right at x=1094, y=24) |
| Standard toast | 336 × 72 px |
| Knock overlay | 415 × 288 px |

---

## 16. External References

| Resource | Link |
|---|---|
| ClickUp (Virtual Office module) | https://app.clickup.com/t/86d2wefft |
| Figma | https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj |
| Figma file key | `Map8gX0L2hk7HnkaFRfhtj` |

---

*อัปเดตล่าสุด: 2026-06-17*
