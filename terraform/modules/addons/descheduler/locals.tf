locals {
  name = "descheduler"

  default_helm_config = {
    name             = local.name
    chart            = local.name
    repository       = "https://kubernetes-sigs.github.io/descheduler"
    version          = "0.24.1"
    namespace        = "kube-system"
    create_namespace = false
    values           = local.default_helm_values
    set              = []
    description      = "Rebalance clusters by evicting Pods that can potentially be scheduled on better nodes."
    wait             = false
  }

  default_helm_values = [templatefile("${path.module}/values.yaml", {})]

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )
}
