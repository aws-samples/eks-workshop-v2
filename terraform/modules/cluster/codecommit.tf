resource "aws_codecommit_repository" "gitops" {
  repository_name = "${var.environment_name}-gitops"
  description     = "CodeCommit repository for GitOps"
}

resource "aws_iam_user" "gitops" {
  name = "${var.environment_name}-gitops"
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
  name  = "${var.environment_name}-gitops-ssh"
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
  name   = "${var.environment_name}-gitops"
  path   = "/"
  policy = data.aws_iam_policy_document.gitops_access.json
}

resource "aws_iam_user_policy_attachment" "gitops_access" {
  user       = aws_iam_user.gitops.name
  policy_arn = aws_iam_policy.gitops_access.arn
}
