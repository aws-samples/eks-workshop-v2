module "aws-eks-accelerator-for-terraform" {
  source = "git::https://github.com/aws-ia/terraform-aws-eks-blueprints.git?ref=v4.0.1"

  tenant            = local.tenant
  environment       = local.environment
  zone              = local.zone
  terraform_version = local.terraform_version

  vpc_id             = module.aws_vpc.vpc_id
  private_subnet_ids = module.aws_vpc.private_subnets

  cluster_version = local.cluster_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  managed_node_groups = {
    mg_5 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["m5.large"]
      subnet_ids      = module.aws_vpc.private_subnets
    }
  }

}
