module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_cluster_autoscaler = true
  cluster_autoscaler = {
    role_name              = "${var.addon_context.eks_cluster_id}-cluster-autoscaler"
    role_name_use_prefix   = false
    policy_name            = "${var.addon_context.eks_cluster_id}-cluster-autoscaler"
    policy_name_use_prefix = false
  }
  create_kubernetes_resources = false

  observability_tag = null
}
