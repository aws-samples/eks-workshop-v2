module "secrets-store-csi-driver" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.1//modules/kubernetes-addons/kyverno"

  enable_kyverno_policies        = true
  enable_kyverno_policy_reporter = true

  kyverno_helm_config = {
    version = "3.0.0"
  }

  kyverno_policies_helm_config = {
    version = "2.5.5"
    values = [
      <<-EOT
        podSecurityStandard: privileged
      EOT
    ]
  }

  kyverno_policy_reporter_helm_config = {
    version = "2.21.1"
  }

  addon_context = local.addon_context
}
