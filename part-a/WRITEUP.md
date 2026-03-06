# Part A: Infrastructure Design Write-up

Virallens Generative AI service - cloud infrastructure design (1-2 pages).

---

## Cloud services chosen and why

**Compute:** EKS (Kubernetes) for running the GenAI inference workload. Enables horizontal scaling, rolling updates, and integration with Karpenter for node autoscaling. Inference runs in a Deployment with multiple pods; async mode adds a separate API Server deployment and Consumer Worker deployment.

**Storage:** S3 for document storage (versioning enabled). Async mode uses S3 Glacier with a 30-day lifecycle rule to archive documents and reduce cost. RDS MySQL for job metadata and status. Async mode adds ElastiCache Redis for poll/cache to reduce database load.

**Networking:** Route53 for DNS. ALB for load balancing. WAF in front of ALB for web application firewall. VPC with public and private subnets. VPC Endpoints (S3, Secrets Manager, SQS in async) to avoid NAT for AWS API calls.

**Integration:** Secrets Manager for credentials; injected via Secrets Store CSI Driver. Async mode uses SQS as a job queue for decoupling API from workers.

**CI/CD:** GitHub, GitHub Actions (build image and update manifests), ArgoCD (GitOps deployment to EKS).

---

## Networking and security design

### VPC and subnets

- **Public subnet:** Hosts ALB, WAF, NAT Gateway. Security group allows 443 from 0.0.0.0/0 for client traffic.
- **Private subnet:** Hosts EKS cluster, RDS MySQL, ElastiCache (async). EKS nodes and workloads do not have public IPs.
- **VPC Flow Logs:** Exported to S3 for audit and troubleshooting.

### IAM

- EKS nodes use IRSA (IAM Roles for Service Accounts) for least-pr privilege access to AWS APIs.
- Secrets Store CSI Driver fetches secrets from Secrets Manager via VPC endpoint; no egress to internet.
- Application pods receive secrets as environment variables or mounted files.

### Ingress and egress

- **Ingress:** Clients -> Route53 -> Internet Gateway -> WAF -> ALB -> EKS Service -> Pods. WAF rules filter malicious traffic before it reaches the cluster.
- **Egress:** Private subnet uses NAT Gateway for outbound internet (e.g. package updates). VPC Endpoints for S3, Secrets Manager, SQS eliminate NAT for AWS service calls.
- **RDS:** Security group allows 3306 from EKS only.

---

## Scaling strategy

### 50 concurrent requests

- **Sync:** HPA keeps a small number of inference pods (e.g. 2–3). Karpenter provisions minimal nodes. Low cost.
- **Async:** API Server and Consumer Worker scale down. KEDA scales workers based on SQS queue depth; with low queue depth, few workers run.

### 10,000 concurrent requests

- **Sync:** HPA scales inference pods based on CPU (or custom metrics). Karpenter provisions additional nodes as needed. ALB distributes traffic across pods.
- **Async:** API Server HPA scales pods for submit/poll traffic. SQS absorbs spikes; KEDA scales Consumer Workers based on queue depth. Workers process documents in parallel. ElastiCache reduces DB load for status polls.

---

## Cost optimization considerations

- **VPC Endpoints:** Avoid NAT Gateway data charges for S3, Secrets Manager, SQS traffic.
- **S3 lifecycle:** Archive documents to S3 Glacier after 30 days (async) to lower storage cost.
- **Karpenter:** Right-size nodes; use spot instances where appropriate for worker workloads.
- **HPA / KEDA:** Scale down during low load to avoid over-provisioning.
- **ElastiCache:** Cache frequent poll responses (async) to reduce RDS read load and cost.

---

## Monitoring and alerting approach

- **Metrics:** Prometheus scrapes application and infrastructure metrics. Grafana dashboards for visualization.
- **Logs:** Fluent Bit DaemonSet collects pod logs and ships to Loki. Grafana queries Loki for log exploration.
- **Alerts:** Grafana alert rules trigger on thresholds (e.g. latency, error rate, GPU utilization). Alerts route to PagerDuty for on-call response.
- **Flow logs:** VPC Flow Logs in S3 support network analysis and security audits.

---

## Architecture diagrams

- `architecture_sync.png` - Synchronous request flow (direct API -> inference -> response)
- `architecture_async.png` - Async producer/consumer flow (presigned upload, SQS, workers, S3/Glacier)

---

## Setup (diagram generation)

**System dependency:** Install Graphviz (required by diagrams):

```shell
# macOS
brew install graphviz

# Ubuntu/Debian
sudo apt install graphviz
```

**Python dependencies:**

```shell
# uv
uv venv && source .venv/bin/activate
uv pip install -r requirements.txt

# pip
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

Regenerate diagrams: `cd part-a && source .venv/bin/activate && python architecture.py`
