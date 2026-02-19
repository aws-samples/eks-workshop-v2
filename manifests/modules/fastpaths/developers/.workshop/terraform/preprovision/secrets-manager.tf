# Secrets Store CSI Driver via Helm (Pod Identity compatible)
resource "helm_release" "secrets_store_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.3.4"
  provider   = helm.auto_mode

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }
  set {
    name  = "enableSecretRotation"
    value = "true"
  }
}

# AWS Secrets Store CSI Driver Provider via Helm
resource "helm_release" "secrets_store_csi_driver_provider_aws" {
  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = "2.1.1"
  provider   = helm.auto_mode

  set {
    name  = "secrets-store-csi-driver.install"
    value = "false"
  }

  depends_on = [
    helm_release.secrets_store_csi_driver
  ]
}

# External Secrets Operator via Helm
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets"
  version    = "0.14.4"
  provider   = helm.auto_mode

  create_namespace = true

  set {
    name  = "serviceAccount.name"
    value = local.external_secrets_sa # To be consistent with the auto-generated one with IRSA
  }
}

# IAM role for Secrets Manager access using Pod Identity
resource "aws_iam_role" "secrets_manager_role" {
  name_prefix = "${var.eks_cluster_auto_id}-secrets-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# IAM policy for Secrets Manager access (keeping same permissions)
resource "aws_iam_policy" "secrets_manager" {
  name_prefix = "${var.eks_cluster_auto_id}-secrets-manager-"
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
      "Resource": "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:${data.aws_partition.current.partition}:kms:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:key/*"
    }
  ]
}
POLICY
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "secrets_manager_role_policy" {
  policy_arn = aws_iam_policy.secrets_manager.arn
  role       = aws_iam_role.secrets_manager_role.name
}

# Pod Identity Association for catalog service account
resource "aws_eks_pod_identity_association" "secrets_manager_role" {
  cluster_name    = var.eks_cluster_auto_id
  namespace       = "catalog"
  service_account = "catalog"
  role_arn        = aws_iam_role.secrets_manager_role.arn

  depends_on = [
    aws_iam_role.secrets_manager_role
  ]
}

locals {
  external_secrets_namespace = "external-secrets"
  external_secrets_sa        = "external-secrets-sa"
}

# IAM role for Secrets Manager access using Pod Identity
resource "aws_iam_role" "external_secrets" {
  name_prefix = "${var.eks_cluster_auto_id}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# IAM policy for Secrets Manager access (keeping same permissions)
resource "aws_iam_policy" "external_secrets" {
  name_prefix = "${var.eks_cluster_auto_id}-secrets-manager-"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds"
      ],
      "Resource": "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:${data.aws_partition.current.partition}:kms:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:key/*"
    }
  ]
}
POLICY
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "external_secrets" {
  policy_arn = aws_iam_policy.external_secrets.arn
  role       = aws_iam_role.external_secrets.name
}

# Pod Identity Association for role
resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = var.eks_cluster_auto_id
  namespace       = local.external_secrets_namespace
  service_account = local.external_secrets_sa
  role_arn        = aws_iam_role.external_secrets.arn
}
