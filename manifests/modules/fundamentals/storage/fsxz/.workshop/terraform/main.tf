# Create FSxZ OIDC providers
module "fsxz_oidc_providers" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

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

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.selected_fsxz.id
  name   = "default"
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

resource "aws_security_group_rule" "fsxz-tcp2049-default-sg" {
  description              = "FSxZ TCP port 2049 rule from default SG"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsxz_sg.id
  source_security_group_id = data.aws_security_group.default.id
  type                     = "ingress"
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
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-fsxz"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = ["arn:aws:iam::aws:policy/AmazonFSxFullAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:fsx-openzfs-csi-controller-sa"]

  tags = var.tags
}

module "fsx_openzfs" {
  source     = "terraform-aws-modules/fsx/aws//modules/openzfs"
  depends_on = [module.iam_assumable_role_fsx, aws_security_group.fsxz_sg, aws_security_group_rule.fsxz-tcp2049-default-sg]
  name       = "${var.eks_cluster_id}-FSxZ"

  # File system
  automatic_backup_retention_days = 0
  copy_tags_to_volumes            = true
  copy_tags_to_backups            = true
  deployment_type                 = "SINGLE_AZ_2"
  create_security_group           = false
  skip_final_backup               = true
  storage_capacity                = 128
  storage_type                    = "SSD"
  subnet_ids                      = [data.aws_subnet.private_fsxz.id]
  throughput_capacity             = 160
  security_group_ids              = [aws_security_group.fsxz_sg.id]

  root_volume_configuration = {
    data_compression_type = "LZ4"
    record_size_kib       = 128
    nfs_exports = {
      client_configurations = [
        {
          clients = data.aws_vpc.selected_fsxz.cidr_block
          options = ["sync", "rw"]
        }
      ]
    }
  }
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

resource "time_sleep" "wait" {
  depends_on = [module.eks_blueprints_addons]

  create_duration = "10s"
}

resource "kubernetes_manifest" "ui_nlb" {
  depends_on = [module.eks_blueprints_addons]

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "name"      = "ui-nlb"
      "namespace" = "ui"
      "annotations" = {
        "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
        "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
      }
    }
    "spec" = {
      "type" = "LoadBalancer"
      "ports" = [{
        "port"       = 80
        "targetPort" = 8080
        "name"       = "http"
      }]
      "selector" = {
        "app.kubernetes.io/name"      = "ui"
        "app.kubernetes.io/instance"  = "ui"
        "app.kubernetes.io/component" = "service"
      }
    }
  }
}
