data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role" {

  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "eks_developers" {
  name               = "${var.eks_cluster_id}-developers"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role" "eks_read_only" {
  name               = "${var.eks_cluster_id}-read-only"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role" "eks_carts_team" {
  name               = "${var.eks_cluster_id}-carts-team"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role" "eks_admins" {
  name               = "${var.eks_cluster_id}-admins"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "terraform_data" "identity_mapping" {
  provisioner "local-exec" {
    command = "eksctl create iamidentitymapping --cluster ${var.eks_cluster_id} --arn ${aws_iam_role.eks_admins.arn} --group system:masters --username cluster-admin"
  }
}