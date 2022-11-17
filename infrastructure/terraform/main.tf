terraform {
  backend "s3" {}
}

module "core" {
  source  = "../../terraform"

  id                          = var.cluster_id
  repository_archive_location = var.repository_archive_location
  cloud9_user_arns            = var.cloud9_additional_role == "" ? [] : [var.cloud9_additional_role]
}