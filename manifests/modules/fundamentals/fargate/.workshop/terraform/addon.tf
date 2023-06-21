resource "aws_eks_fargate_profile" "checkout" {
  cluster_name           = local.addon_context.eks_cluster_id
  fargate_profile_name   = "checkout-profile"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = data.aws_subnets.private.ids

  selector {
    namespace = "checkout"

    labels = {
      fargate = "yes"
    }
  }
}

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }
}

data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

data "aws_iam_policy_document" "fargate_assume_role_policy" {
  statement {
    sid = "EKSFargateAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fargate" {
  name                  = "${local.addon_context.eks_cluster_id}-fargate"
  description           = "EKS Fargate IAM Role"
  assume_role_policy    = data.aws_iam_policy_document.fargate_assume_role_policy.json
  force_detach_policies = true
  tags                  = local.tags
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution_role_policy" {
  policy_arn = "arn:${local.addon_context.aws_partition_id}:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}

data "aws_iam_policy_document" "cwlogs" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
  }
}

resource "aws_iam_policy" "cwlogs" {
  name        = "${local.addon_context.eks_cluster_id}-fargate-cwlogs"
  description = "Allow fargate profiles to write logs to CloudWatch"
  policy      = data.aws_iam_policy_document.cwlogs.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "cwlogs" {
  policy_arn = aws_iam_policy.cwlogs.arn
  role       = aws_iam_role.fargate.name
}
