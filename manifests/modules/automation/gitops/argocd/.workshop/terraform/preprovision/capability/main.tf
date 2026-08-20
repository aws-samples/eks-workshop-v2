# The Amazon EKS Capability for Argo CD and the cluster-side wiring it needs.
#
# This is a child module rather than inline configuration because two different
# callers create it, and only one of them is ever allowed to touch IAM Identity
# Center:
#
#   ../main.tf     Workshop Studio events, alongside the Identity Center instance
#                  and user created there.
#   ../../main.tf  everywhere else, from an Identity Center instance the account
#                  already had, gated on resources_precreated.
#
# Sitting under `preprovision/` keeps that asymmetry intact. Terraform only loads
# directories reachable from a `source`, so the lab reaching `./preprovision/capability`
# does not make `preprovision/main.tf` and its Identity Center writes reachable.
#
# Creating this during pre-provisioning rather than at lab time buys two things.
# The Argo CD rollout takes around ten minutes, which is time participants would
# otherwise spend watching `prepare-environment`. It also keeps the capability out
# of the lab's Terraform state, so moving between labs no longer destroys and
# rebuilds it.
data "aws_region" "current" {}

locals {
  capability_role_name = "${var.eks_cluster_id}-argocd-capability"
}

resource "aws_iam_role" "argocd_capability" {
  name = local.capability_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "capabilities.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "argocd_capability_sso" {
  name = "ArgocdCapabilitySsoPolicy"
  role = aws_iam_role.argocd_capability.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sts:GetCallerIdentity"]
      Resource = ["*"]
    }]
  })
}

# EKS validates the trust policy before IAM propagates globally (~15s).
resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role_policy.argocd_capability_sso]
  create_duration = "30s"
}

# An access entry left behind by a previous capability with the same role name
# would make the create below fail as a duplicate.
resource "null_resource" "cleanup_stale_access_entry" {
  depends_on = [time_sleep.iam_propagation]

  triggers = {
    role_arn     = aws_iam_role.argocd_capability.arn
    cluster_name = var.eks_cluster_id
    region       = data.aws_region.current.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      aws eks delete-access-entry \
        --region ${self.triggers.region} \
        --cluster-name ${self.triggers.cluster_name} \
        --principal-arn ${self.triggers.role_arn} 2>/dev/null || true
    EOF
  }
}

resource "aws_eks_capability" "argocd" {
  depends_on = [null_resource.cleanup_stale_access_entry]

  cluster_name              = var.eks_cluster_id
  capability_name           = "argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.argocd_capability.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      aws_idc {
        idc_instance_arn = var.idc_instance_arn
        idc_region       = data.aws_region.current.id
      }

      rbac_role_mapping {
        role = "ADMIN"
        identity {
          id   = var.idc_user_id
          type = "SSO_USER"
        }
      }
    }
  }
}

resource "null_resource" "argocd_capability_access_entry" {
  depends_on = [aws_eks_capability.argocd]

  triggers = {
    role_arn     = aws_iam_role.argocd_capability.arn
    cluster_name = var.eks_cluster_id
    region       = data.aws_region.current.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      aws eks create-access-entry \
        --region ${self.triggers.region} \
        --cluster-name ${self.triggers.cluster_name} \
        --principal-arn ${self.triggers.role_arn} 2>/dev/null || true
      aws eks associate-access-policy \
        --region ${self.triggers.region} \
        --cluster-name ${self.triggers.cluster_name} \
        --principal-arn ${self.triggers.role_arn} \
        --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
        --access-scope type=cluster
    EOF
  }
}

# Argo CD runs in the AWS control plane and reaches the cluster as the
# `argocd-manager` service account the capability creates, which starts with no
# permissions of its own.
#
# Declared through the Kubernetes provider rather than a `kubectl` call, because
# pre-provisioning runs in a CodeBuild container that has no kubectl binary and no
# kubeconfig. The provider in `base.tf` authenticates straight to the API endpoint
# with an EKS token, so it works in both callers.
resource "kubernetes_cluster_role_binding" "argocd_manager" {
  depends_on = [aws_eks_capability.argocd]

  metadata {
    name = "argocd-manager-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-manager"
    namespace = "kube-system"
  }
}
