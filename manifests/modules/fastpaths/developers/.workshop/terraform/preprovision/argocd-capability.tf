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
  eks_cap_argocd_admin_user      = "${var.eks_cluster_auto_id}-argocd-admin"
  eks_cap_argocd_admin_group     = "${var.eks_cluster_auto_id}-argocd-admins"
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
  }
}

# --- Identity Center user + group + membership ------------------------------
#
# We create a workshop-scoped admin group and a single user inside the built-in
# Identity Store, then map the GROUP -> Argo CD ADMIN role in the capability
# config below.
#
# Activation flow (matches saas-on-eks-workshop-capabilities):
#   1. Admin disables MFA on the IDC instance once (Console only, no API).
#   2. Admin generates a one-time password for this user via the IDC Console
#      (Users -> argo-admin -> Reset password -> "Generate a one-time password").
#   3. Learner signs in to Argo CD with username + OTP, is forced to set a
#      permanent password, then lands in Argo CD as ADMIN.
#
# This is why the email defaults to a non-deliverable placeholder — the OTP
# flow doesn't use it. To use the email-link activation flow instead, set
# TF_VAR_argocd_admin_email to a real address.
#
# Pattern adopted from:
#   https://github.com/aws-samples/saas-on-eks-workshop-capabilities/blob/main/assetsSrc/terraform/identity-center.tf
#   https://github.com/aws-samples/saas-on-eks-workshop-capabilities/blob/main/content/100-introduction/225-argocd-user-management.en.md
resource "aws_identitystore_user" "argocd_admin" {
  identity_store_id = local.eks_cap_idc_identitystore

  user_name    = local.eks_cap_argocd_admin_user
  display_name = "Argo CD Workshop Admin"

  name {
    given_name  = "Argo CD"
    family_name = "Workshop Admin"
  }

  emails {
    value   = var.argocd_admin_email
    primary = true
  }

  depends_on = [null_resource.eks_cap_argocd_idc_preflight]
}

resource "aws_identitystore_group" "argocd_admins" {
  identity_store_id = local.eks_cap_idc_identitystore
  display_name      = local.eks_cap_argocd_admin_group
  description       = "Argo CD administrators for ${var.eks_cluster_auto_id} (EKS Workshop fast path)"

  depends_on = [null_resource.eks_cap_argocd_idc_preflight]
}

resource "aws_identitystore_group_membership" "argocd_admin" {
  identity_store_id = local.eks_cap_idc_identitystore
  group_id          = aws_identitystore_group.argocd_admins.group_id
  member_id         = aws_identitystore_user.argocd_admin.user_id
}

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
          id   = aws_identitystore_group.argocd_admins.group_id
          type = "SSO_GROUP"
        }
      }
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.eks_cap_argocd_codecommit,
    aws_identitystore_group_membership.argocd_admin,
    null_resource.eks_cap_region_preflight,
    null_resource.eks_cap_argocd_idc_preflight,
    time_sleep.eks_cap_argocd_role_propagation,
  ]
}

# Grant the capability's IAM role permission to deploy into THIS cluster.
#
# Unlike the ACK capability, the Argo CD capability AUTOMATICALLY creates the
# EKS access entry for its Capability Role during creation, and AWS auto-attaches
# AmazonEKSArgoCDPolicy (namespace-scoped to argocd) and AmazonEKSArgoCDClusterPolicy
# (cluster-wide). Those auto-attached policies are sufficient for the capability
# to bootstrap itself (create argocd namespace, install CRDs, etc.).
#
# We additionally bind AmazonEKSClusterAdminPolicy so the capability's controllers
# can sync user Applications to the local "in-cluster" deployment target the
# learner registers in Lab 2.
#
# IMPORTANT: do NOT make this depend on aws_eks_capability.argocd reaching ACTIVE.
# That creates a deadlock: terraform waits for the capability before attaching the
# admin policy, but the capability sits in CREATING with health
# `AccessDenied: Unauthorized` for the full 20-min timeout because its controllers
# can't write user Applications without the admin policy. By letting this resource
# apply in parallel with the capability create, the admin policy lands shortly
# after the auto-created access entry appears, and the capability completes its
# next health check successfully.
#
# We also DON'T create an aws_eks_access_entry here — the capability auto-creates
# one and our explicit declaration would collide (ResourceInUseException).
resource "aws_eks_access_policy_association" "argocd" {
  cluster_name  = var.eks_cluster_auto_id
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.eks_cap_argocd_capability.arn

  access_scope {
    type = "cluster"
  }

  # Depend only on the IAM role + 30s propagation, NOT on the capability.
  # The capability's auto-created access entry is what this association binds
  # to; that entry exists from the moment the capability starts CREATING, so
  # we don't need to wait for it to reach ACTIVE.
  depends_on = [
    aws_iam_role.eks_cap_argocd_capability,
    time_sleep.eks_cap_argocd_role_propagation,
  ]
}
