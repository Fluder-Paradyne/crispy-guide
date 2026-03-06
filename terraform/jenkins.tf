
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
  depends_on = [kind_cluster.local]
}

resource "helm_release" "jenkins" {
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  name       = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [
    templatefile("${path.module}/values/jenkins.yaml", {
      jenkins_node_port   = var.jenkins_node_port
      app_config_repo     = var.app_config_repo
      github_username     = var.github_app_config_username
      github_password     = var.github_app_config_token
      has_github_creds   = var.github_app_config_username != "" && var.github_app_config_token != ""
    })
  ]

  timeout = 600
  wait    = true

  depends_on = [kubernetes_deployment.registry]
}
