module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }

  cluster_name      = local.addon_context.eks_cluster_id
  cluster_endpoint  = local.addon_context.aws_eks_cluster_endpoint
  cluster_version   = local.eks_cluster_version
  oidc_provider_arn = local.addon_context.eks_oidc_provider_arn
}

module "iam_assumable_role_lattice" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v5.5.5"
  create_role                   = true
  role_name                     = "${local.addon_context.eks_cluster_id}-lattice"
  provider_url                  = local.addon_context.eks_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.lattice.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:gateway-api-controller:gateway-api-controller"]

  tags = local.tags
}

resource "aws_iam_policy" "lattice" {
  name        = "${local.addon_context.eks_cluster_id}-lattice"
  path        = "/"
  description = "Policy for Lattice controller"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "vpc-lattice:*",
                "iam:CreateServiceLinkedRole",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags"
            ],
            "Resource": "*"
        }
    ]
}
EOF
  tags   = local.tags
}

output "environment" {
  value = <<EOF
export LATTICE_IAM_ROLE="${module.iam_assumable_role_lattice.iam_role_arn}"
EOF
}
