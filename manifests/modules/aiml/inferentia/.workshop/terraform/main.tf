locals {
  namespace = "kube-system"
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

# Pod identity for Karpenter

resource "aws_eks_addon" "pod_identity" {
  cluster_name                = var.addon_context.eks_cluster_id
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve                    = false
}

# Karpenter controller & Node IAM roles, SQS Queue, Eventbridge Rules

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.1.5"

  cluster_name = var.addon_context.eks_cluster_id
  namespace    = local.namespace

  iam_role_name                   = "${var.addon_context.eks_cluster_id}-karpenter-controller"
  iam_role_use_name_prefix        = false
  iam_policy_name                 = "${var.addon_context.eks_cluster_id}-karpenter-controller"
  iam_policy_use_name_prefix      = false
  node_iam_role_name              = "${var.addon_context.eks_cluster_id}-karpenter-node"
  node_iam_role_use_name_prefix   = false
  queue_name                      = "${var.addon_context.eks_cluster_id}-karpenter"
  rule_name_prefix                = "eks-workshop"
  create_pod_identity_association = true

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

# Helm chart

resource "helm_release" "karpenter" {
  name                = "karpenter"
  namespace           = local.namespace
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = var.karpenter_version
  wait                = true

  values = [
    <<-EOT
    settings:
      clusterName: ${var.addon_context.eks_cluster_id}
      clusterEndpoint: ${var.addon_context.aws_eks_cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}

data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

resource "aws_s3_bucket" "inference" {
  bucket_prefix = "${var.addon_context.eks_cluster_id}-inference"
  force_destroy = true

  tags = var.tags
}

module "iam_assumable_role_inference" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-inference"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.inference.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:aiml:inference"]

  tags = var.tags
}

resource "aws_iam_policy" "inference" {
  name        = "${var.addon_context.eks_cluster_id}-inference"
  path        = "/"
  description = "IAM policy for the inferenct workload"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.inference.id}",
        "arn:aws:s3:::${aws_s3_bucket.inference.id}/*"
      ]
    }
  ]
}
EOF
}

data "http" "neuron_device_plugin_rbac_manifest" {
  url = "https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.20.0/src/k8/k8s-neuron-device-plugin-rbac.yml"
}

data "http" "neuron_device_plugin_manifest" {
  url = "https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.20.0/src/k8/k8s-neuron-device-plugin.yml"
}

data "kubectl_file_documents" "neuron_device_plugin_rbac_doc" {
  content = data.http.neuron_device_plugin_rbac_manifest.response_body
}

data "kubectl_file_documents" "neuron_device_plugin_doc" {
  content = data.http.neuron_device_plugin_manifest.response_body
}

resource "kubectl_manifest" "neuron_device_plugin_rbac" {
  for_each  = data.kubectl_file_documents.neuron_device_plugin_rbac_doc.manifests
  yaml_body = each.value
}

resource "kubectl_manifest" "neuron_device_plugin" {
  for_each  = data.kubectl_file_documents.neuron_device_plugin_doc.manifests
  yaml_body = each.value
}
