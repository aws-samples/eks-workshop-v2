resource "aws_eks_addon" "pod_identity" {
  cluster_name                = var.addon_context.eks_cluster_id
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve                    = false
}

module "karpenter" {
  source                             = "terraform-aws-modules/eks/aws//modules/karpenter"
  version                            = "21.15.1"
  iam_role_permissions_boundary_arn  = var.addon_context.irsa_iam_permissions_boundary
  node_iam_role_permissions_boundary = var.addon_context.irsa_iam_permissions_boundary

  cluster_name                    = var.addon_context.eks_cluster_id
  create_pod_identity_association = true
  namespace                       = "karpenter"
  iam_role_name                   = "${var.addon_context.eks_cluster_id}-karpenter-controller"
  iam_role_use_name_prefix        = false
  iam_policy_name                 = "${var.addon_context.eks_cluster_id}-karpenter-controller"
  iam_policy_use_name_prefix      = false
  node_iam_role_name              = "${var.addon_context.eks_cluster_id}-karpenter-node"
  node_iam_role_use_name_prefix   = false
  queue_name                      = "${var.addon_context.eks_cluster_id}-karpenter"
  rule_name_prefix                = "eks-workshop"

  # Karpenter 1.14 calls ec2:DescribeInstanceStatus for instance health checks;
  # module 21.15.1 doesn't grant it (added in 21.19).
  iam_policy_statements = [
    {
      sid       = "AllowDescribeInstanceStatus"
      actions   = ["ec2:DescribeInstanceStatus"]
      resources = ["*"]
    }
  ]

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}
