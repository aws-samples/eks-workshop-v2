
data "aws_region" "current" {}

locals {
  tags = {
    module = "troubleshooting"
  }
}

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

data "aws_subnets" "public" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Public*"]
  }
}


resource "time_sleep" "blueprints_addons_sleep" {
  depends_on = [
    module.eks_blueprints_addons
  ]

  create_duration  = "15s"
  destroy_duration = "15s"
}


resource "null_resource" "break_public_subnet" {
  triggers = {
    public_subnets = join(" ", data.aws_subnets.public.ids)
    always_run     = timestamp()
  }
  count = length(data.aws_subnets.public)

  lifecycle {
    create_before_destroy = false
  }


  provisioner "local-exec" {
    when    = create
    command = "aws ec2 delete-tags --resources ${self.triggers.public_subnets} --tags Key=kubernetes.io/role/elb,Value='1'"
  }

}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    wait = true
  }

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  tags = merge(
    var.tags,
    local.tags
  )

  depends_on = [null_resource.break_public_subnet]

}


# create a new policy from json file 
resource "aws_iam_policy" "issue" {
  name   = "eksworkshopissue"
  path   = "/"
  policy = file("${path.module}/template/other_issue.json")
}

# attach issue policy to role
resource "aws_iam_role_policy_attachment" "issue_policy_attachment" {
  role       = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_name
  policy_arn = aws_iam_policy.issue.arn
  depends_on = [module.eks_blueprints_addons, time_sleep.blueprints_addons_sleep]
}

resource "null_resource" "detach_existing_policy" {
  triggers = {
    role_name  = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_name,
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "aws iam detach-role-policy --role-name ${self.triggers.role_name} --policy-arn ${module.eks_blueprints_addons.aws_load_balancer_controller.iam_policy_arn}"
    when    = create
  }

  depends_on = [aws_iam_role_policy_attachment.issue_policy_attachment]
}

resource "null_resource" "kustomize_app" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl apply -k ~/environment/eks-workshop/modules/troubleshooting/alb/creating-alb"
    when    = create
  }

  depends_on = [aws_iam_role_policy_attachment.issue_policy_attachment]
}
