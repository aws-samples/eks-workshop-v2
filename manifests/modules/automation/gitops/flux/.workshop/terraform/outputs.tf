output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    GITOPS_IAM_SSH_KEY_ID = aws_iam_user_ssh_key.gitops.id
    GITOPS_IAM_SSH_USER   = aws_iam_user.gitops.unique_id
  }
}
