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

resource "aws_eks_node_group" "tainted" {
  cluster_name    = local.addon_context.eks_cluster_id
  node_group_name = "tainted"
  node_role_arn   = aws_iam_role.tainted_nodegroup.arn
  subnet_ids      = data.aws_subnets.private.ids

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    workshop-default = "no"
    tainted          = "yes"
  }

  depends_on = [
    aws_iam_role_policy_attachment.tainted_nodegroup-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.tainted_nodegroup-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.tainted_nodegroup-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "tainted_nodegroup" {
  name = "${local.addon_context.eks_cluster_id}-tainted-nodegroup"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "tainted_nodegroup-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.tainted_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "tainted_nodegroup-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.tainted_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "tainted_nodegroup-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.tainted_nodegroup.name
}

output "environment" {
  value = <<EOF
export EKS_TAINTED_MNG_NAME="${aws_eks_node_group.tainted.node_group_name}"
EOF
}
