resource "aws_codecommit_repository" "gitops" {
  repository_name = "${var.addon_context.eks_cluster_id}-gitops"
  description     = "CodeCommit repository for GitOps"
}

resource "aws_iam_user" "gitops" {
  name = "${var.addon_context.eks_cluster_id}-gitops"
  path = "/"
}

resource "aws_iam_user_ssh_key" "gitops" {
  username   = aws_iam_user.gitops.name
  encoding   = "SSH"
  public_key = tls_private_key.gitops.public_key_openssh
}

resource "tls_private_key" "gitops" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "aws_iam_policy_document" "gitops_access" {
  statement {
    sid = ""
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush"
    ]
    effect    = "Allow"
    resources = [aws_codecommit_repository.gitops.arn]
  }
}

resource "aws_iam_policy" "gitops_access" {
  name   = "${var.addon_context.eks_cluster_id}-gitops"
  path   = "/"
  policy = data.aws_iam_policy_document.gitops_access.json
}

resource "aws_iam_user_policy_attachment" "gitops_access" {
  user       = aws_iam_user.gitops.name
  policy_arn = aws_iam_policy.gitops_access.arn
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.gitops.private_key_pem
  filename        = "/home/ec2-user/.ssh/gitops_ssh.pem"
  file_permission = "0400"
}

resource "local_file" "ssh_config" {
  content         = <<EOF
Host git-codecommit.*.amazonaws.com
  User ${aws_iam_user.gitops.unique_id}
  IdentityFile ~/.ssh/gitops_ssh.pem
EOF
  filename        = "/home/ec2-user/.ssh/config"
  file_permission = "0600"
}

## CI to Flux

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.selected.id

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

output "gitops_ecr_url_ui" {
  value       = aws_ecr_repository.ecr_ui.repository_url
  description = "ECR repository Url for UI module"
}

resource "aws_codecommit_repository" "codecommit_retail_store_sample" {
  repository_name = "${var.addon_context.eks_cluster_id}-retail-store-sample"
  description     = "CodeCommit repository for retail-store-sample"
}

data "aws_iam_policy_document" "ci_access" {
  statement {
    sid = ""
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush"
    ]
    effect = "Allow"
    resources = [
      aws_codecommit_repository.codecommit_retail_store_sample.arn
    ]
  }
}

resource "aws_iam_policy" "ci_access" {
  name   = "${var.addon_context.eks_cluster_id}-ci-access"
  path   = "/"
  policy = data.aws_iam_policy_document.ci_access.json
}

resource "aws_iam_user_policy_attachment" "ci_access" {
  user       = aws_iam_user.gitops.name
  policy_arn = aws_iam_policy.ci_access.arn
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

# CodePipeline dependencies

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
      aws_s3_bucket.build_artifact_bucket.arn,
      "${aws_s3_bucket.build_artifact_bucket.arn}/*"
    ]
  }

  statement {
    actions = [
      "codecommit:*",
    ]
    effect    = "Allow"
    resources = [aws_codecommit_repository.codecommit_retail_store_sample.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = [aws_codebuild_project.codebuild_amd64.arn,
      aws_codebuild_project.codebuild_arm64.arn,
      aws_codebuild_project.codebuild_manifest.arn
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

# CodeBuild dependencies

resource "aws_iam_role" "codebuild_role" {
  name = "${var.addon_context.eks_cluster_id}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "codebuild_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["ecr:*"]
          Resource = [aws_ecr_repository.ecr_ui.arn]
        },
        {
          Effect   = "Allow"
          Action   = ["ecr:GetAuthorizationToken"]
          Resource = ["*"]
        },
        {
          Effect   = "Allow"
          Action   = ["ec2:Describe*"]
          Resource = ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObjectAcl",
            "s3:PutObject"
          ]
          Resource = [
            aws_s3_bucket.build_artifact_bucket.arn,
            "${aws_s3_bucket.build_artifact_bucket.arn}/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs",
            "ec2:CreateNetworkInterfacePermission"
          ]
          Resource = ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "kms:DescribeKey",
            "kms:GenerateDataKey*",
            "kms:Encrypt",
            "kms:ReEncrypt*",
            "kms:Decrypt"
          ]
          Resource = [aws_kms_key.artifact_encryption_key.arn]
        }
      ]
    })
  }
}

resource "aws_kms_key" "artifact_encryption_key" {
  description             = "artifact-encryption-key"
  deletion_window_in_days = 10
}

resource "aws_codebuild_project" "codebuild_amd64" {
  name           = "${var.addon_context.eks_cluster_id}-retail-store-sample-amd64"
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.artifact_encryption_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    privileged_mode = true
    type            = "LINUX_CONTAINER"

    environment_variable {
      name  = "ECR_URI"
      value = aws_ecr_repository.ecr_ui.repository_url
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest-amd64"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  vpc_config {
    vpc_id             = data.aws_vpc.selected.id
    subnets            = data.aws_subnets.private.ids
    security_group_ids = [data.aws_security_group.default.id]
  }
}

resource "aws_codebuild_project" "codebuild_arm64" {
  name           = "${var.addon_context.eks_cluster_id}-retail-store-sample-arm64"
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.artifact_encryption_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    privileged_mode = true
    type            = "ARM_CONTAINER"

    environment_variable {
      name  = "ECR_URI"
      value = aws_ecr_repository.ecr_ui.repository_url
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest-arm64"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  vpc_config {
    vpc_id             = data.aws_vpc.selected.id
    subnets            = data.aws_subnets.private.ids
    security_group_ids = [data.aws_security_group.default.id]
  }
}

resource "aws_codebuild_project" "codebuild_manifest" {
  name           = "${var.addon_context.eks_cluster_id}-retail-store-sample-manifest"
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.artifact_encryption_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    privileged_mode = true
    type            = "LINUX_CONTAINER"

    environment_variable {
      name  = "ECR_URI"
      value = aws_ecr_repository.ecr_ui.repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-manifest.yml"
  }

  vpc_config {
    vpc_id             = data.aws_vpc.selected.id
    subnets            = data.aws_subnets.private.ids
    security_group_ids = [data.aws_security_group.default.id]
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = "${var.addon_context.eks_cluster_id}-retail-store-sample"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.build_artifact_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.artifact_encryption_key.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        RepositoryName = aws_codecommit_repository.codecommit_retail_store_sample.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "build_amd64"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source"]
      version         = "1"
      run_order       = 1

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_amd64.name
      }
    }

    action {
      name            = "build_arm64"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source"]
      version         = "1"
      run_order       = 1

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_arm64.name
      }
    }
    action {
      name            = "build-manifest"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source"]
      version         = "1"
      run_order       = 2

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_manifest.name
      }
    }
  }
}

module "iam_assumable_role_ui" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.54.1"
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
  version = "1.21.0"

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
