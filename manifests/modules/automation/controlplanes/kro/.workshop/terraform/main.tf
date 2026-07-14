terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}


module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.23.0"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait        = true
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  eks_addons = {
    eks-pod-identity-agent = {
      addon_version = "v1.1.0-eksbuild.1"
    }
  }

  observability_tag = null
}

resource "time_sleep" "blueprints_addons_sleep" {
  depends_on = [
    module.eks_blueprints_addons
  ]

  create_duration  = "15s"
  destroy_duration = "15s"
}

resource "kubernetes_manifest" "ui_alb" {
  depends_on = [time_sleep.blueprints_addons_sleep]

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
        "alb.ingress.kubernetes.io/inbound-cidrs"    = var.inbound_cidrs
      }
    }
    "spec" = {
      "ingressClassName" = "alb",
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

# EKS Capabilities run the ACK controllers in AWS-managed infrastructure and
# assume a dedicated IAM "capability role" trusted by the
# capabilities.eks.amazonaws.com service principal (instead of IRSA). Unlike the
# ACK lab, the kro lab drives THREE ACK controllers from its
# ResourceGraphDefinition, so the single capability role must be able to act as
# all three:
#   * DynamoDB  -> create/manage the carts Table
#   * IAM       -> create the Policy + Role the pods assume for table access
#   * EKS       -> create the Pod Identity Association that binds them
resource "aws_iam_role" "ack_capability" {
  name = "${var.addon_context.eks_cluster_id}-ack-capability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

# DynamoDB controller: manage the carts table this lab provisions.
resource "aws_iam_role_policy" "ack_capability_dynamodb" {
  name = "ack-dynamodb"
  role = aws_iam_role.ack_capability.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllAPIActionsOnCart"
        Effect = "Allow"
        Action = "dynamodb:*"
        Resource = [
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.carts_dynamo_table_name}",
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.carts_dynamo_table_name}/index/*"
        ]
      }
    ]
  })
}

# IAM controller: create/manage the Policy and Role the RGD generates for the
# carts pods, and pass that role to the Pod Identity Association.
resource "aws_iam_role_policy" "ack_capability_iam" {
  name = "ack-iam"
  role = aws_iam_role.ack_capability.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Role + inline/attached-policy actions the ACK iam-controller needs to
        # create, reconcile, and delete the Role its RGD defines. Mirrors the
        # role/policy subset of the ACK iam-controller recommended policy
        # (https://github.com/aws-controllers-k8s/iam-controller). Notably
        # includes the List/Get/Put/Delete RolePolicy actions the controller
        # uses when inspecting a role during reconciliation and deletion.
        Sid    = "ManageAckRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Sid    = "ManageAckPolicies"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:ListPolicyVersions",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:ListPolicyTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# EKS controller: create/manage the Pod Identity Association that lets the carts
# pods assume the RGD-generated role.
resource "aws_iam_role_policy" "ack_capability_eks" {
  name = "ack-eks"
  role = aws_iam_role.ack_capability.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManagePodIdentityAssociations"
        Effect = "Allow"
        Action = [
          "eks:CreatePodIdentityAssociation",
          "eks:DeletePodIdentityAssociation",
          "eks:DescribePodIdentityAssociation",
          "eks:UpdatePodIdentityAssociation",
          "eks:ListPodIdentityAssociations",
          "eks:TagResource",
          "eks:UntagResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# The managed ACK controllers authenticate to the cluster's Kubernetes API using
# a cluster access entry tied to the capability role. We manage this access
# entry (and the AWS-managed ACK access policy) explicitly in Terraform so it is
# always created and destroyed together with the role. Otherwise, tearing the
# lab down and recreating it leaves a stale access entry bound to the previous
# role, and the capability fails to start with an "Unauthorized" error.
resource "aws_eks_access_entry" "ack_capability" {
  cluster_name  = var.addon_context.eks_cluster_id
  principal_arn = aws_iam_role.ack_capability.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ack_capability" {
  cluster_name  = var.addon_context.eks_cluster_id
  principal_arn = aws_iam_role.ack_capability.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSACKPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ack_capability]
}

# IAM is eventually consistent, so allow the newly created capability role and
# its trust policy to propagate before EKS validates it during capability
# creation. Without this, CreateCapability can fail with an
# "invalid trust policy" error even though the policy is correct.
resource "time_sleep" "wait_for_capability_role" {
  depends_on = [
    aws_iam_role.ack_capability,
    aws_iam_role_policy.ack_capability_dynamodb,
    aws_iam_role_policy.ack_capability_iam,
    aws_iam_role_policy.ack_capability_eks,
  ]

  create_duration = "30s"
}

# Enable the fully managed AWS Controllers for Kubernetes (ACK) capability.
# Amazon EKS installs the ACK CRDs into the cluster as the capability becomes
# active; no controller is deployed into the cluster itself.
resource "aws_eks_capability" "ack" {
  cluster_name              = var.addon_context.eks_cluster_id
  capability_name           = "ack"
  type                      = "ACK"
  role_arn                  = aws_iam_role.ack_capability.arn
  delete_propagation_policy = "RETAIN"

  depends_on = [
    time_sleep.wait_for_capability_role,
    aws_eks_access_policy_association.ack_capability,
  ]

  tags = var.tags
}

# The kro capability runs the Kube Resource Orchestrator in AWS-managed
# infrastructure, replacing the previous in-cluster `helm install kro` step.
# Unlike ACK, the kro capability role needs NO IAM permissions -- kro only
# interacts with the Kubernetes API, so the role exists purely for the
# capabilities.eks.amazonaws.com trust relationship.
resource "aws_iam_role" "kro_capability" {
  name = "${var.addon_context.eks_cluster_id}-kro-capability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

# AmazonEKSKROPolicy lets the capability manage ResourceGraphDefinitions and
# their instances. EKS creates this access entry automatically, but we manage it
# in Terraform so it is created and destroyed together with the role and does not
# leave a stale entry across lab teardown/recreate cycles.
resource "aws_eks_access_entry" "kro_capability" {
  cluster_name  = var.addon_context.eks_cluster_id
  principal_arn = aws_iam_role.kro_capability.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "kro_capability" {
  cluster_name  = var.addon_context.eks_cluster_id
  principal_arn = aws_iam_role.kro_capability.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSKROPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.kro_capability]
}

# AmazonEKSKROPolicy only grants permission to manage RGDs themselves. To let kro
# create the underlying resources its RGDs define -- Deployments, Services, and
# the ACK custom resources (Table, Policy, Role, PodIdentityAssociation) -- the
# capability role needs broader cluster access. For this workshop we grant
# AmazonEKSClusterAdminPolicy, which AWS recommends for getting-started/dev
# scenarios. Production users should scope this to a custom RBAC policy.
resource "aws_eks_access_policy_association" "kro_capability_admin" {
  cluster_name  = var.addon_context.eks_cluster_id
  principal_arn = aws_iam_role.kro_capability.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.kro_capability]
}

# Allow the kro capability role to propagate before EKS validates it during
# capability creation (IAM is eventually consistent).
resource "time_sleep" "wait_for_kro_capability_role" {
  depends_on = [aws_iam_role.kro_capability]

  create_duration = "30s"
}

# Enable the fully managed Kube Resource Orchestrator (kro) capability. Amazon
# EKS installs the kro CRDs (ResourceGraphDefinition) into the cluster as the
# capability becomes active; no kro controller is deployed into the cluster.
resource "aws_eks_capability" "kro" {
  cluster_name              = var.addon_context.eks_cluster_id
  capability_name           = "kro"
  type                      = "KRO"
  role_arn                  = aws_iam_role.kro_capability.arn
  delete_propagation_policy = "RETAIN"

  depends_on = [
    time_sleep.wait_for_kro_capability_role,
    aws_eks_access_policy_association.kro_capability,
    aws_eks_access_policy_association.kro_capability_admin,
  ]

  tags = var.tags
}