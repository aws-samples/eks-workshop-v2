
# Common Data Sources
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
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

data "aws_vpc" "eks_vpc" {
  id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

data "aws_eks_node_group" "default" {
  cluster_name    = data.aws_eks_cluster.cluster.id
  node_group_name = "default"
}

data "aws_caller_identity" "current" {}


# Additional Data Sources

data "aws_autoscaling_group" "new_nodegroup_1" {
  name = aws_eks_node_group.new_nodegroup_1.resources[0].autoscaling_groups[0].name
  depends_on = [
    aws_eks_node_group.new_nodegroup_1,
    null_resource.increase_desired_count
  ]
}

data "aws_autoscaling_group" "new_nodegroup_2" {
  name = aws_eks_node_group.new_nodegroup_2.resources[0].autoscaling_groups[0].name
  depends_on = [
    aws_eks_node_group.new_nodegroup_2,
    null_resource.increase_nodegroup_2
  ]
}


data "aws_nat_gateways" "cluster_nat_gateways" {
  vpc_id = data.aws_vpc.eks_vpc.id

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_instances" "new_nodegroup_2_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = data.aws_autoscaling_group.new_nodegroup_2.name
  }
  instance_state_names = ["running", "pending"]
  depends_on           = [null_resource.wait_for_instance]
}

data "aws_instances" "new_nodegroup_3_instances" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = ["new_nodegroup_3"]
  }
  instance_state_names = ["running"]
  depends_on           = [aws_eks_node_group.new_nodegroup_3]
}


# Scenario 1 Resources
resource "aws_kms_key" "new_kms_key" {
  description         = "NEW KMS CMK"
  enable_key_rotation = true
}

resource "random_string" "random_suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_kms_alias" "new_kms_key_alias" {
  name          = "alias/new_kms_key_alias_${random_string.random_suffix.result}"
  target_key_id = aws_kms_key.new_kms_key.key_id
  depends_on    = [aws_kms_key.new_kms_key]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_kms_key_policy" "example" {
  key_id = aws_kms_key.new_kms_key.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_launch_template" "new_nodegroup_1" {
  name = "new_nodegroup_1"

  instance_type = "m5.large"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp2"
      encrypted   = true
      kms_key_id  = aws_kms_key.new_kms_key.arn
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "troubleshooting-one-${var.eks_cluster_id}"
    }
  }
  depends_on = [aws_kms_key.new_kms_key]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "new_nodegroup_1" {
  cluster_name    = data.aws_eks_cluster.cluster.id
  node_group_name = "new_nodegroup_1"
  node_role_arn   = data.aws_eks_node_group.default.node_role_arn
  release_version = data.aws_eks_node_group.default.release_version
  subnet_ids      = data.aws_subnets.private.ids

  scaling_config {
    desired_size = 0
    max_size     = 1
    min_size     = 0
  }
  launch_template {
    id      = aws_launch_template.new_nodegroup_1.id
    version = aws_launch_template.new_nodegroup_1.latest_version
  }
  depends_on = [aws_launch_template.new_nodegroup_1]
}

resource "null_resource" "increase_desired_count" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "aws eks update-nodegroup-config --cluster-name ${data.aws_eks_cluster.cluster.id} --nodegroup-name ${aws_eks_node_group.new_nodegroup_1.node_group_name} --scaling-config minSize=0,maxSize=1,desiredSize=1"
    when    = create
    environment = {
      AWS_DEFAULT_REGION = data.aws_region.current.name
    }
  }
  depends_on = [aws_eks_node_group.new_nodegroup_1]
}



# Scenario 2 Resources
resource "aws_subnet" "new_subnet" {
  vpc_id            = data.aws_vpc.eks_vpc.id
  cidr_block        = "10.42.192.0/19"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "eksctl-${data.aws_eks_cluster.cluster.id}/NewPrivateSubnetAZ1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "new_route_table" {
  vpc_id = data.aws_vpc.eks_vpc.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "new_subnet_association" {
  subnet_id      = aws_subnet.new_subnet.id
  route_table_id = aws_route_table.new_route_table.id
}

resource "aws_launch_template" "new_nodegroup_2" {
  name = "new_nodegroup_2"

  instance_type = "m5.large"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "troubleshooting-two-${var.eks_cluster_id}"
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "new_nodegroup_2" {
  cluster_name    = data.aws_eks_cluster.cluster.id
  node_group_name = "new_nodegroup_2"
  node_role_arn   = data.aws_eks_node_group.default.node_role_arn
  subnet_ids      = [aws_subnet.new_subnet.id]

  scaling_config {
    desired_size = 0
    max_size     = 2
    min_size     = 0
  }

  launch_template {
    id      = aws_launch_template.new_nodegroup_2.id
    version = aws_launch_template.new_nodegroup_2.latest_version
  }

  depends_on = [
    aws_subnet.new_subnet,
    aws_route_table_association.new_subnet_association
  ]
}

# Scenario 3 Resources
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

# Kubernetes Resources Deployment for Scenario 3
resource "null_resource" "deploy_kubernetes_resources" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/yaml/namespace.yaml
      sleep 5
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/yaml/priority-class.yaml
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/yaml/configmaps.yaml
      sleep 5
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/yaml/deployment.yaml
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/yaml/daemonset.yaml
    EOT
  }

  depends_on = [aws_eks_node_group.new_nodegroup_3]
}

resource "null_resource" "increase_nodegroup_2" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "aws eks update-nodegroup-config --cluster-name ${data.aws_eks_cluster.cluster.id} --nodegroup-name new_nodegroup_2 --scaling-config minSize=0,maxSize=1,desiredSize=1"
    when    = create
  }
  depends_on = [aws_eks_node_group.new_nodegroup_2]
}

resource "null_resource" "wait_for_instance" {
  depends_on = [null_resource.increase_nodegroup_2, aws_eks_node_group.new_nodegroup_2]

  provisioner "local-exec" {
    command = <<EOT
      while [ "$(aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=${data.aws_autoscaling_group.new_nodegroup_2.name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' --output text)" == "" ]; do
        echo "Waiting for instance to be in running state..."
        sleep 10
      done
    EOT
    when    = create
  }
}
