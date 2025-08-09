module "iam_assumable_role_keda" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.59.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-keda"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchReadOnlyAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:keda:keda-operator"]

  tags = var.tags
}
