output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    NGINX_CHART_VERSION = var.nginx_chart_version
  }
}