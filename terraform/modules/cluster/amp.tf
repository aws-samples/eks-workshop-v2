resource "aws_prometheus_workspace" "this" {
  alias = var.environment_name

  tags = local.tags
}

module "iam_assumable_role_adot" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v5.5.0"
  create_role                   = true
  role_name                     = "${var.environment_name}-adot-collector"
  provider_url                  = local.oidc_url
  role_policy_arns              = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:other:adot-collector"]

  tags = local.tags
}
