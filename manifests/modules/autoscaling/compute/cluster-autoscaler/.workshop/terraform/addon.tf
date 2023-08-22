module "cluster-autoscaler" {
  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/cluster-autoscaler"
  addon_context = merge(local.addon_context, { default_repository = local.amazon_container_image_registry_uris[data.aws_region.current.name] })

  eks_cluster_version = local.eks_cluster_version
}
