module "iam_assumable_role_adot_ci" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v5.5.0"
  create_role                   = true
  role_name                     = "${var.environment_name}-adot-collector-ci"
  provider_url                  = local.oidc_url
  role_policy_arns              = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:other:adot-collector-ci"]

  tags = local.tags
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

module "eks_blueprints_kubernetes_grafana_addon" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.16.0//modules/kubernetes-addons/grafana"

  depends_on = [
    module.eks_blueprints_kubernetes_addons,
    kubernetes_config_map.order-service-metrics-dashboard
  ]

  addon_context = local.addon_context

  irsa_policies = [
    aws_iam_policy.grafana.arn
  ]

  helm_config = {
    create_namespace = false
    namespace        = kubernetes_namespace.grafana.metadata[0].name

    values = [templatefile("${path.module}/templates/grafana.yaml", { prometheus_endpoint = aws_prometheus_workspace.this.prometheus_endpoint, region = data.aws_region.current.name })]
  }
}

resource "kubernetes_config_map" "order-service-metrics-dashboard" {
  metadata {
    name      = "order-service-metrics-dashboard"
    namespace = kubernetes_namespace.grafana.metadata[0].name

    labels = {
      grafana_dashboard = 1
    }
  }
  
  data = {
    "order-service-metrics-dashboard.json" = file("${path.module}/templates/dashboards/order-service-metrics-dashboard.json")
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