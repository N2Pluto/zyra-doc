# คู่มือ dev หน้าบ้าน — ทำ module "แต่งตัวละคร" ฝั่ง user (zyra-app)

> **สำหรับ:** dev ที่รับงาน module แต่งตัวละครฝั่ง member · **อ่านก่อน:** [README.md](README.md) (ภาพรวมไฟล์) → [avatar-outfit-data.json](avatar-outfit-data.json) (data) → [api-example.md](api-example.md) (API) · **สถานะ:** draft 2026-10-21 · API ยังไม่มีจริง ให้ mock ตาม §2
> **ต้นแบบที่ต้องเปิดดูคู่กัน:** [Zyra Avatar Studio prototype](https://claude.ai/artifact/5CWTCN9yMtbQ4czt29FVty) — หน้าตา, พฤติกรรม, ข้อความ ให้ยึดอันนี้จนกว่าจะมี Figma

---

## 0. ก่อนเริ่ม — กฎโปรเจกต์ที่กระทบงานนี้

| กฎ | ผลกับงานนี้ |
|---|---|
| [17-git-branch-workflow](../../../../.claude/rules/17-git-branch-workflow.md) | `git checkout develop && git pull && git checkout -b feat/avatar-outfit` ก่อนแตะโค้ด |
| [15-member-api-separation](../../../../.claude/rules/15-member-api-separation.md) | เรียกได้แค่ `/api/user/avatar/*` ห้ามแตะ `/api/admin/*` |
| [08-shadcn-ui](../../../../.claude/rules/08-shadcn-ui.md) | Tailwind อย่างเดียว ห้าม import `components/ui/*` (ยกเว้น skeleton, icon) |
| [12-icons](../../../../.claude/rules/12-icons.md) | icon ใช้ `lucide-react` · ชื่อ icon ต่อ slot อยู่ใน data file `slots[].icon` แล้ว |
| [03-develop](../../../../.claude/rules/03-develop.md) | no semicolon, double quote, ห้าม `any`, ห้าม `<img>` (canvas ใช้ `new Image()` ได้ ไม่ใช่ JSX) |
| [19-thai-translation](../../../../.claude/rules/19-thai-translation.md) | ข้อความ UI ลง `messages/th.json` + `en.json` · ข้อความไทยทั้งหมดมีใน data file `ui_text_th` |
| [02-design](../../../../.claude/rules/02-design.md) | โครง `views/avatar-outfit/hero-avatar-outfit.tsx` + `lib/api/avatar-outfit.ts` + `app/<route>/page.tsx` |

**ไม่ต้องทำ:** หน้า admin, upload ไฟล์, validate ชีท, ws broadcast — คนละงาน

---

## 1. โครงไฟล์ที่แนะนำ

```
zyra-app/
  lib/api/avatar-outfit.ts                 # types + authFetch (copy จาก api-example.md §client)
  lib/avatar-outfit/
    catalog.ts                             # helper: findPart, findPalette, isRequired, occupiedBy
    palette.ts                             # classifyKey / rampT / rampColor  (§4)
    renderer.ts                            # โหลด sheet → ตัดเฟรม → swap สี → วาดทับ (§5)
    outfit-state.ts                        # reducer: selectPart / selectColor / normalize / randomize (§6)
  views/avatar-outfit/
    hero-avatar-outfit.tsx                 # 2 pane: stage | wardrobe
    components/
      outfit-stage.tsx                     # canvas + ปุ่ม ยืน/เดิน/นั่ง + 4 ทิศ + หมุนอัตโนมัติ
      outfit-tabs.tsx                      # tab ต่อ slot
      outfit-item-grid.tsx                 # card "ไม่ใส่" + ชิ้นส่วน
      outfit-swatches.tsx                  # swatch สีต่อ channel
      outfit-actions.tsx                   # สถานะ dirty + ยกเลิก + บันทึก
  app/avatar/page.tsx                      # route (ชื่อ route รอ PM — ตัวเลือก: /avatar, /profile/avatar)
```

จุดที่ต้องเปิดหน้านี้ (ตาม AvatarCustomization spec): lobby ก่อนเข้า workspace (แทนตัวเลือกตัวละครเดิม), หน้า Profile, profile panel ใน VO — **รอบแรกทำแค่ route เดี่ยวก่อน** ค่อยต่อ entry point

---

## 2. Mock API ให้ทำงานได้ก่อน backend

สร้าง `lib/api/avatar-outfit.mock.ts` แล้วสลับด้วย env `NEXT_PUBLIC_AVATAR_OUTFIT_MOCK=1`

```ts
import data from "@/zyra-doc-data/avatar-outfit-data.json" // copy ไฟล์มาไว้ใน zyra-app/mocks/ ก็ได้
import type { AvatarCatalog, Outfit, OutfitResponse, CatalogResponse } from "./avatar-outfit"

const envelope = <T,>(d: T) => ({ status: 200, message: "success", data: d })

export async function getAvatarCatalog(): Promise<CatalogResponse> {
  const parts = Object.fromEntries(
    Object.entries(data.parts)
      .filter(([k]) => k !== "note")
      .map(([slot, list]) => [
        slot,
        (list as { id: string; name_th: string; ch: string[]; occupies?: string[]; until?: string | null }[]).map((p) => ({
          ...p,
          thumbnail_url: null,
          walk_url: null,
          sit_url: null,
          cols: slot === "eyes" ? 5 : 4,
          available_until: p.until ?? null,
        })),
      ]),
  )
  return envelope({
    version: "mock",
    sheet: { frame: data.sheet.frame, rows: data.sheet.rows, walk_cols: 4, sit_cols: 4, blink_col: 4 },
    render_order: data.render_order,
    slots: data.slots,
    color_channels: data.color_channels,
    palettes: data.palettes,
    parts,
    default_cloth: data.default_cloth,
  } as unknown as AvatarCatalog)
}

let saved: Outfit = data.outfits.prototype_start as unknown as Outfit
const baked = { hash: "mock", walk_url: "", sit_url: "", thumbnail_url: "" }

export async function getMyOutfit(): Promise<OutfitResponse> {
  return envelope({ is_default: false, outfit: saved, baked, updated_at: null })
}
export async function getDefaultOutfit(): Promise<OutfitResponse> {
  return envelope({ is_default: true, outfit: data.outfits.default as unknown as Outfit, baked, updated_at: null })
}
export async function saveMyOutfit(outfit: Outfit): Promise<OutfitResponse> {
  await new Promise((r) => setTimeout(r, 700)) // เลียนแบบ "กำลังประกอบชุด…"
  saved = outfit
  return envelope({ is_default: false, outfit, baked, updated_at: new Date().toISOString() })
}
```

**ข้อจำกัดของ mock:** `walk_url / sit_url` เป็น null เพราะ prototype วาดชิ้นด้วยโค้ด ไม่มี PNG จริง → ตอน mock ให้ renderer ข้ามชิ้นที่ไม่มี URL และวาดเฉพาะ body (ขอไฟล์ `Avatar - default` 1000×1000 จาก Ten/ศิลปิน แล้วย่อเป็น 192×192 ไว้ใน `public/mock/avatar/base_walk.png`, `base_sit.png`) · ผมทรงไทยมีไฟล์จริงใน prototype (`demo file/avatar/1/`) ขอมาใช้ทดสอบ palette swap ได้

---

## 3. Data flow ของหน้า

```
mount
 ├─ GET catalog  ──▶ ["avatar","catalog"]         (staleTime ยาว, invalidate เมื่อได้ PART_NOT_FOUND)
 └─ GET outfit   ──▶ ["avatar","outfit","me"]     → set state `outfit` + `saved`
user กด item / swatch ──▶ reducer (§6) → `outfit` เปลี่ยน → renderer วาดใหม่ (debounce ไม่ต้อง วาด 1 เฟรม < 5ms)
isDirty = JSON.stringify(normalize(outfit)) !== JSON.stringify(normalize(saved))
กด บันทึก ──▶ PUT outfit (body = normalize(outfit)) → สำเร็จ: saved = outfit, invalidate ["avatar","outfit","me"], toast "บันทึกแล้ว ทุก workspace จะเห็นชุดนี้"
กด ยกเลิก ──▶ outfit = saved
กด ชุดเริ่มต้น ──▶ outfit = default (จาก GET outfit/default) ยังไม่ save
```

สถานะมุมล่างซ้าย: ไม่ dirty = จุดเขียว "ใช้ชุดนี้ในทุก workspace" · dirty = จุดเหลือง "ยังไม่ได้บันทึก" · ขณะ save ปุ่มขึ้น "กำลังประกอบชุด…" + `aria-busy`

---

## 4. Palette swap — หัวใจของ renderer (`lib/avatar-outfit/palette.ts`)

ชิ้นส่วนถูกวาดด้วย **สี key** 5 โทน (ดู `color_channels[].key`) · ตอนวาดต้องแทนด้วย palette ที่ user เลือก · **ไม่ใช่ match 4 ค่าตรง ๆ** แต่จัดกลุ่มตาม "ตระกูลสี" แล้วไล่เฉดตามความสว่าง (ศิลปินใช้เฉดกลางได้)

```ts
export type Channel = "skin" | "hair" | "eye" | "primary" | "secondary"
type RGB = [number, number, number]

const KEY: Record<Channel, [string, string, string, string]> = {
  skin: ["#FFA0FF", "#FF00FF", "#A000A0", "#500050"],
  hair: ["#A0FFFF", "#00FFFF", "#00A0A0", "#005050"],
  eye: ["#FFFFA0", "#FFFF00", "#A0A000", "#505000"],
  primary: ["#FFA0A0", "#FF0000", "#A00000", "#500000"],
  secondary: ["#A0FFA0", "#00FF00", "#00A000", "#005000"],
}

export const hex2rgb = (h: string): RGB => [
  parseInt(h.slice(1, 3), 16),
  parseInt(h.slice(3, 5), 16),
  parseInt(h.slice(5, 7), 16),
]
const lum = ([r, g, b]: RGB) => r * 0.299 + g * 0.587 + b * 0.114
const KEY_L = Object.fromEntries(
  Object.entries(KEY).map(([ch, arr]) => [ch, arr.map((h) => lum(hex2rgb(h)))]),
) as Record<Channel, number[]>

// สี key เป็นสี "pure": 2 channel ที่เท่ากันต้องต่างกันไม่เกิน 3 และ channel ที่เหลือต้อง ≤ 70% ของอีกสอง
// (ให้ outline แดงเข้มที่ศิลปินจิ้มเอง เช่น #672924 ยังคงเป็นสีตายตัว)
const FAMILY: [Channel, (r: number, g: number, b: number) => boolean][] = [
  ["skin", (r, g, b) => Math.abs(r - b) <= 3 && g <= Math.min(r, b) * 0.7],
  ["hair", (r, g, b) => Math.abs(g - b) <= 3 && r <= Math.min(g, b) * 0.7],
  ["eye", (r, g, b) => Math.abs(r - g) <= 3 && b <= Math.min(r, g) * 0.7],
  ["primary", (r, g, b) => Math.abs(g - b) <= 3 && Math.max(g, b) <= r * 0.7],
  ["secondary", (r, g, b) => Math.abs(r - b) <= 3 && Math.max(r, b) <= g * 0.7],
]

/** คืน channel ถ้า pixel เป็นสี key · null = สีตายตัว วาดตามไฟล์ */
export function classifyKey(r: number, g: number, b: number): Channel | null {
  const mx = Math.max(r, g, b)
  const mn = Math.min(r, g, b)
  if (mx < 40 || mx - mn < 40) return null
  const f = FAMILY.find(([, test]) => test(r, g, b))
  return f ? f[0] : null
}

/** ตำแหน่งบน ramp 0..3 (ทศนิยมได้) ตามความสว่างของ pixel เทียบกับ 4 เฉด key */
export function rampT(ch: Channel, rgb: RGB): number {
  const L = lum(rgb)
  const A = KEY_L[ch]
  if (L >= A[0]) return 0
  if (L <= A[3]) return 3
  for (let i = 0; i < 3; i++) {
    if (L <= A[i] && L > A[i + 1]) return i + (A[i] - L) / (A[i] - A[i + 1])
  }
  return 3
}

/** สีจริงจาก palette 4 เฉด ที่ตำแหน่ง t (lerp ระหว่างเฉด) */
export function rampColor(ramp: [string, string, string, string], t: number): RGB {
  if (Number.isInteger(t)) return hex2rgb(ramp[t])
  const i = Math.floor(t)
  const f = t - i
  const a = hex2rgb(ramp[i])
  const b = hex2rgb(ramp[Math.min(3, i + 1)])
  return [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f]
}
```

**กฎ:** ชิ้น `costume` ข้าม classifyKey ทั้งหมด (วาดตามไฟล์) · pixel ที่ `alpha < 128` ไม่วาด · `rampT` cache ได้ต่อชิ้น (คำนวณครั้งเดียวตอนโหลด sheet ไม่ใช่ทุกเฟรม)

---

## 5. Renderer (`lib/avatar-outfit/renderer.ts`)

### 5.1 โหลดชีทครั้งเดียว → แปลงเป็น "เฟรมที่ classify แล้ว"

```ts
const W = 48
const H = 48
const ROW = { down: 0, left: 1, right: 2, up: 3 } as const
export type Dir = keyof typeof ROW

type Px = { hex?: string; ch?: Channel; t?: number } // hex = สีตายตัว · ch+t = สี key
export type ParsedSheet = { cols: 4 | 5; frames: (Px | null)[][] } // frames[row*cols+col][y*W+x]

export async function parseSheet(url: string, fixedOnly: boolean): Promise<ParsedSheet> {
  const img = await loadImage(url) // new Image() + crossOrigin = "anonymous" (R2 ต้องเปิด CORS)
  const cols = Math.round(img.naturalWidth / W) as 4 | 5
  const c = document.createElement("canvas")
  c.width = img.naturalWidth
  c.height = img.naturalHeight
  const x = c.getContext("2d")!
  x.drawImage(img, 0, 0)
  const rgba = x.getImageData(0, 0, c.width, c.height).data
  const frames: (Px | null)[][] = []
  for (let r = 0; r < 4; r++) {
    for (let col = 0; col < cols; col++) {
      const fr: (Px | null)[] = new Array(W * H).fill(null)
      for (let y = 0; y < H; y++) {
        for (let px = 0; px < W; px++) {
          const i = ((r * H + y) * c.width + col * W + px) * 4
          if (rgba[i + 3] < 128) continue
          const [R, G, B] = [rgba[i], rgba[i + 1], rgba[i + 2]]
          const ch = fixedOnly ? null : classifyKey(R, G, B)
          fr[y * W + px] = ch ? { ch, t: rampT(ch, [R, G, B]) } : { hex: rgbHex(R, G, B) }
        }
      }
      frames.push(fr)
    }
  }
  return { cols, frames }
}
```

### 5.2 เลือกเฟรม (sheet, col) จากท่า + เวลา — ตรงกับ `animation` ใน data file

```ts
export type Mode = "stand" | "walk" | "sit"
export function pickFrame(mode: Mode, tick: number, sitTick: number, blinking: boolean) {
  if (mode === "walk") return { sheet: "walk" as const, col: tick % 4 }
  if (mode === "stand") return { sheet: "walk" as const, col: blinking ? 4 : 1 }
  const c = Math.min(sitTick, 2)
  return { sheet: "sit" as const, col: c === 2 && blinking ? 4 : c }
}
// tick ทุก 125 ms · เข้าโหมดนั่งให้ sitTick = 0 แล้วนับขึ้น · blink: ยาว 100 ms ทุก 1800 + random(2800) ms · blink ได้เมื่อ stand หรือ sit && sitTick >= 2
```

### 5.3 วาด 1 เฟรมของทั้งชุด

```ts
export function drawOutfit(ctx: CanvasRenderingContext2D, scale: number, outfit: Outfit, catalog: AvatarCatalog, sheets: Map<string, { walk: ParsedSheet; sit: ParsedSheet | null }>, dir: Dir, sheet: "walk" | "sit", col: number) {
  const costume = outfit.slots.costume && findPart(catalog, "costume", outfit.slots.costume.id)
  const occupied = costume?.occupies ?? []
  for (const slot of catalog.render_order) {
    const sel = outfit.slots[slot]
    if (!sel || occupied.includes(slot)) continue          // costume ทับ top/bottom
    const loaded = sheets.get(`${slot}/${sel.id}`)
    if (!loaded) continue                                   // ยังโหลดไม่เสร็จ / mock ไม่มีไฟล์
    const ps = sheet === "sit" && loaded.sit ? loaded.sit : loaded.walk   // ไม่มี sit → ใช้ walk
    const useCol = col === 4 ? (ps.cols === 5 ? 4 : sheet === "walk" ? 1 : 2) : col // blink fallback
    const fr = ps.frames[ROW[dir] * ps.cols + useCol]
    if (!fr) continue
    for (let k = 0; k < W * H; k++) {
      const p = fr[k]
      if (!p) continue
      const rgb = p.hex ? hex2rgb(p.hex) : rampColor(paletteFor(catalog, outfit, slot, p.ch!), p.t!)
      ctx.fillStyle = `rgb(${rgb[0]|0},${rgb[1]|0},${rgb[2]|0})`
      ctx.fillRect((k % W) * scale, Math.floor(k / W) * scale, scale, scale)
    }
  }
}

// palette ที่ใช้กับ channel นี้: global (skin/hair/eye) มาจาก outfit.colors · slot (primary/secondary) มาจาก outfit.slots[slot].colors
function paletteFor(catalog: AvatarCatalog, outfit: Outfit, slot: SlotId, ch: Channel) {
  const def = catalog.color_channels[ch]
  const id = def.scope === "global" ? outfit.colors[ch as GlobalChannel] : outfit.slots[slot]?.colors?.[ch as SlotChannel] ?? catalog.default_cloth[ch as SlotChannel]
  return (catalog.palettes[def.palette].find((p) => p.id === id) ?? catalog.palettes[def.palette][0]).c
}
```

- canvas ตั้ง `imageSmoothingEnabled = false` + CSS `image-rendering: pixelated` · stage ใน prototype 288×288 (scale 6) · ปุ่มทิศ 64×88 · thumbnail card ตัดตาม `thumbnail_crop` ใน data file
- ชิ้นที่ `ch` ว่าง (เช่น แว่นกันแดด, สร้อยทอง) ก็ผ่าน parseSheet ปกติ จะได้ `hex` ทั้งชิ้นเอง
- perf: cache ผลวาดต่อ key `dir|sheet|col|hash(outfit)` เป็น ImageData — prototype ใช้ `Map` แล้ว clear ตอน outfit เปลี่ยน

---

## 6. State reducer (`lib/avatar-outfit/outfit-state.ts`) — ต้องตรงกับ `outfit_state_shape.rules`

```ts
export function selectPart(o: Outfit, catalog: AvatarCatalog, slot: SlotId, id: string | null): Outfit {
  const v = structuredClone(o)
  if (slot === "costume") { v.slots.costume = id ? { id } : null; return v }
  if (id === null) { v.slots[slot] = null }
  else {
    const part = findPart(catalog, slot, id)!
    const prev = o.slots[slot]
    const colors: Partial<Record<SlotChannel, string>> = {}
    part.ch.filter((c): c is SlotChannel => c === "primary" || c === "secondary")
      .forEach((c) => { colors[c] = prev?.colors?.[c] ?? catalog.default_cloth[c] })   // คงสีเดิมถ้าชิ้นใหม่ใช้ channel นั้น
    v.slots[slot] = { id, colors }
  }
  if (slot === "top" || slot === "bottom") v.slots.costume = null  // ถอด costume + toast "ถอดชุด special ออกแล้ว" (ทำที่ caller)
  return v
}

export function selectColor(o: Outfit, target: { type: "global"; ch: GlobalChannel } | { type: "slot"; slot: SlotId; ch: SlotChannel }, paletteId: string): Outfit {
  const v = structuredClone(o)
  if (target.type === "global") v.colors[target.ch] = paletteId
  else if (v.slots[target.slot]) v.slots[target.slot]!.colors = { ...v.slots[target.slot]!.colors, [target.ch]: paletteId }
  return v
}

/** ก่อน save / ก่อนเทียบ dirty: costume ทับ top+bottom → เคลียร์ 2 slot นั้นเป็น null */
export function normalize(o: Outfit, catalog: AvatarCatalog): Outfit {
  const n = structuredClone(o)
  const cos = n.slots.costume && findPart(catalog, "costume", n.slots.costume.id)
  cos?.occupies?.forEach((s) => { n.slots[s] = null })
  return n
}

export function randomize(o: Outfit, catalog: AvatarCatalog): Outfit {
  const pick = <T,>(a: T[]) => a[Math.floor(Math.random() * a.length)]
  const plain = catalog.palettes.cloth.filter((p) => !p.special)
  const v = structuredClone(o)
  v.colors = { skin: pick(catalog.palettes.skin).id, hair: pick(catalog.palettes.hair).id, eye: pick(catalog.palettes.eye).id }
  for (const slot of catalog.render_order.filter((s) => s !== "costume")) {
    const def = catalog.slots.find((s) => s.id === slot)!
    if (!def.required && Math.random() < 0.45) { v.slots[slot] = null; continue }
    const part = pick(catalog.parts[slot])
    const colors: Partial<Record<SlotChannel, string>> = {}
    part.ch.filter((c): c is SlotChannel => c === "primary" || c === "secondary").forEach((c) => { colors[c] = pick(plain).id })
    v.slots[slot] = { id: part.id, colors }
  }
  v.slots.costume = Math.random() < 0.12 && catalog.parts.costume.length ? { id: pick(catalog.parts.costume).id } : null
  return v
}
```

---

## 7. UI checklist (เทียบกับ prototype ทีละข้อ)

**Stage (pane ซ้าย)**
- [ ] canvas 288×288 พื้น `#2B3540` มุม 12px
- [ ] segmented ยืน / เดิน / นั่ง (icon `person-standing` / `footprints` / `armchair`)
- [ ] ปุ่มทิศ 4 ปุ่ม แต่ละปุ่มมี canvas เล็กโชว์ตัวละครทิศนั้น · ปุ่มที่เลือกขอบ `#58D68D`
- [ ] toggle "หมุนดูรอบตัวอัตโนมัติ" (เปิดเป็นค่าเริ่มต้น · เปลี่ยนทิศทุก 14 tick ลำดับ ลง→ซ้าย→ขึ้น→ขวา)
- [ ] ปุ่ม สุ่ม (`dices`) / ชุดเริ่มต้น (`rotate-ccw`)

**Wardrobe (pane ขวา)**
- [ ] tab ต่อ slot ตาม `slots[]` (icon + ชื่อไทย) · tab Special สี `#C3A6FF`
- [ ] หัว tab: ชื่อ + hint "ต้องมี" / "ใส่หรือไม่ใส่ก็ได้" / "ชุดตามเทศกาล ขึ้นเฉพาะช่วงที่เปิด"
- [ ] grid card `minmax(104px,1fr)` · card แรก "ไม่ใส่" (icon `ban`) เฉพาะ slot ไม่บังคับ · card ที่เลือกมี check เขียวมุมขวาบน
- [ ] costume card มี badge "ถึง {until}" (`calendar-clock`) หรือ "Special" (`sparkles`)
- [ ] ถ้าใส่ costume อยู่แล้วเปิด tab เสื้อ/กางเกง → แสดง banner เหลือง + ปุ่ม "ถอดชุด special" แทน grid
- [ ] swatch: tab ตัว → สีผิว · tab ตา → สีตา (ถ้าชิ้นใช้ `eye`) · tab ผม/หนวด → สีผม · slot อื่น → สีหลัก/สีรอง ตาม `ch` ของชิ้นที่เลือก · ชิ้น `ch` ว่าง → ข้อความล็อก (`lock`)
- [ ] swatch special มีจุด `sparkles` มุมขวาบน + title "(special ถึง …)"
- [ ] แถบล่าง: สถานะ dirty + ยกเลิก + บันทึก (`check`)

**ข้อความทั้งหมด** อยู่ใน data file `ui_text_th` → ลง `messages/th.json` key `avatarOutfit.*` แล้วแปล en คู่กัน

---

## 8. ทดสอบ (vitest) — อย่างน้อยต้องมี

| ไฟล์ | เทสอะไร |
|---|---|
| `palette.test.ts` | `classifyKey`: 4 เฉด key ทุก channel → channel ถูก · `#672924` → null · เทา/ดำ → null · `rampT`: เฉด key ตรง → 0,1,2,3 · เฉดกลาง → ทศนิยมระหว่าง |
| `outfit-state.test.ts` | selectPart คงสีเดิม · เลือก top ถอด costume · normalize เคลียร์ top/bottom เมื่อมี costume · randomize ไม่หยิบ palette special และไม่ปล่อย required เป็น null |
| `renderer.test.ts` | pickFrame ทุก mode · blink fallback col 4 → 1/2 เมื่อ cols = 4 · ไม่มี sit → ใช้ walk |
| `avatar-outfit.test.ts` | mock `authFetch` ตาม [04-test.md](../../../../.claude/rules/04-test.md) · save สำเร็จ invalidate query · 400 PART_NOT_FOUND → refetch catalog |

---

## 9. Definition of done รอบแรก

- [ ] เปิด route แล้วเห็นตัวละคร base หมุน + กะพริบ (ใช้ไฟล์ base จริงจาก Ten)
- [ ] เปลี่ยนสีผิว/ผม/ตา เห็นผลทันที
- [ ] ใส่ผมทรงไทย (ไฟล์จริง) แล้วเปลี่ยนสีผมได้ → พิสูจน์ palette swap ทำงานกับไฟล์ที่ศิลปินวาด
- [ ] save ผ่าน mock → สถานะเปลี่ยนเป็น "ใช้ชุดนี้ในทุก workspace"
- [ ] `npx tsc --noEmit` + `npm run lint` + `vitest run` เขียว
- [ ] PR เข้า `develop` พร้อม screenshot 4 ทิศ × 3 ท่า

**ยังไม่ต้องทำรอบแรก:** entry point จาก lobby/profile/VO, ต่อ API จริง, ส่ง URL ที่ bake แล้วให้ VO renderer

---

## 10. ถามใคร

| เรื่อง | คน |
|---|---|
| ไฟล์ base `Avatar - default` + ผมทรงไทย สำหรับ mock | Ten |
| route ชื่ออะไร / เปิดจากไหนก่อน | PM (Moss) |
| API จริงพร้อมเมื่อไหร่ · path เปลี่ยนไหม | Ten (ดู [api-example.md](api-example.md)) |
| Figma หน้าแต่งตัว | Designer (ยังไม่มี — AvatarCustomization ข้อค้าง 4) |
