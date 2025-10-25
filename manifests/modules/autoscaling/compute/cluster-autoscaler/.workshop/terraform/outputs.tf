output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CLUSTER_AUTOSCALER_ROLE          = module.eks_blueprints_addons.cluster_autoscaler.iam_role_arn
    CLUSTER_AUTOSCALER_CHART_VERSION = var.cluster_autoscaler_chart_version
    CLUSTER_AUTOSCALER_IMAGE_TAG     = var.cluster_autoscaler_version
  }
}