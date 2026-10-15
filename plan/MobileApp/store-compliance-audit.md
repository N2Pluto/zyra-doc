# Store Compliance Audit — เทียบกฎ App Store / Google Play

> **สถานะ:** ยังไม่พร้อมส่ง prod review — พบ GAP ที่น่าจะโดน reject 6 ข้อ · ตรวจ 2026-10-15 · Ten + Claude
> **ตรวจจาก:** zyra-mobile `develop` 270a652 · zyra-app `develop` 15ebd648 · zyra-api `develop` 869d825 · archive Zyra UAT 1.0.0 (1) ที่ upload ขึ้น TestFlight แล้ว
> **ไม่ได้ตรวจ:** merged AndroidManifest / AAB จริง (เครื่องนี้ไม่มี JDK) · ทดสอบบนเครื่องจริง
> **ใช้คู่กับ:** [store-release-checklist.md](store-release-checklist.md) · [store-listing-draft.md](store-listing-draft.md)

UAT ที่แจกผ่าน TestFlight internal / Play internal **ไม่ต้องผ่าน review** — รายการนี้บล็อกเฉพาะการส่ง **prod** (และ TestFlight external ถ้าจะเปิด)

## ต้องแก้ก่อนส่ง prod (เรียงตามความเสี่ยง)

| # | เรื่อง | กฎ | หลักฐาน | วิธีแก้ | Repo |
|---|---|---|---|---|---|
| 1 | หน้า **Upgrade plan** เปิดได้บนมือถือตอน workspace เต็ม — ปุ่ม "Upgrade Now" กดแล้วไม่เกิดอะไร · ข้อความ placeholder "Unlock feature {n}" · ราคา "฿ 1,000" hardcode | Apple 2.1 (ของไม่เสร็จ) + 3.1.1 (แสดงราคาโดยไม่ใช้ IAP) | `workspace-capacity-modals.tsx:556`, `messages/en.json:348`, `hero-user-workspace.tsx:450` | ซ่อนเส้นทาง Upgrade / ราคา เมื่อ `isNativeApp()` (`lib/platform.ts:48`) | zyra-app |
| 2 | ไม่มี **report / block** ผู้ใช้ หรือเนื้อหา | Apple 1.2 · Play User Generated Content policy | ไม่พบใน zyra-app / zyra-api | เพิ่ม Report ข้อความ / โปรไฟล์ + Block user (หรือเสี่ยงอธิบายว่า workspace เป็นแบบเชิญเท่านั้น) — **ต้องตัดสินใจ product** | zyra-app + zyra-api |
| 3 | **Facebook SDK ติดมาในแอป** (มาจาก `@capgo/capacitor-social-login`) — iOS archive มี `FBSDKCoreKit`, `FBSDKLoginKit`, `FBAEMKit` · privacy manifest ของ Facebook ประกาศ tracking = true · Android น่าจะดึง `AD_ID` permission | Apple 5.1.2 / ATT · Play Data safety / Ads ID | `App.app/Frameworks/FBSDK*` ใน archive · `gradle.properties` ไม่ได้ตั้ง `socialLogin.facebook.include` | Android: `socialLogin.facebook.include=false` · iOS: patch / fork plugin ตัด Facebook ออก (ไม่ใช้ Facebook login อยู่แล้ว) | zyra-mobile |
| 4 | ไม่มี **PrivacyInfo.xcprivacy** ของแอป — plugin ใช้ UserDefaults (social-login) และ file timestamp (filesystem) | Apple privacy manifest (ITMS-91053) | ไม่พบไฟล์ใน `ios/App/App` | เพิ่ม `PrivacyInfo.xcprivacy` ประกาศ `NSPrivacyAccessedAPICategoryUserDefaults` (CA92.1) + `FileTimestamp` (C617.1) + data types ตาม store-listing-draft §2 | zyra-mobile |
| 5 | **Privacy policy** กว้างเกินไป — ไม่พูดถึงแอปมือถือ, กล้อง / ไมค์, location, push, vendor (Sentry, Mixpanel, GA4, Firebase, LiveKit), session replay, ระยะเก็บข้อมูล, วิธีลบบัญชี, ช่องทางติดต่อ | Apple 5.1.1(i) · Play User Data policy | `messages/en.json:4080-4093` (อัปเดต 06 May 2026) | เขียนใหม่ให้ตรงกับคำตอบ App Privacy / Data safety — **PM / legal** | zyra-app (ข้อความ) |
| 6 | Google login บน iOS **prod** ไม่มี iOS client id → fallback เป็น popup เว็บ น่าจะค้างใน Safari | Apple 2.1 (login ใช้ไม่ได้) | `flavors.json` prod `iosGoogleClientId: ""` | สร้าง OAuth iOS client ของ prod + ใส่ `flavors.json` + secret `NEXT_PUBLIC_GOOGLE_IOS_CLIENT_ID` ใน env `production` ของ zyra-app | zyra-mobile + config |
| 7 | ลบบัญชีแล้ว **ไม่ revoke Apple token** | Apple 5.1.1(v) (Sign in with Apple) | zyra-api ไม่มี call `appleid.apple.com/auth/revoke` | ส่ง authorization code ไป api → แลก refresh token ด้วย `.p8` → revoke ใน `DELETE /me` | zyra-app + zyra-api |
| 8 | ~~**iPad** เปิดอยู่แต่ยังไม่ได้ QA~~ | Apple 2.1 / 4.0 | — | ✅ **มติ Ten 2026-10-15: iPhone อย่างเดียวรอบแรก** — `TARGETED_DEVICE_FAMILY = 1` (zyra-mobile#17) · iPad ยังติดตั้งได้แบบ iPhone compatibility mode (Guideline 2.4.1) · ไม่ต้องมี screenshot iPad · เปิด iPad ได้ในเวอร์ชันถัดไป | zyra-mobile |

## ตรวจก่อน upload prod

- `aps-environment` = `production` ใน IPA ที่ export (archive เป็น `development` ตามปกติ)
- merged AndroidManifest ไม่มี `com.google.android.gms.permission.AD_ID` (หลังแก้ข้อ 3)
- AAB ผ่าน 16 KB page size (APK Analyzer)
- PM sign-off ข้อความ permission ที่ยังเป็น draft (photo add, location, ภาษาไทย)
- Sentry / Mixpanel **session replay** + GTM container — ตรวจว่าไม่มี tag โฆษณา / Google Signals และประกาศใน Data safety
- zyra-app ต้องขึ้น prod (tag `v*`) ก่อน — แอป prod โหลดเว็บ prod

## ผ่านแล้ว

| เรื่อง | หลักฐาน |
|---|---|
| Sign in with Apple ขึ้นคู่กับ Google บน iOS (4.8) | `card-login.tsx:438,647,841` |
| ลบบัญชีในแอปได้ทั้ง Lite / Spatial (5.1.1(v)) | `lite-profile-pages.tsx:78,86`, `vo-phone-profile-pages.tsx:94`, API `DELETE /api/user/me` |
| Permission strings ครบตามที่ใช้ (กล้อง, ไมค์, บันทึกรูป, location) | `Info.plist:48-55` + `th.lproj` |
| Native features พอสำหรับ 4.2 (push, background audio, haptics, share, asset pack, deep / universal links, keep-awake, native Google / Apple sign-in, foreground service) | ดู store-listing-draft §5 |
| Build: Xcode 27 / iOS SDK 27, arm64, minimum iOS 17.5 · Android target / compile SDK 36, minSdk 24, AGP 8.13 | |
| Encryption flag `false` · background mode เฉพาะ `audio` | `Info.plist:44,77` |
| SDK privacy manifests ของ Capacitor, Firebase, GoogleSignIn มีครบ | archive `App.app` |
| Play: notification permission ขอ runtime · storage write จำกัด ≤ Android 9 · ไม่มี READ_MEDIA_* | `AndroidManifest.xml:59-77`, `push.ts:61` |
| Play org account → **ไม่ต้อง** closed test 12 คน 14 วัน (กฎนี้ใช้กับบัญชีส่วนตัว) | บัญชี Maximumsoft เป็น Organization |

## หลังเปิดตัวได้ (ไม่บล็อก)

- `assetlinks.json` + Android App Links `autoVerify`
- push channel ของ Android ตั้งชื่อเอง (ตอนนี้ลง default channel)
- หน้า maintenance ลิงก์ไป `https://zyra.center/` (โดเมนเก่า) — `hero-maintenance.tsx:18`
