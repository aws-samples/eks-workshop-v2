output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    EKS_CLUSTER_NAME = var.eks_cluster_id
    REGION           = data.aws_region.current.name
    FSXL_FS_ID       = aws_fsx_lustre_file_system.this.id
    FSXL_IAM_ROLE    = module.iam_assumable_role_fsx_lustre.iam_role_arn
    FSXL_SG          = aws_security_group.fsxl_sg.id
    FSXL_SUBNET_ID   = data.aws_subnet.private_fsxl.id
  }
}
