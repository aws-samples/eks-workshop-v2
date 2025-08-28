data "aws_partition" "current" {}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix   = "${var.addon_context.eks_cluster_id}-ebs-csi-"
  policy_name_prefix = "${var.addon_context.eks_cluster_id}-ebs-csi-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      preserve                 = false
      configuration_values     = jsonencode({ defaultStorageClass = { enabled = true } })
    }
  }

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

resource "aws_prometheus_workspace" "this" {
  alias = var.addon_context.eks_cluster_id

  tags = var.tags
}

module "iam_assumable_role_adot" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.60.0"

  create_role  = true
  role_name    = "${var.addon_context.eks_cluster_id}-adot-collector"
  provider_url = var.addon_context.eks_oidc_issuer_url
  role_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:other:adot-collector"]

  tags = var.tags
}

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
  chart_version    = "6.43.1"
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
      provider_arn = var.addon_context.eks_oidc_provider_arn
      # namespace is inherited from chart
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
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "target": {
          "limit": 100,
          "matchAny": false,
          "tags": [],
          "type": "dashboard"
        },
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            }
          },
          "mappings": []
        },
        "overrides": []
      },
      "gridPos": {
        "h": 9,
        "w": 9,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "options": {
        "legend": {
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "pieType": "pie",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "editorMode": "builder",
          "expr": "sum by(productId) (watch_orders_total{productId!=\"*\"})",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Orders by Product ",
      "type": "piechart"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 9,
        "w": 6,
        "x": 9,
        "y": 0
      },
      "id": 6,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "pluginVersion": "9.2.2",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
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
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 15,
        "x": 0,
        "y": 9
      },
      "id": 4,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
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
    "list": []
  },
  "time": {
    "from": "now-3h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Order Service Metrics",
  "uid": "r7QHEZEVz",
  "version": 1,
  "weekStart": ""
}
EOF
  }
}

data "aws_iam_policy_document" "grafana" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["aps:*"]
  }
}

resource "aws_iam_policy" "grafana" {
  name = "${var.addon_context.eks_cluster_id}-grafana-other"

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

locals {
  grafana_values = <<EOF
env:
  AWS_SDK_LOAD_CONFIG: true
  GF_AUTH_SIGV4_AUTH_ENABLED: true

ingress:
  enabled: true
  hosts: []
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
  ingressClassName: alb

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: ${aws_prometheus_workspace.this.prometheus_endpoint}
      access: proxy
      jsonData:
        httpMethod: "POST"
        sigV4Auth: true
        sigV4AuthType: "default"
        sigV4Region: ${var.addon_context.aws_region_name}
      isDefault: true

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: default
      orgId: 1
      folder: ""
      type: file
      disableDeletion: false
      editable: false
      options:
        path: /var/lib/grafana/dashboards/default
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

dashboards:
  default:
    kubernetesCluster:
      gnetId: 3119
      revision: 2
      datasource: Prometheus

sidecar:
  dashboards:
    enabled: true
    searchNamespace: ALL
    label: app.kubernetes.io/component
    labelValue: grafana
EOF
}
