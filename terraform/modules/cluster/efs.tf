data "aws_subnet" "pvsubnetsmanagednodes" {
  for_each = toset(module.aws_vpc.private_subnets)

  id = each.key
}

locals {
  availability_zone_subnets = {
    for item in data.aws_subnet.pvsubnetsmanagednodes : item.availability_zone => item.id...
  }
  
  mount_target_subnets = [for subnet_ids in local.availability_zone_subnets : subnet_ids[0]]
}



resource "aws_security_group" "efssecuritygroup" {
  name        = "efssecuritygroup"
  description = "efs security group allow access to port 2049"
  vpc_id      = module.aws_vpc.vpc_id

  ingress {
    description      = "allow inbound NFS traffic"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [module.aws_vpc.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
  }

  tags = {
    Name = "efssecuritygroup"
  }
}

resource "aws_efs_file_system" "efsassets" {
  creation_token = "efs-assets"

  tags = {
    Name = "efs-assets"
  }
}

resource "aws_efs_mount_target" "efsmtpvsubnet" {
  count = length(local.mount_target_subnets)
  file_system_id  = aws_efs_file_system.efsassets.id
  subnet_id = element(local.mount_target_subnets, count.index)
  security_groups = [aws_security_group.efssecuritygroup.id]
 }
 