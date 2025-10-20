provider "aws" {
  default_tags {
    tags = local.tags
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0"
    }
  }

  required_version = ">= 1.4.2"
}

# Data sources for EKS cluster authentication
data "aws_eks_cluster" "cluster" {
  name       = var.auto_cluster_name
  depends_on = [aws_eks_cluster.auto_mode]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = var.auto_cluster_name
  depends_on = [aws_eks_cluster.auto_mode]
}

# Helm provider configuration for EKS
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
