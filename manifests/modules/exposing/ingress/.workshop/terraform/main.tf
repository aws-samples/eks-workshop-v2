data "aws_vpc" "this" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

data "external" "vs_code_vpc_id" {
  program = ["bash", "-c", <<EOF
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    MAC=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/mac)
    VPC_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/vpc-id)
    echo "{\"vpc_id\": \"$VPC_ID\"}"
EOF
  ]
}

resource "aws_route53_zone" "private_zone" {
  name    = "retailstore.com"
  comment = "Private hosted zone for EKS Workshop use"
  vpc {
    vpc_id = data.aws_vpc.this.id
  }
  vpc {
    vpc_id = data.external.vs_code_vpc_id.result.vpc_id
  }

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.21.0"

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
