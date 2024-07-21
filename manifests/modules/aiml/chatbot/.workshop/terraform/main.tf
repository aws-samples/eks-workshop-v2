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

data "aws_region" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"

  enable_karpenter = true

  karpenter_enable_spot_termination          = true
  karpenter_enable_instance_profile_creation = true
  karpenter = {
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
  }

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn
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

resource "aws_s3_bucket" "chatbot" {
  bucket_prefix = "eksworkshop-chatbot"
  force_destroy = true

  tags = var.tags
}

#resource "aws_iam_role" "graviton_node" {
#  name = "${var.addon_context.eks_cluster_id}-graviton-node"

#  assume_role_policy = jsonencode({
#Version = "2012-10-17"
#Statement = [
#{
#Action = "sts:AssumeRole"
#Effect = "Allow"
#Sid    = ""
#Principal = {
#Service = "ec2.amazonaws.com"
#}
#},
#]
# })

#managed_policy_arns = [
# "arn:${var.addon_context.aws_partition_id}:iam::aws:policy/AmazonEKS_CNI_Policy",
# "arn:${var.addon_context.aws_partition_id}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
# "arn:${var.addon_context.aws_partition_id}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
# "arn:${var.addon_context.aws_partition_id}:iam::aws:policy/AmazonSSMManagedInstanceCore"
#]

#tags = var.tags
#}

module "iam_assumable_role_chatbot" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.39.1"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-chatbot"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.chatbot.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:aiml:chatbot"]

  tags = var.tags
}

resource "aws_iam_policy" "chatbot" {
  name        = "${var.addon_context.eks_cluster_id}-chatbot"
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
        "arn:aws:s3:::${aws_s3_bucket.chatbot.id}",
        "arn:aws:s3:::${aws_s3_bucket.chatbot.id}/*"
      ]
    }
  ]
}
EOF
}

data "http" "neuron_device_plugin_rbac_manifest" {
  url = "https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.6.0/src/k8/k8s-neuron-device-plugin-rbac.yml"
}

data "http" "neuron_device_plugin_manifest" {
  url = "https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.6.0/src/k8/k8s-neuron-device-plugin.yml"
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
