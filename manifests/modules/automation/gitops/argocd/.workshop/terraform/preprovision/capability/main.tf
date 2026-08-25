# The Amazon EKS Capability for Argo CD and the cluster-side wiring it needs.
#
# This is a child module rather than inline configuration because two different
# callers create it:
#
#   ../main.tf     Workshop Studio events, during pre-provisioning.
#   ../../main.tf  everywhere else, gated on resources_precreated.
#
# It still sits under `preprovision/` even though it no longer touches Identity
# Center, because `hack/pre-provision-resources.sh` copies a preprovision directory
# and nothing around it. A module a staged preprovision directory sources has to live
# inside that directory, so this cannot move somewhere more neutral without teaching
# the staging script to copy it as well.
#
# Creating this during pre-provisioning rather than at lab time buys two things.
# The Argo CD rollout takes around ten minutes, which is time participants would
# otherwise spend watching `prepare-environment`. It also keeps the capability out
# of the lab's Terraform state, so moving between labs no longer destroys and
# rebuilds it.
#
# Identity Center is discovered here rather than passed in, so that both callers
# instantiate this the same way and neither has to care whether the instance was
# pre-provisioned by `manifests/.workshop/terraform/preprovision-base` or created by
# hand for a self-service run.
data "aws_region" "current" {}

data "aws_ssoadmin_instances" "main" {}

data "aws_identitystore_group" "argocd_admins" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = var.idc_group_name
    }
  }
}

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
# would make the create below fail as a duplicate. `delete_propagation_policy`
# below is RETAIN, so a torn-down capability can leave one behind.
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
        idc_instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
        idc_region       = data.aws_region.current.id
      }

      # Mapped to the group rather than to the user directly. Access is then granted
      # by adding a member to the group, which a second lab or a second cluster can
      # do without editing a mapping it does not own.
      rbac_role_mapping {
        role = "ADMIN"
        identity {
          id   = data.aws_identitystore_group.argocd_admins.group_id
          type = "SSO_GROUP"
        }
      }
    }
  }

  tags = var.tags
}

# Argo CD runs in AWS-owned infrastructure and reaches this cluster as the
# capability's IAM role. `CreateCapability` creates that role's access entry itself
# and attaches AmazonEKSArgoCDPolicy (namespace argocd) and
# AmazonEKSArgoCDClusterPolicy (cluster) to it, which is everything the capability
# needs to come up. So there is deliberately no `aws_eks_access_entry` here: EKS owns
# that resource, and declaring it collides with ResourceInUseException.
#
# This association adds what the auto-attached pair does not cover: permission to
# sync a participant's Applications into the cluster. It depends on the capability so
# the auto-created access entry exists first, otherwise AssociateAccessPolicy fails
# with ResourceNotFoundException on the principal ARN.
resource "aws_eks_access_policy_association" "argocd" {
  depends_on = [aws_eks_capability.argocd]

  cluster_name  = var.eks_cluster_id
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.argocd_capability.arn

  access_scope {
    type = "cluster"
  }
}
