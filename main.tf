terraform {
  required_version = "1.4.4"
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.9.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.19.0"
    }
  }
}

module "istio" {
  source = "./module/istio"
}

module "kubernetes" {
  source = "./module/kubernetes"
}

module "observability" {
  source = "./module/observability"
}