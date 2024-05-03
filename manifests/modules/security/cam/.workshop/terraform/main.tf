locals {
  arn_base     = join(":", slice(split(":", data.aws_eks_cluster.eks_cluster.arn), 0, 5))
  map_accounts = try(yamldecode(data.kubernetes_config_map_v1.aws_auth.data.mapAccounts), [])
  map_users    = try(yamldecode(data.kubernetes_config_map_v1.aws_auth.data.mapUsers), [])
  map_roles    = yamldecode(data.kubernetes_config_map_v1.aws_auth.data.mapRoles)
  add_roles = concat([{
    rolearn  = aws_iam_role.eks_developers.arn
    username = "developer"
    groups = [
      "developers"
    ]
  }])
}

data "aws_iam_policy_document" "assume_role" {

  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

data "aws_iam_policy_document" "view_only" {
  statement {
    sid = "List"
    actions = [
      "eks:ListFargateProfiles",
      "eks:ListNodegroups",
      "eks:ListUpdates",
      "eks:ListAddons",
      "eks:ListAccessEntries",
      "eks:ListAssociatedAccessPolicies",
      "eks:ListIdentityProviderConfigs",
      "eks:ListInsights",
      "eks:ListPodIdentityAssociations",
    ]
    resources = [
      data.aws_eks_cluster.eks_cluster.arn,
      "${local.arn_base}:nodegroup/*/*/*",
      "${local.arn_base}:addon/*/*/*",
      "arn:aws:eks::aws:cluster-access-policy",
    ]
  }

  statement {
    sid = "ListDescribeAll"
    actions = [
      "eks:DescribeAddonConfiguration",
      "eks:DescribeAddonVersions",
      "eks:ListClusters",
      "eks:ListAccessPolicies",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Describe"
    actions = [
      "eks:DescribeNodegroup",
      "eks:DescribeFargateProfile",
      "eks:ListTagsForResource",
      "eks:DescribeUpdate",
      "eks:AccessKubernetesApi",
      "eks:DescribeCluster",
      "eks:DescribeAddon",
      "eks:DescribeAccessEntry",
      "eks:DescribeIdentityProviderConfig",
      "eks:DescribeInsight",
      "eks:DescribePodIdentityAssociation",
    ]
    resources = [
      data.aws_eks_cluster.eks_cluster.arn,
      "${local.arn_base}:fargateprofile/*/*/*",
      "${local.arn_base}:nodegroup/*/*/*",
      "${local.arn_base}:addon/*/*/*",
    ]
  }
}


resource "aws_iam_role" "eks_developers" {
  name               = "EKSDevelopers"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "eks_developers" {
  name   = "EKSDevelopers"
  policy = data.aws_iam_policy_document.view_only.json
}

resource "aws_iam_role_policy_attachment" "eks_developers" {
  policy_arn = aws_iam_policy.eks_developers.arn
  role       = aws_iam_role.eks_developers.name
}

data "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles    = yamlencode(concat(local.add_roles, local.map_roles))
    mapUsers    = yamlencode(local.map_users)
    mapAccounts = yamlencode(local.map_accounts)
  }
  force = true
}

resource "kubernetes_cluster_role_binding_v1" "view" {
  metadata {
    name = "view"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }
  subject {
    kind      = "Group"
    name      = "developers"
    api_group = "rbac.authorization.k8s.io"
  }
}

# resource "kubernetes_role_binding_v1" "developers" {
#   metadata {
#     name      = "developers"
#     namespace = "default"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "edit"
#   }
#   subject {
#     kind      = "Group"
#     name      = "developers"
#     api_group = "rbac.authorization.k8s.io"
#   }
# }
