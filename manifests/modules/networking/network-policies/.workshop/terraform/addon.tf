module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "1.9.2"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }

  cluster_name      = local.eks_cluster_id
  cluster_endpoint  = local.eks_cluster_endpoint
  cluster_version   = local.eks_cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn
}

#resource "aws_eks_addon" "vpc-cni" {
#  cluster_name                = local.eks_cluster_id
#  addon_name                  = "vpc-cni"
#  resolve_conflicts_on_update = "PRESERVE"
#  addon_version               = "v1.14.1-eksbuild.1"

#  configuration_values = "{\"env\":{\"ENABLE_PREFIX_DELEGATION\":\"true\", \"ENABLE_POD_ENI\":\"true\", \"POD_SECURITY_GROUP_ENFORCING_MODE\":\"standard\"},\"enableNetworkPolicy\": \"true\",\"nodeAgent\": {\"enableCloudWatchLogs\": \"true\", \"healthProbeBindAddr\": \"8163\", \"metricsBindAddr\": \"8162\" }}"
#}

data "aws_eks_addon" "vpc_cni_addon" {
  addon_name   = "vpc-cni"
  cluster_name = local.eks_cluster_id
}

resource "aws_iam_policy" "addon_cwlogs_policy" {
  name        = "addon.cwlogs.allow"
  description = "Addon CloudWatch policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:DescribeLogGroups",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "addon_cwlogs_policy_attach" {
  role       = split("/","${data.aws_eks_addon.vpc_cni_addon.service_account_role_arn}")[1]
  policy_arn = "${aws_iam_policy.addon_cwlogs_policy.arn}"
}