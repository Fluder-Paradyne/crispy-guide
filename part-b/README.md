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

All manifests are Helm templates in `app-config/sample-node-app/templates/`. Values are parameterized via `values.yaml` and environment-specific overrides.

### Deployment

**Path:** `app-config/sample-node-app/templates/deployment.yaml`

- **Container image:** `{{ .Values.image.repository }}:{{ .Values.image.tag }}` (default: `registry.registry.svc.cluster.local:5000/sample-node-app:latest`)
- **Replicas:** From `replicaCount` (1 dev, 2 staging, 3 prod)
- **Resources:** CPU/memory requests and limits from `values.resources`
- **Probes:** Liveness and readiness on `GET /` (port 3000), 10s initial delay, 10s period for liveness; 5s initial, 5s period for readiness
- **imagePullPolicy:** Configurable (IfNotPresent default, Always for staging/prod)

### Service

**Path:** `app-config/sample-node-app/templates/service.yaml`

- **Type:** ClusterIP (internal cluster access)
- **Port:** 3000 (configurable via `service.port`)
- **Selector:** Matches deployment pod labels

### HPA (Horizontal Pod Autoscaler)

**Path:** `app-config/sample-node-app/templates/hpa.yaml`

- **Conditional:** Rendered only when `hpa.enabled: true` (staging and prod)
- **Min/max replicas:** Staging 2–5, production 3–10
- **Metric:** CPU utilization (staging 80%, prod 70% target)
- **Scale target:** The sample-node-app Deployment

### NetworkPolicy (optional)

**Path:** `app-config/sample-node-app/templates/networkpolicy.yaml`

- **Conditional:** Rendered only when `networkPolicy.enabled: true` (disabled by default)
- **Ingress:** Allows TCP traffic on the service port from any namespace
- **Egress:** Not restricted (default allow)

---

## CI/CD pipeline

### Jenkinsfile

**Path:** `app-config/Jenkinsfile`

Pipeline runs on Jenkins agents with `docker` label (DinD). Stages:

1. **Checkout** – Clone app repo ([sample-node-project](https://github.com/Fluder-Paradyne/sample-node-project)) into `app/`
2. **Build** – `npm ci` in node container
3. **Test** – `npx jest --ci --passWithNoTests --forceExit` (--forceExit to make sure npx stop once the test is successful, sometimes it get stuck)
4. **Build Image** – Docker build, tag with `BUILD_NUMBER` and `latest`
5. **Push to Registry** – Push to in-cluster registry (in real world it would probably be ECR or some command docker registry)
6. **Deploy to Staging** – Update `values-staging.yaml` tag, commit and push to app-config repo; ArgoCD auto-syncs
7. **Manual Approval** – `input` step gates production
8. **Deploy to Production** – Update `values-prod.yaml` tag, commit and push; ArgoCD syncs

Git push uses `github-app-config` credentials (username/password) for the app-config repo.

### ArgoCD Applications

**Path:** `app-config/argocd-applications/`

| Application | Value file | Sync policy |
|-------------|------------|-------------|
| sample-node-staging | values-staging.yaml | Automated (prune, selfHeal, allowEmpty), PruneLast |
| sample-node-production | values-prod.yaml | Manual sync (no automated block) |

Both deploy the same Helm chart from `sample-node-app/` to namespace `sample-node-app`. Staging auto-syncs on git push; production syncs after Jenkins pushes the updated tag and an operator triggers sync (or uses automated sync if configured).

---

## Helm chart structure (Bonus)

**Path:** `app-config/sample-node-app/`

| File | Purpose |
|------|---------|
| Chart.yaml | Chart metadata (name, version, appVersion) |
| values.yaml | Defaults: 1 replica, HPA off, NetworkPolicy off, base resources |
| values-dev.yaml | Minimal resources (25m/32Mi), HPA off |
| values-staging.yaml | 2 replicas, HPA 2–5, CPU 80%, tag from Jenkins |
| values-prod.yaml | 3 replicas, HPA 3–10, CPU 70%, higher resources (100m/128Mi requests, 500m/512Mi limits) |

Environment differences are managed by value files. ArgoCD Applications specify which value file to use (`values-staging.yaml` vs `values-prod.yaml`). The image tag is updated by Jenkins in the value files on each deploy.

---

## How to run

See `../terraform/README.md` for setup instructions.
