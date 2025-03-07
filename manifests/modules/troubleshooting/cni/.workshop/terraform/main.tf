locals {
  tags = {
    module = "troubleshooting"
  }
  secondary_cidr = "100.64.0.0/22"
}

# data "aws_vpc" "selected" {
#   tags = {
#     created-by = "eks-workshop-v2"
#     env        = var.addon_context.eks_cluster_id
#   }
# }

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id
}

data "aws_vpc" "selected" {
  id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
}

# data "aws_eks_cluster" "this" {
#   name = var.addon_context.eks_cluster_id
# }

# data "aws_vpc" "selected" {
#   id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
# }

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  #  tags = {
  #    created-by = "eks-workshop-v2"
  #    env        = var.addon_context.eks_cluster_id
  #  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = data.aws_vpc.selected.id
  cidr_block = local.secondary_cidr
}

data "aws_subnet" "selected" {
  count = length(data.aws_subnets.private.ids)

  id = data.aws_subnets.private.ids[count.index]
}

resource "aws_subnet" "large_subnet" {
  count = length(data.aws_subnets.private.ids)

  vpc_id            = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
  cidr_block        = cidrsubnet(local.secondary_cidr, 2, count.index)
  availability_zone = data.aws_subnet.selected[count.index].availability_zone

  tags = merge(local.tags, var.tags, {
    AdditionalSubnet = "true"
    Size             = "large"
  })

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.secondary_cidr
  ]
}

resource "aws_subnet" "small_subnet" {
  count = length(data.aws_subnets.private.ids)

  vpc_id            = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
  cidr_block        = cidrsubnet(local.secondary_cidr, 6, count.index + 48)
  availability_zone = data.aws_subnet.selected[count.index].availability_zone

  tags = merge(local.tags, {
    AdditionalSubnet = "true"
    Size             = "small"
  })

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.secondary_cidr
  ]
}

data "aws_route_table" "private" {
  count = length(data.aws_subnets.private.ids)

  vpc_id    = data.aws_vpc.selected.id
  subnet_id = data.aws_subnets.private.ids[count.index]
}

resource "aws_route_table_association" "small_subnet" {
  count = length(data.aws_subnets.private.ids)

  subnet_id      = aws_subnet.small_subnet[count.index].id
  route_table_id = data.aws_route_table.private[count.index].route_table_id
}

resource "aws_route_table_association" "large_subnet" {
  count = length(data.aws_subnets.private.ids)

  subnet_id      = aws_subnet.large_subnet[count.index].id
  route_table_id = data.aws_route_table.private[count.index].route_table_id
}

resource "aws_iam_role" "node_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_eks_access_entry" "cni_troubleshooting_nodes" {
  cluster_name  = var.eks_cluster_id
  principal_arn = aws_iam_role.node_role.arn
  type          = "EC2_LINUX"
}

resource "aws_eks_node_group" "cni_troubleshooting_nodes" {

  cluster_name    = var.eks_cluster_id
  node_group_name = "cni_troubleshooting_nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.small_subnet[*].id
  instance_types  = ["c5.large"]

  scaling_config {
    desired_size = 0
    max_size     = 6
    min_size     = 0
  }

  labels = {
    app = "cni_troubleshooting"
  }

  taint {
    key    = "purpose"
    value  = "cni_troubleshooting"
    effect = "NO_SCHEDULE"
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(local.tags, var.tags)

}


data "aws_eks_addon" "vpc_cni" {
  addon_name   = "vpc-cni"
  cluster_name = var.eks_cluster_id # Changed from var.addon_context.eks_cluster_id
}

resource "null_resource" "change_config" {
  triggers = {
    config          = data.aws_eks_addon.vpc_cni.configuration_values,
    cluster_name    = var.eks_cluster_id, # Changed to be consistent
    role_arn        = data.aws_eks_addon.vpc_cni.service_account_role_arn,
    node_group_name = aws_eks_node_group.cni_troubleshooting_nodes.node_group_name,
    role_name       = split("/", data.aws_eks_addon.vpc_cni.service_account_role_arn)[1],
    timestamp       = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
mkdir -p /eks-workshop/temp
CURRENT_CONFIG='${jsonencode(self.triggers.config)}'
NEW_CONFIG=$(echo $CURRENT_CONFIG | jq -r . | jq -c '. += {"resources":{"requests":{"memory":"2G"}}}')
aws eks update-addon --addon-name vpc-cni --cluster-name ${self.triggers.cluster_name} --service-account-role-arn ${self.triggers.role_arn} --configuration-values $NEW_CONFIG
addons_status="UPDATING"
while [ $addons_status == "UPDATING" ]; do
    sleep 60
    addons_status=$(aws eks describe-addon --addon-name vpc-cni --cluster-name ${self.triggers.cluster_name} --query addon.status --output text)
done
aws iam detach-role-policy --role-name ${self.triggers.role_name} --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws eks update-nodegroup-config --cluster-name ${self.triggers.cluster_name} --nodegroup-name ${self.triggers.node_group_name} --scaling-config minSize=0,maxSize=6,desiredSize=1
EOF
  }

}

resource "null_resource" "kustomize_app" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl apply -k ~/environment/eks-workshop/modules/troubleshooting/cni/workload"
    when    = create
  }

}
