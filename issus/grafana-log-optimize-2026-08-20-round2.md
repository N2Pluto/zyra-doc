# Grafana log audit — round 2 (2026-08-20, evening)

Follow-up to `grafana-optimize-2026-08-20.md`, run after the day's fixes landed
(403 loop, LiveKit v1.13.5, Prometheus dedup, disk prune, Alertmanager).
Everything below is measured against live Loki/Prometheus, not inferred.

**Headline: the obstacles 403 loop is gone, and what it was hiding is that
almost all remaining traffic and log volume is heartbeats and health probes.**

## Log volume, 1h window — 53,587 lines total

| Source | lines/h | share | what it is |
|---|---|---|---|
| argocd (3 pods) | 12,236 | 23% | reconcile chatter at info |
| loki | 9,031 | 17% | Loki logging its own queries |
| zyra-api prod | 8,688 | 16% | 94% presence / refresh / health |
| zyra-notifications (3 envs) | 2,880 | 5% | **100% `GET /healthz`** |
| zyra-api dev + uat | 3,232 | 6% | same shape |
| zyra-ws prod + dev | 864 | 2% | |
| zyra-sfu | 64 | 0.1% | was 46–150/interval before v1.13.5 |

~80% of everything Loki ingests is health probes, heartbeats and control-plane
info. None of it is product signal, and it buries the signal that is.

## A. Auth refresh is being used as a change-detection poll

`components/auth-guard.tsx:22` — `POLL_INTERVAL_MS = 30_000`. Every open tab
calls `POST /api/authen/refresh` every 30s for one reason: to notice that
someone changed the account password.

Measured over 6h: **23,346 calls, 23,296 × 200 and 31 × 401** — not an error
loop, just a very chatty success path. That is **1.08 rps**.

Each call is a full write transaction (`auth_service.go:484`):

```
BEGIN
  SELECT tb_user                       (findUserByID)
  SELECT tb_user_security_session      (validateAndTouchSecuritySession)
  UPDATE tb_user_security_session SET last_seen_at = NOW()
COMMIT
+ JWT sign, 2 Set-Cookie
```

Prod runs **12.54 commits/s** total, so this poll alone is **8.6% of every
transaction on the production database**, forever, for an event that happens
approximately never.

Options, cheapest first:
1. `POLL_INTERVAL_MS` 30s → 5min. 10× cut, 5 lines, detection latency on a rare
   security event goes from 30s to 5min.
2. A `GET /api/authen/session-state` that answers 204/401 from the token's `iat`
   vs `last_password_reset` **without** minting a token or touching
   `last_seen_at`. Keeps 30s detection, removes the write.
3. Push it over the existing WS connection — but AuthGuard covers every page,
   not just VO, so this doesn't cover everyone.

## B. The VO presence heartbeat writes the DB on every beat

`POST /api/user/workspaces/{id}/presence` — **37,425 calls / 6h = 1.73 rps**.
`WorkspacePresenceHub.Heartbeat` stores in memory and then fires
`go savePresenceState(...)`, which does a Redis GET (obstacle grid) plus an
`UPDATE tb_workspace_member`.

That is **1.73 write tx/s = 13.8% of prod commits**, plus 1.73 Redis GET/s of
the 7.13 ops/s total.

Worth noting the position is *already* flowing over the zyra-ws socket at 20Hz.
The HTTP heartbeat is a second, redundant channel for the same fact.

Cheapest fix: skip the UPDATE when the tile is unchanged and `last_visited_at`
was touched recently — the same coalescing idea as the obstacle-grid debounce
(api#28). An idle seated user currently generates a write every beat.

For contrast, `POST /api/user/presence` (**24,535 / 6h = 1.14 rps**) is honest:
`AppHeartbeat` only does `h.appSeen.Store(userID, now)` and persists nothing.
Its cost is HTTP + JWT verify + 24k log lines, not DB.

**Together A + B = 2.81 write tx/s of the 12.54 commits/s on prod — 22.4% of all
production database transactions are polls.**

## C. The access log logs health probes

`zyra-notifications` emits 1,440 lines/h in prod and every single one is
`GET "/healthz"` from the kubelet probe (2 replicas × 720). dev and uat add 720
each.

A skip-path middleware for `/healthz` and `/api/health`, plus dropping or
sampling the two presence paths, removes ~90% of zyra-api's and 100% of
zyra-notifications' log volume with zero product impact.

## D. Control plane is 40% of all log volume

argocd 12,236/h + loki 9,031/h = 21,267 of 53,587 lines. Neither is product
traffic. Both take a log-level value in their chart values.

## E. Still open from earlier work

- **22 deadlocks in 6h on prod `postgres`** (`pg_stat_database_deadlocks`). The
  fix is merged to develop (api#27) and has not been promoted.
- **Obstacle republish has no debounce on prod** — 5 `obstacle grid published`
  lines in a 20-minute window, one per map edit. Debounce is api#28 on develop.
- **23 of 42 prod workspaces have empty obstacle grids** (`0/0`), so zyra-ws
  fails open and players walk through everything there. Needs
  `obstacle-backfill --apply`, but only after app#130 + api#23 reach prod, or
  the server becomes stricter than the shipped client.

## Ranking

| # | Item | Measured cost | Effort |
|---|---|---|---|
| 1 | Refresh poll interval / dedicated endpoint | 8.6% of prod tx, 1.08 rps | 5 lines → small endpoint |
| 2 | Presence UPDATE coalescing | 13.8% of prod tx | small |
| 3 | Access-log skip paths | ~80% of log ingest | small |
| 4 | argocd + loki log level | 40% of log ingest | values.yaml |
| 5 | Promote api#27 (deadlock) | 22 deadlocks/6h | merge only |
| 6 | Promote api#28 (debounce) | full map read per edit | merge only |

---

# Outcome (same evening)

All four items shipped to develop/main. Measured live, with the diurnal caveat
stated below.

| # | Item | Where | Result |
|---|---|---|---|
| 1 | Refresh poll → read-only endpoint | api#31 + app#143 | 3.2× faster/call, DB footprint ≈ no-DB endpoint |
| 2 | Presence write coalescing | api#33 | 100 identical beats: 96 → 5 row updates |
| 3 | Access-log skip paths | api#34, notifications#11 | notifications dev **720/h → 0** |
| 4 | Control-plane log levels | infra#19, #20 | argocd −80%, loki container **→ 0** |
| — | vitest gates CI | app#144 | 849 tests now block a PR instead of being discarded |

## What is attributable, and what is just evening

Cluster total went **53,587 → 13,965 lines/hour**. Do not read all of that as the
work: the first measurement was taken during working hours. `zyra-api` in prod is
still on the OLD image (prod was not promoted) and its own volume fell
8,688 → 4,410 over the same period, so traffic-driven logs carry roughly a 2×
diurnal factor.

The control plane is not traffic-driven, so those numbers are clean:

| source | before | after | attributable |
|---|---|---|---|
| loki (container) | 9,031/h | **0** | yes — `logs loki-0 -c loki --since=5m` returns 0 lines |
| argocd application-controller | 4,117/h | 324/h | yes |
| argocd notifications-controller | 3,758/h | 48/h | yes |
| argocd repo-server | 4,158/h | 1,980/h | yes |
| zyra-notifications dev | 720/h | **0** | yes |
| zyra-api dev | 2,151/h | 480/h | partly — dev traffic is not controlled |

Roughly **19,500 lines/hour** removed with confidence, the bulk of it control
plane. prod's share arrives when the api/notifications images are promoted.

## Two things found while verifying

**The loki figure was two containers, not one.** `app="loki"` covers the Loki
binary and the nginx gateway in front of it. `log_level: warn` took the binary to
zero; the gateway kept logging every promtail push and Grafana query — 3,444
lines/hour of 204s. Fixed separately by `gateway.verboseLogging: false`
(infra#20), which the chart documents as "Enable logging of 2xx and 3xx HTTP
requests", so 4xx/5xx stay visible.

**Promtail appeared to triple** (71 → 1,212 lines/hour) right after the change.
That was self-inflicted and transient: promtail logs a tailer start/stop per pod
log file, and the window contained the three argocd restarts, the loki restart,
the dev rollouts, and a throwaway `curltest` pod used to prove the notifications
probe still passed. Not a regression.

## Argo CD was deliberately NOT changed through Helm

See `argocd-helm-values-drift.md`. The node's HelmChart values have drifted and no
longer contain the devops/tendev accounts that are live and Helm-managed, so any
`helm upgrade` would drop those logins. The log level went in as a direct
`argocd-cmd-params-cm` patch plus a rollout restart of the three noisy
components, with no Helm involvement. infra#19 carries the equivalent
`global.logging.level: warn` in the tftpl for a future VM rebuild.

After the restart: all **23 Argo Applications Synced + Healthy**, and the new
repo-server pod reports `ARGOCD_REPO_SERVER_LOGLEVEL=warn`.

## Still open from this round

- **prod promotion** of items 1–3 (api develop→main, app develop→main)
- **infra#20** (loki gateway) not yet merged
- Reconciling the Argo CD HelmChart drift — needs a human, see the landmine doc
- 2 pre-existing `tsc` errors in `__tests__/pixi-game-scene.test.ts` block a
  typecheck gate (`avatar_url` is not on `RemotePlayerSnapshot`)
- `last_seen_at` is still written on the refresh path with no readers anywhere

---

# Addendum: the loki gateway took four attempts

infra#20 set `gateway.verboseLogging: false` and Argo synced it, but it could not
take effect. Three distinct problems, each only visible after fixing the one in
front of it:

1. **Required anti-affinity on a one-node cluster.** The chart ships a hard
   `podAntiAffinity` on `kubernetes.io/hostname` for the gateway. With
   RollingUpdate at `maxUnavailable: 25%` (rounding to 0 at `replicas: 1`) the
   replacement can never schedule and the incumbent is never released. The pod
   serving at the time was **14 days old** — it had never once updated.
2. **`affinity: {}` does not remove it.** The chart's default for that key is a
   *map*, and Helm *merges* maps, so an empty map merges to exactly the default.
   infra#21 shipped `{}` and changed nothing; the live Deployment kept its
   anti-affinity byte-for-byte. The working form is `podAntiAffinity: null`
   (infra#22). The same ineffective `{}` has been sitting on `singleBinary` since
   the file was written — harmless there only because a StatefulSet replaces a pod
   under the same name, so it never conflicts with itself.
3. **The old pod's anti-affinity still blocked the new one.** After the fix the
   error changed from `didn't match pod anti-affinity rules` to `didn't satisfy
   EXISTING pods anti-affinity rules` — Kubernetes enforces an incumbent's rules
   against newcomers, and the incumbent still carried the old spec. Broken by
   deleting the old pod by hand.

Cost: a **~9 second** gateway gap (15:49:59 → 15:50:08) during which promtail
logged `error sending batch, will retry` and then recovered on its own. No data
lost, and the previous 14 days of failed rolls were never noticed by anyone.

## Verified end state

| container | before | after |
|---|---|---|
| loki | 9,031/h | **0** |
| loki-gateway nginx | 3,444/h | **0** |
| loki-sc-rules | 120/h | 120/h (untouched) |

Checked, not assumed: the running pod's `.spec.affinity` is empty, its
`/etc/nginx/nginx.conf` contains `access_log /dev/stderr main if=$loggable`, all
**23 Argo Applications are Synced + Healthy**, and promtail has logged no push
errors since 15:50:08.

## What the quiet revealed — candidates for a round 3

With the heartbeat noise gone, the loudest remaining lines on dev are ones nobody
could see before:

- **`GET /api/maintenance`** — roughly one every 3-7 seconds. `proxy.ts` calls
  `checkMaintenance()` on every request to a protected route, so this is a
  per-request server-side poll and it is now the top log line on the service.
- **`POST /api/admin/presence/heartbeat`** — the admin dashboard's own presence
  beat, a different route from the two user-side ones that were skipped, and not
  covered by zyra-api#34.

Also confirmed live on dev: `GET /api/authen/session-state` (api#31) is serving
200s, so the client half (app#143) is exercising the new cheap path.

Note dev's zyra-api volume read 480/h shortly after the deploy and 1,820/h twenty
minutes later. That is not a regression — somebody was using the dev admin
dashboard, and those are real API calls, which is exactly what the log should
still contain.

---

# Shipped to prod as v1.1.17

All four services (api, app, ws, notifications) on `v1.1.17`, 0 restarts.
Verified on the live prod pods:

| check | result |
|---|---|
| `/api/maintenance` | 200 `{"enabled":false}` — the migrations landed |
| `/api/health` | ok, v1.1.17, database + storage ok |
| `/api/admin/support/tickets` | **401, not 500** — the live bug is fixed |
| `/api/authen/session-state` | 401, not 404 — new endpoint serving |
| prod api log, 60s | **39 lines, health probes = 0** |
| error/panic, 3 min | none |

Prod api log volume: 8,688/h at peak this morning → **2,340/h** on the same
service after the skips (evening traffic accounts for part of it; health probes
account for exactly zero now).

## Next finding, found while verifying: gin runs in debug mode on prod

```
[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:	export GIN_MODE=release
```

That is **264 `[GIN-debug]` route-table lines on every boot** plus gin's debug
path per request. Setting `GIN_MODE=release` in the prod env removes both. It also
means the 432-lines-in-30s reading taken right after the rollout was 264 lines of
boot noise, not a regression — worth knowing before someone panics at it.

## Still open

- `obstacle-backfill --apply` — now unblocked (app#130 + api#23 are on prod).
  **23 of 42 prod workspaces still have empty obstacle grids**, so players walk
  through everything in them.
- The Argo CD HelmChart drift (`argocd-helm-values-drift.md`) — needs a human.
- 2 pre-existing `tsc` errors in `__tests__/pixi-game-scene.test.ts` block a
  typecheck gate.
- `last_seen_at` is still written on the refresh path with no readers.
