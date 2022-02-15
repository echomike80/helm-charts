{{/*
Renders a value that contains template.
Usage:
{{ include "dokuwiki.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "dokuwiki.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dokuwiki.names.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "dokuwiki.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "dokuwiki.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "dokuwiki.selectorLabels" -}}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Return the target Kubernetes version
*/}}
{{- define "dokuwiki.capabilities.kubeVersion" -}}
{{- if .Values.global }}
    {{- if .Values.global.kubeVersion }}
    {{- .Values.global.kubeVersion -}}
    {{- else }}
    {{- default .Capabilities.KubeVersion.Version .Values.kubeVersion -}}
    {{- end -}}
{{- else }}
{{- default .Capabilities.KubeVersion.Version .Values.kubeVersion -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "dokuwiki.capabilities.ingress.apiVersion" -}}
{{- if .Values.ingress -}}
{{- if .Values.ingress.apiVersion -}}
{{- .Values.ingress.apiVersion -}}
{{- else if semverCompare "<1.14-0" (include "dokuwiki.capabilities.kubeVersion" .) -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" (include "dokuwiki.capabilities.kubeVersion" .) -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end }}
{{- else if semverCompare "<1.14-0" (include "dokuwiki.capabilities.kubeVersion" .) -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" (include "dokuwiki.capabilities.kubeVersion" .) -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}


{{/*
Generate backend entry that is compatible with all Kubernetes API versions.

Usage:
{{ include "dokuwiki.ingress.backend" (dict "serviceName" "backendName" "servicePort" "backendPort" "context" $) }}

Params:
  - serviceName - String. Name of an existing service backend
  - servicePort - String/Int. Port name (or number) of the service. It will be translated to different yaml depending if it is a string or an integer.
  - context - Dict - Required. The context for the template evaluation.
*/}}
{{- define "dokuwiki.ingress.backend" -}}
{{- $apiVersion := (include "dokuwiki.capabilities.ingress.apiVersion" .context) -}}
{{- if or (eq $apiVersion "extensions/v1beta1") (eq $apiVersion "networking.k8s.io/v1beta1") -}}
serviceName: {{ .serviceName }}
servicePort: {{ .servicePort }}
{{- else -}}
service:
  name: {{ .serviceName }}
  port:
    {{- if typeIs "string" .servicePort }}
    name: {{ .servicePort }}
    {{- else if or (typeIs "int" .servicePort) (typeIs "float64" .servicePort) }}
    number: {{ .servicePort | int }}
    {{- end }}
{{- end -}}
{{- end -}}

{{/*
Print "true" if the API pathType field is supported
Usage:
{{ include "dokuwiki.ingress.supportsPathType" . }}
*/}}
{{- define "dokuwiki.ingress.supportsPathType" -}}
{{- if (semverCompare "<1.18-0" (include "dokuwiki.capabilities.kubeVersion" .)) -}}
{{- print "false" -}}
{{- else -}}
{{- print "true" -}}
{{- end -}}
{{- end -}}

{{/*
Returns true if the ingressClassname field is supported
Usage:
{{ include "dokuwiki.ingress.supportsIngressClassname" . }}
*/}}
{{- define "dokuwiki.ingress.supportsIngressClassname" -}}
{{- if semverCompare "<1.18-0" (include "dokuwiki.capabilities.kubeVersion" .) -}}
{{- print "false" -}}
{{- else -}}
{{- print "true" -}}
{{- end -}}
{{- end -}}

{{/*
Return true if cert-manager required annotations for TLS signed
certificates are set in the Ingress annotations
Ref: https://cert-manager.io/docs/usage/ingress/#supported-annotations
Usage:
{{ include "dokuwiki.ingress.certManagerRequest" ( dict "annotations" .Values.path.to.the.ingress.annotations ) }}
*/}}
{{- define "dokuwiki.ingress.certManagerRequest" -}}
{{ if or (hasKey .annotations "cert-manager.io/cluster-issuer") (hasKey .annotations "cert-manager.io/issuer") }}
    {{- true -}}
{{- end -}}
{{- end -}}