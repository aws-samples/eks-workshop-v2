module "preprovision" {
  source = "./preprovision"
  count  = var.resources_precreated ? 0 : 1

  providers = {
    helm.auto_mode       = helm.auto_mode
    kubernetes.auto_mode = kubernetes.auto_mode
  }

  eks_cluster_id      = var.eks_cluster_id
  eks_cluster_auto_id = var.eks_cluster_auto_id
  tags                = var.tags
  inbound_cidrs       = var.inbound_cidrs

  # Defaults to a non-deliverable placeholder (set in base.tf) that's fine for
  # the OTP activation flow; learners only override this if they prefer the
  # email-link activation flow.
  argocd_admin_email = var.argocd_admin_email
}
