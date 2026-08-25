# UX/UI Plan — Virtual Office Module (Pixel-Perfect from Figma)

**Spec:** [zyra.doc/plan/[Module] Virtual Office/spec.md](./zyra.doc/plan/%5BModule%5D%20Virtual%20Office/spec.md)  
**Test Plan:** [test-plan.md](./test-plan.md)  
**ClickUp:** https://app.clickup.com/t/86d2wefft  
**Figma:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj  
**วันที่:** 2026-06-17  
**ครอบคลุม:** SC-VO-01 ถึง SC-VO-14, SC-SB-10, SC-SB-11, SC-PROFILE-06, SC-PROFILE-07

---

## Canvas & Viewport

| Property | Value |
|---|---|
| Screen size | 1440 × 1024 px |
| Left sidebar width | 72 px |
| Headbar height | 72 px |
| Map area | 1352 × 992 px (x=72, y=16) |
| Standard modal width | 458 px |
| Toast width | 336 px (small) / 322 px (notification) |
| Right panel width | 322 px (toast/modals) |
| Member panel width | 320 px |

---

## Navigation Map

```
Space builder (List Workspace)
│
├── [กด Enter workspace] → Before Enter Space (character preview)
│       └── [Join] → Loading Workspace (Connecting to Stardust)
│               └── Virtual Office — Idle UI (Map View)
│                       ├── Left sidebar (72px) — icons
│                       ├── Bottom toolbar — cam/mic/emoji/wave
│                       ├── Minimap — bottom-right
│                       ├── Click avatar → Context Menu (Wave/Follow/Chat/etc.)
│                       │       ├── Wave → toast notification top-right
│                       │       └── Follow → bottom notification bar
│                       ├── Enter Room Zone → Display Panel (top bar)
│                       │       └── Double-click / Enter Meeting → Full Meeting View
│                       ├── Enter Private Zone → Knock Overlay (on room)
│                       │       └── Owner notification top-right (Deny/Allow)
│                       ├── Click own avatar / sidebar profile → Status Picker (bottom-left)
│                       └── Sidebar → Member Panel (left overlay)
│
├── Space Settings → Manage Members → Invite Member (SC-SB-10)
│       └── Email invite → Gmail → "Join our workspace" → Register flow (SC-SB-11)
│
└── Space builder card → [⋮] context menu
        ├── Leave workspace → Confirmation modal (SC-PROFILE-06)
        └── Workspace editor → Manage members → Transfer Owner modal (SC-PROFILE-07)
```

---

## Design System — Color Tokens

### Background
| Token | Hex | ใช้กับ |
|---|---|---|
| Background/Primary | `#242B32` | Sidebar, panels, modals, cards, toasts |
| Background/Secondary | `#2B3540` | Workspace list page background |
| Shade Black/100% | `#1A1B1E` | Minimap background, display tiles |
| Shade Black/50% | `rgba(26,27,30,0.5)` | Map tools (locate/zoom buttons) backdrop-blur |
| Black/70% | `rgba(0,0,0,0.7)` | Room label overlays on map, display name overlays |

### Primary (Brand Green)
| Token | Hex | ใช้กับ |
|---|---|---|
| Primary/500 | `#58D68D` | CTA buttons, active sidebar item bg, Accept button, active status |
| Primary/20% | `rgba(88,214,141,0.2)` | Tab "All workspace" active bg |
| Primary/10% | `rgba(88,214,141,0.1)` | Active sidebar icon bg, status "Active" tab bg |

### Status Colors
| Token | Hex | ใช้กับ |
|---|---|---|
| Available (Green dot) | `#58D68D` | Status badge — available |
| Busy (Yellow dot) | `#FFD400` | Status badge — busy / workspace 40/50 |
| Away (Orange/Red) | `#F03A3A` | Status badge — away / workspace 50/50 |
| Red/500 | `#F03A3A` | Error, Leave button, destructive action |
| Red/20% | `rgba(212,24,24,0.2)` | Mic-off / Video-off icon background in bottom bar |

### Accent Colors
| Token | Hex | ใช้กับ |
|---|---|---|
| Purple/500 | `#996ADF` | "Me" avatar name tag background |
| Blue/500 | `#2DB6FF` | Link text (Log out), Admin role badge |
| Yellow/500 | `#FFD400` | Workspace capacity warning (40/50) |
| Orange/500 | `#FF8000` | Owner role badge |

### Text / Grey
| Token | Hex | ใช้กับ |
|---|---|---|
| White (100%) | `#FFFFFF` | Primary text, button labels |
| Grey/500 | `#8C99A6` | Secondary text, subtitles, timestamps |
| Grey/700 | `#636D76` | Placeholder text |
| Grey/800 | `#4D545B` | Disabled state |

### Border / Surface
| Token | Hex | ใช้กับ |
|---|---|---|
| White/5% | `rgba(255,255,255,0.05)` | Subtle card/button bg |
| White/10% | `rgba(255,255,255,0.1)` | Dividers, language dropdown bg |
| White/20% | `rgba(255,255,255,0.2)` | Border on inputs, icon buttons, minimap rooms |

### Avatar Profile Colors
| Color | Hex |
|---|---|
| Salmon | `#FFA8A8` |
| Lavender | `#E1ADFF` |
| Cornflower Blue | `#7EA2FC` |
| Mint Green | `#C4FCB6` |
| Cyan | `#95F7F6` |

### Role Badge Colors
| Role | Color |
|---|---|
| Owner | Orange/amber pill (`#FF8000`) |
| Admin | Purple pill (`#996ADF`) |
| Member | Blue pill (`#2DB6FF`) |
| Pending | Gray text |

### Typography Scale
| Token | Font | Size | Weight | LineHeight | LetterSpacing |
|---|---|---|---|---|---|
| H/Bold | Inter | 20px | 700 | 100% | 0 |
| Sub/Medium | Inter | 16px | 500 | 22px | 0 |
| Sub/Regular | Inter | 16px | 400 | 20px | 0 |
| Body/Medium | Inter | 14px | 500 | 18px | 0 |
| Body/Regular | Inter | 14px | 400 | 18px | 0 |
| Caption/Regular | Inter | 12px | 400 | 16px | 0 |
| Caption 1/Medium | Inter | 12px | 500 | 15px | -0.43 |
| Caption 1/Regular | Inter | 12px | 400 | 15px | -0.43 |

### Toast / Notification
| Type | Position | Size | Duration |
|---|---|---|---|
| Standard toast | Top-right, x=1088, y=16 | 336×72px | ~3–5s |
| Social notification | Top-right, x=1094, y=24 | 322×142px | ~5s (manual dismiss) |
| Banner (bottom) | Bottom of map, y=956 | 816×44px | persistent until action |

### Standard Buttons
| Variant | Spec |
|---|---|
| Primary (CTA) | Green filled (`#58D68D`), 44px height, full-width in modal |
| Secondary | Outlined, same height |
| Danger | Red filled (`#F03A3A`) — Leave, Delete |
| Ghost/link | No bg, text color only |

### Modal Sizing
| Modal Type | Width | Notes |
|---|---|---|
| Confirmation (simple) | 458px | h=188–220px depending on content |
| Form modal (Invite) | 696px | taller, scrollable if needed |
| Settings/Members | 934px | h=800px, scroll inside |

---

## Existing Components — Reuse Map

> Components ที่มีอยู่แล้วใน `zyra-app/components/` — ควร reuse แทนสร้างใหม่

### UI Primitives (`components/ui/`)
| Component | Path | ใช้กับ Feature |
|---|---|---|
| `Button` | `components/ui/button.tsx` | ทุก CTA: Accept, Deny, Cancel, Leave, Create workspace, Invite |
| `Dialog` | `components/ui/dialog.tsx` | Confirmation modal (SC-PROFILE-06/07), Invite modal (SC-SB-10), error modals |
| `Input` | `components/ui/input.tsx` | Status message input, Search workspace, Invite email input |
| `DropdownMenu` | `components/ui/dropdown-menu.tsx` | Workspace submenu (⋮ button), Role selector (Member/Admin) |
| `Card` | `components/ui/card.tsx` | Workspace card ใน List Workspace |
| `Select` | `components/ui/select.tsx` | Role selector dropdown |
| `Switch` | `components/ui/switch.tsx` | Settings toggles |
| `Checkbox` | `components/ui/checkbox.tsx` | Settings options |
| `Skeleton` | `components/ui/skeleton.tsx` | Loading state สำหรับ workspace cards |
| `Tooltip` | `components/ui/tooltip.tsx` | Tooltips บน sidebar icons |

### Game Components
| Component | Path | ใช้กับ Feature |
|---|---|---|
| `GameCanvas` | `components/game-canvas/game-canvas.tsx` | Map BG rendering (SC-VO-03 ขึ้นไป) |
| `AvatarSprite` | `components/avatar/avatar-sprite.tsx` | Avatar in map, avatar profile |
| `AvatarFrames` | `components/avatar/avatar-frames.ts` | Avatar frame definitions |

### App-Level
| Component | Path | ใช้กับ Feature |
|---|---|---|
| `AppNavbar` | `components/app-navbar.tsx` | Headbar (workspace list, loading page) |
| `Tooltip` | `components/tooltip.tsx` | Custom tooltip |
| `AuthGuard` | `components/auth-guard.tsx` | Route protection สำหรับ Virtual Office |
| `Providers` | `components/providers.tsx` | Context providers |

### Admin Components (adapt สำหรับ VO)
| Component | Path | หมายเหตุ |
|---|---|---|
| `AdminOnlineToast` | `components/admin/admin-online-toast.tsx` | Notification toast pattern |
| `AdminSidebar` | `components/admin/admin-sidebar.tsx` | Sidebar pattern — VO sidebar คล้ายกัน |
| `WorkspacePagination` | `components/admin/workspace-pagination.tsx` | Pagination ใน workspace list |

### Component → Scenario Mapping
| Feature | Component to Reuse |
|---|---|
| Confirmation modal | `Dialog` from `components/ui/dialog.tsx` |
| Invite modal | `Dialog` + `Input` + `Select` |
| Workspace cards | `Card` + `Skeleton` (loading) |
| Workspace submenu | `DropdownMenu` |
| Status dropdown | `DropdownMenu` หรือ custom panel |
| Toast notifications | adapt `AdminOnlineToast` pattern |
| Sidebar icons | `Tooltip` สำหรับ hover label |
| CTA buttons | `Button` (variant: primary=green, destructive=red, ghost=white) |
| Map canvas | `GameCanvas` |
| Avatar rendering | `AvatarSprite` + `AvatarFrames` |

---

## Shared Components (ปรากฏซ้ำหลาย Scenario)

### Side bar - Dark
- ขนาด: 72 × 1024 px
- ตำแหน่ง: x=0, y=0 (ซ้ายสุด)
- Icons (top): Map/home, People/members, Chat, Calendar, Notifications
- Icons (bottom): Help (?), Settings gear, User avatar (~40px circle)
- มี icon profile ด้านล่างสำหรับเปิด User status

### BG (Map background)
- ขนาด: 1352 × 992 px
- ตำแหน่ง: x=72, y=16
- Tile-based map rendered ใน area นี้

### Notification Toast (HUD — top-right)
- ขนาด: 322 × 142 px (knock/wave notification)
- ขนาดเล็ก: 322 × 124 px (wave only)
- ตำแหน่ง: x=1094, y=24

### Toast (feedback message)
- ขนาด: 336 × 72 px หรือ 312 × 72 px หรือ 312 × 90 px
- ตำแหน่ง: x=1088–1104, y=16–24 (top-right)

### Text notification bottom
- ขนาด: 816 × 44 px หรือ 341 × 44 px หรือ 506 × 44 px
- ตำแหน่ง: y ≈ 892–956 (bottom center)
- ใช้กับ: Away status, Follow mode, ยืนยัน action

### Minimap
- ขนาด: 200 × 124 px
- ตำแหน่ง: x=1176, y=876 (bottom-right corner)
- คลิกเพื่อขยาย: Room info popup 389×196 ที่ x=155, y=415

### User status dropdown (self-menu)
- ขนาด: 322 × 412 px (full with custom) หรือ 322 × 310 px (basic)
- ตำแหน่ง 2 รูปแบบ:
  - เปิดจาก sidebar (bottom-left): x=80, y=588 (opens up)
  - เปิดจาก member panel (top-right): x=1094, y=24

### Confirmation modal
- ขนาด: 458 × 188 px (simple confirm) หรือ 458 × 206 px หรือ 458 × 220 px (with input)
- ตำแหน่ง: x=491, y=409–418 (horizontally centered on 1440)
- มี Overlay ทับหน้า: rounded-rectangle full screen

### Display panel (In-room HUD)
- Meeting room / open area: w=1336, h=208 ที่ x=80, y=24
- Private room: w=660, h=208 ที่ x=418, y=24
- Regular room: w=660, h=208 ที่ x=418, y=24

### Room type modal (right-side action)
- ขนาด: 322 × 430 px
- ตำแหน่ง: x=1094, y=24–33

### Setting panel (full-screen modal overlay)
- ขนาด: 934 × 800 px
- ตำแหน่ง: x=253, y=112 หรือ x=253, y=141.5

---

## SC-VO-01 · List Workspace

**Figma:** node `1805-259434` | Key frame: `1805:267553` (1440×1024)

### Layout
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [Zyra logo 32px]  Space builder          [EN ▼] [●CC Conan Grey]  [+ Create] │  h=72 topbar
├──────────────────────────────────────────────────────────────────────────────┤
│ [🔍 Search workspace...]                             [Last visited ↓]         │  h=56 filters
├──────────────────────────────────────────────────────────────────────────────┤
│ All workspace │ My workspace │ Shared with me                                 │  tab bar
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │[pixel map] │  │[pixel map] │  │[pixel map] │  │[pixel map] │  ...         │  card grid
│  │ Starlight  │  │Shooting Star│ │  Cosmos    │  │ Starlight  │             │
│  │ Sep 18 '25 │  │ Sep 18 '25 │  │ Sep 18 '25│  │ Sep 18 '25 │             │
│  │ [● Owner]  │  │ [● Member] │  │ [● Member]│  │ [● Owner]  │  [⋮]        │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘             │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                          ◀  10/page ▼  ▶    │  pagination
└──────────────────────────────────────────────────────────────────────────────┘
```

### Card Components
| Component | Spec |
|---|---|
| Topbar | h=72px, dark bg, flex row: logo left / title / lang+user+create right |
| "Create workspace" button | Green filled `#58D68D`, "+ Create workspace", top-right |
| Tab bar | Active: white text + bottom border green; inactive: gray text |
| Card thumbnail | Pixel art map preview, aspect-ratio ~4:3, rounded-top corners |
| Role badge | Owner: orange pill / Member: outline gray pill, ~12px |
| Pagination | Bottom-right, "◀ [page] 10/page ▼ ▶" |

### Kebab Context Menu (⋮)
```
┌──────────────────────┐  w=200px
│  → Enter workspace   │  ← white text
│  🔗 Copy link        │  ← blue icon
│     Workspace editor │
│  🗑 Leave workspace  │  ← red text (Member/Admin only)
└──────────────────────┘
```

| Role | Menu Items |
|---|---|
| Member | เข้า Work Space, คัดลอก Work Space |
| Owner | เข้า Work Space, คัดลอก Work Space, เข้าแก้ไข, Invite Member |

Submenu sizes: 200×142 px (Owner @ x=1200, y=236), 200×184 px (Member @ x=168, y=506)

---

## SC-VO-02 · Loading Page

**Figma:** node `1805-271513` | Frames: `39:5255`, `70:13872`, `1805:280286`

### Step 1 — Before Enter Space
```
┌────────────────────────────────────────────────────────────────────────────┐
│ [Headbar: logo + topbar h=72]                         [● Conan Grey]        │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────────────────────────────────────────────────────────┐     │
│   │  Welcome to Starlight world             (x=253, y=264, w=934)    │     │
│   │  ┌──────────────────────────────────┐  ┌──────────────────────┐ │     │
│   │  │                                  │  │  [avatar sprite]     │ │     │
│   │  │   [Video/Photo preview           │  │                      │ │     │
│   │  │    ~500px wide, h=432]           │  │  Change avatar       │ │     │
│   │  │                                  │  │  [▶ btn green]       │ │     │
│   │  └──────────────────────────────────┘  └──────────────────────┘ │     │
│   └──────────────────────────────────────────────────────────────────┘     │
│   By joining space, you agree with Terms of Services and Privacy Policy     │  y=974
└────────────────────────────────────────────────────────────────────────────┘
```

### Step 2 — Loading Workspace
```
┌────────────────────────────────────────────────────────────────────────────┐
│          [Full-screen 3D isometric office environment background]           │
│                                                                             │
│                   ┌──────────────────────────┐                             │
│                   │  Connecting to Stardust   │  ← loading modal, center   │
│                   │  ─────────────────────── │                             │
│                   │  Tip: Walk up to ...      │                             │
│                   │  ████████░░ Connected 30% │  ← green fill, dark track  │
│                   └──────────────────────────┘                             │
└────────────────────────────────────────────────────────────────────────────┘
```

Progress phases: **Connecting (0–30%)** → **Loading map (30–70%)** → **Loading members (70–100%)**

### Error States
| State | Component | ขนาด | ตำแหน่ง |
|---|---|---|---|
| Capacity เต็ม (Member/Admin) | Confirmation modal | 458×206 | x=491, y=409 |
| Capacity เต็ม (Owner) | Plan modal | 554×649 | x=443, y=217 |
| Banner warning | Banner | 1440×58 | x=0, y=0 (top) |

---

## SC-VO-03+04 · Render Map & Avatar Movement

**Figma:** node `1805-285771` | Key frame: `1805:287545` (Idle UI), `1810:479896` (Minimap), `1810:481148` (Room hover)

### Screen Zones
```
┌──────────────────────────────────────────────────────────────────────┐
│ ┌──┐  ┌────────────────────────────────────────────────────────────┐ │
│ │  │  │                                                            │ │
│ │  │  │          PIXEL ART 2D MAP CANVAS                          │ │
│ │  │  │     (top-down, multiple rooms visible)                     │ │
│ │SB│  │                                                            │ │
│ │72│  │   [avatars positioned throughout]                          │ │
│ │  │  │                                            ┌────────────┐  │ │
│ │  │  │                                            │  minimap   │  │ │
│ │  │  │                                            │ 200×124 px │  │ │
│ └──┘  │                                            └────────────┘  │ │
│       │  [Move indicator 40×40 @ 395,461]                          │ │
│       └────────────────────────────────────────────────────────────┘ │
│        ┌─────────────────────────────────────────────────────────┐   │
│        │  [🎤▼] [📹▼] [🖥] [⏺▼] [🎭] [👋]  bottom toolbar     │   │
│        └─────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

### Minimap
- Collapsed: 200×124 px ที่ bottom-right (x=1176, y=876)
- Expanded: Room info popup 389×196 px ที่ x=155, y=415
- White dot = self, colored dots = others by status
- Room zone ชื่อ: Lobby, Garden, Team ABC — Private/Meeting zone hover แสดงชื่อ

### Avatar States
| State | Visual |
|---|---|
| Moving | Walk animation 4 direction (up/down/left/right) |
| Idle (3s) | Idle animation loop |
| Following | อยู่ห่าง 1–2 tiles จาก target |

### Movement Feedback
- Click destination: ripple animation at click point
- Nametag badge (52–102×24 px) follows avatar

---

## SC-VO-05 · Collision Detection

**Figma:** node `1810-518058`

### Avatar Clustering (collision zone)
```
Positions within ~300px radius:
  Avatar 89×71  @ (303, 520)   ← center
  Avatar 72×71  @ (172, 533)   ← left
  Avatar 76×71  @ (443, 533)   ← right
  Avatar 125×71 @ (413, 394)   ← upper-right
  Avatar 89×71  @ (168, 394)   ← upper-left
  Avatar 96×71  @ (299, 418)   ← upper-center
```

### Notes from Figma
- "กรณีเดินติดกำแพง ซึ่งมีการ Block ไว้ไม่ให้ผ่าน"
- "เดินไปยังทางที่ไม่มี Block เพื่อเข้าห้องประชุม"

---

## SC-VO-06 · Multiple Room

**Figma:** node `1842-209371`

### A. Display Panel (เดินเข้าห้อง — ยังอยู่ map view)
```
┌──────────────────────────────────────────────────────────────────────┐
│ ┌──┐  ┌──────────────────────────────────────────────────────────┐   │
│ │SB│  │ ┌──────────────────────────────────────────────────────┐ │   │
│ │72│  │ │ [room name]  [●av] [●av] [●av] [+N]  📹 💬  [×][⤢]│ │   │  h=208, y=24
│ │  │  │ └──────────────────────────────────────────────────────┘ │   │
│ │  │  │       [MAP CANVAS continues below panel]                 │   │
│ └──┘  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

### Room Types & Display Panels
| Room Type | Panel Position | ขนาด |
|---|---|---|
| Open area / Meeting | x=80, y=24 | 1336×208 px |
| Private room | x=418, y=24 | 660×208 px |
| Regular room | x=418, y=24 | 660×208 px |

### B. Full Meeting Room View
```
┌──────────────────────────────────────────────────────────────────────────┐
│ ┌──┐  Meeting room 1  ║ 6 ▼ ║            🔒  🔗  💬  ⤢             │  h=56
├─┤  ├──────────────────────────────────────────────────────────────────────┤
│ │SB│  ┌───────────┐  ┌───────────┐  ┌───────────┐  │  Chat        ×  │ │
│ │72│  │  [avatar] │  │  [avatar] │  │  [avatar] │  │  [chat history] │ │
│ │  │  │ 🎤 Name1  │  │ 🎤 Name2  │  │ 🎤 Name3  │  │                 │ │
│ │  │  └───────────┘  └───────────┘  └───────────┘  │  ┌───────────┐  │ │
│ │  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  │  │ Message.. │  │ │
│ │  │  │  [avatar] │  │  [avatar] │  │  [avatar] │  │  │ 📎 🖼 😊▶ │  │ │
│ │  │  └───────────┘  └───────────┘  └───────────┘  │  └───────────┘  │ │
│ └──┘  ┌──────────────────────────────┐             └──────────────────┘ │
│       │ 🎤▼  📹▼  🖥  ⏺▼  😊  ✋  │  toolbar                          │
│       └──────────────────────────────┘                                    │
└──────────────────────────────────────────────────────────────────────────┘
```

### Room Action Submenu (w=289, h=413)
```
┌─────────────────┐  x=110–144, y=64–70 (top-left of map)
│  Chat           │
│  Members        │
│  Record         │  ← Meeting zone only
│  Share screen   │
│  Leave room     │
└─────────────────┘
```

Notes: "ฟีเจอร์ Chat กับ Record เฉพาะ Meeting zone"

---

## SC-VO-07 · Private Area Zone — Knock

**Figma:** node `1858-324403`

### Knock Overlay (ฝั่งคนขอเข้า — on top of the private room)
```
                ┌──────────────────────────────────────────┐  x=140, y=335
                │           [🎥 camera/lock icon ~42px]     │  w=415, h=288
                │                                          │
                │  Requesting access to join the room.     │  ← ~16px white
                │                                          │
                │         [ Join Now  ▶  ]                  │  ← green btn 117×24px
                └──────────────────────────────────────────┘
```

### Knock Notification (ฝั่งเจ้าของห้อง) — top-right
```
┌──────────────────────────────────────────────────────┐  x=1094, y=24
│ [pixel art avatar ~48px]  Taylor Swift               │  322 × 142 px
│                           Ask to join Meeting room 3 │  ← gray ~12px
│                                                      │
│                    [ Deny ]      [ Enter ]           │  ← Deny: outlined / Enter: green
└──────────────────────────────────────────────────────┘
```

**Note:** "Noti ไม่หายจะคงอยู่ตลอดไปจนกว่าจะมีการทำ Action"

### After Allow
- `Move` button 40×40 px ปรากฏบน overlay หลัง allow
- คนขอเข้าสามารถ warp เข้าห้องหรือวิ่งเข้าได้เลย

### Flow Frames
| Frame | ฝั่ง | คำอธิบาย |
|---|---|---|
| `1858:334560` | คนขอ | กำลังเดินเข้าห้อง |
| `1858:324405` | คนขอ | Knock overlay แสดง |
| `1858:334787` | คนขอ | Overlay + Move button |
| `1858:335437` | คนในห้อง | เห็น Notification toast |
| `1860:337848` | คนในห้อง | Room type modal (Allow/Deny) |
| `1860:336781` | คนขอ (ได้รับอนุญาต) | Display panel = เข้าห้องสำเร็จ |

---

## SC-VO-08 · Private Area Zone — ถูกปฏิเสธ

**Figma:** node `1860-338181`

### Denied Overlay (same card as Knock, content changes)
| State | Text | Countdown |
|---|---|---|
| Waiting | "Requesting access to join the room." | — |
| Cooldown 30s (ครั้งที่ 1–2) | "Requesting access to join the room again in **00:30**" | disabled countdown |
| Cooldown 5min (ครั้งที่ 3+) | "Requesting access to join the room again in **05:00**" | disabled countdown |

- Same card: 415×288px, บน private room
- Notification toast (322×142px) top-right: แสดงสั้นๆ แล้วหาย

Notes:
- "กรณี Cool down 30 วิ" (1st–2nd deny)
- "กรณีถูกปฎิเสธเกิน 3 ครั้ง Cool down 5 นาที"

---

## SC-VO-09 · Availability Status

**Figma:** node `1860-341973`

### Status Picker Popover (bottom-left)
```
┌───────────────────────────────────────────────────────┐  x=80, y=588
│ [avatar 40px]  Zachawat Phondec...                    │  w=322, h=412
│                Active  ●                              │  ← current status green
│ ─────────────────────────────────────────────────── │
│  ✦ Go offline                                         │
│  ✦ Change status                                      │
│  ✦ Go to my location                                  │
│     [more options]                                    │
└───────────────────────────────────────────────────────┘
```

**Note:** "User เมนูของตนเอง ปรากฎได้จากการกดที่ Avatar ของตัวเอง และรูปโปรไฟล์ตรง Side bar"

### Status Options
| Status | Badge color | พฤติกรรม |
|---|---|---|
| Available | เขียว `#58D68D` | ปกติ มองเห็นบน map |
| Busy | แดง `#F03A3A` | มองเห็นบน map |
| Away | เหลือง `#FFD400` | **หายจาก map** — คนอื่นมองไม่เห็น |
| Do Not Disturb | — | ซ่อน Wave/Knock notification |
| Custom | — | พิมพ์ข้อความ max 30 ตัว + emoji |

### Away State
- Avatar หายจาก main map และ minimap
- Component `Text notification bottom`: 816×44 px @ x=340, y=956
- กลับมา: กด "Back to available" หรือขยับ WASD

---

## SC-VO-10 · Wave Notification

**Figma:** node `1872-349124`

### Action Menu (คลิก avatar คนอื่น) — top-right
```
┌───────────────────────────────────────────────────────┐  x=1094, y=24
│ [pixel art avatar]  Orchawat Phondechaphiphat         │  w=322, h=310
│ ─────────────────────────────────────────────────── │
│  1. Wave to [Name]                                    │
│  2. Go to [Name]                                      │
│  3. Follow [Name]                                     │
│  [Chat, View Profile]                                 │
└───────────────────────────────────────────────────────┘
```

### Wave Received — Notification Card (ฝั่งที่ถูก wave)
```
┌───────────────────────────────────────────────────────┐  x≈1094, y=24
│ [pixel art avatar ~48px]  Orchawat Phondechaphiphat   │  322 × 124 px
│                           Wave to you right now       │  ← gray ~12px
│                                                       │
│                              [ Wave Back ]            │  ← green outlined
└───────────────────────────────────────────────────────┘
```

- `Waving Hand` emoji icon: 32×32 px ลอยบน avatar ของคนที่ wave
- Note: "กรณีอีกฝั่งเลือก Go to Avatar ของอีกฝั่งจะวิ่งมาหาเราอัตโนมัติ"
- Cooldown: 10 วินาที ต่อคน

---

## SC-VO-11 · Follow

**Figma:** node `1942-29366`

### Follow Context Menu (top-right)
```
┌───────────────────────────────────────────────────────┐  x=1094, y=24
│ [pixel art avatar]  Conan Grey                        │  w=322, h=310
│ ─────────────────────────────────────────────────── │
│  1. Follow Conan Grey                                 │
│  2. Wave to Conan Grey                                │
│  3. Chat                                              │
└───────────────────────────────────────────────────────┘
```

**Note:** "Follow = ไปหา + เดินตามคนนั้น, Go to = ไปยังจุดที่คนนั้นอยู่เฉยๆ ไม่ทำการ Chat space"

### Following State
- Follower bottom bar: `Text notification bottom` x=577.5, y=892, w=341, h=44 — "Following [Name] | Cancel"
- Avatar ห่าง 1–2 tiles ตามอัตโนมัติ

### Target View (ฝั่งที่ถูก follow)
- `Text notification bottom` (wider): 506×44 px แจ้ง "[ชื่อ] is following you"

### Cancel Follow
- กด WASD หรือกด Cancel button บน notification bar

---

## SC-VO-14 · Space Member Panel

**Figma:** node `1951-217507`

### Panel Layout (Left overlay, x=72, y=16, 320×992 px)
```
┌────────────────────────────────────────┐  x=72, y=16
│ Member                           [🔍]  │  ← header bold white
│ ┌──────────────────────────────────┐  │
│ │ 🔍 Searching...                  │  │  ← search input
│ └──────────────────────────────────┘  │
│                                        │
│ Meeting hall 01                        │  ← room section header
│ ●●●●●●●●●  (avatar row, 36px ea.)   │  ← colored dots stacked
│                                        │
│ Meeting hall 02                        │
│ ●●●●●●●●●                            │
│ ─────────────────────────────────── │
│ [av] Zachawat Phondechaphiphat         │  ← individual member rows (40px av)
│ [av] Gatam Grey                        │
└────────────────────────────────────────┘
```

### Panel Sections (Groups)
| Group | Label | ลำดับ |
|---|---|---|
| Online | "Online" | 1 (แสดงก่อน) |
| In meeting room | "In meeting room" | 2 |
| Chat Space | "Chat Space" | 3 |
| Offline | "Offline" | 4 |
| Not found | — | search empty state |

### Member Card Interactions
| Action | ผลลัพธ์ |
|---|---|
| Hover ที่ตนเอง | ไม่มีอะไรเกิดขึ้น |
| Hover ที่คนอื่น | แสดง Wave + Go to |
| Click ที่ meeting | Camera pan ไปห้องประชุมทันที |
| Click card (unlocked) | `User status` popup 322×310 @ x=1094 |
| Click card (locked) | `Room type modal` 322×430 @ x=1094 |

### Modals from Panel
- `Chat space modal`: 322×286 px หรือ 322×334 px @ x=1094, y=24
- `Room type modal`: 322×430 px @ x=1094, y=24
- `User status`: 322×136 px (DND) หรือ 322×412 px (full)

### Circle (Proximity Chat Visual)
- `Circle` component: 200×170 px
- Avatar ใน circle: 68×71 px, 90×71 px (2 คน)

---

## SC-SB-10 · Invite Member เข้า Space ด้วย Email

**Figma:** node `1951-268597`

### Invite Member Dialog
```
┌────────────────────────────────────────────────────────────────────────┐  696px wide
│  Invite member                                                   ×     │
│                                                                        │
│  Choose an option        ────────────────────── ▼                     │
│                                                                        │
│  Invite via email                                                      │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │ Search member or type email...                         [Search]  │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│  [Role: Member ▼]                                                      │
│                                                                        │
│  Invite via link                                                       │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │ https://zyra.app/invite/xxx...                          [Copy]   │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│                                          [ Dismiss ]   [ Invite ▶ ]  │
└────────────────────────────────────────────────────────────────────────┘
```

Modal: 696×503 px (standard) หรือ 696×543 px (overflow emails), ตำแหน่ง x=372, y=240–260

### Role Selector Submenu
- ขนาด: 120×100 px @ x=810, y=485
- Options: Member, Admin

### States
| State | Toast | ขนาด |
|---|---|---|
| ส่งสำเร็จ | "ส่งคำเชิญไปยัง [email] แล้ว" | 312×72 px |
| Email เป็น member อยู่แล้ว | Error toast | 312×90 px |
| Pending badge | badge "รอยืนยัน" สีเหลือง | inline |

### Manage Members (Settings)
- Setting panel: 934×800 px @ x=253, y=112
- Submenu (member action): 289×116 px @ x=1119, y=880

---

## SC-SB-11 · Invite Member ที่ไม่มีบัญชีในระบบ

**Figma:** node `1951-351958`

### Registration Flow
```
Email (invitation link)
  → Login page (1440×1024)     [node: 1951:358410]
  → Register page (1440×1024)  [node: 1951:358491] ← email pre-filled
  → Google OAuth (1920×956)    [node: 1951:359145]
  → Verify account (1440×1024) [node: 1951:358589]
  → Congratulations (1440×1024)[node: 1951:358588]
  → Before enter space (1440×1024) [node: 1951:358636]
  → Setting (member list, Pending→Confirmed) [node: 1951:366022]
```

### Invitation Email (Gmail)
| Element | Spec |
|---|---|
| Subject | "You're invited to join the team on Zyra!" |
| CTA button | "Join our workspace" — green, centered |
| Note | "The link will be expired within **7 days**." |

### Error: Link Expired (Modal 458×348 @ x=491, y=338)
```
┌────────────────────────────────┐
│      [Zyra logo 80px]          │
│  Unable to Join Workspace      │
│  This invitation link has      │
│  expired. Please contact your  │
│  workspace administrator for   │
│  a new invitation.             │
│  ─────────────────────────── │
│  [ Back to login   378×44  ]   │
└────────────────────────────────┘
```

### Error: Capacity Limit (Modal 458×416 @ x=491, y=304)
- Title: "Enter workspace is prohibited"
- Body: "You cannot access this workspace due to capacity of the workspace reach limit."

Notes:
- "กรณีสมัครผ่าน email ให้ Prefill email ไว้"
- "หลังจากคนที่ถูกเชิญตอบรับ status Pending → Confirm"

---

## SC-PROFILE-06 · Leave Workspace — Member/Admin

**Figma:** node `1951-359635`

### Entry Points
1. Workspace card → ⋮ submenu → "Leave workspace" (red text)
2. Settings page → Setting 934×800 → member action

### Confirmation Flow
```
Step 1 — Confirmation modal 458×188 @ x=491, y=418
┌────────────────────────────────────────────────────────┐
│  Leave workspace?                                  ×   │
│  You will lose access to this workspace and will       │
│  need a new invitation to rejoin.                      │
│                           [ Cancel ]   [ Leave ]       │  ← Leave: red filled
└────────────────────────────────────────────────────────┘

Step 2 — Confirmation modal 458×220 @ x=491, y=418 (with input)
┌────────────────────────────────────────────────────────┐
│  พิมพ์ชื่อ Workspace เพื่อยืนยัน               ×      │
│  ┌─────────────────────────────────────────────────┐  │
│  │ [input field — case-sensitive workspace name]   │  │
│  └─────────────────────────────────────────────────┘  │
│           [ ยืนยันออกจาก Workspace  378×44 ]           │  ← active เมื่อพิมพ์ถูก
└────────────────────────────────────────────────────────┘
```

### Success
- Toast 312×72 px @ x=1104, y=24
- Redirect → Workspace list

---

## SC-PROFILE-07 · Leave Workspace — Owner (Transfer Ownership)

**Figma:** node `1951-379814`

### Manage Members Modal (934×800 @ x=253, y=141.5)
```
┌──────────────────────────────────────────────────────────────────────────┐
│  Manage members                                                    ×     │
│  Shooting star | Virtual Office Space                    [ Invite ]      │
│  ─────────────────────────────────────────────────────────────────────  │
│  [🔍 Search member...]                             All role ▼             │
│  Members (6)                                                             │
│  │ Name                   Role     Last active      Status    Action     │
│  │ [av] Dechawat Phon...  [Owner]  13/11/26 11:00  Confirm    ⋮         │
│  │ [av] Conan Grey        [Admin]  13/11/26 11:00  Confirm    ⋮         │
│  │ [av] Taylor Swift      [Member]                            ⋮  ▼      │
│  │ [av] Conan Green       [Member]                  Pending              │
└──────────────────────────────────────────────────────────────────────────┘
```

### Member Action Dropdown (w=240, h=200)
```
┌──────────────────────┐
│  Demote to Member    │
│  Profile             │
│  Transfer Owner      │
│  Delete              │  ← red text
└──────────────────────┘
```

### Transfer Ownership Confirmation (458×220 @ x=491, y=409)
```
┌───────────────────────────────────────────────────────┐
│  Transfer workspace ownership?                   ×    │
│  [User Name] will become the new workspace owner.    │
│  Your role will be changed to Admin, and this change  │
│  will take effect immediately.                        │
│                         [ Cancel ]   [ Transfer ]    │  ← Transfer: green filled
└───────────────────────────────────────────────────────┘
```

### Case A — Owner Leave (มี Member อยู่)
```
Workspace card → Submenu 200×184
  → Setting 934×800 (Transfer Ownership UI)
  → Submenu 240×200 (เลือก Admin target)
  → Confirmation modal 458×206
  → Toast 312×72 (Transfer สำเร็จ)
  → flow Member leave (SC-PROFILE-06) ทำได้แล้ว
```

### Case B — Owner Leave (ไม่มี Member — Leave ได้เลย)
```
Workspace card → Submenu 200×200
  → Confirmation modal 458×188
  → Confirmation modal 458×220 (with input)
  → Toast 312×72
```

### Role Hierarchy
```
Owner → Admin → Member
```
| Action | Owner | Admin | Member |
|---|---|---|---|
| Transfer ownership | ✓ | ✗ | ✗ |
| Delete Admin | ✓ | ✓ | ✗ |
| Delete Member | ✓ | ✓ | ✗ |
| Leave workspace | ต้อง Transfer ก่อน (ถ้ามี member) | ✓ | ✓ |

Notes:
- "Transfer owner ทำได้เฉพาะคนที่อยู่ในตำแหน่ง Admin"
- "เมื่อ Owner ย้าย Ownership แล้ว Owner จะลงไปอยู่ตำแหน่ง Admin"

---

## Component Sizing Reference

| Component | Width | Height | Position / Notes |
|---|---|---|---|
| Side bar | 72 | 1024 | always dark |
| Headbar | 1440 | 72 | top of screen |
| Map BG | 1352 | 992 | x=72, y=16 |
| Avatar (standard) | 89 | 71 | most common |
| Avatar (wide) | 125–140 | 71 | some variants |
| Avatar name badge | 52–102 | 24 | above avatar |
| Notification toast | 322 | 142 | top-right HUD |
| Wave toast | 322 | 124 | shorter variant |
| Toast feedback | 312–336 | 72–90 | top-right corner |
| Bottom notification | 341–816 | 44 | center-bottom |
| Minimap | 200 | 124 | x=1176, y=876 |
| Room popup | 389 | 196 | x=155, y=415 |
| Move button | 40 | 40 | floating |
| User status (full) | 322 | 412 | x=80, y=588 |
| User status (basic) | 322 | 310 | x=1094, y=24 |
| Display panel (full) | 1336 | 208 | x=80, y=24 |
| Display panel (small) | 660 | 208 | x=418, y=24 |
| Room type modal | 322 | 430 | x=1094, y=24 |
| Knock overlay card | 415 | 288 | x=140, y=335 |
| Knock icon | 42 | 42 | inside card |
| Knock cancel button | 117 | 24 | inside card |
| Chat space modal | 322 | 286–334 | x=1094, y=24 |
| Member panel | 320 | 992 | x=72, y=16 |
| Circle | 200 | 170 | proximity chat |
| Invite modal | 696 | 503–543 | x=372, y=240 |
| Role submenu | 120 | 100 | inline |
| Setting modal | 934 | 800 | x=253, y=112 |
| Confirmation (small) | 458 | 188 | x=491, y=418 |
| Confirmation (medium) | 458 | 206 | x=491, y=409 |
| Confirmation (large) | 458 | 220 | x=491, y=418 |
| Error modal (capacity) | 458 | 416 | x=491, y=304 |
| Error modal (expired) | 458 | 348 | x=491, y=338 |
| Logo (in modal) | 80 | 80 | top of modal |
| Modal button | 378 | 44 | full-width |
| Banner (warning) | 1440 | 58 | top of screen |
| Plan modal | 554 | 649 | centered |
| Submenu (context) | 200–289 | 100–430 | varies by type |
| Waving hand icon | 32 | 32 | on avatar |

---

## Figma Node Index

| Scenario | Section Node | Key Sub-nodes |
|---|---|---|
| SC-VO-01 | `1805-259434` | `1805:267553`, `1805:259437`, `1805:259440` |
| SC-VO-02 | `1805-271513` | `39:5255`, `70:13872`, `1805:280889`, `1805:282080` |
| SC-VO-03 | `1805-285771` | `1805:287545`, `1810:479896`, `1810:481148` |
| SC-VO-04 | `1805-285771` | (shared กับ SC-VO-03) |
| SC-VO-05 | `1810-518058` | `1810:518068`, `1810:518076`, `1837:82406` |
| SC-VO-06 | `1842-209371` | `1842:209409`, `1842:209439`, `1842:211155`, `1842:211148` |
| SC-VO-07 | `1858-324403` | `1858:334560`, `1858:324405`, `1858:335437`, `1860:337848`, `1860:336781` |
| SC-VO-08 | `1860-338181` | `1860:338183`, `1860:338237`, `1860:338219`, `1860:338256`, `1860:338264` |
| SC-VO-09 | `1860-341973` | `1865:346019`, `1870:347550`, `1872:347835`, `1872:348696` |
| SC-VO-10 | `1872-349124` | `1872:356873`, `1872:356862`, `1872:356870`, `1977:1361622` |
| SC-VO-11 | `1942-29366` | `1942:31688`, `1942:31694`, `1942:36644`, `1942:37524` |
| SC-VO-14 | `1951-217507` | `1951:241763`, `1951:261031`, `1951:258813`, `1951:261691` |
| SC-SB-10 | `1951-268597` | `1951:268600`, `1951:268604`, `1951:272351`, `1951:271722` |
| SC-SB-11 | `1951-351958` | `1951:352016`, `1951:352002`, `1951:358410`, `1951:358491` |
| SC-PROFILE-06 | `1951-359635` | `1951:369055`, `1951:369427`, `1951:370558`, `1951:371366` |
| SC-PROFILE-07 | `1951-379814` | `1951:379834`, `1972:1304027`, `1951:379851`, `1951:386811` |
