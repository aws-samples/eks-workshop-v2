module "aws_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = local.vpc_name
  cidr = local.vpc_cidr
  secondary_cidr_blocks = local.secondary_cidrs
  azs  = local.azs

  public_subnets  = concat(local.primary_pub_subnets, local.secondary_pub_subnets)
  private_subnets = concat(local.primary_priv_subnets, local.secondary_priv_subnets)

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