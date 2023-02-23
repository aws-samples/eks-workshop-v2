resource "aws_fsx_ontap_file_system" "fsxnassets" {
  storage_capacity    = var.fsx_capacity
  subnet_ids          = [module.aws_vpc.public_subnets[0],module.aws_vpc.public_subnets[1]]
  deployment_type     = "MULTI_AZ_1"
  throughput_capacity = 512
  preferred_subnet_id = module.aws_vpc.public_subnets[0]
  security_group_ids = [aws_security_group.fsxn.id]
  fsx_admin_password = var.fsx_admin_password
  route_table_ids = module.aws_vpc.public_route_table_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.environment_name}-fsxn-assets"
    }
  )
}

resource "aws_fsx_ontap_storage_virtual_machine" "fsxnsvm" {
  file_system_id = aws_fsx_ontap_file_system.fsxnassets.id
  name           = "fsxnsvm"
}

resource "aws_security_group" "fsxn" {
  name_prefix = "security group for fsx access"
  vpc_id      = module.aws_vpc.vpc_id
  tags = merge(
    local.tags,
    {
      Name = "${var.environment_name}-fsxnsecuritygroup"
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
  cidr_blocks       = [module.aws_vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "fsxn_outbound" {
  description       = "allow outbound traffic to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.fsxn.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = [module.aws_vpc.vpc_cidr_block]
}