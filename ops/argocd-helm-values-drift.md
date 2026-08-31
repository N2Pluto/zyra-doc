# Landmine: the node's Argo CD Helm values have drifted, and a re-run wipes the accounts

Found 2026-08-20 while applying the control-plane log-level change (zyra-infra#19).
**Nothing is broken right now.** This is a trap waiting for the next person who
touches Argo CD's Helm release.

## What is wrong

Argo CD is not GitOps-managed — it is a k3s `HelmChart` written by cloud-init to
`/var/lib/rancher/k3s/server/manifests/argocd.yaml`, rendered from
`zyra-infra/terraform/cloud-init-k3s.yaml.tftpl`.

Those two have diverged. The file on the node is **516 bytes** and its
`valuesContent` contains only:

```yaml
configs:
  params:
    server.insecure: true
```

The tftpl additionally carries the local accounts and the RBAC policy:

```yaml
  cm:
    accounts.devops: apiKey, login
    accounts.tendev: apiKey, login
  rbac:
    policy.default: role:readonly
    policy.csv: |
      g, devops, role:admin
      g, tendev, role:admin
```

Even the comment text differs, so the node file is not a stale render of the
current template — it is a different file.

## Why it matters

Those accounts are live, and they are **Helm-managed**:

- `argocd-cm` has `accounts.devops` and `accounts.tendev`, labelled
  `app.kubernetes.io/managed-by: Helm`, `helm.sh/chart: argo-cd-10.3.0`
- `argocd-rbac-cm` has `policy.csv` = `g, devops, role:admin` /
  `g, tendev, role:admin` and `policy.default: role:readonly`

So the release that produced them used the **full** values, while the manifest on
disk no longer contains them. The next `helm upgrade` driven by that manifest
re-renders both ConfigMaps from the values it can see — dropping both accounts
and resetting the RBAC policy. devops and tendev lose their Argo CD logins.

There is no `HelmChartConfig` layering them back in (checked: none exists in any
namespace), and `helmchart/argocd`'s stored `valuesContent` contains the string
`accounts` zero times. Nothing puts them back.

A second, separate hazard sits next to it: the argo-cd chart also manages
`argocd-secret`, which is where account passwords live (set out-of-band with
`argocd account update-password`, deliberately never in git). A chart upgrade that
re-renders that secret can reset them.

## What triggers it

Any helm-controller re-run for this chart: editing the manifest, bumping
`argocd_chart_version`, or a k3s upgrade that re-applies bundled manifests and
sees changed content.

## What was done instead

The log-level change was applied **directly to the ConfigMap** rather than through
Helm, precisely to avoid triggering this:

```bash
kubectl -n argocd patch cm argocd-cmd-params-cm --type merge \
  -p '{"data":{"controller.log.level":"warn", ...}}'
kubectl -n argocd rollout restart \
  statefulset/argocd-application-controller \
  deploy/argocd-repo-server deploy/argocd-notifications-controller
```

That reaches the same place `global.logging.level` would (each component reads
its level from `argocd-cmd-params-cm` via `env valueFrom configMapKeyRef`), with
no Helm involvement. The trade-off: it is out-of-band, so a future Helm run
reverts it — which is acceptable, since a future Helm run is the thing that needs
fixing first.

## Fixing it properly (needs a human)

Reconciling the node manifest to the tftpl would make a Helm run safe for the
accounts, and it is the same edit that would set the log level the intended way.
It still needs a decision about `argocd-secret`: confirm whether the chart would
re-render it and whether the current passwords survive, ideally by capturing
`kubectl -n argocd get secret argocd-secret -o yaml` first and being ready to
restore it.

Until that is done, treat **any** Argo CD Helm operation as an access-losing
change and schedule it with the people who hold those accounts.
