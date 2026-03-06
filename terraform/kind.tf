
resource "kind_cluster" "local" {
  name           = var.cluster_name
  node_image     = "kindest/node:${var.kubernetes_version}"
  wait_for_ready = true
  kubeconfig_path = pathexpand("~/.kube/config-${var.cluster_name}")

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    node {
      role = "worker"
    }

    containerd_config_patches = [
      <<-EOT
        [plugins."io.containerd.grpc.v1.cri".registry]
          config_path = "/etc/containerd/certs.d"
      EOT
    ]
  }
}

resource "null_resource" "registry" {
  depends_on = [kind_cluster.local]

  triggers = {
    cluster = kind_cluster.local.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      if ! docker ps -a --format '{{.Names}}' | grep -q '^kind-registry$$'; then
        docker run -d --restart=always -p 127.0.0.1:${var.registry_port}:5000 --name kind-registry registry:2
      fi
    EOT
    interpreter = ["sh", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "docker stop kind-registry 2>/dev/null || true; docker rm kind-registry 2>/dev/null || true"
    interpreter = ["sh", "-c"]
  }
}

# Configure kind nodes to pull from in-cluster registry (runs after registry is deployed)
# Kind nodes cannot resolve registry.registry.svc.cluster.local (no cluster DNS for node resolution).
# Add /etc/hosts entry so containerd can resolve the registry hostname when pulling images.
resource "null_resource" "registry_config" {
  depends_on = [kubernetes_deployment.registry]

  triggers = {
    cluster = kind_cluster.local.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      export KUBECONFIG="${kind_cluster.local.kubeconfig_path}"
      REGISTRY_ADDR="registry.registry.svc.cluster.local:5000"
      REGISTRY_IP=$(kubectl get svc registry -n registry -o jsonpath='{.spec.clusterIP}')

      for node in $(kubectl get nodes --no-headers -o custom-columns=":metadata.name" 2>/dev/null); do
        REGISTRY_DIR="/etc/containerd/certs.d/$REGISTRY_ADDR"
        docker exec $node mkdir -p "$REGISTRY_DIR"
        cat <<EOF | docker exec -i $node tee "$REGISTRY_DIR/hosts.toml" > /dev/null
[host."http://$REGISTRY_ADDR"]
  capabilities = ["pull", "resolve", "push"]
  skip_verify = true
EOF
        docker exec $node sh -c "grep -q 'registry.registry.svc.cluster.local' /etc/hosts || echo '$REGISTRY_IP registry.registry.svc.cluster.local' >> /etc/hosts"
      done
    EOT
    interpreter = ["sh", "-c"]
    environment = {
      KUBECONFIG = kind_cluster.local.kubeconfig_path
    }
  }
}
