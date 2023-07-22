module "adot-operator" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/opentelemetry-operator"

  addon_config = {
    kubernetes_version = local.eks_cluster_version
    preserve           = false
  }

  addon_context = local.addon_context
}

module "iam_assumable_role_adot_ci" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v5.5.0"
  create_role                   = true
  role_name                     = "${local.addon_context.eks_cluster_id}-adot-collector-ci"
  provider_url                  = local.addon_context.eks_oidc_issuer_url
  role_policy_arns              = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:other:adot-collector-ci"]

  tags = local.tags
}

output "environment" {
  value = <<EOF
export ADOT_IAM_ROLE_CI="${module.iam_assumable_role_adot_ci.iam_role_arn}"
EOF
}
