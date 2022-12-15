module "iam_assumable_role_adot_ci" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v5.5.0"
  create_role                   = true
  role_name                     = "${var.environment_name}-adot-collector-ci"
  provider_url                  = local.oidc_url
  role_policy_arns              = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:other:adot-collector-ci"]

  tags = local.tags
}
