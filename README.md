# Generative AI Service - Architecture

Infrastructure design, Kubernetes deployment, and incident response for a document-processing GenAI service.

---

## Structure

| Part | Directory | Contents |
|------|-----------|----------|
| **A** | [part-a/](part-a/) | Architecture diagram (Python + images), infrastructure write-up |
| **B** | [part-b/](part-b/) | Explanation; [terraform/](terraform/) and [app-config/](app-config/) contain the working configs |
| **C** | [part-c/](part-c/) | Incident response |

---

## Part A: Infrastructure Design

- [part-a/architecture.py](part-a/architecture.py) - Generates architecture diagrams (sync and async)
- [part-a/architecture_sync.png](part-a/architecture_sync.png), [part-a/architecture_async.png](part-a/architecture_async.png) - Output images
- [part-a/WRITEUP.md](part-a/WRITEUP.md) - Cloud services, networking, scaling, cost, monitoring

Regenerate diagrams: `cd part-a && source .venv/bin/activate && python architecture.py` (see [part-a/WRITEUP.md](part-a/WRITEUP.md) for setup)

---

## Part B: Kubernetes + CI/CD

- [terraform/](terraform/) - Kind cluster, Jenkins, ArgoCD, registry ([terraform/README.md](terraform/README.md) for setup)
- [app-config/](app-config/) - Helm chart, Jenkinsfile, ArgoCD Applications
- [part-b/README.md](part-b/README.md) - Manifest explanations, pipeline flow, Helm structure, screenshots

---

## Part C: Incident Response

- [part-c/INCIDENT_RESPONSE.md](part-c/INCIDENT_RESPONSE.md) - Triage, diagnosis, mitigation, post-mortem
