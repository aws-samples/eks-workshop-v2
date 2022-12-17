resource "aws_kms_key" "cmk" {
  description             = "KMS CMK for various resources like EFS, DynamoDB"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cmk.json
}

resource "aws_kms_alias" "cmk" {
  name          = "alias/${var.environment_name}-cmk"
  target_key_id = aws_kms_key.cmk.key_id
}

data "aws_iam_policy_document" "cmk" {
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
      values   = ["dynamodb.*.amazonaws.com", "elasticfilesystem.*.amazonaws.com"]
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
      values   = ["dynamodb.*.amazonaws.com", "elasticfilesystem.*.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
