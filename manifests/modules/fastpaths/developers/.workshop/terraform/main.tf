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

  # Empty string means "use the preprovision module's default placeholder".
  # The preprovision module's default is a non-deliverable placeholder that's
  # fine for the OTP activation flow; learners only need to override this if
  # they prefer the email-link activation flow.
  argocd_admin_email = var.argocd_admin_email != "" ? var.argocd_admin_email : "argocd-admin@example.com"
}
