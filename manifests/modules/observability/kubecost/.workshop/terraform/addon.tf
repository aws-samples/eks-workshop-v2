module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${local.eks_cluster_id}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "1.9.2"

  cluster_name      = local.eks_cluster_id
  cluster_endpoint  = local.eks_cluster_endpoint
  cluster_version   = local.eks_cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      preserve                 = false
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }
}

data "http" "kubecost_values" {
  url    = "https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/v1.102.0/cost-analyzer/values-eks-cost-monitoring.yaml"
}

module "kubecost" {
  depends_on = [
    module.eks_blueprints_addons
  ]

  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/kubecost"
  addon_context = local.addon_context

  helm_config = {
    version = "1.102.0"
    values = [data.http.kubecost_values.body, templatefile("${path.module}/values.yaml", {})]
  }
}
