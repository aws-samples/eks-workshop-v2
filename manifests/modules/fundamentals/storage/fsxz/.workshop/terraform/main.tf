# Create FSxZ CSI Driver IAM Role and associated policy
module "fsxz_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name_prefix   = "${var.addon_context.eks_cluster_id}-fsxz-csi-"
  policy_name_prefix = "${var.addon_context.eks_cluster_id}-fsxz-csi-"

  attach_fsxz_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:fsxz-csi-controller-sa"]
    }
  }

  tags = var.tags

  force_detach_policies = true
  
}