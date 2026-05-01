# SORBA Cloud Bridge Chart — Release Checklist

> **Repository:** `Embernet-ai/sorba-cloud`
> **Chart Name:** `sorba-cloud`
> **GitHub Pages:** `https://embernet-ai.github.io/sorba-cloud/`

Follow every step. In order. Don't freelance.

---

## 1. Version Bump

One file. Two fields. This chart does NOT build its own Docker image — the bridge runs `nginx:alpine` from Docker Hub. Only bump `appVersion` when the upstream SORBA Cloud platform releases a new version.

- [ ] `charts/sorba-cloud/Chart.yaml` — bump `version` (e.g., `1.4.0` → `1.4.1`)
- [ ] `charts/sorba-cloud/Chart.yaml` — update `appVersion` if the upstream SORBA Cloud platform version changes

---

## 2. Quality Gates

### Helm Lint

```bash
helm lint charts/sorba-cloud
```

### Template Dry-Run

```bash
helm template test-release charts/sorba-cloud > /dev/null
helm template test-release charts/sorba-cloud --set sorba.domain=test.com --set sorba.tenant=test > /dev/null
```

Zero errors on both or you're not shipping.

---

## 3. EmberNET Store Labels (The Big Five)

All five labels MUST appear on **both** the pod template AND the service:

| Label | Expected Value | Verified? |
|-------|---------------|-----------|
| `embernet.ai/store-app` | `"true"` | [ ] |
| `embernet.ai/gui-type` | `"web"` | [ ] |
| `embernet.ai/app-name` | `"sorba-cloud"` | [ ] |
| `embernet.ai/gui-port` | `"443"` | [ ] |
| `embernet.ai/chart-name` | `"sorba-cloud"` | [ ] |

```bash
helm template test-release charts/sorba-cloud | grep -c "embernet.ai"
# Expected: 10 (5 labels × 2 resources: pod template + service)
```

- [ ] All 5 labels present on **pod template labels** (deployment.yaml)
- [ ] All 5 labels present on **Service labels** (service.yaml)
- [ ] All 5 labels generated via `sorba-cloud.storeLabels` helper (not hardcoded)
- [ ] `_helpers.tpl` contains `sorba-cloud.storeLabels` helper with all five labels

---

## 4. Service Configuration (FQDN Proxy Routing)

The EmberNET dashboard proxy constructs the FQDN as `{release-name}.{namespace}.svc.cluster.local`. The Service name MUST equal the release name.

```bash
helm template test-release charts/sorba-cloud | grep "name: test-release"
# Expected: Service name is exactly "test-release"
```

- [ ] Service name uses `{{ .Release.Name }}` — NOT `{{ include "sorba-cloud.fullname" . }}`
- [ ] Service type is `ClusterIP` by default
- [ ] Service port is `443` (maps to bridge port 8080)
- [ ] `embernet.ai/display-name` annotation present on Service

---

## 5. Bridge Configuration Verification

The bridge pod is a lightweight nginx reverse proxy to the upstream SORBA platform:

- [ ] `configmap.yaml` — nginx config proxies to `{{ .Values.sorba.platformService }}.{{ .Release.Namespace }}.svc.cluster.local`
- [ ] Health check endpoint `/healthz` is present in nginx config
- [ ] WebSocket support headers are present (`Upgrade`, `Connection`)
- [ ] DNS resolver is `kube-dns.kube-system.svc.cluster.local`
- [ ] `proxy_ssl_verify off` is set (upstream uses self-signed certs)

---

## 6. Clean Old Chart Packages

```powershell
Remove-Item sorba-cloud-*.tgz
```

Old packages are dead weight. Clean them every release.

---

## 7. Package Helm Chart

From repo root:

```bash
helm package charts/sorba-cloud -d .
```

This creates `sorba-cloud-<VERSION>.tgz` in the repo root.

Verify:

```powershell
dir *.tgz
```

---

## 8. Regenerate index.yaml

The `--url` flag is critical. Our `.tgz` files live at the **repo root**, NOT in a `/charts/` subfolder.

```bash
helm repo index . --url https://embernet-ai.github.io/sorba-cloud
```

**Verify the output** — open `index.yaml` and confirm:

- [ ] The new version entry exists with correct `version` and `appVersion`
- [ ] Download URL is: `https://embernet-ai.github.io/sorba-cloud/sorba-cloud-<VERSION>.tgz`
- [ ] **No** `/charts/` in the URL
- [ ] The `.tgz` file referenced actually exists on disk
- [ ] All Rancher annotations (`catalog.cattle.io/*`) are present

If the URL has `/charts/` in it, Rancher gets "gzip: Invalid header" forever.

---

## 9. Verify GitHub Actions Workflow

Check `.github/workflows/helm-publish.yml`:

- [ ] `actions/checkout` — `@v4` (not `@v3`)
- [ ] `azure/setup-helm` — `@v4` (not `@v3`)
- [ ] `peaceiris/actions-gh-pages` — `@v4`
- [ ] Chart name in `helm package` matches `sorba-cloud`
- [ ] `--url` in `helm repo index` matches `https://embernet-ai.github.io/sorba-cloud/`

---

## 10. Commit, Tag, Push, Release

### Review changes:

```bash
git status --short
git diff --stat
```

### Stage all changes:

```bash
git add -A
```

### Commit:

```bash
git commit -m "v<VERSION>: <summary>"
```

### Push to main:

```bash
git push origin main
```

### Create and push tag:

```bash
git tag v<VERSION>
git push origin v<VERSION>
```

The push to main triggers `.github/workflows/helm-publish.yml`, which:
1. Packages the chart
2. Generates `index.yaml`
3. Deploys to GitHub Pages

---

## 11. Verify GitHub Actions

Check the Actions tab at `https://github.com/Embernet-ai/sorba-cloud/actions`:

- [ ] Publish Helm Chart — green

### If the build fails and you need to re-tag:

```bash
git tag -d v<VERSION>
git push origin :refs/tags/v<VERSION>
# Fix whatever failed, commit, push, then:
git tag v<VERSION>
git push origin v<VERSION>
```

---

## 12. Verify Helm Repository

```bash
helm repo add sorba-cloud https://embernet-ai.github.io/sorba-cloud/ --force-update
helm repo update
helm search repo sorba-cloud --versions
```

- [ ] New version appears in search results
- [ ] No 404 or checksum errors

Deeper check:

```bash
curl -sI https://embernet-ai.github.io/sorba-cloud/index.yaml | head -5
curl -sI https://embernet-ai.github.io/sorba-cloud/sorba-cloud-<VERSION>.tgz | head -5
```

Both must return `200 OK`.

---

## 13. Verify Dashboard Integration

- [ ] Chart appears in EmberNET App Store catalog
- [ ] No "gzip: Invalid header" error
- [ ] Chart details render correctly (description, icon, resource requirements)

Verify store.go registration is current:

```bash
grep "sorba-cloud" embernet-dashboard/internal/k8s/store.go
```

Expected: `"https://embernet-ai.github.io/sorba-cloud/index.yaml",`

---

## 14. Post-Deploy Verification (On Cluster)

### Bridge Pod Verification

```bash
# Verify bridge pod is running
kubectl get pods -l app.kubernetes.io/name=sorba-cloud -n <TENANT>

# Verify bridge service has store labels
kubectl get svc -l embernet.ai/store-app=true -n <TENANT> -o wide

# Verify bridge health
kubectl exec -it deploy/<RELEASE>-sorba-cloud-bridge -n <TENANT> -- wget -qO- http://localhost:8080/healthz
```

### Upstream SORBA Platform Verification (if deployed)

```bash
# Verify upstream SORBA pods
kubectl get pods -n <TENANT>

# Test bridge → platform connectivity
kubectl exec -it deploy/<RELEASE>-sorba-cloud-bridge -n <TENANT> -- \
  wget --no-check-certificate -qO- https://platform.<TENANT>.<DOMAIN>/ | head -5
```

---

## Things That Will Ruin Your Day

| Symptom | What You Did Wrong | Fix |
|---------|-------------------|-----|
| "gzip: Invalid header" in Rancher | `--url` in `helm repo index` included `/charts/` | Regenerate: `helm repo index . --url https://embernet-ai.github.io/sorba-cloud` |
| Chart not found after push | GitHub Pages hasn't deployed yet | Wait 1-2 minutes, `helm repo update` |
| Checksum mismatch | Re-packaged chart without regenerating `index.yaml` | Delete old `.tgz`, re-package, regenerate index, commit together |
| Old version still showing | Cache | `helm repo update` + clear Rancher chart cache |
| Bridge pod CrashLoopBackOff | nginx config syntax error | Check configmap: `kubectl describe cm <RELEASE>-sorba-cloud-bridge-config -n <TENANT>` |
| Bridge pod running but 502 Bad Gateway | Upstream SORBA platform not deployed in same namespace | Deploy upstream first: `helm -n $TENANT upgrade $TENANT oci://sorbaregistry.azurecr.io/helm/sorba-cloud ...` |
| "no such host" on platform proxy | DNS resolver in nginx config wrong | Verify `resolver kube-dns.kube-system.svc.cluster.local` in configmap |
| Dashboard sees app but iframe blank | `gui-port` mismatch with service port | Verify: `values.yaml gui.port` = 443, service targets bridge port 8080 |
| Registry auth failures | SORBA registry credentials expired | Contact SORBA team for new credentials, recreate `sorba-registry-secret` |
| App has generic icon | Missing `embernet.ai/chart-name` label | Add label to `storeLabels` helper in `_helpers.tpl` |
| Service FQDN routing broken | Service name ≠ release name | Service must use `{{ .Release.Name }}`, not fullname helper |

---

## How GitHub Pages Serves the Helm Repo

- **Helm repo add URL:** `https://embernet-ai.github.io/sorba-cloud`
- **index.yaml location:** repo root (`/index.yaml`)
- **Chart packages:** repo root (`/sorba-cloud-<VERSION>.tgz`)
- **`helm repo index --url`:** `https://embernet-ai.github.io/sorba-cloud` (`.tgz` at root)

GitHub Pages deploys from the `main` branch, root folder. Every push to main triggers a Pages deploy.

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Chart Developer | | | |
| Reviewer | | | |
| Deployment Lead | | | |
