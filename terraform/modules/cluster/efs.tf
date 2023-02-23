resource "aws_security_group" "efs" {
  name        = "${var.environment_name}-efs"
  description = "efs security group allow access to port 2049"
  vpc_id      = module.aws_vpc.vpc_id

  ingress {
    description = "allow inbound NFS traffic"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [module.aws_vpc.vpc_cidr_block]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.environment_name}-efssecuritygroup"
    }
  )
}

resource "aws_efs_file_system" "efsassets" {
  creation_token = "${var.environment_name}-efs-assets"
  encrypted      = true
  kms_key_id     = aws_kms_key.cmk.arn

  tags = merge(
    local.tags,
    {
      Name = "${var.environment_name}-efs-assets"
    }
  )
}

resource "aws_efs_mount_target" "efsmtpvsubnet" {
  count = length(local.private_subnet_ids)

  file_system_id  = aws_efs_file_system.efsassets.id
  subnet_id       = local.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}
