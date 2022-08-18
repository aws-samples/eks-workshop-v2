terraform {
  backend "s3" {}
}

module "local" {
  source  = "../../terraform/local"

  id = var.cluster_id
}