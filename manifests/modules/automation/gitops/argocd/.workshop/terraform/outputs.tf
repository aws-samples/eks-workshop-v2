output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    GITOPS_IAM_SSH_KEY_ID  = aws_iam_user_ssh_key.gitops.id
    GITOPS_IAM_SSH_USER    = aws_iam_user.gitops.unique_id
    GITOPS_REPO_URL_ARGOCD = "ssh://${aws_iam_user_ssh_key.gitops.id}@git-codecommit.${data.aws_region.current.id}.amazonaws.com/v1/repos/${var.addon_context.eks_cluster_id}-argocd"
    ARGOCD_CHART_VERSION   = var.argocd_chart_version
  }
}