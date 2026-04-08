module "kyverno" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  description      = "Kyverno Kubernetes Native Policy Management"
  chart            = "kyverno"
  chart_version    = var.kyverno_chart_version
  namespace        = "kyverno"
  create_namespace = true
  repository       = "https://kyverno.github.io/kyverno/"

  set = [
    {
      name  = "webhooksCleanup.enabled"
      value = "true"
    }
  ]

  # disable_webhooks passes --no-hooks to helm uninstall, skipping the
  # webhooksCleanup job which hangs when Kyverno is being torn down.
  # cleanup.sh uninstalls both Helm releases directly before Terraform runs,
  # so Terraform destroy finds nothing to do and completes immediately.
  wait             = false
  disable_webhooks = true
}

module "kyverno_policies" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  description   = "Kyverno policy library"
  chart         = "kyverno-policies"
  chart_version = var.kyverno_chart_version
  namespace     = "kyverno"
  repository    = "https://kyverno.github.io/kyverno/"
  values = [
    <<-EOT
          podSecurityStandard: privileged
        EOT
  ]

  disable_webhooks = true

  depends_on = [module.kyverno]
}
