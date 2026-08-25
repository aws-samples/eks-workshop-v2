# Environment variables for the IDE shell.
#
# These cannot come from `module.preprovision` alone. That module is applied by this
# lab only when `resources_precreated` is false, so at a Workshop Studio event -- where
# the pre-provisioning pipeline applied it instead, into a different Terraform state --
# `module.preprovision[0]` does not exist and every value read from it is empty. The
# lab pages and test hooks that reference $EKS_CAP_* then get nothing, which is the
# same failure mode the Argo CD lab avoids by deriving its server URL from the EKS API
# rather than from Terraform.
#
# So anything that can be reconstructed from a name is reconstructed here, where it is
# available on both paths, and the preprovision outputs are merged over the top for the
# values that genuinely cannot be: the Fluent Bit log group carries a random suffix.
data "aws_region" "current" {}

locals {
  # Same expressions as preprovision/eks-capabilities.tf, argocd-capability.tf and
  # kro-capability.tf. Duplicated rather than passed, because a staged preprovision
  # module has no channel back to its caller at an event.
  eks_cap_codecommit_repo_name = "${var.eks_cluster_auto_id}-catalog-gitops"

  eks_cap_derived_environment = {
    EKS_CAP_DDB_TABLE      = "${var.eks_cluster_auto_id}-carts-fastpath"
    EKS_CAP_DDB_TABLE_KRO  = "${var.eks_cluster_auto_id}-carts-kro"
    EKS_CAP_ACK_CAPABILITY = "${var.eks_cluster_auto_id}-ack"
    EKS_CAP_KRO_CAPABILITY = "${var.eks_cluster_auto_id}-kro"

    EKS_CAP_ARGOCD_CAPABILITY = "${var.eks_cluster_auto_id}-argocd"

    # Named after the environment, not the cluster: the user and group are created once
    # per environment by manifests/.workshop/terraform/preprovision-base and shared by
    # every capability that federates with Identity Center.
    EKS_CAP_ARGOCD_USER        = var.eks_cluster_id
    EKS_CAP_ARGOCD_ADMIN_GROUP = "${var.eks_cluster_id}-argocd-admins"

    EKS_CAP_ARGOCD_ADMIN_GROUP_ID = try(data.aws_identitystore_group.argocd_admins[0].group_id, "")

    EKS_CAP_CODECOMMIT_REPO = local.eks_cap_codecommit_repo_name
    EKS_CAP_CODECOMMIT_URL  = "https://git-codecommit.${data.aws_region.current.id}.amazonaws.com/v1/repos/${local.eks_cap_codecommit_repo_name}"

    # Constructed rather than read from a data source, to keep this out of the
    # dev/operator paths' apply, which have no reason to describe the Auto Mode cluster.
    EKS_CLUSTER_AUTO_ARN = "arn:${var.addon_context.aws_partition_id}:eks:${data.aws_region.current.id}:${var.addon_context.aws_caller_identity_account_id}:cluster/${var.eks_cluster_auto_id}"
  }
}

# Only the capabilities path has an Identity Center group to look up. The dev and
# operator paths leave enable_eks_capabilities false, and this lookup would fail their
# apply in an account with no Identity Center instance.
data "aws_ssoadmin_instances" "main" {
  count = var.enable_eks_capabilities ? 1 : 0
}

data "aws_identitystore_group" "argocd_admins" {
  count = var.enable_eks_capabilities ? 1 : 0

  identity_store_id = tolist(data.aws_ssoadmin_instances.main[0].identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "${var.eks_cluster_id}-argocd-admins"
    }
  }
}

output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"

  # preprovision wins where it has a value, because it holds the ones that cannot be
  # derived. It contributes nothing at an event, which is exactly when the derived map
  # is the only source.
  value = merge(
    local.eks_cap_derived_environment,
    try(module.preprovision[0].environment_variables, {}),
  )
}
