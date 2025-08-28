data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

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

resource "time_sleep" "wait" {
  depends_on = [module.eks_blueprints_addons]

  create_duration = "10s"
}

resource "kubernetes_manifest" "ui_nlb" {
  depends_on = [module.eks_blueprints_addons]

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

resource "aws_dynamodb_table" "carts" {
  #checkov:skip=CKV2_AWS_28:Point in time backup not required for workshop
  name             = "${var.addon_context.eks_cluster_id}-carts"
  hash_key         = "id"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.cmk_dynamodb.arn
  }

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name            = "idx_global_customerId"
    hash_key        = "customerId"
    projection_type = "ALL"
  }

  tags = var.tags
}

module "iam_assumable_role_carts" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-carts-dynamo"
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
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.carts.name}",
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.carts.name}/index/*"
      ]
    }
  ]
}
EOF
  tags   = var.tags
}

resource "aws_kms_key" "cmk_dynamodb" {
  description             = "KMS CMK for DynamoDB"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cmk_dynamodb.json
}

resource "aws_kms_alias" "cmk" {
  name          = "alias/${var.addon_context.eks_cluster_id}-cmk-dynamodb"
  target_key_id = aws_kms_key.cmk_dynamodb.key_id
}

data "aws_iam_policy_document" "cmk_dynamodb" {
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        format(
          "arn:%s:iam::%s:root",
          data.aws_partition.current.partition,
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    resources = ["*"]
  }
  statement {
    sid = "Allow DynamoDB to get information about the CMK"
    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "dynamodb.amazonaws.com"
      ]
    }
    resources = ["*"]
  }
  statement {
    sid = "Allow principals to encrypt."
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["dynamodb.*.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
  statement {
    sid = "Allow principals to decrypt."
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["dynamodb.*.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
