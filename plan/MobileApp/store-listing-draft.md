# Store Listing Draft — ข้อความ + คำตอบแบบฟอร์มสำหรับ App Store / Play Store

> **สถานะ:** ร่าง (draft) รอ PM ตรวจ · 2026-10-15 · Ten + Claude
> **ใช้กับ:** prod `co.zyraworld.app` (Zyra World) — UAT ใช้ TestFlight / Play internal ไม่ต้องมี listing เต็ม
> **ที่มาของคำตอบ privacy:** โค้ด zyra-app `develop` 2026-10-15 — Sentry (`@sentry/nextjs`), Mixpanel (`mixpanel-browser`, identify ด้วย user id), GA4 (`app/layout.tsx`), location (`vo-environment-tab.tsx` บันทึกพิกัดของ workspace สำหรับสภาพอากาศ), push token (FCM), LiveKit (เสียง / วิดีโอแบบ real-time) · **ถ้าเพิ่ม SDK ใหม่ต้องแก้ฟอร์มตาม**

## 1. ข้อความ listing

| ช่อง | English | ไทย |
|---|---|---|
| App name (≤30) | Zyra World | Zyra World |
| Subtitle — iOS (≤30) | Your team's virtual office | ออฟฟิศเสมือนของทีมคุณ |
| Short description — Play (≤80) | A virtual office where your team meets, talks and works together. | ออฟฟิศเสมือนที่ทีมได้เจอกัน คุยกัน และทำงานด้วยกัน |
| Keywords — iOS (≤100, คั่นด้วย ,) | virtual office,remote team,meeting,video call,workspace,coworking,hybrid work,chat | ออฟฟิศเสมือน,ทีม,ประชุม,วิดีโอคอล,ทำงานทางไกล,แชท |
| Category | Business (รอง: Productivity) | |
| Support URL | https://zyraworld.co (รอ PM ยืนยันหน้า support) | |
| Privacy policy URL | https://app.zyraworld.co/legal?section=privacy-policy | |
| Terms | https://app.zyraworld.co/legal?section=terms-of-services | |
| Account deletion URL (Play) | https://app.zyraworld.co/setting/delete-account | |

**Description (EN)**

> Zyra World brings your team together in a shared virtual office — right from your phone.
>
> • Walk into your team's space and see who's around
> • Start a voice or video call by joining a meeting room or a circle
> • Chat with teammates, send files and react
> • Get notified when someone waves at you or mentions you
> • Lite mode for quick check-ins in portrait, Spatial mode for the full map in landscape
> • Sign in with email, Google or Apple
>
> Zyra World works with the same workspaces you use on the web, so you can step away from your desk without leaving the team.

**คำอธิบาย (TH)** (description in Thai)

> Zyra World พาทีมของคุณมาอยู่ในออฟฟิศเสมือนเดียวกัน — ผ่านมือถือได้เลย
>
> • เข้าพื้นที่ของทีมแล้วเห็นว่าใครอยู่บ้าง
> • คุยเสียงหรือวิดีโอได้ทันทีเมื่อเข้าห้องประชุมหรือวงสนทนา
> • แชทกับเพื่อนร่วมทีม ส่งไฟล์ และกดรีแอ็กชัน
> • รับแจ้งเตือนเมื่อมีคนโบกมือหรือเมนชันถึงคุณ
> • โหมด Lite สำหรับเช็กอินเร็ว ๆ แนวตั้ง และโหมด Spatial สำหรับแผนที่เต็มแนวนอน
> • เข้าสู่ระบบด้วยอีเมล Google หรือ Apple
>
> ใช้ workspace เดียวกับบนเว็บ ลุกจากโต๊ะได้โดยไม่หลุดจากทีม

## 2. Apple — App Privacy (App Store Connect → App Privacy)

"Do you or your third-party partners collect data from this app?" → **Yes**

| Data type | Collected | Linked to user | Tracking | Purposes |
|---|---|---|---|---|
| Contact Info → Name | ✅ | ✅ | ❌ | App Functionality |
| Contact Info → Email Address | ✅ | ✅ | ❌ | App Functionality |
| User Content → Photos or Videos (profile picture, files in chat) | ✅ | ✅ | ❌ | App Functionality |
| User Content → Audio Data (meeting voice) | ✅ | ✅ | ❌ | App Functionality |
| User Content → Other User Content (chat messages, files) | ✅ | ✅ | ❌ | App Functionality |
| Location → Precise Location (workspace weather) | ✅ | ✅ | ❌ | App Functionality |
| Identifiers → User ID | ✅ | ✅ | ❌ | App Functionality, Analytics |
| Identifiers → Device ID (push token) | ✅ | ✅ | ❌ | App Functionality |
| Usage Data → Product Interaction (Mixpanel, GA4) | ✅ | ✅ | ❌ | Analytics |
| Diagnostics → Crash Data, Performance Data (Sentry) | ✅ | ❌ | ❌ | App Functionality |

- Tracking (ใช้ข้อมูลข้ามแอปของบริษัทอื่นเพื่อโฆษณา) = **ไม่มี** → ไม่ต้องขึ้น ATT prompt
- ⚠️ ต้องยืนยันกับทีม: เสียง / วิดีโอ meeting **ไม่ได้บันทึก** เก็บไว้ที่ server ใช่ไหม (ถ้าไม่บันทึก Apple ยังให้ติ๊ก Audio Data ได้เพราะส่งผ่าน server)

**Age rating:** ตอบ "None" ทุกข้อ ยกเว้น **User-Generated Content / Messaging = Yes** (แชท) → น่าจะได้ 12+

> ⚠️ **ความเสี่ยง Guideline 1.2 (User-Generated Content):** Apple ต้องการให้แอปที่มีแชท / เนื้อหาจากผู้ใช้มีวิธี **report** เนื้อหา และ **block** ผู้ใช้ที่ก่อกวน + ช่องทางติดต่อ · ตรวจโค้ด zyra-app develop 2026-10-15 **ไม่พบ** ฟีเจอร์ report / block user · workspace เป็นแบบเชิญเข้าทีม (ไม่ใช่ social สาธารณะ) อาจผ่านได้ถ้าอธิบายใน review notes แต่มีโอกาสโดน reject — ให้ Ten ตัดสินใจว่าจะทำปุ่ม report / block ก่อนส่ง prod หรือไม่

**Export compliance:** `ITSAppUsesNonExemptEncryption = false` ตั้งไว้แล้ว (ใช้แค่ HTTPS / WSS มาตรฐาน)

## 3. Google Play — Data safety

- Does your app collect or share user data? → **Yes** · Is all data encrypted in transit? → **Yes** · Can users request deletion? → **Yes** (ในแอป + URL ข้างบน)
- **Shared** (ส่งให้บริษัทอื่นใช้เอง) = ไม่มี — Sentry / Mixpanel / Google Analytics นับเป็น service provider ไม่ใช่ sharing

| Category → Type | Collected | Optional? | Purposes |
|---|---|---|---|
| Personal info → Name | ✅ | Required | Account management, App functionality |
| Personal info → Email address | ✅ | Required | Account management, App functionality |
| Personal info → User IDs | ✅ | Required | App functionality, Analytics |
| Location → Precise location | ✅ | Optional | App functionality |
| Messages → Other in-app messages | ✅ | Optional | App functionality |
| Photos and videos → Photos | ✅ | Optional | App functionality |
| Audio → Voice or sound recordings | ✅ | Optional | App functionality |
| Files and docs | ✅ | Optional | App functionality |
| App activity → App interactions | ✅ | Required | Analytics |
| App info and performance → Crash logs, Diagnostics | ✅ | Required | App functionality |
| Device or other IDs | ✅ | Required | App functionality (push) |

## 4. Play — declarations อื่น

| ฟอร์ม | คำตอบ |
|---|---|
| **Foreground service** (`FOREGROUND_SERVICE_MICROPHONE`, `_MEDIA_PLAYBACK`) | ใช้ระหว่างอยู่ในห้องประชุม ให้เสียงไม่ตัดเมื่อผู้ใช้สลับแอปหรือปิดจอ · ผู้ใช้เห็นแจ้งเตือน "Zyra — in a meeting" (กำลังอยู่ในประชุม) ตลอด · หยุดเมื่อออกจากห้อง · **ต้องแนบวิดีโอ** (อัดจอ: เข้าห้อง → กดโฮม → ยังพูดได้ → แจ้งเตือนค้าง → ออกห้อง แจ้งเตือนหาย) |
| App access | All or some functionality is restricted → ใส่ test account เดียวกับ §5 |
| Ads | No ads |
| Content rating (IARC) | Social / communication app · user interaction = Yes · share location = No (พิกัดไม่แสดงให้ผู้ใช้อื่น) |
| Target audience | 18+ (เครื่องมือทำงาน) |
| News app / Health / Financial / Government | No |

## 5. Review notes (App Store + Play App access)

> **ต้องเตรียมก่อน submit:** บัญชีทดสอบบน **prod** + workspace ตัวอย่างที่มีคนอื่น / ห้องประชุมให้ลอง — Ten สร้างเอง (AI สร้างบัญชีไม่ได้) · ใส่ username / password ในช่อง Sign-in information ของ App Store Connect และ App access ของ Play เท่านั้น ห้ามใส่ในเอกสารนี้

**Notes (EN):**

> Zyra World is a virtual office for teams. Sign in with the demo account below; it is a member of the workspace "Zyra Review", which has a second demo user online so you can try calls and chat.
>
> Native features in this app: push notifications (waves, mentions, chat), background audio during meetings (the call keeps running when the app is in the background), Sign in with Apple, haptic feedback, the iOS share sheet, saving images to Photos, and an offline asset pack so the office loads without downloading sounds and images again.
>
> Permissions: camera and microphone are requested only when you join a meeting; location is requested only when a workspace owner sets the workspace's location for local weather.
>
> Account deletion: Profile → Account and Security → Delete account.

## 6. Screenshots (Design — Pai)

| Store | ขนาด | จำนวน |
|---|---|---|
| iOS iPhone 6.9" | 1320 × 2868 (แนวตั้ง) | 3–10 |
| iOS iPad 13" | 2064 × 2752 — **จำเป็นถ้าไม่ปิด iPad** (`TARGETED_DEVICE_FAMILY = 1,2` ตอนนี้) | 3–10 |
| Play phone | 1080 × 1920 ขึ้นไป | 2–8 |
| Play feature graphic | 1024 × 500 | 1 |
| Play icon | 512 × 512 (มีแล้วใน `demo file/icon/512x512`) | 1 |

ฉากที่แนะนำ: เข้า workspace (Lite) · ห้องประชุมวิดีโอ · แชท · แผนที่ Spatial แนวนอน · แจ้งเตือน Wave
