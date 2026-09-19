# GitHub Actions budget ของ org ตัน — `Server Health Monitor` แดงทั้ง 4 repo และ CI/deploy รันไม่ได้ (2026-09-19)

> สถานะ: **วินิจฉัยเสร็จ · ส่วน health monitor ปิดจบแล้ว (ยืนยันด้วยตัวเลขจริงจาก Prometheus prod) · ส่วน budget ยังไม่แก้ — แก้เองไม่ได้ ต้องให้ org owner ทำ** · ยังไม่เห็น CI/deploy fail เพราะยังไม่มี push ใหม่หลังเกิดเหตุ แต่ push ครั้งหน้าจะโดนแน่
> กระทบ: GitHub Actions ทุก repo ใต้ org `Maximumsoft-Co-LTD` — `zyra-api`, `zyra-app`, `zyra-ws`, `zyra-notifications` (และ `deploy-gitops.yml` ของทุกตัว)
> เกี่ยวข้อง: `zyra-infra/gitops/observability/` (ตัวที่รับหน้าที่ monitor แทน)

## อาการ

`Server Health Monitor` (`.github/workflows/server-health.yml`) fail ติดกันทุกรอบ พร้อมกันทั้ง 4 repo ตั้งแต่รอบ **2026-09-19 ~00:52 UTC**

```
X The job was not started because an Actions budget is preventing further use.
```

| Repo | 3 รอบล่าสุด (19 ก.ย.) | รอบก่อนหน้า (18 ก.ย. 18:24 UTC) |
|---|---|---|
| zyra-api | failure ×3 | success |
| zyra-app | failure ×3 | success |
| zyra-ws | failure ×3 | success |
| zyra-notifications | failure ×3 | success |

## ไม่ใช่อะไร (ตัดทิ้งด้วยหลักฐาน)

| สมมติฐาน | สิ่งที่ตรวจ | สรุป |
|---|---|---|
| workflow เขียนผิด / cron ผิด | ไฟล์ไม่ได้ถูกแก้เลย และรอบ 18 ก.ย. 18:24 ยัง success | ❌ ตัดทิ้ง |
| ไฟล์ไม่ได้อยู่บน default branch | มีครบทั้ง `main` และ `develop` ทุก repo · default branch = `main` ทุก repo | ❌ ตัดทิ้ง |
| prod ล่มจริง จน curl fail | job **ไม่ได้ start เลย** — ไม่ถึง step แรกด้วยซ้ำ | ❌ ตัดทิ้ง |
| ปัญหาเฉพาะ repo ใด repo หนึ่ง | annotation ข้อความเดียวกันเป๊ะทั้ง 4 repo | ❌ เป็นระดับ org |

ตัวชี้ขาด: ทุก run ใช้เวลา **3–5 วินาที** (ปกติ 8–12 วิ) — ตายตั้งแต่ตอน queue job

## ต้นเหตุ

**GitHub Actions budget / spending limit ของ org `Maximumsoft-Co-LTD` ตัน** — ไม่ใช่บั๊กในโค้ดหรือ workflow เลย

repo ทั้ง 4 เป็น **private** จึงไม่มีโควต้าฟรีแบบ public repo มารองรับ

### ทำไมแก้เองไม่ได้

```
gh api /user                                    → N2Pluto
gh api /user/memberships/orgs/Maximumsoft-Co-LTD → role=member, state=active
gh api /orgs/Maximumsoft-Co-LTD                  → plan=team
```

บัญชีที่ใช้อยู่เป็นแค่ `member` ไม่ใช่ Owner/Billing manager → เปิดหน้า billing ไม่ได้ทุก URL (`/settings/billing`, `/settings/billing/summary` **ขึ้น 404 ทั้งคู่** — GitHub คืน 404 ไม่ใช่ 403 เวลาสิทธิ์ไม่พอ) และ `gh api /orgs/.../settings/billing/actions` ต้อง scope `admin:org`

Org owners ที่ขอได้: `expertep` · `fc3sekkes` · `hashtagf` · `jacknokhook` · `jen-afk` · `miw1513` · `Morshmello` · `Most-Fullstack` · `muzashi777` · `tense-dev` · `thitiwutnew` · `titledev`

## สิ่งที่ทำ — ปิด `Server Health Monitor` ทิ้ง (ไม่ใช่รอ budget)

`server-health.yml` **ซ้ำซ้อน** กับ blackbox-exporter ที่รันอยู่ใน k3s อยู่แล้วตั้งแต่แรก และของเดิมดีกว่าทุกมิติ ปล่อยไว้มีแต่จะทำให้ Actions ขึ้นแดงทุก 6 ชม. จนคนเลิกสนใจ — ตรงกับที่ comment ใน `zyra-infra/gitops/observability/chart/alerts/blackbox.yaml` เตือนไว้เองว่าเป็น "red alert everyone learns to ignore"

```bash
for r in zyra-api zyra-app zyra-ws zyra-notifications; do
  gh workflow disable server-health.yml -R Maximumsoft-Co-LTD/$r
done
```

ยืนยันผล — ทั้ง 4 repo `state=disabled_manually`

**ไฟล์ยังอยู่บน `main` ทุก repo** ตั้งใจไม่ลบ เพราะการลบต้องไล่ `feat/*` → `develop` → `main` ซึ่ง trigger deploy uat ด้วย ไม่คุ้ม — ให้ลบพ่วงไปกับ PR อื่นที่ต้อง merge อยู่แล้ว

เปิดกลับได้ทุกเมื่อด้วย `gh workflow enable server-health.yml -R ...`

## Before/After

ตัวชี้วัดที่สำคัญคือ **coverage การ monitor ไม่ถดถอยหลังปิด workflow** ไม่ใช่ perf

| Metric | Before (GH Actions) | After (blackbox in-cluster) | Δ |
|---|---|---|---|
| ความถี่ probe prod endpoint | 6 ชม. (GitHub delay/skip ได้ ไม่ใช่ SLA) | **60 วินาที** | ถี่ขึ้น **360 เท่า** |
| เวลาตรวจพบว่า endpoint ล่ม | สูงสุด ~6 ชม. | **2 นาที** (`for: 2m`) | เร็วขึ้น ~180 เท่า |
| จำนวน prod endpoint ที่เช็คจริง | 3 (ตัวที่ 4 ชี้ host ที่ไม่มี DNS — ดูหัวข้อถัดไป) | **4** | +1 |
| เช็ค TLS ใกล้หมดอายุ | ไม่มี | `ZyraProdCertExpiringSoon` (14 วัน) | เพิ่มใหม่ |
| ตรวจจับ "monitor ตัวเองตาย" | ไม่มี | `ZyraBlackboxProbesMissing` (`absent()`, 10m) | เพิ่มใหม่ |
| ขึ้นกับ GitHub billing | ใช่ — พังตอนนี้ | ไม่ | — |
| run ที่ fail ใน Actions | 3/3 = **100% failure** | 0 (ไม่รันแล้ว) | -100% |

### ตัวเลขยืนยันว่า blackbox ทำงานจริง (ไม่ใช่แค่ "มีไฟล์อยู่")

```promql
probe_success{job="blackbox-prod"}                    → 1 ทั้ง 4 endpoint
avg_over_time(probe_success{job="blackbox-prod"}[7d]) → 100% ทั้ง 4 endpoint
count_over_time(probe_success{job="blackbox-prod"}[7d]) → 10080 ทั้ง 4 endpoint
(probe_ssl_earliest_cert_expiry - time()) / 86400     → 31.9 วัน ทั้ง 4 endpoint
```

**10080 = 7 วัน × 24 ชม. × 60 ครั้ง/ชม. เป๊ะพอดี** → probe ยิงครบทุก 60 วินาที ไม่ขาดแม้แต่ครั้งเดียวตลอด 7 วัน รวมช่วงที่ GitHub Actions ตายไปแล้ว

Alert rule โหลดอยู่จริง (`/api/v1/rules`) — `state=inactive` แปลว่าโหลดแล้วไม่มีปัญหา ไม่ใช่ "ไม่มี rule":

```
group: zyra-blackbox-prod
  ZyraProdEndpointDown        health=ok  state=inactive
  ZyraBlackboxProbesMissing   health=ok  state=inactive
  ZyraProdCertExpiringSoon    health=ok  state=inactive
```

Pipeline ถึง Discord ยังต่อติด — `count by (alertname, alertstate) (ALERTS)` คืน `Watchdog firing 1` ตัวเดียว (dead-man's switch ของ kube-prometheus-stack ที่ยิงตลอดโดยตั้งใจ) และไม่มี alert อื่น firing

**วัดยังไง**: PromQL ผ่าน Grafana MCP (datasource uid `prometheus`) + `GET /api/datasources/proxy/uid/prometheus/api/v1/rules?type=alert`
**ช่วงเวลาที่วัด**: instant ณ 2026-09-19 ~12:40 UTC · window ย้อนหลัง 7 วัน (12 ก.ย. – 19 ก.ย.)
**แหล่งข้อมูล**: Prometheus บน k3s prod ผ่าน IAP tunnel ตาม [grafana-optimize-2026-08-20.md](grafana-optimize-2026-08-20.md) §วิธี reproduce

## บั๊กที่เจอติดมาระหว่างไล่

`zyra-notifications/.github/workflows/server-health.yml` ตั้ง `TARGET_URL=https://notifications.zyraworld.co/healthz` แต่ host นี้ **ไม่มี DNS record และ ingress ปิดอยู่** (ระบุไว้ชัดใน comment ของ `zyra-infra/gitops/observability/chart/values.yaml` → `blackbox.targets` ที่จงใจไม่ใส่ target นี้ด้วยเหตุผลเดียวกัน)

แปลว่า workflow ตัวนี้อ่านค่าเป็น down มาตั้งแต่วันแรก — alert ไป Discord ครั้งเดียวตอน transition แล้วเงียบยาว เพราะ logic ใน workflow ยิงเฉพาะตอน healthy → down และ state เก็บใน Actions cache

เป็นอีกเหตุผลที่ปิดทิ้งถูกแล้ว หากวันหนึ่งเปิด ingress + DNS ของ notifications ให้เพิ่ม target ใน `blackbox.targets` แทน (มี comment บอกบรรทัดที่ต้องเติมไว้แล้ว)

## ที่ยังค้าง — ต้องทำต่อ

1. **ทัก org owner เรื่อง Actions budget** — ยังไม่ได้ทำ และเลี่ยงไม่ได้ เพราะ `deploy-gitops.yml` กับ CI ทุก repo ยังโดนบล็อกอยู่ = **deploy ไม่ออกทั้ง dev/uat/prod** เรื่องนี้ blackbox แทนไม่ได้
   - ให้ owner เปิด `https://github.com/organizations/Maximumsoft-Co-LTD/settings/billing` → ดู Spending limit / Budgets ของ Actions → เพิ่ม limit หรือรีเซ็ต budget
   - ทางเลือกระยะยาว: ขอสิทธิ์ **Billing manager** (สิทธิ์แคบ ดู billing อย่างเดียว) ให้คนในทีม จะได้เช็คเองได้ก่อนตัน
2. **ทางเลี่ยงทางเทคนิค (ยังไม่ได้ลอง)** — ย้าย CI/deploy ไป self-hosted runner บน k3s ปกติไม่กินโควต้าที่คิดเงิน **แต่ยังไม่ยืนยันว่าตอน budget ตันแล้ว GitHub ยังปล่อยให้ self-hosted job รันไหม** ต้องทดสอบจริงถึงจะรู้ และเป็นงานติดตั้งพอสมควร ไม่ใช่ทางลัด
3. **ลบไฟล์ `server-health.yml` ออกจาก 4 repo** — พ่วงไปกับ PR อื่นที่ต้อง merge อยู่แล้ว ไม่ต้องเปิด PR เดี่ยว

## ทวนซ้ำการตรวจนี้

```bash
# สถานะ workflow
for r in zyra-api zyra-app zyra-ws zyra-notifications; do
  echo -n "$r → "
  gh api repos/Maximumsoft-Co-LTD/$r/actions/workflows \
    -q '.workflows[] | select(.name=="Server Health Monitor") | .state'
done

# tunnel ไป Grafana (ต้อง gcloud auth login ก่อนถ้า token หมดอายุ)
gcloud compute ssh zyra-k3s --project gather-dev-458614 --zone asia-southeast1-b \
  --tunnel-through-iap -- -N -L 3000:127.0.0.1:8300
```
