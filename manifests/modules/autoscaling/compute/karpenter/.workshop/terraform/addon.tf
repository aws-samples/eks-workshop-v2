module "karpenter" {
  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/karpenter"
  addon_context = merge(local.addon_context, { default_repository = local.amazon_container_image_registry_uris[data.aws_region.current.name] })

  node_iam_instance_profile = aws_iam_instance_profile.karpenter_node.name

  helm_config = {
    set = [{
      name  = "replicas"
      value = "1"
    }]
  }
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name = "${local.addon_context.eks_cluster_id}-karpenter-node"
  role = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role" "karpenter_node" {
  name = "${local.addon_context.eks_cluster_id}-karpenter-node"

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
export KARPENTER_NODE_ROLE="${aws_iam_role.karpenter_node.arn}"
EOF
}
