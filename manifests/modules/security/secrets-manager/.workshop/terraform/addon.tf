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

  role_name_prefix = "${data.aws_eks_cluster.eks_cluster.id}-secrets-manager-"

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

resource "kubernetes_annotations" "catalog-sa" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = "catalog"
    namespace = "catalog"
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = "${module.secrets_manager_role.iam_role_arn}"
  }
  force = true
}

resource "kubectl_manifest" "cluster_secretstore" {
  yaml_body  = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: "cluster-secret-store"
spec:
  provider:
    aws:
      service: SecretsManager
      region: "${data.aws_region.current.name}"
      auth:
        jwt:
          serviceAccountRef:
            name: "external-secrets-sa"
            namespace: "external-secrets"
YAML
  depends_on = [module.external_secrets]
}