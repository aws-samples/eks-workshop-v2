output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    KARPENTER_VERSION   = var.karpenter_version
    KARPENTER_SQS_QUEUE = module.karpenter.queue_name
    KARPENTER_ROLE      = module.karpenter.node_iam_role_name
    KARPENTER_ROLE_ARN  = module.karpenter.node_iam_role_arn
    KUBERNETES_VERSION  = var.eks_cluster_version
  }
}