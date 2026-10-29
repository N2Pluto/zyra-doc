# Accessory Management (Admin) — Task Breakdown

> **สถานะ:** v1.0 · 2026-10-22 ทำครบทุกแถวและ merge เข้า develop แล้ว — api #179–#184 · ws #86 · app #638–#643 · QA-1 #644 (merge แล้ว ยังไม่ได้รันบน dev) · QA-2 manual ยังไม่ทำ · 1 แถว = 1 PR · branch แตกจาก `develop` (`feat/<name>`) ตาม [17-git-branch-workflow.md](../../../.claude/rules/17-git-branch-workflow.md)
> **อ้างอิง:** [technical-design.md](technical-design.md) · [test-plan.md](test-plan.md) (test ID ในตาราง) · [ux-ui-plan.md](ux-ui-plan.md) · POC [poc/accessory-admin-poc.html](poc/accessory-admin-poc.html)
> **ประมาณการ:** วัน-คน ของ dev 1 คน ไม่รวมรอ review · รวมทั้งหมด ≈ 17.5 วัน (api 7 · ws 0.5 · app 9 · E2E/QA 1) · ทำ 2 คนขนานกัน ≈ 3 สัปดาห์

---

## 0. ต้องตอบก่อนเริ่ม (blocker)

| # | เรื่อง | บล็อกงาน | technical-design |
|---|---|---|---|
| D1 | ขนาดชีท 48 vs 64 px | API-2, APP-1 | §12 |
| D2 | พื้นไม่โปร่งใส = error หรือ warning | API-2, APP-4 | §12 |
| D3 | สถานะเริ่มต้นตอนสร้าง | API-3, APP-4 | §12 |
| D4 | 18 หมวด → ขยาย data contract ฝั่ง member | ไม่บล็อก admin · บล็อก member v2 | §2 |
| ~~D5~~ ✅ | ~~Hair / Facial Hair ต้องมีชีทนั่งไหม~~ **ตอบแล้ว (Ten 2026-10-22):** บังคับชีทนั่ง `hair`, `facial_hair`, `shoes` เพิ่ม — ตรงกับไฟล์ศิลปิน (ผม 5 · หนวด 3 · รองเท้า 2 มีชีทนั่งครบ) · zyra-api#187 / zyra-app#646 | API-2 (`CATEGORY_REQUIRES_SIT`) | §2 |
| D6 | สร้าง `tb_avatar_part` ใน PR ไหน (AvatarCustomization A1 หรือ API-1) | API-1 | §4.1 |

งานที่เริ่มได้ทันทีโดยไม่รอ: **APP-1** (ยก renderer จาก POC — ค่าขนาดเป็น constant) และ **APP-2** (หน้า shell + category panel มีโค้ดอยู่แล้วใน branch `feat/accessory-category-panel`)

---

## 1. zyra-api

| ID | PR title | ทำอะไร | Test (test-plan) | ขึ้นกับ | วัน |
|---|---|---|---|---|---|
| API-1 | `feat(api): avatar part schema for admin accessories` | migration `118_avatar_parts_admin.sql` + `.down.sql` · **embedded DDL ใน `internal/database/postgres.go`** (ห้ามลืม) · model `AvatarPart`, `AvatarPartVariant`, `ResetJob` · constants 18 หมวด / layer / requires-sit | migration up/down บน dev DB · AC-T-04 parity (Go ฝั่ง) | D6 | 1 |
| API-2 | `feat(api): validate accessory sprite sheets` | `avatar_part_validate.go`: magic bytes, ≤ 2 MB, 192×192, alpha, โปร่งใส, scan สี key, ตาราง required sheets · sentinel errors ทั้งชุด | AC-U-01~12, AC-U-13~28 | API-1, D1, D2, D5 | 1 |
| API-3 | `feat(api): avatar part service crud + list` | service Create/Update/Get/List/CountByCategory/SetStatus · upload R2 + rollback · thumbnail ฝั่ง server · audit · user count แบบ containment query | AC-U-29~42, AC-U-44~45 | API-2, D3 | 2 |
| API-4 | `feat(api): admin avatar-parts routes` | handler + route ใต้ admin + `RequirePermission(PermAdminAvatarManage)` · map error code ตาม technical-design §5 · envelope `model.APIResponse` | AC-A-01~13, AC-A-18 | API-3 | 1 |
| API-5 | `feat(api): delete accessory with async user reset` | DELETE + confirm_name (> 100) · `tb_avatar_reset_job` · worker batch 100 + `SKIP LOCKED` + resume ตอน start · bake ต่อคน (dedupe hash) · `PublishOutfitReset` · progress endpoint | AC-U-43, 46, 50~57 · AC-A-14~17 | API-4, AvatarCustomization bake (A2) | 1.5 |
| API-6 | `feat(api): daily hard-delete ticker for avatar parts` | ticker 24 ชม. + `pg_try_advisory_lock` · `DeleteByPrefix` R2 · ลบแถว · ครอบ `tb_avatar` เดิมด้วย (แทน `cmd/avatar-cleanup` ที่ไม่เคยถูกรัน) | AC-U-47~49 | API-1 | 0.5 |

> **ตามหลัง (2026-10-22):** zyra-api#185 + zyra-ws#87 — ชุดแยกต่อ workspace ตามมติ C-14 (migration 119, นับคนไม่ซ้ำ, reset ต่อแถว, `outfit_reset` มี `workspace_id`)
> API-5 ต้องมี bake ของ AvatarCustomization (A2) ก่อน · ถ้า A2 ยังไม่มา ให้ทำ API-5 แบบ "ถอด slot + ล้าง `bake_hash`" แล้วปล่อยให้ lazy re-bake ตอน `GET /me/outfit` (ผู้ใช้ online จะเห็นเปลี่ยนเมื่อโหลดชุดใหม่ ซึ่ง `outfit_reset` สั่งอยู่แล้ว)

## 2. zyra-ws

| ID | PR title | ทำอะไร | Test | ขึ้นกับ | วัน |
|---|---|---|---|---|---|
| WS-1 | `feat(ws): relay outfit_reset to the user's sockets` | อ่าน `outfit_reset_user_id` จาก notify envelope · `MsgOutfitReset` · ส่งทุก socket ของ user ทุก workspace | AC-U-58~60 | API-5 (field ใน envelope) | 0.5 |

> อ่านโค้ด ws จาก `origin/develop` ไม่ใช่ branch ที่ checkout อยู่ (checkout ในเครื่อง stale)

## 3. zyra-app

| ID | PR title | ทำอะไร | Test | ขึ้นกับ | วัน |
|---|---|---|---|---|---|
| APP-1 | `feat(app): avatar part renderer lib` | ยกจาก POC เป็น `lib/avatar-part/{render,shade,chair,constants,validate}.ts` · base sheet ใน `public/avatar/base/` | AC-T-04~09, AC-T-11~19 | — (เริ่มได้เลย) | 1.5 |
| APP-2 | `feat(app): accessory management shell + category panel` | route + hero + sidebar (WandSparkles) + i18n namespace + `messages-scope` + category panel + empty state · icon 18 หมวดเข้า `components/ui/icon.tsx` · **หยิบโค้ดจาก branch `feat/accessory-category-panel` (PR #636 ที่ปิดไว้)** แล้วเปลี่ยน icon เป็นของ Figma | AC-C-01~03 · AC-R-01, AC-R-03 | — | 1 |
| APP-3 | `feat(app): accessory list, filter, pagination` | `lib/api/avatar-parts.ts` · list panel · card (ตัวละครใส่ชิ้น — ใช้ APP-1) · filter submenu · search · pagination 20 · count จาก `/category-counts` | AC-T-01~03 · AC-M-01~05 | APP-1, APP-2, API-4 | 1.5 |
| APP-4 | `feat(app): add/edit accessory for regular categories` | form add/view/edit · dropzone walk (+sit) · Save gating · preview Idle/Walking/Sitting + หมุน + เก้าอี้ (`PREVIEW_CHAIR_OBJECT_ID`) · แถว 12 สี + Shade slider · toast/inline error | AC-T-10 · AC-C-04~05, AC-C-07 · AC-M-07~11, 14 | APP-3 | 2 |
| APP-5 | `feat(app): special costume variants + expiration` | ตาราง variant (Colour / Walking / Sitting) · colour picker (node `7488:28727`) · generate ชื่อสี · radio + date range | AC-M-06 | APP-4 | 1.5 |
| APP-6 | `feat(app): hide and delete accessory` | toggle status · delete dialog 3 แบบ · poll progress reset job · VO รับ `outfit_reset` แล้วโหลดชุดใหม่ | AC-C-06 · AC-M-12~13 · AC-R-04 | APP-4, API-5, WS-1 | 1.5 |

## 4. E2E + QA

| ID | PR / งาน | ทำอะไร | Test | ขึ้นกับ | วัน |
|---|---|---|---|---|---|
| QA-1 | `test(app): accessory management e2e` | Playwright บน dev ด้วย fixture จาก `demo file/custom avatar` | AC-E-01~09 | ทุกแถวข้างบน | 0.5 |
| QA-2 | manual QA | checklist AC-M-01~16 · กฎ 80% ต่อการ์ด ClickUp ก่อนขอเปลี่ยนเป็น Completed | AC-M-* | deploy dev | 0.5 |

---

## 5. ลำดับและงานที่ทำขนานกันได้

```
สัปดาห์ 1   API-1 → API-2 → API-3            APP-1 ─┐
                                           APP-2 ─┴→ (รอ API-4)
สัปดาห์ 2   API-4 → API-5 → WS-1            APP-3 → APP-4
            API-6 (เมื่อไหร่ก็ได้หลัง API-1)
สัปดาห์ 3                                  APP-5 → APP-6 → QA-1 → QA-2
```

- สาย api กับสาย app ทำคนละคนได้ตั้งแต่วันแรก — APP-1/APP-2 ไม่ต้องรอ backend
- APP-3 ใช้ mock ของ `lib/api/avatar-parts.ts` ได้ก่อน API-4 merge (`vi.mock` ในเทส · ฝั่ง UI ใช้ fixture JSON ชั่วคราว ห้ามค้างใน PR สุดท้าย)
- **ลำดับ merge เข้า develop:** api ก่อน app เสมอในคู่ที่พึ่งกัน (API-4 ก่อน APP-3, API-5 + WS-1 ก่อน APP-6)
- develop → main → tag ต้องถาม Ten ทุกครั้ง

## 6. Definition of Done (ต่อ PR)

- [ ] โค้ดผ่าน `npx tsc --noEmit` · `npm run lint` · prettier (app) / `go test ./...` · `go vet` (api, ws)
- [ ] test ID ในแถวนั้นมีครบและผ่าน · coverage ตาม test-plan
- [ ] UI ตรง [ux-ui-plan.md](ux-ui-plan.md) (เทียบ Figma ที่ 1440 × 1024) · ไม่มี inline style · icon ตามกฎ 12
- [ ] ตารางใหม่อยู่ทั้ง migration และ embedded DDL (API-1)
- [ ] PR description มี what + why + ระดับที่ verify (build เขียว แยกจาก live-test บน dev)
- [ ] อัปเดต [progress.md](progress.md) entry ใหม่ไว้บนสุด
