# TanStack Query Migration — สถานะและแนวทาง

> อัปเดตล่าสุด: 2026-07-04 — migrate เสร็จ 20 components + 2 shared hooks
> Library: `@tanstack/react-query` v5 · Provider อยู่ใน `components/providers.tsx` (global `retry: 1`)

## กติกาหลัก (สำหรับโค้ดใหม่ทุกตัว)

1. **หน้าใหม่/ฟีเจอร์ใหม่ต้องใช้ `useQuery` เสมอ** สำหรับการโหลดข้อมูลแบบ request/response — ห้ามเขียน useEffect + useState + fetch เองอีก
2. **queryFn ใช้ function จาก `lib/api/*` เดิมได้เลย** (authFetch จัดการ token/401 ให้แล้ว) — เช็ค envelope แล้ว `throw` เมื่อ status ไม่ใช่ 200 เพื่อให้ react-query รู้ว่า error
3. **Query key convention**: `["<resource>", params]` โดย params เป็น object ที่ส่งให้ API ตรงๆ เช่น `["user-workspaces", { search, sort_by, page, limit, tab }]`
4. **หลัง mutation ให้ `invalidateQueries` ด้วย key prefix** เช่น `queryClient.invalidateQueries({ queryKey: ["user-workspaces"] })` — ถ้าอยากให้ UI ตอบสนองทันทีค่อย `setQueryData` แบบ optimistic ก่อนแล้ว invalidate ตาม
5. **Polling**: ใช้ `refetchInterval` แทน setInterval (pause อัตโนมัติตอน tab hidden ซึ่งตรงกับ pattern `visibilityState` เดิม)

## Query keys ที่ใช้อยู่

| Key | Endpoint | ใช้ที่ |
|---|---|---|
| `["user-workspaces", params]` | GET /api/user/workspaces | hero-user-workspace |
| `["workspace-templates"]` | GET /api/user/workspace-templates | create-workspace-modal (space-builder) |
| `["user-avatars"]` (staleTime 5 นาที) | GET /api/user/avatars | `hooks/use-user-avatars.ts` → change-character-modal |
| `["workspace-members", workspaceId]` | GET /api/user/workspaces/:id/members | `hooks/use-workspace-members.ts` → manage-members, invite-member, chat panels (5 จุด) |
| `["profile"]` (no focus refetch) | GET /api/user/me | hero-profile |
| `["admin-online"]` (poll 30s + SSE patch) | GET /api/admin/presence/all | hero-admin-online |
| `["admin-avatars", params]` | GET /api/admin/avatars | hero-avatar-management |
| `["admin-objects", params]` | GET /api/admin/objects | hero-object-management |
| `["admin-map-templates", params]` | GET /api/admin/map-templates | hero-map-management, editor-build-workspace-modal, manage-floor-modal (**cache แชร์กัน**) |
| `["admin-map-template-categories"]` (staleTime 5 นาที) | GET /api/admin/map-template-categories | hero-map-management |
| `["admin-workspaces", params]` | GET /api/admin/workspaces | hero-workspace-management |
| `["workspace-version-history", mode, wsId, refreshKey]` | getVersionHistory (admin/user) | history-panel |
| `["map-versions", mode, mapId, refreshKey]` | listMapVersions (admin/user) | map-version-panel |

Shared hooks: `hooks/use-user-avatars.ts`, `hooks/use-workspace-members.ts` (export `workspaceMembersQueryKey(id)` ไว้ invalidate)

## Pattern และ gotcha ที่เจอมาแล้ว

- **`isPending` = โชว์ skeleton เฉพาะ key ที่ยังไม่มี cache** — สลับ tab/page กลับมาอันเดิมจะโชว์ข้อมูลทันทีแล้ว refetch เบื้องหลัง (stale-while-revalidate)
- **ESLint `react-hooks/set-state-in-effect` เป็น error** — ถ้าต้อง setState ตอนข้อมูลจาก query มาถึง (preselect, restore draft, auto-select) ให้ใช้ **set-state-during-render + boolean guard**:
  ```tsx
  const [processed, setProcessed] = useState(false)
  if (data && !processed) {
    setProcessed(true)
    // setState อื่นๆ ตรงนี้ได้ (ห้ามเขียน ref!)
  }
  ```
  ตัวอย่างจริง: create-group-modal, hero-avatar-management, hero-profile, create-workspace-modal
- **ESLint `react-hooks/refs` ห้ามเขียน/อ่าน ref ระหว่าง render** — ถ้า pattern เดิมใช้ ref เก็บ "original data" ให้ใช้ค่าจาก query cache แทน (ดู hero-profile: ตัด originalRef ทิ้ง ใช้ `profile` + `setQueryData` ตอน save) หรือ seed ref จาก sessionStorage ใน useRef initializer
- **`enabled:` สำหรับ fetch แบบมีเงื่อนไข** — modal ที่โหลดเมื่อเปิด step/view เช่น `enabled: step === 2` (editor-build-workspace-modal)
- **`refreshKey` prop เดิมยังใช้ได้** — เอาไปใส่ใน query key แทนการเป็น effect dep (history-panel, map-version-panel)
- **SSE/WS realtime + query อยู่ร่วมกันได้** — ให้ event patch cache ผ่าน `queryClient.setQueryData` (ดู hero-admin-online)
- **Turbopack dev gotcha**: แก้ไฟล์เดิมหลายสเต็ปติดกันอาจทำให้ dev server เสิร์ฟ chunk ค้าง — อาการคือหน้าโชว์ SSR shell แช่แข็ง ไม่ hydrate ไม่มี error ไม่มี API call → **restart dev server** (เช็คได้ด้วย `Object.keys(el).some(k => k.startsWith("__react"))`)

## สิ่งที่**ห้าม** migrate เป็น react-query

- **Zustand realtime stores**: `chat-store` (optimistic ผ่าน WS), `vo-session-store`, `vo-prefetch-store` — เป็น WS state ไม่ใช่ request cache
- **VO flow ทั้งหมด**: hero-virtual-office, hero-workspace-loading (phased prefetch → เก็บใน store → เข้า VO)
- **Workspace editor internals** (hero-workspace-editor): phased loading (`listAllActiveObjects` palette, `listMaps`), lock heartbeat 60s, autosave 5 นาที, external-update poll — เป็น imperative orchestration ผูกกับ Phaser/engine state
- **Chat initial load** (`listConversations`, `getUnreadCounts`) — hydrate เข้า chat-store ที่ WS อัปเดตทับ ถ้าย้ายจะมี source of truth ชนกัน
- **Mutation ใน event handler** (submit/click) — เรียก lib/api ตรงๆ ต่อได้ (จะยกระดับเป็น `useMutation` ก็ได้แต่ไม่บังคับ)

## งานที่ยังเหลือ (ถ้าจะเก็บให้ครบ 100%)

| ไฟล์ | งาน | ความยาก |
|---|---|---|
| `views/chat/components/conversation-media-panel.tsx` | `["conversation-media", conversationId, tab]` — attachments/links/pins/threads ต่อ tab | ง่าย |
| `views/admin/workspace-management/components/workspace-version-modal.tsx` | ใช้ key `["workspace-version-history", ...]` ร่วมกับ history-panel ได้เลย | ง่าย |
| (ก้ำกึ่ง) hero-accept-invite | แยก useQuery(check) + mutation(accept) — ได้กำไรน้อย | กลาง |
| (ก้ำกึ่ง) avatar-preview-modal | fetch โซฟาเข้า Phaser preview — พันกับ engine preload | กลาง |

## เรื่องอื่นที่ทำไปในรอบเดียวกัน (2026-07-04)

- **play-test ถูกลบแล้ว** (app/play-test, app/play-test-v2, views ทั้งคู่ + เมนู sidebar) — แต่ `components/play-test/` (Phaser wrapper) **ยังอยู่** เพราะ avatar-preview-modal ใช้
- **Avatar spritesheet = 1000×1000 เท่านั้น** (มติทีม) — validate ทั้ง FE (`avatar-validation.ts`) และ BE (`validateSpritesheetDimensions` ใน avatar_service.go)
- **Spritesheet upload ใช้ S3 key ใหม่ทุกครั้ง** (`avatars/{id}/{type}_{uuid}.png` + ลบตัวเก่า) — แก้บัค replace ท่านั่งแล้วเจอ cache รูปเก่า
- **Avatar audit log fix**: migration `57_avatar_audit_performed_by_text.sql` (performed_by uuid→text) + `writeAvatarAudit` ใช้ SAVEPOINT — แก้บัค admin ที่ login ด้วย Google สร้าง avatar ไม่ได้ · **บทเรียน pgx**: best-effort insert ใน tx ต้องใช้ savepoint ไม่งั้น statement ที่ fail จะพาทั้ง tx rollback
- Dev DB seed logins: `member-a@zyra.test` / `admin-a@zyra.test` (รหัส `Password@123`)
- Test ที่ fail ค้างอยู่ 2 ตัวใน `__tests__/chat-ws.test.ts` เป็นของเดิมก่อน migration (มี task แยกไว้แล้ว)
