# Pre-provisioned resources for the Argo CD lab at a Workshop Studio event.
#
# Only `hack/pre-provision-resources.sh` applies this, which in practice means the
# Workshop Studio provisioning pipeline. The lab module deliberately does not declare
# a `module "preprovision"` block, so `prepare-environment` never applies it.
#
# Identity Center is not here. It is created once for the whole event by
# `manifests/.workshop/terraform/preprovision-base`, which the staging script applies
# before this and which no lab can reach by `source`. The marker file next to this
# comment (`.requires-idc`) is what asks for it.
#
# All that is left here is the capability itself, which takes around ten minutes to
# come up and so is worth doing while the event is still provisioning rather than on
# a participant's clock.
locals {
  # Convention, not an output. The base layer names the group after the environment,
  # and every consumer derives it the same way, so a lab's Terraform reads the same
  # whether the group was pre-provisioned or created by hand.
  idc_group_name = "${var.eks_cluster_id}-argocd-admins"
}

module "capability" {
  source = "./capability"

  eks_cluster_id = var.eks_cluster_id
  idc_group_name = local.idc_group_name
  tags           = var.tags
}
