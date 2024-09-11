output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = merge({
    KARPENTER_VERSION   = var.karpenter_version
    KARPENTER_ROLE = module.eks_blueprints_addons_karpenter.karpenter.node_iam_role_name
    }, {
    for index, id in data.aws_subnets.private.ids : "PRIMARY_SUBNET_${index + 1}" => id
  })
  sensitive = true
}