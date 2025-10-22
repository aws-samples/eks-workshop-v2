
data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_auto_id
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_auto_id
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# Helm provider configuration for EKS
terraform {
  required_version = ">= 1.3"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}

provider "helm" {
    kubernetes {
      host = data.aws_eks_cluster.eks_cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
      token = data.aws_eks_cluster_auth.this.token
    }
}