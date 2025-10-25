output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CPA_CHART_VERSION = var.cluster_proportional_autoscaler_chart_version
    CPA_VERSION       = var.cluster_proportional_autoscaler_version
  }
}