output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    BUCKET_NAME       = aws_s3_bucket.s3_data.id
    EKS_CLUSTER_NAME  = var.eks_cluster_id
    FSX_ID            = aws_fsx_lustre_file_system.fsx_lustre.id
    FSX_DNS_NAME      = aws_fsx_lustre_file_system.fsx_lustre.dns_name
    FSX_MOUNT_NAME    = aws_fsx_lustre_file_system.fsx_lustre.mount_name
  }
}