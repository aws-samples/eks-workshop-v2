resource "random_string" "fluentbit_log_group" {
  length  = 6
  special = false
}

locals {
  cw_log_group_name = "/${var.eks_cluster_auto_id}/worker-fluentbit-logs-${random_string.fluentbit_log_group.result}"
}

# Create CloudWatch log group for FluentBit
resource "aws_cloudwatch_log_group" "fluentbit" {
  name              = local.cw_log_group_name
  retention_in_days = 7
  tags              = var.tags
}

# IAM role for FluentBit with CloudWatch write permissions using Pod Identity
resource "aws_iam_role" "auto_fluentbit" {
  name_prefix = "${var.eks_cluster_auto_id}-fluent-bit-"

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

  tags = var.tags
}

# IAM policy for FluentBit CloudWatch log write access
resource "aws_iam_policy" "auto_fluentbit_cloudwatch" {
  name_prefix = "${var.eks_cluster_auto_id}-fluent-bit-"
  description = "CloudWatch Logs policy for FluentBit"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.eks_cluster_auto_id}/*"
      }
    ]
  })

  tags = var.tags
}

# Attach CloudWatch policy to FluentBit role
resource "aws_iam_role_policy_attachment" "auto_fluentbit_cloudwatch" {
  policy_arn = aws_iam_policy.auto_fluentbit_cloudwatch.arn
  role       = aws_iam_role.auto_fluentbit.name
}

# EKS Pod Identity Association for FluentBit
resource "aws_eks_pod_identity_association" "fluentbit" {
  cluster_name    = var.eks_cluster_auto_id
  namespace       = "amazon-cloudwatch"
  service_account = "fluent-bit"
  role_arn        = aws_iam_role.auto_fluentbit.arn

  depends_on = [
    aws_iam_role.auto_fluentbit
  ]
}

# Helm release for AWS for FluentBit (Pod Identity compatible)
resource "helm_release" "aws_for_fluent_bit" {
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  namespace  = "amazon-cloudwatch"
  version    = "0.1.32"
  provider   = helm.auto_mode

  create_namespace = true

  set {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.auto_fluentbit.arn
    }
  set {
      name  = "cloudWatchLogs.enabled"
      value = "true"
    }
  set {
      name  = "cloudWatchLogs.region"
      value = data.aws_region.current.id
  }
  set {
      name  = "cloudWatchLogs.logGroupName"
      value = aws_cloudwatch_log_group.fluentbit.name
  }
  set {
      name  = "firehose.enabled"
      value = "false"
  }
  set {
      name  = "kinesis.enabled"
      value = "false"
  }

  depends_on = [
    aws_cloudwatch_log_group.fluentbit,
    aws_eks_pod_identity_association.fluentbit
  ]
}

output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CLOUDWATCH_LOG_GROUP_NAME = aws_cloudwatch_log_group.fluentbit.name
  }
}