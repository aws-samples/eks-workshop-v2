data "aws_vpc" "selected_sg_rds" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }
}

data "aws_subnets" "private_sg_rds" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

module "catalog_mysql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.12.0"

  identifier = "${var.eks_cluster_id}-catalog"

  create_db_option_group    = false
  create_db_parameter_group = false

  engine               = "mysql"
  engine_version       = var.rds_engine_version
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t4g.micro"

  allocated_storage = 20

  db_name                     = "catalog"
  username                    = "catalog_user"
  manage_master_user_password = false
  password                    = random_string.catalog_db_master.result
  port                        = 3306

  create_db_subnet_group = true
  db_subnet_group_name   = "${var.eks_cluster_id}-catalog"
  subnet_ids             = data.aws_subnets.private_sg_rds.ids
  vpc_security_group_ids = [module.catalog_rds_ingress.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  skip_final_snapshot     = true
  backup_retention_period = 0

  tags = var.tags
}

resource "random_string" "catalog_db_master" {
  length  = 10
  special = false
}

module "catalog_rds_ingress" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${var.eks_cluster_id}-catalog-rds"
  description = "Catalog RDS security group"
  vpc_id      = data.aws_vpc.selected_sg_rds.id

  # ingress
  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "MySQL access from specific security group"
      source_security_group_id = aws_security_group.catalog_rds_ingress.id
    },
  ]

  tags = var.tags
}

resource "aws_security_group" "catalog_rds_ingress" {
  #checkov:skip=CKV2_AWS_5:This is attached in the workshop
  name        = "${var.eks_cluster_id}-catalog"
  description = "Applied to catalog application pods"
  vpc_id      = data.aws_vpc.selected_sg_rds.id

  ingress {
    description = "Allow inbound HTTP API traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_sg_rds.cidr_block]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_ssm_parameter" "secret" {
  name        = "${var.eks_cluster_id}-catalog-db"
  description = "EKS Workshop catalog DB password"
  type        = "SecureString"
  value       = base64encode(random_string.catalog_db_master.result)

  tags = var.tags
}
