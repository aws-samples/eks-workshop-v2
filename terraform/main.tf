terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.46.0"
    }
  }

  required_version = ">= 1.3.7"
}

provider "aws" {
  region = data.aws_region.current.id
  alias  = "default"

  default_tags {
    tags = local.tags
  }
}

module "cluster" {
  source = "./modules/cluster"

  environment_name = local.environment_name

  tags = local.tags

  map_roles = concat(local.map_roles, [{
    rolearn  = aws_iam_role.local_role.arn
    username = local.shell_role_name
    groups   = ["system:masters"]
    }, {
    # Did it this way because of circular dependencies
    rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.cluster.eks_cluster_id}-cloud9"
    username = "cloud9"
    groups   = ["system:masters"]
  }])
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.environment_name
  }

  prefix           = "eks-workshop"
  environment_name = var.environment_suffix == "" ? local.prefix : "${local.prefix}-${var.environment_suffix}"
  shell_role_name  = "${local.environment_name}-shell-role"
  map_roles = [for i, r in var.eks_role_arns : {
    rolearn  = r
    username = "additional${i}"
    groups   = ["system:masters"]
  }]
}
