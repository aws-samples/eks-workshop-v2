terraform {
  backend "s3" {}

  required_version = "<= 1.2.9"
}

module "core" {
  source = "../../terraform"

  environment_suffix = var.environment_suffix
  repository_ref     = var.repository_ref
  cloud9_owner       = var.cloud9_owner
  eks_role_arns      = var.eks_additional_role == "" ? [] : [var.eks_additional_role]
}
