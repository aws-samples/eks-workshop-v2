locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.cluster_name
  }
}