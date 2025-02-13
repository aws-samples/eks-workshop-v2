##To do - added nodegroup name as variable and change change to use the variable instead.

terraform {
  required_providers {
    #    kubectl = {
    #      source  = "gavinbunney/kubectl"
    #      version = ">= 1.14"
    #    }
  }
}



provider "aws" {
  region = "us-west-2"
  alias  = "Oregon"

  default_tags {
    tags = {
      Workshop = "EKS Workshop"
      Module   = "Troubleshooting"
      Issue    = "Two"
    }
  }
}

locals {
  tags = {
    module = "troubleshooting"
  }
}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id
}

data "aws_eks_node_group" "default" {
  cluster_name    = data.aws_eks_cluster.cluster.id
  node_group_name = "default"
}

data "aws_vpc" "selected" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_eks_cluster.cluster.vpc_config[0].vpc_id]
  }
}


data "aws_nat_gateways" "cluster_nat_gateways" {
  #  vpc_id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
  vpc_id = data.aws_vpc.selected.id

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Create a new subnet
resource "aws_subnet" "new_subnet" {
  vpc_id            = data.aws_vpc.selected.id
  cidr_block        = "10.42.192.0/19"
  availability_zone = "us-west-2a"

  tags = {
    Name = "eksctl-${data.aws_eks_cluster.cluster.id}/NewPrivateSubnetUSWEST2A"
  }

  lifecycle {
    create_before_destroy = true
  }
}
# Create a new route table
resource "aws_route_table" "new_route_table" {
  vpc_id = data.aws_vpc.selected.id

  lifecycle {
    create_before_destroy = true
  }
}
# Associate the new subnet with the new route table
resource "aws_route_table_association" "new_subnet_association" {
  subnet_id      = aws_subnet.new_subnet.id
  route_table_id = aws_route_table.new_route_table.id
}

# Create a new launch template to add ec2 names
resource "aws_launch_template" "new_launch_template" {
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
# Create a new managed node group
resource "aws_eks_node_group" "new_nodegroup_2" {
  cluster_name    = data.aws_eks_cluster.cluster.name
  node_group_name = "new_nodegroup_2"
  node_role_arn   = data.aws_eks_node_group.default.node_role_arn
  subnet_ids      = [aws_subnet.new_subnet.id]
  launch_template {
    id      = aws_launch_template.new_launch_template.id
    version = aws_launch_template.new_launch_template.latest_version
  }

  scaling_config {
    desired_size = 0
    max_size     = 2
    min_size     = 0
  }

  depends_on = [
    aws_launch_template.new_launch_template,
    aws_subnet.new_subnet,
    aws_route_table_association.new_subnet_association,
  ]

  # combine local tags with resource-specific tags
  tags = merge(local.tags, {
    Name = "troubleshooting-new-node-group"
  })
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_autoscaling_group" "new_nodegroup_2" {
  name       = aws_eks_node_group.new_nodegroup_2.resources[0].autoscaling_groups[0].name
  depends_on = [aws_eks_node_group.new_nodegroup_2]
}



resource "null_resource" "increase_desired_count" {
  #trigger to properly capture the cluster and node group names for both create and destroy operations
  triggers = {
    cluster_name    = data.aws_eks_cluster.cluster.id
    node_group_name = aws_eks_node_group.new_nodegroup_2.node_group_name
  }
  provisioner "local-exec" {
    command = "aws eks update-nodegroup-config --cluster-name ${data.aws_eks_cluster.cluster.id} --nodegroup-name new_nodegroup_2 --scaling-config minSize=0,maxSize=2,desiredSize=1"

    when = create
  }

  depends_on = [aws_eks_node_group.new_nodegroup_2]
}

resource "null_resource" "wait_for_instance" {
  depends_on = [null_resource.increase_desired_count]

  provisioner "local-exec" {
    command = <<EOT
      while [ "$(aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=${data.aws_autoscaling_group.new_nodegroup_2.name}" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' --output text)" == "" ]; do
        echo "Waiting for instance to be in running state..."
        sleep 10
      done
    EOT
  }
}

data "aws_instances" "new_nodegroup_2_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = data.aws_autoscaling_group.new_nodegroup_2.name
  }
  instance_state_names = ["running", "pending"]
  depends_on           = [null_resource.wait_for_instance]
}

