data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }
}

data "aws_subnet" "private_fsxl" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    Name = "*Private*A"
  }
}

# IAM role for FSx for Lustre CSI driver
module "iam_assumable_role_fsx_lustre" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "6.8.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-fsxl"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = ["arn:aws:iam::aws:policy/AmazonFSxFullAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:fsx-csi-controller-sa"]

  tags = var.tags
}

# Security group for FSx for Lustre
resource "aws_security_group" "fsxl_sg" {
  name        = "${var.eks_cluster_id}-fsxl"
  description = "FSx for Lustre security group"
  vpc_id      = data.aws_vpc.selected.id

  tags = merge(
    var.tags,
    {
      Name = "${var.eks_cluster_id}-fsxl-sg"
    }
  )
}

resource "aws_security_group_rule" "fsxl_ingress_988" {
  description       = "Lustre TCP port 988"
  from_port         = 988
  to_port           = 988
  protocol          = "tcp"
  security_group_id = aws_security_group.fsxl_sg.id
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
}

resource "aws_security_group_rule" "fsxl_ingress_1018_1023" {
  description       = "Lustre TCP ports 1018-1023"
  from_port         = 1018
  to_port           = 1023
  protocol          = "tcp"
  security_group_id = aws_security_group.fsxl_sg.id
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
}

resource "aws_security_group_rule" "fsxl_egress" {
  description       = "FSx for Lustre egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.fsxl_sg.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# FSx for Lustre file system
resource "aws_fsx_lustre_file_system" "this" {
  storage_capacity            = 1200
  subnet_ids                  = [data.aws_subnet.private_fsxl.id]
  security_group_ids          = [aws_security_group.fsxl_sg.id]
  deployment_type             = "PERSISTENT_2"
  per_unit_storage_throughput = 125
  data_compression_type       = "LZ4"

  # The FSx resource only implicitly depends on the security group, not on the
  # separate security_group_rule resources. Without this, Terraform can create
  # the filesystem before the ingress rules exist, causing FSx to reject the
  # request with InvalidNetworkSettings (no Lustre LNET traffic on port 988).
  depends_on = [
    aws_security_group_rule.fsxl_ingress_988,
    aws_security_group_rule.fsxl_ingress_1018_1023,
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.eks_cluster_id}-FSxL"
    }
  )
}

# Load balancer for UI
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.23.0"

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
  depends_on = [time_sleep.wait]

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
        "service.beta.kubernetes.io/load-balancer-source-ranges"       = var.inbound_cidrs
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
