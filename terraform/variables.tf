# ------------------------------------------------------------------------------
# Variables for Kind + Jenkins + ArgoCD setup
# ------------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string
  default     = "cicd-local"
}

variable "kubernetes_version" {
  description = "Kubernetes version for kind cluster"
  type        = string
  default     = "v1.28.0"
}

variable "registry_port" {
  description = "Host port for local Docker registry"
  type        = number
  default     = 5001
}

variable "app_config_repo" {
  description = "GitHub repo URL for app-config (Helm chart and values). Push app-config/ to this repo."
  type        = string
  default     = "https://github.com/Fluder-Paradyne/sample-node-app-config.git"
}

variable "app_config_revision" {
  description = "Git branch or tag for app-config repo"
  type        = string
  default     = "main"
}

variable "jenkins_node_port" {
  description = "NodePort for Jenkins UI"
  type        = number
  default     = 30080
}

variable "github_app_config_username" {
  description = "GitHub username for app-config repo push (used in Jenkins credential github-app-config)"
  type        = string
  default     = ""
}

variable "github_app_config_token" {
  description = "GitHub Personal Access Token for app-config repo push (used in Jenkins credential github-app-config)"
  type        = string
  default     = ""
  sensitive   = true
}
