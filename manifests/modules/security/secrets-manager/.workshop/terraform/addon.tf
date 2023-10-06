module "secrets-store-csi-driver" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.1//modules/kubernetes-addons/secrets-store-csi-driver"

  enable_secrets_store_csi_driver = true

  helm_config = {
    version = "1.3.4"
  }

  addon_context = local.addon_context
}

module "secrets_store_csi_driver_provider_aws" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.1//modules/kubernetes-addons/secrets_store_csi_driver_provider_aws"

  enable_secrets_store_csi_driver_provider_aws = true

  helm_config = {
    version = "0.3.4"
  }

  addon_context = local.addon_context
}
