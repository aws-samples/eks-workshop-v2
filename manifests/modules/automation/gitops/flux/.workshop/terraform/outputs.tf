output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    GITEA_CHART_VERSION = var.gitea_chart_version
    GITEA_PASSWORD      = random_string.gitea_password.result
    SSH_PUBLIC_KEY      = tls_private_key.gitops.public_key_openssh
  }
}
