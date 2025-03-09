

provider "aws" {
  region = "us-west-2"
  alias  = "Oregon"
}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id

  lifecycle {
    postcondition {
      condition     = self.status == "ACTIVE"
      error_message = "EKS cluster must be active"
    }
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_eks_cluster.cluster.vpc_config[0].vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }

  tags = {
    "created-by" = "eks-workshop-v2"
    "env"        = var.addon_context.eks_cluster_id
  }
}

resource "aws_iam_role" "new_nodegroup_3" {
  name = "new_nodegroup_3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.new_nodegroup_3.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.new_nodegroup_3.name
}

resource "aws_launch_template" "new_nodegroup_3" {
  name = "new_nodegroup_3"

  instance_type = "m5.large"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "new_nodegroup_3-${var.eks_cluster_id}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_eks_node_group" "new_nodegroup_3" {
  cluster_name    = data.aws_eks_cluster.cluster.id
  node_group_name = "new_nodegroup_3"
  node_role_arn   = aws_iam_role.new_nodegroup_3.arn
  subnet_ids      = data.aws_subnets.private.ids

  labels = {
    "nodegroup-type" = "prod-app"
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 0
  }

  launch_template {
    id      = aws_launch_template.new_nodegroup_3.id
    version = aws_launch_template.new_nodegroup_3.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
  ]
}

data "aws_instances" "new_nodegroup_3_instances" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = ["new_nodegroup_3"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [aws_eks_node_group.new_nodegroup_3]
}


resource "null_resource" "deploy_kubernetes_resources" {
  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/namespace.yaml
      sleep 5
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/priority-class.yaml
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/configmaps.yaml
      sleep 5
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/deployment.yaml
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/daemonset.yaml
    EOT
  }

  depends_on = [aws_eks_node_group.new_nodegroup_3]
}


resource "null_resource" "deploy_metrics_server" {
  provisioner "local-exec" {
    when    = create
    command = "kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/metrics-server.yaml"
  }

  depends_on = [aws_eks_node_group.new_nodegroup_3]
}



data "aws_caller_identity" "current" {}

