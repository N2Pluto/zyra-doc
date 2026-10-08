# Mobile App — Asset store (เก็บรูป/เสียงบนเครื่อง ไม่โหลดซ้ำ)

> **สถานะ:** A0 ทดสอบบน iPhone แล้ว (2026-10-08) · A1–A3 ยังไม่เริ่ม · **repo:** zyra-app (`lib/native/asset-store.ts`, `zyra-engine/pixi-game/utils.ts`, `app/api/img`) · zyra-mobile (`@capacitor/filesystem`) · zyra-api (`/api/app/config`) · **คนล่าสุด:** Ten + Claude

## โจทย์

Ten (2026-10-08): "แอปมือถือเก็บ package รูป/ไฟล์ไว้ในแอปเลย ไม่ต้องโหลดมาใช้ ทำได้ไหม"

คำตอบสั้น: **ฝังทุกอย่างในไบนารีไม่เหมาะ** เพราะวัตถุ แผนที่ avatar สัตว์เลี้ยง เป็น catalog จาก DB ที่ admin อัปโหลดได้โดยไม่ต้องออกแอปใหม่ — ฝังแล้วของจะเก่าทันทีที่ admin อัปโหลด และต้องส่ง store review ทุกครั้งที่ art เปลี่ยน · ที่ทำได้จริงและตรงเจตนา คือ **โหลดครั้งเดียวต่อเครื่องแล้วเก็บถาวร** (A2) และฝังเฉพาะชุดที่ไม่เปลี่ยน (เสียง backdrop อากาศ UI GIF ~12 MB) ทีหลังถ้าตัวเลขบอกว่าคุ้ม (A3)

## ข้อเท็จจริงจากโค้ด (สำรวจ 2026-10-08)

| เรื่อง | ของจริง |
|---|---|
| ทางที่รูปเข้า engine | เกือบทั้งหมดผ่าน `fetchTex()` (`zyra-engine/pixi-game/utils.ts:665-730`) — `new Image()` + `crossOrigin="anonymous"` + `Texture.from` · cache `texCache` key ด้วย URL · `t.label = url` (peer เทียบ label) · concurrency 4–12 |
| URL ที่โหลดจริง | ทุก R2 URL ถูกห่อเป็น `/api/img?url=<encoded>` ด้วย `proxyUrl()` (`zyra-engine/assets/texture-registry.ts:10`) เพราะ R2 ไม่ส่ง CORS · URL ของ peer มาทาง WS **ในรูปห่อแล้ว** |
| ทางที่ไม่ผ่าน `fetchTex` | `lib/sprite-grid.ts:381` (ตัดเฟรม pet) · `Assets.load({parser:"gif"})` ที่ `scene.ts:5394,6219,6274`, `lib/vo-preload.ts:291` · เสียง `fetch('/api/img?url=')`+`decodeAudioData` ใน `lib/pet-sound-player.ts:93`, `lib/environment-sound-player.ts:112` · `new Audio('/sound/…')` ใน `use-vo-sounds.ts:116` |
| แคชวันนี้ | มีแค่ HTTP cache ของ WebView หลัง `/api/img` (`max-age=86400`) — OS ล้างได้เงียบ ๆ · `sw.js` ไม่แคชอะไร และ SW ไม่รันใน WKWebView |
| ชุดที่เปลี่ยนจาก DB | map `image_url`, object piece `url`, avatar `walking/sitting_spritesheet_url`, pet `sprite_url`, profile `avatar_url` |
| ชุดคงที่ (hard-code) | `public/sound` 688 KB · R2 env sound 9.4 MB · backdrop (315 KB wire / 48 MB decode) + weather · UI GIF · loading art · default avatar sheet 64 KB |
| Capacitor iOS | `capacitor://localhost` ยังลงทะเบียนในโหมด remote (`CAPBridgeViewController.swift:297`) · `WebViewAssetHandler` ใส่ `Access-Control-Allow-Origin: <server.url>` (ยกเว้นไฟล์เสียง/วิดีโอถ้าไม่ส่ง `Range`) · `/_capacitor_file_/<abs>` อ่าน filesystem ได้ทุก path |
| Capacitor Android | `https://<host>/_capacitor_file_/<abs>` เสิร์ฟจาก filesystem จริง same-origin (ไม่ต้อง CORS) · อ่าน APK assets ไม่ได้ · `https://localhost/<www>` ไม่ถูกเสิร์ฟในโหมด remote |
| plugin | ยังไม่มี `@capacitor/filesystem` / `preferences` / CapacitorHttp ทั้งสอง repo |

## A0 — ทดสอบ iOS (2026-10-08, iPhone 15 Pro Max iOS 18.7, dev build ผ่าน Cloudflare tunnel)

วาง `probe.png` + `probe.mp3` ใน `www/` แล้วให้หน้า https ในแอปทดสอบอ่าน `capacitor://localhost/probe.*` (ผลโพสต์กลับมาที่ Mac):

| ทดสอบ | ผล | ความหมาย |
|---|---|---|
| `fetch("capacitor://localhost/probe.png")` | ❌ `Load failed` | `fetch()`/XHR ข้าม scheme ถูก WebKit บล็อก (mixed content / scheme policy) |
| `<img crossOrigin="anonymous">` + `drawImage` + `getImageData` | ✅ `8x8 rgba=255,0,0,255` | รูปโหลดได้และ **ไม่ taint** — CORS header ของ asset handler ใช้ได้ |
| `gl.texImage2D(img)` | ✅ `glError=0` | **WebGL texture จากไฟล์ในแอปใช้ได้** → path หลักของ `fetchTex` ผ่าน |
| `fetch(mp3, Range)` → `decodeAudioData` | ❌ `Load failed` | เสียงแบบ `fetch`+decode (pet/env sound) ใช้ local ไม่ได้ |
| `new Audio(capacitor://…mp3)` | ✅ `dur=1.94` | `<audio>` element ใช้ไฟล์ในแอปได้ |
| `fetch(ไฟล์ที่ไม่มี)` | ❌ `Load failed` (ไม่ใช่ 404) | ต้อง `stat` ก่อนแจก path เสมอ |

**ผลต่อการออกแบบ A2 (iOS):**
- รูป/spritesheet/GIF → `img.src = convertFileSrc(...)` ตรง ๆ ได้เลย ไม่ต้อง fallback `blob:`
- GIF ผ่าน `Assets.load` ของ Pixi ใช้ `fetch` ภายใน → ต้องทดสอบเพิ่มใน A2 ถ้าไม่ผ่านให้ GIF คง network (มีไม่กี่ไฟล์)
- เสียง `use-vo-sounds.ts` (`<audio>`) → local ได้ · pet/env sound (`fetch`+`decodeAudioData`) → **iOS คง network** หรืออ่านผ่าน `Filesystem.readFile` → `blob:` (ช้ากว่า ~100 ms/MB) — ตัดสินตอน A2 จากขนาดจริง
- Android ยังไม่ได้ทดสอบ (same-origin `_capacitor_file_` คาดว่าผ่านทั้ง `fetch` และ `<img>`) — ทดสอบตอน A2 บนเครื่อง Android กลาง

## แผน (อนุมัติ 2026-10-08 — รายละเอียดใน plan file ของ session)

| ขั้น | ทำอะไร | ประมาณ |
|---|---|---|
| A1 | `/api/img`: host allowlist + `immutable, max-age=31536000` เมื่อ key เป็น uuid · `performance.mark` + log `[vo-preload]` กรอก Before | 1 วัน |
| A2 | `@capacitor/filesystem` · `asset_store` ใน `/api/app/config` · `lib/native/asset-store.ts` (`originalUrl` / `resolveAssetSrc` sync / `ensureAssets` / `revalidateUsed` / LRU 300 MB / manifest ใน `Directory.Data`, ไฟล์ใน `Directory.Cache`) · เสียบที่ `fetchTex`, `sprite-grid`, GIF 4 จุด, sound player 2 จุด, `use-vo-sounds`, loading screen, peer prefetch · แถว "ล้างแคชรูป" ใน Settings · tests | 5 วัน |
| A3 (เงื่อนไข) | ฝังชุดคงที่ ~12 MB ในไบนารี (`scripts/build-asset-pack.mjs`, Android copy assets→files ครั้งแรก) — ทำเฉพาะถ้า first-run ของ A2 ยังช้า | 2 วัน |

## Before / After (rule 18) — ยังไม่ได้วัด

| Metric | Before cold / warm / 3-day | After A1 | After A2 | เครื่อง / เน็ต |
|---|---|---|---|---|
| bytes โหลดตอนเข้า workspace (KB) | | | | iPhone 15 Pro Max · Android กลาง · LTE |
| จำนวน request `/api/img` | | | | |
| loading-start → map interactive (s) | | | | |
| hit rate ของ store (%) | n/a | | | |
| ขนาด store บนเครื่อง (MB) | 0 | 0 | | |

**วัดยังไง:** Safari Web Inspector (Develop → iPhone → WebView) / `chrome://inspect` → Network tab filter `api/img`, `_capacitor_file_` · log `[asset-store] hits=… misses=… dl=…KB` · `performance.mark("vo:loading-start" / "vo:map-interactive")`
**ยังไม่ได้วัด — เหตุผล:** A1 (marks + log) ยังไม่ได้ทำ จะกรอก Before ทันทีที่ A1 ขึ้น dev
