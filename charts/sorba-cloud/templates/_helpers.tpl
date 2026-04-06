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
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
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
Selector labels — pods and services must match on these.
*/}}
{{- define "sorba-cloud.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sorba-cloud.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
EmberNET Store discovery labels — THE BIG FOUR.
These go on pod templates AND services. All four. Always.
Miss one and your app is invisible to the dashboard.
*/}}
{{- define "sorba-cloud.storeLabels" -}}
embernet.ai/store-app: "true"
embernet.ai/gui-type: {{ .Values.gui.type | default "web" | quote }}
embernet.ai/app-name: {{ include "sorba-cloud.name" . | quote }}
embernet.ai/gui-port: {{ .Values.gui.port | default .Values.service.port | quote }}
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

{{/*
SORBA registry image pull secret — generates a docker-registry secret
from inline credentials when global.credentials.existingSecret is empty.
*/}}
{{- define "sorba-cloud.registrySecret" -}}
{{- if and .Values.global.credentials.enabled (not .Values.global.credentials.existingSecret) }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" .Values.global.credentials.registry .Values.global.credentials.username .Values.global.credentials.password (printf "%s:%s" .Values.global.credentials.username .Values.global.credentials.password | b64enc) | b64enc }}
{{- end }}
{{- end }}
