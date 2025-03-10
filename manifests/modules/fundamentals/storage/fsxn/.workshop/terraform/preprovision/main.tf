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

resource "random_string" "fsx_password" {
  length           = 8
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  numeric          = true
  special          = true
  override_special = "!"
}

resource "aws_secretsmanager_secret" "fsxn_password_secret" {
  name                    = "${var.eks_cluster_id}-fsxn-secret"
  description             = "FSxN CSI Driver Password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "fsxn_password_secret" {
  secret_id = aws_secretsmanager_secret.fsxn_password_secret.id
  secret_string = jsonencode({
    username = "vsadmin"
    password = "${random_string.fsx_password.result}"
  })
}

resource "aws_fsx_ontap_file_system" "fsxn_filesystem" {
  storage_capacity    = 2048
  subnet_ids          = [data.aws_subnets.private_subnets_fsx.ids[0]]
  deployment_type     = "SINGLE_AZ_1"
  throughput_capacity = 128
  preferred_subnet_id = data.aws_subnets.private_subnets_fsx.ids[0]
  security_group_ids  = [aws_security_group.fsxn.id]
  fsx_admin_password  = random_string.fsx_password.result

  tags = merge(
    var.tags,
    {
      Name = "${var.eks_cluster_id}-fsxn"
    }
  )
}

resource "aws_fsx_ontap_storage_virtual_machine" "fsxn_svm" {
  file_system_id     = aws_fsx_ontap_file_system.fsxn_filesystem.id
  name               = "${var.eks_cluster_id}-svm"
  svm_admin_password = random_string.fsx_password.result
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
