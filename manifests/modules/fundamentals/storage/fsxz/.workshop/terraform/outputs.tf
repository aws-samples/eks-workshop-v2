output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    VPC_CIDR         = data.aws_vpc.selected_fsxz.cidr_block
    EKS_CLUSTER_NAME = var.eks_cluster_id
    REGION           = data.aws_region.region_current.name
    FSXZ_FS_ID       = module.fsx_openzfs.file_system_id
    FSXZ_IAM_ROLE    = module.iam_assumable_role_fsx.iam_role_arn
    FSXZ_SG          = aws_security_group.fsxz_sg.id
  }
}
