#-------------------------------------
# Helm Add-on
#-------------------------------------

module "helm_addon" {
  source            = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.0.1"
  manage_via_gitops = false
  helm_config       = local.helm_config
  irsa_config       = null
  addon_context     = var.addon_context

  # depends_on = [kubernetes_namespace_v1.this]
}

#-------------------------------------
# Helm Namespace
#-------------------------------------

# resource "kubernetes_namespace_v1" "this" {
#   metadata {
#     name = local.helm_config["namespace"]
#   }
# }