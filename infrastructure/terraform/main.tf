terraform {
  backend "s3" {}
}

module "core" {
  source = "../../terraform"

  id             = var.cluster_id
  repository_ref = var.repository_ref
  cloud9_owner   = var.cloud9_owner
  eks_role_arns  = var.eks_additional_role == "" ? [] : [var.eks_additional_role]
}
