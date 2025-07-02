
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_region" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id
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
  name = "${var.addon_context.eks_cluster_id}-ecr-ec2-role"
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
  name = "${var.eks_cluster_id}-ecr-ec2"
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
    env = "${var.eks_cluster_id}"
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

data "template_file" "deployment_yaml1" {
  template = file("${path.module}/deployment_permissions.yaml.tpl")

  vars = {
    image = "${resource.aws_ecr_repository.ui.repository_url}:0.4.0"
  }
}


resource "local_file" "deployment_yaml1" {
  filename = "${path.module}/deployment_permissions.yaml"
  content  = data.template_file.deployment_yaml1.rendered
}

resource "null_resource" "kustomize_app1" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/deployment_permissions.yaml"
    when    = create
  }

  depends_on = [resource.local_file.deployment_yaml1, resource.aws_instance.ui_to_ecr]
}


###======ImagePullBackOff - Public Image
resource "null_resource" "kustomize_app2" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/deployment_image.yaml"
    when    = create
  }
}

###======PodStuck - ContainerCreating
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.21.1"

  enable_aws_efs_csi_driver = true
  aws_efs_csi_driver = {
    wait = true
  }

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn
}


resource "aws_efs_file_system" "efs" {
  tags = {
    Name = "${var.eks_cluster_id}-efs"
  }
}

resource "aws_efs_mount_target" "mount_targets" {
  for_each        = toset(data.aws_subnets.public.ids)
  file_system_id  = resource.aws_efs_file_system.efs.id
  subnet_id       = each.value
  security_groups = [resource.aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name        = "efs_sg"
  description = "Allow tarffic to efs"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "efs_sg"
    env  = "${var.eks_cluster_id}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4" {
  security_group_id = aws_security_group.efs_sg.id
  cidr_ipv4         = data.aws_vpc.selected.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.efs_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

data "template_file" "deployment_yaml2" {
  template = file("${path.module}/deployment_crash.yaml.tpl")

  vars = {
    filesystemid = resource.aws_efs_file_system.efs.id
  }
}

resource "local_file" "deployment_yaml2" {
  filename = "${path.module}/deployment_crash.yaml"
  content  = data.template_file.deployment_yaml2.rendered
}

resource "null_resource" "kustomize_app3" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/deployment_crash.yaml"
    when    = create
  }

  depends_on = [resource.local_file.deployment_yaml2, resource.aws_efs_file_system.efs]
}
