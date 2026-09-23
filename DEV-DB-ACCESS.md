# Dev access to prod AlloyDB & Redis (IAP tunnel)

How a developer connects to **production** AlloyDB (Postgres) and Memorystore
(Redis) from their laptop. Both are **private-IP only** — there is no public
endpoint by design. You reach them by SSH-tunnelling through the `zyra-sfu` VM
over Google IAP (no VPN, no exposed port).

```
your laptop ──IAP tunnel──▶ zyra-sfu VM ──VPC──▶ AlloyDB 10.66.122.2:5432
  (gcloud, your Google id)   (jump host)         Redis    10.107.20.91:6379
```

> Access is **tunnel-only**: you get an SSH port-forward, **not** `sudo`/root on
> the VM. You cannot read the VM's Secret Manager env or touch prod containers.

---

## TL;DR

```bash
# 1. one tunnel, both services (leave this terminal running)
gcloud compute ssh zyra-sfu --tunnel-through-iap --zone asia-southeast1-b --project gather-dev-458614 \
  -- -N -L 5432:10.66.122.2:5432 -L 6379:10.107.20.91:6379

# 2. in another terminal
psql "host=localhost port=5432 dbname=postgres user=zyra sslmode=require"   # prompts for password
redis-cli -h localhost -p 6379 -a "<redis-auth>"
```

Credentials (`<password>`, `<redis-auth>`) come from an admin — see
[Credentials](#credentials).

---

## Prerequisites

1. **`gcloud` CLI** installed and logged in:
   ```bash
   gcloud auth login              # your @hpktechnology.com account
   gcloud config set project gather-dev-458614
   ```
2. **IAP tunnel access** — your Google account must be in
   `var.iap_tunnel_members` (`zyra-infra/terraform/variables.tf`). An admin adds
   you and runs `terraform apply`; you then have `roles/compute.osLogin` +
   `roles/iap.tunnelResourceAccessor`. Ask an admin if `gcloud compute ssh` below
   fails with a 403.
3. **DB / Redis credentials** — shared by an admin (not derivable from your
   grant). See [Credentials](#credentials).

---

## Connection facts

| | Host (private) | Port | Auth | Notes |
|---|---|---|---|---|
| AlloyDB (Postgres) | `10.66.122.2` | `5432` | user `zyra` + password | `dbname=postgres`, **SSL required** (`sslmode=require`) |
| Redis (Memorystore) | `10.107.20.91` | `6379` | AUTH string | BASIC tier, Redis 7.2 |

- Project `gather-dev-458614`, region `asia-southeast1`, jump host VM `zyra-sfu`
  in zone `asia-southeast1-b`.
- AlloyDB's default database is `postgres` — no Terraform resource creates a
  `zyra` DB. Use `postgres` unless an admin has created and switched to `zyra`.

---

## Open the tunnel

`-N` = no remote shell (forward only). Keep this terminal open while you work.

```bash
gcloud compute ssh zyra-sfu \
  --tunnel-through-iap \
  --zone asia-southeast1-b \
  --project gather-dev-458614 \
  -- -N \
     -L 5432:10.66.122.2:5432 \
     -L 6379:10.107.20.91:6379
```

**Local port already in use?** (you run Postgres/Redis locally) — pick different
left-hand ports and point your client at those:

```bash
  -- -N -L 15432:10.66.122.2:5432 -L 16379:10.107.20.91:6379
# then: psql "host=localhost port=15432 ..."  /  redis-cli -p 16379 ...
```

---

## Connect — AlloyDB (Postgres)

```bash
# psql (SSL is required — keep sslmode=require)
psql "host=localhost port=5432 dbname=postgres user=zyra sslmode=require"

# or a DATABASE_URL
postgres://zyra:<password>@localhost:5432/postgres?sslmode=require
```

GUI clients (DBeaver / TablePlus / DataGrip): host `localhost`, port `5432`,
db `postgres`, user `zyra`, **SSL mode = require**. The tunnel forwards raw TCP,
so SSL is negotiated end-to-end with AlloyDB — leave SSL on.

## Connect — Redis

```bash
redis-cli -h localhost -p 6379 -a "<redis-auth>"
# URL form: redis://:<redis-auth>@localhost:6379
```

No TLS on the Redis listener (Memorystore BASIC, in-transit encryption off) — the
IAP tunnel is the encrypted hop. Don't pass `--tls`.

---

## Credentials

Your tunnel grant gives you the **network path only** — not the passwords. An
admin (someone with Terraform state access) fetches and shares them:

```bash
cd zyra-infra/terraform
terraform output -raw prod_db_password     # AlloyDB password for user `zyra`
terraform output -raw prod_redis_url       # redis://:<auth>@10.107.20.91:6379
```

Treat both as **production secrets**: don't commit, paste into chat/tickets, or
store in a shared doc. Ask for them over a secure channel; rotate if leaked.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `gcloud compute ssh` → `403` / `Permission denied` | Not in `iap_tunnel_members`, or missing `osLogin`/`tunnelResourceAccessor`. Ask an admin to add you + `terraform apply`. |
| `reauth related error (invalid_rapt)` | ADC/session expired → `gcloud auth login` again. |
| SSH connects but `psql` times out | Tunnel not open, or wrong local port. Confirm the `-L` terminal is still running. |
| `psql: SSL required` / SSL errors | Keep `sslmode=require` — AlloyDB rejects plaintext. |
| Redis `NOAUTH` / `WRONGPASS` | Missing or wrong `-a <auth>`; get a fresh value from `prod_redis_url`. |
| `bind: address already in use` | Local 5432/6379 taken → use `-L 15432:...` etc. |

---

## What this grant does / doesn't allow

- ✅ SSH-tunnel through `zyra-sfu` and port-forward to AlloyDB / Redis.
- ✅ Full read/write on the DB and Redis **once you have the credentials** (there
  is no per-user DB role split — the `zyra` user is the app user).
- ❌ No `sudo`/root on the VM, no Secret Manager env, no container control
  (that's the admin `iap_ssh_members` list, not this one).

> **Prod data.** This is the live database. Treat writes with care; prefer
> read-only queries unless you know what you're doing. Coordinate schema changes
> through the normal migration flow, not ad-hoc `psql`.

---

*Access model provisioned in `zyra-infra/terraform` — `var.iap_tunnel_members`
(variables.tf) + `google_project_iam_member.iap_tunnel_*` (iam.tf). See
`../PRODUCTION.md` for the full prod runbook.*
