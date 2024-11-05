output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    S3_CSI_ADDON_ROLE = module.mountpoint_s3_csi_driver_irsa.iam_role_arn
    BUCKET_NAME       = aws_s3_bucket.mountpoint_s3.id
    EKS_CLUSTER_NAME  = var.eks_cluster_id
  }
}