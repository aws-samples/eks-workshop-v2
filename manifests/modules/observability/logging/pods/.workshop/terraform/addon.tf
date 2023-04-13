module "aws-for-fluentbit" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/aws-for-fluentbit"

  cw_log_group_name = "/${local.addon_context.eks_cluster_id}/worker-fluentbit-logs-${random_string.fluentbit_log_group.result}"

  addon_context = local.addon_context
}

resource "random_string" "fluentbit_log_group" {
  length  = 6
  special = false
}
