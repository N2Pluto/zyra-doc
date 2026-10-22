# API ตัวอย่าง — ฝั่ง user (member) แต่งตัวละคร

> **สถานะ:** ข้อเสนอ (proposal) 2026-10-21 · **ยังไม่มีใน zyra-api** · ใช้ให้หน้าบ้านเริ่ม mock ได้ก่อน backend เสร็จ · path/field เปลี่ยนได้ ถ้าเปลี่ยนให้แก้ไฟล์นี้ + [avatar-outfit-data.json](avatar-outfit-data.json) คู่กัน
> **กฎที่ยึด:** member เรียกได้เฉพาะ `/api/user/*` ([15-member-api-separation.md](../../../../.claude/rules/15-member-api-separation.md)) · response ใช้ envelope `{ status, message, data }` เหมือน `model.APIResponse` · client ใช้ `authFetch` จาก `lib/api/client.ts` เหมือน `lib/api/avatars.ts` เดิม
> **ของเดิมที่ยังอยู่:** `GET /api/user/avatars`, `GET /api/user/avatars/default`, `PUT /api/user/me/avatar-selection` เป็น model "เลือกตัวสำเร็จรูป" — ชุดใหม่นี้จะมาแทน ไม่ต่อยอด (requirements Q2)

ชื่อ type/field ตรงกับ [avatar-outfit-data.json](avatar-outfit-data.json) ทั้งหมด

---

## สรุป endpoint

| # | Method | Path | ทำอะไร | Guard |
|---|---|---|---|---|
| 1 | GET | `/api/user/avatar/catalog` | โหลด slot + ชิ้นส่วนที่ **active** + palette + สี key + sheet spec (ทุกอย่างที่ต้องใช้เปิดหน้าแต่งตัว) | UserGuard |
| 2 | GET | `/api/user/avatar/outfit` | ชุดปัจจุบันของฉัน + URL ไฟล์ที่ bake แล้ว | UserGuard |
| 3 | PUT | `/api/user/avatar/outfit` | บันทึกชุด → server validate + bake → คืน URL ใหม่ | UserGuard |
| 4 | POST | `/api/user/avatar/outfit/preview` | (optional) ขอ preview sheet ของชุดที่ยังไม่ save — ใช้ถ้าหน้าบ้านไม่ render เอง | UserGuard |
| 5 | GET | `/api/user/avatar/outfit/default` | ชุด default ของ platform (ปุ่ม "ชุดเริ่มต้น") | UserGuard |

หน้าบ้าน render preview เองจาก catalog ได้ (prototype ทำแบบนั้น) → ข้อ 4 เป็น optional ถ้าทีมอยากให้ server วาดให้

---

## 1. `GET /api/user/avatar/catalog`

ไม่มี query · cache ได้ (ETag) เพราะเปลี่ยนเฉพาะตอน admin แก้

**Response 200**

```json
{
  "status": 200,
  "message": "success",
  "data": {
    "version": "2026-10-21T03:00:00Z",
    "sheet": {
      "frame": { "width": 48, "height": 48 },
      "rows": ["down", "left", "right", "up"],
      "walk_cols": 4,
      "sit_cols": 4,
      "blink_col": 4
    },
    "render_order": ["body", "eyes", "bottom", "shoes", "top", "costume", "facial_hair", "accessory", "hair", "glasses", "hat"],
    "slots": [
      { "id": "body", "name_th": "ตัว", "name_en": "Body", "icon": "person-standing", "required": true, "head": false, "color_channels": ["skin"] },
      { "id": "eyes", "name_th": "ตา", "name_en": "Eyes", "icon": "eye", "required": true, "head": true, "color_channels": ["eye", "skin", "hair"] },
      { "id": "top", "name_th": "เสื้อ", "name_en": "Top", "icon": "shirt", "required": true, "head": false, "color_channels": ["primary", "secondary", "skin"] },
      { "id": "costume", "name_th": "ชุด Special", "name_en": "Special", "icon": "sparkles", "required": false, "head": false, "color_channels": [], "occupies": ["top", "bottom"] }
    ],
    "color_channels": {
      "skin":      { "scope": "global", "palette": "skin",  "key": ["#FFA0FF", "#FF00FF", "#A000A0", "#500050"] },
      "hair":      { "scope": "global", "palette": "hair",  "key": ["#A0FFFF", "#00FFFF", "#00A0A0", "#005050"] },
      "eye":       { "scope": "global", "palette": "eye",   "key": ["#FFFFA0", "#FFFF00", "#A0A000", "#505000"] },
      "primary":   { "scope": "slot",   "palette": "cloth", "key": ["#FFA0A0", "#FF0000", "#A00000", "#500000"] },
      "secondary": { "scope": "slot",   "palette": "cloth", "key": ["#A0FFA0", "#00FF00", "#00A000", "#005000"] }
    },
    "palettes": {
      "skin":  [ { "id": "base", "name_th": "สีจากไฟล์ base", "c": ["#FEE8D6", "#FFE8BF", "#FFD3B0", "#F6AF83"] } ],
      "hair":  [ { "id": "black", "name_th": "ดำ", "c": ["#5A5A66", "#2E2E38", "#1C1C24", "#0A0A0F"] } ],
      "eye":   [ { "id": "teal", "name_th": "เขียวน้ำทะเล", "c": ["#7FD6D2", "#2F8F94", "#17555A", "#0A2A2E"] } ],
      "cloth": [
        { "id": "navy", "name_th": "กรมท่า", "c": ["#7092D6", "#3A5AA8", "#26407A", "#132144"] },
        { "id": "halloween", "name_th": "ส้มฮาโลวีน", "c": ["#FFC27A", "#FF7A1A", "#C24E05", "#5A2404"], "special": true, "available_until": "2026-10-31T16:59:59Z" }
      ]
    },
    "parts": {
      "body":  [ { "id": "std", "name_th": "ตัว base (Avatar default)", "ch": ["skin"], "thumbnail_url": "https://pub-xxx.r2.dev/avatar/parts/body/std/thumb.png" } ],
      "eyes":  [ { "id": "classic", "name_th": "แบบตัวเดิม", "ch": ["eye"], "thumbnail_url": "…", "walk_url": "…/eyes/classic/walk.png", "sit_url": "…/eyes/classic/sit.png", "cols": 5 } ],
      "hair":  [ { "id": "thai", "name_th": "ทรงไทย", "ch": ["hair"], "thumbnail_url": "…", "walk_url": "…", "sit_url": "…", "cols": 4 } ],
      "top":   [ { "id": "hoodie", "name_th": "ฮู้ด", "ch": ["primary", "secondary"], "thumbnail_url": "…", "walk_url": "…", "sit_url": null, "cols": 4 } ],
      "costume": [
        { "id": "pumpkin", "name_th": "ฟักทองฮาโลวีน", "ch": [], "occupies": ["top", "bottom"], "available_from": "2026-10-01T00:00:00Z", "available_until": "2026-10-31T16:59:59Z", "thumbnail_url": "…", "walk_url": "…", "sit_url": "…", "cols": 4 }
      ]
    },
    "default_cloth": { "primary": "navy", "secondary": "white" }
  }
}
```

ข้อตกลง
- ส่งเฉพาะชิ้น `status = active` · ชิ้น hidden/deleted ไม่ส่ง (admin HP-05) · costume นอกช่วง `available_from..available_until` ไม่ส่ง
- `sit_url = null` → หน้าบ้านใช้ walk sheet แทนท่านั่ง (ตาม prototype)
- `cols` = 4 หรือ 5 (5 = มีคอลัมน์หลับตา) · ถ้า 4 หน้าบ้าน fallback blink → col 1 (walk) / col 2 (sit)
- `until` ใน prototype เป็นข้อความ "31 ต.ค." → API ส่งเป็น ISO `available_until` แล้วหน้าบ้าน format เอง
- ค่าเต็มของ slots/palettes/parts ดูใน [avatar-outfit-data.json](avatar-outfit-data.json)

---

## 2. `GET /api/user/avatar/outfit`

**Response 200 — เคยแต่งแล้ว**

```json
{
  "status": 200,
  "message": "success",
  "data": {
    "is_default": false,
    "outfit": {
      "colors": { "skin": "base", "hair": "black", "eye": "teal" },
      "slots": {
        "body": { "id": "std" },
        "eyes": { "id": "classic" },
        "hair": { "id": "thai" },
        "facial_hair": null,
        "top": { "id": "hoodie", "colors": { "primary": "teal", "secondary": "white" } },
        "bottom": { "id": "pants", "colors": { "primary": "navy" } },
        "shoes": { "id": "sneaker", "colors": { "primary": "red" } },
        "hat": null,
        "glasses": null,
        "accessory": null,
        "costume": null
      }
    },
    "baked": {
      "hash": "a91f3c…",
      "walk_url": "https://pub-xxx.r2.dev/outfits/a91f3c…/walk.png",
      "sit_url": "https://pub-xxx.r2.dev/outfits/a91f3c…/sit.png",
      "thumbnail_url": "https://pub-xxx.r2.dev/outfits/a91f3c…/thumb.png"
    },
    "updated_at": "2026-10-21T03:12:45Z"
  }
}
```

**Response 200 — ไม่เคยแต่ง (ได้ชุด default อัตโนมัติ)** → `is_default: true`, `outfit` = ชุด default, `baked` ชี้ไฟล์ default ที่ใช้ร่วมกัน, `updated_at: null`

---

## 3. `PUT /api/user/avatar/outfit`

**Request** (`Content-Type: application/json`) — รูปเดียวกับ `outfit_state_shape` ใน data file

```json
{
  "colors": { "skin": "s3", "hair": "blonde", "eye": "blue" },
  "slots": {
    "body": { "id": "std" },
    "eyes": { "id": "sparkle" },
    "hair": { "id": "bob" },
    "facial_hair": null,
    "top": { "id": "tee", "colors": { "primary": "red", "secondary": "white" } },
    "bottom": { "id": "shorts", "colors": { "primary": "navy" } },
    "shoes": null,
    "hat": { "id": "cap", "colors": { "primary": "black", "secondary": "white" } },
    "glasses": null,
    "accessory": null,
    "costume": null
  }
}
```

Server ทำ: validate → normalize (costume ≠ null → top/bottom = null) → bake walk.png + sit.png + thumb.png (240×192) → upload R2 → เก็บ outfit JSON + hash → broadcast ให้ VO ที่ user อยู่ (ถ้าอยู่) → ตอบ

**Response 200** — เหมือน GET ข้อ 2 (`is_default: false`, `baked` ใหม่)

**Error**

| HTTP | `message` | เมื่อไหร่ | `detail` |
|---|---|---|---|
| 400 | `REQUIRED_SLOT_MISSING` | slot required เป็น null | `{ "slot": "top" }` |
| 400 | `PART_NOT_FOUND` | id ไม่มี / hidden / deleted / costume นอกช่วง | `{ "slot": "hat", "id": "cap" }` |
| 400 | `PALETTE_NOT_FOUND` | palette id ไม่มี หรือ special หมดช่วง | `{ "channel": "primary", "id": "halloween" }` |
| 400 | `CHANNEL_NOT_ALLOWED` | ส่ง colors ของ channel ที่ชิ้นนั้นไม่ใช้ | `{ "slot": "glasses", "channel": "secondary" }` |
| 500 | `BAKE_FAILED` | ประกอบรูปไม่สำเร็จ | — |

```json
{ "status": 400, "message": "PART_NOT_FOUND", "detail": { "slot": "hat", "id": "cap" } }
```

หน้าบ้าน: โชว์ toast ตาม `message` (ตาม pattern `toastServerError` ใน `avatar-validation.ts` เดิม) · ถ้า `PART_NOT_FOUND` ให้ reload catalog เพราะ admin อาจเพิ่ง hide ชิ้นนั้น (HP-05 "หายทันที")

---

## 4. `POST /api/user/avatar/outfit/preview` (optional)

Request = body เดียวกับข้อ 3 · Response `data: { walk_url, sit_url }` เป็นไฟล์ชั่วคราว (หมดอายุ 10 นาที) · **ไม่ save** · ใช้เฉพาะถ้าตัดสินใจให้ server render preview แทนหน้าบ้าน

---

## 5. `GET /api/user/avatar/outfit/default`

Response `data` = `{ outfit, baked }` ของชุด default (ค่าเดียวกับ `outfits.default` ใน data file) · ปุ่ม "ชุดเริ่มต้น" ใช้ค่านี้ set state ไม่ต้อง save ทันที

---

## Realtime (เกี่ยวกับ zyra-ws — ยังไม่ออกแบบ)

- หลัง PUT สำเร็จ server ส่ง event ให้ VO ที่ user อยู่ เพื่อให้คนอื่นเห็นชุดใหม่ทันทีโดยไม่ reload (AvatarCustomization spec "Save → คนที่อยู่ใน VO เดียวกันเห็นทันที") · ws ยังรับ "URL เดียวต่อคน" เหมือนเดิม แค่ URL เปลี่ยน
- admin hide/delete ชิ้น → ชุดของ user **ไม่เปลี่ยน** (HP-05) · delete → reset slot นั้น + re-bake + broadcast (HP-06/EC-02) — ฝั่ง admin รับผิดชอบ ไม่ใช่ endpoint ชุดนี้

---

## ตัวอย่าง client (zyra-app) — `lib/api/avatar-outfit.ts`

```ts
import { authFetch } from "@/lib/api/client"

export type SlotId =
  | "body" | "eyes" | "hair" | "facial_hair" | "top" | "bottom"
  | "shoes" | "hat" | "glasses" | "accessory" | "costume"
export type GlobalChannel = "skin" | "hair" | "eye"
export type SlotChannel = "primary" | "secondary"
export type Channel = GlobalChannel | SlotChannel

export interface SlotDef {
  id: SlotId
  name_th: string
  name_en: string
  icon: string
  required: boolean
  head: boolean
  color_channels: Channel[]
  occupies?: SlotId[]
}

export interface PaletteEntry {
  id: string
  name_th: string
  c: [string, string, string, string]
  special?: boolean
  available_until?: string | null
}

export interface PartDef {
  id: string
  name_th: string
  ch: Channel[]
  thumbnail_url: string | null
  walk_url: string | null
  sit_url: string | null
  cols: 4 | 5
  occupies?: SlotId[]
  available_from?: string | null
  available_until?: string | null
}

export interface AvatarCatalog {
  version: string
  sheet: { frame: { width: number; height: number }; rows: string[]; walk_cols: number; sit_cols: number; blink_col: number }
  render_order: SlotId[]
  slots: SlotDef[]
  color_channels: Record<Channel, { scope: "global" | "slot"; palette: "skin" | "hair" | "eye" | "cloth"; key: string[] }>
  palettes: Record<"skin" | "hair" | "eye" | "cloth", PaletteEntry[]>
  parts: Record<SlotId, PartDef[]>
  default_cloth: Record<SlotChannel, string>
}

export interface SlotSelection {
  id: string
  colors?: Partial<Record<SlotChannel, string>>
}

export interface Outfit {
  colors: Record<GlobalChannel, string>
  slots: Record<SlotId, SlotSelection | null>
}

export interface BakedOutfit {
  hash: string
  walk_url: string
  sit_url: string
  thumbnail_url: string
}

export interface OutfitResponse {
  status: number
  message: string
  detail?: Record<string, unknown>
  data?: {
    is_default: boolean
    outfit: Outfit
    baked: BakedOutfit
    updated_at: string | null
  }
}

export interface CatalogResponse {
  status: number
  message: string
  data?: AvatarCatalog
}

export async function getAvatarCatalog(): Promise<CatalogResponse> {
  return authFetch<CatalogResponse>("/api/user/avatar/catalog")
}

export async function getMyOutfit(): Promise<OutfitResponse> {
  return authFetch<OutfitResponse>("/api/user/avatar/outfit")
}

export async function getDefaultOutfit(): Promise<OutfitResponse> {
  return authFetch<OutfitResponse>("/api/user/avatar/outfit/default")
}

export async function saveMyOutfit(outfit: Outfit): Promise<OutfitResponse> {
  return authFetch<OutfitResponse>("/api/user/avatar/outfit", {
    method: "PUT",
    body: JSON.stringify(outfit),
  })
}
```

ใช้กับ TanStack Query ตาม [guides/tanstack-query-migration.md](../../../guides/tanstack-query-migration.md) — key แนะนำ `["avatar", "catalog"]`, `["avatar", "outfit", "me"]` · หลัง `saveMyOutfit` สำเร็จ invalidate `["avatar", "outfit", "me"]`

---

## Mock สำหรับหน้าบ้านเริ่มก่อน

- `GET catalog` → ใช้ [avatar-outfit-data.json](avatar-outfit-data.json) ส่วน `sheet`, `render_order`, `slots`, `color_channels`, `palettes`, `parts`, `default_cloth` ห่อด้วย `{ status: 200, message: "success", data: … }` · เติม `thumbnail_url / walk_url / sit_url` เป็น null ไปก่อน (prototype วาดด้วยโค้ด ไม่มีไฟล์จริง ยกเว้น hair `thai`)
- `GET outfit` → `outfits.prototype_start` ใน data file
- `GET outfit/default` → `outfits.default`
- `PUT outfit` → echo body กลับ + `baked` ปลอม
