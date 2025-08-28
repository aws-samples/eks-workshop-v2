data "aws_partition" "current" {}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }

  observability_tag = null
}

module "iam_assumable_role_keda" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-keda"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchReadOnlyAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:keda:keda-operator"]

  tags = var.tags
}

resource "kubernetes_manifest" "ui_alb" {
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "name"      = "ui"
      "namespace" = "ui"
      "annotations" = {
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/actuator/health/liveness"
      }
    }
    "spec" = {
      ingressClassName = "alb",
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
