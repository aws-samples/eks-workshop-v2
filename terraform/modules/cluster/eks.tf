locals {
  default_mng_min  = 3
  default_mng_max  = 6
  default_mng_size = 3
}

module "aws-eks-accelerator-for-terraform" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.4.0"

  tags = local.tags

  vpc_id             = module.aws_vpc.vpc_id
  private_subnet_ids = module.aws_vpc.private_subnets
  public_subnet_ids  = module.aws_vpc.public_subnets

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  map_roles = var.map_roles

  managed_node_groups = {
    mg_5 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["t3.medium"]
      subnet_ids      = module.aws_vpc.private_subnets

      min_size     = local.default_mng_min
      max_size     = local.default_mng_max
      desired_size = local.default_mng_size

      k8s_labels = {
        workshop-default = "yes"
      }
    }
  }

  fargate_profiles = {
    workshop_system = {
      fargate_profile_name = "workshop_system"
      fargate_profile_namespaces = [
        {
          namespace = "workshop-system"
      }]
      subnet_ids = module.aws_vpc.private_subnets
    }
  }

}
