# Part C: Incident Response

PagerDuty alert at 11 PM: inference service p99 latency spiked from 200ms to 4.5s, 5% of requests returning 503, GPU utilization at 98%.

---

## Triage

### What do you check first?

1. **Inference pod status** – Are pods running, restarting, or OOMKilled? `kubectl get pods -n <inference-ns>` and `kubectl describe pod` for any CrashLoopBackOff or Evicted.
2. **Request rate and queue depth** – Sudden traffic spike or backlog? Check Grafana/Prometheus for request rate, queue length, and error rate over the last 30–60 minutes.
3. **GPU utilization and memory** – Confirm 98% GPU utilization; check GPU memory usage. High utilization with latency spike suggests saturation.
4. **Upstream/downstream dependencies** – Is the load balancer healthy? Any dependency (model server, cache, DB) timing out or failing?
5. **Recent deployments** – Any rollout or config change in the last few hours that could explain the change?

### Tools and dashboards

- **kubectl** – `get pods`, `describe pod`, `logs`, `top pods` for CPU/memory.
- **Grafana** – Inference latency (p50, p95, p99), request rate, error rate, GPU utilization dashboards.
- **Prometheus** – Queries for `rate(http_requests_total[5m])`, `histogram_quantile(0.99, ...)`, GPU metrics.
- **PagerDuty / alert history** – When did alerts start, which services fired first?
- **Cloud provider console** – GPU instance health, throttling, regional issues (if applicable).

---

## Diagnosis

### Likely root causes and how to confirm each

| # | Root cause | How to confirm |
|---|------------|-----------------|
| 1 | **GPU saturation** – Inference nodes at 98% utilization; requests queue and time out | Grafana GPU utilization; Prometheus inference queue depth; correlation of high GPU with latency spike |
| 2 | **Insufficient horizontal scaling** – HPA not scaling up fast enough for load spike | Check HPA status (`kubectl get hpa`), desired vs current replicas; review HPA metrics and scaling events in last hour |
| 3 | **Traffic spike or thundering herd** – Sudden increase in concurrent requests | Request rate and concurrency graphs; compare to baseline; check for retries or batch jobs |
| 4 | **GPU memory exhaustion or throttling** – OOM or thermal throttling causing slowdowns | `nvidia-smi` or node exporter GPU metrics; pod restarts; node-level GPU memory usage |

---

## Mitigation

### Immediate actions to stabilize the service

1. **Scale up inference pods** – Manually increase replicas if HPA is lagging: `kubectl scale deployment <inference-deployment> --replicas=<higher>` to absorb load and reduce queue depth.
2. **Enable or tighten rate limiting** – At ALB/WAF or API gateway, throttle or reject excess traffic to prevent further saturation and protect existing requests.
3. **Shed load or degrade gracefully** – Return 429 (Too Many Requests) or a simplified response for non-critical paths; prioritize high-value or latency-sensitive requests if possible.
4. **Restart stuck or unhealthy pods** – If specific pods are hung or degraded, `kubectl delete pod` to force replacement (avoid deleting too many at once).
5. **Warm standby or failover** – If a multi-region or standby setup exists, route traffic away from the affected region until capacity is restored.

---

## Post-mortem

### Long-term changes to prevent recurrence

1. **Improve scaling** – Tune HPA (e.g., custom metrics, faster scale-up), consider KEDA for queue-based scaling. Add Karpenter or cluster autoscaler so nodes scale with demand. Set min replicas to handle typical baseline load.
2. **Capacity planning and load testing** – Run load tests to find limits; define SLOs (e.g., p99 < 500ms) and alert before saturation. Plan capacity for expected peaks (e.g., 2x baseline).
3. **Request queuing and backpressure** – Add a queue (e.g., SQS) or request queue in front of inference; reject or delay excess requests with 429 instead of overloading GPUs. Consider async processing for batch workloads.
4. **Observability and alerting** – Alert on GPU utilization > 85%, queue depth, and p99 latency before they hit SLO. Add runbooks and on-call playbooks for common scenarios.
5. **Cost vs. performance** – Evaluate more or larger GPUs, spot vs. on-demand mix, and model optimization (quantization, batching) to improve throughput per GPU.
