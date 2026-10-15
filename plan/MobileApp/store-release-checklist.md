# Store Release Checklist — App Store + Play Store (UAT → PROD)

> **สถานะ:** เตรียมความพร้อม — โค้ด / config ฝั่ง dev ทำแล้ว (PR ด้านล่าง) · งานใน console ยังไม่เริ่ม
> **อัปเดตล่าสุด:** 2026-10-15 · Ten + Claude
> **Repo ที่กระทบ:** zyra-mobile, zyra-app, zyra-infra
> **ต่อจาก:** task-breakdown §K (1.12 release CI, 1.13 store listing) · spec Phase 1 acceptance criteria

## มติ (Ten 2026-10-15)

| เรื่อง | มติ |
|---|---|
| บัญชี | มี Apple Developer (Team `Z8TW83PNG3`) + Google Play Console แล้ว |
| UAT | **app แยก** `co.zyraworld.app.uat` ("Zyra UAT") — แจกผ่าน TestFlight internal + Play internal testing เท่านั้น ไม่ขึ้น public |
| PROD | `co.zyraworld.app` ("Zyra World") — ส่ง review จริง |
| วิธี build | รอบแรก **manual** (Xcode archive / Gradle AAB) — release CI (task 1.12) ทำทีหลัง |

> ⚠️ แอปเป็น **remote URL mode** — แอป prod เปิด `https://app.zyraworld.co` ดังนั้นฟีเจอร์ mobile ใน zyra-app
> ต้องขึ้น prod (tag `v*`) **ก่อน** ส่ง prod review ไม่งั้น reviewer จะเห็นเว็บ prod เวอร์ชันเก่า
> (ตอนนี้ develop นำ main อยู่หลายสิบ commit — ดู progress รอบ 63)

## 1. โค้ด / config ที่ทำแล้ว

| Repo | PR | เปลี่ยนอะไร |
|---|---|---|
| zyra-mobile | `feat/store-release-prep` | `version.json` = ที่เดียวที่กำหนด version / build (iOS ผ่าน `flavor.xcconfig`, Android `versionName` / `versionCode`) · `DEVELOPMENT_TEAM = Z8TW83PNG3` ใน xcconfig · `UIRequiredDeviceCapabilities` → `arm64` · Android `signingConfigs.release` อ่านจาก `android/keystore.properties` หรือ env `ZYRA_UPLOAD_*` (ไม่มี = release ไม่ sign, debug เหมือนเดิม) · `npm run bundle:uat` / `bundle:prod` |
| zyra-app | `fix/mobile-legal-links` | ลิงก์ `/legal/terms`, `/legal/privacy` (404) ใน lobby / welcome space ทั้ง mobile และ desktop → `/legal?section=terms-of-services` / `privacy-policy` — reviewer เปิดลิงก์ privacy ในแอปเสมอ |
| zyra-infra | `chore/api-mobile-version-keys` | เพิ่ม key `APP_IOS_MIN_VERSION`, `APP_IOS_LATEST_VERSION`, `APP_IOS_STORE_URL`, `APP_ANDROID_*` (3 ตัวเหมือนกัน) ใน `secret-templates/{uat,prod}/api.json` (ชื่อ key เท่านั้น) · `APPLE_CLIENT_IDS` มีแล้วจาก zyra-infra#50 |

## 2. Phase UAT — ทำก่อน

| # | งาน | ใคร | สถานะ |
|---|---|---|---|
| U1 | App Store Connect: ลงทะเบียน Bundle ID `co.zyraworld.app.uat` (capabilities: Sign in with Apple, Push Notifications, Associated Domains) + สร้าง app "Zyra UAT" | Ten / PM | ☐ |
| U2 | Play Console: สร้าง app "Zyra UAT" package `co.zyraworld.app.uat` · เปิด Play App Signing | Ten / PM | ☐ |
| U3 | สร้าง upload keystore (ครั้งเดียว ใช้ทั้ง uat + prod) — คำสั่งใน §4 · เก็บไฟล์ + รหัสใน password manager ของทีม **ห้าม commit** | Ten | ☐ |
| U4 | Firebase: register iOS + Android app `.uat` ใน project `gather-dev-458614` → วาง `android/app/src/uat/google-services.json` + `ios/App/App/firebase/uat/GoogleService-Info.plist` · **ห้ามลบ project** (มี prod อยู่ด้วย) · ต้องได้ OK จาก Ten ก่อน (เคยถูกบล็อกว่าแตะ prod) | Ten | ☐ |
| U5 | Google OAuth (GCP Credentials): iOS client `co.zyraworld.app.uat` → ใส่ `iosGoogleClientId` ใน `flavors.json` · Android client ใส่ SHA-1 ทั้ง **upload key** และ **app signing key** (จาก Play Console → App integrity) | Ten / Dev | ☐ |
| U6 | Apple: ใส่ `co.zyraworld.app.uat` ใน `APPLE_CLIENT_IDS` ของ zyra-api **uat** secret → รอ ≥5 นาทีให้ ESO sync ก่อน bump env-secret-version | Ten | ☐ |
| U7 | APNs: key `ZY4T34858Q` อัปโหลดใน Firebase แล้ว — เช็คว่าครอบ app ใหม่ | Ten | ☐ |
| U8 | เปิด push บน uat web (`NEXT_PUBLIC_PUSH_ENABLED` ใน GitHub Environment `uat` ของ zyra-app) หลัง U4 เสร็จ | Dev | ☐ |
| U9 | Build + upload (§3) → TestFlight internal / Play internal testing | Dev | ☐ |
| U10 | ทดสอบบนเครื่องจริง (§5) · บันทึกผลใน progress.md | QA / Dev | ☐ |

## 3. วิธี build manual

ต้องอยู่บน branch ที่ merge PR ข้างบนแล้ว · `npm ci` ก่อน · **sync flavor เดียวกับที่จะ build เสมอ** (iOS ไม่มี scheme แยก — build flavor ที่ sync ล่าสุด)

**Version:** แก้ `version.json` ที่เดียว — `build` ต้องเพิ่มทุกครั้งที่ upload (store ไม่รับเลขซ้ำ) · `version` ตาม tag `v*` ของรอบ release

### iOS (Xcode)

```bash
npm run sync:uat
open ios/App/App.xcodeproj
```

Xcode → เลือก **Any iOS Device (arm64)** → Product → Archive → Distribute App → **App Store Connect** → Upload
(prod: `npm run sync:prod` แล้วทำซ้ำ)

เช็คก่อน upload — ใน Organizer คลิกขวา archive → Show in Finder แล้ว:

```bash
codesign -d --entitlements :- "<archive>.xcarchive/Products/Applications/App.app"
```

ต้องเห็น `aps-environment` = `production` หลัง export (ไฟล์ `App.entitlements` ตั้ง `development` ไว้ — Xcode เปลี่ยนให้ตอน distribute; ถ้าไม่เปลี่ยน → แยก `App.release.entitlements`)

### Android (AAB)

```bash
cp android/keystore.properties.example android/keystore.properties   # แล้วใส่ path + รหัส
npm run bundle:uat
```

ไฟล์: `android/app/build/outputs/bundle/uatRelease/app-uat-release.aab` → Play Console → Testing → Internal testing → Create release
เช็ค signing:

```bash
jarsigner -verify -verbose -certs android/app/build/outputs/bundle/uatRelease/app-uat-release.aab | tail -5
```

## 4. Upload keystore (ครั้งเดียว)

```bash
keytool -genkeypair -v -keystore zyra-upload.jks -storetype pkcs12 -alias upload -keyalg RSA -keysize 2048 -validity 10000
keytool -list -v -keystore zyra-upload.jks -alias upload   # เอา SHA-1 / SHA-256 ไปใส่ OAuth (U5)
```

ใช้ Play App Signing → ถ้าทำ upload key หาย ขอ reset ได้ (key จริงที่ sign ให้ผู้ใช้อยู่ที่ Google)

## 5. ทดสอบบนเครื่องจริง (ก่อนขึ้น PROD)

| เคส | iOS | Android |
|---|---|---|
| ติดตั้ง Zyra UAT คู่กับ Zyra Dev ได้ | ☐ | ☐ |
| Login: email / Google / Apple (iOS) | ☐ | ☐ |
| เข้า workspace · Lite + Spatial | ☐ | ☐ |
| Meeting: กล้อง + ไมค์ · พับจอแล้วเสียงยังอยู่ (foreground service / background audio) | ☐ | ☐ |
| Push (Wave / แจ้งเตือน) ตอนแอปอยู่ background | ☐ | ☐ |
| ลบบัญชี (Lite Profile → Delete account) | ☐ | ☐ |
| ลิงก์ Terms / Privacy ไม่ 404 | ☐ | ☐ |
| Permission prompts ขึ้นข้อความถูก (EN / TH) | ☐ | ☐ |

## 6. Phase PROD — หลัง UAT ผ่าน + zyra-app ขึ้น prod

| # | งาน | ใคร | สถานะ |
|---|---|---|---|
| P1 | ทำ U1–U8 ซ้ำสำหรับ `co.zyraworld.app` (ใช้ upload key ตัวเดิม) · `APPLE_CLIENT_IDS` ใน **prod** secret | Ten | ☐ |
| P2 | Store listing: ชื่อ, subtitle, คำอธิบาย (EN + TH), keywords, support URL, marketing URL | PM | ☐ |
| P3 | Screenshots: iPhone 6.9" + 6.5" (iPad ถ้าเปิด `TARGETED_DEVICE_FAMILY` = 1,2 ไว้ — ตอนนี้เปิดอยู่ → ต้องมี iPad 13" ด้วย หรือปิด iPad) · Android phone · Play feature graphic 1024×500 | Design (Pai) | ☐ |
| P4 | Apple: App Privacy (data types: email, name, user content, audio/video ระหว่าง meeting, location coarse, device ID สำหรับ push) · Age rating · Export compliance (ตั้ง `ITSAppUsesNonExemptEncryption = false` แล้ว) | PM | ☐ |
| P5 | Apple review notes: **test account + workspace ตัวอย่าง** ที่มีคนอื่น / object ให้ลอง · อธิบาย native features (push, background audio, Sign in with Apple, haptics, share, asset pack) — กัน Guideline 4.2 (technical-design §3.2) | Dev / PM | ☐ |
| P6 | Play: Data safety form · Foreground service declaration (`microphone` + `mediaPlayback` + วิดีโอสั้นอธิบาย) · Account deletion URL (`https://app.zyraworld.co/setting/delete-account`) · Content rating · Target audience · App access (test account เดียวกับ P5) | PM | ☐ |
| P7 | Sign-off ข้อความ permission ที่ยังเป็น draft (photo library, location, ภาษาไทยทั้งหมด) | PM / Design | ☐ |
| P8 | หลังได้ store URL: ใส่ `APP_IOS_STORE_URL` / `APP_ANDROID_STORE_URL` + `*_MIN_VERSION` / `*_LATEST_VERSION` ใน prod secret (force-update gate) | Ten | ☐ |
| P9 | Submit for review ทั้งสองฝั่ง · Apple ตั้ง **Manual release** (ปล่อยเองหลังผ่าน) | Ten | ☐ |

## 7. Follow-up (ไม่บล็อก submit)

- Android App Links (`autoVerify` + `/.well-known/assetlinks.json` ด้วย SHA-256 ของ app signing key) — ทำหลัง U2/P1
- Release CI (task 1.12) — fastlane + GitHub Actions upload TestFlight / Play internal
- Apple token revoke ตอนลบบัญชี (ต้องใช้ `.p8`)
- `zyra-mobile/README.md` หัวข้อ Placeholders ยังเก่า (icon / splash เปลี่ยนแล้วใน #4, #7)
