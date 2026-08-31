-- ============================================================
-- ZYRA prod schema diagnostic
-- รันบน DB ของ prod:  psql "$PROD_DATABASE_URL" -f prod_schema_check.sql
-- report ออกมาเป็น 2 ส่วน: (1) ตารางที่ขาด  (2) คอลัมน์ที่ขาด
-- ============================================================

-- (1) ตารางที่คาดว่าต้องมี แต่ยังไม่มีใน prod
WITH expected(tbl) AS (
  VALUES
    ('tb_user'),('tb_authen'),('tb_workspace'),('tb_map'),('tb_map_object'),
    ('tb_workspace_member'),('tb_workspace_invite'),('tb_workspace_join_request'),
    ('tb_zone_section'),('tb_zone_section_member'),
    ('tb_object'),('tb_object_image'),('tb_object_information'),('object_compositions'),
    ('tb_avatar'),('tb_avatar_audit_log'),('tb_user_avatar'),
    ('tb_map_template'),('tb_map_template_category'),('tb_map_version'),
    ('tb_map_zone'),('tb_workspace_version'),('tb_workspace_audit_log'),
    ('tb_private_zone_access_log'),('tb_private_zone_claim'),
    ('tb_conversation'),('tb_conversation_member'),('tb_message'),
    ('tb_message_attachment'),('tb_message_reaction'),('tb_user_last_read'),
    ('tb_notification'),('user_activities')
)
SELECT '❌ MISSING TABLE' AS issue, e.tbl AS object
FROM expected e
LEFT JOIN information_schema.tables t
  ON t.table_schema = 'public' AND t.table_name = e.tbl
WHERE t.table_name IS NULL
ORDER BY e.tbl;

-- (2) คอลัมน์ที่ ALTER migration เพิ่ม แต่ prod ยังไม่มี
--     (เช็คเฉพาะ column ที่ table นั้นมีอยู่จริง)
WITH expected_col(tbl, col) AS (
  VALUES
    ('tb_user','last_login_at'),('tb_user','last_login_ip'),
    ('tb_user','last_password_reset'),('tb_user','locked_until'),
    ('tb_user','login_attempts'),('tb_user','otp_attempts'),
    ('tb_map','is_main'),('tb_map','status'),
    ('tb_avatar','deleted_at'),('tb_avatar','is_deleted'),('tb_avatar','thumbnail_url'),
    ('tb_conversation','description'),('tb_conversation','icon_url'),
    ('tb_message','is_thread_reply'),
    ('tb_notification','email_suppressed'),
    ('tb_workspace','owner_id'),('tb_workspace','published_thumbnail_url'),
    ('tb_zone_section','is_locked')
)
SELECT '⚠️  MISSING COLUMN' AS issue, ec.tbl || '.' || ec.col AS object
FROM expected_col ec
JOIN information_schema.tables t
  ON t.table_schema = 'public' AND t.table_name = ec.tbl
LEFT JOIN information_schema.columns c
  ON c.table_schema = 'public' AND c.table_name = ec.tbl AND c.column_name = ec.col
WHERE c.column_name IS NULL
ORDER BY ec.tbl, ec.col;
