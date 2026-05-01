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
EmberNET Store discovery labels — THE BIG FIVE.
These go on pod templates AND services. All five. Always.
Miss one and your app is invisible to the dashboard.

NOTE: embernet.ai/chart-name is required for icon resolution.
The Dashboard maps this label to the correct icon from the chart registry.
*/}}
{{- define "sorba-cloud.storeLabels" -}}
embernet.ai/store-app: "true"
embernet.ai/gui-type: {{ .Values.gui.type | default "web" | quote }}
embernet.ai/app-name: "SORBA Cloud"
embernet.ai/gui-port: {{ .Values.gui.port | default .Values.service.port | quote }}
embernet.ai/chart-name: {{ .Chart.Name | quote }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "sorba-cloud.serviceAccountName" -}}
{{- if .Values.serviceAccount }}
{{- if .Values.serviceAccount.create }}
{{- default (include "sorba-cloud.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- else }}
{{- "default" }}
{{- end }}
{{- end }}
