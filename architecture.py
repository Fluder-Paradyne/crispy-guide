from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import (
    Route53,
    ElbApplicationLoadBalancer as ALB,
    Endpoint,
    InternetGateway,
    NATGateway,
    VPCFlowLogs,
)
from diagrams.aws.integration import SimpleQueueServiceSqs as SQS
from diagrams.aws.storage import SimpleStorageServiceS3 as S3, S3Glacier
from diagrams.aws.compute import EC2
from diagrams.aws.database import RDSMysqlInstance, ElasticacheForRedis
from diagrams.aws.security import SecretsManager, WAF
from diagrams.aws.general import Users
from diagrams.k8s.compute import Deploy, Pod
from diagrams.k8s.clusterconfig import HPA
from diagrams.k8s.network import SVC
from diagrams.k8s.podconfig import Secret
from diagrams.onprem.vcs import Github
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.gitops import Argocd
from diagrams.onprem.monitoring import Grafana, Prometheus
from diagrams.onprem.logging import Fluentbit, Loki
from diagrams.saas.alerting import Pagerduty
from diagrams.k8s.compute import DS

graph_attr = {
    "fontsize": "28",
    "bgcolor": "white",
    "pad": "1.5",
    "splines": "spline",
    "nodesep": "0.8",
    "ranksep": "1.0",
}

with Diagram(
    "GenAI Document Processing - Synchronous",
    show=False,
    filename="architecture_sync",
    direction="TB",
    graph_attr=graph_attr,
):
    with Cluster("CI/CD Pipeline"):
        github = Github("GitHub\nRepo")
        actions = GithubActions("GitHub\nActions")
        argocd = Argocd("ArgoCD")
        github >> Edge(label="push") >> actions >> Edge(label="build image\n& update manifests") >> argocd

    users = Users("Clients")
    dns = Route53("Route53")
    secrets = SecretsManager("Secrets\nManager")
    flow_logs_bucket = S3("S3\nFlow Logs")

    with Cluster("VPC"):
        igw = InternetGateway("Internet\nGateway")
        flow_logs = VPCFlowLogs("VPC\nFlow Logs")

        with Cluster("Public Subnet  (SG: allow 443 from 0.0.0.0/0)"):
            waf = WAF("WAF")
            alb = ALB("ALB")
            nat = NATGateway("NAT\nGateway")

        with Cluster("Private Subnet"):
            with Cluster("EKS Cluster  (SG: allow traffic from ALB)"):
                svc = SVC("Service")
                hpa = HPA("HPA")
                karpenter = EC2("Karpenter")
                csi = Secret("Secrets Store\nCSI Driver")

                with Cluster("GenAI Inference"):
                    deploy = Deploy("Deployment")
                    pods = [Pod("Pod") for _ in range(3)]

                with Cluster("Observability"):
                    grafana = Grafana("Grafana")
                    prometheus = Prometheus("Prometheus")
                    loki = Loki("Loki")
                    fluentbit = DS("Fluent Bit\nDaemonSet")

                svc >> deploy >> pods
                hpa >> Edge(style="dashed", label="scales") >> deploy
                karpenter >> Edge(style="dashed", label="provisions nodes") >> deploy

            db = RDSMysqlInstance("RDS MySQL\n(SG: allow 3306\nfrom EKS)")

            with Cluster("VPC Endpoints\n(no NAT)"):
                s3_ep = Endpoint("S3\nEndpoint")
                secrets_ep = Endpoint("Secrets Manager\nEndpoint")

            pagerduty = Pagerduty("PagerDuty")

    users >> dns >> igw >> waf >> alb >> svc
    argocd >> Edge(style="dashed", label="deploy manifests") >> deploy
    deploy >> Edge(label="read/write\nmetadata") >> db
    flow_logs >> Edge(label="export") >> s3_ep >> flow_logs_bucket
    csi >> Edge(style="dashed", label="via endpoint") >> secrets_ep >> secrets
    csi >> Edge(style="dashed", label="inject env") >> deploy
    prometheus >> Edge(style="dashed", label="scrape metrics") >> deploy
    pods[1] >> Edge(style="dashed", label="collect logs") >> fluentbit
    fluentbit >> Edge(label="ship logs") >> loki
    grafana >> Edge(style="dashed", label="metrics") >> prometheus
    grafana >> Edge(style="dashed", label="logs") >> loki
    grafana >> Edge(label="alerts") >> pagerduty


with Diagram(
    "GenAI Document Processing - Async Producer/Consumer",
    show=False,
    filename="architecture_async",
    direction="TB",
    graph_attr=graph_attr,
):
    with Cluster("CI/CD Pipeline"):
        github = Github("GitHub\nRepo")
        actions = GithubActions("GitHub\nActions")
        argocd = Argocd("ArgoCD")
        github >> Edge(label="push") >> actions >> Edge(label="build image\n& update manifests") >> argocd

    users = Users("Clients")
    dns = Route53("Route53")
    queue = SQS("SQS\nJob Queue")
    secrets = SecretsManager("Secrets\nManager")

    with Cluster("S3 Storage"):
        bucket = S3("S3 Documents\n(versioning enabled)")
        glacier = S3Glacier("S3 Glacier\n(lifecycle: archive\nafter 30 days)")
        flow_logs_bucket = S3("S3\nFlow Logs")
        bucket >> Edge(style="dashed", label="lifecycle\narchive") >> glacier

    with Cluster("VPC"):
        igw = InternetGateway("Internet\nGateway")
        flow_logs = VPCFlowLogs("VPC\nFlow Logs")

        with Cluster("Public Subnet  (SG: allow 443 from 0.0.0.0/0)"):
            waf = WAF("WAF")
            alb = ALB("ALB")
            nat = NATGateway("NAT\nGateway")

        with Cluster("Private Subnet"):
            with Cluster("EKS Cluster  (SG: allow traffic from ALB)"):
                csi = Secret("Secrets Store\nCSI Driver")
                karpenter = EC2("Karpenter")

                with Cluster("API Server"):
                    api_svc = SVC("Service")
                    api_deploy = Deploy("Deployment")
                    api_hpa = HPA("HPA")
                    api_pods = [Pod("Pod") for _ in range(2)]

                    api_svc >> api_deploy >> api_pods
                    api_hpa >> Edge(style="dashed", label="scales") >> api_deploy

                with Cluster("Consumer Worker"):
                    wrk_deploy = Deploy("Deployment")
                    keda = HPA("KEDA\nScaledObject")
                    wrk_pods = [Pod("Pod") for _ in range(3)]

                    wrk_deploy >> wrk_pods
                    keda >> Edge(style="dashed", label="scales on\nqueue depth") >> wrk_deploy

                karpenter >> Edge(style="dashed", label="provisions nodes") >> api_deploy
                karpenter >> Edge(style="dashed", label="provisions nodes") >> wrk_deploy

                with Cluster("Observability"):
                    grafana = Grafana("Grafana")
                    prometheus = Prometheus("Prometheus")
                    loki = Loki("Loki")
                    fluentbit = DS("Fluent Bit\nDaemonSet")

            db = RDSMysqlInstance("RDS MySQL\n(SG: allow 3306\nfrom EKS)")
            redis = ElasticacheForRedis("ElastiCache\nRedis\n(poll cache)")

            with Cluster("VPC Endpoints\n(no NAT)"):
                s3_ep = Endpoint("S3\nEndpoint")
                sqs_ep = Endpoint("SQS\nEndpoint")
                secrets_ep = Endpoint("Secrets Manager\nEndpoint")

            pagerduty = Pagerduty("PagerDuty")

    users >> Edge(label="1. presigned upload") >> bucket
    users >> Edge(label="2. submit / poll") >> dns >> igw >> waf >> alb >> api_svc
    argocd >> Edge(style="dashed", label="deploy") >> api_deploy
    argocd >> Edge(style="dashed", label="deploy") >> wrk_deploy
    api_deploy >> Edge(label="enqueue") >> sqs_ep >> queue
    wrk_deploy >> Edge(label="consume") >> sqs_ep >> queue
    queue >> Edge(style="dashed", label="metrics") >> keda
    wrk_deploy >> Edge(label="read/write docs") >> s3_ep >> bucket
    api_deploy >> Edge(label="presigned URLs") >> s3_ep >> bucket
    api_deploy >> Edge(label="write job status") >> db
    api_deploy >> Edge(style="dashed", label="cache poll") >> redis
    wrk_deploy >> Edge(label="update status") >> db
    wrk_deploy >> Edge(style="dashed", label="update cache") >> redis
    flow_logs >> Edge(label="export") >> s3_ep >> flow_logs_bucket
    csi >> Edge(style="dashed", label="via endpoint") >> secrets_ep >> secrets
    csi >> Edge(style="dashed", label="inject env") >> api_deploy
    csi >> Edge(style="dashed", label="inject env") >> wrk_deploy
    prometheus >> Edge(style="dashed", label="scrape metrics") >> api_deploy
    prometheus >> Edge(style="dashed", label="scrape metrics") >> wrk_deploy
    api_deploy >> Edge(style="dashed", label="collect logs") >> fluentbit
    wrk_deploy >> Edge(style="dashed", label="collect logs") >> fluentbit
    fluentbit >> Edge(label="ship logs") >> loki
    grafana >> Edge(style="dashed", label="metrics") >> prometheus
    grafana >> Edge(style="dashed", label="logs") >> loki
    grafana >> Edge(label="alerts") >> pagerduty
