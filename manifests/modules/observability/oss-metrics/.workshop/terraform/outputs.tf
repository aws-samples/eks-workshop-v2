output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    AMP_ENDPOINT = aws_prometheus_workspace.this.prometheus_endpoint
  }
}