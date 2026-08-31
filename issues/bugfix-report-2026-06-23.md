# Bug Fix Report — Jun 23, 2026

---

## Issue SC-SB-10 (1/2) — Email Invite: Last visited แสดงข้อมูลไม่ถูกต้อง

**Symptom:**  
ใน Manage Members modal คอลัมน์ "Last active" แสดงวันที่ผิด (แสดงวันที่ join แทนวันที่ใช้งานล่าสุด)

**Root Cause — 2 bugs:**

| # | ไฟล์ | บรรทัด | Bug |
|---|------|--------|-----|
| 1 | `zyra-api/internal/service/workspace_member_service.go` | ~112 | SQL query hardcode `NULL::TIMESTAMPTZ AS last_active` แทนที่จะใช้ `wm.last_visited_at` ทำให้ API ส่งค่า `null` เสมอ |
| 2 | `zyra-app/views/user/virtual-office/components/manage-members-modal.tsx` | ~56 | `toUIMember()` ใช้ `m.joined_at` (วันที่ accept invite) แทน `m.last_active` |

**Fix:**
- Backend: เปลี่ยน `NULL::TIMESTAMPTZ` → `wm.last_visited_at AS last_active` ใน confirmed members subquery
- Frontend: เปลี่ยน `if (m.joined_at)` → `if (m.last_active)` ใน `toUIMember()`

---

## Issue SC-SB-10 (2/2) — Email Invite: Link ครั้งแรกยังใช้งานได้หลัง Resend

**Symptom:**  
Owner กด Resend invite → user กด link เก่า (ส่งครั้งแรก) → ยังสามารถ join workspace ได้

**Root Cause:**

| # | ไฟล์ | บรรทัด | Bug |
|---|------|--------|-----|
| 1 | `zyra-api/internal/service/workspace_member_service.go` | `ResendInvite()` | ฟังก์ชัน ResendInvite แค่ reset `expires_at` แต่ **ไม่ได้เปลี่ยน token** → link เก่ากับ link ใหม่เป็น URL เดียวกัน |

**Fix:**  
ใน `ResendInvite()` generate token ใหม่ (`newToken`) แล้วอัปเดต `token` และ `expires_at` พร้อมกัน → link เก่า (token เก่า) หายออกจาก DB ทันที ผู้ใช้ที่กด link เก่าจะได้ `ErrInviteNotFound`

---

## Issue SC-VO-01 — List Workspace: Admin แสดงสิทธิ์เป็น Owner

**Symptom:**  
Admin รับ invite สมัคร Google account → เข้า workspace → ออกมาหน้า workspace list → badge แสดง "Owner" แทน "Admin"

**Root Cause — 2 bugs (cascading):**

| # | ไฟล์ | บรรทัด | Bug |
|---|------|--------|-----|
| 1 | `zyra-app/views/login/components/card-login.tsx` | ~228–233 | Google login handler hardcode redirect เป็น `/signup/google-success` หรือ `/` เสมอ — ทำให้ `redirect_url=/join/{token}` ที่ส่งมาจาก invite page หายไป → invite ไม่ถูก accept → ไม่มี row ใน `tb_workspace_member` |
| 2 | `zyra-api/internal/service/workspace_presence_service.go` | `savePresenceState()` | Heartbeat ใช้ UPSERT ด้วย `role_ = 'owner'` → ถ้าผู้ใช้เข้า workspace โดยยังไม่มี member row จะถูก insert เป็น `role_ = 'owner'` → ต่อมา `AcceptInviteByToken` รัน `ON CONFLICT DO NOTHING` → role 'owner' ถูกเก็บไว้ในฐานข้อมูล |

**Fix:**

| # | ไฟล์ | การแก้ไข |
|---|------|---------|
| 1 | `card-login.tsx` | หลัง Google login success อ่าน `redirect_url` จาก `window.location.search` แล้ว validate same-origin → redirect ไปที่ `redirect_url` ถ้ามี (ข้าม google-success page สำหรับ new user ที่มี redirect_url) |
| 2 | `workspace_presence_service.go` | เปลี่ยน UPSERT → plain `UPDATE` เท่านั้น — heartbeat ทำหน้าที่แค่อัปเดต `last_visited_at` และ position สำหรับ row ที่มีอยู่แล้ว ไม่สร้าง member row ใหม่ |

---

## Summary

| Issue ID | หัวข้อ | ไฟล์ที่แก้ | สถานะ |
|----------|--------|-----------|-------|
| SC-SB-10 (1/2) | Last visited แสดงข้อมูลผิด | `workspace_member_service.go`, `manage-members-modal.tsx` | ✅ Fixed |
| SC-SB-10 (2/2) | Link invite เก่ายังใช้งานได้หลัง resend | `workspace_member_service.go` | ✅ Fixed |
| SC-VO-01 | Admin แสดงเป็น Owner ใน workspace list | `card-login.tsx`, `workspace_presence_service.go` | ✅ Fixed |

---

*แก้ไขโดย AI Agent — Jun 23, 2026*
