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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}


module "iam_assumable_role_carts" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-carts-ack"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.carts_dynamo.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:carts:carts"]

  tags = var.tags
}

resource "aws_iam_policy" "carts_dynamo" {
  name        = "${var.addon_context.eks_cluster_id}-carts-dynamo"
  path        = "/"
  description = "Dynamo policy for carts application"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllAPIActionsOnCart",
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": [
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.addon_context.eks_cluster_id}-carts-ack",
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.addon_context.eks_cluster_id}-carts-ack/index/*"
      ]
    }
  ]
}
EOF
  tags   = var.tags
}

resource "aws_iam_policy" "ack_dynamo" {
  name        = "${var.addon_context.eks_cluster_id}-ack-dynamo"
  path        = "/"
  description = "Dynamo policy for carts application"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllAPIActionsOnCart",
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": [
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.addon_context.eks_cluster_id}-carts-ack",
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.addon_context.eks_cluster_id}-carts-ack/index/*"
      ]
    }
  ]
}
EOF
  tags   = var.tags
}

module "iam_assumable_role_ack" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-ack-controller"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.ack_dynamo.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:ack-system:ack-dynamodb-controller"]

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait        = true
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  observability_tag = null
}

resource "time_sleep" "blueprints_addons_sleep" {
  depends_on = [
    module.eks_blueprints_addons
  ]

  create_duration  = "15s"
  destroy_duration = "15s"
}

resource "kubectl_manifest" "nlb" {
  yaml_body = templatefile("${path.module}/templates/nlb.yaml", {

  })

  wait = true

  depends_on = [time_sleep.blueprints_addons_sleep]
}