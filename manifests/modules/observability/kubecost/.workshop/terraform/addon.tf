provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${local.eks_cluster_id}-ebs-csi-"

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
  source  = "aws-ia/eks-blueprints-addons/aws"
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

resource "time_sleep" "wait" {
  depends_on = [
    module.eks_blueprints_addons
  ]

  create_duration = "10s"
}

data "http" "kubecost_values" {
  url = "https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/v1.106.3/cost-analyzer/values-eks-cost-monitoring.yaml"
}

module "kubecost" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  depends_on = [
    time_sleep.wait
  ]

  name             = "kubecost"
  description      = "Kubecost Helm Chart deployment configuration"
  namespace        = "kubecost"
  create_namespace = true
  chart            = "cost-analyzer"
  chart_version    = "1.106.3"
  repository       = "oci://public.ecr.aws/kubecost"
  values           = [data.http.kubecost_values.body, templatefile("${path.module}/values.yaml", {})]
  wait             = true

  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
}
