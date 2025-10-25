/**
* Provision OpenSearch domain for EKS OpenSearch Observability module and 
* store the OpenSearch endpoint, username and password in SSM parameter store 
* and secrets manager.  
* 
* Placing these resources in this addon_infrastructure.tf (as opposed to addon.tf) 
* enables a pre-provisioning option if using Workshop Studio. This is important 
* since the OpenSearch cluster takes ~20 minutes to provision. 
*/

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  opensearch_host           = aws_opensearch_domain.opensearch.endpoint
  opensearch_user           = "admin"
  opensearch_password       = random_password.master_user.result
  opensearch_parameter_path = "/eksworkshop/${var.eks_cluster_id}/opensearch"
}

# Provision OpenSearch domain
resource "aws_opensearch_domain" "opensearch" {
  domain_name    = var.eks_cluster_id
  engine_version = "OpenSearch_2.9"

  # Specify a single instance cluster
  cluster_config {
    instance_count         = 1
    instance_type          = "r6g.large.search"
    zone_awareness_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 100
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = local.opensearch_user
      master_user_password = local.opensearch_password
    }
  }

  # Allow any IP address to access the OpenSearch domain
  access_policies = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "*"
          },
          "Action" : "es:*",
          "Resource" : "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.eks_cluster_id}/*"
        }
      ]
  })

  # Extend timeouts from 20m default
  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }

  tags = var.tags
}

# Generate random master user password for OpenSearch
resource "random_password" "master_user" {
  length           = 16
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "@#"
}

# Store OpenSearch host in parameter store
resource "aws_ssm_parameter" "opensearch_host" {
  name        = "${local.opensearch_parameter_path}/host"
  description = "OpenSearch domain host endpoint"
  type        = "String"
  value       = local.opensearch_host

  tags = var.tags
}

# Store OpenSearch user name in parameter store
resource "aws_ssm_parameter" "opensearch_user" {
  name        = "${local.opensearch_parameter_path}/user"
  description = "OpenSearch domain user name"
  type        = "SecureString"
  value       = local.opensearch_user

  tags = var.tags
}

# Store OpenSearch password in parameter store
resource "aws_ssm_parameter" "opensearch_password" {
  name        = "${local.opensearch_parameter_path}/password"
  description = "OpenSearch domain password"
  type        = "SecureString"
  value       = local.opensearch_password

  tags = var.tags
}
