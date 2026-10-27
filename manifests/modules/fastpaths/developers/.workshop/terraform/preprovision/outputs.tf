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
    # Deliberately no EKS_CAP_ARGOCD_URL. The URL only exists as an attribute of the
    # capability resource, and the AWS provider has no data source for a capability it
    # did not create, so at an event -- where this module is applied into a different
    # state -- there is nothing to read it from. The lab pages call
    # `aws eks describe-capability` instead, which works on both paths.
    EKS_CAP_ARGOCD_CAPABILITY     = try(aws_eks_capability.argocd[0].capability_name, "")
    EKS_CAP_ARGOCD_ADMIN_GROUP    = try(data.aws_identitystore_group.argocd_admins[0].display_name, "")
    EKS_CAP_ARGOCD_ADMIN_GROUP_ID = try(data.aws_identitystore_group.argocd_admins[0].group_id, "")
    EKS_CAP_ARGOCD_USER           = var.eks_cluster_id
    EKS_CAP_CODECOMMIT_REPO       = try(aws_codecommit_repository.catalog_gitops[0].repository_name, "")
    EKS_CAP_CODECOMMIT_URL        = local.eks_cap_codecommit_repo_url
    EKS_CLUSTER_AUTO_ARN          = data.aws_eks_cluster.eks_cluster_auto.arn

    # kro capability (Lab 3)
    EKS_CAP_KRO_CAPABILITY = try(aws_eks_capability.kro[0].capability_name, "")
    EKS_CAP_DDB_TABLE_KRO  = local.eks_cap_kro_table_name
  }
}
