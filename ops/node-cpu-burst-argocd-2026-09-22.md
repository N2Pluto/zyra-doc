# CPU burst รุนแรงที่สุดเท่าที่เคยวัด — ArgoCD ไม่มี resource request/limit เลยสักตัว (2026-09-22)

> สถานะ: **บรรเทาแล้ว 04:56 UTC (11:56 ไทย)** — prod กลับมาปกติเอง, dev/uat ที่ค้าง CrashLoopBackOff ถูก restart ให้แล้ว, เพิ่ม CPU/memory request+limit ให้ทุก component ของ ArgoCD ผ่าน `HelmChartConfig` (live เท่านั้น ยังไม่ persist เข้า git — ดู "ยังไม่ปิด")
> กระทบ: prod `zyra-app` (2 replica restart แล้วฟื้นเอง) · dev/uat `zyra-app` (CrashLoopBackOff ~40 นาที) · ArgoCD ทั้งคลัสเตอร์ (~10 application flap sync/health status)
> ต่อจาก: [prod-app-crashloop-2026-09-10.md](prod-app-crashloop-2026-09-10.md) (root cause เดียวกัน: node CPU contention) · [node-saturation-2026-09-18.md](node-saturation-2026-09-18.md)

## อาการ

ผู้ใช้แจ้งว่า "server ดับ" ตรวจพบ:

| Metric | ค่าที่วัดได้ (peak, ~04:32-04:45 UTC) |
|---|---|
| node load1 | **54.04** (สูงสุดเท่าที่เคยบันทึกในทุก incident ก่อนหน้า — 09-10 อยู่ที่ 10.55, 09-18 อยู่ที่ 9.65) |
| node load5 / load15 | 71.05 / 52.02 |
| CPU pressure (PSI) `some avg10` | **83%** (avg60 90%, avg300 91%) |
| prod `zyra-app` restart | ทั้ง 2 replica restart (4 และ 2 ครั้ง), `Readiness probe failed: context deadline exceeded` — อาการเดียวกับ 09-10 เป๊ะ |
| dev/uat `zyra-app` | CrashLoopBackOff วนทุก ~100 วิ นานกว่า 40 นาที (`Liveness probe failed` → `connection refused` → `BackOff`) |
| argocd applications flap | ~10 app ที่ไม่เกี่ยวกันเลย (loki, cert-manager, sfu-prod, app-uat, kube-prometheus-stack, ...) เปลี่ยน sync/health status พร้อมกันในหน้าต่าง ~70 วินาที |

ภายนอก (`curl` ตรงไปที่ `app`/`api`/`ws`.zyraworld.co) กลับได้ 200 ตลอดตอนที่ตรวจ — Traefik กระจาย traffic ไปยัง replica ที่ยังไหวได้ทัน จึงไม่เห็นเป็น 503 ชัดจากภายนอกเหมือน 09-10 แต่ pod ข้างในสั่นจริง

## ต้นเหตุ

**ไม่ใช่ deploy ใหม่** — ไม่มี commit ใน `zyra-infra` หรือ `zyra-app` ในช่วง 6 ชม.ก่อนเกิดเหตุ

หลักฐานชี้ไปที่ **ArgoCD เอง**: `kubectl top pod` ตอน peak เจอ `argocd-application-controller-0` กิน **593m** (สูงกว่า SFU และ prod app ทุก replica ในขณะนั้น) และ `argocd-repo-server` / `argocd-server` เองก็โดน `Killing ... failed liveness probe` เหมือนกัน

ตรวจ `terraform/cloud-init-k3s.yaml.tftpl` (ที่ install ArgoCD ผ่าน k3s HelmChart) พบว่า **`valuesContent` ไม่เคยตั้ง `resources` ให้ component ไหนของ ArgoCD เลยสักตัวตั้งแต่ต้น** — ต่างจาก dev/uat ที่ตั้งใจให้จอง CPU ต่ำสุด (10m) เพื่อสละให้ prod, ArgoCD ไม่มี request/limit ใด ๆ จึงแย่ง CPU กับ prod ได้เท่ากันเป๊ะเวลา node ตึง และไม่มีเพดานกันไม่ให้ reconcile รอบใหญ่ (เช่นตอนนี้) กิน CPU ไม่จำกัด

**ห่วงโซ่ที่น่าจะเกิด**: node ตึงอยู่แล้ว (CPU requests 87% เป็นทุนเดิมจาก [09-10](prod-app-crashloop-2026-09-10.md)) → มีสิ่งกระตุ้นให้ ArgoCD reconcile หนักขึ้น (ไม่ทราบตัวกระตุ้นแน่ชัด) → controller ไม่มี limit จึงกิน CPU พุ่ง → ArgoCD เองโดน probe ฆ่า → restart ของ ArgoCD (repo-server clone/render ใหม่) ยิ่งกิน CPU เพิ่ม → วนเป็น cascade จนกระทบ prod/dev/uat app พร้อมกัน — เป็นสมมติฐานที่สอดคล้องกับหลักฐานที่มี ยังไม่ได้ยืนยัน 100% ว่าอะไรเป็นตัวจุดชนวนรอบแรก

## สิ่งที่ทำ (ผู้ใช้ confirm ให้ทำ 2 ข้อ, ต่ำเสี่ยง)

1. **Restart dev/uat `zyra-app` pod ที่ค้าง CrashLoopBackOff** — `kubectl delete pod` ตรง ๆ (non-prod)
2. **เพิ่ม CPU/memory request+limit ให้ทุก component ของ ArgoCD** ผ่าน `HelmChartConfig` (kind: `helm.cattle.io/v1`, name/namespace เดียวกับ HelmChart เดิมคือ `argocd`/`kube-system`) — เป็นกลไกที่ k3s รองรับให้ merge ค่าเพิ่มเติมเข้ากับ HelmChart เดิมแบบ live **โดยไม่แตะ `terraform/cloud-init-k3s.yaml.tftpl`** (ไฟล์นั้นแก้แล้วจะ force-replace VM ทั้งตัวตาม `replace_triggered_by` — เสี่ยงเกินไปสำหรับ mitigation เร่งด่วน)

ค่าที่ตั้ง (request/limit ต่อ component):

| Component | requests (cpu/mem) | limits (cpu/mem) |
|---|---|---|
| controller | 100m / 256Mi | 700m / 1Gi |
| repoServer | 30m / 128Mi | 400m / 768Mi |
| server | 20m / 64Mi | 150m / 256Mi |
| applicationSet | 10m / 64Mi | 100m / 256Mi |
| notifications | 10m / 64Mi | 100m / 256Mi |
| dex | 5m / 64Mi | 50m / 160Mi |
| redis | 10m / 32Mi | 100m / 128Mi |

request รวมที่เพิ่มเข้า node: **+185m** (ตั้งใจให้น้อยที่สุดเท่าที่ยังพอเป็น floor ได้จริง เพราะ node มี headroom เหลือน้อยอยู่แล้ว) — limit ตั้งสูงกว่าที่เคยวัดใช้จริงพอสมควรเพื่อไม่ให้ throttle จน ArgoCD ทำงานไม่ทัน แต่ก็คุมไม่ให้กินได้ไม่จำกัดเหมือนก่อนหน้า

การ apply ค่านี้ทำให้ Helm upgrade ทั้ง chart → ArgoCD pod ทุกตัว **restart ครั้งเดียว** (คาดไว้แล้ว, ไม่กระทบ workload ที่ ArgoCD บริหารอยู่ เพราะ Argo หยุดทำงานชั่วคราวไม่ได้ทำให้ pod ที่รันอยู่หายไป)

## Before / After

| Metric | Before (peak, 04:32-04:45 UTC) | After (04:56 UTC) |
|---|---|---|
| node load1 | **54.04** | 18.06 (กำลังลดต่อเนื่อง — load5/15 ยังสูงเพราะเป็นค่าเฉลี่ยย้อนหลัง) |
| prod `zyra-app` restart | 4 + 2 ครั้งใน ~15 นาที | 0 เพิ่มเติม, 1/1 Ready ทั้งคู่ |
| dev/uat `zyra-app` | CrashLoopBackOff ต่อเนื่อง >40 นาที | **1/1 Running, 0 restart** (หลัง delete pod) |
| ArgoCD applications | ~10 ตัว flap Synced→Unknown / Healthy→Progressing | ทุกตัว Synced/Healthy (เหลือ `app-dev` Progressing ชั่วคราวเพราะเพิ่งรีสตาร์ท) |
| ArgoCD component resources | ไม่มี request/limit เลยสักตัว | ตั้งครบทุก component (ตารางด้านบน) |
| node cpu requests | 3480m/4000m (87%) | **3665m/4000m (91%)** — headroom ลดลงจาก 520m เหลือ ~335m โดยตั้งใจ แลกกับการันตี floor ให้ ArgoCD |
| external health (app/api/ws) | 200 ตลอด (Traefik กระจายไป replica ที่ไหว) | 200 ทั้งหมด, 140-230ms |

**วัดยังไง**: `uptime`, `cat /proc/pressure/cpu`, `kubectl top pod/node`, `kubectl get pods -A`, `kubectl describe node | grep -A6 'Allocated resources'`, `curl` health endpoint ทั้งหมด — SSH ตรงเข้า `zyra-k3s` ผ่าน IAP tunnel ทำสด ไม่ได้เดา
**ช่วงเวลาที่วัด**: before = peak ของเหตุการณ์ (~04:32-04:45 UTC) · after = 10-15 นาทีหลังทำ mitigation (04:56 UTC)

## ยังไม่ปิด

1. **สาเหตุกระตุ้นรอบแรกที่ทำให้ ArgoCD reconcile หนักขึ้นผิดปกติ** — ยังไม่ทราบแน่ชัด (ไม่ใช่ deploy ใหม่) ถ้าเกิดซ้ำอีกควรเช็ค `kubectl logs -n argocd argocd-application-controller-0` ย้อนหลังตอนเกิดเหตุ (รอบนี้ไม่ได้ดึง log ตอน peak เพราะ pod ถูก resync ไปแล้วตอนตรวจ)
2. **`HelmChartConfig` ที่เพิ่มยังเป็น live-only ไม่ได้ persist เข้า git/terraform** — ถ้า VM `zyra-k3s` ถูก recreate ด้วยเหตุผลใดก็ตาม (เช่น ทำตาม [แผนขยาย capacity](media-node-capacity-plan)) การตั้งค่านี้จะหายไป ต้อง apply ซ้ำ หรือย้ายเข้า `terraform/cloud-init-k3s.yaml.tftpl` อย่างเป็นทางการ (ซึ่งจะ force-replace VM ครั้งเดียว ต้องทำพร้อมแก้ blocker เรื่อง terraform state location ที่ค้างอยู่แล้วจาก [PR #29](https://github.com/Maximumsoft-Co-LTD/zyra-infra/pull/29))
3. **node headroom ลดลงเหลือ ~335m** จาก 520m — ยังไม่วิกฤต แต่แคบลง เป็นอีกเหตุผลที่สนับสนุนการตัดสินใจเรื่อง capacity (ดู [media-node-capacity-plan](media-node-capacity-plan)) เร็วขึ้น
4. เหตุการณ์นี้ทำให้ decision gate ของแผน capacity **ยิ่งควรพิจารณาเร็วขึ้น** — โหลดวันนี้หนักกว่าทุกครั้งก่อนหน้า แม้จะมาจาก ArgoCD ไม่ใช่ SFU โดยตรง แต่สะท้อนว่า node ไม่มี slack เหลือพอจะรองรับความผันผวนแม้เพียงเล็กน้อยจาก control-plane เอง
