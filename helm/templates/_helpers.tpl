{{/*
Expand the name of the chart.
*/}}
{{- define "tech-test.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tech-test.fullname" -}}
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

{{- define "tech-test.fullname.data-api" -}}
{{ include "tech-test.fullname" . }}-data-api
{{- end }}

{{- define "tech-test.fullname.backend-api" -}}
{{ include "tech-test.fullname" . }}-backend-api
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tech-test.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tech-test.labels.common" -}}
helm.sh/chart: {{ include "tech-test.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "tech-test.labels.data-api" -}}
{{ include "tech-test.labels.common" . }}
{{ include "tech-test.selectorLabels.data-api" . }}
{{- end }}

{{- define "tech-test.labels.backend-api" -}}
{{ include "tech-test.labels.common" . }}
{{ include "tech-test.selectorLabels.backend-api" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tech-test.selectorLabels.common" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "tech-test.selectorLabels.data-api" -}}
app.kubernetes.io/name: {{ include "tech-test.fullname.data-api" . }}
{{ include "tech-test.selectorLabels.common" . }}
{{- end }}

{{- define "tech-test.selectorLabels.backend-api" -}}
app.kubernetes.io/name: {{ include "tech-test.fullname.backend-api" . }}
{{ include "tech-test.selectorLabels.common" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tech-test.serviceAccountName.backend-api" -}}
{{ include "tech-test.fullname.backend-api" . }}
{{- end }}

{{- define "tech-test.serviceAccountName.data-api" -}}
{{ include "tech-test.fullname.data-api" . }}
{{- end }}
