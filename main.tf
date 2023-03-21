locals {
  ports = [
    {
      name = "minecraft"
      nodePort =  30565
      protocol = "TCP"
      targetPort = 25565
    }
  ]
}

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

resource "kubernetes_namespace" "istio-system" {
  metadata {
    name = "istio-system"
  }
}

# resource "kubernetes_namespace" "istio-operator" {
#   metadata {
#     name = "istio-operator"
#   }
# }

# resource "helm_release" "istio-operator" {
#   name = "istio-operator"
#   repository = "https://wiremind.github.io/wiremind-helm-charts"
#   chart = "istio-operator"
#   namespace = "istio-system"
# }

resource "helm_release" "istio-base" {
  name = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart = "base"
  namespace = "istio-system"
}

resource "helm_release" "istiod" {
  name = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart = "istiod"
  namespace = "istio-system"

  depends_on = [helm_release.istio-base]

  set {
    name = "global.tracer.zipkin.address"
    value = "jaeger-collector.istio-system.svc.cluster.local:14250"
  }
  
   set {
    name  = "prometheus.enabled"
    value = "true"
  }
  
  set {
    name  = "prometheus.namespace"
    value = "custom-namespace"
  }

  set {
    name  = "kiali.enabled"
    value = "true"
  }

  set {
    name  = "tracing.enabled"
    value = "true"
  }

  set {
    name  = "tracing.provider"
    value = "jaeger"
  }
}

resource "kubernetes_namespace" "istio-ingress" {
  metadata {
    labels = {
      istio-injection = "enabled"
    }

    name = "istio-ingress"
  }
}

resource "helm_release" "istio-ingress" {
  name = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart = "gateway"
  namespace = "istio-ingress"

  depends_on = [helm_release.istiod]
  
  set {
    name = "service.type"
    value = "NodePort"
  }

  set {
    name = "service.ports[0].name"
    value = "minecraft"
  }

  set {
    name = "service.ports[0].port"
    value = 25565
  }

  set {
    name = "service.ports[0].protocol"
    value = "TCP"
  }

  set {
    name = "service.ports[0].targetPort"
    value = 25565
  }
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

  depends_on = [helm_release.istiod]
}

resource "helm_release" "kiali-operator" {
  name = "kiali"
  repository = "https://kiali.org/helm-charts"
  chart = "kiali-operator"
  namespace = "kiali-operator"
  create_namespace = true

  depends_on = [helm_release.prometheus]

  set {
    name = "cr.create"
    value = "true"
  }

  set {
    name = "cr.namespace"
    value = "istio-system"
  }
}

# resource "kubernetes_manifest" "kiali" {
#   depends_on = [helm_release.kiali-operator]
#   manifest = {
#     "apiVersion" = "kiali.io/v1alpha1"
#     "kind" = "Kiali"
#     "metadata" = {
#       "name" = "kiali"
#       "namespace"= "istio-system"
#     }
#     "spec" = {
#       "auth" = {
#         "strategy" = "token"
#       }
#       "deployment" = {
#         "accessible_namespaces" = ["istio-ingress", "minecraft"]
#         "view_only_mode" = "false"
#       }
#       "server" = {
#         "web_root" = "/kiali"
#       }
#     }
#   }
# }

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

#resource "kubernetes_manifest" "jaeger" {
#  depends_on = [helm_release.jaeger-operator]
#
#  manifest = {
#    "apiVersion" = "jaegertracing.io/v1"
#    "kind": "Jaeger"
#    "metadata" = {
#      "name" = "allinone"
#      "namespace" = "istio-system"
#    }
#  }
#}