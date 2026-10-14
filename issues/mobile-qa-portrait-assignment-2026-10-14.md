# Mobile App — งานแนวตั้ง (Lite) สำหรับส่งต่อให้ dev อีกคน

> **สถานะ:** กลุ่ม A ทำครบ 13 การ์ด — PR #555–#564 merge เข้า `develop` + deploy dev แล้ว (2026-10-14) · รีวิวหลัง merge เจอบัค 5 ข้อ (ยังไม่แก้) · B-10 แก้แล้วรอ PR ดู [ความคืบหน้า](#ความคืบหน้า-2026-10-14) · **วันที่:** 2026-10-14 · **Repo ที่กระทบ:** zyra-app (หลัก), zyra-ws / zyra-api (บางข้อ)
> **ผู้รับผิดชอบ:** ____________ · สายแนวนอน (Spatial) Ten ทำอยู่ — PR [#538](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/538)–[#543](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/543)
> **ที่มา:** สาย 1 ของ [mobile-qa-work-split-by-orientation-2026-10-12.md](mobile-qa-work-split-by-orientation-2026-10-12.md) (32 การ์ด) — step / root cause / วิธีแก้แบบละเอียดอยู่ใน **description ของแต่ละการ์ด ClickUp** แล้ว (อ่านจากโค้ด `develop` @ `26712577` ยังไม่ได้ทดสอบบนเครื่อง — เลขบรรทัดอาจเลื่อน ค้นด้วยชื่อ function)

## สรุปว่าใครทำอะไร

| กลุ่ม | จำนวน | ใครทำ |
|---|---:|---|
| [A. Dev — แก้โค้ดได้เลย](#a-dev--แก้โค้ดได้เลย) | 13 การ์ด (~8 PR) | **dev แนวตั้ง** |
| [B. QA — เทสซ้ำก่อน (น่าจะหายแล้ว)](#b-qa--เทสซ้ำก่อน-น่าจะหายแล้ว) | 13 การ์ด | QA → ถ้ายังเป็น ส่งกลับให้ dev แนวตั้ง |
| [C. รอข้อมูล QA / รอมติ PM](#c-รอข้อมูล-qa--รอมติ-pm) | 6 การ์ด | PM / QA → แล้วค่อยถึง dev แนวตั้ง |
| [D. DevOps](#d-devops) | 1 การ์ด | DevOps |

> รวม 32 การ์ด — B-24 อยู่ทั้ง A (ส่วน client ทำได้เลย) และ C (ส่วน server รอมติ)

## กติกา

- แตก branch จาก `develop` (`fix/<name>` หรือ `feat/<name>`) → PR เข้า `develop` · ห้าม push `develop` / `main` ตรง · ห้ามสร้าง tag
- **ห้ามเปลี่ยน status ใน ClickUp** (สิทธิ์ PM/QA) — comment ในการ์ดได้
- ทุก PR: `npx vitest run` + `npx tsc --noEmit` + `npm run lint` ผ่าน · มี unit test ของ logic ใหม่ · เขียนใน PR ว่าเทสบนเครื่องจริงถึงไหน
- UI ใหม่ใช้ดีไซน์ / component ของ Lite ที่มีอยู่ (`views/user/virtual-office/lite/`, `liteButton` ใน `lite-ui.tsx`)

## ⚠️ ไฟล์ที่ชนกับ PR แนวนอนที่ยังเปิดอยู่

> **อัปเดต 2026-10-14:** #538–#550 merge เข้า `develop` แล้ว (`develop` @ `26fa158`) — ตารางนี้ไม่ block แล้ว แตก branch จาก `develop` ล่าสุดได้เลย · เก็บไว้เป็นประวัติ

PR ของสายแนวนอนยังไม่ merge — ถ้าแตะไฟล์เหล่านี้ **ให้รอ PR นั้น merge ก่อน หรือ rebase หลัง merge**

| ไฟล์ | PR ที่แก้อยู่ | ส่วนที่แก้ | งานแนวตั้งที่แตะไฟล์เดียวกัน |
|---|---|---|---|
| `views/user/virtual-office/lite/lite-shell.tsx` | [#543](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/543) | `endSession` (await `destroySession`), `changeMode` (ตั้ง `leavingRef`) | A1 (B-03 `enter()`, V-12 Leave) |
| `stores/vo-session-store.ts` | [#543](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/543) | `destroySession` คืน Promise | A4 (V-05 — คนละ function) |
| `lib/lite-home.ts` | [#542](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/542) | แยก `buildLitePeople` ออกจาก `buildLiteHome` | A5 (V-07 เพิ่ม `role` ให้ `LitePerson`) |
| `views/user/virtual-office/use-meeting-media.ts` | [#539](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/539) | ปลดล็อกเสียงด้วย `listenForAudioUnlock` | — |

---

## A. Dev — แก้โค้ดได้เลย

ลำดับแนะนำ = ลำดับในตาราง (A1 คุ้มสุด: กลไกเดียวปิดได้ 5 ใบ)

### A1 — ตัวตนของ Lite ในห้อง Meeting · 1 PR ทั้งก้อน

ต้นเหตุร่วม: Lite **ไม่ส่ง heartbeat ห้องทุก 2 นาที** แบบ Spatial → zyra-api ตัดเป็น offline หลัง 3 นาที · Lite **ไม่ leave ห้องเดิม** ตอนเข้าห้องใหม่ · ปิดแอปแล้ว **ไม่มีใครเคลียร์ zone-section**

- [x] **Q-02** ✅ `fix/lite-meeting-heartbeat` ([#558](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/558)) · [ออกจาก Meeting 8 แล้วไม่เจอตัวเองในห้อง](https://app.clickup.com/t/14zd0zubp9u) — `LiteMeeting` (หรือ lite-shell ตอน `meeting != null`) เรียก `heartbeatZoneSection(workspaceId, zoneId)` ทุก 2 นาทีเหมือน hero · หยุดตอน unmount · unit test ด้วย fake timers
- [x] **B-11** ✅ `fix/lite-meeting-heartbeat` ([#558](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/558)) (สาเหตุ 1 heartbeat) + `fix/lite-switch-room-leave` ([#559](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/559)) (สาเหตุ 2 = B-03) · สาเหตุ 3 ในการ์ด (tile แสดง id แทนชื่อเมื่อไม่อยู่ใน member list) ยังไม่แก้ · [จำนวนคนในห้อง Meeting ไม่อัปเดต / ผิดคน](https://app.clickup.com/t/14zd0zuc0df) — ต้นเหตุเดียวกับ Q-02 + B-03 → หายพร้อมกัน (การ์ดเป็น "ทั้งสองแนว" แต่โค้ดที่ต้องแก้อยู่ฝั่ง Lite)
- [x] **B-03** ✅ `fix/lite-switch-room-leave` ([#559](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/559)) · [Join อีกห้องแล้วเห็นตัวเองค้างห้องเดิม](https://app.clickup.com/t/14zd0zubp9e) — `enter()` ใน `lite/lite-shell.tsx`: ถ้า `meeting && meeting.zoneId !== card.zoneId` → `await liteLeaveMeeting(...)` ห้องเดิมก่อน `liteEnterMeeting`
- [x] **V-12** ✅ `fix/lite-switch-room-leave` ([#559](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/559)) · [กด Leave แล้วหน้า Meeting ยังค้าง](https://app.clickup.com/t/14zd0zuc0dh) — กด Leave → `onLeft()` ทันที (ปิดหน้า + unmount media) แล้วส่ง `liteLeaveMeeting` แบบไม่รอ + timeout (AbortController ~10 วิ) · กันกด Leave ซ้ำ
- [x] **V-11** ✅ (ส่วน zyra-app) `fix/lite-meeting-heartbeat` ([#558](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/558)) · ส่วน server ยังไม่ทำ · [ปิดแอปแล้วคนอื่นยังเห็นอยู่ในห้อง](https://app.clickup.com/t/14zd0zuc0de) — zyra-app: กรอง tile ใน `LiteMeeting` ด้วย WS roster (คนที่ `left` แล้วไม่แสดง แม้ section ยังมี id) · ส่วน server (zyra-ws แจ้ง zyra-api `LeaveZone` หลัง presence grace หมด) แยกเป็น PR ต่อได้

### A2 — WS ของ Lite หลุดบ่อย

- [x] **B-28** ✅ `fix/ws-keepalive-ping` ([#560](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/560)) · [ตัดการเชื่อมต่อบ่อยทั้งที่ 5G เต็ม](https://app.clickup.com/t/14zd0zuc0dv) — Lite ไม่เคยส่ง `ping` (มีแต่ hero) → client ปิด socket ที่เงียบ 30 วิ → reconnect ทุก ~30 วิ ในห้องที่เงียบ · แก้: ย้าย ping keepalive เข้า `WorkspaceWSClient` (`lib/api/workspace-ws.ts`) ให้ทั้ง Lite และ Spatial ได้ · เมื่อ reconnect ครบ 5 ครั้งให้มีปุ่ม Retry (`reconnectNow()`) แทนที่จะหยุดเฉย ๆ · วัด before/after จำนวน reconnect ถ้าทำได้ (rule 18)

### A3 — สถานะตัวละครของ Lite

- [x] **B-23** ✅ `fix/lite-restate-status` ([#561](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/561)) (กรณี C, D) · [Status ตัวละครไม่อัปเดตจนกว่าจะ Refresh](https://app.clickup.com/t/14zd0zubp8t) — กรณี A/B แก้แล้ว (zyra-ws #76, zyra-app #535) · ที่เหลือ: (C) Lite ส่ง `wsClient.setStatus(selfStatus, selfMsg)` หลัง `welcome` แรกและทุก `reconnected` เหมือน hero · (D) `buildLiteHome` เพิ่มคนที่อยู่ใน roster แต่ยังไม่อยู่ใน member list (สมาชิกใหม่)
- [x] **B-24** (ส่วน client) ✅ `fix/lite-wave-result-toast` ([#562](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/562)) · [Wave คนที่ Away ได้](https://app.clickup.com/t/14zd0zubzhw) — Lite ขึ้น toast "You waved at…" ก่อนรู้ผล → ย้าย toast ไปหลังรู้ผล หรือฟัง `wsClient.on("error")` แบบ hero · **ส่วน "away กัน Wave ไหม" รอมติ PM (ดูกลุ่ม C)**

### A4 — Spotlight ฝั่ง Lite

- [x] **V-05** ✅ `fix/lite-spotlight-floor` ([#563](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/563)) · [Start Spotlight นับครบ 5 วิแล้วไม่ขึ้น live](https://app.clickup.com/t/14zd0zuc0dt) — server เลือกชั้นแรกที่มี Spotlight marker แต่ store ของ Lite ทิ้ง update Spotlight ของชั้นอื่นที่ไม่ใช่ `selfFloorId` (`stores/vo-session-store.ts` ราว `:383`) → start ไม่เคยยืนยัน · แก้: ให้ Lite รับ state ของชั้นที่ตัวเองเป็น speaker / ชั้นที่ live · ตอน `giveUp` / ยกเลิก ส่ง `spotlight:stop` เสมอถ้าเคยส่ง start · ทำแล้วช่วย B-13 (ยอด Spotlight) ด้วย

### A5 — หน้าจอ Lite · แยก PR ละข้อได้

- [x] **V-07** ✅ `fix/lite-role-badge` ([#564](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/564)) — รอ design / PM ยืนยันตำแหน่งป้าย · [ไม่แสดงป้าย Owner / Admin](https://app.clickup.com/t/14zd0zuc0d4) — เพิ่ม `role` ใน `LiteMemberInput` / `LitePerson` (`lib/lite-home.ts` — ⚠️ ชน #542) ส่งจาก `memberData.members[].role` · แสดง `LiteRolePill` ท้าย `LiteMemberRow` และใน `LiteMemberProfileSheet` เฉพาะ owner / admin
- [x] **B-43** ✅ `fix/lite-invite-chat-relay` ([#557](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/557)) · [แชร์ Meeting ให้คนที่ไม่เคยคุย ห้องแชทไม่ขึ้น](https://app.clickup.com/t/14zd0zuc0dm) — `sendInChat` (invite → Chat) ส่งผ่าน REST แต่ไม่บอก WS ว่ามีห้องแชทใหม่ → หลัง `sendMessageREST` สำเร็จ เรียก `wsClient.relayMessage(conv.id, confirmed)` · pet-share-modal และ forward-sheet มีปัญหาเดียวกัน → ทำเป็น helper เดียว
- [x] **B-48** ✅ `fix/lite-copy-link` ([#555](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/555)) · [ปุ่ม Copy กับ Share เป็น Action เดียวกัน](https://app.clickup.com/t/14zd0zuc0dr) — เพิ่ม `copyLink(url)` ใน `lib/native/share.ts` (`navigator.clipboard.writeText`, ไม่ได้ค่อยใช้ `@capacitor/clipboard`) ให้ปุ่ม Copy · ปุ่ม Share คง `shareOrCopy`
- [x] **B-39** (ส่วนที่เหลือ) ✅ `fix/lite-capacity-manage-members` ([#556](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/556)) — ⚠️ ทางนี้ยังไม่มีใครเรียก ดูความคืบหน้า · [Manage Member ไม่เต็มจอ](https://app.clickup.com/t/14zd0zubnhm) — ทางเมนู ⋮ แก้แล้ว (#525) · เหลือทาง "Workspace is full → Manage members" (`capacityStep === "manage-members"`) ยังเปิด modal desktop → ใช้ `LiteManageMembersPage` เมื่อ `mobileLists`

---

## ความคืบหน้า 2026-10-14

ทำโดย rif + Claude — กลุ่ม A ครบ 13 การ์ด · แต่ละ branch แตกจาก `develop` ใน worktree แยก · rebase ทั้งหมดขึ้น `develop` @ `28586e0` (หลัง #538–#551 merge) · **PR [#555](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/555)–[#564](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/564) squash merge เข้า `develop` แล้ว (`develop` @ `6849423`) · deploy dev สำเร็จ** · ไม่แตะ ClickUp · ก่อนแก้เปิดอ่าน description + comment ของการ์ดทุกใบแล้ว (มี comment แค่ B-39)

| Branch (zyra-app) | การ์ด | แก้อะไร |
|---|---|---|
| `fix/lite-copy-link` ([#555](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/555)) | B-48 | `copyLink()` ใน `lib/native/share.ts` · ไอคอน Copy ใน `LiteInviteSheet` + "Copy meeting link" ใน Room settings คัดลอกจริง + toast · Share link คง `shareOrCopy` |
| `fix/lite-capacity-manage-members` ([#556](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/556)) | B-39 | `capacityStep === "manage-members"` บนมือถือใช้ `LiteManageMembersPage` + `LiteInviteSheet` · desktop เหมือนเดิม |
| `fix/lite-invite-chat-relay` ([#557](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/557)) | B-43 | `sendDirectMessage` / `relayToConversation` ใน `lib/api/chat-ws.ts` (REST → `relayMessage` → `relayConversationNew`) ใช้ใน Invite sheet, `pet-share-modal`, `forward-sheet` |
| `fix/lite-meeting-heartbeat` ([#558](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/558)) | Q-02 · B-11 · V-11 (client) | hook `use-lite-section-heartbeat.ts` ยิง `heartbeatZoneSection` ทุก 2 นาที (รวมตอนย่อกลับ Home) · `sectionIdsInRoster()` ตัด tile คนที่หลุดจาก WS roster (กรองหลัง `welcomeReceived`, ไม่ตัดตัวเอง) |
| `fix/lite-switch-room-leave` ([#559](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/559)) | B-03 · V-12 | `liteEnterMeeting({ fromZoneId })` เข้าห้องใหม่ก่อน แล้วออกห้องเดิมเมื่อได้ `joined` (ห้องใหม่ล็อก/error → อยู่ห้องเดิม) · Leave ปิดหน้าทันที (`onLeft()`) ส่ง REST leave แบบไม่รอ + timeout 10 วิ (`AbortSignal` ใน `leaveZoneSection`) · กันกดซ้ำ · กลับเข้าห้องเดิมเร็ว ๆ จะรอ leave ที่ค้างก่อน · ทางออกจาก Spotlight ได้แก้แบบเดียวกัน |
| `fix/ws-keepalive-ping` ([#560](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/560)) | B-28 | `WorkspaceWSClient` ส่ง `ping` เมื่อไม่มี ping เกิน 10 วิ (ใช้ tick เดิม 5 วิ, เฉพาะ OPEN + visible) — Spatial ที่ hero ping ทุก 3 วิไม่ถูกเพิ่ม · Lite reconnect ครบแล้วขึ้น toast "Unable to reconnect" + ปุ่ม Retry (`reconnectNow()`) |
| `fix/lite-restate-status` ([#561](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/561)) | B-23 (C, D) | C: ส่ง `setStatus(status, msg)` หลัง welcome (เมื่อ profile โหลดแล้ว) และทุก `reconnected` · D: roster มี user ที่ไม่อยู่ใน member list → invalidate `workspaceMembersQueryKey` (ครั้งเดียวต่อ id) |
| `fix/lite-wave-result-toast` ([#562](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/562)) | B-24 (client) | รอ error จาก WS 1 วิก่อนขึ้น "You waved" — ถ้าได้ unavailable / cooldown / not in office ขึ้นข้อความ error เดิมของ Spatial แทน · ใช้ทั้ง wave และ wave back · ไม่เปลี่ยนว่าใคร wave ได้ (รอมติ PM) |
| `fix/lite-spotlight-floor` ([#563](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/563)) | V-05 | store เก็บ `spotlightFloorId` — Lite ตามชั้นที่ตัวเองเป็น speaker › ชั้นที่ดูอยู่และยัง live › ชั้นอื่นที่ live (zyra-ws ส่ง state ทุกชั้นให้ Lite จึงต้องเลือก) · media / chat room ของ Spotlight Lite ใช้ชั้นนี้ · start ที่ไม่ถูกยืนยันแล้ว giveUp / ยกเลิก → ส่ง `spotlight:stop` · Spatial ยังกรองตาม `selfFloorId` เหมือนเดิม |
| `fix/lite-role-badge` ([#564](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/564)) | V-07 | `role` ใน `LiteMemberInput` / `LitePerson` (Owner ตัดสินด้วย `owner_id` ผ่าน `liteCallerRole`) · `LiteRolePill` เดิมท้าย `LiteMemberRow` + ใน `LiteMemberProfileSheet` เฉพาะ Owner / Admin · ข้อความใช้ `VirtualOffice.roleOwner` / `roleAdmin` |

**verify:**
- ลอง merge ทั้ง 10 branch รวมกันบน `develop` @ `28586e0` → ไม่ชน · **`vitest run` ทั้ง repo บน tree ที่รวมแล้ว: 348 ไฟล์ / 4,289 case ผ่าน (3 skipped)** · eslint ไฟล์ที่แก้ทั้งหมดผ่าน
- `tsc --noEmit` มี 7 error เดิมใน `pixi-game-scene` / `environment-weather-fx` / `pet-creation-wizard` test — มีบน `develop` เปล่าเหมือนกัน ไม่มี error ใหม่
- รันแต่ละ branch แบบขนานเต็มที่มี test timeout 5 วิแบบสุ่ม (เครื่องโหลดหนัก) — รันซ้ำแบบจำกัด worker ผ่านหมด
- **ยังไม่ได้เทสบนเครื่องจริง / ยังไม่ได้ build / ยังไม่ได้รันกับ zyra-ws จริง**

**ข้อควรรู้:**
- **B-39:** ทาง "Workspace is full → Manage members" ตอนนี้ไม่มีใครเรียก — `WorkspaceCard` รับ `onCapacityFull` แต่ไม่เคยเรียก · fix ถูกแต่ยังไม่ปิดอาการที่ QA เห็น ต้องถาม QA ว่าเจอหน้า "Workspace is full" จากไหน
- **B-48:** ในแอปใช้ `navigator.clipboard` ใน WebView — ยังไม่ได้เช็คบน iOS / Android (ถ้าถูกบล็อกต้องเพิ่ม `@capacitor/clipboard`) · `components/zone-enter-header.tsx`, `components/invite-member-modal.tsx` ยัง label Copy แต่เปิด share sheet (ไม่ได้แตะ)
- **B-43:** ฝั่งผู้ส่ง ห้อง DM ใหม่ยังไม่ขึ้นในรายการทันที (ต้อง refetch)
- **V-11:** tile จาก media room (`memberAudio`) ไม่ถูกกรอง · ส่วน server (zyra-ws แจ้ง zyra-api `LeaveZone` หลัง grace) ยังไม่มีคนรับ
- **B-11:** สาเหตุ 3 ในการ์ด (tile แสดง id แทนชื่อ) ยังไม่แก้
- **V-12:** abort แค่หยุดรอฝั่ง client — ถ้า request ถึง server แล้ว leave อาจถูกประมวลผลหลัง 10 วิ ถ้ากลับเข้าห้องเดิมหลังจากนั้นอาจโดนเอาออก (โอกาสต่ำ)
- **B-28:** ปุ่ม Retry อยู่ใน toast ของหน้า Home เท่านั้น (หน้า Meeting มี toast หลุดของตัวเอง ไม่มี Retry) · ping ส่งเฉพาะตอน `visibilityState === "visible"` — ยังไม่ได้เช็คว่า WebView รายงานถูก
- **B-24:** wave 2 คนภายใน 1 วิ ถ้าคนหลัง fail ข้อความ error อาจไปผูกกับคนแรก (error จาก server ไม่มี target id) — ถ้าต้องแก้ขาดให้ zyra-ws ใส่ `target_user_id` ใน error (ทำพร้อมมติ PM ได้)
- **V-05:** แตะ store กลาง + `use-spotlight-broadcast.ts` ที่ Spatial ใช้ร่วม — ควรให้ Ten review · Spatial มีพฤติกรรมใหม่จุดเดียว: ส่ง stop หลัง start ที่ไม่ถูกยืนยัน (server เป็น no-op ถ้าไม่ได้เป็น speaker)
- **V-07:** การ์ดระบุว่าต้อง design / PM ยืนยันตำแหน่งป้าย — revert ได้ด้วยการลบ `<LitePersonRolePill>` 2 จุด

**รีวิวหลัง merge (อ่านโค้ดอย่างเดียว เทียบ zyra-ws / zyra-api `origin/develop` — ยังไม่แก้ รอสั่ง):**

| # | PR | บัค | ผลที่ผู้ใช้เห็น | ระดับ |
|---|---|---|---|---|
| 1 | #559 V-12 | `refreshSections()` ทำงานทันทีหลัง `onLeft` ก่อน REST leave ถึง · `section_sync` ของ Lite ถูก zyra-ws ทิ้ง (`zoneClaimTileOK` — ghost ไม่มี tile ในห้อง) | กด Leave / สลับห้อง แล้ว Home ยังโชว์เราในห้องเดิมนานสุด 30 วิ · Instant meeting เห็นห้องนั้นว่าไม่ว่าง | กลาง |
| 2 | #559 V-12 | `onLeft` ล้าง `meeting` ทันที → `endSession` ไม่รอ leave ที่ค้าง | Leave แล้วรีบสลับ workspace / logout → reload ตัด request → ค้าง Online ในห้อง ≤ 3 นาที | กลาง-ต่ำ |
| 3 | #562 B-24 | wave ที่สำเร็จ server ไม่ส่งอะไรกลับให้ผู้ส่ง (มีแค่ broadcast `wave_animation`) แต่ hook ผูก error กับ wave ที่ค้างนานสุด | wave Ann (ว่าง) แล้ว Bob (busy) ภายใน 1 วิ → Ann ได้ "ไม่ว่าง" · Bob ได้ "You waved" · แก้: ใช้ `wave_animation` ของตัวเองเป็น ack | กลาง |
| 4 | #561 B-23 | `ready` เป็น true ตั้งแต่มี cache `profile-me` แต่เปลี่ยนสถานะไม่อัปเดต cache | ตั้ง busy แล้วสลับ workspace ภายใน 5 นาที → ส่ง "available" จาก cache ทับสถานะจริง | กลาง |
| 5 | #563 V-05 | server บันทึก ✓ รับ Spotlight ของ Lite ที่ชั้นของห้องประชุม (`spotlightMeetingFloor`) แต่ client อ่านจากชั้นที่ดูอยู่ | ห้องประชุมคนละชั้นกับ Spotlight → กด ✓ แล้วขึ้น "Spotlight จบแล้ว" หรือ prompt ค้าง · ต้องตัดสินพฤติกรรม | กลาง |

- **#556 B-39 แก้ผิดเป้า:** ทาง "Workspace is full → Manage members" ไม่มีโค้ดเรียก (`WorkspaceCard` ไม่เคยเรียก `onCapacityFull`) — ไม่พังแต่ไม่ปิดอาการ QA · test mock ทางเข้าที่ของจริงไม่มี
- **ระดับต่ำ:** V-12 timeout 10 วิไม่ครอบช่วงอ่าน body (body พัง → spinner เข้าห้องค้างได้) · Q-02 แอปอยู่ background > 3 นาทีโดนตั้ง Offline แล้ว heartbeat ดึงกลับไม่ได้ · B-28 ระหว่าง Retry ยังขึ้น "Unable to reconnect" · test ของ B-24 ยืนยันพฤติกรรมที่ผิด
- **ไม่เจอบัค:** #555 B-48 (ต้องเช็ค clipboard บนเครื่อง) · #557 B-43 · #564 V-07 · #558 heartbeat / roster filter · #560 B-28 (server ตอบ `pong` จริง)

**B-10 (รวมใน B-02) — ส่วน "หลุดแล้วยังค้างในห้อง":** branch `fix/lite-leave-stale-section` (commit `159c562`, ยังไม่ push / ยังไม่เปิด PR) · Lite เริ่ม session ใหม่ (หลัง reload) ถ้า section list ชุดแรกยังมีเรา Online ในห้องที่ไม่ได้อยู่ → leave ให้ครั้งเดียว แล้วโหลด list ใหม่ (`staleSectionZoneIds()` + hook `use-lite-leave-stale-sections.ts`) · มติ rif 2026-10-14: ออกให้อัตโนมัติ (แบบ ก) ไม่ถาม Rejoin · ข้อเสีย: ถ้า user เดียวกันอยู่ในห้องจากอีกเครื่องจะถูกเอาออก · test Lite 34 ไฟล์ / 310 case ผ่าน · ยังไม่ได้เทสบนเครื่อง · **ส่วนจอขาว (B-02) ยังไม่แก้ — รอ QA เทสซ้ำบน dev (#537)**

**ที่เหลือของสายแนวตั้ง:** กลุ่ม B (QA retest) · กลุ่ม C (รอ PM / QA) · กลุ่ม D (DevOps) · ส่วน server ของ V-11 และ B-24

---

## B. QA — เทสซ้ำก่อน (น่าจะหายแล้ว)

fix อยู่บน `develop` แล้ว (dev env) — **ยังไม่ขึ้น uat** · ข้อไหนยังเป็น → comment ในการ์ดพร้อมวิดีโอ + device + เวลา แล้วส่งให้ dev แนวตั้ง

ก้อน Meeting ของ Lite หลุด/ค้าง — น่าจะหายด้วย #537 (SFU session ต่อใหม่ทุกครั้งที่ meeting re-render):
- [ ] **B-02** [เข้าร่วม Meeting แล้วจอขาว](https://app.clickup.com/t/14zd0zubp9b) (รวม sticky "จอขาวแล้วเด้งออกแต่สถานะยังอยู่")
- [ ] **B-05** [Action in meeting กดไม่ได้](https://app.clickup.com/t/14zd0zubp9p) — บอกด้วยว่าปุ่มไหน
- [ ] **B-06** [กด Instant Meeting แล้วจอกระพริบ](https://app.clickup.com/t/14zd0zubp9t)
- [ ] **B-09** [ปุ่ม ‹ › กระพริบเมื่อมี 6 คนขึ้นไป](https://app.clickup.com/t/14zd0zuc0dc)
- [ ] **V-08** [แนวตั้งเข้า Meeting แต่แนวนอนไม่เห็น + พูดไม่มีเสียง](https://app.clickup.com/t/14zd0zuc0d5)
- [ ] **V-09** [เมนูในห้อง Meeting กดไม่ได้ทุกเมนู](https://app.clickup.com/t/14zd0zuc0d6) — บอกด้วยว่าเมนูไหน
- [ ] **V-10** [กด Instant Meeting แล้วไม่เข้าหน้า Meeting](https://app.clickup.com/t/14zd0zuc0d9) — ขึ้น toast "Meeting has ended" ไหม

อื่น ๆ:
- [ ] **Q-01** [อยู่นอกห้องแต่ถูกนับในกลุ่ม Meeting](https://app.clickup.com/t/14zd0zubp91) — zyra-ws #77 + #537
- [ ] **B-22** [Web ไม่เห็น User ที่ login ผ่านมือถือ](https://app.clickup.com/t/14zd0zubp8q) — zyra-ws #75 / #76
- [ ] **V-01** [Profile เลื่อนลงไม่ได้](https://app.clickup.com/t/14zd0zubp90) — #536
- [ ] **B-41** [กดคีย์บอร์ดใน Chat แล้วมีเส้นขาว](https://app.clickup.com/t/14zd0zubp9k) — #536 (เทสทั้ง Lite และแชทแนวนอน)
- [ ] **B-33** [Remind me again แล้วเลือกโหมดไม่ได้](https://app.clickup.com/t/14zd0zubh45) — #512 (การ์ด completed แล้ว)
- [ ] **B-34** [เคลียร์ Session Google เพื่อเลือกบัญชีใหม่](https://app.clickup.com/t/14zd0zubncm) — #519 (การ์ด completed แล้ว)

## C. รอข้อมูล QA / รอมติ PM

| ข้อ | การ์ด | รออะไร | ได้คำตอบแล้วทำอะไร |
|---|---|---|---|
| V-13 🔥 | [Web เห็นคน Lite วาร์ปพร้อมประกายแสง](https://app.clickup.com/t/14zd0zuc0dk) | **PM / Ten:** คน Lite บนแมพให้ server ขับเดินเอง (โค้ดตอนนี้) หรือวาร์ป — spec technical-design §16.2 ขัดกับโค้ด | วาร์ป → zyra-ws (place + teleport flag) แล้ว zyra-app (snap + sparkle) · ปิด V-02 / V-03 ไปด้วย |
| V-02 | [Web เห็นตัวละครคนแนวตั้งเดินไปมาเอง](https://app.clickup.com/t/14zd0zubp93) | มติเดียวกับ V-13 | ตามมติ |
| V-03 | [ตัวละคร Lite เดินเฉียง](https://app.clickup.com/t/14zd0zubp9d) | มติเดียวกับ V-13 | ยังเดิน → path ของ autopilot เป็น 4 ทิศ (zyra-ws `pathfind.go`) · วาร์ป → ปิดการ์ด |
| B-24 | [Wave คนที่ Away ได้](https://app.clickup.com/t/14zd0zubzhw) (ส่วน server) | **PM:** away อัตโนมัติ (แอปไป background) ควรกัน Wave ไหม — ตอนนี้ตั้งใจให้ส่ง push ไปหาได้ | ถ้ากันเฉพาะ away ที่ตั้งเอง → zyra-ws `handleWave` เพิ่มเงื่อนไข |
| B-25 | [Wave / แจ้งเตือนซ้ำหลังปิดแอป](https://app.clickup.com/t/14zd0zubp9r) | **QA:** ซ้ำแบบไหน (รูปในการ์ดเป็น Raised hand ×5 ไม่ใช่ Wave) | Lite ส่ง `visibility` ตอนเข้า/ออก background · zyra-ws push เฉพาะยกมือใหม่ · ใส่ collapse key |
| B-35 | [Account & Security → Something went wrong](https://app.clickup.com/t/14zd0zubp8z) | stack trace จาก Sentry (org `zyra-rm`, project zyra-app) 2026-10-09 ~14:25 | แก้ตาม trace · เพิ่ม error boundary ให้หน้า setting |

## D. DevOps

- [ ] **B-38** [Invite ผ่าน Gmail แล้ว 404](https://app.clickup.com/t/14zd0zuby77) — ลิงก์ในอีเมลชี้ host Cloud Run เก่า (`*.asia-southeast1.run.app`) · ลิงก์สร้างจาก env `APP_URL` → ตรวจ `APP_URL` ใน secret `zyra-api-<env>-env-json` (และของ zyra-notifications) แล้ว restart pod — ไม่ต้องแก้โค้ด

---

## นอกขอบเขตเอกสารนี้

สาย 3 "ทั้งสองแนว / ตัวแอป" (15 การ์ด — Meeting ร่วม, zyra-mobile, Android build ฯลฯ) **ยังไม่มีคนรับ** — ดู [mobile-qa-work-split-by-orientation-2026-10-12.md](mobile-qa-work-split-by-orientation-2026-10-12.md#สาย-3--ทั้งสองแนว--ตัวแอป--15-การ์ด)
