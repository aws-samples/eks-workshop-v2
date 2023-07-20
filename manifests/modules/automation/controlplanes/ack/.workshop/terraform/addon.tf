locals {
  ec2_name = "ack-ec2"
  rds_name = "ack-rds"
}

module "rds" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.12.2"

  helm_config = {
    name             = local.rds_name
    chart            = "rds-chart"
    repository       = "oci://public.ecr.aws/aws-controllers-k8s"
    version          = "v0.1.1"
    namespace        = local.rds_name
    create_namespace = true
    description      = "ACK RDS Controller Helm chart deployment configuration"
    values = [
      # shortens pod name from `ack-rds-rds-chart-xxxxxxxxxxxxx` to `ack-rds-xxxxxxxxxxxxx`
      <<-EOT
        nameOverride: ack-rds
      EOT
    ]
  }

  set_values = [
    {
      name  = "serviceAccount.name"
      value = local.rds_name
    },
    {
      name  = "serviceAccount.create"
      value = false
    },
    {
      name  = "aws.region"
      value = data.aws_region.current.id
    }
  ]

  irsa_config = {
    create_kubernetes_namespace = true
    kubernetes_namespace        = local.rds_name

    create_kubernetes_service_account = true
    kubernetes_service_account        = local.rds_name

    irsa_iam_policies = [data.aws_iam_policy.rds.arn]
  }

  addon_context = local.addon_context
}

data "aws_iam_policy" "rds" {
  name = "AmazonRDSFullAccess"
}

module "ec2" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.12.2"

  helm_config = {
    name             = local.ec2_name
    chart            = "ec2-chart"
    repository       = "oci://public.ecr.aws/aws-controllers-k8s"
    version          = "v0.1.1"
    namespace        = local.ec2_name
    create_namespace = true
    description      = "ACK EC2 Controller Helm chart deployment configuration"
    values = [
      # shortens pod name from `ack-ec2-ec2-chart-xxxxxxxxxxxxx` to `ack-ec2-xxxxxxxxxxxxx`
      <<-EOT
        nameOverride: ack-ec2
      EOT
    ]
  }

  set_values = [
    {
      name  = "serviceAccount.name"
      value = local.ec2_name
    },
    {
      name  = "serviceAccount.create"
      value = false
    },
    {
      name  = "aws.region"
      value = data.aws_region.current.id
    }
  ]

  irsa_config = {
    create_kubernetes_namespace = true
    kubernetes_namespace        = local.ec2_name

    create_kubernetes_service_account = true
    kubernetes_service_account        = local.ec2_name

    irsa_iam_policies = [data.aws_iam_policy.ec2.arn]
  }

  addon_context = local.addon_context
}

data "aws_iam_policy" "ec2" {
  name = "AmazonEC2FullAccess"
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  enable_aws_load_balancer_controller = true

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
