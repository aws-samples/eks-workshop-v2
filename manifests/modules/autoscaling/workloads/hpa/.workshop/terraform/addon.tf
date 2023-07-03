module "metrics-server" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/metrics-server"

  addon_context = local.addon_context
}
