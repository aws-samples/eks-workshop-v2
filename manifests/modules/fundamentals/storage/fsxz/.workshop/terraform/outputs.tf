output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    VPC_CIDR         = data.aws_vpc.selected_fsxz.cidr_block
    PRIVATE_SUBNET0  = data.aws_subnet.private_fsxz.id
    FSXZ_SG          = aws_security_group.fsxz_sg.id
    EKS_CLUSTER_NAME = var.eks_cluster_id
    REGION           = data.aws_region.region_current.name
  }
}
