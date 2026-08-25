# Capacity, Scaling & Reliability — Real-time Engine

> **Module:** [Real-time Engine](spec.md) · ClickUp [86d2weryr](https://app.clickup.com/t/86d2weryr)
> เอกสารประกอบการตัดสินใจเรื่อง scale/เสถียรภาพ/ต้นทุน — อ้างอิง [technical-design/00](technical-design/00-architecture-overview.md), [zyra-sfu/AGENTS.md](../../../zyra-sfu/AGENTS.md)
> ตัวเลขเป็น **ประมาณการ** ต้องยืนยันด้วย load test จริง

---

## 1. Target & Constraints (จากทีม — อัปเดตล่าสุด)

| ค่า | จำนวน |
|-----|-------|
| **Map capacity (ต่อ 1 map)** | **100–1,000 คน** (คนสร้างเลือกได้ตาม tier) |
| Roadmap เดือน 1 | ~100 active maps |
| Roadmap เดือน 3–6 | 1,000+ active maps |
| คนต่อ 1 zone (media room) | ≤ 20 |
| คนต่อ 1 proximity group | ≤ 20 |
| Screen share ต่อ zone | สูงสุด 2 |
| เปิดกล้อง | ได้ทุกคนใน zone (≤20) |
| **Monetization** | บิลรายเดือน — สิ่งที่กินทรัพยากรเยอะ = จ่ายตาม tier/usage |

> **หัวใจ:** "จำนวน map (catalog) ≠ load. Load = peak concurrent **active** maps × คนต่อ map"
> map ที่ไม่มีคน = cost ~0 (lazy lifecycle) → catalog ใหญ่แค่ไหนก็ได้

---

## 2. สอง แกน Scaling (คนละปัญหา)

| แกน | คำอธิบาย | Bottleneck | ตัวช่วย |
|-----|----------|-----------|---------|
| **Map เยอะ** (100→1000+ maps) | horizontal multi-tenant | จำนวน node ตาม active maps | shard by `workspace_id` (§7) |
| **Map ใหญ่** (1 map = 1000 คน) | vertical — large virtual event | control-plane fan-out ใน map เดียว | **AOI** + intra-map sharding (§6) |

**Media บาวด์เสมอ:** map 1000 คน = zone เยอะขึ้น แต่ละ zone ยัง ≤20 + ≤2 share → media scale linear ตาม **active zones** ไม่ระเบิด. ตัวหนักคือ **control plane**

---

## 3. Planes (คนละ bottleneck)

| Plane | Service | Bottleneck | สรุป |
|-------|---------|-----------|------|
| Control/State | `zyra-ws` | fan-out / connections / ticker | ⚠️ หนักขึ้นที่ map 1000 คน — AOI ต้องรับภาระ |
| Media | `zyra-sfu` (LiveKit) | egress bandwidth + client decode | ⚠️ บาวด์/zone แต่รวมต้อง cluster |
| Shared state | Redis | keys / pub-sub | ⚠️ → Redis Cluster เมื่อ maps โต |
| REST/token | `zyra-api` | stateless | ✅ replica หลัง LB |

**A–E ไม่กระทบ scale** — A/D/E ลด load บน zyra-ws (§9)

---

## 4. Media Plane (บาวด์ต่อ zone — คำนวณได้แม่น)

### 4.1 สมมติฐาน bitrate (simulcast)
| Track | สูง | กลาง | ต่ำ | Audio |
|-------|-----|------|-----|-------|
| Camera | ~1.2 Mbps | ~0.4 | ~0.15 | — |
| Screen 1080p@15 | ~2.0 Mbps | ~0.8 | — | — |
| Audio Opus | — | — | — | ~0.04 |

### 4.2 Egress ต่อ 1 zone (20 คนกล้องเปิดหมด + 2 screen) — worst case
| Stream | สูตร | Egress |
|--------|------|--------|
| Camera | 20×19×0.3 | ~114 Mbps |
| Audio | 20×19×0.04 | ~15 Mbps |
| Screen | 2×19×2.0 | ~76 Mbps |
| **รวม/zone** | | **~205 Mbps** |

### 4.3 Aggregate = ผูกกับ **active zones** ไม่ใช่ catalog
```
egress ≈ active_zones × (เฉลี่ยต่อ zone)
worst/zone ~205 Mbps · realistic ~40–80 Mbps (กล้องเปิดไม่หมด + subscribe layer ต่ำ)

ตัวอย่างเดือน 3–6: active 1000 maps, เฉลี่ย map ละ 3 active zones = 3000 zones
  realistic ~60 Mbps/zone → ~180 Gbps  ← ต้อง LiveKit cluster/Cloud + autoscale จริงจัง
```
> ตัวเลขนี้ทำให้เห็นชัดว่า **media = ต้นทุนก้อนใหญ่สุด** → ผูกกับ billing (§8)

---

## 5. Client decode limit — ⚠️ วิกฤต ไม่เกี่ยว bandwidth
- 20 tile กล้องเปิด = client decode ~20 video → เครื่องอ่อน freeze/ร้อน/แบตหมด
- **บังคับ:** render จริง ~active-speaker + 8–12 tile + pagination · tile เล็กใช้ layer ต่ำ · tile ที่ไม่เห็น unsubscribe

---

## 6. Big-map handling (1 map = 1000 คน)
- **AOI คือพระเอก** — ห้าม broadcast ถึง 1000 คน; 3×3 cell (มีแล้ว) → แต่ละคนเห็น ~ไม่กี่สิบ. tune cell size ตาม density
- Map ใหญ่ 1 อันต้องอยู่ **node เดียว** (ทุกคนต้อง discoverable กัน) → node แรงพอ หรือ **shard by AOI region** ข้าม node (งานยาก = tier พรีเมียม/dedicated)
- **Ticker เฉพาะ active room** (move 50ms, chat-space 100ms) — map ใหญ่มี zone เยอะ ต้องไม่รัน ticker ให้ zone ว่าง
- 1000-คน map = เคสกินทรัพยากรสุด → **จัดเป็น tier แพง + dedicated resource**

---

## 7. Horizontal scaling (many maps)
| # | เทคนิค | แก้อะไร |
|---|--------|---------|
| 1 | **Shard by `workspace_id`** (consistent hashing) | บาวด์ memory/fan-out ต่อ node |
| 2 | **Per-workspace Redis Pub/Sub channel** | event ยิงเฉพาะ node ที่เกี่ยว |
| 3 | **Lazy lifecycle** (room/zone เกิดตอนคนเข้า, ทิ้งเมื่อว่าง) | catalog ใหญ่ = cost 0 ตอน idle |
| 4 | **Autoscale ตาม active maps/connections** (ไม่ใช่ catalog) | จ่ายตามการใช้จริง |
| 5 | **Redis Cluster shard by `{workspace_id}`** | keys หลายล้านตัว |
| 6 | **Workspace-aware gateway routing** | user เข้า map เดียวกัน → node เดียวกัน |

**ช่องว่างใหญ่สุด:** `zyra-ws` วันนี้เป็น single-hub ถือทุก workspace → ต้องทำ **sharded elastic cluster** ก่อนถึงจะรับ maps เยอะได้จริง

---

## 8. Billing-tier = Resource Governor ⭐ (ผูก cost เข้า revenue)

"สิ่งที่กินทรัพยากรเยอะ = จ่ายรายเดือน" → ผูก resource เข้า tier + meter usage

### สิ่งที่ต้อง meter (ต่อ workspace/เดือน)
| Metric | ทำไมกินทรัพยากร |
|--------|------------------|
| CCU-minutes | node control-plane |
| Media participant-minutes (video) | bandwidth ก้อนใหญ่สุด |
| Screen-share minutes | bitrate สูง |
| Recording hours | egress + storage + compute |
| Peak map capacity | node แรง (100/500/1000) |

### ตัวอย่าง tier (ปรับได้)
| Tier | Map capacity | Media | Governor |
|------|-------------|-------|----------|
| Free/เล็ก | ≤100 | audio + camera | quota นาที, ไม่มี recording |
| Pro | ≤500 | + screen share, res สูง | + overage billing |
| Enterprise | ≤1000 | + recording, dedicated | region + hard SLA |

→ tier เป็น **hard cap ในตัว** กัน abuse + map แพง (1000) จ่ายค่า node/bandwidth ที่มันสร้างเอง
→ ต้องมี **metering + quota enforcement subsystem** (อิง LiveKit stats + zyra-ws presence)

---

## 9. A–E กระทบ scale ไหม?
| # | ทางเลือก | ผล |
|---|----------|-----|
| A | LiveKit native events | 🟢 ลด WS traffic |
| B | webhook-driven state | 🟡 webhook เบา (join/leave/track) — **ยังใช้เป็นแหล่ง metering ได้ด้วย** |
| C | server-side force-mute | 🟢 negligible |
| D | path-based movement | 🟢 ลดมาก (สำคัญที่ map 1000 คน) |
| E | setMicrophoneEnabled | 🟢 native, ไม่เพิ่ม WS |

---

## 10. Reliability — "ไม่หลุด ไม่ตัดตอนพูด" (6 ชั้น)

**หลักการ: Audio-first — เสียงต้องรอด, ภาพทิ้งได้**

| ชั้น | เทคนิค | กันอะไร |
|------|--------|---------|
| 1 Audio | **RED** (redundancy) + Opus **FEC** + **DTX** + แยก audio จาก adaptive | เสียงขาดตอน loss (รอดถึง ~30% loss) |
| 2 Video degrade | simulcast/dynacast (✅) + adaptiveStream + **track priority** (กล้อง drop ก่อน) | freeze → เปลี่ยนเป็นลด quality นุ่ม ๆ |
| 3 Connection | **TURN over TCP/TLS 443** + ICE restart + reconnect buffer (SC-RTE-02) + regional (RTT ต่ำ) | หลุดจาก firewall/NAT/IP เปลี่ยน |
| 4 Client CPU | cap video tile (§5) + unsubscribe off-screen | freeze บนเครื่องอ่อน |
| 5 Infra HA | multi-node + room distribution + autoscale headroom ~30% + graceful drain | 1 node ล่มไม่ลากทั้งระบบ |
| 6 ลด load ต้นเหตุ | camera default-off (SC-RTE-06 ✅) + active-speaker video + spotlight | ลด stream ที่ต้องส่ง |

**Monitoring:** LiveKit `ConnectionQualityChanged` → indicator + auto-downgrade เชิงรุกก่อน loss

**3 อย่างผลสูงสุด:** (1) Audio RED+FEC (2) track priority กล้อง-drop-ก่อน (3) TURN/443 fallback + camera-default-off

---

## 11. Config ที่ต้องปรับ
| Config | ตอนนี้ | ควรเป็น |
|--------|--------|---------|
| LiveKit `max_participants` | 50 | **20/zone** (set ต่อ room ผ่าน token) |
| `enable_dynacast` | true ✅ | คงไว้ (จำเป็นมาก) |
| Proximity cap | auto-form 2+ | เพิ่ม cap ≤ 20 |
| Audio RED/FEC/DTX | — | **เปิด** (reliability ชั้น 1) |
| TURN TLS 443 | 7881 TCP | เพิ่ม TLS/443 |
| `use_external_ip` | false (dev) | **true** prod |

---

## 12. Roadmap Phasing
| ช่วง | Active maps | ต้องมี |
|------|-------------|--------|
| **เดือน 1** | ~100 | cluster เล็ก + autoscale · **เริ่ม metering ตั้งแต่ต้น** · reliability ชั้น 1–3 |
| **เดือน 3–6** | 1,000+ | **workspace sharding + Redis Cluster + billing enforcement + ตัดสิน hosting** |
| **ก่อนรับ map 1000 คน** | — | big-map handling (§6) + AOI tuning + load test เต็มรูปแบบ |

---

## 13. Decisions ที่ต้องเคาะ
1. **Hosting media: LiveKit Cloud vs self-host vs hybrid** — ⏳ ยังไม่ตัดสิน. แนะนำ: เดือน 1 (100 maps) เริ่ม Cloud/hybrid ลด ops → reassess ก่อน 1000 maps ดู margin vs volume
2. **Tier structure จริง** (capacity/feature/quota ต่อ tier) — กระทบทั้ง governor + UX
3. **Metering subsystem** — สร้างเอง, หรือใช้ LiveKit Cloud usage API + เสริม
4. **Big-map (1000) strategy** — dedicated node? intra-map AOI sharding? หรือจำกัด media zone ต่อ map
5. **Video tile cap** — กี่ tile/หน้าจอ (แนะนำ active-speaker + 8–12)

---

## 14. Load Test Plan
| Test | เป้า | Pass |
|------|------|------|
| WS: **1 map 1000 CCU** path-based + AOI | fan-out/latency บน node เดียว | p95 < 500ms, ไม่ drop |
| WS: 1000 active maps (sharded) | rebalance/routing | ไม่มี node saturate |
| Media: 1 zone 20 cam + 2 screen | egress/decode/latency | < 500ms, ไม่ drop frame |
| Reliability: inject 30% packet loss | audio ต่อเนื่อง | เสียงไม่ตัด (RED/FEC ทำงาน) |
| Client อ่อน: render N tiles | CPU/FPS | ≥ 24 fps |
| Failover: node ล่ม | maps migrate | reconnect < grace (SC-RTE-02) |
| Metering: usage นับถูก | CCU/media-minutes/egress | ตรงกับ billing |

> media plane ใช้ LiveKit `livekit-load-tester`
