variable "keda_chart_version" {
  description = "The chart version of keda to use"
  type        = string
  # renovate-helm: depName=keda registryUrl=https://kedacore.github.io/charts
  default = "2.18.0"
}

resource "aws_iam_role" "keda_auto" {
  name = "${var.eks_cluster_auto_id}-keda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "keda_auto" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchReadOnlyAccess"
  role       = aws_iam_role.keda_auto.name
}

# EKS Pod Identity Association for FluentBit
resource "aws_eks_pod_identity_association" "keda_auto" {
  cluster_name    = var.eks_cluster_auto_id
  namespace       = "keda"
  service_account = "keda"
  role_arn        = aws_iam_role.keda_auto.arn
}

resource "kubernetes_manifest" "ui_alb" {
  count    = 0 # Created in exposing workloads with Ingress
  provider = kubernetes.auto_mode
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "name"      = "ui_keda"
      "namespace" = "ui"
      "annotations" = {
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/actuator/health/liveness"
      }
    }
    "spec" = {
      ingressClassName = "eks-auto-alb",
      "rules" = [{
        "http" = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            "backend" = {
              service = {
                name = "ui"
                port = {
                  number = 80
                }
              }
            }
          }]
        }
      }]
    }
  }
}
