terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix   = "${var.addon_context.eks_cluster_id}-ebs-csi-"
  policy_name_prefix = "${var.addon_context.eks_cluster_id}-ebs-csi-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.23.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      preserve                 = false
      configuration_values     = jsonencode({ defaultStorageClass = { enabled = true } })
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait        = true
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }

  observability_tag = null
}

resource "time_sleep" "wait" {
  depends_on = [
    module.eks_blueprints_addons
  ]

  create_duration = "10s"
}

resource "kubectl_manifest" "ingress_class_params" {
  depends_on = [time_sleep.wait]

  wait = true

  yaml_body = <<-YAML
    apiVersion: elbv2.k8s.aws/v1beta1
    kind: IngressClassParams
    metadata:
      name: restricted
    spec:
      scheme: internet-facing
      inboundCIDRs: ${jsonencode(split(",", var.inbound_cidrs))}
  YAML
}

resource "kubectl_manifest" "ingress_class" {
  wait = true

  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: IngressClass
    metadata:
      name: restricted
      annotations:
        ingressclass.kubernetes.io/is-default-class: "true"
    spec:
      controller: ingress.k8s.aws/alb
      parameters:
        apiGroup: elbv2.k8s.aws
        kind: IngressClassParams
        name: restricted
  YAML

  depends_on = [
    kubectl_manifest.ingress_class_params
  ]
}

data "aws_region" "current" {}

resource "aws_codecommit_repository" "flux" {
  repository_name = "${var.addon_context.eks_cluster_id}-flux"
  description     = "CodeCommit repository for Flux"
}

resource "aws_iam_user" "gitops" {
  name = "${var.addon_context.eks_cluster_id}-gitops"
  path = "/"
}

resource "aws_iam_user_ssh_key" "gitops" {
  username   = aws_iam_user.gitops.name
  encoding   = "SSH"
  public_key = tls_private_key.gitops.public_key_openssh
}

resource "tls_private_key" "gitops" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.gitops.private_key_pem
  filename        = "/home/ec2-user/.ssh/gitops_ssh.pem"
  file_permission = "0400"
}

resource "local_file" "ssh_config" {
  content         = <<EOF
Host git-codecommit.*.amazonaws.com
  User ${aws_iam_user.gitops.unique_id}
  IdentityFile ~/.ssh/gitops_ssh.pem
EOF
  filename        = "/home/ec2-user/.ssh/config"
  file_permission = "0600"
}

data "aws_iam_policy_document" "gitops_access" {
  statement {
    sid = ""
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush"
    ]
    effect = "Allow"
    resources = [
      aws_codecommit_repository.flux.arn
    ]
  }
}

resource "aws_iam_policy" "gitops_access" {
  name   = "${var.addon_context.eks_cluster_id}-gitops"
  path   = "/"
  policy = data.aws_iam_policy_document.gitops_access.json
}

resource "aws_iam_user_policy_attachment" "gitops_access" {
  user       = aws_iam_user.gitops.name
  policy_arn = aws_iam_policy.gitops_access.arn
}