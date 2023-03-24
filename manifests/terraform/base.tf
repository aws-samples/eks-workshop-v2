terraform {
  required_version = ">= 1.3"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
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

variable "eks_cluster_id" {
  type = string
}

variable "resources_precreated" {
  type    = bool
  default = false
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_id
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_id
}

provider "kubernetes" {
  host                   = local.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = local.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = local.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}

locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }

  eks_oidc_issuer_url  = replace(data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  eks_cluster_endpoint = data.aws_eks_cluster.eks_cluster.endpoint
  eks_cluster_version  = data.aws_eks_cluster.eks_cluster.version

  addon_context = {
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_eks_cluster_endpoint       = local.eks_cluster_endpoint
    aws_partition_id               = data.aws_partition.current.partition
    aws_region_name                = data.aws_region.current.name
    eks_cluster_id                 = data.aws_eks_cluster.eks_cluster.id
    eks_oidc_issuer_url            = local.eks_oidc_issuer_url
    eks_oidc_provider_arn          = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"
    tags                           = {}
    irsa_iam_role_path             = "/"
    irsa_iam_permissions_boundary  = ""
  }

  amazon_container_image_registry_uris = {
    af-south-1     = "877085696533.dkr.ecr.af-south-1.amazonaws.com",
    ap-east-1      = "800184023465.dkr.ecr.ap-east-1.amazonaws.com",
    ap-northeast-1 = "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com",
    ap-northeast-2 = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com",
    ap-northeast-3 = "602401143452.dkr.ecr.ap-northeast-3.amazonaws.com",
    ap-south-1     = "602401143452.dkr.ecr.ap-south-1.amazonaws.com",
    ap-southeast-1 = "602401143452.dkr.ecr.ap-southeast-1.amazonaws.com",
    ap-southeast-2 = "602401143452.dkr.ecr.ap-southeast-2.amazonaws.com",
    ap-southeast-3 = "296578399912.dkr.ecr.ap-southeast-3.amazonaws.com",
    ca-central-1   = "602401143452.dkr.ecr.ca-central-1.amazonaws.com",
    cn-north-1     = "918309763551.dkr.ecr.cn-north-1.amazonaws.com.cn",
    cn-northwest-1 = "961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn",
    eu-central-1   = "602401143452.dkr.ecr.eu-central-1.amazonaws.com",
    eu-north-1     = "602401143452.dkr.ecr.eu-north-1.amazonaws.com",
    eu-south-1     = "590381155156.dkr.ecr.eu-south-1.amazonaws.com",
    eu-west-1      = "602401143452.dkr.ecr.eu-west-1.amazonaws.com",
    eu-west-2      = "602401143452.dkr.ecr.eu-west-2.amazonaws.com",
    eu-west-3      = "602401143452.dkr.ecr.eu-west-3.amazonaws.com",
    me-south-1     = "558608220178.dkr.ecr.me-south-1.amazonaws.com",
    me-central-1   = "759879836304.dkr.ecr.me-central-1.amazonaws.com",
    sa-east-1      = "602401143452.dkr.ecr.sa-east-1.amazonaws.com",
    us-east-1      = "602401143452.dkr.ecr.us-east-1.amazonaws.com",
    us-east-2      = "602401143452.dkr.ecr.us-east-2.amazonaws.com",
    us-gov-east-1  = "151742754352.dkr.ecr.us-gov-east-1.amazonaws.com",
    us-gov-west-1  = "013241004608.dkr.ecr.us-gov-west-1.amazonaws.com",
    us-west-1      = "602401143452.dkr.ecr.us-west-1.amazonaws.com",
    us-west-2      = "602401143452.dkr.ecr.us-west-2.amazonaws.com"
  }
}
