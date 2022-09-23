locals {
  name = "cost-analyzer"

  default_helm_config = {
    name             = local.name
    chart            = local.name
    repository       = "oci://public.ecr.aws/kubecost"
    version          = "1.96.0"
    namespace        = "kubecost"
    create_namespace = true
    values           = local.default_helm_values
    set              = []
    description      = "Provide real-time cost visibility and insights for teams using Kubernetes."
    wait             = false
  }

  default_helm_values = [templatefile("${path.module}/values.yaml", {})]

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )
}
