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

# EKS Capabilities run the ACK controller in AWS-managed infrastructure and
# assume a dedicated IAM "capability role" trusted by the
# capabilities.eks.amazonaws.com service principal (instead of IRSA). We attach
# the same least-privilege DynamoDB policy so the managed controller can only
# act on this lab's carts table.
resource "aws_iam_role" "ack_capability" {
  name = "${var.addon_context.eks_cluster_id}-ack-capability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ack_capability_dynamo" {
  role       = aws_iam_role.ack_capability.name
  policy_arn = aws_iam_policy.ack_dynamo.arn
}

# The managed ACK controller authenticates to the cluster's Kubernetes API using
# a cluster access entry tied to the capability role. We manage this access
# entry (and the AWS-managed ACK access policy) explicitly in Terraform so it is
# always created and destroyed together with the role. Otherwise, tearing the
# lab down and recreating it leaves a stale access entry bound to the previous
# role, and the capability fails to start with an "Unauthorized" error.
resource "aws_eks_access_entry" "ack_capability" {
  cluster_name  = var.addon_context.eks_cluster_id
  principal_arn = aws_iam_role.ack_capability.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ack_capability" {
  cluster_name  = var.addon_context.eks_cluster_id
  principal_arn = aws_iam_role.ack_capability.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSACKPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ack_capability]
}

# IAM is eventually consistent, so allow the newly created capability role and
# its trust policy to propagate before EKS validates it during capability
# creation. Without this, CreateCapability can fail with an
# "invalid trust policy" error even though the policy is correct.
resource "time_sleep" "wait_for_capability_role" {
  depends_on = [
    aws_iam_role.ack_capability,
    aws_iam_role_policy_attachment.ack_capability_dynamo,
  ]

  create_duration = "30s"
}

# Enable the fully managed AWS Controllers for Kubernetes (ACK) capability.
# Amazon EKS installs the ACK CRDs into the cluster as the capability becomes
# active; no controller is deployed into the cluster itself.
resource "aws_eks_capability" "ack_dynamodb" {
  cluster_name              = var.addon_context.eks_cluster_id
  capability_name           = "ack-dynamodb"
  type                      = "ACK"
  role_arn                  = aws_iam_role.ack_capability.arn
  delete_propagation_policy = "RETAIN"

  depends_on = [
    time_sleep.wait_for_capability_role,
    aws_eks_access_policy_association.ack_capability,
  ]

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.23.0"

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

resource "time_sleep" "wait" {
  depends_on = [module.eks_blueprints_addons]

  create_duration = "10s"
}

resource "kubernetes_manifest" "ui_nlb" {
  depends_on = [time_sleep.wait]

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "name"      = "ui-nlb"
      "namespace" = "ui"
      "annotations" = {
        "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
        "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
        "service.beta.kubernetes.io/load-balancer-source-ranges"       = var.inbound_cidrs
      }
    }
    "spec" = {
      "type" = "LoadBalancer"
      "ports" = [{
        "port"       = 80
        "targetPort" = 8080
        "name"       = "http"
      }]
      "selector" = {
        "app.kubernetes.io/name"      = "ui"
        "app.kubernetes.io/instance"  = "ui"
        "app.kubernetes.io/component" = "service"
      }
    }
  }
}
