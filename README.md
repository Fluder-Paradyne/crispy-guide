#Generative AI Service - Architecture

Infrastructure design, Kubernetes deployment, and incident response for a document-processing GenAI service.

---

## Structure

| Part | Directory | Contents |
|------|-----------|----------|
| **A** | `part-a/` | Architecture diagram (Python + images), infrastructure write-up |
| **B** | `part-b/` | Explanation; `terraform/` and `app-config/` contain the working configs |
| **C** | `part-c/` | Incident response |

---

## Part A: Infrastructure Design

- `part-a/architecture.py` - Generates architecture diagrams (sync and async)
- `part-a/architecture_sync.png`, `part-a/architecture_async.png` - Output images
- `part-a/WRITEUP.md` - Fill in: cloud services, networking, scaling, cost, monitoring

Regenerate diagrams: `cd part-a && source ../.venv/bin/activate && python architecture.py`

---

## Part B: Kubernetes + CI/CD

- `terraform/` - Kind cluster, Jenkins, ArgoCD, registry
- `app-config/` - Helm chart, Jenkinsfile, ArgoCD Applications
- `part-b/README.md` - Fill in: manifest explanations, pipeline flow, Helm structure

---

## Part C: Incident Response

- `part-c/INCIDENT_RESPONSE.md` - Fill in: triage, diagnosis, mitigation, post-mortem
