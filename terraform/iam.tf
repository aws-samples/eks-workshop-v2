resource "aws_iam_role" "local_role" {
  name = local.shell_role_name

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

resource "aws_iam_policy" "local_policy" {
  name        = aws_iam_role.local_role.name
  path        = "/"
  description = "Policy for EKS Workshop local environment to access AWS services"

  policy = templatefile("${path.module}/templates/iam_policy.json", {
    cluster_name = module.cluster.eks_cluster_id,
    cluster_arn  = module.cluster.eks_cluster_arn,
    nodegroup    = module.cluster.eks_cluster_nodegroup,
    region       = data.aws_region.current.name
    account_id   = data.aws_caller_identity.current.account_id
  })
}
