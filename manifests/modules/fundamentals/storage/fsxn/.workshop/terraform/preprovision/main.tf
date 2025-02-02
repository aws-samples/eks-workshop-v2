data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_vpc" "selected_vpc_fsx" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }
}

data "aws_subnets" "private_subnets_fsx" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

locals {
    secret_name = "${var.eks_cluster_id}-${var.random_string}"
}

resource "random_string" "fsx_password" {
  length  = 10
  special = false
}

resource "aws_secretsmanager_secret" "fsxn_password_secret" {
  name = local.secret_name
  description = "FSxN CSI Driver Password"
}

resource "aws_secretsmanager_secret_version" "fsxn_password_secret" {
    secret_id     = aws_secretsmanager_secret.fsxn_password_secret.id
    secret_string = jsonencode({
    username = "vsadmin"
    password = "${random_string.fsx_password.result}"
  })
}

resource "aws_fsx_ontap_file_system" "fsxnassets" {
  storage_capacity    = 2048
  subnet_ids          = [data.aws_subnets.private_subnets_fsx.ids[0]]
  deployment_type     = "SINGLE_AZ_1"
  throughput_capacity = 512
  preferred_subnet_id = data.aws_subnets.private_subnets_fsx.ids[0]
  security_group_ids  = [aws_security_group.fsxn.id]
  fsx_admin_password  = random_string.fsx_password.result

  tags = merge(
    var.tags,
    {
      Name = "${var.eks_cluster_id}-fsxn-assets"
    }
  )
}

resource "aws_fsx_ontap_storage_virtual_machine" "fsxnsvm" {
  file_system_id = aws_fsx_ontap_file_system.fsxnassets.id
  name           = "fsxnsvm"
}

resource "aws_security_group" "fsxn" {
  name_prefix = "security group for fsx access"
  vpc_id      = data.aws_vpc.selected_vpc_fsx.id
  tags = merge(
    var.tags,
    {
      Name = "${var.eks_cluster_id}-fsxnsecuritygroup"
    }
  )
}

resource "aws_security_group_rule" "fsxn_inbound" {
  description       = "allow inbound traffic to eks"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  security_group_id = aws_security_group.fsxn.id
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.selected_vpc_fsx.cidr_block]
}

resource "aws_security_group_rule" "fsxn_outbound" {
  description       = "allow outbound traffic to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.fsxn.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.selected_vpc_fsx.cidr_block]
}
