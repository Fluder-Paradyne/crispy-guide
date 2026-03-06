resource "kubernetes_namespace" "sample_node_app" {
  metadata {
    name = "sample-node-app"
  }
  depends_on = [kind_cluster.local]
}

resource "kubernetes_manifest" "argocd_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "sample-node-app"
      namespace = "argocd"
    }
    spec = {
      description  = "Sample Node.js application"
      sourceRepos  = ["*"]
      destinations = [
        {
          server    = "https://kubernetes.default.svc"
          namespace = kubernetes_namespace.sample_node_app.metadata[0].name
        }
      ]
    }
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "argocd_app_staging" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "sample-node-staging"
      namespace = "argocd"
    }
    spec = {
      project = "sample-node-app"
      source = {
        repoURL        = var.app_config_repo
        targetRevision = var.app_config_revision
        path           = "sample-node-app"
        helm = {
          valueFiles = ["values-staging.yaml"]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.sample_node_app.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = true
        }
        syncOptions = ["PruneLast=true"]
      }
    }
  }
  depends_on = [kubernetes_manifest.argocd_project]
}

resource "kubernetes_manifest" "argocd_app_production" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "sample-node-production"
      namespace = "argocd"
    }
    spec = {
      project = "sample-node-app"
      source = {
        repoURL        = var.app_config_repo
        targetRevision = var.app_config_revision
        path           = "sample-node-app"
        helm = {
          valueFiles = ["values-prod.yaml"]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.sample_node_app.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
  depends_on = [kubernetes_manifest.argocd_project]
}
