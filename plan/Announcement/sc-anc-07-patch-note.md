# SC-ANC-07 — Patch Note Announcement

> สร้าง 2026-08-27 · branch `feat/sc-anc-07-patch-notes` (zyra-api + zyra-app)

เมื่อ client ตรวจพบ build ใหม่ (กลไก `/api/version` + `NEXT_PUBLIC_BUILD_ID` เดิมของ
`components/version-check-modal.tsx`) และมี **Patch note** published อยู่ → แสดง modal
ประกาศ (Figma 5291:281002 — ไม่มีรูป ตามที่ตัดสินใจ 2026-08-27) แทน takeover บังคับ reload
เดิม; **ไม่มี auto-reload ใดๆ** ปิดแล้วจบ (localStorage `zyra_seen_patch_notes`) และผู้ใช้ได้
build ใหม่ตอน refresh ปกติ ปุ่ม **See more new update** (มีเฉพาะใน Virtual Office) เปิด
Help Center → หมวดใหม่ **Patch notes** (list + detail จาก API ตรงๆ)

## สถาปัตยกรรมย่อ

- `tb_patch_note` (migration **85**) — system-wide ไม่ผูก workspace, lifecycle แค่
  `draft|published`, ไม่มี schedule/ack/images; แชร์ HTML sanitizer + caps (100/1,000)
  กับ announcement
- Routes: member อ่าน `/api/user/patch-notes` (+`/latest`, `/:id`) ผ่าน UserGuard;
  ทีม Zyra เขียนผ่าน `/api/admin/patch-notes` (AdminGuard) — authoring UI ที่
  `/admin/patch-notes` (sidebar หมวด Support)
- Rich text editor ถูก extract เป็น `components/rich-text/rich-text-editor.tsx`
  (ใช้ร่วม announcement form + patch note form)
- Fallback: build ใหม่แต่ไม่มี patch note published (หรือ fetch ล้มเหลว/ยัง deploy api
  ไม่ทัน/หน้า unauthenticated) → กลับไปใช้หน้าต่าง Reload เดิม ไม่มีพฤติกรรมเปลี่ยน

## ⚠️ Release runbook

**ทีมต้อง publish patch note ก่อนหรือพร้อมกับ deploy release นั้น** — ไม่มี scheduling,
publish = ผู้ใช้เห็นทันทีที่ client ตรวจพบ build ใหม่; ถ้าไม่ publish ผู้ใช้จะเจอหน้าต่าง
Reload แบบเดิมแทน

ลำดับ deploy: migration 85 (psql) → zyra-api → zyra-app

## Verified (2026-08-27, local + dev DB)

- Go table-driven tests + Vitest 4 suites (94 files ผ่านทั้งหมด), `npx tsc --noEmit` ผ่าน
- Live API: guard separation (member 403 บน admin route), draft มองไม่เห็นจาก member
  (404), sanitizer ตัด `<script>`, publish stamps `published_at` ครั้งเดียว, junk id → 404
- Browser E2E (app:3100 + ws:3103): modal ไม่มี banner + ปุ่มตาม Figma, นอก VO ไม่มีปุ่ม
  See more, ใน VO See more → Help Center เปิดที่ Patch notes → detail → back ครบ,
  ปิดแล้วไม่เด้งซ้ำ, ไม่มี note → takeover เดิม
