terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait        = true
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
    # turn off the mutating webhook
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }

  enable_karpenter = true

  karpenter_enable_spot_termination          = true
  karpenter_enable_instance_profile_creation = true
  karpenter = {
    chart_version          = var.karpenter_version
    repository_username    = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password    = data.aws_ecrpublic_authorization_token.token.password
    role_name              = "${var.addon_context.eks_cluster_id}-karpenter-controller"
    role_name_use_prefix   = false
    policy_name            = "${var.addon_context.eks_cluster_id}-karpenter-controller"
    policy_name_use_prefix = false
  }

  karpenter_node = {
    iam_role_use_name_prefix = false
    iam_role_name            = "${var.addon_context.eks_cluster_id}-karpenter-node"
    instance_profile_name    = "${var.addon_context.eks_cluster_id}-karpenter"
  }

  karpenter_sqs = {
    queue_name = "${var.addon_context.eks_cluster_id}-karpenter"
  }

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn
}

data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}
