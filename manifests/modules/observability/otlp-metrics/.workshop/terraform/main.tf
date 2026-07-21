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
