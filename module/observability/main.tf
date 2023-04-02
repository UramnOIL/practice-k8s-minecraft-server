
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "minikube"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  name = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "prometheus"
  namespace = "monitoring"
  create_namespace = true
}

resource "helm_release" "kiali-operator" {
  name = "kiali"
  repository = "https://kiali.org/helm-charts"
  chart = "kiali-operator"
  namespace = "kiali-operator"
  create_namespace = true

  depends_on = [helm_release.prometheus]
  values = [
    file("${path.module}/kiali-operator-values.yaml")
  ]
}

resource "helm_release" "cert-manager" {
  name = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  namespace = "cert-manager"
  version = "v1.10.1"
  create_namespace = true

  set {
    name = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "jaeger-operator" {
  name = "jaeger-operator"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart = "jaeger-operator"
  namespace = "istio-system"

  depends_on = [helm_release.cert-manager]

  set {
    name = "jaeger.create"
    value = "true"
  }
}