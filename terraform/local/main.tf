module "cluster" {
  source = "../modules/cluster"

  id = var.id

  map_roles = [{
    rolearn  = aws_iam_role.local_role.arn
    username = local.rolename
    groups   = ["system:masters"]
  }]
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "local_role" {
  name = local.rolename

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "local_role_eks_read" {
  role       = aws_iam_role.local_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

locals {
  tags = {
    created-by  = "eks-workshop-v2"
    env         = var.id
  }

  prefix        = "eks-workshop"
  rolename      = join("-", [local.prefix, local.tags.env, "role"])
}