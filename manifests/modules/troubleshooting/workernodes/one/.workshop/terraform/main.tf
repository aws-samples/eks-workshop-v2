##To do - added nodegroup name as variable and change change to use the variable instead.

provider "aws" {
  region = "us-west-2"
  alias  = "Oregon"
}

/* locals {
  tags = {
    module = "troubleshooting"
  }
} */

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id
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


#scale nodegroup to 0 and create a new managed node group for scenario (otherwise the issue will transition mng to degraded state and fail reset-environment will take a very long time e.g. 20 minutes)
# Decrease desired count to 0

data "aws_eks_node_group" "default" {
  cluster_name    = data.aws_eks_cluster.cluster.id
  node_group_name = "default"
}

##creating KMS CMK - schedule deletion after minimum of 7 days
resource "aws_kms_key" "new_kms_key" {
  description = "NEW KMS CMK"
  #  deletion_window_in_days = 7
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


# make key alias unique/random for self driven workshopers


#get account ID and output it for use
data "aws_caller_identity" "current" {}

/* output "account_id" {
  value = data.aws_caller_identity.current.account_id
} */

##creating policy document for key policy
data "aws_iam_policy_document" "key_administrators_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}
#add key policy to key
resource "aws_kms_key_policy" "example" {
  key_id = aws_kms_key.new_kms_key.key_id
  policy = data.aws_iam_policy_document.key_administrators_policy.json
}
#remember to use least priviledge permissions where possible ^

#enable encryption by default pointing to the new cmk. Disable script for destroy environment.
# resource "aws_ebs_encryption_by_default" "ebs-encryption-default" {
#   enabled = true
# }


# resource "null_resource" "modify_ebs_default_kms_key" {
#   provisioner "local-exec" {
#     command = "aws ec2 modify-ebs-default-kms-key-id --kms-key-id ${aws_kms_key.new_kms_key.key_id} --region us-west-2"

#     environment = {
#       AWS_DEFAULT_REGION = "us-west-2"
#     }

#   }
# }


# Create a new launch template so ec2 instances will have a name for easier identification during troubleshooting.
resource "aws_launch_template" "new_launch_template" {
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

#create new nodegroup called newnodegroup with zero node, so MNG will not go to degraded state
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

  update_config {
    max_unavailable_percentage = 50
  }
  launch_template {
    id      = aws_launch_template.new_launch_template.id
    version = aws_launch_template.new_launch_template.latest_version
  }
  depends_on = [aws_launch_template.new_launch_template]
}
resource "null_resource" "increase_desired_count" {
  provisioner "local-exec" {
    command = "aws eks update-nodegroup-config --cluster-name ${data.aws_eks_cluster.cluster.id} --nodegroup-name ${aws_eks_node_group.new_nodegroup_1.node_group_name} --scaling-config minSize=0,maxSize=1,desiredSize=1"
    when    = create
    environment = {
      AWS_DEFAULT_REGION = "us-west-2"
    }
    #This will eventually transition newnodegroup into Degraded state. Need to find out how to bring it back to healthy state.

  }
  depends_on = [aws_eks_node_group.new_nodegroup_1]
}


