output "environment_variables" {
  description = "Environment variables exported into the IDE shell"
  value = {
    CLOUDWATCH_LOG_GROUP_NAME = aws_cloudwatch_log_group.fluentbit.name

    # EKS capability env vars (Labs 1-3). Empty on dev/operator paths where the
    # capability resources are gated off (var.enable_eks_capabilities = false);
    # try(...) falls back to "" so the outputs stay valid when count = 0.
    EKS_CAP_DDB_TABLE      = local.eks_cap_carts_table_name
    EKS_CAP_ACK_CAPABILITY = try(aws_eks_capability.ack[0].capability_name, "")

    # Argo CD capability (Lab 2)
    EKS_CAP_ARGOCD_CAPABILITY     = try(aws_eks_capability.argocd[0].capability_name, "")
    EKS_CAP_ARGOCD_URL            = try(aws_eks_capability.argocd[0].configuration[0].argo_cd[0].server_url, "")
    EKS_CAP_ARGOCD_ADMIN_GROUP    = try(aws_identitystore_group.argocd_admins[0].display_name, "")
    EKS_CAP_ARGOCD_ADMIN_GROUP_ID = try(aws_identitystore_group.argocd_admins[0].group_id, "")
    EKS_CAP_ARGOCD_USER           = try(aws_identitystore_user.argocd_admin[0].user_name, "")
    EKS_CAP_CODECOMMIT_REPO       = try(aws_codecommit_repository.catalog_gitops[0].repository_name, "")
    EKS_CAP_CODECOMMIT_URL        = local.eks_cap_codecommit_repo_url
    EKS_CLUSTER_AUTO_ARN          = data.aws_eks_cluster.eks_cluster_auto.arn

    # kro capability (Lab 3)
    EKS_CAP_KRO_CAPABILITY = try(aws_eks_capability.kro[0].capability_name, "")
    EKS_CAP_DDB_TABLE_KRO  = local.eks_cap_kro_table_name
  }
}
