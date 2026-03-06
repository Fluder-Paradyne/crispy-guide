
terraform {
  required_version = ">= 1.0"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "kind" {}

provider "kubernetes" {
  host                   = kind_cluster.local.endpoint
  cluster_ca_certificate  = kind_cluster.local.cluster_ca_certificate
  client_certificate     = kind_cluster.local.client_certificate
  client_key             = kind_cluster.local.client_key
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.local.endpoint
    cluster_ca_certificate = kind_cluster.local.cluster_ca_certificate
    client_certificate     = kind_cluster.local.client_certificate
    client_key             = kind_cluster.local.client_key
  }
}
