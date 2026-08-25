# Chat — Figma Implementation Spec (play-page rebuild)

> Full Figma deep-read of all non-proximity scenarios (2026-06-29). Source of truth for rebuilding chat as a play-page overlay (half-view + full-view).

## Architecture summary (TH)

แชตจะถูกย้ายจาก route แยก (`/workspace/[id]/chat` ที่เป็น `HeroChat` แล้ว `router.push` ออกจากแมป) มาเป็น overlay ภายในหน้า play (`/workspace/[id]/play` = `hero-virtual-office.tsx`) โดยไม่ unmount Pixi/Phaser canvas เลย

โครงสร้าง: เพิ่ม state `chatView: "closed" | "half" | "full"` ในhero-virtual-office. แก้ `handleTabChange` ให้ tab `"chat"` ไม่ `router.push` อีกต่อไป แต่ toggle `chatView` (closed → half, คลิกซ้ำ → closed) แทน — VOSidebar เดิม (rail 56px) ใช้ต่อ ตั้ง `activeTab="chat"` ตอนเปิด พร้อมเพิ่ม red unread badge ที่ icon Chat

Half-view: panel กว้าง 320px เป็น absolute overlay ซ้อนซ้ายของแมป (anchor `left-[56px] top-[16px] bottom-[16px]`, ภายใน wrapper `pointer-events-auto`) เหมือน pattern ของ VOMemberPanel ที่มีอยู่แล้ว — แมป + HUD (cam/mic/share/emoji) + minimap ยังเห็นและกดได้ทางขวา ปุ่ม Expand ในheader สลับเป็น full

Full-view: ปุ่ม Expand → `chatView="full"` ซ่อนแมป (overlay เต็มจอ z สูง คลุม canvas) เป็น 3 คอลัมน์ rail(56) + list(320) + message area(flex-1); ปุ่ม collapse กลับ half คืนแมป

สิ่งที่เปลี่ยนจาก build ปัจจุบัน: component ใน `views/chat/*` (ChatSidebar, DmPanel, ChannelPanel, ThreadPanel, message-list, message-input, search-panel, reaction-modal, file-error-modal, create-group-modal, notification-bell, typing-indicator ฯลฯ) reuse ได้เกือบทั้งหมด แต่ wrapper เดิม `HeroChat` (route) ถูกแทนด้วย overlay controller ใหม่ใน play page ที่จัดการ half↔full, ใช้ `wsClient` จาก `useVOSessionStore` ที่มีอยู่แล้ว (ไม่ต้องสร้าง WS ใหม่), และเรียก API ผ่าน `/api/user/*` ตาม member-API-separation. ไม่มี `router.push` ไป /chat อีก; route /chat คงไว้เป็น fallback/deep-link ได้แต่ไม่ใช่ทางเข้าหลัก

---

# Zyra Chat — Master Implementation Spec (Play-Page Overlay)

> Rebuild target: the Zyra Chat UI as an **overlay inside the Virtual Office play page** (`/workspace/[id]/play` → `views/user/virtual-office/hero-virtual-office.tsx`), **not** a separate `/chat` route. Pixel-faithful (95–100%) to Figma. All colors are exact hex, all sizes exact px, all icons from `lucide-react`, all UI Tailwind-only (no shadcn). Member-facing data via `/api/user/*` only.

---

## 0. Design Tokens (single source of truth)

### Colors
| Token | Hex / rgba | Usage |
|---|---|---|
| Background/Primary | `#242B32` | page bg, chat-list panel inputs, popovers, nav rail (Figma) |
| Background/Secondary | `#2B3540` | chat panel bg, header bg, message input inner, file cards |
| Theme/Tertiary | `#344354` | message-body scroll area bg |
| Rail dark (impl) | `#1A1B1E` | nav rail bg in current build (`VOSidebar`), minimap bg, toast bg |
| Primary/500 | `#58D68D` | primary buttons, Send, active accents, progress fill |
| Primary/10% | `rgba(88,214,141,0.1)` | active nav item bg, selected chat row bg |
| Primary/20% | `rgba(88,214,141,0.2)` | selected reaction chip bg, success toast icon bg |
| Primary hover (impl) | `#4dc47d` | green button hover (project convention) |
| Purple/500 | `#996ADF` | "Me" name-tag on map |
| Grey/500 | `#8C99A6` | secondary text, section headers, "typing", subtitles |
| Grey/700 | `#636D76` | input placeholder text |
| Grey/800 | `#4D545B` | — |
| Grey/200 | `#CAD0D6` | — |
| Red/500 | `#D41818` | unread count badges |
| Destructive | `#F03A3A` | Delete/Leave labels, fail/error text |
| Warn yellow | `#ECC819` | "Unsupported format" tag |
| Info blue | `#2DB6FF` | "Exceed limit file" tag, email links |
| Avatar tints | `#E1ADFF` `#FFA8A8` `#7EA2FC` `#95F7F6` `#FFCEA8` | DM/channel/group avatar circles |
| White/5% | `rgba(255,255,255,0.05)` | ghost-chip button bg |
| White/10% | `rgba(255,255,255,0.1)` | divider, unselected reaction chip, hover row |
| White/20% | `rgba(255,255,255,0.2)` | input borders, button borders, scrollbar |
| White/8% (shadow) | `rgba(255,255,255,0.08)` | popover/menu/modal drop-shadow |
| Scrim | `rgba(0,0,0,0.5)` | full-screen modal scrim (`bg-black/50`) |

### Typography (all **Inter**)
| Style | size / line-height / tracking | weight |
|---|---|---|
| Title | 20px / 25px | Bold |
| Body Regular | 14px / 18px / 0 | Regular |
| Body Medium | 14px / 18px / 0 | Medium |
| Body Bold | 14px / 18px / 0 | Bold |
| Caption1 Regular | 12px / 15px / -0.0516px | Regular |
| Caption1 Medium | 12px / 15px / -0.043px | Medium |
| Caption2 Regular | 10px / 13px / -0.043px | Regular |
| Caption2 Medium | 10px / 14px / 0 | Medium |
| Caption2 Semi | 10px / 13px / -0.043px | SemiBold |

### Radii / sizing
- Panel / message-area / input box / modal: `rounded-[16px]`
- Buttons (chip, send, plus): `rounded-[6px]`
- List rows / menu rows / thumbnails / inputs: `rounded-[8px]`
- Checkbox: `rounded-[4px]`
- Avatars / badges / pills: `rounded-[90px]`
- Avatars: header & message = **32px**; nav user = **40px**; typing-stack = **24px** (1px white border, `mr-[-8px]` overlap); list-row avatar = **32px** (Figma) / 40px in some list frames.
- Half panel width: **320px**. Full message area: fills `flex-1` (Figma 1016px). Thread reply panel (full): **368px**, Threads-Messages middle panel (full): **632px**.

---

## 1. Architecture — Chat as a Play-Page Overlay

### 1.1 What changes vs. the current build
The current code ships chat as a **separate route**:
- `app/workspace/[id]/chat/page.tsx` → `views/chat/hero-chat.tsx` (`HeroChat`), a full-screen `flex h-screen` layout with its **own** `VOSidebar` + `gap-[16px] p-[16px]` two-column body.
- `hero-virtual-office.tsx` `handleTabChange` does `router.push('/workspace/${id}/chat')` for the `"chat"` tab — i.e. it **leaves the map** (unmounts Phaser/Pixi).

**New model:** chat becomes an overlay **inside the play page**, the map is never unmounted.

| Aspect | Current (`/chat` route) | New (play-page overlay) |
|---|---|---|
| Entry | `router.push('/workspace/[id]/chat')` | toggle local `chatView` state in `hero-virtual-office` |
| Mount | separate page, own `VOSidebar`, `flex h-screen` | absolute overlay sibling of Pixi canvas, reuse the page's existing `VOSidebar` |
| Map | unmounted / gone | half-view: visible & interactive; full-view: hidden but mounted |
| WS | re-wires via `useVOSessionStore.getState().wsClient` | reuse the **same** `wsClient` already connected on the play page |
| Half vs full | always "full" 2-column | `half` (320 overlay over map) ↔ `full` (map hidden, multi-column) |

`HeroChat` (the route wrapper) is **replaced** by an overlay controller mounted in the play page. The `views/chat/*` panel components (ChatSidebar, DmPanel, ChannelPanel, ThreadPanel, message-list/-input, search-panel, reaction-modal, file-error-modal, create-group-modal, notification-bell, typing-indicator, etc.) are **reused**; only the outer layout/shell changes. The `/chat` route may remain as a deep-link fallback but is not the primary entry.

### 1.2 New state & triggers (in `hero-virtual-office.tsx`)
```ts
const [chatView, setChatView] = useState<"closed" | "half" | "full">("closed")
```
- **Open**: click the **Chat** icon in `VOSidebar`. In `handleTabChange`, replace the `router.push` branch with:
  - if `tab === "chat"`: `setChatView((v) => (v === "closed" ? "half" : "closed"))`, set `activeTab` to `"chat"` while open (so the rail highlights), collapse other panels.
  - (Other tabs continue to set `activeTab` as today.)
- **Half → Full**: the **Expand** (diagonal-arrows) button in any chat header / list-panel title → `setChatView("full")`.
- **Full → Half**: the **Expand/collapse** button in the full-view list-panel title row → `setChatView("half")`.
- **Close**: the header **chevron-left** (in a conversation) returns to the list; the rail Chat icon toggled again, or `X`, sets `setChatView("closed")` and restores `activeTab` to `"map"`.

### 1.3 Layer / z-order (single 56px-rail composition)
From the play page (matches the existing `pointer-events-none absolute inset-0 z-10 flex` overlay wrapper):
```
z-0   Pixi/Phaser map canvas (PixiGameScene) — full viewport
z-10  VO overlay chrome: nav rail (left), HUD (bottom-center), minimap (bottom-right)
z-50  CHAT PANEL overlay (half) — anchored left of rail, above map; map/HUD/minimap stay interactive
z-50+ CHAT full-view — covers map area (map hidden behind), rail still visible
z-[60] chat sub-popovers (More/context/reaction menus, dropdowns) anchored within chat
z-[70] full-screen modals (upload/preview/file-error/reaction-modal) + bg-black/50 scrim
```
The nav rail is the project's existing `VOSidebar` (56px, `bg-[#1A1B1E]`). Figma draws a 72px rail (40px icons + 16px pad); **keep the existing 56px `VOSidebar`** and anchor the chat panel at `left-[56px]`. (Note this single discrepancy: rail = 56px in code, 72px in Figma.)

### 1.4 Mount snippet (follow the existing VOMemberPanel pattern)
```tsx
{/* inside the z-10 overlay flex, sibling to VOMemberPanel */}
{chatView === "half" && (
  <div className="pointer-events-auto absolute left-[56px] top-[16px] bottom-[16px] z-50">
    <ChatPanelHalf
      workspaceId={workspaceId}
      selfUserId={user?.id}
      wsClient={useVOSessionStore.getState().wsClient}
      onExpand={() => setChatView("full")}
      onClose={() => { setChatView("closed"); setActiveTab("map") }}
    />
  </div>
)}
{chatView === "full" && (
  <div className="pointer-events-auto absolute inset-0 left-[56px] z-50 bg-[#242B32]">
    <ChatViewFull
      workspaceId={workspaceId}
      selfUserId={user?.id}
      wsClient={useVOSessionStore.getState().wsClient}
      onCollapse={() => setChatView("half")}
      onClose={() => { setChatView("closed"); setActiveTab("map") }}
    />
  </div>
)}
```

---

## 2. Half-View Layout (exact)

Composition left → right: **56px nav rail** (existing `VOSidebar`) · **320px chat panel** (overlay) · **map + HUD + minimap** (visible, interactive, to the right).

### 2.1 Chat panel container (half)
- `absolute left-[56px] top-[16px] bottom-[16px]` (Figma: `top-[16px] h-[992px]`), `w-[320px]`, `bg-[#2B3540]`, `rounded-[16px]`, `overflow-hidden`, `flex flex-col`, above the map (`z-50`).
- Inner content width = **288px** (16px padding each side) **only** in the list state; the **conversation** state uses edge-to-edge header/body with their own padding.

### 2.2 Two half-view shells
**(A) Chat-list state** (`ChatSidebar`): `p-[16px] flex-col gap-[16px]`:
1. Title header — `"Chat"` + Expand + Plus.
2. Search row — input (flex-1) + filter button.
3. Scroll list (`flex-1 overflow-y-auto`): Threads row → Channels → Groups → Direct messages → footer "Start a new chat".

**(B) Open-conversation state** (`DmPanel` / `ChannelPanel`): no padding on the panel; two stacked regions:
1. **Header** `bg-[#2B3540]`, `px-[12px] py-[16px]` — chevron-left + avatar + name/subtitle + **Expand** + **More**.
2. **Body** `bg-[#344354]`, `flex-1 flex-col justify-between`:
   - Message scroll region `p-[8px] gap-[16px]` (top: date dividers, info blocks, message rows, typing row).
   - Input box pinned bottom (`h-[138px]`).

Switching content (list ↔ conversation ↔ create-group ↔ settings ↔ members ↔ threads) **swaps panel content only**; the panel position and the map never move.

### 2.3 Map / HUD remain
The PixiGameScene map, bottom-center HUD (camera/mic/screen-share/emoji), right-side map-tools (locate/zoom), avatar name-tags, and bottom-right minimap (`#1A1B1E`, `169×100`, `rounded-[16px]`) all stay rendered and interactive to the right of the panel. Notification toasts render top-right over the map (see §4.11).

---

## 3. Full-View Layout (exact)

Triggered by **Expand**. Map is **hidden** (the full overlay covers it). Composition: **56px rail** · **320px chat-LIST panel** · **wide message area** (`flex-1`, Figma 1016px).

### 3.1 List panel (full)
`absolute top-[16px] bottom-[16px] left-[16px]` (relative to the area right of the rail), `w-[320px]`, `bg-[#2B3540]`, `rounded-[16px]`, `p-[16px] flex-col gap-[16px]`, `overflow-hidden`. Same content as the half-view list state **except** the Expand button now **collapses** to half. Selected row uses `bg-[rgba(88,214,141,0.1)]`.

### 3.2 Message area (full)
`flex-1`, `top-[16px] right-[16px] bottom-[16px]`, `rounded-[16px]`, `flex-col`. Reuses header + body + input:
- **Header (full) differs**: NO chevron-left, NO Expand — only the **More** (3-dot) chip on the right; left = avatar + name + subtitle.
- Body + input identical to half, stretched to full width.

### 3.3 Thread full-view (3 columns)
When a thread is open in full view: list panel (320, `right`-most-left) · **Threads-Messages middle panel** (`w-[632px]`) · **Thread reply panel** (`w-[368px]`, `right-[16px]`). The middle Threads header shows only the **X** (no expand) when the reply panel is open. See §4.8.

---

## 4. Per-Component Specs

> Conventions for all: chip button = `bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)] rounded-[6px] p-[8px]` with a 16px lucide icon. Green button = `bg-[#58D68D] hover:bg-[#4dc47d] rounded-[6px]`. Unread badge = `bg-[#D41818] rounded-[90px] text-white text-[10px] leading-[14px] font-medium min-w-[16px] text-center`.

### 4.1 Nav rail (existing `VOSidebar`, Chat active + unread badge)
- Rail: `w-[56px] bg-[#1A1B1E]`, full height.
- Chat icon active: `bg-[rgba(88,214,141,0.1)] text-[#58D68D] rounded-[10px] size-[40px]`, lucide `MessageCircle` size 20.
- **Add**: red unread badge on the Chat icon — `absolute top-[-4px] right-[-4px] bg-[#D41818] rounded-[90px] min-w-[16px] h-[16px] text-white text-[10px] leading-[14px] font-medium text-center px-[2px]`, value capped at `99+`. (New prop on VOSidebar, e.g. `chatUnread?: number`.)
- Bottom: Help, Settings, divider, user avatar 36–40px with status dot.

### 4.2 Chat header — half (conversation open)
- Container: `bg-[#2B3540] px-[12px] py-[16px] flex items-center justify-between gap-[8px]`.
- **Left** (`flex-1 flex items-center gap-[8px]`):
  - lucide `ChevronLeft` 16px white → back to list (collapse content).
  - Avatar 32×32 `rounded-[90px]` (DM: tinted circle e.g. `#E1ADFF` + sprite + status dot bottom-right at `left-3/4`; Channel: `bg-[#7EA2FC]` + `Hash` glyph; Group: `bg-[#7EA2FC]` + `Users` glyph).
  - Text col `gap-[4px]`: name `text-[14px] leading-[18px] text-white` truncate; subtitle row — DM: `"Online"` `text-[10px] leading-[13px] text-[#8C99A6] tracking-[-0.043px]` (+10px mute glyph); Channel/Group: `"100 members"`.
- **Right** (`flex gap-[8px]`): **Expand** chip (lucide `Maximize2` 16px → full) + **More** chip (lucide `MoreVertical` 16px → submenu §4.6/§4.7).

### 4.3 Chat header — full (message area)
Same `bg-[#2B3540] px-[12px] py-[16px]`. **Drop** chevron-left and Expand. Right side = **only** the More chip. Left = avatar 32 + name + subtitle.

### 4.4 Chat-list panel (list + sections)
- **Title row** (`flex items-center justify-between`): `"Chat"` Title 20/25 Bold white; right `flex gap-[8px]`: **Expand** chip (Maximize2 16) + **Plus** green button `bg-[#58D68D] p-[8px] rounded-[6px]` lucide `Plus` 16 white.
- **Search row** (`flex gap-[8px] items-start`):
  - Input: `flex-1 h-[42px] bg-[#242B32] border border-[rgba(255,255,255,0.2)] rounded-[8px] px-[12px] py-[8px] flex items-center gap-[8px]`. Placeholder `"Search for chat or message"` `text-[14px] leading-[18px] text-[#636D76]` truncate. Active: white text + trailing lucide `X` 16px `text-[#8C99A6]` clear.
  - Filter button: `size-[42px] bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)] rounded-[8px] p-[8px]` lucide `SlidersHorizontal`/`Filter` 16 (active bg `rgba(255,255,255,0.1)`).
- **Threads row**: `flex items-center gap-[8px] p-[12px] w-full` — lucide threads/`MessagesSquare` 16 + `"Threads Messages"` Body white `flex-1` + unread badge `"10"`. Selected state (in Threads view) = `bg-[rgba(88,214,141,0.1)] rounded-[8px]`.
- **Section header (TitleMenu)**: `flex items-center justify-between w-full` (w-288 in list) — label (`"Channels"`/`"Groups"`/`"Direct messages"`, optional `"(50)"`) `text-[14px] leading-[18px] text-[#8C99A6]` + lucide `ChevronUp` 14 `#8C99A6` (collapse). Empty sections still render.
- **Chat-list row**: `flex-col p-[12px] rounded-[8px] w-full h-[61px]` (DM `h-[62px]`), transparent default, **selected** `bg-[rgba(88,214,141,0.1)]`, hover subtle bg.
  - Row inner: `flex items-center gap-[8px]`. Avatar 32 (`rounded-[90px]`): Channel `bg-[#7EA2FC]` + `Hash`; Group `bg-[#7EA2FC]` + `Users`; DM tinted circle + sprite + status dot; text-initials variant = `bg-[#7EA2FC] border border-[rgba(255,255,255,0.2)]` monogram; photo variant = plain 32 photo.
  - Text col `flex-1 gap-[4px]`: Title row — name `text-[14px] leading-[18px] text-white` ellipsis `flex-1` + timestamp `text-[10px] leading-[13px] text-[#8C99A6] tracking-[-0.043px]` (e.g. `10:00` / `Yesterday`). Preview row — last msg `text-[12px] leading-[15px] tracking-[-0.0516px]` ellipsis `flex-1` (read = `#8C99A6`, unread = white) + unread badge `"10"`.
- **Footer**: `"Start a new chat"` — `shrink-0 w-full h-[32px] bg-[#58D68D] rounded-[6px] flex items-center justify-center gap-[8px] px-[16px] py-[8px]`, lucide `Send` 16 white + label Body white. (Hidden while search results show.)

### 4.5 Message bubble + read receipts
- **Incoming (Others)**: row `gap-[8px] items-start p-[8px] w-[304px]`. Avatar 32 (tinted + status dot). Right col `w-[248px] gap-[8px]`:
  - Header row `gap-[8px] items-end`: name Body **Medium** white + time `text-[10px] leading-[13px] text-[#8C99A6] tracking-[-0.043px]` (`"09:00 AM"`) + optional lucide `Pin` 12.
  - Text row `gap-[8px] items-end`: body `text-[12px] leading-[15px] text-white tracking-[-0.0516px]` + trailing receipt icon 12px.
- **Outgoing ("You")**: same, name `"You"`; on **send-fail** show a red `"Resend"` control (lucide `RotateCcw` 12 + label `text-[#F03A3A]`) under the row → tap to retry.
- **Receipts** (12px, `overflow-clip`): single-check `Check` = delivered; double-check `CheckCheck` = read. Channel read-count = double-check 12 + count `text-[10px] leading-[13px] text-[#8C99A6]` (e.g. `"10"`).
- **Time divider**: `flex items-center justify-center gap-[8px] p-[8px] rounded-[90px] w-full` — 1px hairline (`flex-1`, `rgba(255,255,255,0.08)`) + label (`"Today"`/`"Yesterday"`) Caption2 **Semi** `#8C99A6` + 1px hairline.
- **Unread divider / jump-to-latest** (channels): centered divider `"10 Unread Messages"` (same style as time divider, SemiBold 10) above the first unread; floating circular **skip-to-latest** button bottom-right of the list — lucide `ChevronDown` in a `size-[40px] rounded-[90px] bg-[#344354]` (or `#242B32`) circle.

### 4.6 Channel info block + channel More menu
- **Channel info block** (pinned top of message stream): `flex-col gap-[8px]`. Row: `Hash` 16 inside `bg-[rgba(255,255,255,0.1)] rounded-[90px] p-[4px]` chip + name Body **Bold** white. Description `text-[12px] leading-[15px] text-white tracking-[-0.0516px] w-[304px]`. Ordered list `list-decimal ms-[18px]` Caption1 Regular white.
- **Channel/Group More submenu** (popover under More): `bg-[#242B32] rounded-[16px] p-[8px] flex-col gap-[8px] w-[184px]` (group `w-[216px]`), shadow `0 4px 16px rgba(255,255,255,0.08)`. Rows `min-h-[42px] p-[12px] rounded-[8px] flex items-center gap-[8px]` (hover `bg-[rgba(255,255,255,0.05)]`), 16px lucide icon + label Body white.
  - **Channel**: Members, Images, Files, Links, Pin, Threads; divider; Mute, Settings.
  - **Group**: Members, Images, Files, Links, Pin, Threads; divider 1px `rgba(255,255,255,0.2)`; Mute, Settings, **Leave group** (label `#F03A3A`).

### 4.7 Message / list-item context menu (Mark-as-read / Hide / Mute / Delete)
Right-click / long-press on a row or message. `bg-[#242B32] rounded-[16px] p-[8px] flex-col gap-[8px] w-[184px]`, shadow `0 4px 16px rgba(255,255,255,0.08)`. Group 1 rows (each `min-h-[42px] p-[12px] rounded-[8px] gap-[8px]`, 16px icon + Body white): **Mark as read** (`CheckCheck`), **Hide message** (`EyeOff`), **Mute** (`Volume2`/`BellOff`). Divider 1px. Group 2: **Delete message** (`Trash2`, label `#F03A3A`). (DM has Mark-as-read/Hide/Mute/Delete; Group & Channel context menus omit "Hide".)

### 4.8 Thread (replies) panel
- **Threads-Messages list** (half: same 320 panel; full middle: `w-[632px]`): Header `bg-[#2B3540] h-[67px] px-[12px] py-[16px] justify-between` — left threads icon 16 + `"Threads Messages"` Body white (half adds chevron-left); right chip(s): half = Expand + X; full-with-reply = X only. Body `flex-col gap-[16px] p-[8px] overflow-y-auto`: date dividers + **thread group rows**.
  - **Thread group row**: `flex-col gap-[8px] h-[104px] p-[8px] w-full`. Source label `"#Direct message"`/`"#Marketing Team"` Body white. Message line: avatar 32 (tinted + status) + container `flex-1 gap-[4px]` (name Body Medium white + time Caption2; body Caption1 white + read tick 12). Toggle row: branch icon (8×6, lucide `CornerDownRight`-ish) + `"Show N replies"` Caption2 `#8C99A6` (expanded → `"Hide N replies"`).
- **Thread reply panel** (half: 320; full: `w-[368px] right-[16px]`): Header `bg-[#2B3540] h-[67px]` — half: chevron-left + `"Threads"` + Expand + X; full: `"Threads"` + Expand + X (no chevron). Body `bg-[#344354]`:
  - **Parent message** `flex-col gap-[8px] p-[8px]`: avatar 32 + name Medium + time + body Caption1 white + tick + `"Hide N replies"` toggle.
  - **Reply rows** `w-[304px] gap-[8px] p-[8px]`: avatar 32 (e.g. `#FFA8A8` for "You") + container `w-[248px] gap-[8px]` (name Medium + time; body Caption1 white + tick).
  - **Composer** = standard Input box (§4.9).
- Trigger: Threads nav item, or `"Show N replies"`, or context-menu **Reply** (lucide `CornerUpLeft`).

### 4.9 Input message box (composer)
- Outer: `h-[138px] p-[8px] rounded-[16px]` (full width = panel/message-area width).
- Inner: `bg-[#2B3540] rounded-[16px] p-[12px] flex-col justify-between flex-1`.
- Top: placeholder `"Message"` `text-[14px] leading-[18px] text-[#8C99A6]`.
- Bottom row `flex items-center justify-between`: left `flex gap-[8px]` 16px icons — `Paperclip` (attach → file picker), `Image` (image picker), `Smile` (emoji), all `#8C99A6`. Right: **Send** `bg-[#58D68D] rounded-[6px] p-[8px]` lucide `Send` 16 white.
- **Pending attachment previews** appear **above** the placeholder: 56×56 `rounded-[8px]` `object-cover` thumbnails, `gap-[8px]`; full = single row; half = wrap 4/row. Uploading tile: dim image + centered `#58D68D` circular progress ring. Hover → top-right circular **X** (lucide `X` ~24 in a dark circle) to remove.

### 4.10 Reactions
- **Quick-reaction bar + action submenu (`Chat menu`)**: `flex-col gap-[5px] items-center w-[200px]`, absolute overlay anchored to the hovered message (half ≈ left; full ≈ right).
  - **Emoji quick panel** `200×32`: `bg-[#242B32] rounded-[8px] p-[8px] flex gap-[8px] items-center`. 7 emoji `<img>` 16×16 [👋 ❤️ 🎉 👍 🤣 👏 💯] + trailing lucide `Plus` 16 (opens full picker).
  - **Submenu** `w-[184px]`: `bg-[#242B32] rounded-[16px] p-[8px] flex-col gap-[8px]`, shadow `0 4px 16px rgba(255,255,255,0.08)`. Group A rows (`p-[12px] min-h-[42px] rounded-[8px] gap-[8px]`, 16px icon + Body white): Reply (`CornerUpLeft`), Copy (`Copy`), Pin (`Pin`), Forward (`CornerUpRight`), Select (`CircleCheck`), [Download (`Download`) — attachment context only]. Divider 1px. Group B: Delete (`Trash2`, `#F03A3A`).
- **Reaction chip (atomic)**: `rounded-[90px] px-[4px] py-[2px] flex items-center gap-[4px]` ~19px tall — 14×14 emoji + count `text-[12px] leading-[15px] text-white tracking-[-0.0516px]`. **Selected** = `bg-[rgba(88,214,141,0.2)]`; **other** = `bg-[rgba(255,255,255,0.1)]`. Re-tapping your own reaction removes it. Up to **20** distinct types/message.
  - **Chips bar full** (single row, no wrap, `~36px` pitch). **Chips bar half** (`w-[198px] flex flex-wrap content-start gap-[4px]`, wraps to multiple rows).
- **Full emoji picker** `240×361`: dark `~#242B32` panel — search input (lucide `Search` + `"Search"` placeholder + recents toggle) + 7-col scrollable emoji grid (~28–32px cells) + bottom category bar (~9 icons, active highlighted). Rebuild structurally (Figma fill is flattened).
- **Reaction modal (reactors list)** `366px × ~464px`: centered `bg-[#242B32] rounded-[16px] p-[16px] flex-col gap-[8px]`, shadow `0 4px 16px rgba(255,255,255,0.08)`. Title `"20 Reactions"` Body white; close `X` 16 absolute `top-[16px] right-[16px]`. Each reactor row: 16px reaction emoji + member block `rounded-[8px] p-[12px] flex gap-[8px]` (avatar 32 + status dot; name Body Medium white ellipsis + status Caption1 `#8C99A6`). Scrollbar `absolute right-0 top-[56px] w-[6px] h-[64px] bg-[rgba(255,255,255,0.2)] rounded-[90px]`.

### 4.11 Group create / settings / members
- **Create-group panel** (in-panel, replaces body; half & full): `bg-[#2B3540] w-[320px] rounded-[16px] p-[16px] gap-[16px] flex-col items-center overflow-hidden`.
  - Header: chevron-left + `"Create group"` Title 20/25 white; right Expand chip.
  - Profile block `gap-[16px] items-center p-[16px]`: avatar `100×100 bg-[#7EA2FC] rounded-[90px] p-[4px]` + `Users` glyph; white square Plus button `24×24 bg-white rounded-[4px] p-[4px]` lucide `Plus` 16 overlapping bottom-right → Upload modal; label `"Profile"` Body white.
  - **Group name**: label `"Group name"` Body white + field `bg-[#242B32] border border-[rgba(255,255,255,0.2)] h-[42px] px-[12px] py-[8px] rounded-[8px]` value Body white.
  - **Description**: textarea `h-[100px]` same style + counter bottom-right `"50/1000"` (50 = Medium 12 white, /1000 = 12 `#8C99A6`).
  - Divider 1px.
  - **Search**: label `"Search"` + field placeholder `"Search for members"` `#636D76`.
  - **Member list** `h-[324px] overflow-hidden`: title row — `"Select 50"` `#8C99A6` 14 left + lucide `Trash2` 14 + `"Clear all"` `#F03A3A` 14 right. Rows `p-[12px] rounded-[8px] gap-[8px]`: checkbox 16 (`rounded-[4px]`, checked = `bg-[#58D68D]` + `Check`, unchecked = `border border-[#D1D1D6]`) + avatar 32 (+status) + col (name Body Medium white + status Caption1 `#8C99A6`).
  - **Primary CTA** pinned bottom: `absolute bottom-[16px] left-[5%] right-[5%] h-[32px] bg-[#58D68D] rounded-[6px] px-[16px] py-[8px] flex items-center justify-center gap-[8px]` — `Plus` 16 + `"Create a new group"` Body white.
- **Group settings panel**: same layout from More → Settings. Differences: header label `"Settings"` + chevron-left + Expand **and** X; group-name counter `"10/50"`; description counter `"50/1000"`; member checkboxes pre-checked; CTA = `"Edit"` (lucide `Pencil` + `"Edit"`, green). On save → success toast.
- **Upload image modal** (only true centered modal in group flow): full-screen scrim `bg-black/50`; modal `w-[459px] bg-[#242B32] rounded-[16px] p-[16px] gap-[16px] flex-col`, `backdrop-blur-[4px]`. Title col (`"Upload image"` SemiBold 20 white + `"Customize your image placement before upload."` Body `#8C99A6`) + close `X` 24. Divider. Sub-title `"Image preview"` + Reset/Rotate chips. Crop area `h-[320px] rounded-[16px]` with circular crop overlay. Controls `gap-[24px]`: Rotate (tick-slider + value) ; Zoom (track `h-[8px] rounded-[90px] bg-[rgba(255,255,255,0.1)]` + `#58D68D` fill + knob 16 + value). Buttons bottom-right `gap-[16px]`: **Cancel** `bg-white text-[#1A1B1E] h-[42px] px-[16px] rounded-[8px] text-[16px]` + **Upload** `bg-[#58D68D] text-white h-[42px] px-[16px] rounded-[8px]`.
- **Toasts** (top-right over map, `w-[336px]`, `bg-[#1A1B1E] rounded-[16px] p-[16px]`, shadow `0 4px 8px rgba(255,255,255,0.08)`):
  - Member-limit error (`h-[90px]`): leading `40×40 bg-[rgba(240,58,58,0.2)] rounded-[8px] p-[8px]` red `X`/`AlertCircle` 24 + col (`"Member limit reached"` Body Bold white + `"Group capacity reached 50 members."` Body white) + trailing `X` 16.
  - Settings-saved success (`h-[72px]`): leading `40×40 bg-[rgba(88,214,141,0.2)] rounded-[8px]` green `Check` 24 + `"Setting saved successfully"` Body Bold white + `X` 16.

### 4.12 Attachments — inline + preview modals
- **Inline image grid**: tiles `~100×104` `rounded-[8px] object-cover gap-[8px]`. Full = single row of 5; half = wrap 2 cols (2+2+1). Hover tile → centered white `Eye` ~24 over `~40%` dark scrim → opens Preview image modal. Below grid: `"Download all"` Caption1 `#8C99A6`. Optional caption Body white + read tick.
- **Inline file-card stack**: card `bg-[#2B3540] rounded-[16px]` (full ~240px / half panel-width) of rows `rounded-[8px] p-[8px] gap-[8px]`: 40px colored file-type icon (DOCX blue / ZIP purple / PDF pink / XLSX green / CSV red) + filename Body Medium white ellipsis + `"Size: 100 mb"` `text-[12px] leading-[16px] text-[#8C99A6]`. Trailing read tick.
- **Preview image modal** `600px × ~564px`: scrim `bg-black/50`; `bg-[#242B32] rounded-[16px] p-[16px] gap-[16px] flex-col`, shadow `0 4px 16px rgba(255,255,255,0.08)`. Title row (`"Preview image"` SemiBold 20 + `"View the image in full size."` Body `#8C99A6 w-[392px]`) + `X` 24. Divider 1px `#FFFFFF1A`. Crop viewport `h-[320px] rounded-[16px]` checkerboard + `object-cover`; zoom pill bottom-right `h-[30px] bg-[#1A1B1E] border border-[#FFFFFF33] rounded-[6px] px-[8px] py-[6px] gap-[4px]`: `"100%"` 14 white + `Minus` 16 + track `h-[8px] w-[80px]` + `Plus` 16. Thumbnail strip `flex-wrap gap-[8px]` 56×56 tiles, selected = `border-2 border-[#58D68D]`. Buttons row `justify-between`: **Delete** `h-[42px] px-[16px] py-[8px] rounded-[8px] bg-[rgba(240,58,58,0.1)] border border-[rgba(240,58,58,0.2)] text-[#F03A3A] text-[16px] leading-[22px]` (hidden/`opacity-0` in full instance, visible in half) + **Done** `h-[42px] px-[16px] py-[8px] rounded-[8px] bg-[#58D68D] text-white text-[16px]`.
- **Preview file modal (Send files)** `600px × ~578px`: same shell. Title (`"Send files"` Medium 16 + `"Review your files and upload status before sending them to the chat."` Body `#8C99A6`) + `X` 24. Divider. File list card `bg-[#2B3540] opacity-80 rounded-[16px] p-[8px] gap-[4px]`: rows `rounded-[8px] p-[8px] gap-[8px]` — 40px file-type icon + col (filename Body Medium white + meta `flex gap-[4px]` 12: `"Size: 10 mb"` `#8C99A6` • bullet • status). Status text: `"Uploading"` white / `"Failed"` `#D41818` / `"Completed"` `#58D68D`. Failed rows: trailing `Trash2` 16 + `RotateCcw` 16; others: `Trash2` 16 only. Scrollbar pill `right-0 top-[56px] w-[6px] h-[64px]`. **Input box** at bottom (§4.9, `h-[138px]`).
- **Attachment right-click menu** `~200×363`: emoji quick bar (8 items: 👋 ❤️ 🎉 👍 🤣 👏 💯 + `Plus`) above submenu `w-[184px]` (Reply/Copy/Pin/Forward/Select/**Download** + divider + Delete `#F03A3A`). Download row hover = `bg-[rgba(255,255,255,0.1)]`.

### 4.13 File-error modal ("Unable to upload image/file")
Full-screen scrim `bg-black/50` (covers rail + panel + map). Modal `w-[600px] bg-[#242B32] rounded-[16px] p-[16px] gap-[16px] flex-col overflow-hidden`, shadow `0 4px 16px rgba(255,255,255,0.08)`, centered (Figma x420/y328).
- Title row `justify-between`: col (title `"Unable to upload image"` / `"Unable to upload file"` Medium 16/22 white + subtitle Body `#8C99A6` — image: `"Supported formats: jpg,png and gif · Max size: 25 MB"`; file: `"Supported formats: PDF, DOCX, XLSX, PPTX, ZIP, TXT, CSV · Max size: 25 MB"`) + `X` 24.
- Divider 1px `#FFFFFF1A`.
- File-list container `bg-[#2B3540] opacity-80 rounded-[16px] p-[8px] gap-[4px]`. Rows `flex items-center gap-[8px]`: leading icon button `42×42 bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.2)] rounded-[8px]` with lucide `Image` (image modal) / `FileText` (file modal) 16; col (filename Body Medium white + `"Size: NN mb"` `text-[12px] leading-[16px] text-[#8C99A6]`); trailing **status tag**.
- **Status tag** (atomic, `px-[4px] py-[2px] rounded-[4px] border` + Caption1 Regular `tracking-[-0.43px]` nowrap):
  - `"Unsupported format"` → text `#ECC819`, bg/border `rgba(236,200,25,0.1)`.
  - `"Exceed limit file"` → text `#2DB6FF`, bg/border `rgba(45,182,255,0.1)`.
  - `"Virus detected"` → text `#F03A3A`, bg/border `rgba(240,58,58,0.1)`.
- Scrollbar pill `right-0 top-[56px] w-[6px] h-[64px]`.
- Button group `justify-end gap-[16px]`: **Done** `bg-[#58D68D] h-[42px] px-[16px] py-[8px] rounded-[8px] gap-[8px]` label `"Done"` 16/22 white. (X or Done dismiss; valid files remain queued.)

### 4.14 Notification (in-app toast) + unread
- **Toast** `322×124 bg-[#242B32] rounded-[16px] p-[16px] flex-col gap-[16px]`, anchored top-right over the map (independent of chat open):
  - Top row `gap-[8px]`: avatar 40 (`bg-[#E1ADFF] rounded-[90px]` + status dot) + text col `gap-[4px]` (name Medium 16/22 white ellipsis + verb line `<b>Wave</b> to you • right now` — verb white 14, rest `#8C99A6` Body).
  - Buttons `gap-[8px] justify-center`: icon-only `bg-white rounded-[6px] p-[8px]` hand/`Hand` 16; `"Message"` `bg-white rounded-[6px] h-[32px] px-[16px] py-[8px] gap-[8px]` `MessageCircle` 16 + label `text-[#1A1B1E]` 14; `"Go to"` `bg-[#58D68D] flex-grow rounded-[6px] h-[32px] px-[16px] py-[8px] gap-[8px]` `MapPin` 16 + label white 14.
  - Close `X` 16 absolute `top-[8px] right-[8px]`.
  - `"Message"` opens/loads the DM in the half panel; `"Go to"` walks the avatar to the sender.
- **Unread badge** (red `#F03A3A`/`#D41818` family, white text ~11–12, `min-w-[16px]` centered): shown on the rail Chat icon **and** the conversation row; caps at `99+`.
- **Read row**: no badge; preview `#8C99A6`; normal weight.

### 4.15 Search
- **Search bar + filter** (chat-list header region, both views): see §4.4. Result header (when searching): `Search result "<query>" (<n> results)` Body white, `py-[12px]`.
- **Result list item**: `h-~56px px-[12px] gap-[12px]` (hover `rounded-[8px]`). Avatar 40 (DM + status dot / Channel `Hash` / Group `Users`). 2-line col: name Body Medium white + timestamp Caption1 `#8C99A6`; snippet Body `#8C99A6` truncate. **Highlight**: matched token in orange — message-text match = bg `~#F2994A`/`rgba(242,153,74)`; name match = orange text on the matched token only. Selecting → open conversation + scroll to highlighted message.
- **Search Filter panel** `340×382` popover: `bg-[#242B32] rounded-[16px] p-[16px] gap-[16px] flex-col`, shadow `0 4px 16px rgba(255,255,255,0.08)`. Title `"Search filter"` Medium 16/22 white + `X` 24. Divider. Three field groups (`gap-[8px]`, label Body white + field `h-[42px] bg-[#242B32] border border-[rgba(255,255,255,0.2)] rounded-[8px] px-[12px] py-[8px] gap-[8px]` + lucide `ChevronDown` 16):
  - **Sender** (selected: avatar 24 + status + name Medium white); **Chat type** (placeholder `"Please select chat type"` `#636D76`); **Date range** (placeholder `"DD/MM/YYYY - DD/MM/YYYY"`).
  - Buttons row `h-[42px] justify-between`: **Clear all** `bg-[rgba(240,58,58,0.05)] border border-[rgba(240,58,58,0.5)] rounded-[8px] px-[16px] text-[#F03A3A] text-[16px]`; right `gap-[8px]`: **Cancel** `bg-white text-[#1A1B1E] rounded-[8px] px-[16px] text-[16px]` + **Apply** `bg-[#58D68D] text-white rounded-[8px] px-[16px]`. All `h-[42px]`.
- **Sender dropdown**: popover `bg-[#242B32] rounded-[16px] p-[8px] w-[~308px]`, shadow same. Title `"Sender"` Caption1 `#8C99A6`. Rows `p-[12px] rounded-[8px] gap-[8px]` (hover/selected `bg-[rgba(255,255,255,0.1)]`): avatar 32 + status + col (name Medium white ellipsis + `"Active"` Caption1 `#8C99A6`). Free-text filters too.
- **Chat type dropdown** `308×173`: rows `min-h-[42px] p-[12px] rounded-[8px] gap-[8px]` — checkbox 16 (`rounded-[4px] border border-[#D1D1D6]`, checked filled) + label Body white. Options: `Direct message (DM)`, `Group`, `Channel`. Multi-select; none = all.
- **Date Picker** `311×302`: `bg-[#1A1B1E] border border-[#393939] rounded-[16px] p-[16px]`. Header `justify-between`: month button (`"March 2024"` Medium 13/24 white + small chevron) + nav arrows `ChevronLeft`/`ChevronRight` 24 `gap-[14px]`. Weekday row Caption2 `#636D76` 7 cols. Day grid: slot `40×34` Medium 14/24 center; out-of-month `#636D76`; in-month white; today/accent `#58D68D` SemiBold. **Range**: `bg-[#58D68D]` pill — single = full `rounded-[100px]`; range = start `rounded-l`, middle square, end `rounded-r`; range text SemiBold 16/24 white.
- No full-screen scrim for search popovers; in half view they float over the panel/map boundary (anchored to the filter button).

### 4.16 Typing indicator
Appended as the **last row** in the message scroll body (`#344354`), not pinned. Container `flex items-center gap-[8px] p-[8px] w-full`. Mounts when remote typing starts; **unmounts** after >3s idle or input cleared.
- **DM (single)**: avatar 32 (`bg-[#E1ADFF]` + status dot) + label `flex gap-[4px] items-center`: name `"Conan Grey"` Body **Medium** white nowrap + `"typing"` Body Regular `#8C99A6` + dots frame `h-[6px] w-[18px]`.
- **Channel 2–3 typers**: avatar **stack** of three 24px circles `rounded-[90px] border border-white overflow-hidden`, `mr-[-8px]` overlap; bg `#FFA8A8` / `#E1ADFF` / `#95F7F6` + sprites. Label: name `"Conan Grey and Taylor"` Body **Regular** white + `"typing"` `#8C99A6` + dots. (First two names joined by `" and "`.)
- **Channel 4+ typers**: two avatar circles + a 3rd **overflow badge** circle `bg-white rounded-[90px]` with `"+10"`. Label `"Others"` Body Regular white + `"typing"` `#8C99A6` + dots.
- **Animated dots**: `h-[6px] w-[18px]` box, two/three 6px dots in `#8C99A6` (matches "typing"), looping opacity/translate bounce, `gap-[4px]` right of the word.

---

## 5. Build Checklist (per project rules)
- Tailwind-only, no `@/components/ui/*` (rule 08); icons from `lucide-react` only (rule 12).
- Reuse existing `views/chat/*` components and `VOSidebar`; do not fork (rules 09).
- Member data via `/api/user/*` only; never `/api/admin/*` (rule 15). Reuse the play page's existing `wsClient` (`useVOSessionStore`); do not open a new socket.
- No semicolons, double quotes, 2-space indent, trailing commas, 100-col, arrow parens (Prettier).
- Prefix intentionally-unused vars with `_`; pass `npx tsc --noEmit`.
- Do not unmount the Pixi/Phaser canvas when toggling chat. Half = overlay above map; full = overlay covering the map (map stays mounted behind).
- Implement only the specced surfaces; do not add steps/fields not in Figma (rule 14).
