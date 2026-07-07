# EKS Capabilities provisioning -----------------------------------------------
#
# Enables the ACK EKS-managed capability on the shared Auto Mode cluster.
# Used ONLY by the `fastpaths/eks-capabilities` lab. Although this file lives in
# the shared `developers` preprovision module (which reset-environment applies
# for every fastpath), every resource here is gated behind
# var.enable_eks_capabilities so it provisions ONLY for the eks-capabilities
# path — the developer and operator paths never create capabilities and never
# require an IAM Identity Center instance.
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

  # Gate: 1 when the eks-capabilities fast path is active, 0 otherwise. Applied
  # as `count` on every capability resource so dev/operator apply nothing here.
  eks_cap_count = var.enable_eks_capabilities ? 1 : 0
}

resource "null_resource" "eks_cap_region_preflight" {
  count = local.eks_cap_count

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

  # Lab 3 (kro) provisions a second carts-* table via an RGD instance. Use a
  # wildcard ARN so the same carts Pod Identity policy and the same ACK
  # capability role cover both Lab 1's `${cluster}-carts-fastpath` and any
  # `${cluster}-carts-*` table a learner names in their CartsStack instance.
  eks_cap_carts_tables_wildcard_arn = "arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:table/${var.eks_cluster_auto_id}-carts-*"
  eks_cap_kro_table_name            = "${var.eks_cluster_auto_id}-carts-kro"
}

# --- IAM Capability Role for ACK --------------------------------------------
#
# Assumed by the EKS capabilities service principal. The ACK controllers
# (running in AWS-managed infra outside the cluster) use this role to call
# the AWS APIs needed to reconcile the Table custom resource.

resource "aws_iam_role" "eks_cap_ack_capability" {
  count = local.eks_cap_count
  name  = "${var.eks_cluster_auto_id}-ack-cap-role"

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
  count = local.eks_cap_count
  name  = "ack-capability-dynamodb"
  role  = aws_iam_role.eks_cap_ack_capability[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageCartsFastpathTables"
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
          local.eks_cap_carts_tables_wildcard_arn,
          "${local.eks_cap_carts_tables_wildcard_arn}/index/*",
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
  count = local.eks_cap_count

  depends_on = [
    aws_iam_role.eks_cap_ack_capability,
    aws_iam_role_policy.eks_cap_ack_capability_dynamodb,
  ]

  create_duration = "30s"
}

# Activate the ACK capability via the AWS provider's native resource.
#
# The capability auto-creates an EKS access entry for its capability role
# during creation and AWS auto-attaches the minimum policies it needs to reach
# ACTIVE — so the capability does NOT depend on the supplemental
# AmazonEKSClusterAdminPolicy association below. Same pattern as the Argo CD
# and kro capabilities.
resource "aws_eks_capability" "ack" {
  count                     = local.eks_cap_count
  cluster_name              = var.eks_cluster_auto_id
  capability_name           = local.eks_cap_ack_capability_name
  type                      = "ACK"
  role_arn                  = aws_iam_role.eks_cap_ack_capability[0].arn
  delete_propagation_policy = "RETAIN"

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.eks_cap_ack_capability_dynamodb,
    null_resource.eks_cap_region_preflight,
    time_sleep.eks_cap_ack_capability_role_propagation,
  ]
}

# Grant the capability's IAM role cluster-admin so its controllers can
# reconcile the AWS resources a learner asks for (create CRDs, watch
# resources, write Table status, etc.). The auto-attached policies on the
# capability's auto-created access entry are enough to reach ACTIVE, but not
# to manage user workloads — that's what this association adds.
#
# We do NOT declare an aws_eks_access_entry — the capability auto-creates one
# and an explicit declaration would collide with `ResourceInUseException`.
#
# This depends on the capability resource so the auto-created access entry is
# guaranteed to exist before AssociateAccessPolicy runs (otherwise EKS returns
# `ResourceNotFoundException: principalArn could not be found`). Same pattern
# as the Argo CD and kro capabilities.
resource "aws_eks_access_policy_association" "ack" {
  count         = local.eks_cap_count
  cluster_name  = var.eks_cluster_auto_id
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.eks_cap_ack_capability[0].arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_capability.ack]
}

# Give the access policy association time to propagate inside the cluster
# before any ACK custom resource is applied by the labs.
resource "time_sleep" "eks_cap_ack_access_propagation" {
  count           = local.eks_cap_count
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
  count = local.eks_cap_count
  name  = "carts-fastpath-dynamodb"
  role  = module.iam_assumable_role_carts.iam_role_name

  # Wildcard `${cluster}-carts-*` so the same carts ServiceAccount role
  # covers both Lab 1's `-carts-fastpath` table and Lab 3's `-carts-kro`
  # table created by the kro RGD instance. No per-instance policy edits
  # needed when the learner names a new CartsStack.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllAPIActionsOnCartFastpathTables"
        Effect = "Allow"
        Action = "dynamodb:*"
        Resource = [
          local.eks_cap_carts_tables_wildcard_arn,
          "${local.eks_cap_carts_tables_wildcard_arn}/index/*",
        ]
      }
    ]
  })
}
