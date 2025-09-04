data "aws_availability_zones" "available" {}

locals {
  remote_node_cidr = cidrsubnet(var.remote_network_cidr, 8, 0)
  remote_pod_cidr  = "10.53.0.0/16"

  remote_node_azs = slice(data.aws_availability_zones.available.names, 0, 3)

  name = "${var.addon_context.eks_cluster_id}-remote"
}

# Primary VPC created for the EKS Cluster
data "aws_vpc" "primary" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

# Look up "primary" vpc subnet
data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.primary.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

data "http" "public_ip" {
  url = "https://checkip.amazonaws.com/"
}

################################################################################
# Remote VPC
################################################################################

# Create VPC in remote region
resource "aws_vpc" "remote" {

  cidr_block           = var.remote_network_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${local.name}-vpc"
  })
}

# Create public subnets in remote VPC
resource "aws_subnet" "remote_public" {
  #count = 3

  vpc_id = aws_vpc.remote.id

  cidr_block        = local.remote_node_cidr
  availability_zone = local.remote_node_azs[0]

  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${local.name}-public"
  })
}

# Internet Gateway for remote VPC
resource "aws_internet_gateway" "remote" {
  vpc_id = aws_vpc.remote.id

  tags = merge(var.tags, {
    Name = "${local.name}-igw"
  })
}

# Route table for remote public subnets
resource "aws_route_table" "remote_public" {
  vpc_id = aws_vpc.remote.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remote.id
  }

  tags = merge(var.tags, {
    Name = "${local.name}-public-rt"
  })
}

# Associate route table with public subnets
resource "aws_route_table_association" "remote_public" {

  subnet_id      = aws_subnet.remote_public.id
  route_table_id = aws_route_table.remote_public.id
}

################################################################################
# Psuedo Hybrid Node
# Demonstration only - AWS EC2 instances are not supported for EKS Hybrid nodes
################################################################################

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.1.0"

  key_name           = "hybrid-node"
  create_private_key = true

  tags = var.tags
}

resource "local_file" "key_pem" {
  content         = module.key_pair.private_key_pem
  filename        = "${path.cwd}/environment/private-key.pem"
  file_permission = "0600"
}

# Define the security group for the hybrid nodes
resource "aws_security_group" "hybrid_nodes" {
  name        = "hybrid-nodes-sg"
  description = "Security group for hybrid EKS nodes"
  vpc_id      = aws_vpc.remote.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${trimspace(data.http.public_ip.response_body)}/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.primary.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.remote_pod_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

module "hybrid_node" {
  depends_on = [aws_ec2_transit_gateway.tgw, aws_internet_gateway.remote]
  source     = "terraform-aws-modules/ec2-instance/aws"
  version    = "6.1.1"

  metadata_options = {
    "http_tokens" : "required"
  }

  ami_ssm_parameter = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"

  instance_type          = "m5.large"
  subnet_id              = aws_subnet.remote_public.id
  vpc_security_group_ids = [aws_security_group.hybrid_nodes.id]
  key_name               = module.key_pair.key_pair_name

  root_block_device = {
    size                  = 100
    type                  = "gp3"
    delete_on_termination = true
  }

  source_dest_check = false

  user_data = <<-EOF
              #cloud-config
              package_update: true
              packages:
                - unzip

              runcmd:
                - cd /tmp
                - echo "Installing AWS CLI..."
                - curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                - unzip awscliv2.zip
                - ./aws/install
                - rm awscliv2.zip
                - rm -rf aws/
                - echo "Verifying AWS CLI installation..."
                - aws --version
                
                - echo "Downloading nodeadm..."
                - curl -OL 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/amd64/nodeadm'
                - chmod +x nodeadm
                
                - echo "Moving nodeadm to /usr/local/bin"
                - mv nodeadm /usr/local/bin/

                - echo "Verifying installations..."
                - nodeadm --version
              EOF
  tags = merge(var.tags, {
    Name = "${var.addon_context.eks_cluster_id}-hybrid-node-01"
  })
}

################################################################################
# Hybrid Networking
################################################################################

# Create Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {

  description = "Transit Gateway for EKS Workshop Hybrid setup"

  auto_accept_shared_attachments = "enable"

  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = merge(var.tags, {
    Name = "${var.addon_context.eks_cluster_id}-tgw"
  })
}

# Create Transit Gateway VPC Attachment for remote VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "remote" {
  #provider = aws.remote
  subnet_ids         = [aws_subnet.remote_public.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.remote.id

  dns_support = "enable"

  tags = merge(var.tags, {
    Name = "${var.addon_context.eks_cluster_id}-remote-tgw-attachment"
  })
}

data "aws_subnets" "cluster_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.primary.id]
  }

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Public*"]
  }
}

# Attach the main EKS VPC to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  subnet_ids         = data.aws_subnets.cluster_public.ids
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = data.aws_vpc.primary.id

  dns_support = "enable"

  tags = merge(var.tags, {
    Name = "${var.addon_context.eks_cluster_id}-main-tgw-attachment"
  })
}

# Add route in remote VPC route table to reach main VPC
resource "aws_route" "remote_to_main" {
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.remote]

  route_table_id         = aws_route_table.remote_public.id
  destination_cidr_block = data.aws_vpc.primary.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

data "aws_route_tables" "cluster_vpc_routetable" {
  vpc_id = data.aws_vpc.primary.id
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

}

# Add route in main VPC route tables to reach remote VPC
resource "aws_route" "main_to_remote" {
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]

  count          = length(data.aws_route_tables.cluster_vpc_routetable.ids)
  route_table_id = tolist(data.aws_route_tables.cluster_vpc_routetable.ids)[count.index]

  destination_cidr_block = var.remote_network_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Add route in main VPC route tables to reach pod cidr
resource "aws_route" "main_to_pod" {
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]

  count          = length(data.aws_route_tables.cluster_vpc_routetable.ids)
  route_table_id = tolist(data.aws_route_tables.cluster_vpc_routetable.ids)[count.index]

  destination_cidr_block = local.remote_pod_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Add static route in tgw route table to reach pod cidr
resource "aws_ec2_transit_gateway_route" "tgw_route_to_pod" {
  destination_cidr_block         = local.remote_pod_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.remote.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw.association_default_route_table_id
}

# Add static route in remote route table to direct all pod traffic to node eni
resource "aws_route" "remote_route_to_pod" {
  route_table_id         = aws_route_table.remote_public.id
  destination_cidr_block = local.remote_pod_cidr
  network_interface_id   = module.hybrid_node.primary_network_interface_id
}

###### HYBRID ROLE #####

module "eks_hybrid_node_role" {
  source      = "terraform-aws-modules/eks/aws//modules/hybrid-node-role"
  version     = "21.1.5"
  name        = "${var.eks_cluster_id}-hybrid-node-role"
  policy_name = "${var.eks_cluster_id}-hybrid-node-policy"
  tags        = var.tags
}

resource "aws_eks_access_entry" "remote" {
  cluster_name  = var.eks_cluster_id
  principal_arn = module.eks_hybrid_node_role.arn
  type          = "HYBRID_LINUX"
  tags          = var.tags
}

##### ADD PROPER SECURITY GROUP RULE TO ALLOW REMOTE PODS ACCESSINGS EKS NODES AND PDOS ####
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id
}

resource "aws_vpc_security_group_ingress_rule" "node_from_remote_node" {
  cidr_ipv4         = local.remote_node_cidr
  ip_protocol       = "all"
  security_group_id = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "node_from_remote_pod" {
  cidr_ipv4         = local.remote_pod_cidr
  ip_protocol       = "all"
  security_group_id = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }

  observability_tag = null
}
