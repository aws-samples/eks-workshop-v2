resource "aws_codecommit_repository" "gitops" {
  repository_name = "${local.addon_context.eks_cluster_id}-gitops"
  description     = "CodeCommit repository for GitOps"
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

resource "aws_ssm_parameter" "gitops" {
  name  = "${local.addon_context.eks_cluster_id}-gitops-ssh"
  type  = "SecureString"
  value = tls_private_key.gitops.private_key_pem
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
export GITOPS_SSH_SSM_NAME=${aws_ssm_parameter.gitops.name}
EOF
}
