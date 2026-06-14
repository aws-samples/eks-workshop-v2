# kro EKS Capability provisioning --------------------------------------------
#
# Enables the kro EKS-managed capability on the shared Auto Mode cluster.
# Used by the `fastpaths/eks-capabilities` Lab 3 (Compose stacks with kro).
#
# kro is the EKS-managed form of the kro-run/kro project — a Kubernetes
# resource orchestrator that lets users define a single "schema" CR (e.g.
# `CartsStack`) which kro expands into a graph of underlying resources
# (Namespace, ACK Table, ConfigMap, ServiceAccount, ...).
#
# The capability runs in AWS-owned infrastructure outside the cluster. What
# you see inside the cluster are only the CRDs the capability registered
# (`resourcegraphdefinitions.kro.run` plus dynamically generated CRDs for
# each RGD a learner applies).
#
# Reference docs:
#   https://docs.aws.amazon.com/eks/latest/userguide/kro.html
#   https://docs.aws.amazon.com/eks/latest/userguide/create-kro-capability.html
#   https://github.com/kro-run/kro
#
# Data sources (aws_caller_identity, aws_region, aws_partition,
# aws_eks_cluster.eks_cluster_auto) and the region preflight
# (null_resource.eks_cap_region_preflight) are declared in eks-auto.tf /
# eks-capabilities.tf and reused here.

locals {
  eks_cap_kro_capability_name = "${var.eks_cluster_auto_id}-kro"
}

# --- IAM Capability Role for kro --------------------------------------------
#
# kro itself does NOT call AWS APIs (per AWS docs:
# https://docs.aws.amazon.com/eks/latest/userguide/kro-permissions.html). It
# only reconciles Kubernetes resources. So the capability role's only job is
# being trusted by the EKS capabilities service principal — no AWS data-plane
# permissions needed.
resource "aws_iam_role" "eks_cap_kro_capability" {
  name = "${var.eks_cluster_auto_id}-kro-cap-role"

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

# Wait for IAM eventual consistency before EKS validates the role's trust
# policy. Mirrors the ACK + Argo CD capability patterns — without this gap a
# freshly-created role frequently fails CreateCapability with an
# `InvalidParameterException: invalid trust policy` error, even though the
# policy is correct. `reset-environment` runs `terraform destroy` then
# `apply`, so every preprovision run creates a brand-new role and re-encounters
# this race.
resource "time_sleep" "eks_cap_kro_role_propagation" {
  depends_on      = [aws_iam_role.eks_cap_kro_capability]
  create_duration = "30s"
}

# Activate the kro capability via the AWS provider's native resource.
#
# Unlike the Argo CD capability, the kro capability does NOT need
# `AmazonEKSClusterAdminPolicy` to reach ACTIVE — the auto-attached
# `AmazonEKSKROPolicy` is sufficient for kro's bootstrap (managing its own
# `resourcegraphdefinitions.kro.run` CRD). So the capability create has no
# dependency on the supplemental policy below — no deadlock risk, and no
# need to apply them in parallel.
resource "aws_eks_capability" "kro" {
  cluster_name              = var.eks_cluster_auto_id
  capability_name           = local.eks_cap_kro_capability_name
  type                      = "KRO"
  role_arn                  = aws_iam_role.eks_cap_kro_capability.arn
  delete_propagation_policy = "RETAIN"

  tags = var.tags

  depends_on = [
    null_resource.eks_cap_region_preflight,
    time_sleep.eks_cap_kro_role_propagation,
  ]
}

# Grant the kro capability's IAM role cluster-admin so it can reconcile the
# children that workshop RGDs expand into (Namespaces, ACK Tables,
# ConfigMaps, ...).
#
# The kro capability auto-creates an EKS access entry for its capability
# role during creation (per AWS docs — same as the Argo CD capability). AWS
# auto-attaches `AmazonEKSKROPolicy` to that auto-created entry, which is
# sufficient for kro to manage its own CRDs but NOT to create the children
# those RGDs expand into.
#
# We do NOT declare an aws_eks_access_entry — the capability auto-creates
# one and our explicit declaration would collide with
# `ResourceInUseException`.
#
# Unlike the Argo CD capability (Decision 2), we DO depend on the capability
# resource here. Reason: kro's capability reaches ACTIVE on its own; the
# Argo CD deadlock came from Argo CD needing cluster-admin to bootstrap user
# Applications, which kro doesn't need. Depending on the capability resource
# guarantees the auto-created access entry exists before AssociateAccessPolicy
# runs (avoids `ResourceNotFoundException: principalArn could not be found`).
resource "aws_eks_access_policy_association" "kro" {
  cluster_name  = var.eks_cluster_auto_id
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.eks_cap_kro_capability.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_capability.kro,
  ]
}

# Give the access policy association time to propagate inside the cluster
# before any RGD/instance gets applied by the lab. Same 60s gap as the ACK
# capability.
resource "time_sleep" "eks_cap_kro_access_propagation" {
  depends_on      = [aws_eks_access_policy_association.kro]
  create_duration = "60s"
}
