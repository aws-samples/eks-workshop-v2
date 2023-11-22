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

resource "aws_iam_role" "spot_node" {
  name = "${local.addon_context.eks_cluster_id}-spot-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:${local.addon_context.aws_partition_id}:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:${local.addon_context.aws_partition_id}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:${local.addon_context.aws_partition_id}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:${local.addon_context.aws_partition_id}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = local.tags
}

output "environment" {
  value = <<EOF
export SPOT_NODE_ROLE="${aws_iam_role.spot_node.arn}"
%{for index, id in data.aws_subnets.private.ids}
export PRIMARY_SUBNET_${index + 1}=${id}
%{endfor}
EOF
}
