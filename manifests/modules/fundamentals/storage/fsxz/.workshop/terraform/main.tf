# Create FSxZ OIDC providers
module "fsxz_oidc_providers" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.54.1"

  # Create prefixes
  role_name_prefix   = "${var.addon_context.eks_cluster_id}-fsxz-csi-"
  policy_name_prefix = "${var.addon_context.eks_cluster_id}-fsxz-csi-"

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:fsxz-csi-controller-sa"]
    }
  }

  tags = var.tags
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "region_current" {}

data "aws_vpc" "selected_fsxz" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }
}

data "aws_subnet" "private_fsxz" {
  vpc_id = data.aws_vpc.selected_fsxz.id

  tags = {
    Name = "*Private*A"
  }
}

# Create the FSxZ Security Group
resource "aws_security_group" "fsxz_sg" {
  name        = "${var.eks_cluster_id}-fsxz"
  description = "FSxZ security group allow access to required ports"
  vpc_id      = data.aws_vpc.selected_fsxz.id

  tags = merge(
    var.tags,
    {
      Name = "${var.eks_cluster_id}-fsxzsecuritygroup"
    }
  )
}

# Create the necessary FSxZ Security Group rules
resource "aws_security_group_rule" "fsxz-tcp111" {
  description       = "FSxZ TCP port 111 rule"
  from_port         = 111
  to_port           = 111
  protocol          = "tcp"
  security_group_id = aws_security_group.fsxz_sg.id
  type              = "ingress"

  cidr_blocks = [data.aws_vpc.selected_fsxz.cidr_block]
}

resource "aws_security_group_rule" "fsxz-udp111" {
  description       = "FSxZ UDP port 111 rule"
  from_port         = 111
  to_port           = 111
  protocol          = "udp"
  security_group_id = aws_security_group.fsxz_sg.id
  type              = "ingress"

  cidr_blocks = [data.aws_vpc.selected_fsxz.cidr_block]
}

resource "aws_security_group_rule" "fsxz-tcp2049" {
  description       = "FSxZ TCP port 2049 rule"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  security_group_id = aws_security_group.fsxz_sg.id
  type              = "ingress"

  cidr_blocks = [data.aws_vpc.selected_fsxz.cidr_block]
}

resource "aws_security_group_rule" "fsxz-udp2049" {
  description       = "FSxZ UDP port 2049 rule"
  from_port         = 2049
  to_port           = 2049
  protocol          = "udp"
  security_group_id = aws_security_group.fsxz_sg.id
  type              = "ingress"

  cidr_blocks = [data.aws_vpc.selected_fsxz.cidr_block]
}

resource "aws_security_group_rule" "fsxz-tcp20001_20003" {
  description       = "FSxZ TCP port 20001-20003 rule"
  from_port         = 20001
  to_port           = 20003
  protocol          = "tcp"
  security_group_id = aws_security_group.fsxz_sg.id
  type              = "ingress"

  cidr_blocks = [data.aws_vpc.selected_fsxz.cidr_block]
}

resource "aws_security_group_rule" "fsxz-udp20001_20003" {
  description       = "FSxZ UDP port 20001-20003 rule"
  from_port         = 20001
  to_port           = 20003
  protocol          = "udp"
  security_group_id = aws_security_group.fsxz_sg.id
  type              = "ingress"

  cidr_blocks = [data.aws_vpc.selected_fsxz.cidr_block]
}

resource "aws_security_group_rule" "fsxz_egress" {
  description       = "FSxZ egress rule"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.fsxz_sg.id
  type              = "egress"

  cidr_blocks = ["0.0.0.0/0"]
}

module "iam_assumable_role_fsx" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.54.1"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-fsxz"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = ["arn:aws:iam::aws:policy/AmazonFSxFullAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:fsx-openzfs-csi-controller-sa"]

  tags = var.tags
}
