terraform {
  backend "s3" {}

  required_version = "<= 1.2.9"
}

module "core" {
  source = "../../terraform"

  environment_suffix = var.environment_suffix
}
