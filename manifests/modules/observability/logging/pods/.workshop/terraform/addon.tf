resource "random_string" "fluentbit_log_group" {
  length  = 6
  special = false
}

locals {
  cw_log_group_name = "/${local.addon_context.eks_cluster_id}/worker-fluentbit-logs-${random_string.fluentbit_log_group.result}"
}

module "aws-for-fluentbit" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.1//modules/kubernetes-addons/aws-for-fluentbit"

  cw_log_group_name = local.cw_log_group_name

  addon_context = local.addon_context
}

output "environment" {
  value = <<EOF
export CLOUDWATCH_LOG_GROUP_NAME="${local.cw_log_group_name}"
EOF
}