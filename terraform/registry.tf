
resource "kubernetes_namespace" "registry" {
  metadata {
    name = "registry"
  }
  depends_on = [kind_cluster.local]
}

resource "kubernetes_deployment" "registry" {
  metadata {
    name      = "registry"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "registry"
      }
    }
    template {
      metadata {
        labels = {
          app = "registry"
        }
      }
      spec {
        container {
          name  = "registry"
          image = "registry:2"
          port {
            container_port = 5000
          }
          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "registry" {
  metadata {
    name      = "registry"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }
  spec {
    selector = {
      app = "registry"
    }
    port {
      port        = 5000
      target_port = 5000
    }
    type = "ClusterIP"
  }
}
