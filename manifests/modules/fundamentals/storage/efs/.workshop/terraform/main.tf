module "efs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix   = "${var.addon_context.eks_cluster_id}-efs-csi-"
  policy_name_prefix = "${var.addon_context.eks_cluster_id}-ebs-csi-"

  attach_efs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "preprovision" {
  source = "./preprovision"
  count  = var.resources_precreated ? 0 : 1

  eks_cluster_id = var.eks_cluster_id
  tags           = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait        = true
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  observability_tag = null
}

resource "time_sleep" "wait" {
  depends_on = [module.eks_blueprints_addons]

  create_duration = "10s"
}

resource "kubernetes_manifest" "ui_nlb" {
  depends_on = [module.eks_blueprints_addons]

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "name"      = "ui-nlb"
      "namespace" = "ui"
      "annotations" = {
        "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
        "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
      }
    }
    "spec" = {
      "type" = "LoadBalancer"
      "ports" = [{
        "port"       = 80
        "targetPort" = 8080
        "name"       = "http"
      }]
      "selector" = {
        "app.kubernetes.io/name"      = "ui"
        "app.kubernetes.io/instance"  = "ui"
        "app.kubernetes.io/component" = "service"
      }
    }
  }
}
