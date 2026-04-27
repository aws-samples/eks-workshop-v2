module "lab" {
  source = "./lab"

  providers = {
    helm.auto_mode       = helm.auto_mode
    kubernetes.auto_mode = kubernetes.auto_mode
  }

  eks_cluster_id            = local.eks_cluster_id
  eks_cluster_auto_id       = var.eks_cluster_auto_id
  eks_cluster_version       = local.eks_cluster_version
  cluster_security_group_id = local.cluster_security_group_id
  addon_context             = local.addon_context
  tags                      = local.tags
  resources_precreated      = var.resources_precreated
  inbound_cidrs             = var.inbound_cidrs
}

locals {
  environment_variables = try(module.lab.environment_variables, [])
}
