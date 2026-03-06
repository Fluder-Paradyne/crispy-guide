# Part A: Infrastructure Design Write-up

Virallens Generative AI service - cloud infrastructure design (1-2 pages).

---

## Cloud services chosen and why

<!-- Describe the cloud services selected (compute, storage, networking, etc.) and the rationale for each choice. -->

---

## Networking and security design

### VPC and subnets

<!-- Describe VPC layout, public vs private subnets, CIDR allocation. -->

### IAM

<!-- Describe IAM roles, service accounts, least-privilege approach. -->

### Ingress and egress

<!-- Describe traffic flow, security groups, network ACLs, WAF rules. -->

---

## Scaling strategy

### 50 concurrent requests

<!-- How does the system handle low load? -->

### 10,000 concurrent requests

<!-- How does the system scale to high load? (HPA, Karpenter, queue-based scaling, etc.) -->

---

## Cost optimization considerations

<!-- Describe cost-saving measures: spot instances, right-sizing, reserved capacity, storage tiers, etc. -->

---

## Monitoring and alerting approach

<!-- Describe observability stack, metrics, logs, dashboards, alerting rules, PagerDuty integration. -->

---

## Architecture diagrams

- `architecture_sync.png` - Synchronous request flow
- `architecture_async.png` - Async producer/consumer flow

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
uv pip install -r requirements.txts
```

Regenerate diagrams: `cd part-a && source .venv/bin/activate && python architecture.py`