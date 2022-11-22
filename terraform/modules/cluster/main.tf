data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks-blueprints.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks-blueprints.eks_cluster_id
}

provider "aws" {
  region = data.aws_region.current.id
  alias  = "default"

  default_tags {
    tags = local.tags
  }
}

provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}

locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.id
  }

  cluster_version = var.cluster_version
  prefix          = "eks-workshop"

  vpc_cidr               = "10.42.0.0/16"
  secondary_vpc_cidr     = "100.64.0.0/16"
  primary_priv_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]
  secondary_priv_subnets = [for k, v in local.azs : cidrsubnet(local.secondary_vpc_cidr, 8, k + 10)]
  public_subnets         = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  vpc_name               = join("-", [local.prefix, local.tags.env, "vpc"])
  azs                    = slice(data.aws_availability_zones.available.names, 0, 3)
  cluster_name           = join("-", [local.prefix, local.tags.env])

  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = data.aws_region.current.id
}