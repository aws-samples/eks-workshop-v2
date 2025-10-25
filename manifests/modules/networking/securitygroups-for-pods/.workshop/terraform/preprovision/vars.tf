# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_id" {
  description = "EKS cluster name"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = any
}

variable "rds_engine_version" {
  description = "The MySQL engine version of RDS to use"
  type        = string
  # renovate: datasource=endoflife-date depName=amazon-rds-mysql
  default = "8.4.6"
}