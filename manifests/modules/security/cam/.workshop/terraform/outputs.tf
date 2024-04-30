output "developers_role" {
  description = "AWS IAM Role created for EKS Developers access"
  value       = aws_iam_role.developers
}

output "aws_auth" {
  description = "Merged content for `aws-auth` configMap"
  value       = kubernetes_config_map_v1_data.aws_auth
}