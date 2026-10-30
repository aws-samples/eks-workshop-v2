# Nothing consumes these. Labs discover Identity Center through data sources and the
# naming convention below, so that a lab's Terraform is identical whether this module
# ran or an administrator set Identity Center up by hand.
#
# They exist to make a pre-provisioning run legible in the build log, which is the
# only place anyone looks when an event comes up without a working sign-in.
output "idc_instance_arn" {
  description = "ARN of the Identity Center instance that was created or adopted"
  value       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
}

output "idc_identity_store_id" {
  description = "Identity store holding the workshop user and group"
  value       = local.identity_store_id
}

output "idc_user_name" {
  description = "Sign-in name of the Argo CD administrator"
  value       = aws_identitystore_user.argocd_admin.user_name
}

output "idc_group_name" {
  description = "Group that capabilities map to the Argo CD ADMIN role"
  value       = aws_identitystore_group.argocd_admins.display_name
}

output "idc_secret_name" {
  description = "Secrets Manager secret holding the activated {username,password}"
  value       = aws_secretsmanager_secret.argocd_admin.name
}
