# Attach AmazonFSxFullAccess managed policy
resource "aws_iam_role_policy_attachment" "fsx_full_access" {
  role       = "eks-workshop-ide-role"
  policy_arn = "arn:aws:iam::aws:policy/AmazonFSxFullAccess"
}

# Add after the policy attachment
resource "time_sleep" "wait_for_policy_propagation" {
  depends_on = [aws_iam_role_policy_attachment.fsx_full_access]
  create_duration = "30s"  # reduce to minimum amount possible
}

# Add Service_Linked_Role inline policy
resource "aws_iam_role_policy" "service_linked_role" {
  name = "Service_Linked_Role"
  role = "eks-workshop-ide-role"

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceLinkedRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy"
      ],
      "Resource": "arn:aws:iam::*:role/aws-service-role/s3.data-source.lustre.fsx.amazonaws.com/*"
    }
  }
  EOF
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_vpc" "selected_fsx" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }
}

data "aws_subnets" "private_fsx" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Public*"]
  }
}

resource "aws_security_group" "fsx_lustre" {
  name        = "${var.eks_cluster_id}-fsx-lustre"
  description = "FSx for Lustre security group to allow access on required ports"
  vpc_id      = data.aws_vpc.selected_fsx.id

  ingress {
    description = "Allow inbound traffic for Lustre"
    from_port   = 988
    to_port     = 988
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_fsx.cidr_block]
  }

  ingress {
    description = "Allow inbound traffic for Lustre (UDP)"
    from_port   = 988
    to_port     = 988
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.selected_fsx.cidr_block]
  }

  ingress {
    description = "Allow inbound traffic for Lustre data"
    from_port   = 1018
    to_port     = 1023
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_fsx.cidr_block]
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
      Name = "${var.eks_cluster_id}-fsxlustresecuritygroup"
    }
  )
}

# Create S3 bucket to initially put images in
resource "aws_s3_bucket" "s3_data" {

  bucket_prefix = "${var.addon_context.eks_cluster_id}-s3-data"
  force_destroy = true
}

resource "aws_fsx_lustre_file_system" "fsx_lustre" {
  depends_on = [time_sleep.wait_for_policy_propagation]
  import_path      = "s3://${aws_s3_bucket.s3_data.bucket}"
  storage_capacity = 1200
  subnet_ids       = [data.aws_subnets.private_fsx.ids[1]]
  auto_import_policy = "NEW_CHANGED"
  security_group_ids = [aws_security_group.fsx_lustre.id] 

  # Additional recommended settings
  file_system_type_version = "2.12"
  deployment_type = "SCRATCH_2"
  storage_type = "SSD"
}

resource "aws_iam_role_policy" "eks_workshop_ide_s3_put_access" {
  name = "eks-workshop-ide-s3-put-access"
  role = "eks-workshop-ide-role"

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "${aws_s3_bucket.s3_data.arn}/*"
      }
    ]
  }
  EOF
}

# Create FSx CSI Driver IAM Role and associated policy
module "fsx_lustre_csi_driver_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name_prefix = "${var.addon_context.eks_cluster_id}-fsx-lustre-csi-"
  policy_name_prefix = "${var.addon_context.eks_cluster_id}-fsx-lustre-csi-"

  # IAM policy to attach to driver
  attach_fsx_lustre_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:fsx-csi-controller-sa"]
    }
  }
}