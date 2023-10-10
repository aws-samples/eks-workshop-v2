module "fsxn_driver" {
  source = "github.com/NetApp/terraform-aws-netapp-fsxn-eks-addon.git?ref=v1.0"
}

data "aws_vpc" "selected_vpc_fsx" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }
}

data "aws_subnets" "private_subnets_fsx" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

resource "random_string" "fsx_password" {
  length  = 10
  special = false
}

data "aws_route_table" "private" {
  count = length(data.aws_subnets.private_subnets_fsx.ids)

  vpc_id    = data.aws_vpc.selected_vpc_fsx.id
  subnet_id = data.aws_subnets.private_subnets_fsx.ids[count.index]
}

resource "aws_fsx_ontap_file_system" "fsxnassets" {
  storage_capacity    = 2048
  subnet_ids          = slice(data.aws_subnets.private_subnets_fsx.ids, 0, 2)
  deployment_type     = "MULTI_AZ_1"
  throughput_capacity = 512
  preferred_subnet_id = data.aws_subnets.private_subnets_fsx.ids[0]
  security_group_ids  = [aws_security_group.fsxn.id]
  fsx_admin_password  = random_string.fsx_password.result
  route_table_ids     = data.aws_route_table.private.*.id

  tags = merge(
    local.tags,
    {
      Name = "${local.addon_context.eks_cluster_id}-fsxn-assets"
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
    local.tags,
    {
      Name = "${local.addon_context.eks_cluster_id}-fsxnsecuritygroup"
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

output "environment" {
  value = <<EOF
export FSXN_ID=${aws_fsx_ontap_file_system.fsxnassets.id}
export FSXN_ADMIN_PASSWORD=${random_string.fsx_password.result}
export FSXN_IP="${tolist(aws_fsx_ontap_file_system.fsxnassets.endpoints[0].management[0].ip_addresses)[0]}"
EOF
}