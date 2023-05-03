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

  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/crossplane"
  addon_context = local.addon_context

  aws_provider = {
    enable                   = true
    provider_aws_version     = "v0.36.0"
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

module "aws-load-balancer-controller" {
  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/aws-load-balancer-controller"
  addon_context = merge(local.addon_context, { default_repository = local.amazon_container_image_registry_uris[data.aws_region.current.name] })
}

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop"
    env        = local.addon_context.eks_cluster_id
  }
}

data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop"
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