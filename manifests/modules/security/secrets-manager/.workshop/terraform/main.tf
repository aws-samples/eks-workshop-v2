data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_secrets_store_csi_driver = true

  secrets_store_csi_driver = {
    chart_version = "1.3.4"

    set = [{
      name  = "syncSecret.enabled"
      value = true
      },
      {
        name  = "enableSecretRotation"
        value = true
    }]

    wait = true
  }

  enable_secrets_store_csi_driver_provider_aws = true

  secrets_store_csi_driver_provider_aws = {
    chart_version = "0.3.4"

    wait = true
  }

  enable_external_secrets = true

  external_secrets = {
    chart_version = "0.9.5"

    role_name   = "${var.addon_context.eks_cluster_id}-ext-secrets"
    policy_name = "${var.addon_context.eks_cluster_id}-ext-secrets"

    wait = true
  }

  observability_tag = null
}

module "secrets_manager_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix   = "${var.eks_cluster_id}-secrets-"
  policy_name_prefix = "${var.eks_cluster_id}-secrets-"

  role_policy_arns = {
    policy = aws_iam_policy.secrets_manager.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.addon_context.eks_oidc_issuer_url}"
      namespace_service_accounts = ["catalog:catalog"]
    }
  }

  tags = var.tags
}

resource "aws_iam_policy" "secrets_manager" {
  name_prefix = "${var.eks_cluster_id}-secrets-manager-"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:${data.aws_partition.current.partition}:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
    }
  ]
}
POLICY
}
