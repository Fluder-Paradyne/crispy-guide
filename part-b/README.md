# Part B: Kubernetes Deployment + CI/CD

Working configuration for deploying the sample Node.js service to Kubernetes.

---

## Directory structure

| Path | Purpose |
|------|---------|
| `../terraform/` | Kind cluster, Jenkins, ArgoCD, in-cluster registry |
| `../app-config/` | Helm chart, Jenkinsfile, ArgoCD Application manifests |

---

## Kubernetes manifests

<!-- Explain the Deployment, Service, HPA, and NetworkPolicy. Where are they defined? What does each do? -->

### Deployment

<!-- Path: app-config/sample-node-app/templates/deployment.yaml -->

<!-- Describe: container image, replicas, resource limits, env vars, probes. -->

### Service

<!-- Path: app-config/sample-node-app/templates/service.yaml -->

<!-- Describe: service type, port mapping. -->

### HPA (Horizontal Pod Autoscaler)

<!-- Path: app-config/sample-node-app/templates/hpa.yaml -->

<!-- Describe: min/max replicas, scaling metric (CPU, custom). -->

### NetworkPolicy (optional)

<!-- Path: app-config/sample-node-app/templates/networkpolicy.yaml -->

<!-- Describe: ingress/egress rules if enabled. -->

---

## CI/CD pipeline

### Jenkinsfile

<!-- Path: app-config/Jenkinsfile -->

<!-- Describe the pipeline stages: checkout, build, test, push image, deploy to staging, manual approval, deploy to production. -->

### ArgoCD Applications

<!-- Path: app-config/argocd-applications/ -->

<!-- Describe: staging vs production apps, sync policy, promotion flow. -->

---

## Helm chart structure (Bonus)

<!-- Path: app-config/sample-node-app/ -->

| File | Purpose |
|------|---------|
| Chart.yaml | |
| values.yaml | |
| values-dev.yaml | |
| values-staging.yaml | |
| values-prod.yaml | |

<!-- Explain how dev/staging/prod differences are managed via value files. -->

---

## How to run

See `../terraform/README.md` for setup instructions.
