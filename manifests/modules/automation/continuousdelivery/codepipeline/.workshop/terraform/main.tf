data "aws_caller_identity" "current" {}

resource "tls_private_key" "cd" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.cd.private_key_pem
  filename        = "/home/ec2-user/.ssh/cd_ssh.pem"
  file_permission = "0400"
}

output "cd_ecr_url_ui" {
  value       = aws_ecr_repository.ecr_ui.repository_url
  description = "ECR repository Url for UI module"
}

resource "random_string" "ecr_ui_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "aws_ecr_repository" "ecr_ui" {
  name                 = "retail-store-sample-ui-${random_string.ecr_ui_suffix.result}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_s3_bucket" "source_bucket" {
  bucket        = "${var.addon_context.eks_cluster_id}-${data.aws_caller_identity.current.account_id}-retail-store-sample-ui"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.source_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "s3_notify_eventbridge" {
  bucket      = aws_s3_bucket.source_bucket.id
  eventbridge = true
}

resource "aws_cloudwatch_event_rule" "s3_trigger_pipeline" {
  name        = aws_s3_bucket.source_bucket.bucket
  description = "Trigger CodePipeline when a file is uploaded to S3"
  event_pattern = jsonencode({
    source      = ["aws.s3"],
    detail-type = ["Object Created"],
    detail = {
      bucket = {
        name = [aws_s3_bucket.source_bucket.id]
      },
      object = {
        key = ["my-repo/refs/heads/main/repo.zip"]
      }
    }
  })
}

// Terraform does not support all the parameters needed for this pipeline
// So use CloudFormation instead
resource "aws_cloudformation_stack" "eks_workshop_pipeline" {
  name          = "${var.addon_context.eks_cluster_id}-pipeline-stack"
  template_body = file("${path.module}/pipeline.yaml")

  parameters = {
    PipelineName      = "${var.addon_context.eks_cluster_id}-retail-store-cd"
    ServiceRoleArn    = aws_iam_role.codepipeline_role.arn
    ArtifactBucket    = aws_s3_bucket.build_artifact_bucket.bucket
    KMSKeyId          = aws_kms_key.artifact_encryption_key.arn
    SourceBucket      = aws_s3_bucket.source_bucket.bucket
    ECRRepositoryName = aws_ecr_repository.ecr_ui.id
    EKSClusterName    = var.addon_context.eks_cluster_id
  }

  capabilities = ["CAPABILITY_IAM"]
}

locals {
  pipeline_name = aws_cloudformation_stack.eks_workshop_pipeline.outputs["PipelineName"]
  pipeline_arn  = aws_cloudformation_stack.eks_workshop_pipeline.outputs["PipelineArn"]
}

resource "aws_cloudwatch_event_target" "codepipeline_target" {
  rule     = aws_cloudwatch_event_rule.s3_trigger_pipeline.name
  arn      = local.pipeline_arn
  role_arn = aws_iam_role.eventbridge_invoke_pipeline.arn
}

resource "aws_iam_role" "eventbridge_invoke_pipeline" {
  name = "eks-workshop-eventbridge-invoke-codepipeline"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "invoke_pipeline_policy" {
  name = "invoke-codepipeline"
  role = aws_iam_role.eventbridge_invoke_pipeline.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "codepipeline:StartPipelineExecution",
      Resource = local.pipeline_arn
    }]
  })
}

resource "aws_s3_bucket_public_access_block" "source_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.source_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "build_artifact_bucket" {
  bucket_prefix = "${var.addon_context.eks_cluster_id}-artifacts-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "build_artifact_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.build_artifact_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.addon_context.eks_cluster_id}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.source_bucket.arn,
      "${aws_s3_bucket.source_bucket.arn}/*",
      aws_s3_bucket.build_artifact_bucket.arn,
      "${aws_s3_bucket.build_artifact_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:*"
    ]
    resources = [
      aws_ecr_repository.ecr_ui.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "sts:GetServiceBearerToken"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/codepipeline/${var.addon_context.eks_cluster_id}-retail-store-cd",
      "arn:aws:logs:*:*:log-group:/aws/codepipeline/${var.addon_context.eks_cluster_id}-retail-store-cd:log-stream:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.artifact_encryption_key.arn]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.addon_context.eks_cluster_id}-codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

resource "aws_kms_key" "artifact_encryption_key" {
  description             = "artifact-encryption-key"
  deletion_window_in_days = 10
}



module "iam_assumable_role_ui" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-ecr-ui"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.ecr_ui.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:ui:ui"]
}

resource "aws_iam_policy" "ecr_ui" {
  name        = "${var.addon_context.eks_cluster_id}-ecr-ui"
  path        = "/"
  description = "ECR policy for ui application"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllEcrActions",
      "Effect": "Allow",
      "Action": "ecr:*",
      "Resource" : ["${aws_ecr_repository.ecr_ui.arn}"]
    }
  ]
}
EOF
}

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

resource "kubernetes_manifest" "ui_alb" {
  depends_on = [module.eks_blueprints_addons]

  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "name"      = "ui"
      "namespace" = "ui"
      "annotations" = {
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/actuator/health/liveness"
      }
    }
    "spec" = {
      ingressClassName = "alb",
      "rules" = [{
        "http" = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            "backend" = {
              service = {
                name = "ui"
                port = {
                  number = 80
                }
              }
            }
          }]
        }
      }]
    }
  }
}
