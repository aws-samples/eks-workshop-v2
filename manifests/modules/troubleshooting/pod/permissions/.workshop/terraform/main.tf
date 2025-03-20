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

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_region" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id
}


data "aws_eks_node_group" "default" {
  cluster_name    = data.aws_eks_cluster.cluster.id
  node_group_name = "default"
}

data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.eks_cluster_version}/amazon-linux-2/recommended/image_id"
}

data "aws_subnets" "selected" {
  tags = {
    env = var.addon_context.eks_cluster_id
  }
}

resource "aws_iam_role" "ecr_ec2_role" {
  name = "eks-workshop-ecr-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess", "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicPowerUser"]
}

resource "aws_iam_instance_profile" "ecr_ec2" {
  name = "eks-workshop-ecr-ec2"
  role = resource.aws_iam_role.ecr_ec2_role.name
}

resource "aws_instance" "ui_to_ecr" {
  ami                  = data.aws_ssm_parameter.eks_ami.value
  instance_type        = "m5.large"
  user_data            = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              docker pull public.ecr.aws/aws-containers/retail-store-sample-ui:0.4.0
              docker images | grep retail-store | awk '{ print $3 }' | xargs -I {} docker tag {} ${resource.aws_ecr_repository.ui.repository_url}:0.4.0
              aws ecr get-login-password | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com
              docker push ${resource.aws_ecr_repository.ui.repository_url}:0.4.0
              EOF
  subnet_id            = element(data.aws_subnets.selected.ids, 0)
  iam_instance_profile = resource.aws_iam_instance_profile.ecr_ec2.name
  tags = {
    env = "eks-workshop"
  }
  depends_on = [resource.aws_ecr_repository.ui]
}

resource "aws_ecr_repository" "ui" {
  name                 = "retail-sample-app-ui"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

}

data "aws_iam_policy_document" "private_registry" {
  statement {
    sid    = "new policy"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [data.aws_eks_node_group.default.node_role_arn]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}


resource "aws_ecr_repository_policy" "example" {
  repository = aws_ecr_repository.ui.name
  policy     = data.aws_iam_policy_document.private_registry.json
  depends_on = [resource.aws_instance.ui_to_ecr]
}

data "template_file" "deployment_yaml" {
  template = file("${path.module}/deployment.yaml.tpl")

  vars = {
    image = "${resource.aws_ecr_repository.ui.repository_url}:0.4.0"
  }
}


resource "local_file" "deployment_yaml" {
  filename = "${path.module}/deployment.yaml"
  content  = data.template_file.deployment_yaml.rendered
}

resource "null_resource" "kustomize_app" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/deployment.yaml"
    when    = create
  }

  depends_on = [resource.local_file.deployment_yaml, resource.aws_instance.ui_to_ecr]
}
