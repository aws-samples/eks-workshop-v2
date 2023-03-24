data "aws_vpc" "this" {
  tags = {
    created-by = "eks-workshop"
    env        = local.addon_context.eks_cluster_id
  }
}

output "environment" {
  value = <<EOF
export VPC_ID=${data.aws_vpc.this.id}
EOF
}
