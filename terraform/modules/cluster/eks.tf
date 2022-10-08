locals {
  default_mng_min  = 2
  default_mng_max  = 6
  default_mng_size = 2
}

module "aws-eks-accelerator-for-terraform" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.10.0"

  tags = local.tags

  vpc_id             = module.aws_vpc.vpc_id
  private_subnet_ids = slice(module.aws_vpc.private_subnets, 0, 3)
  public_subnet_ids  = module.aws_vpc.public_subnets

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  map_roles = var.map_roles

  node_security_group_additional_rules = {
    # Extend node-to-node security group rules. Recommended and required for the Add-ons
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Recommended outbound traffic for Node groups
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # Allows Control Plane Nodes to talk to Worker nodes on Karpenter ports.
    # This can be extended further to specific port based on the requirement for others Add-on e.g., metrics-server 4443, spark-operator 8080, etc.
    # Change this according to your security requirements if needed
    ingress_nodes_karpenter_port = {
      description                   = "Cluster API to Nodegroup for Karpenter"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  # Add karpenter.sh/discovery tag so that we can use this as securityGroupSelector in karpenter provisioner
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }

  managed_node_groups = {
    mg_5 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["m5.large"]
      subnet_ids      = slice(module.aws_vpc.private_subnets, 0, 3)
      min_size        = local.default_mng_min
      max_size        = local.default_mng_max
      desired_size    = local.default_mng_size

      k8s_labels = {
        workshop-default = "yes"
      }
    }

    system = {
      node_group_name = "managed-system"
      instance_types  = ["m5.large"]
      subnet_ids      = slice(module.aws_vpc.private_subnets, 0, 1)
      min_size        = 1
      max_size        = 2
      desired_size    = 1

      k8s_taints = [{ key = "systemComponent", value = "true", effect = "NO_SCHEDULE" }]

      k8s_labels = {
        workshop-system = "yes"
      }
    }
  }

  fargate_profiles = {
    default_profile = {
      fargate_profile_name = "default-profile"
      fargate_profile_namespaces = [{
        namespace = "kube-system"
        k8s_labels = {
          fargate = "yes"
        }
        }, {
        namespace = "karpenter"
        k8s_labels = {
          fargate = "yes"
        }
        }, {
        namespace = "aws-load-balancer-controller"
        k8s_labels = {
          fargate = "yes"
        }
      }]
      subnet_ids = module.aws_vpc.private_subnets
    }
  }

}
