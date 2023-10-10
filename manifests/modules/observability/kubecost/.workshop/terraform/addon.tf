module "aws-ebs-csi-driver" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/aws-ebs-csi-driver"

  enable_amazon_eks_aws_ebs_csi_driver = true

  addon_config = {
    kubernetes_version = local.eks_cluster_version
    preserve           = false
  }

  addon_context = local.addon_context
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }

  cluster_name      = local.addon_context.eks_cluster_id
  cluster_endpoint  = local.addon_context.aws_eks_cluster_endpoint
  cluster_version   = local.eks_cluster_version
  oidc_provider_arn = local.addon_context.eks_oidc_provider_arn
}

data "http" "kubecost_values" {
  url    = "https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/v1.102.0/cost-analyzer/values-eks-cost-monitoring.yaml"
}

module "kubecost" {
  depends_on = [
    module.aws-ebs-csi-driver,
    module.eks_blueprints_addons
  ]

  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/kubecost"
  addon_context = local.addon_context

  helm_config = {
    version = "1.102.0"
    values = [data.http.kubecost_values.body, templatefile("${path.module}/values.yaml", {})]
  }
}
