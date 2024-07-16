provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ecrpublic_authorization_token" "token" { provider = aws.virginia }

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

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
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name                = var.addon_context.eks_cluster_id
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve                    = false
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.13.1"

  cluster_name                    = var.addon_context.eks_cluster_id
  enable_pod_identity             = true
  create_pod_identity_association = true
  namespace                       = "karpenter"

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "kubernetes_annotations" "disable_gp2" {
  annotations = {
    "storageclass.kubernetes.io/is-default-class" : "false"
  }
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }
  force = true

}

resource "kubernetes_storage_class" "default_gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" : "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    fsType    = "ext4"
    encrypted = true
    type      = "gp3"
  }

  depends_on = [kubernetes_annotations.disable_gp2]
}


resource "aws_prometheus_workspace" "eks_workshop_v2_amp" {
  alias = var.addon_context.eks_cluster_id
}

resource "time_sleep" "blueprints_addons_sleep" {
  depends_on = [
    module.eks_blueprints_addons
  ]
  create_duration = "10s"
}





data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

resource "aws_prometheus_scraper" "agentless_scraper" {
  source {
    eks {
      cluster_arn = "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.eks_cluster_id}"
      subnet_ids  = data.aws_subnets.private.ids
    }
  }
  destination {
    amp {
      workspace_arn = aws_prometheus_workspace.eks_workshop_v2_amp.arn
    }
  }
  scrape_configuration = <<EOT
global:
  scrape_interval: 30s
scrape_configs:
  # pod metrics
  - job_name: pod_exporter
    kubernetes_sd_configs:
      - role: pod
  # container metrics
  - job_name: cadvisor
    scheme: https
    authorization:
      credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - replacement: kubernetes.default.svc:443
        target_label: __address__
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor
  # apiserver metrics
  - bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    job_name: kubernetes-apiservers
    kubernetes_sd_configs:
    - role: endpoints
    relabel_configs:
    - action: keep
      regex: default;kubernetes;https
      source_labels:
      - __meta_kubernetes_namespace
      - __meta_kubernetes_service_name
      - __meta_kubernetes_endpoint_port_name
    scheme: https
  # kube proxy metrics
  - job_name: kube-proxy
    honor_labels: true
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - action: keep
      source_labels:
      - __meta_kubernetes_namespace
      - __meta_kubernetes_pod_name
      separator: '/'
      regex: 'kube-system/kube-proxy.+'
    - source_labels:
      - __address__
      action: replace
      target_label: __address__
      regex: (.+?)(\\:\\d+)?
      replacement: $1:10249
EOT
}


resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

module "eks_blueprints_kubernetes_grafana_addon" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/grafana"

  depends_on = [
    time_sleep.blueprints_addons_sleep,
    kubernetes_config_map.nvidia-dcgm-exporter-dashboard
  ]

  addon_context = var.addon_context

  irsa_policies = [
    aws_iam_policy.grafana.arn
  ]

  helm_config = {
    create_namespace = false
    namespace        = kubernetes_namespace.grafana.metadata[0].name

    values = [local.grafana_values]
  }
}

resource "kubernetes_config_map" "nvidia-dcgm-exporter-dashboard" {
  metadata {
    name      = "nvidia-dcgm-exporter-dashboard"
    namespace = kubernetes_namespace.grafana.metadata[0].name

    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "nvidia-dcgm-exporter-dashboard.json" =  file("~/environment/eks-workshop/modules/aiml/deploy-monitor-genai-model/grafana/nvidia-dcgm-exporter-dashboard.json")
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
serviceAccount:
  create: false
  name: grafana

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
      url: ${aws_prometheus_workspace.eks_workshop_v2_amp.prometheus_endpoint}
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
    - name: nvidia-dcgm-exporter-dashboard
      orgId: 1
      folder: "nvidia-dcgm-exporter-dashboard"
      type: file
      disableDeletion: false
      editable: false
      options:
        path: /var/lib/grafana/dashboards/nvidia-dcgm-exporter-dashboard  

dashboardsConfigMaps:
  nvidia-dcgm-exporter-dashboard: "nvidia-dcgm-exporter-dashboard"

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