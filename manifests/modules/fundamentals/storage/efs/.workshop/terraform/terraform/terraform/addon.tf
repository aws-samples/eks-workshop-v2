module "aws-efs-csi-driver" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/aws-efs-csi-driver"

  addon_context = local.addon_context
}
