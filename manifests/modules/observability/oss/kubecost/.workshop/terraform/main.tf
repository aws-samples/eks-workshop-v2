terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

data "aws_partition" "current" {}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name_prefix = "${var.addon_context.eks_cluster_id}-ebs-csi-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      preserve                 = false
      configuration_values     = jsonencode({ defaultStorageClass = { enabled = true } })
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }
}

resource "time_sleep" "blueprints_addons_sleep" {
  depends_on = [
    module.eks_blueprints_addons
  ]

  create_duration = "15s"
}

resource "aws_prometheus_workspace" "this" {
  alias = var.addon_context.eks_cluster_id

  tags = var.tags
}

module "kubecost_cost_analyzer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name_prefix = "${var.addon_context.eks_cluster_id}-kubecost-cost-analyzer-"

  role_policy_arns = {
    policy_1 = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
    policy_2 = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  }

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kubecost:kubecost-cost-analyzer"]
    }
  }

  tags = var.tags
}

module "kubecost_prometheus_server_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name_prefix = "${var.addon_context.eks_cluster_id}-kubecost-prometheus-"

  role_policy_arns = {
    policy_1 = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
    policy_2 = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  }

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kubecost:kubecost-prometheus-server"]
    }
  }

  tags = var.tags
}
