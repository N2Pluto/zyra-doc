# Mobile App — งานแนวตั้ง (Lite) สำหรับส่งต่อให้ dev อีกคน

> **สถานะ:** พร้อมแจก · **วันที่:** 2026-10-14 · **Repo ที่กระทบ:** zyra-app (หลัก), zyra-ws / zyra-api (บางข้อ)
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

- [ ] **Q-02** [ออกจาก Meeting 8 แล้วไม่เจอตัวเองในห้อง](https://app.clickup.com/t/14zd0zubp9u) — `LiteMeeting` (หรือ lite-shell ตอน `meeting != null`) เรียก `heartbeatZoneSection(workspaceId, zoneId)` ทุก 2 นาทีเหมือน hero · หยุดตอน unmount · unit test ด้วย fake timers
- [ ] **B-11** [จำนวนคนในห้อง Meeting ไม่อัปเดต / ผิดคน](https://app.clickup.com/t/14zd0zuc0df) — ต้นเหตุเดียวกับ Q-02 + B-03 → หายพร้อมกัน (การ์ดเป็น "ทั้งสองแนว" แต่โค้ดที่ต้องแก้อยู่ฝั่ง Lite)
- [ ] **B-03** [Join อีกห้องแล้วเห็นตัวเองค้างห้องเดิม](https://app.clickup.com/t/14zd0zubp9e) — `enter()` ใน `lite/lite-shell.tsx`: ถ้า `meeting && meeting.zoneId !== card.zoneId` → `await liteLeaveMeeting(...)` ห้องเดิมก่อน `liteEnterMeeting`
- [ ] **V-12** [กด Leave แล้วหน้า Meeting ยังค้าง](https://app.clickup.com/t/14zd0zuc0dh) — กด Leave → `onLeft()` ทันที (ปิดหน้า + unmount media) แล้วส่ง `liteLeaveMeeting` แบบไม่รอ + timeout (AbortController ~10 วิ) · กันกด Leave ซ้ำ
- [ ] **V-11** [ปิดแอปแล้วคนอื่นยังเห็นอยู่ในห้อง](https://app.clickup.com/t/14zd0zuc0de) — zyra-app: กรอง tile ใน `LiteMeeting` ด้วย WS roster (คนที่ `left` แล้วไม่แสดง แม้ section ยังมี id) · ส่วน server (zyra-ws แจ้ง zyra-api `LeaveZone` หลัง presence grace หมด) แยกเป็น PR ต่อได้

### A2 — WS ของ Lite หลุดบ่อย

- [ ] **B-28** [ตัดการเชื่อมต่อบ่อยทั้งที่ 5G เต็ม](https://app.clickup.com/t/14zd0zuc0dv) — Lite ไม่เคยส่ง `ping` (มีแต่ hero) → client ปิด socket ที่เงียบ 30 วิ → reconnect ทุก ~30 วิ ในห้องที่เงียบ · แก้: ย้าย ping keepalive เข้า `WorkspaceWSClient` (`lib/api/workspace-ws.ts`) ให้ทั้ง Lite และ Spatial ได้ · เมื่อ reconnect ครบ 5 ครั้งให้มีปุ่ม Retry (`reconnectNow()`) แทนที่จะหยุดเฉย ๆ · วัด before/after จำนวน reconnect ถ้าทำได้ (rule 18)

### A3 — สถานะตัวละครของ Lite

- [ ] **B-23** [Status ตัวละครไม่อัปเดตจนกว่าจะ Refresh](https://app.clickup.com/t/14zd0zubp8t) — กรณี A/B แก้แล้ว (zyra-ws #76, zyra-app #535) · ที่เหลือ: (C) Lite ส่ง `wsClient.setStatus(selfStatus, selfMsg)` หลัง `welcome` แรกและทุก `reconnected` เหมือน hero · (D) `buildLiteHome` เพิ่มคนที่อยู่ใน roster แต่ยังไม่อยู่ใน member list (สมาชิกใหม่)
- [ ] **B-24** (ส่วน client) [Wave คนที่ Away ได้](https://app.clickup.com/t/14zd0zubzhw) — Lite ขึ้น toast "You waved at…" ก่อนรู้ผล → ย้าย toast ไปหลังรู้ผล หรือฟัง `wsClient.on("error")` แบบ hero · **ส่วน "away กัน Wave ไหม" รอมติ PM (ดูกลุ่ม C)**

### A4 — Spotlight ฝั่ง Lite

- [ ] **V-05** [Start Spotlight นับครบ 5 วิแล้วไม่ขึ้น live](https://app.clickup.com/t/14zd0zuc0dt) — server เลือกชั้นแรกที่มี Spotlight marker แต่ store ของ Lite ทิ้ง update Spotlight ของชั้นอื่นที่ไม่ใช่ `selfFloorId` (`stores/vo-session-store.ts` ราว `:383`) → start ไม่เคยยืนยัน · แก้: ให้ Lite รับ state ของชั้นที่ตัวเองเป็น speaker / ชั้นที่ live · ตอน `giveUp` / ยกเลิก ส่ง `spotlight:stop` เสมอถ้าเคยส่ง start · ทำแล้วช่วย B-13 (ยอด Spotlight) ด้วย

### A5 — หน้าจอ Lite · แยก PR ละข้อได้

- [ ] **V-07** [ไม่แสดงป้าย Owner / Admin](https://app.clickup.com/t/14zd0zuc0d4) — เพิ่ม `role` ใน `LiteMemberInput` / `LitePerson` (`lib/lite-home.ts` — ⚠️ ชน #542) ส่งจาก `memberData.members[].role` · แสดง `LiteRolePill` ท้าย `LiteMemberRow` และใน `LiteMemberProfileSheet` เฉพาะ owner / admin
- [ ] **B-43** [แชร์ Meeting ให้คนที่ไม่เคยคุย ห้องแชทไม่ขึ้น](https://app.clickup.com/t/14zd0zuc0dm) — `sendInChat` (invite → Chat) ส่งผ่าน REST แต่ไม่บอก WS ว่ามีห้องแชทใหม่ → หลัง `sendMessageREST` สำเร็จ เรียก `wsClient.relayMessage(conv.id, confirmed)` · pet-share-modal และ forward-sheet มีปัญหาเดียวกัน → ทำเป็น helper เดียว
- [ ] **B-48** [ปุ่ม Copy กับ Share เป็น Action เดียวกัน](https://app.clickup.com/t/14zd0zuc0dr) — เพิ่ม `copyLink(url)` ใน `lib/native/share.ts` (`navigator.clipboard.writeText`, ไม่ได้ค่อยใช้ `@capacitor/clipboard`) ให้ปุ่ม Copy · ปุ่ม Share คง `shareOrCopy`
- [ ] **B-39** (ส่วนที่เหลือ) [Manage Member ไม่เต็มจอ](https://app.clickup.com/t/14zd0zubnhm) — ทางเมนู ⋮ แก้แล้ว (#525) · เหลือทาง "Workspace is full → Manage members" (`capacityStep === "manage-members"`) ยังเปิด modal desktop → ใช้ `LiteManageMembersPage` เมื่อ `mobileLists`

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
