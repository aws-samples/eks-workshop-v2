terraform {
  required_providers {
    #    kubectl = {
    #      source  = "gavinbunney/kubectl"
    #      version = ">= 1.14"
    #    }
  }
}



provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

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
    #cluster_id     = var.addon_context.eks_cluster_id
    public_subnets = join(" ", data.aws_subnets.public.ids)
    timestamp      = timestamp()
  }
  count = length(data.aws_subnets.public)

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 create-tags --resources ${self.triggers.public_subnets} --tags Key=kubernetes.io/role/elb,Value='1'"
  }

  provisioner "local-exec" {
    command = "aws ec2 delete-tags --resources ${self.triggers.public_subnets} --tags Key=kubernetes.io/role/elb,Value='1'"
  }
}


module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.2"

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
  name   = "issue"
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
    role_name = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_name,
    timestamp = timestamp()
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



# Example to now how to get variables from add ons outputs DO-NOT-DELETE; AddOns and helms documentaitons does not show exactly the output variables returned
#resource "null_resource" "blue_print_output" {
#  for_each = module.eks_blueprints_addons.aws_load_balancer_controller
#  triggers = {
#
#    timestamp      = timestamp()
#  }
#
#  #count = length(module.eks_blueprints_addons.aws_load_balancer_controller)
#  provisioner "local-exec" {
#    command = "mkdir -p /eks-workshop/logs; echo \" key: ${each.key} Value:${each.value}\" >> /eks-workshop/logs/action-load-balancer-output.log"
#  }
#
#  depends_on = [module.eks_blueprints_addons,time_sleep.blueprints_addons_sleep]
#}

#option to run a bash script file
#resource "null_resource" "break2" {
#  provisioner "local-exec" {
#    command = "${path.module}/template/break.sh ${path.module} mod2"    
#  }
#
#  triggers = {
#    always_run = timestamp()
#  }
#  depends_on = [module.eks_blueprints_addons,time_sleep.blueprints_addons_sleep]
#}

#option to run a kubectl manifest
#resource "kubectl_manifest" "alb" {
#  yaml_body = templatefile("${path.module}/template/ingress.yaml", {
#
#  })
#
#  depends_on = [null_resource.break_policy]
#}


