data "aws_partition" "current" {}
data "aws_region" "current" {}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait        = true
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }

  observability_tag = null
}

resource "time_sleep" "blueprints_addons_sleep" {
  depends_on = [
    module.eks_blueprints_addons
  ]

  create_duration = "15s"
}

module "cert_manager" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  depends_on = [
    time_sleep.blueprints_addons_sleep
  ]

  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true
  chart            = "cert-manager"
  chart_version    = "v1.15.1"
  repository       = "https://charts.jetstack.io"

  set = [
    {
      name  = "crds.enabled"
      value = true
    }
  ]
}

resource "kubernetes_namespace" "opentelemetry_operator" {
  metadata {
    name = "opentelemetry-operator-system"
  }
}

module "opentelemetry_operator" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  depends_on = [
    module.cert_manager
  ]

  name             = "opentelemetry"
  namespace        = kubernetes_namespace.opentelemetry_operator.metadata[0].name
  create_namespace = false
  wait             = true
  chart            = "opentelemetry-operator"
  chart_version    = var.operator_chart_version
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"

  set = [{
    name  = "manager.collectorImage.repository"
    value = "otel/opentelemetry-collector-k8s"
  }]
}

module "iam_assumable_role_adot_ci" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "${var.addon_context.eks_cluster_id}-adot-collector-ci"
  provider_url                  = var.addon_context.eks_oidc_issuer_url
  role_policy_arns              = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:other:adot-collector-ci"]

  tags = var.tags
}

resource "aws_cloudwatch_dashboard" "order_metrics_ci" {
  dashboard_name = "Order-Service-Metrics-1"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 6,
          "width" : 6,
          "y" : 0,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [{ "expression" : "SELECT COUNT(watch_orders_total) FROM \"ContainerInsights/Prometheus\" WHERE productId != '*' GROUP BY productId", "id" : "q1", "region" : data.aws_region.current.name }]
            ],
            "view" : "pie",
            "region" : data.aws_region.current.name,
            "title" : "Orders by ProductId",
            "period" : 300,
            "stat" : "Average"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 0,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "sparkline" : true,
            "view" : "singleValue",
            "metrics" : [
              [{ "expression" : "SELECT SUM(watch_orders_total) FROM \"ContainerInsights/Prometheus\" WHERE productId = '*'", "label" : "Total", "id" : "q1" }]
            ],
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "period" : 300,
            "title" : "Order Count"
          }
        }
      ]
  })
}
