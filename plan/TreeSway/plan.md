# Tree Sway — ต้นไม้แกว่งตามลมใน Virtual Office

> **สถานะ:** prototype ใช้กับต้นเดียว (`Bigtree 5`) · โค้ดอยู่บน `zyra-app@feat/tree-sway` **ยังไม่ commit** · tsc/eslint/vitest ผ่าน · ยังไม่ได้ live-test บน dev
> **repo:** zyra-app เท่านั้น (ไม่แตะ API / DB / WS) · **อัปเดตล่าสุด:** 2026-09-23
> **ทำต่อ:** ดู [§6 งานที่เหลือ](#6-งานที่เหลือ--คนทำต่อเริ่มตรงไหน) และ [`progress.md`](progress.md)

---

## 1. What

ต้นไม้ใน Virtual Office (PixiJS engine) แกว่งเหมือนโดนลม:

- **ใบ/ทรงพุ่ม** แกว่งมากสุดที่ยอด
- **ลำต้น** เอนตามนิดหน่อย **โคนติดพื้น** ไม่ขยับ — โค้งต่อเนื่อง ไม่มีรอยหักตรงรอยต่อ
- ขยับแบบ **pixel art** — เลื่อนทีละ pixel เต็มของรูป, เดินเป็นเฟรม 8 fps ไม่ลื่นแบบ smooth
- **ความแรงตามลมจริง** ของ office (`wind_kph` / `gust_kph` จาก Environment SC-ENV-01) — ลมแรงแกว่งเยอะ ลมสงบใบไหวนิดๆ

ขอบเขตตอนนี้: **test กับต้นเดียว** คือ object ชื่อ `Bigtree 5` ใน `tb_object` (เลือกด้วยชื่อ — hardcode ชั่วคราว)

---

## 2. ทำงานยังไง

### 2.1 การวาด — Mesh แทน sprite

`zyra-app/zyra-engine/pixi-game/tree-sway.ts` → class `TreeSway`

- piece sprite เดิมของต้นไม้ **ยังอยู่ที่เดิม** (hit-test, outline, depth sort ใช้ตัวนี้ต่อ) แต่ตั้ง `renderable = false`
- มี `Mesh` วางคู่กัน วาด texture เดียวกันแทน — sync ทุกเฟรม: parent (รวมตอนถูกยกเข้า spotlight layer), position, scale, zIndex, visible, alpha, tint
- geometry = **1 quad ต่อ 1 แถว pixel ของ texture** (ไม่ share vertex) → แต่ละแถวเลื่อนอิสระได้
- ทุกแถวเลื่อน `Math.round(...)` = จำนวน pixel เต็ม → ขอบเป็นขั้นบันได ไม่มี pixel โดนบีบ/เอียง
- คำนวณใหม่เฉพาะตอนเฟรมเปลี่ยน (`SWAY_FPS = 8`) และ update buffer เฉพาะเมื่อมีแถวเปลี่ยนจริง

น้ำหนักการเลื่อนต่อแถว (`v` = 0 บนสุด … 1 ล่างสุด):

```
v >= cutoff (ลำต้น):  trunkSway * smooth((1 - v) / (1 - cutoff))        → 0 ที่โคน, trunkSway ที่รอยต่อ
v <  cutoff (ใบ):     trunkSway + (1 - trunkSway) * smooth((cutoff - v) / cutoff)  → 1 ที่ยอด
```

### 2.2 ความแรงลม

`zyra-app/lib/tree-wind.ts` → `treeWindFor()` แปลง snapshot สภาพอากาศเป็น `{ strength, gustStrength }` (0..1)

| `wind_kph` | ระดับ (Beaufort) | strength |
|---|---|---|
| ไม่มีข้อมูล / ฟีเจอร์ปิด | — | `null` → engine ใช้ default **0.35** (แกว่งเบาๆ) |
| 0–5 | ลมสงบ | 0.15 (ไม่นิ่งสนิท — ต้นนิ่งดูเหมือนภาพค้าง) |
| 5–20 | ลมอ่อน | 0.15 → 0.4 |
| 20–39 | ปานกลาง–แรง | 0.4 → 0.8 |
| 39–50+ | แรงมาก/พายุ | 0.8 → 1.0 (cap ที่ 50) |

- ระหว่างช่วง interpolate ต่อเนื่อง
- `condition === "windy"` → strength ขั้นต่ำ **0.7** (ให้ตรงกับ gif ลม/ใบไม้ปลิวที่แผนที่วาดอยู่แล้ว + ใช้เทสใน debug ได้)
- `gustStrength = max(strength, strengthOf(gust_kph))` — engine ใช้ทำจังหวะ "ลมกระโชก" แรงขึ้นเป็นพักๆ
- gate เดียวกับ weather effect อื่น (`shouldRenderWeatherEffects`): env flag, `feature_enabled`, `location_enabled`, `enabled.weather`, และ setting ส่วนตัว `env_weather_effects` — ปิดอันไหน → `null` → แกว่ง default

strength ใน engine ขับ 3 ค่า (ที่ 0.35 จะได้ค่าเดิมที่จูนมือไว้):

| ค่า | สูตร | ที่ 0.35 | ที่ 1.0 |
|---|---|---|---|
| amplitude (สัดส่วนความกว้างรูป ที่ยอด) | `0.1 * s` | 0.035 | 0.1 |
| speed | `0.6 + 1.2 * s` | ~1.0 | 1.8 |
| trunkSway | `0.1 + 0.3 * s` | ~0.2 | 0.4 |

- เปลี่ยนลม → ค่อยๆ ไล่ไปหาค่าใหม่ (`WIND_EASE_S = 3` วินาที) ไม่กระโดด
- เวลาเดินด้วย clock สะสม `dt * speed` → เปลี่ยน speed แล้ว phase ไม่กระตุก

วัดใน headless Chromium (Metal) กับรูปกว้าง 64px — ยอดแกว่ง: 0.15 → ±1px · 0.35 → −3..+2px · 0.7 → ±5px · 1.0 → ±7px (รูปกว้างกว่านี้ได้มากกว่าตามสัดส่วน)

### 2.3 Data flow

```
hero-virtual-office.tsx  (useEffect: environment, environmentEnabled, personalWeather, sceneReady)
  └─ treeWindFor(...)                       lib/tree-wind.ts
      └─ playTestRef.setTreeWind(wind)      components/game-canvas/pixi-canvas.tsx
          └─ PixiGameScene.setTreeWind()    zyra-engine/pixi-game/scene.ts  (เก็บ this.treeWind)
              └─ _update → _updateTreeSway(nowMs) → TreeSway.update(nowMs, this.treeWind)
```

การสร้าง `TreeSway`: ใน `_importMapData` ของ `scene.ts` หลัง `addChild(piece.sprite)` — ถ้า `tile.label` ตรง `TREE_SWAY_NAME_RE` (`/^bigtree 5(\s|$)/i`, ชื่อที่มี "— variant" ต่อท้ายก็ติด) → `new TreeSway(piece.sprite)`
ลบ object / import map ใหม่ → sprite หลุด parent → `_updateTreeSway` เห็น `!alive` แล้ว `destroy()` mesh ทิ้ง

---

## 3. ไฟล์ที่แก้ (zyra-app, branch `feat/tree-sway` แตกจาก `develop`)

| ไฟล์ | เปลี่ยนอะไร |
|---|---|
| `zyra-engine/pixi-game/tree-sway.ts` | **ใหม่** — `TreeSway` (mesh, pixel step, wind) |
| `lib/tree-wind.ts` | **ใหม่** — `windStrengthForKph`, `treeWindFor` |
| `__tests__/tree-wind.test.ts` | **ใหม่** — 9 cases |
| `zyra-engine/pixi-game/scene.ts` | `TREE_SWAY_NAME_RE`, `treeSways`, `treeWind`, `setTreeWind()`, `_updateTreeSway()`, สร้าง `TreeSway` ใน `_importMapData` |
| `zyra-engine/types.ts` | type `TreeWind`, `PlayTestHandle.setTreeWind?` |
| `components/game-canvas/pixi-canvas.tsx` | ส่ง `setTreeWind` ผ่าน imperative handle |
| `views/user/virtual-office/hero-virtual-office.tsx` | useEffect push ค่าลมเข้า scene |

ไม่แก้ Phaser engine (play-test/editor) — ต้นไม้ **ไม่แกว่ง** ในหน้า play-test/editor

---

## 4. ปรับจูน (ค่าอยู่บนหัว `tree-sway.ts`)

| อยากได้ | แก้ |
|---|---|
| ลำต้นขยับ/ใบนิ่ง ผิดตำแหน่ง | `cutoff` (default `0.62`, 0 = บนสุด) — ใบล่างไม่ขยับ → เพิ่ม · ลำต้นแกว่งเยอะ → ลด |
| แกว่งแรง/เบาทั้งหมด | `amplitudeAt` |
| ลำต้นเอนมาก/น้อย | `trunkSwayAt` |
| กระตุกมาก/ลื่นขึ้น | `SWAY_FPS` (6 = กระตุกกว่า, 10–12 = ลื่นขึ้น) |
| ลมปกติ (ไม่มีข้อมูล) แรงแค่ไหน | `DEFAULT_WIND` |
| ตอบสนองลมเปลี่ยนเร็ว/ช้า | `WIND_EASE_S` |
| เกณฑ์ km/h → strength | `BANDS`, `WINDY_MIN_STRENGTH` ใน `lib/tree-wind.ts` (+ แก้ test) |

---

## 5. บทเรียน / กับดัก (อ่านก่อนแก้ render)

1. **อย่ากลับไปใช้ custom `Filter`** — รอบแรกทำเป็น shader filter แล้วเจอ 2 ปัญหา:
   - `PixiJS Error: Could not initialize shader` — Pixi คอมไพล์ vertex เป็น `highp`, fragment เป็น `mediump`; uniform ที่ประกาศทั้ง 2 stage (`uInputSize`) precision ไม่ตรง → link fail → sprite ไม่ถูกวาด (ต้นไม้หาย)
   - แก้ precision แล้ว ในแอปจริงต้นไม้ถูกวาดเป็น **รูปเล็กกลับหัว** ผิดตำแหน่ง — repro ใน headless Chromium (ทั้ง SwiftShader และ Metal) ไม่ขึ้น หาสาเหตุไม่เจอ → เปลี่ยนเป็น Mesh ซึ่งวาดผ่าน renderer ปกติ ไม่มี filter pass
2. **อย่าใช้ `MeshPlane` แบบ vertex share กัน** ถ้าต้องการ pixel look — การ interpolate ระหว่างแถวทำให้ pixel เอียง/บีบ (ดู smooth ไม่ใช่ pixel) จึงเปลี่ยนเป็น quad แยกต่อแถว
3. Mesh ต้อง **ตาม parent ของ sprite** เสมอ — scene ย้าย piece sprite เข้า/ออก `_spotlightFg` (`_liftZoneObjects` / `_lowerLiftedObjects`)
4. ค่าลม **ไม่ realtime**: server push snapshot เฉพาะตอน "สิ่งที่วาดได้" เปลี่ยน (ออกแบบไว้ใน SC-ENV-01) → `wind_kph` เป็นค่าตอนเข้า office หรือตอนเปิดแผง weather ล่าสุด

---

## 6. งานที่เหลือ / คนทำต่อเริ่มตรงไหน

### 6.1 ปิดงาน prototype นี้ (ทำก่อน)

1. `git checkout feat/tree-sway` ใน zyra-app — งานยัง **ไม่ commit**
2. live-test บน local/dev: วาง `Bigtree 5` ในแผนที่ → เข้า VO → เช็ค
   - ต้นไม้แสดงปกติ ไม่มีรูปซ้อน/กลับหัว, คลิก/hover/outline ยังทำงาน, เดินผ่านหน้า–หลังแล้ว depth ถูก
   - เปิด debug → เลือก weather `windy` → ต้นไม้ค่อยๆ แกว่งแรงขึ้นใน ~3 วิ, เปลี่ยนกลับ → ค่อยๆ เบาลง
   - ปิด "weather effects" ใน setting ส่วนตัว → กลับเป็นแกว่ง default
   - zone spotlight ที่มีต้นไม้อยู่ข้างใน → ต้นไม้ยังแกว่งและไม่หาย
3. เช็คชื่อใน DB ว่าขึ้นต้น `Bigtree 5` จริง (`select name from tb_object where name ilike '%bigtree%'`) — ไม่ตรงให้แก้ `TREE_SWAY_NAME_RE`
4. จูน `cutoff` ให้พอดีรูปจริง (default 0.62 ตั้งจากภาพหน้าจอ ไม่ได้วัดจากไฟล์)
5. commit + PR เข้า `develop` ตาม `rules/17-git-branch-workflow.md`

### 6.2 ขยายไปหลายต้น (พักไว้ — ยังไม่เริ่ม, ต้องทำ spec ก่อน)

ตอนนี้เลือกต้นด้วยชื่อ + `cutoff` ค่าเดียว ใช้ไม่ได้กับต้นไม้หลายแบบ (สูง/เตี้ย/ต้นในกระถาง) **ข้อเสนอที่คุยกันแล้ว (ยังไม่อนุมัติ):** ตั้งค่ารายต้นในหน้า admin

- field ต่อ object: เปิด/ปิด sway · ตำแหน่งเส้นแบ่งลำต้น (`cutoff` 0..1) · แรงลม (เบา/กลาง/แรง → ตัวคูณ amplitude)
- admin UI: toggle + **ลากเส้นแนวนอนบนรูป** กำหนดรอยต่อใบ/ลำต้น (หรือขอบกระถาง) + preview แกว่งจริง
- engine: แทน `TREE_SWAY_NAME_RE` ด้วยค่าจาก object (ต้องส่งผ่าน `buildDbTiles` → `SpriteTile` → `_importMapData`)
- กระทบ: `zyra-api` (migration + model + response ของ `/api/objects/all`) และ `zyra-app` (admin object-management + engine) → ต้องมี API/DB plan ตาม AGENTS.md Phase D ก่อนเขียนโค้ด
- ทางเลือกที่พิจารณาแล้วไม่เลือก: ใช้ชื่อ (ต้องแก้โค้ดทุกต้น), ใช้ `nature_type` อย่างเดียว (ต้นประเภทเดียวกันสูงไม่เท่ากัน, ต้นกระถางอาจไม่ใช่ nature), หา cutoff จากสีในรูปอัตโนมัติ (เดาผิดบ่อยกับ pixel art)
- ที่มีอยู่แล้วให้ reuse ได้: `tb_object.nature_type` (migration 105), `tb_object_animation.base_intensity_multiplier` (migration 106 — ยังไม่มี UI)

### 6.3 ข้อควรระวังตอนมีหลายต้น

- mesh ละ ~(ความสูงรูป × 4) vertex → Pixi ไม่ batch mesh ใหญ่ = 1 draw call ต่อต้น — ถ้าวางเป็นร้อยต้นให้วัด FPS; ลดได้โดยรวมแถวที่ shift เท่ากันเป็น quad เดียว หรือใช้แถวละ 2px
- ถ้าต้องการลมอัปเดตระหว่างอยู่ใน office → ต้องให้ server push เมื่อ wind เปลี่ยน หรือ refresh environment เป็นระยะ (แตะ SC-ENV-01 — คุยกับเจ้าของฟีเจอร์ก่อน)
