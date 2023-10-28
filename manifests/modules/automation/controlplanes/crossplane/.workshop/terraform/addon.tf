resource "terraform_data" "cluster" {
  provisioner "local-exec" {
    command = <<EOF
echo "ASDASD"
EOF
  }
}

module "crossplane" {
  depends_on = [
    terraform_data.cluster
  ]

  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.0"

  create = true

  # https://github.com/crossplane/crossplane/tree/master/cluster/charts/crossplane
  name             = "crossplane"
  description      = "A Helm chart to deploy crossplane project"
  namespace        = "crossplane-system"
  create_namespace = true
  chart            = "crossplane"
  chart_version    = "1.13.2"
  repository       = "https://charts.crossplane.io/stable/"
  values           = templatefile("${path.module}/templates/crossplane.yaml", [])
  

  upbound_aws_provider = {
    enable               = true
    version              = "v0.40.0"
    provider_config_name = "aws-provider-config" 
    families = [
      "dynamodb"
    ]
  }

  aws_provider = {
    enable                   = false
    provider_aws_version     = "v0.40.0"
    additional_irsa_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  }

  kubernetes_provider = {
    enable = false
  }

  helm_provider = {
    enable = false
  }

  jet_aws_provider = {
    enable = false

    additional_irsa_policies = []
    provider_aws_version     = ""
  }

  upbound_aws_provider = {
    enable = false
  }
}

resource "kubectl_manifest" "upbound_aws_controller_config" {
  count = local.upbound_aws_provider.enable == true ? 1 : 0
  yaml_body = templatefile("${path.module}/providers/aws-upbound/controller-config.yaml", {
    iam-role-arn          = module.upbound_irsa_aws[0].iam_role_arn
    controller-config = local.upbound_aws_provider.controller_config
  })

  depends_on = [module.crossplane]
}

resource "kubectl_manifest" "upbound_aws_provider" {
  for_each = local.upbound_aws_provider.enable ? toset(local.upbound_aws_provider.families) : toset([])
  yaml_body = templatefile("${path.module}/providers/aws-upbound/provider.yaml", {
    family            = each.key
    version           = local.upbound_aws_provider.version
    controller-config = local.upbound_aws_provider.controller_config
  })
  wait = true

  depends_on = [kubectl_manifest.upbound_aws_controller_config]
}

# Wait for the Upbound AWS Provider CRDs to be fully created before initiating upbound_aws_provider_config
resource "time_sleep" "upbound_wait_60_seconds" {
  count           = local.upbound_aws_provider.enable == true ? 1 : 0
  create_duration = "60s"

  depends_on = [kubectl_manifest.upbound_aws_provider]
}

resource "kubectl_manifest" "upbound_aws_provider_config" {
  count = local.upbound_aws_provider.enable == true ? 1 : 0
  yaml_body = templatefile("${path.module}/providers/aws-upbound/provider-config.yaml", {
    provider-config-name = local.upbound_aws_provider.provider_config_name
  })

  depends_on = [kubectl_manifest.upbound_aws_provider, time_sleep.upbound_wait_60_seconds]
}


resource "aws_iam_policy" "carts_dynamo" {
  name        = "${local.addon_context.eks_cluster_id}-carts-dynamo"
  path        = "/"
  description = "DynamoDB policy for AWS Sample Carts Application"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllAPIActionsOnCart",
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": [
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"        
      ]
    }
  ]
}
EOF
  tags   = local.tags
}



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

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }
}

data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

output "environment" {
  value = <<EOF
export VPC_ID=${data.aws_vpc.selected.id}
export VPC_CIDR=${data.aws_vpc.selected.cidr_block}
%{for index, id in data.aws_subnets.private.ids}
export VPC_PRIVATE_SUBNET_ID_${index + 1}=${id}
%{endfor}
EOF
}