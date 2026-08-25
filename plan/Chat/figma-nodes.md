# Figma Nodes — Chat Module

**File:** `Map8gX0L2hk7HnkaFRfhtj`  
**Base URL:** `https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/Zyra-design--More-Organised-ver.-`  
**Date fetched:** 2026-06-18

---

## Quick Index

| Scenario | Node ID | Section Name |
|---|---|---|
| SC-CHAT-01 | `1977:1359172` | ส่ง Direct Message (DM) |
| SC-CHAT-02 | `2012:260260` | Proximity Chat — คุยกับคนใกล้ |
| SC-CHAT-03 | `2012:406483` | Proximity Chat — ออกนอก Radius |
| SC-CHAT-04 | `2017:446920` | ส่งข้อความใน Global / Channel Chat |
| SC-CHAT-05 | `2081:35462` | สร้างและส่งข้อความใน Group Chat |
| SC-CHAT-06 | `2096:1032317` | Thread Replies |
| SC-CHAT-07 | `2096:1559539` | Emoji Reaction |
| SC-CHAT-08 | `2100:1943316` | File / Image Attachment |
| SC-CHAT-09 | `2122:70963` | File Attachment เกิน Limit หรือประเภทผิด |
| SC-CHAT-10 | `2138:799995` | Unread Badge และ Notification (In-app) |
| SC-CHAT-11 | `2162:83837` | Message Search |
| SC-CHAT-12 | `2151:1217508` | Typing Indicator |

---

## Shared Components (ใช้ข้าม Scenario)

| Component | Node ID | Size | หมายเหตุ |
|---|---|---|---|
| Direct message — Half view | `2006:100547` | 1440×1024 | Symbol (master) |
| Direct message — Full view | `2006:199495` | 1440×1024 | Symbol (master) |
| Channels — Half view | `2006:199494` | 1440×1024 | Symbol (master) |
| Channels — Full view | `2006:203715` | 1440×1024 | Symbol (master) |
| Threads — Half view | `2006:199097` | 1440×1024 | Symbol (master) |
| Threads — Full view | `2006:202457` | 1440×1024 | Symbol (master) |
| Chat menu (hover bar) | — | 200×321 | ประกอบด้วย Emoji panel + Submenu |
| Emoji panel (quick bar) | — | 200×32 | อยู่ใน Chat menu บนสุด |
| Submenu (action list) | — | 184×284 | อยู่ใน Chat menu ล่าง Emoji panel |
| Notification toast | — | 322×124 | ขวาบน at (1094, 24) |
| Toast (small) | — | 336×90 | ใช้ใน Group/Create group |
| Toast (tiny) | — | 336×72 | ใช้หลัง action สำเร็จ |
| Preview image modal | — | 600×564 | Lightbox รูปภาพ at (420, 230) |
| Preview file modal | — | 600×578 | File preview at (420, 223) |
| Preview file modal (compact) | — | 600×368 | drag & drop error case at (420, 328) |
| Reaction modal | — | 366×464 | แสดง user list ต่อ emoji at (532, 220) |
| Search filter panel | — | 340×382 | ใช้ใน SC-CHAT-11 at (550, 321) |
| Date Picker | — | 311×302 | ใช้ใน Search filter at (563, 637) |
| Proximity circle overlay | — | 200×170 | Circle indicator บน VO map |
| Text notification bottom | — | 482×44 | แจ้งเตือนล่างหน้าจอ VO |
| Group info panel | — | 338×992 | ด้านขวา at (1086, 16) |

---

## Layout Constants

| ค่า | จาก Figma |
|---|---|
| Canvas | 1440×1024 px |
| Chat panel — Half view | 320×992, `right-[1048px] top-[16px]` |
| Chat panel — Full view | 1016×992, `right-[16px] top-[16px]` |
| Chat menu (hover) position | x = 184 (half) / 1216 (full), y = 120–219 |
| Notification toast position | x = 1094, y = 24 |
| Overlay (modal bg) | 1440×1024, semi-transparent |
| Preview modal position | x = 420, y = 230 (image) / 223 (file) / 328 (compact) |
| Reaction modal position | x = 532, y = 220 |
| Search filter position | x = 550, y = 321 |

---

## SC-CHAT-01 · ส่ง Direct Message (DM)

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=1977-1359172  
**Section size:** 21103×11495  
**ClickUp:** https://app.clickup.com/t/86d2we8qe

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `1977:1361871` | Wave | 1440×1024 | มี Wave notification toast ด้านขวา |
| `2006:205060` | Direct message — Half view | 1440×1024 | State: เริ่มเปิด DM |
| `2006:207618` | Direct message — Half view | 1440×1024 | State: พิมพ์ข้อความ |
| `2006:207891` | Direct message — Half view | 1440×1024 | State: ส่งข้อความสำเร็จ |
| `2006:212418` | Direct message — Half view | 1440×1024 | State: **ส่ง Fail** (sticky: กรณีส่งข้อความแล้ว Fail) |
| `2006:209410` | Direct message — Half view | 1440×1024 | State: ส่งสำเร็จ (แถว 2) |
| `2006:213614` | Direct message — Half view | 1440×1024 | State: Fail แถว 2 |
| `2006:208219` | Direct message — Full view | 1440×1024 | State: Full view เริ่มต้น |
| `2006:208797` | Direct message — Full view | 1440×1024 | State: Full view พิมพ์ |
| `2006:212706` | Direct message — Full view | 1440×1024 | State: Full view **ส่ง Fail** |
| `2069:66411` | Direct message — Half view + Submenu | 1440×1024 | Hover state: Submenu 184×200 at (186, 865) |

### Key Child Nodes ใน SC-CHAT-01

| Node ID | Name | Size | at (x, y) |
|---|---|---|---|
| `1977:1362093` | Notification toast | 322×124 | (1094, 24) |
| `2069:65685` | Submenu (hover menu) | 184×200 | (186, 865) |
| `2006:100547` | Direct message — Half view (symbol) | 1440×1024 | master |
| `2006:199495` | Direct message — Full view (symbol) | 1440×1024 | master |

### Notes จาก Sticky

- **กรณีส่งข้อความแล้ว Fail** (×4 stickies): แสดง retry button บนข้อความนั้น
- **กรณี Hover**: เห็น action bar (เมนูบน message)
- **กรณี select chat**: DM select state ใน sidebar
- **Mark as read** = อ่านโดยไม่ต้องเข้า Chat · **Hide** = ซ่อนแต่เก็บ history · **Mute** = ปิดแจ้งเตือน · **Delete** = ลบ history (Group/Channel ไม่มีเมนู Hide)

### Sections ย่อย

| Section | คำอธิบาย |
|---|---|
| แถว 1 (y=679) | กรณี DM เมื่อมีคน Wave มา |
| แถว 2 (y=5975) | กรณี DM ผ่าน Chat (เปิดจาก sidebar) |

---

## SC-CHAT-02 · Proximity Chat — คุยกับคนใกล้บน Virtual Office Map

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2012-260260  
**Section size:** 21103×4702  
**ClickUp:** https://app.clickup.com/t/86d2we8zv

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2012:334673` | Idle UI | 1440×1024 | ก่อนเข้า radius |
| `2012:334861` | Circle | 1440×1024 | เห็น user status panel 322×310 at (1094, 24) |
| `110:33057` | Circle | 1440×1024 | Symbol instance: 2 คนในวงกลม |
| `2012:343169` | Circle | 1440×1024 | กรณี Circle มี 20 คนแล้ว (max) |
| `2012:344106` | Circle — Enter circle | 1440×1024 | มุมมองคนที่จะเข้า; Circle indicator 200×170 at (490, 642) |
| `2012:382144` | Circle — Enter circle | 1440×1024 | เข้าได้ปกติ |
| `2012:382343` | Circle — Enter circle | 1440×1024 | มี Text notification bottom 482×44 at (507, 892) |
| `2012:345404` | Circle — Enter circle limit | 1440×1024 | Symbol: เข้าไม่ได้เพราะ full |
| `2012:335504` | Display — 2 people | 1440×1024 | Proximity panel เปิด |

### Key Child Nodes

| Node ID | Name | Size | at (x, y) |
|---|---|---|---|
| `2012:335047` | User status | 322×310 | (1094, 24) |
| Proximity circle indicator | (inline) | 200×170 | (490, 642) |
| Text notification bottom | (inline) | 482×44 | (507, 892) |

### Notes จาก Sticky

- **จะเดินไปหา หรือ เลือกเมนู Go to ก็ได้**
- **พอเดินมาใกล้กันเกิด Circle ครอบทั้ง 2 คน**
- **กรณี Circle มี 20 คนแล้ว** → reject new member
- **Circle ไม่มี Chat Record** — proximity messages เป็น ephemeral ไม่บันทึก history
- **ตอนเดินเข้า Circle จะกลายเป็นว่าเดินอยู่ข้างบน Circle จะไม่ทะลุเข้าไป**
- **กรณี Hover ที่ Circle** → แสดง member list

---

## SC-CHAT-03 · Proximity Chat — ออกนอก Proximity Radius

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2012-406483  
**Section size:** 21103×3326  
**ClickUp:** https://app.clickup.com/t/86d2we93m

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2012:410916` | Circle — 3 participants | 1440×1024 | Symbol: 3 คนในวงกลม |
| `2012:412230` | Circle — 2 participants | 1440×1024 | Symbol: เหลือ 2 คน (1 ออกแล้ว) |
| `2012:412231` | Circle — Leave circle | 1440×1024 | Symbol: ออกจากวงกลม |
| `2017:412519` | Circle — Enter circle limit | 1440×1024 | กรณีกด Leave ออกแล้วยืนที่เดิม |

### Notes จาก Sticky

- **กรณีกด Leave ออกจาก Circle** → สามารถอยู่ที่เดิม แล้วไม่ดึงเข้า Circle ได้
- **กรณีเดินออกจาก Circle** → 2-วินาทีก่อน panel ปิด
- **กรณีเดินออกจาก Circle หมด** → session ถูก destroy ทันที

### Flow: ออก → ปิด Panel

```
3 คน → 1 คนเดินออก → 2 คน (Circle ยังอยู่)
      → คนสุดท้ายออก → Circle หาย (no session)
กด Leave → ยืนที่เดิม แต่ไม่ถูกดึงเข้า Circle
```

---

## SC-CHAT-04 · ส่งข้อความใน Global / Channel Chat

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2017-446920  
**Section size:** 23322×11582  
**ClickUp:** https://app.clickup.com/t/86d2we98u

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2017:447863` | Chat | 1440×1024 | Chat sidebar (base state) |
| `2069:76173` | Mention — Half view | 1440×1024 | `@` mention dropdown: Submenu 184×158 at (192, 271) |
| `2006:199494` | Channels — Half view | 1440×1024 | Symbol: channel view |
| `2017:454199` | Channels — Half view | 1440×1024 | State: unread messages |
| `2033:573794` | Channels — Half view | 1440×1024 | State: มีข้อความใหม่ |
| `2069:70852` | Channels — Half view | 1440×1024 | State: Mention highlight |
| `2020:524104` | Pin — Half view | 1440×1024 | Chat menu 200×321 at (184, 219); Emoji panel 200×32; Submenu 184×284 at (8, 37) |
| `2021:526967` | Pin — Half view | 1440×1024 | Submenu 184×368 at (204, 81) |
| `2069:72458` | Pin — Half view | 1440×1024 | Chat menu 200×321 at (184, 77) |
| `2006:203715` | Channels — Full view | 1440×1024 | Symbol: full view |
| `2017:450932` | Channels — Full view | 1440×1024 | Full view state |
| `2020:523131` | Pin — Full view | 1440×1024 | Chat menu 200×321 at (1216, 219) |
| `2030:537794` | Pin — Full view | 1440×1024 | Symbol |
| `2069:73506` | Pin — Full view | 1440×1024 | Chat menu 200×321 at (1216, 76); Emoji panel; Submenu 184×284 |

### Sections ย่อย

| Section | Node ID | ครอบคลุม |
|---|---|---|
| Mention flow | แถว 1 (y=679) | `@` mention → notification |
| Pin flow | แถว 2 (y=5975) | pin/unpin message |
| Unread flow | แถว 3 (y=8623) | jump-to-unread |
| เพิ่มเติม | `2069:76248` | multi-pin interaction (PIN1 ↔ PIN2 toggle) |

### Chat Menu Structure (ใช้ซ้ำทุก channel/DM)

```
Chat menu (200×321)
├── Emoji panel (200×32)     ← quick reaction bar บนสุด
└── Submenu (184×284)        ← action list: Reply, Pin, Edit, Delete…
    at offset (8, 37) within Chat menu
```

### Notes จาก Sticky

- **กรณี Pin แค่ Message เดียว** vs **กรณีมีหลาย Message Pin**
- **สามารถไล่อ่านข้อความที่ Pin ทั้งหมดในนี้ได้**
- **กรณี Full view สามารถ Unpin ได้ทั้งตัว Main display หรือเมนู Pin**
- **กรณีที่เค้ามาใน Chat ที่เราไม่ได้อ่าน** → Navigate ไปที่ 10 Unread messages + ปุ่ม Skip ไปข้อความล่าสุด
- **Multi-pin** (≥2): tap pin เปลี่ยนชื่อ + navigate ไปยัง pin นั้น (toggle); **≥3 pins** → ดูเพิ่มเติม

---

## SC-CHAT-05 · สร้างและส่งข้อความใน Group Chat

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2081-35462  
**Section size:** 29580×9315  
**ClickUp:** https://app.clickup.com/t/86d2we9cz

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2081:36405` | Chat — Half view + Submenu | 1440×1024 | New Group option: Submenu 184×100 at (204, 81) |
| `2081:36408` | Chat — Half view | 1440×1024 | Select members step |
| `2081:36409` | Chat — Half view | 1440×1024 | Set group name step |
| `2091:248740` | Create group — Half view | 1440×1024 | Toast 336×90 at (1080, 24): group created |
| `2081:36410` | Channels — Half view | 1440×1024 | Group chat (เปิดทันทีหลัง create) |
| `2081:40233` | Channels — Half view | 1440×1024 | อีกฝั่งส่งข้อความในกลุ่ม |
| `48:7381` | Notification | 1440×1024 | Symbol: notification state |
| `2081:41281` | Group chat | 1440×1024 | Notification toast 322×124 at (1094, 24) |
| `2084:205051` | Group chat | 1440×1024 | Group notification panel 338×992 at (1086, 16) |
| `2091:206056` | Group chat | 1440×1024 | Collapse/Expand notification (1 toast visible) |
| `2091:260713` | Chat — Full view | 1440×1024 | Full view: New Group Submenu |
| `2096:264198` | Create group — Full view | 1440×1024 | Toast 336×90 at (1080, 24) |

### Group Notification Panel Detail

```
Group panel (338×992) at (1086, 16):
├── Notification toast ×5  (322×124 each, stacked gap 8px)
│   at (8, 8), (8, 140), (8, 272), (8, 404), (8, 536)
└── Button group (209×24) at (121, 668)
    ├── Button — Collapse (100.5×24)
    └── Button — Expand (100.5×24)
```

### Section เพิ่มเติม (`2091:260389`)

| Node ID | Name | Size | หมายเหตุ |
|---|---|---|---|
| `2091:206825` | Group — Half view | 1440×1024 | Group settings Submenu 216×410 at (177, 74) |
| `2091:248781` | Group — Half view | 1440×1024 | Group info panel |
| `2091:256551` | Chat — Half view — Setting | 1440×1024 | Symbol: group settings |
| `2091:258287` | Upload (group icon) | 1440×1024 | Overlay + Upload image modal 459×574 at (491, 225) |
| `2091:260363` | Chat — Half view — Setting | 1440×1024 | Toast 336×72 at (1080, 24): saved |

### Notes จาก Sticky

- **กรณีไม่มีชื่อกลุ่ม** → ใช้ชื่อ member ต่อกันแทน
- **กรณีเลือกคนเกิน Limit** → error แจ้ง
- **กรณี Hover ที่ Notification** → เงา + ปุ่ม Collapse/Expand + Clear
- **กรณี Collapse** → การ์ด Noti ซ้อนกัน
- **อีกฝั่งส่งข้อความในกลุ่มแชท** → Notification เด้งมาที่เรา; กดที่ Notification ไปที่แชท

---

## SC-CHAT-06 · Thread Replies

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2096-1032317  
**Section size:** 21103×5853  
**ClickUp:** https://app.clickup.com/t/86d2we9ha

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2096:1042290` | Chat | 1440×1024 | Chat sidebar — threads icon |
| `2096:1043263` | Channels — Half view | 1440×1024 | Channel ก่อน hover message |
| `2096:1034238` | Direct message — Full view | 1440×1024 | DM ก่อน reply |
| `2096:1035516` | Threads — Full view | 1440×1024 | Chat menu 200×321 at (1216, 120); Reply option visible |
| `2006:199097` | Threads — Half view | 1440×1024 | Symbol: thread panel (half) |
| `2006:202457` | Threads — Full view | 1440×1024 | Symbol: thread panel (full) |
| `2096:1041190` | Direct message — Full view — Reply | 1440×1024 | Symbol: DM + thread panel open |
| `2096:1047477` | Threads — Full view — Reply | 1440×1024 | Symbol: thread replies view |
| `2096:1043901` | Direct message — Half view — Reply | 1440×1024 | Chat menu 200×321 at (184, 120) |
| `2096:1044002` | Direct message — Half view — Reply | 1440×1024 | Thread panel เปิดแล้ว |
| `2096:1044991` | Direct message — Half view — Reply | 1440×1024 | Reply count badge |
| `2096:1041211` | Direct message — Full view — Reply | 1440×1024 | Full view + thread open |
| `2096:1045977` | Direct message — Half view — Reply | 1440×1024 | Thread reply input |
| `2096:1045541` | Chat | 1440×1024 | Threads messages (all my threads) |

### Thread Panel Anatomy

```
Half view (1440×1024):
├── Main chat panel (left, ~720px wide)
└── Thread panel overlay (right, ~320px wide)
    ├── Parent message (quoted, บนสุด)
    ├── Reply list (flat, created_at ASC)
    └── MessageInput (ล่างสุด)

Chat menu position:
  Half view: x = 184, y = 120
  Full view: x = 1216, y = 120
```

### Notes จาก Sticky

- **เมนู Threads ทั้งใน DM, Group และ Channel** → แสดง Threads ทั้งหมดที่อยู่ในแชทนั้น ทั้งเกี่ยวกับเราและไม่เกี่ยวกับเรา
- **Threads message** (icon ใน sidebar) = แหล่งรวม Threads ทุกแชท **ที่เกี่ยวกับเราเท่านั้น** (เคย reply หรือถูก mention)
- Thread แสดง "Threads ใน Direct message Group Channel" (section label)

---

## SC-CHAT-07 · Emoji Reaction

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2096-1559539  
**Section size:** 21103×3720  
**ClickUp:** https://app.clickup.com/t/86d2we9qh

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2096:1559552` | Chat | 1440×1024 | Sidebar base |
| `2096:1559554` | Channels — Half view | 1440×1024 | Channel view ก่อน hover |
| `2096:1559542` | Emoji — Full view | 1440×1024 | Chat menu 200×321 at (1216, 120); Emoji panel top |
| `2096:1559555` | Direct message — Half view — Reply | 1440×1024 | Chat menu 200×321 at (184, 120) |
| `2096:1573241` | Direct message — Half view — Reply | 1440×1024 | Emoji full picker screenshot 240×361 at (148, 136) |
| `2096:1573601` | Emoji — Full view | 1440×1024 | Emoji full picker 240×361 at (1176, 136) |
| `2096:1572510` | Emoji — Full view | 1440×1024 | **Reaction modal** 366×464 at (532, 220) |
| `2096:1569720` | Direct message — Half view — Reply | 1440×1024 | Reaction modal symbol 366×464 |
| `2096:1571450` | Direct message — Full view | 1440×1024 | Reactions แสดงใต้ message |
| `2096:1571918` | Emoji — Full view | 1440×1024 | After reaction added |
| `2096:1588379` | Emoji — Full view | 1440×1024 | Toggle off (ยกเลิก reaction) |
| `2096:1574104` | Direct message — Half view — Reply | 1440×1024 | Final state |
| `2096:1568938` | Direct message — Half view — Reply | 1440×1024 | After reaction visible |

### Reaction Bar Spec (จาก node `2141:808931` / `2146:811284`)

**Single row bar** (502×19) — emoji chip format:
```
[😄 5] [🎉 1] [❤️ 1] [🤣 1] [😴 1]  ...
chip width: 32–40px  height: 19px
emoji: 14×14px at (4, 2.5)
count text: starts at x=22
```

**Multi-row bar** (198×88) — row เมื่อ reaction มาก:
```
Row 1 (y=0):  [😄 10] [🎉 5] [🎉 5] [🎉 5] [❤️ 8]
Row 2 (y=23): [❤️ 8]  [❤️ 8]  [❤️ 8]  [🤣 2] [🤣 2]
Row 3 (y=46): [🤣 2]  [🤣 2]  [🤣 2]  [🤣 2]  [😴 4]
Row 4 (y=69): [😴 4]  [😴 4]  [😴 4]  [😴 4]  [😴 4]
chip gap: 4px  row gap: 4px
```

### Reaction Modal Spec (366×464)

| Element | Size | Position |
|---|---|---|
| Container | 366×464 | at (532, 220) |
| Emoji tab bar | full width | top |
| User list per emoji | scrollable | body |

### Notes จาก Sticky

- **กรณีกด Emoji ที่เราเคยกด = ยกเลิก Emoji นั้น** (toggle off)
- **Emoji สูงสุด 20 รูปแบบ** — 😎 = 1 ประเภท ซึ่งคนอื่นสามารถมากด emoji รูปแบบนี้ได้เรื่อยๆ

---

## SC-CHAT-08 · File / Image Attachment

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2100-1943316  
**Section size:** 21103×10546  
**ClickUp:** https://app.clickup.com/t/86d2wea2p

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2100:1943340` | Channels — Half view | 1440×1024 | State: ก่อน attach |
| `2100:1949060` | Upload (drag zone) | 1986×1024 | OS file picker / drag area |
| `2106:1951843` | Channels — Half view | 1440×1024 | รูปภาพ uploading (progress) |
| `2106:1953452` | Image preview — Half view | 1440×1024 | Overlay + Preview image modal 600×564 at (420, 230) |
| `2108:1957460` | Image preview — Half view | 1440×1024 | Multi-image preview |
| `2117:2309570` | Channels — Half view | 1440×1024 | รูปแสดงใน chat (sent) |
| `2117:2745319` | Image download — Half view | 1440×1024 | Chat menu 200×363 with Submenu 184×326 at (184, 120) |
| `2122:70320` | Image preview — Half view | 1440×1024 | Lightbox: Preview image modal 600×564 at (420, 230) |
| `2122:70912` | Image preview — Full view | 1440×1024 | Lightbox Full: Preview image modal 600×564 at (420, 230) |
| `2100:1943318` | Direct message — Full view | 1440×1024 | Full view base |
| `2110:1960786` | Direct message — Full view | 1440×1024 | Upload progress |
| `2100:1949065` | Direct message — Full view | 1440×1024 | รูปส่งแล้ว |
| `2117:2387626` | Direct message — Full view | 1440×1024 | Multi-image grid |
| `2135:433116` | Image download — Full view | 1440×1024 | Chat menu 200×363 at (568, 212) |
| `2106:1953407` | Image preview — Full view | 1440×1024 | Lightbox (full) |
| `2116:2093971` | File preview — Half view | 1440×1024 | **Preview file modal 600×578** at (420, 223) |
| `2116:2091012` | File preview — Half view | 1440×1024 | Overlay + file modal symbol |
| `2108:1958309` | Channels — Half view | 1440×1024 | File attachment state |
| `2108:1958308` | Direct message — Full view | 1440×1024 | File attachment full view |

### Preview Modals Spec

| Modal | Node ID | Size | at (x, y) | หมายเหตุ |
|---|---|---|---|---|
| Preview image modal | `2100:1951758` | 600×564 | (420, 230) | Lightbox รูปภาพ |
| Preview file modal | `2116:2091480` | 600×578 | (420, 223) | ไฟล์ non-image |

### Download Menu Spec (200×363)

```
Chat menu (200×363)
├── Emoji panel (200×32)    y=0
└── Submenu (184×326)       y=37, x=8
    Items: Reply, Copy, Forward, Download, Download All, Delete, ...
```

### Notes จาก Sticky

- **กรณีเอาเมาส์ไว้ Hover ตรง image** → Icon กากบาท ปรากฎ เพื่อลบรูปนั้น
- **ตอนรูปภาพยังโหลดไม่เสร็จ** → Hover เพื่อลบได้; ถ้าโหลดเสร็จแล้วก็ Hover แล้วจะมีปุ่มกากบาทเพื่อลบ
- **กรณีส่งข้อความ + รูปภาพ** → ข้อความกับรูปอยู่ด้วยกัน
- **สามารถ Download ทีละภาพ** (คลิกขวาที่รูป) หรือ **Download all** (ปุ่มล่างรูปภาพ)

### Row Layout

| แถว | y | เนื้อหา |
|---|---|---|
| แถว Image | y=679 | Image attachment flow (half view) |
| แถว Image | y=2003 | Image upload progress |
| แถว Image | y=3327 | Image attachment full view |
| แถว Image | y=4651 | Multi-image |
| แถว File | y=7530 | File attachment (half view) |
| แถว File | y=8854 | File attachment (full view) |

---

## SC-CHAT-09 · File Attachment เกิน Limit หรือประเภทผิด

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2122-70963  
**Section size:** 21103×7419  
**ClickUp:** https://app.clickup.com/t/86d2wea5b

### Frame Nodes

| Node ID | Name | Size | State / Error Case |
|---|---|---|---|
| `2122:70983` | Channels — Half view | 1440×1024 | Base state ก่อน attach |
| `2122:71021` | Upload (file picker) | 1986×1024 | File picker opened |
| `2125:82639` | Image file — select file | 1440×1024 | Error: invalid file type (select) |
| `2125:82638` | Image file — drag & drop | 1440×1024 | Error modal: Preview file modal 600×368 at (420, 328) |
| `2128:215012` | File — drag & drop | 1440×1024 | Error modal: Preview file modal 600×368 at (420, 328) |
| `2132:432257` | Image file — select file | 1440×1024 | Error: เกิน 5 ไฟล์ |
| `2136:799642` | File — drag & drop | 1440×1024 | Error: virus detected; file modal 600×368 at (420, 328) |
| `2132:301147` | Channels — Half view | 1440×1024 | หลัง error dismissed |
| `2128:216082` | File preview — Half view | 1440×1024 | Error summary: Preview file modal 600×398 at (420, 313) |

### Error Modal Dimensions

| Case | Size | at (x, y) |
|---|---|---|
| Image drag & drop error | 600×368 | (420, 328) |
| File drag & drop error | 600×368 | (420, 328) |
| Over limit (5+ files) | 600×368 | (420, 328) |
| Virus detected | 600×368 | (420, 328) |
| File preview (error state) | 600×398 | (420, 313) |

### Notes จาก Sticky

- **กรณีอัปโหลดไฟล์หรือรูปภาพจากการกดอัปโหลด** → Validate ไฟล์ที่ระบบซัพพอร์ท; ถ้าไม่ซัพพอร์ทไม่ให้กดเลือก; ครบ 5 ไฟล์แล้วไม่ให้กดเลือกอีก
- **กรณี Drag & drop รูปภาพเมื่อเกิด error** → บอกว่าไม่สามารถอัปโหลดได้เพราะอะไร: Unsupported format / Exceed limit file / Virus detected
- **กรณี Drag & drop ไฟล์เมื่อเกิด error** → บอกว่า Unsupported format / Exceed limit file
- **กรณี Drag & drop มากกว่า 5 ไฟล์** → ไฟล์ที่ 1–5 ถูกอัปโหลด ไฟล์ลำดับที่มากกว่านั้นถูกตัดออก
- **กรณีดาวน์โหลดไฟล์และระบบตรวจเจอว่าติดไวรัส** → error case

### Error Flow

```
เลือกไฟล์ (picker หรือ drag&drop)
├── type ไม่รองรับ → disable ปุ่มเลือก / show error บนไฟล์นั้น
├── size เกิน limit → show "ไฟล์ของคุณ X MB เกิน limit"
├── count > 5 → upload ไฟล์ 1–5 + "ไฟล์ที่เกินถูกตัดออก"
└── virus detected (async หลังส่ง) → file card สีแดง "ไฟล์นี้ไม่ปลอดภัย"
```

---

## SC-CHAT-10 · Unread Badge และ Notification (In-app)

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2138-799995  
**Section size:** 21103×9042  
**ClickUp:** https://app.clickup.com/t/86d2weaan

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2141:807206` | Idle UI | 1440×1024 | Base: ก่อนมีข้อความ |
| `2138:799997` | Wave (1 notification) | 1440×1024 | Notification toast 322×124 at (1094, 24) |
| `2141:807444` | Wave (99+ notifications) | 1440×1024 | Notification สูงสุด 99+ |
| `2141:807715` | Chat | 1440×1024 | Chat panel — unread badges |
| `2141:807716` | Mention — Half view | 1440×1024 | Submenu 184×200 at (192, 867) |
| `2141:809999` | Chat | 1440×1024 | After mention: highlight |
| `2141:809157` | Chat | 1440×1024 | Mark all as read |
| `2146:811379` | Chat | 1440×1024 | Read state (cleared) |
| `2146:835539` | Chat | 1440×1024 | Muted conversation |
| `2146:836084` | Chat | 1440×1024 | Final state |
| `2151:841572` | Form email — message | 1920×1075 | Symbol: email digest (1 sender) |
| `2151:842899` | Form email — message | 1920×1344 | Symbol: email digest (multi sender) |

### Email Digest Sizes

| Case | Node ID | Size |
|---|---|---|
| 1 คนส่งข้อความ | `2151:841572` | 1920×1075 |
| มากกว่า 1 คนส่งข้อความ | `2151:842899` | 1920×1344 |

### Notes จาก Sticky

- **Notification สูงสุดที่ 99 เกินกว่านั้นเป็น 99+**
- **กรณีถูก Mention** → highlight สีพิเศษ
- **กรณีมีแค่ 1 คนที่ข้อความมา** vs **กรณีมีมากกว่า 1 คน** (email digest layout ต่างกัน)

### Submenu (Hover on DM/Channel) Spec

```
Submenu 184×200 at (192, 867) in Chat panel
Items: Mark as read · Hide message · Mute · Delete
Note: Group + Channel ไม่มีเมนู "Hide"
```

---

## SC-CHAT-11 · Message Search

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2162-83837  
**Section size:** 21103×6010  
**ClickUp:** https://app.clickup.com/t/86d2weamj

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2162:83842` | Channels — Half view | 1440×1024 | Base state ก่อน open search |
| `2165:106729` | Message Search — Filter | 1440×1024 | Search filter symbol 340×382 at (550, 321) |
| `2165:107227` | Message Search — Filter | 1440×1024 | Search filter instance (open) |
| `2176:177505` | Message Search — Filter | 1440×1024 | Filter expanded: Sender selected |
| `2165:107725` | Message Search — Filter | 1440×1024 | Sender dropdown open: Submenu 308×173 at (566, 553) |
| `2165:108223` | Message Search — Filter | 1440×1024 | Date picker open: 311×302 at (563, 637) |
| `2176:176964` | Message Search — Filter | 1440×1024 | Filter filled (all fields) |
| `2171:176353` | Message Search — Filter | 1440×1024 | Results list |
| `2171:172927` | Channels — Half view | 1440×1024 | Click result → navigate to message |
| `2196:224146` | Channels — Half view | 1440×1024 | กรณีค้นหาชื่อแชท DM/Group/Channel |
| `2162:88233` | Message Search (Full view) | 1440×1024 | Full view base |
| `2171:170868` | Message Search (Full view) | 1440×1024 | Filter open full view |
| `2171:171294` | Message Search (Full view) | 1440×1024 | Channel type dropdown: Submenu 308×413 at (566, 469) |
| `2176:178613` | Message Search (Full view) | 1440×1024 | Sender selected (full) |
| `2171:171808` | Message Search (Full view) | 1440×1024 | "In" dropdown: Submenu 308×215 at (566, 553) |
| `2171:172360` | Message Search (Full view) | 1440×1024 | Date picker full: 311×302 at (563, 637) |
| `2171:175736` | Message Search (Full view) | 1440×1024 | Results full view |
| `2196:224469` | Chat — Full view | 1440×1024 | Navigate to result (full) |
| `2176:180264` | Direct message — Full view | 1440×1024 | DM result navigate |

### Search Filter Panel Spec (340×382)

```
Search filter (340×382) at (550, 321):
├── Title bar (308×24)
│   ├── "Search filter" label (102×22)
│   └── Cancel ✕ button (24×24) at x=284
├── Divider (308px wide) at y=56
├── Sender input (308×68) at y=72
│   ├── Label "Sender" (308×18)
│   └── Input (308×42)
│       ├── Profile avatar (24×24) at x=12, y=9
│       ├── Name text at x=44
│       └── Chevron-Down (16×16) at x=280, y=13
├── Channel/DM input (308×68) at y=156
├── Date range input (308×68) at y=240
└── Button group (308×42) at y=324
    ├── Clear (93×42)
    └── [Search buttons] (169×42)
        ├── Button 1 (85×42)
        └── Button 2 (76×42)
```

### Submenu Dropdowns

| Filter | Node ID | Size | at (x, y) |
|---|---|---|---|
| Sender (half) | `2165:169253` | 308×413 | (4836+550, 148+553) |
| Sender (half) | `2171:170525` | 308×173 | (566, 553) |
| Chat type (full) | `2171:171719` | 308×413 | (566, 469) |
| In channel (full) | `2171:172321` | 308×215 | (566, 553) |
| Date picker (half) | `2165:104130` | 311×302 | (563, 637) |

### Notes จาก Sticky

- **Sender คือ ทุกคนใน Workspace** → สามารถพิมพ์ใน input หรือ select เลือกใน dropdown ก็ได้
- **ถ้าไม่เลือก filter chat type ก็สามารถค้นหาได้ทุกประเภท**
- **กรณีค้นหาข้อความในแชท** vs **กรณีค้นหาชื่อแชท DM Group หรือ Channel** (2 โหมด)

---

## SC-CHAT-12 · Typing Indicator

**Figma URL:** https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=2151-1217508  
**Section size:** 21103×6010  
**ClickUp:** https://app.clickup.com/t/86d2wear8

### Frame Nodes

| Node ID | Name | Size | State / หมายเหตุ |
|---|---|---|---|
| `2151:1221614` | Channels — Half view | 1440×1024 | DM: 1 คนกำลังพิมพ์ |
| `2151:1223751` | Channels — Half view | 1440×1024 | DM: 2 คนกำลังพิมพ์ |
| `2151:1226142` | Channels — Half view | 1440×1024 | DM: หยุดพิมพ์ (indicator หาย) |
| `2151:1221613` | Direct message — Full view | 1440×1024 | DM Full: 1 คน |
| `2151:1223750` | Direct message — Full view | 1440×1024 | DM Full: 2 คน |
| `2151:1226141` | Direct message — Full view | 1440×1024 | DM Full: หยุดพิมพ์ |
| `2151:1223025` | Channels — Half view | 1440×1024 | Group/Channel: ≤ 3 คน |
| `2151:1224516` | Channels — Half view | 1440×1024 | Group/Channel: 2 คน |
| `2151:1225336` | Channels — Half view | 1440×1024 | Group/Channel: > 3 คน |
| `2151:1223026` | Channels — Full view | 1440×1024 | Group/Channel Full: ≤ 3 คน |
| `2151:1224517` | Channels — Full view | 1440×1024 | Group/Channel Full: 2 คน |
| `2151:1225337` | Channels — Full view | 1440×1024 | Group/Channel Full: > 3 คน |

### Sections ใน SC-CHAT-12

| Label (text node) | แถว y | เนื้อหา |
|---|---|---|
| "Direct message" | y=1811 | DM typing rows (half + full) |
| "Group & Channel" | y=4400 | Channel/Group typing rows |

### Text Rules (จาก Sticky + Spec)

| จำนวนคนพิมพ์ | แสดงข้อความ |
|---|---|
| 1 คน | "[ชื่อ] กำลังพิมพ์..." |
| 2–3 คน | "[ชื่อ1] และ [ชื่อ2] กำลังพิมพ์..." |
| > 3 คน | "หลายคนกำลังพิมพ์..." |
| 0 คน (หยุด/timeout) | ซ่อน indicator |

### Notes จาก Sticky

- **กรณีไม่เกิน 3 คนกำลังพิมพ์** → แสดงชื่อ
- **กรณีมากกว่า 3 คนกำลังพิมพ์** → "หลายคนกำลังพิมพ์..."
- **กรณีผู้ใช้งานหยุดพิมพ์นานเกิน 3 วินาที หรือ เคลียร์ข้อความ** → typing indicator หายไปทันที

---

## Node ID Cheatsheet (สำหรับ implement)

```
เปิดใน Figma:
https://www.figma.com/design/Map8gX0L2hk7HnkaFRfhtj/?node-id=XXXX-YYYYY

แทน XXXX-YYYYY ด้วย node ที่ต้องการ เช่น:
  DM Half view master   → 2006-100547
  DM Full view master   → 2006-199495
  Channel Half master   → 2006-199494
  Channel Full master   → 2006-203715
  Threads Half master   → 2006-199097
  Threads Full master   → 2006-202457
  Chat menu structure   → ดูใน SC-CHAT-04 node 2020-524104
  Emoji reaction bar    → 2141-808931 (single row) / 2146-811284 (multi row)
  Reaction modal        → 2096-1572510
  Preview image modal   → 2122-70320
  Preview file modal    → 2116-2093971
  Search filter panel   → 2176-177505
  Email digest (1 user) → 2151-841572
  Email digest (multi)  → 2151-842899
```
