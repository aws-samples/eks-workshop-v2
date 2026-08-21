resource "aws_iam_policy" "fsxn-csi-policy" {
  name        = "${var.addon_context.eks_cluster_id}-fsxn-csi-${random_string.suffix.result}"
  description = "FSxN CSI Driver Policy"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "fsx:DescribeFileSystems",
          "fsx:DescribeVolumes",
          "fsx:CreateVolume",
          "fsx:RestoreVolumeFromSnapshot",
          "fsx:DescribeStorageVirtualMachines",
          "fsx:UntagResource",
          "fsx:UpdateVolume",
          "fsx:TagResource",
          "fsx:DeleteVolume"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "secretsmanager:GetSecretValue",
        "Resource" : "${data.aws_secretsmanager_secret.fsxn_password_secret.arn}"
      }
    ]
  })
}

data "aws_secretsmanager_secret" "fsxn_password_secret" {
  name       = "${var.addon_context.eks_cluster_id}-fsxn-secret"
  depends_on = [module.preprovision]
}

resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name                = var.eks_cluster_id
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = "v1.3.4-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "fsxn-csi-role" {
  name               = "${var.addon_context.eks_cluster_id}-fsxn-csi-${random_string.suffix.result}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "fsxn-csi-policy-attachment" {
  policy_arn = aws_iam_policy.fsxn-csi-policy.arn
  role       = aws_iam_role.fsxn-csi-role.name
}

resource "aws_eks_pod_identity_association" "fsxn-csi-pod-identity-association" {
  cluster_name    = var.addon_context.eks_cluster_id
  namespace       = local.k8s_service_account_namespace
  service_account = local.k8s_service_account_name
  role_arn        = aws_iam_role.fsxn-csi-role.arn
}


resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  k8s_service_account_namespace = "trident"
  k8s_service_account_name      = "trident-controller"
}


module "preprovision" {
  source = "./preprovision"
  count  = var.resources_precreated ? 0 : 1

  eks_cluster_id = var.eks_cluster_id
  tags           = var.tags
}

# The lab's final step and its placeholder test hook both read the ui-nlb
# Service to fetch the image over HTTP, so the load balancer controller and
# the Service have to exist here as they do in the other storage modules.
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
