terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.31.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
    local = {
      version = "2.6.2"
    }
  }
}

terraform {
  backend "kubernetes" {
    secret_suffix = "state"
    config_path   = "~/.kube/config"
    namespace     = "kube-system"
  }
}

# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_id" {
  description = "EKS cluster name"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "resources_precreated" {
  description = "Have expensive resources been created already"
  type        = bool
  default     = false
}

# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_auto_id" {
  description = "EKS Auto Mode cluster name"
  type        = string
  default     = "eks-workshop-auto"
}

# tflint-ignore: terraform_unused_declarations
variable "inbound_cidrs" {
  description = "CIDR range to allowlist for inbound traffic"
  type        = string
  default     = "0.0.0.0/0"
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_eks_clusters" "available" {}

data "aws_eks_cluster" "eks_cluster" {
  count = local.standard_cluster_exists ? 1 : 0
  name  = var.eks_cluster_id
}

data "aws_eks_cluster_auth" "this" {
  count = local.standard_cluster_exists ? 1 : 0
  name  = var.eks_cluster_id
}

locals {
  standard_cluster_exists = contains(data.aws_eks_clusters.available.names, var.eks_cluster_id)
  auto_cluster_exists     = contains(data.aws_eks_clusters.available.names, var.eks_cluster_auto_id)
}

data "aws_eks_cluster" "eks_cluster_auto" {
  count = local.auto_cluster_exists ? 1 : 0
  name  = var.eks_cluster_auto_id
}

data "aws_eks_cluster_auth" "this_auto" {
  count = local.auto_cluster_exists ? 1 : 0
  name  = var.eks_cluster_auto_id
}

provider "aws" {
  default_tags {
    tags = local.tags
  }
}

provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.eks_cluster[0].endpoint, "https://localhost")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.eks_cluster[0].certificate_authority[0].data), "")
  token                  = try(data.aws_eks_cluster_auth.this[0].token, "")
}

provider "kubernetes" {
  alias                  = "auto_mode"
  host                   = try(data.aws_eks_cluster.eks_cluster_auto[0].endpoint, "https://localhost")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.eks_cluster_auto[0].certificate_authority[0].data), "")
  token                  = try(data.aws_eks_cluster_auth.this_auto[0].token, "")
}

provider "helm" {
  kubernetes {
    host                   = try(data.aws_eks_cluster.eks_cluster[0].endpoint, "https://localhost")
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.eks_cluster[0].certificate_authority[0].data), "")
    token                  = try(data.aws_eks_cluster_auth.this[0].token, "")
  }
}

provider "helm" {
  alias = "auto_mode"
  kubernetes {
    host                   = try(data.aws_eks_cluster.eks_cluster_auto[0].endpoint, "https://localhost")
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.eks_cluster_auto[0].certificate_authority[0].data), "")
    token                  = try(data.aws_eks_cluster_auth.this_auto[0].token, "")
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = try(data.aws_eks_cluster.eks_cluster[0].endpoint, "https://localhost")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.eks_cluster[0].certificate_authority[0].data), "")
  load_config_file       = false
  token                  = try(data.aws_eks_cluster_auth.this[0].token, "")
}

locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }

  eks_cluster_id            = try(data.aws_eks_cluster.eks_cluster[0].id, var.eks_cluster_id)
  eks_oidc_issuer_url       = try(replace(data.aws_eks_cluster.eks_cluster[0].identity[0].oidc[0].issuer, "https://", ""), "")
  eks_cluster_endpoint      = try(data.aws_eks_cluster.eks_cluster[0].endpoint, "")
  eks_cluster_version       = try(data.aws_eks_cluster.eks_cluster[0].version, "")
  eks_oidc_provider_arn     = try("arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer_url}", "")
  cluster_security_group_id = try(data.aws_eks_cluster.eks_cluster[0].vpc_config[0].cluster_security_group_id, "")

  addon_context = {
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_eks_cluster_endpoint       = local.eks_cluster_endpoint
    aws_partition_id               = data.aws_partition.current.partition
    aws_region_name                = data.aws_region.current.name
    eks_cluster_id                 = local.eks_cluster_id
    eks_oidc_issuer_url            = local.eks_oidc_issuer_url
    eks_oidc_provider_arn          = local.eks_oidc_provider_arn
    tags                           = {}
    irsa_iam_role_path             = "/"
    irsa_iam_permissions_boundary  = ""
  }
}
