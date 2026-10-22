# Meeting PIP — Outside display ตอนอยู่ใน meeting (SC-RTE-012)

> **สถานะ:** implemented บน `zyra-app@feat/vo-meeting-pip` (ยังไม่ commit) · 2026-10-11
> **Figma:** [SC-RTE-012 · Meeting PIP — node 7143:750022](https://www.figma.com/design/4SQDUkxARPaqDynY2IH6kt/Zyra-design--More-Organised-ver.---Copy-?node-id=7143-750022)

## Requirement ต้นทาง (ผู้ใช้ 2026-10-11 + sticky note ใน Figma)

1. PiP ตอนออกไป tab อื่น ปกติ (ไม่ได้คุยกับใคร) = เหมือนเดิม (minimap) ไม่แก้
2. อยู่ใน meeting → เปลี่ยนเป็น layout meeting (tile ผู้เข้าร่วม)
3. ผู้ใช้ลากขอบ PiP ย่อ/ขยายได้ — ย่อจนสุด = tile ตัวเอง + "more participants" (Display รวม); กด Display รวม → กลับไปที่ meeting
4. ค่อย ๆ ยืด → "more participants" ลดลงเพราะโชว์คนได้มากขึ้น
5. มีการแชร์จอ → จอที่แชร์อยู่บนสุดเสมอ โชว์เดี่ยว ๆ
6. มีคนมาคุยด้วย (proximity circle) ตอนอยู่ใน workspace → เปลี่ยนเป็น layout meeting ด้วย
7. Sticky: "ให้ขนาดเท่ากับ Mini map" (เปิดที่ 340×280 เหมือนเดิม) · ระบบกำหนด layout ให้ ผู้ใช้ปรับขนาดเองด้วยการลากขอบ

## Implementation

- `views/user/virtual-office/components/vo-outside-meeting.tsx` (ใหม่) — grid: แถว 132px, 2 คอลัมน์ (เลขคี่ = tile แรกอยู่แถวเดี่ยวกึ่งกลางครึ่งความกว้าง), จอแคบ+สูง (<400px และ ≥3 แถว) = 1 คอลัมน์, ล้น = คนอื่นก่อน → ตัวเอง → tile "more participants" (facepile 4 + "+N"), share screen แถวบนสุดเต็มความกว้าง · reuse `CompactDisplayCard` / `ScreenVideo` / `VOAvatar`
- `vo-outside-display.tsx` — prop `meeting` + `onReturnToMeeting`; แยก control bar เป็น `OutsideControlBar` ใช้ร่วมสองโหมด; โหมด meeting scale ลงอย่างเดียว (ขยายหน้าต่าง = เห็นคนมากขึ้น ไม่ใช่ tile ใหญ่ขึ้น)
- `hero-virtual-office.tsx` — `circleParticipants` (ย้ายจาก IIFE ของ circle panel มาเป็น memo ใช้ร่วม) + `outsideMeetingParticipants` (meeting zone / private ≥2 / circle — เงื่อนไขเดียวกับ meeting panel ในหน้า) + `handleOutsideReturnToMeeting` (focus tab office + ปิด PiP)
- i18n: `pipMoreParticipants`, `pipBackToMeeting` (en/th)

## Assumption / ต่างจาก Figma

- ค่า spacing ของ tile "more participants" และ share tile อ่านจากภาพ (Figma MCP ติด rate limit Starter plan ระหว่างดึง) — tile ปกติ/header/bar ใช้ค่าจาก `get_design_context` 7143:749280
- "+N" = จำนวนที่ซ่อนลบจำนวนหน้าที่โชว์ (โชว์สูงสุด 4 หน้า)
- กด "more participants" = focus tab office + ปิด PiP (เหมือนปุ่ม "back to tab" ของ browser) ไม่ได้ขยาย meeting panel ให้อัตโนมัติ
- control bar ยังโชว์ตลอด (ตาม Mini display เดิม) — sticky "ตอน Hover ให้มี Menu เดียวกันกับ Mini display" ตีความว่าใช้ bar ชุดเดียวกัน
- Spotlight ไม่เปลี่ยน PiP (มี stage ของตัวเอง)

## Progress

- ✅ implement + unit test (`__tests__/vo-outside-display.test.tsx` +7 case) — related suites 7 ไฟล์ 502 passed
- ✅ `tsc` ไม่มี error ใหม่ (42 บรรทัด pre-existing เท่า baseline develop) · eslint ไฟล์ที่แก้ผ่าน · `git diff --check` ผ่าน
- ⏳ ยังไม่ได้ทดสอบจริงใน browser (ต้อง Chrome + 2 account + meeting จริง + Document PiP)
- ⏳ ยังไม่ commit / push / PR
