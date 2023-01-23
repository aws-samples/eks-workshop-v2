data "aws_eks_addon_version" "latest" {
  for_each = toset(["vpc-cni"])

  addon_name         = each.value
  kubernetes_version = var.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name         = module.eks_blueprints.eks_cluster_id
  addon_name           = "vpc-cni"
  addon_version        = data.aws_eks_addon_version.latest["vpc-cni"].version
  resolve_conflicts    = "OVERWRITE"
  configuration_values = "{\"env\":{\"ENABLE_PREFIX_DELEGATION\":\"true\", \"ENABLE_POD_ENI\":\"true\"}}"

  depends_on = [
    null_resource.kubectl_set_env
  ]
}

locals {
  ebs_csi_blocker = try(module.eks_blueprints_kubernetes_addons.aws_ebs_csi_driver.release_metadata.metadata.status, "")
}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.16.0//modules/kubernetes-addons"

  depends_on = [
    aws_eks_addon.vpc_cni
  ]

  eks_cluster_id = module.eks_blueprints.eks_cluster_id

  enable_karpenter                       = true
  enable_aws_node_termination_handler    = true
  enable_aws_load_balancer_controller    = true
  enable_cluster_autoscaler              = true
  enable_metrics_server                  = true
  enable_kubecost                        = true
  enable_amazon_eks_adot                 = true
  enable_aws_efs_csi_driver              = true
  enable_aws_for_fluentbit               = true
  enable_self_managed_aws_ebs_csi_driver = true
  enable_crossplane                      = true

  self_managed_aws_ebs_csi_driver_helm_config = {
    set = [{
      name  = "node.tolerateAllTaints"
      value = "true"
      },
      {
        name  = "controller.replicaCount"
        value = 1
      },
      {
        name  = "controller.nodeSelector.workshop-system"
        value = "yes"
        type  = "string"
      },
      {
        name  = "controller.tolerations[0].key"
        value = "systemComponent"
        type  = "string"
      },
      {
        name  = "controller.tolerations[0].operator"
        value = "Exists"
        type  = "string"
      },
      {
        name  = "controller.tolerations[0].effect"
        value = "NoSchedule"
        type  = "string"
    }]
  }

  cluster_autoscaler_helm_config = {
    version   = var.helm_chart_versions["cluster_autoscaler"]
    namespace = "kube-system"

    set = concat([{
      name  = "image.tag"
      value = "v${var.cluster_version}.1"
      },
      {
        name  = "replicaCount"
        value = 0
      }],
    local.system_component_values)
  }

  metrics_server_helm_config = {
    version = var.helm_chart_versions["metrics_server"]

    set = concat([], local.system_component_values)
  }

  aws_load_balancer_controller_helm_config = {
    version   = var.helm_chart_versions["aws-load-balancer-controller"]
    namespace = "aws-load-balancer-controller"

    set = concat([{
      name  = "replicaCount"
      value = 1
      },
      {
        name  = "vpcId"
        value = module.aws_vpc.vpc_id
      }],
    local.system_component_values)
  }

  karpenter_helm_config = {
    version = "v${var.helm_chart_versions["karpenter"]}"
    timeout = 600

    set = concat([{
      name  = "replicas"
      value = "1"
      type  = "auto"
      },
      {
        name  = "aws.defaultInstanceProfile"
        value = module.eks_blueprints.managed_node_group_iam_instance_profile_id[0]
      },
      {
        name  = "controller.resources.requests.cpu"
        value = "300m"
        type  = "string"
      },
      {
        name  = "controller.resources.limits.cpu"
        value = "300m"
        type  = "string"
      }],
    local.system_component_values)
  }

  kubecost_helm_config = {
    set = concat([
      {
        name  = "blocker"
        value = local.ebs_csi_blocker
        type  = "string"
      },
      {
        name  = "prometheus.server.nodeSelector.workshop-system"
        value = "yes"
        type  = "string"
      },
      {
        name  = "prometheus.server.tolerations[0].key"
        value = "systemComponent"
        type  = "string"
      },
      {
        name  = "prometheus.server.tolerations[0].operator"
        value = "Exists"
        type  = "string"
      },
      {
        name  = "prometheus.server.tolerations[0].effect"
        value = "NoSchedule"
        type  = "string"
      },
      {
        name  = "prometheus.kube-state-metrics.nodeSelector.workshop-system"
        value = "yes"
        type  = "string"
      },
      {
        name  = "prometheus.kube-state-metrics.tolerations[0].key"
        value = "systemComponent"
        type  = "string"
      },
      {
        name  = "prometheus.kube-state-metrics.tolerations[0].operator"
        value = "Exists"
        type  = "string"
      },
      {
        name  = "prometheus.kube-state-metrics.tolerations[0].effect"
        value = "NoSchedule"
        type  = "string"
      },
      {
        name  = "prometheus.nodeExporter.tolerations[0].key"
        value = "systemComponent"
        type  = "string"
      },
      {
        name  = "prometheus.nodeExporter.tolerations[0].operator"
        value = "Exists"
        type  = "string"
      },
      {
        name  = "prometheus.nodeExporter.tolerations[0].effect"
        value = "NoSchedule"
        type  = "string"
      }],
    local.system_component_values)
  }

  aws_for_fluentbit_cw_log_group_name = "/${module.eks_blueprints.eks_cluster_id}/worker-fluentbit-logs-${random_string.fluentbit_log_group.result}"

  amazon_eks_adot_config = {
    kubernetes_version = var.cluster_version
  }

  crossplane_aws_provider = {
    enable                   = true
    provider_aws_version     = "v0.36.0"
    additional_irsa_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  }

  tags = local.tags
}

resource "random_string" "fluentbit_log_group" {
  length  = 6
  special = false
}

locals {
  oidc_url = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")

  addon_context = {
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_eks_cluster_endpoint       = data.aws_eks_cluster.cluster.endpoint
    aws_partition_id               = data.aws_partition.current.partition
    aws_region_name                = data.aws_region.current.id
    eks_cluster_id                 = module.eks_blueprints.eks_cluster_id
    eks_oidc_issuer_url            = local.oidc_url
    eks_oidc_provider_arn          = "arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:oidc-provider/${local.oidc_url}"
    irsa_iam_role_path             = "/"
    irsa_iam_permissions_boundary  = ""
    tags                           = {}
  }

  system_component_values = [{
    name  = "nodeSelector.workshop-system"
    value = "yes"
    type  = "string"
    },
    {
      name  = "tolerations[0].key"
      value = "systemComponent"
      type  = "string"
    },
    {
      name  = "tolerations[0].operator"
      value = "Exists"
      type  = "string"
    },
    {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
      type  = "string"
  }]
}

module "eks_blueprints_kubernetes_grafana_addon" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.16.0//modules/kubernetes-addons/grafana"

  depends_on = [
    module.eks_blueprints_kubernetes_addons
  ]

  addon_context = local.addon_context

  irsa_policies = [
    aws_iam_policy.grafana.arn
  ]

  helm_config = {
    values = [templatefile("${path.module}/templates/grafana.yaml", { prometheus_endpoint = aws_prometheus_workspace.this.prometheus_endpoint, region = data.aws_region.current.name })]
  }
}

resource "aws_iam_policy" "grafana" {
  name = "${var.environment_name}-grafana-other"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "aps:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "descheduler" {
  source = "../addons/descheduler"

  addon_context = local.addon_context

  helm_config = {
    set = concat([{
      name  = "blocker"
      value = local.ebs_csi_blocker
      type  = "string"
    }], local.system_component_values)
  }
}
