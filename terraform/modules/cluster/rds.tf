module "orders_rds" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name           = "${local.cluster_name}-orders"
  engine         = "aurora-mysql"
  engine_version = "5.7"
  instance_class = "db.t3.small"
  instances = {
    one = {}
  }

  vpc_id  = module.aws_vpc.vpc_id
  subnets = local.private_subnet_ids

  allowed_security_groups = [aws_security_group.orders_rds_ingress.id]

  master_password        = random_string.orders_db_master.result
  create_random_password = false
  database_name          = "orders"
  storage_encrypted      = true
  apply_immediately      = true
  skip_final_snapshot    = true
  #monitoring_interval = 10

  create_db_parameter_group = true
  db_parameter_group_name   = "${local.cluster_name}-orders"
  db_parameter_group_family = "aurora-mysql5.7"

  create_db_cluster_parameter_group = true
  db_cluster_parameter_group_name   = "${local.cluster_name}-orders"
  db_cluster_parameter_group_family = "aurora-mysql5.7"

  tags = local.tags
}

resource "random_string" "orders_db_master" {
  length  = 10
  special = false
}

resource "aws_security_group" "orders_rds_ingress" {
  name        = "${local.cluster_name}-orders-db"
  description = "Allow inbound traffic to orders MySQL"
  vpc_id      = module.aws_vpc.vpc_id

  tags = local.tags
}