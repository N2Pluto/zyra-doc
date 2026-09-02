# Test Plan — Room Pet (SC-PET-01 ~ 08) · ฝั่ง UI

> **สถานะ:** เขียนจาก [ux-ui.md](ux-ui.md) + [spec.md](spec.md) เมื่อ 2026-09-02 — **ยังไม่มี component ให้รัน** ทุก test ในนี้เป็น case ที่ต้องเขียนพร้อม PR ที่สร้าง component นั้น ชื่อไฟล์/ฟังก์ชันอ้างตามที่เสนอใน [ux-ui.md §10](ux-ui.md) (`VOPetPanel`, `PetTooltip`, `PetStageBadge`, option ใหม่ของ `makeNameTag`, prop `petDots` ของ `VOMinimap`) ถ้าตอน implement ตั้งชื่ออื่น ให้แก้ชื่อในนี้ ไม่ใช่ข้ามเคส
> **repo:** zyra-app (Vitest + Playwright) · zyra-api (Go testify — เฉพาะ API ที่ UI พึ่ง) · zyra-ws (เฉพาะ event ที่ UI รับ)
> **หลักการ:** assert ค่าที่ Figma ระบุเท่านั้น (px/hex ในตาราง ux-ui.md) — สิ่งที่ Figma **ไม่มี** (สี stage badge Adult/Evolved, สี minimap dot, ความถี่ mood bubble, ระยะเวลา animation) **ห้ามเขียน test ที่ล็อกค่า** ให้เขียนเป็น "อ่านจาก const/config" แทน
> กฎโปรเจกต์ที่ test ต้องบังคับ: Tailwind-only ([rule 08](../../../.claude/rules/08-shadcn-ui.md)) · lucide-react only ([rule 12](../../../.claude/rules/12-icons.md)) · member เรียกแค่ `/api/user/*` ([rule 15](../../../.claude/rules/15-member-api-separation.md)) · `vi.mock` ทุก API ห้ามยิงจริง ([rule 04](../../../.claude/rules/04-test.md))

---

## Coverage Targets

| Layer | Module | Target |
|---|---|---|
| Unit (TS) | `lib/api/pets.ts` (member functions ใหม่), `lib/pet-*.ts` (derive stage/mood/relative XP) | ≥ 80% |
| Unit (TS) | `zyra-engine/pixi-game/utils.ts` — option ใหม่ของ `makeNameTag` / mood bubble | ≥ 80% ของ branch ใหม่ |
| Component (Vitest + RTL) | `VOPetPanel`, `PetTooltip`, `PetStageBadge`, `PetEvolutionModal`, `PetHatchOverlay`, pet branch ใน `NotificationCard`, การ์ด egg/Evolution ใน `pet-upload-step.tsx` | critical path ทุกตัว |
| Unit (Go) | `pet_service.go` — GIF-only ที่ `Evolution`, prefill egg default, `stage_ready` | ≥ 80% |
| E2E (Playwright) | 8 journey ตาม scenario | happy + 1 error path ต่อ scenario |

---

## 0. Test fixtures ที่ใช้ร่วมกัน

```ts
// tests/fixtures/pet.ts
export const PET_XP_CONFIG = { xp_baby: 100, xp_adult: 500, xp_evolve: 2000 } // default ของ SC-PM-04
export const ROOM_PET_EGG    = { id: "p1", name: "Golden retriever", xp: 60,   last_activity_at: minutesAgo(5) }   // stage egg
export const ROOM_PET_BABY   = { id: "p2", name: "Golden retriever", xp: 350,  last_activity_at: minutesAgo(5) }   // baby, 350/500 ตาม Figma
export const ROOM_PET_MAX    = { id: "p3", name: "Golden retriever", xp: 2400, last_activity_at: minutesAgo(5) }   // evolved → MAX XP
export const MOOD_HAPPY   = hoursAgo(1)   // ≤ 12h
export const MOOD_NEUTRAL = hoursAgo(30)  // 12–72h
export const MOOD_SAD     = hoursAgo(80)  // > 72h
export const SHARED_EGG_GIF = "https://pub-b74ca51768ef4435bac2cf6f1210514d.r2.dev/static/pet/shared/egg-evolution.gif"
```

- ทุก component test ห่อด้วย `NextIntlClientProvider` + messages en (copy ใน ux-ui.md เป็น EN จาก Figma)
- ห้าม import `@/components/ui/tooltip` / `dialog` / `dropdown-menu` ใน component ใหม่ — มี test ตรวจ import (§1.0)

---

## 1. Unit / Component Tests (zyra-app)

### 1.0 กฎโปรเจกต์ — `tests/pet/rules.test.ts`

| Test | Expected |
|---|---|
| `pet components import no shadcn interactive ui` | `grep` ไฟล์ใต้ `views/user/virtual-office/components/pet-*` ไม่มี `@/components/ui/(tooltip\|dialog\|dropdown-menu\|select\|switch\|button\|input)` |
| `pet components import icons from lucide only` | ไม่มี `react-icons` / `@heroicons` · emoji mood เป็น `<Image>` PNG ไม่ใช่ `<svg>` inline |
| `member pet api never hits /api/admin` | ทุกฟังก์ชัน member ใน `lib/api/pets.ts` (`listWorkspacePets`, `strokePet`, `getPetStatus`) เรียก path ที่ขึ้นต้น `/api/user/` |
| `no hardcoded shared egg gif url in client` | ไม่มี string `egg-evolution.gif` ใน `zyra-app/**` ยกเว้น test fixture — client ต้องอ่าน `sprite_url` จาก response ([ux-ui.md §5.2](ux-ui.md)) |

### 1.1 Derive helpers — `lib/pet-stage.ts` (ใหม่)

| Test | Input | Expected |
|---|---|---|
| `deriveStage below xp_baby → egg` | xp 0, 99 | `"egg"` |
| `deriveStage boundaries` | xp 100 / 500 / 2000 | `"baby"` / `"adult"` / `"evolved"` (threshold เป็น **สะสม** — spec.md ข้อ 5) |
| `relativeProgress egg` | xp 60 | `{ current: 60, max: 100, remaining: 40 }` |
| `relativeProgress baby 350` | xp 350 | `{ current: 250, max: 400, remaining: 150 }` → label "150 XP to evolve next stage" ตรง Figma |
| `relativeProgress evolved` | xp 2400 | `{ isMax: true }` → UI แสดง `MAX XP` ไม่ใช่ตัวเลข |
| `relativeProgress after admin lowers threshold` | xp 400, config xp_adult 300 | stage `adult` ทันที ไม่ต้อง event (derived) |
| `deriveMood happy/neutral/sad` | `last_activity_at` = 1h / 30h / 80h ago | `"happy"` / `"neutral"` / `"sad"` — **3 state เท่านั้น ไม่มี hungry** |
| `deriveMood boundary 12h and 72h` | exactly 12h → happy (≤) · exactly 72h → neutral (Sad เริ่ม > 72) | ตาม PetManagement 2026-09-01 |
| `moodEmojiAsset` | 3 mood | คืน asset *Smiling Face With Hearts* / *Slightly Smiling Face* / *Crying Face* (ชื่อไฟล์ตาม `public/`) |

### 1.2 Nameplate ของ pet — `zyra-engine/pixi-game/utils.test.ts` (ต่อจาก test เดิมของ `makeNameTag`)

| Test | Expected |
|---|---|
| `makeNameTag with leadingIcon replaces status dot` | ไม่มี status dot graphics · มี sprite icon 16×16 ก่อน text |
| `makeNameTag with trailingEmoji` | sprite emoji 16×16 หลัง text · gap 4 (`NAME_TAG_GAP`) |
| `makeNameTag with progress adds second row` | มี track `h 4` เต็มความกว้าง pill radius 90 + fill กว้าง = `progress × trackWidth` · pill สูงขึ้น 4 + gap 4 |
| `pet nameplate uses peer pill background` | bg = ค่าเดียวกับ peer tag ในโค้ด (`0x141420 @ 0.88`) **ไม่ใช่** self `0x996adf` — ตามข้อตัดสิน ux-ui.md คำถาม 11 (ถ้า design เคาะ `#242B32` ให้แก้ค่าที่เดียวใน constants แล้ว test อ่านจาก constant) |
| `pet nameplate font is sans-serif not Inter` | style.fontFamily ไม่มี `Inter` (ภาษาไทย) |
| `pet nameplate truncates long name` | ชื่อ 30 ตัว → ผ่าน `truncateName()` เหมือน avatar |
| `progress 0 and 1 edge` | width 0 ไม่ error · width เต็ม track |

### 1.3 Mood bubble บนแคนวาส — `utils.test.ts`

| Test | Expected |
|---|---|
| `makeMoodBubble geometry` | body `bg 0x1a1b1e`, padding 8, radius 8, มีหางสามเหลี่ยม 20px หมุน 60° ใต้กลาง |
| `mood bubble shows one 16px emoji` | 1 sprite 16×16 ตาม mood |
| `mood bubble pushes nameplate up` | ใช้ `TALKING_BUBBLE_NAMETAG_GAP` เดิม |
| `mood bubble interval is a constant` | `PET_MOOD_BUBBLE_INTERVAL_MS` export จาก constants — test แค่ว่า > 0 **ไม่ล็อก 30000** (sticky บอกยังไม่เคาะ) |

### 1.4 `PetTooltip` (DOM overlay) — `pet-tooltip.test.tsx`

| Test | Expected |
|---|---|
| `variant key renders Press [P] pet` | text "Press" + badge `P` + "pet" · badge class มี `border-[#58D68D]` `text-[#58D68D]` `rounded-[2px]` `w-[16px]` `text-[10px]` |
| `variant emoji renders one 16px image` | `<Image width=16 height=16>` ของ Red Heart |
| `variant xp renders +N XP in yellow` | text `+5 XP` · class `text-[#ECC819]` `text-[12px]` `font-medium` · มี Medal 16px |
| `container classes` | `bg-[#1A1B1E] p-[8px] rounded-[8px]` + shadow `0px_4px_8px_rgba(255,255,255,0.08)` |
| `has bottom pointer` | element หาง `rotate-60` ขนาด 20px อยู่ `bottom-[-12.32px]` กลาง |
| `positioned in screen space` | รับ `sx,sy` → style `left/top` + `translate(-50%,-50%)` แบบ `PZZoneHover` |
| `pointer-events none by default` | ไม่ดักคลิกแคนวาส (HUD layer เป็น `pointer-events-none`) |

### 1.5 Pet menu marker — `pet-menu-marker.test.tsx`

| Test | Expected |
|---|---|
| `renders 32x32 hand button` | outer `bg-[#242B32] p-[4px] rounded-[8px]` · inner `p-[4px] rounded-[4px]` · icon `Hand` (lucide) `size={16}` |
| `only rendered after click, not hover` | prop `open=false` → null · hover state ไม่เปลี่ยน `open` |
| `has pointer-events-auto` | ปุ่มกดได้แม้ parent `pointer-events-none` |
| `click when far triggers walk and closes` | mock `walkAdjacentTo` ถูกเรียกด้วย tile ของ pet · `onClose` ถูกเรียก · **ไม่**เรียก `strokePet` |
| `click when near triggers stroke` | เรียก `strokePet(workspaceId, petId)` · ไม่เรียก `walkAdjacentTo` |

### 1.6 `PetStageBadge` — `pet-stage-badge.test.tsx`

| Test | Expected |
|---|---|
| `egg badge` | `size-[16px] rounded-[4px] bg-[#8C99A6]` text "1" `text-[10px] font-semibold` |
| `baby badge` | `bg-[#2DB6FF]` text "2" |
| `adult / evolved read color from map` | ใช้ `PET_STAGE_BADGE_COLOR.adult / .evolved` — test ว่ามีค่าและเป็น hex **ไม่ล็อกสี** (Figma ไม่มี — ux-ui.md คำถาม 2) |
| `stage label text` | Egg / Baby / Adult / Evolved (ไม่ใช่ Hatch/Grow/Evolve จาก card) |

### 1.7 `VOPetPanel` — `vo-pet-panel.test.tsx`

**Shell**

| Test | Expected |
|---|---|
| `shell classes match profile panel` | root มี `w-[320px] rounded-[16px] bg-[#242B32] p-[16px] gap-[16px]` |
| `positioned top-right` | wrapper `top-[24px] right-[24px]` |
| `close button` | ปุ่ม `X` 16px มุมขวาบน → `onClose` |

**Header (fixture ROOM_PET_BABY xp 350)**

| Test | Expected |
|---|---|
| `avatar circle` | `size-[56px] rounded-[90px] bg-[#FFA8A8] border border-[rgba(255,255,255,0.2)]` มีรูป pet |
| `name` | "Golden retriever" `text-[16px] font-medium leading-[22px]` ellipsis |
| `progress row` | track `h-[4px] rounded-[90px] bg-[rgba(26,27,30,0.5)]` · fill gradient `from-[#58d68d] to-[#8fe4b3]` width 62.5% (250/400) |
| `xp text` | "350" `font-semibold text-white` + "/500 XP" `text-[#8C99A6]` (แสดง **สะสม** ตาม Figma แต่ progress คิด relative) |
| `remaining label` | "150 XP to evolve next stage" `text-[12px] text-[#8C99A6]` |

**Header — MAX variant (fixture ROOM_PET_MAX)**

| Test | Expected |
|---|---|
| `max xp bar full white` | fill 100% · track `bg-white` |
| `max label` | "MAX" semibold white + " XP" grey · **ไม่มี** บรรทัด "XP to evolve" |

**Stats row**

| Test | Expected |
|---|---|
| `two cells with divider` | cell ซ้ายมี `border-r border-[rgba(255,255,255,0.2)]` · ทั้งคู่ `p-[8px] gap-[8px]` |
| `mood cell` | emoji 16 + "Happy" `text-[14px]` + caption "Mood" `text-[12px] text-[#8C99A6]` · เปลี่ยนตาม fixture MOOD_* |
| `stage cell` | `PetStageBadge` + "Baby" + caption "Stage" |

**Streak banner**

| Test | Expected |
|---|---|
| `renders streak` | `bg-[rgba(255,128,0,0.1)] rounded-[8px] p-[8px]` · Fire 16 · text `text-[#FF8000]` "Together for {n} days. Keep it up" |
| `hidden when streak undefined` | ไม่ render (field ยังไม่มีใน schema — spec.md คำถาม 5) |

**Daily quest**

| Test | Expected |
|---|---|
| `renders quests from config not hardcoded` | mock 3 activities enabled → 3 แถว · 0 enabled → header "Daily quest" + empty state |
| `quest row icon tile` | `w-[50px] rounded-[8px] bg-[rgba(255,255,255,0.1)]` + ตัวเลข `+{xp}` จาก config (ไม่ใช่ +5 ตายตัว) |
| `completed row` | count `text-[#58D68D] font-bold` · ปุ่ม "Complete" `h-[24px] rounded-[4px] opacity-50` disabled |
| `incomplete row` | count white · ปุ่ม "Go to" + `ChevronRight` 16 enabled → `onGoTo(activity)` |
| `count format` | "1 / 10" ตาม `times` ของ activity |

**Data / API**

| Test | Expected |
|---|---|
| `fetches status via member endpoint` | `vi.mock("@/lib/api/pets")` — `getPetStatus` ถูกเรียกด้วย `/api/user/...` |
| `updates on pet_xp_changed event` | dispatch event → progress/xp text เปลี่ยนโดยไม่ refetch ทั้งก้อน |

### 1.8 Interaction flow — `pet-interaction.test.tsx` (hook/controller)

| Test | Expected |
|---|---|
| `key P strokes when near` | keydown `P`, distance ≤ 2 tiles → `strokePet` 1 ครั้ง |
| `key P ignored when far` | distance 3 → ไม่เรียก · (Figma: ไกลต้องคลิก icon ให้เดินไป) |
| `key P ignored when typing in input` | focus อยู่ใน `<input>`/`<textarea>` → ไม่เรียก (ชน chat) |
| `rate limit 3s` | เรียก 2 ครั้งใน 3 วิ → API 1 ครั้ง · ครั้งที่ 2 ไม่ error แค่ ignore |
| `xp first then happy` | response `{xp_awarded: 5}` → แสดง `PetTooltip variant=xp` ก่อน แล้ว ♥ + happy animation |
| `no xp → happy immediately` | response `{xp_awarded: 0}` (ครบ limit) → ไม่มี xp tooltip · ♥ + happy ทันที |
| `hand animation asset sizes` | เฟรม 20×20 → 15×15 ตาม Figma |
| `daily limit reached still plays happy` | ClickUp: "ทำได้แต่ไม่ +XP" |

### 1.9 Hatch / Evolve overlay — `pet-hatch-overlay.test.tsx`

| Test | Expected |
|---|---|
| `overlay covers screen` | `absolute inset-0 bg-[rgba(0,0,0,0.5)]` · z สูงกว่า HUD |
| `prompt state` | pet 320×320 กึ่งกลาง · text "Click to start evolve your pet" `text-[20px] font-bold leading-[25px]` ใต้ pet · cursor hint 40×40 |
| `click on overlay does nothing` | คลิกพื้นดำ → state ไม่เปลี่ยน (Figma ไม่มี dismiss) |
| `click on pet starts gif` | คลิก pet → render `<img src={evolutionUrl}>` (GIF) 1000×1000 กึ่งกลาง · `evolutionUrl` มาจาก `animations.egg.Evolution.sprite_url` ของ response |
| `gif ends → flash → reveal` | หลัง `onEnded`/timer → overlay flash → pet ร่างใหม่ 320 + cursor |
| `click reveal opens modal` | → `PetEvolutionModal` เปิด · เรียก `playPetSound()` (optional — test แค่ถูกเรียกถ้ามี asset) |
| `stage switch waits for server confirm` | sprite บน map ยังเป็น egg จน `pet_stage_changed` มาถึง (spec.md ข้อ 6) |
| `only xp filler sees full flow` | prop `isTrigger=false` → ข้ามไปเปิด modal ทันที (SC-PET-07 "กรณีคนในทีม") |
| `gated by presence` | `optedOutOfSharedSpace(status)` true หรือ `inChatSpace` true → ไม่ render อะไรเลย |

### 1.10 `PetEvolutionModal` — `pet-evolution-modal.test.tsx`

| Test | Expected |
|---|---|
| `container` | `w-[458px] bg-[#242B32] rounded-[16px] px-[16px] py-[40px] gap-[40px]` |
| `title + desc` | "Your Pet Evolved" 20/700 · desc 14 `text-[#8C99A6] text-center` |
| `stage row egg→baby` | `PetStageBadge` 1 + "Egg" · `ChevronRight` 24 · badge 2 + "Baby" (16/400) |
| `progress 200x8` | track `w-[200px] h-[8px] bg-white rounded-[90px]` · เริ่ม 100% แล้ว animate ลงเป็น relative ของ stage ใหม่ (350 xp → 62.5%) · ตัวเลขนับจาก "100 / 100 XP" ไป "250 / 400 XP" (relative) |
| `pet image 160 on grass bg` | `size-[160px]` + BG 240×80 |
| `buttons` | ghost "Share your friends" `h-[42px] bg-[rgba(255,255,255,0.05)] border-[rgba(255,255,255,0.2)]` · primary "Confirm" `bg-[#58D68D]` |
| `confirm closes` | `onClose` |
| `share opens existing share modal` | เรียก `openShareModal({type:"pet_evolved", petId})` ของ Chat — **ไม่ render modal ใหม่เอง** |
| `adult→evolved uses per-type gif` | props `fromStage="adult"` → ใช้ `animations.adult.Evolution.sprite_url` |

### 1.11 Notification — `vo-notification-panel.test.tsx` (เพิ่มเคส)

| Test | Expected |
|---|---|
| `pet_stage_change card` | title "Your team pet evolved" 14/500 · body "Your pet has reached a new stage. Come see its new form!" โดย "a new stage" เป็น `text-white` · icon วงกลม 32 `bg-[#E1ADFF] p-[4px]` (branch icon-only ไม่ใช่ `ChatAvatar`) |
| `pet_xp_milestone card` | ใช้ card เดียวกัน ข้อความจาก ClickUp "🌟 … เหลืออีก {n} XP" (EN copy ต้องมาจาก i18n) |
| `pet_daily_reminder card` | เช่นกัน |
| `TYPE_META has 3 pet types` | accent กำหนดแล้ว · `typeLabel()` คืน label |
| `click navigates to room` | เรียก `onNavigateToZone(map_id, zone_id)` |
| `unread styling unchanged` | `bg-[rgba(255,255,255,0.05)]` เมื่อ unread |

### 1.12 Daily reminder banner — `pet-reminder-banner.test.tsx`

| Test | Expected |
|---|---|
| `geometry` | text box `w-[266px] h-[72px] bg-[#242B32] border border-white rounded-r-[16px] pl-[32px] pr-[16px] py-[8px]` · avatar block 124 มีวงกลม 80 + pet 56 + vine 120 |
| `copy` | "Team pet is waiting for you. Come visit and earn some XP!" 14/400 |
| `dismiss variant` | prop `dismissible` → ปุ่ม `X` 16 `right-[10px] top-[8px]` → `onDismiss` |
| `queued behind announcement` | มี announcement active → ไม่ render จน announcement ปิด (ผ่าน `AnnouncementGate`) |
| `once per day` | `localStorage`/API flag วันนี้แล้ว → ไม่ render |

### 1.13 Setting → Notifications — `vo-setting-modal.test.tsx` (เพิ่มเคส)

| Test | Expected |
|---|---|
| `PET section visible` | `notifSectionPet` ไม่มี `hidden` → render label "PET" `text-[#8C99A6] text-[14px] font-medium` |
| `row copy` | "Pet activity" / "Stay updated on your pet's progress, milestones, and evolution." |
| `switch geometry` | `h-[24px] w-[48px]` on `bg-[#58D68D]` off `bg-[rgba(255,255,255,0.2)]` |
| `toggle persists` | เรียก `setAndPersist({ pet_activity: false })` → PATCH `/api/user/me/notification-settings` (mock) · toast ผ่าน `zyraToast` |
| `default on` | `DEFAULT_NOTIFICATION_SETTINGS.pet_activity === true` |

### 1.14 Minimap — `vo-minimap.test.tsx` (เพิ่มเคส)

| Test | Expected |
|---|---|
| `renders petDots` | prop `petDots=[{tileX,tileY}]` → element เพิ่ม 1 ต่อ pet |
| `pet dot scales with dotSize` | collapsed → ขนาด `dotSize × PET_DOT_RATIO` · expanded ใหญ่ขึ้นตาม (ไม่ล็อก 6px) |
| `pet dot color from constant` | `PET_MINIMAP_DOT_COLOR` = **`#996ADF`** (ปิดแล้ว — อ่านจาก SVG Ellipse 4 ของ Figma) ✅ |
| `pet dot not grouped in PlayerPill` | ไม่ถูกนับรวม meeting-zone pill |

### 1.15 Admin — การ์ด egg/`Evolution` prefill — `pet-upload-step.test.tsx` (เพิ่มเคส)

| Test | Expected |
|---|---|
| `default state when is_default` | badge "Default" `text-[#8C99A6]` · preview `<img>` ของ `sprite_url` กลาง · ปุ่ม "Replace" ไม่ใช่ "Upload" · ข้อความ "Default egg hatch animation is shared by all pets. Upload a GIF to use your own." |
| `accept gif only for Evolution` | `accept="image/gif"` ทุก stage ที่ slot Evolution · slot อื่น `image/png` |
| `frame inputs hidden for Evolution` | ไม่มี input `frame_count/frame_rate/direction_rows` ที่การ์ด Evolution |
| `delete own returns to default` | หลัง delete สำเร็จ response `is_default:true` → กลับ state Default (ไม่ใช่ empty) · confirm text พูดถึง "ไฟล์กลาง" |
| `egg count tag starts 1/2` | ไม่มี upload เลย → tag "1/2" · progress bar นับ 1/17 |
| `preview modal plays default gif` | dropdown egg มี Evolution เล่นได้ทันที |

---

## 2. API Tests (zyra-api, Go testify) — เฉพาะที่ UI พึ่ง

### 2.1 `pet_service_test.go` — GIF-only + prefill

| Test | Input | Expected |
|---|---|---|
| `TestUploadAnimation_EvolutionRejectsPNG` | slot Evolution, PNG 1000×1000 | `ErrPetInvalidFileType` |
| `TestUploadAnimation_EvolutionAcceptsGIF` | GIF89a 960×960 | สำเร็จ · `frame_width=960` · `frame_count/frame_rate/direction_rows = NULL` · mime `image/gif` |
| `TestUploadAnimation_EvolutionGIFNotSquare` | GIF 960×800 | `ErrPetInvalidDimensions` |
| `TestUploadAnimation_EvolutionGIFOver1000` | GIF 1200×1200 | `ErrPetInvalidDimensions` |
| `TestUploadAnimation_EvolutionSkipsGridValidation` | GIF 960×960, ไม่ส่ง frame fields | ไม่เรียก `validatePetSpriteDimensions` · ผ่าน |
| `TestUploadAnimation_OtherSlotRejectsGIF` | slot Walking, GIF | `ErrPetInvalidFileType` |
| `TestGetPet_EggEvolutionDefault` | pet ไม่มี row (egg, Evolution) | response มี `sprite_url == cfg.PetEggEvolutionDefaultURL`, `is_default: true`, `frame_width: 960` |
| `TestGetPet_EggEvolutionOwn` | มี row | `is_default: false`, URL ของ type |
| `TestStageReady_EggWithOnlyWobbling` | มีแค่ Wobbling | `stage_ready.egg == true` |
| `TestStageReady_EggEmpty` | ไม่มีอะไร | `false` |
| `TestDeleteAnimation_EggEvolutionReturnsDefault` | ลบ row ที่มี | 200 + object default (ไม่ใช่ 404) |
| `TestDeleteAnimation_EggEvolutionNoRow` | ลบทั้งที่ไม่มี row | 200 + default (idempotent) |
| `TestConfig_DefaultEggURL` | ไม่ตั้ง env | = `AWS_PUBLIC_URL + "/static/pet/shared/egg-evolution.gif"` |
| `TestListWorkspacePets_UsesSameFallback` | member endpoint | egg Evolution ใน payload = default URL |

### 2.2 Member endpoints (สำหรับ panel / interaction)

| Test | Expected |
|---|---|
| `TestStrokePet_AwardsOncePerLimit` | ครั้งที่ ≤ limit → `xp_awarded > 0` · เกิน → `xp_awarded = 0` แต่ 200 (UI เล่น happy ต่อ) |
| `TestStrokePet_RateLimit3s` | 2 ครั้งใน 3 วิ → ครั้งที่ 2 `429` หรือ `xp_awarded 0` (ตามที่ตกลงใน contract) |
| `TestStrokePet_UpdatesLastActivity` | mood กลับ happy ทันที (derived) |
| `TestPetStatus_RelativeProgress` | xp 350 → `stage baby`, `next_threshold 500` — client คิด relative เอง |
| `TestPetStatus_TopContributorsDayKeyUTC7` | event ข้ามเที่ยงคืนไทย → นับวันตาม UTC+7 (spec.md ข้อ 14) |

---

## 3. E2E (Playwright) — ต่อ scenario

ทุก journey: login `member-a@zyra.test` (seed) → เข้า workspace ที่มี pet วางไว้แล้ว (ต้องมี SC-PM-05 ก่อน) · assert บน DOM overlay + screenshot canvas เฉพาะจุด

| ID | Journey | Assert หลัก |
|---|---|---|
| E2E-PET-01 | เข้า VO → เห็น pet | nameplate มีชื่อ + emoji + XP bar · minimap มี pet dot · avatar เดินทับ pet ได้ (tile ไม่ blocked) · ห้องที่ไม่มี pet ไม่มี element pet |
| E2E-PET-01b | mood bubble | รอ ≥ interval → bubble โผล่เหนือ nameplate แล้วหาย |
| E2E-PET-02 | AI movement | ภายใน 30 วิ pet เปลี่ยน tile อย่างน้อย 1 ครั้ง · ไม่ออกนอก zone · egg ไม่เคลื่อน |
| E2E-PET-03a | คลิก pet (ใกล้) | marker มือ 32×32 + `VOPetPanel` เปิดมุมขวาบน · hover อย่างเดียวไม่มี marker |
| E2E-PET-03b | คลิกมือ / กด P | tooltip `+N XP` → ♥ → happy · เรียก API ครั้งเดียว · กดซ้ำใน 3 วิ ไม่เพิ่ม |
| E2E-PET-03c | คลิก pet (ไกล) แล้วคลิกมือ | avatar เดินไปข้าง pet · panel+marker ปิดระหว่างเดิน |
| E2E-PET-04 | XP ถึง 100 (seed xp 99 แล้ว stroke) | overlay + "Click to start evolve your pet" → คลิกไข่ → GIF → ร่างใหม่ → modal "Your Pet Evolved" Egg › Baby · Confirm → sprite เป็น baby |
| E2E-PET-04b | Share | modal share เดิมเปิด · Send → toast "Share successfully." · DM มีการ์ด |
| E2E-PET-05 | baby→adult (seed xp 499) | flow เดียวกัน ใช้ GIF ของ type · คนที่ 2 (อีก browser) เห็น **modal เลย** ไม่มี prompt |
| E2E-PET-06 | Pet panel | ค่าตรง fixture (350/500, "150 XP to evolve next stage", Happy, Baby) · quest list ตาม config · MAX variant กับ pet xp 2400 |
| E2E-PET-07a | Notification | หลัง evolve → bell badge +1 · card "Your team pet evolved" · คลิกไปห้อง |
| E2E-PET-07b | Daily reminder | login แรกของวัน → banner ซ้ายล่าง · ปิดได้ · ไม่โผล่ซ้ำวันเดียวกัน · ถ้ามี announcement ค้าง banner รอ |
| E2E-PET-07c | ปิด notification | Setting → Notifications → PET off → toast · evolve อีกครั้ง → ไม่มี notification card ใหม่ |
| E2E-PET-08 | Sad state (seed `last_activity_at` 80h) | nameplate emoji Crying Face · panel Mood "Sad" · pet ไม่เดิน · stroke 1 ครั้ง → Happy ทันที |
| E2E-PET-GATE | status Away / อยู่ใน chat circle | evolve ของทีม → **ไม่มี** modal โผล่ · notification ยังมา |
| E2E-ADMIN-PREFILL | Pet Management สร้าง type ใหม่ | egg แสดง Evolution "Default" 1/2 · อัป GIF เอง → badge หาย · ลบ → กลับ Default · อัป PNG ที่ Evolution → toast `INVALID_FILE_TYPE` |

---

## 4. สิ่งที่ **ห้าม** test ล็อกค่า (Figma ยังไม่มี — รอ design)

| เรื่อง | ทำอย่างไรใน test |
|---|---|
| สี stage badge Adult / Evolved | assert ว่าอ่านจาก `PET_STAGE_BADGE_COLOR` |
| สี pet dot บน minimap | assert จาก `PET_MINIMAP_DOT_COLOR` |
| ความถี่ mood bubble | assert จาก `PET_MOOD_BUBBLE_INTERVAL_MS` |
| ระยะเวลา hatch/grow/evolve animation | อ่านจาก GIF จริง (`onEnded`) ไม่ล็อก 3–5 / 4–6 / 6–8 วิ |
| Toast copy หลัง toggle Pet activity | assert ว่ามี toast ไม่ล็อกข้อความ |
| Egg stage มี nameplate ไหม | รอคำตอบ ux-ui.md คำถาม 1 — เขียน test ทั้ง 2 ทางแล้ว `skip` ทางที่ไม่เลือก |
| streak "Together for N days" | ซ่อนถ้าไม่มี field |

---

## 5. Definition of Done ของ test

- [ ] ทุก component ใน §1 มี test file คู่กันใน PR เดียวกับที่สร้าง component
- [ ] เคส §6.1 (ชนกับ UI เดิม) และ §6.3 (loading/error) เขียนใน **PR แรก** ที่วาง pet ลงหน้า VO — ไม่รอ PR หลัง
- [ ] เคส §6.2 (realtime edge) เขียนพร้อม PR ที่ต่อ zyra-ws · เคสที่ยัง "เคาะ" อยู่ให้เขียนทั้ง 2 ทางแล้ว `skip` ทางที่ไม่เลือก พร้อม comment อ้าง ID
- [ ] `vitest run` เขียว · `go test ./internal/service/... -run Pet` เขียว
- [ ] ไม่มี test ที่ยิง `/api/*` จริง (ตรวจด้วย `vi.mock` ทุกไฟล์ที่ import `@/lib/api/pets`)
- [ ] E2E อย่างน้อย E2E-PET-01, 03a/b, 04, 06, 07a, ADMIN-PREFILL + CLASH-01, LOAD-02, LOAD-07 ผ่านบน dev ก่อนตั้ง `NEXT_PUBLIC_ROOM_PET=true` บน uat/prod (dev ตั้งได้ก่อนเพื่อ live-test)
- [ ] อัปเดต [progress.md](progress.md) (สร้างเมื่อเริ่มเขียนโค้ด) ว่า test ระดับไหนผ่านจริง — แยก "build เขียว" กับ "live-test ผ่าน"

---

## 6. เคสที่ ux-ui.md ไม่ได้พูดถึงแต่จะเจอตอนวางลงหน้า VO จริง

> เพิ่ม 2026-09-02 หลังเทียบ test plan §1–§3 กับโค้ด VO ปัจจุบัน — เรียงตามความเสี่ยง · **กลุ่ม 6.1 และ 6.3 ควรเขียนพร้อม PR แรก** · กลุ่ม 6.2 รอ technical design ของ zyra-ws ก่อนจึงเขียน expected ได้ครบ

### 6.1 การชนกับ UI เดิมของ VO (เสี่ยงสุด)

| ID | เคส | Expected / สิ่งที่ต้องตัดสิน |
|---|---|---|
| CLASH-01 | เปิด `VOPetPanel` (`top-24 right-24`) แล้วมี `VOConnectionToast` (`right-24 top-24 w-322`) หรือ wave/knock stack (`right-24`) โผล่ | **ตำแหน่งชนกันตรง ๆ** — ต้องเคาะ: toast ดัน panel ลง / panel ดัน toast ลง / toast ทับ panel · test ว่าทั้งสองอ่านได้และกดได้ ไม่มีอันไหนถูกบัง 100% |
| CLASH-02 | Hatch/Evolve overlay ขณะ meeting panel expanded (`zone-enter-panel` `absolute inset-0 z-50`) | เคาะว่า overlay ทับ meeting หรือรอจนออกจาก meeting (gate เดิมพูดถึงแค่ status + bubble ไม่พูดถึง meeting) · test ทั้ง 2 ทางแล้ว `skip` ทางที่ไม่เลือก |
| CLASH-03 | Pet panel เปิดพร้อม `VOProfilePanel` (ฝั่งขวาเหมือนกัน) | เปิดอันหนึ่งปิดอีกอัน (single right-side slot) — ไม่ซ้อน |
| CLASH-04 | Pet panel เปิดพร้อม member/notification panel (ฝั่งซ้าย) | อยู่ร่วมกันได้ ไม่ปิดกัน |
| CLASH-05 | คีย์ลัด `P` ชน shortcut เดิมของ VO | สแกน keydown handler ใน `hero-virtual-office.tsx` + `vo-hud.tsx` ว่าไม่มีใครใช้ `p`/`P` อยู่ · ถ้ามี ต้องเปลี่ยนคีย์ใน Figma ไม่ใช่ทับ |
| CLASH-06 | avatar ยืนทับ pet (walkable) | nameplate ของ avatar อยู่เหนือของ pet (avatar tag = `MAX_SAFE_INTEGER-10`, pet tag ต้องต่ำกว่า) · คลิกตรงนั้นได้ avatar ไม่ใช่ pet ([[vo-avatar-click-two-handlers]] — ห้ามให้ 2 handler รับคลิกเดียว) |
| CLASH-07 | Pet panel กับ status picker / follow bar / away bar ล่างจอ | ไม่ทับกัน (panel สูงสุด 599 ที่ viewport 1024 — เช็คที่ 768) |
| CLASH-08 | mood bubble กับ talking bubble ของ avatar ที่ยืนข้างกัน | ไม่ซ้อนทับจนอ่านไม่ได้ (offset x ต่างกัน) |
| CLASH-09 | marker มือ 32×32 กับ zone label pill / object marker menu ที่ตำแหน่งเดียวกัน | marker pet อยู่บน · ปิดเมื่อคลิกที่อื่น (click-outside) |

### 6.2 State เปลี่ยนใต้เท้า (realtime edge) — รอ zyra-ws design

| ID | เคส | Expected |
|---|---|---|
| RT-01 | admin ลบ pet (`pet_removed`) ขณะ panel เปิด | panel ปิด + toast info · ไม่ error |
| RT-02 | admin ย้าย pet (`pet_moved`) ขณะ hover/marker เปิด | marker/tooltip ตามไปตำแหน่งใหม่หรือปิด · ไม่ค้างกลางอากาศ |
| RT-03 | admin เปลี่ยนชื่อ (`pet_renamed`) | nameplate + panel header อัปเดตทันที |
| RT-04 | `pet_removed` มาระหว่าง GIF hatch เล่นอยู่ | เล่นจบแล้วปิด overlay โดยไม่เปิด modal · หรือปิดทันที — เคาะ |
| RT-05 | คนอื่นทำ XP เต็มขณะผมกำลัง stroke | ผมได้ modal แบบ "คนในทีม" (ไม่ใช่ prompt) · ไม่เล่น 2 flow ซ้อน |
| RT-06 | `pet_stage_changed` มาถึงก่อน `pet_xp_changed` (ลำดับสลับ) | stage ยึด derived จาก xp ล่าสุด ไม่กระพริบกลับ |
| RT-07 | WS หลุด → reconnect | pet position/xp resync จาก `welcome`/snapshot · timer mood bubble ไม่ซ้อน 2 ตัว |
| RT-08 | เปลี่ยนชั้น (multi-floor) | pet ชั้นเก่าหาย, minimap dot หาย, panel ปิด, ไม่มี listener ค้าง ([[vo-multi-floor]]) |
| RT-09 | ห้องเดียวมีหลาย pet (index `uq_room_pet_one_per_zone` ยังไม่เปิด) | คลิกตัวไหนได้ panel ตัวนั้น · marker เปิดได้ทีละตัว |
| RT-10 | pet AI เดินมาทับ tile ที่ avatar ยืน | ไม่ดัน avatar, ไม่ block, ไม่ trigger sit |
| RT-11 | ไม่มีใครในห้อง > 5 นาที แล้วมีคนเข้า | pet กลับมาเคลื่อนภายใน 1 tick · ตำแหน่งจาก Redis ไม่ใช่ตำแหน่งที่วางตอนแรก |

### 6.3 Loading / error / ว่าง

| ID | เคส | Expected |
|---|---|---|
| LOAD-01 | GIF Evolution 404 | overlay ไม่ค้าง → ข้ามไป reveal/modal พร้อม log · ไม่ throw |
| LOAD-02 | GIF โหลดช้า | **preload ก่อนแสดง prompt** "Click to start…" — คลิกแล้วต้องเล่นทันที ไม่มีจอดำ |
| LOAD-03 | sprite ของ pet type 404 | fallback placeholder (ตัดสินว่าใช้ `PawPrint` เหมือน admin thumbnail) ไม่ใช่กล่องดำ/crash |
| LOAD-04 | `GET .../pets` 500 | ไม่มี pet render · toast error ครั้งเดียว ไม่ retry ถี่ |
| LOAD-05 | `getPetStatus` 500 ขณะเปิด panel | panel แสดง error state + ปุ่ม retry ไม่ใช่ skeleton ค้าง |
| LOAD-06 | `strokePet` 500 | ไม่เล่น XP tooltip · เล่น happy ไหม — เคาะ (เสนอ: ไม่เล่น, toast error) |
| LOAD-07 | Feature flag `NEXT_PUBLIC_ROOM_PET` ปิด (unset / ไม่ใช่ `"true"`) | ไม่ render pet ใด ๆ (`innerHTML === ""` — ✅ มี test แล้วใน 3 component) และ **ไม่ยิง API pet เลย** (assert ด้วย mock call count = 0 — เขียนตอนมี hook ดึงข้อมูล) · `isRoomPetEnabled()` default false (✅ `room-pet-feature.test.ts`) |
| LOAD-08 | ชั้นไม่มี pet | ไม่มี element pet ตกค้าง · minimap ไม่มี dot · ไม่มี listener |
| LOAD-09 | panel เปิดตอน status ยังไม่มา | skeleton ตาม geometry จริง (ไม่กระตุกตอนข้อมูลมา) |
| LOAD-10 | config XP ไม่มี (`tb_pet_xp_config` ว่าง) | derive stage/progress ไม่ divide by zero · แสดง `—` |

### 6.4 i18n และข้อความไทย

| ID | เคส | Expected |
|---|---|---|
| I18N-01 | ทุก key ใหม่ใน namespace pet | มีทั้ง `messages/en.json` และ `messages/th.json` — test อ่าน 2 ไฟล์เทียบ key set เท่ากัน |
| I18N-02 | ชื่อ pet ภาษาไทยยาว 30 ตัว | nameplate ผ่าน `truncateName()` · panel header `text-ellipsis` ไม่ล้น 320 |
| I18N-03 | font | nameplate = `sans-serif` (canvas) · DOM ใช้ `font-sans` ไม่ใส่ `font-['Inter']` ([[thai-font-inter-override]]) |
| I18N-04 | ตัวเลข XP | `toLocaleString()` ตาม locale ("1,020 XP") |
| I18N-05 | notification body ที่มีคำเน้น white ("a new stage") | ใช้ rich text ของ next-intl ไม่ split string เอง — ภาษาไทยลำดับคำต่างจาก EN |
| I18N-06 | สลับ locale ขณะ panel เปิด | ข้อความเปลี่ยนโดยไม่ต้องปิด-เปิดใหม่ |

### 6.5 Zoom / viewport / PiP

| ID | เคส | Expected |
|---|---|---|
| ZOOM-01 | camera zoom 12 ระดับ | nameplate, mood bubble, marker มือ สเกลด้วย `_nameTagLayerScale()/zoom` เหมือน avatar · ไม่เบลอที่ zoom สูงสุด (`NAME_TAG_RESOLUTION`) |
| ZOOM-02 | zoom ไกลสุดที่ avatar เปลี่ยนเป็น compact circle 34px | pet เป็นอะไร — **Figma ไม่มี** → เคาะ (เสนอ: dot เหมือน minimap หรือซ่อน nameplate) แล้ว test ตามที่เลือก |
| ZOOM-03 | pet sprite ที่ zoom ใน | ขยายเท่า avatar (Figma ห้องซูม: 120px) ไม่ใช่ขนาดคงที่ |
| ZOOM-04 | viewport 1280×720 | panel 320×599 ไม่ล้น · modal 458×498 กึ่งกลาง · overlay text ไม่ทับ HUD |
| ZOOM-05 | PiP window เล็ก (เช่น 480×300) | panel/modal ต้องซ่อนหรือย่อ — เคาะ · อย่างน้อยไม่มี scrollbar แนวนอน ([[vo-pip-zoom-fit]]) |
| ZOOM-06 | browser zoom 80% / 125% | overlay + pet 320 ยังกึ่งกลาง · tooltip ตำแหน่งตรง pet (คำนวณจาก `getBoundingClientRect` ไม่ใช่ px คงที่) |

### 6.6 Cleanup / performance / a11y

| ID | เคส | Expected |
|---|---|---|
| CLEAN-01 | unmount hero ขณะ mood bubble timer / GIF / marker เปิด | `vi.useFakeTimers` → ไม่มี timer ค้าง · listener `keydown` ถูกถอด · ไม่มี setState after unmount warning |
| CLEAN-02 | tab ซ่อน (`visibilitychange`) | หยุด mood bubble timer + GIF · กลับมาแล้ว resync ครั้งเดียว ([[vo-tab-keepalive-buzz]] — ห้ามมี loop ทำงานตอน hidden) |
| CLEAN-03 | 20 pet บนชั้นเดียว (หลายห้อง) | frame time ไม่แย่กว่า baseline > 10% · texture ของ pet type เดียวกัน share ไม่โหลดซ้ำ |
| CLEAN-04 | GIF 960×960 ×3 stage โหลดพร้อมกัน | โหลดเฉพาะตอนจะใช้ (lazy) ไม่ preload ทุกตัวตอนเข้าห้อง ([[vo-open-network-and-perf-batch-2026-07-30]] — asset burst on mount) |
| A11Y-01 | ปุ่ม icon-only (มือ, X, Go to, Replace) | มี `aria-label` จาก i18n |
| A11Y-02 | `Esc` | ปิด panel → ปิด modal → ไม่ปิด overlay hatch (ต้องคลิก) — เคาะลำดับ |
| A11Y-03 | focus | เปิด modal focus ไปที่ Confirm · ปิดแล้ว focus กลับที่เดิม · Tab ไม่หลุดออกจาก modal |
| A11Y-04 | `prefers-reduced-motion` | GIF ยังเล่น (เป็นเนื้อหา) แต่ particle/flash ลด — เคาะ |
| A11Y-05 | เสียง pet ตอน reveal | เคารพ mute / audio settings ของ VO ([[vo-audio-settings-wiring]]) · ไม่เล่นถ้า tab hidden |

### สิ่งที่ยังไม่ต้องเขียน

dark mode (VO เป็น theme เดียว) · mobile layout (VO ไม่รองรับ) · analytics (ไม่มีใน spec)
