# 🔧 Improvements (Improve) — Feedback 23-07

รวม **33 รายการ** ที่จัดเป็นงานปรับปรุง/ทำเพิ่ม จาก [README.md](README.md) — รวมชุด UX/UI (#2–#44) และ AI100 (#48/#49/#53)

**เรียงตาม priority:**
- 🟠 **Medium:** [#11](#11) · [#29](#29) · [#37](#37) · [#38](#38) · [#39](#39)
- 🟡 **Low:** [#2](#2) · [#4](#4) · [#5](#5) · [#6](#6) · [#7](#7) · [#8](#8) · [#10](#10) · [#13](#13) · [#14](#14) · [#16](#16) · [#17](#17) · [#18](#18) · [#19](#19) · [#20](#20) · [#21](#21) · [#23](#23) · [#28](#28) · [#31](#31) · [#32](#32) · [#34](#34) · [#35](#35) · [#36](#36) · [#40](#40) · [#41](#41) · [#44](#44) · [#48](#48) · [#49](#49) · [#53](#53)

**Figma reference base:** `https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-`

> คำอธิบายฟิลด์: **Effort** `S`<ครึ่งวัน / `M` 1–2 วัน / `L` >2 วัน หรือข้าม service · **Conf.** ความมั่นใจของการวิเคราะห์

---

## Meeting

<a name="37"></a>
### #37 — เพิ่มฟีเจอร์เตะ (kick) ออกจาก Meeting `Meeting · 🟠 Medium · Effort L · Conf. high`

**Feedback เดิม:** "เพิ่มฟีเจอร์เตะออกจาก Meeting" · [Figma 3546-410826](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3546-410826)

**ไฟล์ที่เกี่ยวข้อง:**
- FE: `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx`, `.../components/zone-participants-submenu.tsx` (MemberRow L69–79), `.../use-meeting-media.ts`, `zyra-app/lib/api/workspace-ws.ts`, `.../workspace-ws-types.ts`
- WS: `zyra-ws/internal/hub/audio.go` (`handleMediaRoomLeave` L109, `handleMediaRequest` L162), `.../message.go`, `.../room.go` (~L515–522)

**สาเหตุ / บริบทปัจจุบัน:**
**ยังไม่มีฟีเจอร์ kick ที่ไหนเลย** ตัวใกล้ที่สุดคือ `RequestMediaControls` (แค่ "ขอ" ปิดไมค์/กล้อง advisory) ฝั่ง WS มีแค่ `handleMediaRoomLeave` (เอา client ออกเมื่อ*เจ้าตัว*เดินออกเอง) และ `handleMediaRequest` (relay อย่างเดียว) · **ไม่มี concept host/moderator** ใน meeting room → ต้องตัดสินใจ policy ว่าใครมีสิทธิ์ kick

**แนวทางแก้ (end-to-end):**
- **FE:** เพิ่ม action "Remove from meeting" (icon lucide `UserX`/`LogOut`) ในเมนูต่อ participant (`ZoneParticipantsSubmenu` MemberRow ข้างปุ่ม Chat) หรือปุ่มที่ 3 ใน `RequestMediaControls` hover ของ remote tile → callback `onKickParticipant` → `use-meeting-media.ts` `kickParticipant(targetUserId)` → `workspace-ws.ts` ส่ง `ws:meeting:kick`
- **WS:** เพิ่ม ClientMsg + payload struct ใน `message.go`, handler ใน `audio.go` (ตรวจสิทธิ์ตาม policy เช่น zone/workspace owner, เอา target ออกจาก media room, `stopShare`, unicast `ws:meeting:kicked` ให้ target ตัด LiveKit + เด้งออกจาก zone), register case ใน `room.go`
- เพิ่ม type ใน `workspace-ws-types.ts` + i18n · **ต้องตัดสินใจ policy สิทธิ์ kick ก่อน**

---

<a name="38"></a>
### #38 — เพิ่มปุ่มปิดไมค์ทุกคน (mute all) ยกเว้นตัวเอง `Meeting · 🟠 Medium · Effort L · Conf. high`

**Feedback เดิม:** "เพิ่มปุ่ม ปิดไมค์ทุกคนพร้อมกันได้ยกเว้นแค่ตัวเอง" · [Figma 3547-505857](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3547-505857)

**ไฟล์ที่เกี่ยวข้อง:**
- FE: `zone-enter-panel.tsx` (`MeetingToolbar` L1360–1531), `use-meeting-media.ts` (L662), `workspace-ws.ts`, `workspace-ws-types.ts` (`forced_mute_by` L344)
- WS: `audio.go` (`handleAudioMuteChanged` L138–142), `message.go` (`MemberMediaState.ForcedMuteBy` L1017, `AudioStateUpdatePayload` L1040), `room.go`

**สาเหตุ / บริบทปัจจุบัน:**
มี **scaffolding สำหรับ force-mute อยู่แล้วทั้งสองฝั่งแต่ยัง inert:**
- backend มี field `ForcedMuteBy` + `memberAudioState.forcedMuteBy` (เคลียร์เมื่อเจ้าตัว unmute เอง) **แต่ไม่มี handler ที่ SET**
- FE มี `forced_mute_by` และอ่านเข้า `memberAudio` map แต่**ไม่มีโค้ด auto-mute ตัวเองเมื่อโดน force**
- ปัจจุบันมีแค่ per-target advisory (`requestMediaOff`) · `MeetingToolbar` ไม่มีปุ่ม mute-all

**แนวทางแก้:**
- **FE:** เพิ่มปุ่ม "Mute all" (icon `MicOff`) ใน `MeetingToolbar` → `mediaControls.onMuteAll` → `muteAll()` → `workspace-ws.ts` ส่ง `ws:audio:muteAll` · เพิ่ม logic: เมื่อรับ `ws:audio:stateUpdate` ที่ `forced_mute_by === self` → สั่ง mute LiveKit track จริง (ต่อยอด L662)
- **WS:** เพิ่ม ClientMsg + handler ใน `audio.go` loop สมาชิกทุกคนยกเว้นผู้ส่ง set `forcedMuteBy = c.UserID` broadcast `MsgAudioStateUpdate` ต่อคน, register case ใน `room.go`
- **ต้องตัดสินใจ policy:** advisory (ใครก็กดได้) หรือจำกัดเฉพาะ host

---

<a name="4"></a>
### #4 — Hover ควรมี overlay ดำให้ปุ่มเด่นขึ้น `Meeting · 🟡 Low · Effort S · Conf. med`

**Feedback เดิม:** "Display ตอน Hover จะมี Overlay ดำเพื่อให้ปุ่มมันเด่นขึ้น"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/views/user/virtual-office/components/zone-enter-panel.tsx` (`SelfTileControls` L935, `RequestMediaControls` L982, `ScreenShareBox` compact L633)

**สาเหตุ / บริบทปัจจุบัน:**
hover overlay มีอยู่แล้วบางส่วน (`absolute inset-0 z-20 hidden ... bg-black/40 group-hover:flex` ครอบปุ่ม) **แต่ผูกกับเงื่อนไขว่ามีปุ่มโชว์เท่านั้น** — state ที่ไม่มี overlay: (1) DisplayCard hover ที่ไม่มีปุ่ม (self disconnected / remote ที่ `canRequestMedia=false`) (2) `ScreenShareBox` แบบ expanded (featured) มีแค่ zoom pill → contrast ปุ่มไม่สม่ำเสมอ

**แนวทางแก้:**
ทำ black overlay เป็นมาตรฐานเดียวทุก DisplayCard: เพิ่ม div overlay
`absolute inset-0 rounded-[12px] bg-black/40 opacity-0 transition-opacity group-hover:opacity-100 pointer-events-none z-10`
เป็นชั้นพื้นหลังของ hover controls ทุกตัว (card มี `group` แล้ว) แล้วให้ปุ่ม fade เข้าด้วย opacity · ครอบ `ScreenShareBox` expanded ด้วย · ควรอ้าง Figma "Display - Hover" ยืนยันค่า opacity

---

<a name="48"></a>
### #48 — ห้องประชุมล็อกเอง `Meeting · 🟡 Low` *(AI100 #4)*

**Feedback เดิม (AI100 #4):** "เวลาอยู่ห้องประชุม ห้องชอบล็อกเอง"

**สถานะ:** ✅ Done — เป็นเงื่อนไขระบบที่ตั้งใจ (by-design)

ทีมยืนยันว่าเป็นพฤติกรรมที่ตั้งใจ: ออกแบบให้เหมือน "เคาะก่อนเข้าห้องประชุม" (knock-to-enter) — ไม่มีแผนแก้ · บันทึกไว้เป็น context เผื่อมี feedback ซ้ำ

---

<a name="49"></a>
### #49 — สเตตัสเปลี่ยนเป็นไม่ว่างตอนอยู่ meeting `Meeting · 🟡 Low` *(AI100 #5)*

**Feedback เดิม (AI100 #5):** "เวลาอยู่ห้องประชุม สเตตัสชอบเปลี่ยนเป็นไม่ว่าง แต่จริงๆว่าง"

**สถานะ:** ✅ Done — เป็นเงื่อนไขระบบที่ตั้งใจ (by-design)

ทีมยืนยันว่าเป็นพฤติกรรมที่ตั้งใจ: เข้าห้องประชุมแล้ว status เปลี่ยนเป็น In-Meeting (สีแดง) ตามดีไซน์ — ไม่มีแผนแก้ (canon colors อยู่ที่ `zyra-app/lib/presence-status.ts`, "meeting" = red เป็น client-derived เมื่อ meeting zone ≥ 2 คน)

---

## Menu

<a name="29"></a>
### #29 — Edit profile / Change Avatar เด้งออกจาก VO `Menu · 🟠 Medium · Effort M · Conf. high`

**Feedback เดิม:** "เมื่อกด Edit profile กับ Change Avatar ปัจจุบันจะกลับไปยังหน้าหลัก" · [Figma 2530-560779](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=2530-560779)

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/views/user/virtual-office/hero-virtual-office.tsx` (Edit profile ~L8818, Change Avatar ~L8824, pz onEditProfile ~L7781, VOSettingModal ~L7575/8433)
- `.../components/vo-profile-panel.tsx`, `.../vo-setting-modal.tsx` (prop `initialTab`), `.../vo-profile-tab.tsx`
- `zyra-app/views/user/workspace-enter/components/change-character-modal.tsx`

**สาเหตุ / บริบทปัจจุบัน:**
อาการ "เด้งกลับหน้าหลัก" มาจาก handler โดยตรง:
- ปุ่ม Edit profile เรียก `destroySession()` แล้ว `router.push("/setting?...")` → ทำลาย VO session
- ปุ่ม Change Avatar เรียก `router.push("/workspace/${id}")` → กลับ lobby

**แต่โปรเจกต์มีของอยู่แล้วสำหรับทำ in-place:** `VOSettingModal` รองรับ prop `initialTab` และมีแท็บ "profile" ที่ render `VOProfileTab` (reuse `ProfileForm`) — อ้าง Figma "Varient=Profile" 2530:559473 (กลุ่มเดียวกับ 2530-560779) · Change Avatar (เปลี่ยน character sprite) มี `ChangeCharacterModal` อยู่แล้วแต่ยังไม่ import เข้า VO · ปัญหาซ้ำที่ `pz-zone-card` `onEditProfile` ที่ก็ `router.push("/setting")`

**แนวทางแก้:**
1. **Edit profile (S):** เปลี่ยน `onEditProfile` ทั้งใน `VOProfilePanel` (~L8818) และ `PZZoneCard` (~L7781) ให้ไม่ `destroySession`/`router.push` แต่ `setShowProfilePanel(false)` แล้ว `setActiveModal("setting")` ส่ง `initialTab="profile"` (`VOProfileTab` มี `onSaved → notifyProfileUpdated` ให้ peer เห็นรูป/ชื่อใหม่ทันทีอยู่แล้ว)
2. **Change Avatar (M):** import `ChangeCharacterModal` มา render in-place (state `showChangeCharacter`) แทน `router.push` · `onSave` → `saveSelectedAvatar` + `setMyAvatarSelection` แล้ว apply sprite เข้า pixi scene + broadcast `avatar_url` ผ่าน WS (payload `moved` JSON ส่งเมื่อ `avatar_url` เปลี่ยน ~L2581/2597/2608) เพื่อไม่ต้อง reconnect
> ควรตรวจ Figma 2530-560779 ให้ชัดว่าเป็นแท็บ Profile หรือ Change character variant

---

<a name="39"></a>
### #39 — ระบบแจ้งข่าว (announcement) ถึงทุกคนใน workspace `Menu · 🟠 Medium · Effort L · Conf. high`

**Feedback เดิม:** "ระบบแจ้งเตือนข่าวสาร ทุกคนใน Workspace (Admin, Owner)"

**ไฟล์ที่เกี่ยวข้อง:**
- BE: `zyra-api/internal/service/notification_service.go`, `.../handler/notification_handler.go`, `.../router/router.go`, `.../model/chat.go`, `.../cache/notification.go`
- WS: `zyra-ws/main.go` (~L77 `SubscribeNotifications → PushNotification`)
- FE: `zyra-app/lib/api/chat.ts`, `.../components/vo-notification-panel.tsx`, `.../components/manage-members-modal.tsx`

**สาเหตุ / บริบทปัจจุบัน:**
เป็นฟีเจอร์ใหม่ **แต่มีโครงสร้าง notification ครบพร้อมต่อยอด:**
- `NotificationService` เขียน `tb_notification` (`type/user_id/workspace_id/actor_id/is_read/...`) + `batchInsert` + push real-time ผ่าน `NotificationPublisher → Redis vo:notify → zyra-ws → chat:notification:new`
- type ที่มี: mention/reply/group_add/reaction/zone_force_unclaimed — **`CreateZoneForceUnclaimed` เป็น template ที่ตรงที่สุด** (notification ที่ไม่ผูกกับ conversation ใส่ `workspace_id` ตรง ๆ)
- FE มี `VONotificationPanel` (bell) + `typeLabel()` switch ตาม type อยู่แล้ว · role check ใช้ pattern `callerRole()`
- **ข้อจำกัด:** model `Notification` ไม่มี field `title/body` (preview ดึงจาก `tb_message` ผ่าน join) → announcement ที่ไม่มี message ต้องมีที่เก็บใหม่

**แนวทางแก้:**
- **BE:** เพิ่ม type `"announcement"` — เพิ่ม `title/body` (nullable) ใน `tb_notification` + model หรือทำ `tb_announcement` · เขียน `CreateAnnouncement(ctx, workspaceID, actorID, title, body)` query สมาชิกจาก `tb_workspace_member` แล้ว `batchInsert` หนึ่งแถวต่อคน + push (`pusher.Publish`) · เพิ่ม `POST /api/user/workspaces/:id/announcements` เช็ค `callerRole` ต้องเป็น Owner/Admin (403 ถ้า Member)
- **WS:** reuse `vo:notify`/`PushNotification` ได้เลย
- **FE:** เพิ่ม `createAnnouncement` ใน `chat.ts` (member API `/api/user/*`) + ฟอร์ม compose ในโซน Admin (icon `Megaphone`, i18n) + case `"announcement"` ใน `typeLabel()` และ render ของ `vo-notification-panel.tsx`
- **(ทางเลือก)** ส่งอีเมลผ่าน `zyra-notifications` ด้วย template ใหม่

---

## Chat

<a name="11"></a>
### #11 — Filter Sender: dropdown + typeahead ค้นชื่อ `Chat · 🟠 Medium · Effort S · Conf. high`

**Feedback เดิม:** "ตัว Filter Sender สามารถกด Drop down ได้ และพิมพ์ชื่อแล้ว dropdown ค่อย ๆ โชว์ชื่อได้ไหม?"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/views/chat/components/search-filter-popover.tsx` (dropdown Sender L136–201) · อ้าง pattern จาก `create-group-modal.tsx` (filtered L157–161)

**สาเหตุ / บริบทปัจจุบัน:** `SearchFilterPopover` มี dropdown "Sender" (กดเปิดได้) + list สมาชิกจาก `useWorkspaceMembers` เลือกทีละคนได้ **แต่ยังไม่มีช่องพิมพ์ filter รายชื่อ** → สมาชิกเยอะจะหายาก

**แนวทางแก้:** เพิ่ม state `senderQuery` + input (icon `Search`) บนสุดของ dropdown แล้ว filter members ด้วย `display_name.toLowerCase().includes(q)` ผ่าน `useMemo` แบบเดียวกับ `create-group-modal` + เพิ่ม i18n key `searchSender` placeholder

---

<a name="13"></a>
### #13 — แยกปุ่มแนบไฟล์ให้เลือกได้เฉพาะไฟล์ `Chat · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "แนบไฟล์กับส่งรูปควรแยกประเภท — กดแนบไฟล์ควรเลือกได้แค่ไฟล์ ไม่ใช่เลือกรูปได้ด้วย"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/views/chat/components/message-input.tsx` (L620–637, `onFileInput` L359–362), `.../attachment-utils.tsx` (`FILE_ACCEPT`/`ALLOWED_MIME_TYPES` L14–29)

**สาเหตุ / บริบทปัจจุบัน:** composer มี input ซ่อน 2 ตัว — `fileInputRef` ใช้ `accept={FILE_ACCEPT}` = `ALLOWED_MIME_TYPES` ทั้งหมด (รวม image) ส่วน `imageInputRef` accept เฉพาะรูป → ปุ่ม Paperclip "แนบไฟล์" เลือกได้ทั้งไฟล์และรูป (ทับซ้อนกัน)

**แนวทางแก้:** เพิ่ม `export const FILE_ONLY_ACCEPT` ใน `attachment-utils.tsx` = `ALLOWED_MIME_TYPES` ที่กรอง `isImageMime` ออก (เหลือ pdf/docx/xlsx/pptx/zip/txt/csv) แล้วเปลี่ยน `accept` ของ `fileInputRef` เป็น `FILE_ONLY_ACCEPT` · (option: ตรวจ source ใน `onFileInput` reject รูปที่มาจาก `fileInputRef`)

---

<a name="14"></a>
### #14 — ขยาย UI preview รูปที่ส่งแล้ว `Chat · 🟡 Low · Effort M · Conf. med`

**Feedback เดิม:** "อยากเปลี่ยน UI ตอน Preview รูปที่กดส่งไปแล้ว เพราะปัจจุบันภาพเล็กเกินไป" · [Figma 3221-106306](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=3221-106306)

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/views/chat/components/file-preview.tsx` (panel `w-[600px]`, stage `h-[320px]` L101/126) · เปิดจาก `message-item.tsx` L539–550 (post-send = ไม่ส่ง `onDelete`)

**สาเหตุ / บริบทปัจจุบัน:** `FilePreview` modal ใช้ stage สูงคงที่ `h-[320px]` ร่วมทั้ง pre-send และ post-send → ภาพดูเล็กเพราะ stage ตายตัว

**แนวทางแก้:** ปรับตาม Figma 3221-106306 — เพิ่มขนาด panel/stage โดยเฉพาะโหมด post-send (`onDelete === undefined`) เช่น `max-w-[90vw]`/`max-h-[80vh]` responsive คง `object-contain` + zoom control เดิม · อาจแยก layout post-send ให้ภาพเด่นกว่า pre-send

---

<a name="16"></a>
### #16 — เพิ่มขนาดฟอนต์ข้อความเป็น Body 14 `Chat · 🟡 Low · Effort S · Conf. med`

**Feedback เดิม:** "ข้อความตอนพิมพ์อยากให้ตัวใหญ่ขึ้น อาจเป็น Title 14 Medium / Body 14 Regular"

**ไฟล์ที่เกี่ยวข้อง:** `message-item.tsx` (body L439), `message-text.tsx` (mention/link chip L179/195), `message-input.tsx` (composer L615)

**สาเหตุ / บริบทปัจจุบัน:** composer เป็น `text-[14px] leading-[18px]` แล้ว แต่**เนื้อความในบับเบิลจริงเป็น `text-[12px] leading-[15px]`** และ mention/link chip = `text-[13px]` (ชื่อผู้ส่ง Title = 14 medium อยู่แล้ว) → ยังไม่ตรงสเปก Body 14

**แนวทางแก้:** ปรับ body ใน `message-item` `text-[12px] leading-[15px]` → `text-[14px] leading-[18px]` (คง Title 14 medium) · mention/link chip 13px → 14px · ตรวจ reply preview/receipt/snippet ที่เป็น 12px ให้เข้ากันตามดีไซน์

---

<a name="17"></a>
### #17 — เพิ่มขนาดรูปในบับเบิลแชท `Chat · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "ภาพตอนส่งมีขนาดเล็ก อาจเพิ่มขนาดให้ดูใหญ่กว่านี้"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/views/chat/components/message-item.tsx` (`ImageThumb` `size-[104px]` L730, grid L684, infected L717)

**สาเหตุ / บริบทปัจจุบัน:** `ImageThumb` render ขนาดตายตัว `size-[104px]` เรียงในกริด `flex-wrap gap-[8px]` (รวม placeholder infected/pending) → ดูเล็ก

**แนวทางแก้:** เพิ่มขนาด thumbnail `size-[104px]` → ~160–200px หรือ responsive: รูปเดียวให้ใหญ่พิเศษ (`max-w-[280px]` คงอัตราส่วน) หลายรูปคงกริดแต่เพิ่ม cell size · อัปเดตขนาด block infected + pending overlay ให้ตรงกัน

---

<a name="18"></a>
### #18 — ปุ่ม Expand/Collapse ซ้ำ 2 ที่ ให้เหลือปุ่มเดียว `Chat · 🟡 Low · Effort S · Conf. med`

**Feedback เดิม:** "Expand กับ Collapse มีแค่ตรงวงกลมก็พอ ไม่จำเป็นต้องมี 2 ที่"

**ไฟล์ที่เกี่ยวข้อง:** `chat-sidebar.tsx` (Maximize2 L360–367), `dm-panel.tsx` (L119–128), `channel-panel.tsx` (L143–152), `chat-surface.tsx` (full view L320–362)

**สาเหตุ / บริบทปัจจุบัน:** ปุ่ม Expand (`Maximize2`, `onExpand=onToggleView`) render ทั้งใน header ของ `ChatSidebar` และ header ของ `DmPanel`/`ChannelPanel` → ในโหมด full view แสดง list + panel พร้อมกันจึงเห็นปุ่ม 2 ปุ่ม

**แนวทางแก้:** เก็บปุ่ม expand/collapse ไว้ที่เดียว (ปุ่มวงกลม) — เอา `Maximize2` ออกจาก header ของ conversation panel (dm/channel) ให้เหลือมุมเดียว (แนะนำที่ sidebar) โดย `chat-surface` ไม่ส่ง `onExpand` ให้ทั้งสองจุด · ถ้าต้องการ "วงกลม" ปรับ style เป็น `rounded-full` ตาม Figma

---

<a name="19"></a>
### #19 — เมนู 3 จุดของ DM เพิ่ม Image / File `Chat · 🟡 Low · Effort M · Conf. high`

**Feedback เดิม:** "DM ควรมี Image / file พวกนั้นด้วยเมื่อกด 3 จุด"

**ไฟล์ที่เกี่ยวข้อง:** `dm-panel.tsx` (MoreHorizontal → `ConversationInfoPanel` L129–137/153–159), `conversation-info-panel.tsx`, `conversation-media-panel.tsx`

**สาเหตุ / บริบทปัจจุบัน:** ปุ่ม 3 จุดของ `DmPanel` เปิด `ConversationInfoPanel` ซึ่งมีแค่ Mute + รายชื่อสมาชิก **ไม่มีทางลัด Images/Files** (ต่างจาก channel/group ที่ใช้ `ConversationMenu` มี Images/Files/Links/Pin/Threads เปิด `ConversationMediaPanel`)

**แนวทางแก้:** เพิ่ม Images / Files (icon `ImageIcon`, `FileText`) ให้ DM — ง่ายสุดเพิ่ม state `mediaTab` ใน `dm-panel` เหมือน `channel-panel` แล้ว render `ConversationMediaPanel` (`"images"`/`"files"`) ซึ่ง **reuse ได้ทันที** (รองรับ `conversationId` ทุกชนิดอยู่แล้ว) · หรือเพิ่ม section ใน `ConversationInfoPanel`

---

<a name="20"></a>
### #20 — เพิ่ม hover highlight ที่แถวข้อความ `Chat · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "ยังไม่มี Highlight ตรงข้อความเมื่อเมาส์ไป Hover"

**ไฟล์ที่เกี่ยวข้อง:** `message-item.tsx` (root `group relative flex ... p-[8px]` L279), `message-list.tsx` (ring highlightId L385–391)

**สาเหตุ / บริบทปัจจุบัน:** root ของแต่ละแถวมีแค่ class `group` (เพื่อโชว์ hover action bar) **ไม่มี `hover:bg`** ใด ๆ · wrapper ใน `message-list` มีแค่ ring ตอน `highlightId`

**แนวทางแก้:** เพิ่ม `hover:bg-[rgba(255,255,255,0.03)]` (โทนอ่อนกว่า `#2B3540`) + `rounded-[8px]` ที่ root div ของ `MessageItem` · ระวังไม่ให้ชนกับ ring `highlightId` และ `opacity-50` ตอน status sending

---

<a name="21"></a>
### #21 — Pinned: pin เดียวไม่แสดงขีดนำหน้า `Chat · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "ถ้ามี Pin แค่อันเดียวยังไม่ต้องมีขีดข้างหน้า แต่ถ้ามีหลายอันค่อยขึ้นขีด"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/views/chat/components/pin-banner.tsx` (indicator 3 ขีด L72–76, label L55)

**สาเหตุ / บริบทปัจจุบัน:** `PinBanner` render แถบ indicator แนวตั้ง 3 ขีดเสมอไม่ว่ามี pin กี่อัน (label แยกกรณี pin เดียว/หลายอันแล้ว แต่ขีดนำหน้าไม่ได้ทำ conditional)

**แนวทางแก้:** หุ้มบล็อก indicator 3 ขีด (L72–76) ด้วย `{pins.length > 1 && (...)}` → pin เดียวไม่มีขีด, หลายอันจึงแสดง · (option: ปรับจำนวน segment/ตำแหน่ง active ตามจำนวน pin จริง)

---

<a name="23"></a>
### #23 — เพิ่มปุ่ม Select All ตอนเลือกสมาชิก `Chat · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "เพิ่ม Select All ตรงเลือก member"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/views/chat/components/create-group-modal.tsx` (`clearAll` L448–460, toggle L163–181, `MAX_MEMBERS = 50`)

**สาเหตุ / บริบทปัจจุบัน:** ส่วนเลือกสมาชิกมีปุ่ม "Clear all" แต่**ไม่มี "Select all"** · ปัจจุบัน toggle เลือกทีละคน + เพดาน 50 คน

**แนวทางแก้:** เพิ่มปุ่ม "Select All" ข้าง Clear all — set `selected` จากรายชื่อ `filtered` (เคารพ query filter + `MAX_MEMBERS`) ถ้าเกิน 50 โชว์ `zyraToast.errorWithTitle` เหมือน toggle · อาจทำเป็น toggle select/deselect ตามสถานะ + เพิ่ม i18n `selectAll`

---

## Display

<a name="2"></a>
### #2 — Highlight/ไอคอนเมนูให้โผล่เฉพาะตอน hover `Display · 🟡 Low · Effort S · Conf. med`

**Feedback เดิม:** "Participant ใน Private zone/Circle/Meeting room: (2.1) ยังไม่ hover ไม่ต้องมี Highlight · (2.2) ไอคอนเมนูปรากฏก็ต่อเมื่อ hover เท่านั้น"

**ไฟล์ที่เกี่ยวข้อง:** `zone-enter-panel.tsx` (Compact L790–928, Expanded L1013–1147, `SelfTileControls` L932–962, `RequestMediaControls` L971–1009), `hero-virtual-office.tsx`

**สาเหตุ / บริบทปัจจุบัน:**
จากการตรวจ code จริง — **ส่วนใหญ่ทำงานอยู่แล้ว:**
- ข้อ 2.2: การ์ดใช้ `hidden ... group-hover:flex` → ไอคอนโผล่เฉพาะตอน hover แล้ว
- ข้อ 2.1: การ์ด idle ไม่มี highlight ค้าง มีแค่ border ตั้งใจ (speaking เขียว `#58D68D`, hand-raised เหลือง `#ECC819`)

→ **ช่องว่างจริงคือ Private zone ไม่ขึ้นไอคอน ซึ่งผูกกับ [#1](bugs.md#1) โดยตรง** (สาเหตุความไม่สม่ำเสมอมาจากการ gate props ที่ระดับ hero ไม่ใช่ที่การ์ด)

**แนวทางแก้:** แก้ [#1](bugs.md#1) ก่อน → การ์ดทั้ง 3 โซนจะได้ hover-behavior เหมือนกัน · งานที่เหลือของข้อนี้คือ audit ให้ทั้ง 3 โซนส่ง props ชุดเดียวกัน (`onRequestMediaOff`, `selfControls`) และคง `group-hover:flex` ไว้ (อย่าเปลี่ยนเป็น `flex`)

---

<a name="31"></a>
### #31 — Full view ตอน share screen ไม่มี bottom menu `Display · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "ตอน Share screen ใน Full view ไม่มี Bottom menu ต้องออกจาก Full view ก่อนถึงจะปรากฏ"

**ไฟล์ที่เกี่ยวข้อง:** `zone-enter-panel.tsx` (toolbar เงื่อนไข `{isMeeting && <MeetingToolbar/>}` L2694), `hero-virtual-office.tsx` (`isMeeting` L8865/8987, VOHud L8647)

**สาเหตุ / บริบทปัจจุบัน:**
ในโหมด expanded (full view) `MeetingToolbar` render ด้วย `{isMeeting && ...}` — private zone ส่ง `isMeeting={activeZone.zone_type === "meeting"} = false` และ panel เป็น `absolute inset-0 z-50` คลุมทับ VOHud ทั้งจอ → share screen ใน private zone จึงไม่มีเมนูล่าง ต้องยุบ compact ถึงเห็น (Circle/Meeting ส่ง `isMeeting=true` จึงปกติ) — private zone รองรับ screenshare (media-only shared mic/cam/screenshare)

**แนวทางแก้:** เปลี่ยนเงื่อนไข render toolbar (L2694) ให้แสดงเมื่อมี media session แทนผูกกับ `isMeeting` อย่างเดียว เช่น `{mediaControls && <MeetingToolbar mediaControls={mediaControls} />}` หรือครอบ private zone ด้วย · ตรวจว่า `MeetingToolbar` ทำงานถูกเมื่อไม่มี hand-raise/reactions ในบริบท private zone

---

<a name="53"></a>
### #53 — Zoom-in/Zoom-out เร็วเกินไป `Display · 🟡 Low · Effort S · Conf. high` *(AI100 #9)*

**Feedback เดิม (AI100 #9):** "Zoom-in Zoom-out เร็วเกินไป"

**ไฟล์ที่เกี่ยวข้อง:**
- `zyra-app/zyra-engine/pixi-game/scene.ts` (`onWheel` L1334–1339, register `passive:false` L1411, `zoomTo` L4506–4508)
- `zyra-app/zyra-engine/constants.ts` (`CAMERA_ZOOM` 1.0 L17, `CAMERA_ZOOM_MIN` 0.4 L18, `CAMERA_ZOOM_MAX` 3.0 L19)

**สาเหตุ / บริบทปัจจุบัน:**
`onWheel` ใช้ step **คงที่ ±0.1 ต่อ wheel event** (`delta = e.deltaY > 0 ? -0.1 : 0.1`) apply เชิงเส้น ไม่มี smoothing/accumulate และไม่ normalize `e.deltaMode` (line vs pixel) · trackpad/wheel ความละเอียดสูงยิงหลาย event ต่อ 1 gesture → `zoom` กระโดดทีละ 0.1 หลายครั้งต่อเฟรม ไล่ทั่วช่วง 0.4–3.0 ในไม่กี่เฟรม = รู้สึก "เร็วเกินไป" · ไม่มี pinch handler แยก (pinch บน trackpad มาเป็น wheel events ชุดเดียวกัน)

**แนวทางแก้:**
`onWheel` L1336 — ลด step (เช่น 0.03–0.05), ทำให้ proportional/exponential ต่อ `e.deltaY` พร้อม clamp ต่อเฟรม, normalize `e.deltaMode` · optional: accumulate delta แล้ว apply ครั้งเดียวต่อ rAF

---

## Object

<a name="5"></a>
### #5 — selection ตอนเลือก object ไม่ชัด `Object · 🟡 Low · Effort M · Conf. med`

**Feedback เดิม:** "การแสดงผลตอนเลือก Object ไม่ชัด (แต่ตอนอัปโหลดหลังบ้านชัดนะ)"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/views/admin/workspace-editor/components/map-editor-canvas.tsx` (selection border Pass 2 ~L1150–1259), `.../object-library-panel.tsx` (grid cards L626–684), `.../admin/object-management/components/object-card.tsx` (`isSelected && "ring-1 ring-[#58D68D]"` L31)

**สาเหตุ / บริบทปัจจุบัน:**
selection ของ object บน map วาดเป็นแค่**กรอบเขียวเส้นบาง 2px** (`#58D68D`) ไม่มี fill/tint ทับ sprite → กลืนกับพื้น · ฝั่ง palette ก็ไม่มี state selected ที่โชว์ ring (ต่างจากหน้า Object Management ที่มี `ring-1 ring-[#58D68D]` ชัดเจน) → ตรงกับ feedback "ตอนอัปโหลดหลังบ้านชัด แต่ตอนเลือกไม่ชัด"

**แนวทางแก้:**
- ใน `map-editor-canvas.tsx`: หลังวาดกรอบ ให้ทับ semi-transparent tint fill (เช่น `rgba(88,214,141,0.12)`) ตาม AABB + เพิ่ม lineWidth เป็น 2.5–3 หรือ double-stroke (halo จางด้านนอก) โดยคงโทเคน `#58D68D`/`#F03A3A` (locked)
- palette: ส่ง prop `selectedObjectId` เข้า `object-library-panel.tsx` แล้วเติม `ring-1 ring-[#58D68D]` แบบเดียวกับ `object-card.tsx`
> ทำคู่กับ [#6](#6)

---

<a name="6"></a>
### #6 — เพิ่ม hover state ให้ object `Object · 🟡 Low · Effort M · Conf. med · (In-Progress)`

**Feedback เดิม:** "เพิ่ม Hover เหมือน Object Management"

**ไฟล์ที่เกี่ยวข้อง:** `map-editor-canvas.tsx` (`handleMouseMoveHover` L2498–2548, `getObjectAABBPx`), `object-card.tsx` (`hover:bg-[rgba(255,255,255,0.05)]` L30), `object-library-panel.tsx` (hover L657–664)

**สาเหตุ / บริบทปัจจุบัน:** ตอน hover object บน map `handleMouseMoveHover` ทำแค่เปลี่ยน cursor เป็น pointer/grab จาก hit-test **ไม่มีการวาด visual highlight** บน object เลย (ต่างจาก Object Management ที่มี `hover:bg` และ palette ที่มี translateY + box-shadow + preview popup)

**แนวทางแก้:** เก็บ `hoveredObjectId` ลง ref (set/clear ใน `handleMouseMoveHover` จาก `getObjectAABBPx` ที่มีอยู่ แล้ว `requestDraw`) → ใน object render pass วาด hover highlight แบบเบากว่า selection (กรอบ `rgba(88,214,141,0.4)` lineWidth 1.5 หรือ fill overlay จาง ๆ) เฉพาะตัวที่ hover และไม่ใช่ตัวที่ select อยู่ (กัน state ซ้อน) ใช้ AABB เดียวกับ selection
> ทำคู่กับ [#5](#5)

---

<a name="44"></a>
### #44 — เพิ่มหมวดหมู่ object "Foods & Drink" `Object · 🟡 Low · Effort M · Conf. high`

**Feedback เดิม (UX/UI #44):** "เพิ่มหมวดหมู่ Foods & Drink"

**ไฟล์ที่เกี่ยวข้อง:**
- FE: `zyra-app/lib/api/objects.ts` (`ObjectType` union L6 — single source of truth), `views/admin/object-management/constants.ts` (`OBJECT_TYPES` L15–56, `DEFAULT_Z_INDEX` L66–75, `deriveCollisionModeFromType`/`deriveZIndexFromType` L84–95), `object-type-badge.tsx` (`TYPE_CONFIG` L6–15 — exhaustive `Record<ObjectType,…>`), `object-filter-menu.tsx` (`TYPE_OPTIONS` L7–16), `views/admin/workspace-editor/components/object-library-panel.tsx` (`CATEGORY_FILTERS` L32–45), `left-panel-constants.ts` (icon switch L76–95), `messages/en.json` + `th.json`
- BE: `zyra-api/internal/model/object.go` (const L6–13, `validObjectTypes` L39–47, `IsValidObjectType` L55), `internal/service/workspace_service.go` (`footprintBlocked` L602–616), `internal/service/private_zone_claim_service.go` (allowed-type L36, budget L312)

**สาเหตุ / บริบทปัจจุบัน:**
ระบบ **ไม่มี field "category" แยก** — ตัวกรอง "Category" ของ object library คือ enum `ObjectType` ตรง ๆ · ปัจจุบันมี 8 ค่า: `furniture, decoration, structure, sofa, walkable_group, interactive_barrier, wall, machine` · การเพิ่มหมวดใหม่ = เพิ่ม `ObjectType` ใหม่ ต้องเติมให้ครบทุกจุด มิฉะนั้น `TYPE_CONFIG` (exhaustive `Record<ObjectType,…>`) จะทำ build พัง

**แนวทางแก้:**
เพิ่มค่า `foods_and_drink` (แนะนำให้ behave เหมือน `decoration` = walkable):
1. **FE:** `objects.ts` union → `OBJECT_TYPES` + `DEFAULT_Z_INDEX` + derive helpers → `TYPE_CONFIG` (สี badge) → `TYPE_OPTIONS` → `CATEGORY_FILTERS` (key + labelKey + lucide icon) → icon switch (`case "foods_and_drink"`) → i18n keys `objectTypeFoodsAndDrink`/`…Description`/`objectTypeBadgeFoodsAndDrink`/`objectFilterTypeFoodsAndDrink`/`objectLibraryCategoryFoodsAndDrink` (ทั้ง en + th) → mirror ใน VO placement helper ถ้าให้ walkable (`pzTileAt` L5200/`pzIsOccupied` L5301–5304)
2. **BE:** const + `validObjectTypes` map (gate `IsValidObjectType` ที่ handler) → `footprintBlocked` (ใส่ใน branch walkable) → allowed-in-private-zone + budget ถ้าให้ claimant วางได้
3. **DB:** ไม่ต้อง migration — `object_type` เป็น string ไม่มี CHECK/enum (validation อยู่ที่ Go map `validObjectTypes`)

---

## Member

<a name="7"></a>
### #7 — เมนูโปรไฟล์เพื่อน: ตัดชื่อ avatar ออกจาก label `Member · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "Profile ของเพื่อน มีแค่ชื่อเมนูครับ ไม่เอาชื่อ Avatar (Follow, Request to lead, Go to)"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/views/user/virtual-office/components/player-context-menu.tsx` (L150–173, header L80–117), `messages/en.json`/`th.json`, `hero-virtual-office.tsx` (render L7700)

**สาเหตุ / บริบทปัจจุบัน:**
`PlayerContextMenu` (คลิก avatar คนอื่น) มี 3 เมนูที่ใส่ชื่อคนต่อท้ายผ่าน interpolation: `t("followName", {name})` → "Follow {name}", `t("requestToLeadName", {name})`, `t("goToName", {name})`
feedback ต้องการเหลือแค่ "Follow" / "Request to lead" / "Go to" · **คีย์แบบไม่มีชื่อมีอยู่ครบแล้ว** (`goTo` L717, `follow` L1194, `requestToLead` L1195) และ `pz-zone-card.tsx` ก็ใช้ label แบบไม่มีชื่ออยู่แล้ว → เป็น convention ที่ตรงกับ feedback

**แนวทางแก้:** แก้ `player-context-menu.tsx` 3 จุด (L151/159/167): เปลี่ยนเป็น `t("follow")` / `t("requestToLead")` / `t("goTo")` คง `onFollow/onRequestToLead/onGoTo` เดิม · คีย์ `followName/requestToLeadName/goToName` (L1078–1080) กลายเป็น unused ลบได้ · **คง header (avatar + ชื่อ + สถานะ) ไว้** (feedback พูดถึงเฉพาะ "ชื่อเมนู") — ถ้าทีมตีความว่าต้องซ่อนชื่อใน header ด้วยควร confirm Figma ก่อน

---

<a name="10"></a>
### #10 — Meeting room / Circle ไม่ขึ้นเมนูห้องตาม Design `Member · 🟡 Low · Effort L · Conf. med`

**Feedback เดิม:** "ตอนกด Meeting room กับ Circle ยังไม่มี Menu ห้องขึ้นมาเหมือนตัว Design" · [Figma 1951-241763](https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-?node-id=1951-241763)

**ไฟล์ที่เกี่ยวข้อง:** `hero-virtual-office.tsx` (`handleZoneClick` ~L6612–6682, render `ZoneHoverCard` L8061–8090, `allProximityCirclesRaw` L6434–6452), `zone-hover-card.tsx`, `pixi-game/scene.ts` (`zoneAtWorldPoint` L250), `pixi-canvas.tsx` (`setOnTeleportClick` L5319)

**สาเหตุ / บริบทปัจจุบัน:**
เมนูห้องคือ `ZoneHoverCard` (render เมื่อ `clickedZone !== null`) แต่ `handleZoneClick` เปิดการ์ดนี้**เฉพาะ `zone.zone_type === "meeting"`** (ถ้าไม่ใช่ meeting → `setClickedZone(null)` แล้ว return L6642–6647)
- **Meeting room:** การ์ดที่ขึ้นคือ `ZoneHoverCard` ปัจจุบัน อาจไม่ตรง Figma 1951-241763
- **Circle:** circle เป็น proximity chat-space ไดนามิก (ไม่ใช่ `MapZone` record จริง) — `zoneAtWorldPoint` hit-test เฉพาะ `visibleZones` → คลิกวง circle ไม่ resolve เป็น zone ใด ๆ → **ไม่มีเมนูขึ้นเลย**

**แนวทางแก้:**
1. ทำ/ปรับ component เมนูห้องให้ตรง Figma 1951-241763 (ต่อยอด `zone-hover-card.tsx` หรือแยก `vo-room-menu.tsx`)
2. **Meeting room:** ปรับ layout/ปุ่มให้ตรง design (Join / Copy link / participants / invite)
3. **Circle:** เพิ่ม hit-test การคลิกวง circle ใน Pixi scene (เลียนแบบ `_teleportZoneAt`/`_lockedZoneAt`) แล้ว expose callback (เช่น `setOnCircleClick` ผ่าน `pixi-canvas.tsx`) กลับมา hero → map `circleId` → เมนูเดียวกัน ดึง participants จาก `chatSpaceSessions` · copy-link fallback เป็นลิงก์ workspace เปล่า
> ควรยืนยัน spec ปุ่ม/ฟิลด์กับ Figma ก่อนลงมือ

---

## Avatar

<a name="8"></a>
### #8 — Request to lead ไม่มี notification (ยังเป็น stub) `Avatar · 🟡 Low · Effort L · Conf. high`

**Feedback เดิม:** "ตอนกด Request to lead อีกฝั่งไม่มี Notification ปรากฏ" · Remark: **เพิ่ม Notification**

**ไฟล์ที่เกี่ยวข้อง:** `hero-virtual-office.tsx` (`onRequestToLead` L7756–7764), `player-context-menu.tsx` (L158–165), `zyra-app/lib/api/workspace-ws.ts`, `zyra-ws/internal/hub/message.go`, `vo-wave-notification.tsx` (pattern อ้างอิง)

**สาเหตุ / บริบทปัจจุบัน:**
ปุ่ม "Request to lead" เรียก `onRequestToLead` ซึ่งใน hero **จัดการเฉพาะ mock player** (set `following:true`) ส่วนผู้ใช้จริง**ไม่ทำอะไรเลย** — ไม่ส่งข้อความไปฝั่งไหน
ยืนยันว่า**ไม่มี method `requestToLead` ใน `workspace-ws.ts`** (grep = 0) และใน `message.go` มีแค่ `MsgWaveReceived`/`MsgFollowStarted`/`MsgKnockRequest` **ไม่มี type สำหรับ lead** → ฝั่งผู้ถูกร้องขอไม่เคยได้รับ event → ไม่มี notification (root cause = feature นี้ยังไม่ถูก implement จริงฝั่ง realtime)

**แนวทางแก้ (ทำตาม pattern wave/knock):**
1. **zyra-ws:** เพิ่ม inbound ClientMsg `"request_to_lead"` + outbound unicast `MsgLeadRequested` (payload `requester_user_id/name/avatar`) ใน `message.go` + handler ยิงไป `target_user_id`
2. เพิ่ม method `requestToLead(targetUserId)` ใน `workspace-ws.ts` (ใช้ `_send` เหมือน wave/follow)
3. แก้ hero `onRequestToLead` ให้เรียก `wsClientRef.current?.requestToLead(userId)` แทน no-op
4. สร้าง `VOLeadNotification` เลียนแบบ `vo-wave-notification.tsx` (toast มุมขวาบน, lucide, Tailwind-only, i18n) มีปุ่ม accept/decline โดย accept เรียก follow flow ที่มีอยู่
> งานข้ามหลาย service

---

<a name="28"></a>
### #28 — click-to-move ไม่ให้ลากเส้นทางทะลุ Meeting Room `Avatar · 🟡 Low · Effort M · Conf. high`

**Feedback เดิม:** "เมื่อ click เดิน ไม่ให้ผ่าน Meeting Room"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/zyra-engine/canvas-game/pathfinding.ts` (`findPath`, `GridContext`), `zyra-app/zyra-engine/pixi-game/scene.ts` (`onClick` ~L1272, `_isDodgeForbiddenZone` L3930–3937, locked check L2069–2083, `_gridCtx` getter L3767)

**สาเหตุ / บริบทปัจจุบัน:**
click-to-move เรียก `_findPath → findPath()` — A* ใช้ต้นทุนคงที่ (`g = cur.g + 1`) และ `GridContext` มีแค่ `blockedTiles/wallTiles/wallTileDirections`
Meeting room ไม่ได้อยู่ใน `blockedTiles` แต่เก็บเป็น zone (`_spotlightZones` ที่ `zoneType === "meeting"`) → **พื้นห้อง meeting ที่เดินได้ถูก A* ลากผ่านได้อิสระ** (การกันปัจจุบันมีแค่ตอน overlap-dodge + locked check กลางทาง ไม่ได้กันตอนวางเส้นทาง)

**แนวทางแก้:** เพิ่ม `avoidTiles` (soft-cost) `Set<string>` เข้า `GridContext` แล้วบวก penalty สูงตอน expand (`g += PENALTY`) **ยกเว้นเมื่อ destination อยู่ในห้อง meeting นั้นเอง** (ผู้ใช้ตั้งใจคลิกเข้าไป) · ใน `scene.ts` สร้าง meeting-tile set จาก `_spotlightZones` (rect → tile keys) ส่งเข้า `_gridCtx` → เส้นทางจะอ้อม Meeting Room เว้นแต่ปลายทางอยู่ในห้อง (งาน FE engine 2 ไฟล์)

---

<a name="41"></a>
### #41 — เพิ่มฉายา/nickname บน name tag `Avatar · 🟡 Low · Effort L · Conf. med`

**Feedback เดิม:** "เพิ่มขึ้นฉายา"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/zyra-engine/pixi-game/utils.ts` (`makeNameTag` L460–477), `.../scene.ts` (`_updateNameTag` L3232–3294, `setPlayerName` L3006–3007), `hero-virtual-office.tsx`, `lib/api/workspace-members.ts`, `zyra-ws/internal/hub/message.go`, `zyra-api/internal/model/workspace_member.go`

**สาเหตุ / บริบทปัจจุบัน:**
name tag แสดงชื่อ**บรรทัดเดียว** (`makeNameTag()` สร้าง Text อันเดียว) จาก `character_name`/`display_name` · **ปัจจุบันไม่มี field ฉายา/nickname/title แยก** — `character_name` เก็บที่ `tb_workspace_member.character_name` (broadcast ผ่าน WS snapshot)

**แนวทางแก้ (end-to-end):**
1. **zyra-api:** migration เพิ่มคอลัมน์ `title`/`nickname` ที่ `tb_workspace_member` + field ใน model + handler update
2. **zyra-ws:** เพิ่มใน `PlayerSnapshot`/welcome/joined + profile-update payload (`message.go`)
3. **FE:** เพิ่ม field ใน `workspace-ws-types.ts`, ส่งค่า self เข้า `mapConfig` + รับจาก remote snapshot, แก้ `makeNameTag()` ให้มี Text บรรทัดที่สอง (subtitle/ฉายา) + `_updateNameTag()` จัด layout/pill สูงขึ้น, เพิ่มช่องกรอกใน profile form (Tailwind-only, i18n)
> งานข้าม service (DB+API+WS+FE)

---

## Decoration

<a name="32"></a>
### #32 — เพิ่มปุ่มลัด Delete ลบ object ที่เลือก `Decoration · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "ยังไม่มี Key delete"

**ไฟล์ที่เกี่ยวข้อง:** `hero-virtual-office.tsx` (keydown handlers L640/3483/3579/4875, `pzSelectedId` L467, `handlePzDelete` L5648, `ObjectContextMenu onDelete` L7491), `pz-edit-hud.tsx`

**สาเหตุ / บริบทปัจจุบัน:** มี keydown handler หลายตัวแต่**ไม่มีตัวใดผูก Delete/Backspace กับการลบ object** — การลบทำได้เฉพาะผ่านปุ่ม trash ใน `ObjectContextMenu` · state ที่เลือก = `pzSelectedId`, ตัวลบ = `handlePzDelete` พร้อมใช้แล้ว จึงขาดแค่ตัวรับคีย์บอร์ด

**แนวทางแก้:** เพิ่ม `useEffect` ผูก `window` `keydown` gate ด้วย `pzEditMode && pzSelectedId` เมื่อ `Delete`/`Backspace` → `void handlePzDelete(pzSelectedId)` โดย (1) ข้ามเมื่อ focus อยู่ใน input/textarea (ช่อง search) (2) เคารพ `is_locked`/`pzCanEditObject` เหมือนปุ่มในเมนู (3) `preventDefault` กัน browser back · อาจเพิ่ม hint คีย์ลัดใน `pz-edit-hud.tsx`

---

<a name="34"></a>
### #34 — ห้ามลบ walkable_group/กระเบื้องที่หลังบ้านวางไว้ `Decoration · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "หน้าบ้านไม่มีให้วาง Walkable group → ผู้ใช้ก็ไม่ควรลบ walkable group ที่หลังบ้านวางมาให้ แต่ตอนนี้หน้าบ้านยังลบกระเบื้องได้อยู่" · [วิดีโอ](https://drive.google.com/file/d/1gnuzl6IjwAlZCpUDglGVv9c0ij1QObGS/view)

**ไฟล์ที่เกี่ยวข้อง:** `hero-virtual-office.tsx` (`PZ_DENIED_TYPES` L231, `pzObjectAtWorld` L5276, `pzCanEditObject` L5328/5340–5345, `handlePzDelete` L5648, non-editable logic L7444–7446), `object-context-menu.tsx` (Delete L403–420, prop `objectType` L66)

**สาเหตุ / บริบทปัจจุบัน:**
`PZ_DENIED_TYPES = ['wall','walkable_group','interactive_barrier']` ถูกใช้กรอง**เฉพาะ palette** (ห้าม*วาง*) แต่ `pzObjectAtWorld` สแกน object ทุกชิ้นแบบ bypass ownership และ `pzCanEditObject` อนุญาตให้ member แก้ object ที่ overlap zone rect ของตน → **walkable_group/กระเบื้องที่ backend วางถูกเลือกและลบได้** (`handlePzDelete` ไม่มี guard ตาม type, ObjectContextMenu แสดง Delete เสมอ)

**แนวทางแก้:** เพิ่มเงื่อนไขใน `pzCanEditObject` ให้ return `false` ถ้า `o.object_type` อยู่ใน `PZ_DENIED_TYPES` (โดยเฉพาะ `walkable_group`/`wall`) → ได้ผลเป็น red outline ไม่มี object menu เหมือน foreign object (reuse ระบบ non-editable เดิม L7444–7446) · หรือซ่อน/disable ปุ่ม Delete ใน `object-context-menu.tsx` เมื่อ `objectType === 'walkable_group'/'wall'` — **แนวทางแรกสอดคล้อง convention มากกว่า**

---

<a name="35"></a>
### #35 — Clear all ต้องกดได้แม้ save แล้ว/กลับมา edit ใหม่ `Decoration · 🟡 Low · Effort M · Conf. high`

**Feedback เดิม:** "อยากให้ปุ่ม Clear all กดได้แม้เซฟ Object ไปแล้ว และพอกลับมา Edit Decoration อีกครั้งก็ยังกดได้เพราะยังมี Object อยู่"

**ไฟล์ที่เกี่ยวข้อง:** `pz-edit-hud.tsx` (`disabled={!canUndo}` L444), `hero-virtual-office.tsx` (`canUndo={pzUndoStack.length > 0}` L7891, `handlePzSave` L5868, `pzPlacedCount` L4520)

**สาเหตุ / บริบทปัจจุบัน:**
ปุ่ม Clear (Eraser) ตั้ง `disabled={!canUndo}` โดย `canUndo = pzUndoStack.length > 0` · `handlePzSave` ออกจากโหมดโดยไม่เก็บ history ข้ามเซสชัน → กลับเข้ามา edit ใหม่ `pzUndoStack` ว่าง → **Clear all ถูก disable ทั้งที่ยังมี object** → **เงื่อนไข enable ผูกผิดตัว** (ผูกกับ undo stack แทนจำนวน object จริง)

**แนวทางแก้:** เปลี่ยนเงื่อนไข enable ให้ผูกกับจำนวน object จริง: เพิ่ม prop `canClear` ให้ `PZEditHud` ส่ง `canClear={pzPlacedCount > 0}` แล้วใช้ `disabled={!canClear}` ที่ปุ่ม Eraser (คง `canUndo`/`canRedo` เดิมสำหรับ undo/redo) · **ทำร่วมกับ [#36](#36)** (แก้ semantics ของ `handlePzClear` ให้เป็นลบ object ทั้งหมดจริง)

---

<a name="36"></a>
### #36 — Clear all หลังลบ object กลายเป็น Undo all `Decoration · 🟡 Low · Effort M · Conf. high`

**Feedback เดิม:** "ตอนลบ Object ที่วางไว้ และพอกด Clear all กลับกลายเป็นเหมือน Action Undo all" · Remark: `Screen Recording 2569-07-22 at 12.23.21.mov`

> **หมายเหตุ:** ตารางระบุ Type = Improve แต่จริง ๆ เป็นการแก้พฤติกรรมที่ผิด — ควรทำคู่กับ [#35](#35)

**ไฟล์ที่เกี่ยวข้อง:** `hero-virtual-office.tsx` (`handlePzClear` L5852, `pzRevertAll`, `pzRevertAction` L5707, re-create L5731–5753, `handlePzDelete` L5648–5701), `pz-edit-hud.tsx`

**สาเหตุ / บริบทปัจจุบัน:**
`handlePzClear` เรียก `pzRevertAll(pzUndoStack)` ซึ่ง revert (inverse) ทุก action ของ session — `pzRevertAction` แปลง action `'delete'` เป็นการ**re-create object กลับมา** → ลบ object แล้วกด Clear all → object ที่ลบถูกสร้างกลับ = **พฤติกรรม Undo all ไม่ใช่ล้างทุกชิ้น** (root cause = Clear all ถูก implement เป็น "ย้อน action ทั้งหมด" ไม่ใช่ "ลบ object ทั้งหมดในโซน")

**แนวทางแก้:** เขียน `handlePzClear` ใหม่ให้ลบ object ทุกชิ้นในโซนจริง: filter `data.mapObjects` ตาม `activeZoneId` (`pzAdminTargetZoneId ?? myZoneClaim?.zone_id`) เฉพาะชิ้นที่ `pzCanEditObject` อนุญาตและไม่ใช่ `PZ_DENIED_TYPES` แล้วเรียก `removeMapObject` ทีละชิ้น + optimistic update + `playTestRef.applyObjectDelta('remove', ...)` เหมือน `handlePzDelete` และ push delete actions เข้า undo stack (ให้ยัง undo กลับได้) แทน `pzRevertAll` · **แก้ควบคู่กับเงื่อนไข enable ใน [#35](#35)**

---

## Map Template

<a name="40"></a>
### #40 — เปลี่ยน "โรงเรียน" → "สถานศึกษา" `Map Template · 🟡 Low · Effort S · Conf. high`

**Feedback เดิม:** "คำว่า โรงเรียน เปลี่ยนเป็น สถานศึกษา"

**ไฟล์ที่เกี่ยวข้อง:** `zyra-app/messages/th.json` (L2331 `"workspaceCategorySchool": "โรงเรียน"`), `.../left-panel-constants.ts` (`WORKSPACE_CATEGORY_LABEL_KEYS` L46–53), `editor-build-workspace-modal.tsx` (L524/751), `left-panel.tsx` (L825)

**สาเหตุ / บริบทปัจจุบัน:**
คำว่า "โรงเรียน" มีอยู่**ที่เดียวจริง ๆ** คือ i18n `th.json` L2331 คีย์ `workspaceCategorySchool` (en.json = "School") ถูก map จากหมวด "School" ผ่าน `WORKSPACE_CATEGORY_LABEL_KEYS` และเรนเดอร์ด้วย `t(...)` ใน 2 จุด (tab กรองหมวดในโมดัล Map Template + dropdown เลือกหมวดใน left panel)
> badge หมวดบนการ์ด template แสดง `template.category_name` ดิบจาก backend (seed = "School" อังกฤษ) → **ไม่ใช่คำว่า "โรงเรียน" ที่ feedback พูดถึง**

**แนวทางแก้:** แก้ค่าใน `th.json` L2331 จาก `"โรงเรียน"` เป็น `"สถานศึกษา"` — **แก้ i18n จุดเดียว** propagate อัตโนมัติทุกที่ที่เรียก `t("workspaceCategorySchool")` โดยไม่ต้องแตะ component · คง en.json = "School" และคง key/enum "School" + backend seed (เป็น identifier ที่ match category)
> scope note: ถ้าอยากให้ badge หมวดบนการ์ด (`category_name` ดิบ) เป็นไทยด้วย ต้อง map ผ่าน `WORKSPACE_CATEGORY_LABEL_KEYS` ก่อนแสดง — เกินขอบเขต feedback ข้อนี้
