
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
            "Resource": "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.addon_context.eks_cluster_id}-fsxn-password-secret"
        }
    ]
    })
    depends_on = [ module.preprovision ]
}

module "iam_iam-role-for-service-accounts-eks" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.37.1"

  role_name              = "${var.addon_context.eks_cluster_id}-fsxn-csi-${random_string.suffix.result}"
  allow_self_assume_role = true

  oidc_providers = {
    eks = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]
    }
  }

  role_policy_arns = {
    additional           = aws_iam_policy.fsxn-csi-policy.arn
  }

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