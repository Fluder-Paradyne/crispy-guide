
output "cluster_name" {
  description = "Name of the kind cluster"
  value       = kind_cluster.local.name
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file for the kind cluster"
  value       = kind_cluster.local.kubeconfig_path
}

output "jenkins_url" {
  description = "URL to access Jenkins (use port-forward if NodePort not exposed)"
  value       = "http://localhost:${var.jenkins_node_port}"
}

output "argocd_url" {
  description = "URL to access ArgoCD (NodePort 30081 HTTP, or: kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443)"
  value       = "http://localhost:30081"
}

output "registry_url" {
  description = "In-cluster registry URL for pushing images (use in Jenkins pipeline)"
  value       = "registry.registry.svc.cluster.local:5000"
}

output "sample_app_namespace" {
  description = "Namespace where sample-node-app is deployed"
  value       = "sample-node-app"
}
