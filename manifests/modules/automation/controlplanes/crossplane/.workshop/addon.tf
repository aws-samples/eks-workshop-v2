module "crossplane" {
  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/crossplane"
  addon_context = local.addon_context

  aws_provider = {
    enable                   = true
    provider_aws_version     = "v0.36.0"
    additional_irsa_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  }

  kubernetes_provider = {
    enable = false
  }

  helm_provider = {
    enable = false
  }

  jet_aws_provider = {
    enable = false

    additional_irsa_policies = []
    provider_aws_version     = ""
  }

  upbound_aws_provider = {
    enable = false
  }
}
