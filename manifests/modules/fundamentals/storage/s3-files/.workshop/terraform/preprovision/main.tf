data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }
}

data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

# S3 bucket with versioning (required for S3 Files)
resource "aws_s3_bucket" "s3_files" {
  bucket_prefix = "${var.eks_cluster_id}-s3-files-"
  force_destroy = true

  tags = merge(
    var.tags,
    {
      Name = "${var.eks_cluster_id}-s3-files"
    }
  )
}

resource "aws_s3_bucket_versioning" "s3_files" {
  bucket = aws_s3_bucket.s3_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Security group for S3 Files mount targets (NFS port 2049)
resource "aws_security_group" "s3_files" {
  name        = "${var.eks_cluster_id}-s3-files"
  description = "S3 Files security group allow access to port 2049"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "allow inbound NFS traffic"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.eks_cluster_id}-s3-files-sg"
    }
  )
}

# IAM role for S3 Files to access the bucket
resource "aws_iam_role" "s3_files" {
  name_prefix = "${var.eks_cluster_id}-s3files-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3FilesAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticfilesystem.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:s3files:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:file-system/*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "s3_files" {
  name_prefix = "${var.eks_cluster_id}-s3files-"
  role        = aws_iam_role.s3_files.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ]
        Resource = aws_s3_bucket.s3_files.arn
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "S3ObjectPermissions"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject*",
          "s3:GetObject*",
          "s3:List*",
          "s3:PutObject*"
        ]
        Resource = "${aws_s3_bucket.s3_files.arn}/*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "EventBridgeManage"
        Effect = "Allow"
        Action = [
          "events:DeleteRule",
          "events:DisableRule",
          "events:EnableRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets"
        ]
        Condition = {
          StringEquals = {
            "events:ManagedBy" = "elasticfilesystem.amazonaws.com"
          }
        }
        Resource = ["arn:${data.aws_partition.current.partition}:events:*:*:rule/DO-NOT-DELETE-S3-Files*"]
      },
      {
        Sid    = "EventBridgeRead"
        Effect = "Allow"
        Action = [
          "events:DescribeRule",
          "events:ListRuleNamesByTarget",
          "events:ListRules",
          "events:ListTargetsByRule"
        ]
        Resource = ["arn:${data.aws_partition.current.partition}:events:*:*:rule/*"]
      }
    ]
  })
}

# Create the S3 file system
resource "aws_s3files_file_system" "assets" {
  bucket   = aws_s3_bucket.s3_files.arn
  role_arn = aws_iam_role.s3_files.arn

  # Versioning must be enabled before the file system is created, and the
  # file system must be deleted before versioning is modified on destroy
  # (S3 rejects versioning changes while a file system is attached).
  depends_on = [aws_s3_bucket_versioning.s3_files]

  tags = merge(
    var.tags,
    {
      Name = "${var.eks_cluster_id}-s3-files-assets"
    }
  )
}

# Create mount targets in each private subnet
resource "aws_s3files_mount_target" "assets" {
  count = length(data.aws_subnets.private.ids)

  file_system_id  = aws_s3files_file_system.assets.id
  subnet_id       = data.aws_subnets.private.ids[count.index]
  security_groups = [aws_security_group.s3_files.id]
}

output "s3_file_system_id" {
  value = aws_s3files_file_system.assets.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.s3_files.id
}
