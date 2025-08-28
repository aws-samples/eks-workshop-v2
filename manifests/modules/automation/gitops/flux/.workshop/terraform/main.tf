resource "aws_codecommit_repository" "gitops" {
  repository_name = "${var.addon_context.eks_cluster_id}-gitops"
  description     = "CodeCommit repository for GitOps"
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

data "aws_iam_policy_document" "gitops_access" {
  statement {
    sid = ""
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush"
    ]
    effect    = "Allow"
    resources = [aws_codecommit_repository.gitops.arn]
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

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

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
