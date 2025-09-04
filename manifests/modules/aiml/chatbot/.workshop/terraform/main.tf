locals {
  namespace = "kube-system"
}

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

# Addons for ALB Controller

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

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

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  observability_tag = null
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

# Pod identity for Karpenter

resource "aws_eks_addon" "pod_identity" {
  cluster_name                = var.addon_context.eks_cluster_id
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve                    = false
}

# Karpenter controller & Node IAM roles, SQS Queue, Eventbridge Rules

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.1"

  cluster_name = var.addon_context.eks_cluster_id
  namespace    = local.namespace

  iam_role_name                   = "${var.addon_context.eks_cluster_id}-karpenter-controller"
  iam_role_use_name_prefix        = false
  iam_policy_name                 = "${var.addon_context.eks_cluster_id}-karpenter-controller"
  iam_policy_use_name_prefix      = false
  node_iam_role_name              = "${var.addon_context.eks_cluster_id}-karpenter-node"
  node_iam_role_use_name_prefix   = false
  queue_name                      = "${var.addon_context.eks_cluster_id}-karpenter"
  rule_name_prefix                = "eks-workshop"
  create_pod_identity_association = true

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

# Helm chart

resource "helm_release" "karpenter" {
  name                = "karpenter"
  namespace           = local.namespace
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  # renovate: datasource=github-releases depName=aws/karpenter-provider-aws
  version = "1.6.3"
  wait    = true

  values = [
    <<-EOT
    settings:
      clusterName: ${var.addon_context.eks_cluster_id}
      clusterEndpoint: ${var.addon_context.aws_eks_cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}
