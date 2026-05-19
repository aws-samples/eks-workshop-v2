output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    LBC_CHART_VERSION = var.load_balancer_controller_chart_version
    LBC_ROLE_ARN      = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
    DNS_CHART_VERSION = var.external_dns_chart_version
    DNS_ROLE_ARN      = module.eks_blueprints_addons.external_dns.iam_role_arn
  }
}
