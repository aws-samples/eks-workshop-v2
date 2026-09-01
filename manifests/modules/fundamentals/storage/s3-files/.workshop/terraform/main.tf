# IAM role (IRSA) for the EFS CSI driver *controller* service account
# (kube-system:efs-csi-controller-sa). For S3 Files the controller requires the
# AmazonS3FilesCSIDriverPolicy and AmazonS3FilesClientFullAccess managed policies.
module "s3_files_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix   = "${var.addon_context.eks_cluster_id}-s3files-csi-"
  policy_name_prefix = "${var.addon_context.eks_cluster_id}-s3files-csi-"

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

# Managed policies required by the EFS CSI *controller* for S3 Files.
locals {
  s3_files_controller_policy_arns = {
    csi_driver  = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonS3FilesCSIDriverPolicy"
    client_full = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonS3FilesClientFullAccess"
  }
}

resource "aws_iam_role_policy_attachment" "s3_files_controller" {
  for_each = local.s3_files_controller_policy_arns

  role       = module.s3_files_csi_driver_irsa.iam_role_name
  policy_arn = each.value
}

# Resolve the worker node instance role(s) dynamically from the cluster's EKS
# managed node groups. The role name is not stable across environments (for
# example, eksctl-created clusters use a generated name with a random suffix),
# so we must look it up rather than hard-coding it.
data "aws_eks_node_groups" "this" {
  cluster_name = var.addon_context.eks_cluster_id
}

data "aws_eks_node_group" "this" {
  for_each = data.aws_eks_node_groups.this.names

  cluster_name    = var.addon_context.eks_cluster_id
  node_group_name = each.value
}

locals {
  # Distinct node instance role names across all managed node groups, derived
  # from each node group's node_role_arn (arn:aws:iam::<acct>:role/<name>).
  s3_files_node_role_names = toset([
    for ng in data.aws_eks_node_group.this : split("/", ng.node_role_arn)[1]
  ])

  # The EFS CSI node daemonset (kube-system:efs-csi-node-sa) uses the worker
  # node instance role to mount and stream S3 Files volumes. Attach the required
  # managed policies to every node role, keyed by "<role>:<policy>".
  s3_files_node_attachments = {
    for pair in setproduct(local.s3_files_node_role_names, [
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonS3FilesClientFullAccess",
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonS3ReadOnlyAccess",
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonElasticFileSystemsUtils",
      ]) : "${pair[0]}:${pair[1]}" => {
      role       = pair[0]
      policy_arn = pair[1]
    }
  }
}

resource "aws_iam_role_policy_attachment" "s3_files_node" {
  for_each = local.s3_files_node_attachments

  role       = each.value.role
  policy_arn = each.value.policy_arn
}

data "aws_partition" "current" {}

module "preprovision" {
  source = "./preprovision"
  count  = var.resources_precreated ? 0 : 1

  eks_cluster_id = var.eks_cluster_id
  tags           = var.tags
}

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
