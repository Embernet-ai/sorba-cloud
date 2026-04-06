# 🔥 SORBA Cloud — EmberNET App Store Wrapper Chart

> **What this is:** An EmberNET wrapper chart for the SORBA Cloud IoT platform  
> **What it wraps:** `oci://sorbaregistry.azurecr.io/helm/sorba-cloud` (SORBA's upstream chart)  
> **What it is NOT:** The SORBA SDE — that's in `sorbotics-pod` (a separate product)

---

## 💀 What's Going On Here

There are **two SORBA products** in the EmberNET ecosystem:

| Product | Repo | What It Is |
|---------|------|------------|
| **SORBA SDE** (Smart Data Engine) | `sorbotics-pod` | Edge data collection gateway — single pod, deploys per-node |
| **SORBA Cloud** (IoT Platform) | `sorba-cloud` (this repo) | Full cloud platform — MySQL, InfluxDB, Redis, Grafana, MQTT, VPN, AI, NodeRed |

This chart is for **SORBA Cloud** — the full platform. It's based on the SORBA helm chart deployment guide for private AKS clusters.

## 🏗️ How It Works

This is a **wrapper chart**. It does NOT contain the actual SORBA Cloud application. Instead:

1. **Chart.yaml** declares the upstream SORBA chart as a dependency:
   ```yaml
   dependencies:
     - name: sorba-cloud
       version: "1.3.0"
       repository: "oci://sorbaregistry.azurecr.io/helm"
       alias: upstream
   ```

2. **values.yaml** passes configuration through to the upstream chart via the `upstream:` key

3. **The wrapper adds:**
   - A lightweight nginx bridge pod with EmberNET Big Four store labels
   - A ClusterIP service for the dashboard iframe proxy
   - A ConfigMap for the bridge's nginx reverse proxy config

The upstream chart handles everything else: MySQL, InfluxDB, Redis, Grafana, MQTT broker, NodeRed, AI Trainer, VPN, Identity, API Gateway, ingress-nginx, cert-manager integration.

## 📦 Repository Structure

```
sorba-cloud/
├── charts/
│   └── sorba-cloud/
│       ├── Chart.yaml              ← Wrapper chart with upstream OCI dependency
│       ├── values.yaml             ← EmberNET config + upstream passthrough values
│       └── templates/
│           ├── _helpers.tpl        ← Standard helpers + store labels
│           ├── deployment.yaml     ← Bridge pod (EmberNET labels only)
│           ├── service.yaml        ← ClusterIP service (dashboard proxy target)
│           ├── configmap.yaml      ← Nginx proxy config for bridge
│           ├── secrets.yaml        ← Registry credentials (bridge pod only)
│           └── NOTES.txt           ← Post-install output with SORBA URLs
├── .github/
│   └── workflows/
│       └── helm-publish.yml        ← GH Pages Helm repo publish
└── README.md                       ← You are here
```

## 🚀 Deployment

### Prerequisites

1. **SORBA registry credentials** (username + token) from the SORBA team
2. **cert-manager** installed on the cluster
3. **DNS access** for ACME challenge and wildcard records
4. **Helm registry login:**
   ```bash
   helm registry login sorbaregistry.azurecr.io -u <USERNAME> -p <TOKEN>
   ```

### 1. Create the Registry Secret

```bash
kubectl create secret docker-registry sorba-registry-secret \
  --docker-server=sorbaregistry.azurecr.io \
  --docker-username=<USERNAME> \
  --docker-password=<TOKEN> \
  -n <namespace>
```

### 2. Set Up DNS

```bash
# ACME challenge for SSL certificates
_acme-challenge.{tenant}.{domain} CNAME daed2c11-cadc-43cc-8564-53174c6ab6f6.auth.acme-dns.io

# After deployment — wildcard A record pointing to ingress external IP
*.{tenant}.{domain} A <EXTERNAL_IP>
```

### 3. Configure and Deploy

```yaml
# values.yaml
upstream:
  global:
    domain: "yourdomain.com"
    tenant: "your-tenant"
    version: "1.3.0"
    credentials:
      enabled: true
      registry: sorbaregistry.azurecr.io
      username: <USERNAME>
      password: <TOKEN>
    secrets:
      mysql:
        MYSQL_PASSWORD: "<secure>"
      influx:
        INFLUX_PASSWORD: "<secure>"
      grafana:
        GRAFANA_PASSWORD: "<secure>"
      mqtt:
        MQTT_PASSWORD: "<secure>"
```

```bash
helm dependency update charts/sorba-cloud
helm install sorba-cloud charts/sorba-cloud -n <namespace> --create-namespace -f values.yaml
```

### 4. Get External IP and Set Wildcard DNS

```bash
kubectl -n <namespace> get svc -l app.kubernetes.io/component=controller
# Copy EXTERNAL-IP → create wildcard DNS record
```

## 🏷️ EmberNET Store Labels

The bridge pod and service carry all four required labels:

| Label | Value |
|-------|-------|
| `embernet.ai/store-app` | `"true"` |
| `embernet.ai/gui-type` | `"web"` |
| `embernet.ai/app-name` | `"sorba-cloud"` |
| `embernet.ai/gui-port` | `"443"` |

## 🔗 Dashboard Registration

In `store.go`:
```go
"https://embernet-ai.github.io/sorba-cloud/index.yaml",
```

## 🌐 SORBA Cloud Services

| Application | URL |
|------------|-----|
| IoT Platform | `https://platform.{tenant}.{domain}` |
| Dashboard (Grafana) | `https://dashboard.{tenant}.{domain}` |
| AI Trainer | `https://ml-ui.{tenant}.{domain}` |
| Identity | `https://identity.{tenant}.{domain}` |
| Task Flow | `https://taskflows.{tenant}.{domain}` |
| VPN | `https://vpn.{tenant}.{domain}` |
| Workflow (NodeRed) | `https://workflow.{tenant}.{domain}` |
| API Gateway | `https://gateway.{tenant}.{domain}` |
| InfluxDB API | `https://influx.{tenant}.{domain}` |
| MQTT Broker | `tcp://broker.{tenant}.{domain}:8883` |

---

*Built with Go, Helm, and proper architecture. — Patrick Ryan, CTO*
