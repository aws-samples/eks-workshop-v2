# EKS Capabilities provisioning -----------------------------------------------
#
# Enables the ACK EKS-managed capability on the shared Auto Mode cluster.
# Used by the `fastpaths/eks-capabilities` lab. Provisioned alongside the
# other fastpaths preprovision resources because the cluster is shared.
#
# Reference pattern: aws-samples/appmod-blueprints
#   platform/infra/terraform/cluster/main.tf
#
# We rely on data sources already declared in eks-auto.tf
# (aws_caller_identity, aws_region, aws_partition).

# --- Region preflight --------------------------------------------------------
#
# EKS Capabilities are not available in AWS GovCloud or China regions per the
# GA announcement (Nov 2025). Fail fast with a clear message so learners don't
# wait several minutes for a downstream API error.
locals {
  eks_cap_unsupported_region_prefixes = ["us-gov-", "cn-"]
  eks_cap_region_supported = !anytrue([
    for prefix in local.eks_cap_unsupported_region_prefixes :
    startswith(data.aws_region.current.id, prefix)
  ])
}

resource "null_resource" "eks_cap_region_preflight" {
  lifecycle {
    precondition {
      condition     = local.eks_cap_region_supported
      error_message = "EKS Capabilities are not available in ${data.aws_region.current.id}. Run this fast path from a commercial AWS region (not GovCloud or China)."
    }
  }
}

locals {
  eks_cap_ack_capability_name = "${var.eks_cluster_auto_id}-ack"
  eks_cap_carts_table_name    = "${var.eks_cluster_auto_id}-carts-fastpath"
  eks_cap_carts_table_arn     = "arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:table/${local.eks_cap_carts_table_name}"
}

# --- IAM Capability Role for ACK --------------------------------------------
#
# Assumed by the EKS capabilities service principal. The ACK controllers
# (running in AWS-managed infra outside the cluster) use this role to call
# the AWS APIs needed to reconcile the Table custom resource.

resource "aws_iam_role" "eks_cap_ack_capability" {
  name = "${var.eks_cluster_auto_id}-ack-cap-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession",
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "eks_cap_ack_capability_dynamodb" {
  name = "ack-capability-dynamodb"
  role = aws_iam_role.eks_cap_ack_capability.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageCartsFastpathTable"
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:DescribeTable",
          "dynamodb:UpdateTable",
          "dynamodb:DeleteTable",
          "dynamodb:UpdateContinuousBackups",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:UpdateTimeToLive",
          "dynamodb:DescribeContributorInsights",
          "dynamodb:UpdateContributorInsights",
          "dynamodb:DescribeKinesisStreamingDestination",
          "dynamodb:EnableKinesisStreamingDestination",
          "dynamodb:DisableKinesisStreamingDestination",
          "dynamodb:GetResourcePolicy",
          "dynamodb:PutResourcePolicy",
          "dynamodb:DeleteResourcePolicy",
          "dynamodb:TagResource",
          "dynamodb:UntagResource",
          "dynamodb:ListTagsOfResource",
        ]
        Resource = [
          local.eks_cap_carts_table_arn,
          "${local.eks_cap_carts_table_arn}/index/*",
        ]
      }
    ]
  })
}

# Wait for IAM eventual consistency before EKS validates the role's trust
# policy. Without this gap, CreateCapability frequently fails with
# `InvalidParameterException: The trust policy for the provided role is
# invalid` on a freshly-created role, even though the policy is correct.
# `reset-environment` runs `terraform destroy` then `apply`, so every
# preprovision run creates a brand-new role and re-encounters this race.
resource "time_sleep" "eks_cap_ack_capability_role_propagation" {
  depends_on = [
    aws_iam_role.eks_cap_ack_capability,
    aws_iam_role_policy.eks_cap_ack_capability_dynamodb,
  ]

  create_duration = "30s"
}

# Activate the ACK capability via the AWS provider's native resource.
resource "aws_eks_capability" "ack" {
  cluster_name              = var.eks_cluster_auto_id
  capability_name           = local.eks_cap_ack_capability_name
  type                      = "ACK"
  role_arn                  = aws_iam_role.eks_cap_ack_capability.arn
  delete_propagation_policy = "RETAIN"

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.eks_cap_ack_capability_dynamodb,
    null_resource.eks_cap_region_preflight,
    time_sleep.eks_cap_ack_capability_role_propagation,
    time_sleep.eks_cap_ack_access_propagation,
  ]
}

# Bind the capability's IAM role to the cluster admin access policy so its
# controllers can reconcile inside the cluster (create CRDs, watch resources,
# etc.). Without this association the capability shows ACTIVE but its
# controllers cannot talk to the Kubernetes API.
#
# An aws_eks_access_entry is required before an aws_eks_access_policy_association
# can attach a policy to a principal — the entry establishes the principal's
# identity on the cluster, the association attaches policies to it.
#
# Both are created BEFORE aws_eks_capability.ack so the capability's controllers
# already have cluster API access the first time they reconcile. Without this
# ordering, the capability sits in CREATING with health
# `AccessDenied: Unauthorized`.
resource "aws_eks_access_entry" "ack" {
  cluster_name  = var.eks_cluster_auto_id
  principal_arn = aws_iam_role.eks_cap_ack_capability.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ack" {
  cluster_name  = var.eks_cluster_auto_id
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.eks_cap_ack_capability.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ack]
}

# Give the access entry + policy association time to propagate inside the
# cluster before the capability creates and its controllers try to authenticate.
# Without this gap, the capability frequently sits in CREATING with health
resource "time_sleep" "eks_cap_ack_access_propagation" {
  depends_on      = [aws_eks_access_policy_association.ack]
  create_duration = "60s"
}

# --- Extend the existing carts Pod Identity role -----------------------------
#
# The fastpaths preprovision already creates a carts role + Pod Identity
# association in pod-identity.tf, scoped to the `${cluster}-carts` table.
# Add an inline policy granting access to the new `-carts-fastpath` table
# so the same carts ServiceAccount can read/write it after Lab 1's ConfigMap
# flip — no new ServiceAccount, no SA annotation patching needed.
resource "aws_iam_role_policy" "eks_cap_carts_fastpath_dynamodb" {
  name = "carts-fastpath-dynamodb"
  role = module.iam_assumable_role_carts.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllAPIActionsOnCartFastpath"
        Effect = "Allow"
        Action = "dynamodb:*"
        Resource = [
          local.eks_cap_carts_table_arn,
          "${local.eks_cap_carts_table_arn}/index/*",
        ]
      }
    ]
  })
}
