{{/*
Expand the name of the chart.
*/}}
{{- define "openvpn-router.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openvpn-router.fullname" -}}
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
{{- define "openvpn-router.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openvpn-router.labels" -}}
helm.sh/chart: {{ include "openvpn-router.chart" . }}
{{ include "openvpn-router.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openvpn-router.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openvpn-router.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolve image tags from values, falling back to appVersion-derived defaults.
*/}}
{{- define "openvpn-router.imageTag" -}}
{{- default (printf "slim-%s" .Chart.AppVersion) .Values.image.tag -}}
{{- end }}

{{- define "openvpn-router.initImageTag" -}}
{{- default .Chart.AppVersion .Values.image.initTag -}}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openvpn-router.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openvpn-router.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
