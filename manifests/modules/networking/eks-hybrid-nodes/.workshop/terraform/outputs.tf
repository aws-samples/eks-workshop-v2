output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = merge({
    EKS_CLUSTER_VERSION = var.eks_cluster_version
    HYBRID_ROLE_ARN     = module.eks_hybrid_node_role.arn
    HYBRID_ROLE_NAME    = module.eks_hybrid_node_role.name
    HYBRID_NODE_IP      = module.hybrid_node.public_ip
  })
}
