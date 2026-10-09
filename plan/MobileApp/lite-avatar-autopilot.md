# Mobile App — ตัวละครของคนที่เข้าจากมือถือ (server เดินให้ — "autopilot")

> **สถานะ:** merge เข้า develop ครบ 3 repo (2026-10-09) — [zyra-ws#72](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/72) + รอบต่อ [zyra-ws#73](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/73) (lead request · circle · spotlight) · [zyra-api#164](https://github.com/Maximumsoft-Co-LTD/zyra-api/pull/164) · [zyra-app#521](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/521) · **ยังไม่ได้ลองบนเครื่องจริง** · **repo:** zyra-ws (`internal/hub/autopilot.go`) · zyra-api (`seats` ใน zone cache) · zyra-app (`lib/map-presence.ts`, `autopilot` park/resume) · **คนล่าสุด:** Ten + Claude

## โจทย์

Ten (2026-10-09): "ให้ข้อมูล sync กัน web เห็นยังไง mobile เห็นอย่างนั้น … แนวตั้งกดเข้า meeting ให้ตัวละครโผล่มาใน meeting web ด้วย ให้ render เดินมาจากจุดเกิด … เมื่อปรับจากแนวนอนเป็นแนวตั้ง ตัวละครดันทิ้งตัวเปล่าๆ ไว้บน maps … ถ้าคนนั้นมี private zone ของตัวเองให้ตัวละครกลับไปอยู่ใน zone ของตัวเอง ถ้าไม่มีก็ให้กลับไปอยู่ใน zone ที่ไม่มีเจ้าของ ถ้า zone เต็มหมดแล้วให้ตัวละครเดินเล่นๆ ตรงจุดเกิด — ไม่อยากให้แยกออกคนไหนเข้าจากมือถือ คนไหนเข้าจากคอม"

คำตอบ Ten ต่อคำถาม: zone ที่ไม่มีเจ้าของ = private zone ที่ยังไม่มีใคร claim (**ใช่**) · ไปถึงแล้ว**นั่ง**เก้าอี้ด้วย · บัก "Lite เข้า meeting แล้วคุยไม่ได้" = ไม่ได้ยินเสียงเลย คนบนเว็บไม่รู้ว่ามีตัวตน

## เดิมเป็นยังไง

- Lite (แนวตั้ง) ต่อ zyra-ws เป็น **ghost**: ไม่มี tile ไม่อยู่ใน AOI คำสั่งเดินถูกทิ้ง เข้า meeting ด้วย id ห้อง แล้ว broadcast `ghost_join_zone` ให้เว็บวาดไว้ในห้อง
- เว็บนับคนในห้อง meeting จาก**ตำแหน่ง** (`getZoneParticipants` ใน hero) → ghost ไม่มีตำแหน่งจึงไม่ถูกนับ ไม่ได้ยินเสียง ไม่เห็นตัว
- Spatial บนมือถือหมุนเป็นแนวตั้ง → หน้า Rotate ปิดแมพ input ถูก freeze แต่ตัวละครยืนค้างตรงนั้น

## ทำอะไร

### zyra-ws — `internal/hub/autopilot.go` (#72)

server เดินตัวละครแทนคนที่ไม่มี joystick: Lite ทุกคน + Spatial ที่ส่ง `autopilot {mode: "park"}` (หมุนเป็นแนวตั้ง) จน `{mode: "resume"}`

| สถานการณ์ | ตัวละครทำอะไร |
|---|---|
| เข้า Lite | เริ่มที่ spawn zone ของชั้น (ไม่ restore ตำแหน่งเก่า) แล้วเดินไป "บ้าน" |
| บ้าน | (1) private zone ที่ตัวเอง claim · (2) private zone ที่ยังไม่มีใคร claim และไม่มี autopilot คนอื่นถืออยู่ ไม่มีคนยืนอยู่ — **ถือไว้ในหน่วยความจำ** ตอนอยู่ ไม่ใช่ claim ใน DB (`tb_private_zone_claim` ไม่แตะ) ปล่อยตอนออก/resume · (3) ไม่มี → เดินเล่นรอบ spawn ในรัศมี 3 tile ทุก 6–14 วิ ไม่เข้าโซนใคร |
| ถึงบ้าน | มี seat ใน zone (`seats` จาก zone cache) → นั่ง (`applySit` + broadcast `stopped sitting:true`) · ไม่มี → ยืนในโซน |
| `ws:room:enter` (Lite กด meeting) | ตั้ง `MediaRoomID` ทันที (เสียงเหมือนเดิม) แล้วเดินเข้า tile ของ meeting zone → เว็บนับจากตำแหน่งเหมือนคนเดินเข้า · ไม่ส่ง `ghost_join_zone` แล้ว (Spotlight ยังใช้ marker เดิม) |
| `ws:room:leave` | เดินกลับบ้าน |
| Spatial park | เหมือน Lite (ถ้าอยู่ใน meeting อยู่ จะไม่เดินออก) · resume → หยุด autopilot ปล่อย zone ส่ง `force_sync` ให้เครื่องตัวเองเด้งไปตรงที่จอด |

- เดินผ่าน goto ของ VO_MOVEMENT_V2 เดิม (`beginGoto` แยกออกมาจาก `handleGoto`) → peer interpolate เหมือน click-to-walk ทุกก้าวเช็ค obstacle grid · ถึงปลายทาง = `stopped` ทันที (ไม่รอ client `stop`)
- Lite อยู่ใน AOI แล้ว (peer ต้องเห็นมันเดิน) แต่**ไม่รับ** frame movement/snapshot (ไม่ได้วาดแมพ) · ข้อความเดินจาก client ที่ autopilot ถูกทิ้ง (`dropLiteMessage`) · ไม่ถูกจับเข้า circle ด้วย geometry (`snapshotChatPositions`)
- wire: `Player.autopilot` (true ตอน server เดินให้) · client→server `autopilot {mode}` · zone cache `seats []"tx,ty"`

### zyra-api — seats ใน zone snapshot (#164)

`cache.ZoneGeometry.Seats` = sit point ของทุก sofa บนชั้นนั้นที่ตกใน tile ของ zone (`computeMapSeats` / `seatKeysForPlacement` ใน `obstacle_grid_builder.go` — anchor แบบเดียวกับ collision, คณิต seat เหมือน `scene.ts` "Register sittable seats": anchor = กลาง tile เลื่อนด้วย min col/row ของ footprint, sit point เป็น px จาก canvas 160, floor เป็น tile) · sofa ที่ไม่มี sit point = anchor tile · แก้ object แล้ว republish zone cache ตามหลัง obstacle grid (`WorkspaceService.SetZonePublisher`)

### zyra-app (#521)

- `isGhostPlayer = client_mode === "lite" && !autopilot` → Lite ที่ server เดินให้ถูกวาดเหมือนคนปกติ (แมพ minimap PIP) และนับในห้อง meeting ด้วย geometry · server เก่า → ghost เหมือนเดิม
- Spatial บนมือถือ: `rotateRequired` true → `wsClient.autopilot("park")`, กลับแนวนอน → `"resume"` (ส่งซ้ำตอน reconnect ถ้ายังจอดอยู่)
- Lite เริ่มที่ spawn zone (ไม่ใช้ `last_position`) ให้เว็บเห็นเดินจากจุดเกิด

## verify

- go test / vitest ผ่าน + CI เขียวทั้ง 3 PR · `go test -race` บน autopilot/lite tests ผ่าน · test ใหม่: `autopilot_test.go` (เดินไปบ้าน+นั่ง · 2 zone ว่าง 3 คน = คนละ zone + คนที่ 3 เดินเล่นไม่เข้าโซน · เข้า/ออก meeting · park/resume · zone ของคนอื่น/มีคนยืน/seat ถูกบล็อก/seat มีคนนั่ง) · `TestSeatKeysForPlacement` · `map-presence.test.ts`
- **ยังไม่ได้ลองบนเครื่องจริง** — ขั้นตอน: Lite บนมือถือ + เว็บบนคอม → เห็นตัวโผล่ที่ spawn เดินไป private zone แล้วนั่ง · กด meeting จาก Lite → เดินเข้าห้อง เว็บได้ยินเสียง + เห็นในรายชื่อห้อง · ออก → เดินกลับ · Spatial หมุนแนวตั้ง → เดินไปจอด · หมุนกลับ → คุมได้ต่อ
- Before/After (rule 18): **ยังไม่ได้วัด** — ตัวชี้วัดคือ "Lite ในห้อง meeting ถูกนับในรายชื่อห้องบนเว็บ" (0 → ทุกครั้ง) ต้องลองบนเครื่อง

### รอบต่อ — zyra-ws [#73](https://github.com/Maximumsoft-Co-LTD/zyra-ws/pull/73) (Ten อนุมัติ 2026-10-09)

| เรื่อง | เดิม | ตอนนี้ |
|---|---|---|
| `request_to_lead` ไปหาคน Lite / มือถือที่จอดอยู่ | ปลายทางไม่มี UI ตอบ คนขอรอไปเรื่อยๆ | server ตอบคนขอทันทีด้วย `lead_request_declined {target_user_id, reason:"unavailable"}` (zyra-app ต้องแสดง toast — follow-up) |
| proximity circle | Lite ไม่เคยถูกนับตำแหน่ง | ตัวละครที่ server เดินให้ cluster ตามตำแหน่งเหมือนคนอื่น (คนบนคอมเดินไปหา Lite ที่นั่งอยู่ = เกิดวง) · กฎ "อยู่ในโซน = ไม่ cluster" server ตัดสินเอง (`chatZoneAt`: private/meeting/spotlight → ไม่ cluster, room → เฉพาะในห้อง) · ghost ที่ไม่มี tile ยังถูกข้าม · การถูกพาเข้าวงด้วย id (`circle_join`) ยังคงเดิม และหลุดเมื่ออยู่ใน meeting/marker |
| Spotlight จาก Lite | ใช้ marker แบบ ghost (`ghost_join_zone`) ตัวละครนั่งอยู่ที่บ้านแต่ "พูดจาก marker" | autopilot เดินไปยืนบน marker (เป้าหมายแบบเดียวกับ meeting) · stop → เดินกลับ · ใช้ marker แบบ ghost เฉพาะไม่มี tile หรือ marker อยู่คนละชั้นกับ `FloorID` · `ws:room:leave` หลงมาไม่ดึงออกจาก marker (เคลียร์เป้าหมายต่อ zone) |

## ข้อจำกัด / ต่อจากนี้

- ~~zyra-app ยังไม่แสดง `lead_request_declined`~~ ทำแล้ว [zyra-app#524](https://github.com/Maximumsoft-Co-LTD/zyra-app/pull/524) — toast "{ชื่อ} นำทางให้ไม่ได้ตอนนี้ — กำลังใช้มือถืออยู่" (dev `dev-aa15835`)
- Lite ที่เข้า circle ด้วย id ยังไม่เดินไปหาวง (ถูกพาเข้าแบบเดิม) — ถ้าจะให้เดินไปต้องมีเป้าหมายแบบ tile
- ห้อง meeting ที่ล็อก: autopilot เดินเข้า tile ได้แต่ zyra-api ไม่ให้ token เสียง (เหมือน ghost เดิม) — gate `ws:room:enter` ผ่าน lock ยังเป็น follow-up เดิม
- zone ที่ถูกถือไว้ไม่โชว์บนเว็บว่า "มีคนจอง" (ไม่ใช่ claim) — คนบนเว็บเห็นแค่ตัวละครนั่งอยู่
