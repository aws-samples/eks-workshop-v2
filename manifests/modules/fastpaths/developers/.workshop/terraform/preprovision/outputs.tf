output "environment_variables" {
  description = "Environment variables exported into the IDE shell"
  value = {
    CLOUDWATCH_LOG_GROUP_NAME = aws_cloudwatch_log_group.fluentbit.name
    EKS_CAP_DDB_TABLE         = local.eks_cap_carts_table_name
    EKS_CAP_ACK_CAPABILITY    = aws_eks_capability.ack.capability_name

    # Argo CD capability (Lab 2)
    EKS_CAP_ARGOCD_CAPABILITY     = aws_eks_capability.argocd.capability_name
    EKS_CAP_ARGOCD_URL            = try(aws_eks_capability.argocd.configuration[0].argo_cd[0].server_url, "")
    EKS_CAP_ARGOCD_ADMIN_GROUP    = aws_identitystore_group.argocd_admins.display_name
    EKS_CAP_ARGOCD_ADMIN_GROUP_ID = aws_identitystore_group.argocd_admins.group_id
    EKS_CAP_ARGOCD_USER           = aws_identitystore_user.argocd_admin.user_name
    EKS_CAP_CODECOMMIT_REPO       = aws_codecommit_repository.catalog_gitops.repository_name
    EKS_CAP_CODECOMMIT_URL        = local.eks_cap_codecommit_repo_url
    EKS_CLUSTER_AUTO_ARN          = data.aws_eks_cluster.eks_cluster_auto.arn
  }
}
