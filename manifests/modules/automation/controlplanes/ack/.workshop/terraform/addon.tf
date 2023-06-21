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

module "aws-load-balancer-controller" {
  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/aws-load-balancer-controller"
  addon_context = merge(local.addon_context, { default_repository = local.amazon_container_image_registry_uris[data.aws_region.current.name] })
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
