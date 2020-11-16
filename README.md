## Pre-Req
- argocd
- docker
- kubectl
- kubefwd
- minikube
## Follow the ArgoCD "Getting Started" to get Argo in your minikube cluster
- https://argoproj.github.io/argo-cd/getting_started/ (Stop at the point of Application Creation)

## Setup the ArgoCD Application
```
argocd app create th3-server --repo https://github.com/lainthelame/th3-server --path helm-th3-server --dest-server in-cluster --dest-namespace default
```
- Port forward argo UI and App
```
kubefwd svc -n argocd
kubectl port-forward svc/th3-server-helm-th3-server -n default 8080
```
## How to test?
- Update the "_version_" in the "th3-server.py" file
- Build a new dockerfile 
``` 
docker build -t lainthelame/th3-server:v0.$ .
docker push lainthelame/th3-server:v0.$
```
- Update the version in the "Chart.yaml"
- Push update
- Run "get-version.py" locally to get version from API

## Ideal State
- Deploy "get-version.py" to the cluster and reconfigure to point at the kubernettes service.
- Setup a ArgoCD "BlueGreen" rollout.yaml (example below)
```
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: {{ template "helm-th3-server.fullname" . }}
  labels:
    app: {{ template "helm-th3-server.name" . }}
    chart: {{ template "helm-th3-server.chart" . }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
spec:
  replicas: {{ .Values.replicaCount }}
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: {{ template "helm-th3-server.name" . }}
      release: {{ .Release.Name }}
  strategy:
    blueGreen:
      activeService: {{ template "helm-th3-server.fullname" . }}
      previewService: {{ template "helm-th3-server.fullname" . }}-preview
  template:
    metadata:
      labels:
        app: {{ template "helm-th3-server.name" . }}
        release: {{ .Release.Name }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
{{ toYaml .Values.resources | indent 12 }}
    {{- with .Values.nodeSelector }}
      nodeSelector:
{{ toYaml . | indent 8 }}
    {{- end }}
    {{- with .Values.affinity }}
      affinity:
{{ toYaml . | indent 8 }}
    {{- end }}
    {{- with .Values.tolerations }}
      tolerations:
{{ toYaml . | indent 8 }}
    {{- end }}
```
