resource "random_string" "fluentbit_log_group" {
  length  = 6
  special = false
}

locals {
  cw_log_group_name = "/${var.addon_context.eks_cluster_id}/worker-fluentbit-logs-${random_string.fluentbit_log_group.result}"
}