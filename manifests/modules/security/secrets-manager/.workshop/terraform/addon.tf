module "secrets-store-csi-driver" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.1//modules/kubernetes-addons/secrets-store-csi-driver"

  helm_config = {
    version = "1.3.4"
    set = [{
      name  = "syncSecret.enabled"
      value = true
      },
      {
        name  = "enableSecretRotation"
        value = true
    }]
  }

  addon_context = local.addon_context
}

module "secrets_store_csi_driver_provider_aws" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.1//modules/kubernetes-addons/csi-secrets-store-provider-aws"

  helm_config = {
    version = "0.3.4"
  }

  addon_context = local.addon_context
}

module "external_secrets" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.1//modules/kubernetes-addons/external-secrets"

  helm_config = {
    version = "0.9.5"
  }

  addon_context = local.addon_context
}

module "secrets_manager_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name_prefix = "${data.aws_eks_cluster.eks_cluster.id}-secrets-"

  role_policy_arns = {
    policy = aws_iam_policy.secrets_manager.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"
      namespace_service_accounts = ["catalog:catalog"]
    }
  }

  tags = local.tags
}

resource "aws_iam_policy" "secrets_manager" {
  name_prefix = "${data.aws_eks_cluster.eks_cluster.id}-secrets-manager-"
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

output "environment" {
  value = <<EOF
export CATALOG_IAM_ROLE="${module.secrets_manager_role.iam_role_arn}"
EOF
}
