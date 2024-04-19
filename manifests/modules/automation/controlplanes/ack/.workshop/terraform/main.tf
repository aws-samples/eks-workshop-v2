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

#This module installs the ACK controller for DynamoDB through the AWS EKS Addons for ACK
module "dynamodb_ack_addon" {

  source  = "aws-ia/eks-ack-addons/aws"
  version = "2.2.0"

  # Cluster Info
  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  ecrpublic_username = data.aws_ecrpublic_authorization_token.token.user_name
  ecrpublic_token    = data.aws_ecrpublic_authorization_token.token.password

  # Controllers to enable
  enable_dynamodb = true

  tags = var.tags
}

resource "aws_iam_policy" "carts_dynamo" {
  name        = "${var.addon_context.eks_cluster_id}-carts-dynamo"
  path        = "/"
  description = "DynamoDB policy for AWS Sample Carts Application"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllAPIActionsOnCart",
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": [
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"        
      ]
    }
  ]
}
EOF
  tags   = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.2"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn
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

  depends_on = [time_sleep.blueprints_addons_sleep]
}