# Avatar Customization (SC-AV-02, member) — Progress / Handoff

> **สถานะรวม:** Implement รอบแรกครบทั้ง 3 repo บน branch `feat/avatar-customize` (แตกจาก `origin/develop` 2026-10-22) — **ยังไม่ commit / ยังไม่ push** · flag `NEXT_PUBLIC_AVATAR_CUSTOMIZE` (default ปิด) · ยังไม่ได้ทดสอบกับ API / R2 จริง
> **อัปเดตล่าสุด:** 2026-10-22 · **คนล่าสุด:** rif (ผ่าน Claude Code)

## 2026-10-24 (รอบ 8 · ห้องแต่งตัวมี URL ของตัวเอง) · rif (ผ่าน Claude Code)

- **ทำอะไร (แบบผสม — rif เลือก):**
  - **จาก lobby:** หน้าใหม่ `/workspace/[id]/avatar` (`app/workspace/[id]/avatar/page.tsx` → `views/user/avatar-customize/avatar-customize-page.tsx`) · ปุ่ม Customise avatar (desktop + mobile lobby) ไป `?from=lobby` · ย้อนกลับ = `router.back()` (มาจาก lobby) หรือ `replace` ไป lobby (เปิดตรง/refresh) · flag ปิด → เด้งกลับ lobby · ลบ overlay ใน lobby ออก
  - **จาก VO:** overlay เดิม แต่สถานะอยู่ใน URL `?customize=1` (`history.pushState` + `useSearchParams` — ไม่ navigate ไม่ remount VO) → refresh แล้วเปิดค้าง, ปุ่ม back ของ browser ปิดห้องแต่งตัวโดยไม่ออกจาก office
  - ปิดห้องแต่งตัวระหว่างรอบันทึก (กด back ของ browser / เปลี่ยนหน้า) → ส่งชุดที่ค้างไปบันทึกตอน unmount ไม่ให้หาย (`use-outfit-editor.ts`)
- **verify:** tsc ไม่มี error ใหม่ · eslint ไม่มี error · test 96 ตัว (outfit, lobby/profile sync, profile panel, i18n split, mobile lobby, VO idle/spotlight/lite boundary) ผ่าน · route ใหม่ตอบ 307 ไป `/login?redirect_url=…/avatar` ตอนไม่มี session (เหมือนหน้าอื่นที่ต้อง login)
- **ยังไม่ได้:** เปิดดูจริงหลัง login (ต้องมี API) — refresh ใน VO / back ของ browser

## 2026-10-24 (รอบ 7 · loading ตอนเปลี่ยนชุด) · rif (ผ่าน Claude Code)

- **ทำอะไร:** เปลี่ยน spinner บนตัวละครจาก lucide `LoaderCircle` เป็นวงจุด 8 จุดหมุนทีละจุด (`views/user/avatar-customize/components/dots-spinner.tsx`, CSS ล้วน) หน้าตาแบบ `Loading_icon.gif` ที่ rif ส่งมา — **ไม่ได้ใช้ไฟล์ gif** เพราะเป็น CC BY-SA 4.0 (ต้องใส่เครดิต + share-alike) และพื้นขาว · จุดสีขาวเข้ากับฉากมืด · หยุดหมุนเมื่อผู้ใช้ตั้ง reduced motion
- **verify:** ภาพจริงใน browser (หมุนเป็นจังหวะ) · eslint/tsc ผ่าน · harness ลบแล้ว
- **เพิ่ม:** spinner ขึ้นทันทีที่กดเปลี่ยน (ไม่รอ debounce 600 ms) จนกว่า server บันทึกเสร็จ — `busy` = ชุดบนจอ ≠ ชุดที่บันทึกแล้ว หรือกำลังบันทึก (`use-outfit-editor.ts`) · ถือชุดที่ส่งไปเป็นชุดที่บันทึกแล้วเมื่อ PUT สำเร็จ (กัน spinner ค้างถ้า server normalise)
- **verify (เพิ่ม):** กดเปลี่ยนสีผิว: ก่อนกด ไม่มี spinner · 100 ms มี · 600 ms มี · หลังบันทึก (mock 700 ms) หาย

## 2026-10-22 (รอบ 6 · ขนาดเมนูตอนไม่เต็มจอ) · rif (ผ่าน Claude Code)

- **ทำอะไร:** สเกลเมนู u = min(w/1440, max(h/1024, min(1, h/800))) — หน้าต่างที่เตี้ยกว่า 1024 เล็กน้อย (มีแถบ tab/bookmark) เมนูยังขนาด Figma 1× · ย่อตามความสูงเฉพาะเมื่อต่ำกว่า 800 px (Costume panel ยังพอดีจอ) · เต็มจอเหมือนเดิม
- **verify:** ภาพจริง 1710×867 (หน้าต่างของ rif), 1710×1086 (เต็มจอ), 1710×700, 1280×720 — เมนูขนาดเท่า Figma ตอนไม่เต็มจอ, จอเตี้ยยังไม่ล้น · eslint/test ผ่าน · harness ลบแล้ว

## 2026-10-22 (รอบ 5 · Accessory ชิดคอลัมน์ขวา + ขนาด avatar) · rif (ผ่าน Claude Code)

- **ทำอะไร:** Accessory panel + Undo/Redo/Clear ย้ายไปผูกกับคอลัมน์หมวด (ห่าง 16 px ตาม Figma 831 → 847) แนวตั้งยังตรงกับแท่น · แท่น + ตัวละครย่อ/ขยายตามสเกลของภาพพื้นหลัง (1.2 art px ต่อ Figma px) แทนสเกลของเมนู — ไม่เล็กเกินบนจอกว้างแต่เตี้ย · จำกัดไม่เกิน 1.2 × สเกลเมนู (ลองที่ 1.5 แล้วใหญ่ไป — rif ให้ลด)
- **verify:** ภาพจริง 1710×900, 1710×1107, 1280×720, 1440×1024 — Accessory ชิดคอลัมน์ทุกขนาด, avatar ใหญ่ขึ้นตามฉาก ไม่ทับเมนู · eslint/tsc/test ผ่าน · harness ลบแล้ว

## 2026-10-22 (รอบ 4 · ล็อกหน้าต่างตาม Figma) · rif (ผ่าน Claude Code)

- **ทำอะไร:** แทน "พื้นหลัง cover ตรงกลาง + clamp แท่น" (รอบ 3) ด้วย: หน้าต่างโค้งของภาพถูกวางที่สัดส่วนเดียวกับ Figma เสมอ (x = 426/1440 ของความกว้าง, ขอบล่างหน้าต่าง y = 745/1024 ของความสูง) — คำนวณ scale/ตำแหน่งภาพที่เล็กที่สุดที่ยังเต็มจอ (ไม่มีแถบดำ) · แท่น + ตัวละคร + Accessory + Undo/Redo/Clear วางที่จุดเดียวกัน · เมนูซ้าย/ขวาชิดขอบเหมือนเดิม
- **ผล:** ภาพพื้นหลังถูกซูม/เลื่อนให้หน้าต่างอยู่ซ้ายมือแบบ Figma (ด้านซ้ายของภาพ — โต๊ะเครื่องแป้ง — ถูกตัดออก) · ทุกขนาดจอได้องค์ประกอบเดียวกัน ไม่ต้องเลื่อนแท่นหลบคอลัมน์ขวาแล้ว
- **verify:** ภาพจริง 6 ขนาด (1710×900, 1710×1107, 1280×720, 1024×768, 1440×1024, 2560×1440) — หน้าต่างอยู่ซ้าย แท่นตรงหน้าต่าง เมนูชิดขอบ ไม่ทับกันทุกขนาด · eslint/tsc/test ผ่าน · harness ลบแล้ว

## 2026-10-22 (รอบ 3 · จัด layout ตามขอบจอ) · rif (ผ่าน Claude Code)

- **ทำอะไร:** แยก layout เป็นชั้น — พื้นหลัง cover เต็มจอ · เมนูซ้าย (Headbar, SLOT, Costume) ชิดขอบซ้าย · หมวด + ไอเทม ชิดขอบขวาเต็มความสูง · แท่น + ตัวละคร + Accessory + Undo/Redo/Clear ยืนใต้หน้าต่างโค้งของภาพพื้นหลัง (จุดอ้างอิงในภาพ x 1200, y 1070) · แถบสีอยู่ล่างจอใต้แท่น · ทุกชั้นใช้สเกลเดียวกับเฟรม Figma (min(w/1440, h/1024))
- **ข้อจำกัด:** ถ้าจอแคบ (สัดส่วนใกล้ 1440×1024 หรือแคบกว่า) Accessory panel จะชนคอลัมน์ขวา → แท่นถูกเลื่อนซ้ายให้พ้น เลยไม่ตรงหน้าต่างพอดี · จอเตี้ยมากแท่นถูกดันให้อยู่ในจอ
- **verify:** ภาพจริง 6 ขนาด (1710×830, 1710×1107, 1280×720, 1024×768, 1440×1024, 2560×1440) — เมนูชิดขอบ, แท่นตรงหน้าต่างทุกขนาด ยกเว้น 1440×1024 ที่ถูกเลื่อนซ้ายตามข้อจำกัด · eslint/tsc/test ที่เกี่ยวข้องผ่าน · harness ลบแล้ว

## 2026-10-22 (รอบ 2 · แก้ขนาดจอ) · rif (ผ่าน Claude Code)

- **ทำอะไร:** ภาพพื้นหลังเปลี่ยนเป็นไฟล์ 16:9 ใหม่ (`dressing-room-wide.jpg`) แบบ **เต็มจอ (cover)** · UI ทั้งหมดอยู่ในเฟรม 1440×1024 ตาม Figma ย่อ/ขยายเป็นก้อนเดียวตรงกลาง → ตำแหน่ง UI ตรงตาม Figma ทุกขนาดหน้าต่าง · แก้ warning ของ `next/image` (slot, LCP) · รูปตู้ลบพื้นหลังแล้วเปลี่ยนชื่อเป็น `wardrobe-gold.png` (ตัด cache รูปเก่า)
- **verify:** ภาพจริงใน browser ที่ 1710×830 และ 1710×1107 — พื้นหลังเต็มจอ ไม่มีแถบดำ, UI ตำแหน่งเดียวกันทั้งสองขนาด · console ไม่มี error/warning · eslint + prettier ผ่าน · harness ชั่วคราวลบแล้ว
- **ติดอะไร:** ไม่มี

## 2026-10-22 (รอบ 1 · implement) · rif (ผ่าน Claude Code)

- **มติก่อนเริ่ม:** บันทึกอัตโนมัติตาม Figma (D-M1) · SLOT preset ยังไม่ทำ แสดง SLOT 1 (D-M3) · Default skin = Fair · ชุดแยกต่อ workspace (C-14 — Ten ทำ migration 119 แล้ว) · skin 5 เฉดของระบบ ไม่อัปโหลด (C-13) · 18 หมวด (Q-5) — ดู [spec.md](spec.md) §8.3
- **ทำอะไร:**
  - **zyra-api**
    - `internal/model/avatar_outfit.go` — skin tones 5 เฉด, outfit JSON v1 (`skin_tone`, `slots.<category>.{part_id, variant_id, color}` — คง `part_id` ให้ reset job ของ Admin ใช้ได้), type ของ catalog / response
    - `internal/service/avatar_outfit_bake.go` — bake ชีท `walk` / `sit` 192×192 (4×4 เหมือน VO) + thumb: base body เปลี่ยนสีผิวด้วยอัตราส่วน tone/Fair · ชิ้นส่วน palette swap กติกาเดียวกับ `lib/avatar-part/render.ts` · ลำดับ layer ตาม `AvatarPartCategories` · ชิ้นบนหัวที่ไม่มีชีทนั่งขยับตาม `HEAD_SIT_SHIFT`
    - `internal/service/avatar_outfit_service.go` + `avatar_outfit_store.go` — catalog (active + อยู่ในช่วงเวลา), default outfit (Fair + ชิ้น `is_default`), GET/PUT ต่อ workspace (ตรวจ member, validate, normalize occupies, ชิ้น hidden ที่ใส่อยู่ผ่าน / เลือกใหม่ = `PART_NOT_SELECTABLE`), hash = sha256(bake version + outfit + art_version) → reuse `outfits/{hash}/…` ถ้ามีแล้ว, lazy re-bake ตอน GET (หลัง reset job ล้าง `bake_hash`), cache ชีทที่ decode แล้วใน memory
    - `internal/handler/avatar_outfit_handler.go` + route `GET /api/user/avatar/catalog` (ETag) · `GET /api/user/avatar/outfit/default` · `GET`/`PUT /api/user/workspaces/:id/avatar/outfit` (body ≤ 16 KB)
    - `internal/cache/notification.go` — `PublishOutfitUpdated` (`outfit_updated_user_id` + `outfit`)
    - migration `120_user_outfit_bake_hash_index` (+ down + embedded DDL) — index `bake_hash`
    - asset `internal/service/avatar_part_assets/base_sit.png` (สำเนา `zyra-app/public/avatar/base/sit.png`)
  - **zyra-ws** — `outfit_updated` relay: `store/redis.go` (`OutfitUpdatedUserID`, `Outfit`), `hub/message.go` (`MsgOutfitUpdated`), `hub/outfit_reset.go` (`PushOutfitUpdated` → connection ของ user ใน room ของ workspace นั้น), `main.go`
  - **zyra-app**
    - `lib/api/avatar-outfit.ts` (member API) · `lib/avatar-part/outfit.ts` (skin tones, palette ของชุด parity กับ Go, แก้ชุดแบบ pure: wear / take off / clear / colour / variant, undo-redo) · `lib/avatar-outfit-sync.ts` (ชุด → `StoredAvatar` เดิม) · `lib/avatar-customize-feature.ts` (flag)
    - `views/user/avatar-customize/` — หน้า "Customise avatar" (Dressing room) เต็มจอ scale จากเฟรม 1440×1024: Headbar + ชื่อ workspace, SLOT 1, Costume/Accessory panel (double-click / Delete ถอด), เวที + ตัวละคร (pixel canvas reuse `AvatarPartCanvas` ของ Admin), Undo/Redo/Clear, คอลัมน์ 19 หมวด, การ์ด item + tag Used + จุดสี, แถบสี 12 สี + Shade (special costume = variant), spinner ระหว่างบันทึก, toast EP-01 / EC-02 ตาม Figma · บันทึกอัตโนมัติ debounce 600 ms, error → กลับชุดที่บันทึกล่าสุด
    - ต่อเข้า lobby (`hero-workspace-enter.tsx` ปุ่ม Customise avatar + ใช้ชุดของ workspace + ไม่ส่ง global pick), loading (`hero-workspace-loading.tsx` ดึงชุดก่อนต่อ ws), VO (`hero-virtual-office.tsx` ใช้ชุดตอนเปิด, overlay จากเมนูโปรไฟล์, รับ `outfit_updated` / `outfit_reset` แล้ว hot-swap + toast "Item removed"), `vo-profile-panel.tsx` (label), `lib/api/workspace-ws-types.ts` (`outfit_updated`) — ทั้งหมดอยู่หลัง flag
    - `app/layout.tsx` โหลดฟอนต์ Bagel Fat One เป็น `--font-bagel-fat-one` (label SLOT)
    - asset `public/avatar/customize/` — `dressing-room-wide.jpg` (จาก `Dressing_Room_2560x1440.png` ของ rif, แปลง jpg 85%), `base-platform.png`, `wardrobe-gold.png` (export จาก Figma + ลบพื้นหลัง) + `slot.png`
    - i18n namespace `AvatarCustomize` (en/th) + `VirtualOffice.customiseAvatar`, `WorkspaceEnter.customiseAvatarCta`
- **verify ถึงไหน:**
  - zyra-api: `go build`, `go vet ./...`, `go test ./...` เขียวทั้ง repo · test ใหม่: validation 8 กรณี, not member, normalize + publish, no-op เมื่อชุดเดิม, reuse bake ข้าม workspace, แยกต่อ workspace (HP-06), default เมื่อไม่มีแถว, ชิ้น hidden ที่ใส่อยู่, re-bake หลัง reset, hash ตาม art_version, bake: Fair = ไฟล์ base / Tan = ค่าที่คำนวณ, สีชิ้น, ชิ้นบนหัวตอนนั่ง, ลำดับ layer · handler: map error code, body cap, 401, ETag/304
  - zyra-ws: `go vet`, `go test ./...` เขียว · test `TestPushOutfitUpdated`
  - zyra-app: `tsc` ไม่มี error ใหม่ (error เดิม 9 จุดในไฟล์ test เดิม) · eslint ไฟล์ใหม่/ที่แก้ไม่มี error · `__tests__/avatar-outfit.test.ts` 24 ผ่าน (ค่าสี Tan ตรงกับ test ฝั่ง Go) · test กลุ่ม lobby / loading / profile panel / i18n ผ่าน
  - เปิดหน้าจริงใน browser ผ่าน harness ชั่วคราว (`/dev/avatar-customize`, mock API + sprite จาก `zyra/custom avatar`) ที่ 1440×1024: เปลี่ยนสีผิว, ใส่เสื้อ/หมวก, เลือกสี + Shade, ถอดด้วย double-click, Undo — ไม่มี console error · **ลบ harness แล้วก่อนส่งมอบ**
  - **ยังไม่ได้:** รันกับ zyra-api + R2 จริง (bake + upload จริง), ดู lobby / VO จริงหลังเปิด flag, 2 คนเห็นชุดกันใน ≤ 2 s, multi-tab
- **ต่อจากนี้:**
  - เปิด flag บน local (`NEXT_PUBLIC_AVATAR_CUSTOMIZE=true`) + api จริง ทดสอบ end-to-end ตาม AC ใน spec §4
  - review แล้วค่อย commit / PR (ลำดับ merge: api → ws → app)
  - e2e Playwright (เหมือน `e2e/accessory-management.spec.ts`)
- **ติดอะไร / ข้อสังเกต:**
  - Catalog ต้องมีชิ้น `is_default` (เสื้อ/กางเกงขาว) ในหน้า Admin ไม่งั้นชุด default = ตัวเปล่า (R-5)
  - `StoredAvatar` ใน localStorage เป็น key เดียว — เปิด 2 workspace คนละ tab ค่าจะทับกัน (แต่ละหน้าดึงชุดของตัวเองตอนเปิดอยู่แล้ว)
  - ยังไม่มี rate limit ฝั่ง API (client debounce 600 ms + no-op ถ้าชุดเดิม) — ถ้าโหลดสูงค่อยเพิ่ม
  - ช่องใน Costume/Accessory panel แสดงชิ้นที่ scale 1 (ภาพเล็ก) — Figma ยังไม่มีรูปชิ้นจริงให้เทียบ
  - หมวด "Dress/Outfit" ใน sticky Figma ไม่ได้ทำ (ไม่มีปุ่มใน Figma) · ลำดับหมวดใช้ตาม Figma ฝั่ง client
