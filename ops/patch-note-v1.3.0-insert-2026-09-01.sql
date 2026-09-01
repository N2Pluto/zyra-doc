-- Patch Note สำหรับ release v1.3.0 (SC-ANC-07 · tb_patch_note)
--
-- ลงเป็น state='draft' โดยเจตนา: ตอนที่เขียนนี้ prod ยังไม่มี fix (zyra-api PR #62
-- ยังไม่ merge, ยังไม่ tag) ถ้า publish ก่อน ผู้ใช้จะอ่านว่า "แก้แล้ว" ทั้งที่ของจริง
-- ยังเขียนรูปโปรไฟล์ทับอยู่ → กด Publish ในหน้า Admin หลัง deploy prod เสร็จ
--
-- เนื้อหาผ่านข้อจำกัดจริงของฟีเจอร์แล้ว: title 45/100 rune, description 698/1000 rune,
-- แท็กที่ใช้ (p/ul/li/b) อยู่ใน allowlist ของ sanitizeAnnouncementHTML ทั้งหมด จึงไม่มี
-- ส่วนไหนถูกตัดแม้จะ insert ตรงโดยไม่ผ่าน service layer
--
-- created_by = ten_dev@zyra-world.com (ADMIN) — เปลี่ยนได้ถ้าต้องการให้ผู้เขียนเป็นคนอื่น
--
-- รันซ้ำได้: WHERE NOT EXISTS กันแถวซ้ำด้วย title เดียวกัน
--   cd zyra-service && ./prod-db.sh file ../zyra-doc/ops/patch-note-v1.3.0-insert-2026-09-01.sql --write
--
-- ตรวจหลังรัน (read-only):
--   SELECT title, state, created_at FROM tb_patch_note ORDER BY created_at DESC LIMIT 3;
--
-- Publish ทีหลัง: ทำผ่านหน้า Admin (ปลอดภัยกว่า เพราะ service จะ set published_at ให้เอง
-- และ CHECK constraint บังคับว่า published ต้องมี published_at)

INSERT INTO tb_patch_note (title, description, state, created_by)
SELECT
  'รูปโปรไฟล์ไม่หายอีกแล้ว + ปรับปรุงความปลอดภัย',
  $body$<p><b>แก้ปัญหารูปโปรไฟล์หายเวลาล็อกอินใหม่</b></p>
<p>ก่อนหน้านี้ ทุกครั้งที่ล็อกอินด้วย Google ระบบจะเขียนรูปโปรไฟล์ทับด้วยรูปจากบัญชี Google ทำให้รูปที่ตั้งไว้เองหายไป ตอนนี้แก้แล้ว รูปที่คุณอัปโหลดจะอยู่ถาวร</p>
<ul>
<li>รูปโปรไฟล์ไม่หายเวลาระบบอัปเดต หรือไม่ได้เข้าใช้งานนาน ๆ</li>
<li>ชื่อที่แก้ไว้เองไม่ถูกเปลี่ยนกลับเป็นชื่อจาก Google อีก</li>
<li>สิทธิ์ผู้ดูแลระบบไม่ถูกลดเป็นสมาชิกทั่วไปเวลาล็อกอินด้วย Google</li>
</ul>
<p><b>ถ้ารูปของคุณหายไปก่อนหน้านี้</b> รบกวนอัปโหลดใหม่อีกครั้งเดียว หลังจากนี้จะไม่หายอีก</p>
<p><b>ความปลอดภัย</b> ปิดช่องโหว่เรื่องสิทธิ์การเข้าถึงลิงก์เชิญเข้า Space, การแก้ข้อมูลข้าม Space และการเข้าห้องประชุม/แชท พร้อมทำให้ระบบทนต่อไฟล์รูปที่ผิดปกติได้ดีขึ้น</p>$body$,
  'draft',
  'e91930bb-0477-4b46-9584-a908fce05285'
WHERE NOT EXISTS (
  SELECT 1 FROM tb_patch_note
   WHERE title = 'รูปโปรไฟล์ไม่หายอีกแล้ว + ปรับปรุงความปลอดภัย'
);
