# Docker Stack — Dev & GCloud SFU Deploy

**Dev default: Docker รันแค่ infra ที่รัน native ยาก (`sfu` + `redis`)** — app/api/ws รัน native เพื่อ hot-reload:

```bash
docker compose up -d                 # sfu + redis เท่านั้น (default)
cd zyra-api && go run .              # :3002 native (REDIS_URL ชี้ localhost:6379 แล้ว)
cd zyra-ws  && go run main.go        # :3003 native (REDIS_URL ชี้ localhost:6379 แล้ว)
cd zyra-app && npm run dev           # :3000 native
```

อยากรัน backend เป็น container แทน (demo แบบ production-like): `docker compose --profile backend up -d --build` (+ `--profile app` ถ้าเอา frontend ด้วย) — **native กับ container ใช้ port เดียวกันไม่ได้ ต้องหยุดอีกฝั่งก่อน** ไม่งั้นเจอ `bind: address already in use`

**Production ไม่ได้รวมทุกอย่างไว้ VM เดียว** — ดู [Topology จริง](#topology-จริง--cloud-run--gce-vm-แยกกัน) ด้านล่าง `docker-compose.gcloud.yml` เหลือแค่ service `sfu` เพราะเป็นตัวเดียวที่ต้อง deploy บน VM จริง (ที่เหลือ deploy ผ่าน Cloud Run ของตัวเอง)

| | Dev (macOS, default: sfu+redis) | GCloud (GCE Linux VM, **sfu เท่านั้น**) |
|---|---|---|
| ไฟล์ | `docker-compose.yml` | `docker-compose.gcloud.yml` + `.env.gcloud` |
| คำสั่ง | `docker compose up -d` (`--profile backend/app` = เพิ่ม service อื่น) | `docker compose -f docker-compose.gcloud.yml --env-file .env.gcloud up -d --build` |
| SFU networking | port mapping + **single-port UDP mux** (`udp_port: 7882`) + `--node-ip 127.0.0.1` | `network_mode: host` + UDP range 50000-60000 + `use_external_ip: true` |
| LiveKit config | `zyra-sfu/livekit.yaml` (dev keys ใน git ได้) | `zyra-sfu/livekit-prod.yaml` (keys ผ่าน env เท่านั้น) |
| LiveKit URL ที่ browser ใช้ | `ws://localhost:7880` | `PUBLIC_LIVEKIT_URL` (แนะนำ `wss://` หลัง TLS) |

## Ports (dev)

| Service | Host port | Compose profile |
|---|---|---|
| sfu | 7880 (HTTP/WS), 7881 (ICE-TCP), 7882/udp (media mux) | default |
| redis | 6379 | default |
| api | 3002 | `backend` |
| ws | 3003 | `backend` |
| notifications | — (internal: `http://notifications:3003`) | `backend` |
| app | 3000 | `app` |

## ทำไม dev บน macOS ไม่ใช้ host networking

Docker Desktop บน macOS ไม่ส่งพอร์ตของ container ที่ใช้ `network_mode: host` ออกมาที่เครื่องจริง (container อยู่ใน VM ภายใน) → LiveKit เลยถูก config ให้ mux media ทุก track ผ่าน UDP พอร์ตเดียว (7882) แล้ว map แบบปกติ พร้อม `--node-ip 127.0.0.1` เพื่อให้ ICE candidate ชี้ localhost — ใช้ได้กับ browser บนเครื่องเดียวกัน **ถ้าจะทดสอบจากเครื่องอื่นใน LAN** ต้องเปลี่ยน `--node-ip` เป็น IP เครื่อง host

## GCloud checklist (sfu VM เท่านั้น)

1. `cp .env.gcloud.example .env.gcloud` แล้วเติมค่า (ห้าม commit) — เหลือแค่ `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET`
2. Generate LiveKit key ใหม่: `docker run --rm livekit/livekit-server:v1.13 generate-keys` — **ห้ามใช้ dev key จาก livekit.yaml**
3. Firewall (GCE): เปิด `7880-7881/tcp`, `50000-60000/udp`
4. หลัง deploy เช็ค `curl :7880` (sfu → ตอบ 200)

## Gotchas ที่เจอแล้วแก้ไว้แล้ว

- `livekit.yaml`: `empty_timeout` ต้องเป็นวินาที (ตัวเลข) ไม่ใช่ `5m`, ไม่มี field `enable_dynacast` ฝั่ง server, และ LiveKit **ไม่ expand** `${VAR}` ใน yaml
- `LIVEKIT_KEYS` env ต้องเป็น `"key: secret"` — **มี space หลัง colon**
- `zyra-api/go.mod` ใช้ go 1.26 → Dockerfile ต้อง `golang:1.26-alpine`
- Next.js inline `NEXT_PUBLIC_*` ตอน build → เปลี่ยนค่าเหล่านี้ต้อง rebuild image `app` เสมอ (`BACKEND_URL` เป็น runtime env อ่านใน `next.config.ts`)

---

## Topology จริง — Cloud Run + GCE VM แยกกัน

```
zyra-app, zyra-api, zyra-ws, zyra-notifications  →  Cloud Run (auto-deploy ต่อ service, ดู .github/workflows/deploy.yml ของแต่ละ repo)
zyra-sfu (LiveKit)                                →  GCE VM (Container-Optimized OS)
```

เหตุผล: LiveKit ต้องการ UDP port range สำหรับ media (เสียง/วิดีโอ/แชร์จอ) ซึ่ง **Cloud Run รองรับไม่ได้เลย** (proxy แค่ HTTP(S)/gRPC) จึงต้อง deploy ไปที่ GCE VM แทน — service อื่นคุยกันผ่าน HTTP/WebSocket (TCP) ล้วนๆ จึงอยู่บน Cloud Run ได้ปกติ ไม่มีเหตุผลทางเทคนิคที่ต้องย้ายตาม sfu ไป VM ด้วย (ดู [capacity-scaling.md](../plan/Real-time-Engine/capacity-scaling.md) เรื่อง scaling แต่ละ plane แยกกัน)

`docker-compose.gcloud.yml` (root) จึงเหลือแค่ service `sfu` — ใช้สำหรับ bring-up VM ด้วยมือ/ทดสอบเท่านั้น ตัว deploy pipeline จริงของ zyra-sfu (`zyra-sfu/.github/workflows/deploy.yml`) build+push image แล้ว `gcloud compute instances update-container` เข้า VM ที่มีอยู่แล้วโดยตรง ไม่ได้เรียกไฟล์นี้

### zyra-sfu CI/CD

| ไฟล์ | ทำอะไร |
|---|---|
| `zyra-sfu/Dockerfile` | ห่อ `livekit/livekit-server:v1.13` + bake `livekit-prod.yaml` เข้าไป (ไม่มี secret ในอิมเมจ) |
| `zyra-sfu/.github/workflows/ci.yml` | yamllint `livekit.yaml`/`livekit-prod.yaml`, validate dev compose, build image ตรวจว่า build ผ่าน |
| `zyra-sfu/.github/workflows/deploy.yml` | build+push image ไป Artifact Registry แล้ว `gcloud compute instances update-container` รีสตาร์ต container บน VM ที่มีอยู่แล้ว |

**Secrets ที่ต้องตั้งเพิ่มใน repo `zyra-sfu`** (นอกเหนือจาก `GCP_PROJECT_ID` / `GCP_WIF_PROVIDER` / `GCP_DEPLOY_SA` ที่ repo อื่นใช้ร่วมกันอยู่แล้ว):

| Secret | ค่า |
|---|---|
| `GCE_SFU_VM_NAME` | ชื่อ instance ของ VM ที่รัน LiveKit อยู่ |
| `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET` | คู่ key จริงของ production — ต้องตรงกับที่ตั้งใน `zyra-api`'s Cloud Run env |

**ข้อกำหนดของ VM ก่อนใช้ deploy.yml นี้ได้:**
- สร้างด้วย Container-Optimized OS + `--container-image` (ให้ `update-container` แก้ไขได้)
- Firewall เปิด `7880-7881/tcp` และ `50000-60000/udp`
- ถ้า zone ของ VM ไม่ใช่ `asia-southeast1-b` ต้องแก้ `GCE_ZONE` ใน `deploy.yml`
