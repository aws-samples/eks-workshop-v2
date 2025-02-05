
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_policy" "fsxn-csi-policy" {
  name        = "${var.addon_context.eks_cluster_id}-fsxn-csi-${random_string.suffix.result}"
  description = "FSxN CSI Driver Policy"


  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
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
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${data.aws_secretsmanager_secret.fsxn_password_secret.arn}"
        }
    ]
    })
}

data "aws_secretsmanager_secret" "fsxn_password_secret" {
  name = "${var.addon_context.eks_cluster_id}-fsxn-secret"
  depends_on = [ module.preprovision ]
}
# module "iam_iam-role-for-service-accounts-eks" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.37.1"

#   role_name              = "${var.addon_context.eks_cluster_id}-fsxn-csi-${random_string.suffix.result}"
#   allow_self_assume_role = true

#   oidc_providers = {
#     eks = {
#       provider_arn               = var.addon_context.eks_oidc_provider_arn
#       namespace_service_accounts = ["${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]
#     }
#   }

#   role_policy_arns = {
#     additional           = aws_iam_policy.fsxn-csi-policy.arn
#   }

# }

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
  random_string  = random_string.suffix.result
}