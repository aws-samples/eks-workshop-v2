module "kyverno" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  description      = "Kyverno Kubernetes Native Policy Management"
  chart            = "kyverno"
  chart_version    = "3.0.0"
  namespace        = "kyverno"
  create_namespace = true
  repository       = "https://kyverno.github.io/kyverno/"
}

module "kyverno_policies" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  description   = "Kyverno policy library"
  chart         = "kyverno-policies"
  chart_version = "3.0.0"
  namespace     = "kyverno"
  repository    = "https://kyverno.github.io/kyverno/"
  values = [
    <<-EOT
          podSecurityStandard: privileged
        EOT
  ]

  depends_on = [module.kyverno]
}