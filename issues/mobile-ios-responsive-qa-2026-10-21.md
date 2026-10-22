# Mobile Responsive (iOS Safari) — QA รอบ 2026-10-21 · spec + plan แก้

> **สถานะ:** แก้แล้ว 5 การ์ด (I-01, I-03, I-04, I-05, I-06/I-08) — zyra-app [#635](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/635) merge เข้า `develop` `919e099` (deploy dev อัตโนมัติ) · **ยังไม่เทสบนเครื่อง** · I-02 ไม่แก้ (QA เข้าใจผิด) · I-07 ปิดแล้วไม่ทำ · ดู [§6](#6-ความคืบหน้า) · **วันที่:** 2026-10-21 · **ผู้รับผิดชอบ:** rif · **Repo ที่กระทบ:** zyra-app (หลัก) · zyra-api ไม่กระทบ (เว้นแต่มติข้อ Q3)
> **ที่มา:** ClickUp parent [[Feature] · Mobile Responsive + App Conversion (iOS & Android)](https://app.clickup.com/t/86d4bfpym) (SC-MOB-01) — subtask ที่ยังเปิด 8 ใบ เปิดโดย QA (Pornnapa) 2026-10-21 · ทุกใบ assign rif
> **หลักฐาน:** รูป 3 ใบ + วิดีโอ 2 คลิปจากการ์ด (ตัดเป็นภาพทีละ frame ดูแล้ว) · root cause อ่านจากโค้ด `zyra-app` (`feat/calendar` ซึ่งไฟล์ที่อ้างถึงเหมือน `develop` @ `f6a1f7f` ทุกไฟล์ ยกเว้น `hero-virtual-office.tsx` ที่เลขบรรทัดเลื่อน ~30–60 หลังบรรทัด 12200) — **ยังไม่ได้ทดสอบบนเครื่องจริง** เลขบรรทัดอาจเลื่อน ค้นด้วยชื่อ function/class
> **เกี่ยวข้อง:** [plan/MobileApp](../plan/MobileApp/) · [mobile-qa-portrait-assignment-2026-10-14.md](mobile-qa-portrait-assignment-2026-10-14.md)

## 1. Scope

ทั้ง 8 ใบเป็น **เว็บบน iOS Safari** (`app.dev.zyra.center`) ไม่ใช่แอป Capacitor — 7 ใบเป็น iPhone แนวนอน (Spatial), 1 ใบเป็น iPad แนวนอน

| # | การ์ด | อุปกรณ์ / หน้า | สถานะ ClickUp | กลุ่ม PR |
|---|---|---|---|---|
| I-01 | [UI ไม่เต็มจอ + ปุ่ม Account Setting ไม่ถูกต้อง](https://app.clickup.com/t/14zd0zudjj4) | iPad แนวนอน · Space builder | Open | P5 |
| I-02 | [Character Name ไม่ตรง Display Name + ตัวละครเล็กไป](https://app.clickup.com/t/14zd0zudjjv) | iPhone · VO Spatial | Open | P7 |
| I-03 | [Banner "Zyra World Dev – เปิดในแอป" ทับปุ่ม Chat/Member/Lock](https://app.clickup.com/t/14zd0zudjnd) | iPhone แนวนอน · ห้อง Meeting | Open | P4 |
| I-04 | [พิมพ์ Chat ใน Meeting แล้วหน้าจอทับกัน ต้องกด ✓ ก่อนส่ง](https://app.clickup.com/t/14zd0zudjnh) | iPhone 17 Pro แนวนอน · Meeting chat | Open | P2 |
| I-05 | [หน้า Create an announcement ทับซ้อน](https://app.clickup.com/t/14zd0zudjtv) | iPhone · Announcement | Open | P6 |
| I-06 | [ปุ่ม Notification กับ Meeting Rooms ทับกัน](https://app.clickup.com/t/14zd0zudke8) (การ์ดระบุ iOS + Android) | iPhone แนวนอน · VO Spatial | Open | P1 |
| I-07 | [แป้นพิมพ์ iPhone บังช่อง Chat](https://app.clickup.com/t/14zd0zudkf9) | iPhone แนวนอน · หน้า Chat | **blocked** (ไม่มีเหตุผลในการ์ด — ต้องถาม QA/PM) | P3 |
| I-08 | [ลากจอแล้วปุ่ม Action ทับกัน](https://app.clickup.com/t/14zd0zudkhr) | iPhone แนวนอน · VO Spatial | Open | P1 |

**ไม่อยู่ใน scope:** เปลี่ยน layout ของ Lite (แนวตั้ง) · เปลี่ยน design ปุ่ม/ไอคอน · แก้ใน native app (zyra-mobile) · เปลี่ยน ClickUp status (สิทธิ์ PM/QA)

## 2. รายละเอียดต่อการ์ด

แต่ละข้อแยก: **อาการ (จาก QA)** · **ผลตรวจหลักฐาน** · **ต้นเหตุ (จากโค้ด)** · **แผนแก้ (ข้อเสนอ)** · **Acceptance criteria**

### I-06 + I-08 — ปุ่มลอยมุมขวาทับกันใน Spatial แนวนอน (P1)

**อาการ:** ปุ่ม Notification (badge) ซ้อนกับปุ่ม Meeting Rooms (กล้อง) · เมื่อลากหน้าจอให้ banner เปิดแอปหาย ปุ่ม Action ยิ่งทับกัน

**ผลตรวจหลักฐาน:** รูป `Zyra World 2.png` — ไอคอนกระดิ่ง (badge 1) กับกล้องรวมเป็นปุ่มเดียว · วิดีโอ I-08 — ตอน banner Safari แสดง คอลัมน์ขวา (กล้อง/กระดิ่ง/ล็อก/pet) บีบจนกล้องกับกระดิ่งซ้อน · ตอน banner หายกระดิ่งหลบอยู่ใต้กล้องทั้งปุ่ม · ทั้งเอกสารเลื่อนตามนิ้ว (page scroll / rubber-band)

**ต้นเหตุ:** `views/user/virtual-office/components/vo-sidebar.tsx` (variant `mobile`)
- แถวบน (Weather, Megaphone, Members, Bell) = `absolute top-[16px]` (`:117`)
- Zone menu (Video = Meeting Rooms, Lock, Paw) = `absolute bottom-[176px] flex-col` (`:165-170`) — ยึดจาก **ล่าง**
- ต้องการความสูง HUD ≥ ~16+40+8 + (3×40+2×8) + 176 ≈ 368px ถึงจะไม่ชน · Figma (`6707:63977`) ออกแบบที่ 844×390 แบบไม่มีแถบ browser · บน Safari แนวนอน visible height = 402 − address bar − banner → ต่ำกว่า 368 → ปุ่มบนสุดของ zone menu (Video) ไปทับ Bell ที่ปลายแถวบน
- I-08: หน้า Spatial ไม่ล็อก scroll ของ document — `useResetWindowScroll` ใช้แค่ใน `lite/lite-shell.tsx:114` · ไม่มี `overscroll-behavior` / body lock (`app/globals.css`) · root เป็น `relative h-dvh` (`hero-virtual-office.tsx` ~`:12933`) → ลากแล้ว document เลื่อน + `dvh` เปลี่ยนตอนแถบ Safari ยุบ → HUD absolute ขยับเทียบกับ overlay fixed

**แผนแก้:**
1. รวมแถวบน + zone menu ไว้ใน container เดียวฝั่งขวา (`flex flex-col`) — zone menu ยึดใต้แถวบน (`top = 16 + hud-round + 8`) แทน `bottom-[176px]` แล้วตรวจว่าไม่ชนคอลัมน์ Locate/zoom ของ minimap (เริ่มที่ ~164px จากล่าง)
2. จอเตี้ย (`[@media(max-height:360px)]` หรือวัดจาก `--zyra-visible-height`) → ลด `--hud-round` เป็น 32 / gap 4 หรือย้าย zone menu ไปซ้ายของ minimap (มี `zoneMenuShifted` → `right-[208px]` อยู่แล้ว ใช้ต่อได้)
3. ล็อก scroll บนหน้า Spatial: `useResetWindowScroll(mobileSpatial)` ใน hero + `overscroll-behavior: none` บน html/body เฉพาะหน้า play (หรือ root เป็น `fixed inset-0`)

**AC:**
- [ ] iPhone แนวนอน Safari (มีและไม่มี banner, แถบ Safari ยุบ/ไม่ยุบ) ปุ่มทุกปุ่มมุมขวาไม่ทับกันและกดได้ครบ
- [ ] ลาก/ปัดบนแผนที่แล้ว document ไม่เลื่อน ปุ่มไม่ขยับ
- [ ] Desktop / Lite / แอป native ไม่เปลี่ยน
- [ ] Android Chrome แนวนอน (การ์ด I-06 ระบุ Android ด้วย) ไม่ทับ

### I-04 — Meeting chat: พิมพ์แล้วจอทับกัน ต้องกด ✓ ก่อนส่ง (P2)

**ผลตรวจหลักฐาน (วิดีโอ):** เปิด Meeting chat → แตะช่อง Message → แผง Meeting chat หดเหลือแค่หัว "Meeting chat" เหนือแป้นพิมพ์ · แถวช่องพิมพ์ไปซ้อนกับแถบปุ่มควบคุม Meeting (กล้อง/ไมค์/ออก) เห็นข้อความที่พิมพ์แค่ครึ่งบรรทัด ปุ่มส่งเห็นแค่ขอบ · ต้องกด ✓ ปิดแป้นก่อน ข้อความถึงจะส่งได้

**ต้นเหตุ:** `views/user/virtual-office/components/zone-enter-chat.tsx` (`MeetingChatPanel` เปิดจาก `vo-mobile-meeting.tsx:271`)
- A. ปุ่ม Send / Emoji ใช้ `onClick` อย่างเดียว ไม่มี `onMouseDown/onPointerDown preventDefault` (`:912-941`) → แตะแล้ว input blur → แป้นเริ่มปิด → แผง (สูงตาม visible height) re-layout → ปุ่มเลื่อนออกจากใต้นิ้วก่อน `click` · ช่องแชทหลักกันไว้แล้วด้วย `onMouseDown={(e)=>e.preventDefault()}` (`message-input.tsx:855`) · Send แสดงเฉพาะ `canSend` → layout เปลี่ยนตอนพิมพ์ตัวแรก
- B. `<EmojiPicker>` ที่ `:957` และ `:1181` **ไม่ส่ง `mobile`** → ได้ popover แบบ desktop (สูง ~300px บนจอ 402px) ที่ search `autoFocus` (`emoji-picker.tsx:111`) เปิดแป้นซ้ำ · ตำแหน่งคำนวณครั้งเดียวจาก `window.innerHeight` (`:716`, `:732`) ไม่ฟัง `visualViewport` · ช่องแชทหลักส่ง `mobile` → ได้ bottom sheet (`message-input.tsx:576-581`)
- C. (จากวิดีโอ — ต้องยืนยันในโค้ด) ตอนแป้นเปิด แถบควบคุม Meeting อยู่ชั้นเหนือ/ตำแหน่งเดียวกับ composer ของแผงแชท → ต้องตรวจ z-index ระหว่างแผงแชท (`zone-enter-chat.tsx:974-994` ที่ pin กับ `--zyra-visible-*`) กับแถบควบคุมใน `vo-mobile-meeting.tsx`

**แผนแก้:**
1. ส่ง `mobile` ให้ `EmojiPicker` ทั้ง 2 จุดใน `zone-enter-chat.tsx` (เหมือน `message-input`)
2. `onPointerDown/onMouseDown={e => e.preventDefault()}` บนปุ่ม Send, Emoji, Attach
3. แสดงปุ่ม Send ตลอด (disabled เมื่อ `!canSend`) ไม่ให้ layout กระโดด
4. ตอนแชทเปิด + แป้นเปิด ให้แผงแชทอยู่เหนือแถบควบคุม Meeting (หรือซ่อนแถบควบคุมชั่วคราว) — ยืนยัน z-order ก่อน

**AC:**
- [ ] แตะช่อง Message → เห็นช่องพิมพ์ + ปุ่มส่งเต็ม ๆ เหนือแป้นพิมพ์ ไม่ซ้อนแถบควบคุม
- [ ] พิมพ์แล้วแตะส่ง **ครั้งเดียว** ส่งได้ โดยแป้นยังเปิด
- [ ] เปิด emoji → เป็น bottom sheet ไม่เปิดแป้นซ้อน · เลือกแล้วแทรกในช่อง
- [ ] Desktop meeting chat ไม่เปลี่ยน

### I-07 — หน้า Chat (Spatial แนวนอน): แป้นพิมพ์บังช่องพิมพ์ (P3)

**ผลตรวจหลักฐาน:** รูป `Zyra World 3.png` — แถบ ˄ ˅ ✓ ของ iOS ทับช่องพิมพ์ครึ่งบน ปุ่มส่งโผล่ครึ่งเดียว พื้นที่ข้อความเหลือ ~1 บรรทัด

**ต้นเหตุ:**
- Container หน้า Chat = `fixed inset-0 z-[55]` (`hero-virtual-office.tsx` ~`:15006-15017`) → `ChatSurface view="landscape"`
- Composer (`views/chat/components/message-input.tsx`) ตอน `mobile && flush && focused && keyboard.open` กลายเป็น `fixed inset-x-0 z-[70]` + `bottom: keyboard.inset` (`:127-129`, `:619-629`)
- `hooks/use-keyboard-inset.ts:30` คำนวณ `inset = innerHeight − (vv.offsetTop + vv.height)` — ยึดกับ layout viewport · บน Safari แนวนอน innerHeight เปลี่ยนตาม bar/banner และ iOS เลื่อน window เพื่อโชว์ textarea → inset ≈ 0 ช่วงแอนิเมชัน → bar อยู่ใต้แป้น
- Hero ไม่เรียก `useResetWindowScroll` → หน้าค้างเลื่อนหลังแป้นปิด

**แผนแก้:** ใช้กลไกเดียวกับ Meeting chat
1. ใน hero เรียก `useVisibleViewportVars(chatView !== "closed" && mobileSpatial)` แล้วเปลี่ยน container เป็น `fixed inset-x-0 top-[var(--zyra-visible-top,0px)] h-[var(--zyra-visible-height,100dvh)]` → ทั้งคอลัมน์หดเหนือแป้น composer อยู่ใน layout ปกติ
2. เลิกโหมด `keyboardBar` (fixed + bottom) สำหรับ landscape หรือคำนวณจาก `top = vv.offsetTop + vv.height − barHeight`
3. `useResetWindowScroll(mobileSpatial)` (ใช้ร่วมกับ P1)

**AC:**
- [ ] แตะช่องพิมพ์ → ช่องพิมพ์ + ปุ่มส่งอยู่เหนือแถบ ˄˅✓ ทันที ไม่ต้องเลื่อน
- [ ] ปิดแป้นแล้วหน้ากลับตำแหน่งเดิม ไม่ค้างเลื่อน
- [ ] Lite chat / desktop / แอป native ไม่เปลี่ยน

**ข้อสังเกต:** การ์ดนี้สถานะ `blocked` — ต้องถาม QA/PM ว่า block เพราะอะไรก่อนเริ่ม (Q5)

### I-03 — Banner "เปิดในแอป" ทับปุ่ม Chat / Member / Lock ในห้อง Meeting (P4)

**ผลตรวจหลักฐาน:** วิดีโอทั้ง 2 คลิป — banner `Zyra World Dev · เปิดในแอป Zyra Dev [เปิด]` อยู่ใต้ address bar บังแถบบนของหน้า (หัวห้อง Meeting / ปุ่มบน)

**ต้นเหตุ:** **เป็น banner ของ Safari เอง (Universal Links) ไม่ใช่ component ของเรา → แก้ด้วย z-index ไม่ได้**
- ไม่มี `apple-itunes-app` meta ในโปรเจกต์
- Safari แสดงเพราะ AASA ประกาศ path: `lib/apple-app-site-association.ts:17` `APP_LINK_PATHS = ["/join/*", "/workspace/*"]` → ทุกหน้า `/workspace/*` (รวมหน้า play) เข้าเงื่อนไข · ชื่อ "Zyra Dev" มาจากแอป develop ที่ติดตั้งในเครื่อง QA
- banner ของเราเอง (`components/mobile-app-banner.tsx`, ข้อความ "เปิดแอป") ถูกปิดบนหน้า play แล้ว (`lib/app-banner.ts:89-92`)
- หัวห้อง Meeting (`lite/lite-meeting-view.tsx:153`, `:179-182`) ชิดบน 16px → โดน banner บังจนกว่าจะเลื่อนหน้า

**แผนแก้ (ต้องเลือก — Q3):**
- **ทางเลือก A (แนะนำ):** แคบ AASA ให้ไม่ครอบหน้า play/meeting — เพิ่ม component `exclude` สำหรับ `/workspace/*/play*` (และ `/loading`, `/chat`) หรือเหลือแค่ `/join/*` · ⚠️ เปลี่ยนพฤติกรรม deep link ของลิงก์ meeting/workspace ที่แชร์ → ต้องตกลงกับคนดูแลแอป · Safari cache AASA → เห็นผลหลังติดตั้งแอปใหม่/รอ CDN ของ Apple
- **ทางเลือก B:** คง AASA แล้วดันหัวห้องลงเมื่อตรวจเจอ top ที่ลดลง (`visualViewport.offsetTop` / innerHeight delta) — Safari ไม่บอกความสูง banner ตรง ๆ → ไม่น่าเชื่อถือ
- แจ้ง QA ว่าตัว banner เองซ่อนใต้ UI ไม่ได้

**AC (ถ้าเลือก A):**
- [ ] เปิดหน้า Meeting / VO บน Safari ที่ลงแอปไว้ → ไม่มี banner "เปิดในแอป" · ปุ่ม Chat/Member/Lock กดได้
- [ ] ลิงก์เชิญ `/join/<token>` ยังเปิดแอปได้ (iOS)
- [ ] test `apple-app-site-association` อัปเดตตาม

### I-01 — iPad แนวนอน: Space builder ไม่เต็มจอ + เมนู Account setting ลอยห่าง avatar (P5)

**ผลตรวจหลักฐาน:** รูป `IMG_4769.PNG` (iPad 1180×820 CSS px) — เนื้อหากว้าง ~600px อยู่กลาง ซ้ายขวาว่าง · เมนู Account setting / email / Sign out อยู่ชิดขอบขวาจอ ห่างจาก avatar (ที่อยู่ขอบขวาของคอลัมน์)

**ต้นเหตุ:**
- iPad ถูกนับเป็น mobile UI โดยตั้งใจ (B-40): `lib/platform.ts:18-22, 84-104` touch + ด้านยาว ≤ 1376 → `useMobileUi()` true → `hero-user-workspace.tsx:90-91` render `MobileSpaceBuilder`
- `views/user/workspace/components/mobile-space-builder.tsx:140` คอลัมน์ `mx-auto max-w-[600px]` → ว่างข้าง ๆ บน iPad
- เมนูโปรไฟล์ (`:253-258`) เป็น div `absolute right-[max(16px,…)] top-[calc(64px+…)]` ที่เป็นพี่น้องกับคอลัมน์ ไม่ได้อยู่ในคอลัมน์ → อ้างอิงกับ wrapper `fixed inset-x-0` (`:139`) ที่กว้างเต็มจอ → ไปชิดขอบจอ

**แผนแก้:**
1. ยึดเมนูกับ avatar: ย้ายเมนูเข้าไปใน header ของคอลัมน์ (header เป็น `relative` อยู่แล้ว) หรือห่อ avatar ด้วย `relative` แล้ววาง `absolute right-0 top-[calc(100%+8px)]` — แก้ได้ทันที ไม่ต้องรอมติ
2. ความกว้างบน tablet (Q1): ใช้ `useTabletScale()` (`hooks/use-mobile-ui.ts:84`) ขยายคอลัมน์ + การ์ดเป็น grid 2 คอลัมน์ · **หรือ** ให้ iPad แนวนอนใช้หน้า desktop (`mobileLists = mobileUi && !tabletScale && …`) — ขัดกับ B-40 ต้องให้ PM ตัดสิน

**AC:**
- [ ] เมนูโปรไฟล์เปิดใต้ avatar ชิดขอบขวาของ avatar ทุกขนาดจอ (iPhone, iPad, แนวตั้ง/นอน)
- [ ] iPad แนวนอน ใช้พื้นที่จอตามมติ Q1
- [ ] iPhone ไม่เปลี่ยน

### I-05 — หน้า Create an announcement ทับซ้อน (P6)

**อาการ:** Start publish date, End publish date, Status, ปุ่ม Save as draft ทับกัน (ไม่มีรูปแนบ)

**ต้นเหตุ:**
- มือถือ render `AnnouncementSurface` ใน `MobileSubPage` (`hero-virtual-office.tsx` ~`:14954-14963`) แต่ surface ยังเป็น layout แบ่งซ้าย-ขวาแบบ desktop: `announcement-surface.tsx:258` `flex` + list panel `w-[320px]` (`announcement-list-panel.tsx:105`) → แผงฟอร์มเหลือ ~514px ในแนวนอน และแทบไม่เหลือในแนวตั้ง
- `announcement-form.tsx`: header ปุ่ม `shrink-0` (X + Save as draft + Publish ~320px) บีบชื่อ + root `overflow-hidden` ตัดปุ่ม (`:342-417`) · Schedule `grid grid-cols-2` ตายตัว (`:492`) · Require acknowledgement / Status `grid grid-cols-2` (`:563`)
- `announcement-date-time.tsx` popover ปฏิทิน `absolute left-0 top-[46px] w-[311px]` กว้างกว่าช่องครึ่งคอลัมน์ → ล้นทับช่องข้าง ๆ

**แผนแก้:**
1. มือถือ: master/detail — แสดง list เต็มจอ กด item/สร้าง → ฟอร์มเต็มจอ + ปุ่มกลับ (หรืออย่างน้อย `flex-col` + list `w-full` เมื่อ `mobileSpatial`)
2. ฟอร์ม: grid ทั้ง 2 จุดเป็น container query (`@container` + `@md:grid-cols-2`) เพราะความกว้างแผง ≠ viewport · header `flex-wrap` + ชื่อ `min-w-0 flex-1` · จอแคบย้าย Save as draft / Publish ไป sticky bar ล่าง
3. Popover วันที่: `w-[min(311px,calc(100vw-32px))]` + flip ซ้าย/ขวา หรือ portal

**AC:**
- [ ] iPhone แนวตั้ง + แนวนอน: ทุกช่องและปุ่มในฟอร์มสร้างประกาศไม่ทับกัน กดได้ครบ
- [ ] ปฏิทินเลือกวันไม่ล้นจอ
- [ ] Desktop ไม่เปลี่ยน

### I-02 — ชื่อบนตัวละครไม่ตรง Display Name + ตัวละครเล็กเกิน (P7)

**อาการ:** Character name ไม่ตรงหน้า Display name · ตัวละครเล็กเมื่อเทียบกับจอ (ไม่มีรูปแนบ)

**ต้นเหตุ — ชื่อ:**
- label ใช้ `character_name` (ต่อ workspace) ก่อน `display_name`: ตัวเอง `hero-virtual-office.tsx:6025` (`charName ?? user?.display_name …`), คนอื่น `:4023` (`p.character_name ?? p.display_name`)
- `charName` เริ่มจาก localStorage (`lib/avatar-selection.ts:88-105`) ที่ key **ต่อ user ไม่ใช่ต่อ workspace** และจะถูกทับจาก DB เฉพาะเมื่อ `myEntry.character_name` มีค่า (`:4530-4542`) → ชื่อเก่าจาก workspace อื่น/ก่อนเปลี่ยนชื่อค้างอยู่
- เปลี่ยน Display Name ที่ `/setting` (Space builder → Account setting) ไม่ sync `character_name` หรือ cache · sync มีแค่ใน VO profile save (`:4777-4794`) และหน้า workspace-enter (`hero-workspace-enter.tsx:171-173, 393-414`) ซึ่ง flow มือถืออาจข้าม

**ต้นเหตุ — ขนาด:**
- VO ไม่ส่ง `defaultZoom` → `zyra-engine/pixi-game/scene.ts:1686` ใช้ `CAMERA_ZOOM = 1.0` (`zyra-engine/constants.ts:29`) เท่า desktop 1920px · tile 32px บนจอ 874×402 จึงเล็ก · ไม่มี initial zoom ตามขนาดจอเลย

**แผนแก้ (รอมติ Q2, Q4):**
- ชื่อ: ถ้ากติกาคือ "label = Display Name" → ใช้ `display_name` ก่อน · ถ้ายังต้องมี character name แยกต่อ workspace → key cache ต่อ workspace (`charNameKey(userId, workspaceId)`), DB ไม่มี `character_name` ให้ fallback `display_name` และล้าง cache, save ที่ `/setting` เรียก `updateMyCharacterName`
- ขนาด: ส่ง `defaultZoom` เมื่อ `mobileSpatial` (คำนวณจากด้านสั้น เช่น `clamp(1, minSide/220, 2.5)` แล้วปัดเข้า `CAMERA_ZOOM_STEP` ให้ปุ่ม +/− ยังตรงระดับ) · apply ใหม่ตอนหมุนจอผ่าน `zoomTo`

**AC:**
- [ ] ชื่อบนหัวตัวละคร (ตัวเอง + คนอื่น ทั้ง web และ mobile) ตรงกติกาตามมติ Q2 หลังเปลี่ยนชื่อที่ `/setting` โดยไม่ต้อง refresh/ล้าง cache
- [ ] iPhone แนวนอนเปิด VO ครั้งแรก ตัวละครขนาดตามค่าที่ตกลง (Q4) · ปุ่ม +/− ยังทำงาน · desktop zoom ไม่เปลี่ยน

## 3. Task breakdown (1 task = 1 PR · zyra-app · base `develop`)

| PR | Branch | การ์ด | ไฟล์หลัก | รอมติ? | ขนาด |
|---|---|---|---|---|---|
| P1 | `fix/ios-spatial-hud-layout` | I-06, I-08 | `vo-sidebar.tsx`, `hero-virtual-office.tsx` (scroll lock), `globals.css` | ไม่ | M |
| P2 | `fix/ios-meeting-chat-keyboard` | I-04 | `zone-enter-chat.tsx`, `vo-mobile-meeting.tsx` | ไม่ | S |
| P3 | `fix/ios-chat-keyboard-landscape` | I-07 | `hero-virtual-office.tsx` (chat container), `message-input.tsx`, `use-keyboard-inset.ts` | Q5 (ทำไม blocked) | M |
| P4 | `fix/ios-aasa-exclude-play` | I-03 | `lib/apple-app-site-association.ts` + test | **Q3** | S |
| P5 | `fix/mobile-space-builder-menu-tablet` | I-01 | `mobile-space-builder.tsx` | เมนู: ไม่ · ความกว้าง: **Q1** | S–M |
| P6 | `fix/mobile-announcement-form` | I-05 | `announcement-surface.tsx`, `announcement-list-panel.tsx`, `announcement-form.tsx`, `announcement-date-time.tsx` | ไม่ | M |
| P7 | `fix/vo-character-name-mobile-zoom` | I-02 | `hero-virtual-office.tsx`, `lib/avatar-selection.ts`, setting page, `scene.ts` config | **Q2, Q4** | M (แยก 2 PR ได้: ชื่อ / zoom) |

**ลำดับแนะนำ:** P2 → P1 → P3 (P1 กับ P3 ใช้ `useResetWindowScroll` ร่วม — ทำ P1 ก่อนแล้ว P3 rebase) → P6 → P5 (ส่วนเมนู) → P4/P7 หลังได้มติ

**ไฟล์ชน:** P1, P3, P7 แตะ `hero-virtual-office.tsx` (คนละส่วน) — ไฟล์นี้ใน `feat/calendar` ก็มีงานค้าง (+90/−2) → แตก branch จาก `develop` ไม่ใช่จาก `feat/calendar`

## 4. Test plan

- **Unit (vitest):** P2 — EmojiPicker ใน `MeetingChatPanel` ได้ `mobile`, Send/Emoji `preventDefault` บน pointerdown, Send render ตลอด · P1 — zone menu ไม่ใช้ `bottom-[176px]` / อยู่ใน container เดียวกับแถวบน · P4 — AASA มี exclude ตามมติ · P5 — เมนูอยู่ใต้ avatar · P7 — fallback ชื่อ + cache ต่อ workspace + `defaultZoom` ตามขนาดจอ
- **ทุก PR:** `npx vitest run` + `npx tsc --noEmit` + `npm run lint`
- **เครื่องจริง (ต้องทำ — bug ทั้งหมดเป็น layout ของ Safari ที่ jsdom จำลองไม่ได้):** iPhone แนวนอน Safari (มี/ไม่มีแอป Zyra Dev ติดตั้ง → มี/ไม่มี banner) · iPad แนวนอน · Android Chrome แนวนอน (I-06) · เทียบ desktop ว่าไม่เปลี่ยน
- ถ้าไม่มีเครื่อง: Xcode iOS Simulator (Safari) แนวนอน iPhone 17 Pro + iPad — ใกล้เคียงแต่ไม่มี banner ของแอปที่ไม่ได้ติดตั้ง

## 5. Open questions

| # | คำถาม | ถามใคร | block |
|---|---|---|---|
| Q1 | iPad แนวนอน: ขยาย mobile layout ให้เต็มจอ (grid 2 คอลัมน์) หรือใช้หน้า desktop? (B-40 ตั้งใจให้ tablet ใช้ mobile UI) | PM / design | ✅ rif 2026-10-21: **เต็มจอ** |
| Q2 | ชื่อบนหัวตัวละคร = Display Name เสมอ หรือ character name ต่อ workspace (fallback Display Name)? | PM | ไม่ต้องตอบ — I-02 ไม่แก้ |
| Q3 | ยอมให้ลิงก์ `/workspace/*` ไม่เปิดแอปอัตโนมัติ (เหลือแค่ `/join/*`) หรือ exclude เฉพาะหน้า play/loading/chat? | PM + คนดูแลแอป mobile | ✅ rif 2026-10-21: **ใช่ — เหลือแค่ `/join/*`** |
| Q4 | ขนาดตัวละครเริ่มต้นบนมือถือ | design | ✅ rif: ปกติ (ไม่เปลี่ยน) — I-02 ไม่แก้ |
| Q5 | I-07 ถูกตั้ง `blocked` เพราะอะไร | QA / PM | ✅ rif: การ์ดปิดแล้ว ไม่ต้องทำ |

## 6. ความคืบหน้า

### 2026-10-21 (รอบ 5) · rif + Claude — PR #637 merge

- commit `4445e06` · [#637](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/637) · CI ผ่านครบ (lint-and-build, vitest-coverage, e2e-mobile-harness, e2e-parse, visual-regression, CodeRabbit ไม่มี comment) · rif สั่ง merge → merge commit `f5c13d4` บน `develop` (deploy dev อัตโนมัติ)
- **เหลือ:** เทสบน iPad / มือถือจริงหลัง dev deploy · ClickUp status ไม่ได้แตะ

### 2026-10-21 (รอบ 4) · rif + Claude — iPad เต็มจอ (Space builder + Lobby) · Lite ปุ่มประกาศ (commit ในรอบ 5)

- **ที่มา:** rif ส่งรูปหลัง #635 ขึ้น dev — Space builder บน iPad ยังบีบกลาง · หน้า Lobby (Welcome to …) logo / profile ไม่ชิดขอบ และกล่องผิดสัดส่วน · Lite เมนู "Rooms, zones and more" ยังไม่มีทางไปสร้างประกาศ
- **ต้นเหตุ Space builder:** `wide` ของ #635 ผูกกับ `useTabletScale()` ซึ่งวัดด้านสั้นของ `innerHeight` ≥ 744 — iPad แนวนอนใน Safari เหลือ ~732 หลังหักแถบ browser → ไม่เคยเป็น true
- **แก้ (`zyra-app@fix/ipad-full-width-lobby` จาก `origin/develop` @ `3e56008`):**
  - `mobile-space-builder.tsx` — เลิก cap 600 ทุกจอ (logo / avatar ชิดขอบ) · การ์ด 2 คอลัมน์ที่ `lg` (≥ 1024 กว้าง) · ลบ prop `wide` + `useTabletScale` ใน `hero-user-workspace.tsx`
  - `mobile-lobby.tsx` — header เต็มกว้าง, เฉพาะ panel cap 934 · จอสูง ≥ 600 (`[@media(min-height:600px)]`, iPad) ใช้สัดส่วน desktop: preview 562:344, ตัวละคร 107, Change character 32, Join 42, หัวข้อ 20px · มือถือแนวนอนเหมือนเดิม
  - Lite `lite-home-sheets.tsx` + `lite-shell.tsx` — แถว "Announcement" (Megaphone) ใน Places sheet เฉพาะ Owner / Admin (`canManage`) → `MobileSubPage` + `AnnouncementSurface compact` (dynamic import) · ‹ กลับ Places · i18n `LiteHomeSheets.announcements` (en "Announcement" / th "ประกาศ")
- **verify:** vitest ทั้งชุด 390 ไฟล์ / 4687 ผ่าน · eslint 0 error · tsc 9 error เดิมของ develop · lite-bundle-boundary ผ่าน · **ยังไม่เทสบน iPad / มือถือจริง**
- **Icon (rif 2026-10-21):** Spotlight ใช้ lucide `Radio` ทุกจุด (rif เลือก lucide แทน react-icons `RiLiveLine/Fill` — คง rule 12-icons) · Announcement ใช้ `Megaphone` (เดิมของ Spotlight) — ที่เปลี่ยน: admin workspace editor zone type spotlight (`left-panel-constants.ts`, `zone-canvas-layer.tsx`, `hero-workspace-editor.tsx` ×2) Megaphone→Radio · Lite ปุ่ม Start spotlight (`lite-home.tsx`) Megaphone→Radio · `zone-hover-card.tsx` spotlight Video→Radio · ปุ่ม Spotlight ใน HUD (`vo-hud.tsx` mobile + desktop) Play→Radio (Stop ยังเป็น Square) · confirm Start (`lite-spotlight.tsx`, `vo-spotlight-share-confirm-modal.tsx`) Play→Radio · banner / notification / toast ใช้ Radio อยู่แล้ว · Announcement ทุกจุดใช้ Megaphone อยู่แล้ว · ไม่แตะ `version-check-modal.tsx` (patch note)
- **verify (รวม icon):** vitest ทั้งชุด 4686/4687 — ตัวที่ตกคือ `delete-account-form` timeout ตอนรันทั้งชุด รันเดี่ยวผ่าน (ไฟล์ไม่เกี่ยว) · test ใหม่เช็ก `.lucide-radio` ใน HUD + Lite · tsc 9 error เดิม · eslint 0 error
- **เหลือ:** rif review → commit / PR

### 2026-10-21 (รอบ 3) · rif + Claude — commit + PR + merge

- rif สั่ง commit → PR เข้า develop → merge ถ้าผ่าน · commit `2e75ffb` · [#635](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/635) · CI ผ่านครบ (lint-and-build, vitest-coverage, e2e-mobile-harness, e2e-parse, visual-regression, CodeRabbit ไม่มี comment) · merge commit `919e099` บน `develop`
- **เหลือ:** รอ deploy dev แล้วให้ QA เทสซ้ำบน iPhone แนวนอน (มี/ไม่มี banner) + iPad · ClickUp status ไม่ได้แตะ

### 2026-10-21 (รอบ 2) · rif + Claude — แก้ P1, P2, P4, P5, P6 (commit ในรอบ 3)

- **มติ rif:** Q1 เต็มจอ · Q3 ใช่ (AASA เหลือ `/join/*`) · Q4 ปกติ · Q5 / I-07 ปิดแล้วไม่ทำ · **I-02 ไม่แก้** (ถูกแล้ว QA เข้าใจผิด) → P3, P7 ยกเลิก
- **Branch:** `zyra-app@fix/ios-mobile-responsive-qa` แตกจาก `origin/develop` @ `8ab23e6` (ตัด upstream ออก กัน push เข้า develop) · **ไม่ commit ตามคำสั่ง rif**
- **P2 / I-04** `zone-enter-chat.tsx` — Meeting chat แนวนอน: ตอนแป้นเปิด (`useKeyboardInset`) ซ่อนแถบหัว + ขอบแผงเหลือ 4px ให้ช่องพิมพ์พอดีกับพื้นที่ ~100px · ปุ่มส่ง `onMouseDown preventDefault` (แป้นไม่ปิดตอนแตะ) · emoji เป็น bottom sheet ของมือถือ (portal ไป `body` z-70 เพราะ `backdrop-blur` ของแถบพิมพ์ขัง fixed) · เลือก emoji ไม่ focus ช่องพิมพ์ (ไม่เปิดแป้นทับ sheet) · desktop ไม่เปลี่ยน
- **P1 / I-06 + I-08** `vo-sidebar.tsx` — zone menu (Meeting rooms / Lock / Pet): จอสูง < 380px (`[@media(max-height:379px)]`) เป็นแถวนอนใต้แถวบน แทนคอลัมน์ที่ `bottom-176` · จอสูงพอ (แอป native 402) ยังเป็นคอลัมน์ตาม Figma · `hero-virtual-office.tsx` เรียก `useResetWindowScroll` + `useNoPageOverscroll` (ใหม่ ใน `hooks/use-reset-window-scroll.ts`) เมื่อ `mobileSpatial` — หน้าไม่เลื่อน / ไม่เด้ง
- **P4 / I-03** `lib/apple-app-site-association.ts` — `APP_LINK_PATHS = ["/join/*"]` → Safari ไม่โชว์ banner "เปิดในแอป" บนหน้า workspace/meeting · Android App Links ไม่แตะ · ⚠️ ลิงก์ `/workspace/...` บน iOS จะเปิดใน Safari แทนแอป · Apple cache AASA → เห็นผลหลัง deploy + ลงแอปใหม่ / รอ CDN
- **P5 / I-01** `mobile-space-builder.tsx` — เมนูโปรไฟล์ย้ายเข้า header ใต้ avatar (`top-[calc(100%+8px)] right-[16px]`) · prop `wide` (จาก `useTabletScale()` ใน `hero-user-workspace.tsx`) → tablet ไม่มี `max-w-[600px]` + การ์ด grid 2 คอลัมน์ (empty state ยังอยู่กลาง)
- **P6 / I-05** announcement — `AnnouncementSurface compact` (hero ส่งในหน้า MobileSubPage): list เต็มกว้าง / เปิด-สร้างแล้วฟอร์มแทน list · view mode มีปุ่ม X กลับ list (`onClose`, key `close` เดิม) · ฟอร์ม `@container` + grid `grid-cols-1 @md:grid-cols-2` · header `flex-wrap` · popover ปฏิทินไม่ได้แก้
- **Test ใหม่/แก้:** `meeting-chat-mobile` (+3) · `mobile-parity` (zone menu) · `use-no-page-overscroll` (ใหม่) · `apple-app-site-association` · `mobile-space-builder` (+3) · `hero-user-workspace-manage` (mock `useTabletScale`) · `announcement-compact` (ใหม่ 5)
- **verify:** vitest ไฟล์ที่เกี่ยวผ่านครบ · eslint ไฟล์ที่แก้ 0 error (warning เดิมใน hero) · `tsc --noEmit` มี 9 error ใน test ไฟล์อื่น ซึ่งมีอยู่แล้วบน develop (เทียบด้วย stash แล้ว เท่ากัน) · **ยังไม่ได้เทสบน iPhone / iPad จริง** — โดยเฉพาะ media query `max-height` บน Safari แนวนอน และ AASA
- **เหลือ:** rif review + commit · เทสบนเครื่อง · deploy dev แล้วให้ QA เทสซ้ำ

### 2026-10-21 · rif + Claude — ถอดการ์ด + หาต้นเหตุ

- **ทำ:** อ่านการ์ด 8 ใบ + รูป 3 + วิดีโอ 2 (ตัด frame ด้วย AVFoundation) · หาต้นเหตุจากโค้ด zyra-app · เขียน spec + plan นี้
- **verify:** อ่านโค้ดอย่างเดียว · ยืนยันซ้ำด้วยตาแล้ว: `vo-sidebar.tsx` top-row/zone-menu, `mobile-space-builder.tsx:140, 253-258`, `EmojiPicker` ใน `zone-enter-chat.tsx` ไม่มี `mobile`, `APP_LINK_PATHS`, grid ใน `announcement-form.tsx` · **ยังไม่ได้ทดสอบบนเครื่อง ยังไม่แก้โค้ด**
- **เหลือ:** มติ Q1–Q5 · เริ่ม P2 / P1 ได้เลยไม่ต้องรอมติ
