# zyra-app Structural Refactor — Phase 1 Analysis

> วันที่: 2026-08-06 · Branch: `refactor/project-structure` (แตกจาก `main`)
> เป้าหมาย: ลดขนาดไฟล์ยักษ์ / จัดโครงสร้างให้ชัดเจน โดย **No Behavior Change**

## Baseline (จุดเทียบก่อนแก้)

| Check | ผล |
|---|---|
| `npx tsc --noEmit` | ✅ ผ่าน |
| `npx vitest run` | ✅ 35 files / 653 passed, 3 skipped |
| `npm run lint` | ✅ ไม่มี warning |

ทุก step ของการ refactor ต้องรัน 3 อย่างนี้ผ่านก่อน commit

## Architecture Summary

```
app/            (40 files)  — App Router pages, บางเป็น thin wrapper ชี้ไป views/
views/          (281 files) — feature modules: views/<feature>/hero-*.tsx + components/
components/     (42 files)  — ui/ (shadcn — ห้ามใช้เพิ่มตาม rule 08), admin/, play-test/, game-canvas/
lib/            (58 files)  — lib/api/* (API clients + WS), auth, utils, toast
stores/         (9 files)   — zustand stores (user, chat, vo-session)
hooks/          (8 files)   — shared hooks
zyra-engine/    (32 files)  — pixi-game/ (production VO engine), canvas-game/ (legacy), systems/, scenes/
i18n/, messages/            — next-intl
```

Dependency hubs (fan-in สูง): `lib/toast.tsx` (52), `lib/api/workspaces.ts` (43), `lib/utils.ts` (42), `zyra-engine/types.ts` (35), `lib/api/objects.ts` (35), `lib/api/chat.ts` (32)

ไฟล์ยักษ์ส่วนใหญ่ fan-in ต่ำ (ถูก import โดย 1–4 ไฟล์) → แยกไฟล์ได้โดยไม่กระทบวงกว้าง

## ไฟล์เกิน 500 บรรทัด: 53 ไฟล์ (Top 20)

| Lines | File | Risk |
|---|---|---|
| 10,502 | views/user/virtual-office/hero-virtual-office.tsx | 🔴 สูง (WS/movement) แต่มีส่วนปลอดภัย |
| 6,786 | zyra-engine/pixi-game/scene.ts | 🔴 สูงมาก (desync history 8 รอบ) |
| 6,625 | views/admin/workspace-editor/hero-workspace-editor.tsx | 🟠 กลาง-สูง (`eslint-disable exhaustive-deps` ทั้งไฟล์) |
| 3,667 | zyra-engine/canvas-game/scene.ts | 🟡 กลาง (legacy, ไม่มี reconcile) |
| 2,893 | views/user/virtual-office/components/zone-enter-panel.tsx | 🟢 ต่ำ — 22 components แยกง่ายสุด |
| 2,767 | views/admin/workspace-editor/components/map-editor-canvas.tsx | 🟠 กลาง (46 refs ใน draw loop) |
| 1,939 | views/admin/workspace-editor/components/left-panel.tsx | 🟢 ต่ำ (presentational) |
| 1,915 | views/admin/object-management/components/object-composer.tsx | 🟡 กลาง (undo/redo refs) |
| 1,712 | views/admin/object-management/components/object-add-form.tsx | 🟡 กลาง (variants spine) |
| 1,513 | zyra-engine/systems/placement.system.ts | 🟡 |
| 1,417 | views/user/virtual-office/use-meeting-media.ts | 🟠 (LiveKit state) |
| 1,389 | views/user/workspace/hero-user-workspace.tsx | 🟢 ต่ำ — ครึ่งล่างเป็น sub-components อยู่แล้ว |
| 1,361 | components/play-test/gather-scene.ts | 🟡 (Phaser closure ctx) |
| 1,351 | views/admin/map-management/components/map-template-detail-panel.tsx | 🟢-🟡 |
| 1,223 | lib/api/sfu-client.ts | 🟠 (arrow-fn identity = unsubscribe) |
| 1,209 | views/admin/object-management/components/object-preview-canvas.tsx | 🟡 |
| 1,096 | lib/api/workspace-ws.ts | 🟠 (reconnect/clock state) |
| 1,084 | views/admin/object-management/components/konva-canvas.tsx | 🟡 |
| 1,037 | views/admin/workspace-editor/components/editor-build-workspace-modal.tsx | 🟢 |
| 960 | views/chat/components/message-item.tsx | 🟢 |

(อีก 33 ไฟล์อยู่ช่วง 500–960 บรรทัด — ส่วนใหญ่เป็น modal/panel เดี่ยวที่ยอมรับได้)

## Do-Not-Touch Zones (ห้ามแตะใน refactor นี้)

ส่วนเหล่านี้มีประวัติบั๊ก desync/timing ที่ fix เป็น inline guard — การ reorder = เปลี่ยนพฤติกรรม:

1. **pixi-game/scene.ts**: `_updateMovement` (2169–2784), `_emitInputChanged` (6126–6248), reconcile block (5209–5579), sit block (4067–4523), `_mountInput` (1420–1809)
2. **hero-virtual-office.tsx**: WS effect ยักษ์ (1818–3159, subscribe `welcome` 3 ครั้งแบบ order-dependent), Movement V2 outbound (4671–4898), zone-transition effect (7941–8190)
3. **hero-workspace-editor.tsx**: `saveToDb` (2688–3003), writeBuffer shared maps, undo/redo + `suppressUndoPushRef`
4. **sfu-client.ts / workspace-ws.ts**: event-bridge arrow properties (identity ใช้ unsubscribe), reconnect/clock-sync state
5. **gather-scene.ts**: `update()` ordering + `ctx.*Ref.current` live reads

## แผนการ Refactor (ลำดับตาม Risk × Value)

### Phase 2 — Shared Resources (เริ่มก่อน, ปลอดภัยสุด)

| # | งาน | ที่มา → ที่ไป |
|---|---|---|
| 2.1 | Types/constants ที่ฝังในไฟล์ยักษ์ | PZ types+consts (hero-VO 249–352) → `pz-constants.ts`; `MessageInput` consts; `ZoneEnterPanel` `MEETING_EMOJIS` ฯลฯ |
| 2.2 | Pure utils | `zoneAtWorldPoint`, `meetingLeaveMessage`, `activeMentionAt`, `chunkArray`, `formatChatTime`, PZ geometry (`screenToWorld`, `pzTileAt`, `pzInBounds`, `pzResolveFootprint`) |
| 2.3 | ~~Shared hook `useLatestRef`~~ **ยกเลิก** | ลองแล้ว revert: eslint-plugin-react-hooks มองว่า ref จาก custom hook ไม่ stable → warning 7 จุด บังคับแก้ dep array ซึ่งเสี่ยงเปลี่ยน timing — mirror pattern เดิม lint-clean กว่า |
| 2.4 | lib/api แยกไฟล์เล็ก | `ws-binary.ts` (decodeBinMoved), `ws-config.ts`, `sfu-errors.ts`, `sfu-screen-quality.ts`, `livekit-loader.ts` |
| 2.5 | engine geometry dedup | `_convexHull`/capsule ซ้ำ 2 ที่ (pixi 3778–3844, canvas 2805–3046) → `zyra-engine/geometry/hull.ts` |

### Phase 3 — Feature by Feature (เรียงตามความปลอดภัย)

| ลำดับ | Feature | งานหลัก |
|---|---|---|
| 3.1 | **zone-enter-panel.tsx** (2,893) | แยก icons (287 บรรทัด), chat block (~865), screen-share, display cards, toolbar, header → ~7 ไฟล์ เหลือ orchestrator |
| 3.2 | **hero-user-workspace.tsx** (1,389) | ย้าย sub-components ครึ่งล่าง (บรรทัด 635+) ออก verbatim → workspace-card, capacity-modals, leave-modal |
| 3.3 | **chat**: message-item / message-input | แยก `MessageContextMenu`, `AttachmentBlock`, `PendingCard`, consts; ระวัง state machine ของ hover bar |
| 3.4 | **map-template-detail-panel** (1,351) | แยก `Toggle`, `MapTemplateForm` / `MapTemplateView` / shared `MapTemplatePreview` |
| 3.5 | **left-panel** (1,939) | แยก `DetailsTab` / `LayersTab` (props-only), types |
| 3.6 | **object-composer / object-add-form** | แยก constants, `SortableItem`, file-validation, inline confirm modals ×4, `useObjectDraft`, `useComposerHistory` |
| 3.7 | **hero-virtual-office** (เฉพาะส่วนเขียว) | `AskToJoinButton`, `useVOSounds` (audio refs ×9), `useVODebugPanel`, `useVOChatIntegration`, `useAutoAway`, PZ geometry/API helpers — **ไม่แตะ WS effect / Movement V2** |
| 3.8 | **hero-workspace-editor** (เฉพาะส่วนเขียว) | spiral free-tile dedup (ซ้ำ 3 ที่), wall-rule booleans, toolbar/modal JSX islands, `useFloatingPanel` — **ไม่แตะ saveToDb/writeBuffer/undo-redo** |
| 3.9 | **pixi scene.ts (เฉพาะขอบ)** | chat-capsule geometry → `scene-chat-capsule.ts`, debug overlay → `scene-debug-overlay.ts`, dust → `scene-dust.ts`, map import → `scene-map-import.ts` (ตาม template `RemoteMovementCtx` ที่พิสูจน์แล้ว) — **ไม่แตะ movement/reconcile/sit** |
| 3.10 | **gather-scene / canvas-game scene** | free functions ที่ pure + `CameraController`/`PreviewController` |

### Phase 4 — Cleanup

- ลบ dead code ที่ยืนยันแล้ว (เช่น `_drawPlayerOcclusionGhost` no-op ใน canvas scene, `_spotlightFg` dead path)
- unify `comparePaintOrder` 3 ที่ (canvas / findObjectAtTile / generateThumbnail) — ทำท้ายสุดเพราะ risk กลาง
- ตรวจ import ทั้งหมด, tsc, lint, vitest, `next build`

## Progress Log (2026-08-06)

Branch `refactor/project-structure` — ทุก commit ผ่าน tsc / eslint 0 warnings / vitest 658 tests:

| Commit | งาน | ผลลัพธ์ |
|---|---|---|
| 3cdffc3 | sfu-errors.ts | error classes + withTimeout แยกจาก sfu-client |
| e170421 | ws-binary.ts + ws-tab-session.ts | decodeBinMoved + getTabSessionId แยกจาก workspace-ws |
| 292b8e2 | pz-editor-constants + utils + AskToJoinButton | hero-VO 10,502 → 10,321 |
| 1eb54e9 | zone-enter-panel split (6 ไฟล์) | 2,893 → 461 |
| 3abdf5e | hero-user-workspace split (3 ไฟล์) | 1,389 → 657 |
| 26d8d07 | chat message-item/input split (4 ไฟล์) | 960→689, 877→705 |
| ef5cabe | map-template Toggle | 1,351 → 1,321 (scope จำกัดโดย setState-during-render guards) |
| 39ba7f1 | left-panel tabs split (3 ไฟล์) | 1,939 → 755 |
| 9af26c6 | object-composer/add-form (7 ไฟล์) | 1,915→1,850, 1,712→1,505 |
| 36908dc | use-vo-sounds hook | hero-VO → 10,258 |
| 7d4d892 | spiral dedup + wall rules | hero-workspace-editor 6,625 → 6,548 |

| 135017a | gather-scene + canvas-scene pure hoists | 1,361→1,304 / 3,667→3,534 (+hull-geometry.ts) |
| 33e275a | dead code: _EmptyIllustration + occlusion-ghost stub | −44 บรรทัด |

**Phase 4 (2026-08-06):** `next build` ผ่าน, dead code ที่ยืนยันแล้วลบเรียบร้อย, paint-order unification แยกเป็น task ต่างหาก (ควร verify ภาพใน editor)

**Blocked/deferred:**
- 3.9 pixi scene.ts — มี uncommitted WIP จาก session อื่น (`scene.ts`, `pixi-canvas.tsx`, `pixi-game-scene.test.ts`) ห้ามแตะจนกว่าจะ commit
- 2.5 hull dedup ข้าม engine — เหตุผลเดียวกัน
- useLatestRef — ยกเลิกถาวร (eslint stability)
- map-template form/view split — ต้องตัดสินใจเรื่อง setState-during-render guards ก่อน
- hero-VO ส่วนที่เหลือ (WS effect 1,340 บรรทัด, PZ editor ~1,300, Movement V2) — do-not-touch โดยเจตนา

## กติกาการทำงานทุก step

1. ทีละไฟล์ / ทีละ extraction — ไม่ข้าม dependency order
2. ย้ายโค้ด **verbatim** (ไม่ rewrite logic, ไม่เปลี่ยนชื่อ behavior-bearing)
3. รักษา export เดิม (re-export จากที่เดิมถ้ามีคน import อยู่)
4. หลังทุก step: `tsc --noEmit` + `vitest run` + `lint` ต้องผ่าน
5. Commit แยกเป็น step ด้วย `refactor(app): ...` (Conventional Commits)
6. ระวัง closure identity: callback ที่ register เข้า engine/WS ต้องคง dep array เดิม
