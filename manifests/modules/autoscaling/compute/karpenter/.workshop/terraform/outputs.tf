output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    KARP_ROLE = module.eks_blueprints_addons.karpenter.node_iam_role_name
    KARP_ARN  = module.eks_blueprints_addons.karpenter.node_iam_role_arn
  }
}