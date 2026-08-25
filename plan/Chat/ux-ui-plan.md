# Chat Module — UX/UI Plan (Pixel-Perfect)

> **Source**: Figma file `Map8gX0L2hk7HnkaFRfhtj` (Zyra design — More Organised ver.)
> **Canvas**: 1440 × 1024 px · Design tokens shared with VirtualOffice module
> **Version**: 1.1 · **Date**: 2026-06-29 · **Status**: In Progress

> **Changelog**: v1.1 (2026-06-29) — Codebase Alignment: ปรับเอกสารให้ตรงกับโค้ดจริง

### Codebase Alignment (v1.1)

- **Frontend paths** — ฝั่ง implementation ใช้ client จริง: `authFetch` ใน `lib/api/client.ts` (REST, มี 401 refresh+retry) และ `WorkspaceWSClient` ใน `lib/api/workspace-ws.ts` (single connection ต่อ workspace, มี method `chat(content)` อยู่แล้ว) — ไม่ใช่ `lib/api/chat.ts` / `lib/ws/chat-ws.ts` ที่ยังไม่มี (เป็นไฟล์ใหม่ที่ต้องสร้าง)
- **Renderer** — virtual office ใช้ PixiJS v8 (`PixiGameScene`) ไม่ใช่ Phaser; proximity chat overlay ฝังใน `views/user/virtual-office/hero-virtual-office.tsx`
- **Route** — virtual office จริงคือ `app/workspace/[id]/play/page.tsx` → `HeroVirtualOffice`; หน้า chat ใหม่ใด ๆ ต้องเพิ่ม route ใหม่ + พิจารณา `PUBLIC_PATHS` ใน `components/auth-guard.tsx`
- **Notification boundary** — in-app notification (DB + logic) เป็นของ zyra-api; real-time push เป็นของ zyra-ws; อีเมลทั้งหมดผ่าน zyra-notifications microservice (POST `/v1/email`) — zyra-api ไม่มี SMTP ในตัว
- **Status** — ClickUp parent task `[Module] Chat` อยู่สถานะ In Progress แล้ว เอกสารฉบับนี้จึง bump เป็น v1.1

---

## 1. Canvas & Viewport Baseline

| Property | Value |
|---|---|
| Canvas size | 1440 × 1024 px |
| Root background | `#242B32` |
| Sidebar width | 72 px (p-[16px] each side, icon area 40 px) |
| Chat panel width (Half view) | 320 px, right-[1048px], top-[16px] |
| Chat panel width (Full view — list) | 320 px, right-[1048px], top-[16px] |
| Chat area width (Full view — messages) | 1016 px, right-[16px], top-[16px] |
| Map/BG area (Half view) | 1016 × 992 px, top-[16px], left offset from center |
| Chat panel height | 992 px, rounded-[16px] |

---

## 2. Design System Color Tokens

| Token | Hex / RGBA | Usage |
|---|---|---|
| Background/Primary | `#242B32` | Root bg, chat panel bg, input bg |
| Background/Secondary | `#2B3540` | Chat header, input message container |
| Theme/Tertiary | `#344354` | Chat message area bg |
| Shade Black/100% | `#1A1B1E` | Minimap, zoom control bg |
| Primary/500 (green) | `#58D68D` | Send button, active nav, primary CTA |
| Primary/10% | `rgba(88,214,141,0.1)` | Active nav item bg, active chat item bg |
| Primary/20% | `rgba(88,214,141,0.2)` | Own emoji reaction chip bg |
| Red/500 | `#D41818` | Unread badge bg |
| Red/500 (error) | `#F03A3A` | Delete button text, danger actions |
| Red/5% | `rgba(240,58,58,0.05)` | Danger button bg |
| Red/50% | `rgba(240,58,58,0.5)` | Danger button border |
| Grey/500 | `#8C99A6` | Placeholder, timestamp, subtitle |
| Grey/700 | `#636D76` | Input placeholder text |
| White/5% | `rgba(255,255,255,0.05)` | Ghost button bg |
| White/10% | `rgba(255,255,255,0.1)` | Other emoji reaction chip, hover menu item |
| White/20% | `rgba(255,255,255,0.2)` | Border, divider, scrollbar |
| Purple/500 | `#996ADF` | "Me" nametag bg on map |
| Channel Blue | `#7EA2FC` | Channel/Group avatar bg |

---

## 3. Typography Scale

| Style | Font | Size | Weight | Line Height | Tracking |
|---|---|---|---|---|---|
| Title/Bold | Inter Bold | 20px | 700 | 25px | 0 |
| Sub/Medium | Inter Medium | 16px | 500 | 22px | 0 |
| Sub/Regular | Inter Regular | 16px | 400 | 22px | 0 |
| Body/Bold | Inter Bold | 14px | 700 | 18px | 0 |
| Body/Medium | Inter Medium | 14px | 500 | 18px | 0 |
| Body/Regular | Inter Regular | 14px | 400 | 18px | 0 |
| Caption1/Medium | Inter Medium | 12px | 500 | 15px | -0.43px |
| Caption1/Regular | Inter Regular | 12px | 400 | 15px | -0.43px |
| Caption2/SemiBold | Inter SemiBold | 10px | 600 | 13px | -0.43px |
| Caption2/Medium | Inter Medium | 10px | 500 | 14px | 0 |
| Caption2/Regular | Inter Regular | 10px | 400 | 13px | -0.43px |

---

## 4. Navigation Map

```
[Sidebar 72px]  [Chat Panel List 320px]  [Chat Message Area 1016px]
      │                   │                         │
  ┌───┴───┐         ┌─────┴──────┐          ┌──────┴──────┐
  │ Logo  │         │  "Chat"    │          │  Header     │
  │ Map   │         │  Search+   │          │  (DM/Ch/Grp)│
  │ Members│        │  Filter    │          │─────────────│
  │ Chat ●│         │────────────│          │  Message    │
  │ Calendar│       │  Threads   │          │  Area       │
  │ Notif │         │────────────│          │  (scrollable│
  │       │         │  Channels  │          │   #344354)  │
  │       │         │  Groups    │          │─────────────│
  │       │         │  DMs       │          │  Input Box  │
  │────── │         │            │          │  138px      │
  │ Help  │         │────────────│          └─────────────┘
  │ Setting│        │ Start Chat │
  │ Avatar│         │  [green]   │
  └───────┘         └───────────┘

Half-view (map + chat panel side-by-side):
[Sidebar 72px]  [Map 1016px]           [Chat 320px]
      ←───────── centered canvas 1440px ──────────→
```

---

## 5. Shared Components

### 5.1 Sidebar (Side bar — Dark)

```
┌──────┐
│ [Logo] 40×40px
│ ─────  (divider)
│ [Map]  40×40px icon button, p-[8px]
│ [Member] 40×40px
│ [Chat●] 40×40px  ← active: bg-[rgba(88,214,141,0.1)] rounded-[8px]
│         badge: bg-[#D41818] rounded-[90px] 18px, right-[-4px] top-[-4px]
│ [Calendar] 40×40px
│ [Notif] 40×40px
│
│ ─────  (divider)
│ [Help] 40×40px
│ [Setting] 40×40px
│ ─────  (divider)
│ [Avatar] 40×40px rounded-[90px]
└──────┘
```

**Specs:**
- Container: `w-[72px] h-[1024px] bg-[#242B32] flex flex-col items-center justify-between p-[16px]`
- Icon button inactive: `flex items-center p-[8px] rounded-[8px] w-[40px]`, icon `size-[24px]`
- Icon button active: `bg-[rgba(88,214,141,0.1)] flex gap-[8px] items-center p-[8px] rounded-[8px]`
- Unread badge: `absolute bg-[#D41818] flex flex-col items-center justify-center p-px rounded-[90px] right-[-4px] top-[-4px]`
- Badge text: `font-medium text-[10px] leading-[14px] text-white w-[16px] text-center`

---

### 5.2 Chat Panel Header (Half view — DM)

```
┌────────────────────────────────────┐  h = auto, bg-[#2B3540]
│  ← [Avatar 32px] "Name"  Online   [⤢][⋯]  │  px-[12px] py-[16px]
└────────────────────────────────────┘
```

**Specs:**
- Container: `bg-[#2B3540] flex flex-col items-start overflow-clip px-[12px] py-[16px]`
- Inner row: `flex gap-[8px] items-center w-full`
- Back arrow: `size-[16px]` icon
- Avatar: `size-[32px]` rounded-[90px]
- Name text: `text-[14px] leading-[18px] text-white font-normal`
- Status text: `text-[10px] leading-[13px] text-[#8C99A6] tracking-[-0.043px]`
- Expand/More buttons: `bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)] flex items-center justify-center p-[8px] rounded-[6px]`, icon `size-[16px]`

---

### 5.3 Chat Panel Header (Half view — Channel/Group)

```
┌────────────────────────────────────┐
│  ← [#Icon 32px] "Announcements"   [⤢][⋯]
│                  "100 members"            │
└────────────────────────────────────┘
```

**Specs (Channel avatar icon):**
- `bg-[#7EA2FC] flex items-center justify-center overflow-clip p-[4px] rounded-[90px] size-[32px]`
- Inner channel icon: `absolute inset-[20%]` (80% of 32px = ~25.6px)
- Member count: `text-[10px] leading-[13px] text-[#8C99A6] tracking-[-0.043px]`

---

### 5.4 Chat Panel Header (Full view — DM, larger area)

```
┌────────────────────────────────────────────────────────────────────┐
│  [Avatar 32px] "Conan Grey" / "Online"                        [⋯]  │
└────────────────────────────────────────────────────────────────────┘
```
No expand button (already full view). Only "More" (⋯) button.

---

### 5.5 Chat Panel List (Full view)

```
┌────────────────────────────────────┐  w=320px h=992px bg-[#2B3540]
│  "Chat"  Title/Bold 20px      [⤢][+]  │  p-[16px]
│  [Search input h-42px]       [Filter] │
│  ─────────────────────────────────  │
│  📋 Threads Messages           [10]  │  p-[12px], icon 16px
│  ─────────────────────────────────  │
│  Channels  ▲                         │  section title 14px #8C99A6
│  [# Announcements]  10:00  [10]      │  h-[61px] p-[12px]
│  [# Activity Ann.]  09:40  [10]      │
│  [# General]        09:25  [10]      │
│  Groups  ▲                           │
│  [👥 Marketing Team] 10:00  [10]     │  h-[61px]
│  ...                                 │
│  Direct messages  ▲                  │
│  [Avatar Conan Grey] 09:00   ← active: bg-[rgba(88,214,141,0.1)]
│  ...                                 │
│  ─────────────────────────────────  │
│  [▶ Start a new chat]  bg-[#58D68D] │  h-[32px] rounded-[6px]
└────────────────────────────────────┘
```

**Search row specs:**
- Search input: `flex-1 h-[42px] bg-[#242B32] border border-[rgba(255,255,255,0.2)] rounded-[8px] px-[12px] py-[8px]`
- Placeholder: `text-[14px] text-[#636D76] leading-[18px]`
- Filter button: `size-[42px] bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)] rounded-[8px] flex items-center justify-center`
- Search row container: `flex gap-[8px] items-start w-full`

**Section title:**
- `flex items-center justify-between w-full` text `text-[14px] leading-[18px] text-[#8C99A6]`
- Expand chevron: `size-[14px]`

**Chat list item (Channel/Group):**
- `flex flex-col h-[61px] items-start p-[12px] rounded-[8px]`
- Type icon circle: `bg-[#7EA2FC] flex items-center justify-center overflow-clip p-[4px] rounded-[90px] size-[32px]`
- Name: `text-[14px] leading-[18px] text-white`
- Time: `text-[10px] leading-[13px] text-[#8C99A6] tracking-[-0.043px]`
- Last msg: `text-[12px] leading-[15px] font-medium text-white overflow-hidden text-ellipsis tracking-[-0.0516px]`
- Unread badge: `bg-[#D41818] flex flex-col items-center justify-center p-px rounded-[90px]`, text `w-[16px] text-[10px] leading-[14px] font-medium text-white text-center`

**Chat list item (DM):**
- `flex flex-col h-[62px] items-start p-[12px] rounded-[8px]`
- Avatar: `size-[32px]` rounded circle
- Last msg (sent by me): `text-[12px] text-[#8C99A6]` — prefixed with "You: "

**Start new chat button:**
- `bg-[#58D68D] flex gap-[8px] h-[32px] items-center justify-center px-[16px] py-[8px] rounded-[6px] w-full`
- Icon: `size-[16px]` + text `text-[14px] leading-[18px] text-white`

---

### 5.6 Message Bubble

```
[Avatar 32px] "Sender Name"  09:00 AM   [📌]
              "Message text here..."    [✓✓]
              [😊5][🎉1][❤️1]           ← emoji chips
```

**Specs:**
- Row container: `flex gap-[8px] items-start p-[8px]`
- Avatar: `size-[32px]` rounded-[90px]
- Name: `text-[14px] leading-[18px] font-medium text-white`
- Timestamp: `text-[10px] leading-[13px] text-[#8C99A6] tracking-[-0.043px]`
- Message text: `text-[12px] leading-[15px] text-white tracking-[-0.0516px]`
- Status icon (sent/read): `size-[12px]`
- Pin icon: `size-[12px]`
- Read + read count: `size-[12px]` icon + `text-[10px] leading-[13px] text-[#8C99A6]`

---

### 5.7 Time Divider

```
──────────────── Today ────────────────
```

- `flex gap-[8px] items-center justify-center p-[8px] rounded-[90px] w-full`
- Lines: `flex-[1_0_0] h-0` with border-[rgba(255,255,255,0.2)]
- Text: `text-[10px] leading-[13px] font-semibold text-[#8C99A6] tracking-[-0.043px]`

---

### 5.8 Input Message Box

```
┌────────────────────────────────────┐  h=138px, p-[8px]
│ ┌──────────────────────────────┐   │
│ │  Message                     │   │  bg-[#2B3540] rounded-[16px] p-[12px]
│ │                              │   │
│ │  [📎][🖼][😊]          [▶]   │   │
│ └──────────────────────────────┘   │
└────────────────────────────────────┘
```

**Specs:**
- Outer: `flex flex-col h-[138px] items-start p-[8px]`
- Inner: `bg-[#2B3540] flex flex-[1_0_0] flex-col items-start justify-between p-[12px] rounded-[16px] w-full`
- Placeholder: `text-[14px] leading-[18px] text-[#8C99A6]`
- Icon bar: `flex items-center justify-between w-full`
- Icons (attach/image/emoji): `size-[16px]` each, gap-[8px]
- Send button: `bg-[#58D68D] flex items-center justify-center p-[8px] rounded-[6px]`, icon `size-[16px]`

---

### 5.9 Chat Context Menu

```
┌──────────────────────────────────────┐  Emoji panel: w=full, h=32px
│ 👋  ❤️  🎉  👍  🤣  👏  💯  [+]    │  bg-[#242B32] rounded-[8px] p-[8px] gap-[8px]
└──────────────────────────────────────┘

┌──────────────────┐  w=184px, rounded-[16px], p-[8px]
│ ← Reply          │  min-h=42px, p-[12px]  ← active: bg-[rgba(255,255,255,0.1)]
│ 📋 Copy          │
│ 📌 Pin           │
│ → Forward        │
│ ○ Select         │
│ ──────────────── │  divider
│ 🗑 Delete        │  text-[#F03A3A]
└──────────────────┘  shadow: 0px 4px 16px rgba(255,255,255,0.08)
```

**Specs:**
- Wrapper: `flex flex-col gap-[5px] items-center`
- Emoji panel: `bg-[#242B32] flex gap-[8px] items-center p-[8px] rounded-[8px]`, each emoji `size-[16px]`
- Submenu: `bg-[#242B32] flex flex-col gap-[8px] items-start overflow-clip p-[8px] rounded-[16px] shadow-[0px_4px_16px_0px_rgba(255,255,255,0.08)] w-[184px]`
- Menu item inactive: `flex flex-col items-start min-h-[42px] p-[12px] rounded-[8px] w-full`
- Menu item active: same + `bg-[rgba(255,255,255,0.1)]`
- Menu item inner: `flex gap-[8px] items-center`, icon `size-[16px]`, text `text-[14px] leading-[18px] text-white flex-1`
- Delete text: `text-[#F03A3A] text-[14px]`

---

### 5.10 Emoji Reaction Bar

```
[😊 5] [🎉 1] [❤️ 1] [🤣 1] [😪 1] ...
```

**Specs:**
- Row: `flex gap-[4px] items-start`
- Chip (own/active): `bg-[rgba(88,214,141,0.2)] flex gap-[4px] items-center px-[4px] py-[2px] rounded-[90px]`
- Chip (others): `bg-[rgba(255,255,255,0.1)] flex gap-[4px] items-center px-[4px] py-[2px] rounded-[90px]`
- Emoji icon: `size-[14px]`
- Count: `text-[12px] leading-[15px] text-white tracking-[-0.0516px]`

---

### 5.11 Notification Toast

```
┌──────────────────────────────────────────────────────┐  322×124px
│ 🔔  "Chat Message"                                   │  x=1094, y=24
│     "Conan Grey: Do you have a free time on 1 PM?"  │
│     [09:00 AM]                                       │
└──────────────────────────────────────────────────────┘
```

- Position: `absolute top-[24px] right` (x=1094 in 1440px canvas ≈ right-[322px])
- Dimensions: `w-[322px] h-[124px]`

---

### 5.12 Reaction Modal

```
┌─────────────────────────────────┐  366×464px
│ "20 Reactions"           [✕]   │  x=532, y=220 in canvas
│ ────────────────────────────── │  bg-[#242B32] rounded-[16px] p-[16px]
│ 😊  [Avatar] Conan Grey        │  shadow: 0px 4px 16px rgba(255,255,255,0.08)
│               Available        │
│ 😊  [Avatar] ...               │
│ ...                            │  scrollbar: w-[6px] bg-[rgba(255,255,255,0.2)]
│                                │            rounded-[90px] h-[64px] right-0 top-[56px]
└─────────────────────────────────┘
```

**Specs:**
- Modal: `bg-[#242B32] flex flex-col gap-[8px] items-start overflow-clip p-[16px] rounded-[16px] shadow-[0px_4px_16px_0px_rgba(255,255,255,0.08)] w-[366px] h-[464px]`
- Title: `text-[14px] leading-[18px] text-white`
- Close: `absolute right-[16px] top-[16px] size-[16px]`
- Row: `flex items-center px-[8px]`, emoji `size-[16px]`
- Member row: `flex flex-[1] gap-[8px] items-center justify-center p-[12px] rounded-[8px]`
  - Avatar: `size-[32px]`
  - Name: `text-[14px] leading-[18px] font-medium text-white`
  - Status: `text-[12px] leading-[15px] text-[#8C99A6] tracking-[-0.0516px]`
- Scrollbar: `absolute bg-[rgba(255,255,255,0.2)] h-[64px] right-0 rounded-[90px] top-[56px] w-[6px]`

---

### 5.13 Preview Image Modal

```
┌──────────────────────────────────────────────────────┐  600×564px
│ "Preview image"                               [✕24px] │  x=420, y=230
│ "View the image in full size."                        │  p-[16px] gap-[16px]
│ ────────────────────────────────────────────────────  │
│ ┌────────────────────────────────────────────────┐   │  h=320px rounded-[16px]
│ │  [Image 56px preview, full-size view]           │   │  flex items-center justify-center
│ │                        [100% [—][progress][+]] │   │  zoom ctrl: bottom-right
│ └────────────────────────────────────────────────┘   │
│ ┌────┐┌────┐┌────┐┌────┐┌────┐  ← 56×56px thumbnails│  flex-wrap gap-[8px]
│ │ ●  ││    ││    ││    ││    ││  ← selected: border-2 border-[#58D68D]
│ └────┘└────┘└────┘└────┘└────┘                      │
│ [Delete ❌]                                 [Done ✅] │  h-[42px] buttons
└──────────────────────────────────────────────────────┘
```

**Specs:**
- Modal: `bg-[#242B32] flex flex-col gap-[16px] items-start overflow-clip p-[16px] rounded-[16px] shadow-[0px_4px_16px_0px_rgba(255,255,255,0.08)] w-[600px] h-[564px]`
- Title: `text-[20px] leading-normal font-semibold text-white`
- Subtitle: `text-[14px] leading-[18px] text-[#8C99A6] w-[392px]`
- Close: `size-[24px]`
- Image area: `flex gap-[8px] h-[320px] items-center justify-center rounded-[16px] w-full`
- Zoom control: `absolute bottom-[8px] right-[8px] bg-[#1A1B1E] border border-[rgba(255,255,255,0.2)] flex gap-[4px] h-[30px] items-center justify-center px-[8px] py-[6px] rounded-[6px]`
  - Zoom text: `text-[14px] text-white w-[38px]`
  - Progress bar: `w-[80px] h-[8px]`
  - Icons: `size-[16px]`
- Thumbnail: `size-[56px] rounded-[8px]` (inactive) / `border-2 border-[#58D68D] rounded-[8px] size-[56px]` (active)
- Scrollbar: `absolute bg-[rgba(255,255,255,0.2)] h-[64px] right-0 rounded-[90px] top-[56px] w-[6px]`
- Delete button: `bg-[rgba(240,58,58,0.1)] border border-[rgba(240,58,58,0.2)] flex gap-[8px] h-[42px] items-center justify-center px-[16px] py-[8px] rounded-[8px]`, text `text-[#F03A3A] text-[16px] leading-[22px]`
- Done button: `bg-[#58D68D] flex gap-[8px] h-[42px] items-center justify-center px-[16px] py-[8px] rounded-[8px]`, text `text-white text-[16px] leading-[22px]`

---

### 5.14 Search Filter Panel

```
┌──────────────────────────────────────┐  340×382px
│ "Search filter"               [✕24px] │  x=550, y=321
│ ─────────────────────────────────── │  p-[16px] gap-[16px]
│ Sender                               │
│ ┌──────────────────────────────────┐ │  h=42px input
│ │ [Avatar 24px] Conan Grey      ⌄  │ │  bg-[#242B32] border rounded-[8px]
│ └──────────────────────────────────┘ │
│ Chat type                            │
│ ┌──────────────────────────────────┐ │  h=42px
│ │ Please select chat type        ⌄  │ │  placeholder #636D76
│ └──────────────────────────────────┘ │
│ Date range                           │
│ ┌──────────────────────────────────┐ │  h=42px
│ │ DD/MM/YYYY - DD/MM/YYYY        ⌄  │ │
│ └──────────────────────────────────┘ │
│ [Clear all ❌]    [Cancel] [Apply ✅] │  all h-[42px]
└──────────────────────────────────────┘
```

**Specs:**
- Modal: `bg-[#242B32] flex flex-col gap-[16px] items-start overflow-clip p-[16px] rounded-[16px] shadow-[0px_4px_16px_0px_rgba(255,255,255,0.08)] w-[340px] h-[382px]`
- Title: `text-[16px] leading-[22px] font-medium text-white`
- Close: `size-[24px]`
- Field label: `text-[14px] leading-[18px] text-white w-full`
- Dropdown input: `bg-[#242B32] border border-[rgba(255,255,255,0.2)] flex gap-[8px] h-[42px] items-center px-[12px] py-[8px] rounded-[8px] w-full`
  - Placeholder: `text-[14px] leading-[18px] text-[#636D76] flex-1`
  - Chevron: `size-[16px]`
  - With value (sender): avatar `size-[24px]` + name `text-[14px] font-medium text-white`
- Clear all button: `bg-[rgba(240,58,58,0.05)] border border-[rgba(240,58,58,0.5)] flex gap-[8px] h-[42px] items-center justify-center px-[16px] py-[8px] rounded-[8px]`, text `text-[#F03A3A] text-[16px] leading-[22px]`
- Cancel button: `bg-white flex gap-[8px] h-[42px] items-center justify-center px-[16px] py-[8px] rounded-[8px]`, text `text-[#1A1B1E] text-[16px] leading-[22px]`
- Apply button: `bg-[#58D68D] flex gap-[8px] h-[42px] items-center justify-center px-[16px] py-[8px] rounded-[8px]`, text `text-white text-[16px] leading-[22px]`

---

## 6. Per-Scenario Specs

---

### SC-CHAT-01 — Direct Message (DM)

> Figma node: `1977-1359172` | File: `Map8gX0L2hk7HnkaFRfhtj`
> Figma URL: `https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj?node-id=1977-1359172`

**Layout: Half view (chat panel over map)**

```
1440×1024px canvas
├── [Sidebar 72px] left-0 top-0 h-1024px
├── [Map/BG area] left offset, top-[16px], w-1016px h-992px rounded-[16px]
└── [DM Chat Panel] right-[1048px] top-[16px] w-320px h-992px rounded-[16px]
    ├── Header: bg-[#2B3540] px-[12px] py-[16px]
    │   ← back arrow + Avatar(32px) + "Conan Grey" / "Online" + [⤢][⋯]
    └── Body: bg-[#344354] flex-col justify-between
        ├── Message list area (scrollable) p-[8px] gap-[16px]
        │   ├── Time divider: "Today"
        │   └── Message bubble (others)
        └── Input box h-[138px] p-[8px]
```

**Layout: Full view (no map)**

```
1440×1024px canvas
├── [Sidebar 72px]
├── [Chat Panel List] right-[1048px] top-[16px] w-320px h-992px bg-[#2B3540] rounded-[16px]
│   ├── Title "Chat" (20px bold) + [⤢][+]
│   ├── Search + Filter row
│   ├── Threads section
│   ├── Channels section (collapsible)
│   ├── Groups section (collapsible)
│   ├── Direct messages section (collapsible)
│   │   └── Active DM: bg-[rgba(88,214,141,0.1)]
│   └── "Start a new chat" button
└── [Chat Area] right-[16px] top-[16px] w-1016px h-992px rounded-[16px]
    ├── Header: bg-[#2B3540] Avatar + Name + "Online" + [⋯]
    └── Body: bg-[#344354]
        ├── Messages (scrollable)
        └── Input box h-[138px]
```

**Business Rules:**
- Chat panel toggled with sidebar Chat icon
- Half view: overlay on top of virtual office map
- Full view: map hidden, chat panel list + message area
- DM context menu: Reply, Copy, Pin, Forward, Select, [Mark as read, Hide message, Mute, Delete] (DM-specific)
- Message seen = double blue checkmarks, unseen = single checkmark
- Pin shows 📌 icon on message (12×12px), tap navigates to pinned message

---

### SC-CHAT-02 — Proximity Chat Enter

> Figma node: `2012-260260` | File: `Map8gX0L2hk7HnkaFRfhtj`

**Layout:**

```
1440×1024px canvas (map view)
├── [Sidebar 72px]
├── [Virtual Office Map area]
│   └── [Proximity circle] 200×170px centered on cluster of avatars
│       └── Auto-opens chat panel when user walks into circle
└── [Proximity Chat Panel] overlaid (same as DM half-view panel)
    ├── Header: "Proximity Chat" + member count
    └── Notification: "You joined a proximity chat"
```

**Proximity Circle specs:**
- Circle: `w-[200px] h-[170px]` ellipse/dashed border
- Max participants: 20 people
- No chat history (ephemeral — no record saved)
- User walks ON TOP of circle to enter (not through)

**Waving hand icon** (shown when another user is nearby):
- `w-[32px] h-[32px]` positioned x=808, y=712 in canvas

---

### SC-CHAT-03 — Proximity Chat Leave

> Figma node: `2012-406483` | File: `Map8gX0L2hk7HnkaFRfhtj`

**Layout:** Same map view as SC-CHAT-02

**Business Rules:**
- User leaves proximity circle: stays at current position
- Will NOT re-enter proximity chat automatically
- Chat panel closes, user returns to normal map view
- Notification toast shown: user left proximity chat

---

### SC-CHAT-04 — Channel Chat

> Figma node: `2017-446920` | File: `Map8gX0L2hk7HnkaFRfhtj`
> Channels — Half view node: `2006-199494`

**Layout: Half view (channel on map)**

```
1440×1024px canvas
├── [Sidebar 72px]
├── [Map area] right side, w-1016px
└── [Channel Chat Panel] left overlay, w-320px h-992px
    ├── Header: ← [#Icon bg-[#7EA2FC] 32px] "Announcements" / "100 members" + [⤢][⋯]
    └── Body: bg-[#344354]
        ├── Channel info section:
        │   ├── [#] Channel name (14px bold)
        │   ├── Description text (12px/15px white)
        │   └── Numbered list items (12px/15px white)
        ├── Message bubbles (with read receipt + read count)
        │   └── Read count shown as "✓✓ 10" (icon 12px + text 10px #8C99A6)
        └── Input box
```

**Channel Icon (32px in header, 40px in list):**
- `bg-[#7EA2FC] flex items-center justify-center overflow-clip p-[4px] rounded-[90px] size-[32px]`
- Channel symbol inside: `absolute inset-[20%]`

**Channel vs DM differences:**
- Channel: shows channel icon (blue circle) instead of avatar
- Channel: shows member count instead of online status
- Channel: no "Hide message" in context menu
- Channel: shows read count (e.g. "✓✓ 10") instead of individual seen status

---

### SC-CHAT-05 — Group Chat

> Figma node: `2081-35462` | File: `Map8gX0L2hk7HnkaFRfhtj`

**Layout:** Same structure as Channel (Half/Full view)

**Group Icon (in header/list):**
- `bg-[#7EA2FC] flex items-center justify-center overflow-clip p-[4px] rounded-[90px] size-[32px]`
- Member/people icon inside: `absolute inset-[20%]`

**Create Group Modal:**
```
┌──────────────────────────────────────┐  336×90px toast notification
│ "Group created"                      │  x=1080, y=24
│ "Marketing Team group has been..."  │
└──────────────────────────────────────┘
```

**Business Rules:**
- Group icon: people icon (not channel #)
- No "Hide message" in context menu (same as Channel)
- Admin can add/remove members

---

### SC-CHAT-06 — Thread Replies

> Figma node: `2096-1032317` | File: `Map8gX0L2hk7HnkaFRfhtj`

**Layout:**

```
[Chat Panel List 320px] ← normal list
                         [Thread Panel 320px] ← slides in from right over message area
                                               ├── Header: "Thread" + close [✕]
                                               ├── Original message (quoted)
                                               ├── "── 3 Replies ──"
                                               ├── Reply messages
                                               └── Reply input box
```

**Thread access:**
- Context menu → "Reply" opens thread panel
- "Threads Messages" in chat list → shows all threads with unread count
- Thread panel replaces or overlays the message area

**Threads row in chat list:**
- Icon: threads/stack icon `size-[16px]`
- Text: "Threads Messages" `text-[14px] leading-[18px] text-white`
- Badge: `bg-[#D41818] rounded-[90px]` unread count

---

### SC-CHAT-07 — Emoji Reaction

> Figma node: `2096-1559539` | File: `Map8gX0L2hk7HnkaFRfhtj`
> Chat menu node: `2096-1035517`

**Flow:**
1. Hover/long-press message → Context menu appears
2. Emoji panel (top of menu): 7 preset emojis + [+] to open full emoji picker
3. Tap emoji → adds reaction chip below message
4. Tap own reaction → removes it
5. Tap reaction chip count → opens Reaction Modal (366×464px)

**Emoji panel (context menu top):**
- `bg-[#242B32] flex gap-[8px] items-center p-[8px] rounded-[8px]`
- 8 items: 👋 ❤️ 🎉 👍 🤣 👏 💯 [+], each `size-[16px]`

**Reaction chips:**
- Active (own): `bg-[rgba(88,214,141,0.2)] flex gap-[4px] items-center px-[4px] py-[2px] rounded-[90px]`
- Others: `bg-[rgba(255,255,255,0.1)]` same padding
- Icon: `size-[14px]`, count: `text-[12px]`

**Reaction Modal** (see section 5.12):
- Shows "X Reactions" title + list of who reacted
- Scrollable, max 20 reaction types
- Close button: `size-[16px]` top-right corner

---

### SC-CHAT-08 — File / Image Attachment

> Figma node: `2100-1943316` | File: `Map8gX0L2hk7HnkaFRfhtj`

**Upload flow:**
1. Click 📎 (attach) or 🖼 (image) icon in input box
2. File picker opens (OS native)
3. After selection: preview thumbnails appear above input box
4. Send button sends with attachments

**Preview Image Modal** (after clicking sent image in message):
```
┌──────────────────────────────────────────────────────┐  600×564px, x=420, y=230
│ "Preview image"                               [✕]    │  (see section 5.13 for full spec)
│ "View the image in full size."                        │
│ [Image area 320px tall with zoom control]            │
│ [Thumbnails: 56×56px each, up to 5]                  │
│ [Delete]                              [Done]          │
└──────────────────────────────────────────────────────┘
```

**Preview File Modal:**
```
┌──────────────────────────────────────────────────────┐  600×578px, x=420, y=223
│ "Preview file"                                [✕]    │
│ "Filename.pdf  (2.4 MB)"                             │
│ [File preview area or icon]                          │
│ [Delete]                         [Download] [Done]   │
└──────────────────────────────────────────────────────┘
```

**Business Rules:**
- Max 5 files per message
- Supported image formats: JPG, PNG, GIF, WEBP
- Unsupported formats: grayed out in file picker
- File icons shown in message instead of image preview for non-images

---

### SC-CHAT-09 — File Limit / Error

> Figma node: `2122-70963` | File: `Map8gX0L2hk7HnkaFRfhtj`

**Error state:**
```
┌──────────────────────────────────────────────────────┐  600×368px, x=420, y=328
│ "File upload error"                           [✕]    │  shorter modal (no image preview)
│ ─────────────────────────────────────────────────── │
│                                                       │
│  ⚠️  "You can only attach up to 5 files."             │
│       or                                              │
│      "File format not supported."                     │
│                                                       │
│                                              [OK]     │
└──────────────────────────────────────────────────────┘
```

**Specs:**
- Modal: `w-[600px] h-[368px]` (vs normal 578px — shorter, no crop/preview area)
- Same bg/rounded/padding as normal file modal

---

### SC-CHAT-10 — Unread Messages & Notifications

> Figma node: `2138-799995` | File: `Map8gX0L2hk7HnkaFRfhtj`

**Notification Toast:**
```
┌──────────────────────────────────────────────────────┐  322×124px, x=1094, y=24
│ [Avatar] "Conan Grey"          09:00 AM              │  top-right corner
│           "Do you have a free time on 1 PM?"         │
│           [DM]  [Dismiss]                            │
└──────────────────────────────────────────────────────┘
```

**User Status Panel** (unread indicator):
```
┌──────────────────────────────────────────────────────┐  322×310px, x=1094, y=24
│ [Avatar] "Conan Grey"                                │
│           "Online"                                   │
│ ─────────────────────────────────────────────────── │
│ Chat  Calendar  [...]                                │
│ ─────────────────────────────────────────────────── │
│ [Unread messages list]                               │
└──────────────────────────────────────────────────────┘
```

**Unread badges:**
- Sidebar chat icon: `absolute bg-[#D41818] flex flex-col items-center justify-center p-px right-[-4px] rounded-[90px] top-[-4px]`, text `w-[16px] text-[10px] leading-[14px] font-medium text-white text-center`
- Max displayed: "99+" (not +99 or 100)
- Chat list item: same badge component, right side of row

**Unread message separator:**
- Shown inline in message list: "── N unread messages ──" (same time divider pattern)

---

### SC-CHAT-11 — Message Search

> Figma node: `2162-83837` | File: `Map8gX0L2hk7HnkaFRfhtj`

**Search input (in chat list panel, Full view):**
- `h-[42px] bg-[#242B32] border border-[rgba(255,255,255,0.2)] rounded-[8px] px-[12px] py-[8px]`
- Placeholder: "Search for chat or message" `text-[#636D76]`
- Paired with filter button (size-[42px]) to its right

**Search Filter Panel** (340×382px — see section 5.14):

**Filter fields:**
1. **Sender** — dropdown showing avatar + name, pulls from workspace members
2. **Chat type** — dropdown: All / Direct Message / Channel / Group / Proximity
3. **Date range** — date picker DD/MM/YYYY - DD/MM/YYYY (311×302px picker appears)

**Date picker:**
```
┌───────────────────────────────────┐  311×302px, x=563, y=637
│   <  June 2026  >                 │
│   Su Mo Tu We Th Fr Sa            │
│   ...calendar grid...             │
└───────────────────────────────────┘
```

**Sender dropdown (expanded):**
```
┌───────────────────────────────────┐  308×173px to 413px (variable), x=566, y=469
│ [Avatar] Conan Grey               │  bg-[#242B32] border rounded-[8px]
│ [Avatar] Taylor Swift             │
│ ...                               │
└───────────────────────────────────┘
```

**Business Rules:**
- No filter selection = search all chat types
- Search highlights matching text in results
- Results show chat type + sender + date

---

### SC-CHAT-12 — Typing Indicator

> Figma node: `2151-1217508` | File: `Map8gX0L2hk7HnkaFRfhtj`

**Layout:**

```
[Message area]
...previous messages...
[Avatar 32px] Conan Grey is typing...  ●●●
```

**Typing indicator specs:**
- Row: `flex gap-[8px] items-center p-[8px]`
- Avatar: `size-[32px]` rounded
- Text: `text-[12px] leading-[15px] text-[#8C99A6]` — italic or regular, "X is typing..."
- Animated dots: 3 bouncing dots (CSS animation)

**Business Rules:**
- Disappears after 3 seconds of inactivity OR message is cleared
- 1–2 people: "Name is typing..." / "Name1 and Name2 are typing..."
- 3+ people: "X people are typing..."
- Only shown in DM / Group / Channel where user is participant

---

## 7. Component Sizing Reference

| Component | Width | Height | Node ID |
|---|---|---|---|
| Canvas | 1440px | 1024px | — |
| Sidebar | 72px | 1024px | — |
| Chat panel (Half/both) | 320px | 992px | — |
| Chat list (Full view) | 320px | 992px | — |
| Chat area (Full view) | 1016px | 992px | — |
| Map area (Half view) | 1016px | 992px | — |
| Chat panel header | 320px | auto | — |
| Input message box | 320px (or full) | 138px | 2006:101135 |
| Notification toast | 322px | 124px | 1977:1362093 |
| Toast (create group) | 336px | 90px | — |
| Toast (action) | 336px | 72px | — |
| Submenu (short) | 184px | 200px | — |
| Submenu (default) | 184px | 284px | — |
| Submenu (pin extended) | 184px | 368px | — |
| Chat menu wrapper | 200px | 321px | 2096:1035517 |
| Emoji panel | 200px | 32px | — |
| Preview image modal | 600px | 564px | 2122:70914 |
| Preview file modal | 600px | 578px | — |
| Preview file error modal | 600px | 368px | — |
| Upload image modal | 459px | 574px | — |
| Reaction modal | 366px | 464px | 2096:1573016 |
| Search filter panel | 340px | 382px | 2176:178007 |
| Date picker | 311px | 302px | — |
| Sender dropdown | 308px | 173–413px | — |
| Emoji reaction bar | auto | 19px | 2141:808931 |
| Emoji chip (compact) | auto | 19px | — |
| Proximity circle | 200px | 170px | — |
| Waving hand icon | 32px | 32px | — |
| User status panel | 322px | 310px | — |
| Avatar (profile) | 32px | 32px | — |
| Avatar (sidebar) | 40px | 40px | — |
| Channel/Group icon | 32px (header) / 40px (list) | — | 1995:1627490 |
| Nav icon area | 40px | 40px | — |
| Expand/More button | 32px | 32px | — |

---

## 8. Figma Node Index

| Scenario | Node ID | Description |
|---|---|---|
| SC-CHAT-01 | `1977-1359172` | Send Direct Message |
| SC-CHAT-02 | `2012-260260` | Proximity Chat Enter |
| SC-CHAT-03 | `2012-406483` | Proximity Chat Leave |
| SC-CHAT-04 | `2017-446920` | Global / Channel Chat |
| SC-CHAT-05 | `2081-35462` | Group Chat |
| SC-CHAT-06 | `2096-1032317` | Thread Replies |
| SC-CHAT-07 | `2096-1559539` | Emoji Reaction |
| SC-CHAT-08 | `2100-1943316` | File / Image Attachment |
| SC-CHAT-09 | `2122-70963` | File Limit / Error |
| SC-CHAT-10 | `2138-799995` | Unread & Notification |
| SC-CHAT-11 | `2162-83837` | Message Search |
| SC-CHAT-12 | `2151-1217508` | Typing Indicator |
| DM Half view | `2006-100547` | Direct message — Half view (main frame) |
| DM Full view | `2006-199495` | Direct message — Full view (main frame) |
| Channels Half | `2006-199494` | Channels — Half view |
| Chat menu | `2096-1035517` | Chat context menu (emoji panel + submenu) |
| Reaction modal | `2096-1573016` | Reaction detail modal |
| Preview image | `2122-70914` | Preview image modal |
| Search filter | `2176-178007` | Search filter panel |
| Emoji bar | `2141-808931` | Emoji reaction bar (chips) |

---

## 9. Implementation Notes

> **Codebase Alignment (v1.1)**: ไฟล์/route ในส่วนนี้เป็นเป้าหมายที่ยังต้องสร้างใหม่ (NEW) ตาม convention จริง — REST helpers ให้สร้างใน `lib/api/chat.ts` (ใช้ `authFetch` จาก `lib/api/client.ts`), ส่วน chat WS ให้ extend `WorkspaceWSClient` ใน `lib/api/workspace-ws.ts` (ซึ่งมี `chat(content)` อยู่แล้ว) แทนการสร้าง `lib/ws/chat-ws.ts`. หน้า chat ใหม่เพิ่มเป็น route ใหม่ + พิจารณา `PUBLIC_PATHS` ใน `components/auth-guard.tsx`.

### File structure (zyra-app)

```
views/chat/
  hero-chat.tsx               # top-level view, controls half/full mode
  chat-panel-list.tsx         # left sidebar panel (list of chats)
  chat-message-area.tsx       # right message area
  components/
    chat-header-dm.tsx        # DM header
    chat-header-channel.tsx   # Channel/Group header
    message-bubble.tsx        # single message row
    input-message.tsx         # input box
    time-divider.tsx          # "Today" divider
    emoji-reaction-bar.tsx    # reaction chips row
    chat-context-menu.tsx     # hover menu: emoji panel + submenu
    reaction-modal.tsx        # reaction detail modal
    preview-image-modal.tsx   # image preview modal
    preview-file-modal.tsx    # file preview modal
    search-filter.tsx         # search filter panel
    typing-indicator.tsx      # typing dots
    notification-toast.tsx    # push notification toast
    proximity-circle.tsx      # proximity zone overlay on map

lib/api/chat.ts               # (NEW) REST helpers → /api/user/* (ใช้ authFetch จาก lib/api/client.ts)
                              # chat WS: extend WorkspaceWSClient ใน lib/api/workspace-ws.ts (มี chat(content) อยู่แล้ว)
```

### API Endpoints (all via `/api/user/*`)

```
GET  /api/user/chats                    → list all DM/Channel/Group
GET  /api/user/chats/:id/messages       → message history (paginated)
POST /api/user/chats/:id/messages       → send message
POST /api/user/chats/:id/messages/:msgId/reactions  → add/toggle emoji
GET  /api/user/chats/:id/messages/search → search with filters
WS   /api/user/ws                       → real-time (typing, new messages)
```

### Key Tailwind Patterns

```tsx
// Chat panel container (Half view)
"absolute content-stretch flex flex-col h-[992px] items-start overflow-clip right-[1048px] rounded-[16px] top-[16px] w-[320px]"

// Chat header (DM)
"bg-[#2b3540] content-stretch flex flex-col items-start overflow-clip px-[12px] py-[16px]"

// Message area
"bg-[#344354] content-stretch flex flex-[1_0_0] flex-col items-center justify-between min-h-px overflow-clip"

// Input box container
"content-stretch flex flex-col h-[138px] items-start p-[8px] rounded-[16px]"

// Input inner
"bg-[#2b3540] content-stretch flex flex-[1_0_0] flex-col items-start justify-between min-h-px p-[12px] rounded-[16px] w-full"

// Chat list item (active)
"bg-[rgba(88,214,141,0.1)] content-stretch flex flex-col h-[62px] items-start p-[12px] rounded-[8px]"

// Chat list item (inactive)
"content-stretch flex flex-col h-[61px] items-start p-[12px] rounded-[8px]"

// Unread badge
"bg-[#d41818] content-stretch flex flex-col items-center justify-center p-px rounded-[90px]"
// badge text: "font-medium leading-[14px] text-[10px] text-center text-white w-[16px]"

// Channel avatar
"bg-[#7ea2fc] content-stretch flex items-center justify-center overflow-clip p-[4px] rounded-[90px] size-[32px]"

// Context menu shadow
"shadow-[0px_4px_16px_0px_rgba(255,255,255,0.08)]"

// Icon buttons (expand/more)
"bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)] content-stretch flex items-center justify-center p-[8px] rounded-[6px]"
```
