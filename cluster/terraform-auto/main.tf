locals {
  auto_vpc_cidr        = "10.43.0.0/16"
  auto_azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  auto_private_subnets = [for k, v in local.auto_azs : cidrsubnet(local.auto_vpc_cidr, 3, k + 3)]
  auto_public_subnets  = [for k, v in local.auto_azs : cidrsubnet(local.auto_vpc_cidr, 3, k)]

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.auto_cluster_name
  }
}

module "auto_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.auto_cluster_name
  cidr = local.auto_vpc_cidr

  azs                   = local.auto_azs
  public_subnets        = local.auto_public_subnets
  private_subnets       = local.auto_private_subnets
  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true



  public_subnet_tags = merge(local.tags, {
    "kubernetes.io/role/elb" = "1"
  })

  private_subnet_tags = merge(local.tags, {
    "kubernetes.io/role/internal-elb" = "1"
  })

  tags = local.tags
}

resource "aws_eks_cluster" "auto_mode" {
  name = var.auto_cluster_name

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.auto_cluster.arn
  version  = var.cluster_version

  bootstrap_self_managed_addons = false

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.auto_node.arn
  }

  kubernetes_network_config {
    service_ipv4_cidr = "172.20.0.0/16"  # Custom service CIDR
    ip_family         = "ipv4"           # Optional: ipv4 (default) or ipv6

    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids              = module.auto_vpc.private_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.auto_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.auto_cluster_AmazonEKSComputePolicy,
    aws_iam_role_policy_attachment.auto_cluster_AmazonEKSBlockStoragePolicy,
    aws_iam_role_policy_attachment.auto_cluster_AmazonEKSLoadBalancingPolicy,
    aws_iam_role_policy_attachment.auto_cluster_AmazonEKSNetworkingPolicy,
  ]

  tags = local.tags
}

resource "aws_iam_role" "auto_node" {
  name = "${var.auto_cluster_name}-auto-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "auto_node_AmazonEKSWorkerNodeMinimalPolicy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.auto_node.name
}

resource "aws_iam_role_policy_attachment" "auto_node_AmazonEC2ContainerRegistryPullOnly" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.auto_node.name
}

resource "aws_iam_role" "auto_cluster" {
  name = "${var.auto_cluster_name}-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "auto_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.auto_cluster.name
}

resource "aws_iam_role_policy_attachment" "auto_cluster_AmazonEKSComputePolicy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.auto_cluster.name
}

resource "aws_iam_role_policy_attachment" "auto_cluster_AmazonEKSBlockStoragePolicy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  role       = aws_iam_role.auto_cluster.name
}

resource "aws_iam_role_policy_attachment" "auto_cluster_AmazonEKSLoadBalancingPolicy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.auto_cluster.name
}

resource "aws_iam_role_policy_attachment" "auto_cluster_AmazonEKSNetworkingPolicy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSNetworkingPolicy"
  role       = aws_iam_role.auto_cluster.name
}

resource "aws_eks_access_entry" "auto_workshop_ide" {
  cluster_name  = aws_eks_cluster.auto_mode.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eks-workshop-ide-role"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "auto_workshop_ide_admin" {
  cluster_name  = aws_eks_cluster.auto_mode.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eks-workshop-ide-role"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.auto_workshop_ide]
}

# Add access for the current user/role running Terraform
resource "aws_eks_access_entry" "current_user" {
  cluster_name  = aws_eks_cluster.auto_mode.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "current_user_admin" {
  cluster_name  = aws_eks_cluster.auto_mode.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.current_user]
}

resource "aws_dynamodb_table" "auto_carts" {
  name             = "${var.auto_cluster_name}-carts"
  hash_key         = "id"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name            = "idx_global_customerId"
    hash_key        = "customerId"
    projection_type = "ALL"
  }

  tags = local.tags
}

resource "aws_iam_role" "auto_carts_dynamo" {
  name = "${var.auto_cluster_name}-carts-dynamo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_policy" "auto_carts_dynamo" {
  name        = "${var.auto_cluster_name}-carts-dynamo"
  description = "Dynamo policy for carts application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllAPIActionsOnCart"
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        aws_dynamodb_table.auto_carts.arn,
        "${aws_dynamodb_table.auto_carts.arn}/index/*"
      ]
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "auto_carts_dynamo" {
  policy_arn = aws_iam_policy.auto_carts_dynamo.arn
  role       = aws_iam_role.auto_carts_dynamo.name
}

resource "aws_iam_role" "auto_keda" {
  name = "${var.auto_cluster_name}-keda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "auto_keda_cloudwatch" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchReadOnlyAccess"
  role       = aws_iam_role.auto_keda.name
}
