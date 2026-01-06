{{- define "app-bundle-helpers.namespace" -}}
{{- if and .Values.global .Values.global.namespace -}}
{{- .Values.global.namespace -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}
