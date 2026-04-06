# 🔥 SORBA Cloud — EmberNET App Store Helm Chart

> **Built for:** The EmberNET App Store ecosystem  
> **Source from:** SORBA Cloud (sorbaregistry.azurecr.io) private AKS deployment guide  
> **Adapted by:** Patrick Ryan — CTO @ Fireball Industries  
> **Purpose:** Helm chart for deploying the full SORBA Cloud IoT platform through the EmberNET Dashboard

---

## 💀 What Is This

This repository packages the **SORBA Cloud IoT Unified Platform** as an EmberNET App Store Helm chart. It wraps the upstream SORBA Cloud OCI chart (`oci://sorbaregistry.azurecr.io/helm/sorba-cloud`) and adds all the EmberNET integration points — store labels, proxy compatibility, credential management, and CI/CD for GitHub Pages publishing.

SORBA Cloud provides a complete industrial IoT platform with:
- **IoT Unified Platform** — primary web UI for device management
- **Grafana Dashboard** — metrics visualization
- **AI Trainer** — edge ML model training
- **Workflow Engine** — NodeRed-based automation
- **MQTT Broker** — industrial device messaging (TLS on port 8883)
- **Identity Management** — authentication and authorization
- **API Gateway** — centralized API routing
- **InfluxDB** — time-series storage
- **VPN** — secure remote access

## 📦 Repository Structure

```
sorba-cloud/
├── charts/
│   └── sorba-cloud/
│       ├── Chart.yaml              ← Chart metadata with SORBA + EmberNET annotations
│       ├── values.yaml             ← Default values with SORBA global config + EmberNET store integration
│       └── templates/
│           ├── _helpers.tpl        ← Standard helpers + SORBA registry secret helper
│           ├── deployment.yaml     ← Deployment with EmberNET Big Four labels
│           ├── service.yaml        ← ClusterIP service with store labels
│           ├── ingress.yaml        ← Optional ingress for direct access
│           ├── pvc.yaml            ← Persistent storage for platform data
│           ├── secrets.yaml        ← Registry + service credential secrets
│           └── NOTES.txt           ← Post-install info with SORBA URLs
├── .github/
│   └── workflows/
│       └── helm-publish.yml        ← GH Pages Helm repo publish
└── README.md                       ← You are here
```

## 🚀 Quick Start

### Prerequisites

1. SORBA Cloud registry credentials (username + token) from SORBA team
2. cert-manager installed in the cluster (for SSL certificates)
3. DNS access for ACME challenge and wildcard records

### 1. Create the Registry Secret

```bash
kubectl create secret docker-registry sorba-registry-secret \
  --docker-server=sorbaregistry.azurecr.io \
  --docker-username=<SORBA_USERNAME> \
  --docker-password=<SORBA_TOKEN> \
  -n <namespace>
```

### 2. Create Service Secrets

```bash
kubectl create secret generic sorba-mysql-credentials \
  --from-literal=MYSQL_PASSWORD='<secure-password>' \
  -n <namespace>

kubectl create secret generic sorba-influx-credentials \
  --from-literal=INFLUX_PASSWORD='<secure-password>' \
  -n <namespace>

kubectl create secret generic sorba-grafana-credentials \
  --from-literal=GRAFANA_PASSWORD='<secure-password>' \
  -n <namespace>

kubectl create secret generic sorba-mqtt-credentials \
  --from-literal=MQTT_PASSWORD='<secure-password>' \
  -n <namespace>
```

### 3. Configure values.yaml

```yaml
global:
  domain: "yourdomain.com"
  tenant: "your-tenant"
  version: "1.3.0"
  credentials:
    existingSecret: "sorba-registry-secret"
```

### 4. Deploy via EmberNET Dashboard

Once the chart is published and registered in `store.go`, deploy from the App Store UI — click Deploy, select a node, done.

### 5. Manual Deploy (if needed)

```bash
helm install sorba-cloud ./charts/sorba-cloud \
  -n <namespace> --create-namespace \
  -f values.yaml
```

## 🏷️ EmberNET Store Labels

All four labels are present on both the Pod template and the Service:

| Label | Value | Purpose |
|-------|-------|---------|
| `embernet.ai/store-app` | `"true"` | Dashboard discovers the pod |
| `embernet.ai/gui-type` | `"web"` | Enables "Open" iframe button |
| `embernet.ai/app-name` | `"sorba-cloud"` | Display name in node detail |
| `embernet.ai/gui-port` | `"443"` | Port for proxy iframe target |

## 🔗 Dashboard Registration

Add to `HelmRepoURLs` in `store.go`:

```go
"https://embernet-ai.github.io/sorba-cloud/index.yaml",
```

Or set via environment variable (no rebuild required):

```bash
EMBERNET_HELM_REPOS="...,https://embernet-ai.github.io/sorba-cloud/index.yaml"
```

## 🌐 SORBA Cloud Application URLs

Once deployed with domain and tenant configured:

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

## 📋 Relationship to sorbotics-pod

This chart (`sorba-cloud`) is the **full SORBA Cloud platform** — the complete IoT stack.  
The existing `sorbotics-pod` (`sorba-sde`) is the **SORBA Smart Data Engine** — the edge data collection and analytics component.

They are complementary:
- `sorba-cloud` = the cloud/central platform (9+ services, heavy resources)
- `sorba-sde` = the edge gateway/collector (single pod, lighter footprint)

Both are registered in `store.go` and deployable from the EmberNET App Store.

---

*Built with Go, Helm, YAML, and a White Monster. — Patrick Ryan, CTO*
