# ค่า server GCP ต่อเดือน — ประมาณการจาก resource ที่รันอยู่จริง (2026-10-21)

> สถานะ: **ประมาณการ (estimate) — ไม่ใช่ยอดบิลจริง** · รวม ≈ **$1,130/เดือน** (≈ ฿37,800 ที่ ~33.5 บาท/USD) เฉพาะ GCP project `gather-dev-458614`
> วัดเมื่อ: 2026-10-21 ~08:00 UTC (usage 1–21 ต.ค. 2026 จาก Cloud Monitoring · ราคาจาก Cloud Billing Catalog API region asia-southeast1)
> กระทบ: ไม่มี (อ่านอย่างเดียว)
> ติดอะไร: บัญชี `ten_dev@hpktechnology.com` **ไม่มีสิทธิ์ Billing Account Viewer** บน billing account `01B129-524F19-1584DC` และไม่มี billing export ลง BigQuery → อ่านยอดบิลจริงไม่ได้ (ดู §ข้อจำกัด)
> เกี่ยวข้อง: [live-event-2026-10-20.md](live-event-2026-10-20.md) (resize node เป็น 8 vCPU) · [service-cpu-ram-breakdown-2026-09-24.md](service-cpu-ram-breakdown-2026-09-24.md)

## คำถาม

"ตอนนี้จ่ายค่า server เดือนละเท่าไหร่" (Ten, 2026-10-21)

## คำตอบสั้น

| | USD/เดือน |
|---|---:|
| ค่าคงที่ (VM, DB, Redis, IP, LB, disk ฯลฯ) | ~955 |
| ค่าแปรผัน (internet egress, upper bound) | ~175 |
| **รวม** | **~1,130** (≈ ฿37,800) |

- เป็น rate **หลัง resize วันที่ 2026-10-20** (ทั้ง `zyra-k3s` และ `zyra-sfu-node-0` เป็น 8 vCPU) — ถ้ากลับไป 4 vCPU ทั้งคู่ จะลดราว **$255/เดือน**
- **บิลเดือน ต.ค. 2026 จริงจะสูงกว่านี้** เพราะมี load-test clone (`lt-*`) ที่สร้างแล้วลบไป 19–20 ต.ค. (ดู §รายการครั้งเดียว)
- ไม่รวมบริการนอก GCP: Cloudflare R2, Sentry, GitHub Actions, Vercel (landing), domain

## ค่าคงที่ต่อเดือน (730 ชั่วโมง, list price asia-southeast1 / Singapore)

| รายการ | spec | ราคาต่อหน่วย | USD/เดือน |
|---|---|---|---:|
| VM `zyra-k3s` | e2-standard-8 (8 vCPU / 32 GB) | core $0.026909/h · RAM $0.003606/GB·h | 241 |
| VM `zyra-sfu-node-0` | c2d-highcpu-8 (8 vCPU / 16 GB) | core $0.036471/h · RAM $0.004884/GB·h | 270 |
| AlloyDB `zyra-prod` / `zyra-prod-primary` | 2 vCPU / 16 GB, ZONAL · storage 0.2 GB | vCPU $0.08128/h · RAM $0.01378/GB·h | 280 |
| Memorystore Redis `zyra-prod-redis` | BASIC 1 GB (M1) | $0.065/GB·h | 47 |
| VM `gather-dev` | e2-medium (1 vCPU eq. / 4 GB), zone asia-southeast1-c, สร้าง 2025-05-02 | | 30 |
| Disk pd-balanced ของ `gather-dev` | 100 GB boot + 100 GB `gather-disk-1` | $0.11/GB·mo | 22 |
| Serverless VPC Access `zyra-connector` | e2-micro ×2 (min 2 / max 10) | ~$0.0103/h ต่อตัว | 15 |
| Load balancer TURN `zyra-turn-443` | global SSL-proxy forwarding rule | $0.025/h (+ inbound $0.009/GB, 0.7 GB) | 18 |
| External IP ที่ VM ใช้อยู่ | `zyra-k3s-ip`, `zyra-sfu-node-0-ip`, gather-dev ×3 | $0.005/h ต่อ IP | 11 |
| Static IP `zyra-sfu-ip` | ผูกกับ VM `zyra-sfu` ที่ **TERMINATED** | $0.011/h (reserved แต่ไม่ได้ใช้) | 8 |
| Disk pd-standard | `zyra-k3s` 40 + `zyra-sfu` 20 + `zyra-sfu-node-0` 40 = 100 GB | $0.044/GB·mo | 4 |
| Artifact Registry `zyra` | 47 GB | $0.10/GB·mo (0.5 GB แรกฟรี) | 5 |
| GCS | `zyra-prod-*` 766 MB · egress ~12 GB/mo | $0.02/GB·mo · $0.12/GB | 2 |
| Secret Manager | 29 secrets (ESO sync) | $0.06/secret·mo | 2 |
| Cloud Run `zyra-ws`, `zyra-notifications` | min instances 0 · billable 840 s ทั้งเดือน | free tier | 0 |
| Cloud Logging | ingest 342 MB (ฟรี 50 GB) | | 0 |
| **รวมค่าคงที่** | | | **~955** |

## ค่าแปรผัน — internet egress

Metric `compute.googleapis.com/instance/network/sent_bytes_count` รวม 1 ต.ค. – 21 ต.ค. 08:00 UTC (20.3 วัน) แล้วคูณเป็น 31 วัน:

| VM | ส่งออกจริง 20.3 วัน | คิดเต็มเดือน |
|---|---:|---:|
| `zyra-sfu-node-0` (LiveKit media) | 634 GB | ~967 GB |
| `zyra-k3s` | 327 GB | ~499 GB |
| `gather-dev` | 14 GB | ~21 GB |
| **รวม** | **975 GB** | **~1,490 GB** |

ราคา egress Singapore → APAC (excl. Korea/Indonesia): $0.12/GB (0–1 TB) · $0.11/GB (1–10 TB) → **≈ $175/เดือน**

- เป็น **upper bound** — metric นี้นับ traffic ไป AlloyDB/Redis/ระหว่าง VM ใน zone เดียวกัน (ฟรี) รวมด้วย แยก internet egress จริงไม่ได้จาก Monitoring
- egress ของ SFU ขึ้นกับจำนวน participant/ชั่วโมงประชุม — เดือนที่มี live event (20 ต.ค.) จะสูงกว่าปกติ

## รายการครั้งเดียวในบิล ต.ค. 2026 (ไม่ recurring)

Load-test clone (`lt-k3s`, `lt-sfu-node-0`, `lt-loadgen`, `lt-alloydb`, `lt-redis`, bucket `lt-*`) สร้าง 19 ต.ค. แล้วลบ 19–20 ต.ค. — ยังโผล่ใน Monitoring ของเดือนนี้:

| | ตัวเลขจริง |
|---|---:|
| egress `lt-k3s` | 409 GB (≈ $50) |
| egress `lt-loadgen` + `lt-sfu-node-0` | 38 GB (≈ $5) |
| egress bucket `lt-reports-relay-*` | 7.4 GB (≈ $1) |
| ค่า VM/AlloyDB/Redis ของ clone | ~2 วัน × rate ใกล้เคียง prod (≈ $55–60) |

## ถ้าปรับขนาดกลับ (เทียบ)

| node | ตอนนี้ (8 vCPU) | ถ้า 4 vCPU | ส่วนต่าง |
|---|---:|---:|---:|
| `zyra-k3s` e2-standard-8 → e2-standard-4 | $241 | $121 | −$120 |
| `zyra-sfu-node-0` c2d-highcpu-8 → c2d-highcpu-4 | $270 | $135 | −$135 |

## จุดที่น่าดูเพื่อประหยัด (ยังไม่ได้ทำ — แค่สังเกต)

| รายการ | USD/เดือน | หมายเหตุ |
|---|---:|---|
| VM `gather-dev` + disk 200 GB | ~52 | VM เก่าจาก พ.ค. 2025 zone -c — ยังใช้อยู่ไหม? |
| VM `zyra-sfu` (TERMINATED) disk 20 GB + static IP | ~9 | VM ถูก decommission แล้ว แต่ disk/IP ยังอยู่ |
| AlloyDB RAM 16 GB | 161 (จาก 280) | AlloyDB คิด RAM 8 GB/vCPU ตายตัว ลดไม่ได้ถ้าไม่ลด vCPU |

## วิธีวัด (ทำซ้ำได้)

```bash
export CLOUDSDK_PYTHON=/opt/homebrew/bin/python3.12   # gcloud บนเครื่อง Ten พังกับ python 3.9
P=gather-dev-458614
gcloud compute instances list --project=$P
gcloud alloydb instances list --project=$P --region=- --cluster=-
gcloud redis instances list --project=$P --region=-
gcloud compute networks vpc-access connectors list --project=$P --region=asia-southeast1
# ราคา: GET https://cloudbilling.googleapis.com/v1/services/<serviceId>/skus  (Compute 6F81-5844-456A, AlloyDB C49F-B7F2-7416, Redis 5AF5-2C11-D467, Networking E505-1604-58F8)
# usage: GET https://monitoring.googleapis.com/v3/projects/$P/timeSeries  metric compute.googleapis.com/instance/network/sent_bytes_count (ALIGN_DELTA, REDUCE_SUM by instance_name)
```

## ข้อจำกัด / ต่อจากนี้

- **ยังไม่ได้วัดจากบิลจริง** — เหตุผล: ten_dev ไม่มี Billing Account Viewer บน `01B129-524F19-1584DC`, `gcloud billing accounts list` คืน 0 รายการ, console Billing ว่าง, ไม่มี BigQuery billing export
- ตัวเลขทั้งหมดเป็น on-demand list price ไม่รวม credit / discount / sustained-use ที่ Google อาจให้
- ถ้าอยากได้เลขจริง: ขอ owner ของ billing account เพิ่มสิทธิ์ **Billing Account Viewer** ให้ ten_dev หรือเปิด **billing export → BigQuery** แล้วค่อยเทียบกับตารางนี้
