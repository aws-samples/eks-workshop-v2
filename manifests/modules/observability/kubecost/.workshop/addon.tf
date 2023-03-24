module "aws-ebs-csi-driver" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/aws-ebs-csi-driver"

  enable_amazon_eks_aws_ebs_csi_driver = true

  addon_config = {
    kubernetes_version = local.eks_cluster_version
    preserve           = false
  }

  addon_context = local.addon_context
}

module "aws-load-balancer-controller" {
  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/aws-load-balancer-controller"
  addon_context = merge(local.addon_context, { default_repository = local.amazon_container_image_registry_uris[data.aws_region.current.name] })
}

module "kubecost" {
  depends_on = [
    module.aws-ebs-csi-driver,
    module.aws-load-balancer-controller
  ]

  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/kubecost"
  addon_context = local.addon_context
}
