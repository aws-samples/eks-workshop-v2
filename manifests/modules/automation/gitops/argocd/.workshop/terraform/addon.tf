module "argocd" {
  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/argocd"
  addon_context = local.addon_context

  helm_config = {
    name             = "argocd"
    chart            = "argo-cd"
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "5.36.0"
    namespace        = "argocd"
    timeout          = 1200
    create_namespace = true

    set = [{
      name  = "server.replicas"
      value = "1"
    },{
      name  = "controller.replicas"
      value = "1"
    },{
      name  = "repoServer.replicas"
      value = "1"
    },{
      name  = "applicationSet.replicaCount"
      value = "1"
    },{
      name  = "redis-ha.enabled"
      value = "false"
    },{
      name  = "server.service.type"
      value = "LoadBalancer"
    }]
  }
}

resource "aws_codecommit_repository" "argocd" {
  repository_name = "${local.addon_context.eks_cluster_id}-argocd"
  description     = "CodeCommit repository for ArgoCD"
}

resource "aws_iam_user" "gitops" {
  name = "${local.addon_context.eks_cluster_id}-gitops"
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
      aws_codecommit_repository.argocd.arn
    ]
  }
}

resource "aws_iam_policy" "gitops_access" {
  name   = "${local.addon_context.eks_cluster_id}-gitops"
  path   = "/"
  policy = data.aws_iam_policy_document.gitops_access.json
}

resource "aws_iam_user_policy_attachment" "gitops_access" {
  user       = aws_iam_user.gitops.name
  policy_arn = aws_iam_policy.gitops_access.arn
}

output "environment" {
  value = <<EOF
export GITOPS_IAM_SSH_KEY_ID=${aws_iam_user_ssh_key.gitops.id}
export GITOPS_IAM_SSH_USER=${aws_iam_user.gitops.unique_id}
export GITOPS_REPO_URL_ARGOCD="ssh://${aws_iam_user_ssh_key.gitops.id}@git-codecommit.${data.aws_region.current.id}.amazonaws.com/v1/repos/${local.addon_context.eks_cluster_id}-argocd"
EOF
}