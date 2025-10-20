locals {
}


# Add access for the current user/role running Terraform
resource "aws_eks_access_entry" "current_user" {
  cluster_name  = aws_eks_cluster.auto_mode.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "current_user_admin" {
  cluster_name  = aws_eks_cluster.auto_mode.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.current_user]
}

resource "aws_dynamodb_table" "auto_carts" {
  name             = "${var.auto_cluster_name}-carts"
  hash_key         = "id"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  server_side_encryption {
    enabled = true
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

  tags = local.tags
}

resource "aws_iam_role" "auto_carts_dynamo" {
  name = "${var.auto_cluster_name}-carts-dynamo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_policy" "auto_carts_dynamo" {
  name        = "${var.auto_cluster_name}-carts-dynamo"
  description = "Dynamo policy for carts application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllAPIActionsOnCart"
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        aws_dynamodb_table.auto_carts.arn,
        "${aws_dynamodb_table.auto_carts.arn}/index/*"
      ]
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "auto_carts_dynamo" {
  policy_arn = aws_iam_policy.auto_carts_dynamo.arn
  role       = aws_iam_role.auto_carts_dynamo.name
}

resource "aws_iam_role" "auto_keda" {
  name = "${var.auto_cluster_name}-keda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "auto_keda_cloudwatch" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchReadOnlyAccess"
  role       = aws_iam_role.auto_keda.name
}
