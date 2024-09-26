# Get AWS account ID
data "aws_caller_identity" "current" {}

# Create a unique S3 bucket
resource "aws_s3_bucket" "mountpoint-s3" {

   bucket_prefix = "${var.addon_context.eks_cluster_id}-mountpoint-s3"

   force_destroy = true
   # Start with eks cluster id
  #  bucket = "mountpoint-s3-${data.aws_caller_identity.current.account_id}"
}

# S3 CSI Driver IAM Role
module "mountpoint_s3_csi_driver_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name_prefix = "${var.addon_context.eks_cluster_id}-s3-csi-"
  
  # IAM policy to attach to driver
  policy_name_prefix = "${var.addon_context.eks_cluster_id}-s3-csi-"

  attach_mountpoint_s3_csi_policy = true

  mountpoint_s3_csi_bucket_arns   = [aws_s3_bucket.mountpoint-s3.arn]
  mountpoint_s3_csi_path_arns     = ["${aws_s3_bucket.mountpoint-s3.arn}/*"]

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:s3-csi-driver-sa"]
    }
  }

  tags = var.tags
}

# Mountpoint S3 CSI Add-On
# This might be just a command to run so may not be needed
# resource "aws_eks_addon" "mountpoint_s3_csi_addon" {
#   cluster_name  = var.addon_context.eks_cluster_id
#   addon_name    = "aws-mountpoint-s3-csi-driver"
#   addon_version = "v1.7.0-eksbuild.1"
# }

