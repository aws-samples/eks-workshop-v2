terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

data "aws_partition" "current" {}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name_prefix = "${var.addon_context.eks_cluster_id}-ebs-csi-"

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
  version = "1.16.3"

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
    wait = true
  }
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
  chart_version    = "v1.15.3"
  repository       = "https://charts.jetstack.io"

  set = [
    {
      name  = "crds.enabled"
      value = true
    }
  ]
}

module "opentelemetry_operator" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  depends_on = [
    module.cert_manager
  ]

  name             = "opentelemetry-operator"
  namespace        = "opentelemetry-operator-system"
  create_namespace = true
  wait             = true
  chart            = "opentelemetry-operator"
  chart_version    = var.opentelemetry_operator_chart_version
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"

  set = [{
    name  = "manager.collectorImage.repository"
    value = "otel/opentelemetry-collector-k8s"
  }]
}

module "iam_assumable_role_adot" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.44.0"

  create_role  = true
  role_name    = "${var.addon_context.eks_cluster_id}-adot-collector"
  provider_url = var.addon_context.eks_oidc_issuer_url
  role_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:other:adot-collector"]

  tags = var.tags
}

resource "aws_prometheus_workspace" "this" {
  alias = var.addon_context.eks_cluster_id

  tags = var.tags
}

module "loki" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  name             = "loki"
  namespace        = "loki-system"
  create_namespace = true
  wait             = true
  chart            = "loki"
  chart_version    = var.loki_chart_version
  repository       = "https://grafana.github.io/helm-charts"

  values = [
    <<-EOT
      deploymentMode: SingleBinary
      loki:
        auth_enabled: false
        commonConfig:
          replication_factor: 1
        storage:
          type: 'filesystem'
        schemaConfig:
          configs:
          - from: "2024-01-01"
            store: tsdb
            index:
              prefix: loki_index_
              period: 24h
            object_store: filesystem # we're storing on filesystem so there's no real persistence here.
            schema: v13
      singleBinary:
        replicas: 1
      read:
        replicas: 0
      backend:
        replicas: 0
      write:
        replicas: 0
      test:
        enabled: false
      lokiCanary:
        enabled: false
      chunksCache:
        enabled: false
      resultsCache:
        enabled: false
      gateway:
        enabled: false
    EOT
  ]
}

module "tempo" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  name             = "tempo"
  namespace        = "tempo-system"
  create_namespace = true
  wait             = true
  chart            = "tempo"
  chart_version    = var.tempo_chart_version
  repository       = "https://grafana.github.io/helm-charts"
}

module "grafana_operator" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  name             = "grafana-operator"
  namespace        = "grafana-operator-system"
  create_namespace = true
  wait             = true
  chart            = "grafana-operator"
  chart_version    = var.grafana_operator_chart_version
  repository       = "oci://ghcr.io/grafana/helm-charts"
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

module "grafana_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name_prefix = "${var.addon_context.eks_cluster_id}-grafana-"

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
  }

  oidc_providers = {
    main = {
      provider_arn               = var.addon_context.eks_oidc_provider_arn
      namespace_service_accounts = ["grafana:grafana-sa"]
    }
  }

  tags = var.tags
}

resource "kubectl_manifest" "grafana" {
  depends_on = [
    aws_prometheus_workspace.this,
    module.loki,
    module.tempo,
    module.grafana_operator
  ]

  yaml_body = <<-YAML
apiVersion: grafana.integreatly.org/v1beta1
kind: Grafana
metadata:
  name: grafana
  namespace: grafana
  labels:
    dashboards: "grafana"
spec:
  config:
    log:
      mode: "console"
    auth:
      disable_login_form: "false"
      sigv4_auth_enabled: "true"
    security:
      admin_user: root
      admin_password: secret
  deployment:
    spec:
      template:
        spec:
          containers:
            - name: grafana
              image: grafana/grafana:latest
  serviceAccount:
    metadata:
      annotations:
        eks.amazonaws.com/role-arn: ${module.grafana_irsa.iam_role_arn}
  ingress:
    metadata:
      annotations:
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
    spec:
      ingressClassName: alb
      rules:
        - http:
            paths:
              - backend:
                  service:
                    name: grafana-service
                    port:
                      number: 3000
                path: /
                pathType: Prefix
  YAML
}

resource "kubectl_manifest" "grafana_datasource_prometheus" {
  depends_on = [
    kubectl_manifest.grafana
  ]

  yaml_body = <<-YAML
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDatasource
metadata:
  name: prometheus
  namespace: grafana
spec:
  instanceSelector:
    matchLabels:
      dashboards: "grafana"
  datasource:
    uid: prometheus
    name: Prometheus
    type: prometheus
    access: proxy
    url: ${aws_prometheus_workspace.this.prometheus_endpoint}
    isDefault: true
    editable: false
    jsonData:
        httpMethod: "POST"
        sigV4AuthType: "default"
        sigV4Auth: true
        sigV4Region: ${var.addon_context.aws_region_name}
  YAML
}

resource "kubectl_manifest" "grafana_datasource_loki" {
  depends_on = [
    kubectl_manifest.grafana
  ]

  yaml_body = <<-YAML
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDatasource
metadata:
  name: loki
  namespace: grafana
spec:
  instanceSelector:
    matchLabels:
      dashboards: "grafana"
  datasource:
    uid: loki
    name: Loki
    type: loki
    access: proxy
    url: http://loki.loki-system:3100
    isDefault: false
    editable: false
  YAML
}

resource "kubectl_manifest" "grafana_datasource_tempo" {
  depends_on = [
    kubectl_manifest.grafana
  ]

  yaml_body = <<-YAML
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDatasource
metadata:
  name: tempo
  namespace: grafana
spec:
  instanceSelector:
    matchLabels:
      dashboards: "grafana"
  datasource:
    uid: tempo
    name: Tempo
    type: tempo
    access: proxy
    url: http://tempo.tempo-system:3100
    isDefault: false
    editable: false
  YAML
}

resource "kubectl_manifest" "grafana_dashboard_kubernetes_cluster" {
  depends_on = [
    kubectl_manifest.grafana_datasource_prometheus
  ]

  yaml_body = <<-YAML
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDashboard
metadata:
  name: kubernetes-cluster
  namespace: grafana
spec:
  folder: "Grafana"
  instanceSelector:
    matchLabels:
      dashboards: "grafana"
  grafanaCom:
    id: 3119
    revision: 2
  YAML
}

resource "kubectl_manifest" "config_map_order_service_metrics_dashboard" {
  yaml_body = templatefile("${path.module}/templates/order-service-metrics-dashboard.yaml", {})
}

resource "kubectl_manifest" "grafana_dashboard_order_service_metrics" {
  depends_on = [
    kubectl_manifest.grafana_datasource_prometheus,
    kubectl_manifest.config_map_order_service_metrics_dashboard
  ]

  yaml_body = <<-YAML
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDashboard
metadata:
  name: order-service-metrics
  namespace: grafana
spec:
  folder: "Grafana"
  instanceSelector:
    matchLabels:
      dashboards: "grafana"
  configMapRef:
    name: order-service-metrics-dashboard
    key: json
  YAML
}
