module "cluster" {
  source = "./modules/cluster"

  id = var.id

  map_roles = [{
    rolearn  = aws_iam_role.local_role.arn
    username = local.rolename
    groups   = ["system:masters"]
    }, {
    # Did it this way because of circular dependencies
    rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.cluster.eks_cluster_id}-cloud9"
    username = "cloud9"
    groups   = ["system:masters"]
  }]
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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

resource "aws_iam_role_policy_attachment" "local_role" {
  role       = aws_iam_role.local_role.name
  policy_arn = aws_iam_policy.local_policy.arn
}

locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.id
  }

  prefix   = "eks-workshop"
  rolename = join("-", [local.prefix, local.tags.env, "role"])
}

resource "aws_iam_policy" "local_policy" {
  name        = aws_iam_role.local_role.name
  path        = "/"
  description = "Policy for EKS Workshop local environment to access AWS services"

  policy = templatefile("${path.module}/local/iam_policy.json", {
    cluster_name = module.cluster.eks_cluster_id,
    cluster_arn  = module.cluster.eks_cluster_arn,
    nodegroup    = module.cluster.eks_cluster_nodegroup,
    region       = data.aws_region.current.name
  })
}
