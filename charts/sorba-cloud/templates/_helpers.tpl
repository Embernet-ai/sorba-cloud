{{/*
═══════════════════════════════════════════════════════════════════════
SORBA Cloud — EmberNET App Store Helm Template Helpers
═══════════════════════════════════════════════════════════════════════
Standard helper functions adapted from helm-chart-temps/embernet-app.
Find-and-replaced embernet-app → sorba-cloud per the template README.
═══════════════════════════════════════════════════════════════════════
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "sorba-cloud.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some K8s name fields are limited to this
(by the DNS naming spec). If release name contains chart name it will
be used as a full name.
*/}}
{{- define "sorba-cloud.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sorba-cloud.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels — every resource gets these. No exceptions.
*/}}
{{- define "sorba-cloud.labels" -}}
helm.sh/chart: {{ include "sorba-cloud.chart" . }}
{{ include "sorba-cloud.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sorba-cloud.selectorLabels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
EmberNET Store discovery labels.
These go on pod templates AND services so the dashboard's pod-discovery
(GetNodesWithFilter) and service-discovery (GetRunningServices) both see them.

Set per APP_STORE_DEPLOYMENT_FLOW.md and AUDIT_HELM_CHARTS.md:
  - embernet.ai/store-app  (REQUIRED — discovery gate)
  - embernet.ai/app-name   (display name)
  - embernet.ai/gui-type   ("web" | "shell" | "none")
  - embernet.ai/gui-port   (port number as string)
  - app                    (fallback for name/icon resolution)

Icon resolution flows through the embernet.ai/app-icon ANNOTATION on the
Service (read by services.go), not a label. Set in service.yaml.
*/}}
{{- define "sorba-cloud.storeLabels" -}}
embernet.ai/store-app: "true"
embernet.ai/gui-type: {{ .Values.gui.type | default "web" | quote }}
embernet.ai/app-name: {{ .Chart.Name | quote }}
embernet.ai/gui-port: {{ .Values.gui.port | default .Values.service.port | quote }}
app: {{ .Chart.Name }}
{{- end }}

{{/*
EmberNET tenant labels — injected by the dashboard at deploy time
(store.go tenantLabels: embernet.ai/tenant, deployed-by, deployment-id). MUST be
rendered onto BOTH the pod template AND the Service, or the app is invisible to
every tenant-scoped view and visible only to SuperAdmin (services.go:226) — the
single most common silent App Store failure. Empty on a bare `helm install`, so
this is a no-op outside the dashboard path.
*/}}
{{- define "sorba-cloud.tenantLabels" -}}
{{- with .Values.tenantLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}
