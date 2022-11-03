module "helm_addon" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.13.1"

  helm_config = merge(
    {
      name        = local.name
      chart       = "${path.module}/otel-config"
      version     = "0.3.1"
      namespace   = local.namespace
      description = "ADOT helm Chart deployment configuration"
    },
    var.helm_config
  )

  set_values = [
    {
      name  = "ampurl"
      value = "https://aps-workspaces.${local.context.aws_region_name}.amazonaws.com/workspaces/${local.amp_ws_id}/api/v1/remote_write"
    },
    {
      name  = "region"
      value = local.context.aws_region_name 
    },
    {
      name  = "ekscluster"
      value = local.context.eks_cluster_id
    },
    {
      name  = "globalScrapeInterval"
      value = "60s"
    },
    {
      name  = "globalScrapeTimeout"
      value = "15s"
    },
    {
      name  = "accountId"
      value = local.context.aws_caller_identity_account_id
    },
  ]

  irsa_config = {
    create_kubernetes_namespace       = true
    kubernetes_namespace              = local.namespace
    create_kubernetes_service_account = true
    kubernetes_service_account        = try(var.helm_config.service_account, local.name)
    irsa_iam_policies                 = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"]
  }

  addon_context = local.context
}

resource "aws_prometheus_workspace" "this" {
  alias = local.ampname
}

resource "aws_grafana_workspace" "this" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.assume.arn
  name                     = local.amgname
}

resource "aws_iam_role" "assume" {
  name = "grafana-assume"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })
}