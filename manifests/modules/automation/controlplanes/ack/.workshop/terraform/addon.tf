locals {
  ddb_name = "ack-ddb"
}

#This module installs the ACK controller for DynamoDB through the AWS EKS Addons for ACK
module "dynamodb_ack_addon" {

  source = "aws-ia/eks-ack-addons/aws"
  version = "2.1.0"
  
  # Cluster Info
  cluster_name      = local.addon_context.eks_cluster_id
  cluster_endpoint  = local.addon_context.aws_eks_cluster_endpoint
  oidc_provider_arn = local.addon_context.eks_oidc_issuer_url

  # Controllers to enable
  enable_dynamodb          = true

  #TODO - add namespace configuration to add to carts
  
  tags = local.tags
}

#module "iam_assumable_role_carts" {
#  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#  version                       = "~> v5.5.5"
#  create_role                   = true
#  role_name                     = "${local.addon_context.eks_cluster_id}-carts-dynamo"
#  provider_url                  = local.addon_context.eks_oidc_issuer_url
#  role_policy_arns              = [aws_iam_policy.carts_dynamo.arn]
#  oidc_subjects_with_wildcards  = ["system:serviceaccount:carts:*"]
#
# tags = local.tags
#}

resource "aws_iam_policy" "carts_dynamo" {
  name        = "${local.addon_context.eks_cluster_id}-carts-dynamo"
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
  tags   = local.tags
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "1.9.2"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }

  cluster_name      = local.addon_context.eks_cluster_id
  cluster_endpoint  = local.addon_context.aws_eks_cluster_endpoint
  cluster_version   = local.eks_cluster_version
  oidc_provider_arn = local.addon_context.eks_oidc_provider_arn
}

output "environment" {
  value = <<EOF
export DYNAMODB_POLICY_ARN=${aws_iam_policy.carts_dynamo.arn}
export DYNAMODB_ACKROLE_ARN=${module.iam_assumable_role_carts.iam_role_arn}
EOF
}
