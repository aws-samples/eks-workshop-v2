module "catalog_mysql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.2.3"

  identifier = "${var.environment_name}-catalog"

  create_db_option_group    = false
  create_db_parameter_group = false

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = "mysql"
  engine_version       = "8.0.27"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t4g.micro"

  allocated_storage = 20

  db_name                = "catalog"
  username               = "catalog_user"
  create_random_password = false
  password               = random_string.catalog_db_master.result
  port                   = 3306

  create_db_subnet_group = true
  db_subnet_group_name   = "${var.environment_name}-catalog"
  subnet_ids             = local.private_subnet_ids
  vpc_security_group_ids = [module.catalog_rds_ingress.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 0

  tags = local.tags
}

resource "random_string" "catalog_db_master" {
  length  = 10
  special = false
}

module "catalog_rds_ingress" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.environment_name}-catalog-rds"
  description = "Catalog RDS security group"
  vpc_id      = module.aws_vpc.vpc_id

  # ingress
  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "MySQL access from within VPC"
      source_security_group_id = aws_security_group.catalog_rds_ingress.id
    },
  ]

  tags = local.tags
}

resource "aws_security_group" "catalog_rds_ingress" {
  #checkov:skip=CKV2_AWS_5:This is attached in the workshop
  name        = "${var.environment_name}-catalog"
  description = "Applied to catalog application pods"
  vpc_id      = module.aws_vpc.vpc_id

  ingress {
    description = "Allow inbound HTTP API traffic"
    from_port   = 8080
    to_port     = 8080
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

  tags = local.tags
}
