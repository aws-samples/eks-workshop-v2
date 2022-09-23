resource "kubernetes_namespace" "workshop_system" {
  metadata {
    name = "workshop-system"
  }
}

module "eks-blueprints-kubernetes-addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.10.0//modules/kubernetes-addons"

  eks_cluster_id = module.aws-eks-accelerator-for-terraform.eks_cluster_id

  enable_karpenter                     = true
  enable_aws_node_termination_handler  = true
  enable_aws_load_balancer_controller  = true
  enable_cluster_autoscaler            = true
  enable_metrics_server                = true
  enable_amazon_eks_aws_ebs_csi_driver = true
  enable_kubecost                      = true

  cluster_autoscaler_helm_config = {
    version   = var.helm_chart_versions["cluster_autoscaler"]
    namespace = "kube-system"

    set = [
      {
        name  = "image.tag"
        value = "v${var.cluster_version}.1"
      },
      {
        name  = "replicaCount"
        value = 0
      },
      {
        name  = "podLabels.fargate"
        value = "yes"
      }
    ]
  }

  metrics_server_helm_config = {
    version = var.helm_chart_versions["metrics_server"]
  }

  aws_load_balancer_controller_helm_config = {
    version   = var.helm_chart_versions["aws-load-balancer-controller"]
    namespace = "aws-load-balancer-controller"

    set = [
      {
        name  = "replicaCount"
        value = 1
      },
      {
        name  = "vpcId"
        value = module.aws_vpc.vpc_id
      },
      {
        name  = "podLabels.fargate"
        value = "yes"
      }
    ]
  }

  karpenter_helm_config = {
    version = var.helm_chart_versions["karpenter"]
    timeout = 600

    set = [
      {
        name  = "aws.defaultInstanceProfile"
        value = module.aws-eks-accelerator-for-terraform.managed_node_group_iam_instance_profile_id[0]
      },
      {
        name  = "podLabels.fargate"
        value = "yes"
      }
    ]
  }
}

locals {
  oidc_url = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")

  addon_context = {
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_eks_cluster_endpoint       = data.aws_eks_cluster.cluster.endpoint
    aws_partition_id               = data.aws_partition.current.partition
    aws_region_name                = data.aws_region.current.id
    eks_cluster_id                 = module.aws-eks-accelerator-for-terraform.eks_cluster_id
    eks_oidc_issuer_url            = local.oidc_url
    eks_oidc_provider_arn          = "arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:oidc-provider/${local.oidc_url}"
    tags                           = {}
  }
}

module "descheduler" {
  source        = "../addons/descheduler"
  addon_context = local.addon_context
}

