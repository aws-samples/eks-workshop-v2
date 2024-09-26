output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    AIML_SUBNETS        = "${data.aws_subnets.private.ids[0]},${data.aws_subnets.private.ids[1]},${data.aws_subnets.private.ids[2]}"
    KARPENTER_NODE_ROLE = module.karpenter.node_iam_role_name
    KARPENTER_ARN       = module.karpenter.node_iam_role_arn
  }
}
