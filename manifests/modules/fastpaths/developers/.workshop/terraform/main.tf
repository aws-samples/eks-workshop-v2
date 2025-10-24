module "preprovision" {
  source = "./preprovision"
  count  = var.resources_precreated ? 0 : 1

  providers = {
    helm.auto_mode = helm.auto_mode
  }

  eks_cluster_id      = var.eks_cluster_id
  eks_cluster_auto_id = var.eks_cluster_auto_id
  tags                = var.tags
}