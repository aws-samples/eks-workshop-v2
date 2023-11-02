module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "1.9.2"

  cluster_name      = local.eks_cluster_id
  cluster_endpoint  = local.eks_cluster_endpoint
  cluster_version   = local.eks_cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn

  enable_cluster_autoscaler = true
  cluster_autoscaler        = {
    wait = true
  }
}