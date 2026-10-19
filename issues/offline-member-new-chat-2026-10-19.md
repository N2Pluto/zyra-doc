# สมาชิกที่ Offline เลือกเริ่ม New chat ไม่ได้ (web + mobile)

> **สถานะ:** แก้แล้วบน branch `fix/offline-member-dm` — PR [zyra-app#622](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/622) (2026-10-19) · **build + unit test เขียว · ยังไม่ได้ live-test บน dev** (ดู [Verify ถึงไหน](#verify-ถึงไหน))
> **Repo ที่กระทบ:** `zyra-app` (Virtual Office — member panel + player context menu) · zyra-mobile เป็น WebView โหลด zyra-app จึงได้ fix เดียวกันเมื่อ deploy · **ไม่ต้องแก้ `zyra-api`**
> **ที่มา:** Ten รายงานในแชท 2026-10-19

---

## อาการ

สมาชิกใน workspace ที่สถานะ **Offline** (ไม่ได้ต่อ WS อยู่) เลือกเพื่อเริ่มแชทใหม่ไม่ได้ — เกิดทั้งบน web app และ mobile app (Lite / Spatial)

สิ่งที่ควรเป็น: ส่งข้อความหาสมาชิกคนไหนก็ได้ไม่ว่าจะ online หรือไม่ — แชทเป็น persistent คนที่ offline จะเห็นข้อความเมื่อกลับมา

---

## Root cause

ไล่ทุกทางที่เปิด DM ได้ในโค้ด (`getOrCreateDM(` ทุกจุด) แล้วพบว่ามี **จุดเดียว** ที่กั้นตาม presence คือ **member panel ใน Virtual Office** — ไม่ใช่ chat picker และไม่ใช่ API

### 1. แถว Offline ใน member panel ไม่มี `onClick`

`zyra-app/views/user/virtual-office/components/vo-member-panel.tsx` — ส่วน **Online** ส่ง `onClick={() => onMemberClick?.(member.user_id)}` ให้ทุกแถว แต่ส่วน **Offline** render `<MemberRow>` (desktop) และ `<PhoneMemberRow>` (phone drawer ของ Spatial บนมือถือ) **โดยไม่ส่ง `onClick` เลย** — comment ของ prop ก็เขียนไว้ตรง ๆ ว่า "Called with the userId when an *online* (non-self) member row is clicked" กดแถว offline จึงไม่เกิดอะไร

### 2. ตัวแปลง click → context menu รู้จักเฉพาะคน online

`hero-virtual-office.tsx` — `clickedMenuPlayer` (useMemo) หา player จาก `otherPlayers` (WS roster = คน online) แล้วจาก `mockPlayers` เท่านั้น ถ้าไม่เจอคืน `null` → ต่อให้แถว offline กดได้ ก็ไม่มี `PlayerContextMenu` ขึ้นมาให้กด **Message** (ส่งข้อความ)

### สิ่งที่ตรวจแล้วว่า *ไม่ใช่* สาเหตุ

| ที่ | ผล |
|---|---|
| `views/chat/components/start-new-chat-panel.tsx` (picker "Start a new chat" ใน chat tab — ทั้ง web และ Lite) | ดึงจาก `useWorkspaceMembers` แล้ว filter แค่ `status === "confirm"` + ไม่ใช่ตัวเอง — **ไม่ได้ filter ตาม presence** · `presenceOf()` ใช้แค่วาดจุดสถานะ |
| `zyra-api` `ChatService.GetOrCreateDM` (`internal/service/chat_service.go`) | เช็คแค่ self / เป็นสมาชิก workspace / block — **ไม่มีเช็ค online** · `ListConversations` / `memberPreviews` ก็ไม่ filter presence |
| `/api/user/workspaces/:id/members` (`ListMembers`) | คืนสมาชิก confirmed ทุกคน ไม่ขึ้นกับ `last_visited_at` |
| Lite Home → member row → profile sheet (`lite-home.tsx`, `lite-home-sheets.tsx`) | แถว offline ส่ง `onOpen` และ sheet มีปุ่ม Message ให้คน offline อยู่แล้ว (ซ่อนแค่ Wave) |
| deployed code vs develop | `git diff v1.8.3 origin/develop` ในไฟล์ picker/chat = ว่าง — prod เท่ากับที่อ่าน |

> ถ้า Ten เจออาการที่ **picker "Start a new chat" ใน chat tab** โดยตรง (ไม่ใช่จาก member panel) ต้องขอ repro เพิ่ม (account / workspace / ชื่อสมาชิก / ขึ้น toast อะไร) เพราะในโค้ดไม่มี gate ตรงนั้น

---

## สิ่งที่แก้ (PR zyra-app#622)

| ไฟล์ | แก้อะไร |
|---|---|
| `components/vo-member-panel.tsx` | แถว Offline (desktop + phone drawer) ส่ง `onClick={() => onMemberClick?.(member.user_id)}` เหมือนแถว Online (+ `onMouseLeave` สำหรับ locate-highlight) · แก้ comment ของ prop |
| `utils/member-menu-player.ts` (ใหม่) | `resolveMemberMenuPlayer()` — pure function: live player → mock → **confirmed member เป็น `status: "offline"`** · แทน `useMemo` เดิมใน hero (ใช้ state `allWorkspaceMembers` เป็น dep แทนอ่าน ref) |
| `components/player-context-menu.tsx` | `status === "offline"` → label "Offline" (ออฟไลน์) จุดสถานะเทา · เหลือแค่ **Message** + Report / Block · ซ่อน Wave / Follow / Request to lead / Go to (ต้องมี sprite บนแผนที่) ทั้ง desktop card และ phone sheet |
| `hero-virtual-office.tsx` | กดแถว offline ซ้ำครั้งที่สอง → ปิด menu เฉย ๆ ไม่ toast "They are on another floor" (เขาอยู่คนละชั้น) ซึ่งใช้กับคน online ที่อยู่ชั้นอื่นเท่านั้น |
| `__tests__/offline-member-dm.test.tsx` (ใหม่) | 12 เคส: resolver (live / mock / offline / case-insensitive / ไม่รู้จัก), panel กดแถว offline ได้ (desktop + drawer, แถวตัวเองกดไม่ได้), menu offline มีแค่ Message / online มีครบ |

ไม่แตะ `zyra-api`, `zyra-ws`, `zyra-mobile`

---

## Verify ถึงไหน

| ระดับ | ผล |
|---|---|
| `vitest run` ทั้งชุด | ✅ 381 files / 4565 tests ผ่าน |
| `eslint` ไฟล์ที่แก้ | ✅ 0 error (warning ที่ขึ้นใน hero มีอยู่ก่อนแล้ว) |
| `tsc --noEmit` | ✅ ไม่มี error ในไฟล์ที่แก้ (error ที่เหลือใน `__tests__/pixi-game-scene.test.ts`, `pet-creation-wizard.test.tsx`, `environment-weather-fx.test.ts` มีอยู่ก่อนบน develop) |
| live-test บน dev | ❌ **ยังไม่ได้ทำ** — built-in browser ไม่ได้ login dev และอีก session กำลังขอ Ten login อยู่ จึงไม่เปิดคำขอซ้ำ |

**ขั้นตอน live-test หลัง merge เข้า develop (dev deploy อัตโนมัติ):**
1. Web: เข้า Virtual Office → Member panel → ส่วน **Offline** → กดชื่อสมาชิก → ต้องขึ้น context menu ที่มีสถานะ "Offline" และปุ่ม **Message** (ไม่มี Wave / Follow / Go to) → กด Message → chat half view เปิด DM กับคนนั้น → ส่งข้อความได้
2. Mobile (Spatial landscape): เปิด member drawer → แถว Offline → กดแล้วต้องขึ้น sheet แบบเดียวกัน
3. กดแถว offline ซ้ำ → menu ปิด ไม่มี toast "They are on another floor"
4. Regression: แถว Online ยังเปิด menu ครบ (Message / Wave / Follow / Request to lead / Go to) และกดซ้ำยัง pan กล้องไปหา

## Before/After

ยังไม่ได้วัด — เป็น UI gate (ปุ่มไม่มี handler) ไม่ใช่ perf/incident · metric ที่พอดูได้หลัง deploy: จำนวน `POST /api/user/chat/conversations/dm` ที่ยิงจาก `vo-player-menu-message` (track id) สำหรับ target ที่ offline — ก่อนแก้เป็น 0 โดยโครงสร้าง
