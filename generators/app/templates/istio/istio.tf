locals {
  istio_charts_url = "https://istio-release.storage.googleapis.com/charts"
}

resource "helm_release" "istio-base" {
  repository       = local.istio_charts_url
  chart            = "base"
  name             = "istio-base"
  timeout          = 120
  namespace        = "istio-system"
  version          = "1.17.1"
  create_namespace = true
  cleanup_on_fail  = true
  force_update     = false
}

resource "helm_release" "istiod" {
  repository       = local.istio_charts_url
  chart            = "istiod"
  name             = "istiod"
  timeout          = 120
  namespace        = "istio-system"
  create_namespace = true
  version          = "1.17.1"
  cleanup_on_fail  = true
  force_update     = false
  depends_on       = [helm_release.istio-base]
}
<%_ if (onCloud && domain != "") { _%>
resource "helm_release" "istio-ingressgateway" {
  repository      = local.istio_charts_url
  chart           = "gateway"
  name            = "istio-ingressgateway"
  cleanup_on_fail = true
  force_update    = false
  timeout         = 500
  namespace       = "istio-system"
  version         = "1.17.1"
  depends_on      = [helm_release.istiod]

  set {
    name = "name"
    value = "istio-ingressgateway"
  }
  set {
    name = "labels.app"
    value = "istio-ingressgateway"
  }
  set {
    name = "labels.istio"
    value = "ingressgateway"
  }
  # provision's application loadbalancer
  set {
    name  = "service.type"
    value = "<%= cloudProvider == "aws" ? "NodePort" : "LoadBalancer" %>"
  }
}
<%_ } _%>

<%_ if (cloudProvider == "azure" && domain != "") { _%>

resource "time_sleep" "wait_30_seconds" {
  depends_on = [
    helm_release.istio-ingressgateway
    ]
  create_duration = "30s"
}

resource "null_resource" "print_loadBalancer_public_ip" {
  provisioner "local-exec" {
    command = "kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' >> output.txt"
  }
  depends_on = [
    time_sleep.wait_30_seconds
  ]
}

<%_ } _%>

<%_ if (cloudProvider == "aws" && domain != "") { _%>
resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "ingress"
    namespace = "istio-system"
    labels = {
      app = "ingress"
    }
    annotations = {
      <%_ if (cloudProvider == "aws") { _%>
      "kubernetes.io/ingress.class"       = "alb"
      "alb.ingress.kubernetes.io/scheme"  = "internet-facing"  
      "alb.ingress.kubernetes.io/load-balancer-name" = "${var.cluster_name}-istio-alb" 
      <%_ } _%>
      <%_ if (cloudProvider == "azure") { _%>
      "kubernetes.io/ingress.class" = "azure/ingress-controller"
      "service.beta.kubernetes.io/azure-dns-label-name" = "istio" 
      <%_ } _%>   
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service {
              name = "istio-ingressgateway"
              port {
                number = 80
              }
            }
          }
          path = "/*"
        }
      }
    }
  }

  depends_on = [
    helm_release.istio-ingressgateway
  ]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [kubernetes_ingress_v1.ingress]

  create_duration = "30s"
}

data "aws_lb" "istio_alb" {
  name = "${var.cluster_name}-istio-alb"
  depends_on = [
    time_sleep.wait_30_seconds
  ]
}

resource "null_resource" "print_alb_dns_name" {
  provisioner "local-exec" {
    command = "echo ${data.aws_lb.istio_alb.dns_name} >> output.txt"
  }
  depends_on = [
    data.aws_lb.istio_alb
  ]
}
<%_ } _%>

# Adds default namespace as side car in istio 
resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "kubectl label namespace default istio-injection=enabled"
  }
  depends_on = [
    helm_release.istio-base,
    helm_release.istiod,
    <%_ if (onCloud && domain != "") { _%>
    helm_release.istio-ingressgateway
    <%_ } _%>
  ]
}