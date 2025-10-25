output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    LBC_CHART_VERSION = var.load_balancer_controller_chart_version
    LBC_ROLE_ARN      = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
    FIS_ROLE_ARN      = aws_iam_role.fis_role.arn
    RANDOM_SUFFIX     = random_id.suffix.hex
    SCRIPT_DIR        = var.script_dir
    CANARY_ROLE_ARN   = aws_iam_role.canary_role.arn
    AWS_REGION        = data.aws_region.current.name
  }
}