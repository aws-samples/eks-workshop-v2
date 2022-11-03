module "networking_rds_postgre" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name           = "eksworkshop-rds-networking"
  engine         = "aurora-postgresql"
  engine_version = "11.12"
  instance_class = "db.t3.small"
  instances = {
    one = {}
  }

  vpc_id  = module.aws_vpc.vpc_id
  subnets = local.private_subnet_ids

  create_security_group = false
  allowed_security_groups = [aws_security_group.networking_rds_ingress.id]

  master_username = "eksworkshop"
  master_password        = random_string.networking_db_master.result
  create_random_password = false
  database_name          = "eksworkshop"
  storage_encrypted      = true
  apply_immediately      = true
  skip_final_snapshot    = true
  backup_retention_period = 0
  monitoring_interval = 10

  iam_database_authentication_enabled = true

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = local.tags
}

resource "random_string" "networking_db_master" {
  length  = 10
  special = false
}

resource "aws_security_group" "networking_rds_ingress" {
  description = "Allow inbound traffic to security group networking module RDS"
  vpc_id      = module.aws_vpc.vpc_id

  tags = local.tags
}