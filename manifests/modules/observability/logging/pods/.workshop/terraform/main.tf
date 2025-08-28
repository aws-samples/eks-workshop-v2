resource "random_string" "fluentbit_log_group" {
  length  = 6
  special = false
}

locals {
  cw_log_group_name = "/${var.addon_context.eks_cluster_id}/worker-fluentbit-logs-${random_string.fluentbit_log_group.result}"
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_aws_for_fluentbit = true

  aws_for_fluentbit = {
    chart_version = "0.1.32"

    role_name   = "${var.addon_context.eks_cluster_id}-fluent-bit"
    policy_name = "${var.addon_context.eks_cluster_id}-fluent-bit"

    wait = true
  }

  aws_for_fluentbit_cw_log_group = local.cw_log_group_name

  observability_tag = null
}
