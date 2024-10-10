output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    AMP_WORKSPACE_ID             = aws_prometheus_workspace.this.id
    KUBECOST_CHART_VERSION       = var.kubecost_chart_version
    KUBECOST_IAM_ROLE            = module.kubecost_cost_analyzer_irsa.iam_role_arn
    KUBECOST_PROMETHEUS_IAM_ROLE = module.kubecost_prometheus_server_irsa.iam_role_arn
  }
}
