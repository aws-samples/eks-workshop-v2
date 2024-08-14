module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_aws_load_balancer_controller = true
  create_kubernetes_resources         = false

}


// ALB creation
resource "kubernetes_manifest" "ui_alb" {
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "name"      = "ui"
      "namespace" = "ui"
      "annotations" = {
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/actuator/health/liveness"
      }
    }
    "spec" = {
      ingressClassName = "alb",
      "rules" = [{
        "http" = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            "backend" = {
              service = {
                name = "ui"
                port = {
                  number = 80
                }
              }
            }
          }]
        }
      }]
    }
  }
}

// Create RBAC and Rolebinding
resource "kubernetes_role" "chaos_mesh_role" {
  metadata {
    name      = "chaos-mesh-role"
    namespace = "ui"
  }

  rule {
    api_groups = ["chaos-mesh.org"]
    resources  = ["podchaos"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
}

data "aws_caller_identity" "current" {}

resource "kubernetes_role_binding" "chaos_mesh_rolebinding" {
  metadata {
    name      = "chaos-mesh-rolebinding"
    namespace = "ui"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.chaos_mesh_role.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = data.aws_caller_identity.current.arn
    namespace = "ui"
  }
}

// Add AWS Load Balancer controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.load_balancer_controller_chart_version

  set {
    name  = "clusterName"
    value = var.addon_context.eks_cluster_id
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller-sa"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
  }
}


// Chaos Mesh Helm Release
resource "helm_release" "chaos_mesh" {
  name       = "chaos-mesh"
  repository = "https://charts.chaos-mesh.org"
  chart      = "chaos-mesh"
  namespace  = "chaos-mesh"
  version    = "2.5.1"

  create_namespace = true
}

// FIS IAM role
resource "random_id" "suffix" {
  byte_length = 8
}

resource "aws_iam_role" "fis_role" {
  name = "fis-execution-role-${var.addon_context.eks_cluster_id}-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "fis.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Federated = var.addon_context.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${trimprefix(var.addon_context.eks_oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/")}:sub" = [
              "system:serviceaccount:ui:chaos-mesh-sa"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [kubernetes_role_binding.chaos_mesh_rolebinding]
}

// Attach FIS Access Policy
resource "aws_iam_role_policy_attachment" "fis_eks_access" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorEKSAccess"
  role       = aws_iam_role.fis_role.name
}

resource "aws_iam_role_policy_attachment" "fis_network_access" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorNetworkAccess"
  role       = aws_iam_role.fis_role.name
}

// Policy for creating FIS experiment templates
resource "aws_iam_policy" "eks_resiliency_fis_policy" {
  name        = "eks-resiliency-fis-policy-${random_id.suffix.hex}"
  path        = "/"
  description = "Custom policy for EKS resiliency FIS experiments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          // FIS
          "fis:CreateExperimentTemplate",
          "fis:GetExperimentTemplate",
          "fis:ListExperimentTemplates",
          "fis:DeleteExperimentTemplate",
          "fis:UpdateExperimentTemplate",
          "fis:TagResource",
          "fis:UntagResource",
          "fis:StartExperiment",
          "fis:GetExperiment",
          "fis:ListExperiments",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:TerminateInstances",
          "eks:DescribeCluster",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:SetDesiredCapacity",
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          // Synthetic Canary
          "synthetics:CreateCanary",
          "synthetics:DeleteCanary",
          "synthetics:DescribeCanaries",
          "synthetics:StartCanary",
          "synthetics:StopCanary",
          "synthetics:UpdateCanary",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListAllMyBuckets",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.fis_role.arn
      }
    ]
  })
}

// Attach custom policy to the role
resource "aws_iam_role_policy_attachment" "eks_resiliency_fis_policy_attachment" {
  policy_arn = aws_iam_policy.eks_resiliency_fis_policy.arn
  role       = aws_iam_role.fis_role.name
}
