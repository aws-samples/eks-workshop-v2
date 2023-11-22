data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

output "environment" {
  value = <<EOF
%{for index, id in data.aws_subnets.private.ids}
export PRIMARY_SUBNET_${index + 1}=${id}
%{endfor}
EOF
}
