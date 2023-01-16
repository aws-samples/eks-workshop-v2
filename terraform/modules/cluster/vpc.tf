locals {
  vpc_cidr               = "10.42.0.0/16"
  secondary_vpc_cidr     = "100.64.0.0/16"
  primary_priv_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]
  secondary_priv_subnets = [for k, v in local.azs : cidrsubnet(local.secondary_vpc_cidr, 8, k + 10)]
  public_subnets         = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]

  private_subnet_ids        = length(module.aws_vpc.private_subnets) > 0 ? slice(module.aws_vpc.private_subnets, 0, 3) : []
  primary_private_subnet_id = length(module.aws_vpc.private_subnets) > 0 ? slice(module.aws_vpc.private_subnets, 0, 1) : []
}

module "aws_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name                  = var.environment_name
  cidr                  = local.vpc_cidr
  secondary_cidr_blocks = [local.secondary_vpc_cidr]
  azs                   = local.azs

  public_subnets = local.public_subnets
  private_subnets = concat(
    local.primary_priv_subnets,
    local.secondary_priv_subnets
  )

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
    "karpenter.sh/discovery"                        = var.environment_name
  }

  tags = local.tags
}
