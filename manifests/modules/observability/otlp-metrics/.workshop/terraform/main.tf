data "aws_partition" "current" {}
data "aws_region" "current" {}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.23.0"

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

resource "aws_eks_addon" "pod_identity" {
  cluster_name                = var.addon_context.eks_cluster_id
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve                    = false
}

# IAM role for the CloudWatch Observability add-on (Pod Identity)
resource "aws_iam_role" "cloudwatch_observability" {
  name = "${var.addon_context.eks_cluster_id}-cw-observability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_observability" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_pod_identity_association" "cloudwatch_observability" {
  cluster_name    = var.addon_context.eks_cluster_id
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cloudwatch_observability.arn

  depends_on = [aws_eks_addon.pod_identity]
}

resource "aws_eks_addon" "amazon_cloudwatch_observability" {
  cluster_name                = var.addon_context.eks_cluster_id
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"

  configuration_values = jsonencode({
    otelContainerInsights = {
      enabled = true
      logs = {
        enabled = false
      }
    }
    containerLogs = {
      enabled = false
    }
    applicationSignals = {
      enabled = false
    }
  })

  depends_on = [aws_eks_pod_identity_association.cloudwatch_observability]
}

# Enable resource tags on telemetry (account-level prerequisite for OTel enrichment)
resource "terraform_data" "telemetry_enrichment" {
  provisioner "local-exec" {
    command = "aws observabilityadmin start-telemetry-enrichment"
  }
}

# Enable OTel enrichment for AWS vended metrics (makes them queryable via PromQL with resource tags)
resource "terraform_data" "otel_enrichment" {
  depends_on = [terraform_data.telemetry_enrichment]

  provisioner "local-exec" {
    command = "aws cloudwatch start-otel-enrichment"
  }
}

resource "time_sleep" "blueprints_addons_sleep" {
  depends_on = [
    module.eks_blueprints_addons,
  ]

  create_duration = "15s"
}

# Grafana setup with CloudWatch OTLP metrics as Prometheus-compatible data source

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

module "grafana" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  depends_on = [
    time_sleep.blueprints_addons_sleep,
    kubernetes_config_map.order_service_metrics_dashboard
  ]

  description      = "Grafana"
  chart            = "grafana"
  chart_version    = var.grafana_chart_version
  namespace        = kubernetes_namespace.grafana.metadata[0].name
  create_namespace = false
  repository       = "https://grafana.github.io/helm-charts"
  values           = [local.grafana_values]
  wait             = true
  set = [{
    name  = "serviceAccount.name"
    value = "grafana"
  }]

  create_role             = true
  role_name               = "${var.addon_context.eks_cluster_id}-grafana"
  policy_name             = "${var.addon_context.eks_cluster_id}-grafana"
  source_policy_documents = [data.aws_iam_policy_document.grafana.json]
  set_irsa_names = [
    "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn",
  ]
  oidc_providers = {
    this = {
      provider_arn    = var.addon_context.eks_oidc_provider_arn
      service_account = "grafana"
    }
  }
}

resource "kubernetes_config_map" "order_service_metrics_dashboard" {
  metadata {
    name      = "order-service-metrics-dashboard"
    namespace = kubernetes_namespace.grafana.metadata[0].name

    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "order-service-metrics-dashboard.json" = <<EOF
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "panels": [
    {
      "datasource": {
        "type": "grafana-amazonprometheus-datasource",
        "uid": "$${datasource}"
      },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "palette-classic" },
          "custom": { "hideFrom": { "legend": false, "tooltip": false, "viz": false } },
          "mappings": []
        }
      },
      "gridPos": { "h": 9, "w": 9, "x": 0, "y": 0 },
      "id": 2,
      "options": {
        "legend": { "displayMode": "list", "placement": "bottom", "showLegend": true },
        "pieType": "pie",
        "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false }
      },
      "targets": [
        {
          "datasource": { "type": "grafana-amazonprometheus-datasource", "uid": "$${datasource}" },
          "editorMode": "code",
          "expr": "sum by(productId) (watch_orders_total{productId!=\"*\"})",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Orders by Product",
      "type": "piechart"
    },
    {
      "datasource": {
        "type": "grafana-amazonprometheus-datasource",
        "uid": "$${datasource}"
      },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "mappings": [],
          "thresholds": { "mode": "absolute", "steps": [{ "color": "green", "value": null }] }
        }
      },
      "gridPos": { "h": 9, "w": 6, "x": 9, "y": 0 },
      "id": 6,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false }
      },
      "targets": [
        {
          "datasource": { "type": "grafana-amazonprometheus-datasource", "uid": "$${datasource}" },
          "editorMode": "code",
          "expr": "sum(watch_orders_total{productId=\"*\"}) by (productId)",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Order Count",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "grafana-amazonprometheus-datasource",
        "uid": "$${datasource}"
      },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "palette-classic" },
          "custom": {
            "drawStyle": "line",
            "fillOpacity": 0,
            "lineWidth": 1,
            "pointSize": 5,
            "showPoints": "auto"
          },
          "mappings": [],
          "thresholds": { "mode": "absolute", "steps": [{ "color": "green", "value": null }] }
        }
      },
      "gridPos": { "h": 8, "w": 15, "x": 0, "y": 9 },
      "id": 4,
      "options": {
        "legend": { "displayMode": "list", "placement": "bottom", "showLegend": true }
      },
      "targets": [
        {
          "datasource": { "type": "grafana-amazonprometheus-datasource", "uid": "$${datasource}" },
          "editorMode": "code",
          "expr": "sum by (productId)(rate(watch_orders_total{productId=\"*\"}[2m]))",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Order Rate",
      "type": "timeseries"
    }
  ],
  "schemaVersion": 37,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": [
      {
        "current": {},
        "hide": 0,
        "includeAll": false,
        "label": "Data Source",
        "multi": false,
        "name": "datasource",
        "options": [],
        "query": "grafana-amazonprometheus-datasource",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "type": "datasource"
      }
    ]
  },
  "time": { "from": "now-3h", "to": "now" },
  "title": "Order Service Metrics",
  "uid": "otlp-orders",
  "version": 1
}
EOF
  }
}

data "aws_iam_policy_document" "grafana" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:GetMetricData",
      "cloudwatch:ListMetrics",
      "cloudwatch:QueryMetrics",
    ]
  }
}

locals {
  grafana_values = <<EOF
image:
  tag: "12.1.7"

env:
  AWS_SDK_LOAD_CONFIG: true
  GF_AUTH_SIGV4_AUTH_ENABLED: true
  GF_INSTALL_PLUGINS: grafana-amazonprometheus-datasource 3.0.0

ingress:
  enabled: true
  hosts: []
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/inbound-cidrs: ${var.inbound_cidrs}
  ingressClassName: alb

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: orders-service
      orgId: 1
      folder: "retail-app-metrics"
      type: file
      disableDeletion: false
      editable: false
      options:
        path: /var/lib/grafana/dashboards/orders-service

dashboardsConfigMaps:
  orders-service: "order-service-metrics-dashboard"

sidecar:
  dashboards:
    enabled: true
    searchNamespace: ALL
    label: app.kubernetes.io/component
    labelValue: grafana
EOF
}