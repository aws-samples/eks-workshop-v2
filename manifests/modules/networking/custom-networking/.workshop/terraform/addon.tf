locals {
  secondary_cidr = "100.64.0.0/16"
}

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }
}

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

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = data.aws_vpc.selected.id
  cidr_block = local.secondary_cidr
}

data "aws_subnet" "selected" {
  count = length(data.aws_subnets.private.ids)

  id = data.aws_subnets.private.ids[count.index]
}

resource "aws_subnet" "in_secondary_cidr" {
  count = length(data.aws_subnets.private.ids)

  vpc_id            = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
  cidr_block        = cidrsubnet(local.secondary_cidr, 3, count.index)
  availability_zone = data.aws_subnet.selected[count.index].availability_zone

  tags = local.tags
}

data "aws_route_table" "private" {
  count = length(data.aws_subnets.private.ids)

  vpc_id    = data.aws_vpc.selected.id
  subnet_id = data.aws_subnets.private.ids[count.index]
}

resource "aws_route_table_association" "a" {
  count = length(data.aws_subnets.private.ids)

  subnet_id      = aws_subnet.in_secondary_cidr[count.index].id
  route_table_id = data.aws_route_table.private[count.index].route_table_id
}

resource "aws_iam_role" "custom_networking_node" {
  name = "${local.addon_context.eks_cluster_id}-custom-node"

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
export VPC_ID=${data.aws_vpc.selected.id}
export EKS_CLUSTER_SECURITY_GROUP_ID=${data.aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id}
export CUSTOM_NETWORKING_NODE_ROLE="${aws_iam_role.custom_networking_node.arn}"
%{for index, id in data.aws_subnets.private.ids}
export PRIMARY_SUBNET_${index + 1}=${id}
%{endfor}
%{for index, id in aws_subnet.in_secondary_cidr.*.id}
export SECONDARY_SUBNET_${index + 1}=${id}
%{endfor}
%{for index, az in aws_subnet.in_secondary_cidr.*.availability_zone}
export SUBNET_AZ_${index + 1}=${az}
%{endfor}
EOF
}
