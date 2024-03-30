output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CLOUDWATCH_LOG_GROUP_NAME = local.cw_log_group_name
  }
}