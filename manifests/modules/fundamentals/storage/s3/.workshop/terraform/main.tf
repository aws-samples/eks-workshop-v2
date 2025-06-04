# Create S3 bucket
resource "aws_s3_bucket" "mountpoint_s3" {

  bucket_prefix = "${var.addon_context.eks_cluster_id}-mountpoint-s3"
  force_destroy = true
}

# Create S3 CSI Driver IAM Role and associated policy
module "mountpoint_s3_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

  # Create prefixes
  role_name_prefix   = "${var.addon_context.eks_cluster_id}-s3-csi-"
  policy_name_prefix = "${var.addon_context.eks_cluster_id}-s3-csi-"

  # IAM policy to attach to driver
  attach_mountpoint_s3_csi_policy = true

  mountpoint_s3_csi_bucket_arns = [aws_s3_bucket.mountpoint_s3.arn]
  mountpoint_s3_csi_path_arns   = ["${aws_s3_bucket.mountpoint_s3.arn}/*"]

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:s3-csi-driver-sa"]
    }
  }

  tags = var.tags

  force_detach_policies = true
}