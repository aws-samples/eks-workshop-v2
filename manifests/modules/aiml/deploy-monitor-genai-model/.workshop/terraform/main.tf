provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
    }
  }
}

locals {
  namespace = "kube-system"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ecrpublic_authorization_token" "token" { provider = aws.virginia }

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

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
    wait        = true
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }
}

resource "time_sleep" "wait" {
  depends_on = [
    module.eks_blueprints_addons
  ]

  create_duration = "10s"
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

resource "aws_eks_addon" "pod_identity" {
  cluster_name                = var.addon_context.eks_cluster_id
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve                    = false
}

# Karpenter controller & Node IAM roles, SQS Queue, Eventbridge Rules

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.24.0"

  cluster_name          = var.addon_context.eks_cluster_id
  enable_v1_permissions = true
  namespace             = local.namespace

  iam_role_name                   = "${var.addon_context.eks_cluster_id}-karpenter-controller"
  iam_role_use_name_prefix        = false
  iam_policy_name                 = "${var.addon_context.eks_cluster_id}-karpenter-controller"
  iam_policy_use_name_prefix      = false
  node_iam_role_name              = "${var.addon_context.eks_cluster_id}-karpenter-node"
  node_iam_role_use_name_prefix   = false
  queue_name                      = "${var.addon_context.eks_cluster_id}-karpenter"
  rule_name_prefix                = "eks-workshop"
  create_pod_identity_association = true

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

# Helm chart

resource "helm_release" "karpenter" {
  name                = "karpenter"
  namespace           = local.namespace
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = var.karpenter_version
  wait                = true

  values = [
    <<-EOT
    settings:
      clusterName: ${var.addon_context.eks_cluster_id}
      clusterEndpoint: ${var.addon_context.aws_eks_cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}

resource "kubectl_manifest" "g5_gpu_karpenter_nodepool" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: g5-gpu-karpenter
spec:
  template:
    metadata:
      labels:
        type: karpenter
        NodeGroupType: g5-gpu-karpenter
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: g5-gpu-karpenter    
      taints:
      - key: "nvidia.com/gpu"
        value: "true"
        effect: "NoSchedule"
      requirements:
        - key: "karpenter.k8s.aws/instance-family"
          operator: In
          values: ["g5"]
        - key: "karpenter.k8s.aws/instance-size"
          operator: In
          values: [ "2xlarge", "4xlarge", "8xlarge" ]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand"]
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 300s
    expireAfter: 720h

YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "g5_gpu_karpenter_ec2nodeclass" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: g5-gpu-karpenter
spec:
  amiFamily: AL2023
  amiSelectorTerms:
    - alias: al2023@latest
  role: ${module.karpenter.node_iam_role_arn}
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: $EKS_CLUSTER_NAME
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: $EKS_CLUSTER_NAME
  blockDeviceMappings:
  - deviceName: /dev/xvda
    ebs:
      volumeSize: 100Gi
      volumeType: gp3

YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "x86_cpu_karpenter_nodepool" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: x86-cpu-karpenter
spec:
  template:
    metadata:
      labels:
        type: karpenter
        NodeGroupType: x86-cpu-karpenter
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: x86-cpu-karpenter
      requirements:
        - key: "karpenter.k8s.aws/instance-family"
          operator: In
          values: ["m5"]
        - key: "karpenter.k8s.aws/instance-size"
          operator: In
          values: [ "xlarge", "2xlarge", "4xlarge", "8xlarge"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand"]
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 300s
    expireAfter: 720h

YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "x86_cpu_karpenter_ec2nodeclass" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: x86-cpu-karpenter
spec:
  amiFamily: AL2023
  amiSelectorTerms:
    - alias: al2023@latest
  role: ${module.karpenter.node_iam_role_arn}
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: $EKS_CLUSTER_NAME
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: $EKS_CLUSTER_NAME
  blockDeviceMappings:
  - deviceName: /dev/xvda
    ebs:
      volumeSize: 100Gi
      volumeType: gp3  

YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "aws_prometheus_workspace" "eks_workshop_v2_amp" {
  alias = var.addon_context.eks_cluster_id

  tags = var.tags
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
  tags = var.tags

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
    kubernetes_config_map.nvidia_dcgm_exporter_dashboard
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

resource "kubernetes_config_map" "nvidia_dcgm_exporter_dashboard" {
  metadata {
    name      = "nvidia-dcgm-exporter-dashboard"
    namespace = kubernetes_namespace.grafana.metadata[0].name

    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "nvidia-dcgm-exporter-dashboard.json" =  file("${path.module}/nvidia-dcgm-exporter-dashboard.json")
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
    - name: gpu-metrics
      orgId: 1
      folder: gpu-metrics
      type: file
      disableDeletion: false
      editable: false
      options:
        path: /var/lib/grafana/dashboards/gpu-metrics

dashboardsConfigMaps:
  gpu-metrics: "nvidia-dcgm-exporter-dashboard"

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