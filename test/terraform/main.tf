terraform {
  backend "s3" {}
}

module "core" {
  source  = "../../terraform"

  id = var.cluster_id
}