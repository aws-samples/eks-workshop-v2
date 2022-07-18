module "cluster" {
  source = "../modules/cluster"

  id = var.id

  map_roles = [{
    rolearn  = aws_iam_role.local_role.arn
    username = "eks-workshop-dev-local"
    groups   = ["system:masters"]
  }]
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "local_role" {
  name = "eks-workshop-dev-local"

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
}

resource "aws_iam_role_policy_attachment" "local_role" {
  role       = aws_iam_role.local_role.name
  policy_arn = aws_iam_policy.local_policy.arn
}

data "template_file" "iam_policy" {
  template = file("${path.module}/iam_policy.json")
  vars = {
    cluster_arn = module.cluster.eks_cluster_arn
    nodegroup = module.cluster.eks_cluster_nodegroup
  }
}

resource "aws_iam_policy" "local_policy" {
  name        = "eks-workshop-dev-local"
  path        = "/"
  description = "Policy for EKS Workshop local environment to access AWS services"

  policy = data.template_file.iam_policy.rendered
}