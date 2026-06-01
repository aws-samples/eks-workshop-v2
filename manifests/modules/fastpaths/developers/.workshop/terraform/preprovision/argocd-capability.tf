# Argo CD EKS Capability provisioning ----------------------------------------
#
# Enables the Argo CD EKS-managed capability on the shared Auto Mode cluster,
# federated with AWS IAM Identity Center for sign-in. Used by the
# `fastpaths/eks-capabilities` Lab 2 (Continuous delivery with Argo CD).
#
# Reference pattern: aws-samples/appmod-blueprints + the AWS docs
#   https://docs.aws.amazon.com/eks/latest/userguide/create-argocd-capability.html
#
# Data sources (aws_caller_identity, aws_region, aws_partition,
# aws_eks_cluster.eks_cluster_auto) and the region preflight
# (null_resource.eks_cap_region_preflight) are declared in eks-auto.tf /
# eks-capabilities.tf and reused here.

# --- IAM Identity Center preflight -------------------------------------------
#
# Argo CD is the ONLY EKS capability that requires AWS IAM Identity Center —
# it is the sole authentication path (no local users, no admin password). We do
# NOT create an Identity Center instance for the learner: it is an account-wide,
# largely one-per-org resource. Instead we look it up and fail fast with an
# actionable message if it is missing, so learners don't wait minutes for an
# opaque downstream error.
#
# list-instances is a regional API, so this also enforces that Identity Center
# lives in the same region as the workshop cluster (required because we wire the
# instance region straight into the capability configuration below).
data "aws_ssoadmin_instances" "current" {}

locals {
  eks_cap_idc_present       = length(data.aws_ssoadmin_instances.current.arns) > 0
  eks_cap_idc_instance_arn  = local.eks_cap_idc_present ? tolist(data.aws_ssoadmin_instances.current.arns)[0] : ""
  eks_cap_idc_identitystore = local.eks_cap_idc_present ? tolist(data.aws_ssoadmin_instances.current.identity_store_ids)[0] : ""

  eks_cap_argocd_capability_name = "${var.eks_cluster_auto_id}-argocd"
  eks_cap_codecommit_repo_name   = "${var.eks_cluster_auto_id}-catalog-gitops"
  eks_cap_codecommit_repo_arn    = "arn:${data.aws_partition.current.partition}:codecommit:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${local.eks_cap_codecommit_repo_name}"
  eks_cap_codecommit_repo_url    = "https://git-codecommit.${data.aws_region.current.id}.amazonaws.com/v1/repos/${local.eks_cap_codecommit_repo_name}"
}

resource "null_resource" "eks_cap_argocd_idc_preflight" {
  lifecycle {
    precondition {
      condition     = local.eks_cap_idc_present
      error_message = "The Argo CD capability requires AWS IAM Identity Center, but no Identity Center instance was found in ${data.aws_region.current.id}. Enable IAM Identity Center in this region (https://console.aws.amazon.com/singlesignon/home) before running this fast path."
    }

    precondition {
      condition     = length(var.argocd_admin_group_id) > 0
      error_message = "var.argocd_admin_group_id is required: provide the UUID of an existing IAM Identity Center group whose members are mapped to Argo CD ADMIN. See website/docs/fastpaths/eks-capabilities/setup-idc.md for the one-time prerequisite walkthrough. The same approach is used by https://github.com/aws-samples/sample-platform-engineering-on-eks."
    }
  }
}

# Identity Center user + group lifecycle is intentionally NOT managed here.
# IDC users require a deliverable email for activation + MFA enrollment, so
# placeholders cannot complete first sign-in. The learner provisions the group
# (and a real-email user with MFA) once via the IDC console as a prerequisite,
# then passes the group's UUID via var.argocd_admin_group_id. Same model as
# https://github.com/aws-samples/sample-platform-engineering-on-eks.

# --- CodeCommit repository, seeded with the catalog manifests ----------------
#
# Pre-provisioned and seeded so the lab can focus on the managed Argo CD
# capability rather than Git plumbing. The repo holds a complete, self-contained
# copy of the catalog stack (deployment, service, mysql, config) so Argo CD can
# deploy a healthy catalog from scratch.
resource "aws_codecommit_repository" "catalog_gitops" {
  repository_name = local.eks_cap_codecommit_repo_name
  description     = "Catalog GitOps source for the EKS Workshop Argo CD capability fast path (${var.eks_cluster_auto_id})"

  tags = var.tags
}

# Seed the repo with the catalog manifests via a single CodeCommit commit.
# Idempotent: re-running prepare-environment (which destroys + re-applies this
# module) recreates the repo, so we always seed on create. The trigger also
# re-seeds if the local seed manifests change.
resource "null_resource" "eks_cap_argocd_repo_seed" {
  triggers = {
    repository   = aws_codecommit_repository.catalog_gitops.repository_name
    region       = data.aws_region.current.id
    content_hash = sha1(join(",", [for f in fileset("${path.module}/argocd-seed/catalog", "**") : filesha1("${path.module}/argocd-seed/catalog/${f}")]))
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/argocd-seed/seed-repo.sh"

    environment = {
      REPO_NAME  = aws_codecommit_repository.catalog_gitops.repository_name
      AWS_REGION = data.aws_region.current.id
      SEED_DIR   = "${path.module}/argocd-seed/catalog"
    }
  }

  depends_on = [aws_codecommit_repository.catalog_gitops]
}

# --- IAM Capability Role for Argo CD -----------------------------------------
#
# Assumed by the EKS capabilities service principal. The managed Argo CD
# (running in AWS-owned infrastructure) uses this role to pull the catalog
# manifests from CodeCommit. Scoped to GitPull on the single seeded repo —
# no account-wide managed policy.
resource "aws_iam_role" "eks_cap_argocd_capability" {
  name = "${var.eks_cluster_auto_id}-argocd-cap-role"

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

resource "aws_iam_role_policy" "eks_cap_argocd_codecommit" {
  name = "argocd-capability-codecommit"
  role = aws_iam_role.eks_cap_argocd_capability.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PullCatalogGitOpsRepo"
        Effect = "Allow"
        Action = [
          "codecommit:GitPull",
          "codecommit:GetRepository",
          "codecommit:GetBranch",
          "codecommit:GetFolder",
          "codecommit:GetFile",
        ]
        Resource = local.eks_cap_codecommit_repo_arn
      }
    ]
  })
}

# Wait for IAM eventual consistency before EKS validates the role's trust
# policy. Mirrors the ACK capability pattern in eks-capabilities.tf — a freshly
# created role frequently fails CreateCapability with an invalid-trust-policy
# error without this gap, and reset-environment recreates the role every run.
resource "time_sleep" "eks_cap_argocd_role_propagation" {
  depends_on = [
    aws_iam_role.eks_cap_argocd_capability,
    aws_iam_role_policy.eks_cap_argocd_codecommit,
  ]

  create_duration = "30s"
}

# Activate the Argo CD capability, federated with IAM Identity Center.
#
# The AWS Terraform provider models the capability configuration as native HCL
# nested blocks (NOT jsonencode). IAM Identity Center is required — the
# `aws_idc` block and a role mapping are mandatory for a usable capability.
resource "aws_eks_capability" "argocd" {
  cluster_name              = var.eks_cluster_auto_id
  capability_name           = local.eks_cap_argocd_capability_name
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.eks_cap_argocd_capability.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      namespace = "argocd"

      aws_idc {
        idc_instance_arn = local.eks_cap_idc_instance_arn
        idc_region       = data.aws_region.current.id
      }

      rbac_role_mapping {
        role = "ADMIN"

        identity {
          id   = var.argocd_admin_group_id
          type = "SSO_GROUP"
        }
      }
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.eks_cap_argocd_codecommit,
    null_resource.eks_cap_region_preflight,
    null_resource.eks_cap_argocd_idc_preflight,
    time_sleep.eks_cap_argocd_role_propagation,
  ]
}

# Grant the capability's IAM role permission to deploy into THIS cluster.
#
# Unlike the ACK capability, the Argo CD capability AUTOMATICALLY creates the
# EKS access entry for its Capability Role during creation — but grants it no
# Kubernetes RBAC. So we do NOT create an aws_eks_access_entry here (that would
# collide with the auto-created one); we only attach the cluster-admin access
# policy to the principal AFTER the capability exists. This lets Argo CD sync
# Applications to the local ("in-cluster") deployment target the learner
# registers in the lab.
resource "aws_eks_access_policy_association" "argocd" {
  cluster_name  = var.eks_cluster_auto_id
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.eks_cap_argocd_capability.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_capability.argocd]
}
