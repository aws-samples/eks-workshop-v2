data "aws_vpc" "this" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

resource "aws_route53_zone" "private_zone" {
  name    = "retailstore.com"
  comment = "Private hosted zone for EKS Workshop use"
  vpc {
    vpc_id = data.aws_vpc.this.id
  }

  force_destroy = true

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_external_dns            = true
  external_dns_route53_zone_arns = [aws_route53_zone.private_zone.arn]
  external_dns = {
    create_role = true
    role_name   = "${var.addon_context.eks_cluster_id}-external-dns"
    policy_name = "${var.addon_context.eks_cluster_id}-external-dns"
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }

  create_kubernetes_resources = false

  observability_tag = null
}
