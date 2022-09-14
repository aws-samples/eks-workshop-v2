module "aws_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = local.vpc_name
  cidr = local.vpc_cidr
  secondary_cidr_blocks = [local.secondary_vpc_cidr]
  azs  = local.azs

  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = concat(
    [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)],
    [for k, v in local.azs : cidrsubnet(local.secondary_vpc_cidr, 8, k + 10)]
  )

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "karpenter.sh/discovery"                      = local.cluster_name
  }

  tags = local.tags
}