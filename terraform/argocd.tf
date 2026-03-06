resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [kind_cluster.local]
}

resource "helm_release" "argocd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  name       = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "9.4.7"

  values = [
    file("${path.module}/values/argocd.yaml")
  ]

  timeout = 600
  wait    = true
}
