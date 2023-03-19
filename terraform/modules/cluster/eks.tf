locals {
  default_mng_min  = 2
  default_mng_max  = 6
  default_mng_size = 2
}

#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.10"

  cluster_name                   = var.environment_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          ENABLE_POD_ENI           = "true"

          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
      })
    }
  }

  kms_key_enable_default_policy = true

  vpc_id     = module.aws_vpc.vpc_id
  subnet_ids = local.private_subnet_ids

  cluster_security_group_additional_rules = {
    ingress_from_cloud9_host = {
      description = "Ingress from Cloud9 Host"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [module.aws_vpc.vpc_cidr_block]
    }
  }

  node_security_group_additional_rules = {
    # Extend node-to-node security group rules
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  # Add karpenter.sh/discovery tag so that we can use this as securityGroupSelector in karpenter provisioner
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.environment_name
  }

  eks_managed_node_groups = {
    managed-ondemand = {
      instance_types = ["m5.large"]

      min_size     = local.default_mng_min
      max_size     = local.default_mng_max
      desired_size = local.default_mng_size

      labels = {
        workshop-default = "yes"
      }
    }

    managed-system = {
      instance_types = ["m5.large"]

      min_size     = 1
      max_size     = 2
      desired_size = 1

      taints = [{
        key    = "systemComponent"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]

      labels = {
        workshop-system = "yes"
      }
    }

    managed-ondemand-tainted = {
      instance_types = ["m5.large"]

      min_size     = 0
      max_size     = 2
      desired_size = 0

      labels = {
        workshop-default = "no"
        tainted          = "yes"
      }
    }

    fargate_profiles = {
      checkout_profile = {
        name = "checkout-profile"
        selectors = [
          {
            namespace = "checkout"
            labels = {
              fargate = "yes"
            }
          },
        ]
      }
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true
  aws_auth_roles            = var.map_roles

  tags = local.tags
}

resource "aws_security_group_rule" "dns_udp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [module.aws_vpc.vpc_cidr_block]
  security_group_id = module.eks.cluster_primary_security_group_id
}

resource "aws_security_group_rule" "dns_tcp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = [module.aws_vpc.vpc_cidr_block]
  security_group_id = module.eks.cluster_primary_security_group_id
}
