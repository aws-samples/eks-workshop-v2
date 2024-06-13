output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    KUBECOST_CHART_VERSION = var.kubecost_chart_version
  }
}