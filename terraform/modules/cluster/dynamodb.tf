resource "aws_dynamodb_table" "carts" {
  name             = "${local.cluster_name}-carts"
  hash_key         = "id"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

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
}

module "iam_assumable_role_carts" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v3.13.0"
  create_role                   = true
  role_name                     = "${local.cluster_name}-carts-dynamo"
  provider_url                  = module.aws-eks-accelerator-for-terraform.eks_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.carts_dynamo.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:carts:carts"]
}

resource "aws_iam_policy" "carts_dynamo" {
  name        = "${local.cluster_name}-carts-dynamo"
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
        "arn:aws:dynamodb:${local.aws_region}:${local.aws_account_id}:table/${aws_dynamodb_table.carts.name}",
        "arn:aws:dynamodb:${local.aws_region}:${local.aws_account_id}:table/${aws_dynamodb_table.carts.name}/index/*"
      ]
    }
  ]
}
EOF
}