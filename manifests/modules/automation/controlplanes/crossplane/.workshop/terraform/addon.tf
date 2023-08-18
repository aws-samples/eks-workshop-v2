resource "terraform_data" "cluster" {
  provisioner "local-exec" {
    command = <<EOF
echo "ASDASD"
EOF
  }
}

module "crossplane" {
  depends_on = [
    terraform_data.cluster
  ]

  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.1//modules/kubernetes-addons/crossplane"
  addon_context = local.addon_context

  helm_config = {
    name             = "crossplane"
    chart            = "crossplane"
    repository       = "https://charts.crossplane.io/stable/"
    version          = "1.12.1"
    namespace        = "crossplane-system"
    timeout          = 1200
    create_namespace = true
    values           = [templatefile("${path.module}/templates/crossplane.yaml",{})]
  }

  aws_provider = {
    enable                   = true
    provider_aws_version     = "v0.40.0"
    additional_irsa_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  }

  kubernetes_provider = {
    enable = false
  }

  helm_provider = {
    enable = false
  }

  jet_aws_provider = {
    enable = false

    additional_irsa_policies = []
    provider_aws_version     = ""
  }

  upbound_aws_provider = {
    enable = false
  }
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }

  cluster_name      = local.addon_context.eks_cluster_id
  cluster_endpoint  = local.addon_context.aws_eks_cluster_endpoint
  cluster_version   = local.eks_cluster_version
  oidc_provider_arn = local.addon_context.eks_oidc_provider_arn
}

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }
}

data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

output "environment" {
  value = <<EOF
export VPC_ID=${data.aws_vpc.selected.id}
export VPC_CIDR=${data.aws_vpc.selected.cidr_block}
%{for index, id in data.aws_subnets.private.ids}
export VPC_PRIVATE_SUBNET_ID_${index + 1}=${id}
%{endfor}
EOF
}