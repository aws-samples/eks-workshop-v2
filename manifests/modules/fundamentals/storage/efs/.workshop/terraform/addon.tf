module "efs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${local.eks_cluster_id}-efs-csi-"

  attach_efs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

output "environment" {
  value = <<EOF
export EFS_CSI_ADDON_ROLE="${module.efs_csi_driver_irsa.iam_role_arn}"
EOF
}